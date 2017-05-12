use strict;
use warnings;
use Test::More tests => 5;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
use File::Slurp;
use File::Temp qw(tempfile);

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::MaxIdleTime');

{
    my $pid1 = $gc->do_task( 'Gearman::Driver::Test::Live::MaxIdleTime::get_pid' => '' );
    like( $$pid1, qr~^\d+$~, 'Got some number (pid)' );

    # test max_idle_time (5 seconds)
    for ( 1 .. 3 ) {
        my $pid = $gc->do_task( 'Gearman::Driver::Test::Live::MaxIdleTime::get_pid' => '' );
        is( $$pid1, $$pid, 'Still the same PID' );
        sleep(2);
    }

    sleep(6);
    my $pid2 = $gc->do_task( 'Gearman::Driver::Test::Live::MaxIdleTime::get_pid' => '' );
    isnt( $$pid2, $$pid1, 'Got another PID' );
}

$test->shutdown;
