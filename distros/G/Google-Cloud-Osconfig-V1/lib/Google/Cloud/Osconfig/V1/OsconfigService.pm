package Google::Cloud::Osconfig::V1::OsconfigService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Client };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Osconfig::V1::PatchDeployments };
    eval { require Google::Cloud::Osconfig::V1::PatchJobs };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvb3Njb25maWcvdjEvb3Njb25maWdfc2VydmljZS5wcm90bxIYZ29v
Z2xlLmNsb3VkLm9zY29uZmlnLnYxGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxowZ29vZ2xlL2Nsb3VkL29zY29uZmlnL3YxL3BhdGNoX2Rl
cGxveW1lbnRzLnByb3RvGilnb29nbGUvY2xvdWQvb3Njb25maWcvdjEvcGF0Y2hfam9icy5w
cm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvMqwSCg9Pc0NvbmZpZ1NlcnZpY2USnQEKD0V4ZWN1dGVQYXRjaEpvYhIwLmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MS5FeGVjdXRlUGF0Y2hKb2JSZXF1ZXN0GiIuZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLnYxLlBhdGNoSm9iIjSC0+STAi4iKS92MS97cGFyZW50PXByb2pl
Y3RzLyp9L3BhdGNoSm9iczpleGVjdXRlOgEqEpEBCgtHZXRQYXRjaEpvYhIsLmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy52MS5HZXRQYXRjaEpvYlJlcXVlc3QaIi5nb29nbGUuY2xvdWQub3Nj
b25maWcudjEuUGF0Y2hKb2IiMILT5JMCIxIhL3YxL3tuYW1lPXByb2plY3RzLyovcGF0Y2hK
b2JzLyp92kEEbmFtZRKaAQoOQ2FuY2VsUGF0Y2hKb2ISLy5nb29nbGUuY2xvdWQub3Njb25m
aWcudjEuQ2FuY2VsUGF0Y2hKb2JSZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYx
LlBhdGNoSm9iIjOC0+STAi0iKC92MS97bmFtZT1wcm9qZWN0cy8qL3BhdGNoSm9icy8qfTpj
YW5jZWw6ASoSpAEKDUxpc3RQYXRjaEpvYnMSLi5nb29nbGUuY2xvdWQub3Njb25maWcudjEu
TGlzdFBhdGNoSm9ic1JlcXVlc3QaLy5nb29nbGUuY2xvdWQub3Njb25maWcudjEuTGlzdFBh
dGNoSm9ic1Jlc3BvbnNlIjKC0+STAiMSIS92MS97cGFyZW50PXByb2plY3RzLyp9L3BhdGNo
Sm9ic9pBBnBhcmVudBLgAQobTGlzdFBhdGNoSm9iSW5zdGFuY2VEZXRhaWxzEjwuZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLnYxLkxpc3RQYXRjaEpvYkluc3RhbmNlRGV0YWlsc1JlcXVlc3Qa
PS5nb29nbGUuY2xvdWQub3Njb25maWcudjEuTGlzdFBhdGNoSm9iSW5zdGFuY2VEZXRhaWxz
UmVzcG9uc2UiRILT5JMCNRIzL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9wYXRjaEpvYnMvKn0v
aW5zdGFuY2VEZXRhaWxz2kEGcGFyZW50EuwBChVDcmVhdGVQYXRjaERlcGxveW1lbnQSNi5n
b29nbGUuY2xvdWQub3Njb25maWcudjEuQ3JlYXRlUGF0Y2hEZXBsb3ltZW50UmVxdWVzdBop
Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5QYXRjaERlcGxveW1lbnQicILT5JMCPCIoL3Yx
L3twYXJlbnQ9cHJvamVjdHMvKn0vcGF0Y2hEZXBsb3ltZW50czoQcGF0Y2hfZGVwbG95bWVu
dNpBK3BhcmVudCxwYXRjaF9kZXBsb3ltZW50LHBhdGNoX2RlcGxveW1lbnRfaWQSrQEKEkdl
dFBhdGNoRGVwbG95bWVudBIzLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5HZXRQYXRjaERl
cGxveW1lbnRSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLlBhdGNoRGVwbG95
bWVudCI3gtPkkwIqEigvdjEve25hbWU9cHJvamVjdHMvKi9wYXRjaERlcGxveW1lbnRzLyp9
2kEEbmFtZRLAAQoUTGlzdFBhdGNoRGVwbG95bWVudHMSNS5nb29nbGUuY2xvdWQub3Njb25m
aWcudjEuTGlzdFBhdGNoRGVwbG95bWVudHNSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLm9zY29u
ZmlnLnYxLkxpc3RQYXRjaERlcGxveW1lbnRzUmVzcG9uc2UiOYLT5JMCKhIoL3YxL3twYXJl
bnQ9cHJvamVjdHMvKn0vcGF0Y2hEZXBsb3ltZW50c9pBBnBhcmVudBKgAQoVRGVsZXRlUGF0
Y2hEZXBsb3ltZW50EjYuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLkRlbGV0ZVBhdGNoRGVw
bG95bWVudFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiN4LT5JMCKiooL3YxL3tu
YW1lPXByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qfdpBBG5hbWUS7gEKFVVwZGF0ZVBh
dGNoRGVwbG95bWVudBI2Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5VcGRhdGVQYXRjaERl
cGxveW1lbnRSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLlBhdGNoRGVwbG95
bWVudCJygtPkkwJNMjkvdjEve3BhdGNoX2RlcGxveW1lbnQubmFtZT1wcm9qZWN0cy8qL3Bh
dGNoRGVwbG95bWVudHMvKn06EHBhdGNoX2RlcGxveW1lbnTaQRxwYXRjaF9kZXBsb3ltZW50
LHVwZGF0ZV9tYXNrEroBChRQYXVzZVBhdGNoRGVwbG95bWVudBI1Lmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy52MS5QYXVzZVBhdGNoRGVwbG95bWVudFJlcXVlc3QaKS5nb29nbGUuY2xvdWQu
b3Njb25maWcudjEuUGF0Y2hEZXBsb3ltZW50IkCC0+STAjMiLi92MS97bmFtZT1wcm9qZWN0
cy8qL3BhdGNoRGVwbG95bWVudHMvKn06cGF1c2U6ASraQQRuYW1lEr0BChVSZXN1bWVQYXRj
aERlcGxveW1lbnQSNi5nb29nbGUuY2xvdWQub3Njb25maWcudjEuUmVzdW1lUGF0Y2hEZXBs
b3ltZW50UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5QYXRjaERlcGxveW1l
bnQiQYLT5JMCNCIvL3YxL3tuYW1lPXByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qfTpy
ZXN1bWU6ASraQQRuYW1lGkvKQRdvc2NvbmZpZy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C1AIKHGNvbS5nb29nbGUu
Y2xvdWQub3Njb25maWcudjFCDU9zQ29uZmlnUHJvdG9aOGNsb3VkLmdvb2dsZS5jb20vZ28v
b3Njb25maWcvYXBpdjEvb3Njb25maWdwYjtvc2NvbmZpZ3BiqgIYR29vZ2xlLkNsb3VkLk9z
Q29uZmlnLlYxygIYR29vZ2xlXENsb3VkXE9zQ29uZmlnXFYx6gIbR29vZ2xlOjpDbG91ZDo6
T3NDb25maWc6OlYx6kGVAQofY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZRI0cHJv
amVjdHMve3Byb2plY3R9L3pvbmVzL3t6b25lfS9pbnN0YW5jZXMve2luc3RhbmNlfRI8cHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFu
Y2V9StgZCgcSBQ4AnQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
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
AhIDEAAhCgkKAgMAEgMSACEKCQoCAwESAxMAIwoJCgIDAhIDFAA6CgkKAgMDEgMVADMKCQoC
AwQSAxYAJQoJCgIDBRIDFwAmCggKAQgSAxkANQoJCgIIJRIDGQA1CggKAQgSAxoATwoJCgII
CxIDGgBPCggKAQgSAxsALgoJCgIICBIDGwAuCggKAQgSAxwANQoJCgIIARIDHAA1CggKAQgS
Ax0ANQoJCgIIKRIDHQA1CggKAQgSAx4ANAoJCgIILRIDHgA0CgkKAQgSBB8AIwIKDAoECJ0I
ABIEHwAjAgqwAQoCBgASBSkAnQEBGqIBIE9TIENvbmZpZyBBUEkKCiBUaGUgT1MgQ29uZmln
IHNlcnZpY2UgaXMgYSBzZXJ2ZXItc2lkZSBjb21wb25lbnQgdGhhdCB5b3UgY2FuIHVzZSB0
bwogbWFuYWdlIHBhY2thZ2UgaW5zdGFsbGF0aW9ucyBhbmQgcGF0Y2ggam9icyBmb3Igdmly
dHVhbCBtYWNoaW5lIGluc3RhbmNlcy4KCgoKAwYAARIDKQgXCgoKAwYAAxIDKgI/CgwKBQYA
A5kIEgMqAj8KCwoDBgADEgQrAiw3Cg0KBQYAA5oIEgQrAiw3CkcKBAYAAgASBC8CNAMaOSBQ
YXRjaCBWTSBpbnN0YW5jZXMgYnkgY3JlYXRpbmcgYW5kIHJ1bm5pbmcgYSBwYXRjaCBqb2Iu
CgoMCgUGAAIAARIDLwYVCgwKBQYAAgACEgMvFiwKDAoFBgACAAMSAy83PwoNCgUGAAIABBIE
MAQzBgoRCgkGAAIABLDKvCISBDAEMwYKiwEKBAYAAgESBDgCPQMafSBHZXQgdGhlIHBhdGNo
IGpvYi4gVGhpcyBjYW4gYmUgdXNlZCB0byB0cmFjayB0aGUgcHJvZ3Jlc3Mgb2YgYW4KIG9u
Z29pbmcgcGF0Y2ggam9iIG9yIHJldmlldyB0aGUgZGV0YWlscyBvZiBjb21wbGV0ZWQgam9i
cy4KCgwKBQYAAgEBEgM4BhEKDAoFBgACAQISAzgSJAoMCgUGAAIBAxIDOC83Cg0KBQYAAgEE
EgQ5BDsGChEKCQYAAgEEsMq8IhIEOQQ7BgoMCgUGAAIBBBIDPAQyCg8KCAYAAgEEmwgAEgM8
BDIKawoEBgACAhIEQQJGAxpdIENhbmNlbCBhIHBhdGNoIGpvYi4gVGhlIHBhdGNoIGpvYiBt
dXN0IGJlIGFjdGl2ZS4gQ2FuY2VsZWQgcGF0Y2ggam9icwogY2Fubm90IGJlIHJlc3RhcnRl
ZC4KCgwKBQYAAgIBEgNBBhQKDAoFBgACAgISA0EVKgoMCgUGAAICAxIDQTU9Cg0KBQYAAgIE
EgRCBEUGChEKCQYAAgIEsMq8IhIEQgRFBgopCgQGAAIDEgRJAk4DGhsgR2V0IGEgbGlzdCBv
ZiBwYXRjaCBqb2JzLgoKDAoFBgACAwESA0kGEwoMCgUGAAIDAhIDSRQoCgwKBQYAAgMDEgNJ
M0gKDQoFBgACAwQSBEoETAYKEQoJBgACAwSwyrwiEgRKBEwGCgwKBQYAAgMEEgNNBDQKDwoI
BgACAwSbCAASA00ENApFCgQGAAIEEgRRAlcDGjcgR2V0IGEgbGlzdCBvZiBpbnN0YW5jZSBk
ZXRhaWxzIGZvciBhIGdpdmVuIHBhdGNoIGpvYi4KCgwKBQYAAgQBEgNRBiEKDAoFBgACBAIS
A1EiRAoMCgUGAAIEAxIDUg8yCg0KBQYAAgQEEgRTBFUGChEKCQYAAgQEsMq8IhIEUwRVBgoM
CgUGAAIEBBIDVgQ0Cg8KCAYAAgQEmwgAEgNWBDQKNQoEBgACBRIEWgJiAxonIENyZWF0ZSBh
biBPUyBDb25maWcgcGF0Y2ggZGVwbG95bWVudC4KCgwKBQYAAgUBEgNaBhsKDAoFBgACBQIS
A1ocOAoMCgUGAAIFAxIDWw8eCg0KBQYAAgUEEgRcBF8GChEKCQYAAgUEsMq8IhIEXARfBgoN
CgUGAAIFBBIEYARhNgoQCggGAAIFBJsIABIEYARhNgoyCgQGAAIGEgRlAmoDGiQgR2V0IGFu
IE9TIENvbmZpZyBwYXRjaCBkZXBsb3ltZW50LgoKDAoFBgACBgESA2UGGAoMCgUGAAIGAhID
ZRkyCgwKBQYAAgYDEgNlPUwKDQoFBgACBgQSBGYEaAYKEQoJBgACBgSwyrwiEgRmBGgGCgwK
BQYAAgYEEgNpBDIKDwoIBgACBgSbCAASA2kEMgo6CgQGAAIHEgRtAnMDGiwgR2V0IGEgcGFn
ZSBvZiBPUyBDb25maWcgcGF0Y2ggZGVwbG95bWVudHMuCgoMCgUGAAIHARIDbQYaCgwKBQYA
AgcCEgNtGzYKDAoFBgACBwMSA24PKwoNCgUGAAIHBBIEbwRxBgoRCgkGAAIHBLDKvCISBG8E
cQYKDAoFBgACBwQSA3IENAoPCggGAAIHBJsIABIDcgQ0CjUKBAYAAggSBHYCfAMaJyBEZWxl
dGUgYW4gT1MgQ29uZmlnIHBhdGNoIGRlcGxveW1lbnQuCgoMCgUGAAIIARIDdgYbCgwKBQYA
AggCEgN2HDgKDAoFBgACCAMSA3cPJAoNCgUGAAIIBBIEeAR6BgoRCgkGAAIIBLDKvCISBHgE
egYKDAoFBgACCAQSA3sEMgoPCggGAAIIBJsIABIDewQyCjYKBAYAAgkSBX8ChgEDGicgVXBk
YXRlIGFuIE9TIENvbmZpZyBwYXRjaCBkZXBsb3ltZW50LgoKDAoFBgACCQESA38GGwoMCgUG
AAIJAhIDfxw4Cg0KBQYAAgkDEgSAAQ8eCg8KBQYAAgkEEgaBAQSEAQYKEwoJBgACCQSwyrwi
EgaBAQSEAQYKDQoFBgACCQQSBIUBBEoKEAoIBgACCQSbCAASBIUBBEoKfgoEBgACChIGigEC
kQEDGm4gQ2hhbmdlIHN0YXRlIG9mIHBhdGNoIGRlcGxveW1lbnQgdG8gIlBBVVNFRCIuCiBQ
YXRjaCBkZXBsb3ltZW50IGluIHBhdXNlZCBzdGF0ZSBkb2Vzbid0IGdlbmVyYXRlIHBhdGNo
IGpvYnMuCgoNCgUGAAIKARIEigEGGgoNCgUGAAIKAhIEigEbNgoNCgUGAAIKAxIEiwEPHgoP
CgUGAAIKBBIGjAEEjwEGChMKCQYAAgoEsMq8IhIGjAEEjwEGCg0KBQYAAgoEEgSQAQQyChAK
CAYAAgoEmwgAEgSQAQQyCogBCgQGAAILEgaVAQKcAQMaeCBDaGFuZ2Ugc3RhdGUgb2YgcGF0
Y2ggZGVwbG95bWVudCBiYWNrIHRvICJBQ1RJVkUiLgogUGF0Y2ggZGVwbG95bWVudCBpbiBh
Y3RpdmUgc3RhdGUgY29udGludWVzIHRvIGdlbmVyYXRlIHBhdGNoIGpvYnMuCgoNCgUGAAIL
ARIElQEGGwoNCgUGAAILAhIElQEcOAoNCgUGAAILAxIElgEPHgoPCgUGAAILBBIGlwEEmgEG
ChMKCQYAAgsEsMq8IhIGlwEEmgEGCg0KBQYAAgsEEgSbAQQyChAKCAYAAgsEmwgAEgSbAQQy
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Osconfig::V1::OsconfigService::OsConfigServiceClient ===
package Google::Cloud::Osconfig::V1::OsconfigService::OsConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Osconfig::V1::OsconfigService::OsConfigServiceClient

