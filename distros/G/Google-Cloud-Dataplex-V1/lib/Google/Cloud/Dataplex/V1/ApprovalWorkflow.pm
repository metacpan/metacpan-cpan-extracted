package Google::Cloud::Dataplex::V1::ApprovalWorkflow;

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
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dataplex::V1::BusinessGlossary };
    eval { require Google::Cloud::Dataplex::V1::Catalog };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGF0YXBsZXgvdjEvYXBwcm92YWxfd29ya2Zsb3cucHJvdG8SGGdv
b2dsZS5jbG91ZC5kYXRhcGxleC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxowZ29vZ2xlL2Nsb3VkL2RhdGFwbGV4L3YxL2J1c2luZXNzX2dsb3NzYXJ5LnByb3Rv
GiZnb29nbGUvY2xvdWQvZGF0YXBsZXgvdjEvY2F0YWxvZy5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byLSFgoNQ2hhbmdlUmVxdWVzdBIXCgRuYW1lGAEgASgJQgPg
QQhSBG5hbWUSHQoDdWlkGAIgASgJQgvijM/XCAIIAeBBA1IDdWlkEkAKC2NyZWF0ZV90aW1l
GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAK
C3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1
cGRhdGVUaW1lEikKDWp1c3RpZmljYXRpb24YBSABKAlCA+BBAVINanVzdGlmaWNhdGlvbhJQ
CgZsYWJlbHMYBiADKAsyMy5nb29nbGUuY2xvdWQuZGF0YXBsZXgudjEuQ2hhbmdlUmVxdWVz
dC5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSGwoGYXV0aG9yGAcgASgJQgPgQQNSBmF1dGhv
chJICgVzdGF0ZRgIIAEoDjItLmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5DaGFuZ2VSZXF1
ZXN0LlN0YXRlQgPgQQNSBXN0YXRlEiUKCHJlc291cmNlGAkgASgJQgngQQP6QQMKASpSCHJl
c291cmNlElEKDGNyZWF0ZV9lbnRyeRgKIAEoCzIsLmdvb2dsZS5jbG91ZC5kYXRhcGxleC52
MS5DcmVhdGVFbnRyeVJlcXVlc3RIAFILY3JlYXRlRW50cnkSUQoMdXBkYXRlX2VudHJ5GAsg
ASgLMiwuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLlVwZGF0ZUVudHJ5UmVxdWVzdEgAUgt1
cGRhdGVFbnRyeRJRCgxkZWxldGVfZW50cnkYDCABKAsyLC5nb29nbGUuY2xvdWQuZGF0YXBs
ZXgudjEuRGVsZXRlRW50cnlSZXF1ZXN0SABSC2RlbGV0ZUVudHJ5El4KEWNyZWF0ZV9lbnRy
eV9saW5rGA0gASgLMjAuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkNyZWF0ZUVudHJ5TGlu
a1JlcXVlc3RIAFIPY3JlYXRlRW50cnlMaW5rEl4KEWRlbGV0ZV9lbnRyeV9saW5rGA4gASgL
MjAuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkRlbGV0ZUVudHJ5TGlua1JlcXVlc3RIAFIP
ZGVsZXRlRW50cnlMaW5rEloKD2NyZWF0ZV9nbG9zc2FyeRgUIAEoCzIvLmdvb2dsZS5jbG91
ZC5kYXRhcGxleC52MS5DcmVhdGVHbG9zc2FyeVJlcXVlc3RIAFIOY3JlYXRlR2xvc3NhcnkS
WgoPdXBkYXRlX2dsb3NzYXJ5GBUgASgLMi8uZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLlVw
ZGF0ZUdsb3NzYXJ5UmVxdWVzdEgAUg51cGRhdGVHbG9zc2FyeRJaCg9kZWxldGVfZ2xvc3Nh
cnkYFiABKAsyLy5nb29nbGUuY2xvdWQuZGF0YXBsZXgudjEuRGVsZXRlR2xvc3NhcnlSZXF1
ZXN0SABSDmRlbGV0ZUdsb3NzYXJ5EnMKGGNyZWF0ZV9nbG9zc2FyeV9jYXRlZ29yeRgXIAEo
CzI3Lmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5DcmVhdGVHbG9zc2FyeUNhdGVnb3J5UmVx
dWVzdEgAUhZjcmVhdGVHbG9zc2FyeUNhdGVnb3J5EnMKGHVwZGF0ZV9nbG9zc2FyeV9jYXRl
Z29yeRgYIAEoCzI3Lmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5VcGRhdGVHbG9zc2FyeUNh
dGVnb3J5UmVxdWVzdEgAUhZ1cGRhdGVHbG9zc2FyeUNhdGVnb3J5EnMKGGRlbGV0ZV9nbG9z
c2FyeV9jYXRlZ29yeRgaIAEoCzI3Lmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5EZWxldGVH
bG9zc2FyeUNhdGVnb3J5UmVxdWVzdEgAUhZkZWxldGVHbG9zc2FyeUNhdGVnb3J5EmcKFGNy
ZWF0ZV9nbG9zc2FyeV90ZXJtGBsgASgLMjMuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkNy
ZWF0ZUdsb3NzYXJ5VGVybVJlcXVlc3RIAFISY3JlYXRlR2xvc3NhcnlUZXJtEmcKFHVwZGF0
ZV9nbG9zc2FyeV90ZXJtGBwgASgLMjMuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLlVwZGF0
ZUdsb3NzYXJ5VGVybVJlcXVlc3RIAFISdXBkYXRlR2xvc3NhcnlUZXJtEmcKFGRlbGV0ZV9n
bG9zc2FyeV90ZXJtGB4gASgLMjMuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkRlbGV0ZUds
b3NzYXJ5VGVybVJlcXVlc3RIAFISZGVsZXRlR2xvc3NhcnlUZXJtEnMKG2RhdGFfcHJvZHVj
dF9hY2Nlc3NfcmVxdWVzdBggIAEoCzIyLmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5EYXRh
UHJvZHVjdEFjY2Vzc1JlcXVlc3RIAFIYZGF0YVByb2R1Y3RBY2Nlc3NSZXF1ZXN0ElgKC2No
YW5nZV90eXBlGBMgASgOMjIuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkNoYW5nZVJlcXVl
c3QuQ2hhbmdlVHlwZUID4EEDUgpjaGFuZ2VUeXBlEjAKEXJlamVjdGlvbl9jb21tZW50GBAg
ASgJQgPgQQNSEHJlamVjdGlvbkNvbW1lbnQSHwoIYXBwcm92ZXIYESABKAlCA+BBA1IIYXBw
cm92ZXISFwoEZXRhZxgSIAEoCUID4EEBUgRldGFnGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiXQoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIHCgNORVcQARIMCghBUFBST1ZFRBACEgwKCFJFSkVDVEVEEAMSCwoH
RVhQSVJFRBAEEgsKB1JFVk9LRUQQBSKVAwoKQ2hhbmdlVHlwZRIbChdDSEFOR0VfVFlQRV9V
TlNQRUNJRklFRBAAEhAKDENSRUFURV9FTlRSWRABEhAKDFVQREFURV9FTlRSWRACEhAKDERF
TEVURV9FTlRSWRADEhUKEUNSRUFURV9FTlRSWV9MSU5LEAQSFQoRREVMRVRFX0VOVFJZX0xJ
TksQBRITCg9DUkVBVEVfR0xPU1NBUlkQBxITCg9VUERBVEVfR0xPU1NBUlkQCBITCg9ERUxF
VEVfR0xPU1NBUlkQCRIcChhDUkVBVEVfR0xPU1NBUllfQ0FURUdPUlkQChIcChhVUERBVEVf
R0xPU1NBUllfQ0FURUdPUlkQCxIcChhERUxFVEVfR0xPU1NBUllfQ0FURUdPUlkQDRIYChRD
UkVBVEVfR0xPU1NBUllfVEVSTRAOEhgKFFVQREFURV9HTE9TU0FSWV9URVJNEA8SGAoUREVM
RVRFX0dMT1NTQVJZX1RFUk0QERIfChtSRVFVRVNUX0RBVEFfUFJPRFVDVF9BQ0NFU1MQITqT
AepBjwEKJWRhdGFwbGV4Lmdvb2dsZWFwaXMuY29tL0NoYW5nZVJlcXVlc3QSR3Byb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jaGFuZ2VSZXF1ZXN0cy97Y2hhbmdl
X3JlcXVlc3R9Kg5jaGFuZ2VSZXF1ZXN0czINY2hhbmdlUmVxdWVzdEIQCg5jaGFuZ2VfcGF5
bG9hZCKfAgoYRGF0YVByb2R1Y3RBY2Nlc3NSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC
+kElCiNkYXRhcGxleC5nb29nbGVhcGlzLmNvbS9EYXRhUHJvZHVjdFIGcGFyZW50EisKD2Fj
Y2Vzc19ncm91cF9pZBgCIAEoCUID4EECUg1hY2Nlc3NHcm91cElkEj4KGWFjY2Vzc19ncm91
cF9kaXNwbGF5X25hbWUYBCABKAlCA+BBA1IWYWNjZXNzR3JvdXBEaXNwbGF5TmFtZRI5ChNy
ZXF1ZXN0ZWRfcHJpbmNpcGFsGAMgASgJQgPgQQFIAFIScmVxdWVzdGVkUHJpbmNpcGFsiAEB
QhYKFF9yZXF1ZXN0ZWRfcHJpbmNpcGFsQsUBChxjb20uZ29vZ2xlLmNsb3VkLmRhdGFwbGV4
LnYxQhVBcHByb3ZhbFdvcmtmbG93UHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRh
cGxleC9hcGl2MS9kYXRhcGxleHBiO2RhdGFwbGV4cGKqAhhHb29nbGUuQ2xvdWQuRGF0YXBs
ZXguVjHKAhhHb29nbGVcQ2xvdWRcRGF0YXBsZXhcVjHqAhtHb29nbGU6OkNsb3VkOjpEYXRh
cGxleDo6VjFKsEEKBxIFDgD6AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
JQoJCgIDBBIDFgAjCgkKAgMFEgMXADoKCQoCAwYSAxgAMAoJCgIDBxIDGQApCggKAQgSAxsA
NQoJCgIIJRIDGwA1CggKAQgSAxwATwoJCgIICxIDHABPCggKAQgSAx0AIgoJCgIIChIDHQAi
CggKAQgSAx4ANgoJCgIICBIDHgA2CggKAQgSAx8ANQoJCgIIARIDHwA1CggKAQgSAyAANQoJ
CgIIKRIDIAA1CggKAQgSAyEANAoJCgIILRIDIQA0CkMKAgQAEgUkANoBARo2IFJlcHJlc2Vu
dHMgYSBwcm9wb3NlZCBjaGFuZ2UgdG8gYSBtZXRhZGF0YSByZXNvdXJjZS4KCgoKAwQAARID
JAgVCgsKAwQABxIEJQIqBAoNCgUEAAedCBIEJQIqBAozCgQEAAQAEgQtAj8DGiUgUG9zc2li
bGUgc3RhdGVzIG9mIGEgQ2hhbmdlUmVxdWVzdC4KCgwKBQQABAABEgMtBwwKIwoGBAAEAAIA
EgMvBBoaFCBTdGF0ZSB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAy8EFQoOCgcEAAQAAgAC
EgMvGBkKMAoGBAAEAAIBEgMyBAwaISBUaGUgY2hhbmdlIGlzIHByb3Bvc2VkIGFuZCBuZXcu
CgoOCgcEAAQAAgEBEgMyBAcKDgoHBAAEAAIBAhIDMgoLCi4KBgQABAACAhIDNQQRGh8gVGhl
IGNoYW5nZSBoYXMgYmVlbiBhcHByb3ZlZC4KCg4KBwQABAACAgESAzUEDAoOCgcEAAQAAgIC
EgM1DxAKLgoGBAAEAAIDEgM4BBEaHyBUaGUgY2hhbmdlIGhhcyBiZWVuIHJlamVjdGVkLgoK
DgoHBAAEAAIDARIDOAQMCg4KBwQABAACAwISAzgPEAowCgYEAAQAAgQSAzsEEBohIFRoZSBj
aGFuZ2UgcmVxdWVzdCBoYXMgZXhwaXJlZC4KCg4KBwQABAACBAESAzsECwoOCgcEAAQAAgQC
EgM7Dg8KNgoGBAAEAAIFEgM+BBAaJyBUaGUgYXBwcm92ZWQgY2hhbmdlIGhhcyBiZWVuIHJl
dm9rZWQuCgoOCgcEAAQAAgUBEgM+BAsKDgoHBAAEAAIFAhIDPg4PCkQKBAQABAESBEICcgMa
NiBFbnVtIHJlcHJlc2VudGluZyB0aGUgdHlwZSBvZiBjaGFuZ2UgaW4gdGhlIHBheWxvYWQu
CgoMCgUEAAQBARIDQgcRCiMKBgQABAECABIDRAQgGhQgU3RhdGUgdW5zcGVjaWZpZWQuCgoO
CgcEAAQBAgABEgNEBBsKDgoHBAAEAQIAAhIDRB4fCiwKBgQABAECARIDRwQVGh0gUmVxdWVz
dCB0byBjcmVhdGUgYW4gRW50cnkuCgoOCgcEAAQBAgEBEgNHBBAKDgoHBAAEAQIBAhIDRxMU
CiwKBgQABAECAhIDSgQVGh0gUmVxdWVzdCB0byB1cGRhdGUgYW4gRW50cnkuCgoOCgcEAAQB
AgIBEgNKBBAKDgoHBAAEAQICAhIDShMUCiwKBgQABAECAxIDTQQVGh0gUmVxdWVzdCB0byBk
ZWxldGUgYW4gRW50cnkuCgoOCgcEAAQBAgMBEgNNBBAKDgoHBAAEAQIDAhIDTRMUCjAKBgQA
BAECBBIDUAQaGiEgUmVxdWVzdCB0byBjcmVhdGUgYW4gRW50cnlMaW5rLgoKDgoHBAAEAQIE
ARIDUAQVCg4KBwQABAECBAISA1AYGQowCgYEAAQBAgUSA1MEGhohIFJlcXVlc3QgdG8gZGVs
ZXRlIGFuIEVudHJ5TGluay4KCg4KBwQABAECBQESA1MEFQoOCgcEAAQBAgUCEgNTGBkKLgoG
BAAEAQIGEgNWBBgaHyBSZXF1ZXN0IHRvIGNyZWF0ZSBhIEdsb3NzYXJ5LgoKDgoHBAAEAQIG
ARIDVgQTCg4KBwQABAECBgISA1YWFwouCgYEAAQBAgcSA1kEGBofIFJlcXVlc3QgdG8gdXBk
YXRlIGEgR2xvc3NhcnkuCgoOCgcEAAQBAgcBEgNZBBMKDgoHBAAEAQIHAhIDWRYXCi4KBgQA
BAECCBIDXAQYGh8gUmVxdWVzdCB0byBkZWxldGUgYSBHbG9zc2FyeS4KCg4KBwQABAECCAES
A1wEEwoOCgcEAAQBAggCEgNcFhcKNgoGBAAEAQIJEgNfBCIaJyBSZXF1ZXN0IHRvIGNyZWF0
ZSBhIEdsb3NzYXJ5Q2F0ZWdvcnkuCgoOCgcEAAQBAgkBEgNfBBwKDgoHBAAEAQIJAhIDXx8h
CjYKBgQABAECChIDYgQiGicgUmVxdWVzdCB0byB1cGRhdGUgYSBHbG9zc2FyeUNhdGVnb3J5
LgoKDgoHBAAEAQIKARIDYgQcCg4KBwQABAECCgISA2IfIQo2CgYEAAQBAgsSA2UEIhonIFJl
cXVlc3QgdG8gZGVsZXRlIGEgR2xvc3NhcnlDYXRlZ29yeS4KCg4KBwQABAECCwESA2UEHAoO
CgcEAAQBAgsCEgNlHyEKMgoGBAAEAQIMEgNoBB4aIyBSZXF1ZXN0IHRvIGNyZWF0ZSBhIEds
b3NzYXJ5VGVybS4KCg4KBwQABAECDAESA2gEGAoOCgcEAAQBAgwCEgNoGx0KMgoGBAAEAQIN
EgNrBB4aIyBSZXF1ZXN0IHRvIHVwZGF0ZSBhIEdsb3NzYXJ5VGVybS4KCg4KBwQABAECDQES
A2sEGAoOCgcEAAQBAg0CEgNrGx0KMgoGBAAEAQIOEgNuBB4aIyBSZXF1ZXN0IHRvIGRlbGV0
ZSBhIEdsb3NzYXJ5VGVybS4KCg4KBwQABAECDgESA24EGAoOCgcEAAQBAg4CEgNuGx0KOAoG
BAAEAQIPEgNxBCUaKSBSZXF1ZXN0IHRvIHJlcXVlc3QgRGF0YSBQcm9kdWN0IGFjY2Vzcy4K
Cg4KBwQABAECDwESA3EEHwoOCgcEAAQBAg8CEgNxIiQKrwEKBAQAAgASA3YCPRqhASBJZGVu
dGlmaWVyLiBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQ2hhbmdlUmVxdWVz
dCwgb2YgdGhlIGZvcm06CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb25faWR9L2NoYW5nZVJlcXVlc3RzL3tjaGFuZ2VfcmVxdWVzdF9pZH0KCgwKBQQA
AgAFEgN2AggKDAoFBAACAAESA3YJDQoMCgUEAAIAAxIDdhARCgwKBQQAAgAIEgN2EjwKDwoI
BAACAAicCAASA3YTOwpXCgQEAAIBEgR5AnwEGkkgT3V0cHV0IG9ubHkuIFN5c3RlbSBnZW5l
cmF0ZWQgZ2xvYmFsbHkgdW5pcXVlIElEIGZvciB0aGUgQ2hhbmdlUmVxdWVzdC4KCgwKBQQA
AgEFEgN5AggKDAoFBAACAQESA3kJDAoMCgUEAAIBAxIDeQ8QCg0KBQQAAgEIEgR5EXwDChIK
CwQAAgEIzPH5igEBEgN6BCoKDwoIBAACAQicCAASA3sELQpKCgQEAAICEgV/AoABMho7IE91
dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBDaGFuZ2VSZXF1ZXN0IHdhcyBjcmVhdGVk
LgoKDAoFBAACAgYSA38CGwoMCgUEAAICARIDfxwnCgwKBQQAAgIDEgN/KisKDQoFBAACAggS
BIABBjEKEAoIBAACAgicCAASBIABBzAKUAoEBAACAxIGgwEChAEyGkAgT3V0cHV0IG9ubHku
IFRoZSB0aW1lIHdoZW4gdGhlIENoYW5nZVJlcXVlc3Qgd2FzIGxhc3QgdXBkYXRlZC4KCg0K
BQQAAgMGEgSDAQIbCg0KBQQAAgMBEgSDARwnCg0KBQQAAgMDEgSDASorCg0KBQQAAgMIEgSE
AQYxChAKCAQAAgMInAgAEgSEAQcwCosBCgQEAAIEEgSIAQJEGn0gT3B0aW9uYWwuIEp1c3Rp
ZmljYXRpb24gb2YgdGhlIENoYW5nZVJlcXVlc3QuIFRoaXMgc2hvdWxkIGV4cGxhaW4KICp3
aHkqIHRoZSBjaGFuZ2UgaXMgbmVlZGVkIG9yIHdoeSBpdCBzaG91bGQgYmUgYXBwcm92ZWQu
CgoNCgUEAAIEBRIEiAECCAoNCgUEAAIEARIEiAEJFgoNCgUEAAIEAxIEiAEZGgoNCgUEAAIE
CBIEiAEbQwoQCggEAAIECJwIABIEiAEcQgpECgQEAAIFEgSLAQJKGjYgT3B0aW9uYWwuIFVz
ZXItZGVmaW5lZCBsYWJlbHMgZm9yIHRoZSBDaGFuZ2VSZXF1ZXN0LgoKDQoFBAACBQYSBIsB
AhUKDQoFBAACBQESBIsBFhwKDQoFBAACBQMSBIsBHyAKDQoFBAACBQgSBIsBIUkKEAoIBAAC
BQicCAASBIsBIkgKWQoEBAACBhIEjgECQBpLIE91dHB1dCBvbmx5LiBUaGUgZW1haWwgYWRk
cmVzcyBvZiB0aGUgdXNlciB3aG8gY3JlYXRlZCB0aGUgQ2hhbmdlUmVxdWVzdC4KCg0KBQQA
AgYFEgSOAQIICg0KBQQAAgYBEgSOAQkPCg0KBQQAAgYDEgSOARITCg0KBQQAAgYIEgSOARQ/
ChAKCAQAAgYInAgAEgSOARU+CkQKBAQAAgcSBJEBAj4aNiBPdXRwdXQgb25seS4gVGhlIGN1
cnJlbnQgc3RhdGUgb2YgdGhlIENoYW5nZVJlcXVlc3QuCgoNCgUEAAIHBhIEkQECBwoNCgUE
AAIHARIEkQEIDQoNCgUEAAIHAxIEkQEQEQoNCgUEAAIHCBIEkQESPQoQCggEAAIHCJwIABIE
kQETPArSAQoEBAACCBIGlgECmQEEGsEBIE91dHB1dCBvbmx5LiBUaGUgZnVsbCByZXNvdXJj
ZSBuYW1lIG9mIHRoZSB0YXJnZXQgcmVzb3VyY2UgdG8gYmUgbW9kaWZpZWQuCiBFeGFtcGxl
OgogLy9kYXRhcGxleC5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0
aW9ucy91cy1jZW50cmFsMS9lbnRyeUdyb3Vwcy9teS1ncm91cC9lbnRyaWVzL215LWVudHJ5
CgoNCgUEAAIIBRIElgECCAoNCgUEAAIIARIElgEJEQoNCgUEAAIIAxIElgEUFQoPCgUEAAII
CBIGlgEWmQEDChAKCAQAAggInAgAEgSXAQQtCg8KBwQAAggInwgSBJgBBDMKVwoEBAAIABIG
nAECyQEDGkcgRGV0YWlsZWQgc3BlY2lmaWNhdGlvbiBvZiB0aGUgY2hhbmdlLCBlbWJlZGRp
bmcgdGhlIG9yaWdpbmFsIHJlcXVlc3QuCgoNCgUEAAgAARIEnAEIFgouCgQEAAIJEgSeAQQp
GiAgUGF5bG9hZCBmb3IgY3JlYXRpbmcgYW4gRW50cnkuCgoNCgUEAAIJBhIEngEEFgoNCgUE
AAIJARIEngEXIwoNCgUEAAIJAxIEngEmKAouCgQEAAIKEgShAQQpGiAgUGF5bG9hZCBmb3Ig
dXBkYXRpbmcgYW4gRW50cnkuCgoNCgUEAAIKBhIEoQEEFgoNCgUEAAIKARIEoQEXIwoNCgUE
AAIKAxIEoQEmKAouCgQEAAILEgSkAQQpGiAgUGF5bG9hZCBmb3IgZGVsZXRpbmcgYW4gRW50
cnkuCgoNCgUEAAILBhIEpAEEFgoNCgUEAAILARIEpAEXIwoNCgUEAAILAxIEpAEmKAoyCgQE
AAIMEgSnAQQyGiQgUGF5bG9hZCBmb3IgY3JlYXRpbmcgYW4gRW50cnlMaW5rLgoKDQoFBAAC
DAYSBKcBBBoKDQoFBAACDAESBKcBGywKDQoFBAACDAMSBKcBLzEKMgoEBAACDRIEqgEEMhok
IFBheWxvYWQgZm9yIGRlbGV0aW5nIGFuIEVudHJ5TGluay4KCg0KBQQAAg0GEgSqAQQaCg0K
BQQAAg0BEgSqARssCg0KBQQAAg0DEgSqAS8xCjAKBAQAAg4SBK0BBC8aIiBQYXlsb2FkIGZv
ciBjcmVhdGluZyBhIEdsb3NzYXJ5LgoKDQoFBAACDgYSBK0BBBkKDQoFBAACDgESBK0BGikK
DQoFBAACDgMSBK0BLC4KMAoEBAACDxIEsAEELxoiIFBheWxvYWQgZm9yIHVwZGF0aW5nIGEg
R2xvc3NhcnkuCgoNCgUEAAIPBhIEsAEEGQoNCgUEAAIPARIEsAEaKQoNCgUEAAIPAxIEsAEs
LgowCgQEAAIQEgSzAQQvGiIgUGF5bG9hZCBmb3IgZGVsZXRpbmcgYSBHbG9zc2FyeS4KCg0K
BQQAAhAGEgSzAQQZCg0KBQQAAhABEgSzARopCg0KBQQAAhADEgSzASwuCjgKBAQAAhESBLYB
BEAaKiBQYXlsb2FkIGZvciBjcmVhdGluZyBhIEdsb3NzYXJ5Q2F0ZWdvcnkuCgoNCgUEAAIR
BhIEtgEEIQoNCgUEAAIRARIEtgEiOgoNCgUEAAIRAxIEtgE9Pwo4CgQEAAISEgS5AQRAGiog
UGF5bG9hZCBmb3IgdXBkYXRpbmcgYSBHbG9zc2FyeUNhdGVnb3J5LgoKDQoFBAACEgYSBLkB
BCEKDQoFBAACEgESBLkBIjoKDQoFBAACEgMSBLkBPT8KOAoEBAACExIEvAEEQBoqIFBheWxv
YWQgZm9yIGRlbGV0aW5nIGEgR2xvc3NhcnlDYXRlZ29yeS4KCg0KBQQAAhMGEgS8AQQhCg0K
BQQAAhMBEgS8ASI6Cg0KBQQAAhMDEgS8AT0/CjQKBAQAAhQSBL8BBDgaJiBQYXlsb2FkIGZv
ciBjcmVhdGluZyBhIEdsb3NzYXJ5VGVybS4KCg0KBQQAAhQGEgS/AQQdCg0KBQQAAhQBEgS/
AR4yCg0KBQQAAhQDEgS/ATU3CjQKBAQAAhUSBMIBBDgaJiBQYXlsb2FkIGZvciB1cGRhdGlu
ZyBhIEdsb3NzYXJ5VGVybS4KCg0KBQQAAhUGEgTCAQQdCg0KBQQAAhUBEgTCAR4yCg0KBQQA
AhUDEgTCATU3CjQKBAQAAhYSBMUBBDgaJiBQYXlsb2FkIGZvciBkZWxldGluZyBhIEdsb3Nz
YXJ5VGVybS4KCg0KBQQAAhYGEgTFAQQdCg0KBQQAAhYBEgTFAR4yCg0KBQQAAhYDEgTFATU3
CjgKBAQAAhcSBMgBBD4aKiBQYXlsb2FkIGZvciBEYXRhIFByb2R1Y3QgYWNjZXNzIHJlcXVl
c3QuCgoNCgUEAAIXBhIEyAEEHAoNCgUEAAIXARIEyAEdOAoNCgUEAAIXAxIEyAE7PQqgAQoE
BAACGBIEzQECShqRASBPdXRwdXQgb25seS4gVGhlIHR5cGUgb2YgY2hhbmdlIHJlcHJlc2Vu
dGVkIGJ5IHRoZSBjaGFuZ2VfcGF5bG9hZC4KIFRoaXMgZmllbGQgaXMgZGVyaXZlZCBmcm9t
IHRoZSBwb3B1bGF0ZWQgZmllbGQgaW4gdGhlIGNoYW5nZV9wYXlsb2FkIG9uZW9mLgoKDQoF
BAACGAYSBM0BAgwKDQoFBAACGAESBM0BDRgKDQoFBAACGAMSBM0BGx0KDQoFBAACGAgSBM0B
HkkKEAoIBAACGAicCAASBM0BH0gKUQoEBAACGRIE0AECTBpDIE91dHB1dCBvbmx5LiBUaGUg
cmVhc29uIHByb3ZpZGVkIGZvciByZWplY3RpbmcgdGhlIENoYW5nZVJlcXVlc3QuCgoNCgUE
AAIZBRIE0AECCAoNCgUEAAIZARIE0AEJGgoNCgUEAAIZAxIE0AEdHwoNCgUEAAIZCBIE0AEg
SwoQCggEAAIZCJwIABIE0AEhSgpkCgQEAAIaEgTUAQJDGlYgT3V0cHV0IG9ubHkuIFRoZSBl
bWFpbCBhZGRyZXNzIG9mIHRoZSB1c2VyIHdobyBhcHByb3ZlZC9yZWplY3RlZCB0aGUKIENo
YW5nZVJlcXVlc3QuCgoNCgUEAAIaBRIE1AECCAoNCgUEAAIaARIE1AEJEQoNCgUEAAIaAxIE
1AEUFgoNCgUEAAIaCBIE1AEXQgoQCggEAAIaCJwIABIE1AEYQQqzAQoEBAACGxIE2QECPBqk
ASBPcHRpb25hbC4gVGhpcyBjaGVja3N1bSBpcyBjb21wdXRlZCBieSB0aGUgc2VydmljZS4g
SXQgY2FuIGJlIHNlbnQgb24KIHVwZGF0ZSBhbmQgZGVsZXRlIHJlcXVlc3RzIHRvIGVuc3Vy
ZSB0aGUgY2xpZW50IGhhcyBhbiB1cC10by1kYXRlIHZhbHVlCiBiZWZvcmUgcHJvY2VlZGlu
Zy4KCg0KBQQAAhsFEgTZAQIICg0KBQQAAhsBEgTZAQkNCg0KBQQAAhsDEgTZARASCg0KBQQA
AhsIEgTZARM7ChAKCAQAAhsInAgAEgTZARQ6CpMBCgIEARIG3gEA+gEBGoQBIE1lc3NhZ2Ug
Zm9yIHJlcXVlc3RpbmcgYWNjZXNzIHRvIGEgRGF0YSBQcm9kdWN0LiBUaGlzIHdpbGwgYmUg
dXNlZCB0bwogY3JlYXRlIGEgQ2hhbmdlUmVxdWVzdCBvZiB0eXBlIFJFUVVFU1RfREFUQV9Q
Uk9EVUNUX0FDQ0VTUy4KCgsKAwQBARIE3gEIIAqeAQoEBAECABIG4gEC5wEEGo0BIFJlcXVp
cmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZGF0YSBwcm9kdWN0LgogRm9ybWF0Ogog
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9kYXRh
UHJvZHVjdHMve2RhdGFfcHJvZHVjdF9pZH0KCg0KBQQBAgAFEgTiAQIICg0KBQQBAgABEgTi
AQkPCg0KBQQBAgADEgTiARITCg8KBQQBAgAIEgbiARTnAQMKEAoIBAECAAicCAASBOMBBCoK
EQoHBAECAAifCBIG5AEE5gEFCrYBCgQEAQIBEgTsAQJGGqcBIFJlcXVpcmVkLiBUaGUgSUQg
b2YgdGhlIGFjY2VzcyBncm91cCBmb3Igd2hpY2ggYWNjZXNzIGlzIGJlaW5nIHJlcXVlc3Rl
ZC4KIFRoaXMgY29ycmVzcG9uZHMgdG8gdGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBB
Y2Nlc3NHcm91cCBkZWZpbmVkIGluIHRoZQogRGF0YSBQcm9kdWN0LgoKDQoFBAECAQUSBOwB
AggKDQoFBAECAQESBOwBCRgKDQoFBAECAQMSBOwBGxwKDQoFBAECAQgSBOwBHUUKEAoIBAEC
AQicCAASBOwBHkQKhQEKBAQBAgISBvABAvEBMhp1IE91dHB1dCBvbmx5LiBUaGUgZGlzcGxh
eSBuYW1lIG9mIHRoZSBhY2Nlc3MgZ3JvdXAgZGVmaW5lZCBpbiB0aGUgRGF0YQogUHJvZHVj
dCBmb3Igd2hpY2ggYWNjZXNzIGlzIGJlaW5nIHJlcXVlc3RlZC4KCg0KBQQBAgIFEgTwAQII
Cg0KBQQBAgIBEgTwAQkiCg0KBQQBAgIDEgTwASUmCg0KBQQBAgIIEgTxAQYxChAKCAQBAgII
nAgAEgTxAQcwCtACCgQEAQIDEgb4AQL5AS8avwIgT3B0aW9uYWwuIFRoZSBwcmluY2lwYWwg
Zm9yIHdoaWNoIGFjY2VzcyBpcyBiZWluZyByZXF1ZXN0ZWQgaW4gSUFNIGZvcm1hdC4KIElm
IG5vdCBzcGVjaWZpZWQsIHRoZSByZXF1ZXN0b3IncyBwcmluY2lwYWwgd2lsbCBiZSB1c2Vk
LgogRXhhbXBsZTogYHNlcnZpY2VBY2NvdW50Om15LXNhQG15LXByb2plY3QuaWFtLmdzZXJ2
aWNlYWNjb3VudC5jb21gLgogT25seSBzZXJ2aWNlIGFjY291bnQgcHJpbmNpcGFscyBhcmUg
Y3VycmVudGx5IHN1cHBvcnRlZC4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vZG9j
cy9wcmluY2lwYWwtaWRlbnRpZmllcnMKCg0KBQQBAgMEEgT4AQIKCg0KBQQBAgMFEgT4AQsR
Cg0KBQQBAgMBEgT4ARIlCg0KBQQBAgMDEgT4ASgpCg0KBQQBAgMIEgT5AQYuChAKCAQBAgMI
nAgAEgT5AQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest ===
    # Fields for ChangeRequest
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: justification Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataplex.v1.ChangeRequest.LabelsEntry)
    # Field: author Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dataplex.v1.ChangeRequest.State)
    # Field: resource Type: 9 ()
    # Field: create_entry Type: 11 (.google.cloud.dataplex.v1.CreateEntryRequest)
    # Field: update_entry Type: 11 (.google.cloud.dataplex.v1.UpdateEntryRequest)
    # Field: delete_entry Type: 11 (.google.cloud.dataplex.v1.DeleteEntryRequest)
    # Field: create_entry_link Type: 11 (.google.cloud.dataplex.v1.CreateEntryLinkRequest)
    # Field: delete_entry_link Type: 11 (.google.cloud.dataplex.v1.DeleteEntryLinkRequest)
    # Field: create_glossary Type: 11 (.google.cloud.dataplex.v1.CreateGlossaryRequest)
    # Field: update_glossary Type: 11 (.google.cloud.dataplex.v1.UpdateGlossaryRequest)
    # Field: delete_glossary Type: 11 (.google.cloud.dataplex.v1.DeleteGlossaryRequest)
    # Field: create_glossary_category Type: 11 (.google.cloud.dataplex.v1.CreateGlossaryCategoryRequest)
    # Field: update_glossary_category Type: 11 (.google.cloud.dataplex.v1.UpdateGlossaryCategoryRequest)
    # Field: delete_glossary_category Type: 11 (.google.cloud.dataplex.v1.DeleteGlossaryCategoryRequest)
    # Field: create_glossary_term Type: 11 (.google.cloud.dataplex.v1.CreateGlossaryTermRequest)
    # Field: update_glossary_term Type: 11 (.google.cloud.dataplex.v1.UpdateGlossaryTermRequest)
    # Field: delete_glossary_term Type: 11 (.google.cloud.dataplex.v1.DeleteGlossaryTermRequest)
    # Field: data_product_access_request Type: 11 (.google.cloud.dataplex.v1.DataProductAccessRequest)
    # Field: change_type Type: 14 (.google.cloud.dataplex.v1.ChangeRequest.ChangeType)
    # Field: rejection_comment Type: 9 ()
    # Field: approver Type: 9 ()
    # Field: etag Type: 9 ()

