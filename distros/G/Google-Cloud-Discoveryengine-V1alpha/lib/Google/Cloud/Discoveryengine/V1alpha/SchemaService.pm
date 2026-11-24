package Google::Cloud::Discoveryengine::V1alpha::SchemaService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Schema };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2NoZW1hX3NlcnZpY2Uu
cHJvdG8SJGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYRocZ29vZ2xlL2Fw
aS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMWdv
b2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBoYS9zY2hlbWEucHJvdG8aI2dvb2ds
ZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iVQoQR2V0U2NoZW1hUmVx
dWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9TY2hlbWFSBG5hbWUimgEKEkxpc3RTY2hlbWFzUmVxdWVzdBJICgZwYXJlbnQYASAB
KAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIG
cGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEo
CVIJcGFnZVRva2VuIoUBChNMaXN0U2NoZW1hc1Jlc3BvbnNlEkYKB3NjaGVtYXMYASADKAsy
LC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2NoZW1hUgdzY2hlbWFz
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLMAQoTQ3JlYXRlU2No
ZW1hUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdv
b2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50EkkKBnNjaGVtYRgCIAEoCzIsLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFCA+BBAlIGc2NoZW1hEiAK
CXNjaGVtYV9pZBgDIAEoCUID4EECUghzY2hlbWFJZCKFAQoTVXBkYXRlU2NoZW1hUmVxdWVz
dBJJCgZzY2hlbWEYASABKAsyLC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuU2NoZW1hQgPgQQJSBnNjaGVtYRIjCg1hbGxvd19taXNzaW5nGAMgASgIUgxhbGxvd01p
c3NpbmciWAoTRGVsZXRlU2NoZW1hUmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRp
c2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TY2hlbWFSBG5hbWUikAEKFENyZWF0ZVNj
aGVtYU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUikAEKFFVwZGF0ZVNjaGVtYU1ldGFkYXRhEjsK
C2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRl
VGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
CnVwZGF0ZVRpbWUikAEKFERlbGV0ZVNjaGVtYU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUynw4K
DVNjaGVtYVNlcnZpY2USkAIKCUdldFNjaGVtYRI2Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5HZXRTY2hlbWFSZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlNjaGVtYSKcAYLT5JMCjgESPS92MWFscGhhL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn1aTRJLL3YxYWxwaGEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMv
Ki9zY2hlbWFzLyp92kEEbmFtZRKjAgoLTGlzdFNjaGVtYXMSOC5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdFNjaGVtYXNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RTY2hlbWFzUmVzcG9uc2UingGC0+STAo4B
Ej0vdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8q
fS9zY2hlbWFzWk0SSy92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
b2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2NoZW1hc9pBBnBhcmVudBKVAwoMQ3JlYXRl
U2NoZW1hEjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNyZWF0ZVNj
aGVtYVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqoCgtPkkwKeASI9
L3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0v
c2NoZW1hczoGc2NoZW1hWlUiSy92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2NoZW1hczoGc2NoZW1h2kEXcGFy
ZW50LHNjaGVtYSxzY2hlbWFfaWTKQWgKK2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5TY2hlbWESOWdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5D
cmVhdGVTY2hlbWFNZXRhZGF0YRKJAwoMVXBkYXRlU2NoZW1hEjkuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlVwZGF0ZVNjaGVtYVJlcXVlc3QaHS5nb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uIp4CgtPkkwKsATJEL3YxYWxwaGEve3NjaGVtYS5uYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn06BnNjaGVtYVpc
MlIvdjFhbHBoYS97c2NoZW1hLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2RhdGFTdG9yZXMvKi9zY2hlbWFzLyp9OgZzY2hlbWHKQWgKK2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWESOWdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5VcGRhdGVTY2hlbWFNZXRhZGF0YRLcAgoMRGVsZXRlU2NoZW1h
EjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRlbGV0ZVNjaGVtYVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIvEBgtPkkwKOASo9L3YxYWxw
aGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovc2NoZW1hcy8q
fVpNKksvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25z
LyovZGF0YVN0b3Jlcy8qL3NjaGVtYXMvKn3aQQRuYW1lykFSChVnb29nbGUucHJvdG9idWYu
RW1wdHkSOWdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EZWxldGVTY2hl
bWFNZXRhZGF0YRpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKeAgooY29tLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUISU2NoZW1hU2VydmljZVByb3RvUAFa
UmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292
ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29n
bGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292
ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYx
YWxwaGFKuTgKBxIFDgCDAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJ
CgIDBBIDFgA7CgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoJCgIDBxIDGQApCggKAQgSAxsAQQoJ
CgIIJRIDGwBBCggKAQgSAxwAaQoJCgIICxIDHABpCggKAQgSAx0AIgoJCgIIChIDHQAiCggK
AQgSAx4AMwoJCgIICBIDHgAzCggKAQgSAx8AQQoJCgIIARIDHwBBCggKAQgSAyAALQoJCgII
JBIDIAAtCggKAQgSAyEAQQoJCgIIKRIDIQBBCggKAQgSAyIAQAoJCgIILRIDIgBACloKAgYA
EgQlAG8BGk4gU2VydmljZSBmb3IgbWFuYWdpbmcgW1NjaGVtYV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlNjaGVtYV1zLgoKCgoDBgABEgMlCBUKCgoDBgADEgMm
AkYKDAoFBgADmQgSAyYCRgoLCgMGAAMSBCcCKDcKDQoFBgADmggSBCcCKDcKTQoEBgACABIE
KwIzAxo/IEdldHMgYSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuU2NoZW1hXS4KCgwKBQYAAgABEgMrBg8KDAoFBgACAAISAysQIAoMCgUGAAIAAxID
KysxCg0KBQYAAgAEEgQsBDEGChEKCQYAAgAEsMq8IhIELAQxBgoMCgUGAAIABBIDMgQyCg8K
CAYAAgAEmwgAEgMyBDIKVgoEBgACARIENgI+AxpIIEdldHMgYSBsaXN0IG9mIFtTY2hlbWFd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFdcy4KCgwKBQYA
AgEBEgM2BhEKDAoFBgACAQISAzYSJAoMCgUGAAIBAxIDNi9CCg0KBQYAAgEEEgQ3BDwGChEK
CQYAAgEEsMq8IhIENwQ8BgoMCgUGAAIBBBIDPQQ0Cg8KCAYAAgEEmwgAEgM9BDQKUAoEBgAC
AhIEQQJPAxpCIENyZWF0ZXMgYSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuU2NoZW1hXS4KCgwKBQYAAgIBEgNBBhIKDAoFBgACAgISA0ETJgoMCgUG
AAICAxIDQTFNCg0KBQYAAgIEEgRCBEkGChEKCQYAAgIEsMq8IhIEQgRJBgoMCgUGAAICBBID
SgRFCg8KCAYAAgIEmwgAEgNKBEUKDQoFBgACAgQSBEsETgYKDwoHBgACAgSZCBIESwROBgpQ
CgQGAAIDEgRSAl8DGkIgVXBkYXRlcyBhIFtTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5TY2hlbWFdLgoKDAoFBgACAwESA1IGEgoMCgUGAAIDAhIDUhMm
CgwKBQYAAgMDEgNSMU0KDQoFBgACAwQSBFMEWgYKEQoJBgACAwSwyrwiEgRTBFoGCg0KBQYA
AgMEEgRbBF4GCg8KBwYAAgMEmQgSBFsEXgYKUAoEBgACBBIEYgJuAxpCIERlbGV0ZXMgYSBb
U2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2NoZW1hXS4K
CgwKBQYAAgQBEgNiBhIKDAoFBgACBAISA2ITJgoMCgUGAAIEAxIDYjFNCg0KBQYAAgQEEgRj
BGgGChEKCQYAAgQEsMq8IhIEYwRoBgoMCgUGAAIEBBIDaQQyCg8KCAYAAgQEmwgAEgNpBDIK
DQoFBgACBAQSBGoEbQYKDwoHBgACBASZCBIEagRtBgqDAQoCBAASBHQAfQEadyBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbU2NoZW1hU2VydmljZS5HZXRTY2hlbWFdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFTZXJ2aWNlLkdldFNjaGVtYV0KIG1ldGhv
ZC4KCgoKAwQAARIDdAgYCr8BCgQEAAIAEgR3AnwEGrABIFJlcXVpcmVkLiBUaGUgZnVsbCBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBzY2hlbWEsIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rp
b259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NjaGVtYXMve3NjaGVtYX1gLgoKDAoFBAAC
AAUSA3cCCAoMCgUEAAIAARIDdwkNCgwKBQQAAgADEgN3EBEKDQoFBAACAAgSBHcSfAMKDwoI
BAACAAicCAASA3gEKgoPCgcEAAIACJ8IEgR5BHsFCokBCgIEARIGggEAngEBGnsgUmVxdWVz
dCBtZXNzYWdlIGZvcgogW1NjaGVtYVNlcnZpY2UuTGlzdFNjaGVtYXNdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFzXQog
bWV0aG9kLgoKCwoDBAEBEgSCAQgaCq8BCgQEAQIAEgaFAQKKAQQangEgUmVxdWlyZWQuIFRo
ZSBwYXJlbnQgZGF0YSBzdG9yZSByZXNvdXJjZSBuYW1lLCBpbiB0aGUgZm9ybWF0IG9mCiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tj
b2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfWAuCgoNCgUEAQIABRIEhQECCAoN
CgUEAQIAARIEhQEJDwoNCgUEAQIAAxIEhQESEwoPCgUEAQIACBIGhQEUigEDChAKCAQBAgAI
nAgAEgSGAQQqChEKBwQBAgAInwgSBocBBIkBBQq8AgoEBAECARIElAECFhqtAiBUaGUgbWF4
aW11bSBudW1iZXIgb2YKIFtTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5TY2hlbWFdcyB0byByZXR1cm4uIFRoZQogc2VydmljZSBtYXkgcmV0dXJuIGZl
d2VyIHRoYW4gdGhpcyB2YWx1ZS4KCiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCAxMDAKIFtT
Y2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFdcyBh
cmUgcmV0dXJuZWQuCgogVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3Zl
IDEwMDAgYXJlIHNldCB0byAxMDAwLgoKDQoFBAECAQUSBJQBAgcKDQoFBAECAQESBJQBCBEK
DQoFBAECAQMSBJQBFBUKjQMKBAQBAgISBJ0BAhga/gIgQSBwYWdlIHRva2VuLCByZWNlaXZl
ZCBmcm9tIGEgcHJldmlvdXMKIFtTY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2NoZW1hU2VydmljZS5MaXN0U2NoZW1h
c10KIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdl
LgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8K
IFtTY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuU2NoZW1hU2VydmljZS5MaXN0U2NoZW1hc10KIG11c3QgbWF0Y2ggdGhl
IGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQBAgIFEgSdAQIICg0K
BQQBAgIBEgSdAQkTCg0KBQQBAgIDEgSdARYXCooBCgIEAhIGowEArAEBGnwgUmVzcG9uc2Ug
bWVzc2FnZSBmb3IKIFtTY2hlbWFTZXJ2aWNlLkxpc3RTY2hlbWFzXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2NoZW1hU2VydmljZS5MaXN0U2NoZW1hc10KIG1l
dGhvZC4KCgsKAwQCARIEowEIGwpLCgQEAgIAEgSlAQIeGj0gVGhlIFtTY2hlbWFdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFdcy4KCg0KBQQCAgAEEgSl
AQIKCg0KBQQCAgAGEgSlAQsRCg0KBQQCAgABEgSlARIZCg0KBQQCAgADEgSlARwdCucBCgQE
AgIBEgSrAQIdGtgBIEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcwogW0xpc3RTY2hlbWFz
UmVxdWVzdC5wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuTGlzdFNjaGVtYXNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubwogc3Vic2Vx
dWVudCBwYWdlcy4KCg0KBQQCAgEFEgSrAQIICg0KBQQCAgEBEgSrAQkYCg0KBQQCAgEDEgSr
ARscCosBCgIEAxIGsQEAyAEBGn0gUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NjaGVtYVNlcnZp
Y2UuQ3JlYXRlU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
U2NoZW1hU2VydmljZS5DcmVhdGVTY2hlbWFdCiBtZXRob2QuCgoLCgMEAwESBLEBCBsKrwEK
BAQDAgASBrQBArkBBBqeASBSZXF1aXJlZC4gVGhlIHBhcmVudCBkYXRhIHN0b3JlIHJlc291
cmNlIG5hbWUsIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2Rh
dGFfc3RvcmV9YC4KCg0KBQQDAgAFEgS0AQIICg0KBQQDAgABEgS0AQkPCg0KBQQDAgADEgS0
ARITCg8KBQQDAgAIEga0ARS5AQMKEAoIBAMCAAicCAASBLUBBCoKEQoHBAMCAAifCBIGtgEE
uAEFCl8KBAQDAgESBL0BAj0aUSBSZXF1aXJlZC4gVGhlIFtTY2hlbWFdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFdIHRvCiBjcmVhdGUuCgoNCgUEAwIB
BhIEvQECCAoNCgUEAwIBARIEvQEJDwoNCgUEAwIBAxIEvQESEwoNCgUEAwIBCBIEvQEUPAoQ
CggEAwIBCJwIABIEvQEVOwrUAgoEBAMCAhIExwECQBrFAiBSZXF1aXJlZC4gVGhlIElEIHRv
IHVzZSBmb3IgdGhlCiBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuU2NoZW1hXSwgd2hpY2ggYmVjb21lcyB0aGUKIGZpbmFsIGNvbXBvbmVudCBvZiB0
aGUKIFtTY2hlbWEubmFtZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlNjaGVtYS5uYW1lXS4KCiBUaGlzIGZpZWxkIHNob3VsZCBjb25mb3JtIHRvCiBbUkZDLTEw
MzRdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMxMDM0KSBzdGFuZGFyZCB3aXRo
IGEgbGVuZ3RoCiBsaW1pdCBvZiA2MyBjaGFyYWN0ZXJzLgoKDQoFBAMCAgUSBMcBAggKDQoF
BAMCAgESBMcBCRIKDQoFBAMCAgMSBMcBFRYKDQoFBAMCAggSBMcBFz8KEAoIBAMCAgicCAAS
BMcBGD4KiwEKAgQEEgbNAQDXAQEafSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2NoZW1hU2Vy
dmljZS5VcGRhdGVTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5TY2hlbWFTZXJ2aWNlLlVwZGF0ZVNjaGVtYV0KIG1ldGhvZC4KCgsKAwQEARIEzQEIGwpf
CgQEBAIAEgTQAQI9GlEgUmVxdWlyZWQuIFRoZSBbU2NoZW1hXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuU2NoZW1hXSB0bwogdXBkYXRlLgoKDQoFBAQCAAYSBNAB
AggKDQoFBAQCAAESBNABCQ8KDQoFBAQCAAMSBNABEhMKDQoFBAQCAAgSBNABFDwKEAoIBAQC
AAicCAASBNABFTsK5AEKBAQEAgESBNYBAhka1QEgSWYgc2V0IHRvIHRydWUsIGFuZCB0aGUK
IFtTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFd
IGlzIG5vdCBmb3VuZCwgYSBuZXcKIFtTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5TY2hlbWFdIGlzIGNyZWF0ZWQuIEluIHRoaXMKIHNpdHVhdGlvbiwg
YHVwZGF0ZV9tYXNrYCBpcyBpZ25vcmVkLgoKDQoFBAQCAQUSBNYBAgYKDQoFBAQCAQESBNYB
BxQKDQoFBAQCAQMSBNYBFxgKiwEKAgQFEgbcAQDlAQEafSBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbU2NoZW1hU2VydmljZS5EZWxldGVTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5TY2hlbWFTZXJ2aWNlLkRlbGV0ZVNjaGVtYV0KIG1ldGhvZC4KCgsK
AwQFARIE3AEIGwrBAQoEBAUCABIG3wEC5AEEGrABIFJlcXVpcmVkLiBUaGUgZnVsbCByZXNv
dXJjZSBuYW1lIG9mIHRoZSBzY2hlbWEsIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259
L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NjaGVtYXMve3NjaGVtYX1gLgoKDQoFBAUCAAUS
BN8BAggKDQoFBAUCAAESBN8BCQ0KDQoFBAUCAAMSBN8BEBEKDwoFBAUCAAgSBt8BEuQBAwoQ
CggEBQIACJwIABIE4AEEKgoRCgcEBQIACJ8IEgbhAQTjAQUKLwoCBAYSBugBAO8BARohIE1l
dGFkYXRhIGZvciBDcmVhdGUgU2NoZW1hIExSTy4KCgsKAwQGARIE6AEIHAomCgQEBgIAEgTq
AQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAYCAAYSBOoBAhsKDQoFBAYCAAES
BOoBHCcKDQoFBAYCAAMSBOoBKisKZAoEBAYCARIE7gECLBpWIE9wZXJhdGlvbiBsYXN0IHVw
ZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUK
IGZpbmlzaCB0aW1lLgoKDQoFBAYCAQYSBO4BAhsKDQoFBAYCAQESBO4BHCcKDQoFBAYCAQMS
BO4BKisKLgoCBAcSBvIBAPkBARogIE1ldGFkYXRhIGZvciBVcGRhdGVTY2hlbWEgTFJPLgoK
CwoDBAcBEgTyAQgcCiYKBAQHAgASBPQBAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoN
CgUEBwIABhIE9AECGwoNCgUEBwIAARIE9AEcJwoNCgUEBwIAAxIE9AEqKwpkCgQEBwIBEgT4
AQIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMg
ZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoNCgUEBwIBBhIE+AECGwoN
CgUEBwIBARIE+AEcJwoNCgUEBwIBAxIE+AEqKwouCgIECBIG/AEAgwIBGiAgTWV0YWRhdGEg
Zm9yIERlbGV0ZVNjaGVtYSBMUk8uCgoLCgMECAESBPwBCBwKJgoEBAgCABIE/gECLBoYIE9w
ZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQIAgAGEgT+AQIbCg0KBQQIAgABEgT+ARwnCg0K
BQQIAgADEgT+ASorCmQKBAQIAgESBIICAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGlt
ZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2gg
dGltZS4KCg0KBQQIAgEGEgSCAgIbCg0KBQQIAgEBEgSCAhwnCg0KBQQIAgEDEgSCAiorYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest ===
    # Fields for GetSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::ListSchemasRequest ===
    # Fields for ListSchemasRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::ListSchemasResponse ===
    # Fields for ListSchemasResponse
    # Field: schemas Type: 11 (.google.cloud.discoveryengine.v1alpha.Schema)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::CreateSchemaRequest ===
    # Fields for CreateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.cloud.discoveryengine.v1alpha.Schema)
    # Field: schema_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::UpdateSchemaRequest ===
    # Fields for UpdateSchemaRequest
    # Field: schema Type: 11 (.google.cloud.discoveryengine.v1alpha.Schema)
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::DeleteSchemaRequest ===
    # Fields for DeleteSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::CreateSchemaMetadata ===
    # Fields for CreateSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::UpdateSchemaMetadata ===
    # Fields for UpdateSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::SchemaService::DeleteSchemaMetadata ===
    # Fields for DeleteSchemaMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::SchemaService::SchemaServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::SchemaService::SchemaServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::SchemaService::SchemaServiceClient

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
        ? Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SchemaService',
        method         => 'GetSchema',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Schema::Schema',
    });
}

