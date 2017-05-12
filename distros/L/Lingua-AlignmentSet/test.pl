# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { 
    use_ok('Lingua::AlignmentSet');
    $ENV{ALDIR}="data";
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$alSet = Lingua::AlignmentSet->new([[$ENV{ALDIR}."/spanish-english.naacl","NAACL","1-10"]]);
$alSet->setWordFiles($ENV{ALDIR}."/spanish.naacl",$ENV{ALDIR}."/english.naacl");

$gsLoc = {"sourceToTarget"=>$ENV{ALDIR}."/answer/spanish-english"};
$goldStandard = Lingua::AlignmentSet->new([[$gsLoc,"BLINKER"]]);


$evalResult = $alSet->evaluate($goldStandard,"no-null-align");
if ($evalResult->{AER} <0.28 && $evalResult->{AER}>0.27){
    print "Test passed.";
}else{
    print "Test failed.";
}
print "\n";

