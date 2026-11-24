package Google::Datastore::V1::Entity;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvZGF0YXN0b3JlL3YxL2VudGl0eS5wcm90bxITZ29vZ2xlLmRhdGFzdG9yZS52
MRocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90bxoYZ29vZ2xlL3R5cGUvbGF0bG5nLnByb3RvInAKC1BhcnRpdGlvbklkEh0K
CnByb2plY3RfaWQYAiABKAlSCXByb2plY3RJZBIfCgtkYXRhYmFzZV9pZBgDIAEoCVIKZGF0
YWJhc2VJZBIhCgxuYW1lc3BhY2VfaWQYBCABKAlSC25hbWVzcGFjZUlkItoBCgNLZXkSQwoM
cGFydGl0aW9uX2lkGAEgASgLMiAuZ29vZ2xlLmRhdGFzdG9yZS52MS5QYXJ0aXRpb25JZFIL
cGFydGl0aW9uSWQSOAoEcGF0aBgCIAMoCzIkLmdvb2dsZS5kYXRhc3RvcmUudjEuS2V5LlBh
dGhFbGVtZW50UgRwYXRoGlQKC1BhdGhFbGVtZW50EhIKBGtpbmQYASABKAlSBGtpbmQSEAoC
aWQYAiABKANIAFICaWQSFAoEbmFtZRgDIAEoCUgAUgRuYW1lQgkKB2lkX3R5cGUiQAoKQXJy
YXlWYWx1ZRIyCgZ2YWx1ZXMYASADKAsyGi5nb29nbGUuZGF0YXN0b3JlLnYxLlZhbHVlUgZ2
YWx1ZXMinAUKBVZhbHVlEjsKCm51bGxfdmFsdWUYCyABKA4yGi5nb29nbGUucHJvdG9idWYu
TnVsbFZhbHVlSABSCW51bGxWYWx1ZRIlCg1ib29sZWFuX3ZhbHVlGAEgASgISABSDGJvb2xl
YW5WYWx1ZRIlCg1pbnRlZ2VyX3ZhbHVlGAIgASgDSABSDGludGVnZXJWYWx1ZRIjCgxkb3Vi
bGVfdmFsdWUYAyABKAFIAFILZG91YmxlVmFsdWUSRQoPdGltZXN0YW1wX3ZhbHVlGAogASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUg50aW1lc3RhbXBWYWx1ZRI3CglrZXlf
dmFsdWUYBSABKAsyGC5nb29nbGUuZGF0YXN0b3JlLnYxLktleUgAUghrZXlWYWx1ZRIjCgxz
dHJpbmdfdmFsdWUYESABKAlIAFILc3RyaW5nVmFsdWUSHwoKYmxvYl92YWx1ZRgSIAEoDEgA
UglibG9iVmFsdWUSPQoPZ2VvX3BvaW50X3ZhbHVlGAggASgLMhMuZ29vZ2xlLnR5cGUuTGF0
TG5nSABSDWdlb1BvaW50VmFsdWUSQAoMZW50aXR5X3ZhbHVlGAYgASgLMhsuZ29vZ2xlLmRh
dGFzdG9yZS52MS5FbnRpdHlIAFILZW50aXR5VmFsdWUSQgoLYXJyYXlfdmFsdWUYCSABKAsy
Hy5nb29nbGUuZGF0YXN0b3JlLnYxLkFycmF5VmFsdWVIAFIKYXJyYXlWYWx1ZRIYCgdtZWFu
aW5nGA4gASgFUgdtZWFuaW5nEjAKFGV4Y2x1ZGVfZnJvbV9pbmRleGVzGBMgASgIUhJleGNs
dWRlRnJvbUluZGV4ZXNCDAoKdmFsdWVfdHlwZSLcAQoGRW50aXR5EioKA2tleRgBIAEoCzIY
Lmdvb2dsZS5kYXRhc3RvcmUudjEuS2V5UgNrZXkSSwoKcHJvcGVydGllcxgDIAMoCzIrLmdv
b2dsZS5kYXRhc3RvcmUudjEuRW50aXR5LlByb3BlcnRpZXNFbnRyeVIKcHJvcGVydGllcxpZ
Cg9Qcm9wZXJ0aWVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSMAoFdmFsdWUYAiABKAsyGi5n
b29nbGUuZGF0YXN0b3JlLnYxLlZhbHVlUgV2YWx1ZToCOAFCvAEKF2NvbS5nb29nbGUuZGF0
YXN0b3JlLnYxQgtFbnRpdHlQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFzdG9y
ZS9hcGl2MS9kYXRhc3RvcmVwYjtkYXRhc3RvcmVwYqoCGUdvb2dsZS5DbG91ZC5EYXRhc3Rv
cmUuVjHKAhlHb29nbGVcQ2xvdWRcRGF0YXN0b3JlXFYx6gIcR29vZ2xlOjpDbG91ZDo6RGF0
YXN0b3JlOjpWMUq/OgoHEgUOANgBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACkKCQoCAwISAxQAIgoICgEIEgMW
ADYKCQoCCCUSAxYANgoICgEIEgMXAFIKCQoCCAsSAxcAUgoICgEIEgMYACIKCQoCCAoSAxgA
IgoICgEIEgMZACwKCQoCCAgSAxkALAoICgEIEgMaADAKCQoCCAESAxoAMAoICgEIEgMbADYK
CQoCCCkSAxsANgoICgEIEgMcADUKCQoCCC0SAxwANQriBQoCBAASBDIAPAEa1QUgQSBwYXJ0
aXRpb24gSUQgaWRlbnRpZmllcyBhIGdyb3VwaW5nIG9mIGVudGl0aWVzLiBUaGUgZ3JvdXBp
bmcgaXMgYWx3YXlzCiBieSBwcm9qZWN0IGFuZCBuYW1lc3BhY2UsIGhvd2V2ZXIgdGhlIG5h
bWVzcGFjZSBJRCBtYXkgYmUgZW1wdHkuCgogQSBwYXJ0aXRpb24gSUQgY29udGFpbnMgc2V2
ZXJhbCBkaW1lbnNpb25zOgogcHJvamVjdCBJRCBhbmQgbmFtZXNwYWNlIElELgoKIFBhcnRp
dGlvbiBkaW1lbnNpb25zOgoKIC0gTWF5IGJlIGAiImAuCiAtIE11c3QgYmUgdmFsaWQgVVRG
LTggYnl0ZXMuCiAtIE11c3QgaGF2ZSB2YWx1ZXMgdGhhdCBtYXRjaCByZWdleCBgW0EtWmEt
elxkXC5cLV9dezEsMTAwfWAKIElmIHRoZSB2YWx1ZSBvZiBhbnkgZGltZW5zaW9uIG1hdGNo
ZXMgcmVnZXggYF9fLipfX2AsIHRoZSBwYXJ0aXRpb24gaXMKIHJlc2VydmVkL3JlYWQtb25s
eS4KIEEgcmVzZXJ2ZWQvcmVhZC1vbmx5IHBhcnRpdGlvbiBJRCBpcyBmb3JiaWRkZW4gaW4g
Y2VydGFpbiBkb2N1bWVudGVkCiBjb250ZXh0cy4KCiBGb3JlaWduIHBhcnRpdGlvbiBJRHMg
KGluIHdoaWNoIHRoZSBwcm9qZWN0IElEIGRvZXMKIG5vdCBtYXRjaCB0aGUgY29udGV4dCBw
cm9qZWN0IElEICkgYXJlIGRpc2NvdXJhZ2VkLgogUmVhZHMgYW5kIHdyaXRlcyBvZiBmb3Jl
aWduIHBhcnRpdGlvbiBJRHMgbWF5IGZhaWwgaWYgdGhlIHByb2plY3QgaXMgbm90IGluCiBh
biBhY3RpdmUgc3RhdGUuCgoKCgMEAAESAzIIEwpCCgQEAAIAEgM0AhgaNSBUaGUgSUQgb2Yg
dGhlIHByb2plY3QgdG8gd2hpY2ggdGhlIGVudGl0aWVzIGJlbG9uZy4KCgwKBQQAAgAFEgM0
AggKDAoFBAACAAESAzQJEwoMCgUEAAIAAxIDNBYXClIKBAQAAgESAzgCGRpFIElmIG5vdCBl
bXB0eSwgdGhlIElEIG9mIHRoZSBkYXRhYmFzZSB0byB3aGljaCB0aGUgZW50aXRpZXMKIGJl
bG9uZy4KCgwKBQQAAgEFEgM4AggKDAoFBAACAQESAzgJFAoMCgUEAAIBAxIDOBcYClIKBAQA
AgISAzsCGhpFIElmIG5vdCBlbXB0eSwgdGhlIElEIG9mIHRoZSBuYW1lc3BhY2UgdG8gd2hp
Y2ggdGhlIGVudGl0aWVzIGJlbG9uZy4KCgwKBQQAAgIFEgM7AggKDAoFBAACAgESAzsJFQoM
CgUEAAICAxIDOxgZCusBCgIEARIEQgB+ARreASBBIHVuaXF1ZSBpZGVudGlmaWVyIGZvciBh
biBlbnRpdHkuCiBJZiBhIGtleSdzIHBhcnRpdGlvbiBJRCBvciBhbnkgb2YgaXRzIHBhdGgg
a2luZHMgb3IgbmFtZXMgYXJlCiByZXNlcnZlZC9yZWFkLW9ubHksIHRoZSBrZXkgaXMgcmVz
ZXJ2ZWQvcmVhZC1vbmx5LgogQSByZXNlcnZlZC9yZWFkLW9ubHkga2V5IGlzIGZvcmJpZGRl
biBpbiBjZXJ0YWluIGRvY3VtZW50ZWQgY29udGV4dHMuCgoKCgMEAQESA0IICwqsAQoEBAED
ABIERwJmAxqdASBBIChraW5kLCBJRC9uYW1lKSBwYWlyIHVzZWQgdG8gY29uc3RydWN0IGEg
a2V5IHBhdGguCgogSWYgZWl0aGVyIG5hbWUgb3IgSUQgaXMgc2V0LCB0aGUgZWxlbWVudCBp
cyBjb21wbGV0ZS4KIElmIG5laXRoZXIgaXMgc2V0LCB0aGUgZWxlbWVudCBpcyBpbmNvbXBs
ZXRlLgoKDAoFBAEDAAESA0cKFQrKAgoGBAEDAAIAEgNRBBQaugIgVGhlIGtpbmQgb2YgdGhl
IGVudGl0eS4KCiBBIGtpbmQgbWF0Y2hpbmcgcmVnZXggYF9fLipfX2AgaXMgcmVzZXJ2ZWQv
cmVhZC1vbmx5LgogQSBraW5kIG11c3Qgbm90IGNvbnRhaW4gbW9yZSB0aGFuIDE1MDAgYnl0
ZXMgd2hlbiBVVEYtOCBlbmNvZGVkLgogQ2Fubm90IGJlIGAiImAuCgogTXVzdCBiZSB2YWxp
ZCBVVEYtOCBieXRlcy4gTGVnYWN5IHZhbHVlcyB0aGF0IGFyZSBub3QgdmFsaWQgVVRGLTgg
YXJlCiBlbmNvZGVkIGFzIGBfX2J5dGVzPFg+X19gIHdoZXJlIGA8WD5gIGlzIHRoZSBiYXNl
LTY0IGVuY29kaW5nIG9mIHRoZQogYnl0ZXMuCgoOCgcEAQMAAgAFEgNRBAoKDgoHBAEDAAIA
ARIDUQsPCg4KBwQBAwACAAMSA1ESEwohCgYEAQMACAASBFQEZQUaESBUaGUgdHlwZSBvZiBJ
RC4KCg4KBwQBAwAIAAESA1QKEQqcAQoGBAEDAAIBEgNZBhMajAEgVGhlIGF1dG8tYWxsb2Nh
dGVkIElEIG9mIHRoZSBlbnRpdHkuCgogTmV2ZXIgZXF1YWwgdG8gemVyby4gVmFsdWVzIGxl
c3MgdGhhbiB6ZXJvIGFyZSBkaXNjb3VyYWdlZCBhbmQgbWF5IG5vdAogYmUgc3VwcG9ydGVk
IGluIHRoZSBmdXR1cmUuCgoOCgcEAQMAAgEFEgNZBgsKDgoHBAEDAAIBARIDWQwOCg4KBwQB
AwACAQMSA1kREgrFAgoGBAEDAAICEgNkBhYatQIgVGhlIG5hbWUgb2YgdGhlIGVudGl0eS4K
CiBBIG5hbWUgbWF0Y2hpbmcgcmVnZXggYF9fLipfX2AgaXMgcmVzZXJ2ZWQvcmVhZC1vbmx5
LgogQSBuYW1lIG11c3Qgbm90IGJlIG1vcmUgdGhhbiAxNTAwIGJ5dGVzIHdoZW4gVVRGLTgg
ZW5jb2RlZC4KIENhbm5vdCBiZSBgIiJgLgoKIE11c3QgYmUgdmFsaWQgVVRGLTggYnl0ZXMu
IExlZ2FjeSB2YWx1ZXMgdGhhdCBhcmUgbm90IHZhbGlkIFVURi04IGFyZQogZW5jb2RlZCBh
cyBgX19ieXRlczxYPl9fYCB3aGVyZSBgPFg+YCBpcyB0aGUgYmFzZS02NCBlbmNvZGluZyBv
ZiB0aGUKIGJ5dGVzLgoKDgoHBAEDAAICBRIDZAYMCg4KBwQBAwACAgESA2QNEQoOCgcEAQMA
AgIDEgNkFBUKmQEKBAQBAgASA2sCHxqLASBFbnRpdGllcyBhcmUgcGFydGl0aW9uZWQgaW50
byBzdWJzZXRzLCBjdXJyZW50bHkgaWRlbnRpZmllZCBieSBhIHByb2plY3QKIElEIGFuZCBu
YW1lc3BhY2UgSUQuCiBRdWVyaWVzIGFyZSBzY29wZWQgdG8gYSBzaW5nbGUgcGFydGl0aW9u
LgoKDAoFBAECAAYSA2sCDQoMCgUEAQIAARIDaw4aCgwKBQQBAgADEgNrHR4K9AYKBAQBAgES
A30CIBrmBiBUaGUgZW50aXR5IHBhdGguCiBBbiBlbnRpdHkgcGF0aCBjb25zaXN0cyBvZiBv
bmUgb3IgbW9yZSBlbGVtZW50cyBjb21wb3NlZCBvZiBhIGtpbmQgYW5kIGEKIHN0cmluZyBv
ciBudW1lcmljYWwgaWRlbnRpZmllciwgd2hpY2ggaWRlbnRpZnkgZW50aXRpZXMuIFRoZSBm
aXJzdAogZWxlbWVudCBpZGVudGlmaWVzIGEgX3Jvb3QgZW50aXR5XywgdGhlIHNlY29uZCBl
bGVtZW50IGlkZW50aWZpZXMKIGEgX2NoaWxkXyBvZiB0aGUgcm9vdCBlbnRpdHksIHRoZSB0
aGlyZCBlbGVtZW50IGlkZW50aWZpZXMgYSBjaGlsZCBvZiB0aGUKIHNlY29uZCBlbnRpdHks
IGFuZCBzbyBmb3J0aC4gVGhlIGVudGl0aWVzIGlkZW50aWZpZWQgYnkgYWxsIHByZWZpeGVz
IG9mCiB0aGUgcGF0aCBhcmUgY2FsbGVkIHRoZSBlbGVtZW50J3MgX2FuY2VzdG9yc18uCgog
QW4gZW50aXR5IHBhdGggaXMgYWx3YXlzIGZ1bGx5IGNvbXBsZXRlOiAqYWxsKiBvZiB0aGUg
ZW50aXR5J3MgYW5jZXN0b3JzCiBhcmUgcmVxdWlyZWQgdG8gYmUgaW4gdGhlIHBhdGggYWxv
bmcgd2l0aCB0aGUgZW50aXR5IGlkZW50aWZpZXIgaXRzZWxmLgogVGhlIG9ubHkgZXhjZXB0
aW9uIGlzIHRoYXQgaW4gc29tZSBkb2N1bWVudGVkIGNhc2VzLCB0aGUgaWRlbnRpZmllciBp
biB0aGUKIGxhc3QgcGF0aCBlbGVtZW50IChmb3IgdGhlIGVudGl0eSkgaXRzZWxmIG1heSBi
ZSBvbWl0dGVkLiBGb3IgZXhhbXBsZSwKIHRoZSBsYXN0IHBhdGggZWxlbWVudCBvZiB0aGUg
a2V5IG9mIGBNdXRhdGlvbi5pbnNlcnRgIG1heSBoYXZlIG5vCiBpZGVudGlmaWVyLgoKIEEg
cGF0aCBjYW4gbmV2ZXIgYmUgZW1wdHksIGFuZCBhIHBhdGggY2FuIGhhdmUgYXQgbW9zdCAx
MDAgZWxlbWVudHMuCgoMCgUEAQIBBBIDfQIKCgwKBQQBAgEGEgN9CxYKDAoFBAECAQESA30X
GwoMCgUEAQIBAxIDfR4fCh8KAgQCEgaBAQCGAQEaESBBbiBhcnJheSB2YWx1ZS4KCgsKAwQC
ARIEgQEIEgqeAQoEBAICABIEhQECHBqPASBWYWx1ZXMgaW4gdGhlIGFycmF5LgogVGhlIG9y
ZGVyIG9mIHZhbHVlcyBpbiBhbiBhcnJheSBpcyBwcmVzZXJ2ZWQgYXMgbG9uZyBhcyBhbGwg
dmFsdWVzIGhhdmUKIGlkZW50aWNhbCBzZXR0aW5ncyBmb3IgJ2V4Y2x1ZGVfZnJvbV9pbmRl
eGVzJy4KCg0KBQQCAgAEEgSFAQIKCg0KBQQCAgAGEgSFAQsQCg0KBQQCAgABEgSFAREXCg0K
BQQCAgADEgSFARobCmIKAgQDEgaKAQDDAQEaVCBBIG1lc3NhZ2UgdGhhdCBjYW4gaG9sZCBh
bnkgb2YgdGhlIHN1cHBvcnRlZCB2YWx1ZSB0eXBlcyBhbmQgYXNzb2NpYXRlZAogbWV0YWRh
dGEuCgoLCgMEAwESBIoBCA0KKAoEBAMIABIGjAECuwEDGhggTXVzdCBoYXZlIGEgdmFsdWUg
c2V0LgoKDQoFBAMIAAESBIwBCBIKHQoEBAMCABIEjgEELhoPIEEgbnVsbCB2YWx1ZS4KCg0K
BQQDAgAGEgSOAQQdCg0KBQQDAgABEgSOAR4oCg0KBQQDAgADEgSOASstCiAKBAQDAgESBJEB
BBsaEiBBIGJvb2xlYW4gdmFsdWUuCgoNCgUEAwIBBRIEkQEECAoNCgUEAwIBARIEkQEJFgoN
CgUEAwIBAxIEkQEZGgohCgQEAwICEgSUAQQcGhMgQW4gaW50ZWdlciB2YWx1ZS4KCg0KBQQD
AgIFEgSUAQQJCg0KBQQDAgIBEgSUAQoXCg0KBQQDAgIDEgSUARobCh8KBAQDAgMSBJcBBBwa
ESBBIGRvdWJsZSB2YWx1ZS4KCg0KBQQDAgMFEgSXAQQKCg0KBQQDAgMBEgSXAQsXCg0KBQQD
AgMDEgSXARobCooBCgQEAwIEEgScAQQzGnwgQSB0aW1lc3RhbXAgdmFsdWUuCiBXaGVuIHN0
b3JlZCBpbiB0aGUgRGF0YXN0b3JlLCBwcmVjaXNlIG9ubHkgdG8gbWljcm9zZWNvbmRzOwog
YW55IGFkZGl0aW9uYWwgcHJlY2lzaW9uIGlzIHJvdW5kZWQgZG93bi4KCg0KBQQDAgQGEgSc
AQQdCg0KBQQDAgQBEgScAR4tCg0KBQQDAgQDEgScATAyChwKBAQDAgUSBJ8BBBYaDiBBIGtl
eSB2YWx1ZS4KCg0KBQQDAgUGEgSfAQQHCg0KBQQDAgUBEgSfAQgRCg0KBQQDAgUDEgSfARQV
CrYBCgQEAwIGEgSkAQQdGqcBIEEgVVRGLTggZW5jb2RlZCBzdHJpbmcgdmFsdWUuCiBXaGVu
IGBleGNsdWRlX2Zyb21faW5kZXhlc2AgaXMgZmFsc2UgKGl0IGlzIGluZGV4ZWQpICwgbWF5
IGhhdmUgYXQgbW9zdAogMTUwMCBieXRlcy4gT3RoZXJ3aXNlLCBtYXkgYmUgc2V0IHRvIGF0
IG1vc3QgMSwwMDAsMDAwIGJ5dGVzLgoKDQoFBAMCBgUSBKQBBAoKDQoFBAMCBgESBKQBCxcK
DQoFBAMCBgMSBKQBGhwKsAEKBAQDAgcSBKoBBBoaoQEgQSBibG9iIHZhbHVlLgogTWF5IGhh
dmUgYXQgbW9zdCAxLDAwMCwwMDAgYnl0ZXMuCiBXaGVuIGBleGNsdWRlX2Zyb21faW5kZXhl
c2AgaXMgZmFsc2UsIG1heSBoYXZlIGF0IG1vc3QgMTUwMCBieXRlcy4KIEluIEpTT04gcmVx
dWVzdHMsIG11c3QgYmUgYmFzZTY0LWVuY29kZWQuCgoNCgUEAwIHBRIEqgEECQoNCgUEAwIH
ARIEqgEKFAoNCgUEAwIHAxIEqgEXGQpPCgQEAwIIEgStAQQrGkEgQSBnZW8gcG9pbnQgdmFs
dWUgcmVwcmVzZW50aW5nIGEgcG9pbnQgb24gdGhlIHN1cmZhY2Ugb2YgRWFydGguCgoNCgUE
AwIIBhIErQEEFgoNCgUEAwIIARIErQEXJgoNCgUEAwIIAxIErQEpKgqKAQoEBAMCCRIEtAEE
HBp8IEFuIGVudGl0eSB2YWx1ZS4KCiAtIE1heSBoYXZlIG5vIGtleS4KIC0gTWF5IGhhdmUg
YSBrZXkgd2l0aCBhbiBpbmNvbXBsZXRlIGtleSBwYXRoLgogLSBNYXkgaGF2ZSBhIHJlc2Vy
dmVkL3JlYWQtb25seSBrZXkuCgoNCgUEAwIJBhIEtAEECgoNCgUEAwIJARIEtAELFwoNCgUE
AwIJAxIEtAEaGwqxAQoEBAMCChIEugEEHxqiASBBbiBhcnJheSB2YWx1ZS4KIENhbm5vdCBj
b250YWluIGFub3RoZXIgYXJyYXkgdmFsdWUuCiBBIGBWYWx1ZWAgaW5zdGFuY2UgdGhhdCBz
ZXRzIGZpZWxkIGBhcnJheV92YWx1ZWAgbXVzdCBub3Qgc2V0IGZpZWxkcwogYG1lYW5pbmdg
IG9yIGBleGNsdWRlX2Zyb21faW5kZXhlc2AuCgoNCgUEAwIKBhIEugEEDgoNCgUEAwIKARIE
ugEPGgoNCgUEAwIKAxIEugEdHgpZCgQEAwILEgS+AQIVGksgVGhlIGBtZWFuaW5nYCBmaWVs
ZCBzaG91bGQgb25seSBiZSBwb3B1bGF0ZWQgZm9yIGJhY2t3YXJkcyBjb21wYXRpYmlsaXR5
LgoKDQoFBAMCCwUSBL4BAgcKDQoFBAMCCwESBL4BCA8KDQoFBAMCCwMSBL4BEhQKZQoEBAMC
DBIEwgECIRpXIElmIHRoZSB2YWx1ZSBzaG91bGQgYmUgZXhjbHVkZWQgZnJvbSBhbGwgaW5k
ZXhlcyBpbmNsdWRpbmcgdGhvc2UgZGVmaW5lZAogZXhwbGljaXRseS4KCg0KBQQDAgwFEgTC
AQIGCg0KBQQDAgwBEgTCAQcbCg0KBQQDAgwDEgTCAR4gCksKAgQEEgbIAQDYAQEaPSBBIERh
dGFzdG9yZSBkYXRhIG9iamVjdC4KCiBNdXN0IG5vdCBleGNlZWQgMSBNaUIgLSA0IGJ5dGVz
LgoKCwoDBAQBEgTIAQgOCvIBCgQEBAIAEgTPAQIOGuMBIFRoZSBlbnRpdHkncyBrZXkuCgog
QW4gZW50aXR5IG11c3QgaGF2ZSBhIGtleSwgdW5sZXNzIG90aGVyd2lzZSBkb2N1bWVudGVk
IChmb3IgZXhhbXBsZSwKIGFuIGVudGl0eSBpbiBgVmFsdWUuZW50aXR5X3ZhbHVlYCBtYXkg
aGF2ZSBubyBrZXkpLgogQW4gZW50aXR5J3Mga2luZCBpcyBpdHMga2V5IHBhdGgncyBsYXN0
IGVsZW1lbnQncyBraW5kLAogb3IgbnVsbCBpZiBpdCBoYXMgbm8ga2V5LgoKDQoFBAQCAAYS
BM8BAgUKDQoFBAQCAAESBM8BBgkKDQoFBAQCAAMSBM8BDA0KoQIKBAQEAgESBNcBAiQakgIg
VGhlIGVudGl0eSdzIHByb3BlcnRpZXMuCiBUaGUgbWFwJ3Mga2V5cyBhcmUgcHJvcGVydHkg
bmFtZXMuCiBBIHByb3BlcnR5IG5hbWUgbWF0Y2hpbmcgcmVnZXggYF9fLipfX2AgaXMgcmVz
ZXJ2ZWQuCiBBIHJlc2VydmVkIHByb3BlcnR5IG5hbWUgaXMgZm9yYmlkZGVuIGluIGNlcnRh
aW4gZG9jdW1lbnRlZCBjb250ZXh0cy4KIFRoZSBtYXAga2V5cywgcmVwcmVzZW50ZWQgYXMg
VVRGLTgsIG11c3Qgbm90IGV4Y2VlZCAxLDUwMCBieXRlcyBhbmQgY2Fubm90CiBiZSBlbXB0
eS4KCg0KBQQEAgEGEgTXAQIUCg0KBQQEAgEBEgTXARUfCg0KBQQEAgEDEgTXASIjYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::V1::Entity::PartitionId ===
    # Fields for PartitionId
    # Field: project_id Type: 9 ()
    # Field: database_id Type: 9 ()
    # Field: namespace_id Type: 9 ()

