package Google::Cloud::Resourcemanager::V3::TagValues;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvcmVzb3VyY2VtYW5hZ2VyL3YzL3RhZ192YWx1ZXMucHJvdG8SH2dv
b2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvaWFtL3YxL2lh
bV9wb2xpY3kucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnByb3RvGiNnb29nbGUvbG9u
Z3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2su
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipgMKCFRhZ1ZhbHVlEhcK
BG5hbWUYASABKAlCA+BBBVIEbmFtZRIbCgZwYXJlbnQYAiABKAlCA+BBBVIGcGFyZW50EiUK
CnNob3J0X25hbWUYAyABKAlCBuBBAuBBBVIJc2hvcnROYW1lEiwKD25hbWVzcGFjZWRfbmFt
ZRgEIAEoCUID4EEDUg5uYW1lc3BhY2VkTmFtZRIlCgtkZXNjcmlwdGlvbhgFIAEoCUID4EEB
UgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgHIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIXCgRldGFnGAggASgJQgPg
QQFSBGV0YWc6S+pBSAosY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVGFn
VmFsdWUSFXRhZ1ZhbHVlcy97dGFnX3ZhbHVlfVIBASJ/ChRMaXN0VGFnVmFsdWVzUmVxdWVz
dBIhCgZwYXJlbnQYASABKAlCCeBBAvpBAxIBKlIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEo
BUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKJ
AQoVTGlzdFRhZ1ZhbHVlc1Jlc3BvbnNlEkgKCnRhZ192YWx1ZXMYASADKAsyKS5nb29nbGUu
Y2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLlRhZ1ZhbHVlUgl0YWdWYWx1ZXMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIl4KEkdldFRhZ1ZhbHVlUmVxdWVzdBJI
CgRuYW1lGAEgASgJQjTgQQL6QS4KLGNsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMu
Y29tL1RhZ1ZhbHVlUgRuYW1lImgKHEdldE5hbWVzcGFjZWRUYWdWYWx1ZVJlcXVlc3QSSAoE
bmFtZRgBIAEoCUI04EEC+kEuCixjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNv
bS9UYWdWYWx1ZVIEbmFtZSKOAQoVQ3JlYXRlVGFnVmFsdWVSZXF1ZXN0EksKCXRhZ192YWx1
ZRgBIAEoCzIpLmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuVGFnVmFsdWVCA+BB
AlIIdGFnVmFsdWUSKAoNdmFsaWRhdGVfb25seRgCIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHki
GAoWQ3JlYXRlVGFnVmFsdWVNZXRhZGF0YSLQAQoVVXBkYXRlVGFnVmFsdWVSZXF1ZXN0EksK
CXRhZ192YWx1ZRgBIAEoCzIpLmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuVGFn
VmFsdWVCA+BBAlIIdGFnVmFsdWUSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSKAoNdmFsaWRhdGVfb25seRgDIAEo
CEID4EEBUgx2YWxpZGF0ZU9ubHkiGAoWVXBkYXRlVGFnVmFsdWVNZXRhZGF0YSKkAQoVRGVs
ZXRlVGFnVmFsdWVSZXF1ZXN0EkgKBG5hbWUYASABKAlCNOBBAvpBLgosY2xvdWRyZXNvdXJj
ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVGFnVmFsdWVSBG5hbWUSKAoNdmFsaWRhdGVfb25s
eRgCIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHkSFwoEZXRhZxgDIAEoCUID4EEBUgRldGFnIhgK
FkRlbGV0ZVRhZ1ZhbHVlTWV0YWRhdGEyrA0KCVRhZ1ZhbHVlcxKeAQoNTGlzdFRhZ1ZhbHVl
cxI1Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuTGlzdFRhZ1ZhbHVlc1JlcXVl
c3QaNi5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLkxpc3RUYWdWYWx1ZXNSZXNw
b25zZSIegtPkkwIPEg0vdjMvdGFnVmFsdWVz2kEGcGFyZW50EpQBCgtHZXRUYWdWYWx1ZRIz
Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuR2V0VGFnVmFsdWVSZXF1ZXN0Giku
Z29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5UYWdWYWx1ZSIlgtPkkwIYEhYvdjMv
e25hbWU9dGFnVmFsdWVzLyp92kEEbmFtZRKqAQoVR2V0TmFtZXNwYWNlZFRhZ1ZhbHVlEj0u
Z29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5HZXROYW1lc3BhY2VkVGFnVmFsdWVS
ZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5UYWdWYWx1ZSIngtPk
kwIaEhgvdjMvdGFnVmFsdWVzL25hbWVzcGFjZWTaQQRuYW1lEroBCg5DcmVhdGVUYWdWYWx1
ZRI2Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuQ3JlYXRlVGFnVmFsdWVSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJRgtPkkwIaIg0vdjMvdGFnVmFs
dWVzOgl0YWdfdmFsdWXaQQl0YWdfdmFsdWXKQSIKCFRhZ1ZhbHVlEhZDcmVhdGVUYWdWYWx1
ZU1ldGFkYXRhEtkBCg5VcGRhdGVUYWdWYWx1ZRI2Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1h
bmFnZXIudjMuVXBkYXRlVGFnVmFsdWVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiJwgtPkkwItMiAvdjMve3RhZ192YWx1ZS5uYW1lPXRhZ1ZhbHVlcy8qfToJdGFn
X3ZhbHVl2kEVdGFnX3ZhbHVlLHVwZGF0ZV9tYXNrykEiCghUYWdWYWx1ZRIWVXBkYXRlVGFn
VmFsdWVNZXRhZGF0YRKzAQoORGVsZXRlVGFnVmFsdWUSNi5nb29nbGUuY2xvdWQucmVzb3Vy
Y2VtYW5hZ2VyLnYzLkRlbGV0ZVRhZ1ZhbHVlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb24iSoLT5JMCGCoWL3YzL3tuYW1lPXRhZ1ZhbHVlcy8qfdpBBG5hbWXKQSIK
CFRhZ1ZhbHVlEhZEZWxldGVUYWdWYWx1ZU1ldGFkYXRhEogBCgxHZXRJYW1Qb2xpY3kSIi5n
b29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGlj
eSI9gtPkkwIsIicvdjMve3Jlc291cmNlPXRhZ1ZhbHVlcy8qfTpnZXRJYW1Qb2xpY3k6ASra
QQhyZXNvdXJjZRKPAQoMU2V0SWFtUG9saWN5EiIuZ29vZ2xlLmlhbS52MS5TZXRJYW1Qb2xp
Y3lSZXF1ZXN0GhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3kiRILT5JMCLCInL3YzL3tyZXNvdXJj
ZT10YWdWYWx1ZXMvKn06c2V0SWFtUG9saWN5OgEq2kEPcmVzb3VyY2UscG9saWN5EroBChJU
ZXN0SWFtUGVybWlzc2lvbnMSKC5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9uc1Jl
cXVlc3QaKS5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9uc1Jlc3BvbnNlIk+C0+ST
AjIiLS92My97cmVzb3VyY2U9dGFnVmFsdWVzLyp9OnRlc3RJYW1QZXJtaXNzaW9uczoBKtpB
FHJlc291cmNlLHBlcm1pc3Npb25zGpABykEjY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xl
YXBpcy5jb23SQWdodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0ucmVh
ZC1vbmx5Qu8BCiNjb20uZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52M0IOVGFnVmFs
dWVzUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9yZXNvdXJjZW1hbmFnZXIvYXBpdjMv
cmVzb3VyY2VtYW5hZ2VycGI7cmVzb3VyY2VtYW5hZ2VycGKqAh9Hb29nbGUuQ2xvdWQuUmVz
b3VyY2VNYW5hZ2VyLlYzygIfR29vZ2xlXENsb3VkXFJlc291cmNlTWFuYWdlclxWM+oCIkdv
b2dsZTo6Q2xvdWQ6OlJlc291cmNlTWFuYWdlcjo6VjNK/FAKBxIFDgDKAiEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAoCgkKAgMFEgMXACQKCQoCAwYS
AxgALQoJCgIDBxIDGQAqCgkKAgMIEgMaACkKCAoBCBIDHAA8CgkKAgglEgMcADwKCAoBCBID
HQBkCgkKAggLEgMdAGQKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwAvCgkKAggIEgMf
AC8KCAoBCBIDIAA8CgkKAggBEgMgADwKCAoBCBIDIQA8CgkKAggpEgMhADwKCAoBCBIDIgA7
CgkKAggtEgMiADsKOwoCBgASBSUAnQEBGi4gQWxsb3cgdXNlcnMgdG8gY3JlYXRlIGFuZCBt
YW5hZ2UgdGFnIHZhbHVlcy4KCgoKAwYAARIDJQgRCgoKAwYAAxIDJgJLCgwKBQYAA5kIEgMm
AksKCwoDBgADEgQnAilBCg0KBQYAA5oIEgQnAilBCjoKBAYAAgASBCwCMQMaLCBMaXN0cyBh
bGwgVGFnVmFsdWVzIGZvciBhIHNwZWNpZmljIFRhZ0tleS4KCgwKBQYAAgABEgMsBhMKDAoF
BgACAAISAywUKAoMCgUGAAIAAxIDLDNICg0KBQYAAgAEEgQtBC8GChEKCQYAAgAEsMq8IhIE
LQQvBgoMCgUGAAIABBIDMAQ0Cg8KCAYAAgAEmwgAEgMwBDQKoAEKBAYAAgESBDUCOgMakQEg
UmV0cmlldmVzIGEgVGFnVmFsdWUuIFRoaXMgbWV0aG9kIHdpbGwgcmV0dXJuIGBQRVJNSVNT
SU9OX0RFTklFRGAgaWYgdGhlCiB2YWx1ZSBkb2VzIG5vdCBleGlzdCBvciB0aGUgdXNlciBk
b2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gdmlldyBpdC4KCgwKBQYAAgEBEgM1BhEKDAoF
BgACAQISAzUSJAoMCgUGAAIBAxIDNS83Cg0KBQYAAgEEEgQ2BDgGChEKCQYAAgEEsMq8IhIE
NgQ4BgoMCgUGAAIBBBIDOQQyCg8KCAYAAgEEmwgAEgM5BDIKuAEKBAYAAgISBD8CRAMaqQEg
UmV0cmlldmVzIGEgVGFnVmFsdWUgYnkgaXRzIG5hbWVzcGFjZWQgbmFtZS4KIFRoaXMgbWV0
aG9kIHdpbGwgcmV0dXJuIGBQRVJNSVNTSU9OX0RFTklFRGAgaWYgdGhlIHZhbHVlIGRvZXMg
bm90IGV4aXN0CiBvciB0aGUgdXNlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gdmll
dyBpdC4KCgwKBQYAAgIBEgM/BhsKDAoFBgACAgISAz8cOAoMCgUGAAICAxIDP0NLCg0KBQYA
AgIEEgRABEIGChEKCQYAAgIEsMq8IhIEQARCBgoMCgUGAAICBBIDQwQyCg8KCAYAAgIEmwgA
EgNDBDIKmwIKBAYAAgMSBEoCVQMajAIgQ3JlYXRlcyBhIFRhZ1ZhbHVlIGFzIGEgY2hpbGQg
b2YgdGhlIHNwZWNpZmllZCBUYWdLZXkuIElmIGEgYW5vdGhlcgogcmVxdWVzdCB3aXRoIHRo
ZSBzYW1lIHBhcmFtZXRlcnMgaXMgc2VudCB3aGlsZSB0aGUgb3JpZ2luYWwgcmVxdWVzdCBp
cyBpbgogcHJvY2VzcyB0aGUgc2Vjb25kIHJlcXVlc3Qgd2lsbCByZWNlaXZlIGFuIGVycm9y
LiBBIG1heGltdW0gb2YgMTAwMAogVGFnVmFsdWVzIGNhbiBleGlzdCB1bmRlciBhIFRhZ0tl
eSBhdCBhbnkgZ2l2ZW4gdGltZS4KCgwKBQYAAgMBEgNKBhQKDAoFBgACAwISA0oVKgoMCgUG
AAIDAxIDSw8rCg0KBQYAAgMEEgRMBE8GChEKCQYAAgMEsMq8IhIETARPBgoMCgUGAAIDBBID
UAQ3Cg8KCAYAAgMEmwgAEgNQBDcKDQoFBgACAwQSBFEEVAYKDwoHBgACAwSZCBIEUQRUBgpA
CgQGAAIEEgRYAmMDGjIgVXBkYXRlcyB0aGUgYXR0cmlidXRlcyBvZiB0aGUgVGFnVmFsdWUg
cmVzb3VyY2UuCgoMCgUGAAIEARIDWAYUCgwKBQYAAgQCEgNYFSoKDAoFBgACBAMSA1kPKwoN
CgUGAAIEBBIEWgRdBgoRCgkGAAIEBLDKvCISBFoEXQYKDAoFBgACBAQSA14EQwoPCggGAAIE
BJsIABIDXgRDCg0KBQYAAgQEEgRfBGIGCg8KBwYAAgQEmQgSBF8EYgYKXgoEBgACBRIEZwJx
AxpQIERlbGV0ZXMgYSBUYWdWYWx1ZS4gVGhlIFRhZ1ZhbHVlIGNhbm5vdCBoYXZlIGFueSBi
aW5kaW5ncyB3aGVuIGl0IGlzCiBkZWxldGVkLgoKDAoFBgACBQESA2cGFAoMCgUGAAIFAhID
ZxUqCgwKBQYAAgUDEgNoDysKDQoFBgACBQQSBGkEawYKEQoJBgACBQSwyrwiEgRpBGsGCgwK
BQYAAgUEEgNsBDIKDwoIBgACBQSbCAASA2wEMgoNCgUGAAIFBBIEbQRwBgoPCgcGAAIFBJkI
EgRtBHAGCoYDCgQGAAIGEgV5AoABAxr2AiBHZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xp
Y3kgZm9yIGEgVGFnVmFsdWUuIFRoZSByZXR1cm5lZCBwb2xpY3kgbWF5IGJlCiBlbXB0eSBp
ZiBubyBzdWNoIHBvbGljeSBvciByZXNvdXJjZSBleGlzdHMuIFRoZSBgcmVzb3VyY2VgIGZp
ZWxkIHNob3VsZAogYmUgdGhlIFRhZ1ZhbHVlJ3MgcmVzb3VyY2UgbmFtZS4gRm9yIGV4YW1w
bGU6IGB0YWdWYWx1ZXMvMTIzNGAuCiBUaGUgY2FsbGVyIG11c3QgaGF2ZSB0aGUKIGBjbG91
ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS90YWdWYWx1ZXMuZ2V0SWFtUG9saWN5
YCBwZXJtaXNzaW9uIG9uCiB0aGUgaWRlbnRpZmllZCBUYWdWYWx1ZSB0byBnZXQgdGhlIGFj
Y2VzcyBjb250cm9sIHBvbGljeS4KCgwKBQYAAgYBEgN5BhIKDAoFBgACBgISA3kTNAoMCgUG
AAIGAxIDeg8jCg0KBQYAAgYEEgR7BH4GChEKCQYAAgYEsMq8IhIEewR+BgoMCgUGAAIGBBID
fwQ2Cg8KCAYAAgYEmwgAEgN/BDYKpAIKBAYAAgcSBocBAo4BAxqTAiBTZXRzIHRoZSBhY2Nl
c3MgY29udHJvbCBwb2xpY3kgb24gYSBUYWdWYWx1ZSwgcmVwbGFjaW5nIGFueSBleGlzdGlu
ZwogcG9saWN5LiBUaGUgYHJlc291cmNlYCBmaWVsZCBzaG91bGQgYmUgdGhlIFRhZ1ZhbHVl
J3MgcmVzb3VyY2UgbmFtZS4KIEZvciBleGFtcGxlOiBgdGFnVmFsdWVzLzEyMzRgLgogVGhl
IGNhbGxlciBtdXN0IGhhdmUgYHJlc291cmNlbWFuYWdlci50YWdWYWx1ZXMuc2V0SWFtUG9s
aWN5YCBwZXJtaXNzaW9uCiBvbiB0aGUgaWRlbnRpZmllZCB0YWdWYWx1ZS4KCg0KBQYAAgcB
EgSHAQYSCg0KBQYAAgcCEgSHARM0Cg0KBQYAAgcDEgSIAQ8jCg8KBQYAAgcEEgaJAQSMAQYK
EwoJBgACBwSwyrwiEgaJAQSMAQYKDQoFBgACBwQSBI0BBD0KEAoIBgACBwSbCAASBI0BBD0K
7wEKBAYAAggSBpUBApwBAxreASBSZXR1cm5zIHBlcm1pc3Npb25zIHRoYXQgYSBjYWxsZXIg
aGFzIG9uIHRoZSBzcGVjaWZpZWQgVGFnVmFsdWUuCiBUaGUgYHJlc291cmNlYCBmaWVsZCBz
aG91bGQgYmUgdGhlIFRhZ1ZhbHVlJ3MgcmVzb3VyY2UgbmFtZS4gRm9yIGV4YW1wbGU6CiBg
dGFnVmFsdWVzLzEyMzRgLgoKIFRoZXJlIGFyZSBubyBwZXJtaXNzaW9ucyByZXF1aXJlZCBm
b3IgbWFraW5nIHRoaXMgQVBJIGNhbGwuCgoNCgUGAAIIARIElQEGGAoNCgUGAAIIAhIElQEZ
QAoNCgUGAAIIAxIElgEPNwoPCgUGAAIIBBIGlwEEmgEGChMKCQYAAggEsMq8IhIGlwEEmgEG
Cg0KBQYAAggEEgSbAQRCChAKCAYAAggEmwgAEgSbAQRCCpkBCgIEABIGoQEA0gEBGooBIEEg
VGFnVmFsdWUgaXMgYSBjaGlsZCBvZiBhIHBhcnRpY3VsYXIgVGFnS2V5LiBUaGlzIGlzIHVz
ZWQgdG8gZ3JvdXAKIGNsb3VkIHJlc291cmNlcyBmb3IgdGhlIHB1cnBvc2Ugb2YgY29udHJv
bGxpbmcgdGhlbSB1c2luZyBwb2xpY2llcy4KCgsKAwQAARIEoQEIEAoNCgMEAAcSBqIBAqYB
BAoPCgUEAAedCBIGogECpgEEClQKBAQAAgASBKkBAjwaRiBJbW11dGFibGUuIFJlc291cmNl
IG5hbWUgZm9yIFRhZ1ZhbHVlIGluIHRoZSBmb3JtYXQgYHRhZ1ZhbHVlcy80NTZgLgoKDQoF
BAACAAUSBKkBAggKDQoFBAACAAESBKkBCQ0KDQoFBAACAAMSBKkBEBEKDQoFBAACAAgSBKkB
EjsKEAoIBAACAAicCAASBKkBEzoKfgoEBAACARIErQECPhpwIEltbXV0YWJsZS4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIG5ldyBUYWdWYWx1ZSdzIHBhcmVudCBUYWdLZXkuCiBNdXN0
IGJlIG9mIHRoZSBmb3JtIGB0YWdLZXlzL3t0YWdfa2V5X2lkfWAuCgoNCgUEAAIBBRIErQEC
CAoNCgUEAAIBARIErQEJDwoNCgUEAAIBAxIErQESEwoNCgUEAAIBCBIErQEUPQoQCggEAAIB
CJwIABIErQEVPArXAgoEBAACAhIGtQECuAEEGsYCIFJlcXVpcmVkLiBJbW11dGFibGUuIFVz
ZXItYXNzaWduZWQgc2hvcnQgbmFtZSBmb3IgVGFnVmFsdWUuIFRoZSBzaG9ydCBuYW1lCiBz
aG91bGQgYmUgdW5pcXVlIGZvciBUYWdWYWx1ZXMgd2l0aGluIHRoZSBzYW1lIHBhcmVudCBU
YWdLZXkuCgogVGhlIHNob3J0IG5hbWUgbXVzdCBiZSA2MyBjaGFyYWN0ZXJzIG9yIGxlc3Ms
IGJlZ2lubmluZyBhbmQgZW5kaW5nIHdpdGgKIGFuIGFscGhhbnVtZXJpYyBjaGFyYWN0ZXIg
KFthLXowLTlBLVpdKSB3aXRoIGRhc2hlcyAoLSksIHVuZGVyc2NvcmVzIChfKSwKIGRvdHMg
KC4pLCBhbmQgYWxwaGFudW1lcmljcyBiZXR3ZWVuLgoKDQoFBAACAgUSBLUBAggKDQoFBAAC
AgESBLUBCRMKDQoFBAACAgMSBLUBFhcKDwoFBAACAggSBrUBGLgBAwoQCggEAAICCJwIABIE
tgEEKgoQCggEAAICCJwIARIEtwEEKwqZAgoEBAACAxIEvgECSRqKAiBPdXRwdXQgb25seS4g
VGhlIG5hbWVzcGFjZWQgbmFtZSBvZiB0aGUgVGFnVmFsdWUuIENhbiBiZSBpbiB0aGUgZm9y
bQogYHtvcmdhbml6YXRpb25faWR9L3t0YWdfa2V5X3Nob3J0X25hbWV9L3t0YWdfdmFsdWVf
c2hvcnRfbmFtZX1gIG9yCiBge3Byb2plY3RfaWR9L3t0YWdfa2V5X3Nob3J0X25hbWV9L3t0
YWdfdmFsdWVfc2hvcnRfbmFtZX1gIG9yCiBge3Byb2plY3RfbnVtYmVyfS97dGFnX2tleV9z
aG9ydF9uYW1lfS97dGFnX3ZhbHVlX3Nob3J0X25hbWV9YC4KCg0KBQQAAgMFEgS+AQIICg0K
BQQAAgMBEgS+AQkYCg0KBQQAAgMDEgS+ARscCg0KBQQAAgMIEgS+AR1IChAKCAQAAgMInAgA
EgS+AR5HCnMKBAQAAgQSBMQBAkIaZSBPcHRpb25hbC4gVXNlci1hc3NpZ25lZCBkZXNjcmlw
dGlvbiBvZiB0aGUgVGFnVmFsdWUuCiBNdXN0IG5vdCBleGNlZWQgMjU2IGNoYXJhY3RlcnMu
CgogUmVhZC13cml0ZS4KCg0KBQQAAgQFEgTEAQIICg0KBQQAAgQBEgTEAQkUCg0KBQQAAgQD
EgTEARcYCg0KBQQAAgQIEgTEARlBChAKCAQAAgQInAgAEgTEARpACi0KBAQAAgUSBscBAsgB
MhodIE91dHB1dCBvbmx5LiBDcmVhdGlvbiB0aW1lLgoKDQoFBAACBQYSBMcBAhsKDQoFBAAC
BQESBMcBHCcKDQoFBAACBQMSBMcBKisKDQoFBAACBQgSBMgBBjEKEAoIBAACBQicCAASBMgB
BzAKKwoEBAACBhIGywECzAEyGhsgT3V0cHV0IG9ubHkuIFVwZGF0ZSB0aW1lLgoKDQoFBAAC
BgYSBMsBAhsKDQoFBAACBgESBMsBHCcKDQoFBAACBgMSBMsBKisKDQoFBAACBggSBMwBBjEK
EAoIBAACBgicCAASBMwBBzAKrQEKBAQAAgcSBNEBAjsangEgT3B0aW9uYWwuIEVudGl0eSB0
YWcgd2hpY2ggdXNlcnMgY2FuIHBhc3MgdG8gcHJldmVudCByYWNlIGNvbmRpdGlvbnMuIFRo
aXMKIGZpZWxkIGlzIGFsd2F5cyBzZXQgaW4gc2VydmVyIHJlc3BvbnNlcy4gU2VlIFVwZGF0
ZVRhZ1ZhbHVlUmVxdWVzdCBmb3IKIGRldGFpbHMuCgoNCgUEAAIHBRIE0QECCAoNCgUEAAIH
ARIE0QEJDQoNCgUEAAIHAxIE0QEQEQoNCgUEAAIHCBIE0QESOgoQCggEAAIHCJwIABIE0QET
OQqzAQoCBAESBtcBAOYBARqkASBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBsaXN0aW5nIFRh
Z1ZhbHVlcyBmb3IgdGhlIHNwZWNpZmllZCBUYWdLZXkuCiBSZXNvdXJjZSBuYW1lIGZvciBU
YWdLZXksIHBhcmVudCBvZiB0aGUgVGFnVmFsdWVzIHRvIGJlIGxpc3RlZCwKIGluIHRoZSBm
b3JtYXQgYHRhZ0tleXMvMTIzYC4KCgsKAwQBARIE1wEIHAobCgQEAQIAEgbZAQLcAQQaCyBS
ZXF1aXJlZC4KCg0KBQQBAgAFEgTZAQIICg0KBQQBAgABEgTZAQkPCg0KBQQBAgADEgTZARIT
Cg8KBQQBAgAIEgbZARTcAQMKEAoIBAECAAicCAASBNoBBCoKDwoHBAECAAifCBIE2wEEOQrH
AQoEBAECARIE4QECPxq4ASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIFRhZ1Zh
bHVlcyB0byByZXR1cm4gaW4gdGhlIHJlc3BvbnNlLiBUaGUKIHNlcnZlciBhbGxvd3MgYSBt
YXhpbXVtIG9mIDMwMCBUYWdWYWx1ZXMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwgdGhl
CiBzZXJ2ZXIgd2lsbCB1c2UgMTAwIGFzIHRoZSBkZWZhdWx0LgoKDQoFBAECAQUSBOEBAgcK
DQoFBAECAQESBOEBCBEKDQoFBAECAQMSBOEBFBUKDQoFBAECAQgSBOEBFj4KEAoIBAECAQic
CAASBOEBFz0KlwEKBAQBAgISBOUBAkEaiAEgT3B0aW9uYWwuIEEgcGFnaW5hdGlvbiB0b2tl
biByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgY2FsbCB0bwogYExpc3RUYWdWYWx1ZXNgIHRo
YXQgaW5kaWNhdGVzIHdoZXJlIHRoaXMgbGlzdGluZyBzaG91bGQgY29udGludWUgZnJvbS4K
Cg0KBQQBAgIFEgTlAQIICg0KBQQBAgIBEgTlAQkTCg0KBQQBAgIDEgTlARYXCg0KBQQBAgII
EgTlARhAChAKCAQBAgIInAgAEgTlARk/CisKAgQCEgbpAQDyAQEaHSBUaGUgTGlzdFRhZ1Zh
bHVlcyByZXNwb25zZS4KCgsKAwQCARIE6QEIHQpzCgQEAgIAEgTsAQIjGmUgQSBwb3NzaWJs
eSBwYWdpbmF0ZWQgbGlzdCBvZiBUYWdWYWx1ZXMgdGhhdCBhcmUgZGlyZWN0IGRlc2NlbmRh
bnRzIG9mCiB0aGUgc3BlY2lmaWVkIHBhcmVudCBUYWdLZXkuCgoNCgUEAgIABBIE7AECCgoN
CgUEAgIABhIE7AELEwoNCgUEAgIAARIE7AEUHgoNCgUEAgIAAxIE7AEhIgrkAQoEBAICARIE
8QECHRrVASBBIHBhZ2luYXRpb24gdG9rZW4gcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGNh
bGwgdG8gYExpc3RUYWdWYWx1ZXNgCiB0aGF0IGluZGljYXRlcyBmcm9tIHdoZXJlIGxpc3Rp
bmcgc2hvdWxkIGNvbnRpbnVlLiBUaGlzIGlzIGN1cnJlbnRseSBub3QKIHVzZWQsIGJ1dCB0
aGUgc2VydmVyIG1heSBhdCBhbnkgcG9pbnQgc3RhcnQgc3VwcGx5aW5nIGEgdmFsaWQgdG9r
ZW4uCgoNCgUEAgIBBRIE8QECCAoNCgUEAgIBARIE8QEJGAoNCgUEAgIBAxIE8QEbHAo7CgIE
AxIG9QEA/gEBGi0gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgZ2V0dGluZyBhIFRhZ1ZhbHVl
LgoKCwoDBAMBEgT1AQgaCmQKBAQDAgASBvgBAv0BBBpUIFJlcXVpcmVkLiBSZXNvdXJjZSBu
YW1lIGZvciBUYWdWYWx1ZSB0byBiZSBmZXRjaGVkIGluIHRoZSBmb3JtYXQKIGB0YWdWYWx1
ZXMvNDU2YC4KCg0KBQQDAgAFEgT4AQIICg0KBQQDAgABEgT4AQkNCg0KBQQDAgADEgT4ARAR
Cg8KBQQDAgAIEgb4ARL9AQMKEAoIBAMCAAicCAASBPkBBCoKEQoHBAMCAAifCBIG+gEE/AEF
ClIKAgQEEgaBAgCRAgEaRCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBnZXR0aW5nIGEgVGFn
VmFsdWUgYnkgaXRzIG5hbWVzcGFjZWQgbmFtZS4KCgsKAwQEARIEgQIIJAqGAwoEBAQCABIG
iwICkAIEGvUCIFJlcXVpcmVkLiBBIG5hbWVzcGFjZWQgdGFnIHZhbHVlIG5hbWUgaW4gdGhl
IGZvbGxvd2luZyBmb3JtYXQ6CgogICBge3BhcmVudElkfS97dGFnS2V5U2hvcnR9L3t0YWdW
YWx1ZVNob3J0fWAKCiBFeGFtcGxlczoKIC0gYDQyL2Zvby9hYmNgIGZvciBhIHZhbHVlIHdp
dGggc2hvcnQgbmFtZSAiYWJjIiB1bmRlciB0aGUga2V5IHdpdGggc2hvcnQKICAgbmFtZSAi
Zm9vIiB1bmRlciB0aGUgb3JnYW5pemF0aW9uIHdpdGggSUQgNDIKIC0gYHIyLWQyL2Jhci94
eXpgIGZvciBhIHZhbHVlIHdpdGggc2hvcnQgbmFtZSAieHl6IiB1bmRlciB0aGUga2V5IHdp
dGgKICAgIHNob3J0IG5hbWUgImJhciIgdW5kZXIgdGhlIHByb2plY3Qgd2l0aCBJRCAicjIt
ZDIiCgoNCgUEBAIABRIEiwICCAoNCgUEBAIAARIEiwIJDQoNCgUEBAIAAxIEiwIQEQoPCgUE
BAIACBIGiwISkAIDChAKCAQEAgAInAgAEgSMAgQqChEKBwQEAgAInwgSBo0CBI8CBQo8CgIE
BRIGlAIAnAIBGi4gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBUYWdWYWx1
ZS4KCgsKAwQFARIElAIIHQqZAQoEBAUCABIElwICQhqKASBSZXF1aXJlZC4gVGhlIFRhZ1Zh
bHVlIHRvIGJlIGNyZWF0ZWQuIE9ubHkgZmllbGRzIGBzaG9ydF9uYW1lYCwKIGBkZXNjcmlw
dGlvbmAsIGFuZCBgcGFyZW50YCBhcmUgY29uc2lkZXJlZCBkdXJpbmcgdGhlIGNyZWF0aW9u
IHJlcXVlc3QuCgoNCgUEBQIABhIElwICCgoNCgUEBQIAARIElwILFAoNCgUEBQIAAxIElwIX
GAoNCgUEBQIACBIElwIZQQoQCggEBQIACJwIABIElwIaQAqLAQoEBAUCARIEmwICQhp9IE9w
dGlvbmFsLiBTZXQgYXMgdHJ1ZSB0byBwZXJmb3JtIHRoZSB2YWxpZGF0aW9ucyBuZWNlc3Nh
cnkgZm9yIGNyZWF0aW5nIHRoZQogcmVzb3VyY2UsIGJ1dCBub3QgYWN0dWFsbHkgcGVyZm9y
bSB0aGUgYWN0aW9uLgoKDQoFBAUCAQUSBJsCAgYKDQoFBAUCAQESBJsCBxQKDQoFBAUCAQMS
BJsCFxgKDQoFBAUCAQgSBJsCGUEKEAoIBAUCAQicCAASBJsCGkAKRAoCBAYSBJ8CACEaOCBS
dW50aW1lIG9wZXJhdGlvbiBpbmZvcm1hdGlvbiBmb3IgY3JlYXRpbmcgYSBUYWdWYWx1ZS4K
CgsKAwQGARIEnwIIHgo8CgIEBxIGogIAsAIBGi4gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3Ig
dXBkYXRpbmcgYSBUYWdWYWx1ZS4KCgsKAwQHARIEogIIHQqSAgoEBAcCABIEpwICQhqDAiBS
ZXF1aXJlZC4gVGhlIG5ldyBkZWZpbml0aW9uIG9mIHRoZSBUYWdWYWx1ZS4gT25seSBmaWVs
ZHMgYGRlc2NyaXB0aW9uYCBhbmQKIGBldGFnYCBmaWVsZHMgY2FuIGJlIHVwZGF0ZWQgYnkg
dGhpcyByZXF1ZXN0LiBJZiB0aGUgYGV0YWdgIGZpZWxkIGlzCiBub25lbXB0eSwgaXQgbXVz
dCBtYXRjaCB0aGUgYGV0YWdgIGZpZWxkIG9mIHRoZSBleGlzdGluZyBDb250cm9sR3JvdXAu
CiBPdGhlcndpc2UsIGBBQk9SVEVEYCB3aWxsIGJlIHJldHVybmVkLgoKDQoFBAcCAAYSBKcC
AgoKDQoFBAcCAAESBKcCCxQKDQoFBAcCAAMSBKcCFxgKDQoFBAcCAAgSBKcCGUEKEAoIBAcC
AAicCAASBKcCGkAKMQoEBAcCARIGqgICqwIvGiEgT3B0aW9uYWwuIEZpZWxkcyB0byBiZSB1
cGRhdGVkLgoKDQoFBAcCAQYSBKoCAhsKDQoFBAcCAQESBKoCHCcKDQoFBAcCAQMSBKoCKisK
DQoFBAcCAQgSBKsCBi4KEAoIBAcCAQicCAASBKsCBy0KgAEKBAQHAgISBK8CAkIaciBPcHRp
b25hbC4gVHJ1ZSB0byBwZXJmb3JtIHZhbGlkYXRpb25zIG5lY2Vzc2FyeSBmb3IgdXBkYXRp
bmcgdGhlIHJlc291cmNlLAogYnV0IG5vdCBhY3R1YWxseSBwZXJmb3JtIHRoZSBhY3Rpb24u
CgoNCgUEBwICBRIErwICBgoNCgUEBwICARIErwIHFAoNCgUEBwICAxIErwIXGAoNCgUEBwIC
CBIErwIZQQoQCggEBwICCJwIABIErwIaQApECgIECBIEswIAIRo4IFJ1bnRpbWUgb3BlcmF0
aW9uIGluZm9ybWF0aW9uIGZvciB1cGRhdGluZyBhIFRhZ1ZhbHVlLgoKCwoDBAgBEgSzAgge
CjwKAgQJEga2AgDHAgEaLiBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIFRh
Z1ZhbHVlLgoKCwoDBAkBEgS2AggdCmIKBAQJAgASBrkCAr4CBBpSIFJlcXVpcmVkLiBSZXNv
dXJjZSBuYW1lIGZvciBUYWdWYWx1ZSB0byBiZSBkZWxldGVkIGluIHRoZSBmb3JtYXQKIHRh
Z1ZhbHVlcy80NTYuCgoNCgUECQIABRIEuQICCAoNCgUECQIAARIEuQIJDQoNCgUECQIAAxIE
uQIQEQoPCgUECQIACBIGuQISvgIDChAKCAQJAgAInAgAEgS6AgQqChEKBwQJAgAInwgSBrsC
BL0CBQp+CgQECQIBEgTCAgJCGnAgT3B0aW9uYWwuIFNldCBhcyB0cnVlIHRvIHBlcmZvcm0g
dGhlIHZhbGlkYXRpb25zIG5lY2Vzc2FyeSBmb3IgZGVsZXRpb24sCiBidXQgbm90IGFjdHVh
bGx5IHBlcmZvcm0gdGhlIGFjdGlvbi4KCg0KBQQJAgEFEgTCAgIGCg0KBQQJAgEBEgTCAgcU
Cg0KBQQJAgEDEgTCAhcYCg0KBQQJAgEIEgTCAhlBChAKCAQJAgEInAgAEgTCAhpACo8BCgQE
CQICEgTGAgI7GoABIE9wdGlvbmFsLiBUaGUgZXRhZyBrbm93biB0byB0aGUgY2xpZW50IGZv
ciB0aGUgZXhwZWN0ZWQgc3RhdGUgb2YgdGhlCiBUYWdWYWx1ZS4gVGhpcyBpcyB0byBiZSB1
c2VkIGZvciBvcHRpbWlzdGljIGNvbmN1cnJlbmN5LgoKDQoFBAkCAgUSBMYCAggKDQoFBAkC
AgESBMYCCQ0KDQoFBAkCAgMSBMYCEBEKDQoFBAkCAggSBMYCEjoKEAoIBAkCAgicCAASBMYC
EzkKRAoCBAoSBMoCACEaOCBSdW50aW1lIG9wZXJhdGlvbiBpbmZvcm1hdGlvbiBmb3IgZGVs
ZXRpbmcgYSBUYWdWYWx1ZS4KCgsKAwQKARIEygIIHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::TagValue ===
    # Fields for TagValue
    # Field: name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: short_name Type: 9 ()
    # Field: namespaced_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest ===
    # Fields for ListTagValuesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse ===
    # Fields for ListTagValuesResponse
    # Field: tag_values Type: 11 (.google.cloud.resourcemanager.v3.TagValue)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest ===
    # Fields for GetTagValueRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest ===
    # Fields for GetNamespacedTagValueRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest ===
    # Fields for CreateTagValueRequest
    # Field: tag_value Type: 11 (.google.cloud.resourcemanager.v3.TagValue)
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueMetadata ===
    # Fields for CreateTagValueMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest ===
    # Fields for UpdateTagValueRequest
    # Field: tag_value Type: 11 (.google.cloud.resourcemanager.v3.TagValue)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueMetadata ===
    # Fields for UpdateTagValueMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest ===
    # Fields for DeleteTagValueRequest
    # Field: name Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueMetadata ===
    # Fields for DeleteTagValueMetadata