# Enum: ChangeRequest::State
our $ChangeRequest_STATE_UNSPECIFIED = 0;
our $ChangeRequest_NEW = 1;
our $ChangeRequest_APPROVED = 2;
our $ChangeRequest_REJECTED = 3;
our $ChangeRequest_EXPIRED = 4;
our $ChangeRequest_REVOKED = 5;

# Enum: ChangeRequest::ChangeType
our $ChangeRequest_CHANGE_TYPE_UNSPECIFIED = 0;
our $ChangeRequest_CREATE_ENTRY = 1;
our $ChangeRequest_UPDATE_ENTRY = 2;
our $ChangeRequest_DELETE_ENTRY = 3;
our $ChangeRequest_CREATE_ENTRY_LINK = 4;
our $ChangeRequest_DELETE_ENTRY_LINK = 5;
our $ChangeRequest_CREATE_GLOSSARY = 7;
our $ChangeRequest_UPDATE_GLOSSARY = 8;
our $ChangeRequest_DELETE_GLOSSARY = 9;
our $ChangeRequest_CREATE_GLOSSARY_CATEGORY = 10;
our $ChangeRequest_UPDATE_GLOSSARY_CATEGORY = 11;
our $ChangeRequest_DELETE_GLOSSARY_CATEGORY = 13;
our $ChangeRequest_CREATE_GLOSSARY_TERM = 14;
our $ChangeRequest_UPDATE_GLOSSARY_TERM = 15;
our $ChangeRequest_DELETE_GLOSSARY_TERM = 17;
our $ChangeRequest_REQUEST_DATA_PRODUCT_ACCESS = 33;

