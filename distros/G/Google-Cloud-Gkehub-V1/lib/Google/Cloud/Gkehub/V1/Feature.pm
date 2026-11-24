package Google::Cloud::Gkehub::V1::Feature;

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
    eval { require Google::Cloud::Gkehub::Configmanagement::V1::Configmanagement };
    eval { require Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress };
    eval { require Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvZ2tlaHViL3YxL2ZlYXR1cmUucHJvdG8SFmdvb2dsZS5jbG91ZC5n
a2VodWIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aPmdvb2dsZS9jbG91ZC9na2VodWIvdjEvY29uZmlnbWFuYWdlbWVu
dC9jb25maWdtYW5hZ2VtZW50LnByb3RvGkRnb29nbGUvY2xvdWQvZ2tlaHViL3YxL211bHRp
Y2x1c3RlcmluZ3Jlc3MvbXVsdGljbHVzdGVyaW5ncmVzcy5wcm90bxpOZ29vZ2xlL2Nsb3Vk
L2drZWh1Yi92MS9yYmFjcm9sZWJpbmRpbmdhY3R1YXRpb24vcmJhY3JvbGViaW5kaW5nYWN0
dWF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpAMCgdGZWF0
dXJlEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJDCgZsYWJlbHMYAiADKAsyKy5nb29nbGUu
Y2xvdWQuZ2tlaHViLnYxLkZlYXR1cmUuTGFiZWxzRW50cnlSBmxhYmVscxJYCg5yZXNvdXJj
ZV9zdGF0ZRgDIAEoCzIsLmdvb2dsZS5jbG91ZC5na2VodWIudjEuRmVhdHVyZVJlc291cmNl
U3RhdGVCA+BBA1INcmVzb3VyY2VTdGF0ZRJCCgRzcGVjGAQgASgLMikuZ29vZ2xlLmNsb3Vk
LmdrZWh1Yi52MS5Db21tb25GZWF0dXJlU3BlY0ID4EEBUgRzcGVjEmQKEG1lbWJlcnNoaXBf
c3BlY3MYBSADKAsyNC5nb29nbGUuY2xvdWQuZ2tlaHViLnYxLkZlYXR1cmUuTWVtYmVyc2hp
cFNwZWNzRW50cnlCA+BBAVIPbWVtYmVyc2hpcFNwZWNzEkUKBXN0YXRlGAYgASgLMiouZ29v
Z2xlLmNsb3VkLmdrZWh1Yi52MS5Db21tb25GZWF0dXJlU3RhdGVCA+BBA1IFc3RhdGUSZwoR
bWVtYmVyc2hpcF9zdGF0ZXMYByADKAsyNS5nb29nbGUuY2xvdWQuZ2tlaHViLnYxLkZlYXR1
cmUuTWVtYmVyc2hpcFN0YXRlc0VudHJ5QgPgQQNSEG1lbWJlcnNoaXBTdGF0ZXMSQAoLY3Jl
YXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0
ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCnVwZGF0ZVRpbWUSQAoLZGVsZXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCmRlbGV0ZVRpbWUSVQoLc2NvcGVfc3BlY3MYDCADKAsyLy5n
b29nbGUuY2xvdWQuZ2tlaHViLnYxLkZlYXR1cmUuU2NvcGVTcGVjc0VudHJ5QgPgQQFSCnNj
b3BlU3BlY3MSWAoMc2NvcGVfc3RhdGVzGA0gAygLMjAuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52
MS5GZWF0dXJlLlNjb3BlU3RhdGVzRW50cnlCA+BBA1ILc2NvcGVTdGF0ZXMSJQoLdW5yZWFj
aGFibGUYDyADKAlCA+BBA1ILdW5yZWFjaGFibGUaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARpxChRNZW1iZXJzaGlwU3BlY3NF
bnRyeRIQCgNrZXkYASABKAlSA2tleRJDCgV2YWx1ZRgCIAEoCzItLmdvb2dsZS5jbG91ZC5n
a2VodWIudjEuTWVtYmVyc2hpcEZlYXR1cmVTcGVjUgV2YWx1ZToCOAEacwoVTWVtYmVyc2hp
cFN0YXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkQKBXZhbHVlGAIgASgLMi4uZ29vZ2xl
LmNsb3VkLmdrZWh1Yi52MS5NZW1iZXJzaGlwRmVhdHVyZVN0YXRlUgV2YWx1ZToCOAEaZwoP
U2NvcGVTcGVjc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5Ej4KBXZhbHVlGAIgASgLMiguZ29v
Z2xlLmNsb3VkLmdrZWh1Yi52MS5TY29wZUZlYXR1cmVTcGVjUgV2YWx1ZToCOAEaaQoQU2Nv
cGVTdGF0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI/CgV2YWx1ZRgCIAEoCzIpLmdvb2ds
ZS5jbG91ZC5na2VodWIudjEuU2NvcGVGZWF0dXJlU3RhdGVSBXZhbHVlOgI4ATpe6kFbCh1n
a2VodWIuZ29vZ2xlYXBpcy5jb20vRmVhdHVyZRI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2ZlYXR1cmVzL3tmZWF0dXJlfSLNAQoURmVhdHVyZVJlc291cmNl
U3RhdGUSSAoFc3RhdGUYASABKA4yMi5nb29nbGUuY2xvdWQuZ2tlaHViLnYxLkZlYXR1cmVS
ZXNvdXJjZVN0YXRlLlN0YXRlUgVzdGF0ZSJrCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEgwKCEVOQUJMSU5HEAESCgoGQUNUSVZFEAISDQoJRElTQUJMSU5HEAMSDAoIVVBEQVRJ
TkcQBBIUChBTRVJWSUNFX1VQREFUSU5HEAUi6gEKDEZlYXR1cmVTdGF0ZRI9CgRjb2RlGAEg
ASgOMikuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MS5GZWF0dXJlU3RhdGUuQ29kZVIEY29kZRIg
CgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb24SOwoLdXBkYXRlX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lIjwKBENvZGUSFAoQQ09E
RV9VTlNQRUNJRklFRBAAEgYKAk9LEAESCwoHV0FSTklORxACEgkKBUVSUk9SEAMikAEKEUNv
bW1vbkZlYXR1cmVTcGVjEmsKE211bHRpY2x1c3RlcmluZ3Jlc3MYZiABKAsyNy5nb29nbGUu
Y2xvdWQuZ2tlaHViLm11bHRpY2x1c3RlcmluZ3Jlc3MudjEuRmVhdHVyZVNwZWNIAFITbXVs
dGljbHVzdGVyaW5ncmVzc0IOCgxmZWF0dXJlX3NwZWMi4wEKEkNvbW1vbkZlYXR1cmVTdGF0
ZRJ7ChhyYmFjcm9sZWJpbmRpbmdhY3R1YXRpb24YeCABKAsyPS5nb29nbGUuY2xvdWQuZ2tl
aHViLnJiYWNyb2xlYmluZGluZ2FjdHVhdGlvbi52MS5GZWF0dXJlU3RhdGVIAFIYcmJhY3Jv
bGViaW5kaW5nYWN0dWF0aW9uEj8KBXN0YXRlGAEgASgLMiQuZ29vZ2xlLmNsb3VkLmdrZWh1
Yi52MS5GZWF0dXJlU3RhdGVCA+BBA1IFc3RhdGVCDwoNZmVhdHVyZV9zdGF0ZSISChBTY29w
ZUZlYXR1cmVTcGVjIlQKEVNjb3BlRmVhdHVyZVN0YXRlEj8KBXN0YXRlGAEgASgLMiQuZ29v
Z2xlLmNsb3VkLmdrZWh1Yi52MS5GZWF0dXJlU3RhdGVCA+BBA1IFc3RhdGUijgEKFU1lbWJl
cnNoaXBGZWF0dXJlU3BlYxJlChBjb25maWdtYW5hZ2VtZW50GGogASgLMjcuZ29vZ2xlLmNs
b3VkLmdrZWh1Yi5jb25maWdtYW5hZ2VtZW50LnYxLk1lbWJlcnNoaXBTcGVjSABSEGNvbmZp
Z21hbmFnZW1lbnRCDgoMZmVhdHVyZV9zcGVjIs0BChZNZW1iZXJzaGlwRmVhdHVyZVN0YXRl
EmYKEGNvbmZpZ21hbmFnZW1lbnQYaiABKAsyOC5nb29nbGUuY2xvdWQuZ2tlaHViLmNvbmZp
Z21hbmFnZW1lbnQudjEuTWVtYmVyc2hpcFN0YXRlSABSEGNvbmZpZ21hbmFnZW1lbnQSOgoF
c3RhdGUYASABKAsyJC5nb29nbGUuY2xvdWQuZ2tlaHViLnYxLkZlYXR1cmVTdGF0ZVIFc3Rh
dGVCDwoNZmVhdHVyZV9zdGF0ZUKuAQoaY29tLmdvb2dsZS5jbG91ZC5na2VodWIudjFCDEZl
YXR1cmVQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2drZWh1Yi9hcGl2MS9na2VodWJw
Yjtna2VodWJwYqoCFkdvb2dsZS5DbG91ZC5Ha2VIdWIuVjHKAhZHb29nbGVcQ2xvdWRcR2tl
SHViXFYx6gIZR29vZ2xlOjpDbG91ZDo6R2tlSHViOjpWMUrqRwoHEgUOAIICAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMB
EgMTACMKCQoCAwISAxQASAoJCgIDAxIDFQBOCgkKAgMEEgMWAFgKCQoCAwUSAxcAKQoICgEI
EgMZADMKCQoCCCUSAxkAMwoICgEIEgMaAEkKCQoCCAsSAxoASQoICgEIEgMbACIKCQoCCAoS
AxsAIgoICgEIEgMcAC0KCQoCCAgSAxwALQoICgEIEgMdADMKCQoCCAESAx0AMwoICgEIEgMe
ADMKCQoCCCkSAx4AMwoICgEIEgMfADIKCQoCCC0SAx8AMgpPCgIEABIFIgCKAQEaQiBGZWF0
dXJlIHJlcHJlc2VudHMgdGhlIHNldHRpbmdzIGFuZCBzdGF0dXMgb2YgYW55IEZsZWV0IEZl
YXR1cmUuCgoKCgMEAAESAyIIDwoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKfgoEBAAC
ABIDKgI+GnEgT3V0cHV0IG9ubHkuIFRoZSBmdWxsLCB1bmlxdWUgbmFtZSBvZiB0aGlzIEZl
YXR1cmUgcmVzb3VyY2UgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyov
ZmVhdHVyZXMvKmAuCgoMCgUEAAIABRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMSAyoQ
EQoMCgUEAAIACBIDKhI9Cg8KCAQAAgAInAgAEgMqEzwKJwoEBAACARIDLQIhGhogTGFiZWxz
IGZvciB0aGlzIEZlYXR1cmUuCgoMCgUEAAIBBhIDLQIVCgwKBQQAAgEBEgMtFhwKDAoFBAAC
AQMSAy0fIApCCgQEAAICEgQwAjEyGjQgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBGZWF0
dXJlIHJlc291cmNlIGl0c2VsZi4KCgwKBQQAAgIGEgMwAhYKDAoFBAACAgESAzAXJQoMCgUE
AAICAxIDMCgpCgwKBQQAAgIIEgMxBjEKDwoIBAACAgicCAASAzEHMAqVAQoEBAACAxIDNQJG
GocBIE9wdGlvbmFsLiBGbGVldC13aWRlIEZlYXR1cmUgY29uZmlndXJhdGlvbi4gSWYgdGhp
cyBGZWF0dXJlIGRvZXMgbm90CiBzdXBwb3J0IGFueSBGbGVldC13aWRlIGNvbmZpZ3VyYXRp
b24sIHRoaXMgZmllbGQgbWF5IGJlIHVudXNlZC4KCgwKBQQAAgMGEgM1AhMKDAoFBAACAwES
AzUUGAoMCgUEAAIDAxIDNRscCgwKBQQAAgMIEgM1HUUKDwoIBAACAwicCAASAzUeRArNBgoE
BAACBBIESQJKLxq+BiBPcHRpb25hbC4gTWVtYmVyc2hpcC1zcGVjaWZpYyBjb25maWd1cmF0
aW9uIGZvciB0aGlzIEZlYXR1cmUuIElmIHRoaXMKIEZlYXR1cmUgZG9lcyBub3Qgc3VwcG9y
dCBhbnkgcGVyLU1lbWJlcnNoaXAgY29uZmlndXJhdGlvbiwgdGhpcyBmaWVsZCBtYXkKIGJl
IHVudXNlZC4KCiBUaGUga2V5cyBpbmRpY2F0ZSB3aGljaCBNZW1iZXJzaGlwIHRoZSBjb25m
aWd1cmF0aW9uIGlzIGZvciwgaW4gdGhlIGZvcm06CgogYHByb2plY3RzL3twfS9sb2NhdGlv
bnMve2x9L21lbWJlcnNoaXBzL3ttfWAKCiBXaGVyZSB7cH0gaXMgdGhlIHByb2plY3QsIHts
fSBpcyBhIHZhbGlkIGxvY2F0aW9uIGFuZCB7bX0gaXMgYSB2YWxpZAogTWVtYmVyc2hpcCBp
biB0aGlzIHByb2plY3QgYXQgdGhhdCBsb2NhdGlvbi4ge3B9IFdJTEwgbWF0Y2ggdGhlIEZl
YXR1cmUncwogcHJvamVjdC4KCiB7cH0gd2lsbCBhbHdheXMgYmUgcmV0dXJuZWQgYXMgdGhl
IHByb2plY3QgbnVtYmVyLCBidXQgdGhlIHByb2plY3QgSUQgaXMKIGFsc28gYWNjZXB0ZWQg
ZHVyaW5nIGlucHV0LiBJZiB0aGUgc2FtZSBNZW1iZXJzaGlwIGlzIHNwZWNpZmllZCBpbiB0
aGUgbWFwCiB0d2ljZSAodXNpbmcgdGhlIHByb2plY3QgSUQgZm9ybSwgYW5kIHRoZSBwcm9q
ZWN0IG51bWJlciBmb3JtKSwgZXhhY3RseQogT05FIG9mIHRoZSBlbnRyaWVzIHdpbGwgYmUg
c2F2ZWQsIHdpdGggbm8gZ3VhcmFudGVlcyBhcyB0byB3aGljaC4gRm9yIHRoaXMKIHJlYXNv
biwgaXQgaXMgcmVjb21tZW5kZWQgdGhlIHNhbWUgZm9ybWF0IGJlIHVzZWQgZm9yIGFsbCBl
bnRyaWVzIHdoZW4KIG11dGF0aW5nIGEgRmVhdHVyZS4KCgwKBQQAAgQGEgNJAiQKDAoFBAAC
BAESA0klNQoMCgUEAAIEAxIDSTg5CgwKBQQAAgQIEgNKBi4KDwoIBAACBAicCAASA0oHLQo5
CgQEAAIFEgNNAksaLCBPdXRwdXQgb25seS4gVGhlIEZsZWV0LXdpZGUgRmVhdHVyZSBzdGF0
ZS4KCgwKBQQAAgUGEgNNAhQKDAoFBAACBQESA00VGgoMCgUEAAIFAxIDTR0eCgwKBQQAAgUI
EgNNH0oKDwoIBAACBQicCAASA00gSQqwAwoEBAACBhIEWQJaMhqhAyBPdXRwdXQgb25seS4g
TWVtYmVyc2hpcC1zcGVjaWZpYyBGZWF0dXJlIHN0YXR1cy4gSWYgdGhpcyBGZWF0dXJlIGRv
ZXMKIHJlcG9ydCBhbnkgcGVyLU1lbWJlcnNoaXAgc3RhdHVzLCB0aGlzIGZpZWxkIG1heSBi
ZSB1bnVzZWQuCgogVGhlIGtleXMgaW5kaWNhdGUgd2hpY2ggTWVtYmVyc2hpcCB0aGUgc3Rh
dGUgaXMgZm9yLCBpbiB0aGUgZm9ybToKCiBgcHJvamVjdHMve3B9L2xvY2F0aW9ucy97bH0v
bWVtYmVyc2hpcHMve219YAoKIFdoZXJlIHtwfSBpcyB0aGUgcHJvamVjdCBudW1iZXIsIHts
fSBpcyBhIHZhbGlkIGxvY2F0aW9uIGFuZCB7bX0gaXMgYSB2YWxpZAogTWVtYmVyc2hpcCBp
biB0aGlzIHByb2plY3QgYXQgdGhhdCBsb2NhdGlvbi4ge3B9IE1VU1QgbWF0Y2ggdGhlIEZl
YXR1cmUncwogcHJvamVjdCBudW1iZXIuCgoMCgUEAAIGBhIDWQIlCgwKBQQAAgYBEgNZJjcK
DAoFBAACBgMSA1k6OwoMCgUEAAIGCBIDWgYxCg8KCAQAAgYInAgAEgNaBzAKQwoEBAACBxIE
XQJeMho1IE91dHB1dCBvbmx5LiBXaGVuIHRoZSBGZWF0dXJlIHJlc291cmNlIHdhcyBjcmVh
dGVkLgoKDAoFBAACBwYSA10CGwoMCgUEAAIHARIDXRwnCgwKBQQAAgcDEgNdKisKDAoFBAAC
BwgSA14GMQoPCggEAAIHCJwIABIDXgcwCkgKBAQAAggSBGECYjIaOiBPdXRwdXQgb25seS4g
V2hlbiB0aGUgRmVhdHVyZSByZXNvdXJjZSB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACCAYS
A2ECGwoMCgUEAAIIARIDYRwnCgwKBQQAAggDEgNhKisKDAoFBAACCAgSA2IGMQoPCggEAAII
CJwIABIDYgcwCkMKBAQAAgkSBGUCZjIaNSBPdXRwdXQgb25seS4gV2hlbiB0aGUgRmVhdHVy
ZSByZXNvdXJjZSB3YXMgZGVsZXRlZC4KCgwKBQQAAgkGEgNlAhsKDAoFBAACCQESA2UcJwoM
CgUEAAIJAxIDZSosCgwKBQQAAgkIEgNmBjEKDwoIBAACCQicCAASA2YHMAqDBgoEBAACChIE
eAJ5Lxr0BSBPcHRpb25hbC4gU2NvcGUtc3BlY2lmaWMgY29uZmlndXJhdGlvbiBmb3IgdGhp
cyBGZWF0dXJlLiBJZiB0aGlzIEZlYXR1cmUKIGRvZXMgbm90IHN1cHBvcnQgYW55IHBlci1T
Y29wZSBjb25maWd1cmF0aW9uLCB0aGlzIGZpZWxkIG1heSBiZSB1bnVzZWQuCgogVGhlIGtl
eXMgaW5kaWNhdGUgd2hpY2ggU2NvcGUgdGhlIGNvbmZpZ3VyYXRpb24gaXMgZm9yLCBpbiB0
aGUgZm9ybToKCiBgcHJvamVjdHMve3B9L2xvY2F0aW9ucy9nbG9iYWwvc2NvcGVzL3tzfWAK
CiBXaGVyZSB7cH0gaXMgdGhlIHByb2plY3QsIHtzfSBpcyBhIHZhbGlkIFNjb3BlIGluIHRo
aXMgcHJvamVjdC4KIHtwfSBXSUxMIG1hdGNoIHRoZSBGZWF0dXJlJ3MgcHJvamVjdC4KCiB7
cH0gd2lsbCBhbHdheXMgYmUgcmV0dXJuZWQgYXMgdGhlIHByb2plY3QgbnVtYmVyLCBidXQg
dGhlIHByb2plY3QgSUQgaXMKIGFsc28gYWNjZXB0ZWQgZHVyaW5nIGlucHV0LiBJZiB0aGUg
c2FtZSBTY29wZSBpcyBzcGVjaWZpZWQgaW4gdGhlIG1hcAogdHdpY2UgKHVzaW5nIHRoZSBw
cm9qZWN0IElEIGZvcm0sIGFuZCB0aGUgcHJvamVjdCBudW1iZXIgZm9ybSksIGV4YWN0bHkK
IE9ORSBvZiB0aGUgZW50cmllcyB3aWxsIGJlIHNhdmVkLCB3aXRoIG5vIGd1YXJhbnRlZXMg
YXMgdG8gd2hpY2guIEZvciB0aGlzCiByZWFzb24sIGl0IGlzIHJlY29tbWVuZGVkIHRoZSBz
YW1lIGZvcm1hdCBiZSB1c2VkIGZvciBhbGwgZW50cmllcyB3aGVuCiBtdXRhdGluZyBhIEZl
YXR1cmUuCgoMCgUEAAIKBhIDeAIfCgwKBQQAAgoBEgN4ICsKDAoFBAACCgMSA3guMAoMCgUE
AAIKCBIDeQYuCg8KCAQAAgoInAgAEgN5By0K4AIKBAQAAgsSBoQBAoUBMhrPAiBPdXRwdXQg
b25seS4gU2NvcGUtc3BlY2lmaWMgRmVhdHVyZSBzdGF0dXMuIElmIHRoaXMgRmVhdHVyZSBk
b2VzCiByZXBvcnQgYW55IHBlci1TY29wZSBzdGF0dXMsIHRoaXMgZmllbGQgbWF5IGJlIHVu
dXNlZC4KCiBUaGUga2V5cyBpbmRpY2F0ZSB3aGljaCBTY29wZSB0aGUgc3RhdGUgaXMgZm9y
LCBpbiB0aGUgZm9ybToKCiBgcHJvamVjdHMve3B9L2xvY2F0aW9ucy9nbG9iYWwvc2NvcGVz
L3tzfWAKCiBXaGVyZSB7cH0gaXMgdGhlIHByb2plY3QsIHtzfSBpcyBhIHZhbGlkIFNjb3Bl
IGluIHRoaXMgcHJvamVjdC4KIHtwfSBXSUxMIG1hdGNoIHRoZSBGZWF0dXJlJ3MgcHJvamVj
dC4KCg0KBQQAAgsGEgSEAQIgCg0KBQQAAgsBEgSEASEtCg0KBQQAAgsDEgSEATAyCg0KBQQA
AgsIEgSFAQYxChAKCAQAAgsInAgAEgSFAQcwCmYKBAQAAgwSBIkBAk8aWCBPdXRwdXQgb25s
eS4gTGlzdCBvZiBsb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZCB3aGlsZSBm
ZXRjaGluZwogdGhpcyBmZWF0dXJlLgoKDQoFBAACDAQSBIkBAgoKDQoFBAACDAUSBIkBCxEK
DQoFBAACDAESBIkBEh0KDQoFBAACDAMSBIkBICIKDQoFBAACDAgSBIkBI04KEAoIBAACDAic
CAASBIkBJE0KxQEKAgQBEgaPAQCqAQEatgEgRmVhdHVyZVJlc291cmNlU3RhdGUgZGVzY3Jp
YmVzIHRoZSBzdGF0ZSBvZiBhIEZlYXR1cmUgKnJlc291cmNlKiBpbiB0aGUKIEdrZUh1YiBB
UEkuIFNlZSBgRmVhdHVyZVN0YXRlYCBmb3IgdGhlICJydW5uaW5nIHN0YXRlIiBvZiB0aGUg
RmVhdHVyZSBpbiB0aGUKIEZsZWV0IGFuZCBhY3Jvc3MgTWVtYmVyc2hpcHMuCgoLCgMEAQES
BI8BCBwKRAoEBAEEABIGkQECpgEDGjQgU3RhdGUgZGVzY3JpYmVzIHRoZSBsaWZlY3ljbGUg
c3RhdHVzIG9mIGEgRmVhdHVyZS4KCg0KBQQBBAABEgSRAQcMCi4KBgQBBAACABIEkwEEGhoe
IFN0YXRlIGlzIHVua25vd24gb3Igbm90IHNldC4KCg8KBwQBBAACAAESBJMBBBUKDwoHBAEE
AAIAAhIEkwEYGQqkAQoGBAEEAAIBEgSXAQQRGpMBIFRoZSBGZWF0dXJlIGlzIGJlaW5nIGVu
YWJsZWQsIGFuZCB0aGUgRmVhdHVyZSByZXNvdXJjZSBpcyBiZWluZyBjcmVhdGVkLgogT25j
ZSBjb21wbGV0ZSwgdGhlIGNvcnJlc3BvbmRpbmcgRmVhdHVyZSB3aWxsIGJlIGVuYWJsZWQg
aW4gdGhpcyBGbGVldC4KCg8KBwQBBAACAQESBJcBBAwKDwoHBAEEAAIBAhIElwEPEAplCgYE
AQQAAgISBJsBBA8aVSBUaGUgRmVhdHVyZSBpcyBlbmFibGVkIGluIHRoaXMgRmxlZXQsIGFu
ZCB0aGUgRmVhdHVyZSByZXNvdXJjZSBpcyBmdWxseQogYXZhaWxhYmxlLgoKDwoHBAEEAAIC
ARIEmwEECgoPCgcEAQQAAgICEgSbAQ0OCmoKBgQBBAACAxIEnwEEEhpaIFRoZSBGZWF0dXJl
IGlzIGJlaW5nIGRpc2FibGVkIGluIHRoaXMgRmxlZXQsIGFuZCB0aGUgRmVhdHVyZSByZXNv
dXJjZQogaXMgYmVpbmcgZGVsZXRlZC4KCg8KBwQBBAACAwESBJ8BBA0KDwoHBAEEAAIDAhIE
nwEQEQo4CgYEAQQAAgQSBKIBBBEaKCBUaGUgRmVhdHVyZSByZXNvdXJjZSBpcyBiZWluZyB1
cGRhdGVkLgoKDwoHBAEEAAIEARIEogEEDAoPCgcEAQQAAgQCEgSiAQ8QCksKBgQBBAACBRIE
pQEEGRo7IFRoZSBGZWF0dXJlIHJlc291cmNlIGlzIGJlaW5nIHVwZGF0ZWQgYnkgdGhlIEh1
YiBTZXJ2aWNlLgoKDwoHBAEEAAIFARIEpQEEFAoPCgcEAQQAAgUCEgSlARcYCkkKBAQBAgAS
BKkBAhIaOyBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgRmVhdHVyZSByZXNvdXJjZSBpbiB0
aGUgSHViIEFQSS4KCg0KBQQBAgAGEgSpAQIHCg0KBQQBAgABEgSpAQgNCg0KBQQBAgADEgSp
ARARCrwBCgIEAhIGrwEAzQEBGq0BIEZlYXR1cmVTdGF0ZSBkZXNjcmliZXMgdGhlIGhpZ2gt
bGV2ZWwgc3RhdGUgb2YgYSBGZWF0dXJlLiBJdCBtYXkgYmUgdXNlZCB0bwogZGVzY3JpYmUg
YSBGZWF0dXJlJ3Mgc3RhdGUgYXQgdGhlIGVudmlyb24tbGV2ZWwsIG9yIHBlci1tZW1iZXJz
aG9wLCBkZXBlbmRpbmcKIG9uIHRoZSBjb250ZXh0LgoKCwoDBAIBEgSvAQgUClcKBAQCBAAS
BrEBAsMBAxpHIENvZGUgcmVwcmVzZW50cyBhIG1hY2hpbmUtcmVhZGFibGUsIGhpZ2gtbGV2
ZWwgc3RhdHVzIG9mIHRoZSBGZWF0dXJlLgoKDQoFBAIEAAESBLEBBwsKJQoGBAIEAAIAEgSz
AQQZGhUgVW5rbm93biBvciBub3Qgc2V0LgoKDwoHBAIEAAIAARIEswEEFAoPCgcEAgQAAgAC
EgSzARcYCjQKBgQCBAACARIEtgEECxokIFRoZSBGZWF0dXJlIGlzIG9wZXJhdGluZyBub3Jt
YWxseS4KCg8KBwQCBAACAQESBLYBBAYKDwoHBAIEAAIBAhIEtgEJCgr4AQoGBAIEAAICEgS8
AQQQGucBIFRoZSBGZWF0dXJlIGhhcyBlbmNvdW50ZXJlZCBhbiBpc3N1ZSwgYW5kIGlzIG9w
ZXJhdGluZyBpbiBhIGRlZ3JhZGVkCiBzdGF0ZS4gVGhlIEZlYXR1cmUgbWF5IG5lZWQgaW50
ZXJ2ZW50aW9uIHRvIHJldHVybiB0byBub3JtYWwgb3BlcmF0aW9uLgogU2VlIHRoZSBkZXNj
cmlwdGlvbiBhbmQgYW55IGFzc29jaWF0ZWQgRmVhdHVyZS1zcGVjaWZpYyBkZXRhaWxzIGZv
ciBtb3JlCiBpbmZvcm1hdGlvbi4KCg8KBwQCBAACAgESBLwBBAsKDwoHBAIEAAICAhIEvAEO
DwrtAQoGBAIEAAIDEgTCAQQOGtwBIFRoZSBGZWF0dXJlIGlzIG5vdCBvcGVyYXRpbmcgb3Ig
aXMgaW4gYSBzZXZlcmVseSBkZWdyYWRlZCBzdGF0ZS4KIFRoZSBGZWF0dXJlIG1heSBuZWVk
IGludGVydmVudGlvbiB0byByZXR1cm4gdG8gbm9ybWFsIG9wZXJhdGlvbi4KIFNlZSB0aGUg
ZGVzY3JpcHRpb24gYW5kIGFueSBhc3NvY2lhdGVkIEZlYXR1cmUtc3BlY2lmaWMgZGV0YWls
cyBmb3IgbW9yZQogaW5mb3JtYXRpb24uCgoPCgcEAgQAAgMBEgTCAQQJCg8KBwQCBAACAwIS
BMIBDA0KSAoEBAICABIExgECEBo6IFRoZSBoaWdoLWxldmVsLCBtYWNoaW5lLXJlYWRhYmxl
IHN0YXR1cyBvZiB0aGlzIEZlYXR1cmUuCgoNCgUEAgIABhIExgECBgoNCgUEAgIAARIExgEH
CwoNCgUEAgIAAxIExgEODwpDCgQEAgIBEgTJAQIZGjUgQSBodW1hbi1yZWFkYWJsZSBkZXNj
cmlwdGlvbiBvZiB0aGUgY3VycmVudCBzdGF0dXMuCgoNCgUEAgIBBRIEyQECCAoNCgUEAgIB
ARIEyQEJFAoNCgUEAgIBAxIEyQEXGApbCgQEAgICEgTMAQIsGk0gVGhlIHRpbWUgdGhpcyBz
dGF0dXMgYW5kIGFueSByZWxhdGVkIEZlYXR1cmUtc3BlY2lmaWMgZGV0YWlscyB3ZXJlIHVw
ZGF0ZWQuCgoNCgUEAgICBhIEzAECGwoNCgUEAgICARIEzAEcJwoNCgUEAgICAxIEzAEqKwpN
CgIEAxIG0AEA1gEBGj8gQ29tbW9uRmVhdHVyZVNwZWMgY29udGFpbnMgSHViLXdpZGUgY29u
ZmlndXJhdGlvbiBpbmZvcm1hdGlvbgoKCwoDBAMBEgTQAQgZCg4KBAQDCAASBtEBAtUBAwoN
CgUEAwgAARIE0QEIFAo1CgQEAwIAEgbTAQTUAQwaJSBNdWx0aWNsdXN0ZXIgSW5ncmVzcy1z
cGVjaWZpYyBzcGVjLgoKDQoFBAMCAAYSBNMBBDoKDQoFBAMCAAESBNMBO04KDQoFBAMCAAMS
BNQBCAsKUgoCBAQSBtkBAOIBARpEIENvbW1vbkZlYXR1cmVTdGF0ZSBjb250YWlucyBGbGVl
dC13aWRlIEZlYXR1cmUgc3RhdHVzIGluZm9ybWF0aW9uLgoKCwoDBAQBEgTZAQgaCg4KBAQE
CAASBtoBAt4BAwoNCgUEBAgAARIE2gEIFQo7CgQEBAIAEgbcAQTdAScaKyBSQkFDIFJvbGUg
QmluZGluZyBBY3R1YXRpb24gZmVhdHVyZSBzdGF0ZQoKDQoFBAQCAAYSBNwBBEAKDQoFBAQC
AAESBN0BCCAKDQoFBAQCAAMSBN0BIyYKTgoEBAQCARIE4QECRRpAIE91dHB1dCBvbmx5LiBU
aGUgInJ1bm5pbmcgc3RhdGUiIG9mIHRoZSBGZWF0dXJlIGluIHRoaXMgRmxlZXQuCgoNCgUE
BAIBBhIE4QECDgoNCgUEBAIBARIE4QEPFAoNCgUEBAIBAxIE4QEXGAoNCgUEBAIBCBIE4QEZ
RAoQCggEBAIBCJwIABIE4QEaQwpICgIEBRIE5QEAGxo8IFNjb3BlRmVhdHVyZVNwZWMgY29u
dGFpbnMgZmVhdHVyZSBzcGVjcyBmb3IgYSBmbGVldCBzY29wZS4KCgsKAwQFARIE5QEIGApR
CgIEBhIG6AEA6wEBGkMgU2NvcGVGZWF0dXJlU3RhdGUgY29udGFpbnMgU2NvcGUtd2lkZSBG
ZWF0dXJlIHN0YXR1cyBpbmZvcm1hdGlvbi4KCgsKAwQGARIE6AEIGQpOCgQEBgIAEgTqAQJF
GkAgT3V0cHV0IG9ubHkuIFRoZSAicnVubmluZyBzdGF0ZSIgb2YgdGhlIEZlYXR1cmUgaW4g
dGhpcyBTY29wZS4KCg0KBQQGAgAGEgTqAQIOCg0KBQQGAgABEgTqAQ8UCg0KBQQGAgADEgTq
ARcYCg0KBQQGAgAIEgTqARlEChAKCAQGAgAInAgAEgTqARpDCmIKAgQHEgbvAQD1AQEaVCBN
ZW1iZXJzaGlwRmVhdHVyZVNwZWMgY29udGFpbnMgY29uZmlndXJhdGlvbiBpbmZvcm1hdGlv
biBmb3IgYSBzaW5nbGUKIE1lbWJlcnNoaXAuCgoLCgMEBwESBO8BCB0KDgoEBAcIABIG8AEC
9AEDCg0KBQQHCAABEgTwAQgUCjIKBAQHAgASBvIBBPMBDBoiIENvbmZpZyBNYW5hZ2VtZW50
LXNwZWNpZmljIHNwZWMuCgoNCgUEBwIABhIE8gEEOgoNCgUEBwIAARIE8gE7SwoNCgUEBwIA
AxIE8wEICwpkCgIECBIG+QEAggIBGlYgTWVtYmVyc2hpcEZlYXR1cmVTdGF0ZSBjb250YWlu
cyBGZWF0dXJlIHN0YXR1cyBpbmZvcm1hdGlvbiBmb3IgYSBzaW5nbGUKIE1lbWJlcnNoaXAu
CgoLCgMECAESBPkBCB4KDgoEBAgIABIG+gEC/gEDCg0KBQQICAABEgT6AQgVCjMKBAQIAgAS
BvwBBP0BDBojIENvbmZpZyBNYW5hZ2VtZW50LXNwZWNpZmljIHN0YXRlLgoKDQoFBAgCAAYS
BPwBBDsKDQoFBAgCAAESBPwBPEwKDQoFBAgCAAMSBP0BCAsKTQoEBAgCARIEgQICGRo/IFRo
ZSBoaWdoLWxldmVsIHN0YXRlIG9mIHRoaXMgRmVhdHVyZSBmb3IgYSBzaW5nbGUgbWVtYmVy
c2hpcC4KCg0KBQQIAgEGEgSBAgIOCg0KBQQIAgEBEgSBAg8UCg0KBQQIAgEDEgSBAhcYYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::V1::Feature::Feature ===
    # Fields for Feature
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkehub.v1.Feature.LabelsEntry)
    # Field: resource_state Type: 11 (.google.cloud.gkehub.v1.FeatureResourceState)
    # Field: spec Type: 11 (.google.cloud.gkehub.v1.CommonFeatureSpec)
    # Field: membership_specs Type: 11 (.google.cloud.gkehub.v1.Feature.MembershipSpecsEntry)
    # Field: state Type: 11 (.google.cloud.gkehub.v1.CommonFeatureState)
    # Field: membership_states Type: 11 (.google.cloud.gkehub.v1.Feature.MembershipStatesEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: scope_specs Type: 11 (.google.cloud.gkehub.v1.Feature.ScopeSpecsEntry)
    # Field: scope_states Type: 11 (.google.cloud.gkehub.v1.Feature.ScopeStatesEntry)
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1::Feature::FeatureResourceState ===
    # Fields for FeatureResourceState
    # Field: state Type: 14 (.google.cloud.gkehub.v1.FeatureResourceState.State)

