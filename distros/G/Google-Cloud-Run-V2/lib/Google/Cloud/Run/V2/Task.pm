package Google::Cloud::Run::V2::Task;

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
    eval { require Google::Cloud::Run::V2::Condition };
    eval { require Google::Cloud::Run::V2::K8sMin };
    eval { require Google::Cloud::Run::V2::Sandbox };
    eval { require Google::Cloud::Run::V2::VendorSettings };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ch5nb29nbGUvY2xvdWQvcnVuL3YyL3Rhc2sucHJvdG8SE2dvb2dsZS5jbG91ZC5ydW4udjIa
HGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3Rv
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGiNnb29nbGUvY2xvdWQvcnVuL3YyL2NvbmRpdGlvbi5wcm90bxohZ29vZ2xlL2Ns
b3VkL3J1bi92Mi9rOHMubWluLnByb3RvGiFnb29nbGUvY2xvdWQvcnVuL3YyL3NhbmRib3gu
cHJvdG8aKWdvb2dsZS9jbG91ZC9ydW4vdjIvdmVuZG9yX3NldHRpbmdzLnByb3RvGh5nb29n
bGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIkUKDkdldFRhc2tSZXF1ZXN0EjMKBG5h
bWUYASABKAlCH+BBAvpBGQoXcnVuLmdvb2dsZWFwaXMuY29tL1Rhc2tSBG5hbWUiqgEKEExp
c3RUYXNrc1JlcXVlc3QSNwoGcGFyZW50GAEgASgJQh/gQQL6QRkSF3J1bi5nb29nbGVhcGlz
LmNvbS9UYXNrUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdl
X3Rva2VuGAMgASgJUglwYWdlVG9rZW4SIQoMc2hvd19kZWxldGVkGAQgASgIUgtzaG93RGVs
ZXRlZCJsChFMaXN0VGFza3NSZXNwb25zZRIvCgV0YXNrcxgBIAMoCzIZLmdvb2dsZS5jbG91
ZC5ydW4udjIuVGFza1IFdGFza3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuIrASCgRUYXNrEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRIVCgN1aWQYAiABKAlC
A+BBA1IDdWlkEiMKCmdlbmVyYXRpb24YAyABKANCA+BBA1IKZ2VuZXJhdGlvbhJCCgZsYWJl
bHMYBCADKAsyJS5nb29nbGUuY2xvdWQucnVuLnYyLlRhc2suTGFiZWxzRW50cnlCA+BBA1IG
bGFiZWxzElEKC2Fubm90YXRpb25zGAUgAygLMiouZ29vZ2xlLmNsb3VkLnJ1bi52Mi5UYXNr
LkFubm90YXRpb25zRW50cnlCA+BBA1ILYW5ub3RhdGlvbnMSQAoLY3JlYXRlX3RpbWUYBiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSRgoOc2No
ZWR1bGVkX3RpbWUYIiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDXNj
aGVkdWxlZFRpbWUSPgoKc3RhcnRfdGltZRgbIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IJc3RhcnRUaW1lEkgKD2NvbXBsZXRpb25fdGltZRgHIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IOY29tcGxldGlvblRpbWUSQAoLdXBkYXRlX3Rp
bWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
QAoLZGVsZXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmRlbGV0ZVRpbWUSQAoLZXhwaXJlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCmV4cGlyZVRpbWUSMAoDam9iGAwgASgJQh7gQQP6QRgKFnJ1bi5nb29n
bGVhcGlzLmNvbS9Kb2JSA2pvYhJCCglleGVjdXRpb24YDSABKAlCJOBBA/pBHgoccnVuLmdv
b2dsZWFwaXMuY29tL0V4ZWN1dGlvblIJZXhlY3V0aW9uEj4KCmNvbnRhaW5lcnMYDiADKAsy
Hi5nb29nbGUuY2xvdWQucnVuLnYyLkNvbnRhaW5lclIKY29udGFpbmVycxJHCglzYW5kYm94
ZXMYKCABKAsyKS5nb29nbGUuY2xvdWQucnVuLnYyLlNhbmRib3hDb25maWd1cmF0aW9uUglz
YW5kYm94ZXMSNQoHdm9sdW1lcxgPIAMoCzIbLmdvb2dsZS5jbG91ZC5ydW4udjIuVm9sdW1l
Ugd2b2x1bWVzEh8KC21heF9yZXRyaWVzGBAgASgFUgptYXhSZXRyaWVzEjMKB3RpbWVvdXQY
ESABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SB3RpbWVvdXQSJwoPc2VydmljZV9h
Y2NvdW50GBIgASgJUg5zZXJ2aWNlQWNjb3VudBJeChVleGVjdXRpb25fZW52aXJvbm1lbnQY
FCABKA4yKS5nb29nbGUuY2xvdWQucnVuLnYyLkV4ZWN1dGlvbkVudmlyb25tZW50UhRleGVj
dXRpb25FbnZpcm9ubWVudBIlCgtyZWNvbmNpbGluZxgVIAEoCEID4EEDUgtyZWNvbmNpbGlu
ZxJDCgpjb25kaXRpb25zGBYgAygLMh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5Db25kaXRpb25C
A+BBA1IKY29uZGl0aW9ucxI0ChNvYnNlcnZlZF9nZW5lcmF0aW9uGBcgASgDQgPgQQNSEm9i
c2VydmVkR2VuZXJhdGlvbhIZCgVpbmRleBgYIAEoBUID4EEDUgVpbmRleBIdCgdyZXRyaWVk
GBkgASgFQgPgQQNSB3JldHJpZWQSWwoTbGFzdF9hdHRlbXB0X3Jlc3VsdBgaIAEoCzImLmdv
b2dsZS5jbG91ZC5ydW4udjIuVGFza0F0dGVtcHRSZXN1bHRCA+BBA1IRbGFzdEF0dGVtcHRS
ZXN1bHQSUAoOZW5jcnlwdGlvbl9rZXkYHCABKAlCKeBBA/pBIwohY2xvdWRrbXMuZ29vZ2xl
YXBpcy5jb20vQ3J5cHRvS2V5Ug1lbmNyeXB0aW9uS2V5EkIKCnZwY19hY2Nlc3MYHSABKAsy
Hi5nb29nbGUuY2xvdWQucnVuLnYyLlZwY0FjY2Vzc0ID4EEDUgl2cGNBY2Nlc3MSHAoHbG9n
X3VyaRggIAEoCUID4EEDUgZsb2dVcmkSKAoNc2F0aXNmaWVzX3B6cxghIAEoCEID4EEDUgxz
YXRpc2ZpZXNQenMSSwoNbm9kZV9zZWxlY3RvchgkIAEoCzIhLmdvb2dsZS5jbG91ZC5ydW4u
djIuTm9kZVNlbGVjdG9yQgPgQQNSDG5vZGVTZWxlY3RvchJOCh1ncHVfem9uYWxfcmVkdW5k
YW5jeV9kaXNhYmxlZBglIAEoCEIG4EEB4EEDSABSGmdwdVpvbmFsUmVkdW5kYW5jeURpc2Fi
bGVkiAEBEmoKGHdvcmtsb2FkX2lkZW50aXR5X2NvbmZpZxgmIAEoCzIrLmdvb2dsZS5jbG91
ZC5ydW4udjIuV29ya2xvYWRJZGVudGl0eUNvbmZpZ0ID4EEBUhZ3b3JrbG9hZElkZW50aXR5
Q29uZmlnEhcKBGV0YWcYYyABKAlCA+BBA1IEZXRhZxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj4KEEFubm90YXRpb25zRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATp36kF0Chdy
dW4uZ29vZ2xlYXBpcy5jb20vVGFzaxJWcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2pvYnMve2pvYn0vZXhlY3V0aW9ucy97ZXhlY3V0aW9ufS90YXNrcy97dGFz
a31SAQFCIAoeX2dwdV96b25hbF9yZWR1bmRhbmN5X2Rpc2FibGVkIowBChFUYXNrQXR0ZW1w
dFJlc3VsdBIvCgZzdGF0dXMYASABKAsyEi5nb29nbGUucnBjLlN0YXR1c0ID4EEDUgZzdGF0
dXMSIAoJZXhpdF9jb2RlGAIgASgFQgPgQQNSCGV4aXRDb2RlEiQKC3Rlcm1fc2lnbmFsGAMg
ASgFQgPgQQNSCnRlcm1TaWduYWwy6AMKBVRhc2tzEpcBCgdHZXRUYXNrEiMuZ29vZ2xlLmNs
b3VkLnJ1bi52Mi5HZXRUYXNrUmVxdWVzdBoZLmdvb2dsZS5jbG91ZC5ydW4udjIuVGFzayJM
gtPkkwI/Ej0vdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyovZXhlY3V0
aW9ucy8qL3Rhc2tzLyp92kEEbmFtZRKqAQoJTGlzdFRhc2tzEiUuZ29vZ2xlLmNsb3VkLnJ1
bi52Mi5MaXN0VGFza3NSZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5MaXN0VGFza3NS
ZXNwb25zZSJOgtPkkwI/Ej0vdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pv
YnMvKi9leGVjdXRpb25zLyp9L3Rhc2tz2kEGcGFyZW50GpcBykEScnVuLmdvb2dsZWFwaXMu
Y29t0kF/aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxo
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3J1bixodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL3J1bi5yZWFkb25seUJRChdjb20uZ29vZ2xlLmNsb3VkLnJ1bi52MkIJ
VGFza1Byb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vcnVuL2FwaXYyL3J1bnBiO3J1bnBi
Sq1XCgcSBQ4ArAIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
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
EAAcCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYALQoJCgIDBRIDFwArCgkKAgMGEgMYACsKCQoCAwcSAxkAMwoJCgIDCBIDGgAoCgkKAgMJ
EgMbACkKCQoCAwoSAxwAIQoICgEIEgMeAEAKCQoCCAsSAx4AQAoICgEIEgMfACIKCQoCCAoS
Ax8AIgoICgEIEgMgACoKCQoCCAgSAyAAKgoICgEIEgMhADAKCQoCCAESAyEAMAovCgIGABIE
JAA6ARojIENsb3VkIFJ1biBUYXNrIENvbnRyb2wgUGxhbmUgQVBJLgoKCgoDBgABEgMkCA0K
CgoDBgADEgMlAjoKDAoFBgADmQgSAyUCOgoLCgMGAAMSBCYCKTUKDQoFBgADmggSBCYCKTUK
LgoEBgACABIELAIxAxogIEdldHMgaW5mb3JtYXRpb24gYWJvdXQgYSBUYXNrLgoKDAoFBgAC
AAESAywGDQoMCgUGAAIAAhIDLA4cCgwKBQYAAgADEgMsJysKDQoFBgACAAQSBC0ELwYKEQoJ
BgACAASwyrwiEgQtBC8GCgwKBQYAAgAEEgMwBDIKDwoIBgACAASbCAASAzAEMgo3CgQGAAIB
EgQ0AjkDGikgTGlzdHMgVGFza3MgZnJvbSBhbiBFeGVjdXRpb24gb2YgYSBKb2IuCgoMCgUG
AAIBARIDNAYPCgwKBQYAAgECEgM0ECAKDAoFBgACAQMSAzQrPAoNCgUGAAIBBBIENQQ3BgoR
CgkGAAIBBLDKvCISBDUENwYKDAoFBgACAQQSAzgENAoPCggGAAIBBJsIABIDOAQ0CkQKAgQA
EgQ9AEUBGjggUmVxdWVzdCBtZXNzYWdlIGZvciBvYnRhaW5pbmcgYSBUYXNrIGJ5IGl0cyBm
dWxsIG5hbWUuCgoKCgMEAAESAz0IFgqWAQoEBAACABIEQQJEBBqHASBSZXF1aXJlZC4gVGhl
IGZ1bGwgbmFtZSBvZiB0aGUgVGFzay4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9qb2JzL3tqb2J9L2V4ZWN1dGlvbnMve2V4ZWN1dGlvbn0v
dGFza3Mve3Rhc2t9CgoMCgUEAAIABRIDQQIICgwKBQQAAgABEgNBCQ0KDAoFBAACAAMSA0EQ
EQoNCgUEAAIACBIEQRJEAwoPCggEAAIACJwIABIDQgQqCg4KBwQAAgAInwgSA0MESQo9CgIE
ARIESABbARoxIFJlcXVlc3QgbWVzc2FnZSBmb3IgcmV0cmlldmluZyBhIGxpc3Qgb2YgVGFz
a3MuCgoKCgMEAQESA0gIGAqxAgoEBAECABIETQJQBBqiAiBSZXF1aXJlZC4gVGhlIEV4ZWN1
dGlvbiBmcm9tIHdoaWNoIHRoZSBUYXNrcyBzaG91bGQgYmUgbGlzdGVkLgogVG8gbGlzdCBh
bGwgVGFza3MgYWNyb3NzIEV4ZWN1dGlvbnMgb2YgYSBKb2IsIHVzZSAiLSIgaW5zdGVhZCBv
ZiBFeGVjdXRpb24KIG5hbWUuIFRvIGxpc3QgYWxsIFRhc2tzIGFjcm9zcyBKb2JzLCB1c2Ug
Ii0iIGluc3RlYWQgb2YgSm9iIG5hbWUuIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9qb2JzL3tqb2J9L2V4ZWN1dGlvbnMve2V4ZWN1dGlvbn0K
CgwKBQQBAgAFEgNNAggKDAoFBAECAAESA00JDwoMCgUEAQIAAxIDTRITCg0KBQQBAgAIEgRN
FFADCg8KCAQBAgAInAgAEgNOBCoKDgoHBAECAAifCBIDTwRPCj4KBAQBAgESA1MCFhoxIE1h
eGltdW0gbnVtYmVyIG9mIFRhc2tzIHRvIHJldHVybiBpbiB0aGlzIGNhbGwuCgoMCgUEAQIB
BRIDUwIHCgwKBQQBAgEBEgNTCBEKDAoFBAECAQMSA1MUFQppCgQEAQICEgNXAhgaXCBBIHBh
Z2UgdG9rZW4gcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGNhbGwgdG8gTGlzdFRhc2tzLgog
QWxsIG90aGVyIHBhcmFtZXRlcnMgbXVzdCBtYXRjaC4KCgwKBQQBAgIFEgNXAggKDAoFBAEC
AgESA1cJEwoMCgUEAQICAxIDVxYXClkKBAQBAgMSA1oCGBpMIElmIHRydWUsIHJldHVybnMg
ZGVsZXRlZCAoYnV0IHVuZXhwaXJlZCkgcmVzb3VyY2VzIGFsb25nIHdpdGggYWN0aXZlIG9u
ZXMuCgoMCgUEAQIDBRIDWgIGCgwKBQQBAgMBEgNaBxMKDAoFBAECAwMSA1oWFwo6CgIEAhIE
XgBlARouIFJlc3BvbnNlIG1lc3NhZ2UgY29udGFpbmluZyBhIGxpc3Qgb2YgVGFza3MuCgoK
CgMEAgESA14IGQorCgQEAgIAEgNgAhoaHiBUaGUgcmVzdWx0aW5nIGxpc3Qgb2YgVGFza3Mu
CgoMCgUEAgIABBIDYAIKCgwKBQQCAgAGEgNgCw8KDAoFBAICAAESA2AQFQoMCgUEAgIAAxID
YBgZCnkKBAQCAgESA2QCHRpsIEEgdG9rZW4gaW5kaWNhdGluZyB0aGVyZSBhcmUgbW9yZSBp
dGVtcyB0aGFuIHBhZ2Vfc2l6ZS4gVXNlIGl0IGluIHRoZSBuZXh0CiBMaXN0VGFza3MgcmVx
dWVzdCB0byBjb250aW51ZS4KCgwKBQQCAgEFEgNkAggKDAoFBAICAQESA2QJGAoMCgUEAgIB
AxIDZBscCkkKAgQDEgVoAJcCARo8IFRhc2sgcmVwcmVzZW50cyBhIHNpbmdsZSBydW4gb2Yg
YSBjb250YWluZXIgdG8gY29tcGxldGlvbi4KCgoKAwQDARIDaAgMCgsKAwQDBxIEaQJtBAoN
CgUEAwedCBIEaQJtBAo5CgQEAwIAEgNwAj4aLCBPdXRwdXQgb25seS4gVGhlIHVuaXF1ZSBu
YW1lIG9mIHRoaXMgVGFzay4KCgwKBQQDAgAFEgNwAggKDAoFBAMCAAESA3AJDQoMCgUEAwIA
AxIDcBARCgwKBQQDAgAIEgNwEj0KDwoIBAMCAAicCAASA3ATPAqsAQoEBAMCARIDdQI9Gp4B
IE91dHB1dCBvbmx5LiBTZXJ2ZXIgYXNzaWduZWQgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRo
ZSBUYXNrLiBUaGUgdmFsdWUgaXMgYQogVVVJRDQgc3RyaW5nIGFuZCBndWFyYW50ZWVkIHRv
IHJlbWFpbiB1bmNoYW5nZWQgdW50aWwgdGhlIHJlc291cmNlIGlzCiBkZWxldGVkLgoKDAoF
BAMCAQUSA3UCCAoMCgUEAwIBARIDdQkMCgwKBQQDAgEDEgN1DxAKDAoFBAMCAQgSA3URPAoP
CggEAwIBCJwIABIDdRI7CnIKBAQDAgISA3kCQxplIE91dHB1dCBvbmx5LiBBIG51bWJlciB0
aGF0IG1vbm90b25pY2FsbHkgaW5jcmVhc2VzIGV2ZXJ5IHRpbWUgdGhlIHVzZXIKIG1vZGlm
aWVzIHRoZSBkZXNpcmVkIHN0YXRlLgoKDAoFBAMCAgUSA3kCBwoMCgUEAwICARIDeQgSCgwK
BQQDAgIDEgN5FRYKDAoFBAMCAggSA3kXQgoPCggEAwICCJwIABIDeRhBCrYDCgQEAwIDEgSB
AQJNGqcDIE91dHB1dCBvbmx5LiBVbnN0cnVjdHVyZWQga2V5IHZhbHVlIG1hcCB0aGF0IGNh
biBiZSB1c2VkIHRvIG9yZ2FuaXplIGFuZAogY2F0ZWdvcml6ZSBvYmplY3RzLiBVc2VyLXBy
b3ZpZGVkIGxhYmVscyBhcmUgc2hhcmVkIHdpdGggR29vZ2xlJ3MgYmlsbGluZwogc3lzdGVt
LCBzbyB0aGV5IGNhbiBiZSB1c2VkIHRvIGZpbHRlciwgb3IgYnJlYWsgZG93biBiaWxsaW5n
IGNoYXJnZXMgYnkKIHRlYW0sIGNvbXBvbmVudCwgZW52aXJvbm1lbnQsIHN0YXRlLCBldGMu
IEZvciBtb3JlIGluZm9ybWF0aW9uLCB2aXNpdAogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGluZy1tYW5hZ2luZy1sYWJlbHMgb3IKIGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9ydW4vZG9jcy9jb25maWd1cmluZy9sYWJlbHMKCg0K
BQQDAgMGEgSBAQIVCg0KBQQDAgMBEgSBARYcCg0KBQQDAgMDEgSBAR8gCg0KBQQDAgMIEgSB
ASFMChAKCAQDAgMInAgAEgSBASJLCscBCgQEAwIEEgaHAQKIATIatgEgT3V0cHV0IG9ubHku
IFVuc3RydWN0dXJlZCBrZXkgdmFsdWUgbWFwIHRoYXQgbWF5CiBiZSBzZXQgYnkgZXh0ZXJu
YWwgdG9vbHMgdG8gc3RvcmUgYW5kIGFyYml0cmFyeSBtZXRhZGF0YS4KIFRoZXkgYXJlIG5v
dCBxdWVyeWFibGUgYW5kIHNob3VsZCBiZSBwcmVzZXJ2ZWQKIHdoZW4gbW9kaWZ5aW5nIG9i
amVjdHMuCgoNCgUEAwIEBhIEhwECFQoNCgUEAwIEARIEhwEWIQoNCgUEAwIEAxIEhwEkJQoN
CgUEAwIECBIEiAEGMQoQCggEAwIECJwIABIEiAEHMAqtAQoEBAMCBRIGjQECjgEyGpwBIE91
dHB1dCBvbmx5LiBSZXByZXNlbnRzIHRpbWUgd2hlbiB0aGUgdGFzayB3YXMgY3JlYXRlZCBi
eSB0aGUgc3lzdGVtLgogSXQgaXMgbm90IGd1YXJhbnRlZWQgdG8gYmUgc2V0IGluIGhhcHBl
bnMtYmVmb3JlIG9yZGVyIGFjcm9zcyBzZXBhcmF0ZQogb3BlcmF0aW9ucy4KCg0KBQQDAgUG
EgSNAQIbCg0KBQQDAgUBEgSNARwnCg0KBQQDAgUDEgSNASorCg0KBQQDAgUIEgSOAQYxChAK
CAQDAgUInAgAEgSOAQcwCrYBCgQEAwIGEgaTAQKUATIapQEgT3V0cHV0IG9ubHkuIFJlcHJl
c2VudHMgdGltZSB3aGVuIHRoZSB0YXNrIHdhcyBzY2hlZHVsZWQgdG8gcnVuIGJ5IHRoZQog
c3lzdGVtLiBJdCBpcyBub3QgZ3VhcmFudGVlZCB0byBiZSBzZXQgaW4gaGFwcGVucy1iZWZv
cmUgb3JkZXIgYWNyb3NzCiBzZXBhcmF0ZSBvcGVyYXRpb25zLgoKDQoFBAMCBgYSBJMBAhsK
DQoFBAMCBgESBJMBHCoKDQoFBAMCBgMSBJMBLS8KDQoFBAMCBggSBJQBBjEKEAoIBAMCBgic
CAASBJQBBzAKogEKBAQDAgcSBpkBApoBMhqRASBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0
aW1lIHdoZW4gdGhlIHRhc2sgc3RhcnRlZCB0byBydW4uCiBJdCBpcyBub3QgZ3VhcmFudGVl
ZCB0byBiZSBzZXQgaW4gaGFwcGVucy1iZWZvcmUgb3JkZXIgYWNyb3NzIHNlcGFyYXRlCiBv
cGVyYXRpb25zLgoKDQoFBAMCBwYSBJkBAhsKDQoFBAMCBwESBJkBHCYKDQoFBAMCBwMSBJkB
KSsKDQoFBAMCBwgSBJoBBjEKEAoIBAMCBwicCAASBJoBBzAKoAEKBAQDAggSBp4BAp8BMhqP
ASBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0aW1lIHdoZW4gdGhlIFRhc2sgd2FzIGNvbXBs
ZXRlZC4gSXQgaXMgbm90CiBndWFyYW50ZWVkIHRvIGJlIHNldCBpbiBoYXBwZW5zLWJlZm9y
ZSBvcmRlciBhY3Jvc3Mgc2VwYXJhdGUgb3BlcmF0aW9ucy4KCg0KBQQDAggGEgSeAQIbCg0K
BQQDAggBEgSeARwrCg0KBQQDAggDEgSeAS4vCg0KBQQDAggIEgSfAQYxChAKCAQDAggInAgA
EgSfAQcwCjYKBAQDAgkSBqIBAqMBMhomIE91dHB1dCBvbmx5LiBUaGUgbGFzdC1tb2RpZmll
ZCB0aW1lLgoKDQoFBAMCCQYSBKIBAhsKDQoFBAMCCQESBKIBHCcKDQoFBAMCCQMSBKIBKisK
DQoFBAMCCQgSBKMBBjEKEAoIBAMCCQicCAASBKMBBzAKggEKBAQDAgoSBqcBAqgBMhpyIE91
dHB1dCBvbmx5LiBGb3IgYSBkZWxldGVkIHJlc291cmNlLCB0aGUgZGVsZXRpb24gdGltZS4g
SXQgaXMgb25seQogcG9wdWxhdGVkIGFzIGEgcmVzcG9uc2UgdG8gYSBEZWxldGUgcmVxdWVz
dC4KCg0KBQQDAgoGEgSnAQIbCg0KBQQDAgoBEgSnARwnCg0KBQQDAgoDEgSnASorCg0KBQQD
AgoIEgSoAQYxChAKCAQDAgoInAgAEgSoAQcwCqYBCgQEAwILEgatAQKuATIalQEgT3V0cHV0
IG9ubHkuIEZvciBhIGRlbGV0ZWQgcmVzb3VyY2UsIHRoZSB0aW1lIGFmdGVyIHdoaWNoIGl0
IHdpbGwgYmUKIHBlcm1hbWVudGx5IGRlbGV0ZWQuIEl0IGlzIG9ubHkgcG9wdWxhdGVkIGFz
IGEgcmVzcG9uc2UgdG8gYSBEZWxldGUKIHJlcXVlc3QuCgoNCgUEAwILBhIErQECGwoNCgUE
AwILARIErQEcJwoNCgUEAwILAxIErQEqLAoNCgUEAwILCBIErgEGMQoQCggEAwILCJwIABIE
rgEHMAo6CgQEAwIMEgaxAQK0AQQaKiBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIHBh
cmVudCBKb2IuCgoNCgUEAwIMBRIEsQECCAoNCgUEAwIMARIEsQEJDAoNCgUEAwIMAxIEsQEP
EQoPCgUEAwIMCBIGsQEStAEDChAKCAQDAgwInAgAEgSyAQQtCg8KBwQDAgwInwgSBLMBBEgK
QAoEBAMCDRIGtwECugEEGjAgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQg
RXhlY3V0aW9uLgoKDQoFBAMCDQUSBLcBAggKDQoFBAMCDQESBLcBCRIKDQoFBAMCDQMSBLcB
FRcKDwoFBAMCDQgSBrcBGLoBAwoQCggEAwINCJwIABIEuAEELQoPCgcEAwINCJ8IEgS5AQRO
Cl0KBAQDAg4SBL4BAiUaTyBIb2xkcyB0aGUgc2luZ2xlIGNvbnRhaW5lciB0aGF0IGRlZmlu
ZXMgdGhlIHVuaXQgb2YgZXhlY3V0aW9uIGZvciB0aGlzCiB0YXNrLgoKDQoFBAMCDgQSBL4B
AgoKDQoFBAMCDgYSBL4BCxQKDQoFBAMCDgESBL4BFR8KDQoFBAMCDgMSBL4BIiQKLAoEBAMC
DxIEwQECJhoeIENvbmZpZ3VyYXRpb24gZm9yIHNhbmRib3hlcy4KCg0KBQQDAg8GEgTBAQIW
Cg0KBQQDAg8BEgTBARcgCg0KBQQDAg8DEgTBASMlCkIKBAQDAhASBMQBAh8aNCBBIGxpc3Qg
b2YgVm9sdW1lcyB0byBtYWtlIGF2YWlsYWJsZSB0byBjb250YWluZXJzLgoKDQoFBAMCEAQS
BMQBAgoKDQoFBAMCEAYSBMQBCxEKDQoFBAMCEAESBMQBEhkKDQoFBAMCEAMSBMQBHB4KVAoE
BAMCERIExwECGRpGIE51bWJlciBvZiByZXRyaWVzIGFsbG93ZWQgcGVyIFRhc2ssIGJlZm9y
ZSBtYXJraW5nIHRoaXMgVGFzayBmYWlsZWQuCgoNCgUEAwIRBRIExwECBwoNCgUEAwIRARIE
xwEIEwoNCgUEAwIRAxIExwEWGAruAQoEBAMCEhIEzAECKBrfASBNYXggYWxsb3dlZCB0aW1l
IGR1cmF0aW9uIHRoZSBUYXNrIG1heSBiZSBhY3RpdmUgYmVmb3JlIHRoZSBzeXN0ZW0gd2ls
bAogYWN0aXZlbHkgdHJ5IHRvIG1hcmsgaXQgZmFpbGVkIGFuZCBraWxsIGFzc29jaWF0ZWQg
Y29udGFpbmVycy4gVGhpcyBhcHBsaWVzCiBwZXIgYXR0ZW1wdCBvZiBhIHRhc2ssIG1lYW5p
bmcgZWFjaCByZXRyeSBjYW4gcnVuIGZvciB0aGUgZnVsbCB0aW1lb3V0LgoKDQoFBAMCEgYS
BMwBAhoKDQoFBAMCEgESBMwBGyIKDQoFBAMCEgMSBMwBJScKmAIKBAQDAhMSBNIBAh4aiQIg
RW1haWwgYWRkcmVzcyBvZiB0aGUgSUFNIHNlcnZpY2UgYWNjb3VudCBhc3NvY2lhdGVkIHdp
dGggdGhlIFRhc2sgb2YgYQogSm9iLiBUaGUgc2VydmljZSBhY2NvdW50IHJlcHJlc2VudHMg
dGhlIGlkZW50aXR5IG9mIHRoZQogcnVubmluZyB0YXNrLCBhbmQgZGV0ZXJtaW5lcyB3aGF0
IHBlcm1pc3Npb25zIHRoZSB0YXNrIGhhcy4gSWYKIG5vdCBwcm92aWRlZCwgdGhlIHRhc2sg
d2lsbCB1c2UgdGhlIHByb2plY3QncyBkZWZhdWx0IHNlcnZpY2UgYWNjb3VudC4KCg0KBQQD
AhMFEgTSAQIICg0KBQQDAhMBEgTSAQkYCg0KBQQDAhMDEgTSARsdCkcKBAQDAhQSBNUBAjIa
OSBUaGUgZXhlY3V0aW9uIGVudmlyb25tZW50IGJlaW5nIHVzZWQgdG8gaG9zdCB0aGlzIFRh
c2suCgoNCgUEAwIUBhIE1QECFgoNCgUEAwIUARIE1QEXLAoNCgUEAwIUAxIE1QEvMQrKAQoE
BAMCFRIE2gECRBq7ASBPdXRwdXQgb25seS4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIHJlc291
cmNlJ3MgcmVjb25jaWxpYXRpb24gaXMgc3RpbGwgaW4KIHByb2dyZXNzLiBTZWUgY29tbWVu
dHMgaW4gYEpvYi5yZWNvbmNpbGluZ2AgZm9yIGFkZGl0aW9uYWwgaW5mb3JtYXRpb24gb24K
IHJlY29uY2lsaWF0aW9uIHByb2Nlc3MgaW4gQ2xvdWQgUnVuLgoKDQoFBAMCFQUSBNoBAgYK
DQoFBAMCFQESBNoBBxIKDQoFBAMCFQMSBNoBFRcKDQoFBAMCFQgSBNoBGEMKEAoIBAMCFQic
CAASBNoBGUIKqAEKBAQDAhYSBt4BAt8BMhqXASBPdXRwdXQgb25seS4gVGhlIENvbmRpdGlv
biBvZiB0aGlzIFRhc2ssIGNvbnRhaW5pbmcgaXRzIHJlYWRpbmVzcyBzdGF0dXMsCiBhbmQg
ZGV0YWlsZWQgZXJyb3IgaW5mb3JtYXRpb24gaW4gY2FzZSBpdCBkaWQgbm90IHJlYWNoIHRo
ZSBkZXNpcmVkIHN0YXRlLgoKDQoFBAMCFgQSBN4BAgoKDQoFBAMCFgYSBN4BCxQKDQoFBAMC
FgESBN4BFR8KDQoFBAMCFgMSBN4BIiQKDQoFBAMCFggSBN8BBjEKEAoIBAMCFgicCAASBN8B
BzAKoAEKBAQDAhcSBOMBAk0akQEgT3V0cHV0IG9ubHkuIFRoZSBnZW5lcmF0aW9uIG9mIHRo
aXMgVGFzay4gU2VlIGNvbW1lbnRzIGluIGBKb2IucmVjb25jaWxpbmdgCiBmb3IgYWRkaXRp
b25hbCBpbmZvcm1hdGlvbiBvbiByZWNvbmNpbGlhdGlvbiBwcm9jZXNzIGluIENsb3VkIFJ1
bi4KCg0KBQQDAhcFEgTjAQIHCg0KBQQDAhcBEgTjAQgbCg0KBQQDAhcDEgTjAR4gCg0KBQQD
AhcIEgTjASFMChAKCAQDAhcInAgAEgTjASJLClkKBAQDAhgSBOYBAj8aSyBPdXRwdXQgb25s
eS4gSW5kZXggb2YgdGhlIFRhc2ssIHVuaXF1ZSBwZXIgZXhlY3V0aW9uLCBhbmQgYmVnaW5u
aW5nIGF0IDAuCgoNCgUEAwIYBRIE5gECBwoNCgUEAwIYARIE5gEIDQoNCgUEAwIYAxIE5gEQ
EgoNCgUEAwIYCBIE5gETPgoQCggEAwIYCJwIABIE5gEUPQqFAQoEBAMCGRIE6gECQRp3IE91
dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIHRpbWVzIHRoaXMgVGFzayB3YXMgcmV0cmllZC4K
IFRhc2tzIGFyZSByZXRyaWVkIHdoZW4gdGhleSBmYWlsIHVwIHRvIHRoZSBtYXhSZXRyaWVz
IGxpbWl0LgoKDQoFBAMCGQUSBOoBAgcKDQoFBAMCGQESBOoBCA8KDQoFBAMCGQMSBOoBEhQK
DQoFBAMCGQgSBOoBFUAKEAoIBAMCGQicCAASBOoBFj8KRwoEBAMCGhIG7QEC7gEyGjcgT3V0
cHV0IG9ubHkuIFJlc3VsdCBvZiB0aGUgbGFzdCBhdHRlbXB0IG9mIHRoaXMgVGFzay4KCg0K
BQQDAhoGEgTtAQITCg0KBQQDAhoBEgTtARQnCg0KBQQDAhoDEgTtASosCg0KBQQDAhoIEgTu
AQYxChAKCAQDAhoInAgAEgTuAQcwCtMBCgQEAwIbEgbzAQL4AQQawgEgT3V0cHV0IG9ubHku
IEEgcmVmZXJlbmNlIHRvIGEgY3VzdG9tZXIgbWFuYWdlZCBlbmNyeXB0aW9uIGtleSAoQ01F
SykgdG8gdXNlCiB0byBlbmNyeXB0IHRoaXMgY29udGFpbmVyIGltYWdlLiBGb3IgbW9yZSBp
bmZvcm1hdGlvbiwgZ28gdG8KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9ydW4vZG9jcy9z
ZWN1cmluZy91c2luZy1jbWVrCgoNCgUEAwIbBRIE8wECCAoNCgUEAwIbARIE8wEJFwoNCgUE
AwIbAxIE8wEaHAoPCgUEAwIbCBIG8wEd+AEDChAKCAQDAhsInAgAEgT0AQQtChEKBwQDAhsI
nwgSBvUBBPcBBQqoAQoEBAMCHBIE/QECSBqZASBPdXRwdXQgb25seS4gVlBDIEFjY2VzcyBj
b25maWd1cmF0aW9uIHRvIHVzZSBmb3IgdGhpcyBUYXNrLiBGb3IgbW9yZQogaW5mb3JtYXRp
b24sIHZpc2l0CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcnVuL2RvY3MvY29uZmlndXJp
bmcvY29ubmVjdGluZy12cGMuCgoNCgUEAwIcBhIE/QECCwoNCgUEAwIcARIE/QEMFgoNCgUE
AwIcAxIE/QEZGwoNCgUEAwIcCBIE/QEcRwoQCggEAwIcCJwIABIE/QEdRgpeCgQEAwIdEgSB
AgJCGlAgT3V0cHV0IG9ubHkuIFVSSSB3aGVyZSBsb2dzIGZvciB0aGlzIGV4ZWN1dGlvbiBj
YW4gYmUgZm91bmQgaW4gQ2xvdWQKIENvbnNvbGUuCgoNCgUEAwIdBRIEgQICCAoNCgUEAwId
ARIEgQIJEAoNCgUEAwIdAxIEgQITFQoNCgUEAwIdCBIEgQIWQQoQCggEAwIdCJwIABIEgQIX
QAo1CgQEAwIeEgSEAgJGGicgT3V0cHV0IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNl
LgoKDQoFBAMCHgUSBIQCAgYKDQoFBAMCHgESBIQCBxQKDQoFBAMCHgMSBIQCFxkKDQoFBAMC
HggSBIQCGkUKEAoIBAMCHgicCAASBIQCG0QKPAoEBAMCHxIEhwICThouIE91dHB1dCBvbmx5
LiBUaGUgbm9kZSBzZWxlY3RvciBmb3IgdGhlIHRhc2suCgoNCgUEAwIfBhIEhwICDgoNCgUE
AwIfARIEhwIPHAoNCgUEAwIfAxIEhwIfIQoNCgUEAwIfCBIEhwIiTQoQCggEAwIfCJwIABIE
hwIjTApgCgQEAwIgEgaLAgKOAgQaUCBPcHRpb25hbC4gT3V0cHV0IG9ubHkuIFRydWUgaWYg
R1BVIHpvbmFsIHJlZHVuZGFuY3kgaXMgZGlzYWJsZWQgb24gdGhpcwogdGFzay4KCg0KBQQD
AiAEEgSLAgIKCg0KBQQDAiAFEgSLAgsPCg0KBQQDAiABEgSLAhAtCg0KBQQDAiADEgSLAjAy
Cg8KBQQDAiAIEgaLAjOOAgMKEAoIBAMCIAicCAASBIwCBCoKEAoIBAMCIAicCAESBI0CBC0K
QgoEBAMCIRIGkQICkgIvGjIgT3B0aW9uYWwuIFRoZSBUYXNrJ3Mgd29ya2xvYWQgaWRlbnRp
dHkgc2V0dGluZ3MuCgoNCgUEAwIhBhIEkQICGAoNCgUEAwIhARIEkQIZMQoNCgUEAwIhAxIE
kQI0NgoNCgUEAwIhCBIEkgIGLgoQCggEAwIhCJwIABIEkgIHLQqbAQoEBAMCIhIElgICPxqM
ASBPdXRwdXQgb25seS4gQSBzeXN0ZW0tZ2VuZXJhdGVkIGZpbmdlcnByaW50IGZvciB0aGlz
IHZlcnNpb24gb2YgdGhlCiByZXNvdXJjZS4gTWF5IGJlIHVzZWQgdG8gZGV0ZWN0IG1vZGlm
aWNhdGlvbiBjb25mbGljdCBkdXJpbmcgdXBkYXRlcy4KCg0KBQQDAiIFEgSWAgIICg0KBQQD
AiIBEgSWAgkNCg0KBQQDAiIDEgSWAhASCg0KBQQDAiIIEgSWAhM+ChAKCAQDAiIInAgAEgSW
AhQ9CikKAgQEEgaaAgCsAgEaGyBSZXN1bHQgb2YgYSB0YXNrIGF0dGVtcHQuCgoLCgMEBAES
BJoCCBkKbwoEBAQCABIEnQICSxphIE91dHB1dCBvbmx5LiBUaGUgc3RhdHVzIG9mIHRoaXMg
YXR0ZW1wdC4KIElmIHRoZSBzdGF0dXMgY29kZSBpcyBPSywgdGhlbiB0aGUgYXR0ZW1wdCBz
dWNjZWVkZWQuCgoNCgUEBAIABhIEnQICEwoNCgUEBAIAARIEnQIUGgoNCgUEBAIAAxIEnQId
HgoNCgUEBAIACBIEnQIfSgoQCggEBAIACJwIABIEnQIgSQqKAgoEBAQCARIEpQICQhr7ASBP
dXRwdXQgb25seS4gVGhlIGV4aXQgY29kZSBvZiB0aGlzIGF0dGVtcHQuCiBUaGlzIG1heSBi
ZSB1bnNldCBpZiB0aGUgY29udGFpbmVyIHdhcyB1bmFibGUgdG8gZXhpdCBjbGVhbmx5IHdp
dGggYSBjb2RlCiBkdWUgdG8gc29tZSBvdGhlciBmYWlsdXJlLgogU2VlIHN0YXR1cyBmaWVs
ZCBmb3IgcG9zc2libGUgZmFpbHVyZSBkZXRhaWxzLgoKIEF0IG1vc3Qgb25lIG9mIGV4aXRf
Y29kZSBvciB0ZXJtX3NpZ25hbCB3aWxsIGJlIHNldC4KCg0KBQQEAgEFEgSlAgIHCg0KBQQE
AgEBEgSlAggRCg0KBQQEAgEDEgSlAhQVCg0KBQQEAgEIEgSlAhZBChAKCAQEAgEInAgAEgSl
AhdACsABCgQEBAICEgSrAgJEGrEBIE91dHB1dCBvbmx5LiBUZXJtaW5hdGlvbiBzaWduYWwg
b2YgdGhlIGNvbnRhaW5lci4gVGhpcyBpcyBzZXQgdG8gbm9uLXplcm8KIGlmIHRoZSBjb250
YWluZXIgaXMgdGVybWluYXRlZCBieSB0aGUgc3lzdGVtLgoKIEF0IG1vc3Qgb25lIG9mIGV4
aXRfY29kZSBvciB0ZXJtX3NpZ25hbCB3aWxsIGJlIHNldC4KCg0KBQQEAgIFEgSrAgIHCg0K
BQQEAgIBEgSrAggTCg0KBQQEAgIDEgSrAhYXCg0KBQQEAgIIEgSrAhhDChAKCAQEAgIInAgA
EgSrAhlCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::Task::GetTaskRequest ===
    # Fields for GetTaskRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Run::V2::Task::ListTasksRequest ===
    # Fields for ListTasksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: show_deleted Type: 8 ()

