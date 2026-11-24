package Google::Cloud::Documentai::V1::ProcessorType;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::LaunchStage };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9wcm9jZXNzb3JfdHlwZS5wcm90bxIaZ29v
Z2xlLmNsb3VkLmRvY3VtZW50YWkudjEaHWdvb2dsZS9hcGkvbGF1bmNoX3N0YWdlLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIvkDCg1Qcm9jZXNzb3JUeXBlEhIKBG5hbWUY
ASABKAlSBG5hbWUSEgoEdHlwZRgCIAEoCVIEdHlwZRIaCghjYXRlZ29yeRgDIAEoCVIIY2F0
ZWdvcnkSZwoTYXZhaWxhYmxlX2xvY2F0aW9ucxgEIAMoCzI2Lmdvb2dsZS5jbG91ZC5kb2N1
bWVudGFpLnYxLlByb2Nlc3NvclR5cGUuTG9jYXRpb25JbmZvUhJhdmFpbGFibGVMb2NhdGlv
bnMSJQoOYWxsb3dfY3JlYXRpb24YBiABKAhSDWFsbG93Q3JlYXRpb24SOgoMbGF1bmNoX3N0
YWdlGAggASgOMhcuZ29vZ2xlLmFwaS5MYXVuY2hTdGFnZVILbGF1bmNoU3RhZ2USMAoUc2Ft
cGxlX2RvY3VtZW50X3VyaXMYCSADKAlSEnNhbXBsZURvY3VtZW50VXJpcxovCgxMb2NhdGlv
bkluZm8SHwoLbG9jYXRpb25faWQYASABKAlSCmxvY2F0aW9uSWQ6depBcgonZG9jdW1lbnRh
aS5nb29nbGVhcGlzLmNvbS9Qcm9jZXNzb3JUeXBlEkdwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vcHJvY2Vzc29yVHlwZXMve3Byb2Nlc3Nvcl90eXBlfULVAQoe
Y29tLmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxQhdEb2N1bWVudEFpUHJvY2Vzc29yVHlw
ZVABWj5jbG91ZC5nb29nbGUuY29tL2dvL2RvY3VtZW50YWkvYXBpdjEvZG9jdW1lbnRhaXBi
O2RvY3VtZW50YWlwYqoCGkdvb2dsZS5DbG91ZC5Eb2N1bWVudEFJLlYxygIaR29vZ2xlXENs
b3VkXERvY3VtZW50QUlcVjHqAh1Hb29nbGU6OkNsb3VkOjpEb2N1bWVudEFJOjpWMUqKEQoG
EgQOAEIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkK
AgMAEgMSACcKCQoCAwESAxMAIwoICgEIEgMVADcKCQoCCCUSAxUANwoICgEIEgMWAFUKCQoC
CAsSAxYAVQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADgKCQoCCAgSAxgAOAoICgEI
EgMZADcKCQoCCAESAxkANwoICgEIEgMaADcKCQoCCCkSAxoANwoICgEIEgMbADYKCQoCCC0S
AxsANgqCAQoCBAASBB8AQgEadiBBIHByb2Nlc3NvciB0eXBlIGlzIHJlc3BvbnNpYmxlIGZv
ciBwZXJmb3JtaW5nIGEgY2VydGFpbiBkb2N1bWVudAogdW5kZXJzdGFuZGluZyB0YXNrIG9u
IGEgY2VydGFpbiB0eXBlIG9mIGRvY3VtZW50LgoKCgoDBAABEgMfCBUKCwoDBAAHEgQgAiME
Cg0KBQQAB50IEgQgAiMEClAKBAQAAwASBCYCKgMaQiBUaGUgbG9jYXRpb24gaW5mb3JtYXRp
b24gYWJvdXQgd2hlcmUgdGhlIHByb2Nlc3NvciBpcyBhdmFpbGFibGUuCgoMCgUEAAMAARID
JgoWCoYBCgYEAAMAAgASAykEGxp3IFRoZSBsb2NhdGlvbiBJRC4gRm9yIHN1cHBvcnRlZCBs
b2NhdGlvbnMsIHJlZmVyIHRvIFtyZWdpb25hbCBhbmQKIG11bHRpLXJlZ2lvbmFsIHN1cHBv
cnRdKC9kb2N1bWVudC1haS9kb2NzL3JlZ2lvbnMpLgoKDgoHBAADAAIABRIDKQQKCg4KBwQA
AwACAAESAykLFgoOCgcEAAMAAgADEgMpGRoKdQoEBAACABIDLgISGmggVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIHByb2Nlc3NvciB0eXBlLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2pl
Y3R9L3Byb2Nlc3NvclR5cGVzL3twcm9jZXNzb3JfdHlwZX1gCgoMCgUEAAIABRIDLgIICgwK
BQQAAgABEgMuCQ0KDAoFBAACAAMSAy4QEQpRCgQEAAIBEgMxAhIaRCBUaGUgcHJvY2Vzc29y
IHR5cGUsIHN1Y2ggYXM6IGBPQ1JfUFJPQ0VTU09SYCwgYElOVk9JQ0VfUFJPQ0VTU09SYC4K
CgwKBQQAAgEFEgMxAggKDAoFBAACAQESAzEJDQoMCgUEAAIBAxIDMRARCksKBAQAAgISAzQC
Fho+IFRoZSBwcm9jZXNzb3IgY2F0ZWdvcnksIHVzZWQgYnkgVUkgdG8gZ3JvdXAgcHJvY2Vz
c29yIHR5cGVzLgoKDAoFBAACAgUSAzQCCAoMCgUEAAICARIDNAkRCgwKBQQAAgIDEgM0FBUK
QgoEBAACAxIDNwIwGjUgVGhlIGxvY2F0aW9ucyBpbiB3aGljaCB0aGlzIHByb2Nlc3NvciBp
cyBhdmFpbGFibGUuCgoMCgUEAAIDBBIDNwIKCgwKBQQAAgMGEgM3CxcKDAoFBAACAwESAzcY
KwoMCgUEAAIDAxIDNy4vCqMBCgQEAAIEEgM7AhoalQEgV2hldGhlciB0aGUgcHJvY2Vzc29y
IHR5cGUgYWxsb3dzIGNyZWF0aW9uLiBJZiB0cnVlLCB1c2VycyBjYW4gY3JlYXRlIGEKIHBy
b2Nlc3NvciBvZiB0aGlzIHByb2Nlc3NvciB0eXBlLiBPdGhlcndpc2UsIHVzZXJzIG5lZWQg
dG8gcmVxdWVzdCBhY2Nlc3MuCgoMCgUEAAIEBRIDOwIGCgwKBQQAAgQBEgM7BxUKDAoFBAAC
BAMSAzsYGQoxCgQEAAIFEgM+AioaJCBMYXVuY2ggc3RhZ2Ugb2YgdGhlIHByb2Nlc3NvciB0
eXBlCgoMCgUEAAIFBhIDPgIYCgwKBQQAAgUBEgM+GSUKDAoFBAACBQMSAz4oKQpSCgQEAAIG
EgNBAisaRSBBIHNldCBvZiBDbG91ZCBTdG9yYWdlIFVSSXMgb2Ygc2FtcGxlIGRvY3VtZW50
cyBmb3IgdGhpcyBwcm9jZXNzb3IuCgoMCgUEAAIGBBIDQQIKCgwKBQQAAgYFEgNBCxEKDAoF
BAACBgESA0ESJgoMCgUEAAIGAxIDQSkqYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1::ProcessorType::ProcessorType ===
    # Fields for ProcessorType
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: category Type: 9 ()
    # Field: available_locations Type: 11 (.google.cloud.documentai.v1.ProcessorType.LocationInfo)
    # Field: allow_creation Type: 8 ()
    # Field: launch_stage Type: 14 (.google.api.LaunchStage)
    # Field: sample_document_uris Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1::ProcessorType - Compiled Protocol Buffers messages for google/cloud/documentai/v1/processor_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1::ProcessorType;

    my $msg = Google::Cloud::Documentai::V1::ProcessorType::ProcessorType->new({
        name => $name,
        type => $type,
        category => $category,
        available_locations => $available_locations,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1::ProcessorType::ProcessorType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1/processor_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1::ProcessorType::ProcessorType

A processor type is responsible for performing a certain document
understanding task on a certain type of document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the processor type.
Format: `projects/{project}/processorTypes/{processor_type}`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The processor type, such as: `OCR_PROCESSOR`, `INVOICE_PROCESSOR`.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

The processor category, used by UI to group processor types.

=item * C<< $msg->available_locations() >> / C<< $msg->available_locations($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::ProcessorType::ProcessorType::LocationInfo>)

The locations in which this processor is available.

=item * C<< $msg->allow_creation() >> / C<< $msg->allow_creation($value) >>

Type: C<Bool>

Whether the processor type allows creation. If true, users can create a
processor of this processor type. Otherwise, users need to request access.

=item * C<< $msg->launch_stage() >> / C<< $msg->launch_stage($value) >>

Type: C<Enum> (L<Google::Api::LaunchStage>)

Launch stage of the processor type

=item * C<< $msg->sample_document_uris() >> / C<< $msg->sample_document_uris($value) >>

Type: C<String>

A set of Cloud Storage URIs of sample documents for this processor.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1::ProcessorType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
