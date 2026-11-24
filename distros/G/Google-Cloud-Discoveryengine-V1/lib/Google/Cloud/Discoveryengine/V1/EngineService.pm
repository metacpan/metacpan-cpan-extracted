package Google::Cloud::Discoveryengine::V1::EngineService;

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
    eval { require Google::Cloud::Discoveryengine::V1::Engine };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2VuZ2luZV9zZXJ2aWNlLnByb3Rv
Eh9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3Vk
L2Rpc2NvdmVyeWVuZ2luZS92MS9lbmdpbmUucHJvdG8aHmdvb2dsZS9pYW0vdjEvaWFtX3Bv
bGljeS5wcm90bxoaZ29vZ2xlL2lhbS92MS9wb2xpY3kucHJvdG8aI2dvb2dsZS9sb25ncnVu
bmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdv
b2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvIsgBChNDcmVhdGVFbmdpbmVSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx4EEC
+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvblIGcGFyZW50
EkQKBmVuZ2luZRgCIAEoCzInLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5n
aW5lQgPgQQJSBmVuZ2luZRIgCgllbmdpbmVfaWQYAyABKAlCA+BBAlIIZW5naW5lSWQikAEK
FENyZWF0ZUVuZ2luZU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUiWAoTRGVsZXRlRW5naW5lUmVx
dWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9FbmdpbmVSBG5hbWUikAEKFERlbGV0ZUVuZ2luZU1ldGFkYXRhEjsKC2NyZWF0ZV90
aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1
cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRp
bWUiVQoQR2V0RW5naW5lUmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRpc2NvdmVy
eWVuZ2luZS5nb29nbGVhcGlzLmNvbS9FbmdpbmVSBG5hbWUiwgEKEkxpc3RFbmdpbmVzUmVx
dWVzdBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKwopZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0NvbGxlY3Rpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFn
ZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQg
ASgJQgPgQQFSBmZpbHRlciKAAQoTTGlzdEVuZ2luZXNSZXNwb25zZRJBCgdlbmdpbmVzGAEg
AygLMicuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVSB2VuZ2luZXMS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIpgBChNVcGRhdGVFbmdp
bmVSZXF1ZXN0EkQKBmVuZ2luZRgBIAEoCzInLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuRW5naW5lQgPgQQJSBmVuZ2luZRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sywQ0KDUVuZ2luZVNlcnZpY2USqgIK
DENyZWF0ZUVuZ2luZRI0Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ3JlYXRl
RW5naW5lUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ixAGC0+STAkMi
OS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKn0vZW5n
aW5lczoGZW5naW5l2kEXcGFyZW50LGVuZ2luZSxlbmdpbmVfaWTKQV4KJmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lEjRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkNyZWF0ZUVuZ2luZU1ldGFkYXRhEv4BCgxEZWxldGVFbmdpbmUSNC5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRlbGV0ZUVuZ2luZVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpgBgtPkkwI7KjkvdjEve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn3aQQRuYW1lykFNChVnb29nbGUu
cHJvdG9idWYuRW1wdHkSNGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGVsZXRl
RW5naW5lTWV0YWRhdGES1AEKDFVwZGF0ZUVuZ2luZRI0Lmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuVXBkYXRlRW5naW5lUmVxdWVzdBonLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuRW5naW5lImWC0+STAkoyQC92MS97ZW5naW5lLm5hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn06BmVuZ2luZdpBEmVuZ2lu
ZSx1cGRhdGVfbWFzaxKxAQoJR2V0RW5naW5lEjEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5HZXRFbmdpbmVSZXF1ZXN0GicuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5FbmdpbmUiSILT5JMCOxI5L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
Y29sbGVjdGlvbnMvKi9lbmdpbmVzLyp92kEEbmFtZRLEAQoLTGlzdEVuZ2luZXMSMy5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RFbmdpbmVzUmVxdWVzdBo0Lmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdEVuZ2luZXNSZXNwb25zZSJKgtPkkwI7
EjkvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyp9L2Vu
Z2luZXPaQQZwYXJlbnQSqAEKDEdldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuR2V0SWFt
UG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5Il2C0+STAkwSSi92MS97cmVz
b3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn06
Z2V0SWFtUG9saWN52kEIcmVzb3VyY2USsgEKDFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0u
djEuU2V0SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5ImeC0+STAk8i
Si92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2Vu
Z2luZXMvKn06c2V0SWFtUG9saWN5OgEq2kEPcmVzb3VyY2UscG9saWN5Gs8BykEeZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29t
L2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9k
aXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQoUCCiNjb20uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MUISRW5naW5lU2VydmljZVByb3RvUAFaTWNsb3VkLmdv
b2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxL2Rpc2NvdmVyeWVuZ2luZXBiO2Rp
c2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIfR29vZ2xlLkNsb3VkLkRpc2Nv
dmVyeUVuZ2luZS5WMcoCH0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjHqAiJHb29n
bGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxSrZBCgcSBQ4AlwIBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANgoJCgIDBRIDFwAoCgkKAgMGEgMY
ACQKCQoCAwcSAxkALQoJCgIDCBIDGgAlCgkKAgMJEgMbACoKCQoCAwoSAxwAKQoICgEIEgMe
ADwKCQoCCCUSAx4APAoICgEIEgMfAGQKCQoCCAsSAx8AZAoICgEIEgMgACIKCQoCCAoSAyAA
IgoICgEIEgMhADMKCQoCCAgSAyEAMwoICgEIEgMiADwKCQoCCAESAyIAPAoICgEIEgMjAC0K
CQoCCCQSAyMALQoICgEIEgMkADwKCQoCCCkSAyQAPAoICgEIEgMlADsKCQoCCC0SAyUAOwpk
CgIGABIFKQCEAQEaVyBTZXJ2aWNlIGZvciBtYW5hZ2luZyBbRW5naW5lXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZV0KIGNvbmZpZ3VyYXRpb24uCgoKCgMGAAES
AykIFQoKCgMGAAMSAyoCRgoMCgUGAAOZCBIDKgJGCgsKAwYAAxIEKwIuSgoNCgUGAAOaCBIE
KwIuSgpMCgQGAAIAEgQxAjsDGj4gQ3JlYXRlcyBhbiBbRW5naW5lXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZV0uCgoMCgUGAAIAARIDMQYSCgwKBQYAAgACEgMx
EyYKDAoFBgACAAMSAzExTQoNCgUGAAIABBIEMgQ1BgoRCgkGAAIABLDKvCISBDIENQYKDAoF
BgACAAQSAzYERQoPCggGAAIABJsIABIDNgRFCg0KBQYAAgAEEgQ3BDoGCg8KBwYAAgAEmQgS
BDcEOgYKTAoEBgACARIEPgJHAxo+IERlbGV0ZXMgYW4gW0VuZ2luZV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVdLgoKDAoFBgACAQESAz4GEgoMCgUGAAIBAhID
PhMmCgwKBQYAAgEDEgM+MU0KDQoFBgACAQQSBD8EQQYKEQoJBgACAQSwyrwiEgQ/BEEGCgwK
BQYAAgEEEgNCBDIKDwoIBgACAQSbCAASA0IEMgoNCgUGAAIBBBIEQwRGBgoPCgcGAAIBBJkI
EgRDBEYGCksKBAYAAgISBEoCUAMaPSBVcGRhdGVzIGFuIFtFbmdpbmVdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXQoKDAoFBgACAgESA0oGEgoMCgUGAAICAhID
ShMmCgwKBQYAAgIDEgNKMTcKDQoFBgACAgQSBEsETgYKEQoJBgACAgSwyrwiEgRLBE4GCgwK
BQYAAgIEEgNPBEAKDwoIBgACAgSbCAASA08EQApJCgQGAAIDEgRTAlgDGjsgR2V0cyBhbiBb
RW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZV0uCgoMCgUG
AAIDARIDUwYPCgwKBQYAAgMCEgNTECAKDAoFBgACAwMSA1MrMQoNCgUGAAIDBBIEVARWBgoR
CgkGAAIDBLDKvCISBFQEVgYKDAoFBgACAwQSA1cEMgoPCggGAAIDBJsIABIDVwQyCm0KBAYA
AgQSBFwCYQMaXyBMaXN0cyBhbGwgdGhlIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuRW5naW5lXXMgYXNzb2NpYXRlZAogd2l0aCB0aGUgcHJvamVjdC4KCgwK
BQYAAgQBEgNcBhEKDAoFBgACBAISA1wSJAoMCgUGAAIEAxIDXC9CCg0KBQYAAgQEEgRdBF8G
ChEKCQYAAgQEsMq8IhIEXQRfBgoMCgUGAAIEBBIDYAQ0Cg8KCAYAAgQEmwgAEgNgBDQKiAIK
BAYAAgUSBGcCbQMa+QEgR2V0cyB0aGUgSUFNIGFjY2VzcyBjb250cm9sIHBvbGljeSBmb3Ig
YW4KIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXS4g
QSBgTk9UX0ZPVU5EYCBlcnJvciBpcwogcmV0dXJuZWQgaWYgdGhlIHJlc291cmNlIGRvZXMg
bm90IGV4aXN0LiBBbiBlbXB0eSBwb2xpY3kgaXMgcmV0dXJuZWQgaWYgdGhlCiByZXNvdXJj
ZSBleGlzdHMgYnV0IGRvZXMgbm90IGhhdmUgYSBwb2xpY3kgc2V0IG9uIGl0LgoKDAoFBgAC
BQESA2cGEgoMCgUGAAIFAhIDZxM0CgwKBQYAAgUDEgNoDyMKDQoFBgACBQQSBGkEawYKEQoJ
BgACBQSwyrwiEgRpBGsGCgwKBQYAAgUEEgNsBDYKDwoIBgACBQSbCAASA2wENgrOBAoEBgAC
BhIFfAKDAQMavgQgU2V0cyB0aGUgSUFNIGFjY2VzcyBjb250cm9sIHBvbGljeSBmb3IgYW4K
IFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXS4gQSBg
Tk9UX0ZPVU5EYCBlcnJvciBpcwogcmV0dXJuZWQgaWYgdGhlIHJlc291cmNlIGRvZXMgbm90
IGV4aXN0LgoKICoqSW1wb3J0YW50OioqIFdoZW4gc2V0dGluZyBhIHBvbGljeSBkaXJlY3Rs
eSBvbiBhbiBFbmdpbmUgcmVzb3VyY2UsCiB0aGUgb25seSByZWNvbW1lbmRlZCByb2xlcyBp
biB0aGUgYmluZGluZ3MgYXJlOgogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS5hZG1pbmAsCiBg
cm9sZXMvZGlzY292ZXJ5ZW5naW5lLmFnZW50c3BhY2VBZG1pbmAsCiBgcm9sZXMvZGlzY292
ZXJ5ZW5naW5lLnVzZXJgLAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS5hZ2VudHNwYWNlVXNl
cmAsCiBgcm9sZXMvZGlzY292ZXJ5ZW5naW5lLnZpZXdlcmAsCiBgcm9sZXMvZGlzY292ZXJ5
ZW5naW5lLmFnZW50c3BhY2VWaWV3ZXJgLgogQXR0ZW1wdGluZyB0byBncmFudCBhbnkgb3Ro
ZXIgcm9sZSB3aWxsIHJlc3VsdCBpbiBhIHdhcm5pbmcgaW4gbG9nZ2luZy4KCgwKBQYAAgYB
EgN8BhIKDAoFBgACBgISA3wTNAoMCgUGAAIGAxIDfQ8jCg4KBQYAAgYEEgV+BIEBBgoSCgkG
AAIGBLDKvCISBX4EgQEGCg0KBQYAAgYEEgSCAQQ9ChAKCAYAAgYEmwgAEgSCAQQ9Cn4KAgQA
EgaJAQCfAQEacCBSZXF1ZXN0IGZvcgogW0VuZ2luZVNlcnZpY2UuQ3JlYXRlRW5naW5lXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZVNlcnZpY2UuQ3JlYXRlRW5n
aW5lXQogbWV0aG9kLgoKCwoDBAABEgSJAQgbCoIBCgQEAAIAEgaMAQKRAQQaciBSZXF1aXJl
ZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufWAuCgoN
CgUEAAIABRIEjAECCAoNCgUEAAIAARIEjAEJDwoNCgUEAAIAAxIEjAESEwoPCgUEAAIACBIG
jAEUkQEDChAKCAQAAgAInAgAEgSNAQQqChEKBwQAAgAInwgSBo4BBJABBQpZCgQEAAIBEgSU
AQI9GksgUmVxdWlyZWQuIFRoZSBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkVuZ2luZV0gdG8gY3JlYXRlLgoKDQoFBAACAQYSBJQBAggKDQoFBAACAQESBJQB
CQ8KDQoFBAACAQMSBJQBEhMKDQoFBAACAQgSBJQBFDwKEAoIBAACAQicCAASBJQBFTsKhAMK
BAQAAgISBJ4BAkAa9QIgUmVxdWlyZWQuIFRoZSBJRCB0byB1c2UgZm9yIHRoZQogW0VuZ2lu
ZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVdLCB3aGljaCB3aWxs
IGJlY29tZSB0aGUKIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUgW0VuZ2luZV1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVdJ3MKIHJlc291cmNlIG5hbWUuCgogVGhp
cyBmaWVsZCBtdXN0IGNvbmZvcm0gdG8gW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYu
b3JnL2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdpdGggYSBsZW5ndGggbGltaXQgb2YgNjMg
Y2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbgogSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyBy
ZXR1cm5lZC4KCg0KBQQAAgIFEgSeAQIICg0KBQQAAgIBEgSeAQkSCg0KBQQAAgIDEgSeARUW
Cg0KBQQAAgIIEgSeARc/ChAKCAQAAgIInAgAEgSeARg+CukBCgIEARIGpQEArAEBGtoBIE1l
dGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZQogW0VuZ2luZVNlcnZpY2Uu
Q3JlYXRlRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZVNl
cnZpY2UuQ3JlYXRlRW5naW5lXQogb3BlcmF0aW9uLiBUaGlzIHdpbGwgYmUgcmV0dXJuZWQg
YnkgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEKIGZpZWxkLgoK
CwoDBAEBEgSlAQgcCiYKBAQBAgASBKcBAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoN
CgUEAQIABhIEpwECGwoNCgUEAQIAARIEpwEcJwoNCgUEAQIAAxIEpwEqKwpkCgQEAQIBEgSr
AQIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMg
ZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoNCgUEAQIBBhIEqwECGwoN
CgUEAQIBARIEqwEcJwoNCgUEAQIBAxIEqwEqKwqGAQoCBAISBrEBAMIBARp4IFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtFbmdpbmVTZXJ2aWNlLkRlbGV0ZUVuZ2luZV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVTZXJ2aWNlLkRlbGV0ZUVuZ2luZV0KIG1ldGhv
ZC4KCgsKAwQCARIEsQEIGwr3AwoEBAICABIGvAECwQEEGuYDIFJlcXVpcmVkLiBGdWxsIHJl
c291cmNlIG5hbWUgb2YKIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRW5naW5lXSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZW5naW5lcy97ZW5naW5lX2lk
fWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gZGVsZXRl
IHRoZQogW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVd
LCByZWdhcmRsZXNzIG9mIHdoZXRoZXIgb3IKIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lP
Tl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIFtFbmdpbmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXSB0byBkZWxldGUgZG9lcyBub3QKIGV4
aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQCAgAFEgS8AQIICg0K
BQQCAgABEgS8AQkNCg0KBQQCAgADEgS8ARARCg8KBQQCAgAIEga8ARLBAQMKEAoIBAICAAic
CAASBL0BBCoKEQoHBAICAAifCBIGvgEEwAEFCukBCgIEAxIGyAEAzwEBGtoBIE1ldGFkYXRh
IHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZQogW0VuZ2luZVNlcnZpY2UuRGVsZXRl
RW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZVNlcnZpY2Uu
RGVsZXRlRW5naW5lXQogb3BlcmF0aW9uLiBUaGlzIHdpbGwgYmUgcmV0dXJuZWQgYnkgdGhl
IGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEKIGZpZWxkLgoKCwoDBAMB
EgTIAQgcCiYKBAQDAgASBMoBAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEAwIA
BhIEygECGwoNCgUEAwIAARIEygEcJwoNCgUEAwIAAxIEygEqKwpkCgQEAwIBEgTOAQIsGlYg
T3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwg
dGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoNCgUEAwIBBhIEzgECGwoNCgUEAwIB
ARIEzgEcJwoNCgUEAwIBAxIEzgEqKwqAAQoCBAQSBtQBAN4BARpyIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtFbmdpbmVTZXJ2aWNlLkdldEVuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5FbmdpbmVTZXJ2aWNlLkdldEVuZ2luZV0KIG1ldGhvZC4KCgsKAwQEARIE
1AEIGArJAQoEBAQCABIG2AEC3QEEGrgBIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUg
b2YKIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXSwg
c3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xs
ZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZW5naW5lcy97ZW5naW5lX2lkfWAuCgoNCgUEBAIA
BRIE2AECCAoNCgUEBAIAARIE2AEJDQoNCgUEBAIAAxIE2AEQEQoPCgUEBAIACBIG2AES3QED
ChAKCAQEAgAInAgAEgTZAQQqChEKBwQEAgAInwgSBtoBBNwBBQqEAQoCBAUSBuMBAPYBARp2
IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtFbmdpbmVTZXJ2aWNlLkxpc3RFbmdpbmVzXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZVNlcnZpY2UuTGlzdEVuZ2luZXNd
CiBtZXRob2QuCgoLCgMEBQESBOMBCBoKhQEKBAQFAgASBuYBAusBBBp1IFJlcXVpcmVkLiBU
aGUgcGFyZW50IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9YC4KCg0K
BQQFAgAFEgTmAQIICg0KBQQFAgABEgTmAQkPCg0KBQQFAgADEgTmARITCg8KBQQFAgAIEgbm
ARTrAQMKEAoIBAUCAAicCAASBOcBBCoKEQoHBAUCAAifCBIG6AEE6gEFCigKBAQFAgESBO4B
Aj8aGiBPcHRpb25hbC4gTm90IHN1cHBvcnRlZC4KCg0KBQQFAgEFEgTuAQIHCg0KBQQFAgEB
EgTuAQgRCg0KBQQFAgEDEgTuARQVCg0KBQQFAgEIEgTuARY+ChAKCAQFAgEInAgAEgTuARc9
CigKBAQFAgISBPEBAkEaGiBPcHRpb25hbC4gTm90IHN1cHBvcnRlZC4KCg0KBQQFAgIFEgTx
AQIICg0KBQQFAgIBEgTxAQkTCg0KBQQFAgIDEgTxARYXCg0KBQQFAgIIEgTxARhAChAKCAQF
AgIInAgAEgTxARk/CmMKBAQFAgMSBPUBAj0aVSBPcHRpb25hbC4gRmlsdGVyIGJ5IHNvbHV0
aW9uIHR5cGUuIEZvciBleGFtcGxlOgogc29sdXRpb25fdHlwZT1TT0xVVElPTl9UWVBFX1NF
QVJDSAoKDQoFBAUCAwUSBPUBAggKDQoFBAUCAwESBPUBCQ8KDQoFBAUCAwMSBPUBEhMKDQoF
BAUCAwgSBPUBFDwKEAoIBAUCAwicCAASBPUBFTsKhQEKAgQGEgb7AQCBAgEadyBSZXNwb25z
ZSBtZXNzYWdlIGZvcgogW0VuZ2luZVNlcnZpY2UuTGlzdEVuZ2luZXNdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lU2VydmljZS5MaXN0RW5naW5lc10KIG1ldGhv
ZC4KCgsKAwQGARIE+wEIGwpVCgQEBgIAEgT9AQIeGkcgQWxsIHRoZSBjdXN0b21lcidzIFtF
bmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXXMuCgoNCgUE
BgIABBIE/QECCgoNCgUEBgIABhIE/QELEQoNCgUEBgIAARIE/QESGQoNCgUEBgIAAxIE/QEc
HQoeCgQEBgIBEgSAAgIdGhAgTm90IHN1cHBvcnRlZC4KCg0KBQQGAgEFEgSAAgIICg0KBQQG
AgEBEgSAAgkYCg0KBQQGAgEDEgSAAhscCoYBCgIEBxIGhgIAlwIBGnggUmVxdWVzdCBtZXNz
YWdlIGZvcgogW0VuZ2luZVNlcnZpY2UuVXBkYXRlRW5naW5lXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkVuZ2luZVNlcnZpY2UuVXBkYXRlRW5naW5lXQogbWV0aG9kLgoK
CwoDBAcBEgSGAggbCogDCgQEBwIAEgSPAgI9GvkCIFJlcXVpcmVkLiBUaGUgW0VuZ2luZV1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5FbmdpbmVdIHRvIHVwZGF0ZS4KCiBJ
ZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBb
RW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZV0sIHJlZ2Fy
ZGxlc3Mgb2Ygd2hldGhlciBvcgogbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RFTklF
RCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5FbmdpbmVdIHRvIHVwZGF0ZSBkb2VzIG5vdAogZXhpc3QsIGEg
Tk9UX0ZPVU5EIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAcCAAYSBI8CAggKDQoFBAcCAAES
BI8CCQ8KDQoFBAcCAAMSBI8CEhMKDQoFBAcCAAgSBI8CFDwKEAoIBAcCAAicCAASBI8CFTsK
zgEKBAQHAgESBJYCAiwavwEgSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlk
ZWQKIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRW5naW5lXSB0
byB1cGRhdGUuCgogSWYgYW4gdW5zdXBwb3J0ZWQgb3IgdW5rbm93biBmaWVsZCBpcyBwcm92
aWRlZCwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvcgogaXMgcmV0dXJuZWQuCgoNCgUEBwIB
BhIElgICGwoNCgUEBwIBARIElgIcJwoNCgUEBwIBAxIElgIqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest ===
    # Fields for CreateEngineRequest
    # Field: parent Type: 9 ()
    # Field: engine Type: 11 (.google.cloud.discoveryengine.v1.Engine)
    # Field: engine_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineMetadata ===
    # Fields for CreateEngineMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineRequest ===
    # Fields for DeleteEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineMetadata ===
    # Fields for DeleteEngineMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::GetEngineRequest ===
    # Fields for GetEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesRequest ===
    # Fields for ListEnginesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesResponse ===
    # Fields for ListEnginesResponse
    # Field: engines Type: 11 (.google.cloud.discoveryengine.v1.Engine)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::EngineService::UpdateEngineRequest ===
    # Fields for UpdateEngineRequest
    # Field: engine Type: 11 (.google.cloud.discoveryengine.v1.Engine)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Discoveryengine::V1::EngineService::EngineServiceClient ===
