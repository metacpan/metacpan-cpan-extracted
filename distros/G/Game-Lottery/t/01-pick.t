use 5.036;

use Test2::V0;
use Test2::Bundle::More;

# use Data::Dumper;
# use Data::Printer;
use Game::Lottery;

sub hiloballs ( $hi, @balls ) {
  my $low = $hi;
  my $high = 1;
  for my $ball ( @balls ) {
    $low  = $ball if $ball < $low;
    $high = $ball if $ball > $high;
  }
  cmp_ok( $low, '>=', 1, "Low Ball ${low} is at least 1");
  cmp_ok( $high, '<=', $hi, "High Ball ${high} is no greater than ${hi}");
}

my ($lowball,$highball) = (35,1); # low/hi start at opposite values
subtest 'Pickpall returns full range values for 35 balls' => sub {
    for (my $i = 1; $i <= 5000; $i++) {
        my $pick = Game::Lottery::_PickBall(35);
        $lowball = $pick if $pick < $lowball;
        $highball = $pick if $pick > $highball;
    }
    is( $lowball, 1, 'with 5000 picks the lowball should be 1');
    is( $highball, 35, 'with 5000 picks the highball should be 35');
};

my @picks = Game::Lottery::_DrawBalls( 35, 5 )->@* ;
is (scalar(@picks), 5, 'Shoud have picked 5 balls.');
note ( "balls picked this time: @picks");

subtest 'Basic Draw Games' => sub {
  my $drawgame = Game::Lottery->new( game => 'draw');
  my $draw1 = $drawgame->BasicDraw ( 60, 4 );
  note( 'BasicDraw 4 balls 1-60');
  is( scalar( $draw1->@*), 4, 'correct number of balls picked');
  hiloballs( 60, $draw1->@* );
  my $draw2 = $drawgame->BasicDraw ( 100, 6 );
  note( 'BasicDraw 6 balls 1-100');
  is( scalar( $draw2->@*), 6, 'correct number of balls picked');
  hiloballs( 100, $draw2->@* );
};

done_testing();
