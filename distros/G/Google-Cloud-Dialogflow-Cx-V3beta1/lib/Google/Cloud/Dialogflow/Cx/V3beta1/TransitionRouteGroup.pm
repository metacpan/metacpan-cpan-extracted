package Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Page };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3RyYW5zaXRpb25fcm91dGVf
Z3JvdXAucHJvdG8SImdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gi1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3BhZ2UucHJvdG8aG2dvb2ds
ZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJv
dG8i8wMKFFRyYW5zaXRpb25Sb3V0ZUdyb3VwEhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlz
cGxheV9uYW1lGAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lEmAKEXRyYW5zaXRpb25fcm91dGVz
GAUgAygLMjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9u
Um91dGVSEHRyYW5zaXRpb25Sb3V0ZXM6vALqQbgCCi5kaWFsb2dmbG93Lmdvb2dsZWFwaXMu
Y29tL1RyYW5zaXRpb25Sb3V0ZUdyb3VwEnJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0vZmxvd3Mve2Zsb3d9L3RyYW5zaXRpb25Sb3V0
ZUdyb3Vwcy97dHJhbnNpdGlvbl9yb3V0ZV9ncm91cH0SZXByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9hZ2VudHMve2FnZW50fS90cmFuc2l0aW9uUm91dGVHcm91
cHMve3RyYW5zaXRpb25fcm91dGVfZ3JvdXB9KhV0cmFuc2l0aW9uUm91dGVHcm91cHMyFHRy
YW5zaXRpb25Sb3V0ZUdyb3VwItMBCiBMaXN0VHJhbnNpdGlvblJvdXRlR3JvdXBzUmVxdWVz
dBJOCgZwYXJlbnQYASABKAlCNuBBAvpBMBIuZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9U
cmFuc2l0aW9uUm91dGVHcm91cFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNp
emUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEiMKDWxhbmd1YWdlX2NvZGUYBCAB
KAlSDGxhbmd1YWdlQ29kZSK9AQohTGlzdFRyYW5zaXRpb25Sb3V0ZUdyb3Vwc1Jlc3BvbnNl
EnAKF3RyYW5zaXRpb25fcm91dGVfZ3JvdXBzGAEgAygLMjguZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVHcm91cFIVdHJhbnNpdGlvblJvdXRl
R3JvdXBzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKRAQoeR2V0
VHJhbnNpdGlvblJvdXRlR3JvdXBSZXF1ZXN0EkoKBG5hbWUYASABKAlCNuBBAvpBMAouZGlh
bG9nZmxvdy5nb29nbGVhcGlzLmNvbS9UcmFuc2l0aW9uUm91dGVHcm91cFIEbmFtZRIjCg1s
YW5ndWFnZV9jb2RlGAIgASgJUgxsYW5ndWFnZUNvZGUijQIKIUNyZWF0ZVRyYW5zaXRpb25S
b3V0ZUdyb3VwUmVxdWVzdBJOCgZwYXJlbnQYASABKAlCNuBBAvpBMBIuZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9UcmFuc2l0aW9uUm91dGVHcm91cFIGcGFyZW50EnMKFnRyYW5zaXRp
b25fcm91dGVfZ3JvdXAYAiABKAsyOC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLlRyYW5zaXRpb25Sb3V0ZUdyb3VwQgPgQQJSFHRyYW5zaXRpb25Sb3V0ZUdyb3VwEiMK
DWxhbmd1YWdlX2NvZGUYAyABKAlSDGxhbmd1YWdlQ29kZSL6AQohVXBkYXRlVHJhbnNpdGlv
blJvdXRlR3JvdXBSZXF1ZXN0EnMKFnRyYW5zaXRpb25fcm91dGVfZ3JvdXAYASABKAsyOC5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlRyYW5zaXRpb25Sb3V0ZUdyb3Vw
QgPgQQJSFHRyYW5zaXRpb25Sb3V0ZUdyb3VwEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzaxIjCg1sYW5ndWFnZV9jb2RlGAMg
ASgJUgxsYW5ndWFnZUNvZGUihQEKIURlbGV0ZVRyYW5zaXRpb25Sb3V0ZUdyb3VwUmVxdWVz
dBJKCgRuYW1lGAEgASgJQjbgQQL6QTAKLmRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVHJh
bnNpdGlvblJvdXRlR3JvdXBSBG5hbWUSFAoFZm9yY2UYAiABKAhSBWZvcmNlMrwPChVUcmFu
c2l0aW9uUm91dGVHcm91cHMS1wIKGUxpc3RUcmFuc2l0aW9uUm91dGVHcm91cHMSRC5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkxpc3RUcmFuc2l0aW9uUm91dGVHcm91
cHNSZXF1ZXN0GkUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5MaXN0VHJh
bnNpdGlvblJvdXRlR3JvdXBzUmVzcG9uc2UirAGC0+STApwBEk8vdjNiZXRhMS97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3MvKn0vdHJhbnNpdGlvblJv
dXRlR3JvdXBzWkkSRy92M2JldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9h
Z2VudHMvKn0vdHJhbnNpdGlvblJvdXRlR3JvdXBz2kEGcGFyZW50EsQCChdHZXRUcmFuc2l0
aW9uUm91dGVHcm91cBJCLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2V0
VHJhbnNpdGlvblJvdXRlR3JvdXBSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVHcm91cCKqAYLT5JMCnAESTy92M2JldGExL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3MvKi90cmFuc2l0aW9u
Um91dGVHcm91cHMvKn1aSRJHL3YzYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9hZ2VudHMvKi90cmFuc2l0aW9uUm91dGVHcm91cHMvKn3aQQRuYW1lEpMDChpDcmVhdGVU
cmFuc2l0aW9uUm91dGVHcm91cBJFLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0
YTEuQ3JlYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVHcm91cCLzAYLT5JMCzAEiTy92
M2JldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9mbG93cy8q
fS90cmFuc2l0aW9uUm91dGVHcm91cHM6FnRyYW5zaXRpb25fcm91dGVfZ3JvdXBaYSJHL3Yz
YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qfS90cmFuc2l0
aW9uUm91dGVHcm91cHM6FnRyYW5zaXRpb25fcm91dGVfZ3JvdXDaQR1wYXJlbnQsdHJhbnNp
dGlvbl9yb3V0ZV9ncm91cBLGAwoaVXBkYXRlVHJhbnNpdGlvblJvdXRlR3JvdXASRS5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlVwZGF0ZVRyYW5zaXRpb25Sb3V0ZUdy
b3VwUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNp
dGlvblJvdXRlR3JvdXAipgKC0+STAvoBMmYvdjNiZXRhMS97dHJhbnNpdGlvbl9yb3V0ZV9n
cm91cC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3MvKi90cmFu
c2l0aW9uUm91dGVHcm91cHMvKn06FnRyYW5zaXRpb25fcm91dGVfZ3JvdXBaeDJeL3YzYmV0
YTEve3RyYW5zaXRpb25fcm91dGVfZ3JvdXAubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2FnZW50cy8qL3RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy8qfToWdHJhbnNpdGlvbl9yb3V0ZV9n
cm91cNpBInRyYW5zaXRpb25fcm91dGVfZ3JvdXAsdXBkYXRlX21hc2sSqAIKGkRlbGV0ZVRy
YW5zaXRpb25Sb3V0ZUdyb3VwEkUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRh
MS5EZWxldGVUcmFuc2l0aW9uUm91dGVHcm91cFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHkiqgGC0+STApwBKk8vdjNiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2FnZW50cy8qL2Zsb3dzLyovdHJhbnNpdGlvblJvdXRlR3JvdXBzLyp9WkkqRy92M2JldGEx
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovdHJhbnNpdGlvblJvdXRl
R3JvdXBzLyp92kEEbmFtZRp4ykEZZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9kaWFsb2dmbG93QtABCiZjb20uZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMUIZVHJhbnNpdGlvblJvdXRlR3JvdXBQcm90b1ABWjZjbG91
ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvY3gvYXBpdjNiZXRhMS9jeHBiO2N4cGKiAgJE
RqoCIkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LkN4LlYzQmV0YTHqAiZHb29nbGU6OkNsb3Vk
OjpEaWFsb2dmbG93OjpDWDo6VjNiZXRhMUr6UQoHEgUOAL0CAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADcKCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggK
AQgSAxoAPwoJCgIIJRIDGgA/CggKAQgSAxsATQoJCgIICxIDGwBNCggKAQgSAxwAIgoJCgII
ChIDHAAiCggKAQgSAx0AOgoJCgIICBIDHQA6CggKAQgSAx4APwoJCgIIARIDHgA/CggKAQgS
Ax8AIAoJCgIIJBIDHwAgCggKAQgSAyAAPwoJCgIILRIDIAA/CnUKAgYAEgQkAHoBGmkgU2Vy
dmljZSBmb3IgbWFuYWdpbmcKIFtUcmFuc2l0aW9uUm91dGVHcm91cHNdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJvdXRlR3JvdXBdLgoKCgoDBgAB
EgMkCB0KCgoDBgADEgMlAkEKDAoFBgADmQgSAyUCQQoLCgMGAAMSBCYCKDMKDQoFBgADmggS
BCYCKDMKVgoEBgACABIEKwI0AxpIIFJldHVybnMgdGhlIGxpc3Qgb2YgYWxsIHRyYW5zaXRp
b24gcm91dGUgZ3JvdXBzIGluIHRoZSBzcGVjaWZpZWQgZmxvdy4KCgwKBQYAAgABEgMrBh8K
DAoFBgACAAISAysgQAoMCgUGAAIAAxIDLA8wCg0KBQYAAgAEEgQtBDIGChEKCQYAAgAEsMq8
IhIELQQyBgoMCgUGAAIABBIDMwQ0Cg8KCAYAAgAEmwgAEgMzBDQKeQoEBgACARIEOAJBAxpr
IFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJvdXRlR3JvdXBdLgoK
DAoFBgACAQESAzgGHQoMCgUGAAIBAhIDOB48CgwKBQYAAgEDEgM5DyMKDQoFBgACAQQSBDoE
PwYKEQoJBgACAQSwyrwiEgQ6BD8GCgwKBQYAAgEEEgNABDIKDwoIBgACAQSbCAASA0AEMgqq
AgoEBgACAhIESgJVAxqbAiBDcmVhdGVzIGFuCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJvdXRlR3JvdXBd
CiBpbiB0aGUgc3BlY2lmaWVkIGZsb3cuCgogTm90ZTogWW91IHNob3VsZCBhbHdheXMgdHJh
aW4gYSBmbG93IHByaW9yIHRvIHNlbmRpbmcgaXQgcXVlcmllcy4gU2VlIHRoZQogW3RyYWlu
aW5nCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxv
dy9jeC9kb2NzL2NvbmNlcHQvdHJhaW5pbmcpLgoKDAoFBgACAgESA0oGIAoMCgUGAAICAhID
SiFCCgwKBQYAAgIDEgNLDyMKDQoFBgACAgQSBEwEUwYKEQoJBgACAgSwyrwiEgRMBFMGCgwK
BQYAAgIEEgNUBEsKDwoIBgACAgSbCAASA1QESwqeAgoEBgACAxIEXQJoAxqPAiBVcGRhdGVz
IHRoZSBzcGVjaWZpZWQKIFtUcmFuc2l0aW9uUm91dGVHcm91cF1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVHcm91cF0uCgogTm90ZTogWW91
IHNob3VsZCBhbHdheXMgdHJhaW4gYSBmbG93IHByaW9yIHRvIHNlbmRpbmcgaXQgcXVlcmll
cy4gU2VlIHRoZQogW3RyYWluaW5nCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvdHJhaW5pbmcpLgoKDAoFBgAC
AwESA10GIAoMCgUGAAIDAhIDXSFCCgwKBQYAAgMDEgNeDyMKDQoFBgACAwQSBF8EZgYKEQoJ
BgACAwSwyrwiEgRfBGYGCgwKBQYAAgMEEgNnBFAKDwoIBgACAwSbCAASA2cEUAqeAgoEBgAC
BBIEcAJ5AxqPAiBEZWxldGVzIHRoZSBzcGVjaWZpZWQKIFtUcmFuc2l0aW9uUm91dGVHcm91
cF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVH
cm91cF0uCgogTm90ZTogWW91IHNob3VsZCBhbHdheXMgdHJhaW4gYSBmbG93IHByaW9yIHRv
IHNlbmRpbmcgaXQgcXVlcmllcy4gU2VlIHRoZQogW3RyYWluaW5nCiBkb2N1bWVudGF0aW9u
XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQv
dHJhaW5pbmcpLgoKDAoFBgACBAESA3AGIAoMCgUGAAIEAhIDcCFCCgwKBQYAAgQDEgNxDyQK
DQoFBgACBAQSBHIEdwYKEQoJBgACBASwyrwiEgRyBHcGCgwKBQYAAgQEEgN4BDIKDwoIBgAC
BASbCAASA3gEMgrIAQoCBAASBX8AmAEBGroBIEEgVHJhbnNpdGlvblJvdXRlR3JvdXAgcmVw
cmVzZW50cyBhIGdyb3VwIG9mCiBbYFRyYW5zaXRpb25Sb3V0ZXNgXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLlRyYW5zaXRpb25Sb3V0ZV0gdG8KIGJlIHVzZWQgYnkg
YSBbUGFnZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5QYWdlXS4KCgoK
AwQAARIDfwgcCg0KAwQABxIGgAEChgEECg8KBQQAB50IEgaAAQKGAQQKgwQKBAQAAgASBI8B
AhIa9AMgVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSB0cmFuc2l0aW9uIHJvdXRlIGdy
b3VwLgogW1RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5DcmVhdGVUcmFuc2l0aW9uUm91dGVHcm91
cF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVH
cm91cHMuQ3JlYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBdCiBwb3B1bGF0ZXMgdGhlIG5hbWUg
YXV0b21hdGljYWxseS4gRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9u
cy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi90cmFuc2l0
aW9uUm91dGVHcm91cHMvPFRyYW5zaXRpb25Sb3V0ZUdyb3VwSUQ+YAogb3IKIGBwcm9qZWN0
cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4v
dHJhbnNpdGlvblJvdXRlR3JvdXBzLzxUcmFuc2l0aW9uUm91dGVHcm91cElEPmAKIGZvciBh
Z2VudC1sZXZlbCBncm91cHMuCgoNCgUEAAIABRIEjwECCAoNCgUEAAIAARIEjwEJDQoNCgUE
AAIAAxIEjwEQEQqgAQoEBAACARIEkwECQxqRASBSZXF1aXJlZC4gVGhlIGh1bWFuLXJlYWRh
YmxlIG5hbWUgb2YgdGhlIHRyYW5zaXRpb24gcm91dGUgZ3JvdXAsIHVuaXF1ZQogd2l0aGlu
IHRoZSBmbG93LiBUaGUgZGlzcGxheSBuYW1lIGNhbiBiZSBubyBsb25nZXIgdGhhbiAzMCBj
aGFyYWN0ZXJzLgoKDQoFBAACAQUSBJMBAggKDQoFBAACAQESBJMBCRUKDQoFBAACAQMSBJMB
GBkKDQoFBAACAQgSBJMBGkIKEAoIBAACAQicCAASBJMBG0EKhwEKBAQAAgISBJcBAjEaeSBU
cmFuc2l0aW9uIHJvdXRlcyBhc3NvY2lhdGVkIHdpdGggdGhlCiBbVHJhbnNpdGlvblJvdXRl
R3JvdXBdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJv
dXRlR3JvdXBdLgoKDQoFBAACAgQSBJcBAgoKDQoFBAACAgYSBJcBCxoKDQoFBAACAgESBJcB
GywKDQoFBAACAgMSBJcBLzAKsAEKAgQBEgacAQC8AQEaoQEgVGhlIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtUcmFuc2l0aW9uUm91dGVHcm91cHMuTGlzdFRyYW5zaXRpb25Sb3V0ZUdyb3Vw
c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVH
cm91cHMuTGlzdFRyYW5zaXRpb25Sb3V0ZUdyb3Vwc10uCgoLCgMEAQESBJwBCCgK6gEKBAQB
AgASBqEBAqYBBBrZASBSZXF1aXJlZC4gVGhlIGZsb3cgdG8gbGlzdCBhbGwgdHJhbnNpdGlv
biByb3V0ZSBncm91cHMgZm9yLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPmAK
ICBvciBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2Vu
dHMvPEFnZW50SUQ+LgoKDQoFBAECAAUSBKEBAggKDQoFBAECAAESBKEBCQ8KDQoFBAECAAMS
BKEBEhMKDwoFBAECAAgSBqEBFKYBAwoQCggEAQIACJwIABIEogEEKgoRCgcEAQIACJ8IEgaj
AQSlAQUKaQoEBAECARIEqgECFhpbIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byBy
ZXR1cm4gaW4gYSBzaW5nbGUgcGFnZS4gQnkgZGVmYXVsdCAxMDAgYW5kCiBhdCBtb3N0IDEw
MDAuCgoNCgUEAQIBBRIEqgECBwoNCgUEAQIBARIEqgEIEQoNCgUEAQIBAxIEqgEUFQpQCgQE
AQICEgStAQIYGkIgVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEg
cHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAECAgUSBK0BAggKDQoFBAECAgESBK0BCRMK
DQoFBAECAgMSBK0BFhcK8gMKBAQBAgMSBLsBAhsa4wMgVGhlIGxhbmd1YWdlIHRvIGxpc3Qg
dHJhbnNpdGlvbiByb3V0ZSBncm91cHMgZm9yLiBUaGUgZm9sbG93aW5nIGZpZWxkcyBhcmUK
IGxhbmd1YWdlIGRlcGVuZGVudDoKCiAqICBgVHJhbnNpdGlvblJvdXRlR3JvdXAudHJhbnNp
dGlvbl9yb3V0ZXMudHJpZ2dlcl9mdWxmaWxsbWVudC5tZXNzYWdlc2AKICoKIGBUcmFuc2l0
aW9uUm91dGVHcm91cC50cmFuc2l0aW9uX3JvdXRlcy50cmlnZ2VyX2Z1bGZpbGxtZW50LmNv
bmRpdGlvbmFsX2Nhc2VzYAoKIElmIG5vdCBzcGVjaWZpZWQsIHRoZSBhZ2VudCdzIGRlZmF1
bHQgbGFuZ3VhZ2UgaXMgdXNlZC4KIFtNYW55CiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9kaWFsb2dmbG93L2N4L2RvY3MvcmVmZXJlbmNlL2xhbmd1YWdlKQogYXJl
IHN1cHBvcnRlZC4KIE5vdGU6IGxhbmd1YWdlcyBtdXN0IGJlIGVuYWJsZWQgaW4gdGhlIGFn
ZW50IGJlZm9yZSB0aGV5IGNhbiBiZSB1c2VkLgoKDQoFBAECAwUSBLsBAggKDQoFBAECAwES
BLsBCRYKDQoFBAECAwMSBLsBGRoKsQEKAgQCEgbAAQDKAQEaogEgVGhlIHJlc3BvbnNlIG1l
c3NhZ2UgZm9yCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBzLkxpc3RUcmFuc2l0aW9uUm91dGVH
cm91cHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJv
dXRlR3JvdXBzLkxpc3RUcmFuc2l0aW9uUm91dGVHcm91cHNdLgoKCwoDBAIBEgTAAQgpCoQC
CgQEAgIAEgTFAQI8GvUBIFRoZSBsaXN0IG9mIHRyYW5zaXRpb24gcm91dGUgZ3JvdXBzLiBU
aGVyZSB3aWxsIGJlIGEgbWF4aW11bSBudW1iZXIgb2YKIGl0ZW1zIHJldHVybmVkIGJhc2Vk
IG9uIHRoZSBwYWdlX3NpemUgZmllbGQgaW4gdGhlIHJlcXVlc3QuIFRoZSBsaXN0IG1heSBp
bgogc29tZSBjYXNlcyBiZSBlbXB0eSBvciBjb250YWluIGZld2VyIGVudHJpZXMgdGhhbiBw
YWdlX3NpemUgZXZlbiBpZiB0aGlzCiBpc24ndCB0aGUgbGFzdCBwYWdlLgoKDQoFBAICAAQS
BMUBAgoKDQoFBAICAAYSBMUBCx8KDQoFBAICAAESBMUBIDcKDQoFBAICAAMSBMUBOjsKbwoE
BAICARIEyQECHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0
cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3Qu
CgoNCgUEAgIBBRIEyQECCAoNCgUEAgIBARIEyQEJGAoNCgUEAgIBAxIEyQEbHAqsAQoCBAMS
Bs4BAOkBARqdASBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1RyYW5zaXRpb25Sb3V0ZUdy
b3Vwcy5HZXRUcmFuc2l0aW9uUm91dGVHcm91cF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5UcmFuc2l0aW9uUm91dGVHcm91cHMuR2V0VHJhbnNpdGlvblJvdXRlR3Jv
dXBdLgoKCwoDBAMBEgTOAQgmCvkCCgQEAwIAEgbVAQLaAQQa6AIgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZQogW1RyYW5zaXRpb25Sb3V0ZUdyb3VwXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52M2JldGExLlRyYW5zaXRpb25Sb3V0ZUdyb3VwXS4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJ
RD4vZmxvd3MvPEZsb3dJRD4vdHJhbnNpdGlvblJvdXRlR3JvdXBzLzxUcmFuc2l0aW9uUm91
dGVHcm91cElEPmAKIG9yCiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2Nh
dGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3RyYW5zaXRpb25Sb3V0ZUdyb3Vwcy88VHJhbnNp
dGlvblJvdXRlR3JvdXBJRD5gLgoKDQoFBAMCAAUSBNUBAggKDQoFBAMCAAESBNUBCQ0KDQoF
BAMCAAMSBNUBEBEKDwoFBAMCAAgSBtUBEtoBAwoQCggEAwIACJwIABIE1gEEKgoRCgcEAwIA
CJ8IEgbXAQTZAQUK+QMKBAQDAgESBOgBAhsa6gMgVGhlIGxhbmd1YWdlIHRvIHJldHJpZXZl
IHRoZSB0cmFuc2l0aW9uIHJvdXRlIGdyb3VwIGZvci4gVGhlIGZvbGxvd2luZwogZmllbGRz
IGFyZSBsYW5ndWFnZSBkZXBlbmRlbnQ6CgogKiAgYFRyYW5zaXRpb25Sb3V0ZUdyb3VwLnRy
YW5zaXRpb25fcm91dGVzLnRyaWdnZXJfZnVsZmlsbG1lbnQubWVzc2FnZXNgCiAqCiBgVHJh
bnNpdGlvblJvdXRlR3JvdXAudHJhbnNpdGlvbl9yb3V0ZXMudHJpZ2dlcl9mdWxmaWxsbWVu
dC5jb25kaXRpb25hbF9jYXNlc2AKCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgYWdlbnQncyBk
ZWZhdWx0IGxhbmd1YWdlIGlzIHVzZWQuCiBbTWFueQogbGFuZ3VhZ2VzXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL3JlZmVyZW5jZS9sYW5ndWFnZSkK
IGFyZSBzdXBwb3J0ZWQuCiBOb3RlOiBsYW5ndWFnZXMgbXVzdCBiZSBlbmFibGVkIGluIHRo
ZSBhZ2VudCBiZWZvcmUgdGhleSBjYW4gYmUgdXNlZC4KCg0KBQQDAgEFEgToAQIICg0KBQQD
AgEBEgToAQkWCg0KBQQDAgEDEgToARkaCrIBCgIEBBIG7QEAiwIBGqMBIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBzLkNyZWF0ZVRyYW5zaXRpb25S
b3V0ZUdyb3VwXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlRyYW5zaXRp
b25Sb3V0ZUdyb3Vwcy5DcmVhdGVUcmFuc2l0aW9uUm91dGVHcm91cF0uCgoLCgMEBAESBO0B
CCkKvAIKBAQEAgASBvQBAvkBBBqrAiBSZXF1aXJlZC4gVGhlIGZsb3cgdG8gY3JlYXRlIGFu
CiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuVHJhbnNpdGlvblJvdXRlR3JvdXBdCiBmb3IuIEZvcm1hdDoKIGBwcm9qZWN0cy88
UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZmxv
d3MvPEZsb3dJRD5gCiBvciBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2Nh
dGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+YAogZm9yIGFnZW50LWxldmVsIGdyb3Vwcy4KCg0K
BQQEAgAFEgT0AQIICg0KBQQEAgABEgT0AQkPCg0KBQQEAgADEgT0ARITCg8KBQQEAgAIEgb0
ART5AQMKEAoIBAQCAAicCAASBPUBBCoKEQoHBAQCAAifCBIG9gEE+AEFCkEKBAQEAgESBvwB
Av0BLxoxIFJlcXVpcmVkLiBUaGUgdHJhbnNpdGlvbiByb3V0ZSBncm91cCB0byBjcmVhdGUu
CgoNCgUEBAIBBhIE/AECFgoNCgUEBAIBARIE/AEXLQoNCgUEBAIBAxIE/AEwMQoNCgUEBAIB
CBIE/QEGLgoQCggEBAIBCJwIABIE/QEHLQrSAwoEBAQCAhIEigICGxrDAyBUaGUgbGFuZ3Vh
Z2Ugb2YgdGhlIGZvbGxvd2luZyBmaWVsZHMgaW4gYFRyYW5zaXRpb25Sb3V0ZUdyb3VwYDoK
CiAqICBgVHJhbnNpdGlvblJvdXRlR3JvdXAudHJhbnNpdGlvbl9yb3V0ZXMudHJpZ2dlcl9m
dWxmaWxsbWVudC5tZXNzYWdlc2AKICoKIGBUcmFuc2l0aW9uUm91dGVHcm91cC50cmFuc2l0
aW9uX3JvdXRlcy50cmlnZ2VyX2Z1bGZpbGxtZW50LmNvbmRpdGlvbmFsX2Nhc2VzYAoKIElm
IG5vdCBzcGVjaWZpZWQsIHRoZSBhZ2VudCdzIGRlZmF1bHQgbGFuZ3VhZ2UgaXMgdXNlZC4K
IFtNYW55CiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93
L2N4L2RvY3MvcmVmZXJlbmNlL2xhbmd1YWdlKQogYXJlIHN1cHBvcnRlZC4KIE5vdGU6IGxh
bmd1YWdlcyBtdXN0IGJlIGVuYWJsZWQgaW4gdGhlIGFnZW50IGJlZm9yZSB0aGV5IGNhbiBi
ZSB1c2VkLgoKDQoFBAQCAgUSBIoCAggKDQoFBAQCAgESBIoCCRYKDQoFBAQCAgMSBIoCGRoK
sgEKAgQFEgaPAgCjAgEaowEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtUcmFuc2l0aW9u
Um91dGVHcm91cHMuVXBkYXRlVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJvdXRlR3JvdXBzLlVwZGF0ZVRyYW5z
aXRpb25Sb3V0ZUdyb3VwXS4KCgsKAwQFARIEjwIIKQpBCgQEBQIAEgaRAgKSAi8aMSBSZXF1
aXJlZC4gVGhlIHRyYW5zaXRpb24gcm91dGUgZ3JvdXAgdG8gdXBkYXRlLgoKDQoFBAUCAAYS
BJECAhYKDQoFBAUCAAESBJECFy0KDQoFBAUCAAMSBJECMDEKDQoFBAUCAAgSBJICBi4KEAoI
BAUCAAicCAASBJICBy0KPQoEBAUCARIElQICLBovIFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hp
Y2ggZmllbGRzIGdldCB1cGRhdGVkLgoKDQoFBAUCAQYSBJUCAhsKDQoFBAUCAQESBJUCHCcK
DQoFBAUCAQMSBJUCKisK0gMKBAQFAgISBKICAhsawwMgVGhlIGxhbmd1YWdlIG9mIHRoZSBm
b2xsb3dpbmcgZmllbGRzIGluIGBUcmFuc2l0aW9uUm91dGVHcm91cGA6CgogKiAgYFRyYW5z
aXRpb25Sb3V0ZUdyb3VwLnRyYW5zaXRpb25fcm91dGVzLnRyaWdnZXJfZnVsZmlsbG1lbnQu
bWVzc2FnZXNgCiAqCiBgVHJhbnNpdGlvblJvdXRlR3JvdXAudHJhbnNpdGlvbl9yb3V0ZXMu
dHJpZ2dlcl9mdWxmaWxsbWVudC5jb25kaXRpb25hbF9jYXNlc2AKCiBJZiBub3Qgc3BlY2lm
aWVkLCB0aGUgYWdlbnQncyBkZWZhdWx0IGxhbmd1YWdlIGlzIHVzZWQuCiBbTWFueQogbGFu
Z3VhZ2VzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL3Jl
ZmVyZW5jZS9sYW5ndWFnZSkKIGFyZSBzdXBwb3J0ZWQuCiBOb3RlOiBsYW5ndWFnZXMgbXVz
dCBiZSBlbmFibGVkIGluIHRoZSBhZ2VudCBiZWZvcmUgdGhleSBjYW4gYmUgdXNlZC4KCg0K
BQQFAgIFEgSiAgIICg0KBQQFAgIBEgSiAgkWCg0KBQQFAgIDEgSiAhkaCrIBCgIEBhIGpwIA
vQIBGqMBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBz
LkRlbGV0ZVRyYW5zaXRpb25Sb3V0ZUdyb3VwXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLlRyYW5zaXRpb25Sb3V0ZUdyb3Vwcy5EZWxldGVUcmFuc2l0aW9uUm91dGVH
cm91cF0uCgoLCgMEBgESBKcCCCkKgwMKBAQGAgASBq4CArMCBBryAiBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlCiBbVHJhbnNpdGlvblJvdXRlR3JvdXBdW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzYmV0YTEuVHJhbnNpdGlvblJvdXRlR3JvdXBdCiB0byBkZWxldGUuIEZv
cm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2Fn
ZW50cy88QWdlbnRJRD4vZmxvd3MvPEZsb3dJRD4vdHJhbnNpdGlvblJvdXRlR3JvdXBzLzxU
cmFuc2l0aW9uUm91dGVHcm91cElEPmAKIG9yCiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9j
YXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3RyYW5zaXRpb25Sb3V0ZUdy
b3Vwcy88VHJhbnNpdGlvblJvdXRlR3JvdXBJRD5gLgoKDQoFBAYCAAUSBK4CAggKDQoFBAYC
AAESBK4CCQ0KDQoFBAYCAAMSBK4CEBEKDwoFBAYCAAgSBq4CErMCAwoQCggEBgIACJwIABIE
rwIEKgoRCgcEBgIACJ8IEgawAgSyAgUKkwMKBAQGAgESBLwCAhEahAMgVGhpcyBmaWVsZCBo
YXMgbm8gZWZmZWN0IGZvciB0cmFuc2l0aW9uIHJvdXRlIGdyb3VwIHRoYXQgbm8gcGFnZSBp
cyB1c2luZy4KIElmIHRoZSB0cmFuc2l0aW9uIHJvdXRlIGdyb3VwIGlzIHJlZmVyZW5jZWQg
YnkgYW55IHBhZ2U6CgogKiAgSWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2UsIGFuIGVycm9y
IHdpbGwgYmUgcmV0dXJuZWQgd2l0aCBtZXNzYWdlCiAgICBpbmRpY2F0aW5nIHBhZ2VzIHRo
YXQgcmVmZXJlbmNlIHRoZSB0cmFuc2l0aW9uIHJvdXRlIGdyb3VwLgogKiAgSWYgYGZvcmNl
YCBpcyBzZXQgdG8gdHJ1ZSwgRGlhbG9nZmxvdyB3aWxsIHJlbW92ZSB0aGUgdHJhbnNpdGlv
biByb3V0ZQogICAgZ3JvdXAsIGFzIHdlbGwgYXMgYW55IHJlZmVyZW5jZSB0byBpdC4KCg0K
BQQGAgEFEgS8AgIGCg0KBQQGAgEBEgS8AgcMCg0KBQQGAgEDEgS8Ag8QYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup ===
    # Fields for TransitionRouteGroup
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: transition_routes Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TransitionRoute)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest ===
    # Fields for ListTransitionRouteGroupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse ===
    # Fields for ListTransitionRouteGroupsResponse
    # Field: transition_route_groups Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::GetTransitionRouteGroupRequest ===
    # Fields for GetTransitionRouteGroupRequest
    # Field: name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::CreateTransitionRouteGroupRequest ===
    # Fields for CreateTransitionRouteGroupRequest
    # Field: parent Type: 9 ()
    # Field: transition_route_group Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::UpdateTransitionRouteGroupRequest ===
    # Fields for UpdateTransitionRouteGroupRequest
    # Field: transition_route_group Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::DeleteTransitionRouteGroupRequest ===
    # Fields for DeleteTransitionRouteGroupRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroupsClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroupsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroupsClient

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
        ? Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups',
        method         => 'ListTransitionRouteGroups',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse',
    });
}

