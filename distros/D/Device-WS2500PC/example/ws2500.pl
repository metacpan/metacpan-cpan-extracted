#!/usr/bin/perl -w



 # ****************************************************************************
 # *** ws2500PC, (c) 2004 by Magnus Schmidt, ws2500pc@27b-6.de              ***
 # *** Example application using the Device::WS2500PC package               ***
 # ****************************************************************************
 # *** This program is free software; you can redistribute it and/or modify ***
 # *** it under the terms of the GNU General Public License as published by ***
 # *** the Free Software Foundation; either version 2 of the License, or    ***
 # *** (at your option) any later version.                                  ***
 # ****************************************************************************



use strict;
use Device::WS2500PC qw (:DEFAULT ws2500_SetDebug ws2500_FirstDataset ws2500_GetDatasetBulk);
use Date::Format;
use Getopt::Long;



sub print_Dataset($;$);
sub print_status($);
sub init();
sub main();
our %options;
%options = ('debug'=>0,'device'=>'/dev/ttyS0');



init();
main();
exit 0;



sub init() {
	my %actions = ('status'=>0,'time'=>0,'timestamp'=>0,'next'=>0,'current'=>0,'all'=>0,'reset'=>0);

	GetOptions ("p=s"=>\$options{'device'},"d"=>\$options{'debug'});
	if ((scalar @ARGV)!=1 or !exists $actions{$ARGV[0]} or $options{'device'} eq '') {
		print "Usage: $0 [-p <device>] [-d] <action>\n";
		print "       -p <device>    The device to use, default /dev/ttyS0\n";
		print "       -d             Enable debugging\n";
		print "       <action>       Action can be one of the following keywords:\n";
		print "           status     Print status\n";
		print "           time       Print time\n";
		print "           timestamp  Print unix timestamp\n";
		print "           current    Print the current dataset\n";
		print "           next       Print the next dataset\n";
		print "           all        Print all new datasets\n";
		print "           reset      Reset the pointer\n";
		print "\n(c) 2004 Magnus Schmidt, published under GPL\n";
		exit 1;
	}
	$options{'action'} = $ARGV[0];

	return 1;
}

sub main() {
	ws2500_SetDebug (1) if $options{'debug'};

	if ($options{'action'} eq 'status') {
		print_status ($options{'device'});
		
	} elsif ($options{'action'} eq 'time') {
		my $time = ws2500_GetTime ($options{'device'},1);
		if ($time>1) {
			print time2str("%Y-%m-%d %H:%M:%S",$time)."\n";
		} else {
			print "Communication error\n";
		}
		
	} elsif ($options{'action'} eq 'timestamp') {
		my $time = ws2500_GetTime ($options{'device'},1);
		if ($time>1) {
			print "$time\n";
		} else {
			print "Communication error\n";
		}

	} elsif ($options{'action'} eq 'next' or $options{'action'} eq 'current' or $options{'action'} eq 'all') {
		print_Dataset ($options{'device'},$options{'action'});

	} elsif ($options{'action'} eq 'reset') {
		if (ws2500_FirstDataset($options{'device'})) {
			print "Interface now points to first dataset\n";
		} else {
			print "Communication error\n";
		}
		
	} else {
		print "Internal error, unknown action '$options{'action'}'\n";
		exit 1;
	}
	
	return 1;
}

sub print_DatasetData ($) {
	my $data = shift;

	print "Dataset Nr.: $$data{'block'} / Recorded at: ";
	print time2str("%Y-%m-%d %H:%M:%S",$$data{'timestamp'})."\n";
	for (my $x=1;$x<=8;$x++) {
		next if $$data{"temp$x"}->{'status'} eq 'n/a';
		print "Sensor $x: ";
		printf ("%5.1f°C",$$data{"temp$x"}->{'temperature'});
		if ($$data{"temp$x"}->{'humidity'} ne 'n/a') {
			printf (" / %4.1f%%",$$data{"temp$x"}->{'humidity'});
		}
		if ($$data{"temp$x"}->{'new'}) {
			print " / (New)";
		}
		print "\n";
	}
	if ($$data{'wind'}->{'status'} ne 'n/a') {
		print "Wind: Speed ".$$data{'wind'}->{'speed'}."km/h / ";
		print "Direction ".$$data{'wind'}->{'direction'}."° / ";
		print "Accuracy: +-".$$data{'wind'}->{'accuracy'}."°";
		print " / (New)" if $$data{'wind'}->{'new'};
		print "\n";
	}
	if ($$data{'inside'}->{'status'} ne 'n/a') {
		print "Inside: ".$$data{'inside'}->{'temperature'}."°C / ";
		print $$data{'inside'}->{'pressure'}."hPa / ";
		if ($$data{'inside'}->{'humidity'} ne 'n/a') {
			print $$data{'inside'}->{'humidity'}."% / ";
		}
		print "(New)" if $$data{'inside'}->{'new'};
		print "\n";
	}
	if ($$data{'rain'}->{'status'} ne 'n/a') {
		print "Total: ".$$data{'rain'}->{'counter_ml'}."ml total\n";
	}
	if ($$data{'light'}->{'status'} ne 'n/a') {
		print "Light: ".$$data{'light'}->{'duration'}." Minutes / ";
		print $$data{'light'}->{'brightness'}." Lux";
		print " / (Sunflag)" if $$data>{'light'}->{'sun_flag'};
		print " / (New)" if $$data{'inside'}->{'new'};
		print "\n";
	}
	print "\n";

	return 1;
}

