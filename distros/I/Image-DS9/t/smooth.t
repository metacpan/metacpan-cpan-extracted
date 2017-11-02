use strict;
use warnings;

use Test::More;
use Image::DS9;
use Cwd;

BEGIN { plan( tests => 3 ) ;}

require './t/common.pl';


my $ds9 = start_up();
load_events($ds9);

test_stuff( $ds9, (
                   smooth =>
                   [
                    [] => 1,
                    function => 'boxcar',
                    radius => 3,
                   ],
                  ) );