# Enum: FeatureResourceState::State
our $FeatureResourceState_STATE_UNSPECIFIED = 0;
our $FeatureResourceState_ENABLING = 1;
our $FeatureResourceState_ACTIVE = 2;
our $FeatureResourceState_DISABLING = 3;
our $FeatureResourceState_UPDATING = 4;
our $FeatureResourceState_SERVICE_UPDATING = 5;

# === Message: Google::Cloud::Gkehub::V1::Feature::FeatureState ===
    # Fields for FeatureState
    # Field: code Type: 14 (.google.cloud.gkehub.v1.FeatureState.Code)
    # Field: description Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: FeatureState::Code
our $FeatureState_CODE_UNSPECIFIED = 0;
our $FeatureState_OK = 1;
our $FeatureState_WARNING = 2;
our $FeatureState_ERROR = 3;

# === Message: Google::Cloud::Gkehub::V1::Feature::CommonFeatureSpec ===
    # Fields for CommonFeatureSpec
    # Field: multiclusteringress Type: 11 (.google.cloud.gkehub.multiclusteringress.v1.FeatureSpec)

# === Message: Google::Cloud::Gkehub::V1::Feature::CommonFeatureState ===
    # Fields for CommonFeatureState
    # Field: rbacrolebindingactuation Type: 11 (.google.cloud.gkehub.rbacrolebindingactuation.v1.FeatureState)
    # Field: state Type: 11 (.google.cloud.gkehub.v1.FeatureState)

