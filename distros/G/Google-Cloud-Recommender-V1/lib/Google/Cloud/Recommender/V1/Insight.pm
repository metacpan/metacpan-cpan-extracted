package Google::Cloud::Recommender::V1::Insight;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjEvaW5zaWdodC5wcm90bxIbZ29vZ2xlLmNs
b3VkLnJlY29tbWVuZGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJv
dG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8ikgsKB0luc2lnaHQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiAKC2Rl
c2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhIpChB0YXJnZXRfcmVzb3VyY2VzGAkgAygJ
Ug90YXJnZXRSZXNvdXJjZXMSJwoPaW5zaWdodF9zdWJ0eXBlGAogASgJUg5pbnNpZ2h0U3Vi
dHlwZRIxCgdjb250ZW50GAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIHY29udGVu
dBJGChFsYXN0X3JlZnJlc2hfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSD2xhc3RSZWZyZXNoVGltZRJIChJvYnNlcnZhdGlvbl9wZXJpb2QYBSABKAsyGS5nb29n
bGUucHJvdG9idWYuRHVyYXRpb25SEW9ic2VydmF0aW9uUGVyaW9kEkwKCnN0YXRlX2luZm8Y
BiABKAsyLS5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjEuSW5zaWdodFN0YXRlSW5mb1IJ
c3RhdGVJbmZvEkkKCGNhdGVnb3J5GAcgASgOMi0uZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVy
LnYxLkluc2lnaHQuQ2F0ZWdvcnlSCGNhdGVnb3J5EkkKCHNldmVyaXR5GA8gASgOMi0uZ29v
Z2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLkluc2lnaHQuU2V2ZXJpdHlSCHNldmVyaXR5EhIK
BGV0YWcYCyABKAlSBGV0YWcSewoaYXNzb2NpYXRlZF9yZWNvbW1lbmRhdGlvbnMYCCADKAsy
PC5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjEuSW5zaWdodC5SZWNvbW1lbmRhdGlvblJl
ZmVyZW5jZVIZYXNzb2NpYXRlZFJlY29tbWVuZGF0aW9ucxpBChdSZWNvbW1lbmRhdGlvblJl
ZmVyZW5jZRImCg5yZWNvbW1lbmRhdGlvbhgBIAEoCVIOcmVjb21tZW5kYXRpb24ihQEKCENh
dGVnb3J5EhgKFENBVEVHT1JZX1VOU1BFQ0lGSUVEEAASCAoEQ09TVBABEgwKCFNFQ1VSSVRZ
EAISDwoLUEVSRk9STUFOQ0UQAxIRCg1NQU5BR0VBQklMSVRZEAQSEgoOU1VTVEFJTkFCSUxJ
VFkQBRIPCgtSRUxJQUJJTElUWRAGIlEKCFNldmVyaXR5EhgKFFNFVkVSSVRZX1VOU1BFQ0lG
SUVEEAASBwoDTE9XEAESCgoGTUVESVVNEAISCAoESElHSBADEgwKCENSSVRJQ0FMEAQ6nwPq
QZsDCiJyZWNvbW1lbmRlci5nb29nbGVhcGlzLmNvbS9JbnNpZ2h0ElZwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zaWdodFR5cGVzL3tpbnNpZ2h0X3R5cGV9
L2luc2lnaHRzL3tpbnNpZ2h0fRJlYmlsbGluZ0FjY291bnRzL3tiaWxsaW5nX2FjY291bnR9
L2xvY2F0aW9ucy97bG9jYXRpb259L2luc2lnaHRUeXBlcy97aW5zaWdodF90eXBlfS9pbnNp
Z2h0cy97aW5zaWdodH0SVGZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aW5zaWdodFR5cGVzL3tpbnNpZ2h0X3R5cGV9L2luc2lnaHRzL3tpbnNpZ2h0fRJgb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnNpZ2h0VHlw
ZXMve2luc2lnaHRfdHlwZX0vaW5zaWdodHMve2luc2lnaHR9ItECChBJbnNpZ2h0U3RhdGVJ
bmZvEkkKBXN0YXRlGAEgASgOMjMuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLkluc2ln
aHRTdGF0ZUluZm8uU3RhdGVSBXN0YXRlEmcKDnN0YXRlX21ldGFkYXRhGAIgAygLMkAuZ29v
Z2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxLkluc2lnaHRTdGF0ZUluZm8uU3RhdGVNZXRhZGF0
YUVudHJ5Ug1zdGF0ZU1ldGFkYXRhGkAKElN0YXRlTWV0YWRhdGFFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIkcKBVN0YXRlEhUKEVNUQVRFX1VO
U1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESDAoIQUNDRVBURUQQAhINCglESVNNSVNTRUQQA0Lw
AwofY29tLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MUIMSW5zaWdodFByb3RvUAFaQWNs
b3VkLmdvb2dsZS5jb20vZ28vcmVjb21tZW5kZXIvYXBpdjEvcmVjb21tZW5kZXJwYjtyZWNv
bW1lbmRlcnBiogIEQ1JFQ6oCG0dvb2dsZS5DbG91ZC5SZWNvbW1lbmRlci5WMepB0wIKJnJl
Y29tbWVuZGVyLmdvb2dsZWFwaXMuY29tL0luc2lnaHRUeXBlEkNwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zaWdodFR5cGVzL3tpbnNpZ2h0X3R5cGV9ElJi
aWxsaW5nQWNjb3VudHMve2JpbGxpbmdfYWNjb3VudH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aW5zaWdodFR5cGVzL3tpbnNpZ2h0X3R5cGV9EkFmb2xkZXJzL3tmb2xkZXJ9L2xvY2F0aW9u
cy97bG9jYXRpb259L2luc2lnaHRUeXBlcy97aW5zaWdodF90eXBlfRJNb3JnYW5pemF0aW9u
cy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnNpZ2h0VHlwZXMve2lu
c2lnaHRfdHlwZX1KhSgKBxIFDgCoAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACgKCQoCAwMS
AxUAJgoJCgIDBBIDFgApCggKAQgSAxgAOAoJCgIIJRIDGAA4CggKAQgSAxkAWAoJCgIICxID
GQBYCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwA
OAoJCgIIARIDHAA4CggKAQgSAx0AIgoJCgIIJBIDHQAiCgkKAQgSBB4AJAIKDAoECJ0IABIE
HgAkAgqKAQoCBAASBSgAigEBGn0gQW4gaW5zaWdodCBhbG9uZyB3aXRoIHRoZSBpbmZvcm1h
dGlvbiB1c2VkIHRvIGRlcml2ZSB0aGUgaW5zaWdodC4gVGhlIGluc2lnaHQKIG1heSBoYXZl
IGFzc29jaWF0ZWQgcmVjb21tZW5kYXRpb25zIGFzIHdlbGwuCgoKCgMEAAESAygIDwoLCgME
AAcSBCkCLwQKDQoFBAAHnQgSBCkCLwQKIQoEBAAEABIEMgJHAxoTIEluc2lnaHQgY2F0ZWdv
cnkuCgoMCgUEAAQAARIDMgcPCiYKBgQABAACABIDNAQdGhcgVW5zcGVjaWZpZWQgY2F0ZWdv
cnkuCgoOCgcEAAQAAgABEgM0BBgKDgoHBAAEAAIAAhIDNBscCjAKBgQABAACARIDNwQNGiEg
VGhlIGluc2lnaHQgaXMgcmVsYXRlZCB0byBjb3N0LgoKDgoHBAAEAAIBARIDNwQICg4KBwQA
BAACAQISAzcLDAo0CgYEAAQAAgISAzoEERolIFRoZSBpbnNpZ2h0IGlzIHJlbGF0ZWQgdG8g
c2VjdXJpdHkuCgoOCgcEAAQAAgIBEgM6BAwKDgoHBAAEAAICAhIDOg8QCjcKBgQABAACAxID
PQQUGiggVGhlIGluc2lnaHQgaXMgcmVsYXRlZCB0byBwZXJmb3JtYW5jZS4KCg4KBwQABAAC
AwESAz0EDwoOCgcEAAQAAgMCEgM9EhMKOgoGBAAEAAIEEgNABBYaKyBUaGlzIGluc2lnaHQg
aXMgcmVsYXRlZCB0byBtYW5hZ2VhYmlsaXR5LgoKDgoHBAAEAAIEARIDQAQRCg4KBwQABAAC
BAISA0AUFQo6CgYEAAQAAgUSA0MEFxorIFRoZSBpbnNpZ2h0IGlzIHJlbGF0ZWQgdG8gc3Vz
dGFpbmFiaWxpdHkuCgoOCgcEAAQAAgUBEgNDBBIKDgoHBAAEAAIFAhIDQxUWCjgKBgQABAAC
BhIDRgQUGikgVGhpcyBpbnNpZ2h0IGlzIHJlbGF0ZWQgdG8gcmVsaWFiaWxpdHkuCgoOCgcE
AAQAAgYBEgNGBA8KDgoHBAAEAAIGAhIDRhITCigKBAQABAESBEoCWQMaGiBJbnNpZ2h0IHNl
dmVyaXR5IGxldmVscy4KCgwKBQQABAEBEgNKBw8KMgoGBAAEAQIAEgNMBB0aIyBJbnNpZ2h0
IGhhcyB1bnNwZWNpZmllZCBzZXZlcml0eS4KCg4KBwQABAECAAESA0wEGAoOCgcEAAQBAgAC
EgNMGxwKKgoGBAAEAQIBEgNPBAwaGyBJbnNpZ2h0IGhhcyBsb3cgc2V2ZXJpdHkuCgoOCgcE
AAQBAgEBEgNPBAcKDgoHBAAEAQIBAhIDTwoLCi0KBgQABAECAhIDUgQPGh4gSW5zaWdodCBo
YXMgbWVkaXVtIHNldmVyaXR5LgoKDgoHBAAEAQICARIDUgQKCg4KBwQABAECAgISA1INDgor
CgYEAAQBAgMSA1UEDRocIEluc2lnaHQgaGFzIGhpZ2ggc2V2ZXJpdHkuCgoOCgcEAAQBAgMB
EgNVBAgKDgoHBAAEAQIDAhIDVQsMCi8KBgQABAECBBIDWAQRGiAgSW5zaWdodCBoYXMgY3Jp
dGljYWwgc2V2ZXJpdHkuCgoOCgcEAAQBAgQBEgNYBAwKDgoHBAAEAQIEAhIDWA8QCjoKBAQA
AwASBFwCYAMaLCBSZWZlcmVuY2UgdG8gYW4gYXNzb2NpYXRlZCByZWNvbW1lbmRhdGlvbi4K
CgwKBQQAAwABEgNcCiEKpgEKBgQAAwACABIDXwQeGpYBIFJlY29tbWVuZGF0aW9uIHJlc291
cmNlIG5hbWUsIGUuZy4KIHByb2plY3RzL1tQUk9KRUNUX05VTUJFUl0vbG9jYXRpb25zL1tM
T0NBVElPTl0vcmVjb21tZW5kZXJzL1tSRUNPTU1FTkRFUl9JRF0vcmVjb21tZW5kYXRpb25z
L1tSRUNPTU1FTkRBVElPTl9JRF0KCg4KBwQAAwACAAUSA18ECgoOCgcEAAMAAgABEgNfCxkK
DgoHBAADAAIAAxIDXxwdCi8KBAQAAgASA2MCPRoiIElkZW50aWZpZXIuIE5hbWUgb2YgdGhl
IGluc2lnaHQuCgoMCgUEAAIABRIDYwIICgwKBQQAAgABEgNjCQ0KDAoFBAACAAMSA2MQEQoM
CgUEAAIACBIDYxI8Cg8KCAQAAgAInAgAEgNjEzsKYgoEBAACARIDZwIZGlUgRnJlZS1mb3Jt
IGh1bWFuIHJlYWRhYmxlIHN1bW1hcnkgaW4gRW5nbGlzaC4gVGhlIG1heGltdW0gbGVuZ3Ro
IGlzIDUwMAogY2hhcmFjdGVycy4KCgwKBQQAAgEFEgNnAggKDAoFBAACAQESA2cJFAoMCgUE
AAIBAxIDZxcYCk0KBAQAAgISA2oCJxpAIEZ1bGx5IHF1YWxpZmllZCByZXNvdXJjZSBuYW1l
cyB0aGF0IHRoaXMgaW5zaWdodCBpcyB0YXJnZXRpbmcuCgoMCgUEAAICBBIDagIKCgwKBQQA
AgIFEgNqCxEKDAoFBAACAgESA2oSIgoMCgUEAAICAxIDaiUmCloKBAQAAgMSA20CHhpNIElu
c2lnaHQgc3VidHlwZS4gSW5zaWdodCBjb250ZW50IHNjaGVtYSB3aWxsIGJlIHN0YWJsZSBm
b3IgYSBnaXZlbiBzdWJ0eXBlLgoKDAoFBAACAwUSA20CCAoMCgUEAAIDARIDbQkYCgwKBQQA
AgMDEgNtGx0KbAoEBAACBBIDcQIlGl8gQSBzdHJ1Y3Qgb2YgY3VzdG9tIGZpZWxkcyB0byBl
eHBsYWluIHRoZSBpbnNpZ2h0LgogRXhhbXBsZTogImdyYW50ZWRQZXJtaXNzaW9uc0NvdW50
IjogIjEwMDAiCgoMCgUEAAIEBhIDcQIYCgwKBQQAAgQBEgNxGSAKDAoFBAACBAMSA3EjJApJ
CgQEAAIFEgN0AjIaPCBUaW1lc3RhbXAgb2YgdGhlIGxhdGVzdCBkYXRhIHVzZWQgdG8gZ2Vu
ZXJhdGUgdGhlIGluc2lnaHQuCgoMCgUEAAIFBhIDdAIbCgwKBQQAAgUBEgN0HC0KDAoFBAAC
BQMSA3QwMQq8AQoEBAACBhIDeQIyGq4BIE9ic2VydmF0aW9uIHBlcmlvZCB0aGF0IGxlZCB0
byB0aGUgaW5zaWdodC4gVGhlIHNvdXJjZSBkYXRhIHVzZWQgdG8KIGdlbmVyYXRlIHRoZSBp
bnNpZ2h0IGVuZHMgYXQgbGFzdF9yZWZyZXNoX3RpbWUgYW5kIGJlZ2lucyBhdAogKGxhc3Rf
cmVmcmVzaF90aW1lIC0gb2JzZXJ2YXRpb25fcGVyaW9kKS4KCgwKBQQAAgYGEgN5AhoKDAoF
BAACBgESA3kbLQoMCgUEAAIGAxIDeTAxCi4KBAQAAgcSA3wCIhohIEluZm9ybWF0aW9uIHN0
YXRlIGFuZCBtZXRhZGF0YS4KCgwKBQQAAgcGEgN8AhIKDAoFBAACBwESA3wTHQoMCgUEAAIH
AxIDfCAhCjYKBAQAAggSA38CGBopIENhdGVnb3J5IGJlaW5nIHRhcmdldGVkIGJ5IHRoZSBp
bnNpZ2h0LgoKDAoFBAACCAYSA38CCgoMCgUEAAIIARIDfwsTCgwKBQQAAggDEgN/FhcKIwoE
BAACCRIEggECGRoVIEluc2lnaHQncyBzZXZlcml0eS4KCg0KBQQAAgkGEgSCAQIKCg0KBQQA
AgkBEgSCAQsTCg0KBQQAAgkDEgSCARYYCl4KBAQAAgoSBIYBAhMaUCBGaW5nZXJwcmludCBv
ZiB0aGUgSW5zaWdodC4gUHJvdmlkZXMgb3B0aW1pc3RpYyBsb2NraW5nIHdoZW4gdXBkYXRp
bmcKIHN0YXRlcy4KCg0KBQQAAgoFEgSGAQIICg0KBQQAAgoBEgSGAQkNCg0KBQQAAgoDEgSG
ARASCjoKBAQAAgsSBIkBAkIaLCBSZWNvbW1lbmRhdGlvbnMgZGVyaXZlZCBmcm9tIHRoaXMg
aW5zaWdodC4KCg0KBQQAAgsEEgSJAQIKCg0KBQQAAgsGEgSJAQsiCg0KBQQAAgsBEgSJASM9
Cg0KBQQAAgsDEgSJAUBBCjUKAgQBEgaNAQCoAQEaJyBJbmZvcm1hdGlvbiByZWxhdGVkIHRv
IGluc2lnaHQgc3RhdGUuCgoLCgMEAQESBI0BCBgKKwoEBAEEABIGjwECoQEDGhsgUmVwcmVz
ZW50cyBpbnNpZ2h0IHN0YXRlLgoKDQoFBAEEAAESBI8BBwwKJAoGBAEEAAIAEgSRAQQaGhQg
VW5zcGVjaWZpZWQgc3RhdGUuCgoPCgcEAQQAAgABEgSRAQQVCg8KBwQBBAACAAISBJEBGBkK
kQEKBgQBBAACARIElQEEDxqAASBJbnNpZ2h0IGlzIGFjdGl2ZS4gQ29udGVudCBmb3IgQUNU
SVZFIGluc2lnaHRzIGNhbiBiZSB1cGRhdGVkIGJ5IEdvb2dsZS4KIEFDVElWRSBpbnNpZ2h0
cyBjYW4gYmUgbWFya2VkIERJU01JU1NFRCBPUiBBQ0NFUFRFRC4KCg8KBwQBBAACAQESBJUB
BAoKDwoHBAEEAAIBAhIElQENDgr0AgoGBAEEAAICEgScAQQRGuMCIFNvbWUgYWN0aW9uIGhh
cyBiZWVuIHRha2VuIGJhc2VkIG9uIHRoaXMgaW5zaWdodC4gSW5zaWdodHMgYmVjb21lCiBh
Y2NlcHRlZCB3aGVuIGEgcmVjb21tZW5kYXRpb24gZGVyaXZlZCBmcm9tIHRoZSBpbnNpZ2h0
IGhhcyBiZWVuIG1hcmtlZAogQ0xBSU1FRCwgU1VDQ0VFREVELCBvciBGQUlMRUQuIEFDVElW
RSBpbnNpZ2h0cyBjYW4gYWxzbyBiZSBtYXJrZWQKIEFDQ0VQVEVEIGV4cGxpY2l0bHkuIENv
bnRlbnQgZm9yIEFDQ0VQVEVEIGluc2lnaHRzIGlzIGltbXV0YWJsZS4gQUNDRVBURUQKIGlu
c2lnaHRzIGNhbiBvbmx5IGJlIG1hcmtlZCBBQ0NFUFRFRCAod2hpY2ggbWF5IHVwZGF0ZSBz
dGF0ZSBtZXRhZGF0YSkuCgoPCgcEAQQAAgIBEgScAQQMCg8KBwQBBAACAgISBJwBDxAKjQEK
BgQBBAACAxIEoAEEEhp9IEluc2lnaHQgaXMgZGlzbWlzc2VkLiBDb250ZW50IGZvciBESVNN
SVNTRUQgaW5zaWdodHMgY2FuIGJlIHVwZGF0ZWQgYnkKIEdvb2dsZS4gRElTTUlTU0VEIGlu
c2lnaHRzIGNhbiBiZSBtYXJrZWQgYXMgQUNUSVZFLgoKDwoHBAEEAAIDARIEoAEEDQoPCgcE
AQQAAgMCEgSgARARCh4KBAQBAgASBKQBAhIaECBJbnNpZ2h0IHN0YXRlLgoKDQoFBAECAAYS
BKQBAgcKDQoFBAECAAESBKQBCA0KDQoFBAECAAMSBKQBEBEKWQoEBAECARIEpwECKRpLIEEg
bWFwIG9mIG1ldGFkYXRhIGZvciB0aGUgc3RhdGUsIHByb3ZpZGVkIGJ5IHVzZXIgb3IgYXV0
b21hdGlvbnMgc3lzdGVtcy4KCg0KBQQBAgEGEgSnAQIVCg0KBQQBAgEBEgSnARYkCg0KBQQB
AgEDEgSnAScoYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1::Insight::Insight ===
    # Fields for Insight
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: target_resources Type: 9 ()
    # Field: insight_subtype Type: 9 ()
    # Field: content Type: 11 (.google.protobuf.Struct)
    # Field: last_refresh_time Type: 11 (.google.protobuf.Timestamp)
    # Field: observation_period Type: 11 (.google.protobuf.Duration)
    # Field: state_info Type: 11 (.google.cloud.recommender.v1.InsightStateInfo)
    # Field: category Type: 14 (.google.cloud.recommender.v1.Insight.Category)
    # Field: severity Type: 14 (.google.cloud.recommender.v1.Insight.Severity)
    # Field: etag Type: 9 ()
    # Field: associated_recommendations Type: 11 (.google.cloud.recommender.v1.Insight.RecommendationReference)

