use strict;
use Test::More tests => 2;

require 't/testutils.pl';

use Find::Lib 'libs';

ok "compiled...";
in_inc( 'libs' );
