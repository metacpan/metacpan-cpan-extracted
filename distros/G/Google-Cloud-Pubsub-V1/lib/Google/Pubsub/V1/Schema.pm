package Google::Pubsub::V1::Schema;

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
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ch1nb29nbGUvcHVic3ViL3YxL3NjaGVtYS5wcm90bxIQZ29vZ2xlLnB1YnN1Yi52MRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byLoAwoGU2NoZW1hEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIxCgR0eXBl
GAIgASgOMh0uZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWEuVHlwZVIEdHlwZRIeCgpkZWZpbml0
aW9uGAMgASgJUgpkZWZpbml0aW9uEmAKFWNvbXBpbGVkX3Byb3RvX3NjaGVtYRgIIAEoCzIl
Lmdvb2dsZS5wdWJzdWIudjEuQ29tcGlsZWRQcm90b1NjaGVtYUID4EEBSABSE2NvbXBpbGVk
UHJvdG9TY2hlbWESJwoLcmV2aXNpb25faWQYBCABKAlCBuBBBeBBA1IKcmV2aXNpb25JZBJR
ChRyZXZpc2lvbl9jcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IScmV2aXNpb25DcmVhdGVUaW1lIjsKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklF
RBAAEhMKD1BST1RPQ09MX0JVRkZFUhABEggKBEFWUk8QAjpG6kFDChxwdWJzdWIuZ29vZ2xl
YXBpcy5jb20vU2NoZW1hEiNwcm9qZWN0cy97cHJvamVjdH0vc2NoZW1hcy97c2NoZW1hfUIP
Cg1jb25maWd1cmF0aW9uIqcBChNDcmVhdGVTY2hlbWFSZXF1ZXN0EjwKBnBhcmVudBgBIAEo
CUIk4EEC+kEeEhxwdWJzdWIuZ29vZ2xlYXBpcy5jb20vU2NoZW1hUgZwYXJlbnQSNQoGc2No
ZW1hGAIgASgLMhguZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWFCA+BBAlIGc2NoZW1hEhsKCXNj
aGVtYV9pZBgDIAEoCVIIc2NoZW1hSWQifgoQR2V0U2NoZW1hUmVxdWVzdBI4CgRuYW1lGAEg
ASgJQiTgQQL6QR4KHHB1YnN1Yi5nb29nbGVhcGlzLmNvbS9TY2hlbWFSBG5hbWUSMAoEdmll
dxgCIAEoDjIcLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1hVmlld1IEdmlldyLPAQoSTGlzdFNj
aGVtYXNSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFu
YWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSMAoEdmlldxgCIAEoDjIcLmdv
b2dsZS5wdWJzdWIudjEuU2NoZW1hVmlld1IEdmlldxIbCglwYWdlX3NpemUYAyABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YBCABKAlSCXBhZ2VUb2tlbiJxChNMaXN0U2NoZW1hc1Jl
c3BvbnNlEjIKB3NjaGVtYXMYASADKAsyGC5nb29nbGUucHVic3ViLnYxLlNjaGVtYVIHc2No
ZW1hcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4ixAEKGkxpc3RT
Y2hlbWFSZXZpc2lvbnNSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccHVic3ViLmdv
b2dsZWFwaXMuY29tL1NjaGVtYVIEbmFtZRIwCgR2aWV3GAIgASgOMhwuZ29vZ2xlLnB1YnN1
Yi52MS5TY2hlbWFWaWV3UgR2aWV3EhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSHQoK
cGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2VuInkKG0xpc3RTY2hlbWFSZXZpc2lvbnNSZXNw
b25zZRIyCgdzY2hlbWFzGAEgAygLMhguZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWFSB3NjaGVt
YXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIoYBChNDb21taXRT
Y2hlbWFSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccHVic3ViLmdvb2dsZWFwaXMu
Y29tL1NjaGVtYVIEbmFtZRI1CgZzY2hlbWEYAiABKAsyGC5nb29nbGUucHVic3ViLnYxLlNj
aGVtYUID4EECUgZzY2hlbWEidwoVUm9sbGJhY2tTY2hlbWFSZXF1ZXN0EjgKBG5hbWUYASAB
KAlCJOBBAvpBHgoccHVic3ViLmdvb2dsZWFwaXMuY29tL1NjaGVtYVIEbmFtZRIkCgtyZXZp
c2lvbl9pZBgCIAEoCUID4EECUgpyZXZpc2lvbklkIn8KG0RlbGV0ZVNjaGVtYVJldmlzaW9u
UmVxdWVzdBI4CgRuYW1lGAEgASgJQiTgQQL6QR4KHHB1YnN1Yi5nb29nbGVhcGlzLmNvbS9T
Y2hlbWFSBG5hbWUSJgoLcmV2aXNpb25faWQYAiABKAlCBRgB4EEBUgpyZXZpc2lvbklkIk8K
E0RlbGV0ZVNjaGVtYVJlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxwdWJzdWIuZ29v
Z2xlYXBpcy5jb20vU2NoZW1hUgRuYW1lIpsBChVWYWxpZGF0ZVNjaGVtYVJlcXVlc3QSSwoG
cGFyZW50GAEgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMu
Y29tL1Byb2plY3RSBnBhcmVudBI1CgZzY2hlbWEYAiABKAsyGC5nb29nbGUucHVic3ViLnYx
LlNjaGVtYUID4EECUgZzY2hlbWEiGAoWVmFsaWRhdGVTY2hlbWFSZXNwb25zZSKzAgoWVmFs
aWRhdGVNZXNzYWdlUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNv
dXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFIGcGFyZW50EjcKBG5hbWUYAiAB
KAlCIfpBHgoccHVic3ViLmdvb2dsZWFwaXMuY29tL1NjaGVtYUgAUgRuYW1lEjIKBnNjaGVt
YRgDIAEoCzIYLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1hSABSBnNjaGVtYRIYCgdtZXNzYWdl
GAQgASgMUgdtZXNzYWdlEjYKCGVuY29kaW5nGAUgASgOMhouZ29vZ2xlLnB1YnN1Yi52MS5F
bmNvZGluZ1IIZW5jb2RpbmdCDQoLc2NoZW1hX3NwZWMiGQoXVmFsaWRhdGVNZXNzYWdlUmVz
cG9uc2UiaQoTQ29tcGlsZWRQcm90b1NjaGVtYRImCgxyb290X21lc3NhZ2UYASABKAlCA+BB
AlILcm9vdE1lc3NhZ2USKgoOY29tcGlsZWRfYnl0ZXMYAiABKAxCA+BBAlINY29tcGlsZWRC
eXRlcyo+CgpTY2hlbWFWaWV3EhsKF1NDSEVNQV9WSUVXX1VOU1BFQ0lGSUVEEAASCQoFQkFT
SUMQARIICgRGVUxMEAIqOgoIRW5jb2RpbmcSGAoURU5DT0RJTkdfVU5TUEVDSUZJRUQQABII
CgRKU09OEAESCgoGQklOQVJZEAIyiA0KDVNjaGVtYVNlcnZpY2USmgEKDENyZWF0ZVNjaGVt
YRIlLmdvb2dsZS5wdWJzdWIudjEuQ3JlYXRlU2NoZW1hUmVxdWVzdBoYLmdvb2dsZS5wdWJz
dWIudjEuU2NoZW1hIkmC0+STAikiHy92MS97cGFyZW50PXByb2plY3RzLyp9L3NjaGVtYXM6
BnNjaGVtYdpBF3BhcmVudCxzY2hlbWEsc2NoZW1hX2lkEnkKCUdldFNjaGVtYRIiLmdvb2ds
ZS5wdWJzdWIudjEuR2V0U2NoZW1hUmVxdWVzdBoYLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1h
Ii6C0+STAiESHy92MS97bmFtZT1wcm9qZWN0cy8qL3NjaGVtYXMvKn3aQQRuYW1lEowBCgtM
aXN0U2NoZW1hcxIkLmdvb2dsZS5wdWJzdWIudjEuTGlzdFNjaGVtYXNSZXF1ZXN0GiUuZ29v
Z2xlLnB1YnN1Yi52MS5MaXN0U2NoZW1hc1Jlc3BvbnNlIjCC0+STAiESHy92MS97cGFyZW50
PXByb2plY3RzLyp9L3NjaGVtYXPaQQZwYXJlbnQSsAEKE0xpc3RTY2hlbWFSZXZpc2lvbnMS
LC5nb29nbGUucHVic3ViLnYxLkxpc3RTY2hlbWFSZXZpc2lvbnNSZXF1ZXN0Gi0uZ29vZ2xl
LnB1YnN1Yi52MS5MaXN0U2NoZW1hUmV2aXNpb25zUmVzcG9uc2UiPILT5JMCLxItL3YxL3tu
YW1lPXByb2plY3RzLyovc2NoZW1hcy8qfTpsaXN0UmV2aXNpb25z2kEEbmFtZRKQAQoMQ29t
bWl0U2NoZW1hEiUuZ29vZ2xlLnB1YnN1Yi52MS5Db21taXRTY2hlbWFSZXF1ZXN0GhguZ29v
Z2xlLnB1YnN1Yi52MS5TY2hlbWEiP4LT5JMCKyImL3YxL3tuYW1lPXByb2plY3RzLyovc2No
ZW1hcy8qfTpjb21taXQ6ASraQQtuYW1lLHNjaGVtYRKbAQoOUm9sbGJhY2tTY2hlbWESJy5n
b29nbGUucHVic3ViLnYxLlJvbGxiYWNrU2NoZW1hUmVxdWVzdBoYLmdvb2dsZS5wdWJzdWIu
djEuU2NoZW1hIkaC0+STAi0iKC92MS97bmFtZT1wcm9qZWN0cy8qL3NjaGVtYXMvKn06cm9s
bGJhY2s6ASraQRBuYW1lLHJldmlzaW9uX2lkEqoBChREZWxldGVTY2hlbWFSZXZpc2lvbhIt
Lmdvb2dsZS5wdWJzdWIudjEuRGVsZXRlU2NoZW1hUmV2aXNpb25SZXF1ZXN0GhguZ29vZ2xl
LnB1YnN1Yi52MS5TY2hlbWEiSYLT5JMCMCouL3YxL3tuYW1lPXByb2plY3RzLyovc2NoZW1h
cy8qfTpkZWxldGVSZXZpc2lvbtpBEG5hbWUscmV2aXNpb25faWQSfQoMRGVsZXRlU2NoZW1h
EiUuZ29vZ2xlLnB1YnN1Yi52MS5EZWxldGVTY2hlbWFSZXF1ZXN0GhYuZ29vZ2xlLnByb3Rv
YnVmLkVtcHR5Ii6C0+STAiEqHy92MS97bmFtZT1wcm9qZWN0cy8qL3NjaGVtYXMvKn3aQQRu
YW1lEqgBCg5WYWxpZGF0ZVNjaGVtYRInLmdvb2dsZS5wdWJzdWIudjEuVmFsaWRhdGVTY2hl
bWFSZXF1ZXN0GiguZ29vZ2xlLnB1YnN1Yi52MS5WYWxpZGF0ZVNjaGVtYVJlc3BvbnNlIkOC
0+STAi0iKC92MS97cGFyZW50PXByb2plY3RzLyp9L3NjaGVtYXM6dmFsaWRhdGU6ASraQQ1w
YXJlbnQsc2NoZW1hEqIBCg9WYWxpZGF0ZU1lc3NhZ2USKC5nb29nbGUucHVic3ViLnYxLlZh
bGlkYXRlTWVzc2FnZVJlcXVlc3QaKS5nb29nbGUucHVic3ViLnYxLlZhbGlkYXRlTWVzc2Fn
ZVJlc3BvbnNlIjqC0+STAjQiLy92MS97cGFyZW50PXByb2plY3RzLyp9L3NjaGVtYXM6dmFs
aWRhdGVNZXNzYWdlOgEqGnDKQRVwdWJzdWIuZ29vZ2xlYXBpcy5jb23SQVVodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvcHVic3ViQqoBChRjb20uZ29vZ2xlLnB1YnN1Yi52MUILU2NoZW1h
UHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9wdWJzdWIvdjIvYXBpdjEvcHVic3VicGI7
cHVic3VicGKqAhZHb29nbGUuQ2xvdWQuUHViU3ViLlYxygIWR29vZ2xlXENsb3VkXFB1YlN1
YlxWMeoCGUdvb2dsZTo6Q2xvdWQ6OlB1YlN1Yjo6VjFK1l8KBxIFDgCtAwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABkKCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAlCgkKAgMFEgMXACkKCAoBCBID
GQAzCgkKAgglEgMZADMKCAoBCBIDGgBMCgkKAggLEgMaAEwKCAoBCBIDGwAiCgkKAggKEgMb
ACIKCAoBCBIDHAAsCgkKAggIEgMcACwKCAoBCBIDHQAtCgkKAggBEgMdAC0KCAoBCBIDHgAz
CgkKAggpEgMeADMKCAoBCBIDHwAyCgkKAggtEgMfADIKOgoCBgASBCIAfQEaLiBTZXJ2aWNl
IGZvciBkb2luZyBzY2hlbWEtcmVsYXRlZCBvcGVyYXRpb25zLgoKCgoDBgABEgMiCBUKCgoD
BgADEgMjAj0KDAoFBgADmQgSAyMCPQoLCgMGAAMSBCQCJi8KDQoFBgADmggSBCQCJi8KIQoE
BgACABIEKQIvAxoTIENyZWF0ZXMgYSBzY2hlbWEuCgoMCgUGAAIAARIDKQYSCgwKBQYAAgAC
EgMpEyYKDAoFBgACAAMSAykxNwoNCgUGAAIABBIEKgQtBgoRCgkGAAIABLDKvCISBCoELQYK
DAoFBgACAAQSAy4ERQoPCggGAAIABJsIABIDLgRFCh4KBAYAAgESBDICNwMaECBHZXRzIGEg
c2NoZW1hLgoKDAoFBgACAQESAzIGDwoMCgUGAAIBAhIDMhAgCgwKBQYAAgEDEgMyKzEKDQoF
BgACAQQSBDMENQYKEQoJBgACAQSwyrwiEgQzBDUGCgwKBQYAAgEEEgM2BDIKDwoIBgACAQSb
CAASAzYEMgorCgQGAAICEgQ6Aj8DGh0gTGlzdHMgc2NoZW1hcyBpbiBhIHByb2plY3QuCgoM
CgUGAAICARIDOgYRCgwKBQYAAgICEgM6EiQKDAoFBgACAgMSAzovQgoNCgUGAAICBBIEOwQ9
BgoRCgkGAAICBLDKvCISBDsEPQYKDAoFBgACAgQSAz4ENAoPCggGAAICBJsIABIDPgQ0CkAK
BAYAAgMSBEICSAMaMiBMaXN0cyBhbGwgc2NoZW1hIHJldmlzaW9ucyBmb3IgdGhlIG5hbWVk
IHNjaGVtYS4KCgwKBQYAAgMBEgNCBhkKDAoFBgACAwISA0IaNAoMCgUGAAIDAxIDQw8qCg0K
BQYAAgMEEgREBEYGChEKCQYAAgMEsMq8IhIERARGBgoMCgUGAAIDBBIDRwQyCg8KCAYAAgME
mwgAEgNHBDIKRAoEBgACBBIESwJRAxo2IENvbW1pdHMgYSBuZXcgc2NoZW1hIHJldmlzaW9u
IHRvIGFuIGV4aXN0aW5nIHNjaGVtYS4KCgwKBQYAAgQBEgNLBhIKDAoFBgACBAISA0sTJgoM
CgUGAAIEAxIDSzE3Cg0KBQYAAgQEEgRMBE8GChEKCQYAAgQEsMq8IhIETARPBgoMCgUGAAIE
BBIDUAQ5Cg8KCAYAAgQEmwgAEgNQBDkKWQoEBgACBRIEVAJaAxpLIENyZWF0ZXMgYSBuZXcg
c2NoZW1hIHJldmlzaW9uIHRoYXQgaXMgYSBjb3B5IG9mIHRoZSBwcm92aWRlZCByZXZpc2lv
bl9pZC4KCgwKBQYAAgUBEgNUBhQKDAoFBgACBQISA1QVKgoMCgUGAAIFAxIDVDU7Cg0KBQYA
AgUEEgRVBFgGChEKCQYAAgUEsMq8IhIEVQRYBgoMCgUGAAIFBBIDWQQ+Cg8KCAYAAgUEmwgA
EgNZBD4KMwoEBgACBhIEXQJiAxolIERlbGV0ZXMgYSBzcGVjaWZpYyBzY2hlbWEgcmV2aXNp
b24uCgoMCgUGAAIGARIDXQYaCgwKBQYAAgYCEgNdGzYKDAoFBgACBgMSA11BRwoNCgUGAAIG
BBIEXgRgBgoRCgkGAAIGBLDKvCISBF4EYAYKDAoFBgACBgQSA2EEPgoPCggGAAIGBJsIABID
YQQ+CiEKBAYAAgcSBGUCagMaEyBEZWxldGVzIGEgc2NoZW1hLgoKDAoFBgACBwESA2UGEgoM
CgUGAAIHAhIDZRMmCgwKBQYAAgcDEgNlMUYKDQoFBgACBwQSBGYEaAYKEQoJBgACBwSwyrwi
EgRmBGgGCgwKBQYAAgcEEgNpBDIKDwoIBgACBwSbCAASA2kEMgojCgQGAAIIEgRtAnMDGhUg
VmFsaWRhdGVzIGEgc2NoZW1hLgoKDAoFBgACCAESA20GFAoMCgUGAAIIAhIDbRUqCgwKBQYA
AggDEgNtNUsKDQoFBgACCAQSBG4EcQYKEQoJBgACCASwyrwiEgRuBHEGCgwKBQYAAggEEgNy
BDsKDwoIBgACCASbCAASA3IEOwo1CgQGAAIJEgR2AnwDGicgVmFsaWRhdGVzIGEgbWVzc2Fn
ZSBhZ2FpbnN0IGEgc2NoZW1hLgoKDAoFBgACCQESA3YGFQoMCgUGAAIJAhIDdhYsCgwKBQYA
AgkDEgN3DyYKDQoFBgACCQQSBHgEewYKEQoJBgACCQSwyrwiEgR4BHsGCiIKAgQAEgaAAQCz
AQEaFCBBIHNjaGVtYSByZXNvdXJjZS4KCgsKAwQAARIEgAEIDgoNCgMEAAcSBoEBAoQBBAoP
CgUEAAedCBIGgQEChAEECjMKBAQABAASBocBApABAxojIFBvc3NpYmxlIHNjaGVtYSBkZWZp
bml0aW9uIHR5cGVzLgoKDQoFBAAEAAESBIcBBwsKNgoGBAAEAAIAEgSJAQQZGiYgRGVmYXVs
dCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcEAAQAAgABEgSJAQQUCg8KBwQA
BAACAAISBIkBFxgKNgoGBAAEAAIBEgSMAQQYGiYgQSBQcm90b2NvbCBCdWZmZXIgc2NoZW1h
IGRlZmluaXRpb24uCgoPCgcEAAQAAgEBEgSMAQQTCg8KBwQABAACAQISBIwBFhcKLAoGBAAE
AAICEgSPAQQNGhwgQW4gQXZybyBzY2hlbWEgZGVmaW5pdGlvbi4KCg8KBwQABAACAgESBI8B
BAgKDwoHBAAEAAICAhIEjwELDApfCgQEAAIAEgSUAQI7GlEgUmVxdWlyZWQuIE5hbWUgb2Yg
dGhlIHNjaGVtYS4KIEZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3R9L3NjaGVtYXMve3Nj
aGVtYX1gLgoKDQoFBAACAAUSBJQBAggKDQoFBAACAAESBJQBCQ0KDQoFBAACAAMSBJQBEBEK
DQoFBAACAAgSBJQBEjoKEAoIBAACAAicCAASBJQBEzkKMgoEBAACARIElwECEBokIFRoZSB0
eXBlIG9mIHRoZSBzY2hlbWEgZGVmaW5pdGlvbi4KCg0KBQQAAgEGEgSXAQIGCg0KBQQAAgEB
EgSXAQcLCg0KBQQAAgEDEgSXAQ4PCr8BCgQEAAICEgScAQIYGrABIFRoZSBkZWZpbml0aW9u
IG9mIHRoZSBzY2hlbWEuIFRoaXMgc2hvdWxkIGNvbnRhaW4gYSBzdHJpbmcgcmVwcmVzZW50
aW5nCiB0aGUgZnVsbCBkZWZpbml0aW9uIG9mIHRoZSBzY2hlbWEgdGhhdCBpcyBhIHZhbGlk
IHNjaGVtYSBkZWZpbml0aW9uIG9mCiB0aGUgdHlwZSBzcGVjaWZpZWQgaW4gYHR5cGVgLgoK
DQoFBAACAgUSBJwBAggKDQoFBAACAgESBJwBCRMKDQoFBAACAgMSBJwBFhcK1gEKBAQACAAS
BqIBAqgBAxrFASBUaGUgY29uZmlndXJhdGlvbiBvZiB0aGUgc2NoZW1hLgogVGhpcyBmaWVs
ZCBpcyBtdXR1YWxseSBleGNsdXNpdmUgd2l0aCB0aGUgYGRlZmluaXRpb25gIGZpZWxkIGFi
b3ZlLCBtZWFuaW5nCiBlaXRoZXIgYGRlZmluaXRpb25gIG9yIG9uZSBvZiB0aGUgZmllbGRz
IGJlbG93IGNhbiBiZSBzZXQgaW4gYSB2YWxpZCBTY2hlbWEKIG9iamVjdC4KCg0KBQQACAAB
EgSiAQgVCq4BCgQEAAIDEgamAQSnATEanQEgT3B0aW9uYWwuIENvbmZpZ3VyYXRpb24gZm9y
IGEgc2NoZW1hIHByb3ZpZGVkIGFzIGEgcHJlLWNvbXBpbGVkIFByb3RvY29sCiBCdWZmZXIg
RmlsZURlc2NyaXB0b3JTZXQuIFRoZSBgdHlwZWAgZmllbGQgYWJvdmUgbXVzdCBiZSBzZXQg
dG8KIFBST1RPQ09MX0JVRkZFUi4KCg0KBQQAAgMGEgSmAQQXCg0KBQQAAgMBEgSmARgtCg0K
BQQAAgMDEgSmATAxCg0KBQQAAgMIEgSnAQgwChAKCAQAAgMInAgAEgSnAQkvCkgKBAQAAgQS
BqsBAq4BBBo4IE91dHB1dCBvbmx5LiBJbW11dGFibGUuIFRoZSByZXZpc2lvbiBJRCBvZiB0
aGUgc2NoZW1hLgoKDQoFBAACBAUSBKsBAggKDQoFBAACBAESBKsBCRQKDQoFBAACBAMSBKsB
FxgKDwoFBAACBAgSBqsBGa4BAwoQCggEAAIECJwIABIErAEEKwoQCggEAAIECJwIARIErQEE
LQpLCgQEAAIFEgaxAQKyATIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB0aGF0IHRo
ZSByZXZpc2lvbiB3YXMgY3JlYXRlZC4KCg0KBQQAAgUGEgSxAQIbCg0KBQQAAgUBEgSxARww
Cg0KBQQAAgUDEgSxATM0Cg0KBQQAAgUIEgSyAQYxChAKCAQAAgUInAgAEgSyAQcwClkKAgUA
Ega2AQDAAQEaSyBWaWV3IG9mIFNjaGVtYSBvYmplY3QgZmllbGRzIHRvIGJlIHJldHVybmVk
IGJ5IEdldFNjaGVtYSBhbmQgTGlzdFNjaGVtYXMuCgoLCgMFAAESBLYBBQ8KUwoEBQACABIE
uQECHhpFIFRoZSBkZWZhdWx0IC8gdW5zZXQgdmFsdWUuCiBUaGUgQVBJIHdpbGwgZGVmYXVs
dCB0byB0aGUgQkFTSUMgdmlldy4KCg0KBQUAAgABEgS5AQIZCg0KBQUAAgACEgS5ARwdClAK
BAUAAgESBLwBAgwaQiBJbmNsdWRlIHRoZSBuYW1lIGFuZCB0eXBlIG9mIHRoZSBzY2hlbWEs
IGJ1dCBub3QgdGhlIGRlZmluaXRpb24uCgoNCgUFAAIBARIEvAECBwoNCgUFAAIBAhIEvAEK
CwoxCgQFAAICEgS/AQILGiMgSW5jbHVkZSBhbGwgU2NoZW1hIG9iamVjdCBmaWVsZHMuCgoN
CgUFAAICARIEvwECBgoNCgUFAAICAhIEvwEJCgo0CgIEARIGwwEA2gEBGiYgUmVxdWVzdCBm
b3IgdGhlIENyZWF0ZVNjaGVtYSBtZXRob2QuCgoLCgMEAQESBMMBCBsKdgoEBAECABIGxgEC
ywEEGmYgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwcm9qZWN0IGluIHdoaWNoIHRvIGNy
ZWF0ZSB0aGUgc2NoZW1hLgogRm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdC1pZH1gLgoK
DQoFBAECAAUSBMYBAggKDQoFBAECAAESBMYBCQ8KDQoFBAECAAMSBMYBEhMKDwoFBAECAAgS
BsYBFMsBAwoQCggEAQIACJwIABIExwEEKgoRCgcEAQIACJ8IEgbIAQTKAQUK0wEKBAQBAgES
BNIBAj0axAEgUmVxdWlyZWQuIFRoZSBzY2hlbWEgb2JqZWN0IHRvIGNyZWF0ZS4KCiBUaGlz
IHNjaGVtYSdzIGBuYW1lYCBwYXJhbWV0ZXIgaXMgaWdub3JlZC4gVGhlIHNjaGVtYSBvYmpl
Y3QgcmV0dXJuZWQKIGJ5IENyZWF0ZVNjaGVtYSB3aWxsIGhhdmUgYSBgbmFtZWAgbWFkZSB1
c2luZyB0aGUgZ2l2ZW4gYHBhcmVudGAgYW5kCiBgc2NoZW1hX2lkYC4KCg0KBQQBAgEGEgTS
AQIICg0KBQQBAgEBEgTSAQkPCg0KBQQBAgEDEgTSARITCg0KBQQBAgEIEgTSARQ8ChAKCAQB
AgEInAgAEgTSARU7CtwBCgQEAQICEgTZAQIXGs0BIFRoZSBJRCB0byB1c2UgZm9yIHRoZSBz
Y2hlbWEsIHdoaWNoIHdpbGwgYmVjb21lIHRoZSBmaW5hbCBjb21wb25lbnQgb2YKIHRoZSBz
Y2hlbWEncyByZXNvdXJjZSBuYW1lLgoKIFNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
cHVic3ViL2RvY3MvcHVic3ViLWJhc2ljcyNyZXNvdXJjZV9uYW1lcyBmb3IKIHJlc291cmNl
IG5hbWUgY29uc3RyYWludHMuCgoNCgUEAQICBRIE2QECCAoNCgUEAQICARIE2QEJEgoNCgUE
AQICAxIE2QEVFgoxCgIEAhIG3QEA6AEBGiMgUmVxdWVzdCBmb3IgdGhlIEdldFNjaGVtYSBt
ZXRob2QuCgoLCgMEAgESBN0BCBgKbAoEBAICABIG4AEC4wEEGlwgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBzY2hlbWEgdG8gZ2V0LgogRm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVj
dH0vc2NoZW1hcy97c2NoZW1hfWAuCgoNCgUEAgIABRIE4AECCAoNCgUEAgIAARIE4AEJDQoN
CgUEAgIAAxIE4AEQEQoPCgUEAgIACBIG4AES4wEDChAKCAQCAgAInAgAEgThAQQqCg8KBwQC
AgAInwgSBOIBBE4KoAEKBAQCAgESBOcBAhYakQEgVGhlIHNldCBvZiBmaWVsZHMgdG8gcmV0
dXJuIGluIHRoZSByZXNwb25zZS4gSWYgbm90IHNldCwgcmV0dXJucyBhIFNjaGVtYQogd2l0
aCBhbGwgZmllbGRzIGZpbGxlZCBvdXQuIFNldCB0byBgQkFTSUNgIHRvIG9taXQgdGhlIGBk
ZWZpbml0aW9uYC4KCg0KBQQCAgEGEgTnAQIMCg0KBQQCAgEBEgTnAQ0RCg0KBQQCAgEDEgTn
ARQVCjUKAgQDEgbrAQCBAgEaJyBSZXF1ZXN0IGZvciB0aGUgYExpc3RTY2hlbWFzYCBtZXRo
b2QuCgoLCgMEAwESBOsBCBoKcQoEBAMCABIG7gEC8wEEGmEgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBwcm9qZWN0IGluIHdoaWNoIHRvIGxpc3Qgc2NoZW1hcy4KIEZvcm1hdCBpcyBg
cHJvamVjdHMve3Byb2plY3QtaWR9YC4KCg0KBQQDAgAFEgTuAQIICg0KBQQDAgABEgTuAQkP
Cg0KBQQDAgADEgTuARITCg8KBQQDAgAIEgbuARTzAQMKEAoIBAMCAAicCAASBO8BBCoKEQoH
BAMCAAifCBIG8AEE8gEFCrYBCgQEAwIBEgT4AQIWGqcBIFRoZSBzZXQgb2YgU2NoZW1hIGZp
ZWxkcyB0byByZXR1cm4gaW4gdGhlIHJlc3BvbnNlLiBJZiBub3Qgc2V0LCByZXR1cm5zCiBT
Y2hlbWFzIHdpdGggYG5hbWVgIGFuZCBgdHlwZWAsIGJ1dCBub3QgYGRlZmluaXRpb25gLiBT
ZXQgdG8gYEZVTExgIHRvCiByZXRyaWV2ZSBhbGwgZmllbGRzLgoKDQoFBAMCAQYSBPgBAgwK
DQoFBAMCAQESBPgBDREKDQoFBAMCAQMSBPgBFBUKNAoEBAMCAhIE+wECFhomIE1heGltdW0g
bnVtYmVyIG9mIHNjaGVtYXMgdG8gcmV0dXJuLgoKDQoFBAMCAgUSBPsBAgcKDQoFBAMCAgES
BPsBCBEKDQoFBAMCAgMSBPsBFBUKxgEKBAQDAgMSBIACAhgatwEgVGhlIHZhbHVlIHJldHVy
bmVkIGJ5IHRoZSBsYXN0IGBMaXN0U2NoZW1hc1Jlc3BvbnNlYDsgaW5kaWNhdGVzIHRoYXQK
IHRoaXMgaXMgYSBjb250aW51YXRpb24gb2YgYSBwcmlvciBgTGlzdFNjaGVtYXNgIGNhbGws
IGFuZCB0aGF0IHRoZQogc3lzdGVtIHNob3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBk
YXRhLgoKDQoFBAMCAwUSBIACAggKDQoFBAMCAwESBIACCRMKDQoFBAMCAwMSBIACFhcKNgoC
BAQSBoQCAIsCARooIFJlc3BvbnNlIGZvciB0aGUgYExpc3RTY2hlbWFzYCBtZXRob2QuCgoL
CgMEBAESBIQCCBsKJgoEBAQCABIEhgICHhoYIFRoZSByZXN1bHRpbmcgc2NoZW1hcy4KCg0K
BQQEAgAEEgSGAgIKCg0KBQQEAgAGEgSGAgsRCg0KBQQEAgABEgSGAhIZCg0KBQQEAgADEgSG
AhwdCpsBCgQEBAIBEgSKAgIdGowBIElmIG5vdCBlbXB0eSwgaW5kaWNhdGVzIHRoYXQgdGhl
cmUgbWF5IGJlIG1vcmUgc2NoZW1hcyB0aGF0IG1hdGNoIHRoZQogcmVxdWVzdDsgdGhpcyB2
YWx1ZSBzaG91bGQgYmUgcGFzc2VkIGluIGEgbmV3IGBMaXN0U2NoZW1hc1JlcXVlc3RgLgoK
DQoFBAQCAQUSBIoCAggKDQoFBAQCAQESBIoCCRgKDQoFBAQCAQMSBIoCGxwKPQoCBAUSBo4C
AKACARovIFJlcXVlc3QgZm9yIHRoZSBgTGlzdFNjaGVtYVJldmlzaW9uc2AgbWV0aG9kLgoK
CwoDBAUBEgSOAggiCkkKBAQFAgASBpACApMCBBo5IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgc2NoZW1hIHRvIGxpc3QgcmV2aXNpb25zIGZvci4KCg0KBQQFAgAFEgSQAgIICg0KBQQF
AgABEgSQAgkNCg0KBQQFAgADEgSQAhARCg8KBQQFAgAIEgaQAhKTAgMKEAoIBAUCAAicCAAS
BJECBCoKDwoHBAUCAAifCBIEkgIETgq2AQoEBAUCARIEmAICFhqnASBUaGUgc2V0IG9mIFNj
aGVtYSBmaWVsZHMgdG8gcmV0dXJuIGluIHRoZSByZXNwb25zZS4gSWYgbm90IHNldCwgcmV0
dXJucwogU2NoZW1hcyB3aXRoIGBuYW1lYCBhbmQgYHR5cGVgLCBidXQgbm90IGBkZWZpbml0
aW9uYC4gU2V0IHRvIGBGVUxMYCB0bwogcmV0cmlldmUgYWxsIGZpZWxkcy4KCg0KBQQFAgEG
EgSYAgIMCg0KBQQFAgEBEgSYAg0RCg0KBQQFAgEDEgSYAhQVCkMKBAQFAgISBJsCAhYaNSBU
aGUgbWF4aW11bSBudW1iZXIgb2YgcmV2aXNpb25zIHRvIHJldHVybiBwZXIgcGFnZS4KCg0K
BQQFAgIFEgSbAgIHCg0KBQQFAgIBEgSbAggRCg0KBQQFAgIDEgSbAhQVCoEBCgQEBQIDEgSf
AgIYGnMgVGhlIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBMaXN0U2No
ZW1hUmV2aXNpb25zIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNl
cXVlbnQgcGFnZS4KCg0KBQQFAgMFEgSfAgIICg0KBQQFAgMBEgSfAgkTCg0KBQQFAgMDEgSf
AhYXCj4KAgQGEgajAgCqAgEaMCBSZXNwb25zZSBmb3IgdGhlIGBMaXN0U2NoZW1hUmV2aXNp
b25zYCBtZXRob2QuCgoLCgMEBgESBKMCCCMKLAoEBAYCABIEpQICHhoeIFRoZSByZXZpc2lv
bnMgb2YgdGhlIHNjaGVtYS4KCg0KBQQGAgAEEgSlAgIKCg0KBQQGAgAGEgSlAgsRCg0KBQQG
AgABEgSlAhIZCg0KBQQGAgADEgSlAhwdCosBCgQEBgIBEgSpAgIdGn0gQSB0b2tlbiB0aGF0
IGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdl
LgogSWYgdGhpcyBmaWVsZCBpcyBlbXB0eSwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFn
ZXMuCgoNCgUEBgIBBRIEqQICCAoNCgUEBgIBARIEqQIJGAoNCgUEBgIBAxIEqQIbHAowCgIE
BxIGrQIAtwIBGiIgUmVxdWVzdCBmb3IgQ29tbWl0U2NoZW1hIG1ldGhvZC4KCgsKAwQHARIE
rQIIGwp1CgQEBwIAEgawAgKzAgQaZSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNjaGVt
YSB3ZSBhcmUgcmV2aXNpbmcuCiBGb3JtYXQgaXMgYHByb2plY3RzL3twcm9qZWN0fS9zY2hl
bWFzL3tzY2hlbWF9YC4KCg0KBQQHAgAFEgSwAgIICg0KBQQHAgABEgSwAgkNCg0KBQQHAgAD
EgSwAhARCg8KBQQHAgAIEgawAhKzAgMKEAoIBAcCAAicCAASBLECBCoKDwoHBAcCAAifCBIE
sgIETgo4CgQEBwIBEgS2AgI9GiogUmVxdWlyZWQuIFRoZSBzY2hlbWEgcmV2aXNpb24gdG8g
Y29tbWl0LgoKDQoFBAcCAQYSBLYCAggKDQoFBAcCAQESBLYCCQ8KDQoFBAcCAQMSBLYCEhMK
DQoFBAcCAQgSBLYCFDwKEAoIBAcCAQicCAASBLYCFTsKOAoCBAgSBroCAMYCARoqIFJlcXVl
c3QgZm9yIHRoZSBgUm9sbGJhY2tTY2hlbWFgIG1ldGhvZC4KCgsKAwQIARIEugIIHQpKCgQE
CAIAEga8AgK/AgQaOiBSZXF1aXJlZC4gVGhlIHNjaGVtYSBiZWluZyByb2xsZWQgYmFjayB3
aXRoIHJldmlzaW9uIGlkLgoKDQoFBAgCAAUSBLwCAggKDQoFBAgCAAESBLwCCQ0KDQoFBAgC
AAMSBLwCEBEKDwoFBAgCAAgSBrwCEr8CAwoQCggECAIACJwIABIEvQIEKgoPCgcECAIACJ8I
EgS+AgROCnsKBAQIAgESBMUCAkIabSBSZXF1aXJlZC4gVGhlIHJldmlzaW9uIElEIHRvIHJv
bGwgYmFjayB0by4KIEl0IG11c3QgYmUgYSByZXZpc2lvbiBvZiB0aGUgc2FtZSBzY2hlbWEu
CgogICBFeGFtcGxlOiBjN2NmYTJhOAoKDQoFBAgCAQUSBMUCAggKDQoFBAgCAQESBMUCCRQK
DQoFBAgCAQMSBMUCFxgKDQoFBAgCAQgSBMUCGUEKEAoIBAgCAQicCAASBMUCGkAKPgoCBAkS
BskCANgCARowIFJlcXVlc3QgZm9yIHRoZSBgRGVsZXRlU2NoZW1hUmV2aXNpb25gIG1ldGhv
ZC4KCgsKAwQJARIEyQIIIwqpAQoEBAkCABIGzgIC0QIEGpgBIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUgc2NoZW1hIHJldmlzaW9uIHRvIGJlIGRlbGV0ZWQsIHdpdGggYSByZXZpc2lv
biBJRAogZXhwbGljaXRseSBpbmNsdWRlZC4KCiBFeGFtcGxlOiBgcHJvamVjdHMvMTIzL3Nj
aGVtYXMvbXktc2NoZW1hQGM3Y2ZhMmE4YAoKDQoFBAkCAAUSBM4CAggKDQoFBAkCAAESBM4C
CQ0KDQoFBAkCAAMSBM4CEBEKDwoFBAkCAAgSBs4CEtECAwoQCggECQIACJwIABIEzwIEKgoP
CgcECQIACJ8IEgTQAgROCqwBCgQECQIBEgbWAgLXAkIamwEgT3B0aW9uYWwuIFRoaXMgZmll
bGQgaXMgZGVwcmVjYXRlZCBhbmQgc2hvdWxkIG5vdCBiZSB1c2VkIGZvciBzcGVjaWZ5aW5n
CiB0aGUgcmV2aXNpb24gSUQuIFRoZSByZXZpc2lvbiBJRCBzaG91bGQgYmUgc3BlY2lmaWVk
IHZpYSB0aGUgYG5hbWVgCiBwYXJhbWV0ZXIuCgoNCgUECQIBBRIE1gICCAoNCgUECQIBARIE
1gIJFAoNCgUECQIBAxIE1gIXGAoNCgUECQIBCBIE1wIGQQoOCgYECQIBCAMSBNcCBxgKEAoI
BAkCAQicCAASBNcCGkAKNgoCBAoSBtsCAOICARooIFJlcXVlc3QgZm9yIHRoZSBgRGVsZXRl
U2NoZW1hYCBtZXRob2QuCgoLCgMECgESBNsCCBsKawoEBAoCABIG3gIC4QIEGlsgUmVxdWly
ZWQuIE5hbWUgb2YgdGhlIHNjaGVtYSB0byBkZWxldGUuCiBGb3JtYXQgaXMgYHByb2plY3Rz
L3twcm9qZWN0fS9zY2hlbWFzL3tzY2hlbWF9YC4KCg0KBQQKAgAFEgTeAgIICg0KBQQKAgAB
EgTeAgkNCg0KBQQKAgADEgTeAhARCg8KBQQKAgAIEgbeAhLhAgMKEAoIBAoCAAicCAASBN8C
BCoKDwoHBAoCAAifCBIE4AIETgo4CgIECxIG5QIA8QIBGiogUmVxdWVzdCBmb3IgdGhlIGBW
YWxpZGF0ZVNjaGVtYWAgbWV0aG9kLgoKCwoDBAsBEgTlAggdCnUKBAQLAgASBugCAu0CBBpl
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcHJvamVjdCBpbiB3aGljaCB0byB2YWxpZGF0
ZSBzY2hlbWFzLgogRm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdC1pZH1gLgoKDQoFBAsC
AAUSBOgCAggKDQoFBAsCAAESBOgCCQ8KDQoFBAsCAAMSBOgCEhMKDwoFBAsCAAgSBugCFO0C
AwoQCggECwIACJwIABIE6QIEKgoRCgcECwIACJ8IEgbqAgTsAgUKOAoEBAsCARIE8AICPRoq
IFJlcXVpcmVkLiBUaGUgc2NoZW1hIG9iamVjdCB0byB2YWxpZGF0ZS4KCg0KBQQLAgEGEgTw
AgIICg0KBQQLAgEBEgTwAgkPCg0KBQQLAgEDEgTwAhITCg0KBQQLAgEIEgTwAhQ8ChAKCAQL
AgEInAgAEgTwAhU7CkcKAgQMEgT1AgAhGjsgUmVzcG9uc2UgZm9yIHRoZSBgVmFsaWRhdGVT
Y2hlbWFgIG1ldGhvZC4KIEVtcHR5IGZvciBub3cuCgoLCgMEDAESBPUCCB4KOQoCBA0SBvgC
AJMDARorIFJlcXVlc3QgZm9yIHRoZSBgVmFsaWRhdGVNZXNzYWdlYCBtZXRob2QuCgoLCgME
DQESBPgCCB4KdQoEBA0CABIG+wICgAMEGmUgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBw
cm9qZWN0IGluIHdoaWNoIHRvIHZhbGlkYXRlIHNjaGVtYXMuCiBGb3JtYXQgaXMgYHByb2pl
Y3RzL3twcm9qZWN0LWlkfWAuCgoNCgUEDQIABRIE+wICCAoNCgUEDQIAARIE+wIJDwoNCgUE
DQIAAxIE+wISEwoPCgUEDQIACBIG+wIUgAMDChAKCAQNAgAInAgAEgT8AgQqChEKBwQNAgAI
nwgSBv0CBP8CBQoOCgQEDQgAEgaCAwKMAwMKDQoFBA0IAAESBIIDCBMKcgoEBA0CARIGhgME
iAMGGmIgTmFtZSBvZiB0aGUgc2NoZW1hIGFnYWluc3Qgd2hpY2ggdG8gdmFsaWRhdGUuCgog
Rm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdH0vc2NoZW1hcy97c2NoZW1hfWAuCgoNCgUE
DQIBBRIEhgMECgoNCgUEDQIBARIEhgMLDwoNCgUEDQIBAxIEhgMSEwoPCgUEDQIBCBIGhgMU
iAMFCg8KBwQNAgEInwgSBIcDBlAKNwoEBA0CAhIEiwMEFhopIEFkLWhvYyBzY2hlbWEgYWdh
aW5zdCB3aGljaCB0byB2YWxpZGF0ZQoKDQoFBA0CAgYSBIsDBAoKDQoFBA0CAgESBIsDCxEK
DQoFBA0CAgMSBIsDFBUKRwoEBA0CAxIEjwMCFBo5IE1lc3NhZ2UgdG8gdmFsaWRhdGUgYWdh
aW5zdCB0aGUgcHJvdmlkZWQgYHNjaGVtYV9zcGVjYC4KCg0KBQQNAgMFEgSPAwIHCg0KBQQN
AgMBEgSPAwgPCg0KBQQNAgMDEgSPAxITCjIKBAQNAgQSBJIDAhgaJCBUaGUgZW5jb2Rpbmcg
ZXhwZWN0ZWQgZm9yIG1lc3NhZ2VzCgoNCgUEDQIEBhIEkgMCCgoNCgUEDQIEARIEkgMLEwoN
CgUEDQIEAxIEkgMWFwpICgIEDhIElwMAIho8IFJlc3BvbnNlIGZvciB0aGUgYFZhbGlkYXRl
TWVzc2FnZWAgbWV0aG9kLgogRW1wdHkgZm9yIG5vdy4KCgsKAwQOARIElwMIHwpLCgIEDxIG
mgMAoAMBGj0gQ29uZmlndXJhdGlvbiBzcGVjaWZpYyB0byBjb21waWxlZCBQcm90b2NvbCBC
dWZmZXIgc2NoZW1hcy4KCgsKAwQPARIEmgMIGwpKCgQEDwIAEgScAwJDGjwgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSByb290IG1lc3NhZ2UgdHlwZSBpbiB0aGUgc2NoZW1hLgoKDQoF
BA8CAAUSBJwDAggKDQoFBA8CAAESBJwDCRUKDQoFBA8CAAMSBJwDGBkKDQoFBA8CAAgSBJwD
GkIKEAoIBA8CAAicCAASBJwDG0EKQAoEBA8CARIEnwMCRBoyIFJlcXVpcmVkLiBUaGUgY29t
cGlsZWQgRmlsZURlc2NyaXB0b3JTZXQgYmluYXJ5LgoKDQoFBA8CAQUSBJ8DAgcKDQoFBA8C
AQESBJ8DCBYKDQoFBA8CAQMSBJ8DGRoKDQoFBA8CAQgSBJ8DG0MKEAoIBA8CAQicCAASBJ8D
HEIKNQoCBQESBqMDAK0DARonIFBvc3NpYmxlIGVuY29kaW5nIHR5cGVzIGZvciBtZXNzYWdl
cy4KCgsKAwUBARIEowMFDQobCgQFAQIAEgSlAwIbGg0gVW5zcGVjaWZpZWQKCg0KBQUBAgAB
EgSlAwIWCg0KBQUBAgACEgSlAxkaCh0KBAUBAgESBKgDAgsaDyBKU09OIGVuY29kaW5nCgoN
CgUFAQIBARIEqAMCBgoNCgUFAQIBAhIEqAMJCgp9CgQFAQICEgSsAwINGm8gQmluYXJ5IGVu
Y29kaW5nLCBhcyBkZWZpbmVkIGJ5IHRoZSBzY2hlbWEgdHlwZS4gRm9yIHNvbWUgc2NoZW1h
IHR5cGVzLAogYmluYXJ5IGVuY29kaW5nIG1heSBub3QgYmUgYXZhaWxhYmxlLgoKDQoFBQEC
AgESBKwDAggKDQoFBQECAgISBKwDCwxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Pubsub::V1::Schema::Schema ===
    # Fields for Schema
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.pubsub.v1.Schema.Type)
    # Field: definition Type: 9 ()
    # Field: compiled_proto_schema Type: 11 (.google.pubsub.v1.CompiledProtoSchema)
    # Field: revision_id Type: 9 ()
    # Field: revision_create_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Schema::Type
