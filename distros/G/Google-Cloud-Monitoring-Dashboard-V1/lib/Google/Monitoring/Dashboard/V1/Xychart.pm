package Google::Monitoring::Dashboard::V1::Xychart;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Monitoring::Dashboard::V1::Metrics };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEveHljaGFydC5wcm90bxIeZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGixnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvbWV0cmljcy5wcm90bxoeZ29v
Z2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIvMJCgdYeUNoYXJ0ElEKCWRhdGFfc2V0cxgB
IAMoCzIvLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5YeUNoYXJ0LkRhdGFTZXRC
A+BBAlIIZGF0YVNldHMSSAoSdGltZXNoaWZ0X2R1cmF0aW9uGAQgASgLMhkuZ29vZ2xlLnBy
b3RvYnVmLkR1cmF0aW9uUhF0aW1lc2hpZnREdXJhdGlvbhJJCgp0aHJlc2hvbGRzGAUgAygL
MikuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlRocmVzaG9sZFIKdGhyZXNob2xk
cxJDCgZ4X2F4aXMYBiABKAsyLC5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuWHlD
aGFydC5BeGlzUgV4QXhpcxJDCgZ5X2F4aXMYByABKAsyLC5nb29nbGUubW9uaXRvcmluZy5k
YXNoYm9hcmQudjEuWHlDaGFydC5BeGlzUgV5QXhpcxJFCgd5Ml9heGlzGAkgASgLMiwuZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlh5Q2hhcnQuQXhpc1IGeTJBeGlzElEKDWNo
YXJ0X29wdGlvbnMYCCABKAsyLC5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuQ2hh
cnRPcHRpb25zUgxjaGFydE9wdGlvbnMauwQKB0RhdGFTZXQSYAoRdGltZV9zZXJpZXNfcXVl
cnkYASABKAsyLy5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuVGltZVNlcmllc1F1
ZXJ5QgPgQQJSD3RpbWVTZXJpZXNRdWVyeRJVCglwbG90X3R5cGUYAiABKA4yOC5nb29nbGUu
bW9uaXRvcmluZy5kYXNoYm9hcmQudjEuWHlDaGFydC5EYXRhU2V0LlBsb3RUeXBlUghwbG90
VHlwZRInCg9sZWdlbmRfdGVtcGxhdGUYAyABKAlSDmxlZ2VuZFRlbXBsYXRlElAKFG1pbl9h
bGlnbm1lbnRfcGVyaW9kGAQgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFS
Em1pbkFsaWdubWVudFBlcmlvZBJgCgt0YXJnZXRfYXhpcxgFIAEoDjI6Lmdvb2dsZS5tb25p
dG9yaW5nLmRhc2hib2FyZC52MS5YeUNoYXJ0LkRhdGFTZXQuVGFyZ2V0QXhpc0ID4EEBUgp0
YXJnZXRBeGlzIl8KCFBsb3RUeXBlEhkKFVBMT1RfVFlQRV9VTlNQRUNJRklFRBAAEggKBExJ
TkUQARIQCgxTVEFDS0VEX0FSRUEQAhIPCgtTVEFDS0VEX0JBUhADEgsKB0hFQVRNQVAQBCI5
CgpUYXJnZXRBeGlzEhsKF1RBUkdFVF9BWElTX1VOU1BFQ0lGSUVEEAASBgoCWTEQARIGCgJZ
MhACGp0BCgRBeGlzEhQKBWxhYmVsGAEgASgJUgVsYWJlbBJICgVzY2FsZRgCIAEoDjIyLmdv
b2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5YeUNoYXJ0LkF4aXMuU2NhbGVSBXNjYWxl
IjUKBVNjYWxlEhUKEVNDQUxFX1VOU1BFQ0lGSUVEEAASCgoGTElORUFSEAESCQoFTE9HMTAQ
AiKUAQoMQ2hhcnRPcHRpb25zEkUKBG1vZGUYASABKA4yMS5nb29nbGUubW9uaXRvcmluZy5k
YXNoYm9hcmQudjEuQ2hhcnRPcHRpb25zLk1vZGVSBG1vZGUiPQoETW9kZRIUChBNT0RFX1VO
U1BFQ0lGSUVEEAASCQoFQ09MT1IQARIJCgVYX1JBWRACEgkKBVNUQVRTEANC9QEKImNvbS5n
b29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjFCDFh5Q2hhcnRQcm90b1ABWkZjbG91ZC5n
b29nbGUuY29tL2dvL21vbml0b3JpbmcvZGFzaGJvYXJkL2FwaXYxL2Rhc2hib2FyZHBiO2Rh
c2hib2FyZHBiqgIkR29vZ2xlLkNsb3VkLk1vbml0b3JpbmcuRGFzaGJvYXJkLlYxygIkR29v
Z2xlXENsb3VkXE1vbml0b3JpbmdcRGFzaGJvYXJkXFYx6gIoR29vZ2xlOjpDbG91ZDo6TW9u
aXRvcmluZzo6RGFzaGJvYXJkOjpWMUqXMAoHEgUOAKcBAQq8BAoBDBIDDgASMrEEIENvcHly
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
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTADYKCQoCAwIS
AxQAKAoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAF0KCQoCCAsSAxcAXQoICgEIEgMY
ACIKCQoCCAoSAxgAIgoICgEIEgMZAC0KCQoCCAgSAxkALQoICgEIEgMaADsKCQoCCAESAxoA
OwoICgEIEgMbAEIKCQoCCCkSAxsAQgoICgEIEgMcAEEKCQoCCC0SAxwAQQpHCgIEABIFHwCP
AQEaOiBBIGNoYXJ0IHRoYXQgZGlzcGxheXMgZGF0YSBvbiBhIDJEIChYIGFuZCBZIGF4ZXMp
IHBsYW5lLgoKCgoDBAABEgMfCA8KTAoEBAADABIEIQJgAxo+IEdyb3VwcyBhIHRpbWUgc2Vy
aWVzIHF1ZXJ5IGRlZmluaXRpb24gd2l0aCBjaGFydGluZyBvcHRpb25zLgoKDAoFBAADAAES
AyEKEQpBCgYEAAMABAASBCMEOwUaMSBUaGUgdHlwZXMgb2YgcGxvdHRpbmcgc3RyYXRlZ2ll
cyBmb3IgZGF0YSBzZXRzLgoKDgoHBAADAAQAARIDIwkRCk0KCAQAAwAEAAIAEgMlBiAaPCBQ
bG90IHR5cGUgaXMgdW5zcGVjaWZpZWQuIFRoZSB2aWV3IHdpbGwgZGVmYXVsdCB0byBgTElO
RWAuCgoQCgkEAAMABAACAAESAyUGGwoQCgkEAAMABAACAAISAyUeHwpPCggEAAMABAACARID
KAYPGj4gVGhlIGRhdGEgaXMgcGxvdHRlZCBhcyBhIHNldCBvZiBsaW5lcyAob25lIGxpbmUg
cGVyIHNlcmllcykuCgoQCgkEAAMABAACAQESAygGCgoQCgkEAAMABAACAQISAygNDgqvAgoI
BAADAAQAAgISAy4GFxqdAiBUaGUgZGF0YSBpcyBwbG90dGVkIGFzIGEgc2V0IG9mIGZpbGxl
ZCBhcmVhcyAob25lIGFyZWEgcGVyIHNlcmllcyksCiB3aXRoIHRoZSBhcmVhcyBzdGFja2Vk
IHZlcnRpY2FsbHkgKHRoZSBiYXNlIG9mIGVhY2ggYXJlYSBpcyB0aGUgdG9wIG9mCiBpdHMg
cHJlZGVjZXNzb3IsIGFuZCB0aGUgYmFzZSBvZiB0aGUgZmlyc3QgYXJlYSBpcyB0aGUgeC1h
eGlzKS4gU2luY2UKIHRoZSBhcmVhcyBkbyBub3Qgb3ZlcmxhcCwgZWFjaCBpcyBmaWxsZWQg
d2l0aCBhIGRpZmZlcmVudCBvcGFxdWUgY29sb3IuCgoQCgkEAAMABAACAgESAy4GEgoQCgkE
AAMABAACAgISAy4VFgqxAgoIBAADAAQAAgMSAzQGFhqfAiBUaGUgZGF0YSBpcyBwbG90dGVk
IGFzIGEgc2V0IG9mIHJlY3Rhbmd1bGFyIGJveGVzIChvbmUgYm94IHBlciBzZXJpZXMpLAog
d2l0aCB0aGUgYm94ZXMgc3RhY2tlZCB2ZXJ0aWNhbGx5ICh0aGUgYmFzZSBvZiBlYWNoIGJv
eCBpcyB0aGUgdG9wIG9mCiBpdHMgcHJlZGVjZXNzb3IsIGFuZCB0aGUgYmFzZSBvZiB0aGUg
Zmlyc3QgYm94IGlzIHRoZSB4LWF4aXMpLiBTaW5jZQogdGhlIGJveGVzIGRvIG5vdCBvdmVy
bGFwLCBlYWNoIGlzIGZpbGxlZCB3aXRoIGEgZGlmZmVyZW50IG9wYXF1ZSBjb2xvci4KChAK
CQQAAwAEAAIDARIDNAYRChAKCQQAAwAEAAIDAhIDNBQVCo4CCggEAAMABAACBBIDOgYSGvwB
IFRoZSBkYXRhIGlzIHBsb3R0ZWQgYXMgYSBoZWF0bWFwLiBUaGUgc2VyaWVzIGJlaW5nIHBs
b3R0ZWQgbXVzdCBoYXZlIGEKIGBESVNUUklCVVRJT05gIHZhbHVlIHR5cGUuIFRoZSB2YWx1
ZSBvZiBlYWNoIGJ1Y2tldCBpbiB0aGUgZGlzdHJpYnV0aW9uCiBpcyBkaXNwbGF5ZWQgYXMg
YSBjb2xvci4gVGhpcyB0eXBlIGlzIG5vdCBjdXJyZW50bHkgYXZhaWxhYmxlIGluIHRoZQog
U3RhY2tkcml2ZXIgTW9uaXRvcmluZyBhcHBsaWNhdGlvbi4KChAKCQQAAwAEAAIEARIDOgYN
ChAKCQQAAwAEAAIEAhIDOhARCiUKBgQAAwAEARIEPgRHBRoVIEFuIGF4aXMgaWRlbnRpZmll
ci4KCg4KBwQAAwAEAQESAz4JEwpFCggEAAMABAECABIDQAYiGjQgVGhlIHRhcmdldCBheGlz
IHdhcyBub3Qgc3BlY2lmaWVkLiBEZWZhdWx0cyB0byBZMS4KChAKCQQAAwAEAQIAARIDQAYd
ChAKCQQAAwAEAQIAAhIDQCAhCjgKCAQAAwAEAQIBEgNDBg0aJyBUaGUgeV9heGlzICh0aGUg
cmlnaHQgYXhpcyBvZiBjaGFydCkuCgoQCgkEAAMABAECAQESA0MGCAoQCgkEAAMABAECAQIS
A0MLDAo4CggEAAMABAECAhIDRgYNGicgVGhlIHkyX2F4aXMgKHRoZSBsZWZ0IGF4aXMgb2Yg
Y2hhcnQpLgoKEAoJBAADAAQBAgIBEgNGBggKEAoJBAADAAQBAgICEgNGCwwKYwoGBAADAAIA
EgRLBEwxGlMgUmVxdWlyZWQuIEZpZWxkcyBmb3IgcXVlcnlpbmcgdGltZSBzZXJpZXMgZGF0
YSBmcm9tIHRoZQogU3RhY2tkcml2ZXIgbWV0cmljcyBBUEkuCgoOCgcEAAMAAgAGEgNLBBMK
DgoHBAADAAIAARIDSxQlCg4KBwQAAwACAAMSA0soKQoOCgcEAAMAAgAIEgNMCDAKEQoKBAAD
AAIACJwIABIDTAkvCj4KBgQAAwACARIDTwQbGi8gSG93IHRoaXMgZGF0YSBzaG91bGQgYmUg
cGxvdHRlZCBvbiB0aGUgY2hhcnQuCgoOCgcEAAMAAgEGEgNPBAwKDgoHBAADAAIBARIDTw0W
Cg4KBwQAAwACAQMSA08ZGgrKAQoGBAADAAICEgNUBB8augEgQSB0ZW1wbGF0ZSBzdHJpbmcg
Zm9yIG5hbWluZyBgVGltZVNlcmllc2AgaW4gdGhlIHJlc3VsdGluZyBkYXRhIHNldC4KIFRo
aXMgc2hvdWxkIGJlIGEgc3RyaW5nIHdpdGggaW50ZXJwb2xhdGlvbnMgb2YgdGhlIGZvcm0g
YCR7bGFiZWxfbmFtZX1gLAogd2hpY2ggd2lsbCByZXNvbHZlIHRvIHRoZSBsYWJlbCdzIHZh
bHVlLgoKDgoHBAADAAICBRIDVAQKCg4KBwQAAwACAgESA1QLGgoOCgcEAAMAAgIDEgNUHR4K
8AIKBgQAAwACAxIEWwRcMRrfAiBPcHRpb25hbC4gVGhlIGxvd2VyIGJvdW5kIG9uIGRhdGEg
cG9pbnQgZnJlcXVlbmN5IGZvciB0aGlzIGRhdGEgc2V0LAogaW1wbGVtZW50ZWQgYnkgc3Bl
Y2lmeWluZyB0aGUgbWluaW11bSBhbGlnbm1lbnQgcGVyaW9kIHRvIHVzZSBpbiBhIHRpbWUK
IHNlcmllcyBxdWVyeSBGb3IgZXhhbXBsZSwgaWYgdGhlIGRhdGEgaXMgcHVibGlzaGVkIG9u
Y2UgZXZlcnkgMTAgbWludXRlcywKIHRoZSBgbWluX2FsaWdubWVudF9wZXJpb2RgIHNob3Vs
ZCBiZSBhdCBsZWFzdCAxMCBtaW51dGVzLiBJdCB3b3VsZCBub3QKIG1ha2Ugc2Vuc2UgdG8g
ZmV0Y2ggYW5kIGFsaWduIGRhdGEgYXQgb25lIG1pbnV0ZSBpbnRlcnZhbHMuCgoOCgcEAAMA
AgMGEgNbBBwKDgoHBAADAAIDARIDWx0xCg4KBwQAAwACAwMSA1s0NQoOCgcEAAMAAgMIEgNc
CDAKEQoKBAADAAIDCJwIABIDXAkvCkoKBgQAAwACBBIDXwRIGjsgT3B0aW9uYWwuIFRoZSB0
YXJnZXQgYXhpcyB0byB1c2UgZm9yIHBsb3R0aW5nIHRoZSBtZXRyaWMuCgoOCgcEAAMAAgQG
EgNfBA4KDgoHBAADAAIEARIDXw8aCg4KBwQAAwACBAMSA18dHgoOCgcEAAMAAgQIEgNfH0cK
EQoKBAADAAIECJwIABIDXyBGCh0KBAQAAwESBGMCdQMaDyBBIGNoYXJ0IGF4aXMuCgoMCgUE
AAMBARIDYwoOCi8KBgQAAwEEABIEZQRuBRofIFR5cGVzIG9mIHNjYWxlcyB1c2VkIGluIGF4
ZXMuCgoOCgcEAAMBBAABEgNlCQ4KSwoIBAADAQQAAgASA2cGHBo6IFNjYWxlIGlzIHVuc3Bl
Y2lmaWVkLiBUaGUgdmlldyB3aWxsIGRlZmF1bHQgdG8gYExJTkVBUmAuCgoQCgkEAAMBBAAC
AAESA2cGFwoQCgkEAAMBBAACAAISA2caGwogCggEAAMBBAACARIDagYRGg8gTGluZWFyIHNj
YWxlLgoKEAoJBAADAQQAAgEBEgNqBgwKEAoJBAADAQQAAgECEgNqDxAKLwoIBAADAQQAAgIS
A20GEBoeIExvZ2FyaXRobWljIHNjYWxlIChiYXNlIDEwKS4KChAKCQQAAwEEAAICARIDbQYL
ChAKCQQAAwEEAAICAhIDbQ4PCicKBgQAAwECABIDcQQVGhggVGhlIGxhYmVsIG9mIHRoZSBh
eGlzLgoKDgoHBAADAQIABRIDcQQKCg4KBwQAAwECAAESA3ELEAoOCgcEAAMBAgADEgNxExQK
RAoGBAADAQIBEgN0BBQaNSBUaGUgYXhpcyBzY2FsZS4gQnkgZGVmYXVsdCwgYSBsaW5lYXIg
c2NhbGUgaXMgdXNlZC4KCg4KBwQAAwECAQYSA3QECQoOCgcEAAMBAgEBEgN0Cg8KDgoHBAAD
AQIBAxIDdBITCjoKBAQAAgASA3gCShotIFJlcXVpcmVkLiBUaGUgZGF0YSBkaXNwbGF5ZWQg
aW4gdGhpcyBjaGFydC4KCgwKBQQAAgAEEgN4AgoKDAoFBAACAAYSA3gLEgoMCgUEAAIAARID
eBMcCgwKBQQAAgADEgN4HyAKDAoFBAACAAgSA3ghSQoPCggEAAIACJwIABIDeCJICp4CCgQE
AAIBEgN/AjIakAIgVGhlIGR1cmF0aW9uIHVzZWQgdG8gZGlzcGxheSBhIGNvbXBhcmlzb24g
Y2hhcnQuIEEgY29tcGFyaXNvbiBjaGFydAogc2ltdWx0YW5lb3VzbHkgc2hvd3MgdmFsdWVz
IGZyb20gdHdvIHNpbWlsYXItbGVuZ3RoIHRpbWUgcGVyaW9kcwogKGUuZy4sIHdlZWstb3Zl
ci13ZWVrIG1ldHJpY3MpLgogVGhlIGR1cmF0aW9uIG11c3QgYmUgcG9zaXRpdmUsIGFuZCBp
dCBjYW4gb25seSBiZSBhcHBsaWVkIHRvIGNoYXJ0cyB3aXRoCiBkYXRhIHNldHMgb2YgTElO
RSBwbG90IHR5cGUuCgoMCgUEAAIBBhIDfwIaCgwKBQQAAgEBEgN/Gy0KDAoFBAACAQMSA38w
MQpECgQEAAICEgSCAQIkGjYgVGhyZXNob2xkIGxpbmVzIGRyYXduIGhvcml6b250YWxseSBh
Y3Jvc3MgdGhlIGNoYXJ0LgoKDQoFBAACAgQSBIIBAgoKDQoFBAACAgYSBIIBCxQKDQoFBAAC
AgESBIIBFR8KDQoFBAACAgMSBIIBIiMKNQoEBAACAxIEhQECEhonIFRoZSBwcm9wZXJ0aWVz
IGFwcGxpZWQgdG8gdGhlIHgtYXhpcy4KCg0KBQQAAgMGEgSFAQIGCg0KBQQAAgMBEgSFAQcN
Cg0KBQQAAgMDEgSFARARCjUKBAQAAgQSBIgBAhIaJyBUaGUgcHJvcGVydGllcyBhcHBsaWVk
IHRvIHRoZSB5LWF4aXMuCgoNCgUEAAIEBhIEiAECBgoNCgUEAAIEARIEiAEHDQoNCgUEAAIE
AxIEiAEQEQo2CgQEAAIFEgSLAQITGiggVGhlIHByb3BlcnRpZXMgYXBwbGllZCB0byB0aGUg
eTItYXhpcy4KCg0KBQQAAgUGEgSLAQIGCg0KBQQAAgUBEgSLAQcOCg0KBQQAAgUDEgSLARES
Ci4KBAQAAgYSBI4BAiEaICBEaXNwbGF5IG9wdGlvbnMgZm9yIHRoZSBjaGFydC4KCg0KBQQA
AgYGEgSOAQIOCg0KBQQAAgYBEgSOAQ8cCg0KBQQAAgYDEgSOAR8gCj8KAgQBEgaSAQCnAQEa
MSBPcHRpb25zIHRvIGNvbnRyb2wgdmlzdWFsIHJlbmRlcmluZyBvZiBhIGNoYXJ0LgoKCwoD
BAEBEgSSAQgUCiUKBAQBBAASBpQBAqMBAxoVIENoYXJ0IG1vZGUgb3B0aW9ucy4KCg0KBQQB
BAABEgSUAQcLCkgKBgQBBAACABIElgEEGRo4IE1vZGUgaXMgdW5zcGVjaWZpZWQuIFRoZSB2
aWV3IHdpbGwgZGVmYXVsdCB0byBgQ09MT1JgLgoKDwoHBAEEAAIAARIElgEEFAoPCgcEAQQA
AgACEgSWARcYCpEBCgYEAQQAAgESBJoBBA4agAEgVGhlIGNoYXJ0IGRpc3Rpbmd1aXNoZXMg
ZGF0YSBzZXJpZXMgdXNpbmcgZGlmZmVyZW50IGNvbG9yLiBMaW5lCiBjb2xvcnMgbWF5IGdl
dCByZXVzZWQgd2hlbiB0aGVyZSBhcmUgbWFueSBsaW5lcyBpbiB0aGUgY2hhcnQuCgoPCgcE
AQQAAgEBEgSaAQQJCg8KBwQBBAACAQISBJoBDA0KhgEKBgQBBAACAhIEngEEDhp2IFRoZSBj
aGFydCB1c2VzIHRoZSBTdGFja2RyaXZlciB4LXJheSBtb2RlLCBpbiB3aGljaCBlYWNoCiBk
YXRhIHNldCBpcyBwbG90dGVkIHVzaW5nIHRoZSBzYW1lIHNlbWktdHJhbnNwYXJlbnQgY29s
b3IuCgoPCgcEAQQAAgIBEgSeAQQJCg8KBwQBBAACAgISBJ4BDA0KZAoGBAEEAAIDEgSiAQQO
GlQgVGhlIGNoYXJ0IGRpc3BsYXlzIHN0YXRpc3RpY3Mgc3VjaCBhcyBhdmVyYWdlLCBtZWRp
YW4sIDk1dGggcGVyY2VudGlsZSwKIGFuZCBtb3JlLgoKDwoHBAEEAAIDARIEogEECQoPCgcE
AQQAAgMCEgSiAQwNCh8KBAQBAgASBKYBAhAaESBUaGUgY2hhcnQgbW9kZS4KCg0KBQQBAgAG
EgSmAQIGCg0KBQQBAgABEgSmAQcLCg0KBQQBAgADEgSmAQ4PYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Xychart::XyChart ===
    # Fields for XyChart
    # Field: data_sets Type: 11 (.google.monitoring.dashboard.v1.XyChart.DataSet)
    # Field: timeshift_duration Type: 11 (.google.protobuf.Duration)
    # Field: thresholds Type: 11 (.google.monitoring.dashboard.v1.Threshold)
    # Field: x_axis Type: 11 (.google.monitoring.dashboard.v1.XyChart.Axis)
    # Field: y_axis Type: 11 (.google.monitoring.dashboard.v1.XyChart.Axis)
    # Field: y2_axis Type: 11 (.google.monitoring.dashboard.v1.XyChart.Axis)
    # Field: chart_options Type: 11 (.google.monitoring.dashboard.v1.ChartOptions)

