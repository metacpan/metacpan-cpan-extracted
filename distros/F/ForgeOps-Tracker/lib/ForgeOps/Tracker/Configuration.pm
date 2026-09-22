package ForgeOps::Tracker::Configuration;

use strict;
use warnings;
use Cwd qw(getcwd);

# Holds a single ForgeOps DSN plus everything else the client needs to build and deliver events.
# Mirrors gems/forge_ops_tracker/lib/forge_ops_tracker/configuration.rb: a single DSN string
# carries both the ingestion URL and the project's api_key:
# "https://<api_key>@host/api/v1/events". Hand-parsed with a regex rather than pulling in the URI
# module: this SDK otherwise has zero non-core dependencies (HTTP::Tiny, threads, and
# Thread::Queue are all core as of the Perl versions this targets), and a DSN's shape is simple
# and fixed enough that a regex covers it completely without needing a general-purpose URI parser.
sub new {
    my ($class) = @_;
    return bless {
        dsn                  => $ENV{FORGE_OPS_DSN},
        environment          => $ENV{FORGE_OPS_ENVIRONMENT} || 'production',
        release              => $ENV{FORGE_OPS_RELEASE},
        server_name          => _safe_hostname(),
        app_root             => getcwd(),
        enabled_environments => { production => 1, staging => 1 },
        queue_size           => 1000,
        timeout              => 2, # seconds
        scrub_pii            => 1,
        # Whether EventBuilder reads a few lines of source off disk around each in_app frame's
        # culprit line (see EventBuilder::_attach_source_context). Defaults to true so a snippet
        # shows up with no extra setup, but this flag by itself isn't the real protection against
        # sending proprietary source code somewhere it shouldn't go: ForgeOps' own per-project
        # setting is the durable, server-enforced off switch, since it applies regardless of
        # what this flag happens to be set to on any given deployment, and can't quietly drift
        # back on the way a local config value could. Set this to false too if this host app
        # should never even attempt that disk read in the first place.
        capture_source_context => 1,
        # When an error's text carries the SQL behind a failed database call (DBI's
        # `[for Statement "..."]`, which needs ShowErrorStatement on the handle, or SQLite's
        # `while compiling:`), send the names of the stored procedure, table and view it touched,
        # so an issue says where to start looking. Names are identifiers, never values, which is
        # why this defaults on. capture_sql_statement is the separate, opt-in step of also
        # sending the statement itself, with every string and number replaced by "?"; off by
        # default because even a masked statement describes your schema, and ForgeOps' own
        # per-project setting is what durably governs whether the server stores it. See
        # ForgeOps::Tracker::SqlStatement.
        capture_sql_objects    => 1,
        capture_sql_statement  => 0,
        logger               => undef, # coderef, or undef to log nowhere
        # Whether add_breadcrumb records anything at all: on by default, matching every other
        # client in this repo.
        track_breadcrumbs    => 1,
        # How many of the most recent breadcrumbs are kept, oldest dropped first; 30, matching
        # every other client's own default (all traced back to gems/forge_ops_tracker's).
        max_breadcrumbs      => 30,
        # Whether the PSGI/Dancer2 performance integrations time every request, bucketed by
        # transaction name, and periodically report the aggregates for a dashboard widget on a
        # project's Performance page. On by default, the same "on unless you turn it off" posture
        # error reporting itself already has.
        track_performance         => 1,
        # Interval between aggregate performance reports, in seconds; requests are timed
        # in-process and flushed as one small report on this interval, not one network call per
        # request.
        performance_flush_interval => 60,
        # Seconds between flushes of the buffered capture_metric / capture_infrastructure_metric
        # entries (see MetricBuffer). No track_metrics flag the way track_performance has one: these
        # are explicit calls the host app's own code makes, not automatic instrumentation, so there is
        # nothing to turn off that simply not calling them doesn't already do.
        metric_flush_interval                => 60,
        infrastructure_metric_flush_interval => 60,
        # Whether the PSGI/Dancer2 performance integrations start a trace per request and report
        # it (when slow) to /spans. span() and record_span() only record inside a trace, so this
        # gates the whole feature. On by default.
        track_tracing => 1,
        # A trace is only sent when its root span took at least this many seconds.
        trace_capture_threshold => 1,
    }, $class;
}

# https://<api_key>@host[:port]/path: captures scheme, an optional userinfo (the api_key,
# percent-decoded), and everything from the host onward.
my $DSN_RE = qr{^(https?)://(?:([^:@/]*)@)?([^/]+)(/.*)?$};

sub _parsed_dsn {
    my ($self) = @_;
    return undef unless $self->{dsn};
    return undef unless $self->{dsn} =~ $DSN_RE;

    my ($scheme, $userinfo, $host, $path) = ($1, $2, $3, $4 // '');
    my $api_key = defined($userinfo) && length($userinfo) ? _uri_unescape($userinfo) : undef;
    return {
        scheme        => $scheme,
        api_key       => $api_key,
        ingestion_uri => "$scheme://$host$path",
    };
}

sub api_key {
    my ($self) = @_;
    my $parsed = $self->_parsed_dsn;
    return undef unless $parsed && defined $parsed->{api_key} && length $parsed->{api_key};
    return $parsed->{api_key};
}

# The ingestion URL with credentials stripped out (they travel as the Authorization header
# instead, never embedded in the request URI).
sub ingestion_uri {
    my ($self) = @_;
    my $parsed = $self->_parsed_dsn;
    return undef unless $parsed;
    return $parsed->{ingestion_uri};
}

# Same derivation as ingestion_uri, with the trailing "/events" swapped for
# "/performance_samples": one DSN, two more endpoints alongside deliver's own, matching the Ruby
# gem's own Configuration#performance_samples_uri.
sub performance_samples_uri {
    my ($self) = @_;
    my $uri = $self->ingestion_uri;
    return undef unless defined $uri;

    (my $swapped = $uri) =~ s{/events\z}{/performance_samples};
    return $swapped;
}

# Same derivation again, swapping the trailing "/events" for "/custom_metrics" and
# "/infrastructure_metrics".
sub custom_metrics_uri {
    my ($self) = @_;
    my $uri = $self->ingestion_uri;
    return undef unless defined $uri;

    (my $swapped = $uri) =~ s{/events\z}{/custom_metrics};
    return $swapped;
}

sub infrastructure_metrics_uri {
    my ($self) = @_;
    my $uri = $self->ingestion_uri;
    return undef unless defined $uri;

    (my $swapped = $uri) =~ s{/events\z}{/infrastructure_metrics};
    return $swapped;
}

# Same derivation again, swapping the trailing "/events" for "/spans".
sub spans_uri {
    my ($self) = @_;
    my $uri = $self->ingestion_uri;
    return undef unless defined $uri;

    (my $swapped = $uri) =~ s{/events\z}{/spans};
    return $swapped;
}

sub is_enabled {
    my ($self) = @_;
    return 0 unless $self->{dsn};
    return 0 unless defined $self->api_key;
    return 0 unless $self->{enabled_environments}{ $self->{environment} };
    return 1;
}

sub log {
    my ($self, $message) = @_;
    $self->{logger}->($message) if $self->{logger};
}

sub _safe_hostname {
    require Sys::Hostname;
    my $name = eval { Sys::Hostname::hostname() };
    return $@ ? undef : $name;
}

sub _uri_unescape {
    my ($string) = @_;
    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $string;
}

1;
