package Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::ImportConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZXN0aW1hdGVfYmlsbGlu
Z19zZXJ2aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEa
HGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3Rv
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvaW1wb3J0X2Nv
bmZpZy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8igwcKF0VzdGltYXRlRGF0YVNpemVSZXF1ZXN0
EoEBChN3ZWJzaXRlX2RhdGFfc291cmNlGAIgASgLMk8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLkVzdGltYXRlRGF0YVNpemVSZXF1ZXN0LldlYnNpdGVEYXRhU291
cmNlSABSEXdlYnNpdGVEYXRhU291cmNlEngKEGZpbGVfZGF0YV9zb3VyY2UYAyABKAsyTC5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXN0aW1hdGVEYXRhU2l6ZVJl
cXVlc3QuRmlsZURhdGFTb3VyY2VIAFIOZmlsZURhdGFTb3VyY2USSwoIbG9jYXRpb24YASAB
KAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUghs
b2NhdGlvbhq9AgoRV2Vic2l0ZURhdGFTb3VyY2USngEKFmVzdGltYXRvcl91cmlfcGF0dGVy
bnMYASADKAsyYy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXN0aW1h
dGVEYXRhU2l6ZVJlcXVlc3QuV2Vic2l0ZURhdGFTb3VyY2UuRXN0aW1hdG9yVXJpUGF0dGVy
bkID4EECUhRlc3RpbWF0b3JVcmlQYXR0ZXJucxqGAQoTRXN0aW1hdG9yVXJpUGF0dGVybhIw
ChRwcm92aWRlZF91cmlfcGF0dGVybhgBIAEoCVIScHJvdmlkZWRVcmlQYXR0ZXJuEh8KC2V4
YWN0X21hdGNoGAIgASgIUgpleGFjdE1hdGNoEhwKCWV4Y2x1c2l2ZRgDIAEoCFIJZXhjbHVz
aXZlGs0BCg5GaWxlRGF0YVNvdXJjZRJQCgpnY3Nfc291cmNlGAEgASgLMi8uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdjc1NvdXJjZUgAUglnY3NTb3VyY2USXwoP
YmlncXVlcnlfc291cmNlGAIgASgLMjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkJpZ1F1ZXJ5U291cmNlSABSDmJpZ3F1ZXJ5U291cmNlQggKBnNvdXJjZUINCgtk
YXRhX3NvdXJjZSJpChhFc3RpbWF0ZURhdGFTaXplUmVzcG9uc2USJgoPZGF0YV9zaXplX2J5
dGVzGAEgASgDUg1kYXRhU2l6ZUJ5dGVzEiUKDmRvY3VtZW50X2NvdW50GAIgASgDUg1kb2N1
bWVudENvdW50IlcKGEVzdGltYXRlRGF0YVNpemVNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgB
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUyqQMKFkVzdGlt
YXRlQmlsbGluZ1NlcnZpY2USugIKEEVzdGltYXRlRGF0YVNpemUSPS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXN0aW1hdGVEYXRhU2l6ZVJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIscBgtPkkwJAIjsvdjFhbHBoYS97bG9jYXRpb249
cHJvamVjdHMvKi9sb2NhdGlvbnMvKn06ZXN0aW1hdGVEYXRhU2l6ZToBKspBfgo9Z29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkVzdGltYXRlRGF0YVNpemVSZXNwb25z
ZRI9Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkVzdGltYXRlRGF0YVNp
emVNZXRhZGF0YRpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKnAgooY29tLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIbRXN0aW1hdGVCaWxsaW5nU2Vydmlj
ZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxw
aGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJ
TkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xv
dWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlF
bmdpbmU6OlYxYWxwaGFKwB0KBxIFDgCBAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgBCCgkKAgMFEgMXAC0KCQoCAwYSAxgAKQoICgEIEgMaAEEKCQoC
CCUSAxoAQQoICgEIEgMbAGkKCQoCCAsSAxsAaQoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEI
EgMdADwKCQoCCAgSAx0APAoICgEIEgMeAEEKCQoCCAESAx4AQQoICgEIEgMfAC0KCQoCCCQS
Ax8ALQoICgEIEgMgAEEKCQoCCCkSAyAAQQoICgEIEgMhAEAKCQoCCC0SAyEAQApBCgIGABIE
JAA1ARo1IFNlcnZpY2UgZm9yIG1hbmFnaW5nIGJpbGxpbmcgZXN0aW1hdGlvbnMgcmVzb3Vy
Y2VzLgoKCgoDBgABEgMkCB4KCgoDBgADEgMlAkYKDAoFBgADmQgSAyUCRgoLCgMGAAMSBCYC
JzcKDQoFBgADmggSBCYCJzcKQQoEBgACABIEKgI0AxozIEVzdGltYXRlcyB0aGUgZGF0YSBz
aXplIHRvIGJlIHVzZWQgYnkgYSBjdXN0b21lci4KCgwKBQYAAgABEgMqBhYKDAoFBgACAAIS
AyoXLgoMCgUGAAIAAxIDKw8rCg0KBQYAAgAEEgQsBC8GChEKCQYAAgAEsMq8IhIELAQvBgoN
CgUGAAIABBIEMAQzBgoPCgcGAAIABJkIEgQwBDMGCqMBCgIEABIEOgBvARqWASBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbRXN0aW1hdGVCaWxsaW5nU2VydmljZS5Fc3RpbWF0ZURhdGFTaXpl
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXN0aW1hdGVCaWxsaW5n
U2VydmljZS5Fc3RpbWF0ZURhdGFTaXplXQogbWV0aG9kCgoKCgMEAAESAzoIHwpsCgQEAAMA
EgQ9AlADGl4gRGF0YSBzb3VyY2UgaXMgYSBzZXQgb2Ygd2Vic2l0ZSBwYXR0ZXJucyB0aGF0
IHdlIGNyYXdsIHRvIGdldAogdGhlIHRvdGFsIG51bWJlciBvZiB3ZWJzaXRlcy4KCgwKBQQA
AwABEgM9ChsKNAoGBAADAAMAEgQ/BEoFGiQgVVJJIHBhdHRlcm5zIHRoYXQgd2UgdXNlIHRv
IGNyYXdsLgoKDgoHBAADAAMAARIDPwwfCksKCAQAAwADAAIAEgNBBiYaOiBVc2VyIHByb3Zp
ZGVkIFVSSSBwYXR0ZXJuLiBGb3IgZXhhbXBsZSwgYGZvby5jb20vYmFyLypgLgoKEAoJBAAD
AAMAAgAFEgNBBgwKEAoJBAADAAMAAgABEgNBDSEKEAoJBAADAAMAAgADEgNBJCUKVAoIBAAD
AAMAAgESA0QGGxpDIFdoZXRoZXIgd2UgaW5mZXIgdGhlIGdlbmVyYXRlZCBVUkkgb3IgdXNl
IHRoZSBleGFjdCBwcm92aWRlZCBvbmUuCgoQCgkEAAMAAwACAQUSA0QGCgoQCgkEAAMAAwAC
AQESA0QLFgoQCgkEAAMAAwACAQMSA0QZGgq9AQoIBAADAAMAAgISA0kGGRqrASBXaGV0aGVy
IHRoZSBwYXR0ZXJuIGlzIGV4Y2x1c2l2ZSBvciBub3QuIElmIHNldCB0byB0cnVlLCB0aGUg
cGF0dGVybiBpcwogY29uc2lkZXJlZCBleGNsdXNpdmUuIElmIHVuc2V0IG9yIHNldCB0byBm
YWxzZSwgdGhlIHBhdHRlcm4gaXMKIGNvbnNpZGVyZWQgaW5jbHVzaXZlIGJ5IGRlZmF1bHQu
CgoQCgkEAAMAAwACAgUSA0kGCgoQCgkEAAMAAwACAgESA0kLFAoQCgkEAAMAAwACAgMSA0kX
GAqaAQoGBAADAAIAEgROBE8xGokBIFJlcXVpcmVkLiBUaGUgVVJJIHBhdHRlcm5zIHRvIGVz
dGltYXRlIHRoZSBkYXRhIHNpemVzLiBBdCBtb3N0IDEwCiBwYXR0ZXJucyBhcmUgYWxsb3dl
ZCwgb3RoZXJ3aXNlIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgdGhyb3duLgoKDgoH
BAADAAIABBIDTgQMCg4KBwQAAwACAAYSA04NIAoOCgcEAAMAAgABEgNOITcKDgoHBAADAAIA
AxIDTjo7Cg4KBwQAAwACAAgSA08IMAoRCgoEAAMAAgAInAgAEgNPCS8KTwoEBAADARIEUwJc
AxpBIERhdGEgc291cmNlIGNvbnRhaW5zIGZpbGVzIGVpdGhlciBpbiBDbG91ZCBTdG9yYWdl
IG9yIEJpZ1F1ZXJ5LgoKDAoFBAADAQESA1MKGAo9CgYEAAMBCAASBFUEWwUaLSBXaGljaCBz
b3VyY2UgY29udGFpbnMgdGhlIGZpbGVzIHRvIGJlIHVzZWQuCgoOCgcEAAMBCAABEgNVChAK
PgoGBAADAQIAEgNXBh8aLyBDbG91ZCBTdG9yYWdlIGxvY2F0aW9uIGZvciB0aGUgaW5wdXQg
Y29udGVudC4KCg4KBwQAAwECAAYSA1cGDwoOCgcEAAMBAgABEgNXEBoKDgoHBAADAQIAAxID
Vx0eCicKBgQAAwECARIDWgYpGhggQmlnUXVlcnkgaW5wdXQgc291cmNlLgoKDgoHBAADAQIB
BhIDWgYUCg4KBwQAAwECAQESA1oVJAoOCgcEAAMBAgEDEgNaJygKQQoEBAAIABIEXwJlAxoz
IERhdGEgc291cmNlIGZvciB3aGljaCB3ZSBhcmUgZXN0aW1hdGluZyBpdHMgc2l6ZS4KCgwK
BQQACAABEgNfCBMKHAoEBAACABIDYQQuGg8gV2Vic2l0ZSBkYXRhLgoKDAoFBAACAAYSA2EE
FQoMCgUEAAIAARIDYRYpCgwKBQQAAgADEgNhLC0KLwoEBAACARIDZAQoGiIgU3RydWN0dXJl
ZCBvciB1bnN0cnVjdHVyZWQgZGF0YS4KCgwKBQQAAgEGEgNkBBIKDAoFBAACAQESA2QTIwoM
CgUEAAIBAxIDZCYnCnEKBAQAAgISBGkCbgQaYyBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBu
YW1lIG9mIHRoZSBsb2NhdGlvbiwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufWAuCgoMCgUEAAICBRIDaQIICgwKBQQAAgIBEgNpCREKDAoFBAAC
AgMSA2kUFQoNCgUEAAICCBIEaRZuAwoPCggEAAICCJwIABIDagQqCg8KBwQAAgIInwgSBGsE
bQUK2wEKAgQBEgR0AHoBGs4BIFJlc3BvbnNlIG9mIHRoZSBFc3RpbWF0ZURhdGFTaXplIHJl
cXVlc3QuIElmIHRoZSBsb25nIHJ1bm5pbmcKIG9wZXJhdGlvbiB3YXMgc3VjY2Vzc2Z1bCwg
dGhlbiB0aGlzIG1lc3NhZ2UgaXMgcmV0dXJuZWQgYnkgdGhlCiBnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVsZCBpZiB0aGUgb3BlcmF0aW9uIHdhcyBzdWNj
ZXNzZnVsLgoKCgoDBAEBEgN0CCAKKwoEBAECABIDdgIcGh4gRGF0YSBzaXplIGluIHRlcm1z
IG9mIGJ5dGVzLgoKDAoFBAECAAUSA3YCBwoMCgUEAQIAARIDdggXCgwKBQQBAgADEgN2GhsK
KQoEBAECARIDeQIbGhwgVG90YWwgbnVtYmVyIG9mIGRvY3VtZW50cy4KCgwKBQQBAgEFEgN5
AgcKDAoFBAECAQESA3kIFgoMCgUEAQIBAxIDeRkaCpkBCgIEAhIFfgCBAQEaiwEgTWV0YWRh
dGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlIEVzdGltYXRlRGF0YVNpemUgb3Bl
cmF0aW9uLiBUaGlzIGlzCiByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbi5tZXRhZGF0YSBmaWVsZC4KCgoKAwQCARIDfgggCiYKBAQCAgASBIABAiwaGCBP
cGVyYXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEAgIABhIEgAECGwoNCgUEAgIAARIEgAEcJwoN
CgUEAgIAAxIEgAEqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest ===
    # Fields for EstimateDataSizeRequest
    # Field: website_data_source Type: 11 (.google.cloud.discoveryengine.v1alpha.EstimateDataSizeRequest.WebsiteDataSource)
    # Field: file_data_source Type: 11 (.google.cloud.discoveryengine.v1alpha.EstimateDataSizeRequest.FileDataSource)
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeResponse ===
    # Fields for EstimateDataSizeResponse
    # Field: data_size_bytes Type: 3 ()
    # Field: document_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeMetadata ===
    # Fields for EstimateDataSizeMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateBillingServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateBillingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateBillingServiceClient

Client stub representing the remote C<EstimateBillingService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub estimate_data_size {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EstimateBillingService',
        method         => 'EstimateDataSize',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/estimate_billing_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest->new({
        website_data_source => $website_data_source,
        file_data_source => $file_data_source,
        location => $location,
    });

    # Read or update a field
    my $val = $msg->website_data_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/estimate_billing_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest

Request message for
[EstimateBillingService.EstimateDataSize][google.cloud.discoveryengine.v1alpha.EstimateBillingService.EstimateDataSize]
method

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->website_data_source() >> / C<< $msg->website_data_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource>)

Website data.

=item * C<< $msg->file_data_source() >> / C<< $msg->file_data_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::FileDataSource>)

Structured or unstructured data.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. Full resource name of the location, such as
`projects/{project}/locations/{location}`.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeResponse

Response of the EstimateDataSize request. If the long running
operation was successful, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_size_bytes() >> / C<< $msg->data_size_bytes($value) >>

Type: C<Int64>

Data size in terms of bytes.

=item * C<< $msg->document_count() >> / C<< $msg->document_count($value) >>

Type: C<Int64>

Total number of documents.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeMetadata

Metadata related to the progress of the EstimateDataSize operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
