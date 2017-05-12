use strict;
use warnings;
use Test::More tests => 102;
use Games::Mastermind::Cracker;

sub score_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $guess = shift;
    my $code  = shift;
    my $black = shift;
    my $white = shift;

    my ($b, $w) = Games::Mastermind::Cracker->score($guess, $code);

    is($b, $black, "Black (correct)   is $black for '$guess' vs '$code'");
    is($w, $white, "White (misplaced) is $white for '$guess' vs '$code'");
}

score_is '', '', 0, 0;

score_is 'A', 'A', 1, 0;
score_is 'A', 'B', 0, 0;
score_is 'B', 'A', 0, 0;
score_is 'a', 'A', 0, 0;
score_is 'A', 'a', 0, 0;
score_is 'A', ' ', 0, 0;
score_is ' ', 'A', 0, 0;

score_is  'A', 'AA', 1, 0;
score_is  'B', 'AA', 0, 0;
score_is 'AA',  'A', 1, 0;
score_is 'AA',  'B', 0, 0;

score_is 'A ', 'AA', 1, 0;
score_is ' A', 'AA', 1, 0;
score_is 'B ', 'AA', 0, 0;
score_is ' B', 'AA', 0, 0;

score_is 'AA', 'AA', 2, 0;
score_is 'BA', 'AA', 1, 0;
score_is 'AB', 'AA', 1, 0;
score_is 'BB', 'AA', 0, 0;

score_is 'AA', 'AB', 1, 0;
score_is 'BA', 'AB', 0, 2;
score_is 'AB', 'AB', 2, 0;
score_is 'BB', 'AB', 1, 0;

score_is 'AA', 'BA', 1, 0;
score_is 'BA', 'BA', 2, 0;
score_is 'AB', 'BA', 0, 2;
score_is 'BB', 'BA', 1, 0;

score_is 'AA', 'BB', 0, 0;
score_is 'BA', 'BB', 1, 0;
score_is 'AB', 'BB', 1, 0;
score_is 'BB', 'BB', 2, 0;

score_is 'AA', 'AC', 1, 0;
score_is 'BA', 'AC', 0, 1;
score_is 'AB', 'AC', 1, 0;
score_is 'BB', 'AC', 0, 0;

score_is 'AA', 'CA', 1, 0;
score_is 'BA', 'CA', 1, 0;
score_is 'AB', 'CA', 0, 1;
score_is 'BB', 'CA', 0, 0;

score_is 'AA', 'CC', 0, 0;
score_is 'BA', 'CC', 0, 0;
score_is 'AB', 'CC', 0, 0;
score_is 'BB', 'CC', 0, 0;

score_is '101', '0101', 0, 3;
score_is '010', '0101', 3, 0;

score_is 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 26, 0;
score_is 'BCDEFGHIJKLMNOPQRSTUVWXYZA', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0, 26;
score_is  'BCDEFGHIJKLMNOPQRSTUVWXYZ', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0, 25;
score_is 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',  'BCDEFGHIJKLMNOPQRSTUVWXYZ', 0, 25;

score_is <<'LIGHTHEARTED FRIEND', <<'OR IS IT?', 21, 256;
This is my story of Jack the Ripper, the man behind Britain's worst unsolved murders. It is a story that points to the unlikeliest of suspects: a man who wrote children's stories. That man is Charles Dodgson, better known as Lewis Carroll, author of such beloved books as Alice in Wonderland.
LIGHTHEARTED FRIEND
The truth is this: I, Richard Wallace, stabbed and killed a muted Nicole Brown in cold blood, severing her throat with my trusty shiv's strokes. I set up Orenthal James Simpson, who is utterly innocent of this murder. P.S. I also wrote Shakespeare's sonnets, and a lot of Francis Bacon's works too.
OR IS IT?

