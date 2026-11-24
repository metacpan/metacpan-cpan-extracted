package Google::Cloud::Contentwarehouse::V1::DocumentSchema;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudF9zY2hlbWEucHJv
dG8SIGdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIokECg5Eb2N1bWVudFNjaGVtYRISCgRuYW1lGAEgASgJ
UgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRJnChRwcm9w
ZXJ0eV9kZWZpbml0aW9ucxgDIAMoCzI0Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNl
LnYxLlByb3BlcnR5RGVmaW5pdGlvblITcHJvcGVydHlEZWZpbml0aW9ucxIsChJkb2N1bWVu
dF9pc19mb2xkZXIYBCABKAhSEGRvY3VtZW50SXNGb2xkZXISQAoLdXBkYXRlX3RpbWUYBSAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLY3Jl
YXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0
ZVRpbWUSIAoLZGVzY3JpcHRpb24YByABKAlSC2Rlc2NyaXB0aW9uOn7qQXsKLmNvbnRlbnR3
YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnRTY2hlbWESSXByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudFNjaGVtYXMve2RvY3VtZW50X3Nj
aGVtYX0igwwKElByb3BlcnR5RGVmaW5pdGlvbhIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUS
IQoMZGlzcGxheV9uYW1lGAwgASgJUgtkaXNwbGF5TmFtZRIjCg1pc19yZXBlYXRhYmxlGAIg
ASgIUgxpc1JlcGVhdGFibGUSIwoNaXNfZmlsdGVyYWJsZRgDIAEoCFIMaXNGaWx0ZXJhYmxl
EiMKDWlzX3NlYXJjaGFibGUYBCABKAhSDGlzU2VhcmNoYWJsZRIfCgtpc19tZXRhZGF0YRgF
IAEoCFIKaXNNZXRhZGF0YRIfCgtpc19yZXF1aXJlZBgOIAEoCFIKaXNSZXF1aXJlZBJ7ChRy
ZXRyaWV2YWxfaW1wb3J0YW5jZRgSIAEoDjJILmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhv
dXNlLnYxLlByb3BlcnR5RGVmaW5pdGlvbi5SZXRyaWV2YWxJbXBvcnRhbmNlUhNyZXRyaWV2
YWxJbXBvcnRhbmNlEmgKFGludGVnZXJfdHlwZV9vcHRpb25zGAcgASgLMjQuZ29vZ2xlLmNs
b3VkLmNvbnRlbnR3YXJlaG91c2UudjEuSW50ZWdlclR5cGVPcHRpb25zSABSEmludGVnZXJU
eXBlT3B0aW9ucxJiChJmbG9hdF90eXBlX29wdGlvbnMYCCABKAsyMi5nb29nbGUuY2xvdWQu
Y29udGVudHdhcmVob3VzZS52MS5GbG9hdFR5cGVPcHRpb25zSABSEGZsb2F0VHlwZU9wdGlv
bnMSXwoRdGV4dF90eXBlX29wdGlvbnMYCSABKAsyMS5nb29nbGUuY2xvdWQuY29udGVudHdh
cmVob3VzZS52MS5UZXh0VHlwZU9wdGlvbnNIAFIPdGV4dFR5cGVPcHRpb25zEmsKFXByb3Bl
cnR5X3R5cGVfb3B0aW9ucxgKIAEoCzI1Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNl
LnYxLlByb3BlcnR5VHlwZU9wdGlvbnNIAFITcHJvcGVydHlUeXBlT3B0aW9ucxJfChFlbnVt
X3R5cGVfb3B0aW9ucxgLIAEoCzIxLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYx
LkVudW1UeXBlT3B0aW9uc0gAUg9lbnVtVHlwZU9wdGlvbnMSbAoWZGF0ZV90aW1lX3R5cGVf
b3B0aW9ucxgNIAEoCzI1Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkRhdGVU
aW1lVHlwZU9wdGlvbnNIAFITZGF0ZVRpbWVUeXBlT3B0aW9ucxJcChBtYXBfdHlwZV9vcHRp
b25zGA8gASgLMjAuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuTWFwVHlwZU9w
dGlvbnNIAFIObWFwVHlwZU9wdGlvbnMSbgoWdGltZXN0YW1wX3R5cGVfb3B0aW9ucxgQIAEo
CzI2Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlRpbWVzdGFtcFR5cGVPcHRp
b25zSABSFHRpbWVzdGFtcFR5cGVPcHRpb25zEmgKDnNjaGVtYV9zb3VyY2VzGBMgAygLMkEu
Z29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUHJvcGVydHlEZWZpbml0aW9uLlNj
aGVtYVNvdXJjZVINc2NoZW1hU291cmNlcxpJCgxTY2hlbWFTb3VyY2USEgoEbmFtZRgBIAEo
CVIEbmFtZRIlCg5wcm9jZXNzb3JfdHlwZRgCIAEoCVINcHJvY2Vzc29yVHlwZSJ/ChNSZXRy
aWV2YWxJbXBvcnRhbmNlEiQKIFJFVFJJRVZBTF9JTVBPUlRBTkNFX1VOU1BFQ0lGSUVEEAAS
CwoHSElHSEVTVBABEgoKBkhJR0hFUhACEggKBEhJR0gQAxIKCgZNRURJVU0QBBIHCgNMT1cQ
BRIKCgZMT1dFU1QQBkIUChJ2YWx1ZV90eXBlX29wdGlvbnMiFAoSSW50ZWdlclR5cGVPcHRp
b25zIhIKEEZsb2F0VHlwZU9wdGlvbnMiEQoPVGV4dFR5cGVPcHRpb25zIhUKE0RhdGVUaW1l
VHlwZU9wdGlvbnMiEAoOTWFwVHlwZU9wdGlvbnMiFgoUVGltZXN0YW1wVHlwZU9wdGlvbnMi
gwEKE1Byb3BlcnR5VHlwZU9wdGlvbnMSbAoUcHJvcGVydHlfZGVmaW5pdGlvbnMYASADKAsy
NC5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5Qcm9wZXJ0eURlZmluaXRpb25C
A+BBAlITcHJvcGVydHlEZWZpbml0aW9ucyJ7Cg9FbnVtVHlwZU9wdGlvbnMSLAoPcG9zc2li
bGVfdmFsdWVzGAEgAygJQgPgQQJSDnBvc3NpYmxlVmFsdWVzEjoKGXZhbGlkYXRpb25fY2hl
Y2tfZGlzYWJsZWQYAiABKAhSF3ZhbGlkYXRpb25DaGVja0Rpc2FibGVkQvsBCiRjb20uZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjFCE0RvY3VtZW50U2NoZW1hUHJvdG9QAVpQ
Y2xvdWQuZ29vZ2xlLmNvbS9nby9jb250ZW50d2FyZWhvdXNlL2FwaXYxL2NvbnRlbnR3YXJl
aG91c2VwYjtjb250ZW50d2FyZWhvdXNlcGKqAiBHb29nbGUuQ2xvdWQuQ29udGVudFdhcmVo
b3VzZS5WMcoCIEdvb2dsZVxDbG91ZFxDb250ZW50V2FyZWhvdXNlXFYx6gIjR29vZ2xlOjpD
bG91ZDo6Q29udGVudFdhcmVob3VzZTo6VjFKxjEKBxIFDgDJAQEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkK
AgMCEgMUACkKCAoBCBIDFgA9CgkKAgglEgMWAD0KCAoBCBIDFwBnCgkKAggLEgMXAGcKCAoB
CBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA0CgkKAggIEgMZADQKCAoBCBIDGgA9CgkKAggB
EgMaAD0KCAoBCBIDGwA9CgkKAggpEgMbAD0KCAoBCBIDHAA8CgkKAggtEgMcADwKQgoCBAAS
BB8AQAEaNiBBIGRvY3VtZW50IHNjaGVtYSB1c2VkIHRvIGRlZmluZSBkb2N1bWVudCBzdHJ1
Y3R1cmUuCgoKCgMEAAESAx8IFgoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKzwEKBAQA
AgASAyoCEhrBASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZG9jdW1lbnQgc2NoZW1hLgog
Rm9ybWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9kb2N1bWVudFNjaGVtYXMve2RvY3VtZW50X3NjaGVtYV9pZH0uCgogVGhlIG5hbWUgaXMg
aWdub3JlZCB3aGVuIGNyZWF0aW5nIGEgZG9jdW1lbnQgc2NoZW1hLgoKDAoFBAACAAUSAyoC
CAoMCgUEAAIAARIDKgkNCgwKBQQAAgADEgMqEBEKWgoEBAACARIDLQJDGk0gUmVxdWlyZWQu
IE5hbWUgb2YgdGhlIHNjaGVtYSBnaXZlbiBieSB0aGUgdXNlci4gTXVzdCBiZSB1bmlxdWUg
cGVyIHByb2plY3QuCgoMCgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCRUKDAoFBAACAQMSAy0Y
GQoMCgUEAAIBCBIDLRpCCg8KCAQAAgEInAgAEgMtG0EKIAoEBAACAhIDMAI3GhMgRG9jdW1l
bnQgZGV0YWlscy4KCgwKBQQAAgIEEgMwAgoKDAoFBAACAgYSAzALHQoMCgUEAAICARIDMB4y
CgwKBQQAAgIDEgMwNTYKaAoEBAACAxIDNAIeGlsgRG9jdW1lbnQgVHlwZSwgdHJ1ZSByZWZl
cnMgdGhlIGRvY3VtZW50IGlzIGEgZm9sZGVyLCBvdGhlcndpc2UgaXQgaXMKIGEgdHlwaWNh
bCBkb2N1bWVudC4KCgwKBQQAAgMFEgM0AgYKDAoFBAACAwESAzQHGQoMCgUEAAIDAxIDNBwd
Ck8KBAQAAgQSBDcCODIaQSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgZG9jdW1l
bnQgc2NoZW1hIGlzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgQGEgM3AhsKDAoFBAACBAESAzcc
JwoMCgUEAAIEAxIDNyorCgwKBQQAAgQIEgM4BjEKDwoIBAACBAicCAASAzgHMApKCgQEAAIF
EgQ7AjwyGjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIGRvY3VtZW50IHNjaGVt
YSBpcyBjcmVhdGVkLgoKDAoFBAACBQYSAzsCGwoMCgUEAAIFARIDOxwnCgwKBQQAAgUDEgM7
KisKDAoFBAACBQgSAzwGMQoPCggEAAIFCJwIABIDPAcwCiIKBAQAAgYSAz8CGRoVIFNjaGVt
YSBkZXNjcmlwdGlvbi4KCgwKBQQAAgYFEgM/AggKDAoFBAACBgESAz8JFAoMCgUEAAIGAxID
PxcYCjoKAgQBEgVDAKUBARotIERlZmluZXMgdGhlIG1ldGFkYXRhIGZvciBhIHNjaGVtYSBw
cm9wZXJ0eS4KCgoKAwQBARIDQwgaCjAKBAQBBAASBEUCWgMaIiBTdG9yZXMgdGhlIHJldHJp
ZXZhbCBpbXBvcnRhbmNlLgoKDAoFBAEEAAESA0UHGgpECgYEAQQAAgASA0cEKRo1IE5vIGlt
cG9ydGFuY2Ugc3BlY2lmaWVkLiBEZWZhdWx0IG1lZGl1bSBpbXBvcnRhbmNlLgoKDgoHBAEE
AAIAARIDRwQkCg4KBwQBBAACAAISA0cnKAokCgYEAQQAAgESA0oEEBoVIEhpZ2hlc3QgaW1w
b3J0YW5jZS4KCg4KBwQBBAACAQESA0oECwoOCgcEAQQAAgECEgNKDg8KIwoGBAEEAAICEgNN
BA8aFCBIaWdoZXIgaW1wb3J0YW5jZS4KCg4KBwQBBAACAgESA00ECgoOCgcEAQQAAgICEgNN
DQ4KIQoGBAEEAAIDEgNQBA0aEiBIaWdoIGltcG9ydGFuY2UuCgoOCgcEAQQAAgMBEgNQBAgK
DgoHBAEEAAIDAhIDUAsMCiMKBgQBBAACBBIDUwQPGhQgTWVkaXVtIGltcG9ydGFuY2UuCgoO
CgcEAQQAAgQBEgNTBAoKDgoHBAEEAAIEAhIDUw0OCisKBgQBBAACBRIDVgQMGhwgTG93IGlt
cG9ydGFuY2UgKG5lZ2F0aXZlKS4KCg4KBwQBBAACBQESA1YEBwoOCgcEAQQAAgUCEgNWCgsK
LgoGBAEEAAIGEgNZBA8aHyBMb3dlc3QgaW1wb3J0YW5jZSAobmVnYXRpdmUpLgoKDgoHBAEE
AAIGARIDWQQKCg4KBwQBBAACBgISA1kNDgouCgQEAQMAEgRdAmMDGiAgVGhlIHNjaGVtYSBz
b3VyY2UgaW5mb3JtYXRpb24uCgoMCgUEAQMAARIDXQoWCi8KBgQBAwACABIDXwQUGiAgVGhl
IHNjaGVtYSBuYW1lIGluIHRoZSBzb3VyY2UuCgoOCgcEAQMAAgAFEgNfBAoKDgoHBAEDAAIA
ARIDXwsPCg4KBwQBAwACAAMSA18SEwowCgYEAQMAAgESA2IEHhohIFRoZSBEb2MgQUkgcHJv
Y2Vzc29yIHR5cGUgbmFtZS4KCg4KBwQBAwACAQUSA2IECgoOCgcEAQMAAgEBEgNiCxkKDgoH
BAEDAAIBAxIDYhwdCu0BCgQEAQIAEgNpAjsa3wEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRo
ZSBtZXRhZGF0YSBwcm9wZXJ0eS4KIE11c3QgYmUgdW5pcXVlIHdpdGhpbiBhIGRvY3VtZW50
IHNjaGVtYSBhbmQgaXMgY2FzZSBpbnNlbnNpdGl2ZS4KIE5hbWVzIG11c3QgYmUgbm9uLWJs
YW5rLCBzdGFydCB3aXRoIGEgbGV0dGVyLCBhbmQgY2FuIGNvbnRhaW4gYWxwaGFudW1lcmlj
CiBjaGFyYWN0ZXJzIGFuZDogLywgOiwgLSwgXywgYW5kIC4KCgwKBQQBAgAFEgNpAggKDAoF
BAECAAESA2kJDQoMCgUEAQIAAxIDaRARCgwKBQQBAgAIEgNpEjoKDwoIBAECAAicCAASA2kT
OQpFCgQEAQIBEgNsAhsaOCBUaGUgZGlzcGxheS1uYW1lIGZvciB0aGUgcHJvcGVydHksIHVz
ZWQgZm9yIGZyb250LWVuZC4KCgwKBQQBAgEFEgNsAggKDAoFBAECAQESA2wJFQoMCgUEAQIB
AxIDbBgaCj0KBAQBAgISA28CGRowIFdoZXRoZXIgdGhlIHByb3BlcnR5IGNhbiBoYXZlIG11
bHRpcGxlIHZhbHVlcy4KCgwKBQQBAgIFEgNvAgYKDAoFBAECAgESA28HFAoMCgUEAQICAxID
bxcYCoUBCgQEAQIDEgNzAhkaeCBXaGV0aGVyIHRoZSBwcm9wZXJ0eSBjYW4gYmUgZmlsdGVy
ZWQuIElmIHRoaXMgaXMgYSBzdWItcHJvcGVydHksIGFsbCB0aGUKIHBhcmVudCBwcm9wZXJ0
aWVzIG11c3QgYmUgbWFya2VkIGZpbHRlcmFibGUuCgoMCgUEAQIDBRIDcwIGCgwKBQQBAgMB
EgNzBxQKDAoFBAECAwMSA3MXGApRCgQEAQIEEgN2AhkaRCBJbmRpY2F0ZXMgdGhhdCB0aGUg
cHJvcGVydHkgc2hvdWxkIGJlIGluY2x1ZGVkIGluIGEgZ2xvYmFsIHNlYXJjaC4KCgwKBQQB
AgQFEgN2AgYKDAoFBAECBAESA3YHFAoMCgUEAQIEAxIDdhcYCtcBCgQEAQIFEgN8AhcayQEg
V2hldGhlciB0aGUgcHJvcGVydHkgaXMgdXNlciBzdXBwbGllZCBtZXRhZGF0YS4KIFRoaXMg
b3V0LW9mLXRoZSBib3ggcGxhY2Vob2xkZXIgc2V0dGluZyBjYW4gYmUgdXNlZCB0byB0YWcg
ZGVyaXZlZAogcHJvcGVydGllcy4gSXRzIHZhbHVlIGFuZCBpbnRlcnByZXRhdGlvbiBsb2dp
YyBzaG91bGQgYmUgaW1wbGVtZW50ZWQgYnkgQVBJCiB1c2VyLgoKDAoFBAECBQUSA3wCBgoM
CgUEAQIFARIDfAcSCgwKBQQBAgUDEgN8FRYKtwEKBAQBAgYSBIEBAhgaqAEgV2hldGhlciB0
aGUgcHJvcGVydHkgaXMgbWFuZGF0b3J5LgogRGVmYXVsdCBpcyAnZmFsc2UnLCBpLmUuIHBv
cHVsYXRpbmcgcHJvcGVydHkgdmFsdWUgY2FuIGJlIHNraXBwZWQuCiBJZiAndHJ1ZScgdGhl
biB1c2VyIG11c3QgcG9wdWxhdGUgdGhlIHZhbHVlIGZvciB0aGlzIHByb3BlcnR5LgoKDQoF
BAECBgUSBIEBAgYKDQoFBAECBgESBIEBBxIKDQoFBAECBgMSBIEBFRcKRwoEBAECBxIEhAEC
MBo5IFRoZSByZXRyaWV2YWwgaW1wb3J0YW5jZSBvZiB0aGUgcHJvcGVydHkgZHVyaW5nIHNl
YXJjaC4KCg0KBQQBAgcGEgSEAQIVCg0KBQQBAgcBEgSEARYqCg0KBQQBAgcDEgSEAS0vCicK
BAQBCAASBocBAqEBAxoXIFR5cGUgb2YgdGhlIHByb3BlcnR5LgoKDQoFBAEIAAESBIcBCBoK
IQoEBAECCBIEiQEEMBoTIEludGVnZXIgcHJvcGVydHkuCgoNCgUEAQIIBhIEiQEEFgoNCgUE
AQIIARIEiQEXKwoNCgUEAQIIAxIEiQEuLwofCgQEAQIJEgSMAQQsGhEgRmxvYXQgcHJvcGVy
dHkuCgoNCgUEAQIJBhIEjAEEFAoNCgUEAQIJARIEjAEVJwoNCgUEAQIJAxIEjAEqKwolCgQE
AQIKEgSPAQQqGhcgVGV4dC9zdHJpbmcgcHJvcGVydHkuCgoNCgUEAQIKBhIEjwEEEwoNCgUE
AQIKARIEjwEUJQoNCgUEAQIKAxIEjwEoKQowCgQEAQILEgSSAQQzGiIgTmVzdGVkIHN0cnVj
dHVyZWQgZGF0YSBwcm9wZXJ0eS4KCg0KBQQBAgsGEgSSAQQXCg0KBQQBAgsBEgSSARgtCg0K
BQQBAgsDEgSSATAyCioKBAQBAgwSBJUBBCsaHCBFbnVtL2NhdGVnb3JpY2FsIHByb3BlcnR5
LgoKDQoFBAECDAYSBJUBBBMKDQoFBAECDAESBJUBFCUKDQoFBAECDAMSBJUBKCoKVgoEBAEC
DRIEmQEENBpIIERhdGUgdGltZSBwcm9wZXJ0eS4KIEl0IGlzIG5vdCBzdXBwb3J0ZWQgYnkg
Q01FSyBjb21wbGlhbnQgZGVwbG95bWVudC4KCg0KBQQBAg0GEgSZAQQXCg0KBQQBAg0BEgSZ
ARguCg0KBQQBAg0DEgSZATEzCh0KBAQBAg4SBJwBBCkaDyBNYXAgcHJvcGVydHkuCgoNCgUE
AQIOBhIEnAEEEgoNCgUEAQIOARIEnAETIwoNCgUEAQIOAxIEnAEmKApWCgQEAQIPEgSgAQQ1
GkggVGltZXN0YW1wIHByb3BlcnR5LgogSXQgaXMgbm90IHN1cHBvcnRlZCBieSBDTUVLIGNv
bXBsaWFudCBkZXBsb3ltZW50LgoKDQoFBAECDwYSBKABBBgKDQoFBAECDwESBKABGS8KDQoF
BAECDwMSBKABMjQKVwoEBAECEBIEpAECLBpJIFRoZSBtYXBwaW5nIGluZm9ybWF0aW9uIGJl
dHdlZW4gdGhpcyBwcm9wZXJ0eSB0byBhbm90aGVyIHNjaGVtYSBzb3VyY2UuCgoNCgUEAQIQ
BBIEpAECCgoNCgUEAQIQBhIEpAELFwoNCgUEAQIQARIEpAEYJgoNCgUEAQIQAxIEpAEpKwo1
CgIEAhIEqAEAHRopIENvbmZpZ3VyYXRpb25zIGZvciBhbiBpbnRlZ2VyIHByb3BlcnR5LgoK
CwoDBAIBEgSoAQgaCjIKAgQDEgSrAQAbGiYgQ29uZmlndXJhdGlvbnMgZm9yIGEgZmxvYXQg
cHJvcGVydHkuCgoLCgMEAwESBKsBCBgKMQoCBAQSBK4BABoaJSBDb25maWd1cmF0aW9ucyBm
b3IgYSB0ZXh0IHByb3BlcnR5LgoKCwoDBAQBEgSuAQgXCjYKAgQFEgSxAQAeGiogQ29uZmln
dXJhdGlvbnMgZm9yIGEgZGF0ZSB0aW1lIHByb3BlcnR5LgoKCwoDBAUBEgSxAQgbCjAKAgQG
EgS0AQAZGiQgQ29uZmlndXJhdGlvbnMgZm9yIGEgTWFwIHByb3BlcnR5LgoKCwoDBAYBEgS0
AQgWCjYKAgQHEgS3AQAfGiogQ29uZmlndXJhdGlvbnMgZm9yIGEgdGltZXN0YW1wIHByb3Bl
cnR5LgoKCwoDBAcBEgS3AQgcCkUKAgQIEga6AQC+AQEaNyBDb25maWd1cmF0aW9ucyBmb3Ig
YSBuZXN0ZWQgc3RydWN0dXJlZCBkYXRhIHByb3BlcnR5LgoKCwoDBAgBEgS6AQgbCjkKBAQI
AgASBrwBAr0BLxopIFJlcXVpcmVkLiBMaXN0IG9mIHByb3BlcnR5IGRlZmluaXRpb25zLgoK
DQoFBAgCAAQSBLwBAgoKDQoFBAgCAAYSBLwBCx0KDQoFBAgCAAESBLwBHjIKDQoFBAgCAAMS
BLwBNTYKDQoFBAgCAAgSBL0BBi4KEAoIBAgCAAicCAASBL0BBy0KQAoCBAkSBsEBAMkBARoy
IENvbmZpZ3VyYXRpb25zIGZvciBhbiBlbnVtL2NhdGVnb3JpY2FsIHByb3BlcnR5LgoKCwoD
BAkBEgTBAQgXCjcKBAQJAgASBMMBAk8aKSBSZXF1aXJlZC4gTGlzdCBvZiBwb3NzaWJsZSBl
bnVtIHZhbHVlcy4KCg0KBQQJAgAEEgTDAQIKCg0KBQQJAgAFEgTDAQsRCg0KBQQJAgABEgTD
ARIhCg0KBQQJAgADEgTDASQlCg0KBQQJAgAIEgTDASZOChAKCAQJAgAInAgAEgTDASdNCqoB
CgQECQIBEgTIAQIlGpsBIE1ha2Ugc3VyZSB0aGUgRW51bSBwcm9wZXJ0eSB2YWx1ZSBwcm92
aWRlZCBpbiB0aGUgZG9jdW1lbnQgaXMgaW4gdGhlCiBwb3NzaWxlIHZhbHVlIGxpc3QgZHVy
aW5nIGRvY3VtZW50IGNyZWF0aW9uLiBUaGUgdmFsaWRhdGlvbiBjaGVjayBydW5zIGJ5CiBk
ZWZhdWx0LgoKDQoFBAkCAQUSBMgBAgYKDQoFBAkCAQESBMgBByAKDQoFBAkCAQMSBMgBIyRi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema ===
    # Fields for DocumentSchema
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: property_definitions Type: 11 (.google.cloud.contentwarehouse.v1.PropertyDefinition)
    # Field: document_is_folder Type: 8 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition ===
    # Fields for PropertyDefinition
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: is_repeatable Type: 8 ()
    # Field: is_filterable Type: 8 ()
    # Field: is_searchable Type: 8 ()
    # Field: is_metadata Type: 8 ()
    # Field: is_required Type: 8 ()
    # Field: retrieval_importance Type: 14 (.google.cloud.contentwarehouse.v1.PropertyDefinition.RetrievalImportance)
    # Field: integer_type_options Type: 11 (.google.cloud.contentwarehouse.v1.IntegerTypeOptions)
    # Field: float_type_options Type: 11 (.google.cloud.contentwarehouse.v1.FloatTypeOptions)
    # Field: text_type_options Type: 11 (.google.cloud.contentwarehouse.v1.TextTypeOptions)
    # Field: property_type_options Type: 11 (.google.cloud.contentwarehouse.v1.PropertyTypeOptions)
    # Field: enum_type_options Type: 11 (.google.cloud.contentwarehouse.v1.EnumTypeOptions)
    # Field: date_time_type_options Type: 11 (.google.cloud.contentwarehouse.v1.DateTimeTypeOptions)
    # Field: map_type_options Type: 11 (.google.cloud.contentwarehouse.v1.MapTypeOptions)
    # Field: timestamp_type_options Type: 11 (.google.cloud.contentwarehouse.v1.TimestampTypeOptions)
    # Field: schema_sources Type: 11 (.google.cloud.contentwarehouse.v1.PropertyDefinition.SchemaSource)

