use strict;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
use File::Slurp;
use File::Temp qw(tempfile);


eval { require Gearman::XS };
my $no_gearman_xs = $@;

SKIP: {
    skip ('You need Gearman:XS for this test', 1)
        if $no_gearman_xs;

    $ENV{GEARMAN_DRIVER_ADAPTOR} = 'Gearman::Driver::Adaptor::XS';

    my $test = Gearman::Driver::Test->new();
    my $gc   = $test->gearman_client;

    $test->prepare('Gearman::Driver::Test::Live::Shutdown');

    my ( $fh, $filename ) = tempfile( CLEANUP => 1 );
    $gc->do_task( 'Gearman::Driver::Test::Live::Shutdown::job1' => $filename );
    my $text = read_file($filename);
    is( $text, "begin ...\nstarted job1 ...\ndone with job1 ...\nend ...\n", 'Worker completed task during shutdown' );
};
