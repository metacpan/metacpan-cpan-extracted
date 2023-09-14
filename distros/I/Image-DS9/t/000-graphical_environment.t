#! perl

use Test2::V0;
use Test2::Tools::Command;
use Test::Lib;
use My::Util 'yesno';

skip_all( 'using xvfb; not checking for graphical environment' )
  if yesno( $ENV{TEST_IMAGE_DS9_XVFB} );

command {
    name => 'in graphical enviroment',
    args => [ 'ds9', '-quit' ],
    # args => [ 'false' ],
    status  => 0,
    timeout => 20,
};

is_exit( $? ) or bail_out;

done_testing;

