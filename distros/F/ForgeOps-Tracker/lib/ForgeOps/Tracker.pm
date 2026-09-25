package ForgeOps::Tracker;

use strict;
use warnings;
use POSIX qw(strftime);
use ForgeOps::Tracker::Client;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::DeliveryQueue;
use ForgeOps::Tracker::EventBuilder;
use ForgeOps::Tracker::MetricBuffer;
use ForgeOps::Tracker::PerformanceFlusher;
use ForgeOps::Tracker::Reporter;
use ForgeOps::Tracker::SpanBuffer;
use ForgeOps::Tracker::SpanDelivery;
use ForgeOps::Tracker::TraceParent;
use Scalar::Util ();
use Time::HiRes ();

# 0.2.0 was never bumped past: that exact tarball was uploaded to PAUSE once (2026-09-11) but
# never made it into the public CPAN index, and PAUSE permanently refuses a second upload of a
# distribution+version pair it already has on record, even one that never indexed (confirmed
# directly: retrying the identical 0.2.0 tarball came back 409 Conflict, not the original success
# response repeated). No functional change from 0.2.0; this bump exists solely to get a fresh,
# uploadable version number.
our $VERSION = '0.9.0';

my $configuration;
my $reporter;
my $performance_flusher;
my $span_queue;
my ($metric_buffer, $infrastructure_metric_buffer);

# The affected user set via set_user() below, if any: a plain package variable, the same
# "shared-nothing between requests" reasoning as sdks/php's own static property (see that
# client's own comment): a typical Perl PSGI deployment (Starman, uWSGI, mod_perl's own prefork
# workers) is one process per worker, forked fresh before serving any request, so this is safely
# request-scoped there without needing a thread-local. Request-handling code under a threaded or
# event-loop-based PSGI server should `local`-ize this instead of assigning to it directly, the
# same way Dancer2 itself already uses `local` for its own per-request state.
our $current_user;

# The breadcrumb trail add_breadcrumb() below appends to: a plain package array, the same
# one-process-per-worker reasoning as $current_user above. Unlike $current_user, it accumulates
# over a request's lifetime rather than being set once, so the PSGI/Dancer2 integrations clear it
# at the start of each request themselves (see clear_breadcrumbs); a prefork worker serves many
# requests in a row, and without that one request's trail would leak into the next. Request-
# handling code under a threaded or event-loop-based PSGI server should `local`-ize this array
# instead, exactly as $current_user's own comment describes.
our @current_breadcrumbs;

# The trace span() and record_span() below record into, if one is open: a plain package variable,
# same reasoning as @current_breadcrumbs above. The PSGI/Dancer2 performance integrations start
# and finish it around every request; finish_trace() always clears it, so nothing leaks into the
# next request a prefork worker serves. Request-handling code under a threaded or event-loop-based
# PSGI server should `local`-ize it instead.
our $current_trace;

# The current request's context, if one is running: { trace_id, parent_span_id, transaction_name,
# endpoint, errored }. Set by start_trace() whether or not span tracing is on (the trace id is also
# what links an error to errors in other services), cleared by finish_trace(), and a plain package
# variable for the same reason as $current_trace above (`local`-ize it the same way under a
# threaded or event-loop PSGI server).
our $current_request;

# Request context remembered for an error that escaped a request (see snapshot_onto), for when it
# is only reported after finish_trace() has already cleared $current_request: the PSGI error
# middleware sits outside the performance one, and Dancer2 runs its on_route_exception hooks in
# whatever order the plugins were loaded. A short list rather than something attached to the
# error itself, since a Perl error is as often a plain string as an object; newest first.
my @escaped;
my $MAX_ESCAPED = 8;
sub _configuration {
    $configuration ||= ForgeOps::Tracker::Configuration->new;
    return $configuration;
}

sub _reporter {
    unless ($reporter) {
        my $config = _configuration();
        my $client = ForgeOps::Tracker::Client->new($config);
        my $delivery_queue = ForgeOps::Tracker::DeliveryQueue->new($config, $client);
        $reporter = ForgeOps::Tracker::Reporter->new($config, ForgeOps::Tracker::EventBuilder->new($config), $delivery_queue);
    }
    return $reporter;
}

