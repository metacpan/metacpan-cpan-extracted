# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 1 + 6*6);

# load modules
use Gfsm;

##-- 1: new()
evalok('$sr=Gfsm::Semiring->new()');

%expect = (
	   ##--i=1
	   SRTBoolean=>
	   {
	    zero=>'==0',
	    one=>'==1',
	    plus=>['0,1','!=0'],
	    times=>['0,1','==0'],
	   },

	   ##--i=2
	   SRTLog=>
	   {
	    zero=>'>=1e38',
	    one=>'==0',
	    plus=>['-log(.5),-log(.25)','+log(.75)<=1e-6'],
	    times=>['-log(.5),-log(.25)','+log(.125)<=1e-6'],
	   },

	   ##--i=3
	   SRTPLog=>
	   {
	    zero=>'<=-1e38',
	    one=>'==0',
	    plus=>['log(.5),log(.25)','-log(.75)<=1e-6'],
	    times=>['log(.5),log(.25)','-log(.125)<=1e-6'],
	   },

	   ##--i=4
	   SRTReal=>
	   {
	    zero=>"==0",
	    one=>"==1",
	    plus=>["3,4","==7"],
	    times=>["3,4","==12"],
	   },

	   ##--i=5
	   SRTTrivial=>
	   {
	    zero=>"==0",
	    one=>"==0",
	    plus=>["3,4","==0"],
	    times=>["3,4","==0"],
	   },

	   ##--i=6
	   SRTTropical=>
	   {
	    zero=>">=1e38",
	    one=>'==0',
	    plus=>['3,4', '==3'],
	    times=>['3,4', '==7'],
	   },

	  );

##-- i=1..max(i) ;
foreach $type (keys(%expect)) {
  print "\nSEMIRING TYPE: $type\n";
  $spec = $expect{$type};
  evalok("\$sr=Gfsm::Semiring->new(Gfsm::${type});"); ##-- j=1: new
  evalok("\$sr->type==Gfsm::${type};");               ##-- j=2: type
  evalok("\$sr->zero() $spec->{zero};");              ##-- j=3: zero
  evalok("\$sr->one() $spec->{one};");                ##-- j=4: one
  evalok("\$sr->plus($spec->{plus}[0]) $spec->{plus}[1];");     ##-- j=5: plus
  evalok("\$sr->times($spec->{times}[0]) $spec->{times}[1];");  ##-- j=6: times
}


print "\n";


