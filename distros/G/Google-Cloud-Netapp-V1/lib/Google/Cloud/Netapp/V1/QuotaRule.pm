package Google::Cloud::Netapp::V1::QuotaRule;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvbmV0YXBwL3YxL3F1b3RhX3J1bGUucHJvdG8SFmdvb2dsZS5jbG91
ZC5uZXRhcHAudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItsBChVMaXN0UXVvdGFSdWxlc1JlcXVl
c3QSPwoGcGFyZW50GAEgASgJQifgQQL6QSESH25ldGFwcC5nb29nbGVhcGlzLmNvbS9RdW90
YVJ1bGVSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFn
ZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZp
bHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IqYBChZMaXN0UXVvdGFSdWxl
c1Jlc3BvbnNlEkIKC3F1b3RhX3J1bGVzGAEgAygLMiEuZ29vZ2xlLmNsb3VkLm5ldGFwcC52
MS5RdW90YVJ1bGVSCnF1b3RhUnVsZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0
UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJSChNHZXRRdW90
YVJ1bGVSZXF1ZXN0EjsKBG5hbWUYASABKAlCJ+BBAvpBIQofbmV0YXBwLmdvb2dsZWFwaXMu
Y29tL1F1b3RhUnVsZVIEbmFtZSLJAQoWQ3JlYXRlUXVvdGFSdWxlUmVxdWVzdBI/CgZwYXJl
bnQYASABKAlCJ+BBAvpBIRIfbmV0YXBwLmdvb2dsZWFwaXMuY29tL1F1b3RhUnVsZVIGcGFy
ZW50EkUKCnF1b3RhX3J1bGUYAiABKAsyIS5nb29nbGUuY2xvdWQubmV0YXBwLnYxLlF1b3Rh
UnVsZUID4EECUglxdW90YVJ1bGUSJwoNcXVvdGFfcnVsZV9pZBgDIAEoCUID4EECUgtxdW90
YVJ1bGVJZCKhAQoWVXBkYXRlUXVvdGFSdWxlUmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJFCgpxdW90
YV9ydWxlGAIgASgLMiEuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5RdW90YVJ1bGVCA+BBAlIJ
cXVvdGFSdWxlIlUKFkRlbGV0ZVF1b3RhUnVsZVJlcXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC
+kEhCh9uZXRhcHAuZ29vZ2xlYXBpcy5jb20vUXVvdGFSdWxlUgRuYW1lIoMHCglRdW90YVJ1
bGUSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEhsKBnRhcmdldBgCIAEoCUID4EEBUgZ0YXJn
ZXQSPwoEdHlwZRgDIAEoDjImLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuUXVvdGFSdWxlLlR5
cGVCA+BBAlIEdHlwZRIpCg5kaXNrX2xpbWl0X21pYhgEIAEoBUID4EECUgxkaXNrTGltaXRN
aWISQgoFc3RhdGUYBiABKA4yJy5nb29nbGUuY2xvdWQubmV0YXBwLnYxLlF1b3RhUnVsZS5T
dGF0ZUID4EEDUgVzdGF0ZRIoCg1zdGF0ZV9kZXRhaWxzGAcgASgJQgPgQQNSDHN0YXRlRGV0
YWlscxJACgtjcmVhdGVfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRIlCgtkZXNjcmlwdGlvbhgJIAEoCUID4EEBUgtkZXNjcmlwdGlv
bhJKCgZsYWJlbHMYCiADKAsyLS5nb29nbGUuY2xvdWQubmV0YXBwLnYxLlF1b3RhUnVsZS5M
YWJlbHNFbnRyeUID4EEBUgZsYWJlbHMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNr
ZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASKEAQoEVHlwZRIUChBUWVBFX1VOU1BFQ0lG
SUVEEAASGQoVSU5ESVZJRFVBTF9VU0VSX1FVT1RBEAESGgoWSU5ESVZJRFVBTF9HUk9VUF9R
VU9UQRACEhYKEkRFRkFVTFRfVVNFUl9RVU9UQRADEhcKE0RFRkFVTFRfR1JPVVBfUVVPVEEQ
BCJeCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESDAoIVVBE
QVRJTkcQAhIMCghERUxFVElORxADEgkKBVJFQURZEAQSCQoFRVJST1IQBTqOAepBigEKH25l
dGFwcC5nb29nbGVhcGlzLmNvbS9RdW90YVJ1bGUSUHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS92b2x1bWVzL3t2b2x1bWV9L3F1b3RhUnVsZXMve3F1b3RhX3J1
bGV9KgpxdW90YVJ1bGVzMglxdW90YVJ1bGVCsAEKGmNvbS5nb29nbGUuY2xvdWQubmV0YXBw
LnYxQg5RdW90YVJ1bGVQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL25ldGFwcC9hcGl2
MS9uZXRhcHBwYjtuZXRhcHBwYqoCFkdvb2dsZS5DbG91ZC5OZXRBcHAuVjHKAhZHb29nbGVc
Q2xvdWRcTmV0QXBwXFYx6gIZR29vZ2xlOjpDbG91ZDo6TmV0QXBwOjpWMUrqMgoHEgUOAMoB
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABID
EgApCgkKAgMBEgMTACMKCQoCAwISAxQAKgoJCgIDAxIDFQApCggKAQgSAxcAMwoJCgIIJRID
FwAzCggKAQgSAxgASQoJCgIICxIDGABJCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoA
LwoJCgIICBIDGgAvCggKAQgSAxsAMwoJCgIIARIDGwAzCggKAQgSAxwAMwoJCgIIKRIDHAAz
CggKAQgSAx0AMgoJCgIILRIDHQAyCjwKAgQAEgQgADUBGjAgTGlzdFF1b3RhUnVsZXNSZXF1
ZXN0IGZvciBsaXN0aW5nIHF1b3RhIHJ1bGVzLgoKCgoDBAABEgMgCB0KQAoEBAACABIEIgIn
BBoyIFJlcXVpcmVkLiBQYXJlbnQgdmFsdWUgZm9yIExpc3RRdW90YVJ1bGVzUmVxdWVzdAoK
DAoFBAACAAUSAyICCAoMCgUEAAIAARIDIgkPCgwKBQQAAgADEgMiEhMKDQoFBAACAAgSBCIU
JwMKDwoIBAACAAicCAASAyMEKgoPCgcEAAIACJ8IEgQkBCYFCpoBCgQEAAIBEgMrAj8ajAEg
T3B0aW9uYWwuIFJlcXVlc3RlZCBwYWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJuIGZld2Vy
IGl0ZW1zIHRoYW4KIHJlcXVlc3RlZC4gSWYgdW5zcGVjaWZpZWQsIHRoZSBzZXJ2ZXIgd2ls
bCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoMCgUEAAIBBRIDKwIHCgwKBQQAAgEB
EgMrCBEKDAoFBAACAQMSAysUFQoMCgUEAAIBCBIDKxY+Cg8KCAQAAgEInAgAEgMrFz0KWAoE
BAACAhIDLgJBGksgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJl
c3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAACAgUSAy4CCAoMCgUEAAIC
ARIDLgkTCgwKBQQAAgIDEgMuFhcKDAoFBAACAggSAy4YQAoPCggEAAICCJwIABIDLhk/CioK
BAQAAgMSAzECPRodIE9wdGlvbmFsLiBGaWx0ZXJpbmcgcmVzdWx0cwoKDAoFBAACAwUSAzEC
CAoMCgUEAAIDARIDMQkPCgwKBQQAAgMDEgMxEhMKDAoFBAACAwgSAzEUPAoPCggEAAIDCJwI
ABIDMRU7CjoKBAQAAgQSAzQCPxotIE9wdGlvbmFsLiBIaW50IGZvciBob3cgdG8gb3JkZXIg
dGhlIHJlc3VsdHMKCgwKBQQAAgQFEgM0AggKDAoFBAACBAESAzQJEQoMCgUEAAIEAxIDNBQV
CgwKBQQAAgQIEgM0Fj4KDwoIBAACBAicCAASAzQXPQpQCgIEARIEOABBARpEIExpc3RRdW90
YVJ1bGVzUmVzcG9uc2UgaXMgdGhlIHJlc3BvbnNlIHRvIGEgTGlzdFF1b3RhUnVsZXNSZXF1
ZXN0LgoKCgoDBAEBEgM4CB4KIgoEBAECABIDOgIlGhUgTGlzdCBvZiBxdW90YSBydWxlcwoK
DAoFBAECAAQSAzoCCgoMCgUEAQIABhIDOgsUCgwKBQQBAgABEgM6FSAKDAoFBAECAAMSAzoj
JApOCgQEAQIBEgM9Ah0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRz
IHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCgwKBQQBAgEFEgM9AggKDAoFBAECAQESAz0J
GAoMCgUEAQIBAxIDPRscCjMKBAQBAgISA0ACIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5v
dCBiZSByZWFjaGVkLgoKDAoFBAECAgQSA0ACCgoMCgUEAQICBRIDQAsRCgwKBQQBAgIBEgNA
Eh0KDAoFBAECAgMSA0AgIQo7CgIEAhIERABMARovIEdldFF1b3RhUnVsZVJlcXVlc3QgZm9y
IGdldHRpbmcgYSBxdW90YSBydWxlLgoKCgoDBAIBEgNECBsKMAoEBAICABIERgJLBBoiIFJl
cXVpcmVkLiBOYW1lIG9mIHRoZSBxdW90YSBydWxlCgoMCgUEAgIABRIDRgIICgwKBQQCAgAB
EgNGCQ0KDAoFBAICAAMSA0YQEQoNCgUEAgIACBIERhJLAwoPCggEAgIACJwIABIDRwQqCg8K
BwQCAgAInwgSBEgESgUKPwoCBAMSBE8AYAEaMyBDcmVhdGVRdW90YVJ1bGVSZXF1ZXN0IGZv
ciBjcmVhdGluZyBhIHF1b3RhIHJ1bGUuCgoKCgMEAwESA08IHgpBCgQEAwIAEgRRAlYEGjMg
UmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3IgQ3JlYXRlUXVvdGFSdWxlUmVxdWVzdAoKDAoF
BAMCAAUSA1ECCAoMCgUEAwIAARIDUQkPCgwKBQQDAgADEgNREhMKDQoFBAMCAAgSBFEUVgMK
DwoIBAMCAAicCAASA1IEKgoPCgcEAwIACJ8IEgRTBFUFCkAKBAQDAgESA1kCRBozIFJlcXVp
cmVkLiBGaWVsZHMgb2YgdGhlIHRvIGJlIGNyZWF0ZWQgcXVvdGEgcnVsZS4KCgwKBQQDAgEG
EgNZAgsKDAoFBAMCAQESA1kMFgoMCgUEAwIBAxIDWRkaCgwKBQQDAgEIEgNZG0MKDwoIBAMC
AQicCAASA1kcQgqcAgoEBAMCAhIDXwJEGo4CIFJlcXVpcmVkLiBJRCBvZiB0aGUgcXVvdGEg
cnVsZSB0byBjcmVhdGUuIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgcGFyZW50CiByZXNv
dXJjZS4gTXVzdCBjb250YWluIG9ubHkgbGV0dGVycywgbnVtYmVycywgdW5kZXJzY29yZSBh
bmQgaHlwaGVuLCB3aXRoCiB0aGUgZmlyc3QgY2hhcmFjdGVyIGEgbGV0dGVyIG9yIHVuZGVy
c2NvcmUsIHRoZSBsYXN0IGEgbGV0dGVyIG9yIHVuZGVyc2NvcmUKIG9yIGEgbnVtYmVyLCBh
bmQgYSA2MyBjaGFyYWN0ZXIgbWF4aW11bS4KCgwKBQQDAgIFEgNfAggKDAoFBAMCAgESA18J
FgoMCgUEAwICAxIDXxkaCgwKBQQDAgIIEgNfG0MKDwoIBAMCAgicCAASA18cQgo/CgIEBBIE
YwBuARozIFVwZGF0ZVF1b3RhUnVsZVJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgcXVvdGEgcnVs
ZS4KCgoKAwQEARIDYwgeCtoCCgQEBAIAEgRpAmovGssCIE9wdGlvbmFsLiBGaWVsZCBtYXNr
IGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRo
ZQogUXVvdGEgUnVsZSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVj
aWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2Us
IG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlm
IGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1h
c2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoMCgUEBAIABhIDaQIb
CgwKBQQEAgABEgNpHCcKDAoFBAQCAAMSA2kqKwoMCgUEBAIACBIDagYuCg8KCAQEAgAInAgA
EgNqBy0KNQoEBAQCARIDbQJEGiggUmVxdWlyZWQuIFRoZSBxdW90YSBydWxlIGJlaW5nIHVw
ZGF0ZWQKCgwKBQQEAgEGEgNtAgsKDAoFBAQCAQESA20MFgoMCgUEBAIBAxIDbRkaCgwKBQQE
AgEIEgNtG0MKDwoIBAQCAQicCAASA20cQgpGCgIEBRIEcQB5ARo6IERlbGV0ZVF1b3RhUnVs
ZVJlcXVlc3QgZm9yIGRlbGV0aW5nIGEgc2luZ2xlIHF1b3RhIHJ1bGUuCgoKCgMEBQESA3EI
HgoxCgQEBQIAEgRzAngEGiMgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHF1b3RhIHJ1bGUuCgoM
CgUEBQIABRIDcwIICgwKBQQFAgABEgNzCQ0KDAoFBAUCAAMSA3MQEQoNCgUEBQIACBIEcxJ4
AwoPCggEBQIACJwIABIDdAQqCg8KBwQFAgAInwgSBHUEdwUKpgEKAgQGEgV9AMoBARqYASBR
dW90YVJ1bGUgc3BlY2lmaWVzIHRoZSBtYXhpbXVtIGRpc2sgc3BhY2UgYSB1c2VyIG9yIGdy
b3VwIGNhbiB1c2Ugd2l0aGluIGEKIHZvbHVtZS4gVGhleSBjYW4gYmUgdXNlZCBmb3IgY3Jl
YXRpbmcgZGVmYXVsdCBhbmQgaW5kaXZpZHVhbCBxdW90YSBydWxlcy4KCgoKAwQGARIDfQgR
CgwKAwQGBxIFfgKDAQQKDgoFBAYHnQgSBX4CgwEECiUKBAQGBAASBoYBApUBAxoVIFR5cGVz
IG9mIFF1b3RhIFJ1bGUKCg0KBQQGBAABEgSGAQcLCjEKBgQGBAACABIEiAEEGRohIFVuc3Bl
Y2lmaWVkIHR5cGUgZm9yIHF1b3RhIHJ1bGUKCg8KBwQGBAACAAESBIgBBBQKDwoHBAYEAAIA
AhIEiAEXGAosCgYEBgQAAgESBIsBBB4aHCBJbmRpdmlkdWFsIHVzZXIgcXVvdGEgcnVsZQoK
DwoHBAYEAAIBARIEiwEEGQoPCgcEBgQAAgECEgSLARwdCi0KBgQGBAACAhIEjgEEHxodIElu
ZGl2aWR1YWwgZ3JvdXAgcXVvdGEgcnVsZQoKDwoHBAYEAAICARIEjgEEGgoPCgcEBgQAAgIC
EgSOAR0eCikKBgQGBAACAxIEkQEEGxoZIERlZmF1bHQgdXNlciBxdW90YSBydWxlCgoPCgcE
BgQAAgMBEgSRAQQWCg8KBwQGBAACAwISBJEBGRoKKgoGBAYEAAIEEgSUAQQcGhogRGVmYXVs
dCBncm91cCBxdW90YSBydWxlCgoPCgcEBgQAAgQBEgSUAQQXCg8KBwQGBAACBAISBJQBGhsK
IwoEBAYEARIGmAECqgEDGhMgUXVvdGEgUnVsZSBzdGF0ZXMKCg0KBQQGBAEBEgSYAQcMCjIK
BgQGBAECABIEmgEEGhoiIFVuc3BlY2lmaWVkIHN0YXRlIGZvciBxdW90YSBydWxlCgoPCgcE
BgQBAgABEgSaAQQVCg8KBwQGBAECAAISBJoBGBkKKAoGBAYEAQIBEgSdAQQRGhggUXVvdGEg
cnVsZSBpcyBjcmVhdGluZwoKDwoHBAYEAQIBARIEnQEEDAoPCgcEBgQBAgECEgSdAQ8QCigK
BgQGBAECAhIEoAEEERoYIFF1b3RhIHJ1bGUgaXMgdXBkYXRpbmcKCg8KBwQGBAECAgESBKAB
BAwKDwoHBAYEAQICAhIEoAEPEAooCgYEBgQBAgMSBKMBBBEaGCBRdW90YSBydWxlIGlzIGRl
bGV0aW5nCgoPCgcEBgQBAgMBEgSjAQQMCg8KBwQGBAECAwISBKMBDxAKJQoGBAYEAQIEEgSm
AQQOGhUgUXVvdGEgcnVsZSBpcyByZWFkeQoKDwoHBAYEAQIEARIEpgEECQoPCgcEBgQBAgQC
EgSmAQwNCi8KBgQGBAECBRIEqQEEDhofIFF1b3RhIHJ1bGUgaXMgaW4gZXJyb3Igc3RhdGUu
CgoPCgcEBgQBAgUBEgSpAQQJCg8KBwQGBAECBQISBKkBDA0KtwEKBAQGAgASBK8BAj0aqAEg
SWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHF1b3RhIHJ1bGUuCiBGb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lk
fS92b2x1bWVzL3ZvbHVtZXMve3ZvbHVtZV9pZH0vcXVvdGFSdWxlcy97cXVvdGFfcnVsZV9p
ZH1gLgoKDQoFBAYCAAUSBK8BAggKDQoFBAYCAAESBK8BCQ0KDQoFBAYCAAMSBK8BEBEKDQoF
BAYCAAgSBK8BEjwKEAoIBAYCAAicCAASBK8BEzsKkgEKBAQGAgESBLMBAj0agwEgT3B0aW9u
YWwuIFRoZSBxdW90YSBydWxlIGFwcGxpZXMgdG8gdGhlIHNwZWNpZmllZCB1c2VyIG9yIGdy
b3VwLCBpZGVudGlmaWVkCiBieSBhIFVuaXggVUlEL0dJRCwgV2luZG93cyBTSUQsIG9yIG51
bGwgZm9yIGRlZmF1bHQuCgoNCgUEBgIBBRIEswECCAoNCgUEBgIBARIEswEJDwoNCgUEBgIB
AxIEswESEwoNCgUEBgIBCBIEswEUPAoQCggEBgIBCJwIABIEswEVOwoxCgQEBgICEgS2AQI5
GiMgUmVxdWlyZWQuIFRoZSB0eXBlIG9mIHF1b3RhIHJ1bGUuCgoNCgUEBgICBhIEtgECBgoN
CgUEBgICARIEtgEHCwoNCgUEBgICAxIEtgEODwoNCgUEBgICCBIEtgEQOAoQCggEBgICCJwI
ABIEtgERNwpACgQEBgIDEgS5AQJEGjIgUmVxdWlyZWQuIFRoZSBtYXhpbXVtIGFsbG93ZWQg
ZGlzayBzcGFjZSBpbiBNaUIuCgoNCgUEBgIDBRIEuQECBwoNCgUEBgIDARIEuQEIFgoNCgUE
BgIDAxIEuQEZGgoNCgUEBgIDCBIEuQEbQwoQCggEBgIDCJwIABIEuQEcQgo0CgQEBgIEEgS8
AQI+GiYgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBxdW90YSBydWxlCgoNCgUEBgIEBhIE
vAECBwoNCgUEBgIEARIEvAEIDQoNCgUEBgIEAxIEvAEQEQoNCgUEBgIECBIEvAESPQoQCggE
BgIECJwIABIEvAETPAo8CgQEBgIFEgS/AQJHGi4gT3V0cHV0IG9ubHkuIFN0YXRlIGRldGFp
bHMgb2YgdGhlIHF1b3RhIHJ1bGUKCg0KBQQGAgUFEgS/AQIICg0KBQQGAgUBEgS/AQkWCg0K
BQQGAgUDEgS/ARkaCg0KBQQGAgUIEgS/ARtGChAKCAQGAgUInAgAEgS/ARxFCjwKBAQGAgYS
BsIBAsMBMhosIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZSBvZiB0aGUgcXVvdGEgcnVsZQoK
DQoFBAYCBgYSBMIBAhsKDQoFBAYCBgESBMIBHCcKDQoFBAYCBgMSBMIBKisKDQoFBAYCBggS
BMMBBjEKEAoIBAYCBgicCAASBMMBBzAKNwoEBAYCBxIExgECQhopIE9wdGlvbmFsLiBEZXNj
cmlwdGlvbiBvZiB0aGUgcXVvdGEgcnVsZQoKDQoFBAYCBwUSBMYBAggKDQoFBAYCBwESBMYB
CRQKDQoFBAYCBwMSBMYBFxgKDQoFBAYCBwgSBMYBGUEKEAoIBAYCBwicCAASBMYBGkAKMgoE
BAYCCBIEyQECSxokIE9wdGlvbmFsLiBMYWJlbHMgb2YgdGhlIHF1b3RhIHJ1bGUKCg0KBQQG
AggGEgTJAQIVCg0KBQQGAggBEgTJARYcCg0KBQQGAggDEgTJAR8hCg0KBQQGAggIEgTJASJK
ChAKCAQGAggInAgAEgTJASNJYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest ===
    # Fields for ListQuotaRulesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesResponse ===
    # Fields for ListQuotaRulesResponse
    # Field: quota_rules Type: 11 (.google.cloud.netapp.v1.QuotaRule)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::QuotaRule::GetQuotaRuleRequest ===
    # Fields for GetQuotaRuleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::QuotaRule::CreateQuotaRuleRequest ===
    # Fields for CreateQuotaRuleRequest
    # Field: parent Type: 9 ()
    # Field: quota_rule Type: 11 (.google.cloud.netapp.v1.QuotaRule)
    # Field: quota_rule_id Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::QuotaRule::UpdateQuotaRuleRequest ===
    # Fields for UpdateQuotaRuleRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: quota_rule Type: 11 (.google.cloud.netapp.v1.QuotaRule)

