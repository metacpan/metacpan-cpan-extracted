package Google::Cloud::Osconfig::V1::OsPolicyAssignments;

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
    eval { require Google::Cloud::Osconfig::V1::OsPolicy };
    eval { require Google::Cloud::Osconfig::V1::OsconfigCommon };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvb3Njb25maWcvdjEvb3NfcG9saWN5X2Fzc2lnbm1lbnRzLnByb3Rv
Ehhnb29nbGUuY2xvdWQub3Njb25maWcudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9vc2NvbmZp
Zy92MS9vc19wb2xpY3kucHJvdG8aLmdvb2dsZS9jbG91ZC9vc2NvbmZpZy92MS9vc2NvbmZp
Z19jb21tb24ucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8itw0KEk9TUG9saWN5QXNzaWdubWVudBISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rl
c2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhJICgtvc19wb2xpY2llcxgDIAMoCzIiLmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MS5PU1BvbGljeUID4EECUgpvc1BvbGljaWVzEmkKD2lu
c3RhbmNlX2ZpbHRlchgEIAEoCzI7Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5PU1BvbGlj
eUFzc2lnbm1lbnQuSW5zdGFuY2VGaWx0ZXJCA+BBAlIOaW5zdGFuY2VGaWx0ZXISUwoHcm9s
bG91dBgFIAEoCzI0Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5PU1BvbGljeUFzc2lnbm1l
bnQuUm9sbG91dEID4EECUgdyb2xsb3V0EiQKC3JldmlzaW9uX2lkGAYgASgJQgPgQQNSCnJl
dmlzaW9uSWQSUQoUcmV2aXNpb25fY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSEnJldmlzaW9uQ3JlYXRlVGltZRISCgRldGFnGAggASgJUgRl
dGFnEmMKDXJvbGxvdXRfc3RhdGUYCSABKA4yOS5nb29nbGUuY2xvdWQub3Njb25maWcudjEu
T1NQb2xpY3lBc3NpZ25tZW50LlJvbGxvdXRTdGF0ZUID4EEDUgxyb2xsb3V0U3RhdGUSHwoI
YmFzZWxpbmUYCiABKAhCA+BBA1IIYmFzZWxpbmUSHQoHZGVsZXRlZBgLIAEoCEID4EEDUgdk
ZWxldGVkEiUKC3JlY29uY2lsaW5nGAwgASgIQgPgQQNSC3JlY29uY2lsaW5nEhUKA3VpZBgN
IAEoCUID4EEDUgN1aWQaoAEKCExhYmVsU2V0ElkKBmxhYmVscxgBIAMoCzJBLmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy52MS5PU1BvbGljeUFzc2lnbm1lbnQuTGFiZWxTZXQuTGFiZWxzRW50
cnlSBmxhYmVscxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBGqQDCg5JbnN0YW5jZUZpbHRlchIQCgNhbGwYASABKAhSA2FsbBJg
ChBpbmNsdXNpb25fbGFiZWxzGAIgAygLMjUuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLk9T
UG9saWN5QXNzaWdubWVudC5MYWJlbFNldFIPaW5jbHVzaW9uTGFiZWxzEmAKEGV4Y2x1c2lv
bl9sYWJlbHMYAyADKAsyNS5nb29nbGUuY2xvdWQub3Njb25maWcudjEuT1NQb2xpY3lBc3Np
Z25tZW50LkxhYmVsU2V0Ug9leGNsdXNpb25MYWJlbHMSZwoLaW52ZW50b3JpZXMYBCADKAsy
RS5nb29nbGUuY2xvdWQub3Njb25maWcudjEuT1NQb2xpY3lBc3NpZ25tZW50Lkluc3RhbmNl
RmlsdGVyLkludmVudG9yeVILaW52ZW50b3JpZXMaUwoJSW52ZW50b3J5EicKDW9zX3Nob3J0
X25hbWUYASABKAlCA+BBAlILb3NTaG9ydE5hbWUSHQoKb3NfdmVyc2lvbhgCIAEoCVIJb3NW
ZXJzaW9uGrEBCgdSb2xsb3V0EloKEWRpc3J1cHRpb25fYnVkZ2V0GAEgASgLMiguZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLnYxLkZpeGVkT3JQZXJjZW50QgPgQQJSEGRpc3J1cHRpb25CdWRn
ZXQSSgoRbWluX3dhaXRfZHVyYXRpb24YAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRp
b25CA+BBAlIPbWluV2FpdER1cmF0aW9uImwKDFJvbGxvdXRTdGF0ZRIdChlST0xMT1VUX1NU
QVRFX1VOU1BFQ0lGSUVEEAASDwoLSU5fUFJPR1JFU1MQARIOCgpDQU5DRUxMSU5HEAISDQoJ
Q0FOQ0VMTEVEEAMSDQoJU1VDQ0VFREVEEAQ6hAHqQYABCipvc2NvbmZpZy5nb29nbGVhcGlz
LmNvbS9PU1BvbGljeUFzc2lnbm1lbnQSUnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9vc1BvbGljeUFzc2lnbm1lbnRzL3tvc19wb2xpY3lfYXNzaWdubWVudH0i
sgUKI09TUG9saWN5QXNzaWdubWVudE9wZXJhdGlvbk1ldGFkYXRhEmEKFG9zX3BvbGljeV9h
c3NpZ25tZW50GAEgASgJQi/6QSwKKm9zY29uZmlnLmdvb2dsZWFwaXMuY29tL09TUG9saWN5
QXNzaWdubWVudFISb3NQb2xpY3lBc3NpZ25tZW50EmYKCmFwaV9tZXRob2QYAiABKA4yRy5n
b29nbGUuY2xvdWQub3Njb25maWcudjEuT1NQb2xpY3lBc3NpZ25tZW50T3BlcmF0aW9uTWV0
YWRhdGEuQVBJTWV0aG9kUglhcGlNZXRob2QSbwoNcm9sbG91dF9zdGF0ZRgDIAEoDjJKLmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MS5PU1BvbGljeUFzc2lnbm1lbnRPcGVyYXRpb25NZXRh
ZGF0YS5Sb2xsb3V0U3RhdGVSDHJvbGxvdXRTdGF0ZRJIChJyb2xsb3V0X3N0YXJ0X3RpbWUY
BCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhByb2xsb3V0U3RhcnRUaW1lEkoK
E3JvbGxvdXRfdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
UhFyb2xsb3V0VXBkYXRlVGltZSJLCglBUElNZXRob2QSGgoWQVBJX01FVEhPRF9VTlNQRUNJ
RklFRBAAEgoKBkNSRUFURRABEgoKBlVQREFURRACEgoKBkRFTEVURRADImwKDFJvbGxvdXRT
dGF0ZRIdChlST0xMT1VUX1NUQVRFX1VOU1BFQ0lGSUVEEAASDwoLSU5fUFJPR1JFU1MQARIO
CgpDQU5DRUxMSU5HEAISDQoJQ0FOQ0VMTEVEEAMSDQoJU1VDQ0VFREVEEAQihQIKH0NyZWF0
ZU9TUG9saWN5QXNzaWdubWVudFJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxv
Y2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EmMKFG9zX3BvbGljeV9h
c3NpZ25tZW50GAIgASgLMiwuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxLk9TUG9saWN5QXNz
aWdubWVudEID4EECUhJvc1BvbGljeUFzc2lnbm1lbnQSOgoXb3NfcG9saWN5X2Fzc2lnbm1l
bnRfaWQYAyABKAlCA+BBAlIUb3NQb2xpY3lBc3NpZ25tZW50SWQiyAEKH1VwZGF0ZU9TUG9s
aWN5QXNzaWdubWVudFJlcXVlc3QSYwoUb3NfcG9saWN5X2Fzc2lnbm1lbnQYASABKAsyLC5n
b29nbGUuY2xvdWQub3Njb25maWcudjEuT1NQb2xpY3lBc3NpZ25tZW50QgPgQQJSEm9zUG9s
aWN5QXNzaWdubWVudBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJmChxHZXRPU1BvbGljeUFzc2lnbm1lbnRSZXF1
ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqb3Njb25maWcuZ29vZ2xlYXBpcy5jb20vT1NQ
b2xpY3lBc3NpZ25tZW50UgRuYW1lIp8BCh5MaXN0T1NQb2xpY3lBc3NpZ25tZW50c1JlcXVl
c3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9M
b2NhdGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90
b2tlbhgDIAEoCVIJcGFnZVRva2VuIqsBCh9MaXN0T1NQb2xpY3lBc3NpZ25tZW50c1Jlc3Bv
bnNlEmAKFW9zX3BvbGljeV9hc3NpZ25tZW50cxgBIAMoCzIsLmdvb2dsZS5jbG91ZC5vc2Nv
bmZpZy52MS5PU1BvbGljeUFzc2lnbm1lbnRSE29zUG9saWN5QXNzaWdubWVudHMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIqwBCiZMaXN0T1NQb2xpY3lBc3Np
Z25tZW50UmV2aXNpb25zUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKm9zY29uZmln
Lmdvb2dsZWFwaXMuY29tL09TUG9saWN5QXNzaWdubWVudFIEbmFtZRIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKzAQonTGlz
dE9TUG9saWN5QXNzaWdubWVudFJldmlzaW9uc1Jlc3BvbnNlEmAKFW9zX3BvbGljeV9hc3Np
Z25tZW50cxgBIAMoCzIsLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MS5PU1BvbGljeUFzc2ln
bm1lbnRSE29zUG9saWN5QXNzaWdubWVudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuImkKH0RlbGV0ZU9TUG9saWN5QXNzaWdubWVudFJlcXVlc3QSRgoEbmFt
ZRgBIAEoCUIy4EEC+kEsCipvc2NvbmZpZy5nb29nbGVhcGlzLmNvbS9PU1BvbGljeUFzc2ln
bm1lbnRSBG5hbWVCyAEKHGNvbS5nb29nbGUuY2xvdWQub3Njb25maWcudjFCGE9zUG9saWN5
QXNzaWdubWVudHNQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL29zY29uZmlnL2FwaXYx
L29zY29uZmlncGI7b3Njb25maWdwYqoCGEdvb2dsZS5DbG91ZC5Pc0NvbmZpZy5WMcoCGEdv
b2dsZVxDbG91ZFxPc0NvbmZpZ1xWMeoCG0dvb2dsZTo6Q2xvdWQ6Ok9zQ29uZmlnOjpWMUqJ
ZQoHEgUOAIEDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
IQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAMgoJCgIDAxIDFQA4CgkKAgMEEgMW
ACgKCQoCAwUSAxcAKgoJCgIDBhIDGAApCggKAQgSAxoANQoJCgIIJRIDGgA1CggKAQgSAxsA
TwoJCgIICxIDGwBPCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AOQoJCgIICBIDHQA5
CggKAQgSAx4ANQoJCgIIARIDHgA1CggKAQgSAx8ANQoJCgIIKRIDHwA1CggKAQgSAyAANAoJ
CgIILRIDIAA0CrQECgIEABIFLQDQAQEapgQgT1MgcG9saWN5IGFzc2lnbm1lbnQgaXMgYW4g
QVBJIHJlc291cmNlIHRoYXQgaXMgdXNlZCB0bwogYXBwbHkgYSBzZXQgb2YgT1MgcG9saWNp
ZXMgdG8gYSBkeW5hbWljYWxseSB0YXJnZXRlZCBncm91cCBvZiBDb21wdXRlIEVuZ2luZQog
Vk0gaW5zdGFuY2VzLgoKIEFuIE9TIHBvbGljeSBpcyB1c2VkIHRvIGRlZmluZSB0aGUgZGVz
aXJlZCBzdGF0ZSBjb25maWd1cmF0aW9uIGZvciBhCiBDb21wdXRlIEVuZ2luZSBWTSBpbnN0
YW5jZSB0aHJvdWdoIGEgc2V0IG9mIGNvbmZpZ3VyYXRpb24gcmVzb3VyY2VzIHRoYXQKIHBy
b3ZpZGUgY2FwYWJpbGl0aWVzIHN1Y2ggYXMgaW5zdGFsbGluZyBvciByZW1vdmluZyBzb2Z0
d2FyZSBwYWNrYWdlcywgb3IKIGV4ZWN1dGluZyBhIHNjcmlwdC4KCiBGb3IgbW9yZSBpbmZv
cm1hdGlvbiwgc2VlIFtPUyBwb2xpY3kgYW5kIE9TIHBvbGljeQogYXNzaWdubWVudF0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9vcy1jb25maWd1cmF0aW9uLW1h
bmFnZW1lbnQvd29ya2luZy13aXRoLW9zLXBvbGljaWVzKS4KCgoKAwQAARIDLQgaCgsKAwQA
BxIELgIxBAoNCgUEAAedCBIELgIxBAqvAwoEBAADABIEPAJBAxqgAyBNZXNzYWdlIHJlcHJl
c2VudGluZyBsYWJlbCBzZXQuCiAqIEEgbGFiZWwgaXMgYSBrZXkgdmFsdWUgcGFpciBzZXQg
Zm9yIGEgVk0uCiAqIEEgTGFiZWxTZXQgaXMgYSBzZXQgb2YgbGFiZWxzLgogKiBMYWJlbHMg
d2l0aGluIGEgTGFiZWxTZXQgYXJlIEFORGVkLiBJbiBvdGhlciB3b3JkcywgYSBMYWJlbFNl
dCBpcwogICBhcHBsaWNhYmxlIGZvciBhIFZNIG9ubHkgaWYgaXQgbWF0Y2hlcyBhbGwgdGhl
IGxhYmVscyBpbiB0aGUKICAgTGFiZWxTZXQuCiAqIEV4YW1wbGU6IEEgTGFiZWxTZXQgd2l0
aCAyIGxhYmVsczogYGVudj1wcm9kYCBhbmQgYHR5cGU9d2Vic2VydmVyYCB3aWxsCiAgICAg
ICAgICAgIG9ubHkgYmUgYXBwbGljYWJsZSBmb3IgdGhvc2UgVk1zIHdpdGggYm90aCBsYWJl
bHMKICAgICAgICAgICAgcHJlc2VudC4KCgwKBQQAAwABEgM8ChIKmwEKBgQAAwACABIDQAQj
GosBIExhYmVscyBhcmUgaWRlbnRpZmllZCBieSBrZXkvdmFsdWUgcGFpcnMgaW4gdGhpcyBt
YXAuCiBBIFZNIHNob3VsZCBjb250YWluIGFsbCB0aGUga2V5L3ZhbHVlIHBhaXJzIHNwZWNp
ZmllZCBpbiB0aGlzCiBtYXAgdG8gYmUgc2VsZWN0ZWQuCgoOCgcEAAMAAgAGEgNABBcKDgoH
BAADAAIAARIDQBgeCg4KBwQAAwACAAMSA0AhIgq3AQoEBAADARIERwJsAxqoASBGaWx0ZXJz
IHRvIHNlbGVjdCB0YXJnZXQgVk1zIGZvciBhbiBhc3NpZ25tZW50LgoKIElmIG1vcmUgdGhh
biBvbmUgZmlsdGVyIGNyaXRlcmlhIGlzIHNwZWNpZmllZCBiZWxvdywgYSBWTSB3aWxsIGJl
IHNlbGVjdGVkCiBpZiBhbmQgb25seSBpZiBpdCBzYXRpc2ZpZXMgYWxsIG9mIHRoZW0uCgoM
CgUEAAMBARIDRwoYCicKBgQAAwEDABIESQRVBRoXIFZNIGludmVudG9yeSBkZXRhaWxzLgoK
DgoHBAADAQMAARIDSQwVCi4KCAQAAwEDAAIAEgNLBkgaHSBSZXF1aXJlZC4gVGhlIE9TIHNo
b3J0IG5hbWUKChAKCQQAAwEDAAIABRIDSwYMChAKCQQAAwEDAAIAARIDSw0aChAKCQQAAwED
AAIAAxIDSx0eChAKCQQAAwEDAAIACBIDSx9HChMKDAQAAwEDAAIACJwIABIDSyBGCpECCggE
AAMBAwACARIDVAYcGv8BIFRoZSBPUyB2ZXJzaW9uCgogUHJlZml4IG1hdGNoZXMgYXJlIHN1
cHBvcnRlZCBpZiBhc3RlcmlzaygqKSBpcyBwcm92aWRlZCBhcyB0aGUKIGxhc3QgY2hhcmFj
dGVyLiBGb3IgZXhhbXBsZSwgdG8gbWF0Y2ggYWxsIHZlcnNpb25zIHdpdGggYSBtYWpvcgog
dmVyc2lvbiBvZiBgN2AsIHNwZWNpZnkgdGhlIGZvbGxvd2luZyB2YWx1ZSBmb3IgdGhpcyBm
aWVsZCBgNy4qYAoKIEFuIGVtcHR5IHN0cmluZyBtYXRjaGVzIGFsbCBPUyB2ZXJzaW9ucy4K
ChAKCQQAAwEDAAIBBRIDVAYMChAKCQQAAwEDAAIBARIDVA0XChAKCQQAAwEDAAIBAxIDVBob
ClkKBgQAAwECABIDWQQRGkogVGFyZ2V0IGFsbCBWTXMgaW4gdGhlIHByb2plY3QuIElmIHRy
dWUsIG5vIG90aGVyIGNyaXRlcmlhIGlzCiBwZXJtaXR0ZWQuCgoOCgcEAAMBAgAFEgNZBAgK
DgoHBAADAQIAARIDWQkMCg4KBwQAAwECAAMSA1kPEAqvAQoGBAADAQIBEgNfBCsanwEgTGlz
dCBvZiBsYWJlbCBzZXRzIHVzZWQgZm9yIFZNIGluY2x1c2lvbi4KCiBJZiB0aGUgbGlzdCBo
YXMgbW9yZSB0aGFuIG9uZSBgTGFiZWxTZXRgLCB0aGUgVk0gaXMgaW5jbHVkZWQgaWYgYW55
CiBvZiB0aGUgbGFiZWwgc2V0cyBhcmUgYXBwbGljYWJsZSBmb3IgdGhlIFZNLgoKDgoHBAAD
AQIBBBIDXwQMCg4KBwQAAwECAQYSA18NFQoOCgcEAAMBAgEBEgNfFiYKDgoHBAADAQIBAxID
XykqCq4BCgYEAAMBAgISA2UEKxqeASBMaXN0IG9mIGxhYmVsIHNldHMgdXNlZCBmb3IgVk0g
ZXhjbHVzaW9uLgoKIElmIHRoZSBsaXN0IGhhcyBtb3JlIHRoYW4gb25lIGxhYmVsIHNldCwg
dGhlIFZNIGlzIGV4Y2x1ZGVkIGlmIGFueQogb2YgdGhlIGxhYmVsIHNldHMgYXJlIGFwcGxp
Y2FibGUgZm9yIHRoZSBWTS4KCg4KBwQAAwECAgQSA2UEDAoOCgcEAAMBAgIGEgNlDRUKDgoH
BAADAQICARIDZRYmCg4KBwQAAwECAgMSA2UpKgqRAQoGBAADAQIDEgNrBCcagQEgTGlzdCBv
ZiBpbnZlbnRvcmllcyB0byBzZWxlY3QgVk1zLgoKIEEgVk0gaXMgc2VsZWN0ZWQgaWYgaXRz
IGludmVudG9yeSBkYXRhIG1hdGNoZXMgYXQgbGVhc3Qgb25lIG9mIHRoZQogZm9sbG93aW5n
IGludmVudG9yaWVzLgoKDgoHBAADAQIDBBIDawQMCg4KBwQAAwECAwYSA2sNFgoOCgcEAAMB
AgMBEgNrFyIKDgoHBAADAQIDAxIDayUmCmIKBAQAAwISBHACfQMaVCBNZXNzYWdlIHRvIGNv
bmZpZ3VyZSB0aGUgcm9sbG91dCBhdCB0aGUgem9uYWwgbGV2ZWwgZm9yIHRoZSBPUyBwb2xp
Y3kKIGFzc2lnbm1lbnQuCgoMCgUEAAMCARIDcAoRCm8KBgQAAwICABIEcwR0MRpfIFJlcXVp
cmVkLiBUaGUgbWF4aW11bSBudW1iZXIgKG9yIHBlcmNlbnRhZ2UpIG9mIFZNcyBwZXIgem9u
ZSB0byBkaXNydXB0CiBhdCBhbnkgZ2l2ZW4gbW9tZW50LgoKDgoHBAADAgIABhIDcwQSCg4K
BwQAAwICAAESA3MTJAoOCgcEAAMCAgADEgNzJygKDgoHBAADAgIACBIDdAgwChEKCgQAAwIC
AAicCAASA3QJLwqvAgoGBAADAgIBEgR7BHwxGp4CIFJlcXVpcmVkLiBUaGlzIGRldGVybWlu
ZXMgdGhlIG1pbmltdW0gZHVyYXRpb24gb2YgdGltZSB0byB3YWl0IGFmdGVyIHRoZQogY29u
ZmlndXJhdGlvbiBjaGFuZ2VzIGFyZSBhcHBsaWVkIHRocm91Z2ggdGhlIGN1cnJlbnQgcm9s
bG91dC4gQQogVk0gY29udGludWVzIHRvIGNvdW50IHRvd2FyZHMgdGhlIGBkaXNydXB0aW9u
X2J1ZGdldGAgYXQgbGVhc3QKIHVudGlsIHRoaXMgZHVyYXRpb24gb2YgdGltZSBoYXMgcGFz
c2VkIGFmdGVyIGNvbmZpZ3VyYXRpb24gY2hhbmdlcyBhcmUKIGFwcGxpZWQuCgoOCgcEAAMC
AgEGEgN7BBwKDgoHBAADAgIBARIDex0uCg4KBwQAAwICAQMSA3sxMgoOCgcEAAMCAgEIEgN8
CDAKEQoKBAADAgIBCJwIABIDfAkvCjQKBAQABAASBoABAo8BAxokIE9TIHBvbGljeSBhc3Np
Z25tZW50IHJvbGxvdXQgc3RhdGUKCg0KBQQABAABEgSAAQcTCh8KBgQABAACABIEggEEIhoP
IEludmFsaWQgdmFsdWUKCg8KBwQABAACAAESBIIBBB0KDwoHBAAEAAIAAhIEggEgIQotCgYE
AAQAAgESBIUBBBQaHSBUaGUgcm9sbG91dCBpcyBpbiBwcm9ncmVzcy4KCg8KBwQABAACAQES
BIUBBA8KDwoHBAAEAAIBAhIEhQESEwoxCgYEAAQAAgISBIgBBBMaISBUaGUgcm9sbG91dCBp
cyBiZWluZyBjYW5jZWxsZWQuCgoPCgcEAAQAAgIBEgSIAQQOCg8KBwQABAACAgISBIgBERIK
KwoGBAAEAAIDEgSLAQQSGhsgVGhlIHJvbGxvdXQgaXMgY2FuY2VsbGVkLgoKDwoHBAAEAAID
ARIEiwEEDQoPCgcEAAQAAgMCEgSLARARCjkKBgQABAACBBIEjgEEEhopIFRoZSByb2xsb3V0
IGhhcyBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDwoHBAAEAAIEARIEjgEEDQoPCgcEAAQA
AgQCEgSOARARCsoBCgQEAAIAEgSXAQISGrsBIFJlc291cmNlIG5hbWUuCgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vb3NQb2xp
Y3lBc3NpZ25tZW50cy97b3NfcG9saWN5X2Fzc2lnbm1lbnRfaWR9YAoKIFRoaXMgZmllbGQg
aXMgaWdub3JlZCB3aGVuIHlvdSBjcmVhdGUgYW4gT1MgcG9saWN5IGFzc2lnbm1lbnQuCgoN
CgUEAAIABRIElwECCAoNCgUEAAIAARIElwEJDQoNCgUEAAIAAxIElwEQEQprCgQEAAIBEgSb
AQIZGl0gT1MgcG9saWN5IGFzc2lnbm1lbnQgZGVzY3JpcHRpb24uCiBMZW5ndGggb2YgdGhl
IGRlc2NyaXB0aW9uIGlzIGxpbWl0ZWQgdG8gMTAyNCBjaGFyYWN0ZXJzLgoKDQoFBAACAQUS
BJsBAggKDQoFBAACAQESBJsBCRQKDQoFBAACAQMSBJsBFxgKRwoEBAACAhIEngECTRo5IFJl
cXVpcmVkLiBMaXN0IG9mIE9TIHBvbGljaWVzIHRvIGJlIGFwcGxpZWQgdG8gdGhlIFZNcy4K
Cg0KBQQAAgIEEgSeAQIKCg0KBQQAAgIGEgSeAQsTCg0KBQQAAgIBEgSeARQfCg0KBQQAAgID
EgSeASIjCg0KBQQAAgIIEgSeASRMChAKCAQAAgIInAgAEgSeASVLCi8KBAQAAgMSBKEBAk4a
ISBSZXF1aXJlZC4gRmlsdGVyIHRvIHNlbGVjdCBWTXMuCgoNCgUEAAIDBhIEoQECEAoNCgUE
AAIDARIEoQERIAoNCgUEAAIDAxIEoQEjJAoNCgUEAAIDCBIEoQElTQoQCggEAAIDCJwIABIE
oQEmTArMAgoEBAACBBIEqwECPxq9AiBSZXF1aXJlZC4gUm9sbG91dCB0byBkZXBsb3kgdGhl
IE9TIHBvbGljeSBhc3NpZ25tZW50LgogQSByb2xsb3V0IGlzIHRyaWdnZXJlZCBpbiB0aGUg
Zm9sbG93aW5nIHNpdHVhdGlvbnM6CiAxKSBPU1BvbGljeUFzc2lnbm1lbnQgaXMgY3JlYXRl
ZC4KIDIpIE9TUG9saWN5QXNzaWdubWVudCBpcyB1cGRhdGVkIGFuZCB0aGUgdXBkYXRlIGNv
bnRhaW5zIGNoYW5nZXMgdG8gb25lIG9mCiB0aGUgZm9sbG93aW5nIGZpZWxkczoKICAgIC0g
aW5zdGFuY2VfZmlsdGVyCiAgICAtIG9zX3BvbGljaWVzCiAzKSBPU1BvbGljeUFzc2lnbm1l
bnQgaXMgZGVsZXRlZC4KCg0KBQQAAgQGEgSrAQIJCg0KBQQAAgQBEgSrAQoRCg0KBQQAAgQD
EgSrARQVCg0KBQQAAgQIEgSrARY+ChAKCAQAAgQInAgAEgSrARc9CpEBCgQEAAIFEgSwAQJF
GoIBIE91dHB1dCBvbmx5LiBUaGUgYXNzaWdubWVudCByZXZpc2lvbiBJRAogQSBuZXcgcmV2
aXNpb24gaXMgY29tbWl0dGVkIHdoZW5ldmVyIGEgcm9sbG91dCBpcyB0cmlnZ2VyZWQgZm9y
IGEgT1MgcG9saWN5CiBhc3NpZ25tZW50CgoNCgUEAAIFBRIEsAECCAoNCgUEAAIFARIEsAEJ
FAoNCgUEAAIFAxIEsAEXGAoNCgUEAAIFCBIEsAEZRAoQCggEAAIFCJwIABIEsAEaQwpLCgQE
AAIGEgazAQK0ATIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB0aGF0IHRoZSByZXZp
c2lvbiB3YXMgY3JlYXRlZC4KCg0KBQQAAgYGEgSzAQIbCg0KBQQAAgYBEgSzARwwCg0KBQQA
AgYDEgSzATM0Cg0KBQQAAgYIEgS0AQYxChAKCAQAAgYInAgAEgS0AQcwCngKBAQAAgcSBLgB
AhIaaiBUaGUgZXRhZyBmb3IgdGhpcyBPUyBwb2xpY3kgYXNzaWdubWVudC4KIElmIHRoaXMg
aXMgcHJvdmlkZWQgb24gdXBkYXRlLCBpdCBtdXN0IG1hdGNoIHRoZSBzZXJ2ZXIncyBldGFn
LgoKDQoFBAACBwUSBLgBAggKDQoFBAACBwESBLgBCQ0KDQoFBAACBwMSBLgBEBEKPwoEBAAC
CBIEuwECTRoxIE91dHB1dCBvbmx5LiBPUyBwb2xpY3kgYXNzaWdubWVudCByb2xsb3V0IHN0
YXRlCgoNCgUEAAIIBhIEuwECDgoNCgUEAAIIARIEuwEPHAoNCgUEAAIIAxIEuwEfIAoNCgUE
AAIICBIEuwEhTAoQCggEAAIICJwIABIEuwEiSwqNAgoEBAACCRIEwgECQRr+ASBPdXRwdXQg
b25seS4gSW5kaWNhdGVzIHRoYXQgdGhpcyByZXZpc2lvbiBoYXMgYmVlbiBzdWNjZXNzZnVs
bHkgcm9sbGVkIG91dAogaW4gdGhpcyB6b25lIGFuZCBuZXcgVk1zIHdpbGwgYmUgYXNzaWdu
ZWQgT1MgcG9saWNpZXMgZnJvbSB0aGlzIHJldmlzaW9uLgoKIEZvciBhIGdpdmVuIE9TIHBv
bGljeSBhc3NpZ25tZW50LCB0aGVyZSBpcyBvbmx5IG9uZSByZXZpc2lvbiB3aXRoIGEgdmFs
dWUKIG9mIGB0cnVlYCBmb3IgdGhpcyBmaWVsZC4KCg0KBQQAAgkFEgTCAQIGCg0KBQQAAgkB
EgTCAQcPCg0KBQQAAgkDEgTCARIUCg0KBQQAAgkIEgTCARVAChAKCAQAAgkInAgAEgTCARY/
ClsKBAQAAgoSBMUBAkAaTSBPdXRwdXQgb25seS4gSW5kaWNhdGVzIHRoYXQgdGhpcyByZXZp
c2lvbiBkZWxldGVzIHRoZSBPUyBwb2xpY3kgYXNzaWdubWVudC4KCg0KBQQAAgoFEgTFAQIG
Cg0KBQQAAgoBEgTFAQcOCg0KBQQAAgoDEgTFARETCg0KBQQAAgoIEgTFARQ/ChAKCAQAAgoI
nAgAEgTFARU+CrMBCgQEAAILEgTLAQJEGqQBIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgdGhh
dCByZWNvbmNpbGlhdGlvbiBpcyBpbiBwcm9ncmVzcyBmb3IgdGhlIHJldmlzaW9uLgogVGhp
cyB2YWx1ZSBpcyBgdHJ1ZWAgd2hlbiB0aGUgYHJvbGxvdXRfc3RhdGVgIGlzIG9uZSBvZjoK
ICogSU5fUFJPR1JFU1MKICogQ0FOQ0VMTElORwoKDQoFBAACCwUSBMsBAgYKDQoFBAACCwES
BMsBBxIKDQoFBAACCwMSBMsBFRcKDQoFBAACCwgSBMsBGEMKEAoIBAACCwicCAASBMsBGUIK
XwoEBAACDBIEzwECPhpRIE91dHB1dCBvbmx5LiBTZXJ2ZXIgZ2VuZXJhdGVkIHVuaXF1ZSBp
ZCBmb3IgdGhlIE9TIHBvbGljeSBhc3NpZ25tZW50CiByZXNvdXJjZS4KCg0KBQQAAgwFEgTP
AQIICg0KBQQAAgwBEgTPAQkMCg0KBQQAAgwDEgTPAQ8RCg0KBQQAAgwIEgTPARI9ChAKCAQA
AgwInAgAEgTPARM8CooBCgIEARIG1AEAiQIBGnwgT1MgcG9saWN5IGFzc2lnbm1lbnQgb3Bl
cmF0aW9uIG1ldGFkYXRhIHByb3ZpZGVkIGJ5IE9TIHBvbGljeSBhc3NpZ25tZW50IEFQSQog
bWV0aG9kcyB0aGF0IHJldHVybiBsb25nIHJ1bm5pbmcgb3BlcmF0aW9ucy4KCgsKAwQBARIE
1AEIKwo2CgQEAQQAEgbWAQLiAQMaJiBUaGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgQVBJIG1l
dGhvZC4KCg0KBQQBBAABEgTWAQcQCh8KBgQBBAACABIE2AEEHxoPIEludmFsaWQgdmFsdWUK
Cg8KBwQBBAACAAESBNgBBBoKDwoHBAEEAAIAAhIE2AEdHgo4CgYEAQQAAgESBNsBBA8aKCBD
cmVhdGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgQVBJIG1ldGhvZAoKDwoHBAEEAAIBARIE2wEE
CgoPCgcEAQQAAgECEgTbAQ0OCjgKBgQBBAACAhIE3gEEDxooIFVwZGF0ZSBPUyBwb2xpY3kg
YXNzaWdubWVudCBBUEkgbWV0aG9kCgoPCgcEAQQAAgIBEgTeAQQKCg8KBwQBBAACAgISBN4B
DQ4KOAoGBAEEAAIDEgThAQQPGiggRGVsZXRlIE9TIHBvbGljeSBhc3NpZ25tZW50IEFQSSBt
ZXRob2QKCg8KBwQBBAACAwESBOEBBAoKDwoHBAEEAAIDAhIE4QENDgomCgQEAQQBEgblAQL0
AQMaFiBTdGF0ZSBvZiB0aGUgcm9sbG91dAoKDQoFBAEEAQESBOUBBxMKHwoGBAEEAQIAEgTn
AQQiGg8gSW52YWxpZCB2YWx1ZQoKDwoHBAEEAQIAARIE5wEEHQoPCgcEAQQBAgACEgTnASAh
Ci0KBgQBBAECARIE6gEEFBodIFRoZSByb2xsb3V0IGlzIGluIHByb2dyZXNzLgoKDwoHBAEE
AQIBARIE6gEEDwoPCgcEAQQBAgECEgTqARITCjEKBgQBBAECAhIE7QEEExohIFRoZSByb2xs
b3V0IGlzIGJlaW5nIGNhbmNlbGxlZC4KCg8KBwQBBAECAgESBO0BBA4KDwoHBAEEAQICAhIE
7QEREgorCgYEAQQBAgMSBPABBBIaGyBUaGUgcm9sbG91dCBpcyBjYW5jZWxsZWQuCgoPCgcE
AQQBAgMBEgTwAQQNCg8KBwQBBAECAwISBPABEBEKOQoGBAEEAQIEEgTzAQQSGikgVGhlIHJv
bGxvdXQgaGFzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoPCgcEAQQBAgQBEgTzAQQNCg8K
BwQBBAECBAISBPMBEBEKvAEKBAQBAgASBvoBAvwBBRqrASBSZWZlcmVuY2UgdG8gdGhlIGBP
U1BvbGljeUFzc2lnbm1lbnRgIEFQSSByZXNvdXJjZS4KCiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vc1BvbGljeUFzc2lnbm1l
bnRzL3tvc19wb2xpY3lfYXNzaWdubWVudF9pZEByZXZpc2lvbl9pZH1gCgoNCgUEAQIABRIE
+gECCAoNCgUEAQIAARIE+gEJHQoNCgUEAQIAAxIE+gEgIQoPCgUEAQIACBIG+gEi/AEEChEK
BwQBAgAInwgSBvoBI/wBAwo0CgQEAQIBEgT/AQIbGiYgVGhlIE9TIHBvbGljeSBhc3NpZ25t
ZW50IEFQSSBtZXRob2QuCgoNCgUEAQIBBhIE/wECCwoNCgUEAQIBARIE/wEMFgoNCgUEAQIB
AxIE/wEZGgokCgQEAQICEgSCAgIhGhYgU3RhdGUgb2YgdGhlIHJvbGxvdXQKCg0KBQQBAgIG
EgSCAgIOCg0KBQQBAgIBEgSCAg8cCg0KBQQBAgIDEgSCAh8gCiIKBAQBAgMSBIUCAjMaFCBS
b2xsb3V0IHN0YXJ0IHRpbWUKCg0KBQQBAgMGEgSFAgIbCg0KBQQBAgMBEgSFAhwuCg0KBQQB
AgMDEgSFAjEyCiMKBAQBAgQSBIgCAjQaFSBSb2xsb3V0IHVwZGF0ZSB0aW1lCgoNCgUEAQIE
BhIEiAICGwoNCgUEAQIEARIEiAIcLwoNCgUEAQIEAxIEiAIyMwpDCgIEAhIGjAIAowIBGjUg
QSByZXF1ZXN0IG1lc3NhZ2UgdG8gY3JlYXRlIGFuIE9TIHBvbGljeSBhc3NpZ25tZW50CgoL
CgMEAgESBIwCCCcKagoEBAICABIGjwIClAIEGlogUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVz
b3VyY2UgbmFtZSBpbiB0aGUgZm9ybToKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufQoKDQoFBAICAAUSBI8CAggKDQoFBAICAAESBI8CCQ8KDQoFBAICAAMSBI8C
EhMKDwoFBAICAAgSBo8CFJQCAwoQCggEAgIACJwIABIEkAIEKgoRCgcEAgIACJ8IEgaRAgST
AgUKQwoEBAICARIGlwICmAIvGjMgUmVxdWlyZWQuIFRoZSBPUyBwb2xpY3kgYXNzaWdubWVu
dCB0byBiZSBjcmVhdGVkLgoKDQoFBAICAQYSBJcCAhQKDQoFBAICAQESBJcCFSkKDQoFBAIC
AQMSBJcCLC0KDQoFBAICAQgSBJgCBi4KEAoIBAICAQicCAASBJgCBy0KxQIKBAQCAgISBKIC
Ak4atgIgUmVxdWlyZWQuIFRoZSBsb2dpY2FsIG5hbWUgb2YgdGhlIE9TIHBvbGljeSBhc3Np
Z25tZW50IGluIHRoZSBwcm9qZWN0CiB3aXRoIHRoZSBmb2xsb3dpbmcgcmVzdHJpY3Rpb25z
OgoKICogTXVzdCBjb250YWluIG9ubHkgbG93ZXJjYXNlIGxldHRlcnMsIG51bWJlcnMsIGFu
ZCBoeXBoZW5zLgogKiBNdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCiAqIE11c3QgYmUgYmV0
d2VlbiAxLTYzIGNoYXJhY3RlcnMuCiAqIE11c3QgZW5kIHdpdGggYSBudW1iZXIgb3IgYSBs
ZXR0ZXIuCiAqIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgcHJvamVjdC4KCg0KBQQCAgIF
EgSiAgIICg0KBQQCAgIBEgSiAgkgCg0KBQQCAgIDEgSiAiMkCg0KBQQCAgIIEgSiAiVNChAK
CAQCAgIInAgAEgSiAiZMCkMKAgQDEgamAgCvAgEaNSBBIHJlcXVlc3QgbWVzc2FnZSB0byB1
cGRhdGUgYW4gT1MgcG9saWN5IGFzc2lnbm1lbnQKCgsKAwQDARIEpgIIJwo9CgQEAwIAEgao
AgKpAi8aLSBSZXF1aXJlZC4gVGhlIHVwZGF0ZWQgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgoN
CgUEAwIABhIEqAICFAoNCgUEAwIAARIEqAIVKQoNCgUEAwIAAxIEqAIsLQoNCgUEAwIACBIE
qQIGLgoQCggEAwIACJwIABIEqQIHLQpnCgQEAwIBEgatAgKuAi8aVyBPcHRpb25hbC4gRmll
bGQgbWFzayB0aGF0IGNvbnRyb2xzIHdoaWNoIGZpZWxkcyBvZiB0aGUgYXNzaWdubWVudCBz
aG91bGQgYmUKIHVwZGF0ZWQuCgoNCgUEAwIBBhIErQICGwoNCgUEAwIBARIErQIcJwoNCgUE
AwIBAxIErQIqKwoNCgUEAwIBCBIErgIGLgoQCggEAwIBCJwIABIErgIHLQpACgIEBBIGsgIA
vQIBGjIgQSByZXF1ZXN0IG1lc3NhZ2UgdG8gZ2V0IGFuIE9TIHBvbGljeSBhc3NpZ25tZW50
CgoLCgMEBAESBLICCCQKtAEKBAQEAgASBrcCArwCBBqjASBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgogRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vc1BvbGljeUFzc2lnbm1lbnRzL3tv
c19wb2xpY3lfYXNzaWdubWVudH1Ae3JldmlzaW9uSWR9YAoKDQoFBAQCAAUSBLcCAggKDQoF
BAQCAAESBLcCCQ0KDQoFBAQCAAMSBLcCEBEKDwoFBAQCAAgSBrcCErwCAwoQCggEBAIACJwI
ABIEuAIEKgoRCgcEBAIACJ8IEga5AgS7AgUKVQoCBAUSBsACANACARpHIEEgcmVxdWVzdCBt
ZXNzYWdlIHRvIGxpc3QgT1MgcG9saWN5IGFzc2lnbm1lbnRzIGZvciBhIHBhcmVudCByZXNv
dXJjZQoKCwoDBAUBEgTAAggmCjUKBAQFAgASBsICAscCBBolIFJlcXVpcmVkLiBUaGUgcGFy
ZW50IHJlc291cmNlIG5hbWUuCgoNCgUEBQIABRIEwgICCAoNCgUEBQIAARIEwgIJDwoNCgUE
BQIAAxIEwgISEwoPCgUEBQIACBIGwgIUxwIDChAKCAQFAgAInAgAEgTDAgQqChEKBwQFAgAI
nwgSBsQCBMYCBQo8CgQEBQIBEgTKAgIWGi4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGFzc2ln
bm1lbnRzIHRvIHJldHVybi4KCg0KBQQFAgEFEgTKAgIHCg0KBQQFAgEBEgTKAggRCg0KBQQF
AgEDEgTKAhQVCpgBCgQEBQICEgTPAgIYGokBIEEgcGFnaW5hdGlvbiB0b2tlbiByZXR1cm5l
ZCBmcm9tIGEgcHJldmlvdXMgY2FsbCB0bwogYExpc3RPU1BvbGljeUFzc2lnbm1lbnRzYCB0
aGF0IGluZGljYXRlcyB3aGVyZSB0aGlzIGxpc3Rpbmcgc2hvdWxkIGNvbnRpbnVlCiBmcm9t
LgoKDQoFBAUCAgUSBM8CAggKDQoFBAUCAgESBM8CCRMKDQoFBAUCAgMSBM8CFhcKUgoCBAYS
BtMCANkCARpEIEEgcmVzcG9uc2UgbWVzc2FnZSBmb3IgbGlzdGluZyBhbGwgYXNzaWdubWVu
dHMgdW5kZXIgZ2l2ZW4gcGFyZW50LgoKCwoDBAYBEgTTAggnCicKBAQGAgASBNUCAjgaGSBU
aGUgbGlzdCBvZiBhc3NpZ25tZW50cwoKDQoFBAYCAAQSBNUCAgoKDQoFBAYCAAYSBNUCCx0K
DQoFBAYCAAESBNUCHjMKDQoFBAYCAAMSBNUCNjcKWAoEBAYCARIE2AICHRpKIFRoZSBwYWdp
bmF0aW9uIHRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgT1MgcG9saWN5IGFz
c2lnbm1lbnRzLgoKDQoFBAYCAQUSBNgCAggKDQoFBAYCAQESBNgCCRgKDQoFBAYCAQMSBNgC
GxwKTgoCBAcSBtwCAOwCARpAIEEgcmVxdWVzdCBtZXNzYWdlIHRvIGxpc3QgcmV2aXNpb25z
IGZvciBhIE9TIHBvbGljeSBhc3NpZ25tZW50CgoLCgMEBwESBNwCCC4KVwoEBAcCABIG3gIC
4wIEGkcgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBPUyBwb2xpY3kgYXNzaWdubWVudCB0
byBsaXN0IHJldmlzaW9ucyBmb3IuCgoNCgUEBwIABRIE3gICCAoNCgUEBwIAARIE3gIJDQoN
CgUEBwIAAxIE3gIQEQoPCgUEBwIACBIG3gIS4wIDChAKCAQHAgAInAgAEgTfAgQqChEKBwQH
AgAInwgSBuACBOICBQo6CgQEBwIBEgTmAgIWGiwgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJl
dmlzaW9ucyB0byByZXR1cm4uCgoNCgUEBwIBBRIE5gICBwoNCgUEBwIBARIE5gIIEQoNCgUE
BwIBAxIE5gIUFQqgAQoEBAcCAhIE6wICGBqRASBBIHBhZ2luYXRpb24gdG9rZW4gcmV0dXJu
ZWQgZnJvbSBhIHByZXZpb3VzIGNhbGwgdG8KIGBMaXN0T1NQb2xpY3lBc3NpZ25tZW50UmV2
aXNpb25zYCB0aGF0IGluZGljYXRlcyB3aGVyZSB0aGlzIGxpc3Rpbmcgc2hvdWxkCiBjb250
aW51ZSBmcm9tLgoKDQoFBAcCAgUSBOsCAggKDQoFBAcCAgESBOsCCRMKDQoFBAcCAgMSBOsC
FhcKWAoCBAgSBu8CAPYCARpKIEEgcmVzcG9uc2UgbWVzc2FnZSBmb3IgbGlzdGluZyBhbGwg
cmV2aXNpb25zIGZvciBhIE9TIHBvbGljeSBhc3NpZ25tZW50LgoKCwoDBAgBEgTvAggvCjIK
BAQIAgASBPECAjgaJCBUaGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgcmV2aXNpb25zCgoNCgUE
CAIABBIE8QICCgoNCgUECAIABhIE8QILHQoNCgUECAIAARIE8QIeMwoNCgUECAIAAxIE8QI2
NwpiCgQECAIBEgT1AgIdGlQgVGhlIHBhZ2luYXRpb24gdG9rZW4gdG8gcmV0cmlldmUgdGhl
IG5leHQgcGFnZSBvZiBPUyBwb2xpY3kgYXNzaWdubWVudAogcmV2aXNpb25zLgoKDQoFBAgC
AQUSBPUCAggKDQoFBAgCAQESBPUCCRgKDQoFBAgCAQMSBPUCGxwKRgoCBAkSBvkCAIEDARo4
IEEgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIE9TIHBvbGljeSBhc3NpZ25tZW50
LgoKCwoDBAkBEgT5AggnCk4KBAQJAgASBvsCAoADBBo+IFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgdG8gYmUgZGVsZXRlZAoKDQoFBAkCAAUSBPsC
AggKDQoFBAkCAAESBPsCCQ0KDQoFBAkCAAMSBPsCEBEKDwoFBAkCAAgSBvsCEoADAwoQCggE
CQIACJwIABIE/AIEKgoRCgcECQIACJ8IEgb9AgT/AgViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment ===
    # Fields for OSPolicyAssignment
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: os_policies Type: 11 (.google.cloud.osconfig.v1.OSPolicy)
    # Field: instance_filter Type: 11 (.google.cloud.osconfig.v1.OSPolicyAssignment.InstanceFilter)
    # Field: rollout Type: 11 (.google.cloud.osconfig.v1.OSPolicyAssignment.Rollout)
    # Field: revision_id Type: 9 ()
    # Field: revision_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: rollout_state Type: 14 (.google.cloud.osconfig.v1.OSPolicyAssignment.RolloutState)
    # Field: baseline Type: 8 ()
    # Field: deleted Type: 8 ()
    # Field: reconciling Type: 8 ()
    # Field: uid Type: 9 ()

