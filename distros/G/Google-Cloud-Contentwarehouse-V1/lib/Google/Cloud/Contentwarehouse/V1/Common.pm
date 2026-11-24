package Google::Cloud::Contentwarehouse::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9jb21tb24ucHJvdG8SIGdvb2ds
ZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byJaCg9SZXF1ZXN0TWV0YWRhdGES
RwoJdXNlcl9pbmZvGAEgASgLMiouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEu
VXNlckluZm9SCHVzZXJJbmZvIjEKEFJlc3BvbnNlTWV0YWRhdGESHQoKcmVxdWVzdF9pZBgB
IAEoCVIJcmVxdWVzdElkIjcKCFVzZXJJbmZvEg4KAmlkGAEgASgJUgJpZBIbCglncm91cF9p
ZHMYAiADKAlSCGdyb3VwSWRzIoMCCg1VcGRhdGVPcHRpb25zEk0KC3VwZGF0ZV90eXBlGAEg
ASgOMiwuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuVXBkYXRlVHlwZVIKdXBk
YXRlVHlwZRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1h
c2tSCnVwZGF0ZU1hc2sSZgoUbWVyZ2VfZmllbGRzX29wdGlvbnMYAyABKAsyNC5nb29nbGUu
Y2xvdWQuY29udGVudHdhcmVob3VzZS52MS5NZXJnZUZpZWxkc09wdGlvbnNSEm1lcmdlRmll
bGRzT3B0aW9ucyLDAQoSTWVyZ2VGaWVsZHNPcHRpb25zEjkKFnJlcGxhY2VfbWVzc2FnZV9m
aWVsZHMYASABKAhIAFIUcmVwbGFjZU1lc3NhZ2VGaWVsZHOIAQESOwoXcmVwbGFjZV9yZXBl
YXRlZF9maWVsZHMYAiABKAhIAVIVcmVwbGFjZVJlcGVhdGVkRmllbGRziAEBQhkKF19yZXBs
YWNlX21lc3NhZ2VfZmllbGRzQhoKGF9yZXBsYWNlX3JlcGVhdGVkX2ZpZWxkcyqfAgoKVXBk
YXRlVHlwZRIbChdVUERBVEVfVFlQRV9VTlNQRUNJRklFRBAAEhcKE1VQREFURV9UWVBFX1JF
UExBQ0UQARIVChFVUERBVEVfVFlQRV9NRVJHRRACEioKJlVQREFURV9UWVBFX0lOU0VSVF9Q
Uk9QRVJUSUVTX0JZX05BTUVTEAMSKwonVVBEQVRFX1RZUEVfUkVQTEFDRV9QUk9QRVJUSUVT
X0JZX05BTUVTEAQSKgomVVBEQVRFX1RZUEVfREVMRVRFX1BST1BFUlRJRVNfQllfTkFNRVMQ
BRI/CjtVUERBVEVfVFlQRV9NRVJHRV9BTkRfUkVQTEFDRV9PUl9JTlNFUlRfUFJPUEVSVElF
U19CWV9OQU1FUxAGKlMKDERhdGFiYXNlVHlwZRIOCgpEQl9VTktOT1dOEAASFAoQREJfSU5G
UkFfU1BBTk5FUhABEh0KFURCX0NMT1VEX1NRTF9QT1NUR1JFUxACGgIIASqqAQoRQWNjZXNz
Q29udHJvbE1vZGUSFAoQQUNMX01PREVfVU5LTk9XThAAEh0KGUFDTF9NT0RFX1VOSVZFUlNB
TF9BQ0NFU1MQARIwCixBQ0xfTU9ERV9ET0NVTUVOVF9MRVZFTF9BQ0NFU1NfQ09OVFJPTF9C
WU9JRBACEi4KKkFDTF9NT0RFX0RPQ1VNRU5UX0xFVkVMX0FDQ0VTU19DT05UUk9MX0dDSRAD
KokBChpEb2N1bWVudENyZWF0b3JEZWZhdWx0Um9sZRItCilET0NVTUVOVF9DUkVBVE9SX0RF
RkFVTFRfUk9MRV9VTlNQRUNJRklFRBAAEhIKDkRPQ1VNRU5UX0FETUlOEAESEwoPRE9DVU1F
TlRfRURJVE9SEAISEwoPRE9DVU1FTlRfVklFV0VSEANCyQIKJGNvbS5nb29nbGUuY2xvdWQu
Y29udGVudHdhcmVob3VzZS52MUILQ29tbW9uUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9n
by9jb250ZW50d2FyZWhvdXNlL2FwaXYxL2NvbnRlbnR3YXJlaG91c2VwYjtjb250ZW50d2Fy
ZWhvdXNlcGKqAiBHb29nbGUuQ2xvdWQuQ29udGVudFdhcmVob3VzZS5WMcoCIEdvb2dsZVxD
bG91ZFxDb250ZW50V2FyZWhvdXNlXFYx6gIjR29vZ2xlOjpDbG91ZDo6Q29udGVudFdhcmVo
b3VzZTo6VjHqQVMKKGNvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb24S
J3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufUrvKgoHEgUOAKQBAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAj
CgkKAgMBEgMTACoKCAoBCBIDFQA9CgkKAgglEgMVAD0KCAoBCBIDFgBnCgkKAggLEgMWAGcK
CAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAsCgkKAggIEgMYACwKCAoBCBIDGQA9CgkK
AggBEgMZAD0KCAoBCBIDGgA9CgkKAggpEgMaAD0KCAoBCBIDGwA8CgkKAggtEgMbADwKCQoB
CBIEHAAfAgoMCgQInQgAEgQcAB8CClEKAgQAEgQiACUBGkUgTWV0YSBpbmZvcm1hdGlvbiBp
cyB1c2VkIHRvIGltcHJvdmUgdGhlIHBlcmZvcm1hbmNlIG9mIHRoZSBzZXJ2aWNlLgoKCgoD
BAABEgMiCBcKSgoEBAACABIDJAIZGj0gUHJvdmlkZXMgdXNlciB1bmlxdWUgaWRlbnRpZmlj
YXRpb24gYW5kIGdyb3VwcyBpbmZvcm1hdGlvbi4KCgwKBQQAAgAGEgMkAgoKDAoFBAACAAES
AyQLFAoMCgUEAAIAAxIDJBcYClcKAgQBEgQoACwBGksgQWRkaXRpb25hbCBpbmZvcm1hdGlv
biByZXR1cm5lZCB0byBjbGllbnQsIHN1Y2ggYXMgZGVidWdnaW5nIGluZm9ybWF0aW9uLgoK
CgoDBAEBEgMoCBgKXgoEBAECABIDKwIYGlEgQSB1bmlxdWUgaWQgYXNzb2NpYXRlZCB3aXRo
IHRoaXMgY2FsbC4gVGhpcyBpZCBpcyBsb2dnZWQgZm9yIHRyYWNraW5nCiBwdXJwb3NlLgoK
DAoFBAECAAUSAysCCAoMCgUEAQIAARIDKwkTCgwKBQQBAgADEgMrFhcKIwoCBAISBC8AOgEa
FyBUaGUgdXNlciBpbmZvcm1hdGlvbi4KCgoKAwQCARIDLwgQCqsCCgQEAgIAEgM1AhAanQIg
QSB1bmlxdWUgdXNlciBpZGVudGlmaWNhdGlvbiBzdHJpbmcsIGFzIGRldGVybWluZWQgYnkg
dGhlIGNsaWVudC4KIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMg
aXMgMjU1LgogQWxsb3dlZCBjaGFyYWN0ZXJzIGluY2x1ZGUgbnVtYmVycyAwIHRvIDksIHVw
cGVyY2FzZSBhbmQgbG93ZXJjYXNlIGxldHRlcnMsCiBhbmQgcmVzdHJpY3RlZCBzcGVjaWFs
IHN5bWJvbHMgKDosIEAsICssIC0sIF8sIH4pCiBUaGUgZm9ybWF0IGlzICJ1c2VyOnh4eHhA
ZXhhbXBsZS5jb20iOwoKDAoFBAICAAUSAzUCCAoMCgUEAgIAARIDNQkLCgwKBQQCAgADEgM1
Dg8KdQoEBAICARIDOQIgGmggVGhlIHVuaXF1ZSBncm91cCBpZGVudGlmaWNhdGlvbnMgd2hp
Y2ggdGhlIHVzZXIgaXMgYmVsb25nIHRvLgogVGhlIGZvcm1hdCBpcyAiZ3JvdXA6eXl5eUBl
eGFtcGxlLmNvbSI7CgoMCgUEAgIBBBIDOQIKCgwKBQQCAgEFEgM5CxEKDAoFBAICAQESAzkS
GwoMCgUEAgIBAxIDOR4fCiwKAgQDEgQ9AEkBGiAgT3B0aW9ucyBmb3IgVXBkYXRlIG9wZXJh
dGlvbnMuCgoKCgMEAwESAz0IFQofCgQEAwIAEgM/Ah0aEiBUeXBlIGZvciB1cGRhdGUuCgoM
CgUEAwIABhIDPwIMCgwKBQQDAgABEgM/DRgKDAoFBAMCAAMSAz8bHAq2AQoEBAMCARIDRQIs
GqgBIEZpZWxkIG1hc2sgZm9yIG1lcmdpbmcgRG9jdW1lbnQgZmllbGRzLgogRm9yIHRoZSBg
RmllbGRNYXNrYCBkZWZpbml0aW9uLAogc2VlCiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xl
LmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNm
aWVsZG1hc2sKCgwKBQQDAgEGEgNFAhsKDAoFBAMCAQESA0UcJwoMCgUEAwIBAxIDRSorCiMK
BAQDAgISA0gCLhoWIE9wdGlvbnMgZm9yIG1lcmdpbmcuCgoMCgUEAwICBhIDSAIUCgwKBQQD
AgIBEgNIFSkKDAoFBAMCAgMSA0gsLQoxCgIEBBIETABfARolIE9wdGlvbnMgZm9yIG1lcmdp
bmcgdXBkYXRlZCBmaWVsZHMuCgoKCgMEBAESA0wIGgr/AgoEBAQCABIDUwIrGvECIFdoZW4g
bWVyZ2luZyBtZXNzYWdlIGZpZWxkcywgdGhlIGRlZmF1bHQgYmVoYXZpb3IgaXMgdG8gbWVy
Z2UKIHRoZSBjb250ZW50IG9mIHR3byBtZXNzYWdlIGZpZWxkcyB0b2dldGhlci4gSWYgeW91
IGluc3RlYWQgd2FudCB0byB1c2UKIHRoZSBmaWVsZCBmcm9tIHRoZSBzb3VyY2UgbWVzc2Fn
ZSB0byByZXBsYWNlIHRoZSBjb3JyZXNwb25kaW5nIGZpZWxkIGluCiB0aGUgZGVzdGluYXRp
b24gbWVzc2FnZSwgc2V0IHRoaXMgZmxhZyB0byB0cnVlLiBXaGVuIHRoaXMgZmxhZyBpcyBz
ZXQsCiBzcGVjaWZpZWQgc3VibWVzc2FnZSBmaWVsZHMgdGhhdCBhcmUgbWlzc2luZyBpbiBz
b3VyY2Ugd2lsbCBiZSBjbGVhcmVkIGluCiBkZXN0aW5hdGlvbi4KCgwKBQQEAgAEEgNTAgoK
DAoFBAQCAAUSA1MLDwoMCgUEBAIAARIDUxAmCgwKBQQEAgADEgNTKSoK3gMKBAQEAgESA14C
LBrQAyBXaGVuIG1lcmdpbmcgcmVwZWF0ZWQgZmllbGRzLCB0aGUgZGVmYXVsdCBiZWhhdmlv
ciBpcyB0byBhcHBlbmQKIGVudHJpZXMgZnJvbSB0aGUgc291cmNlIHJlcGVhdGVkIGZpZWxk
IHRvIHRoZSBkZXN0aW5hdGlvbiByZXBlYXRlZCBmaWVsZC4KIElmIHlvdSBpbnN0ZWFkIHdh
bnQgdG8ga2VlcCBvbmx5IHRoZSBlbnRyaWVzIGZyb20gdGhlIHNvdXJjZSByZXBlYXRlZAog
ZmllbGQsIHNldCB0aGlzIGZsYWcgdG8gdHJ1ZS4KCiBJZiB5b3Ugd2FudCB0byByZXBsYWNl
IGEgcmVwZWF0ZWQgZmllbGQgd2l0aGluIGEgbWVzc2FnZSBmaWVsZCBvbiB0aGUKIGRlc3Rp
bmF0aW9uIG1lc3NhZ2UsIHlvdSBtdXN0IHNldCBib3RoIHJlcGxhY2VfcmVwZWF0ZWRfZmll
bGRzIGFuZAogcmVwbGFjZV9tZXNzYWdlX2ZpZWxkcyB0byB0cnVlLCBvdGhlcndpc2UgdGhl
IHJlcGVhdGVkIGZpZWxkcyB3aWxsIGJlCiBhcHBlbmRlZC4KCgwKBQQEAgEEEgNeAgoKDAoF
BAQCAQUSA14LDwoMCgUEBAIBARIDXhAnCgwKBQQEAgEDEgNeKisKKgoCBQASBGIAegEaHiBV
cGRhdGUgdHlwZSBvZiB0aGUgcmVxdWVzdHMuCgoKCgMFAAESA2IFDwpDCgQFAAIAEgNkAh4a
NiBEZWZhdWx0cyB0byBmdWxsIHJlcGxhY2UgYmVoYXZpb3IsIGllLiBGVUxMX1JFUExBQ0Uu
CgoMCgUFAAIAARIDZAIZCgwKBQUAAgACEgNkHB0KeQoEBQACARIDaAIaGmwgRnVsbHkgcmVw
bGFjZSBhbGwgdGhlIGZpZWxkcyAoaW5jbHVkaW5nIHByZXZpb3VzbHkgbGlua2VkIHJhdyBk
b2N1bWVudCkuCiBBbnkgZmllbGQgbWFza3Mgd2lsbCBiZSBpZ25vcmVkLgoKDAoFBQACAQES
A2gCFQoMCgUFAAIBAhIDaBgZCjsKBAUAAgISA2sCGBouIE1lcmdlIHRoZSBmaWVsZHMgaW50
byB0aGUgZXhpc3RpbmcgZW50aXRpZXMuCgoMCgUFAAICARIDawITCgwKBQUAAgICEgNrFhcK
LwoEBQACAxIDbgItGiIgSW5zZXJ0cyB0aGUgcHJvcGVydGllcyBieSBuYW1lcy4KCgwKBQUA
AgMBEgNuAigKDAoFBQACAwISA24rLAovCgQFAAIEEgNxAi4aIiBSZXBsYWNlIHRoZSBwcm9w
ZXJ0aWVzIGJ5IG5hbWVzLgoKDAoFBQACBAESA3ECKQoMCgUFAAIEAhIDcSwtCi4KBAUAAgUS
A3QCLRohIERlbGV0ZSB0aGUgcHJvcGVydGllcyBieSBuYW1lcy4KCgwKBQUAAgUBEgN0AigK
DAoFBQACBQISA3QrLArPAQoEBQACBhIDeQJCGsEBIEZvciBlYWNoIG9mIHRoZSBwcm9wZXJ0
eSwgcmVwbGFjZXMgdGhlIHByb3BlcnR5IGlmIHRoZSBpdCBleGlzdHMsIG90aGVyd2lzZQog
aW5zZXJ0cyBhIG5ldyBwcm9wZXJ0eS4gQW5kIGZvciB0aGUgcmVzdCBvZiB0aGUgZmllbGRz
LCBtZXJnZSB0aGVtIGJhc2VkIG9uCiB1cGRhdGUgbWFzayBhbmQgbWVyZ2UgZmllbGRzIG9w
dGlvbnMuCgoMCgUFAAIGARIDeQI9CgwKBQUAAgYCEgN5QEEKNAoCBQESBX0AhgEBGicgVHlw
ZSBvZiBkYXRhYmFzZSB1c2VkIGJ5IHRoZSBjdXN0b21lcgoKCgoDBQEBEgN9BREKQAoEBQEC
ABIDfwIRGjMgVGhpcyB2YWx1ZSBpcyByZXF1aXJlZCBieSBwcm90b2J1ZiBiZXN0IHByYWN0
aWNlcwoKDAoFBQECAAESA38CDAoMCgUFAQIAAhIDfw8QCiAKBAUBAgESBIIBAhcaEiBJbnRl
cm5hbCBTcGFubmVyCgoNCgUFAQIBARIEggECEgoNCgUFAQIBAhIEggEVFgo2CgQFAQICEgSF
AQIwGiggQ2xvdWQgU3FsIHdpdGggYSBQb3N0Z3JlcyBTcWwgaW5zdGFuY2UKCg0KBQUBAgIB
EgSFAQIXCg0KBQUBAgICEgSFARobCg0KBQUBAgIDEgSFARwvCg4KBgUBAgIDARIEhQEdLgok
CgIFAhIGiQEAlQEBGhYgQWNjZXNzIENvbnRyb2wgTW9kZS4KCgsKAwUCARIEiQEFFgpBCgQF
AgIAEgSLAQIXGjMgVGhpcyB2YWx1ZSBpcyByZXF1aXJlZCBieSBwcm90b2J1ZiBiZXN0IHBy
YWN0aWNlcwoKDQoFBQICAAESBIsBAhIKDQoFBQICAAISBIsBFRYKQwoEBQICARIEjgECIBo1
IFVuaXZlcnNhbCBBY2Nlc3M6IE5vIGRvY3VtZW50IGxldmVsIGFjY2VzcyBjb250cm9sLgoK
DQoFBQICAQESBI4BAhsKDQoFBQICAQISBI4BHh8KUQoEBQICAhIEkQECMxpDIERvY3VtZW50
IGxldmVsIGFjY2VzcyBjb250cm9sIHdpdGggY3VzdG9tZXIgb3duIElkZW50aXR5IFNlcnZp
Y2UuCgoNCgUFAgICARIEkQECLgoNCgUFAgICAhIEkQExMgpKCgQFAgIDEgSUAQIxGjwgRG9j
dW1lbnQgbGV2ZWwgYWNjZXNzIGNvbnRyb2wgdXNpbmcgR29vZ2xlIENsb3VkIElkZW50aXR5
LgoKDQoFBQICAwESBJQBAiwKDQoFBQICAwISBJQBLzAKOQoCBQMSBpgBAKQBARorIFRoZSBk
ZWZhdWx0IHJvbGUgb2YgdGhlIGRvY3VtZW50IGNyZWF0b3IuCgoLCgMFAwESBJgBBR8KRAoE
BQMCABIEmgECMBo2IFVuc3BlY2lmaWVkLCB3aWxsIGJlIGRlZmF1bHQgdG8gZG9jdW1lbnQg
YWRtaW4gcm9sZS4KCg0KBQUDAgABEgSaAQIrCg0KBQUDAgACEgSaAS4vClYKBAUDAgESBJ0B
AhUaSCBEb2N1bWVudCBBZG1pbiwgc2FtZSBhcyBjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFw
aXMuY29tL2RvY3VtZW50QWRtaW4uCgoNCgUFAwIBARIEnQECEAoNCgUFAwIBAhIEnQETFApY
CgQFAwICEgSgAQIWGkogRG9jdW1lbnQgRWRpdG9yLCBzYW1lIGFzIGNvbnRlbnR3YXJlaG91
c2UuZ29vZ2xlYXBpcy5jb20vZG9jdW1lbnRFZGl0b3IuCgoNCgUFAwICARIEoAECEQoNCgUF
AwICAhIEoAEUFQpYCgQFAwIDEgSjAQIWGkogRG9jdW1lbnQgVmlld2VyLCBzYW1lIGFzIGNv
bnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vZG9jdW1lbnRWaWV3ZXIuCgoNCgUFAwID
ARIEowECEQoNCgUFAwIDAhIEowEUFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata ===
    # Fields for RequestMetadata
    # Field: user_info Type: 11 (.google.cloud.contentwarehouse.v1.UserInfo)

