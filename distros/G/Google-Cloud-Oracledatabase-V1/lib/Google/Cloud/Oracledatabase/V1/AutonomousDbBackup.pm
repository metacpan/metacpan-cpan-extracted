package Google::Cloud::Oracledatabase::V1::AutonomousDbBackup;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvYXV0b25vbW91c19kYl9iYWNrdXAu
cHJvdG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byKhBQoYQXV0b25vbW91c0RhdGFiYXNlQmFja3VwEhcK
BG5hbWUYASABKAlCA+BBCFIEbmFtZRJpChNhdXRvbm9tb3VzX2RhdGFiYXNlGAIgASgJQjjg
QQL6QTIKMG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0F1dG9ub21vdXNEYXRhYmFz
ZVISYXV0b25vbW91c0RhdGFiYXNlEiYKDGRpc3BsYXlfbmFtZRgDIAEoCUID4EEBUgtkaXNw
bGF5TmFtZRJnCgpwcm9wZXJ0aWVzGAQgASgLMkIuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFi
YXNlLnYxLkF1dG9ub21vdXNEYXRhYmFzZUJhY2t1cFByb3BlcnRpZXNCA+BBAVIKcHJvcGVy
dGllcxJhCgZsYWJlbHMYBSADKAsyRC5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEu
QXV0b25vbW91c0RhdGFiYXNlQmFja3VwLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxo5CgtM
YWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB
OtEB6kHNAQo2b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vQXV0b25vbW91c0RhdGFi
YXNlQmFja3VwEl5wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0
b25vbW91c0RhdGFiYXNlQmFja3Vwcy97YXV0b25vbW91c19kYXRhYmFzZV9iYWNrdXB9Khlh
dXRvbm9tb3VzRGF0YWJhc2VCYWNrdXBzMhhhdXRvbm9tb3VzRGF0YWJhc2VCYWNrdXAigQoK
IkF1dG9ub21vdXNEYXRhYmFzZUJhY2t1cFByb3BlcnRpZXMSFwoEb2NpZBgBIAEoCUID4EED
UgRvY2lkEjcKFXJldGVudGlvbl9wZXJpb2RfZGF5cxgCIAEoBUID4EEBUhNyZXRlbnRpb25Q
ZXJpb2REYXlzEioKDmNvbXBhcnRtZW50X2lkGAMgASgJQgPgQQNSDWNvbXBhcnRtZW50SWQS
LQoQZGF0YWJhc2Vfc2l6ZV90YhgEIAEoAkID4EEDUg5kYXRhYmFzZVNpemVUYhIiCgpkYl92
ZXJzaW9uGAUgASgJQgPgQQNSCWRiVmVyc2lvbhIyChNpc19sb25nX3Rlcm1fYmFja3VwGAYg
ASgIQgPgQQNSEGlzTG9uZ1Rlcm1CYWNrdXASMwoTaXNfYXV0b21hdGljX2JhY2t1cBgHIAEo
CEID4EEDUhFpc0F1dG9tYXRpY0JhY2t1cBIoCg1pc19yZXN0b3JhYmxlGAggASgIQgPgQQNS
DGlzUmVzdG9yYWJsZRIlCgxrZXlfc3RvcmVfaWQYCSABKAlCA+BBAVIKa2V5U3RvcmVJZBIt
ChBrZXlfc3RvcmVfd2FsbGV0GAogASgJQgPgQQFSDmtleVN0b3JlV2FsbGV0EiEKCmttc19r
ZXlfaWQYCyABKAlCA+BBAVIIa21zS2V5SWQSMAoSa21zX2tleV92ZXJzaW9uX2lkGAwgASgJ
QgPgQQFSD2ttc0tleVZlcnNpb25JZBIwChFsaWZlY3ljbGVfZGV0YWlscxgNIAEoCUID4EED
UhBsaWZlY3ljbGVEZXRhaWxzEnYKD2xpZmVjeWNsZV9zdGF0ZRgOIAEoDjJILmdvb2dsZS5j
bG91ZC5vcmFjbGVkYXRhYmFzZS52MS5BdXRvbm9tb3VzRGF0YWJhc2VCYWNrdXBQcm9wZXJ0
aWVzLlN0YXRlQgPgQQNSDmxpZmVjeWNsZVN0YXRlEhwKB3NpemVfdGIYDyABKAJCA+BBA1IG
c2l6ZVRiEk8KE2F2YWlsYWJsZV90aWxsX3RpbWUYECABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSEWF2YWlsYWJsZVRpbGxUaW1lEjoKCGVuZF90aW1lGBEgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEj4KCnN0YXJ0X3RpbWUY
EiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRJgCgR0
eXBlGBMgASgOMkcuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkF1dG9ub21vdXNE
YXRhYmFzZUJhY2t1cFByb3BlcnRpZXMuVHlwZUID4EEDUgR0eXBlEh4KCHZhdWx0X2lkGBQg
ASgJQgPgQQFSB3ZhdWx0SWQibQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghD
UkVBVElORxABEgoKBkFDVElWRRACEgwKCERFTEVUSU5HEAMSCwoHREVMRVRFRBAEEgoKBkZB
SUxFRBAGEgwKCFVQREFUSU5HEAciRgoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASDwoL
SU5DUkVNRU5UQUwQARIICgRGVUxMEAISDQoJTE9OR19URVJNEANC8QEKImNvbS5nb29nbGUu
Y2xvdWQub3JhY2xlZGF0YWJhc2UudjFCF0F1dG9ub21vdXNEYkJhY2t1cFByb3RvUAFaSmNs
b3VkLmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2Vw
YjtvcmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xlLkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIe
R29vZ2xlXENsb3VkXE9yYWNsZURhdGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xl
RGF0YWJhc2U6OlYxSv8zCgcSBQ4AsgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgS
AxYAOwoJCgIIJRIDFgA7CggKAQgSAxcAYQoJCgIICxIDFwBhCggKAQgSAxgAIgoJCgIIChID
GAAiCggKAQgSAxkAOAoJCgIICBIDGQA4CggKAQgSAxoAOwoJCgIIARIDGgA7CggKAQgSAxsA
OwoJCgIIKRIDGwA7CggKAQgSAxwAOgoJCgIILRIDHAA6CpsBCgIEABIEIABBARqOASBEZXRh
aWxzIG9mIHRoZSBBdXRvbm9tb3VzIERhdGFiYXNlIEJhY2t1cCByZXNvdXJjZS4KIGh0dHBz
Oi8vZG9jcy5vcmFjbGUuY29tL2VuLXVzL2lhYXMvYXBpLyMvZW4vZGF0YWJhc2UvMjAxNjA5
MTgvQXV0b25vbW91c0RhdGFiYXNlQmFja3VwLwoKCgoDBAABEgMgCCAKCwoDBAAHEgQhAiYE
Cg0KBQQAB50IEgQhAiYECr8BCgQEAAIAEgMrAj0asQEgSWRlbnRpZmllci4gVGhlIG5hbWUg
b2YgdGhlIEF1dG9ub21vdXMgRGF0YWJhc2UgQmFja3VwIHJlc291cmNlIHdpdGggdGhlCiBm
b3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259L2F1dG9ub21v
dXNEYXRhYmFzZUJhY2t1cHMve2F1dG9ub21vdXNfZGF0YWJhc2VfYmFja3VwfQoKDAoFBAAC
AAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEKDAoFBAACAAgSAysSPAoPCggE
AAIACJwIABIDKxM7CsgBCgQEAAIBEgQwAjUEGrkBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgQXV0b25vbW91cyBEYXRhYmFzZSByZXNvdXJjZSBmb3Igd2hpY2ggdGhlIGJhY2t1cAog
aXMgYmVpbmcgY3JlYXRlZC4gRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97cmVnaW9ufS9hdXRvbm9tb3VzRGF0YWJhc2VzL3thdXRvbm9tb3VzX2RhdGFiYXNlfQoK
DAoFBAACAQUSAzACCAoMCgUEAAIBARIDMAkcCgwKBQQAAgEDEgMwHyAKDQoFBAACAQgSBDAh
NQMKDwoIBAACAQicCAASAzEEKgoPCgcEAAIBCJ8IEgQyBDQFCmEKBAQAAgISAzkCQxpUIE9w
dGlvbmFsLiBVc2VyIGZyaWVuZGx5IG5hbWUgZm9yIHRoZSBCYWNrdXAuIFRoZSBuYW1lIGRv
ZXMgbm90IGhhdmUgdG8gYmUKIHVuaXF1ZS4KCgwKBQQAAgIFEgM5AggKDAoFBAACAgESAzkJ
FQoMCgUEAAICAxIDORgZCgwKBQQAAgIIEgM5GkIKDwoIBAACAgicCAASAzkbQQo7CgQEAAID
EgQ8Aj0vGi0gT3B0aW9uYWwuIFZhcmlvdXMgcHJvcGVydGllcyBvZiB0aGUgYmFja3VwLgoK
DAoFBAACAwYSAzwCJAoMCgUEAAIDARIDPCUvCgwKBQQAAgMDEgM8MjMKDAoFBAACAwgSAz0G
LgoPCggEAAIDCJwIABIDPQctCkUKBAQAAgQSA0ACSho4IE9wdGlvbmFsLiBsYWJlbHMgb3Ig
dGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIHJlc291cmNlLgoKDAoFBAACBAYSA0ACFQoMCgUE
AAIEARIDQBYcCgwKBQQAAgQDEgNAHyAKDAoFBAACBAgSA0AhSQoPCggEAAIECJwIABIDQCJI
CkUKAgQBEgVEALIBARo4IFByb3BlcnRpZXMgb2YgdGhlIEF1dG9ub21vdXMgRGF0YWJhc2Ug
QmFja3VwIHJlc291cmNlLgoKCgoDBAEBEgNECCoKUgoEBAEEABIERgJbAxpEIC8vIFRoZSB2
YXJpb3VzIGxpZmVjeWNsZSBzdGF0ZXMgb2YgdGhlIEF1dG9ub21vdXMgRGF0YWJhc2UgQmFj
a3VwLgoKDAoFBAEEAAESA0YHDAorCgYEAQQAAgASA0gEGhocIERlZmF1bHQgdW5zcGVjaWZp
ZWQgdmFsdWUuCgoOCgcEAQQAAgABEgNIBBUKDgoHBAEEAAIAAhIDSBgZCkIKBgQBBAACARID
SwQRGjMgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGNyZWF0aW5nIHN0YXRl
LgoKDgoHBAEEAAIBARIDSwQMCg4KBwQBBAACAQISA0sPEApACgYEAQQAAgISA04EDxoxIElu
ZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBhY3RpdmUgc3RhdGUuCgoOCgcEAQQA
AgIBEgNOBAoKDgoHBAEEAAICAhIDTg0OCkIKBgQBBAACAxIDUQQRGjMgSW5kaWNhdGVzIHRo
YXQgdGhlIHJlc291cmNlIGlzIGluIGRlbGV0aW5nIHN0YXRlLgoKDgoHBAEEAAIDARIDUQQM
Cg4KBwQBBAACAwISA1EPEApBCgYEAQQAAgQSA1QEEBoyIEluZGljYXRlcyB0aGF0IHRoZSBy
ZXNvdXJjZSBpcyBpbiBkZWxldGVkIHN0YXRlLgoKDgoHBAEEAAIEARIDVAQLCg4KBwQBBAAC
BAISA1QODwpACgYEAQQAAgUSA1cEDxoxIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBp
cyBpbiBmYWlsZWQgc3RhdGUuCgoOCgcEAQQAAgUBEgNXBAoKDgoHBAEEAAIFAhIDVw0OCkIK
BgQBBAACBhIDWgQRGjMgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIHVwZGF0
aW5nIHN0YXRlLgoKDgoHBAEEAAIGARIDWgQMCg4KBwQBBAACBgISA1oPEAonCgQEAQQBEgRe
AmoDGhkgVGhlIHR5cGUgb2YgdGhlIGJhY2t1cC4KCgwKBQQBBAEBEgNeBwsKKwoGBAEEAQIA
EgNgBBkaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAEEAQIAARIDYAQUCg4K
BwQBBAECAAISA2AXGAolCgYEAQQBAgESA2MEFBoWIEluY3JlbWVudGFsIGJhY2t1cHMuCgoO
CgcEAQQBAgEBEgNjBA8KDgoHBAEEAQIBAhIDYxITCh4KBgQBBAECAhIDZgQNGg8gRnVsbCBi
YWNrdXBzLgoKDgoHBAEEAQICARIDZgQICg4KBwQBBAECAgISA2YLDAojCgYEAQQBAgMSA2kE
EhoUIExvbmcgdGVybSBiYWNrdXBzLgoKDgoHBAEEAQIDARIDaQQNCg4KBwQBBAECAwISA2kQ
EQqYAQoEBAECABIDbgI+GooBIE91dHB1dCBvbmx5LiBPQ0lEIG9mIHRoZSBBdXRvbm9tb3Vz
IERhdGFiYXNlIGJhY2t1cC4KIGh0dHBzOi8vZG9jcy5vcmFjbGUuY29tL2VuLXVzL2lhYXMv
Q29udGVudC9HZW5lcmFsL0NvbmNlcHRzL2lkZW50aWZpZXJzLmh0bSNPcmFjbGUKCgwKBQQB
AgAFEgNuAggKDAoFBAECAAESA24JDQoMCgUEAQIAAxIDbhARCgwKBQQBAgAIEgNuEj0KDwoI
BAECAAicCAASA24TPApBCgQEAQIBEgNxAksaNCBPcHRpb25hbC4gUmV0ZW50aW9uIHBlcmlv
ZCBpbiBkYXlzIGZvciB0aGUgYmFja3VwLgoKDAoFBAECAQUSA3ECBwoMCgUEAQIBARIDcQgd
CgwKBQQBAgEDEgNxICEKDAoFBAECAQgSA3EiSgoPCggEAQIBCJwIABIDcSNJCjgKBAQBAgIS
A3QCSBorIE91dHB1dCBvbmx5LiBUaGUgT0NJRCBvZiB0aGUgY29tcGFydG1lbnQuCgoMCgUE
AQICBRIDdAIICgwKBQQBAgIBEgN0CRcKDAoFBAECAgMSA3QaGwoMCgUEAQICCBIDdBxHCg8K
CAQBAgIInAgAEgN0HUYKTwoEBAECAxIDdwJJGkIgT3V0cHV0IG9ubHkuIFRoZSBxdWFudGl0
eSBvZiBkYXRhIGluIHRoZSBkYXRhYmFzZSwgaW4gdGVyYWJ5dGVzLgoKDAoFBAECAwUSA3cC
BwoMCgUEAQIDARIDdwgYCgwKBQQBAgMDEgN3GxwKDAoFBAECAwgSA3cdSAoPCggEAQIDCJwI
ABIDdx5HClQKBAQBAgQSA3oCRBpHIE91dHB1dCBvbmx5LiBBIHZhbGlkIE9yYWNsZSBEYXRh
YmFzZSB2ZXJzaW9uIGZvciBBdXRvbm9tb3VzIERhdGFiYXNlLgoKDAoFBAECBAUSA3oCCAoM
CgUEAQIEARIDegkTCgwKBQQBAgQDEgN6FhcKDAoFBAECBAgSA3oYQwoPCggEAQIECJwIABID
ehlCCkgKBAQBAgUSA30CSxo7IE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgaWYgdGhlIGJhY2t1
cCBpcyBsb25nIHRlcm0gYmFja3VwLgoKDAoFBAECBQUSA30CBgoMCgUEAQIFARIDfQcaCgwK
BQQBAgUDEgN9HR4KDAoFBAECBQgSA30fSgoPCggEAQIFCJwIABIDfSBJClQKBAQBAgYSBIAB
AksaRiBPdXRwdXQgb25seS4gSW5kaWNhdGVzIGlmIHRoZSBiYWNrdXAgaXMgYXV0b21hdGlj
IG9yIHVzZXIgaW5pdGlhdGVkLgoKDQoFBAECBgUSBIABAgYKDQoFBAECBgESBIABBxoKDQoF
BAECBgMSBIABHR4KDQoFBAECBggSBIABH0oKEAoIBAECBgicCAASBIABIEkKZQoEBAECBxIE
hAECRRpXIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgaWYgdGhlIGJhY2t1cCBjYW4gYmUgdXNl
ZCB0byByZXN0b3JlIHRoZSBBdXRvbm9tb3VzCiBEYXRhYmFzZS4KCg0KBQQBAgcFEgSEAQIG
Cg0KBQQBAgcBEgSEAQcUCg0KBQQBAgcDEgSEARcYCg0KBQQBAgcIEgSEARlEChAKCAQBAgcI
nAgAEgSEARpDCkQKBAQBAggSBIcBAkMaNiBPcHRpb25hbC4gVGhlIE9DSUQgb2YgdGhlIGtl
eSBzdG9yZSBvZiBPcmFjbGUgVmF1bHQuCgoNCgUEAQIIBRIEhwECCAoNCgUEAQIIARIEhwEJ
FQoNCgUEAQIIAxIEhwEYGQoNCgUEAQIICBIEhwEaQgoQCggEAQIICJwIABIEhwEbQQo/CgQE
AQIJEgSKAQJIGjEgT3B0aW9uYWwuIFRoZSB3YWxsZXQgbmFtZSBmb3IgT3JhY2xlIEtleSBW
YXVsdC4KCg0KBQQBAgkFEgSKAQIICg0KBQQBAgkBEgSKAQkZCg0KBQQBAgkDEgSKARweCg0K
BQQBAgkIEgSKAR9HChAKCAQBAgkInAgAEgSKASBGCp0BCgQEAQIKEgSOAQJCGo4BIE9wdGlv
bmFsLiBUaGUgT0NJRCBvZiB0aGUga2V5IGNvbnRhaW5lciB0aGF0IGlzIHVzZWQgYXMgdGhl
IG1hc3RlcgogZW5jcnlwdGlvbiBrZXkgaW4gZGF0YWJhc2UgdHJhbnNwYXJlbnQgZGF0YSBl
bmNyeXB0aW9uIChUREUpIG9wZXJhdGlvbnMuCgoNCgUEAQIKBRIEjgECCAoNCgUEAQIKARIE
jgEJEwoNCgUEAQIKAxIEjgEWGAoNCgUEAQIKCBIEjgEZQQoQCggEAQIKCJwIABIEjgEaQAqT
AwoEBAECCxIElgECShqEAyBPcHRpb25hbC4gVGhlIE9DSUQgb2YgdGhlIGtleSBjb250YWlu
ZXIgdmVyc2lvbiB0aGF0IGlzIHVzZWQgaW4gZGF0YWJhc2UKIHRyYW5zcGFyZW50IGRhdGEg
ZW5jcnlwdGlvbiAoVERFKSBvcGVyYXRpb25zIEtNUyBLZXkgY2FuIGhhdmUgbXVsdGlwbGUg
a2V5CiB2ZXJzaW9ucy4gSWYgbm9uZSBpcyBzcGVjaWZpZWQsIHRoZSBjdXJyZW50IGtleSB2
ZXJzaW9uIChsYXRlc3QpIG9mIHRoZSBLZXkKIElkIGlzIHVzZWQgZm9yIHRoZSBvcGVyYXRp
b24uIEF1dG9ub21vdXMgRGF0YWJhc2UgU2VydmVybGVzcyBkb2VzIG5vdCB1c2UKIGtleSB2
ZXJzaW9ucywgaGVuY2UgaXMgbm90IGFwcGxpY2FibGUgZm9yIEF1dG9ub21vdXMgRGF0YWJh
c2UgU2VydmVybGVzcwogaW5zdGFuY2VzLgoKDQoFBAECCwUSBJYBAggKDQoFBAECCwESBJYB
CRsKDQoFBAECCwMSBJYBHiAKDQoFBAECCwgSBJYBIUkKEAoIBAECCwicCAASBJYBIkgKVgoE
BAECDBIEmQECTBpIIE91dHB1dCBvbmx5LiBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFib3V0
IHRoZSBjdXJyZW50IGxpZmVjeWNsZSBzdGF0ZS4KCg0KBQQBAgwFEgSZAQIICg0KBQQBAgwB
EgSZAQkaCg0KBQQBAgwDEgSZAR0fCg0KBQQBAgwIEgSZASBLChAKCAQBAgwInAgAEgSZASFK
Cj8KBAQBAg0SBJwBAkkaMSBPdXRwdXQgb25seS4gVGhlIGxpZmVjeWNsZSBzdGF0ZSBvZiB0
aGUgYmFja3VwLgoKDQoFBAECDQYSBJwBAgcKDQoFBAECDQESBJwBCBcKDQoFBAECDQMSBJwB
GhwKDQoFBAECDQgSBJwBHUgKEAoIBAECDQicCAASBJwBHkcKOgoEBAECDhIEnwECQRosIE91
dHB1dCBvbmx5LiBUaGUgYmFja3VwIHNpemUgaW4gdGVyYWJ5dGVzLgoKDQoFBAECDgUSBJ8B
AgcKDQoFBAECDgESBJ8BCA8KDQoFBAECDgMSBJ8BEhQKDQoFBAECDggSBJ8BFUAKEAoIBAEC
DgicCAASBJ8BFj8KUQoEBAECDxIGogECowEyGkEgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB1
bnRpbCB3aGVuIHRoZSBiYWNrdXAgd2lsbCBiZSBhdmFpbGFibGUuCgoNCgUEAQIPBhIEogEC
GwoNCgUEAQIPARIEogEcLwoNCgUEAQIPAxIEogEyNAoNCgUEAQIPCBIEowEGMQoQCggEAQIP
CJwIABIEowEHMApGCgQEAQIQEgamAQKnATIaNiBPdXRwdXQgb25seS4gVGhlIGRhdGUgYW5k
IHRpbWUgdGhlIGJhY2t1cCBjb21wbGV0ZWQuCgoNCgUEAQIQBhIEpgECGwoNCgUEAQIQARIE
pgEcJAoNCgUEAQIQAxIEpgEnKQoNCgUEAQIQCBIEpwEGMQoQCggEAQIQCJwIABIEpwEHMApE
CgQEAQIREgaqAQKrATIaNCBPdXRwdXQgb25seS4gVGhlIGRhdGUgYW5kIHRpbWUgdGhlIGJh
Y2t1cCBzdGFydGVkLgoKDQoFBAECEQYSBKoBAhsKDQoFBAECEQESBKoBHCYKDQoFBAECEQMS
BKoBKSsKDQoFBAECEQgSBKsBBjEKEAoIBAECEQicCAASBKsBBzAKNAoEBAECEhIErgECPRom
IE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGUgYmFja3VwLgoKDQoFBAECEgYSBK4BAgYK
DQoFBAECEgESBK4BBwsKDQoFBAECEgMSBK4BDhAKDQoFBAECEggSBK4BETwKEAoIBAECEgic
CAASBK4BEjsKMAoEBAECExIEsQECQBoiIE9wdGlvbmFsLiBUaGUgT0NJRCBvZiB0aGUgdmF1
bHQuCgoNCgUEAQITBRIEsQECCAoNCgUEAQITARIEsQEJEQoNCgUEAQITAxIEsQEUFgoNCgUE
AQITCBIEsQEXPwoQCggEAQITCJwIABIEsQEYPmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup ===
    # Fields for AutonomousDatabaseBackup
    # Field: name Type: 9 ()
    # Field: autonomous_database Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.AutonomousDatabaseBackupProperties)
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.AutonomousDatabaseBackup.LabelsEntry)

