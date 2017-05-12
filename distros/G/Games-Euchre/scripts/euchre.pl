#!/usr/bin/perl -w

use strict;
use Carp;
use lib qw(./lib);  # for use in the distribution directory
use Games::Euchre;
use Games::Euchre::AI::Simple;
use Games::Euchre::AI::Human;

# Debugging
$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;

my $game = Games::Euchre->new();
#$game->{debug} = 1;
foreach my $i (1..4) {
   $game->setAI($i, Games::Euchre::AI::Simple->new());
}
$game->setAI(1, Games::Euchre::AI::Human->new());
$game->playGame();
