package Google::Iam::V2beta::Policy;

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
    eval { require Google::Iam::V2beta::Deny };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ch5nb29nbGUvaWFtL3YyYmV0YS9wb2xpY3kucHJvdG8SEWdvb2dsZS5pYW0udjJiZXRhGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxocZ29vZ2xlL2lhbS92MmJldGEvZGVu
eS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8ikQQKBlBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQVS
BG5hbWUSFQoDdWlkGAIgASgJQgPgQQVSA3VpZBIXCgRraW5kGAMgASgJQgPgQQNSBGtpbmQS
IQoMZGlzcGxheV9uYW1lGAQgASgJUgtkaXNwbGF5TmFtZRJMCgthbm5vdGF0aW9ucxgFIAMo
CzIqLmdvb2dsZS5pYW0udjJiZXRhLlBvbGljeS5Bbm5vdGF0aW9uc0VudHJ5Ugthbm5vdGF0
aW9ucxISCgRldGFnGAYgASgJUgRldGFnEkAKC2NyZWF0ZV90aW1lGAcgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAgg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkAKC2Rl
bGV0ZV90aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpkZWxl
dGVUaW1lEjMKBXJ1bGVzGAogAygLMh0uZ29vZ2xlLmlhbS52MmJldGEuUG9saWN5UnVsZVIF
cnVsZXMaPgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBInIKClBvbGljeVJ1bGUSOgoJZGVueV9ydWxlGAIgASgLMhsuZ29v
Z2xlLmlhbS52MmJldGEuRGVueVJ1bGVIAFIIZGVueVJ1bGUSIAoLZGVzY3JpcHRpb24YASAB
KAlSC2Rlc2NyaXB0aW9uQgYKBGtpbmQibgoTTGlzdFBvbGljaWVzUmVxdWVzdBIbCgZwYXJl
bnQYASABKAlCA+BBAlIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoK
cGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuInUKFExpc3RQb2xpY2llc1Jlc3BvbnNlEjUK
CHBvbGljaWVzGAEgAygLMhkuZ29vZ2xlLmlhbS52MmJldGEuUG9saWN5Ughwb2xpY2llcxIm
Cg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iKwoQR2V0UG9saWN5UmVx
dWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUihwEKE0NyZWF0ZVBvbGljeVJlcXVlc3QS
GwoGcGFyZW50GAEgASgJQgPgQQJSBnBhcmVudBI2CgZwb2xpY3kYAiABKAsyGS5nb29nbGUu
aWFtLnYyYmV0YS5Qb2xpY3lCA+BBAlIGcG9saWN5EhsKCXBvbGljeV9pZBgDIAEoCVIIcG9s
aWN5SWQiTQoTVXBkYXRlUG9saWN5UmVxdWVzdBI2CgZwb2xpY3kYASABKAsyGS5nb29nbGUu
aWFtLnYyYmV0YS5Qb2xpY3lCA+BBAlIGcG9saWN5IkcKE0RlbGV0ZVBvbGljeVJlcXVlc3QS
FwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEhcKBGV0YWcYAiABKAlCA+BBAVIEZXRhZyJWChdQ
b2xpY3lPcGVyYXRpb25NZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUygAcKCFBvbGljaWVzEo8BCgxMaXN0UG9s
aWNpZXMSJi5nb29nbGUuaWFtLnYyYmV0YS5MaXN0UG9saWNpZXNSZXF1ZXN0GicuZ29vZ2xl
LmlhbS52MmJldGEuTGlzdFBvbGljaWVzUmVzcG9uc2UiLoLT5JMCHxIdL3YyYmV0YS97cGFy
ZW50PXBvbGljaWVzLyovKn3aQQZwYXJlbnQSeQoJR2V0UG9saWN5EiMuZ29vZ2xlLmlhbS52
MmJldGEuR2V0UG9saWN5UmVxdWVzdBoZLmdvb2dsZS5pYW0udjJiZXRhLlBvbGljeSIsgtPk
kwIfEh0vdjJiZXRhL3tuYW1lPXBvbGljaWVzLyovKi8qfdpBBG5hbWUSwgEKDENyZWF0ZVBv
bGljeRImLmdvb2dsZS5pYW0udjJiZXRhLkNyZWF0ZVBvbGljeVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uImuC0+STAiciHS92MmJldGEve3BhcmVudD1wb2xpY2ll
cy8qLyp9OgZwb2xpY3naQRdwYXJlbnQscG9saWN5LHBvbGljeV9pZMpBIQoGUG9saWN5EhdQ
b2xpY3lPcGVyYXRpb25NZXRhZGF0YRKvAQoMVXBkYXRlUG9saWN5EiYuZ29vZ2xlLmlhbS52
MmJldGEuVXBkYXRlUG9saWN5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24iWILT5JMCLhokL3YyYmV0YS97cG9saWN5Lm5hbWU9cG9saWNpZXMvKi8qLyp9OgZwb2xp
Y3nKQSEKBlBvbGljeRIXUG9saWN5T3BlcmF0aW9uTWV0YWRhdGESpwEKDERlbGV0ZVBvbGlj
eRImLmdvb2dsZS5pYW0udjJiZXRhLkRlbGV0ZVBvbGljeVJlcXVlc3QaHS5nb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uIlCC0+STAh8qHS92MmJldGEve25hbWU9cG9saWNpZXMvKi8q
Lyp92kEEbmFtZcpBIQoGUG9saWN5EhdQb2xpY3lPcGVyYXRpb25NZXRhZGF0YRpGykESaWFt
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybUKJAQoVY29tLmdvb2dsZS5pYW0udjJiZXRhQgtQb2xpY3lQcm90b1ABWi1j
bG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2MmJldGEvaWFtcGI7aWFtcGKqAhdHb29nbGUu
Q2xvdWQuSWFtLlYyQmV0YcoCF0dvb2dsZVxDbG91ZFxJYW1cVjJiZXRhSqNOCgcSBQ4AmgIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAaCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACYKCQoCAwQSAxYALQoJCgIDBRID
FwApCggKAQgSAxkANAoJCgIIJRIDGQA0CggKAQgSAxoARAoJCgIICxIDGgBECggKAQgSAxsA
IgoJCgIIChIDGwAiCggKAQgSAxwALAoJCgIICBIDHAAsCggKAQgSAx0ALgoJCgIIARIDHQAu
CggKAQgSAx4ANAoJCgIIKRIDHgA0ClYKAgYAEgQhAGcBGkogQW4gaW50ZXJmYWNlIGZvciBt
YW5hZ2luZyBJZGVudGl0eSBhbmQgQWNjZXNzIE1hbmFnZW1lbnQgKElBTSkgcG9saWNpZXMu
CgoKCgMGAAESAyEIEAoKCgMGAAMSAyICOgoMCgUGAAOZCBIDIgI6CgoKAwYAAxIDIwJWCgwK
BQYAA5oIEgMjAlYKtAEKBAYAAgASBCoCLwMapQEgUmV0cmlldmVzIHRoZSBwb2xpY2llcyBv
ZiB0aGUgc3BlY2lmaWVkIGtpbmQgdGhhdCBhcmUgYXR0YWNoZWQgdG8gYQogcmVzb3VyY2Uu
CgogVGhlIHJlc3BvbnNlIGxpc3RzIG9ubHkgcG9saWN5IG1ldGFkYXRhLiBJbiBwYXJ0aWN1
bGFyLCBwb2xpY3kgcnVsZXMgYXJlCiBvbWl0dGVkLgoKDAoFBgACAAESAyoGEgoMCgUGAAIA
AhIDKhMmCgwKBQYAAgADEgMqMUUKDQoFBgACAAQSBCsELQYKEQoJBgACAASwyrwiEgQrBC0G
CgwKBQYAAgAEEgMuBDQKDwoIBgACAASbCAASAy4ENAoeCgQGAAIBEgQyAjcDGhAgR2V0cyBh
IHBvbGljeS4KCgwKBQYAAgEBEgMyBg8KDAoFBgACAQISAzIQIAoMCgUGAAIBAxIDMisxCg0K
BQYAAgEEEgQzBDUGChEKCQYAAgEEsMq8IhIEMwQ1BgoMCgUGAAIBBBIDNgQyCg8KCAYAAgEE
mwgAEgM2BDIKIQoEBgACAhIEOgJEAxoTIENyZWF0ZXMgYSBwb2xpY3kuCgoMCgUGAAICARID
OgYSCgwKBQYAAgICEgM6EyYKDAoFBgACAgMSAzoxTQoNCgUGAAICBBIEOwQ+BgoRCgkGAAIC
BLDKvCISBDsEPgYKDAoFBgACAgQSAz8ERQoPCggGAAICBJsIABIDPwRFCg0KBQYAAgIEEgRA
BEMGCg8KBwYAAgIEmQgSBEAEQwYKsAMKBAYAAgMSBFECWgMaoQMgVXBkYXRlcyB0aGUgc3Bl
Y2lmaWVkIHBvbGljeS4KCiBZb3UgY2FuIHVwZGF0ZSBvbmx5IHRoZSBydWxlcyBhbmQgdGhl
IGRpc3BsYXkgbmFtZSBmb3IgdGhlIHBvbGljeS4KCiBUbyB1cGRhdGUgYSBwb2xpY3ksIHlv
dSBzaG91bGQgdXNlIGEgcmVhZC1tb2RpZnktd3JpdGUgbG9vcDoKCiAxLiBVc2UgW0dldFBv
bGljeV1bZ29vZ2xlLmlhbS52MmJldGEuUG9saWNpZXMuR2V0UG9saWN5XSB0byByZWFkIHRo
ZSBjdXJyZW50IHZlcnNpb24gb2YgdGhlIHBvbGljeS4KIDIuIE1vZGlmeSB0aGUgcG9saWN5
IGFzIG5lZWRlZC4KIDMuIFVzZSBgVXBkYXRlUG9saWN5YCB0byB3cml0ZSB0aGUgdXBkYXRl
ZCBwb2xpY3kuCgogVGhpcyBwYXR0ZXJuIGhlbHBzIHByZXZlbnQgY29uZmxpY3RzIGJldHdl
ZW4gY29uY3VycmVudCB1cGRhdGVzLgoKDAoFBgACAwESA1EGEgoMCgUGAAIDAhIDURMmCgwK
BQYAAgMDEgNRMU0KDQoFBgACAwQSBFIEVQYKEQoJBgACAwSwyrwiEgRSBFUGCg0KBQYAAgME
EgRWBFkGCg8KBwYAAgMEmQgSBFYEWQYKOwoEBgACBBIEXQJmAxotIERlbGV0ZXMgYSBwb2xp
Y3kuIFRoaXMgYWN0aW9uIGlzIHBlcm1hbmVudC4KCgwKBQYAAgQBEgNdBhIKDAoFBgACBAIS
A10TJgoMCgUGAAIEAxIDXTFNCg0KBQYAAgQEEgReBGAGChEKCQYAAgQEsMq8IhIEXgRgBgoM
CgUGAAIEBBIDYQQyCg8KCAYAAgQEmwgAEgNhBDIKDQoFBgACBAQSBGIEZQYKDwoHBgACBASZ
CBIEYgRlBgomCgIEABIFagCcAQEaGSBEYXRhIGZvciBhbiBJQU0gcG9saWN5LgoKCgoDBAAB
EgNqCA4K3gQKBAQAAgASA3cCPBrQBCBJbW11dGFibGUuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBgUG9saWN5YCwgd2hpY2ggbXVzdCBiZSB1bmlxdWUuIEZvcm1hdDoKIGBwb2xpY2ll
cy97YXR0YWNobWVudF9wb2ludH0vZGVueXBvbGljaWVzL3twb2xpY3lfaWR9YAoKCiBUaGUg
YXR0YWNobWVudCBwb2ludCBpcyBpZGVudGlmaWVkIGJ5IGl0cyBVUkwtZW5jb2RlZCBmdWxs
IHJlc291cmNlIG5hbWUsCiB3aGljaCBtZWFucyB0aGF0IHRoZSBmb3J3YXJkLXNsYXNoIGNo
YXJhY3RlciwgYC9gLCBtdXN0IGJlIHdyaXR0ZW4gYXMKIGAlMkZgLiBGb3IgZXhhbXBsZSwK
IGBwb2xpY2llcy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbSUyRnByb2pl
Y3RzJTJGbXktcHJvamVjdC9kZW55cG9saWNpZXMvbXktZGVueS1wb2xpY3lgLgoKIEZvciBv
cmdhbml6YXRpb25zIGFuZCBmb2xkZXJzLCB1c2UgdGhlIG51bWVyaWMgSUQgaW4gdGhlIGZ1
bGwgcmVzb3VyY2UKIG5hbWUuIEZvciBwcm9qZWN0cywgcmVxdWVzdHMgY2FuIHVzZSB0aGUg
YWxwaGFudW1lcmljIG9yIHRoZSBudW1lcmljIElELgogUmVzcG9uc2VzIGFsd2F5cyBjb250
YWluIHRoZSBudW1lcmljIElELgoKDAoFBAACAAUSA3cCCAoMCgUEAAIAARIDdwkNCgwKBQQA
AgADEgN3EBEKDAoFBAACAAgSA3cSOwoPCggEAAIACJwIABIDdxM6CncKBAQAAgESA3sCOxpq
IEltbXV0YWJsZS4gVGhlIGdsb2JhbGx5IHVuaXF1ZSBJRCBvZiB0aGUgYFBvbGljeWAuIEFz
c2lnbmVkIGF1dG9tYXRpY2FsbHkgd2hlbiB0aGUKIGBQb2xpY3lgIGlzIGNyZWF0ZWQuCgoM
CgUEAAIBBRIDewIICgwKBQQAAgEBEgN7CQwKDAoFBAACAQMSA3sPEAoMCgUEAAIBCBIDexE6
Cg8KCAQAAgEInAgAEgN7EjkKXQoEBAACAhIDfgI+GlAgT3V0cHV0IG9ubHkuIFRoZSBraW5k
IG9mIHRoZSBgUG9saWN5YC4gQWx3YXlzIGNvbnRhaW5zIHRoZSB2YWx1ZSBgRGVueVBvbGlj
eWAuCgoMCgUEAAICBRIDfgIICgwKBQQAAgIBEgN+CQ0KDAoFBAACAgMSA34QEQoMCgUEAAIC
CBIDfhI9Cg8KCAQAAgIInAgAEgN+EzwKZQoEBAACAxIEggECGhpXIEEgdXNlci1zcGVjaWZp
ZWQgZGVzY3JpcHRpb24gb2YgdGhlIGBQb2xpY3lgLiBUaGlzIHZhbHVlIGNhbiBiZSB1cCB0
byA2MwogY2hhcmFjdGVycy4KCg0KBQQAAgMFEgSCAQIICg0KBQQAAgMBEgSCAQkVCg0KBQQA
AgMDEgSCARgZCpQBCgQEAAIEEgSGAQImGoUBIEEga2V5LXZhbHVlIG1hcCB0byBzdG9yZSBh
cmJpdHJhcnkgbWV0YWRhdGEgZm9yIHRoZSBgUG9saWN5YC4gS2V5cwogY2FuIGJlIHVwIHRv
IDYzIGNoYXJhY3RlcnMuIFZhbHVlcyBjYW4gYmUgdXAgdG8gMjU1IGNoYXJhY3RlcnMuCgoN
CgUEAAIEBhIEhgECFQoNCgUEAAIEARIEhgEWIQoNCgUEAAIEAxIEhgEkJQqbAgoEBAACBRIE
jgECEhqMAiBBbiBvcGFxdWUgdGFnIHRoYXQgaWRlbnRpZmllcyB0aGUgY3VycmVudCB2ZXJz
aW9uIG9mIHRoZSBgUG9saWN5YC4gSUFNIHVzZXMKIHRoaXMgdmFsdWUgdG8gaGVscCBtYW5h
Z2UgY29uY3VycmVudCB1cGRhdGVzLCBzbyB0aGV5IGRvIG5vdCBjYXVzZSBvbmUKIHVwZGF0
ZSB0byBiZSBvdmVyd3JpdHRlbiBieSBhbm90aGVyLgoKIElmIHRoaXMgZmllbGQgaXMgcHJl
c2VudCBpbiBhIFtDcmVhdGVQb2xpY3ldW10gcmVxdWVzdCwgdGhlIHZhbHVlIGlzCiBpZ25v
cmVkLgoKDQoFBAACBQUSBI4BAggKDQoFBAACBQESBI4BCQ0KDQoFBAACBQMSBI4BEBEKRAoE
BAACBhIEkQECWBo2IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBgUG9saWN5YCB3
YXMgY3JlYXRlZC4KCg0KBQQAAgYGEgSRAQIbCg0KBQQAAgYBEgSRARwnCg0KBQQAAgYDEgSR
ASorCg0KBQQAAgYIEgSRASxXChAKCAQAAgYInAgAEgSRAS1WCkkKBAQAAgcSBJQBAlgaOyBP
dXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgYFBvbGljeWAgd2FzIGxhc3QgdXBkYXRl
ZC4KCg0KBQQAAgcGEgSUAQIbCg0KBQQAAgcBEgSUARwnCg0KBQQAAgcDEgSUASorCg0KBQQA
AgcIEgSUASxXChAKCAQAAgcInAgAEgSUAS1WCmgKBAQAAggSBJcBAlgaWiBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgd2hlbiB0aGUgYFBvbGljeWAgd2FzIGRlbGV0ZWQuIEVtcHR5IGlmIHRo
ZSBwb2xpY3kgaXMgbm90IGRlbGV0ZWQuCgoNCgUEAAIIBhIElwECGwoNCgUEAAIIARIElwEc
JwoNCgUEAAIIAxIElwEqKwoNCgUEAAIICBIElwEsVwoQCggEAAIICJwIABIElwEtVgqQAQoE
BAACCRIEmwECIRqBASBBIGxpc3Qgb2YgcnVsZXMgdGhhdCBzcGVjaWZ5IHRoZSBiZWhhdmlv
ciBvZiB0aGUgYFBvbGljeWAuIEFsbCBvZiB0aGUgcnVsZXMKIHNob3VsZCBiZSBvZiB0aGUg
YGtpbmRgIHNwZWNpZmllZCBpbiB0aGUgYFBvbGljeWAuCgoNCgUEAAIJBBIEmwECCgoNCgUE
AAIJBhIEmwELFQoNCgUEAAIJARIEmwEWGwoNCgUEAAIJAxIEmwEeIAosCgIEARIGnwEAqAEB
Gh4gQSBzaW5nbGUgcnVsZSBpbiBhIGBQb2xpY3lgLgoKCwoDBAEBEgSfAQgSCg4KBAQBCAAS
BqABAqMBAwoNCgUEAQgAARIEoAEIDAopCgQEAQIAEgSiAQQbGhsgQSBydWxlIGZvciBhIGRl
bnkgcG9saWN5LgoKDQoFBAECAAYSBKIBBAwKDQoFBAECAAESBKIBDRYKDQoFBAECAAMSBKIB
GRoKYgoEBAECARIEpwECGRpUIEEgdXNlci1zcGVjaWZpZWQgZGVzY3JpcHRpb24gb2YgdGhl
IHJ1bGUuIFRoaXMgdmFsdWUgY2FuIGJlIHVwIHRvIDI1NgogY2hhcmFjdGVycy4KCg0KBQQB
AgEFEgSnAQIICg0KBQQBAgEBEgSnAQkUCg0KBQQBAgEDEgSnARcYCjMKAgQCEgarAQDBAQEa
JSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBMaXN0UG9saWNpZXNgLgoKCwoDBAIBEgSrAQgbCrAE
CgQEAgIAEgS4AQI9GqEEIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgdGhhdCB0aGUgcG9saWN5
IGlzIGF0dGFjaGVkIHRvLCBhbG9uZyB3aXRoIHRoZSBraW5kIG9mIHBvbGljeQogdG8gbGlz
dC4gRm9ybWF0OgogYHBvbGljaWVzL3thdHRhY2htZW50X3BvaW50fS9kZW55cG9saWNpZXNg
CgoKIFRoZSBhdHRhY2htZW50IHBvaW50IGlzIGlkZW50aWZpZWQgYnkgaXRzIFVSTC1lbmNv
ZGVkIGZ1bGwgcmVzb3VyY2UgbmFtZSwKIHdoaWNoIG1lYW5zIHRoYXQgdGhlIGZvcndhcmQt
c2xhc2ggY2hhcmFjdGVyLCBgL2AsIG11c3QgYmUgd3JpdHRlbiBhcwogYCUyRmAuIEZvciBl
eGFtcGxlLAogYHBvbGljaWVzL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29t
JTJGcHJvamVjdHMlMkZteS1wcm9qZWN0L2Rlbnlwb2xpY2llc2AuCgogRm9yIG9yZ2FuaXph
dGlvbnMgYW5kIGZvbGRlcnMsIHVzZSB0aGUgbnVtZXJpYyBJRCBpbiB0aGUgZnVsbCByZXNv
dXJjZQogbmFtZS4gRm9yIHByb2plY3RzLCB5b3UgY2FuIHVzZSB0aGUgYWxwaGFudW1lcmlj
IG9yIHRoZSBudW1lcmljIElELgoKDQoFBAICAAUSBLgBAggKDQoFBAICAAESBLgBCQ8KDQoF
BAICAAMSBLgBEhMKDQoFBAICAAgSBLgBFDwKEAoIBAICAAicCAASBLgBFTsKagoEBAICARIE
vAECFhpcIFRoZSBtYXhpbXVtIG51bWJlciBvZiBwb2xpY2llcyB0byByZXR1cm4uIElBTSBp
Z25vcmVzIHRoaXMgdmFsdWUgYW5kIHVzZXMKIHRoZSB2YWx1ZSAxMDAwLgoKDQoFBAICAQUS
BLwBAgcKDQoFBAICAQESBLwBCBEKDQoFBAICAQMSBLwBFBUKmgEKBAQCAgISBMABAhgaiwEg
QSBwYWdlIHRva2VuIHJlY2VpdmVkIGluIGEgW0xpc3RQb2xpY2llc1Jlc3BvbnNlXVtnb29n
bGUuaWFtLnYyYmV0YS5MaXN0UG9saWNpZXNSZXNwb25zZV0uIFByb3ZpZGUgdGhpcyB0b2tl
biB0bwogcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KCg0KBQQCAgIFEgTAAQIICg0KBQQCAgIB
EgTAAQkTCg0KBQQCAgIDEgTAARYXCjQKAgQDEgbEAQDLAQEaJiBSZXNwb25zZSBtZXNzYWdl
IGZvciBgTGlzdFBvbGljaWVzYC4KCgsKAwQDARIExAEIHApMCgQEAwIAEgTGAQIfGj4gTWV0
YWRhdGEgZm9yIHRoZSBwb2xpY2llcyB0aGF0IGFyZSBhdHRhY2hlZCB0byB0aGUgcmVzb3Vy
Y2UuCgoNCgUEAwIABBIExgECCgoNCgUEAwIABhIExgELEQoNCgUEAwIAARIExgESGgoNCgUE
AwIAAxIExgEdHgrFAQoEBAMCARIEygECHRq2ASBBIHBhZ2UgdG9rZW4gdGhhdCB5b3UgY2Fu
IHVzZSBpbiBhIFtMaXN0UG9saWNpZXNSZXF1ZXN0XVtnb29nbGUuaWFtLnYyYmV0YS5MaXN0
UG9saWNpZXNSZXF1ZXN0XSB0byByZXRyaWV2ZSB0aGUKIG5leHQgcGFnZS4gSWYgdGhpcyBm
aWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gYWRkaXRpb25hbCBwYWdlcy4KCg0KBQQD
AgEFEgTKAQIICg0KBQQDAgEBEgTKAQkYCg0KBQQDAgEDEgTKARscCjAKAgQEEgbOAQDaAQEa
IiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBHZXRQb2xpY3lgLgoKCwoDBAQBEgTOAQgYCvsDCgQE
BAIAEgTZAQI7GuwDIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcG9saWN5
IHRvIHJldHJpZXZlLiBGb3JtYXQ6CiBgcG9saWNpZXMve2F0dGFjaG1lbnRfcG9pbnR9L2Rl
bnlwb2xpY2llcy97cG9saWN5X2lkfWAKCgogVXNlIHRoZSBVUkwtZW5jb2RlZCBmdWxsIHJl
c291cmNlIG5hbWUsIHdoaWNoIG1lYW5zIHRoYXQgdGhlIGZvcndhcmQtc2xhc2gKIGNoYXJh
Y3RlciwgYC9gLCBtdXN0IGJlIHdyaXR0ZW4gYXMgYCUyRmAuIEZvciBleGFtcGxlLAogYHBv
bGljaWVzL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tJTJGcHJvamVjdHMl
MkZteS1wcm9qZWN0L2Rlbnlwb2xpY2llcy9teS1wb2xpY3lgLgoKIEZvciBvcmdhbml6YXRp
b25zIGFuZCBmb2xkZXJzLCB1c2UgdGhlIG51bWVyaWMgSUQgaW4gdGhlIGZ1bGwgcmVzb3Vy
Y2UKIG5hbWUuIEZvciBwcm9qZWN0cywgeW91IGNhbiB1c2UgdGhlIGFscGhhbnVtZXJpYyBv
ciB0aGUgbnVtZXJpYyBJRC4KCg0KBQQEAgAFEgTZAQIICg0KBQQEAgABEgTZAQkNCg0KBQQE
AgADEgTZARARCg0KBQQEAgAIEgTZARI6ChAKCAQEAgAInAgAEgTZARM5CjMKAgQFEgbdAQDz
AQEaJSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBDcmVhdGVQb2xpY3lgLgoKCwoDBAUBEgTdAQgb
CrEECgQEBQIAEgTpAQI9GqIEIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgdGhhdCB0aGUgcG9s
aWN5IGlzIGF0dGFjaGVkIHRvLCBhbG9uZyB3aXRoIHRoZSBraW5kIG9mIHBvbGljeQogdG8g
Y3JlYXRlLiBGb3JtYXQ6IGBwb2xpY2llcy97YXR0YWNobWVudF9wb2ludH0vZGVueXBvbGlj
aWVzYAoKCiBUaGUgYXR0YWNobWVudCBwb2ludCBpcyBpZGVudGlmaWVkIGJ5IGl0cyBVUkwt
ZW5jb2RlZCBmdWxsIHJlc291cmNlIG5hbWUsCiB3aGljaCBtZWFucyB0aGF0IHRoZSBmb3J3
YXJkLXNsYXNoIGNoYXJhY3RlciwgYC9gLCBtdXN0IGJlIHdyaXR0ZW4gYXMKIGAlMkZgLiBG
b3IgZXhhbXBsZSwKIGBwb2xpY2llcy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlz
LmNvbSUyRnByb2plY3RzJTJGbXktcHJvamVjdC9kZW55cG9saWNpZXNgLgoKIEZvciBvcmdh
bml6YXRpb25zIGFuZCBmb2xkZXJzLCB1c2UgdGhlIG51bWVyaWMgSUQgaW4gdGhlIGZ1bGwg
cmVzb3VyY2UKIG5hbWUuIEZvciBwcm9qZWN0cywgeW91IGNhbiB1c2UgdGhlIGFscGhhbnVt
ZXJpYyBvciB0aGUgbnVtZXJpYyBJRC4KCg0KBQQFAgAFEgTpAQIICg0KBQQFAgABEgTpAQkP
Cg0KBQQFAgADEgTpARITCg0KBQQFAgAIEgTpARQ8ChAKCAQFAgAInAgAEgTpARU7Ci8KBAQF
AgESBOwBAj0aISBSZXF1aXJlZC4gVGhlIHBvbGljeSB0byBjcmVhdGUuCgoNCgUEBQIBBhIE
7AECCAoNCgUEBQIBARIE7AEJDwoNCgUEBQIBAxIE7AESEwoNCgUEBQIBCBIE7AEUPAoQCggE
BQIBCJwIABIE7AEVOwqoAgoEBAUCAhIE8gECFxqZAiBUaGUgSUQgdG8gdXNlIGZvciB0aGlz
IHBvbGljeSwgd2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsIGNvbXBvbmVudCBvZgogdGhl
IHBvbGljeSdzIHJlc291cmNlIG5hbWUuIFRoZSBJRCBtdXN0IGNvbnRhaW4gMyB0byA2MyBj
aGFyYWN0ZXJzLiBJdCBjYW4KIGNvbnRhaW4gbG93ZXJjYXNlIGxldHRlcnMgYW5kIG51bWJl
cnMsIGFzIHdlbGwgYXMgZGFzaGVzIChgLWApIGFuZCBwZXJpb2RzCiAoYC5gKS4gVGhlIGZp
cnN0IGNoYXJhY3RlciBtdXN0IGJlIGEgbG93ZXJjYXNlIGxldHRlci4KCg0KBQQFAgIFEgTy
AQIICg0KBQQFAgIBEgTyAQkSCg0KBQQFAgIDEgTyARUWCjMKAgQGEgb2AQD9AQEaJSBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIGBVcGRhdGVQb2xpY3lgLgoKCwoDBAYBEgT2AQgbCvQBCgQEBgIA
EgT8AQI9GuUBIFJlcXVpcmVkLiBUaGUgcG9saWN5IHRvIHVwZGF0ZS4KCiBUbyBwcmV2ZW50
IGNvbmZsaWN0aW5nIHVwZGF0ZXMsIHRoZSBgZXRhZ2AgdmFsdWUgbXVzdCBtYXRjaCB0aGUg
dmFsdWUgdGhhdAogaXMgc3RvcmVkIGluIElBTS4gSWYgdGhlIGBldGFnYCB2YWx1ZXMgZG8g
bm90IG1hdGNoLCB0aGUgcmVxdWVzdCBmYWlscyB3aXRoCiBhIGA0MDlgIGVycm9yIGNvZGUg
YW5kIGBBQk9SVEVEYCBzdGF0dXMuCgoNCgUEBgIABhIE/AECCAoNCgUEBgIAARIE/AEJDwoN
CgUEBgIAAxIE/AESEwoNCgUEBgIACBIE/AEUPAoQCggEBgIACJwIABIE/AEVOwozCgIEBxIG
gAIAlAIBGiUgUmVxdWVzdCBtZXNzYWdlIGZvciBgRGVsZXRlUG9saWN5YC4KCgsKAwQHARIE
gAIIGwr5AwoEBAcCABIEiwICOxrqAyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIHBvbGljeSB0byBkZWxldGUuIEZvcm1hdDoKIGBwb2xpY2llcy97YXR0YWNobWVudF9w
b2ludH0vZGVueXBvbGljaWVzL3twb2xpY3lfaWR9YAoKCiBVc2UgdGhlIFVSTC1lbmNvZGVk
IGZ1bGwgcmVzb3VyY2UgbmFtZSwgd2hpY2ggbWVhbnMgdGhhdCB0aGUgZm9yd2FyZC1zbGFz
aAogY2hhcmFjdGVyLCBgL2AsIG11c3QgYmUgd3JpdHRlbiBhcyBgJTJGYC4gRm9yIGV4YW1w
bGUsCiBgcG9saWNpZXMvY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20lMkZw
cm9qZWN0cyUyRm15LXByb2plY3QvZGVueXBvbGljaWVzL215LXBvbGljeWAuCgogRm9yIG9y
Z2FuaXphdGlvbnMgYW5kIGZvbGRlcnMsIHVzZSB0aGUgbnVtZXJpYyBJRCBpbiB0aGUgZnVs
bCByZXNvdXJjZQogbmFtZS4gRm9yIHByb2plY3RzLCB5b3UgY2FuIHVzZSB0aGUgYWxwaGFu
dW1lcmljIG9yIHRoZSBudW1lcmljIElELgoKDQoFBAcCAAUSBIsCAggKDQoFBAcCAAESBIsC
CQ0KDQoFBAcCAAMSBIsCEBEKDQoFBAcCAAgSBIsCEjoKEAoIBAcCAAicCAASBIsCEzkKmQIK
BAQHAgESBJMCAjsaigIgT3B0aW9uYWwuIFRoZSBleHBlY3RlZCBgZXRhZ2Agb2YgdGhlIHBv
bGljeSB0byBkZWxldGUuIElmIHRoZSB2YWx1ZSBkb2VzIG5vdCBtYXRjaAogdGhlIHZhbHVl
IHRoYXQgaXMgc3RvcmVkIGluIElBTSwgdGhlIHJlcXVlc3QgZmFpbHMgd2l0aCBhIGA0MDlg
IGVycm9yIGNvZGUKIGFuZCBgQUJPUlRFRGAgc3RhdHVzLgoKIElmIHlvdSBvbWl0IHRoaXMg
ZmllbGQsIHRoZSBwb2xpY3kgaXMgZGVsZXRlZCByZWdhcmRsZXNzIG9mIGl0cyBjdXJyZW50
CiBgZXRhZ2AuCgoNCgUEBwIBBRIEkwICCAoNCgUEBwIBARIEkwIJDQoNCgUEBwIBAxIEkwIQ
EQoNCgUEBwIBCBIEkwISOgoQCggEBwIBCJwIABIEkwITOQo+CgIECBIGlwIAmgIBGjAgTWV0
YWRhdGEgZm9yIGxvbmctcnVubmluZyBgUG9saWN5YCBvcGVyYXRpb25zLgoKCwoDBAgBEgSX
AggfCk4KBAQIAgASBJkCAiwaQCBUaW1lc3RhbXAgd2hlbiB0aGUgYGdvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb25gIHdhcyBjcmVhdGVkLgoKDQoFBAgCAAYSBJkCAhsKDQoFBAgCAAES
BJkCHCcKDQoFBAgCAAMSBJkCKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V2beta::Policy::Policy ===
    # Fields for Policy
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: kind Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v2beta.Policy.AnnotationsEntry)
    # Field: etag Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: rules Type: 11 (.google.iam.v2beta.PolicyRule)

