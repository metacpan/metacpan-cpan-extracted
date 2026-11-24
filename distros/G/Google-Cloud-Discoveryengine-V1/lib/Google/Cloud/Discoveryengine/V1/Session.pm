package Google::Cloud::Discoveryengine::V1::Session;

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
    eval { require Google::Cloud::Discoveryengine::V1::Answer };
    eval { require Google::Cloud::Discoveryengine::V1::AssistAnswer };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3Nlc3Npb24ucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91ZC9kaXNjb3Zl
cnllbmdpbmUvdjEvYW5zd2VyLnByb3RvGjNnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5l
L3YxL2Fzc2lzdF9hbnN3ZXIucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8iyQwKB1Nlc3Npb24SFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEiYKDGRpc3BsYXlfbmFt
ZRgHIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJECgVzdGF0ZRgCIAEoDjIuLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2Vzc2lvbi5TdGF0ZVIFc3RhdGUSJAoOdXNlcl9wc2V1
ZG9faWQYAyABKAlSDHVzZXJQc2V1ZG9JZBJDCgV0dXJucxgEIAMoCzItLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2Vzc2lvbi5UdXJuUgV0dXJucxIbCgZsYWJlbHMYCSAD
KAlCA+BBAVIGbGFiZWxzEj4KCnN0YXJ0X3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRI6CghlbmRfdGltZRgGIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGltZRIgCglpc19waW5uZWQYCCABKAhCA+BB
AVIIaXNQaW5uZWQSTQohcGVuZGluZ19hc3luY19hc3Npc3Rfb3BlcmF0aW9uX2lkGBYgASgJ
QgPgQQNSHXBlbmRpbmdBc3luY0Fzc2lzdE9wZXJhdGlvbklkGpIECgRUdXJuEkEKBXF1ZXJ5
GAEgASgLMiYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5RdWVyeUID4EEBUgVx
dWVyeRJFCgZhbnN3ZXIYAiABKAlCLeBBAfpBJwolZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0Fuc3dlclIGYW5zd2VyElUKD2RldGFpbGVkX2Fuc3dlchgHIAEoCzInLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQW5zd2VyQgPgQQNSDmRldGFpbGVkQW5zd2Vy
EmgKFmRldGFpbGVkX2Fzc2lzdF9hbnN3ZXIYCCABKAsyLS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLkFzc2lzdEFuc3dlckID4EEDUhRkZXRhaWxlZEFzc2lzdEFuc3dlchJm
CgxxdWVyeV9jb25maWcYECADKAsyPi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LlNlc3Npb24uVHVybi5RdWVyeUNvbmZpZ0VudHJ5QgPgQQFSC3F1ZXJ5Q29uZmlnEhcKBGxp
dmUYFCABKAhCA+BBAVIEbGl2ZRo+ChBRdWVyeUNvbmZpZ0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiLwoFU3RhdGUSFQoRU1RBVEVfVU5TUEVD
SUZJRUQQABIPCgtJTl9QUk9HUkVTUxABOvsD6kH3AwomZGlzY292ZXJ5ZW5naW5lLmdvb2ds
ZWFwaXMuY29tL1Nlc3Npb24SUnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zZXNzaW9ucy97c2Vzc2lvbn0Sa3Byb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVj
dGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2Vzc2lvbnMve3Nlc3Npb259EmRwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxl
Y3Rpb259L2VuZ2luZXMve2VuZ2luZX0vc2Vzc2lvbnMve3Nlc3Npb259EpIBcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9u
fS9lbmdpbmVzL3tlbmdpbmV9L2NvbGxhYm9yYXRpdmVQcm9qZWN0cy97Y29sbGFib3JhdGl2
ZV9wcm9qZWN0fS9zZXNzaW9ucy97c2Vzc2lvbn0qCHNlc3Npb25zMgdzZXNzaW9uIkgKBVF1
ZXJ5EhQKBHRleHQYAiABKAlIAFIEdGV4dBIeCghxdWVyeV9pZBgBIAEoCUID4EEDUgdxdWVy
eUlkQgkKB2NvbnRlbnRC/wEKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
QgxTZXNzaW9uUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUv
YXBpdjEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllF
TkdJTkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3Vk
XERpc2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6
VjFKkigKBxIFDgCZAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
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
EgMQACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADYKCQoCAwMSAxUAPQoJCgID
BBIDFgApCggKAQgSAxgAPAoJCgIIJRIDGAA8CggKAQgSAxkAZAoJCgIICxIDGQBkCggKAQgS
AxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAPAoJCgIIARID
HAA8CggKAQgSAx0ALQoJCgIIJBIDHQAtCggKAQgSAx4APAoJCgIIKRIDHgA8CggKAQgSAx8A
OwoJCgIILRIDHwA7CjEKAgQAEgUiAI0BARokIEV4dGVybmFsIHNlc3Npb24gcHJvdG8gZGVm
aW5pdGlvbi4KCgoKAwQAARIDIggPCgsKAwQABxIEIwIrBAoNCgUEAAedCBIEIwIrBApeCgQE
AAMAEgQvAlkDGlAgUmVwcmVzZW50cyBhIHR1cm4sIGluY2x1ZGluZyBhIHF1ZXJ5IGZyb20g
dGhlIHVzZXIgYW5kIGEKIGFuc3dlciBmcm9tIHNlcnZpY2UuCgoMCgUEAAMAARIDLwoOCnwK
BgQAAwACABIDMgQ9Gm0gT3B0aW9uYWwuIFRoZSB1c2VyIHF1ZXJ5LiBNYXkgbm90IGJlIHNl
dCBpZiB0aGlzIHR1cm4gaXMgbWVyZWx5CiByZWdlbmVyYXRpbmcgYW4gYW5zd2VyIHRvIGEg
ZGlmZmVyZW50IHR1cm4KCg4KBwQAAwACAAYSAzIECQoOCgcEAAMAAgABEgMyCg8KDgoHBAAD
AAIAAxIDMhITCg4KBwQAAwACAAgSAzIUPAoRCgoEAAMAAgAInAgAEgMyFTsKngEKBgQAAwAC
ARIEOAQ9BhqNASBPcHRpb25hbC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGFuc3dlciB0
byB0aGUgdXNlciBxdWVyeS4KCiBPbmx5IHNldCBpZiB0aGUgYW5zd2VyIGdlbmVyYXRpb24g
KC9hbnN3ZXIgQVBJIGNhbGwpIGhhcHBlbmVkIGluIHRoaXMKIHR1cm4uCgoOCgcEAAMAAgEF
EgM4BAoKDgoHBAADAAIBARIDOAsRCg4KBwQAAwACAQMSAzgUFQoPCgcEAAMAAgEIEgQ4Fj0F
ChEKCgQAAwACAQicCAASAzkGLAoRCgkEAAMAAgEInwgSBDoGPAcK5AIKBgQAAwACAhIDRQRL
GtQCIE91dHB1dCBvbmx5LiBJbgogW0NvbnZlcnNhdGlvbmFsU2VhcmNoU2VydmljZS5HZXRT
ZXNzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNvbnZlcnNhdGlvbmFs
U2VhcmNoU2VydmljZS5HZXRTZXNzaW9uXQogQVBJLCBpZgogW0dldFNlc3Npb25SZXF1ZXN0
LmluY2x1ZGVfYW5zd2VyX2RldGFpbHNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuR2V0U2Vzc2lvblJlcXVlc3QuaW5jbHVkZV9hbnN3ZXJfZGV0YWlsc10KIGlzIHNldCB0
byB0cnVlLCB0aGlzIGZpZWxkIHdpbGwgYmUgcG9wdWxhdGVkIHdoZW4gZ2V0dGluZyBhbnN3
ZXIgcXVlcnkKIHNlc3Npb24uCgoOCgcEAAMAAgIGEgNFBAoKDgoHBAADAAICARIDRQsaCg4K
BwQAAwACAgMSA0UdHgoOCgcEAAMAAgIIEgNFH0oKEQoKBAADAAICCJwIABIDRSBJCuICCgYE
AAMAAgMSBE0ETjQa0QIgT3V0cHV0IG9ubHkuIEluCiBbQ29udmVyc2F0aW9uYWxTZWFyY2hT
ZXJ2aWNlLkdldFNlc3Npb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29u
dmVyc2F0aW9uYWxTZWFyY2hTZXJ2aWNlLkdldFNlc3Npb25dCiBBUEksIGlmCiBbR2V0U2Vz
c2lvblJlcXVlc3QuaW5jbHVkZV9hbnN3ZXJfZGV0YWlsc11bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5HZXRTZXNzaW9uUmVxdWVzdC5pbmNsdWRlX2Fuc3dlcl9kZXRhaWxz
XQogaXMgc2V0IHRvIHRydWUsIHRoaXMgZmllbGQgd2lsbCBiZSBwb3B1bGF0ZWQgd2hlbiBn
ZXR0aW5nIGFzc2lzdGFudAogc2Vzc2lvbi4KCg4KBwQAAwACAwYSA00EEAoOCgcEAAMAAgMB
EgNNEScKDgoHBAADAAIDAxIDTSorCg4KBwQAAwACAwgSA04IMwoRCgoEAAMAAgMInAgAEgNO
CTIK+QEKBgQAAwACBBIEVARVMRroASBPcHRpb25hbC4gUmVwcmVzZW50cyBtZXRhZGF0YSBy
ZWxhdGVkIHRvIHRoZSBxdWVyeSBjb25maWcsIGZvciBleGFtcGxlCiBMTE0gbW9kZWwgYW5k
IHZlcnNpb24gdXNlZCwgbW9kZWwgcGFyYW1ldGVycyAodGVtcGVyYXR1cmUsIGdyb3VuZGlu
ZwogcGFyYW1ldGVycywgZXRjLikuIFRoZSBwcmVmaXggImdvb2dsZS4iIGlzIHJlc2VydmVk
IGZvciBHb29nbGUtZGV2ZWxvcGVkCiBmdW5jdGlvbmFsaXR5LgoKDgoHBAADAAIEBhIDVAQX
Cg4KBwQAAwACBAESA1QYJAoOCgcEAAMAAgQDEgNUJykKDgoHBAADAAIECBIDVQgwChEKCgQA
AwACBAicCAASA1UJLwpGCgYEAAMAAgUSA1gEPBo3IE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hl
dGhlciB0aGlzIHR1cm4gaXMgYSBsaXZlIHR1cm4uCgoOCgcEAAMAAgUFEgNYBAgKDgoHBAAD
AAIFARIDWAkNCg4KBwQAAwACBQMSA1gQEgoOCgcEAAMAAgUIEgNYEzsKEQoKBAADAAIFCJwI
ABIDWBQ6CjgKBAQABAASBFwCYgMaKiBFbnVtZXJhdGlvbiBvZiB0aGUgc3RhdGUgb2YgdGhl
IHNlc3Npb24uCgoMCgUEAAQAARIDXAcMCiYKBgQABAACABIDXgQaGhcgU3RhdGUgaXMgdW5z
cGVjaWZpZWQuCgoOCgcEAAQAAgABEgNeBBUKDgoHBAAEAAIAAhIDXhgZCi8KBgQABAACARID
YQQUGiAgVGhlIHNlc3Npb24gaXMgY3VycmVudGx5IG9wZW4uCgoOCgcEAAQAAgEBEgNhBA8K
DgoHBAAEAAIBAhIDYRITCooBCgQEAAIAEgNmAjwafSBJbW11dGFibGUuIEZ1bGx5IHF1YWxp
ZmllZCBuYW1lCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy9nbG9iYWwvY29sbGVj
dGlvbnMve2NvbGxlY3Rpb259L2VuZ2luZXMve2VuZ2luZX0vc2Vzc2lvbnMvKmAKCgwKBQQA
AgAFEgNmAggKDAoFBAACAAESA2YJDQoMCgUEAAIAAxIDZhARCgwKBQQAAgAIEgNmEjsKDwoI
BAACAAicCAASA2YTOgq9AQoEBAACARIDbAJDGq8BIE9wdGlvbmFsLiBUaGUgZGlzcGxheSBu
YW1lIG9mIHRoZSBzZXNzaW9uLgoKIFRoaXMgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0
aGUgc2Vzc2lvbiBpbiB0aGUgVUkuCiBCeSBkZWZhdWx0LCB0aGUgZGlzcGxheSBuYW1lIGlz
IHRoZSBmaXJzdCB0dXJuIHF1ZXJ5IHRleHQgaW4gdGhlIHNlc3Npb24uCgoMCgUEAAIBBRID
bAIICgwKBQQAAgEBEgNsCRUKDAoFBAACAQMSA2wYGQoMCgUEAAIBCBIDbBpCCg8KCAQAAgEI
nAgAEgNsG0EKKAoEBAACAhIDbwISGhsgVGhlIHN0YXRlIG9mIHRoZSBzZXNzaW9uLgoKDAoF
BAACAgYSA28CBwoMCgUEAAICARIDbwgNCgwKBQQAAgIDEgNvEBEKNgoEBAACAxIDcgIcGikg
QSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdHJhY2tpbmcgdXNlcnMuCgoMCgUEAAIDBRIDcgII
CgwKBQQAAgMBEgNyCRcKDAoFBAACAwMSA3IaGwoVCgQEAAIEEgN1AhoaCCBUdXJucy4KCgwK
BQQAAgQEEgN1AgoKDAoFBAACBAYSA3ULDwoMCgUEAAIEARIDdRAVCgwKBQQAAgQDEgN1GBkK
YgoEBAACBRIDeQJGGlUgT3B0aW9uYWwuIFRoZSBsYWJlbHMgZm9yIHRoZSBzZXNzaW9uLgog
Q2FuIGJlIHNldCBhcyBmaWx0ZXIgaW4gTGlzdFNlc3Npb25zUmVxdWVzdC4KCgwKBQQAAgUE
EgN5AgoKDAoFBAACBQUSA3kLEQoMCgUEAAIFARIDeRIYCgwKBQQAAgUDEgN5GxwKDAoFBAAC
BQgSA3kdRQoPCggEAAIFCJwIABIDeR5ECjoKBAQAAgYSBHwCfTIaLCBPdXRwdXQgb25seS4g
VGhlIHRpbWUgdGhlIHNlc3Npb24gc3RhcnRlZC4KCgwKBQQAAgYGEgN8AhsKDAoFBAACBgES
A3wcJgoMCgUEAAIGAxIDfCkqCgwKBQQAAgYIEgN9BjEKDwoIBAACBgicCAASA30HMAo9CgQE
AAIHEgaAAQKBATIaLSBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIHNlc3Npb24gZmluaXNo
ZWQuCgoNCgUEAAIHBhIEgAECGwoNCgUEAAIHARIEgAEcJAoNCgUEAAIHAxIEgAEnKAoNCgUE
AAIHCBIEgQEGMQoQCggEAAIHCJwIABIEgQEHMAp6CgQEAAIIEgSFAQI+GmwgT3B0aW9uYWwu
IFdoZXRoZXIgdGhlIHNlc3Npb24gaXMgcGlubmVkLCBwaW5uZWQgc2Vzc2lvbiB3aWxsIGJl
IGRpc3BsYXllZAogb24gdGhlIHRvcCBvZiB0aGUgc2Vzc2lvbiBsaXN0LgoKDQoFBAACCAUS
BIUBAgYKDQoFBAACCAESBIUBBxAKDQoFBAACCAMSBIUBExQKDQoFBAACCAgSBIUBFT0KEAoI
BAACCAicCAASBIUBFjwK+gEKBAQAAgkSBosBAowBMhrpASBPdXRwdXQgb25seS4gRnVsbCBy
ZXNvdXJjZSBuYW1lIG9mIGFuIGluLXByb2dyZXNzIEFzeW5jQXNzaXN0IG9wZXJhdGlvbiBm
b3IKIHRoaXMgc2Vzc2lvbiwgZS5nLgogYHByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVj
dGlvbnMvKi9lbmdpbmVzLyovc2Vzc2lvbnMvKi9vcGVyYXRpb25zLypgLgogU2V0IHdoZW4g
dGhlIG9wZXJhdGlvbiBzdGFydHMgYW5kIGNsZWFyZWQgd2hlbiBpdCBmaW5pc2hlcy4KCg0K
BQQAAgkFEgSLAQIICg0KBQQAAgkBEgSLAQkqCg0KBQQAAgkDEgSLAS0vCg0KBQQAAgkIEgSM
AQYxChAKCAQAAgkInAgAEgSMAQcwCi0KAgQBEgaQAQCZAQEaHyBEZWZpbmVzIGEgdXNlciBp
bnB1dGVkIHF1ZXJ5LgoKCwoDBAEBEgSQAQgNCiAKBAQBCAASBpIBApUBAxoQIFF1ZXJ5IGNv
bnRlbnQuCgoNCgUEAQgAARIEkgEIDwobCgQEAQIAEgSUAQQUGg0gUGxhaW4gdGV4dC4KCg0K
BQQBAgAFEgSUAQQKCg0KBQQBAgABEgSUAQsPCg0KBQQBAgADEgSUARITCjUKBAQBAgESBJgB
AkIaJyBPdXRwdXQgb25seS4gVW5pcXVlIElkIGZvciB0aGUgcXVlcnkuCgoNCgUEAQIBBRIE
mAECCAoNCgUEAQIBARIEmAEJEQoNCgUEAQIBAxIEmAEUFQoNCgUEAQIBCBIEmAEWQQoQCggE
AQIBCJwIABIEmAEXQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Session::Session ===
    # Fields for Session
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1.Session.State)
    # Field: user_pseudo_id Type: 9 ()
    # Field: turns Type: 11 (.google.cloud.discoveryengine.v1.Session.Turn)
    # Field: labels Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: is_pinned Type: 8 ()
    # Field: pending_async_assist_operation_id Type: 9 ()

