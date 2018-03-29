use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 4;
use Lingua::Norms::SUBTLEX;
use FindBin qw/$Bin/;
use File::Spec;

my $subtlex =
  Lingua::Norms::SUBTLEX->new();
my $val;

$subtlex->set_lang(lang => 'US', path => File::Spec->catfile($Bin, qw'samples US.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'));

$val = $subtlex->get_lang();
ok($val eq 'US', 'lang value after set_lang is not US but ' . $val);

$val = $subtlex->pos_dom(string => 'the', conform => 1);
ok($val eq 'DA', 'bad pos_dom after set_lang to US; returned val eq ' . $val);

# switch lang:
$subtlex->set_lang(lang => 'FR', path      => File::Spec->catfile( $Bin, qw'samples FR.txt' ),
        fieldpath => File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
        lang => 'FR');

$val = $subtlex->get_lang();
ok($val eq 'FR', 'lang value after set_lang is not FR but ' . $val);

$val = $subtlex->pos_dom(string => 'nappe', conform => 1);
ok($val eq 'NN', 'bad pos_dom after set_lang to FR; returned val eq ' . $val);


1;
