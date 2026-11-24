package Google::Cloud::Discoveryengine::V1::Chunk;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NodW5rLnByb3RvEh9nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0
LnByb3RvIq0OCgVDaHVuaxISCgRuYW1lGAEgASgJUgRuYW1lEg4KAmlkGAIgASgJUgJpZBIY
Cgdjb250ZW50GAMgASgJUgdjb250ZW50EjEKD3JlbGV2YW5jZV9zY29yZRgIIAEoAUID4EED
SABSDnJlbGV2YW5jZVNjb3JliAEBEmQKEWRvY3VtZW50X21ldGFkYXRhGAUgASgLMjcuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DaHVuay5Eb2N1bWVudE1ldGFkYXRhUhBk
b2N1bWVudE1ldGFkYXRhEkwKE2Rlcml2ZWRfc3RydWN0X2RhdGEYBCABKAsyFy5nb29nbGUu
cHJvdG9idWYuU3RydWN0QgPgQQNSEWRlcml2ZWRTdHJ1Y3REYXRhEkwKCXBhZ2Vfc3BhbhgG
IAEoCzIvLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ2h1bmsuUGFnZVNwYW5S
CHBhZ2VTcGFuEmAKDmNodW5rX21ldGFkYXRhGAcgASgLMjQuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5DaHVuay5DaHVua01ldGFkYXRhQgPgQQNSDWNodW5rTWV0YWRhdGES
IAoJZGF0YV91cmxzGAkgAygJQgPgQQNSCGRhdGFVcmxzEjQKE2Fubm90YXRpb25fY29udGVu
dHMYCyADKAlCA+BBA1ISYW5ub3RhdGlvbkNvbnRlbnRzEm8KE2Fubm90YXRpb25fbWV0YWRh
dGEYDCADKAsyOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNodW5rLkFubm90
YXRpb25NZXRhZGF0YUID4EEDUhJhbm5vdGF0aW9uTWV0YWRhdGEakQEKEERvY3VtZW50TWV0
YWRhdGESEAoDdXJpGAEgASgJUgN1cmkSFAoFdGl0bGUYAiABKAlSBXRpdGxlEhsKCW1pbWVf
dHlwZRgEIAEoCVIIbWltZVR5cGUSOAoLc3RydWN0X2RhdGEYAyABKAsyFy5nb29nbGUucHJv
dG9idWYuU3RydWN0UgpzdHJ1Y3REYXRhGkQKCFBhZ2VTcGFuEh0KCnBhZ2Vfc3RhcnQYASAB
KAVSCXBhZ2VTdGFydBIZCghwYWdlX2VuZBgCIAEoBVIHcGFnZUVuZBqpAQoNQ2h1bmtNZXRh
ZGF0YRJPCg9wcmV2aW91c19jaHVua3MYASADKAsyJi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkNodW5rUg5wcmV2aW91c0NodW5rcxJHCgtuZXh0X2NodW5rcxgCIAMoCzIm
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ2h1bmtSCm5leHRDaHVua3MalAEK
EVN0cnVjdHVyZWRDb250ZW50EmAKDnN0cnVjdHVyZV90eXBlGAEgASgOMjQuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DaHVuay5TdHJ1Y3R1cmVUeXBlQgPgQQNSDXN0cnVj
dHVyZVR5cGUSHQoHY29udGVudBgCIAEoCUID4EEDUgdjb250ZW50GqIBChJBbm5vdGF0aW9u
TWV0YWRhdGESbAoSc3RydWN0dXJlZF9jb250ZW50GAEgASgLMjguZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5DaHVuay5TdHJ1Y3R1cmVkQ29udGVudEID4EEDUhFzdHJ1Y3R1
cmVkQ29udGVudBIeCghpbWFnZV9pZBgCIAEoCUID4EEDUgdpbWFnZUlkInsKDVN0cnVjdHVy
ZVR5cGUSHgoaU1RSVUNUVVJFX1RZUEVfVU5TUEVDSUZJRUQQABIZChVTSEFSRUhPTERFUl9T
VFJVQ1RVUkUQARIXChNTSUdOQVRVUkVfU1RSVUNUVVJFEAISFgoSQ0hFQ0tCT1hfU1RSVUNU
VVJFEAM6sgLqQa4CCiRkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ2h1bmsSdXBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhU3RvcmVzL3tkYXRh
X3N0b3JlfS9icmFuY2hlcy97YnJhbmNofS9kb2N1bWVudHMve2RvY3VtZW50fS9jaHVua3Mv
e2NodW5rfRKOAXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xs
ZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNoZXMv
e2JyYW5jaH0vZG9jdW1lbnRzL3tkb2N1bWVudH0vY2h1bmtzL3tjaHVua31CEgoQX3JlbGV2
YW5jZV9zY29yZUL9AQojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCCkNo
dW5rUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEv
ZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWq
Ah9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2Nv
dmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFK2zEK
BxIFDgCvAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACYKCAoBCBIDFgA8CgkKAgglEgMWADwK
CAoBCBIDFwBkCgkKAggLEgMXAGQKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQArCgkK
AggIEgMZACsKCAoBCBIDGgA8CgkKAggBEgMaADwKCAoBCBIDGwAtCgkKAggkEgMbAC0KCAoB
CBIDHAA8CgkKAggpEgMcADwKCAoBCBIDHQA7CgkKAggtEgMdADsKdQoCBAASBSEArwEBGmgg
Q2h1bmsgY2FwdHVyZXMgYWxsIHJhdyBtZXRhZGF0YSBpbmZvcm1hdGlvbiBvZiBpdGVtcyB0
byBiZSByZWNvbW1lbmRlZCBvcgogc2VhcmNoZWQgaW4gdGhlIGNodW5rIG1vZGUuCgoKCgME
AAESAyEIDQoLCgMEAAcSBCICJgQKDQoFBAAHnQgSBCICJgQKYQoEBAADABIEKgI6AxpTIERv
Y3VtZW50IG1ldGFkYXRhIGNvbnRhaW5zIHRoZSBpbmZvcm1hdGlvbiBvZiB0aGUgZG9jdW1l
bnQgb2YgdGhlIGN1cnJlbnQKIGNodW5rLgoKDAoFBAADAAESAyoKGgolCgYEAAMAAgASAywE
ExoWIFVyaSBvZiB0aGUgZG9jdW1lbnQuCgoOCgcEAAMAAgAFEgMsBAoKDgoHBAADAAIAARID
LAsOCg4KBwQAAwACAAMSAywREgonCgYEAAMAAgESAy8EFRoYIFRpdGxlIG9mIHRoZSBkb2N1
bWVudC4KCg4KBwQAAwACAQUSAy8ECgoOCgcEAAMAAgEBEgMvCxAKDgoHBAADAAIBAxIDLxMU
CnAKBgQAAwACAhIDMwQZGmEgVGhlIG1pbWUgdHlwZSBvZiB0aGUgZG9jdW1lbnQuCiBodHRw
czovL3d3dy5pYW5hLm9yZy9hc3NpZ25tZW50cy9tZWRpYS10eXBlcy9tZWRpYS10eXBlcy54
aHRtbC4KCg4KBwQAAwACAgUSAzMECgoOCgcEAAMAAgIBEgMzCxQKDgoHBAADAAICAxIDMxcY
CtMBCgYEAAMAAgMSAzkEKxrDASBEYXRhIHJlcHJlc2VudGF0aW9uLgogVGhlIHN0cnVjdHVy
ZWQgSlNPTiBkYXRhIGZvciB0aGUgZG9jdW1lbnQuIEl0IHNob3VsZCBjb25mb3JtIHRvIHRo
ZQogcmVnaXN0ZXJlZCBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LlNjaGVtYV0gb3IgYW4KIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyB0aHJvd24uCgoO
CgcEAAMAAgMGEgM5BBoKDgoHBAADAAIDARIDORsmCg4KBwQAAwACAwMSAzkpKgonCgQEAAMB
EgQ9AkMDGhkgUGFnZSBzcGFuIG9mIHRoZSBjaHVuay4KCgwKBQQAAwEBEgM9ChIKLQoGBAAD
AQIAEgM/BBkaHiBUaGUgc3RhcnQgcGFnZSBvZiB0aGUgY2h1bmsuCgoOCgcEAAMBAgAFEgM/
BAkKDgoHBAADAQIAARIDPwoUCg4KBwQAAwECAAMSAz8XGAorCgYEAAMBAgESA0IEFxocIFRo
ZSBlbmQgcGFnZSBvZiB0aGUgY2h1bmsuCgoOCgcEAAMBAgEFEgNCBAkKDgoHBAADAQIBARID
QgoSCg4KBwQAAwECAQMSA0IVFgqjAQoEBAADAhIESAJWAxqUASBNZXRhZGF0YSBvZiB0aGUg
Y3VycmVudCBjaHVuay4gVGhpcyBmaWVsZCBpcyBvbmx5IHBvcHVsYXRlZCBvbgogW1NlYXJj
aFNlcnZpY2UuU2VhcmNoXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlYXJj
aFNlcnZpY2UuU2VhcmNoXQogQVBJLgoKDAoFBAADAgESA0gKFwrtAgoGBAADAgIAEgNOBCca
3QIgVGhlIHByZXZpb3VzIGNodW5rcyBvZiB0aGUgY3VycmVudCBjaHVuay4gVGhlIG51bWJl
ciBpcyBjb250cm9sbGVkIGJ5CiBbU2VhcmNoUmVxdWVzdC5Db250ZW50U2VhcmNoU3BlYy5D
aHVua1NwZWMubnVtX3ByZXZpb3VzX2NodW5rc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5TZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hTcGVjLkNodW5rU3BlYy5udW1f
cHJldmlvdXNfY2h1bmtzXS4KIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQgb24KIFtT
ZWFyY2hTZXJ2aWNlLlNlYXJjaF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5T
ZWFyY2hTZXJ2aWNlLlNlYXJjaF0KIEFQSS4KCg4KBwQAAwICAAQSA04EDAoOCgcEAAMCAgAG
EgNODRIKDgoHBAADAgIAARIDThMiCg4KBwQAAwICAAMSA04lJgrhAgoGBAADAgIBEgNVBCMa
0QIgVGhlIG5leHQgY2h1bmtzIG9mIHRoZSBjdXJyZW50IGNodW5rLiBUaGUgbnVtYmVyIGlz
IGNvbnRyb2xsZWQgYnkKIFtTZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hTcGVjLkNodW5r
U3BlYy5udW1fbmV4dF9jaHVua3NdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
U2VhcmNoUmVxdWVzdC5Db250ZW50U2VhcmNoU3BlYy5DaHVua1NwZWMubnVtX25leHRfY2h1
bmtzXS4KIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQgb24KIFtTZWFyY2hTZXJ2aWNl
LlNlYXJjaF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TZWFyY2hTZXJ2aWNl
LlNlYXJjaF0KIEFQSS4KCg4KBwQAAwICAQQSA1UEDAoOCgcEAAMCAgEGEgNVDRIKDgoHBAAD
AgIBARIDVRMeCg4KBwQAAwICAQMSA1UhIgozCgQEAAMDEgRZAmADGiUgVGhlIHN0cnVjdHVy
ZWQgY29udGVudCBpbmZvcm1hdGlvbi4KCgwKBQQAAwMBEgNZChsKTAoGBAADAwIAEgRbBFw0
GjwgT3V0cHV0IG9ubHkuIFRoZSBzdHJ1Y3R1cmUgdHlwZSBvZiB0aGUgc3RydWN0dXJlZCBj
b250ZW50LgoKDgoHBAADAwIABhIDWwQRCg4KBwQAAwMCAAESA1sSIAoOCgcEAAMDAgADEgNb
IyQKDgoHBAADAwIACBIDXAgzChEKCgQAAwMCAAicCAASA1wJMgpECgYEAAMDAgESA18EQxo1
IE91dHB1dCBvbmx5LiBUaGUgY29udGVudCBvZiB0aGUgc3RydWN0dXJlZCBjb250ZW50LgoK
DgoHBAADAwIBBRIDXwQKCg4KBwQAAwMCAQESA18LEgoOCgcEAAMDAgEDEgNfFRYKDgoHBAAD
AwIBCBIDXxdCChEKCgQAAwMCAQicCAASA18YQQpZCgQEAAMEEgRjAmsDGksgVGhlIGFubm90
YXRpb24gbWV0YWRhdGEgaW5jbHVkZXMgc3RydWN0dXJlZCBjb250ZW50IGluIHRoZSBjdXJy
ZW50IGNodW5rLgoKDAoFBAADBAESA2MKHApCCgYEAAMEAgASBGUEZjQaMiBPdXRwdXQgb25s
eS4gVGhlIHN0cnVjdHVyZWQgY29udGVudCBpbmZvcm1hdGlvbi4KCg4KBwQAAwQCAAYSA2UE
FQoOCgcEAAMEAgABEgNlFigKDgoHBAADBAIAAxIDZSssCg4KBwQAAwQCAAgSA2YIMwoRCgoE
AAMEAgAInAgAEgNmCTIKYwoGBAADBAIBEgNqBEQaVCBPdXRwdXQgb25seS4gSW1hZ2UgaWQg
aXMgcHJvdmlkZWQgaWYgdGhlIHN0cnVjdHVyZWQgY29udGVudCBpcyBiYXNlZCBvbgogYW4g
aW1hZ2UuCgoOCgcEAAMEAgEFEgNqBAoKDgoHBAADBAIBARIDagsTCg4KBwQAAwQCAQMSA2oW
FwoOCgcEAAMEAgEIEgNqGEMKEQoKBAADBAIBCJwIABIDahlCClIKBAQABAASBG4CegMaRCBE
ZWZpbmVzIHRoZSB0eXBlcyBvZiB0aGUgc3RydWN0dXJlZCBjb250ZW50IHRoYXQgY2FuIGJl
IGV4dHJhY3RlZC4KCgwKBQQABAABEgNuBxQKHwoGBAAEAAIAEgNwBCMaECBEZWZhdWx0IHZh
bHVlLgoKDgoHBAAEAAIAARIDcAQeCg4KBwQABAACAAISA3AhIgonCgYEAAQAAgESA3MEHhoY
IFNoYXJlaG9sZGVyIHN0cnVjdHVyZS4KCg4KBwQABAACAQESA3MEGQoOCgcEAAQAAgECEgNz
HB0KJQoGBAAEAAICEgN2BBwaFiBTaWduYXR1cmUgc3RydWN0dXJlLgoKDgoHBAAEAAICARID
dgQXCg4KBwQABAACAgISA3YaGwokCgYEAAQAAgMSA3kEGxoVIENoZWNrYm94IHN0cnVjdHVy
ZS4KCg4KBwQABAACAwESA3kEFgoOCgcEAAQAAgMCEgN5GRoKrAIKBAQAAgASBIIBAhIanQIg
VGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY2h1bmsuCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0
aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9icmFuY2hlcy97YnJhbmNofS9kb2N1bWVu
dHMve2RvY3VtZW50X2lkfS9jaHVua3Mve2NodW5rX2lkfWAuCgogVGhpcyBmaWVsZCBtdXN0
IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0
CiBjaGFyYWN0ZXJzLgoKDQoFBAACAAUSBIIBAggKDQoFBAACAAESBIIBCQ0KDQoFBAACAAMS
BIIBEBEKNQoEBAACARIEhQECEBonIFVuaXF1ZSBjaHVuayBJRCBvZiB0aGUgY3VycmVudCBj
aHVuay4KCg0KBQQAAgEFEgSFAQIICg0KBQQAAgEBEgSFAQkLCg0KBQQAAgEDEgSFAQ4PCkUK
BAQAAgISBIgBAhUaNyBDb250ZW50IGlzIGEgc3RyaW5nIGZyb20gYSBkb2N1bWVudCAocGFy
c2VkIGNvbnRlbnQpLgoKDQoFBAACAgUSBIgBAggKDQoFBAACAgESBIgBCRAKDQoFBAACAgMS
BIgBExQK/QEKBAQAAgMSBo8BApABMhrsASBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0aGUg
cmVsZXZhbmNlIHNjb3JlIGJhc2VkIG9uIHNpbWlsYXJpdHkuCiBIaWdoZXIgc2NvcmUgaW5k
aWNhdGVzIGhpZ2hlciBjaHVuayByZWxldmFuY2UuCiBUaGUgc2NvcmUgaXMgaW4gcmFuZ2Ug
Wy0xLjAsIDEuMF0uCiBPbmx5IHBvcHVsYXRlZCBvbgogW1NlYXJjaFJlc3BvbnNlXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlYXJjaFJlc3BvbnNlXS4KCg0KBQQAAgME
EgSPAQIKCg0KBQQAAgMFEgSPAQsRCg0KBQQAAgMBEgSPARIhCg0KBQQAAgMDEgSPASQlCg0K
BQQAAgMIEgSQAQYxChAKCAQAAgMInAgAEgSQAQcwCkAKBAQAAgQSBJMBAikaMiBNZXRhZGF0
YSBvZiB0aGUgZG9jdW1lbnQgZnJvbSB0aGUgY3VycmVudCBjaHVuay4KCg0KBQQAAgQGEgST
AQISCg0KBQQAAgQBEgSTARMkCg0KBQQAAgQDEgSTAScoCoABCgQEAAIFEgaXAQKYATIacCBP
dXRwdXQgb25seS4gVGhpcyBmaWVsZCBpcyBPVVRQVVRfT05MWS4KIEl0IGNvbnRhaW5zIGRl
cml2ZWQgZGF0YSB0aGF0IGFyZSBub3QgaW4gdGhlIG9yaWdpbmFsIGlucHV0IGRvY3VtZW50
LgoKDQoFBAACBQYSBJcBAhgKDQoFBAACBQESBJcBGSwKDQoFBAACBQMSBJcBLzAKDQoFBAAC
BQgSBJgBBjEKEAoIBAACBQicCAASBJgBBzAKJwoEBAACBhIEmwECGRoZIFBhZ2Ugc3BhbiBv
ZiB0aGUgY2h1bmsuCgoNCgUEAAIGBhIEmwECCgoNCgUEAAIGARIEmwELFAoNCgUEAAIGAxIE
mwEXGAo7CgQEAAIHEgSeAQJPGi0gT3V0cHV0IG9ubHkuIE1ldGFkYXRhIG9mIHRoZSBjdXJy
ZW50IGNodW5rLgoKDQoFBAACBwYSBJ4BAg8KDQoFBAACBwESBJ4BEB4KDQoFBAACBwMSBJ4B
ISIKDQoFBAACBwgSBJ4BI04KEAoIBAACBwicCAASBJ4BJE0KmQIKBAQAAggSBKUBAkwaigIg
T3V0cHV0IG9ubHkuIEltYWdlIERhdGEgVVJMcyBpZiB0aGUgY3VycmVudCBjaHVuayBjb250
YWlucyBpbWFnZXMuCiBEYXRhIFVSTHMgYXJlIGNvbXBvc2VkIG9mIGZvdXIgcGFydHM6IGEg
cHJlZml4IChkYXRhOiksIGEgTUlNRSB0eXBlCiBpbmRpY2F0aW5nIHRoZSB0eXBlIG9mIGRh
dGEsIGFuIG9wdGlvbmFsIGJhc2U2NCB0b2tlbiBpZiBub24tdGV4dHVhbCwKIGFuZCB0aGUg
ZGF0YSBpdHNlbGY6CiBkYXRhOls8bWVkaWF0eXBlPl1bO2Jhc2U2NF0sPGRhdGE+CgoNCgUE
AAIIBBIEpQECCgoNCgUEAAIIBRIEpQELEQoNCgUEAAIIARIEpQESGwoNCgUEAAIIAxIEpQEe
HwoNCgUEAAIICBIEpQEgSwoQCggEAAIICJwIABIEpQEhSgpdCgQEAAIJEgaoAQKpATIaTSBP
dXRwdXQgb25seS4gQW5ub3RhdGlvbiBjb250ZW50cyBpZiB0aGUgY3VycmVudCBjaHVuayBj
b250YWlucyBhbm5vdGF0aW9ucy4KCg0KBQQAAgkEEgSoAQIKCg0KBQQAAgkFEgSoAQsRCg0K
BQQAAgkBEgSoARIlCg0KBQQAAgkDEgSoASgqCg0KBQQAAgkIEgSpAQYxChAKCAQAAgkInAgA
EgSpAQcwCmkKBAQAAgoSBq0BAq4BMhpZIE91dHB1dCBvbmx5LiBUaGUgYW5ub3RhdGlvbiBt
ZXRhZGF0YSBpbmNsdWRlcyBzdHJ1Y3R1cmVkIGNvbnRlbnQgaW4gdGhlCiBjdXJyZW50IGNo
dW5rLgoKDQoFBAACCgQSBK0BAgoKDQoFBAACCgYSBK0BCx0KDQoFBAACCgESBK0BHjEKDQoF
BAACCgMSBK0BNDYKDQoFBAACCggSBK4BBjEKEAoIBAACCgicCAASBK4BBzBiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Chunk::Chunk ===
    # Fields for Chunk
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: content Type: 9 ()
    # Field: relevance_score Type: 1 ()
    # Field: document_metadata Type: 11 (.google.cloud.discoveryengine.v1.Chunk.DocumentMetadata)
    # Field: derived_struct_data Type: 11 (.google.protobuf.Struct)
    # Field: page_span Type: 11 (.google.cloud.discoveryengine.v1.Chunk.PageSpan)
    # Field: chunk_metadata Type: 11 (.google.cloud.discoveryengine.v1.Chunk.ChunkMetadata)
    # Field: data_urls Type: 9 ()
    # Field: annotation_contents Type: 9 ()
    # Field: annotation_metadata Type: 11 (.google.cloud.discoveryengine.v1.Chunk.AnnotationMetadata)

