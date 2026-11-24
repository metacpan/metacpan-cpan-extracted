package Google::Cloud::Visionai::V1alpha1::StreamingResources;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvc3RyZWFtaW5nX3Jlc291cmNlcy5w
cm90bxIeZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJv
dG9idWYvZHVyYXRpb24ucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8igwIKGUdzdHJlYW1lckJ1ZmZlckRlc2Ny
aXB0b3ISHwoLY2Fwc19zdHJpbmcYASABKAlSCmNhcHNTdHJpbmcSIAoMaXNfa2V5X2ZyYW1l
GAIgASgIUgppc0tleUZyYW1lEjUKCHB0c190aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIHcHRzVGltZRI1CghkdHNfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSB2R0c1RpbWUSNQoIZHVyYXRpb24YBSABKAsyGS5nb29nbGUucHJvdG9i
dWYuRHVyYXRpb25SCGR1cmF0aW9uIloKElJhd0ltYWdlRGVzY3JpcHRvchIWCgZmb3JtYXQY
ASABKAlSBmZvcm1hdBIWCgZoZWlnaHQYAiABKAVSBmhlaWdodBIUCgV3aWR0aBgDIAEoBVIF
d2lkdGgiqwMKClBhY2tldFR5cGUSHQoKdHlwZV9jbGFzcxgBIAEoCVIJdHlwZUNsYXNzEmIK
D3R5cGVfZGVzY3JpcHRvchgCIAEoCzI5Lmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhh
MS5QYWNrZXRUeXBlLlR5cGVEZXNjcmlwdG9yUg50eXBlRGVzY3JpcHRvchqZAgoOVHlwZURl
c2NyaXB0b3ISewobZ3N0cmVhbWVyX2J1ZmZlcl9kZXNjcmlwdG9yGAIgASgLMjkuZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLkdzdHJlYW1lckJ1ZmZlckRlc2NyaXB0b3JIAFIZ
Z3N0cmVhbWVyQnVmZmVyRGVzY3JpcHRvchJmChRyYXdfaW1hZ2VfZGVzY3JpcHRvchgDIAEo
CzIyLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5SYXdJbWFnZURlc2NyaXB0b3JI
AFIScmF3SW1hZ2VEZXNjcmlwdG9yEhIKBHR5cGUYASABKAlSBHR5cGVCDgoMdHlwZV9kZXRh
aWxzImUKDlNlcnZlck1ldGFkYXRhEhYKBm9mZnNldBgBIAEoA1IGb2Zmc2V0EjsKC2luZ2Vz
dF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKaW5nZXN0VGltZSJN
Cg5TZXJpZXNNZXRhZGF0YRI7CgZzZXJpZXMYASABKAlCI/pBIAoedmlzaW9uYWkuZ29vZ2xl
YXBpcy5jb20vU2VyaWVzUgZzZXJpZXMi2AMKDFBhY2tldEhlYWRlchJCCgxjYXB0dXJlX3Rp
bWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQRSC2NhcHR1cmVUaW1l
EkYKBHR5cGUYAiABKAsyKi5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuUGFja2V0
VHlwZUIG4EEE4EEFUgR0eXBlEjgKCG1ldGFkYXRhGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVm
LlN0cnVjdEID4EEEUghtZXRhZGF0YRJcCg9zZXJ2ZXJfbWV0YWRhdGEYBCABKAsyLi5nb29n
bGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuU2VydmVyTWV0YWRhdGFCA+BBA1IOc2VydmVy
TWV0YWRhdGESXwoPc2VyaWVzX21ldGFkYXRhGAUgASgLMi4uZ29vZ2xlLmNsb3VkLnZpc2lv
bmFpLnYxYWxwaGExLlNlcmllc01ldGFkYXRhQgbgQQTgQQVSDnNlcmllc01ldGFkYXRhEhkK
BWZsYWdzGAYgASgFQgPgQQVSBWZsYWdzEigKDXRyYWNlX2NvbnRleHQYByABKAlCA+BBBVIM
dHJhY2VDb250ZXh0ImgKBlBhY2tldBJECgZoZWFkZXIYASABKAsyLC5nb29nbGUuY2xvdWQu
dmlzaW9uYWkudjFhbHBoYTEuUGFja2V0SGVhZGVyUgZoZWFkZXISGAoHcGF5bG9hZBgCIAEo
DFIHcGF5bG9hZELlAQoiY29tLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMUIXU3Ry
ZWFtaW5nUmVzb3VyY2VzUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby92aXNpb25haS9h
cGl2MWFscGhhMS92aXNpb25haXBiO3Zpc2lvbmFpcGKqAh5Hb29nbGUuQ2xvdWQuVmlzaW9u
QUkuVjFBbHBoYTHKAh5Hb29nbGVcQ2xvdWRcVmlzaW9uQUlcVjFhbHBoYTHqAiFHb29nbGU6
OkNsb3VkOjpWaXNpb25BSTo6VjFhbHBoYTFKqy8KBxIFDgCsAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkK
AgMCEgMUACgKCQoCAwMSAxUAJgoJCgIDBBIDFgApCggKAQgSAxgAOwoJCgIIJRIDGAA7CggK
AQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAOAoJCgII
CBIDGwA4CggKAQgSAxwAOwoJCgIIARIDHAA7CggKAQgSAx0AOwoJCgIIKRIDHQA7CggKAQgS
Ax4AOgoJCgIILRIDHgA6CjwKAgQAEgQhADABGjAgVGhlIGRlc2NyaXB0b3IgZm9yIGEgZ3N0
cmVhbWVyIGJ1ZmZlciBwYXlsb2FkLgoKCgoDBAABEgMhCCEKLgoEBAACABIDIwIZGiEgVGhl
IGNhcHMgc3RyaW5nIG9mIHRoZSBwYXlsb2FkLgoKDAoFBAACAAUSAyMCCAoMCgUEAAIAARID
IwkUCgwKBQQAAgADEgMjFxgKMQoEBAACARIDJgIYGiQgV2hldGhlciB0aGUgYnVmZmVyIGlz
IGEga2V5IGZyYW1lLgoKDAoFBAACAQUSAyYCBgoMCgUEAAIBARIDJgcTCgwKBQQAAgEDEgMm
FhcKIAoEBAACAhIDKQIpGhMgUFRTIG9mIHRoZSBmcmFtZS4KCgwKBQQAAgIGEgMpAhsKDAoF
BAACAgESAykcJAoMCgUEAAICAxIDKScoCiAKBAQAAgMSAywCKRoTIERUUyBvZiB0aGUgZnJh
bWUuCgoMCgUEAAIDBhIDLAIbCgwKBQQAAgMBEgMsHCQKDAoFBAACAwMSAywnKAolCgQEAAIE
EgMvAigaGCBEdXJhdGlvbiBvZiB0aGUgZnJhbWUuCgoMCgUEAAIEBhIDLwIaCgwKBQQAAgQB
EgMvGyMKDAoFBAACBAMSAy8mJwotCgIEARIEMwA8ARohIFRoZSBkZXNjcmlwdG9yIGZvciBh
IHJhdyBpbWFnZS4KCgoKAwQBARIDMwgaCkEKBAQBAgASAzUCFBo0IFJhdyBpbWFnZSBmb3Jt
YXQuIEl0cyBwb3NzaWJsZSB2YWx1ZXMgYXJlOiAic3JnYiIuCgoMCgUEAQIABRIDNQIICgwK
BQQBAgABEgM1CQ8KDAoFBAECAAMSAzUSEwonCgQEAQIBEgM4AhMaGiBUaGUgaGVpZ2h0IG9m
IHRoZSBpbWFnZS4KCgwKBQQBAgEFEgM4AgcKDAoFBAECAQESAzgIDgoMCgUEAQIBAxIDOBES
CiYKBAQBAgISAzsCEhoZIFRoZSB3aWR0aCBvZiB0aGUgaW1hZ2UuCgoMCgUEAQICBRIDOwIH
CgwKBQQBAgIBEgM7CA0KDAoFBAECAgMSAzsQEQpECgIEAhIEPwBhARo4IFRoZSBtZXNzYWdl
IHRoYXQgcmVwcmVzZW50cyB0aGUgZGF0YSB0eXBlIG9mIGEgcGFja2V0LgoKCgoDBAIBEgM/
CBIKSAoEBAIDABIEQQJZAxo6IFRoZSBtZXNzYWdlIHRoYXQgZnVsbHkgc3BlY2lmaWVzIHRo
ZSB0eXBlIG9mIHRoZSBwYWNrZXQuCgoMCgUEAgMAARIDQQoYCscBCgYEAgMACAASBEYETAUa
tgEgRGV0YWlsZWQgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHR5cGUuCgogSXQgaXMgbm9uLWVt
cHR5IG9ubHkgZm9yIHNwZWNpZmljIHR5cGUgY2xhc3MgY29kZWNzLiBOZWVkZWQgb25seSB3
aGVuIHRoZQogdHlwZSBzdHJpbmcgYWxvbmUgaXMgbm90IGVub3VnaCB0byBkaXNhbWJpZ3Vh
dGUgdGhlIHNwZWNpZmljIHR5cGUuCgoOCgcEAgMACAABEgNGChYKVwoGBAIDAAIAEgNIBkAa
SCBHc3RyZWFtZXJCdWZmZXJEZXNjcmlwdG9yIGlzIHRoZSBkZXNjcmlwdG9yIGZvciBnc3Ry
ZWFtZXIgYnVmZmVyIHR5cGUuCgoOCgcEAgMAAgAGEgNIBh8KDgoHBAIDAAIAARIDSCA7Cg4K
BwQCAwACAAMSA0g+PwpNCgYEAgMAAgESA0sGMho+IFJhd0ltYWdlRGVzY3JpcHRvciBpcyB0
aGUgZGVzY3JpcHRvciBmb3IgdGhlIHJhdyBpbWFnZSB0eXBlLgoKDgoHBAIDAAIBBhIDSwYY
Cg4KBwQCAwACAQESA0sZLQoOCgcEAgMAAgEDEgNLMDEKugMKBgQCAwACAhIDWAQUGqoDIFRo
ZSB0eXBlIG9mIHRoZSBwYWNrZXQuIEl0cyBwb3NzaWJsZSB2YWx1ZXMgaXMgY29kZWMgZGVw
ZW5kZW50LgoKIFRoZSBmdWxseSBxdWFsaWZpZWQgdHlwZSBuYW1lIGlzIGFsd2F5cyB0aGUg
Y29uY2F0ZW5hdGlvbiBvZiB0aGUKIHZhbHVlIGluIGB0eXBlX2NsYXNzYCB0b2dldGhlciB3
aXRoIHRoZSB2YWx1ZSBpbiBgdHlwZWAsIHNlcGFyYXRlZCBieSBhCiAnLycuCgogTm90ZSB0
aGF0IHNwZWNpZmljIGNvZGVjcyBjYW4gZGVmaW5lIHRoZWlyIG93biB0eXBlIGhpZXJhcmNo
eSwgYW5kIHNvIHRoZQogdHlwZSBzdHJpbmcgaGVyZSBjYW4gaW4gZmFjdCBiZSBzZXBhcmF0
ZWQgYnkgbXVsdGlwbGUgJy8ncyBvZiBpdHMgb3duLgoKIFBsZWFzZSBzZWUgdGhlIG9wZW4g
c291cmNlIFNESyBmb3Igc3BlY2lmaWMgY29kZWMgZG9jdW1lbnRhdGlvbi4KCg4KBwQCAwAC
AgUSA1gECgoOCgcEAgMAAgIBEgNYCw8KDgoHBAIDAAICAxIDWBITCmcKBAQCAgASA10CGBpa
IFRoZSB0eXBlIGNsYXNzIG9mIHRoZSBwYWNrZXQuIEl0cyBwb3NzaWJsZSB2YWx1ZXMgYXJl
OgogImdzdCIsICJwcm90b2J1ZiIsIGFuZCAic3RyaW5nIi4KCgwKBQQCAgAFEgNdAggKDAoF
BAICAAESA10JEwoMCgUEAgIAAxIDXRYXCiMKBAQCAgESA2ACJRoWIFRoZSB0eXBlIGRlc2Ny
aXB0b3IuCgoMCgUEAgIBBhIDYAIQCgwKBQQCAgEBEgNgESAKDAoFBAICAQMSA2AjJAo6CgIE
AxIEZABvARouIFRoZSBtZXNzYWdlIHRoYXQgcmVwcmVzZW50cyBzZXJ2ZXIgbWV0YWRhdGEu
CgoKCgMEAwESA2QIFgpACgQEAwIAEgNmAhMaMyBUaGUgb2Zmc2V0IHBvc2l0aW9uIGZvciB0
aGUgcGFja2V0IGluIGl0cyBzdHJlYW0uCgoMCgUEAwIABRIDZgIHCgwKBQQDAgABEgNmCA4K
DAoFBAMCAAMSA2YREgqXAwoEBAMCARIDbgIsGokDIFRoZSB0aW1lc3RhbXAgYXQgd2hpY2gg
dGhlIHN0cmVhbSBzZXJ2ZXIgcmVjZWl2ZXMgdGhpcyBwYWNrZXQuIFRoaXMgaXMKIGJhc2Vk
IG9uIHRoZSBsb2NhbCBjbG9jayBvZiBvbiB0aGUgc2VydmVyIHNpZGUuIEl0IGlzIGd1YXJh
bnRlZWQgdG8gYmUKIG1vbm90b25pY2FsbHkgaW5jcmVhc2luZyBmb3IgdGhlIHBhY2tldHMg
d2l0aGluIGVhY2ggc2Vzc2lvbjsgaG93ZXZlcgogdGhpcyB0aW1lc3RhbXAgaXMgbm90IGNv
bXBhcmFibGUgYWNyb3NzIHBhY2tldHMgc2VudCB0byB0aGUgc2FtZSBzdHJlYW0KIGRpZmZl
cmVudCBzZXNzaW9ucy4gU2Vzc2lvbiBoZXJlIHJlZmVycyB0byBvbmUgaW5kaXZpZHVhbCBn
UlBDIHN0cmVhbWluZwogcmVxdWVzdCB0byB0aGUgc3RyZWFtIHNlcnZlci4KCgwKBQQDAgEG
EgNuAhsKDAoFBAMCAQESA24cJwoMCgUEAwIBAxIDbiorCjoKAgQEEgRyAHgBGi4gVGhlIG1l
c3NhZ2UgdGhhdCByZXByZXNlbnRzIHNlcmllcyBtZXRhZGF0YS4KCgoKAwQEARIDcggWCoEB
CgQEBAIAEgR1AncYGnMgU2VyaWVzIG5hbWUuIEl0J3MgaW4gdGhlIGZvcm1hdCBvZgogInBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbHVzdGVycy97Y2x1c3Rl
cn0vc2VyaWVzL3tzdHJlYW19Ii4KCgwKBQQEAgAFEgN1AggKDAoFBAQCAAESA3UJDwoMCgUE
BAIAAxIDdRITCg0KBQQEAgAIEgR1FHcXCg8KBwQEAgAInwgSBHUVdxYKOQoCBAUSBXsAowEB
GiwgVGhlIG1lc3NhZ2UgdGhhdCByZXByZXNlbnRzIHBhY2tldCBoZWFkZXIuCgoKCgMEBQES
A3sIFAo6CgQEBQIAEgN9AlgaLSBJbnB1dCBvbmx5LiBUaGUgY2FwdHVyZSB0aW1lIG9mIHRo
ZSBwYWNrZXQuCgoMCgUEBQIABhIDfQIbCgwKBQQFAgABEgN9HCgKDAoFBAUCAAMSA30rLAoM
CgUEBQIACBIDfS1XCg8KCAQFAgAInAgAEgN9LlYKQQoEBAUCARIGgAECgwEEGjEgSW5wdXQg
b25seS4gSW1tdXRhYmxlLiBUaGUgdHlwZSBvZiB0aGUgcGF5bG9hZC4KCg0KBQQFAgEGEgSA
AQIMCg0KBQQFAgEBEgSAAQ0RCg0KBQQFAgEDEgSAARQVCg8KBQQFAgEIEgaAARaDAQMKEAoI
BAUCAQicCAASBIEBBCwKEAoIBAUCAQicCAESBIIBBCsKVAoEBAUCAhIEhgECURpGIElucHV0
IG9ubHkuIFRoaXMgZmllbGQgaXMgZm9yIHVzZXJzIHRvIGF0dGFjaCB1c2VyIG1hbmFnZWQg
bWV0YWRhdGEuCgoNCgUEBQICBhIEhgECGAoNCgUEBQICARIEhgEZIQoNCgUEBQICAxIEhgEk
JQoNCgUEBQICCBIEhgEmUAoQCggEBQICCJwIABIEhgEnTwqyAQoEBAUCAxIEiwECURqjASBP
dXRwdXQgb25seS4gTWV0YWRhdGEgdGhhdCB0aGUgc2VydmVyIGFwcGVuZHMgdG8gZWFjaCBw
YWNrZXQgYmVmb3JlIHNlbmRpbmcKIGl0IHRvIHJlY2VpdmVycy4gWW91IGRvbid0IG5lZWQg
dG8gc2V0IGEgdmFsdWUgZm9yIHRoaXMgZmllbGQgd2hlbiBzZW5kaW5nCiBwYWNrZXRzLgoK
DQoFBAUCAwYSBIsBAhAKDQoFBAUCAwESBIsBESAKDQoFBAUCAwMSBIsBIyQKDQoFBAUCAwgS
BIsBJVAKEAoIBAUCAwicCAASBIsBJk8KmQEKBAQFAgQSBo8BApIBBBqIASBJbnB1dCBvbmx5
LiBJbW11dGFibGUuIE1ldGFkYXRhIHRoYXQgdGhlIHNlcnZlciBuZWVkcyB0byBrbm93IHdo
ZXJlIHRvCiB3cml0ZSB0aGUgcGFja2V0cyB0by4gSXQncyBvbmx5IHJlcXVpcmVkIGZvciB0
aGUgZmlyc3QgcGFja2V0LgoKDQoFBAUCBAYSBI8BAhAKDQoFBAUCBAESBI8BESAKDQoFBAUC
BAMSBI8BIyQKDwoFBAUCBAgSBo8BJZIBAwoQCggEBQIECJwIABIEkAEELAoQCggEBQIECJwI
ARIEkQEEKwpQCgQEBQIFEgSVAQI8GkIgSW1tdXRhYmxlLiBQYWNrZXQgZmxhZyBzZXQuIFNE
SyB3aWxsIHNldCB0aGUgZmxhZyBhdXRvbWF0aWNhbGx5LgoKDQoFBAUCBQUSBJUBAgcKDQoF
BAUCBQESBJUBCA0KDQoFBAUCBQMSBJUBEBEKDQoFBAUCBQgSBJUBEjsKEAoIBAUCBQicCAAS
BJUBEzoK8wQKBAQFAgYSBKIBAkUa5AQgSW1tdXRhYmxlLiBIZWFkZXIgc3RyaW5nIGZvciB0
cmFjaW5nIGFjcm9zcyBzZXJ2aWNlcy4gSXQgc2hvdWxkIGJlIHNldCB3aGVuIHRoZSBwYWNr
ZXQKIGlzIGZpcnN0IGFycml2ZWQgaW4gdGhlIHN0cmVhbSBzZXJ2ZXIuCgogVGhlIGlucHV0
IGZvcm1hdCBpcyBhIGxvd2VyY2FzZSBoZXggc3RyaW5nOgogICAtIHZlcnNpb25faWQ6IDEg
Ynl0ZSwgY3VycmVudGx5IG11c3QgYmUgemVybyAtIGhleCBlbmNvZGVkICgyIGNoYXJhY3Rl
cnMpCiAgIC0gdHJhY2VfaWQ6IDE2IGJ5dGVzIChvcGFxdWUgYmxvYikgLSBoZXggZW5jb2Rl
ZCAoMzIgY2hhcmFjdGVycykKICAgLSBzcGFuX2lkOiA4IGJ5dGVzIChvcGFxdWUgYmxvYikg
LSBoZXggZW5jb2RlZCAoMTYgY2hhcmFjdGVycykKICAgLSB0cmFjZV9vcHRpb25zOiAxIGJ5
dGUgKExTQiBtZWFucyB0cmFjaW5nIGVuYWJsZWQpIC0gaGV4IGVuY29kZWQgKDIKICAgY2hh
cmFjdGVycykKIEV4YW1wbGU6ICIwMC00MDQxNDI0MzQ0NDU0NjQ3NDg0OTRhNGI0YzRkNGU0
Zi02MTYyNjM2NDY1NjY2NzY4LTAxIgogICAgICAgICAgIHYgIHRyYWNlX2lkICAgICAgICAg
ICAgICAgICAgICAgICAgIHNwYW5faWQgICAgICAgICAgb3B0aW9ucwoKDQoFBAUCBgUSBKIB
AggKDQoFBAUCBgESBKIBCRYKDQoFBAUCBgMSBKIBGRoKDQoFBAUCBggSBKIBG0QKEAoIBAUC
BgicCAASBKIBHEMKPAoCBAYSBqYBAKwBARouIFRoZSBxdWFudGEgb2YgZGF0dW0gdGhhdCB0
aGUgc2VyaWVzIGFjY2VwdHMuCgoLCgMEBgESBKYBCA4KIgoEBAYCABIEqAECGhoUIFRoZSBw
YWNrZXQgaGVhZGVyLgoKDQoFBAYCAAYSBKgBAg4KDQoFBAYCAAESBKgBDxUKDQoFBAYCAAMS
BKgBGBkKKgoEBAYCARIEqwECFBocIFRoZSBwYXlsb2FkIG9mIHRoZSBwYWNrZXQuCgoNCgUE
BgIBBRIEqwECBwoNCgUEBgIBARIEqwEIDwoNCgUEBgIBAxIEqwESE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor ===
    # Fields for GstreamerBufferDescriptor
    # Field: caps_string Type: 9 ()
    # Field: is_key_frame Type: 8 ()
    # Field: pts_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dts_time Type: 11 (.google.protobuf.Timestamp)
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::RawImageDescriptor ===
    # Fields for RawImageDescriptor
    # Field: format Type: 9 ()
    # Field: height Type: 5 ()
    # Field: width Type: 5 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType ===
    # Fields for PacketType
    # Field: type_class Type: 9 ()
    # Field: type_descriptor Type: 11 (.google.cloud.visionai.v1alpha1.PacketType.TypeDescriptor)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::ServerMetadata ===
    # Fields for ServerMetadata
    # Field: offset Type: 3 ()
    # Field: ingest_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::SeriesMetadata ===
    # Fields for SeriesMetadata
    # Field: series Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketHeader ===
    # Fields for PacketHeader
    # Field: capture_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 11 (.google.cloud.visionai.v1alpha1.PacketType)
    # Field: metadata Type: 11 (.google.protobuf.Struct)
    # Field: server_metadata Type: 11 (.google.cloud.visionai.v1alpha1.ServerMetadata)
    # Field: series_metadata Type: 11 (.google.cloud.visionai.v1alpha1.SeriesMetadata)
    # Field: flags Type: 5 ()
    # Field: trace_context Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet ===
    # Fields for Packet
    # Field: header Type: 11 (.google.cloud.visionai.v1alpha1.PacketHeader)
    # Field: payload Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::StreamingResources - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/streaming_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::StreamingResources;

    my $msg = Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor->new({
        caps_string => $caps_string,
        is_key_frame => $is_key_frame,
        pts_time => $pts_time,
        dts_time => $dts_time,
    });

    # Read or update a field
    my $val = $msg->caps_string();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/streaming_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::GstreamerBufferDescriptor

