package Google::Cloud::Notebooks::V1::ManagedService;

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
    eval { require Google::Cloud::Notebooks::V1::DiagnosticConfig };
    eval { require Google::Cloud::Notebooks::V1::Event };
    eval { require Google::Cloud::Notebooks::V1::Runtime };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL21hbmFnZWRfc2VydmljZS5wcm90bxIZZ29v
Z2xlLmNsb3VkLm5vdGVib29rcy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMWdvb2dsZS9jbG91ZC9ub3RlYm9va3Mv
djEvZGlhZ25vc3RpY19jb25maWcucHJvdG8aJWdvb2dsZS9jbG91ZC9ub3RlYm9va3MvdjEv
ZXZlbnQucHJvdG8aJ2dvb2dsZS9jbG91ZC9ub3RlYm9va3MvdjEvcnVudGltZS5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9m
aWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpMBChNM
aXN0UnVudGltZXNSZXF1ZXN0EkAKBnBhcmVudBgBIAEoCUIo4EEC+kEiEiBub3RlYm9va3Mu
Z29vZ2xlYXBpcy5jb20vUnVudGltZVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFn
ZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIqABChRMaXN0UnVudGltZXNS
ZXNwb25zZRI+CghydW50aW1lcxgBIAMoCzIiLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEu
UnVudGltZVIIcnVudGltZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJRChFHZXRSdW50aW1lUmVx
dWVzdBI8CgRuYW1lGAEgASgJQijgQQL6QSIKIG5vdGVib29rcy5nb29nbGVhcGlzLmNvbS9S
dW50aW1lUgRuYW1lIt4BChRDcmVhdGVSdW50aW1lUmVxdWVzdBJACgZwYXJlbnQYASABKAlC
KOBBAvpBIgogbm90ZWJvb2tzLmdvb2dsZWFwaXMuY29tL1J1bnRpbWVSBnBhcmVudBIiCgpy
dW50aW1lX2lkGAIgASgJQgPgQQJSCXJ1bnRpbWVJZBJBCgdydW50aW1lGAMgASgLMiIuZ29v
Z2xlLmNsb3VkLm5vdGVib29rcy52MS5SdW50aW1lQgPgQQJSB3J1bnRpbWUSHQoKcmVxdWVz
dF9pZBgEIAEoCVIJcmVxdWVzdElkInMKFERlbGV0ZVJ1bnRpbWVSZXF1ZXN0EjwKBG5hbWUY
ASABKAlCKOBBAvpBIgogbm90ZWJvb2tzLmdvb2dsZWFwaXMuY29tL1J1bnRpbWVSBG5hbWUS
HQoKcmVxdWVzdF9pZBgCIAEoCVIJcmVxdWVzdElkIk0KE1N0YXJ0UnVudGltZVJlcXVlc3QS
FwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJ
ZCJMChJTdG9wUnVudGltZVJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEh0KCnJl
cXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJZCLVAQoUU3dpdGNoUnVudGltZVJlcXVlc3QSFwoE
bmFtZRgBIAEoCUID4EECUgRuYW1lEiEKDG1hY2hpbmVfdHlwZRgCIAEoCVILbWFjaGluZVR5
cGUSYgoSYWNjZWxlcmF0b3JfY29uZmlnGAMgASgLMjMuZ29vZ2xlLmNsb3VkLm5vdGVib29r
cy52MS5SdW50aW1lQWNjZWxlcmF0b3JDb25maWdSEWFjY2VsZXJhdG9yQ29uZmlnEh0KCnJl
cXVlc3RfaWQYBCABKAlSCXJlcXVlc3RJZCJNChNSZXNldFJ1bnRpbWVSZXF1ZXN0EhcKBG5h
bWUYASABKAlCA+BBAlIEbmFtZRIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1ZXN0SWQiTwoV
VXBncmFkZVJ1bnRpbWVSZXF1ZXN0EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIdCgpyZXF1
ZXN0X2lkGAIgASgJUglyZXF1ZXN0SWQisAEKGVJlcG9ydFJ1bnRpbWVFdmVudFJlcXVlc3QS
PAoEbmFtZRgBIAEoCUIo4EEC+kEiCiBub3RlYm9va3MuZ29vZ2xlYXBpcy5jb20vUnVudGlt
ZVIEbmFtZRIYCgV2bV9pZBgCIAEoCUID4EECUgR2bUlkEjsKBWV2ZW50GAMgASgLMiAuZ29v
Z2xlLmNsb3VkLm5vdGVib29rcy52MS5FdmVudEID4EECUgVldmVudCK6AQoUVXBkYXRlUnVu
dGltZVJlcXVlc3QSQQoHcnVudGltZRgBIAEoCzIiLmdvb2dsZS5jbG91ZC5ub3RlYm9va3Mu
djEuUnVudGltZUID4EECUgdydW50aW1lEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrEh0KCnJlcXVlc3RfaWQYAyAB
KAlSCXJlcXVlc3RJZCJ8CiJSZWZyZXNoUnVudGltZVRva2VuSW50ZXJuYWxSZXF1ZXN0EjwK
BG5hbWUYASABKAlCKOBBAvpBIgogbm90ZWJvb2tzLmdvb2dsZWFwaXMuY29tL1J1bnRpbWVS
BG5hbWUSGAoFdm1faWQYAiABKAlCA+BBAlIEdm1JZCKKAQojUmVmcmVzaFJ1bnRpbWVUb2tl
bkludGVybmFsUmVzcG9uc2USIQoMYWNjZXNzX3Rva2VuGAEgASgJUgthY2Nlc3NUb2tlbhJA
CgtleHBpcmVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
ZXhwaXJlVGltZSK1AQoWRGlhZ25vc2VSdW50aW1lUmVxdWVzdBI8CgRuYW1lGAEgASgJQijg
QQL6QSIKIG5vdGVib29rcy5nb29nbGVhcGlzLmNvbS9SdW50aW1lUgRuYW1lEl0KEWRpYWdu
b3N0aWNfY29uZmlnGAIgASgLMisuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MS5EaWFnbm9z
dGljQ29uZmlnQgPgQQJSEGRpYWdub3N0aWNDb25maWcy0hUKFk1hbmFnZWROb3RlYm9va1Nl
cnZpY2USrgEKDExpc3RSdW50aW1lcxIuLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuTGlz
dFJ1bnRpbWVzUmVxdWVzdBovLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuTGlzdFJ1bnRp
bWVzUmVzcG9uc2UiPYLT5JMCLhIsL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Kn0vcnVudGltZXPaQQZwYXJlbnQSmwEKCkdldFJ1bnRpbWUSLC5nb29nbGUuY2xvdWQubm90
ZWJvb2tzLnYxLkdldFJ1bnRpbWVSZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52
MS5SdW50aW1lIjuC0+STAi4SLC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3J1
bnRpbWVzLyp92kEEbmFtZRLZAQoNQ3JlYXRlUnVudGltZRIvLmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjEuQ3JlYXRlUnVudGltZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uIniC0+STAjciLC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3J1
bnRpbWVzOgdydW50aW1l2kEZcGFyZW50LHJ1bnRpbWVfaWQscnVudGltZcpBHAoHUnVudGlt
ZRIRT3BlcmF0aW9uTWV0YWRhdGES2wEKDVVwZGF0ZVJ1bnRpbWUSLy5nb29nbGUuY2xvdWQu
bm90ZWJvb2tzLnYxLlVwZGF0ZVJ1bnRpbWVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbiJ6gtPkkwI/MjQvdjEve3J1bnRpbWUubmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL3J1bnRpbWVzLyp9OgdydW50aW1l2kETcnVudGltZSx1cGRhdGVfbWFza8pBHAoH
UnVudGltZRIRT3BlcmF0aW9uTWV0YWRhdGESyQEKDURlbGV0ZVJ1bnRpbWUSLy5nb29nbGUu
Y2xvdWQubm90ZWJvb2tzLnYxLkRlbGV0ZVJ1bnRpbWVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbiJogtPkkwIuKiwvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9ydW50aW1lcy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIRT3Bl
cmF0aW9uTWV0YWRhdGESwgEKDFN0YXJ0UnVudGltZRIuLmdvb2dsZS5jbG91ZC5ub3RlYm9v
a3MudjEuU3RhcnRSdW50aW1lUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24iY4LT5JMCNyIyL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcnVudGltZXMv
Kn06c3RhcnQ6ASraQQRuYW1lykEcCgdSdW50aW1lEhFPcGVyYXRpb25NZXRhZGF0YRK/AQoL
U3RvcFJ1bnRpbWUSLS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLlN0b3BSdW50aW1lUmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iYoLT5JMCNiIxL3YxL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovcnVudGltZXMvKn06c3RvcDoBKtpBBG5hbWXKQRwK
B1J1bnRpbWUSEU9wZXJhdGlvbk1ldGFkYXRhEsUBCg1Td2l0Y2hSdW50aW1lEi8uZ29vZ2xl
LmNsb3VkLm5vdGVib29rcy52MS5Td2l0Y2hSdW50aW1lUmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24iZILT5JMCOCIzL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovcnVudGltZXMvKn06c3dpdGNoOgEq2kEEbmFtZcpBHAoHUnVudGltZRIRT3BlcmF0
aW9uTWV0YWRhdGESwgEKDFJlc2V0UnVudGltZRIuLmdvb2dsZS5jbG91ZC5ub3RlYm9va3Mu
djEuUmVzZXRSdW50aW1lUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i
Y4LT5JMCNyIyL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcnVudGltZXMvKn06
cmVzZXQ6ASraQQRuYW1lykEcCgdSdW50aW1lEhFPcGVyYXRpb25NZXRhZGF0YRLIAQoOVXBn
cmFkZVJ1bnRpbWUSMC5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLlVwZ3JhZGVSdW50aW1l
UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iZYLT5JMCOSI0L3YxL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcnVudGltZXMvKn06dXBncmFkZToBKtpBBG5h
bWXKQRwKB1J1bnRpbWUSEU9wZXJhdGlvbk1ldGFkYXRhEtQBChJSZXBvcnRSdW50aW1lRXZl
bnQSNC5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLlJlcG9ydFJ1bnRpbWVFdmVudFJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uImmC0+STAj0iOC92MS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL3J1bnRpbWVzLyp9OnJlcG9ydEV2ZW50OgEq2kEEbmFt
ZcpBHAoHUnVudGltZRIRT3BlcmF0aW9uTWV0YWRhdGES/gEKG1JlZnJlc2hSdW50aW1lVG9r
ZW5JbnRlcm5hbBI9Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuUmVmcmVzaFJ1bnRpbWVU
b2tlbkludGVybmFsUmVxdWVzdBo+Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuUmVmcmVz
aFJ1bnRpbWVUb2tlbkludGVybmFsUmVzcG9uc2UiYILT5JMCTSJIL3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovcnVudGltZXMvKn06cmVmcmVzaFJ1bnRpbWVUb2tlbkludGVy
bmFsOgEq2kEKbmFtZSx2bV9pZBLdAQoPRGlhZ25vc2VSdW50aW1lEjEuZ29vZ2xlLmNsb3Vk
Lm5vdGVib29rcy52MS5EaWFnbm9zZVJ1bnRpbWVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbiJ4gtPkkwI6IjUvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9ydW50aW1lcy8qfTpkaWFnbm9zZToBKtpBFm5hbWUsZGlhZ25vc3RpY19jb25maWfKQRwK
B1J1bnRpbWUSEU9wZXJhdGlvbk1ldGFkYXRhGkzKQRhub3RlYm9va3MuZ29vZ2xlYXBpcy5j
b23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQswB
Ch1jb20uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MUIVTWFuYWdlZE5vdGVib29rc1Byb3Rv
UAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vbm90ZWJvb2tzL2FwaXYxL25vdGVib29rc3BiO25v
dGVib29rc3BiqgIZR29vZ2xlLkNsb3VkLk5vdGVib29rcy5WMcoCGUdvb2dsZVxDbG91ZFxO
b3RlYm9va3NcVjHqAhxHb29nbGU6OkNsb3VkOjpOb3RlYm9va3M6OlYxSrRaCgcSBQ4AtgMB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAOwoJCgIDBRID
FwAvCgkKAgMGEgMYADEKCQoCAwcSAxkALQoJCgIDCBIDGgAqCgkKAgMJEgMbACkKCAoBCBID
HQA2CgkKAgglEgMdADYKCAoBCBIDHgBSCgkKAggLEgMeAFIKCAoBCBIDHwAiCgkKAggKEgMf
ACIKCAoBCBIDIAA2CgkKAggIEgMgADYKCAoBCBIDIQA2CgkKAggBEgMhADYKCAoBCBIDIgA2
CgkKAggpEgMiADYKCAoBCBIDIwA1CgkKAggtEgMjADUKNAoCBgASBSYAzQEBGicgQVBJIHYx
IHNlcnZpY2UgZm9yIE1hbmFnZWQgTm90ZWJvb2tzLgoKCgoDBgABEgMmCB4KCgoDBgADEgMn
AkAKDAoFBgADmQgSAycCQAoKCgMGAAMSAygCVgoMCgUGAAOaCBIDKAJWCj8KBAYAAgASBCsC
MAMaMSBMaXN0cyBSdW50aW1lcyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoK
DAoFBgACAAESAysGEgoMCgUGAAIAAhIDKxMmCgwKBQYAAgADEgMrMUUKDQoFBgACAAQSBCwE
LgYKEQoJBgACAASwyrwiEgQsBC4GCgwKBQYAAgAEEgMvBDQKDwoIBgACAASbCAASAy8ENApu
CgQGAAIBEgQ0AjkDGmAgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIFJ1bnRpbWUuIFRoZSBs
b2NhdGlvbiBtdXN0IGJlIGEgcmVnaW9uYWwgZW5kcG9pbnQKIHJhdGhlciB0aGFuIHpvbmFs
LgoKDAoFBgACAQESAzQGEAoMCgUGAAIBAhIDNBEiCgwKBQYAAgEDEgM0LTQKDQoFBgACAQQS
BDUENwYKEQoJBgACAQSwyrwiEgQ1BDcGCgwKBQYAAgEEEgM4BDIKDwoIBgACAQSbCAASAzgE
MgpGCgQGAAICEgQ8AkYDGjggQ3JlYXRlcyBhIG5ldyBSdW50aW1lIGluIGEgZ2l2ZW4gcHJv
amVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAICARIDPAYTCgwKBQYAAgICEgM8FCgKDAoFBgAC
AgMSAzwzTwoNCgUGAAICBBIEPQRABgoRCgkGAAICBLDKvCISBD0EQAYKDAoFBgACAgQSA0EE
RwoPCggGAAICBJsIABIDQQRHCg0KBQYAAgIEEgRCBEUGCg8KBwYAAgIEmQgSBEIERQYKNgoE
BgACAxIESQJTAxooIFVwZGF0ZSBOb3RlYm9vayBSdW50aW1lIGNvbmZpZ3VyYXRpb24uCgoM
CgUGAAIDARIDSQYTCgwKBQYAAgMCEgNJFCgKDAoFBgACAwMSA0kzTwoNCgUGAAIDBBIESgRN
BgoRCgkGAAIDBLDKvCISBEoETQYKDAoFBgACAwQSA04EQQoPCggGAAIDBJsIABIDTgRBCg0K
BQYAAgMEEgRPBFIGCg8KBwYAAgMEmQgSBE8EUgYKKQoEBgACBBIEVgJfAxobIERlbGV0ZXMg
YSBzaW5nbGUgUnVudGltZS4KCgwKBQYAAgQBEgNWBhMKDAoFBgACBAISA1YUKAoMCgUGAAIE
AxIDVjNPCg0KBQYAAgQEEgRXBFkGChEKCQYAAgQEsMq8IhIEVwRZBgoMCgUGAAIEBBIDWgQy
Cg8KCAYAAgQEmwgAEgNaBDIKDQoFBgACBAQSBFsEXgYKDwoHBgACBASZCBIEWwReBgqEAgoE
BgACBRIEZgJwAxr1ASBTdGFydHMgYSBNYW5hZ2VkIE5vdGVib29rIFJ1bnRpbWUuCiBQZXJm
b3JtICJTdGFydCIgb24gR1BVIGluc3RhbmNlczsgIlJlc3VtZSIgb24gQ1BVIGluc3RhbmNl
cwogU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9pbnN0YW5j
ZXMvc3RvcC1zdGFydC1pbnN0YW5jZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1
dGUvZG9jcy9pbnN0YW5jZXMvc3VzcGVuZC1yZXN1bWUtaW5zdGFuY2UKCgwKBQYAAgUBEgNm
BhIKDAoFBgACBQISA2YTJgoMCgUGAAIFAxIDZjFNCg0KBQYAAgUEEgRnBGoGChEKCQYAAgUE
sMq8IhIEZwRqBgoMCgUGAAIFBBIDawQyCg8KCAYAAgUEmwgAEgNrBDIKDQoFBgACBQQSBGwE
bwYKDwoHBgACBQSZCBIEbARvBgqEAgoEBgACBhIFdwKBAQMa9AEgU3RvcHMgYSBNYW5hZ2Vk
IE5vdGVib29rIFJ1bnRpbWUuCiBQZXJmb3JtICJTdG9wIiBvbiBHUFUgaW5zdGFuY2VzOyAi
U3VzcGVuZCIgb24gQ1BVIGluc3RhbmNlcwogU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2NvbXB1dGUvZG9jcy9pbnN0YW5jZXMvc3RvcC1zdGFydC1pbnN0YW5jZQogaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9pbnN0YW5jZXMvc3VzcGVuZC1yZXN1
bWUtaW5zdGFuY2UKCgwKBQYAAgYBEgN3BhEKDAoFBgACBgISA3cSJAoMCgUGAAIGAxIDdy9L
Cg0KBQYAAgYEEgR4BHsGChEKCQYAAgYEsMq8IhIEeAR7BgoMCgUGAAIGBBIDfAQyCg8KCAYA
AgYEmwgAEgN8BDIKDgoFBgACBgQSBX0EgAEGChAKBwYAAgYEmQgSBX0EgAEGCjQKBAYAAgcS
BoQBAo4BAxokIFN3aXRjaCBhIE1hbmFnZWQgTm90ZWJvb2sgUnVudGltZS4KCg0KBQYAAgcB
EgSEAQYTCg0KBQYAAgcCEgSEARQoCg0KBQYAAgcDEgSEATNPCg8KBQYAAgcEEgaFAQSIAQYK
EwoJBgACBwSwyrwiEgaFAQSIAQYKDQoFBgACBwQSBIkBBDIKEAoIBgACBwSbCAASBIkBBDIK
DwoFBgACBwQSBooBBI0BBgoRCgcGAAIHBJkIEgaKAQSNAQYKNAoEBgACCBIGkQECmwEDGiQg
UmVzZXRzIGEgTWFuYWdlZCBOb3RlYm9vayBSdW50aW1lLgoKDQoFBgACCAESBJEBBhIKDQoF
BgACCAISBJEBEyYKDQoFBgACCAMSBJEBMU0KDwoFBgACCAQSBpIBBJUBBgoTCgkGAAIIBLDK
vCISBpIBBJUBBgoNCgUGAAIIBBIElgEEMgoQCggGAAIIBJsIABIElgEEMgoPCgUGAAIIBBIG
lwEEmgEGChEKBwYAAggEmQgSBpcBBJoBBgpMCgQGAAIJEgaeAQKoAQMaPCBVcGdyYWRlcyBh
IE1hbmFnZWQgTm90ZWJvb2sgUnVudGltZSB0byB0aGUgbGF0ZXN0IHZlcnNpb24uCgoNCgUG
AAIJARIEngEGFAoNCgUGAAIJAhIEngEVKgoNCgUGAAIJAxIEngE1UQoPCgUGAAIJBBIGnwEE
ogEGChMKCQYAAgkEsMq8IhIGnwEEogEGCg0KBQYAAgkEEgSjAQQyChAKCAYAAgkEmwgAEgSj
AQQyCg8KBQYAAgkEEgakAQSnAQYKEQoHBgACCQSZCBIGpAEEpwEGCjUKBAYAAgoSBqsBArUB
AxolIFJlcG9ydCBhbmQgcHJvY2VzcyBhIHJ1bnRpbWUgZXZlbnQuCgoNCgUGAAIKARIEqwEG
GAoNCgUGAAIKAhIEqwEZMgoNCgUGAAIKAxIEqwE9WQoPCgUGAAIKBBIGrAEErwEGChMKCQYA
AgoEsMq8IhIGrAEErwEGCg0KBQYAAgoEEgSwAQQyChAKCAYAAgoEmwgAEgSwAQQyCg8KBQYA
AgoEEgaxAQS0AQYKEQoHBgACCgSZCBIGsQEEtAEGCp4BCgQGAAILEga5AQK/AQMajQEgR2V0
cyBhbiBhY2Nlc3MgdG9rZW4gZm9yIHRoZSBjb25zdW1lciBzZXJ2aWNlIGFjY291bnQgdGhh
dCB0aGUgY3VzdG9tZXIKIGF0dGFjaGVkIHRvIHRoZSBydW50aW1lLiBPbmx5IGFjY2Vzc2li
bGUgZnJvbSB0aGUgdGVuYW50IGluc3RhbmNlLgoKDQoFBgACCwESBLkBBiEKDQoFBgACCwIS
BLkBIkQKDQoFBgACCwMSBLkBT3IKDwoFBgACCwQSBroBBL0BBgoTCgkGAAILBLDKvCISBroB
BL0BBgoNCgUGAAILBBIEvgEEOAoQCggGAAILBJsIABIEvgEEOApVCgQGAAIMEgbCAQLMAQMa
RSBDcmVhdGVzIGEgRGlhZ25vc3RpYyBGaWxlIGFuZCBydW5zIERpYWdub3N0aWMgVG9vbCBn
aXZlbiBhIFJ1bnRpbWUuCgoNCgUGAAIMARIEwgEGFQoNCgUGAAIMAhIEwgEWLAoNCgUGAAIM
AxIEwgE3UwoPCgUGAAIMBBIGwwEExgEGChMKCQYAAgwEsMq8IhIGwwEExgEGCg0KBQYAAgwE
EgTHAQREChAKCAYAAgwEmwgAEgTHAQRECg8KBQYAAgwEEgbIAQTLAQYKEQoHBgACDASZCBIG
yAEEywEGCj4KAgQAEgbQAQDgAQEaMCBSZXF1ZXN0IGZvciBsaXN0aW5nIE1hbmFnZWQgTm90
ZWJvb2sgUnVudGltZXMuCgoLCgMEAAESBNABCBsKWAoEBAACABIG0wEC2AEEGkggUmVxdWly
ZWQuIEZvcm1hdDoKIGBwYXJlbnQ9cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97
bG9jYXRpb259YAoKDQoFBAACAAUSBNMBAggKDQoFBAACAAESBNMBCQ8KDQoFBAACAAMSBNMB
EhMKDwoFBAACAAgSBtMBFNgBAwoQCggEAAIACJwIABIE1AEEKgoRCgcEAAIACJ8IEgbVAQTX
AQUKNQoEBAACARIE2wECFhonIE1heGltdW0gcmV0dXJuIHNpemUgb2YgdGhlIGxpc3QgY2Fs
bC4KCg0KBQQAAgEFEgTbAQIHCg0KBQQAAgEBEgTbAQgRCg0KBQQAAgEDEgTbARQVCmoKBAQA
AgISBN8BAhgaXCBBIHByZXZpb3VzIHJldHVybmVkIHBhZ2UgdG9rZW4gdGhhdCBjYW4gYmUg
dXNlZCB0byBjb250aW51ZSBsaXN0aW5nCiBmcm9tIHRoZSBsYXN0IHJlc3VsdC4KCg0KBQQA
AgIFEgTfAQIICg0KBQQAAgIBEgTfAQkTCg0KBQQAAgIDEgTfARYXCj8KAgQBEgbjAQDvAQEa
MSBSZXNwb25zZSBmb3IgbGlzdGluZyBNYW5hZ2VkIE5vdGVib29rIFJ1bnRpbWVzLgoKCwoD
BAEBEgTjAQgcCiwKBAQBAgASBOUBAiAaHiBBIGxpc3Qgb2YgcmV0dXJuZWQgUnVudGltZXMu
CgoNCgUEAQIABBIE5QECCgoNCgUEAQIABhIE5QELEgoNCgUEAQIAARIE5QETGwoNCgUEAQIA
AxIE5QEeHwpsCgQEAQIBEgTpAQIdGl4gUGFnZSB0b2tlbiB0aGF0IGNhbiBiZSB1c2VkIHRv
IGNvbnRpbnVlIGxpc3RpbmcgZnJvbSB0aGUgbGFzdCByZXN1bHQgaW4gdGhlCiBuZXh0IGxp
c3QgY2FsbC4KCg0KBQQBAgEFEgTpAQIICg0KBQQBAgEBEgTpAQkYCg0KBQQBAgEDEgTpARsc
Cq0BCgQEAQICEgTuAQIiGp4BIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVk
LiBGb3IgZXhhbXBsZSwKIGBbJ3VzLXdlc3QxJywgJ3VzLWNlbnRyYWwxJ11gLgogQSBMaXN0
UnVudGltZXNSZXNwb25zZSB3aWxsIG9ubHkgY29udGFpbiBlaXRoZXIgcnVudGltZXMgb3Ig
dW5yZWFjaGFibGVzLAoKDQoFBAECAgQSBO4BAgoKDQoFBAECAgUSBO4BCxEKDQoFBAECAgES
BO4BEh0KDQoFBAECAgMSBO4BICEKPwoCBAISBvIBAPsBARoxIFJlcXVlc3QgZm9yIGdldHRp
bmcgYSBNYW5hZ2VkIE5vdGVib29rIFJ1bnRpbWUuCgoLCgMEAgESBPIBCBkKZwoEBAICABIG
9QEC+gEEGlcgUmVxdWlyZWQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vcnVudGltZXMve3J1bnRpbWVfaWR9YAoKDQoFBAICAAUSBPUB
AggKDQoFBAICAAESBPUBCQ0KDQoFBAICAAMSBPUBEBEKDwoFBAICAAgSBvUBEvoBAwoQCggE
AgIACJwIABIE9gEEKgoRCgcEAgIACJ8IEgb3AQT5AQUKQAoCBAMSBv4BAJACARoyIFJlcXVl
c3QgZm9yIGNyZWF0aW5nIGEgTWFuYWdlZCBOb3RlYm9vayBSdW50aW1lLgoKCwoDBAMBEgT+
AQgcClgKBAQDAgASBoECAoYCBBpIIFJlcXVpcmVkLiBGb3JtYXQ6CiBgcGFyZW50PXByb2pl
Y3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCg0KBQQDAgAFEgSBAgII
Cg0KBQQDAgABEgSBAgkPCg0KBQQDAgADEgSBAhITCg8KBQQDAgAIEgaBAhSGAgMKEAoIBAMC
AAicCAASBIICBCoKEQoHBAMCAAifCBIGgwIEhQIFCkEKBAQDAgESBIkCAkEaMyBSZXF1aXJl
ZC4gVXNlci1kZWZpbmVkIHVuaXF1ZSBJRCBvZiB0aGlzIFJ1bnRpbWUuCgoNCgUEAwIBBRIE
iQICCAoNCgUEAwIBARIEiQIJEwoNCgUEAwIBAxIEiQIWFwoNCgUEAwIBCBIEiQIYQAoQCggE
AwIBCJwIABIEiQIZPwo0CgQEAwICEgSMAgI/GiYgUmVxdWlyZWQuIFRoZSBSdW50aW1lIHRv
IGJlIGNyZWF0ZWQuCgoNCgUEAwICBhIEjAICCQoNCgUEAwICARIEjAIKEQoNCgUEAwICAxIE
jAIUFQoNCgUEAwICCBIEjAIWPgoQCggEAwICCJwIABIEjAIXPQooCgQEAwIDEgSPAgIYGhog
SWRlbXBvdGVudCByZXF1ZXN0IFVVSUQuCgoNCgUEAwIDBRIEjwICCAoNCgUEAwIDARIEjwIJ
EwoNCgUEAwIDAxIEjwIWFwpACgIEBBIGkwIAnwIBGjIgUmVxdWVzdCBmb3IgZGVsZXRpbmcg
YSBNYW5hZ2VkIE5vdGVib29rIFJ1bnRpbWUuCgoLCgMEBAESBJMCCBwKZwoEBAQCABIGlgIC
mwIEGlcgUmVxdWlyZWQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcnVudGltZXMve3J1bnRpbWVfaWR9YAoKDQoFBAQCAAUSBJYCAggK
DQoFBAQCAAESBJYCCQ0KDQoFBAQCAAMSBJYCEBEKDwoFBAQCAAgSBpYCEpsCAwoQCggEBAIA
CJwIABIElwIEKgoRCgcEBAIACJ8IEgaYAgSaAgUKKAoEBAQCARIEngICGBoaIElkZW1wb3Rl
bnQgcmVxdWVzdCBVVUlELgoKDQoFBAQCAQUSBJ4CAggKDQoFBAQCAQESBJ4CCRMKDQoFBAQC
AQMSBJ4CFhcKQAoCBAUSBqICAKkCARoyIFJlcXVlc3QgZm9yIHN0YXJ0aW5nIGEgTWFuYWdl
ZCBOb3RlYm9vayBSdW50aW1lLgoKCwoDBAUBEgSiAggbCmUKBAQFAgASBKUCAjsaVyBSZXF1
aXJlZC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9ydW50aW1lcy97cnVudGltZV9pZH1gCgoNCgUEBQIABRIEpQICCAoNCgUEBQIAARIE
pQIJDQoNCgUEBQIAAxIEpQIQEQoNCgUEBQIACBIEpQISOgoQCggEBQIACJwIABIEpQITOQoo
CgQEBQIBEgSoAgIYGhogSWRlbXBvdGVudCByZXF1ZXN0IFVVSUQuCgoNCgUEBQIBBRIEqAIC
CAoNCgUEBQIBARIEqAIJEwoNCgUEBQIBAxIEqAIWFwpACgIEBhIGrAIAswIBGjIgUmVxdWVz
dCBmb3Igc3RvcHBpbmcgYSBNYW5hZ2VkIE5vdGVib29rIFJ1bnRpbWUuCgoLCgMEBgESBKwC
CBoKZQoEBAYCABIErwICOxpXIFJlcXVpcmVkLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3J1bnRpbWVzL3tydW50aW1lX2lkfWAKCg0K
BQQGAgAFEgSvAgIICg0KBQQGAgABEgSvAgkNCg0KBQQGAgADEgSvAhARCg0KBQQGAgAIEgSv
AhI6ChAKCAQGAgAInAgAEgSvAhM5CigKBAQGAgESBLICAhgaGiBJZGVtcG90ZW50IHJlcXVl
c3QgVVVJRC4KCg0KBQQGAgEFEgSyAgIICg0KBQQGAgEBEgSyAgkTCg0KBQQGAgEDEgSyAhYX
CkEKAgQHEga2AgDDAgEaMyBSZXF1ZXN0IGZvciBzd2l0Y2hpbmcgYSBNYW5hZ2VkIE5vdGVi
b29rIFJ1bnRpbWUuCgoLCgMEBwESBLYCCBwKZQoEBAcCABIEuQICOxpXIFJlcXVpcmVkLiBG
b3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3J1
bnRpbWVzL3tydW50aW1lX2lkfWAKCg0KBQQHAgAFEgS5AgIICg0KBQQHAgABEgS5AgkNCg0K
BQQHAgADEgS5AhARCg0KBQQHAgAIEgS5AhI6ChAKCAQHAgAInAgAEgS5AhM5Ch0KBAQHAgES
BLwCAhoaDyBtYWNoaW5lIHR5cGUuCgoNCgUEBwIBBRIEvAICCAoNCgUEBwIBARIEvAIJFQoN
CgUEBwIBAxIEvAIYGQojCgQEBwICEgS/AgIyGhUgYWNjZWxlcmF0b3IgY29uZmlnLgoKDQoF
BAcCAgYSBL8CAhoKDQoFBAcCAgESBL8CGy0KDQoFBAcCAgMSBL8CMDEKKAoEBAcCAxIEwgIC
GBoaIElkZW1wb3RlbnQgcmVxdWVzdCBVVUlELgoKDQoFBAcCAwUSBMICAggKDQoFBAcCAwES
BMICCRMKDQoFBAcCAwMSBMICFhcKQQoCBAgSBsYCAM0CARozIFJlcXVlc3QgZm9yIHJlc2V0
dGluZyBhIE1hbmFnZWQgTm90ZWJvb2sgUnVudGltZS4KCgsKAwQIARIExgIIGwplCgQECAIA
EgTJAgI7GlcgUmVxdWlyZWQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vcnVudGltZXMve3J1bnRpbWVfaWR9YAoKDQoFBAgCAAUSBMkC
AggKDQoFBAgCAAESBMkCCQ0KDQoFBAgCAAMSBMkCEBEKDQoFBAgCAAgSBMkCEjoKEAoIBAgC
AAicCAASBMkCEzkKKAoEBAgCARIEzAICGBoaIElkZW1wb3RlbnQgcmVxdWVzdCBVVUlELgoK
DQoFBAgCAQUSBMwCAggKDQoFBAgCAQESBMwCCRMKDQoFBAgCAQMSBMwCFhcKtAEKAgQJEgbS
AgDZAgEapQEgUmVxdWVzdCBmb3IgdXBncmFkaW5nIGEgTWFuYWdlZCBOb3RlYm9vayBSdW50
aW1lIHRvIHRoZSBsYXRlc3QgdmVyc2lvbi4KIG9wdGlvbiAoZ29vZ2xlLmFwaS5tZXNzYWdl
X3Zpc2liaWxpdHkpLnJlc3RyaWN0aW9uID0KICAgICAiVFJVU1RFRF9URVNURVIsU1BFQ0lB
TF9URVNURVIiOwoKCwoDBAkBEgTSAggdCmUKBAQJAgASBNUCAjsaVyBSZXF1aXJlZC4gRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ydW50
aW1lcy97cnVudGltZV9pZH1gCgoNCgUECQIABRIE1QICCAoNCgUECQIAARIE1QIJDQoNCgUE
CQIAAxIE1QIQEQoNCgUECQIACBIE1QISOgoQCggECQIACJwIABIE1QITOQooCgQECQIBEgTY
AgIYGhogSWRlbXBvdGVudCByZXF1ZXN0IFVVSUQuCgoNCgUECQIBBRIE2AICCAoNCgUECQIB
ARIE2AIJEwoNCgUECQIBAxIE2AIWFwo/CgIEChIG3AIA7AIBGjEgUmVxdWVzdCBmb3IgcmVw
b3J0aW5nIGEgTWFuYWdlZCBOb3RlYm9vayBFdmVudC4KCgsKAwQKARIE3AIIIQpnCgQECgIA
EgbfAgLkAgQaVyBSZXF1aXJlZC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9ydW50aW1lcy97cnVudGltZV9pZH1gCgoNCgUECgIABRIE
3wICCAoNCgUECgIAARIE3wIJDQoNCgUECgIAAxIE3wIQEQoPCgUECgIACBIG3wIS5AIDChAK
CAQKAgAInAgAEgTgAgQqChEKBwQKAgAInwgSBuECBOMCBQqYAQoEBAoCARIE6AICPBqJASBS
ZXF1aXJlZC4gVGhlIFZNIGhhcmR3YXJlIHRva2VuIGZvciBhdXRoZW50aWNhdGluZyB0aGUg
Vk0uCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2luc3RhbmNlcy92
ZXJpZnlpbmctaW5zdGFuY2UtaWRlbnRpdHkKCg0KBQQKAgEFEgToAgIICg0KBQQKAgEBEgTo
AgkOCg0KBQQKAgEDEgToAhESCg0KBQQKAgEIEgToAhM7ChAKCAQKAgEInAgAEgToAhQ6CjMK
BAQKAgISBOsCAjsaJSBSZXF1aXJlZC4gVGhlIEV2ZW50IHRvIGJlIHJlcG9ydGVkLgoKDQoF
BAoCAgYSBOsCAgcKDQoFBAoCAgESBOsCCA0KDQoFBAoCAgMSBOsCEBEKDQoFBAoCAggSBOsC
EjoKEAoIBAoCAgicCAASBOsCEzkKRgoCBAsSBu8CAI4DARo4IFJlcXVlc3QgZm9yIHVwZGF0
aW5nIGEgTWFuYWdlZCBOb3RlYm9vayBjb25maWd1cmF0aW9uLgoKCwoDBAsBEgTvAggcCjQK
BAQLAgASBPECAj8aJiBSZXF1aXJlZC4gVGhlIFJ1bnRpbWUgdG8gYmUgdXBkYXRlZC4KCg0K
BQQLAgAGEgTxAgIJCg0KBQQLAgABEgTxAgoRCg0KBQQLAgADEgTxAhQVCg0KBQQLAgAIEgTx
AhY+ChAKCAQLAgAInAgAEgTxAhc9CpMGCgQECwIBEgSKAwJVGoQGIFJlcXVpcmVkLiBTcGVj
aWZpZXMgdGhlIHBhdGgsIHJlbGF0aXZlIHRvIGBSdW50aW1lYCwgb2YKIHRoZSBmaWVsZCB0
byB1cGRhdGUuIEZvciBleGFtcGxlLCB0byBjaGFuZ2UgdGhlIHNvZnR3YXJlIGNvbmZpZ3Vy
YXRpb24KIGtlcm5lbHMsIHRoZSBgdXBkYXRlX21hc2tgIHBhcmFtZXRlciB3b3VsZCBiZQog
c3BlY2lmaWVkIGFzIGBzb2Z0d2FyZV9jb25maWcua2VybmVsc2AsCiBhbmQgdGhlIGBQQVRD
SGAgcmVxdWVzdCBib2R5IHdvdWxkIHNwZWNpZnkgdGhlIG5ldyB2YWx1ZSwgYXMgZm9sbG93
czoKCiAgICAgewogICAgICAgInNvZnR3YXJlX2NvbmZpZyI6ewogICAgICAgICAia2VybmVs
cyI6IFt7CiAgICAgICAgICAgICdyZXBvc2l0b3J5JzoKICAgICAgICAgICAgJ2djci5pby9k
ZWVwbGVhcm5pbmctcGxhdGZvcm0tcmVsZWFzZS9weXRvcmNoLWdwdScsICd0YWcnOgogICAg
ICAgICAgICAnbGF0ZXN0JyB9XSwKICAgICAgICAgfQogICAgIH0KCgogQ3VycmVudGx5LCBv
bmx5IHRoZSBmb2xsb3dpbmcgZmllbGRzIGNhbiBiZSB1cGRhdGVkOgogLSBgc29mdHdhcmVf
Y29uZmlnLmtlcm5lbHNgCiAtIGBzb2Z0d2FyZV9jb25maWcucG9zdF9zdGFydHVwX3Njcmlw
dGAKIC0gYHNvZnR3YXJlX2NvbmZpZy5jdXN0b21fZ3B1X2RyaXZlcl9wYXRoYAogLSBgc29m
dHdhcmVfY29uZmlnLmlkbGVfc2h1dGRvd25gCiAtIGBzb2Z0d2FyZV9jb25maWcuaWRsZV9z
aHV0ZG93bl90aW1lb3V0YAogLSBgc29mdHdhcmVfY29uZmlnLmRpc2FibGVfdGVybWluYWxg
CgoNCgUECwIBBhIEigMCGwoNCgUECwIBARIEigMcJwoNCgUECwIBAxIEigMqKwoNCgUECwIB
CBIEigMsVAoQCggECwIBCJwIABIEigMtUwooCgQECwICEgSNAwIYGhogSWRlbXBvdGVudCBy
ZXF1ZXN0IFVVSUQuCgoNCgUECwICBRIEjQMCCAoNCgUECwICARIEjQMJEwoNCgUECwICAxIE
jQMWFwo3CgIEDBIGkQMAngMBGikgUmVxdWVzdCBmb3IgZ2V0dGluZyBhIG5ldyBhY2Nlc3Mg
dG9rZW4uCgoLCgMEDAESBJEDCCoKZwoEBAwCABIGlAMCmQMEGlcgUmVxdWlyZWQuIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcnVudGlt
ZXMve3J1bnRpbWVfaWR9YAoKDQoFBAwCAAUSBJQDAggKDQoFBAwCAAESBJQDCQ0KDQoFBAwC
AAMSBJQDEBEKDwoFBAwCAAgSBpQDEpkDAwoQCggEDAIACJwIABIElQMEKgoRCgcEDAIACJ8I
EgaWAwSYAwUKmAEKBAQMAgESBJ0DAjwaiQEgUmVxdWlyZWQuIFRoZSBWTSBoYXJkd2FyZSB0
b2tlbiBmb3IgYXV0aGVudGljYXRpbmcgdGhlIFZNLgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2NvbXB1dGUvZG9jcy9pbnN0YW5jZXMvdmVyaWZ5aW5nLWluc3RhbmNlLWlkZW50aXR5
CgoNCgUEDAIBBRIEnQMCCAoNCgUEDAIBARIEnQMJDgoNCgUEDAIBAxIEnQMREgoNCgUEDAIB
CBIEnQMTOwoQCggEDAIBCJwIABIEnQMUOgoxCgIEDRIGoQMApwMBGiMgUmVzcG9uc2Ugd2l0
aCBhIG5ldyBhY2Nlc3MgdG9rZW4uCgoLCgMEDQESBKEDCCsKKwoEBA0CABIEowMCGhodIFRo
ZSBPQXV0aCAyLjAgYWNjZXNzIHRva2VuLgoKDQoFBA0CAAUSBKMDAggKDQoFBA0CAAESBKMD
CRUKDQoFBA0CAAMSBKMDGBkKMwoEBA0CARIEpgMCWBolIE91dHB1dCBvbmx5LiBUb2tlbiBl
eHBpcmF0aW9uIHRpbWUuCgoNCgUEDQIBBhIEpgMCGwoNCgUEDQIBARIEpgMcJwoNCgUEDQIB
AxIEpgMqKwoNCgUEDQIBCBIEpgMsVwoQCggEDQIBCJwIABIEpgMtVgpJCgIEDhIGqgMAtgMB
GjsgUmVxdWVzdCBmb3IgY3JlYXRpbmcgYSBub3RlYm9vayBpbnN0YW5jZSBkaWFnbm9zdGlj
IGZpbGUuCgoLCgMEDgESBKoDCB4KaAoEBA4CABIGrQMCsgMEGlggUmVxdWlyZWQuIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcnVudGlt
ZXMve3J1bnRpbWVzX2lkfWAKCg0KBQQOAgAFEgStAwIICg0KBQQOAgABEgStAwkNCg0KBQQO
AgADEgStAxARCg8KBQQOAgAIEgatAxKyAwMKEAoIBA4CAAicCAASBK4DBCoKEQoHBA4CAAif
CBIGrwMEsQMFClAKBAQOAgESBLUDAlIaQiBSZXF1aXJlZC4gRGVmaW5lcyBmbGFncyB0aGF0
IGFyZSB1c2VkIHRvIHJ1biB0aGUgZGlhZ25vc3RpYyB0b29sCgoNCgUEDgIBBhIEtQMCEgoN
CgUEDgIBARIEtQMTJAoNCgUEDgIBAxIEtQMnKAoNCgUEDgIBCBIEtQMpUQoQCggEDgIBCJwI
ABIEtQMqUGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest ===
    # Fields for ListRuntimesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesResponse ===
    # Fields for ListRuntimesResponse
    # Field: runtimes Type: 11 (.google.cloud.notebooks.v1.Runtime)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::GetRuntimeRequest ===
    # Fields for GetRuntimeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::CreateRuntimeRequest ===
    # Fields for CreateRuntimeRequest
    # Field: parent Type: 9 ()
    # Field: runtime_id Type: 9 ()
    # Field: runtime Type: 11 (.google.cloud.notebooks.v1.Runtime)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::DeleteRuntimeRequest ===
    # Fields for DeleteRuntimeRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::StartRuntimeRequest ===
    # Fields for StartRuntimeRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::StopRuntimeRequest ===
    # Fields for StopRuntimeRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::SwitchRuntimeRequest ===
    # Fields for SwitchRuntimeRequest
    # Field: name Type: 9 ()
    # Field: machine_type Type: 9 ()
    # Field: accelerator_config Type: 11 (.google.cloud.notebooks.v1.RuntimeAcceleratorConfig)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::ResetRuntimeRequest ===
    # Fields for ResetRuntimeRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::UpgradeRuntimeRequest ===
    # Fields for UpgradeRuntimeRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::ReportRuntimeEventRequest ===
    # Fields for ReportRuntimeEventRequest
    # Field: name Type: 9 ()
    # Field: vm_id Type: 9 ()
    # Field: event Type: 11 (.google.cloud.notebooks.v1.Event)