Client stub representing the remote C<OsConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<osconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'osconfig.googleapis.com:443' );

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

sub execute_patch_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchJobs::ExecutePatchJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'ExecutePatchJob',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchJobs::PatchJob',
    });
}

sub get_patch_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchJobs::GetPatchJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'GetPatchJob',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchJobs::PatchJob',
    });
}

sub cancel_patch_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchJobs::CancelPatchJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'CancelPatchJob',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchJobs::PatchJob',
    });
}

sub list_patch_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchJobs::ListPatchJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'ListPatchJobs',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchJobs::ListPatchJobsResponse',
    });
}

sub list_patch_job_instance_details {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchJobs::ListPatchJobInstanceDetailsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'ListPatchJobInstanceDetails',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchJobs::ListPatchJobInstanceDetailsResponse',
    });
}

sub create_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::CreatePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'CreatePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment',
    });
}

sub get_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::GetPatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'GetPatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment',
    });
}

sub list_patch_deployments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'ListPatchDeployments',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsResponse',
    });
}

sub delete_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::DeletePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'DeletePatchDeployment',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::UpdatePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'UpdatePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment',
    });
}

sub pause_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::PausePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'PausePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment',
    });
}

sub resume_patch_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1::PatchDeployments::ResumePatchDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1.OsConfigService',
        method         => 'ResumePatchDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1::OsconfigService - Compiled Protocol Buffers messages for google/cloud/osconfig/v1/osconfig_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1/osconfig_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1::OsconfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
