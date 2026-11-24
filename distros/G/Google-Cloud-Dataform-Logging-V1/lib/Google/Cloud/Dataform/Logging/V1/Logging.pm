package Google::Cloud::Dataform::Logging::V1::Logging;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZGF0YWZvcm0vbG9nZ2luZy92MS9sb2dnaW5nLnByb3RvEiBnb29n
bGUuY2xvdWQuZGF0YWZvcm0ubG9nZ2luZy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90byKjAwokV29ya2Zsb3dJbnZvY2F0aW9uQ29tcGxldGlvbkxvZ0VudHJ5EjkKFndv
cmtmbG93X2ludm9jYXRpb25faWQYASABKAlCA+BBAlIUd29ya2Zsb3dJbnZvY2F0aW9uSWQS
MQoSd29ya2Zsb3dfY29uZmlnX2lkGAIgASgJQgPgQQFSEHdvcmtmbG93Q29uZmlnSWQSLwoR
cmVsZWFzZV9jb25maWdfaWQYAyABKAlCA+BBAVIPcmVsZWFzZUNvbmZpZ0lkEoABCg50ZXJt
aW5hbF9zdGF0ZRgEIAEoDjJULmdvb2dsZS5jbG91ZC5kYXRhZm9ybS5sb2dnaW5nLnYxLldv
cmtmbG93SW52b2NhdGlvbkNvbXBsZXRpb25Mb2dFbnRyeS5UZXJtaW5hbFN0YXRlQgPgQQJS
DXRlcm1pbmFsU3RhdGUiWQoNVGVybWluYWxTdGF0ZRIeChpURVJNSU5BTF9TVEFURV9VTlNQ
RUNJRklFRBAAEg0KCVNVQ0NFRURFRBABEg0KCUNBTkNFTExFRBACEgoKBkZBSUxFRBADItgN
ChlBY3RBc0RyeVJ1blJlc3VsdExvZ0VudHJ5EiIKCmFwaV9tZXRob2QYASABKAlCA+BBAlIJ
YXBpTWV0aG9kEhsKBmNhbGxlchgCIAEoCUID4EECUgZjYWxsZXISLAoPc2VydmljZV9hY2Nv
dW50GAMgASgJQgPgQQJSDnNlcnZpY2VBY2NvdW50EikKDmRyeV9ydW5fcmVzdWx0GAQgASgI
QgPgQQJSDGRyeVJ1blJlc3VsdBKvAQoiY3JlYXRlX3dvcmtmbG93X2ludm9jYXRpb25fY29u
dGV4dBgFIAEoCzJbLmdvb2dsZS5jbG91ZC5kYXRhZm9ybS5sb2dnaW5nLnYxLkFjdEFzRHJ5
UnVuUmVzdWx0TG9nRW50cnkuQ3JlYXRlV29ya2Zsb3dJbnZvY2F0aW9uQ29udGV4dEID4EEB
SABSH2NyZWF0ZVdvcmtmbG93SW52b2NhdGlvbkNvbnRleHQSlgEKGWNyZWF0ZV9yZXBvc2l0
b3J5X2NvbnRleHQYBiABKAsyUy5nb29nbGUuY2xvdWQuZGF0YWZvcm0ubG9nZ2luZy52MS5B
Y3RBc0RyeVJ1blJlc3VsdExvZ0VudHJ5LkNyZWF0ZVJlcG9zaXRvcnlDb250ZXh0QgPgQQFI
AFIXY3JlYXRlUmVwb3NpdG9yeUNvbnRleHQSlgEKGXVwZGF0ZV9yZXBvc2l0b3J5X2NvbnRl
eHQYByABKAsyUy5nb29nbGUuY2xvdWQuZGF0YWZvcm0ubG9nZ2luZy52MS5BY3RBc0RyeVJ1
blJlc3VsdExvZ0VudHJ5LlVwZGF0ZVJlcG9zaXRvcnlDb250ZXh0QgPgQQFIAFIXdXBkYXRl
UmVwb3NpdG9yeUNvbnRleHQSoAEKHXVwZGF0ZV9yZWxlYXNlX2NvbmZpZ19jb250ZXh0GAgg
ASgLMlYuZ29vZ2xlLmNsb3VkLmRhdGFmb3JtLmxvZ2dpbmcudjEuQWN0QXNEcnlSdW5SZXN1
bHRMb2dFbnRyeS5VcGRhdGVSZWxlYXNlQ29uZmlnQ29udGV4dEID4EEBSABSGnVwZGF0ZVJl
bGVhc2VDb25maWdDb250ZXh0EqMBCh51cGRhdGVfd29ya2Zsb3dfY29uZmlnX2NvbnRleHQY
CSABKAsyVy5nb29nbGUuY2xvdWQuZGF0YWZvcm0ubG9nZ2luZy52MS5BY3RBc0RyeVJ1blJl
c3VsdExvZ0VudHJ5LlVwZGF0ZVdvcmtmbG93Q29uZmlnQ29udGV4dEID4EEBSABSG3VwZGF0
ZVdvcmtmbG93Q29uZmlnQ29udGV4dBKjAQoeY3JlYXRlX3dvcmtmbG93X2NvbmZpZ19jb250
ZXh0GAogASgLMlcuZ29vZ2xlLmNsb3VkLmRhdGFmb3JtLmxvZ2dpbmcudjEuQWN0QXNEcnlS
dW5SZXN1bHRMb2dFbnRyeS5DcmVhdGVXb3JrZmxvd0NvbmZpZ0NvbnRleHRCA+BBAUgAUhtj
cmVhdGVXb3JrZmxvd0NvbmZpZ0NvbnRleHQaPgoXQ3JlYXRlUmVwb3NpdG9yeUNvbnRleHQS
IwoKcmVwb3NpdG9yeRgBIAEoCUID4EEBUgpyZXBvc2l0b3J5Gj4KF1VwZGF0ZVJlcG9zaXRv
cnlDb250ZXh0EiMKCnJlcG9zaXRvcnkYASABKAlCA+BBAVIKcmVwb3NpdG9yeRpIChpVcGRh
dGVSZWxlYXNlQ29uZmlnQ29udGV4dBIqCg5yZWxlYXNlX2NvbmZpZxgBIAEoCUID4EEBUg1y
ZWxlYXNlQ29uZmlnGksKG0NyZWF0ZVdvcmtmbG93Q29uZmlnQ29udGV4dBIsCg93b3JrZmxv
d19jb25maWcYASABKAlCA+BBAVIOd29ya2Zsb3dDb25maWcaSwobVXBkYXRlV29ya2Zsb3dD
b25maWdDb250ZXh0EiwKD3dvcmtmbG93X2NvbmZpZxgBIAEoCUID4EEBUg53b3JrZmxvd0Nv
bmZpZxrTAQofQ3JlYXRlV29ya2Zsb3dJbnZvY2F0aW9uQ29udGV4dBI0ChN3b3JrZmxvd19p
bnZvY2F0aW9uGAEgASgJQgPgQQFSEndvcmtmbG93SW52b2NhdGlvbhI0ChJjb21waWxhdGlv
bl9yZXN1bHQYAiABKAlCA+BBAUgAUhFjb21waWxhdGlvblJlc3VsdBIuCg93b3JrZmxvd19j
b25maWcYAyABKAlCA+BBAUgAUg53b3JrZmxvd0NvbmZpZ0IUChJjb21waWxhdGlvbl9zb3Vy
Y2VCFAoSYXBpX21ldGhvZF9jb250ZXh0QnYKJGNvbS5nb29nbGUuY2xvdWQuZGF0YWZvcm0u
bG9nZ2luZy52MUIMTG9nZ2luZ1Byb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWZv
cm0vbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiSuktCgcSBQ4AlwEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACkKCAoB
CBIDFABVCgkKAggLEgMUAFUKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAtCgkKAggI
EgMWAC0KCAoBCBIDFwA9CgkKAggBEgMXAD0KYwoCBAASBBsANgEaVyBTdHJ1Y3R1cmVkIHBh
eWxvYWQgZm9yIGxvZ3MgZ2VuZXJhdGVkIGZyb20gRGF0YWZvcm0gd29ya2Zsb3cgaW52b2Nh
dGlvbgogY29tcGxldGlvbnMuCgoKCgMEAAESAxsILApQCgQEAAQAEgQdAikDGkIgUmVwcmVz
ZW50cyB0aGUgZmluYWwgdGVybWluYXRpb24gc3RhdGUgb2YgYSB3b3JrZmxvdyBpbnZvY2F0
aW9uLgoKDAoFBAAEAAESAx0HFAo1CgYEAAQAAgASAx8EIxomIERlZmF1bHQgdmFsdWUuIFRo
aXMgdmFsdWUgaXMgdW51c2VkLgoKDgoHBAAEAAIAARIDHwQeCg4KBwQABAACAAISAx8hIgoz
CgYEAAQAAgESAyIEEhokIFRoZSB3b3JrZmxvdyBpbnZvY2F0aW9uIHN1Y2NlZWRlZC4KCg4K
BwQABAACAQESAyIEDQoOCgcEAAQAAgECEgMiEBEKNwoGBAAEAAICEgMlBBIaKCBUaGUgd29y
a2Zsb3cgaW52b2NhdGlvbiB3YXMgY2FuY2VsbGVkLgoKDgoHBAAEAAICARIDJQQNCg4KBwQA
BAACAgISAyUQEQowCgYEAAQAAgMSAygEDxohIFRoZSB3b3JrZmxvdyBpbnZvY2F0aW9uIGZh
aWxlZC4KCg4KBwQABAACAwESAygECgoOCgcEAAQAAgMCEgMoDQ4KPwoEBAACABIDLAJNGjIg
UmVxdWlyZWQuIElkZW50aWZpZXIgb2YgdGhlIHdvcmtmbG93IGludm9jYXRpb24uCgoMCgUE
AAIABRIDLAIICgwKBQQAAgABEgMsCR8KDAoFBAACAAMSAywiIwoMCgUEAAIACBIDLCRMCg8K
CAQAAgAInAgAEgMsJUsKOwoEBAACARIDLwJJGi4gT3B0aW9uYWwuIElkZW50aWZpZXIgb2Yg
dGhlIHdvcmtmbG93IGNvbmZpZy4KCgwKBQQAAgEFEgMvAggKDAoFBAACAQESAy8JGwoMCgUE
AAIBAxIDLx4fCgwKBQQAAgEIEgMvIEgKDwoIBAACAQicCAASAy8hRwo6CgQEAAICEgMyAkga
LSBPcHRpb25hbC4gSWRlbnRpZmllciBvZiB0aGUgcmVsZWFzZSBjb25maWcuCgoMCgUEAAIC
BRIDMgIICgwKBQQAAgIBEgMyCRoKDAoFBAACAgMSAzIdHgoMCgUEAAICCBIDMh9HCg8KCAQA
AgIInAgAEgMyIEYKSwoEBAACAxIDNQJMGj4gUmVxdWlyZWQuIFRoZSB3b3JrZmxvdyBpbnZv
Y2F0aW9uJ3MgZmluYWwgdGVybWluYXRpb24gc3RhdGUuCgoMCgUEAAIDBhIDNQIPCgwKBQQA
AgMBEgM1EB4KDAoFBAACAwMSAzUhIgoMCgUEAAIDCBIDNSNLCg8KCAQAAgMInAgAEgM1JEoK
WgoCBAESBTkAlwEBGk0gU3RydWN0dXJlZCBwYXlsb2FkIGZvciBsb2dzIGdlbmVyYXRlZCBm
cm9tIERhdGFmb3JtIEFjdC1hcyBkcnkgcnVuIHJlc3VsdHMuCgoKCgMEAQESAzkIIQpBCgQE
AQMAEgQ7Aj8DGjMgQ29udGV4dCBzcGVjaWZpYyB0byBgQ3JlYXRlUmVwb3NpdG9yeWAgQVBJ
IGNhbGxzLgoKDAoFBAEDAAESAzsKIQptCgYEAQMAAgASAz4EQxpeIE9wdGlvbmFsLiBSZXNv
dXJjZSBuYW1lIG9mIHRoZSByZXBvc2l0b3J5LgogRm9ybWF0OiBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9yZXBvc2l0b3JpZXMvKmAuCgoOCgcEAQMAAgAFEgM+BAoKDgoHBAEDAAIAARID
PgsVCg4KBwQBAwACAAMSAz4YGQoOCgcEAQMAAgAIEgM+GkIKEQoKBAEDAAIACJwIABIDPhtB
CkEKBAQBAwESBEICRgMaMyBDb250ZXh0IHNwZWNpZmljIHRvIGBVcGRhdGVSZXBvc2l0b3J5
YCBBUEkgY2FsbHMuCgoMCgUEAQMBARIDQgohCm0KBgQBAwECABIDRQRDGl4gT3B0aW9uYWwu
IFJlc291cmNlIG5hbWUgb2YgdGhlIHJlcG9zaXRvcnkuCiBGb3JtYXQ6IGBwcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL3JlcG9zaXRvcmllcy8qYC4KCg4KBwQBAwECAAUSA0UECgoOCgcEAQMB
AgABEgNFCxUKDgoHBAEDAQIAAxIDRRgZCg4KBwQBAwECAAgSA0UaQgoRCgoEAQMBAgAInAgA
EgNFG0EKRAoEBAEDAhIESQJNAxo2IENvbnRleHQgc3BlY2lmaWMgdG8gYFVwZGF0ZVJlbGVh
c2VDb25maWdgIEFQSSBjYWxscy4KCgwKBQQBAwIBEgNJCiQKggEKBgQBAwICABIDTARHGnMg
T3B0aW9uYWwuIFJlc291cmNlIG5hbWUgb2YgdGhlIHJlbGVhc2UgY29uZmlnLgogRm9ybWF0
OiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKi9yZWxlYXNlQ29uZmln
cy8qYC4KCg4KBwQBAwICAAUSA0wECgoOCgcEAQMCAgABEgNMCxkKDgoHBAEDAgIAAxIDTBwd
Cg4KBwQBAwICAAgSA0weRgoRCgoEAQMCAgAInAgAEgNMH0UKRQoEBAEDAxIEUAJUAxo3IENv
bnRleHQgc3BlY2lmaWMgdG8gYENyZWF0ZVdvcmtmbG93Q29uZmlnYCBBUEkgY2FsbHMuCgoM
CgUEAQMDARIDUAolCoQBCgYEAQMDAgASA1MESBp1IE9wdGlvbmFsLiBSZXNvdXJjZSBuYW1l
IG9mIHRoZSB3b3JrZmxvdyBjb25maWcuCiBGb3JtYXQ6IGBwcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3JlcG9zaXRvcmllcy8qL3dvcmtmbG93Q29uZmlncy8qYC4KCg4KBwQBAwMCAAUSA1ME
CgoOCgcEAQMDAgABEgNTCxoKDgoHBAEDAwIAAxIDUx0eCg4KBwQBAwMCAAgSA1MfRwoRCgoE
AQMDAgAInAgAEgNTIEYKRQoEBAEDBBIEVwJbAxo3IENvbnRleHQgc3BlY2lmaWMgdG8gYFVw
ZGF0ZVdvcmtmbG93Q29uZmlnYCBBUEkgY2FsbHMuCgoMCgUEAQMEARIDVwolCoQBCgYEAQME
AgASA1oESBp1IE9wdGlvbmFsLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSB3b3JrZmxvdyBjb25m
aWcuCiBGb3JtYXQ6IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JlcG9zaXRvcmllcy8qL3dv
cmtmbG93Q29uZmlncy8qYC4KCg4KBwQBAwQCAAUSA1oECgoOCgcEAQMEAgABEgNaCxoKDgoH
BAEDBAIAAxIDWh0eCg4KBwQBAwQCAAgSA1ofRwoRCgoEAQMEAgAInAgAEgNaIEYKSQoEBAED
BRIEXgJuAxo7IENvbnRleHQgc3BlY2lmaWMgdG8gYENyZWF0ZVdvcmtmbG93SW52b2NhdGlv
bmAgQVBJIGNhbGxzLgoKDAoFBAEDBQESA14KKQqMAQoGBAEDBQIAEgNhBEwafSBPcHRpb25h
bC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgd29ya2Zsb3cgaW52b2NhdGlvbi4KIEZvcm1hdDog
YHByb2plY3RzLyovbG9jYXRpb25zLyovcmVwb3NpdG9yaWVzLyovd29ya2Zsb3dJbnZvY2F0
aW9ucy8qYC4KCg4KBwQBAwUCAAUSA2EECgoOCgcEAQMFAgABEgNhCx4KDgoHBAEDBQIAAxID
YSEiCg4KBwQBAwUCAAgSA2EjSwoRCgoEAQMFAgAInAgAEgNhJEoKOwoGBAEDBQgAEgRkBG0F
GisgVGhlIGlkZW50aWZpZXIgb2YgdGhlIGNvbXBpbGF0aW9uIHNvdXJjZS4KCg4KBwQBAwUI
AAESA2QKHAqwAQoGBAEDBQIBEgNoBk0aoAEgT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRoZSBj
b21waWxhdGlvbiByZXN1bHQgdG8gdXNlIGZvciB0aGlzCiBpbnZvY2F0aW9uLiBNdXN0IGJl
IGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JlcG9zaXRvcmllcy8q
L2NvbXBpbGF0aW9uUmVzdWx0cy8qYC4KCg4KBwQBAwUCAQUSA2gGDAoOCgcEAQMFAgEBEgNo
DR8KDgoHBAEDBQIBAxIDaCIjCg4KBwQBAwUCAQgSA2gkTAoRCgoEAQMFAgEInAgAEgNoJUsK
mAEKBgQBAwUCAhIDbAZKGogBIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgd29ya2Zsb3cg
Y29uZmlnIHRvIGludm9rZS4gTXVzdCBiZSBpbiB0aGUKIGZvcm1hdCBgcHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKi93b3JrZmxvd0NvbmZpZ3MvKmAuCgoOCgcEAQMF
AgIFEgNsBgwKDgoHBAEDBQICARIDbA0cCg4KBwQBAwUCAgMSA2wfIAoOCgcEAQMFAgIIEgNs
IUkKEQoKBAEDBQICCJwIABIDbCJICk4KBAQBAgASA3ECQRpBIFJlcXVpcmVkLiBUaGUgQVBJ
IG1ldGhvZCBuYW1lIHRoYXQgdHJpZ2dlcmVkIHRoZSBkcnkgcnVuIGNoZWNrLgoKDAoFBAEC
AAUSA3ECCAoMCgUEAQIAARIDcQkTCgwKBQQBAgADEgNxFhcKDAoFBAECAAgSA3EYQAoPCggE
AQIACJwIABIDcRk/CkUKBAQBAgESA3QCPRo4IFJlcXVpcmVkLiBUaGUgY2FsbGVyIHRoYXQg
dHJpZ2dlcmVkIHRoZSBkcnkgcnVuIGNoZWNrLgoKDAoFBAECAQUSA3QCCAoMCgUEAQIBARID
dAkPCgwKBQQBAgEDEgN0EhMKDAoFBAECAQgSA3QUPAoPCggEAQIBCJwIABIDdBU7CkgKBAQB
AgISA3cCRho7IFJlcXVpcmVkLiBUaGUgc2VydmljZSBhY2NvdW50IHVzZWQgZm9yIHRoZSBk
cnkgcnVuIGNoZWNrLgoKDAoFBAECAgUSA3cCCAoMCgUEAQICARIDdwkYCgwKBQQBAgIDEgN3
GxwKDAoFBAECAggSA3cdRQoPCggEAQICCJwIABIDdx5ECmcKBAQBAgMSA3sCQxpaIFJlcXVp
cmVkLiBUaGUgcmVzdWx0IG9mIHRoZSBkcnkgcnVuIGNoZWNrLiBUcnVlIGlmIGNoZWNrIHBh
c3NlZCwgZmFsc2UgaWYKIGNoZWNrIGZhaWxlZC4KCgwKBQQBAgMFEgN7AgYKDAoFBAECAwES
A3sHFQoMCgUEAQIDAxIDexgZCgwKBQQBAgMIEgN7GkIKDwoIBAECAwicCAASA3sbQQpaCgQE
AQgAEgV+ApYBAxpLIEFkZGl0aW9uYWwgY29udGV4dCBzcGVjaWZpYyB0byB0aGUgQVBJIG1l
dGhvZCB0aGF0IHRyaWdnZXJlZCB0aGUgZHJ5IHJ1bi4KCgwKBQQBCAABEgN+CBoKSQoEBAEC
BBIGgAEEgQExGjkgT3B0aW9uYWwuIENvbnRleHQgZm9yIGBDcmVhdGVXb3JrZmxvd0ludm9j
YXRpb25gIGNhbGxzLgoKDQoFBAECBAYSBIABBCMKDQoFBAECBAESBIABJEYKDQoFBAECBAMS
BIABSUoKDQoFBAECBAgSBIEBCDAKEAoIBAECBAicCAASBIEBCS8KQQoEBAECBRIGhAEEhQEx
GjEgT3B0aW9uYWwuIENvbnRleHQgZm9yIGBDcmVhdGVSZXBvc2l0b3J5YCBjYWxscy4KCg0K
BQQBAgUGEgSEAQQbCg0KBQQBAgUBEgSEARw1Cg0KBQQBAgUDEgSEATg5Cg0KBQQBAgUIEgSF
AQgwChAKCAQBAgUInAgAEgSFAQkvCkEKBAQBAgYSBogBBIkBMRoxIE9wdGlvbmFsLiBDb250
ZXh0IGZvciBgVXBkYXRlUmVwb3NpdG9yeWAgY2FsbHMuCgoNCgUEAQIGBhIEiAEEGwoNCgUE
AQIGARIEiAEcNQoNCgUEAQIGAxIEiAE4OQoNCgUEAQIGCBIEiQEIMAoQCggEAQIGCJwIABIE
iQEJLwpECgQEAQIHEgaMAQSNATEaNCBPcHRpb25hbC4gQ29udGV4dCBmb3IgYFVwZGF0ZVJl
bGVhc2VDb25maWdgIGNhbGxzLgoKDQoFBAECBwYSBIwBBB4KDQoFBAECBwESBIwBHzwKDQoF
BAECBwMSBIwBP0AKDQoFBAECBwgSBI0BCDAKEAoIBAECBwicCAASBI0BCS8KRQoEBAECCBIG
kAEEkQExGjUgT3B0aW9uYWwuIENvbnRleHQgZm9yIGBVcGRhdGVXb3JrZmxvd0NvbmZpZ2Ag
Y2FsbHMuCgoNCgUEAQIIBhIEkAEEHwoNCgUEAQIIARIEkAEgPgoNCgUEAQIIAxIEkAFBQgoN
CgUEAQIICBIEkQEIMAoQCggEAQIICJwIABIEkQEJLwpFCgQEAQIJEgaUAQSVATEaNSBPcHRp
b25hbC4gQ29udGV4dCBmb3IgYENyZWF0ZVdvcmtmbG93Q29uZmlnYCBjYWxscy4KCg0KBQQB
AgkGEgSUAQQfCg0KBQQBAgkBEgSUASA+Cg0KBQQBAgkDEgSUAUFDCg0KBQQBAgkIEgSVAQgw
ChAKCAQBAgkInAgAEgSVAQkvYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry ===
    # Fields for WorkflowInvocationCompletionLogEntry
    # Field: workflow_invocation_id Type: 9 ()
    # Field: workflow_config_id Type: 9 ()
    # Field: release_config_id Type: 9 ()
    # Field: terminal_state Type: 14 (.google.cloud.dataform.logging.v1.WorkflowInvocationCompletionLogEntry.TerminalState)

