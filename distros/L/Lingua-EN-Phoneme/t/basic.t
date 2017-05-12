use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Lingua::EN::Phoneme;

my $lep = new Lingua::EN::Phoneme();

my @tests;
while (<DATA>) {
      chomp;
      push @tests, $_;
}

plan tests => scalar(@tests) * 2;

for (@tests) {
    my ($latin, @pronunciation) = split m!\.!;
    my $s = $lep->phoneme($latin) || 'NOT IN DICTIONARY';
    my @a = $lep->phoneme($latin);

    is_deeply (\@a, \@pronunciation, "$latin array");
    is ($s, join(' ', @pronunciation), "$latin scalar");
}
__DATA__
the.DH.AH0
quick.K.W.IH1.K
brown.B.R.AW1.N
fox.F.AA1.K.S
jumps.JH.AH1.M.P.S
over.OW1.V.ER0
an.AE1.N
incandescent.IH2.N.K.AH0.N.D.EH1.S.AH0.N.T
octopus.AA1.K.T.AH0.P.UH2.S
belonging.B.IH0.L.AO1.NG.IH0.NG
to.T.UW1
somebody.S.AH1.M.B.AA2.D.IY0