# === Message: Google::Iam::V2beta::Policy::PolicyRule ===
    # Fields for PolicyRule
    # Field: deny_rule Type: 11 (.google.iam.v2beta.DenyRule)
    # Field: description Type: 9 ()

# === Message: Google::Iam::V2beta::Policy::ListPoliciesRequest ===
    # Fields for ListPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V2beta::Policy::ListPoliciesResponse ===
    # Fields for ListPoliciesResponse
    # Field: policies Type: 11 (.google.iam.v2beta.Policy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V2beta::Policy::GetPolicyRequest ===
    # Fields for GetPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V2beta::Policy::CreatePolicyRequest ===
    # Fields for CreatePolicyRequest
    # Field: parent Type: 9 ()
    # Field: policy Type: 11 (.google.iam.v2beta.Policy)
    # Field: policy_id Type: 9 ()

# === Message: Google::Iam::V2beta::Policy::UpdatePolicyRequest ===
    # Fields for UpdatePolicyRequest
    # Field: policy Type: 11 (.google.iam.v2beta.Policy)

# === Message: Google::Iam::V2beta::Policy::DeletePolicyRequest ===
    # Fields for DeletePolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

# === Message: Google::Iam::V2beta::Policy::PolicyOperationMetadata ===
    # Fields for PolicyOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Iam::V2beta::Policy::PoliciesClient ===
