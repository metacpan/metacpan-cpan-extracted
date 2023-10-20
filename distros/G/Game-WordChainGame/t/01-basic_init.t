use strict;
use warnings;
use Game::WordChainGame;
use Test::More;

BEGIN {
    use_ok( 'Game::WordChainGame' ) || print "Unable to load module!\n";
}
diag( "Testing Game::WordChainGame $Game::WordChainGame::VERSION, Perl $], $^X" );

my $game = Game::WordChainGame->new(players => ['Jack', 'Jill']);
isa_ok($game, 'Game::WordChainGame', 'Game object created');
is_deeply($game->players, ['Jack', 'Jill'], 'Players set correctly');
isa_ok($game->wn, 'WordNet::QueryData', 'WordNet object initialized');

done_testing();
