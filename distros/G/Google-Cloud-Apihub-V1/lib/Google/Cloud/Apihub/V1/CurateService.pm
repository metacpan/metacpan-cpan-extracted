package Google::Cloud::Apihub::V1::CurateService;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYXBpaHViL3YxL2N1cmF0ZV9zZXJ2aWNlLnByb3RvEhZnb29nbGUu
Y2xvdWQuYXBpaHViLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBn
b29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byLAAQoVQ3JlYXRlQ3VyYXRpb25SZXF1ZXN0Ej4KBnBhcmVudBgBIAEoCUIm
4EEC+kEgEh5hcGlodWIuZ29vZ2xlYXBpcy5jb20vQ3VyYXRpb25SBnBhcmVudBIkCgtjdXJh
dGlvbl9pZBgCIAEoCUID4EEBUgpjdXJhdGlvbklkEkEKCGN1cmF0aW9uGAMgASgLMiAuZ29v
Z2xlLmNsb3VkLmFwaWh1Yi52MS5DdXJhdGlvbkID4EECUghjdXJhdGlvbiJQChJHZXRDdXJh
dGlvblJlcXVlc3QSOgoEbmFtZRgBIAEoCUIm4EEC+kEgCh5hcGlodWIuZ29vZ2xlYXBpcy5j
b20vQ3VyYXRpb25SBG5hbWUinAEKFVVwZGF0ZUN1cmF0aW9uUmVxdWVzdBJBCghjdXJhdGlv
bhgBIAEoCzIgLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuQ3VyYXRpb25CA+BBAlIIY3VyYXRp
b24SQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPg
QQFSCnVwZGF0ZU1hc2siUwoVRGVsZXRlQ3VyYXRpb25SZXF1ZXN0EjoKBG5hbWUYASABKAlC
JuBBAvpBIAoeYXBpaHViLmdvb2dsZWFwaXMuY29tL0N1cmF0aW9uUgRuYW1lIrkBChRMaXN0
Q3VyYXRpb25zUmVxdWVzdBI+CgZwYXJlbnQYASABKAlCJuBBAvpBIBIeYXBpaHViLmdvb2ds
ZWFwaXMuY29tL0N1cmF0aW9uUgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQFSBmZpbHRl
chIgCglwYWdlX3NpemUYAyABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgEIAEo
CUID4EEBUglwYWdlVG9rZW4ifwoVTGlzdEN1cmF0aW9uc1Jlc3BvbnNlEj4KCWN1cmF0aW9u
cxgBIAMoCzIgLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuQ3VyYXRpb25SCWN1cmF0aW9ucxIm
Cg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i/wgKCEN1cmF0aW9uEhcK
BG5hbWUYASABKAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlz
cGxheU5hbWUSJQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SQQoIZW5k
cG9pbnQYBCABKAsyIC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkVuZHBvaW50QgPgQQJSCGVu
ZHBvaW50EnQKF3BsdWdpbl9pbnN0YW5jZV9hY3Rpb25zGAUgAygLMjcuZ29vZ2xlLmNsb3Vk
LmFwaWh1Yi52MS5DdXJhdGlvbi5QbHVnaW5JbnN0YW5jZUFjdGlvbklEQgPgQQNSFXBsdWdp
bkluc3RhbmNlQWN0aW9ucxJqChRsYXN0X2V4ZWN1dGlvbl9zdGF0ZRgGIAEoDjIzLmdvb2ds
ZS5jbG91ZC5hcGlodWIudjEuQ3VyYXRpb24uTGFzdEV4ZWN1dGlvblN0YXRlQgPgQQNSEmxh
c3RFeGVjdXRpb25TdGF0ZRJqChlsYXN0X2V4ZWN1dGlvbl9lcnJvcl9jb2RlGAcgASgOMiou
Z29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5DdXJhdGlvbi5FcnJvckNvZGVCA+BBA1IWbGFzdEV4
ZWN1dGlvbkVycm9yQ29kZRJEChxsYXN0X2V4ZWN1dGlvbl9lcnJvcl9tZXNzYWdlGAggASgJ
QgPgQQNSGWxhc3RFeGVjdXRpb25FcnJvck1lc3NhZ2USQAoLY3JlYXRlX3RpbWUYCSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRl
X3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRp
bWUakQEKFlBsdWdpbkluc3RhbmNlQWN0aW9uSUQSVQoPcGx1Z2luX2luc3RhbmNlGAEgASgJ
QizgQQP6QSYKJGFwaWh1Yi5nb29nbGVhcGlzLmNvbS9QbHVnaW5JbnN0YW5jZVIOcGx1Z2lu
SW5zdGFuY2USIAoJYWN0aW9uX2lkGAIgASgJQgPgQQNSCGFjdGlvbklkIlUKEkxhc3RFeGVj
dXRpb25TdGF0ZRIkCiBMQVNUX0VYRUNVVElPTl9TVEFURV9VTlNQRUNJRklFRBAAEg0KCVNV
Q0NFRURFRBABEgoKBkZBSUxFRBACIk0KCUVycm9yQ29kZRIaChZFUlJPUl9DT0RFX1VOU1BF
Q0lGSUVEEAASEgoOSU5URVJOQUxfRVJST1IQARIQCgxVTkFVVEhPUklaRUQQAjp26kFzCh5h
cGlodWIuZ29vZ2xlYXBpcy5jb20vQ3VyYXRpb24SPHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jdXJhdGlvbnMve2N1cmF0aW9ufSoJY3VyYXRpb25zMghjdXJh
dGlvbiK+AQoIRW5kcG9pbnQSnQEKKGFwcGxpY2F0aW9uX2ludGVncmF0aW9uX2VuZHBvaW50
X2RldGFpbHMYASABKAsyPS5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkFwcGxpY2F0aW9uSW50
ZWdyYXRpb25FbmRwb2ludERldGFpbHNCA+BBAkgAUiVhcHBsaWNhdGlvbkludGVncmF0aW9u
RW5kcG9pbnREZXRhaWxzQhIKEGVuZHBvaW50X2RldGFpbHMiYgolQXBwbGljYXRpb25JbnRl
Z3JhdGlvbkVuZHBvaW50RGV0YWlscxIVCgN1cmkYASABKAlCA+BBAlIDdXJpEiIKCnRyaWdn
ZXJfaWQYAiABKAlCA+BBAlIJdHJpZ2dlcklkMsQHCgxBcGlIdWJDdXJhdGUSwAEKDkNyZWF0
ZUN1cmF0aW9uEi0uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5DcmVhdGVDdXJhdGlvblJlcXVl
c3QaIC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkN1cmF0aW9uIl2C0+STAjkiLS92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2N1cmF0aW9uczoIY3VyYXRpb27aQRtwYXJl
bnQsY3VyYXRpb24sY3VyYXRpb25faWQSmQEKC0dldEN1cmF0aW9uEiouZ29vZ2xlLmNsb3Vk
LmFwaWh1Yi52MS5HZXRDdXJhdGlvblJlcXVlc3QaIC5nb29nbGUuY2xvdWQuYXBpaHViLnYx
LkN1cmF0aW9uIjyC0+STAi8SLS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2N1
cmF0aW9ucy8qfdpBBG5hbWUSrAEKDUxpc3RDdXJhdGlvbnMSLC5nb29nbGUuY2xvdWQuYXBp
aHViLnYxLkxpc3RDdXJhdGlvbnNSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5M
aXN0Q3VyYXRpb25zUmVzcG9uc2UiPoLT5JMCLxItL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKn0vY3VyYXRpb25z2kEGcGFyZW50EsIBCg5VcGRhdGVDdXJhdGlvbhItLmdv
b2dsZS5jbG91ZC5hcGlodWIudjEuVXBkYXRlQ3VyYXRpb25SZXF1ZXN0GiAuZ29vZ2xlLmNs
b3VkLmFwaWh1Yi52MS5DdXJhdGlvbiJfgtPkkwJCMjYvdjEve2N1cmF0aW9uLm5hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jdXJhdGlvbnMvKn06CGN1cmF0aW9u2kEUY3VyYXRpb24s
dXBkYXRlX21hc2sSlQEKDkRlbGV0ZUN1cmF0aW9uEi0uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52
MS5EZWxldGVDdXJhdGlvblJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiPILT5JMC
LyotL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY3VyYXRpb25zLyp92kEEbmFt
ZRpJykEVYXBpaHViLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9jbG91ZC1wbGF0Zm9ybUK0AQoaY29tLmdvb2dsZS5jbG91ZC5hcGlodWIudjFC
EkN1cmF0ZVNlcnZpY2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2FwaWh1Yi9hcGl2
MS9hcGlodWJwYjthcGlodWJwYqoCFkdvb2dsZS5DbG91ZC5BcGlIdWIuVjHKAhZHb29nbGVc
Q2xvdWRcQXBpSHViXFYx6gIZR29vZ2xlOjpDbG91ZDo6QXBpSHViOjpWMUrlXQoHEgUOANgC
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACUKCQoCAwUS
AxcAKgoJCgIDBhIDGAApCggKAQgSAxoAMwoJCgIIJRIDGgAzCggKAQgSAxsASQoJCgIICxID
GwBJCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AMwoJCgIICBIDHQAzCggKAQgSAx4A
MwoJCgIIARIDHgAzCggKAQgSAx8AMwoJCgIIKRIDHwAzCggKAQgSAyAAMgoJCgIILRIDIAAy
Cm8KAgYAEgQkAFwBGmMgVGhpcyBzZXJ2aWNlIGlzIHVzZWQgZm9yIG1hbmFnaW5nIGN1cmF0
aW9ucyBmb3IgcHJvY2Vzc2luZyBBUEkgZGF0YSBjb25zdW1lZAogZnJvbSBjb2xsZWN0IGxh
eWVyLgoKCgoDBgABEgMkCBQKCgoDBgADEgMlAj0KDAoFBgADmQgSAyUCPQoLCgMGAAMSBCYC
JzcKDQoFBgADmggSBCYCJzcKhQEKBAYAAgASBCsCMQMadyBDcmVhdGUgYSBjdXJhdGlvbiBy
ZXNvdXJjZSBpbiB0aGUgQVBJIGh1Yi4KIE9uY2UgYSBjdXJhdGlvbiByZXNvdXJjZSBpcyBj
cmVhdGVkLCBwbHVnaW4gaW5zdGFuY2VzIGNhbiBzdGFydCB1c2luZyBpdC4KCgwKBQYAAgAB
EgMrBhQKDAoFBgACAAISAysVKgoMCgUGAAIAAxIDKzU9Cg0KBQYAAgAEEgQsBC8GChEKCQYA
AgAEsMq8IhIELAQvBgoMCgUGAAIABBIDMARJCg8KCAYAAgAEmwgAEgMwBEkKLgoEBgACARIE
NAI5AxogIEdldCBjdXJhdGlvbiByZXNvdXJjZSBkZXRhaWxzLgoKDAoFBgACAQESAzQGEQoM
CgUGAAIBAhIDNBIkCgwKBQYAAgEDEgM0LzcKDQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwi
EgQ1BDcGCgwKBQYAAgEEEgM4BDIKDwoIBgACAQSbCAASAzgEMgo3CgQGAAICEgQ8AkEDGikg
TGlzdCBjdXJhdGlvbiByZXNvdXJjZXMgaW4gdGhlIEFQSSBodWIuCgoMCgUGAAICARIDPAYT
CgwKBQYAAgICEgM8FCgKDAoFBgACAgMSAzwzSAoNCgUGAAICBBIEPQQ/BgoRCgkGAAICBLDK
vCISBD0EPwYKDAoFBgACAgQSA0AENAoPCggGAAICBJsIABIDQAQ0CpIDCgQGAAIDEgRMAlID
GoMDIFVwZGF0ZSBhIGN1cmF0aW9uIHJlc291cmNlIGluIHRoZSBBUEkgaHViLiBUaGUgZm9s
bG93aW5nIGZpZWxkcyBpbiB0aGUKIFtjdXJhdGlvbl1bZ29vZ2xlLmNsb3VkLmFwaWh1Yi52
MS5DdXJhdGlvbl0gY2FuIGJlIHVwZGF0ZWQ6CgogKiBbZGlzcGxheV9uYW1lXVtnb29nbGUu
Y2xvdWQuYXBpaHViLnYxLkN1cmF0aW9uLmRpc3BsYXlfbmFtZV0KICogW2Rlc2NyaXB0aW9u
XVtnb29nbGUuY2xvdWQuYXBpaHViLnYxLkN1cmF0aW9uLmRlc2NyaXB0aW9uXQoKIFRoZQog
W3VwZGF0ZV9tYXNrXVtnb29nbGUuY2xvdWQuYXBpaHViLnYxLlVwZGF0ZUFwaVJlcXVlc3Qu
dXBkYXRlX21hc2tdCiBzaG91bGQgYmUgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgYmVp
bmcgdXBkYXRlZC4KCgwKBQYAAgMBEgNMBhQKDAoFBgACAwISA0wVKgoMCgUGAAIDAxIDTDU9
Cg0KBQYAAgMEEgRNBFAGChEKCQYAAgMEsMq8IhIETQRQBgoMCgUGAAIDBBIDUQRCCg8KCAYA
AgMEmwgAEgNRBEIKiQEKBAYAAgQSBFYCWwMaeyBEZWxldGUgYSBjdXJhdGlvbiByZXNvdXJj
ZSBpbiB0aGUgQVBJIGh1Yi4gQSBjdXJhdGlvbiBjYW4gb25seSBiZSBkZWxldGVkCiBpZiBp
dCdzIG5vdCBiZWluZyB1c2VkIGJ5IGFueSBwbHVnaW4gaW5zdGFuY2UuCgoMCgUGAAIEARID
VgYUCgwKBQYAAgQCEgNWFSoKDAoFBgACBAMSA1Y1SgoNCgUGAAIEBBIEVwRZBgoRCgkGAAIE
BLDKvCISBFcEWQYKDAoFBgACBAQSA1oEMgoPCggGAAIEBJsIABIDWgQyCksKAgQAEgRfAHcB
Gj8gVGhlIFtDcmVhdGVDdXJhdGlvbl1bQXBpSHViLkNyZWF0ZUN1cmF0aW9uXSBtZXRob2Qn
cyByZXF1ZXN0LgoKCgoDBAABEgNfCB0KewoEBAACABIEYgJnBBptIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIGZvciB0aGUgY3VyYXRpb24gcmVzb3VyY2UuCiBGb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCgoMCgUEAAIABRIDYgII
CgwKBQQAAgABEgNiCQ8KDAoFBAACAAMSA2ISEwoNCgUEAAIACBIEYhRnAwoPCggEAAIACJwI
ABIDYwQqCg8KBwQAAgAInwgSBGQEZgUKzgMKBAQAAgESA3MCQhrAAyBPcHRpb25hbC4gVGhl
IElEIHRvIHVzZSBmb3IgdGhlIGN1cmF0aW9uIHJlc291cmNlLCB3aGljaCB3aWxsIGJlY29t
ZSB0aGUKIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUgY3VyYXRpb25zJ3MgcmVzb3VyY2UgbmFt
ZS4gVGhpcyBmaWVsZCBpcyBvcHRpb25hbC4KCiAqIElmIHByb3ZpZGVkLCB0aGUgc2FtZSB3
aWxsIGJlIHVzZWQuIFRoZSBzZXJ2aWNlIHdpbGwgdGhyb3cgYW4gZXJyb3IgaWYKIHRoZSBz
cGVjaWZpZWQgSUQgaXMgYWxyZWFkeSB1c2VkIGJ5IGFub3RoZXIgY3VyYXRpb24gcmVzb3Vy
Y2UgaW4gdGhlIEFQSQogaHViLgogKiBJZiBub3QgcHJvdmlkZWQsIGEgc3lzdGVtIGdlbmVy
YXRlZCBJRCB3aWxsIGJlIHVzZWQuCgogVGhpcyB2YWx1ZSBzaG91bGQgYmUgNC01MDAgY2hh
cmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMKIGFyZSAvW2Etel1bQS1aXVswLTldLV8v
LgoKDAoFBAACAQUSA3MCCAoMCgUEAAIBARIDcwkUCgwKBQQAAgEDEgNzFxgKDAoFBAACAQgS
A3MZQQoPCggEAAIBCJwIABIDcxpACjkKBAQAAgISA3YCQRosIFJlcXVpcmVkLiBUaGUgY3Vy
YXRpb24gcmVzb3VyY2UgdG8gY3JlYXRlLgoKDAoFBAACAgYSA3YCCgoMCgUEAAICARIDdgsT
CgwKBQQAAgIDEgN2FhcKDAoFBAACAggSA3YYQAoPCggEAAICCJwIABIDdhk/CkYKAgQBEgV6
AIEBARo5IFRoZSBbR2V0Q3VyYXRpb25dW0FwaUh1Yi5HZXRDdXJhdGlvbl0gbWV0aG9kJ3Mg
cmVxdWVzdC4KCgoKAwQBARIDeggaCpIBCgQEAQIAEgV9AoABBBqCASBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIGN1cmF0aW9uIHJlc291cmNlIHRvIHJldHJpZXZlLgogRm9ybWF0OiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2N1cmF0aW9ucy97Y3Vy
YXRpb259YAoKDAoFBAECAAUSA30CCAoMCgUEAQIAARIDfQkNCgwKBQQBAgADEgN9EBEKDgoF
BAECAAgSBX0SgAEDCg8KCAQBAgAInAgAEgN+BCoKDgoHBAECAAifCBIDfwRQCk0KAgQCEgaE
AQCPAQEaPyBUaGUgW1VwZGF0ZUN1cmF0aW9uXVtBcGlIdWIuVXBkYXRlQ3VyYXRpb25dIG1l
dGhvZCdzIHJlcXVlc3QuCgoLCgMEAgESBIQBCB0K4AEKBAQCAgASBIoBAkEa0QEgUmVxdWly
ZWQuIFRoZSBjdXJhdGlvbiByZXNvdXJjZSB0byB1cGRhdGUuCgogVGhlIGN1cmF0aW9uIHJl
c291cmNlJ3MgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIGN1cmF0aW9u
CiByZXNvdXJjZSB0byB1cGRhdGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY3VyYXRpb25zL3tjdXJhdGlvbn1gCgoNCgUEAgIABhIEigEC
CgoNCgUEAgIAARIEigELEwoNCgUEAgIAAxIEigEWFwoNCgUEAgIACBIEigEYQAoQCggEAgIA
CJwIABIEigEZPwo5CgQEAgIBEgaNAQKOAS8aKSBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgZmll
bGRzIHRvIHVwZGF0ZS4KCg0KBQQCAgEGEgSNAQIbCg0KBQQCAgEBEgSNARwnCg0KBQQCAgED
EgSNASorCg0KBQQCAgEIEgSOAQYuChAKCAQCAgEInAgAEgSOAQctCk0KAgQDEgaSAQCZAQEa
PyBUaGUgW0RlbGV0ZUN1cmF0aW9uXVtBcGlIdWIuRGVsZXRlQ3VyYXRpb25dIG1ldGhvZCdz
IHJlcXVlc3QuCgoLCgMEAwESBJIBCB0KkQEKBAQDAgASBpUBApgBBBqAASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIGN1cmF0aW9uIHJlc291cmNlIHRvIGRlbGV0ZS4KIEZvcm1hdDog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jdXJhdGlvbnMve2N1
cmF0aW9ufWAKCg0KBQQDAgAFEgSVAQIICg0KBQQDAgABEgSVAQkNCg0KBQQDAgADEgSVARAR
Cg8KBQQDAgAIEgaVARKYAQMKEAoIBAMCAAicCAASBJYBBCoKDwoHBAMCAAifCBIElwEEUApL
CgIEBBIGnAEA0QEBGj0gVGhlIFtMaXN0Q3VyYXRpb25zXVtBcGlIdWIuTGlzdEN1cmF0aW9u
c10gbWV0aG9kJ3MgcmVxdWVzdC4KCgsKAwQEARIEnAEIHAqMAQoEBAQCABIGnwECpAEEGnwg
UmVxdWlyZWQuIFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mIGN1
cmF0aW9uIHJlc291cmNlcy4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufWAKCg0KBQQEAgAFEgSfAQIICg0KBQQEAgABEgSfAQkPCg0KBQQEAgAD
EgSfARITCg8KBQQEAgAIEgafARSkAQMKEAoIBAQCAAicCAASBKABBCoKEQoHBAQCAAifCBIG
oQEEowEFCpELCgQEBAIBEgTDAQI9GoILIE9wdGlvbmFsLiBBbiBleHByZXNzaW9uIHRoYXQg
ZmlsdGVycyB0aGUgbGlzdCBvZiBjdXJhdGlvbiByZXNvdXJjZXMuCgogQSBmaWx0ZXIgZXhw
cmVzc2lvbiBjb25zaXN0cyBvZiBhIGZpZWxkIG5hbWUsIGEgY29tcGFyaXNvbgogb3BlcmF0
b3IsIGFuZCBhIHZhbHVlIGZvciBmaWx0ZXJpbmcuIFRoZSB2YWx1ZSBtdXN0IGJlIGEgc3Ry
aW5nLiBUaGUKIGNvbXBhcmlzb24gb3BlcmF0b3IgbXVzdCBiZSBvbmUgb2Y6IGA8YCwgYD5g
LCBgOmAgb3IgYD1gLiBGaWx0ZXJzIGFyZSBjYXNlCiBpbnNlbnNpdGl2ZS4KCiBUaGUgZm9s
bG93aW5nIGZpZWxkcyBpbiB0aGUgYGN1cmF0aW9uIHJlc291cmNlYCBhcmUgZWxpZ2libGUg
Zm9yIGZpbHRlcmluZzoKCiAgICogYGNyZWF0ZV90aW1lYCAtIFRoZSB0aW1lIGF0IHdoaWNo
IHRoZSBjdXJhdGlvbiB3YXMgY3JlYXRlZC4KICAgVGhlIHZhbHVlIHNob3VsZCBiZSBpbiB0
aGUgKFJGQzMzMzkpW2h0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMzMzM5XQogICBm
b3JtYXQuIEFsbG93ZWQgY29tcGFyaXNvbiBvcGVyYXRvcnM6IGA+YCBhbmQgYDxgLgogICAq
IGBkaXNwbGF5X25hbWVgIC0gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgY3VyYXRpb24uIEFs
bG93ZWQKICAgY29tcGFyaXNvbiBvcGVyYXRvcnM6IGA9YC4KICAgKiBgc3RhdGVgIC0gVGhl
IHN0YXRlIG9mIHRoZSBjdXJhdGlvbi4gQWxsb3dlZCBjb21wYXJpc29uIG9wZXJhdG9yczog
YD1gLgoKIEV4cHJlc3Npb25zIGFyZSBjb21iaW5lZCB3aXRoIGVpdGhlciBgQU5EYCBsb2dp
YyBvcGVyYXRvciBvciBgT1JgIGxvZ2ljYWwKIG9wZXJhdG9yIGJ1dCBub3QgYm90aCBvZiB0
aGVtIHRvZ2V0aGVyIGkuZS4gb25seSBvbmUgb2YgdGhlIGBBTkRgIG9yIGBPUmAKIG9wZXJh
dG9yIGNhbiBiZSB1c2VkIHRocm91Z2hvdXQgdGhlIGZpbHRlciBzdHJpbmcgYW5kIGJvdGgg
dGhlIG9wZXJhdG9ycwogY2Fubm90IGJlIHVzZWQgdG9nZXRoZXIuIE5vIG90aGVyIGxvZ2lj
YWwgb3BlcmF0b3JzIGFyZSBzdXBwb3J0ZWQuIEF0IG1vc3QKIHRocmVlIGZpbHRlciBmaWVs
ZHMgYXJlIGFsbG93ZWQgaW4gdGhlIGZpbHRlciBzdHJpbmcgYW5kIGlmIHByb3ZpZGVkCiBt
b3JlIHRoYW4gdGhhdCB0aGVuIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyByZXR1cm5l
ZCBieSB0aGUgQVBJLgoKIEhlcmUgYXJlIGEgZmV3IGV4YW1wbGVzOgoKICAgKiBgY3JlYXRl
X3RpbWUgPCBcIjIwMjEtMDgtMTVUMTQ6NTA6MDBaXCIgQU5EIGNyZWF0ZV90aW1lID4KICAg
XCIyMDIxLTA4LTEwVDEyOjAwOjAwWlwiYCAtCiAgIFRoZSBjdXJhdGlvbiByZXNvdXJjZSB3
YXMgY3JlYXRlZCBiZWZvcmUgXzIwMjEtMDgtMTUgMTQ6NTA6MDAgVVRDXyBhbmQKICAgYWZ0
ZXIgXzIwMjEtMDgtMTAgMTI6MDA6MDAgVVRDXy4KCg0KBQQEAgEFEgTDAQIICg0KBQQEAgEB
EgTDAQkPCg0KBQQEAgEDEgTDARITCg0KBQQEAgEIEgTDARQ8ChAKCAQEAgEInAgAEgTDARU7
CvwBCgQEBAICEgTJAQI/Gu0BIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgY3Vy
YXRpb24gcmVzb3VyY2VzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UKIG1heSByZXR1cm4gZmV3
ZXIgdGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBjdXJhdGlv
bnMgd2lsbAogYmUgcmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVl
cyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZAogdG8gMTAwMC4KCg0KBQQEAgIFEgTJAQIH
Cg0KBQQEAgIBEgTJAQgRCg0KBQQEAgIDEgTJARQVCg0KBQQEAgIIEgTJARY+ChAKCAQEAgII
nAgAEgTJARc9CpACCgQEBAIDEgTQAQJBGoECIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJl
Y2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdEN1cmF0aW9uc2AgY2FsbC4KIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGlu
ZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgKGV4Y2VwdCBwYWdlX3NpemUpIHByb3ZpZGVkIHRv
CiBgTGlzdEN1cmF0aW9uc2AgbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRo
ZSBwYWdlIHRva2VuLgoKDQoFBAQCAwUSBNABAggKDQoFBAQCAwESBNABCRMKDQoFBAQCAwMS
BNABFhcKDQoFBAQCAwgSBNABGEAKEAoIBAQCAwicCAASBNABGT8KTAoCBAUSBtQBANsBARo+
IFRoZSBbTGlzdEN1cmF0aW9uc11bQXBpSHViLkxpc3RDdXJhdGlvbnNdIG1ldGhvZCdzIHJl
c3BvbnNlLgoKCwoDBAUBEgTUAQgdCj4KBAQFAgASBNYBAiIaMCBUaGUgY3VyYXRpb24gcmVz
b3VyY2VzIHByZXNlbnQgaW4gdGhlIEFQSSBodWIuCgoNCgUEBQIABBIE1gECCgoNCgUEBQIA
BhIE1gELEwoNCgUEBQIAARIE1gEUHQoNCgUEBQIAAxIE1gEgIQqQAQoEBAUCARIE2gECHRqB
ASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmll
dmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJl
IG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEBQIBBRIE2gECCAoNCgUEBQIBARIE2gEJGAoN
CgUEBQIBAxIE2gEbHAozCgIEBhIG3gEAugIBGiUgQSBjdXJhdGlvbiByZXNvdXJjZSBpbiB0
aGUgQVBJIEh1Yi4KCgsKAwQGARIE3gEIEAoNCgMEBgcSBt8BAuQBBAoPCgUEBgedCBIG3wEC
5AEEClcKBAQGAwASBucBAvYBAxpHIFRoZSBwbHVnaW4gaW5zdGFuY2UgYW5kIGFzc29jaWF0
ZWQgYWN0aW9uIHRoYXQgaXMgdXNpbmcgdGhlIGN1cmF0aW9uLgoKDQoFBAYDAAESBOcBCiAK
qQEKBgQGAwACABIG6wEE8AEGGpYBIE91dHB1dCBvbmx5LiBQbHVnaW4gaW5zdGFuY2UgdGhh
dCBpcyB1c2luZyB0aGUgY3VyYXRpb24uCiBGb3JtYXQgaXMKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcGx1Z2lucy97cGx1Z2lufS9pbnN0YW5jZXMve2lu
c3RhbmNlfWAKCg8KBwQGAwACAAUSBOsBBAoKDwoHBAYDAAIAARIE6wELGgoPCgcEBgMAAgAD
EgTrAR0eChEKBwQGAwACAAgSBusBH/ABBQoSCgoEBgMAAgAInAgAEgTsAQYvChMKCQQGAwAC
AAifCBIG7QEG7wEHCp8BCgYEBgMAAgESBPUBBEUajgEgT3V0cHV0IG9ubHkuIFRoZSBhY3Rp
b24gSUQgdGhhdCBpcyB1c2luZyB0aGUgY3VyYXRpb24uCiBUaGlzIHNob3VsZCBtYXAgdG8g
b25lIG9mIHRoZSBhY3Rpb24gSURzIHNwZWNpZmllZAogaW4gYWN0aW9uIGNvbmZpZ3MgaW4g
dGhlIHBsdWdpbi4KCg8KBwQGAwACAQUSBPUBBAoKDwoHBAYDAAIBARIE9QELFAoPCgcEBgMA
AgEDEgT1ARcYCg8KBwQGAwACAQgSBPUBGUQKEgoKBAYDAAIBCJwIABIE9QEaQwpCCgQEBgQA
Egb5AQKCAgMaMiBUaGUgc3RhdGUgb2YgdGhlIGxhc3QgZXhlY3V0aW9uIG9mIHRoZSBjdXJh
dGlvbi4KCg0KBQQGBAABEgT5AQcZCiwKBgQGBAACABIE+wEEKRocIERlZmF1bHQgdW5zcGVj
aWZpZWQgc3RhdGUuCgoPCgcEBgQAAgABEgT7AQQkCg8KBwQGBAACAAISBPsBJygKPQoGBAYE
AAIBEgT+AQQSGi0gVGhlIGxhc3QgY3VyYXRpb24gZXhlY3V0aW9uIHdhcyBzdWNjZXNzZnVs
LgoKDwoHBAYEAAIBARIE/gEEDQoPCgcEBgQAAgECEgT+ARARCjUKBgQGBAACAhIEgQIEDxol
IFRoZSBsYXN0IGN1cmF0aW9uIGV4ZWN1dGlvbiBmYWlsZWQuCgoPCgcEBgQAAgIBEgSBAgQK
Cg8KBwQGBAACAgISBIECDQ4KOAoEBAYEARIGhQICjgIDGiggVGhlIGVycm9yIGNvZGVzIGZv
ciBmYWlsZWQgZXhlY3V0aW9ucy4KCg0KBQQGBAEBEgSFAgcQCjEKBgQGBAECABIEhwIEHxoh
IERlZmF1bHQgdW5zcGVjaWZpZWQgZXJyb3IgY29kZS4KCg8KBwQGBAECAAESBIcCBBoKDwoH
BAYEAQIAAhIEhwIdHgpACgYEBgQBAgESBIoCBBcaMCBUaGUgZXhlY3V0aW9uIGZhaWxlZCBk
dWUgdG8gYW4gaW50ZXJuYWwgZXJyb3IuCgoPCgcEBgQBAgEBEgSKAgQSCg8KBwQGBAECAQIS
BIoCFRYKTQoGBAYEAQICEgSNAgQVGj0gVGhlIGN1cmF0aW9uIGlzIG5vdCBhdXRob3JpemVk
IHRvIHRyaWdnZXIgdGhlIGVuZHBvaW50IHVyaS4KCg8KBwQGBAECAgESBI0CBBAKDwoHBAYE
AQICAhIEjQITFAp/CgQEBgIAEgSUAgI9GnEgSWRlbnRpZmllci4gVGhlIG5hbWUgb2YgdGhl
IGN1cmF0aW9uLgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vY3VyYXRpb25zL3tjdXJhdGlvbn1gCgoNCgUEBgIABRIElAICCAoNCgUEBgIA
ARIElAIJDQoNCgUEBgIAAxIElAIQEQoNCgUEBgIACBIElAISPAoQCggEBgIACJwIABIElAIT
Owo7CgQEBgIBEgSXAgJDGi0gUmVxdWlyZWQuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGN1
cmF0aW9uLgoKDQoFBAYCAQUSBJcCAggKDQoFBAYCAQESBJcCCRUKDQoFBAYCAQMSBJcCGBkK
DQoFBAYCAQgSBJcCGkIKEAoIBAYCAQicCAASBJcCG0EKOgoEBAYCAhIEmgICQhosIE9wdGlv
bmFsLiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIGN1cmF0aW9uLgoKDQoFBAYCAgUSBJoCAggK
DQoFBAYCAgESBJoCCRQKDQoFBAYCAgMSBJoCFxgKDQoFBAYCAggSBJoCGUEKEAoIBAYCAgic
CAASBJoCGkAKRAoEBAYCAxIEnQICQRo2IFJlcXVpcmVkLiBUaGUgZW5kcG9pbnQgdG8gYmUg
dHJpZ2dlcmVkIGZvciBjdXJhdGlvbi4KCg0KBQQGAgMGEgSdAgIKCg0KBQQGAgMBEgSdAgsT
Cg0KBQQGAgMDEgSdAhYXCg0KBQQGAgMIEgSdAhhAChAKCAQGAgMInAgAEgSdAhk/CtsBCgQE
BgIEEgaiAgKjAjIaygEgT3V0cHV0IG9ubHkuIFRoZSBwbHVnaW4gaW5zdGFuY2VzIGFuZCBh
c3NvY2lhdGVkIGFjdGlvbnMgdGhhdCBhcmUgdXNpbmcgdGhlCiBjdXJhdGlvbi4gTm90ZTog
QSBwYXJ0aWN1bGFyIGN1cmF0aW9uIGNvdWxkIGJlIHVzZWQgYnkgbXVsdGlwbGUgcGx1Z2lu
CiBpbnN0YW5jZXMgb3IgbXVsdGlwbGUgYWN0aW9ucyBpbiBhIHBsdWdpbiBpbnN0YW5jZS4K
Cg0KBQQGAgQEEgSiAgIKCg0KBQQGAgQGEgSiAgshCg0KBQQGAgQBEgSiAiI5Cg0KBQQGAgQD
EgSiAjw9Cg0KBQQGAgQIEgSjAgYxChAKCAQGAgQInAgAEgSjAgcwCkgKBAQGAgUSBqYCAqcC
Mho4IE91dHB1dCBvbmx5LiBUaGUgbGFzdCBleGVjdXRpb24gc3RhdGUgb2YgdGhlIGN1cmF0
aW9uLgoKDQoFBAYCBQYSBKYCAhQKDQoFBAYCBQESBKYCFSkKDQoFBAYCBQMSBKYCLC0KDQoF
BAYCBQgSBKcCBjEKEAoIBAYCBQicCAASBKcCBzAKoAEKBAQGAgYSBqsCAqwCMhqPASBPdXRw
dXQgb25seS4gVGhlIGVycm9yIGNvZGUgb2YgdGhlIGxhc3QgZXhlY3V0aW9uIG9mIHRoZSBj
dXJhdGlvbi4gVGhlCiBlcnJvciBjb2RlIGlzIHBvcHVsYXRlZCBvbmx5IHdoZW4gdGhlIGxh
c3QgZXhlY3V0aW9uIHN0YXRlIGlzIGZhaWxlZC4KCg0KBQQGAgYGEgSrAgILCg0KBQQGAgYB
EgSrAgwlCg0KBQQGAgYDEgSrAigpCg0KBQQGAgYIEgSsAgYxChAKCAQGAgYInAgAEgSsAgcw
CngKBAQGAgcSBrACArECMhpoIE91dHB1dCBvbmx5LiBFcnJvciBtZXNzYWdlIGRlc2NyaWJp
bmcgdGhlIGZhaWx1cmUsIGlmIGFueSwgZHVyaW5nIHRoZSBsYXN0CiBleGVjdXRpb24gb2Yg
dGhlIGN1cmF0aW9uLgoKDQoFBAYCBwUSBLACAggKDQoFBAYCBwESBLACCSUKDQoFBAYCBwMS
BLACKCkKDQoFBAYCBwgSBLECBjEKEAoIBAYCBwicCAASBLECBzAKSgoEBAYCCBIGtAICtQIy
GjogT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBjdXJhdGlvbiB3YXMgY3Jl
YXRlZC4KCg0KBQQGAggGEgS0AgIbCg0KBQQGAggBEgS0AhwnCg0KBQQGAggDEgS0AiorCg0K
BQQGAggIEgS1AgYxChAKCAQGAggInAgAEgS1AgcwCk8KBAQGAgkSBrgCArkCMho/IE91dHB1
dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGUgY3VyYXRpb24gd2FzIGxhc3QgdXBkYXRl
ZC4KCg0KBQQGAgkGEgS4AgIbCg0KBQQGAgkBEgS4AhwnCg0KBQQGAgkDEgS4AiosCg0KBQQG
AgkIEgS5AgYxChAKCAQGAgkInAgAEgS5AgcwCqYCCgIEBxIGwQIAygIBGpcCIFRoZSBlbmRw
b2ludCB0byBiZSB0cmlnZ2VyZWQgZm9yIGN1cmF0aW9uLgogVGhlIGVuZHBvaW50IHdpbGwg
YmUgaW52b2tlZCB3aXRoIGEgcmVxdWVzdCBwYXlsb2FkIGNvbnRhaW5pbmcKIFtBcGlNZXRh
ZGF0YV1bZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5BcGlIdWIuQXBpTWV0YWRhdGFdLgogUmVz
cG9uc2Ugc2hvdWxkIGNvbnRhaW4gY3VyYXRlZCBkYXRhIGluIHRoZSBmb3JtIG9mCiBbQXBp
TWV0YWRhdGFdW2dvb2dsZS5jbG91ZC5hcGlodWIudjEuQXBpSHViLkFwaU1ldGFkYXRhXS4K
CgsKAwQHARIEwQIIEApLCgQEBwgAEgbDAgLJAgMaOyBUaGUgZGV0YWlscyBvZiB0aGUgZW5k
cG9pbnQgdG8gYmUgdHJpZ2dlcmVkIGZvciBjdXJhdGlvbi4KCg0KBQQHCAABEgTDAggYCm4K
BAQHAgASBsYCBMgCMRpeIFJlcXVpcmVkLiBUaGUgZGV0YWlscyBvZiB0aGUgQXBwbGljYXRp
b24gSW50ZWdyYXRpb24gZW5kcG9pbnQgdG8gYmUKIHRyaWdnZXJlZCBmb3IgY3VyYXRpb24u
CgoNCgUEBwIABhIExgIEKQoNCgUEBwIAARIExwIIMAoNCgUEBwIAAxIExwIzNAoNCgUEBwIA
CBIEyAIIMAoQCggEBwIACJwIABIEyAIJLwpiCgIECBIGzgIA2AIBGlQgVGhlIGRldGFpbHMg
b2YgdGhlIEFwcGxpY2F0aW9uIEludGVncmF0aW9uIGVuZHBvaW50IHRvIGJlIHRyaWdnZXJl
ZCBmb3IKIGN1cmF0aW9uLgoKCwoDBAgBEgTOAggtCscCCgQECAIAEgTUAgI6GrgCIFJlcXVp
cmVkLiBUaGUgZW5kcG9pbnQgVVJJIHNob3VsZCBiZSBhIHZhbGlkIFJFU1QgVVJJIGZvciB0
cmlnZ2VyaW5nIGFuCiBBcHBsaWNhdGlvbiBJbnRlZ3JhdGlvbi4gRm9ybWF0OgogYGh0dHBz
Oi8vaW50ZWdyYXRpb25zLmdvb2dsZWFwaXMuY29tL3YxL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovaW50ZWdyYXRpb25zLyp9OmV4ZWN1dGVgCiBvcgogYGh0dHBzOi8ve2xvY2F0
aW9ufS1pbnRlZ3JhdGlvbnMuZ29vZ2xlYXBpcy5jb20vdjEve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9pbnRlZ3JhdGlvbnMvKn06ZXhlY3V0ZWAKCg0KBQQIAgAFEgTUAgIICg0K
BQQIAgABEgTUAgkMCg0KBQQIAgADEgTUAg8QCg0KBQQIAgAIEgTUAhE5ChAKCAQIAgAInAgA
EgTUAhI4ClUKBAQIAgESBNcCAkEaRyBSZXF1aXJlZC4gVGhlIEFQSSB0cmlnZ2VyIElEIG9m
IHRoZSBBcHBsaWNhdGlvbiBJbnRlZ3JhdGlvbiB3b3JrZmxvdy4KCg0KBQQIAgEFEgTXAgII
Cg0KBQQIAgEBEgTXAgkTCg0KBQQIAgEDEgTXAhYXCg0KBQQIAgEIEgTXAhhAChAKCAQIAgEI
nAgAEgTXAhk/YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest ===
    # Fields for CreateCurationRequest
    # Field: parent Type: 9 ()
    # Field: curation_id Type: 9 ()
    # Field: curation Type: 11 (.google.cloud.apihub.v1.Curation)

