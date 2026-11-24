package Google::Cloud::Apihub::V1::ProvisioningService;

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
    eval { require Google::Cloud::Apihub::V1::CommonFields };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYXBpaHViL3YxL3Byb3Zpc2lvbmluZ19zZXJ2aWNlLnByb3RvEhZn
b29nbGUuY2xvdWQuYXBpaHViLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdn
b29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoqZ29vZ2xlL2Nsb3VkL2FwaWh1Yi92MS9j
b21tb25fZmllbGRzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvIusBChtDcmVhdGVBcGlIdWJJbnN0YW5j
ZVJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlz
LmNvbS9Mb2NhdGlvblIGcGFyZW50EjIKE2FwaV9odWJfaW5zdGFuY2VfaWQYAiABKAlCA+BB
AVIQYXBpSHViSW5zdGFuY2VJZBJVChBhcGlfaHViX2luc3RhbmNlGAMgASgLMiYuZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MS5BcGlIdWJJbnN0YW5jZUID4EECUg5hcGlIdWJJbnN0YW5jZSJf
ChtEZWxldGVBcGlIdWJJbnN0YW5jZVJlcXVlc3QSQAoEbmFtZRgBIAEoCUIs4EEC+kEmCiRh
cGlodWIuZ29vZ2xlYXBpcy5jb20vQXBpSHViSW5zdGFuY2VSBG5hbWUiXAoYR2V0QXBpSHVi
SW5zdGFuY2VSZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpBJgokYXBpaHViLmdvb2dsZWFw
aXMuY29tL0FwaUh1Ykluc3RhbmNlUgRuYW1lImMKG0xvb2t1cEFwaUh1Ykluc3RhbmNlUmVx
dWVzdBJECgZwYXJlbnQYASABKAlCLOBBAvpBJhIkYXBpaHViLmdvb2dsZWFwaXMuY29tL0Fw
aUh1Ykluc3RhbmNlUgZwYXJlbnQicAocTG9va3VwQXBpSHViSW5zdGFuY2VSZXNwb25zZRJQ
ChBhcGlfaHViX2luc3RhbmNlGAEgASgLMiYuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5BcGlI
dWJJbnN0YW5jZVIOYXBpSHViSW5zdGFuY2UyzQcKDFByb3Zpc2lvbmluZxKOAgoUQ3JlYXRl
QXBpSHViSW5zdGFuY2USMy5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkNyZWF0ZUFwaUh1Yklu
c3RhbmNlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ioQGC0+STAkci
My92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2FwaUh1Ykluc3RhbmNlczoQ
YXBpX2h1Yl9pbnN0YW5jZdpBK3BhcmVudCxhcGlfaHViX2luc3RhbmNlLGFwaV9odWJfaW5z
dGFuY2VfaWTKQSMKDkFwaUh1Ykluc3RhbmNlEhFPcGVyYXRpb25NZXRhZGF0YRLbAQoURGVs
ZXRlQXBpSHViSW5zdGFuY2USMy5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkRlbGV0ZUFwaUh1
Ykluc3RhbmNlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ib4LT5JMC
NSozL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYXBpSHViSW5zdGFuY2VzLyp9
2kEEbmFtZcpBKgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRKx
AQoRR2V0QXBpSHViSW5zdGFuY2USMC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkdldEFwaUh1
Ykluc3RhbmNlUmVxdWVzdBomLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuQXBpSHViSW5zdGFu
Y2UiQoLT5JMCNRIzL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYXBpSHViSW5z
dGFuY2VzLyp92kEEbmFtZRLOAQoUTG9va3VwQXBpSHViSW5zdGFuY2USMy5nb29nbGUuY2xv
dWQuYXBpaHViLnYxLkxvb2t1cEFwaUh1Ykluc3RhbmNlUmVxdWVzdBo0Lmdvb2dsZS5jbG91
ZC5hcGlodWIudjEuTG9va3VwQXBpSHViSW5zdGFuY2VSZXNwb25zZSJLgtPkkwI8EjovdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9hcGlIdWJJbnN0YW5jZXM6bG9va3Vw
2kEGcGFyZW50GknKQRVhcGlodWIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQroBChpjb20uZ29vZ2xlLmNsb3VkLmFw
aWh1Yi52MUIYUHJvdmlzaW9uaW5nU2VydmljZVByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20v
Z28vYXBpaHViL2FwaXYxL2FwaWh1YnBiO2FwaWh1YnBiqgIWR29vZ2xlLkNsb3VkLkFwaUh1
Yi5WMcoCFkdvb2dsZVxDbG91ZFxBcGlIdWJcVjHqAhlHb29nbGU6OkNsb3VkOjpBcGlIdWI6
OlYxSp8gCgcSBQ4ApAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAfCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoC
AwQSAxYANAoJCgIDBRIDFwAtCgkKAgMGEgMYACUKCAoBCBIDGgAzCgkKAgglEgMaADMKCAoB
CBIDGwBJCgkKAggLEgMbAEkKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA5CgkKAggI
EgMdADkKCAoBCBIDHgAzCgkKAggBEgMeADMKCAoBCBIDHwAzCgkKAggpEgMfADMKCAoBCBID
IAAyCgkKAggtEgMgADIKWwoCBgASBCMAVQEaTyBUaGlzIHNlcnZpY2UgaXMgdXNlZCBmb3Ig
bWFuYWdpbmcgdGhlIGRhdGEgcGxhbmUgcHJvdmlzaW9uaW5nIG9mIHRoZSBBUEkgaHViLgoK
CgoDBgABEgMjCBQKCgoDBgADEgMkAj0KDAoFBgADmQgSAyQCPQoLCgMGAAMSBCUCJjcKDQoF
BgADmggSBCUCJjcKPgoEBgACABIEKQI1AxowIFByb3Zpc2lvbnMgaW5zdGFuY2UgcmVzb3Vy
Y2VzIGZvciB0aGUgQVBJIEh1Yi4KCgwKBQYAAgABEgMpBhoKDAoFBgACAAISAykbNgoMCgUG
AAIAAxIDKg8rCg0KBQYAAgAEEgQrBC4GChEKCQYAAgAEsMq8IhIEKwQuBgoNCgUGAAIABBIE
LwQwNgoQCggGAAIABJsIABIELwQwNgoNCgUGAAIABBIEMQQ0BgoPCgcGAAIABJkIEgQxBDQG
Ci0KBAYAAgESBDgCQgMaHyBEZWxldGVzIHRoZSBBUEkgaHViIGluc3RhbmNlLgoKDAoFBgAC
AQESAzgGGgoMCgUGAAIBAhIDOBs2CgwKBQYAAgEDEgM5DysKDQoFBgACAQQSBDoEPAYKEQoJ
BgACAQSwyrwiEgQ6BDwGCgwKBQYAAgEEEgM9BDIKDwoIBgACAQSbCAASAz0EMgoNCgUGAAIB
BBIEPgRBBgoPCgcGAAIBBJkIEgQ+BEEGCjoKBAYAAgISBEUCSgMaLCBHZXRzIGRldGFpbHMg
b2YgYSBzaW5nbGUgQVBJIEh1YiBpbnN0YW5jZS4KCgwKBQYAAgIBEgNFBhcKDAoFBgACAgIS
A0UYMAoMCgUGAAICAxIDRTtJCg0KBQYAAgIEEgRGBEgGChEKCQYAAgIEsMq8IhIERgRIBgoM
CgUGAAICBBIDSQQyCg8KCAYAAgIEmwgAEgNJBDIKnQEKBAYAAgMSBE4CVAMajgEgTG9va3Mg
dXAgYW4gQXBpIEh1YiBpbnN0YW5jZSBpbiBhIGdpdmVuIEdDUCBwcm9qZWN0LiBUaGVyZSB3
aWxsIGFsd2F5cyBiZQogb25seSBvbmUgQXBpIEh1YiBpbnN0YW5jZSBmb3IgYSBHQ1AgcHJv
amVjdCBhY3Jvc3MgYWxsIGxvY2F0aW9ucy4KCgwKBQYAAgMBEgNOBhoKDAoFBgACAwISA04b
NgoMCgUGAAIDAxIDTw8rCg0KBQYAAgMEEgRQBFIGChEKCQYAAgMEsMq8IhIEUARSBgoMCgUG
AAIDBBIDUwQ0Cg8KCAYAAgMEmwgAEgNTBDQKdgoCBAASBFoAbgEaaiBUaGUKIFtDcmVhdGVB
cGlIdWJJbnN0YW5jZV1bZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5Qcm92aXNpb25pbmcuQ3Jl
YXRlQXBpSHViSW5zdGFuY2VdCiBtZXRob2QncyByZXF1ZXN0LgoKCgoDBAABEgNaCCMKgwEK
BAQAAgASBF0CYgQadSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBmb3IgdGhlIEFw
aSBIdWIgaW5zdGFuY2UgcmVzb3VyY2UuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn1gCgoMCgUEAAIABRIDXQIICgwKBQQAAgABEgNdCQ8KDAoF
BAACAAMSA10SEwoNCgUEAAIACBIEXRRiAwoPCggEAAIACJwIABIDXgQqCg8KBwQAAgAInwgS
BF8EYQUKlgIKBAQAAgESA2oCShqIAiBPcHRpb25hbC4gSWRlbnRpZmllciB0byBhc3NpZ24g
dG8gdGhlIEFwaSBIdWIgaW5zdGFuY2UuIE11c3QgYmUgdW5pcXVlCiB3aXRoaW4gc2NvcGUg
b2YgdGhlIHBhcmVudCByZXNvdXJjZS4gSWYgdGhlIGZpZWxkIGlzIG5vdCBwcm92aWRlZCwg
c3lzdGVtCiBnZW5lcmF0ZWQgaWQgd2lsbCBiZSB1c2VkLgoKIFRoaXMgdmFsdWUgc2hvdWxk
IGJlIDQtNDAgY2hhcmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMKIGFyZSBgL1thLXpd
W0EtWl1bMC05XS1fL2AuCgoMCgUEAAIBBRIDagIICgwKBQQAAgEBEgNqCRwKDAoFBAACAQMS
A2ofIAoMCgUEAAIBCBIDaiFJCg8KCAQAAgEInAgAEgNqIkgKLQoEBAACAhIDbQJPGiAgUmVx
dWlyZWQuIFRoZSBBcGlIdWIgaW5zdGFuY2UuCgoMCgUEAAICBhIDbQIQCgwKBQQAAgIBEgNt
ESEKDAoFBAACAgMSA20kJQoMCgUEAAICCBIDbSZOCg8KCAQAAgIInAgAEgNtJ00KdgoCBAES
BHMAfQEaaiBUaGUKIFtEZWxldGVBcGlIdWJJbnN0YW5jZV1bZ29vZ2xlLmNsb3VkLmFwaWh1
Yi52MS5Qcm92aXNpb25pbmcuRGVsZXRlQXBpSHViSW5zdGFuY2VdCiBtZXRob2QncyByZXF1
ZXN0LgoKCgoDBAEBEgNzCCMKnAEKBAQBAgASBHcCfAQajQEgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBBcGkgSHViIGluc3RhbmNlIHRvIGRlbGV0ZS4KIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBpSHViSW5zdGFuY2VzL3thcGlI
dWJJbnN0YW5jZX1gLgoKDAoFBAECAAUSA3cCCAoMCgUEAQIAARIDdwkNCgwKBQQBAgADEgN3
EBEKDQoFBAECAAgSBHcSfAMKDwoIBAECAAicCAASA3gEKgoPCgcEAQIACJ8IEgR5BHsFCnIK
AgQCEgaCAQCMAQEaZCBUaGUKIFtHZXRBcGlIdWJJbnN0YW5jZV1bZ29vZ2xlLmNsb3VkLmFw
aWh1Yi52MS5Qcm92aXNpb25pbmcuR2V0QXBpSHViSW5zdGFuY2VdCiBtZXRob2QncyByZXF1
ZXN0LgoKCwoDBAIBEgSCAQggCqABCgQEAgIAEgaGAQKLAQQajwEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBBcGkgSHViIGluc3RhbmNlIHRvIHJldHJpZXZlLgogRm9ybWF0OgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcGlIdWJJbnN0YW5jZXMv
e2FwaUh1Ykluc3RhbmNlfWAuCgoNCgUEAgIABRIEhgECCAoNCgUEAgIAARIEhgEJDQoNCgUE
AgIAAxIEhgEQEQoPCgUEAgIACBIGhgESiwEDChAKCAQCAgAInAgAEgSHAQQqChEKBwQCAgAI
nwgSBogBBIoBBQp4CgIEAxIGkQEAnAEBGmogVGhlCiBbTG9va3VwQXBpSHViSW5zdGFuY2Vd
W2dvb2dsZS5jbG91ZC5hcGlodWIudjEuUHJvdmlzaW9uaW5nLkxvb2t1cEFwaUh1Ykluc3Rh
bmNlXQogbWV0aG9kJ3MgcmVxdWVzdC4KCgsKAwQDARIEkQEIIwrfAQoEBAMCABIGlgECmwEE
Gs4BIFJlcXVpcmVkLiBUaGVyZSB3aWxsIGFsd2F5cyBiZSBvbmx5IG9uZSBBcGkgSHViIGlu
c3RhbmNlIGZvciBhIEdDUCBwcm9qZWN0CiBhY3Jvc3MgYWxsIGxvY2F0aW9ucy4KIFRoZSBw
YXJlbnQgcmVzb3VyY2UgZm9yIHRoZSBBcGkgSHViIGluc3RhbmNlIHJlc291cmNlLgogRm9y
bWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAMC
AAUSBJYBAggKDQoFBAMCAAESBJYBCQ8KDQoFBAMCAAMSBJYBEhMKDwoFBAMCAAgSBpYBFJsB
AwoQCggEAwIACJwIABIElwEEKgoRCgcEAwIACJ8IEgaYAQSaAQUKegoCBAQSBqEBAKQBARps
IFRoZQogW0xvb2t1cEFwaUh1Ykluc3RhbmNlXVtnb29nbGUuY2xvdWQuYXBpaHViLnYxLlBy
b3Zpc2lvbmluZy5Mb29rdXBBcGlIdWJJbnN0YW5jZV0KIG1ldGhvZCdzIHJlc3BvbnNlLmAK
CgsKAwQEARIEoQEIJApNCgQEBAIAEgSjAQImGj8gQVBJIEh1YiBpbnN0YW5jZSBmb3IgYSBw
cm9qZWN0IGlmIGl0IGV4aXN0cywgZW1wdHkgb3RoZXJ3aXNlLgoKDQoFBAQCAAYSBKMBAhAK
DQoFBAQCAAESBKMBESEKDQoFBAQCAAMSBKMBJCViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest ===
    # Fields for CreateApiHubInstanceRequest
    # Field: parent Type: 9 ()
    # Field: api_hub_instance_id Type: 9 ()
    # Field: api_hub_instance Type: 11 (.google.cloud.apihub.v1.ApiHubInstance)

