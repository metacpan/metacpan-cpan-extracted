use strict;
use Test::More tests => 1;

require 't/testutils.pl';

use Find::Lib 'unexistent';
not_in_inc( 'unexistent' );
