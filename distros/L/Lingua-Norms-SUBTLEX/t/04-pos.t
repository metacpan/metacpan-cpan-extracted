use strict;
use warnings;
use Test::More tests => 1;
use Statistics::Lite qw(mean median stddev);
use File::Spec;
use FindBin;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'));

ok(
    $subtlex->pos( string => 'aardvark' ) eq 'Noun',
    "'aardvark' POS not returned as Noun"
);

1;
