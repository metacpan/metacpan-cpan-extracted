use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 2 ) ;}

require './t/common.pl';

my $ds9 = start_up();

SKIP: {
      skip 'iconify currently untestable', 2;

test_stuff( $ds9, (
                   iconify =>
                   [
                    [] => 1,
                    [] => 0,
                   ],
                  ) );

}
