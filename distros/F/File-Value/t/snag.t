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

{
remake_td();
my $x;

$x = `$cmd $td/foo`;
chop($x);
is $x, "$td/foo", "snag simple file";

ok(-f "$td/foo", "file is a file");

use Errno;
$x = `$cmd $td/bar/foo`;
chop($x);
# Avoid using english diagnostic for comparison (fails in other locales)
#like $x, qr/.o such file or directory/, "non-existent intermediate dir";
$! = 2;		# expect this error, but need locale-based string
my $z = "" . $! . "";	# hope this forces string context
like $x, qr/$z/, "non-existent intermediate dir";

$x = `$cmd $td/bar/`;
chop($x);
is $x, "$td/bar/", "snag simple directory";

ok(-d "$td/bar", "directory is a directory");

$x = `$cmd -f $td/bar`;
chop($x);
is $x, "$td/bar", "snag file, forcing replace of directory";

ok(-f "$td/bar", "replacement is a file");

$x = `$cmd --mknext $td/bar`;
chop($x);
is $x, "$td/bar1", "snag next version of unnumbered file";

$x = `$cmd --mknext $td/bar/`;
chop($x);
like $x, qr/different/, "snag next dir version of file version";

$x = `$cmd --mknext $td/bar500`;
chop($x);
is $x, "$td/bar002", "snag version 2 padded 3, low 500, pre-existing";

$x = `$cmd --mknext $td/zaf500`;
chop($x);
is $x, "$td/zaf500", "snag version 500 padded 3, low 500 of non-existing";

$x = `$cmd --mknext $td/zaf1`;
chop($x);
is $x, "$td/zaf501", "snag version 501 padded 1, low 1 of pre-existing";

$x = `$cmd --lshigh $td/zaf1`;
chop($x);
is $x, "$td/zaf501", "list high version";

$x = `$cmd --lslow $td/zaf1`;
chop($x);
is $x, "$td/zaf500", "list low version";

$x = `$cmd --mknextcopy $td/zaf1`;
chop($x);
like $x, qr/pre-existing file/,
	"snag --mknextcopy fails without pre-existing unnumbered version";

$x = `$cmd $td/daffy/`;			# snag an unnumbered directory
$x = `$cmd --mknext $td/daffy`;		# bump version number
$x = `$cmd --mknextcopy $td/daffy`;
like $x, qr/pre-existing.*file/,
	"snag --mknextcopy fails because pre-existing is a directory";

file_value(">$td/farley", 'barfoo');
file_value("<$td/farley", $x);
$x = `$cmd --mknext $td/farley`;

file_value("<$td/farley1", $x);
is $x, '', 'mknext (no copy) creates zero length file';

$x = `$cmd --mknextcopy $td/farley`;
is $x, "$td/farley2\n", 'mknextcopy creates next version';

file_value("<$td/farley2", $x);
is $x, 'barfoo', 'mknextcopy copied unnumbered version content';

remove_td();

}
