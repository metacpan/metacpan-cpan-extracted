#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
my $nested = {
    numbers => [1, 2, 2.5, 99.99],
    cats => [qw/mocha dusty milky/],
    dogs => [qw/Tico Rocky Pinky/],
    fruit => {
	thai => 'pineapple',
	japan => 'persimmon',
	australia => 'orange',
    },
};
print create_json ($nested);
