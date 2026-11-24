package Google::Cloud::Discoveryengine::V1beta::SchemaService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Schema };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zY2hlbWFfc2VydmljZS5w
cm90bxIjZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjBnb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zY2hlbWEucHJvdG8aI2dvb2dsZS9s
b25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iVQoQR2V0U2NoZW1hUmVxdWVz
dBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9TY2hlbWFSBG5hbWUimgEKEkxpc3RTY2hlbWFzUmVxdWVzdBJICgZwYXJlbnQYASABKAlC
MOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFy
ZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJ
cGFnZVRva2VuIoQBChNMaXN0U2NoZW1hc1Jlc3BvbnNlEkUKB3NjaGVtYXMYASADKAsyKy5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFSB3NjaGVtYXMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIssBChNDcmVhdGVTY2hlbWFS
ZXF1ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xl
YXBpcy5jb20vRGF0YVN0b3JlUgZwYXJlbnQSSAoGc2NoZW1hGAIgASgLMisuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2NoZW1hQgPgQQJSBnNjaGVtYRIgCglzY2hl
bWFfaWQYAyABKAlCA+BBAlIIc2NoZW1hSWQihAEKE1VwZGF0ZVNjaGVtYVJlcXVlc3QSSAoG
c2NoZW1hGAEgASgLMisuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2No
ZW1hQgPgQQJSBnNjaGVtYRIjCg1hbGxvd19taXNzaW5nGAMgASgIUgxhbGxvd01pc3Npbmci
WAoTRGVsZXRlU2NoZW1hUmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRpc2NvdmVy
eWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TY2hlbWFSBG5hbWUikAEKFENyZWF0ZVNjaGVtYU1l
dGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCnVwZGF0ZVRpbWUikAEKFFVwZGF0ZVNjaGVtYU1ldGFkYXRhEjsKC2NyZWF0
ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7
Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0
ZVRpbWUikAEKFERlbGV0ZVNjaGVtYU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUyhw8KDVNjaGVt
YVNlcnZpY2USjAIKCUdldFNjaGVtYRI1Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkdldFNjaGVtYVJlcXVlc3QaKy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5TY2hlbWEimgGC0+STAowBEjwvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn1aTBJKL3YxYmV0YS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMv
Kn3aQQRuYW1lEp8CCgtMaXN0U2NoZW1hcxI3Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkxpc3RTY2hlbWFzUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkxpc3RTY2hlbWFzUmVzcG9uc2UinAGC0+STAowBEjwvdjFiZXRhL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3NjaGVtYXNaTBJK
L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9k
YXRhU3RvcmVzLyp9L3NjaGVtYXPaQQZwYXJlbnQSkAMKDENyZWF0ZVNjaGVtYRI4Lmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0ZVNjaGVtYVJlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqYCgtPkkwKcASI8L3YxYmV0YS97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qfS9zY2hlbWFzOgZzY2hlbWFa
VCJKL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMv
Ki9kYXRhU3RvcmVzLyp9L3NjaGVtYXM6BnNjaGVtYdpBF3BhcmVudCxzY2hlbWEsc2NoZW1h
X2lkykFmCipnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWESOGdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0ZVNjaGVtYU1ldGFkYXRh
EoQDCgxVcGRhdGVTY2hlbWESOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5VcGRhdGVTY2hlbWFSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKa
AoLT5JMCqgEyQy92MWJldGEve3NjaGVtYS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn06BnNjaGVtYVpbMlEvdjFiZXRhL3tzY2hlbWEubmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3Nj
aGVtYXMvKn06BnNjaGVtYcpBZgoqZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuU2NoZW1hEjhnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5VcGRhdGVT
Y2hlbWFNZXRhZGF0YRLYAgoMRGVsZXRlU2NoZW1hEjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuRGVsZXRlU2NoZW1hUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb24i7gGC0+STAowBKjwvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn1aTCpKL3YxYmV0YS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn3a
QQRuYW1lykFRChVnb29nbGUucHJvdG9idWYuRW1wdHkSOGdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkRlbGV0ZVNjaGVtYU1ldGFkYXRhGs8BykEeZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zl
cnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlz
Y292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQpkCCidjb20uZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGFCElNjaGVtYVNlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29n
bGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7
ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlz
Y292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFi
ZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKoDgKBxIFDgCE
AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA6CgkKAgMF
EgMXAC0KCQoCAwYSAxgAJQoJCgIDBxIDGQApCggKAQgSAxsAQAoJCgIIJRIDGwBACggKAQgS
AxwAaAoJCgIICxIDHABoCggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4AMwoJCgIICBID
HgAzCggKAQgSAx8AQAoJCgIIARIDHwBACggKAQgSAyAALQoJCgIIJBIDIAAtCggKAQgSAyEA
QAoJCgIIKRIDIQBACggKAQgSAyIAPwoJCgIILRIDIgA/ClkKAgYAEgQlAHEBGk0gU2Vydmlj
ZSBmb3IgbWFuYWdpbmcgW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuU2NoZW1hXXMuCgoKCgMGAAESAyUIFQoKCgMGAAMSAyYCRgoMCgUGAAOZCBIDJgJG
CgsKAwYAAxIEJwIqSgoNCgUGAAOaCBIEJwIqSgpMCgQGAAIAEgQtAjUDGj4gR2V0cyBhIFtT
Y2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNjaGVtYV0uCgoM
CgUGAAIAARIDLQYPCgwKBQYAAgACEgMtECAKDAoFBgACAAMSAy0rMQoNCgUGAAIABBIELgQz
BgoRCgkGAAIABLDKvCISBC4EMwYKDAoFBgACAAQSAzQEMgoPCggGAAIABJsIABIDNAQyClUK
BAYAAgESBDgCQAMaRyBHZXRzIGEgbGlzdCBvZiBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFdcy4KCgwKBQYAAgEBEgM4BhEKDAoFBgACAQIS
AzgSJAoMCgUGAAIBAxIDOC9CCg0KBQYAAgEEEgQ5BD4GChEKCQYAAgEEsMq8IhIEOQQ+BgoM
CgUGAAIBBBIDPwQ0Cg8KCAYAAgEEmwgAEgM/BDQKTwoEBgACAhIEQwJRAxpBIENyZWF0ZXMg
YSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFd
LgoKDAoFBgACAgESA0MGEgoMCgUGAAICAhIDQxMmCgwKBQYAAgIDEgNDMU0KDQoFBgACAgQS
BEQESwYKEQoJBgACAgSwyrwiEgREBEsGCgwKBQYAAgIEEgNMBEUKDwoIBgACAgSbCAASA0wE
RQoNCgUGAAICBBIETQRQBgoPCgcGAAICBJkIEgRNBFAGCk8KBAYAAgMSBFQCYQMaQSBVcGRh
dGVzIGEgW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2No
ZW1hXS4KCgwKBQYAAgMBEgNUBhIKDAoFBgACAwISA1QTJgoMCgUGAAIDAxIDVDFNCg0KBQYA
AgMEEgRVBFwGChEKCQYAAgMEsMq8IhIEVQRcBgoNCgUGAAIDBBIEXQRgBgoPCgcGAAIDBJkI
EgRdBGAGCk8KBAYAAgQSBGQCcAMaQSBEZWxldGVzIGEgW1NjaGVtYV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2NoZW1hXS4KCgwKBQYAAgQBEgNkBhIKDAoFBgAC
BAISA2QTJgoMCgUGAAIEAxIDZDFNCg0KBQYAAgQEEgRlBGoGChEKCQYAAgQEsMq8IhIEZQRq
BgoMCgUGAAIEBBIDawQyCg8KCAYAAgQEmwgAEgNrBDIKDQoFBgACBAQSBGwEbwYKDwoHBgAC
BASZCBIEbARvBgqCAQoCBAASBHYAfwEadiBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2NoZW1h
U2VydmljZS5HZXRTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlNjaGVtYVNlcnZpY2UuR2V0U2NoZW1hXQogbWV0aG9kLgoKCgoDBAABEgN2CBgKvwEKBAQA
AgASBHkCfgQasAEgUmVxdWlyZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHNj
aGVtYSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9z
dG9yZX0vc2NoZW1hcy97c2NoZW1hfWAuCgoMCgUEAAIABRIDeQIICgwKBQQAAgABEgN5CQ0K
DAoFBAACAAMSA3kQEQoNCgUEAAIACBIEeRJ+AwoPCggEAAIACJwIABIDegQqCg8KBwQAAgAI
nwgSBHsEfQUKiAEKAgQBEgaEAQCfAQEaeiBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2NoZW1h
U2VydmljZS5MaXN0U2NoZW1hc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuU2NoZW1hU2VydmljZS5MaXN0U2NoZW1hc10KIG1ldGhvZC4KCgsKAwQBARIEhAEIGgqv
AQoEBAECABIGhwECjAEEGp4BIFJlcXVpcmVkLiBUaGUgcGFyZW50IGRhdGEgc3RvcmUgcmVz
b3VyY2UgbmFtZSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97
ZGF0YV9zdG9yZX1gLgoKDQoFBAECAAUSBIcBAggKDQoFBAECAAESBIcBCQ8KDQoFBAECAAMS
BIcBEhMKDwoFBAECAAgSBocBFIwBAwoQCggEAQIACJwIABIEiAEEKgoRCgcEAQIACJ8IEgaJ
AQSLAQUKuQIKBAQBAgESBJUBAhYaqgIgVGhlIG1heGltdW0gbnVtYmVyIG9mIFtTY2hlbWFd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNjaGVtYV1zCiB0byByZXR1
cm4uIFRoZSBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLgoKIElm
IHVuc3BlY2lmaWVkLCBhdCBtb3N0IDEwMAogW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuU2NoZW1hXXMgYXJlIHJldHVybmVkLgoKIFRoZSBtYXhpbXVt
IHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIGFyZSBzZXQgdG8gMTAwMC4KCg0K
BQQBAgEFEgSVAQIHCg0KBQQBAgEBEgSVAQgRCg0KBQQBAgEDEgSVARQVCosDCgQEAQICEgSe
AQIYGvwCIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBbU2NoZW1h
U2VydmljZS5MaXN0U2NoZW1hc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuU2NoZW1hU2VydmljZS5MaXN0U2NoZW1hc10KIGNhbGwuIFByb3ZpZGUgdGhpcyB0byBy
ZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90
aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8KIFtTY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFz
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFTZXJ2aWNlLkxp
c3RTY2hlbWFzXQogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdl
IHRva2VuLgoKDQoFBAECAgUSBJ4BAggKDQoFBAECAgESBJ4BCRMKDQoFBAECAgMSBJ4BFhcK
iQEKAgQCEgakAQCtAQEaeyBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1NjaGVtYVNlcnZpY2Uu
TGlzdFNjaGVtYXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNjaGVt
YVNlcnZpY2UuTGlzdFNjaGVtYXNdCiBtZXRob2QuCgoLCgMEAgESBKQBCBsKSgoEBAICABIE
pgECHho8IFRoZSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TY2hlbWFdcy4KCg0KBQQCAgAEEgSmAQIKCg0KBQQCAgAGEgSmAQsRCg0KBQQCAgABEgSm
ARIZCg0KBQQCAgADEgSmARwdCuYBCgQEAgIBEgSsAQIdGtcBIEEgdG9rZW4gdGhhdCBjYW4g
YmUgc2VudCBhcwogW0xpc3RTY2hlbWFzUmVxdWVzdC5wYWdlX3Rva2VuXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0U2NoZW1hc1JlcXVlc3QucGFnZV90b2tl
bl0KIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgb21pdHRl
ZCwgdGhlcmUgYXJlIG5vCiBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAICAQUSBKwBAggKDQoF
BAICAQESBKwBCRgKDQoFBAICAQMSBKwBGxwKigEKAgQDEgayAQDJAQEafCBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbU2NoZW1hU2VydmljZS5DcmVhdGVTY2hlbWFdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLlNjaGVtYVNlcnZpY2UuQ3JlYXRlU2NoZW1hXQogbWV0
aG9kLgoKCwoDBAMBEgSyAQgbCq8BCgQEAwIAEga1AQK6AQQangEgUmVxdWlyZWQuIFRoZSBw
YXJlbnQgZGF0YSBzdG9yZSByZXNvdXJjZSBuYW1lLCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xs
ZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfWAuCgoNCgUEAwIABRIEtQECCAoNCgUE
AwIAARIEtQEJDwoNCgUEAwIAAxIEtQESEwoPCgUEAwIACBIGtQEUugEDChAKCAQDAgAInAgA
EgS2AQQqChEKBwQDAgAInwgSBrcBBLkBBQpeCgQEAwIBEgS+AQI9GlAgUmVxdWlyZWQuIFRo
ZSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFd
IHRvCiBjcmVhdGUuCgoNCgUEAwIBBhIEvgECCAoNCgUEAwIBARIEvgEJDwoNCgUEAwIBAxIE
vgESEwoNCgUEAwIBCBIEvgEUPAoQCggEAwIBCJwIABIEvgEVOwrSAgoEBAMCAhIEyAECQBrD
AiBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlCiBbU2NoZW1hXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFdLCB3aGljaCBiZWNvbWVzIHRoZQog
ZmluYWwgY29tcG9uZW50IG9mIHRoZQogW1NjaGVtYS5uYW1lXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWEubmFtZV0uCgogVGhpcyBmaWVsZCBzaG91bGQg
Y29uZm9ybSB0bwogW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYub3JnL2h0bWwvcmZj
MTAzNCkgc3RhbmRhcmQgd2l0aCBhIGxlbmd0aAogbGltaXQgb2YgNjMgY2hhcmFjdGVycy4K
Cg0KBQQDAgIFEgTIAQIICg0KBQQDAgIBEgTIAQkSCg0KBQQDAgIDEgTIARUWCg0KBQQDAgII
EgTIARc/ChAKCAQDAgIInAgAEgTIARg+CooBCgIEBBIGzgEA2AEBGnwgUmVxdWVzdCBtZXNz
YWdlIGZvcgogW1NjaGVtYVNlcnZpY2UuVXBkYXRlU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFTZXJ2aWNlLlVwZGF0ZVNjaGVtYV0KIG1ldGhv
ZC4KCgsKAwQEARIEzgEIGwpeCgQEBAIAEgTRAQI9GlAgUmVxdWlyZWQuIFRoZSBbU2NoZW1h
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFdIHRvCiB1cGRh
dGUuCgoNCgUEBAIABhIE0QECCAoNCgUEBAIAARIE0QEJDwoNCgUEBAIAAxIE0QESEwoNCgUE
BAIACBIE0QEUPAoQCggEBAIACJwIABIE0QEVOwriAQoEBAQCARIE1wECGRrTASBJZiBzZXQg
dG8gdHJ1ZSwgYW5kIHRoZQogW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuU2NoZW1hXSBpcyBub3QgZm91bmQsIGEgbmV3CiBbU2NoZW1hXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TY2hlbWFdIGlzIGNyZWF0ZWQuIEluIHRo
aXMKIHNpdHVhdGlvbiwgYHVwZGF0ZV9tYXNrYCBpcyBpZ25vcmVkLgoKDQoFBAQCAQUSBNcB
AgYKDQoFBAQCAQESBNcBBxQKDQoFBAQCAQMSBNcBFxgKigEKAgQFEgbdAQDmAQEafCBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbU2NoZW1hU2VydmljZS5EZWxldGVTY2hlbWFdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNjaGVtYVNlcnZpY2UuRGVsZXRlU2NoZW1h
XQogbWV0aG9kLgoKCwoDBAUBEgTdAQgbCsEBCgQEBQIAEgbgAQLlAQQasAEgUmVxdWlyZWQu
IFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHNjaGVtYSwgaW4gdGhlIGZvcm1hdCBv
ZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9u
cy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2NoZW1hcy97c2NoZW1h
fWAuCgoNCgUEBQIABRIE4AECCAoNCgUEBQIAARIE4AEJDQoNCgUEBQIAAxIE4AEQEQoPCgUE
BQIACBIG4AES5QEDChAKCAQFAgAInAgAEgThAQQqChEKBwQFAgAInwgSBuIBBOQBBQovCgIE
BhIG6QEA8AEBGiEgTWV0YWRhdGEgZm9yIENyZWF0ZSBTY2hlbWEgTFJPLgoKCwoDBAYBEgTp
AQgcCiYKBAQGAgASBOsBAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEBgIABhIE
6wECGwoNCgUEBgIAARIE6wEcJwoNCgUEBgIAAxIE6wEqKwpkCgQEBgIBEgTvAQIsGlYgT3Bl
cmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhp
cyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoNCgUEBgIBBhIE7wECGwoNCgUEBgIBARIE
7wEcJwoNCgUEBgIBAxIE7wEqKwouCgIEBxIG8wEA+gEBGiAgTWV0YWRhdGEgZm9yIFVwZGF0
ZVNjaGVtYSBMUk8uCgoLCgMEBwESBPMBCBwKJgoEBAcCABIE9QECLBoYIE9wZXJhdGlvbiBj
cmVhdGUgdGltZS4KCg0KBQQHAgAGEgT1AQIbCg0KBQQHAgABEgT1ARwnCg0KBQQHAgADEgT1
ASorCmQKBAQHAgESBPkBAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhl
IG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0K
BQQHAgEGEgT5AQIbCg0KBQQHAgEBEgT5ARwnCg0KBQQHAgEDEgT5ASorCi4KAgQIEgb9AQCE
AgEaICBNZXRhZGF0YSBmb3IgRGVsZXRlU2NoZW1hIExSTy4KCgsKAwQIARIE/QEIHAomCgQE
CAIAEgT/AQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAgCAAYSBP8BAhsKDQoF
BAgCAAESBP8BHCcKDQoFBAgCAAMSBP8BKisKZAoEBAgCARIEgwICLBpWIE9wZXJhdGlvbiBs
YXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxz
byB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAgCAQYSBIMCAhsKDQoFBAgCAQESBIMCHCcKDQoF
BAgCAQMSBIMCKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest ===
    # Fields for GetSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::ListSchemasRequest ===
    # Fields for ListSchemasRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::ListSchemasResponse ===
    # Fields for ListSchemasResponse
    # Field: schemas Type: 11 (.google.cloud.discoveryengine.v1beta.Schema)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::CreateSchemaRequest ===
    # Fields for CreateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.cloud.discoveryengine.v1beta.Schema)
    # Field: schema_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::UpdateSchemaRequest ===
    # Fields for UpdateSchemaRequest
    # Field: schema Type: 11 (.google.cloud.discoveryengine.v1beta.Schema)
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::DeleteSchemaRequest ===
    # Fields for DeleteSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::CreateSchemaMetadata ===
    # Fields for CreateSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::UpdateSchemaMetadata ===
    # Fields for UpdateSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::SchemaService::DeleteSchemaMetadata ===
    # Fields for DeleteSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::SchemaService::SchemaServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::SchemaService::SchemaServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::SchemaService::SchemaServiceClient

