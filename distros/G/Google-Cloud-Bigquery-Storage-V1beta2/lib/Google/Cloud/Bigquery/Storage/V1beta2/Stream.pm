package Google::Cloud::Bigquery::Storage::V1beta2::Stream;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Bigquery::Storage::V1beta2::Arrow };
    eval { require Google::Cloud::Bigquery::Storage::V1beta2::Avro };
    eval { require Google::Cloud::Bigquery::Storage::V1beta2::Table };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEyL3N0cmVhbS5wcm90bxIl
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMhofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoxZ29vZ2xlL2Ns
b3VkL2JpZ3F1ZXJ5L3N0b3JhZ2UvdjFiZXRhMi9hcnJvdy5wcm90bxowZ29vZ2xlL2Nsb3Vk
L2JpZ3F1ZXJ5L3N0b3JhZ2UvdjFiZXRhMi9hdnJvLnByb3RvGjFnb29nbGUvY2xvdWQvYmln
cXVlcnkvc3RvcmFnZS92MWJldGEyL3RhYmxlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvIqAJCgtSZWFkU2Vzc2lvbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUS
QAoLZXhwaXJlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmV4cGlyZVRpbWUSVwoLZGF0YV9mb3JtYXQYAyABKA4yMS5nb29nbGUuY2xvdWQuYmlncXVl
cnkuc3RvcmFnZS52MWJldGEyLkRhdGFGb3JtYXRCA+BBBVIKZGF0YUZvcm1hdBJZCgthdnJv
X3NjaGVtYRgEIAEoCzIxLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTIu
QXZyb1NjaGVtYUID4EEDSABSCmF2cm9TY2hlbWESXAoMYXJyb3dfc2NoZW1hGAUgASgLMjIu
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMi5BcnJvd1NjaGVtYUID4EED
SABSC2Fycm93U2NoZW1hEjsKBXRhYmxlGAYgASgJQiXgQQX6QR8KHWJpZ3F1ZXJ5Lmdvb2ds
ZWFwaXMuY29tL1RhYmxlUgV0YWJsZRJvCg90YWJsZV9tb2RpZmllcnMYByABKAsyQS5nb29n
bGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEyLlJlYWRTZXNzaW9uLlRhYmxlTW9k
aWZpZXJzQgPgQQFSDnRhYmxlTW9kaWZpZXJzEmsKDHJlYWRfb3B0aW9ucxgIIAEoCzJDLmdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTIuUmVhZFNlc3Npb24uVGFibGVS
ZWFkT3B0aW9uc0ID4EEBUgtyZWFkT3B0aW9ucxJQCgdzdHJlYW1zGAogAygLMjEuZ29vZ2xl
LmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMi5SZWFkU3RyZWFtQgPgQQNSB3N0cmVh
bXMaUQoOVGFibGVNb2RpZmllcnMSPwoNc25hcHNob3RfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSDHNuYXBzaG90VGltZRrsAQoQVGFibGVSZWFkT3B0aW9ucxIn
Cg9zZWxlY3RlZF9maWVsZHMYASADKAlSDnNlbGVjdGVkRmllbGRzEicKD3Jvd19yZXN0cmlj
dGlvbhgCIAEoCVIOcm93UmVzdHJpY3Rpb24ShQEKG2Fycm93X3NlcmlhbGl6YXRpb25fb3B0
aW9ucxgDIAEoCzJALmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTIuQXJy
b3dTZXJpYWxpemF0aW9uT3B0aW9uc0ID4EEBUhlhcnJvd1NlcmlhbGl6YXRpb25PcHRpb25z
OmvqQWgKKmJpZ3F1ZXJ5c3RvcmFnZS5nb29nbGVhcGlzLmNvbS9SZWFkU2Vzc2lvbhI6cHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nlc3Npb25zL3tzZXNzaW9u
fUIICgZzY2hlbWEiogEKClJlYWRTdHJlYW0SFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lOnvq
QXgKKWJpZ3F1ZXJ5c3RvcmFnZS5nb29nbGVhcGlzLmNvbS9SZWFkU3RyZWFtEktwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2Vzc2lvbnMve3Nlc3Npb259L3N0
cmVhbXMve3N0cmVhbX0imAQKC1dyaXRlU3RyZWFtEhcKBG5hbWUYASABKAlCA+BBA1IEbmFt
ZRJQCgR0eXBlGAIgASgOMjcuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRh
Mi5Xcml0ZVN0cmVhbS5UeXBlQgPgQQVSBHR5cGUSQAoLY3JlYXRlX3RpbWUYAyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLY29tbWl0X3Rp
bWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNvbW1pdFRpbWUS
WgoMdGFibGVfc2NoZW1hGAUgASgLMjIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2Uu
djFiZXRhMi5UYWJsZVNjaGVtYUID4EEDUgt0YWJsZVNjaGVtYSJGCgRUeXBlEhQKEFRZUEVf
VU5TUEVDSUZJRUQQABINCglDT01NSVRURUQQARILCgdQRU5ESU5HEAISDAoIQlVGRkVSRUQQ
Azp26kFzCipiaWdxdWVyeXN0b3JhZ2UuZ29vZ2xlYXBpcy5jb20vV3JpdGVTdHJlYW0SRXBy
b2plY3RzL3twcm9qZWN0fS9kYXRhc2V0cy97ZGF0YXNldH0vdGFibGVzL3t0YWJsZX0vc3Ry
ZWFtcy97c3RyZWFtfSo+CgpEYXRhRm9ybWF0EhsKF0RBVEFfRk9STUFUX1VOU1BFQ0lGSUVE
EAASCAoEQVZSTxABEgkKBUFSUk9XEAJC1wEKKWNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnku
c3RvcmFnZS52MWJldGEyQgtTdHJlYW1Qcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2Jp
Z3F1ZXJ5L3N0b3JhZ2UvYXBpdjFiZXRhMi9zdG9yYWdlcGI7c3RvcmFnZXBi6kFVCh1iaWdx
dWVyeS5nb29nbGVhcGlzLmNvbS9UYWJsZRI0cHJvamVjdHMve3Byb2plY3R9L2RhdGFzZXRz
L3tkYXRhc2V0fS90YWJsZXMve3RhYmxlfUqHNgoHEgUOAL4BAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQAOwoJCgIDAxIDFQA6CgkKAgMEEgMWADsKCQoCAwUSAxcAKQoICgEIEgMZAFoKCQoC
CAsSAxkAWgoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbACwKCQoCCAgSAxsALAoICgEI
EgMcAEIKCQoCCAESAxwAQgoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKMwoCBQASBCMALQEa
JyBEYXRhIGZvcm1hdCBmb3IgaW5wdXQgb3Igb3V0cHV0IGRhdGEuCgoKCgMFAAESAyMFDwoL
CgQFAAIAEgMkAh4KDAoFBQACAAESAyQCGQoMCgUFAAIAAhIDJBwdCnQKBAUAAgESAygCCxpn
IEF2cm8gaXMgYSBzdGFuZGFyZCBvcGVuIHNvdXJjZSByb3cgYmFzZWQgZmlsZSBmb3JtYXQu
CiBTZWUgaHR0cHM6Ly9hdnJvLmFwYWNoZS5vcmcvIGZvciBtb3JlIGRldGFpbHMuCgoMCgUF
AAIBARIDKAIGCgwKBQUAAgECEgMoCQoKfAoEBQACAhIDLAIMGm8gQXJyb3cgaXMgYSBzdGFu
ZGFyZCBvcGVuIHNvdXJjZSBjb2x1bW4tYmFzZWQgbWVzc2FnZSBmb3JtYXQuCiBTZWUgaHR0
cHM6Ly9hcnJvdy5hcGFjaGUub3JnLyBmb3IgbW9yZSBkZXRhaWxzLgoKDAoFBQACAgESAywC
BwoMCgUFAAICAhIDLAoLCjEKAgQAEgUwAIEBARokIEluZm9ybWF0aW9uIGFib3V0IHRoZSBS
ZWFkU2Vzc2lvbi4KCgoKAwQAARIDMAgTCgsKAwQABxIEMQI0BAoNCgUEAAedCBIEMQI0BAo7
CgQEAAMAEgQ3AjoDGi0gQWRkaXRpb25hbCBhdHRyaWJ1dGVzIHdoZW4gcmVhZGluZyBhIHRh
YmxlLgoKDAoFBAADAAESAzcKGApQCgYEAAMAAgASAzkEMBpBIFRoZSBzbmFwc2hvdCB0aW1l
IG9mIHRoZSB0YWJsZS4gSWYgbm90IHNldCwgaW50ZXJwcmV0ZWQgYXMgbm93LgoKDgoHBAAD
AAIABhIDOQQdCg4KBwQAAwACAAESAzkeKwoOCgcEAAMAAgADEgM5Li8KNgoEBAADARIEPQJS
AxooIE9wdGlvbnMgZGljdGF0aW5nIGhvdyB3ZSByZWFkIGEgdGFibGUuCgoMCgUEAAMBARID
PQoaCpgCCgYEAAMBAgASA0IEKBqIAiBOYW1lcyBvZiB0aGUgZmllbGRzIGluIHRoZSB0YWJs
ZSB0aGF0IHNob3VsZCBiZSByZWFkLiBJZiBlbXB0eSwgYWxsCiBmaWVsZHMgd2lsbCBiZSBy
ZWFkLiBJZiB0aGUgc3BlY2lmaWVkIGZpZWxkIGlzIGEgbmVzdGVkIGZpZWxkLCBhbGwKIHRo
ZSBzdWItZmllbGRzIGluIHRoZSBmaWVsZCB3aWxsIGJlIHNlbGVjdGVkLiBUaGUgb3V0cHV0
IGZpZWxkIG9yZGVyIGlzCiB1bnJlbGF0ZWQgdG8gdGhlIG9yZGVyIG9mIGZpZWxkcyBpbiBz
ZWxlY3RlZF9maWVsZHMuCgoOCgcEAAMBAgAEEgNCBAwKDgoHBAADAQIABRIDQg0TCg4KBwQA
AwECAAESA0IUIwoOCgcEAAMBAgADEgNCJicKhwMKBgQAAwECARIDTgQfGvcCIFNRTCB0ZXh0
IGZpbHRlcmluZyBzdGF0ZW1lbnQsIHNpbWlsYXIgdG8gYSBXSEVSRSBjbGF1c2UgaW4gYSBx
dWVyeS4KIEFnZ3JlZ2F0ZXMgYXJlIG5vdCBzdXBwb3J0ZWQuCgogRXhhbXBsZXM6ICJpbnRf
ZmllbGQgPiA1IgogICAgICAgICAgICJkYXRlX2ZpZWxkID0gQ0FTVCgnMjAxNC05LTI3JyBh
cyBEQVRFKSIKICAgICAgICAgICAibnVsbGFibGVfZmllbGQgaXMgbm90IE5VTEwiCiAgICAg
ICAgICAgInN0X2VxdWFscyhnZW9fZmllbGQsIHN0X2dlb2Zyb210ZXh0KCJQT0lOVCgyLCAy
KSIpKSIKICAgICAgICAgICAibnVtZXJpY19maWVsZCBCRVRXRUVOIDEuMCBBTkQgNS4wIgoK
IFJlc3RyaWN0ZWQgdG8gYSBtYXhpbXVtIGxlbmd0aCBmb3IgMSBNQi4KCg4KBwQAAwECAQUS
A04ECgoOCgcEAAMBAgEBEgNOCxoKDgoHBAADAQIBAxIDTh0eCk4KBgQAAwECAhIDUQRnGj8g
T3B0aW9uYWwuIE9wdGlvbnMgc3BlY2lmaWMgdG8gdGhlIEFwYWNoZSBBcnJvdyBvdXRwdXQg
Zm9ybWF0LgoKDgoHBAADAQICBhIDUQQdCg4KBwQAAwECAgESA1EeOQoOCgcEAAMBAgIDEgNR
PD0KDgoHBAADAQICCBIDUT5mChEKCgQAAwECAgicCAASA1E/ZQqQAQoEBAACABIDVgI+GoIB
IE91dHB1dCBvbmx5LiBVbmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIHNlc3Npb24sIGluIHRo
ZSBmb3JtCiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nl
c3Npb25zL3tzZXNzaW9uX2lkfWAuCgoMCgUEAAIABRIDVgIICgwKBQQAAgABEgNWCQ0KDAoF
BAACAAMSA1YQEQoMCgUEAAIACBIDVhI9Cg8KCAQAAgAInAgAEgNWEzwK7wEKBAQAAgESA1sC
WBrhASBPdXRwdXQgb25seS4gVGltZSBhdCB3aGljaCB0aGUgc2Vzc2lvbiBiZWNvbWVzIGlu
dmFsaWQuIEFmdGVyIHRoaXMgdGltZSwgc3Vic2VxdWVudAogcmVxdWVzdHMgdG8gcmVhZCB0
aGlzIFNlc3Npb24gd2lsbCByZXR1cm4gZXJyb3JzLiBUaGUgZXhwaXJlX3RpbWUgaXMKIGF1
dG9tYXRpY2FsbHkgYXNzaWduZWQgYW5kIGN1cnJlbnRseSBjYW5ub3QgYmUgc3BlY2lmaWVk
IG9yIHVwZGF0ZWQuCgoMCgUEAAIBBhIDWwIbCgwKBQQAAgEBEgNbHCcKDAoFBAACAQMSA1sq
KwoMCgUEAAIBCBIDWyxXCg8KCAQAAgEInAgAEgNbLVYKOQoEBAACAhIDXgJHGiwgSW1tdXRh
YmxlLiBEYXRhIGZvcm1hdCBvZiB0aGUgb3V0cHV0IGRhdGEuCgoMCgUEAAICBhIDXgIMCgwK
BQQAAgIBEgNeDRgKDAoFBAACAgMSA14bHAoMCgUEAAICCBIDXh1GCg8KCAQAAgIInAgAEgNe
HkUKsgEKBAQACAASBGMCaQMaowEgVGhlIHNjaGVtYSBmb3IgdGhlIHJlYWQuIElmIHJlYWRf
b3B0aW9ucy5zZWxlY3RlZF9maWVsZHMgaXMgc2V0LCB0aGUKIHNjaGVtYSBtYXkgYmUgZGlm
ZmVyZW50IGZyb20gdGhlIHRhYmxlIHNjaGVtYSBhcyBpdCB3aWxsIG9ubHkgY29udGFpbgog
dGhlIHNlbGVjdGVkIGZpZWxkcy4KCgwKBQQACAABEgNjCA4KKAoEBAACAxIDZQRLGhsgT3V0
cHV0IG9ubHkuIEF2cm8gc2NoZW1hLgoKDAoFBAACAwYSA2UEDgoMCgUEAAIDARIDZQ8aCgwK
BQQAAgMDEgNlHR4KDAoFBAACAwgSA2UfSgoPCggEAAIDCJwIABIDZSBJCikKBAQAAgQSA2gE
TRocIE91dHB1dCBvbmx5LiBBcnJvdyBzY2hlbWEuCgoMCgUEAAIEBhIDaAQPCgwKBQQAAgQB
EgNoEBwKDAoFBAACBAMSA2gfIAoMCgUEAAIECBIDaCFMCg8KCAQAAgQInAgAEgNoIksKlAEK
BAQAAgUSBG0CcgQahQEgSW1tdXRhYmxlLiBUYWJsZSB0aGF0IHRoaXMgUmVhZFNlc3Npb24g
aXMgcmVhZGluZyBmcm9tLCBpbiB0aGUgZm9ybQogYHByb2plY3RzL3twcm9qZWN0X2lkfS9k
YXRhc2V0cy97ZGF0YXNldF9pZH0vdGFibGVzL3t0YWJsZV9pZH0KCgwKBQQAAgUFEgNtAggK
DAoFBAACBQESA20JDgoMCgUEAAIFAxIDbRESCg0KBQQAAgUIEgRtE3IDCg8KCAQAAgUInAgA
EgNuBCsKDwoHBAACBQifCBIEbwRxBQpfCgQEAAIGEgN1Ak4aUiBPcHRpb25hbC4gQW55IG1v
ZGlmaWVycyB3aGljaCBhcmUgYXBwbGllZCB3aGVuIHJlYWRpbmcgZnJvbSB0aGUgc3BlY2lm
aWVkIHRhYmxlLgoKDAoFBAACBgYSA3UCEAoMCgUEAAIGARIDdREgCgwKBQQAAgYDEgN1IyQK
DAoFBAACBggSA3UlTQoPCggEAAIGCJwIABIDdSZMClgKBAQAAgcSA3gCTRpLIE9wdGlvbmFs
LiBSZWFkIG9wdGlvbnMgZm9yIHRoaXMgc2Vzc2lvbiAoZS5nLiBjb2x1bW4gc2VsZWN0aW9u
LCBmaWx0ZXJzKS4KCgwKBQQAAgcGEgN4AhIKDAoFBAACBwESA3gTHwoMCgUEAAIHAxIDeCIj
CgwKBQQAAgcIEgN4JEwKDwoIBAACBwicCAASA3glSwrMAgoEBAACCBIEgAECTxq9AiBPdXRw
dXQgb25seS4gQSBsaXN0IG9mIHN0cmVhbXMgY3JlYXRlZCB3aXRoIHRoZSBzZXNzaW9uLgoK
IEF0IGxlYXN0IG9uZSBzdHJlYW0gaXMgY3JlYXRlZCB3aXRoIHRoZSBzZXNzaW9uLiBJbiB0
aGUgZnV0dXJlLCBsYXJnZXIKIHJlcXVlc3Rfc3RyZWFtX2NvdW50IHZhbHVlcyAqbWF5KiBy
ZXN1bHQgaW4gdGhpcyBsaXN0IGJlaW5nIHVucG9wdWxhdGVkLAogaW4gdGhhdCBjYXNlLCB0
aGUgdXNlciB3aWxsIG5lZWQgdG8gdXNlIGEgTGlzdCBtZXRob2QgdG8gZ2V0IHRoZSBzdHJl
YW1zCiBpbnN0ZWFkLCB3aGljaCBpcyBub3QgeWV0IGF2YWlsYWJsZS4KCg0KBQQAAggEEgSA
AQIKCg0KBQQAAggGEgSAAQsVCg0KBQQAAggBEgSAARYdCg0KBQQAAggDEgSAASAiCg0KBQQA
AggIEgSAASNOChAKCAQAAggInAgAEgSAASRNCsMBCgIEARIGhgEAjwEBGrQBIEluZm9ybWF0
aW9uIGFib3V0IGEgc2luZ2xlIHN0cmVhbSB0aGF0IGdldHMgZGF0YSBvdXQgb2YgdGhlIHN0
b3JhZ2Ugc3lzdGVtLgogTW9zdCBvZiB0aGUgaW5mb3JtYXRpb24gYWJvdXQgYFJlYWRTdHJl
YW1gIGluc3RhbmNlcyBpcyBhZ2dyZWdhdGVkLCBtYWtpbmcKIGBSZWFkU3RyZWFtYCBsaWdo
dHdlaWdodC4KCgsKAwQBARIEhgEIEgoNCgMEAQcSBocBAooBBAoPCgUEAQedCBIGhwECigEE
CpYBCgQEAQIAEgSOAQI+GocBIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBzdHJlYW0sIGlu
IHRoZSBmb3JtCiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259
L3Nlc3Npb25zL3tzZXNzaW9uX2lkfS9zdHJlYW1zL3tzdHJlYW1faWR9YC4KCg0KBQQBAgAF
EgSOAQIICg0KBQQBAgABEgSOAQkNCg0KBQQBAgADEgSOARARCg0KBQQBAgAIEgSOARI9ChAK
CAQBAgAInAgAEgSOARM8ClsKAgQCEgaSAQC+AQEaTSBJbmZvcm1hdGlvbiBhYm91dCBhIHNp
bmdsZSBzdHJlYW0gdGhhdCBnZXRzIGRhdGEgaW5zaWRlIHRoZSBzdG9yYWdlIHN5c3RlbS4K
CgsKAwQCARIEkgEIEwoNCgMEAgcSBpMBApYBBAoPCgUEAgedCBIGkwEClgEECioKBAQCBAAS
BpkBAqYBAxoaIFR5cGUgZW51bSBvZiB0aGUgc3RyZWFtLgoKDQoFBAIEAAESBJkBBwsKHwoG
BAIEAAIAEgSbAQQZGg8gVW5rbm93biB0eXBlLgoKDwoHBAIEAAIAARIEmwEEFAoPCgcEAgQA
AgACEgSbARcYCmIKBgQCBAACARIEnwEEEhpSIERhdGEgd2lsbCBjb21taXQgYXV0b21hdGlj
YWxseSBhbmQgYXBwZWFyIGFzIHNvb24gYXMgdGhlIHdyaXRlIGlzCiBhY2tub3dsZWRnZWQu
CgoPCgcEAgQAAgEBEgSfAQQNCg8KBwQCBAACAQISBJ8BEBEKQgoGBAIEAAICEgSiAQQQGjIg
RGF0YSBpcyBpbnZpc2libGUgdW50aWwgdGhlIHN0cmVhbSBpcyBjb21taXR0ZWQuCgoPCgcE
AgQAAgIBEgSiAQQLCg8KBwQCBAACAgISBKIBDg8KUAoGBAIEAAIDEgSlAQQRGkAgRGF0YSBp
cyBvbmx5IHZpc2libGUgdXAgdG8gdGhlIG9mZnNldCB0byB3aGljaCBpdCB3YXMgZmx1c2hl
ZC4KCg8KBwQCBAACAwESBKUBBAwKDwoHBAIEAAIDAhIEpQEPEAqGAQoEBAICABIEqgECPhp4
IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBzdHJlYW0sIGluIHRoZSBmb3JtCiBgcHJvamVj
dHMve3Byb2plY3R9L2RhdGFzZXRzL3tkYXRhc2V0fS90YWJsZXMve3RhYmxlfS9zdHJlYW1z
L3tzdHJlYW19YC4KCg0KBQQCAgAFEgSqAQIICg0KBQQCAgABEgSqAQkNCg0KBQQCAgADEgSq
ARARCg0KBQQCAgAIEgSqARI9ChAKCAQCAgAInAgAEgSqARM8Ci4KBAQCAgESBK0BAjoaICBJ
bW11dGFibGUuIFR5cGUgb2YgdGhlIHN0cmVhbS4KCg0KBQQCAgEGEgStAQIGCg0KBQQCAgEB
EgStAQcLCg0KBQQCAgEDEgStAQ4PCg0KBQQCAgEIEgStARA5ChAKCAQCAgEInAgAEgStARE4
CnkKBAQCAgISBLEBAlgaayBPdXRwdXQgb25seS4gQ3JlYXRlIHRpbWUgb2YgdGhlIHN0cmVh
bS4gRm9yIHRoZSBfZGVmYXVsdCBzdHJlYW0sIHRoaXMgaXMgdGhlCiBjcmVhdGlvbl90aW1l
IG9mIHRoZSB0YWJsZS4KCg0KBQQCAgIGEgSxAQIbCg0KBQQCAgIBEgSxARwnCg0KBQQCAgID
EgSxASorCg0KBQQCAgIIEgSxASxXChAKCAQCAgIInAgAEgSxAS1WCu0BCgQEAgIDEgS3AQJY
Gt4BIE91dHB1dCBvbmx5LiBDb21taXQgdGltZSBvZiB0aGUgc3RyZWFtLgogSWYgYSBzdHJl
YW0gaXMgb2YgYENPTU1JVFRFRGAgdHlwZSwgdGhlbiBpdCB3aWxsIGhhdmUgYSBjb21taXRf
dGltZSBzYW1lIGFzCiBgY3JlYXRlX3RpbWVgLiBJZiB0aGUgc3RyZWFtIGlzIG9mIGBQRU5E
SU5HYCB0eXBlLCBjb21taXRfdGltZSBiZWluZyBlbXB0eQogbWVhbnMgaXQgaXMgbm90IGNv
bW1pdHRlZC4KCg0KBQQCAgMGEgS3AQIbCg0KBQQCAgMBEgS3ARwnCg0KBQQCAgMDEgS3ASor
Cg0KBQQCAgMIEgS3ASxXChAKCAQCAgMInAgAEgS3AS1WCqsCCgQEAgIEEgS9AQJLGpwCIE91
dHB1dCBvbmx5LiBUaGUgc2NoZW1hIG9mIHRoZSBkZXN0aW5hdGlvbiB0YWJsZS4gSXQgaXMg
b25seSByZXR1cm5lZCBpbgogYENyZWF0ZVdyaXRlU3RyZWFtYCByZXNwb25zZS4gQ2FsbGVy
IHNob3VsZCBnZW5lcmF0ZSBkYXRhIHRoYXQncwogY29tcGF0aWJsZSB3aXRoIHRoaXMgc2No
ZW1hIHRvIHNlbmQgaW4gaW5pdGlhbCBgQXBwZW5kUm93c1JlcXVlc3RgLgogVGhlIHRhYmxl
IHNjaGVtYSBjb3VsZCBnbyBvdXQgb2YgZGF0ZSBkdXJpbmcgdGhlIGxpZmUgdGltZSBvZiB0
aGUgc3RyZWFtLgoKDQoFBAICBAYSBL0BAg0KDQoFBAICBAESBL0BDhoKDQoFBAICBAMSBL0B
HR4KDQoFBAICBAgSBL0BH0oKEAoIBAICBAicCAASBL0BIEliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadSession ===
    # Fields for ReadSession
    # Field: name Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_format Type: 14 (.google.cloud.bigquery.storage.v1beta2.DataFormat)
    # Field: avro_schema Type: 11 (.google.cloud.bigquery.storage.v1beta2.AvroSchema)
    # Field: arrow_schema Type: 11 (.google.cloud.bigquery.storage.v1beta2.ArrowSchema)
    # Field: table Type: 9 ()
    # Field: table_modifiers Type: 11 (.google.cloud.bigquery.storage.v1beta2.ReadSession.TableModifiers)
    # Field: read_options Type: 11 (.google.cloud.bigquery.storage.v1beta2.ReadSession.TableReadOptions)
    # Field: streams Type: 11 (.google.cloud.bigquery.storage.v1beta2.ReadStream)

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadStream ===
    # Fields for ReadStream
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Stream::WriteStream ===
    # Fields for WriteStream
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.bigquery.storage.v1beta2.WriteStream.Type)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: commit_time Type: 11 (.google.protobuf.Timestamp)
    # Field: table_schema Type: 11 (.google.cloud.bigquery.storage.v1beta2.TableSchema)