# Enum: Insight::Category
our $Insight_CATEGORY_UNSPECIFIED = 0;
our $Insight_COST = 1;
our $Insight_SECURITY = 2;
our $Insight_PERFORMANCE = 3;
our $Insight_MANAGEABILITY = 4;
our $Insight_SUSTAINABILITY = 5;
our $Insight_RELIABILITY = 6;

# Enum: Insight::Severity
our $Insight_SEVERITY_UNSPECIFIED = 0;
our $Insight_LOW = 1;
our $Insight_MEDIUM = 2;
our $Insight_HIGH = 3;
our $Insight_CRITICAL = 4;

# === Message: Google::Cloud::Recommender::V1::Insight::InsightStateInfo ===
    # Fields for InsightStateInfo
    # Field: state Type: 14 (.google.cloud.recommender.v1.InsightStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.v1.InsightStateInfo.StateMetadataEntry)

# Enum: InsightStateInfo::State
our $InsightStateInfo_STATE_UNSPECIFIED = 0;
our $InsightStateInfo_ACTIVE = 1;
our $InsightStateInfo_ACCEPTED = 2;
our $InsightStateInfo_DISMISSED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1::Insight - Compiled Protocol Buffers messages for google/cloud/recommender/v1/insight.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1::Insight;

    my $msg = Google::Cloud::Recommender::V1::Insight::Insight->new({
        name => $name,
        description => $description,
        target_resources => $target_resources,
        insight_subtype => $insight_subtype,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1::Insight::Insight->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1/insight.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1::Insight::Insight

An insight along with the information used to derive the insight. The insight
may have associated recommendations as well.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the insight.

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

Type: C<Message> (L<Google::Cloud::Recommender::V1::Insight::InsightStateInfo>)

Information state and metadata.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::Insight::Category>)

Category being targeted by the insight.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::Insight::Severity>)

