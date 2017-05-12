use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 89;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open
	shash_get shash_set
	shash_snapshot shash_is_snapshot
	shash_idle
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $s0 = shash_open("$tmpdir/t0", "rwc");
ok $s0;
ok is_shash($s0);
ok !shash_is_snapshot($s0);

shash_set($s0, "a", "aa");
shash_set($s0, "b", "bb");
is shash_get($s0, "a"), "aa";
is shash_get($s0, "b"), "bb";
is shash_get($s0, "c"), undef;
is shash_get($s0, "d"), undef;

my $s1 = shash_snapshot($s0);
ok $s1;
ok is_shash($s1);
ok shash_is_snapshot($s1);
is shash_get($s1, "a"), "aa";
is shash_get($s1, "b"), "bb";
is shash_get($s1, "c"), undef;
is shash_get($s1, "d"), undef;

shash_set($s0, "c", "cc");
is shash_get($s0, "a"), "aa";
is shash_get($s0, "b"), "bb";
is shash_get($s0, "c"), "cc";
is shash_get($s0, "d"), undef;
is shash_get($s1, "a"), "aa";
is shash_get($s1, "b"), "bb";
is shash_get($s1, "c"), undef;
is shash_get($s1, "d"), undef;

my $s2 = shash_snapshot($s0);
ok $s2;
ok is_shash($s2);
ok shash_is_snapshot($s2);
is shash_get($s2, "a"), "aa";
is shash_get($s2, "b"), "bb";
is shash_get($s2, "c"), "cc";
is shash_get($s2, "d"), undef;

shash_set($s0, "d", "dd");
is shash_get($s0, "a"), "aa";
is shash_get($s0, "b"), "bb";
is shash_get($s0, "c"), "cc";
is shash_get($s0, "d"), "dd";
is shash_get($s1, "a"), "aa";
is shash_get($s1, "b"), "bb";
is shash_get($s1, "c"), undef;
is shash_get($s1, "d"), undef;
is shash_get($s2, "a"), "aa";
is shash_get($s2, "b"), "bb";
is shash_get($s2, "c"), "cc";
is shash_get($s2, "d"), undef;

shash_idle($s0);
shash_idle($s1);

my $s3 = shash_snapshot($s1);
ok $s3;
ok is_shash($s3);
ok shash_is_snapshot($s3);
is shash_get($s3, "a"), "aa";
is shash_get($s3, "b"), "bb";
is shash_get($s3, "c"), undef;
is shash_get($s3, "d"), undef;

shash_set($s0, "a", undef);
is shash_get($s0, "a"), undef;
is shash_get($s0, "b"), "bb";
is shash_get($s0, "c"), "cc";
is shash_get($s0, "d"), "dd";
is shash_get($s1, "a"), "aa";
is shash_get($s1, "b"), "bb";
is shash_get($s1, "c"), undef;
is shash_get($s1, "d"), undef;
is shash_get($s2, "a"), "aa";
is shash_get($s2, "b"), "bb";
is shash_get($s2, "c"), "cc";
is shash_get($s2, "d"), undef;
is shash_get($s3, "a"), "aa";
is shash_get($s3, "b"), "bb";
is shash_get($s3, "c"), undef;
is shash_get($s3, "d"), undef;

$s0 = undef;
is shash_get($s1, "a"), "aa";
is shash_get($s1, "b"), "bb";
is shash_get($s1, "c"), undef;
is shash_get($s1, "d"), undef;
is shash_get($s2, "a"), "aa";
is shash_get($s2, "b"), "bb";
is shash_get($s2, "c"), "cc";
is shash_get($s2, "d"), undef;
is shash_get($s3, "a"), "aa";
is shash_get($s3, "b"), "bb";
is shash_get($s3, "c"), undef;
is shash_get($s3, "d"), undef;

$s1 = undef;
is shash_get($s2, "a"), "aa";
is shash_get($s2, "b"), "bb";
is shash_get($s2, "c"), "cc";
is shash_get($s2, "d"), undef;
is shash_get($s3, "a"), "aa";
is shash_get($s3, "b"), "bb";
is shash_get($s3, "c"), undef;
is shash_get($s3, "d"), undef;

$s2 = undef;
is shash_get($s3, "a"), "aa";
is shash_get($s3, "b"), "bb";
is shash_get($s3, "c"), undef;
is shash_get($s3, "d"), undef;

1;