# === Message: Google::Cloud::Gkehub::V1::Feature::ScopeFeatureSpec ===
    # Fields for ScopeFeatureSpec

# === Message: Google::Cloud::Gkehub::V1::Feature::ScopeFeatureState ===
    # Fields for ScopeFeatureState
    # Field: state Type: 11 (.google.cloud.gkehub.v1.FeatureState)

# === Message: Google::Cloud::Gkehub::V1::Feature::MembershipFeatureSpec ===
    # Fields for MembershipFeatureSpec
    # Field: configmanagement Type: 11 (.google.cloud.gkehub.configmanagement.v1.MembershipSpec)

# === Message: Google::Cloud::Gkehub::V1::Feature::MembershipFeatureState ===
    # Fields for MembershipFeatureState
    # Field: configmanagement Type: 11 (.google.cloud.gkehub.configmanagement.v1.MembershipState)
    # Field: state Type: 11 (.google.cloud.gkehub.v1.FeatureState)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::V1::Feature - Compiled Protocol Buffers messages for google/cloud/gkehub/v1/feature.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::V1::Feature;

    my $msg = Google::Cloud::Gkehub::V1::Feature::Feature->new({
        name => $name,
        labels => $labels,
        resource_state => $resource_state,
        spec => $spec,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::V1::Feature::Feature->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1/feature.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::V1::Feature::Feature

Feature represents the settings and status of any Fleet Feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full, unique name of this Feature resource in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::Feature::LabelsEntry>)

Labels for this Feature.

=item * C<< $msg->resource_state() >> / C<< $msg->resource_state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::FeatureResourceState>)

