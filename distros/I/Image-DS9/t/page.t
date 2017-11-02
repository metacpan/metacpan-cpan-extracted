use strict;
use warnings;

use Test::More;
use Image::DS9;
use Cwd;

BEGIN { plan( tests => 9 ) ;}

require './t/common.pl';


my $ds9 = start_up();

test_stuff( $ds9, (
                   page =>
                   [
                    [qw( setup orientation )] => 'landscape',
                    [qw( setup orientation )] => 'portrait',
                    [qw( setup pagescale )] => 'fixed',
                    [qw( setup pagescale )] => 'scaled',
                    [qw( setup pagesize )] => 'legal',
                    [qw( setup pagesize )] => 'tabloid',
                    [qw( setup pagesize )] => 'poster',
                    [qw( setup pagesize )] => 'a4',
                    [qw( setup pagesize )] => 'letter',
                   ],
                  ) );