# === Message: Google::Cloud::Dataplex::V1::ApprovalWorkflow::DataProductAccessRequest ===
    # Fields for DataProductAccessRequest
    # Field: parent Type: 9 ()
    # Field: access_group_id Type: 9 ()
    # Field: access_group_display_name Type: 9 ()
    # Field: requested_principal Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataplex::V1::ApprovalWorkflow - Compiled Protocol Buffers messages for google/cloud/dataplex/v1/approval_workflow.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::ApprovalWorkflow;

    my $msg = Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataplex/v1/approval_workflow.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest

Represents a proposed change to a metadata resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The relative resource name of the ChangeRequest, of the form:
projects/{project_number}/locations/{location_id}/changeRequests/{change_request_id}

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. System generated globally unique ID for the ChangeRequest.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the ChangeRequest was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the ChangeRequest was last updated.

=item * C<< $msg->justification() >> / C<< $msg->justification($value) >>

Type: C<String>

Optional. Justification of the ChangeRequest. This should explain
*why* the change is needed or why it should be approved.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest::LabelsEntry>)

Optional. User-defined labels for the ChangeRequest.

=item * C<< $msg->author() >> / C<< $msg->author($value) >>

Type: C<String>

Output only. The email address of the user who created the ChangeRequest.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dataplex::V1::ChangeRequest::State>)

