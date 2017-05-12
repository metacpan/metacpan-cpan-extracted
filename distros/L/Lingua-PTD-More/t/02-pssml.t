#!perl

use Test::More tests => 3;

use Lingua::PTD;
use Lingua::PTD::More qw/pssml/;

my $ptdA = Lingua::PTD->new('t/ptd.en-pt.dmp');
my $ptdB = Lingua::PTD->new('t/ptd.pt-en.dmp');

my %pssml = pssml($ptdA, $ptdB, 'house');
ok( $pssml{house} == 1 and $pssml{house} == 1 );

%pssml = pssml($ptdA, $ptdB, 'cat');
ok( $pssml{cat} == 1 and $pssml{cat} == 1 );

%pssml = pssml($ptdA, $ptdB, 'cat', 0.5);
ok( $pssml{cat} == 1 and $pssml{cat} == 1);
