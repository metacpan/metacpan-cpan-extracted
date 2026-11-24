package Google::Cloud::Discoveryengine::V1::CmekConfigService;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NtZWtfY29uZmlnX3NlcnZpY2Uu
cHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaHGdvb2dsZS9hcGkvYW5u
b3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiNnb29nbGUv
bG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoQBChdVcGRhdGVDbWVrQ29u
ZmlnUmVxdWVzdBJICgZjb25maWcYASABKAsyKy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkNtZWtDb25maWdCA+BBAlIGY29uZmlnEh8KC3NldF9kZWZhdWx0GAIgASgIUgpz
ZXREZWZhdWx0Il0KFEdldENtZWtDb25maWdSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpB
KwopZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NtZWtDb25maWdSBG5hbWUiVgoP
U2luZ2xlUmVnaW9uS2V5EkMKB2ttc19rZXkYASABKAlCKuBBAvpBJAoiY2xvdWRrbXMuZ29v
Z2xlYXBpcy5jb20vQ3J5cHRvS2V5c1IGa21zS2V5IsMICgpDbWVrQ29uZmlnEhcKBG5hbWUY
ASABKAlCA+BBAlIEbmFtZRJDCgdrbXNfa2V5GAIgASgJQirgQQL6QSQKImNsb3Vka21zLmdv
b2dsZWFwaXMuY29tL0NyeXB0b0tleXNSBmttc0tleRJZCg9rbXNfa2V5X3ZlcnNpb24YBiAB
KAlCMeBBA/pBKwopY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5VmVyc2lvbnNS
DWttc0tleVZlcnNpb24STAoFc3RhdGUYAyABKA4yMS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkNtZWtDb25maWcuU3RhdGVCA+BBA1IFc3RhdGUSIgoKaXNfZGVmYXVsdBgE
IAEoCEID4EEDUglpc0RlZmF1bHQSSAoebGFzdF9yb3RhdGlvbl90aW1lc3RhbXBfbWljcm9z
GAUgASgDQgPgQQNSG2xhc3RSb3RhdGlvblRpbWVzdGFtcE1pY3JvcxJjChJzaW5nbGVfcmVn
aW9uX2tleXMYByADKAsyMC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNpbmds
ZVJlZ2lvbktleUID4EEBUhBzaW5nbGVSZWdpb25LZXlzEmsKEG5vdGVib29rbG1fc3RhdGUY
CCABKA4yOy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNtZWtDb25maWcuTm90
ZWJvb2tMTVN0YXRlQgPgQQNSD25vdGVib29rbG1TdGF0ZSKlAQoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEg0KCUtFWV9JU1NVRRAD
EgwKCERFTEVUSU5HEAQSEQoNREVMRVRFX0ZBSUxFRBAHEgwKCFVOVVNBQkxFEAUSEwoPQUNU
SVZFX1JPVEFUSU5HEAYSCwoHREVMRVRFRBAIEgsKB0VYUElSRUQQCSKDAQoPTm90ZWJvb2tM
TVN0YXRlEiEKHU5PVEVCT09LX0xNX1NUQVRFX1VOU1BFQ0lGSUVEEAASGQoVTk9URUJPT0tf
TE1fTk9UX1JFQURZEAESFQoRTk9URUJPT0tfTE1fUkVBRFkQAhIbChdOT1RFQk9PS19MTV9O
T1RfRU5BQkxFRBADOr8B6kG7AQopZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0Nt
ZWtDb25maWcSMnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbWVr
Q29uZmlnEkFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY21la0Nv
bmZpZ3Mve2NtZWtfY29uZmlnfSoLY21la0NvbmZpZ3MyCmNtZWtDb25maWcilAEKGFVwZGF0
ZUNtZWtDb25maWdNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lImEKFkxpc3RDbWVrQ29uZmlnc1Jl
cXVlc3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50ImkKF0xpc3RDbWVrQ29uZmlnc1Jlc3BvbnNlEk4K
DGNtZWtfY29uZmlncxgBIAMoCzIrLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
Q21la0NvbmZpZ1ILY21la0NvbmZpZ3MiYAoXRGVsZXRlQ21la0NvbmZpZ1JlcXVlc3QSRQoE
bmFtZRgBIAEoCUIx4EEC+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ21l
a0NvbmZpZ1IEbmFtZSKUAQoYRGVsZXRlQ21la0NvbmZpZ01ldGFkYXRhEjsKC2NyZWF0ZV90
aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1
cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRp
bWUy/wkKEUNtZWtDb25maWdTZXJ2aWNlEuUCChBVcGRhdGVDbWVrQ29uZmlnEjguZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5VcGRhdGVDbWVrQ29uZmlnUmVxdWVzdBodLmdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i9wGC0+STAn8yMy92MS97Y29uZmlnLm5hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbWVrQ29uZmlnfToGY29uZmlnWkAyNi92MS97Y29u
ZmlnLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbWVrQ29uZmlncy8qfToGY29uZmln
2kEGY29uZmlnykFmCipnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNtZWtDb25m
aWcSOGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXBkYXRlQ21la0NvbmZpZ01l
dGFkYXRhEuMBCg1HZXRDbWVrQ29uZmlnEjUuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5HZXRDbWVrQ29uZmlnUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuQ21la0NvbmZpZyJugtPkkwJhEiwvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jbWVrQ29uZmlnfVoxEi8vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
bWVrQ29uZmlncy8qfdpBBG5hbWUSxgEKD0xpc3RDbWVrQ29uZmlncxI3Lmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdENtZWtDb25maWdzUmVxdWVzdBo4Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdENtZWtDb25maWdzUmVzcG9uc2UiQILT5JMC
MRIvL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY21la0NvbmZpZ3PaQQZw
YXJlbnQSgAIKEERlbGV0ZUNtZWtDb25maWcSOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkRlbGV0ZUNtZWtDb25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiKSAYLT5JMCMSovL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY21l
a0NvbmZpZ3MvKn3aQQRuYW1lykFRChVnb29nbGUucHJvdG9idWYuRW1wdHkSOGdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGVsZXRlQ21la0NvbmZpZ01ldGFkYXRhGs8BykEe
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQokCCiNjb20uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUIWQ21la0NvbmZpZ1NlcnZpY2VQcm90b1AB
Wk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3Zlcnll
bmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5D
bG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5l
XFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUqpRQoHEgUOALgCAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAm
CgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC0KCQoCAwUSAxcA
JQoJCgIDBhIDGAApCggKAQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsAZAoJCgIICxIDGwBk
CggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANwoJCgIICBIDHQA3CggKAQgSAx4APAoJ
CgIIARIDHgA8CggKAQgSAx8ALQoJCgIIJBIDHwAtCggKAQgSAyAAPAoJCgIIKRIDIAA8CggK
AQgSAyEAOwoJCgIILRIDIQA7CjUKAgYAEgQkAGEBGikgU2VydmljZSBmb3IgbWFuYWdpbmcg
Q01FSyByZWxhdGVkIHRhc2tzCgoKCgMGAAESAyQIGQoKCgMGAAMSAyUCRgoMCgUGAAOZCBID
JQJGCgsKAwYAAxIEJgIpSgoNCgUGAAOaCBIEJgIpSgrtAQoEBgACABIELwI+AxreASBQcm92
aXNpb25zIGEgQ01FSyBrZXkgZm9yIHVzZSBpbiBhIGxvY2F0aW9uIG9mIGEgY3VzdG9tZXIn
cyBwcm9qZWN0LgogVGhpcyBtZXRob2Qgd2lsbCBhbHNvIGNvbmR1Y3QgbG9jYXRpb24gdmFs
aWRhdGlvbiBvbiB0aGUgcHJvdmlkZWQKIGNtZWtDb25maWcgdG8gbWFrZSBzdXJlIHRoZSBr
ZXkgaXMgdmFsaWQgYW5kIGNhbiBiZSB1c2VkIGluIHRoZQogc2VsZWN0ZWQgbG9jYXRpb24u
CgoMCgUGAAIAARIDLwYWCgwKBQYAAgACEgMvFy4KDAoFBgACAAMSAzAPKwoNCgUGAAIABBIE
MQQ4BgoRCgkGAAIABLDKvCISBDEEOAYKDAoFBgACAAQSAzkENAoPCggGAAIABJsIABIDOQQ0
Cg0KBQYAAgAEEgQ6BD0GCg8KBwYAAgAEmQgSBDoEPQYKUgoEBgACARIEQQJJAxpEIEdldHMg
dGhlIFtDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNtZWtD
b25maWddLgoKDAoFBgACAQESA0EGEwoMCgUGAAIBAhIDQRQoCgwKBQYAAgEDEgNBMz0KDQoF
BgACAQQSBEIERwYKEQoJBgACAQSwyrwiEgRCBEcGCgwKBQYAAgEEEgNIBDIKDwoIBgACAQSb
CAASA0gEMgpqCgQGAAICEgRNAlMDGlwgTGlzdHMgYWxsIHRoZSBbQ21la0NvbmZpZ11bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DbWVrQ29uZmlnXXMKIHdpdGggdGhlIHBy
b2plY3QuCgoMCgUGAAICARIDTQYVCgwKBQYAAgICEgNNFiwKDAoFBgACAgMSA04PJgoNCgUG
AAICBBIETwRRBgoRCgkGAAICBLDKvCISBE8EUQYKDAoFBgACAgQSA1IENAoPCggGAAICBJsI
ABIDUgQ0CisKBAYAAgMSBFYCYAMaHSBEZS1wcm92aXNpb25zIGEgQ21la0NvbmZpZy4KCgwK
BQYAAgMBEgNWBhYKDAoFBgACAwISA1YXLgoMCgUGAAIDAxIDVw8rCg0KBQYAAgMEEgRYBFoG
ChEKCQYAAgMEsMq8IhIEWARaBgoMCgUGAAIDBBIDWwQyCg8KCAYAAgMEmwgAEgNbBDIKDQoF
BgACAwQSBFwEXwYKDwoHBgACAwSZCBIEXARfBgpACgIEABIEZQBsARo0IFJlcXVlc3QgbWVz
c2FnZSBmb3IgVXBkYXRlQ21la0NvbmZpZyBtZXRob2QuCiBycGMuCgoKCgMEAAESA2UIHwox
CgQEAAIAEgNnAkEaJCBSZXF1aXJlZC4gVGhlIENtZWtDb25maWcgcmVzb3VyY2UuCgoMCgUE
AAIABhIDZwIMCgwKBQQAAgABEgNnDRMKDAoFBAACAAMSA2cWFwoMCgUEAAIACBIDZxhACg8K
CAQAAgAInAgAEgNnGT8KcwoEBAACARIDawIXGmYgU2V0IHRoZSBmb2xsb3dpbmcgQ21la0Nv
bmZpZyBhcyB0aGUgZGVmYXVsdCB0byBiZSB1c2VkIGZvciBjaGlsZAogcmVzb3VyY2VzIGlm
IG9uZSBpcyBub3Qgc3BlY2lmaWVkLgoKDAoFBAACAQUSA2sCBgoMCgUEAAIBARIDawcSCgwK
BQQAAgEDEgNrFRYKPgoCBAESBG8AfgEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEdldENtZWtD
b25maWdSZXF1ZXN0IG1ldGhvZC4KCgoKAwQBARIDbwgcCoEDCgQEAQIAEgR4An0EGvICIFJl
cXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mCiBbQ21la0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5DbWVrQ29uZmlnXSwgc3VjaCBhcwogYHByb2plY3RzLyovbG9j
YXRpb25zLyovY21la0NvbmZpZ2Agb3IKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NtZWtD
b25maWdzLypgLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRv
IGFjY2VzcyB0aGUKIFtDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLkNtZWtDb25maWddLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlz
dHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUEAQIABRID
eAIICgwKBQQBAgABEgN4CQ0KDAoFBAECAAMSA3gQEQoNCgUEAQIACBIEeBJ9AwoPCggEAQIA
CJwIABIDeQQqCg8KBwQBAgAInwgSBHoEfAUKMwoCBAISBoEBAIsBARolIE1ldGFkYXRhIGZv
ciBzaW5nbGUtcmVnaW9uYWwgQ01FS3MuCgoLCgMEAgESBIEBCBcKvQEKBAQCAgASBoUBAooB
BBqsASBSZXF1aXJlZC4gU2luZ2xlLXJlZ2lvbmFsIGttcyBrZXkgcmVzb3VyY2UgbmFtZSB3
aGljaCB3aWxsIGJlIHVzZWQgdG8KIGVuY3J5cHQgcmVzb3VyY2VzCiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleVJpbmdzL3trZXlSaW5nfS9jcnlwdG9L
ZXlzL3trZXlJZH1gLgoKDQoFBAICAAUSBIUBAggKDQoFBAICAAESBIUBCRAKDQoFBAICAAMS
BIUBExQKDwoFBAICAAgSBoUBFYoBAwoQCggEAgIACJwIABIEhgEEKgoRCgcEAgIACJ8IEgaH
AQSJAQUKVwoCBAMSBo4BAPMBARpJIENvbmZpZ3VyYXRpb25zIHVzZWQgdG8gZW5hYmxlIENN
RUsgZGF0YSBlbmNyeXB0aW9uIHdpdGggQ2xvdWQgS01TIGtleXMuCgoLCgMEAwESBI4BCBIK
DQoDBAMHEgaPAQKVAQQKDwoFBAMHnQgSBo8BApUBBAorCgQEAwQAEgaYAQK5AQMaGyBTdGF0
ZXMgb2YgdGhlIENtZWtDb25maWcuCgoNCgUEAwQAARIEmAEHDAoyCgYEAwQAAgASBJoBBBoa
IiBUaGUgQ21la0NvbmZpZyBzdGF0ZSBpcyB1bmtub3duLgoKDwoHBAMEAAIAARIEmgEEFQoP
CgcEAwQAAgACEgSaARgZCi0KBgQDBAACARIEnQEEERodIFRoZSBDbWVrQ29uZmlnIGlzIGNy
ZWF0aW5nLgoKDwoHBAMEAAIBARIEnQEEDAoPCgcEAwQAAgECEgSdAQ8QCj0KBgQDBAACAhIE
oAEEDxotIFRoZSBDbWVrQ29uZmlnIGNhbiBiZSB1c2VkIHdpdGggRGF0YVN0b3Jlcy4KCg8K
BwQDBAACAgESBKABBAoKDwoHBAMEAAICAhIEoAENDgpfCgYEAwQAAgMSBKQBBBIaTyBUaGUg
Q21la0NvbmZpZyBpcyB1bmF2YWlsYWJsZSwgbW9zdCBsaWtlbHkgZHVlIHRvIHRoZSBLTVMg
S2V5IGJlaW5nCiByZXZva2VkLgoKDwoHBAMEAAIDARIEpAEEDQoPCgcEAwQAAgMCEgSkARAR
Ci0KBgQDBAACBBIEpwEEERodIFRoZSBDbWVrQ29uZmlnIGlzIGRlbGV0aW5nLgoKDwoHBAME
AAIEARIEpwEEDAoPCgcEAwQAAgQCEgSnAQ8QCjkKBgQDBAACBRIEqgEEFhopIFRoZSBDbWVr
Q29uZmlnIGRlbGV0aW9uIHByb2Nlc3MgZmFpbGVkLgoKDwoHBAMEAAIFARIEqgEEEQoPCgcE
AwQAAgUCEgSqARQVClcKBgQDBAACBhIErQEEERpHIFRoZSBDbWVrQ29uZmlnIGlzIG5vdCB1
c2FibGUsIG1vc3QgbGlrZWx5IGR1ZSB0byBzb21lIGludGVybmFsIGlzc3VlLgoKDwoHBAME
AAIGARIErQEEDAoPCgcEAwQAAgYCEgStAQ8QCjcKBgQDBAACBxIEsAEEGBonIFRoZSBLTVMg
a2V5IHZlcnNpb24gaXMgYmVpbmcgcm90YXRlZC4KCg8KBwQDBAACBwESBLABBBMKDwoHBAME
AAIHAhIEsAEWFwpfCgYEAwQAAggSBLQBBBAaTyBUaGUgS01TIGtleSBpcyBzb2Z0IGRlbGV0
ZWQuIFNvbWUgY2xlYW51cCBwb2xpY3kgd2lsbCBldmVudHVhbGx5IGJlCiBhcHBsaWVkLgoK
DwoHBAMEAAIIARIEtAEECwoPCgcEAwQAAggCEgS0AQ4PCqIBCgYEAwQAAgkSBLgBBBAakQEg
VGhlIEtNUyBrZXkgaXMgZXhwaXJlZCwgbWVhbmluZyB0aGUga2V5IGhhcyBiZWVuIGRpc2Fi
bGVkIGZvciAzMCsgZGF5cy4KIFRoZSBjdXN0b21lciBjYW4gY2FsbCBEZWxldGVDbWVrQ29u
ZmlnIHRvIGNoYW5nZSB0aGUgc3RhdGUgdG8gREVMRVRFRC4KCg8KBwQDBAACCQESBLgBBAsK
DwoHBAMEAAIJAhIEuAEODwonCgQEAwQBEga8AQLIAQMaFyBTdGF0ZXMgb2YgTm90ZWJvb2tM
TS4KCg0KBQQDBAEBEgS8AQcWCjIKBgQDBAECABIEvgEEJhoiIFRoZSBOb3RlYm9va0xNIHN0
YXRlIGlzIHVua25vd24uCgoPCgcEAwQBAgABEgS+AQQhCg8KBwQDBAECAAISBL4BJCUKLgoG
BAMEAQIBEgTBAQQeGh4gVGhlIE5vdGVib29rTE0gaXMgbm90IHJlYWR5LgoKDwoHBAMEAQIB
ARIEwQEEGQoPCgcEAwQBAgECEgTBARwdCjUKBgQDBAECAhIExAEEGholIFRoZSBOb3RlYm9v
a0xNIGlzIHJlYWR5IHRvIGJlIHVzZWQuCgoPCgcEAwQBAgIBEgTEAQQVCg8KBwQDBAECAgIS
BMQBGBkKMAoGBAMEAQIDEgTHAQQgGiAgVGhlIE5vdGVib29rTE0gaXMgbm90IGVuYWJsZWQu
CgoPCgcEAwQBAgMBEgTHAQQbCg8KBwQDBAECAwISBMcBHh8KwAEKBAQDAgASBM0BAjsasQEg
UmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBDbWVrQ29uZmlnIG9mIHRoZSBmb3JtCiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NtZWtDb25maWdgIG9yCiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NtZWtDb25maWdzL3tj
bWVrX2NvbmZpZ31gLgoKDQoFBAMCAAUSBM0BAggKDQoFBAMCAAESBM0BCQ0KDQoFBAMCAAMS
BM0BEBEKDQoFBAMCAAgSBM0BEjoKEAoIBAMCAAicCAASBM0BEzkKrAEKBAQDAgESBtEBAtYB
BBqbASBSZXF1aXJlZC4gS01TIGtleSByZXNvdXJjZSBuYW1lIHdoaWNoIHdpbGwgYmUgdXNl
ZCB0byBlbmNyeXB0IHJlc291cmNlcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5UmluZ30vY3J5cHRvS2V5cy97a2V5SWR9YC4KCg0K
BQQDAgEFEgTRAQIICg0KBQQDAgEBEgTRAQkQCg0KBQQDAgEDEgTRARMUCg8KBQQDAgEIEgbR
ARXWAQMKEAoIBAMCAQicCAASBNIBBCoKEQoHBAMCAQifCBIG0wEE1QEFCpMBCgQEAwICEgbb
AQLgAQQaggEgT3V0cHV0IG9ubHkuIEtNUyBrZXkgdmVyc2lvbiByZXNvdXJjZSBuYW1lIHdo
aWNoIHdpbGwgYmUgdXNlZCB0byBlbmNyeXB0CiByZXNvdXJjZXMKIGA8a21zX2tleT4vY3J5
cHRvS2V5VmVyc2lvbnMve2tleVZlcnNpb259YC4KCg0KBQQDAgIFEgTbAQIICg0KBQQDAgIB
EgTbAQkYCg0KBQQDAgIDEgTbARscCg8KBQQDAgIIEgbbAR3gAQMKEAoIBAMCAgicCAASBNwB
BC0KEQoHBAMCAgifCBIG3QEE3wEFCjoKBAQDAgMSBOMBAj4aLCBPdXRwdXQgb25seS4gVGhl
IHN0YXRlcyBvZiB0aGUgQ21la0NvbmZpZy4KCg0KBQQDAgMGEgTjAQIHCg0KBQQDAgMBEgTj
AQgNCg0KBQQDAgMDEgTjARARCg0KBQQDAgMIEgTjARI9ChAKCAQDAgMInAgAEgTjARM8CkUK
BAQDAgQSBOYBAkIaNyBPdXRwdXQgb25seS4gVGhlIGRlZmF1bHQgQ21la0NvbmZpZyBmb3Ig
dGhlIEN1c3RvbWVyLgoKDQoFBAMCBAUSBOYBAgYKDQoFBAMCBAESBOYBBxEKDQoFBAMCBAMS
BOYBFBUKDQoFBAMCBAgSBOYBFkEKEAoIBAMCBAicCAASBOYBF0AKRgoEBAMCBRIG6QEC6gEy
GjYgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgdGhlIGxhc3Qga2V5IHJvdGF0aW9u
LgoKDQoFBAMCBQUSBOkBAgcKDQoFBAMCBQESBOkBCCYKDQoFBAMCBQMSBOkBKSoKDQoFBAMC
BQgSBOoBBjEKEAoIBAMCBQicCAASBOoBBzAKWwoEBAMCBhIG7QEC7gEvGksgT3B0aW9uYWwu
IFNpbmdsZS1yZWdpb25hbCBDTUVLcyB0aGF0IGFyZSByZXF1aXJlZCBmb3Igc29tZSBWQUlT
IGZlYXR1cmVzLgoKDQoFBAMCBgQSBO0BAgoKDQoFBAMCBgYSBO0BCxoKDQoFBAMCBgESBO0B
Gy0KDQoFBAMCBgMSBO0BMDEKDQoFBAMCBggSBO4BBi4KEAoIBAMCBgicCAASBO4BBy0KUQoE
BAMCBxIG8QEC8gEyGkEgT3V0cHV0IG9ubHkuIFdoZXRoZXIgdGhlIE5vdGVib29rTE0gQ29y
cHVzIGlzIHJlYWR5IHRvIGJlIHVzZWQuCgoNCgUEAwIHBhIE8QECEQoNCgUEAwIHARIE8QES
IgoNCgUEAwIHAxIE8QElJgoNCgUEAwIHCBIE8gEGMQoQCggEAwIHCJwIABIE8gEHMAr5AQoC
BAQSBvkBAIACARrqASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUK
IFtDbWVrQ29uZmlnU2VydmljZS5VcGRhdGVDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkNtZWtDb25maWdTZXJ2aWNlLlVwZGF0ZUNtZWtDb25maWddCiBv
cGVyYXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMEBAESBPkBCCAKJgoEBAQCABIE
+wECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQEAgAGEgT7AQIbCg0KBQQEAgAB
EgT7ARwnCg0KBQQEAgADEgT7ASorCmQKBAQEAgESBP8BAiwaViBPcGVyYXRpb24gbGFzdCB1
cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhl
CiBmaW5pc2ggdGltZS4KCg0KBQQEAgEGEgT/AQIbCg0KBQQEAgEBEgT/ARwnCg0KBQQEAgED
EgT/ASorCpUBCgIEBRIGhQIAkwIBGoYBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDbWVrQ29u
ZmlnU2VydmljZS5MaXN0Q21la0NvbmZpZ3NdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuQ21la0NvbmZpZ1NlcnZpY2UuTGlzdENtZWtDb25maWdzXQogbWV0aG9kLgoKCwoD
BAUBEgSFAggeCs8CCgQEBQIAEgaNAgKSAgQavgIgUmVxdWlyZWQuIFRoZSBwYXJlbnQgbG9j
YXRpb24gcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1p
c3Npb24gdG8gbGlzdAogW0NtZWtDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuQ21la0NvbmZpZ11zIHVuZGVyIHRoaXMKIGxvY2F0aW9uLCByZWdhcmRsZXNzIG9m
IHdoZXRoZXIgb3Igbm90IGEgQ21la0NvbmZpZyBleGlzdHMsIGEKIFBFUk1JU1NJT05fREVO
SUVEIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAUCAAUSBI0CAggKDQoFBAUCAAESBI0CCQ8K
DQoFBAUCAAMSBI0CEhMKDwoFBAUCAAgSBo0CFJICAwoQCggEBQIACJwIABIEjgIEKgoRCgcE
BQIACJ8IEgaPAgSRAgUKlgEKAgQGEgaYAgCcAgEahwEgUmVzcG9uc2UgbWVzc2FnZSBmb3IK
IFtDbWVrQ29uZmlnU2VydmljZS5MaXN0Q21la0NvbmZpZ3NdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuQ21la0NvbmZpZ1NlcnZpY2UuTGlzdENtZWtDb25maWdzXQogbWV0
aG9kLgoKCwoDBAYBEgSYAggfCl4KBAQGAgASBJsCAicaUCBBbGwgdGhlIGN1c3RvbWVyJ3MK
IFtDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNtZWtDb25m
aWddcy4KCg0KBQQGAgAEEgSbAgIKCg0KBQQGAgAGEgSbAgsVCg0KBQQGAgABEgSbAhYiCg0K
BQQGAgADEgSbAiUmCpcBCgIEBxIGoQIAqwIBGogBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtD
bWVrQ29uZmlnU2VydmljZS5EZWxldGVDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLkNtZWtDb25maWdTZXJ2aWNlLkRlbGV0ZUNtZWtDb25maWddCiBtZXRo
b2QuCgoLCgMEBwESBKECCB8KyAEKBAQHAgASBqUCAqoCBBq3ASBSZXF1aXJlZC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlCiBbQ21la0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5DbWVrQ29uZmlnXSB0byBkZWxldGUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY21la0NvbmZpZ3Mve2NtZWtfY29uZmln
fWAuCgoNCgUEBwIABRIEpQICCAoNCgUEBwIAARIEpQIJDQoNCgUEBwIAAxIEpQIQEQoPCgUE
BwIACBIGpQISqgIDChAKCAQHAgAInAgAEgSmAgQqChEKBwQHAgAInwgSBqcCBKkCBQr5AQoC
BAgSBrECALgCARrqASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUK
IFtDbWVrQ29uZmlnU2VydmljZS5EZWxldGVDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkNtZWtDb25maWdTZXJ2aWNlLkRlbGV0ZUNtZWtDb25maWddCiBv
cGVyYXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMECAESBLECCCAKJgoEBAgCABIE
swICLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQIAgAGEgSzAgIbCg0KBQQIAgAB
EgSzAhwnCg0KBQQIAgADEgSzAiorCmQKBAQIAgESBLcCAiwaViBPcGVyYXRpb24gbGFzdCB1
cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhl
CiBmaW5pc2ggdGltZS4KCg0KBQQIAgEGEgS3AgIbCg0KBQQIAgEBEgS3AhwnCg0KBQQIAgED
EgS3AiorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest ===
    # Fields for UpdateCmekConfigRequest
    # Field: config Type: 11 (.google.cloud.discoveryengine.v1.CmekConfig)
    # Field: set_default Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::GetCmekConfigRequest ===
    # Fields for GetCmekConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::SingleRegionKey ===
    # Fields for SingleRegionKey
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig ===
    # Fields for CmekConfig
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()
    # Field: kms_key_version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1.CmekConfig.State)
    # Field: is_default Type: 8 ()
    # Field: last_rotation_timestamp_micros Type: 3 ()
    # Field: single_region_keys Type: 11 (.google.cloud.discoveryengine.v1.SingleRegionKey)
    # Field: notebooklm_state Type: 14 (.google.cloud.discoveryengine.v1.CmekConfig.NotebookLMState)

