use strict;
use warnings;
use Test::More tests => 3;
use Array::Compare;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;

my $subtlex =
  Lingua::Norms::SUBTLEX->new(
    path => File::Spec->catfile($Bin, qw'samples US.csv'),
    fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
    lang => 'US'
  );

my $cmp_aref = Array::Compare->new;

my $list;

$list = $subtlex->select_words(
    frq_opm         => [ 1, 20 ],
    length       => [ 4, 4 ],
    'cv_pattern' => 'CVCV',
    regex        => '^f.+'
);

ok( $cmp_aref->simple_compare( $list, [qw/fiji fuse/] ),
    'select_words error: expected \'fiji fuse\'; got ' . join( ' ', @$list ) );

# min only:
$list = $subtlex->select_words(
    frq_opm         => [ 1, 20 ],
    length       => [ 5,],
);
ok( scalar(@$list == 2),
    'select_words error: expected 2 items; got ' . scalar @$list );

# max only:
$list = $subtlex->select_words(
    frq_opm         => [ 1, 20 ],
    length       => ['', 4],
);
ok( scalar(@$list == 8),
    'select_words error: expected 8 items; got ' . scalar @$list );

1;
