#!/usr/bin/perl
use warnings;
use strict;
use lib qw( ../lib ./lib );
use IRC::Bot::Hangman;



IRC::Bot::Hangman->new(
  channels => [ '#hangman' ],
  nick     => 'hangman',
  server   => 'irc.london.pm.org',
  games    => 3,
  can_talk => 1,
  word_list_name => 'too_easy',
  ignore_list => [qw(dipsy pasty namer)],
)->run;

print "Exiting\n";
