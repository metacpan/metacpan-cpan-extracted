package Google::Cloud::Discoveryengine::V1::RankService;

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
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3Jhbmtfc2VydmljZS5wcm90bxIf
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iZQoNUmFua2luZ1JlY29y
ZBIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEhgKB2NvbnRlbnQYAyAB
KAlSB2NvbnRlbnQSFAoFc2NvcmUYBCABKAJSBXNjb3JlIuIDCgtSYW5rUmVxdWVzdBJbCg5y
YW5raW5nX2NvbmZpZxgBIAEoCUI04EEC+kEuCixkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb20vUmFua2luZ0NvbmZpZ1INcmFua2luZ0NvbmZpZxIUCgVtb2RlbBgCIAEoCVIFbW9k
ZWwSEwoFdG9wX24YAyABKAVSBHRvcE4SFAoFcXVlcnkYBCABKAlSBXF1ZXJ5Ek0KB3JlY29y
ZHMYBSADKAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJhbmtpbmdSZWNv
cmRCA+BBAlIHcmVjb3JkcxJICiFpZ25vcmVfcmVjb3JkX2RldGFpbHNfaW5fcmVzcG9uc2UY
BiABKAhSHWlnbm9yZVJlY29yZERldGFpbHNJblJlc3BvbnNlEl0KC3VzZXJfbGFiZWxzGAcg
AygLMjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5SYW5rUmVxdWVzdC5Vc2Vy
TGFiZWxzRW50cnlSCnVzZXJMYWJlbHMaPQoPVXNlckxhYmVsc0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiWAoMUmFua1Jlc3BvbnNlEkgKB3Jl
Y29yZHMYBSADKAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJhbmtpbmdS
ZWNvcmRSB3JlY29yZHMykwMKC1JhbmtTZXJ2aWNlErEBCgRSYW5rEiwuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5SYW5rUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuUmFua1Jlc3BvbnNlIkyC0+STAkYiQS92MS97cmFua2luZ19jb25maWc9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yYW5raW5nQ29uZmlncy8qfTpyYW5rOgEqGs8BykEe
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQoMCCiNjb20uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUIQUmFua1NlcnZpY2VQcm90b1ABWk1jbG91
ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVw
YjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5E
aXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIi
R29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUrhIwoHEgUOAIYBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCggKAQgSAxcAPAoJCgIIJRIDFwA8CggKAQgS
AxgAZAoJCgIICxIDGABkCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMQoJCgIICBID
GgAxCggKAQgSAxsAPAoJCgIIARIDGwA8CggKAQgSAxwALQoJCgIIJBIDHAAtCggKAQgSAx0A
PAoJCgIIKRIDHQA8CggKAQgSAx4AOwoJCgIILRIDHgA7Ci8KAgYAEgQhAC8BGiMgU2Vydmlj
ZSBmb3IgcmFua2luZyB0ZXh0IHJlY29yZHMuCgoKCgMGAAESAyEIEwoKCgMGAAMSAyICRgoM
CgUGAAOZCBIDIgJGCgsKAwYAAxIEIwImSgoNCgUGAAOaCBIEIwImSgpMCgQGAAIAEgQpAi4D
Gj4gUmFua3MgYSBsaXN0IG9mIHRleHQgcmVjb3JkcyBiYXNlZCBvbiB0aGUgZ2l2ZW4gaW5w
dXQgcXVlcnkuCgoMCgUGAAIAARIDKQYKCgwKBQYAAgACEgMpCxYKDAoFBgACAAMSAykhLQoN
CgUGAAIABBIEKgQtBgoRCgkGAAIABLDKvCISBCoELQYKbgoCBAASBDMASQEaYiBSZWNvcmQg
bWVzc2FnZSBmb3IKIFtSYW5rU2VydmljZS5SYW5rXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLlJhbmtTZXJ2aWNlLlJhbmtdIG1ldGhvZC4KCgoKAwQAARIDMwgVCjUKBAQA
AgASAzUCEBooIFRoZSB1bmlxdWUgSUQgdG8gcmVwcmVzZW50IHRoZSByZWNvcmQuCgoMCgUE
AAIABRIDNQIICgwKBQQAAgABEgM1CQsKDAoFBAACAAMSAzUODwqMAgoEBAACARIDPAITGv4B
IFRoZSB0aXRsZSBvZiB0aGUgcmVjb3JkLiBFbXB0eSBieSBkZWZhdWx0LgogQXQgbGVhc3Qg
b25lIG9mCiBbdGl0bGVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUmFua2lu
Z1JlY29yZC50aXRsZV0gb3IKIFtjb250ZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlJhbmtpbmdSZWNvcmQuY29udGVudF0gc2hvdWxkIGJlCiBzZXQgb3RoZXJ3aXNl
IGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgdGhyb3duLgoKDAoFBAACAQUSAzwCCAoM
CgUEAAIBARIDPAkOCgwKBQQAAgEDEgM8ERIKjgIKBAQAAgISA0MCFRqAAiBUaGUgY29udGVu
dCBvZiB0aGUgcmVjb3JkLiBFbXB0eSBieSBkZWZhdWx0LgogQXQgbGVhc3Qgb25lIG9mCiBb
dGl0bGVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUmFua2luZ1JlY29yZC50
aXRsZV0gb3IKIFtjb250ZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJh
bmtpbmdSZWNvcmQuY29udGVudF0gc2hvdWxkIGJlCiBzZXQgb3RoZXJ3aXNlIGFuIElOVkFM
SURfQVJHVU1FTlQgZXJyb3IgaXMgdGhyb3duLgoKDAoFBAACAgUSA0MCCAoMCgUEAAICARID
QwkQCgwKBQQAAgIDEgNDExQK2gEKBAQAAgMSA0gCEhrMASBUaGUgc2NvcmUgb2YgdGhpcyBy
ZWNvcmQgYmFzZWQgb24gdGhlIGdpdmVuIHF1ZXJ5IGFuZCBzZWxlY3RlZCBtb2RlbC4KIFRo
ZSBzY29yZSB3aWxsIGJlIHJvdW5kZWQgdG8gNCBkZWNpbWFsIHBsYWNlcy4gSWYgdGhlIHNj
b3JlIGlzIGNsb3NlIHRvIDAsCiBpdCB3aWxsIGJlIHJvdW5kZWQgdG8gMC4wMDAwMSB0byBh
dm9pZCByZXR1cm5pbmcgdW5zZXQuCgoMCgUEAAIDBRIDSAIHCgwKBQQAAgMBEgNICA0KDAoF
BAACAwMSA0gQEQpvCgIEARIETQB/ARpjIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtSYW5rU2Vy
dmljZS5SYW5rXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJhbmtTZXJ2aWNl
LlJhbmtdIG1ldGhvZC4KCgoKAwQBARIDTQgTCqYBCgQEAQIAEgRQAlUEGpcBIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmFuayBzZXJ2aWNlIGNvbmZpZywgc3VjaCBh
cwogYHByb2plY3RzL3twcm9qZWN0X251bX0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmFua2lu
Z0NvbmZpZ3MvZGVmYXVsdF9yYW5raW5nX2NvbmZpZ2AuCgoMCgUEAQIABRIDUAIICgwKBQQB
AgABEgNQCRcKDAoFBAECAAMSA1AaGwoNCgUEAQIACBIEUBxVAwoPCggEAQIACJwIABIDUQQq
Cg8KBwQBAgAInwgSBFIEVAUK5QEKBAQBAgESA10CExrXASBUaGUgaWRlbnRpZmllciBvZiB0
aGUgbW9kZWwgdG8gdXNlLiBJdCBpcyBvbmUgb2Y6CgogKiBgc2VtYW50aWMtcmFua2VyLTUx
MkBsYXRlc3RgOiBTZW1hbnRpYyByYW5raW5nIG1vZGVsIHdpdGggbWF4aW11bSBpbnB1dAog
dG9rZW4gc2l6ZSA1MTIuCgogSXQgaXMgc2V0IHRvIGBzZW1hbnRpYy1yYW5rZXItNTEyQGxh
dGVzdGAgYnkgZGVmYXVsdCBpZiB1bnNwZWNpZmllZC4KCgwKBQQBAgEFEgNdAggKDAoFBAEC
AQESA10JDgoMCgUEAQIBAxIDXRESCm4KBAQBAgISA2ECEhphIFRoZSBudW1iZXIgb2YgcmVz
dWx0cyB0byByZXR1cm4uIElmIHRoaXMgaXMgdW5zZXQgb3Igbm8gYmlnZ2VyIHRoYW4gemVy
bywKIHJldHVybnMgYWxsIHJlc3VsdHMuCgoMCgUEAQICBRIDYQIHCgwKBQQBAgIBEgNhCA0K
DAoFBAECAgMSA2EQEQogCgQEAQIDEgNkAhMaEyBUaGUgcXVlcnkgdG8gdXNlLgoKDAoFBAEC
AwUSA2QCCAoMCgUEAQIDARIDZAkOCgwKBQQBAgMDEgNkERIKMwoEBAECBBIDZwJOGiYgUmVx
dWlyZWQuIEEgbGlzdCBvZiByZWNvcmRzIHRvIHJhbmsuCgoMCgUEAQIEBBIDZwIKCgwKBQQB
AgQGEgNnCxgKDAoFBAECBAESA2cZIAoMCgUEAQIEAxIDZyMkCgwKBQQBAgQIEgNnJU0KDwoI
BAECBAicCAASA2cmTAqQAQoEBAECBRIDawItGoIBIElmIHRydWUsIHRoZSByZXNwb25zZSB3
aWxsIGNvbnRhaW4gb25seSByZWNvcmQgSUQgYW5kIHNjb3JlLiBCeSBkZWZhdWx0LCBpdAog
aXMgZmFsc2UsIHRoZSByZXNwb25zZSB3aWxsIGNvbnRhaW4gcmVjb3JkIGRldGFpbHMuCgoM
CgUEAQIFBRIDawIGCgwKBQQBAgUBEgNrBygKDAoFBAECBQMSA2srLArrBgoEBAECBhIDfgIm
Gt0GIFRoZSB1c2VyIGxhYmVscyBhcHBsaWVkIHRvIGEgcmVzb3VyY2UgbXVzdCBtZWV0IHRo
ZSBmb2xsb3dpbmcgcmVxdWlyZW1lbnRzOgoKICogRWFjaCByZXNvdXJjZSBjYW4gaGF2ZSBt
dWx0aXBsZSBsYWJlbHMsIHVwIHRvIGEgbWF4aW11bSBvZiA2NC4KICogRWFjaCBsYWJlbCBt
dXN0IGJlIGEga2V5LXZhbHVlIHBhaXIuCiAqIEtleXMgaGF2ZSBhIG1pbmltdW0gbGVuZ3Ro
IG9mIDEgY2hhcmFjdGVyIGFuZCBhIG1heGltdW0gbGVuZ3RoIG9mIDYzCiAgIGNoYXJhY3Rl
cnMgYW5kIGNhbm5vdCBiZSBlbXB0eS4gVmFsdWVzIGNhbiBiZSBlbXB0eSBhbmQgaGF2ZSBh
IG1heGltdW0KICAgbGVuZ3RoIG9mIDYzIGNoYXJhY3RlcnMuCiAqIEtleXMgYW5kIHZhbHVl
cyBjYW4gY29udGFpbiBvbmx5IGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1lcmljIGNoYXJhY3Rl
cnMsCiAgIHVuZGVyc2NvcmVzLCBhbmQgZGFzaGVzLiBBbGwgY2hhcmFjdGVycyBtdXN0IHVz
ZSBVVEYtOCBlbmNvZGluZywgYW5kCiAgIGludGVybmF0aW9uYWwgY2hhcmFjdGVycyBhcmUg
YWxsb3dlZC4KICogVGhlIGtleSBwb3J0aW9uIG9mIGEgbGFiZWwgbXVzdCBiZSB1bmlxdWUu
IEhvd2V2ZXIsIHlvdSBjYW4gdXNlIHRoZSBzYW1lCiAgIGtleSB3aXRoIG11bHRpcGxlIHJl
c291cmNlcy4KICogS2V5cyBtdXN0IHN0YXJ0IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIG9y
IGludGVybmF0aW9uYWwgY2hhcmFjdGVyLgoKIFNlZSBbR29vZ2xlIENsb3VkCiBEb2N1bWVu
dF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVh
dGluZy1tYW5hZ2luZy1sYWJlbHMjcmVxdWlyZW1lbnRzKQogZm9yIG1vcmUgZGV0YWlscy4K
CgwKBQQBAgYGEgN+AhUKDAoFBAECBgESA34WIQoMCgUEAQIGAxIDfiQlCnIKAgQCEgaDAQCG
AQEaZCBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1JhbmtTZXJ2aWNlLlJhbmtdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUmFua1NlcnZpY2UuUmFua10gbWV0aG9kLgoKCwoD
BAIBEgSDAQgUCj0KBAQCAgASBIUBAiUaLyBBIGxpc3Qgb2YgcmVjb3JkcyBzb3J0ZWQgYnkg
ZGVzY2VuZGluZyBzY29yZS4KCg0KBQQCAgAEEgSFAQIKCg0KBQQCAgAGEgSFAQsYCg0KBQQC
AgABEgSFARkgCg0KBQQCAgADEgSFASMkYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::RankService::RankingRecord ===
    # Fields for RankingRecord
    # Field: id Type: 9 ()
    # Field: title Type: 9 ()
    # Field: content Type: 9 ()
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Discoveryengine::V1::RankService::RankRequest ===
    # Fields for RankRequest
    # Field: ranking_config Type: 9 ()
    # Field: model Type: 9 ()
    # Field: top_n Type: 5 ()
    # Field: query Type: 9 ()
    # Field: records Type: 11 (.google.cloud.discoveryengine.v1.RankingRecord)
    # Field: ignore_record_details_in_response Type: 8 ()
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1.RankRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1::RankService::RankResponse ===
    # Fields for RankResponse
    # Field: records Type: 11 (.google.cloud.discoveryengine.v1.RankingRecord)