# Enum: WorkflowInvocationCompletionLogEntry::TerminalState
our $WorkflowInvocationCompletionLogEntry_TERMINAL_STATE_UNSPECIFIED = 0;
our $WorkflowInvocationCompletionLogEntry_SUCCEEDED = 1;
our $WorkflowInvocationCompletionLogEntry_CANCELLED = 2;
our $WorkflowInvocationCompletionLogEntry_FAILED = 3;

# === Message: Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry ===
    # Fields for ActAsDryRunResultLogEntry
    # Field: api_method Type: 9 ()
    # Field: caller Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: dry_run_result Type: 8 ()
    # Field: create_workflow_invocation_context Type: 11 (.google.cloud.dataform.logging.v1.ActAsDryRunResultLogEntry.CreateWorkflowInvocationContext)
    # Field: create_repository_context Type: 11 (.google.cloud.dataform.logging.v1.ActAsDryRunResultLogEntry.CreateRepositoryContext)
    # Field: update_repository_context Type: 11 (.google.cloud.dataform.logging.v1.ActAsDryRunResultLogEntry.UpdateRepositoryContext)
    # Field: update_release_config_context Type: 11 (.google.cloud.dataform.logging.v1.ActAsDryRunResultLogEntry.UpdateReleaseConfigContext)
    # Field: update_workflow_config_context Type: 11 (.google.cloud.dataform.logging.v1.ActAsDryRunResultLogEntry.UpdateWorkflowConfigContext)
    # Field: create_workflow_config_context Type: 11 (.google.cloud.dataform.logging.v1.ActAsDryRunResultLogEntry.CreateWorkflowConfigContext)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataform::Logging::V1::Logging - Compiled Protocol Buffers messages for google/cloud/dataform/logging/v1/logging.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataform::Logging::V1::Logging;

    my $msg = Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry->new({
        workflow_invocation_id => $workflow_invocation_id,
        workflow_config_id => $workflow_config_id,
        release_config_id => $release_config_id,
        terminal_state => $terminal_state,
    });

    # Read or update a field
    my $val = $msg->workflow_invocation_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataform/logging/v1/logging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry

Structured payload for logs generated from Dataform workflow invocation
completions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workflow_invocation_id() >> / C<< $msg->workflow_invocation_id($value) >>

Type: C<String>

Required. Identifier of the workflow invocation.

=item * C<< $msg->workflow_config_id() >> / C<< $msg->workflow_config_id($value) >>

Type: C<String>

Optional. Identifier of the workflow config.

=item * C<< $msg->release_config_id() >> / C<< $msg->release_config_id($value) >>

Type: C<String>

Optional. Identifier of the release config.

=item * C<< $msg->terminal_state() >> / C<< $msg->terminal_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dataform::Logging::V1::WorkflowInvocationCompletionLogEntry::TerminalState>)

Required. The workflow invocation's final termination state.

=back

=head3 Enum: WorkflowInvocationCompletionLogEntry::TerminalState

=over 4

=item * C<TERMINAL_STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<CANCELLED> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry

Structured payload for logs generated from Dataform Act-as dry run results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_method() >> / C<< $msg->api_method($value) >>

Type: C<String>

Required. The API method name that triggered the dry run check.

=item * C<< $msg->caller() >> / C<< $msg->caller($value) >>

Type: C<String>

Required. The caller that triggered the dry run check.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Required. The service account used for the dry run check.

=item * C<< $msg->dry_run_result() >> / C<< $msg->dry_run_result($value) >>

