#!/usr/bin/env perl

use Test::More tests => 3;
use English;

use File::Basename;
chdir dirname($0);
my $dir=dirname($0)."/../../InSilico";
my $env="INSILICOSPECTRO_DEFFILE=../../InSilico/insilicodef-test.xml";

eval{
  require Statistics::Basic;
  require  Math::FixedPrecision;
};
if($@){
 SKIP:{
    skip "no Statistics::Basic or Math::FixedPrecision installed - skipping MSFilter test", 3;
  }
}else{
  is(system("$env $EXECUTABLE_NAME testMSFilterDirectValue.pl") , 0);
  is(system("$env $EXECUTABLE_NAME testMSFilterAlgorithm.pl"), 0);
  is(system("$env $EXECUTABLE_NAME testMSFilterCollection.pl") , 0);
}
