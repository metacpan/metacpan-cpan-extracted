use strict;
use warnings;
use Game::WordChainGame;
use Test::More;

my $game = Game::WordChainGame->new(players => ['Jack', 'Jill']);
ok($game->validate_word('apple'), 'Valid word: apple');
ok(!$game->validate_word('aple'), 'Invalid word: aple');

done_testing();
