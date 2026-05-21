#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Every misuse should croak with a clear, plugin-named message.

my ($fh, $path) = tempfile(UNLINK => 1);
binmode $fh;
print $fh 'abc';
close $fh;

# Missing 'into'.
{
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'sha256');
        ''
    } || $@;
    like($err, qr/'into' is required/, 'missing into croaks');
}

# 'into' undef.
{
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'sha256', into => undef);
        ''
    } || $@;
    like($err, qr/'into' is required/, 'undef into croaks');
}

# 'into' non-ref.
{
    my $err = eval {
        my $not_a_ref = 'just a string';
        file_slurp($path, plugin => 'hash', algo => 'sha256',
                   into => $not_a_ref);
        ''
    } || $@;
    like($err, qr/'into' must be a reference/, 'non-ref into croaks');
}

# 'into' wrong shape: hash ref for single-algo.
{
    my %h;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'sha256',
                   into => \%h);
        ''
    } || $@;
    like($err, qr/SCALAR ref for single-algo/, 'hash-ref into for single-algo croaks');
}

# 'into' wrong shape: scalar ref for multi-algo.
{
    my $s;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algos => [qw(sha256 md5)],
                   into => \$s);
        ''
    } || $@;
    like($err, qr/hash ref when 'algos' is used/,
         'scalar-ref into for multi-algo croaks');
}

# Unknown algo.
{
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'sha9999',
                   into => \$d);
        ''
    } || $@;
    like($err, qr/unknown algo 'sha9999'/, 'unknown algo croaks');
}

# Unknown format.
{
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'sha256',
                   format => 'wat', into => \$d);
        ''
    } || $@;
    like($err, qr/unknown format 'wat'/, 'unknown format croaks');
}

# algo + algos mutually exclusive.
{
    my %h;
    my $err = eval {
        file_slurp($path, plugin => 'hash',
            algo  => 'sha256',
            algos => [qw(md5)],
            into  => \%h);
        ''
    } || $@;
    like($err, qr/mutually exclusive/, 'algo + algos together croaks');
}

# Empty algos.
{
    my %h;
    my $err = eval {
        file_slurp($path, plugin => 'hash',
            algos => [],
            into  => \%h);
        ''
    } || $@;
    like($err, qr/'algos' arrayref is empty/, 'empty algos croaks');
}

# Unknown option key.
{
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash',
            algo    => 'sha256',
            into    => \$d,
            wibble  => 1);
        ''
    } || $@;
    like($err, qr/unknown option 'wibble'/, 'unknown option croaks');
}

# 'algos' not an arrayref.
{
    my %h;
    my $err = eval {
        file_slurp($path, plugin => 'hash',
            algos => 'sha256',
            into  => \%h);
        ''
    } || $@;
    like($err, qr/'algos' must be an arrayref/, 'non-arrayref algos croaks');
}

# hmac_key as a reference croaks (must be a byte string).
{
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'sha256',
                   hmac_key => [1, 2, 3], into => \$d);
        ''
    } || $@;
    like($err, qr/'hmac_key' must be a byte string/,
         'hmac_key arrayref croaks');
}

# xxh64_seed as a reference croaks.
{
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'xxh64',
                   xxh64_seed => [1], into => \$d);
        ''
    } || $@;
    like($err, qr/'xxh64_seed' must be an integer/,
         'xxh64_seed reference croaks');
}

# hmac_key + non-HMAC-able algo croaks.
{
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => 'crc32',
                   hmac_key => 'k', into => \$d);
        ''
    } || $@;
    like($err, qr/HMAC is not defined for algo 'crc32'/,
         'hmac_key with crc32 croaks');
}

done_testing;
