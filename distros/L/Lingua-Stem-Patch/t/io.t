use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 41;
use Lingua::Stem::Patch::IO qw( stem );

is stem('la'),      'la',      'article';
is stem('hundo'),   'hundo',   'noun';
is stem('hundi'),   'hundo',   'plural noun';
is stem('hundon'),  'hundo',   'accusative noun';
is stem('hundin'),  'hundo',   'accusative plural noun';
is stem('longa'),   'longa',   'adjective';
is stem('labore'),  'labore',  'adverb';

for my $word (map { $_ . 'a' } qw{ elu ilu li lu me ni olu onu su tu vi vu }) {
    is stem($word), $word, 'possessive pronouns';
}

for my $suffix (qw{ ir ar or is as os us ez }) {
    is stem('labor'   . $suffix), 'laborar', "-$suffix verb";
    is stem('laborab' . $suffix), 'laborar', "-ab$suffix verb";
}

for my $suffix (qw{ inta anta onta ita ata ota }) {
    is stem('labor' . $suffix), 'laborar', "-$suffix participle";
}
