package Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvcnVuX2Fzc2V0X2Rpc2NvdmVyeV9y
ZXNwb25zZS5wcm90bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxGh5nb29nbGUv
cHJvdG9idWYvZHVyYXRpb24ucHJvdG8i+AEKGVJ1bkFzc2V0RGlzY292ZXJ5UmVzcG9uc2US
VQoFc3RhdGUYASABKA4yPy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuUnVuQXNz
ZXREaXNjb3ZlcnlSZXNwb25zZS5TdGF0ZVIFc3RhdGUSNQoIZHVyYXRpb24YAiABKAsyGS5n
b29nbGUucHJvdG9idWYuRHVyYXRpb25SCGR1cmF0aW9uIk0KBVN0YXRlEhUKEVNUQVRFX1VO
U1BFQ0lGSUVEEAASDQoJQ09NUExFVEVEEAESDgoKU1VQRVJTRURFRBACEg4KClRFUk1JTkFU
RUQQA0LYAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MVABWkpjbG91ZC5n
b29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2Vj
dXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2ds
ZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2Vu
dGVyOjpWMUqDDAoGEgQOADIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAnCgkKAgMAEgMSACgKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBhCgkK
AggLEgMVAGEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA7CgkKAggBEgMXADsKCAoB
CBIDGAA7CgkKAggpEgMYADsKCAoBCBIDGQA6CgkKAggtEgMZADoKLQoCBAASBBwAMgEaISBS
ZXNwb25zZSBvZiBhc3NldCBkaXNjb3ZlcnkgcnVuCgoKCgMEAAESAxwIIQo0CgQEAAQAEgQe
AisDGiYgVGhlIHN0YXRlIG9mIGFuIGFzc2V0IGRpc2NvdmVyeSBydW4uCgoMCgUEAAQAARID
HgcMCjsKBgQABAACABIDIAQaGiwgQXNzZXQgZGlzY292ZXJ5IHJ1biBzdGF0ZSB3YXMgdW5z
cGVjaWZpZWQuCgoOCgcEAAQAAgABEgMgBBUKDgoHBAAEAAIAAhIDIBgZCjwKBgQABAACARID
IwQSGi0gQXNzZXQgZGlzY292ZXJ5IHJ1biBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDgoH
BAAEAAIBARIDIwQNCg4KBwQABAACAQISAyMQEQqbAQoGBAAEAAICEgMnBBMaiwEgQXNzZXQg
ZGlzY292ZXJ5IHJ1biB3YXMgY2FuY2VsbGVkIHdpdGggdGFza3Mgc3RpbGwgcGVuZGluZywg
YXMgYW5vdGhlcgogcnVuIGZvciB0aGUgc2FtZSBvcmdhbml6YXRpb24gd2FzIHN0YXJ0ZWQg
d2l0aCBhIGhpZ2hlciBwcmlvcml0eS4KCg4KBwQABAACAgESAycEDgoOCgcEAAQAAgICEgMn
ERIKPwoGBAAEAAIDEgMqBBMaMCBBc3NldCBkaXNjb3ZlcnkgcnVuIHdhcyBraWxsZWQgYW5k
IHRlcm1pbmF0ZWQuCgoOCgcEAAQAAgMBEgMqBA4KDgoHBAAEAAIDAhIDKhESCjMKBAQAAgAS
Ay4CEhomIFRoZSBzdGF0ZSBvZiBhbiBhc3NldCBkaXNjb3ZlcnkgcnVuLgoKDAoFBAACAAYS
Ay4CBwoMCgUEAAIAARIDLggNCgwKBQQAAgADEgMuEBEKRQoEBAACARIDMQIoGjggVGhlIGR1
cmF0aW9uIGJldHdlZW4gYXNzZXQgZGlzY292ZXJ5IHJ1biBzdGFydCBhbmQgZW5kCgoMCgUE
AAIBBhIDMQIaCgwKBQQAAgEBEgMxGyMKDAoFBAACAQMSAzEmJ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse ===
    # Fields for RunAssetDiscoveryResponse
    # Field: state Type: 14 (.google.cloud.securitycenter.v1.RunAssetDiscoveryResponse.State)
    # Field: duration Type: 11 (.google.protobuf.Duration)

# Enum: RunAssetDiscoveryResponse::State
our $RunAssetDiscoveryResponse_STATE_UNSPECIFIED = 0;
our $RunAssetDiscoveryResponse_COMPLETED = 1;
our $RunAssetDiscoveryResponse_SUPERSEDED = 2;
our $RunAssetDiscoveryResponse_TERMINATED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/run_asset_discovery_response.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse;

    my $msg = Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse->new({
        state => $state,
        duration => $duration,
    });

    # Read or update a field
    my $val = $msg->state();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/run_asset_discovery_response.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse

Response of asset discovery run

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse::State>)

The state of an asset discovery run.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The duration between asset discovery run start and end

=back

=head3 Enum: RunAssetDiscoveryResponse::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<COMPLETED> => C<1>

=item * C<SUPERSEDED> => C<2>

=item * C<TERMINATED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::RunAssetDiscoveryResponse::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
