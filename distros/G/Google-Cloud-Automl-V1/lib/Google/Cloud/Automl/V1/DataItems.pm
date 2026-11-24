package Google::Cloud::Automl::V1::DataItems;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1::Geometry };
    eval { require Google::Cloud::Automl::V1::Io };
    eval { require Google::Cloud::Automl::V1::TextSegment };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXV0b21sL3YxL2RhdGFfaXRlbXMucHJvdG8SFmdvb2dsZS5jbG91
ZC5hdXRvbWwudjEaJWdvb2dsZS9jbG91ZC9hdXRvbWwvdjEvZ2VvbWV0cnkucHJvdG8aH2dv
b2dsZS9jbG91ZC9hdXRvbWwvdjEvaW8ucHJvdG8aKWdvb2dsZS9jbG91ZC9hdXRvbWwvdjEv
dGV4dF9zZWdtZW50LnByb3RvIlcKBUltYWdlEiEKC2ltYWdlX2J5dGVzGAEgASgMSABSCmlt
YWdlQnl0ZXMSIwoNdGh1bWJuYWlsX3VyaRgEIAEoCVIMdGh1bWJuYWlsVXJpQgYKBGRhdGEi
ZQoLVGV4dFNuaXBwZXQSGAoHY29udGVudBgBIAEoCVIHY29udGVudBIbCgltaW1lX3R5cGUY
AiABKAlSCG1pbWVUeXBlEh8KC2NvbnRlbnRfdXJpGAQgASgJUgpjb250ZW50VXJpIv8BChJE
b2N1bWVudERpbWVuc2lvbnMSVAoEdW5pdBgBIAEoDjJALmdvb2dsZS5jbG91ZC5hdXRvbWwu
djEuRG9jdW1lbnREaW1lbnNpb25zLkRvY3VtZW50RGltZW5zaW9uVW5pdFIEdW5pdBIUCgV3
aWR0aBgCIAEoAlIFd2lkdGgSFgoGaGVpZ2h0GAMgASgCUgZoZWlnaHQiZQoVRG9jdW1lbnRE
aW1lbnNpb25Vbml0EicKI0RPQ1VNRU5UX0RJTUVOU0lPTl9VTklUX1VOU1BFQ0lGSUVEEAAS
CAoESU5DSBABEg4KCkNFTlRJTUVURVIQAhIJCgVQT0lOVBADItAGCghEb2N1bWVudBJOCgxp
bnB1dF9jb25maWcYASABKAsyKy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLkRvY3VtZW50SW5w
dXRDb25maWdSC2lucHV0Q29uZmlnEkgKDWRvY3VtZW50X3RleHQYAiABKAsyIy5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxLlRleHRTbmlwcGV0Ugxkb2N1bWVudFRleHQSPwoGbGF5b3V0GAMg
AygLMicuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5Eb2N1bWVudC5MYXlvdXRSBmxheW91dBJb
ChNkb2N1bWVudF9kaW1lbnNpb25zGAQgASgLMiouZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5E
b2N1bWVudERpbWVuc2lvbnNSEmRvY3VtZW50RGltZW5zaW9ucxIdCgpwYWdlX2NvdW50GAUg
ASgFUglwYWdlQ291bnQa7AMKBkxheW91dBJGCgx0ZXh0X3NlZ21lbnQYASABKAsyIy5nb29n
bGUuY2xvdWQuYXV0b21sLnYxLlRleHRTZWdtZW50Ugt0ZXh0U2VnbWVudBIfCgtwYWdlX251
bWJlchgCIAEoBVIKcGFnZU51bWJlchJJCg1ib3VuZGluZ19wb2x5GAMgASgLMiQuZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MS5Cb3VuZGluZ1BvbHlSDGJvdW5kaW5nUG9seRJjChF0ZXh0X3Nl
Z21lbnRfdHlwZRgEIAEoDjI3Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuRG9jdW1lbnQuTGF5
b3V0LlRleHRTZWdtZW50VHlwZVIPdGV4dFNlZ21lbnRUeXBlIsgBCg9UZXh0U2VnbWVudFR5
cGUSIQodVEVYVF9TRUdNRU5UX1RZUEVfVU5TUEVDSUZJRUQQABIJCgVUT0tFThABEg0KCVBB
UkFHUkFQSBACEg4KCkZPUk1fRklFTEQQAxITCg9GT1JNX0ZJRUxEX05BTUUQBBIXChNGT1JN
X0ZJRUxEX0NPTlRFTlRTEAUSCQoFVEFCTEUQBhIQCgxUQUJMRV9IRUFERVIQBxINCglUQUJM
RV9ST1cQCBIOCgpUQUJMRV9DRUxMEAki3AEKDkV4YW1wbGVQYXlsb2FkEjUKBWltYWdlGAEg
ASgLMh0uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5JbWFnZUgAUgVpbWFnZRJICgx0ZXh0X3Nu
aXBwZXQYAiABKAsyIy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRleHRTbmlwcGV0SABSC3Rl
eHRTbmlwcGV0Ej4KCGRvY3VtZW50GAQgASgLMiAuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5E
b2N1bWVudEgAUghkb2N1bWVudEIJCgdwYXlsb2FkQqABChpjb20uZ29vZ2xlLmNsb3VkLmF1
dG9tbC52MVABWjJjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MS9hdXRvbWxwYjth
dXRvbWxwYqoCFkdvb2dsZS5DbG91ZC5BdXRvTUwuVjHKAhZHb29nbGVcQ2xvdWRcQXV0b01s
XFYx6gIZR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMUq7NQoHEgUOALoBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAvCgkKAgMBEgMT
ACkKCQoCAwISAxQAMwoICgEIEgMWADMKCQoCCCUSAxYAMwoICgEIEgMXAEkKCQoCCAsSAxcA
SQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADMKCQoCCAESAxkAMwoICgEIEgMaADMK
CQoCCCkSAxoAMwoICgEIEgMbADIKCQoCCC0SAxsAMgpaCgIEABIEHwArARpOIEEgcmVwcmVz
ZW50YXRpb24gb2YgYW4gaW1hZ2UuCiBPbmx5IGltYWdlcyB1cCB0byAzME1CIGluIHNpemUg
YXJlIHN1cHBvcnRlZC4KCgoKAwQAARIDHwgNCpYBCgQEAAgAEgQiAicDGocBIElucHV0IG9u
bHkuIFRoZSBkYXRhIHJlcHJlc2VudGluZyB0aGUgaW1hZ2UuCiBGb3IgUHJlZGljdCBjYWxs
cyBbaW1hZ2VfYnl0ZXNdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjEuSW1hZ2UuaW1hZ2VfYnl0
ZXNdIG11c3QgYmUgc2V0IC4KCgwKBQQACAABEgMiCAwKuwEKBAQAAgASAyYEGhqtASBJbWFn
ZSBjb250ZW50IHJlcHJlc2VudGVkIGFzIGEgc3RyZWFtIG9mIGJ5dGVzLgogTm90ZTogQXMg
d2l0aCBhbGwgYGJ5dGVzYCBmaWVsZHMsIHByb3RvYnVmZmVycyB1c2UgYSBwdXJlIGJpbmFy
eQogcmVwcmVzZW50YXRpb24sIHdoZXJlYXMgSlNPTiByZXByZXNlbnRhdGlvbnMgdXNlIGJh
c2U2NC4KCgwKBQQAAgAFEgMmBAkKDAoFBAACAAESAyYKFQoMCgUEAAIAAxIDJhgZCjwKBAQA
AgESAyoCGxovIE91dHB1dCBvbmx5LiBIVFRQIFVSSSB0byB0aGUgdGh1bWJuYWlsIGltYWdl
LgoKDAoFBAACAQUSAyoCCAoMCgUEAAIBARIDKgkWCgwKBQQAAgEDEgMqGRoKMQoCBAESBC4A
OgEaJSBBIHJlcHJlc2VudGF0aW9uIG9mIGEgdGV4dCBzbmlwcGV0LgoKCgoDBAEBEgMuCBMK
ZAoEBAECABIDMQIVGlcgUmVxdWlyZWQuIFRoZSBjb250ZW50IG9mIHRoZSB0ZXh0IHNuaXBw
ZXQgYXMgYSBzdHJpbmcuIFVwIHRvIDI1MDAwMAogY2hhcmFjdGVycyBsb25nLgoKDAoFBAEC
AAUSAzECCAoMCgUEAQIAARIDMQkQCgwKBQQBAgADEgMxExQKswIKBAQBAgESAzYCFxqlAiBP
cHRpb25hbC4gVGhlIGZvcm1hdCBvZiBbY29udGVudF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MS5UZXh0U25pcHBldC5jb250ZW50XS4gQ3VycmVudGx5IHRoZSBvbmx5IHR3byBhbGxvd2Vk
CiB2YWx1ZXMgYXJlICJ0ZXh0L2h0bWwiIGFuZCAidGV4dC9wbGFpbiIuIElmIGxlZnQgYmxh
bmssIHRoZSBmb3JtYXQgaXMKIGF1dG9tYXRpY2FsbHkgZGV0ZXJtaW5lZCBmcm9tIHRoZSB0
eXBlIG9mIHRoZSB1cGxvYWRlZCBbY29udGVudF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5U
ZXh0U25pcHBldC5jb250ZW50XS4KCgwKBQQBAgEFEgM2AggKDAoFBAECAQESAzYJEgoMCgUE
AQIBAxIDNhUWCkgKBAQBAgISAzkCGRo7IE91dHB1dCBvbmx5LiBIVFRQIFVSSSB3aGVyZSB5
b3UgY2FuIGRvd25sb2FkIHRoZSBjb250ZW50LgoKDAoFBAECAgUSAzkCCAoMCgUEAQICARID
OQkUCgwKBQQBAgIDEgM5FxgKPQoCBAISBD0AVQEaMSBNZXNzYWdlIHRoYXQgZGVzY3JpYmVz
IGRpbWVuc2lvbiBvZiBhIGRvY3VtZW50LgoKCgoDBAIBEgM9CBoKLwoEBAIEABIEPwJLAxoh
IFVuaXQgb2YgdGhlIGRvY3VtZW50IGRpbWVuc2lvbi4KCgwKBQQCBAABEgM/BxwKJAoGBAIE
AAIAEgNBBCwaFSBTaG91bGQgbm90IGJlIHVzZWQuCgoOCgcEAgQAAgABEgNBBCcKDgoHBAIE
AAIAAhIDQSorCjoKBgQCBAACARIDRAQNGisgRG9jdW1lbnQgZGltZW5zaW9uIGlzIG1lYXN1
cmVkIGluIGluY2hlcy4KCg4KBwQCBAACAQESA0QECAoOCgcEAgQAAgECEgNECwwKPwoGBAIE
AAICEgNHBBMaMCBEb2N1bWVudCBkaW1lbnNpb24gaXMgbWVhc3VyZWQgaW4gY2VudGltZXRl
cnMuCgoOCgcEAgQAAgIBEgNHBA4KDgoHBAIEAAICAhIDRxESCk4KBgQCBAACAxIDSgQOGj8g
RG9jdW1lbnQgZGltZW5zaW9uIGlzIG1lYXN1cmVkIGluIHBvaW50cy4gNzIgcG9pbnRzID0g
MSBpbmNoLgoKDgoHBAIEAAIDARIDSgQJCg4KBwQCBAACAwISA0oMDQolCgQEAgIAEgNOAiEa
GCBVbml0IG9mIHRoZSBkaW1lbnNpb24uCgoMCgUEAgIABhIDTgIXCgwKBQQCAgABEgNOGBwK
DAoFBAICAAMSA04fIApJCgQEAgIBEgNRAhIaPCBXaWR0aCB2YWx1ZSBvZiB0aGUgZG9jdW1l
bnQsIHdvcmtzIHRvZ2V0aGVyIHdpdGggdGhlIHVuaXQuCgoMCgUEAgIBBRIDUQIHCgwKBQQC
AgEBEgNRCA0KDAoFBAICAQMSA1EQEQpKCgQEAgICEgNUAhMaPSBIZWlnaHQgdmFsdWUgb2Yg
dGhlIGRvY3VtZW50LCB3b3JrcyB0b2dldGhlciB3aXRoIHRoZSB1bml0LgoKDAoFBAICAgUS
A1QCBwoMCgUEAgICARIDVAgOCgwKBQQCAgIDEgNUERIKNQoCBAMSBVgAqwEBGiggQSBzdHJ1
Y3R1cmVkIHRleHQgZG9jdW1lbnQgZS5nLiBhIFBERi4KCgoKAwQDARIDWAgQCosBCgQEAwMA
EgVaApoBAxp8IERlc2NyaWJlcyB0aGUgbGF5b3V0IGluZm9ybWF0aW9uIG9mIGEgW3RleHRf
c2VnbWVudF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5Eb2N1bWVudC5MYXlvdXQudGV4dF9z
ZWdtZW50XSBpbiB0aGUgZG9jdW1lbnQuCgoMCgUEAwMAARIDWgoQClMKBgQDAwAEABIFXASE
AQUaQiBUaGUgdHlwZSBvZiBUZXh0U2VnbWVudCBpbiB0aGUgY29udGV4dCBvZiB0aGUgb3Jp
Z2luYWwgZG9jdW1lbnQuCgoOCgcEAwMABAABEgNcCRgKJgoIBAMDAAQAAgASA14GKBoVIFNo
b3VsZCBub3QgYmUgdXNlZC4KChAKCQQDAwAEAAIAARIDXgYjChAKCQQDAwAEAAIAAhIDXiYn
CjoKCAQDAwAEAAIBEgNhBhAaKSBUaGUgdGV4dCBzZWdtZW50IGlzIGEgdG9rZW4uIGUuZy4g
d29yZC4KChAKCQQDAwAEAAIBARIDYQYLChAKCQQDAwAEAAIBAhIDYQ4PCjMKCAQDAwAEAAIC
EgNkBhQaIiBUaGUgdGV4dCBzZWdtZW50IGlzIGEgcGFyYWdyYXBoLgoKEAoJBAMDAAQAAgIB
EgNkBg8KEAoJBAMDAAQAAgICEgNkEhMKNAoIBAMDAAQAAgMSA2cGFRojIFRoZSB0ZXh0IHNl
Z21lbnQgaXMgYSBmb3JtIGZpZWxkLgoKEAoJBAMDAAQAAgMBEgNnBhAKEAoJBAMDAAQAAgMC
EgNnExQKygEKCAQDAwAEAAIEEgNsBhoauAEgVGhlIHRleHQgc2VnbWVudCBpcyB0aGUgbmFt
ZSBwYXJ0IG9mIGEgZm9ybSBmaWVsZC4gSXQgd2lsbCBiZSB0cmVhdGVkCiBhcyBjaGlsZCBv
ZiBhbm90aGVyIEZPUk1fRklFTEQgVGV4dFNlZ21lbnQgaWYgaXRzIHNwYW4gaXMgc3Vic3Bh
biBvZgogYW5vdGhlciBUZXh0U2VnbWVudCB3aXRoIHR5cGUgRk9STV9GSUVMRC4KChAKCQQD
AwAEAAIEARIDbAYVChAKCQQDAwAEAAIEAhIDbBgZCtIBCggEAwMABAACBRIDcQYeGsABIFRo
ZSB0ZXh0IHNlZ21lbnQgaXMgdGhlIHRleHQgY29udGVudCBwYXJ0IG9mIGEgZm9ybSBmaWVs
ZC4gSXQgd2lsbCBiZQogdHJlYXRlZCBhcyBjaGlsZCBvZiBhbm90aGVyIEZPUk1fRklFTEQg
VGV4dFNlZ21lbnQgaWYgaXRzIHNwYW4gaXMKIHN1YnNwYW4gb2YgYW5vdGhlciBUZXh0U2Vn
bWVudCB3aXRoIHR5cGUgRk9STV9GSUVMRC4KChAKCQQDAwAEAAIFARIDcQYZChAKCQQDAwAE
AAIFAhIDcRwdClYKCAQDAwAEAAIGEgN0BhAaRSBUaGUgdGV4dCBzZWdtZW50IGlzIGEgd2hv
bGUgdGFibGUsIGluY2x1ZGluZyBoZWFkZXJzLCBhbmQgYWxsIHJvd3MuCgoQCgkEAwMABAAC
BgESA3QGCwoQCgkEAwMABAACBgISA3QODwq0AQoIBAMDAAQAAgcSA3kGFxqiASBUaGUgdGV4
dCBzZWdtZW50IGlzIGEgdGFibGUncyBoZWFkZXJzLiBJdCB3aWxsIGJlIHRyZWF0ZWQgYXMg
Y2hpbGQgb2YKIGFub3RoZXIgVEFCTEUgVGV4dFNlZ21lbnQgaWYgaXRzIHNwYW4gaXMgc3Vi
c3BhbiBvZiBhbm90aGVyIFRleHRTZWdtZW50CiB3aXRoIHR5cGUgVEFCTEUuCgoQCgkEAwMA
BAACBwESA3kGEgoQCgkEAwMABAACBwISA3kVFgqxAQoIBAMDAAQAAggSA34GFBqfASBUaGUg
dGV4dCBzZWdtZW50IGlzIGEgcm93IGluIHRhYmxlLiBJdCB3aWxsIGJlIHRyZWF0ZWQgYXMg
Y2hpbGQgb2YKIGFub3RoZXIgVEFCTEUgVGV4dFNlZ21lbnQgaWYgaXRzIHNwYW4gaXMgc3Vi
c3BhbiBvZiBhbm90aGVyIFRleHRTZWdtZW50CiB3aXRoIHR5cGUgVEFCTEUuCgoQCgkEAwMA
BAACCAESA34GDwoQCgkEAwMABAACCAISA34SEwq7AQoIBAMDAAQAAgkSBIMBBhUaqAEgVGhl
IHRleHQgc2VnbWVudCBpcyBhIGNlbGwgaW4gdGFibGUuIEl0IHdpbGwgYmUgdHJlYXRlZCBh
cyBjaGlsZCBvZgogYW5vdGhlciBUQUJMRV9ST1cgVGV4dFNlZ21lbnQgaWYgaXRzIHNwYW4g
aXMgc3Vic3BhbiBvZiBhbm90aGVyCiBUZXh0U2VnbWVudCB3aXRoIHR5cGUgVEFCTEVfUk9X
LgoKEQoJBAMDAAQAAgkBEgSDAQYQChEKCQQDAwAEAAIJAhIEgwETFAqCAQoGBAMDAAIAEgSI
AQQhGnIgVGV4dCBTZWdtZW50IHRoYXQgcmVwcmVzZW50cyBhIHNlZ21lbnQgaW4KIFtkb2N1
bWVudF90ZXh0XVtnb29nbGUuY2xvdWQuYXV0b21sLnYxcDFiZXRhLkRvY3VtZW50LmRvY3Vt
ZW50X3RleHRdLgoKDwoHBAMDAAIABhIEiAEEDwoPCgcEAwMAAgABEgSIARAcCg8KBwQDAwAC
AAMSBIgBHyAKkwEKBgQDAwACARIEjAEEGhqCASBQYWdlIG51bWJlciBvZiB0aGUgW3RleHRf
c2VnbWVudF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5Eb2N1bWVudC5MYXlvdXQudGV4dF9z
ZWdtZW50XSBpbiB0aGUgb3JpZ2luYWwgZG9jdW1lbnQsIHN0YXJ0cwogZnJvbSAxLgoKDwoH
BAMDAAIBBRIEjAEECQoPCgcEAwMAAgEBEgSMAQoVCg8KBwQDAwACAQMSBIwBGBkK6QMKBgQD
AwACAhIElgEEIxrYAyBUaGUgcG9zaXRpb24gb2YgdGhlIFt0ZXh0X3NlZ21lbnRdW2dvb2ds
ZS5jbG91ZC5hdXRvbWwudjEuRG9jdW1lbnQuTGF5b3V0LnRleHRfc2VnbWVudF0gaW4gdGhl
IHBhZ2UuCiBDb250YWlucyBleGFjdGx5IDQKIFtub3JtYWxpemVkX3ZlcnRpY2VzXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxcDFiZXRhLkJvdW5kaW5nUG9seS5ub3JtYWxpemVkX3ZlcnRp
Y2VzXQogYW5kIHRoZXkgYXJlIGNvbm5lY3RlZCBieSBlZGdlcyBpbiB0aGUgb3JkZXIgcHJv
dmlkZWQsIHdoaWNoIHdpbGwKIHJlcHJlc2VudCBhIHJlY3RhbmdsZSBwYXJhbGxlbCB0byB0
aGUgZnJhbWUuIFRoZQogW05vcm1hbGl6ZWRWZXJ0ZXgtc11bZ29vZ2xlLmNsb3VkLmF1dG9t
bC52MXAxYmV0YS5Ob3JtYWxpemVkVmVydGV4XSBhcmUKIHJlbGF0aXZlIHRvIHRoZSBwYWdl
LgogQ29vcmRpbmF0ZXMgYXJlIGJhc2VkIG9uIHRvcC1sZWZ0IGFzIHBvaW50ICgwLDApLgoK
DwoHBAMDAAICBhIElgEEEAoPCgcEAwMAAgIBEgSWAREeCg8KBwQDAwACAgMSBJYBISIKcgoG
BAMDAAIDEgSZAQQqGmIgVGhlIHR5cGUgb2YgdGhlIFt0ZXh0X3NlZ21lbnRdW2dvb2dsZS5j
bG91ZC5hdXRvbWwudjEuRG9jdW1lbnQuTGF5b3V0LnRleHRfc2VnbWVudF0gaW4gZG9jdW1l
bnQuCgoPCgcEAwMAAgMGEgSZAQQTCg8KBwQDAwACAwESBJkBFCUKDwoHBAMDAAIDAxIEmQEo
KQpHCgQEAwIAEgSdAQInGjkgQW4gaW5wdXQgY29uZmlnIHNwZWNpZnlpbmcgdGhlIGNvbnRl
bnQgb2YgdGhlIGRvY3VtZW50LgoKDQoFBAMCAAYSBJ0BAhUKDQoFBAMCAAESBJ0BFiIKDQoF
BAMCAAMSBJ0BJSYKOAoEBAMCARIEoAECIBoqIFRoZSBwbGFpbiB0ZXh0IHZlcnNpb24gb2Yg
dGhpcyBkb2N1bWVudC4KCg0KBQQDAgEGEgSgAQINCg0KBQQDAgEBEgSgAQ4bCg0KBQQDAgED
EgSgAR4fClEKBAQDAgISBKQBAh0aQyBEZXNjcmliZXMgdGhlIGxheW91dCBvZiB0aGUgZG9j
dW1lbnQuCiBTb3J0ZWQgYnkgW3BhZ2VfbnVtYmVyXVtdLgoKDQoFBAMCAgQSBKQBAgoKDQoF
BAMCAgYSBKQBCxEKDQoFBAMCAgESBKQBEhgKDQoFBAMCAgMSBKQBGxwKOwoEBAMCAxIEpwEC
LRotIFRoZSBkaW1lbnNpb25zIG9mIHRoZSBwYWdlIGluIHRoZSBkb2N1bWVudC4KCg0KBQQD
AgMGEgSnAQIUCg0KBQQDAgMBEgSnARUoCg0KBQQDAgMDEgSnASssCjAKBAQDAgQSBKoBAhca
IiBOdW1iZXIgb2YgcGFnZXMgaW4gdGhlIGRvY3VtZW50LgoKDQoFBAMCBAUSBKoBAgcKDQoF
BAMCBAESBKoBCBIKDQoFBAMCBAMSBKoBFRYKPQoCBAQSBq4BALoBARovIEV4YW1wbGUgZGF0
YSB1c2VkIGZvciB0cmFpbmluZyBvciBwcmVkaWN0aW9uLgoKCwoDBAQBEgSuAQgWCi0KBAQE
CAASBrABArkBAxodIFJlcXVpcmVkLiBUaGUgZXhhbXBsZSBkYXRhLgoKDQoFBAQIAAESBLAB
CA8KHgoEBAQCABIEsgEEFBoQIEV4YW1wbGUgaW1hZ2UuCgoNCgUEBAIABhIEsgEECQoNCgUE
BAIAARIEsgEKDwoNCgUEBAIAAxIEsgESEwodCgQEBAIBEgS1AQQhGg8gRXhhbXBsZSB0ZXh0
LgoKDQoFBAQCAQYSBLUBBA8KDQoFBAQCAQESBLUBEBwKDQoFBAQCAQMSBLUBHyAKIQoEBAQC
AhIEuAEEGhoTIEV4YW1wbGUgZG9jdW1lbnQuCgoNCgUEBAICBhIEuAEEDAoNCgUEBAICARIE
uAENFQoNCgUEBAICAxIEuAEYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::DataItems::Image ===
    # Fields for Image
    # Field: image_bytes Type: 12 ()
    # Field: thumbnail_uri Type: 9 ()

