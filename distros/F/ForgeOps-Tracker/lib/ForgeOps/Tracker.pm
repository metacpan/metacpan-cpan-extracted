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
use Time::HiRes ();

# 0.2.0 was never bumped past: that exact tarball was uploaded to PAUSE once (2026-09-11) but
# never made it into the public CPAN index, and PAUSE permanently refuses a second upload of a
# distribution+version pair it already has on record, even one that never indexed (confirmed
# directly: retrying the identical 0.2.0 tarball came back 409 Conflict, not the original success
# response repeated). No functional change from 0.2.0; this bump exists solely to get a fresh,
# uploadable version number.
our $VERSION = '0.6.0';

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
#   ForgeOps::Tracker::init(dsn => 'https://<api_key>@your-forgeops-host/api/v1/events');
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
sub report {
    my ($error, $context, $user) = @_;
    $user = $current_user unless defined $user;
    _reporter()->report($error, $context, $user, [ @current_breadcrumbs ]);
    return;
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

# start_trace(): starts a fresh trace on this process, discarding any earlier one. The PSGI/Dancer2
# performance integrations call this at the start of every request; call it (with finish_trace)
# yourself to trace anything else, e.g. a queue job. Does nothing when track_tracing is off or the
# client isn't enabled.
sub start_trace {
    my $config = _configuration();
    $current_trace = ($config->{track_tracing} && $config->is_enabled)
        ? ForgeOps::Tracker::SpanBuffer->new($config)
        : undef;
    return;
}

# finish_trace($name, $started_at, $duration_ms): ends the current trace, queueing it for delivery
# when the root took at least trace_capture_threshold seconds, and always clears it. $started_at
# is an epoch-seconds float (Time::HiRes::time).
sub finish_trace {
    my ($name, $started_at, $duration_ms) = @_;
    my $trace = $current_trace;
    $current_trace = undef;
    return unless $trace;

    my $payload = $trace->finish_trace($name, $started_at, $duration_ms);
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
    $current_user = undef;
    @current_breadcrumbs = ();
    return;
}

1;

__END__

=head1 NAME

ForgeOps::Tracker - error reporting client for a ForgeOps instance

=head1 SYNOPSIS

    use ForgeOps::Tracker;

    ForgeOps::Tracker::init(
        dsn         => 'https://<api_key>@your-forgeops-host/api/v1/events',
        environment => 'production',
    );

    eval { risky_operation() };
    if ($@) {
        ForgeOps::Tracker::report($@, { order_id => $order->id });
    }

See L<sdks/perl/README.md|../README.md> for PSGI/Plack and Dancer2 integrations, the delivery
model, and PII scrubbing.

=cut