# === Message: Google::Datastore::V1::Entity::Key ===
    # Fields for Key
    # Field: partition_id Type: 11 (.google.datastore.v1.PartitionId)
    # Field: path Type: 11 (.google.datastore.v1.Key.PathElement)

# === Message: Google::Datastore::V1::Entity::ArrayValue ===
    # Fields for ArrayValue
    # Field: values Type: 11 (.google.datastore.v1.Value)

# === Message: Google::Datastore::V1::Entity::Value ===
    # Fields for Value
    # Field: null_value Type: 14 (.google.protobuf.NullValue)
    # Field: boolean_value Type: 8 ()
    # Field: integer_value Type: 3 ()
    # Field: double_value Type: 1 ()
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: key_value Type: 11 (.google.datastore.v1.Key)
    # Field: string_value Type: 9 ()
    # Field: blob_value Type: 12 ()
    # Field: geo_point_value Type: 11 (.google.type.LatLng)
    # Field: entity_value Type: 11 (.google.datastore.v1.Entity)
    # Field: array_value Type: 11 (.google.datastore.v1.ArrayValue)
    # Field: meaning Type: 5 ()
    # Field: exclude_from_indexes Type: 8 ()

# === Message: Google::Datastore::V1::Entity::Entity ===
    # Fields for Entity
    # Field: key Type: 11 (.google.datastore.v1.Key)
    # Field: properties Type: 11 (.google.datastore.v1.Entity.PropertiesEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::V1::Entity - Compiled Protocol Buffers messages for google/datastore/v1/entity.proto

