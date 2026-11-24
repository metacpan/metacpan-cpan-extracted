package Google::Cloud::Datacatalog::V1::Policytagmanager;

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
    eval { require Google::Cloud::Datacatalog::V1::Common };
    eval { require Google::Cloud::Datacatalog::V1::Timestamps };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvcG9saWN5dGFnbWFuYWdlci5wcm90bxIb
Z29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL2RhdGFj
YXRhbG9nL3YxL2NvbW1vbi5wcm90bxosZ29vZ2xlL2Nsb3VkL2RhdGFjYXRhbG9nL3YxL3Rp
bWVzdGFtcHMucHJvdG8aHmdvb2dsZS9pYW0vdjEvaWFtX3BvbGljeS5wcm90bxoaZ29vZ2xl
L2lhbS92MS9wb2xpY3kucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29v
Z2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i3gUKCFRheG9ub215EhcKBG5hbWUYASAB
KAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUS
JQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SLQoQcG9saWN5X3RhZ19j
b3VudBgEIAEoBUID4EEDUg5wb2xpY3lUYWdDb3VudBJjChN0YXhvbm9teV90aW1lc3RhbXBz
GAUgASgLMi0uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlN5c3RlbVRpbWVzdGFtcHNC
A+BBA1ISdGF4b25vbXlUaW1lc3RhbXBzEmsKFmFjdGl2YXRlZF9wb2xpY3lfdHlwZXMYBiAD
KA4yMC5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuVGF4b25vbXkuUG9saWN5VHlwZUID
4EEBUhRhY3RpdmF0ZWRQb2xpY3lUeXBlcxJMCgdzZXJ2aWNlGAcgASgLMi0uZ29vZ2xlLmNs
b3VkLmRhdGFjYXRhbG9nLnYxLlRheG9ub215LlNlcnZpY2VCA+BBA1IHc2VydmljZRpmCgdT
ZXJ2aWNlEj8KBG5hbWUYASABKA4yKy5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuTWFu
YWdpbmdTeXN0ZW1SBG5hbWUSGgoIaWRlbnRpdHkYAiABKAlSCGlkZW50aXR5IkoKClBvbGlj
eVR5cGUSGwoXUE9MSUNZX1RZUEVfVU5TUEVDSUZJRUQQABIfChtGSU5FX0dSQUlORURfQUND
RVNTX0NPTlRST0wQATpn6kFkCiNkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9UYXhvbm9t
eRI9cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3RheG9ub21pZXMv
e3RheG9ub215fSLOAgoJUG9saWN5VGFnEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRImCgxk
aXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAyAB
KAlSC2Rlc2NyaXB0aW9uEioKEXBhcmVudF9wb2xpY3lfdGFnGAQgASgJUg9wYXJlbnRQb2xp
Y3lUYWcSLwoRY2hpbGRfcG9saWN5X3RhZ3MYBSADKAlCA+BBA1IPY2hpbGRQb2xpY3lUYWdz
OoAB6kF9CiRkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9Qb2xpY3lUYWcSVXByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90YXhvbm9taWVzL3t0YXhvbm9teX0v
cG9saWN5VGFncy97cG9saWN5X3RhZ30inwEKFUNyZWF0ZVRheG9ub215UmVxdWVzdBJDCgZw
YXJlbnQYASABKAlCK+BBAvpBJRIjZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25v
bXlSBnBhcmVudBJBCgh0YXhvbm9teRgCIAEoCzIlLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxv
Zy52MS5UYXhvbm9teVIIdGF4b25vbXkiWAoVRGVsZXRlVGF4b25vbXlSZXF1ZXN0Ej8KBG5h
bWUYASABKAlCK+BBAvpBJQojZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlS
BG5hbWUilwEKFVVwZGF0ZVRheG9ub215UmVxdWVzdBJBCgh0YXhvbm9teRgBIAEoCzIlLmdv
b2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5UYXhvbm9teVIIdGF4b25vbXkSOwoLdXBkYXRl
X21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIrAB
ChVMaXN0VGF4b25vbWllc1JlcXVlc3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI2RhdGFj
YXRhbG9nLmdvb2dsZWFwaXMuY29tL1RheG9ub215UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIg
ASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoGZmlsdGVy
GAQgASgJUgZmaWx0ZXIihwEKFkxpc3RUYXhvbm9taWVzUmVzcG9uc2USRQoKdGF4b25vbWll
cxgBIAMoCzIlLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5UYXhvbm9teVIKdGF4b25v
bWllcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iVQoSR2V0VGF4
b25vbXlSZXF1ZXN0Ej8KBG5hbWUYASABKAlCK+BBAvpBJQojZGF0YWNhdGFsb2cuZ29vZ2xl
YXBpcy5jb20vVGF4b25vbXlSBG5hbWUipQEKFkNyZWF0ZVBvbGljeVRhZ1JlcXVlc3QSRAoG
cGFyZW50GAEgASgJQizgQQL6QSYSJGRhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29tL1BvbGlj
eVRhZ1IGcGFyZW50EkUKCnBvbGljeV90YWcYAiABKAsyJi5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjEuUG9saWN5VGFnUglwb2xpY3lUYWciWgoWRGVsZXRlUG9saWN5VGFnUmVxdWVz
dBJACgRuYW1lGAEgASgJQizgQQL6QSYKJGRhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29tL1Bv
bGljeVRhZ1IEbmFtZSKcAQoWVXBkYXRlUG9saWN5VGFnUmVxdWVzdBJFCgpwb2xpY3lfdGFn
GAEgASgLMiYuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlBvbGljeVRhZ1IJcG9saWN5
VGFnEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IK
dXBkYXRlTWFzayKZAQoVTGlzdFBvbGljeVRhZ3NSZXF1ZXN0EkQKBnBhcmVudBgBIAEoCUIs
4EEC+kEmEiRkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9Qb2xpY3lUYWdSBnBhcmVudBIb
CglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VU
b2tlbiKJAQoWTGlzdFBvbGljeVRhZ3NSZXNwb25zZRJHCgtwb2xpY3lfdGFncxgBIAMoCzIm
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWdSCnBvbGljeVRhZ3MSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlcKE0dldFBvbGljeVRhZ1Jl
cXVlc3QSQAoEbmFtZRgBIAEoCUIs4EEC+kEmCiRkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNv
bS9Qb2xpY3lUYWdSBG5hbWUyuxUKEFBvbGljeVRhZ01hbmFnZXISvwEKDkNyZWF0ZVRheG9u
b215EjIuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkNyZWF0ZVRheG9ub215UmVxdWVz
dBolLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5UYXhvbm9teSJSgtPkkwI6Ii4vdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS90YXhvbm9taWVzOgh0YXhvbm9tedpB
D3BhcmVudCx0YXhvbm9teRKbAQoORGVsZXRlVGF4b25vbXkSMi5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjEuRGVsZXRlVGF4b25vbXlSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5Ij2C0+STAjAqLi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3RheG9ub21p
ZXMvKn3aQQRuYW1lEsEBCg5VcGRhdGVUYXhvbm9teRIyLmdvb2dsZS5jbG91ZC5kYXRhY2F0
YWxvZy52MS5VcGRhdGVUYXhvbm9teVJlcXVlc3QaJS5nb29nbGUuY2xvdWQuZGF0YWNhdGFs
b2cudjEuVGF4b25vbXkiVILT5JMCQzI3L3YxL3t0YXhvbm9teS5uYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovdGF4b25vbWllcy8qfToIdGF4b25vbXnaQQh0YXhvbm9teRK6AQoOTGlz
dFRheG9ub21pZXMSMi5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuTGlzdFRheG9ub21p
ZXNSZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkxpc3RUYXhvbm9taWVz
UmVzcG9uc2UiP4LT5JMCMBIuL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0v
dGF4b25vbWllc9pBBnBhcmVudBKkAQoLR2V0VGF4b25vbXkSLy5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjEuR2V0VGF4b25vbXlSZXF1ZXN0GiUuZ29vZ2xlLmNsb3VkLmRhdGFjYXRh
bG9nLnYxLlRheG9ub215Ij2C0+STAjASLi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3RheG9ub21pZXMvKn3aQQRuYW1lEtMBCg9DcmVhdGVQb2xpY3lUYWcSMy5nb29nbGUu
Y2xvdWQuZGF0YWNhdGFsb2cudjEuQ3JlYXRlUG9saWN5VGFnUmVxdWVzdBomLmdvb2dsZS5j
bG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWciY4LT5JMCSSI7L3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi90YXhvbm9taWVzLyp9L3BvbGljeVRhZ3M6CnBvbGljeV90
YWfaQRFwYXJlbnQscG9saWN5X3RhZxKqAQoPRGVsZXRlUG9saWN5VGFnEjMuZ29vZ2xlLmNs
b3VkLmRhdGFjYXRhbG9nLnYxLkRlbGV0ZVBvbGljeVRhZ1JlcXVlc3QaFi5nb29nbGUucHJv
dG9idWYuRW1wdHkiSoLT5JMCPSo7L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
dGF4b25vbWllcy8qL3BvbGljeVRhZ3MvKn3aQQRuYW1lEtcBCg9VcGRhdGVQb2xpY3lUYWcS
My5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuVXBkYXRlUG9saWN5VGFnUmVxdWVzdBom
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWciZ4LT5JMCVDJGL3YxL3tw
b2xpY3lfdGFnLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi90YXhvbm9taWVzLyovcG9s
aWN5VGFncy8qfToKcG9saWN5X3RhZ9pBCnBvbGljeV90YWcSxwEKDkxpc3RQb2xpY3lUYWdz
EjIuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkxpc3RQb2xpY3lUYWdzUmVxdWVzdBoz
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5MaXN0UG9saWN5VGFnc1Jlc3BvbnNlIkyC
0+STAj0SOy92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovdGF4b25vbWllcy8q
fS9wb2xpY3lUYWdz2kEGcGFyZW50ErQBCgxHZXRQb2xpY3lUYWcSMC5nb29nbGUuY2xvdWQu
ZGF0YWNhdGFsb2cudjEuR2V0UG9saWN5VGFnUmVxdWVzdBomLmdvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5Qb2xpY3lUYWciSoLT5JMCPRI7L3YxL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovdGF4b25vbWllcy8qL3BvbGljeVRhZ3MvKn3aQQRuYW1lEuoBCgxHZXRJYW1Q
b2xpY3kSIi5nb29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFt
LnYxLlBvbGljeSKeAYLT5JMClwEiPy92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi90YXhvbm9taWVzLyp9OmdldElhbVBvbGljeToBKlpRIkwvdjEve3Jlc291cmNlPXBy
b2plY3RzLyovbG9jYXRpb25zLyovdGF4b25vbWllcy8qL3BvbGljeVRhZ3MvKn06Z2V0SWFt
UG9saWN5OgEqEuoBCgxTZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYxLlNldElhbVBvbGlj
eVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGljeSKeAYLT5JMClwEiPy92MS97cmVzb3Vy
Y2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi90YXhvbm9taWVzLyp9OnNldElhbVBvbGljeToB
KlpRIkwvdjEve3Jlc291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyovdGF4b25vbWllcy8q
L3BvbGljeVRhZ3MvKn06c2V0SWFtUG9saWN5OgEqEpYCChJUZXN0SWFtUGVybWlzc2lvbnMS
KC5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9uc1JlcXVlc3QaKS5nb29nbGUuaWFt
LnYxLlRlc3RJYW1QZXJtaXNzaW9uc1Jlc3BvbnNlIqoBgtPkkwKjASJFL3YxL3tyZXNvdXJj
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3RheG9ub21pZXMvKn06dGVzdElhbVBlcm1pc3Np
b25zOgEqWlciUi92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi90YXhvbm9t
aWVzLyovcG9saWN5VGFncy8qfTp0ZXN0SWFtUGVybWlzc2lvbnM6ASoaTspBGmRhdGFjYXRh
bG9nLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybULaAQofY29tLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MUIVUG9s
aWN5VGFnTWFuYWdlclByb3RvUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWNhdGFsb2cv
YXBpdjEvZGF0YWNhdGFsb2dwYjtkYXRhY2F0YWxvZ3BiqgIbR29vZ2xlLkNsb3VkLkRhdGFD
YXRhbG9nLlYxygIbR29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYx6gIeR29vZ2xlOjpDbG91
ZDo6RGF0YUNhdGFsb2c6OlYxSrRuCgcSBQ4A+QMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYAMgoJCgIDBRIDFwA2CgkKAgMGEgMYACgKCQoCAwcSAxkA
JAoJCgIDCBIDGgAlCgkKAgMJEgMbACoKCAoBCBIDHQA4CgkKAgglEgMdADgKCAoBCBIDHgBY
CgkKAggLEgMeAFgKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAA2CgkKAggIEgMgADYK
CAoBCBIDIQA4CgkKAggBEgMhADgKCAoBCBIDIgA4CgkKAggpEgMiADgKCAoBCBIDIwA3CgkK
AggtEgMjADcKoQIKAgYAEgUrALcBARqTAiBQb2xpY3kgVGFnIE1hbmFnZXIgQVBJIHNlcnZp
Y2UgYWxsb3dzIHlvdSB0byBtYW5hZ2UgeW91ciBwb2xpY3kgdGFncyBhbmQKIHRheG9ub21p
ZXMuCgogUG9saWN5IHRhZ3MgYXJlIHVzZWQgdG8gdGFnIEJpZ1F1ZXJ5IGNvbHVtbnMgYW5k
IGFwcGx5IGFkZGl0aW9uYWwgYWNjZXNzCiBjb250cm9sIHBvbGljaWVzLiBBIHRheG9ub215
IGlzIGEgaGllcmFyY2hpY2FsIGdyb3VwaW5nIG9mIHBvbGljeSB0YWdzIHRoYXQKIGNsYXNz
aWZ5IGRhdGEgYWxvbmcgYSBjb21tb24gYXhpcy4KCgoKAwYAARIDKwgYCgoKAwYAAxIDLAJC
CgwKBQYAA5kIEgMsAkIKCwoDBgADEgQtAi43Cg0KBQYAA5oIEgQtAi43CoYBCgQGAAIAEgQz
AjkDGnggQ3JlYXRlcyBhIHRheG9ub215IGluIGEgc3BlY2lmaWVkIHByb2plY3QuCgogVGhl
IHRheG9ub215IGlzIGluaXRpYWxseSBlbXB0eSwgdGhhdCBpcywgaXQgZG9lc24ndCBjb250
YWluIHBvbGljeSB0YWdzLgoKDAoFBgACAAESAzMGFAoMCgUGAAIAAhIDMxUqCgwKBQYAAgAD
EgMzNT0KDQoFBgACAAQSBDQENwYKEQoJBgACAASwyrwiEgQ0BDcGCgwKBQYAAgAEEgM4BD0K
DwoIBgACAASbCAASAzgEPQqjAQoEBgACARIEPgJDAxqUASBEZWxldGVzIGEgdGF4b25vbXks
IGluY2x1ZGluZyBhbGwgcG9saWN5IHRhZ3MgaW4gdGhpcwogdGF4b25vbXksIHRoZWlyIGFz
c29jaWF0ZWQgcG9saWNpZXMsIGFuZCB0aGUgcG9saWN5IHRhZ3MgcmVmZXJlbmNlcyBmcm9t
CiBCaWdRdWVyeSBjb2x1bW5zLgoKDAoFBgACAQESAz4GFAoMCgUGAAIBAhIDPhUqCgwKBQYA
AgEDEgM+NUoKDQoFBgACAQQSBD8EQQYKEQoJBgACAQSwyrwiEgQ/BEEGCgwKBQYAAgEEEgNC
BDIKDwoIBgACAQSbCAASA0IEMgppCgQGAAICEgRHAk0DGlsgVXBkYXRlcyBhIHRheG9ub215
LCBpbmNsdWRpbmcgaXRzIGRpc3BsYXkgbmFtZSwKIGRlc2NyaXB0aW9uLCBhbmQgYWN0aXZh
dGVkIHBvbGljeSB0eXBlcy4KCgwKBQYAAgIBEgNHBhQKDAoFBgACAgISA0cVKgoMCgUGAAIC
AxIDRzU9Cg0KBQYAAgIEEgRIBEsGChEKCQYAAgIEsMq8IhIESARLBgoMCgUGAAICBBIDTAQ2
Cg8KCAYAAgIEmwgAEgNMBDYKbwoEBgACAxIEUQJWAxphIExpc3RzIGFsbCB0YXhvbm9taWVz
IGluIGEgcHJvamVjdCBpbiBhIHBhcnRpY3VsYXIgbG9jYXRpb24gdGhhdCB5b3UKIGhhdmUg
YSBwZXJtaXNzaW9uIHRvIHZpZXcuCgoMCgUGAAIDARIDUQYUCgwKBQYAAgMCEgNRFSoKDAoF
BgACAwMSA1E1SwoNCgUGAAIDBBIEUgRUBgoRCgkGAAIDBLDKvCISBFIEVAYKDAoFBgACAwQS
A1UENAoPCggGAAIDBJsIABIDVQQ0CiAKBAYAAgQSBFkCXgMaEiBHZXRzIGEgdGF4b25vbXku
CgoMCgUGAAIEARIDWQYRCgwKBQYAAgQCEgNZEiQKDAoFBgACBAMSA1kvNwoNCgUGAAIEBBIE
WgRcBgoRCgkGAAIEBLDKvCISBFoEXAYKDAoFBgACBAQSA10EMgoPCggGAAIEBJsIABIDXQQy
CjMKBAYAAgUSBGECZwMaJSBDcmVhdGVzIGEgcG9saWN5IHRhZyBpbiBhIHRheG9ub215LgoK
DAoFBgACBQESA2EGFQoMCgUGAAIFAhIDYRYsCgwKBQYAAgUDEgNhN0AKDQoFBgACBQQSBGIE
ZQYKEQoJBgACBQSwyrwiEgRiBGUGCgwKBQYAAgUEEgNmBD8KDwoIBgACBQSbCAASA2YEPwqB
AgoEBgACBhIEbwJ0AxryASBEZWxldGVzIGEgcG9saWN5IHRhZyB0b2dldGhlciB3aXRoIHRo
ZSBmb2xsb3dpbmc6CgogKiBBbGwgb2YgaXRzIGRlc2NlbmRhbnQgcG9saWN5IHRhZ3MsIGlm
IGFueQogKiBQb2xpY2llcyBhc3NvY2lhdGVkIHdpdGggdGhlIHBvbGljeSB0YWcgYW5kIGl0
cyBkZXNjZW5kYW50cwogKiBSZWZlcmVuY2VzIGZyb20gQmlnUXVlcnkgdGFibGUgc2NoZW1h
IG9mIHRoZSBwb2xpY3kgdGFnIGFuZCBpdHMKICAgZGVzY2VuZGFudHMKCgwKBQYAAgYBEgNv
BhUKDAoFBgACBgISA28WLAoMCgUGAAIGAxIDbzdMCg0KBQYAAgYEEgRwBHIGChEKCQYAAgYE
sMq8IhIEcARyBgoMCgUGAAIGBBIDcwQyCg8KCAYAAgYEmwgAEgNzBDIKZgoEBgACBxIEeAJ+
AxpYIFVwZGF0ZXMgYSBwb2xpY3kgdGFnLCBpbmNsdWRpbmcgaXRzIGRpc3BsYXkKIG5hbWUs
IGRlc2NyaXB0aW9uLCBhbmQgcGFyZW50IHBvbGljeSB0YWcuCgoMCgUGAAIHARIDeAYVCgwK
BQYAAgcCEgN4FiwKDAoFBgACBwMSA3g3QAoNCgUGAAIHBBIEeQR8BgoRCgkGAAIHBLDKvCIS
BHkEfAYKDAoFBgACBwQSA30EOAoPCggGAAIHBJsIABIDfQQ4CjYKBAYAAggSBoEBAoYBAxom
IExpc3RzIGFsbCBwb2xpY3kgdGFncyBpbiBhIHRheG9ub215LgoKDQoFBgACCAESBIEBBhQK
DQoFBgACCAISBIEBFSoKDQoFBgACCAMSBIEBNUsKDwoFBgACCAQSBoIBBIQBBgoTCgkGAAII
BLDKvCISBoIBBIQBBgoNCgUGAAIIBBIEhQEENAoQCggGAAIIBJsIABIEhQEENAokCgQGAAIJ
EgaJAQKOAQMaFCBHZXRzIGEgcG9saWN5IHRhZy4KCg0KBQYAAgkBEgSJAQYSCg0KBQYAAgkC
EgSJARMmCg0KBQYAAgkDEgSJATE6Cg8KBQYAAgkEEgaKAQSMAQYKEwoJBgACCQSwyrwiEgaK
AQSMAQYKDQoFBgACCQQSBI0BBDIKEAoIBgACCQSbCAASBI0BBDIKRQoEBgACChIGkQECmwED
GjUgR2V0cyB0aGUgSUFNIHBvbGljeSBmb3IgYSBwb2xpY3kgdGFnIG9yIGEgdGF4b25vbXku
CgoNCgUGAAIKARIEkQEGEgoNCgUGAAIKAhIEkQETNAoNCgUGAAIKAxIEkgEPIwoPCgUGAAIK
BBIGkwEEmgEGChMKCQYAAgoEsMq8IhIGkwEEmgEGCkUKBAYAAgsSBp4BAqgBAxo1IFNldHMg
dGhlIElBTSBwb2xpY3kgZm9yIGEgcG9saWN5IHRhZyBvciBhIHRheG9ub215LgoKDQoFBgAC
CwESBJ4BBhIKDQoFBgACCwISBJ4BEzQKDQoFBgACCwMSBJ8BDyMKDwoFBgACCwQSBqABBKcB
BgoTCgkGAAILBLDKvCISBqABBKcBBgpSCgQGAAIMEgasAQK2AQMaQiBSZXR1cm5zIHlvdXIg
cGVybWlzc2lvbnMgb24gYSBzcGVjaWZpZWQgcG9saWN5IHRhZyBvcgogdGF4b25vbXkuCgoN
CgUGAAIMARIErAEGGAoNCgUGAAIMAhIErAEZQAoNCgUGAAIMAxIErQEPNwoPCgUGAAIMBBIG
rgEEtQEGChMKCQYAAgwEsMq8IhIGrgEEtQEGCrMDCgIEABIG0QEAjwIBGqQDIEEgdGF4b25v
bXkgaXMgYSBjb2xsZWN0aW9uIG9mIGhpZXJhcmNoaWNhbCBwb2xpY3kgdGFncyB0aGF0IGNs
YXNzaWZ5IGRhdGEKIGFsb25nIGEgY29tbW9uIGF4aXMuCgogRm9yIGV4YW1wbGUsIGEgImRh
dGEgc2Vuc2l0aXZpdHkiIHRheG9ub215IG1pZ2h0IGNvbnRhaW4gdGhlIGZvbGxvd2luZyBw
b2xpY3kKIHRhZ3M6CgogYGBgCiArIFBJSQogICArIEFjY291bnQgbnVtYmVyCiAgICsgQWdl
CiAgICsgU1NOCiAgICsgWmlwY29kZQogKyBGaW5hbmNpYWxzCiAgICsgUmV2ZW51ZQogYGBg
CgogQSAiZGF0YSBvcmlnaW4iIHRheG9ub215IG1pZ2h0IGNvbnRhaW4gdGhlIGZvbGxvd2lu
ZyBwb2xpY3kgdGFnczoKCiBgYGAKICsgVXNlciBkYXRhCiArIEVtcGxveWVlIGRhdGEKICsg
UGFydG5lciBkYXRhCiArIFB1YmxpYyBkYXRhCiBgYGAKCgsKAwQAARIE0QEIEAoNCgMEAAcS
BtIBAtUBBAoPCgUEAAedCBIG0gEC1QEECk0KBAQABAASBtgBAt8BAxo9IERlZmluZXMgcG9s
aWN5IHR5cGVzIHdoZXJlIHRoZSBwb2xpY3kgdGFncyBjYW4gYmUgdXNlZCBmb3IuCgoNCgUE
AAQAARIE2AEHEQoqCgYEAAQAAgASBNoBBCAaGiBVbnNwZWNpZmllZCBwb2xpY3kgdHlwZS4K
Cg8KBwQABAACAAESBNoBBBsKDwoHBAAEAAIAAhIE2gEeHwpqCgYEAAQAAgESBN4BBCQaWiBG
aW5lLWdyYWluZWQgYWNjZXNzIGNvbnRyb2wgcG9saWN5IHRoYXQgZW5hYmxlcyBhY2Nlc3Mg
Y29udHJvbCBvbgogdGFnZ2VkIHN1Yi1yZXNvdXJjZXMuCgoPCgcEAAQAAgEBEgTeAQQfCg8K
BwQABAACAQISBN4BIiMKNAoEBAADABIG4gEC6AEDGiQgVGhlIHNvdXJjZSBzeXN0ZW0gb2Yg
dGhlIFRheG9ub215LgoKDQoFBAADAAESBOIBChEKMAoGBAADAAIAEgTkAQQcGiAgVGhlIEdv
b2dsZSBDbG91ZCBzZXJ2aWNlIG5hbWUuCgoPCgcEAAMAAgAGEgTkAQQSCg8KBwQAAwACAAES
BOQBExcKDwoHBAADAAIAAxIE5AEaGwo0CgYEAAMAAgESBOcBBBgaJCBUaGUgc2VydmljZSBh
Z2VudCBmb3IgdGhlIHNlcnZpY2UuCgoPCgcEAAMAAgEFEgTnAQQKCg8KBwQAAwACAQESBOcB
CxMKDwoHBAADAAIBAxIE5wEWFwqDAQoEBAACABIE7QECPRp1IElkZW50aWZpZXIuIFJlc291
cmNlIG5hbWUgb2YgdGhpcyB0YXhvbm9teSBpbiBVUkwgZm9ybWF0LgoKIE5vdGU6IFBvbGlj
eSB0YWcgbWFuYWdlciBnZW5lcmF0ZXMgdW5pcXVlIHRheG9ub215IElEcy4KCg0KBQQAAgAF
EgTtAQIICg0KBQQAAgABEgTtAQkNCg0KBQQAAgADEgTtARARCg0KBQQAAgAIEgTtARI8ChAK
CAQAAgAInAgAEgTtARM7CrACCgQEAAIBEgT2AQJDGqECIFJlcXVpcmVkLiBVc2VyLWRlZmlu
ZWQgbmFtZSBvZiB0aGlzIHRheG9ub215LgoKIFRoZSBuYW1lIGNhbid0IHN0YXJ0IG9yIGVu
ZCB3aXRoIHNwYWNlcywgbXVzdCBjb250YWluIG9ubHkgVW5pY29kZSBsZXR0ZXJzLAogbnVt
YmVycywgdW5kZXJzY29yZXMsIGRhc2hlcywgYW5kIHNwYWNlcywgYW5kIGJlIGF0IG1vc3Qg
MjAwIGJ5dGVzIGxvbmcKIHdoZW4gZW5jb2RlZCBpbiBVVEYtOC4KCiBUaGUgdGF4b25vbXkg
ZGlzcGxheSBuYW1lIG11c3QgYmUgdW5pcXVlIHdpdGhpbiBhbiBvcmdhbml6YXRpb24uCgoN
CgUEAAIBBRIE9gECCAoNCgUEAAIBARIE9gEJFQoNCgUEAAIBAxIE9gEYGQoNCgUEAAIBCBIE
9gEaQgoQCggEAAIBCJwIABIE9gEbQQr6AQoEBAACAhIE/QECQhrrASBPcHRpb25hbC4gRGVz
Y3JpcHRpb24gb2YgdGhpcyB0YXhvbm9teS4gSWYgbm90IHNldCwgZGVmYXVsdHMgdG8gZW1w
dHkuCgogVGhlIGRlc2NyaXB0aW9uIG11c3QgY29udGFpbiBvbmx5IFVuaWNvZGUgY2hhcmFj
dGVycywgdGFicywgbmV3bGluZXMsCiBjYXJyaWFnZSByZXR1cm5zLCBhbmQgcGFnZSBicmVh
a3MsIGFuZCBiZSBhdCBtb3N0IDIwMDAgYnl0ZXMgbG9uZyB3aGVuCiBlbmNvZGVkIGluIFVU
Ri04LgoKDQoFBAACAgUSBP0BAggKDQoFBAACAgESBP0BCRQKDQoFBAACAgMSBP0BFxgKDQoF
BAACAggSBP0BGUEKEAoIBAACAgicCAASBP0BGkAKRAoEBAACAxIEgAICSRo2IE91dHB1dCBv
bmx5LiBOdW1iZXIgb2YgcG9saWN5IHRhZ3MgaW4gdGhpcyB0YXhvbm9teS4KCg0KBQQAAgMF
EgSAAgIHCg0KBQQAAgMBEgSAAggYCg0KBQQAAgMDEgSAAhscCg0KBQQAAgMIEgSAAh1IChAK
CAQAAgMInAgAEgSAAh5HClUKBAQAAgQSBoMCAoQCMhpFIE91dHB1dCBvbmx5LiBDcmVhdGlv
biBhbmQgbW9kaWZpY2F0aW9uIHRpbWVzdGFtcHMgb2YgdGhpcyB0YXhvbm9teS4KCg0KBQQA
AgQGEgSDAgISCg0KBQQAAgQBEgSDAhMmCg0KBQQAAgQDEgSDAikqCg0KBQQAAgQIEgSEAgYx
ChAKCAQAAgQInAgAEgSEAgcwCoABCgQEAAIFEgaIAgKJAi8acCBPcHRpb25hbC4gQSBsaXN0
IG9mIHBvbGljeSB0eXBlcyB0aGF0IGFyZSBhY3RpdmF0ZWQgZm9yIHRoaXMgdGF4b25vbXku
IElmCiBub3Qgc2V0LCBkZWZhdWx0cyB0byBhbiBlbXB0eSBsaXN0LgoKDQoFBAACBQQSBIgC
AgoKDQoFBAACBQYSBIgCCxUKDQoFBAACBQESBIgCFiwKDQoFBAACBQMSBIgCLzAKDQoFBAAC
BQgSBIkCBi4KEAoIBAACBQicCAASBIkCBy0KzQEKBAQAAgYSBI4CAkIavgEgT3V0cHV0IG9u
bHkuIElkZW50aXR5IG9mIHRoZSBzZXJ2aWNlIHdoaWNoIG93bnMgdGhlIFRheG9ub215LiBU
aGlzIGZpZWxkIGlzCiBvbmx5IHBvcHVsYXRlZCB3aGVuIHRoZSB0YXhvbm9teSBpcyBjcmVh
dGVkIGJ5IGEgR29vZ2xlIENsb3VkIHNlcnZpY2UuCiBDdXJyZW50bHkgb25seSAnREFUQVBM
RVgnIGlzIHN1cHBvcnRlZC4KCg0KBQQAAgYGEgSOAgIJCg0KBQQAAgYBEgSOAgoRCg0KBQQA
AgYDEgSOAhQVCg0KBQQAAgYIEgSOAhZBChAKCAQAAgYInAgAEgSOAhdACv4BCgIEARIGnQIA
wQIBGu8BIERlbm90ZXMgb25lIHBvbGljeSB0YWcgaW4gYSB0YXhvbm9teSwgZm9yIGV4YW1w
bGUsIFNTTi4KCiBQb2xpY3kgdGFncyBjYW4gYmUgZGVmaW5lZCBpbiBhIGhpZXJhcmNoeS4g
Rm9yIGV4YW1wbGU6CgogYGBgCiArIEdlb2xvY2F0aW9uCiAgICsgTGF0TG9uZwogICArIENp
dHkKICAgKyBaaXBDb2RlCiBgYGAKCiBXaGVyZSB0aGUgIkdlb2xvY2F0aW9uIiBwb2xpY3kg
dGFnIGNvbnRhaW5zIHRocmVlIGNoaWxkcmVuLgoKCwoDBAEBEgSdAggRCg0KAwQBBxIGngIC
oQIECg8KBQQBB50IEgaeAgKhAgQKmwEKBAQBAgASBKYCAj0ajAEgSWRlbnRpZmllci4gUmVz
b3VyY2UgbmFtZSBvZiB0aGlzIHBvbGljeSB0YWcgaW4gdGhlIFVSTCBmb3JtYXQuCgogVGhl
IHBvbGljeSB0YWcgbWFuYWdlciBnZW5lcmF0ZXMgdW5pcXVlIHRheG9ub215IElEcyBhbmQg
cG9saWN5IHRhZyBJRHMuCgoNCgUEAQIABRIEpgICCAoNCgUEAQIAARIEpgIJDQoNCgUEAQIA
AxIEpgIQEQoNCgUEAQIACBIEpgISPAoQCggEAQIACJwIABIEpgITOwqXAgoEBAECARIErQIC
QxqIAiBSZXF1aXJlZC4gVXNlci1kZWZpbmVkIG5hbWUgb2YgdGhpcyBwb2xpY3kgdGFnLgoK
IFRoZSBuYW1lIGNhbid0IHN0YXJ0IG9yIGVuZCB3aXRoIHNwYWNlcyBhbmQgbXVzdCBiZSB1
bmlxdWUgd2l0aGluIHRoZQogcGFyZW50IHRheG9ub215LCBjb250YWluIG9ubHkgVW5pY29k
ZSBsZXR0ZXJzLCBudW1iZXJzLCB1bmRlcnNjb3JlcywgZGFzaGVzCiBhbmQgc3BhY2VzLCBh
bmQgYmUgYXQgbW9zdCAyMDAgYnl0ZXMgbG9uZyB3aGVuIGVuY29kZWQgaW4gVVRGLTguCgoN
CgUEAQIBBRIErQICCAoNCgUEAQIBARIErQIJFQoNCgUEAQIBAxIErQIYGQoNCgUEAQIBCBIE
rQIaQgoQCggEAQIBCJwIABIErQIbQQrxAQoEBAECAhIEtAICGRriASBEZXNjcmlwdGlvbiBv
ZiB0aGlzIHBvbGljeSB0YWcuIElmIG5vdCBzZXQsIGRlZmF1bHRzIHRvIGVtcHR5LgoKIFRo
ZSBkZXNjcmlwdGlvbiBtdXN0IGNvbnRhaW4gb25seSBVbmljb2RlIGNoYXJhY3RlcnMsCiB0
YWJzLCBuZXdsaW5lcywgY2FycmlhZ2UgcmV0dXJucyBhbmQgcGFnZSBicmVha3MsIGFuZCBi
ZSBhdCBtb3N0IDIwMDAgYnl0ZXMKIGxvbmcgd2hlbiBlbmNvZGVkIGluIFVURi04LgoKDQoF
BAECAgUSBLQCAggKDQoFBAECAgESBLQCCRQKDQoFBAECAgMSBLQCFxgKywIKBAQBAgMSBLwC
Ah8avAIgUmVzb3VyY2UgbmFtZSBvZiB0aGlzIHBvbGljeSB0YWcncyBwYXJlbnQgcG9saWN5
IHRhZy4gSWYgZW1wdHksIHRoaXMgaXMgYQogdG9wIGxldmVsIHRhZy4gSWYgbm90IHNldCwg
ZGVmYXVsdHMgdG8gYW4gZW1wdHkgc3RyaW5nLgoKIEZvciBleGFtcGxlLCBmb3IgdGhlICJM
YXRMb25nIiBwb2xpY3kgdGFnIGluIHRoZSBleGFtcGxlIGFib3ZlLCB0aGlzIGZpZWxkCiBj
b250YWlucyB0aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgIkdlb2xvY2F0aW9uIiBwb2xpY3kg
dGFnLCBhbmQsIGZvcgogIkdlb2xvY2F0aW9uIiwgdGhpcyBmaWVsZCBpcyBlbXB0eS4KCg0K
BQQBAgMFEgS8AgIICg0KBQQBAgMBEgS8AgkaCg0KBQQBAgMDEgS8Ah0eClYKBAQBAgQSBr8C
AsACMhpGIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lcyBvZiBjaGlsZCBwb2xpY3kgdGFn
cyBvZiB0aGlzIHBvbGljeSB0YWcuCgoNCgUEAQIEBBIEvwICCgoNCgUEAQIEBRIEvwILEQoN
CgUEAQIEARIEvwISIwoNCgUEAQIEAxIEvwImJwoNCgUEAQIECBIEwAIGMQoQCggEAQIECJwI
ABIEwAIHMApzCgIEAhIGxQIA0AIBGmUgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0NyZWF0ZVRh
eG9ub215XVtnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuUG9saWN5VGFnTWFuYWdlci5D
cmVhdGVUYXhvbm9teV0uCgoLCgMEAgESBMUCCB0KWgoEBAICABIGxwICzAIEGkogUmVxdWly
ZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHByb2plY3QgdGhhdCB0aGUgdGF4b25vbXkgd2ls
bCBiZWxvbmcgdG8uCgoNCgUEAgIABRIExwICCAoNCgUEAgIAARIExwIJDwoNCgUEAgIAAxIE
xwISEwoPCgUEAgIACBIGxwIUzAIDChAKCAQCAgAInAgAEgTIAgQqChEKBwQCAgAInwgSBskC
BMsCBQonCgQEAgIBEgTPAgIYGhkgVGhlIHRheG9ub215IHRvIGNyZWF0ZS4KCg0KBQQCAgEG
EgTPAgIKCg0KBQQCAgEBEgTPAgsTCg0KBQQCAgEDEgTPAhYXCnMKAgQDEgbUAgDeAgEaZSBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGVsZXRlVGF4b25vbXldW2dvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyLkRlbGV0ZVRheG9ub215XS4KCgsKAwQDARIE
1AIIHQp/CgQEAwIAEgbYAgLdAgQabyBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUg
dGF4b25vbXkgdG8gZGVsZXRlLgoKIE5vdGU6IEFsbCBwb2xpY3kgdGFncyBpbiB0aGlzIHRh
eG9ub215IGFyZSBhbHNvIGRlbGV0ZWQuCgoNCgUEAwIABRIE2AICCAoNCgUEAwIAARIE2AIJ
DQoNCgUEAwIAAxIE2AIQEQoPCgUEAwIACBIG2AIS3QIDChAKCAQDAgAInAgAEgTZAgQqChEK
BwQDAgAInwgSBtoCBNwCBQpzCgIEBBIG4gIA7QIBGmUgUmVxdWVzdCBtZXNzYWdlIGZvcgog
W1VwZGF0ZVRheG9ub215XVtnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuUG9saWN5VGFn
TWFuYWdlci5VcGRhdGVUYXhvbm9teV0uCgoLCgMEBAESBOICCB0KdwoEBAQCABIE5QICGBpp
IFRoZSB0YXhvbm9teSB0byB1cGRhdGUuIFlvdSBjYW4gdXBkYXRlIG9ubHkgaXRzIGRlc2Ny
aXB0aW9uLCBkaXNwbGF5IG5hbWUsCiBhbmQgYWN0aXZhdGVkIHBvbGljeSB0eXBlcy4KCg0K
BQQEAgAGEgTlAgIKCg0KBQQEAgABEgTlAgsTCg0KBQQEAgADEgTlAhYXCuQBCgQEBAIBEgTs
AgIsGtUBIFNwZWNpZmllcyBmaWVsZHMgdG8gdXBkYXRlLiBJZiBub3Qgc2V0LCBkZWZhdWx0
cyB0byBhbGwgZmllbGRzIHlvdSBjYW4KIHVwZGF0ZS4KCiBGb3IgbW9yZSBpbmZvcm1hdGlv
biwgc2VlIFtGaWVsZE1hc2tdCiAoaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJv
dG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYjZmllbGRtYXNr
KS4KCg0KBQQEAgEGEgTsAgIbCg0KBQQEAgEBEgTsAhwnCg0KBQQEAgEDEgTsAiorCnMKAgQF
EgbxAgCHAwEaZSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbTGlzdFRheG9ub21pZXNdW2dvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyLkxpc3RUYXhvbm9taWVz
XS4KCgsKAwQFARIE8QIIHQpTCgQEBQIAEgbzAgL4AgQaQyBSZXF1aXJlZC4gUmVzb3VyY2Ug
bmFtZSBvZiB0aGUgcHJvamVjdCB0byBsaXN0IHRoZSB0YXhvbm9taWVzIG9mLgoKDQoFBAUC
AAUSBPMCAggKDQoFBAUCAAESBPMCCQ8KDQoFBAUCAAMSBPMCEhMKDwoFBAUCAAgSBvMCFPgC
AwoQCggEBQIACJwIABIE9AIEKgoRCgcEBQIACJ8IEgb1AgT3AgUKgwEKBAQFAgESBPwCAhYa
dSBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLiBNdXN0IGJlIGEgdmFs
dWUgYmV0d2VlbiAxIGFuZCAxMDAwCiBpbmNsdXNpdmVseS4gSWYgbm90IHNldCwgZGVmYXVs
dHMgdG8gNTAuCgoNCgUEBQIBBRIE/AICBwoNCgUEBQIBARIE/AIIEQoNCgUEBQIBAxIE/AIU
FQqsAQoEBAUCAhIEggMCGBqdASBUaGUgcGFnaW5hdGlvbiB0b2tlbiBvZiB0aGUgbmV4dCBy
ZXN1bHRzIHBhZ2UuIElmIG5vdCBzZXQsCiB0aGUgZmlyc3QgcGFnZSBpcyByZXR1cm5lZC4K
CiBUaGUgdG9rZW4gaXMgcmV0dXJuZWQgaW4gdGhlIHJlc3BvbnNlIHRvIGEgcHJldmlvdXMg
bGlzdCByZXF1ZXN0LgoKDQoFBAUCAgUSBIIDAggKDQoFBAUCAgESBIIDCRMKDQoFBAUCAgMS
BIIDFhcKZwoEBAUCAxIEhgMCFBpZIFN1cHBvcnRlZCBmaWVsZCBmb3IgZmlsdGVyIGlzICdz
ZXJ2aWNlJyBhbmQgdmFsdWUgaXMgJ2RhdGFwbGV4Jy4KIEVnOiBzZXJ2aWNlPWRhdGFwbGV4
LgoKDQoFBAUCAwUSBIYDAggKDQoFBAUCAwESBIYDCQ8KDQoFBAUCAwMSBIYDEhMKdAoCBAYS
BosDAJIDARpmIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbTGlzdFRheG9ub21pZXNdW2dvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyLkxpc3RUYXhvbm9taWVz
XS4KCgsKAwQGARIEiwMIHgo1CgQEBgIAEgSNAwIjGicgVGF4b25vbWllcyB0aGF0IHRoZSBw
cm9qZWN0IGNvbnRhaW5zLgoKDQoFBAYCAAQSBI0DAgoKDQoFBAYCAAYSBI0DCxMKDQoFBAYC
AAESBI0DFB4KDQoFBAYCAAMSBI0DISIKawoEBAYCARIEkQMCHRpdIFBhZ2luYXRpb24gdG9r
ZW4gb2YgdGhlIG5leHQgcmVzdWx0cyBwYWdlLiBFbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1v
cmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQGAgEFEgSRAwIICg0KBQQGAgEBEgSRAwkY
Cg0KBQQGAgEDEgSRAxscCm0KAgQHEgaWAwCeAwEaXyBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
R2V0VGF4b25vbXldW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5h
Z2VyLkdldFRheG9ub215XS4KCgsKAwQHARIElgMIGgpBCgQEBwIAEgaYAwKdAwQaMSBSZXF1
aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgdGF4b25vbXkgdG8gZ2V0LgoKDQoFBAcCAAUS
BJgDAggKDQoFBAcCAAESBJgDCQ0KDQoFBAcCAAMSBJgDEBEKDwoFBAcCAAgSBpgDEp0DAwoQ
CggEBwIACJwIABIEmQMEKgoRCgcEBwIACJ8IEgaaAwScAwUKdQoCBAgSBqIDAK0DARpnIFJl
cXVlc3QgbWVzc2FnZSBmb3IKIFtDcmVhdGVQb2xpY3lUYWddW2dvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyLkNyZWF0ZVBvbGljeVRhZ10uCgoLCgMECAES
BKIDCB4KXQoEBAgCABIGpAMCqQMEGk0gUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhl
IHRheG9ub215IHRoYXQgdGhlIHBvbGljeSB0YWcgd2lsbCBiZWxvbmcgdG8uCgoNCgUECAIA
BRIEpAMCCAoNCgUECAIAARIEpAMJDwoNCgUECAIAAxIEpAMSEwoPCgUECAIACBIGpAMUqQMD
ChAKCAQIAgAInAgAEgSlAwQqChEKBwQIAgAInwgSBqYDBKgDBQopCgQECAIBEgSsAwIbGhsg
VGhlIHBvbGljeSB0YWcgdG8gY3JlYXRlLgoKDQoFBAgCAQYSBKwDAgsKDQoFBAgCAQESBKwD
DBYKDQoFBAgCAQMSBKwDGRoKdQoCBAkSBrEDALsDARpnIFJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtEZWxldGVQb2xpY3lUYWddW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lU
YWdNYW5hZ2VyLkRlbGV0ZVBvbGljeVRhZ10uCgoLCgMECQESBLEDCB4KggEKBAQJAgASBrUD
AroDBBpyIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBwb2xpY3kgdGFnIHRvIGRl
bGV0ZS4KCiBOb3RlOiBBbGwgb2YgaXRzIGRlc2NlbmRhbnQgcG9saWN5IHRhZ3MgYXJlIGFs
c28gZGVsZXRlZC4KCg0KBQQJAgAFEgS1AwIICg0KBQQJAgABEgS1AwkNCg0KBQQJAgADEgS1
AxARCg8KBQQJAgAIEga1AxK6AwMKEAoIBAkCAAicCAASBLYDBCoKEQoHBAkCAAifCBIGtwME
uQMFCnUKAgQKEga/AwDLAwEaZyBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVXBkYXRlUG9saWN5
VGFnXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuUG9saWN5VGFnTWFuYWdlci5VcGRh
dGVQb2xpY3lUYWddLgoKCwoDBAoBEgS/AwgeCnsKBAQKAgASBMIDAhsabSBUaGUgcG9saWN5
IHRhZyB0byB1cGRhdGUuIFlvdSBjYW4gdXBkYXRlIG9ubHkgaXRzIGRlc2NyaXB0aW9uLCBk
aXNwbGF5CiBuYW1lLCBhbmQgcGFyZW50IHBvbGljeSB0YWcgZmllbGRzLgoKDQoFBAoCAAYS
BMIDAgsKDQoFBAoCAAESBMIDDBYKDQoFBAoCAAMSBMIDGRoKqgIKBAQKAgESBMoDAiwamwIg
U3BlY2lmaWVzIHRoZSBmaWVsZHMgdG8gdXBkYXRlLgoKIFlvdSBjYW4gdXBkYXRlIG9ubHkg
ZGlzcGxheSBuYW1lLCBkZXNjcmlwdGlvbiwgYW5kIHBhcmVudCBwb2xpY3kgdGFnLgogSWYg
bm90IHNldCwgZGVmYXVsdHMgdG8gYWxsIHVwZGF0YWJsZSBmaWVsZHMuCiBGb3IgbW9yZSBp
bmZvcm1hdGlvbiwgc2VlIFtGaWVsZE1hc2tdCiAoaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2ds
ZS5jb20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYj
ZmllbGRtYXNrKS4KCg0KBQQKAgEGEgTKAwIbCg0KBQQKAgEBEgTKAxwnCg0KBQQKAgEDEgTK
AyorCnMKAgQLEgbPAwDiAwEaZSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbTGlzdFBvbGljeVRh
Z3NdW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Qb2xpY3lUYWdNYW5hZ2VyLkxpc3RQ
b2xpY3lUYWdzXS4KCgsKAwQLARIEzwMIHQpVCgQECwIAEgbRAwLWAwQaRSBSZXF1aXJlZC4g
UmVzb3VyY2UgbmFtZSBvZiB0aGUgdGF4b25vbXkgdG8gbGlzdCB0aGUgcG9saWN5IHRhZ3Mg
b2YuCgoNCgUECwIABRIE0QMCCAoNCgUECwIAARIE0QMJDwoNCgUECwIAAxIE0QMSEwoPCgUE
CwIACBIG0QMU1gMDChAKCAQLAgAInAgAEgTSAwQqChEKBwQLAgAInwgSBtMDBNUDBQqEAQoE
BAsCARIE2wMCFhp2IFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4uIE11
c3QgYmUgYSB2YWx1ZSBiZXR3ZWVuIDEgYW5kIDEwMDAKIGluY2x1c2l2ZWx5LgogSWYgbm90
IHNldCwgZGVmYXVsdHMgdG8gNTAuCgoNCgUECwIBBRIE2wMCBwoNCgUECwIBARIE2wMIEQoN
CgUECwIBAxIE2wMUFQqoAQoEBAsCAhIE4QMCGBqZASBUaGUgcGFnaW5hdGlvbiB0b2tlbiBv
ZiB0aGUgbmV4dCByZXN1bHRzIHBhZ2UuIElmIG5vdCBzZXQsIHJldHVybnMgdGhlCiBmaXJz
dCBwYWdlLgoKIFRoZSB0b2tlbiBpcyByZXR1cm5lZCBpbiB0aGUgcmVzcG9uc2UgdG8gYSBw
cmV2aW91cyBsaXN0IHJlcXVlc3QuCgoNCgUECwICBRIE4QMCCAoNCgUECwICARIE4QMJEwoN
CgUECwICAxIE4QMWFwp0CgIEDBIG5gMA7QMBGmYgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtM
aXN0UG9saWN5VGFnc11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlBvbGljeVRhZ01h
bmFnZXIuTGlzdFBvbGljeVRhZ3NdLgoKCwoDBAwBEgTmAwgeCjwKBAQMAgASBOgDAiUaLiBU
aGUgcG9saWN5IHRhZ3MgdGhhdCBiZWxvbmcgdG8gdGhlIHRheG9ub215LgoKDQoFBAwCAAQS
BOgDAgoKDQoFBAwCAAYSBOgDCxQKDQoFBAwCAAESBOgDFSAKDQoFBAwCAAMSBOgDIyQKawoE
BAwCARIE7AMCHRpdIFBhZ2luYXRpb24gdG9rZW4gb2YgdGhlIG5leHQgcmVzdWx0cyBwYWdl
LiBFbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0K
BQQMAgEFEgTsAwIICg0KBQQMAgEBEgTsAwkYCg0KBQQMAgEDEgTsAxscCm8KAgQNEgbxAwD5
AwEaYSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbR2V0UG9saWN5VGFnXVtnb29nbGUuY2xvdWQu
ZGF0YWNhdGFsb2cudjEuUG9saWN5VGFnTWFuYWdlci5HZXRQb2xpY3lUYWddLgoKCwoDBA0B
EgTxAwgbCjwKBAQNAgASBvMDAvgDBBosIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRo
ZSBwb2xpY3kgdGFnLgoKDQoFBA0CAAUSBPMDAggKDQoFBA0CAAESBPMDCQ0KDQoFBA0CAAMS
BPMDEBEKDwoFBA0CAAgSBvMDEvgDAwoQCggEDQIACJwIABIE9AMEKgoRCgcEDQIACJ8IEgb1
AwT3AwViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy ===
    # Fields for Taxonomy
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: policy_tag_count Type: 5 ()
    # Field: taxonomy_timestamps Type: 11 (.google.cloud.datacatalog.v1.SystemTimestamps)
    # Field: activated_policy_types Type: 14 (.google.cloud.datacatalog.v1.Taxonomy.PolicyType)
    # Field: service Type: 11 (.google.cloud.datacatalog.v1.Taxonomy.Service)

