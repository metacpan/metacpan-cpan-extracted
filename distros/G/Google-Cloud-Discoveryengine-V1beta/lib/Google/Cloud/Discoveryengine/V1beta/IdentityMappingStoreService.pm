package Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ckhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9pZGVudGl0eV9tYXBwaW5n
X3N0b3JlX3NlcnZpY2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5w
cm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxpAZ29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvaWRlbnRp
dHlfbWFwcGluZ19zdG9yZS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMu
cHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8iswMKIUNyZWF0ZUlkZW50
aXR5TWFwcGluZ1N0b3JlUmVxdWVzdBJaChBjbWVrX2NvbmZpZ19uYW1lGAUgASgJQi76QSsK
KWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9DbWVrQ29uZmlnSABSDmNtZWtDb25m
aWdOYW1lEiMKDGRpc2FibGVfY21laxgGIAEoCEgAUgtkaXNhYmxlQ21laxJHCgZwYXJlbnQY
ASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9u
UgZwYXJlbnQSPgoZaWRlbnRpdHlfbWFwcGluZ19zdG9yZV9pZBgCIAEoCUID4EECUhZpZGVu
dGl0eU1hcHBpbmdTdG9yZUlkEnQKFmlkZW50aXR5X21hcHBpbmdfc3RvcmUYAyABKAsyOS5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JZGVudGl0eU1hcHBpbmdTdG9y
ZUID4EECUhRpZGVudGl0eU1hcHBpbmdTdG9yZUIOCgxjbWVrX29wdGlvbnMicQoeR2V0SWRl
bnRpdHlNYXBwaW5nU3RvcmVSZXF1ZXN0Ek8KBG5hbWUYASABKAlCO+BBAvpBNQozZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0lkZW50aXR5TWFwcGluZ1N0b3JlUgRuYW1lInQK
IURlbGV0ZUlkZW50aXR5TWFwcGluZ1N0b3JlUmVxdWVzdBJPCgRuYW1lGAEgASgJQjvgQQL6
QTUKM2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9JZGVudGl0eU1hcHBpbmdTdG9y
ZVIEbmFtZSKaAwodSW1wb3J0SWRlbnRpdHlNYXBwaW5nc1JlcXVlc3QSdgoNaW5saW5lX3Nv
dXJjZRgCIAEoCzJPLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkltcG9y
dElkZW50aXR5TWFwcGluZ3NSZXF1ZXN0LklubGluZVNvdXJjZUgAUgxpbmxpbmVTb3VyY2US
cQoWaWRlbnRpdHlfbWFwcGluZ19zdG9yZRgBIAEoCUI74EEC+kE1CjNkaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb20vSWRlbnRpdHlNYXBwaW5nU3RvcmVSFGlkZW50aXR5TWFwcGlu
Z1N0b3JlGoMBCgxJbmxpbmVTb3VyY2UScwoYaWRlbnRpdHlfbWFwcGluZ19lbnRyaWVzGAEg
AygLMjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRlbnRpdHlNYXBw
aW5nRW50cnlSFmlkZW50aXR5TWFwcGluZ0VudHJpZXNCCAoGc291cmNlIlkKHkltcG9ydElk
ZW50aXR5TWFwcGluZ3NSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIuZ29vZ2xl
LnJwYy5TdGF0dXNSDGVycm9yU2FtcGxlcyLVAwocUHVyZ2VJZGVudGl0eU1hcHBpbmdzUmVx
dWVzdBJ1Cg1pbmxpbmVfc291cmNlGAIgASgLMk4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuUHVyZ2VJZGVudGl0eU1hcHBpbmdzUmVxdWVzdC5JbmxpbmVTb3VyY2VI
AFIMaW5saW5lU291cmNlEnEKFmlkZW50aXR5X21hcHBpbmdfc3RvcmUYASABKAlCO+BBAvpB
NQozZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0lkZW50aXR5TWFwcGluZ1N0b3Jl
UhRpZGVudGl0eU1hcHBpbmdTdG9yZRIWCgZmaWx0ZXIYAyABKAlSBmZpbHRlchIZCgVmb3Jj
ZRgEIAEoCEgBUgVmb3JjZYgBARqDAQoMSW5saW5lU291cmNlEnMKGGlkZW50aXR5X21hcHBp
bmdfZW50cmllcxgBIAMoCzI5Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LklkZW50aXR5TWFwcGluZ0VudHJ5UhZpZGVudGl0eU1hcHBpbmdFbnRyaWVzQggKBnNvdXJj
ZUIICgZfZm9yY2UizAEKG0xpc3RJZGVudGl0eU1hcHBpbmdzUmVxdWVzdBJxChZpZGVudGl0
eV9tYXBwaW5nX3N0b3JlGAEgASgJQjvgQQL6QTUKM2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9JZGVudGl0eU1hcHBpbmdTdG9yZVIUaWRlbnRpdHlNYXBwaW5nU3RvcmUSGwoJ
cGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9r
ZW4iuwEKHExpc3RJZGVudGl0eU1hcHBpbmdzUmVzcG9uc2UScwoYaWRlbnRpdHlfbWFwcGlu
Z19lbnRyaWVzGAEgAygLMjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
SWRlbnRpdHlNYXBwaW5nRW50cnlSFmlkZW50aXR5TWFwcGluZ0VudHJpZXMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIqcBCiBMaXN0SWRlbnRpdHlNYXBwaW5n
U3RvcmVzUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghw
YWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4ivgEKIUxpc3RJZGVudGl0
eU1hcHBpbmdTdG9yZXNSZXNwb25zZRJxChdpZGVudGl0eV9tYXBwaW5nX3N0b3JlcxgBIAMo
CzI5Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLklkZW50aXR5TWFwcGlu
Z1N0b3JlUhVpZGVudGl0eU1hcHBpbmdTdG9yZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
Ug1uZXh0UGFnZVRva2VuIpIBCiVJZGVudGl0eU1hcHBpbmdFbnRyeU9wZXJhdGlvbk1ldGFk
YXRhEiMKDXN1Y2Nlc3NfY291bnQYASABKANSDHN1Y2Nlc3NDb3VudBIjCg1mYWlsdXJlX2Nv
dW50GAIgASgDUgxmYWlsdXJlQ291bnQSHwoLdG90YWxfY291bnQYAyABKANSCnRvdGFsQ291
bnQingEKIkRlbGV0ZUlkZW50aXR5TWFwcGluZ1N0b3JlTWV0YWRhdGESOwoLY3JlYXRlX3Rp
bWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3Vw
ZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGlt
ZTKuEgobSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlErkCChpDcmVhdGVJZGVudGl0eU1h
cHBpbmdTdG9yZRJGLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0
ZUlkZW50aXR5TWFwcGluZ1N0b3JlUmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLklkZW50aXR5TWFwcGluZ1N0b3JlIpcBgtPkkwJXIj0vdjFiZXRhL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vaWRlbnRpdHlNYXBwaW5nU3RvcmVzOhZp
ZGVudGl0eV9tYXBwaW5nX3N0b3Jl2kE3cGFyZW50LGlkZW50aXR5X21hcHBpbmdfc3RvcmUs
aWRlbnRpdHlfbWFwcGluZ19zdG9yZV9pZBLnAQoXR2V0SWRlbnRpdHlNYXBwaW5nU3RvcmUS
Qy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5HZXRJZGVudGl0eU1hcHBp
bmdTdG9yZVJlcXVlc3QaOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5J
ZGVudGl0eU1hcHBpbmdTdG9yZSJMgtPkkwI/Ej0vdjFiZXRhL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovaWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp92kEEbmFtZRK0AgoaRGVsZXRl
SWRlbnRpdHlNYXBwaW5nU3RvcmUSRi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5EZWxldGVJZGVudGl0eU1hcHBpbmdTdG9yZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uIq4BgtPkkwI/Kj0vdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovaWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp92kEEbmFtZcpBXwoVZ29vZ2xlLnBy
b3RvYnVmLkVtcHR5EkZnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EZWxl
dGVJZGVudGl0eU1hcHBpbmdTdG9yZU1ldGFkYXRhEoIDChZJbXBvcnRJZGVudGl0eU1hcHBp
bmdzEkIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSW1wb3J0SWRlbnRp
dHlNYXBwaW5nc1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIoQCgtPk
kwJrImYvdjFiZXRhL3tpZGVudGl0eV9tYXBwaW5nX3N0b3JlPXByb2plY3RzLyovbG9jYXRp
b25zLyovaWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp9OmltcG9ydElkZW50aXR5TWFwcGluZ3M6
ASrKQY8BCkJnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JbXBvcnRJZGVu
dGl0eU1hcHBpbmdzUmVzcG9uc2USSWdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLklkZW50aXR5TWFwcGluZ0VudHJ5T3BlcmF0aW9uTWV0YWRhdGES0QIKFVB1cmdlSWRl
bnRpdHlNYXBwaW5ncxJBLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlB1
cmdlSWRlbnRpdHlNYXBwaW5nc1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uItUBgtPkkwJqImUvdjFiZXRhL3tpZGVudGl0eV9tYXBwaW5nX3N0b3JlPXByb2plY3Rz
LyovbG9jYXRpb25zLyovaWRlbnRpdHlNYXBwaW5nU3RvcmVzLyp9OnB1cmdlSWRlbnRpdHlN
YXBwaW5nczoBKspBYgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5Eklnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5JZGVudGl0eU1hcHBpbmdFbnRyeU9wZXJhdGlvbk1ldGFk
YXRhEokCChRMaXN0SWRlbnRpdHlNYXBwaW5ncxJALmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkxpc3RJZGVudGl0eU1hcHBpbmdzUmVxdWVzdBpBLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RJZGVudGl0eU1hcHBpbmdzUmVzcG9uc2Ui
bILT5JMCZhJkL3YxYmV0YS97aWRlbnRpdHlfbWFwcGluZ19zdG9yZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2lkZW50aXR5TWFwcGluZ1N0b3Jlcy8qfTpsaXN0SWRlbnRpdHlNYXBwaW5n
cxL6AQoZTGlzdElkZW50aXR5TWFwcGluZ1N0b3JlcxJFLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkxpc3RJZGVudGl0eU1hcHBpbmdTdG9yZXNSZXF1ZXN0GkYuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdElkZW50aXR5TWFwcGluZ1N0
b3Jlc1Jlc3BvbnNlIk6C0+STAj8SPS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qfS9pZGVudGl0eU1hcHBpbmdTdG9yZXPaQQZwYXJlbnQazwHKQR5kaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2Nv
dmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9k
aXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCpwIKJ2NvbS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIgSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlUHJv
dG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rp
c2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIj
R29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlz
Y292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6
VjFiZXRhSqteCgcSBQ4A+QIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMK
CQoCAwQSAxYASgoJCgIDBRIDFwAtCgkKAgMGEgMYACUKCQoCAwcSAxkAKQoJCgIDCBIDGgAh
CggKAQgSAxwAQAoJCgIIJRIDHABACggKAQgSAx0AaAoJCgIICxIDHQBoCggKAQgSAx4AIgoJ
CgIIChIDHgAiCggKAQgSAx8AQQoJCgIICBIDHwBBCggKAQgSAyAAQAoJCgIIARIDIABACggK
AQgSAyEALQoJCgIIJBIDIQAtCggKAQgSAyIAQAoJCgIIKRIDIgBACggKAQgSAyMAPwoJCgII
LRIDIwA/CjsKAgYAEgQmAHkBGi8gU2VydmljZSBmb3IgbWFuYWdpbmcgSWRlbnRpdHkgTWFw
cGluZyBTdG9yZXMuCgoKCgMGAAESAyYIIwoKCgMGAAMSAycCRgoMCgUGAAOZCBIDJwJGCgsK
AwYAAxIEKAIrSgoNCgUGAAOaCBIEKAIrSgo1CgQGAAIAEgQuAjYDGicgQ3JlYXRlcyBhIG5l
dyBJZGVudGl0eSBNYXBwaW5nIFN0b3JlLgoKDAoFBgACAAESAy4GIAoMCgUGAAIAAhIDLiFC
CgwKBQYAAgADEgMvDyMKDQoFBgACAAQSBDAEMwYKEQoJBgACAASwyrwiEgQwBDMGCg0KBQYA
AgAEEgQ0BDVCChAKCAYAAgAEmwgAEgQ0BDVCCjAKBAYAAgESBDkCPwMaIiBHZXRzIHRoZSBJ
ZGVudGl0eSBNYXBwaW5nIFN0b3JlLgoKDAoFBgACAQESAzkGHQoMCgUGAAIBAhIDOR48CgwK
BQYAAgEDEgM6DyMKDQoFBgACAQQSBDsEPQYKEQoJBgACAQSwyrwiEgQ7BD0GCgwKBQYAAgEE
EgM+BDIKDwoIBgACAQSbCAASAz4EMgozCgQGAAICEgRCAkwDGiUgRGVsZXRlcyB0aGUgSWRl
bnRpdHkgTWFwcGluZyBTdG9yZS4KCgwKBQYAAgIBEgNCBiAKDAoFBgACAgISA0IhQgoMCgUG
AAICAxIDQw8rCg0KBQYAAgIEEgREBEYGChEKCQYAAgIEsMq8IhIERARGBgoMCgUGAAICBBID
RwQyCg8KCAYAAgIEmwgAEgNHBDIKDQoFBgACAgQSBEgESwYKDwoHBgACAgSZCBIESARLBgpY
CgQGAAIDEgRPAlkDGkogSW1wb3J0cyBhIGxpc3Qgb2YgSWRlbnRpdHkgTWFwcGluZyBFbnRy
aWVzIHRvIGFuIElkZW50aXR5IE1hcHBpbmcgU3RvcmUuCgoMCgUGAAIDARIDTwYcCgwKBQYA
AgMCEgNPHToKDAoFBgACAwMSA1APKwoNCgUGAAIDBBIEUQRUBgoRCgkGAAIDBLDKvCISBFEE
VAYKDQoFBgACAwQSBFUEWAYKDwoHBgACAwSZCBIEVQRYBgphCgQGAAIEEgRdAmcDGlMgUHVy
Z2VzIHNwZWNpZmllZCBvciBhbGwgSWRlbnRpdHkgTWFwcGluZyBFbnRyaWVzIGZyb20gYW4g
SWRlbnRpdHkgTWFwcGluZwogU3RvcmUuCgoMCgUGAAIEARIDXQYbCgwKBQYAAgQCEgNdHDgK
DAoFBgACBAMSA14PKwoNCgUGAAIEBBIEXwRiBgoRCgkGAAIEBLDKvCISBF8EYgYKDQoFBgAC
BAQSBGMEZgYKDwoHBgACBASZCBIEYwRmBgpFCgQGAAIFEgRqAm8DGjcgTGlzdHMgSWRlbnRp
dHkgTWFwcGluZ3MgaW4gYW4gSWRlbnRpdHkgTWFwcGluZyBTdG9yZS4KCgwKBQYAAgUBEgNq
BhoKDAoFBgACBQISA2obNgoMCgUGAAIFAxIDaw8rCg0KBQYAAgUEEgRsBG4GChEKCQYAAgUE
sMq8IhIEbARuBgoyCgQGAAIGEgRyAngDGiQgTGlzdHMgYWxsIElkZW50aXR5IE1hcHBpbmcg
U3RvcmVzLgoKDAoFBgACBgESA3IGHwoMCgUGAAIGAhIDciBACgwKBQYAAgYDEgNzDzAKDQoF
BgACBgQSBHQEdgYKEQoJBgACBgSwyrwiEgR0BHYGCgwKBQYAAgYEEgN3BDQKDwoIBgACBgSb
CAASA3cENAq5AQoCBAASBX0AnwEBGqsBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtJZGVudGl0
eU1hcHBpbmdTdG9yZVNlcnZpY2UuQ3JlYXRlSWRlbnRpdHlNYXBwaW5nU3RvcmVdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLklkZW50aXR5TWFwcGluZ1N0b3JlU2Vy
dmljZS5DcmVhdGVJZGVudGl0eU1hcHBpbmdTdG9yZV0KCgoKAwQAARIDfQgpCpcBCgQEAAgA
EgaAAQKLAQMahgEgQ01FSyBvcHRpb25zIGZvciB0aGUgSWRlbnRpdHkgTWFwcGluZyBTdG9y
ZS4gU2V0dGluZyB0aGlzIGZpZWxkIHdpbGwKIG92ZXJyaWRlIHRoZSBkZWZhdWx0IENtZWtD
b25maWcgaWYgb25lIGlzIHNldCBmb3IgdGhlIHByb2plY3QuCgoNCgUEAAgAARIEgAEIFApl
CgQEAAIAEgaDAQSFAQcaVSBSZXNvdXJjZSBuYW1lIG9mIHRoZSBDbWVrQ29uZmlnIHRvIHVz
ZSBmb3IgcHJvdGVjdGluZyB0aGlzIElkZW50aXR5CiBNYXBwaW5nIFN0b3JlLgoKDQoFBAAC
AAUSBIMBBAoKDQoFBAACAAESBIMBCxsKDQoFBAACAAMSBIMBHh8KDwoFBAACAAgSBoMBIIUB
BgoRCgcEAAIACJ8IEgaDASGFAQUKtAEKBAQAAgESBIoBBBoapQEgSWRlbnRpdHkgTWFwcGlu
ZyBTdG9yZSB3aXRob3V0IENNRUsgcHJvdGVjdGlvbnMuIElmIGEgZGVmYXVsdCBDbWVrQ29u
ZmlnCiBpcyBzZXQgZm9yIHRoZSBwcm9qZWN0LCBzZXR0aW5nIHRoaXMgZmllbGQgd2lsbCBv
dmVycmlkZSB0aGUgZGVmYXVsdAogQ21la0NvbmZpZyBhcyB3ZWxsLgoKDQoFBAACAQUSBIoB
BAgKDQoFBAACAQESBIoBCRUKDQoFBAACAQMSBIoBGBkKdAoEBAACAhIGjwEClAEEGmQgUmVx
dWlyZWQuIFRoZSBwYXJlbnQgY29sbGVjdGlvbiByZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCg0KBQQAAgIFEgSP
AQIICg0KBQQAAgIBEgSPAQkPCg0KBQQAAgIDEgSPARITCg8KBQQAAgIIEgaPARSUAQMKEAoI
BAACAgicCAASBJABBCoKEQoHBAACAgifCBIGkQEEkwEFCtABCgQEAAIDEgSaAQJQGsEBIFJl
cXVpcmVkLiBUaGUgSUQgb2YgdGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gY3JlYXRl
LgoKIFRoZSBJRCBtdXN0IGNvbnRhaW4gb25seSBsZXR0ZXJzIChhLXosIEEtWiksIG51bWJl
cnMgKDAtOSksIHVuZGVyc2NvcmVzCiAoXyksIGFuZCBoeXBoZW5zICgtKS4gVGhlIG1heGlt
dW0gbGVuZ3RoIGlzIDYzIGNoYXJhY3RlcnMuCgoNCgUEAAIDBRIEmgECCAoNCgUEAAIDARIE
mgEJIgoNCgUEAAIDAxIEmgElJgoNCgUEAAIDCBIEmgEnTwoQCggEAAIDCJwIABIEmgEoTgpB
CgQEAAIEEgadAQKeAS8aMSBSZXF1aXJlZC4gVGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmUg
dG8gY3JlYXRlLgoKDQoFBAACBAYSBJ0BAhYKDQoFBAACBAESBJ0BFy0KDQoFBAACBAMSBJ0B
MDEKDQoFBAACBAgSBJ4BBi4KEAoIBAACBAicCAASBJ4BBy0KtAEKAgQBEgajAQCtAQEapQEg
UmVxdWVzdCBtZXNzYWdlIGZvcgogW0lkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5HZXRJ
ZGVudGl0eU1hcHBpbmdTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkdldElkZW50aXR5TWFwcGluZ1N0b3Jl
XQoKCwoDBAEBEgSjAQgmCqwBCgQEAQIAEganAQKsAQQamwEgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBJZGVudGl0eSBNYXBwaW5nIFN0b3JlIHRvIGdldC4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaWRlbnRpdHlNYXBwaW5nU3Rv
cmVzL3tpZGVudGl0eU1hcHBpbmdTdG9yZX1gCgoNCgUEAQIABRIEpwECCAoNCgUEAQIAARIE
pwEJDQoNCgUEAQIAAxIEpwEQEQoPCgUEAQIACBIGpwESrAEDChAKCAQBAgAInAgAEgSoAQQq
ChEKBwQBAgAInwgSBqkBBKsBBQq6AQoCBAISBrEBALsBARqrASBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkRlbGV0ZUlkZW50aXR5TWFwcGlu
Z1N0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JZGVudGl0eU1h
cHBpbmdTdG9yZVNlcnZpY2UuRGVsZXRlSWRlbnRpdHlNYXBwaW5nU3RvcmVdCgoLCgMEAgES
BLEBCCkKrwEKBAQCAgASBrUBAroBBBqeASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIElk
ZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gZGVsZXRlLgogRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pZGVudGl0eU1hcHBpbmdTdG9yZXMve2lk
ZW50aXR5TWFwcGluZ1N0b3JlfWAKCg0KBQQCAgAFEgS1AQIICg0KBQQCAgABEgS1AQkNCg0K
BQQCAgADEgS1ARARCg8KBQQCAgAIEga1ARK6AQMKEAoIBAICAAicCAASBLYBBCoKEQoHBAIC
AAifCBIGtwEEuQEFCrIBCgIEAxIGvwEA1QEBGqMBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtJ
ZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuSW1wb3J0SWRlbnRpdHlNYXBwaW5nc11bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRlbnRpdHlNYXBwaW5nU3RvcmVT
ZXJ2aWNlLkltcG9ydElkZW50aXR5TWFwcGluZ3NdCgoLCgMEAwESBL8BCCUKTAoEBAMDABIG
wQECxAEDGjwgVGhlIGlubGluZSBzb3VyY2UgdG8gaW1wb3J0IGlkZW50aXR5IG1hcHBpbmcg
ZW50cmllcyBmcm9tLgoKDQoFBAMDAAESBMEBChYKSAoGBAMDAAIAEgTDAQQ/GjggQSBtYXhp
bXVtIG9mIDEwMDAwIGVudHJpZXMgY2FuIGJlIGltcG9ydGVkIGF0IG9uZSB0aW1lCgoPCgcE
AwMAAgAEEgTDAQQMCg8KBwQDAwACAAYSBMMBDSEKDwoHBAMDAAIAARIEwwEiOgoPCgcEAwMA
AgADEgTDAT0+CioKBAQDCAASBscBAsoBAxoaIFRoZSBzb3VyY2Ugb2YgdGhlIGlucHV0LgoK
DQoFBAMIAAESBMcBCA4KSgoEBAMCABIEyQEEIxo8IFRoZSBpbmxpbmUgc291cmNlIHRvIGlt
cG9ydCBpZGVudGl0eSBtYXBwaW5nIGVudHJpZXMgZnJvbS4KCg0KBQQDAgAGEgTJAQQQCg0K
BQQDAgABEgTJAREeCg0KBQQDAgADEgTJASEiCssBCgQEAwIBEgbPAQLUAQQaugEgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBJZGVudGl0eSBNYXBwaW5nIFN0b3JlIHRvIGltcG9ydCBJ
ZGVudGl0eSBNYXBwaW5nCiBFbnRyaWVzIHRvLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2lkZW50aXR5TWFwcGluZ1N0b3Jlcy97aWRlbnRp
dHlNYXBwaW5nU3RvcmV9YAoKDQoFBAMCAQUSBM8BAggKDQoFBAMCAQESBM8BCR8KDQoFBAMC
AQMSBM8BIiMKDwoFBAMCAQgSBs8BJNQBAwoQCggEAwIBCJwIABIE0AEEKgoRCgcEAwIBCJ8I
EgbRAQTTAQUKswEKAgQEEgbZAQDcAQEapAEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtJZGVu
dGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuSW1wb3J0SWRlbnRpdHlNYXBwaW5nc11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRlbnRpdHlNYXBwaW5nU3RvcmVTZXJ2
aWNlLkltcG9ydElkZW50aXR5TWFwcGluZ3NdCgoLCgMEBAESBNkBCCYKTAoEBAQCABIE2wEC
Lxo+IEEgc2FtcGxlIG9mIGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSBwcm9jZXNzaW5nIHRo
ZSByZXF1ZXN0LgoKDQoFBAQCAAQSBNsBAgoKDQoFBAQCAAYSBNsBCxwKDQoFBAQCAAESBNsB
HSoKDQoFBAQCAAMSBNsBLS4KsAEKAgQFEgbgAQCRAgEaoQEgUmVxdWVzdCBtZXNzYWdlIGZv
cgogW0lkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5QdXJnZUlkZW50aXR5TWFwcGluZ3Nd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLklkZW50aXR5TWFwcGluZ1N0
b3JlU2VydmljZS5QdXJnZUlkZW50aXR5TWFwcGluZ3NdCgoLCgMEBQESBOABCCQKSwoEBAUD
ABIG4gEC5QEDGjsgVGhlIGlubGluZSBzb3VyY2UgdG8gcHVyZ2UgaWRlbnRpdHkgbWFwcGlu
ZyBlbnRyaWVzIGZyb20uCgoNCgUEBQMAARIE4gEKFgpGCgYEBQMAAgASBOQBBD8aNiBBIG1h
eGltdW0gb2YgMTAwMDAgZW50cmllcyBjYW4gYmUgcHVyZ2VkIGF0IG9uZSB0aW1lCgoPCgcE
BQMAAgAEEgTkAQQMCg8KBwQFAwACAAYSBOQBDSEKDwoHBAUDAAIAARIE5AEiOgoPCgcEBQMA
AgADEgTkAT0+CioKBAQFCAASBugBAusBAxoaIFRoZSBzb3VyY2Ugb2YgdGhlIGlucHV0LgoK
DQoFBAUIAAESBOgBCA4KSQoEBAUCABIE6gEEIxo7IFRoZSBpbmxpbmUgc291cmNlIHRvIHB1
cmdlIGlkZW50aXR5IG1hcHBpbmcgZW50cmllcyBmcm9tLgoKDQoFBAUCAAYSBOoBBBAKDQoF
BAUCAAESBOoBER4KDQoFBAUCAAMSBOoBISIKzAEKBAQFAgESBvABAvUBBBq7ASBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIElkZW50aXR5IE1hcHBpbmcgU3RvcmUgdG8gcHVyZ2UgSWRl
bnRpdHkgTWFwcGluZwogRW50cmllcyBmcm9tLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2lkZW50aXR5TWFwcGluZ1N0b3Jlcy97aWRlbnRp
dHlNYXBwaW5nU3RvcmV9YAoKDQoFBAUCAQUSBPABAggKDQoFBAUCAQESBPABCR8KDQoFBAUC
AQMSBPABIiMKDwoFBAUCAQgSBvABJPUBAwoQCggEBQIBCJwIABIE8QEEKgoRCgcEBQIBCJ8I
EgbyAQT0AQUK8QQKBAQFAgISBIoCAhQa4gQgRmlsdGVyIG1hdGNoaW5nIGlkZW50aXR5IG1h
cHBpbmdzIHRvIHB1cmdlLgogVGhlIGVsaWdpYmxlIGZpZWxkIGZvciBmaWx0ZXJpbmcgaXM6
CgogKiBgdXBkYXRlX3RpbWVgOiBpbiBJU08gODYwMSAienVsdSIgZm9ybWF0LgogKiBgZXh0
ZXJuYWxfaWRgCgogRXhhbXBsZXM6CgogKiBEZWxldGluZyBhbGwgaWRlbnRpdHkgbWFwcGlu
Z3MgdXBkYXRlZCBpbiBhIHRpbWUgcmFuZ2U6CiAgIGB1cGRhdGVfdGltZSA+ICIyMDEyLTA0
LTIzVDE4OjI1OjQzLjUxMVoiIEFORCB1cGRhdGVfdGltZSA8CiAgICIyMDEyLTA0LTIzVDE4
OjMwOjQzLjUxMVoiYAogKiBEZWxldGluZyBhbGwgaWRlbnRpdHkgbWFwcGluZ3MgZm9yIGEg
Z2l2ZW4gZXh0ZXJuYWxfaWQ6CiBgZXh0ZXJuYWxfaWQgPSAiaWQxImAKICogRGVsZXRpbmcg
YWxsIGlkZW50aXR5IG1hcHBpbmdzIGluc2lkZSBhbiBpZGVudGl0eSBtYXBwaW5nIHN0b3Jl
OgogICBgKmAKCiBUaGUgZmlsdGVyaW5nIGZpZWxkcyBhcmUgYXNzdW1lZCB0byBoYXZlIGFu
IGltcGxpY2l0IEFORC4KIFNob3VsZCBub3QgYmUgdXNlZCB3aXRoIHNvdXJjZS4gQW4gZXJy
b3Igd2lsbCBiZSB0aHJvd24sIGlmIGJvdGggYXJlCiBwcm92aWRlZC4KCg0KBQQFAgIFEgSK
AgIICg0KBQQFAgIBEgSKAgkPCg0KBQQFAgIDEgSKAhITCq4CCgQEBQIDEgSQAgIaGp8CIEFj
dHVhbGx5IHBlcmZvcm1zIHRoZSBwdXJnZS4gSWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2Us
IHJldHVybiB0aGUKIGV4cGVjdGVkIHB1cmdlIGNvdW50IHdpdGhvdXQgZGVsZXRpbmcgYW55
IGlkZW50aXR5IG1hcHBpbmdzLiBUaGlzIGZpZWxkIGlzCiBvbmx5IHN1cHBvcnRlZCBmb3Ig
cHVyZ2Ugd2l0aCBmaWx0ZXIuIEZvciBpbnB1dCBzb3VyY2UgdGhpcyBmaWVsZCBpcwogaWdu
b3JlZCBhbmQgZGF0YSB3aWxsIGJlIHB1cmdlZCByZWdhcmRsZXNzIG9mIHRoZSB2YWx1ZSBv
ZiB0aGlzIGZpZWxkLgoKDQoFBAUCAwQSBJACAgoKDQoFBAUCAwUSBJACCw8KDQoFBAUCAwES
BJACEBUKDQoFBAUCAwMSBJACGBkKrgEKAgQGEgaVAgCsAgEanwEgUmVxdWVzdCBtZXNzYWdl
IGZvcgogW0lkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5MaXN0SWRlbnRpdHlNYXBwaW5n
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRlbnRpdHlNYXBwaW5n
U3RvcmVTZXJ2aWNlLkxpc3RJZGVudGl0eU1hcHBpbmdzXQoKCwoDBAYBEgSVAggjCskBCgQE
BgIAEgaZAgKeAgQauAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBJZGVudGl0eSBNYXBw
aW5nIFN0b3JlIHRvIGxpc3QgSWRlbnRpdHkgTWFwcGluZwogRW50cmllcyBpbi4gRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pZGVudGl0eU1h
cHBpbmdTdG9yZXMve2lkZW50aXR5TWFwcGluZ1N0b3JlfWAKCg0KBQQGAgAFEgSZAgIICg0K
BQQGAgABEgSZAgkfCg0KBQQGAgADEgSZAiIjCg8KBQQGAgAIEgaZAiSeAgMKEAoIBAYCAAic
CAASBJoCBCoKEQoHBAYCAAifCBIGmwIEnQIFCrMBCgQEBgIBEgSjAgIWGqQBIE1heGltdW0g
bnVtYmVyIG9mIElkZW50aXR5TWFwcGluZ3MgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwg
ZGVmYXVsdHMKIHRvIDIwMDAuIFRoZSBtYXhpbXVtIGFsbG93ZWQgdmFsdWUgaXMgMTAwMDAu
IFZhbHVlcyBhYm92ZSAxMDAwMCB3aWxsIGJlCiBjb2VyY2VkIHRvIDEwMDAwLgoKDQoFBAYC
AQUSBKMCAgcKDQoFBAYCAQESBKMCCBEKDQoFBAYCAQMSBKMCFBUKggIKBAQGAgISBKsCAhga
8wEgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RJZGVudGl0
eU1hcHBpbmdzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1
ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92
aWRlZCB0bwogYExpc3RJZGVudGl0eU1hcHBpbmdzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRo
YXQgcHJvdmlkZWQgdGhlIHBhZ2UKIHRva2VuLgoKDQoFBAYCAgUSBKsCAggKDQoFBAYCAgES
BKsCCRMKDQoFBAYCAgMSBKsCFhcKrwEKAgQHEgawAgC3AgEaoAEgUmVzcG9uc2UgbWVzc2Fn
ZSBmb3IKIFtJZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuTGlzdElkZW50aXR5TWFwcGlu
Z3NdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLklkZW50aXR5TWFwcGlu
Z1N0b3JlU2VydmljZS5MaXN0SWRlbnRpdHlNYXBwaW5nc10KCgsKAwQHARIEsAIIJAotCgQE
BwIAEgSyAgI9Gh8gVGhlIElkZW50aXR5IE1hcHBpbmcgRW50cmllcy4KCg0KBQQHAgAEEgSy
AgIKCg0KBQQHAgAGEgSyAgsfCg0KBQQHAgABEgSyAiA4Cg0KBQQHAgADEgSyAjs8Co0BCgQE
BwIBEgS2AgIdGn8gQSB0b2tlbiB0aGF0IGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0
byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLiBJZiB0aGlzCiBmaWVsZCBpcyBvbWl0dGVkLCB0
aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQHAgEFEgS2AgIICg0KBQQHAgEB
EgS2AgkYCg0KBQQHAgEDEgS2AhscCrgBCgIECBIGuwIA0gIBGqkBIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtJZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuTGlzdElkZW50aXR5TWFwcGlu
Z1N0b3Jlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRlbnRpdHlN
YXBwaW5nU3RvcmVTZXJ2aWNlLkxpc3RJZGVudGl0eU1hcHBpbmdTdG9yZXNdCgoLCgMECAES
BLsCCCgKgwEKBAQIAgASBr8CAsQCBBpzIFJlcXVpcmVkLiBUaGUgcGFyZW50IG9mIHRoZSBJ
ZGVudGl0eSBNYXBwaW5nIFN0b3JlcyB0byBsaXN0LgogRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAuCgoNCgUECAIABRIEvwICCAoNCgUECAIA
ARIEvwIJDwoNCgUECAIAAxIEvwISEwoPCgUECAIACBIGvwIUxAIDChAKCAQIAgAInAgAEgTA
AgQqChEKBwQIAgAInwgSBsECBMMCBQq0AQoEBAgCARIEyQICFhqlASBNYXhpbXVtIG51bWJl
ciBvZiBJZGVudGl0eU1hcHBpbmdTdG9yZXMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwg
ZGVmYXVsdHMKIHRvIDEwMC4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLiBW
YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlCiBjb2VyY2VkIHRvIDEwMDAuCgoNCgUECAIBBRIE
yQICBwoNCgUECAIBARIEyQIIEQoNCgUECAIBAxIEyQIUFQqMAgoEBAgCAhIE0QICGBr9ASBB
IHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdElkZW50aXR5TWFw
cGluZ1N0b3Jlc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2Vx
dWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJv
dmlkZWQgdG8KIGBMaXN0SWRlbnRpdHlNYXBwaW5nU3RvcmVzYCBtdXN0IG1hdGNoIHRoZSBj
YWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UKIHRva2VuLgoKDQoFBAgCAgUSBNECAggKDQoF
BAgCAgESBNECCRMKDQoFBAgCAgMSBNECFhcKuQEKAgQJEgbWAgDdAgEaqgEgUmVzcG9uc2Ug
bWVzc2FnZSBmb3IKIFtJZGVudGl0eU1hcHBpbmdTdG9yZVNlcnZpY2UuTGlzdElkZW50aXR5
TWFwcGluZ1N0b3Jlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRl
bnRpdHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkxpc3RJZGVudGl0eU1hcHBpbmdTdG9yZXNdCgoL
CgMECQESBNYCCCkKLAoEBAkCABIE2AICPBoeIFRoZSBJZGVudGl0eSBNYXBwaW5nIFN0b3Jl
cy4KCg0KBQQJAgAEEgTYAgIKCg0KBQQJAgAGEgTYAgsfCg0KBQQJAgABEgTYAiA3Cg0KBQQJ
AgADEgTYAjo7Co0BCgQECQIBEgTcAgIdGn8gQSB0b2tlbiB0aGF0IGNhbiBiZSBzZW50IGFz
IGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLiBJZiB0aGlzCiBmaWVs
ZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQJAgEF
EgTcAgIICg0KBQQJAgEBEgTcAgkYCg0KBQQJAgEDEgTcAhscCuYCCgIEChIG4wIA7AIBGtcC
IElkZW50aXR5TWFwcGluZ0VudHJ5IExvbmdSdW5uaW5nT3BlcmF0aW9uIG1ldGFkYXRhIGZv
cgogW0lkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5JbXBvcnRJZGVudGl0eU1hcHBpbmdz
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JZGVudGl0eU1hcHBpbmdT
dG9yZVNlcnZpY2UuSW1wb3J0SWRlbnRpdHlNYXBwaW5nc10KIGFuZAogW0lkZW50aXR5TWFw
cGluZ1N0b3JlU2VydmljZS5QdXJnZUlkZW50aXR5TWFwcGluZ3NdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLklkZW50aXR5TWFwcGluZ1N0b3JlU2VydmljZS5QdXJn
ZUlkZW50aXR5TWFwcGluZ3NdCgoLCgMECgESBOMCCC0KVgoEBAoCABIE5QICGhpIIFRoZSBu
dW1iZXIgb2YgSWRlbnRpdHlNYXBwaW5nRW50cmllcyB0aGF0IHdlcmUgc3VjY2Vzc2Z1bGx5
IHByb2Nlc3NlZC4KCg0KBQQKAgAFEgTlAgIHCg0KBQQKAgABEgTlAggVCg0KBQQKAgADEgTl
AhgZClEKBAQKAgESBOgCAhoaQyBUaGUgbnVtYmVyIG9mIElkZW50aXR5TWFwcGluZ0VudHJp
ZXMgdGhhdCBmYWlsZWQgdG8gYmUgcHJvY2Vzc2VkLgoKDQoFBAoCAQUSBOgCAgcKDQoFBAoC
AQESBOgCCBUKDQoFBAoCAQMSBOgCGBkKTwoEBAoCAhIE6wICGBpBIFRoZSB0b3RhbCBudW1i
ZXIgb2YgSWRlbnRpdHlNYXBwaW5nRW50cmllcyB0aGF0IHdlcmUgcHJvY2Vzc2VkLgoKDQoF
BAoCAgUSBOsCAgcKDQoFBAoCAgESBOsCCBMKDQoFBAoCAgMSBOsCFhcKpQIKAgQLEgbyAgD5
AgEalgIgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBbSWRlbnRp
dHlNYXBwaW5nU3RvcmVTZXJ2aWNlLkRlbGV0ZUlkZW50aXR5TWFwcGluZ1N0b3JlXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JZGVudGl0eU1hcHBpbmdTdG9yZVNl
cnZpY2UuRGVsZXRlSWRlbnRpdHlNYXBwaW5nU3RvcmVdCiBvcGVyYXRpb24uIFRoaXMgd2ls
bCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRh
ZGF0YQogZmllbGQuCgoLCgMECwESBPICCCoKJgoEBAsCABIE9AICLBoYIE9wZXJhdGlvbiBj
cmVhdGUgdGltZS4KCg0KBQQLAgAGEgT0AgIbCg0KBQQLAgABEgT0AhwnCg0KBQQLAgADEgT0
AiorCmQKBAQLAgESBPgCAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhl
IG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0K
BQQLAgEGEgT4AgIbCg0KBQQLAgEBEgT4AhwnCg0KBQQLAgEDEgT4AiorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest ===
    # Fields for CreateIdentityMappingStoreRequest
    # Field: cmek_config_name Type: 9 ()
    # Field: disable_cmek Type: 8 ()
    # Field: parent Type: 9 ()
    # Field: identity_mapping_store_id Type: 9 ()
    # Field: identity_mapping_store Type: 11 (.google.cloud.discoveryengine.v1beta.IdentityMappingStore)

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::GetIdentityMappingStoreRequest ===
    # Fields for GetIdentityMappingStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest ===
    # Fields for DeleteIdentityMappingStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ImportIdentityMappingsRequest ===
    # Fields for ImportIdentityMappingsRequest
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1beta.ImportIdentityMappingsRequest.InlineSource)
    # Field: identity_mapping_store Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ImportIdentityMappingsResponse ===
    # Fields for ImportIdentityMappingsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::PurgeIdentityMappingsRequest ===
    # Fields for PurgeIdentityMappingsRequest
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1beta.PurgeIdentityMappingsRequest.InlineSource)
    # Field: identity_mapping_store Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingsRequest ===
    # Fields for ListIdentityMappingsRequest
    # Field: identity_mapping_store Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingsResponse ===
    # Fields for ListIdentityMappingsResponse
    # Field: identity_mapping_entries Type: 11 (.google.cloud.discoveryengine.v1beta.IdentityMappingEntry)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingStoresRequest ===
    # Fields for ListIdentityMappingStoresRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingStoresResponse ===
    # Fields for ListIdentityMappingStoresResponse
    # Field: identity_mapping_stores Type: 11 (.google.cloud.discoveryengine.v1beta.IdentityMappingStore)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata ===
    # Fields for IdentityMappingEntryOperationMetadata
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: total_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata ===
    # Fields for DeleteIdentityMappingStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::IdentityMappingStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::IdentityMappingStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::IdentityMappingStoreServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'CreateIdentityMappingStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore',
    });
}

