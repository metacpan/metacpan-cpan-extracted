use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 388;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash check_shash
	shash_open
	shash_is_readable shash_is_writable shash_mode
	shash_exists shash_getd shash_length shash_get
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

is scalar(is_shash("foo")), !!0;
is_deeply [is_shash("foo")], [!!0];
eval { check_shash("foo") };
like $@, qr/\Ahandle is not a shared hash handle /;

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
is scalar(is_shash($sh)), !!1;
is_deeply [is_shash($sh)], [!!1];
eval { check_shash($sh) };
is $@, "";
is scalar(check_shash($sh)), undef;
is_deeply [check_shash($sh)], [];
is scalar(shash_is_snapshot($sh)), !!0;
is_deeply [shash_is_snapshot($sh)], [!!0];
is scalar(shash_is_readable($sh)), !!1;
is_deeply [shash_is_readable($sh)], [!!1];
is scalar(shash_is_writable($sh)), !!1;
is_deeply [shash_is_writable($sh)], [!!1];
is scalar(shash_mode($sh)), "rw";
is_deeply [shash_mode($sh)], ["rw"];
eval { ${\shash_mode($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;

is scalar(shash_exists($sh, "a100")), !!0;
is_deeply [shash_exists($sh, "a100")], [!!0];
is scalar(shash_getd($sh, "a100")), !!0;
is_deeply [shash_getd($sh, "a100")], [!!0];
is scalar(shash_length($sh, "a100")), undef;
is_deeply [shash_length($sh, "a100")], [undef];
is scalar(shash_get($sh, "a100")), undef;
is_deeply [shash_get($sh, "a100")], [undef];
is scalar(shash_occupied($sh)), !!0;
is_deeply [shash_occupied($sh)], [!!0];
is scalar(shash_count($sh)), 0;
is_deeply [shash_count($sh)], [0];
eval { ${\shash_count($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
like scalar(shash_size($sh)), qr/\A[0-9]+\z/;
like join(",", shash_size($sh)), qr/\A[0-9]+\z/;
eval { ${\shash_size($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is scalar(shash_key_min($sh)), undef;
is_deeply [shash_key_min($sh)], [undef];
is scalar(shash_key_max($sh)), undef;
is_deeply [shash_key_max($sh)], [undef];
is scalar(shash_key_ge($sh, "a110")), undef;
is_deeply [shash_key_ge($sh, "a110")], [undef];
is scalar(shash_key_gt($sh, "a110")), undef;
is_deeply [shash_key_gt($sh, "a110")], [undef];
is scalar(shash_key_le($sh, "a110")), undef;
is_deeply [shash_key_le($sh, "a110")], [undef];
is scalar(shash_key_lt($sh, "a110")), undef;
is_deeply [shash_key_lt($sh, "a110")], [undef];
is_deeply scalar(shash_keys_array($sh)), [];
is_deeply [shash_keys_array($sh)], [[]];
eval { ${\shash_keys_array($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is_deeply scalar(shash_keys_hash($sh)), {};
is_deeply [shash_keys_hash($sh)], [{}];
eval { ${\shash_keys_hash($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is_deeply scalar(shash_group_get_hash($sh)), {};
is_deeply [shash_group_get_hash($sh)], [{}];
eval { ${\shash_group_get_hash($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;

shash_set($sh, "a110", "b110");
is scalar(shash_set($sh, "a100", "b100")), undef;
is_deeply [shash_set($sh, "a120", "b120")], [];

is scalar(shash_exists($sh, "a100")), !!1;
is_deeply [shash_exists($sh, "a100")], [!!1];
is scalar(shash_getd($sh, "a100")), !!1;
is_deeply [shash_getd($sh, "a100")], [!!1];
is scalar(shash_length($sh, "a100")), 4;
is_deeply [shash_length($sh, "a100")], [4];
eval { ${\shash_length($sh, "a100")} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is scalar(shash_get($sh, "a100")), "b100";
is_deeply [shash_get($sh, "a100")], ["b100"];
is scalar(shash_occupied($sh)), !!1;
is_deeply [shash_occupied($sh)], [!!1];
is scalar(shash_count($sh)), 3;
is_deeply [shash_count($sh)], [3];
eval { ${\shash_count($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
like scalar(shash_size($sh)), qr/\A[0-9]+\z/;
like join(",", shash_size($sh)), qr/\A[0-9]+\z/;
eval { ${\shash_size($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is scalar(shash_key_min($sh)), "a100";
is_deeply [shash_key_min($sh)], ["a100"];
is scalar(shash_key_max($sh)), "a120";
is_deeply [shash_key_max($sh)], ["a120"];
is scalar(shash_key_ge($sh, "a110")), "a110";
is_deeply [shash_key_ge($sh, "a110")], ["a110"];
is scalar(shash_key_gt($sh, "a110")), "a120";
is_deeply [shash_key_gt($sh, "a110")], ["a120"];
is scalar(shash_key_le($sh, "a110")), "a110";
is_deeply [shash_key_le($sh, "a110")], ["a110"];
is scalar(shash_key_lt($sh, "a110")), "a100";
is_deeply [shash_key_lt($sh, "a110")], ["a100"];
is_deeply scalar(shash_keys_array($sh)), [qw(a100 a110 a120)];
is_deeply [shash_keys_array($sh)], [[qw(a100 a110 a120)]];
eval { ${\shash_keys_array($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is_deeply scalar(shash_keys_hash($sh)),
	{ a100=>undef, a110=>undef, a120=>undef };
is_deeply [shash_keys_hash($sh)], [{ a100=>undef, a110=>undef, a120=>undef }];
eval { ${\shash_keys_hash($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
is_deeply scalar(shash_group_get_hash($sh)),
	{ a100=>"b100", a110=>"b110", a120=>"b120" };
is_deeply [shash_group_get_hash($sh)],
	[{ a100=>"b100", a110=>"b110", a120=>"b120" }];
eval { ${\shash_group_get_hash($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;

is scalar(shash_exists($sh, "a000")), !!0;
is scalar(shash_length($sh, "a000")), undef;
is scalar(shash_get($sh, "a000")), undef;
is scalar(shash_exists($sh, "a105")), !!0;
is scalar(shash_length($sh, "a105")), undef;
is scalar(shash_get($sh, "a105")), undef;
is scalar(shash_exists($sh, "a110")), !!1;
is scalar(shash_length($sh, "a110")), 4;
is scalar(shash_get($sh, "a110")), "b110";
is scalar(shash_exists($sh, "a115")), !!0;
is scalar(shash_length($sh, "a115")), undef;
is scalar(shash_get($sh, "a115")), undef;
is scalar(shash_exists($sh, "a120")), !!1;
is scalar(shash_length($sh, "a120")), 4;
is scalar(shash_get($sh, "a120")), "b120";
is scalar(shash_exists($sh, "a130")), !!0;
is scalar(shash_length($sh, "a130")), undef;
is scalar(shash_get($sh, "a130")), undef;

my $sn = shash_snapshot($sh);
is scalar(is_shash($sn)), !!1;
is_deeply [is_shash($sn)], [!!1];
eval { check_shash($sn) };
is $@, "";
is scalar(check_shash($sn)), undef;
is_deeply [check_shash($sn)], [];
is scalar(shash_is_snapshot($sn)), !!1;
is_deeply [shash_is_snapshot($sn)], [!!1];
is scalar(shash_is_readable($sn)), !!1;
is_deeply [shash_is_readable($sn)], [!!1];
is scalar(shash_is_writable($sn)), !!0;
is_deeply [shash_is_writable($sn)], [!!0];
is scalar(shash_mode($sn)), "r";
is_deeply [shash_mode($sn)], ["r"];

is shash_exists($sn, "a000"), !!0;
is shash_length($sn, "a000"), undef;
is shash_get($sn, "a000"), undef;
is shash_exists($sn, "a100"), !!1;
is shash_length($sn, "a100"), 4;
is shash_get($sn, "a100"), "b100";
is shash_exists($sn, "a105"), !!0;
is shash_length($sn, "a105"), undef;
is shash_get($sn, "a105"), undef;
is shash_exists($sn, "a110"), !!1;
is shash_length($sn, "a110"), 4;
is shash_get($sn, "a110"), "b110";
is shash_exists($sn, "a115"), !!0;
is shash_length($sn, "a115"), undef;
is shash_get($sn, "a115"), undef;
is shash_exists($sn, "a120"), !!1;
is shash_length($sn, "a120"), 4;
is shash_get($sn, "a120"), "b120";
is shash_exists($sn, "a130"), !!0;
is shash_length($sn, "a130"), undef;
is shash_get($sn, "a130"), undef;
is shash_occupied($sn), !!1;
is shash_count($sn), 3;
is shash_key_min($sn), "a100";
is shash_key_max($sn), "a120";
is shash_key_ge($sn, "a110"), "a110";
is shash_key_gt($sn, "a110"), "a120";
is shash_key_le($sn, "a110"), "a110";
is shash_key_lt($sn, "a110"), "a100";
is_deeply shash_keys_array($sn), [qw(a100 a110 a120)];
is_deeply shash_keys_hash($sn), { a100=>undef, a110=>undef, a120=>undef };
is_deeply shash_group_get_hash($sn),
	{ a100=>"b100", a110=>"b110", a120=>"b120" };

shash_set($sh, "a105", "b105");
shash_set($sh, "a110", undef);

is shash_exists($sh, "a000"), !!0;
is shash_length($sh, "a000"), undef;
is shash_get($sh, "a000"), undef;
is shash_exists($sh, "a100"), !!1;
is shash_length($sh, "a100"), 4;
is shash_get($sh, "a100"), "b100";
is shash_exists($sh, "a105"), !!1;
is shash_length($sh, "a105"), 4;
is shash_get($sh, "a105"), "b105";
is shash_exists($sh, "a110"), !!0;
is shash_length($sh, "a110"), undef;
is shash_get($sh, "a110"), undef;
is shash_exists($sh, "a115"), !!0;
is shash_length($sh, "a115"), undef;
is shash_get($sh, "a115"), undef;
is shash_exists($sh, "a120"), !!1;
is shash_length($sh, "a120"), 4;
is shash_get($sh, "a120"), "b120";
is shash_exists($sh, "a130"), !!0;
is shash_length($sh, "a130"), undef;
is shash_get($sh, "a130"), undef;
is shash_occupied($sh), !!1;
is shash_count($sh), 3;
is shash_key_min($sh), "a100";
is shash_key_max($sh), "a120";
is shash_key_ge($sh, "a110"), "a120";
is shash_key_gt($sh, "a110"), "a120";
is shash_key_le($sh, "a110"), "a105";
is shash_key_lt($sh, "a110"), "a105";
is_deeply shash_keys_array($sh), [qw(a100 a105 a120)];
is_deeply shash_keys_hash($sh), { a100=>undef, a105=>undef, a120=>undef };
is_deeply shash_group_get_hash($sh),
	{ a100=>"b100", a105=>"b105", a120=>"b120" };

is shash_exists($sn, "a000"), !!0;
is shash_length($sn, "a000"), undef;
is shash_get($sn, "a000"), undef;
is shash_exists($sn, "a100"), !!1;
is shash_length($sn, "a100"), 4;
is shash_get($sn, "a100"), "b100";
is shash_exists($sn, "a105"), !!0;
is shash_length($sn, "a105"), undef;
is shash_get($sn, "a105"), undef;
is shash_exists($sn, "a110"), !!1;
is shash_length($sn, "a110"), 4;
is shash_get($sn, "a110"), "b110";
is shash_exists($sn, "a115"), !!0;
is shash_length($sn, "a115"), undef;
is shash_get($sn, "a115"), undef;
is shash_exists($sn, "a120"), !!1;
is shash_length($sn, "a120"), 4;
is shash_get($sn, "a120"), "b120";
is shash_exists($sn, "a130"), !!0;
is shash_length($sn, "a130"), undef;
is shash_get($sn, "a130"), undef;
is shash_occupied($sn), !!1;
is shash_count($sn), 3;
is shash_key_min($sn), "a100";
is shash_key_max($sn), "a120";
is shash_key_ge($sn, "a110"), "a110";
is shash_key_gt($sn, "a110"), "a120";
is shash_key_le($sn, "a110"), "a110";
is shash_key_lt($sn, "a110"), "a100";
is_deeply shash_keys_array($sn), [qw(a100 a110 a120)];
is_deeply shash_keys_hash($sn), { a100=>undef, a110=>undef, a120=>undef };
is_deeply shash_group_get_hash($sn),
	{ a100=>"b100", a110=>"b110", a120=>"b120" };

eval { shash_set($sn, "a115", "b115") };
like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t0:
		\ shared\ hash\ handle\ is\ a\ snapshot\ #x;
is shash_exists($sh, "a115"), !!0;
is shash_length($sh, "a115"), undef;
is shash_get($sh, "a115"), undef;
is shash_occupied($sh), !!1;
is shash_count($sh), 3;
is shash_key_min($sh), "a100";
is shash_key_max($sh), "a120";
is shash_key_ge($sh, "a110"), "a120";
is shash_key_gt($sh, "a110"), "a120";
is shash_key_le($sh, "a110"), "a105";
is shash_key_lt($sh, "a110"), "a105";
is_deeply shash_keys_array($sh), [qw(a100 a105 a120)];
is_deeply shash_keys_hash($sh), { a100=>undef, a105=>undef, a120=>undef };
is_deeply shash_group_get_hash($sh),
	{ a100=>"b100", a105=>"b105", a120=>"b120" };
is shash_exists($sn, "a115"), !!0;
is shash_length($sn, "a115"), undef;
is shash_get($sn, "a115"), undef;
is shash_occupied($sn), !!1;
is shash_count($sn), 3;
is shash_key_min($sn), "a100";
is shash_key_max($sn), "a120";
is shash_key_ge($sn, "a110"), "a110";
is shash_key_gt($sn, "a110"), "a120";
is shash_key_le($sn, "a110"), "a110";
is shash_key_lt($sn, "a110"), "a100";
is_deeply shash_keys_array($sn), [qw(a100 a110 a120)];
is_deeply shash_keys_hash($sn), { a100=>undef, a110=>undef, a120=>undef };
is_deeply shash_group_get_hash($sn),
	{ a100=>"b100", a110=>"b110", a120=>"b120" };

shash_gset($sh, "a115", "c115");
is shash_get($sh, "a115"), "c115";
shash_gset($sh, "a115", "d115");
is shash_get($sh, "a115"), "d115";
shash_gset($sh, "a115", "d115");
is shash_get($sh, "a115"), "d115";
shash_gset($sh, "a115", undef);
is shash_get($sh, "a115"), undef;
shash_gset($sh, "a115", undef);
is shash_get($sh, "a115"), undef;

is scalar(shash_gset($sh, "a115", "e115")), undef;
is shash_get($sh, "a115"), "e115";
is scalar(shash_gset($sh, "a115", "f115")), "e115";
is shash_get($sh, "a115"), "f115";
is scalar(shash_gset($sh, "a115", "f115")), "f115";
is shash_get($sh, "a115"), "f115";
is scalar(shash_gset($sh, "a115", undef)), "f115";
is shash_get($sh, "a115"), undef;
is scalar(shash_gset($sh, "a115", undef)), undef;
is shash_get($sh, "a115"), undef;

is_deeply [shash_gset($sh, "a115", "g115")], [undef];
is shash_get($sh, "a115"), "g115";
is_deeply [shash_gset($sh, "a115", "h115")], ["g115"];
is shash_get($sh, "a115"), "h115";
is_deeply [shash_gset($sh, "a115", "h115")], ["h115"];
is shash_get($sh, "a115"), "h115";
is_deeply [shash_gset($sh, "a115", undef)], ["h115"];
is shash_get($sh, "a115"), undef;
is_deeply [shash_gset($sh, "a115", undef)], [undef];
is shash_get($sh, "a115"), undef;

shash_cset($sh, "a115", "z", "i115");
is shash_get($sh, "a115"), undef;
shash_cset($sh, "a115", undef, "j115");
is shash_get($sh, "a115"), "j115";
shash_cset($sh, "a115", "z", "k115");
is shash_get($sh, "a115"), "j115";
shash_cset($sh, "a115", undef, "l115");
is shash_get($sh, "a115"), "j115";
shash_cset($sh, "a115", "j115", "m115");
is shash_get($sh, "a115"), "m115";
shash_cset($sh, "a115", "z", "m115");
is shash_get($sh, "a115"), "m115";
shash_cset($sh, "a115", undef, "m115");
is shash_get($sh, "a115"), "m115";
shash_cset($sh, "a115", "m115", "m115");
is shash_get($sh, "a115"), "m115";
shash_cset($sh, "a115", "z", undef);
is shash_get($sh, "a115"), "m115";
shash_cset($sh, "a115", undef, undef);
is shash_get($sh, "a115"), "m115";
shash_cset($sh, "a115", "m115", undef);
is shash_get($sh, "a115"), undef;
shash_cset($sh, "a115", "z", undef);
is shash_get($sh, "a115"), undef;
shash_cset($sh, "a115", undef, undef);
is shash_get($sh, "a115"), undef;

is scalar(shash_cset($sh, "a115", "z", "i115")), !!0;
is shash_get($sh, "a115"), undef;
is scalar(shash_cset($sh, "a115", undef, "j115")), !!1;
is shash_get($sh, "a115"), "j115";
is scalar(shash_cset($sh, "a115", "z", "k115")), !!0;
is shash_get($sh, "a115"), "j115";
is scalar(shash_cset($sh, "a115", undef, "l115")), !!0;
is shash_get($sh, "a115"), "j115";
is scalar(shash_cset($sh, "a115", "j115", "m115")), !!1;
is shash_get($sh, "a115"), "m115";
is scalar(shash_cset($sh, "a115", "z", "m115")), !!0;
is shash_get($sh, "a115"), "m115";
is scalar(shash_cset($sh, "a115", undef, "m115")), !!0;
is shash_get($sh, "a115"), "m115";
is scalar(shash_cset($sh, "a115", "m115", "m115")), !!1;
is shash_get($sh, "a115"), "m115";
is scalar(shash_cset($sh, "a115", "z", undef)), !!0;
is shash_get($sh, "a115"), "m115";
is scalar(shash_cset($sh, "a115", undef, undef)), !!0;
is shash_get($sh, "a115"), "m115";
is scalar(shash_cset($sh, "a115", "m115", undef)), !!1;
is shash_get($sh, "a115"), undef;
is scalar(shash_cset($sh, "a115", "z", undef)), !!0;
is shash_get($sh, "a115"), undef;
is scalar(shash_cset($sh, "a115", undef, undef)), !!1;
is shash_get($sh, "a115"), undef;

is_deeply [shash_cset($sh, "a115", "z", "i115")], [!!0];
is shash_get($sh, "a115"), undef;
is_deeply [shash_cset($sh, "a115", undef, "j115")], [!!1];
is shash_get($sh, "a115"), "j115";
is_deeply [shash_cset($sh, "a115", "z", "k115")], [!!0];
is shash_get($sh, "a115"), "j115";
is_deeply [shash_cset($sh, "a115", undef, "l115")], [!!0];
is shash_get($sh, "a115"), "j115";
is_deeply [shash_cset($sh, "a115", "j115", "m115")], [!!1];
is shash_get($sh, "a115"), "m115";
is_deeply [shash_cset($sh, "a115", "z", "m115")], [!!0];
is shash_get($sh, "a115"), "m115";
is_deeply [shash_cset($sh, "a115", undef, "m115")], [!!0];
is shash_get($sh, "a115"), "m115";
is_deeply [shash_cset($sh, "a115", "m115", "m115")], [!!1];
is shash_get($sh, "a115"), "m115";
is_deeply [shash_cset($sh, "a115", "z", undef)], [!!0];
is shash_get($sh, "a115"), "m115";
is_deeply [shash_cset($sh, "a115", undef, undef)], [!!0];
is shash_get($sh, "a115"), "m115";
is_deeply [shash_cset($sh, "a115", "m115", undef)], [!!1];
is shash_get($sh, "a115"), undef;
is_deeply [shash_cset($sh, "a115", "z", undef)], [!!0];
is shash_get($sh, "a115"), undef;
is_deeply [shash_cset($sh, "a115", undef, undef)], [!!1];
is shash_get($sh, "a115"), undef;

shash_idle($sh);
is scalar(shash_idle($sh)), undef;
is_deeply [shash_idle($sh)], [];

shash_tidy($sh);
is scalar(shash_tidy($sh)), undef;
is_deeply [shash_tidy($sh)], [];

my $h;
shash_tally_get($sh);
$h = shash_tally_get($sh);
is ref($h), "HASH";
ok !grep { !/\A[a-z_]+\z/ } keys %$h;
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;
$h = [shash_tally_get($sh)];
is @$h, 1;
is ref($h->[0]), "HASH";
ok !grep { !/\A[a-z_]+\z/ } keys %{$h->[0]};
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %{$h->[0]};

shash_tally_zero($sh);
is scalar(shash_tally_zero($sh)), undef;
is_deeply [shash_tally_zero($sh)], [];

shash_tally_gzero($sh);
$h = shash_tally_gzero($sh);
is ref($h), "HASH";
ok !grep { !/\A[a-z_]+\z/ } keys %$h;
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %$h;
$h = [shash_tally_gzero($sh)];
is @$h, 1;
is ref($h->[0]), "HASH";
ok !grep { !/\A[a-z_]+\z/ } keys %{$h->[0]};
ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %{$h->[0]};

my $nx = shash_open("$tmpdir/t1", "c");
ok $nx;
is scalar(is_shash($nx)), !!1;
is_deeply [is_shash($nx)], [!!1];
eval { check_shash($nx) };
is $@, "";
is scalar(check_shash($nx)), undef;
is_deeply [check_shash($nx)], [];
is scalar(shash_is_snapshot($nx)), !!0;
is_deeply [shash_is_snapshot($nx)], [!!0];
is scalar(shash_is_readable($nx)), !!0;
is_deeply [shash_is_readable($nx)], [!!0];
is scalar(shash_is_writable($nx)), !!0;
is_deeply [shash_is_writable($nx)], [!!0];
is scalar(shash_mode($nx)), "";
is_deeply [shash_mode($nx)], [""];
eval { shash_exists($nx, "a100") };
like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t1:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
eval { shash_length($nx, "a100") };
like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t1:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
eval { shash_get($nx, "a100") };
like $@, qr#\Acan't\ read\ shared\ hash\ \Q$tmpdir\E/t1:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
eval { shash_set($nx, "a100", "b100") };
like $@, qr#\Acan't\ write\ shared\ hash\ \Q$tmpdir\E/t1:
		\ shared\ hash\ was\ opened\ in\ unwritable\ mode\ #x;
eval { shash_gset($nx, "a100", "b100") };
like $@, qr#\Acan't\ update\ shared\ hash\ \Q$tmpdir\E/t1:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;
eval { shash_cset($nx, "a100", "b100", "c100") };
like $@, qr#\Acan't\ update\ shared\ hash\ \Q$tmpdir\E/t1:
		\ shared\ hash\ was\ opened\ in\ unreadable\ mode\ #x;

eval { shash_open("$tmpdir/t1", "c") };
is $@, "";
my @sh = shash_open("$tmpdir/t1", "c");
is scalar(@sh), 1;
ok is_shash($sh[0]);
eval { ${\shash_open("$tmpdir/t1", "c")} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
eval { ${\shash_snapshot($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
eval { ${\shash_snapshot($sn)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;

1;
