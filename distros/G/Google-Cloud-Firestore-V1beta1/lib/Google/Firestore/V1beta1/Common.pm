package Google::Firestore::V1beta1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvZmlyZXN0b3JlL3YxYmV0YTEvY29tbW9uLnByb3RvEhhnb29nbGUuZmlyZXN0
b3JlLnYxYmV0YTEaH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iLwoMRG9jdW1l
bnRNYXNrEh8KC2ZpZWxkX3BhdGhzGAEgAygJUgpmaWVsZFBhdGhzInkKDFByZWNvbmRpdGlv
bhIYCgZleGlzdHMYASABKAhIAFIGZXhpc3RzEj0KC3VwZGF0ZV90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUgp1cGRhdGVUaW1lQhAKDmNvbmRpdGlvbl90eXBl
IuQCChJUcmFuc2FjdGlvbk9wdGlvbnMSVAoJcmVhZF9vbmx5GAIgASgLMjUuZ29vZ2xlLmZp
cmVzdG9yZS52MWJldGExLlRyYW5zYWN0aW9uT3B0aW9ucy5SZWFkT25seUgAUghyZWFkT25s
eRJXCgpyZWFkX3dyaXRlGAMgASgLMjYuZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLlRyYW5z
YWN0aW9uT3B0aW9ucy5SZWFkV3JpdGVIAFIJcmVhZFdyaXRlGjgKCVJlYWRXcml0ZRIrChFy
ZXRyeV90cmFuc2FjdGlvbhgBIAEoDFIQcmV0cnlUcmFuc2FjdGlvbhpdCghSZWFkT25seRI5
CglyZWFkX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSCHJlYWRU
aW1lQhYKFGNvbnNpc3RlbmN5X3NlbGVjdG9yQgYKBG1vZGVC3AEKHGNvbS5nb29nbGUuZmly
ZXN0b3JlLnYxYmV0YTFCC0NvbW1vblByb3RvUAFaQGNsb3VkLmdvb2dsZS5jb20vZ28vZmly
ZXN0b3JlL2FwaXYxYmV0YTEvZmlyZXN0b3JlcGI7ZmlyZXN0b3JlcGKiAgRHQ0ZTqgIeR29v
Z2xlLkNsb3VkLkZpcmVzdG9yZS5WMUJldGExygIeR29vZ2xlXENsb3VkXEZpcmVzdG9yZVxW
MWJldGEx6gIhR29vZ2xlOjpDbG91ZDo6RmlyZXN0b3JlOjpWMWJldGExSqQVCgYSBA4AUQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIA
KQoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAFcKCQoCCAsSAxUAVwoICgEIEgMWACIK
CQoCCAoSAxYAIgoICgEIEgMXACwKCQoCCAgSAxcALAoICgEIEgMYADUKCQoCCAESAxgANQoI
CgEIEgMZACIKCQoCCCQSAxkAIgoICgEIEgMaADsKCQoCCCkSAxoAOwoICgEIEgMbADoKCQoC
CC0SAxsAOgrYAgoCBAASBCIAJgEaywIgQSBzZXQgb2YgZmllbGQgcGF0aHMgb24gYSBkb2N1
bWVudC4KIFVzZWQgdG8gcmVzdHJpY3QgYSBnZXQgb3IgdXBkYXRlIG9wZXJhdGlvbiBvbiBh
IGRvY3VtZW50IHRvIGEgc3Vic2V0IG9mIGl0cwogZmllbGRzLgogVGhpcyBpcyBkaWZmZXJl
bnQgZnJvbSBzdGFuZGFyZCBmaWVsZCBtYXNrcywgYXMgdGhpcyBpcyBhbHdheXMgc2NvcGVk
IHRvIGEKIFtEb2N1bWVudF1bZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLkRvY3VtZW50XSwg
YW5kIHRha2VzIGluIGFjY291bnQgdGhlIGR5bmFtaWMgbmF0dXJlIG9mIFtWYWx1ZV1bZ29v
Z2xlLmZpcmVzdG9yZS52MWJldGExLlZhbHVlXS4KCgoKAwQAARIDIggUCpgBCgQEAAIAEgMl
AiIaigEgVGhlIGxpc3Qgb2YgZmllbGQgcGF0aHMgaW4gdGhlIG1hc2suIFNlZSBbRG9jdW1l
bnQuZmllbGRzXVtnb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuRG9jdW1lbnQuZmllbGRzXSBm
b3IgYSBmaWVsZAogcGF0aCBzeW50YXggcmVmZXJlbmNlLgoKDAoFBAACAAQSAyUCCgoMCgUE
AAIABRIDJQsRCgwKBQQAAgABEgMlEh0KDAoFBAACAAMSAyUgIQpMCgIEARIEKQA0ARpAIEEg
cHJlY29uZGl0aW9uIG9uIGEgZG9jdW1lbnQsIHVzZWQgZm9yIGNvbmRpdGlvbmFsIG9wZXJh
dGlvbnMuCgoKCgMEAQESAykIFAopCgQEAQgAEgQrAjMDGhsgVGhlIHR5cGUgb2YgcHJlY29u
ZGl0aW9uLgoKDAoFBAEIAAESAysIFgp8CgQEAQIAEgMuBBQabyBXaGVuIHNldCB0byBgdHJ1
ZWAsIHRoZSB0YXJnZXQgZG9jdW1lbnQgbXVzdCBleGlzdC4KIFdoZW4gc2V0IHRvIGBmYWxz
ZWAsIHRoZSB0YXJnZXQgZG9jdW1lbnQgbXVzdCBub3QgZXhpc3QuCgoMCgUEAQIABRIDLgQI
CgwKBQQBAgABEgMuCQ8KDAoFBAECAAMSAy4SEwphCgQEAQIBEgMyBC4aVCBXaGVuIHNldCwg
dGhlIHRhcmdldCBkb2N1bWVudCBtdXN0IGV4aXN0IGFuZCBoYXZlIGJlZW4gbGFzdCB1cGRh
dGVkIGF0CiB0aGF0IHRpbWUuCgoMCgUEAQIBBhIDMgQdCgwKBQQBAgEBEgMyHikKDAoFBAEC
AQMSAzIsLQo1CgIEAhIENwBRARopIE9wdGlvbnMgZm9yIGNyZWF0aW5nIGEgbmV3IHRyYW5z
YWN0aW9uLgoKCgoDBAIBEgM3CBoKVwoEBAIDABIEOQI8AxpJIE9wdGlvbnMgZm9yIGEgdHJh
bnNhY3Rpb24gdGhhdCBjYW4gYmUgdXNlZCB0byByZWFkIGFuZCB3cml0ZSBkb2N1bWVudHMu
CgoMCgUEAgMAARIDOQoTCjIKBgQCAwACABIDOwQgGiMgQW4gb3B0aW9uYWwgdHJhbnNhY3Rp
b24gdG8gcmV0cnkuCgoOCgcEAgMAAgAFEgM7BAkKDgoHBAIDAAIAARIDOwobCg4KBwQCAwAC
AAMSAzseHwpSCgQEAgMBEgQ/AkcDGkQgT3B0aW9ucyBmb3IgYSB0cmFuc2FjdGlvbiB0aGF0
IGNhbiBvbmx5IGJlIHVzZWQgdG8gcmVhZCBkb2N1bWVudHMuCgoMCgUEAgMBARIDPwoSCmkK
BgQCAwEIABIEQgRGBRpZIFRoZSBjb25zaXN0ZW5jeSBtb2RlIGZvciB0aGlzIHRyYW5zYWN0
aW9uLiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byBzdHJvbmcKIGNvbnNpc3RlbmN5LgoKDgoH
BAIDAQgAARIDQgoeClsKBgQCAwECABIDRQYuGkwgUmVhZHMgZG9jdW1lbnRzIGF0IHRoZSBn
aXZlbiB0aW1lLgogVGhpcyBtYXkgbm90IGJlIG9sZGVyIHRoYW4gNjAgc2Vjb25kcy4KCg4K
BwQCAwECAAYSA0UGHwoOCgcEAgMBAgABEgNFICkKDgoHBAIDAQIAAxIDRSwtCiwKBAQCCAAS
BEoCUAMaHiBUaGUgbW9kZSBvZiB0aGUgdHJhbnNhY3Rpb24uCgoMCgUEAggAARIDSggMCkQK
BAQCAgASA0wEGxo3IFRoZSB0cmFuc2FjdGlvbiBjYW4gb25seSBiZSB1c2VkIGZvciByZWFk
IG9wZXJhdGlvbnMuCgoMCgUEAgIABhIDTAQMCgwKBQQCAgABEgNMDRYKDAoFBAICAAMSA0wZ
GgpOCgQEAgIBEgNPBB0aQSBUaGUgdHJhbnNhY3Rpb24gY2FuIGJlIHVzZWQgZm9yIGJvdGgg
cmVhZCBhbmQgd3JpdGUgb3BlcmF0aW9ucy4KCgwKBQQCAgEGEgNPBA0KDAoFBAICAQESA08O
GAoMCgUEAgIBAxIDTxscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1beta1::Common::DocumentMask ===
    # Fields for DocumentMask
    # Field: field_paths Type: 9 ()