Type: C<Bool>

Required. The result of the dry run check. True if check passed, false if
check failed.

=item * C<< $msg->create_workflow_invocation_context() >> / C<< $msg->create_workflow_invocation_context($value) >>

Type: C<Message> (L<Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowInvocationContext>)

Optional. Context for `CreateWorkflowInvocation` calls.

=item * C<< $msg->create_repository_context() >> / C<< $msg->create_repository_context($value) >>

Type: C<Message> (L<Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateRepositoryContext>)

Optional. Context for `CreateRepository` calls.

=item * C<< $msg->update_repository_context() >> / C<< $msg->update_repository_context($value) >>

Type: C<Message> (L<Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateRepositoryContext>)

Optional. Context for `UpdateRepository` calls.

=item * C<< $msg->update_release_config_context() >> / C<< $msg->update_release_config_context($value) >>

Type: C<Message> (L<Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateReleaseConfigContext>)

Optional. Context for `UpdateReleaseConfig` calls.

=item * C<< $msg->update_workflow_config_context() >> / C<< $msg->update_workflow_config_context($value) >>

Type: C<Message> (L<Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateWorkflowConfigContext>)

Optional. Context for `UpdateWorkflowConfig` calls.

=item * C<< $msg->create_workflow_config_context() >> / C<< $msg->create_workflow_config_context($value) >>

Type: C<Message> (L<Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowConfigContext>)

Optional. Context for `CreateWorkflowConfig` calls.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataform::Logging::V1::Logging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