# === Message: Google::Cloud::Run::V2::Task::ListTasksResponse ===
    # Fields for ListTasksResponse
    # Field: tasks Type: 11 (.google.cloud.run.v2.Task)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Run::V2::Task::Task ===
    # Fields for Task
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: generation Type: 3 ()
    # Field: labels Type: 11 (.google.cloud.run.v2.Task.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.run.v2.Task.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: scheduled_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: completion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: job Type: 9 ()
    # Field: execution Type: 9 ()
    # Field: containers Type: 11 (.google.cloud.run.v2.Container)
    # Field: sandboxes Type: 11 (.google.cloud.run.v2.SandboxConfiguration)
    # Field: volumes Type: 11 (.google.cloud.run.v2.Volume)
    # Field: max_retries Type: 5 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: service_account Type: 9 ()
    # Field: execution_environment Type: 14 (.google.cloud.run.v2.ExecutionEnvironment)
    # Field: reconciling Type: 8 ()
    # Field: conditions Type: 11 (.google.cloud.run.v2.Condition)
    # Field: observed_generation Type: 3 ()
    # Field: index Type: 5 ()
    # Field: retried Type: 5 ()
    # Field: last_attempt_result Type: 11 (.google.cloud.run.v2.TaskAttemptResult)
    # Field: encryption_key Type: 9 ()
    # Field: vpc_access Type: 11 (.google.cloud.run.v2.VpcAccess)
    # Field: log_uri Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: node_selector Type: 11 (.google.cloud.run.v2.NodeSelector)
    # Field: gpu_zonal_redundancy_disabled Type: 8 ()
    # Field: workload_identity_config Type: 11 (.google.cloud.run.v2.WorkloadIdentityConfig)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Run::V2::Task::TaskAttemptResult ===
    # Fields for TaskAttemptResult
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: exit_code Type: 5 ()
    # Field: term_signal Type: 5 ()