# === Message: Google::Cloud::Automl::V1::DataItems::TextSnippet ===
    # Fields for TextSnippet
    # Field: content Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: content_uri Type: 9 ()

# === Message: Google::Cloud::Automl::V1::DataItems::DocumentDimensions ===
    # Fields for DocumentDimensions
    # Field: unit Type: 14 (.google.cloud.automl.v1.DocumentDimensions.DocumentDimensionUnit)
    # Field: width Type: 2 ()
    # Field: height Type: 2 ()

# Enum: DocumentDimensions::DocumentDimensionUnit
our $DocumentDimensions_DOCUMENT_DIMENSION_UNIT_UNSPECIFIED = 0;
our $DocumentDimensions_INCH = 1;
our $DocumentDimensions_CENTIMETER = 2;
our $DocumentDimensions_POINT = 3;

# === Message: Google::Cloud::Automl::V1::DataItems::Document ===
    # Fields for Document
    # Field: input_config Type: 11 (.google.cloud.automl.v1.DocumentInputConfig)
    # Field: document_text Type: 11 (.google.cloud.automl.v1.TextSnippet)
    # Field: layout Type: 11 (.google.cloud.automl.v1.Document.Layout)
    # Field: document_dimensions Type: 11 (.google.cloud.automl.v1.DocumentDimensions)
    # Field: page_count Type: 5 ()