package Google::Iam::V2beta::Policy::PoliciesClient;

=pod

=head2 Service Client: Google::Iam::V2beta::Policy::PoliciesClient

Client stub representing the remote C<Policies> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<iam.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iam.googleapis.com:443' );

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

sub list_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2beta::Policy::ListPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2beta.Policies',
        method         => 'ListPolicies',
        request        => $req,
        response_class => 'Google::Iam::V2beta::Policy::ListPoliciesResponse',
    });
}

sub get_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2beta::Policy::GetPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2beta.Policies',
        method         => 'GetPolicy',
        request        => $req,
        response_class => 'Google::Iam::V2beta::Policy::Policy',
    });
}

sub create_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2beta::Policy::CreatePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2beta.Policies',
        method         => 'CreatePolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2beta::Policy::UpdatePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2beta.Policies',
        method         => 'UpdatePolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2beta::Policy::DeletePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2beta.Policies',
        method         => 'DeletePolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V2beta::Policy - Compiled Protocol Buffers messages for google/iam/v2beta/policy.proto

=head1 SYNOPSIS

    use Google::Iam::V2beta::Policy;

    my $msg = Google::Iam::V2beta::Policy::Policy->new({
        name => $name,
        uid => $uid,
        kind => $kind,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V2beta::Policy::Policy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v2beta/policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V2beta::Policy::Policy

Data for an IAM policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the `Policy`, which must be unique. Format:
`policies/{attachment_point}/denypolicies/{policy_id}`


The attachment point is identified by its URL-encoded full resource name,
which means that the forward-slash character, `/`, must be written as
`%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies/my-deny-policy`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, requests can use the alphanumeric or the numeric ID.
Responses always contain the numeric ID.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Immutable. The globally unique ID of the `Policy`. Assigned automatically when the
`Policy` is created.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

Output only. The kind of the `Policy`. Always contains the value `DenyPolicy`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A user-specified description of the `Policy`. This value can be up to 63
characters.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Iam::V2beta::Policy::Policy::AnnotationsEntry>)

A key-value map to store arbitrary metadata for the `Policy`. Keys
can be up to 63 characters. Values can be up to 255 characters.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

An opaque tag that identifies the current version of the `Policy`. IAM uses
this value to help manage concurrent updates, so they do not cause one
update to be overwritten by another.

If this field is present in a [CreatePolicy][] request, the value is
ignored.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the `Policy` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the `Policy` was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the `Policy` was deleted. Empty if the policy is not deleted.

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Iam::V2beta::Policy::PolicyRule>)

