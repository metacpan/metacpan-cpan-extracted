package ForgeOps::Tracker;

use strict;
use warnings;
use ForgeOps::Tracker::Client;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::DeliveryQueue;
use ForgeOps::Tracker::EventBuilder;
use ForgeOps::Tracker::PerformanceFlusher;
use ForgeOps::Tracker::Reporter;

# 0.2.0 was never bumped past: that exact tarball was uploaded to PAUSE once (2026-09-11) but
# never made it into the public CPAN index, and PAUSE permanently refuses a second upload of a
# distribution+version pair it already has on record, even one that never indexed (confirmed
# directly: retrying the identical 0.2.0 tarball came back 409 Conflict, not the original success
# response repeated). No functional change from 0.2.0; this bump exists solely to get a fresh,
# uploadable version number.
our $VERSION = '0.2.1';

my $configuration;
my $reporter;
my $performance_flusher;

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

# report($error, \%context): report an exception you've already caught, e.g.:
#
#   eval { risky_operation() };
#   if ($@) {
#       ForgeOps::Tracker::report($@, { order_id => $order->id });
#   }
sub report {
    my ($error, $context) = @_;
    _reporter()->report($error, $context);
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

# @internal not part of the public API: resets module state between test cases
sub _reset_for_testing {
    $configuration = undef;
    $reporter = undef;
    $performance_flusher = undef;
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
