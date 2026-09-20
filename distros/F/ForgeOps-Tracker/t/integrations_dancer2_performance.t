use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Plack::Test;
use HTTP::Request::Common qw(GET);
use ForgeOps::Tracker;

my @recorded;
local *ForgeOps::Tracker::record_performance = sub { push @recorded, [@_]; };

package TestApp {
    use Dancer2;
    use ForgeOps::Tracker::Integrations::Dancer2Performance;

    set apphandler => 'PSGI';
    set startup_info => 0;

    get '/users/:id' => sub { return 'ok'; };
    get '/slow/:id' => sub {
        ForgeOps::Tracker::span('inner work', sub { ForgeOps::Tracker::Integrations::Dancer2Performance::_slow() });
        return 'ok';
    };
}

my $app = TestApp->to_app;

test_psgi $app, sub {
    my $cb = shift;

    subtest 'records the matched route pattern, not the raw path' => sub {
        @recorded = ();
        my $res = $cb->(GET '/users/42');

        is($res->code, 200);
        is(scalar(@recorded), 1);
        # The route pattern, not "GET /users/42": a distinct user id must not explode into its
        # own separate transaction the way the literal path would.
        is($recorded[0][0], 'GET /users/:id');
        ok($recorded[0][1] >= 0, 'a non-negative duration was recorded');
    };

    subtest 'records a controller breadcrumb with the matched route pattern' => sub {
        ForgeOps::Tracker::add_breadcrumb('left by an earlier request');
        $cb->(GET '/users/42');

        is(scalar(@ForgeOps::Tracker::current_breadcrumbs), 1, 'a fresh trail per request');
        my ($crumb) = @ForgeOps::Tracker::current_breadcrumbs;
        is($crumb->{category}, 'controller');
        is($crumb->{message}, 'GET /users/:id');
        is($crumb->{data}{status}, 200);
        is($crumb->{data}{path}, '/users/42');
    };

    subtest 'traces a slow request with the matched route as the root span' => sub {
        ForgeOps::Tracker::_reset_for_testing();
        ForgeOps::Tracker::init(
            dsn                     => 'https://key@tracker.example.com/api/v1/events',
            environment             => 'production',
            enabled_environments    => { production => 1 },
            trace_capture_threshold => 0.01,
        );
        my @pushed;
        no warnings 'redefine';
        local *ForgeOps::Tracker::_span_queue = sub { bless {}, 'Traced::Queue' };
        local *Traced::Queue::push = sub { push @pushed, $_[1]; 1 };
        local *ForgeOps::Tracker::Integrations::Dancer2Performance::_slow = sub { select(undef, undef, undef, 0.03) };

        my $res = $cb->(GET '/slow/1');

        is($res->code, 200);
        is(scalar(@pushed), 1);
        my @names = map { $_->{name} } @{ $pushed[0]{spans} };
        is_deeply(\@names, ['GET /slow/:id', 'inner work']);
    };

    subtest 'records nothing for a request that never matches a route' => sub {
        @recorded = ();
        my $res = $cb->(GET '/no-such-route');

        is($res->code, 404);
        # Dancer2's own after_request hook never fires for a 404 (confirmed directly against
        # Dancer2::Core::App's dispatch code); an accepted gap in this integration, not a bug.
        is(scalar(@recorded), 0);
    };
};

done_testing;
