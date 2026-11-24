package Google::Cloud::Discoveryengine::V1alpha::RankService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvcmFua19zZXJ2aWNlLnBy
b3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvImUKDVJh
bmtpbmdSZWNvcmQSDgoCaWQYASABKAlSAmlkEhQKBXRpdGxlGAIgASgJUgV0aXRsZRIYCgdj
b250ZW50GAMgASgJUgdjb250ZW50EhQKBXNjb3JlGAQgASgCUgVzY29yZSLsAwoLUmFua1Jl
cXVlc3QSWwoOcmFua2luZ19jb25maWcYASABKAlCNOBBAvpBLgosZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29tL1JhbmtpbmdDb25maWdSDXJhbmtpbmdDb25maWcSFAoFbW9kZWwY
AiABKAlSBW1vZGVsEhMKBXRvcF9uGAMgASgFUgR0b3BOEhQKBXF1ZXJ5GAQgASgJUgVxdWVy
eRJSCgdyZWNvcmRzGAUgAygLMjMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLlJhbmtpbmdSZWNvcmRCA+BBAlIHcmVjb3JkcxJICiFpZ25vcmVfcmVjb3JkX2RldGFp
bHNfaW5fcmVzcG9uc2UYBiABKAhSHWlnbm9yZVJlY29yZERldGFpbHNJblJlc3BvbnNlEmIK
C3VzZXJfbGFiZWxzGAcgAygLMkEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLlJhbmtSZXF1ZXN0LlVzZXJMYWJlbHNFbnRyeVIKdXNlckxhYmVscxo9Cg9Vc2VyTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJd
CgxSYW5rUmVzcG9uc2USTQoHcmVjb3JkcxgFIAMoCzIzLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5SYW5raW5nUmVjb3JkUgdyZWNvcmRzMqQCCgtSYW5rU2Vydmlj
ZRLAAQoEUmFuaxIxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SYW5r
UmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SYW5rUmVz
cG9uc2UiUYLT5JMCSyJGL3YxYWxwaGEve3JhbmtpbmdfY29uZmlnPXByb2plY3RzLyovbG9j
YXRpb25zLyovcmFua2luZ0NvbmZpZ3MvKn06cmFuazoBKhpSykEeZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybUKcAgooY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YUIQUmFua1NlcnZpY2VQcm90b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVu
Z2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIP
RElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhh
ygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91
ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhhSqAjCgcSBQ4AhQEBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJ
CgIDAhIDFAApCgkKAgMDEgMVACMKCAoBCBIDFwBBCgkKAgglEgMXAEEKCAoBCBIDGABpCgkK
AggLEgMYAGkKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAxCgkKAggIEgMaADEKCAoB
CBIDGwBBCgkKAggBEgMbAEEKCAoBCBIDHAAtCgkKAggkEgMcAC0KCAoBCBIDHQBBCgkKAggp
EgMdAEEKCAoBCBIDHgBACgkKAggtEgMeAEAKLwoCBgASBCEALQEaIyBTZXJ2aWNlIGZvciBy
YW5raW5nIHRleHQgcmVjb3Jkcy4KCgoKAwYAARIDIQgTCgoKAwYAAxIDIgJGCgwKBQYAA5kI
EgMiAkYKCwoDBgADEgQjAiQ3Cg0KBQYAA5oIEgQjAiQ3CkwKBAYAAgASBCcCLAMaPiBSYW5r
cyBhIGxpc3Qgb2YgdGV4dCByZWNvcmRzIGJhc2VkIG9uIHRoZSBnaXZlbiBpbnB1dCBxdWVy
eS4KCgwKBQYAAgABEgMnBgoKDAoFBgACAAISAycLFgoMCgUGAAIAAxIDJyEtCg0KBQYAAgAE
EgQoBCsGChEKCQYAAgAEsMq8IhIEKAQrBgp0CgIEABIEMgBGARpoIFJlY29yZCBtZXNzYWdl
IGZvcgogW1JhbmtTZXJ2aWNlLlJhbmtdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5SYW5rU2VydmljZS5SYW5rXQogbWV0aG9kLgoKCgoDBAABEgMyCBUKNQoEBAAC
ABIDNAIQGiggVGhlIHVuaXF1ZSBJRCB0byByZXByZXNlbnQgdGhlIHJlY29yZC4KCgwKBQQA
AgAFEgM0AggKDAoFBAACAAESAzQJCwoMCgUEAAIAAxIDNA4PCpYCCgQEAAIBEgM7AhMaiAIg
VGhlIHRpdGxlIG9mIHRoZSByZWNvcmQuIEVtcHR5IGJ5IGRlZmF1bHQuCiBBdCBsZWFzdCBv
bmUgb2YKIFt0aXRsZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlJh
bmtpbmdSZWNvcmQudGl0bGVdIG9yCiBbY29udGVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlJhbmtpbmdSZWNvcmQuY29udGVudF0KIHNob3VsZCBiZSBzZXQg
b3RoZXJ3aXNlIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgdGhyb3duLgoKDAoFBAAC
AQUSAzsCCAoMCgUEAAIBARIDOwkOCgwKBQQAAgEDEgM7ERIKmAIKBAQAAgISA0ICFRqKAiBU
aGUgY29udGVudCBvZiB0aGUgcmVjb3JkLiBFbXB0eSBieSBkZWZhdWx0LgogQXQgbGVhc3Qg
b25lIG9mCiBbdGl0bGVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5S
YW5raW5nUmVjb3JkLnRpdGxlXSBvcgogW2NvbnRlbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5SYW5raW5nUmVjb3JkLmNvbnRlbnRdCiBzaG91bGQgYmUgc2V0
IG90aGVyd2lzZSBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHRocm93bi4KCgwKBQQA
AgIFEgNCAggKDAoFBAACAgESA0IJEAoMCgUEAAICAxIDQhMUClQKBAQAAgMSA0UCEhpHIFRo
ZSBzY29yZSBvZiB0aGlzIHJlY29yZCBiYXNlZCBvbiB0aGUgZ2l2ZW4gcXVlcnkgYW5kIHNl
bGVjdGVkIG1vZGVsLgoKDAoFBAACAwUSA0UCBwoMCgUEAAIDARIDRQgNCgwKBQQAAgMDEgNF
EBEKdQoCBAESBEsAfQEaaSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbUmFua1NlcnZpY2UuUmFu
a11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlJhbmtTZXJ2aWNlLlJh
bmtdCiBtZXRob2QuCgoKCgMEAQESA0sIEwqpAQoEBAECABIETgJTBBqaASBSZXF1aXJlZC4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHJhbmsgc2VydmljZSBjb25maWcsIHN1Y2ggYXMK
IGBwcm9qZWN0cy97cHJvamVjdF9udW19L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L3Jhbmtp
bmdDb25maWdzL2RlZmF1bHRfcmFua2luZ19jb25maWdgLgoKDAoFBAECAAUSA04CCAoMCgUE
AQIAARIDTgkXCgwKBQQBAgADEgNOGhsKDQoFBAECAAgSBE4cUwMKDwoIBAECAAicCAASA08E
KgoPCgcEAQIACJ8IEgRQBFIFCuUBCgQEAQIBEgNbAhMa1wEgVGhlIGlkZW50aWZpZXIgb2Yg
dGhlIG1vZGVsIHRvIHVzZS4gSXQgaXMgb25lIG9mOgoKICogYHNlbWFudGljLXJhbmtlci01
MTJAbGF0ZXN0YDogU2VtYW50aWMgcmFua2luZyBtb2RlbCB3aXRoIG1heGl1bW4gaW5wdXQK
IHRva2VuIHNpemUgNTEyLgoKIEl0IGlzIHNldCB0byBgc2VtYW50aWMtcmFua2VyLTUxMkBs
YXRlc3RgIGJ5IGRlZmF1bHQgaWYgdW5zcGVjaWZpZWQuCgoMCgUEAQIBBRIDWwIICgwKBQQB
AgEBEgNbCQ4KDAoFBAECAQMSA1sREgpuCgQEAQICEgNfAhIaYSBUaGUgbnVtYmVyIG9mIHJl
c3VsdHMgdG8gcmV0dXJuLiBJZiB0aGlzIGlzIHVuc2V0IG9yIG5vIGJpZ2dlciB0aGFuIHpl
cm8sCiByZXR1cm5zIGFsbCByZXN1bHRzLgoKDAoFBAECAgUSA18CBwoMCgUEAQICARIDXwgN
CgwKBQQBAgIDEgNfEBEKIAoEBAECAxIDYgITGhMgVGhlIHF1ZXJ5IHRvIHVzZS4KCgwKBQQB
AgMFEgNiAggKDAoFBAECAwESA2IJDgoMCgUEAQIDAxIDYhESClAKBAQBAgQSA2UCThpDIFJl
cXVpcmVkLiBBIGxpc3Qgb2YgcmVjb3JkcyB0byByYW5rLiBBdCBtb3N0IDIwMCByZWNvcmRz
IHRvIHJhbmsuCgoMCgUEAQIEBBIDZQIKCgwKBQQBAgQGEgNlCxgKDAoFBAECBAESA2UZIAoM
CgUEAQIEAxIDZSMkCgwKBQQBAgQIEgNlJU0KDwoIBAECBAicCAASA2UmTAqQAQoEBAECBRID
aQItGoIBIElmIHRydWUsIHRoZSByZXNwb25zZSB3aWxsIGNvbnRhaW4gb25seSByZWNvcmQg
SUQgYW5kIHNjb3JlLiBCeSBkZWZhdWx0LCBpdAogaXMgZmFsc2UsIHRoZSByZXNwb25zZSB3
aWxsIGNvbnRhaW4gcmVjb3JkIGRldGFpbHMuCgoMCgUEAQIFBRIDaQIGCgwKBQQBAgUBEgNp
BygKDAoFBAECBQMSA2krLArrBgoEBAECBhIDfAImGt0GIFRoZSB1c2VyIGxhYmVscyBhcHBs
aWVkIHRvIGEgcmVzb3VyY2UgbXVzdCBtZWV0IHRoZSBmb2xsb3dpbmcgcmVxdWlyZW1lbnRz
OgoKICogRWFjaCByZXNvdXJjZSBjYW4gaGF2ZSBtdWx0aXBsZSBsYWJlbHMsIHVwIHRvIGEg
bWF4aW11bSBvZiA2NC4KICogRWFjaCBsYWJlbCBtdXN0IGJlIGEga2V5LXZhbHVlIHBhaXIu
CiAqIEtleXMgaGF2ZSBhIG1pbmltdW0gbGVuZ3RoIG9mIDEgY2hhcmFjdGVyIGFuZCBhIG1h
eGltdW0gbGVuZ3RoIG9mIDYzCiAgIGNoYXJhY3RlcnMgYW5kIGNhbm5vdCBiZSBlbXB0eS4g
VmFsdWVzIGNhbiBiZSBlbXB0eSBhbmQgaGF2ZSBhIG1heGltdW0KICAgbGVuZ3RoIG9mIDYz
IGNoYXJhY3RlcnMuCiAqIEtleXMgYW5kIHZhbHVlcyBjYW4gY29udGFpbiBvbmx5IGxvd2Vy
Y2FzZSBsZXR0ZXJzLCBudW1lcmljIGNoYXJhY3RlcnMsCiAgIHVuZGVyc2NvcmVzLCBhbmQg
ZGFzaGVzLiBBbGwgY2hhcmFjdGVycyBtdXN0IHVzZSBVVEYtOCBlbmNvZGluZywgYW5kCiAg
IGludGVybmF0aW9uYWwgY2hhcmFjdGVycyBhcmUgYWxsb3dlZC4KICogVGhlIGtleSBwb3J0
aW9uIG9mIGEgbGFiZWwgbXVzdCBiZSB1bmlxdWUuIEhvd2V2ZXIsIHlvdSBjYW4gdXNlIHRo
ZSBzYW1lCiAgIGtleSB3aXRoIG11bHRpcGxlIHJlc291cmNlcy4KICogS2V5cyBtdXN0IHN0
YXJ0IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIG9yIGludGVybmF0aW9uYWwgY2hhcmFjdGVy
LgoKIFNlZSBbR29vZ2xlIENsb3VkCiBEb2N1bWVudF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGluZy1tYW5hZ2luZy1sYWJlbHMjcmVx
dWlyZW1lbnRzKQogZm9yIG1vcmUgZGV0YWlscy4KCgwKBQQBAgYGEgN8AhUKDAoFBAECBgES
A3wWIQoMCgUEAQIGAxIDfCQlCngKAgQCEgaCAQCFAQEaaiBSZXNwb25zZSBtZXNzYWdlIGZv
cgogW1JhbmtTZXJ2aWNlLlJhbmtdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5SYW5rU2VydmljZS5SYW5rXQogbWV0aG9kLgoKCwoDBAIBEgSCAQgUCj0KBAQCAgAS
BIQBAiUaLyBBIGxpc3Qgb2YgcmVjb3JkcyBzb3J0ZWQgYnkgZGVzY2VuZGluZyBzY29yZS4K
Cg0KBQQCAgAEEgSEAQIKCg0KBQQCAgAGEgSEAQsYCg0KBQQCAgABEgSEARkgCg0KBQQCAgAD
EgSEASMkYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord ===
    # Fields for RankingRecord
    # Field: id Type: 9 ()
    # Field: title Type: 9 ()
    # Field: content Type: 9 ()
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest ===
    # Fields for RankRequest
    # Field: ranking_config Type: 9 ()
    # Field: model Type: 9 ()
    # Field: top_n Type: 5 ()
    # Field: query Type: 9 ()
    # Field: records Type: 11 (.google.cloud.discoveryengine.v1alpha.RankingRecord)
    # Field: ignore_record_details_in_response Type: 8 ()
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1alpha.RankRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse ===
    # Fields for RankResponse
    # Field: records Type: 11 (.google.cloud.discoveryengine.v1alpha.RankingRecord)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::RankService::RankServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::RankService::RankServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::RankService::RankServiceClient

