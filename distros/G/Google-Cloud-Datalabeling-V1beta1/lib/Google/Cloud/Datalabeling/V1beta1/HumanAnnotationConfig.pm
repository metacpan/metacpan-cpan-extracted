package Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvaHVtYW5fYW5ub3RhdGlvbl9j
b25maWcucHJvdG8SIWdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnBy
b3RvIvoDChVIdW1hbkFubm90YXRpb25Db25maWcSJQoLaW5zdHJ1Y3Rpb24YASABKAlCA+BB
AlILaW5zdHJ1Y3Rpb24SSAoeYW5ub3RhdGVkX2RhdGFzZXRfZGlzcGxheV9uYW1lGAIgASgJ
QgPgQQJSG2Fubm90YXRlZERhdGFzZXREaXNwbGF5TmFtZRJHCh1hbm5vdGF0ZWRfZGF0YXNl
dF9kZXNjcmlwdGlvbhgDIAEoCUID4EEBUhthbm5vdGF0ZWREYXRhc2V0RGVzY3JpcHRpb24S
JAoLbGFiZWxfZ3JvdXAYBCABKAlCA+BBAVIKbGFiZWxHcm91cBIoCg1sYW5ndWFnZV9jb2Rl
GAUgASgJQgPgQQFSDGxhbmd1YWdlQ29kZRIoCg1yZXBsaWNhX2NvdW50GAYgASgFQgPgQQFS
DHJlcGxpY2FDb3VudBJLChFxdWVzdGlvbl9kdXJhdGlvbhgHIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvbkID4EEBUhBxdWVzdGlvbkR1cmF0aW9uEjIKEmNvbnRyaWJ1dG9yX2Vt
YWlscxgJIAMoCUID4EEBUhFjb250cmlidXRvckVtYWlscxIsChJ1c2VyX2VtYWlsX2FkZHJl
c3MYCiABKAlSEHVzZXJFbWFpbEFkZHJlc3Mi+AEKGUltYWdlQ2xhc3NpZmljYXRpb25Db25m
aWcSMwoTYW5ub3RhdGlvbl9zcGVjX3NldBgBIAEoCUID4EECUhFhbm5vdGF0aW9uU3BlY1Nl
dBIvChFhbGxvd19tdWx0aV9sYWJlbBgCIAEoCEID4EEBUg9hbGxvd011bHRpTGFiZWwSdQoX
YW5zd2VyX2FnZ3JlZ2F0aW9uX3R5cGUYAyABKA4yOC5nb29nbGUuY2xvdWQuZGF0YWxhYmVs
aW5nLnYxYmV0YTEuU3RyaW5nQWdncmVnYXRpb25UeXBlQgPgQQFSFWFuc3dlckFnZ3JlZ2F0
aW9uVHlwZSJ/ChJCb3VuZGluZ1BvbHlDb25maWcSMwoTYW5ub3RhdGlvbl9zcGVjX3NldBgB
IAEoCUID4EECUhFhbm5vdGF0aW9uU3BlY1NldBI0ChNpbnN0cnVjdGlvbl9tZXNzYWdlGAIg
ASgJQgPgQQFSEmluc3RydWN0aW9uTWVzc2FnZSJ7Cg5Qb2x5bGluZUNvbmZpZxIzChNhbm5v
dGF0aW9uX3NwZWNfc2V0GAEgASgJQgPgQQJSEWFubm90YXRpb25TcGVjU2V0EjQKE2luc3Ry
dWN0aW9uX21lc3NhZ2UYAiABKAlCA+BBAVISaW5zdHJ1Y3Rpb25NZXNzYWdlInoKElNlZ21l
bnRhdGlvbkNvbmZpZxIzChNhbm5vdGF0aW9uX3NwZWNfc2V0GAEgASgJQgPgQQJSEWFubm90
YXRpb25TcGVjU2V0Ei8KE2luc3RydWN0aW9uX21lc3NhZ2UYAiABKAlSEmluc3RydWN0aW9u
TWVzc2FnZSLuAgoZVmlkZW9DbGFzc2lmaWNhdGlvbkNvbmZpZxKYAQobYW5ub3RhdGlvbl9z
cGVjX3NldF9jb25maWdzGAEgAygLMlQuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJl
dGExLlZpZGVvQ2xhc3NpZmljYXRpb25Db25maWcuQW5ub3RhdGlvblNwZWNTZXRDb25maWdC
A+BBAlIYYW5ub3RhdGlvblNwZWNTZXRDb25maWdzEjUKFGFwcGx5X3Nob3RfZGV0ZWN0aW9u
GAIgASgIQgPgQQFSEmFwcGx5U2hvdERldGVjdGlvbhp/ChdBbm5vdGF0aW9uU3BlY1NldENv
bmZpZxIzChNhbm5vdGF0aW9uX3NwZWNfc2V0GAEgASgJQgPgQQJSEWFubm90YXRpb25TcGVj
U2V0Ei8KEWFsbG93X211bHRpX2xhYmVsGAIgASgIQgPgQQFSD2FsbG93TXVsdGlMYWJlbCKF
AQoVT2JqZWN0RGV0ZWN0aW9uQ29uZmlnEjMKE2Fubm90YXRpb25fc3BlY19zZXQYASABKAlC
A+BBAlIRYW5ub3RhdGlvblNwZWNTZXQSNwoVZXh0cmFjdGlvbl9mcmFtZV9yYXRlGAMgASgB
QgPgQQJSE2V4dHJhY3Rpb25GcmFtZVJhdGUiSwoUT2JqZWN0VHJhY2tpbmdDb25maWcSMwoT
YW5ub3RhdGlvbl9zcGVjX3NldBgBIAEoCUID4EECUhFhbm5vdGF0aW9uU3BlY1NldCJECgtF
dmVudENvbmZpZxI1ChRhbm5vdGF0aW9uX3NwZWNfc2V0cxgBIAMoCUID4EECUhJhbm5vdGF0
aW9uU3BlY1NldHMi5AEKGFRleHRDbGFzc2lmaWNhdGlvbkNvbmZpZxIvChFhbGxvd19tdWx0
aV9sYWJlbBgBIAEoCEID4EEBUg9hbGxvd011bHRpTGFiZWwSMwoTYW5ub3RhdGlvbl9zcGVj
X3NldBgCIAEoCUID4EECUhFhbm5vdGF0aW9uU3BlY1NldBJiChBzZW50aW1lbnRfY29uZmln
GAMgASgLMjIuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLlNlbnRpbWVudENv
bmZpZ0ID4EEBUg9zZW50aW1lbnRDb25maWciWgoPU2VudGltZW50Q29uZmlnEkcKIGVuYWJs
ZV9sYWJlbF9zZW50aW1lbnRfc2VsZWN0aW9uGAEgASgIUh1lbmFibGVMYWJlbFNlbnRpbWVu
dFNlbGVjdGlvbiJRChpUZXh0RW50aXR5RXh0cmFjdGlvbkNvbmZpZxIzChNhbm5vdGF0aW9u
X3NwZWNfc2V0GAEgASgJQgPgQQJSEWFubm90YXRpb25TcGVjU2V0KnsKFVN0cmluZ0FnZ3Jl
Z2F0aW9uVHlwZRInCiNTVFJJTkdfQUdHUkVHQVRJT05fVFlQRV9VTlNQRUNJRklFRBAAEhEK
DU1BSk9SSVRZX1ZPVEUQARISCg5VTkFOSU1PVVNfVk9URRACEhIKDk5PX0FHR1JFR0FUSU9O
EANC4wEKJWNvbS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTFQAVpJY2xvdWQu
Z29vZ2xlLmNvbS9nby9kYXRhbGFiZWxpbmcvYXBpdjFiZXRhMS9kYXRhbGFiZWxpbmdwYjtk
YXRhbGFiZWxpbmdwYqoCIUdvb2dsZS5DbG91ZC5EYXRhTGFiZWxpbmcuVjFCZXRhMcoCIUdv
b2dsZVxDbG91ZFxEYXRhTGFiZWxpbmdcVjFiZXRhMeoCJEdvb2dsZTo6Q2xvdWQ6OkRhdGFM
YWJlbGluZzo6VjFiZXRhMUrEQwoHEgUPANIBAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCgoICgECEgMRACoKCQoCAwASAxMAKQoJCgIDARIDFAAoCggKAQgSAxYAPgoJ
CgIIJRIDFgA+CggKAQgSAxcAYAoJCgIICxIDFwBgCggKAQgSAxgAIgoJCgIIChIDGAAiCggK
AQgSAxkAPgoJCgIIARIDGQA+CggKAQgSAxoAPgoJCgIIKRIDGgA+CggKAQgSAxsAPQoJCgII
LRIDGwA9CgoKAgUAEgQdACgBCgoKAwUAARIDHQUaCgsKBAUAAgASAx4CKgoMCgUFAAIAARID
HgIlCgwKBQUAAgACEgMeKCkKMgoEBQACARIDIQIUGiUgTWFqb3JpdHkgdm90ZSB0byBhZ2dy
ZWdhdGUgYW5zd2Vycy4KCgwKBQUAAgEBEgMhAg8KDAoFBQACAQISAyESEwoxCgQFAAICEgMk
AhUaJCBVbmFuaW1vdXMgYW5zd2VycyB3aWxsIGJlIGFkb3B0ZWQuCgoMCgUFAAICARIDJAIQ
CgwKBQUAAgICEgMkExQKNQoEBQACAxIDJwIVGiggUHJlc2VydmUgYWxsIGFuc3dlcnMgYnkg
Y3Jvd2QgY29tcHV0ZS4KCgwKBQUAAgMBEgMnAhAKDAoFBQACAwISAycTFApHCgIEABIEKwBX
ARo7IENvbmZpZ3VyYXRpb24gZm9yIGhvdyBodW1hbiBsYWJlbGluZyB0YXNrIHNob3VsZCBi
ZSBkb25lLgoKCgoDBAABEgMrCB0KMwoEBAACABIDLQJCGiYgUmVxdWlyZWQuIEluc3RydWN0
aW9uIHJlc291cmNlIG5hbWUuCgoMCgUEAAIABRIDLQIICgwKBQQAAgABEgMtCRQKDAoFBAAC
AAMSAy0XGAoMCgUEAAIACBIDLRlBCg8KCAQAAgAInAgAEgMtGkAKcgoEBAACARIDMgJVGmUg
UmVxdWlyZWQuIEEgaHVtYW4tcmVhZGFibGUgbmFtZSBmb3IgQW5ub3RhdGVkRGF0YXNldCBk
ZWZpbmVkIGJ5CiB1c2Vycy4gTWF4aW11bSBvZiA2NCBjaGFyYWN0ZXJzCiAuCgoMCgUEAAIB
BRIDMgIICgwKBQQAAgEBEgMyCScKDAoFBAACAQMSAzIqKwoMCgUEAAIBCBIDMixUCg8KCAQA
AgEInAgAEgMyLVMKgAEKBAQAAgISAzYCVBpzIE9wdGlvbmFsLiBBIGh1bWFuLXJlYWRhYmxl
IGRlc2NyaXB0aW9uIGZvciBBbm5vdGF0ZWREYXRhc2V0LgogVGhlIGRlc2NyaXB0aW9uIGNh
biBiZSB1cCB0byAxMDAwMCBjaGFyYWN0ZXJzIGxvbmcuCgoMCgUEAAICBRIDNgIICgwKBQQA
AgIBEgM2CSYKDAoFBAACAgMSAzYpKgoMCgUEAAICCBIDNitTCg8KCAQAAgIInAgAEgM2LFIK
nwEKBAQAAgMSAzoCQhqRASBPcHRpb25hbC4gQSBodW1hbi1yZWFkYWJsZSBsYWJlbCB1c2Vk
IHRvIGxvZ2ljYWxseSBncm91cCBsYWJlbGluZyB0YXNrcy4KIFRoaXMgc3RyaW5nIG11c3Qg
bWF0Y2ggdGhlIHJlZ3VsYXIgZXhwcmVzc2lvbiBgW2EtekEtWlxcZF8tXXswLDEyOH1gLgoK
DAoFBAACAwUSAzoCCAoMCgUEAAIDARIDOgkUCgwKBQQAAgMDEgM6FxgKDAoFBAACAwgSAzoZ
QQoPCggEAAIDCJwIABIDOhpACu8BCgQEAAIEEgNBAkQa4QEgT3B0aW9uYWwuIFRoZSBMYW5n
dWFnZSBvZiB0aGlzIHF1ZXN0aW9uLCBhcyBhCiBbQkNQLTQ3XShodHRwczovL3d3dy5yZmMt
ZWRpdG9yLm9yZy9yZmMvYmNwL2JjcDQ3LnR4dCkuCiBEZWZhdWx0IHZhbHVlIGlzIGVuLVVT
LgogT25seSBuZWVkIHRvIHNldCB0aGlzIHdoZW4gdGFzayBpcyBsYW5ndWFnZSByZWxhdGVk
LiBGb3IgZXhhbXBsZSwgRnJlbmNoCiB0ZXh0IGNsYXNzaWZpY2F0aW9uLgoKDAoFBAACBAUS
A0ECCAoMCgUEAAIEARIDQQkWCgwKBQQAAgQDEgNBGRoKDAoFBAACBAgSA0EbQwoPCggEAAIE
CJwIABIDQRxCCvABCgQEAAIFEgNHAkMa4gEgT3B0aW9uYWwuIFJlcGxpY2F0aW9uIG9mIHF1
ZXN0aW9ucy4gRWFjaCBxdWVzdGlvbiB3aWxsIGJlIHNlbnQgdG8gdXAgdG8KIHRoaXMgbnVt
YmVyIG9mIGNvbnRyaWJ1dG9ycyB0byBsYWJlbC4gQWdncmVnYXRlZCBhbnN3ZXJzIHdpbGwg
YmUgcmV0dXJuZWQuCiBEZWZhdWx0IGlzIHNldCB0byAxLgogRm9yIGltYWdlIHJlbGF0ZWQg
bGFiZWxpbmcsIHZhbGlkIHZhbHVlcyBhcmUgMSwgMywgNS4KCgwKBQQAAgUFEgNHAgcKDAoF
BAACBQESA0cIFQoMCgUEAAIFAxIDRxgZCgwKBQQAAgUIEgNHGkIKDwoIBAACBQicCAASA0cb
QQqDAQoEBAACBhIDSwJaGnYgT3B0aW9uYWwuIE1heGltdW0gZHVyYXRpb24gZm9yIGNvbnRy
aWJ1dG9ycyB0byBhbnN3ZXIgYSBxdWVzdGlvbi4gTWF4aW11bQogaXMgMzYwMCBzZWNvbmRz
LiBEZWZhdWx0IGlzIDM2MDAgc2Vjb25kcy4KCgwKBQQAAgYGEgNLAhoKDAoFBAACBgESA0sb
LAoMCgUEAAIGAxIDSy8wCgwKBQQAAgYIEgNLMVkKDwoIBAACBgicCAASA0syWArCAgoEBAAC
BxIDUgJSGrQCIE9wdGlvbmFsLiBJZiB5b3Ugd2FudCB5b3VyIG93biBsYWJlbGluZyBjb250
cmlidXRvcnMgdG8gbWFuYWdlIGFuZCB3b3JrIG9uCiB0aGlzIGxhYmVsaW5nIHJlcXVlc3Qs
IHlvdSBjYW4gc2V0IHRoZXNlIGNvbnRyaWJ1dG9ycyBoZXJlLiBXZSB3aWxsIGdpdmUKIHRo
ZW0gYWNjZXNzIHRvIHRoZSBxdWVzdGlvbiB0eXBlcyBpbiBjcm93ZGNvbXB1dGUuIE5vdGUg
dGhhdCB0aGVzZQogZW1haWxzIG11c3QgYmUgcmVnaXN0ZXJlZCBpbiBjcm93ZGNvbXB1dGUg
d29ya2VyIFVJOgogaHR0cHM6Ly9jcm93ZC1jb21wdXRlLmFwcHNwb3QuY29tLwoKDAoFBAAC
BwQSA1ICCgoMCgUEAAIHBRIDUgsRCgwKBQQAAgcBEgNSEiQKDAoFBAACBwMSA1InKAoMCgUE
AAIHCBIDUilRCg8KCAQAAgcInAgAEgNSKlAKhwEKBAQAAggSA1YCIRp6IEVtYWlsIG9mIHRo
ZSB1c2VyIHdobyBzdGFydGVkIHRoZSBsYWJlbGluZyB0YXNrIGFuZCBzaG91bGQgYmUgbm90
aWZpZWQgYnkKIGVtYWlsLiBJZiBlbXB0eSBubyBub3RpZmljYXRpb24gd2lsbCBiZSBzZW50
LgoKDAoFBAACCAUSA1YCCAoMCgUEAAIIARIDVgkbCgwKBQQAAggDEgNWHiAKQgoCBAESBFoA
ZAEaNiBDb25maWcgZm9yIGltYWdlIGNsYXNzaWZpY2F0aW9uIGh1bWFuIGxhYmVsaW5nIHRh
c2suCgoKCgMEAQESA1oIIQo7CgQEAQIAEgNcAkoaLiBSZXF1aXJlZC4gQW5ub3RhdGlvbiBz
cGVjIHNldCByZXNvdXJjZSBuYW1lLgoKDAoFBAECAAUSA1wCCAoMCgUEAQIAARIDXAkcCgwK
BQQBAgADEgNcHyAKDAoFBAECAAgSA1whSQoPCggEAQIACJwIABIDXCJICnYKBAQBAgESA2AC
RhppIE9wdGlvbmFsLiBJZiBhbGxvd19tdWx0aV9sYWJlbCBpcyB0cnVlLCBjb250cmlidXRv
cnMgYXJlIGFibGUgdG8gY2hvb3NlCiBtdWx0aXBsZSBsYWJlbHMgZm9yIG9uZSBpbWFnZS4K
CgwKBQQBAgEFEgNgAgYKDAoFBAECAQESA2AHGAoMCgUEAQIBAxIDYBscCgwKBQQBAgEIEgNg
HUUKDwoIBAECAQicCAASA2AeRAo+CgQEAQICEgNjAl0aMSBPcHRpb25hbC4gVGhlIHR5cGUg
b2YgaG93IHRvIGFnZ3JlZ2F0ZSBhbnN3ZXJzLgoKDAoFBAECAgYSA2MCFwoMCgUEAQICARID
YxgvCgwKBQQBAgIDEgNjMjMKDAoFBAECAggSA2M0XAoPCggEAQICCJwIABIDYzVbClQKAgQC
EgRnAG0BGkggQ29uZmlnIGZvciBpbWFnZSBib3VuZGluZyBwb2x5IChhbmQgYm91bmRpbmcg
Ym94KSBodW1hbiBsYWJlbGluZyB0YXNrLgoKCgoDBAIBEgNnCBoKOwoEBAICABIDaQJKGi4g
UmVxdWlyZWQuIEFubm90YXRpb24gc3BlYyBzZXQgcmVzb3VyY2UgbmFtZS4KCgwKBQQCAgAF
EgNpAggKDAoFBAICAAESA2kJHAoMCgUEAgIAAxIDaR8gCgwKBQQCAgAIEgNpIUkKDwoIBAIC
AAicCAASA2kiSApHCgQEAgIBEgNsAkoaOiBPcHRpb25hbC4gSW5zdHJ1Y3Rpb24gbWVzc2Fn
ZSBzaG93ZWQgb24gY29udHJpYnV0b3JzIFVJLgoKDAoFBAICAQUSA2wCCAoMCgUEAgIBARID
bAkcCgwKBQQCAgEDEgNsHyAKDAoFBAICAQgSA2whSQoPCggEAgIBCJwIABIDbCJICjwKAgQD
EgRwAHYBGjAgQ29uZmlnIGZvciBpbWFnZSBwb2x5bGluZSBodW1hbiBsYWJlbGluZyB0YXNr
LgoKCgoDBAMBEgNwCBYKOwoEBAMCABIDcgJKGi4gUmVxdWlyZWQuIEFubm90YXRpb24gc3Bl
YyBzZXQgcmVzb3VyY2UgbmFtZS4KCgwKBQQDAgAFEgNyAggKDAoFBAMCAAESA3IJHAoMCgUE
AwIAAxIDch8gCgwKBQQDAgAIEgNyIUkKDwoIBAMCAAicCAASA3IiSApHCgQEAwIBEgN1Akoa
OiBPcHRpb25hbC4gSW5zdHJ1Y3Rpb24gbWVzc2FnZSBzaG93ZWQgb24gY29udHJpYnV0b3Jz
IFVJLgoKDAoFBAMCAQUSA3UCCAoMCgUEAwIBARIDdQkcCgwKBQQDAgEDEgN1HyAKDAoFBAMC
AQgSA3UhSQoPCggEAwIBCJwIABIDdSJICiwKAgQEEgV5AIABARofIENvbmZpZyBmb3IgaW1h
Z2Ugc2VnbWVudGF0aW9uCgoKCgMEBAESA3kIGgqGAQoEBAQCABIDfAJKGnkgUmVxdWlyZWQu
IEFubm90YXRpb24gc3BlYyBzZXQgcmVzb3VyY2UgbmFtZS4gZm9ybWF0OgogcHJvamVjdHMv
e3Byb2plY3RfaWR9L2Fubm90YXRpb25TcGVjU2V0cy97YW5ub3RhdGlvbl9zcGVjX3NldF9p
ZH0KCgwKBQQEAgAFEgN8AggKDAoFBAQCAAESA3wJHAoMCgUEBAIAAxIDfB8gCgwKBQQEAgAI
EgN8IUkKDwoIBAQCAAicCAASA3wiSAo5CgQEBAIBEgN/AiEaLCBJbnN0cnVjdGlvbiBtZXNz
YWdlIHNob3dlZCBvbiBsYWJlbGVycyBVSS4KCgwKBQQEAgEFEgN/AggKDAoFBAQCAQESA38J
HAoMCgUEBAIBAxIDfx8gCpMCCgIEBRIGhwEAnAEBGoQCIENvbmZpZyBmb3IgdmlkZW8gY2xh
c3NpZmljYXRpb24gaHVtYW4gbGFiZWxpbmcgdGFzay4KIEN1cnJlbnRseSB0d28gdHlwZXMg
b2YgdmlkZW8gY2xhc3NpZmljYXRpb24gYXJlIHN1cHBvcnRlZDoKIDEuIEFzc2lnbiBsYWJl
bHMgb24gdGhlIGVudGlyZSB2aWRlby4KIDIuIFNwbGl0IHRoZSB2aWRlbyBpbnRvIG11bHRp
cGxlIHZpZGVvIGNsaXBzIGJhc2VkIG9uIGNhbWVyYSBzaG90LCBhbmQKIGFzc2lnbiBsYWJl
bHMgb24gZWFjaCB2aWRlbyBjbGlwLgoKCwoDBAUBEgSHAQghClcKBAQFAwASBokBApABAxpH
IEFubm90YXRpb24gc3BlYyBzZXQgd2l0aCB0aGUgc2V0dGluZyBvZiBhbGxvd2luZyBtdWx0
aSBsYWJlbHMgb3Igbm90LgoKDQoFBAUDAAESBIkBCiEKPgoGBAUDAAIAEgSLAQRMGi4gUmVx
dWlyZWQuIEFubm90YXRpb24gc3BlYyBzZXQgcmVzb3VyY2UgbmFtZS4KCg8KBwQFAwACAAUS
BIsBBAoKDwoHBAUDAAIAARIEiwELHgoPCgcEBQMAAgADEgSLASEiCg8KBwQFAwACAAgSBIsB
I0sKEgoKBAUDAAIACJwIABIEiwEkSgqIAQoGBAUDAAIBEgSPAQRIGnggT3B0aW9uYWwuIElm
IGFsbG93X211bHRpX2xhYmVsIGlzIHRydWUsIGNvbnRyaWJ1dG9ycyBhcmUgYWJsZSB0bwog
Y2hvb3NlIG11bHRpcGxlIGxhYmVscyBmcm9tIG9uZSBhbm5vdGF0aW9uIHNwZWMgc2V0LgoK
DwoHBAUDAAIBBRIEjwEECAoPCgcEBQMAAgEBEgSPAQkaCg8KBwQFAwACAQMSBI8BHR4KDwoH
BAUDAAIBCBIEjwEfRwoSCgoEBQMAAgEInAgAEgSPASBGCvkCCgQEBQIAEgSYAQJsGuoCIFJl
cXVpcmVkLiBUaGUgbGlzdCBvZiBhbm5vdGF0aW9uIHNwZWMgc2V0IGNvbmZpZ3MuCiBTaW5j
ZSB3YXRjaGluZyBhIHZpZGVvIGNsaXAgdGFrZXMgbXVjaCBsb25nZXIgdGltZSB0aGFuIGFu
IGltYWdlLCB3ZQogc3VwcG9ydCBsYWJlbCB3aXRoIG11bHRpcGxlIEFubm90YXRpb25TcGVj
U2V0IGF0IHRoZSBzYW1lIHRpbWUuIExhYmVscwogaW4gZWFjaCBBbm5vdGF0aW9uU3BlY1Nl
dCB3aWxsIGJlIHNob3duIGluIGEgZ3JvdXAgdG8gY29udHJpYnV0b3JzLgogQ29udHJpYnV0
b3JzIGNhbiBzZWxlY3Qgb25lIG9yIG1vcmUgKGRlcGVuZGluZyBvbiB3aGV0aGVyIHRvIGFs
bG93IG11bHRpCiBsYWJlbCkgZnJvbSBlYWNoIGdyb3VwLgoKDQoFBAUCAAQSBJgBAgoKDQoF
BAUCAAYSBJgBCyIKDQoFBAUCAAESBJgBIz4KDQoFBAUCAAMSBJgBQUIKDQoFBAUCAAgSBJgB
Q2sKEAoIBAUCAAicCAASBJgBRGoKRgoEBAUCARIEmwECSRo4IE9wdGlvbmFsLiBPcHRpb24g
dG8gYXBwbHkgc2hvdCBkZXRlY3Rpb24gb24gdGhlIHZpZGVvLgoKDQoFBAUCAQUSBJsBAgYK
DQoFBAUCAQESBJsBBxsKDQoFBAUCAQMSBJsBHh8KDQoFBAUCAQgSBJsBIEgKEAoIBAUCAQic
CAASBJsBIUcKsAIKAgQGEgajAQCpAQEaoQIgQ29uZmlnIGZvciB2aWRlbyBvYmplY3QgZGV0
ZWN0aW9uIGh1bWFuIGxhYmVsaW5nIHRhc2suCiBPYmplY3QgZGV0ZWN0aW9uIHdpbGwgYmUg
Y29uZHVjdGVkIG9uIHRoZSBpbWFnZXMgZXh0cmFjdGVkIGZyb20gdGhlIHZpZGVvLAogYW5k
IHRob3NlIG9iamVjdHMgd2lsbCBiZSBsYWJlbGVkIHdpdGggYm91bmRpbmcgYm94ZXMuCiBV
c2VyIG5lZWQgdG8gc3BlY2lmeSB0aGUgbnVtYmVyIG9mIGltYWdlcyB0byBiZSBleHRyYWN0
ZWQgcGVyIHNlY29uZCBhcyB0aGUKIGV4dHJhY3Rpb24gZnJhbWUgcmF0ZS4KCgsKAwQGARIE
owEIHQo8CgQEBgIAEgSlAQJKGi4gUmVxdWlyZWQuIEFubm90YXRpb24gc3BlYyBzZXQgcmVz
b3VyY2UgbmFtZS4KCg0KBQQGAgAFEgSlAQIICg0KBQQGAgABEgSlAQkcCg0KBQQGAgADEgSl
AR8gCg0KBQQGAgAIEgSlASFJChAKCAQGAgAInAgAEgSlASJIClUKBAQGAgESBKgBAkwaRyBS
ZXF1aXJlZC4gTnVtYmVyIG9mIGZyYW1lcyBwZXIgc2Vjb25kIHRvIGJlIGV4dHJhY3RlZCBm
cm9tIHRoZSB2aWRlby4KCg0KBQQGAgEFEgSoAQIICg0KBQQGAgEBEgSoAQkeCg0KBQQGAgED
EgSoASEiCg0KBQQGAgEIEgSoASNLChAKCAQGAgEInAgAEgSoASRKCkUKAgQHEgasAQCvAQEa
NyBDb25maWcgZm9yIHZpZGVvIG9iamVjdCB0cmFja2luZyBodW1hbiBsYWJlbGluZyB0YXNr
LgoKCwoDBAcBEgSsAQgcCjwKBAQHAgASBK4BAkoaLiBSZXF1aXJlZC4gQW5ub3RhdGlvbiBz
cGVjIHNldCByZXNvdXJjZSBuYW1lLgoKDQoFBAcCAAUSBK4BAggKDQoFBAcCAAESBK4BCRwK
DQoFBAcCAAMSBK4BHyAKDQoFBAcCAAgSBK4BIUkKEAoIBAcCAAicCAASBK4BIkgKOwoCBAgS
BrIBALcBARotIENvbmZpZyBmb3IgdmlkZW8gZXZlbnQgaHVtYW4gbGFiZWxpbmcgdGFzay4K
CgsKAwQIARIEsgEIEwq5AQoEBAgCABIEtgECVBqqASBSZXF1aXJlZC4gVGhlIGxpc3Qgb2Yg
YW5ub3RhdGlvbiBzcGVjIHNldCByZXNvdXJjZSBuYW1lLiBTaW1pbGFyIHRvIHZpZGVvCiBj
bGFzc2lmaWNhdGlvbiwgd2Ugc3VwcG9ydCBzZWxlY3RpbmcgZXZlbnQgZnJvbSBtdWx0aXBs
ZSBBbm5vdGF0aW9uU3BlY1NldAogYXQgdGhlIHNhbWUgdGltZS4KCg0KBQQIAgAEEgS2AQIK
Cg0KBQQIAgAFEgS2AQsRCg0KBQQIAgABEgS2ARImCg0KBQQIAgADEgS2ASkqCg0KBQQIAgAI
EgS2AStTChAKCAQIAgAInAgAEgS2ASxSCkMKAgQJEga6AQDEAQEaNSBDb25maWcgZm9yIHRl
eHQgY2xhc3NpZmljYXRpb24gaHVtYW4gbGFiZWxpbmcgdGFzay4KCgsKAwQJARIEugEIIAp+
CgQECQIAEgS9AQJGGnAgT3B0aW9uYWwuIElmIGFsbG93X211bHRpX2xhYmVsIGlzIHRydWUs
IGNvbnRyaWJ1dG9ycyBhcmUgYWJsZSB0byBjaG9vc2UKIG11bHRpcGxlIGxhYmVscyBmb3Ig
b25lIHRleHQgc2VnbWVudC4KCg0KBQQJAgAFEgS9AQIGCg0KBQQJAgABEgS9AQcYCg0KBQQJ
AgADEgS9ARscCg0KBQQJAgAIEgS9AR1FChAKCAQJAgAInAgAEgS9AR5ECjwKBAQJAgESBMAB
AkoaLiBSZXF1aXJlZC4gQW5ub3RhdGlvbiBzcGVjIHNldCByZXNvdXJjZSBuYW1lLgoKDQoF
BAkCAQUSBMABAggKDQoFBAkCAQESBMABCRwKDQoFBAkCAQMSBMABHyAKDQoFBAkCAQgSBMAB
IUkKEAoIBAkCAQicCAASBMABIkgKOgoEBAkCAhIEwwECUBosIE9wdGlvbmFsLiBDb25maWdz
IGZvciBzZW50aW1lbnQgc2VsZWN0aW9uLgoKDQoFBAkCAgYSBMMBAhEKDQoFBAkCAgESBMMB
EiIKDQoFBAkCAgMSBMMBJSYKDQoFBAkCAggSBMMBJ08KEAoIBAkCAgicCAASBMMBKE4KMQoC
BAoSBscBAMwBARojIENvbmZpZyBmb3Igc2V0dGluZyB1cCBzZW50aW1lbnRzLgoKCwoDBAoB
EgTHAQgXCrABCgQECgIAEgTLAQIsGqEBIElmIHNldCB0byB0cnVlLCBjb250cmlidXRvcnMg
d2lsbCBoYXZlIHRoZSBvcHRpb24gdG8gc2VsZWN0IHNlbnRpbWVudCBvZgogdGhlIGxhYmVs
IHRoZXkgc2VsZWN0ZWQsIHRvIG1hcmsgaXQgYXMgbmVnYXRpdmUgb3IgcG9zaXRpdmUgbGFi
ZWwuIERlZmF1bHQKIGlzIGZhbHNlLgoKDQoFBAoCAAUSBMsBAgYKDQoFBAoCAAESBMsBBycK
DQoFBAoCAAMSBMsBKisKRgoCBAsSBs8BANIBARo4IENvbmZpZyBmb3IgdGV4dCBlbnRpdHkg
ZXh0cmFjdGlvbiBodW1hbiBsYWJlbGluZyB0YXNrLgoKCwoDBAsBEgTPAQgiCjwKBAQLAgAS
BNEBAkoaLiBSZXF1aXJlZC4gQW5ub3RhdGlvbiBzcGVjIHNldCByZXNvdXJjZSBuYW1lLgoK
DQoFBAsCAAUSBNEBAggKDQoFBAsCAAESBNEBCRwKDQoFBAsCAAMSBNEBHyAKDQoFBAsCAAgS
BNEBIUkKEAoIBAsCAAicCAASBNEBIkhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig ===
    # Fields for HumanAnnotationConfig
    # Field: instruction Type: 9 ()
    # Field: annotated_dataset_display_name Type: 9 ()
    # Field: annotated_dataset_description Type: 9 ()
    # Field: label_group Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: replica_count Type: 5 ()
    # Field: question_duration Type: 11 (.google.protobuf.Duration)
    # Field: contributor_emails Type: 9 ()
    # Field: user_email_address Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig ===
    # Fields for ImageClassificationConfig
    # Field: annotation_spec_set Type: 9 ()
    # Field: allow_multi_label Type: 8 ()
    # Field: answer_aggregation_type Type: 14 (.google.cloud.datalabeling.v1beta1.StringAggregationType)

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig ===
    # Fields for BoundingPolyConfig
    # Field: annotation_spec_set Type: 9 ()
    # Field: instruction_message Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::PolylineConfig ===
    # Fields for PolylineConfig
    # Field: annotation_spec_set Type: 9 ()
    # Field: instruction_message Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SegmentationConfig ===
    # Fields for SegmentationConfig
    # Field: annotation_spec_set Type: 9 ()
    # Field: instruction_message Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig ===
    # Fields for VideoClassificationConfig
    # Field: annotation_spec_set_configs Type: 11 (.google.cloud.datalabeling.v1beta1.VideoClassificationConfig.AnnotationSpecSetConfig)
    # Field: apply_shot_detection Type: 8 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectDetectionConfig ===
    # Fields for ObjectDetectionConfig
    # Field: annotation_spec_set Type: 9 ()
    # Field: extraction_frame_rate Type: 1 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectTrackingConfig ===
    # Fields for ObjectTrackingConfig
    # Field: annotation_spec_set Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::EventConfig ===
    # Fields for EventConfig
    # Field: annotation_spec_sets Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig ===
    # Fields for TextClassificationConfig
    # Field: allow_multi_label Type: 8 ()
    # Field: annotation_spec_set Type: 9 ()
    # Field: sentiment_config Type: 11 (.google.cloud.datalabeling.v1beta1.SentimentConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SentimentConfig ===
    # Fields for SentimentConfig
    # Field: enable_label_sentiment_selection Type: 8 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextEntityExtractionConfig ===
    # Fields for TextEntityExtractionConfig
    # Field: annotation_spec_set Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/human_annotation_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig;

    my $msg = Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig->new({
        instruction => $instruction,
        annotated_dataset_display_name => $annotated_dataset_display_name,
        annotated_dataset_description => $annotated_dataset_description,
        label_group => $label_group,
    });

    # Read or update a field
    my $val = $msg->instruction();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/human_annotation_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig

