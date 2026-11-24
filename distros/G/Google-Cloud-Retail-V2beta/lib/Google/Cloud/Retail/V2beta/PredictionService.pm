package Google::Cloud::Retail::V2beta::PredictionService;

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
    eval { require Google::Cloud::Retail::V2beta::UserEvent };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9wcmVkaWN0aW9uX3NlcnZpY2UucHJvdG8S
Gmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxorZ29vZ2xlL2Nsb3VkL3JldGFp
bC92MmJldGEvdXNlcl9ldmVudC5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90
byKpBAoOUHJlZGljdFJlcXVlc3QSIQoJcGxhY2VtZW50GAEgASgJQgPgQQJSCXBsYWNlbWVu
dBJJCgp1c2VyX2V2ZW50GAIgASgLMiUuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuVXNl
ckV2ZW50QgPgQQJSCXVzZXJFdmVudBIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEiEK
CnBhZ2VfdG9rZW4YBCABKAlCAhgBUglwYWdlVG9rZW4SFgoGZmlsdGVyGAUgASgJUgZmaWx0
ZXISIwoNdmFsaWRhdGVfb25seRgGIAEoCFIMdmFsaWRhdGVPbmx5Ek4KBnBhcmFtcxgHIAMo
CzI2Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlByZWRpY3RSZXF1ZXN0LlBhcmFtc0Vu
dHJ5UgZwYXJhbXMSTgoGbGFiZWxzGAggAygLMjYuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuUHJlZGljdFJlcXVlc3QuTGFiZWxzRW50cnlSBmxhYmVscxpRCgtQYXJhbXNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIsCgV2YWx1ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1
ZVIFdmFsdWU6AjgBGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgJUgV2YWx1ZToCOAEivgMKD1ByZWRpY3RSZXNwb25zZRJWCgdyZXN1bHRzGAEgAygL
MjwuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHJlZGljdFJlc3BvbnNlLlByZWRpY3Rp
b25SZXN1bHRSB3Jlc3VsdHMSKwoRYXR0cmlidXRpb25fdG9rZW4YAiABKAlSEGF0dHJpYnV0
aW9uVG9rZW4SHwoLbWlzc2luZ19pZHMYAyADKAlSCm1pc3NpbmdJZHMSIwoNdmFsaWRhdGVf
b25seRgEIAEoCFIMdmFsaWRhdGVPbmx5Gt8BChBQcmVkaWN0aW9uUmVzdWx0Eg4KAmlkGAEg
ASgJUgJpZBJmCghtZXRhZGF0YRgCIAMoCzJKLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LlByZWRpY3RSZXNwb25zZS5QcmVkaWN0aW9uUmVzdWx0Lk1ldGFkYXRhRW50cnlSCG1ldGFk
YXRhGlMKDU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLAoFdmFsdWUYAiABKAsy
Fi5nb29nbGUucHJvdG9idWYuVmFsdWVSBXZhbHVlOgI4ATLxAgoRUHJlZGljdGlvblNlcnZp
Y2USkAIKB1ByZWRpY3QSKi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5QcmVkaWN0UmVx
dWVzdBorLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlByZWRpY3RSZXNwb25zZSKrAYLT
5JMCpAEiSi92MmJldGEve3BsYWNlbWVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFs
b2dzLyovcGxhY2VtZW50cy8qfTpwcmVkaWN0OgEqWlMiTi92MmJldGEve3BsYWNlbWVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn06cHJl
ZGljdDoBKhpJykEVcmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULVAQoeY29tLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhQhZQcmVkaWN0aW9uU2VydmljZVByb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20v
Z28vcmV0YWlsL2FwaXYyYmV0YS9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCGkdvb2ds
ZS5DbG91ZC5SZXRhaWwuVjJCZXRhygIaR29vZ2xlXENsb3VkXFJldGFpbFxWMmJldGHqAh1H
b29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYmV0YUrgRwoHEgUOAOEBAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADUKCQoCAwUSAxcAJgoICgEIEgMZADcK
CQoCCCUSAxkANwoICgEIEgMaAE0KCQoCCAsSAxoATQoICgEIEgMbACIKCQoCCAoSAxsAIgoI
CgEIEgMcADcKCQoCCAgSAxwANwoICgEIEgMdADcKCQoCCAESAx0ANwoICgEIEgMeACQKCQoC
CCQSAx4AJAoICgEIEgMfADcKCQoCCCkSAx8ANwoICgEIEgMgADYKCQoCCC0SAyAANgo7CgIG
ABIEIwAzARovIFNlcnZpY2UgZm9yIG1ha2luZyByZWNvbW1lbmRhdGlvbiBwcmVkaWN0aW9u
LgoKCgoDBgABEgMjCBkKCgoDBgADEgMkAj0KDAoFBgADmQgSAyQCPQoLCgMGAAMSBCUCJjcK
DQoFBgADmggSBCUCJjcKMgoEBgACABIEKQIyAxokIE1ha2VzIGEgcmVjb21tZW5kYXRpb24g
cHJlZGljdGlvbi4KCgwKBQYAAgABEgMpBg0KDAoFBgACAAISAykOHAoMCgUGAAIAAxIDKSc2
Cg0KBQYAAgAEEgQqBDEGChEKCQYAAgAEsMq8IhIEKgQxBgoyCgIEABIFNgC+AQEaJSBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIFByZWRpY3QgbWV0aG9kLgoKCgoDBAABEgM2CBYK6AUKBAQAAgAS
A0UCQBraBSBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBmb3JtYXQ6CiBg
e3BsYWNlbWVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVmYXVs
dF9jYXRhbG9nL3NlcnZpbmdDb25maWdzLyp9YAogb3IKIGB7cGxhY2VtZW50PXByb2plY3Rz
LyovbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFsb2cvcGxhY2VtZW50
cy8qfWAuCiBXZSByZWNvbW1lbmQgdXNpbmcgdGhlIGBzZXJ2aW5nQ29uZmlnc2AgcmVzb3Vy
Y2UuIGBwbGFjZW1lbnRzYCBpcyBhIGxlZ2FjeQogcmVzb3VyY2UuCiBUaGUgSUQgb2YgdGhl
IFJlY29tbWVuZGF0aW9ucyBBSSBzZXJ2aW5nIGNvbmZpZyBvciBwbGFjZW1lbnQuCiBCZWZv
cmUgeW91IGNhbiByZXF1ZXN0IHByZWRpY3Rpb25zIGZyb20geW91ciBtb2RlbCwgeW91IG11
c3QgY3JlYXRlIGF0CiBsZWFzdCBvbmUgc2VydmluZyBjb25maWcgb3IgcGxhY2VtZW50IGZv
ciBpdC4gRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQogW01hbmFnZSBzZXJ2aW5nIGNvbmZp
Z3NdCiAoaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9kb2NzL21hbmFnZS1jb25m
aWdzKS4KCiBUaGUgZnVsbCBsaXN0IG9mIGF2YWlsYWJsZSBzZXJ2aW5nIGNvbmZpZ3MgY2Fu
IGJlIHNlZW4gYXQKIGh0dHBzOi8vY29uc29sZS5jbG91ZC5nb29nbGUuY29tL2FpL3JldGFp
bC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFsb2cvY29uZmlncwoKDAoFBAACAAUSA0UCCAoMCgUE
AAIAARIDRQkSCgwKBQQAAgADEgNFFRYKDAoFBAACAAgSA0UXPwoPCggEAAIACJwIABIDRRg+
CpgGCgQEAAIBEgNVAkQaigYgUmVxdWlyZWQuIENvbnRleHQgYWJvdXQgdGhlIHVzZXIsIHdo
YXQgdGhleSBhcmUgbG9va2luZyBhdCBhbmQgd2hhdCBhY3Rpb24KIHRoZXkgdG9vayB0byB0
cmlnZ2VyIHRoZSBwcmVkaWN0IHJlcXVlc3QuIE5vdGUgdGhhdCB0aGlzIHVzZXIgZXZlbnQg
ZGV0YWlsCiB3b24ndCBiZSBpbmdlc3RlZCB0byB1c2VyRXZlbnQgbG9ncy4gVGh1cywgYSBz
ZXBhcmF0ZSB1c2VyRXZlbnQgd3JpdGUKIHJlcXVlc3QgaXMgcmVxdWlyZWQgZm9yIGV2ZW50
IGxvZ2dpbmcuCgogRG9uJ3Qgc2V0CiBbVXNlckV2ZW50LnZpc2l0b3JfaWRdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLlVzZXJFdmVudC52aXNpdG9yX2lkXSBvcgogW1VzZXJJbmZv
LnVzZXJfaWRdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVzZXJJbmZvLnVzZXJfaWRd
IHRvIHRoZSBzYW1lCiBmaXhlZCBJRCBmb3IgZGlmZmVyZW50IHVzZXJzLiBJZiB5b3UgYXJl
IHRyeWluZyB0byByZWNlaXZlIG5vbi1wZXJzb25hbGl6ZWQKIHJlY29tbWVuZGF0aW9ucyAo
bm90IHJlY29tbWVuZGVkOyB0aGlzIGNhbiBuZWdhdGl2ZWx5IGltcGFjdCBtb2RlbAogcGVy
Zm9ybWFuY2UpLCBpbnN0ZWFkIHNldAogW1VzZXJFdmVudC52aXNpdG9yX2lkXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YS5Vc2VyRXZlbnQudmlzaXRvcl9pZF0gdG8KIGEgcmFuZG9t
IHVuaXF1ZSBJRCBhbmQgbGVhdmUKIFtVc2VySW5mby51c2VyX2lkXVtnb29nbGUuY2xvdWQu
cmV0YWlsLnYyYmV0YS5Vc2VySW5mby51c2VyX2lkXSB1bnNldC4KCgwKBQQAAgEGEgNVAgsK
DAoFBAACAQESA1UMFgoMCgUEAAIBAxIDVRkaCgwKBQQAAgEIEgNVG0MKDwoIBAACAQicCAAS
A1UcQgr3AQoEBAACAhIDWwIWGukBIE1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0
dXJuLiBTZXQgdGhpcyBwcm9wZXJ0eSB0byB0aGUgbnVtYmVyIG9mCiBwcmVkaWN0aW9uIHJl
c3VsdHMgbmVlZGVkLiBJZiB6ZXJvLCB0aGUgc2VydmljZSB3aWxsIGNob29zZSBhIHJlYXNv
bmFibGUKIGRlZmF1bHQuIFRoZSBtYXhpbXVtIGFsbG93ZWQgdmFsdWUgaXMgMTAwLiBWYWx1
ZXMgYWJvdmUgMTAwIHdpbGwgYmUgY29lcmNlZAogdG8gMTAwLgoKDAoFBAACAgUSA1sCBwoM
CgUEAAICARIDWwgRCgwKBQQAAgIDEgNbFBUKNgoEBAACAxIDXgIsGikgVGhpcyBmaWVsZCBp
cyBub3QgdXNlZDsgbGVhdmUgaXQgdW5zZXQuCgoMCgUEAAIDBRIDXgIICgwKBQQAAgMBEgNe
CRMKDAoFBAACAwMSA14WFwoMCgUEAAIDCBIDXhgrCg0KBgQAAgMIAxIDXhkqCr8NCgQEAAIE
EgSHAQIUGrANIEZpbHRlciBmb3IgcmVzdHJpY3RpbmcgcHJlZGljdGlvbiByZXN1bHRzIHdp
dGggYSBsZW5ndGggbGltaXQgb2YgNSwwMDAKIGNoYXJhY3RlcnMuIEFjY2VwdHMgdmFsdWVz
IGZvciB0YWdzIGFuZCB0aGUgYGZpbHRlck91dE9mU3RvY2tJdGVtc2AgZmxhZy4KCiAgKiBU
YWcgZXhwcmVzc2lvbnMuIFJlc3RyaWN0cyBwcmVkaWN0aW9ucyB0byBwcm9kdWN0cyB0aGF0
IG1hdGNoIGFsbCBvZiB0aGUKICAgIHNwZWNpZmllZCB0YWdzLiBCb29sZWFuIG9wZXJhdG9y
cyBgT1JgIGFuZCBgTk9UYCBhcmUgc3VwcG9ydGVkIGlmIHRoZQogICAgZXhwcmVzc2lvbiBp
cyBlbmNsb3NlZCBpbiBwYXJlbnRoZXNlcywgYW5kIG11c3QgYmUgc2VwYXJhdGVkIGZyb20g
dGhlCiAgICB0YWcgdmFsdWVzIGJ5IGEgc3BhY2UuIGAtInRhZ0EiYCBpcyBhbHNvIHN1cHBv
cnRlZCBhbmQgaXMgZXF1aXZhbGVudCB0bwogICAgYE5PVCAidGFnQSJgLiBUYWcgdmFsdWVz
IG11c3QgYmUgZG91YmxlIHF1b3RlZCBVVEYtOCBlbmNvZGVkIHN0cmluZ3MKICAgIHdpdGgg
YSBzaXplIGxpbWl0IG9mIDEsMDAwIGNoYXJhY3RlcnMuCgogICAgTm90ZTogIlJlY2VudGx5
IHZpZXdlZCIgbW9kZWxzIGRvbid0IHN1cHBvcnQgdGFnIGZpbHRlcmluZyBhdCB0aGUKICAg
IG1vbWVudC4KCiAgKiBmaWx0ZXJPdXRPZlN0b2NrSXRlbXMuIFJlc3RyaWN0cyBwcmVkaWN0
aW9ucyB0byBwcm9kdWN0cyB0aGF0IGRvIG5vdAogIGhhdmUgYQogICAgc3RvY2tTdGF0ZSB2
YWx1ZSBvZiBPVVRfT0ZfU1RPQ0suCgogRXhhbXBsZXM6CgogICogdGFnPSgiUmVkIiBPUiAi
Qmx1ZSIpIHRhZz0iTmV3LUFycml2YWwiIHRhZz0oTk9UICJwcm9tb3Rpb25hbCIpCiAgKiBm
aWx0ZXJPdXRPZlN0b2NrSXRlbXMgIHRhZz0oLSJwcm9tb3Rpb25hbCIpCiAgKiBmaWx0ZXJP
dXRPZlN0b2NrSXRlbXMKCiBJZiB5b3VyIGZpbHRlciBibG9ja3MgYWxsIHByZWRpY3Rpb24g
cmVzdWx0cywgdGhlIEFQSSB3aWxsIHJldHVybiAqbm8qCiByZXN1bHRzLiBJZiBpbnN0ZWFk
IHlvdSB3YW50IGVtcHR5IHJlc3VsdCBzZXRzIHRvIHJldHVybiBnZW5lcmljCiAodW5maWx0
ZXJlZCkgcG9wdWxhciBwcm9kdWN0cywgc2V0IGBzdHJpY3RGaWx0ZXJpbmdgIHRvIEZhbHNl
IGluCiBgUHJlZGljdFJlcXVlc3QucGFyYW1zYC4gTm90ZSB0aGF0IHRoZSBBUEkgd2lsbCBu
ZXZlciByZXR1cm4gaXRlbXMgd2l0aAogc3RvcmFnZVN0YXR1cyBvZiAiRVhQSVJFRCIgb3Ig
IkRFTEVURUQiIHJlZ2FyZGxlc3Mgb2YgZmlsdGVyIGNob2ljZXMuCgogSWYgYGZpbHRlclN5
bnRheFYyYCBpcyBzZXQgdG8gdHJ1ZSB1bmRlciB0aGUgYHBhcmFtc2AgZmllbGQsIHRoZW4K
IGF0dHJpYnV0ZS1iYXNlZCBleHByZXNzaW9ucyBhcmUgZXhwZWN0ZWQgaW5zdGVhZCBvZiB0
aGUgYWJvdmUgZGVzY3JpYmVkCiB0YWctYmFzZWQgc3ludGF4LiBFeGFtcGxlczoKCiAgKiAo
Y29sb3JzOiBBTlkoIlJlZCIsICJCbHVlIikpIEFORCBOT1QgKGNhdGVnb3JpZXM6IEFOWSgi
UGhvbmVzIikpCiAgKiAoYXZhaWxhYmlsaXR5OiBBTlkoIklOX1NUT0NLIikpIEFORAogICAg
KGNvbG9yczogQU5ZKCJSZWQiKSBPUiBjYXRlZ29yaWVzOiBBTlkoIlBob25lcyIpKQoKIEZv
ciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtGaWx0ZXIgcmVjb21tZW5kYXRpb25zXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RvY3MvZmlsdGVyLXJlY3MpLgoKDQoFBAAC
BAUSBIcBAggKDQoFBAACBAESBIcBCQ8KDQoFBAACBAMSBIcBEhMK+QEKBAQAAgUSBI0BAhka
6gEgVXNlIHZhbGlkYXRlIG9ubHkgbW9kZSBmb3IgdGhpcyBwcmVkaWN0aW9uIHF1ZXJ5LiBJ
ZiBzZXQgdG8gdHJ1ZSwgYQogZHVtbXkgbW9kZWwgd2lsbCBiZSB1c2VkIHRoYXQgcmV0dXJu
cyBhcmJpdHJhcnkgcHJvZHVjdHMuCiBOb3RlIHRoYXQgdGhlIHZhbGlkYXRlIG9ubHkgbW9k
ZSBzaG91bGQgb25seSBiZSB1c2VkIGZvciB0ZXN0aW5nIHRoZSBBUEksCiBvciBpZiB0aGUg
bW9kZWwgaXMgbm90IHJlYWR5LgoKDQoFBAACBQUSBI0BAgYKDQoFBAACBQESBI0BBxQKDQoF
BAACBQMSBI0BFxgK4AsKBAQAAgYSBKoBAjAa0QsgQWRkaXRpb25hbCBkb21haW4gc3BlY2lm
aWMgcGFyYW1ldGVycyBmb3IgdGhlIHByZWRpY3Rpb25zLgoKIEFsbG93ZWQgdmFsdWVzOgoK
ICogYHJldHVyblByb2R1Y3RgOiBCb29sZWFuLiBJZiBzZXQgdG8gdHJ1ZSwgdGhlIGFzc29j
aWF0ZWQgcHJvZHVjdAogICAgb2JqZWN0IHdpbGwgYmUgcmV0dXJuZWQgaW4gdGhlIGByZXN1
bHRzLm1ldGFkYXRhYCBmaWVsZCBpbiB0aGUKICAgIHByZWRpY3Rpb24gcmVzcG9uc2UuCiAq
IGByZXR1cm5TY29yZWA6IEJvb2xlYW4uIElmIHNldCB0byB0cnVlLCB0aGUgcHJlZGljdGlv
biAnc2NvcmUnCiAgICBjb3JyZXNwb25kaW5nIHRvIGVhY2ggcmV0dXJuZWQgcHJvZHVjdCB3
aWxsIGJlIHNldCBpbiB0aGUKICAgIGByZXN1bHRzLm1ldGFkYXRhYCBmaWVsZCBpbiB0aGUg
cHJlZGljdGlvbiByZXNwb25zZS4gVGhlIGdpdmVuCiAgICAnc2NvcmUnIGluZGljYXRlcyB0
aGUgcHJvYmFiaWxpdHkgb2YgYSBwcm9kdWN0IGJlaW5nIGNsaWNrZWQvcHVyY2hhc2VkCiAg
ICBnaXZlbiB0aGUgdXNlcidzIGNvbnRleHQgYW5kIGhpc3RvcnkuCiAqIGBzdHJpY3RGaWx0
ZXJpbmdgOiBCb29sZWFuLiBUcnVlIGJ5IGRlZmF1bHQuIElmIHNldCB0byBmYWxzZSwgdGhl
IHNlcnZpY2UKICAgIHdpbGwgcmV0dXJuIGdlbmVyaWMgKHVuZmlsdGVyZWQpIHBvcHVsYXIg
cHJvZHVjdHMgaW5zdGVhZCBvZiBlbXB0eSBpZgogICAgeW91ciBmaWx0ZXIgYmxvY2tzIGFs
bCBwcmVkaWN0aW9uIHJlc3VsdHMuCiAqIGBwcmljZVJlcmFua0xldmVsYDogU3RyaW5nLiBE
ZWZhdWx0IGVtcHR5LiBJZiBzZXQgdG8gYmUgbm9uLWVtcHR5LCB0aGVuCiAgICBpdCBuZWVk
cyB0byBiZSBvbmUgb2Ygeyduby1wcmljZS1yZXJhbmtpbmcnLCAnbG93LXByaWNlLXJlcmFu
a2luZycsCiAgICAnbWVkaXVtLXByaWNlLXJlcmFua2luZycsICdoaWdoLXByaWNlLXJlcmFu
a2luZyd9LiBUaGlzIGdpdmVzCiAgICByZXF1ZXN0LWxldmVsIGNvbnRyb2wgYW5kIGFkanVz
dHMgcHJlZGljdGlvbiByZXN1bHRzIGJhc2VkIG9uIHByb2R1Y3QKICAgIHByaWNlLgogKiBg
ZGl2ZXJzaXR5TGV2ZWxgOiBTdHJpbmcuIERlZmF1bHQgZW1wdHkuIElmIHNldCB0byBiZSBu
b24tZW1wdHksIHRoZW4KICAgIGl0IG5lZWRzIHRvIGJlIG9uZSBvZiB7J25vLWRpdmVyc2l0
eScsICdsb3ctZGl2ZXJzaXR5JywKICAgICdtZWRpdW0tZGl2ZXJzaXR5JywgJ2hpZ2gtZGl2
ZXJzaXR5JywgJ2F1dG8tZGl2ZXJzaXR5J30uIFRoaXMgZ2l2ZXMKICAgIHJlcXVlc3QtbGV2
ZWwgY29udHJvbCBhbmQgYWRqdXN0cyBwcmVkaWN0aW9uIHJlc3VsdHMgYmFzZWQgb24gcHJv
ZHVjdAogICAgY2F0ZWdvcnkuCiAqIGBmaWx0ZXJTeW50YXhWMmA6IEJvb2xlYW4uIEZhbHNl
IGJ5IGRlZmF1bHQuIElmIHNldCB0byB0cnVlLCB0aGUgYGZpbHRlcmAKICAgZmllbGQgaXMg
aW50ZXJwcmV0ZXRlZCBhY2NvcmRpbmcgdG8gdGhlIG5ldywgYXR0cmlidXRlLWJhc2VkIHN5
bnRheC4KCg0KBQQAAgYGEgSqAQIkCg0KBQQAAgYBEgSqASUrCg0KBQQAAgYDEgSqAS4vCucG
CgQEAAIHEgS9AQIhGtgGIFRoZSBsYWJlbHMgYXBwbGllZCB0byBhIHJlc291cmNlIG11c3Qg
bWVldCB0aGUgZm9sbG93aW5nIHJlcXVpcmVtZW50czoKCiAqIEVhY2ggcmVzb3VyY2UgY2Fu
IGhhdmUgbXVsdGlwbGUgbGFiZWxzLCB1cCB0byBhIG1heGltdW0gb2YgNjQuCiAqIEVhY2gg
bGFiZWwgbXVzdCBiZSBhIGtleS12YWx1ZSBwYWlyLgogKiBLZXlzIGhhdmUgYSBtaW5pbXVt
IGxlbmd0aCBvZiAxIGNoYXJhY3RlciBhbmQgYSBtYXhpbXVtIGxlbmd0aCBvZiA2MwogICBj
aGFyYWN0ZXJzIGFuZCBjYW5ub3QgYmUgZW1wdHkuIFZhbHVlcyBjYW4gYmUgZW1wdHkgYW5k
IGhhdmUgYSBtYXhpbXVtCiAgIGxlbmd0aCBvZiA2MyBjaGFyYWN0ZXJzLgogKiBLZXlzIGFu
ZCB2YWx1ZXMgY2FuIGNvbnRhaW4gb25seSBsb3dlcmNhc2UgbGV0dGVycywgbnVtZXJpYyBj
aGFyYWN0ZXJzLAogICB1bmRlcnNjb3JlcywgYW5kIGRhc2hlcy4gQWxsIGNoYXJhY3RlcnMg
bXVzdCB1c2UgVVRGLTggZW5jb2RpbmcsIGFuZAogICBpbnRlcm5hdGlvbmFsIGNoYXJhY3Rl
cnMgYXJlIGFsbG93ZWQuCiAqIFRoZSBrZXkgcG9ydGlvbiBvZiBhIGxhYmVsIG11c3QgYmUg
dW5pcXVlLiBIb3dldmVyLCB5b3UgY2FuIHVzZSB0aGUgc2FtZQogICBrZXkgd2l0aCBtdWx0
aXBsZSByZXNvdXJjZXMuCiAqIEtleXMgbXVzdCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxl
dHRlciBvciBpbnRlcm5hdGlvbmFsIGNoYXJhY3Rlci4KCiBTZWUgW0dvb2dsZSBDbG91ZAog
RG9jdW1lbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2Rv
Y3MvY3JlYXRpbmctbWFuYWdpbmctbGFiZWxzI3JlcXVpcmVtZW50cykKIGZvciBtb3JlIGRl
dGFpbHMuCgoNCgUEAAIHBhIEvQECFQoNCgUEAAIHARIEvQEWHAoNCgUEAAIHAxIEvQEfIAo0
CgIEARIGwQEA4QEBGiYgUmVzcG9uc2UgbWVzc2FnZSBmb3IgcHJlZGljdCBtZXRob2QuCgoL
CgMEAQESBMEBCBcKVAoEBAEDABIGwwEC0AEDGkQgUHJlZGljdGlvblJlc3VsdCByZXByZXNl
bnRzIHRoZSByZWNvbW1lbmRhdGlvbiBwcmVkaWN0aW9uIHJlc3VsdHMuCgoNCgUEAQMAARIE
wwEKGgovCgYEAQMAAgASBMUBBBIaHyBJRCBvZiB0aGUgcmVjb21tZW5kZWQgcHJvZHVjdAoK
DwoHBAEDAAIABRIExQEECgoPCgcEAQMAAgABEgTFAQsNCg8KBwQBAwACAAMSBMUBEBEKvwIK
BgQBAwACARIEzwEENBquAiBBZGRpdGlvbmFsIHByb2R1Y3QgbWV0YWRhdGEgLyBhbm5vdGF0
aW9ucy4KCiBQb3NzaWJsZSB2YWx1ZXM6CgogKiBgcHJvZHVjdGA6IEpTT04gcmVwcmVzZW50
YXRpb24gb2YgdGhlIHByb2R1Y3QuIElzIHNldCBpZgogICBgcmV0dXJuUHJvZHVjdGAgaXMg
c2V0IHRvIHRydWUgaW4gYFByZWRpY3RSZXF1ZXN0LnBhcmFtc2AuCiAqIGBzY29yZWA6IFBy
ZWRpY3Rpb24gc2NvcmUgaW4gZG91YmxlIHZhbHVlLiBJcyBzZXQgaWYKICAgYHJldHVyblNj
b3JlYCBpcyBzZXQgdG8gdHJ1ZSBpbiBgUHJlZGljdFJlcXVlc3QucGFyYW1zYC4KCg8KBwQB
AwACAQYSBM8BBCYKDwoHBAEDAAIBARIEzwEnLwoPCgcEAQMAAgEDEgTPATIzCoABCgQEAQIA
EgTUAQIoGnIgQSBsaXN0IG9mIHJlY29tbWVuZGVkIHByb2R1Y3RzLiBUaGUgb3JkZXIgcmVw
cmVzZW50cyB0aGUgcmFua2luZyAoZnJvbSB0aGUKIG1vc3QgcmVsZXZhbnQgcHJvZHVjdCB0
byB0aGUgbGVhc3QpLgoKDQoFBAECAAQSBNQBAgoKDQoFBAECAAYSBNQBCxsKDQoFBAECAAES
BNQBHCMKDQoFBAECAAMSBNQBJicK8QEKBAQBAgESBNoBAh8a4gEgQSB1bmlxdWUgYXR0cmli
dXRpb24gdG9rZW4uIFRoaXMgc2hvdWxkIGJlIGluY2x1ZGVkIGluIHRoZQogW1VzZXJFdmVu
dF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuVXNlckV2ZW50XSBsb2dzIHJlc3VsdGlu
ZyBmcm9tIHRoaXMKIHJlY29tbWVuZGF0aW9uLCB3aGljaCBlbmFibGVzIGFjY3VyYXRlIGF0
dHJpYnV0aW9uIG9mIHJlY29tbWVuZGF0aW9uIG1vZGVsCiBwZXJmb3JtYW5jZS4KCg0KBQQB
AgEFEgTaAQIICg0KBQQBAgEBEgTaAQkaCg0KBQQBAgEDEgTaAR0eClQKBAQBAgISBN0BAiIa
RiBJRHMgb2YgcHJvZHVjdHMgaW4gdGhlIHJlcXVlc3QgdGhhdCB3ZXJlIG1pc3NpbmcgZnJv
bSB0aGUgaW52ZW50b3J5LgoKDQoFBAECAgQSBN0BAgoKDQoFBAECAgUSBN0BCxEKDQoFBAEC
AgESBN0BEh0KDQoFBAECAgMSBN0BICEKSQoEBAECAxIE4AECGRo7IFRydWUgaWYgdGhlIHZh
bGlkYXRlT25seSBwcm9wZXJ0eSB3YXMgc2V0IGluIHRoZSByZXF1ZXN0LgoKDQoFBAECAwUS
BOABAgYKDQoFBAECAwESBOABBxQKDQoFBAECAwMSBOABFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: placement Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.retail.v2beta.UserEvent)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: params Type: 11 (.google.cloud.retail.v2beta.PredictRequest.ParamsEntry)
    # Field: labels Type: 11 (.google.cloud.retail.v2beta.PredictRequest.LabelsEntry)

