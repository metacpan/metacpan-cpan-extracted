use 5.036;

use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
# use Data::Dumper;
use Data::Printer;
use ok 'Game::Lottery';

my ($lowball,$highball) = (1,1);

my $lottery = Game::Lottery->new( game => 'Powerball' );
can_ok ( $lottery, '_PickBall');
can_ok ( $lottery, '_DrawBalls');
can_ok ( $lottery, 'BigDraw');

ok( dies { my $badlottery = Game::Lottery->new( game => 'GrandPonzi' ); },
    'unknown game dies'
);

my $PB = Game::Lottery->new( game => 'pOWER');
is( $PB->Game(), 'PowerBall', 'ADJUST block corrected game pOWER to PowerBall');
my $MM = Game::Lottery->new( game => 'megam');
is( $MM->Game(), 'MegaMillions', 'ADJUST block corrected game megam to MegaMillions');

my $cbd = Game::Lottery->new( game => 'CustomBigDraw' );
ok( dies { $cbd->BigDraw(); },
    'CustomBigDraw will die if CustomBigDrawSetup is not run to set ball values'
);


done_testing();