Client stub representing the remote C<SchemaService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SchemaService',
        method         => 'GetSchema',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Schema::Schema',
    });
}

sub list_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SchemaService::ListSchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SchemaService',
        method         => 'ListSchemas',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SchemaService::ListSchemasResponse',
    });
}

sub create_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SchemaService::CreateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SchemaService',
        method         => 'CreateSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SchemaService::UpdateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SchemaService',
        method         => 'UpdateSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SchemaService::DeleteSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SchemaService',
        method         => 'DeleteSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SchemaService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/schema_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SchemaService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/schema_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest

Request message for
[SchemaService.GetSchema][google.cloud.discoveryengine.v1beta.SchemaService.GetSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::ListSchemasRequest

Request message for
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1beta.SchemaService.ListSchemas]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of [Schema][google.cloud.discoveryengine.v1beta.Schema]s
to return. The service may return fewer than this value.

If unspecified, at most 100
[Schema][google.cloud.discoveryengine.v1beta.Schema]s are returned.

The maximum value is 1000; values above 1000 are set to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1beta.SchemaService.ListSchemas]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1beta.SchemaService.ListSchemas]
must match the call that provided the page token.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::ListSchemasResponse

Response message for
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1beta.SchemaService.ListSchemas]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schemas() >> / C<< $msg->schemas($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Schema::Schema>)

