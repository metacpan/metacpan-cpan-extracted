use strict;
use warnings;

use Test::Most;
use Test::Deep;

plan qw/no_plan/;

#use Data::Dump qw/dump/;
#print dump($left), "\n";
#print dump($merged), "\n";

use Hash::Merge::Simple qw/merge clone_merge dclone_merge/;

my ($left, $right, $result);

SKIP: {
    eval "require Clone;" or skip "Clone required for this test";
    $left = { foo => { bar => 2 } };
    $right = { baz => 4 };
    $result = clone_merge( $left, $right );
    $left->{foo}{bar} = 3 ;
    $left->{foo}{aaa} = 5 ;
    cmp_deeply $left, { foo => { bar => 3, aaa => 5 } };
    cmp_deeply $result, { foo => { bar => 2 }, baz => 4 };
}

SKIP: {
    eval "require Storable;" or skip "Storable required for this test";
    $left = { foo => { bar => 2 } };
    $right = { baz => 4 };
    $result = dclone_merge( $left, $right );
    $left->{foo}{bar} = 3 ;
    $left->{foo}{aaa} = 5 ;
    cmp_deeply $left, { foo => { bar => 3, aaa => 5 } };
    cmp_deeply $result, { foo => { bar => 2 }, baz => 4 };
}

$left = { foo => { bar => 2 } };
$right = { baz => 4 };
$result = merge( $left, $right );
$left->{foo}{bar} = 3 ;
$left->{foo}{aaa} = 5 ;
cmp_deeply $left, { foo => { bar => 3, aaa => 5 } };
cmp_deeply $result, { foo => { aaa => 5, bar => 3 }, baz => 4 };