# Enum: OSPolicyAssignment::RolloutState
our $OSPolicyAssignment_ROLLOUT_STATE_UNSPECIFIED = 0;
our $OSPolicyAssignment_IN_PROGRESS = 1;
our $OSPolicyAssignment_CANCELLING = 2;
our $OSPolicyAssignment_CANCELLED = 3;
our $OSPolicyAssignment_SUCCEEDED = 4;

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata ===
    # Fields for OSPolicyAssignmentOperationMetadata
    # Field: os_policy_assignment Type: 9 ()
    # Field: api_method Type: 14 (.google.cloud.osconfig.v1.OSPolicyAssignmentOperationMetadata.APIMethod)
    # Field: rollout_state Type: 14 (.google.cloud.osconfig.v1.OSPolicyAssignmentOperationMetadata.RolloutState)
    # Field: rollout_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: rollout_update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: OSPolicyAssignmentOperationMetadata::APIMethod
our $OSPolicyAssignmentOperationMetadata_API_METHOD_UNSPECIFIED = 0;
our $OSPolicyAssignmentOperationMetadata_CREATE = 1;
our $OSPolicyAssignmentOperationMetadata_UPDATE = 2;
our $OSPolicyAssignmentOperationMetadata_DELETE = 3;

# Enum: OSPolicyAssignmentOperationMetadata::RolloutState
our $OSPolicyAssignmentOperationMetadata_ROLLOUT_STATE_UNSPECIFIED = 0;
our $OSPolicyAssignmentOperationMetadata_IN_PROGRESS = 1;
our $OSPolicyAssignmentOperationMetadata_CANCELLING = 2;
our $OSPolicyAssignmentOperationMetadata_CANCELLED = 3;
our $OSPolicyAssignmentOperationMetadata_SUCCEEDED = 4;

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest ===
    # Fields for CreateOSPolicyAssignmentRequest
    # Field: parent Type: 9 ()
    # Field: os_policy_assignment Type: 11 (.google.cloud.osconfig.v1.OSPolicyAssignment)
    # Field: os_policy_assignment_id Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest ===
    # Fields for UpdateOSPolicyAssignmentRequest
    # Field: os_policy_assignment Type: 11 (.google.cloud.osconfig.v1.OSPolicyAssignment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::GetOSPolicyAssignmentRequest ===
    # Fields for GetOSPolicyAssignmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsRequest ===
    # Fields for ListOSPolicyAssignmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsResponse ===
    # Fields for ListOSPolicyAssignmentsResponse
    # Field: os_policy_assignments Type: 11 (.google.cloud.osconfig.v1.OSPolicyAssignment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest ===
    # Fields for ListOSPolicyAssignmentRevisionsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse ===
    # Fields for ListOSPolicyAssignmentRevisionsResponse
    # Field: os_policy_assignments Type: 11 (.google.cloud.osconfig.v1.OSPolicyAssignment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest ===
    # Fields for DeleteOSPolicyAssignmentRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1::OsPolicyAssignments - Compiled Protocol Buffers messages for google/cloud/osconfig/v1/os_policy_assignments.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1::OsPolicyAssignments;

    my $msg = Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment->new({
        name => $name,
        description => $description,
        os_policies => $os_policies,
        instance_filter => $instance_filter,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1/os_policy_assignments.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment

OS policy assignment is an API resource that is used to
apply a set of OS policies to a dynamically targeted group of Compute Engine
VM instances.

An OS policy is used to define the desired state configuration for a
Compute Engine VM instance through a set of configuration resources that
provide capabilities such as installing or removing software packages, or
executing a script.

For more information, see [OS policy and OS policy
assignment](https://cloud.google.com/compute/docs/os-configuration-management/working-with-os-policies).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource name.

Format:
`projects/{project_number}/locations/{location}/osPolicyAssignments/{os_policy_assignment_id}`

This field is ignored when you create an OS policy assignment.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

OS policy assignment description.
Length of the description is limited to 1024 characters.

=item * C<< $msg->os_policies() >> / C<< $msg->os_policies($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicy::OSPolicy>)

Required. List of OS policies to be applied to the VMs.

=item * C<< $msg->instance_filter() >> / C<< $msg->instance_filter($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter>)

Required. Filter to select VMs.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::Rollout>)

Required. Rollout to deploy the OS policy assignment.
A rollout is triggered in the following situations:
1) OSPolicyAssignment is created.
2) OSPolicyAssignment is updated and the update contains changes to one of
the following fields:
   - instance_filter
   - os_policies