# === Message: Google::Cloud::Apihub::V1::CurateService::GetCurationRequest ===
    # Fields for GetCurationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::CurateService::UpdateCurationRequest ===
    # Fields for UpdateCurationRequest
    # Field: curation Type: 11 (.google.cloud.apihub.v1.Curation)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Apihub::V1::CurateService::DeleteCurationRequest ===
    # Fields for DeleteCurationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::CurateService::ListCurationsRequest ===
    # Fields for ListCurationsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::CurateService::ListCurationsResponse ===
    # Fields for ListCurationsResponse
    # Field: curations Type: 11 (.google.cloud.apihub.v1.Curation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::CurateService::Curation ===
    # Fields for Curation
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: endpoint Type: 11 (.google.cloud.apihub.v1.Endpoint)
    # Field: plugin_instance_actions Type: 11 (.google.cloud.apihub.v1.Curation.PluginInstanceActionID)
    # Field: last_execution_state Type: 14 (.google.cloud.apihub.v1.Curation.LastExecutionState)
    # Field: last_execution_error_code Type: 14 (.google.cloud.apihub.v1.Curation.ErrorCode)
    # Field: last_execution_error_message Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Curation::LastExecutionState
our $Curation_LAST_EXECUTION_STATE_UNSPECIFIED = 0;
our $Curation_SUCCEEDED = 1;
our $Curation_FAILED = 2;

