package Google::Cloud::Discoveryengine::V1alpha::ChunkService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Chunk };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY2h1bmtfc2VydmljZS5w
cm90bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxowZ29v
Z2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL2NodW5rLnByb3RvIlMKD0dldENo
dW5rUmVxdWVzdBJACgRuYW1lGAEgASgJQizgQQL6QSYKJGRpc2NvdmVyeWVuZ2luZS5nb29n
bGVhcGlzLmNvbS9DaHVua1IEbmFtZSKYAQoRTGlzdENodW5rc1JlcXVlc3QSRwoGcGFyZW50
GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVu
dFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuIoEBChJMaXN0Q2h1bmtzUmVzcG9uc2USQwoGY2h1bmtzGAEgAygL
MisuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNodW5rUgZjaHVua3MS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMu0FCgxDaHVua1NlcnZp
Y2USuQIKCEdldENodW5rEjUuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkdldENodW5rUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5DaHVuayLIAYLT5JMCugESUy92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyovZG9jdW1lbnRzLyovY2h1bmtzLyp9WmMSYS92
MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyovYnJhbmNoZXMvKi9kb2N1bWVudHMvKi9jaHVua3MvKn3aQQRuYW1lEswCCgpM
aXN0Q2h1bmtzEjcuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RD
aHVua3NSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxp
c3RDaHVua3NSZXNwb25zZSLKAYLT5JMCugESUy92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMvKi9kb2N1bWVudHMvKn0vY2h1
bmtzWmMSYS92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qfS9jaHVua3PaQQZw
YXJlbnQaUspBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CnQIKKGNvbS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCEUNodW5rU2VydmljZVByb3RvUAFaUmNsb3Vk
Lmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5n
aW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xv
dWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5n
aW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFK
jSIKBxIFDgCIAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
AC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBID
FgA6CggKAQgSAxgAQQoJCgIIJRIDGABBCggKAQgSAxkAaQoJCgIICxIDGQBpCggKAQgSAxoA
IgoJCgIIChIDGgAiCggKAQgSAxsAMgoJCgIICBIDGwAyCggKAQgSAxwAQQoJCgIIARIDHABB
CggKAQgSAx0ALQoJCgIIJBIDHQAtCggKAQgSAx4AQQoJCgIIKRIDHgBBCggKAQgSAx8AQAoJ
CgIILRIDHwBACpYBCgIGABIEJAA+ARqJASBTZXJ2aWNlIGZvciBkaXNwbGF5aW5nIHByb2Nl
c3NlZAogW0NodW5rXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1
bmtdIGluZm9ybWF0aW9uIG9mIHRoZQogY3VzdG9tZXIncyB1bnN0cnVjdHVyZWQgZGF0YS4K
CgoKAwYAARIDJAgUCgoKAwYAAxIDJQJGCgwKBQYAA5kIEgMlAkYKCwoDBgADEgQmAic3Cg0K
BQYAA5oIEgQmAic3ClEKBAYAAgASBCoCMgMaQyBHZXRzIGEgW0RvY3VtZW50XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRG9jdW1lbnRdLgoKDAoFBgACAAESAyoG
DgoMCgUGAAIAAhIDKg8eCgwKBQYAAgADEgMqKS4KDQoFBgACAAQSBCsEMAYKEQoJBgACAASw
yrwiEgQrBDAGCgwKBQYAAgAEEgMxBDIKDwoIBgACAASbCAASAzEEMgpUCgQGAAIBEgQ1Aj0D
GkYgR2V0cyBhIGxpc3Qgb2YgW0NodW5rXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuQ2h1bmtdcy4KCgwKBQYAAgEBEgM1BhAKDAoFBgACAQISAzURIgoMCgUGAAIB
AxIDNS0/Cg0KBQYAAgEEEgQ2BDsGChEKCQYAAgEEsMq8IhIENgQ7BgoMCgUGAAIBBBIDPAQ0
Cg8KCAYAAgEEmwgAEgM8BDQKfwoCBAASBEMAVAEacyBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
Q2h1bmtTZXJ2aWNlLkdldENodW5rXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuQ2h1bmtTZXJ2aWNlLkdldENodW5rXQogbWV0aG9kLgoKCgoDBAABEgNDCBcKuQQK
BAQAAgASBE4CUwQaqgQgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0NodW5r
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1bmtdLCBzdWNoIGFz
CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25z
L3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9icmFuY2hlcy97YnJhbmNo
fS9kb2N1bWVudHMve2RvY3VtZW50fS9jaHVua3Mve2NodW5rfWAuCgogSWYgdGhlIGNhbGxl
ciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gYWNjZXNzIHRoZQogW0NodW5rXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1bmtdLCByZWdhcmRsZXNzIG9m
IHdoZXRoZXIKIG9yIG5vdCBpdCBleGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJv
ciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgcmVxdWVzdGVkIFtDaHVua11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNodW5rXSBkb2VzCiBub3QgZXhpc3QsIGEgYE5P
VF9GT1VORGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUEAAIABRIDTgIICgwKBQQAAgABEgNO
CQ0KDAoFBAACAAMSA04QEQoNCgUEAAIACBIEThJTAwoPCggEAAIACJwIABIDTwQqCg8KBwQA
AgAInwgSBFAEUgUKgwEKAgQBEgRZAHoBGncgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0NodW5r
U2VydmljZS5MaXN0Q2h1bmtzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuQ2h1bmtTZXJ2aWNlLkxpc3RDaHVua3NdCiBtZXRob2QuCgoKCgMEAQESA1kIGQqjAwoE
BAECABIEYQJmBBqUAyBSZXF1aXJlZC4gVGhlIHBhcmVudCBkb2N1bWVudCByZXNvdXJjZSBu
YW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9icmFu
Y2hlcy97YnJhbmNofS9kb2N1bWVudHMve2RvY3VtZW50fWAuCgogSWYgdGhlIGNhbGxlciBk
b2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gbGlzdAogW0NodW5rXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1bmtdcyB1bmRlciB0aGlzIGRvY3VtZW50LAog
cmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCB0aGlzIGRvY3VtZW50IGV4aXN0cywgYSBg
UEVSTUlTU0lPTl9ERU5JRURgCiBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQQBAgAFEgNhAggK
DAoFBAECAAESA2EJDwoMCgUEAQIAAxIDYRITCg0KBQQBAgAIEgRhFGYDCg8KCAQBAgAInAgA
EgNiBCoKDwoHBAECAAifCBIEYwRlBQqYAgoEBAECARIDbQIWGooCIE1heGltdW0gbnVtYmVy
IG9mIFtDaHVua11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNodW5r
XXMgdG8KIHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1bHRzIHRvIDEwMC4gVGhlIG1h
eGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLgogVmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBi
ZSBjb2VyY2VkIHRvIDEwMDAuCgogSWYgdGhpcyBmaWVsZCBpcyBuZWdhdGl2ZSwgYW4gYElO
VkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDAoFBAECAQUSA20CBwoMCgUE
AQIBARIDbQgRCgwKBQQBAgEDEgNtFBUKqQQKBAQBAgISA3kCGBqbBCBBIHBhZ2UgdG9rZW4K
IFtMaXN0Q2h1bmtzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdENodW5rc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tl
bl0sCiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIFtDaHVua1NlcnZpY2UuTGlzdENodW5r
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNodW5rU2VydmljZS5M
aXN0Q2h1bmtzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1
ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92
aWRlZCB0bwogW0NodW5rU2VydmljZS5MaXN0Q2h1bmtzXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1bmtTZXJ2aWNlLkxpc3RDaHVua3NdCiBtdXN0IG1hdGNo
IHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uIE90aGVyd2lzZSwgYW4K
IGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQQBAgIFEgN5AggK
DAoFBAECAgESA3kJEwoMCgUEAQICAxIDeRYXCoUBCgIEAhIFfwCIAQEaeCBSZXNwb25zZSBt
ZXNzYWdlIGZvcgogW0NodW5rU2VydmljZS5MaXN0Q2h1bmtzXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1bmtTZXJ2aWNlLkxpc3RDaHVua3NdCiBtZXRob2Qu
CgoKCgMEAgESA38IGgpJCgQEAgIAEgSBAQIcGjsgVGhlIFtDaHVua11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNodW5rXXMuCgoNCgUEAgIABBIEgQECCgoNCgUE
AgIABhIEgQELEAoNCgUEAgIAARIEgQERFwoNCgUEAgIAAxIEgQEaGwrlAQoEBAICARIEhwEC
HRrWASBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMKIFtMaXN0Q2h1bmtzUmVxdWVzdC5w
YWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdENo
dW5rc1JlcXVlc3QucGFnZV90b2tlbl0KIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuIElm
IHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vCiBzdWJzZXF1ZW50IHBhZ2Vz
LgoKDQoFBAICAQUSBIcBAggKDQoFBAICAQESBIcBCRgKDQoFBAICAQMSBIcBGxxiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest ===
    # Fields for GetChunkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksRequest ===
    # Fields for ListChunksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksResponse ===
    # Fields for ListChunksResponse
    # Field: chunks Type: 11 (.google.cloud.discoveryengine.v1alpha.Chunk)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::ChunkService::ChunkServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::ChunkService::ChunkServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::ChunkService::ChunkServiceClient

