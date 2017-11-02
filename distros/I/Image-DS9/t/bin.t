use strict;
use warnings;

use Test::More;
use Image::DS9;
use Cwd;

BEGIN { plan( tests => 7 ) ;}

require './t/common.pl';


my $ds9 = start_up();
load_events($ds9);

test_stuff( $ds9, (
                   bin =>
                   [
                    about => [ 0.023, 0.023 ],
                    buffersize => 256,
                    cols => [ qw (rt_x rt_y ) ],
                    factor => [ 0.050, 0.01 ],
                    depth => 1,
                    filter => 'rt_time > 0.5',
                    function => 'average',
                   ],
                  ) );
