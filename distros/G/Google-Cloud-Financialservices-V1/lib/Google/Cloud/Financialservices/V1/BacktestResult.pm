package Google::Cloud::Financialservices::V1::BacktestResult;

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
    eval { require Google::Cloud::Financialservices::V1::BigqueryDestination };
    eval { require Google::Cloud::Financialservices::V1::LineOfBusiness };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvYmFja3Rlc3RfcmVzdWx0LnBy
b3RvEiFnb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aPGdvb2dsZS9j
bG91ZC9maW5hbmNpYWxzZXJ2aWNlcy92MS9iaWdxdWVyeV9kZXN0aW5hdGlvbi5wcm90bxo4
Z29vZ2xlL2Nsb3VkL2ZpbmFuY2lhbHNlcnZpY2VzL3YxL2xpbmVfb2ZfYnVzaW5lc3MucHJv
dG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvIsMJCg5CYWNrdGVzdFJlc3VsdBIXCgRuYW1lGAEgASgJQgPgQQNS
BG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSVQoGbGFiZWxzGAQgAygLMj0uZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkJhY2t0ZXN0UmVzdWx0LkxhYmVsc0VudHJ5
UgZsYWJlbHMSUgoFc3RhdGUYBSABKA4yNy5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2Vydmlj
ZXMudjEuQmFja3Rlc3RSZXN1bHQuU3RhdGVCA+BBA1IFc3RhdGUSSgoHZGF0YXNldBgGIAEo
CUIw4EEC+kEqCihmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9EYXRhc2V0Ugdk
YXRhc2V0EkQKBW1vZGVsGAcgASgJQi7gQQL6QSgKJmZpbmFuY2lhbHNlcnZpY2VzLmdvb2ds
ZWFwaXMuY29tL01vZGVsUgVtb2RlbBI6CghlbmRfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBAlIHZW5kVGltZRIpChBiYWNrdGVzdF9wZXJpb2RzGAogASgF
Ug9iYWNrdGVzdFBlcmlvZHMSdwoScGVyZm9ybWFuY2VfdGFyZ2V0GAsgASgLMkMuZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkJhY2t0ZXN0UmVzdWx0LlBlcmZvcm1hbmNl
VGFyZ2V0QgPgQQJSEXBlcmZvcm1hbmNlVGFyZ2V0EmAKEGxpbmVfb2ZfYnVzaW5lc3MYDCAB
KA4yMS5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuTGluZU9mQnVzaW5lc3NC
A+BBA1IObGluZU9mQnVzaW5lc3MaaAoRUGVyZm9ybWFuY2VUYXJnZXQSUwokcGFydHlfaW52
ZXN0aWdhdGlvbnNfcGVyX3BlcmlvZF9oaW50GAEgASgDQgPgQQJSIHBhcnR5SW52ZXN0aWdh
dGlvbnNQZXJQZXJpb2RIaW50GjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiVAoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQ
ABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEgwKCFVQREFUSU5HEAMSDAoIREVMRVRJTkcQ
BDqZAepBlQEKL2ZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0JhY2t0ZXN0UmVz
dWx0EmJwcm9qZWN0cy97cHJvamVjdF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3Rh
bmNlcy97aW5zdGFuY2V9L2JhY2t0ZXN0UmVzdWx0cy97YmFja3Rlc3RfcmVzdWx0fSLWAQoa
TGlzdEJhY2t0ZXN0UmVzdWx0c1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWZp
bmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgZwYXJlbnQSGwoJcGFn
ZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4S
FgoGZmlsdGVyGAQgASgJUgZmaWx0ZXISGQoIb3JkZXJfYnkYBSABKAlSB29yZGVyQnkixQEK
G0xpc3RCYWNrdGVzdFJlc3VsdHNSZXNwb25zZRJcChBiYWNrdGVzdF9yZXN1bHRzGAEgAygL
MjEuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkJhY2t0ZXN0UmVzdWx0Ug9i
YWNrdGVzdFJlc3VsdHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
EiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJnChhHZXRCYWNrdGVzdFJlc3Vs
dFJlcXVlc3QSSwoEbmFtZRgBIAEoCUI34EEC+kExCi9maW5hbmNpYWxzZXJ2aWNlcy5nb29n
bGVhcGlzLmNvbS9CYWNrdGVzdFJlc3VsdFIEbmFtZSKgAgobQ3JlYXRlQmFja3Rlc3RSZXN1
bHRSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx4EEC+kErCilmaW5hbmNpYWxzZXJ2aWNlcy5n
b29nbGVhcGlzLmNvbS9JbnN0YW5jZVIGcGFyZW50EjEKEmJhY2t0ZXN0X3Jlc3VsdF9pZBgC
IAEoCUID4EECUhBiYWNrdGVzdFJlc3VsdElkEl8KD2JhY2t0ZXN0X3Jlc3VsdBgDIAEoCzIx
Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5CYWNrdGVzdFJlc3VsdEID4EEC
Ug5iYWNrdGVzdFJlc3VsdBIiCgpyZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJlcXVlc3RJZCLk
AQobVXBkYXRlQmFja3Rlc3RSZXN1bHRSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhou
Z29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrEl8KD2JhY2t0ZXN0
X3Jlc3VsdBgCIAEoCzIxLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5CYWNr
dGVzdFJlc3VsdEID4EECUg5iYWNrdGVzdFJlc3VsdBIiCgpyZXF1ZXN0X2lkGAMgASgJQgPg
QQFSCXJlcXVlc3RJZCKOAQobRGVsZXRlQmFja3Rlc3RSZXN1bHRSZXF1ZXN0EksKBG5hbWUY
ASABKAlCN+BBAvpBMQovZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vQmFja3Rl
c3RSZXN1bHRSBG5hbWUSIgoKcmVxdWVzdF9pZBgCIAEoCUID4EEBUglyZXF1ZXN0SWQijQIK
I0V4cG9ydEJhY2t0ZXN0UmVzdWx0TWV0YWRhdGFSZXF1ZXN0EmAKD2JhY2t0ZXN0X3Jlc3Vs
dBgBIAEoCUI34EEC+kExCi9maW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9CYWNr
dGVzdFJlc3VsdFIOYmFja3Rlc3RSZXN1bHQSgwEKH3N0cnVjdHVyZWRfbWV0YWRhdGFfZGVz
dGluYXRpb24YAiABKAsyNi5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuQmln
UXVlcnlEZXN0aW5hdGlvbkID4EECUh1zdHJ1Y3R1cmVkTWV0YWRhdGFEZXN0aW5hdGlvbiIm
CiRFeHBvcnRCYWNrdGVzdFJlc3VsdE1ldGFkYXRhUmVzcG9uc2VCggIKJWNvbS5nb29nbGUu
Y2xvdWQuZmluYW5jaWFsc2VydmljZXMudjFCE0JhY2t0ZXN0UmVzdWx0UHJvdG9QAVpTY2xv
dWQuZ29vZ2xlLmNvbS9nby9maW5hbmNpYWxzZXJ2aWNlcy9hcGl2MS9maW5hbmNpYWxzZXJ2
aWNlc3BiO2ZpbmFuY2lhbHNlcnZpY2VzcGKqAiFHb29nbGUuQ2xvdWQuRmluYW5jaWFsU2Vy
dmljZXMuVjHKAiFHb29nbGVcQ2xvdWRcRmluYW5jaWFsU2VydmljZXNcVjHqAiRHb29nbGU6
OkNsb3VkOjpGaW5hbmNpYWxTZXJ2aWNlczo6VjFK/lMKBxIFDgCjAi8KvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUAEYKCQoCAwMSAxUAQgoJCgIDBBIDFgAqCgkKAgMFEgMXACkKCAoBCBIDGQA+
CgkKAgglEgMZAD4KCAoBCBIDGgBqCgkKAggLEgMaAGoKCAoBCBIDGwAiCgkKAggKEgMbACIK
CAoBCBIDHAA0CgkKAggIEgMcADQKCAoBCBIDHQA+CgkKAggBEgMdAD4KCAoBCBIDHgA+CgkK
AggpEgMeAD4KCAoBCBIDHwA9CgkKAggtEgMfAD0KWQoCBAASBSIAggEBGkwgQmFja3Rlc3RS
ZXN1bHQgaXMgY3JlYXRlZCB0byB0ZXN0IHRoZSBwZXJmb3JtYW5jZSBvZiBhIG1vZGVsIG9u
IGEgZGF0YXNldC4KCgoKAwQAARIDIggWCgsKAwQABxIEIwImBAoNCgUEAAedCBIEIwImBApd
CgQEAAMAEgQqAjMDGk8gUGVyZm9ybWFuY2VUYXJnZXQgZ2l2ZXMgaGludHMgb24gaG93IHRv
IGV2YWx1YXRlIHRoZSBwZXJmb3JtYW5jZSBvZiBhCiBtb2RlbC4KCgwKBQQAAwABEgMqChsK
mQMKBgQAAwACABIEMQQyMRqIAyBSZXF1aXJlZC4gQSBudW1iZXIgdGhhdCBnaXZlcyB0aGUg
dHVuZXIgYSBoaW50IG9uIHRoZSBudW1iZXIgb2YgcGFydGllcwogZnJvbSB0aGlzIGRhdGEg
dGhhdCB3aWxsIGJlIGludmVzdGlnYXRlZCBwZXIgcGVyaW9kIChtb250aGx5KS4gVGhpcyBp
cwogdXNlZCB0byBjb250cm9sIGhvdyB0aGUgbW9kZWwgaXMgZXZhbHVhdGVkLiBGb3IgZXhh
bXBsZSwgd2hlbiB0cnlpbmcgQU1MCiBBSSBmb3IgdGhlIGZpcnN0IHRpbWUsIHdlIHJlY29t
bWVuZCBzZXR0aW5nIHRoaXMgdG8gdGhlIG51bWJlciBvZiBwYXJ0aWVzCiBpbnZlc3RpZ2F0
ZWQgaW4gYW4gYXZlcmFnZSBtb250aCwgYmFzZWQgb24gYWxlcnRzIGZyb20geW91ciBleGlz
dGluZwogYXV0b21hdGVkIGFsZXJ0aW5nIHN5c3RlbS4KCg4KBwQAAwACAAUSAzEECQoOCgcE
AAMAAgABEgMxCi4KDgoHBAADAAIAAxIDMTEyCg4KBwQAAwACAAgSAzIIMAoRCgoEAAMAAgAI
nAgAEgMyCS8KMgoEBAAEABIENgJFAxokIFRoZSBwb3NzaWJsZSBzdGF0ZXMgb2YgYSByZXNv
dXJjZS4KCgwKBQQABAABEgM2BwwKOAoGBAAEAAIAEgM4BBoaKSBTdGF0ZSBpcyB1bnNwZWNp
ZmllZCwgc2hvdWxkIG5vdCBvY2N1ci4KCg4KBwQABAACAAESAzgEFQoOCgcEAAQAAgACEgM4
GBkKPQoGBAAEAAIBEgM7BBEaLiBUaGUgcmVzb3VyY2UgaGFzIG5vdCBmaW5pc2hlZCBiZWlu
ZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDOwQMCg4KBwQABAACAQISAzsPEAo5CgYEAAQAAgIS
Az4EDxoqIFRoZSByZXNvdXJjZSBpcyBhY3RpdmUvcmVhZHkgdG8gYmUgdXNlZC4KCg4KBwQA
BAACAgESAz4ECgoOCgcEAAQAAgICEgM+DQ4KQQoGBAAEAAIDEgNBBBEaMiBUaGUgcmVzb3Vy
Y2UgaXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAACAwESA0EE
DAoOCgcEAAQAAgMCEgNBDxAKQQoGBAAEAAIEEgNEBBEaMiBUaGUgcmVzb3VyY2UgaXMgaW4g
dGhlIHByb2Nlc3Mgb2YgYmVpbmcgZGVsZXRlZC4KCg4KBwQABAACBAESA0QEDAoOCgcEAAQA
AgQCEgNEDxAKtQEKBAQAAgASA0oCPhqnASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIEJhY2t0ZXN0UmVzdWx0LgogZm9ybWF0OgogYC9wcm9qZWN0cy97cHJvamVj
dF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2JhY2t0
ZXN0UmVzdWx0cy97YmFja3Rlc3RfcmVzdWx0fWAKCgwKBQQAAgAFEgNKAggKDAoFBAACAAES
A0oJDQoMCgUEAAIAAxIDShARCgwKBQQAAgAIEgNKEj0KDwoIBAACAAicCAASA0oTPApICgQE
AAIBEgRNAk4yGjogT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgY3JlYXRpb24gb2Yg
dGhpcyByZXNvdXJjZS4KCgwKBQQAAgEGEgNNAhsKDAoFBAACAQESA00cJwoMCgUEAAIBAxID
TSorCgwKBQQAAgEIEgNOBjEKDwoIBAACAQicCAASA04HMApWCgQEAAICEgRRAlIyGkggT3V0
cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgdGhlIG1vc3QgcmVjZW50IHVwZGF0ZSBvZiB0
aGlzIHJlc291cmNlLgoKDAoFBAACAgYSA1ECGwoMCgUEAAICARIDURwnCgwKBQQAAgIDEgNR
KisKDAoFBAACAggSA1IGMQoPCggEAAICCJwIABIDUgcwChUKBAQAAgMSA1UCIRoIIExhYmVs
cwoKDAoFBAACAwYSA1UCFQoMCgUEAAIDARIDVRYcCgwKBQQAAgMDEgNVHyAKWgoEBAACBBID
WAI+Gk0gT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBCYWNrdGVzdFJlc3VsdCAoY3JlYXRp
bmcsIGFjdGl2ZSwgZGVsZXRpbmcsIGV0Yy4pCgoMCgUEAAIEBhIDWAIHCgwKBQQAAgQBEgNY
CA0KDAoFBAACBAMSA1gQEQoMCgUEAAIECBIDWBI9Cg8KCAQAAgQInAgAEgNYEzwKqwEKBAQA
AgUSBF0CYgQanAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBEYXRhc2V0
IHRvIGJhY2t0ZXN0IG9uCiBGb3JtYXQ6CiBgL3Byb2plY3RzL3twcm9qZWN0X251bX0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vZGF0YXNldHMve2RhdGFz
ZXR9YAoKDAoFBAACBQUSA10CCAoMCgUEAAIFARIDXQkQCgwKBQQAAgUDEgNdExQKDQoFBAAC
BQgSBF0VYgMKDwoIBAACBQicCAASA14EKgoPCgcEAAIFCJ8IEgRfBGEFCq0BCgQEAAIGEgRn
AmwEGp4BIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgTW9kZWwgdG8gdXNl
IG9yIHRvIGJhY2t0ZXN0LgogRm9ybWF0OgogYC9wcm9qZWN0cy97cHJvamVjdF9udW19L2xv
Y2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L21vZGVscy97bW9kZWx9
YAoKDAoFBAACBgUSA2cCCAoMCgUEAAIGARIDZwkOCgwKBQQAAgYDEgNnERIKDQoFBAACBggS
BGcTbAMKDwoIBAACBgicCAASA2gEKgoPCgcEAAIGCJ8IEgRpBGsFCvABCgQEAAIHEgRxAnIv
GuEBIFJlcXVpcmVkLiBFbmRfdGltZSBzcGVjaWZpZXMgdGhlIGxhdGVzdCB0aW1lIGZyb20g
d2hpY2ggbGFiZWxzIGFyZSB1c2VkIGFuZAogZnJvbSB3aGljaCBkYXRhIGlzIHVzZWQgdG8g
Z2VuZXJhdGUgZmVhdHVyZXMgZm9yIGJhY2t0ZXN0aW5nLiAgRW5kX3RpbWUKIHNob3VsZCBi
ZSBubyBsYXRlciB0aGFuIHRoZSBlbmQgb2YgdGhlIGRhdGVfcmFuZ2Ugb2YgdGhlIHByaW1h
cnkgZGF0YXNldC4KCgwKBQQAAgcGEgNxAhsKDAoFBAACBwESA3EcJAoMCgUEAAIHAxIDcSco
CgwKBQQAAgcIEgNyBi4KDwoIBAACBwicCAASA3IHLQqpAQoEBAACCBIDdwIeGpsBIFRoZSBu
dW1iZXIgb2YgY29uc2VjdXRpdmUgbW9udGhzIHRvIGNvbmR1Y3QgYmFja3Rlc3RpbmcgZm9y
LCBlbmRpbmcgd2l0aAogdGhlIGxhc3QgZnVsbCBtb250aCBwcmlvciB0byB0aGUgZW5kX3Rp
bWUgYWNjb3JkaW5nIHRvIHRoZSBkYXRhc2V0J3MKIHRpbWV6b25lLgoKDAoFBAACCAUSA3cC
BwoMCgUEAAIIARIDdwgYCgwKBQQAAggDEgN3Gx0KYQoEBAACCRIEewJ8LxpTIFJlcXVpcmVk
LiBQZXJmb3JtYW5jZVRhcmdldCBnaXZlcyBpbmZvcm1hdGlvbiBvbiBob3cgdGhlIHRlc3Qg
d2lsbCBiZQogZXZhbHVhdGVkLgoKDAoFBAACCQYSA3sCEwoMCgUEAAIJARIDexQmCgwKBQQA
AgkDEgN7KSsKDAoFBAACCQgSA3wGLgoPCggEAAIJCJwIABIDfActCooBCgQEAAIKEgaAAQKB
ATIaeiBPdXRwdXQgb25seS4gVGhlIGxpbmUgb2YgYnVzaW5lc3MgKFJldGFpbC9Db21tZXJj
aWFsKSB0aGlzIGJhY2t0ZXN0IGlzIGZvci4KIERldGVybWluZWQgYnkgTW9kZWwsIGNhbm5v
dCBiZSBzZXQgYnkgdXNlci4KCg0KBQQAAgoGEgSAAQIQCg0KBQQAAgoBEgSAAREhCg0KBQQA
AgoDEgSAASQmCg0KBQQAAgoIEgSBAQYxChAKCAQAAgoInAgAEgSBAQcwCnYKAgQBEgaGAQCg
AQEaaCBSZXF1ZXN0IGZvciByZXRyaWV2aW5nIGEgcGFnaW5hdGVkIGxpc3Qgb2YgQmFja3Rl
c3RSZXN1bHQgcmVzb3VyY2VzIHRoYXQKIG1lZXQgdGhlIHNwZWNpZmllZCBjcml0ZXJpYS4K
CgsKAwQBARIEhgEIIgpNCgQEAQIAEgaIAQKNAQQaPSBSZXF1aXJlZC4gVGhlIHBhcmVudCBv
ZiB0aGUgQmFja3Rlc3RSZXN1bHQgaXMgdGhlIEluc3RhbmNlLgoKDQoFBAECAAUSBIgBAggK
DQoFBAECAAESBIgBCQ8KDQoFBAECAAMSBIgBEhMKDwoFBAECAAgSBogBFI0BAwoQCggEAQIA
CJwIABIEiQEEKgoRCgcEAQIACJ8IEgaKAQSMAQUKrQEKBAQBAgESBJIBAhYangEgVGhlIG51
bWJlciBvZiByZXNvdXJjZXMgdG8gYmUgaW5jbHVkZWQgaW4gdGhlIHJlc3BvbnNlLiBUaGUg
cmVzcG9uc2UKIGNvbnRhaW5zIGEgbmV4dF9wYWdlX3Rva2VuLCB3aGljaCBjYW4gYmUgdXNl
ZCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mCiByZXNvdXJjZXMuCgoNCgUEAQIBBRIE
kgECBwoNCgUEAQIBARIEkgEIEQoNCgUEAQIBAxIEkgEUFQq1AgoEBAECAhIEmQECGBqmAiBJ
biBjYXNlIG9mIHBhZ2luYXRlZCByZXN1bHRzLCB0aGlzIGlzIHRoZSB0b2tlbiB0aGF0IHdh
cyByZXR1cm5lZCBpbiB0aGUKIHByZXZpb3VzIExpc3RCYWNrdGVzdFJlc3VsdHNSZXNwb25z
ZS4gSXQgc2hvdWxkIGJlIGNvcGllZCBoZXJlIHRvCiByZXRyaWV2ZSB0aGUgbmV4dCBwYWdl
IG9mIHJlc291cmNlcy4gRW1wdHkgd2lsbCBnaXZlIHRoZSBmaXJzdCBwYWdlIG9mCiBMaXN0
QmFja3Rlc3RSZXN1bHRzUmVxdWVzdCwgYW5kIHRoZSBsYXN0IHBhZ2Ugd2lsbCByZXR1cm4g
YW4gZW1wdHkKIHBhZ2VfdG9rZW4uCgoNCgUEAQICBRIEmQECCAoNCgUEAQICARIEmQEJEwoN
CgUEAQICAxIEmQEWFwo6CgQEAQIDEgScAQIUGiwgU3BlY2lmeSBhIGZpbHRlciB0byBuYXJy
b3cgc2VhcmNoIHJlc3VsdHMuCgoNCgUEAQIDBRIEnAECCAoNCgUEAQIDARIEnAEJDwoNCgUE
AQIDAxIEnAESEwo0CgQEAQIEEgSfAQIWGiYgU3BlY2lmeSBhIGZpZWxkIHRvIHVzZSBmb3Ig
b3JkZXJpbmcuCgoNCgUEAQIEBRIEnwECCAoNCgUEAQIEARIEnwEJEQoNCgUEAQIEAxIEnwEU
FQpBCgIEAhIGowEArgEBGjMgUmVzcG9uc2UgZm9yIHJldHJpZXZpbmcgYSBsaXN0IG9mIEJh
Y2t0ZXN0UmVzdWx0cwoKCwoDBAIBEgSjAQgjCjAKBAQCAgASBKUBAi8aIiBMaXN0IG9mIEJh
Y2t0ZXN0UmVzdWx0IHJlc291cmNlcwoKDQoFBAICAAQSBKUBAgoKDQoFBAICAAYSBKUBCxkK
DQoFBAICAAESBKUBGioKDQoFBAICAAMSBKUBLS4KoQEKBAQCAgESBKoBAh0akgEgVGhpcyB0
b2tlbiBzaG91bGQgYmUgcGFzc2VkIHRvIHRoZSBuZXh0IExpc3RCYWNrdGVzdFJlc3VsdHNS
ZXF1ZXN0IHRvCiByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIEJhY2t0ZXN0UmVzdWx0cyAo
ZW1wdHkgaW5kaWNhdGVzIHdlIGFyZQogZG9uZSkuCgoNCgUEAgIBBRIEqgECCAoNCgUEAgIB
ARIEqgEJGAoNCgUEAgIBAxIEqgEbHAo0CgQEAgICEgStAQIiGiYgTG9jYXRpb25zIHRoYXQg
Y291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAgICBBIErQECCgoNCgUEAgICBRIErQELEQoN
CgUEAgICARIErQESHQoNCgUEAgICAxIErQEgIQpKCgIEAxIGsQEAuQEBGjwgUmVxdWVzdCBm
b3IgcmV0cmlldmluZyBhIHNwZWNpZmljIEJhY2t0ZXN0UmVzdWx0IHJlc291cmNlLgoKCwoD
BAMBEgSxAQggCkMKBAQDAgASBrMBArgBBBozIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgQmFja3Rlc3RSZXN1bHQKCg0KBQQDAgAFEgSzAQIICg0KBQQDAgABEgSzAQkN
Cg0KBQQDAgADEgSzARARCg8KBQQDAgAIEgazARK4AQMKEAoIBAMCAAicCAASBLQBBCoKEQoH
BAMCAAifCBIGtQEEtwEFCj8KAgQEEga8AQDZAQEaMSBSZXF1ZXN0IGZvciBjcmVhdGluZyBh
IEJhY2t0ZXN0UmVzdWx0IHJlc291cmNlLgoKCwoDBAQBEgS8AQgjCk0KBAQEAgASBr4BAsMB
BBo9IFJlcXVpcmVkLiBUaGUgcGFyZW50IG9mIHRoZSBCYWNrdGVzdFJlc3VsdCBpcyB0aGUg
SW5zdGFuY2UuCgoNCgUEBAIABRIEvgECCAoNCgUEBAIAARIEvgEJDwoNCgUEBAIAAxIEvgES
EwoPCgUEBAIACBIGvgEUwwEDChAKCAQEAgAInAgAEgS/AQQqChEKBwQEAgAInwgSBsABBMIB
BQo/CgQEBAIBEgTGAQJJGjEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBpZCBvZiB0aGUgQmFj
a3Rlc3RSZXN1bHQKCg0KBQQEAgEFEgTGAQIICg0KBQQEAgEBEgTGAQkbCg0KBQQEAgEDEgTG
AR4fCg0KBQQEAgEIEgTGASBIChAKCAQEAgEInAgAEgTGASFHCkIKBAQEAgISBMkBAk4aNCBS
ZXF1aXJlZC4gVGhlIEJhY2t0ZXN0UmVzdWx0IHRoYXQgd2lsbCBiZSBjcmVhdGVkLgoKDQoF
BAQCAgYSBMkBAhAKDQoFBAQCAgESBMkBESAKDQoFBAQCAgMSBMkBIyQKDQoFBAQCAggSBMkB
JU0KEAoIBAQCAgicCAASBMkBJkwKjwYKBAQEAgMSBNgBAkEagAYgT3B0aW9uYWwuIEFuIG9w
dGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlx
dWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3Qs
IHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFz
IGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRo
YXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgog
Rm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGlu
aXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2Ug
dGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZl
ciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVz
dCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQg
cmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVh
dGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBh
IHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qg
c3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoF
BAQCAwUSBNgBAggKDQoFBAQCAwESBNgBCRMKDQoFBAQCAwMSBNgBFhcKDQoFBAQCAwgSBNgB
GEAKEAoIBAQCAwicCAASBNgBGT8KNQoCBAUSBtwBAPcBARonIFJlcXVlc3QgZm9yIHVwZGF0
aW5nIGEgQmFja3Rlc3RSZXN1bHQKCgsKAwQFARIE3AEIIwrgAgoEBAUCABIG4gEC4wEvGs8C
IE9wdGlvbmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRv
IGJlIG92ZXJ3cml0dGVuIGluIHRoZQogQmFja3Rlc3RSZXN1bHQgcmVzb3VyY2UgYnkgdGhl
IHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUg
cmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmll
bGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgdGhlCiB1
c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZpZWxkcyB3aWxsIGJlIG92
ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBOIBAhsKDQoFBAUCAAESBOIBHCcKDQoFBAUCAAMSBOIB
KisKDQoFBAUCAAgSBOMBBi4KEAoIBAUCAAicCAASBOMBBy0KeAoEBAUCARIE5wECThpqIFJl
cXVpcmVkLiBUaGUgbmV3IHZhbHVlIG9mIHRoZSBCYWNrdGVzdFJlc3VsdCBmaWVsZHMgdGhh
dCB3aWxsIGJlIHVwZGF0ZWQKIGFjY29yZGluZyB0byB0aGUgdXBkYXRlX21hc2suCgoNCgUE
BQIBBhIE5wECEAoNCgUEBQIBARIE5wERIAoNCgUEBQIBAxIE5wEjJAoNCgUEBQIBCBIE5wEl
TQoQCggEBQIBCJwIABIE5wEmTAqPBgoEBAUCAhIE9gECQRqABiBPcHRpb25hbC4gQW4gb3B0
aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1
ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwg
dGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMg
YWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUgdGhh
dCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBG
b3IgZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5p
dGlhbCByZXF1ZXN0IGFuZCB0aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0
aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVy
IGNhbiBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0
IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCBy
ZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0
aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEg
dmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBz
dXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUE
BQICBRIE9gECCAoNCgUEBQICARIE9gEJEwoNCgUEBQICAxIE9gEWFwoNCgUEBQICCBIE9gEY
QAoQCggEBQICCJwIABIE9gEZPwo2CgIEBhIG+gEAkQIBGiggUmVxdWVzdCBmb3IgZGVsZXRp
bmcgYSBCYWNrdGVzdFJlc3VsdC4KCgsKAwQGARIE+gEIIwpECgQEBgIAEgb8AQKBAgQaNCBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEJhY2t0ZXN0UmVzdWx0LgoKDQoF
BAYCAAUSBPwBAggKDQoFBAYCAAESBPwBCQ0KDQoFBAYCAAMSBPwBEBEKDwoFBAYCAAgSBvwB
EoECAwoQCggEBgIACJwIABIE/QEEKgoRCgcEBgIACJ8IEgb+AQSAAgUKjwYKBAQGAgESBJAC
AkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVx
dWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVz
dCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUg
dGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2
ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgYWZ0ZXIg
dGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9u
IHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRp
bWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSBy
ZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9u
IHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdp
bGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBm
cm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhl
IHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRo
YXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAw
MC0wMDAwMDAwMDAwMDApLgoKDQoFBAYCAQUSBJACAggKDQoFBAYCAQESBJACCRMKDQoFBAYC
AQMSBJACFhcKDQoFBAYCAQgSBJACGEAKEAoIBAYCAQicCAASBJACGT8KPgoCBAcSBpQCAKAC
ARowIFJlcXVlc3QgZm9yIGV4cG9ydGluZyBCYWNrdGVzdFJlc3VsdCBtZXRhZGF0YS4KCgsK
AwQHARIElAIIKwpECgQEBwIAEgaWAgKbAgQaNCBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIEJhY2t0ZXN0UmVzdWx0LgoKDQoFBAcCAAUSBJYCAggKDQoFBAcCAAESBJYC
CRgKDQoFBAcCAAMSBJYCGxwKDwoFBAcCAAgSBpYCHZsCAwoQCggEBwIACJwIABIElwIEKgoR
CgcEBwIACJ8IEgaYAgSaAgUKTwoEBAcCARIGngICnwIvGj8gUmVxdWlyZWQuIEJpZ1F1ZXJ5
IG91dHB1dCB3aGVyZSB0aGUgbWV0YWRhdGEgd2lsbCBiZSB3cml0dGVuLgoKDQoFBAcCAQYS
BJ4CAhUKDQoFBAcCAQESBJ4CFjUKDQoFBAcCAQMSBJ4CODkKDQoFBAcCAQgSBJ8CBi4KEAoI
BAcCAQicCAASBJ8CBy0KPQoCBAgSBKMCAC8aMSBSZXNwb25zZSBmb3IgZXhwb3J0aW5nIEJh
Y2t0ZXN0UmVzdWx0IG1ldGFkYXRhLgoKCwoDBAgBEgSjAggsYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult ===
    # Fields for BacktestResult
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.financialservices.v1.BacktestResult.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.financialservices.v1.BacktestResult.State)
    # Field: dataset Type: 9 ()
    # Field: model Type: 9 ()
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: backtest_periods Type: 5 ()
    # Field: performance_target Type: 11 (.google.cloud.financialservices.v1.BacktestResult.PerformanceTarget)
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)

