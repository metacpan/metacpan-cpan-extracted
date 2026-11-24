package Google::Devtools::Resultstore::V2::UploadMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvdXBsb2FkX21ldGFkYXRhLnByb3Rv
Eh5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8ixwEKDlVwbG9hZE1ldGFkYXRhEhIKBG5hbWUYASABKAlSBG5hbWUSIQoMcmVzdW1l
X3Rva2VuGAIgASgJUgtyZXN1bWVUb2tlbhIlCg51cGxvYWRlcl9zdGF0ZRgDIAEoDFINdXBs
b2FkZXJTdGF0ZTpX6kFUCilyZXN1bHRzdG9yZS5nb29nbGVhcGlzLmNvbS9VcGxvYWRNZXRh
ZGF0YRInaW52b2NhdGlvbnMve2ludm9jYXRpb259L3VwbG9hZE1ldGFkYXRhQoYBCiJjb20u
Z29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyQhNVcGxvYWRNZXRhZGF0YVByb3RvUAFa
SWdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZGV2dG9vbHMvcmVzdWx0
c3RvcmUvdjI7cmVzdWx0c3RvcmVKqQoKBhIEDgAtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAjCggKAQgSAxQAYAoJCgIICxIDFABg
CggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYANAoJCgIICBIDFgA0CggKAQgSAxcAOwoJ
CgIIARIDFwA7CjMKAgQAEgQaAC0BGicgVGhlIHVwbG9hZCBtZXRhZGF0YSBmb3IgYW4gaW52
b2NhdGlvbgoKCgoDBAABEgMaCBYKCwoDBAAHEgQbAh4ECg0KBQQAB50IEgQbAh4ECnEKBAQA
AgASAyICEhpkIFRoZSBuYW1lIG9mIHRoZSB1cGxvYWQgbWV0YWRhdGEuICBJdHMgZm9ybWF0
IHdpbGwgYmU6CiBpbnZvY2F0aW9ucy8ke0lOVk9DQVRJT05fSUR9L3VwbG9hZE1ldGFkYXRh
CgoMCgUEAAIABRIDIgIICgwKBQQAAgABEgMiCQ0KDAoFBAACAAMSAyIQEQq3AQoEBAACARID
KAIaGqkBIFRoZSByZXN1bWUgdG9rZW4gb2YgdGhlIGxhc3QgYmF0Y2ggdGhhdCB3YXMgY29t
bWl0dGVkIGluIHRoZSBtb3N0IHJlY2VudAogYmF0Y2ggdXBsb2FkLgogTW9yZSBpbmZvcm1h
dGlvbiB3aXRoIHJlc3VtZV90b2tlbiBjb3VsZCBiZSBmb3VuZCBpbgogcmVzdWx0c3RvcmVf
dXBsb2FkLnByb3RvCgoMCgUEAAIBBRIDKAIICgwKBQQAAgEBEgMoCRUKDAoFBAACAQMSAygY
GQpvCgQEAAICEgMsAhsaYiBDbGllbnQtc3BlY2lmaWMgZGF0YSB1c2VkIHRvIHJlc3VtZSBi
YXRjaCB1cGxvYWQgaWYgYW4gZXJyb3Igb2NjdXJzIGFuZAogcmV0cnkgYWN0aW9uIGlzIG5l
ZWRlZC4KCgwKBQQAAgIFEgMsAgcKDAoFBAACAgESAywIFgoMCgUEAAICAxIDLBkaYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata ===
    # Fields for UploadMetadata
    # Field: name Type: 9 ()
    # Field: resume_token Type: 9 ()
    # Field: uploader_state Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::UploadMetadata - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/upload_metadata.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::UploadMetadata;

    my $msg = Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata->new({
        name => $name,
        resume_token => $resume_token,
        uploader_state => $uploader_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/upload_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata

The upload metadata for an invocation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the upload metadata.  Its format will be:
invocations/${INVOCATION_ID}/uploadMetadata

=item * C<< $msg->resume_token() >> / C<< $msg->resume_token($value) >>

Type: C<String>

The resume token of the last batch that was committed in the most recent
batch upload.
More information with resume_token could be found in
resultstore_upload.proto

=item * C<< $msg->uploader_state() >> / C<< $msg->uploader_state($value) >>

Type: C<Bytes>

Client-specific data used to resume batch upload if an error occurs and
retry action is needed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::UploadMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