Output only. The current state of the ChangeRequest.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Output only. The full resource name of the target resource to be modified.
Example:
//dataplex.googleapis.com/projects/my-project/locations/us-central1/entryGroups/my-group/entries/my-entry

=item * C<< $msg->create_entry() >> / C<< $msg->create_entry($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::Catalog::CreateEntryRequest>)

Payload for creating an Entry.

=item * C<< $msg->update_entry() >> / C<< $msg->update_entry($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::Catalog::UpdateEntryRequest>)

Payload for updating an Entry.

=item * C<< $msg->delete_entry() >> / C<< $msg->delete_entry($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::Catalog::DeleteEntryRequest>)

Payload for deleting an Entry.

=item * C<< $msg->create_entry_link() >> / C<< $msg->create_entry_link($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::Catalog::CreateEntryLinkRequest>)

Payload for creating an EntryLink.

=item * C<< $msg->delete_entry_link() >> / C<< $msg->delete_entry_link($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::Catalog::DeleteEntryLinkRequest>)

Payload for deleting an EntryLink.

=item * C<< $msg->create_glossary() >> / C<< $msg->create_glossary($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryRequest>)

Payload for creating a Glossary.

=item * C<< $msg->update_glossary() >> / C<< $msg->update_glossary($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryRequest>)

