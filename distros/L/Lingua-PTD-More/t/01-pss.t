#!perl

use Test::More tests => 3;

use Lingua::PTD;
use Lingua::PTD::More qw/pss/;

my $ptdA = Lingua::PTD->new('t/ptd.en-pt.dmp');
my $ptdB = Lingua::PTD->new('t/ptd.pt-en.dmp');

my %pss = pss($ptdA, $ptdB, 'house');
ok( $pss{house} == 1 and $pss{casa} == 1);

%pss = pss($ptdA, $ptdB, 'cat');
ok( $pss{cat} == 1 and $pss{gato} == 1 and $pss{felino} == 0.4);

%pss = pss($ptdA, $ptdB, 'cat', 0.5);
ok( $pss{cat} == 1 and $pss{gato} == 1);
