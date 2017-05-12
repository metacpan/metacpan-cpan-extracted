use warnings;
use strict;

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 149;

BEGIN { use_ok "Hash::SharedMem", qw(
	is_shash shash_open shash_get shash_set shash_gset
	shash_tally_get shash_tally_zero shash_tally_gzero
); }

my $tmpdir = tempdir(CLEANUP => 1);
my $sh = shash_open("$tmpdir/t0", "rwc");
ok $sh;
ok is_shash($sh);
my $t;

sub ok_tally($) {
	is ref($_[0]), "HASH";
	is_deeply [ sort keys %{$_[0]} ], [sort qw(
		string_read
		string_write
		bnode_read
		bnode_write
		key_compare
		root_change_attempt
		root_change_success
		file_change_attempt
		file_change_success
		data_read_op
		data_write_op
	)];
	ok !grep { ref($_) ne "" } values %{$_[0]};
	ok !grep { !/\A(?:0|[1-9][0-9]*)\z/ } values %{$_[0]};
}

$t = shash_tally_get($sh);
ok_tally $t;
ok !grep { $_ ne "0" } values %$t;

is shash_get($sh, "a0"), undef;
$t = shash_tally_get($sh);
ok_tally $t;
is $t->{string_read}, 0;
is $t->{string_write}, 0;
is $t->{bnode_read}, 1;
is $t->{bnode_write}, 0;
is $t->{key_compare}, 0;
is $t->{root_change_attempt}, 0;
is $t->{root_change_success}, 0;
is $t->{file_change_attempt}, 0;
is $t->{file_change_success}, 0;
is $t->{data_read_op}, 1;
is $t->{data_write_op}, 0;

is shash_get($sh, "a1"), undef;
$t = shash_tally_get($sh);
ok_tally $t;
is $t->{string_read}, 0;
is $t->{string_write}, 0;
is $t->{bnode_read}, 2;
is $t->{bnode_write}, 0;
is $t->{key_compare}, 0;
is $t->{root_change_attempt}, 0;
is $t->{root_change_success}, 0;
is $t->{file_change_attempt}, 0;
is $t->{file_change_success}, 0;
is $t->{data_read_op}, 2;
is $t->{data_write_op}, 0;

shash_set($sh, "a2", "b2");
$t = shash_tally_get($sh);
ok_tally $t;
SKIP: {
	skip "surprisingly early file rollover", 11
		if $t->{file_change_attempt} > 1;
	is $t->{string_read}, 0;
	is $t->{string_write}, 2;
	is $t->{bnode_read}, 5;
	is $t->{bnode_write}, 1;
	is $t->{key_compare}, 0;
	is $t->{root_change_attempt}, 1;
	is $t->{root_change_success}, 1;
	is $t->{file_change_attempt}, 1;
	is $t->{file_change_success}, 1;
	is $t->{data_read_op}, 2;
	is $t->{data_write_op}, 1;
}

shash_set($sh, "a3", "b3");
$t = shash_tally_get($sh);
ok_tally $t;
SKIP: {
	skip "surprisingly early file rollover", 11
		if $t->{file_change_attempt} > 1;
	is $t->{string_read}, 1;
	is $t->{string_write}, 4;
	is $t->{bnode_read}, 6;
	is $t->{bnode_write}, 2;
	is $t->{key_compare}, 1;
	is $t->{root_change_attempt}, 2;
	is $t->{root_change_success}, 2;
	is $t->{file_change_attempt}, 1;
	is $t->{file_change_success}, 1;
	is $t->{data_read_op}, 2;
	is $t->{data_write_op}, 2;
}

is shash_get($sh, "a2"), "b2";
$t = shash_tally_get($sh);
ok_tally $t;
SKIP: {
	skip "surprisingly early file rollover", 11
		if $t->{file_change_attempt} > 1;
	ok $t->{string_read} >= 2;
	is $t->{string_write}, 4;
	is $t->{bnode_read}, 7;
	is $t->{bnode_write}, 2;
	ok $t->{key_compare} >= 2;
	is $t->{root_change_attempt}, 2;
	is $t->{root_change_success}, 2;
	is $t->{file_change_attempt}, 1;
	is $t->{file_change_success}, 1;
	is $t->{data_read_op}, 3;
	is $t->{data_write_op}, 2;
}

shash_tally_zero($sh);
$t = shash_tally_get($sh);
ok_tally $t;
ok !grep { $_ ne "0" } values %$t;

is shash_get($sh, "a0"), undef;
$t = shash_tally_get($sh);
ok_tally $t;
ok $t->{string_read} >= 1;
is $t->{string_write}, 0;
is $t->{bnode_read}, 1;
is $t->{bnode_write}, 0;
ok $t->{key_compare} >= 1;
is $t->{root_change_attempt}, 0;
is $t->{root_change_success}, 0;
is $t->{file_change_attempt}, 0;
is $t->{file_change_success}, 0;
is $t->{data_read_op}, 1;
is $t->{data_write_op}, 0;
is_deeply shash_tally_get($sh), $t;

is shash_gset($sh, "a2", "b2b"), "b2";
$t = shash_tally_gzero($sh);
ok_tally $t;
SKIP: {
	skip "surprisingly early file rollover", 11
		if $t->{file_change_attempt} > 0;
	ok $t->{string_read} >= 3;
	is $t->{string_write}, 1;
	is $t->{bnode_read}, 2;
	is $t->{bnode_write}, 1;
	ok $t->{key_compare} >= 2;
	is $t->{root_change_attempt}, 1;
	is $t->{root_change_success}, 1;
	is $t->{file_change_attempt}, 0;
	is $t->{file_change_success}, 0;
	is $t->{data_read_op}, 1;
	is $t->{data_write_op}, 1;
}
eval { $t->{string_read} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
$t = shash_tally_get($sh);
ok_tally $t;
ok !grep { $_ ne "0" } values %$t;

is shash_gset($sh, "a2", "b2b"), "b2b";
$t = shash_tally_get($sh);
ok_tally $t;
SKIP: {
	skip "surprisingly early file rollover", 11
		if $t->{file_change_attempt} > 0;
	ok $t->{string_read} >= 2;
	is $t->{string_write}, 0;
	is $t->{bnode_read}, 1;
	is $t->{bnode_write}, 0;
	ok $t->{key_compare} >= 1;
	is $t->{root_change_attempt}, 0;
	is $t->{root_change_success}, 0;
	is $t->{file_change_attempt}, 0;
	is $t->{file_change_success}, 0;
	is $t->{data_read_op}, 0;
	is $t->{data_write_op}, 1;
}
eval { $t->{string_read} = undef; };
like $@, qr/\AModification of a read-only value attempted /;

eval { ${\shash_tally_get($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;
eval { ${\shash_tally_gzero($sh)} = undef; };
like $@, qr/\AModification of a read-only value attempted /;

1;
