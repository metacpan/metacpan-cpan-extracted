use 5.006;
use Test::More qw( no_plan );
use strict;
use warnings;

my $script = "snag";		# script we're testing

# as of 2010.05.02  (perlpath minus _exe, plus filval(), no -x for MSWin)
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

# Abbreviated version of "raw" File::Value::file_value()
sub filval { my( $file, $value )=@_;	# $file must begin with >, <, or >>
	if ($file =~ /^\s*>>?/) {
		open(OUT, $file)	or return "$file: $!";
		my $r = print OUT $value;
		close(OUT);		return ($r ? '' : "write failed: $!");
	} # If we get here, we're doing file-to-value case.
	open(IN, $file)		or return "$file: $!";
	local $/;		$_[1] = <IN>;	# slurp mode (entire file)
	close(IN);		return '';
}

#### end boilerplate

use File::Value ':all';

{	# file_value tests

remake_td();
my $x = '   /hi;!echo *; e/fred/foo/pbase        ';
my $y;

is file_value(">$td/fvtest", $x, "raw"), "", 'write returns ""';

is file_value("<$td/fvtest", $y, "raw"), "", 'read returns ""';

is $x, $y, 'raw read of what was written';

my $z = (-s "$td/fvtest");
is $z, length($x), "all bytes written";

file_value("<$td/fvtest", $x);
is $x, '/hi;!echo *; e/fred/foo/pbase', 'default trim';

file_value("<$td/fvtest", $x, "trim");
is $x, '/hi;!echo *; e/fred/foo/pbase', 'explicit trim';

file_value("<$td/fvtest", $x, "untaint");
is $x, 'hi', 'untaint test';

file_value("<$td/fvtest", $x, "trim", 0);
is $x, '/hi;!echo *; e/fred/foo/pbase', 'trim, unlimited';

file_value("<$td/fvtest", $x, "trim", 12);
is $x, '/hi;!echo', 'trim, max 12';

file_value("<$td/fvtest", $x, "trim", 12000);
is $x, '/hi;!echo *; e/fred/foo/pbase', 'trim, max 12000';

like file_value("<$td/fvtest", $x, "foo"), '/must be one of/',
'error message test';

like file_value("$td/fvtest", $x),
'/file .*fvtest. must begin.*/', 'force use of >, <, or >>';

# disallowed windows chars: $s =~ tr[<>:"/?*][.]
is file_value(">$td/Whoa,dude+! Huck Finn", "dummy"), "",
	'write to weird filename';

file_value(">$td/fvtest", "   foo		\n\n\n");
file_value("<$td/fvtest", $x, "raw");
is $x, "foo\n", 'trim on write';

is file_value(">$td/fvtest", "abcdefghij" x 40000), "", 'wrote large file';
is file_value("<$td/fvtest", $x, "raw"), "", 'read large file';
is length($x), 400000, 'scaled up to 400Kb value';

remove_td();
}
