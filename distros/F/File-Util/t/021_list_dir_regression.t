
use strict;
use warnings;

# the original intent of this test was to isolate and test solely the
# list_dir method, but it became immediatley apparent that you can't
# very well test list_dir() unless you have a good directory tree first;
# this led to the combining of the make_dir and list_dir testing routines

use Test::More tests => 2;
use Test::NoWarnings;

use File::Temp qw( tempdir );

use lib './lib';
use File::Util qw( SL NL OS );

# one recognized instantiation setting
my $ftl = File::Util->new( );

my $tempdir     = tempdir( CLEANUP => 1 );
my $testbed     = $tempdir . SL . $$ . SL . time;
my @test_dirs   = qw/ Fin Rey Kylo Poe /;

for my $tdir ( @test_dirs )
{
   $ftl->make_dir( $testbed . SL . $tdir )
}

is_deeply
(
   [ sort $ftl->list_dir( $testbed ) ],
   [ sort qw( . .. ), @test_dirs  ],
   'regression: plain dir listing with only subdirs present (no files)'
);

exit;