Configuration for how human labeling task should be done.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instruction() >> / C<< $msg->instruction($value) >>

Type: C<String>

Required. Instruction resource name.

=item * C<< $msg->annotated_dataset_display_name() >> / C<< $msg->annotated_dataset_display_name($value) >>

Type: C<String>

Required. A human-readable name for AnnotatedDataset defined by
users. Maximum of 64 characters
.

=item * C<< $msg->annotated_dataset_description() >> / C<< $msg->annotated_dataset_description($value) >>

Type: C<String>

Optional. A human-readable description for AnnotatedDataset.
The description can be up to 10000 characters long.

=item * C<< $msg->label_group() >> / C<< $msg->label_group($value) >>

Type: C<String>

Optional. A human-readable label used to logically group labeling tasks.
This string must match the regular expression `[a-zA-Z\\d_-]{0,128}`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. The Language of this question, as a
[BCP-47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt).
Default value is en-US.
Only need to set this when task is language related. For example, French
text classification.

=item * C<< $msg->replica_count() >> / C<< $msg->replica_count($value) >>

Type: C<Int32>

Optional. Replication of questions. Each question will be sent to up to
this number of contributors to label. Aggregated answers will be returned.
Default is set to 1.
For image related labeling, valid values are 1, 3, 5.

=item * C<< $msg->question_duration() >> / C<< $msg->question_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Maximum duration for contributors to answer a question. Maximum
is 3600 seconds. Default is 3600 seconds.

