package Google::Cloud::Discoveryengine::V1::ProjectService;

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
    eval { require Google::Cloud::Discoveryengine::V1::Common };
    eval { require Google::Cloud::Discoveryengine::V1::Project };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3Byb2plY3Rfc2VydmljZS5wcm90
bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91
ZC9kaXNjb3ZlcnllbmdpbmUvdjEvY29tbW9uLnByb3RvGi1nb29nbGUvY2xvdWQvZGlzY292
ZXJ5ZW5naW5lL3YxL3Byb2plY3QucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRp
b25zLnByb3RvIvkFChdQcm92aXNpb25Qcm9qZWN0UmVxdWVzdBJCCgRuYW1lGAEgASgJQi7g
QQL6QSgKJmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgRuYW1lEjYK
FWFjY2VwdF9kYXRhX3VzZV90ZXJtcxgCIAEoCEID4EECUhJhY2NlcHREYXRhVXNlVGVybXMS
OAoWZGF0YV91c2VfdGVybXNfdmVyc2lvbhgDIAEoCUID4EECUhNkYXRhVXNlVGVybXNWZXJz
aW9uEmkKC3NhYXNfcGFyYW1zGAQgASgLMkMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5Qcm92aXNpb25Qcm9qZWN0UmVxdWVzdC5TYWFzUGFyYW1zQgPgQQFSCnNhYXNQYXJh
bXMSeAoQcHJvdmlzaW9uX2ludGVudBgFIAEoDjJILmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuUHJvdmlzaW9uUHJvamVjdFJlcXVlc3QuUHJvdmlzaW9uSW50ZW50QgPgQQFS
D3Byb3Zpc2lvbkludGVudBJOCgppZHBfY29uZmlnGAYgASgLMiouZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5JZHBDb25maWdCA+BBAVIJaWRwQ29uZmlnEjEKEnByZV9wcm92
aXNpb25fbW9kZRgIIAEoCEID4EEBUhBwcmVQcm92aXNpb25Nb2RlGlMKClNhYXNQYXJhbXMS
KQoOYWNjZXB0X2Jpel9xb3MYASABKAhCA+BBAVIMYWNjZXB0Qml6UW9zEhoKBmlzX2JpehgC
IAEoCEID4EEBUgVpc0JpeiJrCg9Qcm92aXNpb25JbnRlbnQSIAocUFJPVklTSU9OX0lOVEVO
VF9VTlNQRUNJRklFRBAAEhkKFVBST1ZJU0lPTl9JTlRFTlRfU09CSRABEhsKF1BST1ZJU0lP
Tl9JTlRFTlRfTEVHQUNZEAIiGgoYUHJvdmlzaW9uUHJvamVjdE1ldGFkYXRhMpwECg5Qcm9q
ZWN0U2VydmljZRK3AgoQUHJvdmlzaW9uUHJvamVjdBI4Lmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuUHJvdmlzaW9uUHJvamVjdFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIskBgtPkkwJWIh8vdjEve25hbWU9cHJvamVjdHMvKn06cHJvdmlzaW9u
OgEqWjAiKy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfTpwcm92aXNpb246ASra
QQRuYW1lykFjCidnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlByb2plY3QSOGdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUHJvdmlzaW9uUHJvamVjdE1ldGFkYXRh
Gs8BykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQoYCCiNj
b20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUITUHJvamVjdFNlcnZpY2VQcm90
b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3Zl
cnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2ds
ZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5n
aW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUr9JAoHEgUOAJMB
Iwq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADYKCQoCAwUS
AxcANwoJCgIDBhIDGAAtCggKAQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsAZAoJCgIICxID
GwBkCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4A
PAoJCgIIARIDHgA8CggKAQgSAx8ALQoJCgIIJBIDHwAtCggKAQgSAyAAPAoJCgIIKRIDIAA8
CggKAQgSAyEAOwoJCgIILRIDIQA7CmAKAgYAEgQlAEIBGlQgU2VydmljZSBmb3Igb3BlcmF0
aW9ucyBvbiB0aGUKIFtQcm9qZWN0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LlByb2plY3RdLgoKCgoDBgABEgMlCBYKCgoDBgADEgMmAkYKDAoFBgADmQgSAyYCRgoLCgMG
AAMSBCcCKkoKDQoFBgADmggSBCcCKkoKpAIKBAYAAgASBDICQQMalQIgUHJvdmlzaW9ucyB0
aGUgcHJvamVjdCByZXNvdXJjZS4gRHVyaW5nIHRoZQogcHJvY2VzcywgcmVsYXRlZCBzeXN0
ZW1zIHdpbGwgZ2V0IHByZXBhcmVkIGFuZCBpbml0aWFsaXplZC4KCiBDYWxsZXIgbXVzdCBy
ZWFkIHRoZSBbVGVybXMgZm9yIGRhdGEKIHVzZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L3JldGFpbC9kYXRhLXVzZS10ZXJtcyksIGFuZCBvcHRpb25hbGx5CiBzcGVjaWZ5IGluIHJl
cXVlc3QgdG8gcHJvdmlkZSBjb25zZW50IHRvIHRoYXQgc2VydmljZSB0ZXJtcy4KCgwKBQYA
AgABEgMyBhYKDAoFBgACAAISAzIXLgoMCgUGAAIAAxIDMw8rCg0KBQYAAgAEEgQ0BDsGChEK
CQYAAgAEsMq8IhIENAQ7BgoMCgUGAAIABBIDPAQyCg8KCAYAAgAEmwgAEgM8BDIKDQoFBgAC
AAQSBD0EQAYKDwoHBgACAASZCBIEPQRABgqHAQoCBAASBUcAkAEBGnogUmVxdWVzdCBmb3IK
IFtQcm9qZWN0U2VydmljZS5Qcm92aXNpb25Qcm9qZWN0XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLlByb2plY3RTZXJ2aWNlLlByb3Zpc2lvblByb2plY3RdCiBtZXRob2Qu
CgoKCgMEAAESA0cIHwoqCgQEAAMAEgRJAlIDGhwgUGFyYW1ldGVycyBmb3IgQWdlbnRzcGFj
ZS4KCgwKBQQAAwABEgNJChQKnAEKBgQAAwACABIDTARFGowBIE9wdGlvbmFsLiBTZXQgdG8g
YHRydWVgIHRvIHNwZWNpZnkgdGhhdCBjYWxsZXIgaGFzIHJlYWQgYW5kIHdvdWxkIGxpa2Ug
dG8KIGdpdmUgY29uc2VudCB0byB0aGUgW1Rlcm1zIGZvciBBZ2VudCBTcGFjZSBxdWFsaXR5
IG9mIHNlcnZpY2VdLgoKDgoHBAADAAIABRIDTAQICg4KBwQAAwACAAESA0wJFwoOCgcEAAMA
AgADEgNMGhsKDgoHBAADAAIACBIDTBxEChEKCgQAAwACAAicCAASA0wdQwprCgYEAAMAAgES
A1EEPRpcIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaWYgdGhlIGN1cnJlbnQgcmVxdWVzdCBpcyBm
b3IgQml6IGVkaXRpb24gKD0gdHJ1ZSkgb3IKIG5vdAogKD0gZmFsc2UpLgoKDgoHBAADAAIB
BRIDUQQICg4KBwQAAwACAQESA1EJDwoOCgcEAAMAAgEDEgNREhMKDgoHBAADAAIBCBIDURQ8
ChEKCgQAAwACAQicCAASA1EVOwo8CgQEAAQAEgRVAl8DGi4gV2hpY2ggZXhwZXJpZW5jZSB0
aGUgY2FsbGVyIGlzIHByb3Zpc2lvbmluZy4KCgwKBQQABAABEgNVBxYKHQoGBAAEAAIAEgNX
BCUaDiBVbnNwZWNpZmllZC4KCg4KBwQABAACAAESA1cEIAoOCgcEAAQAAgACEgNXIyQKVQoG
BAAEAAIBEgNaBB4aRiBUaGUgY2FsbGVyIGlzIHByb3Zpc2lvbmluZyBmb3IgdGhlIG5ldyBH
ZW1pbmkgRW50ZXJwcmlzZSBleHBlcmllbmNlLgoKDgoHBAAEAAIBARIDWgQZCg4KBwQABAAC
AQISA1ocHQpaCgYEAAQAAgISA14EIBpLIFRoZSBjYWxsZXIgaXMgcHJvdmlzaW9uaW5nIGZv
ciB0aGUgY2xhc3NpYyBHZW1pbmkgRW50ZXJwcmlzZQogZXhwZXJpZW5jZS4KCg4KBwQABAAC
AgESA14EGwoOCgcEAAQAAgICEgNeHh8KkwEKBAQAAgASBGQCaQQahAEgUmVxdWlyZWQuIEZ1
bGwgcmVzb3VyY2UgbmFtZSBvZiBhCiBbUHJvamVjdF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5Qcm9qZWN0XSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0X2lkX29y
X251bWJlcn1gLgoKDAoFBAACAAUSA2QCCAoMCgUEAAIAARIDZAkNCgwKBQQAAgADEgNkEBEK
DQoFBAACAAgSBGQSaQMKDwoIBAACAAicCAASA2UEKgoPCgcEAAIACJ8IEgRmBGgFCrUBCgQE
AAIBEgNuAkoapwEgUmVxdWlyZWQuIFNldCB0byBgdHJ1ZWAgdG8gc3BlY2lmeSB0aGF0IGNh
bGxlciBoYXMgcmVhZCBhbmQgd291bGQgbGlrZSB0bwogZ2l2ZSBjb25zZW50IHRvIHRoZSBb
VGVybXMgZm9yIGRhdGEKIHVzZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9k
YXRhLXVzZS10ZXJtcykuCgoMCgUEAAIBBRIDbgIGCgwKBQQAAgEBEgNuBxwKDAoFBAACAQMS
A24fIAoMCgUEAAIBCBIDbiFJCg8KCAQAAgEInAgAEgNuIkgK8AEKBAQAAgISA3UCTRriASBS
ZXF1aXJlZC4gVGhlIHZlcnNpb24gb2YgdGhlIFtUZXJtcyBmb3IgZGF0YQogdXNlXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RhdGEtdXNlLXRlcm1zKSB0aGF0IGNhbGxl
ciBoYXMgcmVhZAogYW5kIHdvdWxkIGxpa2UgdG8gZ2l2ZSBjb25zZW50IHRvLgoKIEFjY2Vw
dGFibGUgdmVyc2lvbiBpcyBgMjAyMi0xMS0yM2AsIGFuZCB0aGlzIG1heSBjaGFuZ2Ugb3Zl
ciB0aW1lLgoKDAoFBAACAgUSA3UCCAoMCgUEAAICARIDdQkfCgwKBQQAAgIDEgN1IiMKDAoF
BAACAggSA3UkTAoPCggEAAICCJwIABIDdSVLCjMKBAQAAgMSA3gCRhomIE9wdGlvbmFsLiBQ
YXJhbWV0ZXJzIGZvciBBZ2VudHNwYWNlLgoKDAoFBAACAwYSA3gCDAoMCgUEAAIDARIDeA0Y
CgwKBQQAAgMDEgN4GxwKDAoFBAACAwgSA3gdRQoPCggEAAIDCJwIABIDeB5ECoABCgQEAAIE
EgN8AlAacyBPcHRpb25hbC4gVGhlIGNhbGxlciBzdGF0ZXMgd2hldGhlciB0aGUgcHJvdmlz
aW9uaW5nIGlzIGZvciB0aGUgbmV3IG9yIHRoZQogY2xhc3NpYyBHZW1pbmkgRW50ZXJwcmlz
ZSBleHBlcmllbmNlLgoKDAoFBAACBAYSA3wCEQoMCgUEAAIEARIDfBIiCgwKBQQAAgQDEgN8
JSYKDAoFBAACBAgSA3wnTwoPCggEAAIECJwIABIDfChOCsIBCgQEAAIFEgSBAQJEGrMBIE9w
dGlvbmFsLiBUaGUgaWRlbnRpdHkgcHJvdmlkZXIgZm9yIHRoaXMgbG9jYXRpb24uIFdoZW4g
cHJvdmlkZWQsIHRoZQogbG9jYXRpb24ncyBbQWNsQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkFjbENvbmZpZ10gaXMKIHNldCBmcm9tIGl0IGFzIHBhcnQgb2Yg
cHJvdmlzaW9uaW5nLgoKDQoFBAACBQYSBIEBAgsKDQoFBAACBQESBIEBDBYKDQoFBAACBQMS
BIEBGRoKDQoFBAACBQgSBIEBG0MKEAoIBAACBQicCAASBIEBHEIKsAUKBAQAAgYSBI8BAkca
oQUgT3B0aW9uYWwuIFJ1bnMgb25seSB0aGUgY29tbW9uIHByb2plY3QtbGV2ZWwgcHJlLXBy
b3Zpc2lvbmluZyBzdGVwcwogKHNlcnZpY2UgYWdlbnRzLCBhZ2VudCBpZGVudGl0eSBwb29s
cywgcHJvamVjdC1zY29wZWQgZXh0ZW5zaW9uIGJpbmRpbmdzLAogQXBwIEh1YiByZWdpc3Ry
eSwgU29iaSBhZ2VudCBkZWZhdWx0IGlkZW50aXR5LCBhbmQgU29iaSBkZWZhdWx0IE1vZGVs
IEFybW9yCiB0ZW1wbGF0ZSkgd2l0aG91dCByZWFkaW5nIG9yIHdyaXRpbmcgdGhlIEN1c3Rv
bWVyLCBDb2xsZWN0aW9uLCBvciBVc2VyU3RvcmUKIHRhYmxlcywgQ2FwYWJpbGl0eUNvbmZp
ZywgdGVuYW50IHByb2plY3QsIGRlZmF1bHQgZW5naW5lLCBvciB0cmlhbCBsaWNlbnNlcwog
d2hlbiBgdHJ1ZWAuCgogQXNzdW1lcyBubyBjdXN0b21lciBleGlzdHMgeWV0LiBDdXN0b21l
ci1sZXZlbCBvciBub24tU09CSSBmaWVsZHMKIChgYWNjZXB0X2RhdGFfdXNlX3Rlcm1zYCwg
YGRhdGFfdXNlX3Rlcm1zX3ZlcnNpb25gLCBgc2Fhc19wYXJhbXNgLAogYGlkcF9jb25maWdg
LCBhbmQgYFBST1ZJU0lPTl9JTlRFTlRfTEVHQUNZYCkgYXJlIHJlamVjdGVkIHdpdGgKIGBJ
TlZBTElEX0FSR1VNRU5UYCwgYW5kIHRoZSByZXR1cm5lZCBjb21wbGV0ZWQgYE9wZXJhdGlv
bmAgaGFzIGFuIGVtcHR5CiByZXNwb25zZS4KCg0KBQQAAgYFEgSPAQIGCg0KBQQAAgYBEgSP
AQcZCg0KBQQAAgYDEgSPARwdCg0KBQQAAgYIEgSPAR5GChAKCAQAAgYInAgAEgSPAR9FCkUK
AgQBEgSTAQAjGjkgTWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIGEgcHJvamVjdCBwcm92aXNp
b24gb3BlcmF0aW9uLgoKCwoDBAEBEgSTAQggYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest ===
    # Fields for ProvisionProjectRequest
    # Field: name Type: 9 ()
    # Field: accept_data_use_terms Type: 8 ()
    # Field: data_use_terms_version Type: 9 ()
    # Field: saas_params Type: 11 (.google.cloud.discoveryengine.v1.ProvisionProjectRequest.SaasParams)
    # Field: provision_intent Type: 14 (.google.cloud.discoveryengine.v1.ProvisionProjectRequest.ProvisionIntent)
    # Field: idp_config Type: 11 (.google.cloud.discoveryengine.v1.IdpConfig)
    # Field: pre_provision_mode Type: 8 ()