# Enum: PropertyDefinition::RetrievalImportance
our $PropertyDefinition_RETRIEVAL_IMPORTANCE_UNSPECIFIED = 0;
our $PropertyDefinition_HIGHEST = 1;
our $PropertyDefinition_HIGHER = 2;
our $PropertyDefinition_HIGH = 3;
our $PropertyDefinition_MEDIUM = 4;
our $PropertyDefinition_LOW = 5;
our $PropertyDefinition_LOWEST = 6;

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::IntegerTypeOptions ===
    # Fields for IntegerTypeOptions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::FloatTypeOptions ===
    # Fields for FloatTypeOptions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::TextTypeOptions ===
    # Fields for TextTypeOptions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::DateTimeTypeOptions ===
    # Fields for DateTimeTypeOptions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::MapTypeOptions ===
    # Fields for MapTypeOptions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::TimestampTypeOptions ===
    # Fields for TimestampTypeOptions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyTypeOptions ===
    # Fields for PropertyTypeOptions
    # Field: property_definitions Type: 11 (.google.cloud.contentwarehouse.v1.PropertyDefinition)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchema::EnumTypeOptions ===
    # Fields for EnumTypeOptions
    # Field: possible_values Type: 9 ()
    # Field: validation_check_disabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentSchema - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/document_schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::DocumentSchema;

    my $msg = Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema->new({
        name => $name,
        display_name => $display_name,
        property_definitions => $property_definitions,
        document_is_folder => $document_is_folder,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/document_schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema

A document schema used to define document structure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the document schema.
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

The name is ignored when creating a document schema.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Name of the schema given by the user. Must be unique per project.

=item * C<< $msg->property_definitions() >> / C<< $msg->property_definitions($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition>)

Document details.

=item * C<< $msg->document_is_folder() >> / C<< $msg->document_is_folder($value) >>

Type: C<Bool>

Document Type, true refers the document is a folder, otherwise it is
a typical document.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document schema is last updated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the document schema is created.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Schema description.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition

Defines the metadata for a schema property.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the metadata property.
Must be unique within a document schema and is case insensitive.
Names must be non-blank, start with a letter, and can contain alphanumeric
characters and: /, :, -, _, and .

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display-name for the property, used for front-end.

=item * C<< $msg->is_repeatable() >> / C<< $msg->is_repeatable($value) >>

Type: C<Bool>

Whether the property can have multiple values.

=item * C<< $msg->is_filterable() >> / C<< $msg->is_filterable($value) >>

Type: C<Bool>

Whether the property can be filtered. If this is a sub-property, all the
parent properties must be marked filterable.

=item * C<< $msg->is_searchable() >> / C<< $msg->is_searchable($value) >>

Type: C<Bool>

Indicates that the property should be included in a global search.

=item * C<< $msg->is_metadata() >> / C<< $msg->is_metadata($value) >>

Type: C<Bool>

Whether the property is user supplied metadata.
This out-of-the box placeholder setting can be used to tag derived
properties. Its value and interpretation logic should be implemented by API
user.

=item * C<< $msg->is_required() >> / C<< $msg->is_required($value) >>

Type: C<Bool>

Whether the property is mandatory.
Default is 'false', i.e. populating property value can be skipped.
If 'true' then user must populate the value for this property.

=item * C<< $msg->retrieval_importance() >> / C<< $msg->retrieval_importance($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::PropertyDefinition::RetrievalImportance>)

The retrieval importance of the property during search.

=item * C<< $msg->integer_type_options() >> / C<< $msg->integer_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::IntegerTypeOptions>)

Integer property.

=item * C<< $msg->float_type_options() >> / C<< $msg->float_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::FloatTypeOptions>)

