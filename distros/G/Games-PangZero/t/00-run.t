use strict;
use warnings;
use Test::More;
use Games::PangZero;

$ENV{PANGZERO_TEST} = 1;

$ENV{SDL_VIDEODRIVER}                          = 'dummy';
Games::PangZero::Initialize();
$Games::PangZero::Game                         = Games::PangZero::PanicGame->new();
@Games::PangZero::Highscore::UnsavedHighScores = ();
$Games::PangZero::Game->Run();

delete $ENV{SDL_VIDEODRIVER};
pass('Game Ran!!');
done_testing();