3) OSPolicyAssignment is deleted.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Output only. The assignment revision ID
A new revision is committed whenever a rollout is triggered for a OS policy
assignment

=item * C<< $msg->revision_create_time() >> / C<< $msg->revision_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp that the revision was created.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

The etag for this OS policy assignment.
If this is provided on update, it must match the server's etag.

=item * C<< $msg->rollout_state() >> / C<< $msg->rollout_state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1::OSPolicyAssignment::RolloutState>)

Output only. OS policy assignment rollout state

=item * C<< $msg->baseline() >> / C<< $msg->baseline($value) >>

Type: C<Bool>

Output only. Indicates that this revision has been successfully rolled out
in this zone and new VMs will be assigned OS policies from this revision.

For a given OS policy assignment, there is only one revision with a value
of `true` for this field.

=item * C<< $msg->deleted() >> / C<< $msg->deleted($value) >>

Type: C<Bool>

Output only. Indicates that this revision deletes the OS policy assignment.

=item * C<< $msg->reconciling() >> / C<< $msg->reconciling($value) >>

Type: C<Bool>

Output only. Indicates that reconciliation is in progress for the revision.
This value is `true` when the `rollout_state` is one of:
* IN_PROGRESS
* CANCELLING

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated unique id for the OS policy assignment
resource.

