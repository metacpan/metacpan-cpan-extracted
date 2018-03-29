use strict;
use warnings;
use Test::More tests => 7;
use FindBin qw/$Bin/;
use File::Spec;
use Array::Compare;
use Lingua::Norms::SUBTLEX;

my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples US.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'US');

my $pos_str = $subtlex->pos_dom( string => 'aardvark' );

ok(
    $pos_str eq 'Noun',
    "'aardvark' POS not returned as Noun"
);

# translite: 
my $stub = Lingua::Norms::SUBTLEX::_pos_is($pos_str, $subtlex->{'_FIELDS'}, $subtlex->{'_LANG'});

ok($stub->[0] eq 'NN', "pos returned false");

$pos_str = $subtlex->pos_dom( string => 'aardvark', conform => 1 );

ok($pos_str eq 'NN', "pos returned false");

# pos_all
#
$subtlex = Lingua::Norms::SUBTLEX->new(
        path      => File::Spec->catfile( $Bin, qw'samples SUBTLEX-PT_Soares_et_al._QJEP.csv' ),
        fieldpath => File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
        lang => 'PT',
        match_level => 0,
    );
 my $aref =  $subtlex->pos_all(string => 'selvagem');
 ok(ref $aref, 'Not an aref from pos_all');
 
ok($aref->[0] eq 'ADJ', 'wrong pos from pos_all: ' . $aref->[0]);

$aref =  $subtlex->pos_all(string => 'selvagem', conform => 1);
ok($aref->[0] eq 'AJ', 'wrong pos from pos_all with conform:' . $aref->[0]);


# programme
$subtlex = Lingua::Norms::SUBTLEX->new(
        path      => File::Spec->catfile( $Bin, qw'samples UK.csv' ),
        fieldpath => File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
        lang => 'UK',
        match_level => 0,
    );
$aref =  $subtlex->pos_all(string => 'programme', conform => 1);

my $cmp_aref = Array::Compare->new;
ok( $cmp_aref->simple_compare( $aref, [qw/NN NM VB AJ AV UK/] ),
    'pos_all error: expected \'NN NM VB AJ AV UK\'; got ' . join( ' ', @{$aref} ) );


1;
