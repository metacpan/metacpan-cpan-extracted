use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Plack::Builder;
use ForgeOps::Tracker;
use ForgeOps::Tracker::Integrations::PSGI;

my @reported;
# Overriding the package sub via a local typeglob assignment, rather than mocking an object method:
# ForgeOps::Tracker's public API is a set of plain subs (report/init), not a class, the same
# module-level-function shape sdks/node/src/index.js exposes for its own captureException.
local *ForgeOps::Tracker::report = sub { push @reported, [@_]; };

my $app = builder {
    # The leading '+' tells Plack::Builder to use this exact class name rather than prepending
    # its default Plack::Middleware::* namespace prefix: confirmed directly (the bare name
    # produced "Can't locate Plack/Middleware/ForgeOps/..."), not assumed from Plack::Builder's
    # own docs alone.
    enable '+ForgeOps::Tracker::Integrations::PSGI';
    sub {
        my $env = shift;
        die "route exploded\n" if $env->{PATH_INFO} eq '/boom';
        return [200, ['Content-Type' => 'text/plain'], ['ok']];
    };
};

test_psgi $app, sub {
    my $cb = shift;

    subtest 'reports and re-raises an exception that escapes the route' => sub {
        @reported = ();
        my $res = $cb->(GET '/boom');

        is($res->code, 500, 'Plack still produces its own 500 response');
        is(scalar(@reported), 1);
        like($reported[0][0], qr/route exploded/);
        is($reported[0][1]{path}, '/boom');
        is($reported[0][1]{method}, 'GET');
    };

    subtest 'clears the breadcrumb trail at the start of each request' => sub {
        ForgeOps::Tracker::add_breadcrumb('left by an earlier request');

        $cb->(GET '/fine');

        is(scalar(@ForgeOps::Tracker::current_breadcrumbs), 0);
    };

    subtest 'does not report a request that completes normally' => sub {
        @reported = ();
        my $res = $cb->(GET '/fine');

        is($res->code, 200);
        is($res->content, 'ok');
        is(scalar(@reported), 0);
    };
};

done_testing;
