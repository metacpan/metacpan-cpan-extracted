package Google::Appengine::V1beta::Certificate;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9jZXJ0aWZpY2F0ZS5wcm90bxIXZ29vZ2xlLmFw
cGVuZ2luZS52MWJldGEaH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i5wMKFUF1
dGhvcml6ZWRDZXJ0aWZpY2F0ZRISCgRuYW1lGAEgASgJUgRuYW1lEg4KAmlkGAIgASgJUgJp
ZBIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lEiEKDGRvbWFpbl9uYW1lcxgE
IAMoCVILZG9tYWluTmFtZXMSOwoLZXhwaXJlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgpleHBpcmVUaW1lEl0KFGNlcnRpZmljYXRlX3Jhd19kYXRhGAYgASgL
MisuZ29vZ2xlLmFwcGVuZ2luZS52MWJldGEuQ2VydGlmaWNhdGVSYXdEYXRhUhJjZXJ0aWZp
Y2F0ZVJhd0RhdGESXAoTbWFuYWdlZF9jZXJ0aWZpY2F0ZRgHIAEoCzIrLmdvb2dsZS5hcHBl
bmdpbmUudjFiZXRhLk1hbmFnZWRDZXJ0aWZpY2F0ZVISbWFuYWdlZENlcnRpZmljYXRlEjYK
F3Zpc2libGVfZG9tYWluX21hcHBpbmdzGAggAygJUhV2aXNpYmxlRG9tYWluTWFwcGluZ3MS
MgoVZG9tYWluX21hcHBpbmdzX2NvdW50GAkgASgFUhNkb21haW5NYXBwaW5nc0NvdW50ImQK
EkNlcnRpZmljYXRlUmF3RGF0YRItChJwdWJsaWNfY2VydGlmaWNhdGUYASABKAlSEXB1Ymxp
Y0NlcnRpZmljYXRlEh8KC3ByaXZhdGVfa2V5GAIgASgJUgpwcml2YXRlS2V5Ip8BChJNYW5h
Z2VkQ2VydGlmaWNhdGUSRgoRbGFzdF9yZW5ld2FsX3RpbWUYASABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUg9sYXN0UmVuZXdhbFRpbWUSQQoGc3RhdHVzGAIgASgOMikuZ29v
Z2xlLmFwcGVuZ2luZS52MWJldGEuTWFuYWdlbWVudFN0YXR1c1IGc3RhdHVzKsYBChBNYW5h
Z2VtZW50U3RhdHVzEiEKHU1BTkFHRU1FTlRfU1RBVFVTX1VOU1BFQ0lGSUVEEAASBgoCT0sQ
ARILCgdQRU5ESU5HEAISHwobRkFJTEVEX1JFVFJZSU5HX05PVF9WSVNJQkxFEAQSFAoQRkFJ
TEVEX1BFUk1BTkVOVBAGEiEKHUZBSUxFRF9SRVRSWUlOR19DQUFfRk9SQklEREVOEAcSIAoc
RkFJTEVEX1JFVFJZSU5HX0NBQV9DSEVDS0lORxAIQtYBChtjb20uZ29vZ2xlLmFwcGVuZ2lu
ZS52MWJldGFCEENlcnRpZmljYXRlUHJvdG9QAVpAZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJv
dG8vZ29vZ2xlYXBpcy9hcHBlbmdpbmUvdjFiZXRhO2FwcGVuZ2luZaoCHUdvb2dsZS5DbG91
ZC5BcHBFbmdpbmUuVjFCZXRhygIdR29vZ2xlXENsb3VkXEFwcEVuZ2luZVxWMWJldGHqAiBH
b29nbGU6OkNsb3VkOjpBcHBFbmdpbmU6OlYxYmV0YUryMQoHEgUOAKsBAQq8BAoBDBIDDgAS
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
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCggKAQgSAxQA
OgoJCgIIJRIDFAA6CggKAQgSAxUAVwoJCgIICxIDFQBXCggKAQgSAxYAIgoJCgIIChIDFgAi
CggKAQgSAxcAMQoJCgIICBIDFwAxCggKAQgSAxgANAoJCgIIARIDGAA0CggKAQgSAxkAOgoJ
CgIIKRIDGQA6CggKAQgSAxoAOQoJCgIILRIDGgA5CrYBCgIEABIEHwBfARqpASBBbiBTU0wg
Y2VydGlmaWNhdGUgdGhhdCBhIHVzZXIgaGFzIGJlZW4gYXV0aG9yaXplZCB0byBhZG1pbmlz
dGVyLiBBIHVzZXIKIGlzIGF1dGhvcml6ZWQgdG8gYWRtaW5pc3RlciBhbnkgY2VydGlmaWNh
dGUgdGhhdCBhcHBsaWVzIHRvIG9uZSBvZiB0aGVpcgogYXV0aG9yaXplZCBkb21haW5zLgoK
CgoDBAABEgMfCB0KkAEKBAQAAgASAyQCEhqCASBGdWxsIHBhdGggdG8gdGhlIGBBdXRob3Jp
emVkQ2VydGlmaWNhdGVgIHJlc291cmNlIGluIHRoZSBBUEkuIEV4YW1wbGU6CiBgYXBwcy9t
eWFwcC9hdXRob3JpemVkQ2VydGlmaWNhdGVzLzEyMzQ1YC4KCiBAT3V0cHV0T25seQoKDAoF
BAACAAUSAyQCCAoMCgUEAAIAARIDJAkNCgwKBQQAAgADEgMkEBEKpQEKBAQAAgESAyoCEBqX
ASBSZWxhdGl2ZSBuYW1lIG9mIHRoZSBjZXJ0aWZpY2F0ZS4gVGhpcyBpcyBhIHVuaXF1ZSB2
YWx1ZSBhdXRvZ2VuZXJhdGVkCiBvbiBgQXV0aG9yaXplZENlcnRpZmljYXRlYCByZXNvdXJj
ZSBjcmVhdGlvbi4gRXhhbXBsZTogYDEyMzQ1YC4KCiBAT3V0cHV0T25seQoKDAoFBAACAQUS
AyoCCAoMCgUEAAIBARIDKgkLCgwKBQQAAgEDEgMqDg8KgwEKBAQAAgISAy4CGhp2IFRoZSB1
c2VyLXNwZWNpZmllZCBkaXNwbGF5IG5hbWUgb2YgdGhlIGNlcnRpZmljYXRlLiBUaGlzIGlz
IG5vdAogZ3VhcmFudGVlZCB0byBiZSB1bmlxdWUuIEV4YW1wbGU6IGBNeSBDZXJ0aWZpY2F0
ZWAuCgoMCgUEAAICBRIDLgIICgwKBQQAAgIBEgMuCRUKDAoFBAACAgMSAy4YGQqmAQoEBAAC
AxIDNAIjGpgBIFRvcG1vc3QgYXBwbGljYWJsZSBkb21haW5zIG9mIHRoaXMgY2VydGlmaWNh
dGUuIFRoaXMgY2VydGlmaWNhdGUKIGFwcGxpZXMgdG8gdGhlc2UgZG9tYWlucyBhbmQgdGhl
aXIgc3ViZG9tYWlucy4gRXhhbXBsZTogYGV4YW1wbGUuY29tYC4KCiBAT3V0cHV0T25seQoK
DAoFBAACAwQSAzQCCgoMCgUEAAIDBRIDNAsRCgwKBQQAAgMBEgM0Eh4KDAoFBAACAwMSAzQh
IgryAQoEBAACBBIDOwIsGuQBIFRoZSB0aW1lIHdoZW4gdGhpcyBjZXJ0aWZpY2F0ZSBleHBp
cmVzLiBUbyB1cGRhdGUgdGhlIHJlbmV3YWwgdGltZSBvbiB0aGlzCiBjZXJ0aWZpY2F0ZSwg
dXBsb2FkIGFuIFNTTCBjZXJ0aWZpY2F0ZSB3aXRoIGEgZGlmZmVyZW50IGV4cGlyYXRpb24g
dGltZQogdXNpbmcgW2BBdXRob3JpemVkQ2VydGlmaWNhdGVzLlVwZGF0ZUF1dGhvcml6ZWRD
ZXJ0aWZpY2F0ZWBdKCkuCgogQE91dHB1dE9ubHkKCgwKBQQAAgQGEgM7AhsKDAoFBAACBAES
AzscJwoMCgUEAAIEAxIDOyorCpQBCgQEAAIFEgM/Ai4ahgEgVGhlIFNTTCBjZXJ0aWZpY2F0
ZSBzZXJ2aW5nIHRoZSBgQXV0aG9yaXplZENlcnRpZmljYXRlYCByZXNvdXJjZS4gVGhpcwog
bXVzdCBiZSBvYnRhaW5lZCBpbmRlcGVuZGVudGx5IGZyb20gYSBjZXJ0aWZpY2F0ZSBhdXRo
b3JpdHkuCgoMCgUEAAIFBhIDPwIUCgwKBQQAAgUBEgM/FSkKDAoFBAACBQMSAz8sLQq9AgoE
BAACBhIDRwItGq8CIE9ubHkgYXBwbGljYWJsZSBpZiB0aGlzIGNlcnRpZmljYXRlIGlzIG1h
bmFnZWQgYnkgQXBwIEVuZ2luZS4gTWFuYWdlZAogY2VydGlmaWNhdGVzIGFyZSB0aWVkIHRv
IHRoZSBsaWZlY3ljbGUgb2YgYSBgRG9tYWluTWFwcGluZ2AgYW5kIGNhbm5vdCBiZQogdXBk
YXRlZCBvciBkZWxldGVkIHZpYSB0aGUgYEF1dGhvcml6ZWRDZXJ0aWZpY2F0ZXNgIEFQSS4g
SWYgdGhpcwogY2VydGlmaWNhdGUgaXMgbWFudWFsbHkgYWRtaW5pc3RlcmVkIGJ5IHRoZSB1
c2VyLCB0aGlzIGZpZWxkIHdpbGwgYmUgZW1wdHkuCgogQE91dHB1dE9ubHkKCgwKBQQAAgYG
EgNHAhQKDAoFBAACBgESA0cVKAoMCgUEAAIGAxIDRyssCv0DCgQEAAIHEgNUAi4a7wMgVGhl
IGZ1bGwgcGF0aHMgdG8gdXNlciB2aXNpYmxlIERvbWFpbiBNYXBwaW5nIHJlc291cmNlcyB0
aGF0IGhhdmUgdGhpcwogY2VydGlmaWNhdGUgbWFwcGVkLiBFeGFtcGxlOiBgYXBwcy9teWFw
cC9kb21haW5NYXBwaW5ncy9leGFtcGxlLmNvbWAuCgogVGhpcyBtYXkgbm90IHJlcHJlc2Vu
dCB0aGUgZnVsbCBsaXN0IG9mIG1hcHBlZCBkb21haW4gbWFwcGluZ3MgaWYgdGhlIHVzZXIK
IGRvZXMgbm90IGhhdmUgYFZJRVdFUmAgcGVybWlzc2lvbnMgb24gYWxsIG9mIHRoZSBhcHBs
aWNhdGlvbnMgdGhhdCBoYXZlCiB0aGlzIGNlcnRpZmljYXRlIG1hcHBlZC4gU2VlIGBkb21h
aW5fbWFwcGluZ3NfY291bnRgIGZvciBhIGNvbXBsZXRlIGNvdW50LgoKIE9ubHkgcmV0dXJu
ZWQgYnkgYEdFVGAgb3IgYExJU1RgIHJlcXVlc3RzIHdoZW4gc3BlY2lmaWNhbGx5IHJlcXVl
c3RlZCBieQogdGhlIGB2aWV3PUZVTExfQ0VSVElGSUNBVEVgIG9wdGlvbi4KCiBAT3V0cHV0
T25seQoKDAoFBAACBwQSA1QCCgoMCgUEAAIHBRIDVAsRCgwKBQQAAgcBEgNUEikKDAoFBAAC
BwMSA1QsLQq/AgoEBAACCBIDXgIiGrECIEFnZ3JlZ2F0ZSBjb3VudCBvZiB0aGUgZG9tYWlu
IG1hcHBpbmdzIHdpdGggdGhpcyBjZXJ0aWZpY2F0ZSBtYXBwZWQuIFRoaXMKIGNvdW50IGlu
Y2x1ZGVzIGRvbWFpbiBtYXBwaW5ncyBvbiBhcHBsaWNhdGlvbnMgZm9yIHdoaWNoIHRoZSB1
c2VyIGRvZXMgbm90CiBoYXZlIGBWSUVXRVJgIHBlcm1pc3Npb25zLgoKIE9ubHkgcmV0dXJu
ZWQgYnkgYEdFVGAgb3IgYExJU1RgIHJlcXVlc3RzIHdoZW4gc3BlY2lmaWNhbGx5IHJlcXVl
c3RlZCBieQogdGhlIGB2aWV3PUZVTExfQ0VSVElGSUNBVEVgIG9wdGlvbi4KCiBAT3V0cHV0
T25seQoKDAoFBAACCAUSA14CBwoMCgUEAAIIARIDXggdCgwKBQQAAggDEgNeICEKRwoCBAES
BGIAdgEaOyBBbiBTU0wgY2VydGlmaWNhdGUgb2J0YWluZWQgZnJvbSBhIGNlcnRpZmljYXRl
IGF1dGhvcml0eS4KCgoKAwQBARIDYggaCvMBCgQEAQIAEgNqAiAa5QEgUEVNIGVuY29kZWQg
eC41MDkgcHVibGljIGtleSBjZXJ0aWZpY2F0ZS4gVGhpcyBmaWVsZCBpcyBzZXQgb25jZSBv
bgogY2VydGlmaWNhdGUgY3JlYXRpb24uIE11c3QgaW5jbHVkZSB0aGUgaGVhZGVyIGFuZCBm
b290ZXIuIEV4YW1wbGU6CiA8cHJlPgogLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCiA8
Y2VydGlmaWNhdGVfdmFsdWU+CiAtLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCiA8L3ByZT4K
CgwKBQQBAgAFEgNqAggKDAoFBAECAAESA2oJGwoMCgUEAQIAAxIDah4fCscCCgQEAQIBEgN1
AhkauQIgVW5lbmNyeXB0ZWQgUEVNIGVuY29kZWQgUlNBIHByaXZhdGUga2V5LiBUaGlzIGZp
ZWxkIGlzIHNldCBvbmNlIG9uCiBjZXJ0aWZpY2F0ZSBjcmVhdGlvbiBhbmQgdGhlbiBlbmNy
eXB0ZWQuIFRoZSBrZXkgc2l6ZSBtdXN0IGJlIDIwNDgKIGJpdHMgb3IgZmV3ZXIuIE11c3Qg
aW5jbHVkZSB0aGUgaGVhZGVyIGFuZCBmb290ZXIuIEV4YW1wbGU6CiA8cHJlPgogLS0tLS1C
RUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQogPHVuZW5jcnlwdGVkX2tleV92YWx1ZT4KIC0t
LS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCiA8L3ByZT4KIEBJbnB1dE9ubHkKCgwKBQQB
AgEFEgN1AggKDAoFBAECAQESA3UJFAoMCgUEAQIBAxIDdRcYCnYKAgUAEgV6AJsBARppIFN0
YXRlIG9mIGNlcnRpZmljYXRlIG1hbmFnZW1lbnQuIFJlZmVycyB0byB0aGUgbW9zdCByZWNl
bnQgY2VydGlmaWNhdGUKIGFjcXVpc2l0aW9uIG9yIHJlbmV3YWwgYXR0ZW1wdC4KCgoKAwUA
ARIDegUVCgsKBAUAAgASA3sCJAoMCgUFAAIAARIDewIfCgwKBQUAAgACEgN7IiMKWwoEBQAC
ARIDfwIJGk4gQ2VydGlmaWNhdGUgd2FzIHN1Y2Nlc3NmdWxseSBvYnRhaW5lZCBhbmQgaW5z
ZXJ0ZWQgaW50byB0aGUgc2VydmluZwogc3lzdGVtLgoKDAoFBQACAQESA38CBAoMCgUFAAIB
AhIDfwcICkkKBAUAAgISBIIBAg4aOyBDZXJ0aWZpY2F0ZSBpcyB1bmRlciBhY3RpdmUgYXR0
ZW1wdHMgdG8gYWNxdWlyZSBvciByZW5ldy4KCg0KBQUAAgIBEgSCAQIJCg0KBQUAAgICEgSC
AQwNCoUCCgQFAAIDEgSIAQIiGvYBIE1vc3QgcmVjZW50IHJlbmV3YWwgZmFpbGVkIGR1ZSB0
byBhbiBpbnZhbGlkIEROUyBzZXR1cCBhbmQgd2lsbCBiZQogcmV0cmllZC4gUmVuZXdhbCBh
dHRlbXB0cyB3aWxsIGNvbnRpbnVlIHRvIGZhaWwgdW50aWwgdGhlIGNlcnRpZmljYXRlCiBk
b21haW4ncyBETlMgY29uZmlndXJhdGlvbiBpcyBmaXhlZC4gVGhlIGxhc3Qgc3VjY2Vzc2Z1
bGx5IHByb3Zpc2lvbmVkCiBjZXJ0aWZpY2F0ZSBtYXkgc3RpbGwgYmUgc2VydmluZy4KCg0K
BQUAAgMBEgSIAQIdCg0KBQUAAgMCEgSIASAhCl4KBAUAAgQSBIwBAhcaUCBBbGwgcmVuZXdh
bCBhdHRlbXB0cyBoYXZlIGJlZW4gZXhoYXVzdGVkLCBsaWtlbHkgZHVlIHRvIGFuIGludmFs
aWQgRE5TCiBzZXR1cC4KCg0KBQUAAgQBEgSMAQISCg0KBQUAAgQCEgSMARUWCpkCCgQFAAIF
EgSSAQIkGooCIE1vc3QgcmVjZW50IHJlbmV3YWwgZmFpbGVkIGR1ZSB0byBhbiBleHBsaWNp
dCBDQUEgcmVjb3JkIHRoYXQgZG9lcyBub3QKIGluY2x1ZGUgb25lIG9mIHRoZSBpbi11c2Ug
Q0FzIChHb29nbGUgQ0EgYW5kIExldCdzIEVuY3J5cHQpLiBSZW5ld2FscyB3aWxsCiBjb250
aW51ZSB0byBmYWlsIHVudGlsIHRoZSBDQUEgaXMgcmVjb25maWd1cmVkLiBUaGUgbGFzdCBz
dWNjZXNzZnVsbHkKIHByb3Zpc2lvbmVkIGNlcnRpZmljYXRlIG1heSBzdGlsbCBiZSBzZXJ2
aW5nLgoKDQoFBQACBQESBJIBAh8KDQoFBQACBQISBJIBIiMKlgMKBAUAAgYSBJoBAiMahwMg
TW9zdCByZWNlbnQgcmVuZXdhbCBmYWlsZWQgZHVlIHRvIGEgQ0FBIHJldHJpZXZhbCBmYWls
dXJlLiBUaGlzIG1lYW5zIHRoYXQKIHRoZSBkb21haW4ncyBETlMgcHJvdmlkZXIgZG9lcyBu
b3QgcHJvcGVybHkgaGFuZGxlIENBQSByZWNvcmRzLCBmYWlsaW5nCiByZXF1ZXN0cyBmb3Ig
Q0FBIHJlY29yZHMgd2hlbiBubyBDQUEgcmVjb3JkcyBhcmUgZGVmaW5lZC4gUmVuZXdhbHMg
d2lsbAogY29udGludWUgdG8gZmFpbCB1bnRpbCB0aGUgRE5TIHByb3ZpZGVyIGlzIGNoYW5n
ZWQgb3IgYSBDQUEgcmVjb3JkIGlzCiBhZGRlZCBmb3IgdGhlIGdpdmVuIGRvbWFpbi4gVGhl
IGxhc3Qgc3VjY2Vzc2Z1bGx5IHByb3Zpc2lvbmVkIGNlcnRpZmljYXRlCiBtYXkgc3RpbGwg
YmUgc2VydmluZy4KCg0KBQUAAgYBEgSaAQIeCg0KBQUAAgYCEgSaASEiCjQKAgQCEgaeAQCr
AQEaJiBBIGNlcnRpZmljYXRlIG1hbmFnZWQgYnkgQXBwIEVuZ2luZS4KCgsKAwQCARIEngEI
Ggr5AQoEBAICABIEpAECMhrqASBUaW1lIGF0IHdoaWNoIHRoZSBjZXJ0aWZpY2F0ZSB3YXMg
bGFzdCByZW5ld2VkLiBUaGUgcmVuZXdhbCBwcm9jZXNzIGlzCiBmdWxseSBtYW5hZ2VkLiBD
ZXJ0aWZpY2F0ZSByZW5ld2FsIHdpbGwgYXV0b21hdGljYWxseSBvY2N1ciBiZWZvcmUgdGhl
CiBjZXJ0aWZpY2F0ZSBleHBpcmVzLiBSZW5ld2FsIGVycm9ycyBjYW4gYmUgdHJhY2tlZCB2
aWEgYE1hbmFnZW1lbnRTdGF0dXNgLgoKIEBPdXRwdXRPbmx5CgoNCgUEAgIABhIEpAECGwoN
CgUEAgIAARIEpAEcLQoNCgUEAgIAAxIEpAEwMQqGAQoEBAICARIEqgECHhp4IFN0YXR1cyBv
ZiBjZXJ0aWZpY2F0ZSBtYW5hZ2VtZW50LiBSZWZlcnMgdG8gdGhlIG1vc3QgcmVjZW50IGNl
cnRpZmljYXRlCiBhY3F1aXNpdGlvbiBvciByZW5ld2FsIGF0dGVtcHQuCgogQE91dHB1dE9u
bHkKCg0KBQQCAgEGEgSqAQISCg0KBQQCAgEBEgSqARMZCg0KBQQCAgEDEgSqARwdYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Certificate::AuthorizedCertificate ===
    # Fields for AuthorizedCertificate
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: domain_names Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: certificate_raw_data Type: 11 (.google.appengine.v1beta.CertificateRawData)
    # Field: managed_certificate Type: 11 (.google.appengine.v1beta.ManagedCertificate)
    # Field: visible_domain_mappings Type: 9 ()
    # Field: domain_mappings_count Type: 5 ()

