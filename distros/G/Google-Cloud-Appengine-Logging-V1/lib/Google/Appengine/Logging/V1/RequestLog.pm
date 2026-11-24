package Google::Appengine::Logging::V1::RequestLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Logging::Type::LogSeverity };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvYXBwZW5naW5lL2xvZ2dpbmcvdjEvcmVxdWVzdF9sb2cucHJvdG8SG2dvb2ds
ZS5hcHBlbmdpbmUubG9nZ2luZy52MRomZ29vZ2xlL2xvZ2dpbmcvdHlwZS9sb2dfc2V2ZXJp
dHkucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byLuAQoHTG9nTGluZRIuCgR0aW1lGAEgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIEdGltZRI8CghzZXZlcml0eRgCIAEoDjIgLmdvb2dsZS5s
b2dnaW5nLnR5cGUuTG9nU2V2ZXJpdHlSCHNldmVyaXR5Eh8KC2xvZ19tZXNzYWdlGAMgASgJ
Ugpsb2dNZXNzYWdlElQKD3NvdXJjZV9sb2NhdGlvbhgEIAEoCzIrLmdvb2dsZS5hcHBlbmdp
bmUubG9nZ2luZy52MS5Tb3VyY2VMb2NhdGlvblIOc291cmNlTG9jYXRpb24iXQoOU291cmNl
TG9jYXRpb24SEgoEZmlsZRgBIAEoCVIEZmlsZRISCgRsaW5lGAIgASgDUgRsaW5lEiMKDWZ1
bmN0aW9uX25hbWUYAyABKAlSDGZ1bmN0aW9uTmFtZSJSCg9Tb3VyY2VSZWZlcmVuY2USHgoK
cmVwb3NpdG9yeRgBIAEoCVIKcmVwb3NpdG9yeRIfCgtyZXZpc2lvbl9pZBgCIAEoCVIKcmV2
aXNpb25JZCK7CQoKUmVxdWVzdExvZxIVCgZhcHBfaWQYASABKAlSBWFwcElkEhsKCW1vZHVs
ZV9pZBglIAEoCVIIbW9kdWxlSWQSHQoKdmVyc2lvbl9pZBgCIAEoCVIJdmVyc2lvbklkEh0K
CnJlcXVlc3RfaWQYAyABKAlSCXJlcXVlc3RJZBIOCgJpcBgEIAEoCVICaXASOQoKc3RhcnRf
dGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1Cghl
bmRfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSMwoH
bGF0ZW5jeRgIIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIHbGF0ZW5jeRIfCgtt
ZWdhX2N5Y2xlcxgJIAEoA1IKbWVnYUN5Y2xlcxIWCgZtZXRob2QYCiABKAlSBm1ldGhvZBIa
CghyZXNvdXJjZRgLIAEoCVIIcmVzb3VyY2USIQoMaHR0cF92ZXJzaW9uGAwgASgJUgtodHRw
VmVyc2lvbhIWCgZzdGF0dXMYDSABKAVSBnN0YXR1cxIjCg1yZXNwb25zZV9zaXplGA4gASgD
UgxyZXNwb25zZVNpemUSGgoIcmVmZXJyZXIYDyABKAlSCHJlZmVycmVyEh0KCnVzZXJfYWdl
bnQYECABKAlSCXVzZXJBZ2VudBIaCghuaWNrbmFtZRgoIAEoCVIIbmlja25hbWUSIgoNdXJs
X21hcF9lbnRyeRgRIAEoCVILdXJsTWFwRW50cnkSEgoEaG9zdBgUIAEoCVIEaG9zdBISCgRj
b3N0GBUgASgBUgRjb3N0EiYKD3Rhc2tfcXVldWVfbmFtZRgWIAEoCVINdGFza1F1ZXVlTmFt
ZRIbCgl0YXNrX25hbWUYFyABKAlSCHRhc2tOYW1lEi4KE3dhc19sb2FkaW5nX3JlcXVlc3QY
GCABKAhSEXdhc0xvYWRpbmdSZXF1ZXN0EjwKDHBlbmRpbmdfdGltZRgZIAEoCzIZLmdvb2ds
ZS5wcm90b2J1Zi5EdXJhdGlvblILcGVuZGluZ1RpbWUSJQoOaW5zdGFuY2VfaW5kZXgYGiAB
KAVSDWluc3RhbmNlSW5kZXgSGgoIZmluaXNoZWQYGyABKAhSCGZpbmlzaGVkEhQKBWZpcnN0
GCogASgIUgVmaXJzdBIfCgtpbnN0YW5jZV9pZBgcIAEoCVIKaW5zdGFuY2VJZBI4CgRsaW5l
GB0gAygLMiQuZ29vZ2xlLmFwcGVuZ2luZS5sb2dnaW5nLnYxLkxvZ0xpbmVSBGxpbmUSLAoS
YXBwX2VuZ2luZV9yZWxlYXNlGCYgASgJUhBhcHBFbmdpbmVSZWxlYXNlEhkKCHRyYWNlX2lk
GCcgASgJUgd0cmFjZUlkEiMKDXRyYWNlX3NhbXBsZWQYKyABKAhSDHRyYWNlU2FtcGxlZBJX
ChBzb3VyY2VfcmVmZXJlbmNlGCkgAygLMiwuZ29vZ2xlLmFwcGVuZ2luZS5sb2dnaW5nLnYx
LlNvdXJjZVJlZmVyZW5jZVIPc291cmNlUmVmZXJlbmNlQugBCh9jb20uZ29vZ2xlLmFwcGVu
Z2luZS5sb2dnaW5nLnYxQg9SZXF1ZXN0TG9nUHJvdG9QAVpCZ29vZ2xlLmdvbGFuZy5vcmcv
Z2VucHJvdG8vZ29vZ2xlYXBpcy9hcHBlbmdpbmUvbG9nZ2luZy92MTtsb2dnaW5nqgIhR29v
Z2xlLkNsb3VkLkFwcEVuZ2luZS5Mb2dnaW5nLlYxygIhR29vZ2xlXENsb3VkXEFwcEVuZ2lu
ZVxMb2dnaW5nXFYx6gIlR29vZ2xlOjpDbG91ZDo6QXBwRW5naW5lOjpMb2dnaW5nOjpWMUqZ
OQoHEgUOAMMBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
JAoJCgIDABIDEgAwCgkKAgMBEgMTACgKCQoCAwISAxQAKQoICgEIEgMWAD4KCQoCCCUSAxYA
PgoICgEIEgMXAFkKCQoCCAsSAxcAWQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAK
CQoCCAgSAxkAMAoICgEIEgMaADgKCQoCCAESAxoAOAoICgEIEgMbAD8KCQoCCCkSAxsAPwoI
CgEIEgMcAD4KCQoCCC0SAxwAPgpGCgIEABIEHwArARo6IEFwcGxpY2F0aW9uIGxvZyBsaW5l
IGVtaXR0ZWQgd2hpbGUgcHJvY2Vzc2luZyBhIHJlcXVlc3QuCgoKCgMEAAESAx8IDwo9CgQE
AAIAEgMhAiUaMCBBcHByb3hpbWF0ZSB0aW1lIHdoZW4gdGhpcyBsb2cgZW50cnkgd2FzIG1h
ZGUuCgoMCgUEAAIABhIDIQIbCgwKBQQAAgABEgMhHCAKDAoFBAACAAMSAyEjJAoqCgQEAAIB
EgMkAi8aHSBTZXZlcml0eSBvZiB0aGlzIGxvZyBlbnRyeS4KCgwKBQQAAgEGEgMkAiEKDAoF
BAACAQESAyQiKgoMCgUEAAIBAxIDJC0uCigKBAQAAgISAycCGRobIEFwcC1wcm92aWRlZCBs
b2cgbWVzc2FnZS4KCgwKBQQAAgIFEgMnAggKDAoFBAACAgESAycJFAoMCgUEAAICAxIDJxcY
CkUKBAQAAgMSAyoCJRo4IFdoZXJlIGluIHRoZSBzb3VyY2UgY29kZSB0aGlzIGxvZyBtZXNz
YWdlIHdhcyB3cml0dGVuLgoKDAoFBAACAwYSAyoCEAoMCgUEAAIDARIDKhEgCgwKBQQAAgMD
EgMqIyQKOQoCBAESBC4APQEaLSBTcGVjaWZpZXMgYSBsb2NhdGlvbiBpbiBhIHNvdXJjZSBj
b2RlIGZpbGUuCgoKCgMEAQESAy4IFgp+CgQEAQIAEgMxAhIacSBTb3VyY2UgZmlsZSBuYW1l
LiBEZXBlbmRpbmcgb24gdGhlIHJ1bnRpbWUgZW52aXJvbm1lbnQsIHRoaXMgbWlnaHQgYmUg
YQogc2ltcGxlIG5hbWUgb3IgYSBmdWxseS1xdWFsaWZpZWQgbmFtZS4KCgwKBQQBAgAFEgMx
AggKDAoFBAECAAESAzEJDQoMCgUEAQIAAxIDMRARCisKBAQBAgESAzQCERoeIExpbmUgd2l0
aGluIHRoZSBzb3VyY2UgZmlsZS4KCgwKBQQBAgEFEgM0AgcKDAoFBAECAQESAzQIDAoMCgUE
AQIBAxIDNA8QCvkCCgQEAQICEgM8Ahsa6wIgSHVtYW4tcmVhZGFibGUgbmFtZSBvZiB0aGUg
ZnVuY3Rpb24gb3IgbWV0aG9kIGJlaW5nIGludm9rZWQsIHdpdGggb3B0aW9uYWwKIGNvbnRl
eHQgc3VjaCBhcyB0aGUgY2xhc3Mgb3IgcGFja2FnZSBuYW1lLiBUaGlzIGluZm9ybWF0aW9u
IGlzIHVzZWQgaW4KIGNvbnRleHRzIHN1Y2ggYXMgdGhlIGxvZ3Mgdmlld2VyLCB3aGVyZSBh
IGZpbGUgYW5kIGxpbmUgbnVtYmVyIGFyZSBsZXNzCiBtZWFuaW5nZnVsLiBUaGUgZm9ybWF0
IGNhbiB2YXJ5IGJ5IGxhbmd1YWdlLiBGb3IgZXhhbXBsZToKIGBxdWFsLmlmLmllZC5DbGFz
cy5tZXRob2RgIChKYXZhKSwgYGRpci9wYWNrYWdlLmZ1bmNgIChHbyksIGBmdW5jdGlvbmAK
IChQeXRob24pLgoKDAoFBAECAgUSAzwCCAoMCgUEAQICARIDPAkWCgwKBQQBAgIDEgM8GRoK
bwoCBAISBEEASQEaYyBBIHJlZmVyZW5jZSB0byBhIHBhcnRpY3VsYXIgc25hcHNob3Qgb2Yg
dGhlIHNvdXJjZSB0cmVlIHVzZWQgdG8gYnVpbGQgYW5kCiBkZXBsb3kgYW4gYXBwbGljYXRp
b24uCgoKCgMEAgESA0EIFwqDAQoEBAICABIDRAIYGnYgT3B0aW9uYWwuIEEgVVJJIHN0cmlu
ZyBpZGVudGlmeWluZyB0aGUgcmVwb3NpdG9yeS4KIEV4YW1wbGU6ICJodHRwczovL2dpdGh1
Yi5jb20vR29vZ2xlQ2xvdWRQbGF0Zm9ybS9rdWJlcm5ldGVzLmdpdCIKCgwKBQQCAgAFEgNE
AggKDAoFBAICAAESA0QJEwoMCgUEAgIAAxIDRBYXCosBCgQEAgIBEgNIAhkafiBUaGUgY2Fu
b25pY2FsIGFuZCBwZXJzaXN0ZW50IGlkZW50aWZpZXIgb2YgdGhlIGRlcGxveWVkIHJldmlz
aW9uLgogRXhhbXBsZSAoZ2l0KTogIjAwMzU3ODFjNTBlYzdhYTIzMzg1ZGM4NDE1MjljZThh
NGI3MGRiMWIiCgoMCgUEAgIBBRIDSAIICgwKBQQCAgEBEgNICRQKDAoFBAICAQMSA0gXGApi
CgIEAxIFTQDDAQEaVSBDb21wbGV0ZSBsb2cgaW5mb3JtYXRpb24gYWJvdXQgYSBzaW5nbGUg
SFRUUCByZXF1ZXN0IHRvIGFuIEFwcCBFbmdpbmUKIGFwcGxpY2F0aW9uLgoKCgoDBAMBEgNN
CBIKNQoEBAMCABIDTwIUGiggQXBwbGljYXRpb24gdGhhdCBoYW5kbGVkIHRoaXMgcmVxdWVz
dC4KCgwKBQQDAgAFEgNPAggKDAoFBAMCAAESA08JDwoMCgUEAwIAAxIDTxITCkMKBAQDAgES
A1ICGBo2IE1vZHVsZSBvZiB0aGUgYXBwbGljYXRpb24gdGhhdCBoYW5kbGVkIHRoaXMgcmVx
dWVzdC4KCgwKBQQDAgEFEgNSAggKDAoFBAMCAQESA1IJEgoMCgUEAwIBAxIDUhUXCkQKBAQD
AgISA1UCGBo3IFZlcnNpb24gb2YgdGhlIGFwcGxpY2F0aW9uIHRoYXQgaGFuZGxlZCB0aGlz
IHJlcXVlc3QuCgoMCgUEAwICBRIDVQIICgwKBQQDAgIBEgNVCRMKDAoFBAMCAgMSA1UWFwri
AQoEBAMCAxIDWgIYGtQBIEdsb2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyIGZvciBhIHJlcXVl
c3QsIHdoaWNoIGlzIGJhc2VkIG9uIHRoZSByZXF1ZXN0CiBzdGFydCB0aW1lLiAgUmVxdWVz
dCBJRHMgZm9yIHJlcXVlc3RzIHdoaWNoIHN0YXJ0ZWQgbGF0ZXIgd2lsbCBjb21wYXJlCiBn
cmVhdGVyIGFzIHN0cmluZ3MgdGhhbiB0aG9zZSBmb3IgcmVxdWVzdHMgd2hpY2ggc3RhcnRl
ZCBlYXJsaWVyLgoKDAoFBAMCAwUSA1oCCAoMCgUEAwIDARIDWgkTCgwKBQQDAgMDEgNaFhcK
IQoEBAMCBBIDXQIQGhQgT3JpZ2luIElQIGFkZHJlc3MuCgoMCgUEAwIEBRIDXQIICgwKBQQD
AgQBEgNdCQsKDAoFBAMCBAMSA10ODwotCgQEAwIFEgNgAisaICBUaW1lIHdoZW4gdGhlIHJl
cXVlc3Qgc3RhcnRlZC4KCgwKBQQDAgUGEgNgAhsKDAoFBAMCBQESA2AcJgoMCgUEAwIFAxID
YCkqCi4KBAQDAgYSA2MCKRohIFRpbWUgd2hlbiB0aGUgcmVxdWVzdCBmaW5pc2hlZC4KCgwK
BQQDAgYGEgNjAhsKDAoFBAMCBgESA2McJAoMCgUEAwIGAxIDYycoCiYKBAQDAgcSA2YCJxoZ
IExhdGVuY3kgb2YgdGhlIHJlcXVlc3QuCgoMCgUEAwIHBhIDZgIaCgwKBQQDAgcBEgNmGyIK
DAoFBAMCBwMSA2YlJgpACgQEAwIIEgNpAhgaMyBOdW1iZXIgb2YgQ1BVIG1lZ2FjeWNsZXMg
dXNlZCB0byBwcm9jZXNzIHJlcXVlc3QuCgoMCgUEAwIIBRIDaQIHCgwKBQQDAggBEgNpCBMK
DAoFBAMCCAMSA2kWFwpZCgQEAwIJEgNsAhUaTCBSZXF1ZXN0IG1ldGhvZC4gRXhhbXBsZTog
YCJHRVQiYCwgYCJIRUFEImAsIGAiUFVUImAsIGAiUE9TVCJgLCBgIkRFTEVURSJgLgoKDAoF
BAMCCQUSA2wCCAoMCgUEAwIJARIDbAkPCgwKBQQDAgkDEgNsEhQKkAIKBAQDAgoSA3ICFxqC
AiBDb250YWlucyB0aGUgcGF0aCBhbmQgcXVlcnkgcG9ydGlvbiBvZiB0aGUgVVJMIHRoYXQg
d2FzIHJlcXVlc3RlZC4gRm9yCiBleGFtcGxlLCBpZiB0aGUgVVJMIHdhcyAiaHR0cDovL2V4
YW1wbGUuY29tL2FwcD9uYW1lPXZhbCIsIHRoZSByZXNvdXJjZQogd291bGQgYmUgIi9hcHA/
bmFtZT12YWwiLiAgVGhlIGZyYWdtZW50IGlkZW50aWZpZXIsIHdoaWNoIGlzIGlkZW50aWZp
ZWQgYnkKIHRoZSBgI2AgY2hhcmFjdGVyLCBpcyBub3QgaW5jbHVkZWQuCgoMCgUEAwIKBRID
cgIICgwKBQQDAgoBEgNyCREKDAoFBAMCCgMSA3IUFgo+CgQEAwILEgN1AhsaMSBIVFRQIHZl
cnNpb24gb2YgcmVxdWVzdC4gRXhhbXBsZTogYCJIVFRQLzEuMSJgLgoKDAoFBAMCCwUSA3UC
CAoMCgUEAwILARIDdQkVCgwKBQQDAgsDEgN1GBoKPAoEBAMCDBIDeAIUGi8gSFRUUCByZXNw
b25zZSBzdGF0dXMgY29kZS4gRXhhbXBsZTogMjAwLCA0MDQuCgoMCgUEAwIMBRIDeAIHCgwK
BQQDAgwBEgN4CA4KDAoFBAMCDAMSA3gREwo8CgQEAwINEgN7AhsaLyBTaXplIGluIGJ5dGVz
IHNlbnQgYmFjayB0byBjbGllbnQgYnkgcmVxdWVzdC4KCgwKBQQDAg0FEgN7AgcKDAoFBAMC
DQESA3sIFQoMCgUEAwINAxIDexgaCicKBAQDAg4SA34CFxoaIFJlZmVycmVyIFVSTCBvZiBy
ZXF1ZXN0LgoKDAoFBAMCDgUSA34CCAoMCgUEAwIOARIDfgkRCgwKBQQDAg4DEgN+FBYKMQoE
BAMCDxIEgQECGRojIFVzZXIgYWdlbnQgdGhhdCBtYWRlIHRoZSByZXF1ZXN0LgoKDQoFBAMC
DwUSBIEBAggKDQoFBAMCDwESBIEBCRMKDQoFBAMCDwMSBIEBFhgKjgMKBAQDAhASBIsBAhca
/wIgVGhlIGxvZ2dlZC1pbiB1c2VyIHdobyBtYWRlIHRoZSByZXF1ZXN0LgoKIE1vc3QgbGlr
ZWx5LCB0aGlzIGlzIHRoZSBwYXJ0IG9mIHRoZSB1c2VyJ3MgZW1haWwgYmVmb3JlIHRoZSBg
QGAgc2lnbi4gIFRoZQogZmllbGQgdmFsdWUgaXMgdGhlIHNhbWUgZm9yIGRpZmZlcmVudCBy
ZXF1ZXN0cyBmcm9tIHRoZSBzYW1lIHVzZXIsIGJ1dAogZGlmZmVyZW50IHVzZXJzIGNhbiBo
YXZlIHNpbWlsYXIgbmFtZXMuICBUaGlzIGluZm9ybWF0aW9uIGlzIGFsc28KIGF2YWlsYWJs
ZSB0byB0aGUgYXBwbGljYXRpb24gdmlhIHRoZSBBcHAgRW5naW5lIFVzZXJzIEFQSS4KCiBU
aGlzIGZpZWxkIHdpbGwgYmUgcG9wdWxhdGVkIHN0YXJ0aW5nIHdpdGggQXBwIEVuZ2luZSAx
LjkuMjEuCgoNCgUEAwIQBRIEiwECCAoNCgUEAwIQARIEiwEJEQoNCgUEAwIQAxIEiwEUFgo3
CgQEAwIREgSOAQIcGikgRmlsZSBvciBjbGFzcyB0aGF0IGhhbmRsZWQgdGhlIHJlcXVlc3Qu
CgoNCgUEAwIRBRIEjgECCAoNCgUEAwIRARIEjgEJFgoNCgUEAwIRAxIEjgEZGwpOCgQEAwIS
EgSRAQITGkAgSW50ZXJuZXQgaG9zdCBhbmQgcG9ydCBudW1iZXIgb2YgdGhlIHJlc291cmNl
IGJlaW5nIHJlcXVlc3RlZC4KCg0KBQQDAhIFEgSRAQIICg0KBQQDAhIBEgSRAQkNCg0KBQQD
AhIDEgSRARASCksKBAQDAhMSBJQBAhMaPSBBbiBpbmRpY2F0aW9uIG9mIHRoZSByZWxhdGl2
ZSBjb3N0IG9mIHNlcnZpbmcgdGhpcyByZXF1ZXN0LgoKDQoFBAMCEwUSBJQBAggKDQoFBAMC
EwESBJQBCQ0KDQoFBAMCEwMSBJQBEBIKTQoEBAMCFBIElwECHho/IFF1ZXVlIG5hbWUgb2Yg
dGhlIHJlcXVlc3QsIGluIHRoZSBjYXNlIG9mIGFuIG9mZmxpbmUgcmVxdWVzdC4KCg0KBQQD
AhQFEgSXAQIICg0KBQQDAhQBEgSXAQkYCg0KBQQDAhQDEgSXARsdCkwKBAQDAhUSBJoBAhga
PiBUYXNrIG5hbWUgb2YgdGhlIHJlcXVlc3QsIGluIHRoZSBjYXNlIG9mIGFuIG9mZmxpbmUg
cmVxdWVzdC4KCg0KBQQDAhUFEgSaAQIICg0KBQQDAhUBEgSaAQkSCg0KBQQDAhUDEgSaARUX
CkQKBAQDAhYSBJ0BAiAaNiBXaGV0aGVyIHRoaXMgd2FzIGEgbG9hZGluZyByZXF1ZXN0IGZv
ciB0aGUgaW5zdGFuY2UuCgoNCgUEAwIWBRIEnQECBgoNCgUEAwIWARIEnQEHGgoNCgUEAwIW
AxIEnQEdHwpFCgQEAwIXEgSgAQItGjcgVGltZSB0aGlzIHJlcXVlc3Qgc3BlbnQgaW4gdGhl
IHBlbmRpbmcgcmVxdWVzdCBxdWV1ZS4KCg0KBQQDAhcGEgSgAQIaCg0KBQQDAhcBEgSgARsn
Cg0KBQQDAhcDEgSgASosCqwBCgQEAwIYEgSlAQIcGp0BIElmIHRoZSBpbnN0YW5jZSBwcm9j
ZXNzaW5nIHRoaXMgcmVxdWVzdCBiZWxvbmdzIHRvIGEgbWFudWFsbHkgc2NhbGVkCiBtb2R1
bGUsIHRoZW4gdGhpcyBpcyB0aGUgMC1iYXNlZCBpbmRleCBvZiB0aGUgaW5zdGFuY2UuIE90
aGVyd2lzZSwgdGhpcwogdmFsdWUgaXMgLTEuCgoNCgUEAwIYBRIEpQECBwoNCgUEAwIYARIE
pQEIFgoNCgUEAwIYAxIEpQEZGwo7CgQEAwIZEgSoAQIVGi0gV2hldGhlciB0aGlzIHJlcXVl
c3QgaXMgZmluaXNoZWQgb3IgYWN0aXZlLgoKDQoFBAMCGQUSBKgBAgYKDQoFBAMCGQESBKgB
Bw8KDQoFBAMCGQMSBKgBEhQK1QEKBAQDAhoSBK0BAhIaxgEgV2hldGhlciB0aGlzIGlzIHRo
ZSBmaXJzdCBgUmVxdWVzdExvZ2AgZW50cnkgZm9yIHRoaXMgcmVxdWVzdC4gIElmIGFuCiBh
Y3RpdmUgcmVxdWVzdCBoYXMgc2V2ZXJhbCBgUmVxdWVzdExvZ2AgZW50cmllcyB3cml0dGVu
IHRvIFN0YWNrZHJpdmVyCiBMb2dnaW5nLCB0aGVuIHRoaXMgZmllbGQgd2lsbCBiZSBzZXQg
Zm9yIG9uZSBvZiB0aGVtLgoKDQoFBAMCGgUSBK0BAgYKDQoFBAMCGgESBK0BBwwKDQoFBAMC
GgMSBK0BDxEKSAoEBAMCGxIEsAECGho6IEFuIGlkZW50aWZpZXIgZm9yIHRoZSBpbnN0YW5j
ZSB0aGF0IGhhbmRsZWQgdGhlIHJlcXVlc3QuCgoNCgUEAwIbBRIEsAECCAoNCgUEAwIbARIE
sAEJFAoNCgUEAwIbAxIEsAEXGQpaCgQEAwIcEgSzAQIdGkwgQSBsaXN0IG9mIGxvZyBsaW5l
cyBlbWl0dGVkIGJ5IHRoZSBhcHBsaWNhdGlvbiB3aGlsZSBzZXJ2aW5nIHRoaXMgcmVxdWVz
dC4KCg0KBQQDAhwEEgSzAQIKCg0KBQQDAhwGEgSzAQsSCg0KBQQDAhwBEgSzARMXCg0KBQQD
AhwDEgSzARocCisKBAQDAh0SBLYBAiEaHSBBcHAgRW5naW5lIHJlbGVhc2UgdmVyc2lvbi4K
Cg0KBQQDAh0FEgS2AQIICg0KBQQDAh0BEgS2AQkbCg0KBQQDAh0DEgS2AR4gCj4KBAQDAh4S
BLkBAhcaMCBTdGFja2RyaXZlciBUcmFjZSBpZGVudGlmaWVyIGZvciB0aGlzIHJlcXVlc3Qu
CgoNCgUEAwIeBRIEuQECCAoNCgUEAwIeARIEuQEJEQoNCgUEAwIeAxIEuQEUFgpnCgQEAwIf
EgS9AQIaGlkgSWYgdHJ1ZSwgdGhlIHZhbHVlIGluIHRoZSAndHJhY2VfaWQnIGZpZWxkIHdh
cyBzYW1wbGVkIGZvciBzdG9yYWdlIGluIGEKIHRyYWNlIGJhY2tlbmQuCgoNCgUEAwIfBRIE
vQECBgoNCgUEAwIfARIEvQEHFAoNCgUEAwIfAxIEvQEXGQrNAQoEBAMCIBIEwgECMRq+ASBT
b3VyY2UgY29kZSBmb3IgdGhlIGFwcGxpY2F0aW9uIHRoYXQgaGFuZGxlZCB0aGlzIHJlcXVl
c3QuIFRoZXJlIGNhbiBiZQogbW9yZSB0aGFuIG9uZSBzb3VyY2UgcmVmZXJlbmNlIHBlciBk
ZXBsb3llZCBhcHBsaWNhdGlvbiBpZiBzb3VyY2UgY29kZSBpcwogZGlzdHJpYnV0ZWQgYW1v
bmcgbXVsdGlwbGUgcmVwb3NpdG9yaWVzLgoKDQoFBAMCIAQSBMIBAgoKDQoFBAMCIAYSBMIB
CxoKDQoFBAMCIAESBMIBGysKDQoFBAMCIAMSBMIBLjBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::Logging::V1::RequestLog::LogLine ===
    # Fields for LogLine
    # Field: time Type: 11 (.google.protobuf.Timestamp)
    # Field: severity Type: 14 (.google.logging.type.LogSeverity)
    # Field: log_message Type: 9 ()
    # Field: source_location Type: 11 (.google.appengine.logging.v1.SourceLocation)

