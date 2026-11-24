package Google::Firestore::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvZmlyZXN0b3JlL3YxL2NvbW1vbi5wcm90bxITZ29vZ2xlLmZpcmVzdG9yZS52
MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byIvCgxEb2N1bWVudE1hc2sSHwoLZmllbGRfcGF0aHMYASADKAlSCmZp
ZWxkUGF0aHMieQoMUHJlY29uZGl0aW9uEhgKBmV4aXN0cxgBIAEoCEgAUgZleGlzdHMSPQoL
dXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSCnVwZGF0
ZVRpbWVCEAoOY29uZGl0aW9uX3R5cGUimgQKElRyYW5zYWN0aW9uT3B0aW9ucxJPCglyZWFk
X29ubHkYAiABKAsyMC5nb29nbGUuZmlyZXN0b3JlLnYxLlRyYW5zYWN0aW9uT3B0aW9ucy5S
ZWFkT25seUgAUghyZWFkT25seRJSCgpyZWFkX3dyaXRlGAMgASgLMjEuZ29vZ2xlLmZpcmVz
dG9yZS52MS5UcmFuc2FjdGlvbk9wdGlvbnMuUmVhZFdyaXRlSABSCXJlYWRXcml0ZRqhAQoJ
UmVhZFdyaXRlEisKEXJldHJ5X3RyYW5zYWN0aW9uGAEgASgMUhByZXRyeVRyYW5zYWN0aW9u
EmcKEGNvbmN1cnJlbmN5X21vZGUYAiABKA4yNy5nb29nbGUuZmlyZXN0b3JlLnYxLlRyYW5z
YWN0aW9uT3B0aW9ucy5Db25jdXJyZW5jeU1vZGVCA+BBAVIPY29uY3VycmVuY3lNb2RlGl0K
CFJlYWRPbmx5EjkKCXJlYWRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBIAFIIcmVhZFRpbWVCFgoUY29uc2lzdGVuY3lfc2VsZWN0b3IiVAoPQ29uY3VycmVuY3lN
b2RlEiAKHENPTkNVUlJFTkNZX01PREVfVU5TUEVDSUZJRUQQABIOCgpPUFRJTUlTVElDEAES
DwoLUEVTU0lNSVNUSUMQAkIGCgRtb2RlIjgKDlJlcXVlc3RPcHRpb25zEiYKDHJlcXVlc3Rf
dGFncxgBIAMoCUID4EEBUgtyZXF1ZXN0VGFnc0LDAQoXY29tLmdvb2dsZS5maXJlc3RvcmUu
djFCC0NvbW1vblByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZmlyZXN0b3JlL2FwaXYx
L2ZpcmVzdG9yZXBiO2ZpcmVzdG9yZXBiogIER0NGU6oCGUdvb2dsZS5DbG91ZC5GaXJlc3Rv
cmUuVjHKAhlHb29nbGVcQ2xvdWRcRmlyZXN0b3JlXFYx6gIcR29vZ2xlOjpDbG91ZDo6Rmly
ZXN0b3JlOjpWMUqbHwoGEgQOAHQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVADYKCQoCCCUSAxUA
NgoICgEIEgMWAFIKCQoCCAsSAxYAUgoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYACwK
CQoCCAgSAxgALAoICgEIEgMZADAKCQoCCAESAxkAMAoICgEIEgMaACIKCQoCCCQSAxoAIgoI
CgEIEgMbADYKCQoCCCkSAxsANgoICgEIEgMcADUKCQoCCC0SAxwANQrPAgoCBAASBCQAKQEa
wgIgQSBzZXQgb2YgZmllbGQgcGF0aHMgb24gYSBkb2N1bWVudC4KIFVzZWQgdG8gcmVzdHJp
Y3QgYSBnZXQgb3IgdXBkYXRlIG9wZXJhdGlvbiBvbiBhIGRvY3VtZW50IHRvIGEgc3Vic2V0
IG9mIGl0cwogZmllbGRzLgogVGhpcyBpcyBkaWZmZXJlbnQgZnJvbSBzdGFuZGFyZCBmaWVs
ZCBtYXNrcywgYXMgdGhpcyBpcyBhbHdheXMgc2NvcGVkIHRvIGEKIFtEb2N1bWVudF1bZ29v
Z2xlLmZpcmVzdG9yZS52MS5Eb2N1bWVudF0sIGFuZCB0YWtlcyBpbiBhY2NvdW50IHRoZSBk
eW5hbWljCiBuYXR1cmUgb2YgW1ZhbHVlXVtnb29nbGUuZmlyZXN0b3JlLnYxLlZhbHVlXS4K
CgoKAwQAARIDJAgUCpQBCgQEAAIAEgMoAiIahgEgVGhlIGxpc3Qgb2YgZmllbGQgcGF0aHMg
aW4gdGhlIG1hc2suIFNlZQogW0RvY3VtZW50LmZpZWxkc11bZ29vZ2xlLmZpcmVzdG9yZS52
MS5Eb2N1bWVudC5maWVsZHNdIGZvciBhIGZpZWxkIHBhdGgKIHN5bnRheCByZWZlcmVuY2Uu
CgoMCgUEAAIABBIDKAIKCgwKBQQAAgAFEgMoCxEKDAoFBAACAAESAygSHQoMCgUEAAIAAxID
KCAhCkwKAgQBEgQsADcBGkAgQSBwcmVjb25kaXRpb24gb24gYSBkb2N1bWVudCwgdXNlZCBm
b3IgY29uZGl0aW9uYWwgb3BlcmF0aW9ucy4KCgoKAwQBARIDLAgUCikKBAQBCAASBC4CNgMa
GyBUaGUgdHlwZSBvZiBwcmVjb25kaXRpb24uCgoMCgUEAQgAARIDLggWCnwKBAQBAgASAzEE
FBpvIFdoZW4gc2V0IHRvIGB0cnVlYCwgdGhlIHRhcmdldCBkb2N1bWVudCBtdXN0IGV4aXN0
LgogV2hlbiBzZXQgdG8gYGZhbHNlYCwgdGhlIHRhcmdldCBkb2N1bWVudCBtdXN0IG5vdCBl
eGlzdC4KCgwKBQQBAgAFEgMxBAgKDAoFBAECAAESAzEJDwoMCgUEAQIAAxIDMRITCogBCgQE
AQIBEgM1BC4aeyBXaGVuIHNldCwgdGhlIHRhcmdldCBkb2N1bWVudCBtdXN0IGV4aXN0IGFu
ZCBoYXZlIGJlZW4gbGFzdCB1cGRhdGVkIGF0CiB0aGF0IHRpbWUuIFRpbWVzdGFtcCBtdXN0
IGJlIG1pY3Jvc2Vjb25kIGFsaWduZWQuCgoMCgUEAQIBBhIDNQQdCgwKBQQBAgEBEgM1HikK
DAoFBAECAQMSAzUsLQo1CgIEAhIEOgBuARopIE9wdGlvbnMgZm9yIGNyZWF0aW5nIGEgbmV3
IHRyYW5zYWN0aW9uLgoKCgoDBAIBEgM6CBoKRgoEBAIEABIEPAJFAxo4IFRoZSB0eXBlIG9m
IGNvbmN1cnJlbmN5IGNvbnRyb2wgbW9kZSBmb3IgdHJhbnNhY3Rpb25zLgoKDAoFBAIEAAES
AzwHFgpYCgYEAgQAAgASAz4EJRpJIFN0YXJ0IHRoZSB0cmFuc2FjdGlvbiB3aXRoIHRoZSBk
YXRhYmFzZS1sZXZlbCBkZWZhdWx0IGNvbmN1cnJlbmN5IG1vZGUuCgoOCgcEAgQAAgABEgM+
BCAKDgoHBAIEAAIAAhIDPiMkCkwKBgQCBAACARIDQQQTGj0gVXNlIG9wdGltaXN0aWMgY29u
Y3VycmVuY3kgY29udHJvbCBmb3IgdGhlIG5ldyB0cmFuc2FjdGlvbi4KCg4KBwQCBAACAQES
A0EEDgoOCgcEAgQAAgECEgNBERIKTQoGBAIEAAICEgNEBBQaPiBVc2UgcGVzc2ltaXN0aWMg
Y29uY3VycmVuY3kgY29udHJvbCBmb3IgdGhlIG5ldyB0cmFuc2FjdGlvbi4KCg4KBwQCBAAC
AgESA0QEDwoOCgcEAgQAAgICEgNEEhMKVwoEBAIDABIESAJWAxpJIE9wdGlvbnMgZm9yIGEg
dHJhbnNhY3Rpb24gdGhhdCBjYW4gYmUgdXNlZCB0byByZWFkIGFuZCB3cml0ZSBkb2N1bWVu
dHMuCgoMCgUEAgMAARIDSAoTCjIKBgQCAwACABIDSgQgGiMgQW4gb3B0aW9uYWwgdHJhbnNh
Y3Rpb24gdG8gcmV0cnkuCgoOCgcEAgMAAgAFEgNKBAkKDgoHBAIDAAIAARIDSgobCg4KBwQC
AwACAAMSA0oeHwr3AgoGBAIDAAIBEgRUBFUxGuYCIE9wdGlvbmFsLiBUaGUgY29uY3VycmVu
Y3kgY29udHJvbCBtb2RlIHRvIHVzZSBmb3IgdGhpcyB0cmFuc2FjdGlvbi4KCiBBIGRhdGFi
YXNlIGlzIGFibGUgdG8gdXNlIGRpZmZlcmVudCBjb25jdXJyZW5jeSBtb2RlcyBmb3IgZGlm
ZmVyZW50CiB0cmFuc2FjdGlvbnMgc2ltdWx0YW5lb3VzbHkuCgogM3JkIHBhcnR5IGF1dGgg
cmVxdWVzdHMgYXJlIG9ubHkgYWxsb3dlZCB0byBjcmVhdGUgb3B0aW1pc3RpYwogcmVhZC13
cml0ZSB0cmFuc2FjdGlvbnMgYW5kIG11c3Qgc3BlY2lmeSB0aGF0IGhlcmUgZXZlbiBpZiB0
aGUKIGRhdGFiYXNlLWxldmVsIHNldHRpbmcgaXMgYWxyZWFkeSBjb25maWd1cmVkIHRvIG9w
dGltaXN0aWMuCgoOCgcEAgMAAgEGEgNUBBMKDgoHBAIDAAIBARIDVBQkCg4KBwQCAwACAQMS
A1QnKAoOCgcEAgMAAgEIEgNVCDAKEQoKBAIDAAIBCJwIABIDVQkvClIKBAQCAwESBFkCZAMa
RCBPcHRpb25zIGZvciBhIHRyYW5zYWN0aW9uIHRoYXQgY2FuIG9ubHkgYmUgdXNlZCB0byBy
ZWFkIGRvY3VtZW50cy4KCgwKBQQCAwEBEgNZChIKaQoGBAIDAQgAEgRcBGMFGlkgVGhlIGNv
bnNpc3RlbmN5IG1vZGUgZm9yIHRoaXMgdHJhbnNhY3Rpb24uIElmIG5vdCBzZXQsIGRlZmF1
bHRzIHRvIHN0cm9uZwogY29uc2lzdGVuY3kuCgoOCgcEAgMBCAABEgNcCh4K7wEKBgQCAwEC
ABIDYgYuGt8BIFJlYWRzIGRvY3VtZW50cyBhdCB0aGUgZ2l2ZW4gdGltZS4KCiBUaGlzIG11
c3QgYmUgYSBtaWNyb3NlY29uZCBwcmVjaXNpb24gdGltZXN0YW1wIHdpdGhpbiB0aGUgcGFz
dCBvbmUKIGhvdXIsIG9yIGlmIFBvaW50LWluLVRpbWUgUmVjb3ZlcnkgaXMgZW5hYmxlZCwg
Y2FuIGFkZGl0aW9uYWxseSBiZSBhCiB3aG9sZSBtaW51dGUgdGltZXN0YW1wIHdpdGhpbiB0
aGUgcGFzdCA3IGRheXMuCgoOCgcEAgMBAgAGEgNiBh8KDgoHBAIDAQIAARIDYiApCg4KBwQC
AwECAAMSA2IsLQosCgQEAggAEgRnAm0DGh4gVGhlIG1vZGUgb2YgdGhlIHRyYW5zYWN0aW9u
LgoKDAoFBAIIAAESA2cIDApECgQEAgIAEgNpBBsaNyBUaGUgdHJhbnNhY3Rpb24gY2FuIG9u
bHkgYmUgdXNlZCBmb3IgcmVhZCBvcGVyYXRpb25zLgoKDAoFBAICAAYSA2kEDAoMCgUEAgIA
ARIDaQ0WCgwKBQQCAgADEgNpGRoKTgoEBAICARIDbAQdGkEgVGhlIHRyYW5zYWN0aW9uIGNh
biBiZSB1c2VkIGZvciBib3RoIHJlYWQgYW5kIHdyaXRlIG9wZXJhdGlvbnMuCgoMCgUEAgIB
BhIDbAQNCgwKBQQCAgEBEgNsDhgKDAoFBAICAQMSA2wbHAorCgIEAxIEcQB0ARofIE9wdGlv
bnMgZm9yIGEgc2VydmVyIHJlcXVlc3QuCgoKCgMEAwESA3EIFgowCgQEAwIAEgNzAkwaIyBU
aGUgcmVxdWVzdCB0YWdzIGZvciB0aGUgcmVxdWVzdC4KCgwKBQQDAgAEEgNzAgoKDAoFBAMC
AAUSA3MLEQoMCgUEAwIAARIDcxIeCgwKBQQDAgADEgNzISIKDAoFBAMCAAgSA3MjSwoPCggE
AwIACJwIABIDcyRKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::Common::DocumentMask ===
    # Fields for DocumentMask
    # Field: field_paths Type: 9 ()

