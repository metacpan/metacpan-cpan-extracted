package Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments;

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
    eval { require Google::Cloud::Osconfig::V1alpha::OsPolicy };
    eval { require Google::Cloud::Osconfig::V1alpha::OsconfigCommon };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvb3Njb25maWcvdjFhbHBoYS9vc19wb2xpY3lfYXNzaWdubWVudHMu
cHJvdG8SHWdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xv
dWQvb3Njb25maWcvdjFhbHBoYS9vc19wb2xpY3kucHJvdG8aM2dvb2dsZS9jbG91ZC9vc2Nv
bmZpZy92MWFscGhhL29zY29uZmlnX2NvbW1vbi5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1
cmF0aW9uLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKODgoST1NQb2xpY3lBc3NpZ25tZW50EhIKBG5h
bWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEk0KC29z
X3BvbGljaWVzGAMgAygLMicuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuT1NQb2xp
Y3lCA+BBAlIKb3NQb2xpY2llcxJuCg9pbnN0YW5jZV9maWx0ZXIYBCABKAsyQC5nb29nbGUu
Y2xvdWQub3Njb25maWcudjFhbHBoYS5PU1BvbGljeUFzc2lnbm1lbnQuSW5zdGFuY2VGaWx0
ZXJCA+BBAlIOaW5zdGFuY2VGaWx0ZXISWAoHcm9sbG91dBgFIAEoCzI5Lmdvb2dsZS5jbG91
ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNzaWdubWVudC5Sb2xsb3V0QgPgQQJSB3Jv
bGxvdXQSJAoLcmV2aXNpb25faWQYBiABKAlCA+BBA1IKcmV2aXNpb25JZBJRChRyZXZpc2lv
bl9jcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IS
cmV2aXNpb25DcmVhdGVUaW1lEhIKBGV0YWcYCCABKAlSBGV0YWcSaAoNcm9sbG91dF9zdGF0
ZRgJIAEoDjI+Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNzaWdu
bWVudC5Sb2xsb3V0U3RhdGVCA+BBA1IMcm9sbG91dFN0YXRlEh8KCGJhc2VsaW5lGAogASgI
QgPgQQNSCGJhc2VsaW5lEh0KB2RlbGV0ZWQYCyABKAhCA+BBA1IHZGVsZXRlZBIlCgtyZWNv
bmNpbGluZxgMIAEoCEID4EEDUgtyZWNvbmNpbGluZxIVCgN1aWQYDSABKAlCA+BBA1IDdWlk
GqUBCghMYWJlbFNldBJeCgZsYWJlbHMYASADKAsyRi5nb29nbGUuY2xvdWQub3Njb25maWcu
djFhbHBoYS5PU1BvbGljeUFzc2lnbm1lbnQuTGFiZWxTZXQuTGFiZWxzRW50cnlSBmxhYmVs
cxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBGt0DCg5JbnN0YW5jZUZpbHRlchIQCgNhbGwYASABKAhSA2FsbBIoCg5vc19zaG9y
dF9uYW1lcxgCIAMoCUICGAFSDG9zU2hvcnROYW1lcxJlChBpbmNsdXNpb25fbGFiZWxzGAMg
AygLMjouZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuT1NQb2xpY3lBc3NpZ25tZW50
LkxhYmVsU2V0Ug9pbmNsdXNpb25MYWJlbHMSZQoQZXhjbHVzaW9uX2xhYmVscxgEIAMoCzI6
Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNzaWdubWVudC5MYWJl
bFNldFIPZXhjbHVzaW9uTGFiZWxzEmwKC2ludmVudG9yaWVzGAUgAygLMkouZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxYWxwaGEuT1NQb2xpY3lBc3NpZ25tZW50Lkluc3RhbmNlRmlsdGVy
LkludmVudG9yeVILaW52ZW50b3JpZXMaUwoJSW52ZW50b3J5EicKDW9zX3Nob3J0X25hbWUY
ASABKAlCA+BBAlILb3NTaG9ydE5hbWUSHQoKb3NfdmVyc2lvbhgCIAEoCVIJb3NWZXJzaW9u
GrYBCgdSb2xsb3V0El8KEWRpc3J1cHRpb25fYnVkZ2V0GAEgASgLMi0uZ29vZ2xlLmNsb3Vk
Lm9zY29uZmlnLnYxYWxwaGEuRml4ZWRPclBlcmNlbnRCA+BBAlIQZGlzcnVwdGlvbkJ1ZGdl
dBJKChFtaW5fd2FpdF9kdXJhdGlvbhgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
bkID4EECUg9taW5XYWl0RHVyYXRpb24ibAoMUm9sbG91dFN0YXRlEh0KGVJPTExPVVRfU1RB
VEVfVU5TUEVDSUZJRUQQABIPCgtJTl9QUk9HUkVTUxABEg4KCkNBTkNFTExJTkcQAhINCglD
QU5DRUxMRUQQAxINCglTVUNDRUVERUQQBDqEAepBgAEKKm9zY29uZmlnLmdvb2dsZWFwaXMu
Y29tL09TUG9saWN5QXNzaWdubWVudBJScHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L29zUG9saWN5QXNzaWdubWVudHMve29zX3BvbGljeV9hc3NpZ25tZW50fSK8
BQojT1NQb2xpY3lBc3NpZ25tZW50T3BlcmF0aW9uTWV0YWRhdGESYQoUb3NfcG9saWN5X2Fz
c2lnbm1lbnQYASABKAlCL/pBLAoqb3Njb25maWcuZ29vZ2xlYXBpcy5jb20vT1NQb2xpY3lB
c3NpZ25tZW50UhJvc1BvbGljeUFzc2lnbm1lbnQSawoKYXBpX21ldGhvZBgCIAEoDjJMLmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNzaWdubWVudE9wZXJhdGlv
bk1ldGFkYXRhLkFQSU1ldGhvZFIJYXBpTWV0aG9kEnQKDXJvbGxvdXRfc3RhdGUYAyABKA4y
Ty5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5PU1BvbGljeUFzc2lnbm1lbnRPcGVy
YXRpb25NZXRhZGF0YS5Sb2xsb3V0U3RhdGVSDHJvbGxvdXRTdGF0ZRJIChJyb2xsb3V0X3N0
YXJ0X3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhByb2xsb3V0U3Rh
cnRUaW1lEkoKE3JvbGxvdXRfdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUhFyb2xsb3V0VXBkYXRlVGltZSJLCglBUElNZXRob2QSGgoWQVBJX01FVEhP
RF9VTlNQRUNJRklFRBAAEgoKBkNSRUFURRABEgoKBlVQREFURRACEgoKBkRFTEVURRADImwK
DFJvbGxvdXRTdGF0ZRIdChlST0xMT1VUX1NUQVRFX1VOU1BFQ0lGSUVEEAASDwoLSU5fUFJP
R1JFU1MQARIOCgpDQU5DRUxMSU5HEAISDQoJQ0FOQ0VMTEVEEAMSDQoJU1VDQ0VFREVEEAQi
igIKH0NyZWF0ZU9TUG9saWN5QXNzaWdubWVudFJlcXVlc3QSQQoGcGFyZW50GAEgASgJQing
QQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EmgKFG9z
X3BvbGljeV9hc3NpZ25tZW50GAIgASgLMjEuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxw
aGEuT1NQb2xpY3lBc3NpZ25tZW50QgPgQQJSEm9zUG9saWN5QXNzaWdubWVudBI6Chdvc19w
b2xpY3lfYXNzaWdubWVudF9pZBgDIAEoCUID4EECUhRvc1BvbGljeUFzc2lnbm1lbnRJZCLN
AQofVXBkYXRlT1NQb2xpY3lBc3NpZ25tZW50UmVxdWVzdBJoChRvc19wb2xpY3lfYXNzaWdu
bWVudBgBIAEoCzIxLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNz
aWdubWVudEID4EECUhJvc1BvbGljeUFzc2lnbm1lbnQSQAoLdXBkYXRlX21hc2sYAiABKAsy
Gi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siZgocR2V0T1NQ
b2xpY3lBc3NpZ25tZW50UmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKm9zY29uZmln
Lmdvb2dsZWFwaXMuY29tL09TUG9saWN5QXNzaWdubWVudFIEbmFtZSKfAQoeTGlzdE9TUG9s
aWN5QXNzaWdubWVudHNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlv
bnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVS
CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKwAQofTGlzdE9TUG9s
aWN5QXNzaWdubWVudHNSZXNwb25zZRJlChVvc19wb2xpY3lfYXNzaWdubWVudHMYASADKAsy
MS5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5PU1BvbGljeUFzc2lnbm1lbnRSE29z
UG9saWN5QXNzaWdubWVudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuIqwBCiZMaXN0T1NQb2xpY3lBc3NpZ25tZW50UmV2aXNpb25zUmVxdWVzdBJGCgRuYW1l
GAEgASgJQjLgQQL6QSwKKm9zY29uZmlnLmdvb2dsZWFwaXMuY29tL09TUG9saWN5QXNzaWdu
bWVudFIEbmFtZRIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
AyABKAlSCXBhZ2VUb2tlbiK4AQonTGlzdE9TUG9saWN5QXNzaWdubWVudFJldmlzaW9uc1Jl
c3BvbnNlEmUKFW9zX3BvbGljeV9hc3NpZ25tZW50cxgBIAMoCzIxLmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNzaWdubWVudFITb3NQb2xpY3lBc3NpZ25tZW50
cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iaQofRGVsZXRlT1NQ
b2xpY3lBc3NpZ25tZW50UmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKm9zY29uZmln
Lmdvb2dsZWFwaXMuY29tL09TUG9saWN5QXNzaWdubWVudFIEbmFtZULhAQohY29tLmdvb2ds
ZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhQhhPc1BvbGljeUFzc2lnbm1lbnRzUHJvdG9QAVo9
Y2xvdWQuZ29vZ2xlLmNvbS9nby9vc2NvbmZpZy9hcGl2MWFscGhhL29zY29uZmlncGI7b3Nj
b25maWdwYqoCHUdvb2dsZS5DbG91ZC5Pc0NvbmZpZy5WMUFscGhhygIdR29vZ2xlXENsb3Vk
XE9zQ29uZmlnXFYxYWxwaGHqAiBHb29nbGU6OkNsb3VkOjpPc0NvbmZpZzo6VjFhbHBoYUqD
ZwoHEgUOAP4CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
JgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANwoJCgIDAxIDFQA9CgkKAgMEEgMW
ACgKCQoCAwUSAxcAKgoJCgIDBhIDGAApCggKAQgSAxoAOgoJCgIIJRIDGgA6CggKAQgSAxsA
VAoJCgIICxIDGwBUCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AOQoJCgIICBIDHQA5
CggKAQgSAx4AOgoJCgIIARIDHgA6CggKAQgSAx8AOgoJCgIIKRIDHwA6CggKAQgSAyAAOQoJ
CgIILRIDIAA5CrQECgIEABIFLQDRAQEapgQgT1MgcG9saWN5IGFzc2lnbm1lbnQgaXMgYW4g
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
BAADAAIAARIDQBgeCg4KBwQAAwACAAMSA0AhIgq3AQoEBAADARIERwJxAxqoASBGaWx0ZXJz
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
DgoHBAADAQIAARIDWQkMCg4KBwQAAwECAAMSA1kPEAqhAQoGBAADAQIBEgNeBDsakQEgRGVw
cmVjYXRlZC4gVXNlIHRoZSBgaW52ZW50b3JpZXNgIGZpZWxkIGluc3RlYWQuCiBBIFZNIGlz
IHNlbGVjdGVkIGlmIGl0J3MgT1Mgc2hvcnQgbmFtZSBtYXRjaGVzIHdpdGggYW55IG9mIHRo
ZQogdmFsdWVzIHByb3ZpZGVkIGluIHRoaXMgbGlzdC4KCg4KBwQAAwECAQQSA14EDAoOCgcE
AAMBAgEFEgNeDRMKDgoHBAADAQIBARIDXhQiCg4KBwQAAwECAQMSA14lJgoOCgcEAAMBAgEI
EgNeJzoKDwoIBAADAQIBCAMSA14oOQqvAQoGBAADAQICEgNkBCsanwEgTGlzdCBvZiBsYWJl
bCBzZXRzIHVzZWQgZm9yIFZNIGluY2x1c2lvbi4KCiBJZiB0aGUgbGlzdCBoYXMgbW9yZSB0
aGFuIG9uZSBgTGFiZWxTZXRgLCB0aGUgVk0gaXMgaW5jbHVkZWQgaWYgYW55CiBvZiB0aGUg
bGFiZWwgc2V0cyBhcmUgYXBwbGljYWJsZSBmb3IgdGhlIFZNLgoKDgoHBAADAQICBBIDZAQM
Cg4KBwQAAwECAgYSA2QNFQoOCgcEAAMBAgIBEgNkFiYKDgoHBAADAQICAxIDZCkqCq4BCgYE
AAMBAgMSA2oEKxqeASBMaXN0IG9mIGxhYmVsIHNldHMgdXNlZCBmb3IgVk0gZXhjbHVzaW9u
LgoKIElmIHRoZSBsaXN0IGhhcyBtb3JlIHRoYW4gb25lIGxhYmVsIHNldCwgdGhlIFZNIGlz
IGV4Y2x1ZGVkIGlmIGFueQogb2YgdGhlIGxhYmVsIHNldHMgYXJlIGFwcGxpY2FibGUgZm9y
IHRoZSBWTS4KCg4KBwQAAwECAwQSA2oEDAoOCgcEAAMBAgMGEgNqDRUKDgoHBAADAQIDARID
ahYmCg4KBwQAAwECAwMSA2opKgqRAQoGBAADAQIEEgNwBCcagQEgTGlzdCBvZiBpbnZlbnRv
cmllcyB0byBzZWxlY3QgVk1zLgoKIEEgVk0gaXMgc2VsZWN0ZWQgaWYgaXRzIGludmVudG9y
eSBkYXRhIG1hdGNoZXMgYXQgbGVhc3Qgb25lIG9mIHRoZQogZm9sbG93aW5nIGludmVudG9y
aWVzLgoKDgoHBAADAQIEBBIDcAQMCg4KBwQAAwECBAYSA3ANFgoOCgcEAAMBAgQBEgNwFyIK
DgoHBAADAQIEAxIDcCUmCmMKBAQAAwISBXUCgAEDGlQgTWVzc2FnZSB0byBjb25maWd1cmUg
dGhlIHJvbGxvdXQgYXQgdGhlIHpvbmFsIGxldmVsIGZvciB0aGUgT1MgcG9saWN5CiBhc3Np
Z25tZW50LgoKDAoFBAADAgESA3UKEQpuCgYEAAMCAgASA3gEUhpfIFJlcXVpcmVkLiBUaGUg
bWF4aW11bSBudW1iZXIgKG9yIHBlcmNlbnRhZ2UpIG9mIFZNcyBwZXIgem9uZSB0byBkaXNy
dXB0IGF0CiBhbnkgZ2l2ZW4gbW9tZW50LgoKDgoHBAADAgIABhIDeAQSCg4KBwQAAwICAAES
A3gTJAoOCgcEAAMCAgADEgN4JygKDgoHBAADAgIACBIDeClRChEKCgQAAwICAAicCAASA3gq
UAquAgoGBAADAgIBEgN/BFwangIgUmVxdWlyZWQuIFRoaXMgZGV0ZXJtaW5lcyB0aGUgbWlu
aW11bSBkdXJhdGlvbiBvZiB0aW1lIHRvIHdhaXQgYWZ0ZXIgdGhlCiBjb25maWd1cmF0aW9u
IGNoYW5nZXMgYXJlIGFwcGxpZWQgdGhyb3VnaCB0aGUgY3VycmVudCByb2xsb3V0LiBBCiBW
TSBjb250aW51ZXMgdG8gY291bnQgdG93YXJkcyB0aGUgYGRpc3J1cHRpb25fYnVkZ2V0YCBh
dCBsZWFzdAogdW50aWwgdGhpcyBkdXJhdGlvbiBvZiB0aW1lIGhhcyBwYXNzZWQgYWZ0ZXIg
Y29uZmlndXJhdGlvbiBjaGFuZ2VzIGFyZQogYXBwbGllZC4KCg4KBwQAAwICAQYSA38EHAoO
CgcEAAMCAgEBEgN/HS4KDgoHBAADAgIBAxIDfzEyCg4KBwQAAwICAQgSA38zWwoRCgoEAAMC
AgEInAgAEgN/NFoKNAoEBAAEABIGgwECkgEDGiQgT1MgcG9saWN5IGFzc2lnbm1lbnQgcm9s
bG91dCBzdGF0ZQoKDQoFBAAEAAESBIMBBxMKHwoGBAAEAAIAEgSFAQQiGg8gSW52YWxpZCB2
YWx1ZQoKDwoHBAAEAAIAARIEhQEEHQoPCgcEAAQAAgACEgSFASAhCi0KBgQABAACARIEiAEE
FBodIFRoZSByb2xsb3V0IGlzIGluIHByb2dyZXNzLgoKDwoHBAAEAAIBARIEiAEEDwoPCgcE
AAQAAgECEgSIARITCjEKBgQABAACAhIEiwEEExohIFRoZSByb2xsb3V0IGlzIGJlaW5nIGNh
bmNlbGxlZC4KCg8KBwQABAACAgESBIsBBA4KDwoHBAAEAAICAhIEiwEREgorCgYEAAQAAgMS
BI4BBBIaGyBUaGUgcm9sbG91dCBpcyBjYW5jZWxsZWQuCgoPCgcEAAQAAgMBEgSOAQQNCg8K
BwQABAACAwISBI4BEBEKOQoGBAAEAAIEEgSRAQQSGikgVGhlIHJvbGxvdXQgaGFzIGNvbXBs
ZXRlZCBzdWNjZXNzZnVsbHkuCgoPCgcEAAQAAgQBEgSRAQQNCg8KBwQABAACBAISBJEBEBEK
ygEKBAQAAgASBJoBAhIauwEgUmVzb3VyY2UgbmFtZS4KCiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vc1BvbGljeUFzc2lnbm1l
bnRzL3tvc19wb2xpY3lfYXNzaWdubWVudF9pZH1gCgogVGhpcyBmaWVsZCBpcyBpZ25vcmVk
IHdoZW4geW91IGNyZWF0ZSBhbiBPUyBwb2xpY3kgYXNzaWdubWVudC4KCg0KBQQAAgAFEgSa
AQIICg0KBQQAAgABEgSaAQkNCg0KBQQAAgADEgSaARARCmsKBAQAAgESBJ4BAhkaXSBPUyBw
b2xpY3kgYXNzaWdubWVudCBkZXNjcmlwdGlvbi4KIExlbmd0aCBvZiB0aGUgZGVzY3JpcHRp
b24gaXMgbGltaXRlZCB0byAxMDI0IGNoYXJhY3RlcnMuCgoNCgUEAAIBBRIEngECCAoNCgUE
AAIBARIEngEJFAoNCgUEAAIBAxIEngEXGApHCgQEAAICEgShAQJNGjkgUmVxdWlyZWQuIExp
c3Qgb2YgT1MgcG9saWNpZXMgdG8gYmUgYXBwbGllZCB0byB0aGUgVk1zLgoKDQoFBAACAgQS
BKEBAgoKDQoFBAACAgYSBKEBCxMKDQoFBAACAgESBKEBFB8KDQoFBAACAgMSBKEBIiMKDQoF
BAACAggSBKEBJEwKEAoIBAACAgicCAASBKEBJUsKLwoEBAACAxIEpAECThohIFJlcXVpcmVk
LiBGaWx0ZXIgdG8gc2VsZWN0IFZNcy4KCg0KBQQAAgMGEgSkAQIQCg0KBQQAAgMBEgSkAREg
Cg0KBQQAAgMDEgSkASMkCg0KBQQAAgMIEgSkASVNChAKCAQAAgMInAgAEgSkASZMCswCCgQE
AAIEEgSuAQI/Gr0CIFJlcXVpcmVkLiBSb2xsb3V0IHRvIGRlcGxveSB0aGUgT1MgcG9saWN5
IGFzc2lnbm1lbnQuCiBBIHJvbGxvdXQgaXMgdHJpZ2dlcmVkIGluIHRoZSBmb2xsb3dpbmcg
c2l0dWF0aW9uczoKIDEpIE9TUG9saWN5QXNzaWdubWVudCBpcyBjcmVhdGVkLgogMikgT1NQ
b2xpY3lBc3NpZ25tZW50IGlzIHVwZGF0ZWQgYW5kIHRoZSB1cGRhdGUgY29udGFpbnMgY2hh
bmdlcyB0byBvbmUgb2YKIHRoZSBmb2xsb3dpbmcgZmllbGRzOgogICAgLSBpbnN0YW5jZV9m
aWx0ZXIKICAgIC0gb3NfcG9saWNpZXMKIDMpIE9TUG9saWN5QXNzaWdubWVudCBpcyBkZWxl
dGVkLgoKDQoFBAACBAYSBK4BAgkKDQoFBAACBAESBK4BChEKDQoFBAACBAMSBK4BFBUKDQoF
BAACBAgSBK4BFj4KEAoIBAACBAicCAASBK4BFz0KkQEKBAQAAgUSBLMBAkUaggEgT3V0cHV0
IG9ubHkuIFRoZSBhc3NpZ25tZW50IHJldmlzaW9uIElECiBBIG5ldyByZXZpc2lvbiBpcyBj
b21taXR0ZWQgd2hlbmV2ZXIgYSByb2xsb3V0IGlzIHRyaWdnZXJlZCBmb3IgYSBPUyBwb2xp
Y3kKIGFzc2lnbm1lbnQKCg0KBQQAAgUFEgSzAQIICg0KBQQAAgUBEgSzAQkUCg0KBQQAAgUD
EgSzARcYCg0KBQQAAgUIEgSzARlEChAKCAQAAgUInAgAEgSzARpDCkkKBAQAAgYSBLYBAmEa
OyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB0aGF0IHRoZSByZXZpc2lvbiB3YXMgY3Jl
YXRlZC4KCg0KBQQAAgYGEgS2AQIbCg0KBQQAAgYBEgS2ARwwCg0KBQQAAgYDEgS2ATM0Cg0K
BQQAAgYIEgS2ATVgChAKCAQAAgYInAgAEgS2ATZfCngKBAQAAgcSBLoBAhIaaiBUaGUgZXRh
ZyBmb3IgdGhpcyBPUyBwb2xpY3kgYXNzaWdubWVudC4KIElmIHRoaXMgaXMgcHJvdmlkZWQg
b24gdXBkYXRlLCBpdCBtdXN0IG1hdGNoIHRoZSBzZXJ2ZXIncyBldGFnLgoKDQoFBAACBwUS
BLoBAggKDQoFBAACBwESBLoBCQ0KDQoFBAACBwMSBLoBEBEKPwoEBAACCBIEvQECTRoxIE91
dHB1dCBvbmx5LiBPUyBwb2xpY3kgYXNzaWdubWVudCByb2xsb3V0IHN0YXRlCgoNCgUEAAII
BhIEvQECDgoNCgUEAAIIARIEvQEPHAoNCgUEAAIIAxIEvQEfIAoNCgUEAAIICBIEvQEhTAoQ
CggEAAIICJwIABIEvQEiSwqNAgoEBAACCRIExAECQRr+ASBPdXRwdXQgb25seS4gSW5kaWNh
dGVzIHRoYXQgdGhpcyByZXZpc2lvbiBoYXMgYmVlbiBzdWNjZXNzZnVsbHkgcm9sbGVkIG91
dCBpbiB0aGlzIHpvbmUKIGFuZCBuZXcgVk1zIHdpbGwgYmUgYXNzaWduZWQgT1MgcG9saWNp
ZXMgZnJvbSB0aGlzIHJldmlzaW9uLgoKIEZvciBhIGdpdmVuIE9TIHBvbGljeSBhc3NpZ25t
ZW50LCB0aGVyZSBpcyBvbmx5IG9uZSByZXZpc2lvbiB3aXRoIGEgdmFsdWUKIG9mIGB0cnVl
YCBmb3IgdGhpcyBmaWVsZC4KCg0KBQQAAgkFEgTEAQIGCg0KBQQAAgkBEgTEAQcPCg0KBQQA
AgkDEgTEARIUCg0KBQQAAgkIEgTEARVAChAKCAQAAgkInAgAEgTEARY/ClsKBAQAAgoSBMcB
AkAaTSBPdXRwdXQgb25seS4gSW5kaWNhdGVzIHRoYXQgdGhpcyByZXZpc2lvbiBkZWxldGVz
IHRoZSBPUyBwb2xpY3kgYXNzaWdubWVudC4KCg0KBQQAAgoFEgTHAQIGCg0KBQQAAgoBEgTH
AQcOCg0KBQQAAgoDEgTHARETCg0KBQQAAgoIEgTHARQ/ChAKCAQAAgoInAgAEgTHARU+CrMB
CgQEAAILEgTNAQJEGqQBIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgdGhhdCByZWNvbmNpbGlh
dGlvbiBpcyBpbiBwcm9ncmVzcyBmb3IgdGhlIHJldmlzaW9uLgogVGhpcyB2YWx1ZSBpcyBg
dHJ1ZWAgd2hlbiB0aGUgYHJvbGxvdXRfc3RhdGVgIGlzIG9uZSBvZjoKICogSU5fUFJPR1JF
U1MKICogQ0FOQ0VMTElORwoKDQoFBAACCwUSBM0BAgYKDQoFBAACCwESBM0BBxIKDQoFBAAC
CwMSBM0BFRcKDQoFBAACCwgSBM0BGEMKEAoIBAACCwicCAASBM0BGUIKXgoEBAACDBIE0AEC
PhpQIE91dHB1dCBvbmx5LiBTZXJ2ZXIgZ2VuZXJhdGVkIHVuaXF1ZSBpZCBmb3IgdGhlIE9T
IHBvbGljeSBhc3NpZ25tZW50IHJlc291cmNlLgoKDQoFBAACDAUSBNABAggKDQoFBAACDAES
BNABCQwKDQoFBAACDAMSBNABDxEKDQoFBAACDAgSBNABEj0KEAoIBAACDAicCAASBNABEzwK
igEKAgQBEgbVAQCKAgEafCBPUyBwb2xpY3kgYXNzaWdubWVudCBvcGVyYXRpb24gbWV0YWRh
dGEgcHJvdmlkZWQgYnkgT1MgcG9saWN5IGFzc2lnbm1lbnQgQVBJCiBtZXRob2RzIHRoYXQg
cmV0dXJuIGxvbmcgcnVubmluZyBvcGVyYXRpb25zLgoKCwoDBAEBEgTVAQgrCjYKBAQBBAAS
BtcBAuMBAxomIFRoZSBPUyBwb2xpY3kgYXNzaWdubWVudCBBUEkgbWV0aG9kLgoKDQoFBAEE
AAESBNcBBxAKHwoGBAEEAAIAEgTZAQQfGg8gSW52YWxpZCB2YWx1ZQoKDwoHBAEEAAIAARIE
2QEEGgoPCgcEAQQAAgACEgTZAR0eCjgKBgQBBAACARIE3AEEDxooIENyZWF0ZSBPUyBwb2xp
Y3kgYXNzaWdubWVudCBBUEkgbWV0aG9kCgoPCgcEAQQAAgEBEgTcAQQKCg8KBwQBBAACAQIS
BNwBDQ4KOAoGBAEEAAICEgTfAQQPGiggVXBkYXRlIE9TIHBvbGljeSBhc3NpZ25tZW50IEFQ
SSBtZXRob2QKCg8KBwQBBAACAgESBN8BBAoKDwoHBAEEAAICAhIE3wENDgo4CgYEAQQAAgMS
BOIBBA8aKCBEZWxldGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgQVBJIG1ldGhvZAoKDwoHBAEE
AAIDARIE4gEECgoPCgcEAQQAAgMCEgTiAQ0OCiYKBAQBBAESBuYBAvUBAxoWIFN0YXRlIG9m
IHRoZSByb2xsb3V0CgoNCgUEAQQBARIE5gEHEwofCgYEAQQBAgASBOgBBCIaDyBJbnZhbGlk
IHZhbHVlCgoPCgcEAQQBAgABEgToAQQdCg8KBwQBBAECAAISBOgBICEKLQoGBAEEAQIBEgTr
AQQUGh0gVGhlIHJvbGxvdXQgaXMgaW4gcHJvZ3Jlc3MuCgoPCgcEAQQBAgEBEgTrAQQPCg8K
BwQBBAECAQISBOsBEhMKMQoGBAEEAQICEgTuAQQTGiEgVGhlIHJvbGxvdXQgaXMgYmVpbmcg
Y2FuY2VsbGVkLgoKDwoHBAEEAQICARIE7gEEDgoPCgcEAQQBAgICEgTuARESCisKBgQBBAEC
AxIE8QEEEhobIFRoZSByb2xsb3V0IGlzIGNhbmNlbGxlZC4KCg8KBwQBBAECAwESBPEBBA0K
DwoHBAEEAQIDAhIE8QEQEQo5CgYEAQQBAgQSBPQBBBIaKSBUaGUgcm9sbG91dCBoYXMgY29t
cGxldGVkIHN1Y2Nlc3NmdWxseS4KCg8KBwQBBAECBAESBPQBBA0KDwoHBAEEAQIEAhIE9AEQ
EQq8AQoEBAECABIG+wEC/QEmGqsBIFJlZmVyZW5jZSB0byB0aGUgYE9TUG9saWN5QXNzaWdu
bWVudGAgQVBJIHJlc291cmNlLgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1i
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L29zUG9saWN5QXNzaWdubWVudHMve29zX3BvbGlj
eV9hc3NpZ25tZW50X2lkQHJldmlzaW9uX2lkfWAKCg0KBQQBAgAFEgT7AQIICg0KBQQBAgAB
EgT7AQkdCg0KBQQBAgADEgT7ASAhCg8KBQQBAgAIEgb7ASL9ASUKEQoHBAECAAifCBIG+wEj
/QEkCjQKBAQBAgESBIACAhsaJiBUaGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgQVBJIG1ldGhv
ZC4KCg0KBQQBAgEGEgSAAgILCg0KBQQBAgEBEgSAAgwWCg0KBQQBAgEDEgSAAhkaCiQKBAQB
AgISBIMCAiEaFiBTdGF0ZSBvZiB0aGUgcm9sbG91dAoKDQoFBAECAgYSBIMCAg4KDQoFBAEC
AgESBIMCDxwKDQoFBAECAgMSBIMCHyAKIgoEBAECAxIEhgICMxoUIFJvbGxvdXQgc3RhcnQg
dGltZQoKDQoFBAECAwYSBIYCAhsKDQoFBAECAwESBIYCHC4KDQoFBAECAwMSBIYCMTIKIwoE
BAECBBIEiQICNBoVIFJvbGxvdXQgdXBkYXRlIHRpbWUKCg0KBQQBAgQGEgSJAgIbCg0KBQQB
AgQBEgSJAhwvCg0KBQQBAgQDEgSJAjIzCkMKAgQCEgaNAgCjAgEaNSBBIHJlcXVlc3QgbWVz
c2FnZSB0byBjcmVhdGUgYW4gT1MgcG9saWN5IGFzc2lnbm1lbnQKCgsKAwQCARIEjQIIJwpq
CgQEAgIAEgaQAgKVAgQaWiBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lIGlu
IHRoZSBmb3JtOgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259CgoN
CgUEAgIABRIEkAICCAoNCgUEAgIAARIEkAIJDwoNCgUEAgIAAxIEkAISEwoPCgUEAgIACBIG
kAIUlQIDChAKCAQCAgAInAgAEgSRAgQqChEKBwQCAgAInwgSBpICBJQCBQpBCgQEAgIBEgSY
AgJXGjMgUmVxdWlyZWQuIFRoZSBPUyBwb2xpY3kgYXNzaWdubWVudCB0byBiZSBjcmVhdGVk
LgoKDQoFBAICAQYSBJgCAhQKDQoFBAICAQESBJgCFSkKDQoFBAICAQMSBJgCLC0KDQoFBAIC
AQgSBJgCLlYKEAoIBAICAQicCAASBJgCL1UKxQIKBAQCAgISBKICAk4atgIgUmVxdWlyZWQu
IFRoZSBsb2dpY2FsIG5hbWUgb2YgdGhlIE9TIHBvbGljeSBhc3NpZ25tZW50IGluIHRoZSBw
cm9qZWN0CiB3aXRoIHRoZSBmb2xsb3dpbmcgcmVzdHJpY3Rpb25zOgoKICogTXVzdCBjb250
YWluIG9ubHkgbG93ZXJjYXNlIGxldHRlcnMsIG51bWJlcnMsIGFuZCBoeXBoZW5zLgogKiBN
dXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCiAqIE11c3QgYmUgYmV0d2VlbiAxLTYzIGNoYXJh
Y3RlcnMuCiAqIE11c3QgZW5kIHdpdGggYSBudW1iZXIgb3IgYSBsZXR0ZXIuCiAqIE11c3Qg
YmUgdW5pcXVlIHdpdGhpbiB0aGUgcHJvamVjdC4KCg0KBQQCAgIFEgSiAgIICg0KBQQCAgIB
EgSiAgkgCg0KBQQCAgIDEgSiAiMkCg0KBQQCAgIIEgSiAiVNChAKCAQCAgIInAgAEgSiAiZM
CkMKAgQDEgamAgCsAgEaNSBBIHJlcXVlc3QgbWVzc2FnZSB0byB1cGRhdGUgYW4gT1MgcG9s
aWN5IGFzc2lnbm1lbnQKCgsKAwQDARIEpgIIJwo7CgQEAwIAEgSoAgJXGi0gUmVxdWlyZWQu
IFRoZSB1cGRhdGVkIE9TIHBvbGljeSBhc3NpZ25tZW50LgoKDQoFBAMCAAYSBKgCAhQKDQoF
BAMCAAESBKgCFSkKDQoFBAMCAAMSBKgCLC0KDQoFBAMCAAgSBKgCLlYKEAoIBAMCAAicCAAS
BKgCL1UKZAoEBAMCARIEqwICVRpWIE9wdGlvbmFsLiBGaWVsZCBtYXNrIHRoYXQgY29udHJv
bHMgd2hpY2ggZmllbGRzIG9mIHRoZSBhc3NpZ25tZW50IHNob3VsZCBiZSB1cGRhdGVkLgoK
DQoFBAMCAQYSBKsCAhsKDQoFBAMCAQESBKsCHCcKDQoFBAMCAQMSBKsCKisKDQoFBAMCAQgS
BKsCLFQKEAoIBAMCAQicCAASBKsCLVMKQAoCBAQSBq8CALoCARoyIEEgcmVxdWVzdCBtZXNz
YWdlIHRvIGdldCBhbiBPUyBwb2xpY3kgYXNzaWdubWVudAoKCwoDBAQBEgSvAggkCrQBCgQE
BAIAEga0AgK5AgQaowEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIE9TIHBvbGlj
eSBhc3NpZ25tZW50LgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vb3NQb2xpY3lBc3NpZ25tZW50cy97b3NfcG9saWN5X2Fzc2lnbm1lbnR9
QHtyZXZpc2lvbklkfWAKCg0KBQQEAgAFEgS0AgIICg0KBQQEAgABEgS0AgkNCg0KBQQEAgAD
EgS0AhARCg8KBQQEAgAIEga0AhK5AgMKEAoIBAQCAAicCAASBLUCBCoKEQoHBAQCAAifCBIG
tgIEuAIFClUKAgQFEga9AgDNAgEaRyBBIHJlcXVlc3QgbWVzc2FnZSB0byBsaXN0IE9TIHBv
bGljeSBhc3NpZ25tZW50cyBmb3IgYSBwYXJlbnQgcmVzb3VyY2UKCgsKAwQFARIEvQIIJgo1
CgQEBQIAEga/AgLEAgQaJSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLgoK
DQoFBAUCAAUSBL8CAggKDQoFBAUCAAESBL8CCQ8KDQoFBAUCAAMSBL8CEhMKDwoFBAUCAAgS
Br8CFMQCAwoQCggEBQIACJwIABIEwAIEKgoRCgcEBQIACJ8IEgbBAgTDAgUKPAoEBAUCARIE
xwICFhouIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhc3NpZ25tZW50cyB0byByZXR1cm4uCgoN
CgUEBQIBBRIExwICBwoNCgUEBQIBARIExwIIEQoNCgUEBQIBAxIExwIUFQqYAQoEBAUCAhIE
zAICGBqJASBBIHBhZ2luYXRpb24gdG9rZW4gcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGNh
bGwgdG8KIGBMaXN0T1NQb2xpY3lBc3NpZ25tZW50c2AgdGhhdCBpbmRpY2F0ZXMgd2hlcmUg
dGhpcyBsaXN0aW5nIHNob3VsZCBjb250aW51ZQogZnJvbS4KCg0KBQQFAgIFEgTMAgIICg0K
BQQFAgIBEgTMAgkTCg0KBQQFAgIDEgTMAhYXClIKAgQGEgbQAgDWAgEaRCBBIHJlc3BvbnNl
IG1lc3NhZ2UgZm9yIGxpc3RpbmcgYWxsIGFzc2lnbm1lbnRzIHVuZGVyIGdpdmVuIHBhcmVu
dC4KCgsKAwQGARIE0AIIJwonCgQEBgIAEgTSAgI4GhkgVGhlIGxpc3Qgb2YgYXNzaWdubWVu
dHMKCg0KBQQGAgAEEgTSAgIKCg0KBQQGAgAGEgTSAgsdCg0KBQQGAgABEgTSAh4zCg0KBQQG
AgADEgTSAjY3ClgKBAQGAgESBNUCAh0aSiBUaGUgcGFnaW5hdGlvbiB0b2tlbiB0byByZXRy
aWV2ZSB0aGUgbmV4dCBwYWdlIG9mIE9TIHBvbGljeSBhc3NpZ25tZW50cy4KCg0KBQQGAgEF
EgTVAgIICg0KBQQGAgEBEgTVAgkYCg0KBQQGAgEDEgTVAhscCk4KAgQHEgbZAgDpAgEaQCBB
IHJlcXVlc3QgbWVzc2FnZSB0byBsaXN0IHJldmlzaW9ucyBmb3IgYSBPUyBwb2xpY3kgYXNz
aWdubWVudAoKCwoDBAcBEgTZAgguClcKBAQHAgASBtsCAuACBBpHIFJlcXVpcmVkLiBUaGUg
bmFtZSBvZiB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgdG8gbGlzdCByZXZpc2lvbnMgZm9y
LgoKDQoFBAcCAAUSBNsCAggKDQoFBAcCAAESBNsCCQ0KDQoFBAcCAAMSBNsCEBEKDwoFBAcC
AAgSBtsCEuACAwoQCggEBwIACJwIABIE3AIEKgoRCgcEBwIACJ8IEgbdAgTfAgUKOgoEBAcC
ARIE4wICFhosIFRoZSBtYXhpbXVtIG51bWJlciBvZiByZXZpc2lvbnMgdG8gcmV0dXJuLgoK
DQoFBAcCAQUSBOMCAgcKDQoFBAcCAQESBOMCCBEKDQoFBAcCAQMSBOMCFBUKoAEKBAQHAgIS
BOgCAhgakQEgQSBwYWdpbmF0aW9uIHRva2VuIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBj
YWxsIHRvCiBgTGlzdE9TUG9saWN5QXNzaWdubWVudFJldmlzaW9uc2AgdGhhdCBpbmRpY2F0
ZXMgd2hlcmUgdGhpcyBsaXN0aW5nIHNob3VsZAogY29udGludWUgZnJvbS4KCg0KBQQHAgIF
EgToAgIICg0KBQQHAgIBEgToAgkTCg0KBQQHAgIDEgToAhYXClgKAgQIEgbsAgDzAgEaSiBB
IHJlc3BvbnNlIG1lc3NhZ2UgZm9yIGxpc3RpbmcgYWxsIHJldmlzaW9ucyBmb3IgYSBPUyBw
b2xpY3kgYXNzaWdubWVudC4KCgsKAwQIARIE7AIILwoyCgQECAIAEgTuAgI4GiQgVGhlIE9T
IHBvbGljeSBhc3NpZ25tZW50IHJldmlzaW9ucwoKDQoFBAgCAAQSBO4CAgoKDQoFBAgCAAYS
BO4CCx0KDQoFBAgCAAESBO4CHjMKDQoFBAgCAAMSBO4CNjcKYgoEBAgCARIE8gICHRpUIFRo
ZSBwYWdpbmF0aW9uIHRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgT1MgcG9s
aWN5IGFzc2lnbm1lbnQKIHJldmlzaW9ucy4KCg0KBQQIAgEFEgTyAgIICg0KBQQIAgEBEgTy
AgkYCg0KBQQIAgEDEgTyAhscCkYKAgQJEgb2AgD+AgEaOCBBIHJlcXVlc3QgbWVzc2FnZSBm
b3IgZGVsZXRpbmcgYSBPUyBwb2xpY3kgYXNzaWdubWVudC4KCgsKAwQJARIE9gIIJwpOCgQE
CQIAEgb4AgL9AgQaPiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIE9TIHBvbGljeSBhc3Np
Z25tZW50IHRvIGJlIGRlbGV0ZWQKCg0KBQQJAgAFEgT4AgIICg0KBQQJAgABEgT4AgkNCg0K
BQQJAgADEgT4AhARCg8KBQQJAgAIEgb4AhL9AgMKEAoIBAkCAAicCAASBPkCBCoKEQoHBAkC
AAifCBIG+gIE/AIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment ===
    # Fields for OSPolicyAssignment
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: os_policies Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicy)
    # Field: instance_filter Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment.InstanceFilter)
    # Field: rollout Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment.Rollout)
    # Field: revision_id Type: 9 ()
    # Field: revision_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: rollout_state Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment.RolloutState)
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

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata ===
    # Fields for OSPolicyAssignmentOperationMetadata
    # Field: os_policy_assignment Type: 9 ()
    # Field: api_method Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyAssignmentOperationMetadata.APIMethod)
    # Field: rollout_state Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyAssignmentOperationMetadata.RolloutState)
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

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::CreateOSPolicyAssignmentRequest ===
    # Fields for CreateOSPolicyAssignmentRequest
    # Field: parent Type: 9 ()
    # Field: os_policy_assignment Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment)
    # Field: os_policy_assignment_id Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest ===
    # Fields for UpdateOSPolicyAssignmentRequest
    # Field: os_policy_assignment Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::GetOSPolicyAssignmentRequest ===
    # Fields for GetOSPolicyAssignmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentsRequest ===
    # Fields for ListOSPolicyAssignmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentsResponse ===
    # Fields for ListOSPolicyAssignmentsResponse
    # Field: os_policy_assignments Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest ===
    # Fields for ListOSPolicyAssignmentRevisionsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse ===
    # Fields for ListOSPolicyAssignmentRevisionsResponse
    # Field: os_policy_assignments Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyAssignment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest ===
    # Fields for DeleteOSPolicyAssignmentRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments - Compiled Protocol Buffers messages for google/cloud/osconfig/v1alpha/os_policy_assignments.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments;

    my $msg = Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment->new({
        name => $name,
        description => $description,
        os_policies => $os_policies,
        instance_filter => $instance_filter,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1alpha/os_policy_assignments.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment

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

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicy::OSPolicy>)

Required. List of OS policies to be applied to the VMs.

=item * C<< $msg->instance_filter() >> / C<< $msg->instance_filter($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter>)

Required. Filter to select VMs.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment::Rollout>)

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

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyAssignment::RolloutState>)

