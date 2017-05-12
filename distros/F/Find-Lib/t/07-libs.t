use strict;
use Test::More tests => 2;

require 't/testutils.pl';

use Find::Lib 'libs';
use Foo a => 1, b => 42;
in_inc( 'libs' );