=item * C<< $msg->contributor_emails() >> / C<< $msg->contributor_emails($value) >>

Type: C<String>

Optional. If you want your own labeling contributors to manage and work on
this labeling request, you can set these contributors here. We will give
them access to the question types in crowdcompute. Note that these
emails must be registered in crowdcompute worker UI:
https://crowd-compute.appspot.com/

=item * C<< $msg->user_email_address() >> / C<< $msg->user_email_address($value) >>

Type: C<String>

Email of the user who started the labeling task and should be notified by
email. If empty no notification will be sent.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig

Config for image classification human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=item * C<< $msg->allow_multi_label() >> / C<< $msg->allow_multi_label($value) >>

Type: C<Bool>

Optional. If allow_multi_label is true, contributors are able to choose
multiple labels for one image.

=item * C<< $msg->answer_aggregation_type() >> / C<< $msg->answer_aggregation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::StringAggregationType>)

Optional. The type of how to aggregate answers.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig

Config for image bounding poly (and bounding box) human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=item * C<< $msg->instruction_message() >> / C<< $msg->instruction_message($value) >>

Type: C<String>

Optional. Instruction message showed on contributors UI.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::PolylineConfig

Config for image polyline human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=item * C<< $msg->instruction_message() >> / C<< $msg->instruction_message($value) >>

