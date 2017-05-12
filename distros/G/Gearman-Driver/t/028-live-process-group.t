use strict;
use warnings;
use Test::More tests => 4;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
use File::Slurp;
use File::Temp qw(tempfile);

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::ProcessGroup');

{
    my $pid1 = $gc->do_task( 'Gearman::Driver::Test::Live::ProcessGroup::job1' => '' );
    my $pid2 = $gc->do_task( 'Gearman::Driver::Test::Live::ProcessGroup::job2' => '' );
    my $pid3 = $gc->do_task( 'Gearman::Driver::Test::Live::ProcessGroup::job3' => '' );
    my $pid4 = $gc->do_task( 'Gearman::Driver::Test::Live::ProcessGroup::job4' => '' );
    my $pid5 = $gc->do_task( 'Gearman::Driver::Test::Live::ProcessGroup::job5' => '' );
    is( $$pid1, $$pid2, 'Same pid for all jobs of ProcessGroup group1 #1' );
    is( $$pid1, $$pid3, 'Same pid for all jobs of ProcessGroup group1 #2' );
    is( $$pid1, $$pid4, 'Same pid for all jobs of ProcessGroup group1 #3' );
    isnt( $$pid1, $$pid5, 'Not same pid because job5 doesnt use ProcessGroup' );
}

$test->shutdown;
