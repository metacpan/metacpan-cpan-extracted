package Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvY2xvdWRzZXR1cC9sb2dnaW5nL3YxL2NvbXBsZXRlX2RlcGxveW1l
bnQucHJvdG8SImdvb2dsZS5jbG91ZC5jbG91ZHNldHVwLmxvZ2dpbmcudjEaGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvItwCChdDb21wbGV0
ZURlcGxveW1lbnRFdmVudBJUCgV2YWx1ZRgBIAEoCzI8Lmdvb2dsZS5jbG91ZC5jbG91ZHNl
dHVwLmxvZ2dpbmcudjEuQ29tcGxldGVEZXBsb3ltZW50UmVzdWx0SABSBXZhbHVlEioKBWVy
cm9yGAIgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNIAFIFZXJyb3ISVwoFc3RhdGUYAyABKA4y
QS5nb29nbGUuY2xvdWQuY2xvdWRzZXR1cC5sb2dnaW5nLnYxLkNvbXBsZXRlRGVwbG95bWVu
dEV2ZW50LlN0YXRlUgVzdGF0ZRIhCgxwcmV2aWV3X29ubHkYBCABKAhSC3ByZXZpZXdPbmx5
IjkKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDQoJU1VDQ0VFREVEEAESCgoGRkFJ
TEVEEAJCCAoGcmVzdWx0IrkBChhDb21wbGV0ZURlcGxveW1lbnRSZXN1bHQSRQoKZGVwbG95
bWVudBgBIAEoCUIl+kEiCiBjb25maWcuZ29vZ2xlYXBpcy5jb20vRGVwbG95bWVudFIKZGVw
bG95bWVudBI8CgdwcmV2aWV3GAMgASgJQiL6QR8KHWNvbmZpZy5nb29nbGVhcGlzLmNvbS9Q
cmV2aWV3UgdwcmV2aWV3EhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2VC+AEKJmNvbS5nb29n
bGUuY2xvdWQuY2xvdWRzZXR1cC5sb2dnaW5nLnYxQhdDb21wbGV0ZURlcGxveW1lbnRQcm90
b1ABWkBjbG91ZC5nb29nbGUuY29tL2dvL2Nsb3Vkc2V0dXAvbG9nZ2luZy9hcGl2MS9sb2dn
aW5ncGI7bG9nZ2luZ3BiqgIiR29vZ2xlLkNsb3VkLkNsb3VkU2V0dXAuTG9nZ2luZy5WMcoC
Ikdvb2dsZVxDbG91ZFxDbG91ZFNldHVwXExvZ2dpbmdcVjHqAiZHb29nbGU6OkNsb3VkOjpD
bG91ZFNldHVwOjpMb2dnaW5nOjpWMUr2FwoGEgQOAFcBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACMKCQoCAwESAxMAIQoICgEIEgMV
AFcKCQoCCAsSAxUAVwoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADgKCQoCCAgSAxcA
OAoICgEIEgMYAD8KCQoCCAESAxgAPwoICgEIEgMZAD8KCQoCCCUSAxkAPwoICgEIEgMaAEAK
CQoCCCkSAxoAQAoICgEIEgMbAD8KCQoCCC0SAxsAPwr0BAoCBAASBCgARAEa5wQgSlNPTiBw
YXlsb2FkIGZvciB0aGUgQ2xvdWQgTG9nZ2luZyBldmVudDoKIGBvcmdhbml6YXRpb25zL1tv
cmdhbml6YXRpb25JZF0vbG9ncy9jbG91ZHNldHVwLmdvb2dsZWFwaXMuY29tJTJGY29tcGxl
dGVfZGVwbG95bWVudGAuCiBUaGlzIGV2ZW50IGdldHMgZW1pdHRlZCB1cG9uIGNvbXBsZXRp
b24gb2YgYSBjb25maWcgZGVwbG95bWVudCBhcyBwYXJ0IG9mIHRoZQogQ2xvdWQgU2V0dXAg
Q2hlY2tsaXN0LgoKIFRoZSBkZXBsb3ltZW50IGNhbiBmYWlsIGV2ZW4gaWYgaXQgcmV0dXJu
cyBhCiBgY29uZmlnLmdvb2dsZWFwaXMuY29tL0RlcGxveW1lbnRgLiBUaGUgc3RhdGUgb2Yg
dGhhdCBtZXNzYWdlIHdpbGwgYmUKIGBGQUlMRURgLiBIZW5jZSwgaWYgdGhlcmUgaXMgYSBg
dmFsdWVgIHByZXNlbnQsIHRoZSBgc3RhdGVgIGNhbiBzdGlsbCBiZSwKIGBGQUlMRURgLiBU
aGUgbWVzc2FnZSBmb3IgdGhlIGVycm9yIG9yIGZhaWx1cmUgd2lsbCBiZSBvbiB0aGUgYGVy
cm9yYCBvciB0aGUKIGB2YWx1ZWAgaWYgdGhlIE9wZXJhdGlvbiByZXN1bHRzIGluIGFuIGVy
cm9yIG9yIGlmIHRoZSBgc3RhdGVgIG9mIHRoZQogRGVwbG95bWVudCBpcyBgRkFJTEVEYCwg
cmVzcGVjdGl2ZWx5LgoKCgoDBAABEgMoCB8KMgoEBAAEABIEKgI1AxokIFN0YXRlIG9mIHRo
ZSBjb21wbGV0ZWQgZGVwbG95bWVudC4KCgwKBQQABAABEgMqBwwKUQoGBAAEAAIAEgMsBBoa
QiBUaGUgemVybyB2YWx1ZS4gSXQgaXMgYXBwbGllZCB3aGVuIGBzdGF0ZWAgaXMgdW5zZXQu
IERvIG5vdCB1c2UuCgoOCgcEAAQAAgABEgMsBBUKDgoHBAAEAAIAAhIDLBgZCpIBCgYEAAQA
AgESAzAEEhqCASBJbmRpY2F0ZXMgdGhhdCBhIERlcGxveW1lbnQgdmFsdWUgd2FzIHByZXNl
bnQgd2hlbiB0aGUgY29uZmlnIGRlcGxveW1lbnQKIGZpbmlzaGVkIGFuZCB0aGUgU3RhdGUg
d2FzIGFueXRoaW5nIG90aGVyIHRoYW4gRkFJTEVELgoKDgoHBAAEAAIBARIDMAQNCg4KBwQA
BAACAQISAzAQEQpoCgYEAAQAAgISAzQEDxpZIEluZGljYXRlcyB0aGF0IHRoZSBPcGVyYXRp
b24gcmVzdWx0IHdhcyBhbiBlcnJvciBvciB0aGUgRGVwbG95bWVudAogYHN0YXRlYCB3YXMg
RkFJTEVELgoKDgoHBAAEAAICARIDNAQKCg4KBwQABAACAgISAzQNDgoMCgQEAAgAEgQ3Aj0D
CgwKBQQACAABEgM3CA4KQQoEBAACABIDOQQnGjQgUmVzdWx0IG9mIHRoZSBEZXBsb3ltZW50
IHJlY29yZGVkIHVwb24gY29tcGxldGlvbi4KCgwKBQQAAgAGEgM5BBwKDAoFBAACAAESAzkd
IgoMCgUEAAIAAxIDOSUmCk8KBAQAAgESAzwEIBpCIFJlc3VsdCBvZiB0aGUgRGVwbG95bWVu
dCBpZiB0aGUgYE9wZXJhdGlvbmAgcmVzdWx0cyBpbiBhbiBlcnJvci4KCgwKBQQAAgEGEgM8
BBUKDAoFBAACAQESAzwWGwoMCgUEAAIBAxIDPB4fCj8KBAQAAgISA0ACEhoyIFRoZSBgc3Rh
dGVgIG9mIHRoaXMgZGVwbG95bWVudCBjb21wbGV0aW9uIGV2ZW50LgoKDAoFBAACAgYSA0AC
BwoMCgUEAAICARIDQAgNCgwKBQQAAgIDEgNAEBEKPgoEBAACAxIDQwIYGjEgRmxhZyB0byBp
bmRpY2F0ZSBpZiBkZXBsb3ltZW50IGlzIHByZXZpZXcgb25seS4KCgwKBQQAAgMFEgNDAgYK
DAoFBAACAwESA0MHEwoMCgUEAAIDAxIDQxYXClAKAgQBEgRHAFcBGkQgVGhpcyBtZXNzYWdl
IGlzIHVzZWQgd2hlbiB0aGUgQ29tcGxldGVEZXBsb3ltZW50RXZlbnQgaGFzIGEgdmFsdWUu
CgoKCgMEAQESA0cIIAp9CgQEAQIAEgRKAkwFGm8gVGhpcyBpcyB0aGUgRGVwbG95bWVudCB0
aGF0IGNvbXBsZXRlZC4KIEZvcm1hdCBpcyBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGVwbG95bWVudHMve25hbWV9LgoKDAoFBAECAAUSA0oCCAoMCgUEAQIA
ARIDSgkTCgwKBQQBAgADEgNKFhcKDQoFBAECAAgSBEoYTAQKDwoHBAECAAifCBIEShlMAwp5
CgQEAQIBEgRQAlIEGmsgVGhpcyBpcyB0aGUgUHJldmlldyB0aGF0IGNvbXBsZXRlZC4KIEZv
cm1hdCBpcyBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJldmll
d3Mve3ByZXZpZXd9CgoMCgUEAQIBBRIDUAIICgwKBQQBAgEBEgNQCRAKDAoFBAECAQMSA1AT
FAoNCgUEAQIBCBIEUBVSAwoOCgcEAQIBCJ8IEgNRBE8KlAEKBAQBAgISA1YCFRqGASBUaGUg
bWVzc2FnZSB0aGF0IGlzIHJldHVybmVkIHdoZW4gYSBkZXBsb3ltZW50IGNvbXBsZXRlcy4g
VGhpcyAqKmNhbioqIGJlCiBhbiBlcnJvciBtZXNzYWdlIGlmIHRoZSBgRGVwbG95bWVudGAg
YHN0YXRlYCBpcyBgRkFJTEVEYC4KCgwKBQQBAgIFEgNWAggKDAoFBAECAgESA1YJEAoMCgUE
AQICAxIDVhMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent ===
    # Fields for CompleteDeploymentEvent
    # Field: value Type: 11 (.google.cloud.cloudsetup.logging.v1.CompleteDeploymentResult)
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: state Type: 14 (.google.cloud.cloudsetup.logging.v1.CompleteDeploymentEvent.State)
    # Field: preview_only Type: 8 ()

