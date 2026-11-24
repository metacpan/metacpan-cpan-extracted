package Google::Cloud::Visionai::V1::StreamingResources;

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
CjJnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvc3RyZWFtaW5nX3Jlc291cmNlcy5wcm90bxIY
Z29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRp
b24ucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8igwIKGUdzdHJlYW1lckJ1ZmZlckRlc2NyaXB0b3ISHwoLY2Fw
c19zdHJpbmcYASABKAlSCmNhcHNTdHJpbmcSIAoMaXNfa2V5X2ZyYW1lGAIgASgIUgppc0tl
eUZyYW1lEjUKCHB0c190aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIH
cHRzVGltZRI1CghkdHNfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
B2R0c1RpbWUSNQoIZHVyYXRpb24YBSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25S
CGR1cmF0aW9uIloKElJhd0ltYWdlRGVzY3JpcHRvchIWCgZmb3JtYXQYASABKAlSBmZvcm1h
dBIWCgZoZWlnaHQYAiABKAVSBmhlaWdodBIUCgV3aWR0aBgDIAEoBVIFd2lkdGgimQMKClBh
Y2tldFR5cGUSHQoKdHlwZV9jbGFzcxgBIAEoCVIJdHlwZUNsYXNzElwKD3R5cGVfZGVzY3Jp
cHRvchgCIAEoCzIzLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5QYWNrZXRUeXBlLlR5cGVE
ZXNjcmlwdG9yUg50eXBlRGVzY3JpcHRvchqNAgoOVHlwZURlc2NyaXB0b3ISdQobZ3N0cmVh
bWVyX2J1ZmZlcl9kZXNjcmlwdG9yGAIgASgLMjMuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYx
LkdzdHJlYW1lckJ1ZmZlckRlc2NyaXB0b3JIAFIZZ3N0cmVhbWVyQnVmZmVyRGVzY3JpcHRv
chJgChRyYXdfaW1hZ2VfZGVzY3JpcHRvchgDIAEoCzIsLmdvb2dsZS5jbG91ZC52aXNpb25h
aS52MS5SYXdJbWFnZURlc2NyaXB0b3JIAFIScmF3SW1hZ2VEZXNjcmlwdG9yEhIKBHR5cGUY
ASABKAlSBHR5cGVCDgoMdHlwZV9kZXRhaWxzImUKDlNlcnZlck1ldGFkYXRhEhYKBm9mZnNl
dBgBIAEoA1IGb2Zmc2V0EjsKC2luZ2VzdF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIKaW5nZXN0VGltZSJNCg5TZXJpZXNNZXRhZGF0YRI7CgZzZXJpZXMYASAB
KAlCI/pBIAoedmlzaW9uYWkuZ29vZ2xlYXBpcy5jb20vU2VyaWVzUgZzZXJpZXMixgMKDFBh
Y2tldEhlYWRlchJCCgxjYXB0dXJlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQRSC2NhcHR1cmVUaW1lEkAKBHR5cGUYAiABKAsyJC5nb29nbGUuY2xvdWQu
dmlzaW9uYWkudjEuUGFja2V0VHlwZUIG4EEE4EEFUgR0eXBlEjgKCG1ldGFkYXRhGAMgASgL
MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEEUghtZXRhZGF0YRJWCg9zZXJ2ZXJfbWV0
YWRhdGEYBCABKAsyKC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuU2VydmVyTWV0YWRhdGFC
A+BBA1IOc2VydmVyTWV0YWRhdGESWQoPc2VyaWVzX21ldGFkYXRhGAUgASgLMiguZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxLlNlcmllc01ldGFkYXRhQgbgQQTgQQVSDnNlcmllc01ldGFk
YXRhEhkKBWZsYWdzGAYgASgFQgPgQQVSBWZsYWdzEigKDXRyYWNlX2NvbnRleHQYByABKAlC
A+BBBVIMdHJhY2VDb250ZXh0ImIKBlBhY2tldBI+CgZoZWFkZXIYASABKAsyJi5nb29nbGUu
Y2xvdWQudmlzaW9uYWkudjEuUGFja2V0SGVhZGVyUgZoZWFkZXISGAoHcGF5bG9hZBgCIAEo
DFIHcGF5bG9hZELHAQocY29tLmdvb2dsZS5jbG91ZC52aXNpb25haS52MUIXU3RyZWFtaW5n
UmVzb3VyY2VzUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby92aXNpb25haS9hcGl2MS92
aXNpb25haXBiO3Zpc2lvbmFpcGKqAhhHb29nbGUuQ2xvdWQuVmlzaW9uQUkuVjHKAhhHb29n
bGVcQ2xvdWRcVmlzaW9uQUlcVjHqAhtHb29nbGU6OkNsb3VkOjpWaXNpb25BSTo6VjFKry8K
BxIFDgCvAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACgKCQoCAwMSAxUAJgoJCgIDBBIDFgAp
CggKAQgSAxgANQoJCgIIJRIDGAA1CggKAQgSAxkATwoJCgIICxIDGQBPCggKAQgSAxoAIgoJ
CgIIChIDGgAiCggKAQgSAxsAOAoJCgIICBIDGwA4CggKAQgSAxwANQoJCgIIARIDHAA1CggK
AQgSAx0ANQoJCgIIKRIDHQA1CggKAQgSAx4ANAoJCgIILRIDHgA0CjwKAgQAEgQhADABGjAg
VGhlIGRlc2NyaXB0b3IgZm9yIGEgZ3N0cmVhbWVyIGJ1ZmZlciBwYXlsb2FkLgoKCgoDBAAB
EgMhCCEKLgoEBAACABIDIwIZGiEgVGhlIGNhcHMgc3RyaW5nIG9mIHRoZSBwYXlsb2FkLgoK
DAoFBAACAAUSAyMCCAoMCgUEAAIAARIDIwkUCgwKBQQAAgADEgMjFxgKMQoEBAACARIDJgIY
GiQgV2hldGhlciB0aGUgYnVmZmVyIGlzIGEga2V5IGZyYW1lLgoKDAoFBAACAQUSAyYCBgoM
CgUEAAIBARIDJgcTCgwKBQQAAgEDEgMmFhcKIAoEBAACAhIDKQIpGhMgUFRTIG9mIHRoZSBm
cmFtZS4KCgwKBQQAAgIGEgMpAhsKDAoFBAACAgESAykcJAoMCgUEAAICAxIDKScoCiAKBAQA
AgMSAywCKRoTIERUUyBvZiB0aGUgZnJhbWUuCgoMCgUEAAIDBhIDLAIbCgwKBQQAAgMBEgMs
HCQKDAoFBAACAwMSAywnKAolCgQEAAIEEgMvAigaGCBEdXJhdGlvbiBvZiB0aGUgZnJhbWUu
CgoMCgUEAAIEBhIDLwIaCgwKBQQAAgQBEgMvGyMKDAoFBAACBAMSAy8mJwotCgIEARIEMwA8
ARohIFRoZSBkZXNjcmlwdG9yIGZvciBhIHJhdyBpbWFnZS4KCgoKAwQBARIDMwgaCkEKBAQB
AgASAzUCFBo0IFJhdyBpbWFnZSBmb3JtYXQuIEl0cyBwb3NzaWJsZSB2YWx1ZXMgYXJlOiAi
c3JnYiIuCgoMCgUEAQIABRIDNQIICgwKBQQBAgABEgM1CQ8KDAoFBAECAAMSAzUSEwonCgQE
AQIBEgM4AhMaGiBUaGUgaGVpZ2h0IG9mIHRoZSBpbWFnZS4KCgwKBQQBAgEFEgM4AgcKDAoF
BAECAQESAzgIDgoMCgUEAQIBAxIDOBESCiYKBAQBAgISAzsCEhoZIFRoZSB3aWR0aCBvZiB0
aGUgaW1hZ2UuCgoMCgUEAQICBRIDOwIHCgwKBQQBAgIBEgM7CA0KDAoFBAECAgMSAzsQEQpE
CgIEAhIEPwBhARo4IFRoZSBtZXNzYWdlIHRoYXQgcmVwcmVzZW50cyB0aGUgZGF0YSB0eXBl
IG9mIGEgcGFja2V0LgoKCgoDBAIBEgM/CBIKSAoEBAIDABIEQQJZAxo6IFRoZSBtZXNzYWdl
IHRoYXQgZnVsbHkgc3BlY2lmaWVzIHRoZSB0eXBlIG9mIHRoZSBwYWNrZXQuCgoMCgUEAgMA
ARIDQQoYCscBCgYEAgMACAASBEYETAUatgEgRGV0YWlsZWQgaW5mb3JtYXRpb24gYWJvdXQg
dGhlIHR5cGUuCgogSXQgaXMgbm9uLWVtcHR5IG9ubHkgZm9yIHNwZWNpZmljIHR5cGUgY2xh
c3MgY29kZWNzLiBOZWVkZWQgb25seSB3aGVuIHRoZQogdHlwZSBzdHJpbmcgYWxvbmUgaXMg
bm90IGVub3VnaCB0byBkaXNhbWJpZ3VhdGUgdGhlIHNwZWNpZmljIHR5cGUuCgoOCgcEAgMA
CAABEgNGChYKVwoGBAIDAAIAEgNIBkAaSCBHc3RyZWFtZXJCdWZmZXJEZXNjcmlwdG9yIGlz
IHRoZSBkZXNjcmlwdG9yIGZvciBnc3RyZWFtZXIgYnVmZmVyIHR5cGUuCgoOCgcEAgMAAgAG
EgNIBh8KDgoHBAIDAAIAARIDSCA7Cg4KBwQCAwACAAMSA0g+PwpNCgYEAgMAAgESA0sGMho+
IFJhd0ltYWdlRGVzY3JpcHRvciBpcyB0aGUgZGVzY3JpcHRvciBmb3IgdGhlIHJhdyBpbWFn
ZSB0eXBlLgoKDgoHBAIDAAIBBhIDSwYYCg4KBwQCAwACAQESA0sZLQoOCgcEAgMAAgEDEgNL
MDEKugMKBgQCAwACAhIDWAQUGqoDIFRoZSB0eXBlIG9mIHRoZSBwYWNrZXQuIEl0cyBwb3Nz
aWJsZSB2YWx1ZXMgaXMgY29kZWMgZGVwZW5kZW50LgoKIFRoZSBmdWxseSBxdWFsaWZpZWQg
dHlwZSBuYW1lIGlzIGFsd2F5cyB0aGUgY29uY2F0ZW5hdGlvbiBvZiB0aGUKIHZhbHVlIGlu
IGB0eXBlX2NsYXNzYCB0b2dldGhlciB3aXRoIHRoZSB2YWx1ZSBpbiBgdHlwZWAsIHNlcGFy
YXRlZCBieSBhCiAnLycuCgogTm90ZSB0aGF0IHNwZWNpZmljIGNvZGVjcyBjYW4gZGVmaW5l
IHRoZWlyIG93biB0eXBlIGhpZXJhcmNoeSwgYW5kIHNvIHRoZQogdHlwZSBzdHJpbmcgaGVy
ZSBjYW4gaW4gZmFjdCBiZSBzZXBhcmF0ZWQgYnkgbXVsdGlwbGUgJy8ncyBvZiBpdHMgb3du
LgoKIFBsZWFzZSBzZWUgdGhlIG9wZW4gc291cmNlIFNESyBmb3Igc3BlY2lmaWMgY29kZWMg
ZG9jdW1lbnRhdGlvbi4KCg4KBwQCAwACAgUSA1gECgoOCgcEAgMAAgIBEgNYCw8KDgoHBAID
AAICAxIDWBITCmcKBAQCAgASA10CGBpaIFRoZSB0eXBlIGNsYXNzIG9mIHRoZSBwYWNrZXQu
IEl0cyBwb3NzaWJsZSB2YWx1ZXMgYXJlOgogImdzdCIsICJwcm90b2J1ZiIsIGFuZCAic3Ry
aW5nIi4KCgwKBQQCAgAFEgNdAggKDAoFBAICAAESA10JEwoMCgUEAgIAAxIDXRYXCiMKBAQC
AgESA2ACJRoWIFRoZSB0eXBlIGRlc2NyaXB0b3IuCgoMCgUEAgIBBhIDYAIQCgwKBQQCAgEB
EgNgESAKDAoFBAICAQMSA2AjJAo6CgIEAxIEZABvARouIFRoZSBtZXNzYWdlIHRoYXQgcmVw
cmVzZW50cyBzZXJ2ZXIgbWV0YWRhdGEuCgoKCgMEAwESA2QIFgpACgQEAwIAEgNmAhMaMyBU
aGUgb2Zmc2V0IHBvc2l0aW9uIGZvciB0aGUgcGFja2V0IGluIGl0cyBzdHJlYW0uCgoMCgUE
AwIABRIDZgIHCgwKBQQDAgABEgNmCA4KDAoFBAMCAAMSA2YREgqXAwoEBAMCARIDbgIsGokD
IFRoZSB0aW1lc3RhbXAgYXQgd2hpY2ggdGhlIHN0cmVhbSBzZXJ2ZXIgcmVjZWl2ZXMgdGhp
cyBwYWNrZXQuIFRoaXMgaXMKIGJhc2VkIG9uIHRoZSBsb2NhbCBjbG9jayBvZiBvbiB0aGUg
c2VydmVyIHNpZGUuIEl0IGlzIGd1YXJhbnRlZWQgdG8gYmUKIG1vbm90b25pY2FsbHkgaW5j
cmVhc2luZyBmb3IgdGhlIHBhY2tldHMgd2l0aGluIGVhY2ggc2Vzc2lvbjsgaG93ZXZlcgog
dGhpcyB0aW1lc3RhbXAgaXMgbm90IGNvbXBhcmFibGUgYWNyb3NzIHBhY2tldHMgc2VudCB0
byB0aGUgc2FtZSBzdHJlYW0KIGRpZmZlcmVudCBzZXNzaW9ucy4gU2Vzc2lvbiBoZXJlIHJl
ZmVycyB0byBvbmUgaW5kaXZpZHVhbCBnUlBDIHN0cmVhbWluZwogcmVxdWVzdCB0byB0aGUg
c3RyZWFtIHNlcnZlci4KCgwKBQQDAgEGEgNuAhsKDAoFBAMCAQESA24cJwoMCgUEAwIBAxID
biorCjoKAgQEEgRyAHgBGi4gVGhlIG1lc3NhZ2UgdGhhdCByZXByZXNlbnRzIHNlcmllcyBt
ZXRhZGF0YS4KCgoKAwQEARIDcggWCoEBCgQEBAIAEgR1AncEGnMgU2VyaWVzIG5hbWUuIEl0
J3MgaW4gdGhlIGZvcm1hdCBvZgogInByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jbHVzdGVycy97Y2x1c3Rlcn0vc2VyaWVzL3tzdHJlYW19Ii4KCgwKBQQEAgAF
EgN1AggKDAoFBAQCAAESA3UJDwoMCgUEBAIAAxIDdRITCg0KBQQEAgAIEgR1FHcDCg4KBwQE
AgAInwgSA3YEUAo5CgIEBRIFewCmAQEaLCBUaGUgbWVzc2FnZSB0aGF0IHJlcHJlc2VudHMg
cGFja2V0IGhlYWRlci4KCgoKAwQFARIDewgUCjsKBAQFAgASBH0CfjEaLSBJbnB1dCBvbmx5
LiBUaGUgY2FwdHVyZSB0aW1lIG9mIHRoZSBwYWNrZXQuCgoMCgUEBQIABhIDfQIbCgwKBQQF
AgABEgN9HCgKDAoFBAUCAAMSA30rLAoMCgUEBQIACBIDfgYwCg8KCAQFAgAInAgAEgN+By8K
QQoEBAUCARIGgQEChAEEGjEgSW5wdXQgb25seS4gSW1tdXRhYmxlLiBUaGUgdHlwZSBvZiB0
aGUgcGF5bG9hZC4KCg0KBQQFAgEGEgSBAQIMCg0KBQQFAgEBEgSBAQ0RCg0KBQQFAgEDEgSB
ARQVCg8KBQQFAgEIEgaBARaEAQMKEAoIBAUCAQicCAASBIIBBCwKEAoIBAUCAQicCAESBIMB
BCsKVgoEBAUCAhIGhwECiAExGkYgSW5wdXQgb25seS4gVGhpcyBmaWVsZCBpcyBmb3IgdXNl
cnMgdG8gYXR0YWNoIHVzZXIgbWFuYWdlZCBtZXRhZGF0YS4KCg0KBQQFAgIGEgSHAQIYCg0K
BQQFAgIBEgSHARkhCg0KBQQFAgIDEgSHASQlCg0KBQQFAgIIEgSIAQYwChAKCAQFAgIInAgA
EgSIAQcvCrQBCgQEBQIDEgaNAQKOATIaowEgT3V0cHV0IG9ubHkuIE1ldGFkYXRhIHRoYXQg
dGhlIHNlcnZlciBhcHBlbmRzIHRvIGVhY2ggcGFja2V0IGJlZm9yZSBzZW5kaW5nCiBpdCB0
byByZWNlaXZlcnMuIFlvdSBkb24ndCBuZWVkIHRvIHNldCBhIHZhbHVlIGZvciB0aGlzIGZp
ZWxkIHdoZW4gc2VuZGluZwogcGFja2V0cy4KCg0KBQQFAgMGEgSNAQIQCg0KBQQFAgMBEgSN
AREgCg0KBQQFAgMDEgSNASMkCg0KBQQFAgMIEgSOAQYxChAKCAQFAgMInAgAEgSOAQcwCpkB
CgQEBQIEEgaSAQKVAQQaiAEgSW5wdXQgb25seS4gSW1tdXRhYmxlLiBNZXRhZGF0YSB0aGF0
IHRoZSBzZXJ2ZXIgbmVlZHMgdG8ga25vdyB3aGVyZSB0bwogd3JpdGUgdGhlIHBhY2tldHMg
dG8uIEl0J3Mgb25seSByZXF1aXJlZCBmb3IgdGhlIGZpcnN0IHBhY2tldC4KCg0KBQQFAgQG
EgSSAQIQCg0KBQQFAgQBEgSSAREgCg0KBQQFAgQDEgSSASMkCg8KBQQFAgQIEgaSASWVAQMK
EAoIBAUCBAicCAASBJMBBCwKEAoIBAUCBAicCAESBJQBBCsKUAoEBAUCBRIEmAECPBpCIElt
bXV0YWJsZS4gUGFja2V0IGZsYWcgc2V0LiBTREsgd2lsbCBzZXQgdGhlIGZsYWcgYXV0b21h
dGljYWxseS4KCg0KBQQFAgUFEgSYAQIHCg0KBQQFAgUBEgSYAQgNCg0KBQQFAgUDEgSYARAR
Cg0KBQQFAgUIEgSYARI7ChAKCAQFAgUInAgAEgSYARM6CvMECgQEBQIGEgSlAQJFGuQEIElt
bXV0YWJsZS4gSGVhZGVyIHN0cmluZyBmb3IgdHJhY2luZyBhY3Jvc3Mgc2VydmljZXMuIEl0
IHNob3VsZCBiZSBzZXQgd2hlbgogdGhlIHBhY2tldCBpcyBmaXJzdCBhcnJpdmVkIGluIHRo
ZSBzdHJlYW0gc2VydmVyLgoKIFRoZSBpbnB1dCBmb3JtYXQgaXMgYSBsb3dlcmNhc2UgaGV4
IHN0cmluZzoKICAgLSB2ZXJzaW9uX2lkOiAxIGJ5dGUsIGN1cnJlbnRseSBtdXN0IGJlIHpl
cm8gLSBoZXggZW5jb2RlZCAoMiBjaGFyYWN0ZXJzKQogICAtIHRyYWNlX2lkOiAxNiBieXRl
cyAob3BhcXVlIGJsb2IpIC0gaGV4IGVuY29kZWQgKDMyIGNoYXJhY3RlcnMpCiAgIC0gc3Bh
bl9pZDogOCBieXRlcyAob3BhcXVlIGJsb2IpIC0gaGV4IGVuY29kZWQgKDE2IGNoYXJhY3Rl
cnMpCiAgIC0gdHJhY2Vfb3B0aW9uczogMSBieXRlIChMU0IgbWVhbnMgdHJhY2luZyBlbmFi
bGVkKSAtIGhleCBlbmNvZGVkICgyCiAgIGNoYXJhY3RlcnMpCiBFeGFtcGxlOiAiMDAtNDA0
MTQyNDM0NDQ1NDY0NzQ4NDk0YTRiNGM0ZDRlNGYtNjE2MjYzNjQ2NTY2Njc2OC0wMSIKICAg
ICAgICAgICB2ICB0cmFjZV9pZCAgICAgICAgICAgICAgICAgICAgICAgICBzcGFuX2lkICAg
ICAgICAgIG9wdGlvbnMKCg0KBQQFAgYFEgSlAQIICg0KBQQFAgYBEgSlAQkWCg0KBQQFAgYD
EgSlARkaCg0KBQQFAgYIEgSlARtEChAKCAQFAgYInAgAEgSlARxDCjwKAgQGEgapAQCvAQEa
LiBUaGUgcXVhbnRhIG9mIGRhdHVtIHRoYXQgdGhlIHNlcmllcyBhY2NlcHRzLgoKCwoDBAYB
EgSpAQgOCiIKBAQGAgASBKsBAhoaFCBUaGUgcGFja2V0IGhlYWRlci4KCg0KBQQGAgAGEgSr
AQIOCg0KBQQGAgABEgSrAQ8VCg0KBQQGAgADEgSrARgZCioKBAQGAgESBK4BAhQaHCBUaGUg
cGF5bG9hZCBvZiB0aGUgcGFja2V0LgoKDQoFBAYCAQUSBK4BAgcKDQoFBAYCAQESBK4BCA8K
DQoFBAYCAQMSBK4BEhNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::StreamingResources::GstreamerBufferDescriptor ===
    # Fields for GstreamerBufferDescriptor
    # Field: caps_string Type: 9 ()
    # Field: is_key_frame Type: 8 ()
    # Field: pts_time Type: 11 (.google.protobuf.Timestamp)
    # Field: dts_time Type: 11 (.google.protobuf.Timestamp)
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Visionai::V1::StreamingResources::RawImageDescriptor ===
    # Fields for RawImageDescriptor
    # Field: format Type: 9 ()
    # Field: height Type: 5 ()
    # Field: width Type: 5 ()

