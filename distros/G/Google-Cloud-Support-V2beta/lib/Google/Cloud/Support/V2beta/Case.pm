package Google::Cloud::Support::V2beta::Case;

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
    eval { require Google::Cloud::Support::V2beta::Actor };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvY2FzZS5wcm90bxIbZ29vZ2xlLmNsb3Vk
LnN1cHBvcnQudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvYWN0
b3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8irQgKBENhc2USFwoE
bmFtZRgBIAEoCUID4EEIUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5h
bWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uElcKDmNsYXNzaWZpY2F0aW9u
GAQgASgLMi8uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLkNhc2VDbGFzc2lmaWNhdGlv
blIOY2xhc3NpZmljYXRpb24SGwoJdGltZV96b25lGAggASgJUgh0aW1lWm9uZRI8ChpzdWJz
Y3JpYmVyX2VtYWlsX2FkZHJlc3NlcxgJIAMoCVIYc3Vic2NyaWJlckVtYWlsQWRkcmVzc2Vz
EkIKBXN0YXRlGAwgASgOMicuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLkNhc2UuU3Rh
dGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUYDSABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYDiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSPAoHY3JlYXRvchgPIAEo
CzIiLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5BY3RvclIHY3JlYXRvchIjCg1jb250
YWN0X2VtYWlsGCMgASgJUgxjb250YWN0RW1haWwSHAoJZXNjYWxhdGVkGBEgASgIUgllc2Nh
bGF0ZWQSGwoJdGVzdF9jYXNlGBMgASgIUgh0ZXN0Q2FzZRIjCg1sYW5ndWFnZV9jb2RlGBcg
ASgJUgxsYW5ndWFnZUNvZGUSRgoIcHJpb3JpdHkYICABKA4yKi5nb29nbGUuY2xvdWQuc3Vw
cG9ydC52MmJldGEuQ2FzZS5Qcmlvcml0eVIIcHJpb3JpdHkifwoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIHCgNORVcQARIeChpJTl9QUk9HUkVTU19HT09HTEVfU1VQUE9SVBAC
EhMKD0FDVElPTl9SRVFVSVJFRBADEhUKEVNPTFVUSU9OX1BST1ZJREVEEAQSCgoGQ0xPU0VE
EAUiTAoIUHJpb3JpdHkSGAoUUFJJT1JJVFlfVU5TUEVDSUZJRUQQABIGCgJQMBABEgYKAlAx
EAISBgoCUDIQAxIGCgJQMxAEEgYKAlA0EAU6cepBbgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFw
aXMuY29tL0Nhc2USKW9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vY2FzZXMve2Nhc2V9
Eh9wcm9qZWN0cy97cHJvamVjdH0vY2FzZXMve2Nhc2V9IocBChJDYXNlQ2xhc3NpZmljYXRp
b24SDgoCaWQYAyABKAlSAmlkEiEKDGRpc3BsYXlfbmFtZRgEIAEoCVILZGlzcGxheU5hbWUS
PgoHcHJvZHVjdBgKIAEoCzIkLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5Qcm9kdWN0
Ugdwcm9kdWN0IlYKB1Byb2R1Y3QSSwoMcHJvZHVjdF9saW5lGAEgASgOMiguZ29vZ2xlLmNs
b3VkLnN1cHBvcnQudjJiZXRhLlByb2R1Y3RMaW5lUgtwcm9kdWN0TGluZSpOCgtQcm9kdWN0
TGluZRIcChhQUk9EVUNUX0xJTkVfVU5TUEVDSUZJRUQQABIQCgxHT09HTEVfQ0xPVUQQARIP
CgtHT09HTEVfTUFQUxACQsYBCh9jb20uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhQglD
YXNlUHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2FwaXYyYmV0YS9zdXBw
b3J0cGI7c3VwcG9ydHBiqgIbR29vZ2xlLkNsb3VkLlN1cHBvcnQuVjJCZXRhygIbR29vZ2xl
XENsb3VkXFN1cHBvcnRcVjJiZXRh6gIeR29vZ2xlOjpDbG91ZDo6U3VwcG9ydDo6VjJiZXRh
Suo4CgcSBQ4A2QEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAkCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAxCgkKAgMDEgMVACkKCAoBCBID
FwA4CgkKAgglEgMXADgKCAoBCBIDGABQCgkKAggLEgMYAFAKCAoBCBIDGQAiCgkKAggKEgMZ
ACIKCAoBCBIDGgAqCgkKAggIEgMaACoKCAoBCBIDGwA4CgkKAggBEgMbADgKCAoBCBIDHAA4
CgkKAggpEgMcADgKCAoBCBIDHQA3CgkKAggtEgMdADcKRQoCBQASBCAAKQEaOSBUaGUgcHJv
ZHVjdCBsaW5lIGEgc3VwcG9ydCBjYXNlIG1heSBiZSBhc3NvY2lhdGVkIHdpdGguCgoKCgMF
AAESAyAFEAokCgQFAAIAEgMiAh8aFyBVbmtub3duIHByb2R1Y3QgdHlwZS4KCgwKBQUAAgAB
EgMiAhoKDAoFBQACAAISAyIdHgobCgQFAAIBEgMlAhMaDiBHb29nbGUgQ2xvdWQKCgwKBQUA
AgEBEgMlAg4KDAoFBQACAQISAyUREgoaCgQFAAICEgMoAhIaDSBHb29nbGUgTWFwcwoKDAoF
BQACAgESAygCDQoMCgUFAAICAhIDKBARCv8FCgIEABIFRgC3AQEa8QUgQSBDYXNlIGlzIGFu
IG9iamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBkZXRhaWxzIG9mIGEgc3VwcG9ydCBjYXNlLiBJ
dAogY29udGFpbnMgZmllbGRzIGZvciB0aGUgdGltZSBpdCB3YXMgY3JlYXRlZCwgaXRzIHBy
aW9yaXR5LCBpdHMKIGNsYXNzaWZpY2F0aW9uLCBhbmQgbW9yZS4gQ2FzZXMgY2FuIGFsc28g
aGF2ZSBjb21tZW50cyBhbmQgYXR0YWNobWVudHMgdGhhdAogZ2V0IGFkZGVkIG92ZXIgdGlt
ZS4KCiBBIGNhc2UgaXMgcGFyZW50ZWQgYnkgYSBHb29nbGUgQ2xvdWQgb3JnYW5pemF0aW9u
IG9yIHByb2plY3QuCgogT3JnYW5pemF0aW9ucyBhcmUgaWRlbnRpZmllZCBieSBhIG51bWJl
ciwgc28gdGhlIG5hbWUgb2YgYSBjYXNlIHBhcmVudGVkIGJ5CiBhbiBvcmdhbml6YXRpb24g
d291bGQgbG9vayBsaWtlIHRoaXM6CgogYGBgCiBvcmdhbml6YXRpb25zLzEyMy9jYXNlcy80
NTYKIGBgYAoKIFByb2plY3RzIGhhdmUgdHdvIHVuaXF1ZSBpZGVudGlmaWVycywgYW4gSUQg
YW5kIGEgbnVtYmVyLCBhbmQgdGhleSBsb29rIGxpa2UKIHRoaXM6CgogYGBgCiBwcm9qZWN0
cy9hYmMvY2FzZXMvNDU2CiBgYGAKCiBgYGAKIHByb2plY3RzLzEyMy9jYXNlcy80NTYKIGBg
YAoKIFlvdSBjYW4gdXNlIGVpdGhlciBvZiB0aGVtIHdoZW4gY2FsbGluZyB0aGUgQVBJLiBU
byBsZWFybiBtb3JlCiBhYm91dCBwcm9qZWN0IGlkZW50aWZpZXJzLCBzZWUgW0FJUC0yNTEw
XShodHRwczovL2dvb2dsZS5haXAuZGV2L2Nsb3VkLzI1MTApLgoKCgoDBAABEgNGCAwKCwoD
BAAHEgRHAksECg0KBQQAB50IEgRHAksECi0KBAQABAASBE4CYAMaHyBUaGUgc3RhdHVzIG9m
IGEgc3VwcG9ydCBjYXNlLgoKDAoFBAAEAAESA04HDAotCgYEAAQAAgASA1AEGhoeIENhc2Ug
aXMgaW4gYW4gdW5rbm93biBzdGF0ZS4KCg4KBwQABAACAAESA1AEFQoOCgcEAAQAAgACEgNQ
GBkKVAoGBAAEAAIBEgNTBAwaRSBUaGUgY2FzZSBoYXMgYmVlbiBjcmVhdGVkIGJ1dCBubyBv
bmUgaXMgYXNzaWduZWQgdG8gd29yayBvbiBpdCB5ZXQuCgoOCgcEAAQAAgEBEgNTBAcKDgoH
BAAEAAIBAhIDUwoLCkcKBgQABAACAhIDVgQjGjggVGhlIGNhc2UgaXMgY3VycmVudGx5IGJl
aW5nIGhhbmRsZWQgYnkgR29vZ2xlIHN1cHBvcnQuCgoOCgcEAAQAAgIBEgNWBB4KDgoHBAAE
AAICAhIDViEiCjIKBgQABAACAxIDWQQYGiMgR29vZ2xlIGlzIHdhaXRpbmcgZm9yIGEgcmVz
cG9uc2UuCgoOCgcEAAQAAgMBEgNZBBMKDgoHBAAEAAIDAhIDWRYXClMKBgQABAACBBIDXAQa
GkQgQSBzb2x1dGlvbiBoYXMgYmVlbiBvZmZlcmVkIGZvciB0aGUgY2FzZSwgYnV0IGl0IGlz
bid0IHlldCBjbG9zZWQuCgoOCgcEAAQAAgQBEgNcBBUKDgoHBAAEAAIEAhIDXBgZCiwKBgQA
BAACBRIDXwQPGh0gVGhlIGNhc2UgaGFzIGJlZW4gcmVzb2x2ZWQuCgoOCgcEAAQAAgUBEgNf
BAoKDgoHBAAEAAIFAhIDXw0OCkYKBAQABAESBGMCeAMaOCBUaGUgY2FzZSBQcmlvcml0eS4g
UDAgaXMgbW9zdCB1cmdlbnQgYW5kIFA0IHRoZSBsZWFzdC4KCgwKBQQABAEBEgNjBw8KPwoG
BAAEAQIAEgNlBB0aMCBQcmlvcml0eSBpcyB1bmRlZmluZWQgb3IgaGFzIG5vdCBiZWVuIHNl
dCB5ZXQuCgoOCgcEAAQBAgABEgNlBBgKDgoHBAAEAQIAAhIDZRscCk4KBgQABAECARIDaAQL
Gj8gRXh0cmVtZSBpbXBhY3Qgb24gYSBwcm9kdWN0aW9uIHNlcnZpY2UuIFNlcnZpY2UgaXMg
aGFyZCBkb3duLgoKDgoHBAAEAQIBARIDaAQGCg4KBwQABAECAQISA2gJCgpYCgYEAAQBAgIS
A2sECxpJIENyaXRpY2FsIGltcGFjdCBvbiBhIHByb2R1Y3Rpb24gc2VydmljZS4gU2Vydmlj
ZSBpcyBjdXJyZW50bHkgdW51c2FibGUuCgoOCgcEAAQBAgIBEgNrBAYKDgoHBAAEAQICAhID
awkKCmAKBgQABAECAxIDbwQLGlEgU2V2ZXJlIGltcGFjdCBvbiBhIHByb2R1Y3Rpb24gc2Vy
dmljZS4gU2VydmljZSBpcyB1c2FibGUgYnV0IGdyZWF0bHkKIGltcGFpcmVkLgoKDgoHBAAE
AQIDARIDbwQGCg4KBwQABAECAwISA28JCgpoCgYEAAQBAgQSA3MECxpZIE1lZGl1bSBpbXBh
Y3Qgb24gYSBwcm9kdWN0aW9uIHNlcnZpY2UuICBTZXJ2aWNlIGlzIGF2YWlsYWJsZSwgYnV0
CiBtb2RlcmF0ZWx5IGltcGFpcmVkLgoKDgoHBAAEAQIEARIDcwQGCg4KBwQABAECBAISA3MJ
CgpcCgYEAAQBAgUSA3cECxpNIEdlbmVyYWwgcXVlc3Rpb25zIG9yIG1pbm9yIGlzc3Vlcy4g
IFByb2R1Y3Rpb24gc2VydmljZSBpcyBmdWxseQogYXZhaWxhYmxlLgoKDgoHBAAEAQIFARID
dwQGCg4KBwQABAECBQISA3cJCgo6CgQEAAIAEgN7Aj0aLSBJZGVudGlmaWVyLiBUaGUgcmVz
b3VyY2UgbmFtZSBmb3IgdGhlIGNhc2UuCgoMCgUEAAIABRIDewIICgwKBQQAAgABEgN7CQ0K
DAoFBAACAAMSA3sQEQoMCgUEAAIACBIDexI8Cg8KCAQAAgAInAgAEgN7EzsKRAoEBAACARID
fgIaGjcgVGhlIHNob3J0IHN1bW1hcnkgb2YgdGhlIGlzc3VlIHJlcG9ydGVkIGluIHRoaXMg
Y2FzZS4KCgwKBQQAAgEFEgN+AggKDAoFBAACAQESA34JFQoMCgUEAAIBAxIDfhgZCjEKBAQA
AgISBIEBAhkaIyBBIGJyb2FkIGRlc2NyaXB0aW9uIG9mIHRoZSBpc3N1ZS4KCg0KBQQAAgIF
EgSBAQIICg0KBQQAAgIBEgSBAQkUCg0KBQQAAgIDEgSBARcYCkEKBAQAAgMSBIQBAigaMyBU
aGUgaXNzdWUgY2xhc3NpZmljYXRpb24gYXBwbGljYWJsZSB0byB0aGlzIGNhc2UuCgoNCgUE
AAIDBhIEhAECFAoNCgUEAAIDARIEhAEVIwoNCgUEAAIDAxIEhAEmJwrHAQoEBAACBBIEiQEC
Fxq4ASBUaGUgdGltZXpvbmUgb2YgdGhlIHVzZXIgd2hvIGNyZWF0ZWQgdGhlIHN1cHBvcnQg
Y2FzZS4KIEl0IHNob3VsZCBiZSBpbiBhIGZvcm1hdCBJQU5BIHJlY29nbml6ZXM6IGh0dHBz
Oi8vd3d3LmlhbmEub3JnL3RpbWUtem9uZXMuCiBUaGVyZSBpcyBubyBhZGRpdGlvbmFsIHZh
bGlkYXRpb24gZG9uZSBieSB0aGUgQVBJLgoKDQoFBAACBAUSBIkBAggKDQoFBAACBAESBIkB
CRIKDQoFBAACBAMSBIkBFRYKRAoEBAACBRIEjAECMRo2IFRoZSBlbWFpbCBhZGRyZXNzZXMg
dG8gcmVjZWl2ZSB1cGRhdGVzIG9uIHRoaXMgY2FzZS4KCg0KBQQAAgUEEgSMAQIKCg0KBQQA
AgUFEgSMAQsRCg0KBQQAAgUBEgSMARIsCg0KBQQAAgUDEgSMAS8wCkQKBAQAAgYSBI8BAj8a
NiBPdXRwdXQgb25seS4gVGhlIGN1cnJlbnQgc3RhdHVzIG9mIHRoZSBzdXBwb3J0IGNhc2Uu
CgoNCgUEAAIGBhIEjwECBwoNCgUEAAIGARIEjwEIDQoNCgUEAAIGAxIEjwEQEgoNCgUEAAIG
CBIEjwETPgoQCggEAAIGCJwIABIEjwEUPQo+CgQEAAIHEgaSAQKTATIaLiBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgdGhpcyBjYXNlIHdhcyBjcmVhdGVkLgoKDQoFBAACBwYSBJIBAhsKDQoF
BAACBwESBJIBHCcKDQoFBAACBwMSBJIBKiwKDQoFBAACBwgSBJMBBjEKEAoIBAACBwicCAAS
BJMBBzAKQwoEBAACCBIGlgEClwEyGjMgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoaXMgY2Fz
ZSB3YXMgbGFzdCB1cGRhdGVkLgoKDQoFBAACCAYSBJYBAhsKDQoFBAACCAESBJYBHCcKDQoF
BAACCAMSBJYBKiwKDQoFBAACCAgSBJcBBjEKEAoIBAACCAicCAASBJcBBzAKiAEKBAQAAgkS
BJ0BAhUaeiBUaGUgdXNlciB3aG8gY3JlYXRlZCB0aGUgY2FzZS4KCiBOb3RlOiBUaGUgbmFt
ZSBhbmQgZW1haWwgd2lsbCBiZSBvYmZ1c2NhdGVkIGlmIHRoZSBjYXNlIHdhcyBjcmVhdGVk
IGJ5CiBHb29nbGUgU3VwcG9ydC4KCg0KBQQAAgkGEgSdAQIHCg0KBQQAAgkBEgSdAQgPCg0K
BQQAAgkDEgSdARIUCskBCgQEAAIKEgSiAQIcGroBIEEgdXNlci1zdXBwbGllZCBlbWFpbCBh
ZGRyZXNzIHRvIHNlbmQgY2FzZSB1cGRhdGUgbm90aWZpY2F0aW9ucyBmb3IuIFRoaXMKIHNo
b3VsZCBvbmx5IGJlIHVzZWQgaW4gQllPSUQgZmxvd3MsIHdoZXJlIHdlIGNhbm5vdCBpbmZl
ciB0aGUgdXNlcidzIGVtYWlsCiBhZGRyZXNzIGRpcmVjdGx5IGZyb20gdGhlaXIgRVVDcy4K
Cg0KBQQAAgoFEgSiAQIICg0KBQQAAgoBEgSiAQkWCg0KBQQAAgoDEgSiARkbCjgKBAQAAgsS
BKUBAhYaKiBXaGV0aGVyIHRoZSBjYXNlIGlzIGN1cnJlbnRseSBlc2NhbGF0ZWQuCgoNCgUE
AAILBRIEpQECBgoNCgUEAAILARIEpQEHEAoNCgUEAAILAxIEpQETFQp3CgQEAAIMEgSpAQIW
GmkgV2hldGhlciB0aGlzIGNhc2Ugd2FzIGNyZWF0ZWQgZm9yIGludGVybmFsIEFQSSB0ZXN0
aW5nIGFuZCBzaG91bGQgbm90IGJlCiBhY3RlZCBvbiBieSB0aGUgc3VwcG9ydCB0ZWFtLgoK
DQoFBAACDAUSBKkBAgYKDQoFBAACDAESBKkBBxAKDQoFBAACDAMSBKkBExUK4wMKBAQAAg0S
BLMBAhwa1AMgVGhlIGxhbmd1YWdlIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgdG8gcmVjZWl2
ZSBzdXBwb3J0IGluLiBUaGlzIHNob3VsZCBiZSBhCiBCQ1AgNDcgbGFuZ3VhZ2UgY29kZSAo
ZS5nLiwgYCJlbiJgLCBgInpoLUNOImAsIGAiemgtVFciYCwgYCJqYSJgLCBgImtvImApLgog
SWYgbm8gbGFuZ3VhZ2Ugb3IgYW4gdW5zdXBwb3J0ZWQgbGFuZ3VhZ2UgaXMgc3BlY2lmaWVk
LCB0aGlzIGZpZWxkIGRlZmF1bHRzCiB0byBFbmdsaXNoIChlbikuCgogTGFuZ3VhZ2Ugc2Vs
ZWN0aW9uIGR1cmluZyBjYXNlIGNyZWF0aW9uIG1heSBhZmZlY3QgeW91ciBhdmFpbGFibGUg
c3VwcG9ydAogb3B0aW9ucy4gRm9yIGEgbGlzdCBvZiBzdXBwb3J0ZWQgbGFuZ3VhZ2VzIGFu
ZCB0aGVpciBzdXBwb3J0IHdvcmtpbmcgaG91cnMsCiBzZWU6IGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9zdXBwb3J0L2RvY3MvbGFuZ3VhZ2Utd29ya2luZy1ob3VycwoKDQoFBAACDQUS
BLMBAggKDQoFBAACDQESBLMBCRYKDQoFBAACDQMSBLMBGRsKKgoEBAACDhIEtgECGRocIFRo
ZSBwcmlvcml0eSBvZiB0aGlzIGNhc2UuCgoNCgUEAAIOBhIEtgECCgoNCgUEAAIOARIEtgEL
EwoNCgUEAAIOAxIEtgEWGArDAgoCBAESBr8BANMBARq0AiBBIENhc2UgQ2xhc3NpZmljYXRp
b24gcmVwcmVzZW50cyB0aGUgdG9waWMgdGhhdCBhIGNhc2UgaXMgYWJvdXQuIEl0J3MgdmVy
eQogaW1wb3J0YW50IHRvIHVzZSBhY2N1cmF0ZSBjbGFzc2lmaWNhdGlvbnMsIGJlY2F1c2Ug
dGhleSdyZQogdXNlZCB0byByb3V0ZSB5b3VyIGNhc2VzIHRvIHNwZWNpYWxpc3RzIHdobyBj
YW4gaGVscCB5b3UuCgogQSBjbGFzc2lmaWNhdGlvbiBhbHdheXMgaGFzIGFuIElEIHRoYXQg
aXMgaXRzIHVuaXF1ZSBpZGVudGlmaWVyLgogQSB2YWxpZCBJRCBpcyByZXF1aXJlZCB3aGVu
IGNyZWF0aW5nIGEgY2FzZS4KCgsKAwQBARIEvwEIGgrLAwoEBAECABIEyQECEBq8AyBUaGUg
dW5pcXVlIElEIGZvciBhIGNsYXNzaWZpY2F0aW9uLiBNdXN0IGJlIHNwZWNpZmllZCBmb3Ig
Y2FzZSBjcmVhdGlvbi4KCiBUbyByZXRyaWV2ZSB2YWxpZCBjbGFzc2lmaWNhdGlvbiBJRHMg
Zm9yIGNhc2UgY3JlYXRpb24sIHVzZQogYGNhc2VDbGFzc2lmaWNhdGlvbnMuc2VhcmNoYC4K
CiBDbGFzc2lmaWNhdGlvbiBJRHMgcmV0dXJuZWQgYnkgYGNhc2VDbGFzc2lmaWNhdGlvbnMu
c2VhcmNoYCBhcmUgZ3VhcmFudGVlZAogdG8gYmUgdmFsaWQgZm9yIGF0IGxlYXN0IDYgbW9u
dGhzLiBJZiBhIGdpdmVuIGNsYXNzaWZpY2F0aW9uIGlzCiBkZWFjdGl2ZWF0ZWQsIGl0IHdp
bGwgaW1tZWRpYXRlbHkgc3RvcCBiZWluZyByZXR1cm5lZC4gQWZ0ZXIgNiBtb250aHMsCiBg
Y2FzZS5jcmVhdGVgIHJlcXVlc3RzIHVzaW5nIHRoZSBjbGFzc2lmaWNhdGlvbiBJRCB3aWxs
IGZhaWwuCgoNCgUEAQIABRIEyQECCAoNCgUEAQIAARIEyQEJCwoNCgUEAQIAAxIEyQEODwrH
AQoEBAECARIEzwECGhq4ASBBIGRpc3BsYXkgbmFtZSBmb3IgdGhlIGNsYXNzaWZpY2F0aW9u
LgoKIFRoZSBkaXNwbGF5IG5hbWUgaXMgbm90IHN0YXRpYyBhbmQgY2FuIGNoYW5nZS4gVG8g
dW5pcXVlbHkgYW5kIGNvbnNpc3RlbnRseQogaWRlbnRpZnkgY2xhc3NpZmljYXRpb25zLCB1
c2UgdGhlIGBDYXNlQ2xhc3NpZmljYXRpb24uaWRgIGZpZWxkLgoKDQoFBAECAQUSBM8BAggK
DQoFBAECAQESBM8BCRUKDQoFBAECAQMSBM8BGBkKQwoEBAECAhIE0gECFxo1IFRoZSBmdWxs
IHByb2R1Y3QgdGhlIGNsYXNzaWZpY2F0aW9uIGNvcnJlc3BvbmRzIHRvLgoKDQoFBAECAgYS
BNIBAgkKDQoFBAECAgESBNIBChEKDQoFBAECAgMSBNIBFBYKOgoCBAISBtYBANkBARosIFRo
ZSBwcm9kdWN0IGEgY2FzZSBtYXkgYmUgYXNzb2NpYXRlZCB3aXRoLgoKCwoDBAIBEgTWAQgP
CjAKBAQCAgASBNgBAh8aIiBUaGUgcHJvZHVjdCBsaW5lIG9mIHRoZSBQcm9kdWN0LgoKDQoF
BAICAAYSBNgBAg0KDQoFBAICAAESBNgBDhoKDQoFBAICAAMSBNgBHR5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::Case::Case ===
    # Fields for Case
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: classification Type: 11 (.google.cloud.support.v2beta.CaseClassification)
    # Field: time_zone Type: 9 ()
    # Field: subscriber_email_addresses Type: 9 ()
    # Field: state Type: 14 (.google.cloud.support.v2beta.Case.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 11 (.google.cloud.support.v2beta.Actor)
    # Field: contact_email Type: 9 ()
    # Field: escalated Type: 8 ()
    # Field: test_case Type: 8 ()
    # Field: language_code Type: 9 ()
    # Field: priority Type: 14 (.google.cloud.support.v2beta.Case.Priority)