# === Message: Google::Appengine::V1beta::Certificate::CertificateRawData ===
    # Fields for CertificateRawData
    # Field: public_certificate Type: 9 ()
    # Field: private_key Type: 9 ()

# === Message: Google::Appengine::V1beta::Certificate::ManagedCertificate ===
    # Fields for ManagedCertificate
    # Field: last_renewal_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status Type: 14 (.google.appengine.v1beta.ManagementStatus)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Certificate - Compiled Protocol Buffers messages for google/appengine/v1beta/certificate.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Certificate;

    my $msg = Google::Appengine::V1beta::Certificate::AuthorizedCertificate->new({
        name => $name,
        id => $id,
        display_name => $display_name,
        domain_names => $domain_names,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Certificate::AuthorizedCertificate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/certificate.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Certificate::AuthorizedCertificate

An SSL certificate that a user has been authorized to administer. A user
is authorized to administer any certificate that applies to one of their
authorized domains.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the `AuthorizedCertificate` resource in the API. Example:
`apps/myapp/authorizedCertificates/12345`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Relative name of the certificate. This is a unique value autogenerated
on `AuthorizedCertificate` resource creation. Example: `12345`.

@OutputOnly

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The user-specified display name of the certificate. This is not
guaranteed to be unique. Example: `My Certificate`.

=item * C<< $msg->domain_names() >> / C<< $msg->domain_names($value) >>

Type: C<String>

Topmost applicable domains of this certificate. This certificate
applies to these domains and their subdomains. Example: `example.com`.

@OutputOnly

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when this certificate expires. To update the renewal time on this
certificate, upload an SSL certificate with a different expiration time
using [`AuthorizedCertificates.UpdateAuthorizedCertificate`]().

@OutputOnly

=item * C<< $msg->certificate_raw_data() >> / C<< $msg->certificate_raw_data($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Certificate::CertificateRawData>)

The SSL certificate serving the `AuthorizedCertificate` resource. This
must be obtained independently from a certificate authority.

=item * C<< $msg->managed_certificate() >> / C<< $msg->managed_certificate($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Certificate::ManagedCertificate>)

Only applicable if this certificate is managed by App Engine. Managed
certificates are tied to the lifecycle of a `DomainMapping` and cannot be
updated or deleted via the `AuthorizedCertificates` API. If this
certificate is manually administered by the user, this field will be empty.

@OutputOnly

=item * C<< $msg->visible_domain_mappings() >> / C<< $msg->visible_domain_mappings($value) >>

Type: C<String>

The full paths to user visible Domain Mapping resources that have this
certificate mapped. Example: `apps/myapp/domainMappings/example.com`.

This may not represent the full list of mapped domain mappings if the user
does not have `VIEWER` permissions on all of the applications that have
this certificate mapped. See `domain_mappings_count` for a complete count.

Only returned by `GET` or `LIST` requests when specifically requested by
the `view=FULL_CERTIFICATE` option.

@OutputOnly

=item * C<< $msg->domain_mappings_count() >> / C<< $msg->domain_mappings_count($value) >>

Type: C<Int32>

Aggregate count of the domain mappings with this certificate mapped. This
count includes domain mappings on applications for which the user does not
have `VIEWER` permissions.

Only returned by `GET` or `LIST` requests when specifically requested by
the `view=FULL_CERTIFICATE` option.

@OutputOnly

=back

=head2 Google::Appengine::V1beta::Certificate::CertificateRawData

An SSL certificate obtained from a certificate authority.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->public_certificate() >> / C<< $msg->public_certificate($value) >>

Type: C<String>

PEM encoded x.509 public key certificate. This field is set once on
certificate creation. Must include the header and footer. Example:
<pre>
-----BEGIN CERTIFICATE-----
<certificate_value>
-----END CERTIFICATE-----
</pre>

=item * C<< $msg->private_key() >> / C<< $msg->private_key($value) >>

Type: C<String>

Unencrypted PEM encoded RSA private key. This field is set once on
certificate creation and then encrypted. The key size must be 2048
bits or fewer. Must include the header and footer. Example:
<pre>
-----BEGIN RSA PRIVATE KEY-----
<unencrypted_key_value>
-----END RSA PRIVATE KEY-----
</pre>
@InputOnly

=back

=head2 Google::Appengine::V1beta::Certificate::ManagedCertificate

A certificate managed by App Engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_renewal_time() >> / C<< $msg->last_renewal_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time at which the certificate was last renewed. The renewal process is
fully managed. Certificate renewal will automatically occur before the
certificate expires. Renewal errors can be tracked via `ManagementStatus`.

@OutputOnly

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::ManagementStatus>)

Status of certificate management. Refers to the most recent certificate
acquisition or renewal attempt.

@OutputOnly

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Certificate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