# === Message: Google::Cloud::Visionai::V1::StreamingResources::PacketType ===
    # Fields for PacketType
    # Field: type_class Type: 9 ()
    # Field: type_descriptor Type: 11 (.google.cloud.visionai.v1.PacketType.TypeDescriptor)

# === Message: Google::Cloud::Visionai::V1::StreamingResources::ServerMetadata ===
    # Fields for ServerMetadata
    # Field: offset Type: 3 ()
    # Field: ingest_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Visionai::V1::StreamingResources::SeriesMetadata ===
    # Fields for SeriesMetadata
    # Field: series Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::StreamingResources::PacketHeader ===
    # Fields for PacketHeader
    # Field: capture_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 11 (.google.cloud.visionai.v1.PacketType)
    # Field: metadata Type: 11 (.google.protobuf.Struct)
    # Field: server_metadata Type: 11 (.google.cloud.visionai.v1.ServerMetadata)
    # Field: series_metadata Type: 11 (.google.cloud.visionai.v1.SeriesMetadata)
    # Field: flags Type: 5 ()
    # Field: trace_context Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::StreamingResources::Packet ===
    # Fields for Packet
    # Field: header Type: 11 (.google.cloud.visionai.v1.PacketHeader)
    # Field: payload Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::StreamingResources - Compiled Protocol Buffers messages for google/cloud/visionai/v1/streaming_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::StreamingResources;

    my $msg = Google::Cloud::Visionai::V1::StreamingResources::GstreamerBufferDescriptor->new({
        caps_string => $caps_string,
        is_key_frame => $is_key_frame,
        pts_time => $pts_time,
        dts_time => $dts_time,
    });

    # Read or update a field
    my $val = $msg->caps_string();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::StreamingResources::GstreamerBufferDescriptor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/streaming_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::StreamingResources::GstreamerBufferDescriptor

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