# === Message: Google::Monitoring::Dashboard::V1::Xychart::ChartOptions ===
    # Fields for ChartOptions
    # Field: mode Type: 14 (.google.monitoring.dashboard.v1.ChartOptions.Mode)

# Enum: ChartOptions::Mode
our $ChartOptions_MODE_UNSPECIFIED = 0;
our $ChartOptions_COLOR = 1;
our $ChartOptions_X_RAY = 2;
our $ChartOptions_STATS = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Xychart - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/xychart.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Xychart;

    my $msg = Google::Monitoring::Dashboard::V1::Xychart::XyChart->new({
        data_sets => $data_sets,
        timeshift_duration => $timeshift_duration,
        thresholds => $thresholds,
        x_axis => $x_axis,
    });

    # Read or update a field
    my $val = $msg->data_sets();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Xychart::XyChart->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/xychart.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Xychart::XyChart

A chart that displays data on a 2D (X and Y axes) plane.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_sets() >> / C<< $msg->data_sets($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Xychart::XyChart::DataSet>)

Required. The data displayed in this chart.

=item * C<< $msg->timeshift_duration() >> / C<< $msg->timeshift_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The duration used to display a comparison chart. A comparison chart
simultaneously shows values from two similar-length time periods
(e.g., week-over-week metrics).
The duration must be positive, and it can only be applied to charts with
data sets of LINE plot type.

=item * C<< $msg->thresholds() >> / C<< $msg->thresholds($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::Threshold>)

Threshold lines drawn horizontally across the chart.

=item * C<< $msg->x_axis() >> / C<< $msg->x_axis($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Xychart::XyChart::Axis>)

The properties applied to the x-axis.

=item * C<< $msg->y_axis() >> / C<< $msg->y_axis($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Xychart::XyChart::Axis>)

The properties applied to the y-axis.

=item * C<< $msg->y2_axis() >> / C<< $msg->y2_axis($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Xychart::XyChart::Axis>)

The properties applied to the y2-axis.

=item * C<< $msg->chart_options() >> / C<< $msg->chart_options($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Xychart::ChartOptions>)

Display options for the chart.

=back

=head2 Google::Monitoring::Dashboard::V1::Xychart::ChartOptions

Options to control visual rendering of a chart.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::ChartOptions::Mode>)

The chart mode.

=back

=head3 Enum: ChartOptions::Mode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<COLOR> => C<1>

=item * C<X_RAY> => C<2>

=item * C<STATS> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Xychart::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