# Enum: Taxonomy::PolicyType
our $Taxonomy_POLICY_TYPE_UNSPECIFIED = 0;
our $Taxonomy_FINE_GRAINED_ACCESS_CONTROL = 1;

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag ===
    # Fields for PolicyTag
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: parent_policy_tag Type: 9 ()
    # Field: child_policy_tags Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest ===
    # Fields for CreateTaxonomyRequest
    # Field: parent Type: 9 ()
    # Field: taxonomy Type: 11 (.google.cloud.datacatalog.v1.Taxonomy)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::DeleteTaxonomyRequest ===
    # Fields for DeleteTaxonomyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::UpdateTaxonomyRequest ===
    # Fields for UpdateTaxonomyRequest
    # Field: taxonomy Type: 11 (.google.cloud.datacatalog.v1.Taxonomy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesRequest ===
    # Fields for ListTaxonomiesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesResponse ===
    # Fields for ListTaxonomiesResponse
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1.Taxonomy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::GetTaxonomyRequest ===
    # Fields for GetTaxonomyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::CreatePolicyTagRequest ===
    # Fields for CreatePolicyTagRequest
    # Field: parent Type: 9 ()
    # Field: policy_tag Type: 11 (.google.cloud.datacatalog.v1.PolicyTag)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::DeletePolicyTagRequest ===
    # Fields for DeletePolicyTagRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::UpdatePolicyTagRequest ===
    # Fields for UpdatePolicyTagRequest
    # Field: policy_tag Type: 11 (.google.cloud.datacatalog.v1.PolicyTag)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsRequest ===
    # Fields for ListPolicyTagsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsResponse ===
    # Fields for ListPolicyTagsResponse
    # Field: policy_tags Type: 11 (.google.cloud.datacatalog.v1.PolicyTag)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::Policytagmanager::GetPolicyTagRequest ===
    # Fields for GetPolicyTagRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTagManagerClient ===
package Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTagManagerClient;

=pod

=head2 Service Client: Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTagManagerClient

Client stub representing the remote C<PolicyTagManager> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<datacatalog.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'datacatalog.googleapis.com:443' );

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

sub create_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'CreateTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy',
    });
}

sub delete_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::DeleteTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'DeleteTaxonomy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::UpdateTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'UpdateTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy',
    });
}

sub list_taxonomies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'ListTaxonomies',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesResponse',
    });
}

sub get_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::GetTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'GetTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy',
    });
}

sub create_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::CreatePolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'CreatePolicyTag',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag',
    });
}

sub delete_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::DeletePolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'DeletePolicyTag',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::UpdatePolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'UpdatePolicyTag',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag',
    });
}

sub list_policy_tags {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'ListPolicyTags',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsResponse',
    });
}

sub get_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1::Policytagmanager::GetPolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'GetPolicyTag',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1.PolicyTagManager',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Policytagmanager - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/policytagmanager.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Policytagmanager;

    my $msg = Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        policy_tag_count => $policy_tag_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/policytagmanager.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy

A taxonomy is a collection of hierarchical policy tags that classify data
along a common axis.

For example, a "data sensitivity" taxonomy might contain the following policy
tags:

```
+ PII
  + Account number
  + Age
  + SSN
  + Zipcode
+ Financials
  + Revenue
```

