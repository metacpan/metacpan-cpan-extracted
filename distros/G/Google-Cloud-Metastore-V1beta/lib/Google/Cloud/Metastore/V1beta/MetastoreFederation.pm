package Google::Cloud::Metastore::V1beta::MetastoreFederation;

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
    eval { require Google::Cloud::Metastore::V1beta::Metastore };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvbWV0YXN0b3JlL3YxYmV0YS9tZXRhc3RvcmVfZmVkZXJhdGlvbi5w
cm90bxIdZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWJldGEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xv
dWQvbWV0YXN0b3JlL3YxYmV0YS9tZXRhc3RvcmUucHJvdG8aI2dvb2dsZS9sb25ncnVubmlu
Zy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2ds
ZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIrwHCgpGZWRlcmF0aW9uEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRJACgtjcmVh
dGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKdXBkYXRlVGltZRJNCgZsYWJlbHMYBCADKAsyNS5nb29nbGUuY2xvdWQubWV0YXN0
b3JlLnYxYmV0YS5GZWRlcmF0aW9uLkxhYmVsc0VudHJ5UgZsYWJlbHMSHQoHdmVyc2lvbhgF
IAEoCUID4EEFUgd2ZXJzaW9uEm8KEmJhY2tlbmRfbWV0YXN0b3JlcxgGIAMoCzJALmdvb2ds
ZS5jbG91ZC5tZXRhc3RvcmUudjFiZXRhLkZlZGVyYXRpb24uQmFja2VuZE1ldGFzdG9yZXNF
bnRyeVIRYmFja2VuZE1ldGFzdG9yZXMSJgoMZW5kcG9pbnRfdXJpGAcgASgJQgPgQQNSC2Vu
ZHBvaW50VXJpEkoKBXN0YXRlGAggASgOMi8uZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWJl
dGEuRmVkZXJhdGlvbi5TdGF0ZUID4EEDUgVzdGF0ZRIoCg1zdGF0ZV9tZXNzYWdlGAkgASgJ
QgPgQQNSDHN0YXRlTWVzc2FnZRIVCgN1aWQYCiABKAlCA+BBA1IDdWlkGjkKC0xhYmVsc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEadQoWQmFj
a2VuZE1ldGFzdG9yZXNFbnRyeRIQCgNrZXkYASABKAVSA2tleRJFCgV2YWx1ZRgCIAEoCzIv
Lmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjFiZXRhLkJhY2tlbmRNZXRhc3RvcmVSBXZhbHVl
OgI4ASJfCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCgoG
QUNUSVZFEAISDAoIVVBEQVRJTkcQAxIMCghERUxFVElORxAEEgkKBUVSUk9SEAU6aupBZwoj
bWV0YXN0b3JlLmdvb2dsZWFwaXMuY29tL0ZlZGVyYXRpb24SQHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9mZWRlcmF0aW9ucy97ZmVkZXJhdGlvbn0i8QEKEEJh
Y2tlbmRNZXRhc3RvcmUSEgoEbmFtZRgBIAEoCVIEbmFtZRJkCg5tZXRhc3RvcmVfdHlwZRgC
IAEoDjI9Lmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjFiZXRhLkJhY2tlbmRNZXRhc3RvcmUu
TWV0YXN0b3JlVHlwZVINbWV0YXN0b3JlVHlwZSJjCg1NZXRhc3RvcmVUeXBlEh4KGk1FVEFT
VE9SRV9UWVBFX1VOU1BFQ0lGSUVEEAASDAoIREFUQVBMRVgQARIMCghCSUdRVUVSWRACEhYK
EkRBVEFQUk9DX01FVEFTVE9SRRADIuABChZMaXN0RmVkZXJhdGlvbnNSZXF1ZXN0EkMKBnBh
cmVudBgBIAEoCUIr4EEC+kElEiNtZXRhc3RvcmUuZ29vZ2xlYXBpcy5jb20vRmVkZXJhdGlv
blIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rv
a2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVy
Eh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkisAEKF0xpc3RGZWRlcmF0aW9uc1Jl
c3BvbnNlEksKC2ZlZGVyYXRpb25zGAEgAygLMikuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52
MWJldGEuRmVkZXJhdGlvblILZmVkZXJhdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
Ug1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJXChRH
ZXRGZWRlcmF0aW9uUmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUKI21ldGFzdG9yZS5n
b29nbGVhcGlzLmNvbS9GZWRlcmF0aW9uUgRuYW1lIvwBChdDcmVhdGVGZWRlcmF0aW9uUmVx
dWVzdBJDCgZwYXJlbnQYASABKAlCK+BBAvpBJRIjbWV0YXN0b3JlLmdvb2dsZWFwaXMuY29t
L0ZlZGVyYXRpb25SBnBhcmVudBIoCg1mZWRlcmF0aW9uX2lkGAIgASgJQgPgQQJSDGZlZGVy
YXRpb25JZBJOCgpmZWRlcmF0aW9uGAMgASgLMikuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52
MWJldGEuRmVkZXJhdGlvbkID4EECUgpmZWRlcmF0aW9uEiIKCnJlcXVlc3RfaWQYBCABKAlC
A+BBAVIJcmVxdWVzdElkIs8BChdVcGRhdGVGZWRlcmF0aW9uUmVxdWVzdBJACgt1cGRhdGVf
bWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFz
axJOCgpmZWRlcmF0aW9uGAIgASgLMikuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWJldGEu
RmVkZXJhdGlvbkID4EECUgpmZWRlcmF0aW9uEiIKCnJlcXVlc3RfaWQYAyABKAlCA+BBAVIJ
cmVxdWVzdElkIn4KF0RlbGV0ZUZlZGVyYXRpb25SZXF1ZXN0Ej8KBG5hbWUYASABKAlCK+BB
AvpBJQojbWV0YXN0b3JlLmdvb2dsZWFwaXMuY29tL0ZlZGVyYXRpb25SBG5hbWUSIgoKcmVx
dWVzdF9pZBgCIAEoCUID4EEBUglyZXF1ZXN0SWQymAoKG0RhdGFwcm9jTWV0YXN0b3JlRmVk
ZXJhdGlvbhLGAQoPTGlzdEZlZGVyYXRpb25zEjUuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52
MWJldGEuTGlzdEZlZGVyYXRpb25zUmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUu
djFiZXRhLkxpc3RGZWRlcmF0aW9uc1Jlc3BvbnNlIkSC0+STAjUSMy92MWJldGEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9mZWRlcmF0aW9uc9pBBnBhcmVudBKzAQoNR2V0
RmVkZXJhdGlvbhIzLmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjFiZXRhLkdldEZlZGVyYXRp
b25SZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWJldGEuRmVkZXJhdGlvbiJC
gtPkkwI1EjMvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZmVkZXJhdGlv
bnMvKn3aQQRuYW1lEpUCChBDcmVhdGVGZWRlcmF0aW9uEjYuZ29vZ2xlLmNsb3VkLm1ldGFz
dG9yZS52MWJldGEuQ3JlYXRlRmVkZXJhdGlvblJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIqkBgtPkkwJBIjMvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKn0vZmVkZXJhdGlvbnM6CmZlZGVyYXRpb27aQR9wYXJlbnQsZmVkZXJhdGlvbixm
ZWRlcmF0aW9uX2lkykE9CgpGZWRlcmF0aW9uEi9nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYx
YmV0YS5PcGVyYXRpb25NZXRhZGF0YRKXAgoQVXBkYXRlRmVkZXJhdGlvbhI2Lmdvb2dsZS5j
bG91ZC5tZXRhc3RvcmUudjFiZXRhLlVwZGF0ZUZlZGVyYXRpb25SZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiKrAYLT5JMCTDI+L3YxYmV0YS97ZmVkZXJhdGlvbi5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZmVkZXJhdGlvbnMvKn06CmZlZGVyYXRpb27a
QRZmZWRlcmF0aW9uLHVwZGF0ZV9tYXNrykE9CgpGZWRlcmF0aW9uEi9nb29nbGUuY2xvdWQu
bWV0YXN0b3JlLnYxYmV0YS5PcGVyYXRpb25NZXRhZGF0YRL5AQoQRGVsZXRlRmVkZXJhdGlv
bhI2Lmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjFiZXRhLkRlbGV0ZUZlZGVyYXRpb25SZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKNAYLT5JMCNSozL3YxYmV0YS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2ZlZGVyYXRpb25zLyp92kEEbmFtZcpBSAoV
Z29vZ2xlLnByb3RvYnVmLkVtcHR5Ei9nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxYmV0YS5P
cGVyYXRpb25NZXRhZGF0YRpMykEYbWV0YXN0b3JlLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKAAQohY29tLmdvb2ds
ZS5jbG91ZC5tZXRhc3RvcmUudjFiZXRhQhhNZXRhc3RvcmVGZWRlcmF0aW9uUHJvdG9QAVo/
Y2xvdWQuZ29vZ2xlLmNvbS9nby9tZXRhc3RvcmUvYXBpdjFiZXRhL21ldGFzdG9yZXBiO21l
dGFzdG9yZXBiSrdnCgcSBQ4A+AIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAmCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYANwoJCgIDBRIDFwAtCgkKAgMGEgMYACUKCQoCAwcSAxkAKgoJCgIDCBID
GgApCggKAQgSAxwAVgoJCgIICxIDHABWCggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4A
OQoJCgIICBIDHgA5CggKAQgSAx8AOgoJCgIIARIDHwA6Cu0FCgIGABIELgBsARrgBSBDb25m
aWd1cmVzIGFuZCBtYW5hZ2VzIG1ldGFzdG9yZSBmZWRlcmF0aW9uIHNlcnZpY2VzLgogRGF0
YXByb2MgTWV0YXN0b3JlIEZlZGVyYXRpb24gU2VydmljZSBhbGxvd3MgZmVkZXJhdGluZyBh
IGNvbGxlY3Rpb24gb2YKIGJhY2tlbmQgbWV0YXN0b3JlcyBsaWtlIEJpZ1F1ZXJ5LCBEYXRh
cGxleCBMYWtlcywgYW5kIG90aGVyIERhdGFwcm9jCiBNZXRhc3RvcmVzLiBUaGUgRmVkZXJh
dGlvbiBTZXJ2aWNlIGV4cG9zZXMgYSBnUlBDIFVSTCB0aHJvdWdoIHdoaWNoIG1ldGFkYXRh
CiBmcm9tIHRoZSBiYWNrZW5kIG1ldGFzdG9yZXMgYXJlIHNlcnZlZCBhdCBxdWVyeSB0aW1l
LgoKIFRoZSBEYXRhcHJvYyBNZXRhc3RvcmUgRmVkZXJhdGlvbiBBUEkgZGVmaW5lcyB0aGUg
Zm9sbG93aW5nIHJlc291cmNlIG1vZGVsOgogKiBUaGUgc2VydmljZSB3b3JrcyB3aXRoIGEg
Y29sbGVjdGlvbiBvZiBHb29nbGUgQ2xvdWQgcHJvamVjdHMuCiAqIEVhY2ggcHJvamVjdCBo
YXMgYSBjb2xsZWN0aW9uIG9mIGF2YWlsYWJsZSBsb2NhdGlvbnMuCiAqIEVhY2ggbG9jYXRp
b24gaGFzIGEgY29sbGVjdGlvbiBvZiBmZWRlcmF0aW9ucy4KICogRGF0YXByb2MgTWV0YXN0
b3JlIEZlZGVyYXRpb25zIGFyZSByZXNvdXJjZXMgd2l0aCBuYW1lcyBvZiB0aGUKIGZvcm06
CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9m
ZWRlcmF0aW9ucy97ZmVkZXJhdGlvbl9pZH1gLgoKCgoDBgABEgMuCCMKCgoDBgADEgMvAkAK
DAoFBgADmQgSAy8CQAoLCgMGAAMSBDACMTcKDQoFBgADmggSBDACMTcKPAoEBgACABIENAI6
AxouIExpc3RzIGZlZGVyYXRpb25zIGluIGEgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUG
AAIAARIDNAYVCgwKBQYAAgACEgM0FiwKDAoFBgACAAMSAzUPJgoNCgUGAAIABBIENgQ4BgoR
CgkGAAIABLDKvCISBDYEOAYKDAoFBgACAAQSAzkENAoPCggGAAIABJsIABIDOQQ0CjgKBAYA
AgESBD0CQgMaKiBHZXRzIHRoZSBkZXRhaWxzIG9mIGEgc2luZ2xlIGZlZGVyYXRpb24uCgoM
CgUGAAIBARIDPQYTCgwKBQYAAgECEgM9FCgKDAoFBgACAQMSAz0zPQoNCgUGAAIBBBIEPgRA
BgoRCgkGAAIBBLDKvCISBD4EQAYKDAoFBgACAQQSA0EEMgoPCggGAAIBBJsIABIDQQQyCkkK
BAYAAgISBEUCUAMaOyBDcmVhdGVzIGEgbWV0YXN0b3JlIGZlZGVyYXRpb24gaW4gYSBwcm9q
ZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgIBEgNFBhYKDAoFBgACAgISA0UXLgoMCgUGAAIC
AxIDRg8rCg0KBQYAAgIEEgRHBEoGChEKCQYAAgIEsMq8IhIERwRKBgoMCgUGAAICBBIDSwRN
Cg8KCAYAAgIEmwgAEgNLBE0KDQoFBgACAgQSBEwETwYKDwoHBgACAgSZCBIETARPBgozCgQG
AAIDEgRTAl4DGiUgVXBkYXRlcyB0aGUgZmllbGRzIG9mIGEgZmVkZXJhdGlvbi4KCgwKBQYA
AgMBEgNTBhYKDAoFBgACAwISA1MXLgoMCgUGAAIDAxIDVA8rCg0KBQYAAgMEEgRVBFgGChEK
CQYAAgMEsMq8IhIEVQRYBgoMCgUGAAIDBBIDWQRECg8KCAYAAgMEmwgAEgNZBEQKDQoFBgAC
AwQSBFoEXQYKDwoHBgACAwSZCBIEWgRdBgosCgQGAAIEEgRhAmsDGh4gRGVsZXRlcyBhIHNp
bmdsZSBmZWRlcmF0aW9uLgoKDAoFBgACBAESA2EGFgoMCgUGAAIEAhIDYRcuCgwKBQYAAgQD
EgNiDysKDQoFBgACBAQSBGMEZQYKEQoJBgACBASwyrwiEgRjBGUGCgwKBQYAAgQEEgNmBDIK
DwoIBgACBASbCAASA2YEMgoNCgUGAAIEBBIEZwRqBgoPCgcGAAIEBJkIEgRnBGoGCkYKAgQA
EgVvALUBARo5IFJlcHJlc2VudHMgYSBmZWRlcmF0aW9uIG9mIG11bHRpcGxlIGJhY2tlbmQg
bWV0YXN0b3Jlcy4KCgoKAwQAARIDbwgSCgsKAwQABxIEcAJzBAoNCgUEAAedCBIEcAJzBAo1
CgQEAAQAEgV2AooBAxomIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBmZWRlcmF0aW9uLgoK
DAoFBAAEAAESA3YHDApCCgYEAAQAAgASA3gEGhozIFRoZSBzdGF0ZSBvZiB0aGUgbWV0YXN0
b3JlIGZlZGVyYXRpb24gaXMgdW5rbm93bi4KCg4KBwQABAACAAESA3gEFQoOCgcEAAQAAgAC
EgN4GBkKTQoGBAAEAAIBEgN7BBEaPiBUaGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gaXMgaW4g
dGhlIHByb2Nlc3Mgb2YgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACAQESA3sEDAoOCgcEAAQA
AgECEgN7DxAKUAoGBAAEAAICEgN+BA8aQSBUaGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gaXMg
cnVubmluZyBhbmQgcmVhZHkgdG8gc2VydmUgcXVlcmllcy4KCg4KBwQABAACAgESA34ECgoO
CgcEAAQAAgICEgN+DQ4KmQEKBgQABAACAxIEggEEERqIASBUaGUgbWV0YXN0b3JlIGZlZGVy
YXRpb24gaXMgYmVpbmcgdXBkYXRlZC4gSXQgcmVtYWlucyB1c2FibGUgYnV0IGNhbm5vdAog
YWNjZXB0IGFkZGl0aW9uYWwgdXBkYXRlIHJlcXVlc3RzIG9yIGJlIGRlbGV0ZWQgYXQgdGhp
cyB0aW1lLgoKDwoHBAAEAAIDARIEggEEDAoPCgcEAAQAAgMCEgSCAQ8QClUKBgQABAACBBIE
hQEEERpFIFRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiBpcyB1bmRlcmdvaW5nIGRlbGV0aW9u
LiBJdCBjYW5ub3QgYmUgdXNlZC4KCg8KBwQABAACBAESBIUBBAwKDwoHBAAEAAIEAhIEhQEP
EAqEAQoGBAAEAAIFEgSJAQQOGnQgVGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uIGhhcyBlbmNv
dW50ZXJlZCBhbiBlcnJvciBhbmQgY2Fubm90IGJlIHVzZWQuIFRoZQogbWV0YXN0b3JlIGZl
ZGVyYXRpb24gc2hvdWxkIGJlIGRlbGV0ZWQuCgoPCgcEAAQAAgUBEgSJAQQJCg8KBwQABAAC
BQISBIkBDA0KqAEKBAQAAgASBI8BAjwamQEgSW1tdXRhYmxlLiBUaGUgcmVsYXRpdmUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgZmVkZXJhdGlvbiwgb2YgdGhlCiBmb3JtOgogcHJvamVjdHMv
e3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9mZWRlcmF0aW9ucy97
ZmVkZXJhdGlvbl9pZH1gLgoKDQoFBAACAAUSBI8BAggKDQoFBAACAAESBI8BCQ0KDQoFBAAC
AAMSBI8BEBEKDQoFBAACAAgSBI8BEjsKEAoIBAACAAicCAASBI8BEzoKUgoEBAACARIGkgEC
kwEyGkIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIG1ldGFzdG9yZSBmZWRlcmF0
aW9uIHdhcyBjcmVhdGVkLgoKDQoFBAACAQYSBJIBAhsKDQoFBAACAQESBJIBHCcKDQoFBAAC
AQMSBJIBKisKDQoFBAACAQgSBJMBBjEKEAoIBAACAQicCAASBJMBBzAKVwoEBAACAhIGlgEC
lwEyGkcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIG1ldGFzdG9yZSBmZWRlcmF0
aW9uIHdhcyBsYXN0IHVwZGF0ZWQuCgoNCgUEAAICBhIElgECGwoNCgUEAAICARIElgEcJwoN
CgUEAAICAxIElgEqKwoNCgUEAAICCBIElwEGMQoQCggEAAICCJwIABIElwEHMApBCgQEAAID
EgSaAQIhGjMgVXNlci1kZWZpbmVkIGxhYmVscyBmb3IgdGhlIG1ldGFzdG9yZSBmZWRlcmF0
aW9uLgoKDQoFBAACAwYSBJoBAhUKDQoFBAACAwESBJoBFhwKDQoFBAACAwMSBJoBHyAKoAEK
BAQAAgQSBJ4BAj8akQEgSW1tdXRhYmxlLiBUaGUgQXBhY2hlIEhpdmUgbWV0YXN0b3JlIHZl
cnNpb24gb2YgdGhlIGZlZGVyYXRpb24uIEFsbCBiYWNrZW5kCiBtZXRhc3RvcmUgdmVyc2lv
bnMgbXVzdCBiZSBjb21wYXRpYmxlIHdpdGggdGhlIGZlZGVyYXRpb24gdmVyc2lvbi4KCg0K
BQQAAgQFEgSeAQIICg0KBQQAAgQBEgSeAQkQCg0KBQQAAgQDEgSeARMUCg0KBQQAAgQIEgSe
ARU+ChAKCAQAAgQInAgAEgSeARY9CqQDCgQEAAIFEgSmAQI2GpUDIEEgbWFwIGZyb20gYEJh
Y2tlbmRNZXRhc3RvcmVgIHJhbmsgdG8gYEJhY2tlbmRNZXRhc3RvcmVgcyBmcm9tIHdoaWNo
IHRoZQogZmVkZXJhdGlvbiBzZXJ2aWNlIHNlcnZlcyBtZXRhZGF0YSBhdCBxdWVyeSB0aW1l
LiBUaGUgbWFwIGtleSByZXByZXNlbnRzCiB0aGUgb3JkZXIgaW4gd2hpY2ggYEJhY2tlbmRN
ZXRhc3RvcmVgcyBzaG91bGQgYmUgZXZhbHVhdGVkIHRvIHJlc29sdmUKIGRhdGFiYXNlIG5h
bWVzIGF0IHF1ZXJ5IHRpbWUgYW5kIHNob3VsZCBiZSBncmVhdGVyIHRoYW4gb3IgZXF1YWwg
dG8gemVyby4gQQogYEJhY2tlbmRNZXRhc3RvcmVgIHdpdGggYSBsb3dlciBudW1iZXIgd2ls
bCBiZSBldmFsdWF0ZWQgYmVmb3JlIGEKIGBCYWNrZW5kTWV0YXN0b3JlYCB3aXRoIGEgaGln
aGVyIG51bWJlci4KCg0KBQQAAgUGEgSmAQIeCg0KBQQAAgUBEgSmAR8xCg0KBQQAAgUDEgSm
ATQ1CjUKBAQAAgYSBKkBAkYaJyBPdXRwdXQgb25seS4gVGhlIGZlZGVyYXRpb24gZW5kcG9p
bnQuCgoNCgUEAAIGBRIEqQECCAoNCgUEAAIGARIEqQEJFQoNCgUEAAIGAxIEqQEYGQoNCgUE
AAIGCBIEqQEaRQoQCggEAAIGCJwIABIEqQEbRApBCgQEAAIHEgSsAQI+GjMgT3V0cHV0IG9u
bHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBmZWRlcmF0aW9uLgoKDQoFBAACBwYSBKwB
AgcKDQoFBAACBwESBKwBCA0KDQoFBAACBwMSBKwBEBEKDQoFBAACBwgSBKwBEj0KEAoIBAAC
BwicCAASBKwBEzwKdwoEBAACCBIEsAECRxppIE91dHB1dCBvbmx5LiBBZGRpdGlvbmFsIGlu
Zm9ybWF0aW9uIGFib3V0IHRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZQogbWV0YXN0b3JlIGZl
ZGVyYXRpb24sIGlmIGF2YWlsYWJsZS4KCg0KBQQAAggFEgSwAQIICg0KBQQAAggBEgSwAQkW
Cg0KBQQAAggDEgSwARkaCg0KBQQAAggIEgSwARtGChAKCAQAAggInAgAEgSwARxFCmIKBAQA
AgkSBLQBAj4aVCBPdXRwdXQgb25seS4gVGhlIGdsb2JhbGx5IHVuaXF1ZSByZXNvdXJjZSBp
ZGVudGlmaWVyIG9mIHRoZSBtZXRhc3RvcmUKIGZlZGVyYXRpb24uCgoNCgUEAAIJBRIEtAEC
CAoNCgUEAAIJARIEtAEJDAoNCgUEAAIJAxIEtAEPEQoNCgUEAAIJCBIEtAESPQoQCggEAAIJ
CJwIABIEtAETPApCCgIEARIGuAEA1AEBGjQgUmVwcmVzZW50cyBhIGJhY2tlbmQgbWV0YXN0
b3JlIGZvciB0aGUgZmVkZXJhdGlvbi4KCgsKAwQBARIEuAEIGAo0CgQEAQQAEga6AQLGAQMa
JCBUaGUgdHlwZSBvZiB0aGUgYmFja2VuZCBtZXRhc3RvcmUuCgoNCgUEAQQAARIEugEHFAow
CgYEAQQAAgASBLwBBCMaICBUaGUgbWV0YXN0b3JlIHR5cGUgaXMgbm90IHNldC4KCg8KBwQB
BAACAAESBLwBBB4KDwoHBAEEAAIAAhIEvAEhIgo0CgYEAQQAAgESBL8BBBEaJCBUaGUgYmFj
a2VuZCBtZXRhc3RvcmUgaXMgRGF0YXBsZXguCgoPCgcEAQQAAgEBEgS/AQQMCg8KBwQBBAAC
AQISBL8BDxAKNAoGBAEEAAICEgTCAQQRGiQgVGhlIGJhY2tlbmQgbWV0YXN0b3JlIGlzIEJp
Z1F1ZXJ5LgoKDwoHBAEEAAICARIEwgEEDAoPCgcEAQQAAgICEgTCAQ8QCj4KBgQBBAACAxIE
xQEEGxouIFRoZSBiYWNrZW5kIG1ldGFzdG9yZSBpcyBEYXRhcHJvYyBNZXRhc3RvcmUuCgoP
CgcEAQQAAgMBEgTFAQQWCg8KBwQBBAACAwISBMUBGRoKxwIKBAQBAgASBNABAhIauAIgVGhl
IHJlbGF0aXZlIHJlc291cmNlIG5hbWUgb2YgdGhlIG1ldGFzdG9yZSB0aGF0IGlzIGJlaW5n
IGZlZGVyYXRlZC4KIFRoZSBmb3JtYXRzIG9mIHRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1l
cyBmb3IgdGhlIGN1cnJlbnRseSBzdXBwb3J0ZWQKIG1ldGFzdG9yZXMgYXJlIGxpc3RlZCBi
ZWxvdzoKCiAqIEJpZ1F1ZXJ5CiAgICAgKiBgcHJvamVjdHMve3Byb2plY3RfaWR9YAogKiBE
YXRhcHJvYyBNZXRhc3RvcmUKICAgICAqIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vc2VydmljZXMve3NlcnZpY2VfaWR9YAoKDQoFBAECAAUSBNABAggK
DQoFBAECAAESBNABCQ0KDQoFBAECAAMSBNABEBEKMgoEBAECARIE0wECIxokIFRoZSB0eXBl
IG9mIHRoZSBiYWNrZW5kIG1ldGFzdG9yZS4KCg0KBQQBAgEGEgTTAQIPCg0KBQQBAgEBEgTT
ARAeCg0KBQQBAgEDEgTTASEiCjQKAgQCEgbXAQD5AQEaJiBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IExpc3RGZWRlcmF0aW9ucy4KCgsKAwQCARIE1wEIHgq3AQoEBAICABIG2wEC4AEEGqYBIFJl
cXVpcmVkLiBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbG9jYXRpb24gb2Yg
bWV0YXN0b3JlCiBmZWRlcmF0aW9ucyB0byBsaXN0LCBpbiB0aGUgZm9sbG93aW5nIGZvcm06
CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfWAu
CgoNCgUEAgIABRIE2wECCAoNCgUEAgIAARIE2wEJDwoNCgUEAgIAAxIE2wESEwoPCgUEAgIA
CBIG2wEU4AEDChAKCAQCAgAInAgAEgTcAQQqChEKBwQCAgAInwgSBt0BBN8BBQr7AQoEBAIC
ARIE5gECPxrsASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGZlZGVyYXRpb25z
IHRvIHJldHVybi4gVGhlIHJlc3BvbnNlIG1heQogY29udGFpbiBsZXNzIHRoYW4gdGhlIG1h
eGltdW0gbnVtYmVyLiBJZiB1bnNwZWNpZmllZCwgbm8gbW9yZSB0aGFuIDUwMAogc2Vydmlj
ZXMgYXJlIHJldHVybmVkLiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJv
dmUgMTAwMCBhcmUKIGNoYW5nZWQgdG8gMTAwMC4KCg0KBQQCAgEFEgTmAQIHCg0KBQQCAgEB
EgTmAQgRCg0KBQQCAgEDEgTmARQVCg0KBQQCAgEIEgTmARY+ChAKCAQCAgEInAgAEgTmARc9
CsgCCgQEAgICEgTwAQJBGrkCIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZy
b20gYSBwcmV2aW91cyBMaXN0RmVkZXJhdGlvblNlcnZpY2VzCiBjYWxsLiBQcm92aWRlIHRo
aXMgdG9rZW4gdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBUbyByZXRyaWV2
ZSB0aGUgZmlyc3QgcGFnZSwgc3VwcGx5IGFuIGVtcHR5IHBhZ2UgdG9rZW4uCgogV2hlbiBw
YWdpbmF0aW5nLCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBMaXN0RmVkZXJhdGlv
blNlcnZpY2VzIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUKIHBhZ2Ug
dG9rZW4uCgoNCgUEAgICBRIE8AECCAoNCgUEAgICARIE8AEJEwoNCgUEAgICAxIE8AEWFwoN
CgUEAgICCBIE8AEYQAoQCggEAgICCJwIABIE8AEZPwo+CgQEAgIDEgTzAQI9GjAgT3B0aW9u
YWwuIFRoZSBmaWx0ZXIgdG8gYXBwbHkgdG8gbGlzdCByZXN1bHRzLgoKDQoFBAICAwUSBPMB
AggKDQoFBAICAwESBPMBCQ8KDQoFBAICAwMSBPMBEhMKDQoFBAICAwgSBPMBFDwKEAoIBAIC
AwicCAASBPMBFTsK5AEKBAQCAgQSBPgBAj8a1QEgT3B0aW9uYWwuIFNwZWNpZnkgdGhlIG9y
ZGVyaW5nIG9mIHJlc3VsdHMgYXMgZGVzY3JpYmVkIGluIFtTb3J0aW5nCiBPcmRlcl0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL2Rlc2lnbl9wYXR0ZXJucyNzb3J0
aW5nX29yZGVyKS4KIElmIG5vdCBzcGVjaWZpZWQsIHRoZSByZXN1bHRzIHdpbGwgYmUgc29y
dGVkIGluIHRoZSBkZWZhdWx0IG9yZGVyLgoKDQoFBAICBAUSBPgBAggKDQoFBAICBAESBPgB
CREKDQoFBAICBAMSBPgBFBUKDQoFBAICBAgSBPgBFj4KEAoIBAICBAicCAASBPgBFz0KNAoC
BAMSBvwBAIYCARomIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExpc3RGZWRlcmF0aW9ucwoKCwoD
BAMBEgT8AQgfCjcKBAQDAgASBP4BAiYaKSBUaGUgc2VydmljZXMgaW4gdGhlIHNwZWNpZmll
ZCBsb2NhdGlvbi4KCg0KBQQDAgAEEgT+AQIKCg0KBQQDAgAGEgT+AQsVCg0KBQQDAgABEgT+
ARYhCg0KBQQDAgADEgT+ASQlCo0BCgQEAwIBEgSCAgIdGn8gQSB0b2tlbiB0aGF0IGNhbiBi
ZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLiBJZiB0
aGlzCiBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4K
Cg0KBQQDAgEFEgSCAgIICg0KBQQDAgEBEgSCAgkYCg0KBQQDAgEDEgSCAhscCjQKBAQDAgIS
BIUCAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQDAgIE
EgSFAgIKCg0KBQQDAgIFEgSFAgsRCg0KBQQDAgIBEgSFAhIdCg0KBQQDAgIDEgSFAiAhCjIK
AgQEEgaJAgCUAgEaJCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEdldEZlZGVyYXRpb24uCgoLCgME
BAESBIkCCBwKywEKBAQEAgASBo4CApMCBBq6ASBSZXF1aXJlZC4gVGhlIHJlbGF0aXZlIHJl
c291cmNlIG5hbWUgb2YgdGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uIHRvCiByZXRyaWV2ZSwg
aW4gdGhlIGZvbGxvd2luZyBmb3JtOgoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xv
Y2F0aW9ucy97bG9jYXRpb25faWR9L2ZlZGVyYXRpb25zL3tmZWRlcmF0aW9uX2lkfWAuCgoN
CgUEBAIABRIEjgICCAoNCgUEBAIAARIEjgIJDQoNCgUEBAIAAxIEjgIQEQoPCgUEBAIACBIG
jgISkwIDChAKCAQEAgAInAgAEgSPAgQqChEKBwQEAgAInwgSBpACBJICBQo1CgIEBRIGlwIA
vQIBGicgUmVxdWVzdCBtZXNzYWdlIGZvciBDcmVhdGVGZWRlcmF0aW9uLgoKCwoDBAUBEgSX
AggfCr8BCgQEBQIAEgacAgKhAgQargEgUmVxdWlyZWQuIFRoZSByZWxhdGl2ZSByZXNvdXJj
ZSBuYW1lIG9mIHRoZSBsb2NhdGlvbiBpbiB3aGljaCB0byBjcmVhdGUgYQogZmVkZXJhdGlv
biBzZXJ2aWNlLCBpbiB0aGUgZm9sbG93aW5nIGZvcm06CgogYHByb2plY3RzL3twcm9qZWN0
X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH1gLgoKDQoFBAUCAAUSBJwCAggKDQoF
BAUCAAESBJwCCQ8KDQoFBAUCAAMSBJwCEhMKDwoFBAUCAAgSBpwCFKECAwoQCggEBQIACJwI
ABIEnQIEKgoRCgcEBQIACJ8IEgaeAgSgAgUKtwIKBAQFAgESBKkCAkQaqAIgUmVxdWlyZWQu
IFRoZSBJRCBvZiB0aGUgbWV0YXN0b3JlIGZlZGVyYXRpb24sIHdoaWNoIGlzIHVzZWQgYXMg
dGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uJ3MgbmFt
ZS4KCiBUaGlzIHZhbHVlIG11c3QgYmUgYmV0d2VlbiAyIGFuZCA2MyBjaGFyYWN0ZXJzIGxv
bmcgaW5jbHVzaXZlLCBiZWdpbiB3aXRoIGEKIGxldHRlciwgZW5kIHdpdGggYSBsZXR0ZXIg
b3IgbnVtYmVyLCBhbmQgY29uc2lzdCBvZiBhbHBoYS1udW1lcmljCiBBU0NJSSBjaGFyYWN0
ZXJzIG9yIGh5cGhlbnMuCgoNCgUEBQIBBRIEqQICCAoNCgUEBQIBARIEqQIJFgoNCgUEBQIB
AxIEqQIZGgoNCgUEBQIBCBIEqQIbQwoQCggEBQIBCJwIABIEqQIcQgrBAQoEBAUCAhIErgIC
RRqyASBSZXF1aXJlZC4gVGhlIE1ldGFzdG9yZSBGZWRlcmF0aW9uIHRvIGNyZWF0ZS4gVGhl
IGBuYW1lYCBmaWVsZCBpcwogaWdub3JlZC4gVGhlIElEIG9mIHRoZSBjcmVhdGVkIG1ldGFz
dG9yZSBmZWRlcmF0aW9uIG11c3QgYmUKIHByb3ZpZGVkIGluIHRoZSByZXF1ZXN0J3MgYGZl
ZGVyYXRpb25faWRgIGZpZWxkLgoKDQoFBAUCAgYSBK4CAgwKDQoFBAUCAgESBK4CDRcKDQoF
BAUCAgMSBK4CGhsKDQoFBAUCAggSBK4CHEQKEAoIBAUCAgicCAASBK4CHUMK+QQKBAQFAgMS
BLwCAkEa6gQgT3B0aW9uYWwuIEEgcmVxdWVzdCBJRC4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1
ZXN0IElEIHRvIGFsbG93IHRoZSBzZXJ2ZXIgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBp
dCBoYXMgY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwgaWdub3JlIHN1YnNlcXVlbnQKIHJl
cXVlc3RzIHRoYXQgcHJvdmlkZSBhIGR1cGxpY2F0ZSByZXF1ZXN0IElEIGZvciBhdCBsZWFz
dCA2MCBtaW51dGVzIGFmdGVyCiB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwg
aWYgYW4gaW5pdGlhbCByZXF1ZXN0IHRpbWVzIG91dCwgZm9sbG93ZWQgYnkgYW5vdGhlciBy
ZXF1ZXN0CiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQsIHRoZSBzZXJ2ZXIgaWdub3JlcyB0
aGUgc2Vjb25kIHJlcXVlc3QgdG8gcHJldmVudAogdGhlIGNyZWF0aW9uIG9mIGR1cGxpY2F0
ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQKIFtVVUlE
XShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxseV91bmlxdWVfaWRl
bnRpZmllciNGb3JtYXQpCiBBIHplcm8gVVVJRCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAt
MDAwMDAwMDAwMDAwKSBpcyBub3Qgc3VwcG9ydGVkLgoKDQoFBAUCAwUSBLwCAggKDQoFBAUC
AwESBLwCCRMKDQoFBAUCAwMSBLwCFhcKDQoFBAUCAwgSBLwCGEAKEAoIBAUCAwicCAASBLwC
GT8KNQoCBAYSBsACANwCARonIFJlcXVlc3QgbWVzc2FnZSBmb3IgVXBkYXRlRmVkZXJhdGlv
bi4KCgsKAwQGARIEwAIIHwqYAgoEBAYCABIGxQICxgIvGocCIFJlcXVpcmVkLiBBIGZpZWxk
IG1hc2sgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4g
dGhlCiBtZXRhc3RvcmUgZmVkZXJhdGlvbiByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogRmll
bGRzIHNwZWNpZmllZCBpbiB0aGUgYHVwZGF0ZV9tYXNrYCBhcmUgcmVsYXRpdmUgdG8gdGhl
IHJlc291cmNlIChub3QKIHRvIHRoZSBmdWxsIHJlcXVlc3QpLiBBIGZpZWxkIGlzIG92ZXJ3
cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLgoKDQoFBAYCAAYSBMUCAhsKDQoFBAYCAAES
BMUCHCcKDQoFBAYCAAMSBMUCKisKDQoFBAYCAAgSBMYCBi4KEAoIBAYCAAicCAASBMYCBy0K
+AEKBAQGAgESBM0CAkUa6QEgUmVxdWlyZWQuIFRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiB0
byB1cGRhdGUuIFRoZSBzZXJ2ZXIgb25seSBtZXJnZXMgZmllbGRzCiBpbiB0aGUgc2Vydmlj
ZSBpZiB0aGV5IGFyZSBzcGVjaWZpZWQgaW4gYHVwZGF0ZV9tYXNrYC4KCiBUaGUgbWV0YXN0
b3JlIGZlZGVyYXRpb24ncyBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUK
IG1ldGFzdG9yZSBzZXJ2aWNlIHRvIGJlIHVwZGF0ZWQuCgoNCgUEBgIBBhIEzQICDAoNCgUE
BgIBARIEzQINFwoNCgUEBgIBAxIEzQIaGwoNCgUEBgIBCBIEzQIcRAoQCggEBgIBCJwIABIE
zQIdQwr5BAoEBAYCAhIE2wICQRrqBCBPcHRpb25hbC4gQSByZXF1ZXN0IElELiBTcGVjaWZ5
IGEgdW5pcXVlIHJlcXVlc3QgSUQgdG8gYWxsb3cgdGhlIHNlcnZlciB0bwogaWdub3JlIHRo
ZSByZXF1ZXN0IGlmIGl0IGhhcyBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbCBpZ25vcmUg
c3Vic2VxdWVudAogcmVxdWVzdHMgdGhhdCBwcm92aWRlIGEgZHVwbGljYXRlIHJlcXVlc3Qg
SUQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgYWZ0ZXIKIHRoZSBmaXJzdCByZXF1ZXN0LgoK
IEZvciBleGFtcGxlLCBpZiBhbiBpbml0aWFsIHJlcXVlc3QgdGltZXMgb3V0LCBmb2xsb3dl
ZCBieSBhbm90aGVyIHJlcXVlc3QKIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRCwgdGhlIHNl
cnZlciBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdCB0byBwcmV2ZW50CiB0aGUgY3JlYXRp
b24gb2YgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUg
YSB2YWxpZAogW1VVSURdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1VuaXZlcnNh
bGx5X3VuaXF1ZV9pZGVudGlmaWVyI0Zvcm1hdCkKIEEgemVybyBVVUlEICgwMDAwMDAwMC0w
MDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApIGlzIG5vdCBzdXBwb3J0ZWQuCgoNCgUEBgIC
BRIE2wICCAoNCgUEBgICARIE2wIJEwoNCgUEBgICAxIE2wIWFwoNCgUEBgICCBIE2wIYQAoQ
CggEBgICCJwIABIE2wIZPwo1CgIEBxIG3wIA+AIBGicgUmVxdWVzdCBtZXNzYWdlIGZvciBE
ZWxldGVGZWRlcmF0aW9uLgoKCwoDBAcBEgTfAggfCskBCgQEBwIAEgbkAgLpAgQauAEgUmVx
dWlyZWQuIFRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtZXRhc3RvcmUgZmVk
ZXJhdGlvbiB0byBkZWxldGUsCiBpbiB0aGUgZm9sbG93aW5nIGZvcm06CgogYHByb2plY3Rz
L3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZmVkZXJhdGlvbnMv
e2ZlZGVyYXRpb25faWR9YC4KCg0KBQQHAgAFEgTkAgIICg0KBQQHAgABEgTkAgkNCg0KBQQH
AgADEgTkAhARCg8KBQQHAgAIEgbkAhLpAgMKEAoIBAcCAAicCAASBOUCBCoKEQoHBAcCAAif
CBIG5gIE6AIFCvkECgQEBwIBEgT3AgJBGuoEIE9wdGlvbmFsLiBBIHJlcXVlc3QgSUQuIFNw
ZWNpZnkgYSB1bmlxdWUgcmVxdWVzdCBJRCB0byBhbGxvdyB0aGUgc2VydmVyIHRvCiBpZ25v
cmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsIGln
bm9yZSBzdWJzZXF1ZW50CiByZXF1ZXN0cyB0aGF0IHByb3ZpZGUgYSBkdXBsaWNhdGUgcmVx
dWVzdCBJRCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBhZnRlcgogdGhlIGZpcnN0IHJlcXVl
c3QuCgogRm9yIGV4YW1wbGUsIGlmIGFuIGluaXRpYWwgcmVxdWVzdCB0aW1lcyBvdXQsIGZv
bGxvd2VkIGJ5IGFub3RoZXIgcmVxdWVzdAogd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElELCB0
aGUgc2VydmVyIGlnbm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0IHRvIHByZXZlbnQKIHRoZSBj
cmVhdGlvbiBvZiBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVz
dCBiZSBhIHZhbGlkCiBbVVVJRF0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvVW5p
dmVyc2FsbHlfdW5pcXVlX2lkZW50aWZpZXIjRm9ybWF0KQogQSB6ZXJvIFVVSUQgKDAwMDAw
MDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkgaXMgbm90IHN1cHBvcnRlZC4KCg0K
BQQHAgEFEgT3AgIICg0KBQQHAgEBEgT3AgkTCg0KBQQHAgEDEgT3AhYXCg0KBQQHAgEIEgT3
AhhAChAKCAQHAgEInAgAEgT3Ahk/YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation ===
    # Fields for Federation
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.metastore.v1beta.Federation.LabelsEntry)
    # Field: version Type: 9 ()
    # Field: backend_metastores Type: 11 (.google.cloud.metastore.v1beta.Federation.BackendMetastoresEntry)
    # Field: endpoint_uri Type: 9 ()
    # Field: state Type: 14 (.google.cloud.metastore.v1beta.Federation.State)
    # Field: state_message Type: 9 ()
    # Field: uid Type: 9 ()

