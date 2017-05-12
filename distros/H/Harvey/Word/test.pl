# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

use Test;
BEGIN { plan tests => $TESTCNT };
use Word;

#########################

#
# Test code
#

my $TESTCNT = 42;
my $CNT = 0;

my $L;
my @A;
my @B;
my $V;
my $W;
my $K;
my $M;
my $T;

my $I = Word->new("i");

$CNT++ if ok($I->pronoun(),2409);
$CNT++ if ok($I->pronoun_freq(),884599);
$CNT++ if ok($I->pronoun_persons(),1);
$CNT++ if ok($I->first_pronoun(),1);
$CNT++ if ok($I->second_pronoun(),0);
$CNT++ if ok($I->singular_pronoun(),8);
$CNT++ if ok($I->plural_pronoun(),0);
$CNT++ if ok($I->masculine_pronoun(),32);
$CNT++ if ok($I->feminine_pronoun(),64);
$CNT++ if ok($I->nominative_pronoun(),256);
$CNT++ if ok($I->accusative_pronoun(),0);
$CNT++ if ok($I->person_pronoun(),2048);
$CNT++ if ok(@{$I->prioritize()},1);

my $C = Word->new("can");

$CNT++ if ok($C->noun(),2);
$CNT++ if ok($C->noun_freq(),1107);
$CNT++ if ok($C->noun_persons(),4);
$CNT++ if ok($C->singular_noun(),2);
$CNT++ if ok($C->plural_noun(),0);
$CNT++ if ok(@{$C->prioritize()},3);
$CNT++ if ok($C->verb(),97);
$CNT++ if ok($C->verb_freq(),807);
$CNT++ if ok($C->verb_persons(),59);
$CNT++ if ok($C->infinitive_verb(),1);
$CNT++ if ok($C->present_verb(),32);
$CNT++ if ok($C->starter_verb(),64);
$CNT++ if ok($C->past_verb(),0);
$CNT++ if ok($C->modal(),1);
$CNT++ if ok($C->modal_freq(),234386);
$CNT++ if ok($C->modal(),1);

my $W = Word->new("walk");

$CNT++ if ok($W->noun(),2);
$CNT++ if ok($W->noun_freq(),4138);
$CNT++ if ok($W->noun_persons(),4);
$CNT++ if ok($W->singular_noun(),2);
$CNT++ if ok($W->plural_noun(),0);
$CNT++ if ok(@{$W->prioritize()},2);
$CNT++ if ok($W->verb(),97);
$CNT++ if ok($W->verb_freq(),6294);
$CNT++ if ok($W->verb_persons(),59);
$CNT++ if ok($W->infinitive_verb(),1);
$CNT++ if ok($W->present_verb(),32);
$CNT++ if ok($W->starter_verb(),64);
$CNT++ if ok($W->participle_verb(),0);

if ($CNT != $TESTCNT) {
	my $Errors = $TESTCNT - $CNT;
	
	print "Word: failed $Errors tests, this install is invalid!\n";
}
else {
	print "Word: passed all tests, good install!\n";

}


