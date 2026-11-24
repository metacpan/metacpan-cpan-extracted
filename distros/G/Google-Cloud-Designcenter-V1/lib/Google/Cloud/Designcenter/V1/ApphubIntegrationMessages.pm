package Google::Cloud::Designcenter::V1::ApphubIntegrationMessages;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Designcenter::V1::ApphubIntegration };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2FwcGh1Yl9pbnRlZ3JhdGlvbl9tZXNz
YWdlcy5wcm90bxIcZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo1Z29vZ2xl
L2Nsb3VkL2Rlc2lnbmNlbnRlci92MS9hcHBodWJfaW50ZWdyYXRpb24ucHJvdG8ioAIKKVJl
Z2lzdGVyQXBwSHViQXBwbGljYXRpb25SZXNvdXJjZXNSZXF1ZXN0Ei4KD3Rmc3RhdGVfY29u
dGVudBgCIAEoCUID4EEBSABSDnRmc3RhdGVDb250ZW50EjoKFnRmc3RhdGVfc2lnbmVkX2dj
c191cmkYAyABKAlCA+BBAUgAUhN0ZnN0YXRlU2lnbmVkR2NzVXJpEkEKBnBhcmVudBgBIAEo
CUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIy
ChJhcHBodWJfYXBwbGljYXRpb24YBCABKAlCA+BBAlIRYXBwaHViQXBwbGljYXRpb25CEAoO
dGZzdGF0ZV9zb3VyY2UigAEKKlJlZ2lzdGVyQXBwSHViQXBwbGljYXRpb25SZXNvdXJjZXNS
ZXNwb25zZRJSCghyZXNwb25zZRgBIAEoCzI2Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIu
djEuRGVwbG95ZWRSZXNvdXJjZVJlc3BvbnNlUghyZXNwb25zZSLnAQoYRGVwbG95ZWRSZXNv
dXJjZVJlc3BvbnNlEi0KEmFwcGh1Yl9hcHBsaWNhdGlvbhgBIAEoCVIRYXBwaHViQXBwbGlj
YXRpb24SMQoUcmVnaXN0ZXJlZF9yZXNvdXJjZXMYAiADKAlSE3JlZ2lzdGVyZWRSZXNvdXJj
ZXMSaQoWdW5yZWdpc3RlcmVkX3Jlc291cmNlcxgDIAMoCzIyLmdvb2dsZS5jbG91ZC5kZXNp
Z25jZW50ZXIudjEuVW5yZWdpc3RlcmVkUmVzb3VyY2VSFXVucmVnaXN0ZXJlZFJlc291cmNl
c0LtAQogY29tLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjFCIUFwcGh1YkludGVncmF0
aW9uUnBjTWVzc2FnZXNQcm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dvL2Rlc2lnbmNlbnRl
ci9hcGl2MS9kZXNpZ25jZW50ZXJwYjtkZXNpZ25jZW50ZXJwYqoCHEdvb2dsZS5DbG91ZC5E
ZXNpZ25DZW50ZXIuVjHKAhxHb29nbGVcQ2xvdWRcRGVzaWduQ2VudGVyXFYx6gIfR29vZ2xl
OjpDbG91ZDo6RGVzaWduQ2VudGVyOjpWMUqsFAoGEgQOAE4BCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgID
AhIDFAA/CggKAQgSAxYAOQoJCgIIJRIDFgA5CggKAQgSAxcAWwoJCgIICxIDFwBbCggKAQgS
AxgAIgoJCgIIChIDGAAiCggKAQgSAxkAQgoJCgIICBIDGQBCCggKAQgSAxoAOQoJCgIIARID
GgA5CggKAQgSAxsAOQoJCgIIKRIDGwA5CggKAQgSAxwAOAoJCgIILRIDHAA4CkwKAgQAEgQf
ADsBGkAgUmVxdWVzdCBtZXNzYWdlIGZvciBSZWdpc3RlckFwcEh1YkFwcGxpY2F0aW9uUmVz
b3VyY2VzIG1ldGhvZC4KCgoKAwQAARIDHwgxCjUKBAQACAASBCECLAMaJyBUaGUgVGVycmFm
b3JtIHN0YXRlICh0ZnN0YXRlKSBzb3VyY2UuCgoMCgUEAAgAARIDIQgWCqgBCgQEAAIAEgMl
BEgamgEgT3B0aW9uYWwuIFRoZSBUZXJyYWZvcm0gc3RhdGUgKHRmc3RhdGUpIGNvbnRlbnQg
YXMgYSByYXcgc3RyaW5nLgogRm9yIGxhcmdlIHN0YXRlIGZpbGVzIGV4Y2VlZGluZyAxME1C
LCB1c2UgdGhlICd0ZnN0YXRlX3NpZ25lZF9nY3NfdXJpJwogZmllbGQgaW5zdGVhZC4KCgwK
BQQAAgAFEgMlBAoKDAoFBAACAAESAyULGgoMCgUEAAIAAxIDJR0eCgwKBQQAAgAIEgMlH0cK
DwoIBAACAAicCAASAyUgRgqaAgoEBAACARIDKwRPGowCIE9wdGlvbmFsLiBBIHNlY3VyZWx5
IHNpZ25lZCBDbG91ZCBTdG9yYWdlIFVSSSBwb2ludGluZyB0byB0aGUgdGZzdGF0ZQogZmls
ZS4gVGhlIFVSSSBtdXN0IGJlIHNpZ25lZCB0byBncmFudCB0aGUgc2VydmljZSB0ZW1wb3Jh
cnkgcmVhZCBhY2Nlc3MKIHRvIHRoZSBzdGF0ZSBmaWxlLiBBcHBsaWNhdGlvbiBEZXNpZ24g
Q2VudGVyIGltcG9zZXMgYSBsaW1pdCBvbiB0aGUKIG1heGltdW0gc2l6ZSBvZiB0aGUgc3Rh
dGUgZmlsZSBhY2Nlc3NlZCB2aWEgdGhpcyBVUkkuCgoMCgUEAAIBBRIDKwQKCgwKBQQAAgEB
EgMrCyEKDAoFBAACAQMSAyskJQoMCgUEAAIBCBIDKyZOCg8KCAQAAgEInAgAEgMrJ00KXwoE
BAACAhIEMAI1BBpRIFJlcXVpcmVkLiBUaGUgcGFyZW50IGxvY2F0aW9uLgogRm9ybWF0OiBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQAAgIFEgMwAggK
DAoFBAACAgESAzAJDwoMCgUEAAICAxIDMBITCg0KBQQAAgIIEgQwFDUDCg8KCAQAAgIInAgA
EgMxBCoKDwoHBAACAgifCBIEMgQ0BQqJAQoEBAACAxIDOgJJGnwgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBBcHBIdWIgQXBwbGljYXRpb24uCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwbGljYXRpb25zL3thcHBsaWNhdGlvbn0K
CgwKBQQAAgMFEgM6AggKDAoFBAACAwESAzoJGwoMCgUEAAIDAxIDOh4fCgwKBQQAAgMIEgM6
IEgKDwoIBAACAwicCAASAzohRwpNCgIEARIEPgBCARpBIFJlc3BvbnNlIG1lc3NhZ2UgZm9y
IFJlZ2lzdGVyQXBwSHViQXBwbGljYXRpb25SZXNvdXJjZXMgbWV0aG9kLgoKCgoDBAEBEgM+
CDIKZgoEBAECABIDQQIoGlkgVGhlIHJlc3BvbnNlIGZvciB0aGUgcmVnaXN0cmF0aW9uIG9m
IGRlcGxveWVkIHJlc291cmNlcyBvZiBhIGdpdmVuIEFwcEh1YgogYXBwbGljYXRpb24uCgoM
CgUEAQIABhIDQQIaCgwKBQQBAgABEgNBGyMKDAoFBAECAAMSA0EmJwpMCgIEAhIERQBOARpA
IENvbW1vbiByZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgcmVzb3VyY2UgcmVnaXN0cmF0aW9u
IG1ldGhvZHMuCgoKCgMEAgESA0UIIAosCgQEAgIAEgNHAiAaHyBUaGUgQXBwIEh1YiBhcHBs
aWNhdGlvbiBuYW1lLgoKDAoFBAICAAUSA0cCCAoMCgUEAgIAARIDRwkbCgwKBQQCAgADEgNH
Hh8KQQoEBAICARIDSgIrGjQgVGhlIGxpc3Qgb2Ygc3VjY2Vzc2Z1bGx5IHJlZ2lzdGVyZWQg
R0NQIHJlc291cmNlcy4KCgwKBQQCAgEEEgNKAgoKDAoFBAICAQUSA0oLEQoMCgUEAgIBARID
ShImCgwKBQQCAgEDEgNKKSoKSQoEBAICAhIDTQI7GjwgVGhlIGxpc3Qgb2YgdW5yZWdpc3Rl
cmVkIEdDUCByZXNvdXJjZXMgd2l0aCBlcnJvciBkZXRhaWxzLgoKDAoFBAICAgQSA00CCgoM
CgUEAgICBhIDTQsfCgwKBQQCAgIBEgNNIDYKDAoFBAICAgMSA005OmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest ===
    # Fields for RegisterAppHubApplicationResourcesRequest
    # Field: tfstate_content Type: 9 ()
    # Field: tfstate_signed_gcs_uri Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: apphub_application Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesResponse ===
    # Fields for RegisterAppHubApplicationResourcesResponse
    # Field: response Type: 11 (.google.cloud.designcenter.v1.DeployedResourceResponse)

