package Google::Cloud::Discoveryengine::V1beta::Chunk;

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
Ci9nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jaHVuay5wcm90bxIjZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90b2J1
Zi9zdHJ1Y3QucHJvdG8izQ4KBUNodW5rEhIKBG5hbWUYASABKAlSBG5hbWUSDgoCaWQYAiAB
KAlSAmlkEhgKB2NvbnRlbnQYAyABKAlSB2NvbnRlbnQSMQoPcmVsZXZhbmNlX3Njb3JlGAgg
ASgBQgPgQQNIAFIOcmVsZXZhbmNlU2NvcmWIAQESaAoRZG9jdW1lbnRfbWV0YWRhdGEYBSAB
KAsyOy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DaHVuay5Eb2N1bWVu
dE1ldGFkYXRhUhBkb2N1bWVudE1ldGFkYXRhEkwKE2Rlcml2ZWRfc3RydWN0X2RhdGEYBCAB
KAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQNSEWRlcml2ZWRTdHJ1Y3REYXRhElAK
CXBhZ2Vfc3BhbhgGIAEoCzIzLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkNodW5rLlBhZ2VTcGFuUghwYWdlU3BhbhJkCg5jaHVua19tZXRhZGF0YRgHIAEoCzI4Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNodW5rLkNodW5rTWV0YWRhdGFC
A+BBA1INY2h1bmtNZXRhZGF0YRIgCglkYXRhX3VybHMYCSADKAlCA+BBA1IIZGF0YVVybHMS
NAoTYW5ub3RhdGlvbl9jb250ZW50cxgLIAMoCUID4EEDUhJhbm5vdGF0aW9uQ29udGVudHMS
cwoTYW5ub3RhdGlvbl9tZXRhZGF0YRgMIAMoCzI9Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkNodW5rLkFubm90YXRpb25NZXRhZGF0YUID4EEDUhJhbm5vdGF0aW9u
TWV0YWRhdGEakQEKEERvY3VtZW50TWV0YWRhdGESEAoDdXJpGAEgASgJUgN1cmkSFAoFdGl0
bGUYAiABKAlSBXRpdGxlEhsKCW1pbWVfdHlwZRgEIAEoCVIIbWltZVR5cGUSOAoLc3RydWN0
X2RhdGEYAyABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgpzdHJ1Y3REYXRhGkQKCFBh
Z2VTcGFuEh0KCnBhZ2Vfc3RhcnQYASABKAVSCXBhZ2VTdGFydBIZCghwYWdlX2VuZBgCIAEo
BVIHcGFnZUVuZBqxAQoNQ2h1bmtNZXRhZGF0YRJTCg9wcmV2aW91c19jaHVua3MYASADKAsy
Ki5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DaHVua1IOcHJldmlvdXND
aHVua3MSSwoLbmV4dF9jaHVua3MYAiADKAsyKi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5DaHVua1IKbmV4dENodW5rcxqYAQoRU3RydWN0dXJlZENvbnRlbnQSZAoO
c3RydWN0dXJlX3R5cGUYASABKA4yOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5DaHVuay5TdHJ1Y3R1cmVUeXBlQgPgQQNSDXN0cnVjdHVyZVR5cGUSHQoHY29udGVu
dBgCIAEoCUID4EEDUgdjb250ZW50GqYBChJBbm5vdGF0aW9uTWV0YWRhdGEScAoSc3RydWN0
dXJlZF9jb250ZW50GAEgASgLMjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuQ2h1bmsuU3RydWN0dXJlZENvbnRlbnRCA+BBA1IRc3RydWN0dXJlZENvbnRlbnQSHgoI
aW1hZ2VfaWQYAiABKAlCA+BBA1IHaW1hZ2VJZCJ7Cg1TdHJ1Y3R1cmVUeXBlEh4KGlNUUlVD
VFVSRV9UWVBFX1VOU1BFQ0lGSUVEEAASGQoVU0hBUkVIT0xERVJfU1RSVUNUVVJFEAESFwoT
U0lHTkFUVVJFX1NUUlVDVFVSRRACEhYKEkNIRUNLQk9YX1NUUlVDVFVSRRADOrIC6kGuAgok
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NodW5rEnVwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNo
ZXMve2JyYW5jaH0vZG9jdW1lbnRzL3tkb2N1bWVudH0vY2h1bmtzL3tjaHVua30SjgFwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxl
Y3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9L2RvY3Vt
ZW50cy97ZG9jdW1lbnR9L2NodW5rcy97Y2h1bmt9QhIKEF9yZWxldmFuY2Vfc2NvcmVCkQIK
J2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIKQ2h1bmtQcm90b1AB
WlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292
ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29n
bGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3Zl
cnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJl
dGFK9zEKBxIFDgCvAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACYKCAoBCBIDFgBACgkKAggl
EgMWAEAKCAoBCBIDFwBoCgkKAggLEgMXAGgKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBID
GQArCgkKAggIEgMZACsKCAoBCBIDGgBACgkKAggBEgMaAEAKCAoBCBIDGwAtCgkKAggkEgMb
AC0KCAoBCBIDHABACgkKAggpEgMcAEAKCAoBCBIDHQA/CgkKAggtEgMdAD8KdQoCBAASBSEA
rwEBGmggQ2h1bmsgY2FwdHVyZXMgYWxsIHJhdyBtZXRhZGF0YSBpbmZvcm1hdGlvbiBvZiBp
dGVtcyB0byBiZSByZWNvbW1lbmRlZCBvcgogc2VhcmNoZWQgaW4gdGhlIGNodW5rIG1vZGUu
CgoKCgMEAAESAyEIDQoLCgMEAAcSBCICJgQKDQoFBAAHnQgSBCICJgQKYQoEBAADABIEKgI6
AxpTIERvY3VtZW50IG1ldGFkYXRhIGNvbnRhaW5zIHRoZSBpbmZvcm1hdGlvbiBvZiB0aGUg
ZG9jdW1lbnQgb2YgdGhlIGN1cnJlbnQKIGNodW5rLgoKDAoFBAADAAESAyoKGgolCgYEAAMA
AgASAywEExoWIFVyaSBvZiB0aGUgZG9jdW1lbnQuCgoOCgcEAAMAAgAFEgMsBAoKDgoHBAAD
AAIAARIDLAsOCg4KBwQAAwACAAMSAywREgonCgYEAAMAAgESAy8EFRoYIFRpdGxlIG9mIHRo
ZSBkb2N1bWVudC4KCg4KBwQAAwACAQUSAy8ECgoOCgcEAAMAAgEBEgMvCxAKDgoHBAADAAIB
AxIDLxMUCnAKBgQAAwACAhIDMwQZGmEgVGhlIG1pbWUgdHlwZSBvZiB0aGUgZG9jdW1lbnQu
CiBodHRwczovL3d3dy5pYW5hLm9yZy9hc3NpZ25tZW50cy9tZWRpYS10eXBlcy9tZWRpYS10
eXBlcy54aHRtbC4KCg4KBwQAAwACAgUSAzMECgoOCgcEAAMAAgIBEgMzCxQKDgoHBAADAAIC
AxIDMxcYCtcBCgYEAAMAAgMSAzkEKxrHASBEYXRhIHJlcHJlc2VudGF0aW9uLgogVGhlIHN0
cnVjdHVyZWQgSlNPTiBkYXRhIGZvciB0aGUgZG9jdW1lbnQuIEl0IHNob3VsZCBjb25mb3Jt
IHRvIHRoZQogcmVnaXN0ZXJlZCBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5TY2hlbWFdIG9yIGFuCiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMg
dGhyb3duLgoKDgoHBAADAAIDBhIDOQQaCg4KBwQAAwACAwESAzkbJgoOCgcEAAMAAgMDEgM5
KSoKJwoEBAADARIEPQJDAxoZIFBhZ2Ugc3BhbiBvZiB0aGUgY2h1bmsuCgoMCgUEAAMBARID
PQoSCi0KBgQAAwECABIDPwQZGh4gVGhlIHN0YXJ0IHBhZ2Ugb2YgdGhlIGNodW5rLgoKDgoH
BAADAQIABRIDPwQJCg4KBwQAAwECAAESAz8KFAoOCgcEAAMBAgADEgM/FxgKKwoGBAADAQIB
EgNCBBcaHCBUaGUgZW5kIHBhZ2Ugb2YgdGhlIGNodW5rLgoKDgoHBAADAQIBBRIDQgQJCg4K
BwQAAwECAQESA0IKEgoOCgcEAAMBAgEDEgNCFRYKpwEKBAQAAwISBEgCVgMamAEgTWV0YWRh
dGEgb2YgdGhlIGN1cnJlbnQgY2h1bmsuIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQg
b24KIFtTZWFyY2hTZXJ2aWNlLlNlYXJjaF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuU2VhcmNoU2VydmljZS5TZWFyY2hdCiBBUEkuCgoMCgUEAAMCARIDSAoXCvUC
CgYEAAMCAgASA04EJxrlAiBUaGUgcHJldmlvdXMgY2h1bmtzIG9mIHRoZSBjdXJyZW50IGNo
dW5rLiBUaGUgbnVtYmVyIGlzIGNvbnRyb2xsZWQgYnkKIFtTZWFyY2hSZXF1ZXN0LkNvbnRl
bnRTZWFyY2hTcGVjLkNodW5rU3BlYy5udW1fcHJldmlvdXNfY2h1bmtzXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hT
cGVjLkNodW5rU3BlYy5udW1fcHJldmlvdXNfY2h1bmtzXS4KIFRoaXMgZmllbGQgaXMgb25s
eSBwb3B1bGF0ZWQgb24KIFtTZWFyY2hTZXJ2aWNlLlNlYXJjaF1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuU2VhcmNoU2VydmljZS5TZWFyY2hdCiBBUEkuCgoOCgcE
AAMCAgAEEgNOBAwKDgoHBAADAgIABhIDTg0SCg4KBwQAAwICAAESA04TIgoOCgcEAAMCAgAD
EgNOJSYK6QIKBgQAAwICARIDVQQjGtkCIFRoZSBuZXh0IGNodW5rcyBvZiB0aGUgY3VycmVu
dCBjaHVuay4gVGhlIG51bWJlciBpcyBjb250cm9sbGVkIGJ5CiBbU2VhcmNoUmVxdWVzdC5D
b250ZW50U2VhcmNoU3BlYy5DaHVua1NwZWMubnVtX25leHRfY2h1bmtzXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hT
cGVjLkNodW5rU3BlYy5udW1fbmV4dF9jaHVua3NdLgogVGhpcyBmaWVsZCBpcyBvbmx5IHBv
cHVsYXRlZCBvbgogW1NlYXJjaFNlcnZpY2UuU2VhcmNoXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hTZXJ2aWNlLlNlYXJjaF0KIEFQSS4KCg4KBwQAAwIC
AQQSA1UEDAoOCgcEAAMCAgEGEgNVDRIKDgoHBAADAgIBARIDVRMeCg4KBwQAAwICAQMSA1Uh
IgozCgQEAAMDEgRZAmADGiUgVGhlIHN0cnVjdHVyZWQgY29udGVudCBpbmZvcm1hdGlvbi4K
CgwKBQQAAwMBEgNZChsKTAoGBAADAwIAEgRbBFw0GjwgT3V0cHV0IG9ubHkuIFRoZSBzdHJ1
Y3R1cmUgdHlwZSBvZiB0aGUgc3RydWN0dXJlZCBjb250ZW50LgoKDgoHBAADAwIABhIDWwQR
Cg4KBwQAAwMCAAESA1sSIAoOCgcEAAMDAgADEgNbIyQKDgoHBAADAwIACBIDXAgzChEKCgQA
AwMCAAicCAASA1wJMgpECgYEAAMDAgESA18EQxo1IE91dHB1dCBvbmx5LiBUaGUgY29udGVu
dCBvZiB0aGUgc3RydWN0dXJlZCBjb250ZW50LgoKDgoHBAADAwIBBRIDXwQKCg4KBwQAAwMC
AQESA18LEgoOCgcEAAMDAgEDEgNfFRYKDgoHBAADAwIBCBIDXxdCChEKCgQAAwMCAQicCAAS
A18YQQpZCgQEAAMEEgRjAmsDGksgVGhlIGFubm90YXRpb24gbWV0YWRhdGEgaW5jbHVkZXMg
c3RydWN0dXJlZCBjb250ZW50IGluIHRoZSBjdXJyZW50IGNodW5rLgoKDAoFBAADBAESA2MK
HApCCgYEAAMEAgASBGUEZjQaMiBPdXRwdXQgb25seS4gVGhlIHN0cnVjdHVyZWQgY29udGVu
dCBpbmZvcm1hdGlvbi4KCg4KBwQAAwQCAAYSA2UEFQoOCgcEAAMEAgABEgNlFigKDgoHBAAD
BAIAAxIDZSssCg4KBwQAAwQCAAgSA2YIMwoRCgoEAAMEAgAInAgAEgNmCTIKYwoGBAADBAIB
EgNqBEQaVCBPdXRwdXQgb25seS4gSW1hZ2UgaWQgaXMgcHJvdmlkZWQgaWYgdGhlIHN0cnVj
dHVyZWQgY29udGVudCBpcyBiYXNlZCBvbgogYW4gaW1hZ2UuCgoOCgcEAAMEAgEFEgNqBAoK
DgoHBAADBAIBARIDagsTCg4KBwQAAwQCAQMSA2oWFwoOCgcEAAMEAgEIEgNqGEMKEQoKBAAD
BAIBCJwIABIDahlCClIKBAQABAASBG4CegMaRCBEZWZpbmVzIHRoZSB0eXBlcyBvZiB0aGUg
c3RydWN0dXJlZCBjb250ZW50IHRoYXQgY2FuIGJlIGV4dHJhY3RlZC4KCgwKBQQABAABEgNu
BxQKHwoGBAAEAAIAEgNwBCMaECBEZWZhdWx0IHZhbHVlLgoKDgoHBAAEAAIAARIDcAQeCg4K
BwQABAACAAISA3AhIgonCgYEAAQAAgESA3MEHhoYIFNoYXJlaG9sZGVyIHN0cnVjdHVyZS4K
Cg4KBwQABAACAQESA3MEGQoOCgcEAAQAAgECEgNzHB0KJQoGBAAEAAICEgN2BBwaFiBTaWdu
YXR1cmUgc3RydWN0dXJlLgoKDgoHBAAEAAICARIDdgQXCg4KBwQABAACAgISA3YaGwokCgYE
AAQAAgMSA3kEGxoVIENoZWNrYm94IHN0cnVjdHVyZS4KCg4KBwQABAACAwESA3kEFgoOCgcE
AAQAAgMCEgN5GRoKrAIKBAQAAgASBIIBAhIanQIgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgY2h1bmsuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0
b3JlfS9icmFuY2hlcy97YnJhbmNofS9kb2N1bWVudHMve2RvY3VtZW50X2lkfS9jaHVua3Mv
e2NodW5rX2lkfWAuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJp
bmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDQoFBAACAAUS
BIIBAggKDQoFBAACAAESBIIBCQ0KDQoFBAACAAMSBIIBEBEKNQoEBAACARIEhQECEBonIFVu
aXF1ZSBjaHVuayBJRCBvZiB0aGUgY3VycmVudCBjaHVuay4KCg0KBQQAAgEFEgSFAQIICg0K
BQQAAgEBEgSFAQkLCg0KBQQAAgEDEgSFAQ4PCkUKBAQAAgISBIgBAhUaNyBDb250ZW50IGlz
IGEgc3RyaW5nIGZyb20gYSBkb2N1bWVudCAocGFyc2VkIGNvbnRlbnQpLgoKDQoFBAACAgUS
BIgBAggKDQoFBAACAgESBIgBCRAKDQoFBAACAgMSBIgBExQKgQIKBAQAAgMSBo8BApABMhrw
ASBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0aGUgcmVsZXZhbmNlIHNjb3JlIGJhc2VkIG9u
IHNpbWlsYXJpdHkuCiBIaWdoZXIgc2NvcmUgaW5kaWNhdGVzIGhpZ2hlciBjaHVuayByZWxl
dmFuY2UuCiBUaGUgc2NvcmUgaXMgaW4gcmFuZ2UgWy0xLjAsIDEuMF0uCiBPbmx5IHBvcHVs
YXRlZCBvbgogW1NlYXJjaFJlc3BvbnNlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5TZWFyY2hSZXNwb25zZV0uCgoNCgUEAAIDBBIEjwECCgoNCgUEAAIDBRIEjwEL
EQoNCgUEAAIDARIEjwESIQoNCgUEAAIDAxIEjwEkJQoNCgUEAAIDCBIEkAEGMQoQCggEAAID
CJwIABIEkAEHMApACgQEAAIEEgSTAQIpGjIgTWV0YWRhdGEgb2YgdGhlIGRvY3VtZW50IGZy
b20gdGhlIGN1cnJlbnQgY2h1bmsuCgoNCgUEAAIEBhIEkwECEgoNCgUEAAIEARIEkwETJAoN
CgUEAAIEAxIEkwEnKAqAAQoEBAACBRIGlwECmAEyGnAgT3V0cHV0IG9ubHkuIFRoaXMgZmll
bGQgaXMgT1VUUFVUX09OTFkuCiBJdCBjb250YWlucyBkZXJpdmVkIGRhdGEgdGhhdCBhcmUg
bm90IGluIHRoZSBvcmlnaW5hbCBpbnB1dCBkb2N1bWVudC4KCg0KBQQAAgUGEgSXAQIYCg0K
BQQAAgUBEgSXARksCg0KBQQAAgUDEgSXAS8wCg0KBQQAAgUIEgSYAQYxChAKCAQAAgUInAgA
EgSYAQcwCicKBAQAAgYSBJsBAhkaGSBQYWdlIHNwYW4gb2YgdGhlIGNodW5rLgoKDQoFBAAC
BgYSBJsBAgoKDQoFBAACBgESBJsBCxQKDQoFBAACBgMSBJsBFxgKOwoEBAACBxIEngECTxot
IE91dHB1dCBvbmx5LiBNZXRhZGF0YSBvZiB0aGUgY3VycmVudCBjaHVuay4KCg0KBQQAAgcG
EgSeAQIPCg0KBQQAAgcBEgSeARAeCg0KBQQAAgcDEgSeASEiCg0KBQQAAgcIEgSeASNOChAK
CAQAAgcInAgAEgSeASRNCpkCCgQEAAIIEgSlAQJMGooCIE91dHB1dCBvbmx5LiBJbWFnZSBE
YXRhIFVSTHMgaWYgdGhlIGN1cnJlbnQgY2h1bmsgY29udGFpbnMgaW1hZ2VzLgogRGF0YSBV
UkxzIGFyZSBjb21wb3NlZCBvZiBmb3VyIHBhcnRzOiBhIHByZWZpeCAoZGF0YTopLCBhIE1J
TUUgdHlwZQogaW5kaWNhdGluZyB0aGUgdHlwZSBvZiBkYXRhLCBhbiBvcHRpb25hbCBiYXNl
NjQgdG9rZW4gaWYgbm9uLXRleHR1YWwsCiBhbmQgdGhlIGRhdGEgaXRzZWxmOgogZGF0YTpb
PG1lZGlhdHlwZT5dWztiYXNlNjRdLDxkYXRhPgoKDQoFBAACCAQSBKUBAgoKDQoFBAACCAUS
BKUBCxEKDQoFBAACCAESBKUBEhsKDQoFBAACCAMSBKUBHh8KDQoFBAACCAgSBKUBIEsKEAoI
BAACCAicCAASBKUBIUoKXQoEBAACCRIGqAECqQEyGk0gT3V0cHV0IG9ubHkuIEFubm90YXRp
b24gY29udGVudHMgaWYgdGhlIGN1cnJlbnQgY2h1bmsgY29udGFpbnMgYW5ub3RhdGlvbnMu
CgoNCgUEAAIJBBIEqAECCgoNCgUEAAIJBRIEqAELEQoNCgUEAAIJARIEqAESJQoNCgUEAAIJ
AxIEqAEoKgoNCgUEAAIJCBIEqQEGMQoQCggEAAIJCJwIABIEqQEHMAppCgQEAAIKEgatAQKu
ATIaWSBPdXRwdXQgb25seS4gVGhlIGFubm90YXRpb24gbWV0YWRhdGEgaW5jbHVkZXMgc3Ry
dWN0dXJlZCBjb250ZW50IGluIHRoZQogY3VycmVudCBjaHVuay4KCg0KBQQAAgoEEgStAQIK
Cg0KBQQAAgoGEgStAQsdCg0KBQQAAgoBEgStAR4xCg0KBQQAAgoDEgStATQ2Cg0KBQQAAgoI
EgSuAQYxChAKCAQAAgoInAgAEgSuAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk ===
    # Fields for Chunk
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: content Type: 9 ()
    # Field: relevance_score Type: 1 ()
    # Field: document_metadata Type: 11 (.google.cloud.discoveryengine.v1beta.Chunk.DocumentMetadata)
    # Field: derived_struct_data Type: 11 (.google.protobuf.Struct)
    # Field: page_span Type: 11 (.google.cloud.discoveryengine.v1beta.Chunk.PageSpan)
    # Field: chunk_metadata Type: 11 (.google.cloud.discoveryengine.v1beta.Chunk.ChunkMetadata)
    # Field: data_urls Type: 9 ()
    # Field: annotation_contents Type: 9 ()
    # Field: annotation_metadata Type: 11 (.google.cloud.discoveryengine.v1beta.Chunk.AnnotationMetadata)

# Enum: Chunk::StructureType
our $Chunk_STRUCTURE_TYPE_UNSPECIFIED = 0;
our $Chunk_SHAREHOLDER_STRUCTURE = 1;
our $Chunk_SIGNATURE_STRUCTURE = 2;
our $Chunk_CHECKBOX_STRUCTURE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Chunk - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/chunk.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Chunk;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk->new({
        name => $name,
        id => $id,
        content => $content,
        relevance_score => $relevance_score,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/chunk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk

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
[SearchResponse][google.cloud.discoveryengine.v1beta.SearchResponse].

=item * C<< $msg->document_metadata() >> / C<< $msg->document_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk::DocumentMetadata>)

Metadata of the document from the current chunk.

=item * C<< $msg->derived_struct_data() >> / C<< $msg->derived_struct_data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. This field is OUTPUT_ONLY.
It contains derived data that are not in the original input document.

=item * C<< $msg->page_span() >> / C<< $msg->page_span($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk::PageSpan>)

Page span of the chunk.

=item * C<< $msg->chunk_metadata() >> / C<< $msg->chunk_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk::ChunkMetadata>)

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Chunk::Chunk::AnnotationMetadata>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Chunk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
