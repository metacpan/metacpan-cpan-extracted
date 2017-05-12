use strict;
use warnings;
use Test::More tests => 6;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::Quit');

{
    my $pid1 = $gc->do_task( 'Gearman::Driver::Test::Live::Quit::quit1' => '' );
    like( $$pid1, qr/^\d+$/, 'Got some number (pid)' );

    # tell worker to exit
    $gc->dispatch_background( 'Gearman::Driver::Test::Live::Quit::quit1' => 'exit' );

    my $pid2 = $gc->do_task( 'Gearman::Driver::Test::Live::Quit::quit1' => '' );
    like( $$pid2, qr/^\d+$/, 'Got again some number (pid)' );
    isnt( $$pid2, $$pid1, 'Worker got restarted, got a new pid' );
}

{
    my $pid1 = $gc->do_task( 'Gearman::Driver::Test::Live::Quit::quit2' => '' );
    like( $$pid1, qr/^\d+$/, 'Got some number (pid)' );

    # tell worker to die - in fact it doesnt die
    $gc->dispatch_background( 'Gearman::Driver::Test::Live::Quit::quit2' => 'die' );

    my $pid2 = $gc->do_task( 'Gearman::Driver::Test::Live::Quit::quit2' => '' );
    like( $$pid2, qr/^\d+$/, 'Got again some number (pid)' );
    is( $$pid2, $$pid1, 'Worker did not die' );
}

$test->shutdown;
