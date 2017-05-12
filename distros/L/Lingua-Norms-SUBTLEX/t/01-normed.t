use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use File::Spec;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv') );

ok( $subtlex->is_normed( string => 'cat' ) == 1,
    '\'cat\' returned as not a word' );
ok( $subtlex->is_normed( string => 'cet' ) == 0, '\'cet\' returned as a word' );

1;