=head1 SYNOPSIS

    use Google::Datastore::V1::Entity;

    my $msg = Google::Datastore::V1::Entity::PartitionId->new({
        project_id => $project_id,
        database_id => $database_id,
        namespace_id => $namespace_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::V1::Entity::PartitionId->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/v1/entity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::V1::Entity::PartitionId

A partition ID identifies a grouping of entities. The grouping is always
by project and namespace, however the namespace ID may be empty.

A partition ID contains several dimensions:
project ID and namespace ID.

Partition dimensions:

- May be `""`.
- Must be valid UTF-8 bytes.
- Must have values that match regex `[A-Za-z\d\.\-_]{1,100}`
If the value of any dimension matches regex `__.*__`, the partition is
reserved/read-only.
A reserved/read-only partition ID is forbidden in certain documented
contexts.

Foreign partition IDs (in which the project ID does
not match the context project ID ) are discouraged.
Reads and writes of foreign partition IDs may fail if the project is not in
an active state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project to which the entities belong.

=item * C<< $msg->database_id() >> / C<< $msg->database_id($value) >>

Type: C<String>

If not empty, the ID of the database to which the entities
belong.

=item * C<< $msg->namespace_id() >> / C<< $msg->namespace_id($value) >>

Type: C<String>

If not empty, the ID of the namespace to which the entities belong.

=back

=head2 Google::Datastore::V1::Entity::Key

A unique identifier for an entity.
If a key's partition ID or any of its path kinds or names are
reserved/read-only, the key is reserved/read-only.
A reserved/read-only key is forbidden in certain documented contexts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partition_id() >> / C<< $msg->partition_id($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::PartitionId>)

Entities are partitioned into subsets, currently identified by a project
ID and namespace ID.
Queries are scoped to a single partition.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::Key::PathElement>)

The entity path.
An entity path consists of one or more elements composed of a kind and a
string or numerical identifier, which identify entities. The first
element identifies a _root entity_, the second element identifies
a _child_ of the root entity, the third element identifies a child of the
second entity, and so forth. The entities identified by all prefixes of
the path are called the element's _ancestors_.

An entity path is always fully complete: *all* of the entity's ancestors
are required to be in the path along with the entity identifier itself.
The only exception is that in some documented cases, the identifier in the
last path element (for the entity) itself may be omitted. For example,
the last path element of the key of `Mutation.insert` may have no
identifier.

A path can never be empty, and a path can have at most 100 elements.

=back

=head2 Google::Datastore::V1::Entity::ArrayValue

An array value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::Value>)

