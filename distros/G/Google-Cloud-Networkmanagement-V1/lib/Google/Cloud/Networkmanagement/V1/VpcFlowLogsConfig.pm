package Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvbmV0d29ya21hbmFnZW1lbnQvdjEvdnBjX2Zsb3dfbG9nc19jb25m
aWcucHJvdG8SIWdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKVEgoRVnBjRmxvd0xvZ3NDb25maWcSFwoE
bmFtZRgBIAEoCUID4EEIUgRuYW1lEioKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFIAVILZGVz
Y3JpcHRpb26IAQESWgoFc3RhdGUYAyABKA4yOi5nb29nbGUuY2xvdWQubmV0d29ya21hbmFn
ZW1lbnQudjEuVnBjRmxvd0xvZ3NDb25maWcuU3RhdGVCA+BBAUgCUgVzdGF0ZYgBARKFAQoU
YWdncmVnYXRpb25faW50ZXJ2YWwYBCABKA4ySC5nb29nbGUuY2xvdWQubmV0d29ya21hbmFn
ZW1lbnQudjEuVnBjRmxvd0xvZ3NDb25maWcuQWdncmVnYXRpb25JbnRlcnZhbEID4EEBSANS
E2FnZ3JlZ2F0aW9uSW50ZXJ2YWyIAQESLQoNZmxvd19zYW1wbGluZxgFIAEoAkID4EEBSARS
DGZsb3dTYW1wbGluZ4gBARJjCghtZXRhZGF0YRgGIAEoDjI9Lmdvb2dsZS5jbG91ZC5uZXR3
b3JrbWFuYWdlbWVudC52MS5WcGNGbG93TG9nc0NvbmZpZy5NZXRhZGF0YUID4EEBSAVSCG1l
dGFkYXRhiAEBEiwKD21ldGFkYXRhX2ZpZWxkcxgHIAMoCUID4EEBUg5tZXRhZGF0YUZpZWxk
cxIpCgtmaWx0ZXJfZXhwchgIIAEoCUID4EEBSAZSCmZpbHRlckV4cHKIAQESiQEKFmNyb3Nz
X3Byb2plY3RfbWV0YWRhdGEYDSABKA4ySS5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1l
bnQudjEuVnBjRmxvd0xvZ3NDb25maWcuQ3Jvc3NQcm9qZWN0TWV0YWRhdGFCA+BBAUgHUhRj
cm9zc1Byb2plY3RNZXRhZGF0YYgBARKGAQoVdGFyZ2V0X3Jlc291cmNlX3N0YXRlGAwgASgO
MkguZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLlZwY0Zsb3dMb2dzQ29uZmln
LlRhcmdldFJlc291cmNlU3RhdGVCA+BBA0gIUhN0YXJnZXRSZXNvdXJjZVN0YXRliAEBEhoK
B25ldHdvcmsYZCABKAlIAFIHbmV0d29yaxIYCgZzdWJuZXQYZSABKAlIAFIGc3VibmV0EjkK
F2ludGVyY29ubmVjdF9hdHRhY2htZW50GGYgASgJSABSFmludGVyY29ubmVjdEF0dGFjaG1l
bnQSHwoKdnBuX3R1bm5lbBhnIAEoCUgAUgl2cG5UdW5uZWwSXQoGbGFiZWxzGAsgAygLMkAu
Z29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLlZwY0Zsb3dMb2dzQ29uZmlnLkxh
YmVsc0VudHJ5QgPgQQFSBmxhYmVscxJACgtjcmVhdGVfdGltZRgJIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgKIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRo5CgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIjkK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHRU5BQkxFRBABEgwKCERJU0FCTEVE
EAIitgEKE0FnZ3JlZ2F0aW9uSW50ZXJ2YWwSJAogQUdHUkVHQVRJT05fSU5URVJWQUxfVU5T
UEVDSUZJRUQQABISCg5JTlRFUlZBTF81X1NFQxABEhMKD0lOVEVSVkFMXzMwX1NFQxACEhIK
DklOVEVSVkFMXzFfTUlOEAMSEgoOSU5URVJWQUxfNV9NSU4QBBITCg9JTlRFUlZBTF8xMF9N
SU4QBRITCg9JTlRFUlZBTF8xNV9NSU4QBiJtCghNZXRhZGF0YRIYChRNRVRBREFUQV9VTlNQ
RUNJRklFRBAAEhgKFElOQ0xVREVfQUxMX01FVEFEQVRBEAESGAoURVhDTFVERV9BTExfTUVU
QURBVEEQAhITCg9DVVNUT01fTUVUQURBVEEQAyKHAQoUQ3Jvc3NQcm9qZWN0TWV0YWRhdGES
JgoiQ1JPU1NfUFJPSkVDVF9NRVRBREFUQV9VTlNQRUNJRklFRBAAEiIKHkNST1NTX1BST0pF
Q1RfTUVUQURBVEFfRU5BQkxFRBABEiMKH0NST1NTX1BST0pFQ1RfTUVUQURBVEFfRElTQUJM
RUQQAiJ8ChNUYXJnZXRSZXNvdXJjZVN0YXRlEiUKIVRBUkdFVF9SRVNPVVJDRV9TVEFURV9V
TlNQRUNJRklFRBAAEhoKFlRBUkdFVF9SRVNPVVJDRV9FWElTVFMQARIiCh5UQVJHRVRfUkVT
T1VSQ0VfRE9FU19OT1RfRVhJU1QQAjqPAupBiwIKMm5ldHdvcmttYW5hZ2VtZW50Lmdvb2ds
ZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmlnElFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vdnBjRmxvd0xvZ3NDb25maWdzL3t2cGNfZmxvd19sb2dzX2NvbmZp
Z30SW29yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
dnBjRmxvd0xvZ3NDb25maWdzL3t2cGNfZmxvd19sb2dzX2NvbmZpZ30qEnZwY0Zsb3dMb2dz
Q29uZmlnczIRdnBjRmxvd0xvZ3NDb25maWdCEQoPdGFyZ2V0X3Jlc291cmNlQg4KDF9kZXNj
cmlwdGlvbkIICgZfc3RhdGVCFwoVX2FnZ3JlZ2F0aW9uX2ludGVydmFsQhAKDl9mbG93X3Nh
bXBsaW5nQgsKCV9tZXRhZGF0YUIOCgxfZmlsdGVyX2V4cHJCGQoXX2Nyb3NzX3Byb2plY3Rf
bWV0YWRhdGFCGAoWX3RhcmdldF9yZXNvdXJjZV9zdGF0ZSL3CAoaRWZmZWN0aXZlVnBjRmxv
d0xvZ3NDb25maWcSEgoEbmFtZRgBIAEoCVIEbmFtZRJVCgVzdGF0ZRgDIAEoDjI6Lmdvb2ds
ZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5WcGNGbG93TG9nc0NvbmZpZy5TdGF0ZUgB
UgVzdGF0ZYgBARKAAQoUYWdncmVnYXRpb25faW50ZXJ2YWwYBCABKA4ySC5nb29nbGUuY2xv
dWQubmV0d29ya21hbmFnZW1lbnQudjEuVnBjRmxvd0xvZ3NDb25maWcuQWdncmVnYXRpb25J
bnRlcnZhbEgCUhNhZ2dyZWdhdGlvbkludGVydmFsiAEBEigKDWZsb3dfc2FtcGxpbmcYBSAB
KAJIA1IMZmxvd1NhbXBsaW5niAEBEl4KCG1ldGFkYXRhGAYgASgOMj0uZ29vZ2xlLmNsb3Vk
Lm5ldHdvcmttYW5hZ2VtZW50LnYxLlZwY0Zsb3dMb2dzQ29uZmlnLk1ldGFkYXRhSARSCG1l
dGFkYXRhiAEBEicKD21ldGFkYXRhX2ZpZWxkcxgHIAMoCVIObWV0YWRhdGFGaWVsZHMSJAoL
ZmlsdGVyX2V4cHIYCCABKAlIBVIKZmlsdGVyRXhwcogBARKEAQoWY3Jvc3NfcHJvamVjdF9t
ZXRhZGF0YRgNIAEoDjJJLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5WcGNG
bG93TG9nc0NvbmZpZy5Dcm9zc1Byb2plY3RNZXRhZGF0YUgGUhRjcm9zc1Byb2plY3RNZXRh
ZGF0YYgBARIaCgduZXR3b3JrGGQgASgJSABSB25ldHdvcmsSGAoGc3VibmV0GGUgASgJSABS
BnN1Ym5ldBI5ChdpbnRlcmNvbm5lY3RfYXR0YWNobWVudBhmIAEoCUgAUhZpbnRlcmNvbm5l
Y3RBdHRhY2htZW50Eh8KCnZwbl90dW5uZWwYZyABKAlIAFIJdnBuVHVubmVsEl4KBXNjb3Bl
GAwgASgOMkMuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLkVmZmVjdGl2ZVZw
Y0Zsb3dMb2dzQ29uZmlnLlNjb3BlSAdSBXNjb3BliAEBIo4BCgVTY29wZRIVChFTQ09QRV9V
TlNQRUNJRklFRBAAEgoKBlNVQk5FVBABEhYKEkNPTVBVVEVfQVBJX1NVQk5FVBACEgsKB05F
VFdPUksQAxIOCgpWUE5fVFVOTkVMEAQSGwoXSU5URVJDT05ORUNUX0FUVEFDSE1FTlQQBRIQ
CgxPUkdBTklaQVRJT04QBkIRCg90YXJnZXRfcmVzb3VyY2VCCAoGX3N0YXRlQhcKFV9hZ2dy
ZWdhdGlvbl9pbnRlcnZhbEIQCg5fZmxvd19zYW1wbGluZ0ILCglfbWV0YWRhdGFCDgoMX2Zp
bHRlcl9leHByQhkKF19jcm9zc19wcm9qZWN0X21ldGFkYXRhQggKBl9zY29wZULyAgolY29t
Lmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MUIWVnBjRmxvd0xvZ3NDb25maWdQ
cm90b1ABWlNjbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmttYW5hZ2VtZW50L2FwaXYxL25l
dHdvcmttYW5hZ2VtZW50cGI7bmV0d29ya21hbmFnZW1lbnRwYqoCIUdvb2dsZS5DbG91ZC5O
ZXR3b3JrTWFuYWdlbWVudC5WMcoCIUdvb2dsZVxDbG91ZFxOZXR3b3JrTWFuYWdlbWVudFxW
MeoCJEdvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtNYW5hZ2VtZW50OjpWMepBago1bmV0d29ya21h
bmFnZW1lbnQuZ29vZ2xlYXBpcy5jb20vT3JnYW5pemF0aW9uTG9jYXRpb24SMW9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn1K3F4KBxIFDgC8AgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIA
KQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA+CgkKAgglEgMWAD4KCAoBCBIDFwBq
CgkKAggLEgMXAGoKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA3CgkKAggIEgMZADcK
CAoBCBIDGgA+CgkKAggBEgMaAD4KCAoBCBIDGwA+CgkKAggpEgMbAD4KCAoBCBIDHAA9CgkK
AggtEgMcAD0KCQoBCBIEHQAgAgoMCgQInQgAEgQdACACCrEBCgIEABIFJwDXAQEaLCBBIGNv
bmZpZ3VyYXRpb24gdG8gZ2VuZXJhdGUgVlBDIEZsb3cgTG9ncy4KMnYgRGVmaW5pdGlvbiBv
ZiBhIFZwY0Zsb3dMb2dzQ29uZmlnIHJlc291cmNlLCB3aGljaCBjb250YWlucyB0aGUgY29u
ZmlndXJhdGlvbgogZm9yIFZQQyBGbG93IExvZ3MuCiBMSU5UOiBMRUdBQ1lfTkFNRVMKCgoK
AwQAARIDJwgZCgsKAwQABxIEKAIuBAoNCgUEAAedCBIEKAIuBApOCgQEAAQAEgQxAjoDGkAg
RGV0ZXJtaW5lcyB3aGV0aGVyIHRoaXMgY29uZmlndXJhdGlvbiB3aWxsIGJlIGdlbmVyYXRp
bmcgbG9ncy4KCgwKBQQABAABEgMxBwwKOwoGBAAEAAIAEgMzBBoaLCBJZiBub3Qgc3BlY2lm
aWVkLCB3aWxsIGRlZmF1bHQgdG8gRU5BQkxFRC4KCg4KBwQABAACAAESAzMEFQoOCgcEAAQA
AgACEgMzGBkKRQoGBAAEAAIBEgM2BBAaNiBXaGVuIEVOQUJMRUQsIHRoaXMgY29uZmlndXJh
dGlvbiB3aWxsIGdlbmVyYXRlIGxvZ3MuCgoOCgcEAAQAAgEBEgM2BAsKDgoHBAAEAAIBAhID
Ng4PCkoKBgQABAACAhIDOQQRGjsgV2hlbiBESVNBQkxFRCwgdGhpcyBjb25maWd1cmF0aW9u
IHdpbGwgbm90IGdlbmVyYXRlIGxvZ3MuCgoOCgcEAAQAAgIBEgM5BAwKDgoHBAAEAAICAhID
OQ8QClUKBAQABAESBD0CUgMaRyBUb2dnbGVzIHRoZSBhZ2dyZWdhdGlvbiBpbnRlcnZhbCBm
b3IgY29sbGVjdGluZyBmbG93IGxvZ3MgYnkgNS10dXBsZS4KCgwKBQQABAEBEgM9BxoKQgoG
BAAEAQIAEgM/BCkaMyBJZiBub3Qgc3BlY2lmaWVkLCB3aWxsIGRlZmF1bHQgdG8gSU5URVJW
QUxfNV9TRUMuCgoOCgcEAAQBAgABEgM/BCQKDgoHBAAEAQIAAhIDPycoCjAKBgQABAECARID
QgQXGiEgQWdncmVnYXRlIGxvZ3MgaW4gNXMgaW50ZXJ2YWxzLgoKDgoHBAAEAQIBARIDQgQS
Cg4KBwQABAECAQISA0IVFgoxCgYEAAQBAgISA0UEGBoiIEFnZ3JlZ2F0ZSBsb2dzIGluIDMw
cyBpbnRlcnZhbHMuCgoOCgcEAAQBAgIBEgNFBBMKDgoHBAAEAQICAhIDRRYXCjAKBgQABAEC
AxIDSAQXGiEgQWdncmVnYXRlIGxvZ3MgaW4gMW0gaW50ZXJ2YWxzLgoKDgoHBAAEAQIDARID
SAQSCg4KBwQABAECAwISA0gVFgowCgYEAAQBAgQSA0sEFxohIEFnZ3JlZ2F0ZSBsb2dzIGlu
IDVtIGludGVydmFscy4KCg4KBwQABAECBAESA0sEEgoOCgcEAAQBAgQCEgNLFRYKMQoGBAAE
AQIFEgNOBBgaIiBBZ2dyZWdhdGUgbG9ncyBpbiAxMG0gaW50ZXJ2YWxzLgoKDgoHBAAEAQIF
ARIDTgQTCg4KBwQABAECBQISA04WFwoxCgYEAAQBAgYSA1EEGBoiIEFnZ3JlZ2F0ZSBsb2dz
IGluIDE1bSBpbnRlcnZhbHMuCgoOCgcEAAQBAgYBEgNRBBMKDgoHBAAEAQIGAhIDURYXCj4K
BAQABAISBFUCYQMaMCBDb25maWd1cmVzIHdoaWNoIGxvZyBmaWVsZHMgd291bGQgYmUgaW5j
bHVkZWQuCgoMCgUEAAQCARIDVQcPCkgKBgQABAICABIDVwQdGjkgSWYgbm90IHNwZWNpZmll
ZCwgd2lsbCBkZWZhdWx0IHRvIElOQ0xVREVfQUxMX01FVEFEQVRBLgoKDgoHBAAEAgIAARID
VwQYCg4KBwQABAICAAISA1cbHAotCgYEAAQCAgESA1oEHRoeIEluY2x1ZGUgYWxsIG1ldGFk
YXRhIGZpZWxkcy4KCg4KBwQABAICAQESA1oEGAoOCgcEAAQCAgECEgNaGxwKLQoGBAAEAgIC
EgNdBB0aHiBFeGNsdWRlIGFsbCBtZXRhZGF0YSBmaWVsZHMuCgoOCgcEAAQCAgIBEgNdBBgK
DgoHBAAEAgICAhIDXRscCksKBgQABAICAxIDYAQYGjwgSW5jbHVkZSBvbmx5IGN1c3RvbSBm
aWVsZHMgKHNwZWNpZmllZCBpbiBtZXRhZGF0YV9maWVsZHMpLgoKDgoHBAAEAgIDARIDYAQT
Cg4KBwQABAICAwISA2AWFwqfAQoEBAAEAxIEZQJwAxqQASBEZXRlcm1pbmVzIHdoZXRoZXIg
dG8gaW5jbHVkZSBjcm9zcyBwcm9qZWN0IGFubm90YXRpb25zIGluIHRoZSBsb2dzLgogUHJv
amVjdCBjb25maWd1cmF0aW9ucyB3aWxsIGFsd2F5cyBoYXZlIENST1NTX1BST0pFQ1RfTUVU
QURBVEFfRElTQUJMRUQuCgoMCgUEAAQDARIDZQcbClEKBgQABAMCABIDZwQrGkIgSWYgbm90
IHNwZWNpZmllZCwgdGhlIGRlZmF1bHQgaXMgQ1JPU1NfUFJPSkVDVF9NRVRBREFUQV9FTkFC
TEVELgoKDgoHBAAEAwIAARIDZwQmCg4KBwQABAMCAAISA2cpKgpxCgYEAAQDAgESA2sEJxpi
IFdoZW4gQ1JPU1NfUFJPSkVDVF9NRVRBREFUQV9FTkFCTEVELCBtZXRhZGF0YSBmcm9tIG90
aGVyIHByb2plY3RzIHdpbGwgYmUKIGluY2x1ZGVkIGluIHRoZSBsb2dzLgoKDgoHBAAEAwIB
ARIDawQiCg4KBwQABAMCAQISA2slJgp2CgYEAAQDAgISA28EKBpnIFdoZW4gQ1JPU1NfUFJP
SkVDVF9NRVRBREFUQV9ESVNBQkxFRCwgbWV0YWRhdGEgZnJvbSBvdGhlciBwcm9qZWN0cyB3
aWxsCiBub3QgYmUgaW5jbHVkZWQgaW4gdGhlIGxvZ3MuCgoOCgcEAAQDAgIBEgNvBCMKDgoH
BAAEAwICAhIDbyYnCmQKBAQABAQSBHQCfQMaViBPdXRwdXQgb25seS4gSW5kaWNhdGVzIHdo
ZXRoZXIgdGhlIHRhcmdldCByZXNvdXJjZSBleGlzdHMsIGZvciBkaWFnbm9zdGljCiBwdXJw
b3Nlcy4KCgwKBQQABAQBEgN0BxoKMwoGBAAEBAIAEgN2BCoaJCBVbnNwZWNpZmllZCB0YXJn
ZXQgcmVzb3VyY2Ugc3RhdGUuCgoOCgcEAAQEAgABEgN2BCUKDgoHBAAEBAIAAhIDdigpCjsK
BgQABAQCARIDeQQfGiwgSW5kaWNhdGVzIHRoYXQgdGhlIHRhcmdldCByZXNvdXJjZSBleGlz
dHMuCgoOCgcEAAQEAgEBEgN5BBoKDgoHBAAEBAIBAhIDeR0eCkMKBgQABAQCAhIDfAQnGjQg
SW5kaWNhdGVzIHRoYXQgdGhlIHRhcmdldCByZXNvdXJjZSBkb2VzIG5vdCBleGlzdC4KCg4K
BwQABAQCAgESA3wEIgoOCgcEAAQEAgICEgN8JSYK9gIKBAQAAgASBIcBAj0a5wIgSWRlbnRp
Zmllci4gVW5pcXVlIG5hbWUgb2YgdGhlIGNvbmZpZ3VyYXRpb24uIFRoZSBuYW1lIGNhbiBo
YXZlIG9uZSBvZiB0aGUKIGZvbGxvd2luZyBmb3JtczoKCiAtIEZvciBwcm9qZWN0LWxldmVs
IGNvbmZpZ3VyYXRpb25zOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xv
YmFsL3ZwY0Zsb3dMb2dzQ29uZmlncy97dnBjX2Zsb3dfbG9nc19jb25maWdfaWR9YAoKIC0g
Rm9yIG9yZ2FuaXphdGlvbi1sZXZlbCBjb25maWd1cmF0aW9uczoKIGBvcmdhbml6YXRpb25z
L3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy9nbG9iYWwvdnBjRmxvd0xvZ3NDb25maWdz
L3t2cGNfZmxvd19sb2dzX2NvbmZpZ19pZH1gCgoNCgUEAAIABRIEhwECCAoNCgUEAAIAARIE
hwEJDQoNCgUEAAIAAxIEhwEQEQoNCgUEAAIACBIEhwESPAoQCggEAAIACJwIABIEhwETOwp3
CgQEAAIBEgSLAQJLGmkgT3B0aW9uYWwuIFRoZSB1c2VyLXN1cHBsaWVkIGRlc2NyaXB0aW9u
IG9mIHRoZSBWUEMgRmxvdyBMb2dzIGNvbmZpZ3VyYXRpb24uCiBNYXhpbXVtIG9mIDUxMiBj
aGFyYWN0ZXJzLgoKDQoFBAACAQQSBIsBAgoKDQoFBAACAQUSBIsBCxEKDQoFBAACAQESBIsB
Eh0KDQoFBAACAQMSBIsBICEKDQoFBAACAQgSBIsBIkoKEAoIBAACAQicCAASBIsBI0kK4AEK
BAQAAgISBJABAkQa0QEgT3B0aW9uYWwuIFRoZSBzdGF0ZSBvZiB0aGUgVlBDIEZsb3cgTG9n
IGNvbmZpZ3VyYXRpb24uIERlZmF1bHQgdmFsdWUgaXMKIEVOQUJMRUQuIFdoZW4gY3JlYXRp
bmcgYSBuZXcgY29uZmlndXJhdGlvbiwgaXQgbXVzdCBiZSBlbmFibGVkLiBTZXR0aW5nCiBz
dGF0ZT1ESVNBQkxFRCB3aWxsIHBhdXNlIHRoZSBsb2cgZ2VuZXJhdGlvbiBmb3IgdGhpcyBj
b25maWcuCgoNCgUEAAICBBIEkAECCgoNCgUEAAICBhIEkAELEAoNCgUEAAICARIEkAERFgoN
CgUEAAICAxIEkAEZGgoNCgUEAAICCBIEkAEbQwoQCggEAAICCJwIABIEkAEcQgpkCgQEAAID
EgaUAQKVAS8aVCBPcHRpb25hbC4gVGhlIGFnZ3JlZ2F0aW9uIGludGVydmFsIGZvciB0aGUg
bG9ncy4gRGVmYXVsdCB2YWx1ZSBpcwogSU5URVJWQUxfNV9TRUMuCgoNCgUEAAIDBBIElAEC
CgoNCgUEAAIDBhIElAELHgoNCgUEAAIDARIElAEfMwoNCgUEAAIDAxIElAE2NwoNCgUEAAID
CBIElQEGLgoQCggEAAIDCJwIABIElQEHLQqlAgoEBAACBBIEmwECTBqWAiBPcHRpb25hbC4g
VGhlIHZhbHVlIG9mIHRoZSBmaWVsZCBtdXN0IGJlIGluICgwLCAxXS4gVGhlIHNhbXBsaW5n
IHJhdGUgb2YKIFZQQyBGbG93IExvZ3Mgd2hlcmUgMS4wIG1lYW5zIGFsbCBjb2xsZWN0ZWQg
bG9ncyBhcmUgcmVwb3J0ZWQuIFNldHRpbmcgdGhlCiBzYW1wbGluZyByYXRlIHRvIDAuMCBp
cyBub3QgYWxsb3dlZC4gSWYgeW91IHdhbnQgdG8gZGlzYWJsZSBWUEMgRmxvdyBMb2dzLAog
dXNlIHRoZSBzdGF0ZSBmaWVsZCBpbnN0ZWFkLiBEZWZhdWx0IHZhbHVlIGlzIDEuMC4KCg0K
BQQAAgQEEgSbAQIKCg0KBQQAAgQFEgSbAQsQCg0KBQQAAgQBEgSbAREeCg0KBQQAAgQDEgSb
ASEiCg0KBQQAAgQIEgSbASNLChAKCAQAAgQInAgAEgSbASRKCq4BCgQEAAIFEgSgAQJKGp8B
IE9wdGlvbmFsLiBDb25maWd1cmVzIHdoZXRoZXIgYWxsLCBub25lIG9yIGEgc3Vic2V0IG9m
IG1ldGFkYXRhIGZpZWxkcwogc2hvdWxkIGJlIGFkZGVkIHRvIHRoZSByZXBvcnRlZCBWUEMg
ZmxvdyBsb2dzLiBEZWZhdWx0IHZhbHVlIGlzCiBJTkNMVURFX0FMTF9NRVRBREFUQS4KCg0K
BQQAAgUEEgSgAQIKCg0KBQQAAgUGEgSgAQsTCg0KBQQAAgUBEgSgARQcCg0KBQQAAgUDEgSg
AR8gCg0KBQQAAgUIEgSgASFJChAKCAQAAgUInAgAEgSgASJICpwBCgQEAAIGEgSkAQJPGo0B
IE9wdGlvbmFsLiBDdXN0b20gbWV0YWRhdGEgZmllbGRzIHRvIGluY2x1ZGUgaW4gdGhlIHJl
cG9ydGVkIFZQQyBmbG93IGxvZ3MuCiBDYW4gb25seSBiZSBzcGVjaWZpZWQgaWYgIm1ldGFk
YXRhIiB3YXMgc2V0IHRvIENVU1RPTV9NRVRBREFUQS4KCg0KBQQAAgYEEgSkAQIKCg0KBQQA
AgYFEgSkAQsRCg0KBQQAAgYBEgSkARIhCg0KBQQAAgYDEgSkASQlCg0KBQQAAgYIEgSkASZO
ChAKCAQAAgYInAgAEgSkASdNCl0KBAQAAgcSBKgBAksaTyBPcHRpb25hbC4gRXhwb3J0IGZp
bHRlciB1c2VkIHRvIGRlZmluZSB3aGljaCBWUEMgRmxvdyBMb2dzIHNob3VsZCBiZQogbG9n
Z2VkLgoKDQoFBAACBwQSBKgBAgoKDQoFBAACBwUSBKgBCxEKDQoFBAACBwESBKgBEh0KDQoF
BAACBwMSBKgBICEKDQoFBAACBwgSBKgBIkoKEAoIBAACBwicCAASBKgBI0kK8AEKBAQAAggS
Bq0BAq4BLxrfASBPcHRpb25hbC4gRGV0ZXJtaW5lcyB3aGV0aGVyIHRvIGluY2x1ZGUgY3Jv
c3MgcHJvamVjdCBhbm5vdGF0aW9ucyBpbiB0aGUKIGxvZ3MuIFRoaXMgZmllbGQgaXMgYXZh
aWxhYmxlIG9ubHkgZm9yIG9yZ2FuaXphdGlvbiBjb25maWd1cmF0aW9ucy4gSWYgbm90CiBz
cGVjaWZpZWQgaW4gb3JnIGNvbmZpZ3Mgd2lsbCBiZSBzZXQgdG8gQ1JPU1NfUFJPSkVDVF9N
RVRBREFUQV9FTkFCTEVELgoKDQoFBAACCAQSBK0BAgoKDQoFBAACCAYSBK0BCx8KDQoFBAAC
CAESBK0BIDYKDQoFBAACCAMSBK0BOTsKDQoFBAACCAgSBK4BBi4KEAoIBAACCAicCAASBK4B
By0KbgoEBAACCRIGsgECswEyGl4gT3V0cHV0IG9ubHkuIERlc2NyaWJlcyB0aGUgc3RhdGUg
b2YgdGhlIGNvbmZpZ3VyZWQgdGFyZ2V0IHJlc291cmNlIGZvcgogZGlhZ25vc3RpYyBwdXJw
b3Nlcy4KCg0KBQQAAgkEEgSyAQIKCg0KBQQAAgkGEgSyAQseCg0KBQQAAgkBEgSyAR80Cg0K
BQQAAgkDEgSyATc5Cg0KBQQAAgkIEgSzAQYxChAKCAQAAgkInAgAEgSzAQcwCoICCgQEAAgA
Ega5AQLLAQMa8QEgUmVmZXJlbmNlIHRvIHRoZSByZXNvdXJjZSBvZiB0aGUgY29uZmlnIHNj
b3BlLiBUaGF0IGlzLCB0aGUgc2NvcGUgZnJvbQogd2hpY2ggdHJhZmZpYyBpcyBsb2dnZWQu
IFRoZSB0YXJnZXQgcmVzb3VyY2UgbXVzdCBiZWxvbmcgdG8gdGhlIHNhbWUKIHByb2plY3Qg
YXMgdGhlIGNvbmZpZ3VyYXRpb24uCiBUaGlzIGZpZWxkIGlzIG5vdCBzdXBwb3J0ZWQgZm9y
IG9yZ2FuaXphdGlvbiBsZXZlbCBjb25maWd1cmF0aW9ucy4KCg0KBQQACAABEgS5AQgXCqUB
CgQEAAIKEgS9AQQZGpYBIFRyYWZmaWMgd2lsbCBiZSBsb2dnZWQgZnJvbSBWTXMsIFZQTiB0
dW5uZWxzIGFuZCBJbnRlcmNvbm5lY3QgQXR0YWNobWVudHMKIHdpdGhpbiB0aGUgbmV0d29y
ay4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3RfaWR9L2dsb2JhbC9uZXR3b3Jrcy97bmFt
ZX0KCg0KBQQAAgoFEgS9AQQKCg0KBQQAAgoBEgS9AQsSCg0KBQQAAgoDEgS9ARUYCokBCgQE
AAILEgTBAQQYGnsgVHJhZmZpYyB3aWxsIGJlIGxvZ2dlZCBmcm9tIFZNcyB3aXRoaW4gdGhl
IHN1Ym5ldHdvcmsuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0X2lkfS9yZWdpb25zL3ty
ZWdpb259L3N1Ym5ldHdvcmtzL3tuYW1lfQoKDQoFBAACCwUSBMEBBAoKDQoFBAACCwESBMEB
CxEKDQoFBAACCwMSBMEBFBcKmQEKBAQAAgwSBMYBBCkaigEgVHJhZmZpYyB3aWxsIGJlIGxv
Z2dlZCBmcm9tIHRoZSBJbnRlcmNvbm5lY3QgQXR0YWNobWVudC4KIEZvcm1hdDoKIHByb2pl
Y3RzL3twcm9qZWN0X2lkfS9yZWdpb25zL3tyZWdpb259L2ludGVyY29ubmVjdEF0dGFjaG1l
bnRzL3tuYW1lfQoKDQoFBAACDAUSBMYBBAoKDQoFBAACDAESBMYBCyIKDQoFBAACDAMSBMYB
JSgKfQoEBAACDRIEygEEHBpvIFRyYWZmaWMgd2lsbCBiZSBsb2dnZWQgZnJvbSB0aGUgVlBO
IFR1bm5lbC4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3RfaWR9L3JlZ2lvbnMve3JlZ2lv
bn0vdnBuVHVubmVscy97bmFtZX0KCg0KBQQAAg0FEgTKAQQKCg0KBQQAAg0BEgTKAQsVCg0K
BQQAAg0DEgTKARgbCk4KBAQAAg4SBM4BAksaQCBPcHRpb25hbC4gUmVzb3VyY2UgbGFiZWxz
IHRvIHJlcHJlc2VudCB1c2VyLXByb3ZpZGVkIG1ldGFkYXRhLgoKDQoFBAACDgYSBM4BAhUK
DQoFBAACDgESBM4BFhwKDQoFBAACDgMSBM4BHyEKDQoFBAACDggSBM4BIkoKEAoIBAACDgic
CAASBM4BI0kKPwoEBAACDxIG0QEC0gEyGi8gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBj
b25maWcgd2FzIGNyZWF0ZWQuCgoNCgUEAAIPBhIE0QECGwoNCgUEAAIPARIE0QEcJwoNCgUE
AAIPAxIE0QEqKwoNCgUEAAIPCBIE0gEGMQoQCggEAAIPCJwIABIE0gEHMAo/CgQEAAIQEgbV
AQLWATIaLyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIGNvbmZpZyB3YXMgdXBkYXRlZC4K
Cg0KBQQAAhAGEgTVAQIbCg0KBQQAAhABEgTVARwnCg0KBQQAAhADEgTVASosCg0KBQQAAhAI
EgTWAQYxChAKCAQAAhAInAgAEgTWAQcwCmIKAgQBEgbbAQC8AgEaVCBBIGNvbmZpZ3VyYXRp
b24gdG8gZ2VuZXJhdGUgYSByZXNwb25zZSBmb3IgR2V0RWZmZWN0aXZlVnBjRmxvd0xvZ3ND
b25maWcKIHJlcXVlc3QuCgoLCgMEAQESBNsBCCIKPAoEBAEEABIG3QEC8wEDGiwgVGhlIHNj
b3BlIGZvciB0aGlzIGZsb3cgbG9nIGNvbmZpZ3VyYXRpb24uCgoNCgUEAQQAARIE3QEHDAon
CgYEAQQAAgASBN8BBBoaFyBTY29wZSBpcyB1bnNwZWNpZmllZC4KCg8KBwQBBAACAAESBN8B
BBUKDwoHBAEEAAIAAhIE3wEYGQpHCgYEAQQAAgESBOIBBA8aNyBUYXJnZXQgcmVzb3VyY2Ug
aXMgYSBzdWJuZXQgKE5ldHdvcmsgTWFuYWdlbWVudCBBUEkpLgoKDwoHBAEEAAIBARIE4gEE
CgoPCgcEAQQAAgECEgTiAQ0OCl8KBgQBBAACAhIE5gEEGxpPIFRhcmdldCByZXNvdXJjZSBp
cyBhIHN1Ym5ldCwgYW5kIHRoZSBjb25maWcgb3JpZ2luYXRlcyBmcm9tIHRoZSBDb21wdXRl
CiBBUEkuCgoPCgcEAQQAAgIBEgTmAQQWCg8KBwQBBAACAgISBOYBGRoKLwoGBAEEAAIDEgTp
AQQQGh8gVGFyZ2V0IHJlc291cmNlIGlzIGEgbmV0d29yay4KCg8KBwQBBAACAwESBOkBBAsK
DwoHBAEEAAIDAhIE6QEODwoyCgYEAQQAAgQSBOwBBBMaIiBUYXJnZXQgcmVzb3VyY2UgaXMg
YSBWUE4gdHVubmVsLgoKDwoHBAEEAAIEARIE7AEEDgoPCgcEAQQAAgQCEgTsARESCkAKBgQB
BAACBRIE7wEEIBowIFRhcmdldCByZXNvdXJjZSBpcyBhbiBpbnRlcmNvbm5lY3QgYXR0YWNo
bWVudC4KCg8KBwQBBAACBQESBO8BBBsKDwoHBAEEAAIFAhIE7wEeHwpCCgYEAQQAAgYSBPIB
BBUaMiBDb25maWd1cmF0aW9uIGFwcGxpZXMgdG8gYW4gZW50aXJlIG9yZ2FuaXphdGlvbi4K
Cg8KBwQBBAACBgESBPIBBBAKDwoHBAEEAAIGAhIE8gETFArvAwoEBAECABIEgAICEhrgAyBV
bmlxdWUgbmFtZSBvZiB0aGUgY29uZmlndXJhdGlvbi4gVGhlIG5hbWUgY2FuIGhhdmUgb25l
IG9mIHRoZSBmb2xsb3dpbmcKIGZvcm1zOgoKIC0gRm9yIHByb2plY3QtbGV2ZWwgY29uZmln
dXJhdGlvbnM6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvdnBj
Rmxvd0xvZ3NDb25maWdzL3t2cGNfZmxvd19sb2dzX2NvbmZpZ19pZH1gCgogLSBGb3Igb3Jn
YW5pemF0aW9uLWxldmVsIGNvbmZpZ3VyYXRpb25zOgogYG9yZ2FuaXphdGlvbnMve29yZ2Fu
aXphdGlvbl9pZH0vbG9jYXRpb25zL2dsb2JhbC92cGNGbG93TG9nc0NvbmZpZ3Mve3ZwY19m
bG93X2xvZ3NfY29uZmlnX2lkfWAKCiAtIEZvciBhIENvbXB1dGUgY29uZmlnLCB0aGUgbmFt
ZSB3aWxsIGJlIHRoZSBwYXRoIG9mIHRoZSBzdWJuZXQ6CiBgcHJvamVjdHMve3Byb2plY3Rf
aWR9L3JlZ2lvbnMve3JlZ2lvbn0vc3VibmV0d29ya3Mve3N1Ym5ldF9pZH1gCgoNCgUEAQIA
BRIEgAICCAoNCgUEAQIAARIEgAIJDQoNCgUEAQIAAxIEgAIQEQrWAQoEBAECARIEhQICLRrH
ASBUaGUgc3RhdGUgb2YgdGhlIFZQQyBGbG93IExvZyBjb25maWd1cmF0aW9uLiBEZWZhdWx0
IHZhbHVlIGlzIEVOQUJMRUQuCiBXaGVuIGNyZWF0aW5nIGEgbmV3IGNvbmZpZ3VyYXRpb24s
IGl0IG11c3QgYmUgZW5hYmxlZC4KIFNldHRpbmcgc3RhdGU9RElTQUJMRUQgd2lsbCBwYXVz
ZSB0aGUgbG9nIGdlbmVyYXRpb24gZm9yIHRoaXMgY29uZmlnLgoKDQoFBAECAQQSBIUCAgoK
DQoFBAECAQYSBIUCCyIKDQoFBAECAQESBIUCIygKDQoFBAECAQMSBIUCKywKVwoEBAECAhIE
iAICShpJIFRoZSBhZ2dyZWdhdGlvbiBpbnRlcnZhbCBmb3IgdGhlIGxvZ3MuIERlZmF1bHQg
dmFsdWUgaXMgSU5URVJWQUxfNV9TRUMuCgoNCgUEAQICBBIEiAICCgoNCgUEAQICBhIEiAIL
MAoNCgUEAQICARIEiAIxRQoNCgUEAQICAxIEiAJISQqcAgoEBAECAxIEjwICIxqNAiBUaGUg
dmFsdWUgb2YgdGhlIGZpZWxkIG11c3QgYmUgaW4gKDAsIDFdLiBUaGUgc2FtcGxpbmcgcmF0
ZSBvZiBWUEMgRmxvdwogTG9ncyB3aGVyZSAxLjAgbWVhbnMgYWxsIGNvbGxlY3RlZCBsb2dz
IGFyZSByZXBvcnRlZC4KIFNldHRpbmcgdGhlIHNhbXBsaW5nIHJhdGUgdG8gMC4wIGlzIG5v
dCBhbGxvd2VkLiBJZiB5b3Ugd2FudCB0byBkaXNhYmxlIFZQQwogRmxvdyBMb2dzLCB1c2Ug
dGhlIHN0YXRlIGZpZWxkIGluc3RlYWQuCiBEZWZhdWx0IHZhbHVlIGlzIDEuMC4KCg0KBQQB
AgMEEgSPAgIKCg0KBQQBAgMFEgSPAgsQCg0KBQQBAgMBEgSPAhEeCg0KBQQBAgMDEgSPAiEi
CqQBCgQEAQIEEgSUAgIzGpUBIENvbmZpZ3VyZXMgd2hldGhlciBhbGwsIG5vbmUgb3IgYSBz
dWJzZXQgb2YgbWV0YWRhdGEgZmllbGRzIHNob3VsZCBiZQogYWRkZWQgdG8gdGhlIHJlcG9y
dGVkIFZQQyBmbG93IGxvZ3MuCiBEZWZhdWx0IHZhbHVlIGlzIElOQ0xVREVfQUxMX01FVEFE
QVRBLgoKDQoFBAECBAQSBJQCAgoKDQoFBAECBAYSBJQCCyUKDQoFBAECBAESBJQCJi4KDQoF
BAECBAMSBJQCMTIKkgEKBAQBAgUSBJgCAiYagwEgQ3VzdG9tIG1ldGFkYXRhIGZpZWxkcyB0
byBpbmNsdWRlIGluIHRoZSByZXBvcnRlZCBWUEMgZmxvdyBsb2dzLgogQ2FuIG9ubHkgYmUg
c3BlY2lmaWVkIGlmICJtZXRhZGF0YSIgd2FzIHNldCB0byBDVVNUT01fTUVUQURBVEEuCgoN
CgUEAQIFBBIEmAICCgoNCgUEAQIFBRIEmAILEQoNCgUEAQIFARIEmAISIQoNCgUEAQIFAxIE
mAIkJQpSCgQEAQIGEgSbAgIiGkQgRXhwb3J0IGZpbHRlciB1c2VkIHRvIGRlZmluZSB3aGlj
aCBWUEMgRmxvdyBMb2dzIHNob3VsZCBiZSBsb2dnZWQuCgoNCgUEAQIGBBIEmwICCgoNCgUE
AQIGBRIEmwILEQoNCgUEAQIGARIEmwISHQoNCgUEAQIGAxIEmwIgIQrkAQoEBAECBxIEoAIC
ThrVASBEZXRlcm1pbmVzIHdoZXRoZXIgdG8gaW5jbHVkZSBjcm9zcyBwcm9qZWN0IGFubm90
YXRpb25zIGluIHRoZSBsb2dzLgogVGhpcyBmaWVsZCBpcyBhdmFpbGFibGUgb25seSBmb3Ig
b3JnYW5pemF0aW9uIGNvbmZpZ3VyYXRpb25zLiBJZiBub3QKIHNwZWNpZmllZCBpbiBvcmcg
Y29uZmlncyB3aWxsIGJlIHNldCB0byBDUk9TU19QUk9KRUNUX01FVEFEQVRBX0VOQUJMRUQu
CgoNCgUEAQIHBBIEoAICCgoNCgUEAQIHBhIEoAILMQoNCgUEAQIHARIEoAIySAoNCgUEAQIH
AxIEoAJLTQqCAgoEBAEIABIGpgICuAIDGvEBIFJlZmVyZW5jZSB0byB0aGUgcmVzb3VyY2Ug
b2YgdGhlIGNvbmZpZyBzY29wZS4gVGhhdCBpcywgdGhlIHNjb3BlIGZyb20KIHdoaWNoIHRy
YWZmaWMgaXMgbG9nZ2VkLiBUaGUgdGFyZ2V0IHJlc291cmNlIG11c3QgYmVsb25nIHRvIHRo
ZSBzYW1lCiBwcm9qZWN0IGFzIHRoZSBjb25maWd1cmF0aW9uLgogVGhpcyBmaWVsZCBpcyBu
b3Qgc3VwcG9ydGVkIGZvciBvcmdhbml6YXRpb24gbGV2ZWwgY29uZmlndXJhdGlvbnMuCgoN
CgUEAQgAARIEpgIIFwqlAQoEBAECCBIEqgIEGRqWASBUcmFmZmljIHdpbGwgYmUgbG9nZ2Vk
IGZyb20gVk1zLCBWUE4gdHVubmVscyBhbmQgSW50ZXJjb25uZWN0IEF0dGFjaG1lbnRzCiB3
aXRoaW4gdGhlIG5ldHdvcmsuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0X2lkfS9nbG9i
YWwvbmV0d29ya3Mve25hbWV9CgoNCgUEAQIIBRIEqgIECgoNCgUEAQIIARIEqgILEgoNCgUE
AQIIAxIEqgIVGAqJAQoEBAECCRIErgIEGBp7IFRyYWZmaWMgd2lsbCBiZSBsb2dnZWQgZnJv
bSBWTXMgd2l0aGluIHRoZSBzdWJuZXR3b3JrLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVj
dF9pZH0vcmVnaW9ucy97cmVnaW9ufS9zdWJuZXR3b3Jrcy97bmFtZX0KCg0KBQQBAgkFEgSu
AgQKCg0KBQQBAgkBEgSuAgsRCg0KBQQBAgkDEgSuAhQXCpkBCgQEAQIKEgSzAgQpGooBIFRy
YWZmaWMgd2lsbCBiZSBsb2dnZWQgZnJvbSB0aGUgSW50ZXJjb25uZWN0IEF0dGFjaG1lbnQu
CiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdF9pZH0vcmVnaW9ucy97cmVnaW9ufS9pbnRl
cmNvbm5lY3RBdHRhY2htZW50cy97bmFtZX0KCg0KBQQBAgoFEgSzAgQKCg0KBQQBAgoBEgSz
AgsiCg0KBQQBAgoDEgSzAiUoCn0KBAQBAgsSBLcCBBwabyBUcmFmZmljIHdpbGwgYmUgbG9n
Z2VkIGZyb20gdGhlIFZQTiBUdW5uZWwuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0X2lk
fS9yZWdpb25zL3tyZWdpb259L3ZwblR1bm5lbHMve25hbWV9CgoNCgUEAQILBRIEtwIECgoN
CgUEAQILARIEtwILFQoNCgUEAQILAxIEtwIYGwpaCgQEAQIMEgS7AgIcGkwgU3BlY2lmaWVz
IHRoZSBzY29wZSBvZiB0aGUgY29uZmlnIChlLmcuLCBTVUJORVQsIE5FVFdPUkssIE9SR0FO
SVpBVElPTi4uKS4KCg0KBQQBAgwEEgS7AgIKCg0KBQQBAgwGEgS7AgsQCg0KBQQBAgwBEgS7
AhEWCg0KBQQBAgwDEgS7AhkbYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig ===
    # Fields for VpcFlowLogsConfig
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.State)
    # Field: aggregation_interval Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.AggregationInterval)
    # Field: flow_sampling Type: 2 ()
    # Field: metadata Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.Metadata)
    # Field: metadata_fields Type: 9 ()
    # Field: filter_expr Type: 9 ()
    # Field: cross_project_metadata Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.CrossProjectMetadata)
    # Field: target_resource_state Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.TargetResourceState)
    # Field: network Type: 9 ()
    # Field: subnet Type: 9 ()
    # Field: interconnect_attachment Type: 9 ()
    # Field: vpn_tunnel Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: VpcFlowLogsConfig::State