sub list_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SchemaService::ListSchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SchemaService',
        method         => 'ListSchemas',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SchemaService::ListSchemasResponse',
    });
}

sub create_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SchemaService::CreateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SchemaService',
        method         => 'CreateSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SchemaService::UpdateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SchemaService',
        method         => 'UpdateSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SchemaService::DeleteSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SchemaService',
        method         => 'DeleteSchema',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SchemaService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/schema_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SchemaService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/schema_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest

Request message for
[SchemaService.GetSchema][google.cloud.discoveryengine.v1alpha.SchemaService.GetSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::ListSchemasRequest

Request message for
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1alpha.SchemaService.ListSchemas]
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

The maximum number of
[Schema][google.cloud.discoveryengine.v1alpha.Schema]s to return. The
service may return fewer than this value.

If unspecified, at most 100
[Schema][google.cloud.discoveryengine.v1alpha.Schema]s are returned.

The maximum value is 1000; values above 1000 are set to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1alpha.SchemaService.ListSchemas]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1alpha.SchemaService.ListSchemas]
must match the call that provided the page token.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::ListSchemasResponse

Response message for
[SchemaService.ListSchemas][google.cloud.discoveryengine.v1alpha.SchemaService.ListSchemas]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schemas() >> / C<< $msg->schemas($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Schema::Schema>)