Payload for updating a Glossary.

=item * C<< $msg->delete_glossary() >> / C<< $msg->delete_glossary($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryRequest>)

Payload for deleting a Glossary.

=item * C<< $msg->create_glossary_category() >> / C<< $msg->create_glossary_category($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryCategoryRequest>)

Payload for creating a GlossaryCategory.

=item * C<< $msg->update_glossary_category() >> / C<< $msg->update_glossary_category($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryCategoryRequest>)

Payload for updating a GlossaryCategory.

=item * C<< $msg->delete_glossary_category() >> / C<< $msg->delete_glossary_category($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryCategoryRequest>)

Payload for deleting a GlossaryCategory.

=item * C<< $msg->create_glossary_term() >> / C<< $msg->create_glossary_term($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::CreateGlossaryTermRequest>)

Payload for creating a GlossaryTerm.

=item * C<< $msg->update_glossary_term() >> / C<< $msg->update_glossary_term($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::UpdateGlossaryTermRequest>)

Payload for updating a GlossaryTerm.

=item * C<< $msg->delete_glossary_term() >> / C<< $msg->delete_glossary_term($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::BusinessGlossary::DeleteGlossaryTermRequest>)

Payload for deleting a GlossaryTerm.

=item * C<< $msg->data_product_access_request() >> / C<< $msg->data_product_access_request($value) >>

