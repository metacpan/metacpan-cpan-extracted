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

$test->prepare( '--namespaces Gearman::Driver::Test::Live::RuntimeOption', "--configfile $FindBin::Bin/gearman_driver.yml" );

my $job1 = 'Gearman::Driver::Test::Live::RuntimeOption::job1';
{
    my $result_ref = $gc->do_task($job1);
    is( ${$result_ref}, "Test", 'worker attribute Foo runtime changed to Test' );
}

my $job2 = 'Gearman::Driver::Test::Live::RuntimeOption::job2';
{
    my $result_ref = $gc->do_task($job2);
    is( ${$result_ref}, "GlobalTest", 'GLOBAL worker attribute global_foo runtime changed to GlobalTest' );
}

{
    my $telnet = $test->telnet_client;
    $telnet->print("status");
    while ( my $line = $telnet->getline() ) {
        last if $line eq ".\n";
        chomp $line;
        if ( $line =~ qr/^$job1/ ) {
            like( $line, qr/^$job1  2  10  2 .*$/, 'job runtime attributes job1' );
        }
        elsif ( $line =~ qr/^$job2/ ) {
            like( $line, qr/^$job2  1   1  1 .*$/, 'job runtime attributes job2' );
        }
        else {
            fail("Unknown job: $line");
        }
    }
}
$test->shutdown;
