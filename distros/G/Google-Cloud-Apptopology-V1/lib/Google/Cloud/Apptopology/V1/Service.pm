package Google::Cloud::Apptopology::V1::Service;

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
    eval { require Google::Cloud::Apptopology::V1::Graph };
    eval { require Google::Cloud::Apptopology::V1::Query };
    eval { require Google::Cloud::Apptopology::V1::Schema };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYXBwdG9wb2xvZ3kvdjEvc2VydmljZS5wcm90bxIbZ29vZ2xlLmNs
b3VkLmFwcHRvcG9sb2d5LnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL2FwcHRvcG9sb2d5L3Yx
L2dyYXBoLnByb3RvGidnb29nbGUvY2xvdWQvYXBwdG9wb2xvZ3kvdjEvcXVlcnkucHJvdG8a
KGdvb2dsZS9jbG91ZC9hcHB0b3BvbG9neS92MS9zY2hlbWEucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8i1QIKEU9wZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90
aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdl
bmRUaW1lEhsKBnRhcmdldBgDIAEoCUID4EEDUgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EED
UgR2ZXJiEioKDnN0YXR1c19tZXNzYWdlGAUgASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoW
cmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgGIAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRp
b24SJAoLYXBpX3ZlcnNpb24YByABKAlCA+BBA1IKYXBpVmVyc2lvbiKkAgoqR2VuZXJhdGVE
aXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3lSZXF1ZXN0EkMKBmZpbHRlchgDIAEoCzIpLmdv
b2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5HcmFwaFBhdHRlcm5IAFIGZmlsdGVyElIKBG5h
bWUYASABKAlCPuBBAvpBOAo2YXBwdG9wb2xvZ3kuZ29vZ2xlYXBpcy5jb20vRGlzY292ZXJl
ZFJlc291cmNlc1RvcG9sb2d5UgRuYW1lElQKEHRvcG9sb2d5X2RvbWFpbnMYAiADKAlCKeBB
AvpBIwohYXBwdG9wb2xvZ3kuZ29vZ2xlYXBpcy5jb20vRG9tYWluUg90b3BvbG9neURvbWFp
bnNCBwoFcXVlcnkiZworR2VuZXJhdGVEaXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3lSZXNw
b25zZRI4CgVncmFwaBgBIAEoCzIiLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5HcmFw
aFIFZ3JhcGgiUQoQR2V0U2NoZW1hUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWFw
cHRvcG9sb2d5Lmdvb2dsZWFwaXMuY29tL1NjaGVtYVIEbmFtZSLeAQoURXhwbG9yZVNjaGVt
YVJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFhcHB0b3BvbG9neS5nb29nbGVhcGlz
LmNvbS9TY2hlbWFSBG5hbWUSJgoMc3RhcnRfbGFiZWxzGAMgAygJQgPgQQFSC3N0YXJ0TGFi
ZWxzEhkKBWRlcHRoGAQgASgFQgPgQQFSBWRlcHRoEiAKCXBhZ2Vfc2l6ZRgFIAEoBUID4EEB
UghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAYgASgJQgPgQQFSCXBhZ2VUb2tlbiLqAgoVRXhw
bG9yZVNjaGVtYVJlc3BvbnNlEkQKCm5vZGVfdHlwZXMYASADKAsyJS5nb29nbGUuY2xvdWQu
YXBwdG9wb2xvZ3kudjEuTm9kZVR5cGVSCW5vZGVUeXBlcxJECgplZGdlX3R5cGVzGAIgAygL
MiUuZ29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5LnYxLkVkZ2VUeXBlUgllZGdlVHlwZXMSVwoQ
bGFiZWxfcHJvcGVydGllcxgDIAMoCzIsLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5M
YWJlbFByb3BlcnRpZXNSD2xhYmVsUHJvcGVydGllcxJECgplZGdlX3J1bGVzGAQgAygLMiUu
Z29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5LnYxLkVkZ2VSdWxlUgllZGdlUnVsZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAUgASgJUg1uZXh0UGFnZVRva2VuIlEKEEdldERvbWFpblJlcXVlc3QS
PQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFhcHB0b3BvbG9neS5nb29nbGVhcGlzLmNvbS9Eb21h
aW5SBG5hbWUinQEKEkxpc3REb21haW5zUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpB
IxIhYXBwdG9wb2xvZ3kuZ29vZ2xlYXBpcy5jb20vRG9tYWluUgZwYXJlbnQSIAoJcGFnZV9z
aXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFn
ZVRva2VuInwKE0xpc3REb21haW5zUmVzcG9uc2USPQoHZG9tYWlucxgBIAMoCzIjLmdvb2ds
ZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Eb21haW5SB2RvbWFpbnMSJgoPbmV4dF9wYWdlX3Rv
a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMq0JCgtBcHBUb3BvbG9neRKjAgojR2VuZXJhdGVE
aXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3kSRy5nb29nbGUuY2xvdWQuYXBwdG9wb2xvZ3ku
djEuR2VuZXJhdGVEaXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3lSZXF1ZXN0GkguZ29vZ2xl
LmNsb3VkLmFwcHRvcG9sb2d5LnYxLkdlbmVyYXRlRGlzY292ZXJlZFJlc291cmNlc1RvcG9s
b2d5UmVzcG9uc2UiaYLT5JMCSyJGL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGlzY292ZXJlZFJlc291cmNlc1RvcG9sb2d5fTpnZW5lcmF0ZToBKtpBFW5hbWUsdG9wb2xv
Z3lfZG9tYWlucxKiAQoJR2V0U2NoZW1hEi0uZ29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5LnYx
LkdldFNjaGVtYVJlcXVlc3QaIy5nb29nbGUuY2xvdWQuYXBwdG9wb2xvZ3kudjEuU2NoZW1h
IkGC0+STAjQSMi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RvbWFpbnMvKi9z
Y2hlbWF92kEEbmFtZRLEAQoNRXhwbG9yZVNjaGVtYRIxLmdvb2dsZS5jbG91ZC5hcHB0b3Bv
bG9neS52MS5FeHBsb3JlU2NoZW1hUmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9n
eS52MS5FeHBsb3JlU2NoZW1hUmVzcG9uc2UiTILT5JMCPyI6L3YxL3tuYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovZG9tYWlucy8qL3NjaGVtYX06ZXhwbG9yZToBKtpBBG5hbWUSmwEK
CUdldERvbWFpbhItLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5HZXREb21haW5SZXF1
ZXN0GiMuZ29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5LnYxLkRvbWFpbiI6gtPkkwItEisvdjEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kb21haW5zLyp92kEEbmFtZRKuAQoLTGlz
dERvbWFpbnMSLy5nb29nbGUuY2xvdWQuYXBwdG9wb2xvZ3kudjEuTGlzdERvbWFpbnNSZXF1
ZXN0GjAuZ29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5LnYxLkxpc3REb21haW5zUmVzcG9uc2Ui
PILT5JMCLRIrL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZG9tYWluc9pB
BnBhcmVudBq8AcpBGmFwcHRvcG9sb2d5Lmdvb2dsZWFwaXMuY29t0kGbAWh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvYXBwdG9wb2xvZ3kucmVhZC1vbmx5LGh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvYXBwdG9wb2xvZ3kucmVhZC13cml0ZSxodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQo4DCh9jb20uZ29vZ2xlLmNs
b3VkLmFwcHRvcG9sb2d5LnYxQgxTZXJ2aWNlUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9n
by9hcHB0b3BvbG9neS9hcGl2MS9hcHB0b3BvbG9neXBiO2FwcHRvcG9sb2d5cGKqAhtHb29n
bGUuQ2xvdWQuQXBwVG9wb2xvZ3kuVjHKAhtHb29nbGVcQ2xvdWRcQXBwVG9wb2xvZ3lcVjHq
Ah5Hb29nbGU6OkNsb3VkOjpBcHBUb3BvbG9neTo6VjHqQbkBCjZhcHB0b3BvbG9neS5nb29n
bGVhcGlzLmNvbS9EaXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3kSQ3Byb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kaXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3kq
HWRpc2NvdmVyZWRSZXNvdXJjZXNUb3BvbG9naWVzMhtkaXNjb3ZlcmVkUmVzb3VyY2VzVG9w
b2xvZ3lKv0wKBxIFDgCmAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACQKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJ
CgIDBBIDFgAxCgkKAgMFEgMXADEKCQoCAwYSAxgAMgoJCgIDBxIDGQApCggKAQgSAxsAOAoJ
CgIIJRIDGwA4CggKAQgSAxwAWAoJCgIICxIDHABYCggKAQgSAx0AIgoJCgIIChIDHQAiCggK
AQgSAx4ALQoJCgIICBIDHgAtCggKAQgSAx8AOAoJCgIIARIDHwA4CggKAQgSAyAAOAoJCgII
KRIDIAA4CggKAQgSAyEANwoJCgIILRIDIQA3CgkKAQgSBCIAJwIKDAoECJ0IABIEIgAnAgo3
CgIGABIEKgBlARorIFNlcnZpY2UgZGVzY3JpYmluZyBoYW5kbGVycyBmb3IgcmVzb3VyY2Vz
CgoKCgMGAAESAyoIEwoKCgMGAAMSAysCQgoMCgUGAAOZCBIDKwJCCgsKAwYAAxIELAIvNwoN
CgUGAAOaCBIELAIvNwr+AQoEBgACABIENgI+AxrvASBHZW5lcmF0ZSB0aGUgdG9wb2xvZ3kg
Zm9yIGFsbCByZXNvdXJjZXMgaW4gdGhlIGdpdmVuIHByb2plY3QuIElmIHRoZQogcHJvamVj
dCByZXByZXNlbnRzIGFuCiBbYXBwCiBib3VuZGFyeV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FwcC1odWIvZG9jcy9yZWZlcmVuY2UvcmVzdC92MS9Cb3VuZGFyeSksCiB0aGUgdG9w
b2xvZ3kgaXMgZ2VuZXJhdGVkIGZvciBhbGwgcmVzb3VyY2VzIGluIHRoZSBib3VuZGFyeS4K
CgwKBQYAAgABEgM2BikKDAoFBgACAAISAzcGMAoMCgUGAAIAAxIDOA86Cg0KBQYAAgAEEgQ5
BDwGChEKCQYAAgAEsMq8IhIEOQQ8BgoMCgUGAAIABBIDPQRDCg8KCAYAAgAEmwgAEgM9BEMK
3wEKBAYAAgESBEQCSQMa0AEgUmV0cmlldmVzIHRoZSBzY2hlbWEgZm9yIHRoZSBzcGVjaWZp
ZWQgdG9wb2xvZ3kgZG9tYWluLiBUaGUgc2NoZW1hCiBkZWZpbmVzIHRoZSBOb2RlVHlwZXMg
YW5kIEVkZ2VUeXBlcyB0aGF0IGFyZSBzdXBwb3J0ZWQgaW4KIEdlbmVyYXRlRGlzY292ZXJl
ZFJlc291cmNlc1RvcG9sb2d5IHJlcXVlc3RzIGFuZCByZXNwb25zZXMgZm9yIGEgZ2l2ZW4K
IGRvbWFpbi4KCgwKBQYAAgEBEgNEBg8KDAoFBgACAQISA0QQIAoMCgUGAAIBAxIDRCsxCg0K
BQYAAgEEEgRFBEcGChEKCQYAAgEEsMq8IhIERQRHBgoMCgUGAAIBBBIDSAQyCg8KCAYAAgEE
mwgAEgNIBDIKeAoEBgACAhIETQJTAxpqIEV4cGxvcmVzIHRoZSB0b3BvbG9neSBzY2hlbWEg
c3RhcnRpbmcgZnJvbSBnaXZlbiBub2RlIHR5cGVzIG9yIGxhYmVsIG5hbWVzCiB1cCB0byBh
IHNwZWNpZmllZCBob3AgZGVwdGguCgoMCgUGAAICARIDTQYTCgwKBQYAAgICEgNNFCgKDAoF
BgACAgMSA00zSAoNCgUGAAICBBIETgRRBgoRCgkGAAICBLDKvCISBE4EUQYKDAoFBgACAgQS
A1IEMgoPCggGAAICBJsIABIDUgQyCjgKBAYAAgMSBFYCWwMaKiBSZXRyaWV2ZXMgdGhlIHNw
ZWNpZmllZCB0b3BvbG9neSBkb21haW4uCgoMCgUGAAIDARIDVgYPCgwKBQYAAgMCEgNWECAK
DAoFBgACAwMSA1YrMQoNCgUGAAIDBBIEVwRZBgoRCgkGAAIDBLDKvCISBFcEWQYKDAoFBgAC
AwQSA1oEMgoPCggGAAIDBJsIABIDWgQyCnIKBAYAAgQSBF8CZAMaZCBMaXN0cyB0aGUgdG9w
b2xvZ3kgZG9tYWlucyBhdmFpbGFibGUgaW4gYSBzcGVjaWZpYyBsb2NhdGlvbi4KIE9ubHkg
YGdsb2JhbGAgbG9jYXRpb24gaXMgc3VwcG9ydGVkLgoKDAoFBgACBAESA18GEQoMCgUGAAIE
AhIDXxIkCgwKBQYAAgQDEgNfL0IKDQoFBgACBAQSBGAEYgYKEQoJBgACBASwyrwiEgRgBGIG
CgwKBQYAAgQEEgNjBDQKDwoIBgACBASbCAASA2MENApFCgIEABIFaACEAQEaOCBSZXByZXNl
bnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQA
ARIDaAgZCkAKBAQAAgASBGoCazIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJh
dGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgAGEgNqAhsKDAoFBAACAAESA2ocJwoMCgUEAAIA
AxIDaiorCgwKBQQAAgAIEgNrBjEKDwoIBAACAAicCAASA2sHMApFCgQEAAIBEgRuAm8yGjcg
T3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4K
CgwKBQQAAgEGEgNuAhsKDAoFBAACAQESA24cJAoMCgUEAAIBAxIDbicoCgwKBQQAAgEIEgNv
BjEKDwoIBAACAQicCAASA28HMApZCgQEAAICEgNyAkAaTCBPdXRwdXQgb25seS4gU2VydmVy
LWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9u
LgoKDAoFBAACAgUSA3ICCAoMCgUEAAICARIDcgkPCgwKBQQAAgIDEgNyEhMKDAoFBAACAggS
A3IUPwoPCggEAAICCJwIABIDchU+CkcKBAQAAgMSA3UCPho6IE91dHB1dCBvbmx5LiBOYW1l
IG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRIDdQII
CgwKBQQAAgMBEgN1CQ0KDAoFBAACAwMSA3UQEQoMCgUEAAIDCBIDdRI9Cg8KCAQAAgMInAgA
EgN1EzwKSwoEBAACBBIDeAJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1
cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoMCgUEAAIEBRIDeAIICgwKBQQAAgQBEgN4
CRcKDAoFBAACBAMSA3gaGwoMCgUEAAIECBIDeBxHCg8KCAQAAgQInAgAEgN4HUYK0wIKBAQA
AgUSBIABAk4axAIgT3V0cHV0IG9ubHkuIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNlciBo
YXMgcmVxdWVzdGVkIGNhbmNlbGxhdGlvbgogb2YgdGhlIG9wZXJhdGlvbi4gT3BlcmF0aW9u
cyB0aGF0IGhhdmUgYmVlbiBjYW5jZWxsZWQgc3VjY2Vzc2Z1bGx5CiBoYXZlCiBbZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbi5lcnJvcl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbi5lcnJvcl0KIHZhbHVlIHdpdGggYSBbZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV1bZ29v
Z2xlLnJwYy5TdGF0dXMuY29kZV0gb2YgYDFgLAogY29ycmVzcG9uZGluZyB0byBgQ29kZS5D
QU5DRUxMRURgLgoKDQoFBAACBQUSBIABAgYKDQoFBAACBQESBIABBx0KDQoFBAACBQMSBIAB
ICEKDQoFBAACBQgSBIABIk0KEAoIBAACBQicCAASBIABI0wKRQoEBAACBhIEgwECRRo3IE91
dHB1dCBvbmx5LiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRpb24uCgoN
CgUEAAIGBRIEgwECCAoNCgUEAAIGARIEgwEJFAoNCgUEAAIGAxIEgwEXGAoNCgUEAAIGCBIE
gwEZRAoQCggEAAIGCJwIABIEgwEaQwpACgIEARIGhwEApQEBGjIgUmVxdWVzdCBmb3IgR2Vu
ZXJhdGVEaXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3kuCgoLCgMEAQESBIcBCDIKZgoEBAEI
ABIGigECjwEDGlYgUXVlcnkgdGhlIHRvcG9sb2d5IGJ5IGJ1aWxkaW5nIGEgZ3JhcGggcGF0
dGVybiBmaWx0ZXIgb3IgcHJlLWRlZmluZWQKIHRvcG9sb2d5IHZpZXcuCgoNCgUEAQgAARIE
igEIDQrjAQoEBAECABIEjgEEHBrUASBGaWx0ZXJzIGZvciB0aGUgdG9wb2xvZ3kgbm9kZXMg
YW5kIGVkZ2VzOyBEZXRhaWwgZm9ybWF0IHNlZSBHcmFwaFBhdHRlcm4KIHByb3RvLiBBIHNl
cGFyYXRlICdMb29rdXBTY2hlbWEnIG1ldGhvZCB3aWxsIGJlIGFkZGVkIHRoYXQgd2lsbCBy
ZXR1cm4KIHRoZSBuZWNlc3NhcnkgaW5mb3JtYXRpb24gdG8gYmUgYWJsZSB0byBjb25zdHJ1
Y3QgdGhlc2UgZmlsdGVycy4KCg0KBQQBAgAGEgSOAQQQCg0KBQQBAgABEgSOAREXCg0KBQQB
AgADEgSOARobCswBCgQEAQIBEgaVAQKaAQQauwEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0IHRv
IHF1ZXJ5IGRpc2NvdmVyYWJsZSByZXNvdXJjZXMgb24uCiBFeHBlY3RlZCBmb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Rpc2NvdmVyZWRSZXNv
dXJjZXNUb3BvbG9neWAuCiBPbmx5IGBnbG9iYWxgIGxvY2F0aW9uIGlzIHN1cHBvcnRlZC4K
Cg0KBQQBAgEFEgSVAQIICg0KBQQBAgEBEgSVAQkNCg0KBQQBAgEDEgSVARARCg8KBQQBAgEI
EgaVARKaAQMKEAoIBAECAQicCAASBJYBBCoKEQoHBAECAQifCBIGlwEEmQEFCucBCgQEAQIC
EgafAQKkAQQa1gEgUmVxdWlyZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIGRv
bWFpbiBvZiB0aGUgYXBwIHRvcG9sb2d5LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2RvbWFpbnMve2RvbWFpbn1gCiBDYWxsZXIgbXVzdCBo
YXZlIGFwcHRvcG9sb2d5LmRvbWFpbnMuZ2V0IHBlcm1pc3Npb24gb24gZWFjaCBvZiB0aGUg
ZG9tYWlucy4KCg0KBQQBAgIEEgSfAQIKCg0KBQQBAgIFEgSfAQsRCg0KBQQBAgIBEgSfARIi
Cg0KBQQBAgIDEgSfASUmCg8KBQQBAgIIEgafASekAQMKEAoIBAECAgicCAASBKABBCoKEQoH
BAECAgifCBIGoQEEowEFCkEKAgQCEgaoAQCrAQEaMyBSZXNwb25zZSBmb3IgR2VuZXJhdGVE
aXNjb3ZlcmVkUmVzb3VyY2VzVG9wb2xvZ3kuCgoLCgMEAgESBKgBCDMKLQoEBAICABIEqgEC
EhofIFRoZSBnZW5lcmF0ZWQgdG9wb2xvZ3kgZ3JhcGguCgoNCgUEAgIABhIEqgECBwoNCgUE
AgIAARIEqgEIDQoNCgUEAgIAAxIEqgEQEQomCgIEAxIGrgEAtwEBGhggUmVxdWVzdCBmb3Ig
R2V0U2NoZW1hLgoKCwoDBAMBEgSuAQgYCpkBCgQEAwIAEgaxAQK2AQQaiAEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBzaW5nbGV0b24gZG9tYWluIHNjaGVtYSByZXNvdXJjZS4KIEZv
cm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb21haW5z
L3tkb21haW59L3NjaGVtYWAKCg0KBQQDAgAFEgSxAQIICg0KBQQDAgABEgSxAQkNCg0KBQQD
AgADEgSxARARCg8KBQQDAgAIEgaxARK2AQMKEAoIBAMCAAicCAASBLIBBCoKEQoHBAMCAAif
CBIGswEEtQEFCioKAgQEEga6AQDgAQEaHCBSZXF1ZXN0IGZvciBFeHBsb3JlU2NoZW1hLgoK
CwoDBAQBEgS6AQgcCpkBCgQEBAIAEga9AQLCAQQaiAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBzaW5nbGV0b24gZG9tYWluIHNjaGVtYSByZXNvdXJjZS4KIEZvcm1hdDogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb21haW5zL3tkb21haW59L3Nj
aGVtYWAKCg0KBQQEAgAFEgS9AQIICg0KBQQEAgABEgS9AQkNCg0KBQQEAgADEgS9ARARCg8K
BQQEAgAIEga9ARLCAQMKEAoIBAQCAAicCAASBL4BBCoKEQoHBAQCAAifCBIGvwEEwQEFCvIC
CgQEBAIBEgTKAQJMGuMCIE9wdGlvbmFsLiBTdGFydGluZyBsYWJlbCBuYW1lcyB0byBiZWdp
biB0cmF2ZXJzYWwuCiBTdWJzdHJpbmcsIGNhc2UtaW5zZW5zaXRpdmUgbWF0Y2hlcyBhcmUg
cGVyZm9ybWVkIGFnYWluc3QgYWxsb3dlZCBsYWJlbAogbmFtZXMgaW4gdGhlIHNjaGVtYS4g
QSBtYXhpbXVtIG9mIDEwIGBzdGFydF9sYWJlbHNgIGNhbiBiZSBzcGVjaWZpZWQ7CiBwcm92
aWRpbmcgbW9yZSB3aWxsIHJlc3VsdCBpbiBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3Iu
CiBJZiBgc3RhcnRfbGFiZWxzYCBpcyB1bnNldCBvciBlbXB0eSwgYWxsIGF1dGhvcml6ZWQg
bm9kZSB0eXBlcyB3aWxsIGJlIHVzZWQKIGFzIHRoZSBzdGFydGluZyBzZXQuCgoNCgUEBAIB
BBIEygECCgoNCgUEBAIBBRIEygELEQoNCgUEBAIBARIEygESHgoNCgUEBAIBAxIEygEhIgoN
CgUEBAIBCBIEygEjSwoQCggEBAIBCJwIABIEygEkSgqZAQoEBAQCAhIEzgECOxqKASBPcHRp
b25hbC4gVGhlIG1heGltdW0gZGVwdGggb2YgQkZTIHRyYXZlcnNhbCBob3BzIHRvIHBlcmZv
cm0gZnJvbSB0aGUKIHN0YXJ0aW5nIG5vZGUgdHlwZXMgb3IgbGFiZWwgbmFtZXMuIERlZmF1
bHRzIHRvIDAgaWYgdW5zcGVjaWZpZWQuCgoNCgUEBAICBRIEzgECBwoNCgUEBAICARIEzgEI
DQoNCgUEBAICAxIEzgEQEQoNCgUEBAICCBIEzgESOgoQCggEBAICCJwIABIEzgETOQrFAwoE
BAQCAxIE2AECPxq2AyBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHNjaGVtYSBl
bGVtZW50cyB0byByZXR1cm4gaW4gYSBzaW5nbGUgcGFnZS4KCiAtIFRoZSBzZXJ2aWNlIG1p
Z2h0IHJldHVybiBmZXdlciBlbGVtZW50cyB0aGFuIHRoaXMgdmFsdWUgaWYgYWRkaW5nIGFu
b3RoZXIKICAgZWRnZSBhbmQgaXRzIHJlcXVpcmVkIGVuZHBvaW50IG5vZGVzIGV4Y2VlZHMg
YHBhZ2Vfc2l6ZWAuCiAtIElmIG9taXR0ZWQgb3Igc2V0IHRvIDAsIGRlZmF1bHQgKDEwMCkg
d2lsbCBiZSB1c2VkLgogLSBNaW5pbXVtIHBhZ2Vfc2l6ZSBpcyAzIHRvIGVuc3VyZSBhdCBs
ZWFzdCBvbmUgZWRnZSBhbmQgaXRzIGVuZHBvaW50CiAgIG5vZGVzIGZpdCBvbiBhIHBhZ2U7
IHZhbHVlcyBiZWxvdyAzIChlLmcuIDEgb3IgMikgYXJlIGNoYW5nZWQgdG8gMy4KIC0gTWF4
aW11bSB2YWx1ZSBpcyA1MDAuCgoNCgUEBAIDBRIE2AECBwoNCgUEBAIDARIE2AEIEQoNCgUE
BAIDAxIE2AEUFQoNCgUEBAIDCBIE2AEWPgoQCggEBAIDCJwIABIE2AEXPQqPAgoEBAQCBBIE
3wECQRqAAiBPcHRpb25hbC4gQSBwYWdlIHRva2VuIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91
cyBgRXhwbG9yZVNjaGVtYWAgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUg
c3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRl
cnMgKGV4Y2VwdCBwYWdlX3NpemUpIHByb3ZpZGVkIHRvCiBgRXhwbG9yZVNjaGVtYWAgbXVz
dCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAQC
BAUSBN8BAggKDQoFBAQCBAESBN8BCRMKDQoFBAQCBAMSBN8BFhcKDQoFBAQCBAgSBN8BGEAK
EAoIBAQCBAicCAASBN8BGT8KKwoCBAUSBuMBAPcBARodIFJlc3BvbnNlIGZvciBFeHBsb3Jl
U2NoZW1hLgoKCwoDBAUBEgTjAQgdCn0KBAQFAgASBOYBAiMabyBBIGxpc3Qgb2YgYE5vZGVU
eXBlYHMgZGVmaW5lZCB3aXRoaW4gdGhpcyBzY2hlbWEuCiBSZWZlciB0byB0aGUgZG9jdW1l
bnRhdGlvbiBvZiBgTm9kZVR5cGVgIGZvciBtb3JlIGRldGFpbHMuCgoNCgUEBQIABBIE5gEC
CgoNCgUEBQIABhIE5gELEwoNCgUEBQIAARIE5gEUHgoNCgUEBQIAAxIE5gEhIgp9CgQEBQIB
EgTqAQIjGm8gQSBsaXN0IG9mIGBFZGdlVHlwZWBzIGRlZmluZWQgd2l0aGluIHRoaXMgc2No
ZW1hLgogUmVmZXIgdG8gdGhlIGRvY3VtZW50YXRpb24gb2YgYEVkZ2VUeXBlYCBmb3IgbW9y
ZSBkZXRhaWxzLgoKDQoFBAUCAQQSBOoBAgoKDQoFBAUCAQYSBOoBCxMKDQoFBAUCAQESBOoB
FB4KDQoFBAUCAQMSBOoBISIKSAoEBAUCAhIE7QECMBo6IEEgbGlzdCBvZiBzdXBwb3J0ZWQg
bGFiZWxzIGFuZCBjb3JyZXNwb25kaW5nIHByb3BlcnRpZXMuCgoNCgUEBQICBBIE7QECCgoN
CgUEBQICBhIE7QELGgoNCgUEBQICARIE7QEbKwoNCgUEBQICAxIE7QEuLwq/AQoEBAUCAxIE
8gECIxqwASBFZGdlIHJ1bGVzLiBUaGVzZSB3aWxsIGluZGljYXRlIHdoaWNoIG5vZGUgdHlw
ZXMgY2FuIGJlIGNvbm5lY3RlZCBhbmQKIHRocm91Z2ggd2hhdCBlZGdlIHR5cGUuIFRoaXMg
aXMgYSBsaXN0IG9mIChzb3VyY2Vfbm9kZV90eXBlLCBlZGdlX3R5cGUsCiBkZXN0aW5hdGlv
bl9ub2RlX3R5cGUpIHR1cGxlcy4KCg0KBQQFAgMEEgTyAQIKCg0KBQQFAgMGEgTyAQsTCg0K
BQQFAgMBEgTyARQeCg0KBQQFAgMDEgTyASEiCnoKBAQFAgQSBPYBAh0abCBBIHRva2VuIHRv
IHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUg
YXJlIG5vCiBtb3JlIHJlc3VsdHMgaW4gdGhlIHRyYXZlcnNhbCBzZXQuCgoNCgUEBQIEBRIE
9gECCAoNCgUEBQIEARIE9gEJGAoNCgUEBQIEAxIE9gEbHAomCgIEBhIG+gEAgwIBGhggUmVx
dWVzdCBmb3IgR2V0RG9tYWluLgoKCwoDBAYBEgT6AQgYCoMBCgQEBgIAEgb9AQKCAgQacyBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGRvbWFpbiB0byByZXRyaWV2ZS4KIEZvcm1hdDog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb21haW5zL3tkb21h
aW59YAoKDQoFBAYCAAUSBP0BAggKDQoFBAYCAAESBP0BCQ0KDQoFBAYCAAMSBP0BEBEKDwoF
BAYCAAgSBv0BEoICAwoQCggEBgIACJwIABIE/gEEKgoRCgcEBgIACJ8IEgb/AQSBAgUKKAoC
BAcSBoYCAJwCARoaIFJlcXVlc3QgZm9yIExpc3REb21haW5zLgoKCwoDBAcBEgSGAggaCp4B
CgQEBwIAEgaKAgKPAgQajQEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgbG9jYXRpb24gdG8gbGlz
dCBkb21haW5zIGZvci4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufWAKIE9ubHkgYGdsb2JhbGAgbG9jYXRpb24gaXMgc3VwcG9ydGVkLgoKDQoF
BAcCAAUSBIoCAggKDQoFBAcCAAESBIoCCQ8KDQoFBAcCAAMSBIoCEhMKDwoFBAcCAAgSBooC
FI8CAwoQCggEBwIACJwIABIEiwIEKgoRCgcEBwIACJ8IEgaMAgSOAgUK7gEKBAQHAgESBJQC
Aj8a3wEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBkb21haW5zIHRvIHJldHVy
bi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJZiB1
bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBkb21haW5zIHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUg
bWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJj
ZWQgdG8gMTAwMC4KCg0KBQQHAgEFEgSUAgIHCg0KBQQHAgEBEgSUAggRCg0KBQQHAgEDEgSU
AhQVCg0KBQQHAgEIEgSUAhY+ChAKCAQHAgEInAgAEgSUAhc9CvkBCgQEBwICEgSbAgJBGuoB
IE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlz
dERvbWFpbnNgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVl
bnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3Zp
ZGVkIHRvIGBMaXN0RG9tYWluc2AgbXVzdCBtYXRjaAogdGhlIGNhbGwgdGhhdCBwcm92aWRl
ZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQHAgIFEgSbAgIICg0KBQQHAgIBEgSbAgkTCg0KBQQH
AgIDEgSbAhYXCg0KBQQHAgIIEgSbAhhAChAKCAQHAgIInAgAEgSbAhk/CikKAgQIEgafAgCm
AgEaGyBSZXNwb25zZSBmb3IgTGlzdERvbWFpbnMuCgoLCgMECAESBJ8CCBsKNgoEBAgCABIE
oQICHhooIFRoZSBkb21haW5zIGluIHRoZSBzcGVjaWZpZWQgbG9jYXRpb24uCgoNCgUECAIA
BBIEoQICCgoNCgUECAIABhIEoQILEQoNCgUECAIAARIEoQISGQoNCgUECAIAAxIEoQIcHQqN
AQoEBAgCARIEpQICHRp/IEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tl
bmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRl
ZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUECAIBBRIEpQICCAoNCgUE
CAIBARIEpQIJGAoNCgUECAIBAxIEpQIbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apptopology::V1::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest ===
    # Fields for GenerateDiscoveredResourcesTopologyRequest
    # Field: filter Type: 11 (.google.cloud.apptopology.v1.GraphPattern)
    # Field: name Type: 9 ()
    # Field: topology_domains Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse ===
    # Fields for GenerateDiscoveredResourcesTopologyResponse
    # Field: graph Type: 11 (.google.cloud.apptopology.v1.Graph)

