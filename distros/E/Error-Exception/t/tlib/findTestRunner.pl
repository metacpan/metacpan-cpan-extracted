use strict;
use warnings;

use Module::Locate  qw( locate );
use File::Basename;
use File::Spec::Functions;

my $loc = locate( 'Test::Unit' );
my $dir = dirname( $loc );
my $testrunner = catfile( $dir, 'TestRunner.pl' );

die "$testrunner does not exist" if( ! -f $testrunner );

print "$testrunner\n";

1;
