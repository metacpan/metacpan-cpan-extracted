#!/usr/bin/perl

use lib qw(../blib/lib ../blib/arch);
use strict;
use warnings;

use Mac::CoreMIDI;
use Mac::CoreMIDI::Client;;

my $c = Mac::CoreMIDI::Client->new(name => 'Perl',
    callback => \&Update);

Mac::CoreMIDI::RunLoopRun();

sub Update {
    print "MIDI system was updated!\n";
}
