package Google::Cloud::Networkservices::V1beta1::Common;

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
CjFnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxYmV0YTEvY29tbW9uLnByb3RvEiRn
b29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1QIKEU9w
ZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEoCUID4EED
UgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEioKDnN0YXR1c19tZXNzYWdlGAUg
ASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgGIAEo
CEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YByABKAlCA+BB
A1IKYXBpVmVyc2lvbiIwChNUcmFmZmljUG9ydFNlbGVjdG9yEhkKBXBvcnRzGAEgAygJQgPg
QQFSBXBvcnRzIrYFCg9FbmRwb2ludE1hdGNoZXISggEKFm1ldGFkYXRhX2xhYmVsX21hdGNo
ZXIYASABKAsySi5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuRW5kcG9p
bnRNYXRjaGVyLk1ldGFkYXRhTGFiZWxNYXRjaGVySABSFG1ldGFkYXRhTGFiZWxNYXRjaGVy
Go0EChRNZXRhZGF0YUxhYmVsTWF0Y2hlchKoAQodbWV0YWRhdGFfbGFiZWxfbWF0Y2hfY3Jp
dGVyaWEYASABKA4yZS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuRW5k
cG9pbnRNYXRjaGVyLk1ldGFkYXRhTGFiZWxNYXRjaGVyLk1ldGFkYXRhTGFiZWxNYXRjaENy
aXRlcmlhUhptZXRhZGF0YUxhYmVsTWF0Y2hDcml0ZXJpYRKCAQoPbWV0YWRhdGFfbGFiZWxz
GAIgAygLMlkuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MWJldGExLkVuZHBvaW50
TWF0Y2hlci5NZXRhZGF0YUxhYmVsTWF0Y2hlci5NZXRhZGF0YUxhYmVsc1IObWV0YWRhdGFM
YWJlbHMaWgoOTWV0YWRhdGFMYWJlbHMSIgoKbGFiZWxfbmFtZRgBIAEoCUID4EECUglsYWJl
bE5hbWUSJAoLbGFiZWxfdmFsdWUYAiABKAlCA+BBAlIKbGFiZWxWYWx1ZSJpChpNZXRhZGF0
YUxhYmVsTWF0Y2hDcml0ZXJpYRItCilNRVRBREFUQV9MQUJFTF9NQVRDSF9DUklURVJJQV9V
TlNQRUNJRklFRBAAEg0KCU1BVENIX0FOWRABEg0KCU1BVENIX0FMTBACQg4KDG1hdGNoZXJf
dHlwZUKFAgooY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjFiZXRhMUILQ29t
bW9uUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VydmljZXMvYXBpdjFi
ZXRhMS9uZXR3b3Jrc2VydmljZXNwYjtuZXR3b3Jrc2VydmljZXNwYqoCJEdvb2dsZS5DbG91
ZC5OZXR3b3JrU2VydmljZXMuVjFCZXRhMcoCJEdvb2dsZVxDbG91ZFxOZXR3b3JrU2Vydmlj
ZXNcVjFiZXRhMeoCJ0dvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZXJ2aWNlczo6VjFiZXRhMUqj
KQoHEgUOAIoBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
LQoJCgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBIDFQBBCgkKAgglEgMVAEEKCAoBCBIDFgBp
CgkKAggLEgMWAGkKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAsCgkKAggIEgMYACwK
CAoBCBIDGQBBCgkKAggBEgMZAEEKCAoBCBIDGgBBCgkKAggpEgMaAEEKCAoBCBIDGwBACgkK
AggtEgMbAEAKRAoCBAASBB4AOQEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUg
bG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQAARIDHggZCkAKBAQAAgASBCACITIaMiBP
dXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQA
AgAGEgMgAhsKDAoFBAACAAESAyAcJwoMCgUEAAIAAxIDICorCgwKBQQAAgAIEgMhBjEKDwoI
BAACAAicCAASAyEHMApFCgQEAAIBEgQkAiUyGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRo
ZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCgwKBQQAAgEGEgMkAhsKDAoFBAACAQES
AyQcJAoMCgUEAAIBAxIDJCcoCgwKBQQAAgEIEgMlBjEKDwoIBAACAQicCAASAyUHMApZCgQE
AAICEgMoAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBm
b3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAgUSAygCCAoMCgUEAAIC
ARIDKAkPCgwKBQQAAgIDEgMoEhMKDAoFBAACAggSAygUPwoPCggEAAICCJwIABIDKBU+CkcK
BAQAAgMSAysCPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5
IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRIDKwIICgwKBQQAAgMBEgMrCQ0KDAoFBAACAwMS
AysQEQoMCgUEAAIDCBIDKxI9Cg8KCAQAAgMInAgAEgMrEzwKSwoEBAACBBIDLgJIGj4gT3V0
cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBh
bnkuCgoMCgUEAAIEBRIDLgIICgwKBQQAAgQBEgMuCRcKDAoFBAACBAMSAy4aGwoMCgUEAAIE
CBIDLhxHCg8KCAQAAgQInAgAEgMuHUYKmgIKBAQAAgUSAzUCThqMAiBPdXRwdXQgb25seS4g
SWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9u
CiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkg
YmVlbiBjYW5jZWxsZWQKIGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEK
IFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiAx
LCBjb3JyZXNwb25kaW5nIHRvCiBgQ29kZS5DQU5DRUxMRURgLgoKDAoFBAACBQUSAzUCBgoM
CgUEAAIFARIDNQcdCgwKBQQAAgUDEgM1ICEKDAoFBAACBQgSAzUiTQoPCggEAAIFCJwIABID
NSNMCkQKBAQAAgYSAzgCRRo3IE91dHB1dCBvbmx5LiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0
YXJ0IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIGBRIDOAIICgwKBQQAAgYBEgM4CRQKDAoFBAAC
BgMSAzgXGAoMCgUEAAIGCBIDOBlECg8KCAQAAgYInAgAEgM4GkMKNQoCBAESBDwAQgEaKSBT
cGVjaWZpY2F0aW9uIG9mIGEgcG9ydC1iYXNlZCBzZWxlY3Rvci4KCgoKAwQBARIDPAgbCvEB
CgQEAQIAEgNBAkUa4wEgT3B0aW9uYWwuIEEgbGlzdCBvZiBwb3J0cy4gQ2FuIGJlIHBvcnQg
bnVtYmVycyBvciBwb3J0IHJhbmdlCiAoZXhhbXBsZSwgWzgwLTkwXSBzcGVjaWZpZXMgYWxs
IHBvcnRzIGZyb20gODAgdG8gOTAsIGluY2x1ZGluZwogODAgYW5kIDkwKSBvciBuYW1lZCBw
b3J0cyBvciAqIHRvIHNwZWNpZnkgYWxsIHBvcnRzLiBJZiB0aGUKIGxpc3QgaXMgZW1wdHks
IGFsbCBwb3J0cyBhcmUgc2VsZWN0ZWQuCgoMCgUEAQIABBIDQQIKCgwKBQQBAgAFEgNBCxEK
DAoFBAECAAESA0ESFwoMCgUEAQIAAxIDQRobCgwKBQQBAgAIEgNBHEQKDwoIBAECAAicCAAS
A0EdQwppCgIEAhIFRgCKAQEaXCBBIGRlZmluaXRpb24gb2YgYSBtYXRjaGVyIHRoYXQgc2Vs
ZWN0cyBlbmRwb2ludHMgdG8gd2hpY2ggdGhlIHBvbGljaWVzCiBzaG91bGQgYmUgYXBwbGll
ZC4KCgoKAwQCARIDRggXClUKBAQCAwASBUgCgwEDGkYgVGhlIG1hdGNoZXIgdGhhdCBpcyBi
YXNlZCBvbiBub2RlIG1ldGFkYXRhIHByZXNlbnRlZCBieSB4RFMgY2xpZW50cy4KCgwKBQQC
AwABEgNICh4KPwoGBAIDAAMAEgRKBFEFGi8gRGVmaW5lcyBhIG5hbWUtcGFpciB2YWx1ZSBm
b3IgYSBzaW5nbGUgbGFiZWwuCgoOCgcEAgMAAwABEgNKDBoKTgoIBAIDAAMAAgASA0wGRRo9
IFJlcXVpcmVkLiBMYWJlbCBuYW1lIHByZXNlbnRlZCBhcyBrZXkgaW4geERTIE5vZGUgTWV0
YWRhdGEuCgoQCgkEAgMAAwACAAUSA0wGDAoQCgkEAgMAAwACAAESA0wNFwoQCgkEAgMAAwAC
AAMSA0waGwoQCgkEAgMAAwACAAgSA0wcRAoTCgwEAgMAAwACAAicCAASA0wdQwpyCggEAgMA
AwACARIDUAZGGmEgUmVxdWlyZWQuIExhYmVsIHZhbHVlIHByZXNlbnRlZCBhcyB2YWx1ZSBj
b3JyZXNwb25kaW5nIHRvIHRoZSBhYm92ZQoga2V5LCBpbiB4RFMgTm9kZSBNZXRhZGF0YS4K
ChAKCQQCAwADAAIBBRIDUAYMChAKCQQCAwADAAIBARIDUA0YChAKCQQCAwADAAIBAxIDUBsc
ChAKCQQCAwADAAIBCBIDUB1FChMKDAQCAwADAAIBCJwIABIDUB5EClUKBgQCAwAEABIEVARf
BRpFIFBvc3NpYmxlIGNyaXRlcmlhIHZhbHVlcyB0aGF0IGRlZmluZSBsb2dpYyBvZiBob3cg
bWF0Y2hpbmcgaXMgbWFkZS4KCg4KBwQCAwAEAAESA1QJIwo1CggEAgMABAACABIDVgY0GiQg
RGVmYXVsdCB2YWx1ZS4gU2hvdWxkIG5vdCBiZSB1c2VkLgoKEAoJBAIDAAQAAgABEgNWBi8K
EAoJBAIDAAQAAgACEgNWMjMKegoIBAIDAAQAAgESA1oGFBppIEF0IGxlYXN0IG9uZSBvZiB0
aGUgTGFiZWxzIHNwZWNpZmllZCBpbiB0aGUgbWF0Y2hlciBzaG91bGQgbWF0Y2ggdGhlCiBt
ZXRhZGF0YSBwcmVzZW50ZWQgYnkgeERTIGNsaWVudC4KChAKCQQCAwAEAAIBARIDWgYPChAK
CQQCAwAEAAIBAhIDWhITCm0KCAQCAwAEAAICEgNeBhQaXCBUaGUgbWV0YWRhdGEgcHJlc2Vu
dGVkIGJ5IHRoZSB4RFMgY2xpZW50IHNob3VsZCBjb250YWluIGFsbCBvZiB0aGUKIGxhYmVs
cyBzcGVjaWZpZWQgaGVyZS4KChAKCQQCAwAEAAICARIDXgYPChAKCQQCAwAEAAICAhIDXhIT
CtcHCgYEAgMAAgASA3sEQRrHByBTcGVjaWZpZXMgaG93IG1hdGNoaW5nIHNob3VsZCBiZSBk
b25lLgoKIFN1cHBvcnRlZCB2YWx1ZXMgYXJlOgogTUFUQ0hfQU5ZOiBBdCBsZWFzdCBvbmUg
b2YgdGhlIExhYmVscyBzcGVjaWZpZWQgaW4gdGhlCiAgIG1hdGNoZXIgc2hvdWxkIG1hdGNo
IHRoZSBtZXRhZGF0YSBwcmVzZW50ZWQgYnkgeERTIGNsaWVudC4KIE1BVENIX0FMTDogVGhl
IG1ldGFkYXRhIHByZXNlbnRlZCBieSB0aGUgeERTIGNsaWVudCBzaG91bGQKICAgY29udGFp
biBhbGwgb2YgdGhlIGxhYmVscyBzcGVjaWZpZWQgaGVyZS4KCiBUaGUgc2VsZWN0aW9uIGlz
IGRldGVybWluZWQgYmFzZWQgb24gdGhlIGJlc3QgbWF0Y2guIEZvcgogZXhhbXBsZSwgc3Vw
cG9zZSB0aGVyZSBhcmUgdGhyZWUgRW5kcG9pbnRQb2xpY3kKIHJlc291cmNlcyBQMSwgUDIg
YW5kIFAzIGFuZCBpZiBQMSBoYXMgYSB0aGUgbWF0Y2hlciBhcwogTUFUQ0hfQU5ZIDxBOjEs
IEI6MT4sIFAyIGhhcyBNQVRDSF9BTEwgPEE6MSxCOjE+LCBhbmQgUDMgaGFzCiBNQVRDSF9B
TEwgPEE6MSxCOjEsQzoxPi4KCiBJZiBhIGNsaWVudCB3aXRoIGxhYmVsIDxBOjE+IGNvbm5l
Y3RzLCB0aGUgY29uZmlnIGZyb20gUDEKIHdpbGwgYmUgc2VsZWN0ZWQuCgogSWYgYSBjbGll
bnQgd2l0aCBsYWJlbCA8QToxLEI6MT4gY29ubmVjdHMsIHRoZSBjb25maWcgZnJvbSBQMgog
d2lsbCBiZSBzZWxlY3RlZC4KCiBJZiBhIGNsaWVudCB3aXRoIGxhYmVsIDxBOjEsQjoxLEM6
MT4gY29ubmVjdHMsIHRoZSBjb25maWcKIGZyb20gUDMgd2lsbCBiZSBzZWxlY3RlZC4KCiBJ
ZiB0aGVyZSBpcyBtb3JlIHRoYW4gb25lIGJlc3QgbWF0Y2gsIChmb3IgZXhhbXBsZSwgaWYg
YQogY29uZmlnIFA0IHdpdGggc2VsZWN0b3IgPEE6MSxEOjE+IGV4aXN0cyBhbmQgaWYgYSBj
bGllbnQgd2l0aAogbGFiZWwgPEE6MSxCOjEsRDoxPiBjb25uZWN0cyksIGFuIGVycm9yIHdp
bGwgYmUgdGhyb3duLgoKDgoHBAIDAAIABhIDewQeCg4KBwQCAwACAAESA3sfPAoOCgcEAgMA
AgADEgN7P0AKnQIKBgQCAwACARIEggEEMBqMAiBUaGUgbGlzdCBvZiBsYWJlbCB2YWx1ZSBw
YWlycyB0aGF0IG11c3QgbWF0Y2ggbGFiZWxzIGluIHRoZQogcHJvdmlkZWQgbWV0YWRhdGEg
YmFzZWQgb24gZmlsdGVyTWF0Y2hDcml0ZXJpYSBUaGlzIGxpc3QgY2FuCiBoYXZlIGF0IG1v
c3QgNjQgZW50cmllcy4gVGhlIGxpc3QgY2FuIGJlIGVtcHR5IGlmIHRoZSBtYXRjaAogY3Jp
dGVyaWEgaXMgTUFUQ0hfQU5ZLCB0byBzcGVjaWZ5IGEgd2lsZGNhcmQgbWF0Y2ggKGkuZSB0
aGlzCiBtYXRjaGVzIGFueSBjbGllbnQpLgoKDwoHBAIDAAIBBBIEggEEDAoPCgcEAgMAAgEG
EgSCAQ0bCg8KBwQCAwACAQESBIIBHCsKDwoHBAIDAAIBAxIEggEuLwpPCgQEAggAEgaGAQKJ
AQMaPyBTcGVjaWZpZXMgdHlwZSBvZiB0aGUgbWF0Y2hlciB1c2VkIGZvciB0aGlzIGVuZHBv
aW50IG1hdGNoZXIuCgoNCgUEAggAARIEhgEIFApPCgQEAgIAEgSIAQQ0GkEgVGhlIG1hdGNo
ZXIgaXMgYmFzZWQgb24gbm9kZSBtZXRhZGF0YSBwcmVzZW50ZWQgYnkgeERTIGNsaWVudHMu
CgoNCgUEAgIABhIEiAEEGAoNCgUEAgIAARIEiAEZLwoNCgUEAgIAAxIEiAEyM2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1beta1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1beta1::Common::TrafficPortSelector ===
    # Fields for TrafficPortSelector
    # Field: ports Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1beta1::Common::EndpointMatcher ===
    # Fields for EndpointMatcher
    # Field: metadata_label_matcher Type: 11 (.google.cloud.networkservices.v1beta1.EndpointMatcher.MetadataLabelMatcher)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1beta1::Common - Compiled Protocol Buffers messages for google/cloud/networkservices/v1beta1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1beta1::Common;

    my $msg = Google::Cloud::Networkservices::V1beta1::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkservices::V1beta1::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1beta1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkservices::V1beta1::Common::OperationMetadata

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

=head2 Google::Cloud::Networkservices::V1beta1::Common::TrafficPortSelector

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

=head2 Google::Cloud::Networkservices::V1beta1::Common::EndpointMatcher

A definition of a matcher that selects endpoints to which the policies
should be applied.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metadata_label_matcher() >> / C<< $msg->metadata_label_matcher($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::Common::EndpointMatcher::MetadataLabelMatcher>)

The matcher is based on node metadata presented by xDS clients.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1beta1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
