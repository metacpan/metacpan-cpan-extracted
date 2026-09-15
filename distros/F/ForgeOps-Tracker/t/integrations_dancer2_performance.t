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