# === Message: Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata ===
    # Fields for ResponseMetadata
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Common::UserInfo ===
    # Fields for UserInfo
    # Field: id Type: 9 ()
    # Field: group_ids Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Common::UpdateOptions ===
    # Fields for UpdateOptions
    # Field: update_type Type: 14 (.google.cloud.contentwarehouse.v1.UpdateType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: merge_fields_options Type: 11 (.google.cloud.contentwarehouse.v1.MergeFieldsOptions)

# === Message: Google::Cloud::Contentwarehouse::V1::Common::MergeFieldsOptions ===
    # Fields for MergeFieldsOptions
    # Field: replace_message_fields Type: 8 ()
    # Field: replace_repeated_fields Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Common - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::Common;

    my $msg = Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata->new({
        user_info => $user_info,
    });

    # Read or update a field
    my $val = $msg->user_info();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata

Meta information is used to improve the performance of the service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_info() >> / C<< $msg->user_info($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::UserInfo>)

Provides user unique identification and groups information.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Common::ResponseMetadata

Additional information returned to client, such as debugging information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

A unique id associated with this call. This id is logged for tracking
purpose.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Common::UserInfo

The user information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

A unique user identification string, as determined by the client.
The maximum number of allowed characters is 255.
Allowed characters include numbers 0 to 9, uppercase and lowercase letters,
and restricted special symbols (:, @, +, -, _, ~)
The format is "user:xxxx@example.com";

