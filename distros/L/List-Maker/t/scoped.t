use Test::More 'no_plan';

is_deeply [<1..10>],  ['1..10']                => 'leading <1..10>';

{
    use List::Maker;
    is_deeply [<1..10>],  [1,2,3,4,5,6,7,8,9,10]   => 'scoped <1..10>';
}

if ($] < 5.010) {
    is_deeply [<1..10>],  [1,2,3,4,5,6,7,8,9,10]   => 'trailing file-scoped <1..10>';
}
else {
    is_deeply [<1..10>],  ['1..10']                => 'trailing block-scoped <1..10>';
}

