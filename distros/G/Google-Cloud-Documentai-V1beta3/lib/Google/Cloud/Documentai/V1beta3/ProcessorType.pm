package Google::Cloud::Documentai::V1beta3::ProcessorType;

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
CjRnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL3Byb2Nlc3Nvcl90eXBlLnByb3Rv
Eh9nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzGh1nb29nbGUvYXBpL2xhdW5jaF9z
dGFnZS5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byL+AwoNUHJvY2Vzc29yVHlw
ZRISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHR5cGUYAiABKAlSBHR5cGUSGgoIY2F0ZWdvcnkY
AyABKAlSCGNhdGVnb3J5EmwKE2F2YWlsYWJsZV9sb2NhdGlvbnMYBCADKAsyOy5nb29nbGUu
Y2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLlByb2Nlc3NvclR5cGUuTG9jYXRpb25JbmZvUhJh
dmFpbGFibGVMb2NhdGlvbnMSJQoOYWxsb3dfY3JlYXRpb24YBiABKAhSDWFsbG93Q3JlYXRp
b24SOgoMbGF1bmNoX3N0YWdlGAggASgOMhcuZ29vZ2xlLmFwaS5MYXVuY2hTdGFnZVILbGF1
bmNoU3RhZ2USMAoUc2FtcGxlX2RvY3VtZW50X3VyaXMYCSADKAlSEnNhbXBsZURvY3VtZW50
VXJpcxovCgxMb2NhdGlvbkluZm8SHwoLbG9jYXRpb25faWQYASABKAlSCmxvY2F0aW9uSWQ6
depBcgonZG9jdW1lbnRhaS5nb29nbGVhcGlzLmNvbS9Qcm9jZXNzb3JUeXBlEkdwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJvY2Vzc29yVHlwZXMve3Byb2Nl
c3Nvcl90eXBlfULuAQojY29tLmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTNCF0Rv
Y3VtZW50QWlQcm9jZXNzb3JUeXBlUAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28vZG9jdW1lbnRh
aS9hcGl2MWJldGEzL2RvY3VtZW50YWlwYjtkb2N1bWVudGFpcGKqAh9Hb29nbGUuQ2xvdWQu
RG9jdW1lbnRBSS5WMUJldGEzygIfR29vZ2xlXENsb3VkXERvY3VtZW50QUlcVjFiZXRhM+oC
Ikdvb2dsZTo6Q2xvdWQ6OkRvY3VtZW50QUk6OlYxYmV0YTNKihEKBhIEDgBCAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAnCgkKAgMB
EgMTACMKCAoBCBIDFQA8CgkKAgglEgMVADwKCAoBCBIDFgBaCgkKAggLEgMWAFoKCAoBCBID
FwAiCgkKAggKEgMXACIKCAoBCBIDGAA4CgkKAggIEgMYADgKCAoBCBIDGQA8CgkKAggBEgMZ
ADwKCAoBCBIDGgA8CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKggEKAgQAEgQf
AEIBGnYgQSBwcm9jZXNzb3IgdHlwZSBpcyByZXNwb25zaWJsZSBmb3IgcGVyZm9ybWluZyBh
IGNlcnRhaW4gZG9jdW1lbnQKIHVuZGVyc3RhbmRpbmcgdGFzayBvbiBhIGNlcnRhaW4gdHlw
ZSBvZiBkb2N1bWVudC4KCgoKAwQAARIDHwgVCgsKAwQABxIEIAIjBAoNCgUEAAedCBIEIAIj
BApQCgQEAAMAEgQmAioDGkIgVGhlIGxvY2F0aW9uIGluZm9ybWF0aW9uIGFib3V0IHdoZXJl
IHRoZSBwcm9jZXNzb3IgaXMgYXZhaWxhYmxlLgoKDAoFBAADAAESAyYKFgqGAQoGBAADAAIA
EgMpBBsadyBUaGUgbG9jYXRpb24gSUQuIEZvciBzdXBwb3J0ZWQgbG9jYXRpb25zLCByZWZl
ciB0byBbcmVnaW9uYWwgYW5kCiBtdWx0aS1yZWdpb25hbCBzdXBwb3J0XSgvZG9jdW1lbnQt
YWkvZG9jcy9yZWdpb25zKS4KCg4KBwQAAwACAAUSAykECgoOCgcEAAMAAgABEgMpCxYKDgoH
BAADAAIAAxIDKRkaCnUKBAQAAgASAy4CEhpoIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBw
cm9jZXNzb3IgdHlwZS4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9wcm9jZXNzb3JU
eXBlcy97cHJvY2Vzc29yX3R5cGV9YAoKDAoFBAACAAUSAy4CCAoMCgUEAAIAARIDLgkNCgwK
BQQAAgADEgMuEBEKUQoEBAACARIDMQISGkQgVGhlIHByb2Nlc3NvciB0eXBlLCBzdWNoIGFz
OiBgT0NSX1BST0NFU1NPUmAsIGBJTlZPSUNFX1BST0NFU1NPUmAuCgoMCgUEAAIBBRIDMQII
CgwKBQQAAgEBEgMxCQ0KDAoFBAACAQMSAzEQEQpLCgQEAAICEgM0AhYaPiBUaGUgcHJvY2Vz
c29yIGNhdGVnb3J5LCB1c2VkIGJ5IFVJIHRvIGdyb3VwIHByb2Nlc3NvciB0eXBlcy4KCgwK
BQQAAgIFEgM0AggKDAoFBAACAgESAzQJEQoMCgUEAAICAxIDNBQVCkIKBAQAAgMSAzcCMBo1
IFRoZSBsb2NhdGlvbnMgaW4gd2hpY2ggdGhpcyBwcm9jZXNzb3IgaXMgYXZhaWxhYmxlLgoK
DAoFBAACAwQSAzcCCgoMCgUEAAIDBhIDNwsXCgwKBQQAAgMBEgM3GCsKDAoFBAACAwMSAzcu
LwqjAQoEBAACBBIDOwIaGpUBIFdoZXRoZXIgdGhlIHByb2Nlc3NvciB0eXBlIGFsbG93cyBj
cmVhdGlvbi4gSWYgdHJ1ZSwgdXNlcnMgY2FuIGNyZWF0ZSBhCiBwcm9jZXNzb3Igb2YgdGhp
cyBwcm9jZXNzb3IgdHlwZS4gT3RoZXJ3aXNlLCB1c2VycyBuZWVkIHRvIHJlcXVlc3QgYWNj
ZXNzLgoKDAoFBAACBAUSAzsCBgoMCgUEAAIEARIDOwcVCgwKBQQAAgQDEgM7GBkKMQoEBAAC
BRIDPgIqGiQgTGF1bmNoIHN0YWdlIG9mIHRoZSBwcm9jZXNzb3IgdHlwZQoKDAoFBAACBQYS
Az4CGAoMCgUEAAIFARIDPhklCgwKBQQAAgUDEgM+KCkKUgoEBAACBhIDQQIrGkUgQSBzZXQg
b2YgQ2xvdWQgU3RvcmFnZSBVUklzIG9mIHNhbXBsZSBkb2N1bWVudHMgZm9yIHRoaXMgcHJv
Y2Vzc29yLgoKDAoFBAACBgQSA0ECCgoMCgUEAAIGBRIDQQsRCgwKBQQAAgYBEgNBEiYKDAoF
BAACBgMSA0EpKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::ProcessorType::ProcessorType ===
    # Fields for ProcessorType
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: category Type: 9 ()
    # Field: available_locations Type: 11 (.google.cloud.documentai.v1beta3.ProcessorType.LocationInfo)
    # Field: allow_creation Type: 8 ()
    # Field: launch_stage Type: 14 (.google.api.LaunchStage)
    # Field: sample_document_uris Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::ProcessorType - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/processor_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::ProcessorType;

    my $msg = Google::Cloud::Documentai::V1beta3::ProcessorType::ProcessorType->new({
        name => $name,
        type => $type,
        category => $category,
        available_locations => $available_locations,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::ProcessorType::ProcessorType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/processor_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::ProcessorType::ProcessorType

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

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::ProcessorType::ProcessorType::LocationInfo>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::ProcessorType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