A list of rules that specify the behavior of the `Policy`. All of the rules
should be of the `kind` specified in the `Policy`.

=back

=head2 Google::Iam::V2beta::Policy::PolicyRule

A single rule in a `Policy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deny_rule() >> / C<< $msg->deny_rule($value) >>

Type: C<Message> (L<Google::Iam::V2beta::Deny::DenyRule>)

A rule for a deny policy.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A user-specified description of the rule. This value can be up to 256
characters.

=back

=head2 Google::Iam::V2beta::Policy::ListPoliciesRequest

Request message for `ListPolicies`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource that the policy is attached to, along with the kind of policy
to list. Format:
`policies/{attachment_point}/denypolicies`


The attachment point is identified by its URL-encoded full resource name,
which means that the forward-slash character, `/`, must be written as
`%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of policies to return. IAM ignores this value and uses
the value 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token received in a [ListPoliciesResponse][google.iam.v2beta.ListPoliciesResponse]. Provide this token to
retrieve the next page.

=back

=head2 Google::Iam::V2beta::Policy::ListPoliciesResponse

Response message for `ListPolicies`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policies() >> / C<< $msg->policies($value) >>

Type: C<Message> (L<Google::Iam::V2beta::Policy::Policy>)

Metadata for the policies that are attached to the resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A page token that you can use in a [ListPoliciesRequest][google.iam.v2beta.ListPoliciesRequest] to retrieve the
next page. If this field is omitted, there are no additional pages.

