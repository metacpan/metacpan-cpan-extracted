use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
use File::Slurp;
use File::Temp qw(tempfile);

my $test = Gearman::Driver::Test->new();
my $gc   = $test->gearman_client;

$test->prepare('Gearman::Driver::Test::Live::WithBaseClass');

{
    my ( $fh, $filename ) = tempfile( CLEANUP => 1 );
    $gc->do_task( 'Gearman::Driver::Test::Live::WithBaseClass::job1' => $filename );
    my $text = read_file($filename);
    is( $text, "begin ...\njob1 ...\nend ...\n", 'Begin/end blocks in worker have been run' );
}

{
    my ( $fh, $filename ) = tempfile( CLEANUP => 1 );
    $gc->do_task( 'Gearman::Driver::Test::Live::WithBaseClass::job2' => $filename );
    my $text = read_file($filename);
    is( $text, "begin ...\nend ...\n", 'Worker died, but begin -and- end blocks have been run' );
}

$test->shutdown;