# === Service Client: Google::Cloud::Run::V2::Task::TasksClient ===
package Google::Cloud::Run::V2::Task::TasksClient;

=pod

=head2 Service Client: Google::Cloud::Run::V2::Task::TasksClient

Client stub representing the remote C<Tasks> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<run.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'run.googleapis.com:443' );

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

sub get_task {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Task::GetTaskRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Tasks',
        method         => 'GetTask',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Task::Task',
    });
}

sub list_tasks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Task::ListTasksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Tasks',
        method         => 'ListTasks',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Task::ListTasksResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::Task - Compiled Protocol Buffers messages for google/cloud/run/v2/task.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::Task;

    my $msg = Google::Cloud::Run::V2::Task::GetTaskRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::Task::GetTaskRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::Task::GetTaskRequest

Request message for obtaining a Task by its full name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full name of the Task.
Format:
projects/{project}/locations/{location}/jobs/{job}/executions/{execution}/tasks/{task}

=back

=head2 Google::Cloud::Run::V2::Task::ListTasksRequest

Request message for retrieving a list of Tasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Execution from which the Tasks should be listed.
To list all Tasks across Executions of a Job, use "-" instead of Execution
name. To list all Tasks across Jobs, use "-" instead of Job name. Format:
projects/{project}/locations/{location}/jobs/{job}/executions/{execution}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of Tasks to return in this call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token received from a previous call to ListTasks.
All other parameters must match.

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

