# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
package Harveytest;
#########################

use Test;
BEGIN { plan tests => $TESTCNT };
use Harvey::Word;
use Verb;

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

my $ok = 1; # assume we are ok unless an error crops up

sub bin2dec {		# 1.01
	return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub dec2bin {		# 1.01
	return unpack("B32", pack("N",shift));
}

while ($L = <DATA>) {

        # trim off \n
	chomp $L;

        # split into words
	@A = split /\s/,$L;

        # initialize object array for sentence	
	@B = ();
	
        # load object array with Word objects
	foreach $K (@A) {
		push @B,Word->new($K);
	} 

        # make a Verb object with the array of word objects
	$V = Verb->new(\@B,0);

        # create a string of test data from Verb object
        # that should match the strings created at release time
	$M = $V->complete_tense().";".$V->show_adverbs().";"."used: ".dec2bin($V->used()).";"."persons: ".dec2bin($V->persons()).";"."type: ".$V->sentence_type()."\n";
        # get the string from __DATA__ to test against created string against
        $T = <DATA>;
        if ($T ne $M) {
            print "Err on test sentence: $L\n";
            print "$M not equal to\n$T";
            $ok = 0;
        }
}

if ($ok) {
   print "\nVerb.pm tests passed.  Use \'make install\' to finish install\n";
}
else {
   print "\nVerb.pm not all tests passed, this release may not be valid.\n";
}

__DATA__
i see the tree
present of see;;used: 00000000000000000000000000000010;persons: 00000000000000000000000000111011;type: 0
you saw the tree
past of see;;used: 00000000000000000000000000000010;persons: 00000000000000000000000000111011;type: 0
he has seen the tree
present perfect of see;;used: 00000000000000000000000000000110;persons: 00000000000000000000000000000100;type: 0
we had seen the tree
past perfect of see;;used: 00000000000000000000000000000110;persons: 00000000000000000000000000111111;type: 0
they are seeing the tree
present progressive of see;;used: 00000000000000000000000000000110;persons: 00000000000000000000000000111010;type: 0
she was seeing the tree
past progressive of see;;used: 00000000000000000000000000000110;persons: 00000000000000000000000000000101;type: 0
it has been seeing the tree
present perfect progressive of see;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000000100;type: 0
i had been seeing the tree
past perfect progressive of see;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
the tree is seen by me
present passive of see;;used: 00000000000000000000000000001100;persons: 00000000000000000000000000000100;type: 0
the tree was seen by me
past passive of see;;used: 00000000000000000000000000001100;persons: 00000000000000000000000000000101;type: 0
the tree has been seen by me
present perfect passive of see;;used: 00000000000000000000000000011100;persons: 00000000000000000000000000000100;type: 0
the tree had been seen by me
past perfect passive of see;;used: 00000000000000000000000000011100;persons: 00000000000000000000000000111111;type: 0
the tree is being seen by me
present progressive passive of see;;used: 00000000000000000000000000011100;persons: 00000000000000000000000000000100;type: 0
the tree was being seen by me
past progressive passive of see;;used: 00000000000000000000000000011100;persons: 00000000000000000000000000000101;type: 0
the tree has been being seen by me
present perfect progressive passive of see;;used: 00000000000000000000000000111100;persons: 00000000000000000000000000000100;type: 0
the tree had been being seen seen by me
past perfect progressive passive of see;;used: 00000000000000000000000000111100;persons: 00000000000000000000000000111111;type: 0
i can drive
present ability modality for the infinitive of drive;;used: 00000000000000000000000000000110;persons: 00000000000000000000000000111111;type: 0
i must have driven
present requirement modality for the perfect infinitive of drive;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
i may be driving
present allowance modality for the progressive infinitive of drive;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
i could have been driving
present subjunctive_ablility modality for the perfect progressive infinitive of drive;;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
i should be driven
present obligation modality for the passive infinitive of drive;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
i might have been driven
present possiblity modality for the perfect passive infinitive of drive;;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
i would be being driven
present subjunctive modality for the progressive passive infinitive of drive;;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
i will have been being driven
present intention modality for the perfect progressive passive infinitive of drive;;used: 00000000000000000000000000111110;persons: 00000000000000000000000000111111;type: 0
i want to go
present want modality for the infinitive of go;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111011;type: 0
you wanted to be going
past want modality for the progressive infinitive of go;;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
he has wanted to have gone
present perfect want modality for the perfect infinitive of go;;used: 00000000000000000000000000111110;persons: 00000000000000000000000000000100;type: 0
they had wanted to have been going
past perfect want modality for the perfect progressive infinitive of go;;used: 00000000000000000000000001111110;persons: 00000000000000000000000000111111;type: 0
she is wanting to be seen
present progressive want modality for the passive infinitive of see;;used: 00000000000000000000000000111110;persons: 00000000000000000000000000000100;type: 0
he was wanting to have been seen
past progressive want modality for the perfect passive infinitive of see;;used: 00000000000000000000000001111110;persons: 00000000000000000000000000000101;type: 0
they have been wanting to be being seen
present perfect progressive want modality for the progressive passive infinitive of see;;used: 00000000000000000000000011111110;persons: 00000000000000000000000000111011;type: 0
we had been wanting to have been being seen
past perfect progressive want modality for the perfect progressive passive infinitive of see;;used: 00000000000000000000000111111110;persons: 00000000000000000000000000111111;type: 0
i am able to swim
present ability modality for the infinitive of swim;;used: 00000000000000000000000000011110;persons: 00000000000000000000000000000001;type: 0
you help park the car
present help modality for the infinitive of park;;used: 00000000000000000000000000000110;persons: 00000000000000000000000000111011;type: 0
we helped with parking the car
past help modality for the progressive of park;;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
they have helped to park the car
present perfect help modality for the infinitive of park;;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111011;type: 0
i have a desire to play a game
present want modality for the infinitive of play;;used: 00000000000000000000000000111010;persons: 00000000000000000000000000111011;type: 0
i have a need to start to run
present need modality for the start modality for the infinitive of run;;used: 00000000000000000000000011111010;persons: 00000000000000000000000000111011;type: 0
he has always seen the tree
present perfect of see;see adverbs:  always;used: 00000000000000000000000000001110;persons: 00000000000000000000000000000100;type: 0
we had often seen the tree
past perfect of see;see adverbs:  often;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
they are always seeing the tree
present progressive of see;see adverbs:  always;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111010;type: 0
she was often seeing the tree
past progressive of see;see adverbs:  often;used: 00000000000000000000000000001110;persons: 00000000000000000000000000000101;type: 0
it has always been seeing the tree
present perfect progressive of see;see adverbs:  always;used: 00000000000000000000000000011110;persons: 00000000000000000000000000000100;type: 0
i had often been seeing the tree
past perfect progressive of see;see adverbs:  often;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
the tree is often seen by me
present passive of see;see adverbs:  often;used: 00000000000000000000000000011100;persons: 00000000000000000000000000000100;type: 0
the tree was always seen by me
past passive of see;see adverbs:  always;used: 00000000000000000000000000011100;persons: 00000000000000000000000000000101;type: 0
the tree has very often been seen by me
present perfect passive of see;see adverbs:  very often;used: 00000000000000000000000001111100;persons: 00000000000000000000000000000100;type: 0
the tree had always been seen by me
past perfect passive of see;see adverbs:  always;used: 00000000000000000000000000111100;persons: 00000000000000000000000000111111;type: 0
the tree is often being seen by me
present progressive passive of see;see adverbs:  often;used: 00000000000000000000000000111100;persons: 00000000000000000000000000000100;type: 0
the tree was always being seen by me
past progressive passive of see;see adverbs:  always;used: 00000000000000000000000000111100;persons: 00000000000000000000000000000101;type: 0
the tree has often been being seen by me
present perfect progressive passive of see;see adverbs:  often;used: 00000000000000000000000001111100;persons: 00000000000000000000000000000100;type: 0
the tree had always been being seen seen by me
past perfect progressive passive of see;see adverbs:  always;used: 00000000000000000000000001111100;persons: 00000000000000000000000000111111;type: 0
i can always drive
present ability modality for the infinitive of drive;drive adverbs:  always;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111111;type: 0
i must have driven often
present requirement modality for the perfect infinitive of drive;drive adverbs:  often;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
i may be driving soon
present allowance modality for the progressive infinitive of drive;drive adverbs:  soon;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
i could always have been driving fast
present subjunctive_ablility modality for the perfect progressive infinitive of drive;drive adverbs:  always fast;used: 00000000000000000000000001111110;persons: 00000000000000000000000000111111;type: 0
i should always be driven
present obligation modality for the passive infinitive of drive;drive adverbs:  always;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
i might frequently have been driven
present possiblity modality for the perfect passive infinitive of drive;drive adverbs:  frequently;used: 00000000000000000000000000111110;persons: 00000000000000000000000000111111;type: 0
i would happily be being driven
present subjunctive modality for the progressive passive infinitive of drive;drive adverbs:  happily;used: 00000000000000000000000000111110;persons: 00000000000000000000000000111111;type: 0
i will soon have been being driven
present intention modality for the perfect progressive passive infinitive of drive;drive adverbs:  soon;used: 00000000000000000000000001111110;persons: 00000000000000000000000000111111;type: 0
i want to go badly
present want modality for the infinitive of go;go adverbs:  badly;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111011;type: 0
you wanted very badly to be going
past want modality for the progressive infinitive of go;want adverbs:  very badly;used: 00000000000000000000000001111110;persons: 00000000000000000000000000111111;type: 0
he has always wanted to have gone
present perfect want modality for the perfect infinitive of go;want adverbs:  always;used: 00000000000000000000000001111110;persons: 00000000000000000000000000000100;type: 0
they had sorely wanted to have been going
past perfect want modality for the perfect progressive infinitive of go;want adverbs:  sorely;used: 00000000000000000000000011111110;persons: 00000000000000000000000000111111;type: 0
she is really wanting to be seen
present progressive want modality for the passive infinitive of see;want adverbs:  really;used: 00000000000000000000000001111110;persons: 00000000000000000000000000000100;type: 0
he was really wanting to have been seen
past progressive want modality for the perfect passive infinitive of see;want adverbs:  really;used: 00000000000000000000000011111110;persons: 00000000000000000000000000000101;type: 0
they have always been wanting to be being seen
present perfect progressive want modality for the progressive passive infinitive of see;want adverbs:  always;used: 00000000000000000000000111111110;persons: 00000000000000000000000000111011;type: 0
we had always been wanting to have been being seen often
past perfect progressive want modality for the perfect progressive passive infinitive of see;want adverbs:  always see adverbs:  often;used: 00000000000000000000011111111110;persons: 00000000000000000000000000111111;type: 0
i am never able to swim
present ability modality for the infinitive of swim;ability adverbs:  never;used: 00000000000000000000000000111110;persons: 00000000000000000000000000000001;type: 0
you help quickly park the car
present help modality for the infinitive of park;help adverbs:  quickly;used: 00000000000000000000000000001110;persons: 00000000000000000000000000111011;type: 0
we helped often with parking the car
past help modality for the progressive of park;help adverbs:  often;used: 00000000000000000000000000011110;persons: 00000000000000000000000000111111;type: 0
they have always helped to park the car
present perfect help modality for the infinitive of park;help adverbs:  always;used: 00000000000000000000000000111110;persons: 00000000000000000000000000111011;type: 0
i had always wanted to be able to have been being captured by cannibals 
past perfect want modality for the ability modality for the perfect progressive passive infinitive of capture;want adverbs:  always;used: 00000000000000000000111111111110;persons: 00000000000000000000000000111111;type: 0
do i see the cloud
present know modality for the infinitive of cloud;;used: 00000000000000000000000000011101;persons: 00000000000000000000000000111011;type: 1
does she see the kite
present of see;;used: 00000000000000000000000000000101;persons: 00000000000000000000000000000100;type: 1
did they feel the rain
past of feel;;used: 00000000000000000000000000000101;persons: 00000000000000000000000000111111;type: 1
am i going to run 
present progressive execution modality for the infinitive of run;;used: 00000000000000000000000000011101;persons: 00000000000000000000000000000001;type: 1
was she working hard
past progressive of work;;used: 00000000000000000000000000000101;persons: 00000000000000000000000000000101;type: 1
have you been trying to sell the tree
present perfect progressive strive modality for the infinitive of sell;;used: 00000000000000000000000000111101;persons: 00000000000000000000000000111011;type: 1
would you have been talking to her
present subjunctive modality for the perfect progressive infinitive of talk;;used: 00000000000000000000000000011101;persons: 00000000000000000000000000111111;type: 1
when would you have been talking
present subjunctive modality for the perfect progressive infinitive of talk;;used: 00000000000000000000000000111010;persons: 00000000000000000000000000111111;type: 1
