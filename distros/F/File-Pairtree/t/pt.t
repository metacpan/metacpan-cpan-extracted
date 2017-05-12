use 5.006;
use Test::More qw( no_plan );
use strict;
use warnings;

use File::Pairtree;
my $script = 'pt';		# script we're testing

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

{
remake_td();
my $x;

$x = `$cmd -d $td mkid abc`;
is $?, 0, "status good on simple mkid";

like $x, qr|ab/c/|, "simple mkid";

use File::Namaste;
(undef, $x, undef) = File::Namaste::nam_get($td, 0);
is $x, "$td/0=pairtree_$File::Pairtree::VERSION",
	"namaste dirtype tag created";

$x = `$cmd -d $td lstree`;
is $?, 0, "status good on simple lstree";

like $x, qr|abc\n1 object\s*$|, "simple lstree with one node";

remake_td();		# re-make temp dir

$x = `$cmd -d dummy mktree $td prefix`;
is $?, 0, "status good on mktree with prefix and ignored -d";

$x = `$cmd -d dummy lstree`;
isnt $?, 0, "status non-zero on lstree as -d wasn't created";
chop $x;

like $x, qr|no such file or dir|, "complaint of non-existent tree";

$x = `$cmd -d $td mkid prefixabc prefixdef prefixhigk`;
like $x, qr|abc.*def.*higk.$|s, "make 3 nodes at once, prefix stripped";

$x = `$cmd --dummy lsid prefixdef`;
ok($? > 1, "status greater than 1 on bad option");

$x = `$cmd -d $td lsid prefixxyz prefixdef`;
is $?>>8, 1, "status 1 on lsid with at least one non-existent node";

$x = `$cmd -fd $td lsid def`;
is $?>>8, 2, "status 2 on lsid of existing node, no prefix, but --force)";

$x = `$cmd -d $td lsid def`;
is $?, 0, "status good on lsid of existing node, no prefix (no --force)";

$x = `$cmd -d $td lsid prefixdef`;
is $?, 0, "status good on lsid of existing node (with prefix)";

$x = `$cmd -d $td rmid prefixdef`;
is $?, 0, "status good on rmid of existing node (with prefix)";

$x = `$cmd -d $td rmid prefixdummy`;
is $?>>8, 1, "soft fail on rmid of non-existing node (with prefix)";

remake_td();		# re-make temp dir

$x = `$cmd -d $td mkid abc abcd abcde def ghi jkl`;
$x = `$cmd -d $td lstree`;
like $x, qr/6 objects/, 'make and list 6 object tree, overlapping ids';

my $R = 'pairtree_root';
filval("> $td/$R/ab/c/foo", "content");	# set up unencapsulated file error
mkdir "$td/$R/de/f/fo";			# set up shorty after morty error
mkdir "$td/$R/gh/i/ghi2";		# set up unencapsulated group error
# YYY!!! don't use `date ...` ever because on Windows it prompts user!
#`date > $td/$R/ab/c/foo`;	# set up unencapsulated file error
#`mkdir $td/$R/de/f/fo`;		# set up shorty after morty error
#`mkdir $td/$R/gh/i/ghi2`;	# set up unencapsulated group error

$x = `$cmd -d $td lstree`;
like $x, qr/split end/s, 'detected split end';

like $x, qr/forced path ending/s, 'detected shorty after morty';

like $x, qr/unencapsulated file/s, 'detected unencapsulated group';

#print "x=$x\n";

remove_td();
}

#done_testing();