# === Message: Google::Cloud::Automl::V1::DataItems::ExamplePayload ===
    # Fields for ExamplePayload
    # Field: image Type: 11 (.google.cloud.automl.v1.Image)
    # Field: text_snippet Type: 11 (.google.cloud.automl.v1.TextSnippet)
    # Field: document Type: 11 (.google.cloud.automl.v1.Document)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::DataItems - Compiled Protocol Buffers messages for google/cloud/automl/v1/data_items.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::DataItems;

    my $msg = Google::Cloud::Automl::V1::DataItems::Image->new({
        image_bytes => $image_bytes,
        thumbnail_uri => $thumbnail_uri,
    });

    # Read or update a field
    my $val = $msg->image_bytes();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::DataItems::Image->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/data_items.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::DataItems::Image

A representation of an image.
Only images up to 30MB in size are supported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_bytes() >> / C<< $msg->image_bytes($value) >>

Type: C<Bytes>

Image content represented as a stream of bytes.
Note: As with all `bytes` fields, protobuffers use a pure binary
representation, whereas JSON representations use base64.

=item * C<< $msg->thumbnail_uri() >> / C<< $msg->thumbnail_uri($value) >>

Type: C<String>

Output only. HTTP URI to the thumbnail image.

=back

=head2 Google::Cloud::Automl::V1::DataItems::TextSnippet

