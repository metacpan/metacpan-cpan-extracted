package Google::Cloud::Datacatalog::V1beta1::Policytagmanager;

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
    eval { require Google::Cloud::Datacatalog::V1beta1::Common };
    eval { require Google::Cloud::Datacatalog::V1beta1::Timestamps };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS9wb2xpY3l0YWdtYW5hZ2VyLnBy
b3RvEiBnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9j
bG91ZC9kYXRhY2F0YWxvZy92MWJldGExL2NvbW1vbi5wcm90bxoxZ29vZ2xlL2Nsb3VkL2Rh
dGFjYXRhbG9nL3YxYmV0YTEvdGltZXN0YW1wcy5wcm90bxoeZ29vZ2xlL2lhbS92MS9pYW1f
cG9saWN5LnByb3RvGhpnb29nbGUvaWFtL3YxL3BvbGljeS5wcm90bxobZ29vZ2xlL3Byb3Rv
YnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byLyBQoI
VGF4b25vbXkSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEo
CUID4EECUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgDIAEoCUID4EEBUgtkZXNjcmlw
dGlvbhItChBwb2xpY3lfdGFnX2NvdW50GAQgASgFQgPgQQNSDnBvbGljeVRhZ0NvdW50EmgK
E3RheG9ub215X3RpbWVzdGFtcHMYBSABKAsyMi5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cu
djFiZXRhMS5TeXN0ZW1UaW1lc3RhbXBzQgPgQQNSEnRheG9ub215VGltZXN0YW1wcxJwChZh
Y3RpdmF0ZWRfcG9saWN5X3R5cGVzGAYgAygOMjUuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9n
LnYxYmV0YTEuVGF4b25vbXkuUG9saWN5VHlwZUID4EEBUhRhY3RpdmF0ZWRQb2xpY3lUeXBl
cxJRCgdzZXJ2aWNlGAcgASgLMjIuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEu
VGF4b25vbXkuU2VydmljZUID4EEDUgdzZXJ2aWNlGmsKB1NlcnZpY2USRAoEbmFtZRgBIAEo
DjIwLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLk1hbmFnaW5nU3lzdGVtUgRu
YW1lEhoKCGlkZW50aXR5GAIgASgJUghpZGVudGl0eSJKCgpQb2xpY3lUeXBlEhsKF1BPTElD
WV9UWVBFX1VOU1BFQ0lGSUVEEAASHwobRklORV9HUkFJTkVEX0FDQ0VTU19DT05UUk9MEAE6
Z+pBZAojZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXkSPXByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90YXhvbm9taWVzL3t0YXhvbm9teX0izgIK
CVBvbGljeVRhZxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIg
ASgJQgPgQQJSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlv
bhIqChFwYXJlbnRfcG9saWN5X3RhZxgEIAEoCVIPcGFyZW50UG9saWN5VGFnEi8KEWNoaWxk
X3BvbGljeV90YWdzGAUgAygJQgPgQQNSD2NoaWxkUG9saWN5VGFnczqAAepBfQokZGF0YWNh
dGFsb2cuZ29vZ2xlYXBpcy5jb20vUG9saWN5VGFnElVwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vdGF4b25vbWllcy97dGF4b25vbXl9L3BvbGljeVRhZ3Mve3Bv
bGljeV90YWd9IqQBChVDcmVhdGVUYXhvbm9teVJlcXVlc3QSQwoGcGFyZW50GAEgASgJQivg
QQL6QSUSI2RhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29tL1RheG9ub215UgZwYXJlbnQSRgoI
dGF4b25vbXkYAiABKAsyKi5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5UYXhv
bm9teVIIdGF4b25vbXkiWAoVRGVsZXRlVGF4b25vbXlSZXF1ZXN0Ej8KBG5hbWUYASABKAlC
K+BBAvpBJQojZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlSBG5hbWUinAEK
FVVwZGF0ZVRheG9ub215UmVxdWVzdBJGCgh0YXhvbm9teRgBIAEoCzIqLmdvb2dsZS5jbG91
ZC5kYXRhY2F0YWxvZy52MWJldGExLlRheG9ub215Ugh0YXhvbm9teRI7Cgt1cGRhdGVfbWFz
axgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sisAEKFUxp
c3RUYXhvbm9taWVzUmVxdWVzdBJDCgZwYXJlbnQYASABKAlCK+BBAvpBJRIjZGF0YWNhdGFs
b2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVS
CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCAB
KAlSBmZpbHRlciKMAQoWTGlzdFRheG9ub21pZXNSZXNwb25zZRJKCgp0YXhvbm9taWVzGAEg
AygLMiouZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuVGF4b25vbXlSCnRheG9u
b21pZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlUKEkdldFRh
eG9ub215UmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUKI2RhdGFjYXRhbG9nLmdvb2ds
ZWFwaXMuY29tL1RheG9ub215UgRuYW1lIqoBChZDcmVhdGVQb2xpY3lUYWdSZXF1ZXN0EkQK
BnBhcmVudBgBIAEoCUIs4EEC+kEmEiRkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9Qb2xp
Y3lUYWdSBnBhcmVudBJKCgpwb2xpY3lfdGFnGAIgASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFj
YXRhbG9nLnYxYmV0YTEuUG9saWN5VGFnUglwb2xpY3lUYWciWgoWRGVsZXRlUG9saWN5VGFn
UmVxdWVzdBJACgRuYW1lGAEgASgJQizgQQL6QSYKJGRhdGFjYXRhbG9nLmdvb2dsZWFwaXMu
Y29tL1BvbGljeVRhZ1IEbmFtZSKhAQoWVXBkYXRlUG9saWN5VGFnUmVxdWVzdBJKCgpwb2xp
Y3lfdGFnGAEgASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuUG9saWN5
VGFnUglwb2xpY3lUYWcSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYu
RmllbGRNYXNrUgp1cGRhdGVNYXNrIpkBChVMaXN0UG9saWN5VGFnc1JlcXVlc3QSRAoGcGFy
ZW50GAEgASgJQizgQQL6QSYSJGRhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29tL1BvbGljeVRh
Z1IGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuIo4BChZMaXN0UG9saWN5VGFnc1Jlc3BvbnNlEkwKC3BvbGljeV90
YWdzGAEgAygLMisuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuUG9saWN5VGFn
Ugpwb2xpY3lUYWdzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJX
ChNHZXRQb2xpY3lUYWdSZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpBJgokZGF0YWNhdGFs
b2cuZ29vZ2xlYXBpcy5jb20vUG9saWN5VGFnUgRuYW1lMuUWChBQb2xpY3lUYWdNYW5hZ2Vy
Es4BCg5DcmVhdGVUYXhvbm9teRI3Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGEx
LkNyZWF0ZVRheG9ub215UmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJl
dGExLlRheG9ub215IleC0+STAj8iMy92MWJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKn0vdGF4b25vbWllczoIdGF4b25vbXnaQQ9wYXJlbnQsdGF4b25vbXkSpQEKDkRl
bGV0ZVRheG9ub215EjcuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuRGVsZXRl
VGF4b25vbXlSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkKC0+STAjUqMy92MWJl
dGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovdGF4b25vbWllcy8qfdpBBG5hbWUS
0AEKDlVwZGF0ZVRheG9ub215EjcuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEu
VXBkYXRlVGF4b25vbXlSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0
YTEuVGF4b25vbXkiWYLT5JMCSDI8L3YxYmV0YTEve3RheG9ub215Lm5hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi90YXhvbm9taWVzLyp9Ogh0YXhvbm9tedpBCHRheG9ub215EskBCg5M
aXN0VGF4b25vbWllcxI3Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLkxpc3RU
YXhvbm9taWVzUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLkxp
c3RUYXhvbm9taWVzUmVzcG9uc2UiRILT5JMCNRIzL3YxYmV0YTEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qfS90YXhvbm9taWVz2kEGcGFyZW50ErMBCgtHZXRUYXhvbm9teRI0
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLkdldFRheG9ub215UmVxdWVzdBoq
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlRheG9ub215IkKC0+STAjUSMy92
MWJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovdGF4b25vbWllcy8qfdpBBG5h
bWUS4gEKD0NyZWF0ZVBvbGljeVRhZxI4Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJl
dGExLkNyZWF0ZVBvbGljeVRhZ1JlcXVlc3QaKy5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cu
djFiZXRhMS5Qb2xpY3lUYWciaILT5JMCTiJAL3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL3RheG9ub21pZXMvKn0vcG9saWN5VGFnczoKcG9saWN5X3RhZ9pBEXBh
cmVudCxwb2xpY3lfdGFnErQBCg9EZWxldGVQb2xpY3lUYWcSOC5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjFiZXRhMS5EZWxldGVQb2xpY3lUYWdSZXF1ZXN0GhYuZ29vZ2xlLnByb3Rv
YnVmLkVtcHR5Ik+C0+STAkIqQC92MWJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovdGF4b25vbWllcy8qL3BvbGljeVRhZ3MvKn3aQQRuYW1lEuYBCg9VcGRhdGVQb2xpY3lU
YWcSOC5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5VcGRhdGVQb2xpY3lUYWdS
ZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuUG9saWN5VGFnImyC
0+STAlkySy92MWJldGExL3twb2xpY3lfdGFnLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki90YXhvbm9taWVzLyovcG9saWN5VGFncy8qfToKcG9saWN5X3RhZ9pBCnBvbGljeV90YWcS
1gEKDkxpc3RQb2xpY3lUYWdzEjcuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEu
TGlzdFBvbGljeVRhZ3NSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0
YTEuTGlzdFBvbGljeVRhZ3NSZXNwb25zZSJRgtPkkwJCEkAvdjFiZXRhMS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyovdGF4b25vbWllcy8qfS9wb2xpY3lUYWdz2kEGcGFyZW50
EsMBCgxHZXRQb2xpY3lUYWcSNS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5H
ZXRQb2xpY3lUYWdSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEu
UG9saWN5VGFnIk+C0+STAkISQC92MWJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovdGF4b25vbWllcy8qL3BvbGljeVRhZ3MvKn3aQQRuYW1lEvQBCgxHZXRJYW1Qb2xpY3kS
Ii5nb29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBv
bGljeSKoAYLT5JMCoQEiRC92MWJldGExL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3RheG9ub21pZXMvKn06Z2V0SWFtUG9saWN5OgEqWlYiUS92MWJldGExL3tyZXNvdXJj
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3RheG9ub21pZXMvKi9wb2xpY3lUYWdzLyp9Omdl
dElhbVBvbGljeToBKhL0AQoMU2V0SWFtUG9saWN5EiIuZ29vZ2xlLmlhbS52MS5TZXRJYW1Q
b2xpY3lSZXF1ZXN0GhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3kiqAGC0+STAqEBIkQvdjFiZXRh
MS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi90YXhvbm9taWVzLyp9OnNldElh
bVBvbGljeToBKlpWIlEvdjFiZXRhMS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki90YXhvbm9taWVzLyovcG9saWN5VGFncy8qfTpzZXRJYW1Qb2xpY3k6ASoSoAIKElRlc3RJ
YW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVxdWVz
dBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9uc2UitAGC0+STAq0B
IkovdjFiZXRhMS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi90YXhvbm9taWVz
Lyp9OnRlc3RJYW1QZXJtaXNzaW9uczoBKlpcIlcvdjFiZXRhMS97cmVzb3VyY2U9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi90YXhvbm9taWVzLyovcG9saWN5VGFncy8qfTp0ZXN0SWFtUGVy
bWlzc2lvbnM6ASoaTspBGmRhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULzAQokY29tLmdvb2dsZS5j
bG91ZC5kYXRhY2F0YWxvZy52MWJldGExQhVQb2xpY3lUYWdNYW5hZ2VyUHJvdG9QAVpGY2xv
dWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9hcGl2MWJldGExL2RhdGFjYXRhbG9ncGI7
ZGF0YWNhdGFsb2dwYqoCIEdvb2dsZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMUJldGExygIgR29v
Z2xlXENsb3VkXERhdGFDYXRhbG9nXFYxYmV0YTHqAiNHb29nbGU6OkNsb3VkOjpEYXRhQ2F0
YWxvZzo6VjFiZXRhMUqqbAoHEgUOAMMDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgID
AxIDFQAjCgkKAgMEEgMWADcKCQoCAwUSAxcAOwoJCgIDBhIDGAAoCgkKAgMHEgMZACQKCQoC
AwgSAxoAJQoJCgIDCRIDGwAqCggKAQgSAx0APQoJCgIIJRIDHQA9CggKAQgSAx4AXQoJCgII
CxIDHgBdCggKAQgSAx8AIgoJCgIIChIDHwAiCggKAQgSAyAANgoJCgIICBIDIAA2CggKAQgS
AyEAPQoJCgIIARIDIQA9CggKAQgSAyIAPQoJCgIIKRIDIgA9CggKAQgSAyMAPAoJCgIILRID
IwA8Cm0KAgYAEgUnAKkBARpgIFRoZSBwb2xpY3kgdGFnIG1hbmFnZXIgQVBJIHNlcnZpY2Ug
YWxsb3dzIGNsaWVudHMgdG8gbWFuYWdlIHRoZWlyIHRheG9ub21pZXMKIGFuZCBwb2xpY3kg
dGFncy4KCgoKAwYAARIDJwgYCgoKAwYAAxIDKAJCCgwKBQYAA5kIEgMoAkIKCwoDBgADEgQp
Aio3Cg0KBQYAA5oIEgQpAio3CjwKBAYAAgASBC0CMwMaLiBDcmVhdGVzIGEgdGF4b25vbXkg
aW4gdGhlIHNwZWNpZmllZCBwcm9qZWN0LgoKDAoFBgACAAESAy0GFAoMCgUGAAIAAhIDLRUq
CgwKBQYAAgADEgMtNT0KDQoFBgACAAQSBC4EMQYKEQoJBgACAASwyrwiEgQuBDEGCgwKBQYA
AgAEEgMyBD0KDwoIBgACAASbCAASAzIEPQqLAQoEBgACARIENwI8Axp9IERlbGV0ZXMgYSB0
YXhvbm9teS4gVGhpcyBvcGVyYXRpb24gd2lsbCBhbHNvIGRlbGV0ZSBhbGwKIHBvbGljeSB0
YWdzIGluIHRoaXMgdGF4b25vbXkgYWxvbmcgd2l0aCB0aGVpciBhc3NvY2lhdGVkIHBvbGlj
aWVzLgoKDAoFBgACAQESAzcGFAoMCgUGAAIBAhIDNxUqCgwKBQYAAgEDEgM3NUoKDQoFBgAC
AQQSBDgEOgYKEQoJBgACAQSwyrwiEgQ4BDoGCgwKBQYAAgEEEgM7BDIKDwoIBgACAQSbCAAS
AzsEMgojCgQGAAICEgQ/AkUDGhUgVXBkYXRlcyBhIHRheG9ub215LgoKDAoFBgACAgESAz8G
FAoMCgUGAAICAhIDPxUqCgwKBQYAAgIDEgM/NT0KDQoFBgACAgQSBEAEQwYKEQoJBgACAgSw
yrwiEgRABEMGCgwKBQYAAgIEEgNEBDYKDwoIBgACAgSbCAASA0QENgpzCgQGAAIDEgRJAk4D
GmUgTGlzdHMgYWxsIHRheG9ub21pZXMgaW4gYSBwcm9qZWN0IGluIGEgcGFydGljdWxhciBs
b2NhdGlvbiB0aGF0IHRoZSBjYWxsZXIKIGhhcyBwZXJtaXNzaW9uIHRvIHZpZXcuCgoMCgUG
AAIDARIDSQYUCgwKBQYAAgMCEgNJFSoKDAoFBgACAwMSA0k1SwoNCgUGAAIDBBIESgRMBgoR
CgkGAAIDBLDKvCISBEoETAYKDAoFBgACAwQSA00ENAoPCggGAAIDBJsIABIDTQQ0CiAKBAYA
AgQSBFECVgMaEiBHZXRzIGEgdGF4b25vbXkuCgoMCgUGAAIEARIDUQYRCgwKBQYAAgQCEgNR
EiQKDAoFBgACBAMSA1EvNwoNCgUGAAIEBBIEUgRUBgoRCgkGAAIEBLDKvCISBFIEVAYKDAoF
BgACBAQSA1UEMgoPCggGAAIEBJsIABIDVQQyCj8KBAYAAgUSBFkCXwMaMSBDcmVhdGVzIGEg
cG9saWN5IHRhZyBpbiB0aGUgc3BlY2lmaWVkIHRheG9ub215LgoKDAoFBgACBQESA1kGFQoM
CgUGAAIFAhIDWRYsCgwKBQYAAgUDEgNZN0AKDQoFBgACBQQSBFoEXQYKEQoJBgACBQSwyrwi
EgRaBF0GCgwKBQYAAgUEEgNeBD8KDwoIBgACBQSbCAASA14EPwpVCgQGAAIGEgRiAmcDGkcg
RGVsZXRlcyBhIHBvbGljeSB0YWcuIEFsc28gZGVsZXRlcyBhbGwgb2YgaXRzIGRlc2NlbmRh
bnQgcG9saWN5IHRhZ3MuCgoMCgUGAAIGARIDYgYVCgwKBQYAAgYCEgNiFiwKDAoFBgACBgMS
A2I3TAoNCgUGAAIGBBIEYwRlBgoRCgkGAAIGBLDKvCISBGMEZQYKDAoFBgACBgQSA2YEMgoP
CggGAAIGBJsIABIDZgQyCiUKBAYAAgcSBGoCcAMaFyBVcGRhdGVzIGEgcG9saWN5IHRhZy4K
CgwKBQYAAgcBEgNqBhUKDAoFBgACBwISA2oWLAoMCgUGAAIHAxIDajdACg0KBQYAAgcEEgRr
BG4GChEKCQYAAgcEsMq8IhIEawRuBgoMCgUGAAIHBBIDbwQ4Cg8KCAYAAgcEmwgAEgNvBDgK
NAoEBgACCBIEcwJ4AxomIExpc3RzIGFsbCBwb2xpY3kgdGFncyBpbiBhIHRheG9ub215LgoK
DAoFBgACCAESA3MGFAoMCgUGAAIIAhIDcxUqCgwKBQYAAggDEgNzNUsKDQoFBgACCAQSBHQE
dgYKEQoJBgACCASwyrwiEgR0BHYGCgwKBQYAAggEEgN3BDQKDwoIBgACCASbCAASA3cENAoj
CgQGAAIJEgV7AoABAxoUIEdldHMgYSBwb2xpY3kgdGFnLgoKDAoFBgACCQESA3sGEgoMCgUG
AAIJAhIDexMmCgwKBQYAAgkDEgN7MToKDQoFBgACCQQSBHwEfgYKEQoJBgACCQSwyrwiEgR8
BH4GCgwKBQYAAgkEEgN/BDIKDwoIBgACCQSbCAASA38EMgpFCgQGAAIKEgaDAQKNAQMaNSBH
ZXRzIHRoZSBJQU0gcG9saWN5IGZvciBhIHRheG9ub215IG9yIGEgcG9saWN5IHRhZy4KCg0K
BQYAAgoBEgSDAQYSCg0KBQYAAgoCEgSDARM0Cg0KBQYAAgoDEgSEAQ8jCg8KBQYAAgoEEgaF
AQSMAQYKEwoJBgACCgSwyrwiEgaFAQSMAQYKRQoEBgACCxIGkAECmgEDGjUgU2V0cyB0aGUg
SUFNIHBvbGljeSBmb3IgYSB0YXhvbm9teSBvciBhIHBvbGljeSB0YWcuCgoNCgUGAAILARIE
kAEGEgoNCgUGAAILAhIEkAETNAoNCgUGAAILAxIEkQEPIwoPCgUGAAILBBIGkgEEmQEGChMK
CQYAAgsEsMq8IhIGkgEEmQEGCmUKBAYAAgwSBp4BAqgBAxpVIFJldHVybnMgdGhlIHBlcm1p
c3Npb25zIHRoYXQgYSBjYWxsZXIgaGFzIG9uIHRoZSBzcGVjaWZpZWQgdGF4b25vbXkgb3IK
IHBvbGljeSB0YWcuCgoNCgUGAAIMARIEngEGGAoNCgUGAAIMAhIEngEZQAoNCgUGAAIMAxIE
nwEPNwoPCgUGAAIMBBIGoAEEpwEGChMKCQYAAgwEsMq8IhIGoAEEpwEGCs4CCgIEABIGsAEA
6wEBGr8CIEEgdGF4b25vbXkgaXMgYSBjb2xsZWN0aW9uIG9mIHBvbGljeSB0YWdzIHRoYXQg
Y2xhc3NpZnkgZGF0YSBhbG9uZyBhIGNvbW1vbgogYXhpcy4gRm9yIGluc3RhbmNlIGEgZGF0
YSAqc2Vuc2l0aXZpdHkqIHRheG9ub215IGNvdWxkIGNvbnRhaW4gcG9saWN5IHRhZ3MKIGRl
bm90aW5nIFBJSSBzdWNoIGFzIGFnZSwgemlwY29kZSwgYW5kIFNTTi4gQSBkYXRhICpvcmln
aW4qIHRheG9ub215IGNvdWxkCiBjb250YWluIHBvbGljeSB0YWdzIHRvIGRpc3Rpbmd1aXNo
IHVzZXIgZGF0YSwgZW1wbG95ZWUgZGF0YSwgcGFydG5lciBkYXRhLAogcHVibGljIGRhdGEu
CgoLCgMEAAESBLABCBAKDQoDBAAHEgaxAQK0AQQKDwoFBAAHnQgSBrEBArQBBApICgQEAAQA
Ega3AQK+AQMaOCBEZWZpbmVzIHBvbGljeSB0eXBlcyB3aGVyZSBwb2xpY3kgdGFnIGNhbiBi
ZSB1c2VkIGZvci4KCg0KBQQABAABEgS3AQcRCioKBgQABAACABIEuQEEIBoaIFVuc3BlY2lm
aWVkIHBvbGljeSB0eXBlLgoKDwoHBAAEAAIAARIEuQEEGwoPCgcEAAQAAgACEgS5AR4fCmgK
BgQABAACARIEvQEEJBpYIEZpbmUgZ3JhaW5lZCBhY2Nlc3MgY29udHJvbCBwb2xpY3ksIHdo
aWNoIGVuYWJsZXMgYWNjZXNzIGNvbnRyb2wgb24KIHRhZ2dlZCByZXNvdXJjZXMuCgoPCgcE
AAQAAgEBEgS9AQQfCg8KBwQABAACAQISBL0BIiMKNAoEBAADABIGwQECxwEDGiQgVGhlIHNv
dXJjZSBzeXN0ZW0gb2YgdGhlIFRheG9ub215LgoKDQoFBAADAAESBMEBChEKMAoGBAADAAIA
EgTDAQQcGiAgVGhlIEdvb2dsZSBDbG91ZCBzZXJ2aWNlIG5hbWUuCgoPCgcEAAMAAgAGEgTD
AQQSCg8KBwQAAwACAAESBMMBExcKDwoHBAADAAIAAxIEwwEaGwo0CgYEAAMAAgESBMYBBBga
JCBUaGUgc2VydmljZSBhZ2VudCBmb3IgdGhlIHNlcnZpY2UuCgoPCgcEAAMAAgEFEgTGAQQK
Cg8KBwQAAwACAQESBMYBCxMKDwoHBAADAAIBAxIExgEWFwqTAQoEBAACABIEywECPRqEASBJ
ZGVudGlmaWVyLiBSZXNvdXJjZSBuYW1lIG9mIHRoaXMgdGF4b25vbXksIHdob3NlIGZvcm1h
dCBpczoKICJwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25f
aWR9L3RheG9ub21pZXMve2lkfSIuCgoNCgUEAAIABRIEywECCAoNCgUEAAIAARIEywEJDQoN
CgUEAAIAAxIEywEQEQoNCgUEAAIACBIEywESPAoQCggEAAIACJwIABIEywETOwqmAgoEBAAC
ARIE0gECQxqXAiBSZXF1aXJlZC4gVXNlciBkZWZpbmVkIG5hbWUgb2YgdGhpcyB0YXhvbm9t
eS4gSXQgbXVzdDogY29udGFpbiBvbmx5IHVuaWNvZGUKIGxldHRlcnMsIG51bWJlcnMsIHVu
ZGVyc2NvcmVzLCBkYXNoZXMgYW5kIHNwYWNlczsgbm90IHN0YXJ0IG9yIGVuZCB3aXRoCiBz
cGFjZXM7IGFuZCBiZSBhdCBtb3N0IDIwMCBieXRlcyBsb25nIHdoZW4gZW5jb2RlZCBpbiBV
VEYtOC4KCiBUaGUgdGF4b25vbXkgZGlzcGxheSBuYW1lIG11c3QgYmUgdW5pcXVlIHdpdGhp
biBhbiBvcmdhbml6YXRpb24uCgoNCgUEAAIBBRIE0gECCAoNCgUEAAIBARIE0gEJFQoNCgUE
AAIBAxIE0gEYGQoNCgUEAAIBCBIE0gEaQgoQCggEAAIBCJwIABIE0gEbQQr7AQoEBAACAhIE
2AECQhrsASBPcHRpb25hbC4gRGVzY3JpcHRpb24gb2YgdGhpcyB0YXhvbm9teS4gSXQgbXVz
dDogY29udGFpbiBvbmx5IHVuaWNvZGUKIGNoYXJhY3RlcnMsIHRhYnMsIG5ld2xpbmVzLCBj
YXJyaWFnZSByZXR1cm5zIGFuZCBwYWdlIGJyZWFrczsgYW5kIGJlIGF0CiBtb3N0IDIwMDAg
Ynl0ZXMgbG9uZyB3aGVuIGVuY29kZWQgaW4gVVRGLTguIElmIG5vdCBzZXQsIGRlZmF1bHRz
IHRvIGFuCiBlbXB0eSBkZXNjcmlwdGlvbi4KCg0KBQQAAgIFEgTYAQIICg0KBQQAAgIBEgTY
AQkUCg0KBQQAAgIDEgTYARcYCg0KBQQAAgIIEgTYARlBChAKCAQAAgIInAgAEgTYARpACk4K
BAQAAgMSBNsBAkkaQCBPdXRwdXQgb25seS4gTnVtYmVyIG9mIHBvbGljeSB0YWdzIGNvbnRh
aW5lZCBpbiB0aGlzIHRheG9ub215LgoKDQoFBAACAwUSBNsBAgcKDQoFBAACAwESBNsBCBgK
DQoFBAACAwMSBNsBGxwKDQoFBAACAwgSBNsBHUgKEAoIBAACAwicCAASBNsBHkcKagoEBAAC
BBIG3wEC4AEyGlogT3V0cHV0IG9ubHkuIFRpbWVzdGFtcHMgYWJvdXQgdGhpcyB0YXhvbm9t
eS4gT25seSBjcmVhdGVfdGltZSBhbmQKIHVwZGF0ZV90aW1lIGFyZSB1c2VkLgoKDQoFBAAC
BAYSBN8BAhIKDQoFBAACBAESBN8BEyYKDQoFBAACBAMSBN8BKSoKDQoFBAACBAgSBOABBjEK
EAoIBAACBAicCAASBOABBzAKgAEKBAQAAgUSBuQBAuUBLxpwIE9wdGlvbmFsLiBBIGxpc3Qg
b2YgcG9saWN5IHR5cGVzIHRoYXQgYXJlIGFjdGl2YXRlZCBmb3IgdGhpcyB0YXhvbm9teS4g
SWYKIG5vdCBzZXQsIGRlZmF1bHRzIHRvIGFuIGVtcHR5IGxpc3QuCgoNCgUEAAIFBBIE5AEC
CgoNCgUEAAIFBhIE5AELFQoNCgUEAAIFARIE5AEWLAoNCgUEAAIFAxIE5AEvMAoNCgUEAAIF
CBIE5QEGLgoQCggEAAIFCJwIABIE5QEHLQrNAQoEBAACBhIE6gECQhq+ASBPdXRwdXQgb25s
eS4gSWRlbnRpdHkgb2YgdGhlIHNlcnZpY2Ugd2hpY2ggb3ducyB0aGUgVGF4b25vbXkuIFRo
aXMgZmllbGQgaXMKIG9ubHkgcG9wdWxhdGVkIHdoZW4gdGhlIHRheG9ub215IGlzIGNyZWF0
ZWQgYnkgYSBHb29nbGUgQ2xvdWQgc2VydmljZS4KIEN1cnJlbnRseSBvbmx5ICdEQVRBUExF
WCcgaXMgc3VwcG9ydGVkLgoKDQoFBAACBgYSBOoBAgkKDQoFBAACBgESBOoBChEKDQoFBAAC
BgMSBOoBFBUKDQoFBAACBggSBOoBFkEKEAoIBAACBgicCAASBOoBF0AKpgIKAgQBEgbxAQCS
AgEalwIgRGVub3RlcyBvbmUgcG9saWN5IHRhZyBpbiBhIHRheG9ub215IChlLmcuIHNzbiku
IFBvbGljeSBUYWdzIGNhbiBiZSBkZWZpbmVkCiBpbiBhIGhpZXJhcmNoeS4gRm9yIGV4YW1w
bGUsIGNvbnNpZGVyIHRoZSBmb2xsb3dpbmcgaGllcmFyY2h5OgogR2VvbG9jYXRpb24gLSZn
dDsgKExhdExvbmcsIENpdHksIFppcENvZGUpLiBQb2xpY3lUYWcgIkdlb2xvY2F0aW9uIgog
Y29udGFpbnMgdGhyZWUgY2hpbGQgcG9saWN5IHRhZ3M6ICJMYXRMb25nIiwgIkNpdHkiLCBh
bmQgIlppcENvZGUiLgoKCwoDBAEBEgTxAQgRCg0KAwQBBxIG8gEC9QEECg8KBQQBB50IEgby
AQL1AQQKrgEKBAQBAgASBPkBAj0anwEgSWRlbnRpZmllci4gUmVzb3VyY2UgbmFtZSBvZiB0
aGlzIHBvbGljeSB0YWcsIHdob3NlIGZvcm1hdCBpczoKICJwcm9qZWN0cy97cHJvamVjdF9u
dW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L3RheG9ub21pZXMve3RheG9ub215X2lk
fS9wb2xpY3lUYWdzL3tpZH0iLgoKDQoFBAECAAUSBPkBAggKDQoFBAECAAESBPkBCQ0KDQoF
BAECAAMSBPkBEBEKDQoFBAECAAgSBPkBEjwKEAoIBAECAAicCAASBPkBEzsKjAIKBAQBAgES
BP8BAkMa/QEgUmVxdWlyZWQuIFVzZXIgZGVmaW5lZCBuYW1lIG9mIHRoaXMgcG9saWN5IHRh
Zy4gSXQgbXVzdDogYmUgdW5pcXVlIHdpdGhpbgogdGhlIHBhcmVudCB0YXhvbm9teTsgY29u
dGFpbiBvbmx5IHVuaWNvZGUgbGV0dGVycywgbnVtYmVycywgdW5kZXJzY29yZXMsCiBkYXNo
ZXMgYW5kIHNwYWNlczsgbm90IHN0YXJ0IG9yIGVuZCB3aXRoIHNwYWNlczsgYW5kIGJlIGF0
IG1vc3QgMjAwIGJ5dGVzCiBsb25nIHdoZW4gZW5jb2RlZCBpbiBVVEYtOC4KCg0KBQQBAgEF
EgT/AQIICg0KBQQBAgEBEgT/AQkVCg0KBQQBAgEDEgT/ARgZCg0KBQQBAgEIEgT/ARpCChAK
CAQBAgEInAgAEgT/ARtBCqECCgQEAQICEgSFAgIZGpICIERlc2NyaXB0aW9uIG9mIHRoaXMg
cG9saWN5IHRhZy4gSXQgbXVzdDogY29udGFpbiBvbmx5IHVuaWNvZGUgY2hhcmFjdGVycywK
IHRhYnMsIG5ld2xpbmVzLCBjYXJyaWFnZSByZXR1cm5zIGFuZCBwYWdlIGJyZWFrczsgYW5k
IGJlIGF0IG1vc3QgMjAwMCBieXRlcwogbG9uZyB3aGVuIGVuY29kZWQgaW4gVVRGLTguIElm
IG5vdCBzZXQsIGRlZmF1bHRzIHRvIGFuIGVtcHR5IGRlc2NyaXB0aW9uLgogSWYgbm90IHNl
dCwgZGVmYXVsdHMgdG8gYW4gZW1wdHkgZGVzY3JpcHRpb24uCgoNCgUEAQICBRIEhQICCAoN
CgUEAQICARIEhQIJFAoNCgUEAQICAxIEhQIXGAqDAwoEBAECAxIEjQICHxr0AiBSZXNvdXJj
ZSBuYW1lIG9mIHRoaXMgcG9saWN5IHRhZydzIHBhcmVudCBwb2xpY3kgdGFnIChlLmcuIGZv
ciB0aGUKICJMYXRMb25nIiBwb2xpY3kgdGFnIGluIHRoZSBleGFtcGxlIGFib3ZlLCB0aGlz
IGZpZWxkIGNvbnRhaW5zIHRoZQogcmVzb3VyY2UgbmFtZSBvZiB0aGUgIkdlb2xvY2F0aW9u
IiBwb2xpY3kgdGFnKS4gSWYgZW1wdHksIGl0IG1lYW5zIHRoaXMKIHBvbGljeSB0YWcgaXMg
YSB0b3AgbGV2ZWwgcG9saWN5IHRhZyAoZS5nLiB0aGlzIGZpZWxkIGlzIGVtcHR5IGZvciB0
aGUKICJHZW9sb2NhdGlvbiIgcG9saWN5IHRhZyBpbiB0aGUgZXhhbXBsZSBhYm92ZSkuIElm
IG5vdCBzZXQsIGRlZmF1bHRzIHRvIGFuCiBlbXB0eSBzdHJpbmcuCgoNCgUEAQIDBRIEjQIC
CAoNCgUEAQIDARIEjQIJGgoNCgUEAQIDAxIEjQIdHgpWCgQEAQIEEgaQAgKRAjIaRiBPdXRw
dXQgb25seS4gUmVzb3VyY2UgbmFtZXMgb2YgY2hpbGQgcG9saWN5IHRhZ3Mgb2YgdGhpcyBw
b2xpY3kgdGFnLgoKDQoFBAECBAQSBJACAgoKDQoFBAECBAUSBJACCxEKDQoFBAECBAESBJAC
EiMKDQoFBAECBAMSBJACJicKDQoFBAECBAgSBJECBjEKEAoIBAECBAicCAASBJECBzAKeAoC
BAISBpYCAKECARpqIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDcmVhdGVUYXhvbm9teV1bZ29v
Z2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuUG9saWN5VGFnTWFuYWdlci5DcmVhdGVU
YXhvbm9teV0uCgoLCgMEAgESBJYCCB0KWgoEBAICABIGmAICnQIEGkogUmVxdWlyZWQuIFJl
c291cmNlIG5hbWUgb2YgdGhlIHByb2plY3QgdGhhdCB0aGUgdGF4b25vbXkgd2lsbCBiZWxv
bmcgdG8uCgoNCgUEAgIABRIEmAICCAoNCgUEAgIAARIEmAIJDwoNCgUEAgIAAxIEmAISEwoP
CgUEAgIACBIGmAIUnQIDChAKCAQCAgAInAgAEgSZAgQqChEKBwQCAgAInwgSBpoCBJwCBQor
CgQEAgIBEgSgAgIYGh0gVGhlIHRheG9ub215IHRvIGJlIGNyZWF0ZWQuCgoNCgUEAgIBBhIE
oAICCgoNCgUEAgIBARIEoAILEwoNCgUEAgIBAxIEoAIWFwp4CgIEAxIGpQIArgIBGmogUmVx
dWVzdCBtZXNzYWdlIGZvcgogW0RlbGV0ZVRheG9ub215XVtnb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFiZXRhMS5Qb2xpY3lUYWdNYW5hZ2VyLkRlbGV0ZVRheG9ub215XS4KCgsKAwQD
ARIEpQIIHQqAAQoEBAMCABIGqAICrQIEGnAgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2Yg
dGhlIHRheG9ub215IHRvIGJlIGRlbGV0ZWQuIEFsbCBwb2xpY3kgdGFncyBpbgogdGhpcyB0
YXhvbm9teSB3aWxsIGFsc28gYmUgZGVsZXRlZC4KCg0KBQQDAgAFEgSoAgIICg0KBQQDAgAB
EgSoAgkNCg0KBQQDAgADEgSoAhARCg8KBQQDAgAIEgaoAhKtAgMKEAoIBAMCAAicCAASBKkC
BCoKEQoHBAMCAAifCBIGqgIErAIFCngKAgQEEgayAgC8AgEaaiBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbVXBkYXRlVGF4b25vbXldW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGEx
LlBvbGljeVRhZ01hbmFnZXIuVXBkYXRlVGF4b25vbXldLgoKCwoDBAQBEgSyAggdCnMKBAQE
AgASBLUCAhgaZSBUaGUgdGF4b25vbXkgdG8gdXBkYXRlLiBPbmx5IGRlc2NyaXB0aW9uLCBk
aXNwbGF5X25hbWUsIGFuZCBhY3RpdmF0ZWQKIHBvbGljeSB0eXBlcyBjYW4gYmUgdXBkYXRl
ZC4KCg0KBQQEAgAGEgS1AgIKCg0KBQQEAgABEgS1AgsTCg0KBQQEAgADEgS1AhYXCv4BCgQE
BAIBEgS7AgIsGu8BIFRoZSB1cGRhdGUgbWFzayBhcHBsaWVzIHRvIHRoZSByZXNvdXJjZS4g
Rm9yIHRoZSBgRmllbGRNYXNrYCBkZWZpbml0aW9uLAogc2VlCiBodHRwczovL2RldmVsb3Bl
cnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5w
cm90b2J1ZiNmaWVsZG1hc2sKIElmIG5vdCBzZXQsIGRlZmF1bHRzIHRvIGFsbCBvZiB0aGUg
ZmllbGRzIHRoYXQgYXJlIGFsbG93ZWQgdG8gdXBkYXRlLgoKDQoFBAQCAQYSBLsCAhsKDQoF
BAQCAQESBLsCHCcKDQoFBAQCAQMSBLsCKisKeAoCBAUSBsACANQCARpqIFJlcXVlc3QgbWVz
c2FnZSBmb3IKIFtMaXN0VGF4b25vbWllc11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYx
YmV0YTEuUG9saWN5VGFnTWFuYWdlci5MaXN0VGF4b25vbWllc10uCgoLCgMEBQESBMACCB0K
UwoEBAUCABIGwgICxwIEGkMgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHByb2pl
Y3QgdG8gbGlzdCB0aGUgdGF4b25vbWllcyBvZi4KCg0KBQQFAgAFEgTCAgIICg0KBQQFAgAB
EgTCAgkPCg0KBQQFAgADEgTCAhITCg8KBQQFAgAIEgbCAhTHAgMKEAoIBAUCAAicCAASBMMC
BCoKEQoHBAUCAAifCBIGxAIExgIFCncKBAQFAgESBMsCAhYaaSBUaGUgbWF4aW11bSBudW1i
ZXIgb2YgaXRlbXMgdG8gcmV0dXJuLiBNdXN0IGJlIGEgdmFsdWUgYmV0d2VlbiAxIGFuZCAx
MDAwLgogSWYgbm90IHNldCwgZGVmYXVsdHMgdG8gNTAuCgoNCgUEBQIBBRIEywICBwoNCgUE
BQIBARIEywIIEQoNCgUEBQIBAxIEywIUFQqCAQoEBAUCAhIEzwICGBp0IFRoZSBuZXh0X3Bh
Z2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdCwg
aWYgYW55LiBJZgogbm90IHNldCwgZGVmYXVsdHMgdG8gYW4gZW1wdHkgc3RyaW5nLgoKDQoF
BAUCAgUSBM8CAggKDQoFBAUCAgESBM8CCRMKDQoFBAUCAgMSBM8CFhcKZwoEBAUCAxIE0wIC
FBpZIFN1cHBvcnRlZCBmaWVsZCBmb3IgZmlsdGVyIGlzICdzZXJ2aWNlJyBhbmQgdmFsdWUg
aXMgJ2RhdGFwbGV4Jy4KIEVnOiBzZXJ2aWNlPWRhdGFwbGV4LgoKDQoFBAUCAwUSBNMCAggK
DQoFBAUCAwESBNMCCQ8KDQoFBAUCAwMSBNMCEhMKeQoCBAYSBtgCAN8CARprIFJlc3BvbnNl
IG1lc3NhZ2UgZm9yCiBbTGlzdFRheG9ub21pZXNdW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxv
Zy52MWJldGExLlBvbGljeVRhZ01hbmFnZXIuTGlzdFRheG9ub21pZXNdLgoKCwoDBAYBEgTY
AggeCjUKBAQGAgASBNoCAiMaJyBUYXhvbm9taWVzIHRoYXQgdGhlIHByb2plY3QgY29udGFp
bnMuCgoNCgUEBgIABBIE2gICCgoNCgUEBgIABhIE2gILEwoNCgUEBgIAARIE2gIUHgoNCgUE
BgIAAxIE2gIhIgp0CgQEBgIBEgTeAgIdGmYgVG9rZW4gdXNlZCB0byByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSBy
ZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBAYCAQUSBN4CAggKDQoFBAYCAQESBN4CCRgKDQoF
BAYCAQMSBN4CGxwKcgoCBAcSBuMCAOsCARpkIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtHZXRU
YXhvbm9teV1bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuUG9saWN5VGFnTWFu
YWdlci5HZXRUYXhvbm9teV0uCgoLCgMEBwESBOMCCBoKRAoEBAcCABIG5QIC6gIEGjQgUmVx
dWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHJlcXVlc3RlZCB0YXhvbm9teS4KCg0KBQQH
AgAFEgTlAgIICg0KBQQHAgABEgTlAgkNCg0KBQQHAgADEgTlAhARCg8KBQQHAgAIEgblAhLq
AgMKEAoIBAcCAAicCAASBOYCBCoKEQoHBAcCAAifCBIG5wIE6QIFCnoKAgQIEgbvAgD6AgEa
bCBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ3JlYXRlUG9saWN5VGFnXVtnb29nbGUuY2xvdWQu
ZGF0YWNhdGFsb2cudjFiZXRhMS5Qb2xpY3lUYWdNYW5hZ2VyLkNyZWF0ZVBvbGljeVRhZ10u
CgoLCgMECAESBO8CCB4KXQoEBAgCABIG8QIC9gIEGk0gUmVxdWlyZWQuIFJlc291cmNlIG5h
bWUgb2YgdGhlIHRheG9ub215IHRoYXQgdGhlIHBvbGljeSB0YWcgd2lsbCBiZWxvbmcgdG8u
CgoNCgUECAIABRIE8QICCAoNCgUECAIAARIE8QIJDwoNCgUECAIAAxIE8QISEwoPCgUECAIA
CBIG8QIU9gIDChAKCAQIAgAInAgAEgTyAgQqChEKBwQIAgAInwgSBvMCBPUCBQotCgQECAIB
EgT5AgIbGh8gVGhlIHBvbGljeSB0YWcgdG8gYmUgY3JlYXRlZC4KCg0KBQQIAgEGEgT5AgIL
Cg0KBQQIAgEBEgT5AgwWCg0KBQQIAgEDEgT5AhkaCnoKAgQJEgb+AgCHAwEabCBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbRGVsZXRlUG9saWN5VGFnXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFs
b2cudjFiZXRhMS5Qb2xpY3lUYWdNYW5hZ2VyLkRlbGV0ZVBvbGljeVRhZ10uCgoLCgMECQES
BP4CCB4KgwEKBAQJAgASBoEDAoYDBBpzIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRo
ZSBwb2xpY3kgdGFnIHRvIGJlIGRlbGV0ZWQuIEFsbCBvZiBpdHMKIGRlc2NlbmRhbnQgcG9s
aWN5IHRhZ3Mgd2lsbCBhbHNvIGJlIGRlbGV0ZWQuCgoNCgUECQIABRIEgQMCCAoNCgUECQIA
ARIEgQMJDQoNCgUECQIAAxIEgQMQEQoPCgUECQIACBIGgQMShgMDChAKCAQJAgAInAgAEgSC
AwQqChEKBwQJAgAInwgSBoMDBIUDBQp6CgIEChIGiwMAmAMBGmwgUmVxdWVzdCBtZXNzYWdl
IGZvcgogW1VwZGF0ZVBvbGljeVRhZ11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0
YTEuUG9saWN5VGFnTWFuYWdlci5VcGRhdGVQb2xpY3lUYWddLgoKCwoDBAoBEgSLAwgeCnsK
BAQKAgASBI4DAhsabSBUaGUgcG9saWN5IHRhZyB0byB1cGRhdGUuIE9ubHkgdGhlIGRlc2Ny
aXB0aW9uLCBkaXNwbGF5X25hbWUsIGFuZAogcGFyZW50X3BvbGljeV90YWcgZmllbGRzIGNh
biBiZSB1cGRhdGVkLgoKDQoFBAoCAAYSBI4DAgsKDQoFBAoCAAESBI4DDBYKDQoFBAoCAAMS
BI4DGRoK9AMKBAQKAgESBJcDAiwa5QMgVGhlIHVwZGF0ZSBtYXNrIGFwcGxpZXMgdG8gdGhl
IHJlc291cmNlLiBPbmx5IGRpc3BsYXlfbmFtZSwgZGVzY3JpcHRpb24gYW5kCiBwYXJlbnRf
cG9saWN5X3RhZyBjYW4gYmUgdXBkYXRlZCBhbmQgdGh1cyBjYW4gYmUgbGlzdGVkIGluIHRo
ZSBtYXNrLiBJZgogdXBkYXRlX21hc2sgaXMgbm90IHByb3ZpZGVkLCBhbGwgYWxsb3dlZCBm
aWVsZHMgKGkuZS4gZGlzcGxheV9uYW1lLAogZGVzY3JpcHRpb24gYW5kIHBhcmVudCkgd2ls
bCBiZSB1cGRhdGVkLiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBpbmNsdWRpbmcgdGhlCiBgRmll
bGRNYXNrYCBkZWZpbml0aW9uLCBzZWUKIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29t
L3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9yZWZlcmVuY2UvZ29vZ2xlLnByb3RvYnVmI2ZpZWxk
bWFzawogSWYgbm90IHNldCwgZGVmYXVsdHMgdG8gYWxsIG9mIHRoZSBmaWVsZHMgdGhhdCBh
cmUgYWxsb3dlZCB0byB1cGRhdGUuCgoNCgUECgIBBhIElwMCGwoNCgUECgIBARIElwMcJwoN
CgUECgIBAxIElwMqKwp4CgIECxIGnAMArAMBGmogUmVxdWVzdCBtZXNzYWdlIGZvcgogW0xp
c3RQb2xpY3lUYWdzXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5Qb2xpY3lU
YWdNYW5hZ2VyLkxpc3RQb2xpY3lUYWdzXS4KCgsKAwQLARIEnAMIHQpVCgQECwIAEgaeAwKj
AwQaRSBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgdGF4b25vbXkgdG8gbGlzdCB0
aGUgcG9saWN5IHRhZ3Mgb2YuCgoNCgUECwIABRIEngMCCAoNCgUECwIAARIEngMJDwoNCgUE
CwIAAxIEngMSEwoPCgUECwIACBIGngMUowMDChAKCAQLAgAInAgAEgSfAwQqChEKBwQLAgAI
nwgSBqADBKIDBQp3CgQECwIBEgSnAwIWGmkgVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1z
IHRvIHJldHVybi4gTXVzdCBiZSBhIHZhbHVlIGJldHdlZW4gMSBhbmQgMTAwMC4KIElmIG5v
dCBzZXQsIGRlZmF1bHRzIHRvIDUwLgoKDQoFBAsCAQUSBKcDAgcKDQoFBAsCAQESBKcDCBEK
DQoFBAsCAQMSBKcDFBUKggEKBAQLAgISBKsDAhgadCBUaGUgbmV4dF9wYWdlX3Rva2VuIHZh
bHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBMaXN0IHJlcXVlc3QsIGlmIGFueS4gSWYK
IG5vdCBzZXQsIGRlZmF1bHRzIHRvIGFuIGVtcHR5IHN0cmluZy4KCg0KBQQLAgIFEgSrAwII
Cg0KBQQLAgIBEgSrAwkTCg0KBQQLAgIDEgSrAxYXCnkKAgQMEgawAwC3AwEaayBSZXNwb25z
ZSBtZXNzYWdlIGZvcgogW0xpc3RQb2xpY3lUYWdzXVtnb29nbGUuY2xvdWQuZGF0YWNhdGFs
b2cudjFiZXRhMS5Qb2xpY3lUYWdNYW5hZ2VyLkxpc3RQb2xpY3lUYWdzXS4KCgsKAwQMARIE
sAMIHgpDCgQEDAIAEgSyAwIlGjUgVGhlIHBvbGljeSB0YWdzIHRoYXQgYXJlIGluIHRoZSBy
ZXF1ZXN0ZWQgdGF4b25vbXkuCgoNCgUEDAIABBIEsgMCCgoNCgUEDAIABhIEsgMLFAoNCgUE
DAIAARIEsgMVIAoNCgUEDAIAAxIEsgMjJAp0CgQEDAIBEgS2AwIdGmYgVG9rZW4gdXNlZCB0
byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJl
IGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBAwCAQUSBLYDAggKDQoF
BAwCAQESBLYDCRgKDQoFBAwCAQMSBLYDGxwKdAoCBA0SBrsDAMMDARpmIFJlcXVlc3QgbWVz
c2FnZSBmb3IKIFtHZXRQb2xpY3lUYWddW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJl
dGExLlBvbGljeVRhZ01hbmFnZXIuR2V0UG9saWN5VGFnXS4KCgsKAwQNARIEuwMIGwpGCgQE
DQIAEga9AwLCAwQaNiBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVxdWVzdGVk
IHBvbGljeSB0YWcuCgoNCgUEDQIABRIEvQMCCAoNCgUEDQIAARIEvQMJDQoNCgUEDQIAAxIE
vQMQEQoPCgUEDQIACBIGvQMSwgMDChAKCAQNAgAInAgAEgS+AwQqChEKBwQNAgAInwgSBr8D
BMEDBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy ===
    # Fields for Taxonomy
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: policy_tag_count Type: 5 ()
    # Field: taxonomy_timestamps Type: 11 (.google.cloud.datacatalog.v1beta1.SystemTimestamps)
    # Field: activated_policy_types Type: 14 (.google.cloud.datacatalog.v1beta1.Taxonomy.PolicyType)
    # Field: service Type: 11 (.google.cloud.datacatalog.v1beta1.Taxonomy.Service)

