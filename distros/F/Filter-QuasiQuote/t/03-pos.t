use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';
use t::data::QuotePos;

is [:pos|hello|], 'Line 9, Col 4, File t/03-pos.t';
is [:pos|hello|] . ' ' . [:pos|foo|], 'Line 10, Col 4, File t/03-pos.t Line 10, Col 26, File t/03-pos.t';
is ( [:pos|
    world
    hello|], 'Line 11, Col 6, File t/03-pos.t');
is ([:eval|256+1|], 257, 'eval still works');
is ([:pos|xxx|], 'Line 15, Col 5, File t/03-pos.t', 'pos still right');
is (__LINE__, 16, 'pos still right');
#is (eval '__LINE__', 17, 'pos still right');

