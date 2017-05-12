#!/usr/bin/perl

use strict;
use Config;
use lib "lib";
use Device::TNC;
use Data::Dumper;

my %tnc_config = (
	'port' => ($Config{'osname'} eq "MSWin32") ? "COM3" : "/dev/TNC-X",
	'baudrate' => 19200,
	'warn_malformed_kiss' => 1,
	'raw_log' => "raw_packet.log",
	);
my $tnc = new Device::TNC('KISS', %tnc_config);
die "Error: TNC didn't connect or something.\n" . Dumper($tnc) unless $tnc;

while (1)
{
	print "\nWaiting for next frame\n";
	#my $frame = $tnc->read_kiss_frame();
	#print "\nKISS FRAME: $frame\n";
	#my $frame = $tnc->read_hdlc_frame();
	#print "\nHDLC FRAME: $frame\n";
	my $data = $tnc->read_ax25_frame();
	#print "AX.25 FRAME: ". Dumper($data) ."\n";
	print "From: $data->{'ADDRESS'}->{'SOURCE'} To: $data->{'ADDRESS'}->{'DESTINATION'}";
	my $repeaters = join ", ", @{$data->{'ADDRESS'}->{'REPEATERS'}};
	my $info = join "", @{$data->{'INFO'}};
	print " via $repeaters\nData: $info\n";
}


