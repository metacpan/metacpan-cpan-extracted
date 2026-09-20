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
# Also starts a trace for the request and finishes it here (root span named like the
# transaction), so a slow request's own breakdown reaches /spans; see ForgeOps::Tracker::span.
# There is no automatic database or HTTP span (no DBI or HTTP::Tiny hook here), so add those by
# hand.
#
# The transaction name is "<HTTP method> <path>", the raw PATH_INFO, not a matched route pattern:
# plain PSGI has no route-matching concept of its own (a bare $env hash) to read one from
# generically, the same reasoning Go's own net/http integration documents for itself. A Dancer2
# app should use Integrations::Dancer2Performance instead, which reads the matched route's own
# pattern and so avoids a distinct id exploding into its own separate transaction.
sub call {
    my ($self, $env) = @_;

    ForgeOps::Tracker::clear_breadcrumbs();
    ForgeOps::Tracker::start_trace();

    my $started_at = Time::HiRes::time;
    my @response = eval { @{ $self->app->($env) } };
    my $error = $@;
    my $duration_ms = (Time::HiRes::time - $started_at) * 1000;

    my $transaction_name = "$env->{REQUEST_METHOD} $env->{PATH_INFO}";
    ForgeOps::Tracker::record_performance($transaction_name, $duration_ms);

    # Also an automatic "controller" breadcrumb, recorded on the way out (before an exception is
    # re-raised below), so it is already in the trail by the time Integrations::PSGI, enabled
    # outside this middleware as in the synopsis above, reports that exception. Recorded whether or
    # not the request raised, since eval above catches both.
    ForgeOps::Tracker::add_breadcrumb(
        $transaction_name,
        category => 'controller',
        level    => $error ? 'error' : 'info',
        data     => { $error ? () : (status => $response[0]), path => $env->{PATH_INFO} },
    );

    ForgeOps::Tracker::finish_trace($transaction_name, $started_at, $duration_ms);

    die $error if $error;
    return \@response;
}

1;
