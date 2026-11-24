package Google::Devtools::Resultstore::V2::DownloadMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Resultstore::V2::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvZG93bmxvYWRfbWV0YWRhdGEucHJv
dG8SHmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MhoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxorZ29vZ2xlL2RldnRvb2xzL3Jlc3VsdHN0b3JlL3YyL2NvbW1vbi5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKXAwoQRG93bmxvYWRNZXRhZGF0YRIS
CgRuYW1lGAEgASgJUgRuYW1lElEKDXVwbG9hZF9zdGF0dXMYAiABKA4yLC5nb29nbGUuZGV2
dG9vbHMucmVzdWx0c3RvcmUudjIuVXBsb2FkU3RhdHVzUgx1cGxvYWRTdGF0dXMSOwoLY3Jl
YXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1l
Ej8KDWZpbmFsaXplX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxm
aW5hbGl6ZVRpbWUSQQoOaW1tdXRhYmxlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUg1pbW11dGFibGVUaW1lOlvqQVgKK3Jlc3VsdHN0b3JlLmdvb2dsZWFwaXMu
Y29tL0Rvd25sb2FkTWV0YWRhdGESKWludm9jYXRpb25zL3tpbnZvY2F0aW9ufS9kb3dubG9h
ZE1ldGFkYXRhQogBCiJjb20uZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyQhVEb3du
bG9hZE1ldGFkYXRhUHJvdG9QAVpJZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xl
YXBpcy9kZXZ0b29scy9yZXN1bHRzdG9yZS92MjtyZXN1bHRzdG9yZUqkDgoGEgQOADgBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACMK
CQoCAwESAxMANQoJCgIDAhIDFAApCggKAQgSAxYAYAoJCgIICxIDFgBgCggKAQgSAxcAIgoJ
CgIIChIDFwAiCggKAQgSAxgANgoJCgIICBIDGAA2CggKAQgSAxkAOwoJCgIIARIDGQA7CjUK
AgQAEgQcADgBGikgVGhlIGRvd25sb2FkIG1ldGFkYXRhIGZvciBhbiBpbnZvY2F0aW9uCgoK
CgMEAAESAxwIGAoLCgMEAAcSBB0CIAQKDQoFBAAHnQgSBB0CIAQKdQoEBAACABIDJAISGmgg
VGhlIG5hbWUgb2YgdGhlIGRvd25sb2FkIG1ldGFkYXRhLiAgSXRzIGZvcm1hdCB3aWxsIGJl
OgogaW52b2NhdGlvbnMvJHtJTlZPQ0FUSU9OX0lEfS9kb3dubG9hZE1ldGFkYXRhCgoMCgUE
AAIABRIDJAIICgwKBQQAAgABEgMkCQ0KDAoFBAACAAMSAyQQEQpwCgQEAAIBEgMoAiEaYyBJ
bmRpY2F0ZXMgdGhlIHVwbG9hZCBzdGF0dXMgb2YgdGhlIGludm9jYXRpb24sIHdoZXRoZXIg
aXQgaXMKIHBvc3QtcHJvY2Vzc2luZywgb3IgaW1tdXRhYmxlLCBldGMuCgoMCgUEAAIBBhID
KAIOCgwKBQQAAgEBEgMoDxwKDAoFBAACAQMSAygfIArMAQoEBAACAhIDLQIsGr4BIElmIHBv
cHVsYXRlZCwgdGhlIHRpbWUgd2hlbiBDcmVhdGVJbnZvY2F0aW9uIGlzIGNhbGxlZC4KIFRo
aXMgZG9lcyBub3QgbmVjZXNzYXJpbHkgbGluZSB1cCB3aXRoIHRoZSBzdGFydCB0aW1lIG9m
IHRoZSBpbnZvY2F0aW9uLgogUGxlYXNlIHVzZSBpbnZvY2F0aW9uLnRpbWluZy5zdGFydF90
aW1lIGZvciB0aGF0IHB1cnBvc2UuCgoMCgUEAAICBhIDLQIbCgwKBQQAAgIBEgMtHCcKDAoF
BAACAgMSAy0qKwq9AQoEBAACAxIDMgIuGq8BIElmIHBvcHVsYXRlZCwgdGhlIHRpbWUgd2hl
biBGaW5hbGl6ZUludm9jYXRpb24gaXMgY2FsbGVkIG9yIHdoZW4gaW52b2NhdGlvbgogaXMg
YXV0b21hdGljYWxseSBmaW5hbGl6ZWQuIFRoaXMgZmllbGQgaXMgcG9wdWxhdGVkIHdoZW4g
dXBsb2FkX3N0YXR1cwogYmVjb21lcyBQT1NUX1BST0NFU1NJTkcuCgoMCgUEAAIDBhIDMgIb
CgwKBQQAAgMBEgMyHCkKDAoFBAACAwMSAzIsLQqyAQoEBAACBBIDNwIvGqQBIElmIHBvcHVs
YXRlZCwgdGhlIHRpbWUgd2hlbiBhbGwgcG9zdCBwcm9jZXNzaW5nIGlzIGRvbmUgYW5kIHRo
ZSBpbnZvY2F0aW9uCiBpcyBtYXJrZWQgYXMgaW1tdXRhYmxlLiBUaGlzIGZpZWxkIGlzIHBv
cHVsYXRlZCB3aGVuIHVwbG9hZF9zdGF0dXMgYmVjb21lcwogSU1NVVRBQkxFLgoKDAoFBAAC
BAYSAzcCGwoMCgUEAAIEARIDNxwqCgwKBQQAAgQDEgM3LS5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata ===
    # Fields for DownloadMetadata
    # Field: name Type: 9 ()
    # Field: upload_status Type: 14 (.google.devtools.resultstore.v2.UploadStatus)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: finalize_time Type: 11 (.google.protobuf.Timestamp)
    # Field: immutable_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::DownloadMetadata - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/download_metadata.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::DownloadMetadata;

    my $msg = Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata->new({
        name => $name,
        upload_status => $upload_status,
        create_time => $create_time,
        finalize_time => $finalize_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/download_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata

The download metadata for an invocation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the download metadata.  Its format will be:
invocations/${INVOCATION_ID}/downloadMetadata

=item * C<< $msg->upload_status() >> / C<< $msg->upload_status($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::UploadStatus>)

Indicates the upload status of the invocation, whether it is
post-processing, or immutable, etc.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If populated, the time when CreateInvocation is called.
This does not necessarily line up with the start time of the invocation.
Please use invocation.timing.start_time for that purpose.

=item * C<< $msg->finalize_time() >> / C<< $msg->finalize_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If populated, the time when FinalizeInvocation is called or when invocation
is automatically finalized. This field is populated when upload_status
becomes POST_PROCESSING.

=item * C<< $msg->immutable_time() >> / C<< $msg->immutable_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If populated, the time when all post processing is done and the invocation
is marked as immutable. This field is populated when upload_status becomes
IMMUTABLE.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::DownloadMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