Type: C<String>

Optional. Instruction message showed on contributors UI.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SegmentationConfig

Config for image segmentation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name. format:
projects/{project_id}/annotationSpecSets/{annotation_spec_set_id}

=item * C<< $msg->instruction_message() >> / C<< $msg->instruction_message($value) >>

Type: C<String>

Instruction message showed on labelers UI.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig

Config for video classification human labeling task.
Currently two types of video classification are supported:
1. Assign labels on the entire video.
2. Split the video into multiple video clips based on camera shot, and
assign labels on each video clip.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set_configs() >> / C<< $msg->annotation_spec_set_configs($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig::AnnotationSpecSetConfig>)

Required. The list of annotation spec set configs.
Since watching a video clip takes much longer time than an image, we
support label with multiple AnnotationSpecSet at the same time. Labels
in each AnnotationSpecSet will be shown in a group to contributors.
Contributors can select one or more (depending on whether to allow multi
label) from each group.

=item * C<< $msg->apply_shot_detection() >> / C<< $msg->apply_shot_detection($value) >>

Type: C<Bool>

Optional. Option to apply shot detection on the video.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectDetectionConfig

Config for video object detection human labeling task.
Object detection will be conducted on the images extracted from the video,
and those objects will be labeled with bounding boxes.
User need to specify the number of images to be extracted per second as the
extraction frame rate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=item * C<< $msg->extraction_frame_rate() >> / C<< $msg->extraction_frame_rate($value) >>

Type: C<Double>

Required. Number of frames per second to be extracted from the video.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectTrackingConfig

Config for video object tracking human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::EventConfig

Config for video event human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_sets() >> / C<< $msg->annotation_spec_sets($value) >>

Type: C<String>

Required. The list of annotation spec set resource name. Similar to video
classification, we support selecting event from multiple AnnotationSpecSet
at the same time.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig

Config for text classification human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->allow_multi_label() >> / C<< $msg->allow_multi_label($value) >>

Type: C<Bool>

Optional. If allow_multi_label is true, contributors are able to choose
multiple labels for one text segment.

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=item * C<< $msg->sentiment_config() >> / C<< $msg->sentiment_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SentimentConfig>)

Optional. Configs for sentiment selection.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SentimentConfig

Config for setting up sentiments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_label_sentiment_selection() >> / C<< $msg->enable_label_sentiment_selection($value) >>

Type: C<Bool>

If set to true, contributors will have the option to select sentiment of
the label they selected, to mark it as negative or positive label. Default
is false.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextEntityExtractionConfig

Config for text entity extraction human labeling task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Annotation spec set resource name.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
