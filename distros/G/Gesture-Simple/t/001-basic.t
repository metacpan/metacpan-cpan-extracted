#!/usr/bin/env perl
use strict;
use warnings;
use Gesture::Simple;
use Test::More tests => 21;

my $recognizer = Gesture::Simple->new;

my $L_template = Gesture::Simple::Template->new(
    name   => 'L',
    points => [
        [ 73,  58 ],
        [ 73,  59 ],
        [ 73,  61 ],
        [ 73,  63 ],
        [ 73,  68 ],
        [ 73,  74 ],
        [ 74,  82 ],
        [ 74,  88 ],
        [ 75,  94 ],
        [ 75, 102 ],
        [ 76, 109 ],
        [ 76, 118 ],
        [ 76, 124 ],
        [ 77, 129 ],
        [ 77, 131 ],
        [ 77, 135 ],
        [ 77, 136 ],
        [ 77, 138 ],
        [ 77, 140 ],
        [ 78, 141 ],
        [ 80, 141 ],
        [ 84, 141 ],
        [ 91, 142 ],
        [101, 142 ],
        [112, 142 ],
        [123, 142 ],
        [135, 141 ],
        [148, 140 ],
        [161, 140 ],
        [169, 139 ],
        [175, 138 ],
        [176, 138 ],
        [177, 138 ],
    ],
);

my $O_template = Gesture::Simple::Template->new(
    name => 'O',
    points => [
        [ 152, 106 ],
        [ 150, 106 ],
        [ 149, 106 ],
        [ 145, 106 ],
        [ 142, 106 ],
        [ 138, 106 ],
        [ 133, 106 ],
        [ 127, 107 ],
        [ 122, 110 ],
        [ 118, 113 ],
        [ 114, 116 ],
        [ 112, 118 ],
        [ 111, 121 ],
        [ 111, 125 ],
        [ 111, 132 ],
        [ 114, 138 ],
        [ 118, 142 ],
        [ 124, 148 ],
        [ 131, 152 ],
        [ 140, 155 ],
        [ 146, 156 ],
        [ 155, 157 ],
        [ 162, 157 ],
        [ 169, 157 ],
        [ 177, 155 ],
        [ 182, 152 ],
        [ 186, 149 ],
        [ 190, 146 ],
        [ 193, 143 ],
        [ 194, 141 ],
        [ 195, 137 ],
        [ 196, 133 ],
        [ 196, 128 ],
        [ 196, 125 ],
        [ 196, 121 ],
        [ 194, 120 ],
        [ 192, 117 ],
        [ 187, 115 ],
        [ 183, 113 ],
        [ 179, 112 ],
        [ 175, 110 ],
        [ 172, 109 ],
        [ 168, 108 ],
        [ 163, 107 ],
        [ 159, 106 ],
        [ 155, 105 ],
        [ 152, 104 ],
        [ 149, 103 ],
        [ 147, 103 ],
        [ 146, 103 ],
        [ 145, 103 ],
        [ 143, 103 ],
    ],
);


$recognizer->add_template($L_template);

my $gesture = Gesture::Simple::Gesture->new(
    points => [
        [  94,  64 ],
        [  94,  66 ],
        [  94,  71 ],
        [  95,  76 ],
        [  96,  86 ],
        [  97,  99 ],
        [  97, 109 ],
        [  98, 120 ],
        [ 100, 130 ],
        [ 103, 138 ],
        [ 105, 143 ],
        [ 109, 147 ],
        [ 113, 151 ],
        [ 134, 156 ],
        [ 155, 156 ],
        [ 186, 155 ],
        [ 206, 153 ],
        [ 219, 153 ],
        [ 223, 152 ],
        [ 230, 151 ],
        [ 234, 150 ],
        [ 236, 150 ],
    ],
);

my $match = $recognizer->match($gesture);

ok($match, 'got a match');
isa_ok($match, 'Gesture::Simple::Match', 'match class');
is($match->template, $L_template, 'correct template');
is($match->name, 'L', 'correct match name');
is($match->gesture, $gesture, 'correct gesture');

cmp_ok($match->score, '>', 90, 'the gesture matched very well');

$recognizer->add_template($O_template);

my @matches = $recognizer->match($gesture);

is(@matches, 2, 'got two matches');

is($matches[0]->name, 'L', 'correct best match');
cmp_ok($matches[0]->score, '>', 90, 'the gesture matched very well');

is($matches[1]->name, 'O', 'correct worst match');
cmp_ok($matches[1]->score, '<', 75, 'the gesture did not match well');


@matches = $recognizer->match($L_template);

is(@matches, 2, 'got two matches');

is($matches[0]->name, 'L', 'correct best match');
cmp_ok($matches[0]->score, '>', 90, 'the gesture matched very well');

is($matches[1]->name, 'O', 'correct worst match');
cmp_ok($matches[1]->score, '<', 75, 'the gesture did not match well');


@matches = $recognizer->match($O_template);

is(@matches, 2, 'got two matches');

is($matches[0]->name, 'O', 'correct best match');
cmp_ok($matches[0]->score, '>', 90, 'the gesture matched very well');

is($matches[1]->name, 'L', 'correct worst match');
cmp_ok($matches[1]->score, '<', 75, 'the gesture did not match well');

