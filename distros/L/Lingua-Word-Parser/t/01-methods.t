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
my $score = $p->score( '[', ']' );
is @{ $score->{1111111111} }, 2, 'score';
is $score->{1111111111}[0]{definition},
    'opposite, life, possessing, opposite, like',
    'definition';
is $score->{1111111111}[0]{partition},
    '[a]bioticaly, a[bio]ticaly, abio[tic]aly, abiotic[a]ly, abiotica[ly]',
    'partition';

is Lingua::Word::Parser::_rle('01'), 'u1k1', '_rle';
is Lingua::Word::Parser::_rle('0011'), 'u2k2', '_rle';

done_testing();