sub _performance_flusher {
    unless ($performance_flusher) {
        my $config = _configuration();
        my $client = ForgeOps::Tracker::Client->new($config);
        $performance_flusher = ForgeOps::Tracker::PerformanceFlusher->new($config, $client);
    }
    return $performance_flusher;
}

sub _metric_buffers {
    unless ($metric_buffer) {
        my $config = _configuration();
        my $client = ForgeOps::Tracker::Client->new($config);
        $metric_buffer = ForgeOps::Tracker::MetricBuffer->new(
            $config, sub { $client->deliver_metrics($_[0]) }, sub { $config->{metric_flush_interval} },
        );
        $infrastructure_metric_buffer = ForgeOps::Tracker::MetricBuffer->new(
            $config, sub { $client->deliver_infrastructure_metrics($_[0]) }, sub { $config->{infrastructure_metric_flush_interval} },
        );
    }
    return ($metric_buffer, $infrastructure_metric_buffer);
}

sub _span_queue {
    unless ($span_queue) {
        my $config = _configuration();
        my $client = ForgeOps::Tracker::Client->new($config);
        $span_queue = ForgeOps::Tracker::DeliveryQueue->new($config, ForgeOps::Tracker::SpanDelivery->new($client));
    }
    return $span_queue;
}

# init(%overrides): configure the client. Call once at startup, e.g.:
#
#   ForgeOps::Tracker::init(dsn => 'https://<api_key>@getforgeops.net/api/v1/events');
#
# Any Configuration field can be overridden by name.
sub init {
    my (%overrides) = @_;
    my $config = _configuration();

    for my $key (keys %overrides) {
        die "Configuration has no property '$key'" unless exists $config->{$key};
        $config->{$key} = $overrides{$key};
    }

    return $config;
}

# report($error, \%context, \%user): report an exception you've already caught, e.g.:
#
#   eval { risky_operation() };
#   if ($@) {
#       ForgeOps::Tracker::report($@, { order_id => $order->id });
#   }
#
# \%user defaults to whatever set_user() last set (undef if nothing did); pass one explicitly to
# override that for this one report.
#
# During a request (between start_trace and finish_trace), the event also carries the request's
# trace_id, transaction_name and endpoint, and the request is marked errored so its trace is sent
# however fast it was. An error one of the integrations saw escape a request falls back to what
# snapshot_onto remembered for it (along with the user and breadcrumb trail), for when it's
# reported only after the request's own state is gone.
sub report {
    my ($error, $context, $user) = @_;
    my $snapshot = $current_request ? undef : _snapshot_for($error);
    $current_request->{errored} = 1 if $current_request;

    my $source = $current_request || $snapshot || {};
    $user = $current_user unless defined $user;
    $user = $snapshot->{user} if !defined $user && $snapshot;
    my @breadcrumbs = @current_breadcrumbs;
    @breadcrumbs = @{ $snapshot->{breadcrumbs} } if !@breadcrumbs && $snapshot;

    _reporter()->report($error, $context, $user, \@breadcrumbs, {
        map { $_ => $source->{$_} } qw(transaction_name endpoint trace_id)
    });
    return;
}

# current_trace_id(): the current request's W3C trace id (32 lowercase hex characters), or undef
# outside a request. Handy for your own logs: it's the id ForgeOps links errors across services
# with.
sub current_trace_id {
    return $current_request ? $current_request->{trace_id} : undef;
}

# set_request_route($transaction_name, $endpoint): names the current request once its route is
# known. $transaction_name is the same name its performance sample and root span use, $endpoint
# the HTTP method plus the route pattern ("GET /users/:id"), never the literal path. The Dancer2
# performance plugin calls this as soon as Dancer2 has matched the route, so an error reported
# from inside the route already carries both; plain PSGI has no route pattern of its own, so a
# PSGI app that has one (from its own router) can call this itself. Does nothing outside a request.
sub set_request_route {
    my ($transaction_name, $endpoint) = @_;
    return unless $current_request;
    $current_request->{transaction_name} = $transaction_name;
    $current_request->{endpoint} = $endpoint;
    return;
}

