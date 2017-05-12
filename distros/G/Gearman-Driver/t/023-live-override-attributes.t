use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::OverrideAttributes');

{
    my $string = $gc->do_task( "Gearman::Driver::Test::Live::OverrideAttributes::job1" => 'workload' );
    is( $$string, 'ENCODE::DECODE::workload::DECODE::ENCODE', 'Attributes were overridden' );
}

{
    my $string = $gc->do_task( "Gearman::Driver::Test::Live::OverrideAttributes::job2" => 'workload' );
    is( $$string, 'ENCODE::workload::ENCODE', 'Job method returns $job->workload instead of $workload' );
}

$test->shutdown;
