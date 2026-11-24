package Google::Cloud::Discoveryengine::V1::PurgeConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1::ImportConfig };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3B1cmdlX2NvbmZpZy5wcm90bxIf
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxozZ29vZ2xlL2Nsb3VkL2Rp
c2NvdmVyeWVuZ2luZS92MS9pbXBvcnRfY29uZmlnLnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byKVAQoWUHVyZ2VVc2Vy
RXZlbnRzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50EhsKBmZpbHRlchgCIAEoCUID4EEC
UgZmaWx0ZXISFAoFZm9yY2UYAyABKAhSBWZvcmNlIjoKF1B1cmdlVXNlckV2ZW50c1Jlc3Bv
bnNlEh8KC3B1cmdlX2NvdW50GAEgASgDUgpwdXJnZUNvdW50It0BChdQdXJnZVVzZXJFdmVu
dHNNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEiMKDXN1Y2Nlc3NfY291bnQYAyABKANSDHN1Y2Nl
c3NDb3VudBIjCg1mYWlsdXJlX2NvdW50GAQgASgDUgxmYWlsdXJlQ291bnQiQgoQUHVyZ2VF
cnJvckNvbmZpZxIfCgpnY3NfcHJlZml4GAEgASgJSABSCWdjc1ByZWZpeEINCgtkZXN0aW5h
dGlvbiKJBAoVUHVyZ2VEb2N1bWVudHNSZXF1ZXN0EksKCmdjc19zb3VyY2UYBSABKAsyKi5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkdjc1NvdXJjZUgAUglnY3NTb3VyY2US
agoNaW5saW5lX3NvdXJjZRgGIAEoCzJDLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuUHVyZ2VEb2N1bWVudHNSZXF1ZXN0LklubGluZVNvdXJjZUgAUgxpbmxpbmVTb3VyY2US
RQoGcGFyZW50GAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9CcmFuY2hSBnBhcmVudBIbCgZmaWx0ZXIYAiABKAlCA+BBAlIGZmlsdGVyElQKDGVycm9y
X2NvbmZpZxgHIAEoCzIxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUHVyZ2VF
cnJvckNvbmZpZ1ILZXJyb3JDb25maWcSFAoFZm9yY2UYAyABKAhSBWZvcmNlGl0KDElubGlu
ZVNvdXJjZRJNCglkb2N1bWVudHMYASADKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdv
b2dsZWFwaXMuY29tL0RvY3VtZW50Uglkb2N1bWVudHNCCAoGc291cmNlIooBChZQdXJnZURv
Y3VtZW50c1Jlc3BvbnNlEh8KC3B1cmdlX2NvdW50GAEgASgDUgpwdXJnZUNvdW50Ek8KDHB1
cmdlX3NhbXBsZRgCIAMoCUIs+kEpCidkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
RG9jdW1lbnRSC3B1cmdlU2FtcGxlIoECChZQdXJnZURvY3VtZW50c01ldGFkYXRhEjsKC2Ny
ZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGlt
ZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVw
ZGF0ZVRpbWUSIwoNc3VjY2Vzc19jb3VudBgDIAEoA1IMc3VjY2Vzc0NvdW50EiMKDWZhaWx1
cmVfY291bnQYBCABKANSDGZhaWx1cmVDb3VudBIjCg1pZ25vcmVkX2NvdW50GAUgASgDUgxp
Z25vcmVkQ291bnQicQolUHVyZ2VTdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzUmVxdWVzdBJI
CgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t
L0RhdGFTdG9yZVIGcGFyZW50IoIBCiZQdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNS
ZXNwb25zZRIfCgtwdXJnZV9jb3VudBgBIAEoA1IKcHVyZ2VDb3VudBI3Cg1lcnJvcl9zYW1w
bGVzGAIgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSDGVycm9yU2FtcGxlcyKiAQomUHVyZ2VT
dWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzTWV0YWRhdGESOwoLY3JlYXRlX3RpbWUYASABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1l
GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZSJtCiFQdXJn
ZUNvbXBsZXRpb25TdWdnZXN0aW9uc1JlcXVlc3QSSAoGcGFyZW50GAEgASgJQjDgQQL6QSoK
KGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSBnBhcmVudCKGAQoi
UHVyZ2VDb21wbGV0aW9uU3VnZ2VzdGlvbnNSZXNwb25zZRInCg9wdXJnZV9zdWNjZWVkZWQY
ASABKAhSDnB1cmdlU3VjY2VlZGVkEjcKDWVycm9yX3NhbXBsZXMYAiADKAsyEi5nb29nbGUu
cnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVzIp4BCiJQdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9u
c01ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWVCgwIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxQhBQdXJnZUNvbmZpZ1Byb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vZGlz
Y292ZXJ5ZW5naW5lL2FwaXYxL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBi
ogIPRElTQ09WRVJZRU5HSU5FqgIfR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMcoC
H0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjHqAiJHb29nbGU6OkNsb3VkOjpEaXNj
b3ZlcnlFbmdpbmU6OlYxSoVRCgcSBQ4AngIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA9CgkK
AgMDEgMVACkKCQoCAwQSAxYAIQoICgEIEgMYADwKCQoCCCUSAxgAPAoICgEIEgMZAGQKCQoC
CAsSAxkAZAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADEKCQoCCAgSAxsAMQoICgEI
EgMcADwKCQoCCAESAxwAPAoICgEIEgMdAC0KCQoCCCQSAx0ALQoICgEIEgMeADwKCQoCCCkS
Ax4APAoICgEIEgMfADsKCQoCCC0SAx8AOwo5CgIEABIEIgBTARotIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgUHVyZ2VVc2VyRXZlbnRzIG1ldGhvZC4KCgoKAwQAARIDIggeCsYBCgQEAAIAEgQm
AisEGrcBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY2F0YWxvZyB1bmRl
ciB3aGljaCB0aGUgZXZlbnRzIGFyZQogY3JlYXRlZC4gVGhlIGZvcm1hdCBpcwogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMvZ2xvYmFsL2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9u
fS9kYXRhU3RvcmVzL3tkYXRhU3RvcmV9YC4KCgwKBQQAAgAFEgMmAggKDAoFBAACAAESAyYJ
DwoMCgUEAAIAAxIDJhITCg0KBQQAAgAIEgQmFCsDCg8KCAQAAgAInAgAEgMnBCoKDwoHBAAC
AAifCBIEKAQqBQqpCQoEBAACARIDSgI9GpsJIFJlcXVpcmVkLiBUaGUgZmlsdGVyIHN0cmlu
ZyB0byBzcGVjaWZ5IHRoZSBldmVudHMgdG8gYmUgZGVsZXRlZCB3aXRoIGEKIGxlbmd0aCBs
aW1pdCBvZiA1LDAwMCBjaGFyYWN0ZXJzLiBUaGUgZWxpZ2libGUgZmllbGRzIGZvciBmaWx0
ZXJpbmcgYXJlOgoKICogYGV2ZW50VHlwZWA6IERvdWJsZSBxdW90ZWQKIFtVc2VyRXZlbnQu
ZXZlbnRfdHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyRXZlbnQu
ZXZlbnRfdHlwZV0KIHN0cmluZy4KICogYGV2ZW50VGltZWA6IGluIElTTyA4NjAxICJ6dWx1
IiBmb3JtYXQuCiAqIGB1c2VyUHNldWRvSWRgOiBEb3VibGUgcXVvdGVkIHN0cmluZy4gU3Bl
Y2lmeWluZyB0aGlzIHdpbGwgZGVsZXRlIGFsbAogICBldmVudHMgYXNzb2NpYXRlZCB3aXRo
IGEgdmlzaXRvci4KICogYHVzZXJJZGA6IERvdWJsZSBxdW90ZWQgc3RyaW5nLiBTcGVjaWZ5
aW5nIHRoaXMgd2lsbCBkZWxldGUgYWxsIGV2ZW50cwogICBhc3NvY2lhdGVkIHdpdGggYSB1
c2VyLgoKIE5vdGU6IFRoaXMgQVBJIG9ubHkgc3VwcG9ydHMgcHVyZ2luZyBhIG1heCByYW5n
ZSBvZiAzMCBkYXlzLgoKIEV4YW1wbGVzOgoKICogRGVsZXRpbmcgYWxsIGV2ZW50cyBpbiBh
IHRpbWUgcmFuZ2U6CiAgIGBldmVudFRpbWUgPiAiMjAxMi0wNC0yM1QxODoyNTo0My41MTFa
IgogICBldmVudFRpbWUgPCAiMjAxMi0wNC0yM1QxODozMDo0My41MTFaImAKICogRGVsZXRp
bmcgc3BlY2lmaWMgZXZlbnRUeXBlIGluIGEgdGltZSByYW5nZToKICAgYGV2ZW50VGltZSA+
ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiCiAgIGV2ZW50VGltZSA8ICIyMDEyLTA0LTIz
VDE4OjMwOjQzLjUxMVoiIGV2ZW50VHlwZSA9ICJzZWFyY2giYAogKiBEZWxldGluZyBhbGwg
ZXZlbnRzIGZvciBhIHNwZWNpZmljIHZpc2l0b3IgaW4gYSB0aW1lIHJhbmdlOgogICBgZXZl
bnRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTExWiIKICAgZXZlbnRUaW1lIDwgIjIw
MTItMDQtMjNUMTg6MzA6NDMuNTExWiIgdXNlclBzZXVkb0lkID0gInZpc2l0b3IxMDI0ImAK
ICogRGVsZXRpbmcgdGhlIHBhc3QgMzAgZGF5cyBvZiBldmVudHMgaW5zaWRlIGEgRGF0YVN0
b3JlOgogICBgKmAKCiBUaGUgZmlsdGVyaW5nIGZpZWxkcyBhcmUgYXNzdW1lZCB0byBoYXZl
IGFuIGltcGxpY2l0IEFORC4KCgwKBQQAAgEFEgNKAggKDAoFBAACAQESA0oJDwoMCgUEAAIB
AxIDShITCgwKBQQAAgEIEgNKFDwKDwoIBAACAQicCAASA0oVOwrbAgoEBAACAhIDUgIRGs0C
IFRoZSBgZm9yY2VgIGZpZWxkIGlzIGN1cnJlbnRseSBub3Qgc3VwcG9ydGVkLiBQdXJnZSB1
c2VyIGV2ZW50IHJlcXVlc3RzCiB3aWxsIHBlcm1hbmVudGx5IGRlbGV0ZSBhbGwgcHVyZ2Vh
YmxlIGV2ZW50cy4gT25jZSB0aGUgZGV2ZWxvcG1lbnQgaXMKIGNvbXBsZXRlOgogSWYgYGZv
cmNlYCBpcyBzZXQgdG8gZmFsc2UsIHRoZSBtZXRob2Qgd2lsbCByZXR1cm4gdGhlIGV4cGVj
dGVkCiBwdXJnZSBjb3VudCB3aXRob3V0IGRlbGV0aW5nIGFueSB1c2VyIGV2ZW50cy4gVGhp
cyBmaWVsZCB3aWxsIGRlZmF1bHQgdG8KIGZhbHNlIGlmIG5vdCBpbmNsdWRlZCBpbiB0aGUg
cmVxdWVzdC4KCgwKBQQAAgIFEgNSAgYKDAoFBAACAgESA1IHDAoMCgUEAAICAxIDUg8QCr8B
CgIEARIEWABbARqyASBSZXNwb25zZSBvZiB0aGUgUHVyZ2VVc2VyRXZlbnRzUmVxdWVzdC4g
SWYgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24gaXMKIHN1Y2Nlc3NmdWxseSBkb25lLCB0
aGVuIHRoaXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0aGUKIGdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkLgoKCgoDBAEBEgNYCB8KTQoEBAECABIDWgIY
GkAgVGhlIHRvdGFsIGNvdW50IG9mIGV2ZW50cyBwdXJnZWQgYXMgYSByZXN1bHQgb2YgdGhl
IG9wZXJhdGlvbi4KCgwKBQQBAgAFEgNaAgcKDAoFBAECAAESA1oIEwoMCgUEAQIAAxIDWhYX
CpwBCgIEAhIEXwBsARqPASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0
aGUgUHVyZ2VVc2VyRXZlbnRzIG9wZXJhdGlvbi4KIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBi
eSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YSBmaWVsZC4KCgoK
AwQCARIDXwgfCiUKBAQCAgASA2ECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCgwKBQQC
AgAGEgNhAhsKDAoFBAICAAESA2EcJwoMCgUEAgIAAxIDYSorCmMKBAQCAgESA2UCLBpWIE9w
ZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRo
aXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDAoFBAICAQYSA2UCGwoMCgUEAgIBARID
ZRwnCgwKBQQCAgEDEgNlKisKPwoEBAICAhIDaAIaGjIgQ291bnQgb2YgZW50cmllcyB0aGF0
IHdlcmUgZGVsZXRlZCBzdWNjZXNzZnVsbHkuCgoMCgUEAgICBRIDaAIHCgwKBQQCAgIBEgNo
CBUKDAoFBAICAgMSA2gYGQpJCgQEAgIDEgNrAhoaPCBDb3VudCBvZiBlbnRyaWVzIHRoYXQg
ZW5jb3VudGVyZWQgZXJyb3JzIHdoaWxlIHByb2Nlc3NpbmcuCgoMCgUEAgIDBRIDawIHCgwK
BQQCAgMBEgNrCBUKDAoFBAICAwMSA2sYGQpECgIEAxIEbwB4ARo4IENvbmZpZ3VyYXRpb24g
b2YgZGVzdGluYXRpb24gZm9yIFB1cmdlIHJlbGF0ZWQgZXJyb3JzLgoKCgoDBAMBEgNvCBgK
LQoEBAMIABIEcQJ3AxofIFJlcXVpcmVkLiBFcnJvcnMgZGVzdGluYXRpb24uCgoMCgUEAwgA
ARIDcQgTCuwBCgQEAwIAEgN2BBoa3gEgQ2xvdWQgU3RvcmFnZSBwcmVmaXggZm9yIHB1cmdl
IGVycm9ycy4gVGhpcyBtdXN0IGJlIGFuIGVtcHR5LAogZXhpc3RpbmcgQ2xvdWQgU3RvcmFn
ZSBkaXJlY3RvcnkuIFB1cmdlIGVycm9ycyBhcmUgd3JpdHRlbiB0bwogc2hhcmRlZCBmaWxl
cyBpbiB0aGlzIGRpcmVjdG9yeSwgb25lIHBlciBsaW5lLCBhcyBhIEpTT04tZW5jb2RlZAog
YGdvb2dsZS5ycGMuU3RhdHVzYCBtZXNzYWdlLgoKDAoFBAMCAAUSA3YECgoMCgUEAwIAARID
dgsVCgwKBQQDAgADEgN2GBkKjgEKAgQEEgV9AK4BARqAASBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbRG9jdW1lbnRTZXJ2aWNlLlB1cmdlRG9jdW1lbnRzXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLkRvY3VtZW50U2VydmljZS5QdXJnZURvY3VtZW50c10KIG1ldGhvZC4K
CgoKAwQEARIDfQgdCqgBCgQEBAMAEgaBAQKMAQMalwEgVGhlIGlubGluZSBzb3VyY2UgZm9y
IHRoZSBpbnB1dCBjb25maWcgZm9yCiBbRG9jdW1lbnRTZXJ2aWNlLlB1cmdlRG9jdW1lbnRz
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50U2VydmljZS5QdXJn
ZURvY3VtZW50c10KIG1ldGhvZC4KCg0KBQQEAwABEgSBAQoWCs0BCgYEBAMAAgASBoYBBIsB
Bhq6ASBSZXF1aXJlZC4gQSBsaXN0IG9mIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBkb2N1bWVu
dHMgdG8gcHVyZ2UuIEluIHRoZQogZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
b2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qYC4KIFJl
Y29tbWVuZGVkIG1heCBvZiAxMDAgaXRlbXMuCgoPCgcEBAMAAgAEEgSGAQQMCg8KBwQEAwAC
AAUSBIYBDRMKDwoHBAQDAAIAARIEhgEUHQoPCgcEBAMAAgADEgSGASAhChEKBwQEAwACAAgS
BoYBIosBBQoSCgoEBAMAAgAInAgAEgSHAQYsChMKCQQEAwACAAifCBIGiAEGigEHClsKBAQE
CAASBo8BApgBAxpLIFRoZSBkZXNpcmVkIGlucHV0IHNvdXJjZSBmb3IgdGhlIHB1cmdpbmcg
ZG9jdW1lbnRzIGJhc2VkIG9uIGRvY3VtZW50IElEcy4KCg0KBQQECAABEgSPAQgOCroBCgQE
BAIAEgSUAQQdGqsBIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gZm9yIHRoZSBpbnB1dCBjb250
ZW50LgogU3VwcG9ydGVkIGBkYXRhX3NjaGVtYWA6CiAqIGBkb2N1bWVudF9pZGA6IE9uZSB2
YWxpZAogW0RvY3VtZW50LmlkXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRv
Y3VtZW50LmlkXSBwZXIgbGluZS4KCg0KBQQEAgAGEgSUAQQNCg0KBQQEAgABEgSUAQ4YCg0K
BQQEAgADEgSUARscCj4KBAQEAgESBJcBBCMaMCBJbmxpbmUgc291cmNlIGZvciB0aGUgaW5w
dXQgY29udGVudCBmb3IgcHVyZ2UuCgoNCgUEBAIBBhIElwEEEAoNCgUEBAIBARIElwERHgoN
CgUEBAIBAxIElwEhIgqtAQoEBAQCAhIGnAECoQEEGpwBIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFf
c3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9YC4KCg0KBQQEAgIFEgScAQIICg0KBQQEAgIBEgSc
AQkPCg0KBQQEAgIDEgScARITCg8KBQQEAgIIEgacARShAQMKEAoIBAQCAgicCAASBJ0BBCoK
EQoHBAQCAgifCBIGngEEoAEFCnIKBAQEAgMSBKYBAj0aZCBSZXF1aXJlZC4gRmlsdGVyIG1h
dGNoaW5nIGRvY3VtZW50cyB0byBwdXJnZS4gT25seSBjdXJyZW50bHkgc3VwcG9ydGVkCiB2
YWx1ZSBpcwogYCpgIChhbGwgaXRlbXMpLgoKDQoFBAQCAwUSBKYBAggKDQoFBAQCAwESBKYB
CQ8KDQoFBAQCAwMSBKYBEhMKDQoFBAQCAwgSBKYBFDwKEAoIBAQCAwicCAASBKYBFTsKSQoE
BAQCBBIEqQECJBo7IFRoZSBkZXNpcmVkIGxvY2F0aW9uIG9mIGVycm9ycyBpbmN1cnJlZCBk
dXJpbmcgdGhlIHB1cmdlLgoKDQoFBAQCBAYSBKkBAhIKDQoFBAQCBAESBKkBEx8KDQoFBAQC
BAMSBKkBIiMKiQEKBAQEAgUSBK0BAhEaeyBBY3R1YWxseSBwZXJmb3JtcyB0aGUgcHVyZ2Uu
IElmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLCByZXR1cm4gdGhlCiBleHBlY3RlZCBwdXJn
ZSBjb3VudCB3aXRob3V0IGRlbGV0aW5nIGFueSBkb2N1bWVudHMuCgoNCgUEBAIFBRIErQEC
BgoNCgUEBAIFARIErQEHDAoNCgUEBAIFAxIErQEPEAqYAgoCBAUSBrQBAL4BARqJAiBSZXNw
b25zZSBtZXNzYWdlIGZvcgogW0RvY3VtZW50U2VydmljZS5QdXJnZURvY3VtZW50c11bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudFNlcnZpY2UuUHVyZ2VEb2N1
bWVudHNdCiBtZXRob2QuIElmIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIGlzIHN1Y2Nl
c3NmdWxseSBkb25lLCB0aGVuIHRoaXMgbWVzc2FnZQogaXMgcmV0dXJuZWQgYnkgdGhlIGdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkLgoKCwoDBAUBEgS0
AQgeClEKBAQFAgASBLYBAhgaQyBUaGUgdG90YWwgY291bnQgb2YgZG9jdW1lbnRzIHB1cmdl
ZCBhcyBhIHJlc3VsdCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAUCAAUSBLYBAgcKDQoFBAUC
AAESBLYBCBMKDQoFBAUCAAMSBLYBFhcKuAEKBAQFAgESBrsBAr0BBRqnASBBIHNhbXBsZSBv
ZiBkb2N1bWVudCBuYW1lcyB0aGF0IHdpbGwgYmUgZGVsZXRlZC4gT25seSBwb3B1bGF0ZWQg
aWYgYGZvcmNlYAogaXMgc2V0IHRvIGZhbHNlLiBBIG1heCBvZiAxMDAgbmFtZXMgd2lsbCBi
ZSByZXR1cm5lZCBhbmQgdGhlIG5hbWVzIGFyZQogY2hvc2VuIGF0IHJhbmRvbS4KCg0KBQQF
AgEEEgS7AQIKCg0KBQQFAgEFEgS7AQsRCg0KBQQFAgEBEgS7ARIeCg0KBQQFAgEDEgS7ASEi
Cg8KBQQFAgEIEga7ASO9AQQKEQoHBAUCAQifCBIGuwEkvQEDCp0BCgIEBhIGwgEA0gEBGo4B
IE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZSBQdXJnZURvY3VtZW50
cyBvcGVyYXRpb24uCiBUaGlzIHdpbGwgYmUgcmV0dXJuZWQgYnkgdGhlIGdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEgZmllbGQuCgoLCgMEBgESBMIBCB4KJgoEBAYC
ABIExAECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQGAgAGEgTEAQIbCg0KBQQG
AgABEgTEARwnCg0KBQQGAgADEgTEASorCmQKBAQGAgESBMgBAiwaViBPcGVyYXRpb24gbGFz
dCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28g
dGhlCiBmaW5pc2ggdGltZS4KCg0KBQQGAgEGEgTIAQIbCg0KBQQGAgEBEgTIARwnCg0KBQQG
AgEDEgTIASorCkAKBAQGAgISBMsBAhoaMiBDb3VudCBvZiBlbnRyaWVzIHRoYXQgd2VyZSBk
ZWxldGVkIHN1Y2Nlc3NmdWxseS4KCg0KBQQGAgIFEgTLAQIHCg0KBQQGAgIBEgTLAQgVCg0K
BQQGAgIDEgTLARgZCkoKBAQGAgMSBM4BAhoaPCBDb3VudCBvZiBlbnRyaWVzIHRoYXQgZW5j
b3VudGVyZWQgZXJyb3JzIHdoaWxlIHByb2Nlc3NpbmcuCgoNCgUEBgIDBRIEzgECBwoNCgUE
BgIDARIEzgEIFQoNCgUEBgIDAxIEzgEYGQpNCgQEBgIEEgTRAQIaGj8gQ291bnQgb2YgZW50
cmllcyB0aGF0IHdlcmUgaWdub3JlZCBhcyBlbnRyaWVzIHdlcmUgbm90IGZvdW5kLgoKDQoF
BAYCBAUSBNEBAgcKDQoFBAYCBAESBNEBCBUKDQoFBAYCBAMSBNEBGBkKswEKAgQHEgbXAQDg
AQEapAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0NvbXBsZXRpb25TZXJ2aWNlLlB1cmdlU3Vn
Z2VzdGlvbkRlbnlMaXN0RW50cmllc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5Db21wbGV0aW9uU2VydmljZS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNdCiBt
ZXRob2QuCgoLCgMEBwESBNcBCC0KqgEKBAQHAgASBtoBAt8BBBqZASBSZXF1aXJlZC4gVGhl
IHBhcmVudCBkYXRhIHN0b3JlIHJlc291cmNlIG5hbWUgZm9yIHdoaWNoIHRvIGltcG9ydCBk
ZW55bGlzdAogZW50cmllcy4gRm9sbG93cyBwYXR0ZXJuIHByb2plY3RzLyovbG9jYXRpb25z
LyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyouCgoNCgUEBwIABRIE2gECCAoNCgUEBwIA
ARIE2gEJDwoNCgUEBwIAAxIE2gESEwoPCgUEBwIACBIG2gEU3wEDChAKCAQHAgAInAgAEgTb
AQQqChEKBwQHAgAInwgSBtwBBN4BBQq0AQoCBAgSBuUBAOsBARqlASBSZXNwb25zZSBtZXNz
YWdlIGZvcgogW0NvbXBsZXRpb25TZXJ2aWNlLlB1cmdlU3VnZ2VzdGlvbkRlbnlMaXN0RW50
cmllc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db21wbGV0aW9uU2Vydmlj
ZS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNdCiBtZXRob2QuCgoLCgMECAESBOUB
CC4KPgoEBAgCABIE5wECGBowIE51bWJlciBvZiBzdWdnZXN0aW9uIGRlbnkgbGlzdCBlbnRy
aWVzIHB1cmdlZC4KCg0KBQQIAgAFEgTnAQIHCg0KBQQIAgABEgTnAQgTCg0KBQQIAgADEgTn
ARYXCkwKBAQIAgESBOoBAi8aPiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hp
bGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVzdC4KCg0KBQQIAgEEEgTqAQIKCg0KBQQIAgEGEgTq
AQscCg0KBQQIAgEBEgTqAR0qCg0KBQQIAgEDEgTqAS0uCqkBCgIECRIG8AEA9wEBGpoBIE1l
dGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZSBQdXJnZVN1Z2dlc3Rpb25E
ZW55TGlzdEVudHJpZXMKIG9wZXJhdGlvbi4gVGhpcyBpcyByZXR1cm5lZCBieSB0aGUgZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMECQESBPAB
CC4KJgoEBAkCABIE8gECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQJAgAGEgTy
AQIbCg0KBQQJAgABEgTyARwnCg0KBQQJAgADEgTyASorCmQKBAQJAgESBPYBAiwaViBPcGVy
YXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlz
IGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQJAgEGEgT2AQIbCg0KBQQJAgEBEgT2
ARwnCg0KBQQJAgEDEgT2ASorCqsBCgIEChIG/AEAhgIBGpwBIFJlcXVlc3QgbWVzc2FnZSBm
b3IKIFtDb21wbGV0aW9uU2VydmljZS5QdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc11bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db21wbGV0aW9uU2VydmljZS5QdXJnZUNv
bXBsZXRpb25TdWdnZXN0aW9uc10KIG1ldGhvZC4KCgsKAwQKARIE/AEIKQqwAQoEBAoCABIG
gAIChQIEGp8BIFJlcXVpcmVkLiBUaGUgcGFyZW50IGRhdGEgc3RvcmUgcmVzb3VyY2UgbmFt
ZSBmb3Igd2hpY2ggdG8gcHVyZ2UgY29tcGxldGlvbgogc3VnZ2VzdGlvbnMuIEZvbGxvd3Mg
cGF0dGVybgogcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9y
ZXMvKi4KCg0KBQQKAgAFEgSAAgIICg0KBQQKAgABEgSAAgkPCg0KBQQKAgADEgSAAhITCg8K
BQQKAgAIEgaAAhSFAgMKEAoIBAoCAAicCAASBIECBCoKEQoHBAoCAAifCBIGggIEhAIFCrQC
CgIECxIGjAIAkgIBGqUCIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbQ29tcGxldGlvblNlcnZp
Y2UuUHVyZ2VDb21wbGV0aW9uU3VnZ2VzdGlvbnNdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuQ29tcGxldGlvblNlcnZpY2UuUHVyZ2VDb21wbGV0aW9uU3VnZ2VzdGlvbnNd
CiBtZXRob2QuIElmIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIGlzIHN1Y2Nlc3NmdWxs
eSBkb25lLCB0aGVuIHRoaXMKIG1lc3NhZ2UgaXMgcmV0dXJuZWQgYnkgdGhlIGdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkLgoKCwoDBAsBEgSMAggqCkwK
BAQLAgASBI4CAhsaPiBXaGV0aGVyIHRoZSBjb21wbGV0aW9uIHN1Z2dlc3Rpb25zIHdlcmUg
c3VjY2Vzc2Z1bGx5IHB1cmdlZC4KCg0KBQQLAgAFEgSOAgIGCg0KBQQLAgABEgSOAgcWCg0K
BQQLAgADEgSOAhkaCkwKBAQLAgESBJECAi8aPiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3Vu
dGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVzdC4KCg0KBQQLAgEEEgSRAgIKCg0K
BQQLAgEGEgSRAgscCg0KBQQLAgEBEgSRAh0qCg0KBQQLAgEDEgSRAi0uCqUBCgIEDBIGlwIA
ngIBGpYBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZSBQdXJnZUNv
bXBsZXRpb25TdWdnZXN0aW9ucwogb3BlcmF0aW9uLiBUaGlzIGlzIHJldHVybmVkIGJ5IHRo
ZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVsZC4KCgsKAwQM
ARIElwIIKgomCgQEDAIAEgSZAgIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAwC
AAYSBJkCAhsKDQoFBAwCAAESBJkCHCcKDQoFBAwCAAMSBJkCKisKZAoEBAwCARIEnQICLBpW
IE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUs
IHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAwCAQYSBJ0CAhsKDQoFBAwC
AQESBJ0CHCcKDQoFBAwCAQMSBJ0CKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsRequest ===
    # Fields for PurgeUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsResponse ===
    # Fields for PurgeUserEventsResponse
    # Field: purge_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsMetadata ===
    # Fields for PurgeUserEventsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeErrorConfig ===
    # Fields for PurgeErrorConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsRequest ===
    # Fields for PurgeDocumentsRequest
    # Field: gcs_source Type: 11 (.google.cloud.discoveryengine.v1.GcsSource)
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1.PurgeDocumentsRequest.InlineSource)
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1.PurgeErrorConfig)
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsResponse ===
    # Fields for PurgeDocumentsResponse
    # Field: purge_count Type: 3 ()
    # Field: purge_sample Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsMetadata ===
    # Fields for PurgeDocumentsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: ignored_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeSuggestionDenyListEntriesRequest ===
    # Fields for PurgeSuggestionDenyListEntriesRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeSuggestionDenyListEntriesResponse ===
    # Fields for PurgeSuggestionDenyListEntriesResponse
    # Field: purge_count Type: 3 ()
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata ===
    # Fields for PurgeSuggestionDenyListEntriesMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeCompletionSuggestionsRequest ===
    # Fields for PurgeCompletionSuggestionsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeCompletionSuggestionsResponse ===
    # Fields for PurgeCompletionSuggestionsResponse
    # Field: purge_succeeded Type: 8 ()
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeCompletionSuggestionsMetadata ===
    # Fields for PurgeCompletionSuggestionsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::PurgeConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/purge_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::PurgeConfig;

    my $msg = Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsRequest->new({
        parent => $parent,
        filter => $filter,
        force => $force,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/purge_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsRequest

Request message for PurgeUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the catalog under which the events are
created. The format is
`projects/{project}/locations/global/collections/{collection}/dataStores/{dataStore}`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the events to be deleted with a
length limit of 5,000 characters. The eligible fields for filtering are:

* `eventType`: Double quoted
[UserEvent.event_type][google.cloud.discoveryengine.v1.UserEvent.event_type]
string.
* `eventTime`: in ISO 8601 "zulu" format.
* `userPseudoId`: Double quoted string. Specifying this will delete all
  events associated with a visitor.
* `userId`: Double quoted string. Specifying this will delete all events
  associated with a user.

Note: This API only supports purging a max range of 30 days.

Examples:

* Deleting all events in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z"`
* Deleting specific eventType in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z" eventType = "search"`
* Deleting all events for a specific visitor in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z" userPseudoId = "visitor1024"`
* Deleting the past 30 days of events inside a DataStore:
  `*`

The filtering fields are assumed to have an implicit AND.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

The `force` field is currently not supported. Purge user event requests
will permanently delete all purgeable events. Once the development is
complete:
If `force` is set to false, the method will return the expected
purge count without deleting any user events. This field will default to
false if not included in the request.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsResponse

Response of the PurgeUserEventsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of events purged as a result of the operation.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeUserEventsMetadata

Metadata related to the progress of the PurgeUserEvents operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeErrorConfig

Configuration of destination for Purge related errors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<String>

Cloud Storage prefix for purge errors. This must be an empty,
existing Cloud Storage directory. Purge errors are written to
sharded files in this directory, one per line, as a JSON-encoded
`google.rpc.Status` message.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsRequest

Request message for
[DocumentService.PurgeDocuments][google.cloud.discoveryengine.v1.DocumentService.PurgeDocuments]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ImportConfig::GcsSource>)

Cloud Storage location for the input content.
Supported `data_schema`:
* `document_id`: One valid
[Document.id][google.cloud.discoveryengine.v1.Document.id] per line.

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsRequest::InlineSource>)