=back

=head3 Enum: OSPolicyAssignment::RolloutState

=over 4

=item * C<ROLLOUT_STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<CANCELLING> => C<2>

=item * C<CANCELLED> => C<3>

=item * C<SUCCEEDED> => C<4>

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata

OS policy assignment operation metadata provided by OS policy assignment API
methods that return long running operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignment() >> / C<< $msg->os_policy_assignment($value) >>

Type: C<String>

Reference to the `OSPolicyAssignment` API resource.

Format:
`projects/{project_number}/locations/{location}/osPolicyAssignments/{os_policy_assignment_id@revision_id}`

=item * C<< $msg->api_method() >> / C<< $msg->api_method($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1::OSPolicyAssignmentOperationMetadata::APIMethod>)

The OS policy assignment API method.

=item * C<< $msg->rollout_state() >> / C<< $msg->rollout_state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1::OSPolicyAssignmentOperationMetadata::RolloutState>)

State of the rollout

=item * C<< $msg->rollout_start_time() >> / C<< $msg->rollout_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Rollout start time

=item * C<< $msg->rollout_update_time() >> / C<< $msg->rollout_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Rollout update time

=back

=head3 Enum: OSPolicyAssignmentOperationMetadata::APIMethod

=over 4

=item * C<API_METHOD_UNSPECIFIED> => C<0>

