package Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType;

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
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZ29sZGVuZ2F0ZV9kZXBsb3ltZW50
X3R5cGUucHJvdG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byLyCQoY
R29sZGVuZ2F0ZURlcGxveW1lbnRUeXBlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJ1Cg9k
ZXBsb3ltZW50X3R5cGUYAiABKA4yRy5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEu
R29sZGVuZ2F0ZURlcGxveW1lbnRUeXBlLkRlcGxveW1lbnRUeXBlQgPgQQNSDmRlcGxveW1l
bnRUeXBlEmwKCGNhdGVnb3J5GAMgASgOMksuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNl
LnYxLkdvbGRlbmdhdGVEZXBsb3ltZW50VHlwZS5EZXBsb3ltZW50Q2F0ZWdvcnlCA+BBA1II
Y2F0ZWdvcnkSLgoQY29ubmVjdGlvbl90eXBlcxgEIAMoCUID4EEDUg9jb25uZWN0aW9uVHlw
ZXMSJgoMZGlzcGxheV9uYW1lGAUgASgJQgPgQQNSC2Rpc3BsYXlOYW1lEiQKC29nZ192ZXJz
aW9uGAYgASgJQgPgQQNSCm9nZ1ZlcnNpb24SNAoTc291cmNlX3RlY2hub2xvZ2llcxgHIAMo
CUID4EEDUhJzb3VyY2VUZWNobm9sb2dpZXMSOgoWc3VwcG9ydGVkX2NhcGFiaWxpdGllcxgI
IAMoCUID4EEDUhVzdXBwb3J0ZWRDYXBhYmlsaXRpZXMSQQoac3VwcG9ydGVkX3RlY2hub2xv
Z2llc191cmwYCSABKAlCA+BBA1IYc3VwcG9ydGVkVGVjaG5vbG9naWVzVXJsEjQKE3Rhcmdl
dF90ZWNobm9sb2dpZXMYCiADKAlCA+BBA1ISdGFyZ2V0VGVjaG5vbG9naWVzEi4KEGRlZmF1
bHRfdXNlcm5hbWUYCyABKAlCA+BBA1IPZGVmYXVsdFVzZXJuYW1lIvIBCg5EZXBsb3ltZW50
VHlwZRIfChtERVBMT1lNRU5UX1RZUEVfVU5TUEVDSUZJRUQQABIHCgNPR0cQARITCg9EQVRB
QkFTRV9PUkFDTEUQAhILCgdCSUdEQVRBEAMSIAocREFUQUJBU0VfTUlDUk9TT0ZUX1NRTFNF
UlZFUhAEEhIKDkRBVEFCQVNFX01ZU1FMEAUSFwoTREFUQUJBU0VfUE9TVEdSRVNRTBAGEhMK
D0RBVEFCQVNFX0RCMlpPUxAHEhEKDURBVEFCQVNFX0RCMkkQCBIICgRHR1NBEAkSEwoPREFU
QV9UUkFOU0ZPUk1TEAoidgoSRGVwbG95bWVudENhdGVnb3J5EiMKH0RFUExPWU1FTlRfQ0FU
RUdPUllfVU5TUEVDSUZJRUQQABIdChlEQVRBX1JFUExJQ0FUSU9OX0NBVEVHT1JZEAESHAoY
REFUQV9UUkFOU0ZPUk1TX0NBVEVHT1JZEAI60QHqQc0BCjZvcmFjbGVkYXRhYmFzZS5nb29n
bGVhcGlzLmNvbS9Hb2xkZW5nYXRlRGVwbG95bWVudFR5cGUSXnByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9nb2xkZW5nYXRlRGVwbG95bWVudFR5cGVzL3tnb2xk
ZW5nYXRlX2RlcGxveW1lbnRfdHlwZX0qGWdvbGRlbmdhdGVEZXBsb3ltZW50VHlwZXMyGGdv
bGRlbmdhdGVEZXBsb3ltZW50VHlwZSKBAgokTGlzdEdvbGRlbmdhdGVEZXBsb3ltZW50VHlw
ZXNSZXF1ZXN0ElYKBnBhcmVudBgBIAEoCUI+4EEC+kE4EjZvcmFjbGVkYXRhYmFzZS5nb29n
bGVhcGlzLmNvbS9Hb2xkZW5nYXRlRGVwbG95bWVudFR5cGVSBnBhcmVudBIgCglwYWdlX3Np
emUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdl
VG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID
4EEBUgdvcmRlckJ5IvABCiVMaXN0R29sZGVuZ2F0ZURlcGxveW1lbnRUeXBlc1Jlc3BvbnNl
EngKG2dvbGRlbmdhdGVfZGVwbG95bWVudF90eXBlcxgBIAMoCzI4Lmdvb2dsZS5jbG91ZC5v
cmFjbGVkYXRhYmFzZS52MS5Hb2xkZW5nYXRlRGVwbG95bWVudFR5cGVSGWdvbGRlbmdhdGVE
ZXBsb3ltZW50VHlwZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
EiUKC3VucmVhY2hhYmxlGAMgAygJQgPgQQZSC3VucmVhY2hhYmxlQvcBCiJjb20uZ29vZ2xl
LmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxQh1Hb2xkZW5nYXRlRGVwbG95bWVudFR5cGVQcm90
b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRh
dGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFz
ZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6
Ok9yYWNsZURhdGFiYXNlOjpWMUqSMgoHEgUOALEBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQA7
CgkKAgglEgMVADsKCAoBCBIDFgBhCgkKAggLEgMWAGEKCAoBCBIDFwAiCgkKAggKEgMXACIK
CAoBCBIDGAA+CgkKAggIEgMYAD4KCAoBCBIDGQA7CgkKAggBEgMZADsKCAoBCBIDGgA7CgkK
AggpEgMaADsKCAoBCBIDGwA6CgkKAggtEgMbADoKQgoCBAASBR4AhQEBGjUgRGV0YWlscyBv
ZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50IFR5cGUgcmVzb3VyY2UuCgoKCgMEAAESAx4I
IAoLCgMEAAcSBB8CJAQKDQoFBAAHnQgSBB8CJAQKTwoEBAAEABIEJwJIAxpBIFRoZSBkZXBs
b3ltZW50IHR5cGUgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBUeXBlIHJlc291cmNl
LgoKDAoFBAAEAAESAycHFQorCgYEAAQAAgASAykEJBocIERlZmF1bHQgdW5zcGVjaWZpZWQg
dmFsdWUuCgoOCgcEAAQAAgABEgMpBB8KDgoHBAAEAAIAAhIDKSIjCjwKBgQABAACARIDLAQM
Gi0gR29sZGVuZ2F0ZSBEZXBsb3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgT0dHLgoKDgoHBAAE
AAIBARIDLAQHCg4KBwQABAACAQISAywKCwpICgYEAAQAAgISAy8EGBo5IEdvbGRlbmdhdGUg
RGVwbG95bWVudCBUeXBlIGNhdGVnb3J5IGlzIERBVEFCQVNFX09SQUNMRS4KCg4KBwQABAAC
AgESAy8EEwoOCgcEAAQAAgICEgMvFhcKQAoGBAAEAAIDEgMyBBAaMSBHb2xkZW5nYXRlIERl
cGxveW1lbnQgVHlwZSBjYXRlZ29yeSBpcyBCSUdEQVRBLgoKDgoHBAAEAAIDARIDMgQLCg4K
BwQABAACAwISAzIODwpVCgYEAAQAAgQSAzUEJRpGIEdvbGRlbmdhdGUgRGVwbG95bWVudCBU
eXBlIGNhdGVnb3J5IGlzIERBVEFCQVNFX01JQ1JPU09GVF9TUUxTRVJWRVIuCgoOCgcEAAQA
AgQBEgM1BCAKDgoHBAAEAAIEAhIDNSMkCkcKBgQABAACBRIDOAQXGjggR29sZGVuZ2F0ZSBE
ZXBsb3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgREFUQUJBU0VfTVlTUUwuCgoOCgcEAAQAAgUB
EgM4BBIKDgoHBAAEAAIFAhIDOBUWCkwKBgQABAACBhIDOwQcGj0gR29sZGVuZ2F0ZSBEZXBs
b3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgREFUQUJBU0VfUE9TVEdSRVNRTC4KCg4KBwQABAAC
BgESAzsEFwoOCgcEAAQAAgYCEgM7GhsKSAoGBAAEAAIHEgM+BBgaOSBHb2xkZW5nYXRlIERl
cGxveW1lbnQgVHlwZSBjYXRlZ29yeSBpcyBEQVRBQkFTRV9EQjJaT1MuCgoOCgcEAAQAAgcB
EgM+BBMKDgoHBAAEAAIHAhIDPhYXCkYKBgQABAACCBIDQQQWGjcgR29sZGVuZ2F0ZSBEZXBs
b3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgREFUQUJBU0VfREIySS4KCg4KBwQABAACCAESA0EE
EQoOCgcEAAQAAggCEgNBFBUKPQoGBAAEAAIJEgNEBA0aLiBHb2xkZW5nYXRlIERlcGxveW1l
bnQgVHlwZSBjYXRlZ29yeSBpcyBHR1NBLgoKDgoHBAAEAAIJARIDRAQICg4KBwQABAACCQIS
A0QLDApICgYEAAQAAgoSA0cEGRo5IEdvbGRlbmdhdGUgRGVwbG95bWVudCBUeXBlIGNhdGVn
b3J5IGlzIERBVEFfVFJBTlNGT1JNUy4KCg4KBwQABAACCgESA0cEEwoOCgcEAAQAAgoCEgNH
FhgKSAoEBAAEARIESwJUAxo6IFRoZSBjYXRlZ29yeSBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBs
b3ltZW50IFR5cGUgcmVzb3VyY2UuCgoMCgUEAAQBARIDSwcZCisKBgQABAECABIDTQQoGhwg
RGVmYXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg4KBwQABAECAAESA00EIwoOCgcEAAQBAgAC
EgNNJicKUgoGBAAEAQIBEgNQBCIaQyBHb2xkZW5nYXRlIERlcGxveW1lbnQgVHlwZSBjYXRl
Z29yeSBpcyBEQVRBX1JFUExJQ0FUSU9OX0NBVEVHT1JZLgoKDgoHBAAEAQIBARIDUAQdCg4K
BwQABAECAQISA1AgIQpRCgYEAAQBAgISA1MEIRpCIEdvbGRlbmdhdGUgRGVwbG95bWVudCBU
eXBlIGNhdGVnb3J5IGlzIERBVEFfVFJBTlNGT1JNU19DQVRFR09SWS4KCg4KBwQABAECAgES
A1MEHAoOCgcEAAQBAgICEgNTHyAKvwEKBAQAAgASA1kCPRqxASBJZGVudGlmaWVyLiBUaGUg
bmFtZSBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50IFR5cGUgcmVzb3VyY2Ugd2l0aCB0
aGUKIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve3JlZ2lvbn0vZ29s
ZGVuZ2F0ZURlcGxveW1lbnRUeXBlcy97Z29sZGVuZ2F0ZV9kZXBsb3ltZW50X3R5cGV9CgoM
CgUEAAIABRIDWQIICgwKBQQAAgABEgNZCQ0KDAoFBAACAAMSA1kQEQoMCgUEAAIACBIDWRI8
Cg8KCAQAAgAInAgAEgNZEzsKXQoEBAACARIEXQJeMhpPIE91dHB1dCBvbmx5LiBUaGUgZGVw
bG95bWVudCB0eXBlIG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVHlwZQogcmVzb3Vy
Y2UuCgoMCgUEAAIBBhIDXQIQCgwKBQQAAgEBEgNdESAKDAoFBAACAQMSA10jJAoMCgUEAAIB
CBIDXgYxCg8KCAQAAgEInAgAEgNeBzAKVAoEBAACAhIDYQJOGkcgT3V0cHV0IG9ubHkuIFRo
ZSBjYXRlZ29yeSBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50IFR5cGUgcmVzb3VyY2Uu
CgoMCgUEAAICBhIDYQIUCgwKBQQAAgIBEgNhFR0KDAoFBAACAgMSA2EgIQoMCgUEAAICCBID
YSJNCg8KCAQAAgIInAgAEgNhI0wKXgoEBAACAxIEZQJmMhpQIE91dHB1dCBvbmx5LiBUaGUg
Y29ubmVjdGlvbiB0eXBlcyBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50IFR5cGUKIHJl
c291cmNlLgoKDAoFBAACAwQSA2UCCgoMCgUEAAIDBRIDZQsRCgwKBQQAAgMBEgNlEiIKDAoF
BAACAwMSA2UlJgoMCgUEAAIDCBIDZgYxCg8KCAQAAgMInAgAEgNmBzAKWAoEBAACBBIDaQJG
GksgT3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIEdvbGRlbmdhdGUgRGVw
bG95bWVudCBUeXBlIHJlc291cmNlLgoKDAoFBAACBAUSA2kCCAoMCgUEAAIEARIDaQkVCgwK
BQQAAgQDEgNpGBkKDAoFBAACBAgSA2kaRQoPCggEAAIECJwIABIDaRtEClcKBAQAAgUSA2wC
RRpKIE91dHB1dCBvbmx5LiBUaGUgT2dnIHZlcnNpb24gb2YgdGhlIEdvbGRlbmdhdGUgRGVw
bG95bWVudCBUeXBlIHJlc291cmNlLgoKDAoFBAACBQUSA2wCCAoMCgUEAAIFARIDbAkUCgwK
BQQAAgUDEgNsFxgKDAoFBAACBQgSA2wZRAoPCggEAAIFCJwIABIDbBpDCmEKBAQAAgYSBHAC
cTIaUyBPdXRwdXQgb25seS4gVGhlIHNvdXJjZSB0ZWNobm9sb2dpZXMgb2YgdGhlIEdvbGRl
bmdhdGUgRGVwbG95bWVudCBUeXBlCiByZXNvdXJjZS4KCgwKBQQAAgYEEgNwAgoKDAoFBAAC
BgUSA3ALEQoMCgUEAAIGARIDcBIlCgwKBQQAAgYDEgNwKCkKDAoFBAACBggSA3EGMQoPCggE
AAIGCJwIABIDcQcwCmQKBAQAAgcSBHUCdjIaViBPdXRwdXQgb25seS4gVGhlIHN1cHBvcnRl
ZCBjYXBhYmlsaXRpZXMgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBUeXBlCiByZXNv
dXJjZS4KCgwKBQQAAgcEEgN1AgoKDAoFBAACBwUSA3ULEQoMCgUEAAIHARIDdRIoCgwKBQQA
AgcDEgN1KywKDAoFBAACBwgSA3YGMQoPCggEAAIHCJwIABIDdgcwCmgKBAQAAggSBHoCezIa
WiBPdXRwdXQgb25seS4gVGhlIHN1cHBvcnRlZCB0ZWNobm9sb2dpZXMgVVJMIG9mIHRoZSBH
b2xkZW5nYXRlIERlcGxveW1lbnQKIFR5cGUgcmVzb3VyY2UuCgoMCgUEAAIIBRIDegIICgwK
BQQAAggBEgN6CSMKDAoFBAACCAMSA3omJwoMCgUEAAIICBIDewYxCg8KCAQAAggInAgAEgN7
BzAKYgoEBAACCRIFfwKAATIaUyBPdXRwdXQgb25seS4gVGhlIHRhcmdldCB0ZWNobm9sb2dp
ZXMgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBUeXBlCiByZXNvdXJjZS4KCgwKBQQA
AgkEEgN/AgoKDAoFBAACCQUSA38LEQoMCgUEAAIJARIDfxIlCgwKBQQAAgkDEgN/KCoKDQoF
BAACCQgSBIABBjEKEAoIBAACCQicCAASBIABBzAKXgoEBAACChIEhAECSxpQIE91dHB1dCBv
bmx5LiBUaGUgZGVmYXVsdCB1c2VybmFtZSBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50
IFR5cGUKIHJlc291cmNlLgoKDQoFBAACCgUSBIQBAggKDQoFBAACCgESBIQBCRkKDQoFBAAC
CgMSBIQBHB4KDQoFBAACCggSBIQBH0oKEAoIBAACCgicCAASBIQBIEkKPgoCBAESBogBAKMB
ARowIE1lc3NhZ2UgZm9yIGxpc3RpbmcgR29sZGVuZ2F0ZURlcGxveW1lbnRUeXBlcy4KCgsK
AwQBARIEiAEILAphCgQEAQIAEgaLAQKQAQQaUSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNv
dXJjZS4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
CgoNCgUEAQIABRIEiwECCAoNCgUEAQIAARIEiwEJDwoNCgUEAQIAAxIEiwESEwoPCgUEAQIA
CBIGiwEUkAEDChAKCAQBAgAInAgAEgSMAQQqChEKBwQBAgAInwgSBo0BBI8BBQqXAQoEBAEC
ARIElAECPxqIASBPcHRpb25hbC4gUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gU2VydmVyIG1heSBy
ZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbgogcmVxdWVzdGVkLiBJZiB1bnNwZWNpZmllZCwgc2Vy
dmVyIHdpbGwgcGljayBhbiBhcHByb3ByaWF0ZSBkZWZhdWx0LgoKDQoFBAECAQUSBJQBAgcK
DQoFBAECAQESBJQBCBEKDQoFBAECAQMSBJQBFBUKDQoFBAECAQgSBJQBFj4KEAoIBAECAQic
CAASBJQBFz0KWQoEBAECAhIElwECQRpLIE9wdGlvbmFsLiBBIHRva2VuIGlkZW50aWZ5aW5n
IGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQBAgIF
EgSXAQIICg0KBQQBAgIBEgSXAQkTCg0KBQQBAgIDEgSXARYXCg0KBQQBAgIIEgSXARhAChAK
CAQBAgIInAgAEgSXARk/CrgDCgQEAQIDEgSfAQI9GqkDIE9wdGlvbmFsLiBBbiBleHByZXNz
aW9uIGZvciBmaWx0ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhlIHJlcXVlc3QuIEVpdGhlcgog
dGhlIGRlcGxveW1lbnRfdHlwZSBhbmQgb2dnX3ZlcnNpb24gZmllbGRzIG11c3QgYmUgc3Bl
Y2lmaWVkIGluIHRoZSBmb3JtYXQ6CiBgZGVwbG95bWVudF90eXBlPSJEQVRBQkFTRV9PUkFD
TEUiYCBvciBgb2dnX3ZlcnNpb249InZlcnNpb24iYC4KIEFsbG93ZWQgdmFsdWVzIGZvciBk
ZXBsb3ltZW50X3R5cGUgYXJlOiBgREFUQUJBU0VfT1JBQ0xFYCwgYEJJR0RBVEFgLAogYERB
VEFCQVNFX01JQ1JPU09GVF9TUUxTRVJWRVJgLCBgREFUQUJBU0VfTVlTUUxgLCBgREFUQUJB
U0VfUE9TVEdSRVNRTGAsCiBgREFUQUJBU0VfREIyWk9TYCwgYERBVEFCQVNFX0RCMklgLCBg
R0dTQWAsIGBEQVRBX1RSQU5TRk9STVNgLgoKDQoFBAECAwUSBJ8BAggKDQoFBAECAwESBJ8B
CQ8KDQoFBAECAwMSBJ8BEhMKDQoFBAECAwgSBJ8BFDwKEAoIBAECAwicCAASBJ8BFTsKOwoE
BAECBBIEogECPxotIE9wdGlvbmFsLiBIaW50IGZvciBob3cgdG8gb3JkZXIgdGhlIHJlc3Vs
dHMKCg0KBQQBAgQFEgSiAQIICg0KBQQBAgQBEgSiAQkRCg0KBQQBAgQDEgSiARQVCg0KBQQB
AgQIEgSiARY+ChAKCAQBAgQInAgAEgSiARc9CkkKAgQCEgamAQCxAQEaOyBNZXNzYWdlIGZv
ciByZXNwb25zZSB0byBsaXN0aW5nIEdvbGRlbmdhdGVEZXBsb3ltZW50VHlwZXMKCgsKAwQC
ARIEpgEILQo0CgQEAgIAEgSoAQJEGiYgVGhlIGxpc3Qgb2YgR29sZGVuZ2F0ZURlcGxveW1l
bnRUeXBlCgoNCgUEAgIABBIEqAECCgoNCgUEAgIABhIEqAELIwoNCgUEAgIAARIEqAEkPwoN
CgUEAgIAAxIEqAFCQwqQAQoEBAICARIErAECHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUg
c2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRo
aXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoN
CgUEAgIBBRIErAECCAoNCgUEAgIBARIErAEJGAoNCgUEAgIBAxIErAEbHApcCgQEAgICEgav
AQKwATUaTCBVbm9yZGVyZWQgbGlzdC4gVGhlIHJlc291cmNlIG5hbWVzIG9mIGxvY2F0aW9u
cyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoFBAICAgQSBK8BAgoKDQoFBAICAgUS
BK8BCxEKDQoFBAICAgESBK8BEh0KDQoFBAICAgMSBK8BICEKDQoFBAICAggSBLABBjQKEAoI
BAICAgicCAASBLABBzNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType ===
    # Fields for GoldengateDeploymentType
    # Field: name Type: 9 ()
    # Field: deployment_type Type: 14 (.google.cloud.oracledatabase.v1.GoldengateDeploymentType.DeploymentType)
    # Field: category Type: 14 (.google.cloud.oracledatabase.v1.GoldengateDeploymentType.DeploymentCategory)
    # Field: connection_types Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: ogg_version Type: 9 ()
    # Field: source_technologies Type: 9 ()
    # Field: supported_capabilities Type: 9 ()
    # Field: supported_technologies_url Type: 9 ()
    # Field: target_technologies Type: 9 ()
    # Field: default_username Type: 9 ()

