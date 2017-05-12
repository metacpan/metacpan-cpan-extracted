#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Math::Random::OO::Bootstrap  

use Test::MockRandom 'Math::Random::OO::Bootstrap';
BEGIN { Test::MockRandom->export_srand_to('Math::Random::OO::Bootstrap') }

my ($test_array, $test_program);

BEGIN {
    $test_array = [
        { 
            name        => "list",
            new_args    => [ 1, 2, 2, 3 ], 
            data       =>  [   
                [0.2, 1],
                [0.5, 2],
                [oneish, 3]
            ]
        },
        { 
            name        => "arrayref",
            new_args    => [ [1, 2, 2, 3 ] ], 
            data       =>  [   
                [0.2, 1],
                [0.5, 2],
                [oneish, 3]
            ]
        },
    ];    
    $test_program = 0;
    $test_program += @{$_->{data}} + 1 for @$test_array;
}

use Test::More tests => (5 + $test_program);
use Test::Number::Delta within => 1e-5;
BEGIN { use_ok( 'Math::Random::OO::Bootstrap' ); }

my $obj;
eval { Math::Random::OO::Bootstrap->new() };
ok( $@, 'does new die with no arguments?' );
$obj = Math::Random::OO::Bootstrap->new(1);
isa_ok ($obj, 'Math::Random::OO::Bootstrap');
isa_ok ($obj->new(1), 'Math::Random::OO::Bootstrap');
can_ok ($obj, qw( seed next ));

for my $case ( @$test_array ) {
    ok( $obj = $obj->new(@{$case->{new_args}}), 
        'creating object with '.$case->{name}.' args to new()');
    for my $data (@{$case->{data}}) {
        my ($seed,$val) = @$data;
        $obj->seed($seed);
        delta_ok( $obj->next, $val, "does srand($seed),next() give $val?" );
    }
}


