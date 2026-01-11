#!/usr/bin/perl

use Getopt::Long;
use strict;
use warnings;
use Dump::Krumo;
use Time::HiRes qw(time);
use JSON::RPC::Simple::Lite;

# Default URL
my $api_url = "https://www.perturb.org/api/json-rpc/";

###################################################################

my ($method,$curl);
my $params = "";
my $debug  = 0;

my $ok = GetOptions(
	"debug+"   => \$debug,
	"url=s"    => \$api_url,
	"method=s" => \$method,
	"params=s" => \$params,
	"curl"     => \$curl,
);

my @params = ();

# Raw called like echo_data(2,4,8)
if (!$method) {
	if ($ARGV[0] && $ARGV[0] =~ /([\w.]+)\((.*?)\)/) {
		$method = $1;
		$params = $2;

		@params = str_to_array($params);
	}
} else {
	# Convert the params string to an array
	@params = split(/,/, $params);
	#@params = eval($params);
}

if (!$method || !$api_url) {
	die(usage());
}

my $s = JSON::RPC::Simple::Lite->new($api_url,{debug => $debug});

if (!@params) {
	#@params = undef;
}

###################################################################

if ($curl) {
	my $curl = $s->curl_call($method,@params);
	print $curl . "\n";
	exit;
}

if ($debug > 1) {
	my $curl = $s->curl_call($method,@params);
	print "curl     : $curl\n";
}

# Raw call method
my $i = $s->_call($method,@params);

# Statically code the method name in your code (most readable), uses AUTOLOAD magic
# Note: requires params to be set to SOMETHING (even undef) for AUTOLOAD magic to work
#my $i = $s->peak->echo_data(@params);

if (!defined($i)) {
	my $status = $s->{response}->{status};
	print "*** Error decoding JSON ***\nHTTP Code: $status - Response:\n";
	print $s->{response}->{content} . "\n";

	exit(2);
}

print color('white', "Response :\n");
out($i);

###################################################################

sub usage {
	return "$0 --method echo_data [--params \"2,4,6,eight\"] [--url http://domain.com/path/] [--debug]\n";
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my ($str, $txt) = @_;

	# If we're NOT connected to a an interactive terminal don't do color
	if (-t STDOUT == 0) { return $txt // ""; }

	# No string sent in, so we just reset
	if (!length($str) || $str eq 'reset') { return "\e[0m"; }

	# Some predefined colors
	my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

	# Get foreground/background and any commands
	my ($fc,$cmd) = $str =~ /^(\d{1,3})?_?(\w+)?$/g;
	my ($bc)      = $str =~ /on_(\d{1,3})$/g;

	if (defined($fc) && int($fc) > 255) { $fc = undef; } # above 255 is invalid

	# Some predefined commands
	my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
	my $cmd_num = $cmd_map{$cmd // 0};

	my $ret = '';
	if ($cmd_num)      { $ret .= "\e[${cmd_num}m"; }
	if (defined($fc))  { $ret .= "\e[38;5;${fc}m"; }
	if (defined($bc))  { $ret .= "\e[48;5;${bc}m"; }
	if (defined($txt)) { $ret .= $txt . "\e[0m";   }

	return $ret;
}

# Use Data::Dump::Color if available, else Data::Dumper
BEGIN {
	if(eval "require Data::Dump::Color; 1") {
		#*out = \&Data::Dump::Color::dd;
		*out = \&Dump::Krumo::kx;
	} else {
		require Data::Dumper;
		*out = sub {
			print Data::Dumper::Dumper(@_) . "\n"
		};
	}
}

sub str_to_array {
	my ($str, $sep) = @_;
	my @ret;

	# Default separator
	$sep ||= ",";

	# Split at the separator
	#my @p = split(/$sep/, $str);
	# Borrowed from: https://stackoverflow.com/questions/9855101/split-comma-separated-list-with-commas-embedded-in-quoted-arguments-in-perl
	my @p = $str =~  m/(['"][^"']+['"]|[^,]+)(?:,\s*)?/g;

	#dd([\@p, scalar(@p)]); die;

	# Clean up each element
	foreach my $x (@p) {
		# Trim off trailing and leading whitespace
		$x =~ s/^\s*//;
		$x =~ s/\s*$//;

		# Remove surrounding quotes (convert to string)
		if ($x =~ /^(['"](.*?)['"])$/) {
			$x = $2;
		# Convert numbers to an int/float
		} elsif ($x =~ /^[\d-]/) {
			$x += 0;
		# If it's neither a quoted word or a number
		} else {
			print STDERR "Skipping $x because it's not formatted correctly. Try quoting it?\n";
			exit();
			$x = undef;
		}

		push(@ret, $x);
	}

	# Eval is another option, but has less control on invalid items
	#$str = "($str)";
	#my @z = eval($str);

	return @ret;
}