# === Message: Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackupProperties ===
    # Fields for AutonomousDatabaseBackupProperties
    # Field: ocid Type: 9 ()
    # Field: retention_period_days Type: 5 ()
    # Field: compartment_id Type: 9 ()
    # Field: database_size_tb Type: 2 ()
    # Field: db_version Type: 9 ()
    # Field: is_long_term_backup Type: 8 ()
    # Field: is_automatic_backup Type: 8 ()
    # Field: is_restorable Type: 8 ()
    # Field: key_store_id Type: 9 ()
    # Field: key_store_wallet Type: 9 ()
    # Field: kms_key_id Type: 9 ()
    # Field: kms_key_version_id Type: 9 ()
    # Field: lifecycle_details Type: 9 ()
    # Field: lifecycle_state Type: 14 (.google.cloud.oracledatabase.v1.AutonomousDatabaseBackupProperties.State)
    # Field: size_tb Type: 2 ()
    # Field: available_till_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 14 (.google.cloud.oracledatabase.v1.AutonomousDatabaseBackupProperties.Type)
    # Field: vault_id Type: 9 ()

# Enum: AutonomousDatabaseBackupProperties::State
our $AutonomousDatabaseBackupProperties_STATE_UNSPECIFIED = 0;
our $AutonomousDatabaseBackupProperties_CREATING = 1;
our $AutonomousDatabaseBackupProperties_ACTIVE = 2;
our $AutonomousDatabaseBackupProperties_DELETING = 3;
our $AutonomousDatabaseBackupProperties_DELETED = 4;
our $AutonomousDatabaseBackupProperties_FAILED = 6;
our $AutonomousDatabaseBackupProperties_UPDATING = 7;

