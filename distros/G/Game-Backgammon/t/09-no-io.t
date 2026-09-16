#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

# THE ENGINE DOES NO INPUT OR OUTPUT. Not a style rule: it is the reason
# this is a distribution rather than code inside one application. Game::
# Cribbage was an engine with a terminal welded to it and only the engine
# turned out to be reusable, which is the finding this dist was shaped
# around.
#
# So: tie STDOUT and STDERR to something that dies on write, make warnings
# fatal, and play a whole game through the engine and the bot. Anything that
# prints, warns, or reads takes the test down.

package Deaf;
sub TIEHANDLE { bless {}, shift }
sub PRINT     { die "the engine printed: @_[1 .. $#_]\n" }
sub PRINTF    { die "the engine printf'd\n" }
sub WRITE     { die "the engine wrote\n" }
sub READLINE  { die "the engine tried to read\n" }
sub GETC      { die "the engine tried to read a character\n" }
sub CLOSE     { 1 }

package main;

use Game::Backgammon;
use Game::Backgammon::Bot;

plan tests => 3;

my $result;
my $err = '';
{
    local $SIG{__WARN__} = sub { die "the engine warned: $_[0]" };
    tie *STDOUT, 'Deaf';
    tie *STDERR, 'Deaf';
    tie *STDIN,  'Deaf';

    eval {
        my $game = Game::Backgammon->new(seed => Digest::SHA::sha256('quiet'));
        my $bot  = Game::Backgammon::Bot->new(level => 3);
        my $n = 0;
        while ($game->status eq 'active' && $n++ < 4000) {
            my $turn = $bot->choose($game) or last;
            $game->play($turn) or last;
        }
        # the things a caller asks for, all of which could be tempted to print
        $game->board->pip_count('white');
        $game->to_log;
        $result = $game->result;
        1;
    } or $err = $@;

    untie *STDOUT;
    untie *STDERR;
    untie *STDIN;
}

is($err, '', 'a whole game plays without printing, warning or reading');
ok($result, 'and the game actually finished');
ok($result && $result->winner, 'with a winner');