# Enum: CompleteDeploymentEvent::State
our $CompleteDeploymentEvent_STATE_UNSPECIFIED = 0;
our $CompleteDeploymentEvent_SUCCEEDED = 1;
our $CompleteDeploymentEvent_FAILED = 2;

# === Message: Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentResult ===
    # Fields for CompleteDeploymentResult
    # Field: deployment Type: 9 ()
    # Field: preview Type: 9 ()
    # Field: message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment - Compiled Protocol Buffers messages for google/cloud/cloudsetup/logging/v1/complete_deployment.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment;

    my $msg = Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent->new({
        value => $value,
        error => $error,
        state => $state,
        preview_only => $preview_only,
    });

    # Read or update a field
    my $val = $msg->value();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudsetup/logging/v1/complete_deployment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent

JSON payload for the Cloud Logging event:
`organizations/[organizationId]/logs/cloudsetup.googleapis.com%2Fcomplete_deployment`.
This event gets emitted upon completion of a config deployment as part of the
Cloud Setup Checklist.

The deployment can fail even if it returns a
`config.googleapis.com/Deployment`. The state of that message will be
`FAILED`. Hence, if there is a `value` present, the `state` can still be,
`FAILED`. The message for the error or failure will be on the `error` or the
`value` if the Operation results in an error or if the `state` of the
Deployment is `FAILED`, respectively.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentResult>)

Result of the Deployment recorded upon completion.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Result of the Deployment if the `Operation` results in an error.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudsetup::Logging::V1::CompleteDeploymentEvent::State>)

The `state` of this deployment completion event.

=item * C<< $msg->preview_only() >> / C<< $msg->preview_only($value) >>

Type: C<Bool>

Flag to indicate if deployment is preview only.

=back

=head3 Enum: CompleteDeploymentEvent::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<FAILED> => C<2>

=back

=head2 Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentResult

This message is used when the CompleteDeploymentEvent has a value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<String>

This is the Deployment that completed.
Format is projects/{project}/locations/{location}/deployments/{name}.

=item * C<< $msg->preview() >> / C<< $msg->preview($value) >>

Type: C<String>

This is the Preview that completed.
Format is projects/{project}/locations/{location}/previews/{preview}

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

The message that is returned when a deployment completes. This B<can> be
an error message if the `Deployment` `state` is `FAILED`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