# Enum: Curation::ErrorCode
our $Curation_ERROR_CODE_UNSPECIFIED = 0;
our $Curation_INTERNAL_ERROR = 1;
our $Curation_UNAUTHORIZED = 2;

# === Message: Google::Cloud::Apihub::V1::CurateService::Endpoint ===
    # Fields for Endpoint
    # Field: application_integration_endpoint_details Type: 11 (.google.cloud.apihub.v1.ApplicationIntegrationEndpointDetails)

# === Message: Google::Cloud::Apihub::V1::CurateService::ApplicationIntegrationEndpointDetails ===
    # Fields for ApplicationIntegrationEndpointDetails
    # Field: uri Type: 9 ()
    # Field: trigger_id Type: 9 ()

# === Service Client: Google::Cloud::Apihub::V1::CurateService::ApiHubCurateClient ===
package Google::Cloud::Apihub::V1::CurateService::ApiHubCurateClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::CurateService::ApiHubCurateClient

Client stub representing the remote C<ApiHubCurate> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apihub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apihub.googleapis.com:443' );

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

sub create_curation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubCurate',
        method         => 'CreateCuration',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CurateService::Curation',
    });
}

sub get_curation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::CurateService::GetCurationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubCurate',
        method         => 'GetCuration',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CurateService::Curation',
    });
}