# Enum: BacktestResult::State
our $BacktestResult_STATE_UNSPECIFIED = 0;
our $BacktestResult_CREATING = 1;
our $BacktestResult_ACTIVE = 2;
our $BacktestResult_UPDATING = 3;
our $BacktestResult_DELETING = 4;

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsRequest ===
    # Fields for ListBacktestResultsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsResponse ===
    # Fields for ListBacktestResultsResponse
    # Field: backtest_results Type: 11 (.google.cloud.financialservices.v1.BacktestResult)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::GetBacktestResultRequest ===
    # Fields for GetBacktestResultRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::CreateBacktestResultRequest ===
    # Fields for CreateBacktestResultRequest
    # Field: parent Type: 9 ()
    # Field: backtest_result_id Type: 9 ()
    # Field: backtest_result Type: 11 (.google.cloud.financialservices.v1.BacktestResult)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::UpdateBacktestResultRequest ===
    # Fields for UpdateBacktestResultRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: backtest_result Type: 11 (.google.cloud.financialservices.v1.BacktestResult)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::DeleteBacktestResultRequest ===
    # Fields for DeleteBacktestResultRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataRequest ===
    # Fields for ExportBacktestResultMetadataRequest
    # Field: backtest_result Type: 9 ()
    # Field: structured_metadata_destination Type: 11 (.google.cloud.financialservices.v1.BigQueryDestination)

