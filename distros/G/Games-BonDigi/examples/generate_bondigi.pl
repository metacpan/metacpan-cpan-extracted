#!/usr/bin/env perl

# Generate BonDigi(tm) sequence of words
# until a given number
#
# $Id: generate_bondigi.pl 11 2008-01-12 13:50:55Z Cosimo $

use strict;
use warnings;

# Just in case one doesn't want to install before trying...
use lib '../lib';
use lib './lib';

use Games::BonDigi;

sub show_usage
{
    print
        $0, ' - Generate "BonDigi" game sequence of words', "\n\n",
        "Usage: $0 <limit>\n\n",
        "       where <limit> is an integer (ex.: 5)\n";
    exit 1;
}

show_usage unless @ARGV;

# Sequence limit for game
my $limit = $ARGV[0] + 0;

if($limit < 2)
{
    die "Limit lesser than 2 is nonsense!\n";
}

# Start the fun!
my $game = Games::BonDigi->new();

# Get the iterator ...
my $seq = $game->sequence(2, $limit);

# ... and iterate over sequence
while(my $word = $seq->())
{
    print $word, ' ';
}

# End of script