Values in the array.
The order of values in an array is preserved as long as all values have
identical settings for 'exclude_from_indexes'.

=back

=head2 Google::Datastore::V1::Entity::Value

A message that can hold any of the supported value types and associated
metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->null_value() >> / C<< $msg->null_value($value) >>

Type: C<Enum> (L<Google::Protobuf::NullValue>)

A null value.

=item * C<< $msg->boolean_value() >> / C<< $msg->boolean_value($value) >>

Type: C<Bool>

A boolean value.

=item * C<< $msg->integer_value() >> / C<< $msg->integer_value($value) >>

Type: C<Int64>

An integer value.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

A double value.

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

A timestamp value.
When stored in the Datastore, precise only to microseconds;
any additional precision is rounded down.

=item * C<< $msg->key_value() >> / C<< $msg->key_value($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::Key>)

A key value.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A UTF-8 encoded string value.
When `exclude_from_indexes` is false (it is indexed) , may have at most
1500 bytes. Otherwise, may be set to at most 1,000,000 bytes.

=item * C<< $msg->blob_value() >> / C<< $msg->blob_value($value) >>

Type: C<Bytes>

A blob value.
May have at most 1,000,000 bytes.
When `exclude_from_indexes` is false, may have at most 1500 bytes.
In JSON requests, must be base64-encoded.

