use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples US.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'US' );

ok( $subtlex->is_normed( string => 'cat' ) == 1,
    '\'cat\' returned as not a word' );
ok( $subtlex->is_normed( string => 'cet' ) == 0, '\'cet\' returned as a word' );

1;