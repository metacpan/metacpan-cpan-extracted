use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 12;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open shash_get shash_set shash_tidy
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);
my %ph;

ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000001";
ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000002";
shash_tidy($sh);
ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000001";
ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000002";

shash_set($sh, 0, "y");
$ph{0} = "y";
ok -f "$tmpdir/t0/&\"JBLMEgGm0000000000000001";
ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000002";

FILL: for(my $p = 7; ; $p += 2 ) {
	my $v = 5;
	for(my $j = 0; $j != 50000; $j++) {
		$v = ($v*21+$p) % 100000;
		my $x = "$v/$p";
		shash_set($sh, $v, $x);
		$ph{$v} = $x;
		shash_tidy($sh);
		last FILL if !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000001" ||
			-f "$tmpdir/t0/&\"JBLMEgGm0000000000000002";
	}
}

ok !-f "$tmpdir/t0/&\"JBLMEgGm0000000000000001";
ok -f "$tmpdir/t0/&\"JBLMEgGm0000000000000002";

my $v = 5;
for(my $j = 0; $j != 1000; $j++) {
	$v = ($v*61+19) % 100000;
	shash_set($sh, $v, "b".$v);
	$ph{$v} = "b".$v;
}

sub doru($) { defined($_[0]) ? $_[0] : "u" }

my $ok = 1;
for(my $v = 0; $v != 100000; $v++) {
	$ok &&= doru(shash_get($sh, $v)) eq doru($ph{$v});
}
ok $ok;

1;
