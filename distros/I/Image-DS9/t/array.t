use strict;
use warnings;

use Test::More;

use Image::DS9;

unless ( $Image::DS9::use_PDL )
{
  plan( skip_all => 'No PDL; skipping' );
}
else
{
  eval 'use PDL';
  plan( tests => 2 );
}

require 't/common.pl';

my $ds9 = start_up();

my $x = zeroes(20,20)->rvals;

eval {
  $ds9->array($x);
};
diag $@ if $@;
ok( ! $@, "PDL array" );
  
my $p = $x->get_dataref;
  
my @dims = $x->dims;
eval {
  $ds9->array($$p, { xdim => $dims[0], ydim => $dims[1], bitpix => -64 } );
};
ok ( ! $@, "raw array" );
