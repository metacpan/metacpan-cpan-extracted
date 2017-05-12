#!/usr/bin/perl -w
use strict;

use Data::FormValidator;
use Test::More tests => 30;
use Labyrinth::Variables;

Labyrinth::Variables::init();   # initial standard variable values

my @tests = (
    [ 'http://example.com',                 1, 1 ],
    [ 'http://example.com/',                1, 1 ],
    [ 'http://example.com/path',            1, 1 ],
    [ 'http://example.com/path?query',      1, 1 ],
    [ 'http://example.com/path?query#here', 1, 1 ],
    [ 'file:///path',                       1, 1 ],
    [ 'file://path',                        1, 0 ], # this shouldn't match urlregex, but it does :(

    [ '/path',                              1, 0 ],
    [ '/path/here',                         1, 0 ],
    [ '/path?query',                        1, 0 ],
    [ '/path?query#here',                   1, 0 ],

    [ 'example.com',                        1, 0 ],
    [ 'example.com/',                       1, 0 ],
    [ 'path',                               0, 0 ],
    [ 'path?query',                         0, 0 ],
);

for my $test (@tests) {
    if($test->[1]) {
        like($test->[0],$settings{urlregex},".. urlregex matches '$test->[0]'");
    } else {
        unlike($test->[0],$settings{urlregex},".. urlregex doesn't match '$test->[0]'");
    }

    if($test->[2]) {
        like($test->[0],$settings{urlstrict},".. urlstrict matches '$test->[0]'");
    } else {
        unlike($test->[0],$settings{urlstrict},".. urlstrict doesn't match '$test->[0]'");
    }
}
