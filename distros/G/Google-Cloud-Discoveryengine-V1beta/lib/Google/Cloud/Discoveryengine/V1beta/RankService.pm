package Google::Cloud::Discoveryengine::V1beta::RankService;

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
CjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9yYW5rX3NlcnZpY2UucHJv
dG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUvYXBpL2Fu
bm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byJlCg1SYW5r
aW5nUmVjb3JkEg4KAmlkGAEgASgJUgJpZBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSGAoHY29u
dGVudBgDIAEoCVIHY29udGVudBIUCgVzY29yZRgEIAEoAlIFc2NvcmUi6gMKC1JhbmtSZXF1
ZXN0ElsKDnJhbmtpbmdfY29uZmlnGAEgASgJQjTgQQL6QS4KLGRpc2NvdmVyeWVuZ2luZS5n
b29nbGVhcGlzLmNvbS9SYW5raW5nQ29uZmlnUg1yYW5raW5nQ29uZmlnEhQKBW1vZGVsGAIg
ASgJUgVtb2RlbBITCgV0b3BfbhgDIAEoBVIEdG9wThIUCgVxdWVyeRgEIAEoCVIFcXVlcnkS
UQoHcmVjb3JkcxgFIAMoCzIyLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlJhbmtpbmdSZWNvcmRCA+BBAlIHcmVjb3JkcxJICiFpZ25vcmVfcmVjb3JkX2RldGFpbHNf
aW5fcmVzcG9uc2UYBiABKAhSHWlnbm9yZVJlY29yZERldGFpbHNJblJlc3BvbnNlEmEKC3Vz
ZXJfbGFiZWxzGAcgAygLMkAuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
UmFua1JlcXVlc3QuVXNlckxhYmVsc0VudHJ5Ugp1c2VyTGFiZWxzGj0KD1VzZXJMYWJlbHNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIlwKDFJh
bmtSZXNwb25zZRJMCgdyZWNvcmRzGAUgAygLMjIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuUmFua2luZ1JlY29yZFIHcmVjb3JkczKfAwoLUmFua1NlcnZpY2USvQEK
BFJhbmsSMC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5SYW5rUmVxdWVz
dBoxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJhbmtSZXNwb25zZSJQ
gtPkkwJKIkUvdjFiZXRhL3tyYW5raW5nX2NvbmZpZz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3JhbmtpbmdDb25maWdzLyp9OnJhbms6ASoazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xl
YXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5y
ZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zlcnllbmdp
bmUuc2VydmluZy5yZWFkd3JpdGVClwIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YUIQUmFua1NlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rp
c2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5n
aW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5l
LlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xl
OjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKhSQKBxIFDgCJAQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoICgEIEgMXAEAKCQoCCCUSAxcAQAoICgEIEgMY
AGgKCQoCCAsSAxgAaAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADEKCQoCCAgSAxoA
MQoICgEIEgMbAEAKCQoCCAESAxsAQAoICgEIEgMcAC0KCQoCCCQSAxwALQoICgEIEgMdAEAK
CQoCCCkSAx0AQAoICgEIEgMeAD8KCQoCCC0SAx4APwovCgIGABIEIQAvARojIFNlcnZpY2Ug
Zm9yIHJhbmtpbmcgdGV4dCByZWNvcmRzLgoKCgoDBgABEgMhCBMKCgoDBgADEgMiAkYKDAoF
BgADmQgSAyICRgoLCgMGAAMSBCMCJkoKDQoFBgADmggSBCMCJkoKTAoEBgACABIEKQIuAxo+
IFJhbmtzIGEgbGlzdCBvZiB0ZXh0IHJlY29yZHMgYmFzZWQgb24gdGhlIGdpdmVuIGlucHV0
IHF1ZXJ5LgoKDAoFBgACAAESAykGCgoMCgUGAAIAAhIDKQsWCgwKBQYAAgADEgMpIS0KDQoF
BgACAAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0GCnMKAgQAEgQ0AEoBGmcgUmVjb3JkIG1l
c3NhZ2UgZm9yCiBbUmFua1NlcnZpY2UuUmFua11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuUmFua1NlcnZpY2UuUmFua10KIG1ldGhvZC4KCgoKAwQAARIDNAgVCjUK
BAQAAgASAzYCEBooIFRoZSB1bmlxdWUgSUQgdG8gcmVwcmVzZW50IHRoZSByZWNvcmQuCgoM
CgUEAAIABRIDNgIICgwKBQQAAgABEgM2CQsKDAoFBAACAAMSAzYODwqUAgoEBAACARIDPQIT
GoYCIFRoZSB0aXRsZSBvZiB0aGUgcmVjb3JkLiBFbXB0eSBieSBkZWZhdWx0LgogQXQgbGVh
c3Qgb25lIG9mCiBbdGl0bGVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlJhbmtpbmdSZWNvcmQudGl0bGVdIG9yCiBbY29udGVudF1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuUmFua2luZ1JlY29yZC5jb250ZW50XSBzaG91bGQKIGJlIHNl
dCBvdGhlcndpc2UgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyB0aHJvd24uCgoMCgUE
AAIBBRIDPQIICgwKBQQAAgEBEgM9CQ4KDAoFBAACAQMSAz0REgqWAgoEBAACAhIDRAIVGogC
IFRoZSBjb250ZW50IG9mIHRoZSByZWNvcmQuIEVtcHR5IGJ5IGRlZmF1bHQuCiBBdCBsZWFz
dCBvbmUgb2YKIFt0aXRsZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
UmFua2luZ1JlY29yZC50aXRsZV0gb3IKIFtjb250ZW50XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5SYW5raW5nUmVjb3JkLmNvbnRlbnRdIHNob3VsZAogYmUgc2V0
IG90aGVyd2lzZSBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHRocm93bi4KCgwKBQQA
AgIFEgNEAggKDAoFBAACAgESA0QJEAoMCgUEAAICAxIDRBMUCtoBCgQEAAIDEgNJAhIazAEg
VGhlIHNjb3JlIG9mIHRoaXMgcmVjb3JkIGJhc2VkIG9uIHRoZSBnaXZlbiBxdWVyeSBhbmQg
c2VsZWN0ZWQgbW9kZWwuCiBUaGUgc2NvcmUgd2lsbCBiZSByb3VuZGVkIHRvIDQgZGVjaW1h
bCBwbGFjZXMuIElmIHRoZSBzY29yZSBpcyBjbG9zZSB0byAwLAogaXQgd2lsbCBiZSByb3Vu
ZGVkIHRvIDAuMDAwMDEgdG8gYXZvaWQgcmV0dXJuaW5nIHVuc2V0LgoKDAoFBAACAwUSA0kC
BwoMCgUEAAIDARIDSQgNCgwKBQQAAgMDEgNJEBEKdQoCBAESBU8AgQEBGmggUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1JhbmtTZXJ2aWNlLlJhbmtdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLlJhbmtTZXJ2aWNlLlJhbmtdCiBtZXRob2QuCgoKCgMEAQESA08IEwqm
AQoEBAECABIEUgJXBBqXASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHJh
bmsgc2VydmljZSBjb25maWcsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdF9udW19L2xv
Y2F0aW9ucy97bG9jYXRpb259L3JhbmtpbmdDb25maWdzL2RlZmF1bHRfcmFua2luZ19jb25m
aWdgLgoKDAoFBAECAAUSA1ICCAoMCgUEAQIAARIDUgkXCgwKBQQBAgADEgNSGhsKDQoFBAEC
AAgSBFIcVwMKDwoIBAECAAicCAASA1MEKgoPCgcEAQIACJ8IEgRUBFYFCuUBCgQEAQIBEgNf
AhMa1wEgVGhlIGlkZW50aWZpZXIgb2YgdGhlIG1vZGVsIHRvIHVzZS4gSXQgaXMgb25lIG9m
OgoKICogYHNlbWFudGljLXJhbmtlci01MTJAbGF0ZXN0YDogU2VtYW50aWMgcmFua2luZyBt
b2RlbCB3aXRoIG1heGltdW0gaW5wdXQKIHRva2VuIHNpemUgNTEyLgoKIEl0IGlzIHNldCB0
byBgc2VtYW50aWMtcmFua2VyLTUxMkBsYXRlc3RgIGJ5IGRlZmF1bHQgaWYgdW5zcGVjaWZp
ZWQuCgoMCgUEAQIBBRIDXwIICgwKBQQBAgEBEgNfCQ4KDAoFBAECAQMSA18REgpuCgQEAQIC
EgNjAhIaYSBUaGUgbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB0aGlzIGlzIHVu
c2V0IG9yIG5vIGJpZ2dlciB0aGFuIHplcm8sCiByZXR1cm5zIGFsbCByZXN1bHRzLgoKDAoF
BAECAgUSA2MCBwoMCgUEAQICARIDYwgNCgwKBQQBAgIDEgNjEBEKIAoEBAECAxIDZgITGhMg
VGhlIHF1ZXJ5IHRvIHVzZS4KCgwKBQQBAgMFEgNmAggKDAoFBAECAwESA2YJDgoMCgUEAQID
AxIDZhESCjMKBAQBAgQSA2kCThomIFJlcXVpcmVkLiBBIGxpc3Qgb2YgcmVjb3JkcyB0byBy
YW5rLgoKDAoFBAECBAQSA2kCCgoMCgUEAQIEBhIDaQsYCgwKBQQBAgQBEgNpGSAKDAoFBAEC
BAMSA2kjJAoMCgUEAQIECBIDaSVNCg8KCAQBAgQInAgAEgNpJkwKkAEKBAQBAgUSA20CLRqC
ASBJZiB0cnVlLCB0aGUgcmVzcG9uc2Ugd2lsbCBjb250YWluIG9ubHkgcmVjb3JkIElEIGFu
ZCBzY29yZS4gQnkgZGVmYXVsdCwgaXQKIGlzIGZhbHNlLCB0aGUgcmVzcG9uc2Ugd2lsbCBj
b250YWluIHJlY29yZCBkZXRhaWxzLgoKDAoFBAECBQUSA20CBgoMCgUEAQIFARIDbQcoCgwK
BQQBAgUDEgNtKywK7AYKBAQBAgYSBIABAiYa3QYgVGhlIHVzZXIgbGFiZWxzIGFwcGxpZWQg
dG8gYSByZXNvdXJjZSBtdXN0IG1lZXQgdGhlIGZvbGxvd2luZyByZXF1aXJlbWVudHM6Cgog
KiBFYWNoIHJlc291cmNlIGNhbiBoYXZlIG11bHRpcGxlIGxhYmVscywgdXAgdG8gYSBtYXhp
bXVtIG9mIDY0LgogKiBFYWNoIGxhYmVsIG11c3QgYmUgYSBrZXktdmFsdWUgcGFpci4KICog
S2V5cyBoYXZlIGEgbWluaW11bSBsZW5ndGggb2YgMSBjaGFyYWN0ZXIgYW5kIGEgbWF4aW11
bSBsZW5ndGggb2YgNjMKICAgY2hhcmFjdGVycyBhbmQgY2Fubm90IGJlIGVtcHR5LiBWYWx1
ZXMgY2FuIGJlIGVtcHR5IGFuZCBoYXZlIGEgbWF4aW11bQogICBsZW5ndGggb2YgNjMgY2hh
cmFjdGVycy4KICogS2V5cyBhbmQgdmFsdWVzIGNhbiBjb250YWluIG9ubHkgbG93ZXJjYXNl
IGxldHRlcnMsIG51bWVyaWMgY2hhcmFjdGVycywKICAgdW5kZXJzY29yZXMsIGFuZCBkYXNo
ZXMuIEFsbCBjaGFyYWN0ZXJzIG11c3QgdXNlIFVURi04IGVuY29kaW5nLCBhbmQKICAgaW50
ZXJuYXRpb25hbCBjaGFyYWN0ZXJzIGFyZSBhbGxvd2VkLgogKiBUaGUga2V5IHBvcnRpb24g
b2YgYSBsYWJlbCBtdXN0IGJlIHVuaXF1ZS4gSG93ZXZlciwgeW91IGNhbiB1c2UgdGhlIHNh
bWUKICAga2V5IHdpdGggbXVsdGlwbGUgcmVzb3VyY2VzLgogKiBLZXlzIG11c3Qgc3RhcnQg
d2l0aCBhIGxvd2VyY2FzZSBsZXR0ZXIgb3IgaW50ZXJuYXRpb25hbCBjaGFyYWN0ZXIuCgog
U2VlIFtHb29nbGUgQ2xvdWQKIERvY3VtZW50XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
cmVzb3VyY2UtbWFuYWdlci9kb2NzL2NyZWF0aW5nLW1hbmFnaW5nLWxhYmVscyNyZXF1aXJl
bWVudHMpCiBmb3IgbW9yZSBkZXRhaWxzLgoKDQoFBAECBgYSBIABAhUKDQoFBAECBgESBIAB
FiEKDQoFBAECBgMSBIABJCUKdwoCBAISBoYBAIkBARppIFJlc3BvbnNlIG1lc3NhZ2UgZm9y
CiBbUmFua1NlcnZpY2UuUmFua11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuUmFua1NlcnZpY2UuUmFua10KIG1ldGhvZC4KCgsKAwQCARIEhgEIFAo9CgQEAgIAEgSI
AQIlGi8gQSBsaXN0IG9mIHJlY29yZHMgc29ydGVkIGJ5IGRlc2NlbmRpbmcgc2NvcmUuCgoN
CgUEAgIABBIEiAECCgoNCgUEAgIABhIEiAELGAoNCgUEAgIAARIEiAEZIAoNCgUEAgIAAxIE
iAEjJGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord ===
    # Fields for RankingRecord
    # Field: id Type: 9 ()
    # Field: title Type: 9 ()
    # Field: content Type: 9 ()
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest ===
    # Fields for RankRequest
    # Field: ranking_config Type: 9 ()
    # Field: model Type: 9 ()
    # Field: top_n Type: 5 ()
    # Field: query Type: 9 ()
    # Field: records Type: 11 (.google.cloud.discoveryengine.v1beta.RankingRecord)
    # Field: ignore_record_details_in_response Type: 8 ()
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1beta.RankRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse ===
    # Fields for RankResponse
    # Field: records Type: 11 (.google.cloud.discoveryengine.v1beta.RankingRecord)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::RankService::RankServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::RankService::RankServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::RankService::RankServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.RankService',
        method         => 'Rank',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::RankService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/rank_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::RankService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord->new({
        id => $id,
        title => $title,
        content => $content,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/rank_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord

Record message for
[RankService.Rank][google.cloud.discoveryengine.v1beta.RankService.Rank]
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
[title][google.cloud.discoveryengine.v1beta.RankingRecord.title] or
[content][google.cloud.discoveryengine.v1beta.RankingRecord.content] should
be set otherwise an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

The content of the record. Empty by default.
At least one of
[title][google.cloud.discoveryengine.v1beta.RankingRecord.title] or
[content][google.cloud.discoveryengine.v1beta.RankingRecord.content] should
be set otherwise an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

The score of this record based on the given query and selected model.
The score will be rounded to 4 decimal places. If the score is close to 0,
it will be rounded to 0.00001 to avoid returning unset.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest

Request message for
[RankService.Rank][google.cloud.discoveryengine.v1beta.RankService.Rank]
method.

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord>)

Required. A list of records to rank.

=item * C<< $msg->ignore_record_details_in_response() >> / C<< $msg->ignore_record_details_in_response($value) >>

Type: C<Bool>

If true, the response will contain only record ID and score. By default, it
is false, the response will contain record details.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest::UserLabelsEntry>)

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

=head2 Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse

Response message for
[RankService.Rank][google.cloud.discoveryengine.v1beta.RankService.Rank]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->records() >> / C<< $msg->records($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord>)

A list of records sorted by descending score.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::RankService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