# Enum: Federation::State
our $Federation_STATE_UNSPECIFIED = 0;
our $Federation_CREATING = 1;
our $Federation_ACTIVE = 2;
our $Federation_UPDATING = 3;
our $Federation_DELETING = 4;
our $Federation_ERROR = 5;

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::BackendMetastore ===
    # Fields for BackendMetastore
    # Field: name Type: 9 ()
    # Field: metastore_type Type: 14 (.google.cloud.metastore.v1beta.BackendMetastore.MetastoreType)

# Enum: BackendMetastore::MetastoreType
our $BackendMetastore_METASTORE_TYPE_UNSPECIFIED = 0;
our $BackendMetastore_DATAPLEX = 1;
our $BackendMetastore_BIGQUERY = 2;
our $BackendMetastore_DATAPROC_METASTORE = 3;

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::ListFederationsRequest ===
    # Fields for ListFederationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::ListFederationsResponse ===
    # Fields for ListFederationsResponse
    # Field: federations Type: 11 (.google.cloud.metastore.v1beta.Federation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::GetFederationRequest ===
    # Fields for GetFederationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::CreateFederationRequest ===
    # Fields for CreateFederationRequest
    # Field: parent Type: 9 ()
    # Field: federation_id Type: 9 ()
    # Field: federation Type: 11 (.google.cloud.metastore.v1beta.Federation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::UpdateFederationRequest ===
    # Fields for UpdateFederationRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: federation Type: 11 (.google.cloud.metastore.v1beta.Federation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Metastore::V1beta::MetastoreFederation::DeleteFederationRequest ===
    # Fields for DeleteFederationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Service Client: Google::Cloud::Metastore::V1beta::MetastoreFederation::DataprocMetastoreFederationClient ===
