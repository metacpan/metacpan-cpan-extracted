# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for the ternary calculator application

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/25_calculator.t'

#########################

use 5.008;
use strict;
use warnings;
use Test::More tests => 1;
use File::Spec;
use Math::Logic::Ternary::Calculator;

#########################

subtest('tcalc runs', sub {
    plan(tests => 6);
    my $r;
    my $devnull = File::Spec->devnull;
    open STDIN,    '<', $devnull or die "$devnull: cannot open r: $!";
    open my $null, '>', $devnull or die "$devnull: cannot open w: $!";
    select $null;
    $r = eval { tcalc; 1 };
    select STDOUT;
    diag("caught exception: $@") if !$r;
    is($r, 1, 'without arguments');
    select $null;
    $r = eval { tcalc(9); 1 };
    select STDOUT;
    diag("caught exception: $@") if !$r;
    is($r, 1, 'with word_size 9');
    select $null;
    $r = eval { tcalc('foobar'); 1 };
    select STDOUT;
    is($r, undef, 'with bad argument');
    is($@, qq{usage: tcalc [word_size [mode]]\n}, 'usage message');
    select $null;
    $r = eval { tcalc(9, 0, 1); 1 };
    select STDOUT;
    is($r, undef, 'with too many arguments');
    is($@, qq{usage: tcalc [word_size [mode]]\n}, 'usage message');
    close $null or die "$devnull: cannot close: $!";
});                                     # 1

# TODO: capture and check output of a couple of normal tcalc runs

__END__
