package ForgeOps::Tracker::Integrations::Dancer2Performance;

use strict;
use warnings;
use Dancer2::Plugin;
use Dancer2::Core::Hook;
use Time::HiRes ();
use ForgeOps::Tracker;

# Dancer2 plugin that times every request end to end and reports it, bucketed by transaction
# name, for a dashboard widget on a project's Performance page. A separate, independent plugin
# from Integrations::Dancer2 (error reporting), not layered onto it, for the same reason PSGI's
# own two middlewares (Integrations::PSGI and Integrations::PSGIPerformance) are kept apart:
# performance tracking runs regardless of whether error reporting is even configured.
#
#   use Dancer2;
#   use ForgeOps::Tracker::Integrations::Dancer2Performance; # that's it, no further wiring
#
# Registers a before_request/after_request hook pair (Dancer2's own documented hooks), storing
# the start time on the current request between them via Dancer2's own per-request var storage,
# rather than a lexical closed over by both hooks: the hook code closes over the app object, not
# the request, and the same app object dispatches every request it ever handles, so a variable
# scoped to the request itself is what actually keeps two overlapping requests' own timers from
# clobbering each other.
#
# Also starts a trace per request in before_request and finishes it in after_request (root span
# named like the transaction), so a slow request's own breakdown reaches /spans; there is no
# automatic database or HTTP span, add those by hand with ForgeOps::Tracker::span.
#
# The transaction name is the matched route's own spec_route (e.g. "/users/:id", the pattern as
# originally declared): Dancer2 sets this on the request during route matching, before the route
# handler runs, so it is already populated by the time after_request fires. A distinct user id
# must not explode into its own separate transaction the way the raw path would.
#
# after_request only fires for a request that actually matched a route and produced a normal
# response (confirmed directly against Dancer2::Core::App's own dispatch code: a 404's
# response_not_found path returns without ever calling execute_hook for after_request at all), so
# a request that never matched any route isn't recorded by this integration, an accepted gap
# rather than a fallback: Dancer2's own hook API simply doesn't expose that case as an event.
my $STARTED_AT_KEY = 'forge_ops_tracker_performance_started_at';

sub BUILD {
    my ($plugin) = @_;
    my $app = $plugin->app;

    $app->add_hook(Dancer2::Core::Hook->new(
        name => 'before_request',
        code => sub {
            ForgeOps::Tracker::clear_breadcrumbs();
            ForgeOps::Tracker::start_trace();
            my $request = $app->request;
            $request->var($STARTED_AT_KEY, Time::HiRes::time) if $request;
        },
    ));

    $app->add_hook(Dancer2::Core::Hook->new(
        name => 'after_request',
        code => sub {
            my $request = $app->request;
            return unless $request;

            my $started_at = $request->var($STARTED_AT_KEY);
            return unless defined $started_at;

            my $duration_ms = (Time::HiRes::time - $started_at) * 1000;
            my $route = $request->route;
            my $pattern = $route ? $route->spec_route : undef;
            my $transaction_name = $request->method . ' ' . (defined $pattern ? "$pattern" : $request->path);

            ForgeOps::Tracker::record_performance($transaction_name, $duration_ms);
            ForgeOps::Tracker::finish_trace($transaction_name, $started_at, $duration_ms);
            ForgeOps::Tracker::add_breadcrumb(
                $transaction_name,
                category => 'controller',
                data     => { status => $app->response ? $app->response->status : undef, path => $request->path },
            );
        },
    ));
}

1;
