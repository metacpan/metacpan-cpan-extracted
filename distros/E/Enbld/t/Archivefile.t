#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Temp;

use Test::More;

require_ok( 'Enbld::Archivefile' );

my $path = File::Spec->catfile( $FindBin::Bin, 'TestApp-1.0.tar.gz' );

my $temp = File::Temp->newdir;

my $archivefile = Enbld::Archivefile->new( $path );
ok( -d $archivefile->extract( $temp ), 'archive file extract' );

done_testing();