sub list_curations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::CurateService::ListCurationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubCurate',
        method         => 'ListCurations',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CurateService::ListCurationsResponse',
    });
}

sub update_curation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::CurateService::UpdateCurationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubCurate',
        method         => 'UpdateCuration',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CurateService::Curation',
    });
}

sub delete_curation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::CurateService::DeleteCurationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubCurate',
        method         => 'DeleteCuration',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::CurateService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/curate_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::CurateService;

    my $msg = Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest->new({
        parent => $parent,
        curation_id => $curation_id,
        curation => $curation,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/curate_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest

The [CreateCuration][ApiHub.CreateCuration] method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource for the curation resource.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->curation_id() >> / C<< $msg->curation_id($value) >>

Type: C<String>

Optional. The ID to use for the curation resource, which will become the
final component of the curations's resource name. This field is optional.

* If provided, the same will be used. The service will throw an error if
the specified ID is already used by another curation resource in the API
hub.
* If not provided, a system generated ID will be used.

This value should be 4-500 characters, and valid characters
are /[a-z][A-Z][0-9]-_/.

=item * C<< $msg->curation() >> / C<< $msg->curation($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CurateService::Curation>)

Required. The curation resource to create.

=back

=head2 Google::Cloud::Apihub::V1::CurateService::GetCurationRequest

The [GetCuration][ApiHub.GetCuration] method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the curation resource to retrieve.
Format: `projects/{project}/locations/{location}/curations/{curation}`

=back

=head2 Google::Cloud::Apihub::V1::CurateService::UpdateCurationRequest

The [UpdateCuration][ApiHub.UpdateCuration] method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->curation() >> / C<< $msg->curation($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CurateService::Curation>)

Required. The curation resource to update.

The curation resource's `name` field is used to identify the curation
resource to update.
Format: `projects/{project}/locations/{location}/curations/{curation}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Apihub::V1::CurateService::DeleteCurationRequest

The [DeleteCuration][ApiHub.DeleteCuration] method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the curation resource to delete.
Format: `projects/{project}/locations/{location}/curations/{curation}`

=back

=head2 Google::Cloud::Apihub::V1::CurateService::ListCurationsRequest

The [ListCurations][ApiHub.ListCurations] method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of curation resources.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression that filters the list of curation resources.

A filter expression consists of a field name, a comparison
operator, and a value for filtering. The value must be a string. The
comparison operator must be one of: `<`, `>`, `:` or `=`. Filters are case
insensitive.

The following fields in the `curation resource` are eligible for filtering:

  * `create_time` - The time at which the curation was created.
  The value should be in the (RFC3339)[https://tools.ietf.org/html/rfc3339]
  format. Allowed comparison operators: `>` and `<`.
  * `display_name` - The display name of the curation. Allowed
  comparison operators: `=`.
  * `state` - The state of the curation. Allowed comparison operators: `=`.

Expressions are combined with either `AND` logic operator or `OR` logical
operator but not both of them together i.e. only one of the `AND` or `OR`
operator can be used throughout the filter string and both the operators
cannot be used together. No other logical operators are supported. At most
three filter fields are allowed in the filter string and if provided
more than that then `INVALID_ARGUMENT` error is returned by the API.

Here are a few examples:

  * `create_time < \"2021-08-15T14:50:00Z\" AND create_time >
  \"2021-08-10T12:00:00Z\"` -
  The curation resource was created before _2021-08-15 14:50:00 UTC_ and
  after _2021-08-10 12:00:00 UTC_.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of curation resources to return. The service
may return fewer than this value. If unspecified, at most 50 curations will
be returned. The maximum value is 1000; values above 1000 will be coerced
to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListCurations` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters (except page_size) provided to
`ListCurations` must match the call that provided the page token.

=back

=head2 Google::Cloud::Apihub::V1::CurateService::ListCurationsResponse

The [ListCurations][ApiHub.ListCurations] method's response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->curations() >> / C<< $msg->curations($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CurateService::Curation>)

The curation resources present in the API hub.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Apihub::V1::CurateService::Curation

A curation resource in the API Hub.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the curation.

Format:
`projects/{project}/locations/{location}/curations/{curation}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the curation.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the curation.

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CurateService::Endpoint>)

Required. The endpoint to be triggered for curation.

=item * C<< $msg->plugin_instance_actions() >> / C<< $msg->plugin_instance_actions($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CurateService::Curation::PluginInstanceActionID>)

Output only. The plugin instances and associated actions that are using the
curation. Note: A particular curation could be used by multiple plugin
instances or multiple actions in a plugin instance.

=item * C<< $msg->last_execution_state() >> / C<< $msg->last_execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Apihub::V1::Curation::LastExecutionState>)