# === Message: Google::Cloud::Netapp::V1::QuotaRule::DeleteQuotaRuleRequest ===
    # Fields for DeleteQuotaRuleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::QuotaRule::QuotaRule ===
    # Fields for QuotaRule
    # Field: name Type: 9 ()
    # Field: target Type: 9 ()
    # Field: type Type: 14 (.google.cloud.netapp.v1.QuotaRule.Type)
    # Field: disk_limit_mib Type: 5 ()
    # Field: state Type: 14 (.google.cloud.netapp.v1.QuotaRule.State)
    # Field: state_details Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.netapp.v1.QuotaRule.LabelsEntry)

# Enum: QuotaRule::Type
our $QuotaRule_TYPE_UNSPECIFIED = 0;
our $QuotaRule_INDIVIDUAL_USER_QUOTA = 1;
our $QuotaRule_INDIVIDUAL_GROUP_QUOTA = 2;
our $QuotaRule_DEFAULT_USER_QUOTA = 3;
our $QuotaRule_DEFAULT_GROUP_QUOTA = 4;

# Enum: QuotaRule::State
our $QuotaRule_STATE_UNSPECIFIED = 0;
our $QuotaRule_CREATING = 1;
our $QuotaRule_UPDATING = 2;
our $QuotaRule_DELETING = 3;
our $QuotaRule_READY = 4;
our $QuotaRule_ERROR = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::QuotaRule - Compiled Protocol Buffers messages for google/cloud/netapp/v1/quota_rule.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::QuotaRule;

    my $msg = Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/quota_rule.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesRequest

ListQuotaRulesRequest for listing quota rules.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListQuotaRulesRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, the server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=back

=head2 Google::Cloud::Netapp::V1::QuotaRule::ListQuotaRulesResponse

ListQuotaRulesResponse is the response to a ListQuotaRulesRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->quota_rules() >> / C<< $msg->quota_rules($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::QuotaRule::QuotaRule>)

List of quota rules

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::QuotaRule::GetQuotaRuleRequest

GetQuotaRuleRequest for getting a quota rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the quota rule

=back

=head2 Google::Cloud::Netapp::V1::QuotaRule::CreateQuotaRuleRequest

CreateQuotaRuleRequest for creating a quota rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for CreateQuotaRuleRequest

=item * C<< $msg->quota_rule() >> / C<< $msg->quota_rule($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::QuotaRule::QuotaRule>)

Required. Fields of the to be created quota rule.

=item * C<< $msg->quota_rule_id() >> / C<< $msg->quota_rule_id($value) >>

Type: C<String>

Required. ID of the quota rule to create. Must be unique within the parent
resource. Must contain only letters, numbers, underscore and hyphen, with
the first character a letter or underscore, the last a letter or underscore
or a number, and a 63 character maximum.

=back

=head2 Google::Cloud::Netapp::V1::QuotaRule::UpdateQuotaRuleRequest