=head2 Google::Cloud::Visionai::V1::StreamingResources::RawImageDescriptor

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

=head2 Google::Cloud::Visionai::V1::StreamingResources::PacketType

The message that represents the data type of a packet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type_class() >> / C<< $msg->type_class($value) >>

Type: C<String>

The type class of the packet. Its possible values are:
"gst", "protobuf", and "string".

=item * C<< $msg->type_descriptor() >> / C<< $msg->type_descriptor($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::PacketType::TypeDescriptor>)

The type descriptor.

=back

=head2 Google::Cloud::Visionai::V1::StreamingResources::ServerMetadata

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

=head2 Google::Cloud::Visionai::V1::StreamingResources::SeriesMetadata

The message that represents series metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

Series name. It's in the format of
"projects/{project}/locations/{location}/clusters/{cluster}/series/{stream}".

=back

=head2 Google::Cloud::Visionai::V1::StreamingResources::PacketHeader

The message that represents packet header.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->capture_time() >> / C<< $msg->capture_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Input only. The capture time of the packet.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::PacketType>)

Input only. Immutable. The type of the payload.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Input only. This field is for users to attach user managed metadata.

=item * C<< $msg->server_metadata() >> / C<< $msg->server_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::ServerMetadata>)

Output only. Metadata that the server appends to each packet before sending
it to receivers. You don't need to set a value for this field when sending
packets.