=back

=head2 Google::Iam::V2beta::Policy::GetPolicyRequest

Request message for `GetPolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the policy to retrieve. Format:
`policies/{attachment_point}/denypolicies/{policy_id}`


Use the URL-encoded full resource name, which means that the forward-slash
character, `/`, must be written as `%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies/my-policy`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=back

=head2 Google::Iam::V2beta::Policy::CreatePolicyRequest

Request message for `CreatePolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource that the policy is attached to, along with the kind of policy
to create. Format: `policies/{attachment_point}/denypolicies`


The attachment point is identified by its URL-encoded full resource name,
which means that the forward-slash character, `/`, must be written as
`%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V2beta::Policy::Policy>)

Required. The policy to create.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

The ID to use for this policy, which will become the final component of
the policy's resource name. The ID must contain 3 to 63 characters. It can
contain lowercase letters and numbers, as well as dashes (`-`) and periods
(`.`). The first character must be a lowercase letter.

=back

=head2 Google::Iam::V2beta::Policy::UpdatePolicyRequest

Request message for `UpdatePolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V2beta::Policy::Policy>)

Required. The policy to update.

To prevent conflicting updates, the `etag` value must match the value that
is stored in IAM. If the `etag` values do not match, the request fails with
a `409` error code and `ABORTED` status.

=back

=head2 Google::Iam::V2beta::Policy::DeletePolicyRequest

Request message for `DeletePolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the policy to delete. Format:
`policies/{attachment_point}/denypolicies/{policy_id}`


Use the URL-encoded full resource name, which means that the forward-slash
character, `/`, must be written as `%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies/my-policy`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The expected `etag` of the policy to delete. If the value does not match
the value that is stored in IAM, the request fails with a `409` error code
and `ABORTED` status.

If you omit this field, the policy is deleted regardless of its current
`etag`.

=back

=head2 Google::Iam::V2beta::Policy::PolicyOperationMetadata

Metadata for long-running `Policy` operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the `google.longrunning.Operation` was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V2beta::Policy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
