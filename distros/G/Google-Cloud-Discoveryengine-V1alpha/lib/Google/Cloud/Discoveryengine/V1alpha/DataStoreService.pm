package Google::Cloud::Discoveryengine::V1alpha::DataStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::DataStore };
    eval { require Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZGF0YV9zdG9yZV9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZGF0YV9zdG9yZS5wcm90
bxpFZ29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL2RvY3VtZW50X3Byb2Nl
c3NpbmdfY29uZmlnLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLhAgoWQ3JlYXRl
RGF0YVN0b3JlUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKwopZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29tL0NvbGxlY3Rpb25SBnBhcmVudBJTCgpkYXRhX3N0b3JlGAIg
ASgLMi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZUID
4EECUglkYXRhU3RvcmUSJwoNZGF0YV9zdG9yZV9pZBgDIAEoCUID4EECUgtkYXRhU3RvcmVJ
ZBI9ChtjcmVhdGVfYWR2YW5jZWRfc2l0ZV9zZWFyY2gYBCABKAhSGGNyZWF0ZUFkdmFuY2Vk
U2l0ZVNlYXJjaBI/Chxza2lwX2RlZmF1bHRfc2NoZW1hX2NyZWF0aW9uGAcgASgIUhlza2lw
RGVmYXVsdFNjaGVtYUNyZWF0aW9uIlsKE0dldERhdGFTdG9yZVJlcXVlc3QSRAoEbmFtZRgB
IAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRGF0YVN0b3Jl
UgRuYW1lIpMBChdDcmVhdGVEYXRhU3RvcmVNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3Rp
bWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lIrYBChVM
aXN0RGF0YVN0b3Jlc1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWRpc2NvdmVy
eWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSGwoJcGFnZV9zaXpl
GAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoGZmls
dGVyGAQgASgJUgZmaWx0ZXIikgEKFkxpc3REYXRhU3RvcmVzUmVzcG9uc2USUAoLZGF0YV9z
dG9yZXMYASADKAsyLy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0
YVN0b3JlUgpkYXRhU3RvcmVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiJeChZEZWxldGVEYXRhU3RvcmVSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgoo
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIEbmFtZSKqAQoWVXBk
YXRlRGF0YVN0b3JlUmVxdWVzdBJTCgpkYXRhX3N0b3JlGAEgASgLMi8uZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZUID4EECUglkYXRhU3RvcmUSOwoL
dXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVN
YXNrIpMBChdEZWxldGVEYXRhU3RvcmVNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lInkKIkdldERv
Y3VtZW50UHJvY2Vzc2luZ0NvbmZpZ1JlcXVlc3QSUwoEbmFtZRgBIAEoCUI/4EEC+kE5Cjdk
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnRQcm9jZXNzaW5nQ29uZmln
UgRuYW1lIugBCiVVcGRhdGVEb2N1bWVudFByb2Nlc3NpbmdDb25maWdSZXF1ZXN0EoEBChpk
b2N1bWVudF9wcm9jZXNzaW5nX2NvbmZpZxgBIAEoCzI+Lmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5Eb2N1bWVudFByb2Nlc3NpbmdDb25maWdCA+BBAlIYZG9jdW1l
bnRQcm9jZXNzaW5nQ29uZmlnEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzazKtFAoQRGF0YVN0b3JlU2VydmljZRKdAwoPQ3Jl
YXRlRGF0YVN0b3JlEjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNy
ZWF0ZURhdGFTdG9yZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqwC
gtPkkwKSASIzL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kYXRh
U3RvcmVzOgpkYXRhX3N0b3JlWk8iQS92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb2xsZWN0aW9ucy8qfS9kYXRhU3RvcmVzOgpkYXRhX3N0b3Jl2kEfcGFyZW50
LGRhdGFfc3RvcmUsZGF0YV9zdG9yZV9pZMpBbgouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLkRhdGFTdG9yZRI8Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkNyZWF0ZURhdGFTdG9yZU1ldGFkYXRhEoQCCgxHZXREYXRhU3RvcmUSOS5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuR2V0RGF0YVN0b3JlUmVxdWVzdBov
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmUihwGC0+ST
AnoSMy92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8q
fVpDEkEvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25z
LyovZGF0YVN0b3Jlcy8qfdpBBG5hbWUSlwIKDkxpc3REYXRhU3RvcmVzEjsuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3REYXRhU3RvcmVzUmVxdWVzdBo8Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0RGF0YVN0b3Jlc1Jlc3Bv
bnNlIokBgtPkkwJ6EjMvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
L2RhdGFTdG9yZXNaQxJBL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NvbGxlY3Rpb25zLyp9L2RhdGFTdG9yZXPaQQZwYXJlbnQS0AIKD0RlbGV0ZURhdGFTdG9y
ZRI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EZWxldGVEYXRhU3Rv
cmVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLfAYLT5JMCeiozL3Yx
YWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9WkMqQS92
MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyp92kEEbmFtZcpBVQoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ejxnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGVsZXRlRGF0YVN0b3JlTWV0YWRhdGESywIK
D1VwZGF0ZURhdGFTdG9yZRI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5VcGRhdGVEYXRhU3RvcmVSZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLkRhdGFTdG9yZSLIAYLT5JMCqAEyPi92MWFscGhhL3tkYXRhX3N0b3JlLm5h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9OgpkYXRhX3N0b3JlWloy
TC92MWFscGhhL3tkYXRhX3N0b3JlLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xs
ZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn06CmRhdGFfc3RvcmXaQRZkYXRhX3N0b3JlLHVwZGF0
ZV9tYXNrEuQCChtHZXREb2N1bWVudFByb2Nlc3NpbmdDb25maWcSSC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuR2V0RG9jdW1lbnRQcm9jZXNzaW5nQ29uZmlnUmVx
dWVzdBo+Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Eb2N1bWVudFBy
b2Nlc3NpbmdDb25maWciugGC0+STAqwBEkwvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9kb2N1bWVudFByb2Nlc3NpbmdDb25maWd9WlwSWi92
MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyovZG9jdW1lbnRQcm9jZXNzaW5nQ29uZmlnfdpBBG5hbWUS+wMKHlVwZGF0ZURv
Y3VtZW50UHJvY2Vzc2luZ0NvbmZpZxJLLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5VcGRhdGVEb2N1bWVudFByb2Nlc3NpbmdDb25maWdSZXF1ZXN0Gj4uZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50UHJvY2Vzc2luZ0NvbmZp
ZyLLAoLT5JMCmwIyZy92MWFscGhhL3tkb2N1bWVudF9wcm9jZXNzaW5nX2NvbmZpZy5uYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL2RvY3VtZW50UHJvY2Vzc2lu
Z0NvbmZpZ306GmRvY3VtZW50X3Byb2Nlc3NpbmdfY29uZmlnWpMBMnUvdjFhbHBoYS97ZG9j
dW1lbnRfcHJvY2Vzc2luZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nv
bGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL2RvY3VtZW50UHJvY2Vzc2luZ0NvbmZpZ306GmRv
Y3VtZW50X3Byb2Nlc3NpbmdfY29uZmln2kEmZG9jdW1lbnRfcHJvY2Vzc2luZ19jb25maWcs
dXBkYXRlX21hc2saUspBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CoQIKKGNvbS5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCFURhdGFTdG9yZVNlcnZpY2VQcm90
b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rp
c2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIk
R29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERp
c2NvdmVyeUVuZ2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5l
OjpWMWFscGhhSuRiCgcSBQ4AiwMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYAPwoJCgIDBRIDFwBPCgkKAgMGEgMYAC0KCQoCAwcSAxkAJQoJCgIDCBID
GgAqCgkKAgMJEgMbACkKCAoBCBIDHQBBCgkKAgglEgMdAEEKCAoBCBIDHgBpCgkKAggLEgMe
AGkKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAA2CgkKAggIEgMgADYKCAoBCBIDIQBB
CgkKAggBEgMhAEEKCAoBCBIDIgAtCgkKAggkEgMiAC0KCAoBCBIDIwBBCgkKAggpEgMjAEEK
CAoBCBIDJABACgkKAggtEgMkAEAKbwoCBgASBSgAmwEBGmIgU2VydmljZSBmb3IgbWFuYWdp
bmcKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5E
YXRhU3RvcmVdIGNvbmZpZ3VyYXRpb24uCgoKCgMGAAESAygIGAoKCgMGAAMSAykCRgoMCgUG
AAOZCBIDKQJGCgsKAwYAAxIEKgIrNwoNCgUGAAOaCBIEKgIrNwrMAgoEBgACABIENAJDAxq9
AiBDcmVhdGVzIGEgW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkRhdGFTdG9yZV0uCgogRGF0YVN0b3JlIGlzIGZvciBzdG9yaW5nCiBbRG9jdW1l
bnRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRG9jdW1lbnRdLiBU
byBzZXJ2ZSB0aGVzZQogZG9jdW1lbnRzIGZvciBTZWFyY2gsIG9yIFJlY29tbWVuZGF0aW9u
IHVzZSBjYXNlLCBhbgogW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkVuZ2luZV0gbmVlZHMgdG8gYmUgY3JlYXRlZAogc2VwYXJhdGVseS4KCgwKBQYA
AgABEgM0BhUKDAoFBgACAAISAzQWLAoMCgUGAAIAAxIDNQ8rCg0KBQYAAgAEEgQ2BD0GChEK
CQYAAgAEsMq8IhIENgQ9BgoMCgUGAAIABBIDPgRNCg8KCAYAAgAEmwgAEgM+BE0KDQoFBgAC
AAQSBD8EQgYKDwoHBgACAASZCBIEPwRCBgpTCgQGAAIBEgRGAk4DGkUgR2V0cyBhIFtEYXRh
U3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVd
LgoKDAoFBgACAQESA0YGEgoMCgUGAAIBAhIDRhMmCgwKBQYAAgEDEgNGMToKDQoFBgACAQQS
BEcETAYKEQoJBgACAQSwyrwiEgRHBEwGCgwKBQYAAgEEEgNNBDIKDwoIBgACAQSbCAASA00E
Mgp4CgQGAAICEgRSAloDGmogTGlzdHMgYWxsIHRoZSBbRGF0YVN0b3JlXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlXXMKIGFzc29jaWF0ZWQgd2l0
aCB0aGUgcHJvamVjdC4KCgwKBQYAAgIBEgNSBhQKDAoFBgACAgISA1IVKgoMCgUGAAICAxID
UjVLCg0KBQYAAgIEEgRTBFgGChEKCQYAAgIEsMq8IhIEUwRYBgoMCgUGAAICBBIDWQQ0Cg8K
CAYAAgIEmwgAEgNZBDQKVgoEBgACAxIEXQJqAxpIIERlbGV0ZXMgYSBbRGF0YVN0b3JlXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlXS4KCgwKBQYA
AgMBEgNdBhUKDAoFBgACAwISA10WLAoMCgUGAAIDAxIDXg8rCg0KBQYAAgMEEgRfBGQGChEK
CQYAAgMEsMq8IhIEXwRkBgoMCgUGAAIDBBIDZQQyCg8KCAYAAgMEmwgAEgNlBDIKDQoFBgAC
AwQSBGYEaQYKDwoHBgACAwSZCBIEZgRpBgpVCgQGAAIEEgRtAncDGkcgVXBkYXRlcyBhIFtE
YXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3Rv
cmVdCgoMCgUGAAIEARIDbQYVCgwKBQYAAgQCEgNtFiwKDAoFBgACBAMSA203QAoNCgUGAAIE
BBIEbgR1BgoRCgkGAAIEBLDKvCISBG4EdQYKDAoFBgACBAQSA3YERAoPCggGAAIEBJsIABID
dgRECnMKBAYAAgUSBXsChAEDGmQgR2V0cyBhCiBbRG9jdW1lbnRQcm9jZXNzaW5nQ29uZmln
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRG9jdW1lbnRQcm9jZXNz
aW5nQ29uZmlnXS4KCgwKBQYAAgUBEgN7BiEKDAoFBgACBQISA3siRAoMCgUGAAIFAxIDfA8n
Cg4KBQYAAgUEEgV9BIIBBgoSCgkGAAIFBLDKvCISBX0EggEGCg0KBQYAAgUEEgSDAQQyChAK
CAYAAgUEmwgAEgSDAQQyCo4ECgQGAAIGEgaOAQKaAQMa/QMgVXBkYXRlcyB0aGUKIFtEb2N1
bWVudFByb2Nlc3NpbmdDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5Eb2N1bWVudFByb2Nlc3NpbmdDb25maWddLgogW0RvY3VtZW50UHJvY2Vzc2luZ0Nv
bmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50UHJv
Y2Vzc2luZ0NvbmZpZ10KIGlzIGEgc2luZ2xlb24gcmVzb3VyY2Ugb2YKIFtEYXRhU3RvcmVd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVdLiBJdCdz
IGVtcHR5CiB3aGVuIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5EYXRhU3RvcmVdIGlzCiBjcmVhdGVkLiBUaGUgZmlyc3QgY2FsbCB0byB0aGlz
IG1ldGhvZCB3aWxsIHNldCB1cAogW0RvY3VtZW50UHJvY2Vzc2luZ0NvbmZpZ11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50UHJvY2Vzc2luZ0NvbmZp
Z10uCgoNCgUGAAIGARIEjgEGJAoNCgUGAAIGAhIEjgElSgoNCgUGAAIGAxIEjwEPJwoPCgUG
AAIGBBIGkAEElwEGChMKCQYAAgYEsMq8IhIGkAEElwEGCg8KBQYAAgYEEgaYAQSZATEKEgoI
BgACBgSbCAASBpgBBJkBMQqQAQoCBAASBqABAMkBARqBASBSZXF1ZXN0IGZvcgogW0RhdGFT
dG9yZVNlcnZpY2UuQ3JlYXRlRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuRGF0YVN0b3JlU2VydmljZS5DcmVhdGVEYXRhU3RvcmVdCiBtZXRob2Qu
CgoLCgMEAAESBKABCB4KggEKBAQAAgASBqMBAqgBBBpyIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259YC4KCg0KBQQAAgAFEgSjAQII
Cg0KBQQAAgABEgSjAQkPCg0KBQQAAgADEgSjARITCg8KBQQAAgAIEgajARSoAQMKEAoIBAAC
AAicCAASBKQBBCoKEQoHBAACAAifCBIGpQEEpwEFCmUKBAQAAgESBKwBAkQaVyBSZXF1aXJl
ZC4gVGhlIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5EYXRhU3RvcmVdCiB0byBjcmVhdGUuCgoNCgUEAAIBBhIErAECCwoNCgUEAAIBARIErAEM
FgoNCgUEAAIBAxIErAEZGgoNCgUEAAIBCBIErAEbQwoQCggEAAIBCJwIABIErAEcQgqbAwoE
BAACAhIEtwECRBqMAyBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlCiBbRGF0YVN0
b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlXSwg
d2hpY2ggd2lsbAogYmVjb21lIHRoZSBmaW5hbCBjb21wb25lbnQgb2YgdGhlCiBbRGF0YVN0
b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlXSdz
IHJlc291cmNlCiBuYW1lLgoKIFRoaXMgZmllbGQgbXVzdCBjb25mb3JtIHRvIFtSRkMtMTAz
NF0oaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL3JmYzEwMzQpCiBzdGFuZGFyZCB3aXRo
IGEgbGVuZ3RoIGxpbWl0IG9mIDYzIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4KIElOVkFM
SURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAICBRIEtwECCAoNCgUEAAIC
ARIEtwEJFgoNCgUEAAICAxIEtwEZGgoNCgUEAAICCBIEtwEbQwoQCggEAAICCJwIABIEtwEc
Qgr/AQoEBAACAxIEvgECJxrwASBBIGJvb2xlYW4gZmxhZyBpbmRpY2F0aW5nIHdoZXRoZXIg
dXNlciB3YW50IHRvIGRpcmVjdGx5IGNyZWF0ZSBhbiBhZHZhbmNlZAogZGF0YSBzdG9yZSBm
b3Igc2l0ZSBzZWFyY2guCiBJZiB0aGUgZGF0YSBzdG9yZSBpcyBub3QgY29uZmlndXJlZCBh
cyBzaXRlCiBzZWFyY2ggKEdFTkVSSUMgdmVydGljYWwgYW5kIFBVQkxJQ19XRUJTSVRFIGNv
bnRlbnRfY29uZmlnKSwgdGhpcyBmbGFnIHdpbGwKIGJlIGlnbm9yZWQuCgoNCgUEAAIDBRIE
vgECBgoNCgUEAAIDARIEvgEHIgoNCgUEAAIDAxIEvgElJgqNAwoEBAACBBIEyAECKBr+AiBB
IGJvb2xlYW4gZmxhZyBpbmRpY2F0aW5nIHdoZXRoZXIgdG8gc2tpcCB0aGUgZGVmYXVsdCBz
Y2hlbWEgY3JlYXRpb24gZm9yCiB0aGUgZGF0YSBzdG9yZS4gT25seSBlbmFibGUgdGhpcyBm
bGFnIGlmIHlvdSBhcmUgY2VydGFpbiB0aGF0IHRoZSBkZWZhdWx0CiBzY2hlbWEgaXMgaW5j
b21wYXRpYmxlIHdpdGggeW91ciB1c2UgY2FzZS4KCiBJZiBzZXQgdG8gdHJ1ZSwgeW91IG11
c3QgbWFudWFsbHkgY3JlYXRlIGEgc2NoZW1hIGZvciB0aGUgZGF0YSBzdG9yZSBiZWZvcmUK
IGFueSBkb2N1bWVudHMgY2FuIGJlIGluZ2VzdGVkLgoKIFRoaXMgZmxhZyBjYW5ub3QgYmUg
c3BlY2lmaWVkIGlmIGBkYXRhX3N0b3JlLnN0YXJ0aW5nX3NjaGVtYWAgaXMgc3BlY2lmaWVk
LgoKDQoFBAACBAUSBMgBAgYKDQoFBAACBAESBMgBByMKDQoFBAACBAMSBMgBJicKkgEKAgQB
EgbOAQDgAQEagwEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFTdG9yZVNlcnZpY2UuR2V0
RGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0
b3JlU2VydmljZS5HZXREYXRhU3RvcmVdCiBtZXRob2QuCgoLCgMEAQESBM4BCBsKoAQKBAQB
AgASBtoBAt8BBBqPBCBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mCiBbRGF0YVN0
b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlXSwg
c3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xs
ZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZV9pZH1gLgoK
IElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGFjY2VzcyB0aGUK
IFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRh
U3RvcmVdLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgUEVS
TUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIHJlcXVlc3RlZAog
W0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFT
dG9yZV0gZG9lcyBub3QgZXhpc3QsCiBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4K
Cg0KBQQBAgAFEgTaAQIICg0KBQQBAgABEgTaAQkNCg0KBQQBAgADEgTaARARCg8KBQQBAgAI
EgbaARLfAQMKEAoIBAECAAicCAASBNsBBCoKEQoHBAECAAifCBIG3AEE3gEFCvoBCgIEAhIG
5gEA7QEBGusBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZQogW0Rh
dGFTdG9yZVNlcnZpY2UuQ3JlYXRlRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlU2VydmljZS5DcmVhdGVEYXRhU3RvcmVdCiBvcGVy
YXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMEAgESBOYBCB8KJgoEBAICABIE6AEC
LBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQCAgAGEgToAQIbCg0KBQQCAgABEgTo
ARwnCg0KBQQCAgADEgToASorCmQKBAQCAgESBOwBAiwaViBPcGVyYXRpb24gbGFzdCB1cGRh
dGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBm
aW5pc2ggdGltZS4KCg0KBQQCAgEGEgTsAQIbCg0KBQQCAgEBEgTsARwnCg0KBQQCAgEDEgTs
ASorCpYBCgIEAxIG8gEAmAIBGocBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEYXRhU3RvcmVT
ZXJ2aWNlLkxpc3REYXRhU3RvcmVzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuRGF0YVN0b3JlU2VydmljZS5MaXN0RGF0YVN0b3Jlc10KIG1ldGhvZC4KCgsKAwQD
ARIE8gEIHQrvAgoEBAMCABIG+gEC/wEEGt4CIFJlcXVpcmVkLiBUaGUgcGFyZW50IGJyYW5j
aCByZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfWAuCgogSWYgdGhlIGNh
bGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gbGlzdAogW0RhdGFTdG9yZV1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZV1zIHVuZGVyIHRo
aXMKIGxvY2F0aW9uLCByZWdhcmRsZXNzIG9mIHdoZXRoZXIgb3Igbm90IHRoaXMgZGF0YSBz
dG9yZSBleGlzdHMsIGEKIFBFUk1JU1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoK
DQoFBAMCAAUSBPoBAggKDQoFBAMCAAESBPoBCQ8KDQoFBAMCAAMSBPoBEhMKDwoFBAMCAAgS
BvoBFP8BAwoQCggEAwIACJwIABIE+wEEKgoRCgcEAwIACJ8IEgb8AQT+AQUKkwIKBAQDAgES
BIcCAhYahAIgTWF4aW11bSBudW1iZXIgb2YKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVdcyB0byByZXR1cm4uIElmCiB1bnNw
ZWNpZmllZCwgZGVmYXVsdHMgdG8gMTAuIFRoZSBtYXhpbXVtIGFsbG93ZWQgdmFsdWUgaXMg
NTAuIFZhbHVlcyBhYm92ZQogNTAgd2lsbCBiZSBjb2VyY2VkIHRvIDUwLgoKIElmIHRoaXMg
ZmllbGQgaXMgbmVnYXRpdmUsIGFuIElOVkFMSURfQVJHVU1FTlQgaXMgcmV0dXJuZWQuCgoN
CgUEAwIBBRIEhwICBwoNCgUEAwIBARIEhwIIEQoNCgUEAwIBAxIEhwIUFQrQBAoEBAMCAhIE
kwICGBrBBCBBIHBhZ2UgdG9rZW4KIFtMaXN0RGF0YVN0b3Jlc1Jlc3BvbnNlLm5leHRfcGFn
ZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3REYXRh
U3RvcmVzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXSwKIHJlY2VpdmVkIGZyb20gYSBwcmV2
aW91cwogW0RhdGFTdG9yZVNlcnZpY2UuTGlzdERhdGFTdG9yZXNdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVTZXJ2aWNlLkxpc3REYXRhU3RvcmVz
XQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2Uu
CgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwog
W0RhdGFTdG9yZVNlcnZpY2UuTGlzdERhdGFTdG9yZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVTZXJ2aWNlLkxpc3REYXRhU3RvcmVzXQogbXVz
dCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLiBPdGhlcndp
c2UsIGFuCiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAMCAgUS
BJMCAggKDQoFBAMCAgESBJMCCRMKDQoFBAMCAgMSBJMCFhcKZwoEBAMCAxIElwICFBpZIEZp
bHRlciBieSBzb2x1dGlvbiB0eXBlIC4KIEZvciBleGFtcGxlOiBgZmlsdGVyID0gJ3NvbHV0
aW9uX3R5cGU6U09MVVRJT05fVFlQRV9TRUFSQ0gnYAoKDQoFBAMCAwUSBJcCAggKDQoFBAMC
AwESBJcCCQ8KDQoFBAMCAwMSBJcCEhMKlwEKAgQEEgadAgCnAgEaiAEgUmVzcG9uc2UgbWVz
c2FnZSBmb3IKIFtEYXRhU3RvcmVTZXJ2aWNlLkxpc3REYXRhU3RvcmVzXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlU2VydmljZS5MaXN0RGF0YVN0
b3Jlc10KIG1ldGhvZC4KCgsKAwQEARIEnQIIHgphCgQEBAIAEgSgAgIlGlMgQWxsIHRoZSBj
dXN0b21lcidzCiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuRGF0YVN0b3JlXXMuCgoNCgUEBAIABBIEoAICCgoNCgUEBAIABhIEoAILFAoNCgUE
BAIAARIEoAIVIAoNCgUEBAIAAxIEoAIjJArtAQoEBAQCARIEpgICHRreASBBIHRva2VuIHRo
YXQgY2FuIGJlIHNlbnQgYXMKIFtMaXN0RGF0YVN0b3Jlc1JlcXVlc3QucGFnZV90b2tlbl1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3REYXRhU3RvcmVzUmVx
dWVzdC5wYWdlX3Rva2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4gSWYgdGhpcyBm
aWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUE
BAIBBRIEpgICCAoNCgUEBAIBARIEpgIJGAoNCgUEBAIBAxIEpgIbHAqYAQoCBAUSBqwCAL0C
ARqJASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YVN0b3JlU2VydmljZS5EZWxldGVEYXRh
U3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVT
ZXJ2aWNlLkRlbGV0ZURhdGFTdG9yZV0KIG1ldGhvZC4KCgsKAwQFARIErAIIHgqfBAoEBAUC
ABIGtwICvAIEGo4EIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YKIFtEYXRhU3Rv
cmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVdLCBz
dWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxl
Y3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlX2lkfWAuCgog
SWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gZGVsZXRlIHRoZQog
W0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFT
dG9yZV0sIHJlZ2FyZGxlc3Mgb2YKIHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJN
SVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0RhdGFTdG9yZV1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZV0gdG8KIGRl
bGV0ZSBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoN
CgUEBQIABRIEtwICCAoNCgUEBQIAARIEtwIJDQoNCgUEBQIAAxIEtwIQEQoPCgUEBQIACBIG
twISvAIDChAKCAQFAgAInAgAEgS4AgQqChEKBwQFAgAInwgSBrkCBLsCBQqYAQoCBAYSBsIC
ANQCARqJASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YVN0b3JlU2VydmljZS5VcGRhdGVE
YXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3Rv
cmVTZXJ2aWNlLlVwZGF0ZURhdGFTdG9yZV0KIG1ldGhvZC4KCgsKAwQGARIEwgIIHgqqAwoE
BAYCABIEzAICRBqbAyBSZXF1aXJlZC4gVGhlIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVdCiB0byB1cGRhdGUuCgogSWYgdGhl
IGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gdXBkYXRlIHRoZQogW0RhdGFT
dG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZV0s
IHJlZ2FyZGxlc3Mgb2YKIHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9O
X0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0RhdGFTdG9yZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZV0gdG8KIHVwZGF0ZSBk
b2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEBgIA
BhIEzAICCwoNCgUEBgIAARIEzAIMFgoNCgUEBgIAAxIEzAIZGgoNCgUEBgIACBIEzAIbQwoQ
CggEBgIACJwIABIEzAIcQgrZAQoEBAYCARIE0wICLBrKASBJbmRpY2F0ZXMgd2hpY2ggZmll
bGRzIGluIHRoZSBwcm92aWRlZAogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZV0gdG8gdXBkYXRlLgoKIElmIGFuIHVuc3VwcG9y
dGVkIG9yIHVua25vd24gZmllbGQgaXMgcHJvdmlkZWQsIGFuIElOVkFMSURfQVJHVU1FTlQg
ZXJyb3IKIGlzIHJldHVybmVkLgoKDQoFBAYCAQYSBNMCAhsKDQoFBAYCAQESBNMCHCcKDQoF
BAYCAQMSBNMCKisK+gEKAgQHEgbaAgDhAgEa6wEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUg
cHJvZ3Jlc3Mgb2YgdGhlCiBbRGF0YVN0b3JlU2VydmljZS5EZWxldGVEYXRhU3RvcmVdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVTZXJ2aWNlLkRl
bGV0ZURhdGFTdG9yZV0KIG9wZXJhdGlvbi4gVGhpcyB3aWxsIGJlIHJldHVybmVkIGJ5IHRo
ZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVsZC4KCgsKAwQH
ARIE2gIIHwomCgQEBwIAEgTcAgIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAcC
AAYSBNwCAhsKDQoFBAcCAAESBNwCHCcKDQoFBAcCAAMSBNwCKisKZAoEBAcCARIE4AICLBpW
IE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUs
IHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAcCAQYSBOACAhsKDQoFBAcC
AQESBOACHCcKDQoFBAcCAQMSBOACKisKqAEKAgQIEgbmAgDvAgEamQEgUmVxdWVzdCBmb3IK
IFtEYXRhU3RvcmVTZXJ2aWNlLkdldERvY3VtZW50UHJvY2Vzc2luZ0NvbmZpZ11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9yZVNlcnZpY2UuR2V0RG9j
dW1lbnRQcm9jZXNzaW5nQ29uZmlnXQogbWV0aG9kLgoKCwoDBAgBEgTmAggqCtYBCgQECAIA
EgbpAgLuAgQaxQEgUmVxdWlyZWQuIEZ1bGwgRG9jdW1lbnRQcm9jZXNzaW5nQ29uZmlnIHJl
c291cmNlIG5hbWUuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0
aW9ucy97bG9jYXRpb25faWR9L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9kYXRhU3Rv
cmVzL3tkYXRhX3N0b3JlX2lkfS9kb2N1bWVudFByb2Nlc3NpbmdDb25maWdgCgoNCgUECAIA
BRIE6QICCAoNCgUECAIAARIE6QIJDQoNCgUECAIAAxIE6QIQEQoPCgUECAIACBIG6QIS7gID
ChAKCAQIAgAInAgAEgTqAgQqChEKBwQIAgAInwgSBusCBO0CBQquAQoCBAkSBvQCAIsDARqf
ASBSZXF1ZXN0IGZvcgogW0RhdGFTdG9yZVNlcnZpY2UuVXBkYXRlRG9jdW1lbnRQcm9jZXNz
aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0
b3JlU2VydmljZS5VcGRhdGVEb2N1bWVudFByb2Nlc3NpbmdDb25maWddCiBtZXRob2QuCgoL
CgMECQESBPQCCC0K5QMKBAQJAgASBoADAoEDLxrUAyBSZXF1aXJlZC4gVGhlCiBbRG9jdW1l
bnRQcm9jZXNzaW5nQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRG9jdW1lbnRQcm9jZXNzaW5nQ29uZmlnXQogdG8gdXBkYXRlLgoKIElmIHRoZSBjYWxs
ZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZSB0aGUKIFtEb2N1bWVudFBy
b2Nlc3NpbmdDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5E
b2N1bWVudFByb2Nlc3NpbmdDb25maWddLAogdGhlbiBhIFBFUk1JU1NJT05fREVOSUVEIGVy
cm9yIGlzIHJldHVybmVkLgoKIElmIHRoZQogW0RvY3VtZW50UHJvY2Vzc2luZ0NvbmZpZ11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50UHJvY2Vzc2lu
Z0NvbmZpZ10KIHRvIHVwZGF0ZSBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3Ig
aXMgcmV0dXJuZWQuCgoNCgUECQIABhIEgAMCGgoNCgUECQIAARIEgAMbNQoNCgUECQIAAxIE
gAM4OQoNCgUECQIACBIEgQMGLgoQCggECQIACJwIABIEgQMHLQrvAgoEBAkCARIEigMCLBrg
AiBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0RvY3VtZW50UHJv
Y2Vzc2luZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRv
Y3VtZW50UHJvY2Vzc2luZ0NvbmZpZ10KIHRvIHVwZGF0ZS4gVGhlIGZvbGxvd2luZyBhcmUg
dGhlIG9ubHkgc3VwcG9ydGVkIGZpZWxkczoKCiAqIFtEb2N1bWVudFByb2Nlc3NpbmdDb25m
aWcub2NyX2NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRv
Y3VtZW50UHJvY2Vzc2luZ0NvbmZpZy5vY3JfY29uZmlnXQoKIElmIG5vdCBzZXQsIGFsbCBz
dXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoFBAkCAQYSBIoDAhsKDQoFBAkCAQES
BIoDHCcKDQoFBAkCAQMSBIoDKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest ===
    # Fields for CreateDataStoreRequest
    # Field: parent Type: 9 ()
    # Field: data_store Type: 11 (.google.cloud.discoveryengine.v1alpha.DataStore)
    # Field: data_store_id Type: 9 ()
    # Field: create_advanced_site_search Type: 8 ()
    # Field: skip_default_schema_creation Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::GetDataStoreRequest ===
    # Fields for GetDataStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreMetadata ===
    # Fields for CreateDataStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::ListDataStoresRequest ===
    # Fields for ListDataStoresRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::ListDataStoresResponse ===
    # Fields for ListDataStoresResponse
    # Field: data_stores Type: 11 (.google.cloud.discoveryengine.v1alpha.DataStore)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DeleteDataStoreRequest ===
    # Fields for DeleteDataStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDataStoreRequest ===
    # Fields for UpdateDataStoreRequest
    # Field: data_store Type: 11 (.google.cloud.discoveryengine.v1alpha.DataStore)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DeleteDataStoreMetadata ===
    # Fields for DeleteDataStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::GetDocumentProcessingConfigRequest ===
    # Fields for GetDocumentProcessingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDocumentProcessingConfigRequest ===
    # Fields for UpdateDocumentProcessingConfigRequest
    # Field: document_processing_config Type: 11 (.google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DataStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DataStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DataStoreServiceClient

Client stub representing the remote C<DataStoreService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub create_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'CreateDataStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::GetDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'GetDataStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore',
    });
}