our $VpcFlowLogsConfig_STATE_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_ENABLED = 1;
our $VpcFlowLogsConfig_DISABLED = 2;

# Enum: VpcFlowLogsConfig::AggregationInterval
our $VpcFlowLogsConfig_AGGREGATION_INTERVAL_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_INTERVAL_5_SEC = 1;
our $VpcFlowLogsConfig_INTERVAL_30_SEC = 2;
our $VpcFlowLogsConfig_INTERVAL_1_MIN = 3;
our $VpcFlowLogsConfig_INTERVAL_5_MIN = 4;
our $VpcFlowLogsConfig_INTERVAL_10_MIN = 5;
our $VpcFlowLogsConfig_INTERVAL_15_MIN = 6;

# Enum: VpcFlowLogsConfig::Metadata
our $VpcFlowLogsConfig_METADATA_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_INCLUDE_ALL_METADATA = 1;
our $VpcFlowLogsConfig_EXCLUDE_ALL_METADATA = 2;
our $VpcFlowLogsConfig_CUSTOM_METADATA = 3;

# Enum: VpcFlowLogsConfig::CrossProjectMetadata
our $VpcFlowLogsConfig_CROSS_PROJECT_METADATA_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_CROSS_PROJECT_METADATA_ENABLED = 1;
our $VpcFlowLogsConfig_CROSS_PROJECT_METADATA_DISABLED = 2;

