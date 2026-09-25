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
# automatic database or HTTP span, add those by hand with ForgeOps::Tracker::span (and
# ForgeOps::Tracker::http_span for an outgoing HTTP call, which also hands it the traceparent
# header to send).
#
# The trace continues the caller's when the request arrived with a usable W3C `traceparent` header
# (see ForgeOps::Tracker::TraceParent), and its trace id exists even with track_tracing off, since
# every error reported during the request carries it. Dancer2 has already matched the route when
# before_request fires, so the request is named there (transaction name and endpoint, both
# "GET /users/:id"), before the route runs: an error reported from inside the route carries both.
#
# A route that dies never reaches after_request (see below), so an on_route_exception hook
# finishes its trace instead, marked errored so it's sent however fast it was. It remembers the
# request's context for that error first (ForgeOps::Tracker::snapshot_onto): Dancer2 runs the two
# plugins' on_route_exception hooks in load order, and Integrations::Dancer2's report has to find
# the trace id either way.
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
            my $request = $app->request;
            ForgeOps::Tracker::start_trace($request ? scalar $request->header('traceparent') : undef);
            return unless $request;

            $request->var($STARTED_AT_KEY, Time::HiRes::time);
            my $route = $request->route;
            if ($route) {
                my $name = $request->method . ' ' . $route->spec_route;
                ForgeOps::Tracker::set_request_route($name, $name);
            }
        },
    ));

    $app->add_hook(Dancer2::Core::Hook->new(
        name => 'on_route_exception',
        code => sub {
            my (undef, $error) = @_;
            my $request = $app->request;
            ForgeOps::Tracker::snapshot_onto($error);
            my $started_at = $request ? $request->var($STARTED_AT_KEY) : undef;
            return unless defined $started_at;

            ForgeOps::Tracker::finish_trace(
                _transaction_name($request), $started_at, (Time::HiRes::time - $started_at) * 1000,
            );
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
            my $transaction_name = _transaction_name($request);

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

sub _transaction_name {
    my ($request) = @_;
    my $route = $request->route;
    my $pattern = $route ? $route->spec_route : undef;
    return $request->method . ' ' . (defined $pattern ? "$pattern" : $request->path);
}

1;
