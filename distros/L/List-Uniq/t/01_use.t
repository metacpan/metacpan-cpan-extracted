#
# $Id$
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 1;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok('List::Uniq');
local $List::Uniq::VERSION = $List::Uniq::VERSION || 'from repo';
note("List::Uniq $List::Uniq::VERSION, Perl $], $^X");

#
# EOF