# === Message: Google::Appengine::Logging::V1::RequestLog::SourceLocation ===
    # Fields for SourceLocation
    # Field: file Type: 9 ()
    # Field: line Type: 3 ()
    # Field: function_name Type: 9 ()

# === Message: Google::Appengine::Logging::V1::RequestLog::SourceReference ===
    # Fields for SourceReference
    # Field: repository Type: 9 ()
    # Field: revision_id Type: 9 ()

# === Message: Google::Appengine::Logging::V1::RequestLog::RequestLog ===
    # Fields for RequestLog
    # Field: app_id Type: 9 ()
    # Field: module_id Type: 9 ()
    # Field: version_id Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: ip Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: latency Type: 11 (.google.protobuf.Duration)
    # Field: mega_cycles Type: 3 ()
    # Field: method Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: http_version Type: 9 ()
    # Field: status Type: 5 ()
    # Field: response_size Type: 3 ()
    # Field: referrer Type: 9 ()
    # Field: user_agent Type: 9 ()
    # Field: nickname Type: 9 ()
    # Field: url_map_entry Type: 9 ()
    # Field: host Type: 9 ()
    # Field: cost Type: 1 ()
    # Field: task_queue_name Type: 9 ()
    # Field: task_name Type: 9 ()
    # Field: was_loading_request Type: 8 ()
    # Field: pending_time Type: 11 (.google.protobuf.Duration)
    # Field: instance_index Type: 5 ()
    # Field: finished Type: 8 ()
    # Field: first Type: 8 ()
    # Field: instance_id Type: 9 ()
    # Field: line Type: 11 (.google.appengine.logging.v1.LogLine)
    # Field: app_engine_release Type: 9 ()
    # Field: trace_id Type: 9 ()
    # Field: trace_sampled Type: 8 ()
    # Field: source_reference Type: 11 (.google.appengine.logging.v1.SourceReference)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::Logging::V1::RequestLog - Compiled Protocol Buffers messages for google/appengine/logging/v1/request_log.proto

