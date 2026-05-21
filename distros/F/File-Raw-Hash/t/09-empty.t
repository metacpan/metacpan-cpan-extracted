#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Empty input must produce each algorithm's empty-string digest, both
# via READ and STREAM, on a zero-byte file.

my %EMPTY_DIGEST = (
    sha256 => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    sha512 => 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce'
            . '47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e',
    sha1   => 'da39a3ee5e6b4b0d3255bfef95601890afd80709',
    md5    => 'd41d8cd98f00b204e9800998ecf8427e',
    crc32  => '00000000',
);

my ($fh, $path) = tempfile(UNLINK => 1);
close $fh;
ok(-e $path && -z $path, 'fixture is a zero-byte file');

# READ phase, single algo at a time.
for my $algo (sort keys %EMPTY_DIGEST) {
    my $d;
    my $bytes = file_slurp($path,
        plugin => 'hash', algo => $algo, into => \$d);
    is($bytes, '', "READ on empty: bytes empty ($algo)");
    is($d, $EMPTY_DIGEST{$algo}, "READ on empty: $algo digest matches");
}

# Multi-algo on empty.
{
    my %h;
    file_slurp($path,
        plugin => 'hash',
        algos  => [qw(sha256 md5 crc32)],
        into   => \%h);
    is($h{sha256}, $EMPTY_DIGEST{sha256}, 'multi-algo on empty: sha256');
    is($h{md5},    $EMPTY_DIGEST{md5},    'multi-algo on empty: md5');
    is($h{crc32},  $EMPTY_DIGEST{crc32},  'multi-algo on empty: crc32');
}

# STREAM on empty - the dispatcher feeds zero chunks and a final
# eof=1 flush. The digest should still equal the empty-string digest.
{
    my $d;
    File::Raw::each_line($path, sub {},
        plugin => 'hash', algo => 'sha256', into => \$d);
    is($d, $EMPTY_DIGEST{sha256}, 'STREAM on empty file: sha256 of empty');
}

done_testing;
