use strict;
use warnings;

use Test::More;
use Image::DS9;
use Cwd;

BEGIN { plan( tests => 4 ) }

require './t/common.pl';


my $ds9 = start_up();

load_events( $ds9 );

test_stuff( $ds9, (
                   grid =>
                   [
                    [] => 1,
                    [] => 0,
                   ],

                  ) );


$ds9->grid(1);
unlink 'snooker.grid';
$ds9->grid( save => cwd() . '/snooker.grid' );
ok ( -f 'snooker.grid', 'grid save' );

$ds9->grid(0);
eval {
  $ds9->grid( load => cwd() . '/snooker.grid' );
};
diag $@ if $@;
ok(!$@, 'grid load' );
unlink 'snooker.grid';