Output only. The last execution state of the curation.

=item * C<< $msg->last_execution_error_code() >> / C<< $msg->last_execution_error_code($value) >>

Type: C<Enum> (L<Google::Cloud::Apihub::V1::Curation::ErrorCode>)

Output only. The error code of the last execution of the curation. The
error code is populated only when the last execution state is failed.

=item * C<< $msg->last_execution_error_message() >> / C<< $msg->last_execution_error_message($value) >>

Type: C<String>

Output only. Error message describing the failure, if any, during the last
execution of the curation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the curation was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the curation was last updated.

=back

=head3 Enum: Curation::LastExecutionState

=over 4

=item * C<LAST_EXECUTION_STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<FAILED> => C<2>

=back

=head3 Enum: Curation::ErrorCode

=over 4

=item * C<ERROR_CODE_UNSPECIFIED> => C<0>

=item * C<INTERNAL_ERROR> => C<1>

=item * C<UNAUTHORIZED> => C<2>

=back

=head2 Google::Cloud::Apihub::V1::CurateService::Endpoint

The endpoint to be triggered for curation.
The endpoint will be invoked with a request payload containing
[ApiMetadata][google.cloud.apihub.v1.ApiHub.ApiMetadata].
Response should contain curated data in the form of
[ApiMetadata][google.cloud.apihub.v1.ApiHub.ApiMetadata].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->application_integration_endpoint_details() >> / C<< $msg->application_integration_endpoint_details($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CurateService::ApplicationIntegrationEndpointDetails>)

Required. The details of the Application Integration endpoint to be
triggered for curation.

=back

=head2 Google::Cloud::Apihub::V1::CurateService::ApplicationIntegrationEndpointDetails

The details of the Application Integration endpoint to be triggered for
curation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The endpoint URI should be a valid REST URI for triggering an
Application Integration. Format:
`https://integrations.googleapis.com/v1/{name=projects/*/locations/*/integrations/*}:execute`
or
`https://{location}-integrations.googleapis.com/v1/{name=projects/*/locations/*/integrations/*}:execute`

=item * C<< $msg->trigger_id() >> / C<< $msg->trigger_id($value) >>

Type: C<String>

Required. The API trigger ID of the Application Integration workflow.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::CurateService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
