package Google::Cloud::Discoveryengine::V1alpha::ServingConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::ServingConfig };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2VydmluZ19jb25maWdf
c2VydmljZS5wcm90bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxo5Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL3NlcnZpbmdfY29u
ZmlnLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byK6AQoaVXBkYXRl
U2VydmluZ0NvbmZpZ1JlcXVlc3QSXwoOc2VydmluZ19jb25maWcYASABKAsyMy5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VydmluZ0NvbmZpZ0ID4EECUg1zZXJ2
aW5nQ29uZmlnEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxk
TWFza1IKdXBkYXRlTWFzayJjChdHZXRTZXJ2aW5nQ29uZmlnUmVxdWVzdBJICgRuYW1lGAEg
ASgJQjTgQQL6QS4KLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TZXJ2aW5nQ29u
ZmlnUgRuYW1lIq8BChlMaXN0U2VydmluZ0NvbmZpZ3NSZXF1ZXN0EkwKBnBhcmVudBgBIAEo
CUI04EEC+kEuEixkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZp
Z1IGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rv
a2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKiAQoaTGlzdFNlcnZpbmdDb25maWdzUmVzcG9u
c2USXAoPc2VydmluZ19jb25maWdzGAEgAygLMjMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlNlcnZpbmdDb25maWdSDnNlcnZpbmdDb25maWdzEiYKD25leHRfcGFn
ZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbjKRCwoUU2VydmluZ0NvbmZpZ1NlcnZpY2US
/wMKE1VwZGF0ZVNlcnZpbmdDb25maWcSQC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuVXBkYXRlU2VydmluZ0NvbmZpZ1JlcXVlc3QaMy5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VydmluZ0NvbmZpZyLwAoLT5JMCzAIyUy92MWFscGhh
L3tzZXJ2aW5nX2NvbmZpZy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jl
cy8qL3NlcnZpbmdDb25maWdzLyp9Og5zZXJ2aW5nX2NvbmZpZ1pzMmEvdjFhbHBoYS97c2Vy
dmluZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyov
ZGF0YVN0b3Jlcy8qL3NlcnZpbmdDb25maWdzLyp9Og5zZXJ2aW5nX2NvbmZpZ1pwMl4vdjFh
bHBoYS97c2VydmluZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxl
Y3Rpb25zLyovZW5naW5lcy8qL3NlcnZpbmdDb25maWdzLyp9Og5zZXJ2aW5nX2NvbmZpZ9pB
GnNlcnZpbmdfY29uZmlnLHVwZGF0ZV9tYXNrEoYDChBHZXRTZXJ2aW5nQ29uZmlnEj0uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdldFNlcnZpbmdDb25maWdSZXF1
ZXN0GjMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlcnZpbmdDb25m
aWci/QGC0+STAu8BEkQvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rh
dGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8qfVpUElIvdjFhbHBoYS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3NlcnZpbmdDb25m
aWdzLyp9WlESTy92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVj
dGlvbnMvKi9lbmdpbmVzLyovc2VydmluZ0NvbmZpZ3MvKn3aQQRuYW1lEpkDChJMaXN0U2Vy
dmluZ0NvbmZpZ3MSPy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlz
dFNlcnZpbmdDb25maWdzUmVxdWVzdBpALmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5MaXN0U2VydmluZ0NvbmZpZ3NSZXNwb25zZSL/AYLT5JMC7wESRC92MWFscGhh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3NlcnZpbmdD
b25maWdzWlQSUi92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xs
ZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2VydmluZ0NvbmZpZ3NaURJPL3YxYWxwaGEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qfS9z
ZXJ2aW5nQ29uZmlnc9pBBnBhcmVudBpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMu
Y29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKl
AgooY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIZU2VydmluZ0Nv
bmZpZ1NlcnZpY2VQcm90b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2lu
ZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElT
Q09WRVJZRU5HSU5FqgIkR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIk
R29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6
RGlzY292ZXJ5RW5naW5lOjpWMWFscGhhSrMcCgcSBQ4AkwEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgID
AhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAQwoJCgIDBRIDFwAqCggKAQgSAxkAQQoJCgII
JRIDGQBBCggKAQgSAxoAaQoJCgIICxIDGgBpCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgS
AxwAOgoJCgIICBIDHAA6CggKAQgSAx0AQQoJCgIIARIDHQBBCggKAQgSAx4ALQoJCgIIJBID
HgAtCggKAQgSAx8AQQoJCgIIKRIDHwBBCggKAQgSAyAAQAoJCgIILRIDIABACnUKAgYAEgQk
AFoBGmkgU2VydmljZSBmb3Igb3BlcmF0aW9ucyByZWxhdGVkIHRvCiBbU2VydmluZ0NvbmZp
Z11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlcnZpbmdDb25maWdd
LgoKCgoDBgABEgMkCBwKCgoDBgADEgMlAkYKDAoFBgADmQgSAyUCRgoLCgMGAAMSBCYCJzcK
DQoFBgADmggSBCYCJzcKaQoEBgACABIELAI6AxpbIFVwZGF0ZXMgYSBTZXJ2aW5nQ29uZmln
LgoKIFJldHVybnMgYSBOT1RfRk9VTkQgZXJyb3IgaWYgdGhlIFNlcnZpbmdDb25maWcgZG9l
cyBub3QgZXhpc3QuCgoMCgUGAAIAARIDLAYZCgwKBQYAAgACEgMsGjQKDAoFBgACAAMSAyw/
TAoNCgUGAAIABBIELQQ4BgoRCgkGAAIABLDKvCISBC0EOAYKDAoFBgACAAQSAzkESAoPCggG
AAIABJsIABIDOQRICmUKBAYAAgESBD8CSgMaVyBHZXRzIGEgU2VydmluZ0NvbmZpZy4KCiBS
ZXR1cm5zIGEgTm90Rm91bmQgZXJyb3IgaWYgdGhlIFNlcnZpbmdDb25maWcgZG9lcyBub3Qg
ZXhpc3QuCgoMCgUGAAIBARIDPwYWCgwKBQYAAgECEgM/Fy4KDAoFBgACAQMSAz85RgoNCgUG
AAIBBBIEQARIBgoRCgkGAAIBBLDKvCISBEAESAYKDAoFBgACAQQSA0kEMgoPCggGAAIBBJsI
ABIDSQQyCkIKBAYAAgISBE0CWQMaNCBMaXN0cyBhbGwgU2VydmluZ0NvbmZpZ3MgbGlua2Vk
IHRvIHRoaXMgZGF0YVN0b3JlLgoKDAoFBgACAgESA00GGAoMCgUGAAICAhIDTRkyCgwKBQYA
AgIDEgNODykKDQoFBgACAgQSBE8EVwYKEQoJBgACAgSwyrwiEgRPBFcGCgwKBQYAAgIEEgNY
BDQKDwoIBgACAgSbCAASA1gENAo1CgIEABIEXQBpARopIFJlcXVlc3QgZm9yIFVwZGF0ZVNl
cnZpbmdDb25maWcgbWV0aG9kLgoKCgoDBAABEgNdCCIKNQoEBAACABIDXwJMGiggUmVxdWly
ZWQuIFRoZSBTZXJ2aW5nQ29uZmlnIHRvIHVwZGF0ZS4KCgwKBQQAAgAGEgNfAg8KDAoFBAAC
AAESA18QHgoMCgUEAAIAAxIDXyEiCgwKBQQAAgAIEgNfI0sKDwoIBAACAAicCAASA18kSgqq
AgoEBAACARIDaAIsGpwCIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHByb3ZpZGVk
CiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlNlcnZpbmdDb25maWddIHRvCiB1cGRhdGUuIFRoZSBmb2xsb3dpbmcgYXJlIE5PVCBzdXBw
b3J0ZWQ6CgogKiBbU2VydmluZ0NvbmZpZy5uYW1lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuU2VydmluZ0NvbmZpZy5uYW1lXQoKIElmIG5vdCBzZXQsIGFsbCBz
dXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDAoFBAACAQYSA2gCGwoMCgUEAAIBARID
aBwnCgwKBQQAAgEDEgNoKisKMgoCBAESBGwAdQEaJiBSZXF1ZXN0IGZvciBHZXRTZXJ2aW5n
Q29uZmlnIG1ldGhvZC4KCgoKAwQBARIDbAgfCtABCgQEAQIAEgRvAnQEGsEBIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgU2VydmluZ0NvbmZpZyB0byBnZXQuIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nv
bGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdpbmV9L3NlcnZpbmdDb25maWdz
L3tzZXJ2aW5nX2NvbmZpZ19pZH1gCgoMCgUEAQIABRIDbwIICgwKBQQBAgABEgNvCQ0KDAoF
BAECAAMSA28QEQoNCgUEAQIACBIEbxJ0AwoPCggEAQIACJwIABIDcAQqCg8KBwQBAgAInwgS
BHEEcwUKNQoCBAISBXgAigEBGiggUmVxdWVzdCBmb3IgTGlzdFNlcnZpbmdDb25maWdzIG1l
dGhvZC4KCgoKAwQCARIDeAghCqoBCgQEAgIAEgV7AoABBBqaASBSZXF1aXJlZC4gRnVsbCBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXJlbnQgcmVzb3VyY2UuIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tj
b2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdpbmV9YAoKDAoFBAICAAUSA3sCCAoMCgUEAgIAARID
ewkPCgwKBQQCAgADEgN7EhMKDgoFBAICAAgSBXsUgAEDCg8KCAQCAgAInAgAEgN8BCoKDwoH
BAICAAifCBIEfQR/BQqtAQoEBAICARIEhQECPxqeASBPcHRpb25hbC4gTWF4aW11bSBudW1i
ZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8g
MTAwLiBJZiBhIHZhbHVlIGdyZWF0ZXIgdGhhbiAxMDAgaXMgcHJvdmlkZWQsIGF0IG1vc3Qg
MTAwIHJlc3VsdHMgYXJlCiByZXR1cm5lZC4KCg0KBQQCAgEFEgSFAQIHCg0KBQQCAgEBEgSF
AQgRCg0KBQQCAgEDEgSFARQVCg0KBQQCAgEIEgSFARY+ChAKCAQCAgEInAgAEgSFARc9CooB
CgQEAgICEgSJAQJBGnwgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBh
IHByZXZpb3VzIGBMaXN0U2VydmluZ0NvbmZpZ3NgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8g
cmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQCAgIFEgSJAQIICg0KBQQCAgIB
EgSJAQkTCg0KBQQCAgIDEgSJARYXCg0KBQQCAgIIEgSJARhAChAKCAQCAgIInAgAEgSJARk/
CjcKAgQDEgaNAQCTAQEaKSBSZXNwb25zZSBmb3IgTGlzdFNlcnZpbmdDb25maWdzIG1ldGhv
ZC4KCgsKAwQDARIEjQEIIgo9CgQEAwIAEgSPAQItGi8gQWxsIHRoZSBTZXJ2aW5nQ29uZmln
cyBmb3IgYSBnaXZlbiBkYXRhU3RvcmUuCgoNCgUEAwIABBIEjwECCgoNCgUEAwIABhIEjwEL
GAoNCgUEAwIAARIEjwEZKAoNCgUEAwIAAxIEjwErLApKCgQEAwIBEgSSAQIdGjwgUGFnaW5h
dGlvbiB0b2tlbiwgaWYgbm90IHJldHVybmVkIGluZGljYXRlcyB0aGUgbGFzdCBwYWdlLgoK
DQoFBAMCAQUSBJIBAggKDQoFBAMCAQESBJIBCRgKDQoFBAMCAQMSBJIBGxxiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest ===
    # Fields for UpdateServingConfigRequest
    # Field: serving_config Type: 11 (.google.cloud.discoveryengine.v1alpha.ServingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::GetServingConfigRequest ===
    # Fields for GetServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsRequest ===
    # Fields for ListServingConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsResponse ===
    # Fields for ListServingConfigsResponse
    # Field: serving_configs Type: 11 (.google.cloud.discoveryengine.v1alpha.ServingConfig)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ServingConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ServingConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ServingConfigServiceClient

Client stub representing the remote C<ServingConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub update_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig',
    });
}

sub get_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::GetServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ServingConfigService',
        method         => 'GetServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig',
    });
}

sub list_serving_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ServingConfigService',
        method         => 'ListServingConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ServingConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/serving_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::ServingConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest->new({
        serving_config => $serving_config,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->serving_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/serving_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest

Request for UpdateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig>)

Required. The ServingConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[ServingConfig][google.cloud.discoveryengine.v1alpha.ServingConfig] to
update. The following are NOT supported:

* [ServingConfig.name][google.cloud.discoveryengine.v1alpha.ServingConfig.name]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::GetServingConfigRequest

Request for GetServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to get. Format:
`projects/{project_number}/locations/{location}/collections/{collection}/engines/{engine}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsRequest

Request for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of the parent resource. Format:
`projects/{project_number}/locations/{location}/collections/{collection}/engines/{engine}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 100. If a value greater than 100 is provided, at most 100 results are
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListServingConfigs` call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsResponse

Response for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_configs() >> / C<< $msg->serving_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig>)

All the ServingConfigs for a given dataStore.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