our $Schema_TYPE_UNSPECIFIED = 0;
our $Schema_PROTOCOL_BUFFER = 1;
our $Schema_AVRO = 2;

# === Message: Google::Pubsub::V1::Schema::CreateSchemaRequest ===
    # Fields for CreateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)
    # Field: schema_id Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::GetSchemaRequest ===
    # Fields for GetSchemaRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.pubsub.v1.SchemaView)

# === Message: Google::Pubsub::V1::Schema::ListSchemasRequest ===
    # Fields for ListSchemasRequest
    # Field: parent Type: 9 ()
    # Field: view Type: 14 (.google.pubsub.v1.SchemaView)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::ListSchemasResponse ===
    # Fields for ListSchemasResponse
    # Field: schemas Type: 11 (.google.pubsub.v1.Schema)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest ===
    # Fields for ListSchemaRevisionsRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.pubsub.v1.SchemaView)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse ===
    # Fields for ListSchemaRevisionsResponse
    # Field: schemas Type: 11 (.google.pubsub.v1.Schema)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::CommitSchemaRequest ===
    # Fields for CommitSchemaRequest
    # Field: name Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)

# === Message: Google::Pubsub::V1::Schema::RollbackSchemaRequest ===
    # Fields for RollbackSchemaRequest
    # Field: name Type: 9 ()
    # Field: revision_id Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest ===
    # Fields for DeleteSchemaRevisionRequest
    # Field: name Type: 9 ()
    # Field: revision_id Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::DeleteSchemaRequest ===
    # Fields for DeleteSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Pubsub::V1::Schema::ValidateSchemaRequest ===
    # Fields for ValidateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)