# Enum: Taxonomy::PolicyType
our $Taxonomy_POLICY_TYPE_UNSPECIFIED = 0;
our $Taxonomy_FINE_GRAINED_ACCESS_CONTROL = 1;

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag ===
    # Fields for PolicyTag
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: parent_policy_tag Type: 9 ()
    # Field: child_policy_tags Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::CreateTaxonomyRequest ===
    # Fields for CreateTaxonomyRequest
    # Field: parent Type: 9 ()
    # Field: taxonomy Type: 11 (.google.cloud.datacatalog.v1beta1.Taxonomy)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::DeleteTaxonomyRequest ===
    # Fields for DeleteTaxonomyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::UpdateTaxonomyRequest ===
    # Fields for UpdateTaxonomyRequest
    # Field: taxonomy Type: 11 (.google.cloud.datacatalog.v1beta1.Taxonomy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListTaxonomiesRequest ===
    # Fields for ListTaxonomiesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListTaxonomiesResponse ===
    # Fields for ListTaxonomiesResponse
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1beta1.Taxonomy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::GetTaxonomyRequest ===
    # Fields for GetTaxonomyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::CreatePolicyTagRequest ===
    # Fields for CreatePolicyTagRequest
    # Field: parent Type: 9 ()
    # Field: policy_tag Type: 11 (.google.cloud.datacatalog.v1beta1.PolicyTag)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::DeletePolicyTagRequest ===
    # Fields for DeletePolicyTagRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::UpdatePolicyTagRequest ===
    # Fields for UpdatePolicyTagRequest
    # Field: policy_tag Type: 11 (.google.cloud.datacatalog.v1beta1.PolicyTag)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListPolicyTagsRequest ===
    # Fields for ListPolicyTagsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListPolicyTagsResponse ===
    # Fields for ListPolicyTagsResponse
    # Field: policy_tags Type: 11 (.google.cloud.datacatalog.v1beta1.PolicyTag)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::GetPolicyTagRequest ===
    # Fields for GetPolicyTagRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTagManagerClient ===
package Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTagManagerClient;

=pod

=head2 Service Client: Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTagManagerClient

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
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::CreateTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'CreateTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy',
    });
}

sub delete_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::DeleteTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'DeleteTaxonomy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::UpdateTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'UpdateTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy',
    });
}

sub list_taxonomies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListTaxonomiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'ListTaxonomies',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListTaxonomiesResponse',
    });
}

sub get_taxonomy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::GetTaxonomyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'GetTaxonomy',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy',
    });
}

sub create_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::CreatePolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'CreatePolicyTag',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag',
    });
}

sub delete_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::DeletePolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'DeletePolicyTag',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::UpdatePolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'UpdatePolicyTag',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag',
    });
}

sub list_policy_tags {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListPolicyTagsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'ListPolicyTags',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListPolicyTagsResponse',
    });
}

sub get_policy_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanager::GetPolicyTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'GetPolicyTag',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
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
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
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
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManager',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Policytagmanager - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/policytagmanager.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Policytagmanager;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        policy_tag_count => $policy_tag_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/policytagmanager.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy

A taxonomy is a collection of policy tags that classify data along a common
axis. For instance a data *sensitivity* taxonomy could contain policy tags
denoting PII such as age, zipcode, and SSN. A data *origin* taxonomy could
contain policy tags to distinguish user data, employee data, partner data,
public data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of this taxonomy, whose format is:
"projects/{project_number}/locations/{location_id}/taxonomies/{id}".

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. User defined name of this taxonomy. It must: contain only unicode
letters, numbers, underscores, dashes and spaces; not start or end with
spaces; and be at most 200 bytes long when encoded in UTF-8.

