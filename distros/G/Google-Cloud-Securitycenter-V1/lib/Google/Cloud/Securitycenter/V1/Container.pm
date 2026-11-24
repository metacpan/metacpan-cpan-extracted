package Google::Cloud::Securitycenter::V1::Container;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Securitycenter::V1::Label };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvY29udGFpbmVyLnByb3RvEh5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaKmdvb2dsZS9jbG91ZC9zZWN1cml0eWNlbnRl
ci92MS9sYWJlbC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLIAQoJ
Q29udGFpbmVyEhIKBG5hbWUYASABKAlSBG5hbWUSEAoDdXJpGAIgASgJUgN1cmkSGQoIaW1h
Z2VfaWQYAyABKAlSB2ltYWdlSWQSPQoGbGFiZWxzGAQgAygLMiUuZ29vZ2xlLmNsb3VkLnNl
Y3VyaXR5Y2VudGVyLnYxLkxhYmVsUgZsYWJlbHMSOwoLY3JlYXRlX3RpbWUYBSABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lQugBCiJjb20uZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYxQg5Db250YWluZXJQcm90b1ABWkpjbG91ZC5nb29nbGUu
Y29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHlj
ZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91
ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpW
MUqHDAoGEgQOAC8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAnCgkKAgMAEgMSADQKCQoCAwESAxMAKQoICgEIEgMVADsKCQoCCCUSAxUAOwoICgEIEgMW
AGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC8KCQoCCAgSAxgA
LwoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoICgEIEgMbADoK
CQoCCC0SAxsAOgo0CgIEABIEHgAvARooIENvbnRhaW5lciBhc3NvY2lhdGVkIHdpdGggdGhl
IGZpbmRpbmcuCgoKCgMEAAESAx4IEQolCgQEAAIAEgMgAhIaGCBOYW1lIG9mIHRoZSBjb250
YWluZXIuCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCQ0KDAoFBAACAAMSAyAQEQqZAQoE
BAACARIDJAIRGosBIENvbnRhaW5lciBpbWFnZSBVUkkgcHJvdmlkZWQgd2hlbiBjb25maWd1
cmluZyBhIHBvZCBvciBjb250YWluZXIuIFRoaXMKIHN0cmluZyBjYW4gaWRlbnRpZnkgYSBj
b250YWluZXIgaW1hZ2UgdmVyc2lvbiB1c2luZyBtdXRhYmxlIHRhZ3MuCgoMCgUEAAIBBRID
JAIICgwKBQQAAgEBEgMkCQwKDAoFBAACAQMSAyQPEAqkAQoEBAACAhIDKAIWGpYBIE9wdGlv
bmFsIGNvbnRhaW5lciBpbWFnZSBJRCwgaWYgcHJvdmlkZWQgYnkgdGhlIGNvbnRhaW5lciBy
dW50aW1lLiBVbmlxdWVseQogaWRlbnRpZmllcyB0aGUgY29udGFpbmVyIGltYWdlIGxhdW5j
aGVkIHVzaW5nIGEgY29udGFpbmVyIGltYWdlIGRpZ2VzdC4KCgwKBQQAAgIFEgMoAggKDAoF
BAACAgESAygJEQoMCgUEAAICAxIDKBQVCkYKBAQAAgMSAysCHBo5IENvbnRhaW5lciBsYWJl
bHMsIGFzIHByb3ZpZGVkIGJ5IHRoZSBjb250YWluZXIgcnVudGltZS4KCgwKBQQAAgMEEgMr
AgoKDAoFBAACAwYSAysLEAoMCgUEAAIDARIDKxEXCgwKBQQAAgMDEgMrGhsKNwoEBAACBBID
LgIsGiogVGhlIHRpbWUgdGhhdCB0aGUgY29udGFpbmVyIHdhcyBjcmVhdGVkLgoKDAoFBAAC
BAYSAy4CGwoMCgUEAAIEARIDLhwnCgwKBQQAAgQDEgMuKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Container::Container ===
    # Fields for Container
    # Field: name Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: image_id Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.securitycenter.v1.Label)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Container - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/container.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Container;

    my $msg = Google::Cloud::Securitycenter::V1::Container::Container->new({
        name => $name,
        uri => $uri,
        image_id => $image_id,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Container::Container->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/container.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Container::Container

Container associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the container.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Container image URI provided when configuring a pod or container. This
string can identify a container image version using mutable tags.

=item * C<< $msg->image_id() >> / C<< $msg->image_id($value) >>

Type: C<String>

Optional container image ID, if provided by the container runtime. Uniquely
identifies the container image launched using a container image digest.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Label::Label>)

Container labels, as provided by the container runtime.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time that the container was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Container::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