Inline source for the input content for purge.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. Filter matching documents to purge. Only currently supported
value is
`*` (all items).

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeErrorConfig>)

The desired location of errors incurred during the purge.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually performs the purge. If `force` is set to false, return the
expected purge count without deleting any documents.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsResponse

Response message for
[DocumentService.PurgeDocuments][google.cloud.discoveryengine.v1.DocumentService.PurgeDocuments]
method. If the long running operation is successfully done, then this message
is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of documents purged as a result of the operation.

=item * C<< $msg->purge_sample() >> / C<< $msg->purge_sample($value) >>

Type: C<String>

A sample of document names that will be deleted. Only populated if `force`
is set to false. A max of 100 names will be returned and the names are
chosen at random.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsMetadata

Metadata related to the progress of the PurgeDocuments operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=item * C<< $msg->ignored_count() >> / C<< $msg->ignored_count($value) >>

Type: C<Int64>

Count of entries that were ignored as entries were not found.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeSuggestionDenyListEntriesRequest

Request message for
[CompletionService.PurgeSuggestionDenyListEntries][google.cloud.discoveryengine.v1.CompletionService.PurgeSuggestionDenyListEntries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name for which to import denylist
entries. Follows pattern projects/*/locations/*/collections/*/dataStores/*.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeSuggestionDenyListEntriesResponse

Response message for
[CompletionService.PurgeSuggestionDenyListEntries][google.cloud.discoveryengine.v1.CompletionService.PurgeSuggestionDenyListEntries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

Number of suggestion deny list entries purged.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata

Metadata related to the progress of the PurgeSuggestionDenyListEntries
operation. This is returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeCompletionSuggestionsRequest

Request message for
[CompletionService.PurgeCompletionSuggestions][google.cloud.discoveryengine.v1.CompletionService.PurgeCompletionSuggestions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name for which to purge completion
suggestions. Follows pattern
projects/*/locations/*/collections/*/dataStores/*.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeCompletionSuggestionsResponse

Response message for
[CompletionService.PurgeCompletionSuggestions][google.cloud.discoveryengine.v1.CompletionService.PurgeCompletionSuggestions]
method. If the long running operation is successfully done, then this
message is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_succeeded() >> / C<< $msg->purge_succeeded($value) >>

Type: C<Bool>

Whether the completion suggestions were successfully purged.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeCompletionSuggestionsMetadata

Metadata related to the progress of the PurgeCompletionSuggestions
operation. This is returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::PurgeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