package Google::Cloud::Discoveryengine::V1::EngineService::EngineServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::EngineService::EngineServiceClient

Client stub representing the remote C<EngineService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'CreateEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'DeleteEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::EngineService::UpdateEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'UpdateEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Engine::Engine',
    });
}

sub get_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::EngineService::GetEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'GetEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Engine::Engine',
    });
}

sub list_engines {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'ListEngines',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesResponse',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::EngineService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/engine_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::EngineService;

    my $msg = Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest->new({
        parent => $parent,
        engine => $engine,
        engine_id => $engine_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/engine_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest

Request for
[EngineService.CreateEngine][google.cloud.discoveryengine.v1.EngineService.CreateEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Engine::Engine>)

Required. The [Engine][google.cloud.discoveryengine.v1.Engine] to create.

=item * C<< $msg->engine_id() >> / C<< $msg->engine_id($value) >>

Type: C<String>

Required. The ID to use for the
[Engine][google.cloud.discoveryengine.v1.Engine], which will become the
final component of the [Engine][google.cloud.discoveryengine.v1.Engine]'s
resource name.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
INVALID_ARGUMENT error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineMetadata

Metadata related to the progress of the
[EngineService.CreateEngine][google.cloud.discoveryengine.v1.EngineService.CreateEngine]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

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

=head2 Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineRequest

Request message for
[EngineService.DeleteEngine][google.cloud.discoveryengine.v1.EngineService.DeleteEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Engine][google.cloud.discoveryengine.v1.Engine], such as
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

If the caller does not have permission to delete the
[Engine][google.cloud.discoveryengine.v1.Engine], regardless of whether or
not it exists, a PERMISSION_DENIED error is returned.

If the [Engine][google.cloud.discoveryengine.v1.Engine] to delete does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::EngineService::DeleteEngineMetadata

Metadata related to the progress of the
[EngineService.DeleteEngine][google.cloud.discoveryengine.v1.EngineService.DeleteEngine]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

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

=head2 Google::Cloud::Discoveryengine::V1::EngineService::GetEngineRequest

Request message for
[EngineService.GetEngine][google.cloud.discoveryengine.v1.EngineService.GetEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Engine][google.cloud.discoveryengine.v1.Engine], such as
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesRequest

Request message for
[EngineService.ListEngines][google.cloud.discoveryengine.v1.EngineService.ListEngines]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Not supported.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Not supported.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter by solution type. For example:
solution_type=SOLUTION_TYPE_SEARCH

=back

=head2 Google::Cloud::Discoveryengine::V1::EngineService::ListEnginesResponse

Response message for
[EngineService.ListEngines][google.cloud.discoveryengine.v1.EngineService.ListEngines]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engines() >> / C<< $msg->engines($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Engine::Engine>)

All the customer's [Engine][google.cloud.discoveryengine.v1.Engine]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Not supported.

=back

=head2 Google::Cloud::Discoveryengine::V1::EngineService::UpdateEngineRequest

Request message for
[EngineService.UpdateEngine][google.cloud.discoveryengine.v1.EngineService.UpdateEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Engine::Engine>)

Required. The [Engine][google.cloud.discoveryengine.v1.Engine] to update.

If the caller does not have permission to update the
[Engine][google.cloud.discoveryengine.v1.Engine], regardless of whether or
not it exists, a PERMISSION_DENIED error is returned.

If the [Engine][google.cloud.discoveryengine.v1.Engine] to update does not
exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Engine][google.cloud.discoveryengine.v1.Engine] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::EngineService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
