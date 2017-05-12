use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 1803;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open
	shash_length shash_get shash_set
	shash_occupied shash_count
	shash_key_min shash_key_max
	shash_key_ge shash_key_gt shash_key_le shash_key_lt
	shash_keys_array shash_keys_hash
	shash_group_get_hash
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);
my %ph;

sub doru($) { defined($_[0]) ? $_[0] : "u" }
sub dorm1($) { defined($_[0]) ? $_[0] : -1 }

sub check_hash_state() {
	is shash_occupied($sh), !!keys(%ph);
	is shash_count($sh), keys(%ph);
	my @sk = sort keys %ph;
	is shash_key_min($sh), $sk[0];
	is shash_key_max($sh), @sk ? $sk[-1] : undef;
	my $ok = 1;
	for(my $v = 0; $v != 100000; $v++) {
		$ok &&= dorm1(shash_length($sh, $v)) ==
				exists($ph{$v}) ? length($ph{$v}) : -1;
		$ok &&= doru(shash_get($sh, $v)) eq doru($ph{$v});
	}
	ok $ok;
	$ok = 1;
	for(my $i = 0; $i != @sk; $i++) {
		$ok &&= doru(shash_key_ge($sh, $sk[$i])) eq $sk[$i];
		$ok &&= doru(shash_key_gt($sh, $sk[$i])) eq doru($sk[$i+1]);
		$ok &&= doru(shash_key_le($sh, $sk[$i])) eq $sk[$i];
		$ok &&= doru(shash_key_lt($sh, $sk[$i])) eq
				($i != 0 ? $sk[$i-1] : "u");
	}
	ok $ok;
	$ok = 1;
	$ok &&= doru(shash_key_ge($sh, "-")) eq doru($sk[0]);
	$ok &&= doru(shash_key_gt($sh, "-")) eq doru($sk[0]);
	$ok &&= doru(shash_key_le($sh, "-")) eq "u";
	$ok &&= doru(shash_key_lt($sh, "-")) eq "u";
	for(my $i = 0; $i < $#sk; $i++) {
		$ok &&= doru(shash_key_ge($sh, $sk[$i]."-")) eq doru($sk[$i+1]);
		$ok &&= doru(shash_key_gt($sh, $sk[$i]."-")) eq doru($sk[$i+1]);
		$ok &&= doru(shash_key_le($sh, $sk[$i]."-")) eq $sk[$i];
		$ok &&= doru(shash_key_lt($sh, $sk[$i]."-")) eq $sk[$i];
	}
	ok $ok;
	is_deeply shash_keys_array($sh), \@sk;
	is_deeply shash_keys_hash($sh), { map { ($_ => undef) } @sk };
	is_deeply shash_group_get_hash($sh), \%ph;
}

my $v = 5;
for(my $i = 0; $i != 40; $i++) {
	for(my $j = 0; $j != 1000; $j++) {
		$v = ($v*21+7) % 100000;
		shash_set($sh, $v, "a".$v);
		$ph{$v} = "a".$v;
	}
	check_hash_state();
}

$v = 5;
for(my $i = 0; $i != 40; $i++) {
	for(my $j = 0; $j != 1000; $j++) {
		$v = ($v*61+19) % 100000;
		shash_set($sh, $v, "b".$v);
		$ph{$v} = "b".$v;
	}
	check_hash_state();
}

$v = 5;
for(my $i = 0; $i != 100; $i++) {
	for(my $j = 0; $j != 1000; $j++) {
		$v = ($v*41+17) % 100000;
		shash_set($sh, $v, undef);
		delete $ph{$v};
	}
	check_hash_state();
}

1;