=item * C<< $msg->series_metadata() >> / C<< $msg->series_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::SeriesMetadata>)

Input only. Immutable. Metadata that the server needs to know where to
write the packets to. It's only required for the first packet.

=item * C<< $msg->flags() >> / C<< $msg->flags($value) >>

Type: C<Int32>

Immutable. Packet flag set. SDK will set the flag automatically.

=item * C<< $msg->trace_context() >> / C<< $msg->trace_context($value) >>

Type: C<String>

Immutable. Header string for tracing across services. It should be set when
the packet is first arrived in the stream server.

The input format is a lowercase hex string:
  - version_id: 1 byte, currently must be zero - hex encoded (2 characters)
  - trace_id: 16 bytes (opaque blob) - hex encoded (32 characters)
  - span_id: 8 bytes (opaque blob) - hex encoded (16 characters)
  - trace_options: 1 byte (LSB means tracing enabled) - hex encoded (2
  characters)
Example: "00-404142434445464748494a4b4c4d4e4f-6162636465666768-01"
          v  trace_id                         span_id          options

=back

=head2 Google::Cloud::Visionai::V1::StreamingResources::Packet

The quanta of datum that the series accepts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->header() >> / C<< $msg->header($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::PacketHeader>)

The packet header.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

The payload of the packet.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::StreamingResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
