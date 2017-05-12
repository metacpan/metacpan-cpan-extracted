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

{	# fiso tests

# 	$base		$last		Returns
#  1.	/		bar		/bar
#  2.	.		bar		bar
#  3.	foo		bar		foo/bar
#  4.	foo/		bar		foo/bar
#  5.	foo/bar		bar		foo/bar
#  6.	bar		bar		bar
#  7.	""		bar		bar
#  8.	foo		""		foo
#
# xxx was called prep_file in pt script
# FISO = FIle System Object
# dname = "down" name (full name with descender, suitable for -X tests)
# uname = "up" name (upper name without descender, still unique, suitable
#         for communicating with users)

# xxx may not port to Windows for the root cases
my $B = $File::Value::B;	# portability to Windows

is fiso_dname("${B}", "bar"), "${B}bar", "case 1";
	print "XXX case 1=", fiso_dname("${B}", "bar"), "\n";

is fiso_dname("${B}${B}", "bar"), "${B}bar", "case 1 extra ${B}";
is fiso_dname(".", "bar"), "bar", "case 2";
is fiso_dname(".${B}", "bar"), "bar", "case 2 with ${B}";
is fiso_dname("foo", "bar"), "foo${B}bar", "case 3";
is fiso_dname("foo${B}", "bar"), "foo${B}bar", "case 4";
is fiso_dname("foo${B}${B}", "bar"), "foo${B}bar", "case 4 extra ${B}";
is fiso_dname("foo${B}bar", "bar"), "foo${B}bar", "case 5";
is fiso_dname("foo${B}${B}bar", "bar"), "foo${B}bar", "case 5 extra ${B}";
is fiso_dname("bar", "bar"), "bar", "case 6";
is fiso_dname("${B}bar", "bar"), "${B}bar", "case 6 with initial ${B}";
is fiso_dname("", "bar"), "bar", "case 7";
is fiso_dname("foo", undef), "foo", "case 8";

is fiso_uname("${B}"), "${B}", "root alone";
is fiso_uname("${B}${B}"), "${B}", "root doubled";
is fiso_uname("foo${B}bar${B}"), "foo${B}", "dname was a dir";
is fiso_uname("foo${B}"), ".${B}", "dname was short dir";
is fiso_uname("foo${B}bar"), "foo${B}", "dir with descender";
is fiso_uname("foo"), ".${B}", "no dir";
is fiso_uname(""), "", "arg is an empty string";
is fiso_uname(undef), "", "arg is undefined";

}