# Enum: Session::State
our $Session_STATE_UNSPECIFIED = 0;
our $Session_IN_PROGRESS = 1;

# === Message: Google::Cloud::Discoveryengine::V1::Session::Query ===
    # Fields for Query
    # Field: text Type: 9 ()
    # Field: query_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Session - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/session.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Session;

    my $msg = Google::Cloud::Discoveryengine::V1::Session::Session->new({
        name => $name,
        display_name => $display_name,
        state => $state,
        user_pseudo_id => $user_pseudo_id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Session::Session->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/session.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Session::Session

External session proto definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/{project}/locations/global/collections/{collection}/engines/{engine}/sessions/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the session.

This field is used to identify the session in the UI.
By default, the display name is the first turn query text in the session.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::Session::State>)

The state of the session.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking users.

=item * C<< $msg->turns() >> / C<< $msg->turns($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Session::Session::Turn>)

Turns.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Optional. The labels for the session.
Can be set as filter in ListSessionsRequest.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the session started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the session finished.

=item * C<< $msg->is_pinned() >> / C<< $msg->is_pinned($value) >>

Type: C<Bool>

Optional. Whether the session is pinned, pinned session will be displayed
on the top of the session list.

=item * C<< $msg->pending_async_assist_operation_id() >> / C<< $msg->pending_async_assist_operation_id($value) >>

Type: C<String>

Output only. Full resource name of an in-progress AsyncAssist operation for
this session, e.g.
`projects/*/locations/*/collections/*/engines/*/sessions/*/operations/*`.
Set when the operation starts and cleared when it finishes.

=back

=head3 Enum: Session::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=back

=head2 Google::Cloud::Discoveryengine::V1::Session::Query

Defines a user inputed query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Plain text.

=item * C<< $msg->query_id() >> / C<< $msg->query_id($value) >>

Type: C<String>

Output only. Unique Id for the query.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Session::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
