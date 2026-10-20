#!perl
use strict;
use warnings;
use Test::More;
use File::Raw::Hash;
use Digest::SHA ();
use Digest::MD5 ();

# The digests against Digest::SHA and Digest::MD5: every input length from 0
# to 1,100 bytes (every block-boundary case for 64- and 128-byte blocks) and
# two large ones, each from a buffer at a random offset and fed in random
# pieces. A seed is fixed so a failure repeats; ORACLE_SEED overrides it.

plan skip_all => 'RELEASE_TESTING not set' unless $ENV{RELEASE_TESTING};

my $seed = $ENV{ORACLE_SEED} // 20261019;
srand $seed;
diag "seed $seed";

my %ref = (
    md5    => sub { Digest::MD5::md5_hex($_[0]) },
    sha1   => sub { Digest::SHA::sha1_hex($_[0]) },
    sha256 => sub { Digest::SHA::sha256_hex($_[0]) },
    sha512 => sub { Digest::SHA::sha512_hex($_[0]) },
);

sub bytes { join '', map { chr int rand 256 } 1 .. $_[0] }

for my $algo (sort keys %ref) {
    my ($bad, $n) = (0, 0);
    for my $len (0 .. 1100, 1 << 20, (64 << 20) + 37) {
        my $data = $len > 1 << 16 ? (bytes(4096) x int($len / 4096 + 1)) : bytes($len);
        substr($data, $len) = '' if length $data > $len;
        my $want = $ref{$algo}->($data);
        my $offset = int rand 64;
        my @pieces = map { 1 + int rand 200 } 1 .. (1 + int rand 5);
        push @pieces, 64 if $len % 3 == 0;
        my $got = File::Raw::Hash::_test_feed($algo, $data, $offset, @pieces);
        my $whole = File::Raw::Hash::_test_feed($algo, $data, 0);
        $n++;
        next if $got eq $want && $whole eq $want;
        $bad++;
        diag "$algo, $len bytes, offset $offset, pieces @pieces: got $got / $whole, want $want" if $bad <= 5;
    }
    is $bad, 0, "$algo agrees with the reference on all $n inputs, whole and in pieces";
}

done_testing;
