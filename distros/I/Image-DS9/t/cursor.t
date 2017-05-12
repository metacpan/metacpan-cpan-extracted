use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 1 ) ;}

require 't/common.pl';


my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz');

eval {
  $ds9->cursor( 1,1 );
};
diag $@ if $@;
ok ( ! $@, "cursor" );