=item * C<< $msg->geo_point_value() >> / C<< $msg->geo_point_value($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

A geo point value representing a point on the surface of Earth.

=item * C<< $msg->entity_value() >> / C<< $msg->entity_value($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::Entity>)

An entity value.

- May have no key.
- May have a key with an incomplete key path.
- May have a reserved/read-only key.

=item * C<< $msg->array_value() >> / C<< $msg->array_value($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::ArrayValue>)

An array value.
Cannot contain another array value.
A `Value` instance that sets field `array_value` must not set fields
`meaning` or `exclude_from_indexes`.

=item * C<< $msg->meaning() >> / C<< $msg->meaning($value) >>

Type: C<Int32>

The `meaning` field should only be populated for backwards compatibility.

=item * C<< $msg->exclude_from_indexes() >> / C<< $msg->exclude_from_indexes($value) >>

Type: C<Bool>

If the value should be excluded from all indexes including those defined
explicitly.

=back

=head2 Google::Datastore::V1::Entity::Entity

A Datastore data object.

Must not exceed 1 MiB - 4 bytes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::Key>)

The entity's key.

An entity must have a key, unless otherwise documented (for example,
an entity in `Value.entity_value` may have no key).
An entity's kind is its key path's last element's kind,
or null if it has no key.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Datastore::V1::Entity::Entity::PropertiesEntry>)

The entity's properties.
The map's keys are property names.
A property name matching regex `__.*__` is reserved.
A reserved property name is forbidden in certain documented contexts.
The map keys, represented as UTF-8, must not exceed 1,500 bytes and cannot
be empty.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::V1::Entity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
