use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::Builder 0.03 ();
use Test::More 0.40 tests => 145;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open
	shash_exists shash_get shash_set shash_gset shash_cset
	shash_count
); }

my $tmpdir = tempdir(CLEANUP => 1);
my @sh;
$sh[0] = shash_open("$tmpdir/t0", "rwc");
ok $sh[0];
ok is_shash($sh[0]);
$sh[1] = shash_open("$tmpdir/t0", "rwc");
ok $sh[1];
ok is_shash($sh[1]);
$sh[2] = shash_open("$tmpdir/t0", "rw");
ok $sh[2];
ok is_shash($sh[2]);
$sh[3] = shash_open("$tmpdir/t0", "r");
ok $sh[3];
ok is_shash($sh[3]);

is shash_get($_, "a"), undef foreach @sh;
is shash_get($_, "b"), undef foreach @sh;
is shash_get($_, "c"), undef foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
shash_set($sh[0], "a", "aa");
is shash_get($_, "a"), "aa" foreach @sh;
is shash_get($_, "b"), undef foreach @sh;
is shash_get($_, "c"), undef foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
shash_set($sh[1], "b", "bb");
is shash_get($_, "a"), "aa" foreach @sh;
is shash_get($_, "b"), "bb" foreach @sh;
is shash_get($_, "c"), undef foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
shash_set($sh[2], "c", "cc");
is shash_get($_, "a"), "aa" foreach @sh;
is shash_get($_, "b"), "bb" foreach @sh;
is shash_get($_, "c"), "cc" foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
is shash_gset($sh[0], "a", "xx"), "aa";
is shash_get($_, "a"), "xx" foreach @sh;
is shash_get($_, "b"), "bb" foreach @sh;
is shash_get($_, "c"), "cc" foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
is shash_gset($sh[1], "b", "yy"), "bb";
is shash_get($_, "a"), "xx" foreach @sh;
is shash_get($_, "b"), "yy" foreach @sh;
is shash_get($_, "c"), "cc" foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
ok !shash_cset($sh[2], "c", "pp", "qq");
is shash_get($_, "a"), "xx" foreach @sh;
is shash_get($_, "b"), "yy" foreach @sh;
is shash_get($_, "c"), "cc" foreach @sh;
is shash_get($_, "d"), undef foreach @sh;
ok shash_cset($sh[2], "c", "cc", "zz");
is shash_get($_, "a"), "xx" foreach @sh;
is shash_get($_, "b"), "yy" foreach @sh;
is shash_get($_, "c"), "zz" foreach @sh;
is shash_get($_, "d"), undef foreach @sh;

@sh = ();
my($rp0, $wp0, $rp1, $wp1, $pid);
alarm 0;
$SIG{ALRM} = "DEFAULT";

pipe($rp0, $wp0) or die "pipe: $!";
pipe($rp1, $wp1) or die "pipe: $!";
alarm 1000;
$pid = fork();
defined $pid or die "fork: $!";
if($pid == 0) {
	Test::More->builder->no_ending(1);
	$File::Temp::KEEP_ALL = 1;
	close $wp0;
	close $rp1;
	my $sh = shash_open("$tmpdir/t0", "rw");
	close $wp1;
	scalar <$rp0>;
	my $x = 5;
	for(my $j = 0; $j != 50000; $j++) {
		$x = ($x*21+7) % 100000;
		shash_set($sh, sprintf("%05dx", $x), "a$x");
	}
	exit 0;
} else {
	close $rp0;
	close $wp1;
	my $sh = shash_open("$tmpdir/t0", "rw");
	close $wp0;
	scalar <$rp1>;
	my $y = 5;
	for(my $j = 0; $j != 50000; $j++) {
		$y = ($y*61+19) % 100000;
		shash_set($sh, sprintf("%05dy", $y), "b$y");
	}
	close $rp1;
	waitpid $pid, 0;
}
alarm 0;
{
	my %ph;
	my $x = 5;
	my $y = 5;
	for(my $j = 0; $j != 50000; $j++) {
		$x = ($x*21+7) % 100000;
		$y = ($y*61+19) % 100000;
		$ph{sprintf("%05dx", $x)} = "a$x";
		$ph{sprintf("%05dy", $y)} = "b$y";
	}
	my $sh = shash_open("$tmpdir/t0", "r");
	is shash_count($sh), 100003;
	is_deeply +{ map {
		(shash_exists($sh, $_) ? ($_ => shash_get($sh, $_)) : ())
	} map { $_."x", $_."y" } "00000".."99999" }, \%ph;
}

shash_set(shash_open("$tmpdir/t0", "rw"), "k", 0);
pipe($rp0, $wp0) or die "pipe: $!";
pipe($rp1, $wp1) or die "pipe: $!";
alarm 1000;
$pid = fork();
defined $pid or die "fork: $!";
if($pid == 0) {
	Test::More->builder->no_ending(1);
	$File::Temp::KEEP_ALL = 1;
	close $wp0;
	close $rp1;
	my $sh = shash_open("$tmpdir/t0", "rw");
	close $wp1;
	scalar <$rp0>;
	for(my $i = 0; $i != 100000; $i++) {
		my($ov, $nv);
		do {
			$ov = shash_get($sh, "k");
			$nv = $ov + 1;
		} until shash_cset($sh, "k", $ov, $nv);
	}
	exit 0;
} else {
	close $rp0;
	close $wp1;
	my $sh = shash_open("$tmpdir/t0", "rw");
	close $wp0;
	scalar <$rp1>;
	for(my $i = 0; $i != 100000; $i++) {
		my($ov, $nv);
		do {
			$ov = shash_get($sh, "k");
			$nv = $ov + 1;
		} until shash_cset($sh, "k", $ov, $nv);
	}
	close $rp1;
	waitpid $pid, 0;
}
alarm 0;
{
	my $sh = shash_open("$tmpdir/t0", "r");
	is shash_count($sh), 100004;
	is shash_get($sh, "k"), 200000;
}

1;