Client stub representing the remote C<ChunkService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_chunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ChunkService',
        method         => 'GetChunk',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk',
    });
}

sub list_chunks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ChunkService',
        method         => 'ListChunks',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ChunkService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/chunk_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::ChunkService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/chunk_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest

Request message for
[ChunkService.GetChunk][google.cloud.discoveryengine.v1alpha.ChunkService.GetChunk]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Chunk][google.cloud.discoveryengine.v1alpha.Chunk], such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document}/chunks/{chunk}`.

If the caller does not have permission to access the
[Chunk][google.cloud.discoveryengine.v1alpha.Chunk], regardless of whether
or not it exists, a `PERMISSION_DENIED` error is returned.

If the requested [Chunk][google.cloud.discoveryengine.v1alpha.Chunk] does
not exist, a `NOT_FOUND` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksRequest

Request message for
[ChunkService.ListChunks][google.cloud.discoveryengine.v1alpha.ChunkService.ListChunks]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent document resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document}`.

If the caller does not have permission to list
[Chunk][google.cloud.discoveryengine.v1alpha.Chunk]s under this document,
regardless of whether or not this document exists, a `PERMISSION_DENIED`
error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of [Chunk][google.cloud.discoveryengine.v1alpha.Chunk]s to
return. If unspecified, defaults to 100. The maximum allowed value is 1000.
Values above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListChunksResponse.next_page_token][google.cloud.discoveryengine.v1alpha.ListChunksResponse.next_page_token],
received from a previous
[ChunkService.ListChunks][google.cloud.discoveryengine.v1alpha.ChunkService.ListChunks]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[ChunkService.ListChunks][google.cloud.discoveryengine.v1alpha.ChunkService.ListChunks]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksResponse

Response message for
[ChunkService.ListChunks][google.cloud.discoveryengine.v1alpha.ChunkService.ListChunks]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->chunks() >> / C<< $msg->chunks($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk>)

The [Chunk][google.cloud.discoveryengine.v1alpha.Chunk]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListChunksRequest.page_token][google.cloud.discoveryengine.v1alpha.ListChunksRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::ChunkService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
