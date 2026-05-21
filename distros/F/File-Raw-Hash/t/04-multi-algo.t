#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# `algos => [...]` writes a hashref keyed by algo name. Every entry
# must equal the same input run through that algo on its own.

my ($fh, $path) = tempfile(UNLINK => 1);
binmode $fh;
print $fh 'The quick brown fox jumps over the lazy dog';
close $fh;

# Single-algo references for cross-checking.
my %expected;
for my $algo (qw(sha256 sha512 sha1 md5 crc32)) {
    file_slurp($path,
        plugin => 'hash', algo => $algo, into => \$expected{$algo});
}

# Multi-algo run, hash dest.
my %got;
my $bytes = file_slurp($path,
    plugin => 'hash',
    algos  => [qw(sha256 sha512 sha1 md5 crc32)],
    into   => \%got,
);

is($bytes, 'The quick brown fox jumps over the lazy dog',
   'multi-algo run still passes bytes through');

is_deeply([sort keys %got], [qw(crc32 md5 sha1 sha256 sha512)],
          'hash destination has one entry per requested algo');

for my $algo (sort keys %expected) {
    is($got{$algo}, $expected{$algo},
       "multi-algo $algo matches single-algo $algo");
}

# Subset of two algos.
{
    my %got2;
    file_slurp($path,
        plugin => 'hash',
        algos  => [qw(md5 sha256)],
        into   => \%got2);
    is_deeply([sort keys %got2], [qw(md5 sha256)],
              'subset: only requested algos appear');
    is($got2{md5},    $expected{md5},    'subset md5 matches');
    is($got2{sha256}, $expected{sha256}, 'subset sha256 matches');
}

# Existing keys in the destination hash are preserved.
{
    my %dest = (preexisting => 'kept');
    file_slurp($path,
        plugin => 'hash',
        algos  => [qw(sha256)],
        into   => \%dest);
    is($dest{preexisting}, 'kept', 'existing hash entries are not clobbered');
    is($dest{sha256}, $expected{sha256}, 'requested entry is added');
}

done_testing;
