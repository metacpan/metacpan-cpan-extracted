#!/usr/bin/perl
package CaseScoping;
use strict;
use warnings;

use Fennec;

my $var;
my $before_var;
my $before_all;

case alpha => sub { $var = 'a' };
case bravo => sub { $var = 'b' };

before_all clear_the_room => sub {
    # If scoping works properly, this should have no case applied
    $before_all = $var;
};

before_each set_the_before => sub {
    # If scoping works properly, we should hit this twice, once
    # for alpha and once for bravo, with $var set appropriately.
    $before_var = $var;
};

tests check_before_each => sub {
    is( $before_var, $var );
};

tests check_before_all => sub {
    is( $before_all, undef );
};

done_testing;
