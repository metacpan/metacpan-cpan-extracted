package Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3::Page };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My90cmFuc2l0aW9uX3JvdXRlX2dyb3Vw
LnByb3RvEh1nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52MxocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9j
bG91ZC9kaWFsb2dmbG93L2N4L3YzL3BhZ2UucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0
eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i7gMKFFRyYW5zaXRp
b25Sb3V0ZUdyb3VwEhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJ
QgPgQQJSC2Rpc3BsYXlOYW1lElsKEXRyYW5zaXRpb25fcm91dGVzGAUgAygLMi4uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHJhbnNpdGlvblJvdXRlUhB0cmFuc2l0aW9uUm91
dGVzOrwC6kG4AgouZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9UcmFuc2l0aW9uUm91dGVH
cm91cBJycHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97
YWdlbnR9L2Zsb3dzL3tmbG93fS90cmFuc2l0aW9uUm91dGVHcm91cHMve3RyYW5zaXRpb25f
cm91dGVfZ3JvdXB9EmVwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
YWdlbnRzL3thZ2VudH0vdHJhbnNpdGlvblJvdXRlR3JvdXBzL3t0cmFuc2l0aW9uX3JvdXRl
X2dyb3VwfSoVdHJhbnNpdGlvblJvdXRlR3JvdXBzMhR0cmFuc2l0aW9uUm91dGVHcm91cCLT
AQogTGlzdFRyYW5zaXRpb25Sb3V0ZUdyb3Vwc1JlcXVlc3QSTgoGcGFyZW50GAEgASgJQjbg
QQL6QTASLmRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVHJhbnNpdGlvblJvdXRlR3JvdXBS
BnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyAB
KAlSCXBhZ2VUb2tlbhIjCg1sYW5ndWFnZV9jb2RlGAQgASgJUgxsYW5ndWFnZUNvZGUiuAEK
IUxpc3RUcmFuc2l0aW9uUm91dGVHcm91cHNSZXNwb25zZRJrChd0cmFuc2l0aW9uX3JvdXRl
X2dyb3VwcxgBIAMoCzIzLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRp
b25Sb3V0ZUdyb3VwUhV0cmFuc2l0aW9uUm91dGVHcm91cHMSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuIpEBCh5HZXRUcmFuc2l0aW9uUm91dGVHcm91cFJlcXVl
c3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Ry
YW5zaXRpb25Sb3V0ZUdyb3VwUgRuYW1lEiMKDWxhbmd1YWdlX2NvZGUYAiABKAlSDGxhbmd1
YWdlQ29kZSKIAgohQ3JlYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBSZXF1ZXN0Ek4KBnBhcmVu
dBgBIAEoCUI24EEC+kEwEi5kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1RyYW5zaXRpb25S
b3V0ZUdyb3VwUgZwYXJlbnQSbgoWdHJhbnNpdGlvbl9yb3V0ZV9ncm91cBgCIAEoCzIzLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3VwQgPgQQJS
FHRyYW5zaXRpb25Sb3V0ZUdyb3VwEiMKDWxhbmd1YWdlX2NvZGUYAyABKAlSDGxhbmd1YWdl
Q29kZSL1AQohVXBkYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBSZXF1ZXN0Em4KFnRyYW5zaXRp
b25fcm91dGVfZ3JvdXAYASABKAsyMy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5U
cmFuc2l0aW9uUm91dGVHcm91cEID4EECUhR0cmFuc2l0aW9uUm91dGVHcm91cBI7Cgt1cGRh
dGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sS
IwoNbGFuZ3VhZ2VfY29kZRgDIAEoCVIMbGFuZ3VhZ2VDb2RlIoUBCiFEZWxldGVUcmFuc2l0
aW9uUm91dGVHcm91cFJlcXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5kaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1RyYW5zaXRpb25Sb3V0ZUdyb3VwUgRuYW1lEhQKBWZvcmNlGAIg
ASgIUgVmb3JjZTLdDgoVVHJhbnNpdGlvblJvdXRlR3JvdXBzEsMCChlMaXN0VHJhbnNpdGlv
blJvdXRlR3JvdXBzEj8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuTGlzdFRyYW5z
aXRpb25Sb3V0ZUdyb3Vwc1JlcXVlc3QaQC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
My5MaXN0VHJhbnNpdGlvblJvdXRlR3JvdXBzUmVzcG9uc2UiogGC0+STApIBEkovdjMve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Zsb3dzLyp9L3RyYW5zaXRp
b25Sb3V0ZUdyb3Vwc1pEEkIvdjMve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Fn
ZW50cy8qfS90cmFuc2l0aW9uUm91dGVHcm91cHPaQQZwYXJlbnQSsAIKF0dldFRyYW5zaXRp
b25Sb3V0ZUdyb3VwEj0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2V0VHJhbnNp
dGlvblJvdXRlR3JvdXBSZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMu
VHJhbnNpdGlvblJvdXRlR3JvdXAioAGC0+STApIBEkovdjMve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9hZ2VudHMvKi9mbG93cy8qL3RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy8qfVpE
EkIvdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi90cmFuc2l0aW9u
Um91dGVHcm91cHMvKn3aQQRuYW1lEv8CChpDcmVhdGVUcmFuc2l0aW9uUm91dGVHcm91cBJA
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkNyZWF0ZVRyYW5zaXRpb25Sb3V0ZUdy
b3VwUmVxdWVzdBozLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25S
b3V0ZUdyb3VwIukBgtPkkwLCASJKL3YzL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9hZ2VudHMvKi9mbG93cy8qfS90cmFuc2l0aW9uUm91dGVHcm91cHM6FnRyYW5zaXRpb25f
cm91dGVfZ3JvdXBaXCJCL3YzL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2Vu
dHMvKn0vdHJhbnNpdGlvblJvdXRlR3JvdXBzOhZ0cmFuc2l0aW9uX3JvdXRlX2dyb3Vw2kEd
cGFyZW50LHRyYW5zaXRpb25fcm91dGVfZ3JvdXASsgMKGlVwZGF0ZVRyYW5zaXRpb25Sb3V0
ZUdyb3VwEkAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVXBkYXRlVHJhbnNpdGlv
blJvdXRlR3JvdXBSZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHJh
bnNpdGlvblJvdXRlR3JvdXAinAKC0+STAvABMmEvdjMve3RyYW5zaXRpb25fcm91dGVfZ3Jv
dXAubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Zsb3dzLyovdHJhbnNp
dGlvblJvdXRlR3JvdXBzLyp9OhZ0cmFuc2l0aW9uX3JvdXRlX2dyb3VwWnMyWS92My97dHJh
bnNpdGlvbl9yb3V0ZV9ncm91cC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRz
LyovdHJhbnNpdGlvblJvdXRlR3JvdXBzLyp9OhZ0cmFuc2l0aW9uX3JvdXRlX2dyb3Vw2kEi
dHJhbnNpdGlvbl9yb3V0ZV9ncm91cCx1cGRhdGVfbWFzaxKZAgoaRGVsZXRlVHJhbnNpdGlv
blJvdXRlR3JvdXASQC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5EZWxldGVUcmFu
c2l0aW9uUm91dGVHcm91cFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkioAGC0+ST
ApIBKkovdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9mbG93cy8q
L3RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy8qfVpEKkIvdjMve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9hZ2VudHMvKi90cmFuc2l0aW9uUm91dGVHcm91cHMvKn3aQQRuYW1lGnjKQRlk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rp
YWxvZ2Zsb3dCvAEKIWNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M0IZVHJhbnNp
dGlvblJvdXRlR3JvdXBQcm90b1ABWjFjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cv
Y3gvYXBpdjMvY3hwYjtjeHBiogICREaqAh1Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5W
M+oCIUdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6OkNYOjpWM0qXUAoHEgUOALsCAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJgoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADIKCQoCAwUSAxcAJQoJ
CgIDBhIDGAAqCggKAQgSAxoAOgoJCgIIJRIDGgA6CggKAQgSAxsASAoJCgIICxIDGwBICggK
AQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AOgoJCgIICBIDHQA6CggKAQgSAx4AOgoJCgII
ARIDHgA6CggKAQgSAx8AIAoJCgIIJBIDHwAgCggKAQgSAyAAOgoJCgIILRIDIAA6CnAKAgYA
EgQkAHoBGmQgU2VydmljZSBmb3IgbWFuYWdpbmcKIFtUcmFuc2l0aW9uUm91dGVHcm91cHNd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3VwXS4K
CgoKAwYAARIDJAgdCgoKAwYAAxIDJQJBCgwKBQYAA5kIEgMlAkEKCwoDBgADEgQmAigzCg0K
BQYAA5oIEgQmAigzClYKBAYAAgASBCsCNAMaSCBSZXR1cm5zIHRoZSBsaXN0IG9mIGFsbCB0
cmFuc2l0aW9uIHJvdXRlIGdyb3VwcyBpbiB0aGUgc3BlY2lmaWVkIGZsb3cuCgoMCgUGAAIA
ARIDKwYfCgwKBQYAAgACEgMrIEAKDAoFBgACAAMSAywPMAoNCgUGAAIABBIELQQyBgoRCgkG
AAIABLDKvCISBC0EMgYKDAoFBgACAAQSAzMENAoPCggGAAIABJsIABIDMwQ0CnQKBAYAAgES
BDgCQQMaZiBSZXRyaWV2ZXMgdGhlIHNwZWNpZmllZAogW1RyYW5zaXRpb25Sb3V0ZUdyb3Vw
XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5UcmFuc2l0aW9uUm91dGVHcm91cF0u
CgoMCgUGAAIBARIDOAYdCgwKBQYAAgECEgM4HjwKDAoFBgACAQMSAzkPIwoNCgUGAAIBBBIE
OgQ/BgoRCgkGAAIBBLDKvCISBDoEPwYKDAoFBgACAQQSA0AEMgoPCggGAAIBBJsIABIDQAQy
CqUCCgQGAAICEgRKAlUDGpYCIENyZWF0ZXMgYW4KIFtUcmFuc2l0aW9uUm91dGVHcm91cF1b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHJhbnNpdGlvblJvdXRlR3JvdXBdCiBp
biB0aGUgc3BlY2lmaWVkIGZsb3cuCgogTm90ZTogWW91IHNob3VsZCBhbHdheXMgdHJhaW4g
YSBmbG93IHByaW9yIHRvIHNlbmRpbmcgaXQgcXVlcmllcy4gU2VlIHRoZQogW3RyYWluaW5n
CiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9j
eC9kb2NzL2NvbmNlcHQvdHJhaW5pbmcpLgoKDAoFBgACAgESA0oGIAoMCgUGAAICAhIDSiFC
CgwKBQYAAgIDEgNLDyMKDQoFBgACAgQSBEwEUwYKEQoJBgACAgSwyrwiEgRMBFMGCgwKBQYA
AgIEEgNUBEsKDwoIBgACAgSbCAASA1QESwqZAgoEBgACAxIEXQJoAxqKAiBVcGRhdGVzIHRo
ZSBzcGVjaWZpZWQKIFtUcmFuc2l0aW9uUm91dGVHcm91cF1bZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjMuVHJhbnNpdGlvblJvdXRlR3JvdXBdLgoKIE5vdGU6IFlvdSBzaG91bGQg
YWx3YXlzIHRyYWluIGEgZmxvdyBwcmlvciB0byBzZW5kaW5nIGl0IHF1ZXJpZXMuIFNlZSB0
aGUKIFt0cmFpbmluZwogZG9jdW1lbnRhdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L2RpYWxvZ2Zsb3cvY3gvZG9jcy9jb25jZXB0L3RyYWluaW5nKS4KCgwKBQYAAgMBEgNdBiAK
DAoFBgACAwISA10hQgoMCgUGAAIDAxIDXg8jCg0KBQYAAgMEEgRfBGYGChEKCQYAAgMEsMq8
IhIEXwRmBgoMCgUGAAIDBBIDZwRQCg8KCAYAAgMEmwgAEgNnBFAKmQIKBAYAAgQSBHACeQMa
igIgRGVsZXRlcyB0aGUgc3BlY2lmaWVkCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3VwXS4KCiBOb3Rl
OiBZb3Ugc2hvdWxkIGFsd2F5cyB0cmFpbiBhIGZsb3cgcHJpb3IgdG8gc2VuZGluZyBpdCBx
dWVyaWVzLiBTZWUgdGhlCiBbdHJhaW5pbmcKIGRvY3VtZW50YXRpb25dKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2N4L2RvY3MvY29uY2VwdC90cmFpbmluZykuCgoM
CgUGAAIEARIDcAYgCgwKBQYAAgQCEgNwIUIKDAoFBgACBAMSA3EPJAoNCgUGAAIEBBIEcgR3
BgoRCgkGAAIEBLDKvCISBHIEdwYKDAoFBgACBAQSA3gEMgoPCggGAAIEBJsIABIDeAQyCr4B
CgIEABIFfwCWAQEasAEgQSBUcmFuc2l0aW9uUm91dGVHcm91cCByZXByZXNlbnRzIGEgZ3Jv
dXAgb2YKIFtgVHJhbnNpdGlvblJvdXRlc2BdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLlRyYW5zaXRpb25Sb3V0ZV0gdG8gYmUKIHVzZWQgYnkgYSBbUGFnZV1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuUGFnZV0uCgoKCgMEAAESA38IHAoNCgMEAAcSBoABAoYB
BAoPCgUEAAedCBIGgAEChgEECvUCCgQEAAIAEgSNAQISGuYCIFRoZSB1bmlxdWUgaWRlbnRp
ZmllciBvZiB0aGUgdHJhbnNpdGlvbiByb3V0ZSBncm91cC4KIFtUcmFuc2l0aW9uUm91dGVH
cm91cHMuQ3JlYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5DcmVhdGVUcmFuc2l0aW9uUm91dGVH
cm91cF0KIHBvcHVsYXRlcyB0aGUgbmFtZSBhdXRvbWF0aWNhbGx5LiBGb3JtYXQ6CiBgcHJv
amVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50
SUQ+L2Zsb3dzLzxGbG93SUQ+L3RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy88VHJhbnNpdGlvblJv
dXRlR3JvdXBJRD5gCiAuCgoNCgUEAAIABRIEjQECCAoNCgUEAAIAARIEjQEJDQoNCgUEAAIA
AxIEjQEQEQqgAQoEBAACARIEkQECQxqRASBSZXF1aXJlZC4gVGhlIGh1bWFuLXJlYWRhYmxl
IG5hbWUgb2YgdGhlIHRyYW5zaXRpb24gcm91dGUgZ3JvdXAsIHVuaXF1ZQogd2l0aGluIHRo
ZSBmbG93LiBUaGUgZGlzcGxheSBuYW1lIGNhbiBiZSBubyBsb25nZXIgdGhhbiAzMCBjaGFy
YWN0ZXJzLgoKDQoFBAACAQUSBJEBAggKDQoFBAACAQESBJEBCRUKDQoFBAACAQMSBJEBGBkK
DQoFBAACAQgSBJEBGkIKEAoIBAACAQicCAASBJEBG0EKggEKBAQAAgISBJUBAjEadCBUcmFu
c2l0aW9uIHJvdXRlcyBhc3NvY2lhdGVkIHdpdGggdGhlCiBbVHJhbnNpdGlvblJvdXRlR3Jv
dXBdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3Vw
XS4KCg0KBQQAAgIEEgSVAQIKCg0KBQQAAgIGEgSVAQsaCg0KBQQAAgIBEgSVARssCg0KBQQA
AgIDEgSVAS8wCqsBCgIEARIGmgEAugEBGpwBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
VHJhbnNpdGlvblJvdXRlR3JvdXBzLkxpc3RUcmFuc2l0aW9uUm91dGVHcm91cHNdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5MaXN0VHJh
bnNpdGlvblJvdXRlR3JvdXBzXS4KCgsKAwQBARIEmgEIKArqAQoEBAECABIGnwECpAEEGtkB
IFJlcXVpcmVkLiBUaGUgZmxvdyB0byBsaXN0IGFsbCB0cmFuc2l0aW9uIHJvdXRlIGdyb3Vw
cyBmb3IuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2Nh
dGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+YAogIG9yIGBwcm9qZWN0
cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4u
CgoNCgUEAQIABRIEnwECCAoNCgUEAQIAARIEnwEJDwoNCgUEAQIAAxIEnwESEwoPCgUEAQIA
CBIGnwEUpAEDChAKCAQBAgAInAgAEgSgAQQqChEKBwQBAgAInwgSBqEBBKMBBQppCgQEAQIB
EgSoAQIWGlsgVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNp
bmdsZSBwYWdlLiBCeSBkZWZhdWx0IDEwMCBhbmQKIGF0IG1vc3QgMTAwMC4KCg0KBQQBAgEF
EgSoAQIHCg0KBQQBAgEBEgSoAQgRCg0KBQQBAgEDEgSoARQVClAKBAQBAgISBKsBAhgaQiBU
aGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0
IHJlcXVlc3QuCgoNCgUEAQICBRIEqwECCAoNCgUEAQICARIEqwEJEwoNCgUEAQICAxIEqwEW
FwryAwoEBAECAxIEuQECGxrjAyBUaGUgbGFuZ3VhZ2UgdG8gbGlzdCB0cmFuc2l0aW9uIHJv
dXRlIGdyb3VwcyBmb3IuIFRoZSBmb2xsb3dpbmcgZmllbGRzIGFyZQogbGFuZ3VhZ2UgZGVw
ZW5kZW50OgoKICogIGBUcmFuc2l0aW9uUm91dGVHcm91cC50cmFuc2l0aW9uX3JvdXRlcy50
cmlnZ2VyX2Z1bGZpbGxtZW50Lm1lc3NhZ2VzYAogKgogYFRyYW5zaXRpb25Sb3V0ZUdyb3Vw
LnRyYW5zaXRpb25fcm91dGVzLnRyaWdnZXJfZnVsZmlsbG1lbnQuY29uZGl0aW9uYWxfY2Fz
ZXNgCgogSWYgbm90IHNwZWNpZmllZCwgdGhlIGFnZW50J3MgZGVmYXVsdCBsYW5ndWFnZSBp
cyB1c2VkLgogW01hbnkKIGxhbmd1YWdlc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2Rp
YWxvZ2Zsb3cvY3gvZG9jcy9yZWZlcmVuY2UvbGFuZ3VhZ2UpCiBhcmUgc3VwcG9ydGVkLgog
Tm90ZTogbGFuZ3VhZ2VzIG11c3QgYmUgZW5hYmxlZCBpbiB0aGUgYWdlbnQgYmVmb3JlIHRo
ZXkgY2FuIGJlIHVzZWQuCgoNCgUEAQIDBRIEuQECCAoNCgUEAQIDARIEuQEJFgoNCgUEAQID
AxIEuQEZGgqsAQoCBAISBr4BAMgBARqdASBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtU
cmFuc2l0aW9uUm91dGVHcm91cHMuTGlzdFRyYW5zaXRpb25Sb3V0ZUdyb3Vwc11bZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHJhbnNpdGlvblJvdXRlR3JvdXBzLkxpc3RUcmFu
c2l0aW9uUm91dGVHcm91cHNdLgoKCwoDBAIBEgS+AQgpCoQCCgQEAgIAEgTDAQI8GvUBIFRo
ZSBsaXN0IG9mIHRyYW5zaXRpb24gcm91dGUgZ3JvdXBzLiBUaGVyZSB3aWxsIGJlIGEgbWF4
aW11bSBudW1iZXIgb2YKIGl0ZW1zIHJldHVybmVkIGJhc2VkIG9uIHRoZSBwYWdlX3NpemUg
ZmllbGQgaW4gdGhlIHJlcXVlc3QuIFRoZSBsaXN0IG1heSBpbgogc29tZSBjYXNlcyBiZSBl
bXB0eSBvciBjb250YWluIGZld2VyIGVudHJpZXMgdGhhbiBwYWdlX3NpemUgZXZlbiBpZiB0
aGlzCiBpc24ndCB0aGUgbGFzdCBwYWdlLgoKDQoFBAICAAQSBMMBAgoKDQoFBAICAAYSBMMB
Cx8KDQoFBAICAAESBMMBIDcKDQoFBAICAAMSBMMBOjsKbwoEBAICARIExwECHRphIFRva2Vu
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhl
cmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAgIBBRIExwECCAoN
CgUEAgIBARIExwEJGAoNCgUEAgIBAxIExwEbHAqnAQoCBAMSBswBAOcBARqYASBUaGUgcmVx
dWVzdCBtZXNzYWdlIGZvcgogW1RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5HZXRUcmFuc2l0aW9u
Um91dGVHcm91cF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHJhbnNpdGlvblJv
dXRlR3JvdXBzLkdldFRyYW5zaXRpb25Sb3V0ZUdyb3VwXS4KCgsKAwQDARIEzAEIJgr0AgoE
BAMCABIG0wEC2AEEGuMCIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUKIFtUcmFuc2l0aW9u
Um91dGVHcm91cF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVHJhbnNpdGlvblJv
dXRlR3JvdXBdLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88
TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi90cmFuc2l0aW9u
Um91dGVHcm91cHMvPFRyYW5zaXRpb25Sb3V0ZUdyb3VwSUQ+YAogb3IKIGBwcm9qZWN0cy88
UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vdHJh
bnNpdGlvblJvdXRlR3JvdXBzLzxUcmFuc2l0aW9uUm91dGVHcm91cElEPmAuCgoNCgUEAwIA
BRIE0wECCAoNCgUEAwIAARIE0wEJDQoNCgUEAwIAAxIE0wEQEQoPCgUEAwIACBIG0wES2AED
ChAKCAQDAgAInAgAEgTUAQQqChEKBwQDAgAInwgSBtUBBNcBBQr5AwoEBAMCARIE5gECGxrq
AyBUaGUgbGFuZ3VhZ2UgdG8gcmV0cmlldmUgdGhlIHRyYW5zaXRpb24gcm91dGUgZ3JvdXAg
Zm9yLiBUaGUgZm9sbG93aW5nCiBmaWVsZHMgYXJlIGxhbmd1YWdlIGRlcGVuZGVudDoKCiAq
ICBgVHJhbnNpdGlvblJvdXRlR3JvdXAudHJhbnNpdGlvbl9yb3V0ZXMudHJpZ2dlcl9mdWxm
aWxsbWVudC5tZXNzYWdlc2AKICoKIGBUcmFuc2l0aW9uUm91dGVHcm91cC50cmFuc2l0aW9u
X3JvdXRlcy50cmlnZ2VyX2Z1bGZpbGxtZW50LmNvbmRpdGlvbmFsX2Nhc2VzYAoKIElmIG5v
dCBzcGVjaWZpZWQsIHRoZSBhZ2VudCdzIGRlZmF1bHQgbGFuZ3VhZ2UgaXMgdXNlZC4KIFtN
YW55CiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2N4
L2RvY3MvcmVmZXJlbmNlL2xhbmd1YWdlKQogYXJlIHN1cHBvcnRlZC4KIE5vdGU6IGxhbmd1
YWdlcyBtdXN0IGJlIGVuYWJsZWQgaW4gdGhlIGFnZW50IGJlZm9yZSB0aGV5IGNhbiBiZSB1
c2VkLgoKDQoFBAMCAQUSBOYBAggKDQoFBAMCAQESBOYBCRYKDQoFBAMCAQMSBOYBGRoKrQEK
AgQEEgbrAQCJAgEangEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtUcmFuc2l0aW9uUm91
dGVHcm91cHMuQ3JlYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5DcmVhdGVUcmFuc2l0aW9uUm91
dGVHcm91cF0uCgoLCgMEBAESBOsBCCkKtwIKBAQEAgASBvIBAvcBBBqmAiBSZXF1aXJlZC4g
VGhlIGZsb3cgdG8gY3JlYXRlIGFuCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3VwXQogZm9yLiBGb3Jt
YXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2Vu
dHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+YAogb3IgYHByb2plY3RzLzxQcm9qZWN0SUQ+
L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPmAKIGZvciBhZ2VudC1s
ZXZlbCBncm91cHMuCgoNCgUEBAIABRIE8gECCAoNCgUEBAIAARIE8gEJDwoNCgUEBAIAAxIE
8gESEwoPCgUEBAIACBIG8gEU9wEDChAKCAQEAgAInAgAEgTzAQQqChEKBwQEAgAInwgSBvQB
BPYBBQpBCgQEBAIBEgb6AQL7AS8aMSBSZXF1aXJlZC4gVGhlIHRyYW5zaXRpb24gcm91dGUg
Z3JvdXAgdG8gY3JlYXRlLgoKDQoFBAQCAQYSBPoBAhYKDQoFBAQCAQESBPoBFy0KDQoFBAQC
AQMSBPoBMDEKDQoFBAQCAQgSBPsBBi4KEAoIBAQCAQicCAASBPsBBy0K0gMKBAQEAgISBIgC
AhsawwMgVGhlIGxhbmd1YWdlIG9mIHRoZSBmb2xsb3dpbmcgZmllbGRzIGluIGBUcmFuc2l0
aW9uUm91dGVHcm91cGA6CgogKiAgYFRyYW5zaXRpb25Sb3V0ZUdyb3VwLnRyYW5zaXRpb25f
cm91dGVzLnRyaWdnZXJfZnVsZmlsbG1lbnQubWVzc2FnZXNgCiAqCiBgVHJhbnNpdGlvblJv
dXRlR3JvdXAudHJhbnNpdGlvbl9yb3V0ZXMudHJpZ2dlcl9mdWxmaWxsbWVudC5jb25kaXRp
b25hbF9jYXNlc2AKCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgYWdlbnQncyBkZWZhdWx0IGxh
bmd1YWdlIGlzIHVzZWQuCiBbTWFueQogbGFuZ3VhZ2VzXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL3JlZmVyZW5jZS9sYW5ndWFnZSkKIGFyZSBzdXBw
b3J0ZWQuCiBOb3RlOiBsYW5ndWFnZXMgbXVzdCBiZSBlbmFibGVkIGluIHRoZSBhZ2VudCBi
ZWZvcmUgdGhleSBjYW4gYmUgdXNlZC4KCg0KBQQEAgIFEgSIAgIICg0KBQQEAgIBEgSIAgkW
Cg0KBQQEAgIDEgSIAhkaCq0BCgIEBRIGjQIAoQIBGp4BIFRoZSByZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBzLlVwZGF0ZVRyYW5zaXRpb25Sb3V0ZUdyb3Vw
XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5UcmFuc2l0aW9uUm91dGVHcm91cHMu
VXBkYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBdLgoKCwoDBAUBEgSNAggpCkEKBAQFAgASBo8C
ApACLxoxIFJlcXVpcmVkLiBUaGUgdHJhbnNpdGlvbiByb3V0ZSBncm91cCB0byB1cGRhdGUu
CgoNCgUEBQIABhIEjwICFgoNCgUEBQIAARIEjwIXLQoNCgUEBQIAAxIEjwIwMQoNCgUEBQIA
CBIEkAIGLgoQCggEBQIACJwIABIEkAIHLQo9CgQEBQIBEgSTAgIsGi8gVGhlIG1hc2sgdG8g
Y29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBQIBBhIEkwICGwoNCgUE
BQIBARIEkwIcJwoNCgUEBQIBAxIEkwIqKwrSAwoEBAUCAhIEoAICGxrDAyBUaGUgbGFuZ3Vh
Z2Ugb2YgdGhlIGZvbGxvd2luZyBmaWVsZHMgaW4gYFRyYW5zaXRpb25Sb3V0ZUdyb3VwYDoK
CiAqICBgVHJhbnNpdGlvblJvdXRlR3JvdXAudHJhbnNpdGlvbl9yb3V0ZXMudHJpZ2dlcl9m
dWxmaWxsbWVudC5tZXNzYWdlc2AKICoKIGBUcmFuc2l0aW9uUm91dGVHcm91cC50cmFuc2l0
aW9uX3JvdXRlcy50cmlnZ2VyX2Z1bGZpbGxtZW50LmNvbmRpdGlvbmFsX2Nhc2VzYAoKIElm
IG5vdCBzcGVjaWZpZWQsIHRoZSBhZ2VudCdzIGRlZmF1bHQgbGFuZ3VhZ2UgaXMgdXNlZC4K
IFtNYW55CiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93
L2N4L2RvY3MvcmVmZXJlbmNlL2xhbmd1YWdlKQogYXJlIHN1cHBvcnRlZC4KIE5vdGU6IGxh
bmd1YWdlcyBtdXN0IGJlIGVuYWJsZWQgaW4gdGhlIGFnZW50IGJlZm9yZSB0aGV5IGNhbiBi
ZSB1c2VkLgoKDQoFBAUCAgUSBKACAggKDQoFBAUCAgESBKACCRYKDQoFBAUCAgMSBKACGRoK
rQEKAgQGEgalAgC7AgEangEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtUcmFuc2l0aW9u
Um91dGVHcm91cHMuRGVsZXRlVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5EZWxldGVUcmFuc2l0aW9u
Um91dGVHcm91cF0uCgoLCgMEBgESBKUCCCkK/gIKBAQGAgASBqwCArECBBrtAiBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzLlRyYW5zaXRpb25Sb3V0ZUdyb3VwXQogdG8gZGVsZXRlLiBG
b3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9h
Z2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+L3RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy88
VHJhbnNpdGlvblJvdXRlR3JvdXBJRD5gCiBvcgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi90cmFuc2l0aW9uUm91dGVH
cm91cHMvPFRyYW5zaXRpb25Sb3V0ZUdyb3VwSUQ+YC4KCg0KBQQGAgAFEgSsAgIICg0KBQQG
AgABEgSsAgkNCg0KBQQGAgADEgSsAhARCg8KBQQGAgAIEgasAhKxAgMKEAoIBAYCAAicCAAS
BK0CBCoKEQoHBAYCAAifCBIGrgIEsAIFCpMDCgQEBgIBEgS6AgIRGoQDIFRoaXMgZmllbGQg
aGFzIG5vIGVmZmVjdCBmb3IgdHJhbnNpdGlvbiByb3V0ZSBncm91cCB0aGF0IG5vIHBhZ2Ug
aXMgdXNpbmcuCiBJZiB0aGUgdHJhbnNpdGlvbiByb3V0ZSBncm91cCBpcyByZWZlcmVuY2Vk
IGJ5IGFueSBwYWdlOgoKICogIElmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLCBhbiBlcnJv
ciB3aWxsIGJlIHJldHVybmVkIHdpdGggbWVzc2FnZQogICAgaW5kaWNhdGluZyBwYWdlcyB0
aGF0IHJlZmVyZW5jZSB0aGUgdHJhbnNpdGlvbiByb3V0ZSBncm91cC4KICogIElmIGBmb3Jj
ZWAgaXMgc2V0IHRvIHRydWUsIERpYWxvZ2Zsb3cgd2lsbCByZW1vdmUgdGhlIHRyYW5zaXRp
b24gcm91dGUKICAgIGdyb3VwLCBhcyB3ZWxsIGFzIGFueSByZWZlcmVuY2UgdG8gaXQuCgoN
CgUEBgIBBRIEugICBgoNCgUEBgIBARIEugIHDAoNCgUEBgIBAxIEugIPEGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup ===
    # Fields for TransitionRouteGroup
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: transition_routes Type: 11 (.google.cloud.dialogflow.cx.v3.TransitionRoute)

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsRequest ===
    # Fields for ListTransitionRouteGroupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse ===
    # Fields for ListTransitionRouteGroupsResponse
    # Field: transition_route_groups Type: 11 (.google.cloud.dialogflow.cx.v3.TransitionRouteGroup)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::GetTransitionRouteGroupRequest ===
    # Fields for GetTransitionRouteGroupRequest
    # Field: name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::CreateTransitionRouteGroupRequest ===
    # Fields for CreateTransitionRouteGroupRequest
    # Field: parent Type: 9 ()
    # Field: transition_route_group Type: 11 (.google.cloud.dialogflow.cx.v3.TransitionRouteGroup)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::UpdateTransitionRouteGroupRequest ===
    # Fields for UpdateTransitionRouteGroupRequest
    # Field: transition_route_group Type: 11 (.google.cloud.dialogflow.cx.v3.TransitionRouteGroup)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::DeleteTransitionRouteGroupRequest ===
    # Fields for DeleteTransitionRouteGroupRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroupsClient ===
package Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroupsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroupsClient

Client stub representing the remote C<TransitionRouteGroups> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub list_transition_route_groups {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups',
        method         => 'ListTransitionRouteGroups',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse',
    });
}

sub get_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::GetTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups',
        method         => 'GetTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup',
    });
}

sub create_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::CreateTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups',
        method         => 'CreateTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup',
    });
}

sub update_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::UpdateTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups',
        method         => 'UpdateTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup',
    });
}

sub delete_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::DeleteTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.TransitionRouteGroups',
        method         => 'DeleteTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/transition_route_group.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup->new({
        name => $name,
        display_name => $display_name,
        transition_routes => $transition_routes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/transition_route_group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup

A TransitionRouteGroup represents a group of
[`TransitionRoutes`][google.cloud.dialogflow.cx.v3.TransitionRoute] to be
used by a [Page][google.cloud.dialogflow.cx.v3.Page].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the transition route group.
[TransitionRouteGroups.CreateTransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.CreateTransitionRouteGroup]
populates the name automatically. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/transitionRouteGroups/<TransitionRouteGroupID>`
.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the transition route group, unique
within the flow. The display name can be no longer than 30 characters.

=item * C<< $msg->transition_routes() >> / C<< $msg->transition_routes($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Page::TransitionRoute>)

Transition routes associated with the
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroup].

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsRequest

The request message for
[TransitionRouteGroups.ListTransitionRouteGroups][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.ListTransitionRouteGroups].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The flow to list all transition route groups for.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`
 or `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 100 and
at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list transition route groups for. The following fields are
language dependent:

*  `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages`
*
`TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`

If not specified, the agent's default language is used.
[Many
languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
are supported.
Note: languages must be enabled in the agent before they can be used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::ListTransitionRouteGroupsResponse

The response message for
[TransitionRouteGroups.ListTransitionRouteGroups][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.ListTransitionRouteGroups].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transition_route_groups() >> / C<< $msg->transition_route_groups($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup>)

The list of transition route groups. There will be a maximum number of
items returned based on the page_size field in the request. The list may in
some cases be empty or contain fewer entries than page_size even if this
isn't the last page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::GetTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.GetTransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.GetTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroup].
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/transitionRouteGroups/<TransitionRouteGroupID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/transitionRouteGroups/<TransitionRouteGroupID>`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to retrieve the transition route group for. The following
fields are language dependent:

*  `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages`
*
`TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`

If not specified, the agent's default language is used.
[Many
languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
are supported.
Note: languages must be enabled in the agent before they can be used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::CreateTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.CreateTransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.CreateTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The flow to create an
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroup]
for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`
or `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`
for agent-level groups.

=item * C<< $msg->transition_route_group() >> / C<< $msg->transition_route_group($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup>)

Required. The transition route group to create.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language of the following fields in `TransitionRouteGroup`:

*  `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages`
*
`TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`

If not specified, the agent's default language is used.
[Many
languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
are supported.
Note: languages must be enabled in the agent before they can be used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::UpdateTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.UpdateTransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.UpdateTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transition_route_group() >> / C<< $msg->transition_route_group($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::TransitionRouteGroup>)

Required. The transition route group to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The mask to control which fields get updated.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language of the following fields in `TransitionRouteGroup`:

*  `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages`
*
`TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`

If not specified, the agent's default language is used.
[Many
languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
are supported.
Note: languages must be enabled in the agent before they can be used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::DeleteTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.DeleteTransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroups.DeleteTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3.TransitionRouteGroup]
to delete. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/transitionRouteGroups/<TransitionRouteGroupID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/transitionRouteGroups/<TransitionRouteGroupID>`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

This field has no effect for transition route group that no page is using.
If the transition route group is referenced by any page:

*  If `force` is set to false, an error will be returned with message
   indicating pages that reference the transition route group.
*  If `force` is set to true, Dialogflow will remove the transition route
   group, as well as any reference to it.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