# Enum: GoldengateDeploymentType::DeploymentType
our $GoldengateDeploymentType_DEPLOYMENT_TYPE_UNSPECIFIED = 0;
our $GoldengateDeploymentType_OGG = 1;
our $GoldengateDeploymentType_DATABASE_ORACLE = 2;
our $GoldengateDeploymentType_BIGDATA = 3;
our $GoldengateDeploymentType_DATABASE_MICROSOFT_SQLSERVER = 4;
our $GoldengateDeploymentType_DATABASE_MYSQL = 5;
our $GoldengateDeploymentType_DATABASE_POSTGRESQL = 6;
our $GoldengateDeploymentType_DATABASE_DB2ZOS = 7;
our $GoldengateDeploymentType_DATABASE_DB2I = 8;
our $GoldengateDeploymentType_GGSA = 9;
our $GoldengateDeploymentType_DATA_TRANSFORMS = 10;

# Enum: GoldengateDeploymentType::DeploymentCategory
our $GoldengateDeploymentType_DEPLOYMENT_CATEGORY_UNSPECIFIED = 0;
our $GoldengateDeploymentType_DATA_REPLICATION_CATEGORY = 1;
our $GoldengateDeploymentType_DATA_TRANSFORMS_CATEGORY = 2;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesRequest ===
    # Fields for ListGoldengateDeploymentTypesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesResponse ===
    # Fields for ListGoldengateDeploymentTypesResponse
    # Field: goldengate_deployment_types Type: 11 (.google.cloud.oracledatabase.v1.GoldengateDeploymentType)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/goldengate_deployment_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType;

    my $msg = Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType->new({
        name => $name,
        deployment_type => $deployment_type,
        category => $category,
        connection_types => $connection_types,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/goldengate_deployment_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType

Details of the Goldengate Deployment Type resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Goldengate Deployment Type resource with the
format:
projects/{project}/locations/{region}/goldengateDeploymentTypes/{goldengate_deployment_type}

=item * C<< $msg->deployment_type() >> / C<< $msg->deployment_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::DeploymentType>)

Output only. The deployment type of the Goldengate Deployment Type
resource.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::DeploymentCategory>)