sub list_data_stores {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::ListDataStoresRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'ListDataStores',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::DataStoreService::ListDataStoresResponse',
    });
}

sub delete_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DeleteDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'DeleteDataStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'UpdateDataStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore',
    });
}

sub get_document_processing_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::GetDocumentProcessingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'GetDocumentProcessingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig',
    });
}

sub update_document_processing_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDocumentProcessingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'UpdateDocumentProcessingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::DataStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/data_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::DataStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest->new({
        parent => $parent,
        data_store => $data_store,
        data_store_id => $data_store_id,
        create_advanced_site_search => $create_advanced_site_search,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/data_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest

Request for
[DataStoreService.CreateDataStore][google.cloud.discoveryengine.v1alpha.DataStoreService.CreateDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore>)

Required. The [DataStore][google.cloud.discoveryengine.v1alpha.DataStore]
to create.

=item * C<< $msg->data_store_id() >> / C<< $msg->data_store_id($value) >>

Type: C<String>

Required. The ID to use for the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], which will
become the final component of the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore]'s resource
name.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
INVALID_ARGUMENT error is returned.

=item * C<< $msg->create_advanced_site_search() >> / C<< $msg->create_advanced_site_search($value) >>

Type: C<Bool>

A boolean flag indicating whether user want to directly create an advanced
data store for site search.
If the data store is not configured as site
search (GENERIC vertical and PUBLIC_WEBSITE content_config), this flag will
be ignored.

