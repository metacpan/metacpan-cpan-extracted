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

use File::Namaste ':all';

{	# nam_elide tests

is nam_elide("abcdefghi"), "abcdefghi", 'simple no-op';

is nam_elide("abcdefghijklmnopqrstuvwxyz", "7m", ".."),
"ab..xyz", 'truncate explicit, middle';

is nam_elide("abcdefghijklmnopqrstuvwxyz"),
"abcdefghijklmn..", 'truncate implicit, end';

is nam_elide("abcdefghijklmnopqrstuvwxyz", 22),
"abcdefghijklmnopqrst..", 'truncate explicit, end';

is nam_elide("abcdefghijklmnopqrstuvwxyz", 22, ".."),
"abcdefghijklmnopqrst..", 'truncate explicit, end, explicit ellipsis';

is nam_elide("abcdefghijklmnopqrstuvwxyz", "22m"),
"abcdefghi...qrstuvwxyz", 'truncate explicit, middle';

is nam_elide("abcdefghijklmnopqrstuvwxyz", "22m", ".."),
"abcdefghij..qrstuvwxyz", 'truncate explicit, middle, explicit ellipsis';

is nam_elide("abcdefghijklmnopqrstuvwxyz", "22s"),
"..ghijklmnopqrstuvwxyz", 'truncate explicit, start';

is nam_elide("To be or not to be– that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune,
Or to take arms against a sea of troubles
And, by opposing, end them. To die, to sleep
No more – and by a sleep to say we end
The heartache and the thousand natural shocks
That flesh is heir to – ‘tis a consummation
Devoutly to be wished. To die, to sleep
To sleep, perchance to dream.", "22s"),
".. perchance to dream.", 'larger test with newlines';

# XXXX this +4% test isn't really implemented
is nam_elide("abcdefghijklmnopqrstuvwxyz", "22m+4%", "__"),
"abcdefghij__qrstuvwxyz", 'truncate explicit, middle, alt. ellipsis';

}