A "data origin" taxonomy might contain the following policy tags:

```
+ User data
+ Employee data
+ Partner data
+ Public data
```

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of this taxonomy in URL format.

Note: Policy tag manager generates unique taxonomy IDs.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. User-defined name of this taxonomy.

The name can't start or end with spaces, must contain only Unicode letters,
numbers, underscores, dashes, and spaces, and be at most 200 bytes long
when encoded in UTF-8.

The taxonomy display name must be unique within an organization.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of this taxonomy. If not set, defaults to empty.

The description must contain only Unicode characters, tabs, newlines,
carriage returns, and page breaks, and be at most 2000 bytes long when
encoded in UTF-8.

=item * C<< $msg->policy_tag_count() >> / C<< $msg->policy_tag_count($value) >>

Type: C<Int32>

Output only. Number of policy tags in this taxonomy.

=item * C<< $msg->taxonomy_timestamps() >> / C<< $msg->taxonomy_timestamps($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps>)

Output only. Creation and modification timestamps of this taxonomy.

=item * C<< $msg->activated_policy_types() >> / C<< $msg->activated_policy_types($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::Taxonomy::PolicyType>)

Optional. A list of policy types that are activated for this taxonomy. If
not set, defaults to an empty list.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy::Service>)

Output only. Identity of the service which owns the Taxonomy. This field is
only populated when the taxonomy is created by a Google Cloud service.
Currently only 'DATAPLEX' is supported.

