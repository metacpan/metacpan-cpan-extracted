use Test::More 'no_plan';

use List::Maker;

sub test (&@) {
    my ($test, $desc) = @_;
    my ($res) = eval { $test->(); 1; };
    like $@, qr/\A$desc/ => $desc;
}

test { <1..10 x -1> } 'Sequence <1, 0, -1...> will never reach 10';
test { <1..-10 x 1> } 'Sequence <1, 2, 3...> will never reach -10';
test { <1,3..-10> }   'Sequence <1, 3, 5...> will never reach -10';
test { <1,-2..10> }   'Sequence <1, -2, -5...> will never reach 10';
test { <1,1..10> }    'Sequence <1, 1, 1...> will never reach 10';
test { <2..10x0> }    'Sequence <2, 2, 2...> will never reach 10';
test { <3,3..-10> }   'Sequence <3, 3, 3...> will never reach -10';
test { <4..-10x0> }   'Sequence <4, 4, 4...> will never reach -10';

is_deeply [<1,1..1>], [1] =>  'Sequence <1, 1, 1...> will reach 1';
is_deeply [<2..2x0>], [2] =>  'Sequence <2, 2, 2...> will reach 2';