sub get_identity_mapping_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::GetIdentityMappingStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'GetIdentityMappingStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore',
    });
}

sub delete_identity_mapping_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'DeleteIdentityMappingStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_identity_mappings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ImportIdentityMappingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'ImportIdentityMappings',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub purge_identity_mappings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::PurgeIdentityMappingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'PurgeIdentityMappings',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_identity_mappings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'ListIdentityMappings',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingsResponse',
    });
}

sub list_identity_mapping_stores {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingStoresRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'ListIdentityMappingStores',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingStoresResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/identity_mapping_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest->new({
        cmek_config_name => $cmek_config_name,
        disable_cmek => $disable_cmek,
        parent => $parent,
        identity_mapping_store_id => $identity_mapping_store_id,
    });

    # Read or update a field
    my $val = $msg->cmek_config_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/identity_mapping_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest

Request message for
[IdentityMappingStoreService.CreateIdentityMappingStore][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.CreateIdentityMappingStore]

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore>)

Required. The Identity Mapping Store to create.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::GetIdentityMappingStoreRequest

Request message for
[IdentityMappingStoreService.GetIdentityMappingStore][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.GetIdentityMappingStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to get.
Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest

Request message for
[IdentityMappingStoreService.DeleteIdentityMappingStore][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.DeleteIdentityMappingStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to delete.
Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ImportIdentityMappingsRequest

Request message for
[IdentityMappingStoreService.ImportIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ImportIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ImportIdentityMappingsRequest::InlineSource>)

The inline source to import identity mapping entries from.

=item * C<< $msg->identity_mapping_store() >> / C<< $msg->identity_mapping_store($value) >>

Type: C<String>

Required. The name of the Identity Mapping Store to import Identity Mapping
Entries to. Format:
`projects/{project}/locations/{location}/identityMappingStores/{identityMappingStore}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ImportIdentityMappingsResponse

Response message for
[IdentityMappingStoreService.ImportIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ImportIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::PurgeIdentityMappingsRequest

Request message for
[IdentityMappingStoreService.PurgeIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.PurgeIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::PurgeIdentityMappingsRequest::InlineSource>)

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

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingsRequest

Request message for
[IdentityMappingStoreService.ListIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ListIdentityMappings]

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

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingsResponse

Response message for
[IdentityMappingStoreService.ListIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ListIdentityMappings]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity_mapping_entries() >> / C<< $msg->identity_mapping_entries($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingEntry>)

The Identity Mapping Entries.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page. If this
field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingStoresRequest

Request message for
[IdentityMappingStoreService.ListIdentityMappingStores][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ListIdentityMappingStores]

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

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::ListIdentityMappingStoresResponse

Response message for
[IdentityMappingStoreService.ListIdentityMappingStores][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ListIdentityMappingStores]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity_mapping_stores() >> / C<< $msg->identity_mapping_stores($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore>)

The Identity Mapping Stores.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page. If this
field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata

IdentityMappingEntry LongRunningOperation metadata for
[IdentityMappingStoreService.ImportIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.ImportIdentityMappings]
and
[IdentityMappingStoreService.PurgeIdentityMappings][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.PurgeIdentityMappings]

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

=head2 Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata

Metadata related to the progress of the
[IdentityMappingStoreService.DeleteIdentityMappingStore][google.cloud.discoveryengine.v1beta.IdentityMappingStoreService.DeleteIdentityMappingStore]
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
