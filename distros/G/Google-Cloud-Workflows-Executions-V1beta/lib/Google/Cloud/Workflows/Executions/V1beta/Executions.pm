package Google::Cloud::Workflows::Executions::V1beta::Executions;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvd29ya2Zsb3dzL2V4ZWN1dGlvbnMvdjFiZXRhL2V4ZWN1dGlvbnMu
cHJvdG8SKGdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJldGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItgFCglFeGVjdXRpb24SFwoEbmFt
ZRgBIAEoCUID4EEDUgRuYW1lEj4KCnN0YXJ0X3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRI6CghlbmRfdGltZRgDIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGltZRJUCgVzdGF0ZRgEIAEoDjI5Lmdv
b2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJldGEuRXhlY3V0aW9uLlN0YXRl
QgPgQQNSBXN0YXRlEhoKCGFyZ3VtZW50GAUgASgJUghhcmd1bWVudBIbCgZyZXN1bHQYBiAB
KAlCA+BBA1IGcmVzdWx0ElQKBWVycm9yGAcgASgLMjkuZ29vZ2xlLmNsb3VkLndvcmtmbG93
cy5leGVjdXRpb25zLnYxYmV0YS5FeGVjdXRpb24uRXJyb3JCA+BBA1IFZXJyb3ISNQoUd29y
a2Zsb3dfcmV2aXNpb25faWQYCCABKAlCA+BBA1ISd29ya2Zsb3dSZXZpc2lvbklkGjsKBUVy
cm9yEhgKB3BheWxvYWQYASABKAlSB3BheWxvYWQSGAoHY29udGV4dBgCIAEoCVIHY29udGV4
dCJUCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEg0KCVNVQ0NF
RURFRBACEgoKBkZBSUxFRBADEg0KCUNBTkNFTExFRBAEOoYB6kGCAQord29ya2Zsb3dleGVj
dXRpb25zLmdvb2dsZWFwaXMuY29tL0V4ZWN1dGlvbhJTcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L3dvcmtmbG93cy97d29ya2Zsb3d9L2V4ZWN1dGlvbnMve2V4
ZWN1dGlvbn0i6AEKFUxpc3RFeGVjdXRpb25zUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBB
AvpBIwohd29ya2Zsb3dzLmdvb2dsZWFwaXMuY29tL1dvcmtmbG93UgZwYXJlbnQSGwoJcGFn
ZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4S
UAoEdmlldxgEIAEoDjI3Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJl
dGEuRXhlY3V0aW9uVmlld0ID4EEBUgR2aWV3IpUBChZMaXN0RXhlY3V0aW9uc1Jlc3BvbnNl
ElMKCmV4ZWN1dGlvbnMYASADKAsyMy5nb29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlv
bnMudjFiZXRhLkV4ZWN1dGlvblIKZXhlY3V0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiAB
KAlSDW5leHRQYWdlVG9rZW4iswEKFkNyZWF0ZUV4ZWN1dGlvblJlcXVlc3QSQQoGcGFyZW50
GAEgASgJQingQQL6QSMKIXdvcmtmbG93cy5nb29nbGVhcGlzLmNvbS9Xb3JrZmxvd1IGcGFy
ZW50ElYKCWV4ZWN1dGlvbhgCIAEoCzIzLmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0
aW9ucy52MWJldGEuRXhlY3V0aW9uQgPgQQJSCWV4ZWN1dGlvbiKwAQoTR2V0RXhlY3V0aW9u
UmVxdWVzdBJHCgRuYW1lGAEgASgJQjPgQQL6QS0KK3dvcmtmbG93ZXhlY3V0aW9ucy5nb29n
bGVhcGlzLmNvbS9FeGVjdXRpb25SBG5hbWUSUAoEdmlldxgCIAEoDjI3Lmdvb2dsZS5jbG91
ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJldGEuRXhlY3V0aW9uVmlld0ID4EEBUgR2aWV3
ImEKFkNhbmNlbEV4ZWN1dGlvblJlcXVlc3QSRwoEbmFtZRgBIAEoCUIz4EEC+kEtCit3b3Jr
Zmxvd2V4ZWN1dGlvbnMuZ29vZ2xlYXBpcy5jb20vRXhlY3V0aW9uUgRuYW1lKkQKDUV4ZWN1
dGlvblZpZXcSHgoaRVhFQ1VUSU9OX1ZJRVdfVU5TUEVDSUZJRUQQABIJCgVCQVNJQxABEggK
BEZVTEwQAjLzBwoKRXhlY3V0aW9ucxLkAQoOTGlzdEV4ZWN1dGlvbnMSPy5nb29nbGUuY2xv
dWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMudjFiZXRhLkxpc3RFeGVjdXRpb25zUmVxdWVzdBpA
Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJldGEuTGlzdEV4ZWN1dGlv
bnNSZXNwb25zZSJPgtPkkwJAEj4vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi93b3JrZmxvd3MvKn0vZXhlY3V0aW9uc9pBBnBhcmVudBLuAQoPQ3JlYXRlRXhlY3V0
aW9uEkAuZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxYmV0YS5DcmVhdGVF
eGVjdXRpb25SZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYx
YmV0YS5FeGVjdXRpb24iZILT5JMCSyI+L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyovd29ya2Zsb3dzLyp9L2V4ZWN1dGlvbnM6CWV4ZWN1dGlvbtpBEHBhcmVudCxl
eGVjdXRpb24S0QEKDEdldEV4ZWN1dGlvbhI9Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhl
Y3V0aW9ucy52MWJldGEuR2V0RXhlY3V0aW9uUmVxdWVzdBozLmdvb2dsZS5jbG91ZC53b3Jr
Zmxvd3MuZXhlY3V0aW9ucy52MWJldGEuRXhlY3V0aW9uIk2C0+STAkASPi92MWJldGEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi93b3JrZmxvd3MvKi9leGVjdXRpb25zLyp92kEE
bmFtZRLhAQoPQ2FuY2VsRXhlY3V0aW9uEkAuZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVj
dXRpb25zLnYxYmV0YS5DYW5jZWxFeGVjdXRpb25SZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLndv
cmtmbG93cy5leGVjdXRpb25zLnYxYmV0YS5FeGVjdXRpb24iV4LT5JMCSiJFL3YxYmV0YS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtmbG93cy8qL2V4ZWN1dGlvbnMvKn06
Y2FuY2VsOgEq2kEEbmFtZRpVykEhd29ya2Zsb3dleGVjdXRpb25zLmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULzAQos
Y29tLmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJldGFCD0V4ZWN1dGlv
bnNQcm90b1ABWkxjbG91ZC5nb29nbGUuY29tL2dvL3dvcmtmbG93cy9leGVjdXRpb25zL2Fw
aXYxYmV0YS9leGVjdXRpb25zcGI7ZXhlY3V0aW9uc3Bi6kFhCiF3b3JrZmxvd3MuZ29vZ2xl
YXBpcy5jb20vV29ya2Zsb3cSPHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS93b3JrZmxvd3Mve3dvcmtmbG93fUr7PgoHEgUOAPsBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACkKCAoBCBIDGABjCgkKAggLEgMYAGMKCAoB
CBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAwCgkKAggIEgMaADAKCAoBCBIDGwBFCgkKAggB
EgMbAEUKCQoBCBIEHAAfAgoMCgQInQgAEgQcAB8CCpIBCgIGABIEIwBLARqFASBFeGVjdXRp
b25zIGlzIHVzZWQgdG8gc3RhcnQgYW5kIG1hbmFnZSBydW5uaW5nIGluc3RhbmNlcyBvZgog
W1dvcmtmbG93c11bZ29vZ2xlLmNsb3VkLndvcmtmbG93cy52MWJldGEuV29ya2Zsb3ddIGNh
bGxlZCBleGVjdXRpb25zLgoKCgoDBgABEgMjCBIKCgoDBgADEgMkAkkKDAoFBgADmQgSAyQC
SQoKCgMGAAMSAyUCVgoMCgUGAAOaCBIDJQJWCt8BCgQGAAIAEgQrAjADGtABIFJldHVybnMg
YSBsaXN0IG9mIGV4ZWN1dGlvbnMgd2hpY2ggYmVsb25nIHRvIHRoZSB3b3JrZmxvdyB3aXRo
CiB0aGUgZ2l2ZW4gbmFtZS4gVGhlIG1ldGhvZCByZXR1cm5zIGV4ZWN1dGlvbnMgb2YgYWxs
IHdvcmtmbG93CiByZXZpc2lvbnMuIFJldHVybmVkIGV4ZWN1dGlvbnMgYXJlIG9yZGVyZWQg
YnkgdGhlaXIgc3RhcnQgdGltZSAobmV3ZXN0CiBmaXJzdCkuCgoMCgUGAAIAARIDKwYUCgwK
BQYAAgACEgMrFSoKDAoFBgACAAMSAys1SwoNCgUGAAIABBIELAQuBgoRCgkGAAIABLDKvCIS
BCwELgYKDAoFBgACAAQSAy8ENAoPCggGAAIABJsIABIDLwQ0ClgKBAYAAgESBDMCOQMaSiBD
cmVhdGVzIGEgbmV3IGV4ZWN1dGlvbiB1c2luZyB0aGUgbGF0ZXN0IHJldmlzaW9uIG9mIHRo
ZSBnaXZlbiB3b3JrZmxvdy4KCgwKBQYAAgEBEgMzBhUKDAoFBgACAQISAzMWLAoMCgUGAAIB
AxIDMzdACg0KBQYAAgEEEgQ0BDcGChEKCQYAAgEEsMq8IhIENAQ3BgoMCgUGAAIBBBIDOAQ+
Cg8KCAYAAgEEmwgAEgM4BD4KNwoEBgACAhIEPAJBAxopIFJldHVybnMgYW4gZXhlY3V0aW9u
IG9mIHRoZSBnaXZlbiBuYW1lLgoKDAoFBgACAgESAzwGEgoMCgUGAAICAhIDPBMmCgwKBQYA
AgIDEgM8MToKDQoFBgACAgQSBD0EPwYKEQoJBgACAgSwyrwiEgQ9BD8GCgwKBQYAAgIEEgNA
BDIKDwoIBgACAgSbCAASA0AEMgo3CgQGAAIDEgREAkoDGikgQ2FuY2VscyBhbiBleGVjdXRp
b24gb2YgdGhlIGdpdmVuIG5hbWUuCgoMCgUGAAIDARIDRAYVCgwKBQYAAgMCEgNEFiwKDAoF
BgACAwMSA0Q3QAoNCgUGAAIDBBIERQRIBgoRCgkGAAIDBLDKvCISBEUESAYKDAoFBgACAwQS
A0kEMgoPCggGAAIDBJsIABIDSQQyCloKAgQAEgVOAI0BARpNIEEgcnVubmluZyBpbnN0YW5j
ZSBvZiBhIFtXb3JrZmxvd11bZ29vZ2xlLmNsb3VkLndvcmtmbG93cy52MWJldGEuV29ya2Zs
b3ddLgoKCgoDBAABEgNOCBEKCwoDBAAHEgRPAlIECg0KBQQAB50IEgRPAlIECkwKBAQAAwAS
BFUCWwMaPiBFcnJvciBkZXNjcmliZXMgd2h5IHRoZSBleGVjdXRpb24gd2FzIGFibm9ybWFs
bHkgdGVybWluYXRlZC4KCgwKBQQAAwABEgNVCg8KVwoGBAADAAIAEgNXBBcaSCBFcnJvciBw
YXlsb2FkIHJldHVybmVkIGJ5IHRoZSBleGVjdXRpb24sIHJlcHJlc2VudGVkIGFzIGEgSlNP
TiBzdHJpbmcuCgoOCgcEAAMAAgAFEgNXBAoKDgoHBAADAAIAARIDVwsSCg4KBwQAAwACAAMS
A1cVFgpOCgYEAAMAAgESA1oEFxo/IEh1bWFuIHJlYWRhYmxlIGVycm9yIGNvbnRleHQsIGhl
bHBmdWwgZm9yIGRlYnVnZ2luZyBwdXJwb3Nlcy4KCg4KBwQAAwACAQUSA1oECgoOCgcEAAMA
AgEBEgNaCxIKDgoHBAADAAIBAxIDWhUWCmYKBAQABAASBF8CbgMaWCBEZXNjcmliZXMgdGhl
IGN1cnJlbnQgc3RhdGUgb2YgdGhlIGV4ZWN1dGlvbi4gTW9yZSBzdGF0ZXMgbWF5IGJlIGFk
ZGVkCiBpbiB0aGUgZnV0dXJlLgoKDAoFBAAEAAESA18HDAofCgYEAAQAAgASA2EEGhoQIElu
dmFsaWQgc3RhdGUuCgoOCgcEAAQAAgABEgNhBBUKDgoHBAAEAAIAAhIDYRgZCi4KBgQABAAC
ARIDZAQPGh8gVGhlIGV4ZWN1dGlvbiBpcyBpbiBwcm9ncmVzcy4KCg4KBwQABAACAQESA2QE
CgoOCgcEAAQAAgECEgNkDQ4KNQoGBAAEAAICEgNnBBIaJiBUaGUgZXhlY3V0aW9uIGZpbmlz
aGVkIHN1Y2Nlc3NmdWxseS4KCg4KBwQABAACAgESA2cEDQoOCgcEAAQAAgICEgNnEBEKNAoG
BAAEAAIDEgNqBA8aJSBUaGUgZXhlY3V0aW9uIGZhaWxlZCB3aXRoIGFuIGVycm9yLgoKDgoH
BAAEAAIDARIDagQKCg4KBwQABAACAwISA2oNDgo5CgYEAAQAAgQSA20EEhoqIFRoZSBleGVj
dXRpb24gd2FzIHN0b3BwZWQgaW50ZW50aW9uYWxseS4KCg4KBwQABAACBAESA20EDQoOCgcE
AAQAAgQCEgNtEBEKngEKBAQAAgASA3MCPhqQASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIGV4ZWN1dGlvbi4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtmbG93fS9leGVjdXRpb25zL3tl
eGVjdXRpb259CgoMCgUEAAIABRIDcwIICgwKBQQAAgABEgNzCQ0KDAoFBAACAAMSA3MQEQoM
CgUEAAIACBIDcxI9Cg8KCAQAAgAInAgAEgNzEzwKPQoEBAACARIDdgJXGjAgT3V0cHV0IG9u
bHkuIE1hcmtzIHRoZSBiZWdpbm5pbmcgb2YgZXhlY3V0aW9uLgoKDAoFBAACAQYSA3YCGwoM
CgUEAAIBARIDdhwmCgwKBQQAAgEDEgN2KSoKDAoFBAACAQgSA3YrVgoPCggEAAIBCJwIABID
dixVCkoKBAQAAgISA3kCVRo9IE91dHB1dCBvbmx5LiBNYXJrcyB0aGUgZW5kIG9mIGV4ZWN1
dGlvbiwgc3VjY2Vzc2Z1bCBvciBub3QuCgoMCgUEAAICBhIDeQIbCgwKBQQAAgIBEgN5HCQK
DAoFBAACAgMSA3knKAoMCgUEAAICCBIDeSlUCg8KCAQAAgIInAgAEgN5KlMKOwoEBAACAxID
fAI+Gi4gT3V0cHV0IG9ubHkuIEN1cnJlbnQgc3RhdGUgb2YgdGhlIGV4ZWN1dGlvbi4KCgwK
BQQAAgMGEgN8AgcKDAoFBAACAwESA3wIDQoMCgUEAAIDAxIDfBARCgwKBQQAAgMIEgN8Ej0K
DwoIBAACAwicCAASA3wTPApoCgQEAAIEEgSAAQIWGlogSW5wdXQgcGFyYW1ldGVycyBvZiB0
aGUgZXhlY3V0aW9uIHJlcHJlc2VudGVkIGFzIGEgSlNPTiBzdHJpbmcuCiBUaGUgc2l6ZSBs
aW1pdCBpcyAzMktCLgoKDQoFBAACBAUSBIABAggKDQoFBAACBAESBIABCREKDQoFBAACBAMS
BIABFBUKmwEKBAQAAgUSBIQBAkAajAEgT3V0cHV0IG9ubHkuIE91dHB1dCBvZiB0aGUgZXhl
Y3V0aW9uIHJlcHJlc2VudGVkIGFzIGEgSlNPTiBzdHJpbmcuIFRoZQogdmFsdWUgY2FuIG9u
bHkgYmUgcHJlc2VudCBpZiB0aGUgZXhlY3V0aW9uJ3Mgc3RhdGUgaXMgYFNVQ0NFRURFRGAu
CgoNCgUEAAIFBRIEhAECCAoNCgUEAAIFARIEhAEJDwoNCgUEAAIFAxIEhAESEwoNCgUEAAIF
CBIEhAEUPwoQCggEAAIFCJwIABIEhAEVPgqqAQoEBAACBhIEiQECPhqbASBPdXRwdXQgb25s
eS4gVGhlIGVycm9yIHdoaWNoIGNhdXNlZCB0aGUgZXhlY3V0aW9uIHRvIGZpbmlzaCBwcmVt
YXR1cmVseS4KIFRoZSB2YWx1ZSBpcyBvbmx5IHByZXNlbnQgaWYgdGhlIGV4ZWN1dGlvbidz
IHN0YXRlIGlzIGBGQUlMRURgCiBvciBgQ0FOQ0VMTEVEYC4KCg0KBQQAAgYGEgSJAQIHCg0K
BQQAAgYBEgSJAQgNCg0KBQQAAgYDEgSJARARCg0KBQQAAgYIEgSJARI9ChAKCAQAAgYInAgA
EgSJARM8Ck4KBAQAAgcSBIwBAk4aQCBPdXRwdXQgb25seS4gUmV2aXNpb24gb2YgdGhlIHdv
cmtmbG93IHRoaXMgZXhlY3V0aW9uIGlzIHVzaW5nLgoKDQoFBAACBwUSBIwBAggKDQoFBAAC
BwESBIwBCR0KDQoFBAACBwMSBIwBICEKDQoFBAACBwgSBIwBIk0KEAoIBAACBwicCAASBIwB
I0wKfgoCBAESBpIBAK0BARpwIFJlcXVlc3QgZm9yIHRoZQogW0xpc3RFeGVjdXRpb25zXVtn
b29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMudjFiZXRhLkV4ZWN1dGlvbnMuTGlz
dEV4ZWN1dGlvbnNdCiBtZXRob2QuCgoLCgMEAQESBJIBCB0KogEKBAQBAgASBpUBApoBBBqR
ASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgd29ya2Zsb3cgZm9yIHdoaWNoIHRoZSBleGVjdXRp
b25zIHNob3VsZCBiZSBsaXN0ZWQuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtmbG93fQoKDQoFBAECAAUSBJUBAggK
DQoFBAECAAESBJUBCQ8KDQoFBAECAAMSBJUBEhMKDwoFBAECAAgSBpUBFJoBAwoQCggEAQIA
CJwIABIElgEEKgoRCgcEAQIACJ8IEgaXAQSZAQUKxAIKBAQBAgESBKEBAhYatQIgTWF4aW11
bSBudW1iZXIgb2YgZXhlY3V0aW9ucyB0byByZXR1cm4gcGVyIGNhbGwuCiBNYXggc3VwcG9y
dGVkIHZhbHVlIGRlcGVuZHMgb24gdGhlIHNlbGVjdGVkIEV4ZWN1dGlvbiB2aWV3OiBpdCdz
IDEwMDAwIGZvcgogQkFTSUMgYW5kIDEwMCBmb3IgRlVMTC4gVGhlIGRlZmF1bHQgdmFsdWUg
dXNlZCBpZiB0aGUgZmllbGQgaXMgbm90CiBzcGVjaWZpZWQgaXMgMTAwLCByZWdhcmRsZXNz
IG9mIHRoZSBzZWxlY3RlZCB2aWV3LiBWYWx1ZXMgZ3JlYXRlciB0aGFuCiB0aGUgbWF4IHZh
bHVlIHdpbGwgYmUgY29lcmNlZCBkb3duIHRvIGl0LgoKDQoFBAECAQUSBKEBAgcKDQoFBAEC
AQESBKEBCBEKDQoFBAECAQMSBKEBFBUK9QEKBAQBAgISBKgBAhga5gEgQSBwYWdlIHRva2Vu
LCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RFeGVjdXRpb25zYCBjYWxsLgogUHJv
dmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdp
bmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBgTGlzdEV4ZWN1dGlv
bnNgIG11c3QKIG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4u
CgoNCgUEAQICBRIEqAECCAoNCgUEAQICARIEqAEJEwoNCgUEAQICAxIEqAEWFwqMAQoEBAEC
AxIErAECQhp+IE9wdGlvbmFsLiBBIHZpZXcgZGVmaW5pbmcgd2hpY2ggZmllbGRzIHNob3Vs
ZCBiZSBmaWxsZWQgaW4gdGhlIHJldHVybmVkIGV4ZWN1dGlvbnMuCiBUaGUgQVBJIHdpbGwg
ZGVmYXVsdCB0byB0aGUgQkFTSUMgdmlldy4KCg0KBQQBAgMGEgSsAQIPCg0KBQQBAgMBEgSs
ARAUCg0KBQQBAgMDEgSsARcYCg0KBQQBAgMIEgSsARlBChAKCAQBAgMInAgAEgSsARpACn8K
AgQCEgayAQC5AQEacSBSZXNwb25zZSBmb3IgdGhlCiBbTGlzdEV4ZWN1dGlvbnNdW2dvb2ds
ZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MWJldGEuRXhlY3V0aW9ucy5MaXN0RXhl
Y3V0aW9uc10KIG1ldGhvZC4KCgsKAwQCARIEsgEIHgo3CgQEAgIAEgS0AQIkGikgVGhlIGV4
ZWN1dGlvbnMgd2hpY2ggbWF0Y2ggdGhlIHJlcXVlc3QuCgoNCgUEAgIABBIEtAECCgoNCgUE
AgIABhIEtAELFAoNCgUEAgIAARIEtAEVHwoNCgUEAgIAAxIEtAEiIwqQAQoEBAICARIEuAEC
HRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0
cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUg
YXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAgIBBRIEuAECCAoNCgUEAgIBARIEuAEJ
GAoNCgUEAgIBAxIEuAEbHAqAAQoCBAMSBr4BAMsBARpyIFJlcXVlc3QgZm9yIHRoZQogW0Ny
ZWF0ZUV4ZWN1dGlvbl1bZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxYmV0
YS5FeGVjdXRpb25zLkNyZWF0ZUV4ZWN1dGlvbl0KIG1ldGhvZC4KCgsKAwQDARIEvgEIHgrU
AQoEBAMCABIGwgECxwEEGsMBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSB3b3JrZmxvdyBmb3Ig
d2hpY2ggYW4gZXhlY3V0aW9uIHNob3VsZCBiZSBjcmVhdGVkLgogRm9ybWF0OiBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vd29ya2Zsb3dzL3t3b3JrZmxvd30K
IFRoZSBsYXRlc3QgcmV2aXNpb24gb2YgdGhlIHdvcmtmbG93IHdpbGwgYmUgdXNlZC4KCg0K
BQQDAgAFEgTCAQIICg0KBQQDAgABEgTCAQkPCg0KBQQDAgADEgTCARITCg8KBQQDAgAIEgbC
ARTHAQMKEAoIBAMCAAicCAASBMMBBCoKEQoHBAMCAAifCBIGxAEExgEFCjIKBAQDAgESBMoB
AkMaJCBSZXF1aXJlZC4gRXhlY3V0aW9uIHRvIGJlIGNyZWF0ZWQuCgoNCgUEAwIBBhIEygEC
CwoNCgUEAwIBARIEygEMFQoNCgUEAwIBAxIEygEYGQoNCgUEAwIBCBIEygEaQgoQCggEAwIB
CJwIABIEygEbQQp6CgIEBBIG0AEA3gEBGmwgUmVxdWVzdCBmb3IgdGhlCiBbR2V0RXhlY3V0
aW9uXVtnb29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMudjFiZXRhLkV4ZWN1dGlv
bnMuR2V0RXhlY3V0aW9uXQogbWV0aG9kLgoKCwoDBAQBEgTQAQgbCqEBCgQEBAIAEgbUAQLZ
AQQakAEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGV4ZWN1dGlvbiB0byBiZSByZXRyaWV2ZWQu
CiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vd29y
a2Zsb3dzL3t3b3JrZmxvd30vZXhlY3V0aW9ucy97ZXhlY3V0aW9ufQoKDQoFBAQCAAUSBNQB
AggKDQoFBAQCAAESBNQBCQ0KDQoFBAQCAAMSBNQBEBEKDwoFBAQCAAgSBtQBEtkBAwoQCggE
BAIACJwIABIE1QEEKgoRCgcEBAIACJ8IEgbWAQTYAQUKigEKBAQEAgESBN0BAkIafCBPcHRp
b25hbC4gQSB2aWV3IGRlZmluaW5nIHdoaWNoIGZpZWxkcyBzaG91bGQgYmUgZmlsbGVkIGlu
IHRoZSByZXR1cm5lZCBleGVjdXRpb24uCiBUaGUgQVBJIHdpbGwgZGVmYXVsdCB0byB0aGUg
RlVMTCB2aWV3LgoKDQoFBAQCAQYSBN0BAg8KDQoFBAQCAQESBN0BEBQKDQoFBAQCAQMSBN0B
FxgKDQoFBAQCAQgSBN0BGUEKEAoIBAQCAQicCAASBN0BGkAKgAEKAgQFEgbjAQDtAQEaciBS
ZXF1ZXN0IGZvciB0aGUKIFtDYW5jZWxFeGVjdXRpb25dW2dvb2dsZS5jbG91ZC53b3JrZmxv
d3MuZXhlY3V0aW9ucy52MWJldGEuRXhlY3V0aW9ucy5DYW5jZWxFeGVjdXRpb25dCiBtZXRo
b2QuCgoLCgMEBQESBOMBCB4KoQEKBAQFAgASBucBAuwBBBqQASBSZXF1aXJlZC4gTmFtZSBv
ZiB0aGUgZXhlY3V0aW9uIHRvIGJlIGNhbmNlbGxlZC4KIEZvcm1hdDoKIHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtmbG93fS9leGVj
dXRpb25zL3tleGVjdXRpb259CgoNCgUEBQIABRIE5wECCAoNCgUEBQIAARIE5wEJDQoNCgUE
BQIAAxIE5wEQEQoPCgUEBQIACBIG5wES7AEDChAKCAQFAgAInAgAEgToAQQqChEKBwQFAgAI
nwgSBukBBOsBBQo+CgIFABIG8AEA+wEBGjAgRGVmaW5lcyBwb3NzaWJsZSB2aWV3cyBmb3Ig
ZXhlY3V0aW9uIHJlc291cmNlLgoKCwoDBQABEgTwAQUSCioKBAUAAgASBPIBAiEaHCBUaGUg
ZGVmYXVsdCAvIHVuc2V0IHZhbHVlLgoKDQoFBQACAAESBPIBAhwKDQoFBQACAAISBPIBHyAK
nwEKBAUAAgESBPcBAgwakAEgSW5jbHVkZXMgb25seSBiYXNpYyBtZXRhZGF0YSBhYm91dCB0
aGUgZXhlY3V0aW9uLgogRm9sbG93aW5nIGZpZWxkcyBhcmUgcmV0dXJuZWQ6IG5hbWUsIHN0
YXJ0X3RpbWUsIGVuZF90aW1lLCBzdGF0ZQogYW5kIHdvcmtmbG93X3JldmlzaW9uX2lkLgoK
DQoFBQACAQESBPcBAgcKDQoFBQACAQISBPcBCgsKIgoEBQACAhIE+gECCxoUIEluY2x1ZGVz
IGFsbCBkYXRhLgoKDQoFBQACAgESBPoBAgYKDQoFBQACAgISBPoBCQpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Workflows::Executions::V1beta::Executions::Execution ===
    # Fields for Execution
    # Field: name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.workflows.executions.v1beta.Execution.State)
    # Field: argument Type: 9 ()
    # Field: result Type: 9 ()
    # Field: error Type: 11 (.google.cloud.workflows.executions.v1beta.Execution.Error)
    # Field: workflow_revision_id Type: 9 ()

