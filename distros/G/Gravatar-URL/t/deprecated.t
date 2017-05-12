#!/usr/bin/perl -w

# Test that deprecated keys warn.

use strict;
use Test::More 'no_plan';
use Test::Warn;

use Gravatar::URL;

my $id = 'a60fc0828e808b9a6a9d50f1792240c8';
my $email = 'whatever@wherever.whichever';
my $base = 'http://www.gravatar.com/avatar';

warning_is {
    is gravatar_url(
        id   => '12345',
        base => 'http://www.example.com/gravatar',
        border => "FFF"
    ), "http://www.example.com/gravatar/12345?b=FFF";
} {carped => "The border key is deprecated"};