Output only. State of the Feature resource itself.

=item * C<< $msg->spec() >> / C<< $msg->spec($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::CommonFeatureSpec>)

Optional. Fleet-wide Feature configuration. If this Feature does not
support any Fleet-wide configuration, this field may be unused.

=item * C<< $msg->membership_specs() >> / C<< $msg->membership_specs($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::Feature::MembershipSpecsEntry>)

Optional. Membership-specific configuration for this Feature. If this
Feature does not support any per-Membership configuration, this field may
be unused.

The keys indicate which Membership the configuration is for, in the form:

`projects/{p}/locations/{l}/memberships/{m}`

Where {p} is the project, {l} is a valid location and {m} is a valid
Membership in this project at that location. {p} WILL match the Feature's
project.

{p} will always be returned as the project number, but the project ID is
also accepted during input. If the same Membership is specified in the map
twice (using the project ID form, and the project number form), exactly
ONE of the entries will be saved, with no guarantees as to which. For this
reason, it is recommended the same format be used for all entries when
mutating a Feature.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::CommonFeatureState>)

Output only. The Fleet-wide Feature state.

=item * C<< $msg->membership_states() >> / C<< $msg->membership_states($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::Feature::MembershipStatesEntry>)

Output only. Membership-specific Feature status. If this Feature does
report any per-Membership status, this field may be unused.