=head1 SYNOPSIS

    use Google::Appengine::Logging::V1::RequestLog;

    my $msg = Google::Appengine::Logging::V1::RequestLog::LogLine->new({
        time => $time,
        severity => $severity,
        log_message => $log_message,
        source_location => $source_location,
    });

    # Read or update a field
    my $val = $msg->time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::Logging::V1::RequestLog::LogLine->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/logging/v1/request_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::Logging::V1::RequestLog::LogLine

Application log line emitted while processing a request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time() >> / C<< $msg->time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Approximate time when this log entry was made.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Logging::Type::LogSeverity>)

Severity of this log entry.

=item * C<< $msg->log_message() >> / C<< $msg->log_message($value) >>

Type: C<String>

App-provided log message.

=item * C<< $msg->source_location() >> / C<< $msg->source_location($value) >>

Type: C<Message> (L<Google::Appengine::Logging::V1::RequestLog::SourceLocation>)

Where in the source code this log message was written.

=back

=head2 Google::Appengine::Logging::V1::RequestLog::SourceLocation

Specifies a location in a source code file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<String>

Source file name. Depending on the runtime environment, this might be a
simple name or a fully-qualified name.

=item * C<< $msg->line() >> / C<< $msg->line($value) >>

Type: C<Int64>

Line within the source file.