UpdateQuotaRuleRequest for updating a quota rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Quota Rule resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->quota_rule() >> / C<< $msg->quota_rule($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::QuotaRule::QuotaRule>)

Required. The quota rule being updated

=back

=head2 Google::Cloud::Netapp::V1::QuotaRule::DeleteQuotaRuleRequest

DeleteQuotaRuleRequest for deleting a single quota rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the quota rule.

=back

=head2 Google::Cloud::Netapp::V1::QuotaRule::QuotaRule

QuotaRule specifies the maximum disk space a user or group can use within a
volume. They can be used for creating default and individual quota rules.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the quota rule.
Format:
`projects/{project_number}/locations/{location_id}/volumes/volumes/{volume_id}/quotaRules/{quota_rule_id}`.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Optional. The quota rule applies to the specified user or group, identified
by a Unix UID/GID, Windows SID, or null for default.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::QuotaRule::Type>)

Required. The type of quota rule.

=item * C<< $msg->disk_limit_mib() >> / C<< $msg->disk_limit_mib($value) >>

Type: C<Int32>

Required. The maximum allowed disk space in MiB.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::QuotaRule::State>)

Output only. State of the quota rule

=item * C<< $msg->state_details() >> / C<< $msg->state_details($value) >>

Type: C<String>

Output only. State details of the quota rule

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the quota rule

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the quota rule

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::QuotaRule::QuotaRule::LabelsEntry>)

Optional. Labels of the quota rule

=back

=head3 Enum: QuotaRule::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<INDIVIDUAL_USER_QUOTA> => C<1>

=item * C<INDIVIDUAL_GROUP_QUOTA> => C<2>

=item * C<DEFAULT_USER_QUOTA> => C<3>

=item * C<DEFAULT_GROUP_QUOTA> => C<4>

=back

=head3 Enum: QuotaRule::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<UPDATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<READY> => C<4>

=item * C<ERROR> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::QuotaRule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