# === Message: Google::Pubsub::V1::Schema::ValidateSchemaResponse ===
    # Fields for ValidateSchemaResponse

# === Message: Google::Pubsub::V1::Schema::ValidateMessageRequest ===
    # Fields for ValidateMessageRequest
    # Field: parent Type: 9 ()
    # Field: name Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)
    # Field: message Type: 12 ()
    # Field: encoding Type: 14 (.google.pubsub.v1.Encoding)

# === Message: Google::Pubsub::V1::Schema::ValidateMessageResponse ===
    # Fields for ValidateMessageResponse

# === Message: Google::Pubsub::V1::Schema::CompiledProtoSchema ===
    # Fields for CompiledProtoSchema
    # Field: root_message Type: 9 ()
    # Field: compiled_bytes Type: 12 ()

# === Service Client: Google::Pubsub::V1::Schema::SchemaServiceClient ===
package Google::Pubsub::V1::Schema::SchemaServiceClient;

=pod

=head2 Service Client: Google::Pubsub::V1::Schema::SchemaServiceClient

Client stub representing the remote C<SchemaService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsub.googleapis.com:443' );

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

sub create_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::CreateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'CreateSchema',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::Schema',
    });
}

sub get_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::GetSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'GetSchema',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::Schema',
    });
}

sub list_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::ListSchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'ListSchemas',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::ListSchemasResponse',
    });
}

