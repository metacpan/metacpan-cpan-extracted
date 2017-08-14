#!perl -T
# above line is required to enable taint mode

use warnings;
use strict;

BEGIN {
	if(eval { eval("1".substr($^X,0,0)) }) {
		require Test::More;
		Test::More::plan(skip_all =>
			"tainting not supported on this Perl");
	}
}

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 834;

my($pr, $pw);
pipe($pr, $pw) or die "pipe: $!";
close $pw;
my $tainted_undef = <$pr>;
close $pr;
sub tainted($) {
	if(defined $_[0]) {
		return $_[0].substr($^X, 0, 0);
	} else {
		return $tainted_undef;
	}
}
sub untainted($) {
	if(defined $_[0]) {
		$_[0] =~ /\A(.*)\z/s;
		return "$1";
	} else {
		return undef;
	}
}
sub is_tainted($) {
	no warnings "uninitialized";
	return !eval { eval("1;#".substr($_[0], 0, 0)); 1 };
}

ok !is_tainted("wibble");
is tainted("wibble"), "wibble";
ok is_tainted(tainted("wibble"));
is tainted(tainted("wibble")), "wibble";
ok is_tainted(tainted(tainted("wibble")));
is untainted("wibble"), "wibble";
ok !is_tainted(untainted("wibble"));
is untainted(tainted("wibble")), "wibble";
ok !is_tainted(untainted(tainted("wibble")));
ok !is_tainted(undef);
is tainted(undef), undef;
ok is_tainted(tainted(undef));
is tainted(tainted(undef)), undef;
ok is_tainted(tainted(tainted(undef)));
is untainted(undef), undef;
ok !is_tainted(untainted(undef));
is untainted(tainted(undef)), undef;
ok !is_tainted(untainted(tainted(undef)));

sub is_tnt(&$) {
	my $v = eval { $_[0]->() };
	is $@, "";
	ok is_tainted($v);
	is $v, $_[1];
}
sub is_unt(&$) {
	my $v = eval { $_[0]->() };
	is $@, "";
	ok !is_tainted($v);
	is $v, $_[1];
}
sub is_mbt(&$) {
	my $v = eval { $_[0]->() };
	is $@, "";
	is $v, $_[1];
}

BEGIN { $ENV{$_} = untainted($ENV{$_}) foreach keys %ENV; }