# Enum: VpcFlowLogsConfig::TargetResourceState
our $VpcFlowLogsConfig_TARGET_RESOURCE_STATE_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_TARGET_RESOURCE_EXISTS = 1;
our $VpcFlowLogsConfig_TARGET_RESOURCE_DOES_NOT_EXIST = 2;

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig ===
    # Fields for EffectiveVpcFlowLogsConfig
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.State)
    # Field: aggregation_interval Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.AggregationInterval)
    # Field: flow_sampling Type: 2 ()
    # Field: metadata Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.Metadata)
    # Field: metadata_fields Type: 9 ()
    # Field: filter_expr Type: 9 ()
    # Field: cross_project_metadata Type: 14 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig.CrossProjectMetadata)
    # Field: network Type: 9 ()
    # Field: subnet Type: 9 ()
    # Field: interconnect_attachment Type: 9 ()
    # Field: vpn_tunnel Type: 9 ()
    # Field: scope Type: 14 (.google.cloud.networkmanagement.v1.EffectiveVpcFlowLogsConfig.Scope)

# Enum: EffectiveVpcFlowLogsConfig::Scope
our $EffectiveVpcFlowLogsConfig_SCOPE_UNSPECIFIED = 0;
our $EffectiveVpcFlowLogsConfig_SUBNET = 1;
our $EffectiveVpcFlowLogsConfig_COMPUTE_API_SUBNET = 2;
our $EffectiveVpcFlowLogsConfig_NETWORK = 3;
our $EffectiveVpcFlowLogsConfig_VPN_TUNNEL = 4;
our $EffectiveVpcFlowLogsConfig_INTERCONNECT_ATTACHMENT = 5;
our $EffectiveVpcFlowLogsConfig_ORGANIZATION = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig - Compiled Protocol Buffers messages for google/cloud/networkmanagement/v1/vpc_flow_logs_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig;

    my $msg = Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig->new({
        name => $name,
        description => $description,
        state => $state,
        aggregation_interval => $aggregation_interval,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkmanagement/v1/vpc_flow_logs_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig

A configuration to generate VPC Flow Logs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Unique name of the configuration. The name can have one of the
following forms:

- For project-level configurations:
`projects/{project_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For organization-level configurations:
`organizations/{organization_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The user-supplied description of the VPC Flow Logs configuration.
Maximum of 512 characters.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::State>)

Optional. The state of the VPC Flow Log configuration. Default value is
ENABLED. When creating a new configuration, it must be enabled. Setting
state=DISABLED will pause the log generation for this config.

=item * C<< $msg->aggregation_interval() >> / C<< $msg->aggregation_interval($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::AggregationInterval>)

Optional. The aggregation interval for the logs. Default value is
INTERVAL_5_SEC.

=item * C<< $msg->flow_sampling() >> / C<< $msg->flow_sampling($value) >>

Type: C<Float>

Optional. The value of the field must be in (0, 1]. The sampling rate of
VPC Flow Logs where 1.0 means all collected logs are reported. Setting the
sampling rate to 0.0 is not allowed. If you want to disable VPC Flow Logs,
use the state field instead. Default value is 1.0.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::Metadata>)

Optional. Configures whether all, none or a subset of metadata fields
should be added to the reported VPC flow logs. Default value is
INCLUDE_ALL_METADATA.

=item * C<< $msg->metadata_fields() >> / C<< $msg->metadata_fields($value) >>

Type: C<String>

Optional. Custom metadata fields to include in the reported VPC flow logs.
Can only be specified if "metadata" was set to CUSTOM_METADATA.

=item * C<< $msg->filter_expr() >> / C<< $msg->filter_expr($value) >>

Type: C<String>

Optional. Export filter used to define which VPC Flow Logs should be
logged.

=item * C<< $msg->cross_project_metadata() >> / C<< $msg->cross_project_metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::CrossProjectMetadata>)

