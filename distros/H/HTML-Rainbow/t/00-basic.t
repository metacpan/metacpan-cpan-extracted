# 00-basic.t
#
# Test suite for HTML::Rainbow
# Make sure the basic stuff works
#
# copyright (C) 2009 David Landgren

use strict;
use Test::More tests => 6;

diag( "testing HTML::Rainbow v$HTML::Rainbow::VERSION" );

BEGIN { use_ok('HTML::Rainbow', 'rainbow') }

like (rainbow('a'), qr{<font color="#[\da-f]{6}">a</font>}, 'rainbow a');

like (rainbow('ab'),
    qr{<font color="#[\da-f]{6}">a</font><font color="#[\da-f]{6}">b</font>},
    'rainbow ab'
);

like (rainbow('a b'),
    qr{<font color="#[\da-f]{6}">a</font> <font color="#[\da-f]{6}">b</font>},
    'rainbow a b'
);

is (rainbow(undef), '', 'rainbow undef');
like (rainbow(undef, 'a'), qr{<font color="#[\da-f]{6}">a</font>}, 'rainbow undef a');