=item * C<< $msg->function_name() >> / C<< $msg->function_name($value) >>

Type: C<String>

Human-readable name of the function or method being invoked, with optional
context such as the class or package name. This information is used in
contexts such as the logs viewer, where a file and line number are less
meaningful. The format can vary by language. For example:
`qual.if.ied.Class.method` (Java), `dir/package.func` (Go), `function`
(Python).

=back

=head2 Google::Appengine::Logging::V1::RequestLog::SourceReference

A reference to a particular snapshot of the source tree used to build and
deploy an application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<String>

Optional. A URI string identifying the repository.
Example: "https://github.com/GoogleCloudPlatform/kubernetes.git"

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

The canonical and persistent identifier of the deployed revision.
Example (git): "0035781c50ec7aa23385dc841529ce8a4b70db1b"

=back

=head2 Google::Appengine::Logging::V1::RequestLog::RequestLog

Complete log information about a single HTTP request to an App Engine
application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app_id() >> / C<< $msg->app_id($value) >>

Type: C<String>

Application that handled this request.

=item * C<< $msg->module_id() >> / C<< $msg->module_id($value) >>

Type: C<String>

Module of the application that handled this request.

=item * C<< $msg->version_id() >> / C<< $msg->version_id($value) >>

Type: C<String>

Version of the application that handled this request.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Globally unique identifier for a request, which is based on the request
start time.  Request IDs for requests which started later will compare
greater as strings than those for requests which started earlier.