# === Message: Google::Cloud::Apptopology::V1::Service::GetSchemaRequest ===
    # Fields for GetSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::ExploreSchemaRequest ===
    # Fields for ExploreSchemaRequest
    # Field: name Type: 9 ()
    # Field: start_labels Type: 9 ()
    # Field: depth Type: 5 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::ExploreSchemaResponse ===
    # Fields for ExploreSchemaResponse
    # Field: node_types Type: 11 (.google.cloud.apptopology.v1.NodeType)
    # Field: edge_types Type: 11 (.google.cloud.apptopology.v1.EdgeType)
    # Field: label_properties Type: 11 (.google.cloud.apptopology.v1.LabelProperties)
    # Field: edge_rules Type: 11 (.google.cloud.apptopology.v1.EdgeRule)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::GetDomainRequest ===
    # Fields for GetDomainRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::ListDomainsRequest ===
    # Fields for ListDomainsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Service::ListDomainsResponse ===
    # Fields for ListDomainsResponse
    # Field: domains Type: 11 (.google.cloud.apptopology.v1.Domain)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Apptopology::V1::Service::AppTopologyClient ===
package Google::Cloud::Apptopology::V1::Service::AppTopologyClient;

=pod

=head2 Service Client: Google::Cloud::Apptopology::V1::Service::AppTopologyClient