If true, returns deleted (but unexpired) resources along with active ones.

=back

=head2 Google::Cloud::Run::V2::Task::ListTasksResponse

Response message containing a list of Tasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tasks() >> / C<< $msg->tasks($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Task::Task>)

The resulting list of Tasks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token indicating there are more items than page_size. Use it in the next
ListTasks request to continue.

=back

=head2 Google::Cloud::Run::V2::Task::Task

Task represents a single run of a container to completion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique name of this Task.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the Task. The value is a
UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->generation() >> / C<< $msg->generation($value) >>

Type: C<Int64>

Output only. A number that monotonically increases every time the user
modifies the desired state.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Task::Task::LabelsEntry>)

Output only. Unstructured key value map that can be used to organize and
categorize objects. User-provided labels are shared with Google's billing
system, so they can be used to filter, or break down billing charges by
team, component, environment, state, etc. For more information, visit
https://cloud.google.com/resource-manager/docs/creating-managing-labels or
https://cloud.google.com/run/docs/configuring/labels

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Task::Task::AnnotationsEntry>)

Output only. Unstructured key value map that may
be set by external tools to store and arbitrary metadata.
They are not queryable and should be preserved
when modifying objects.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the task was created by the system.
It is not guaranteed to be set in happens-before order across separate
operations.

