#!/usr/bin/perl
use warnings;
use strict;
use blib;
use lib qw( lib );
use Data::Dumper;
use Test::More no_plan => 1;
use Games::GuessWord;


use_ok( 'IRC::Bot::Hangman' );
my %params = (
              channels => [ '#hangman' ],
              nick     => 'hangman',
              server   => 'irc.blablabla.bla',
              games    => 1,
             );
ok( my $bot = IRC::Bot::Hangman->new( %params ) );
is( ($bot->channels)[0], '#hangman' );
is( $bot->nick, 'hangman' );
is( $bot->server, 'irc.blablabla.bla' );
is( $bot->games, 1);
ok( ! $bot->wordlist( 1 ) );
ok( $bot->word_list( ['foo', 'bar'] ) );
is( scalar @{$bot->word_list}, 2 );
ok( $bot->games(2) );
is( $bot->games, 2 );
ok( $bot->game->isa('Games::GuessWord') );
my $game = Games::GuessWord->new(words => []);
ok( $bot->game($game) );
is( $bot->game, $game );
ok( $bot->new_game );
isnt( $bot->game, $game );
ok( ! $bot->can_talk );
ok( ! $bot->game->won );
ok( ! $bot->game->lost );
ok( $bot->game->guess($bot->game->secret) );
ok( $bot->game->won );
