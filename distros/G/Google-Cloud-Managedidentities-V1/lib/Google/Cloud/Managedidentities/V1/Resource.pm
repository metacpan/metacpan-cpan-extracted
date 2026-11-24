package Google::Cloud::Managedidentities::V1::Resource;

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
CjBnb29nbGUvY2xvdWQvbWFuYWdlZGlkZW50aXRpZXMvdjEvcmVzb3VyY2UucHJvdG8SIWdv
b2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byKrBwoGRG9tYWluEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRJS
CgZsYWJlbHMYAiADKAsyNS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuRG9t
YWluLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxI0ChNhdXRob3JpemVkX25ldHdvcmtzGAMg
AygJQgPgQQFSEmF1dGhvcml6ZWROZXR3b3JrcxIvChFyZXNlcnZlZF9pcF9yYW5nZRgEIAEo
CUID4EECUg9yZXNlcnZlZElwUmFuZ2USIQoJbG9jYXRpb25zGAUgAygJQgPgQQJSCWxvY2F0
aW9ucxIZCgVhZG1pbhgGIAEoCUID4EEBUgVhZG1pbhIXCgRmcWRuGAogASgJQgPgQQNSBGZx
ZG4SQAoLY3JlYXRlX3RpbWUYCyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYDCABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSSgoFc3RhdGUYDSABKA4yLy5nb29nbGUuY2xv
dWQubWFuYWdlZGlkZW50aXRpZXMudjEuRG9tYWluLlN0YXRlQgPgQQNSBXN0YXRlEioKDnN0
YXR1c19tZXNzYWdlGA4gASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USRQoGdHJ1c3RzGA8gAygL
MiguZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLlRydXN0QgPgQQNSBnRydXN0
cxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIo8BCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAES
CQoFUkVBRFkQAhIMCghVUERBVElORxADEgwKCERFTEVUSU5HEAQSDQoJUkVQQUlSSU5HEAUS
GgoWUEVSRk9STUlOR19NQUlOVEVOQU5DRRAGEg8KC1VOQVZBSUxBQkxFEAc6ZupBYwonbWFu
YWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5jb20vRG9tYWluEjhwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9tYWlucy97ZG9tYWlufSKcCAoFVHJ1c3QSMQoS
dGFyZ2V0X2RvbWFpbl9uYW1lGAEgASgJQgPgQQJSEHRhcmdldERvbWFpbk5hbWUSVgoKdHJ1
c3RfdHlwZRgCIAEoDjIyLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5UcnVz
dC5UcnVzdFR5cGVCA+BBAlIJdHJ1c3RUeXBlEmUKD3RydXN0X2RpcmVjdGlvbhgDIAEoDjI3
Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5UcnVzdC5UcnVzdERpcmVjdGlv
bkID4EECUg50cnVzdERpcmVjdGlvbhI+ChhzZWxlY3RpdmVfYXV0aGVudGljYXRpb24YBCAB
KAhCA+BBAVIXc2VsZWN0aXZlQXV0aGVudGljYXRpb24SOgoXdGFyZ2V0X2Ruc19pcF9hZGRy
ZXNzZXMYBSADKAlCA+BBAlIUdGFyZ2V0RG5zSXBBZGRyZXNzZXMSOQoWdHJ1c3RfaGFuZHNo
YWtlX3NlY3JldBgGIAEoCUID4EECUhR0cnVzdEhhbmRzaGFrZVNlY3JldBJACgtjcmVhdGVf
dGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGlt
ZRJACgt1cGRhdGVfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKdXBkYXRlVGltZRJJCgVzdGF0ZRgJIAEoDjIuLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRl
bnRpdGllcy52MS5UcnVzdC5TdGF0ZUID4EEDUgVzdGF0ZRIwChFzdGF0ZV9kZXNjcmlwdGlv
bhgLIAEoCUID4EEDUhBzdGF0ZURlc2NyaXB0aW9uEloKGWxhc3RfdHJ1c3RfaGVhcnRiZWF0
X3RpbWUYDCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSFmxhc3RUcnVz
dEhlYXJ0YmVhdFRpbWUiaQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVB
VElORxABEgwKCFVQREFUSU5HEAISDAoIREVMRVRJTkcQAxINCglDT05ORUNURUQQBBIQCgxE
SVNDT05ORUNURUQQBSJBCglUcnVzdFR5cGUSGgoWVFJVU1RfVFlQRV9VTlNQRUNJRklFRBAA
EgoKBkZPUkVTVBABEgwKCEVYVEVSTkFMEAIiXwoOVHJ1c3REaXJlY3Rpb24SHwobVFJVU1Rf
RElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASCwoHSU5CT1VORBABEgwKCE9VVEJPVU5EEAISEQoN
QklESVJFQ1RJT05BTBADQvwBCiVjb20uZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVz
LnYxQg1SZXNvdXJjZVByb3RvUAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28vbWFuYWdlZGlkZW50
aXRpZXMvYXBpdjEvbWFuYWdlZGlkZW50aXRpZXNwYjttYW5hZ2VkaWRlbnRpdGllc3BiqgIh
R29vZ2xlLkNsb3VkLk1hbmFnZWRJZGVudGl0aWVzLlYxygIhR29vZ2xlXENsb3VkXE1hbmFn
ZWRJZGVudGl0aWVzXFYx6gIkR29vZ2xlOjpDbG91ZDo6TWFuYWdlZElkZW50aXRpZXM6OlYx
Sq0/CgcSBQ8A0wEBCr0ECgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQIS
AxEAKgoJCgIDABIDEwApCgkKAgMBEgMUACMKCQoCAwISAxUAKQoICgEIEgMXAD4KCQoCCCUS
AxcAPgoICgEIEgMYAGoKCQoCCAsSAxgAagoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMa
AC4KCQoCCAgSAxoALgoICgEIEgMbAD4KCQoCCAESAxsAPgoICgEIEgMcAD4KCQoCCCkSAxwA
PgoICgEIEgMdAD0KCQoCCC0SAx0APQpFCgIEABIEIAB1ARo5IFJlcHJlc2VudHMgYSBtYW5h
Z2VkIE1pY3Jvc29mdCBBY3RpdmUgRGlyZWN0b3J5IGRvbWFpbi4KCgoKAwQAARIDIAgOCgsK
AwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBApECgQEAAQAEgQnAkADGjYgUmVwcmVzZW50cyB0
aGUgZGlmZmVyZW50IHN0YXRlcyBvZiBhIG1hbmFnZWQgZG9tYWluLgoKDAoFBAAEAAESAycH
DAoZCgYEAAQAAgASAykEGhoKIE5vdCBzZXQuCgoOCgcEAAQAAgABEgMpBBUKDgoHBAAEAAIA
AhIDKRgZCi0KBgQABAACARIDLAQRGh4gVGhlIGRvbWFpbiBpcyBiZWluZyBjcmVhdGVkLgoK
DgoHBAAEAAIBARIDLAQMCg4KBwQABAACAQISAywPEApBCgYEAAQAAgISAy8EDhoyIFRoZSBk
b21haW4gaGFzIGJlZW4gY3JlYXRlZCBhbmQgaXMgZnVsbHkgdXNhYmxlLgoKDgoHBAAEAAIC
ARIDLwQJCg4KBwQABAACAgISAy8MDQo9CgYEAAQAAgMSAzIEERouIFRoZSBkb21haW4ncyBj
b25maWd1cmF0aW9uIGlzIGJlaW5nIHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgMyBAwKDgoHBAAE
AAIDAhIDMg8QCi0KBgQABAACBBIDNQQRGh4gVGhlIGRvbWFpbiBpcyBiZWluZyBkZWxldGVk
LgoKDgoHBAAEAAIEARIDNQQMCg4KBwQABAACBAISAzUPEAp3CgYEAAQAAgUSAzkEEhpoIFRo
ZSBkb21haW4gaXMgYmVpbmcgcmVwYWlyZWQgYW5kIG1heSBiZSB1bnVzYWJsZS4gRGV0YWls
cwogY2FuIGJlIGZvdW5kIGluIHRoZSBgc3RhdHVzX21lc3NhZ2VgIGZpZWxkLgoKDgoHBAAE
AAIFARIDOQQNCg4KBwQABAACBQISAzkQEQo2CgYEAAQAAgYSAzwEHxonIFRoZSBkb21haW4g
aXMgdW5kZXJnb2luZyBtYWludGVuYW5jZS4KCg4KBwQABAACBgESAzwEGgoOCgcEAAQAAgYC
EgM8HR4KNAoGBAAEAAIHEgM/BBQaJSBUaGUgZG9tYWluIGlzIG5vdCBzZXJ2aW5nIHJlcXVl
c3RzLgoKDgoHBAAEAAIHARIDPwQPCg4KBwQABAACBwISAz8SEwqHAQoEBAACABIDRAI7Gnog
UmVxdWlyZWQuIFRoZSB1bmlxdWUgbmFtZSBvZiB0aGUgZG9tYWluIHVzaW5nIHRoZSBmb3Jt
OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMve2Rv
bWFpbl9uYW1lfWAuCgoMCgUEAAIABRIDRAIICgwKBQQAAgABEgNECQ0KDAoFBAACAAMSA0QQ
EQoMCgUEAAIACBIDRBI6Cg8KCAQAAgAInAgAEgNEEzkKUQoEBAACARIDRwJKGkQgT3B0aW9u
YWwuIFJlc291cmNlIGxhYmVscyB0aGF0IGNhbiBjb250YWluIHVzZXItcHJvdmlkZWQgbWV0
YWRhdGEuCgoMCgUEAAIBBhIDRwIVCgwKBQQAAgEBEgNHFhwKDAoFBAACAQMSA0cfIAoMCgUE
AAIBCBIDRyFJCg8KCAQAAgEInAgAEgNHIkgK4QIKBAQAAgISA04CUxrTAiBPcHRpb25hbC4g
VGhlIGZ1bGwgbmFtZXMgb2YgdGhlIEdvb2dsZSBDb21wdXRlIEVuZ2luZQogW25ldHdvcmtz
XSgvY29tcHV0ZS9kb2NzL25ldHdvcmtzLWFuZC1maXJld2FsbHMjbmV0d29ya3MpIHRoZSBk
b21haW4KIGluc3RhbmNlIGlzIGNvbm5lY3RlZCB0by4gTmV0d29ya3MgY2FuIGJlIGFkZGVk
IHVzaW5nIFVwZGF0ZURvbWFpbi4KIFRoZSBkb21haW4gaXMgb25seSBhdmFpbGFibGUgb24g
bmV0d29ya3MgbGlzdGVkIGluIGBhdXRob3JpemVkX25ldHdvcmtzYC4KIElmIENJRFIgc3Vi
bmV0cyBvdmVybGFwIGJldHdlZW4gbmV0d29ya3MsIGRvbWFpbiBjcmVhdGlvbiB3aWxsIGZh
aWwuCgoMCgUEAAICBBIDTgIKCgwKBQQAAgIFEgNOCxEKDAoFBAACAgESA04SJQoMCgUEAAIC
AxIDTigpCgwKBQQAAgIIEgNOKlIKDwoIBAACAgicCAASA04rUQrwAQoEBAACAxIDVAJIGuIB
IFJlcXVpcmVkLiBUaGUgQ0lEUiByYW5nZSBvZiBpbnRlcm5hbCBhZGRyZXNzZXMgdGhhdCBh
cmUgcmVzZXJ2ZWQgZm9yIHRoaXMKIGRvbWFpbi4gUmVzZXJ2ZWQgbmV0d29ya3MgbXVzdCBi
ZSAvMjQgb3IgbGFyZ2VyLiBSYW5nZXMgbXVzdCBiZQogdW5pcXVlIGFuZCBub24tb3Zlcmxh
cHBpbmcgd2l0aCBleGlzdGluZyBzdWJuZXRzIGluCiBbRG9tYWluXS5bYXV0aG9yaXplZF9u
ZXR3b3Jrc10uCgoMCgUEAAIDBRIDVAIICgwKBQQAAgMBEgNUCRoKDAoFBAACAwMSA1QdHgoM
CgUEAAIDCBIDVB9HCg8KCAQAAgMInAgAEgNUIEYK3gEKBAQAAgQSA1sCSRrQASBSZXF1aXJl
ZC4gTG9jYXRpb25zIHdoZXJlIGRvbWFpbiBuZWVkcyB0byBiZSBwcm92aXNpb25lZC4KIFty
ZWdpb25zXVtjb21wdXRlL2RvY3MvcmVnaW9ucy16b25lcy9dCiBlLmcuIHVzLXdlc3QxIG9y
IHVzLWVhc3Q0CiBTZXJ2aWNlIHN1cHBvcnRzIHVwIHRvIDQgbG9jYXRpb25zIGF0IG9uY2Uu
IEVhY2ggbG9jYXRpb24gd2lsbCB1c2UgYSAvMjYKIGJsb2NrLgoKDAoFBAACBAQSA1sCCgoM
CgUEAAIEBRIDWwsRCgwKBQQAAgQBEgNbEhsKDAoFBAACBAMSA1seHwoMCgUEAAIECBIDWyBI
Cg8KCAQAAgQInAgAEgNbIUcKoAEKBAQAAgUSA18CPBqSASBPcHRpb25hbC4gVGhlIG5hbWUg
b2YgZGVsZWdhdGVkIGFkbWluaXN0cmF0b3IgYWNjb3VudCB1c2VkIHRvIHBlcmZvcm0KIEFj
dGl2ZSBEaXJlY3Rvcnkgb3BlcmF0aW9ucy4gSWYgbm90IHNwZWNpZmllZCwgYHNldHVwYWRt
aW5gIHdpbGwgYmUgdXNlZC4KCgwKBQQAAgUFEgNfAggKDAoFBAACBQESA18JDgoMCgUEAAIF
AxIDXxESCgwKBQQAAgUIEgNfEzsKDwoIBAACBQicCAASA18UOgrWAQoEBAACBhIDZAI/GsgB
IE91dHB1dCBvbmx5LiBUaGUgZnVsbHktcXVhbGlmaWVkIGRvbWFpbiBuYW1lIG9mIHRoZSBl
eHBvc2VkIGRvbWFpbiB1c2VkIGJ5CiBjbGllbnRzIHRvIGNvbm5lY3QgdG8gdGhlIHNlcnZp
Y2UuIFNpbWlsYXIgdG8gd2hhdCB3b3VsZCBiZSBjaG9zZW4gZm9yIGFuCiBBY3RpdmUgRGly
ZWN0b3J5IHNldCB1cCBvbiBhbiBpbnRlcm5hbCBuZXR3b3JrLgoKDAoFBAACBgUSA2QCCAoM
CgUEAAIGARIDZAkNCgwKBQQAAgYDEgNkEBIKDAoFBAACBggSA2QTPgoPCggEAAIGCJwIABID
ZBQ9Cj4KBAQAAgcSA2cCWRoxIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgaW5zdGFuY2Ug
d2FzIGNyZWF0ZWQuCgoMCgUEAAIHBhIDZwIbCgwKBQQAAgcBEgNnHCcKDAoFBAACBwMSA2cq
LAoMCgUEAAIHCBIDZy1YCg8KCAQAAgcInAgAEgNnLlcKMQoEBAACCBIDagJZGiQgT3V0cHV0
IG9ubHkuIFRoZSBsYXN0IHVwZGF0ZSB0aW1lLgoKDAoFBAACCAYSA2oCGwoMCgUEAAIIARID
ahwnCgwKBQQAAggDEgNqKiwKDAoFBAACCAgSA2otWAoPCggEAAIICJwIABIDai5XCj0KBAQA
AgkSA20CPxowIE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGlzIGRvbWFp
bi4KCgwKBQQAAgkGEgNtAgcKDAoFBAACCQESA20IDQoMCgUEAAIJAxIDbRASCgwKBQQAAgkI
EgNtEz4KDwoIBAACCQicCAASA20UPQpqCgQEAAIKEgNxAkkaXSBPdXRwdXQgb25seS4gQWRk
aXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgY3VycmVudCBzdGF0dXMgb2YgdGhpcwog
ZG9tYWluLCBpZiBhdmFpbGFibGUuCgoMCgUEAAIKBRIDcQIICgwKBQQAAgoBEgNxCRcKDAoF
BAACCgMSA3EaHAoMCgUEAAIKCBIDcR1ICg8KCAQAAgoInAgAEgNxHkcKSgoEBAACCxIDdAJJ
Gj0gT3V0cHV0IG9ubHkuIFRoZSBjdXJyZW50IHRydXN0cyBhc3NvY2lhdGVkIHdpdGggdGhl
IGRvbWFpbi4KCgwKBQQAAgsEEgN0AgoKDAoFBAACCwYSA3QLEAoMCgUEAAILARIDdBEXCgwK
BQQAAgsDEgN0GhwKDAoFBAACCwgSA3QdSAoPCggEAAILCJwIABIDdB5HCpABCgIEARIFeQDT
AQEaggEgUmVwcmVzZW50cyBhIHJlbGF0aW9uc2hpcCBiZXR3ZWVuIHR3byBkb21haW5zLiBU
aGlzIGFsbG93cyBhIGNvbnRyb2xsZXIgaW4KIG9uZSBkb21haW4gdG8gYXV0aGVudGljYXRl
IGEgdXNlciBpbiBhbm90aGVyIGRvbWFpbi4KCgoKAwQBARIDeQgNCkMKBAQBBAASBXsCjQED
GjQgUmVwcmVzZW50cyB0aGUgZGlmZmVyZW50IHN0YXRlcyBvZiBhIGRvbWFpbiB0cnVzdC4K
CgwKBQQBBAABEgN7BwwKGQoGBAEEAAIAEgN9BBoaCiBOb3Qgc2V0LgoKDgoHBAEEAAIAARID
fQQVCg4KBwQBBAACAAISA30YGQo0CgYEAQQAAgESBIABBBEaJCBUaGUgZG9tYWluIHRydXN0
IGlzIGJlaW5nIGNyZWF0ZWQuCgoPCgcEAQQAAgEBEgSAAQQMCg8KBwQBBAACAQISBIABDxAK
NAoGBAEEAAICEgSDAQQRGiQgVGhlIGRvbWFpbiB0cnVzdCBpcyBiZWluZyB1cGRhdGVkLgoK
DwoHBAEEAAICARIEgwEEDAoPCgcEAQQAAgICEgSDAQ8QCjQKBgQBBAACAxIEhgEEERokIFRo
ZSBkb21haW4gdHJ1c3QgaXMgYmVpbmcgZGVsZXRlZC4KCg8KBwQBBAACAwESBIYBBAwKDwoH
BAEEAAIDAhIEhgEPEAowCgYEAQQAAgQSBIkBBBIaICBUaGUgZG9tYWluIHRydXN0IGlzIGNv
bm5lY3RlZC4KCg8KBwQBBAACBAESBIkBBA0KDwoHBAEEAAIEAhIEiQEQEQozCgYEAQQAAgUS
BIwBBBUaIyBUaGUgZG9tYWluIHRydXN0IGlzIGRpc2Nvbm5lY3RlZC4KCg8KBwQBBAACBQES
BIwBBBAKDwoHBAEEAAIFAhIEjAETFApECgQEAQQBEgaQAQKZAQMaNCBSZXByZXNlbnRzIHRo
ZSBkaWZmZXJlbnQgaW50ZXItZm9yZXN0IHRydXN0IHR5cGVzLgoKDQoFBAEEAQESBJABBxAK
GgoGBAEEAQIAEgSSAQQfGgogTm90IHNldC4KCg8KBwQBBAECAAESBJIBBBoKDwoHBAEEAQIA
AhIEkgEdHgojCgYEAQQBAgESBJUBBA8aEyBUaGUgZm9yZXN0IHRydXN0LgoKDwoHBAEEAQIB
ARIElQEECgoPCgcEAQQBAgECEgSVAQ0OCiwKBgQBBAECAhIEmAEEERocIFRoZSBleHRlcm5h
bCBkb21haW4gdHJ1c3QuCgoPCgcEAQQBAgIBEgSYAQQMCg8KBwQBBAECAgISBJgBDxAKiQIK
BAQBBAISBp8BAqsBAxr4ASBSZXByZXNlbnRzIHRoZSBkaXJlY3Rpb24gb2YgdHJ1c3QuCiBT
ZWUKIFtTeXN0ZW0uRGlyZWN0b3J5U2VydmljZXMuQWN0aXZlRGlyZWN0b3J5LlRydXN0RGly
ZWN0aW9uXShodHRwczovL2RvY3MubWljcm9zb2Z0LmNvbS9lbi11cy9kb3RuZXQvYXBpL3N5
c3RlbS5kaXJlY3RvcnlzZXJ2aWNlcy5hY3RpdmVkaXJlY3RvcnkudHJ1c3RkaXJlY3Rpb24/
dmlldz1uZXRmcmFtZXdvcmstNC43LjIpCiBmb3IgbW9yZSBpbmZvcm1hdGlvbi4KCg0KBQQB
BAIBEgSfAQcVChoKBgQBBAICABIEoQEEJBoKIE5vdCBzZXQuCgoPCgcEAQQCAgABEgShAQQf
Cg8KBwQBBAICAAISBKEBIiMKRQoGBAEEAgIBEgSkAQQQGjUgVGhlIGluYm91bmQgZGlyZWN0
aW9uIHJlcHJlc2VudHMgdGhlIHRydXN0aW5nIHNpZGUuCgoPCgcEAQQCAgEBEgSkAQQLCg8K
BwQBBAICAQISBKQBDg8KRAoGBAEEAgICEgSnAQQRGjQgVGhlIG91dGJvdWQgZGlyZWN0aW9u
IHJlcHJlc2VudHMgdGhlIHRydXN0ZWQgc2lkZS4KCg8KBwQBBAICAgESBKcBBAwKDwoHBAEE
AgICAhIEpwEPEApVCgYEAQQCAgMSBKoBBBYaRSBUaGUgYmlkaXJlY3Rpb25hbCBkaXJlY3Rp
b24gcmVwcmVzZW50cyB0aGUgdHJ1c3RlZCAvIHRydXN0aW5nIHNpZGUuCgoPCgcEAQQCAgMB
EgSqAQQRCg8KBwQBBAICAwISBKoBFBUKcQoEBAECABIErwECSRpjIFJlcXVpcmVkLiBUaGUg
ZnVsbHkgcXVhbGlmaWVkIHRhcmdldCBkb21haW4gbmFtZSB3aGljaCB3aWxsIGJlIGluIHRy
dXN0IHdpdGggdGhlCiBjdXJyZW50IGRvbWFpbi4KCg0KBQQBAgAFEgSvAQIICg0KBQQBAgAB
EgSvAQkbCg0KBQQBAgADEgSvAR4fCg0KBQQBAgAIEgSvASBIChAKCAQBAgAInAgAEgSvASFH
Ck4KBAQBAgESBLIBAkQaQCBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgdHJ1c3QgcmVwcmVzZW50
ZWQgYnkgdGhlIHRydXN0IHJlc291cmNlLgoKDQoFBAECAQYSBLIBAgsKDQoFBAECAQESBLIB
DBYKDQoFBAECAQMSBLIBGRoKDQoFBAECAQgSBLIBG0MKEAoIBAECAQicCAASBLIBHEIKcgoE
BAECAhIEtgECThpkIFJlcXVpcmVkLiBUaGUgdHJ1c3QgZGlyZWN0aW9uLCB3aGljaCBkZWNp
ZGVzIGlmIHRoZSBjdXJyZW50IGRvbWFpbiBpcyB0cnVzdGVkLAogdHJ1c3RpbmcsIG9yIGJv
dGguCgoNCgUEAQICBhIEtgECEAoNCgUEAQICARIEtgERIAoNCgUEAQICAxIEtgEjJAoNCgUE
AQICCBIEtgElTQoQCggEAQICCJwIABIEtgEmTAq1AQoEBAECAxIEuwECTRqmASBPcHRpb25h
bC4gVGhlIHRydXN0IGF1dGhlbnRpY2F0aW9uIHR5cGUsIHdoaWNoIGRlY2lkZXMgd2hldGhl
ciB0aGUgdHJ1c3RlZCBzaWRlIGhhcwogZm9yZXN0L2RvbWFpbiB3aWRlIGFjY2VzcyBvciBz
ZWxlY3RpdmUgYWNjZXNzIHRvIGFuIGFwcHJvdmVkIHNldCBvZgogcmVzb3VyY2VzLgoKDQoF
BAECAwUSBLsBAgYKDQoFBAECAwESBLsBBx8KDQoFBAECAwMSBLsBIiMKDQoFBAECAwgSBLsB
JEwKEAoIBAECAwicCAASBLsBJUsKeAoEBAECBBIEvwECVxpqIFJlcXVpcmVkLiBUaGUgdGFy
Z2V0IEROUyBzZXJ2ZXIgSVAgYWRkcmVzc2VzIHdoaWNoIGNhbiByZXNvbHZlIHRoZSByZW1v
dGUgZG9tYWluCiBpbnZvbHZlZCBpbiB0aGUgdHJ1c3QuCgoNCgUEAQIEBBIEvwECCgoNCgUE
AQIEBRIEvwELEQoNCgUEAQIEARIEvwESKQoNCgUEAQIEAxIEvwEsLQoNCgUEAQIECBIEvwEu
VgoQCggEAQIECJwIABIEvwEvVQpzCgQEAQIFEgTDAQJNGmUgUmVxdWlyZWQuIFRoZSB0cnVz
dCBzZWNyZXQgdXNlZCBmb3IgdGhlIGhhbmRzaGFrZSB3aXRoIHRoZSB0YXJnZXQgZG9tYWlu
LiBUaGlzIHdpbGwKIG5vdCBiZSBzdG9yZWQuCgoNCgUEAQIFBRIEwwECCAoNCgUEAQIFARIE
wwEJHwoNCgUEAQIFAxIEwwEiIwoNCgUEAQIFCBIEwwEkTAoQCggEAQIFCJwIABIEwwElSwo/
CgQEAQIGEgTGAQJYGjEgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBpbnN0YW5jZSB3YXMg
Y3JlYXRlZC4KCg0KBQQBAgYGEgTGAQIbCg0KBQQBAgYBEgTGARwnCg0KBQQBAgYDEgTGASor
Cg0KBQQBAgYIEgTGASxXChAKCAQBAgYInAgAEgTGAS1WCjIKBAQBAgcSBMkBAlgaJCBPdXRw
dXQgb25seS4gVGhlIGxhc3QgdXBkYXRlIHRpbWUuCgoNCgUEAQIHBhIEyQECGwoNCgUEAQIH
ARIEyQEcJwoNCgUEAQIHAxIEyQEqKwoNCgUEAQIHCBIEyQEsVwoQCggEAQIHCJwIABIEyQEt
Vgo8CgQEAQIIEgTMAQI+Gi4gT3V0cHV0IG9ubHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRo
ZSB0cnVzdC4KCg0KBQQBAggGEgTMAQIHCg0KBQQBAggBEgTMAQgNCg0KBQQBAggDEgTMARAR
Cg0KBQQBAggIEgTMARI9ChAKCAQBAggInAgAEgTMARM8CmcKBAQBAgkSBM8BAkwaWSBPdXRw
dXQgb25seS4gQWRkaXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgY3VycmVudCBzdGF0
ZSBvZiB0aGUgdHJ1c3QsIGlmIGF2YWlsYWJsZS4KCg0KBQQBAgkFEgTPAQIICg0KBQQBAgkB
EgTPAQkaCg0KBQQBAgkDEgTPAR0fCg0KBQQBAgkIEgTPASBLChAKCAQBAgkInAgAEgTPASFK
Cl4KBAQBAgoSBNIBAmcaUCBPdXRwdXQgb25seS4gVGhlIGxhc3QgaGVhcnRiZWF0IHRpbWUg
d2hlbiB0aGUgdHJ1c3Qgd2FzIGtub3duIHRvIGJlIGNvbm5lY3RlZC4KCg0KBQQBAgoGEgTS
AQIbCg0KBQQBAgoBEgTSARw1Cg0KBQQBAgoDEgTSATg6Cg0KBQQBAgoIEgTSATtmChAKCAQB
AgoInAgAEgTSATxlYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Managedidentities::V1::Resource::Domain ===
    # Fields for Domain
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.managedidentities.v1.Domain.LabelsEntry)
    # Field: authorized_networks Type: 9 ()
    # Field: reserved_ip_range Type: 9 ()
    # Field: locations Type: 9 ()
    # Field: admin Type: 9 ()
    # Field: fqdn Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.managedidentities.v1.Domain.State)
    # Field: status_message Type: 9 ()
    # Field: trusts Type: 11 (.google.cloud.managedidentities.v1.Trust)

