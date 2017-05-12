
package Log::Parallel::Geo::IP;

use strict;
use warnings;
use File::Slurp;
use File::Flock;
use Search::Binary;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(ip2cc ordered_ip2cc ip2int start_ordered_ip2cc location);

# 
# This uses the database that can be downloaded from
# http://software77.net/geo-ip/
#

our $cc_update_freq = 3; # days
our $cc_stream_command = "wget 'software77.net/geo-ip?DL=1' -q -O -";
our $cc_file_location = "$ENV{HOME}/.IP2Country.gz";
our $cc_file_min_size = 800_000;


if (-e $cc_file_location && -M $cc_file_location < $cc_update_freq) {
	# good
} else {
	lock($cc_file_location);
	if (-e $cc_file_location && -M $cc_file_location < $cc_update_freq && -s _ > $cc_file_min_size) {
		# some other process fixed it
		unlock($cc_file_location);
	} else {
		print STDERR "Updating IP->country code database\n";
		open my $data, "$cc_stream_command |" or die;
		local($/) = undef;
		my $new = <$data>;

		if (length($new) > $cc_file_min_size) {
			write_file("$cc_file_location.tmp", $new);
			rename("$cc_file_location.tmp", $cc_file_location) or die;
		} else {
			my $l = int(length($new)/1024);
			die "IP->country code database isn't big enough (${l}K)";
		}
	}
}

my $ccdata;

my $tries = 0;

#
# Portions of this function are copied from David Sharnoff's
# readfancylog() function in his ccserver program.
#
sub read_data
{
	my ($handle, $val, $pos) = @_;
	die if $tries++ > 40;
	if (defined $pos) {
		pos($ccdata) = $pos;
		$ccdata =~ /\G.*?\n(?=(?:"\d|\z))/gcs;
	}

	$pos = pos($ccdata);

	$ccdata =~ /\G(.*?)\n(?=(?:"\d|\z))/gcs or return (-1, $pos);
	my $line = $1;

	# "4177526784","4194303999","iana","410227200","ZZ","ZZZ","Reserved"

	$line =~ /"(\d+)","(\d+)",".*?","\d+",".*?",".*?",".*?"/;
	return (-1, $pos) if $val < $1;
	return (1, $pos) if $val > $2;
	return (0, $pos);
}

# $pos = binary_search($min, $max, $val, $read, $handle, [$size]);

my $num255_rx = qr/(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)/;
my $ip_rx = qr/$num255_rx\.$num255_rx\.$num255_rx\.$num255_rx/;

sub ip2cc
{
	my ($ip) = @_;

	unless ($ccdata) {
		open my $cc, "-|", "zcat", "-f", $cc_file_location or die;
		local($/) = undef;
		$ccdata = <$cc>;
		$ccdata =~ s/^.*?\n"/\n\n"/s;
	}

	$tries = 0;
	$ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ or die;

	my $val = $4 + $3 * 256 + $2 * 65536 + $1 * (256*256*256);

	my $pos = binary_search(0, length($ccdata), $val, \&read_data, 0, 40);
	return undef unless $pos;

	pos($ccdata) = $pos;
	$ccdata =~ /\G(.*?)\n(?=(?:"\d|\z))/gcs or return undef;
	my $line = $1;
	$line =~ /"\d+","\d+",".*?","\d+","(.*?)","(.*?)","(.*?)"/ or die;

	return $1 unless wantarray;
	return ($1, $2, $3);
}

my $ccfd;
my $last_line;
my $last_begin;
my $last_end;
my $last_cc;
my $last_val;

sub ordered_ip2cc
{
	my ($ip) = @_;

	my $val;
	if ($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		$val = $4 + $3 * 256 + $2 * 65536 + $1 * (256*256*256);
	} elsif ($ip =~ /^\d+$/) {
		$val = $ip;
	} else {
		die $val;
	}

	die if $last_val && $last_val < $val;

	return undef unless $ccfd;
	while ($val > $last_end) { 
		unless (defined($_ = <$ccfd>)) {
			undef $ccfd;
			return undef;
		}
		next if /^#/;
		# "407633920","407896063","arin","976838400","CA","CAN","Canada"
		next unless /"(\d+)","(\d+)","[^"]*","\d+","([^"]*)","([^"]*)","([^"]*)"/ or die "line $_ - ";
		$last_begin = $1;
		$last_end = $2;
		$last_cc = $3;
		$last_line = $_;
	}
	return undef unless $val >= $last_begin;
	return $last_cc;
}

sub start_ordered_ip2cc
{
	open $ccfd, "-|", "zcat", "-f", $cc_file_location or die;
	while (<$ccfd>) {
		next unless /"(\d+)","(\d+)",".*?","\d+","(.*?)","(.*?)","(.*?)"/;
		$last_begin = $1;
		$last_end = $2;
		$last_cc = $3;
		$last_line = $_;
		last;
	}
	undef $last_val;
	$last_end = 0;
	$last_begin = 2**32;
}

sub ip2int
{
	my ($ip) = @_;
	$ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ or die;
	return $4 + $3 * 256 + $2 * 65536 + $1 * (256*256*256);
}

1;

__END__

=head1 NAME

Log::Parallel::Geo::IP - IP address to country code translation

=head1 SYNOPSIS

 use Log::Parallel::Geo::IP;

 local($Log::Parallel::Geo::IP::cc_stream_command) = "ssh my.computer cat my.cached.copy";

 $cc = ip2cc("1.2.3.4");

 start_ordered_ip2cc();
 $integer = ip2int("1.2.3.4");
 $cc = ordered_ip2cc("1.2.3.4");

=head1 DESCRIPTION

This package does IP addres to country code translations.  It does it 
based on a text file downloaded from C<http://software77.net/geo-ip/>.
It will automatically re-download the file every 
C<$Log::Parallel::Geo::IP::cc_update_freq> days (default 3).  If you're
running this on multiple systems, download the file in a cronjob 
and distribute it.

It can do a lookup of a single address with a binary search of the file
C<ip2cc()> or it can bulk lookups if the requests come in IP address integer
order.  Start bulk lookups with C<start_ordered_ip2cc()> and then do the
lookups with C<ordered_ip2cc()>.  Bulk lookups are much faster when you have
to do a lot of them.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