=item * C<< $msg->scheduled_time() >> / C<< $msg->scheduled_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the task was scheduled to run by the
system. It is not guaranteed to be set in happens-before order across
separate operations.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the task started to run.
It is not guaranteed to be set in happens-before order across separate
operations.

=item * C<< $msg->completion_time() >> / C<< $msg->completion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the Task was completed. It is not
guaranteed to be set in happens-before order across separate operations.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. For a deleted resource, the deletion time. It is only
populated as a response to a Delete request.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. For a deleted resource, the time after which it will be
permamently deleted. It is only populated as a response to a Delete
request.

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<String>

Output only. The name of the parent Job.

=item * C<< $msg->execution() >> / C<< $msg->execution($value) >>

Type: C<String>

Output only. The name of the parent Execution.

=item * C<< $msg->containers() >> / C<< $msg->containers($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Container>)

Holds the single container that defines the unit of execution for this
task.

=item * C<< $msg->sandboxes() >> / C<< $msg->sandboxes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Sandbox::SandboxConfiguration>)

Configuration for sandboxes.

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Volume>)

A list of Volumes to make available to containers.

=item * C<< $msg->max_retries() >> / C<< $msg->max_retries($value) >>

Type: C<Int32>

Number of retries allowed per Task, before marking this Task failed.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Max allowed time duration the Task may be active before the system will
actively try to mark it failed and kill associated containers. This applies
per attempt of a task, meaning each retry can run for the full timeout.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Email address of the IAM service account associated with the Task of a
Job. The service account represents the identity of the
running task, and determines what permissions the task has. If
not provided, the task will use the project's default service account.