# === Message: Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataResponse ===
    # Fields for ExportBacktestResultMetadataResponse

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::BacktestResult - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/backtest_result.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::BacktestResult;

    my $msg = Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/backtest_result.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult

BacktestResult is created to test the performance of a model on a dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the BacktestResult.
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/backtestResults/{backtest_result}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of creation of this resource.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of the most recent update of this resource.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::LabelsEntry>)

Labels

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::BacktestResult::State>)

Output only. State of the BacktestResult (creating, active, deleting, etc.)

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Required. The resource name of the Dataset to backtest on
Format:
`/projects/{project_num}/locations/{location}/instances/{instance}/datasets/{dataset}`

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The resource name of the Model to use or to backtest.
Format:
`/projects/{project_num}/locations/{location}/instances/{instance}/models/{model}`

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. End_time specifies the latest time from which labels are used and
from which data is used to generate features for backtesting.  End_time
should be no later than the end of the date_range of the primary dataset.

=item * C<< $msg->backtest_periods() >> / C<< $msg->backtest_periods($value) >>

Type: C<Int32>

The number of consecutive months to conduct backtesting for, ending with
the last full month prior to the end_time according to the dataset's
timezone.

=item * C<< $msg->performance_target() >> / C<< $msg->performance_target($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::PerformanceTarget>)

