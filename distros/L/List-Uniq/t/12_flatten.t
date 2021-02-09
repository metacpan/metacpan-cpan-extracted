#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 6;

use_ok('List::Uniq', ':all');

my $elements = [ [ 'foo' ], [ 'bar' ], [ 'baz', 'quux' ] ];

is_deeply scalar uniq($elements), [ qw|foo bar baz quux| ],
    'arrayrefs flatten implicitly';

is_deeply scalar uniq( { flatten => 1 }, $elements ), [ qw|foo bar baz quux| ],
    'arrayrefs flatten explicitly';

my $ret = ( uniq( { flatten => 0 }, $elements ) )[0];
for( 1 .. 3 ) {
    is $ret->[$_], $elements->[$_], "arrayrefs do not flatten explicitly $_/3";
}

#
# EOF
