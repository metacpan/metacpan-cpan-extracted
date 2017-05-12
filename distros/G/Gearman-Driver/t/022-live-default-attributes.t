use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::DefaultAttributes');

{
    my $string = $gc->do_task( "Gearman::Driver::Test::Live::DefaultAttributes::job1" => 'workload' );
    is( $$string, 'ENCODE::DECODE::workload::DECODE::ENCODE', 'DefaultAttributes were set' );
}

{
    my $string = $gc->do_task( "Gearman::Driver::Test::Live::DefaultAttributes::job2" => 'workload' );
    is( $$string, 'ENCODE::workload::ENCODE', 'Job method returns $job->workload instead of $workload' );
}

{
    my $pid1 = $gc->do_task( "Gearman::Driver::Test::Live::DefaultAttributes::job3" => '' );
    my $pid2 = $gc->do_task( "Gearman::Driver::Test::Live::DefaultAttributes::job3" => '' );
    is( $$pid1, $$pid2, 'DefaultAttributes ProcessGroup works, got same pid for different jobs' );
}

$test->shutdown;