The keys indicate which Membership the state is for, in the form:

`projects/{p}/locations/{l}/memberships/{m}`

Where {p} is the project number, {l} is a valid location and {m} is a valid
Membership in this project at that location. {p} MUST match the Feature's
project number.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Feature resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Feature resource was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Feature resource was deleted.

=item * C<< $msg->scope_specs() >> / C<< $msg->scope_specs($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::Feature::ScopeSpecsEntry>)

Optional. Scope-specific configuration for this Feature. If this Feature
does not support any per-Scope configuration, this field may be unused.

The keys indicate which Scope the configuration is for, in the form:

`projects/{p}/locations/global/scopes/{s}`

Where {p} is the project, {s} is a valid Scope in this project.
{p} WILL match the Feature's project.

{p} will always be returned as the project number, but the project ID is
also accepted during input. If the same Scope is specified in the map
twice (using the project ID form, and the project number form), exactly
ONE of the entries will be saved, with no guarantees as to which. For this
reason, it is recommended the same format be used for all entries when
mutating a Feature.

=item * C<< $msg->scope_states() >> / C<< $msg->scope_states($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::Feature::ScopeStatesEntry>)

Output only. Scope-specific Feature status. If this Feature does
report any per-Scope status, this field may be unused.

The keys indicate which Scope the state is for, in the form:

`projects/{p}/locations/global/scopes/{s}`

Where {p} is the project, {s} is a valid Scope in this project.
{p} WILL match the Feature's project.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Output only. List of locations that could not be reached while fetching
this feature.

=back

=head2 Google::Cloud::Gkehub::V1::Feature::FeatureResourceState

FeatureResourceState describes the state of a Feature *resource* in the
GkeHub API. See `FeatureState` for the "running state" of the Feature in the
Fleet and across Memberships.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1::FeatureResourceState::State>)

The current state of the Feature resource in the Hub API.

=back

=head3 Enum: FeatureResourceState::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DISABLING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<SERVICE_UPDATING> => C<5>

=back

=head2 Google::Cloud::Gkehub::V1::Feature::FeatureState

FeatureState describes the high-level state of a Feature. It may be used to
describe a Feature's state at the environ-level, or per-membershop, depending
on the context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1::FeatureState::Code>)

The high-level, machine-readable status of this Feature.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the current status.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this status and any related Feature-specific details were updated.

=back

=head3 Enum: FeatureState::Code

=over 4

=item * C<CODE_UNSPECIFIED> => C<0>

=item * C<OK> => C<1>

=item * C<WARNING> => C<2>

=item * C<ERROR> => C<3>

=back

=head2 Google::Cloud::Gkehub::V1::Feature::CommonFeatureSpec