The descriptor for a gstreamer buffer payload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->caps_string() >> / C<< $msg->caps_string($value) >>

Type: C<String>

The caps string of the payload.

=item * C<< $msg->is_key_frame() >> / C<< $msg->is_key_frame($value) >>

Type: C<Bool>

Whether the buffer is a key frame.

=item * C<< $msg->pts_time() >> / C<< $msg->pts_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

PTS of the frame.

=item * C<< $msg->dts_time() >> / C<< $msg->dts_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

DTS of the frame.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration of the frame.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::RawImageDescriptor

The descriptor for a raw image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->format() >> / C<< $msg->format($value) >>

Type: C<String>

Raw image format. Its possible values are: "srgb".

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Int32>

The height of the image.

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Int32>

The width of the image.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType

The message that represents the data type of a packet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type_class() >> / C<< $msg->type_class($value) >>

Type: C<String>

The type class of the packet. Its possible values are:
"gst", "protobuf", and "string".

=item * C<< $msg->type_descriptor() >> / C<< $msg->type_descriptor($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType::TypeDescriptor>)

The type descriptor.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::ServerMetadata

The message that represents server metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int64>

The offset position for the packet in its stream.

=item * C<< $msg->ingest_time() >> / C<< $msg->ingest_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp at which the stream server receives this packet. This is
based on the local clock of on the server side. It is guaranteed to be
monotonically increasing for the packets within each session; however
this timestamp is not comparable across packets sent to the same stream
different sessions. Session here refers to one individual gRPC streaming
request to the stream server.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::SeriesMetadata