# === Message: Google::Firestore::V1beta1::Common::Precondition ===
    # Fields for Precondition
    # Field: exists Type: 8 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1beta1::Common::TransactionOptions ===
    # Fields for TransactionOptions
    # Field: read_only Type: 11 (.google.firestore.v1beta1.TransactionOptions.ReadOnly)
    # Field: read_write Type: 11 (.google.firestore.v1beta1.TransactionOptions.ReadWrite)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1beta1::Common - Compiled Protocol Buffers messages for google/firestore/v1beta1/common.proto

=head1 SYNOPSIS

    use Google::Firestore::V1beta1::Common;

    my $msg = Google::Firestore::V1beta1::Common::DocumentMask->new({
        field_paths => $field_paths,
    });

    # Read or update a field
    my $val = $msg->field_paths();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1beta1::Common::DocumentMask->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1beta1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1beta1::Common::DocumentMask

A set of field paths on a document.
Used to restrict a get or update operation on a document to a subset of its
fields.
This is different from standard field masks, as this is always scoped to a
[Document][google.firestore.v1beta1.Document], and takes in account the dynamic nature of [Value][google.firestore.v1beta1.Value].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field_paths() >> / C<< $msg->field_paths($value) >>

Type: C<String>

The list of field paths in the mask. See [Document.fields][google.firestore.v1beta1.Document.fields] for a field
path syntax reference.

=back

=head2 Google::Firestore::V1beta1::Common::Precondition

A precondition on a document, used for conditional operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exists() >> / C<< $msg->exists($value) >>

Type: C<Bool>

When set to `true`, the target document must exist.
When set to `false`, the target document must not exist.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

When set, the target document must exist and have been last updated at
that time.

=back

=head2 Google::Firestore::V1beta1::Common::TransactionOptions

Options for creating a new transaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->read_only() >> / C<< $msg->read_only($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Common::TransactionOptions::ReadOnly>)

The transaction can only be used for read operations.

=item * C<< $msg->read_write() >> / C<< $msg->read_write($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Common::TransactionOptions::ReadWrite>)

The transaction can be used for both read and write operations.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1beta1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