sub list_schema_revisions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'ListSchemaRevisions',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse',
    });
}

sub commit_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::CommitSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'CommitSchema',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::Schema',
    });
}

sub rollback_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::RollbackSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'RollbackSchema',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::Schema',
    });
}

sub delete_schema_revision {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'DeleteSchemaRevision',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::Schema',
    });
}

sub delete_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::DeleteSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'DeleteSchema',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub validate_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::ValidateSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'ValidateSchema',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::ValidateSchemaResponse',
    });
}

sub validate_message {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1::Schema::ValidateMessageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1.SchemaService',
        method         => 'ValidateMessage',
        request        => $req,
        response_class => 'Google::Pubsub::V1::Schema::ValidateMessageResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Pubsub::V1::Schema - Compiled Protocol Buffers messages for google/pubsub/v1/schema.proto

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::Schema->new({
        name => $name,
        type => $type,
        definition => $definition,
        compiled_proto_schema => $compiled_proto_schema,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Pubsub::V1::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/pubsub/v1/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Pubsub::V1::Schema::Schema

A schema resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the schema.
Format is `projects/{project}/schemas/{schema}`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Pubsub::V1::Schema::Type>)

The type of the schema definition.

=item * C<< $msg->definition() >> / C<< $msg->definition($value) >>

Type: C<String>

The definition of the schema. This should contain a string representing
the full definition of the schema that is a valid schema definition of
the type specified in `type`.

=item * C<< $msg->compiled_proto_schema() >> / C<< $msg->compiled_proto_schema($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::CompiledProtoSchema>)

Optional. Configuration for a schema provided as a pre-compiled Protocol
Buffer FileDescriptorSet. The `type` field above must be set to
PROTOCOL_BUFFER.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Output only. Immutable. The revision ID of the schema.

=item * C<< $msg->revision_create_time() >> / C<< $msg->revision_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp that the revision was created.

=back

=head3 Enum: Schema::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<PROTOCOL_BUFFER> => C<1>

=item * C<AVRO> => C<2>

=back

=head2 Google::Pubsub::V1::Schema::CreateSchemaRequest

Request for the CreateSchema method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project in which to create the schema.
Format is `projects/{project-id}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::Schema>)

Required. The schema object to create.

This schema's `name` parameter is ignored. The schema object returned
by CreateSchema will have a `name` made using the given `parent` and
`schema_id`.

=item * C<< $msg->schema_id() >> / C<< $msg->schema_id($value) >>

Type: C<String>

The ID to use for the schema, which will become the final component of
the schema's resource name.

See https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names for
resource name constraints.

=back

=head2 Google::Pubsub::V1::Schema::GetSchemaRequest

Request for the GetSchema method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the schema to get.
Format is `projects/{project}/schemas/{schema}`.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Pubsub::V1::SchemaView>)

The set of fields to return in the response. If not set, returns a Schema
with all fields filled out. Set to `BASIC` to omit the `definition`.

=back

=head2 Google::Pubsub::V1::Schema::ListSchemasRequest

Request for the `ListSchemas` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project in which to list schemas.
Format is `projects/{project-id}`.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Pubsub::V1::SchemaView>)

The set of Schema fields to return in the response. If not set, returns
Schemas with `name` and `type`, but not `definition`. Set to `FULL` to
retrieve all fields.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of schemas to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListSchemasResponse`; indicates that
this is a continuation of a prior `ListSchemas` call, and that the
system should return the next page of data.

=back

=head2 Google::Pubsub::V1::Schema::ListSchemasResponse

Response for the `ListSchemas` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schemas() >> / C<< $msg->schemas($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::Schema>)

The resulting schemas.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more schemas that match the
request; this value should be passed in a new `ListSchemasRequest`.

=back

=head2 Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest

Request for the `ListSchemaRevisions` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the schema to list revisions for.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Pubsub::V1::SchemaView>)

The set of Schema fields to return in the response. If not set, returns
Schemas with `name` and `type`, but not `definition`. Set to `FULL` to
retrieve all fields.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of revisions to return per page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The page token, received from a previous ListSchemaRevisions call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse

Response for the `ListSchemaRevisions` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schemas() >> / C<< $msg->schemas($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::Schema>)

The revisions of the schema.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is empty, there are no subsequent pages.

=back

=head2 Google::Pubsub::V1::Schema::CommitSchemaRequest

Request for CommitSchema method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the schema we are revising.
Format is `projects/{project}/schemas/{schema}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::Schema>)

Required. The schema revision to commit.

=back

=head2 Google::Pubsub::V1::Schema::RollbackSchemaRequest

Request for the `RollbackSchema` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The schema being rolled back with revision id.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Required. The revision ID to roll back to.
It must be a revision of the same schema.

  Example: c7cfa2a8

=back

=head2 Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest

Request for the `DeleteSchemaRevision` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the schema revision to be deleted, with a revision ID
explicitly included.

Example: `projects/123/schemas/my-schema@c7cfa2a8`

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Optional. This field is deprecated and should not be used for specifying
the revision ID. The revision ID should be specified via the `name`
parameter.

=back

=head2 Google::Pubsub::V1::Schema::DeleteSchemaRequest

Request for the `DeleteSchema` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the schema to delete.
Format is `projects/{project}/schemas/{schema}`.

=back

=head2 Google::Pubsub::V1::Schema::ValidateSchemaRequest

Request for the `ValidateSchema` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project in which to validate schemas.
Format is `projects/{project-id}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::Schema>)

