use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 678;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash check_shash shash_open
	shash_is_readable shash_is_writable shash_mode
	shash_exists shash_length shash_get
	shash_set shash_gset shash_cset
	shash_occupied shash_count shash_size
	shash_key_min shash_key_max
	shash_key_ge shash_key_gt shash_key_le shash_key_lt
	shash_keys_array shash_keys_hash
	shash_group_get_hash
	shash_snapshot shash_is_snapshot
	shash_idle shash_tidy
	shash_tally_get shash_tally_zero shash_tally_gzero
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);

my $magic;
my $fetched;
{
	package t::TiedScalar;
	sub TIESCALAR { bless({ value => $_[1] }, $_[0]) }
	sub FETCH { $fetched++; $_[0]->{value} }
}
sub tm1(&$;$) {
	untie $magic;
	$magic = $_[2];
	tie $magic, "t::TiedScalar", $_[1];
	$fetched = 0;
	$_[0]->();
	is $fetched, 1;
}

foreach my $cval ("a19", [], undef, $sh) {
	foreach my $rval ("a20", [], undef) {
		tm1 { ok !is_shash($magic) } $rval, $cval;
		tm1 {
			eval { check_shash($magic) };
			like $@, qr/\Ahandle is not a shared hash handle /;
		} $rval, $cval;
	}
	tm1 { ok is_shash($magic) } $sh, $cval;
	tm1 {
		eval { check_shash($magic) };
		is $@, "";
	} $sh, $cval;
}

