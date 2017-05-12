#!/usr/bin/env perl
use Test::More tests => 44;
use File::Basename;
my $dir=dirname($0)."/InSilico";
my $env="INSILICOSPECTRO_DEFFILE=$dir/insilicodef-test.xml";

is(system("$env perl $dir/testSequence.pl 1 > /dev/null"), 0);

is(system("$env perl $dir/testAASequence.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testAASequence.pl 3 > /dev/null"), 0);

is(system("$env perl $dir/testPeptide.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testPeptide.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testPeptide.pl 3 > /dev/null"), 0);

is(system("$env perl $dir/testCleavEnzyme.pl > /dev/null"), 0);

is(system("$env perl $dir/testModRes.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testModRes.pl 2 > /dev/null"), 0);

is(system("$env perl $dir/testCalcDigest.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigest.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigest.pl 3 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigest.pl 4 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigest.pl 5 > /dev/null"), 0);

is(system("$env perl $dir/testCalcDigestOOP.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigestOOP.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigestOOP.pl 3 > /dev/null"), 0);
is(system("$env perl $dir/testCalcDigestOOP.pl 4 > /dev/null"), 0);

is(system("$env perl $dir/testCalcFrag.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcFrag.pl 2 > /dev/null"), 0);

is(system("$env perl $dir/testCalcFragOOP.pl > /dev/null"), 0);

is(system("$env perl $dir/testCalcMatch.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcMatch.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testCalcMatch.pl 3 > /dev/null"), 0);

is(system("$env perl $dir/testCalcMatchOOP.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcMatchOOP.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testCalcMatchOOP.pl 3 > /dev/null"), 0);

is(system("$env perl $dir/testCalcPMFMatch.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcPMFMatch.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testCalcPMFMatch.pl 3 > /dev/null"), 0);

is(system("$env perl $dir/testCalcPMFMatchOOP.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcPMFMatchOOP.pl 2 > /dev/null"), 0);

is(system("$env perl $dir/testCalcVarpept.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testCalcVarpept.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testCalcVarpept.pl 3 > /dev/null"), 0);
is(system("$env perl $dir/testCalcVarpept.pl 4 > /dev/null"), 0);

is(system("$env perl $dir/testMSMSOutText.pl 1 > /dev/null"), 0);
is(system("$env perl $dir/testMSMSOutText.pl 2 > /dev/null"), 0);
is(system("$env perl $dir/testMSMSOutHtml.pl > /dev/null"), 0);
is(system("$env perl $dir/testMSMSOutLatex.pl > /dev/null"), 0);
is(system("$env perl $dir/testMSMSOutPlot.pl > /dev/null"), 0);
is(system("$env perl $dir/testMSMSOutLegend.pl > /dev/null"), 0);

eval{
  require Bio::Perl;
  is(system("$env perl $dir/testSequence.pl 2 > /dev/null"), 0);
  is(system("$env perl $dir/testAASequence.pl 2 > /dev/null"), 0);
};
if($@){
 SKIP:{
    skip "no Bio::Perl installed", 2;
  }
}
