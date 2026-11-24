package Google::Cloud::Securitycenter::V2::VertexAi;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvdmVydGV4X2FpLnByb3RvEh5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIixgIKCFZlcnRleEFpEkwKCGRhdGFzZXRzGAEg
AygLMjAuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLlZlcnRleEFpLkRhdGFzZXRS
CGRhdGFzZXRzEk8KCXBpcGVsaW5lcxgCIAMoCzIxLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52Mi5WZXJ0ZXhBaS5QaXBlbGluZVIJcGlwZWxpbmVzGlgKB0RhdGFzZXQSEgoEbmFt
ZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEhYKBnNv
dXJjZRgDIAEoCVIGc291cmNlGkEKCFBpcGVsaW5lEhIKBG5hbWUYASABKAlSBG5hbWUSIQoM
ZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZULnAQoiY29tLmdvb2dsZS5jbG91ZC5z
ZWN1cml0eWNlbnRlci52MkINVmVydGV4QWlQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dv
L3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJw
YqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1
cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMkq8DwoG
EgQOADkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggK
AQgSAxIAOwoJCgIIJRIDEgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJCgII
ChIDFAAiCggKAQgSAxUALgoJCgIICBIDFQAuCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgS
AxcAOwoJCgIIKRIDFwA7CggKAQgSAxgAOgoJCgIILRIDGAA6CkgKAgQAEgQbADkBGjwgVmVy
dGV4IEFJLXJlbGF0ZWQgaW5mb3JtYXRpb24gYXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5n
LgoKCgoDBAABEgMbCBAKPgoEBAADABIEHQIoAxowIFZlcnRleCBBSSBkYXRhc2V0IGFzc29j
aWF0ZWQgd2l0aCB0aGUgZmluZGluZy4KCgwKBQQAAwABEgMdChEKeQoGBAADAAIAEgMgBBQa
aiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBkYXRhc2V0LCBlLmcuCiBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YXNldHMvMjA5NDA0MDIzNjA2NDUwNTg1NgoK
DgoHBAADAAIABRIDIAQKCg4KBwQAAwACAAESAyALDwoOCgcEAAMAAgADEgMgEhMKTgoGBAAD
AAIBEgMjBBwaPyBUaGUgdXNlciBkZWZpbmVkIGRpc3BsYXkgbmFtZSBvZiBkYXRhc2V0LCBl
LmcuIHBsYW50cy1kYXRhc2V0CgoOCgcEAAMAAgEFEgMjBAoKDgoHBAADAAIBARIDIwsXCg4K
BwQAAwACAQMSAyMaGwpkCgYEAAMAAgISAycEFhpVIERhdGEgc291cmNlLCBzdWNoIGFzIGEg
QmlnUXVlcnkgc291cmNlIFVSSSwgZS5nLgogYnE6Ly9zY2MtbmV4dXMtdGVzdC5BSVBQdGVz
dC5nc29kCgoOCgcEAAMAAgIFEgMnBAoKDgoHBAADAAICARIDJwsRCg4KBwQAAwACAgMSAycU
FQpICgQEAAMBEgQrAjIDGjogVmVydGV4IEFJIHRyYWluaW5nIHBpcGVsaW5lIGFzc29jaWF0
ZWQgd2l0aCB0aGUgZmluZGluZy4KCgwKBQQAAwEBEgMrChIKgwEKBgQAAwECABIDLgQUGnQg
UmVzb3VyY2UgbmFtZSBvZiB0aGUgcGlwZWxpbmUsIGUuZy4KIHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90cmFpbmluZ1BpcGVsaW5lcy81MjUzNDI4MjI5MjI1
NTc4NDk2CgoOCgcEAAMBAgAFEgMuBAoKDgoHBAADAQIAARIDLgsPCg4KBwQAAwECAAMSAy4S
EwpWCgYEAAMBAgESAzEEHBpHIFRoZSB1c2VyLWRlZmluZWQgZGlzcGxheSBuYW1lIG9mIHBp
cGVsaW5lLCBlLmcuIHBsYW50cy1jbGFzc2lmaWNhdGlvbgoKDgoHBAADAQIBBRIDMQQKCg4K
BwQAAwECAQESAzELFwoOCgcEAAMBAgEDEgMxGhsKNAoEBAACABIDNQIgGicgRGF0YXNldHMg
YXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5nLgoKDAoFBAACAAQSAzUCCgoMCgUEAAIABhID
NQsSCgwKBQQAAgABEgM1ExsKDAoFBAACAAMSAzUeHwo1CgQEAAIBEgM4AiIaKCBQaXBlbGlu
ZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5nLgoKDAoFBAACAQQSAzgCCgoMCgUEAAIB
BhIDOAsTCgwKBQQAAgEBEgM4FB0KDAoFBAACAQMSAzggIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::VertexAi::VertexAi ===
    # Fields for VertexAi
    # Field: datasets Type: 11 (.google.cloud.securitycenter.v2.VertexAi.Dataset)
    # Field: pipelines Type: 11 (.google.cloud.securitycenter.v2.VertexAi.Pipeline)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::VertexAi - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/vertex_ai.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::VertexAi;

    my $msg = Google::Cloud::Securitycenter::V2::VertexAi::VertexAi->new({
        datasets => $datasets,
        pipelines => $pipelines,
    });

    # Read or update a field
    my $val = $msg->datasets();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::VertexAi::VertexAi->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/vertex_ai.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::VertexAi::VertexAi

Vertex AI-related information associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->datasets() >> / C<< $msg->datasets($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Dataset>)

Datasets associated with the finding.

=item * C<< $msg->pipelines() >> / C<< $msg->pipelines($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Pipeline>)

Pipelines associated with the finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::VertexAi::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