BEGIN { use_ok "Hash::SharedMem", qw(
	shash_referential_handle
	is_shash check_shash
	shash_open
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

is_unt { @{[ shash_referential_handle ]} } 1;
ok !is_tainted(eval { shash_referential_handle });
is_mbt { @{[ substr($^X, 0, 0), shash_referential_handle ]} } 2;

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");

is_unt { shash_occupied($sh) } !!0;
is_mbt { [ substr($^X, 0, 0), shash_occupied($sh) ]->[1] } !!0;
is_tnt { shash_count($sh) } 0;
is_tnt { [ substr($^X, 0, 0), shash_count($sh) ]->[1] } 0;
ok is_tainted(shash_size($sh));
ok is_tainted([ substr($^X, 0, 0), shash_size($sh) ]->[1]);
is_unt { shash_key_min($sh) } undef;
is_mbt { [ substr($^X, 0, 0), shash_key_min($sh) ]->[1] } undef;
is_unt { shash_key_max($sh) } undef;
is_mbt { [ substr($^X, 0, 0), shash_key_max($sh) ]->[1] } undef;
is_unt { join("", @{shash_keys_array($sh)}) } "";
is_mbt { [ substr($^X, 0, 0), join("", @{shash_keys_array($sh)}) ]->[1] } "";
is_unt { join("", sort keys %{shash_keys_hash($sh)}) } "";
is_mbt { [ substr($^X, 0, 0),
		join("", sort keys %{shash_keys_hash($sh)}) ]->[1] } "";
is_unt { join("", sort %{shash_group_get_hash($sh)}) } "";
is_mbt { [ substr($^X, 0, 0),
		join("", sort %{shash_group_get_hash($sh)}) ]->[1] } "";

shash_set($sh, "a$_", "b$_") foreach 0..19;
my $a20 = join("abcdef", 0..999);
my $a20len = length($a20);
shash_set($sh, "a20", $a20);

is_unt { is_shash($sh) } !!1;
is_mbt { [ substr($^X, 0, 0), is_shash($sh) ]->[1] } !!1;
is_unt { is_shash("wibble") } !!0;
is_mbt { [ substr($^X, 0, 0), is_shash("wibble") ]->[1] } !!0;
is_mbt { is_shash(tainted("wibble")) } !!0;
is_mbt { [ substr($^X, 0, 0), is_shash(tainted("wibble")) ]->[1] } !!0;

is_unt { check_shash($sh) } undef;
is_mbt { [ substr($^X, 0, 0), check_shash($sh) ]->[1] } undef;
is eval { scalar(check_shash("wibble")) }, undef;
like $@, qr/\Ahandle is not a shared hash handle /;
is eval { [ substr($^X, 0, 0), scalar(check_shash("wibble")) ] }, undef;
like $@, qr/\Ahandle is not a shared hash handle /;
is eval { check_shash(tainted("wibble")) }, undef;
like $@, qr/\Ahandle is not a shared hash handle /;
is eval { [ substr($^X, 0, 0), scalar(check_shash(tainted("wibble"))) ] },
	undef;
like $@, qr/\Ahandle is not a shared hash handle /;

$sh = undef;
foreach my $iomode ("", qw(r w rw c rc wc rwc)) {
	my $fn = "$tmpdir/t0";
	my $md = $iomode;
	$sh = eval { shash_open($fn, $md) };
	is $@, "";
	ok is_shash($sh);
	$md = tainted($md);
	$sh = eval { shash_open($fn, $md) };
	if($iomode =~ /[wc]/) {
		like $@, qr/\AInsecure dependency in shash_open /;
		is $sh, undef;
	} else {
		is $@, "";
		ok is_shash($sh);
	}
	$fn = tainted($fn);
	$sh = eval { shash_open($fn, $md) };
	if($iomode =~ /[wc]/) {
		like $@, qr/\AInsecure dependency in shash_open /;
		is $sh, undef;
	} else {
		is $@, "";
		ok is_shash($sh);
	}
	$md = untainted($md);
	$sh = eval { shash_open($fn, $md) };
	if($iomode =~ /[wc]/) {
		like $@, qr/\AInsecure dependency in shash_open /;
		is $sh, undef;
	} else {
		is $@, "";
		ok is_shash($sh);
	}
}
$sh = undef;

$sh = shash_open(tainted("$tmpdir/t0"), tainted("r"));
is_unt { shash_is_readable($sh) } !!1;
is_mbt { [ substr($^X, 0, 0), shash_is_readable($sh) ]->[1] } !!1;
is_unt { shash_is_writable($sh) } !!0;
is_mbt { [ substr($^X, 0, 0), shash_is_writable($sh) ]->[1] } !!0;
is_unt { shash_mode($sh) } "r";
is_mbt { [ substr($^X, 0, 0), shash_mode($sh) ]->[1] } "r";

is_tnt { join("", @{shash_keys_array($sh)}) }
	join("", sort map { "a$_" } 0..20);
is_tnt { [ substr($^X, 0, 0), join("", @{shash_keys_array($sh)}) ]->[1] }
	join("", sort map { "a$_" } 0..20);

is_unt { join("", sort keys %{shash_keys_hash($sh)}) }
	join("", sort map { "a$_" } 0..20);
is_mbt { [ substr($^X, 0, 0),
		join("", sort keys %{shash_keys_hash($sh)}) ]->[1] }
	join("", sort map { "a$_" } 0..20);

is_tnt { join("", sort %{shash_group_get_hash($sh)}) }
	join("", sort((map { ("a$_", "b$_") } 0..19), "a20", $a20));
is_tnt { [ substr($^X, 0, 0),
		join("", sort %{shash_group_get_hash($sh)}) ]->[1] }
	join("", sort((map { ("a$_", "b$_") } 0..19), "a20", $a20));

foreach(
	sub { shash_open("$tmpdir/t0", "r") },
	sub { shash_open("$tmpdir/t0", "rw") },
	sub { shash_open(tainted("$tmpdir/t0"), tainted("r")) },
) {
	$sh = $_->();
	is_unt { shash_exists($sh, "a0") } !!1;
	is_mbt { shash_exists($sh, tainted("a0")) } !!1;
	is_mbt { [ substr($^X, 0, 0), shash_exists($sh, "a0") ]->[1] } !!1;
	is_unt { shash_exists($sh, "a20") } !!1;
	is_mbt { shash_exists($sh, tainted("a20")) } !!1;
	is_mbt { [ substr($^X, 0, 0), shash_exists($sh, "a20") ]->[1] } !!1;
	is_unt { shash_exists($sh, "c0") } !!0;
	is_mbt { shash_exists($sh, tainted("c0")) } !!0;
	is_mbt { [ substr($^X, 0, 0), shash_exists($sh, "c0") ]->[1] } !!0;
	is_tnt { shash_length($sh, "a1") } 2;
	is_tnt { shash_length($sh, tainted("a1")) } 2;
	is_tnt { [ substr($^X, 0, 0), shash_length($sh, "a1") ]->[1] } 2;
	is_tnt { shash_length($sh, "a20") } $a20len;
	is_tnt { shash_length($sh, tainted("a20")) } $a20len;
	is_tnt { [ substr($^X, 0, 0), shash_length($sh, "a20") ]->[1] } $a20len;
	is_unt { shash_length($sh, "c1") } undef;
	is_mbt { shash_length($sh, tainted("c1")) } undef;
	is_mbt { [ substr($^X, 0, 0), shash_length($sh, "c1") ]->[1] } undef;
	is_tnt { shash_get($sh, "a2") } "b2";
	is_tnt { shash_get($sh, tainted("a2")) } "b2";
	is_tnt { [ substr($^X, 0, 0), shash_get($sh, "a2") ]->[1] } "b2";
	is_tnt { shash_get($sh, "a20") } $a20;
	is_tnt { shash_get($sh, tainted("a20")) } $a20;
	is_tnt { [ substr($^X, 0, 0), shash_get($sh, "a20") ]->[1] } $a20;
	is_unt { shash_get($sh, "c2") } undef;
	is_mbt { shash_get($sh, tainted("c2")) } undef;
	is_mbt { [ substr($^X, 0, 0), shash_get($sh, "c2") ]->[1] } undef;
}

$sh = shash_open("$tmpdir/t0", "rw");
is_unt { shash_set($sh, "d0", "e0a") } undef;
is_mbt { shash_set($sh, "d1", tainted("e1a")) } undef;
is_mbt { shash_set($sh, tainted("d2"), "e2a") } undef;
is_mbt { [ substr($^X, 0, 0), shash_set($sh, "d3", "e3a") ]->[1] } undef;
is shash_get($sh, "d$_"), "e${_}a" foreach 0..3;
is_unt { shash_set($sh, "d0", "e0b") } undef;
is_mbt { shash_set($sh, "d1", tainted("e1b")) } undef;
is_mbt { shash_set($sh, tainted("d2"), "e2b") } undef;
is_mbt { [ substr($^X, 0, 0), shash_set($sh, "d3", "e3b") ]->[1] } undef;
is shash_get($sh, "d$_"), "e${_}b" foreach 0..3;
is_unt { shash_set($sh, "d0", undef) } undef;
is_mbt { shash_set($sh, "d1", tainted(undef)) } undef;
is_mbt { shash_set($sh, tainted("d2"), undef) } undef;
is_mbt { [ substr($^X, 0, 0), shash_set($sh, "d3", undef) ]->[1] } undef;
is shash_get($sh, "d$_"), undef foreach 0..3;
is_unt { shash_set($sh, "d0", undef) } undef;
is_mbt { shash_set($sh, "d1", tainted(undef)) } undef;
is_mbt { shash_set($sh, tainted("d2"), undef) } undef;
is_mbt { [ substr($^X, 0, 0), shash_set($sh, "d3", undef) ]->[1] } undef;
is shash_get($sh, "d$_"), undef foreach 0..3;

is_unt { shash_gset($sh, "f0", "g0a") } undef;
is_mbt { shash_gset($sh, "f1", tainted("g1a")) } undef;
is_mbt { shash_gset($sh, tainted("f2"), "g2a") } undef;
is_mbt { [ substr($^X, 0, 0), shash_gset($sh, "f3", "g3a") ]->[1] } undef;
is shash_get($sh, "f$_"), "g${_}a" foreach 0..3;
is_tnt { shash_gset($sh, "f0", "g0b") } "g0a";
is_tnt { shash_gset($sh, "f1", tainted("g1b")) } "g1a";
is_tnt { shash_gset($sh, tainted("f2"), "g2b") } "g2a";
is_tnt { [ substr($^X, 0, 0), shash_gset($sh, "f3", "g3b") ]->[1] } "g3a";
is shash_get($sh, "f$_"), "g${_}b" foreach 0..3;
is_tnt { shash_gset($sh, "f0", undef) } "g0b";
is_tnt { shash_gset($sh, "f1", tainted(undef)) } "g1b";
is_tnt { shash_gset($sh, tainted("f2"), undef) } "g2b";
is_tnt { [ substr($^X, 0, 0), shash_gset($sh, "f3", undef) ]->[1] } "g3b";
is shash_get($sh, "f$_"), undef foreach 0..3;
is_unt { shash_gset($sh, "f0", undef) } undef;
is_mbt { shash_gset($sh, "f1", tainted(undef)) } undef;
is_mbt { shash_gset($sh, tainted("f2"), undef) } undef;
is_mbt { [ substr($^X, 0, 0), shash_gset($sh, "f3", undef) ]->[1] } undef;
is shash_get($sh, "f$_"), undef foreach 0..3;
is_unt { shash_gset($sh, "f0", "g0c$a20") } undef;
is_mbt { shash_gset($sh, "f1", tainted("g1c$a20")) } undef;
is_mbt { shash_gset($sh, tainted("f2"), "g2c$a20") } undef;
is_mbt { [ substr($^X, 0, 0), shash_gset($sh, "f3", "g3c$a20") ]->[1] } undef;
is shash_get($sh, "f$_"), "g${_}c$a20" foreach 0..3;
is_tnt { shash_gset($sh, "f0", "g0d$a20") } "g0c$a20";
is_tnt { shash_gset($sh, "f1", tainted("g1d$a20")) } "g1c$a20";
is_tnt { shash_gset($sh, tainted("f2"), "g2d$a20") } "g2c$a20";
is_tnt { [ substr($^X, 0, 0), shash_gset($sh, "f3", "g3d$a20") ]->[1] }
	"g3c$a20";
is shash_get($sh, "f$_"), "g${_}d$a20" foreach 0..3;
is_tnt { shash_gset($sh, "f0", undef) } "g0d$a20";
is_tnt { shash_gset($sh, "f1", tainted(undef)) } "g1d$a20";
is_tnt { shash_gset($sh, tainted("f2"), undef) } "g2d$a20";
is_tnt { [ substr($^X, 0, 0), shash_gset($sh, "f3", undef) ]->[1] } "g3d$a20";
is shash_get($sh, "f$_"), undef foreach 0..3;

is_unt { shash_cset($sh, "h0", undef, undef) } !!1;
is_mbt { shash_cset($sh, "h1", undef, tainted(undef)) } !!1;
is_mbt { shash_cset($sh, "h2", tainted(undef), undef) } !!1;
is_mbt { shash_cset($sh, tainted("h3"), undef, undef) } !!1;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", undef, undef) ]->[1] } !!1;
is shash_get($sh, "h$_"), undef foreach 0..4;
is_unt { shash_cset($sh, "h0", "i0a", undef) } !!0;
is_mbt { shash_cset($sh, "h1", "i1a", tainted(undef)) } !!0;
is_mbt { shash_cset($sh, "h2", tainted("i2a"), undef) } !!0;
is_mbt { shash_cset($sh, tainted("h3"), "i3a", undef) } !!0;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", "i4a", undef) ]->[1] } !!0;
is shash_get($sh, "h$_"), undef foreach 0..4;
is_unt { shash_cset($sh, "h0", "i0b", "i0c") } !!0;
is_mbt { shash_cset($sh, "h1", "i1b", tainted("i1c")) } !!0;
is_mbt { shash_cset($sh, "h2", tainted("i2b"), "i2c") } !!0;
is_mbt { shash_cset($sh, tainted("h3"), "i3b", "i3c") } !!0;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", "i4b", "i4c") ]->[1] } !!0;
is shash_get($sh, "h$_"), undef foreach 0..4;
is_unt { shash_cset($sh, "h0", undef, "i0d") } !!1;
is_mbt { shash_cset($sh, "h1", undef, tainted("i1d")) } !!1;
is_mbt { shash_cset($sh, "h2", tainted(undef), "i2d") } !!1;
is_mbt { shash_cset($sh, tainted("h3"), undef, "i3d") } !!1;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", undef, "i4d") ]->[1] } !!1;
is shash_get($sh, "h$_"), "i${_}d" foreach 0..4;
is_unt { shash_cset($sh, "h0", undef, undef) } !!0;
is_mbt { shash_cset($sh, "h1", undef, tainted(undef)) } !!0;
is_mbt { shash_cset($sh, "h2", tainted(undef), undef) } !!0;
is_mbt { shash_cset($sh, tainted("h3"), undef, undef) } !!0;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", undef, undef) ]->[1] } !!0;
is shash_get($sh, "h$_"), "i${_}d" foreach 0..4;
is_unt { shash_cset($sh, "h0", undef, "i0e") } !!0;
is_mbt { shash_cset($sh, "h1", undef, tainted("i1e")) } !!0;
is_mbt { shash_cset($sh, "h2", tainted(undef), "i2e") } !!0;
is_mbt { shash_cset($sh, tainted("h3"), undef, "i3e") } !!0;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", undef, "i4e") ]->[1] } !!0;
is shash_get($sh, "h$_"), "i${_}d" foreach 0..4;
is_unt { shash_cset($sh, "h0", "i0f", undef) } !!0;
is_mbt { shash_cset($sh, "h1", "i1f", tainted(undef)) } !!0;
is_mbt { shash_cset($sh, "h2", tainted("i2f"), undef) } !!0;
is_mbt { shash_cset($sh, tainted("h3"), "i3f", undef) } !!0;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", "i4f", undef) ]->[1] } !!0;
is shash_get($sh, "h$_"), "i${_}d" foreach 0..4;
is_unt { shash_cset($sh, "h0", "i0g", "i0h") } !!0;
is_mbt { shash_cset($sh, "h1", "i1g", tainted("i1h")) } !!0;
is_mbt { shash_cset($sh, "h2", tainted("i2g"), "i2h") } !!0;
is_mbt { shash_cset($sh, tainted("h3"), "i3g", "i3h") } !!0;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", "i4g", "i4h") ]->[1] } !!0;
is shash_get($sh, "h$_"), "i${_}d" foreach 0..4;
is_unt { shash_cset($sh, "h0", "i0d", "i0i") } !!1;
is_mbt { shash_cset($sh, "h1", "i1d", tainted("i1i")) } !!1;
is_mbt { shash_cset($sh, "h2", tainted("i2d"), "i2i") } !!1;
is_mbt { shash_cset($sh, tainted("h3"), "i3d", "i3i") } !!1;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", "i4d", "i4i") ]->[1] } !!1;
is shash_get($sh, "h$_"), "i${_}i" foreach 0..4;
is_unt { shash_cset($sh, "h0", "i0i", undef) } !!1;
is_mbt { shash_cset($sh, "h1", "i1i", tainted(undef)) } !!1;
is_mbt { shash_cset($sh, "h2", tainted("i2i"), undef) } !!1;
is_mbt { shash_cset($sh, tainted("h3"), "i3i", undef) } !!1;
is_mbt { [ substr($^X, 0, 0), shash_cset($sh, "h4", "i4i", undef) ]->[1] } !!1;
is shash_get($sh, "h$_"), undef foreach 0..4;

is_unt { shash_occupied($sh) } !!1;
is_mbt { [ substr($^X, 0, 0), shash_occupied($sh) ]->[1] } !!1;
is_tnt { shash_count($sh) } 21;
is_tnt { [ substr($^X, 0, 0), shash_count($sh) ]->[1] } 21;
ok is_tainted(shash_size($sh));
ok is_tainted([ substr($^X, 0, 0), shash_size($sh) ]->[1]);
is_tnt { shash_key_min($sh) } "a0";
is_tnt { [ substr($^X, 0, 0), shash_key_min($sh) ]->[1] } "a0";
is_tnt { shash_key_max($sh) } "a9";
is_tnt { [ substr($^X, 0, 0), shash_key_max($sh) ]->[1] } "a9";

is_unt { shash_key_ge($sh, "~") } undef;
is_mbt { [ substr($^X, 0, 0), shash_key_ge($sh, "~") ]->[1] } undef;
is_tnt { shash_key_ge($sh, "a3") } "a3";
is_tnt { [ substr($^X, 0, 0), shash_key_ge($sh, "a3") ]->[1] } "a3";
is_unt { shash_key_gt($sh, "~") } undef;
is_mbt { [ substr($^X, 0, 0), shash_key_gt($sh, "~") ]->[1] } undef;
is_tnt { shash_key_gt($sh, "a3") } "a4";
is_tnt { [ substr($^X, 0, 0), shash_key_gt($sh, "a3") ]->[1] } "a4";
is_unt { shash_key_le($sh, "-") } undef;
is_mbt { [ substr($^X, 0, 0), shash_key_le($sh, "-") ]->[1] } undef;
is_tnt { shash_key_le($sh, "a3") } "a3";
is_tnt { [ substr($^X, 0, 0), shash_key_le($sh, "a3") ]->[1] } "a3";
is_unt { shash_key_lt($sh, "-") } undef;
is_mbt { [ substr($^X, 0, 0), shash_key_lt($sh, "-") ]->[1] } undef;
is_tnt { shash_key_lt($sh, "a3") } "a20";
is_tnt { [ substr($^X, 0, 0), shash_key_lt($sh, "a3") ]->[1] } "a20";

is_unt { shash_idle($sh) } undef;
is_mbt { [ substr($^X, 0, 0), shash_idle($sh) ]->[1] } undef;

is_unt { shash_tidy($sh) } undef;
is_mbt { [ substr($^X, 0, 0), shash_tidy($sh) ]->[1] } undef;

my $h;
$h = eval { shash_tally_get($sh) };
is $@, "";
is ref($h), "HASH";
ok !grep { is_tainted($_) } keys %$h;
ok !grep { is_tainted($_) } values %$h;
ok !grep { !/\A[a-z_]+\z/ } keys %$h;
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;
$h = eval { [ substr($^X, 0, 0), shash_tally_get($sh) ]->[1] };
is $@, "";
is ref($h), "HASH";
ok !grep { !/\A[a-z_]+\z/ } keys %$h;
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;

is_unt { shash_tally_zero($sh) } undef;
is_mbt { [ substr($^X, 0, 0), shash_tally_zero($sh) ]->[1] } undef;

$h = eval { shash_tally_gzero($sh) };
is $@, "";
is ref($h), "HASH";
ok !grep { is_tainted($_) } keys %$h;
ok !grep { is_tainted($_) } values %$h;
ok !grep { !/\A[a-z_]+\z/ } keys %$h;
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;
$h = eval { [ substr($^X, 0, 0), shash_tally_gzero($sh) ]->[1] };
is $@, "";
is ref($h), "HASH";
ok !grep { !/\A[a-z_]+\z/ } keys %$h;
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;

is_unt { shash_is_snapshot($sh) } !!0;
is_mbt { [ substr($^X, 0, 0), shash_is_snapshot($sh) ]->[1] } !!0;
$sh = eval { [ substr($^X, 0, 0), shash_snapshot($sh) ]->[1] };
is $@, "";
ok is_shash($sh);
is_unt { shash_is_snapshot($sh) } !!1;
is_mbt { [ substr($^X, 0, 0), shash_is_snapshot($sh) ]->[1] } !!1;

is eval { shash_tidy($sh) }, undef;
like $@, qr#\Acan't\ tidy\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
is eval { [ substr($^X, 0, 0), shash_tidy($sh) ]->[1] }, undef;
like $@, qr#\Acan't\ tidy\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ handle\ is\ a\ snapshot\ #x;

1;
