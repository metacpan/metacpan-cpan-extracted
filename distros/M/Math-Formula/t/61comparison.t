#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

my @numeric = (
	[ true  => '1 <  2' ],
	[ false => '2 <  2' ],
	[ false => '3 <  2' ],

	[ true  => '1 <= 2' ],
	[ true  => '2 <= 2' ],
	[ false => '3 <= 2' ],

	[ false => '1 == 2' ],
	[ true  => '2 == 2' ],
	[ false => '3 == 2' ],

	[ true  => '1 != 2' ],
	[ false => '2 != 2' ],
	[ true  => '3 != 2' ],

	[ false => '1 >= 2' ],
	[ true  => '2 >= 2' ],
	[ true  => '3 >= 2' ],

	[ false => '1 >  2' ],
	[ false => '2 >  2' ],
	[ true  => '3 >  2' ],
);

my @textual = (
	[ true  => '"a" lt "b"' ],
	[ false => '"b" lt "b"' ],
	[ false => '"c" lt "b"' ],

	[ true  => '"a" le "b"' ],
	[ true  => '"b" le "b"' ],
	[ false => '"c" le "b"' ],

	[ false => '"a" eq "b"' ],
	[ true  => '"b" eq "b"' ],
	[ false => '"c" eq "b"' ],

	[ true  => '"a" ne "b"' ],
	[ false => '"b" ne "b"' ],
	[ true  => '"c" ne "b"' ],

	[ false => '"a" ge "b"' ],
	[ true  => '"b" ge "b"' ],
	[ true  => '"c" ge "b"' ],

	[ false => '"a" gt "b"' ],
	[ false => '"b" gt "b"' ],
	[ true  => '"c" gt "b"' ],

	#TODO: checks which demonstrate Unicode::Collate
);

foreach (@numeric, @textual)
{   my ($result, $rule) = @$_;

    $expr->_test($rule);
    my $eval = $expr->evaluate;
    is $eval->token, $result, "$rule -> $result";
    isa_ok $eval, 'MF::BOOLEAN';
}

done_testing;