The taxonomy display name must be unique within an organization.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of this taxonomy. It must: contain only unicode
characters, tabs, newlines, carriage returns and page breaks; and be at
most 2000 bytes long when encoded in UTF-8. If not set, defaults to an
empty description.

=item * C<< $msg->policy_tag_count() >> / C<< $msg->policy_tag_count($value) >>

Type: C<Int32>

Output only. Number of policy tags contained in this taxonomy.

=item * C<< $msg->taxonomy_timestamps() >> / C<< $msg->taxonomy_timestamps($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Timestamps::SystemTimestamps>)

Output only. Timestamps about this taxonomy. Only create_time and
update_time are used.

=item * C<< $msg->activated_policy_types() >> / C<< $msg->activated_policy_types($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1beta1::Taxonomy::PolicyType>)

Optional. A list of policy types that are activated for this taxonomy. If
not set, defaults to an empty list.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy::Service>)

Output only. Identity of the service which owns the Taxonomy. This field is
only populated when the taxonomy is created by a Google Cloud service.
Currently only 'DATAPLEX' is supported.

=back

=head3 Enum: Taxonomy::PolicyType

=over 4

=item * C<POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<FINE_GRAINED_ACCESS_CONTROL> => C<1>

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag

Denotes one policy tag in a taxonomy (e.g. ssn). Policy Tags can be defined
in a hierarchy. For example, consider the following hierarchy:
Geolocation -&gt; (LatLong, City, ZipCode). PolicyTag "Geolocation"
contains three child policy tags: "LatLong", "City", and "ZipCode".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of this policy tag, whose format is:
"projects/{project_number}/locations/{location_id}/taxonomies/{taxonomy_id}/policyTags/{id}".

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. User defined name of this policy tag. It must: be unique within
the parent taxonomy; contain only unicode letters, numbers, underscores,
dashes and spaces; not start or end with spaces; and be at most 200 bytes
long when encoded in UTF-8.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of this policy tag. It must: contain only unicode characters,
tabs, newlines, carriage returns and page breaks; and be at most 2000 bytes
long when encoded in UTF-8. If not set, defaults to an empty description.
If not set, defaults to an empty description.

