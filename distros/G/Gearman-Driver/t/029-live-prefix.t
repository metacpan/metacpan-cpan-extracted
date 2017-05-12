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

$test->prepare('Gearman::Driver::Test::Live::Prefix');

{
    my $pong = $gc->do_task( 'ping' => '' );
    is( $$pong, 'pong', 'Custom worker prefix working' );
}

$test->shutdown;
