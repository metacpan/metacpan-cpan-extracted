package Google::Cloud::Discoveryengine::V1::SchemaService;

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
    eval { require Google::Cloud::Discoveryengine::V1::Schema };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NjaGVtYV9zZXJ2aWNlLnByb3Rv
Eh9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3Vk
L2Rpc2NvdmVyeWVuZ2luZS92MS9zY2hlbWEucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9v
cGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8iVQoQR2V0U2NoZW1hUmVxdWVzdBJBCgRuYW1lGAEg
ASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TY2hlbWFSBG5h
bWUimgEKEkxpc3RTY2hlbWFzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50EhsKCXBhZ2Vf
c2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIoAB
ChNMaXN0U2NoZW1hc1Jlc3BvbnNlEkEKB3NjaGVtYXMYASADKAsyJy5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLlNjaGVtYVIHc2NoZW1hcxImCg9uZXh0X3BhZ2VfdG9rZW4Y
AiABKAlSDW5leHRQYWdlVG9rZW4ixwEKE0NyZWF0ZVNjaGVtYVJlcXVlc3QSSAoGcGFyZW50
GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3Rv
cmVSBnBhcmVudBJECgZzY2hlbWEYAiABKAsyJy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlNjaGVtYUID4EECUgZzY2hlbWESIAoJc2NoZW1hX2lkGAMgASgJQgPgQQJSCHNj
aGVtYUlkIoABChNVcGRhdGVTY2hlbWFSZXF1ZXN0EkQKBnNjaGVtYRgBIAEoCzInLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hQgPgQQJSBnNjaGVtYRIjCg1hbGxv
d19taXNzaW5nGAMgASgIUgxhbGxvd01pc3NpbmciWAoTRGVsZXRlU2NoZW1hUmVxdWVzdBJB
CgRuYW1lGAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9T
Y2hlbWFSBG5hbWUikAEKFENyZWF0ZVNjaGVtYU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUikAEK
FFVwZGF0ZVNjaGVtYU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUikAEKFERlbGV0ZVNjaGVtYU1l
dGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCnVwZGF0ZVRpbWUyrw4KDVNjaGVtYVNlcnZpY2US/AEKCUdldFNjaGVtYRIx
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuR2V0U2NoZW1hUmVxdWVzdBonLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hIpIBgtPkkwKEARI4L3YxL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn1aSBJG
L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3Rv
cmVzLyovc2NoZW1hcy8qfdpBBG5hbWUSjwIKC0xpc3RTY2hlbWFzEjMuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0U2NoZW1hc1JlcXVlc3QaNC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RTY2hlbWFzUmVzcG9uc2UilAGC0+STAoQBEjgvdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2NoZW1hc1pI
EkYvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0
YVN0b3Jlcy8qfS9zY2hlbWFz2kEGcGFyZW50EvwCCgxDcmVhdGVTY2hlbWESNC5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNyZWF0ZVNjaGVtYVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpYCgtPkkwKUASI4L3YxL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3NjaGVtYXM6BnNjaGVtYVpQIkYvdjEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8q
fS9zY2hlbWFzOgZzY2hlbWHaQRdwYXJlbnQsc2NoZW1hLHNjaGVtYV9pZMpBXgomZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWESNGdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuQ3JlYXRlU2NoZW1hTWV0YWRhdGES8AIKDFVwZGF0ZVNjaGVtYRI0Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXBkYXRlU2NoZW1hUmVxdWVzdBodLmdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iigKC0+STAqIBMj8vdjEve3NjaGVtYS5uYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn06BnNjaGVt
YVpXMk0vdjEve3NjaGVtYS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlv
bnMvKi9kYXRhU3RvcmVzLyovc2NoZW1hcy8qfToGc2NoZW1hykFeCiZnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLlNjaGVtYRI0Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5VcGRhdGVTY2hlbWFNZXRhZGF0YRLIAgoMRGVsZXRlU2NoZW1hEjQuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EZWxldGVTY2hlbWFSZXF1ZXN0Gh0uZ29vZ2xlLmxv
bmdydW5uaW5nLk9wZXJhdGlvbiLiAYLT5JMChAEqOC92MS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9zY2hlbWFzLyp9WkgqRi92MS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn3a
QQRuYW1lykFNChVnb29nbGUucHJvdG9idWYuRW1wdHkSNGdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuRGVsZXRlU2NoZW1hTWV0YWRhdGEazwHKQR5kaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVu
Z2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zl
cnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVChQIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxQhJTY2hlbWFTZXJ2aWNlUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9n
by9kaXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5n
aW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5l
LlYxygIfR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6
OkRpc2NvdmVyeUVuZ2luZTo6VjFKvDcKBxIFDgCBAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMU
ACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA2CgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoJCgIDBxID
GQApCggKAQgSAxsAPAoJCgIIJRIDGwA8CggKAQgSAxwAZAoJCgIICxIDHABkCggKAQgSAx0A
IgoJCgIIChIDHQAiCggKAQgSAx4AMwoJCgIICBIDHgAzCggKAQgSAx8APAoJCgIIARIDHwA8
CggKAQgSAyAALQoJCgIIJBIDIAAtCggKAQgSAyEAPAoJCgIIKRIDIQA8CggKAQgSAyIAOwoJ
CgIILRIDIgA7ClUKAgYAEgQlAHEBGkkgU2VydmljZSBmb3IgbWFuYWdpbmcgW1NjaGVtYV1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWFdcy4KCgoKAwYAARIDJQgV
CgoKAwYAAxIDJgJGCgwKBQYAA5kIEgMmAkYKCwoDBgADEgQnAipKCg0KBQYAA5oIEgQnAipK
CkgKBAYAAgASBC0CNQMaOiBHZXRzIGEgW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5TY2hlbWFdLgoKDAoFBgACAAESAy0GDwoMCgUGAAIAAhIDLRAgCgwKBQYA
AgADEgMtKzEKDQoFBgACAAQSBC4EMwYKEQoJBgACAASwyrwiEgQuBDMGCgwKBQYAAgAEEgM0
BDIKDwoIBgACAASbCAASAzQEMgpRCgQGAAIBEgQ4AkADGkMgR2V0cyBhIGxpc3Qgb2YgW1Nj
aGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWFdcy4KCgwKBQYA
AgEBEgM4BhEKDAoFBgACAQISAzgSJAoMCgUGAAIBAxIDOC9CCg0KBQYAAgEEEgQ5BD4GChEK
CQYAAgEEsMq8IhIEOQQ+BgoMCgUGAAIBBBIDPwQ0Cg8KCAYAAgEEmwgAEgM/BDQKSwoEBgAC
AhIEQwJRAxo9IENyZWF0ZXMgYSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlNjaGVtYV0uCgoMCgUGAAICARIDQwYSCgwKBQYAAgICEgNDEyYKDAoFBgACAgMS
A0MxTQoNCgUGAAICBBIERARLBgoRCgkGAAICBLDKvCISBEQESwYKDAoFBgACAgQSA0wERQoP
CggGAAICBJsIABIDTARFCg0KBQYAAgIEEgRNBFAGCg8KBwYAAgIEmQgSBE0EUAYKSwoEBgAC
AxIEVAJhAxo9IFVwZGF0ZXMgYSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlNjaGVtYV0uCgoMCgUGAAIDARIDVAYSCgwKBQYAAgMCEgNUEyYKDAoFBgACAwMS
A1QxTQoNCgUGAAIDBBIEVQRcBgoRCgkGAAIDBLDKvCISBFUEXAYKDQoFBgACAwQSBF0EYAYK
DwoHBgACAwSZCBIEXQRgBgpLCgQGAAIEEgRkAnADGj0gRGVsZXRlcyBhIFtTY2hlbWFdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hXS4KCgwKBQYAAgQBEgNkBhIK
DAoFBgACBAISA2QTJgoMCgUGAAIEAxIDZDFNCg0KBQYAAgQEEgRlBGoGChEKCQYAAgQEsMq8
IhIEZQRqBgoMCgUGAAIEBBIDawQyCg8KCAYAAgQEmwgAEgNrBDIKDQoFBgACBAQSBGwEbwYK
DwoHBgACBASZCBIEbARvBgp+CgIEABIEdgB/ARpyIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtT
Y2hlbWFTZXJ2aWNlLkdldFNjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5TY2hlbWFTZXJ2aWNlLkdldFNjaGVtYV0KIG1ldGhvZC4KCgoKAwQAARIDdggYCr8BCgQE
AAIAEgR5An4EGrABIFJlcXVpcmVkLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBz
Y2hlbWEsIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFf
c3RvcmV9L3NjaGVtYXMve3NjaGVtYX1gLgoKDAoFBAACAAUSA3kCCAoMCgUEAAIAARIDeQkN
CgwKBQQAAgADEgN5EBEKDQoFBAACAAgSBHkSfgMKDwoIBAACAAicCAASA3oEKgoPCgcEAAIA
CJ8IEgR7BH0FCoQBCgIEARIGhAEAnwEBGnYgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NjaGVt
YVNlcnZpY2UuTGlzdFNjaGVtYXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
U2NoZW1hU2VydmljZS5MaXN0U2NoZW1hc10KIG1ldGhvZC4KCgsKAwQBARIEhAEIGgqvAQoE
BAECABIGhwECjAEEGp4BIFJlcXVpcmVkLiBUaGUgcGFyZW50IGRhdGEgc3RvcmUgcmVzb3Vy
Y2UgbmFtZSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0
YV9zdG9yZX1gLgoKDQoFBAECAAUSBIcBAggKDQoFBAECAAESBIcBCQ8KDQoFBAECAAMSBIcB
EhMKDwoFBAECAAgSBocBFIwBAwoQCggEAQIACJwIABIEiAEEKgoRCgcEAQIACJ8IEgaJAQSL
AQUKsQIKBAQBAgESBJUBAhYaogIgVGhlIG1heGltdW0gbnVtYmVyIG9mIFtTY2hlbWFdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hXXMgdG8KIHJldHVybi4gVGhl
IHNlcnZpY2UgbWF5IHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCgogSWYgdW5zcGVj
aWZpZWQsIGF0IG1vc3QgMTAwCiBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlNjaGVtYV1zIGFyZSByZXR1cm5lZC4KCiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAx
MDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCBhcmUgc2V0IHRvIDEwMDAuCgoNCgUEAQIBBRIElQEC
BwoNCgUEAQIBARIElQEIEQoNCgUEAQIBAxIElQEUFQqDAwoEBAECAhIEngECGBr0AiBBIHBh
Z2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogW1NjaGVtYVNlcnZpY2UuTGlz
dFNjaGVtYXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hU2Vydmlj
ZS5MaXN0U2NoZW1hc10KIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vi
c2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMg
cHJvdmlkZWQgdG8KIFtTY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFzXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLlNjaGVtYVNlcnZpY2UuTGlzdFNjaGVtYXNdCiBtdXN0IG1h
dGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEAQICBRIE
ngECCAoNCgUEAQICARIEngEJEwoNCgUEAQICAxIEngEWFwqFAQoCBAISBqQBAK0BARp3IFJl
c3BvbnNlIG1lc3NhZ2UgZm9yCiBbU2NoZW1hU2VydmljZS5MaXN0U2NoZW1hc11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFzXQog
bWV0aG9kLgoKCwoDBAIBEgSkAQgbCkYKBAQCAgASBKYBAh4aOCBUaGUgW1NjaGVtYV1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWFdcy4KCg0KBQQCAgAEEgSmAQIK
Cg0KBQQCAgAGEgSmAQsRCg0KBQQCAgABEgSmARIZCg0KBQQCAgADEgSmARwdCuIBCgQEAgIB
EgSsAQIdGtMBIEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcwogW0xpc3RTY2hlbWFzUmVx
dWVzdC5wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RT
Y2hlbWFzUmVxdWVzdC5wYWdlX3Rva2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4g
SWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFn
ZXMuCgoNCgUEAgIBBRIErAECCAoNCgUEAgIBARIErAEJGAoNCgUEAgIBAxIErAEbHAqGAQoC
BAMSBrIBAMgBARp4IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTY2hlbWFTZXJ2aWNlLkNyZWF0
ZVNjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWFTZXJ2aWNl
LkNyZWF0ZVNjaGVtYV0KIG1ldGhvZC4KCgsKAwQDARIEsgEIGwqvAQoEBAMCABIGtQECugEE
Gp4BIFJlcXVpcmVkLiBUaGUgcGFyZW50IGRhdGEgc3RvcmUgcmVzb3VyY2UgbmFtZSwgaW4g
dGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX1gLgoK
DQoFBAMCAAUSBLUBAggKDQoFBAMCAAESBLUBCQ8KDQoFBAMCAAMSBLUBEhMKDwoFBAMCAAgS
BrUBFLoBAwoQCggEAwIACJwIABIEtgEEKgoRCgcEAwIACJ8IEga3AQS5AQUKWQoEBAMCARIE
vQECPRpLIFJlcXVpcmVkLiBUaGUgW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5TY2hlbWFdIHRvIGNyZWF0ZS4KCg0KBQQDAgEGEgS9AQIICg0KBQQDAgEBEgS9
AQkPCg0KBQQDAgEDEgS9ARITCg0KBQQDAgEIEgS9ARQ8ChAKCAQDAgEInAgAEgS9ARU7CsoC
CgQEAwICEgTHAQJAGrsCIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtTY2hl
bWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hXSwgd2hpY2ggYmVj
b21lcyB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUKIFtTY2hlbWEubmFtZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TY2hlbWEubmFtZV0uCgogVGhpcyBmaWVsZCBz
aG91bGQgY29uZm9ybSB0bwogW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYub3JnL2h0
bWwvcmZjMTAzNCkgc3RhbmRhcmQgd2l0aCBhIGxlbmd0aAogbGltaXQgb2YgNjMgY2hhcmFj
dGVycy4KCg0KBQQDAgIFEgTHAQIICg0KBQQDAgIBEgTHAQkSCg0KBQQDAgIDEgTHARUWCg0K
BQQDAgIIEgTHARc/ChAKCAQDAgIInAgAEgTHARg+CoYBCgIEBBIGzQEA1QEBGnggUmVxdWVz
dCBtZXNzYWdlIGZvcgogW1NjaGVtYVNlcnZpY2UuVXBkYXRlU2NoZW1hXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNjaGVtYVNlcnZpY2UuVXBkYXRlU2NoZW1hXQogbWV0
aG9kLgoKCwoDBAQBEgTNAQgbClkKBAQEAgASBM8BAj0aSyBSZXF1aXJlZC4gVGhlIFtTY2hl
bWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2NoZW1hXSB0byB1cGRhdGUu
CgoNCgUEBAIABhIEzwECCAoNCgUEBAIAARIEzwEJDwoNCgUEBAIAAxIEzwESEwoNCgUEBAIA
CBIEzwEUPAoQCggEBAIACJwIABIEzwEVOwrZAQoEBAQCARIE1AECGRrKASBJZiBzZXQgdG8g
dHJ1ZSwgYW5kIHRoZSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LlNjaGVtYV0gaXMKIG5vdCBmb3VuZCwgYSBuZXcgW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5TY2hlbWFdIGlzCiBjcmVhdGVkLiBJbiB0aGlzIHNpdHVhdGlv
biwgYHVwZGF0ZV9tYXNrYCBpcyBpZ25vcmVkLgoKDQoFBAQCAQUSBNQBAgYKDQoFBAQCAQES
BNQBBxQKDQoFBAQCAQMSBNQBFxgKhgEKAgQFEgbaAQDjAQEaeCBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbU2NoZW1hU2VydmljZS5EZWxldGVTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuU2NoZW1hU2VydmljZS5EZWxldGVTY2hlbWFdCiBtZXRob2QuCgoLCgME
BQESBNoBCBsKwQEKBAQFAgASBt0BAuIBBBqwASBSZXF1aXJlZC4gVGhlIGZ1bGwgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgc2NoZW1hLCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9k
YXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zY2hlbWFzL3tzY2hlbWF9YC4KCg0KBQQFAgAFEgTd
AQIICg0KBQQFAgABEgTdAQkNCg0KBQQFAgADEgTdARARCg8KBQQFAgAIEgbdARLiAQMKEAoI
BAUCAAicCAASBN4BBCoKEQoHBAUCAAifCBIG3wEE4QEFCi8KAgQGEgbmAQDtAQEaISBNZXRh
ZGF0YSBmb3IgQ3JlYXRlIFNjaGVtYSBMUk8uCgoLCgMEBgESBOYBCBwKJgoEBAYCABIE6AEC
LBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQGAgAGEgToAQIbCg0KBQQGAgABEgTo
ARwnCg0KBQQGAgADEgToASorCmQKBAQGAgESBOwBAiwaViBPcGVyYXRpb24gbGFzdCB1cGRh
dGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBm
aW5pc2ggdGltZS4KCg0KBQQGAgEGEgTsAQIbCg0KBQQGAgEBEgTsARwnCg0KBQQGAgEDEgTs
ASorCi4KAgQHEgbwAQD3AQEaICBNZXRhZGF0YSBmb3IgVXBkYXRlU2NoZW1hIExSTy4KCgsK
AwQHARIE8AEIHAomCgQEBwIAEgTyAQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoF
BAcCAAYSBPIBAhsKDQoFBAcCAAESBPIBHCcKDQoFBAcCAAMSBPIBKisKZAoEBAcCARIE9gEC
LBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRv
bmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAcCAQYSBPYBAhsKDQoF
BAcCAQESBPYBHCcKDQoFBAcCAQMSBPYBKisKLgoCBAgSBvoBAIECARogIE1ldGFkYXRhIGZv
ciBEZWxldGVTY2hlbWEgTFJPLgoKCwoDBAgBEgT6AQgcCiYKBAQIAgASBPwBAiwaGCBPcGVy
YXRpb24gY3JlYXRlIHRpbWUuCgoNCgUECAIABhIE/AECGwoNCgUECAIAARIE/AEcJwoNCgUE
CAIAAxIE/AEqKwpkCgQECAIBEgSAAgIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUu
IElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRp
bWUuCgoNCgUECAIBBhIEgAICGwoNCgUECAIBARIEgAIcJwoNCgUECAIBAxIEgAIqK2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest ===
    # Fields for GetSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasRequest ===
    # Fields for ListSchemasRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasResponse ===
    # Fields for ListSchemasResponse
    # Field: schemas Type: 11 (.google.cloud.discoveryengine.v1.Schema)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaRequest ===
    # Fields for CreateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.cloud.discoveryengine.v1.Schema)
    # Field: schema_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaRequest ===
    # Fields for UpdateSchemaRequest
    # Field: schema Type: 11 (.google.cloud.discoveryengine.v1.Schema)
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaRequest ===
    # Fields for DeleteSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaMetadata ===
    # Fields for CreateSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaMetadata ===
    # Fields for UpdateSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaMetadata ===
    # Fields for DeleteSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1::SchemaService::SchemaServiceClient ===
