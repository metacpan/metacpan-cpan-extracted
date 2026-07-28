package Google::Pubsub::V1::Schema;

use strict;
use warnings;

our $VERSION = '0.11';

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
dGFtcC5wcm90byL1AgoGU2NoZW1hEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIxCgR0eXBl
GAIgASgOMh0uZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWEuVHlwZVIEdHlwZRIeCgpkZWZpbml0
aW9uGAMgASgJUgpkZWZpbml0aW9uEicKC3JldmlzaW9uX2lkGAQgASgJQgbgQQXgQQNSCnJl
dmlzaW9uSWQSUQoUcmV2aXNpb25fY3JlYXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSEnJldmlzaW9uQ3JlYXRlVGltZSI7CgRUeXBlEhQKEFRZUEVf
VU5TUEVDSUZJRUQQABITCg9QUk9UT0NPTF9CVUZGRVIQARIICgRBVlJPEAI6RupBQwoccHVi
c3ViLmdvb2dsZWFwaXMuY29tL1NjaGVtYRIjcHJvamVjdHMve3Byb2plY3R9L3NjaGVtYXMv
e3NjaGVtYX0ipwEKE0NyZWF0ZVNjaGVtYVJlcXVlc3QSPAoGcGFyZW50GAEgASgJQiTgQQL6
QR4SHHB1YnN1Yi5nb29nbGVhcGlzLmNvbS9TY2hlbWFSBnBhcmVudBI1CgZzY2hlbWEYAiAB
KAsyGC5nb29nbGUucHVic3ViLnYxLlNjaGVtYUID4EECUgZzY2hlbWESGwoJc2NoZW1hX2lk
GAMgASgJUghzY2hlbWFJZCJ+ChBHZXRTY2hlbWFSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBB
AvpBHgoccHVic3ViLmdvb2dsZWFwaXMuY29tL1NjaGVtYVIEbmFtZRIwCgR2aWV3GAIgASgO
MhwuZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWFWaWV3UgR2aWV3Is8BChJMaXN0U2NoZW1hc1Jl
cXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdv
b2dsZWFwaXMuY29tL1Byb2plY3RSBnBhcmVudBIwCgR2aWV3GAIgASgOMhwuZ29vZ2xlLnB1
YnN1Yi52MS5TY2hlbWFWaWV3UgR2aWV3EhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUS
HQoKcGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2VuInEKE0xpc3RTY2hlbWFzUmVzcG9uc2US
MgoHc2NoZW1hcxgBIAMoCzIYLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1hUgdzY2hlbWFzEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLEAQoaTGlzdFNjaGVtYVJl
dmlzaW9uc1JlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxwdWJzdWIuZ29vZ2xlYXBp
cy5jb20vU2NoZW1hUgRuYW1lEjAKBHZpZXcYAiABKA4yHC5nb29nbGUucHVic3ViLnYxLlNj
aGVtYVZpZXdSBHZpZXcSGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rv
a2VuGAQgASgJUglwYWdlVG9rZW4ieQobTGlzdFNjaGVtYVJldmlzaW9uc1Jlc3BvbnNlEjIK
B3NjaGVtYXMYASADKAsyGC5nb29nbGUucHVic3ViLnYxLlNjaGVtYVIHc2NoZW1hcxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4ihgEKE0NvbW1pdFNjaGVtYVJl
cXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxwdWJzdWIuZ29vZ2xlYXBpcy5jb20vU2No
ZW1hUgRuYW1lEjUKBnNjaGVtYRgCIAEoCzIYLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1hQgPg
QQJSBnNjaGVtYSJ3ChVSb2xsYmFja1NjaGVtYVJlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC
+kEeChxwdWJzdWIuZ29vZ2xlYXBpcy5jb20vU2NoZW1hUgRuYW1lEiQKC3JldmlzaW9uX2lk
GAIgASgJQgPgQQJSCnJldmlzaW9uSWQifwobRGVsZXRlU2NoZW1hUmV2aXNpb25SZXF1ZXN0
EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccHVic3ViLmdvb2dsZWFwaXMuY29tL1NjaGVtYVIE
bmFtZRImCgtyZXZpc2lvbl9pZBgCIAEoCUIFGAHgQQFSCnJldmlzaW9uSWQiTwoTRGVsZXRl
U2NoZW1hUmVxdWVzdBI4CgRuYW1lGAEgASgJQiTgQQL6QR4KHHB1YnN1Yi5nb29nbGVhcGlz
LmNvbS9TY2hlbWFSBG5hbWUimwEKFVZhbGlkYXRlU2NoZW1hUmVxdWVzdBJLCgZwYXJlbnQY
ASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJv
amVjdFIGcGFyZW50EjUKBnNjaGVtYRgCIAEoCzIYLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1h
QgPgQQJSBnNjaGVtYSIYChZWYWxpZGF0ZVNjaGVtYVJlc3BvbnNlIrMCChZWYWxpZGF0ZU1l
c3NhZ2VSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFu
YWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSNwoEbmFtZRgCIAEoCUIh+kEe
ChxwdWJzdWIuZ29vZ2xlYXBpcy5jb20vU2NoZW1hSABSBG5hbWUSMgoGc2NoZW1hGAMgASgL
MhguZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWFIAFIGc2NoZW1hEhgKB21lc3NhZ2UYBCABKAxS
B21lc3NhZ2USNgoIZW5jb2RpbmcYBSABKA4yGi5nb29nbGUucHVic3ViLnYxLkVuY29kaW5n
UghlbmNvZGluZ0INCgtzY2hlbWFfc3BlYyIZChdWYWxpZGF0ZU1lc3NhZ2VSZXNwb25zZSo+
CgpTY2hlbWFWaWV3EhsKF1NDSEVNQV9WSUVXX1VOU1BFQ0lGSUVEEAASCQoFQkFTSUMQARII
CgRGVUxMEAIqOgoIRW5jb2RpbmcSGAoURU5DT0RJTkdfVU5TUEVDSUZJRUQQABIICgRKU09O
EAESCgoGQklOQVJZEAIyiA0KDVNjaGVtYVNlcnZpY2USmgEKDENyZWF0ZVNjaGVtYRIlLmdv
b2dsZS5wdWJzdWIudjEuQ3JlYXRlU2NoZW1hUmVxdWVzdBoYLmdvb2dsZS5wdWJzdWIudjEu
U2NoZW1hIkmC0+STAikiHy92MS97cGFyZW50PXByb2plY3RzLyp9L3NjaGVtYXM6BnNjaGVt
YdpBF3BhcmVudCxzY2hlbWEsc2NoZW1hX2lkEnkKCUdldFNjaGVtYRIiLmdvb2dsZS5wdWJz
dWIudjEuR2V0U2NoZW1hUmVxdWVzdBoYLmdvb2dsZS5wdWJzdWIudjEuU2NoZW1hIi6C0+ST
AiESHy92MS97bmFtZT1wcm9qZWN0cy8qL3NjaGVtYXMvKn3aQQRuYW1lEowBCgtMaXN0U2No
ZW1hcxIkLmdvb2dsZS5wdWJzdWIudjEuTGlzdFNjaGVtYXNSZXF1ZXN0GiUuZ29vZ2xlLnB1
YnN1Yi52MS5MaXN0U2NoZW1hc1Jlc3BvbnNlIjCC0+STAiESHy92MS97cGFyZW50PXByb2pl
Y3RzLyp9L3NjaGVtYXPaQQZwYXJlbnQSsAEKE0xpc3RTY2hlbWFSZXZpc2lvbnMSLC5nb29n
bGUucHVic3ViLnYxLkxpc3RTY2hlbWFSZXZpc2lvbnNSZXF1ZXN0Gi0uZ29vZ2xlLnB1YnN1
Yi52MS5MaXN0U2NoZW1hUmV2aXNpb25zUmVzcG9uc2UiPILT5JMCLxItL3YxL3tuYW1lPXBy
b2plY3RzLyovc2NoZW1hcy8qfTpsaXN0UmV2aXNpb25z2kEEbmFtZRKQAQoMQ29tbWl0U2No
ZW1hEiUuZ29vZ2xlLnB1YnN1Yi52MS5Db21taXRTY2hlbWFSZXF1ZXN0GhguZ29vZ2xlLnB1
YnN1Yi52MS5TY2hlbWEiP4LT5JMCKyImL3YxL3tuYW1lPXByb2plY3RzLyovc2NoZW1hcy8q
fTpjb21taXQ6ASraQQtuYW1lLHNjaGVtYRKbAQoOUm9sbGJhY2tTY2hlbWESJy5nb29nbGUu
cHVic3ViLnYxLlJvbGxiYWNrU2NoZW1hUmVxdWVzdBoYLmdvb2dsZS5wdWJzdWIudjEuU2No
ZW1hIkaC0+STAi0iKC92MS97bmFtZT1wcm9qZWN0cy8qL3NjaGVtYXMvKn06cm9sbGJhY2s6
ASraQRBuYW1lLHJldmlzaW9uX2lkEqoBChREZWxldGVTY2hlbWFSZXZpc2lvbhItLmdvb2ds
ZS5wdWJzdWIudjEuRGVsZXRlU2NoZW1hUmV2aXNpb25SZXF1ZXN0GhguZ29vZ2xlLnB1YnN1
Yi52MS5TY2hlbWEiSYLT5JMCMCouL3YxL3tuYW1lPXByb2plY3RzLyovc2NoZW1hcy8qfTpk
ZWxldGVSZXZpc2lvbtpBEG5hbWUscmV2aXNpb25faWQSfQoMRGVsZXRlU2NoZW1hEiUuZ29v
Z2xlLnB1YnN1Yi52MS5EZWxldGVTY2hlbWFSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5Ii6C0+STAiEqHy92MS97bmFtZT1wcm9qZWN0cy8qL3NjaGVtYXMvKn3aQQRuYW1lEqgB
Cg5WYWxpZGF0ZVNjaGVtYRInLmdvb2dsZS5wdWJzdWIudjEuVmFsaWRhdGVTY2hlbWFSZXF1
ZXN0GiguZ29vZ2xlLnB1YnN1Yi52MS5WYWxpZGF0ZVNjaGVtYVJlc3BvbnNlIkOC0+STAi0i
KC92MS97cGFyZW50PXByb2plY3RzLyp9L3NjaGVtYXM6dmFsaWRhdGU6ASraQQ1wYXJlbnQs
c2NoZW1hEqIBCg9WYWxpZGF0ZU1lc3NhZ2USKC5nb29nbGUucHVic3ViLnYxLlZhbGlkYXRl
TWVzc2FnZVJlcXVlc3QaKS5nb29nbGUucHVic3ViLnYxLlZhbGlkYXRlTWVzc2FnZVJlc3Bv
bnNlIjqC0+STAjQiLy92MS97cGFyZW50PXByb2plY3RzLyp9L3NjaGVtYXM6dmFsaWRhdGVN
ZXNzYWdlOgEqGnDKQRVwdWJzdWIuZ29vZ2xlYXBpcy5jb23SQVVodHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvcHVic3ViQqoBChRjb20uZ29vZ2xlLnB1YnN1Yi52MUILU2NoZW1hUHJvdG9Q
AVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9wdWJzdWIvdjIvYXBpdjEvcHVic3VicGI7cHVic3Vi
cGKqAhZHb29nbGUuQ2xvdWQuUHViU3ViLlYxygIWR29vZ2xlXENsb3VkXFB1YlN1YlxWMeoC
GUdvb2dsZTo6Q2xvdWQ6OlB1YlN1Yjo6VjFK61gKBxIFDgCYAwEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABkKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAlCgkKAgMFEgMXACkKCAoBCBIDGQAzCgkK
AgglEgMZADMKCAoBCBIDGgBMCgkKAggLEgMaAEwKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoB
CBIDHAAsCgkKAggIEgMcACwKCAoBCBIDHQAtCgkKAggBEgMdAC0KCAoBCBIDHgAzCgkKAggp
EgMeADMKCAoBCBIDHwAyCgkKAggtEgMfADIKOgoCBgASBCIAfQEaLiBTZXJ2aWNlIGZvciBk
b2luZyBzY2hlbWEtcmVsYXRlZCBvcGVyYXRpb25zLgoKCgoDBgABEgMiCBUKCgoDBgADEgMj
Aj0KDAoFBgADmQgSAyMCPQoLCgMGAAMSBCQCJi8KDQoFBgADmggSBCQCJi8KIQoEBgACABIE
KQIvAxoTIENyZWF0ZXMgYSBzY2hlbWEuCgoMCgUGAAIAARIDKQYSCgwKBQYAAgACEgMpEyYK
DAoFBgACAAMSAykxNwoNCgUGAAIABBIEKgQtBgoRCgkGAAIABLDKvCISBCoELQYKDAoFBgAC
AAQSAy4ERQoPCggGAAIABJsIABIDLgRFCh4KBAYAAgESBDICNwMaECBHZXRzIGEgc2NoZW1h
LgoKDAoFBgACAQESAzIGDwoMCgUGAAIBAhIDMhAgCgwKBQYAAgEDEgMyKzEKDQoFBgACAQQS
BDMENQYKEQoJBgACAQSwyrwiEgQzBDUGCgwKBQYAAgEEEgM2BDIKDwoIBgACAQSbCAASAzYE
MgorCgQGAAICEgQ6Aj8DGh0gTGlzdHMgc2NoZW1hcyBpbiBhIHByb2plY3QuCgoMCgUGAAIC
ARIDOgYRCgwKBQYAAgICEgM6EiQKDAoFBgACAgMSAzovQgoNCgUGAAICBBIEOwQ9BgoRCgkG
AAICBLDKvCISBDsEPQYKDAoFBgACAgQSAz4ENAoPCggGAAICBJsIABIDPgQ0CkAKBAYAAgMS
BEICSAMaMiBMaXN0cyBhbGwgc2NoZW1hIHJldmlzaW9ucyBmb3IgdGhlIG5hbWVkIHNjaGVt
YS4KCgwKBQYAAgMBEgNCBhkKDAoFBgACAwISA0IaNAoMCgUGAAIDAxIDQw8qCg0KBQYAAgME
EgREBEYGChEKCQYAAgMEsMq8IhIERARGBgoMCgUGAAIDBBIDRwQyCg8KCAYAAgMEmwgAEgNH
BDIKRAoEBgACBBIESwJRAxo2IENvbW1pdHMgYSBuZXcgc2NoZW1hIHJldmlzaW9uIHRvIGFu
IGV4aXN0aW5nIHNjaGVtYS4KCgwKBQYAAgQBEgNLBhIKDAoFBgACBAISA0sTJgoMCgUGAAIE
AxIDSzE3Cg0KBQYAAgQEEgRMBE8GChEKCQYAAgQEsMq8IhIETARPBgoMCgUGAAIEBBIDUAQ5
Cg8KCAYAAgQEmwgAEgNQBDkKWQoEBgACBRIEVAJaAxpLIENyZWF0ZXMgYSBuZXcgc2NoZW1h
IHJldmlzaW9uIHRoYXQgaXMgYSBjb3B5IG9mIHRoZSBwcm92aWRlZCByZXZpc2lvbl9pZC4K
CgwKBQYAAgUBEgNUBhQKDAoFBgACBQISA1QVKgoMCgUGAAIFAxIDVDU7Cg0KBQYAAgUEEgRV
BFgGChEKCQYAAgUEsMq8IhIEVQRYBgoMCgUGAAIFBBIDWQQ+Cg8KCAYAAgUEmwgAEgNZBD4K
MwoEBgACBhIEXQJiAxolIERlbGV0ZXMgYSBzcGVjaWZpYyBzY2hlbWEgcmV2aXNpb24uCgoM
CgUGAAIGARIDXQYaCgwKBQYAAgYCEgNdGzYKDAoFBgACBgMSA11BRwoNCgUGAAIGBBIEXgRg
BgoRCgkGAAIGBLDKvCISBF4EYAYKDAoFBgACBgQSA2EEPgoPCggGAAIGBJsIABIDYQQ+CiEK
BAYAAgcSBGUCagMaEyBEZWxldGVzIGEgc2NoZW1hLgoKDAoFBgACBwESA2UGEgoMCgUGAAIH
AhIDZRMmCgwKBQYAAgcDEgNlMUYKDQoFBgACBwQSBGYEaAYKEQoJBgACBwSwyrwiEgRmBGgG
CgwKBQYAAgcEEgNpBDIKDwoIBgACBwSbCAASA2kEMgojCgQGAAIIEgRtAnMDGhUgVmFsaWRh
dGVzIGEgc2NoZW1hLgoKDAoFBgACCAESA20GFAoMCgUGAAIIAhIDbRUqCgwKBQYAAggDEgNt
NUsKDQoFBgACCAQSBG4EcQYKEQoJBgACCASwyrwiEgRuBHEGCgwKBQYAAggEEgNyBDsKDwoI
BgACCASbCAASA3IEOwo1CgQGAAIJEgR2AnwDGicgVmFsaWRhdGVzIGEgbWVzc2FnZSBhZ2Fp
bnN0IGEgc2NoZW1hLgoKDAoFBgACCQESA3YGFQoMCgUGAAIJAhIDdhYsCgwKBQYAAgkDEgN3
DyYKDQoFBgACCQQSBHgEewYKEQoJBgACCQSwyrwiEgR4BHsGCiIKAgQAEgaAAQCnAQEaFCBB
IHNjaGVtYSByZXNvdXJjZS4KCgsKAwQAARIEgAEIDgoNCgMEAAcSBoEBAoQBBAoPCgUEAAed
CBIGgQEChAEECjMKBAQABAASBocBApABAxojIFBvc3NpYmxlIHNjaGVtYSBkZWZpbml0aW9u
IHR5cGVzLgoKDQoFBAAEAAESBIcBBwsKNgoGBAAEAAIAEgSJAQQZGiYgRGVmYXVsdCB2YWx1
ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcEAAQAAgABEgSJAQQUCg8KBwQABAACAAIS
BIkBFxgKNgoGBAAEAAIBEgSMAQQYGiYgQSBQcm90b2NvbCBCdWZmZXIgc2NoZW1hIGRlZmlu
aXRpb24uCgoPCgcEAAQAAgEBEgSMAQQTCg8KBwQABAACAQISBIwBFhcKLAoGBAAEAAICEgSP
AQQNGhwgQW4gQXZybyBzY2hlbWEgZGVmaW5pdGlvbi4KCg8KBwQABAACAgESBI8BBAgKDwoH
BAAEAAICAhIEjwELDApfCgQEAAIAEgSUAQI7GlEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHNj
aGVtYS4KIEZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3R9L3NjaGVtYXMve3NjaGVtYX1g
LgoKDQoFBAACAAUSBJQBAggKDQoFBAACAAESBJQBCQ0KDQoFBAACAAMSBJQBEBEKDQoFBAAC
AAgSBJQBEjoKEAoIBAACAAicCAASBJQBEzkKMgoEBAACARIElwECEBokIFRoZSB0eXBlIG9m
IHRoZSBzY2hlbWEgZGVmaW5pdGlvbi4KCg0KBQQAAgEGEgSXAQIGCg0KBQQAAgEBEgSXAQcL
Cg0KBQQAAgEDEgSXAQ4PCr8BCgQEAAICEgScAQIYGrABIFRoZSBkZWZpbml0aW9uIG9mIHRo
ZSBzY2hlbWEuIFRoaXMgc2hvdWxkIGNvbnRhaW4gYSBzdHJpbmcgcmVwcmVzZW50aW5nCiB0
aGUgZnVsbCBkZWZpbml0aW9uIG9mIHRoZSBzY2hlbWEgdGhhdCBpcyBhIHZhbGlkIHNjaGVt
YSBkZWZpbml0aW9uIG9mCiB0aGUgdHlwZSBzcGVjaWZpZWQgaW4gYHR5cGVgLgoKDQoFBAAC
AgUSBJwBAggKDQoFBAACAgESBJwBCRMKDQoFBAACAgMSBJwBFhcKSAoEBAACAxIGnwECogEE
GjggT3V0cHV0IG9ubHkuIEltbXV0YWJsZS4gVGhlIHJldmlzaW9uIElEIG9mIHRoZSBzY2hl
bWEuCgoNCgUEAAIDBRIEnwECCAoNCgUEAAIDARIEnwEJFAoNCgUEAAIDAxIEnwEXGAoPCgUE
AAIDCBIGnwEZogEDChAKCAQAAgMInAgAEgSgAQQrChAKCAQAAgMInAgBEgShAQQtCksKBAQA
AgQSBqUBAqYBMho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHRoYXQgdGhlIHJldmlz
aW9uIHdhcyBjcmVhdGVkLgoKDQoFBAACBAYSBKUBAhsKDQoFBAACBAESBKUBHDAKDQoFBAAC
BAMSBKUBMzQKDQoFBAACBAgSBKYBBjEKEAoIBAACBAicCAASBKYBBzAKWQoCBQASBqoBALQB
ARpLIFZpZXcgb2YgU2NoZW1hIG9iamVjdCBmaWVsZHMgdG8gYmUgcmV0dXJuZWQgYnkgR2V0
U2NoZW1hIGFuZCBMaXN0U2NoZW1hcy4KCgsKAwUAARIEqgEFDwpTCgQFAAIAEgStAQIeGkUg
VGhlIGRlZmF1bHQgLyB1bnNldCB2YWx1ZS4KIFRoZSBBUEkgd2lsbCBkZWZhdWx0IHRvIHRo
ZSBCQVNJQyB2aWV3LgoKDQoFBQACAAESBK0BAhkKDQoFBQACAAISBK0BHB0KUAoEBQACARIE
sAECDBpCIEluY2x1ZGUgdGhlIG5hbWUgYW5kIHR5cGUgb2YgdGhlIHNjaGVtYSwgYnV0IG5v
dCB0aGUgZGVmaW5pdGlvbi4KCg0KBQUAAgEBEgSwAQIHCg0KBQUAAgECEgSwAQoLCjEKBAUA
AgISBLMBAgsaIyBJbmNsdWRlIGFsbCBTY2hlbWEgb2JqZWN0IGZpZWxkcy4KCg0KBQUAAgIB
EgSzAQIGCg0KBQUAAgICEgSzAQkKCjQKAgQBEga3AQDOAQEaJiBSZXF1ZXN0IGZvciB0aGUg
Q3JlYXRlU2NoZW1hIG1ldGhvZC4KCgsKAwQBARIEtwEIGwp2CgQEAQIAEga6AQK/AQQaZiBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHByb2plY3QgaW4gd2hpY2ggdG8gY3JlYXRlIHRo
ZSBzY2hlbWEuCiBGb3JtYXQgaXMgYHByb2plY3RzL3twcm9qZWN0LWlkfWAuCgoNCgUEAQIA
BRIEugECCAoNCgUEAQIAARIEugEJDwoNCgUEAQIAAxIEugESEwoPCgUEAQIACBIGugEUvwED
ChAKCAQBAgAInAgAEgS7AQQqChEKBwQBAgAInwgSBrwBBL4BBQrTAQoEBAECARIExgECPRrE
ASBSZXF1aXJlZC4gVGhlIHNjaGVtYSBvYmplY3QgdG8gY3JlYXRlLgoKIFRoaXMgc2NoZW1h
J3MgYG5hbWVgIHBhcmFtZXRlciBpcyBpZ25vcmVkLiBUaGUgc2NoZW1hIG9iamVjdCByZXR1
cm5lZAogYnkgQ3JlYXRlU2NoZW1hIHdpbGwgaGF2ZSBhIGBuYW1lYCBtYWRlIHVzaW5nIHRo
ZSBnaXZlbiBgcGFyZW50YCBhbmQKIGBzY2hlbWFfaWRgLgoKDQoFBAECAQYSBMYBAggKDQoF
BAECAQESBMYBCQ8KDQoFBAECAQMSBMYBEhMKDQoFBAECAQgSBMYBFDwKEAoIBAECAQicCAAS
BMYBFTsK3AEKBAQBAgISBM0BAhcazQEgVGhlIElEIHRvIHVzZSBmb3IgdGhlIHNjaGVtYSwg
d2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsIGNvbXBvbmVudCBvZgogdGhlIHNjaGVtYSdz
IHJlc291cmNlIG5hbWUuCgogU2VlIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9wdWJzdWIv
ZG9jcy9wdWJzdWItYmFzaWNzI3Jlc291cmNlX25hbWVzIGZvcgogcmVzb3VyY2UgbmFtZSBj
b25zdHJhaW50cy4KCg0KBQQBAgIFEgTNAQIICg0KBQQBAgIBEgTNAQkSCg0KBQQBAgIDEgTN
ARUWCjEKAgQCEgbRAQDcAQEaIyBSZXF1ZXN0IGZvciB0aGUgR2V0U2NoZW1hIG1ldGhvZC4K
CgsKAwQCARIE0QEIGApsCgQEAgIAEgbUAQLXAQQaXCBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIHNjaGVtYSB0byBnZXQuCiBGb3JtYXQgaXMgYHByb2plY3RzL3twcm9qZWN0fS9zY2hl
bWFzL3tzY2hlbWF9YC4KCg0KBQQCAgAFEgTUAQIICg0KBQQCAgABEgTUAQkNCg0KBQQCAgAD
EgTUARARCg8KBQQCAgAIEgbUARLXAQMKEAoIBAICAAicCAASBNUBBCoKDwoHBAICAAifCBIE
1gEETgqgAQoEBAICARIE2wECFhqRASBUaGUgc2V0IG9mIGZpZWxkcyB0byByZXR1cm4gaW4g
dGhlIHJlc3BvbnNlLiBJZiBub3Qgc2V0LCByZXR1cm5zIGEgU2NoZW1hCiB3aXRoIGFsbCBm
aWVsZHMgZmlsbGVkIG91dC4gU2V0IHRvIGBCQVNJQ2AgdG8gb21pdCB0aGUgYGRlZmluaXRp
b25gLgoKDQoFBAICAQYSBNsBAgwKDQoFBAICAQESBNsBDREKDQoFBAICAQMSBNsBFBUKNQoC
BAMSBt8BAPUBARonIFJlcXVlc3QgZm9yIHRoZSBgTGlzdFNjaGVtYXNgIG1ldGhvZC4KCgsK
AwQDARIE3wEIGgpxCgQEAwIAEgbiAQLnAQQaYSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IHByb2plY3QgaW4gd2hpY2ggdG8gbGlzdCBzY2hlbWFzLgogRm9ybWF0IGlzIGBwcm9qZWN0
cy97cHJvamVjdC1pZH1gLgoKDQoFBAMCAAUSBOIBAggKDQoFBAMCAAESBOIBCQ8KDQoFBAMC
AAMSBOIBEhMKDwoFBAMCAAgSBuIBFOcBAwoQCggEAwIACJwIABIE4wEEKgoRCgcEAwIACJ8I
EgbkAQTmAQUKtgEKBAQDAgESBOwBAhYapwEgVGhlIHNldCBvZiBTY2hlbWEgZmllbGRzIHRv
IHJldHVybiBpbiB0aGUgcmVzcG9uc2UuIElmIG5vdCBzZXQsIHJldHVybnMKIFNjaGVtYXMg
d2l0aCBgbmFtZWAgYW5kIGB0eXBlYCwgYnV0IG5vdCBgZGVmaW5pdGlvbmAuIFNldCB0byBg
RlVMTGAgdG8KIHJldHJpZXZlIGFsbCBmaWVsZHMuCgoNCgUEAwIBBhIE7AECDAoNCgUEAwIB
ARIE7AENEQoNCgUEAwIBAxIE7AEUFQo0CgQEAwICEgTvAQIWGiYgTWF4aW11bSBudW1iZXIg
b2Ygc2NoZW1hcyB0byByZXR1cm4uCgoNCgUEAwICBRIE7wECBwoNCgUEAwICARIE7wEIEQoN
CgUEAwICAxIE7wEUFQrGAQoEBAMCAxIE9AECGBq3ASBUaGUgdmFsdWUgcmV0dXJuZWQgYnkg
dGhlIGxhc3QgYExpc3RTY2hlbWFzUmVzcG9uc2VgOyBpbmRpY2F0ZXMgdGhhdAogdGhpcyBp
cyBhIGNvbnRpbnVhdGlvbiBvZiBhIHByaW9yIGBMaXN0U2NoZW1hc2AgY2FsbCwgYW5kIHRo
YXQgdGhlCiBzeXN0ZW0gc2hvdWxkIHJldHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoN
CgUEAwIDBRIE9AECCAoNCgUEAwIDARIE9AEJEwoNCgUEAwIDAxIE9AEWFwo2CgIEBBIG+AEA
/wEBGiggUmVzcG9uc2UgZm9yIHRoZSBgTGlzdFNjaGVtYXNgIG1ldGhvZC4KCgsKAwQEARIE
+AEIGwomCgQEBAIAEgT6AQIeGhggVGhlIHJlc3VsdGluZyBzY2hlbWFzLgoKDQoFBAQCAAQS
BPoBAgoKDQoFBAQCAAYSBPoBCxEKDQoFBAQCAAESBPoBEhkKDQoFBAQCAAMSBPoBHB0KmwEK
BAQEAgESBP4BAh0ajAEgSWYgbm90IGVtcHR5LCBpbmRpY2F0ZXMgdGhhdCB0aGVyZSBtYXkg
YmUgbW9yZSBzY2hlbWFzIHRoYXQgbWF0Y2ggdGhlCiByZXF1ZXN0OyB0aGlzIHZhbHVlIHNo
b3VsZCBiZSBwYXNzZWQgaW4gYSBuZXcgYExpc3RTY2hlbWFzUmVxdWVzdGAuCgoNCgUEBAIB
BRIE/gECCAoNCgUEBAIBARIE/gEJGAoNCgUEBAIBAxIE/gEbHAo9CgIEBRIGggIAlAIBGi8g
UmVxdWVzdCBmb3IgdGhlIGBMaXN0U2NoZW1hUmV2aXNpb25zYCBtZXRob2QuCgoLCgMEBQES
BIICCCIKSQoEBAUCABIGhAIChwIEGjkgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzY2hl
bWEgdG8gbGlzdCByZXZpc2lvbnMgZm9yLgoKDQoFBAUCAAUSBIQCAggKDQoFBAUCAAESBIQC
CQ0KDQoFBAUCAAMSBIQCEBEKDwoFBAUCAAgSBoQCEocCAwoQCggEBQIACJwIABIEhQIEKgoP
CgcEBQIACJ8IEgSGAgROCrYBCgQEBQIBEgSMAgIWGqcBIFRoZSBzZXQgb2YgU2NoZW1hIGZp
ZWxkcyB0byByZXR1cm4gaW4gdGhlIHJlc3BvbnNlLiBJZiBub3Qgc2V0LCByZXR1cm5zCiBT
Y2hlbWFzIHdpdGggYG5hbWVgIGFuZCBgdHlwZWAsIGJ1dCBub3QgYGRlZmluaXRpb25gLiBT
ZXQgdG8gYEZVTExgIHRvCiByZXRyaWV2ZSBhbGwgZmllbGRzLgoKDQoFBAUCAQYSBIwCAgwK
DQoFBAUCAQESBIwCDREKDQoFBAUCAQMSBIwCFBUKQwoEBAUCAhIEjwICFho1IFRoZSBtYXhp
bXVtIG51bWJlciBvZiByZXZpc2lvbnMgdG8gcmV0dXJuIHBlciBwYWdlLgoKDQoFBAUCAgUS
BI8CAgcKDQoFBAUCAgESBI8CCBEKDQoFBAUCAgMSBI8CFBUKgQEKBAQFAgMSBJMCAhgacyBU
aGUgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIExpc3RTY2hlbWFSZXZp
c2lvbnMgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBw
YWdlLgoKDQoFBAUCAwUSBJMCAggKDQoFBAUCAwESBJMCCRMKDQoFBAUCAwMSBJMCFhcKPgoC
BAYSBpcCAJ4CARowIFJlc3BvbnNlIGZvciB0aGUgYExpc3RTY2hlbWFSZXZpc2lvbnNgIG1l
dGhvZC4KCgsKAwQGARIElwIIIwosCgQEBgIAEgSZAgIeGh4gVGhlIHJldmlzaW9ucyBvZiB0
aGUgc2NoZW1hLgoKDQoFBAYCAAQSBJkCAgoKDQoFBAYCAAYSBJkCCxEKDQoFBAYCAAESBJkC
EhkKDQoFBAYCAAMSBJkCHB0KiwEKBAQGAgESBJ0CAh0afSBBIHRva2VuIHRoYXQgY2FuIGJl
IHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0
aGlzIGZpZWxkIGlzIGVtcHR5LCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0K
BQQGAgEFEgSdAgIICg0KBQQGAgEBEgSdAgkYCg0KBQQGAgEDEgSdAhscCjAKAgQHEgahAgCr
AgEaIiBSZXF1ZXN0IGZvciBDb21taXRTY2hlbWEgbWV0aG9kLgoKCwoDBAcBEgShAggbCnUK
BAQHAgASBqQCAqcCBBplIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2NoZW1hIHdlIGFy
ZSByZXZpc2luZy4KIEZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3R9L3NjaGVtYXMve3Nj
aGVtYX1gLgoKDQoFBAcCAAUSBKQCAggKDQoFBAcCAAESBKQCCQ0KDQoFBAcCAAMSBKQCEBEK
DwoFBAcCAAgSBqQCEqcCAwoQCggEBwIACJwIABIEpQIEKgoPCgcEBwIACJ8IEgSmAgROCjgK
BAQHAgESBKoCAj0aKiBSZXF1aXJlZC4gVGhlIHNjaGVtYSByZXZpc2lvbiB0byBjb21taXQu
CgoNCgUEBwIBBhIEqgICCAoNCgUEBwIBARIEqgIJDwoNCgUEBwIBAxIEqgISEwoNCgUEBwIB
CBIEqgIUPAoQCggEBwIBCJwIABIEqgIVOwo4CgIECBIGrgIAugIBGiogUmVxdWVzdCBmb3Ig
dGhlIGBSb2xsYmFja1NjaGVtYWAgbWV0aG9kLgoKCwoDBAgBEgSuAggdCkoKBAQIAgASBrAC
ArMCBBo6IFJlcXVpcmVkLiBUaGUgc2NoZW1hIGJlaW5nIHJvbGxlZCBiYWNrIHdpdGggcmV2
aXNpb24gaWQuCgoNCgUECAIABRIEsAICCAoNCgUECAIAARIEsAIJDQoNCgUECAIAAxIEsAIQ
EQoPCgUECAIACBIGsAISswIDChAKCAQIAgAInAgAEgSxAgQqCg8KBwQIAgAInwgSBLICBE4K
ewoEBAgCARIEuQICQhptIFJlcXVpcmVkLiBUaGUgcmV2aXNpb24gSUQgdG8gcm9sbCBiYWNr
IHRvLgogSXQgbXVzdCBiZSBhIHJldmlzaW9uIG9mIHRoZSBzYW1lIHNjaGVtYS4KCiAgIEV4
YW1wbGU6IGM3Y2ZhMmE4CgoNCgUECAIBBRIEuQICCAoNCgUECAIBARIEuQIJFAoNCgUECAIB
AxIEuQIXGAoNCgUECAIBCBIEuQIZQQoQCggECAIBCJwIABIEuQIaQAo+CgIECRIGvQIAzAIB
GjAgUmVxdWVzdCBmb3IgdGhlIGBEZWxldGVTY2hlbWFSZXZpc2lvbmAgbWV0aG9kLgoKCwoD
BAkBEgS9AggjCqkBCgQECQIAEgbCAgLFAgQamAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRo
ZSBzY2hlbWEgcmV2aXNpb24gdG8gYmUgZGVsZXRlZCwgd2l0aCBhIHJldmlzaW9uIElECiBl
eHBsaWNpdGx5IGluY2x1ZGVkLgoKIEV4YW1wbGU6IGBwcm9qZWN0cy8xMjMvc2NoZW1hcy9t
eS1zY2hlbWFAYzdjZmEyYThgCgoNCgUECQIABRIEwgICCAoNCgUECQIAARIEwgIJDQoNCgUE
CQIAAxIEwgIQEQoPCgUECQIACBIGwgISxQIDChAKCAQJAgAInAgAEgTDAgQqCg8KBwQJAgAI
nwgSBMQCBE4KrAEKBAQJAgESBsoCAssCQhqbASBPcHRpb25hbC4gVGhpcyBmaWVsZCBpcyBk
ZXByZWNhdGVkIGFuZCBzaG91bGQgbm90IGJlIHVzZWQgZm9yIHNwZWNpZnlpbmcKIHRoZSBy
ZXZpc2lvbiBJRC4gVGhlIHJldmlzaW9uIElEIHNob3VsZCBiZSBzcGVjaWZpZWQgdmlhIHRo
ZSBgbmFtZWAKIHBhcmFtZXRlci4KCg0KBQQJAgEFEgTKAgIICg0KBQQJAgEBEgTKAgkUCg0K
BQQJAgEDEgTKAhcYCg0KBQQJAgEIEgTLAgZBCg4KBgQJAgEIAxIEywIHGAoQCggECQIBCJwI
ABIEywIaQAo2CgIEChIGzwIA1gIBGiggUmVxdWVzdCBmb3IgdGhlIGBEZWxldGVTY2hlbWFg
IG1ldGhvZC4KCgsKAwQKARIEzwIIGwprCgQECgIAEgbSAgLVAgQaWyBSZXF1aXJlZC4gTmFt
ZSBvZiB0aGUgc2NoZW1hIHRvIGRlbGV0ZS4KIEZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2pl
Y3R9L3NjaGVtYXMve3NjaGVtYX1gLgoKDQoFBAoCAAUSBNICAggKDQoFBAoCAAESBNICCQ0K
DQoFBAoCAAMSBNICEBEKDwoFBAoCAAgSBtICEtUCAwoQCggECgIACJwIABIE0wIEKgoPCgcE
CgIACJ8IEgTUAgROCjgKAgQLEgbZAgDlAgEaKiBSZXF1ZXN0IGZvciB0aGUgYFZhbGlkYXRl
U2NoZW1hYCBtZXRob2QuCgoLCgMECwESBNkCCB0KdQoEBAsCABIG3AIC4QIEGmUgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBwcm9qZWN0IGluIHdoaWNoIHRvIHZhbGlkYXRlIHNjaGVt
YXMuCiBGb3JtYXQgaXMgYHByb2plY3RzL3twcm9qZWN0LWlkfWAuCgoNCgUECwIABRIE3AIC
CAoNCgUECwIAARIE3AIJDwoNCgUECwIAAxIE3AISEwoPCgUECwIACBIG3AIU4QIDChAKCAQL
AgAInAgAEgTdAgQqChEKBwQLAgAInwgSBt4CBOACBQo4CgQECwIBEgTkAgI9GiogUmVxdWly
ZWQuIFRoZSBzY2hlbWEgb2JqZWN0IHRvIHZhbGlkYXRlLgoKDQoFBAsCAQYSBOQCAggKDQoF
BAsCAQESBOQCCQ8KDQoFBAsCAQMSBOQCEhMKDQoFBAsCAQgSBOQCFDwKEAoIBAsCAQicCAAS
BOQCFTsKRwoCBAwSBOkCACEaOyBSZXNwb25zZSBmb3IgdGhlIGBWYWxpZGF0ZVNjaGVtYWAg
bWV0aG9kLgogRW1wdHkgZm9yIG5vdy4KCgsKAwQMARIE6QIIHgo5CgIEDRIG7AIAhwMBGisg
UmVxdWVzdCBmb3IgdGhlIGBWYWxpZGF0ZU1lc3NhZ2VgIG1ldGhvZC4KCgsKAwQNARIE7AII
Hgp1CgQEDQIAEgbvAgL0AgQaZSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHByb2plY3Qg
aW4gd2hpY2ggdG8gdmFsaWRhdGUgc2NoZW1hcy4KIEZvcm1hdCBpcyBgcHJvamVjdHMve3By
b2plY3QtaWR9YC4KCg0KBQQNAgAFEgTvAgIICg0KBQQNAgABEgTvAgkPCg0KBQQNAgADEgTv
AhITCg8KBQQNAgAIEgbvAhT0AgMKEAoIBA0CAAicCAASBPACBCoKEQoHBA0CAAifCBIG8QIE
8wIFCg4KBAQNCAASBvYCAoADAwoNCgUEDQgAARIE9gIIEwpyCgQEDQIBEgb6AgT8AgYaYiBO
YW1lIG9mIHRoZSBzY2hlbWEgYWdhaW5zdCB3aGljaCB0byB2YWxpZGF0ZS4KCiBGb3JtYXQg
aXMgYHByb2plY3RzL3twcm9qZWN0fS9zY2hlbWFzL3tzY2hlbWF9YC4KCg0KBQQNAgEFEgT6
AgQKCg0KBQQNAgEBEgT6AgsPCg0KBQQNAgEDEgT6AhITCg8KBQQNAgEIEgb6AhT8AgUKDwoH
BA0CAQifCBIE+wIGUAo3CgQEDQICEgT/AgQWGikgQWQtaG9jIHNjaGVtYSBhZ2FpbnN0IHdo
aWNoIHRvIHZhbGlkYXRlCgoNCgUEDQICBhIE/wIECgoNCgUEDQICARIE/wILEQoNCgUEDQIC
AxIE/wIUFQpHCgQEDQIDEgSDAwIUGjkgTWVzc2FnZSB0byB2YWxpZGF0ZSBhZ2FpbnN0IHRo
ZSBwcm92aWRlZCBgc2NoZW1hX3NwZWNgLgoKDQoFBA0CAwUSBIMDAgcKDQoFBA0CAwESBIMD
CA8KDQoFBA0CAwMSBIMDEhMKMgoEBA0CBBIEhgMCGBokIFRoZSBlbmNvZGluZyBleHBlY3Rl
ZCBmb3IgbWVzc2FnZXMKCg0KBQQNAgQGEgSGAwIKCg0KBQQNAgQBEgSGAwsTCg0KBQQNAgQD
EgSGAxYXCkgKAgQOEgSLAwAiGjwgUmVzcG9uc2UgZm9yIHRoZSBgVmFsaWRhdGVNZXNzYWdl
YCBtZXRob2QuCiBFbXB0eSBmb3Igbm93LgoKCwoDBA4BEgSLAwgfCjUKAgUBEgaOAwCYAwEa
JyBQb3NzaWJsZSBlbmNvZGluZyB0eXBlcyBmb3IgbWVzc2FnZXMuCgoLCgMFAQESBI4DBQ0K
GwoEBQECABIEkAMCGxoNIFVuc3BlY2lmaWVkCgoNCgUFAQIAARIEkAMCFgoNCgUFAQIAAhIE
kAMZGgodCgQFAQIBEgSTAwILGg8gSlNPTiBlbmNvZGluZwoKDQoFBQECAQESBJMDAgYKDQoF
BQECAQISBJMDCQoKfQoEBQECAhIElwMCDRpvIEJpbmFyeSBlbmNvZGluZywgYXMgZGVmaW5l
ZCBieSB0aGUgc2NoZW1hIHR5cGUuIEZvciBzb21lIHNjaGVtYSB0eXBlcywKIGJpbmFyeSBl
bmNvZGluZyBtYXkgbm90IGJlIGF2YWlsYWJsZS4KCg0KBQUBAgIBEgSXAwIICg0KBQUBAgIC
EgSXAwsMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Pubsub::V1::Schema::Schema ===
    # Fields for Schema
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.pubsub.v1.Schema.Type)
    # Field: definition Type: 9 ()
    # Field: revision_id Type: 9 ()
    # Field: revision_create_time Type: 11 (.google.protobuf.Timestamp)

