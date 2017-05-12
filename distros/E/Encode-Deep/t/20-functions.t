use strict;
use warnings;

use Test::More tests => 3;
use Encode ();

use_ok( 'Encode::Deep', ':all' );

is(encode('iso-8859-1',"\x{c3a4}"), Encode::encode('iso-8859-1',"\x{c3a4}"), 'Plain encode iso-8859-1');
is(decode('iso-8859-1',"\xa4"), Encode::decode('iso-8859-1',"\xa4"), 'Plain decode iso-8859-1');