=back

=head3 Enum: Taxonomy::PolicyType

=over 4

=item * C<POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<FINE_GRAINED_ACCESS_CONTROL> => C<1>

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag

Denotes one policy tag in a taxonomy, for example, SSN.

Policy tags can be defined in a hierarchy. For example:

```
+ Geolocation
  + LatLong
  + City
  + ZipCode
```

Where the "Geolocation" policy tag contains three children.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of this policy tag in the URL format.

The policy tag manager generates unique taxonomy IDs and policy tag IDs.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. User-defined name of this policy tag.

The name can't start or end with spaces and must be unique within the
parent taxonomy, contain only Unicode letters, numbers, underscores, dashes
and spaces, and be at most 200 bytes long when encoded in UTF-8.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of this policy tag. If not set, defaults to empty.

The description must contain only Unicode characters,
tabs, newlines, carriage returns and page breaks, and be at most 2000 bytes
long when encoded in UTF-8.

=item * C<< $msg->parent_policy_tag() >> / C<< $msg->parent_policy_tag($value) >>

Type: C<String>

Resource name of this policy tag's parent policy tag. If empty, this is a
top level tag. If not set, defaults to an empty string.

For example, for the "LatLong" policy tag in the example above, this field
contains the resource name of the "Geolocation" policy tag, and, for
"Geolocation", this field is empty.

