package Google::Cloud::Networkservices::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL2NvbW1vbi5wcm90bxIfZ29vZ2xl
LmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLVAgoRT3BlcmF0aW9uTWV0
YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdldBIX
CgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSABKAlCA+BBA1IN
c3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgIQgPgQQNSFXJl
cXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EEDUgphcGlWZXJz
aW9uIjAKE1RyYWZmaWNQb3J0U2VsZWN0b3ISGQoFcG9ydHMYASADKAlCA+BBAVIFcG9ydHMi
pQUKD0VuZHBvaW50TWF0Y2hlchJ9ChZtZXRhZGF0YV9sYWJlbF9tYXRjaGVyGAEgASgLMkUu
Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5FbmRwb2ludE1hdGNoZXIuTWV0YWRh
dGFMYWJlbE1hdGNoZXJIAFIUbWV0YWRhdGFMYWJlbE1hdGNoZXIaggQKFE1ldGFkYXRhTGFi
ZWxNYXRjaGVyEqMBCh1tZXRhZGF0YV9sYWJlbF9tYXRjaF9jcml0ZXJpYRgBIAEoDjJgLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuRW5kcG9pbnRNYXRjaGVyLk1ldGFkYXRh
TGFiZWxNYXRjaGVyLk1ldGFkYXRhTGFiZWxNYXRjaENyaXRlcmlhUhptZXRhZGF0YUxhYmVs
TWF0Y2hDcml0ZXJpYRJ9Cg9tZXRhZGF0YV9sYWJlbHMYAiADKAsyVC5nb29nbGUuY2xvdWQu
bmV0d29ya3NlcnZpY2VzLnYxLkVuZHBvaW50TWF0Y2hlci5NZXRhZGF0YUxhYmVsTWF0Y2hl
ci5NZXRhZGF0YUxhYmVsc1IObWV0YWRhdGFMYWJlbHMaWgoOTWV0YWRhdGFMYWJlbHMSIgoK
bGFiZWxfbmFtZRgBIAEoCUID4EECUglsYWJlbE5hbWUSJAoLbGFiZWxfdmFsdWUYAiABKAlC
A+BBAlIKbGFiZWxWYWx1ZSJpChpNZXRhZGF0YUxhYmVsTWF0Y2hDcml0ZXJpYRItCilNRVRB
REFUQV9MQUJFTF9NQVRDSF9DUklURVJJQV9VTlNQRUNJRklFRBAAEg0KCU1BVENIX0FOWRAB
Eg0KCU1BVENIX0FMTBACQg4KDG1hdGNoZXJfdHlwZSpKCgxFbnZveUhlYWRlcnMSHQoZRU5W
T1lfSEVBREVSU19VTlNQRUNJRklFRBAAEggKBE5PTkUQARIRCg1ERUJVR19IRUFERVJTEAJC
7AEKI2NvbS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxQgtDb21tb25Qcm90b1AB
Wk1jbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZXJ2aWNlcy9hcGl2MS9uZXR3b3Jrc2Vy
dmljZXNwYjtuZXR3b3Jrc2VydmljZXNwYqoCH0dvb2dsZS5DbG91ZC5OZXR3b3JrU2Vydmlj
ZXMuVjHKAh9Hb29nbGVcQ2xvdWRcTmV0d29ya1NlcnZpY2VzXFYx6gIiR29vZ2xlOjpDbG91
ZDo6TmV0d29ya1NlcnZpY2VzOjpWMUqSLQoHEgUOAJsBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBID
FQA8CgkKAgglEgMVADwKCAoBCBIDFgBkCgkKAggLEgMWAGQKCAoBCBIDFwAiCgkKAggKEgMX
ACIKCAoBCBIDGAAsCgkKAggIEgMYACwKCAoBCBIDGQA8CgkKAggBEgMZADwKCAoBCBIDGgA8
CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKPAoCBQASBB4ALAEaMCBFbnZveUhl
YWRlciBjb25maWd1cmF0aW9uIGZvciBNZXNoIGFuZCBHYXRld2F5CgoKCgMFAAESAx4FEQog
CgQFAAIAEgMgAiAaEyBEZWZhdWx0cyB0byBOT05FLgoKDAoFBQACAAESAyACGwoMCgUFAAIA
AhIDIB4fCiwKBAUAAgESAyMCCxofIFN1cHByZXNzIGVudm95IGRlYnVnIGhlYWRlcnMuCgoM
CgUFAAIBARIDIwIGCgwKBQUAAgECEgMjCQoK6QEKBAUAAgISAysCFBrbASBFbnZveSB3aWxs
IGluc2VydCBkZWZhdWx0IGludGVybmFsIGRlYnVnIGhlYWRlcnMgaW50byB1cHN0cmVhbSBy
ZXF1ZXN0czoKIHgtZW52b3ktYXR0ZW1wdC1jb3VudCwKIHgtZW52b3ktaXMtdGltZW91dC1y
ZXRyeSwKIHgtZW52b3ktZXhwZWN0ZWQtcnEtdGltZW91dC1tcywKIHgtZW52b3ktb3JpZ2lu
YWwtcGF0aCwKIHgtZW52b3ktdXBzdHJlYW0tc3RyZWFtLWR1cmF0aW9uLW1zCgoMCgUFAAIC
ARIDKwIPCgwKBQUAAgICEgMrEhMKRAoCBAASBC8ASgEaOCBSZXByZXNlbnRzIHRoZSBtZXRh
ZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQAARIDLwgZCkAKBAQA
AgASBDECMjIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3YXMgY3Jl
YXRlZC4KCgwKBQQAAgAGEgMxAhsKDAoFBAACAAESAzEcJwoMCgUEAAIAAxIDMSorCgwKBQQA
AgAIEgMyBjEKDwoIBAACAAicCAASAzIHMApFCgQEAAIBEgQ1AjYyGjcgT3V0cHV0IG9ubHku
IFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCgwKBQQAAgEGEgM1
AhsKDAoFBAACAQESAzUcJAoMCgUEAAIBAxIDNScoCgwKBQQAAgEIEgM2BjEKDwoIBAACAQic
CAASAzYHMApZCgQEAAICEgM5AkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVz
b3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAgUS
AzkCCAoMCgUEAAICARIDOQkPCgwKBQQAAgIDEgM5EhMKDAoFBAACAggSAzkUPwoPCggEAAIC
CJwIABIDORU+CkcKBAQAAgMSAzwCPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJi
IGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRIDPAIICgwKBQQAAgMBEgM8
CQ0KDAoFBAACAwMSAzwQEQoMCgUEAAIDCBIDPBI9Cg8KCAQAAgMInAgAEgM8EzwKSwoEBAAC
BBIDPwJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3Bl
cmF0aW9uLCBpZiBhbnkuCgoMCgUEAAIEBRIDPwIICgwKBQQAAgQBEgM/CRcKDAoFBAACBAMS
Az8aGwoMCgUEAAIECBIDPxxHCg8KCAQAAgQInAgAEgM/HUYKmgIKBAQAAgUSA0YCThqMAiBP
dXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQg
Y2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBz
dWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQKIGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2
YWx1ZSB3aXRoIGEKIFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1
cy5jb2RlXSBvZiAxLCBjb3JyZXNwb25kaW5nIHRvCiBgQ29kZS5DQU5DRUxMRURgLgoKDAoF
BAACBQUSA0YCBgoMCgUEAAIFARIDRgcdCgwKBQQAAgUDEgNGICEKDAoFBAACBQgSA0YiTQoP
CggEAAIFCJwIABIDRiNMCkQKBAQAAgYSA0kCRRo3IE91dHB1dCBvbmx5LiBBUEkgdmVyc2lv
biB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIGBRIDSQIICgwKBQQAAgYB
EgNJCRQKDAoFBAACBgMSA0kXGAoMCgUEAAIGCBIDSRlECg8KCAQAAgYInAgAEgNJGkMKNQoC
BAESBE0AUwEaKSBTcGVjaWZpY2F0aW9uIG9mIGEgcG9ydC1iYXNlZCBzZWxlY3Rvci4KCgoK
AwQBARIDTQgbCvEBCgQEAQIAEgNSAkUa4wEgT3B0aW9uYWwuIEEgbGlzdCBvZiBwb3J0cy4g
Q2FuIGJlIHBvcnQgbnVtYmVycyBvciBwb3J0IHJhbmdlCiAoZXhhbXBsZSwgWzgwLTkwXSBz
cGVjaWZpZXMgYWxsIHBvcnRzIGZyb20gODAgdG8gOTAsIGluY2x1ZGluZwogODAgYW5kIDkw
KSBvciBuYW1lZCBwb3J0cyBvciAqIHRvIHNwZWNpZnkgYWxsIHBvcnRzLiBJZiB0aGUKIGxp
c3QgaXMgZW1wdHksIGFsbCBwb3J0cyBhcmUgc2VsZWN0ZWQuCgoMCgUEAQIABBIDUgIKCgwK
BQQBAgAFEgNSCxEKDAoFBAECAAESA1ISFwoMCgUEAQIAAxIDUhobCgwKBQQBAgAIEgNSHEQK
DwoIBAECAAicCAASA1IdQwppCgIEAhIFVwCbAQEaXCBBIGRlZmluaXRpb24gb2YgYSBtYXRj
aGVyIHRoYXQgc2VsZWN0cyBlbmRwb2ludHMgdG8gd2hpY2ggdGhlIHBvbGljaWVzCiBzaG91
bGQgYmUgYXBwbGllZC4KCgoKAwQCARIDVwgXClUKBAQCAwASBVkClAEDGkYgVGhlIG1hdGNo
ZXIgdGhhdCBpcyBiYXNlZCBvbiBub2RlIG1ldGFkYXRhIHByZXNlbnRlZCBieSB4RFMgY2xp
ZW50cy4KCgwKBQQCAwABEgNZCh4KPwoGBAIDAAMAEgRbBGIFGi8gRGVmaW5lcyBhIG5hbWUt
cGFpciB2YWx1ZSBmb3IgYSBzaW5nbGUgbGFiZWwuCgoOCgcEAgMAAwABEgNbDBoKTgoIBAID
AAMAAgASA10GRRo9IFJlcXVpcmVkLiBMYWJlbCBuYW1lIHByZXNlbnRlZCBhcyBrZXkgaW4g
eERTIE5vZGUgTWV0YWRhdGEuCgoQCgkEAgMAAwACAAUSA10GDAoQCgkEAgMAAwACAAESA10N
FwoQCgkEAgMAAwACAAMSA10aGwoQCgkEAgMAAwACAAgSA10cRAoTCgwEAgMAAwACAAicCAAS
A10dQwpyCggEAgMAAwACARIDYQZGGmEgUmVxdWlyZWQuIExhYmVsIHZhbHVlIHByZXNlbnRl
ZCBhcyB2YWx1ZSBjb3JyZXNwb25kaW5nIHRvIHRoZSBhYm92ZQoga2V5LCBpbiB4RFMgTm9k
ZSBNZXRhZGF0YS4KChAKCQQCAwADAAIBBRIDYQYMChAKCQQCAwADAAIBARIDYQ0YChAKCQQC
AwADAAIBAxIDYRscChAKCQQCAwADAAIBCBIDYR1FChMKDAQCAwADAAIBCJwIABIDYR5EClUK
BgQCAwAEABIEZQRwBRpFIFBvc3NpYmxlIGNyaXRlcmlhIHZhbHVlcyB0aGF0IGRlZmluZSBs
b2dpYyBvZiBob3cgbWF0Y2hpbmcgaXMgbWFkZS4KCg4KBwQCAwAEAAESA2UJIwo1CggEAgMA
BAACABIDZwY0GiQgRGVmYXVsdCB2YWx1ZS4gU2hvdWxkIG5vdCBiZSB1c2VkLgoKEAoJBAID
AAQAAgABEgNnBi8KEAoJBAIDAAQAAgACEgNnMjMKegoIBAIDAAQAAgESA2sGFBppIEF0IGxl
YXN0IG9uZSBvZiB0aGUgTGFiZWxzIHNwZWNpZmllZCBpbiB0aGUgbWF0Y2hlciBzaG91bGQg
bWF0Y2ggdGhlCiBtZXRhZGF0YSBwcmVzZW50ZWQgYnkgeERTIGNsaWVudC4KChAKCQQCAwAE
AAIBARIDawYPChAKCQQCAwAEAAIBAhIDaxITCm0KCAQCAwAEAAICEgNvBhQaXCBUaGUgbWV0
YWRhdGEgcHJlc2VudGVkIGJ5IHRoZSB4RFMgY2xpZW50IHNob3VsZCBjb250YWluIGFsbCBv
ZiB0aGUKIGxhYmVscyBzcGVjaWZpZWQgaGVyZS4KChAKCQQCAwAEAAICARIDbwYPChAKCQQC
AwAEAAICAhIDbxITCukHCgYEAgMAAgASBIwBBEEa2AcgU3BlY2lmaWVzIGhvdyBtYXRjaGlu
ZyBzaG91bGQgYmUgZG9uZS4KCiBTdXBwb3J0ZWQgdmFsdWVzIGFyZToKIE1BVENIX0FOWTog
QXQgbGVhc3Qgb25lIG9mIHRoZSBMYWJlbHMgc3BlY2lmaWVkIGluIHRoZQogICBtYXRjaGVy
IHNob3VsZCBtYXRjaCB0aGUgbWV0YWRhdGEgcHJlc2VudGVkIGJ5IHhEUyBjbGllbnQuCiBN
QVRDSF9BTEw6IFRoZSBtZXRhZGF0YSBwcmVzZW50ZWQgYnkgdGhlIHhEUyBjbGllbnQgc2hv
dWxkCiAgIGNvbnRhaW4gYWxsIG9mIHRoZSBsYWJlbHMgc3BlY2lmaWVkIGhlcmUuCgogVGhl
IHNlbGVjdGlvbiBpcyBkZXRlcm1pbmVkIGJhc2VkIG9uIHRoZSBiZXN0IG1hdGNoLiBGb3IK
IGV4YW1wbGUsIHN1cHBvc2UgdGhlcmUgYXJlIHRocmVlIEVuZHBvaW50UG9saWN5CiByZXNv
dXJjZXMgUDEsIFAyIGFuZCBQMyBhbmQgaWYgUDEgaGFzIGEgdGhlIG1hdGNoZXIgYXMKIE1B
VENIX0FOWSA8QToxLCBCOjE+LCBQMiBoYXMgTUFUQ0hfQUxMIDxBOjEsQjoxPiwgYW5kIFAz
IGhhcwogTUFUQ0hfQUxMIDxBOjEsQjoxLEM6MT4uCgogSWYgYSBjbGllbnQgd2l0aCBsYWJl
bCA8QToxPiBjb25uZWN0cywgdGhlIGNvbmZpZyBmcm9tIFAxCiB3aWxsIGJlIHNlbGVjdGVk
LgoKIElmIGEgY2xpZW50IHdpdGggbGFiZWwgPEE6MSxCOjE+IGNvbm5lY3RzLCB0aGUgY29u
ZmlnIGZyb20gUDIKIHdpbGwgYmUgc2VsZWN0ZWQuCgogSWYgYSBjbGllbnQgd2l0aCBsYWJl
bCA8QToxLEI6MSxDOjE+IGNvbm5lY3RzLCB0aGUgY29uZmlnCiBmcm9tIFAzIHdpbGwgYmUg
c2VsZWN0ZWQuCgogSWYgdGhlcmUgaXMgbW9yZSB0aGFuIG9uZSBiZXN0IG1hdGNoLCAoZm9y
IGV4YW1wbGUsIGlmIGEKIGNvbmZpZyBQNCB3aXRoIHNlbGVjdG9yIDxBOjEsRDoxPiBleGlz
dHMgYW5kIGlmIGEgY2xpZW50IHdpdGgKIGxhYmVsIDxBOjEsQjoxLEQ6MT4gY29ubmVjdHMp
LCBwaWNrIHVwIHRoZSBvbmUgd2l0aCBvbGRlciBjcmVhdGlvbiB0aW1lLgoKDwoHBAIDAAIA
BhIEjAEEHgoPCgcEAgMAAgABEgSMAR88Cg8KBwQCAwACAAMSBIwBP0AKnQIKBgQCAwACARIE
kwEEMBqMAiBUaGUgbGlzdCBvZiBsYWJlbCB2YWx1ZSBwYWlycyB0aGF0IG11c3QgbWF0Y2gg
bGFiZWxzIGluIHRoZQogcHJvdmlkZWQgbWV0YWRhdGEgYmFzZWQgb24gZmlsdGVyTWF0Y2hD
cml0ZXJpYSBUaGlzIGxpc3QgY2FuCiBoYXZlIGF0IG1vc3QgNjQgZW50cmllcy4gVGhlIGxp
c3QgY2FuIGJlIGVtcHR5IGlmIHRoZSBtYXRjaAogY3JpdGVyaWEgaXMgTUFUQ0hfQU5ZLCB0
byBzcGVjaWZ5IGEgd2lsZGNhcmQgbWF0Y2ggKGkuZSB0aGlzCiBtYXRjaGVzIGFueSBjbGll
bnQpLgoKDwoHBAIDAAIBBBIEkwEEDAoPCgcEAgMAAgEGEgSTAQ0bCg8KBwQCAwACAQESBJMB
HCsKDwoHBAIDAAIBAxIEkwEuLwpPCgQEAggAEgaXAQKaAQMaPyBTcGVjaWZpZXMgdHlwZSBv
ZiB0aGUgbWF0Y2hlciB1c2VkIGZvciB0aGlzIGVuZHBvaW50IG1hdGNoZXIuCgoNCgUEAggA
ARIElwEIFApPCgQEAgIAEgSZAQQ0GkEgVGhlIG1hdGNoZXIgaXMgYmFzZWQgb24gbm9kZSBt
ZXRhZGF0YSBwcmVzZW50ZWQgYnkgeERTIGNsaWVudHMuCgoNCgUEAgIABhIEmQEEGAoNCgUE
AgIAARIEmQEZLwoNCgUEAgIAAxIEmQEyM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::Common::TrafficPortSelector ===
    # Fields for TrafficPortSelector
    # Field: ports Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::Common::EndpointMatcher ===
    # Fields for EndpointMatcher
    # Field: metadata_label_matcher Type: 11 (.google.cloud.networkservices.v1.EndpointMatcher.MetadataLabelMatcher)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1::Common - Compiled Protocol Buffers messages for google/cloud/networkservices/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Common;

    my $msg = Google::Cloud::Networkservices::V1::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkservices::V1::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkservices::V1::Common::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Networkservices::V1::Common::TrafficPortSelector

Specification of a port-based selector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ports() >> / C<< $msg->ports($value) >>

Type: C<String>

Optional. A list of ports. Can be port numbers or port range
(example, [80-90] specifies all ports from 80 to 90, including
80 and 90) or named ports or * to specify all ports. If the
list is empty, all ports are selected.

=back

=head2 Google::Cloud::Networkservices::V1::Common::EndpointMatcher

A definition of a matcher that selects endpoints to which the policies
should be applied.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata_label_matcher() >> / C<< $msg->metadata_label_matcher($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher>)

The matcher is based on node metadata presented by xDS clients.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
