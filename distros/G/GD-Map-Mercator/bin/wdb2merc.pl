#!perl -w
#
#	convert WDB textual GIS data into Mercator projected 
#	binary data for quicker loading and data compression
#
use Geo::Mercator;
use Pod::Usage;

use strict;
use warnings;

pod2usage(-exitval => 1 ) if $ARGV[0] && 
	(($ARGV[0] eq '-h') || ($ARGV[0] eq '-help'));
pod2usage(-msg => 'No input path specified.', -exitval => 1 ) unless $ARGV[0];
pod2usage(-msg => 'No output path specified.', -exitval => 1 ) unless $ARGV[1];
my $path = $ARGV[0];
my $out = $ARGV[1];

my @srcs = qw(
africa-bdy
africa-cil
africa-riv
asia-bdy
asia-cil
asia-riv
europe-bdy
europe-cil
europe-riv
namer-bdy
namer-cil
namer-pby
namer-riv
samer-bdy
samer-cil
samer-riv
asia-bdy
asia-riv
);

$| = 1;
read_wdb($_)
	foreach (@srcs);

sub read_wdb {
	my $src = shift;
	print STDERR "Skipping $path/$src.txt: $!\n" and
	return undef
		unless open INF, "$path/$src.txt";

	open BINF, '>', "$out/$src.bin" or die "Cannot open $out/$src.bin: $!";
	binmode BINF;
	my $oldfd = select BINF;
	$| = 1;
	select $oldfd;

	my @wdb = ();
	my ($minlat, $minlong, $maxlat, $maxlong) = (10000, 100000, -100000, -100000);
#
#	add parsing code here
#
	print "Loading $path/$src.txt\n";
	my $seg = '';
	my @mercs = ();
	my ($segno, $rank, $pts);
	my $msg;
	while (<INF>) {
		s/^\s+//;
		unless (substr($_, 0, 7) eq 'segment') {
			my ($lat, $long) = split /\s+/;
#
#	we've got some dirty data!!!
#
			print STDERR "\n**** Bad data point in $path/$src.txt segment $segno: ",
				$lat, ', ', $long, "\n" and
			next
				unless ($lat >= -90) && ($lat <= 90) && ($long >= -192) && ($long <= 192);
			push @mercs, mercate($lat, $long);
			$minlat = $lat
				if ($minlat > $lat);
			$maxlat = $lat
				if ($maxlat < $lat);
			$minlong = $long
				if ($minlong > $long);
			$maxlong = $long
				if ($maxlong < $long);
			next;
		}
#
#	set total record length (after recordlength)
#	then pack all the floats into the record
#
		if (@mercs > 0) {
			$msg = join('', 
				"\r",
				"Packing segment $segno got ", scalar @mercs, " coords, expected ",
					$pts * 2);
			$msg .= ' ' x (75 - length($msg));
			print $msg;
			$seg .= pack('LLLL', 12 + (8 * 2 * $pts), $segno, $rank, $pts);
			$pts *= 2;
			$seg .= pack("d$pts", @mercs);
			print BINF $seg;
			@mercs = ();
			$seg = '';
		}
		($segno, $rank, $pts) = (/^\s*segment\s+(\d+)\s+rank\s+(\d+)\s+points\s+(\d+)/);
		$msg = "\rStarting segment $segno";
		$msg .= ' ' x (75 - length($msg));
		print $msg;
	}
	close INF;
	if (@mercs > 0) {
		$msg = join('', 
			"\rPacking segment $segno got ", scalar @mercs, " coords, expected ",
				$pts * 2);
		$msg .= ' ' x (75 - length($msg));
		print $msg;
		$seg .= pack('LLLL', 12 + (8 * 2 * $pts), $segno, $rank, $pts);
		$pts *= 2;
		$seg .= pack("d$pts", @mercs);
		print BINF $seg;
	}

	print "\n$src bounding box is $minlat, $minlong to $maxlat,$maxlong\n";
	close BINF;
	return 1;
}

=pod

=head1 NAME

wdb2merc - Convert Textual WDB datasets to binary Mercator Projected files

=head1 SYNOPSIS

	wdb2merc.pl <WDB-path> <output-path>
	wdb2merc.pl -h|-help

=head1 DESCRIPTION

Reads the latitude/longitude coordinate values from textual WDB dataset
files I(available at> L<http://www.evl.uic.edu/pape/data/WDB/>) and converts
them to Mercator projected distance values (in meters), writing the
the values out in a packed binary format that is faster to load, and
compresses the data approx. 35%.

The datasets are also scrubbed of some bad data (I checked my globe
several times, but couldn't find longitude -544 degrees...).

The resulting binary files are used by L<GD::Map::Mercator> to
render map images.

=cut
