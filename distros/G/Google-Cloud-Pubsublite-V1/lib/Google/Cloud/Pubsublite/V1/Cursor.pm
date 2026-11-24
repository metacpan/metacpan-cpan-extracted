package Google::Cloud::Pubsublite::V1::Cursor;

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
    eval { require Google::Cloud::Pubsublite::V1::Common };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvcHVic3VibGl0ZS92MS9jdXJzb3IucHJvdG8SGmdvb2dsZS5jbG91
ZC5wdWJzdWJsaXRlLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL3B1YnN1YmxpdGUvdjEvY29t
bW9uLnByb3RvIl4KGkluaXRpYWxDb21taXRDdXJzb3JSZXF1ZXN0EiIKDHN1YnNjcmlwdGlv
bhgBIAEoCVIMc3Vic2NyaXB0aW9uEhwKCXBhcnRpdGlvbhgCIAEoA1IJcGFydGl0aW9uIh0K
G0luaXRpYWxDb21taXRDdXJzb3JSZXNwb25zZSJaChxTZXF1ZW5jZWRDb21taXRDdXJzb3JS
ZXF1ZXN0EjoKBmN1cnNvchgBIAEoCzIiLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkN1
cnNvclIGY3Vyc29yIlIKHVNlcXVlbmNlZENvbW1pdEN1cnNvclJlc3BvbnNlEjEKFGFja25v
d2xlZGdlZF9jb21taXRzGAEgASgDUhNhY2tub3dsZWRnZWRDb21taXRzItEBChxTdHJlYW1p
bmdDb21taXRDdXJzb3JSZXF1ZXN0ElIKB2luaXRpYWwYASABKAsyNi5nb29nbGUuY2xvdWQu
cHVic3VibGl0ZS52MS5Jbml0aWFsQ29tbWl0Q3Vyc29yUmVxdWVzdEgAUgdpbml0aWFsElIK
BmNvbW1pdBgCIAEoCzI4Lmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLlNlcXVlbmNlZENv
bW1pdEN1cnNvclJlcXVlc3RIAFIGY29tbWl0QgkKB3JlcXVlc3Qi1AEKHVN0cmVhbWluZ0Nv
bW1pdEN1cnNvclJlc3BvbnNlElMKB2luaXRpYWwYASABKAsyNy5nb29nbGUuY2xvdWQucHVi
c3VibGl0ZS52MS5Jbml0aWFsQ29tbWl0Q3Vyc29yUmVzcG9uc2VIAFIHaW5pdGlhbBJTCgZj
b21taXQYAiABKAsyOS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5TZXF1ZW5jZWRDb21t
aXRDdXJzb3JSZXNwb25zZUgAUgZjb21taXRCCQoHcmVxdWVzdCKTAQoTQ29tbWl0Q3Vyc29y
UmVxdWVzdBIiCgxzdWJzY3JpcHRpb24YASABKAlSDHN1YnNjcmlwdGlvbhIcCglwYXJ0aXRp
b24YAiABKANSCXBhcnRpdGlvbhI6CgZjdXJzb3IYAyABKAsyIi5nb29nbGUuY2xvdWQucHVi
c3VibGl0ZS52MS5DdXJzb3JSBmN1cnNvciIWChRDb21taXRDdXJzb3JSZXNwb25zZSKhAQob
TGlzdFBhcnRpdGlvbkN1cnNvcnNSZXF1ZXN0EkYKBnBhcmVudBgBIAEoCUIu4EEC+kEoCiZw
dWJzdWJsaXRlLmdvb2dsZWFwaXMuY29tL1N1YnNjcmlwdGlvblIGcGFyZW50EhsKCXBhZ2Vf
c2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuImsK
D1BhcnRpdGlvbkN1cnNvchIcCglwYXJ0aXRpb24YASABKANSCXBhcnRpdGlvbhI6CgZjdXJz
b3IYAiABKAsyIi5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5DdXJzb3JSBmN1cnNvciKg
AQocTGlzdFBhcnRpdGlvbkN1cnNvcnNSZXNwb25zZRJYChFwYXJ0aXRpb25fY3Vyc29ycxgB
IAMoCzIrLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLlBhcnRpdGlvbkN1cnNvclIQcGFy
dGl0aW9uQ3Vyc29ycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4y
ogUKDUN1cnNvclNlcnZpY2USkgEKFVN0cmVhbWluZ0NvbW1pdEN1cnNvchI4Lmdvb2dsZS5j
bG91ZC5wdWJzdWJsaXRlLnYxLlN0cmVhbWluZ0NvbW1pdEN1cnNvclJlcXVlc3QaOS5nb29n
bGUuY2xvdWQucHVic3VibGl0ZS52MS5TdHJlYW1pbmdDb21taXRDdXJzb3JSZXNwb25zZSIA
KAEwARLLAQoMQ29tbWl0Q3Vyc29yEi8uZ29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuQ29t
bWl0Q3Vyc29yUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkNvbW1pdEN1
cnNvclJlc3BvbnNlIliC0+STAlIiTS92MS9jdXJzb3Ive3N1YnNjcmlwdGlvbj1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3N1YnNjcmlwdGlvbnMvKn06Y29tbWl0Q3Vyc29yOgEqEt4BChRM
aXN0UGFydGl0aW9uQ3Vyc29ycxI3Lmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkxpc3RQ
YXJ0aXRpb25DdXJzb3JzUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkxp
c3RQYXJ0aXRpb25DdXJzb3JzUmVzcG9uc2UiU4LT5JMCRBJCL3YxL2N1cnNvci97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovc3Vic2NyaXB0aW9ucy8qfS9jdXJzb3Jz2kEGcGFy
ZW50Gk3KQRlwdWJzdWJsaXRlLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULPAQohY29tLmdvb2dsZS5jbG91ZC5wdWJz
dWJsaXRlLnByb3RvQgtDdXJzb3JQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL3B1YnN1
YmxpdGUvYXBpdjEvcHVic3VibGl0ZXBiO3B1YnN1YmxpdGVwYvgBAaoCGkdvb2dsZS5DbG91
ZC5QdWJTdWJMaXRlLlYxygIaR29vZ2xlXENsb3VkXFB1YlN1YkxpdGVcVjHqAh1Hb29nbGU6
OkNsb3VkOjpQdWJTdWJMaXRlOjpWMUr1KQoHEgUOAK8BAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADEKCAoBCBIDGAAfCgkKAggfEgMYAB8KCAoBCBID
GQA3CgkKAgglEgMZADcKCAoBCBIDGgBVCgkKAggLEgMaAFUKCAoBCBIDGwAiCgkKAggKEgMb
ACIKCAoBCBIDHAAsCgkKAggIEgMcACwKCAoBCBIDHQA6CgkKAggBEgMdADoKCAoBCBIDHgA3
CgkKAggpEgMeADcKCAoBCBIDHwA2CgkKAggtEgMfADYK3AEKAgYAEgQkAD0BGs8BIFRoZSBz
ZXJ2aWNlIHRoYXQgYSBzdWJzY3JpYmVyIGNsaWVudCBhcHBsaWNhdGlvbiB1c2VzIHRvIG1h
bmFnZSBjb21taXR0ZWQKIGN1cnNvcnMgd2hpbGUgcmVjZWl2aW5nIG1lc3NzYWdlcy4gQSBj
dXJzb3IgcmVwcmVzZW50cyBhIHN1YnNjcmliZXIncwogcHJvZ3Jlc3Mgd2l0aGluIGEgdG9w
aWMgcGFydGl0aW9uIGZvciBhIGdpdmVuIHN1YnNjcmlwdGlvbi4KCgoKAwYAARIDJAgVCgoK
AwYAAxIDJQJBCgwKBQYAA5kIEgMlAkEKCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3ClQK
BAYAAgASBCoCKzcaRiBFc3RhYmxpc2hlcyBhIHN0cmVhbSB3aXRoIHRoZSBzZXJ2ZXIgZm9y
IG1hbmFnaW5nIGNvbW1pdHRlZCBjdXJzb3JzLgoKDAoFBgACAAESAyoGGwoMCgUGAAIABRID
KhwiCgwKBQYAAgACEgMqIz8KDAoFBgACAAYSAysPFQoMCgUGAAIAAxIDKxYzCi0KBAYAAgES
BC4CMwMaHyBVcGRhdGVzIHRoZSBjb21taXR0ZWQgY3Vyc29yLgoKDAoFBgACAQESAy4GEgoM
CgUGAAIBAhIDLhMmCgwKBQYAAgEDEgMuMUUKDQoFBgACAQQSBC8EMgYKEQoJBgACAQSwyrwi
EgQvBDIGCkwKBAYAAgISBDYCPAMaPiBSZXR1cm5zIGFsbCBjb21taXR0ZWQgY3Vyc29yIGlu
Zm9ybWF0aW9uIGZvciBhIHN1YnNjcmlwdGlvbi4KCgwKBQYAAgIBEgM2BhoKDAoFBgACAgIS
AzYbNgoMCgUGAAICAxIDNw8rCg0KBQYAAgIEEgQ4BDoGChEKCQYAAgIEsMq8IhIEOAQ6BgoM
CgUGAAICBBIDOwQ0Cg8KCAYAAgIEmwgAEgM7BDQKsAEKAgQAEgRCAEkBGqMBIFRoZSBmaXJz
dCBzdHJlYW1pbmcgcmVxdWVzdCB0aGF0IG11c3QgYmUgc2VudCBvbiBhIG5ld2x5LW9wZW5l
ZCBzdHJlYW0uIFRoZQogY2xpZW50IG11c3Qgd2FpdCBmb3IgdGhlIHJlc3BvbnNlIGJlZm9y
ZSBzZW5kaW5nIHN1YnNlcXVlbnQgcmVxdWVzdHMgb24gdGhlCiBzdHJlYW0uCgoKCgMEAAES
A0IIIgpGCgQEAAIAEgNEAhoaOSBUaGUgc3Vic2NyaXB0aW9uIGZvciB3aGljaCB0byBtYW5h
Z2UgY29tbWl0dGVkIGN1cnNvcnMuCgoMCgUEAAIABRIDRAIICgwKBQQAAgABEgNECRUKDAoF
BAACAAMSA0QYGQqhAQoEBAACARIDSAIWGpMBIFRoZSBwYXJ0aXRpb24gZm9yIHdoaWNoIHRv
IG1hbmFnZSBjb21taXR0ZWQgY3Vyc29ycy4gUGFydGl0aW9ucyBhcmUgemVybwogaW5kZXhl
ZCwgc28gYHBhcnRpdGlvbmAgbXVzdCBiZSBpbiB0aGUgcmFuZ2UgWzAsIHRvcGljLm51bV9w
YXJ0aXRpb25zKS4KCgwKBQQAAgEFEgNIAgcKDAoFBAACAQESA0gIEQoMCgUEAAIBAxIDSBQV
CjcKAgQBEgNMACYaLCBSZXNwb25zZSB0byBhbiBJbml0aWFsQ29tbWl0Q3Vyc29yUmVxdWVz
dC4KCgoKAwQBARIDTAgjCoQBCgIEAhIEUABTARp4IFN0cmVhbWluZyByZXF1ZXN0IHRvIHVw
ZGF0ZSB0aGUgY29tbWl0dGVkIGN1cnNvci4gU3Vic2VxdWVudAogU2VxdWVuY2VkQ29tbWl0
Q3Vyc29yUmVxdWVzdHMgb3ZlcnJpZGUgb3V0c3RhbmRpbmcgb25lcy4KCgoKAwQCARIDUAgk
CjYKBAQCAgASA1ICFBopIFRoZSBuZXcgdmFsdWUgZm9yIHRoZSBjb21taXR0ZWQgY3Vyc29y
LgoKDAoFBAICAAYSA1ICCAoMCgUEAgIAARIDUgkPCgwKBQQCAgADEgNSEhMKOQoCBAMSBFYA
WwEaLSBSZXNwb25zZSB0byBhIFNlcXVlbmNlZENvbW1pdEN1cnNvclJlcXVlc3QuCgoKCgME
AwESA1YIJQrGAQoEBAMCABIDWgIhGrgBIFRoZSBudW1iZXIgb2Ygb3V0c3RhbmRpbmcgU2Vx
dWVuY2VkQ29tbWl0Q3Vyc29yUmVxdWVzdHMgYWNrbm93bGVkZ2VkIGJ5CiB0aGlzIHJlc3Bv
bnNlLiBOb3RlIHRoYXQgU2VxdWVuY2VkQ29tbWl0Q3Vyc29yUmVxdWVzdHMgYXJlIGFja25v
d2xlZGdlZCBpbgogdGhlIG9yZGVyIHRoYXQgdGhleSBhcmUgcmVjZWl2ZWQuCgoMCgUEAwIA
BRIDWgIHCgwKBQQDAgABEgNaCBwKDAoFBAMCAAMSA1ofIApHCgIEBBIEXgBnARo7IEEgcmVx
dWVzdCBzZW50IGZyb20gdGhlIGNsaWVudCB0byB0aGUgc2VydmVyIG9uIGEgc3RyZWFtLgoK
CgoDBAQBEgNeCCQKLAoEBAQIABIEYAJmAxoeIFRoZSB0eXBlIG9mIHJlcXVlc3QgdGhpcyBp
cy4KCgwKBQQECAABEgNgCA8KLQoEBAQCABIDYgQrGiAgSW5pdGlhbCByZXF1ZXN0IG9uIHRo
ZSBzdHJlYW0uCgoMCgUEBAIABhIDYgQeCgwKBQQEAgABEgNiHyYKDAoFBAQCAAMSA2IpKgo0
CgQEBAIBEgNlBCwaJyBSZXF1ZXN0IHRvIGNvbW1pdCBhIG5ldyBjdXJzb3IgdmFsdWUuCgoM
CgUEBAIBBhIDZQQgCgwKBQQEAgEBEgNlIScKDAoFBAQCAQMSA2UqKwo5CgIEBRIEagBzARot
IFJlc3BvbnNlIHRvIGEgU3RyZWFtaW5nQ29tbWl0Q3Vyc29yUmVxdWVzdC4KCgoKAwQFARID
agglCiwKBAQFCAASBGwCcgMaHiBUaGUgdHlwZSBvZiByZXF1ZXN0IHRoaXMgaXMuCgoMCgUE
BQgAARIDbAgPCi4KBAQFAgASA24ELBohIEluaXRpYWwgcmVzcG9uc2Ugb24gdGhlIHN0cmVh
bS4KCgwKBQQFAgAGEgNuBB8KDAoFBAUCAAESA24gJwoMCgUEBQIAAxIDbiorCjkKBAQFAgES
A3EELRosIFJlc3BvbnNlIHRvIGNvbW1pdHRpbmcgYSBuZXcgY3Vyc29yIHZhbHVlLgoKDAoF
BAUCAQYSA3EEIQoMCgUEBQIBARIDcSIoCgwKBQQFAgEDEgNxKywKKAoCBAYSBXYAgAEBGhsg
UmVxdWVzdCBmb3IgQ29tbWl0Q3Vyc29yLgoKCgoDBAYBEgN2CBsKPwoEBAYCABIDeAIaGjIg
VGhlIHN1YnNjcmlwdGlvbiBmb3Igd2hpY2ggdG8gdXBkYXRlIHRoZSBjdXJzb3IuCgoMCgUE
BgIABRIDeAIICgwKBQQGAgABEgN4CRUKDAoFBAYCAAMSA3gYGQqaAQoEBAYCARIDfAIWGowB
IFRoZSBwYXJ0aXRpb24gZm9yIHdoaWNoIHRvIHVwZGF0ZSB0aGUgY3Vyc29yLiBQYXJ0aXRp
b25zIGFyZSB6ZXJvIGluZGV4ZWQsCiBzbyBgcGFydGl0aW9uYCBtdXN0IGJlIGluIHRoZSBy
YW5nZSBbMCwgdG9waWMubnVtX3BhcnRpdGlvbnMpLgoKDAoFBAYCAQUSA3wCBwoMCgUEBgIB
ARIDfAgRCgwKBQQGAgEDEgN8FBUKNgoEBAYCAhIDfwIUGikgVGhlIG5ldyB2YWx1ZSBmb3Ig
dGhlIGNvbW1pdHRlZCBjdXJzb3IuCgoMCgUEBgICBhIDfwIICgwKBQQGAgIBEgN/CQ8KDAoF
BAYCAgMSA38SEwooCgIEBxIEgwEAHxocIFJlc3BvbnNlIGZvciBDb21taXRDdXJzb3IuCgoL
CgMEBwESBIMBCBwKMQoCBAgSBoYBAJwBARojIFJlcXVlc3QgZm9yIExpc3RQYXJ0aXRpb25D
dXJzb3JzLgoKCwoDBAgBEgSGAQgjCrABCgQECAIAEgaKAQKPAQQanwEgUmVxdWlyZWQuIFRo
ZSBzdWJzY3JpcHRpb24gZm9yIHdoaWNoIHRvIHJldHJpZXZlIGN1cnNvcnMuCiBTdHJ1Y3R1
cmVkIGxpa2UKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRp
b259L3N1YnNjcmlwdGlvbnMve3N1YnNjcmlwdGlvbl9pZH1gLgoKDQoFBAgCAAUSBIoBAggK
DQoFBAgCAAESBIoBCQ8KDQoFBAgCAAMSBIoBEhMKDwoFBAgCAAgSBooBFI8BAwoQCggECAIA
CJwIABIEiwEEKgoRCgcECAIACJ8IEgaMAQSOAQUKqAEKBAQIAgESBJQBAhYamQEgVGhlIG1h
eGltdW0gbnVtYmVyIG9mIGN1cnNvcnMgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkgcmV0
dXJuIGZld2VyIHRoYW4KIHRoaXMgdmFsdWUuCiBJZiB1bnNldCBvciB6ZXJvLCBhbGwgY3Vy
c29ycyBmb3IgdGhlIHBhcmVudCB3aWxsIGJlIHJldHVybmVkLgoKDQoFBAgCAQUSBJQBAgcK
DQoFBAgCAQESBJQBCBEKDQoFBAgCAQMSBJQBFBUKgQIKBAQIAgISBJsBAhga8gEgQSBwYWdl
IHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RQYXJ0aXRpb25DdXJzb3Jz
YCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2Uu
CgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBg
TGlzdFBhcnRpdGlvbkN1cnNvcnNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlk
ZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUECAICBRIEmwECCAoNCgUECAICARIEmwEJEwoNCgUE
CAICAxIEmwEWFwo/CgIECRIGnwEApQEBGjEgQSBwYWlyIG9mIGEgQ3Vyc29yIGFuZCB0aGUg
cGFydGl0aW9uIGl0IGlzIGZvci4KCgsKAwQJARIEnwEIFwoqCgQECQIAEgShAQIWGhwgVGhl
IHBhcnRpdGlvbiB0aGlzIGlzIGZvci4KCg0KBQQJAgAFEgShAQIHCg0KBQQJAgABEgShAQgR
Cg0KBQQJAgADEgShARQVCigKBAQJAgESBKQBAhQaGiBUaGUgdmFsdWUgb2YgdGhlIGN1cnNv
ci4KCg0KBQQJAgEGEgSkAQIICg0KBQQJAgEBEgSkAQkPCg0KBQQJAgEDEgSkARITCjEKAgQK
EgaoAQCvAQEaIyBSZXNwb25zZSBmb3IgTGlzdFBhcnRpdGlvbkN1cnNvcnMKCgsKAwQKARIE
qAEIJAo4CgQECgIAEgSqAQIxGiogVGhlIHBhcnRpdGlvbiBjdXJzb3JzIGZyb20gdGhpcyBy
ZXF1ZXN0LgoKDQoFBAoCAAQSBKoBAgoKDQoFBAoCAAYSBKoBCxoKDQoFBAoCAAESBKoBGywK
DQoFBAoCAAMSBKoBLzAKkAEKBAQKAgESBK4BAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJl
IHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0
aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoK
DQoFBAoCAQUSBK4BAggKDQoFBAoCAQESBK4BCRgKDQoFBAoCAQMSBK4BGxxiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest ===
    # Fields for InitialCommitCursorRequest
    # Field: subscription Type: 9 ()
    # Field: partition Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorResponse ===
    # Fields for InitialCommitCursorResponse