tm1 {
	is eval { shash_is_readable($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_is_readable($magic), !!1 } $sh;
tm1 { is shash_is_readable($magic), !!1 } $sh, [];

tm1 {
	is eval { shash_is_writable($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_is_writable($magic), !!1 } $sh;
tm1 { is shash_is_writable($magic), !!1 } $sh, [];

tm1 {
	is eval { shash_mode($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_mode($magic), "rw" } $sh;
tm1 { is shash_mode($magic), "rw" } $sh, [];

tm1 { is shash_exists($sh, $magic), !!0 } "b0";
tm1 { is shash_length($sh, $magic), undef } "b0";
tm1 { is shash_get($sh, $magic), undef } "b0";
tm1 { is shash_exists($sh, $magic), !!0 } "b1", "b2";
tm1 { is shash_length($sh, $magic), undef } "b1", "b2";
tm1 { is shash_get($sh, $magic), undef } "b1", "b2";
tm1 { is shash_exists($sh, $magic), !!0 } "b3", [];
tm1 { is shash_length($sh, $magic), undef } "b3", [];
tm1 { is shash_get($sh, $magic), undef } "b3", [];
shash_set($sh, "b".$_, "a".$_) foreach 0..20;

tm1 {
	is eval { shash_exists($magic, "b30") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	is eval { shash_length($magic, "b30") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	is eval { shash_get($magic, "b30") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_exists($magic, "b30"), !!0 } $sh;
tm1 { is shash_length($magic, "b30"), undef } $sh;
tm1 { is shash_get($magic, "b30"), undef } $sh;
tm1 { is shash_exists($magic, "b30"), !!0 } $sh, [];
tm1 { is shash_length($magic, "b30"), undef } $sh, [];
tm1 { is shash_get($magic, "b30"), undef } $sh, [];
tm1 { is shash_exists($magic, "b30"), !!0 } $sh, "b8";
tm1 { is shash_length($magic, "b30"), undef } $sh, "b8";
tm1 { is shash_get($magic, "b30"), undef } $sh, "b8";
tm1 { is shash_exists($magic, "b9"), !!1 } $sh;
tm1 { is shash_length($magic, "b9"), 2 } $sh;
tm1 { is shash_get($magic, "b9"), "a9" } $sh;
tm1 { is shash_exists($magic, "b9"), !!1 } $sh, [];
tm1 { is shash_length($magic, "b9"), 2 } $sh, [];
tm1 { is shash_get($magic, "b9"), "a9" } $sh, [];
tm1 { is shash_exists($magic, "b9"), !!1 } $sh, "b8";
tm1 { is shash_length($magic, "b9"), 2 } $sh, "b8";
tm1 { is shash_get($magic, "b9"), "a9" } $sh, "b8";

tm1 {
	is eval { shash_exists($sh, $magic) }, undef;
	like $@, qr/\Akey is not an octet string at /;
} undef, "a21";
tm1 {
	is eval { shash_length($sh, $magic) }, undef;
	like $@, qr/\Akey is not an octet string at /;
} undef, "a21";
tm1 {
	is eval { shash_get($sh, $magic) }, undef;
	like $@, qr/\Akey is not an octet string at /;
} undef, "a21";
tm1 { is shash_exists($sh, $magic), !!0 } "b30";
tm1 { is shash_length($sh, $magic), undef } "b30";
tm1 { is shash_get($sh, $magic), undef } "b30";
tm1 { is shash_exists($sh, $magic), !!0 } "b31", "b32";
tm1 { is shash_length($sh, $magic), undef } "b31", "b32";
tm1 { is shash_get($sh, $magic), undef } "b31", "b32";
tm1 { is shash_exists($sh, $magic), !!0 } "b33", [];
tm1 { is shash_length($sh, $magic), undef } "b33", [];
tm1 { is shash_get($sh, $magic), undef } "b33", [];
tm1 { is shash_exists($sh, $magic), !!0 } "b34", "b5";
tm1 { is shash_length($sh, $magic), undef } "b34", "b5";
tm1 { is shash_get($sh, $magic), undef } "b34", "b5";
tm1 { is shash_exists($sh, $magic), !!1 } "b0";
tm1 { is shash_length($sh, $magic), 2 } "b0";
tm1 { is shash_get($sh, $magic), "a0" } "b0";
tm1 { is shash_exists($sh, $magic), !!1 } "b1", "b2";
tm1 { is shash_length($sh, $magic), 2 } "b1", "b2";
tm1 { is shash_get($sh, $magic), "a1" } "b1", "b2";
tm1 { is shash_exists($sh, $magic), !!1 } "b3", [];
tm1 { is shash_length($sh, $magic), 2 } "b3", [];
tm1 { is shash_get($sh, $magic), "a3" } "b3", [];
tm1 { is shash_exists($sh, $magic), !!1 } "b4", "a5";
tm1 { is shash_length($sh, $magic), 2 } "b4", "a5";
tm1 { is shash_get($sh, $magic), "a4" } "b4", "a5";
tm1 { is shash_exists($sh, $magic), !!0 } "a6", "b7";
tm1 { is shash_length($sh, $magic), undef } "a6", "b7";
tm1 { is shash_get($sh, $magic), undef } "a6", "b7";

tm1 {
	is eval { shash_occupied($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_occupied($magic), !!1 } $sh;
tm1 { is shash_occupied($magic), !!1 } $sh, [];

tm1 {
	is eval { shash_count($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_count($magic), 21 } $sh;
tm1 { is shash_count($magic), 21 } $sh, [];

tm1 {
	is eval { shash_size($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { like shash_size($magic), qr/\A[0-9]+\z/ } $sh;
tm1 { like shash_size($magic), qr/\A[0-9]+\z/ } $sh, [];

tm1 {
	is eval { shash_key_min($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_key_min($magic), "b0" } $sh;
tm1 { is shash_key_min($magic), "b0" } $sh, [];

tm1 {
	is eval { shash_key_max($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_key_max($magic), "b9" } $sh;
tm1 { is shash_key_max($magic), "b9" } $sh, [];

tm1 {
	is eval { shash_key_ge($magic, "b3") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_key_ge($magic, "b3"), "b3" } $sh;
tm1 { is shash_key_ge($magic, "b3"), "b3" } $sh, [];
tm1 { is shash_key_ge($sh, $magic), "b3" } "b3";
tm1 { is shash_key_ge($sh, $magic), "b3" } "b3", "b7";
tm1 { is shash_key_ge($sh, $magic), "b3" } "b3", [];

tm1 {
	is eval { shash_key_gt($magic, "b3") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_key_gt($magic, "b3"), "b4" } $sh;
tm1 { is shash_key_gt($magic, "b3"), "b4" } $sh, [];
tm1 { is shash_key_gt($sh, $magic), "b4" } "b3";
tm1 { is shash_key_gt($sh, $magic), "b4" } "b3", "b7";
tm1 { is shash_key_gt($sh, $magic), "b4" } "b3", [];

tm1 {
	is eval { shash_key_le($magic, "b3") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_key_le($magic, "b3"), "b3" } $sh;
tm1 { is shash_key_le($magic, "b3"), "b3" } $sh, [];
tm1 { is shash_key_le($sh, $magic), "b3" } "b3";
tm1 { is shash_key_le($sh, $magic), "b3" } "b3", "b7";
tm1 { is shash_key_le($sh, $magic), "b3" } "b3", [];

tm1 {
	is eval { shash_key_lt($magic, "b3") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_key_lt($magic, "b3"), "b20" } $sh;
tm1 { is shash_key_lt($magic, "b3"), "b20" } $sh, [];
tm1 { is shash_key_lt($sh, $magic), "b20" } "b3";
tm1 { is shash_key_lt($sh, $magic), "b20" } "b3", "b7";
tm1 { is shash_key_lt($sh, $magic), "b20" } "b3", [];

tm1 {
	is eval { shash_keys_array($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is_deeply shash_keys_array($magic), [sort map { "b$_" } 0..20] } $sh;
tm1 { is_deeply shash_keys_array($magic), [sort map { "b$_" } 0..20] } $sh, [];

tm1 {
	is eval { shash_keys_hash($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	is_deeply shash_keys_hash($magic), { map { ("b$_" => undef) } 0..20 };
} $sh;
tm1 {
	is_deeply shash_keys_hash($magic), { map { ("b$_" => undef) } 0..20 };
} $sh, [];

tm1 {
	is eval { shash_group_get_hash($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	is_deeply shash_group_get_hash($magic),
		{ map { ("b$_" => "a$_") } 0..20 };
} $sh;
tm1 {
	is_deeply shash_group_get_hash($magic),
		{ map { ("b$_" => "a$_") } 0..20 };
} $sh, [];

tm1 {
	is eval { shash_set($magic, "c3", "d3a") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { shash_set($magic, "c2", "d2a") } $sh;
is shash_get($sh, "c2"), "d2a";
tm1 { shash_set($magic, "c2", "d2b") } $sh, [];
is shash_get($sh, "c2"), "d2b";
tm1 { shash_set($magic, "c2", undef) } $sh, "a16";
is shash_get($sh, "c2"), undef;
tm1 { shash_set($magic, "c2", undef) } $sh;
is shash_get($sh, "c2"), undef;

tm1 {
	eval { shash_set($sh, $magic, "a23") };
	like $@, qr/\Akey is not an octet string at /;
} undef, "a22";
tm1 { shash_set($sh, $magic, "d0a") } "c0";
is shash_get($sh, "c0"), "d0a";
tm1 { shash_set($sh, $magic, "d0b") } "c0", "a8";
is shash_get($sh, "c0"), "d0b";
tm1 { shash_set($sh, $magic, undef) } "c0", [];
is shash_get($sh, "c0"), undef;
tm1 { shash_set($sh, $magic, undef) } "c0";
is shash_get($sh, "c0"), undef;

tm1 {
	eval { shash_set($sh, "a30", $magic) };
	like $@, qr/\Anew value is neither an octet string nor undef at /;
} [], "a29";
tm1 { shash_set($sh, "c1", $magic) } "d1a";
is shash_get($sh, "c1"), "d1a";
tm1 { shash_set($sh, "c1", $magic) } "d1b", [];
is shash_get($sh, "c1"), "d1b";
tm1 { shash_set($sh, "c1", $magic) } "d1c", "d1d";
is shash_get($sh, "c1"), "d1c";
tm1 { shash_set($sh, "c1", $magic) } undef, "d1e";
is shash_get($sh, "c1"), undef;
tm1 { shash_set($sh, "c1", $magic) } undef, [];
is shash_get($sh, "c1"), undef;

tm1 {
	is eval { shash_gset($magic, "e3", "f3a") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_gset($magic, "e2", "f2a"), undef } $sh;
is shash_get($sh, "e2"), "f2a";
tm1 { is shash_gset($magic, "e2", "f2b"), "f2a" } $sh, [];
is shash_get($sh, "e2"), "f2b";
tm1 { is shash_gset($magic, "e2", undef), "f2b" } $sh, "a17";
is shash_get($sh, "e2"), undef;
tm1 { is shash_gset($magic, "e2", undef), undef } $sh;
is shash_get($sh, "e2"), undef;

tm1 {
	is eval { shash_gset($sh, $magic, "a25") }, undef;
	like $@, qr/\Akey is not an octet string at /;
} undef, "a24";
tm1 { is shash_gset($sh, $magic, "f0a"), undef } "e0";
is shash_get($sh, "e0"), "f0a";
tm1 { is shash_gset($sh, $magic, "f0b"), "f0a" } "e0", "a9";
is shash_get($sh, "e0"), "f0b";
tm1 { is shash_gset($sh, $magic, undef), "f0b" } "e0", [];
is shash_get($sh, "e0"), undef;
tm1 { is shash_gset($sh, $magic, undef), undef } "e0";
is shash_get($sh, "e0"), undef;

tm1 {
	is eval { shash_gset($sh, "a32", $magic) }, undef;
	like $@, qr/\Anew value is neither an octet string nor undef at /;
} [], "a31";
tm1 { is shash_gset($sh, "e1", $magic), undef } "f1a";
is shash_get($sh, "e1"), "f1a";
tm1 { is shash_gset($sh, "e1", $magic), "f1a" } "f1b";
is shash_get($sh, "e1"), "f1b";
tm1 { is shash_gset($sh, "e1", $magic), "f1b" } undef, [];
is shash_get($sh, "e1"), undef;
tm1 { is shash_gset($sh, "e1", $magic), undef } undef, "f1c";
is shash_get($sh, "e1"), undef;

tm1 {
	is eval { shash_cset($magic, "g4", "h4a", "h4b") }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_cset($magic, "g3", undef, undef), !!1 } $sh;
is shash_get($sh, "g3"), undef;
tm1 { is shash_cset($magic, "g3", "h3a", undef), !!0 } $sh;
is shash_get($sh, "g3"), undef;
tm1 { is shash_cset($magic, "g3", "h3b", "h3c"), !!0 } $sh;
is shash_get($sh, "g3"), undef;
tm1 { is shash_cset($magic, "g3", undef, "h3d"), !!1 } $sh, [];
is shash_get($sh, "g3"), "h3d";
tm1 { is shash_cset($magic, "g3", undef, undef), !!0 } $sh;
is shash_get($sh, "g3"), "h3d";
tm1 { is shash_cset($magic, "g3", undef, "h3e"), !!0 } $sh;
is shash_get($sh, "g3"), "h3d";
tm1 { is shash_cset($magic, "g3", "h3f", undef), !!0 } $sh;
is shash_get($sh, "g3"), "h3d";
tm1 { is shash_cset($magic, "g3", "h3g", "h3h"), !!0 } $sh;
is shash_get($sh, "g3"), "h3d";
tm1 { is shash_cset($magic, "g3", "h3d", "h3i"), !!1 } $sh, "a18";
is shash_get($sh, "g3"), "h3i";
tm1 { is shash_cset($magic, "g3", "h3i", undef), !!1 } $sh;
is shash_get($sh, "g3"), undef;

tm1 {
	is eval { shash_cset($sh, $magic, "a27", "a28") }, undef;
	like $@, qr/\Akey is not an octet string at /;
} undef, "a26";
tm1 { is shash_cset($sh, $magic, undef, undef), !!1 } "g0";
is shash_get($sh, "g0"), undef;
tm1 { is shash_cset($sh, $magic, "h0a", undef), !!0 } "g0";
is shash_get($sh, "g0"), undef;
tm1 { is shash_cset($sh, $magic, "h0b", "h0c"), !!0 } "g0";
is shash_get($sh, "g0"), undef;
tm1 { is shash_cset($sh, $magic, undef, "h0d"), !!1 } "g0";
is shash_get($sh, "g0"), "h0d";
tm1 { is shash_cset($sh, $magic, undef, undef), !!0 } "g0", "a9";
is shash_get($sh, "g0"), "h0d";
tm1 { is shash_cset($sh, $magic, undef, "h0e"), !!0 } "g0";
is shash_get($sh, "g0"), "h0d";
tm1 { is shash_cset($sh, $magic, "h0f", undef), !!0 } "g0";
is shash_get($sh, "g0"), "h0d";
tm1 { is shash_cset($sh, $magic, "h0g", "h0h"), !!0 } "g0";
is shash_get($sh, "g0"), "h0d";
tm1 { is shash_cset($sh, $magic, "h0d", "h0i"), !!1 } "g0";
is shash_get($sh, "g0"), "h0i";
tm1 { is shash_cset($sh, $magic, "h0i", undef), !!1 } "g0";
is shash_get($sh, "g0"), undef;

tm1 {
	is eval { shash_cset($sh, "a34", $magic, "a35") }, undef;
	like $@, qr/\Acheck value is neither an octet string nor undef at /;
} [], "a33";
tm1 { is shash_cset($sh, "g1", $magic, undef), !!1 } undef, "a10";
is shash_get($sh, "g1"), undef;
tm1 { is shash_cset($sh, "g1", $magic, undef), !!0 } "h1a";
is shash_get($sh, "g1"), undef;
tm1 { is shash_cset($sh, "g1", $magic, "h1c"), !!0 } "h1b", [];
is shash_get($sh, "g1"), undef;
tm1 { is shash_cset($sh, "g1", $magic, "h1d"), !!1 } undef, [];
is shash_get($sh, "g1"), "h1d";
tm1 { is shash_cset($sh, "g1", $magic, undef), !!0 } undef, "a11";
is shash_get($sh, "g1"), "h1d";
tm1 { is shash_cset($sh, "g1", $magic, "h1e"), !!0 } undef, "a12";
is shash_get($sh, "g1"), "h1d";
tm1 { is shash_cset($sh, "g1", $magic, undef), !!0 } "h1f";
is shash_get($sh, "g1"), "h1d";
tm1 { is shash_cset($sh, "g1", $magic, "h1h"), !!0 } "h1g";
is shash_get($sh, "g1"), "h1d";
tm1 { is shash_cset($sh, "g1", $magic, "h1i"), !!1 } "h1d", [];
is shash_get($sh, "g1"), "h1i";
tm1 { is shash_cset($sh, "g1", $magic, undef), !!1 } "h1i";
is shash_get($sh, "g1"), undef;

tm1 {
	is eval { shash_cset($sh, "a37", "a38", $magic) }, undef;
	like $@, qr/\Anew value is neither an octet string nor undef at /;
} [], "a36";
tm1 { is shash_cset($sh, "g2", undef, $magic), !!1 } undef, "a13";
is shash_get($sh, "g2"), undef;
tm1 { is shash_cset($sh, "g2", "h2a", $magic), !!0 } undef, [];
is shash_get($sh, "g2"), undef;
tm1 { is shash_cset($sh, "g2", "h2b", $magic), !!0 } "h2c";
is shash_get($sh, "g2"), undef;
tm1 { is shash_cset($sh, "g2", undef, $magic), !!1 } "h2d", [];
is shash_get($sh, "g2"), "h2d";
tm1 { is shash_cset($sh, "g2", undef, $magic), !!0 } undef, "a14";
is shash_get($sh, "g2"), "h2d";
tm1 { is shash_cset($sh, "g2", undef, $magic), !!0 } "h2e", [];
is shash_get($sh, "g2"), "h2d";
tm1 { is shash_cset($sh, "g2", "h2f", $magic), !!0 } undef, [];
is shash_get($sh, "g2"), "h2d";
tm1 { is shash_cset($sh, "g2", "h2g", $magic), !!0 } "h2h";
is shash_get($sh, "g2"), "h2d";
tm1 { is shash_cset($sh, "g2", "h2d", $magic), !!1 } "h2i";
is shash_get($sh, "g2"), "h2i";
tm1 { is shash_cset($sh, "g2", "h2i", $magic), !!1 } undef, "a15";
is shash_get($sh, "g2"), undef;

my $sn = shash_snapshot($sh);
ok $sn;
ok is_shash($sn);

tm1 {
	is eval { shash_snapshot($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	my $t = shash_snapshot($magic);
	ok is_shash($t);
	ok shash_is_snapshot($t);
} $sh;
tm1 {
	my $t = shash_snapshot($magic);
	ok is_shash($t);
	ok shash_is_snapshot($t);
} $sn;

tm1 {
	is eval { shash_is_snapshot($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { is shash_is_snapshot($magic), !!0 } $sh;
tm1 { is shash_is_snapshot($magic), !!0 } $sh, [];
tm1 { is shash_is_snapshot($magic), !!1 } $sn;
tm1 { is shash_is_snapshot($magic), !!1 } $sn, [];

tm1 {
	is eval { shash_idle($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { shash_idle($magic) } $sh;

tm1 {
	is eval { shash_tidy($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 { shash_tidy($magic) } $sh;

tm1 {
	is eval { shash_tally_get($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	my $h = shash_tally_get($magic);
	is ref($h), "HASH";
	ok !grep { !/\A[a-z_]+\z/ } keys %$h;
	ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;
} $sh;

tm1 {
	is eval { shash_tally_zero($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	my $v = shash_tally_zero($magic);
	is $v, undef;
} $sh;

tm1 {
	is eval { shash_tally_gzero($magic) }, undef;
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	my $h = shash_tally_gzero($magic);
	is ref($h), "HASH";
	ok !grep { !/\A[a-z_]+\z/ } keys %$h;
	ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;
} $sh;

require_ok "Hash::SharedMem::Handle";

tm1 {
	my %h;
	eval { tie %h, "Hash::SharedMem::Handle", $magic };
	like $@, qr/\Ahandle is not a shared hash handle /;
} [], $sh;
tm1 {
	my %h;
	tie %h, "Hash::SharedMem::Handle", $magic;
	my $h = tied(%h);
	ok is_shash($h);
	$h{i0} = "j0";
	is $h{i1}, undef;
	is $h{i0}, "j0";
} $sh;

tm1 {
	my $s = shash_open($magic, "r");
	ok is_shash($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k0", "l0") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "$tmpdir/t0", "$tmpdir/t1";
tm1 {
	my $s = shash_open($magic, "r");
	ok is_shash($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k0", "l0") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "$tmpdir/t0";
tm1 {
	my $s = shash_open($magic, "wc");
	ok is_shash($s);
	eval { shash_set($s, "k3", "l3") };
	is $@, "";
	is eval { shash_get($s, "b11") }, undef;
	like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t2:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
} "$tmpdir/t2", "$tmpdir/t3";
tm1 {
	my $s = shash_open($magic, "wc");
	ok is_shash($s);
	eval { shash_set($s, "k3", "l3") };
	is $@, "";
	is eval { shash_get($s, "b11") }, undef;
	like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t8:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
} "$tmpdir/t8";

tm1 {
	my $s = shash_open("$tmpdir/t0", $magic);
	ok is_shash($s);
	ok shash_is_readable($s);
	ok !shash_is_writable($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k6", "l6") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "r", "w";
tm1 {
	my $s = shash_open("$tmpdir/t0", $magic);
	ok is_shash($s);
	ok shash_is_readable($s);
	ok !shash_is_writable($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k6", "l6") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "r";

tm1 {
	my $s = Hash::SharedMem::Handle->open($magic, "r");
	ok is_shash($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k1", "l1") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "$tmpdir/t0", "$tmpdir/t1";
tm1 {
	my $s = Hash::SharedMem::Handle->open($magic, "r");
	ok is_shash($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k1", "l1") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "$tmpdir/t0";
tm1 {
	my $s = Hash::SharedMem::Handle->open($magic, "wc");
	ok is_shash($s);
	eval { shash_set($s, "k4", "l4") };
	is $@, "";
	is eval { shash_get($s, "b11") }, undef;
	like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t4:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
} "$tmpdir/t4", "$tmpdir/t5";
tm1 {
	my $s = Hash::SharedMem::Handle->open($magic, "wc");
	ok is_shash($s);
	eval { shash_set($s, "k4", "l4") };
	is $@, "";
	is eval { shash_get($s, "b11") }, undef;
	like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t9:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
} "$tmpdir/t9";

tm1 {
	my $s = Hash::SharedMem::Handle->open("$tmpdir/t0", $magic);
	ok is_shash($s);
	ok shash_is_readable($s);
	ok !shash_is_writable($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k7", "l7") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "r", "w";
tm1 {
	my $s = Hash::SharedMem::Handle->open("$tmpdir/t0", $magic);
	ok is_shash($s);
	ok shash_is_readable($s);
	ok !shash_is_writable($s);
	is shash_get($s, "b11"), "a11";
	eval { shash_set($s, "k7", "l7") };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "r";

tm1 {
	my %s;
	tie %s, "Hash::SharedMem::Handle", $magic, "r";
	ok is_shash(tied(%s));
	is $s{b11}, "a11";
	eval { $s{k2} = "l2" };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "$tmpdir/t0", "$tmpdir/t1";
tm1 {
	my %s;
	tie %s, "Hash::SharedMem::Handle", $magic, "r";
	ok is_shash(tied(%s));
	is $s{b11}, "a11";
	eval { $s{k2} = "l2" };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "$tmpdir/t0";
tm1 {
	my %s;
	tie %s, "Hash::SharedMem::Handle", $magic, "wc";
	ok is_shash(tied(%s));
	eval { $s{k5} = "l5" };
	is $@, "";
	is eval { $s{b11} }, undef;
	like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t6:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
} "$tmpdir/t6", "$tmpdir/t7";
tm1 {
	my %s;
	tie %s, "Hash::SharedMem::Handle", $magic, "wc";
	ok is_shash(tied(%s));
	eval { $s{k5} = "l5" };
	is $@, "";
	is eval { $s{b11} }, undef;
	like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t10:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
} "$tmpdir/t10";

tm1 {
	my %s;
	tie %s, "Hash::SharedMem::Handle", "$tmpdir/t0", $magic;
	ok is_shash(tied(%s));
	ok shash_is_readable(tied(%s));
	ok !shash_is_writable(tied(%s));
	is $s{b11}, "a11";
	eval { $s{k8} = "l8" };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "r", "w";
tm1 {
	my %s;
	tie %s, "Hash::SharedMem::Handle", "$tmpdir/t0", $magic;
	ok is_shash(tied(%s));
	ok shash_is_readable(tied(%s));
	ok !shash_is_writable(tied(%s));
	is $s{b11}, "a11";
	eval { $s{k8} = "l8" };
	like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
} "r";

1;
