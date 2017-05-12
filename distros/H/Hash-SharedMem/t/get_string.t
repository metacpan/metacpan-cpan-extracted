use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 30014;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open
	shash_get shash_set
	shash_key_min shash_key_max
	shash_keys_array shash_keys_hash
	shash_group_get_hash
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);

my $keys_a = shash_keys_array($sh);
is_deeply $keys_a, [];
eval { push @$keys_a, "zzz"; };
like $@, qr/\AModification of a read-only value attempted /;
is_deeply shash_keys_hash($sh), {};
is_deeply shash_group_get_hash($sh), {};

my $genstr = join("x", 0..1222);
my %orig;
for(my $i = 0; $i != 5000; $i++) {
	my $s = substr($i."_".$genstr, 0, $i);
	shash_set($sh, $i, $s);
	$orig{$i} = \$s;
}
my %get;
for(my $i = 0; $i != 5000; $i++) {
	$get{$i} = \shash_get($sh, $i);
}
is_deeply \%get, \%orig;
$keys_a = shash_keys_array($sh);
my $keys_h = shash_keys_hash($sh);
my $group_h = shash_group_get_hash($sh);
is_deeply $keys_a, [sort keys %orig];
is_deeply $keys_h, { map { ($_ => undef) } keys %orig };
is_deeply $group_h, { map { ($_ => ${$orig{$_}}) } keys %orig };
$sh = undef;
is_deeply \%get, \%orig;
is_deeply $keys_a, [sort keys %orig];
is_deeply $keys_h, { map { ($_ => undef) } keys %orig };
for(my $i = 0; $i != 5000; $i++) {
	eval { ${$get{$i}} = undef; };
	like $@, qr/\AModification of a read-only value attempted /;
	eval { $keys_a->[$i] = undef; };
	like $@, qr/\AModification of a read-only value attempted /;
	eval { $keys_h->{$i} = undef; };
	like $@, qr/\AModification of a read-only value attempted /;
	eval { $group_h->{$i} = undef; };
	like $@, qr/\AModification of a read-only value attempted /;
}
eval { push @$keys_a, "zzz"; };
like $@, qr/\AModification of a read-only value attempted /;

$sh = shash_open("$tmpdir/t0", "rw");
ok $sh;
ok is_shash($sh);

my(@orig, @key);
for(my $i = 5000; $i--; ) {
	my $k = substr(sprintf("-%04d_%s", $i, $genstr), 0, $i);
	$orig[$i] = \$k;
	shash_set($sh, $k, $i);
	$key[$i] = \shash_key_min($sh);
}
is_deeply \@key, \@orig;
for(my $i = 0; $i != 5000; $i++) {
	eval { ${$key[$i]} = undef; };
	like $@, qr/\AModification of a read-only value attempted /;
}

@orig = (); @key = ();
for(my $i = 5; $i != 5000; $i++) {
	my $k = substr(sprintf("l%04d_%s", $i, $genstr), 0, $i);
	$orig[$i] = \$k;
	shash_set($sh, $k, $i);
	$key[$i] = \shash_key_max($sh);
}
is_deeply \@key, \@orig;
for(my $i = 5; $i != 5000; $i++) {
	eval { ${$key[$i]} = undef; };
	like $@, qr/\AModification of a read-only value attempted /;
}

1;