# Enum: Chunk::StructureType
our $Chunk_STRUCTURE_TYPE_UNSPECIFIED = 0;
our $Chunk_SHAREHOLDER_STRUCTURE = 1;
our $Chunk_SIGNATURE_STRUCTURE = 2;
our $Chunk_CHECKBOX_STRUCTURE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Chunk - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/chunk.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Chunk;

    my $msg = Google::Cloud::Discoveryengine::V1::Chunk::Chunk->new({
        name => $name,
        id => $id,
        content => $content,
        relevance_score => $relevance_score,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Chunk::Chunk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/chunk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Chunk::Chunk

Chunk captures all raw metadata information of items to be recommended or
searched in the chunk mode.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The full resource name of the chunk.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document_id}/chunks/{chunk_id}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Unique chunk ID of the current chunk.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Content is a string from a document (parsed content).

=item * C<< $msg->relevance_score() >> / C<< $msg->relevance_score($value) >>

Type: C<Double>

Output only. Represents the relevance score based on similarity.
Higher score indicates higher chunk relevance.
The score is in range [-1.0, 1.0].
Only populated on
[SearchResponse][google.cloud.discoveryengine.v1.SearchResponse].

=item * C<< $msg->document_metadata() >> / C<< $msg->document_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Chunk::Chunk::DocumentMetadata>)