# === Message: Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorRequest ===
    # Fields for SequencedCommitCursorRequest
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorResponse ===
    # Fields for SequencedCommitCursorResponse
    # Field: acknowledged_commits Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest ===
    # Fields for StreamingCommitCursorRequest
    # Field: initial Type: 11 (.google.cloud.pubsublite.v1.InitialCommitCursorRequest)
    # Field: commit Type: 11 (.google.cloud.pubsublite.v1.SequencedCommitCursorRequest)

# === Message: Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse ===
    # Fields for StreamingCommitCursorResponse
    # Field: initial Type: 11 (.google.cloud.pubsublite.v1.InitialCommitCursorResponse)
    # Field: commit Type: 11 (.google.cloud.pubsublite.v1.SequencedCommitCursorResponse)

# === Message: Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest ===
    # Fields for CommitCursorRequest
    # Field: subscription Type: 9 ()
    # Field: partition Type: 3 ()
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse ===
    # Fields for CommitCursorResponse

# === Message: Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsRequest ===
    # Fields for ListPartitionCursorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Pubsublite::V1::Cursor::PartitionCursor ===
    # Fields for PartitionCursor
    # Field: partition Type: 3 ()
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsResponse ===
    # Fields for ListPartitionCursorsResponse
    # Field: partition_cursors Type: 11 (.google.cloud.pubsublite.v1.PartitionCursor)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Pubsublite::V1::Cursor::CursorServiceClient ===