# Enum: WriteStream::Type
our $WriteStream_TYPE_UNSPECIFIED = 0;
our $WriteStream_COMMITTED = 1;
our $WriteStream_PENDING = 2;
our $WriteStream_BUFFERED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta2::Stream - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta2/stream.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta2::Stream;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadSession->new({
        name => $name,
        expire_time => $expire_time,
        data_format => $data_format,
        avro_schema => $avro_schema,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadSession->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta2/stream.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadSession

Information about the ReadSession.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Unique identifier for the session, in the form
`projects/{project_id}/locations/{location}/sessions/{session_id}`.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time at which the session becomes invalid. After this time, subsequent
requests to read this Session will return errors. The expire_time is
automatically assigned and currently cannot be specified or updated.

=item * C<< $msg->data_format() >> / C<< $msg->data_format($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1beta2::DataFormat>)

Immutable. Data format of the output data.

=item * C<< $msg->avro_schema() >> / C<< $msg->avro_schema($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroSchema>)

Output only. Avro schema.

=item * C<< $msg->arrow_schema() >> / C<< $msg->arrow_schema($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSchema>)

Output only. Arrow schema.

=item * C<< $msg->table() >> / C<< $msg->table($value) >>

Type: C<String>

Immutable. Table that this ReadSession is reading from, in the form
`projects/{project_id}/datasets/{dataset_id}/tables/{table_id}

=item * C<< $msg->table_modifiers() >> / C<< $msg->table_modifiers($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadSession::TableModifiers>)

Optional. Any modifiers which are applied when reading from the specified table.

=item * C<< $msg->read_options() >> / C<< $msg->read_options($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadSession::TableReadOptions>)

Optional. Read options for this session (e.g. column selection, filters).

=item * C<< $msg->streams() >> / C<< $msg->streams($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadStream>)

Output only. A list of streams created with the session.

At least one stream is created with the session. In the future, larger
request_stream_count values *may* result in this list being unpopulated,
in that case, the user will need to use a List method to get the streams
instead, which is not yet available.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Stream::ReadStream

Information about a single stream that gets data out of the storage system.
Most of the information about `ReadStream` instances is aggregated, making
`ReadStream` lightweight.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the stream, in the form
`projects/{project_id}/locations/{location}/sessions/{session_id}/streams/{stream_id}`.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Stream::WriteStream

Information about a single stream that gets data inside the storage system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the stream, in the form
`projects/{project}/datasets/{dataset}/tables/{table}/streams/{stream}`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1beta2::WriteStream::Type>)

Immutable. Type of the stream.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the stream. For the _default stream, this is the
creation_time of the table.

=item * C<< $msg->commit_time() >> / C<< $msg->commit_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Commit time of the stream.
If a stream is of `COMMITTED` type, then it will have a commit_time same as
`create_time`. If the stream is of `PENDING` type, commit_time being empty
means it is not committed.

=item * C<< $msg->table_schema() >> / C<< $msg->table_schema($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Table::TableSchema>)

Output only. The schema of the destination table. It is only returned in
`CreateWriteStream` response. Caller should generate data that's
compatible with this schema to send in initial `AppendRowsRequest`.
The table schema could go out of date during the life time of the stream.

=back

=head3 Enum: WriteStream::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<COMMITTED> => C<1>

=item * C<PENDING> => C<2>

=item * C<BUFFERED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta2::Stream::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
