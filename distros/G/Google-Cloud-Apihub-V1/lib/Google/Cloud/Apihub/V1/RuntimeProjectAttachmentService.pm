package Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService;

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
Cj9nb29nbGUvY2xvdWQvYXBpaHViL3YxL3J1bnRpbWVfcHJvamVjdF9hdHRhY2htZW50X3Nl
cnZpY2UucHJvdG8SFmdvb2dsZS5jbG91ZC5hcGlodWIudjEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJv
dG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8itAIK
JUNyZWF0ZVJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFJlcXVlc3QSTgoGcGFyZW50GAEgASgJ
QjbgQQL6QTASLmFwaWh1Yi5nb29nbGVhcGlzLmNvbS9SdW50aW1lUHJvamVjdEF0dGFjaG1l
bnRSBnBhcmVudBJGCh1ydW50aW1lX3Byb2plY3RfYXR0YWNobWVudF9pZBgCIAEoCUID4EEC
UhpydW50aW1lUHJvamVjdEF0dGFjaG1lbnRJZBJzChpydW50aW1lX3Byb2plY3RfYXR0YWNo
bWVudBgDIAEoCzIwLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuUnVudGltZVByb2plY3RBdHRh
Y2htZW50QgPgQQJSGHJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudCJwCiJHZXRSdW50aW1lUHJv
amVjdEF0dGFjaG1lbnRSZXF1ZXN0EkoKBG5hbWUYASABKAlCNuBBAvpBMAouYXBpaHViLmdv
b2dsZWFwaXMuY29tL1J1bnRpbWVQcm9qZWN0QXR0YWNobWVudFIEbmFtZSL5AQokTGlzdFJ1
bnRpbWVQcm9qZWN0QXR0YWNobWVudHNSZXF1ZXN0Ek4KBnBhcmVudBgBIAEoCUI24EEC+kEw
Ei5hcGlodWIuZ29vZ2xlYXBpcy5jb20vUnVudGltZVByb2plY3RBdHRhY2htZW50UgZwYXJl
bnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyAB
KAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3Jk
ZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLBAQolTGlzdFJ1bnRpbWVQcm9qZWN0QXR0YWNo
bWVudHNSZXNwb25zZRJwChtydW50aW1lX3Byb2plY3RfYXR0YWNobWVudHMYASADKAsyMC5n
b29nbGUuY2xvdWQuYXBpaHViLnYxLlJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFIZcnVudGlt
ZVByb2plY3RBdHRhY2htZW50cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4icwolRGVsZXRlUnVudGltZVByb2plY3RBdHRhY2htZW50UmVxdWVzdBJKCgRuYW1l
GAEgASgJQjbgQQL6QTAKLmFwaWh1Yi5nb29nbGVhcGlzLmNvbS9SdW50aW1lUHJvamVjdEF0
dGFjaG1lbnRSBG5hbWUiZgolTG9va3VwUnVudGltZVByb2plY3RBdHRhY2htZW50UmVxdWVz
dBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2Nh
dGlvblIEbmFtZSKYAQomTG9va3VwUnVudGltZVByb2plY3RBdHRhY2htZW50UmVzcG9uc2US
bgoacnVudGltZV9wcm9qZWN0X2F0dGFjaG1lbnQYASABKAsyMC5nb29nbGUuY2xvdWQuYXBp
aHViLnYxLlJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFIYcnVudGltZVByb2plY3RBdHRhY2ht
ZW50IqIDChhSdW50aW1lUHJvamVjdEF0dGFjaG1lbnQSFwoEbmFtZRgBIAEoCUID4EEIUgRu
YW1lEl8KD3J1bnRpbWVfcHJvamVjdBgCIAEoCUI24EEC4EEF+kEtCitjbG91ZHJlc291cmNl
bWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0Ug5ydW50aW1lUHJvamVjdBJACgtjcmVh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZTrJAepBxQEKLmFwaWh1Yi5nb29nbGVhcGlzLmNvbS9SdW50aW1lUHJvamVjdEF0dGFj
aG1lbnQSXnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ydW50aW1l
UHJvamVjdEF0dGFjaG1lbnRzL3tydW50aW1lX3Byb2plY3RfYXR0YWNobWVudH0qGXJ1bnRp
bWVQcm9qZWN0QXR0YWNobWVudHMyGHJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudDKsCgofUnVu
dGltZVByb2plY3RBdHRhY2htZW50U2VydmljZRK3AgoeQ3JlYXRlUnVudGltZVByb2plY3RB
dHRhY2htZW50Ej0uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5DcmVhdGVSdW50aW1lUHJvamVj
dEF0dGFjaG1lbnRSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5SdW50aW1lUHJv
amVjdEF0dGFjaG1lbnQiowGC0+STAlsiPS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyp9L3J1bnRpbWVQcm9qZWN0QXR0YWNobWVudHM6GnJ1bnRpbWVfcHJvamVjdF9hdHRh
Y2htZW502kE/cGFyZW50LHJ1bnRpbWVfcHJvamVjdF9hdHRhY2htZW50LHJ1bnRpbWVfcHJv
amVjdF9hdHRhY2htZW50X2lkEtkBChtHZXRSdW50aW1lUHJvamVjdEF0dGFjaG1lbnQSOi5n
b29nbGUuY2xvdWQuYXBpaHViLnYxLkdldFJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFJlcXVl
c3QaMC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLlJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudCJM
gtPkkwI/Ej0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9ydW50aW1lUHJvamVj
dEF0dGFjaG1lbnRzLyp92kEEbmFtZRLsAQodTGlzdFJ1bnRpbWVQcm9qZWN0QXR0YWNobWVu
dHMSPC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkxpc3RSdW50aW1lUHJvamVjdEF0dGFjaG1l
bnRzUmVxdWVzdBo9Lmdvb2dsZS5jbG91ZC5hcGlodWIudjEuTGlzdFJ1bnRpbWVQcm9qZWN0
QXR0YWNobWVudHNSZXNwb25zZSJOgtPkkwI/Ej0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qfS9ydW50aW1lUHJvamVjdEF0dGFjaG1lbnRz2kEGcGFyZW50EsUBCh5EZWxl
dGVSdW50aW1lUHJvamVjdEF0dGFjaG1lbnQSPS5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkRl
bGV0ZVJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHkiTILT5JMCPyo9L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcnVudGlt
ZVByb2plY3RBdHRhY2htZW50cy8qfdpBBG5hbWUS8AEKHkxvb2t1cFJ1bnRpbWVQcm9qZWN0
QXR0YWNobWVudBI9Lmdvb2dsZS5jbG91ZC5hcGlodWIudjEuTG9va3VwUnVudGltZVByb2pl
Y3RBdHRhY2htZW50UmVxdWVzdBo+Lmdvb2dsZS5jbG91ZC5hcGlodWIudjEuTG9va3VwUnVu
dGltZVByb2plY3RBdHRhY2htZW50UmVzcG9uc2UiT4LT5JMCQhJAL3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyp9Omxvb2t1cFJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudNpBBG5h
bWUaScpBFWFwaWh1Yi5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CxgEKGmNvbS5nb29nbGUuY2xvdWQuYXBpaHViLnYx
QiRSdW50aW1lUHJvamVjdEF0dGFjaG1lbnRTZXJ2aWNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xl
LmNvbS9nby9hcGlodWIvYXBpdjEvYXBpaHVicGI7YXBpaHVicGKqAhZHb29nbGUuQ2xvdWQu
QXBpSHViLlYxygIWR29vZ2xlXENsb3VkXEFwaUh1YlxWMeoCGUdvb2dsZTo6Q2xvdWQ6OkFw
aUh1Yjo6VjFK2z8KBxIFDgCEAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgAlCgkKAgMFEgMXACkKCAoBCBIDGQAzCgkKAgglEgMZADMKCAoBCBIDGgBJ
CgkKAggLEgMaAEkKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHABFCgkKAggIEgMcAEUK
CAoBCBIDHQAzCgkKAggBEgMdADMKCAoBCBIDHgAzCgkKAggpEgMeADMKCAoBCBIDHwAyCgkK
AggtEgMfADIKUAoCBgASBCIAVwEaRCBUaGlzIHNlcnZpY2UgaXMgdXNlZCBmb3IgbWFuYWdp
bmcgdGhlIHJ1bnRpbWUgcHJvamVjdCBhdHRhY2htZW50cy4KCgoKAwYAARIDIggnCgoKAwYA
AxIDIwI9CgwKBQYAA5kIEgMjAj0KCwoDBgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3Cj8KBAYA
AgASBCgCMAMaMSBBdHRhY2hlcyBhIHJ1bnRpbWUgcHJvamVjdCB0byB0aGUgaG9zdCBwcm9q
ZWN0LgoKDAoFBgACAAESAygGJAoMCgUGAAIAAhIDKCVKCgwKBQYAAgADEgMpDycKDQoFBgAC
AAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0GCg0KBQYAAgAEEgQuBC9KChAKCAYAAgAEmwgA
EgQuBC9KCjIKBAYAAgESBDMCOQMaJCBHZXRzIGEgcnVudGltZSBwcm9qZWN0IGF0dGFjaG1l
bnQuCgoMCgUGAAIBARIDMwYhCgwKBQYAAgECEgMzIkQKDAoFBgACAQMSAzQPJwoNCgUGAAIB
BBIENQQ3BgoRCgkGAAIBBLDKvCISBDUENwYKDAoFBgACAQQSAzgEMgoPCggGAAIBBJsIABID
OAQyCkMKBAYAAgISBDwCQgMaNSBMaXN0IHJ1bnRpbWUgcHJvamVjdHMgYXR0YWNoZWQgdG8g
dGhlIGhvc3QgcHJvamVjdC4KCgwKBQYAAgIBEgM8BiMKDAoFBgACAgISAzwkSAoMCgUGAAIC
AxIDPQ80Cg0KBQYAAgIEEgQ+BEAGChEKCQYAAgIEsMq8IhIEPgRABgoMCgUGAAICBBIDQQQ0
Cg8KCAYAAgIEmwgAEgNBBDQKhQEKBAYAAgMSBEYCTAMadyBEZWxldGUgYSBydW50aW1lIHBy
b2plY3QgYXR0YWNobWVudCBpbiB0aGUgQVBJIEh1Yi4gVGhpcyBjYWxsIHdpbGwgZGV0YWNo
CiB0aGUgcnVudGltZSBwcm9qZWN0IGZyb20gdGhlIGhvc3QgcHJvamVjdC4KCgwKBQYAAgMB
EgNGBiQKDAoFBgACAwISA0YlSgoMCgUGAAIDAxIDRw8kCg0KBQYAAgMEEgRIBEoGChEKCQYA
AgMEsMq8IhIESARKBgoMCgUGAAIDBBIDSwQyCg8KCAYAAgMEmwgAEgNLBDIKbAoEBgACBBIE
UAJWAxpeIExvb2sgdXAgYSBydW50aW1lIHByb2plY3QgYXR0YWNobWVudC4gVGhpcyBBUEkg
Y2FuIGJlIGNhbGxlZCBpbiB0aGUgY29udGV4dAogb2YgYW55IHByb2plY3QuCgoMCgUGAAIE
ARIDUAYkCgwKBQYAAgQCEgNQJUoKDAoFBgACBAMSA1EPNQoNCgUGAAIEBBIEUgRUBgoRCgkG
AAIEBLDKvCISBFIEVAYKDAoFBgACBAQSA1UEMgoPCggGAAIEBJsIABIDVQQyCp4BCgIEABIE
XABwARqRASBUaGUKIFtDcmVhdGVSdW50aW1lUHJvamVjdEF0dGFjaG1lbnRdW2dvb2dsZS5j
bG91ZC5hcGlodWIudjEuUnVudGltZVByb2plY3RBdHRhY2htZW50U2VydmljZS5DcmVhdGVS
dW50aW1lUHJvamVjdEF0dGFjaG1lbnRdCiBtZXRob2QncyByZXF1ZXN0LgoKCgoDBAABEgNc
CC0KhAEKBAQAAgASBF8CZAQadiBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBmb3Ig
dGhlIFJ1bnRpbWUgUHJvamVjdCBBdHRhY2htZW50LgogRm9ybWF0OiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDAoFBAACAAUSA18CCAoMCgUEAAIAARID
XwkPCgwKBQQAAgADEgNfEhMKDQoFBAACAAgSBF8UZAMKDwoIBAACAAicCAASA2AEKgoPCgcE
AAIACJ8IEgRhBGMFCqgCCgQEAAIBEgRqAmsvGpkCIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNl
IGZvciB0aGUgUnVudGltZSBQcm9qZWN0IEF0dGFjaG1lbnQsIHdoaWNoIHdpbGwKIGJlY29t
ZSB0aGUgZmluYWwgY29tcG9uZW50IG9mIHRoZSBSdW50aW1lIFByb2plY3QgQXR0YWNobWVu
dCdzIG5hbWUuIFRoZSBJRAogbXVzdCBiZSB0aGUgc2FtZSBhcyB0aGUgcHJvamVjdCBJRCBv
ZiB0aGUgR29vZ2xlIGNsb3VkIHByb2plY3Qgc3BlY2lmaWVkIGluCiB0aGUgcnVudGltZV9w
cm9qZWN0X2F0dGFjaG1lbnQucnVudGltZV9wcm9qZWN0IGZpZWxkLgoKDAoFBAACAQUSA2oC
CAoMCgUEAAIBARIDagkmCgwKBQQAAgEDEgNqKSoKDAoFBAACAQgSA2sGLgoPCggEAAIBCJwI
ABIDawctCkMKBAQAAgISBG4Cby8aNSBSZXF1aXJlZC4gVGhlIFJ1bnRpbWUgUHJvamVjdCBB
dHRhY2htZW50IHRvIGNyZWF0ZS4KCgwKBQQAAgIGEgNuAhoKDAoFBAACAgESA24bNQoMCgUE
AAICAxIDbjg5CgwKBQQAAgIIEgNvBi4KDwoIBAACAgicCAASA28HLQqYAQoCBAESBHUAfwEa
iwEgVGhlCiBbR2V0UnVudGltZVByb2plY3RBdHRhY2htZW50XVtnb29nbGUuY2xvdWQuYXBp
aHViLnYxLlJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFNlcnZpY2UuR2V0UnVudGltZVByb2pl
Y3RBdHRhY2htZW50XQogbWV0aG9kJ3MgcmVxdWVzdC4KCgoKAwQBARIDdQgqCq8BCgQEAQIA
EgR5An4EGqABIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgQVBJIHJlc291cmNlIHRvIHJl
dHJpZXZlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9ydW50aW1lUHJvamVjdEF0dGFjaG1lbnRzL3tydW50aW1lX3Byb2plY3RfYXR0YWNo
bWVudH1gCgoMCgUEAQIABRIDeQIICgwKBQQBAgABEgN5CQ0KDAoFBAECAAMSA3kQEQoNCgUE
AQIACBIEeRJ+AwoPCggEAQIACJwIABIDegQqCg8KBwQBAgAInwgSBHsEfQUKngEKAgQCEgaE
AQCxAQEajwEgVGhlCiBbTGlzdFJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudHNdW2dvb2dsZS5j
bG91ZC5hcGlodWIudjEuUnVudGltZVByb2plY3RBdHRhY2htZW50U2VydmljZS5MaXN0UnVu
dGltZVByb2plY3RBdHRhY2htZW50c10KIG1ldGhvZCdzIHJlcXVlc3QuCgoLCgMEAgESBIQB
CCwKlgEKBAQCAgASBocBAowBBBqFASBSZXF1aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3du
cyB0aGlzIGNvbGxlY3Rpb24gb2YgcnVudGltZSBwcm9qZWN0CiBhdHRhY2htZW50cy4gRm9y
bWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAIC
AAUSBIcBAggKDQoFBAICAAESBIcBCQ8KDQoFBAICAAMSBIcBEhMKDwoFBAICAAgSBocBFIwB
AwoQCggEAgIACJwIABIEiAEEKgoRCgcEAgIACJ8IEgaJAQSLAQUKlwIKBAQCAgESBJIBAj8a
iAIgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBydW50aW1lIHByb2plY3QgYXR0
YWNobWVudHMgdG8gcmV0dXJuLiBUaGUKIHNlcnZpY2UgbWF5IHJldHVybiBmZXdlciB0aGFu
IHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwCiBydW50aW1lIHByb2pl
Y3QgYXR0YWNobWVudHMgd2lsbCBiZSByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMg
MTAwMDsKIHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoF
BAICAQUSBJIBAgcKDQoFBAICAQESBJIBCBEKDQoFBAICAQMSBJIBFBUKDQoFBAICAQgSBJIB
Fj4KEAoIBAICAQicCAASBJIBFz0KsgIKBAQCAgISBJsBAkEaowIgT3B0aW9uYWwuIEEgcGFn
ZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdFJ1bnRpbWVQcm9qZWN0
QXR0YWNobWVudHNgIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNl
cXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIChl
eGNlcHQgcGFnZV9zaXplKSBwcm92aWRlZCB0bwogYExpc3RSdW50aW1lUHJvamVjdEF0dGFj
aG1lbnRzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UKIHRv
a2VuLgoKDQoFBAICAgUSBJsBAggKDQoFBAICAgESBJsBCRMKDQoFBAICAgMSBJsBFhcKDQoF
BAICAggSBJsBGEAKEAoIBAICAgicCAASBJsBGT8KygUKBAQCAgMSBK0BAj0auwUgT3B0aW9u
YWwuIEFuIGV4cHJlc3Npb24gdGhhdCBmaWx0ZXJzIHRoZSBsaXN0IG9mIFJ1bnRpbWVQcm9q
ZWN0QXR0YWNobWVudHMuCgogQSBmaWx0ZXIgZXhwcmVzc2lvbiBjb25zaXN0cyBvZiBhIGZp
ZWxkIG5hbWUsIGEgY29tcGFyaXNvbgogb3BlcmF0b3IsIGFuZCBhIHZhbHVlIGZvciBmaWx0
ZXJpbmcuIFRoZSB2YWx1ZSBtdXN0IGJlIGEgc3RyaW5nLiBBbGwKIHN0YW5kYXJkIG9wZXJh
dG9ycyBhcyBkb2N1bWVudGVkIGF0IGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTYwIGFyZQog
c3VwcG9ydGVkLgoKIFRoZSBmb2xsb3dpbmcgZmllbGRzIGluIHRoZSBgUnVudGltZVByb2pl
Y3RBdHRhY2htZW50YCBhcmUgZWxpZ2libGUgZm9yCiBmaWx0ZXJpbmc6CgogICAqIGBuYW1l
YCAtIFRoZSBuYW1lIG9mIHRoZSBSdW50aW1lUHJvamVjdEF0dGFjaG1lbnQuCiAgICogYGNy
ZWF0ZV90aW1lYCAtIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBSdW50aW1lUHJvamVjdEF0dGFj
aG1lbnQgd2FzCiAgIGNyZWF0ZWQuIFRoZSB2YWx1ZSBzaG91bGQgYmUgaW4gdGhlCiAgIChS
RkMzMzM5KVtodHRwczovL3Rvb2xzLmlldGYub3JnL2h0bWwvcmZjMzMzOV0gZm9ybWF0Lgog
ICAqIGBydW50aW1lX3Byb2plY3RgIC0gVGhlIEdvb2dsZSBjbG91ZCBwcm9qZWN0IGFzc29j
aWF0ZWQgd2l0aCB0aGUKICAgUnVudGltZVByb2plY3RBdHRhY2htZW50LgoKDQoFBAICAwUS
BK0BAggKDQoFBAICAwESBK0BCQ8KDQoFBAICAwMSBK0BEhMKDQoFBAICAwgSBK0BFDwKEAoI
BAICAwicCAASBK0BFTsKPAoEBAICBBIEsAECPxouIE9wdGlvbmFsLiBIaW50IGZvciBob3cg
dG8gb3JkZXIgdGhlIHJlc3VsdHMuCgoNCgUEAgIEBRIEsAECCAoNCgUEAgIEARIEsAEJEQoN
CgUEAgIEAxIEsAEUFQoNCgUEAgIECBIEsAEWPgoQCggEAgIECJwIABIEsAEXPQqfAQoCBAMS
BrYBAL0BARqQASBUaGUKIFtMaXN0UnVudGltZVByb2plY3RBdHRhY2htZW50c11bZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MS5SdW50aW1lUHJvamVjdEF0dGFjaG1lbnRTZXJ2aWNlLkxpc3RS
dW50aW1lUHJvamVjdEF0dGFjaG1lbnRzXQogbWV0aG9kJ3MgcmVzcG9uc2UuCgoLCgMEAwES
BLYBCC0KNAoEBAMCABIEuAECRBomIExpc3Qgb2YgcnVudGltZSBwcm9qZWN0IGF0dGFjaG1l
bnRzLgoKDQoFBAMCAAQSBLgBAgoKDQoFBAMCAAYSBLgBCyMKDQoFBAMCAAESBLgBJD8KDQoF
BAMCAAMSBLgBQkMKkAEKBAQDAgESBLwBAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNl
bnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlz
IGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoF
BAMCAQUSBLwBAggKDQoFBAMCAQESBLwBCRgKDQoFBAMCAQMSBLwBGxwKoAEKAgQEEgbCAQDM
AQEakQEgVGhlCiBbRGVsZXRlUnVudGltZVByb2plY3RBdHRhY2htZW50XVtnb29nbGUuY2xv
dWQuYXBpaHViLnYxLlJ1bnRpbWVQcm9qZWN0QXR0YWNobWVudFNlcnZpY2UuRGVsZXRlUnVu
dGltZVByb2plY3RBdHRhY2htZW50XQogbWV0aG9kJ3MgcmVxdWVzdC4KCgsKAwQEARIEwgEI
LQq9AQoEBAQCABIGxgECywEEGqwBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgUnVudGlt
ZSBQcm9qZWN0IEF0dGFjaG1lbnQgdG8gZGVsZXRlLgogRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ydW50aW1lUHJvamVjdEF0dGFjaG1lbnRz
L3tydW50aW1lX3Byb2plY3RfYXR0YWNobWVudH1gCgoNCgUEBAIABRIExgECCAoNCgUEBAIA
ARIExgEJDQoNCgUEBAIAAxIExgEQEQoPCgUEBAIACBIGxgESywEDChAKCAQEAgAInAgAEgTH
AQQqChEKBwQEAgAInwgSBsgBBMoBBQqgAQoCBAUSBtEBANsBARqRASBUaGUKIFtMb29rdXBS
dW50aW1lUHJvamVjdEF0dGFjaG1lbnRdW2dvb2dsZS5jbG91ZC5hcGlodWIudjEuUnVudGlt
ZVByb2plY3RBdHRhY2htZW50U2VydmljZS5Mb29rdXBSdW50aW1lUHJvamVjdEF0dGFjaG1l
bnRdCiBtZXRob2QncyByZXF1ZXN0LgoKCwoDBAUBEgTRAQgtCrsBCgQEBQIAEgbVAQLaAQQa
qgEgUmVxdWlyZWQuIFJ1bnRpbWUgcHJvamVjdCBJRCB0byBsb29rIHVwIHJ1bnRpbWUgcHJv
amVjdCBhdHRhY2htZW50IGZvci4KIExvb2t1cCBoYXBwZW5zIGFjcm9zcyBhbGwgcmVnaW9u
cy4gRXhwZWN0ZWQgZm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufWAuCgoNCgUEBQIABRIE1QECCAoNCgUEBQIAARIE1QEJDQoNCgUEBQIAAxIE1QEQ
EQoPCgUEBQIACBIG1QES2gEDChAKCAQFAgAInAgAEgTWAQQqChEKBwQFAgAInwgSBtcBBNkB
BQqfAQoCBAYSBuABAOMBARqQASBUaGUKIFtMaXN0UnVudGltZVByb2plY3RBdHRhY2htZW50
c11bZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5SdW50aW1lUHJvamVjdEF0dGFjaG1lbnRTZXJ2
aWNlLkxpc3RSdW50aW1lUHJvamVjdEF0dGFjaG1lbnRzXQogbWV0aG9kJ3MgcmVzcG9uc2Uu
CgoLCgMEBgESBOABCC4KVAoEBAYCABIE4gECOhpGIFJ1bnRpbWUgcHJvamVjdCBhdHRhY2ht
ZW50IGZvciBhIHByb2plY3QgaWYgZXhpc3RzLCBlbXB0eSBvdGhlcndpc2UuCgoNCgUEBgIA
BhIE4gECGgoNCgUEBgIAARIE4gEbNQoNCgUEBgIAAxIE4gE4OQqDAgoCBAcSBukBAIQCARr0
ASBSdW50aW1lIHByb2plY3QgYXR0YWNobWVudCByZXByZXNlbnRzIGFuIGF0dGFjaG1lbnQg
ZnJvbSB0aGUgcnVudGltZSBwcm9qZWN0CiB0byB0aGUgaG9zdCBwcm9qZWN0LiBBcGkgSHVi
IGxvb2tzIGZvciBkZXBsb3ltZW50cyBpbiB0aGUgYXR0YWNoZWQgcnVudGltZQogcHJvamVj
dHMgYW5kIGNyZWF0ZXMgY29ycmVzcG9uZGluZyByZXNvdXJjZXMgaW4gQXBpIEh1YiBmb3Ig
dGhlIGRpc2NvdmVyZWQKIGRlcGxveW1lbnRzLgoKCwoDBAcBEgTpAQggCg0KAwQHBxIG6gEC
7wEECg8KBQQHB50IEgbqAQLvAQQKugEKBAQHAgASBPMBAj0aqwEgSWRlbnRpZmllci4gVGhl
IHJlc291cmNlIG5hbWUgb2YgYSBydW50aW1lIHByb2plY3QgYXR0YWNobWVudC4gRm9ybWF0
OgogInByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ydW50aW1lUHJv
amVjdEF0dGFjaG1lbnRzL3tydW50aW1lX3Byb2plY3RfYXR0YWNobWVudH0iLgoKDQoFBAcC
AAUSBPMBAggKDQoFBAcCAAESBPMBCQ0KDQoFBAcCAAMSBPMBEBEKDQoFBAcCAAgSBPMBEjwK
EAoIBAcCAAicCAASBPMBEzsK7gEKBAQHAgESBvkBAv8BBBrdASBSZXF1aXJlZC4gSW1tdXRh
YmxlLiBHb29nbGUgY2xvdWQgcHJvamVjdCBuYW1lIGluIHRoZSBmb3JtYXQ6CiAicHJvamVj
dHMvYWJjIiBvciAicHJvamVjdHMvMTIzIi4gQXMgaW5wdXQsIHByb2plY3QgbmFtZSB3aXRo
IGVpdGhlcgogcHJvamVjdCBpZCBvciBudW1iZXIgYXJlIGFjY2VwdGVkLiBBcyBvdXRwdXQs
IHRoaXMgZmllbGQgd2lsbCBjb250YWluCiBwcm9qZWN0IG51bWJlci4KCg0KBQQHAgEFEgT5
AQIICg0KBQQHAgEBEgT5AQkYCg0KBQQHAgEDEgT5ARscCg8KBQQHAgEIEgb5AR3/AQMKEAoI
BAcCAQicCAASBPoBBCoKEAoIBAcCAQicCAESBPsBBCsKEQoHBAcCAQifCBIG/AEE/gEFCisK
BAQHAgISBoICAoMCMhobIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZS4KCg0KBQQHAgIGEgSC
AgIbCg0KBQQHAgIBEgSCAhwnCg0KBQQHAgIDEgSCAiorCg0KBQQHAgIIEgSDAgYxChAKCAQH
AgIInAgAEgSDAgcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest ===
    # Fields for CreateRuntimeProjectAttachmentRequest
    # Field: parent Type: 9 ()
    # Field: runtime_project_attachment_id Type: 9 ()
    # Field: runtime_project_attachment Type: 11 (.google.cloud.apihub.v1.RuntimeProjectAttachment)

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::GetRuntimeProjectAttachmentRequest ===
    # Fields for GetRuntimeProjectAttachmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsRequest ===
    # Fields for ListRuntimeProjectAttachmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsResponse ===
    # Fields for ListRuntimeProjectAttachmentsResponse
    # Field: runtime_project_attachments Type: 11 (.google.cloud.apihub.v1.RuntimeProjectAttachment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::DeleteRuntimeProjectAttachmentRequest ===
    # Fields for DeleteRuntimeProjectAttachmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentRequest ===
    # Fields for LookupRuntimeProjectAttachmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentResponse ===
    # Fields for LookupRuntimeProjectAttachmentResponse
    # Field: runtime_project_attachment Type: 11 (.google.cloud.apihub.v1.RuntimeProjectAttachment)