=item * C<< $msg->execution_environment() >> / C<< $msg->execution_environment($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::ExecutionEnvironment>)

The execution environment being used to host this Task.

=item * C<< $msg->reconciling() >> / C<< $msg->reconciling($value) >>

Type: C<Bool>

Output only. Indicates whether the resource's reconciliation is still in
progress. See comments in `Job.reconciling` for additional information on
reconciliation process in Cloud Run.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Condition::Condition>)

Output only. The Condition of this Task, containing its readiness status,
and detailed error information in case it did not reach the desired state.

=item * C<< $msg->observed_generation() >> / C<< $msg->observed_generation($value) >>

Type: C<Int64>

Output only. The generation of this Task. See comments in `Job.reconciling`
for additional information on reconciliation process in Cloud Run.

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

Output only. Index of the Task, unique per execution, and beginning at 0.

=item * C<< $msg->retried() >> / C<< $msg->retried($value) >>

Type: C<Int32>

Output only. The number of times this Task was retried.
Tasks are retried when they fail up to the maxRetries limit.

=item * C<< $msg->last_attempt_result() >> / C<< $msg->last_attempt_result($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Task::TaskAttemptResult>)

Output only. Result of the last attempt of this Task.

=item * C<< $msg->encryption_key() >> / C<< $msg->encryption_key($value) >>