# Enum: Execution::State
our $Execution_STATE_UNSPECIFIED = 0;
our $Execution_ACTIVE = 1;
our $Execution_SUCCEEDED = 2;
our $Execution_FAILED = 3;
our $Execution_CANCELLED = 4;

# === Message: Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsRequest ===
    # Fields for ListExecutionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.cloud.workflows.executions.v1beta.ExecutionView)

# === Message: Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsResponse ===
    # Fields for ListExecutionsResponse
    # Field: executions Type: 11 (.google.cloud.workflows.executions.v1beta.Execution)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Workflows::Executions::V1beta::Executions::CreateExecutionRequest ===
    # Fields for CreateExecutionRequest
    # Field: parent Type: 9 ()
    # Field: execution Type: 11 (.google.cloud.workflows.executions.v1beta.Execution)

# === Message: Google::Cloud::Workflows::Executions::V1beta::Executions::GetExecutionRequest ===
    # Fields for GetExecutionRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.cloud.workflows.executions.v1beta.ExecutionView)

# === Message: Google::Cloud::Workflows::Executions::V1beta::Executions::CancelExecutionRequest ===
    # Fields for CancelExecutionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Workflows::Executions::V1beta::Executions::ExecutionsClient ===
package Google::Cloud::Workflows::Executions::V1beta::Executions::ExecutionsClient;

