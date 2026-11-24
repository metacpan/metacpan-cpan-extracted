package Google::Firestore::V1::BloomFilter;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvZmlyZXN0b3JlL3YxL2Jsb29tX2ZpbHRlci5wcm90bxITZ29vZ2xlLmZpcmVz
dG9yZS52MSI/CgtCaXRTZXF1ZW5jZRIWCgZiaXRtYXAYASABKAxSBmJpdG1hcBIYCgdwYWRk
aW5nGAIgASgFUgdwYWRkaW5nImIKC0Jsb29tRmlsdGVyEjQKBGJpdHMYASABKAsyIC5nb29n
bGUuZmlyZXN0b3JlLnYxLkJpdFNlcXVlbmNlUgRiaXRzEh0KCmhhc2hfY291bnQYAiABKAVS
CWhhc2hDb3VudELIAQoXY29tLmdvb2dsZS5maXJlc3RvcmUudjFCEEJsb29tRmlsdGVyUHJv
dG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYXBpdjEvZmlyZXN0b3JlcGI7
ZmlyZXN0b3JlcGKiAgRHQ0ZTqgIZR29vZ2xlLkNsb3VkLkZpcmVzdG9yZS5WMcoCGUdvb2ds
ZVxDbG91ZFxGaXJlc3RvcmVcVjHqAhxHb29nbGU6OkNsb3VkOjpGaXJlc3RvcmU6OlYxSuwV
CgYSBA4ASAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwK
CAoBCBIDEgA2CgkKAgglEgMSADYKCAoBCBIDEwBSCgkKAggLEgMTAFIKCAoBCBIDFAAiCgkK
AggKEgMUACIKCAoBCBIDFQAxCgkKAggIEgMVADEKCAoBCBIDFgAwCgkKAggBEgMWADAKCAoB
CBIDFwAiCgkKAggkEgMXACIKCAoBCBIDGAA2CgkKAggpEgMYADYKCAoBCBIDGQA1CgkKAggt
EgMZADUK3gYKAgQAEgQqADMBGtEGIEEgc2VxdWVuY2Ugb2YgYml0cywgZW5jb2RlZCBpbiBh
IGJ5dGUgYXJyYXkuCgogRWFjaCBieXRlIGluIHRoZSBgYml0bWFwYCBieXRlIGFycmF5IHN0
b3JlcyA4IGJpdHMgb2YgdGhlIHNlcXVlbmNlLiBUaGUgb25seQogZXhjZXB0aW9uIGlzIHRo
ZSBsYXN0IGJ5dGUsIHdoaWNoIG1heSBzdG9yZSA4IF9vciBmZXdlcl8gYml0cy4gVGhlIGBw
YWRkaW5nYAogZGVmaW5lcyB0aGUgbnVtYmVyIG9mIGJpdHMgb2YgdGhlIGxhc3QgYnl0ZSB0
byBiZSBpZ25vcmVkIGFzICJwYWRkaW5nIi4gVGhlCiB2YWx1ZXMgb2YgdGhlc2UgInBhZGRp
bmciIGJpdHMgYXJlIHVuc3BlY2lmaWVkIGFuZCBtdXN0IGJlIGlnbm9yZWQuCgogVG8gcmV0
cmlldmUgdGhlIGZpcnN0IGJpdCwgYml0IDAsIGNhbGN1bGF0ZTogYChiaXRtYXBbMF0gJiAw
eDAxKSAhPSAwYC4KIFRvIHJldHJpZXZlIHRoZSBzZWNvbmQgYml0LCBiaXQgMSwgY2FsY3Vs
YXRlOiBgKGJpdG1hcFswXSAmIDB4MDIpICE9IDBgLgogVG8gcmV0cmlldmUgdGhlIHRoaXJk
IGJpdCwgYml0IDIsIGNhbGN1bGF0ZTogYChiaXRtYXBbMF0gJiAweDA0KSAhPSAwYC4KIFRv
IHJldHJpZXZlIHRoZSBmb3VydGggYml0LCBiaXQgMywgY2FsY3VsYXRlOiBgKGJpdG1hcFsw
XSAmIDB4MDgpICE9IDBgLgogVG8gcmV0cmlldmUgYml0IG4sIGNhbGN1bGF0ZTogYChiaXRt
YXBbbiAvIDhdICYgKDB4MDEgPDwgKG4gJSA4KSkpICE9IDBgLgoKIFRoZSAic2l6ZSIgb2Yg
YSBgQml0U2VxdWVuY2VgICh0aGUgbnVtYmVyIG9mIGJpdHMgaXQgY29udGFpbnMpIGlzIGNh
bGN1bGF0ZWQKIGJ5IHRoaXMgZm9ybXVsYTogYChiaXRtYXAubGVuZ3RoICogOCkgLSBwYWRk
aW5nYC4KCgoKAwQAARIDKggTClIKBAQAAgASAy0CExpFIFRoZSBieXRlcyB0aGF0IGVuY29k
ZSB0aGUgYml0IHNlcXVlbmNlLgogTWF5IGhhdmUgYSBsZW5ndGggb2YgemVyby4KCgwKBQQA
AgAFEgMtAgcKDAoFBAACAAESAy0IDgoMCgUEAAIAAxIDLRESCtMBCgQEAAIBEgMyAhQaxQEg
VGhlIG51bWJlciBvZiBiaXRzIG9mIHRoZSBsYXN0IGJ5dGUgaW4gYGJpdG1hcGAgdG8gaWdu
b3JlIGFzICJwYWRkaW5nIi4KIElmIHRoZSBsZW5ndGggb2YgYGJpdG1hcGAgaXMgemVybywg
dGhlbiB0aGlzIHZhbHVlIG11c3QgYmUgYDBgLgogT3RoZXJ3aXNlLCB0aGlzIHZhbHVlIG11
c3QgYmUgYmV0d2VlbiAwIGFuZCA3LCBpbmNsdXNpdmUuCgoMCgUEAAIBBRIDMgIHCgwKBQQA
AgEBEgMyCA8KDAoFBAACAQMSAzISEwrCBAoCBAESBEIASAEatQQgQSBibG9vbSBmaWx0ZXIg
KGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL0Jsb29tX2ZpbHRlcikuCgogVGhlIGJs
b29tIGZpbHRlciBoYXNoZXMgdGhlIGVudHJpZXMgd2l0aCBNRDUgYW5kIHRyZWF0cyB0aGUg
cmVzdWx0aW5nIDEyOC1iaXQKIGhhc2ggYXMgMiBkaXN0aW5jdCA2NC1iaXQgaGFzaCB2YWx1
ZXMsIGludGVycHJldGVkIGFzIHVuc2lnbmVkIGludGVnZXJzCiB1c2luZyAyJ3MgY29tcGxl
bWVudCBlbmNvZGluZy4KCiBUaGVzZSB0d28gaGFzaCB2YWx1ZXMsIG5hbWVkIGBoMWAgYW5k
IGBoMmAsIGFyZSB0aGVuIHVzZWQgdG8gY29tcHV0ZSB0aGUKIGBoYXNoX2NvdW50YCBoYXNo
IHZhbHVlcyB1c2luZyB0aGUgZm9ybXVsYSwgc3RhcnRpbmcgYXQgYGk9MGA6CgogICAgIGgo
aSkgPSBoMSArIChpICogaDIpCgogVGhlc2UgcmVzdWx0aW5nIHZhbHVlcyBhcmUgdGhlbiB0
YWtlbiBtb2R1bG8gdGhlIG51bWJlciBvZiBiaXRzIGluIHRoZSBibG9vbQogZmlsdGVyIHRv
IGdldCB0aGUgYml0cyBvZiB0aGUgYmxvb20gZmlsdGVyIHRvIHRlc3QgZm9yIHRoZSBnaXZl
biBlbnRyeS4KCgoKAwQBARIDQggTCiUKBAQBAgASA0QCFxoYIFRoZSBibG9vbSBmaWx0ZXIg
ZGF0YS4KCgwKBQQBAgAGEgNEAg0KDAoFBAECAAESA0QOEgoMCgUEAQIAAxIDRBUWCjoKBAQB
AgESA0cCFxotIFRoZSBudW1iZXIgb2YgaGFzaGVzIHVzZWQgYnkgdGhlIGFsZ29yaXRobS4K
CgwKBQQBAgEFEgNHAgcKDAoFBAECAQESA0cIEgoMCgUEAQIBAxIDRxUWYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::BloomFilter::BitSequence ===
    # Fields for BitSequence
    # Field: bitmap Type: 12 ()
    # Field: padding Type: 5 ()

