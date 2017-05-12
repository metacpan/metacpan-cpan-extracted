#
# $Id: 05_basic.t 4496 2010-06-18 15:19:43Z james $
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 2;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok('List::Uniq', ':all');

# simplest possible usage
is_deeply scalar uniq('foo','foo'), [ 'foo' ],
    'one of two duplicates removed';

#
# EOF
