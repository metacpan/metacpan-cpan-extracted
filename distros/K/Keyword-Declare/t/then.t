use warnings;
use strict;

use Keyword::Declare;

keyword LAST (Block $block) :then(Statement* $etc, '}') {{{
        «$etc» } do «$block»;
}}}

print "1..7\n";
for my $n (1,3,5) {
    LAST { print "ok 7 - LAST\n" }
    for (1) {
        LAST { print "ok ".($n+1)."\n"; }
        print "ok $n\n";
    }
}