The [Schema][google.cloud.discoveryengine.v1alpha.Schema]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSchemasRequest.page_token][google.cloud.discoveryengine.v1alpha.ListSchemasRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::CreateSchemaRequest

Request message for
[SchemaService.CreateSchema][google.cloud.discoveryengine.v1alpha.SchemaService.CreateSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Schema::Schema>)

Required. The [Schema][google.cloud.discoveryengine.v1alpha.Schema] to
create.

=item * C<< $msg->schema_id() >> / C<< $msg->schema_id($value) >>

Type: C<String>

Required. The ID to use for the
[Schema][google.cloud.discoveryengine.v1alpha.Schema], which becomes the
final component of the
[Schema.name][google.cloud.discoveryengine.v1alpha.Schema.name].

This field should conform to
[RFC-1034](https://tools.ietf.org/html/rfc1034) standard with a length
limit of 63 characters.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::UpdateSchemaRequest

Request message for
[SchemaService.UpdateSchema][google.cloud.discoveryengine.v1alpha.SchemaService.UpdateSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Schema::Schema>)

Required. The [Schema][google.cloud.discoveryengine.v1alpha.Schema] to
update.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to true, and the
[Schema][google.cloud.discoveryengine.v1alpha.Schema] is not found, a new
[Schema][google.cloud.discoveryengine.v1alpha.Schema] is created. In this
situation, `update_mask` is ignored.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::DeleteSchemaRequest

Request message for
[SchemaService.DeleteSchema][google.cloud.discoveryengine.v1alpha.SchemaService.DeleteSchema]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the schema, in the format of
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/schemas/{schema}`.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::CreateSchemaMetadata

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

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::UpdateSchemaMetadata

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

=head2 Google::Cloud::Discoveryengine::V1alpha::SchemaService::DeleteSchemaMetadata

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SchemaService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
