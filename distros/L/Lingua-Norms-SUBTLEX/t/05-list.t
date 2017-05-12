use strict;
use warnings;
use Test::More tests => 3;
use Array::Compare;
use File::Spec;
use FindBin;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'), lang => 'US');

my $cmp_aref = Array::Compare->new;

my $list;

$list = $subtlex->list_words(
    freq         => [ 1, 20 ],
    length       => [ 4, 4 ],
    onc          => [ 0, 4 ],
    'cv_pattern' => 'CVCV',
    regex        => '^f.+'
);

ok( $cmp_aref->simple_compare( $list, [qw/fiji fuse/] ),
    'list_words error: expected \'fiji fuse\'; got ' . join( ' ', @$list ) );

# min only:
$list = $subtlex->list_words(
    freq         => [ 1, 20 ],
    length       => [ 5,],
    onc          => [ 0, 4 ],   
);
ok( scalar(@$list == 2),
    'list_words error: expected 2 items; got ' . scalar @$list );

# max only:
$list = $subtlex->list_words(
    freq         => [ 1, 20 ],
    length       => ['', 4],
    onc          => [ 0, 4 ],   
);
ok( scalar(@$list == 6),
    'list_words error: expected 3 items; got ' . scalar @$list );

1;