Required. The schema object to validate.

=back

=head2 Google::Pubsub::V1::Schema::ValidateSchemaResponse

Response for the `ValidateSchema` method.
Empty for now.

Inherits from L<Protobuf::Message>.

=head2 Google::Pubsub::V1::Schema::ValidateMessageRequest

Request for the `ValidateMessage` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project in which to validate schemas.
Format is `projects/{project-id}`.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the schema against which to validate.

Format is `projects/{project}/schemas/{schema}`.

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<Message> (L<Google::Pubsub::V1::Schema::Schema>)

Ad-hoc schema against which to validate

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<Bytes>

Message to validate against the provided `schema_spec`.

=item * C<< $msg->encoding() >> / C<< $msg->encoding($value) >>

Type: C<Enum> (L<Google::Pubsub::V1::Encoding>)

The encoding expected for messages

=back

=head2 Google::Pubsub::V1::Schema::ValidateMessageResponse

Response for the `ValidateMessage` method.
Empty for now.

Inherits from L<Protobuf::Message>.

=head2 Google::Pubsub::V1::Schema::CompiledProtoSchema

Configuration specific to compiled Protocol Buffer schemas.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->root_message() >> / C<< $msg->root_message($value) >>

Type: C<String>

Required. The name of the root message type in the schema.

=item * C<< $msg->compiled_bytes() >> / C<< $msg->compiled_bytes($value) >>

Type: C<Bytes>

Required. The compiled FileDescriptorSet binary.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Pubsub::V1::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