# Enum: Case::State
our $Case_STATE_UNSPECIFIED = 0;
our $Case_NEW = 1;
our $Case_IN_PROGRESS_GOOGLE_SUPPORT = 2;
our $Case_ACTION_REQUIRED = 3;
our $Case_SOLUTION_PROVIDED = 4;
our $Case_CLOSED = 5;

# Enum: Case::Priority
our $Case_PRIORITY_UNSPECIFIED = 0;
our $Case_P0 = 1;
our $Case_P1 = 2;
our $Case_P2 = 3;
our $Case_P3 = 4;
our $Case_P4 = 5;

# === Message: Google::Cloud::Support::V2beta::Case::CaseClassification ===
    # Fields for CaseClassification
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: product Type: 11 (.google.cloud.support.v2beta.Product)

# === Message: Google::Cloud::Support::V2beta::Case::Product ===
    # Fields for Product
    # Field: product_line Type: 14 (.google.cloud.support.v2beta.ProductLine)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::Case - Compiled Protocol Buffers messages for google/cloud/support/v2beta/case.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::Case;

    my $msg = Google::Cloud::Support::V2beta::Case::Case->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        classification => $classification,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::Case::Case->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/case.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::Case::Case

A Case is an object that contains the details of a support case. It
contains fields for the time it was created, its priority, its
classification, and more. Cases can also have comments and attachments that
get added over time.