Client stub representing the remote C<AppTopology> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apptopology.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apptopology.googleapis.com:443' );

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

sub generate_discovered_resources_topology {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'GenerateDiscoveredResourcesTopology',
        request        => $req,
        response_class => 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse',
    });
}

sub get_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apptopology::V1::Service::GetSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'GetSchema',
        request        => $req,
        response_class => 'Google::Cloud::Apptopology::V1::Schema::Schema',
    });
}

sub explore_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apptopology::V1::Service::ExploreSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'ExploreSchema',
        request        => $req,
        response_class => 'Google::Cloud::Apptopology::V1::Service::ExploreSchemaResponse',
    });
}

sub get_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apptopology::V1::Service::GetDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'GetDomain',
        request        => $req,
        response_class => 'Google::Cloud::Apptopology::V1::Schema::Domain',
    });
}

sub list_domains {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apptopology::V1::Service::ListDomainsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'ListDomains',
        request        => $req,
        response_class => 'Google::Cloud::Apptopology::V1::Service::ListDomainsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apptopology::V1::Service - Compiled Protocol Buffers messages for google/cloud/apptopology/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apptopology::V1::Service;

    my $msg = Google::Cloud::Apptopology::V1::Service::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apptopology::V1::Service::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apptopology/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apptopology::V1::Service::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of `1`,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest

Request for GenerateDiscoveredResourcesTopology.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::GraphPattern>)