The message that represents series metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

Series name. It's in the format of
"projects/{project}/locations/{location}/clusters/{cluster}/series/{stream}".

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketHeader

The message that represents packet header.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->capture_time() >> / C<< $msg->capture_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Input only. The capture time of the packet.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketType>)

Input only. Immutable. The type of the payload.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Input only. This field is for users to attach user managed metadata.

=item * C<< $msg->server_metadata() >> / C<< $msg->server_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::ServerMetadata>)

Output only. Metadata that the server appends to each packet before sending
it to receivers. You don't need to set a value for this field when sending
packets.

=item * C<< $msg->series_metadata() >> / C<< $msg->series_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::SeriesMetadata>)

Input only. Immutable. Metadata that the server needs to know where to
write the packets to. It's only required for the first packet.

=item * C<< $msg->flags() >> / C<< $msg->flags($value) >>

Type: C<Int32>

Immutable. Packet flag set. SDK will set the flag automatically.

=item * C<< $msg->trace_context() >> / C<< $msg->trace_context($value) >>

Type: C<String>

Immutable. Header string for tracing across services. It should be set when the packet
is first arrived in the stream server.

The input format is a lowercase hex string:
  - version_id: 1 byte, currently must be zero - hex encoded (2 characters)
  - trace_id: 16 bytes (opaque blob) - hex encoded (32 characters)
  - span_id: 8 bytes (opaque blob) - hex encoded (16 characters)
  - trace_options: 1 byte (LSB means tracing enabled) - hex encoded (2
  characters)
Example: "00-404142434445464748494a4b4c4d4e4f-6162636465666768-01"
          v  trace_id                         span_id          options

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet

The quanta of datum that the series accepts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->header() >> / C<< $msg->header($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::PacketHeader>)

The packet header.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

The payload of the packet.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::StreamingResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