# === Service Client: Google::Cloud::Discoveryengine::V1::RankService::RankServiceClient ===
package Google::Cloud::Discoveryengine::V1::RankService::RankServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::RankService::RankServiceClient

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
        ? Google::Cloud::Discoveryengine::V1::RankService::RankRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.RankService',
        method         => 'Rank',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::RankService::RankResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::RankService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/rank_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::RankService;

    my $msg = Google::Cloud::Discoveryengine::V1::RankService::RankingRecord->new({
        id => $id,
        title => $title,
        content => $content,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::RankService::RankingRecord->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/rank_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::RankService::RankingRecord

Record message for
[RankService.Rank][google.cloud.discoveryengine.v1.RankService.Rank] method.

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
[title][google.cloud.discoveryengine.v1.RankingRecord.title] or
[content][google.cloud.discoveryengine.v1.RankingRecord.content] should be
set otherwise an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

The content of the record. Empty by default.
At least one of
[title][google.cloud.discoveryengine.v1.RankingRecord.title] or
[content][google.cloud.discoveryengine.v1.RankingRecord.content] should be
set otherwise an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

The score of this record based on the given query and selected model.
The score will be rounded to 4 decimal places. If the score is close to 0,
it will be rounded to 0.00001 to avoid returning unset.

=back

=head2 Google::Cloud::Discoveryengine::V1::RankService::RankRequest

Request message for
[RankService.Rank][google.cloud.discoveryengine.v1.RankService.Rank] method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ranking_config() >> / C<< $msg->ranking_config($value) >>

Type: C<String>

Required. The resource name of the rank service config, such as
`projects/{project_num}/locations/{location}/rankingConfigs/default_ranking_config`.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The identifier of the model to use. It is one of:

* `semantic-ranker-512@latest`: Semantic ranking model with maximum input
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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::RankService::RankingRecord>)

Required. A list of records to rank.

=item * C<< $msg->ignore_record_details_in_response() >> / C<< $msg->ignore_record_details_in_response($value) >>

Type: C<Bool>

If true, the response will contain only record ID and score. By default, it
is false, the response will contain record details.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::RankService::RankRequest::UserLabelsEntry>)

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

=head2 Google::Cloud::Discoveryengine::V1::RankService::RankResponse

Response message for
[RankService.Rank][google.cloud.discoveryengine.v1.RankService.Rank] method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->records() >> / C<< $msg->records($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::RankService::RankingRecord>)

A list of records sorted by descending score.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::RankService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