# === Message: Google::Cloud::Apihub::V1::ProvisioningService::DeleteApiHubInstanceRequest ===
    # Fields for DeleteApiHubInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::ProvisioningService::GetApiHubInstanceRequest ===
    # Fields for GetApiHubInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceRequest ===
    # Fields for LookupApiHubInstanceRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceResponse ===
    # Fields for LookupApiHubInstanceResponse
    # Field: api_hub_instance Type: 11 (.google.cloud.apihub.v1.ApiHubInstance)

# === Service Client: Google::Cloud::Apihub::V1::ProvisioningService::ProvisioningClient ===
package Google::Cloud::Apihub::V1::ProvisioningService::ProvisioningClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::ProvisioningService::ProvisioningClient

Client stub representing the remote C<Provisioning> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apihub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apihub.googleapis.com:443' );

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

sub create_api_hub_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.Provisioning',
        method         => 'CreateApiHubInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_api_hub_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::ProvisioningService::DeleteApiHubInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.Provisioning',
        method         => 'DeleteApiHubInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_api_hub_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::ProvisioningService::GetApiHubInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.Provisioning',
        method         => 'GetApiHubInstance',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance',
    });
}

sub lookup_api_hub_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.Provisioning',
        method         => 'LookupApiHubInstance',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::ProvisioningService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/provisioning_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::ProvisioningService;

    my $msg = Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest->new({
        parent => $parent,
        api_hub_instance_id => $api_hub_instance_id,
        api_hub_instance => $api_hub_instance,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/provisioning_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest

The
[CreateApiHubInstance][google.cloud.apihub.v1.Provisioning.CreateApiHubInstance]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource for the Api Hub instance resource.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->api_hub_instance_id() >> / C<< $msg->api_hub_instance_id($value) >>

Type: C<String>

Optional. Identifier to assign to the Api Hub instance. Must be unique
within scope of the parent resource. If the field is not provided, system
generated id will be used.

This value should be 4-40 characters, and valid characters
are `/[a-z][A-Z][0-9]-_/`.

=item * C<< $msg->api_hub_instance() >> / C<< $msg->api_hub_instance($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance>)

Required. The ApiHub instance.

=back

=head2 Google::Cloud::Apihub::V1::ProvisioningService::DeleteApiHubInstanceRequest

The
[DeleteApiHubInstance][google.cloud.apihub.v1.Provisioning.DeleteApiHubInstance]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Api Hub instance to delete.
Format:
`projects/{project}/locations/{location}/apiHubInstances/{apiHubInstance}`.

=back

=head2 Google::Cloud::Apihub::V1::ProvisioningService::GetApiHubInstanceRequest

The
[GetApiHubInstance][google.cloud.apihub.v1.Provisioning.GetApiHubInstance]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Api Hub instance to retrieve.
Format:
`projects/{project}/locations/{location}/apiHubInstances/{apiHubInstance}`.

=back

=head2 Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceRequest

The
[LookupApiHubInstance][google.cloud.apihub.v1.Provisioning.LookupApiHubInstance]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. There will always be only one Api Hub instance for a GCP project
across all locations.
The parent resource for the Api Hub instance resource.
Format: `projects/{project}/locations/{location}`

=back

=head2 Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceResponse

The
[LookupApiHubInstance][google.cloud.apihub.v1.Provisioning.LookupApiHubInstance]
method's response.`

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_hub_instance() >> / C<< $msg->api_hub_instance($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance>)

API Hub instance for a project if it exists, empty otherwise.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::ProvisioningService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