# Enum: Domain::State
our $Domain_STATE_UNSPECIFIED = 0;
our $Domain_CREATING = 1;
our $Domain_READY = 2;
our $Domain_UPDATING = 3;
our $Domain_DELETING = 4;
our $Domain_REPAIRING = 5;
our $Domain_PERFORMING_MAINTENANCE = 6;
our $Domain_UNAVAILABLE = 7;

# === Message: Google::Cloud::Managedidentities::V1::Resource::Trust ===
    # Fields for Trust
    # Field: target_domain_name Type: 9 ()
    # Field: trust_type Type: 14 (.google.cloud.managedidentities.v1.Trust.TrustType)
    # Field: trust_direction Type: 14 (.google.cloud.managedidentities.v1.Trust.TrustDirection)
    # Field: selective_authentication Type: 8 ()
    # Field: target_dns_ip_addresses Type: 9 ()
    # Field: trust_handshake_secret Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.managedidentities.v1.Trust.State)
    # Field: state_description Type: 9 ()
    # Field: last_trust_heartbeat_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Trust::State
our $Trust_STATE_UNSPECIFIED = 0;
our $Trust_CREATING = 1;
our $Trust_UPDATING = 2;
our $Trust_DELETING = 3;
our $Trust_CONNECTED = 4;
our $Trust_DISCONNECTED = 5;