=item * C<< $msg->group_ids() >> / C<< $msg->group_ids($value) >>

Type: C<String>

The unique group identifications which the user is belong to.
The format is "group:yyyy@example.com";

=back

=head2 Google::Cloud::Contentwarehouse::V1::Common::UpdateOptions

Options for Update operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_type() >> / C<< $msg->update_type($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::UpdateType>)

Type for update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask for merging Document fields.
For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=item * C<< $msg->merge_fields_options() >> / C<< $msg->merge_fields_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::MergeFieldsOptions>)

Options for merging.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Common::MergeFieldsOptions

Options for merging updated fields.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->replace_message_fields() >> / C<< $msg->replace_message_fields($value) >>

Type: C<Bool>

When merging message fields, the default behavior is to merge
the content of two message fields together. If you instead want to use
the field from the source message to replace the corresponding field in
the destination message, set this flag to true. When this flag is set,
specified submessage fields that are missing in source will be cleared in
destination.

=item * C<< $msg->replace_repeated_fields() >> / C<< $msg->replace_repeated_fields($value) >>

Type: C<Bool>

When merging repeated fields, the default behavior is to append
entries from the source repeated field to the destination repeated field.
If you instead want to keep only the entries from the source repeated
field, set this flag to true.

If you want to replace a repeated field within a message field on the
destination message, you must set both replace_repeated_fields and
replace_message_fields to true, otherwise the repeated fields will be
appended.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