# === Message: Google::Firestore::V1::BloomFilter::BloomFilter ===
    # Fields for BloomFilter
    # Field: bits Type: 11 (.google.firestore.v1.BitSequence)
    # Field: hash_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::BloomFilter - Compiled Protocol Buffers messages for google/firestore/v1/bloom_filter.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::BloomFilter;

    my $msg = Google::Firestore::V1::BloomFilter::BitSequence->new({
        bitmap => $bitmap,
        padding => $padding,
    });

    # Read or update a field
    my $val = $msg->bitmap();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::BloomFilter::BitSequence->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/bloom_filter.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::BloomFilter::BitSequence

A sequence of bits, encoded in a byte array.

Each byte in the `bitmap` byte array stores 8 bits of the sequence. The only
exception is the last byte, which may store 8 _or fewer_ bits. The `padding`
defines the number of bits of the last byte to be ignored as "padding". The
values of these "padding" bits are unspecified and must be ignored.

To retrieve the first bit, bit 0, calculate: `(bitmap[0] & 0x01) != 0`.
To retrieve the second bit, bit 1, calculate: `(bitmap[0] & 0x02) != 0`.
To retrieve the third bit, bit 2, calculate: `(bitmap[0] & 0x04) != 0`.
To retrieve the fourth bit, bit 3, calculate: `(bitmap[0] & 0x08) != 0`.
To retrieve bit n, calculate: `(bitmap[n / 8] & (0x01 << (n % 8))) != 0`.