# === Service Client: Google::Cloud::Resourcemanager::V3::TagValues::TagValuesClient ===
package Google::Cloud::Resourcemanager::V3::TagValues::TagValuesClient;

=pod

=head2 Service Client: Google::Cloud::Resourcemanager::V3::TagValues::TagValuesClient

Client stub representing the remote C<TagValues> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<resourcemanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'resourcemanager.googleapis.com:443' );

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

sub list_tag_values {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'ListTagValues',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse',
    });
}

sub get_tag_value {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'GetTagValue',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue',
    });
}

sub get_namespaced_tag_value {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'GetNamespacedTagValue',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue',
    });
}

sub create_tag_value {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'CreateTagValue',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_tag_value {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'UpdateTagValue',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_tag_value {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'DeleteTagValue',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
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
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagValues - Compiled Protocol Buffers messages for google/cloud/resourcemanager/v3/tag_values.proto

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::TagValues;

    my $msg = Google::Cloud::Resourcemanager::V3::TagValues::TagValue->new({
        name => $name,
        parent => $parent,
        short_name => $short_name,
        namespaced_name => $namespaced_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Resourcemanager::V3::TagValues::TagValue->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/resourcemanager/v3/tag_values.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Resourcemanager::V3::TagValues::TagValue

A TagValue is a child of a particular TagKey. This is used to group
cloud resources for the purpose of controlling them using policies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Resource name for TagValue in the format `tagValues/456`.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Immutable. The resource name of the new TagValue's parent TagKey.
Must be of the form `tagKeys/{tag_key_id}`.

=item * C<< $msg->short_name() >> / C<< $msg->short_name($value) >>

Type: C<String>

Required. Immutable. User-assigned short name for TagValue. The short name
should be unique for TagValues within the same parent TagKey.

The short name must be 63 characters or less, beginning and ending with
an alphanumeric character ([a-z0-9A-Z]) with dashes (-), underscores (_),
dots (.), and alphanumerics between.

=item * C<< $msg->namespaced_name() >> / C<< $msg->namespaced_name($value) >>

Type: C<String>

Output only. The namespaced name of the TagValue. Can be in the form
`{organization_id}/{tag_key_short_name}/{tag_value_short_name}` or
`{project_id}/{tag_key_short_name}/{tag_value_short_name}` or
`{project_number}/{tag_key_short_name}/{tag_value_short_name}`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-assigned description of the TagValue.
Must not exceed 256 characters.

Read-write.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. Entity tag which users can pass to prevent race conditions. This
field is always set in server responses. See UpdateTagValueRequest for
details.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest

The request message for listing TagValues for the specified TagKey.
Resource name for TagKey, parent of the TagValues to be listed,
in the format `tagKeys/123`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of TagValues to return in the response. The
server allows a maximum of 300 TagValues to return. If unspecified, the
server will use 100 as the default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to
`ListTagValues` that indicates where this listing should continue from.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse

The ListTagValues response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_values() >> / C<< $msg->tag_values($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>)

A possibly paginated list of TagValues that are direct descendants of
the specified parent TagKey.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to `ListTagValues`
that indicates from where listing should continue. This is currently not
used, but the server may at any point start supplying a valid token.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest

The request message for getting a TagValue.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name for TagValue to be fetched in the format
`tagValues/456`.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest

The request message for getting a TagValue by its namespaced name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A namespaced tag value name in the following format:

  `{parentId}/{tagKeyShort}/{tagValueShort}`

Examples:
- `42/foo/abc` for a value with short name "abc" under the key with short
  name "foo" under the organization with ID 42
- `r2-d2/bar/xyz` for a value with short name "xyz" under the key with
   short name "bar" under the project with ID "r2-d2"

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest

The request message for creating a TagValue.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_value() >> / C<< $msg->tag_value($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>)

Required. The TagValue to be created. Only fields `short_name`,
`description`, and `parent` are considered during the creation request.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set as true to perform the validations necessary for creating the
resource, but not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueMetadata

Runtime operation information for creating a TagValue.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest

The request message for updating a TagValue.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_value() >> / C<< $msg->tag_value($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>)

Required. The new definition of the TagValue. Only fields `description` and
`etag` fields can be updated by this request. If the `etag` field is
nonempty, it must match the `etag` field of the existing ControlGroup.
Otherwise, `ABORTED` will be returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Fields to be updated.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. True to perform validations necessary for updating the resource,
but not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueMetadata

Runtime operation information for updating a TagValue.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest

The request message for deleting a TagValue.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name for TagValue to be deleted in the format
tagValues/456.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set as true to perform the validations necessary for deletion,
but not actually perform the action.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag known to the client for the expected state of the
TagValue. This is to be used for optimistic concurrency.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueMetadata

Runtime operation information for deleting a TagValue.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Resourcemanager::V3::TagValues::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
