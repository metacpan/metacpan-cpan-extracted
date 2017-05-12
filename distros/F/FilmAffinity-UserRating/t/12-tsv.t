use strict;
use warnings;

use IO::All -utf8;
use FilmAffinity::Utils qw/data2tsv/;

use Test::LongString;
use Test::More tests => 2;

my %films = (
  '309023' => { 'title' => 'Back to the Future', 'rating' => 10},
);

my $oneLine = io('t/resources/tsv/one-line.list')->all;
is( data2tsv( \%films ), $oneLine, 'one line conversion tsv');

%films = (
  '445069' => { 'title' => 'The Pacific (TV)', 'rating' => 21},
  '161026' => { 'title' => 'The Shawshank Redemption', 'rating' => 1},
  '309023' => { 'title' => 'Back to the Future', 'rating' => 10},
  '942334' => { 'title' => 'Dragon Ball Z (TV Series)', 'rating' => 8},
  '576352' => { 'title' => 'Terminator 2: Judgment Day', 'rating' => 5},
);

my $multiLine = io('t/resources/tsv/multi-line.list')->all;
is( data2tsv( \%films ), $multiLine, 'multi line conversion tsv');