Output only. The category of the Goldengate Deployment Type resource.

=item * C<< $msg->connection_types() >> / C<< $msg->connection_types($value) >>

Type: C<String>

Output only. The connection types of the Goldengate Deployment Type
resource.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the Goldengate Deployment Type resource.

=item * C<< $msg->ogg_version() >> / C<< $msg->ogg_version($value) >>

Type: C<String>

Output only. The Ogg version of the Goldengate Deployment Type resource.

=item * C<< $msg->source_technologies() >> / C<< $msg->source_technologies($value) >>

Type: C<String>

Output only. The source technologies of the Goldengate Deployment Type
resource.

=item * C<< $msg->supported_capabilities() >> / C<< $msg->supported_capabilities($value) >>

Type: C<String>

Output only. The supported capabilities of the Goldengate Deployment Type
resource.

=item * C<< $msg->supported_technologies_url() >> / C<< $msg->supported_technologies_url($value) >>

Type: C<String>

Output only. The supported technologies URL of the Goldengate Deployment
Type resource.

=item * C<< $msg->target_technologies() >> / C<< $msg->target_technologies($value) >>

Type: C<String>

Output only. The target technologies of the Goldengate Deployment Type
resource.

=item * C<< $msg->default_username() >> / C<< $msg->default_username($value) >>

