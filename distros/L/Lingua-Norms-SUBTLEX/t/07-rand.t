use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;
use Lingua::Norms::SUBTLEX;
use File::Spec;
use FindBin;

my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'));

    
my @random = $subtlex->random_word();
ok(
    scalar @random > 1, 'method \'random_word\' did not return an array, it seems'
);

my $str = $subtlex->random_word();
ok(
    length ($str), 'method \'random_word\' did not return a word of any length, it seems'
);

1;
