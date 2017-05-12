# datapanel.pl
#
# Act as a SNP Slave and serve serial port requests from a DataPanel
# Implement reading and writing of SNP data as Amarok commands etc
#
# Segment Data definitions for the Linux Datapanel, as defined
# in the DataDesigner database in datadesigner/linux.DTB
#
# %Q1	     play		 Play
# %Q2	     pause		 Pause
# %Q3	     prev		 Prev
# %Q4	     next		 Next
# %Q5	     volup		 Vol -
# %Q6	     voldown		 Vol +
#
# %R1-%R16     artist		 Current song artist (max 32 bytes)
# %R17-%R32     track		 Current song name text (max 32 bytes)
# %R33-%R48     album		 Current song album text (max 32 bytes)
#
# Author: Mike McCauley (mikem@open.com.au)
# Copyright (C) 2006 Mike McCauley
# $Id: datapanel.pl,v 1.1 2006/05/31 23:30:53 mikem Exp mikem $

use strict;
require "newgetopt.pl";
use Device::SNP;
use DCOP::Amarok::Player;

my $player;

# Override Device::SNP to implement our own read and write operations
package LinuxDataPanel;
our @ISA = ('Device::SNP::Slave');

# Here we override some functions in Device::SNP::Slave
# so we get control when the DataPanel asks for and sets data.
# Sigh: DP30 seems to need byte swaped text, so need -b flag
sub read_words
{
    my ($self, $segmentname, $offset, $length) = @_;

    my $result;
    if ($segmentname eq 'R' && $offset == 0)
    {
	$result = $player->artist();
    }
    elsif ($segmentname eq 'R' && $offset == 16)
    {
	$result = $player->title();
    }
    elsif ($segmentname eq 'R' && $offset == 32)
    {
	$result = $player->album();
    }
    if ($main::opt_b)
    {
	$result .= "\0" if length $result & 0x1; # pad to even length
	$result = pack('v*', unpack('n*', $result)); # byte swap
    }
    return pack('a32', $result);
}

sub write_bits
{
    my ($self, $segmentname, $offset, $length, $data) = @_;

    if ($segmentname eq 'Q' && $offset == 0)
    {
	$player->play();
    }
    elsif ($segmentname eq 'Q' && $offset == 1)
    {
	$player->pause();
    }
    elsif ($segmentname eq 'Q' && $offset == 2)
    {
	$player->prev();
    }
    elsif ($segmentname eq 'Q' && $offset == 3)
    {
	$player->next();
    }
    elsif ($segmentname eq 'Q' && $offset == 4)
    {
	$player->volumeDown();
    }
    elsif ($segmentname eq 'Q' && $offset == 5)
    {
	$player->volumeUp();
    }
    return 1; # Success
}


package main;
my @options = 
    (
     'h',                   # Help, show usage
     'd',                   # Debug
     'p=s',                 # Port device name, default /dev/ttyUSB0
     'b',                   # Apply byte swapping (for DP30)
     );

&NGetOpt(@options) || &usage;
&usage if $main::opt_h;

my $port = '/dev/ttyUSB0';
$port = $main::opt_p if defined $main::opt_p;
my $s = new LinuxDataPanel(Portname => $port,
			   Debug => $main::opt_d);
die "Could not create Device::SNP::LinuxDataPanel\n" unless $s;

$player = DCOP::Amarok::Player->new();
die "Could not create DCOP::Amarok::Player" unless $player;

# Receive commands and despatch them to the functions in LinuxDataPanel
$s->run();

#####################################################################
sub usage
{
    print "usage: $0 [-h] [-d] [-p portdevice] [-b]\n";
    exit;
}
