use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 41;
use Lingua::Stem::Patch::IO qw( stem_aggressive );

*stem = \&stem_aggressive;

is stem('la'),      'la',    'article';
is stem('hundo'),   'hund',  'noun';
is stem('hundi'),   'hund',  'plural noun';
is stem('hundon'),  'hund',  'accusative noun';
is stem('hundin'),  'hund',  'accusative plural noun';
is stem('longa'),   'long',  'adjective';
is stem('labore'),  'labor', 'adverb';

for my $word (qw{ elu ilu li lu me ni olu onu su tu vi vu }) {
    my $stem = length $word == 2 ? $word : substr $word, 0, 2;
    is stem($word . 'a'), $stem, 'possessive pronouns';
}

for my $suffix (qw{ ir ar or is as os us ez }) {
    is stem('labor'   . $suffix), 'labor', "-$suffix verb";
    is stem('laborab' . $suffix), 'labor', "-ab$suffix verb";
}

for my $suffix (qw{ inta anta onta ita ata ota }) {
    is stem('labor' . $suffix), 'labor', "-$suffix participle";
}