=item * C<< $msg->skip_default_schema_creation() >> / C<< $msg->skip_default_schema_creation($value) >>

Type: C<Bool>

A boolean flag indicating whether to skip the default schema creation for
the data store. Only enable this flag if you are certain that the default
schema is incompatible with your use case.

If set to true, you must manually create a schema for the data store before
any documents can be ingested.

This flag cannot be specified if `data_store.starting_schema` is specified.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::GetDataStoreRequest

Request message for
[DataStoreService.GetDataStore][google.cloud.discoveryengine.v1alpha.DataStoreService.GetDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

If the caller does not have permission to access the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore] does not exist,
a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreMetadata

Metadata related to the progress of the
[DataStoreService.CreateDataStore][google.cloud.discoveryengine.v1alpha.DataStoreService.CreateDataStore]
operation. This will be returned by the google.longrunning.Operation.metadata
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

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::ListDataStoresRequest

Request message for
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1alpha.DataStoreService.ListDataStores]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/collections/{collection_id}`.

If the caller does not have permission to list
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore]s under this
location, regardless of whether or not this data store exists, a
PERMISSION_DENIED error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore]s to return. If
unspecified, defaults to 10. The maximum allowed value is 50. Values above
50 will be coerced to 50.

If this field is negative, an INVALID_ARGUMENT is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListDataStoresResponse.next_page_token][google.cloud.discoveryengine.v1alpha.ListDataStoresResponse.next_page_token],
received from a previous
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1alpha.DataStoreService.ListDataStores]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1alpha.DataStoreService.ListDataStores]
must match the call that provided the page token. Otherwise, an
INVALID_ARGUMENT error is returned.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter by solution type .
For example: `filter = 'solution_type:SOLUTION_TYPE_SEARCH'`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::ListDataStoresResponse

Response message for
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1alpha.DataStoreService.ListDataStores]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_stores() >> / C<< $msg->data_stores($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore>)

All the customer's
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListDataStoresRequest.page_token][google.cloud.discoveryengine.v1alpha.ListDataStoresRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DeleteDataStoreRequest

Request message for
[DataStoreService.DeleteDataStore][google.cloud.discoveryengine.v1alpha.DataStoreService.DeleteDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

If the caller does not have permission to delete the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [DataStore][google.cloud.discoveryengine.v1alpha.DataStore] to
delete does not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDataStoreRequest

Request message for
[DataStoreService.UpdateDataStore][google.cloud.discoveryengine.v1alpha.DataStoreService.UpdateDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore>)

Required. The [DataStore][google.cloud.discoveryengine.v1alpha.DataStore]
to update.

If the caller does not have permission to update the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [DataStore][google.cloud.discoveryengine.v1alpha.DataStore] to
update does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::DeleteDataStoreMetadata

Metadata related to the progress of the
[DataStoreService.DeleteDataStore][google.cloud.discoveryengine.v1alpha.DataStoreService.DeleteDataStore]
operation. This will be returned by the google.longrunning.Operation.metadata
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

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::GetDocumentProcessingConfigRequest

Request for
[DataStoreService.GetDocumentProcessingConfig][google.cloud.discoveryengine.v1alpha.DataStoreService.GetDocumentProcessingConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full DocumentProcessingConfig resource name. Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/dataStores/{data_store_id}/documentProcessingConfig`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDocumentProcessingConfigRequest

Request for
[DataStoreService.UpdateDocumentProcessingConfig][google.cloud.discoveryengine.v1alpha.DataStoreService.UpdateDocumentProcessingConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_processing_config() >> / C<< $msg->document_processing_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig>)

Required. The
[DocumentProcessingConfig][google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig]
to update.

If the caller does not have permission to update the
[DocumentProcessingConfig][google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig],
then a PERMISSION_DENIED error is returned.

If the
[DocumentProcessingConfig][google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig]
to update does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[DocumentProcessingConfig][google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig]
to update. The following are the only supported fields:

* [DocumentProcessingConfig.ocr_config][google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig.ocr_config]

If not set, all supported fields are updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::DataStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