# Enum: AutonomousDatabaseBackupProperties::Type
our $AutonomousDatabaseBackupProperties_TYPE_UNSPECIFIED = 0;
our $AutonomousDatabaseBackupProperties_INCREMENTAL = 1;
our $AutonomousDatabaseBackupProperties_FULL = 2;
our $AutonomousDatabaseBackupProperties_LONG_TERM = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDbBackup - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/autonomous_db_backup.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::AutonomousDbBackup;

    my $msg = Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup->new({
        name => $name,
        autonomous_database => $autonomous_database,
        display_name => $display_name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/autonomous_db_backup.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup

Details of the Autonomous Database Backup resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/AutonomousDatabaseBackup/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Autonomous Database Backup resource with the
format:
projects/{project}/locations/{region}/autonomousDatabaseBackups/{autonomous_database_backup}

=item * C<< $msg->autonomous_database() >> / C<< $msg->autonomous_database($value) >>

Type: C<String>

Required. The name of the Autonomous Database resource for which the backup
is being created. Format:
projects/{project}/locations/{region}/autonomousDatabases/{autonomous_database}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User friendly name for the Backup. The name does not have to be
unique.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackupProperties>)

Optional. Various properties of the backup.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup::LabelsEntry>)

Optional. labels or tags associated with the resource.

