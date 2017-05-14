use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes;
require "t/exercises.tt";

if (! eval "use Net::Objwrap qw(:test);1") {
    SKIP: {
        skip("Net::Objwrap required for this test", 1);
    }
    done_testing;
    exit;
}
Net::Objwrap::Server->TEST_MODE;

my $r_id = 0;
for my $impl (IMPL()) {

    $r_id++;
    unlink "t/rq.$r_id", "t/cfg.$r_id";
    ok(! -f "t/rq.$r_id", "queue file does not exist");
    ok(! -f "t/cfg.$r_id", "remote config file does not exist");
    
    my $q1 = Forks::Queue->new( impl => $impl, file => "t/rq.$r_id",
                                db_file => "t/rq.$r_id",
                                remote => "t/cfg.$r_id",
                                list => [ 1 .. 10 ] );

    ok(ref($q1) =~ /Forks::Queue/, 'created remote queue');
    ok($q1->pending == 10, 'queue is populated');
    if ($impl ne 'Shmem') {
        ok(-f "t/rq.$r_id", "queue file t/rq.$r_id created impl=$impl");
    }
    ok(-f "t/cfg.$r_id", 'remote queue config created');

    my $q2 = Forks::Queue->new( remote => "t/cfg.$r_id" );
    ok(ref($q2) eq 'Net::Objwrap::Proxy', 'proxy queue created');
    ok(Net::Objwrap::ref($q2) eq ref($q1), 'correct remote ref');
    ok($q2->pending == 10, 'proxy queue is populated');

    is($q2->get, 1, 'got item with proxy');
    is($q1->get, 2, 'got item with remote queue');
    is($q2->get, 3, 'got another item with proxy');

    is(1, $q1->put(11), 'put from remote queue');
    is(2, $q2->put(12,13), 'put from proxy queue');
    is($q1->pending, $q2->pending, 'queue sizes are consistent');

    $q1->limit = 25;
    is(25, $q2->limit, 'limit lvalue on remote queue affects proxy queue');

    # $q2->limit = 39    doesn't work
    # $q2->{limit} = 39  also doesn't work
    $q2->limit(39);
    is(39, $q1->limit, 'limit on proxy queue affects remote queue');

    $q2->end;
    is(0, $q1->put(14), 'end call from proxy affects remote queue');
    Net::Objwrap::Server->SHUTDOWN if $^O eq 'MSWin32';
}

done_testing();