Insight's severity.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Fingerprint of the Insight. Provides optimistic locking when updating
states.

=item * C<< $msg->associated_recommendations() >> / C<< $msg->associated_recommendations($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Insight::Insight::RecommendationReference>)

Recommendations derived from this insight.

=back

=head3 Enum: Insight::Category

=over 4

=item * C<CATEGORY_UNSPECIFIED> => C<0>

=item * C<COST> => C<1>

=item * C<SECURITY> => C<2>

=item * C<PERFORMANCE> => C<3>

=item * C<MANAGEABILITY> => C<4>

=item * C<SUSTAINABILITY> => C<5>

=item * C<RELIABILITY> => C<6>

=back

=head3 Enum: Insight::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<LOW> => C<1>

=item * C<MEDIUM> => C<2>

=item * C<HIGH> => C<3>

=item * C<CRITICAL> => C<4>

=back

=head2 Google::Cloud::Recommender::V1::Insight::InsightStateInfo

Information related to insight state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::InsightStateInfo::State>)

Insight state.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::Insight::InsightStateInfo::StateMetadataEntry>)

A map of metadata for the state, provided by user or automations systems.

=back

=head3 Enum: InsightStateInfo::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<ACCEPTED> => C<2>

=item * C<DISMISSED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1::Insight::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
