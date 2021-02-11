use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'List::Uniq', ':all' );

# array refs following empty array refs are not flattened
is_deeply scalar uniq( 'foo', 'bar', [], ['foo'], 'quux' ), [qw|foo bar quux|], 'array refs following empty array refs';