=item * C<< $msg->child_policy_tags() >> / C<< $msg->child_policy_tags($value) >>

Type: C<String>

Output only. Resource names of child policy tags of this policy tag.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest

Request message for
[CreateTaxonomy][google.cloud.datacatalog.v1.PolicyTagManager.CreateTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the taxonomy will belong to.

=item * C<< $msg->taxonomy() >> / C<< $msg->taxonomy($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>)

The taxonomy to create.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::DeleteTaxonomyRequest

Request message for
[DeleteTaxonomy][google.cloud.datacatalog.v1.PolicyTagManager.DeleteTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the taxonomy to delete.

Note: All policy tags in this taxonomy are also deleted.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::UpdateTaxonomyRequest

Request message for
[UpdateTaxonomy][google.cloud.datacatalog.v1.PolicyTagManager.UpdateTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomy() >> / C<< $msg->taxonomy($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>)

The taxonomy to update. You can update only its description, display name,
and activated policy types.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Specifies fields to update. If not set, defaults to all fields you can
update.

For more information, see [FieldMask]
(https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask).

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesRequest

Request message for
[ListTaxonomies][google.cloud.datacatalog.v1.PolicyTagManager.ListTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project to list the taxonomies of.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return. Must be a value between 1 and 1000
inclusively. If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The pagination token of the next results page. If not set,
the first page is returned.

The token is returned in the response to a previous list request.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Supported field for filter is 'service' and value is 'dataplex'.
Eg: service=dataplex.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesResponse

Response message for
[ListTaxonomies][google.cloud.datacatalog.v1.PolicyTagManager.ListTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy>)

Taxonomies that the project contains.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token of the next results page. Empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::GetTaxonomyRequest

Request message for
[GetTaxonomy][google.cloud.datacatalog.v1.PolicyTagManager.GetTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the taxonomy to get.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::CreatePolicyTagRequest

Request message for
[CreatePolicyTag][google.cloud.datacatalog.v1.PolicyTagManager.CreatePolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the taxonomy that the policy tag will belong to.

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag>)

The policy tag to create.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::DeletePolicyTagRequest

Request message for
[DeletePolicyTag][google.cloud.datacatalog.v1.PolicyTagManager.DeletePolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the policy tag to delete.

Note: All of its descendant policy tags are also deleted.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::UpdatePolicyTagRequest

Request message for
[UpdatePolicyTag][google.cloud.datacatalog.v1.PolicyTagManager.UpdatePolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag>)

The policy tag to update. You can update only its description, display
name, and parent policy tag fields.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Specifies the fields to update.

You can update only display name, description, and parent policy tag.
If not set, defaults to all updatable fields.
For more information, see [FieldMask]
(https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask).

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsRequest

Request message for
[ListPolicyTags][google.cloud.datacatalog.v1.PolicyTagManager.ListPolicyTags].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the taxonomy to list the policy tags of.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return. Must be a value between 1 and 1000
inclusively.
If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The pagination token of the next results page. If not set, returns the
first page.

The token is returned in the response to a previous list request.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsResponse

Response message for
[ListPolicyTags][google.cloud.datacatalog.v1.PolicyTagManager.ListPolicyTags].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tags() >> / C<< $msg->policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag>)

The policy tags that belong to the taxonomy.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token of the next results page. Empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Datacatalog::V1::Policytagmanager::GetPolicyTagRequest

Request message for
[GetPolicyTag][google.cloud.datacatalog.v1.PolicyTagManager.GetPolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the policy tag.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Policytagmanager::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
