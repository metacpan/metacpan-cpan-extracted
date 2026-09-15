use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Plack::Builder;
use ForgeOps::Tracker;
use ForgeOps::Tracker::Integrations::PSGIPerformance;

my @recorded;
# Overriding the package sub via a local typeglob assignment, the same way t/integrations_psgi.t
# stubs out ForgeOps::Tracker::report: ForgeOps::Tracker's public API is a set of plain subs, not
# a class.
local *ForgeOps::Tracker::record_performance = sub { push @recorded, [@_]; };

my $app = builder {
    enable '+ForgeOps::Tracker::Integrations::PSGIPerformance';
    sub {
        my $env = shift;
        die "route exploded\n" if $env->{PATH_INFO} eq '/boom';
        return [200, ['Content-Type' => 'text/plain'], ['ok']];
    };
};

test_psgi $app, sub {
    my $cb = shift;

    subtest 'records the raw path (plain PSGI has no route pattern of its own)' => sub {
        @recorded = ();
        my $res = $cb->(GET '/users/42');

        is($res->code, 200);
        is(scalar(@recorded), 1);
        is($recorded[0][0], 'GET /users/42');
        ok($recorded[0][1] >= 0, 'a non-negative duration was recorded');
    };

    subtest 'still records a duration for a request that raises, then re-raises' => sub {
        @recorded = ();
        my $res = $cb->(GET '/boom');

        is($res->code, 500, "Plack's own 500 response still happens");
        is(scalar(@recorded), 1);
        is($recorded[0][0], 'GET /boom');
    };
};

done_testing;