# snapshot_onto($error): remembers the current request's trace id, transaction name and endpoint,
# plus the affected user and breadcrumb trail, for $error, and marks the request errored. Called by
# the PSGI/Dancer2 performance integrations when an error escapes a request, just before they
# finish its trace, so a report made afterward (see report) still has all of it. The first snapshot
# for the same error wins: the innermost one saw the request closest to where it failed. Never
# dies. Not something app code normally calls directly.
sub snapshot_onto {
    my ($error) = @_;
    eval {
        return unless $current_request && defined $error;
        $current_request->{errored} = 1;
        return if _snapshot_for($error);

        my $entry = {
            (ref $error ? (address => Scalar::Util::refaddr($error), error => $error) : (text => "$error")),
            user        => $current_user,
            breadcrumbs => [ map { { %$_ } } @current_breadcrumbs ],
            map { $_ => $current_request->{$_} } qw(transaction_name endpoint trace_id),
        };
        Scalar::Util::weaken($entry->{error}) if ref $error;
        unshift @escaped, $entry;
        splice @escaped, $MAX_ESCAPED if @escaped > $MAX_ESCAPED;
        1;
    };
    return;
}

sub _snapshot_for {
    my ($error) = @_;
    return undef unless defined $error;
    for my $entry (@escaped) {
        if (ref $error) {
            return $entry if defined $entry->{error} && $entry->{address} == Scalar::Util::refaddr($error);
        } elsif (defined $entry->{text} && $entry->{text} eq $error) {
            return $entry;
        }
    }
    return undef;
}

# set_user(%user): manually attaches an affected user to whatever gets reported for the rest of
# this process (or, under a threaded/event-loop PSGI server, `local`-ize $current_user directly
# instead: see that variable's own comment). id/email/username are all independently optional;
# call with no arguments to clear whatever was set, e.g.:
#
#   ForgeOps::Tracker::set_user(id => $user->id, email => $user->email);
#   ForgeOps::Tracker::set_user(); # clear it
sub set_user {
    my (%user) = @_;
    my %defined = map { $_ => $user{$_} } grep { defined $user{$_} } keys %user;
    $current_user = %defined ? \%defined : undef;
    return;
}

# add_breadcrumb($message, %options): records one entry in a small, bounded trail of recent
# events, attached to whatever report() sends next so an issue's detail page can show what led up
# to it. Options: category (default 'custom'), level (default 'info'), data (a hashref of extra
# detail, default {}). Only the max_breadcrumbs most recent are kept; does nothing when
# track_breadcrumbs is off, e.g.:
#
#   ForgeOps::Tracker::add_breadcrumb('charging card', category => 'payment', data => { order_id => 42 });
sub add_breadcrumb {
    my ($message, %options) = @_;
    my $config = _configuration();
    return unless $config->{track_breadcrumbs};

    push @current_breadcrumbs, {
        category  => defined $options{category} ? $options{category} : 'custom',
        message   => $message,
        level     => defined $options{level} ? $options{level} : 'info',
        timestamp => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        data      => defined $options{data} ? $options{data} : {},
    };

    my $max = $config->{max_breadcrumbs};
    shift @current_breadcrumbs while @current_breadcrumbs > $max;
    return;
}

# clear_breadcrumbs(): empties the current trail. The PSGI/Dancer2 integrations call this at the
# start of every request themselves; call it by hand at the start of any other unit of work (a
# cron job's next iteration, say) that should begin with a fresh trail.
sub clear_breadcrumbs {
    @current_breadcrumbs = ();
    return;
}

# record_performance($transaction_name, $duration_ms): called by the PSGI/Dancer2 performance
# integrations, not typically called directly, e.g.:
#
#   ForgeOps::Tracker::record_performance('GET /users/:id', $elapsed_ms);
sub record_performance {
    my ($transaction_name, $duration_ms) = @_;
    _performance_flusher()->record($transaction_name, $duration_ms);
    return;
}

