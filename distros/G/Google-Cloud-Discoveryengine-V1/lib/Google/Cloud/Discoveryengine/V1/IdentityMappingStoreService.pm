package Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1::IdentityMappingStore };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2lkZW50aXR5X21hcHBpbmdfc3Rv
cmVfc2VydmljZS5wcm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aPGdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvaWRlbnRpdHlfbWFwcGluZ19z
dG9yZS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2ds
ZS9wcm90b2J1Zi9lbXB0eS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8irwMKIUNyZWF0ZUlkZW50aXR5TWFwcGluZ1N0
b3JlUmVxdWVzdBJaChBjbWVrX2NvbmZpZ19uYW1lGAUgASgJQi76QSsKKWRpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9DbWVrQ29uZmlnSABSDmNtZWtDb25maWdOYW1lEiMKDGRp
c2FibGVfY21laxgGIAEoCEgAUgtkaXNhYmxlQ21laxJHCgZwYXJlbnQYASABKAlCL+BBAvpB
KQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSPgoZ
aWRlbnRpdHlfbWFwcGluZ19zdG9yZV9pZBgCIAEoCUID4EECUhZpZGVudGl0eU1hcHBpbmdT
dG9yZUlkEnAKFmlkZW50aXR5X21hcHBpbmdfc3RvcmUYAyABKAsyNS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLklkZW50aXR5TWFwcGluZ1N0b3JlQgPgQQJSFGlkZW50aXR5
TWFwcGluZ1N0b3JlQg4KDGNtZWtfb3B0aW9ucyJxCh5HZXRJZGVudGl0eU1hcHBpbmdTdG9y
ZVJlcXVlc3QSTwoEbmFtZRgBIAEoCUI74EEC+kE1CjNkaXNjb3ZlcnllbmdpbmUuZ29vZ2xl
YXBpcy5jb20vSWRlbnRpdHlNYXBwaW5nU3RvcmVSBG5hbWUidAohRGVsZXRlSWRlbnRpdHlN
YXBwaW5nU3RvcmVSZXF1ZXN0Ek8KBG5hbWUYASABKAlCO+BBAvpBNQozZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29tL0lkZW50aXR5TWFwcGluZ1N0b3JlUgRuYW1lIpEDCh1JbXBv
cnRJZGVudGl0eU1hcHBpbmdzUmVxdWVzdBJyCg1pbmxpbmVfc291cmNlGAIgASgLMksuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JbXBvcnRJZGVudGl0eU1hcHBpbmdzUmVx
dWVzdC5JbmxpbmVTb3VyY2VIAFIMaW5saW5lU291cmNlEnEKFmlkZW50aXR5X21hcHBpbmdf
c3RvcmUYASABKAlCO+BBAvpBNQozZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0lk
ZW50aXR5TWFwcGluZ1N0b3JlUhRpZGVudGl0eU1hcHBpbmdTdG9yZRp/CgxJbmxpbmVTb3Vy
Y2USbwoYaWRlbnRpdHlfbWFwcGluZ19lbnRyaWVzGAEgAygLMjUuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1hcHBpbmdFbnRyeVIWaWRlbnRpdHlNYXBwaW5n
RW50cmllc0IICgZzb3VyY2UiWQoeSW1wb3J0SWRlbnRpdHlNYXBwaW5nc1Jlc3BvbnNlEjcK
DWVycm9yX3NhbXBsZXMYASADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVz
IswDChxQdXJnZUlkZW50aXR5TWFwcGluZ3NSZXF1ZXN0EnEKDWlubGluZV9zb3VyY2UYAiAB
KAsySi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlB1cmdlSWRlbnRpdHlNYXBw
aW5nc1JlcXVlc3QuSW5saW5lU291cmNlSABSDGlubGluZVNvdXJjZRJxChZpZGVudGl0eV9t
YXBwaW5nX3N0b3JlGAEgASgJQjvgQQL6QTUKM2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9JZGVudGl0eU1hcHBpbmdTdG9yZVIUaWRlbnRpdHlNYXBwaW5nU3RvcmUSFgoGZmls
dGVyGAMgASgJUgZmaWx0ZXISGQoFZm9yY2UYBCABKAhIAVIFZm9yY2WIAQEafwoMSW5saW5l
U291cmNlEm8KGGlkZW50aXR5X21hcHBpbmdfZW50cmllcxgBIAMoCzI1Lmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuSWRlbnRpdHlNYXBwaW5nRW50cnlSFmlkZW50aXR5TWFw
cGluZ0VudHJpZXNCCAoGc291cmNlQggKBl9mb3JjZSLMAQobTGlzdElkZW50aXR5TWFwcGlu
Z3NSZXF1ZXN0EnEKFmlkZW50aXR5X21hcHBpbmdfc3RvcmUYASABKAlCO+BBAvpBNQozZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0lkZW50aXR5TWFwcGluZ1N0b3JlUhRpZGVu
dGl0eU1hcHBpbmdTdG9yZRIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2Vf
dG9rZW4YAyABKAlSCXBhZ2VUb2tlbiK3AQocTGlzdElkZW50aXR5TWFwcGluZ3NSZXNwb25z
ZRJvChhpZGVudGl0eV9tYXBwaW5nX2VudHJpZXMYASADKAsyNS5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLklkZW50aXR5TWFwcGluZ0VudHJ5UhZpZGVudGl0eU1hcHBpbmdF
bnRyaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKnAQogTGlz
dElkZW50aXR5TWFwcGluZ1N0b3Jlc1JlcXVlc3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkK
J2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBh
Z2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu
IroBCiFMaXN0SWRlbnRpdHlNYXBwaW5nU3RvcmVzUmVzcG9uc2USbQoXaWRlbnRpdHlfbWFw
cGluZ19zdG9yZXMYASADKAsyNS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLklk
ZW50aXR5TWFwcGluZ1N0b3JlUhVpZGVudGl0eU1hcHBpbmdTdG9yZXMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIpIBCiVJZGVudGl0eU1hcHBpbmdFbnRyeU9w
ZXJhdGlvbk1ldGFkYXRhEiMKDXN1Y2Nlc3NfY291bnQYASABKANSDHN1Y2Nlc3NDb3VudBIj
Cg1mYWlsdXJlX2NvdW50GAIgASgDUgxmYWlsdXJlQ291bnQSHwoLdG90YWxfY291bnQYAyAB
KANSCnRvdGFsQ291bnQingEKIkRlbGV0ZUlkZW50aXR5TWFwcGluZ1N0b3JlTWV0YWRhdGES
OwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVh
dGVUaW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIKdXBkYXRlVGltZTLWEQobSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlEq0CChpDcmVh
dGVJZGVudGl0eU1hcHBpbmdTdG9yZRJCLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuQ3JlYXRlSWRlbnRpdHlNYXBwaW5nU3RvcmVSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1hcHBpbmdTdG9yZSKTAYLT5JMCUyI5L3YxL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vaWRlbnRpdHlNYXBwaW5nU3RvcmVzOhZp
ZGVudGl0eV9tYXBwaW5nX3N0b3Jl2kE3cGFyZW50LGlkZW50aXR5X21hcHBpbmdfc3RvcmUs
aWRlbnRpdHlfbWFwcGluZ19zdG9yZV9pZBLbAQoXR2V0SWRlbnRpdHlNYXBwaW5nU3RvcmUS
Py5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkdldElkZW50aXR5TWFwcGluZ1N0
b3JlUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuSWRlbnRpdHlN
YXBwaW5nU3RvcmUiSILT5JMCOxI5L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
aWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp92kEEbmFtZRKoAgoaRGVsZXRlSWRlbnRpdHlNYXBw
aW5nU3RvcmUSQi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRlbGV0ZUlkZW50
aXR5TWFwcGluZ1N0b3JlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i
pgGC0+STAjsqOS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lkZW50aXR5TWFw
cGluZ1N0b3Jlcy8qfdpBBG5hbWXKQVsKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRJCZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EZWxldGVJZGVudGl0eU1hcHBpbmdTdG9yZU1l
dGFkYXRhEvICChZJbXBvcnRJZGVudGl0eU1hcHBpbmdzEj4uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5JbXBvcnRJZGVudGl0eU1hcHBpbmdzUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24i+AGC0+STAmciYi92MS97aWRlbnRpdHlfbWFwcGluZ19z
dG9yZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lkZW50aXR5TWFwcGluZ1N0b3Jlcy8qfTpp
bXBvcnRJZGVudGl0eU1hcHBpbmdzOgEqykGHAQo+Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5JbXBvcnRJZGVudGl0eU1hcHBpbmdzUmVzcG9uc2USRWdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjEuSWRlbnRpdHlNYXBwaW5nRW50cnlPcGVyYXRpb25NZXRhZGF0
YRLFAgoVUHVyZ2VJZGVudGl0eU1hcHBpbmdzEj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5QdXJnZUlkZW50aXR5TWFwcGluZ3NSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbiLNAYLT5JMCZiJhL3YxL3tpZGVudGl0eV9tYXBwaW5nX3N0b3JlPXBy
b2plY3RzLyovbG9jYXRpb25zLyovaWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp9OnB1cmdlSWRl
bnRpdHlNYXBwaW5nczoBKspBXgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EkVnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLklkZW50aXR5TWFwcGluZ0VudHJ5T3BlcmF0aW9uTWV0
YWRhdGES/QEKFExpc3RJZGVudGl0eU1hcHBpbmdzEjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5MaXN0SWRlbnRpdHlNYXBwaW5nc1JlcXVlc3QaPS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RJZGVudGl0eU1hcHBpbmdzUmVzcG9uc2UiaILT5JMC
YhJgL3YxL3tpZGVudGl0eV9tYXBwaW5nX3N0b3JlPXByb2plY3RzLyovbG9jYXRpb25zLyov
aWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp9Omxpc3RJZGVudGl0eU1hcHBpbmdzEu4BChlMaXN0
SWRlbnRpdHlNYXBwaW5nU3RvcmVzEkEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5MaXN0SWRlbnRpdHlNYXBwaW5nU3RvcmVzUmVxdWVzdBpCLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuTGlzdElkZW50aXR5TWFwcGluZ1N0b3Jlc1Jlc3BvbnNlIkqC0+ST
AjsSOS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2lkZW50aXR5TWFwcGlu
Z1N0b3Jlc9pBBnBhcmVudBrPAcpBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJB
qgFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxo
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5n
LnJlYWR3cml0ZUKTAgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCIElk
ZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZVByb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28v
ZGlzY292ZXJ5ZW5naW5lL2FwaXYxL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2lu
ZXBiogIPRElTQ09WRVJZRU5HSU5FqgIfR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5W
McoCH0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjHqAiJHb29nbGU6OkNsb3VkOjpE
aXNjb3ZlcnlFbmdpbmU6OlYxSvddCgcSBQ4A+QIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYARgoJCgIDBRIDFwAtCgkKAgMGEgMYACUKCQoCAwcSAxkA
KQoJCgIDCBIDGgAhCggKAQgSAxwAPAoJCgIIJRIDHAA8CggKAQgSAx0AZAoJCgIICxIDHQBk
CggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8AQQoJCgIICBIDHwBBCggKAQgSAyAAPAoJ
CgIIARIDIAA8CggKAQgSAyEALQoJCgIIJBIDIQAtCggKAQgSAyIAPAoJCgIIKRIDIgA8CggK
AQgSAyMAOwoJCgIILRIDIwA7CjsKAgYAEgQmAHkBGi8gU2VydmljZSBmb3IgbWFuYWdpbmcg
SWRlbnRpdHkgTWFwcGluZyBTdG9yZXMuCgoKCgMGAAESAyYIIwoKCgMGAAMSAycCRgoMCgUG
AAOZCBIDJwJGCgsKAwYAAxIEKAIrSgoNCgUGAAOaCBIEKAIrSgo1CgQGAAIAEgQuAjYDGicg
Q3JlYXRlcyBhIG5ldyBJZGVudGl0eSBNYXBwaW5nIFN0b3JlLgoKDAoFBgACAAESAy4GIAoM
CgUGAAIAAhIDLiFCCgwKBQYAAgADEgMvDyMKDQoFBgACAAQSBDAEMwYKEQoJBgACAASwyrwi
EgQwBDMGCg0KBQYAAgAEEgQ0BDVCChAKCAYAAgAEmwgAEgQ0BDVCCjAKBAYAAgESBDkCPwMa
IiBHZXRzIHRoZSBJZGVudGl0eSBNYXBwaW5nIFN0b3JlLgoKDAoFBgACAQESAzkGHQoMCgUG
AAIBAhIDOR48CgwKBQYAAgEDEgM6DyMKDQoFBgACAQQSBDsEPQYKEQoJBgACAQSwyrwiEgQ7
BD0GCgwKBQYAAgEEEgM+BDIKDwoIBgACAQSbCAASAz4EMgozCgQGAAICEgRCAkwDGiUgRGVs
ZXRlcyB0aGUgSWRlbnRpdHkgTWFwcGluZyBTdG9yZS4KCgwKBQYAAgIBEgNCBiAKDAoFBgAC
AgISA0IhQgoMCgUGAAICAxIDQw8rCg0KBQYAAgIEEgREBEYGChEKCQYAAgIEsMq8IhIERARG
BgoMCgUGAAICBBIDRwQyCg8KCAYAAgIEmwgAEgNHBDIKDQoFBgACAgQSBEgESwYKDwoHBgAC
AgSZCBIESARLBgpYCgQGAAIDEgRPAlkDGkogSW1wb3J0cyBhIGxpc3Qgb2YgSWRlbnRpdHkg
TWFwcGluZyBFbnRyaWVzIHRvIGFuIElkZW50aXR5IE1hcHBpbmcgU3RvcmUuCgoMCgUGAAID
ARIDTwYcCgwKBQYAAgMCEgNPHToKDAoFBgACAwMSA1APKwoNCgUGAAIDBBIEUQRUBgoRCgkG
AAIDBLDKvCISBFEEVAYKDQoFBgACAwQSBFUEWAYKDwoHBgACAwSZCBIEVQRYBgphCgQGAAIE
EgRdAmcDGlMgUHVyZ2VzIHNwZWNpZmllZCBvciBhbGwgSWRlbnRpdHkgTWFwcGluZyBFbnRy
aWVzIGZyb20gYW4gSWRlbnRpdHkgTWFwcGluZwogU3RvcmUuCgoMCgUGAAIEARIDXQYbCgwK
BQYAAgQCEgNdHDgKDAoFBgACBAMSA14PKwoNCgUGAAIEBBIEXwRiBgoRCgkGAAIEBLDKvCIS
BF8EYgYKDQoFBgACBAQSBGMEZgYKDwoHBgACBASZCBIEYwRmBgpFCgQGAAIFEgRqAm8DGjcg
TGlzdHMgSWRlbnRpdHkgTWFwcGluZ3MgaW4gYW4gSWRlbnRpdHkgTWFwcGluZyBTdG9yZS4K
CgwKBQYAAgUBEgNqBhoKDAoFBgACBQISA2obNgoMCgUGAAIFAxIDaw8rCg0KBQYAAgUEEgRs
BG4GChEKCQYAAgUEsMq8IhIEbARuBgoyCgQGAAIGEgRyAngDGiQgTGlzdHMgYWxsIElkZW50
aXR5IE1hcHBpbmcgU3RvcmVzLgoKDAoFBgACBgESA3IGHwoMCgUGAAIGAhIDciBACgwKBQYA
AgYDEgNzDzAKDQoFBgACBgQSBHQEdgYKEQoJBgACBgSwyrwiEgR0BHYGCgwKBQYAAgYEEgN3
BDQKDwoIBgACBgSbCAASA3cENAq1AQoCBAASBX0AnwEBGqcBIFJlcXVlc3QgbWVzc2FnZSBm
b3IKIFtJZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuQ3JlYXRlSWRlbnRpdHlNYXBwaW5n
U3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuSWRlbnRpdHlNYXBwaW5n
U3RvcmVTZXJ2aWNlLkNyZWF0ZUlkZW50aXR5TWFwcGluZ1N0b3JlXQoKCgoDBAABEgN9CCkK
lwEKBAQACAASBoABAosBAxqGASBDTUVLIG9wdGlvbnMgZm9yIHRoZSBJZGVudGl0eSBNYXBw
aW5nIFN0b3JlLiBTZXR0aW5nIHRoaXMgZmllbGQgd2lsbAogb3ZlcnJpZGUgdGhlIGRlZmF1
bHQgQ21la0NvbmZpZyBpZiBvbmUgaXMgc2V0IGZvciB0aGUgcHJvamVjdC4KCg0KBQQACAAB
EgSAAQgUCmUKBAQAAgASBoMBBIUBBxpVIFJlc291cmNlIG5hbWUgb2YgdGhlIENtZWtDb25m
aWcgdG8gdXNlIGZvciBwcm90ZWN0aW5nIHRoaXMgSWRlbnRpdHkKIE1hcHBpbmcgU3RvcmUu
CgoNCgUEAAIABRIEgwEECgoNCgUEAAIAARIEgwELGwoNCgUEAAIAAxIEgwEeHwoPCgUEAAIA
CBIGgwEghQEGChEKBwQAAgAInwgSBoMBIYUBBQq0AQoEBAACARIEigEEGhqlASBJZGVudGl0
eSBNYXBwaW5nIFN0b3JlIHdpdGhvdXQgQ01FSyBwcm90ZWN0aW9ucy4gSWYgYSBkZWZhdWx0
IENtZWtDb25maWcKIGlzIHNldCBmb3IgdGhlIHByb2plY3QsIHNldHRpbmcgdGhpcyBmaWVs
ZCB3aWxsIG92ZXJyaWRlIHRoZSBkZWZhdWx0CiBDbWVrQ29uZmlnIGFzIHdlbGwuCgoNCgUE
AAIBBRIEigEECAoNCgUEAAIBARIEigEJFQoNCgUEAAIBAxIEigEYGQp0CgQEAAICEgaPAQKU
AQQaZCBSZXF1aXJlZC4gVGhlIHBhcmVudCBjb2xsZWN0aW9uIHJlc291cmNlIG5hbWUsIHN1
Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDQoF
BAACAgUSBI8BAggKDQoFBAACAgESBI8BCQ8KDQoFBAACAgMSBI8BEhMKDwoFBAACAggSBo8B
FJQBAwoQCggEAAICCJwIABIEkAEEKgoRCgcEAAICCJ8IEgaRAQSTAQUK0AEKBAQAAgMSBJoB
AlAawQEgUmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgSWRlbnRpdHkgTWFwcGluZyBTdG9yZSB0
byBjcmVhdGUuCgogVGhlIElEIG11c3QgY29udGFpbiBvbmx5IGxldHRlcnMgKGEteiwgQS1a
KSwgbnVtYmVycyAoMC05KSwgdW5kZXJzY29yZXMKIChfKSwgYW5kIGh5cGhlbnMgKC0pLiBU
aGUgbWF4aW11bSBsZW5ndGggaXMgNjMgY2hhcmFjdGVycy4KCg0KBQQAAgMFEgSaAQIICg0K
BQQAAgMBEgSaAQkiCg0KBQQAAgMDEgSaASUmCg0KBQQAAgMIEgSaASdPChAKCAQAAgMInAgA
EgSaAShOCkEKBAQAAgQSBp0BAp4BLxoxIFJlcXVpcmVkLiBUaGUgSWRlbnRpdHkgTWFwcGlu
ZyBTdG9yZSB0byBjcmVhdGUuCgoNCgUEAAIEBhIEnQECFgoNCgUEAAIEARIEnQEXLQoNCgUE
AAIEAxIEnQEwMQoNCgUEAAIECBIEngEGLgoQCggEAAIECJwIABIEngEHLQqwAQoCBAESBqMB
AK0BARqhASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2
aWNlLkdldElkZW50aXR5TWFwcGluZ1N0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLklkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5HZXRJZGVudGl0eU1hcHBpbmdT
dG9yZV0KCgsKAwQBARIEowEIJgqsAQoEBAECABIGpwECrAEEGpsBIFJlcXVpcmVkLiBUaGUg
bmFtZSBvZiB0aGUgSWRlbnRpdHkgTWFwcGluZyBTdG9yZSB0byBnZXQuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2lkZW50aXR5TWFwcGlu
Z1N0b3Jlcy97aWRlbnRpdHlNYXBwaW5nU3RvcmV9YAoKDQoFBAECAAUSBKcBAggKDQoFBAEC
AAESBKcBCQ0KDQoFBAECAAMSBKcBEBEKDwoFBAECAAgSBqcBEqwBAwoQCggEAQIACJwIABIE
qAEEKgoRCgcEAQIACJ8IEgapAQSrAQUKtgEKAgQCEgaxAQC7AQEapwEgUmVxdWVzdCBtZXNz
YWdlIGZvcgogW0lkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5EZWxldGVJZGVudGl0eU1h
cHBpbmdTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1h
cHBpbmdTdG9yZVNlcnZpY2UuRGVsZXRlSWRlbnRpdHlNYXBwaW5nU3RvcmVdCgoLCgMEAgES
BLEBCCkKrwEKBAQCAgASBrUBAroBBBqeASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIElk
ZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gZGVsZXRlLgogRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pZGVudGl0eU1hcHBpbmdTdG9yZXMve2lk
ZW50aXR5TWFwcGluZ1N0b3JlfWAKCg0KBQQCAgAFEgS1AQIICg0KBQQCAgABEgS1AQkNCg0K
BQQCAgADEgS1ARARCg8KBQQCAgAIEga1ARK6AQMKEAoIBAICAAicCAASBLYBBCoKEQoHBAIC
AAifCBIGtwEEuQEFCq4BCgIEAxIGvwEA1QEBGp8BIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtJ
ZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuSW1wb3J0SWRlbnRpdHlNYXBwaW5nc11bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZp
Y2UuSW1wb3J0SWRlbnRpdHlNYXBwaW5nc10KCgsKAwQDARIEvwEIJQpMCgQEAwMAEgbBAQLE
AQMaPCBUaGUgaW5saW5lIHNvdXJjZSB0byBpbXBvcnQgaWRlbnRpdHkgbWFwcGluZyBlbnRy
aWVzIGZyb20uCgoNCgUEAwMAARIEwQEKFgpICgYEAwMAAgASBMMBBD8aOCBBIG1heGltdW0g
b2YgMTAwMDAgZW50cmllcyBjYW4gYmUgaW1wb3J0ZWQgYXQgb25lIHRpbWUKCg8KBwQDAwAC
AAQSBMMBBAwKDwoHBAMDAAIABhIEwwENIQoPCgcEAwMAAgABEgTDASI6Cg8KBwQDAwACAAMS
BMMBPT4KKgoEBAMIABIGxwECygEDGhogVGhlIHNvdXJjZSBvZiB0aGUgaW5wdXQuCgoNCgUE
AwgAARIExwEIDgpKCgQEAwIAEgTJAQQjGjwgVGhlIGlubGluZSBzb3VyY2UgdG8gaW1wb3J0
IGlkZW50aXR5IG1hcHBpbmcgZW50cmllcyBmcm9tLgoKDQoFBAMCAAYSBMkBBBAKDQoFBAMC
AAESBMkBER4KDQoFBAMCAAMSBMkBISIKywEKBAQDAgESBs8BAtQBBBq6ASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gaW1wb3J0IElkZW50
aXR5IE1hcHBpbmcKIEVudHJpZXMgdG8uIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vaWRlbnRpdHlNYXBwaW5nU3RvcmVzL3tpZGVudGl0eU1h
cHBpbmdTdG9yZX1gCgoNCgUEAwIBBRIEzwECCAoNCgUEAwIBARIEzwEJHwoNCgUEAwIBAxIE
zwEiIwoPCgUEAwIBCBIGzwEk1AEDChAKCAQDAgEInAgAEgTQAQQqChEKBwQDAgEInwgSBtEB
BNMBBQqvAQoCBAQSBtkBANwBARqgASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0lkZW50aXR5
TWFwcGluZ1N0b3JlU2VydmljZS5JbXBvcnRJZGVudGl0eU1hcHBpbmdzXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLklkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5JbXBv
cnRJZGVudGl0eU1hcHBpbmdzXQoKCwoDBAQBEgTZAQgmCkwKBAQEAgASBNsBAi8aPiBBIHNh
bXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVz
dC4KCg0KBQQEAgAEEgTbAQIKCg0KBQQEAgAGEgTbAQscCg0KBQQEAgABEgTbAR0qCg0KBQQE
AgADEgTbAS0uCqwBCgIEBRIG4AEAkQIBGp0BIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtJZGVu
dGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuUHVyZ2VJZGVudGl0eU1hcHBpbmdzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLklkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5Q
dXJnZUlkZW50aXR5TWFwcGluZ3NdCgoLCgMEBQESBOABCCQKSwoEBAUDABIG4gEC5QEDGjsg
VGhlIGlubGluZSBzb3VyY2UgdG8gcHVyZ2UgaWRlbnRpdHkgbWFwcGluZyBlbnRyaWVzIGZy
b20uCgoNCgUEBQMAARIE4gEKFgpGCgYEBQMAAgASBOQBBD8aNiBBIG1heGltdW0gb2YgMTAw
MDAgZW50cmllcyBjYW4gYmUgcHVyZ2VkIGF0IG9uZSB0aW1lCgoPCgcEBQMAAgAEEgTkAQQM
Cg8KBwQFAwACAAYSBOQBDSEKDwoHBAUDAAIAARIE5AEiOgoPCgcEBQMAAgADEgTkAT0+CioK
BAQFCAASBugBAusBAxoaIFRoZSBzb3VyY2Ugb2YgdGhlIGlucHV0LgoKDQoFBAUIAAESBOgB
CA4KSQoEBAUCABIE6gEEIxo7IFRoZSBpbmxpbmUgc291cmNlIHRvIHB1cmdlIGlkZW50aXR5
IG1hcHBpbmcgZW50cmllcyBmcm9tLgoKDQoFBAUCAAYSBOoBBBAKDQoFBAUCAAESBOoBER4K
DQoFBAUCAAMSBOoBISIKzAEKBAQFAgESBvABAvUBBBq7ASBSZXF1aXJlZC4gVGhlIG5hbWUg
b2YgdGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gcHVyZ2UgSWRlbnRpdHkgTWFwcGlu
ZwogRW50cmllcyBmcm9tLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2lkZW50aXR5TWFwcGluZ1N0b3Jlcy97aWRlbnRpdHlNYXBwaW5nU3Rv
cmV9YAoKDQoFBAUCAQUSBPABAggKDQoFBAUCAQESBPABCR8KDQoFBAUCAQMSBPABIiMKDwoF
BAUCAQgSBvABJPUBAwoQCggEBQIBCJwIABIE8QEEKgoRCgcEBQIBCJ8IEgbyAQT0AQUK8QQK
BAQFAgISBIoCAhQa4gQgRmlsdGVyIG1hdGNoaW5nIGlkZW50aXR5IG1hcHBpbmdzIHRvIHB1
cmdlLgogVGhlIGVsaWdpYmxlIGZpZWxkIGZvciBmaWx0ZXJpbmcgaXM6CgogKiBgdXBkYXRl
X3RpbWVgOiBpbiBJU08gODYwMSAienVsdSIgZm9ybWF0LgogKiBgZXh0ZXJuYWxfaWRgCgog
RXhhbXBsZXM6CgogKiBEZWxldGluZyBhbGwgaWRlbnRpdHkgbWFwcGluZ3MgdXBkYXRlZCBp
biBhIHRpbWUgcmFuZ2U6CiAgIGB1cGRhdGVfdGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1OjQz
LjUxMVoiIEFORCB1cGRhdGVfdGltZSA8CiAgICIyMDEyLTA0LTIzVDE4OjMwOjQzLjUxMVoi
YAogKiBEZWxldGluZyBhbGwgaWRlbnRpdHkgbWFwcGluZ3MgZm9yIGEgZ2l2ZW4gZXh0ZXJu
YWxfaWQ6CiBgZXh0ZXJuYWxfaWQgPSAiaWQxImAKICogRGVsZXRpbmcgYWxsIGlkZW50aXR5
IG1hcHBpbmdzIGluc2lkZSBhbiBpZGVudGl0eSBtYXBwaW5nIHN0b3JlOgogICBgKmAKCiBU
aGUgZmlsdGVyaW5nIGZpZWxkcyBhcmUgYXNzdW1lZCB0byBoYXZlIGFuIGltcGxpY2l0IEFO
RC4KIFNob3VsZCBub3QgYmUgdXNlZCB3aXRoIHNvdXJjZS4gQW4gZXJyb3Igd2lsbCBiZSB0
aHJvd24sIGlmIGJvdGggYXJlCiBwcm92aWRlZC4KCg0KBQQFAgIFEgSKAgIICg0KBQQFAgIB
EgSKAgkPCg0KBQQFAgIDEgSKAhITCq4CCgQEBQIDEgSQAgIaGp8CIEFjdHVhbGx5IHBlcmZv
cm1zIHRoZSBwdXJnZS4gSWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2UsIHJldHVybiB0aGUK
IGV4cGVjdGVkIHB1cmdlIGNvdW50IHdpdGhvdXQgZGVsZXRpbmcgYW55IGlkZW50aXR5IG1h
cHBpbmdzLiBUaGlzIGZpZWxkIGlzCiBvbmx5IHN1cHBvcnRlZCBmb3IgcHVyZ2Ugd2l0aCBm
aWx0ZXIuIEZvciBpbnB1dCBzb3VyY2UgdGhpcyBmaWVsZCBpcwogaWdub3JlZCBhbmQgZGF0
YSB3aWxsIGJlIHB1cmdlZCByZWdhcmRsZXNzIG9mIHRoZSB2YWx1ZSBvZiB0aGlzIGZpZWxk
LgoKDQoFBAUCAwQSBJACAgoKDQoFBAUCAwUSBJACCw8KDQoFBAUCAwESBJACEBUKDQoFBAUC
AwMSBJACGBkKqgEKAgQGEgaVAgCsAgEamwEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0lkZW50
aXR5TWFwcGluZ1N0b3JlU2VydmljZS5MaXN0SWRlbnRpdHlNYXBwaW5nc11bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuTGlz
dElkZW50aXR5TWFwcGluZ3NdCgoLCgMEBgESBJUCCCMKyQEKBAQGAgASBpkCAp4CBBq4ASBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gbGlz
dCBJZGVudGl0eSBNYXBwaW5nCiBFbnRyaWVzIGluLiBGb3JtYXQ6CiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2lkZW50aXR5TWFwcGluZ1N0b3Jlcy97aWRl
bnRpdHlNYXBwaW5nU3RvcmV9YAoKDQoFBAYCAAUSBJkCAggKDQoFBAYCAAESBJkCCR8KDQoF
BAYCAAMSBJkCIiMKDwoFBAYCAAgSBpkCJJ4CAwoQCggEBgIACJwIABIEmgIEKgoRCgcEBgIA
CJ8IEgabAgSdAgUKswEKBAQGAgESBKMCAhYapAEgTWF4aW11bSBudW1iZXIgb2YgSWRlbnRp
dHlNYXBwaW5ncyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8gMjAw
MC4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAxMDAwMC4gVmFsdWVzIGFib3ZlIDEw
MDAwIHdpbGwgYmUKIGNvZXJjZWQgdG8gMTAwMDAuCgoNCgUEBgIBBRIEowICBwoNCgUEBgIB
ARIEowIIEQoNCgUEBgIBAxIEowIUFQqCAgoEBAYCAhIEqwICGBrzASBBIHBhZ2UgdG9rZW4s
IHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdElkZW50aXR5TWFwcGluZ3NgIGNhbGwu
CiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVu
IHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgTGlzdElk
ZW50aXR5TWFwcGluZ3NgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUg
cGFnZQogdG9rZW4uCgoNCgUEBgICBRIEqwICCAoNCgUEBgICARIEqwIJEwoNCgUEBgICAxIE
qwIWFwqrAQoCBAcSBrACALcCARqcASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0lkZW50aXR5
TWFwcGluZ1N0b3JlU2VydmljZS5MaXN0SWRlbnRpdHlNYXBwaW5nc11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuTGlzdElk
ZW50aXR5TWFwcGluZ3NdCgoLCgMEBwESBLACCCQKLQoEBAcCABIEsgICPRofIFRoZSBJZGVu
dGl0eSBNYXBwaW5nIEVudHJpZXMuCgoNCgUEBwIABBIEsgICCgoNCgUEBwIABhIEsgILHwoN
CgUEBwIAARIEsgIgOAoNCgUEBwIAAxIEsgI7PAqNAQoEBAcCARIEtgICHRp/IEEgdG9rZW4g
dGhhdCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZS4gSWYgdGhpcwogZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVl
bnQgcGFnZXMuCgoNCgUEBwIBBRIEtgICCAoNCgUEBwIBARIEtgIJGAoNCgUEBwIBAxIEtgIb
HAq0AQoCBAgSBrsCANICARqlASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbSWRlbnRpdHlNYXBw
aW5nU3RvcmVTZXJ2aWNlLkxpc3RJZGVudGl0eU1hcHBpbmdTdG9yZXNdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkxpc3RJ
ZGVudGl0eU1hcHBpbmdTdG9yZXNdCgoLCgMECAESBLsCCCgKgwEKBAQIAgASBr8CAsQCBBpz
IFJlcXVpcmVkLiBUaGUgcGFyZW50IG9mIHRoZSBJZGVudGl0eSBNYXBwaW5nIFN0b3JlcyB0
byBsaXN0LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufWAuCgoNCgUECAIABRIEvwICCAoNCgUECAIAARIEvwIJDwoNCgUECAIAAxIEvwISEwoP
CgUECAIACBIGvwIUxAIDChAKCAQIAgAInAgAEgTAAgQqChEKBwQIAgAInwgSBsECBMMCBQq0
AQoEBAgCARIEyQICFhqlASBNYXhpbXVtIG51bWJlciBvZiBJZGVudGl0eU1hcHBpbmdTdG9y
ZXMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwgZGVmYXVsdHMKIHRvIDEwMC4gVGhlIG1h
eGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLiBWYWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJl
CiBjb2VyY2VkIHRvIDEwMDAuCgoNCgUECAIBBRIEyQICBwoNCgUECAIBARIEyQIIEQoNCgUE
CAIBAxIEyQIUFQqMAgoEBAgCAhIE0QICGBr9ASBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZy
b20gYSBwcmV2aW91cyBgTGlzdElkZW50aXR5TWFwcGluZ1N0b3Jlc2AgY2FsbC4KIFByb3Zp
ZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5h
dGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8KIGBMaXN0SWRlbnRpdHlN
YXBwaW5nU3RvcmVzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBh
Z2UKIHRva2VuLgoKDQoFBAgCAgUSBNECAggKDQoFBAgCAgESBNECCRMKDQoFBAgCAgMSBNEC
FhcKtQEKAgQJEgbWAgDdAgEapgEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtJZGVudGl0eU1h
cHBpbmdTdG9yZVNlcnZpY2UuTGlzdElkZW50aXR5TWFwcGluZ1N0b3Jlc11bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuTGlz
dElkZW50aXR5TWFwcGluZ1N0b3Jlc10KCgsKAwQJARIE1gIIKQosCgQECQIAEgTYAgI8Gh4g
VGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmVzLgoKDQoFBAkCAAQSBNgCAgoKDQoFBAkCAAYS
BNgCCx8KDQoFBAkCAAESBNgCIDcKDQoFBAkCAAMSBNgCOjsKjQEKBAQJAgESBNwCAh0afyBB
IHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRo
ZSBuZXh0IHBhZ2UuIElmIHRoaXMKIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBz
dWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAkCAQUSBNwCAggKDQoFBAkCAQESBNwCCRgKDQoFBAkC
AQMSBNwCGxwK3gIKAgQKEgbjAgDsAgEazwIgSWRlbnRpdHlNYXBwaW5nRW50cnkgTG9uZ1J1
bm5pbmdPcGVyYXRpb24gbWV0YWRhdGEgZm9yCiBbSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2
aWNlLkltcG9ydElkZW50aXR5TWFwcGluZ3NdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkltcG9ydElkZW50aXR5TWFwcGlu
Z3NdCiBhbmQKIFtJZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuUHVyZ2VJZGVudGl0eU1h
cHBpbmdzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLklkZW50aXR5TWFwcGlu
Z1N0b3JlU2VydmljZS5QdXJnZUlkZW50aXR5TWFwcGluZ3NdCgoLCgMECgESBOMCCC0KVgoE
BAoCABIE5QICGhpIIFRoZSBudW1iZXIgb2YgSWRlbnRpdHlNYXBwaW5nRW50cmllcyB0aGF0
IHdlcmUgc3VjY2Vzc2Z1bGx5IHByb2Nlc3NlZC4KCg0KBQQKAgAFEgTlAgIHCg0KBQQKAgAB
EgTlAggVCg0KBQQKAgADEgTlAhgZClEKBAQKAgESBOgCAhoaQyBUaGUgbnVtYmVyIG9mIElk
ZW50aXR5TWFwcGluZ0VudHJpZXMgdGhhdCBmYWlsZWQgdG8gYmUgcHJvY2Vzc2VkLgoKDQoF
BAoCAQUSBOgCAgcKDQoFBAoCAQESBOgCCBUKDQoFBAoCAQMSBOgCGBkKTwoEBAoCAhIE6wIC
GBpBIFRoZSB0b3RhbCBudW1iZXIgb2YgSWRlbnRpdHlNYXBwaW5nRW50cmllcyB0aGF0IHdl
cmUgcHJvY2Vzc2VkLgoKDQoFBAoCAgUSBOsCAgcKDQoFBAoCAgESBOsCCBMKDQoFBAoCAgMS
BOsCFhcKoQIKAgQLEgbyAgD5AgEakgIgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jl
c3Mgb2YgdGhlCiBbSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkRlbGV0ZUlkZW50aXR5
TWFwcGluZ1N0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLklkZW50aXR5
TWFwcGluZ1N0b3JlU2VydmljZS5EZWxldGVJZGVudGl0eU1hcHBpbmdTdG9yZV0KIG9wZXJh
dGlvbi4gVGhpcyB3aWxsIGJlIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVsZC4KCgsKAwQLARIE8gIIKgomCgQECwIAEgT0AgIs
GhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAsCAAYSBPQCAhsKDQoFBAsCAAESBPQC
HCcKDQoFBAsCAAMSBPQCKisKZAoEBAsCARIE+AICLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0
ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZp
bmlzaCB0aW1lLgoKDQoFBAsCAQYSBPgCAhsKDQoFBAsCAQESBPgCHCcKDQoFBAsCAQMSBPgC
KitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest ===
    # Fields for CreateIdentityMappingStoreRequest
    # Field: cmek_config_name Type: 9 ()
    # Field: disable_cmek Type: 8 ()
    # Field: parent Type: 9 ()
    # Field: identity_mapping_store_id Type: 9 ()
    # Field: identity_mapping_store Type: 11 (.google.cloud.discoveryengine.v1.IdentityMappingStore)

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::GetIdentityMappingStoreRequest ===
    # Fields for GetIdentityMappingStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest ===
    # Fields for DeleteIdentityMappingStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest ===
    # Fields for ImportIdentityMappingsRequest
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1.ImportIdentityMappingsRequest.InlineSource)
    # Field: identity_mapping_store Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsResponse ===
    # Fields for ImportIdentityMappingsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest ===
    # Fields for PurgeIdentityMappingsRequest
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1.PurgeIdentityMappingsRequest.InlineSource)
    # Field: identity_mapping_store Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsRequest ===
    # Fields for ListIdentityMappingsRequest
    # Field: identity_mapping_store Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsResponse ===
    # Fields for ListIdentityMappingsResponse
    # Field: identity_mapping_entries Type: 11 (.google.cloud.discoveryengine.v1.IdentityMappingEntry)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresRequest ===
    # Fields for ListIdentityMappingStoresRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresResponse ===
    # Fields for ListIdentityMappingStoresResponse
    # Field: identity_mapping_stores Type: 11 (.google.cloud.discoveryengine.v1.IdentityMappingStore)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata ===
    # Fields for IdentityMappingEntryOperationMetadata
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: total_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata ===
    # Fields for DeleteIdentityMappingStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingStoreServiceClient

Client stub representing the remote C<IdentityMappingStoreService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_identity_mapping_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'CreateIdentityMappingStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore',
    });
}

sub get_identity_mapping_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::GetIdentityMappingStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'GetIdentityMappingStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore',
    });
}

sub delete_identity_mapping_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'DeleteIdentityMappingStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_identity_mappings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'ImportIdentityMappings',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub purge_identity_mappings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'PurgeIdentityMappings',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_identity_mappings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'ListIdentityMappings',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsResponse',
    });
}

sub list_identity_mapping_stores {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'ListIdentityMappingStores',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/identity_mapping_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest->new({
        cmek_config_name => $cmek_config_name,
        disable_cmek => $disable_cmek,
        parent => $parent,
        identity_mapping_store_id => $identity_mapping_store_id,
    });

    # Read or update a field
    my $val = $msg->cmek_config_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/identity_mapping_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest

Request message for
[IdentityMappingStoreService.CreateIdentityMappingStore][google.cloud.discoveryengine.v1.IdentityMappingStoreService.CreateIdentityMappingStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cmek_config_name() >> / C<< $msg->cmek_config_name($value) >>

Type: C<String>

Resource name of the CmekConfig to use for protecting this Identity
Mapping Store.

=item * C<< $msg->disable_cmek() >> / C<< $msg->disable_cmek($value) >>

Type: C<Bool>

Identity Mapping Store without CMEK protections. If a default CmekConfig
is set for the project, setting this field will override the default
CmekConfig as well.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent collection resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->identity_mapping_store_id() >> / C<< $msg->identity_mapping_store_id($value) >>

Type: C<String>

Required. The ID of the Identity Mapping Store to create.

The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores
(_), and hyphens (-). The maximum length is 63 characters.

=item * C<< $msg->identity_mapping_store() >> / C<< $msg->identity_mapping_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore>)

Required. The Identity Mapping Store to create.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::GetIdentityMappingStoreRequest

Request message for
[IdentityMappingStoreService.GetIdentityMappingStore][google.cloud.discoveryengine.v1.IdentityMappingStoreService.GetIdentityMappingStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to get.
Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest

Request message for
[IdentityMappingStoreService.DeleteIdentityMappingStore][google.cloud.discoveryengine.v1.IdentityMappingStoreService.DeleteIdentityMappingStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to delete.
Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest

Request message for
[IdentityMappingStoreService.ImportIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ImportIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest::InlineSource>)

The inline source to import identity mapping entries from.

=item * C<< $msg->identity_mapping_store() >> / C<< $msg->identity_mapping_store($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to import Identity Mapping
Entries to. Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsResponse

Response message for
[IdentityMappingStoreService.ImportIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ImportIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest

Request message for
[IdentityMappingStoreService.PurgeIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.PurgeIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest::InlineSource>)

The inline source to purge identity mapping entries from.

=item * C<< $msg->identity_mapping_store() >> / C<< $msg->identity_mapping_store($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to purge Identity Mapping
Entries from. Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter matching identity mappings to purge.
The eligible field for filtering is:

* `update_time`: in ISO 8601 "zulu" format.
* `external_id`

Examples:

* Deleting all identity mappings updated in a time range:
  `update_time > "2012-04-23T18:25:43.511Z" AND update_time <
  "2012-04-23T18:30:43.511Z"`
* Deleting all identity mappings for a given external_id:
`external_id = "id1"`
* Deleting all identity mappings inside an identity mapping store:
  `*`

The filtering fields are assumed to have an implicit AND.
Should not be used with source. An error will be thrown, if both are
provided.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually performs the purge. If `force` is set to false, return the
expected purge count without deleting any identity mappings. This field is
only supported for purge with filter. For input source this field is
ignored and data will be purged regardless of the value of this field.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsRequest

Request message for
[IdentityMappingStoreService.ListIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ListIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity_mapping_store() >> / C<< $msg->identity_mapping_store($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to list Identity Mapping
Entries in. Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of IdentityMappings to return. If unspecified, defaults
to 2000. The maximum allowed value is 10000. Values above 10000 will be
coerced to 10000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListIdentityMappings` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`ListIdentityMappings` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsResponse

Response message for
[IdentityMappingStoreService.ListIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ListIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity_mapping_entries() >> / C<< $msg->identity_mapping_entries($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingEntry>)

The Identity Mapping Entries.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page. If this
field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresRequest

Request message for
[IdentityMappingStoreService.ListIdentityMappingStores][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ListIdentityMappingStores]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Identity Mapping Stores to list.
Format:
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of IdentityMappingStores to return. If unspecified, defaults
to 100. The maximum allowed value is 1000. Values above 1000 will be
coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListIdentityMappingStores` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`ListIdentityMappingStores` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresResponse

Response message for
[IdentityMappingStoreService.ListIdentityMappingStores][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ListIdentityMappingStores]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity_mapping_stores() >> / C<< $msg->identity_mapping_stores($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore>)

The Identity Mapping Stores.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page. If this
field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata

IdentityMappingEntry LongRunningOperation metadata for
[IdentityMappingStoreService.ImportIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.ImportIdentityMappings]
and
[IdentityMappingStoreService.PurgeIdentityMappings][google.cloud.discoveryengine.v1.IdentityMappingStoreService.PurgeIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

The number of IdentityMappingEntries that were successfully processed.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

The number of IdentityMappingEntries that failed to be processed.

=item * C<< $msg->total_count() >> / C<< $msg->total_count($value) >>

Type: C<Int64>

The total number of IdentityMappingEntries that were processed.

=back

=head2 Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata

Metadata related to the progress of the
[IdentityMappingStoreService.DeleteIdentityMappingStore][google.cloud.discoveryengine.v1.IdentityMappingStoreService.DeleteIdentityMappingStore]
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

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
