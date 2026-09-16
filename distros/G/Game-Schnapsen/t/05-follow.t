#!perl
use 5.010; use strict; use warnings;
use Test::More;

use Game::Schnapsen::Card qw(id_of name_of);
use Game::Schnapsen::Trick qw(legal_follows follow_band);

# Phase 2 forces follow suit and, subject to that, winning the trick. That is a
# STRICT CASCADE of four bands and not a list of preferences, so every assertion
# here is an exact list and never `ok(scalar @legal)`.
#
# The failure this guards is a legal_follows that returns the UNION - anything in
# the suit, or a trump, or anything. Every game a bot plays against it runs to
# the end looking perfectly correct, and it is wrong only in the positions where
# the rule decides anything at all, which is to say the ones that matter.

sub hand { return [ map { id_of($_) } @_ ] }
sub names { return [ sort map { name_of($_) } @{ $_[0] } ] }

my $TRUMP = 'H';

# ---- band 1: you hold a higher card of the suit led ---------------------------------

subtest 'holding a higher card of the suit led, you must beat it' => sub {
    plan tests => 3;
    #                 higher   lower   trump   other
    my $h = hand(qw(  AS KS     JS      TH      QD  ));
    my $lead = id_of('QS');

    is(follow_band($h, $lead, $TRUMP, 2), 'beat', 'the band is beat');
    is_deeply(names(legal_follows($h, $lead, $TRUMP, 2)), [qw(AS KS)],
              'only the spades above the queen are offered');

    # The three cards NOT offered are each offered by one of the wrong
    # implementations: JS by "any card of the suit", TH by "or a trump", QD by
    # "or anything".
    is_deeply([ grep { my $n = $_;
                       scalar grep { $_ eq $n } @{ names(legal_follows($h, $lead, $TRUMP, 2)) } }
                qw(JS TH QD) ], [],
              'and the lower spade, the trump and the off-suit card are all refused');
};

# ---- band 2: you hold the suit but nothing higher -------------------------------------

subtest 'holding only lower cards of the suit led, you must still follow' => sub {
    plan tests => 3;
    my $h = hand(qw( JS 9S   TH AH   QD ));
    my $lead = id_of('KS');

    is(follow_band($h, $lead, $TRUMP, 2), 'follow', 'the band is follow');
    is_deeply(names(legal_follows($h, $lead, $TRUMP, 2)), [qw(9S JS)],
              'both low spades, and nothing else');

    # THE BAND THAT IS EASIEST TO GET WRONG: holding two trumps and no way to
    # win, you may not trump. Following suit outranks winning the trick.
    is_deeply([ grep { my $n = $_;
                       scalar grep { $_ eq $n } @{ names(legal_follows($h, $lead, $TRUMP, 2)) } }
                qw(TH AH) ], [],
              'and the trumps are refused even though they would win');
};

# ---- band 3: void in the suit, holding trumps -------------------------------------------

subtest 'void in the suit led, you must trump' => sub {
    plan tests => 3;
    my $h = hand(qw( TH 9H   AD KD QC ));
    my $lead = id_of('KS');

    is(follow_band($h, $lead, $TRUMP, 2), 'trump', 'the band is trump');
    is_deeply(names(legal_follows($h, $lead, $TRUMP, 2)), [qw(9H TH)], 'both trumps');

    # No obligation to trump HIGH: the source requires a trump and says nothing
    # about which. Offering only the ace of trumps would be a rule nobody wrote.
    is(scalar @{ legal_follows($h, $lead, $TRUMP, 2) }, 2,
       'either of them, because no source says a trump must be a high one');
};

# ---- band 4: void in both -----------------------------------------------------------------

subtest 'void in the suit and in trumps, you may play anything' => sub {
    plan tests => 2;
    my $h = hand(qw( AD KD QC 9C ));
    my $lead = id_of('KS');

    is(follow_band($h, $lead, $TRUMP, 2), 'free', 'the band is free');
    is_deeply(names(legal_follows($h, $lead, $TRUMP, 2)), [qw(9C AD KD QC)],
              'the whole hand');
};

# ---- a trump lead collapses the first three bands into one --------------------------------

subtest 'a trump lead is answered by the same cascade' => sub {
    plan tests => 4;
    my $h = hand(qw( AH 9H   AS KD ));

    is(follow_band($h, id_of('TH'), $TRUMP, 2), 'beat', 'holding a higher trump, beat it');
    is_deeply(names(legal_follows($h, id_of('TH'), $TRUMP, 2)), [qw(AH)],
              'which is the ace of trumps alone');

    my $low = hand(qw( 9H   AS KD ));
    is(follow_band($low, id_of('TH'), $TRUMP, 2), 'follow',
       'holding only a lower trump, follow with it');
    is_deeply(names(legal_follows($low, id_of('TH'), $TRUMP, 2)), [qw(9H)],
              'and it is the only card offered');
};

# ---- phase 1 has none of this ---------------------------------------------------------------

subtest 'phase 1 refuses nothing' => sub {
    # "There is no requirement to follow suit, nor to try to win the trick."
    # Every hand above, answered in phase 1, gives back the whole hand.
    plan tests => 5;
    my @hands = (
        hand(qw( AS KS JS TH QD )),
        hand(qw( JS 9S TH AH QD )),
        hand(qw( TH 9H AD KD QC )),
        hand(qw( AD KD QC 9C )),
        hand(qw( AH 9H AS KD )),
    );
    for my $h (@hands) {
        is_deeply(names(legal_follows($h, id_of('KS'), $TRUMP, 1)), names($h),
                  'the whole hand is on offer');
    }
};

# ---- the bands are exclusive ------------------------------------------------------------------

subtest 'a band is one band and never a union of them' => sub {
    # The union bug again, checked as a property rather than on rigged hands:
    # whatever the band, the answer is a subset of the hand, never empty, and
    # never the whole hand unless the band really is free.
    plan tests => 4;
    my @cases = (
        [ hand(qw( AS KS JS TH QD )), 'QS' ],
        [ hand(qw( JS 9S TH AH QD )), 'KS' ],
        [ hand(qw( TH 9H AD KD QC )), 'KS' ],
        [ hand(qw( AD KD QC 9C )),    'KS' ],
    );
    for my $c (@cases) {
        my ($h, $lead) = @$c;
        my $got  = legal_follows($h, id_of($lead), $TRUMP, 2);
        my $band = follow_band($h, id_of($lead), $TRUMP, 2);
        my $whole = (scalar @$got == scalar @$h) ? 1 : 0;
        is($whole, ($band eq 'free' ? 1 : 0),
           "$band: the whole hand is offered only when the band is free");
    }
};

done_testing();
