use 5.036;

use Test2::V0;
use Test2::Bundle::More;
use Math::Random::Secure;

# use Data::Dumper;
# use Data::Printer;

use Game::Lottery;

my $pb = Game::Lottery->new( game => 'PowerBall');
my $mm = Game::Lottery->new( game => 'MegaMillions');
my $pbr = $pb->BigDraw();
my $mmr = $mm->BigDraw();

is ( $pbr->{game}, "PowerBall", 'Big Draw Method confirm game returned' );
is ( scalar $pbr->{redballs}->@*, 1, 'only 1 red ball was drawn');
is ( scalar $mmr->{whiteballs}->@*, 5, '5 whiteballs were drawn');

note( "Custom Game white 1-50 6 balls, red 1-20 1 ball (as default), no custom game name");
my $custgame = Game::Lottery->new( game => 'Custom');
$custgame->CustomBigDrawSetup(
  white => 50,
  whitecount => 6,
  red => 20
);
my $cgr = $custgame->BigDraw();
is ( scalar $cgr->{redballs}->@*, 1, 'only 1 red ball was drawn');
is ( scalar $cgr->{whiteballs}->@*, 6, '6 whiteballs were drawn');
is ( $cgr->{game}, 'CustomBigDraw', 'BigDraw returned default CustomBigDraw game name' );
note( "Custom Game white 1-99 1 ball, red 1-20 5 balls, custom game name =OttaL99");
$custgame->CustomBigDrawSetup(
  game => 'OttaL99',
  white => 99,
  whitecount => 1,
  red => 20,
  redcount => 5
);
$cgr = $custgame->BigDraw();
is ( scalar $cgr->{redballs}->@*, 5, 'only 5 red balls');
is ( scalar $cgr->{whiteballs}->@*, 1, '1 whiteball');
is ( $cgr->{game}, 'OttaL99', 'BigDraw returned game name set' );
done_testing();
