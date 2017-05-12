use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 1 ) ;}

require 't/common.pl';


my $ds9 = start_up();

eval {
  $ds9->raise();
};
diag( $@ ) if $@;
ok ( ! $@, 'version' );
