#
# $Id: 01_use.t 4496 2010-06-18 15:19:43Z james $
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

use_ok('List::Uniq');
is($List::Uniq::VERSION, '0.20', 'check module version');

#
# EOF
