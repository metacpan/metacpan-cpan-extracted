use 5.006;
use Test::More qw( no_plan );

use strict;
use warnings;

my $script = "erc";		# script we're testing

# as of 2011.06.29  flvl() from File::Value
#### start boilerplate for script name and temporary directory support

use Config;
$ENV{SHELL} = "/bin/sh";
my $td = "td_$script";		# temporary test directory named for script
# Depending on circs, use blib, but prepare to use lib as fallback.
my $blib = (-e "blib" || -e "../blib" ?	"-Mblib" : "-Ilib");
my $bin = ($blib eq "-Mblib" ?		# path to testable script
	"blib/script/" : "") . $script;
my $perl = $Config{perlpath};		# perl used in testing
my $cmd = "2>&1 $perl $blib " .		# command to run, capturing stderr
	(-e $bin ? $bin : "../$bin") . " ";	# exit status in $? >> 8

my ($rawstatus, $status);		# "shell status" version of "is"
sub shellst_is { my( $expected, $output, $label )=@_;
	$status = ($rawstatus = $?) >> 8;
	$status != $expected and	# if not what we thought, then we're
		print $output, "\n";	# likely interested in seeing output
	return is($status, $expected, $label);
}

use File::Path;
sub remake_td {		# make $td with possible cleanup
	-e $td			and remove_td();
	mkdir($td)		or die "$td: couldn't mkdir: $!";
}
sub remove_td {		# remove $td but make sure $td isn't set to "."
	! $td || $td eq "."	and die "bad dirname \$td=$td";
	eval { rmtree($td); };
	$@			and die "$td: couldn't remove: $@";
}

use File::Value ':all';

#### end boilerplate

use File::ERC;

{	# num2tag tests

my @x = File::ERC::num2tag("c1", "h3", "2", "dummy");

is 4, scalar(@x), 'num2tag with 4 args returns 4 values';

is $x[0], 'ERC', 'num2tag c1 return';

is $x[1], 'when', 'num2tag h3 return';

is $x[2], 'what', 'num2tag pure numeric return';

is $x[3], '', 'num2tag with empty return for unknown code';

}

{	# erc script tests

my $x = `$cmd get 505 h505`;
is $? >> 8, '0', 'correct status returned on success';

is $x, 'publisher	h505
publisher	h505
',	'simple 2 arg erc script test';

$x = `$cmd get h1 h2 h3 h4 hxyzzy h11 h12 h13 h14`;
is $? >> 8, '1', 'correct status returned on error';

is $x, 'who	h1
what	h2
when	h3
where	h4
???	hxyzzy
about-who	h11
about-what	h12
about-when	h13
about-where	h14
', 'many-arg erc script with unknown element';

$x = `$cmd get | sort`;
like $x, qr/\nabout.*\npublisher.*\nsupport/s, 'dump of known elements';

$x = `$cmd get who where`;
is $x, 'who	h1
where	h4
', 'exact inverse mapping';

$x = `$cmd get "who\$"`;
like $x, qr/about-who.*meta-who.*support-who.*who	h1/s,
	'inexact inverse mapping';

$x = `$cmd`;
like $x, qr/^\s*erc/, 'default help blurb';
}