The [Schema][google.cloud.discoveryengine.v1beta.Schema]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSchemasRequest.page_token][google.cloud.discoveryengine.v1beta.ListSchemasRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::CreateSchemaRequest

Request message for
[SchemaService.CreateSchema][google.cloud.discoveryengine.v1beta.SchemaService.CreateSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Schema::Schema>)

Required. The [Schema][google.cloud.discoveryengine.v1beta.Schema] to
create.

=item * C<< $msg->schema_id() >> / C<< $msg->schema_id($value) >>

Type: C<String>

Required. The ID to use for the
[Schema][google.cloud.discoveryengine.v1beta.Schema], which becomes the
final component of the
[Schema.name][google.cloud.discoveryengine.v1beta.Schema.name].

This field should conform to
[RFC-1034](https://tools.ietf.org/html/rfc1034) standard with a length
limit of 63 characters.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::UpdateSchemaRequest

Request message for
[SchemaService.UpdateSchema][google.cloud.discoveryengine.v1beta.SchemaService.UpdateSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Schema::Schema>)

Required. The [Schema][google.cloud.discoveryengine.v1beta.Schema] to
update.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to true, and the
[Schema][google.cloud.discoveryengine.v1beta.Schema] is not found, a new
[Schema][google.cloud.discoveryengine.v1beta.Schema] is created. In this
situation, `update_mask` is ignored.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::DeleteSchemaRequest

Request message for
[SchemaService.DeleteSchema][google.cloud.discoveryengine.v1beta.SchemaService.DeleteSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::CreateSchemaMetadata

Metadata for Create Schema LRO.

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

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::UpdateSchemaMetadata

Metadata for UpdateSchema LRO.

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

=head2 Google::Cloud::Discoveryengine::V1beta::SchemaService::DeleteSchemaMetadata

Metadata for DeleteSchema LRO.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SchemaService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
