package Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse;

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
CkZnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjFiZXRhMS9ydW5fYXNzZXRfZGlzY292
ZXJ5X3Jlc3BvbnNlLnByb3RvEiNnb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFiZXRh
MRoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIv0BChlSdW5Bc3NldERpc2NvdmVy
eVJlc3BvbnNlEloKBXN0YXRlGAEgASgOMkQuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVy
LnYxYmV0YTEuUnVuQXNzZXREaXNjb3ZlcnlSZXNwb25zZS5TdGF0ZVIFc3RhdGUSNQoIZHVy
YXRpb24YAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCGR1cmF0aW9uIk0KBVN0
YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDQoJQ09NUExFVEVEEAESDgoKU1VQRVJTRURF
RBACEg4KClRFUk1JTkFURUQQA0J8Cidjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVy
LnYxYmV0YTFQAVpPY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2MWJl
dGExL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYkrECwoGEgQOAC8BCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACgKCAoB
CBIDFABmCgkKAggLEgMUAGYKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgBACgkKAggB
EgMWAEAKLQoCBAASBBkALwEaISBSZXNwb25zZSBvZiBhc3NldCBkaXNjb3ZlcnkgcnVuCgoK
CgMEAAESAxkIIQo0CgQEAAQAEgQbAigDGiYgVGhlIHN0YXRlIG9mIGFuIGFzc2V0IGRpc2Nv
dmVyeSBydW4uCgoMCgUEAAQAARIDGwcMCjsKBgQABAACABIDHQQaGiwgQXNzZXQgZGlzY292
ZXJ5IHJ1biBzdGF0ZSB3YXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMdBBUKDgoHBAAE
AAIAAhIDHRgZCjwKBgQABAACARIDIAQSGi0gQXNzZXQgZGlzY292ZXJ5IHJ1biBjb21wbGV0
ZWQgc3VjY2Vzc2Z1bGx5LgoKDgoHBAAEAAIBARIDIAQNCg4KBwQABAACAQISAyAQEQqbAQoG
BAAEAAICEgMkBBMaiwEgQXNzZXQgZGlzY292ZXJ5IHJ1biB3YXMgY2FuY2VsbGVkIHdpdGgg
dGFza3Mgc3RpbGwgcGVuZGluZywgYXMgYW5vdGhlcgogcnVuIGZvciB0aGUgc2FtZSBvcmdh
bml6YXRpb24gd2FzIHN0YXJ0ZWQgd2l0aCBhIGhpZ2hlciBwcmlvcml0eS4KCg4KBwQABAAC
AgESAyQEDgoOCgcEAAQAAgICEgMkERIKPwoGBAAEAAIDEgMnBBMaMCBBc3NldCBkaXNjb3Zl
cnkgcnVuIHdhcyBraWxsZWQgYW5kIHRlcm1pbmF0ZWQuCgoOCgcEAAQAAgMBEgMnBA4KDgoH
BAAEAAIDAhIDJxESCjMKBAQAAgASAysCEhomIFRoZSBzdGF0ZSBvZiBhbiBhc3NldCBkaXNj
b3ZlcnkgcnVuLgoKDAoFBAACAAYSAysCBwoMCgUEAAIAARIDKwgNCgwKBQQAAgADEgMrEBEK
RQoEBAACARIDLgIoGjggVGhlIGR1cmF0aW9uIGJldHdlZW4gYXNzZXQgZGlzY292ZXJ5IHJ1
biBzdGFydCBhbmQgZW5kCgoMCgUEAAIBBhIDLgIaCgwKBQQAAgEBEgMuGyMKDAoFBAACAQMS
Ay4mJ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse ===
    # Fields for RunAssetDiscoveryResponse
    # Field: state Type: 14 (.google.cloud.securitycenter.v1beta1.RunAssetDiscoveryResponse.State)
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

Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1beta1/run_asset_discovery_response.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse;

    my $msg = Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse->new({
        state => $state,
        duration => $duration,
    });

    # Read or update a field
    my $val = $msg->state();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1beta1/run_asset_discovery_response.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse

Response of asset discovery run

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::State>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