package Google::Cloud::Metastore::V1beta::MetastoreFederation::DataprocMetastoreFederationClient;

=pod

=head2 Service Client: Google::Cloud::Metastore::V1beta::MetastoreFederation::DataprocMetastoreFederationClient

Client stub representing the remote C<DataprocMetastoreFederation> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<metastore.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'metastore.googleapis.com:443' );

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

sub list_federations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1beta::MetastoreFederation::ListFederationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1beta.DataprocMetastoreFederation',
        method         => 'ListFederations',
        request        => $req,
        response_class => 'Google::Cloud::Metastore::V1beta::MetastoreFederation::ListFederationsResponse',
    });
}

sub get_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1beta::MetastoreFederation::GetFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1beta.DataprocMetastoreFederation',
        method         => 'GetFederation',
        request        => $req,
        response_class => 'Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation',
    });
}

sub create_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1beta::MetastoreFederation::CreateFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1beta.DataprocMetastoreFederation',
        method         => 'CreateFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1beta::MetastoreFederation::UpdateFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1beta.DataprocMetastoreFederation',
        method         => 'UpdateFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1beta::MetastoreFederation::DeleteFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1beta.DataprocMetastoreFederation',
        method         => 'DeleteFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Metastore::V1beta::MetastoreFederation - Compiled Protocol Buffers messages for google/cloud/metastore/v1beta/metastore_federation.proto

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1beta::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/metastore/v1beta/metastore_federation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation

Represents a federation of multiple backend metastores.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The relative resource name of the federation, of the
form:
projects/{project_number}/locations/{location_id}/federations/{federation_id}`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the metastore federation was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the metastore federation was last updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation::LabelsEntry>)

User-defined labels for the metastore federation.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Immutable. The Apache Hive metastore version of the federation. All backend
metastore versions must be compatible with the federation version.

=item * C<< $msg->backend_metastores() >> / C<< $msg->backend_metastores($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation::BackendMetastoresEntry>)

A map from `BackendMetastore` rank to `BackendMetastore`s from which the
federation service serves metadata at query time. The map key represents
the order in which `BackendMetastore`s should be evaluated to resolve
database names at query time and should be greater than or equal to zero. A
`BackendMetastore` with a lower number will be evaluated before a
`BackendMetastore` with a higher number.

=item * C<< $msg->endpoint_uri() >> / C<< $msg->endpoint_uri($value) >>

Type: C<String>

Output only. The federation endpoint.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Metastore::V1beta::Federation::State>)

Output only. The current state of the federation.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

Output only. Additional information about the current state of the
metastore federation, if available.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique resource identifier of the metastore
federation.

=back

=head3 Enum: Federation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=item * C<ERROR> => C<5>

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::BackendMetastore

Represents a backend metastore for the federation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of the metastore that is being federated.
The formats of the relative resource names for the currently supported
metastores are listed below:

* BigQuery
    * `projects/{project_id}`
* Dataproc Metastore
    * `projects/{project_id}/locations/{location}/services/{service_id}`

=item * C<< $msg->metastore_type() >> / C<< $msg->metastore_type($value) >>

Type: C<Enum> (L<Google::Cloud::Metastore::V1beta::BackendMetastore::MetastoreType>)

The type of the backend metastore.

=back

=head3 Enum: BackendMetastore::MetastoreType

=over 4

=item * C<METASTORE_TYPE_UNSPECIFIED> => C<0>

=item * C<DATAPLEX> => C<1>

=item * C<BIGQUERY> => C<2>

=item * C<DATAPROC_METASTORE> => C<3>

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::ListFederationsRequest

Request message for ListFederations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The relative resource name of the location of metastore
federations to list, in the following form:
`projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of federations to return. The response may
contain less than the maximum number. If unspecified, no more than 500
services are returned. The maximum value is 1000; values above 1000 are
changed to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous ListFederationServices
call. Provide this token to retrieve the subsequent page.