Float property.

=item * C<< $msg->text_type_options() >> / C<< $msg->text_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::TextTypeOptions>)

Text/string property.

=item * C<< $msg->property_type_options() >> / C<< $msg->property_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyTypeOptions>)

Nested structured data property.

=item * C<< $msg->enum_type_options() >> / C<< $msg->enum_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::EnumTypeOptions>)

Enum/categorical property.

=item * C<< $msg->date_time_type_options() >> / C<< $msg->date_time_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::DateTimeTypeOptions>)

Date time property.
It is not supported by CMEK compliant deployment.

=item * C<< $msg->map_type_options() >> / C<< $msg->map_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::MapTypeOptions>)

Map property.

=item * C<< $msg->timestamp_type_options() >> / C<< $msg->timestamp_type_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::TimestampTypeOptions>)

Timestamp property.
It is not supported by CMEK compliant deployment.

=item * C<< $msg->schema_sources() >> / C<< $msg->schema_sources($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition::SchemaSource>)

The mapping information between this property to another schema source.

=back

=head3 Enum: PropertyDefinition::RetrievalImportance

=over 4

=item * C<RETRIEVAL_IMPORTANCE_UNSPECIFIED> => C<0>

=item * C<HIGHEST> => C<1>

=item * C<HIGHER> => C<2>

=item * C<HIGH> => C<3>

=item * C<MEDIUM> => C<4>

=item * C<LOW> => C<5>

=item * C<LOWEST> => C<6>

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::IntegerTypeOptions

Configurations for an integer property.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::FloatTypeOptions

Configurations for a float property.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::TextTypeOptions

Configurations for a text property.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::DateTimeTypeOptions

Configurations for a date time property.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::MapTypeOptions

Configurations for a Map property.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::TimestampTypeOptions

Configurations for a timestamp property.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyTypeOptions

Configurations for a nested structured data property.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property_definitions() >> / C<< $msg->property_definitions($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition>)

Required. List of property definitions.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchema::EnumTypeOptions

Configurations for an enum/categorical property.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->possible_values() >> / C<< $msg->possible_values($value) >>

Type: C<String>

Required. List of possible enum values.

=item * C<< $msg->validation_check_disabled() >> / C<< $msg->validation_check_disabled($value) >>

Type: C<Bool>

Make sure the Enum property value provided in the document is in the
possile value list during document creation. The validation check runs by
default.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