=back

=head2 Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackupProperties

Properties of the Autonomous Database Backup resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. OCID of the Autonomous Database backup.
https://docs.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm#Oracle

=item * C<< $msg->retention_period_days() >> / C<< $msg->retention_period_days($value) >>

Type: C<Int32>

Optional. Retention period in days for the backup.

=item * C<< $msg->compartment_id() >> / C<< $msg->compartment_id($value) >>

Type: C<String>

Output only. The OCID of the compartment.

=item * C<< $msg->database_size_tb() >> / C<< $msg->database_size_tb($value) >>

Type: C<Float>

Output only. The quantity of data in the database, in terabytes.

=item * C<< $msg->db_version() >> / C<< $msg->db_version($value) >>

Type: C<String>

Output only. A valid Oracle Database version for Autonomous Database.

=item * C<< $msg->is_long_term_backup() >> / C<< $msg->is_long_term_backup($value) >>

Type: C<Bool>

Output only. Indicates if the backup is long term backup.

=item * C<< $msg->is_automatic_backup() >> / C<< $msg->is_automatic_backup($value) >>

Type: C<Bool>

Output only. Indicates if the backup is automatic or user initiated.

=item * C<< $msg->is_restorable() >> / C<< $msg->is_restorable($value) >>

Type: C<Bool>

