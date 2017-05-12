#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Const::Fast;
use Iterator::Simple qw( iter list );

BEGIN {
    use_ok( 'Iterator::Simple::Util',
            qw( igroup ireduce isum
                imax imin imaxstr iminstr imax_by imin_by imaxstr_by iminstr_by
                iany inone inotall
                ifirstval ilastval
                ibefore ibefore_incl iafter iafter_incl
                inatatime )
        );
}

note "Testing igroup";

{    
    const my @DATA => ( [a => 1], [a => 2], [a => 3], [b => 1], [b => 2], [c => 1], [c => 2], [c => 3], [d => 1] );

    my $gr = igroup { $a->[0] eq $b->[0] } \@DATA;
    ok $gr, 'igroup succeeds';
    isa_ok $gr, Iterator::Simple::ITERATOR_CLASS;

    my $num_groups = 0;

    while ( my $grit = $gr->next ) {
        isa_ok $grit, Iterator::Simple::ITERATOR_CLASS;
        $num_groups++;
        my %seen;
        while( defined( $_ = $grit->next ) ) {
            $seen{ $_->[0] }++;
        }
        is scalar( keys %seen ), 1, 'Subroup has consistent key value';
    }

    is $num_groups, 4, 'Iterator returned 4 subgroups';
}

{
    my $gr = igroup { $a->[0] eq $b->[0] } [];
    isa_ok $gr, Iterator::Simple::ITERATOR_CLASS;
    ok !$gr->next, 'Empty iterator has no subgroups';
}

note "Testing ireduce";

{
    my $res = ireduce { $a + $b } iter [1..10];
    
    is $res, 55, 'ireduce an array of ints with +';
    
    is ireduce( sub { $a + $b }, iter [1..10] ), 55, 'same thing with a sub{}';

    is ireduce( sub { $a + $b }, 10, iter [1..10] ), 65, '...and with an initial vaule';
}

{
    my $it = iter( [] );

    ok !defined( ireduce { $a + $b } $it ), 'ireduce an empty iterator returns nothing';    
}

{
    my $it = iter( [ 1000 ] );

    is ireduce( sub { $a / $b }, $it ), 1000, 'ireduce a single-valued iterator returns the value';
}

note "Testing isum";

is isum( iter [1..10] ), 55, 'isum 1..10';
is isum( 10, iter [1..10] ), 65, 'isum 10 1..10';

note "Testing imax and imin";

{
    const my @NUMS => ( 10, 7, 3, 9, 40, -1, 11, 17, -41 );
    
    is imax( iter \@NUMS ), 40, 'imax';
    is imin( iter \@NUMS ), -41, 'imin';
}

note "Testing imax_by and imin_by";

{
    const my @DATA => map +{ k => $_ }, ( 10, 7, 3, 9, 40, -1, 11, 17, -41 );

    ok my $max = imax_by { $_->{k} } iter \@DATA;
    is_deeply $max, { k => 40 }, 'imax_by';

    ok my $min = imin_by { $_->{k} } iter \@DATA;
    is_deeply $min, { k => -41 }, 'imin_by';

    ok $min = imin_by { $_->{k} * $_->{k} } iter \@DATA;
    is_deeply $min, { k => -1 } , 'imin_by';
}

note "Testing imaxstr and iminstr";

{
    const my @STRS => qw( foo bar baz quux );

    is imaxstr( \@STRS ), 'quux', 'imaxstr';
    is iminstr( \@STRS ), 'bar', 'iminstr';
}   

note "Testing imaxstr_by and iminstr_by";

{
    const my @STRS => qw( foo bar baz quux );

    ok my $max = imaxstr_by { join '', reverse split // } iter \@STRS;
    is $max, 'baz', 'imaxstr_by';

    ok my $min = iminstr_by { join '', reverse split // } iter \@STRS;
    is $min, 'foo', 'iminstr_by';
}

note "Testing iany";

ok iany { $_ > 2 } iter [0..10];

ok !iany { $_ > 10 } iter [0..10];

note "Testing inone";

ok inone { $_ > 10 } iter [0..10];

ok !inone { $_ > 2 } iter [0..10];

note "Testing inotall";

ok inotall { $_ > 2 } iter [0..10];
ok !inotall { $_ <= 10 } iter [0..10];

note "Testing ifirstval";
{
    my $v = ifirstval { $_ > 2 } iter [0..10];
    is $v, 3, 'ifirstval';
}

note "Testing ilastval";
{
    my $v = ilastval { $_ < 7 } iter [0..10];
    is $v, 6, 'ilastval';
}

note "Testing ibefore";
{
    ok my $it = ibefore { $_ > 2 } iter [0..10];
    isa_ok $it, Iterator::Simple->ITERATOR_CLASS;
    is_deeply list($it), [0,1,2];    
}

note "Testing ibefore_incl";
{
    ok my $it = ibefore_incl { $_ > 2 } iter [0..10];
    isa_ok $it, Iterator::Simple->ITERATOR_CLASS;
    is_deeply list($it), [0,1,2,3];
}

note "Testing iafter";
{
    ok my $it = iafter { $_ > 2 } iter [0..10];
    isa_ok $it, Iterator::Simple->ITERATOR_CLASS;
    is_deeply list($it), [4..10];
}

note "Testing iafter_incl";
{
    ok my $it = iafter_incl { $_ > 2 } iter [0..10];
    isa_ok $it, Iterator::Simple->ITERATOR_CLASS;
    is_deeply list($it), [3..10];
}

note "Testing inatatime";
{
    ok my $it = inatatime 3, iter [0..10];
    isa_ok $it, Iterator::Simple->ITERATOR_CLASS;
    is_deeply list($it), [ [0..2], [3..5], [6..8], [9,10] ];
}

done_testing();