# start_trace($traceparent): starts a fresh trace on this process, discarding any earlier one. The
# PSGI/Dancer2 performance integrations call this at the start of every request with the request's
# own `traceparent` header: a usable W3C value continues the caller's trace (same trace id, and the
# root span's parent is the caller's span), anything else (undef, blank, malformed) starts a new
# one. Call it (with finish_trace) yourself to trace anything else, e.g. a queue job.
#
# The trace id exists whenever the client is enabled, even with track_tracing off, since errors
# reported before finish_trace carry it and http_span propagates it; only span recording is gated
# on track_tracing. Does nothing when the client isn't enabled.
sub start_trace {
    my ($traceparent) = @_;
    my $config = _configuration();
    $current_trace = undef;
    $current_request = undef;
    return unless $config->is_enabled;

    my $incoming = ForgeOps::Tracker::TraceParent::parse($traceparent);
    $current_request = {
        trace_id       => $incoming ? $incoming->{trace_id} : ForgeOps::Tracker::TraceParent::generate_trace_id(),
        parent_span_id => $incoming ? $incoming->{parent_span_id} : undef,
        errored        => 0,
    };
    $current_trace = ForgeOps::Tracker::SpanBuffer->new(
        $config,
        trace_id              => $current_request->{trace_id},
        remote_parent_span_id => $current_request->{parent_span_id},
    ) if $config->{track_tracing};
    return;
}

# finish_trace($name, $started_at, $duration_ms): ends the current trace, queueing it for delivery
# when the root took at least trace_capture_threshold seconds or the request errored (an error was
# reported during it, or escaped it), and always clears it along with the request context.
# $started_at is an epoch-seconds float (Time::HiRes::time).
sub finish_trace {
    my ($name, $started_at, $duration_ms) = @_;
    my $trace = $current_trace;
    my $errored = $current_request && $current_request->{errored};
    $current_trace = undef;
    $current_request = undef;
    return unless $trace;

    my $payload = $trace->finish_trace($name, $started_at, $duration_ms, $errored);
    _span_queue()->push($payload) if $payload;
    return;
}

# span($name, $code, kind => 'service', data => {}): runs $code as a child span of whatever span is
# open (or of the request's root), returning what it returned. Outside a trace it just runs $code.
# Recorded even if $code dies, which is re-raised unchanged. kind is one of controller, service,
# database, redis, http, job, other (anything else is sent as "other"), e.g.:
#
#   my $order = ForgeOps::Tracker::span('charge card', sub { $gateway->charge($id) }, data => { order => $id });
sub span {
    my ($name, $code, %options) = @_;
    my $trace = $current_trace;
    return $code->() unless $trace;

    my $wantarray = wantarray;
    my $id = $trace->open_span;
    my $started_at = Time::HiRes::time;
    my (@result, $failed, $error);
    {
        local $@;
        $failed = !eval {
            if ($wantarray) { @result = $code->() }
            elsif (defined $wantarray) { $result[0] = $code->() }
            else { $code->() }
            1;
        };
        $error = $@;
    }
    $trace->finish(
        $id, $name, defined $options{kind} ? $options{kind} : 'service',
        $started_at, (Time::HiRes::time - $started_at) * 1000, $options{data},
    );
    die $error if $failed;
    return $wantarray ? @result : $result[0];
}

