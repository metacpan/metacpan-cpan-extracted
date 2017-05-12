#!perl
use Test::More;
use Test::Deep;
use List::Flatten::Recursive;

my @flat_list = ( 1..10 );

my $circ1 = [ 1..5 ];
my $circ2 = [ 6..10 ];
push @$circ1, $circ2;
push @$circ2, $circ1;

cmp_deeply(
    [ flat($circ1) ],
    \@flat_list,
    "Flatten circular listrefs."
);

done_testing();
