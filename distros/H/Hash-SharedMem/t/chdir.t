use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 109;

BEGIN { use_ok "Hash::SharedMem", qw(is_shash shash_open shash_set shash_get); }

my $tmpdir = tempdir(CLEANUP => 1);

sub mkd($) {
	my($fn) = @_;
	mkdir $fn or die "can't create $fn: $!";
}

sub chd($) {
	my($fn) = @_;
	chdir $fn or die "can't chdir to $fn: $!";
}

sub test_chdir($$$$$) {
	my($absloc, $firstdir, $relloc, $seconddir, $aval) = @_;
	ok !-e $absloc;
	chd $firstdir;
	my $sh = shash_open($relloc, "rwce");
	ok $sh;
	ok is_shash($sh);
	chd $seconddir;
	shash_set($sh, "a", $aval);
	$sh = undef;
	chd "/";
	ok -d $absloc;
	ok -f "$absloc/iNmv0,m\$%3";
	ok -f "$absloc/&\"JBLMEgGm0000000000000001";
	$sh = shash_open($absloc, "r");
	ok $sh;
	ok is_shash($sh);
	is shash_get($sh, "a"), $aval;
}

mkd "$tmpdir/t0";
mkd "$tmpdir/t0/t1";
mkd "$tmpdir/t2";
mkd "$tmpdir/t2/t3";

test_chdir "$tmpdir/t2/t4", "$tmpdir/t0", "$tmpdir/t2/t4",
	"$tmpdir/t0/t1", "a4";
test_chdir "$tmpdir/t2/t5", "$tmpdir/t0", "../t2/t5",
	"$tmpdir/t0/t1", "a5";
test_chdir "$tmpdir/t2/t6", "$tmpdir/t0/t1", "$tmpdir/t2/t6",
	"$tmpdir/t0", "a6";
test_chdir "$tmpdir/t2/t7", "$tmpdir/t0/t1", "../../t2/t7",
	"$tmpdir/t0", "a7";
test_chdir "$tmpdir/t2/t3/t8", "$tmpdir/t0", "$tmpdir/t2/t3/t8",
	"$tmpdir/t0/t1", "a8";
test_chdir "$tmpdir/t2/t3/t9", "$tmpdir/t0", "../t2/t3/t9",
	"$tmpdir/t0/t1", "a9";
test_chdir "$tmpdir/t2/t3/t10", "$tmpdir/t0/t1", "$tmpdir/t2/t3/t10",
	"$tmpdir/t0", "a10";
test_chdir "$tmpdir/t2/t3/t11", "$tmpdir/t0/t1", "../../t2/t3/t11",
	"$tmpdir/t0", "a11";
test_chdir "$tmpdir/t2/t12", "$tmpdir", "$tmpdir/t2/t12",
	"$tmpdir/t0/t1", "a12";
test_chdir "$tmpdir/t2/t13", "$tmpdir", "t2/t13",
	"$tmpdir/t0/t1", "a13";
test_chdir "$tmpdir/t2/t14", "$tmpdir/t0/t1", "$tmpdir/t2/t14",
	"$tmpdir", "a14";
test_chdir "$tmpdir/t2/t15", "$tmpdir/t0/t1", "../../t2/t15",
	"$tmpdir", "a15";

1;
