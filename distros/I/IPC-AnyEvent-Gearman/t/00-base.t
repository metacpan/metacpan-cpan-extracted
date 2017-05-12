#!/usr/bin/perl
use Test::More tests=>2;
use AnyEvent;
use AnyEvent::Gearman;

my $useok;
BEGIN{
    $useok = use_ok('Gearman::Server');
}

if( !$useok ){
    fail();
    done_testing();
    exit;
}
my $condvar = AE::cv;
use IO::Socket::INET;

my $pid = fork();
if( !$pid ){
    exec('gearmand -p 9999');
    die "cannot gearmand"
}
sleep(3);
my $gw = gearman_worker 'localhost:9999';
$gw->register_function( reverse => sub{ my $job = shift;
    my $res = reverse $job->workload;
    $job->complete($res);
    },);
my $gc = gearman_client 'localhost:9999';
$gc->add_task( reverse => 'test',
    on_complete => sub{
        my $result = $_[1];
        is($result,'tset');
        $condvar->send();
    },
    on_fail => sub{
        fail();
        $condvar->send();
    });

my $timeout = AE::timer 10, 0, sub{ 
print "TIMEOUT\n";
$condvar->send(); };

$condvar->recv;
done_testing();
undef($timeout);
undef($gc);
undef($gw);
kill 9,$pid;