=item * C<< $msg->parent_policy_tag() >> / C<< $msg->parent_policy_tag($value) >>

Type: C<String>

Resource name of this policy tag's parent policy tag (e.g. for the
"LatLong" policy tag in the example above, this field contains the
resource name of the "Geolocation" policy tag). If empty, it means this
policy tag is a top level policy tag (e.g. this field is empty for the
"Geolocation" policy tag in the example above). If not set, defaults to an
empty string.

=item * C<< $msg->child_policy_tags() >> / C<< $msg->child_policy_tags($value) >>

Type: C<String>

Output only. Resource names of child policy tags of this policy tag.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::CreateTaxonomyRequest

Request message for
[CreateTaxonomy][google.cloud.datacatalog.v1beta1.PolicyTagManager.CreateTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the taxonomy will belong to.

=item * C<< $msg->taxonomy() >> / C<< $msg->taxonomy($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy>)

The taxonomy to be created.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::DeleteTaxonomyRequest

Request message for
[DeleteTaxonomy][google.cloud.datacatalog.v1beta1.PolicyTagManager.DeleteTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the taxonomy to be deleted. All policy tags in
this taxonomy will also be deleted.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::UpdateTaxonomyRequest

Request message for
[UpdateTaxonomy][google.cloud.datacatalog.v1beta1.PolicyTagManager.UpdateTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomy() >> / C<< $msg->taxonomy($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy>)

The taxonomy to update. Only description, display_name, and activated
policy types can be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
If not set, defaults to all of the fields that are allowed to update.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListTaxonomiesRequest

Request message for
[ListTaxonomies][google.cloud.datacatalog.v1beta1.PolicyTagManager.ListTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project to list the taxonomies of.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return. Must be a value between 1 and 1000.
If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any. If
not set, defaults to an empty string.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Supported field for filter is 'service' and value is 'dataplex'.
Eg: service=dataplex.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListTaxonomiesResponse

Response message for
[ListTaxonomies][google.cloud.datacatalog.v1beta1.PolicyTagManager.ListTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy>)

Taxonomies that the project contains.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token used to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::GetTaxonomyRequest

Request message for
[GetTaxonomy][google.cloud.datacatalog.v1beta1.PolicyTagManager.GetTaxonomy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the requested taxonomy.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::CreatePolicyTagRequest

Request message for
[CreatePolicyTag][google.cloud.datacatalog.v1beta1.PolicyTagManager.CreatePolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the taxonomy that the policy tag will belong to.

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag>)

The policy tag to be created.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::DeletePolicyTagRequest

Request message for
[DeletePolicyTag][google.cloud.datacatalog.v1beta1.PolicyTagManager.DeletePolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the policy tag to be deleted. All of its
descendant policy tags will also be deleted.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::UpdatePolicyTagRequest

Request message for
[UpdatePolicyTag][google.cloud.datacatalog.v1beta1.PolicyTagManager.UpdatePolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag>)

The policy tag to update. Only the description, display_name, and
parent_policy_tag fields can be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. Only display_name, description and
parent_policy_tag can be updated and thus can be listed in the mask. If
update_mask is not provided, all allowed fields (i.e. display_name,
description and parent) will be updated. For more information including the
`FieldMask` definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
If not set, defaults to all of the fields that are allowed to update.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListPolicyTagsRequest

Request message for
[ListPolicyTags][google.cloud.datacatalog.v1beta1.PolicyTagManager.ListPolicyTags].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the taxonomy to list the policy tags of.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return. Must be a value between 1 and 1000.
If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous List request, if any. If
not set, defaults to an empty string.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::ListPolicyTagsResponse

Response message for
[ListPolicyTags][google.cloud.datacatalog.v1beta1.PolicyTagManager.ListPolicyTags].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tags() >> / C<< $msg->policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::PolicyTag>)

The policy tags that are in the requested taxonomy.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token used to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanager::GetPolicyTagRequest

Request message for
[GetPolicyTag][google.cloud.datacatalog.v1beta1.PolicyTagManager.GetPolicyTag].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the requested policy tag.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
