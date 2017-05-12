#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Math::Random::OO::UniformInt  
my ($test_array, $test_program);

BEGIN {
    $test_array = [
        { 
            new_args    => [], 
            data       =>  [   
                [0.2, 0],
                [0.5, 1],
            ]
        },
        { 
            new_args    => [1], 
            data       =>  [   
                [0.4, 0],
                [0.5, 1],
            ]
        },
        { 
            new_args    => [2], 
            data       =>  [   
                [0.25, 0],
                [0.34, 1],
                [0.67, 2]
            ]
        },
        { 
            new_args    => [1, 6], 
            data       =>  [   
                [0.1, 1],
                [0.3, 2],
                [0.5, 4],
                [0.7, 5]
            ]
        },
        { 
            new_args    => [-1, 1], 
            data       =>  [   
                [0.33, -1],
                [0.34, 0],
                [0.67, 1]
            ]
        },
        { 
            new_args    => [1,-1], 
            data       =>  [   
                [0.33, -1],
                [0.34, 0],
                [0.67, 1]
            ]
        },
        { 
            new_args    => [-1.56,1.23], 
            data       =>  [   
                [0.33, -1],
                [0.34, 0],
                [0.67, 1]
            ]
        },
    ];    
    $test_program = 0;
    $test_program += @{$_->{data}} + 1 for @$test_array;
}

use Test::More tests => (4 + $test_program);
use Test::Number::Delta within => 1e-5;
use Test::MockRandom 'Math::Random::OO::UniformInt';
BEGIN { Test::MockRandom->export_srand_to('Math::Random::OO::UniformInt') }
BEGIN { use_ok( 'Math::Random::OO::UniformInt' ); }

my $obj = Math::Random::OO::UniformInt->new ();
isa_ok ($obj, 'Math::Random::OO::UniformInt');
isa_ok ($obj->new, 'Math::Random::OO::UniformInt');
can_ok ($obj, qw( seed next ));

for my $case ( @$test_array ) {
    ok( $obj = $obj->new(@{$case->{new_args}}), 
        'creating object with new('.join(", ",@{$case->{new_args}}).')');
    for my $data (@{$case->{data}}) {
        my ($seed,$val) = @$data;
        $obj->seed($seed);
        delta_ok( $obj->next, $val, "does srand($seed),next() give $val?" );
    }
}