Required. PerformanceTarget gives information on how the test will be
evaluated.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Output only. The line of business (Retail/Commercial) this backtest is for.
Determined by Model, cannot be set by user.

=back

=head3 Enum: BacktestResult::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsRequest

Request for retrieving a paginated list of BacktestResult resources that
meet the specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the BacktestResult is the Instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of resources to be included in the response. The response
contains a next_page_token, which can be used to retrieve the next page of
resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

In case of paginated results, this is the token that was returned in the
previous ListBacktestResultsResponse. It should be copied here to
retrieve the next page of resources. Empty will give the first page of
ListBacktestResultsRequest, and the last page will return an empty
page_token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Specify a filter to narrow search results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsResponse

Response for retrieving a list of BacktestResults

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backtest_results() >> / C<< $msg->backtest_results($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult>)

List of BacktestResult resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next ListBacktestResultsRequest to
retrieve the next page of BacktestResults (empty indicates we are
done).

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::GetBacktestResultRequest

Request for retrieving a specific BacktestResult resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the BacktestResult

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::CreateBacktestResultRequest

Request for creating a BacktestResult resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the BacktestResult is the Instance.

=item * C<< $msg->backtest_result_id() >> / C<< $msg->backtest_result_id($value) >>

Type: C<String>

Required. The resource id of the BacktestResult

=item * C<< $msg->backtest_result() >> / C<< $msg->backtest_result($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult>)

Required. The BacktestResult that will be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::UpdateBacktestResultRequest

Request for updating a BacktestResult

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
BacktestResult resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->backtest_result() >> / C<< $msg->backtest_result($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult>)

Required. The new value of the BacktestResult fields that will be updated
according to the update_mask.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::DeleteBacktestResultRequest

Request for deleting a BacktestResult.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the BacktestResult.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataRequest

Request for exporting BacktestResult metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backtest_result() >> / C<< $msg->backtest_result($value) >>

Type: C<String>

Required. The resource name of the BacktestResult.

=item * C<< $msg->structured_metadata_destination() >> / C<< $msg->structured_metadata_destination($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination>)

Required. BigQuery output where the metadata will be written.

=back

=head2 Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataResponse

Response for exporting BacktestResult metadata.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::BacktestResult::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