sub get_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::GetTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups',
        method         => 'GetTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup',
    });
}

sub create_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::CreateTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups',
        method         => 'CreateTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup',
    });
}

sub update_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::UpdateTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups',
        method         => 'UpdateTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup',
    });
}

sub delete_transition_route_group {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::DeleteTransitionRouteGroupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups',
        method         => 'DeleteTransitionRouteGroup',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/transition_route_group.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup->new({
        name => $name,
        display_name => $display_name,
        transition_routes => $transition_routes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/transition_route_group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup

A TransitionRouteGroup represents a group of
[`TransitionRoutes`][google.cloud.dialogflow.cx.v3beta1.TransitionRoute] to
be used by a [Page][google.cloud.dialogflow.cx.v3beta1.Page].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the transition route group.
[TransitionRouteGroups.CreateTransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.CreateTransitionRouteGroup]
populates the name automatically. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/transitionRouteGroups/<TransitionRouteGroupID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/transitionRouteGroups/<TransitionRouteGroupID>`
for agent-level groups.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the transition route group, unique
within the flow. The display name can be no longer than 30 characters.

=item * C<< $msg->transition_routes() >> / C<< $msg->transition_routes($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Page::TransitionRoute>)

Transition routes associated with the
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup].

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest

The request message for
[TransitionRouteGroups.ListTransitionRouteGroups][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.ListTransitionRouteGroups].

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse

The response message for
[TransitionRouteGroups.ListTransitionRouteGroups][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.ListTransitionRouteGroups].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transition_route_groups() >> / C<< $msg->transition_route_groups($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup>)

The list of transition route groups. There will be a maximum number of
items returned based on the page_size field in the request. The list may in
some cases be empty or contain fewer entries than page_size even if this
isn't the last page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::GetTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.GetTransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.GetTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup].
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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::CreateTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.CreateTransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.CreateTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The flow to create an
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup]
for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`
or `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`
for agent-level groups.

=item * C<< $msg->transition_route_group() >> / C<< $msg->transition_route_group($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup>)

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::UpdateTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.UpdateTransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.UpdateTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transition_route_group() >> / C<< $msg->transition_route_group($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup>)

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::DeleteTransitionRouteGroupRequest

The request message for
[TransitionRouteGroups.DeleteTransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroups.DeleteTransitionRouteGroup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[TransitionRouteGroup][google.cloud.dialogflow.cx.v3beta1.TransitionRouteGroup]
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
