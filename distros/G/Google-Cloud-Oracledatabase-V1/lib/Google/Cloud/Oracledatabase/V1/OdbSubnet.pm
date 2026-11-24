package Google::Cloud::Oracledatabase::V1::OdbSubnet;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvb2RiX3N1Ym5ldC5wcm90bxIeZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIocGCglPZGJTdWJuZXQSFwoEbmFtZRgBIAEoCUID4EEI
UgRuYW1lEiUKCmNpZHJfcmFuZ2UYAiABKAlCBuBBAuBBBVIJY2lkclJhbmdlElMKB3B1cnBv
c2UYAyABKA4yMS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuT2RiU3VibmV0LlB1
cnBvc2VCBuBBAuBBBVIHcHVycG9zZRJSCgZsYWJlbHMYBCADKAsyNS5nb29nbGUuY2xvdWQu
b3JhY2xlZGF0YWJhc2UudjEuT2RiU3VibmV0LkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJA
CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRJKCgVzdGF0ZRgGIAEoDjIvLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFz
ZS52MS5PZGJTdWJuZXQuU3RhdGVCA+BBA1IFc3RhdGUaOQoLTGFiZWxzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJICgdQdXJwb3NlEhcKE1BV
UlBPU0VfVU5TUEVDSUZJRUQQABIRCg1DTElFTlRfU1VCTkVUEAESEQoNQkFDS1VQX1NVQk5F
VBACIlwKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASEAoMUFJPVklTSU9OSU5HEAES
DQoJQVZBSUxBQkxFEAISDwoLVEVSTUlOQVRJTkcQAxIKCgZGQUlMRUQQBDqfAepBmwEKJ29y
YWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL09kYlN1Ym5ldBJZcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30vb2Ri
U3VibmV0cy97b2RiX3N1Ym5ldH0qCm9kYlN1Ym5ldHMyCW9kYlN1Ym5ldCKFAgoWQ3JlYXRl
T2RiU3VibmV0UmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKRInb3JhY2xlZGF0YWJh
c2UuZ29vZ2xlYXBpcy5jb20vT2RiU3VibmV0UgZwYXJlbnQSJwoNb2RiX3N1Ym5ldF9pZBgC
IAEoCUID4EECUgtvZGJTdWJuZXRJZBJNCgpvZGJfc3VibmV0GAMgASgLMikuZ29vZ2xlLmNs
b3VkLm9yYWNsZWRhdGFiYXNlLnYxLk9kYlN1Ym5ldEID4EECUglvZGJTdWJuZXQSKgoKcmVx
dWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCLVAQoWVXBkYXRlT2RiU3Vi
bmV0UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVs
ZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJNCgpvZGJfc3VibmV0GAIgASgLMikuZ29vZ2xlLmNs
b3VkLm9yYWNsZWRhdGFiYXNlLnYxLk9kYlN1Ym5ldEID4EECUglvZGJTdWJuZXQSKgoKcmVx
dWVzdF9pZBgDIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCKJAQoWRGVsZXRlT2RiU3Vi
bmV0UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ29yYWNsZWRhdGFiYXNlLmdvb2ds
ZWFwaXMuY29tL09kYlN1Ym5ldFIEbmFtZRIqCgpyZXF1ZXN0X2lkGAIgASgJQgvijM/XCAII
AeBBAVIJcmVxdWVzdElkIuMBChVMaXN0T2RiU3VibmV0c1JlcXVlc3QSRwoGcGFyZW50GAEg
ASgJQi/gQQL6QSkSJ29yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL09kYlN1Ym5ldFIG
cGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2Vu
GAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4K
CG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkirgEKFkxpc3RPZGJTdWJuZXRzUmVzcG9u
c2USSgoLb2RiX3N1Ym5ldHMYASADKAsyKS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2Uu
djEuT2RiU3VibmV0UgpvZGJTdWJuZXRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiWgoTR2V0T2Ri
U3VibmV0UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ29yYWNsZWRhdGFiYXNlLmdv
b2dsZWFwaXMuY29tL09kYlN1Ym5ldFIEbmFtZULoAQoiY29tLmdvb2dsZS5jbG91ZC5vcmFj
bGVkYXRhYmFzZS52MUIOT2RiU3VibmV0UHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9v
cmFjbGVkYXRhYmFzZS9hcGl2MS9vcmFjbGVkYXRhYmFzZXBiO29yYWNsZWRhdGFiYXNlcGKq
Ah5Hb29nbGUuQ2xvdWQuT3JhY2xlRGF0YWJhc2UuVjHKAh5Hb29nbGVcQ2xvdWRcT3JhY2xl
RGF0YWJhc2VcVjHqAiFHb29nbGU6OkNsb3VkOjpPcmFjbGVEYXRhYmFzZTo6VjFKukIKBxIF
DgDuAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoC
AwASAxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKgoJCgIDBBIDFgApCggK
AQgSAxgAOwoJCgIIJRIDGAA7CggKAQgSAxkAYQoJCgIICxIDGQBhCggKAQgSAxoAIgoJCgII
ChIDGgAiCggKAQgSAxsALwoJCgIICBIDGwAvCggKAQgSAxwAOwoJCgIIARIDHAA7CggKAQgS
Ax0AOwoJCgIIKRIDHQA7CggKAQgSAx4AOgoJCgIILRIDHgA6CiwKAgQAEgQhAGABGiAgUmVw
cmVzZW50cyBPZGJTdWJuZXQgcmVzb3VyY2UuCgoKCgMEAAESAyEIEQoLCgMEAAcSBCICJwQK
DQoFBAAHnQgSBCICJwQKMQoEBAAEABIEKgIzAxojIFB1cnBvc2UgYXZhaWxhYmxlIGZvciB0
aGUgc3VibmV0LgoKDAoFBAAEAAESAyoHDgorCgYEAAQAAgASAywEHBocIERlZmF1bHQgdW5z
cGVjaWZpZWQgdmFsdWUuCgoOCgcEAAQAAgABEgMsBBcKDgoHBAAEAAIAAhIDLBobCjoKBgQA
BAACARIDLwQWGisgU3VibmV0IHRvIGJlIHVzZWQgZm9yIGNsaWVudCBjb25uZWN0aW9ucy4K
Cg4KBwQABAACAQESAy8EEQoOCgcEAAQAAgECEgMvFBUKLgoGBAAEAAICEgMyBBYaHyBTdWJu
ZXQgdG8gYmUgdXNlZCBmb3IgYmFja3VwLgoKDgoHBAAEAAICARIDMgQRCg4KBwQABAACAgIS
AzIUFQo/CgQEAAQBEgQ2AkUDGjEgVGhlIHZhcmlvdXMgbGlmZWN5Y2xlIHN0YXRlcyBvZiB0
aGUgT0RCIFN1Ym5ldC4KCgwKBQQABAEBEgM2BwwKKwoGBAAEAQIAEgM4BBoaHCBEZWZhdWx0
IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAAEAQIAARIDOAQVCg4KBwQABAECAAISAzgYGQpG
CgYEAAQBAgESAzsEFRo3IEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBwcm92
aXNpb25pbmcgc3RhdGUuCgoOCgcEAAQBAgEBEgM7BBAKDgoHBAAEAQIBAhIDOxMUCkMKBgQA
BAECAhIDPgQSGjQgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGF2YWlsYWJs
ZSBzdGF0ZS4KCg4KBwQABAECAgESAz4EDQoOCgcEAAQBAgICEgM+EBEKRQoGBAAEAQIDEgNB
BBQaNiBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gdGVybWluYXRpbmcgc3Rh
dGUuCgoOCgcEAAQBAgMBEgNBBA8KDgoHBAAEAQIDAhIDQRITCkAKBgQABAECBBIDRAQPGjEg
SW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGZhaWxlZCBzdGF0ZS4KCg4KBwQA
BAECBAESA0QECgoOCgcEAAQBAgQCEgNEDQ4KsgEKBAQAAgASA0kCPRqkASBJZGVudGlmaWVy
LiBUaGUgbmFtZSBvZiB0aGUgT2RiU3VibmV0IHJlc291cmNlIGluIHRoZSBmb2xsb3dpbmcg
Zm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L29kYk5l
dHdvcmtzL3tvZGJfbmV0d29ya30vb2RiU3VibmV0cy97b2RiX3N1Ym5ldH0KCgwKBQQAAgAF
EgNJAggKDAoFBAACAAESA0kJDQoMCgUEAAIAAxIDSRARCgwKBQQAAgAIEgNJEjwKDwoIBAAC
AAicCAASA0kTOwpCCgQEAAIBEgRMAk8EGjQgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIENJ
RFIgcmFuZ2Ugb2YgdGhlIHN1Ym5ldC4KCgwKBQQAAgEFEgNMAggKDAoFBAACAQESA0wJEwoM
CgUEAAIBAxIDTBYXCg0KBQQAAgEIEgRMGE8DCg8KCAQAAgEInAgAEgNNBCoKDwoIBAACAQic
CAESA04EKwo7CgQEAAICEgRSAlUEGi0gUmVxdWlyZWQuIEltbXV0YWJsZS4gUHVycG9zZSBv
ZiB0aGUgc3VibmV0LgoKDAoFBAACAgYSA1ICCQoMCgUEAAICARIDUgoRCgwKBQQAAgIDEgNS
FBUKDQoFBAACAggSBFIWVQMKDwoIBAACAgicCAASA1MEKgoPCggEAAICCJwIARIDVAQrCkUK
BAQAAgMSA1gCSho4IE9wdGlvbmFsLiBMYWJlbHMgb3IgdGFncyBhc3NvY2lhdGVkIHdpdGgg
dGhlIHJlc291cmNlLgoKDAoFBAACAwYSA1gCFQoMCgUEAAIDARIDWBYcCgwKBQQAAgMDEgNY
HyAKDAoFBAACAwgSA1ghSQoPCggEAAIDCJwIABIDWCJICk8KBAQAAgQSBFsCXDIaQSBPdXRw
dXQgb25seS4gVGhlIGRhdGUgYW5kIHRpbWUgdGhhdCB0aGUgT2RiTmV0d29yayB3YXMgY3Jl
YXRlZC4KCgwKBQQAAgQGEgNbAhsKDAoFBAACBAESA1scJwoMCgUEAAIEAxIDWyorCgwKBQQA
AgQIEgNcBjEKDwoIBAACBAicCAASA1wHMAo0CgQEAAIFEgNfAj4aJyBPdXRwdXQgb25seS4g
U3RhdGUgb2YgdGhlIE9EQiBTdWJuZXQuCgoMCgUEAAIFBhIDXwIHCgwKBQQAAgUBEgNfCA0K
DAoFBAACBQMSA18QEQoMCgUEAAIFCBIDXxI9Cg8KCAQAAgUInAgAEgNfEzwKMgoCBAESBWMA
ggEBGiUgVGhlIHJlcXVlc3QgZm9yIGBPZGJTdWJuZXQuQ3JlYXRlYC4KCgoKAwQBARIDYwge
CpoBCgQEAQIAEgRmAmsEGosBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHZhbHVlIGZvciB0aGUg
T2RiU3VibmV0IGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30uCgoMCgUE
AQIABRIDZgIICgwKBQQBAgABEgNmCQ8KDAoFBAECAAMSA2YSEwoNCgUEAQIACBIEZhRrAwoP
CggEAQIACJwIABIDZwQqCg8KBwQBAgAInwgSBGgEagUK9wEKBAQBAgESA3ECRBrpASBSZXF1
aXJlZC4gVGhlIElEIG9mIHRoZSBPZGJTdWJuZXQgdG8gY3JlYXRlLiBUaGlzIHZhbHVlIGlz
IHJlc3RyaWN0ZWQKIHRvICheW2Etel0oW2EtejAtOS1dezAsNjF9W2EtejAtOV0pPyQpIGFu
ZCBtdXN0IGJlIGEgbWF4aW11bSBvZiA2MwogY2hhcmFjdGVycyBpbiBsZW5ndGguIFRoZSB2
YWx1ZSBtdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIgYW5kIGVuZCB3aXRoCiBhIGxldHRlciBv
ciBhIG51bWJlci4KCgwKBQQBAgEFEgNxAggKDAoFBAECAQESA3EJFgoMCgUEAQIBAxIDcRka
CgwKBQQBAgEIEgNxG0MKDwoIBAECAQicCAASA3EcQgpFCgQEAQICEgN0AkQaOCBSZXF1aXJl
ZC4gRGV0YWlscyBvZiB0aGUgT2RiU3VibmV0IGluc3RhbmNlIHRvIGNyZWF0ZS4KCgwKBQQB
AgIGEgN0AgsKDAoFBAECAgESA3QMFgoMCgUEAQICAxIDdBkaCgwKBQQBAgIIEgN0G0MKDwoI
BAECAgicCAASA3QcQgrWAwoEBAECAxIFfgKBAQQaxgMgT3B0aW9uYWwuIEFuIG9wdGlvbmFs
IElEIHRvIGlkZW50aWZ5IHRoZSByZXF1ZXN0LiBUaGlzIHZhbHVlIGlzIHVzZWQgdG8KIGlk
ZW50aWZ5IGR1cGxpY2F0ZSByZXF1ZXN0cy4gSWYgeW91IG1ha2UgYSByZXF1ZXN0IHdpdGgg
dGhlIHNhbWUgcmVxdWVzdCBJRAogYW5kIHRoZSBvcmlnaW5hbCByZXF1ZXN0IGlzIHN0aWxs
IGluIHByb2dyZXNzIG9yIGNvbXBsZXRlZCwgdGhlIHNlcnZlcgogaWdub3JlcyB0aGUgc2Vj
b25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMgY2xpZW50cyBmcm9tCiBhY2NpZGVudGFsbHkg
Y3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3Qg
YmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwog
bm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4K
CgwKBQQBAgMFEgN+AggKDAoFBAECAwESA34JEwoMCgUEAQIDAxIDfhYXCg4KBQQBAgMIEgV+
GIEBAwoSCgsEAQIDCMzx+YoBARIDfwQqChAKCAQBAgMInAgAEgSAAQQqCjMKAgQCEgaFAQCi
AQEaJSBUaGUgcmVxdWVzdCBmb3IgYE9kYlN1Ym5ldC5VcGRhdGVgLgoKCwoDBAIBEgSFAQge
CvYCCgQEAgIAEgaLAQKMAS8a5QIgT3B0aW9uYWwuIEEgbWFzayBzcGVjaWZ5aW5nIHdoaWNo
IGZpZWxkcyBpbiB0aGUgT2RiU3VibmV0IHNob3VsZCBiZQogdXBkYXRlZC4gQSBmaWVsZCBz
cGVjaWZpZWQgaW4gdGhlIG1hc2sgaXMgdXBkYXRlZC4gSWYgYSBtYXNrIGlzbid0CiBwcm92
aWRlZCwgdGhlIHNlcnZpY2UgdHJlYXRzIHRoaXMgYXMgYW4gaW1wbGllZCBmaWVsZCBtYXNr
IGVxdWl2YWxlbnQgdG8KIGFsbCBmaWVsZHMgdGhhdCBhcmUgcG9wdWxhdGVkIChoYXZlIGEg
bm9uLWVtcHR5IHZhbHVlKS4gVG8gY2xlYXIgb3IgdW5zZXQgYQogZmllbGQsIHRoZSBmaWVs
ZCBtdXN0IGJlIGV4cGxpY2l0bHkgc3BlY2lmaWVkIGluIHRoZSBgdXBkYXRlX21hc2tgLgoK
DQoFBAICAAYSBIsBAhsKDQoFBAICAAESBIsBHCcKDQoFBAICAAMSBIsBKisKDQoFBAICAAgS
BIwBBi4KEAoIBAICAAicCAASBIwBBy0KsAMKBAQCAgESBJQBAkQaoQMgUmVxdWlyZWQuIFRo
ZSByZXNvdXJjZSBiZWluZyB1cGRhdGVkLiBOb3RlIG9ubHkgbGFiZWxzIGNhbiBiZSB1cGRh
dGVkLgogVGhlIHByb3ZpZGVkIGxhYmVscyB3aWxsIGNvbXBsZXRlbHkgcmVwbGFjZSB0aGUg
ZXhpc3RpbmcgbGFiZWxzLgogQW55IGV4aXN0aW5nIGxhYmVsIGtleXMgdGhhdCBhcmUgbm90
IGluY2x1ZGVkIGluIHRoZSB1cGRhdGUgcmVxdWVzdCB3aWxsIGJlCiBkZWxldGVkLiBOb3Qg
cHJvdmlkaW5nIGxhYmVscyBhbmQgdXBkYXRlX21hc2sgd2lsbCBub3QgdXBkYXRlIHRoZSBs
YWJlbHMuCiBUbyBjbGVhciBhbGwgbGFiZWxzLCBzcGVjaWZ5IGBsYWJlbHNgIGluIHRoZSBg
dXBkYXRlX21hc2tgIGFuZCBvbWl0IG9yCiBsZWF2ZSB0aGUgYGxhYmVsc2AgZmllbGQgZW1w
dHkgaW4gdGhlIHVwZGF0ZSByZXF1ZXN0LgoKDQoFBAICAQYSBJQBAgsKDQoFBAICAQESBJQB
DBYKDQoFBAICAQMSBJQBGRoKDQoFBAICAQgSBJQBG0MKEAoIBAICAQicCAASBJQBHEIK1wMK
BAQCAgISBp4BAqEBBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8gaWRlbnRpZnkg
dGhlIHJlcXVlc3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkgZHVwbGljYXRl
IHJlcXVlc3RzLiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2FtZSByZXF1ZXN0
IElECiBhbmQgdGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJvZ3Jlc3Mgb3Ig
Y29tcGxldGVkLCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhp
cyBwcmV2ZW50cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNh
dGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQg
d2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgw
MDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAICAgUSBJ4BAggK
DQoFBAICAgESBJ4BCRMKDQoFBAICAgMSBJ4BFhcKDwoFBAICAggSBp4BGKEBAwoTCgsEAgIC
CMzx+YoBARIEnwEEKgoQCggEAgICCJwIABIEoAEEKgozCgIEAxIGpQEAuwEBGiUgVGhlIHJl
cXVlc3QgZm9yIGBPZGJTdWJuZXQuRGVsZXRlYC4KCgsKAwQDARIEpQEIHgqoAQoEBAMCABIG
qAECrQEEGpcBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcmVzb3VyY2UgaW4gdGhlIGZv
bGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259
L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30vb2RiU3VibmV0cy97b2RiX3N1Ym5ldH0uCgoN
CgUEAwIABRIEqAECCAoNCgUEAwIAARIEqAEJDQoNCgUEAwIAAxIEqAEQEQoPCgUEAwIACBIG
qAESrQEDChAKCAQDAgAInAgAEgSpAQQqChEKBwQDAgAInwgSBqoBBKwBBQrXAwoEBAMCARIG
twECugEEGsYDIE9wdGlvbmFsLiBBbiBvcHRpb25hbCBJRCB0byBpZGVudGlmeSB0aGUgcmVx
dWVzdC4gVGhpcyB2YWx1ZSBpcyB1c2VkIHRvCiBpZGVudGlmeSBkdXBsaWNhdGUgcmVxdWVz
dHMuIElmIHlvdSBtYWtlIGEgcmVxdWVzdCB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIGFu
ZCB0aGUgb3JpZ2luYWwgcmVxdWVzdCBpcyBzdGlsbCBpbiBwcm9ncmVzcyBvciBjb21wbGV0
ZWQsIHRoZSBzZXJ2ZXIKIGlnbm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZl
bnRzIGNsaWVudHMgZnJvbQogYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21t
aXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRo
ZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAw
LTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEAwIBBRIEtwECCAoNCgUEAwIB
ARIEtwEJEwoNCgUEAwIBAxIEtwEWFwoPCgUEAwIBCBIGtwEYugEDChMKCwQDAgEIzPH5igEB
EgS4AQQqChAKCAQDAgEInAgAEgS5AQQqCjEKAgQEEga+AQDVAQEaIyBUaGUgcmVxdWVzdCBm
b3IgYE9kYlN1Ym5ldC5MaXN0YC4KCgsKAwQEARIEvgEIHQqcAQoEBAQCABIGwQECxgEEGosB
IFJlcXVpcmVkLiBUaGUgcGFyZW50IHZhbHVlIGZvciB0aGUgT2RiU3VibmV0IGluIHRoZSBm
b2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30uCgoNCgUEBAIABRIEwQECCAoNCgUEBAIA
ARIEwQEJDwoNCgUEBAIAAxIEwQESEwoPCgUEBAIACBIGwQEUxgEDChAKCAQEAgAInAgAEgTC
AQQqChEKBwQEAgAInwgSBsMBBMUBBQrDAQoEBAQCARIEywECPxq0ASBPcHRpb25hbC4gVGhl
IG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybi4KIElmIHVuc3BlY2lmaWVkLCBh
dCBtb3N0IDUwIE9EQiBOZXR3b3JrcyB3aWxsIGJlIHJldHVybmVkLgogVGhlIG1heGltdW0g
dmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEw
MDAuCgoNCgUEBAIBBRIEywECBwoNCgUEBAIBARIEywEIEQoNCgUEBAIBAxIEywEUFQoNCgUE
BAIBCBIEywEWPgoQCggEBAIBCJwIABIEywEXPQpZCgQEBAICEgTOAQJBGksgT3B0aW9uYWwu
IEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91
bGQgcmV0dXJuLgoKDQoFBAQCAgUSBM4BAggKDQoFBAQCAgESBM4BCRMKDQoFBAQCAgMSBM4B
FhcKDQoFBAQCAggSBM4BGEAKEAoIBAQCAgicCAASBM4BGT8KUQoEBAQCAxIE0QECPRpDIE9w
dGlvbmFsLiBBbiBleHByZXNzaW9uIGZvciBmaWx0ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhl
IHJlcXVlc3QuCgoNCgUEBAIDBRIE0QECCAoNCgUEBAIDARIE0QEJDwoNCgUEBAIDAxIE0QES
EwoNCgUEBAIDCBIE0QEUPAoQCggEBAIDCJwIABIE0QEVOwpQCgQEBAIEEgTUAQI/GkIgT3B0
aW9uYWwuIEFuIGV4cHJlc3Npb24gZm9yIG9yZGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSBy
ZXF1ZXN0LgoKDQoFBAQCBAUSBNQBAggKDQoFBAQCBAESBNQBCREKDQoFBAQCBAMSBNQBFBUK
DQoFBAQCBAgSBNQBFj4KEAoIBAQCBAicCAASBNQBFz0KMgoCBAUSBtgBAOIBARokIFRoZSBy
ZXNwb25zZSBmb3IgYE9kYlN1Ym5ldC5MaXN0YC4KCgsKAwQFARIE2AEIHgooCgQEBQIAEgTa
AQIlGhogVGhlIGxpc3Qgb2YgT0RCIFN1Ym5ldHMuCgoNCgUEBQIABBIE2gECCgoNCgUEBQIA
BhIE2gELFAoNCgUEBQIAARIE2gEVIAoNCgUEBQIAAxIE2gEjJApPCgQEBQIBEgTdAQIdGkEg
QSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3Vs
ZCByZXR1cm4uCgoNCgUEBQIBBRIE3QECCAoNCgUEBQIBARIE3QEJGAoNCgUEBQIBAxIE3QEb
HApvCgQEBQICEgThAQIiGmEgVW5yZWFjaGFibGUgbG9jYXRpb25zIHdoZW4gbGlzdGluZyBy
ZXNvdXJjZXMgYWNyb3NzIGFsbCBsb2NhdGlvbnMgdXNpbmcKIHdpbGRjYXJkIGxvY2F0aW9u
ICctJy4KCg0KBQQFAgIEEgThAQIKCg0KBQQFAgIFEgThAQsRCg0KBQQFAgIBEgThARIdCg0K
BQQFAgIDEgThASAhCjAKAgQGEgblAQDuAQEaIiBUaGUgcmVxdWVzdCBmb3IgYE9kYlN1Ym5l
dC5HZXRgLgoKCwoDBAYBEgTlAQgbCqsBCgQEBgIAEgboAQLtAQQamgEgUmVxdWlyZWQuIFRo
ZSBuYW1lIG9mIHRoZSBPZGJTdWJuZXQgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vb2RiTmV0d29ya3Mve29kYl9u
ZXR3b3JrfS9vZGJTdWJuZXRzL3tvZGJfc3VibmV0fS4KCg0KBQQGAgAFEgToAQIICg0KBQQG
AgABEgToAQkNCg0KBQQGAgADEgToARARCg8KBQQGAgAIEgboARLtAQMKEAoIBAYCAAicCAAS
BOkBBCoKEQoHBAYCAAifCBIG6gEE7AEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet ===
    # Fields for OdbSubnet
    # Field: name Type: 9 ()
    # Field: cidr_range Type: 9 ()
    # Field: purpose Type: 14 (.google.cloud.oracledatabase.v1.OdbSubnet.Purpose)
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.OdbSubnet.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.OdbSubnet.State)