=pod

=head1 NAME

Google::Pubsub::V1::Schema::Schema - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::Schema->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<type>

Type: Enum (.google.pubsub.v1.Schema.Type)

=item * B<definition>

Type: String

=item * B<revision_id>

Type: String

=item * B<revision_create_time>

Type: Message (.google.protobuf.Timestamp)

=back

=cut

# Enum: Schema::Type
our $Schema_TYPE_UNSPECIFIED = 0;
our $Schema_PROTOCOL_BUFFER = 1;
our $Schema_AVRO = 2;

=pod

=head2 Enum: Schema::Type

Values:

=over 4

=item * C<TYPE_UNSPECIFIED> => 0

=item * C<PROTOCOL_BUFFER> => 1

=item * C<AVRO> => 2

=back

=cut

# === Message: Google::Pubsub::V1::Schema::CreateSchemaRequest ===
    # Fields for CreateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)
    # Field: schema_id Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::CreateSchemaRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::CreateSchemaRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<schema>

Type: Message (.google.pubsub.v1.Schema)

=item * B<schema_id>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::GetSchemaRequest ===
    # Fields for GetSchemaRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.pubsub.v1.SchemaView)

=pod

=head1 NAME

Google::Pubsub::V1::Schema::GetSchemaRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::GetSchemaRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<view>

