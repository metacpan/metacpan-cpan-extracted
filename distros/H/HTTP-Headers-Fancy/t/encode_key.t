#!perl

use Test::More tests => 13;

use HTTP::Headers::Fancy qw(encode_key);

is encode_key('X')             => 'x';
is encode_key('-X')            => 'x-x';
is encode_key('-foo')          => 'x-foo';
is encode_key('foo')           => 'foo';
is encode_key('foO')           => 'fo-o';
is encode_key('fOo')           => 'f-oo';
is encode_key('fOO')           => 'f-o-o';
is encode_key('FFF')           => 'f-f-f';
is encode_key('xx-xx')         => 'xx-xx';
is encode_key('AbcXyz')        => 'abc-xyz';
is encode_key('abc_xyz')       => 'abc-xyz';
is encode_key('abc_Xyz')       => 'abc-xyz';
is encode_key('x___x___x___x') => 'x-x-x-x';

done_testing;
