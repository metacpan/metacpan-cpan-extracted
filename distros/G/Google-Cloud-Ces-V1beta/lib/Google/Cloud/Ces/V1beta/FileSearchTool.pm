package Google::Cloud::Ces::V1beta::FileSearchTool;

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
Ci5nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9maWxlX3NlYXJjaF90b29sLnByb3RvEhdnb29n
bGUuY2xvdWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKe
AgoORmlsZVNlYXJjaFRvb2wSWAoLY29ycHVzX3R5cGUYAyABKA4yMi5nb29nbGUuY2xvdWQu
Y2VzLnYxYmV0YS5GaWxlU2VhcmNoVG9vbC5Db3JwdXNUeXBlQgPgQQFSCmNvcnB1c1R5cGUS
FwoEbmFtZRgEIAEoCUID4EECUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAUgASgJQgPgQQFSC2Rl
c2NyaXB0aW9uEiQKC2ZpbGVfY29ycHVzGAYgASgJQgPgQQFSCmZpbGVDb3JwdXMiTAoKQ29y
cHVzVHlwZRIbChdDT1JQVVNfVFlQRV9VTlNQRUNJRklFRBAAEg4KClVTRVJfT1dORUQQARIR
Cg1GVUxMWV9NQU5BR0VEEAJCYwobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhQhNGaWxl
U2VhcmNoVG9vbFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9j
ZXNwYjtjZXNwYkrCDgoGEgQOADYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
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
LgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCAoBCBIDFABECgkKAggLEgMUAEQKCAoBCBIDFQAi
CgkKAggKEgMVACIKCAoBCBIDFgA0CgkKAggIEgMWADQKCAoBCBIDFwA0CgkKAggBEgMXADQK
8AEKAgQAEgQcADYBGuMBIFRoZSBmaWxlIHNlYXJjaCB0b29sIGFsbG93cyB0aGUgYWdlbnQg
dG8gc2VhcmNoIGFjcm9zcyB0aGUgZmlsZXMgdXBsb2FkZWQgYnkKIHRoZSBhcHAvYWdlbnQg
ZGV2ZWxvcGVyLiBJdCBoYXMgcHJlc2V0cyB0byBnaXZlIHJlbGF0aXZlbHkgZ29vZCBxdWFs
aXR5CiBzZWFyY2ggb3ZlciB0aGUgdXBsb2FkZWQgZmlsZXMgYW5kIHN1bW1hcml6YXRpb24g
b2YgdGhlIHJldHJpZXZlZCByZXN1bHRzLgoKCgoDBAABEgMcCBYKMgoEBAAEABIEHgInAxok
IFRoZSB0eXBlIG9mIHRoZSBWZXJ0ZXggUkFHIGNvcnB1cy4KCgwKBQQABAABEgMeBxEKKQoG
BAAEAAIAEgMgBCAaGiBVbnNwZWNpZmllZCBjb3JwdXMgdHlwZS4KCg4KBwQABAACAAESAyAE
GwoOCgcEAAQAAgACEgMgHh8KPQoGBAAEAAIBEgMjBBMaLiBUaGUgY29ycHVzIGlzIGNyZWF0
ZWQgYW5kIG93bmVkIGJ5IHRoZSB1c2VyLgoKDgoHBAAEAAIBARIDIwQOCg4KBwQABAACAQIS
AyMREgo0CgYEAAQAAgISAyYEFholIFRoZSBjb3JwdXMgaXMgY3JlYXRlZCBieSB0aGUgYWdl
bnQuCgoOCgcEAAQAAgIBEgMmBBEKDgoHBAAEAAICAhIDJhQVCkoKBAQAAgASAyoCRho9IE9w
dGlvbmFsLiBUaGUgdHlwZSBvZiB0aGUgY29ycHVzLiBEZWZhdWx0IGlzIEZVTExZX01BTkFH
RUQuCgoMCgUEAAIABhIDKgIMCgwKBQQAAgABEgMqDRgKDAoFBAACAAMSAyobHAoMCgUEAAIA
CBIDKh1FCg8KCAQAAgAInAgAEgMqHkQKJwoEBAACARIDLQI7GhogUmVxdWlyZWQuIFRoZSB0
b29sIG5hbWUuCgoMCgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCQ0KDAoFBAACAQMSAy0QEQoM
CgUEAAIBCBIDLRI6Cg8KCAQAAgEInAgAEgMtEzkKLgoEBAACAhIDMAJCGiEgT3B0aW9uYWwu
IFRoZSB0b29sIGRlc2NyaXB0aW9uLgoKDAoFBAACAgUSAzACCAoMCgUEAAICARIDMAkUCgwK
BQQAAgIDEgMwFxgKDAoFBAACAggSAzAZQQoPCggEAAICCJwIABIDMBpACoUBCgQEAAIDEgM1
AkIaeCBPcHRpb25hbC4gVGhlIGNvcnB1cyB3aGVyZSBmaWxlcyBhcmUgc3RvcmVkLgogRm9y
bWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JhZ0NvcnBv
cmEve3JhZ19jb3JwdXN9CgoMCgUEAAIDBRIDNQIICgwKBQQAAgMBEgM1CRQKDAoFBAACAwMS
AzUXGAoMCgUEAAIDCBIDNRlBCg8KCAQAAgMInAgAEgM1GkBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::FileSearchTool::FileSearchTool ===
    # Fields for FileSearchTool
    # Field: corpus_type Type: 14 (.google.cloud.ces.v1beta.FileSearchTool.CorpusType)
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

Google::Cloud::Ces::V1beta::FileSearchTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/file_search_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::FileSearchTool;

    my $msg = Google::Cloud::Ces::V1beta::FileSearchTool::FileSearchTool->new({
        corpus_type => $corpus_type,
        name => $name,
        description => $description,
        file_corpus => $file_corpus,
    });

    # Read or update a field
    my $val = $msg->corpus_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::FileSearchTool::FileSearchTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/file_search_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::FileSearchTool::FileSearchTool

The file search tool allows the agent to search across the files uploaded by
the app/agent developer. It has presets to give relatively good quality
search over the uploaded files and summarization of the retrieved results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->corpus_type() >> / C<< $msg->corpus_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::FileSearchTool::CorpusType>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::FileSearchTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