A case is parented by a Google Cloud organization or project.

Organizations are identified by a number, so the name of a case parented by
an organization would look like this:

```
organizations/123/cases/456
```

Projects have two unique identifiers, an ID and a number, and they look like
this:

```
projects/abc/cases/456
```

```
projects/123/cases/456
```

You can use either of them when calling the API. To learn more
about project identifiers, see [AIP-2510](https://google.aip.dev/cloud/2510).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name for the case.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The short summary of the issue reported in this case.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A broad description of the issue.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::CaseClassification>)

The issue classification applicable to this case.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

The timezone of the user who created the support case.
It should be in a format IANA recognizes: https://www.iana.org/time-zones.
There is no additional validation done by the API.

=item * C<< $msg->subscriber_email_addresses() >> / C<< $msg->subscriber_email_addresses($value) >>

Type: C<String>

The email addresses to receive updates on this case.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::Case::State>)

Output only. The current status of the support case.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this case was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this case was last updated.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Actor::Actor>)

The user who created the case.

Note: The name and email will be obfuscated if the case was created by
Google Support.

=item * C<< $msg->contact_email() >> / C<< $msg->contact_email($value) >>

Type: C<String>

A user-supplied email address to send case update notifications for. This
should only be used in BYOID flows, where we cannot infer the user's email
address directly from their EUCs.