package Google::Cloud::Discoveryengine::V1::SchemaService::SchemaServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::SchemaService::SchemaServiceClient

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
        ? Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SchemaService',
        method         => 'GetSchema',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Schema::Schema',
    });
}

sub list_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SchemaService',
        method         => 'ListSchemas',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasResponse',
    });
}

sub create_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SchemaService',
        method         => 'CreateSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SchemaService',
        method         => 'UpdateSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SchemaService',
        method         => 'DeleteSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::SchemaService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/schema_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::SchemaService;

    my $msg = Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/schema_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest

Request message for
[SchemaService.GetSchema][google.cloud.discoveryengine.v1.SchemaService.GetSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasRequest

Request message for
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1.SchemaService.ListSchemas]
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

The maximum number of [Schema][google.cloud.discoveryengine.v1.Schema]s to
return. The service may return fewer than this value.

If unspecified, at most 100
[Schema][google.cloud.discoveryengine.v1.Schema]s are returned.

The maximum value is 1000; values above 1000 are set to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1.SchemaService.ListSchemas]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1.SchemaService.ListSchemas]
must match the call that provided the page token.

=back

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasResponse

Response message for
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1.SchemaService.ListSchemas]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schemas() >> / C<< $msg->schemas($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Schema::Schema>)

The [Schema][google.cloud.discoveryengine.v1.Schema]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSchemasRequest.page_token][google.cloud.discoveryengine.v1.ListSchemasRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaRequest

Request message for
[SchemaService.CreateSchema][google.cloud.discoveryengine.v1.SchemaService.CreateSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Schema::Schema>)

Required. The [Schema][google.cloud.discoveryengine.v1.Schema] to create.

=item * C<< $msg->schema_id() >> / C<< $msg->schema_id($value) >>

Type: C<String>

Required. The ID to use for the
[Schema][google.cloud.discoveryengine.v1.Schema], which becomes the final
component of the
[Schema.name][google.cloud.discoveryengine.v1.Schema.name].

This field should conform to
[RFC-1034](https://tools.ietf.org/html/rfc1034) standard with a length
limit of 63 characters.

=back

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaRequest

Request message for
[SchemaService.UpdateSchema][google.cloud.discoveryengine.v1.SchemaService.UpdateSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Schema::Schema>)

Required. The [Schema][google.cloud.discoveryengine.v1.Schema] to update.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to true, and the [Schema][google.cloud.discoveryengine.v1.Schema] is
not found, a new [Schema][google.cloud.discoveryengine.v1.Schema] is
created. In this situation, `update_mask` is ignored.

=back

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaRequest

Request message for
[SchemaService.DeleteSchema][google.cloud.discoveryengine.v1.SchemaService.DeleteSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaMetadata

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

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaMetadata

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

=head2 Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaMetadata

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::SchemaService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