=item * C<CREATE> => C<1>

=item * C<UPDATE> => C<2>

=item * C<DELETE> => C<3>

=back

=head3 Enum: OSPolicyAssignmentOperationMetadata::RolloutState

=over 4

=item * C<ROLLOUT_STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<CANCELLING> => C<2>

=item * C<CANCELLED> => C<3>

=item * C<SUCCEEDED> => C<4>

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest

A request message to create an OS policy assignment

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name in the form:
projects/{project}/locations/{location}

=item * C<< $msg->os_policy_assignment() >> / C<< $msg->os_policy_assignment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment>)

Required. The OS policy assignment to be created.

=item * C<< $msg->os_policy_assignment_id() >> / C<< $msg->os_policy_assignment_id($value) >>

Type: C<String>

Required. The logical name of the OS policy assignment in the project
with the following restrictions:

* Must contain only lowercase letters, numbers, and hyphens.
* Must start with a letter.
* Must be between 1-63 characters.
* Must end with a number or a letter.
* Must be unique within the project.

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest

A request message to update an OS policy assignment

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignment() >> / C<< $msg->os_policy_assignment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment>)

Required. The updated OS policy assignment.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask that controls which fields of the assignment should be
updated.

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::GetOSPolicyAssignmentRequest

A request message to get an OS policy assignment

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of OS policy assignment.

Format:
`projects/{project}/locations/{location}/osPolicyAssignments/{os_policy_assignment}@{revisionId}`

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsRequest

A request message to list OS policy assignments for a parent resource

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of assignments to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to
`ListOSPolicyAssignments` that indicates where this listing should continue
from.

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsResponse

A response message for listing all assignments under given parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignments() >> / C<< $msg->os_policy_assignments($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment>)

The list of assignments

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token to retrieve the next page of OS policy assignments.

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest

A request message to list revisions for a OS policy assignment

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the OS policy assignment to list revisions for.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of revisions to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to
`ListOSPolicyAssignmentRevisions` that indicates where this listing should
continue from.

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse

A response message for listing all revisions for a OS policy assignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignments() >> / C<< $msg->os_policy_assignments($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment>)

The OS policy assignment revisions

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token to retrieve the next page of OS policy assignment
revisions.

=back

=head2 Google::Cloud::Osconfig::V1::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest

A request message for deleting a OS policy assignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the OS policy assignment to be deleted

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
