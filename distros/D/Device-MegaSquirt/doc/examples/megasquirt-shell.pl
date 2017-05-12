#!/usr/bin/perl -w
use strict;

#
# megasquirt-shell.pl
# 
# A simple command line shell for running commands on
# a MegaSquirt controller.
#
#
# TODO - write table commands
#

use Device::MegaSquirt;
use Text::LookUpTable;

use Data::Dumper;

my $help = <<HELP;
  help

  quit
  exit

  display
    advanceTable1
    veTable1
    crankingRPM
  set
    crankingRPM

  Commands can usually be abbreviated to the first few
  characters as long as it is unique.

  e.g.
    display advanceTable1
    set crankingRPM 350
    display crankingRPM
HELP

unless (1 == @ARGV) {
    die "usage: a.out <device>\n";
}

my ($dev) = @ARGV;

my $ms = Device::MegaSquirt->new($dev)
	or die "Unable to create MegaSquirt object";

print "Successfully connected to a MegaSquirt controller.\n";
print "Version: '" . $ms->get_version . "'\n";

print "\n";
print "MegaSquirt command line shell started.\n";
print "Enter 'help' for more info.\n";

while (1) {

    print "megasquirt> ";

    my $full_cmd = <STDIN>;

    next if ($full_cmd =~ /^[\s]*$/);

    my @cmd_parts = split /[\s]+/, $full_cmd;
    my $cmd = $cmd_parts[0];

    if ($cmd =~ /^e/ or $cmd =~ /^q/) {
        # [e]xit, [q]uit
        print "Good Bye.\n";
        last;
    } elsif ($cmd =~ /^h/) {
        # [h]elp
       
        print $help;

    } elsif ($cmd =~ /^d/) { 
        # [d]isplay

        my $cmd = $cmd_parts[1];

        if ($cmd =~ /^adv/) {
            # [adv]anceTable1

            # this operation is slow, tell user to be patient
            print "  retrieving advanceTable1 ...\n";

            print $ms->read_advanceTable1();
        } elsif ($cmd =~ /^ve/) {

            # this operation is slow, tell user to be patient
            print "  retrieving veTable1 ...\n";

            # [ve]Table1
            print $ms->read_veTable1();
        } elsif ($cmd =~ /^c/) {
            # [c]rankingRPM
            print "crankingRPM: " . $ms->read_crankingRPM() . "\n";
        } else {
            print STDERR "unknown command: '$cmd'\n";
        }
    } elsif ($cmd =~ /^s/) {
        # [s]et

        my $cmd = $cmd_parts[1];

        if ($cmd =~ /^c/) {
            # [c]rankingRPM

            my $val = $cmd_parts[2];
            
            if ($val !~ /^[\d]{1,4}$/) {
                print STDERR "Value '$val' must be an integer between 1 and 4 digits.\n";
                next; # abort
            } 

            my $res = $ms->write_crankingRPM($val);
            if ($res) {
                print "  crankingRPM set to '$val' successfully.\n";
            } else {
                print "  failed to set crankingRPM.\n";
            }
        } else {
            print STDERR "unknown command: '$cmd'\n";
        }
    } else {
        print STDERR "unknown command: '$cmd'\n";
    }

}


