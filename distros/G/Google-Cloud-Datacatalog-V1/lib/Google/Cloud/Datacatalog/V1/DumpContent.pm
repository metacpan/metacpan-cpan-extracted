package Google::Cloud::Datacatalog::V1::DumpContent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Datacatalog::V1::Datacatalog };
    eval { require Google::Cloud::Datacatalog::V1::Tags };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvZHVtcF9jb250ZW50LnByb3RvEhtnb29n
bGUuY2xvdWQuZGF0YWNhdGFsb2cudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aLWdvb2dsZS9jbG91ZC9kYXRhY2F0YWxvZy92MS9kYXRhY2F0YWxvZy5wcm90bxomZ29v
Z2xlL2Nsb3VkL2RhdGFjYXRhbG9nL3YxL3RhZ3MucHJvdG8i6QEKC1RhZ2dlZEVudHJ5Ej8K
CHYxX2VudHJ5GAEgASgLMiIuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkVudHJ5SABS
B3YxRW50cnkSSAoMcHJlc2VudF90YWdzGAIgAygLMiAuZ29vZ2xlLmNsb3VkLmRhdGFjYXRh
bG9nLnYxLlRhZ0ID4EEBUgtwcmVzZW50VGFncxJGCgthYnNlbnRfdGFncxgDIAMoCzIgLmdv
b2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5UYWdCA+BBAVIKYWJzZW50VGFnc0IHCgVlbnRy
eSJhCghEdW1wSXRlbRJNCgx0YWdnZWRfZW50cnkYASABKAsyKC5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjEuVGFnZ2VkRW50cnlIAFILdGFnZ2VkRW50cnlCBgoEaXRlbULVAQofY29t
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MUIQRHVtcENvbnRlbnRQcm90b1ABWkFjbG91
ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRhbG9nL2FwaXYxL2RhdGFjYXRhbG9ncGI7ZGF0YWNh
dGFsb2dwYqoCG0dvb2dsZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMcoCG0dvb2dsZVxDbG91ZFxE
YXRhQ2F0YWxvZ1xWMeoCHkdvb2dsZTo6Q2xvdWQ6OkRhdGFDYXRhbG9nOjpWMUqaDQoGEgQO
ADYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMA
EgMSACkKCQoCAwESAxMANwoJCgIDAhIDFAAwCggKAQgSAxYAOAoJCgIIJRIDFgA4CggKAQgS
AxcAWAoJCgIICxIDFwBYCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMQoJCgIICBID
GQAxCggKAQgSAxoAOAoJCgIIARIDGgA4CggKAQgSAxsAOAoJCgIIKRIDGwA4CggKAQgSAxwA
NwoJCgIILRIDHAA3CnAKAgQAEgQgAC4BGmQgV3JhcHBlciBjb250YWluaW5nIEVudHJ5IGFu
ZCBpbmZvcm1hdGlvbiBhYm91dCBUYWdzCiB0aGF0IHNob3VsZCBhbmQgc2hvdWxkIG5vdCBi
ZSBhdHRhY2hlZCB0byBpdC4KCgoKAwQAARIDIAgTCi8KBAQACAASBCICJQMaISBSZXF1aXJl
ZC4gRW50cnkgdG8gYmUgaW5nZXN0ZWQuCgoMCgUEAAgAARIDIggNCjMKBAQAAgASAyQEFxom
IE5vbi1lbmNyeXB0ZWQgRGF0YSBDYXRhbG9nIHYxIEVudHJ5LgoKDAoFBAACAAYSAyQECQoM
CgUEAAIAARIDJAoSCgwKBQQAAgADEgMkFRYKhgEKBAQAAgESAykCSRp5IE9wdGlvbmFsLiBU
YWdzIHRoYXQgc2hvdWxkIGJlIGluZ2VzdGVkIGludG8gdGhlIERhdGEgQ2F0YWxvZy4KIENh
bGxlciBzaG91bGQgcG9wdWxhdGUgdGVtcGxhdGUgbmFtZSwgY29sdW1uIGFuZCBmaWVsZHMu
CgoMCgUEAAIBBBIDKQIKCgwKBQQAAgEGEgMpCw4KDAoFBAACAQESAykPGwoMCgUEAAIBAxID
KR4fCgwKBQQAAgEIEgMpIEgKDwoIBAACAQicCAASAykhRwqCAQoEBAACAhIDLQJIGnUgT3B0
aW9uYWwuIFRhZ3MgdGhhdCBzaG91bGQgYmUgZGVsZXRlZCBmcm9tIHRoZSBEYXRhIENhdGFs
b2cuCiBDYWxsZXIgc2hvdWxkIHBvcHVsYXRlIHRlbXBsYXRlIG5hbWUgYW5kIGNvbHVtbiBv
bmx5LgoKDAoFBAACAgQSAy0CCgoMCgUEAAICBhIDLQsOCgwKBQQAAgIBEgMtDxoKDAoFBAAC
AgMSAy0dHgoMCgUEAAICCBIDLR9HCg8KCAQAAgIInAgAEgMtIEYKRQoCBAESBDEANgEaOSBX
cmFwcGVyIGZvciBhbnkgaXRlbSB0aGF0IGNhbiBiZSBjb250YWluZWQgaW4gdGhlIGR1bXAu
CgoKCgMEAQESAzEIEAoMCgQEAQgAEgQyAjUDCgwKBQQBCAABEgMyCAwKIgoEBAECABIDNAQh
GhUgRW50cnkgYW5kIGl0cyB0YWdzLgoKDAoFBAECAAYSAzQEDwoMCgUEAQIAARIDNBAcCgwK
BQQBAgADEgM0HyBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry ===
    # Fields for TaggedEntry
    # Field: v1_entry Type: 11 (.google.cloud.datacatalog.v1.Entry)
    # Field: present_tags Type: 11 (.google.cloud.datacatalog.v1.Tag)
    # Field: absent_tags Type: 11 (.google.cloud.datacatalog.v1.Tag)

# === Message: Google::Cloud::Datacatalog::V1::DumpContent::DumpItem ===
    # Fields for DumpItem
    # Field: tagged_entry Type: 11 (.google.cloud.datacatalog.v1.TaggedEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::DumpContent - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/dump_content.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::DumpContent;

    my $msg = Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry->new({
        v1_entry => $v1_entry,
        present_tags => $present_tags,
        absent_tags => $absent_tags,
    });

    # Read or update a field
    my $val = $msg->v1_entry();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/dump_content.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry

Wrapper containing Entry and information about Tags
that should and should not be attached to it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->v1_entry() >> / C<< $msg->v1_entry($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Datacatalog::Entry>)

Non-encrypted Data Catalog v1 Entry.

=item * C<< $msg->present_tags() >> / C<< $msg->present_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::Tag>)

Optional. Tags that should be ingested into the Data Catalog.
Caller should populate template name, column and fields.

=item * C<< $msg->absent_tags() >> / C<< $msg->absent_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Tags::Tag>)

Optional. Tags that should be deleted from the Data Catalog.
Caller should populate template name and column only.

=back

=head2 Google::Cloud::Datacatalog::V1::DumpContent::DumpItem

Wrapper for any item that can be contained in the dump.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tagged_entry() >> / C<< $msg->tagged_entry($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry>)

Entry and its tags.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::DumpContent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
