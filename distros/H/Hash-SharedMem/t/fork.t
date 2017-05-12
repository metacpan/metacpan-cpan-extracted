use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::Builder 0.03 ();
use Test::More 0.40 tests => 4;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open
	shash_exists shash_get shash_set
	shash_count
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok is_shash($sh);
shash_set($sh, $_, $_) foreach "a0".."a3";

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
	is shash_count($sh), 100004;
	is_deeply +{ map {
		(shash_exists($sh, $_) ? ($_ => shash_get($sh, $_)) : ())
	} map { $_."x", $_."y" } "00000".."99999" }, \%ph;
}

1;
