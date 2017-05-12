
use Log::Any::Adapter;
use Log::Any qw($log);
use Time::HiRes qw( gettimeofday tv_interval );

my $n = 20000;

for $ignore_reply ( 0 .. 1 ) {

    Log::Any::Adapter->set( 'Redis', ignore_reply => $ignore_reply,
        host => '192.168.0.20'
    );

    my $t0 = [gettimeofday];
    $log->info('Hello, Redis') for 1 .. $n;
    my $elapsed = tv_interval($t0);

    printf "%i log entries, ignore_reply = %i: elapsed: %f sec\n", $n, $ignore_reply, $elapsed;
}

__DATA__

with redis on localhost:
20000 log entries, ignore_reply = 0: elapsed: 1.246693 sec
20000 log entries, ignore_reply = 1: elapsed: 0.680638 sec

with redis in local network (avg. ping to host: 0.306ms):
20000 log entries, ignore_reply = 0: elapsed: 8.437271 sec
20000 log entries, ignore_reply = 1: elapsed: 0.406765 sec