To retrieve the first page, supply an empty page token.

When paginating, other parameters provided to
ListFederationServices must match the call that provided the
page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply to list results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Specify the ordering of results as described in [Sorting
Order](https://cloud.google.com/apis/design/design_patterns#sorting_order).
If not specified, the results will be sorted in the default order.

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::ListFederationsResponse

Response message for ListFederations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->federations() >> / C<< $msg->federations($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation>)

The services in the specified location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page. If this
field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::GetFederationRequest

Request message for GetFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The relative resource name of the metastore federation to
retrieve, in the following form:

`projects/{project_number}/locations/{location_id}/federations/{federation_id}`.

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::CreateFederationRequest

Request message for CreateFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The relative resource name of the location in which to create a
federation service, in the following form:

`projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->federation_id() >> / C<< $msg->federation_id($value) >>

Type: C<String>

Required. The ID of the metastore federation, which is used as the final
component of the metastore federation's name.

This value must be between 2 and 63 characters long inclusive, begin with a
letter, end with a letter or number, and consist of alpha-numeric
ASCII characters or hyphens.

=item * C<< $msg->federation() >> / C<< $msg->federation($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation>)

Required. The Metastore Federation to create. The `name` field is
ignored. The ID of the created metastore federation must be
provided in the request's `federation_id` field.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID. Specify a unique request ID to allow the server to
ignore the request if it has completed. The server will ignore subsequent
requests that provide a duplicate request ID for at least 60 minutes after
the first request.

For example, if an initial request times out, followed by another request
with the same request ID, the server ignores the second request to prevent
the creation of duplicate commitments.

The request ID must be a valid
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Format)
A zero UUID (00000000-0000-0000-0000-000000000000) is not supported.

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::UpdateFederationRequest

Request message for UpdateFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. A field mask used to specify the fields to be overwritten in the
metastore federation resource by the update.
Fields specified in the `update_mask` are relative to the resource (not
to the full request). A field is overwritten if it is in the mask.

=item * C<< $msg->federation() >> / C<< $msg->federation($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1beta::MetastoreFederation::Federation>)

Required. The metastore federation to update. The server only merges fields
in the service if they are specified in `update_mask`.

The metastore federation's `name` field is used to identify the
metastore service to be updated.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID. Specify a unique request ID to allow the server to
ignore the request if it has completed. The server will ignore subsequent
requests that provide a duplicate request ID for at least 60 minutes after
the first request.

For example, if an initial request times out, followed by another request
with the same request ID, the server ignores the second request to prevent
the creation of duplicate commitments.

The request ID must be a valid
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Format)
A zero UUID (00000000-0000-0000-0000-000000000000) is not supported.

=back

=head2 Google::Cloud::Metastore::V1beta::MetastoreFederation::DeleteFederationRequest

Request message for DeleteFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The relative resource name of the metastore federation to delete,
in the following form:

`projects/{project_number}/locations/{location_id}/federations/{federation_id}`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID. Specify a unique request ID to allow the server to
ignore the request if it has completed. The server will ignore subsequent
requests that provide a duplicate request ID for at least 60 minutes after
the first request.

For example, if an initial request times out, followed by another request
with the same request ID, the server ignores the second request to prevent
the creation of duplicate commitments.

The request ID must be a valid
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Format)
A zero UUID (00000000-0000-0000-0000-000000000000) is not supported.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Metastore::V1beta::MetastoreFederation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