=item * C<< $msg->escalated() >> / C<< $msg->escalated($value) >>

Type: C<Bool>

Whether the case is currently escalated.

=item * C<< $msg->test_case() >> / C<< $msg->test_case($value) >>

Type: C<Bool>

Whether this case was created for internal API testing and should not be
acted on by the support team.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language the user has requested to receive support in. This should be a
BCP 47 language code (e.g., `"en"`, `"zh-CN"`, `"zh-TW"`, `"ja"`, `"ko"`).
If no language or an unsupported language is specified, this field defaults
to English (en).

Language selection during case creation may affect your available support
options. For a list of supported languages and their support working hours,
see: https://cloud.google.com/support/docs/language-working-hours

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::Case::Priority>)

The priority of this case.

=back

=head3 Enum: Case::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<NEW> => C<1>

=item * C<IN_PROGRESS_GOOGLE_SUPPORT> => C<2>

=item * C<ACTION_REQUIRED> => C<3>

=item * C<SOLUTION_PROVIDED> => C<4>

=item * C<CLOSED> => C<5>

=back

=head3 Enum: Case::Priority

=over 4

=item * C<PRIORITY_UNSPECIFIED> => C<0>

=item * C<P0> => C<1>

=item * C<P1> => C<2>

=item * C<P2> => C<3>

=item * C<P3> => C<4>

=item * C<P4> => C<5>

=back

=head2 Google::Cloud::Support::V2beta::Case::CaseClassification

A Case Classification represents the topic that a case is about. It's very
important to use accurate classifications, because they're
used to route your cases to specialists who can help you.

A classification always has an ID that is its unique identifier.
A valid ID is required when creating a case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The unique ID for a classification. Must be specified for case creation.

To retrieve valid classification IDs for case creation, use
`caseClassifications.search`.

Classification IDs returned by `caseClassifications.search` are guaranteed
to be valid for at least 6 months. If a given classification is
deactiveated, it will immediately stop being returned. After 6 months,
`case.create` requests using the classification ID will fail.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A display name for the classification.

The display name is not static and can change. To uniquely and consistently
identify classifications, use the `CaseClassification.id` field.

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::Product>)

The full product the classification corresponds to.

=back

=head2 Google::Cloud::Support::V2beta::Case::Product

The product a case may be associated with.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product_line() >> / C<< $msg->product_line($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::ProductLine>)

The product line of the Product.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::Case::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
