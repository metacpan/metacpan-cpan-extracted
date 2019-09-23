#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Lingua::EN::Opinion';

my $obj = eval { Lingua::EN::Opinion->new };
isa_ok $obj, 'Lingua::EN::Opinion';

is $obj->file, undef, 'no file';
is $obj->text, undef, 'no text';
is $obj->stem, 0, 'no stem';
is_deeply $obj->sentences, [], 'no sentences';
is_deeply $obj->scores, [], 'no scores';
is_deeply $obj->familiarity, { known => 0, unknown => 0 }, 'no familiarity';
isa_ok $obj->positive, 'Lingua::EN::Opinion::Positive';
isa_ok $obj->negative, 'Lingua::EN::Opinion::Negative';
isa_ok $obj->emotion, 'Lingua::EN::Opinion::Emotion';

throws_ok {
    $obj->ratio
} qr/division by zero/, 'no ratio';

throws_ok {
    $obj = Lingua::EN::Opinion->new( file => 'foo' );
} qr/does not exist/, 'bogus file';

$obj = Lingua::EN::Opinion->new( file => 't/test.txt' );
isa_ok $obj, 'Lingua::EN::Opinion';

my $sentences = [
    'I begin this story with a neutral statement.',
    'Basically this is a very silly test.',
    'You are testing the Lingua::EN::Opinion package using short, inane sentences.',
    'I am actually very happy today.',
    'I have finally finished writing this package.',
    'Tomorrow I will be very sad.',
    "I won't have anything left to do.",
    'I might get angry and decide to do something horrible.',
    'I might destroy the entire package and start from scratch.',
    'Then again, I might find it satisfying to have completed my this package.',
    "You might even say it's beautiful!",
];

$obj->analyze;
is scalar( @{ $obj->sentences } ), scalar( @{ $obj->scores } ), 'sentences == scores';
my $got = $obj->sentences;
is_deeply $got, $sentences, 'sentences';
$got = $obj->scores;
my $expected = [ 0, -1, -1, 1, 0, -1, 0, -2, -2, 1, 1 ];
is_deeply $got, $expected, 'scores';
is_deeply $obj->familiarity, { known => 10, unknown => 80 }, 'familiarity';
is sprintf( '%.3f', $obj->ratio ), 0.111, 'known ratio';
is sprintf( '%.3f', $obj->ratio(1) ), 0.889, 'unknown ratio';

my $text = join "\n", @$sentences;

$obj = Lingua::EN::Opinion->new( text => $text );
isa_ok $obj, 'Lingua::EN::Opinion';
$obj->analyze;
is scalar( @{ $obj->sentences } ), scalar( @{ $obj->scores } ), 'sentences == scores';
$got = $obj->sentences;
is_deeply $got, $sentences, 'sentences';
$got = $obj->scores;
$expected = [ 0, -1, -1, 1, 0, -1, 0, -2, -2, 1, 1 ];
is_deeply $got, $expected, 'scores';
is_deeply $obj->familiarity, { known => 10, unknown => 80 }, 'familiarity';
is sprintf( '%.3f', $obj->ratio ), 0.111, 'known ratio';
is sprintf( '%.3f', $obj->ratio(1) ), 0.889, 'unknown ratio';

$got = $obj->averaged_score(2);
$expected = [ -0.5, 0, -0.5, -1, -0.5, 1 ];
is_deeply $got, $expected, 'averaged_score';

$expected = {
    anger        => 0,
    anticipation => 1,
    disgust      => 0,
    fear         => 0,
    joy          => 0,
    negative     => 0,
    positive     => 1,
    sadness      => 0,
    surprise     => 0,
    trust        => 2
};

$obj->nrc_analyze();
is scalar( @{ $obj->sentences } ), scalar( @{ $obj->scores } ), 'sentences == scores';
is_deeply $obj->nrc_scores->[0], $expected, 'nrc_scores';
is_deeply $obj->familiarity, { known => 27, unknown => 63 }, 'familiarity';
is $obj->ratio, 0.3, 'known ratio';
is $obj->ratio(1), 0.7, 'unknown ratio';

$got = $obj->get_word('foo');
is_deeply $got, undef, 'get_word';

$got = $obj->nrc_get_word('foo');
is_deeply $got, undef, 'nrc_get_word';

$got = $obj->get_word('happy');
is_deeply $got, 1, 'positive get_word';

$got = $obj->get_word('unhappy');
is_deeply $got, -1, 'negative get_word';

$got = $obj->nrc_get_word('happy');
$expected = {
    anger        => 0,
    anticipation => 1,
    disgust      => 0,
    fear         => 0,
    joy          => 1,
    negative     => 0,
    positive     => 1,
    sadness      => 0,
    surprise     => 0,
    trust        => 1,
};
is_deeply $got, $expected, 'positive nrc_get_word';

$got = $obj->nrc_get_word('unhappy');
$expected = {
    anger        => 1,
    anticipation => 0,
    disgust      => 1,
    fear         => 0,
    joy          => 0,
    negative     => 1,
    positive     => 0,
    sadness      => 1,
    surprise     => 0,
    trust        => 0,
};
is_deeply $got, $expected, 'negative nrc_get_word';

$text = 'I am actually very happy happy today';
my ( $known, $unknown ) = ( 0, 0 );
( $got, $known, $unknown ) = $obj->get_sentence($text);
is $got, 2, 'get_sentence';
is $known, 2, 'known';
is $unknown, 5, 'unknown';

( $got, $known, $unknown ) = $obj->nrc_get_sentence($text);
$expected = {
    anger        => 0,
    anticipation => 2,
    disgust      => 0,
    fear         => 0,
    joy          => 2,
    negative     => 0,
    positive     => 2,
    sadness      => 0,
    surprise     => 0,
    trust        => 2,
};
is_deeply $got, $expected, 'nrc_get_sentence';

done_testing();
