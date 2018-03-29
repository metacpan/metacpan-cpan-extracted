use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;
use Lingua::Norms::SUBTLEX;
use FindBin qw/$Bin/;
use File::Spec;

my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples US.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'US');

my @random = $subtlex->random_word();
ok(
    scalar @random > 1, 'method \'random_word\' did not return an array'
);

my $str = $subtlex->random_word();
ok(
    length ($str), 'method \'random_word\' did not return a word of any length'
);

1;
