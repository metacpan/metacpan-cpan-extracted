use Test;
BEGIN { plan tests => 7462 }

use Games::Cards::Poker qw(:all);

ok(1);
my $shrt;
for(my $i=0;$i<=7460;$i++){
  $shrt = HandScore($i);
  ok($i, ScoreHand($shrt));
  if(ScoreHand($shrt) != $i) {
    for(my $j=-2;$j<=2;$j++) {
      $shrt = HandScore($i + $j);
      if(($i + $j) <= 7459) {
#        printf("!*EROR*! i:%4d != scor:%4d  shrt:$shrt!\n", ($i+$j), ScoreHand($shrt));
      }
    }
    last;
  }
}