=item * C<< $msg->ip() >> / C<< $msg->ip($value) >>

Type: C<String>

Origin IP address.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the request started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the request finished.

=item * C<< $msg->latency() >> / C<< $msg->latency($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Latency of the request.

=item * C<< $msg->mega_cycles() >> / C<< $msg->mega_cycles($value) >>

Type: C<Int64>

Number of CPU megacycles used to process request.

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<String>

Request method. Example: `"GET"`, `"HEAD"`, `"PUT"`, `"POST"`, `"DELETE"`.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Contains the path and query portion of the URL that was requested. For
example, if the URL was "http://example.com/app?name=val", the resource
would be "/app?name=val".  The fragment identifier, which is identified by
the `#` character, is not included.

=item * C<< $msg->http_version() >> / C<< $msg->http_version($value) >>

Type: C<String>

HTTP version of request. Example: `"HTTP/1.1"`.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Int32>

HTTP response status code. Example: 200, 404.

=item * C<< $msg->response_size() >> / C<< $msg->response_size($value) >>

Type: C<Int64>

Size in bytes sent back to client by request.

=item * C<< $msg->referrer() >> / C<< $msg->referrer($value) >>

Type: C<String>

Referrer URL of request.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<String>

User agent that made the request.

=item * C<< $msg->nickname() >> / C<< $msg->nickname($value) >>

Type: C<String>

The logged-in user who made the request.

Most likely, this is the part of the user's email before the `@` sign.  The
field value is the same for different requests from the same user, but
different users can have similar names.  This information is also
available to the application via the App Engine Users API.

This field will be populated starting with App Engine 1.9.21.

=item * C<< $msg->url_map_entry() >> / C<< $msg->url_map_entry($value) >>

Type: C<String>

File or class that handled the request.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Internet host and port number of the resource being requested.

=item * C<< $msg->cost() >> / C<< $msg->cost($value) >>

Type: C<Double>

An indication of the relative cost of serving this request.

=item * C<< $msg->task_queue_name() >> / C<< $msg->task_queue_name($value) >>

Type: C<String>

Queue name of the request, in the case of an offline request.

=item * C<< $msg->task_name() >> / C<< $msg->task_name($value) >>

Type: C<String>

Task name of the request, in the case of an offline request.

=item * C<< $msg->was_loading_request() >> / C<< $msg->was_loading_request($value) >>

Type: C<Bool>

Whether this was a loading request for the instance.

=item * C<< $msg->pending_time() >> / C<< $msg->pending_time($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time this request spent in the pending request queue.

=item * C<< $msg->instance_index() >> / C<< $msg->instance_index($value) >>

Type: C<Int32>

If the instance processing this request belongs to a manually scaled
module, then this is the 0-based index of the instance. Otherwise, this
value is -1.

=item * C<< $msg->finished() >> / C<< $msg->finished($value) >>

Type: C<Bool>

Whether this request is finished or active.

=item * C<< $msg->first() >> / C<< $msg->first($value) >>

Type: C<Bool>

Whether this is the first `RequestLog` entry for this request.  If an
active request has several `RequestLog` entries written to Stackdriver
Logging, then this field will be set for one of them.

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

An identifier for the instance that handled the request.

=item * C<< $msg->line() >> / C<< $msg->line($value) >>

Type: C<Message> (L<Google::Appengine::Logging::V1::RequestLog::LogLine>)

A list of log lines emitted by the application while serving this request.

=item * C<< $msg->app_engine_release() >> / C<< $msg->app_engine_release($value) >>

Type: C<String>

App Engine release version.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Stackdriver Trace identifier for this request.

=item * C<< $msg->trace_sampled() >> / C<< $msg->trace_sampled($value) >>

Type: C<Bool>

If true, the value in the 'trace_id' field was sampled for storage in a
trace backend.

=item * C<< $msg->source_reference() >> / C<< $msg->source_reference($value) >>

Type: C<Message> (L<Google::Appengine::Logging::V1::RequestLog::SourceReference>)

Source code for the application that handled this request. There can be
more than one source reference per deployed application if source code is
distributed among multiple repositories.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::Logging::V1::RequestLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
