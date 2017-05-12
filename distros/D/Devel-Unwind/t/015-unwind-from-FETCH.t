use warnings;
use strict;

use Test::More;
use Devel::Unwind;

sub TIESCALAR { bless [] }
sub FETCH {
    eval { eval {
        unwind LABEL;
    }};
}

my $a = "b";
mark LABEL {
    my $x;
    $a = "a";
    tie $x, 'main';
    my $y = $x;
    fail "Execution resumed inside mark block";
};
is($a, "a", "Variable correctly set after mark block");
pass "Execution resumed after mark block";
done_testing;