=pod

=head2 Service Client: Google::Cloud::Workflows::Executions::V1beta::Executions::ExecutionsClient

Client stub representing the remote C<Executions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<workflows.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'workflows.googleapis.com:443' );

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

sub list_executions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1beta.Executions',
        method         => 'ListExecutions',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsResponse',
    });
}

sub create_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1beta::Executions::CreateExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1beta.Executions',
        method         => 'CreateExecution',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution',
    });
}

sub get_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1beta::Executions::GetExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1beta.Executions',
        method         => 'GetExecution',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution',
    });
}

sub cancel_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1beta::Executions::CancelExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1beta.Executions',
        method         => 'CancelExecution',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Workflows::Executions::V1beta::Executions - Compiled Protocol Buffers messages for google/cloud/workflows/executions/v1beta/executions.proto

=head1 SYNOPSIS

    use Google::Cloud::Workflows::Executions::V1beta::Executions;

    my $msg = Google::Cloud::Workflows::Executions::V1beta::Executions::Execution->new({
        name => $name,
        start_time => $start_time,
        end_time => $end_time,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Workflows::Executions::V1beta::Executions::Execution->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/workflows/executions/v1beta/executions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Workflows::Executions::V1beta::Executions::Execution

A running instance of a [Workflow][google.cloud.workflows.v1beta.Workflow].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the execution.
Format:
projects/{project}/locations/{location}/workflows/{workflow}/executions/{execution}

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Marks the beginning of execution.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Marks the end of execution, successful or not.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1beta::Execution::State>)

Output only. Current state of the execution.

=item * C<< $msg->argument() >> / C<< $msg->argument($value) >>

Type: C<String>

Input parameters of the execution represented as a JSON string.
The size limit is 32KB.

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<String>

Output only. Output of the execution represented as a JSON string. The
value can only be present if the execution's state is `SUCCEEDED`.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1beta::Executions::Execution::Error>)

Output only. The error which caused the execution to finish prematurely.
The value is only present if the execution's state is `FAILED`
or `CANCELLED`.

=item * C<< $msg->workflow_revision_id() >> / C<< $msg->workflow_revision_id($value) >>

Type: C<String>

Output only. Revision of the workflow this execution is using.

=back

=head3 Enum: Execution::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<FAILED> => C<3>

=item * C<CANCELLED> => C<4>

=back

=head2 Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsRequest

Request for the
[ListExecutions][google.cloud.workflows.executions.v1beta.Executions.ListExecutions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the workflow for which the executions should be listed.
Format: projects/{project}/locations/{location}/workflows/{workflow}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of executions to return per call.
Max supported value depends on the selected Execution view: it's 10000 for
BASIC and 100 for FULL. The default value used if the field is not
specified is 100, regardless of the selected view. Values greater than
the max value will be coerced down to it.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListExecutions` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListExecutions` must
match the call that provided the page token.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1beta::ExecutionView>)

Optional. A view defining which fields should be filled in the returned executions.
The API will default to the BASIC view.

=back

=head2 Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsResponse

Response for the
[ListExecutions][google.cloud.workflows.executions.v1beta.Executions.ListExecutions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->executions() >> / C<< $msg->executions($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1beta::Executions::Execution>)

The executions which match the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Workflows::Executions::V1beta::Executions::CreateExecutionRequest

Request for the
[CreateExecution][google.cloud.workflows.executions.v1beta.Executions.CreateExecution]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the workflow for which an execution should be created.
Format: projects/{project}/locations/{location}/workflows/{workflow}
The latest revision of the workflow will be used.

=item * C<< $msg->execution() >> / C<< $msg->execution($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1beta::Executions::Execution>)

Required. Execution to be created.

=back

=head2 Google::Cloud::Workflows::Executions::V1beta::Executions::GetExecutionRequest

Request for the
[GetExecution][google.cloud.workflows.executions.v1beta.Executions.GetExecution]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the execution to be retrieved.
Format:
projects/{project}/locations/{location}/workflows/{workflow}/executions/{execution}

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1beta::ExecutionView>)

Optional. A view defining which fields should be filled in the returned execution.
The API will default to the FULL view.

=back

=head2 Google::Cloud::Workflows::Executions::V1beta::Executions::CancelExecutionRequest

Request for the
[CancelExecution][google.cloud.workflows.executions.v1beta.Executions.CancelExecution]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the execution to be cancelled.
Format:
projects/{project}/locations/{location}/workflows/{workflow}/executions/{execution}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Workflows::Executions::V1beta::Executions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