Type: C<String>

Output only. A reference to a customer managed encryption key (CMEK) to use
to encrypt this container image. For more information, go to
https://cloud.google.com/run/docs/securing/using-cmek

=item * C<< $msg->vpc_access() >> / C<< $msg->vpc_access($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::VpcAccess>)

Output only. VPC Access configuration to use for this Task. For more
information, visit
https://cloud.google.com/run/docs/configuring/connecting-vpc.

=item * C<< $msg->log_uri() >> / C<< $msg->log_uri($value) >>

Type: C<String>

Output only. URI where logs for this execution can be found in Cloud
Console.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->node_selector() >> / C<< $msg->node_selector($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::NodeSelector>)

Output only. The node selector for the task.

=item * C<< $msg->gpu_zonal_redundancy_disabled() >> / C<< $msg->gpu_zonal_redundancy_disabled($value) >>

Type: C<Bool>

Optional. Output only. True if GPU zonal redundancy is disabled on this
task.

=item * C<< $msg->workload_identity_config() >> / C<< $msg->workload_identity_config($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig>)

Optional. The Task's workload identity settings.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. A system-generated fingerprint for this version of the
resource. May be used to detect modification conflict during updates.

=back

=head2 Google::Cloud::Run::V2::Task::TaskAttemptResult

Result of a task attempt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The status of this attempt.
If the status code is OK, then the attempt succeeded.

=item * C<< $msg->exit_code() >> / C<< $msg->exit_code($value) >>

Type: C<Int32>

Output only. The exit code of this attempt.
This may be unset if the container was unable to exit cleanly with a code
due to some other failure.
See status field for possible failure details.

At most one of exit_code or term_signal will be set.

=item * C<< $msg->term_signal() >> / C<< $msg->term_signal($value) >>

Type: C<Int32>

Output only. Termination signal of the container. This is set to non-zero
if the container is terminated by the system.

At most one of exit_code or term_signal will be set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::Task::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