# Enum: OdbSubnet::Purpose
our $OdbSubnet_PURPOSE_UNSPECIFIED = 0;
our $OdbSubnet_CLIENT_SUBNET = 1;
our $OdbSubnet_BACKUP_SUBNET = 2;

# Enum: OdbSubnet::State
our $OdbSubnet_STATE_UNSPECIFIED = 0;
our $OdbSubnet_PROVISIONING = 1;
our $OdbSubnet_AVAILABLE = 2;
our $OdbSubnet_TERMINATING = 3;
our $OdbSubnet_FAILED = 4;

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::CreateOdbSubnetRequest ===
    # Fields for CreateOdbSubnetRequest
    # Field: parent Type: 9 ()
    # Field: odb_subnet_id Type: 9 ()
    # Field: odb_subnet Type: 11 (.google.cloud.oracledatabase.v1.OdbSubnet)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::UpdateOdbSubnetRequest ===
    # Fields for UpdateOdbSubnetRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: odb_subnet Type: 11 (.google.cloud.oracledatabase.v1.OdbSubnet)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::DeleteOdbSubnetRequest ===
    # Fields for DeleteOdbSubnetRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsRequest ===
    # Fields for ListOdbSubnetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsResponse ===
    # Fields for ListOdbSubnetsResponse
    # Field: odb_subnets Type: 11 (.google.cloud.oracledatabase.v1.OdbSubnet)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbSubnet::GetOdbSubnetRequest ===
    # Fields for GetOdbSubnetRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::OdbSubnet - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/odb_subnet.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::OdbSubnet;

    my $msg = Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet->new({
        name => $name,
        cidr_range => $cidr_range,
        purpose => $purpose,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/odb_subnet.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet

Represents OdbSubnet resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the OdbSubnet resource in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}

=item * C<< $msg->cidr_range() >> / C<< $msg->cidr_range($value) >>

Type: C<String>

Required. Immutable. The CIDR range of the subnet.

=item * C<< $msg->purpose() >> / C<< $msg->purpose($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::OdbSubnet::Purpose>)

Required. Immutable. Purpose of the subnet.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet::LabelsEntry>)

