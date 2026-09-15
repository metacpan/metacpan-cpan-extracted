package ForgeOps::Tracker::Integrations::PSGIPerformance;

use strict;
use warnings;
use parent 'Plack::Middleware';
use Time::HiRes ();
use ForgeOps::Tracker;

# PSGI/Plack middleware that times every request end to end and reports it, bucketed by
# transaction name, for a dashboard widget on a project's Performance page (so it can show which
# parts of your app are actually slow, not just which ones raise). A separate, independent
# middleware from Integrations::PSGI (error reporting), not layered onto it, since performance
# tracking runs regardless of whether error reporting is even configured: the same
# several-genuinely-independent-mechanisms split every other client's own integrations already
# use.
#
#   use Plack::Builder;
#   builder {
#       enable '+ForgeOps::Tracker::Integrations::PSGI';            # error reporting
#       enable '+ForgeOps::Tracker::Integrations::PSGIPerformance'; # performance monitoring
#       $app;
#   };
#
# Wraps the downstream app call in an eval, records the duration either way, then re-raises the
# original exception unchanged, the same shape Integrations::PSGI's own call already uses to keep
# Plack's own error handling exactly as it would be without this middleware installed.
#
# The transaction name is "<HTTP method> <path>", the raw PATH_INFO, not a matched route pattern:
# plain PSGI has no route-matching concept of its own (a bare $env hash) to read one from
# generically, the same reasoning Go's own net/http integration documents for itself. A Dancer2
# app should use Integrations::Dancer2Performance instead, which reads the matched route's own
# pattern and so avoids a distinct id exploding into its own separate transaction.
sub call {
    my ($self, $env) = @_;

    my $started_at = Time::HiRes::time;
    my @response = eval { @{ $self->app->($env) } };
    my $error = $@;
    my $duration_ms = (Time::HiRes::time - $started_at) * 1000;

    ForgeOps::Tracker::record_performance("$env->{REQUEST_METHOD} $env->{PATH_INFO}", $duration_ms);

    die $error if $error;
    return \@response;
}

1;
