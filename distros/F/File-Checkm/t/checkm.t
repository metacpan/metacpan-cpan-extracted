use 5.006;
use Test::More qw( no_plan );
use strict;
use warnings;

my $script = 'checkm';		# script we're testing

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

$x = `$cmd -d $td --version`;
like $x, qr|^v\d+\.\d+\.\d+$|m, 'version number correctly formatted';

my $da = "abcdefg";
my $db = "hi\njk\r\nlm\r\n";	# odd line ends
# next contains Unicode smiley face
my $du = "opqrstu\r";
#my $du = "op" . chr(0x263a);	# 3 octets or 4 octets per 'length'?
filval(">$td/a", $da);
filval(">$td/b", $db);
filval(">$td/u", $du);

# XXXXX -d right now means nothing in these commands!
$x = `$cmd -d $td over $td/a $td/b $td/u`;
is $?, 0, "status good on simple checkm over";

#$x = `date > $td/a; cp $td/a $td/b; echo "foo" > $td/c`;
#$x = `$cmd -d $td over $td/a $td/b $td/c`;
#is $?, 0, "status good on simple checkm over";

like $x, qr|^#%checkm_stats.*26\.3\+0\.0\.0|m,
	"simple manifest of named files, no directories";

$x = `$cmd -d $td over $td`;
like $x, qr|^#%checkm_stats.*26\.3\+1\.0\.0|m,
	"simple manifest with oxum over one directory";

$x = `$cmd -d $td over $td/a $td/b $td/a $td/b`;
like $x, qr|^#%checkm_stats.*36\.4\+0\.0\.0|m,
	"manifest with oxum over two files, with repeats";

use File::Spec;
# We use this to do conditional testing depending on platform.
my $Win = grep(/Win32|OS2/i, @File::Spec::ISA);
unless ($Win) {
	my $qf = "fo|o";
	filval(">$td/$qf", "quirky fname to be encoded\n");
	$x = `$cmd -d $td over $td/`;
	like $x, qr|^$td/fo%7co|m, "manifest with encoded filename";
	unlink "$td/$qf";
}

mkdir "$td/d";
mkdir "$td/empty";


$x = `$cmd -d $td over $td`;
like $x, qr|^#%checkm_stats.*26\.3\+3\.0\.0|m,
	"with oxum over one directory";

# XXXX to do: add symlink and device testing
# XXXX to do: add file/path testing

remove_td();
exit;


$x = `$cmd -d $td lstree`;
is $?, 0, "status good on simple lstree";

like $x, qr|abc\n1 object$|, "simple lstree with one node";

remake_td();		# re-make temp dir

$x = `$cmd -d dummy mktree $td prefix`;
is $?, 0, "status good on mktree with prefix and ignored -d";

$x = `$cmd -d dummy lstree`;
isnt $?, 0, "status non-zero on lstree as -d wasn't created";
chop $x;

like $x, qr|no such file or dir|, "complaint of non-existent tree";

$x = `$cmd -d $td mknode prefixabc prefixdef prefixhigk`;
like $x, qr|abc.*def.*higk.$|s, "make 3 nodes at once, prefix stripped";

$x = `$cmd --dummy lsnode prefixdef`;
ok($? > 1, "status greater than 1 on bad option");

$x = `$cmd -d $td lsnode prefixxyz prefixdef`;
is $?>>8, 1, "status 1 on lsnode with at least one non-existent node";

$x = `$cmd -fd $td lsnode def`;
is $?>>8, 2, "status 2 on lsnode of existing node, no prefix, but --force)";

$x = `$cmd -d $td lsnode def`;
is $?, 0, "status good on lsnode of existing node, no prefix (no --force)";

$x = `$cmd -d $td lsnode prefixdef`;
is $?, 0, "status good on lsnode of existing node (with prefix)";

$x = `$cmd -d $td rmnode prefixdef`;
is $?, 0, "status good on rmnode of existing node (with prefix)";

$x = `$cmd -d $td rmnode prefixdummy`;
is $?>>8, 1, "soft fail on rmnode of non-existing node (with prefix)";

remake_td();		# re-make temp dir

$x = `$cmd -d $td mknode abc abcd abcde def ghi jkl`;
$x = `$cmd -d $td lstree`;
like $x, qr/6 objects/, 'make and list 6 object tree, overlapping ids';

my $R = 'pairtree_root';
`date > $td/$R/ab/c/foo`;	# set up unencapsulated file error
`mkdir $td/$R/de/f/fo`;		# set up shorty after morty error
`mkdir $td/$R/gh/i/ghi2`;	# set up unencapsulated group error

$x = `$cmd -d $td lstree`;
like $x, qr/split end/s, 'detected split end';

like $x, qr/forced path ending/s, 'detected shorty after morty';

like $x, qr/unencapsulated file/s, 'detected unencapsulated group';

#print "x=$x\n";

remove_td();
}

#done_testing();
