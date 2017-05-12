# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Lingua::Treebank') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @utts = Lingua::Treebank->from_penn_fh(*DATA);

ok(@utts > 0, "successfully read in!");

cmp_ok(scalar @utts, '==', 14);

foreach (@utts) {
    my @words = $_->get_all_terminals();
}


__END__
*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*
*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*
*x*                                                                     *x*
*x*            Copyright (C) 1995 University of Pennsylvania            *x*
*x*                                                                     *x*
*x*    The data in this file are part of a preliminary version of the   *x*
*x*    Penn Treebank Corpus and should not be redistributed.  Any       *x*
*x*    research using this corpus or based on it should acknowledge     *x*
*x*    that fact, as well as the preliminary nature of the corpus.      *x*
*x*                                                                     *x*
*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*
*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*x*

( (CODE (SYM SpeakerB1) (. .) ))
( (INTJ (UH Hello) (. .) (-DFL- E_S) ))
( (CODE (SYM SpeakerA2) (. .) ))
( (INTJ (UH Hello)
    (, ,)
    (-DFL- E_S) ))
( (CODE (SYM SpeakerB3) (. .) ))
( (INTJ (UH Hi) (. .) (-DFL- E_S) ))
( (CODE (SYM SpeakerA4) (. .) ))
( (INTJ (UH Hello) (-DFL- E_S) ))
( (S 
    (NP-SBJ (DT this) )
    (VP (VBZ is) 
      (NP-PRD (NNS Lois) ))
    (. .) (-DFL- E_S) ))
( (CODE (SYM SpeakerB5) (. .) ))
( (INTJ (UH Hi) 
    (, ,)
    (-DFL- E_S) ))
( (INTJ (UH hi) 
    (, ,)
    (-DFL- E_S) ))
( (S 
    (NP-SBJ (DT this) )
    (VP (VBZ is) 
      (NP-PRD (NNP Lisa) ))
    (. .) (-DFL- E_S) ))
( (CODE (SYM SpeakerA6) (. .) ))

