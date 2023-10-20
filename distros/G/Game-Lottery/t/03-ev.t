use 5.036;

use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
# use Data::Dumper;
# use Data::Printer;
use ok 'Game::Lottery';

my $PB = Game::Lottery->new( game => 'Powerball' );
my $MM = Game::Lottery->new( game => 'MegaMillions');

# if payout tables change the tests will need update after change in
# module calculations.
is( Game::Lottery::_round_val($MM->_BaseMMVal()), '0.25',
  'without jackpot MegaMillions pays 25¢ per $2 bet' );
is( Game::Lottery::_round_val($PB->_BasePBVal()), '0.38',
  'without jackpot PowerBall pays 38¢ per $2 bet' );
is( $PB->TicketValue( 683 * 10**6 ), '2.72', 'check a powerball ticket with a value in millions');
is( $PB->TicketValue( 683 ), '2.72', 'check the same ticket again without the 0s');
is ( $MM->TicketValue( 500 ), '1.90', 'check an mm ticket value' );
is ( $MM->TicketValue(), '0.25', 'check an mm ticket value with defaulted jackpot value of 0' );
is ( $MM->TicketJackPotValue( 500 ), '1.65', 'check mm for jackpot only value' );
is ( $PB->TicketJackPotValue( 683 * 10**6 ), '2.34', 'check pb for jackpot only value' );

done_testing();
