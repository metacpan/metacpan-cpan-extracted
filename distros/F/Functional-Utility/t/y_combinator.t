#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use lib grep { -d } qw(../lib ./lib);
use Functional::Utility qw(y_combinator);

my $f1;
$f1 = sub {
	my $n = shift;
	return $n if $n == 1;
	return $n * $f1->($n - 1);
};

is( $f1->(6), 720, 'anonymous subs recurse correctly' );

my $factorial = y_combinator {
    my ($recurse) = @_;

    return sub {
        my $n = shift;
        return $n if $n == 1;
        return $n * $recurse->($n - 1);
    };
};

is( $factorial->(6), 720, 'we can recurse correctly, yo' );