# Enum: CmekConfig::State
our $CmekConfig_STATE_UNSPECIFIED = 0;
our $CmekConfig_CREATING = 1;
our $CmekConfig_ACTIVE = 2;
our $CmekConfig_KEY_ISSUE = 3;
our $CmekConfig_DELETING = 4;
our $CmekConfig_DELETE_FAILED = 7;
our $CmekConfig_UNUSABLE = 5;
our $CmekConfig_ACTIVE_ROTATING = 6;
our $CmekConfig_DELETED = 8;
our $CmekConfig_EXPIRED = 9;

# Enum: CmekConfig::NotebookLMState
our $CmekConfig_NOTEBOOK_LM_STATE_UNSPECIFIED = 0;
our $CmekConfig_NOTEBOOK_LM_NOT_READY = 1;
our $CmekConfig_NOTEBOOK_LM_READY = 2;
our $CmekConfig_NOTEBOOK_LM_NOT_ENABLED = 3;

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigMetadata ===
    # Fields for UpdateCmekConfigMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsRequest ===
    # Fields for ListCmekConfigsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsResponse ===
    # Fields for ListCmekConfigsResponse
    # Field: cmek_configs Type: 11 (.google.cloud.discoveryengine.v1.CmekConfig)

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigRequest ===
    # Fields for DeleteCmekConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigMetadata ===
    # Fields for DeleteCmekConfigMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfigServiceClient

Client stub representing the remote C<CmekConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub update_cmek_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CmekConfigService',
        method         => 'UpdateCmekConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_cmek_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::CmekConfigService::GetCmekConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CmekConfigService',
        method         => 'GetCmekConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig',
    });
}

sub list_cmek_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CmekConfigService',
        method         => 'ListCmekConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsResponse',
    });
}

sub delete_cmek_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.CmekConfigService',
        method         => 'DeleteCmekConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::CmekConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/cmek_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::CmekConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest->new({
        config => $config,
        set_default => $set_default,
    });

    # Read or update a field
    my $val = $msg->config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/cmek_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest

Request message for UpdateCmekConfig method.
rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig>)

Required. The CmekConfig resource.

=item * C<< $msg->set_default() >> / C<< $msg->set_default($value) >>

Type: C<Bool>

Set the following CmekConfig as the default to be used for child
resources if one is not specified.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::GetCmekConfigRequest

Request message for GetCmekConfigRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of
[CmekConfig][google.cloud.discoveryengine.v1.CmekConfig], such as
`projects/*/locations/*/cmekConfig` or
`projects/*/locations/*/cmekConfigs/*`.

If the caller does not have permission to access the
[CmekConfig][google.cloud.discoveryengine.v1.CmekConfig], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::SingleRegionKey

