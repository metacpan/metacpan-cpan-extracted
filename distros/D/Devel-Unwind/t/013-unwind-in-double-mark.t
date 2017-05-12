use strict;
use warnings;

use Test::More;
use Devel::Unwind;

my $i=0;
my $x;
mark FOO {
    $x = "foo";
    mark BAR {
        unwind BAR;
        fail "Execution resumed inside mark BAR after unwind";
    };
    pass "Execution resumed inside mark FOO after unwind";
    if ($i++>0) {
        fail "Execution resumed again after first mark BAR";
    }
    mark BAR {
        unwind BAR;
        fail "Execution resumed inside second mark BAR after unwind";
    };
    pass "Execution resumed after second mark BAR after unwind";
    mark BAZ {
        unwind FOO;
        fail "Execution resumed inside second mark BAR after unwind";
    };
    fail "Execution resumed inside mark FOO after unwind";
};
pass "Execution resumed after mark FOO";
is($x,'foo', 'Variable correctly set after mark block');
done_testing;