Type: C<String>

Output only. The default username of the Goldengate Deployment Type
resource.

=back

=head3 Enum: GoldengateDeploymentType::DeploymentType

=over 4

=item * C<DEPLOYMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<OGG> => C<1>

=item * C<DATABASE_ORACLE> => C<2>

=item * C<BIGDATA> => C<3>

=item * C<DATABASE_MICROSOFT_SQLSERVER> => C<4>

=item * C<DATABASE_MYSQL> => C<5>

=item * C<DATABASE_POSTGRESQL> => C<6>

=item * C<DATABASE_DB2ZOS> => C<7>

=item * C<DATABASE_DB2I> => C<8>

=item * C<GGSA> => C<9>

=item * C<DATA_TRANSFORMS> => C<10>

=back

=head3 Enum: GoldengateDeploymentType::DeploymentCategory

=over 4

=item * C<DEPLOYMENT_CATEGORY_UNSPECIFIED> => C<0>

=item * C<DATA_REPLICATION_CATEGORY> => C<1>

=item * C<DATA_TRANSFORMS_CATEGORY> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesRequest

Message for listing GoldengateDeploymentTypes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource.
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Either
the deployment_type and ogg_version fields must be specified in the format:
`deployment_type="DATABASE_ORACLE"` or `ogg_version="version"`.
Allowed values for deployment_type are: `DATABASE_ORACLE`, `BIGDATA`,
`DATABASE_MICROSOFT_SQLSERVER`, `DATABASE_MYSQL`, `DATABASE_POSTGRESQL`,
`DATABASE_DB2ZOS`, `DATABASE_DB2I`, `GGSA`, `DATA_TRANSFORMS`.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::ListGoldengateDeploymentTypesResponse

Message for response to listing GoldengateDeploymentTypes

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->goldengate_deployment_types() >> / C<< $msg->goldengate_deployment_types($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::GoldengateDeploymentType>)

The list of GoldengateDeploymentType

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. The resource names of locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