Metadata for single-regional CMEKs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Required. Single-regional kms key resource name which will be used to
encrypt resources
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{keyId}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig

Configurations used to enable CMEK data encryption with Cloud KMS keys.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the CmekConfig of the form
`projects/{project}/locations/{location}/cmekConfig` or
`projects/{project}/locations/{location}/cmekConfigs/{cmek_config}`.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Required. KMS key resource name which will be used to encrypt resources
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{keyId}`.

=item * C<< $msg->kms_key_version() >> / C<< $msg->kms_key_version($value) >>

Type: C<String>

Output only. KMS key version resource name which will be used to encrypt
resources
`<kms_key>/cryptoKeyVersions/{keyVersion}`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::CmekConfig::State>)

Output only. The states of the CmekConfig.

=item * C<< $msg->is_default() >> / C<< $msg->is_default($value) >>

Type: C<Bool>

Output only. The default CmekConfig for the Customer.

=item * C<< $msg->last_rotation_timestamp_micros() >> / C<< $msg->last_rotation_timestamp_micros($value) >>

Type: C<Int64>

Output only. The timestamp of the last key rotation.

=item * C<< $msg->single_region_keys() >> / C<< $msg->single_region_keys($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::CmekConfigService::SingleRegionKey>)

Optional. Single-regional CMEKs that are required for some VAIS features.

=item * C<< $msg->notebooklm_state() >> / C<< $msg->notebooklm_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::CmekConfig::NotebookLMState>)

Output only. Whether the NotebookLM Corpus is ready to be used.

=back

=head3 Enum: CmekConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<KEY_ISSUE> => C<3>

=item * C<DELETING> => C<4>

=item * C<DELETE_FAILED> => C<7>

=item * C<UNUSABLE> => C<5>

=item * C<ACTIVE_ROTATING> => C<6>

=item * C<DELETED> => C<8>

=item * C<EXPIRED> => C<9>

=back

=head3 Enum: CmekConfig::NotebookLMState

=over 4

=item * C<NOTEBOOK_LM_STATE_UNSPECIFIED> => C<0>

=item * C<NOTEBOOK_LM_NOT_READY> => C<1>

=item * C<NOTEBOOK_LM_READY> => C<2>

=item * C<NOTEBOOK_LM_NOT_ENABLED> => C<3>

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigMetadata

Metadata related to the progress of the
[CmekConfigService.UpdateCmekConfig][google.cloud.discoveryengine.v1.CmekConfigService.UpdateCmekConfig]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsRequest

Request message for
[CmekConfigService.ListCmekConfigs][google.cloud.discoveryengine.v1.CmekConfigService.ListCmekConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location resource name, such as
`projects/{project}/locations/{location}`.

If the caller does not have permission to list
[CmekConfig][google.cloud.discoveryengine.v1.CmekConfig]s under this
location, regardless of whether or not a CmekConfig exists, a
PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsResponse

Response message for
[CmekConfigService.ListCmekConfigs][google.cloud.discoveryengine.v1.CmekConfigService.ListCmekConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cmek_configs() >> / C<< $msg->cmek_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig>)

All the customer's
[CmekConfig][google.cloud.discoveryengine.v1.CmekConfig]s.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigRequest

Request message for
[CmekConfigService.DeleteCmekConfig][google.cloud.discoveryengine.v1.CmekConfigService.DeleteCmekConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[CmekConfig][google.cloud.discoveryengine.v1.CmekConfig] to delete, such as
`projects/{project}/locations/{location}/cmekConfigs/{cmek_config}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigMetadata

Metadata related to the progress of the
[CmekConfigService.DeleteCmekConfig][google.cloud.discoveryengine.v1.CmekConfigService.DeleteCmekConfig]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::CmekConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
