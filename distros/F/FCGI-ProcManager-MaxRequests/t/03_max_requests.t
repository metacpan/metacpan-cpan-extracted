use strict;
use Test::More tests => 4;

use FCGI::ProcManager::MaxRequests;

pipe my $server_in, my $test_out;
pipe my $test_in,   my $server_out;

my $pid;
if ( $pid = fork ) {
    close $server_out;
    close $server_in;
    local $SIG{CHLD} = 'IGNORE';
    my @spids;

    # test code
    foreach my $req ( 1 .. 5 ) {
        syswrite $test_out, "req $req\n";
        my $in = <$test_in>;
        fail("something wrong") unless $in =~ /server\((\d+)\): req $req/;
        push @spids, $1;
    }
    close $test_out;
    close $test_in;
    kill TERM => $pid;
    waitpid( $pid, 0 );
    is( $spids[0], $spids[1], '1 and 2 requests was done by same process' );
    isnt( $spids[1], $spids[2], '2 and 3 requests was done by distinct processes' );
    is( $spids[2], $spids[3], '3 and 4 requests was done by same process' );
    isnt( $spids[3], $spids[4], '4 and 5 requests was done by distinct processes' );
}
else {
    die "Can't fork: $!" unless defined $pid;
    close $test_in;
    close $test_out;

    # manager
    my $m = FCGI::ProcManager::MaxRequests->new(
        {
            n_processes  => 1,
            no_signals   => 1,
            max_requests => 2,
        }
    );

    $m->pm_manage;

    while ( my $msg = <$server_in> ) {
        $m->pm_pre_dispatch();
        chomp $msg;
        syswrite $server_out, $m->role . "(" . $$ . "): $msg\n";
        $m->pm_post_dispatch();
    }
    exit(0);    # think, that test close pipe
}