A representation of a text snippet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Required. The content of the text snippet as a string. Up to 250000
characters long.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Optional. The format of [content][google.cloud.automl.v1.TextSnippet.content]. Currently the only two allowed
values are "text/html" and "text/plain". If left blank, the format is
automatically determined from the type of the uploaded [content][google.cloud.automl.v1.TextSnippet.content].

=item * C<< $msg->content_uri() >> / C<< $msg->content_uri($value) >>

Type: C<String>

Output only. HTTP URI where you can download the content.

=back

=head2 Google::Cloud::Automl::V1::DataItems::DocumentDimensions

Message that describes dimension of a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->unit() >> / C<< $msg->unit($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1::DocumentDimensions::DocumentDimensionUnit>)

Unit of the dimension.

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Float>

Width value of the document, works together with the unit.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Float>

Height value of the document, works together with the unit.

=back

=head3 Enum: DocumentDimensions::DocumentDimensionUnit

=over 4

=item * C<DOCUMENT_DIMENSION_UNIT_UNSPECIFIED> => C<0>

=item * C<INCH> => C<1>

=item * C<CENTIMETER> => C<2>

=item * C<POINT> => C<3>

=back

=head2 Google::Cloud::Automl::V1::DataItems::Document

A structured text document e.g. a PDF.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Io::DocumentInputConfig>)

An input config specifying the content of the document.

=item * C<< $msg->document_text() >> / C<< $msg->document_text($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::TextSnippet>)

The plain text version of this document.

=item * C<< $msg->layout() >> / C<< $msg->layout($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::Document::Layout>)

Describes the layout of the document.
Sorted by [page_number][].

=item * C<< $msg->document_dimensions() >> / C<< $msg->document_dimensions($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::DocumentDimensions>)

The dimensions of the page in the document.

=item * C<< $msg->page_count() >> / C<< $msg->page_count($value) >>

Type: C<Int32>

Number of pages in the document.

=back

=head2 Google::Cloud::Automl::V1::DataItems::ExamplePayload

Example data used for training or prediction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::Image>)

Example image.

=item * C<< $msg->text_snippet() >> / C<< $msg->text_snippet($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::TextSnippet>)

Example text.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::Document>)

Example document.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::DataItems::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
