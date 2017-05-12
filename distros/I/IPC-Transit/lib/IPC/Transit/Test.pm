package IPC::Transit::Test;
$IPC::Transit::Test::VERSION = '1.162230';
use strict;use warnings;
use Data::Dumper;
use IPC::Transit;

BEGIN {
    $IPC::Transit::config_dir = '/tmp/ipc_transit_test';
    $IPC::Transit::config_file = "transit_test_$$.conf";
    $IPC::Transit::test_qname = 'tr_perl_dist_test_qname';
    $IPC::Transit::test_qname1 = 'tr_perl_dist_test_qname1';
    $IPC::Transit::test_qname2 = 'tr_perl_dist_test_qname2';
};

sub
clear_test_queue {
    for(1..100) {
        my $m;
        eval {
            $m = IPC::Transit::receive(qname => $IPC::Transit::test_qname, nonblock => 1);
        };
        last if $m;
    }
}

sub run_daemon {
    my $prog = shift;
    print STDERR "\$prog=$prog\n";
    my $pid = fork;
    die "run_daemon: fork failed: $!" if not defined $pid;
    if(not $pid) { #child
        #exec "perl -Ilib bin/$prog -P/tmp/ipc_transit_test";
        exec $prog;
        exit;
    }
    return $pid;
}

sub kill_daemon {
    my $pid = shift;
    kill 15, $pid;
    sleep 1;
    kill 9, $pid;
}


END {
    IPC::Transit::Internal::_drop_all_queues();
};
1;