Optional. Labels or tags associated with the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the OdbNetwork was created.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::OdbSubnet::State>)

Output only. State of the ODB Subnet.

=back

=head3 Enum: OdbSubnet::Purpose

=over 4

=item * C<PURPOSE_UNSPECIFIED> => C<0>

=item * C<CLIENT_SUBNET> => C<1>

=item * C<BACKUP_SUBNET> => C<2>

=back

=head3 Enum: OdbSubnet::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<TERMINATING> => C<3>

=item * C<FAILED> => C<4>

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::CreateOdbSubnetRequest

The request for `OdbSubnet.Create`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the OdbSubnet in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}.

=item * C<< $msg->odb_subnet_id() >> / C<< $msg->odb_subnet_id($value) >>

Type: C<String>

Required. The ID of the OdbSubnet to create. This value is restricted
to (^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$) and must be a maximum of 63
characters in length. The value must start with a letter and end with
a letter or a number.

=item * C<< $msg->odb_subnet() >> / C<< $msg->odb_subnet($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet>)

Required. Details of the OdbSubnet instance to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::UpdateOdbSubnetRequest

The request for `OdbSubnet.Update`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A mask specifying which fields in the OdbSubnet should be
updated. A field specified in the mask is updated. If a mask isn't
provided, the service treats this as an implied field mask equivalent to
all fields that are populated (have a non-empty value). To clear or unset a
field, the field must be explicitly specified in the `update_mask`.

=item * C<< $msg->odb_subnet() >> / C<< $msg->odb_subnet($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet>)

Required. The resource being updated. Note only labels can be updated.
The provided labels will completely replace the existing labels.
Any existing label keys that are not included in the update request will be
deleted. Not providing labels and update_mask will not update the labels.
To clear all labels, specify `labels` in the `update_mask` and omit or
leave the `labels` field empty in the update request.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::DeleteOdbSubnetRequest

The request for `OdbSubnet.Delete`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource in the following format:
projects/{project}/locations/{region}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsRequest

The request for `OdbSubnet.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the OdbSubnet in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, at most 50 ODB Networks will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression for ordering the results of the request.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsResponse

The response for `OdbSubnet.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->odb_subnets() >> / C<< $msg->odb_subnets($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet>)

The list of ODB Subnets.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable locations when listing resources across all locations using
wildcard location '-'.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbSubnet::GetOdbSubnetRequest

The request for `OdbSubnet.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the OdbSubnet in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::OdbSubnet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
