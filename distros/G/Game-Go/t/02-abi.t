#!perl

# The ABI table, and the zobrist table under it.
#
# THE ZOBRIST ASSERTION IS THE POINT OF THIS FILE. The table is derived from
# SHA-256 rather than from a generator for exactly one reason: it makes the
# values verifiable from outside the engine. Digest::SHA is core, so this file
# computes the entries independently and compares. A table seeded from a PRNG
# would be a build artifact sitting in the middle of the legality path with
# nothing able to check it.

use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Go;
use Game::Go::Engine;

subtest 'the table is there and its version obeys the >= rule' => sub {
	my $ptr = Game::Go::Engine::_abi_ptr();
	ok($ptr, 'the table has an address');

	my $v = Game::Go::Engine::_abi_version();
	is($v, Game::Go->abi_version, 'and Game::Go->abi_version reports the same one');
	cmp_ok($v, '>=', 1, 'it is at or above the version this suite was written against');
	done_testing();
};

subtest 'every slot in the table is reachable' => sub {
	# There is no way to read a function pointer for null-ness from Perl, so
	# this calls one thing per slot instead. A slot left unassigned in
	# go_abi_table() is a null call and a crash, which is a louder failure
	# than a skipped test and is the whole reason the table is filled in by
	# NAME rather than positionally.
	my $b = Game::Go::Engine->new(size => 9);
	my $pt = $b->point_of(4, 4);

	is($b->size, 9, 'size_of');
	is($b->stride, 11, 'stride_of');
	is($b->col_of($pt), 4, 'col_of');
	is($b->row_of($pt), 4, 'row_of');
	is($b->at($pt), Game::Go::EMPTY, 'at');
	is($b->libs($pt), -1, 'libs, on an empty point');
	is($b->chain_size($pt), 0, 'chain_size, on an empty point');
	is_deeply($b->chain_at($pt), [], 'chain_at, on an empty point');
	is($b->stones(Game::Go::BLACK), 0, 'stones');
	is(length($b->pack_position), 81, 'pack');
	is(length($b->hash_hex), 16, 'hash');
	isa_ok($b->clone, 'Game::Go::Engine', 'board_copy');

	$b->put($pt, Game::Go::BLACK);
	is($b->at($pt), Game::Go::BLACK, 'put');
	is($b->lift($pt), 1, 'lift');

	like(Game::Go::Engine->zobrist_hex(1, 1), qr/\A[0-9a-f]{16}\z/, 'zobrist');
	done_testing();
};

subtest 'every declared table member is actually assigned' => sub {
	# The table is filled in BY NAME rather than by a positional initialiser,
	# which stops a reordered struct binding the wrong function to a member.
	# It does not stop a member being declared and then never assigned, which
	# leaves a null pointer in the table and crashes the first caller.
	#
	# So this reads both sources and compares the two sets. It is the only
	# assertion in the suite that looks at the C rather than through it, and
	# it is here because the alternative is noticing at a segfault.
	plan skip_all => 'not run from the distribution root'
		unless -e 'include/go_abi.h' && -e 'go_engine.c' && -e 'go_search.c';

	my $header = do { open my $fh, '<', 'include/go_abi.h' or die $!; local $/; <$fh> };
	my $engine = do { open my $fh, '<', 'go_engine.c'      or die $!; local $/; <$fh> };
	my $search = do { open my $fh, '<', 'go_search.c'      or die $!; local $/; <$fh> };

	my ($struct) = $header =~ /struct go_abi \{(.*?)\n\};/s;
	ok($struct, 'found struct go_abi in the header');
	my @declared = $struct =~ /\(\s*\*\s*([a-z_0-9]+)\s*\)/g;

	# THE TABLE IS FILLED IN FROM TWO FILES. go_engine.c assigns its own
	# members and then hands the table to go_search.c, which assigns the
	# search's four. A test that read only the first file would report four
	# unassigned members that are in fact assigned, and would have to be
	# weakened to shut it up; reading both keeps it exact.
	my ($body) = $engine =~ /const struct go_abi \*go_abi_table\(void\)\s*\{(.*?)\n\}/s;
	ok($body, 'found go_abi_table in the engine');
	my @assigned = $body =~ /GO_TABLE\.([a-z_0-9]+)\s*=/g;

	my ($install) = $search =~ /void go_search_install\(struct go_abi \*t\)\s*\{(.*?)\n\}/s;
	ok($install, 'found go_search_install in the search');
	push @assigned, $install =~ /t->([a-z_0-9]+)\s*=/g;

	# abi_version is a plain integer rather than a function pointer, so it is
	# assigned and not declared among them.
	my %assigned = map { $_ => 1 } @assigned;
	delete $assigned{abi_version};

	cmp_ok(scalar @declared, '>=', 30, 'the header declares a table of real size');
	is_deeply([ sort @declared ], [ sort keys %assigned ],
		'every declared member is assigned, and nothing is assigned that is not declared');
	done_testing();
};

subtest 'the zobrist table is the SHA-256 the header says it is' => sub {
	# The spelling of the label is PART OF THE ABI, because this is what
	# holds the C to it:
	#
	#     zobrist(colour, point) = the first 8 bytes, big-endian, of
	#                              SHA256("go-zobrist:<colour>:<point>")
	#
	# Changing either the prefix or the separators changes every hash in
	# every saved superko history, so it changes with an ABI version bump
	# and not otherwise.
	my $checked = 0;
	for my $colour (1, 2) {
		for my $pt (0, 1, 24, 48, 100, 440) {
			my $want = unpack 'H16', substr(sha256("go-zobrist:$colour:$pt"), 0, 8);
			my $got  = Game::Go::Engine->zobrist_hex($colour, $pt);
			is($got, $want, "zobrist($colour, $pt) is the documented SHA-256");
			$checked++;
		}
	}
	is($checked, 12, 'and the loop actually ran, rather than passing by comparing nothing');
	done_testing();
};

subtest 'the zobrist table has no give-away structure' => sub {
	my %seen;
	my $n = 0;
	for my $colour (1, 2) {
		for my $pt (0 .. 440) {
			my $h = Game::Go::Engine->zobrist_hex($colour, $pt);
			$seen{$h}++;
			$n++;
		}
	}
	is($n, 882, 'every entry of the table was read');
	is(scalar keys %seen, 882, 'and all 882 are distinct');

	isnt(Game::Go::Engine->zobrist_hex(1, 24),
	     Game::Go::Engine->zobrist_hex(2, 24),
	     'the two colours differ on the same point');
	is(Game::Go::Engine->zobrist_hex(0, 24), '0' x 16, 'EMPTY has no entry');
	is(Game::Go::Engine->zobrist_hex(3, 24), '0' x 16, 'nor does BORDER');
	done_testing();
};

subtest 'the hash is a string, and that is deliberate' => sub {
	# A 64-bit value does not fit a UV on a perl built with 32-bit integers,
	# and the top half would vanish with nothing saying so. Every entry
	# below has its high nibble set, so a test that let the value through a
	# number would show it.
	my @high = grep { /\A[89a-f]/ }
	           map  { Game::Go::Engine->zobrist_hex(1, $_) } 0 .. 440;
	ok(scalar @high, 'some entries have the top bit of the top byte set');
	like($high[0], qr/\A[0-9a-f]{16}\z/, 'and they come back as sixteen hex characters');
	done_testing();
};

done_testing();