Metadata of the document from the current chunk.

=item * C<< $msg->derived_struct_data() >> / C<< $msg->derived_struct_data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. This field is OUTPUT_ONLY.
It contains derived data that are not in the original input document.

=item * C<< $msg->page_span() >> / C<< $msg->page_span($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Chunk::Chunk::PageSpan>)

Page span of the chunk.

=item * C<< $msg->chunk_metadata() >> / C<< $msg->chunk_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Chunk::Chunk::ChunkMetadata>)

Output only. Metadata of the current chunk.

=item * C<< $msg->data_urls() >> / C<< $msg->data_urls($value) >>

Type: C<String>

Output only. Image Data URLs if the current chunk contains images.
Data URLs are composed of four parts: a prefix (data:), a MIME type
indicating the type of data, an optional base64 token if non-textual,
and the data itself:
data:[<mediatype>][;base64],<data>

=item * C<< $msg->annotation_contents() >> / C<< $msg->annotation_contents($value) >>

Type: C<String>

Output only. Annotation contents if the current chunk contains annotations.

=item * C<< $msg->annotation_metadata() >> / C<< $msg->annotation_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Chunk::Chunk::AnnotationMetadata>)

Output only. The annotation metadata includes structured content in the
current chunk.

=back

=head3 Enum: Chunk::StructureType

=over 4

=item * C<STRUCTURE_TYPE_UNSPECIFIED> => C<0>

=item * C<SHAREHOLDER_STRUCTURE> => C<1>

=item * C<SIGNATURE_STRUCTURE> => C<2>

=item * C<CHECKBOX_STRUCTURE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Chunk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