CommonFeatureSpec contains Hub-wide configuration information

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->multiclusteringress() >> / C<< $msg->multiclusteringress($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Multiclusteringress::V1::Multiclusteringress::FeatureSpec>)

Multicluster Ingress-specific spec.

=back

=head2 Google::Cloud::Gkehub::V1::Feature::CommonFeatureState

CommonFeatureState contains Fleet-wide Feature status information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rbacrolebindingactuation() >> / C<< $msg->rbacrolebindingactuation($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Rbacrolebindingactuation::V1::Rbacrolebindingactuation::FeatureState>)

RBAC Role Binding Actuation feature state

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::FeatureState>)

Output only. The "running state" of the Feature in this Fleet.

=back

=head2 Google::Cloud::Gkehub::V1::Feature::ScopeFeatureSpec

ScopeFeatureSpec contains feature specs for a fleet scope.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Gkehub::V1::Feature::ScopeFeatureState

ScopeFeatureState contains Scope-wide Feature status information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::FeatureState>)

Output only. The "running state" of the Feature in this Scope.

=back

=head2 Google::Cloud::Gkehub::V1::Feature::MembershipFeatureSpec

MembershipFeatureSpec contains configuration information for a single
Membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->configmanagement() >> / C<< $msg->configmanagement($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Configmanagement::V1::Configmanagement::MembershipSpec>)

Config Management-specific spec.

=back

=head2 Google::Cloud::Gkehub::V1::Feature::MembershipFeatureState

MembershipFeatureState contains Feature status information for a single
Membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->configmanagement() >> / C<< $msg->configmanagement($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Configmanagement::V1::Configmanagement::MembershipState>)

Config Management-specific state.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1::Feature::FeatureState>)

The high-level state of this Feature for a single membership.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::V1::Feature::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