Filters for the topology nodes and edges; Detail format see GraphPattern
proto. A separate 'LookupSchema' method will be added that will return
the necessary information to be able to construct these filters.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The project to query discoverable resources on.
Expected format:
`projects/{project}/locations/{location}/discoveredResourcesTopology`.
Only `global` location is supported.

=item * C<< $msg->topology_domains() >> / C<< $msg->topology_domains($value) >>

Type: C<String>

Required. The full resource name of the domain of the app topology.
Format: `projects/{project}/locations/{location}/domains/{domain}`
Caller must have apptopology.domains.get permission on each of the domains.

=back

=head2 Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse

Response for GenerateDiscoveredResourcesTopology.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->graph() >> / C<< $msg->graph($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Graph::Graph>)

The generated topology graph.

=back

=head2 Google::Cloud::Apptopology::V1::Service::GetSchemaRequest

Request for GetSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the singleton domain schema resource.
Format: `projects/{project}/locations/{location}/domains/{domain}/schema`

=back

=head2 Google::Cloud::Apptopology::V1::Service::ExploreSchemaRequest

Request for ExploreSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the singleton domain schema resource.
Format: `projects/{project}/locations/{location}/domains/{domain}/schema`

=item * C<< $msg->start_labels() >> / C<< $msg->start_labels($value) >>