# === Message: Google::Firestore::V1::Common::Precondition ===
    # Fields for Precondition
    # Field: exists Type: 8 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1::Common::TransactionOptions ===
    # Fields for TransactionOptions
    # Field: read_only Type: 11 (.google.firestore.v1.TransactionOptions.ReadOnly)
    # Field: read_write Type: 11 (.google.firestore.v1.TransactionOptions.ReadWrite)

# Enum: TransactionOptions::ConcurrencyMode
our $TransactionOptions_CONCURRENCY_MODE_UNSPECIFIED = 0;
our $TransactionOptions_OPTIMISTIC = 1;
our $TransactionOptions_PESSIMISTIC = 2;

# === Message: Google::Firestore::V1::Common::RequestOptions ===
    # Fields for RequestOptions
    # Field: request_tags Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::Common - Compiled Protocol Buffers messages for google/firestore/v1/common.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::Common;

    my $msg = Google::Firestore::V1::Common::DocumentMask->new({
        field_paths => $field_paths,
    });

    # Read or update a field
    my $val = $msg->field_paths();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::Common::DocumentMask->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::Common::DocumentMask

A set of field paths on a document.
Used to restrict a get or update operation on a document to a subset of its
fields.
This is different from standard field masks, as this is always scoped to a
[Document][google.firestore.v1.Document], and takes in account the dynamic
nature of [Value][google.firestore.v1.Value].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field_paths() >> / C<< $msg->field_paths($value) >>

Type: C<String>

The list of field paths in the mask. See
[Document.fields][google.firestore.v1.Document.fields] for a field path
syntax reference.

=back

=head2 Google::Firestore::V1::Common::Precondition

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
that time. Timestamp must be microsecond aligned.

=back

=head2 Google::Firestore::V1::Common::TransactionOptions

Options for creating a new transaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->read_only() >> / C<< $msg->read_only($value) >>

Type: C<Message> (L<Google::Firestore::V1::Common::TransactionOptions::ReadOnly>)

The transaction can only be used for read operations.

=item * C<< $msg->read_write() >> / C<< $msg->read_write($value) >>

Type: C<Message> (L<Google::Firestore::V1::Common::TransactionOptions::ReadWrite>)

The transaction can be used for both read and write operations.

=back

=head3 Enum: TransactionOptions::ConcurrencyMode

=over 4

=item * C<CONCURRENCY_MODE_UNSPECIFIED> => C<0>

=item * C<OPTIMISTIC> => C<1>

=item * C<PESSIMISTIC> => C<2>

=back

=head2 Google::Firestore::V1::Common::RequestOptions

Options for a server request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request_tags() >> / C<< $msg->request_tags($value) >>

Type: C<String>

The request tags for the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
