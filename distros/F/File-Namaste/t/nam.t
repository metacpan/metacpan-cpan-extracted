use 5.006;
use Test::More qw( no_plan );

use strict;
use warnings;

my $script = "nam";		# script we're testing

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

{ 	# Namaste.pm tests

remake_td();

my $portable = undef;	# need undef (not 0) so $portable_default works
my $namy = "noid_0.6";
is nam_add($td, $portable, 0, "pairtree_0.3"), "", 'short namaste tag';
is nam_add($td, $portable, 0, $namy), "", 'second, repeating namaste tag';

my $namx = "Test/line:!
  Adventures of HuckleBerry Finn";

is nam_add($td, $portable, 1, $namx), "", 'longer stranger tag';

#   # fake tests to see what happens on Windows
#
#   use File::Spec::Functions;
#   use File::Glob ':glob';	# standard use of module, which we need
#				# as vanilla glob won't match whitespace
#   my @in = bsd_glob("$td/[0-9]=*");
#   like join(", ", @in), qr,td_nam,,
#   	'glob with / got some files, even on Windows';
#
#   #my @in = bsd_glob(catfile($td, '[0-9]=*'));
#   #like join(", ", @in), qr,td_nam/0=,, 'blob got some files';
#
#   my $x = opendir(my $dh, $td);
#   is 1, $x, "opendir on $td";
#
#   my @dots = readdir($dh);
#   closedir $dh;
#   like join(", ", map({catfile($td, $_)} @dots)), qr,td_nam/.*=Test,,
#   	'readdir on $td';

my @namtags = nam_get($td);
is scalar(@namtags), "9", 'got correct number of tags';

is $namtags[8], $namx, 'read back longer stranger tag';

is scalar(nam_get($td, "9")), "0", 'no matching tags';

@namtags = nam_get($td, "0");
is $namtags[2], $namy, 'read repeated namaste tag, which glob sorts first';

my ($num, $fname, $fvalue, @nums);
@namtags = nam_get($td);
while (defined($num = shift(@namtags))) {
	$fname = shift(@namtags);
	$fvalue = shift(@namtags);
	unlink($fname);
	push(@nums, $num);
}
is join(", ", @nums), "0, 0, 1", 'tag num sequence extracted from array';

is scalar(nam_get($td)), "0", 'tags all unlinked';

#XXX need lots more tests

remove_td();

}

{ 	# nam tests
# XXX need more -m tests
# xxx need -d tests
remake_td();
$cmd .= " -d $td ";

my $x;

$x = `$cmd rmall`;
is $x, "", 'nam rmall to clean out test dir';

$x = `$cmd set 0 foo`;
chop($x);
is $x, "", 'set of dir_type';

#print "nam_cmd=$cmd\n", `ls -t`;

$x = `$cmd get 0`;
chop($x);chop($x);
is $x, "foo", 'get of dir_type';

$x = `$cmd add 0 bar`;
chop($x);
is $x, "", 'set extra dir_type';

$x = `$cmd get 0`;
chop($x);chop($x);
is $x, "bar
foo", 'get of two dir_types';

$x = `$cmd set 0 zaf`;
chop($x);
is $x, "", 'clear old dir_types, replace with new';

$x = `$cmd get 0`;
chop($x);chop($x);
is $x, "zaf", 'get of one new dir_type';

$x = `$cmd set 1 "Mark Twain"`;
chop($x);
is $x, "", 'set of "who"';

$x = `$cmd get 1`;
chop($x);chop($x);
is $x, "Mark Twain", 'get of "who"';

$x = `$cmd set 2 "Adventures of Huckleberry Finn" 13m ___`;
chop($x);
is $x, "", 'set of long "what" value, with elision';

$x = `$cmd get 2`;
chop($x);chop($x);
is $x, 'Adventures of Huckleberry Finn', 'get of long "what" value';

$x = `$cmd add 8 "Adventures of Huckleberry Finn" 0`;
chop($x);
is $x, "", 'add of long "8" value, no elision';

$x = `$cmd -vm anvl get 8`;
chop($x);chop($x);
like $x, qr/8=Adventures of Huckleberry Finn/,
	'get of long "8" value, no elision';

$x = `$cmd -vm anvl get 2`;
chop($x);
like $x, '/2=Adven___ Finn/', 'get filename with "-m anvl" and -v comment';

$x = `$cmd --verbose --format xml get 2`;
chop($x);
like $x, '/2=Adven___ Finn-->/', 'get with long options and "xml" comment';

$x = `$cmd rmall`;
is $x, "", 'final nam rmall to clean out test dir';

use File::Spec;
# Default setting for tranformations is non-portable for Unix.
# We use this to do conditional testing depending on platform.
my $portable_default = grep(/Win32|OS2/i, @File::Spec::ISA);

$x = `$cmd set 4 "ark:/13030/123"`;
$x = `$cmd -v get 4`;
chop($x);chop($x);
if ($portable_default) {
	like $x, '/4=ark\.=13030=123/', 'simple tvalue (Win32)';
}
else {
	like $x, '/4=ark:=13030=123/', 'simple tvalue (Unix)';
}

$x = `$cmd --portable set 4 "ark:/13030/123"`;
$x = `$cmd get -v 4`;
chop($x);chop($x);
like $x, '/4=ark\.=13030=123/', 'tvalue with --portable';

$x = `$cmd --portable set 4 "ab c   d	'x*x/x:x<x>x?x|x\\x" 33`;
$x = `$cmd get -v 4`;
chop($x);chop($x);
like $x, '/4=a.b c d .x.x=x.x.x.x.x.x.x/', 'garbage tvalue with --portable';

$x = `$cmd elide "The question is this: why and/or how?" 24s "**"`;
chop($x);chop($x);
is $x, '** this: why and/or how?', 'raw interface to elide';

remove_td();

}
