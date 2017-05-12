#!/usr/bin/perl

use lib qw(../blib/lib ../blib/arch);
use strict;
use warnings;

use Mac::CoreMIDI;

#my $c = Mac::CoreMIDI::Client->new(name => 'Perl');
my $c = MyClient->new(name => 'Perl');

my $i = Mac::CoreMIDI::Port->new_input(
    name => 'Perl input', client => $c);

my $o = Mac::CoreMIDI::Port->new_output(
    name => 'Perl output', client => $c);
    


Mac::CoreMIDI::RunLoopRun();

package MyClient;

use base qw(Mac::CoreMIDI::Client);

sub Update {
    print "Harhar! I am the updater!\n";
}
