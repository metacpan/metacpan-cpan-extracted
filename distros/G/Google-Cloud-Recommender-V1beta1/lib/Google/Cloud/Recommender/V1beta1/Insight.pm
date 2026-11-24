package Google::Cloud::Recommender::V1beta1::Insight;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjFiZXRhMS9pbnNpZ2h0LnByb3RvEiBnb29n
bGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3Ry
dWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIvwKCgdJbnNpZ2h0
EhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9u
EikKEHRhcmdldF9yZXNvdXJjZXMYCSADKAlSD3RhcmdldFJlc291cmNlcxInCg9pbnNpZ2h0
X3N1YnR5cGUYCiABKAlSDmluc2lnaHRTdWJ0eXBlEjEKB2NvbnRlbnQYAyABKAsyFy5nb29n
bGUucHJvdG9idWYuU3RydWN0Ugdjb250ZW50EkYKEWxhc3RfcmVmcmVzaF90aW1lGAQgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIPbGFzdFJlZnJlc2hUaW1lEkgKEm9ic2Vy
dmF0aW9uX3BlcmlvZBgFIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIRb2JzZXJ2
YXRpb25QZXJpb2QSUQoKc3RhdGVfaW5mbxgGIAEoCzIyLmdvb2dsZS5jbG91ZC5yZWNvbW1l
bmRlci52MWJldGExLkluc2lnaHRTdGF0ZUluZm9SCXN0YXRlSW5mbxJOCghjYXRlZ29yeRgH
IAEoDjIyLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLkluc2lnaHQuQ2F0ZWdv
cnlSCGNhdGVnb3J5Ek4KCHNldmVyaXR5GA8gASgOMjIuZ29vZ2xlLmNsb3VkLnJlY29tbWVu
ZGVyLnYxYmV0YTEuSW5zaWdodC5TZXZlcml0eVIIc2V2ZXJpdHkSEgoEZXRhZxgLIAEoCVIE
ZXRhZxKAAQoaYXNzb2NpYXRlZF9yZWNvbW1lbmRhdGlvbnMYCCADKAsyQS5nb29nbGUuY2xv
dWQucmVjb21tZW5kZXIudjFiZXRhMS5JbnNpZ2h0LlJlY29tbWVuZGF0aW9uUmVmZXJlbmNl
Uhlhc3NvY2lhdGVkUmVjb21tZW5kYXRpb25zGkEKF1JlY29tbWVuZGF0aW9uUmVmZXJlbmNl
EiYKDnJlY29tbWVuZGF0aW9uGAEgASgJUg5yZWNvbW1lbmRhdGlvbiJgCghDYXRlZ29yeRIY
ChRDQVRFR09SWV9VTlNQRUNJRklFRBAAEggKBENPU1QQARIMCghTRUNVUklUWRACEg8KC1BF
UkZPUk1BTkNFEAMSEQoNTUFOQUdFQUJJTElUWRAEIlEKCFNldmVyaXR5EhgKFFNFVkVSSVRZ
X1VOU1BFQ0lGSUVEEAASBwoDTE9XEAESCgoGTUVESVVNEAISCAoESElHSBADEgwKCENSSVRJ
Q0FMEAQ6nwPqQZsDCiJyZWNvbW1lbmRlci5nb29nbGVhcGlzLmNvbS9JbnNpZ2h0ElZwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zaWdodFR5cGVzL3tpbnNp
Z2h0X3R5cGV9L2luc2lnaHRzL3tpbnNpZ2h0fRJlYmlsbGluZ0FjY291bnRzL3tiaWxsaW5n
X2FjY291bnR9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc2lnaHRUeXBlcy97aW5zaWdodF90
eXBlfS9pbnNpZ2h0cy97aW5zaWdodH0SVGZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vaW5zaWdodFR5cGVzL3tpbnNpZ2h0X3R5cGV9L2luc2lnaHRzL3tpbnNpZ2h0
fRJgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9p
bnNpZ2h0VHlwZXMve2luc2lnaHRfdHlwZX0vaW5zaWdodHMve2luc2lnaHR9ItsCChBJbnNp
Z2h0U3RhdGVJbmZvEk4KBXN0YXRlGAEgASgOMjguZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVy
LnYxYmV0YTEuSW5zaWdodFN0YXRlSW5mby5TdGF0ZVIFc3RhdGUSbAoOc3RhdGVfbWV0YWRh
dGEYAiADKAsyRS5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMS5JbnNpZ2h0U3Rh
dGVJbmZvLlN0YXRlTWV0YWRhdGFFbnRyeVINc3RhdGVNZXRhZGF0YRpAChJTdGF0ZU1ldGFk
YXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJH
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEgwKCEFDQ0VQVEVE
EAISDQoJRElTTUlTU0VEEAMimAMKC0luc2lnaHRUeXBlEhIKBG5hbWUYASABKAlSBG5hbWU6
9ALqQfACCiZyZWNvbW1lbmRlci5nb29nbGVhcGlzLmNvbS9JbnNpZ2h0VHlwZRJDcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc2lnaHRUeXBlcy97aW5zaWdo
dF90eXBlfRJSYmlsbGluZ0FjY291bnRzL3tiaWxsaW5nX2FjY291bnR9L2xvY2F0aW9ucy97
bG9jYXRpb259L2luc2lnaHRUeXBlcy97aW5zaWdodF90eXBlfRJBZm9sZGVycy97Zm9sZGVy
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnNpZ2h0VHlwZXMve2luc2lnaHRfdHlwZX0STW9y
Z2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zaWdo
dFR5cGVzL3tpbnNpZ2h0X3R5cGV9EhtpbnNpZ2h0VHlwZXMve2luc2lnaHRfdHlwZX1CmgEK
JGNvbS5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMVABWkZjbG91ZC5nb29nbGUu
Y29tL2dvL3JlY29tbWVuZGVyL2FwaXYxYmV0YTEvcmVjb21tZW5kZXJwYjtyZWNvbW1lbmRl
cnBiogIEQ1JFQ6oCIEdvb2dsZS5DbG91ZC5SZWNvbW1lbmRlci5WMUJldGExStgnCgcSBQ4A
qQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMA
EgMSACMKCQoCAwESAxMAKAoJCgIDAhIDFAAmCgkKAgMDEgMVACkKCAoBCBIDFwA9CgkKAggl
EgMXAD0KCAoBCBIDGABdCgkKAggLEgMYAF0KCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBID
GgA9CgkKAggBEgMaAD0KCAoBCBIDGwAiCgkKAggkEgMbACIKiQEKAgQAEgQfAHsBGn0gQW4g
aW5zaWdodCBhbG9uZyB3aXRoIHRoZSBpbmZvcm1hdGlvbiB1c2VkIHRvIGRlcml2ZSB0aGUg
aW5zaWdodC4gVGhlIGluc2lnaHQKIG1heSBoYXZlIGFzc29jaWF0ZWQgcmVjb21tZW5kYXRp
b25zIGFzIHdlbGwuCgoKCgMEAAESAx8IDwoLCgMEAAcSBCACJgQKDQoFBAAHnQgSBCACJgQK
IQoEBAAEABIEKQI4AxoTIEluc2lnaHQgY2F0ZWdvcnkuCgoMCgUEAAQAARIDKQcPCiYKBgQA
BAACABIDKwQdGhcgVW5zcGVjaWZpZWQgY2F0ZWdvcnkuCgoOCgcEAAQAAgABEgMrBBgKDgoH
BAAEAAIAAhIDKxscCjAKBgQABAACARIDLgQNGiEgVGhlIGluc2lnaHQgaXMgcmVsYXRlZCB0
byBjb3N0LgoKDgoHBAAEAAIBARIDLgQICg4KBwQABAACAQISAy4LDAo0CgYEAAQAAgISAzEE
ERolIFRoZSBpbnNpZ2h0IGlzIHJlbGF0ZWQgdG8gc2VjdXJpdHkuCgoOCgcEAAQAAgIBEgMx
BAwKDgoHBAAEAAICAhIDMQ8QCjcKBgQABAACAxIDNAQUGiggVGhlIGluc2lnaHQgaXMgcmVs
YXRlZCB0byBwZXJmb3JtYW5jZS4KCg4KBwQABAACAwESAzQEDwoOCgcEAAQAAgMCEgM0EhMK
OgoGBAAEAAIEEgM3BBYaKyBUaGlzIGluc2lnaHQgaXMgcmVsYXRlZCB0byBtYW5hZ2VhYmls
aXR5LgoKDgoHBAAEAAIEARIDNwQRCg4KBwQABAACBAISAzcUFQooCgQEAAQBEgQ7AkoDGhog
SW5zaWdodCBzZXZlcml0eSBsZXZlbHMuCgoMCgUEAAQBARIDOwcPCjIKBgQABAECABIDPQQd
GiMgSW5zaWdodCBoYXMgdW5zcGVjaWZpZWQgc2V2ZXJpdHkuCgoOCgcEAAQBAgABEgM9BBgK
DgoHBAAEAQIAAhIDPRscCioKBgQABAECARIDQAQMGhsgSW5zaWdodCBoYXMgbG93IHNldmVy
aXR5LgoKDgoHBAAEAQIBARIDQAQHCg4KBwQABAECAQISA0AKCwotCgYEAAQBAgISA0MEDxoe
IEluc2lnaHQgaGFzIG1lZGl1bSBzZXZlcml0eS4KCg4KBwQABAECAgESA0MECgoOCgcEAAQB
AgICEgNDDQ4KKwoGBAAEAQIDEgNGBA0aHCBJbnNpZ2h0IGhhcyBoaWdoIHNldmVyaXR5LgoK
DgoHBAAEAQIDARIDRgQICg4KBwQABAECAwISA0YLDAovCgYEAAQBAgQSA0kEERogIEluc2ln
aHQgaGFzIGNyaXRpY2FsIHNldmVyaXR5LgoKDgoHBAAEAQIEARIDSQQMCg4KBwQABAECBAIS
A0kPEAo6CgQEAAMAEgRNAlEDGiwgUmVmZXJlbmNlIHRvIGFuIGFzc29jaWF0ZWQgcmVjb21t
ZW5kYXRpb24uCgoMCgUEAAMAARIDTQohCqYBCgYEAAMAAgASA1AEHhqWASBSZWNvbW1lbmRh
dGlvbiByZXNvdXJjZSBuYW1lLCBlLmcuCiBwcm9qZWN0cy9bUFJPSkVDVF9OVU1CRVJdL2xv
Y2F0aW9ucy9bTE9DQVRJT05dL3JlY29tbWVuZGVycy9bUkVDT01NRU5ERVJfSURdL3JlY29t
bWVuZGF0aW9ucy9bUkVDT01NRU5EQVRJT05fSURdCgoOCgcEAAMAAgAFEgNQBAoKDgoHBAAD
AAIAARIDUAsZCg4KBwQAAwACAAMSA1AcHQojCgQEAAIAEgNUAhIaFiBOYW1lIG9mIHRoZSBp
bnNpZ2h0LgoKDAoFBAACAAUSA1QCCAoMCgUEAAIAARIDVAkNCgwKBQQAAgADEgNUEBEKYgoE
BAACARIDWAIZGlUgRnJlZS1mb3JtIGh1bWFuIHJlYWRhYmxlIHN1bW1hcnkgaW4gRW5nbGlz
aC4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDUwMAogY2hhcmFjdGVycy4KCgwKBQQAAgEFEgNY
AggKDAoFBAACAQESA1gJFAoMCgUEAAIBAxIDWBcYCk0KBAQAAgISA1sCJxpAIEZ1bGx5IHF1
YWxpZmllZCByZXNvdXJjZSBuYW1lcyB0aGF0IHRoaXMgaW5zaWdodCBpcyB0YXJnZXRpbmcu
CgoMCgUEAAICBBIDWwIKCgwKBQQAAgIFEgNbCxEKDAoFBAACAgESA1sSIgoMCgUEAAICAxID
WyUmCloKBAQAAgMSA14CHhpNIEluc2lnaHQgc3VidHlwZS4gSW5zaWdodCBjb250ZW50IHNj
aGVtYSB3aWxsIGJlIHN0YWJsZSBmb3IgYSBnaXZlbiBzdWJ0eXBlLgoKDAoFBAACAwUSA14C
CAoMCgUEAAIDARIDXgkYCgwKBQQAAgMDEgNeGx0KbAoEBAACBBIDYgIlGl8gQSBzdHJ1Y3Qg
b2YgY3VzdG9tIGZpZWxkcyB0byBleHBsYWluIHRoZSBpbnNpZ2h0LgogRXhhbXBsZTogImdy
YW50ZWRQZXJtaXNzaW9uc0NvdW50IjogIjEwMDAiCgoMCgUEAAIEBhIDYgIYCgwKBQQAAgQB
EgNiGSAKDAoFBAACBAMSA2IjJApJCgQEAAIFEgNlAjIaPCBUaW1lc3RhbXAgb2YgdGhlIGxh
dGVzdCBkYXRhIHVzZWQgdG8gZ2VuZXJhdGUgdGhlIGluc2lnaHQuCgoMCgUEAAIFBhIDZQIb
CgwKBQQAAgUBEgNlHC0KDAoFBAACBQMSA2UwMQq8AQoEBAACBhIDagIyGq4BIE9ic2VydmF0
aW9uIHBlcmlvZCB0aGF0IGxlZCB0byB0aGUgaW5zaWdodC4gVGhlIHNvdXJjZSBkYXRhIHVz
ZWQgdG8KIGdlbmVyYXRlIHRoZSBpbnNpZ2h0IGVuZHMgYXQgbGFzdF9yZWZyZXNoX3RpbWUg
YW5kIGJlZ2lucyBhdAogKGxhc3RfcmVmcmVzaF90aW1lIC0gb2JzZXJ2YXRpb25fcGVyaW9k
KS4KCgwKBQQAAgYGEgNqAhoKDAoFBAACBgESA2obLQoMCgUEAAIGAxIDajAxCi4KBAQAAgcS
A20CIhohIEluZm9ybWF0aW9uIHN0YXRlIGFuZCBtZXRhZGF0YS4KCgwKBQQAAgcGEgNtAhIK
DAoFBAACBwESA20THQoMCgUEAAIHAxIDbSAhCjYKBAQAAggSA3ACGBopIENhdGVnb3J5IGJl
aW5nIHRhcmdldGVkIGJ5IHRoZSBpbnNpZ2h0LgoKDAoFBAACCAYSA3ACCgoMCgUEAAIIARID
cAsTCgwKBQQAAggDEgNwFhcKIgoEBAACCRIDcwIZGhUgSW5zaWdodCdzIHNldmVyaXR5LgoK
DAoFBAACCQYSA3MCCgoMCgUEAAIJARIDcwsTCgwKBQQAAgkDEgNzFhgKXQoEBAACChIDdwIT
GlAgRmluZ2VycHJpbnQgb2YgdGhlIEluc2lnaHQuIFByb3ZpZGVzIG9wdGltaXN0aWMgbG9j
a2luZyB3aGVuIHVwZGF0aW5nCiBzdGF0ZXMuCgoMCgUEAAIKBRIDdwIICgwKBQQAAgoBEgN3
CQ0KDAoFBAACCgMSA3cQEgo5CgQEAAILEgN6AkIaLCBSZWNvbW1lbmRhdGlvbnMgZGVyaXZl
ZCBmcm9tIHRoaXMgaW5zaWdodC4KCgwKBQQAAgsEEgN6AgoKDAoFBAACCwYSA3oLIgoMCgUE
AAILARIDeiM9CgwKBQQAAgsDEgN6QEEKNAoCBAESBX4AmQEBGicgSW5mb3JtYXRpb24gcmVs
YXRlZCB0byBpbnNpZ2h0IHN0YXRlLgoKCgoDBAEBEgN+CBgKKwoEBAEEABIGgAECkgEDGhsg
UmVwcmVzZW50cyBpbnNpZ2h0IHN0YXRlLgoKDQoFBAEEAAESBIABBwwKJAoGBAEEAAIAEgSC
AQQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoPCgcEAQQAAgABEgSCAQQVCg8KBwQBBAACAAIS
BIIBGBkKkQEKBgQBBAACARIEhgEEDxqAASBJbnNpZ2h0IGlzIGFjdGl2ZS4gQ29udGVudCBm
b3IgQUNUSVZFIGluc2lnaHRzIGNhbiBiZSB1cGRhdGVkIGJ5IEdvb2dsZS4KIEFDVElWRSBp
bnNpZ2h0cyBjYW4gYmUgbWFya2VkIERJU01JU1NFRCBPUiBBQ0NFUFRFRC4KCg8KBwQBBAAC
AQESBIYBBAoKDwoHBAEEAAIBAhIEhgENDgr0AgoGBAEEAAICEgSNAQQRGuMCIFNvbWUgYWN0
aW9uIGhhcyBiZWVuIHRha2VuIGJhc2VkIG9uIHRoaXMgaW5zaWdodC4gSW5zaWdodHMgYmVj
b21lCiBhY2NlcHRlZCB3aGVuIGEgcmVjb21tZW5kYXRpb24gZGVyaXZlZCBmcm9tIHRoZSBp
bnNpZ2h0IGhhcyBiZWVuIG1hcmtlZAogQ0xBSU1FRCwgU1VDQ0VFREVELCBvciBGQUlMRUQu
IEFDVElWRSBpbnNpZ2h0cyBjYW4gYWxzbyBiZSBtYXJrZWQKIEFDQ0VQVEVEIGV4cGxpY2l0
bHkuIENvbnRlbnQgZm9yIEFDQ0VQVEVEIGluc2lnaHRzIGlzIGltbXV0YWJsZS4gQUNDRVBU
RUQKIGluc2lnaHRzIGNhbiBvbmx5IGJlIG1hcmtlZCBBQ0NFUFRFRCAod2hpY2ggbWF5IHVw
ZGF0ZSBzdGF0ZSBtZXRhZGF0YSkuCgoPCgcEAQQAAgIBEgSNAQQMCg8KBwQBBAACAgISBI0B
DxAKjQEKBgQBBAACAxIEkQEEEhp9IEluc2lnaHQgaXMgZGlzbWlzc2VkLiBDb250ZW50IGZv
ciBESVNNSVNTRUQgaW5zaWdodHMgY2FuIGJlIHVwZGF0ZWQgYnkKIEdvb2dsZS4gRElTTUlT
U0VEIGluc2lnaHRzIGNhbiBiZSBtYXJrZWQgYXMgQUNUSVZFLgoKDwoHBAEEAAIDARIEkQEE
DQoPCgcEAQQAAgMCEgSRARARCh4KBAQBAgASBJUBAhIaECBJbnNpZ2h0IHN0YXRlLgoKDQoF
BAECAAYSBJUBAgcKDQoFBAECAAESBJUBCA0KDQoFBAECAAMSBJUBEBEKWQoEBAECARIEmAEC
KRpLIEEgbWFwIG9mIG1ldGFkYXRhIGZvciB0aGUgc3RhdGUsIHByb3ZpZGVkIGJ5IHVzZXIg
b3IgYXV0b21hdGlvbnMgc3lzdGVtcy4KCg0KBQQBAgEGEgSYAQIVCg0KBQQBAgEBEgSYARYk
Cg0KBQQBAgEDEgSYAScoCiQKAgQCEgacAQCpAQEaFiBUaGUgdHlwZSBvZiBpbnNpZ2h0LgoK
CwoDBAIBEgScAQgTCg0KAwQCBxIGnQECpAEECg8KBQQCB50IEgadAQKkAQQKewoEBAICABIE
qAECEhptIFRoZSBpbnNpZ2h0X3R5cGXigJlzIG5hbWUgaW4gZm9ybWF0IGluc2lnaHRUeXBl
cy97aW5zaWdodF90eXBlfQogZWc6IGluc2lnaHRUeXBlcy9nb29nbGUuaWFtLnBvbGljeS5J
bnNpZ2h0CgoNCgUEAgIABRIEqAECCAoNCgUEAgIAARIEqAEJDQoNCgUEAgIAAxIEqAEQEWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1beta1::Insight::Insight ===
    # Fields for Insight
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: target_resources Type: 9 ()
    # Field: insight_subtype Type: 9 ()
    # Field: content Type: 11 (.google.protobuf.Struct)
    # Field: last_refresh_time Type: 11 (.google.protobuf.Timestamp)
    # Field: observation_period Type: 11 (.google.protobuf.Duration)
    # Field: state_info Type: 11 (.google.cloud.recommender.v1beta1.InsightStateInfo)
    # Field: category Type: 14 (.google.cloud.recommender.v1beta1.Insight.Category)
    # Field: severity Type: 14 (.google.cloud.recommender.v1beta1.Insight.Severity)
    # Field: etag Type: 9 ()
    # Field: associated_recommendations Type: 11 (.google.cloud.recommender.v1beta1.Insight.RecommendationReference)