The "size" of a `BitSequence` (the number of bits it contains) is calculated
by this formula: `(bitmap.length * 8) - padding`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bitmap() >> / C<< $msg->bitmap($value) >>

Type: C<Bytes>

The bytes that encode the bit sequence.
May have a length of zero.

=item * C<< $msg->padding() >> / C<< $msg->padding($value) >>

Type: C<Int32>

The number of bits of the last byte in `bitmap` to ignore as "padding".
If the length of `bitmap` is zero, then this value must be `0`.
Otherwise, this value must be between 0 and 7, inclusive.

=back

=head2 Google::Firestore::V1::BloomFilter::BloomFilter

A bloom filter (https://en.wikipedia.org/wiki/Bloom_filter).

The bloom filter hashes the entries with MD5 and treats the resulting 128-bit
hash as 2 distinct 64-bit hash values, interpreted as unsigned integers
using 2's complement encoding.

These two hash values, named `h1` and `h2`, are then used to compute the
`hash_count` hash values using the formula, starting at `i=0`:

    h(i) = h1 + (i * h2)

These resulting values are then taken modulo the number of bits in the bloom
filter to get the bits of the bloom filter to test for the given entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bits() >> / C<< $msg->bits($value) >>

Type: C<Message> (L<Google::Firestore::V1::BloomFilter::BitSequence>)

The bloom filter data.

=item * C<< $msg->hash_count() >> / C<< $msg->hash_count($value) >>

Type: C<Int32>

The number of hashes used by the algorithm.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::BloomFilter::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