# Enum: ProvisionProjectRequest::ProvisionIntent
our $ProvisionProjectRequest_PROVISION_INTENT_UNSPECIFIED = 0;
our $ProvisionProjectRequest_PROVISION_INTENT_SOBI = 1;
our $ProvisionProjectRequest_PROVISION_INTENT_LEGACY = 2;

# === Message: Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectMetadata ===
    # Fields for ProvisionProjectMetadata

# === Service Client: Google::Cloud::Discoveryengine::V1::ProjectService::ProjectServiceClient ===
package Google::Cloud::Discoveryengine::V1::ProjectService::ProjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::ProjectService::ProjectServiceClient

Client stub representing the remote C<ProjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub provision_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ProjectService',
        method         => 'ProvisionProject',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::ProjectService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/project_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::ProjectService;

    my $msg = Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest->new({
        name => $name,
        accept_data_use_terms => $accept_data_use_terms,
        data_use_terms_version => $data_use_terms_version,
        saas_params => $saas_params,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/project_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest

Request for
[ProjectService.ProvisionProject][google.cloud.discoveryengine.v1.ProjectService.ProvisionProject]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of a
[Project][google.cloud.discoveryengine.v1.Project], such as
`projects/{project_id_or_number}`.

=item * C<< $msg->accept_data_use_terms() >> / C<< $msg->accept_data_use_terms($value) >>

Type: C<Bool>

Required. Set to `true` to specify that caller has read and would like to
give consent to the [Terms for data
use](https://cloud.google.com/retail/data-use-terms).

=item * C<< $msg->data_use_terms_version() >> / C<< $msg->data_use_terms_version($value) >>

Type: C<String>

Required. The version of the [Terms for data
use](https://cloud.google.com/retail/data-use-terms) that caller has read
and would like to give consent to.

Acceptable version is `2022-11-23`, and this may change over time.

=item * C<< $msg->saas_params() >> / C<< $msg->saas_params($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest::SaasParams>)

Optional. Parameters for Agentspace.

=item * C<< $msg->provision_intent() >> / C<< $msg->provision_intent($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::ProvisionProjectRequest::ProvisionIntent>)

Optional. The caller states whether the provisioning is for the new or the
classic Gemini Enterprise experience.

=item * C<< $msg->idp_config() >> / C<< $msg->idp_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Common::IdpConfig>)

Optional. The identity provider for this location. When provided, the
location's [AclConfig][google.cloud.discoveryengine.v1.AclConfig] is
set from it as part of provisioning.

=item * C<< $msg->pre_provision_mode() >> / C<< $msg->pre_provision_mode($value) >>

Type: C<Bool>

Optional. Runs only the common project-level pre-provisioning steps
(service agents, agent identity pools, project-scoped extension bindings,
App Hub registry, Sobi agent default identity, and Sobi default Model Armor
template) without reading or writing the Customer, Collection, or UserStore
tables, CapabilityConfig, tenant project, default engine, or trial licenses
when `true`.

Assumes no customer exists yet. Customer-level or non-SOBI fields
(`accept_data_use_terms`, `data_use_terms_version`, `saas_params`,
`idp_config`, and `PROVISION_INTENT_LEGACY`) are rejected with
`INVALID_ARGUMENT`, and the returned completed `Operation` has an empty
response.

=back

=head3 Enum: ProvisionProjectRequest::ProvisionIntent

=over 4

=item * C<PROVISION_INTENT_UNSPECIFIED> => C<0>

=item * C<PROVISION_INTENT_SOBI> => C<1>

=item * C<PROVISION_INTENT_LEGACY> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectMetadata

Metadata associated with a project provision operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::ProjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