Output only. Indicates if the backup can be used to restore the Autonomous
Database.

=item * C<< $msg->key_store_id() >> / C<< $msg->key_store_id($value) >>

Type: C<String>

Optional. The OCID of the key store of Oracle Vault.

=item * C<< $msg->key_store_wallet() >> / C<< $msg->key_store_wallet($value) >>

Type: C<String>

Optional. The wallet name for Oracle Key Vault.

=item * C<< $msg->kms_key_id() >> / C<< $msg->kms_key_id($value) >>

Type: C<String>

Optional. The OCID of the key container that is used as the master
encryption key in database transparent data encryption (TDE) operations.

=item * C<< $msg->kms_key_version_id() >> / C<< $msg->kms_key_version_id($value) >>

Type: C<String>

Optional. The OCID of the key container version that is used in database
transparent data encryption (TDE) operations KMS Key can have multiple key
versions. If none is specified, the current key version (latest) of the Key
Id is used for the operation. Autonomous Database Serverless does not use
key versions, hence is not applicable for Autonomous Database Serverless
instances.

=item * C<< $msg->lifecycle_details() >> / C<< $msg->lifecycle_details($value) >>

Type: C<String>

Output only. Additional information about the current lifecycle state.

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::AutonomousDatabaseBackupProperties::State>)

Output only. The lifecycle state of the backup.

=item * C<< $msg->size_tb() >> / C<< $msg->size_tb($value) >>

Type: C<Float>

Output only. The backup size in terabytes.

=item * C<< $msg->available_till_time() >> / C<< $msg->available_till_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp until when the backup will be available.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time the backup completed.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time the backup started.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::AutonomousDatabaseBackupProperties::Type>)

Output only. The type of the backup.

=item * C<< $msg->vault_id() >> / C<< $msg->vault_id($value) >>

Type: C<String>

Optional. The OCID of the vault.

=back

=head3 Enum: AutonomousDatabaseBackupProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=item * C<DELETED> => C<4>

=item * C<FAILED> => C<6>

=item * C<UPDATING> => C<7>

=back

=head3 Enum: AutonomousDatabaseBackupProperties::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<INCREMENTAL> => C<1>

=item * C<FULL> => C<2>

=item * C<LONG_TERM> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