package Google::Cloud::Pubsublite::V1::Cursor::CursorServiceClient;

=pod

=head2 Service Client: Google::Cloud::Pubsublite::V1::Cursor::CursorServiceClient

Client stub representing the remote C<CursorService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsublite.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsublite.googleapis.com:443' );

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

sub streaming_commit_cursor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.CursorService',
        method         => 'StreamingCommitCursor',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse',
    });
}

sub commit_cursor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.CursorService',
        method         => 'CommitCursor',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse',
    });
}

sub list_partition_cursors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.CursorService',
        method         => 'ListPartitionCursors',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Pubsublite::V1::Cursor - Compiled Protocol Buffers messages for google/cloud/pubsublite/v1/cursor.proto

=head1 SYNOPSIS

    use Google::Cloud::Pubsublite::V1::Cursor;

    my $msg = Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest->new({
        subscription => $subscription,
        partition => $partition,
    });

    # Read or update a field
    my $val = $msg->subscription();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/pubsublite/v1/cursor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest

The first streaming request that must be sent on a newly-opened stream. The
client must wait for the response before sending subsequent requests on the
stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription for which to manage committed cursors.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

The partition for which to manage committed cursors. Partitions are zero
indexed, so `partition` must be in the range [0, topic.num_partitions).

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorResponse

Response to an InitialCommitCursorRequest.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorRequest

Streaming request to update the committed cursor. Subsequent
SequencedCommitCursorRequests override outstanding ones.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The new value for the committed cursor.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorResponse

Response to a SequencedCommitCursorRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->acknowledged_commits() >> / C<< $msg->acknowledged_commits($value) >>

Type: C<Int64>

The number of outstanding SequencedCommitCursorRequests acknowledged by
this response. Note that SequencedCommitCursorRequests are acknowledged in
the order that they are received.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest

A request sent from the client to the server on a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial() >> / C<< $msg->initial($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest>)

Initial request on the stream.

=item * C<< $msg->commit() >> / C<< $msg->commit($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorRequest>)

Request to commit a new cursor value.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse

Response to a StreamingCommitCursorRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial() >> / C<< $msg->initial($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorResponse>)

Initial response on the stream.

=item * C<< $msg->commit() >> / C<< $msg->commit($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorResponse>)

Response to committing a new cursor value.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest

Request for CommitCursor.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription for which to update the cursor.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

The partition for which to update the cursor. Partitions are zero indexed,
so `partition` must be in the range [0, topic.num_partitions).

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The new value for the committed cursor.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse

Response for CommitCursor.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsRequest

Request for ListPartitionCursors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The subscription for which to retrieve cursors.
Structured like
`projects/{project_number}/locations/{location}/subscriptions/{subscription_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of cursors to return. The service may return fewer than
this value.
If unset or zero, all cursors for the parent will be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListPartitionCursors` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListPartitionCursors`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::PartitionCursor

A pair of a Cursor and the partition it is for.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

The partition this is for.

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The value of the cursor.

=back

=head2 Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsResponse

Response for ListPartitionCursors

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partition_cursors() >> / C<< $msg->partition_cursors($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Cursor::PartitionCursor>)

The partition cursors from this request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Pubsublite::V1::Cursor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