Optional. Determines whether to include cross project annotations in the
logs. This field is available only for organization configurations. If not
specified in org configs will be set to CROSS_PROJECT_METADATA_ENABLED.

=item * C<< $msg->target_resource_state() >> / C<< $msg->target_resource_state($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::TargetResourceState>)

Output only. Describes the state of the configured target resource for
diagnostic purposes.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Traffic will be logged from VMs, VPN tunnels and Interconnect Attachments
within the network.
Format: projects/{project_id}/global/networks/{name}

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<String>

Traffic will be logged from VMs within the subnetwork.
Format: projects/{project_id}/regions/{region}/subnetworks/{name}

=item * C<< $msg->interconnect_attachment() >> / C<< $msg->interconnect_attachment($value) >>

Type: C<String>

Traffic will be logged from the Interconnect Attachment.
Format:
projects/{project_id}/regions/{region}/interconnectAttachments/{name}

=item * C<< $msg->vpn_tunnel() >> / C<< $msg->vpn_tunnel($value) >>

Type: C<String>

Traffic will be logged from the VPN Tunnel.
Format: projects/{project_id}/regions/{region}/vpnTunnels/{name}

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig::LabelsEntry>)

Optional. Resource labels to represent user-provided metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the config was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the config was updated.

=back

=head3 Enum: VpcFlowLogsConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head3 Enum: VpcFlowLogsConfig::AggregationInterval