Type: Enum (.google.pubsub.v1.SchemaView)

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ListSchemasRequest ===
    # Fields for ListSchemasRequest
    # Field: parent Type: 9 ()
    # Field: view Type: 14 (.google.pubsub.v1.SchemaView)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ListSchemasRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ListSchemasRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<view>

Type: Enum (.google.pubsub.v1.SchemaView)

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ListSchemasResponse ===
    # Fields for ListSchemasResponse
    # Field: schemas Type: 11 (.google.pubsub.v1.Schema)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ListSchemasResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ListSchemasResponse->new(
        schemas => $value,
    );

=head1 FIELDS

=over 4

=item * B<schemas>

Type: Message (.google.pubsub.v1.Schema)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest ===
    # Fields for ListSchemaRevisionsRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.pubsub.v1.SchemaView)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<view>

Type: Enum (.google.pubsub.v1.SchemaView)

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse ===
    # Fields for ListSchemaRevisionsResponse
    # Field: schemas Type: 11 (.google.pubsub.v1.Schema)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse->new(
        schemas => $value,
    );

=head1 FIELDS

=over 4

=item * B<schemas>

Type: Message (.google.pubsub.v1.Schema)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::CommitSchemaRequest ===
    # Fields for CommitSchemaRequest
    # Field: name Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)