Type: C<String>

Optional. Starting label names to begin traversal.
Substring, case-insensitive matches are performed against allowed label
names in the schema. A maximum of 10 `start_labels` can be specified;
providing more will result in an `INVALID_ARGUMENT` error.
If `start_labels` is unset or empty, all authorized node types will be used
as the starting set.

=item * C<< $msg->depth() >> / C<< $msg->depth($value) >>

Type: C<Int32>

Optional. The maximum depth of BFS traversal hops to perform from the
starting node types or label names. Defaults to 0 if unspecified.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of schema elements to return in a single page.

- The service might return fewer elements than this value if adding another
  edge and its required endpoint nodes exceeds `page_size`.
- If omitted or set to 0, default (100) will be used.
- Minimum page_size is 3 to ensure at least one edge and its endpoint
  nodes fit on a page; values below 3 (e.g. 1 or 2) are changed to 3.
- Maximum value is 500.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token received from a previous `ExploreSchema` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters (except page_size) provided to
`ExploreSchema` must match the call that provided the page token.

=back

=head2 Google::Cloud::Apptopology::V1::Service::ExploreSchemaResponse

Response for ExploreSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_types() >> / C<< $msg->node_types($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::NodeType>)

A list of `NodeType`s defined within this schema.
Refer to the documentation of `NodeType` for more details.

