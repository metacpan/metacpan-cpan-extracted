#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Lingua::Word::Parser';

my $p = eval { Lingua::Word::Parser->new };
isa_ok $p, 'Lingua::Word::Parser';
ok !$@, 'created with no arguments';
ok !ref $p->{lex}, 'no lex';

$p = Lingua::Word::Parser->new(
    file => 'eg/lexicon.dat',
    word => 'abioticaly',
);
is ref $p->{lex}, 'HASH', 'lex';

my ($known) = $p->knowns;
is keys %$known, 10, 'known';
my $power = $p->power;
is @$power, 215, 'power';

my $score = $p->score_parts( '[', ']' );
my $mask = '1111111111';
is @{ $score->{$mask} }, 2, 'score N';
is_deeply $score->{$mask}[0]{score},
    {
        knownc   => 10,
        unknownc => 40,
        knowns   => 5,
        unknowns => 8
    },
    'score';
is_deeply $score->{$mask}[0]{familiarity}, [1,1], 'familiarity';
is_deeply $score->{$mask}[0]{partition},
    [
        '[a]bioticaly',
        'a[bio]ticaly',
        'abio[tic]aly',
        'abiotic[a]ly',
        'abiotica[ly]'
    ],
    'partition';
is_deeply $score->{$mask}[0]{definition},
    [
        'opposite',
        'life',
        'possessing',
        'opposite',
        'like'
    ],
    'definition';

done_testing();