# === Message: Google::Cloud::Retail::V2beta::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: results Type: 11 (.google.cloud.retail.v2beta.PredictResponse.PredictionResult)
    # Field: attribution_token Type: 9 ()
    # Field: missing_ids Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Cloud::Retail::V2beta::PredictionService::PredictionServiceClient ===
package Google::Cloud::Retail::V2beta::PredictionService::PredictionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::PredictionService::PredictionServiceClient

Client stub representing the remote C<PredictionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::PredictionService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/prediction_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::PredictionService;

    my $msg = Google::Cloud::Retail::V2beta::PredictionService::PredictRequest->new({
        placement => $placement,
        user_event => $user_event,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->placement();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::PredictionService::PredictRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/prediction_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::PredictionService::PredictRequest

Request message for Predict method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->placement() >> / C<< $msg->placement($value) >>

Type: C<String>

Required. Full resource name of the format:
`{placement=projects/*/locations/global/catalogs/default_catalog/servingConfigs/*}`
or
`{placement=projects/*/locations/global/catalogs/default_catalog/placements/*}`.
We recommend using the `servingConfigs` resource. `placements` is a legacy
resource.
The ID of the Recommendations AI serving config or placement.
Before you can request predictions from your model, you must create at
least one serving config or placement for it. For more information, see
[Manage serving configs]
(https://cloud.google.com/retail/docs/manage-configs).

The full list of available serving configs can be seen at
https://console.cloud.google.com/ai/retail/catalogs/default_catalog/configs

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent>)

Required. Context about the user, what they are looking at and what action
they took to trigger the predict request. Note that this user event detail
won't be ingested to userEvent logs. Thus, a separate userEvent write
request is required for event logging.

Don't set
[UserEvent.visitor_id][google.cloud.retail.v2beta.UserEvent.visitor_id] or
[UserInfo.user_id][google.cloud.retail.v2beta.UserInfo.user_id] to the same
fixed ID for different users. If you are trying to receive non-personalized
recommendations (not recommended; this can negatively impact model
performance), instead set
[UserEvent.visitor_id][google.cloud.retail.v2beta.UserEvent.visitor_id] to
a random unique ID and leave
[UserInfo.user_id][google.cloud.retail.v2beta.UserInfo.user_id] unset.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of results to return. Set this property to the number of
prediction results needed. If zero, the service will choose a reasonable
default. The maximum allowed value is 100. Values above 100 will be coerced
to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

This field is not used; leave it unset.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter for restricting prediction results with a length limit of 5,000
characters. Accepts values for tags and the `filterOutOfStockItems` flag.

 * Tag expressions. Restricts predictions to products that match all of the
   specified tags. Boolean operators `OR` and `NOT` are supported if the
   expression is enclosed in parentheses, and must be separated from the
   tag values by a space. `-"tagA"` is also supported and is equivalent to
   `NOT "tagA"`. Tag values must be double quoted UTF-8 encoded strings
   with a size limit of 1,000 characters.

   Note: "Recently viewed" models don't support tag filtering at the
   moment.

 * filterOutOfStockItems. Restricts predictions to products that do not
 have a
   stockState value of OUT_OF_STOCK.

Examples:

 * tag=("Red" OR "Blue") tag="New-Arrival" tag=(NOT "promotional")
 * filterOutOfStockItems  tag=(-"promotional")
 * filterOutOfStockItems

If your filter blocks all prediction results, the API will return *no*
results. If instead you want empty result sets to return generic
(unfiltered) popular products, set `strictFiltering` to False in
`PredictRequest.params`. Note that the API will never return items with
storageStatus of "EXPIRED" or "DELETED" regardless of filter choices.

If `filterSyntaxV2` is set to true under the `params` field, then
attribute-based expressions are expected instead of the above described
tag-based syntax. Examples:

 * (colors: ANY("Red", "Blue")) AND NOT (categories: ANY("Phones"))
 * (availability: ANY("IN_STOCK")) AND
   (colors: ANY("Red") OR categories: ANY("Phones"))

For more information, see
[Filter recommendations](https://cloud.google.com/retail/docs/filter-recs).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Use validate only mode for this prediction query. If set to true, a
dummy model will be used that returns arbitrary products.
Note that the validate only mode should only be used for testing the API,
or if the model is not ready.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::ParamsEntry>)

Additional domain specific parameters for the predictions.

Allowed values:

* `returnProduct`: Boolean. If set to true, the associated product
   object will be returned in the `results.metadata` field in the
   prediction response.
* `returnScore`: Boolean. If set to true, the prediction 'score'
   corresponding to each returned product will be set in the
   `results.metadata` field in the prediction response. The given
   'score' indicates the probability of a product being clicked/purchased
   given the user's context and history.
* `strictFiltering`: Boolean. True by default. If set to false, the service
   will return generic (unfiltered) popular products instead of empty if
   your filter blocks all prediction results.
* `priceRerankLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of {'no-price-reranking', 'low-price-reranking',
   'medium-price-reranking', 'high-price-reranking'}. This gives
   request-level control and adjusts prediction results based on product
   price.
* `diversityLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of {'no-diversity', 'low-diversity',
   'medium-diversity', 'high-diversity', 'auto-diversity'}. This gives
   request-level control and adjusts prediction results based on product
   category.
* `filterSyntaxV2`: Boolean. False by default. If set to true, the `filter`
  field is interpreteted according to the new, attribute-based syntax.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::LabelsEntry>)

The labels applied to a resource must meet the following requirements:

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

=head2 Google::Cloud::Retail::V2beta::PredictionService::PredictResponse

Response message for predict method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult>)

A list of recommended products. The order represents the ranking (from the
most relevant product to the least).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique attribution token. This should be included in the
[UserEvent][google.cloud.retail.v2beta.UserEvent] logs resulting from this
recommendation, which enables accurate attribution of recommendation model
performance.

=item * C<< $msg->missing_ids() >> / C<< $msg->missing_ids($value) >>

Type: C<String>

IDs of products in the request that were missing from the inventory.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

True if the validateOnly property was set in the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::PredictionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