# http_span($method, $url, $code, data => {}): makes one outgoing HTTP call inside the current
# trace. Records it as an "http" span named "<METHOD> <host>" (never the path or query, which could
# carry an id or a token) and calls $code with a hashref of headers to add to the request,
# currently a W3C `traceparent` whose parent id is that span's own id, so the called service's
# root span nests under it. Returns what $code returned; the span is recorded even if $code dies,
# which is re-raised unchanged, e.g.:
#
#   my $response = ForgeOps::Tracker::http_span(POST => $url, sub {
#       my ($headers) = @_;
#       $http->post($url, { headers => { %$headers, 'Content-Type' => 'application/json' }, content => $body });
#   });
#
# The headers are empty outside a request, when propagate_traces is off, or when the host isn't in
# trace_propagation_targets; outside a request no span is recorded either. With track_tracing off
# the header is still sent (the trace id links errors across services) but no span is kept.
sub http_span {
    my ($method, $url, $code, %options) = @_;
    my $request = $current_request;
    return $code->({}) unless $request;

    my ($host) = (defined $url ? $url : '') =~ m{\A[A-Za-z][A-Za-z0-9+.-]*://(?:[^/?#\@]*\@)?(\[[^\]]*\]|[^:/?#]+)};
    $host = lc $host if defined $host;
    my $span_id = ForgeOps::Tracker::TraceParent::generate_span_id();
    my %headers = _configuration()->should_propagate_trace($host)
        ? (ForgeOps::Tracker::TraceParent::HEADER() => ForgeOps::Tracker::TraceParent::build($request->{trace_id}, $span_id))
        : ();

    my $trace = $current_trace;
    return $code->(\%headers) unless $trace;

    my $wantarray = wantarray;
    $trace->open_span($span_id);
    my $started_at = Time::HiRes::time;
    my (@result, $failed, $error);
    {
        local $@;
        $failed = !eval {
            if ($wantarray) { @result = $code->(\%headers) }
            elsif (defined $wantarray) { $result[0] = $code->(\%headers) }
            else { $code->(\%headers) }
            1;
        };
        $error = $@;
    }
    $trace->finish(
        $span_id, uc($method) . ' ' . (defined $host ? $host : 'unknown'), 'http',
        $started_at, (Time::HiRes::time - $started_at) * 1000, $options{data},
    );
    die $error if $failed;
    return $wantarray ? @result : $result[0];
}

# record_span($name, $kind, $started_at, $duration_ms, $data): records a span you timed yourself
# under the current one; does nothing outside a trace. $started_at is an epoch-seconds float.
sub record_span {
    my ($name, $kind, $started_at, $duration_ms, $data) = @_;
    $current_trace->record_leaf($name, $kind, $started_at, $duration_ms, $data) if $current_trace;
    return;
}

# capture_metric($name, $value = 1): records a named business metric (a signup, a payment, anything
# you want to name), buffered and flushed periodically as one batch rather than one network call per
# capture. $value defaults to 1 so a bare counter-style call needs no argument; pass one for a real
# magnitude (capture_metric('payment', 49)); it may be negative (a refund). Does nothing when the
# client isn't enabled (no DSN, or this environment isn't in enabled_environments), and a
# non-numeric value is dropped.
sub capture_metric {
    my ($name, $value) = @_;
    $value = 1 unless defined $value;
    my $config = _configuration();
    return unless $config->is_enabled;

    my ($metrics) = _metric_buffers();
    $metrics->record({ metric_name => $name, value => $value, environment => $config->{environment}, release => $config->{release} });
    return;
}

# capture_infrastructure_metric($name, $value, hostname => $host): records one infrastructure reading
# (CPU, memory, disk, anything else a script of yours reads) from one of your own hosts. hostname
# defaults to server_name, so a script running on the box it reports about needs no argument. Same
# buffered-batch delivery and no-op-when-disabled contract as capture_metric. A program that ends
# normally flushes what is left from an END block, so a short-lived cron script needs nothing more;
# call flush_metrics() if it might exit another way (POSIX::_exit).
sub capture_infrastructure_metric {
    my ($name, $value, %options) = @_;
    my $config = _configuration();
    return unless $config->is_enabled;

    my (undef, $infrastructure) = _metric_buffers();
    $infrastructure->record({
        metric_name => $name,
        value       => $value,
        hostname    => defined $options{hostname} ? $options{hostname} : $config->{server_name},
    });
    return;
}

# flush_metrics(): delivers every buffered metric and infrastructure reading right now, instead of
# waiting for the next flush interval.
sub flush_metrics {
    $metric_buffer->flush if $metric_buffer;
    $infrastructure_metric_buffer->flush if $infrastructure_metric_buffer;
    return;
}

# @internal not part of the public API: resets module state between test cases
sub _reset_for_testing {
    $configuration = undef;
    $reporter = undef;
    $performance_flusher = undef;
    $span_queue = undef;
    $metric_buffer->_clear if $metric_buffer;
    $infrastructure_metric_buffer->_clear if $infrastructure_metric_buffer;
    $metric_buffer = undef;
    $infrastructure_metric_buffer = undef;
    $current_trace = undef;
    $current_request = undef;
    @escaped = ();
    $current_user = undef;
    @current_breadcrumbs = ();
    return;
}

1;

__END__

=head1 NAME

ForgeOps::Tracker - error reporting client for ForgeOps

=head1 SYNOPSIS

    use ForgeOps::Tracker;

    ForgeOps::Tracker::init(
        dsn         => 'https://<api_key>@getforgeops.net/api/v1/events',
        environment => 'production',
    );

    eval { risky_operation() };
    if ($@) {
        ForgeOps::Tracker::report($@, { order_id => $order->id });
    }

See L<sdks/perl/README.md|../README.md> for PSGI/Plack and Dancer2 integrations, the delivery
model, and PII scrubbing.

=cut