# Enum: Trust::TrustType
our $Trust_TRUST_TYPE_UNSPECIFIED = 0;
our $Trust_FOREST = 1;
our $Trust_EXTERNAL = 2;

# Enum: Trust::TrustDirection
our $Trust_TRUST_DIRECTION_UNSPECIFIED = 0;
our $Trust_INBOUND = 1;
our $Trust_OUTBOUND = 2;
our $Trust_BIDIRECTIONAL = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Managedidentities::V1::Resource - Compiled Protocol Buffers messages for google/cloud/managedidentities/v1/resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Managedidentities::V1::Resource;

    my $msg = Google::Cloud::Managedidentities::V1::Resource::Domain->new({
        name => $name,
        labels => $labels,
        authorized_networks => $authorized_networks,
        reserved_ip_range => $reserved_ip_range,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Managedidentities::V1::Resource::Domain->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/managedidentities/v1/resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Managedidentities::V1::Resource::Domain

Represents a managed Microsoft Active Directory domain.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique name of the domain using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Domain::LabelsEntry>)

Optional. Resource labels that can contain user-provided metadata.

=item * C<< $msg->authorized_networks() >> / C<< $msg->authorized_networks($value) >>

Type: C<String>

Optional. The full names of the Google Compute Engine
[networks](/compute/docs/networks-and-firewalls#networks) the domain
instance is connected to. Networks can be added using UpdateDomain.
The domain is only available on networks listed in `authorized_networks`.
If CIDR subnets overlap between networks, domain creation will fail.

=item * C<< $msg->reserved_ip_range() >> / C<< $msg->reserved_ip_range($value) >>

Type: C<String>

Required. The CIDR range of internal addresses that are reserved for this
domain. Reserved networks must be /24 or larger. Ranges must be
unique and non-overlapping with existing subnets in
[Domain].[authorized_networks].

=item * C<< $msg->locations() >> / C<< $msg->locations($value) >>

Type: C<String>

Required. Locations where domain needs to be provisioned.
[regions][compute/docs/regions-zones/]
e.g. us-west1 or us-east4
Service supports up to 4 locations at once. Each location will use a /26
block.

=item * C<< $msg->admin() >> / C<< $msg->admin($value) >>

Type: C<String>

Optional. The name of delegated administrator account used to perform
Active Directory operations. If not specified, `setupadmin` will be used.

=item * C<< $msg->fqdn() >> / C<< $msg->fqdn($value) >>

Type: C<String>

Output only. The fully-qualified domain name of the exposed domain used by
clients to connect to the service. Similar to what would be chosen for an
Active Directory set up on an internal network.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the instance was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update time.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1::Domain::State>)

Output only. The current state of this domain.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Additional information about the current status of this
domain, if available.

=item * C<< $msg->trusts() >> / C<< $msg->trusts($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Trust>)

Output only. The current trusts associated with the domain.

=back

=head3 Enum: Domain::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=item * C<REPAIRING> => C<5>

=item * C<PERFORMING_MAINTENANCE> => C<6>

=item * C<UNAVAILABLE> => C<7>

=back

=head2 Google::Cloud::Managedidentities::V1::Resource::Trust

Represents a relationship between two domains. This allows a controller in
one domain to authenticate a user in another domain.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_domain_name() >> / C<< $msg->target_domain_name($value) >>

Type: C<String>

Required. The fully qualified target domain name which will be in trust with the
current domain.

=item * C<< $msg->trust_type() >> / C<< $msg->trust_type($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1::Trust::TrustType>)

Required. The type of trust represented by the trust resource.

=item * C<< $msg->trust_direction() >> / C<< $msg->trust_direction($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1::Trust::TrustDirection>)

Required. The trust direction, which decides if the current domain is trusted,
trusting, or both.

=item * C<< $msg->selective_authentication() >> / C<< $msg->selective_authentication($value) >>

Type: C<Bool>

Optional. The trust authentication type, which decides whether the trusted side has
forest/domain wide access or selective access to an approved set of
resources.

=item * C<< $msg->target_dns_ip_addresses() >> / C<< $msg->target_dns_ip_addresses($value) >>

Type: C<String>

Required. The target DNS server IP addresses which can resolve the remote domain
involved in the trust.

=item * C<< $msg->trust_handshake_secret() >> / C<< $msg->trust_handshake_secret($value) >>

Type: C<String>

Required. The trust secret used for the handshake with the target domain. This will
not be stored.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the instance was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update time.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1::Trust::State>)

Output only. The current state of the trust.

=item * C<< $msg->state_description() >> / C<< $msg->state_description($value) >>

Type: C<String>

Output only. Additional information about the current state of the trust, if available.

=item * C<< $msg->last_trust_heartbeat_time() >> / C<< $msg->last_trust_heartbeat_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last heartbeat time when the trust was known to be connected.

=back

=head3 Enum: Trust::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<UPDATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<CONNECTED> => C<4>

=item * C<DISCONNECTED> => C<5>

=back

=head3 Enum: Trust::TrustType

=over 4

=item * C<TRUST_TYPE_UNSPECIFIED> => C<0>

=item * C<FOREST> => C<1>

=item * C<EXTERNAL> => C<2>

=back

=head3 Enum: Trust::TrustDirection

=over 4

=item * C<TRUST_DIRECTION_UNSPECIFIED> => C<0>

=item * C<INBOUND> => C<1>

=item * C<OUTBOUND> => C<2>

=item * C<BIDIRECTIONAL> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Managedidentities::V1::Resource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
