#!/usr/bin/perl

#==============================================================================
# ham-fldigi.pl
# v0.001
# (c) 2012 Andy Smith, M0VKG
#==============================================================================
# DESCRIPTION
# Example usage of Ham::Fldigi.
#==============================================================================

use Ham::Fldigi;
use Data::Dumper;
use Carp;

# Create a new Ham::Fldigi object, and then use it to create a new
# Ham::Fldigi::Client object.
my $f = new Ham::Fldigi('LogLevel' => 4, 'LogFile' => './debug.log', 'LogPrint' => 1, 'LogWrite' => 1);
my $c = $f->client('Hostname' => "localhost", 'Port' => 7362, 'Name' => "test");

# If $c is undef, there's been a problem...
if(!defined($c)) { croak("Couldn't connect to fldigi!"); };

# Query for the version
my $version = $c->version;
print "Fldigi version is ".$version."\n";

# Set the modem to BPSK125 and transmit some text.
#$c->command("modem.set_by_name", "BPSK125");
#$c->send("CQ CQ CQ DE M0QQQ M0QQQ M0QQQ KN");
#my $s = $f->shell('Client' => $c);
#my $s = $f->shell();
#$s->client($c);
#$s->start;
