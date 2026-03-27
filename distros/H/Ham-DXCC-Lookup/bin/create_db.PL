#!/usr/bin/env perl

# Download the data from https://www.country-files.com/

use strict;
use warnings;

use Text::CSV;
use autodie qw(:all);

my $file = 'downloads/cty.dat';
my $filename = 'data/cty.csv';

if(!-d 'data') {
	mkdir 'data', 0755;
}

my $force_flag;
if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	open my $out, '>', $filename;
	print $out "prefix,dxcc_name,iso,cq_zone,itu_zone,continent,latitude,longitude,gmt_offset,primary_prefix\n";
	exit;
}

if(-r $filename) {
	# Don't bother downloading if the file is less than a day old
	if(((-s $filename) > 0) && (-M $filename < 1) && !$force_flag) {
		exit;
	}
	unlink $filename;
}

open(my $out, '>:encoding(utf8)', $filename);

my $csv = Text::CSV->new({ binary => 1, eol => "\n" });

# Header (added gmt_offset and dxcc_number)
$csv->print($out, [qw(prefix dxcc_name iso cq_zone itu_zone continent latitude longitude gmt_offset primary_prefix)]);

open(my $cty, '<', $file);

while(my $line = <$cty>) {
	chomp $line;
	next unless length $line >= 70;	# basic sanity check
	$line =~ s/\r//g;

	my($name, $cqzone, $ituzone, $cont, $lat, $lon, $gmt_offset, $primary_prefix) = unpack('A26 A5 A5 A5 A9 A10 A9 A6', $line);

	$name	 =~ s/\s+$//;
	$name =~ s/:$//;
	$cqzone =~ s/\s+$//;
	$cqzone =~ s/:$//;
	$ituzone =~ s/\s+$//;
	$ituzone =~ s/:$//;
	$cont =~ s/\s+$//;
	$cont =~ s/:$//;
	$lat =~ s/^\s+//;
	$lat =~ s/\s+$//;
	$lat =~ s/:$//;
	$lon =~ s/^\s+//;
	$lon =~ s/\s+$//;
	$lon =~ s/:$//;
	$gmt_offset =~ s/^\s+//;
	$gmt_offset =~ s/\s+$//;
	$gmt_offset =~ s/:$//;
	$primary_prefix =~ s/\s+$//;
	$primary_prefix =~ s/:$//;

	# iso not available in CTY.DAT, so empty or you add a map later
	my $iso = '';

	while(1) {
		my $prefixes = <$cty>;
		chomp $prefixes;
	$prefixes =~ s/\r//g;

		# Prefixes can be comma or semicolon separated, often with modifiers (* = ...)
		my @prefix_list = split /[,;]/, $prefixes;

		for my $p (@prefix_list) {
		# Clean modifiers, brackets, etc.
		$p =~ s/^[\*=\~\<\>\{\}\#\[\]\/\+]+//;
		$p =~ s/[\#\[\]\(\)]//g;
		$p =~ s/^\s+//g;
		next unless $p =~ /\w/;

		$csv->print($out, [
			$p,
			$name,
			$iso,
			$cqzone,
			$ituzone,
			$cont,
			$lat,
			$lon,
			$gmt_offset,
			$primary_prefix,
		]);
		}
		last if($prefixes =~ /;$/);
	}
}

close $out;
print "Generated cty.csv with DXCC number and GMT offset fields\n";