=over 4

=item * C<AGGREGATION_INTERVAL_UNSPECIFIED> => C<0>

=item * C<INTERVAL_5_SEC> => C<1>

=item * C<INTERVAL_30_SEC> => C<2>

=item * C<INTERVAL_1_MIN> => C<3>

=item * C<INTERVAL_5_MIN> => C<4>

=item * C<INTERVAL_10_MIN> => C<5>

=item * C<INTERVAL_15_MIN> => C<6>

=back

=head3 Enum: VpcFlowLogsConfig::Metadata

=over 4

=item * C<METADATA_UNSPECIFIED> => C<0>

=item * C<INCLUDE_ALL_METADATA> => C<1>

=item * C<EXCLUDE_ALL_METADATA> => C<2>

=item * C<CUSTOM_METADATA> => C<3>

=back

=head3 Enum: VpcFlowLogsConfig::CrossProjectMetadata

=over 4

=item * C<CROSS_PROJECT_METADATA_UNSPECIFIED> => C<0>

=item * C<CROSS_PROJECT_METADATA_ENABLED> => C<1>

=item * C<CROSS_PROJECT_METADATA_DISABLED> => C<2>

=back

=head3 Enum: VpcFlowLogsConfig::TargetResourceState

=over 4

=item * C<TARGET_RESOURCE_STATE_UNSPECIFIED> => C<0>