# === Message: Google::Cloud::Notebooks::V1::ManagedService::UpdateRuntimeRequest ===
    # Fields for UpdateRuntimeRequest
    # Field: runtime Type: 11 (.google.cloud.notebooks.v1.Runtime)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalRequest ===
    # Fields for RefreshRuntimeTokenInternalRequest
    # Field: name Type: 9 ()
    # Field: vm_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalResponse ===
    # Fields for RefreshRuntimeTokenInternalResponse
    # Field: access_token Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Notebooks::V1::ManagedService::DiagnoseRuntimeRequest ===
    # Fields for DiagnoseRuntimeRequest
    # Field: name Type: 9 ()
    # Field: diagnostic_config Type: 11 (.google.cloud.notebooks.v1.DiagnosticConfig)

# === Service Client: Google::Cloud::Notebooks::V1::ManagedService::ManagedNotebookServiceClient ===
package Google::Cloud::Notebooks::V1::ManagedService::ManagedNotebookServiceClient;

=pod

=head2 Service Client: Google::Cloud::Notebooks::V1::ManagedService::ManagedNotebookServiceClient

Client stub representing the remote C<ManagedNotebookService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<notebooks.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'notebooks.googleapis.com:443' );

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

sub list_runtimes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'ListRuntimes',
        request        => $req,
        response_class => 'Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesResponse',
    });
}

