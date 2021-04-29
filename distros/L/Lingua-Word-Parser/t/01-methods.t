#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Lingua::Word::Parser';

my $p = new_ok 'Lingua::Word::Parser';

ok !$p->{lex}, 'no lex';

$p = new_ok 'Lingua::Word::Parser' => [
    file => 'eg/lexicon.dat',
    word => 'abioticaly',
];

isa_ok $p->{lex}, 'HASH';
ok keys %{ $p->{lex} }, 'lex';

my ($known) = $p->knowns;
is keys %$known, 10, 'known';
my $power = $p->power;
is @$power, 215, 'power';

my $score = $p->score_parts( '[', ']' );
my $mask = '1111111111';
my $x = $score->{$mask}[0];
is @{ $score->{$mask} }, 2, 'score N';
is_deeply $x->{score},
    {
        knownc   => 10,
        unknownc => 40,
        knowns   => 5,
        unknowns => 8
    },
    'score';
is_deeply $x->{familiarity}, [1,1], 'familiarity';
is_deeply $x->{partition},
    [qw/
        [a]bioticaly
        a[bio]ticaly
        abio[tic]aly
        abiotic[a]ly
        abiotica[ly]
    /],
    'partition';
is_deeply $x->{definition},
    [qw/
        opposite
        life
        possessing
        opposite
        like
    /],
    'definition';

$score = $p->score;
$x = $score->{$mask}[-1];
is $x->{score}, '6:10 chunks / 10:50 chars', 'score';
is $x->{familiarity}, '1.00 chunks / 1.00 chars', 'familiarity';
is $x->{partition},
    '<a>bioticaly, a<bi>oticaly, abi<o>ticaly, abio<tic>aly, abiotic<a>ly, abiotica<ly>',
    'partition';
is $x->{definition},
    'opposite, two, combining, possessing, opposite, like',
    'definition';

done_testing();
