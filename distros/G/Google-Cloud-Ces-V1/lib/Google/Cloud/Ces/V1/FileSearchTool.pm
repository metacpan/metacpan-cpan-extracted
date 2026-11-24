package Google::Cloud::Ces::V1::FileSearchTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvY2VzL3YxL2ZpbGVfc2VhcmNoX3Rvb2wucHJvdG8SE2dvb2dsZS5j
bG91ZC5jZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8imgIKDkZpbGVT
ZWFyY2hUb29sElQKC2NvcnB1c190eXBlGAMgASgOMi4uZ29vZ2xlLmNsb3VkLmNlcy52MS5G
aWxlU2VhcmNoVG9vbC5Db3JwdXNUeXBlQgPgQQFSCmNvcnB1c1R5cGUSFwoEbmFtZRgEIAEo
CUID4EECUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAUgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEiQK
C2ZpbGVfY29ycHVzGAYgASgJQgPgQQFSCmZpbGVDb3JwdXMiTAoKQ29ycHVzVHlwZRIbChdD
T1JQVVNfVFlQRV9VTlNQRUNJRklFRBAAEg4KClVTRVJfT1dORUQQARIRCg1GVUxMWV9NQU5B
R0VEEAJCWwoXY29tLmdvb2dsZS5jbG91ZC5jZXMudjFCE0ZpbGVTZWFyY2hUb29sUHJvdG9Q
AVopY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjEvY2VzcGI7Y2VzcGJKwg4KBhIEDgA2
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABID
EgApCggKAQgSAxQAQAoJCgIICxIDFABACggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYA
NAoJCgIICBIDFgA0CggKAQgSAxcAMAoJCgIIARIDFwAwCvABCgIEABIEHAA2ARrjASBUaGUg
ZmlsZSBzZWFyY2ggdG9vbCBhbGxvd3MgdGhlIGFnZW50IHRvIHNlYXJjaCBhY3Jvc3MgdGhl
IGZpbGVzIHVwbG9hZGVkIGJ5CiB0aGUgYXBwL2FnZW50IGRldmVsb3Blci4gSXQgaGFzIHBy
ZXNldHMgdG8gZ2l2ZSByZWxhdGl2ZWx5IGdvb2QgcXVhbGl0eQogc2VhcmNoIG92ZXIgdGhl
IHVwbG9hZGVkIGZpbGVzIGFuZCBzdW1tYXJpemF0aW9uIG9mIHRoZSByZXRyaWV2ZWQgcmVz
dWx0cy4KCgoKAwQAARIDHAgWCjIKBAQABAASBB4CJwMaJCBUaGUgdHlwZSBvZiB0aGUgVmVy
dGV4IFJBRyBjb3JwdXMuCgoMCgUEAAQAARIDHgcRCikKBgQABAACABIDIAQgGhogVW5zcGVj
aWZpZWQgY29ycHVzIHR5cGUuCgoOCgcEAAQAAgABEgMgBBsKDgoHBAAEAAIAAhIDIB4fCj0K
BgQABAACARIDIwQTGi4gVGhlIGNvcnB1cyBpcyBjcmVhdGVkIGFuZCBvd25lZCBieSB0aGUg
dXNlci4KCg4KBwQABAACAQESAyMEDgoOCgcEAAQAAgECEgMjERIKNAoGBAAEAAICEgMmBBYa
JSBUaGUgY29ycHVzIGlzIGNyZWF0ZWQgYnkgdGhlIGFnZW50LgoKDgoHBAAEAAICARIDJgQR
Cg4KBwQABAACAgISAyYUFQpKCgQEAAIAEgMqAkYaPSBPcHRpb25hbC4gVGhlIHR5cGUgb2Yg
dGhlIGNvcnB1cy4gRGVmYXVsdCBpcyBGVUxMWV9NQU5BR0VELgoKDAoFBAACAAYSAyoCDAoM
CgUEAAIAARIDKg0YCgwKBQQAAgADEgMqGxwKDAoFBAACAAgSAyodRQoPCggEAAIACJwIABID
Kh5ECicKBAQAAgESAy0COxoaIFJlcXVpcmVkLiBUaGUgdG9vbCBuYW1lLgoKDAoFBAACAQUS
Ay0CCAoMCgUEAAIBARIDLQkNCgwKBQQAAgEDEgMtEBEKDAoFBAACAQgSAy0SOgoPCggEAAIB
CJwIABIDLRM5Ci4KBAQAAgISAzACQhohIE9wdGlvbmFsLiBUaGUgdG9vbCBkZXNjcmlwdGlv
bi4KCgwKBQQAAgIFEgMwAggKDAoFBAACAgESAzAJFAoMCgUEAAICAxIDMBcYCgwKBQQAAgII
EgMwGUEKDwoIBAACAgicCAASAzAaQAqFAQoEBAACAxIDNQJCGnggT3B0aW9uYWwuIFRoZSBj
b3JwdXMgd2hlcmUgZmlsZXMgYXJlIHN0b3JlZC4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yYWdDb3Jwb3JhL3tyYWdfY29ycHVzfQoKDAoF
BAACAwUSAzUCCAoMCgUEAAIDARIDNQkUCgwKBQQAAgMDEgM1FxgKDAoFBAACAwgSAzUZQQoP
CggEAAIDCJwIABIDNRpAYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::FileSearchTool::FileSearchTool ===
    # Fields for FileSearchTool
    # Field: corpus_type Type: 14 (.google.cloud.ces.v1.FileSearchTool.CorpusType)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: file_corpus Type: 9 ()

# Enum: FileSearchTool::CorpusType
our $FileSearchTool_CORPUS_TYPE_UNSPECIFIED = 0;
our $FileSearchTool_USER_OWNED = 1;
our $FileSearchTool_FULLY_MANAGED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::FileSearchTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/file_search_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::FileSearchTool;

    my $msg = Google::Cloud::Ces::V1::FileSearchTool::FileSearchTool->new({
        corpus_type => $corpus_type,
        name => $name,
        description => $description,
        file_corpus => $file_corpus,
    });

    # Read or update a field
    my $val = $msg->corpus_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::FileSearchTool::FileSearchTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/file_search_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::FileSearchTool::FileSearchTool

The file search tool allows the agent to search across the files uploaded by
the app/agent developer. It has presets to give relatively good quality
search over the uploaded files and summarization of the retrieved results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->corpus_type() >> / C<< $msg->corpus_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::FileSearchTool::CorpusType>)

Optional. The type of the corpus. Default is FULLY_MANAGED.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The tool name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The tool description.

=item * C<< $msg->file_corpus() >> / C<< $msg->file_corpus($value) >>

Type: C<String>

Optional. The corpus where files are stored.
Format:
projects/{project}/locations/{location}/ragCorpora/{rag_corpus}

=back

=head3 Enum: FileSearchTool::CorpusType

=over 4

=item * C<CORPUS_TYPE_UNSPECIFIED> => C<0>

=item * C<USER_OWNED> => C<1>

=item * C<FULLY_MANAGED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::FileSearchTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