=item * C<TARGET_RESOURCE_EXISTS> => C<1>

=item * C<TARGET_RESOURCE_DOES_NOT_EXIST> => C<2>

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig

A configuration to generate a response for GetEffectiveVpcFlowLogsConfig
request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Unique name of the configuration. The name can have one of the following
forms:

- For project-level configurations:
`projects/{project_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For organization-level configurations:
`organizations/{organization_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For a Compute config, the name will be the path of the subnet:
`projects/{project_id}/regions/{region}/subnetworks/{subnet_id}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::State>)

The state of the VPC Flow Log configuration. Default value is ENABLED.
When creating a new configuration, it must be enabled.
Setting state=DISABLED will pause the log generation for this config.

=item * C<< $msg->aggregation_interval() >> / C<< $msg->aggregation_interval($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::AggregationInterval>)

The aggregation interval for the logs. Default value is INTERVAL_5_SEC.

=item * C<< $msg->flow_sampling() >> / C<< $msg->flow_sampling($value) >>

Type: C<Float>

The value of the field must be in (0, 1]. The sampling rate of VPC Flow
Logs where 1.0 means all collected logs are reported.
Setting the sampling rate to 0.0 is not allowed. If you want to disable VPC
Flow Logs, use the state field instead.
Default value is 1.0.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::Metadata>)

Configures whether all, none or a subset of metadata fields should be
added to the reported VPC flow logs.
Default value is INCLUDE_ALL_METADATA.

=item * C<< $msg->metadata_fields() >> / C<< $msg->metadata_fields($value) >>

Type: C<String>

Custom metadata fields to include in the reported VPC flow logs.
Can only be specified if "metadata" was set to CUSTOM_METADATA.

=item * C<< $msg->filter_expr() >> / C<< $msg->filter_expr($value) >>

Type: C<String>

Export filter used to define which VPC Flow Logs should be logged.

=item * C<< $msg->cross_project_metadata() >> / C<< $msg->cross_project_metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::CrossProjectMetadata>)

Determines whether to include cross project annotations in the logs.
This field is available only for organization configurations. If not
specified in org configs will be set to CROSS_PROJECT_METADATA_ENABLED.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Traffic will be logged from VMs, VPN tunnels and Interconnect Attachments
within the network.
Format: projects/{project_id}/global/networks/{name}

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<String>

Traffic will be logged from VMs within the subnetwork.
Format: projects/{project_id}/regions/{region}/subnetworks/{name}

=item * C<< $msg->interconnect_attachment() >> / C<< $msg->interconnect_attachment($value) >>

Type: C<String>

Traffic will be logged from the Interconnect Attachment.
Format:
projects/{project_id}/regions/{region}/interconnectAttachments/{name}

=item * C<< $msg->vpn_tunnel() >> / C<< $msg->vpn_tunnel($value) >>

Type: C<String>

Traffic will be logged from the VPN Tunnel.
Format: projects/{project_id}/regions/{region}/vpnTunnels/{name}

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1::EffectiveVpcFlowLogsConfig::Scope>)

Specifies the scope of the config (e.g., SUBNET, NETWORK, ORGANIZATION..).

=back

=head3 Enum: EffectiveVpcFlowLogsConfig::Scope

=over 4

=item * C<SCOPE_UNSPECIFIED> => C<0>

=item * C<SUBNET> => C<1>

=item * C<COMPUTE_API_SUBNET> => C<2>

=item * C<NETWORK> => C<3>

=item * C<VPN_TUNNEL> => C<4>

=item * C<INTERCONNECT_ATTACHMENT> => C<5>

=item * C<ORGANIZATION> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