sub get_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::GetRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'GetRuntime',
        request        => $req,
        response_class => 'Google::Cloud::Notebooks::V1::Runtime::Runtime',
    });
}

sub create_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::CreateRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'CreateRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::UpdateRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'UpdateRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::DeleteRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'DeleteRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub start_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::StartRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'StartRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub stop_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::StopRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'StopRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub switch_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::SwitchRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'SwitchRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reset_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::ResetRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'ResetRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub upgrade_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::UpgradeRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'UpgradeRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub report_runtime_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::ReportRuntimeEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'ReportRuntimeEvent',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub refresh_runtime_token_internal {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'RefreshRuntimeTokenInternal',
        request        => $req,
        response_class => 'Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalResponse',
    });
}

sub diagnose_runtime {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V1::ManagedService::DiagnoseRuntimeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v1.ManagedNotebookService',
        method         => 'DiagnoseRuntime',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::ManagedService - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/managed_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::ManagedService;

    my $msg = Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/managed_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest

Request for listing Managed Notebook Runtimes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format:
`parent=projects/{project_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum return size of the list call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A previous returned page token that can be used to continue listing
from the last result.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesResponse

Response for listing Managed Notebook Runtimes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->runtimes() >> / C<< $msg->runtimes($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Runtime::Runtime>)

A list of returned Runtimes.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token that can be used to continue listing from the last result in the
next list call.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached. For example,
`['us-west1', 'us-central1']`.
A ListRuntimesResponse will only contain either runtimes or unreachables,

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::GetRuntimeRequest

Request for getting a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::CreateRuntimeRequest

Request for creating a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format:
`parent=projects/{project_id}/locations/{location}`

=item * C<< $msg->runtime_id() >> / C<< $msg->runtime_id($value) >>

Type: C<String>

Required. User-defined unique ID of this Runtime.

=item * C<< $msg->runtime() >> / C<< $msg->runtime($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Runtime::Runtime>)

Required. The Runtime to be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::DeleteRuntimeRequest

Request for deleting a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::StartRuntimeRequest

Request for starting a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::StopRuntimeRequest

Request for stopping a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::SwitchRuntimeRequest

Request for switching a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->machine_type() >> / C<< $msg->machine_type($value) >>

Type: C<String>

machine type.

=item * C<< $msg->accelerator_config() >> / C<< $msg->accelerator_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Runtime::RuntimeAcceleratorConfig>)

accelerator config.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::ResetRuntimeRequest

Request for resetting a Managed Notebook Runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::UpgradeRuntimeRequest

Request for upgrading a Managed Notebook Runtime to the latest version.
option (google.api.message_visibility).restriction =
    "TRUSTED_TESTER,SPECIAL_TESTER";

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::ReportRuntimeEventRequest

Request for reporting a Managed Notebook Event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->vm_id() >> / C<< $msg->vm_id($value) >>

Type: C<String>

Required. The VM hardware token for authenticating the VM.
https://cloud.google.com/compute/docs/instances/verifying-instance-identity

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Event::Event>)

Required. The Event to be reported.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::UpdateRuntimeRequest

Request for updating a Managed Notebook configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->runtime() >> / C<< $msg->runtime($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Runtime::Runtime>)

Required. The Runtime to be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Specifies the path, relative to `Runtime`, of
the field to update. For example, to change the software configuration
kernels, the `update_mask` parameter would be
specified as `software_config.kernels`,
and the `PATCH` request body would specify the new value, as follows:

    {
      "software_config":{
        "kernels": [{
           'repository':
           'gcr.io/deeplearning-platform-release/pytorch-gpu', 'tag':
           'latest' }],
        }
    }


Currently, only the following fields can be updated:
- `software_config.kernels`
- `software_config.post_startup_script`
- `software_config.custom_gpu_driver_path`
- `software_config.idle_shutdown`
- `software_config.idle_shutdown_timeout`
- `software_config.disable_terminal`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalRequest

Request for getting a new access token.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtime_id}`

=item * C<< $msg->vm_id() >> / C<< $msg->vm_id($value) >>

Type: C<String>

Required. The VM hardware token for authenticating the VM.
https://cloud.google.com/compute/docs/instances/verifying-instance-identity

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalResponse

Response with a new access token.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_token() >> / C<< $msg->access_token($value) >>

Type: C<String>

The OAuth 2.0 access token.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Token expiration time.

=back

=head2 Google::Cloud::Notebooks::V1::ManagedService::DiagnoseRuntimeRequest

Request for creating a notebook instance diagnostic file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/runtimes/{runtimes_id}`

=item * C<< $msg->diagnostic_config() >> / C<< $msg->diagnostic_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig>)

Required. Defines flags that are used to run the diagnostic tool

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::ManagedService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