Type: C<Message> (L<Google::Cloud::Dataplex::V1::ApprovalWorkflow::DataProductAccessRequest>)

Payload for Data Product access request.

=item * C<< $msg->change_type() >> / C<< $msg->change_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dataplex::V1::ChangeRequest::ChangeType>)

Output only. The type of change represented by the change_payload.
This field is derived from the populated field in the change_payload oneof.

=item * C<< $msg->rejection_comment() >> / C<< $msg->rejection_comment($value) >>

Type: C<String>

Output only. The reason provided for rejecting the ChangeRequest.

=item * C<< $msg->approver() >> / C<< $msg->approver($value) >>

Type: C<String>

Output only. The email address of the user who approved/rejected the
ChangeRequest.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. This checksum is computed by the service. It can be sent on
update and delete requests to ensure the client has an up-to-date value
before proceeding.

=back

=head3 Enum: ChangeRequest::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<NEW> => C<1>

=item * C<APPROVED> => C<2>

=item * C<REJECTED> => C<3>

=item * C<EXPIRED> => C<4>

=item * C<REVOKED> => C<5>

=back

=head3 Enum: ChangeRequest::ChangeType

=over 4

=item * C<CHANGE_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE_ENTRY> => C<1>

=item * C<UPDATE_ENTRY> => C<2>