# === Message: Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::DeployedResourceResponse ===
    # Fields for DeployedResourceResponse
    # Field: apphub_application Type: 9 ()
    # Field: registered_resources Type: 9 ()
    # Field: unregistered_resources Type: 11 (.google.cloud.designcenter.v1.UnregisteredResource)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::ApphubIntegrationMessages - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/apphub_integration_messages.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::ApphubIntegrationMessages;

    my $msg = Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest->new({
        tfstate_content => $tfstate_content,
        tfstate_signed_gcs_uri => $tfstate_signed_gcs_uri,
        parent => $parent,
        apphub_application => $apphub_application,
    });

    # Read or update a field
    my $val = $msg->tfstate_content();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/apphub_integration_messages.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest

Request message for RegisterAppHubApplicationResources method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tfstate_content() >> / C<< $msg->tfstate_content($value) >>

Type: C<String>

Optional. The Terraform state (tfstate) content as a raw string.
For large state files exceeding 10MB, use the 'tfstate_signed_gcs_uri'
field instead.

=item * C<< $msg->tfstate_signed_gcs_uri() >> / C<< $msg->tfstate_signed_gcs_uri($value) >>

Type: C<String>

Optional. A securely signed Cloud Storage URI pointing to the tfstate
file. The URI must be signed to grant the service temporary read access
to the state file. Application Design Center imposes a limit on the
maximum size of the state file accessed via this URI.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location.
Format: projects/{project}/locations/{location}

=item * C<< $msg->apphub_application() >> / C<< $msg->apphub_application($value) >>

Type: C<String>

Required. The name of the AppHub Application.
Format:
projects/{project}/locations/{location}/applications/{application}

=back

=head2 Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesResponse

Response message for RegisterAppHubApplicationResources method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::DeployedResourceResponse>)

The response for the registration of deployed resources of a given AppHub
application.

=back

=head2 Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::DeployedResourceResponse

Common response message for the resource registration methods.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->apphub_application() >> / C<< $msg->apphub_application($value) >>

Type: C<String>

The App Hub application name.

=item * C<< $msg->registered_resources() >> / C<< $msg->registered_resources($value) >>

Type: C<String>

The list of successfully registered GCP resources.

=item * C<< $msg->unregistered_resources() >> / C<< $msg->unregistered_resources($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource>)

The list of unregistered GCP resources with error details.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
