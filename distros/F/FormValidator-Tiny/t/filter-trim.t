#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( trim );

like dies {
        my $foo = trim('blah');
    }, qr/unknown trim option/,
    'invalid trim option causes error';

{
    my $trim = trim();
    is $trim->(local $_ = "   abc   "), "abc", "trim() trims both";
}

{
    my $trim_both = trim('both');
    is $trim_both->(local $_ = "   abc   "), "abc", "trim(both) trims both";
}

{
    my $trim_left = trim('left');
    is $trim_left->(local $_ = "abc   "), "abc   ", "trim(left) trims left";
}

{
    my $trim_right = trim('right');
    is $trim_right->(local $_ = "   abc"), "   abc", "trim(right) trims right";
}

done_testing;