=pod

=head1 NAME

Google::Pubsub::V1::Schema::CommitSchemaRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::CommitSchemaRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<schema>

Type: Message (.google.pubsub.v1.Schema)

=back

=cut

# === Message: Google::Pubsub::V1::Schema::RollbackSchemaRequest ===
    # Fields for RollbackSchemaRequest
    # Field: name Type: 9 ()
    # Field: revision_id Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::RollbackSchemaRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::RollbackSchemaRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<revision_id>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest ===
    # Fields for DeleteSchemaRevisionRequest
    # Field: name Type: 9 ()
    # Field: revision_id Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<revision_id>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::DeleteSchemaRequest ===
    # Fields for DeleteSchemaRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Pubsub::V1::Schema::DeleteSchemaRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::DeleteSchemaRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ValidateSchemaRequest ===
    # Fields for ValidateSchemaRequest
    # Field: parent Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ValidateSchemaRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ValidateSchemaRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<schema>

Type: Message (.google.pubsub.v1.Schema)

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ValidateSchemaResponse ===
    # Fields for ValidateSchemaResponse

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ValidateSchemaResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ValidateSchemaResponse->new(
    );

=head1 FIELDS

=over 4

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ValidateMessageRequest ===
    # Fields for ValidateMessageRequest
    # Field: parent Type: 9 ()
    # Field: name Type: 9 ()
    # Field: schema Type: 11 (.google.pubsub.v1.Schema)
    # Field: message Type: 12 ()
    # Field: encoding Type: 14 (.google.pubsub.v1.Encoding)

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ValidateMessageRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ValidateMessageRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<name>

Type: String

=item * B<schema>

Type: Message (.google.pubsub.v1.Schema)

=item * B<message>

Type: Bytes

=item * B<encoding>

Type: Enum (.google.pubsub.v1.Encoding)

=back

=cut

# === Message: Google::Pubsub::V1::Schema::ValidateMessageResponse ===
    # Fields for ValidateMessageResponse

=pod

=head1 NAME

Google::Pubsub::V1::Schema::ValidateMessageResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Pubsub::V1::Schema;

    my $msg = Google::Pubsub::V1::Schema::ValidateMessageResponse->new(
    );

=head1 FIELDS

=over 4

=back

=cut

# === Service Client: Google::Pubsub::V1::Schema::SchemaServiceClient ===
package Google::Pubsub::V1::Schema::SchemaServiceClient;

=pod

=head1 NAME

Google::Pubsub::V1::Schema::SchemaServiceClient - Client stub representing the remote SchemaService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<pubsub.googleapis.com:443>.

=head2 credentials

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

=head1 NAME

Google::Pubsub::V1::Schema - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
