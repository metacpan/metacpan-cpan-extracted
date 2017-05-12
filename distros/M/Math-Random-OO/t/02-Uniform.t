#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Math::Random::OO::Uniform  
my ($test_array, $test_program);

BEGIN {
    $test_array = [
        { 
            new_args    => [], 
            data       =>  [   
                [0.5, 0.5],
                [0.23, 0.23]
            ]
        },
        { 
            new_args    => [2], 
            data       =>  [   
                [0.4, 0.8],
                [0.7, 1.4]
            ]
        },
        { 
            new_args    => [1, 6], 
            data       =>  [   
                [0.5, 3.5],
                [0.1, 1.5]
            ]
        },
        { 
            new_args    => [-1, 1], 
            data       =>  [   
                [0.5, 0],
                [0.6, 0.2]
            ]
        },
        { 
            new_args    => [2,-2], 
            data       =>  [   
                [0.5, 0],
                [0.6, 0.4]
            ]
        },
    ];    
    $test_program = 0;
    $test_program += @{$_->{data}} + 1 for @$test_array;
}

use Test::More tests => (4 + $test_program);
use Test::Number::Delta 0.14 within => 1e-5;
use Test::MockRandom 0.95 'Math::Random::OO::Uniform';
BEGIN { Test::MockRandom->export_srand_to('Math::Random::OO::Uniform') }
BEGIN { use_ok( 'Math::Random::OO::Uniform' ); }

my $obj = Math::Random::OO::Uniform->new ();
isa_ok ($obj, 'Math::Random::OO::Uniform');
isa_ok ($obj->new, 'Math::Random::OO::Uniform');
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