Output only. OS policy assignment rollout state

=item * C<< $msg->baseline() >> / C<< $msg->baseline($value) >>

Type: C<Bool>

Output only. Indicates that this revision has been successfully rolled out in this zone
and new VMs will be assigned OS policies from this revision.

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

Output only. Server generated unique id for the OS policy assignment resource.

=back

=head3 Enum: OSPolicyAssignment::RolloutState

=over 4

=item * C<ROLLOUT_STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<CANCELLING> => C<2>

=item * C<CANCELLED> => C<3>

=item * C<SUCCEEDED> => C<4>

=back

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata

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

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyAssignmentOperationMetadata::APIMethod>)

The OS policy assignment API method.

=item * C<< $msg->rollout_state() >> / C<< $msg->rollout_state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyAssignmentOperationMetadata::RolloutState>)

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

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::CreateOSPolicyAssignmentRequest

A request message to create an OS policy assignment

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name in the form:
projects/{project}/locations/{location}

=item * C<< $msg->os_policy_assignment() >> / C<< $msg->os_policy_assignment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment>)

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

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest

A request message to update an OS policy assignment

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignment() >> / C<< $msg->os_policy_assignment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment>)

Required. The updated OS policy assignment.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask that controls which fields of the assignment should be updated.

=back

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::GetOSPolicyAssignmentRequest

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

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentsRequest

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

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentsResponse

A response message for listing all assignments under given parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignments() >> / C<< $msg->os_policy_assignments($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment>)

The list of assignments

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token to retrieve the next page of OS policy assignments.

=back

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest

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

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse

A response message for listing all revisions for a OS policy assignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_assignments() >> / C<< $msg->os_policy_assignments($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment>)

The OS policy assignment revisions

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token to retrieve the next page of OS policy assignment
revisions.

=back

=head2 Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest

A request message for deleting a OS policy assignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the OS policy assignment to be deleted

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