# === Message: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment ===
    # Fields for RuntimeProjectAttachment
    # Field: name Type: 9 ()
    # Field: runtime_project Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachmentServiceClient ===
package Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachmentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachmentServiceClient

Client stub representing the remote C<RuntimeProjectAttachmentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_runtime_project_attachment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.RuntimeProjectAttachmentService',
        method         => 'CreateRuntimeProjectAttachment',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment',
    });
}

sub get_runtime_project_attachment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::GetRuntimeProjectAttachmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.RuntimeProjectAttachmentService',
        method         => 'GetRuntimeProjectAttachment',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment',
    });
}

sub list_runtime_project_attachments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.RuntimeProjectAttachmentService',
        method         => 'ListRuntimeProjectAttachments',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsResponse',
    });
}

sub delete_runtime_project_attachment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::DeleteRuntimeProjectAttachmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.RuntimeProjectAttachmentService',
        method         => 'DeleteRuntimeProjectAttachment',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub lookup_runtime_project_attachment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.RuntimeProjectAttachmentService',
        method         => 'LookupRuntimeProjectAttachment',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/runtime_project_attachment_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService;

    my $msg = Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest->new({
        parent => $parent,
        runtime_project_attachment_id => $runtime_project_attachment_id,
        runtime_project_attachment => $runtime_project_attachment,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/runtime_project_attachment_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest

The
[CreateRuntimeProjectAttachment][google.cloud.apihub.v1.RuntimeProjectAttachmentService.CreateRuntimeProjectAttachment]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource for the Runtime Project Attachment.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->runtime_project_attachment_id() >> / C<< $msg->runtime_project_attachment_id($value) >>

Type: C<String>

Required. The ID to use for the Runtime Project Attachment, which will
become the final component of the Runtime Project Attachment's name. The ID
must be the same as the project ID of the Google cloud project specified in
the runtime_project_attachment.runtime_project field.

=item * C<< $msg->runtime_project_attachment() >> / C<< $msg->runtime_project_attachment($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment>)

Required. The Runtime Project Attachment to create.

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::GetRuntimeProjectAttachmentRequest

The
[GetRuntimeProjectAttachment][google.cloud.apihub.v1.RuntimeProjectAttachmentService.GetRuntimeProjectAttachment]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the API resource to retrieve.
Format:
`projects/{project}/locations/{location}/runtimeProjectAttachments/{runtime_project_attachment}`

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsRequest

The
[ListRuntimeProjectAttachments][google.cloud.apihub.v1.RuntimeProjectAttachmentService.ListRuntimeProjectAttachments]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of runtime project
attachments. Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of runtime project attachments to return. The
service may return fewer than this value. If unspecified, at most 50
runtime project attachments will be returned. The maximum value is 1000;
values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListRuntimeProjectAttachments` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters (except page_size) provided to
`ListRuntimeProjectAttachments` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression that filters the list of RuntimeProjectAttachments.

A filter expression consists of a field name, a comparison
operator, and a value for filtering. The value must be a string. All
standard operators as documented at https://google.aip.dev/160 are
supported.

The following fields in the `RuntimeProjectAttachment` are eligible for
filtering:

  * `name` - The name of the RuntimeProjectAttachment.
  * `create_time` - The time at which the RuntimeProjectAttachment was
  created. The value should be in the
  (RFC3339)[https://tools.ietf.org/html/rfc3339] format.
  * `runtime_project` - The Google cloud project associated with the
  RuntimeProjectAttachment.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsResponse

The
[ListRuntimeProjectAttachments][google.cloud.apihub.v1.RuntimeProjectAttachmentService.ListRuntimeProjectAttachments]
method's response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->runtime_project_attachments() >> / C<< $msg->runtime_project_attachments($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment>)

List of runtime project attachments.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::DeleteRuntimeProjectAttachmentRequest

The
[DeleteRuntimeProjectAttachment][google.cloud.apihub.v1.RuntimeProjectAttachmentService.DeleteRuntimeProjectAttachment]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Runtime Project Attachment to delete.
Format:
`projects/{project}/locations/{location}/runtimeProjectAttachments/{runtime_project_attachment}`

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentRequest

The
[LookupRuntimeProjectAttachment][google.cloud.apihub.v1.RuntimeProjectAttachmentService.LookupRuntimeProjectAttachment]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Runtime project ID to look up runtime project attachment for.
Lookup happens across all regions. Expected format:
`projects/{project}/locations/{location}`.

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentResponse

The
[ListRuntimeProjectAttachments][google.cloud.apihub.v1.RuntimeProjectAttachmentService.ListRuntimeProjectAttachments]
method's response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->runtime_project_attachment() >> / C<< $msg->runtime_project_attachment($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment>)

Runtime project attachment for a project if exists, empty otherwise.

=back

=head2 Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment

Runtime project attachment represents an attachment from the runtime project
to the host project. Api Hub looks for deployments in the attached runtime
projects and creates corresponding resources in Api Hub for the discovered
deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of a runtime project attachment. Format:
"projects/{project}/locations/{location}/runtimeProjectAttachments/{runtime_project_attachment}".

=item * C<< $msg->runtime_project() >> / C<< $msg->runtime_project($value) >>

Type: C<String>

Required. Immutable. Google cloud project name in the format:
"projects/abc" or "projects/123". As input, project name with either
project id or number are accepted. As output, this field will contain
project number.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
