use strict;
use warnings;

use Test::More;
use Image::DS9;
use Cwd;

BEGIN { plan( tests => 15 ) ;}

require './t/common.pl';


my $ds9 = start_up();

test_stuff( $ds9, (
                   print =>
                   [
                    destination => 'file',
                    destination => 'printer',
                    command => 'print_this',
                    filename => 'print_this.ps',
                    palette => 'gray',
                    palette => 'cmyk',
                    palette => 'rgb',
                    level => 1,
                    level => 2,
                    resolution => 53,
                    resolution => 72,
                    resolution => 75,
                    resolution => 150,
                    resolution => 300,
                    resolution => 600,
                   ],
                  ) );

