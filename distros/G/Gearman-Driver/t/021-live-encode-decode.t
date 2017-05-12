use strict;
use warnings;
use Test::More tests => 7;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::EncodeDecode');

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job1' => 'some workload ...' );
    is( $$string, 'STANDARDDECODE::some workload ...::STANDARDDECODE', 'Standard decoding works' );
}

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job2' => 'some workload ...' );
    is( $$string, 'CUSTOMDECODE::some workload ...::CUSTOMDECODE', 'Custom decoding works' );
}

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job3' => 'some workload ...' );
    is( $$string, 'STANDARDENCODE::some workload ...::STANDARDENCODE', 'Standard encoding works' );
}

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job4' => 'some workload ...' );
    is( $$string, 'CUSTOMENCODE::some workload ...::CUSTOMENCODE', 'Custom encoding works' );
}

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job5' => 'some workload ...' );
    is( $$string, 'some workload ...', 'Job does not have any encode/decode attribute' );
}

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job6' => 'some workload ...' );
    is(
        $$string,
        'STANDARDENCODE::STANDARDDECODE::some workload ...::STANDARDDECODE::STANDARDENCODE',
        'Job has encode -and- decode attribute'
    );
}

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::EncodeDecode::job7' => 'some workload ...' );
    is(
        $$string,
        'CUSTOMENCODE::CUSTOMDECODE::some workload ...::CUSTOMDECODE::CUSTOMENCODE',
        'Job has custom encode -and- decode attribute'
    );
}

$test->shutdown;