sub print_Dataset($;$) {
	my $port = shift;
	my $type = shift;
	my %result;
	my $finished = 0;
	my $token    = $type;
	my $maxbulk  = 20;

	if ($token eq 'current' or $token eq 'next') {
		if (ws2500_GetDataset($port,\%result,$token)) {
			if ($result{'dataset'}->{'status'} eq 'dataset') {
				print_DatasetData ($result{'dataset'});
			} else {
				# No new data
				print "No new dataset available\n" if $type ne 'all';
			}
		} else {
			print "Communication error\n";
			$finished=1;
		}
	} else {
		# Bulkdata
		while (!$finished) {
			if (ws2500_GetDatasetBulk($port,\%result,$maxbulk)) {
				if ($result{'bulkcount'}>0) {
					foreach my $data (@{$result{'bulk'}}) {
						print_DatasetData ($data);
					}
				}
				$finished=1 if $result{'bulkcount'} != $maxbulk;	
			} else {
				print "Communication error\n";
				$finished=1;
			}
		} # while
	}
}


sub print_status($) {
	my $port = shift;
	my %status;

	if (ws2500_GetStatus ($port,\%status)) {
		print "Sensors:\n";
		for (my $x=1;$x<=8;$x++) {
			printf "  Temperature Sensor %d:   %-3s (%3d Dropouts)\n",$x,$status{'sensors'}->{"temp$x"}->{'status'},
									             $status{'sensors'}->{"temp$x"}->{'dropouts'};
		}
		printf "  Rain Sensor:            %-3s (%3d Dropouts)\n",$status{'sensors'}->{'rain'}->{'status'},
								         $status{'sensors'}->{'rain'}->{'dropouts'};
		printf "  Wind Sensor:            %-3s (%3d Dropouts)\n",$status{'sensors'}->{'wind'}->{'status'},
								         $status{'sensors'}->{'wind'}->{'dropouts'};
		printf "  Light Sensor:           %-3s (%3d Dropouts)\n",$status{'sensors'}->{'light'}->{'status'},
								         $status{'sensors'}->{'light'}->{'dropouts'};
		printf "  Inside Sensor:          %-3s (%3d Dropouts)\n",$status{'sensors'}->{'inside'}->{'status'},
								         $status{'sensors'}->{'inside'}->{'dropouts'};

		print "Addresses:\n";
		print "  Rain:   $status{'sensors'}->{'rain'}->{'address'}\n";
		print "  Wind:   $status{'sensors'}->{'wind'}->{'address'}\n";
		print "  Light:  $status{'sensors'}->{'light'}->{'address'}\n";
		print "  Inside: $status{'sensors'}->{'inside'}->{'address'}\n";

		print "Interface:\n";
		print "  Interval:      Each $status{'interface'}->{'interval'} Minutes\n";
		print "  Version:       $status{'interface'}->{'version'}\n";
		print "  Language:      $status{'interface'}->{'language'}\n";
		print "  DCF available: ".($status{'interface'}->{'with_dcf'}?'Yes':'No')."\n";
		print "  DCF in sync:   ".($status{'interface'}->{'sync_dcf'}?'Yes':'No')."\n";
		print "  Protocol:      $status{'interface'}->{'protocol'}\n";
		print "  Type:          $status{'interface'}->{'type'}\n";
	} else {
		print "Error while retrieving data\n";
	}
	
}