=item * C<DELETE_ENTRY> => C<3>

=item * C<CREATE_ENTRY_LINK> => C<4>

=item * C<DELETE_ENTRY_LINK> => C<5>

=item * C<CREATE_GLOSSARY> => C<7>

=item * C<UPDATE_GLOSSARY> => C<8>

=item * C<DELETE_GLOSSARY> => C<9>

=item * C<CREATE_GLOSSARY_CATEGORY> => C<10>

=item * C<UPDATE_GLOSSARY_CATEGORY> => C<11>

=item * C<DELETE_GLOSSARY_CATEGORY> => C<13>

=item * C<CREATE_GLOSSARY_TERM> => C<14>

=item * C<UPDATE_GLOSSARY_TERM> => C<15>

=item * C<DELETE_GLOSSARY_TERM> => C<17>

=item * C<REQUEST_DATA_PRODUCT_ACCESS> => C<33>

=back

=head2 Google::Cloud::Dataplex::V1::ApprovalWorkflow::DataProductAccessRequest

Message for requesting access to a Data Product. This will be used to
create a ChangeRequest of type REQUEST_DATA_PRODUCT_ACCESS.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the data product.
Format:
projects/{project_number}/locations/{location_id}/dataProducts/{data_product_id}

=item * C<< $msg->access_group_id() >> / C<< $msg->access_group_id($value) >>

Type: C<String>

Required. The ID of the access group for which access is being requested.
This corresponds to the unique identifier of the AccessGroup defined in the
Data Product.

=item * C<< $msg->access_group_display_name() >> / C<< $msg->access_group_display_name($value) >>

Type: C<String>

Output only. The display name of the access group defined in the Data
Product for which access is being requested.

=item * C<< $msg->requested_principal() >> / C<< $msg->requested_principal($value) >>

Type: C<String>

Optional. The principal for which access is being requested in IAM format.
If not specified, the requestor's principal will be used.
Example: `serviceAccount:my-sa@my-project.iam.gserviceaccount.com`.
Only service account principals are currently supported.
https://cloud.google.com/iam/docs/principal-identifiers

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataplex::V1::ApprovalWorkflow::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
