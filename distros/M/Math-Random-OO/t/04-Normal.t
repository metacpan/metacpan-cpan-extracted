#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Math::Random::OO::Normal  

my ($test_array, $test_program);

BEGIN {
    $test_array = [
        { 
            new_args    => [], 
            data       =>  [   
                [0.5, 0],
                [0.3, -0.52440],
                [0.9, 1.28155],
                [0.1, -1.28155]
            ]
        },
        { 
            new_args    => [5], 
            data       =>  [   
                [0.5, 5],
                [0.3, 4.47560],
                [0.9, 6.28155]
            ]
        },
        { 
            new_args    => [0,3], 
            data       =>  [   
                [0.5, 0],
                [0.3, -1.57320],
                [0.9, 3.84465]
            ]
        },
        { 
            new_args    => [0,-3], 
            data       =>  [   
                [0.5, 0],
                [0.3, -1.57320],
                [0.9, 3.84465]
            ]
        },
    ];    
    $test_program = 0;
    $test_program += @{$_->{data}} + 1 for @$test_array;
}

use Test::More tests => (5 + $test_program);
use Test::Number::Delta within => 1e-5;
use Test::MockRandom 'Math::Random::OO::Normal';
BEGIN { Test::MockRandom->export_srand_to('Math::Random::OO::Normal') }

BEGIN { use_ok( 'Math::Random::OO::Normal' ); }

my $obj = Math::Random::OO::Normal->new ();
isa_ok ($obj, 'Math::Random::OO::Normal');
isa_ok ($obj->new, 'Math::Random::OO::Normal');
can_ok ($obj, qw( seed next ));
eval { $obj->next };
is( $@, "", 'next handles 0 correctly?');

for my $case ( @$test_array ) {
    ok( $obj = $obj->new(@{$case->{new_args}}), 
        'creating object with new('.join(", ",@{$case->{new_args}}).')');
    for my $data (@{$case->{data}}) {
        my ($seed,$val) = @$data;
        $obj->seed($seed);
        delta_ok( $obj->next, $val, "does srand($seed),next() give $val?" );
    }
}

