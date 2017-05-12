use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 13;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open
	shash_length shash_get shash_set
	shash_occupied shash_count shash_size
	shash_key_min shash_key_max
	shash_keys_array shash_keys_hash
	shash_group_get_hash
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);

my $tstr = join("", map { sprintf("abcd%6d", $_) } 0..999_999);
shash_set($sh, "xyz", $tstr);
is shash_occupied($sh), !!1;
is shash_count($sh), 1;
ok shash_size($sh) > length($tstr);
is shash_key_min($sh), "xyz";
is shash_key_max($sh), "xyz";
is_deeply shash_keys_array($sh), ["xyz"];
is_deeply shash_keys_hash($sh), { xyz=>undef };
is_deeply shash_group_get_hash($sh), { xyz=>$tstr };
is shash_length($sh, "xyz"), length($tstr);
is shash_get($sh, "xyz"), $tstr;

1;