# Enum: Insight::Category
our $Insight_CATEGORY_UNSPECIFIED = 0;
our $Insight_COST = 1;
our $Insight_SECURITY = 2;
our $Insight_PERFORMANCE = 3;
our $Insight_MANAGEABILITY = 4;

# Enum: Insight::Severity
our $Insight_SEVERITY_UNSPECIFIED = 0;
our $Insight_LOW = 1;
our $Insight_MEDIUM = 2;
our $Insight_HIGH = 3;
our $Insight_CRITICAL = 4;

# === Message: Google::Cloud::Recommender::V1beta1::Insight::InsightStateInfo ===
    # Fields for InsightStateInfo
    # Field: state Type: 14 (.google.cloud.recommender.v1beta1.InsightStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.v1beta1.InsightStateInfo.StateMetadataEntry)

# Enum: InsightStateInfo::State
our $InsightStateInfo_STATE_UNSPECIFIED = 0;
our $InsightStateInfo_ACTIVE = 1;
our $InsightStateInfo_ACCEPTED = 2;
our $InsightStateInfo_DISMISSED = 3;

# === Message: Google::Cloud::Recommender::V1beta1::Insight::InsightType ===
    # Fields for InsightType
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1beta1::Insight - Compiled Protocol Buffers messages for google/cloud/recommender/v1beta1/insight.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1beta1::Insight;

    my $msg = Google::Cloud::Recommender::V1beta1::Insight::Insight->new({
        name => $name,
        description => $description,
        target_resources => $target_resources,
        insight_subtype => $insight_subtype,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1beta1::Insight::Insight->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1beta1/insight.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1beta1::Insight::Insight

An insight along with the information used to derive the insight. The insight
may have associated recommendations as well.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the insight.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Free-form human readable summary in English. The maximum length is 500
characters.

=item * C<< $msg->target_resources() >> / C<< $msg->target_resources($value) >>

Type: C<String>

Fully qualified resource names that this insight is targeting.

=item * C<< $msg->insight_subtype() >> / C<< $msg->insight_subtype($value) >>

Type: C<String>

Insight subtype. Insight content schema will be stable for a given subtype.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

A struct of custom fields to explain the insight.
Example: "grantedPermissionsCount": "1000"

=item * C<< $msg->last_refresh_time() >> / C<< $msg->last_refresh_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of the latest data used to generate the insight.

=item * C<< $msg->observation_period() >> / C<< $msg->observation_period($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Observation period that led to the insight. The source data used to
generate the insight ends at last_refresh_time and begins at
(last_refresh_time - observation_period).

=item * C<< $msg->state_info() >> / C<< $msg->state_info($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Insight::InsightStateInfo>)

Information state and metadata.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::Insight::Category>)

Category being targeted by the insight.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::Insight::Severity>)

Insight's severity.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Fingerprint of the Insight. Provides optimistic locking when updating
states.

=item * C<< $msg->associated_recommendations() >> / C<< $msg->associated_recommendations($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Insight::Insight::RecommendationReference>)

Recommendations derived from this insight.

=back

=head3 Enum: Insight::Category

=over 4

=item * C<CATEGORY_UNSPECIFIED> => C<0>

=item * C<COST> => C<1>

=item * C<SECURITY> => C<2>

=item * C<PERFORMANCE> => C<3>

=item * C<MANAGEABILITY> => C<4>

=back

=head3 Enum: Insight::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<LOW> => C<1>

=item * C<MEDIUM> => C<2>

=item * C<HIGH> => C<3>

=item * C<CRITICAL> => C<4>

=back

=head2 Google::Cloud::Recommender::V1beta1::Insight::InsightStateInfo

Information related to insight state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::InsightStateInfo::State>)

Insight state.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Insight::InsightStateInfo::StateMetadataEntry>)

A map of metadata for the state, provided by user or automations systems.

=back

=head3 Enum: InsightStateInfo::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<ACCEPTED> => C<2>

=item * C<DISMISSED> => C<3>

=back

=head2 Google::Cloud::Recommender::V1beta1::Insight::InsightType

The type of insight.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The insight_type’s name in format insightTypes/{insight_type}
eg: insightTypes/google.iam.policy.Insight

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1beta1::Insight::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
