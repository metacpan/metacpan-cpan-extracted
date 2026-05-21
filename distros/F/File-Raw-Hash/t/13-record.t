#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;
# We cross-check digests against the plugin's own READ phase rather
# than against a separate Digest:: module - this keeps the test
# self-contained and exercises only the code under test.

# RECORD phase wires the plugin's record_fn through File::Raw's
# file_plugin_dispatch_record entry point. File::Raw 0.11 does not
# expose a public per-record iterator yet, so the test invokes the
# dispatcher via the plugin's private _test_record_one helper. Same
# code path that future File::Raw releases will use.

my @RECORDS = ('first line', 'second line', 'third line', '');

# Single algo: digest pushed per record.
{
    my @digests;
    for my $rec (@RECORDS) {
        my $back = File::Raw::Hash::_test_record_one($rec,
            algo => 'sha256', into => \@digests);
        is($back, $rec, "record passthrough preserves '$rec'");
    }

    is(scalar @digests, scalar @RECORDS,
       'one digest per record was pushed');

    # Cross-check against READ-phase digest of each record.
    for my $i (0 .. $#RECORDS) {
        my ($fh, $path) = tempfile(UNLINK => 1);
        binmode $fh;
        print $fh $RECORDS[$i];
        close $fh;
        my $expected;
        file_slurp($path, plugin => 'hash', algo => 'sha256',
                   into => \$expected);
        is($digests[$i], $expected,
           "RECORD digest #$i matches READ-phase digest of same bytes");
    }
}

# Multi-algo: each record produces a hashref-of-digests.
{
    my @per_record;
    for my $rec (@RECORDS[0, 1]) {
        File::Raw::Hash::_test_record_one($rec,
            algos => [qw(sha256 md5 crc32)],
            into  => \@per_record);
    }
    is(scalar @per_record, 2, 'two records, two hashref entries');
    for my $entry (@per_record) {
        is(ref $entry, 'HASH', 'multi-algo RECORD entry is a hashref');
        is_deeply([sort keys %$entry], [qw(crc32 md5 sha256)],
                  'hashref has all requested algos');
    }
    # Check first entry's sha256 against READ-phase digest of "first line".
    {
        my ($fh, $path) = tempfile(UNLINK => 1);
        binmode $fh;
        print $fh 'first line';
        close $fh;
        my $expected;
        file_slurp($path, plugin => 'hash', algo => 'sha256',
                   into => \$expected);
        is($per_record[0]{sha256}, $expected,
           'multi-algo RECORD entry sha256 matches READ-phase digest');
    }
}

# RECORD requires `into` to be an arrayref; scalar / hash refs croak.
{
    my $s;
    my $err = eval {
        File::Raw::Hash::_test_record_one('rec',
            algo => 'sha256', into => \$s);
        ''
    } || $@;
    like($err, qr/in record phase, 'into' must be an ARRAY ref/,
         'RECORD with scalar-ref into croaks');
}
{
    my %h;
    my $err = eval {
        File::Raw::Hash::_test_record_one('rec',
            algos => [qw(sha256 md5)], into => \%h);
        ''
    } || $@;
    like($err, qr/in record phase, 'into' must be an ARRAY ref/,
         'RECORD with hash-ref into croaks even for multi-algo');
}

# RECORD with HMAC option is honoured.
{
    my @macs;
    File::Raw::Hash::_test_record_one('Hi There',
        algo     => 'sha256',
        hmac_key => "\x0b" x 20,
        into     => \@macs);
    is($macs[0], 'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7',
       'RECORD honours hmac_key (RFC 4231 #1)');
}

# RECORD with raw format produces 32 bytes of binary.
{
    my @ds;
    File::Raw::Hash::_test_record_one('abc',
        algo => 'sha256', format => 'raw', into => \@ds);
    is(length $ds[0], 32, 'RECORD raw format yields 32 bytes for sha256');
}

done_testing;