Client stub representing the remote C<RankService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub rank {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.RankService',
        method         => 'Rank',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::RankService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/rank_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::RankService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord->new({
        id => $id,
        title => $title,
        content => $content,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/rank_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord

Record message for
[RankService.Rank][google.cloud.discoveryengine.v1alpha.RankService.Rank]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The unique ID to represent the record.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

The title of the record. Empty by default.
At least one of
[title][google.cloud.discoveryengine.v1alpha.RankingRecord.title] or
[content][google.cloud.discoveryengine.v1alpha.RankingRecord.content]
should be set otherwise an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

The content of the record. Empty by default.
At least one of
[title][google.cloud.discoveryengine.v1alpha.RankingRecord.title] or
[content][google.cloud.discoveryengine.v1alpha.RankingRecord.content]
should be set otherwise an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

The score of this record based on the given query and selected model.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest

Request message for
[RankService.Rank][google.cloud.discoveryengine.v1alpha.RankService.Rank]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ranking_config() >> / C<< $msg->ranking_config($value) >>

Type: C<String>

Required. The resource name of the rank service config, such as
`projects/{project_num}/locations/{location_id}/rankingConfigs/default_ranking_config`.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The identifier of the model to use. It is one of:

* `semantic-ranker-512@latest`: Semantic ranking model with maxiumn input
token size 512.

It is set to `semantic-ranker-512@latest` by default if unspecified.

=item * C<< $msg->top_n() >> / C<< $msg->top_n($value) >>

Type: C<Int32>

The number of results to return. If this is unset or no bigger than zero,
returns all results.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

The query to use.

=item * C<< $msg->records() >> / C<< $msg->records($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord>)

Required. A list of records to rank. At most 200 records to rank.

=item * C<< $msg->ignore_record_details_in_response() >> / C<< $msg->ignore_record_details_in_response($value) >>

Type: C<Bool>

If true, the response will contain only record ID and score. By default, it
is false, the response will contain record details.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest::UserLabelsEntry>)

The user labels applied to a resource must meet the following requirements:

* Each resource can have multiple labels, up to a maximum of 64.
* Each label must be a key-value pair.
* Keys have a minimum length of 1 character and a maximum length of 63
  characters and cannot be empty. Values can be empty and have a maximum
  length of 63 characters.
* Keys and values can contain only lowercase letters, numeric characters,
  underscores, and dashes. All characters must use UTF-8 encoding, and
  international characters are allowed.
* The key portion of a label must be unique. However, you can use the same
  key with multiple resources.
* Keys must start with a lowercase letter or international character.

See [Google Cloud
Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
for more details.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse

Response message for
[RankService.Rank][google.cloud.discoveryengine.v1alpha.RankService.Rank]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->records() >> / C<< $msg->records($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord>)

A list of records sorted by descending score.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::RankService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
