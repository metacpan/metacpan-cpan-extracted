#!perl -T

use 5.006;
use strict;
use warnings;
use utf8;

use Test::More tests => 22;

use Encode qw(encode decode);
use Encode::Safename;

# uppercase characters
is(encode('safename', 'A'), '{a}',
    'encode a single uppercase character');
is(encode('safename', 'ABC'), '{abc}',
    'encode multiple uppercase characters');

is(decode('safename', '{a}'), 'A',
    'decode a single uppercase character');
is(decode('safename', '{abc}'), 'ABC',
    'decode multiple uppercase characters');

# spaces
is(encode('safename', ' '), '_',
    'encode a single space');
is(encode('safename', '   '), '___',
    'encode multiple spaces');

is(decode('safename', '_'), ' ',
    'decode a single space');
is(decode('safename', '___'), '   ',
    'decode multiple spaces');

# safe characters
is(encode('safename', 'a'), 'a',
    'encode a single safe character');
is(encode('safename', 'a1@'), 'a1@',
    'encode multiple safe characters');

is(decode('safename', 'a'), 'a',
    'decode a single safe character');
is(decode('safename', 'a1@'), 'a1@',
    'decode multiple safe characters');

# other characters
is(encode('safename', ':'), '(3a)',
    'encode a single other character');
is(encode('safename', 'é'), '(e9)',
    'encode a single Unicode character');
is(encode('safename', ':é?'), '(3a)(e9)(3f)',
    'encode multiple other characters');
is(encode('safename', '_(){}'), '(5f)(28)(29)(7b)(7d)',
    'encode control characters');

is(decode('safename', '(3a)'), ':',
    'decode a single other character');
is(decode('safename', '(e9)'), 'é',
    'decode a single Unicode character');
is(decode('safename', '(3a)(e9)(3f)'), ':é?',
    'decode multiple other characters');
is(decode('safename', '(5f)(28)(29)(7b)(7d)'), '_(){}',
    'decode control characters');

# combinations
is(encode('safename', 'Abc Déf Gh1'), '{a}bc_{d}(e9)f_{g}h1',
    'encode a string');

is(decode('safename', '{a}bc_{d}(e9)f_{g}h1'), 'Abc Déf Gh1',
    'decode a string');