=item * C<< $msg->edge_types() >> / C<< $msg->edge_types($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::EdgeType>)

A list of `EdgeType`s defined within this schema.
Refer to the documentation of `EdgeType` for more details.

=item * C<< $msg->label_properties() >> / C<< $msg->label_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::LabelProperties>)

A list of supported labels and corresponding properties.

=item * C<< $msg->edge_rules() >> / C<< $msg->edge_rules($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::EdgeRule>)

Edge rules. These will indicate which node types can be connected and
through what edge type. This is a list of (source_node_type, edge_type,
destination_node_type) tuples.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results, or empty if there are no
more results in the traversal set.

=back

=head2 Google::Cloud::Apptopology::V1::Service::GetDomainRequest

Request for GetDomain.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the domain to retrieve.
Format: `projects/{project}/locations/{location}/domains/{domain}`

=back

=head2 Google::Cloud::Apptopology::V1::Service::ListDomainsRequest

Request for ListDomains.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location to list domains for.
Format: `projects/{project}/locations/{location}`
Only `global` location is supported.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of domains to return. The service may return
fewer than this value. If unspecified, at most 50 domains will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListDomains` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListDomains` must match
the call that provided the page token.

=back

=head2 Google::Cloud::Apptopology::V1::Service::ListDomainsResponse

Response for ListDomains.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->domains() >> / C<< $msg->domains($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::Domain>)

The domains in the specified location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apptopology::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
