use strict;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
use File::Slurp;
use File::Temp qw(tempfile);

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::Spread');

{
    my $string = $gc->do_task( 'Gearman::Driver::Test::Live::Spread::main' => 'some workload ...' );
    is( $$string, '12345', 'Spreading works (tests $worker->server attribute)' );
}

$test->shutdown;
