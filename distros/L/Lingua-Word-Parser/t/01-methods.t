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
is @{ $score->{$mask} }, 2, 'score N';

# Two distinct combos both fully cover the word: one segments "bio" as a
# single 3-char part (5 parts total), the other splits it into "bi" + "o"
# (6 parts total)
my ($five_part) = grep { $_->{score}{knowns} == 5 } @{ $score->{$mask} };
my ($six_part)  = grep { $_->{score}{knowns} == 6 } @{ $score->{$mask} };
ok $five_part, 'found the 5-part (bio as one part) combo';
ok $six_part,  'found the 6-part (bi + o split) combo';

is_deeply $five_part->{score},
    {
        knownc   => 10,
        unknownc => 40,
        knowns   => 5,
        unknowns => 8
    },
    'score (5-part combo)';
is_deeply $five_part->{familiarity}, [1,1], 'familiarity (5-part combo)';
is_deeply $five_part->{partition},
    [qw/
        [a]bioticaly
        a[bio]ticaly
        abio[tic]aly
        abiotic[a]ly
        abiotica[ly]
    /],
    'partition (5-part combo)';
is_deeply $five_part->{definition},
    [qw/
        opposite
        life
        possessing
        opposite
        like
    /],
    'definition (5-part combo)';

$score = $p->score;
my ($x) = grep { $_->{score} eq '6:10 chunks / 10:50 chars' && $_->{partition} =~ /</ } @{ $score->{$mask} };
ok $x, 'found the 6-part combo in stringified score() output';
is $x->{familiarity}, '1.00 chunks / 1.00 chars', 'familiarity';
is $x->{partition},
    '<a>bioticaly, a<bi>oticaly, abi<o>ticaly, abio<tic>aly, abiotic<a>ly, abiotica<ly>',
    'partition';
is $x->{definition},
    'opposite, two, combining, possessing, opposite, like',
    'definition';

done_testing();
