package Google::Cloud::Backupdr::V1::RestoreVerificationPlan;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvcmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbi5w
cm90bxIYZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byKmCAoXUmVzdG9yZVZlcmlmaWNhdGlvblBsYW4SGgoE
bmFtZRgBIAEoCUIG4EED4EEIUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rl
c2NyaXB0aW9uEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEloKBmxhYmVscxgFIAMoCzI9Lmdv
b2dsZS5jbG91ZC5iYWNrdXBkci52MS5SZXN0b3JlVmVyaWZpY2F0aW9uUGxhbi5MYWJlbHNF
bnRyeUID4EEBUgZsYWJlbHMSUgoFc3RhdGUYBiABKA4yNy5nb29nbGUuY2xvdWQuYmFja3Vw
ZHIudjEuUmVzdG9yZVZlcmlmaWNhdGlvblBsYW4uU3RhdGVCA+BBA1IFc3RhdGUSHwoIc2No
ZWR1bGUYByABKAlCA+BBAlIIc2NoZWR1bGUSIAoJdGltZV96b25lGAggASgJQgPgQQFSCHRp
bWVab25lEm8KFHN1Y2Nlc3NfY2xlYW51cF9ydWxlGAkgASgLMjguZ29vZ2xlLmNsb3VkLmJh
Y2t1cGRyLnYxLlJlc3RvcmVWZXJpZmljYXRpb25DbGVhbnVwUnVsZUID4EEBUhJzdWNjZXNz
Q2xlYW51cFJ1bGUSbwoUZmFpbHVyZV9jbGVhbnVwX3J1bGUYCiABKAsyOC5nb29nbGUuY2xv
dWQuYmFja3VwZHIudjEuUmVzdG9yZVZlcmlmaWNhdGlvbkNsZWFudXBSdWxlQgPgQQFSEmZh
aWx1cmVDbGVhbnVwUnVsZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2
YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIm0KBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAAS
DAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIMCghERUxFVElORxADEgwKCElOQUNUSVZFEAQS
DAoIVVBEQVRJTkcQBRIJCgVFUlJPUhAGOsQB6kHAAQovYmFja3VwZHIuZ29vZ2xlYXBpcy5j
b20vUmVzdG9yZVZlcmlmaWNhdGlvblBsYW4SWnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnMve3Jlc3RvcmVWZXJpZmlj
YXRpb25QbGFufSoYcmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zMhdyZXN0b3JlVmVyaWZpY2F0
aW9uUGxhbiKjAQoeUmVzdG9yZVZlcmlmaWNhdGlvbkNsZWFudXBSdWxlEkMKDWNsZWFudXBf
ZGVsYXkYASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBAVIMY2xlYW51cERl
bGF5EisKDHNraXBfY2xlYW51cBgCIAEoCEID4EEBSABSC3NraXBDbGVhbnVwiAEBQg8KDV9z
a2lwX2NsZWFudXAi3QIKJENyZWF0ZVJlc3RvcmVWZXJpZmljYXRpb25QbGFuUmVxdWVzdBJP
CgZwYXJlbnQYASABKAlCN+BBAvpBMRIvYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9y
ZVZlcmlmaWNhdGlvblBsYW5SBnBhcmVudBJEChxyZXN0b3JlX3ZlcmlmaWNhdGlvbl9wbGFu
X2lkGAIgASgJQgPgQQJSGXJlc3RvcmVWZXJpZmljYXRpb25QbGFuSWQScgoZcmVzdG9yZV92
ZXJpZmljYXRpb25fcGxhbhgDIAEoCzIxLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5SZXN0
b3JlVmVyaWZpY2F0aW9uUGxhbkID4EECUhdyZXN0b3JlVmVyaWZpY2F0aW9uUGxhbhIqCgpy
ZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkInAKIUdldFJlc3RvcmVW
ZXJpZmljYXRpb25QbGFuUmVxdWVzdBJLCgRuYW1lGAEgASgJQjfgQQL6QTEKL2JhY2t1cGRy
Lmdvb2dsZWFwaXMuY29tL1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuUgRuYW1lIvkBCiNMaXN0
UmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zUmVxdWVzdBJPCgZwYXJlbnQYASABKAlCN+BBAvpB
MRIvYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5SBnBh
cmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghv
cmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IuEBCiRMaXN0UmVzdG9yZVZlcmlmaWNhdGlv
blBsYW5zUmVzcG9uc2USbwoacmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbnMYASADKAsyMS5n
b29nbGUuY2xvdWQuYmFja3VwZHIudjEuUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5SGHJlc3Rv
cmVWZXJpZmljYXRpb25QbGFucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIroBCiREZWxldGVSZXN0
b3JlVmVyaWZpY2F0aW9uUGxhblJlcXVlc3QSSwoEbmFtZRgBIAEoCUI34EEC+kExCi9iYWNr
dXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVmVyaWZpY2F0aW9uUGxhblIEbmFtZRIqCgpy
ZXF1ZXN0X2lkGAIgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkEhkKBWZvcmNlGAMgASgI
QgPgQQFSBWZvcmNlQswBChxjb20uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxQhxSZXN0b3Jl
VmVyaWZpY2F0aW9uUGxhblByb3RvUAFaOGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIv
YXBpdjEvYmFja3VwZHJwYjtiYWNrdXBkcnBiqgIYR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYx
ygIYR29vZ2xlXENsb3VkXEJhY2t1cERSXFYx6gIbR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6
OlYxStpYCgcSBQ4AnwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACgKCQoC
AwQSAxYAKQoICgEIEgMYADUKCQoCCCUSAxgANQoICgEIEgMZAE8KCQoCCAsSAxkATwoICgEI
EgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAD0KCQoCCAgSAxsAPQoICgEIEgMcADUKCQoCCAES
AxwANQoICgEIEgMdADUKCQoCCCkSAx0ANQoICgEIEgMeADQKCQoCCC0SAx4ANAqXAgoCBAAS
BCQAegEaigIgQSBgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5gIHNwZWNpZmllcyB0aGUgc2No
ZWR1bGluZyBhbmQgY2xlYW4tdXAgdGVtcGxhdGUKIGZvciBhdXRvbWF0ZWQgcmVzdG9yZSB2
ZXJpZmljYXRpb24uIEl0IGNvbnRhaW5zIGEgYHNjaGVkdWxlYCB0byBkaWN0YXRlIHdoZW4K
IHRoZSB2ZXJpZmljYXRpb25zIHNob3VsZCBydW4sIGFuZCBhIGBSZXN0b3JlVmVyaWZpY2F0
aW9uQ2xlYW51cFJ1bGVgIGZvcgogcG9zdC12ZXJpZmljYXRpb24gcmVzb3VyY2UgZGVsZXRp
b24uCgoKCgMEAAESAyQIHwoLCgMEAAcSBCUCKgQKDQoFBAAHnQgSBCUCKgQKVwoEBAAEABIE
LQJCAxpJIGBTdGF0ZWAgZW51bWVyYXRlcyB0aGUgcG9zc2libGUgc3RhdGVzIGZvciBhIGBS
ZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAuCgoMCgUEAAQAARIDLQcMCh8KBgQABAACABIDLwQa
GhAgU3RhdGUgbm90IHNldC4KCg4KBwQABAACAAESAy8EFQoOCgcEAAQAAgACEgMvGBkKLwoG
BAAEAAIBEgMyBBEaICBUaGUgcmVzb3VyY2UgaXMgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAAC
AQESAzIEDAoOCgcEAAQAAgECEgMyDxAKQwoGBAAEAAICEgM1BA8aNCBUaGUgcmVzb3VyY2Ug
aGFzIGJlZW4gY3JlYXRlZCBhbmQgaXMgZnVsbHkgdXNhYmxlLgoKDgoHBAAEAAICARIDNQQK
Cg4KBwQABAACAgISAzUNDgovCgYEAAQAAgMSAzgEERogIFRoZSByZXNvdXJjZSBpcyBiZWlu
ZyBkZWxldGVkLgoKDgoHBAAEAAIDARIDOAQMCg4KBwQABAACAwISAzgPEApBCgYEAAQAAgQS
AzsEERoyIFRoZSByZXNvdXJjZSBoYXMgYmVlbiBjcmVhdGVkIGJ1dCBpcyBub3QgdXNhYmxl
LgoKDgoHBAAEAAIEARIDOwQMCg4KBwQABAACBAISAzsPEAovCgYEAAQAAgUSAz4EERogIFRo
ZSByZXNvdXJjZSBpcyBiZWluZyB1cGRhdGVkLgoKDgoHBAAEAAIFARIDPgQMCg4KBwQABAAC
BQISAz4PEApQCgYEAAQAAgYSA0EEDhpBIFRoZSByZXNvdXJjZSBpcyBpbiBhbiBlcnJvciBz
dGF0ZSBkdWUgdG8gYSBjb25maWd1cmF0aW9uIGlzc3VlLgoKDgoHBAAEAAIGARIDQQQJCg4K
BwQABAACBgISA0EMDQrGAQoEBAACABIESQJMBBq3ASBPdXRwdXQgb25seS4gSWRlbnRpZmll
ci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlCiBgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5g
LgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zL3tyZXN0b3JlVmVyaWZpY2F0aW9uUGxhbn1gCgoM
CgUEAAIABRIDSQIICgwKBQQAAgABEgNJCQ0KDAoFBAACAAMSA0kQEQoNCgUEAAIACBIESRJM
AwoPCggEAAIACJwIABIDSgQtCg8KCAQAAgAInAgBEgNLBCwKnAMKBAQAAgESA1UCQhqOAyBP
cHRpb25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBgUmVzdG9yZVZlcmlmaWNhdGlvblBs
YW5gIHJlc291cmNlLgoKIFRoZSBkZXNjcmlwdGlvbiBhbGxvd3MgZm9yIGFkZGl0aW9uYWwg
ZGV0YWlscyBhYm91dAogYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYCBhbmQgaXRzIHVzZSBj
YXNlcyB0byBiZSBwcm92aWRlZC4gQW4gZXhhbXBsZQogZGVzY3JpcHRpb24gaXMgdGhlIGZv
bGxvd2luZzogIlRoaXMgaXMgYSByZXN0b3JlIHZlcmlmaWNhdGlvbiBwbGFuIHRoYXQKIHBl
cmZvcm1zIGEgZGFpbHkgdmVyaWZpY2F0aW9uIGFuZCBjbGVhbnMgdXAgdGhlIHJlc291cmNl
cyBpbW1lZGlhdGVseQogYWZ0ZXIuIiBUaGUgZGVzY3JpcHRpb24gbXVzdCBiZSBhdCBtb3N0
IDIwNDggY2hhcmFjdGVycy4KCgwKBQQAAgEFEgNVAggKDAoFBAACAQESA1UJFAoMCgUEAAIB
AxIDVRcYCgwKBQQAAgEIEgNVGUEKDwoIBAACAQicCAASA1UaQApMCgQEAAICEgRYAlkyGj4g
T3V0cHV0IG9ubHkuIFdoZW4gdGhlIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAgd2FzIGNy
ZWF0ZWQuCgoMCgUEAAICBhIDWAIbCgwKBQQAAgIBEgNYHCcKDAoFBAACAgMSA1gqKwoMCgUE
AAICCBIDWQYxCg8KCAQAAgIInAgAEgNZBzAKUQoEBAACAxIEXAJdMhpDIE91dHB1dCBvbmx5
LiBXaGVuIHRoZSBgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5gIHdhcyBsYXN0IHVwZGF0ZWQu
CgoMCgUEAAIDBhIDXAIbCgwKBQQAAgMBEgNcHCcKDAoFBAACAwMSA1wqKwoMCgUEAAIDCBID
XQYxCg8KCAQAAgMInAgAEgNdBzAKLQoEBAACBBIDYAJKGiAgT3B0aW9uYWwuIFVzZXItZGVm
aW5lZCBsYWJlbHMuCgoMCgUEAAIEBhIDYAIVCgwKBQQAAgQBEgNgFhwKDAoFBAACBAMSA2Af
IAoMCgUEAAIECBIDYCFJCg8KCAQAAgQInAgAEgNgIkgKSgoEBAACBRIDYwI+Gj0gT3V0cHV0
IG9ubHkuIFRoZSBgU3RhdGVgIGZvciB0aGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYC4K
CgwKBQQAAgUGEgNjAgcKDAoFBAACBQESA2MIDQoMCgUEAAIFAxIDYxARCgwKBQQAAgUIEgNj
Ej0KDwoIBAACBQicCAASA2MTPArGAQoEBAACBhIDagI/GrgBIFJlcXVpcmVkLiBEZXNjcmli
ZXMgdGhlIHNjaGVkdWxlIG9uIHdoaWNoIHRoZSByZXN0b3JlIHZlcmlmaWNhdGlvbiB3aWxs
IGJlCiBleGVjdXRlZC4KCiBUaGUgc2NoZWR1bGUgaXMgc3BlY2lmaWVkIGFzIGEKIFtDcm9u
dGFiXShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9Dcm9uI092ZXJ2aWV3KSBzdHJp
bmcuCgoMCgUEAAIGBRIDagIICgwKBQQAAgYBEgNqCREKDAoFBAACBgMSA2oUFQoMCgUEAAIG
CBIDahY+Cg8KCAQAAgYInAgAEgNqFz0K0QIKBAQAAgcSA3ECQBrDAiBPcHRpb25hbC4gU3Bl
Y2lmaWVzIHRoZSB0aW1lIHpvbmUgdG8gYmUgdXNlZCBpbiBpbnRlcnByZXRpbmcKIFtzY2hl
ZHVsZV1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLlJlc3RvcmVWZXJpZmljYXRpb25QbGFu
LnNjaGVkdWxlXS4KIFRoZSB2YWx1ZSBvZiB0aGlzIGZpZWxkIG11c3QgYmUgYSB0aW1lIHpv
bmUgbmFtZSBmcm9tIHRoZSBbdHoKIGRhdGFiYXNlXShodHRwczovL2VuLndpa2lwZWRpYS5v
cmcvd2lraS9Uel9kYXRhYmFzZSksIGxpa2UKICJBbWVyaWNhL05ld19Zb3JrIiBvciAiVVRD
Ii4gRGVmYXVsdHMgdG8gYFVUQ2AgaWYgbm90IHNwZWNpZmllZC4KCgwKBQQAAgcFEgNxAggK
DAoFBAACBwESA3EJEgoMCgUEAAIHAxIDcRUWCgwKBQQAAgcIEgNxFz8KDwoIBAACBwicCAAS
A3EYPgpZCgQEAAIIEgR0AnUvGksgT3B0aW9uYWwuIFRoZSBjbGVhbnVwIHJ1bGUgdG8gYXBw
bHkgaWYgdGhlIHJlc3RvcmUgdmVyaWZpY2F0aW9uIHN1Y2NlZWRzLgoKDAoFBAACCAYSA3QC
IAoMCgUEAAIIARIDdCE1CgwKBQQAAggDEgN0ODkKDAoFBAACCAgSA3UGLgoPCggEAAIICJwI
ABIDdQctClYKBAQAAgkSBHgCeS8aSCBPcHRpb25hbC4gVGhlIGNsZWFudXAgcnVsZSB0byBh
cHBseSBpZiB0aGUgcmVzdG9yZSB2ZXJpZmljYXRpb24gZmFpbHMuCgoMCgUEAAIJBhIDeAIg
CgwKBQQAAgkBEgN4ITUKDAoFBAACCQMSA3g4OgoMCgUEAAIJCBIDeQYuCg8KCAQAAgkInAgA
EgN5By0KMwoCBAESBX0AhQEBGiYgRGVmaW5lcyB0aGUgc3BlY2lmaWMgY2xlYW51cCBhY3Rp
b24uCgoKCgMEAQESA30IJgqWAQoEBAECABIGgAECgQEvGoUBIE9wdGlvbmFsLiBEdXJhdGlv
biBhZnRlciByZXN0b3JlIGZpbmlzaGVzIHdoZW4gY2xlYW51cCB0cmlnZ2Vycy4KIERlbGF5
IG11c3QgYmUgbm9uLW5lZ2F0aXZlIGFuZCBhdCBtb3N0IDMwIGRheXMgKDI1OTIwMDAgc2Vj
b25kcykuCgoNCgUEAQIABhIEgAECGgoNCgUEAQIAARIEgAEbKAoNCgUEAQIAAxIEgAErLAoN
CgUEAQIACBIEgQEGLgoQCggEAQIACJwIABIEgQEHLQpXCgQEAQIBEgSEAQJKGkkgT3B0aW9u
YWwuIElmIHNldCB0byB0cnVlLCB0aGUgcmVzdG9yZWQgcmVzb3VyY2Ugd2lsbCBub3QgYmUg
Y2xlYW5lZCB1cC4KCg0KBQQBAgEEEgSEAQIKCg0KBQQBAgEFEgSEAQsPCg0KBQQBAgEBEgSE
ARAcCg0KBQQBAgEDEgSEAR8gCg0KBQQBAgEIEgSEASFJChAKCAQBAgEInAgAEgSEASJICk0K
AgQCEgaIAQCvAQEaPyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBjcmVhdGluZyBhIGBSZXN0
b3JlVmVyaWZpY2F0aW9uUGxhbmAuCgoLCgMEAgESBIgBCCwK7AEKBAQCAgASBowBApEBBBrb
ASBSZXF1aXJlZC4gVGhlIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAgcHJvamVjdCBhbmQg
bG9jYXRpb24gaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufWAuIEluIEdvb2dsZSBDbG91ZCBCYWNrdXAgYW5kIERSCiBsb2NhdGlvbnMg
bWFwIHRvIEdvb2dsZSBDbG91ZCByZWdpb25zLCBmb3IgZXhhbXBsZSAqKnVzLWNlbnRyYWwx
KiouCgoNCgUEAgIABRIEjAECCAoNCgUEAgIAARIEjAEJDwoNCgUEAgIAAxIEjAESEwoPCgUE
AgIACBIGjAEUkQEDChAKCAQCAgAInAgAEgSNAQQqChEKBwQCAgAInwgSBo4BBJABBQqmAgoE
BAICARIGlwECmAEvGpUCIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYFJlc3RvcmVWZXJp
ZmljYXRpb25QbGFuYCB0byBjcmVhdGUuIFRoZSBuYW1lCiBtdXN0IGJlIHVuaXF1ZSBmb3Ig
dGhlIHNwZWNpZmllZCBwcm9qZWN0IGFuZCBsb2NhdGlvbi4gVGhlIG5hbWUgbXVzdCBzdGFy
dAogd2l0aCBhIGxvd2VyY2FzZSBsZXR0ZXIgZm9sbG93ZWQgYnkgdXAgdG8gNjIgbG93ZXJj
YXNlIGxldHRlcnMsIG51bWJlcnMsIG9yCiBoeXBoZW5zLiBQYXR0ZXJuLCBgXlthLXpdKFst
YS16MC05XSpbYS16MC05XSk/JGAuCgoNCgUEAgIBBRIElwECCAoNCgUEAgIBARIElwEJJQoN
CgUEAgIBAxIElwEoKQoNCgUEAgIBCBIEmAEGLgoQCggEAgIBCJwIABIEmAEHLQpUCgQEAgIC
EgabAQKcAS8aRCBSZXF1aXJlZC4gVGhlIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAgcmVz
b3VyY2Ugb2JqZWN0IHRvIGNyZWF0ZS4KCg0KBQQCAgIGEgSbAQIZCg0KBQQCAgIBEgSbARoz
Cg0KBQQCAgIDEgSbATY3Cg0KBQQCAgIIEgScAQYuChAKCAQCAgIInAgAEgScAQctCpEGCgQE
AgIDEgarAQKuAQQagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRl
bnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBp
ZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRv
CiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQu
IFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0
ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEg
c2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRoZSBy
ZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0
aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwg
b3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQg
aWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwog
Y2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVu
dHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhj
ZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAw
LTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAICAwUSBKsBAggKDQoFBAICAwESBKsB
CRMKDQoFBAICAwMSBKsBFhcKDwoFBAICAwgSBqsBGK4BAwoTCgsEAgIDCMzx+YoBARIErAEE
KgoQCggEAgIDCJwIABIErQEEKgpMCgIEAxIGsgEAvQEBGj4gVGhlIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgZ2V0dGluZyBhIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAuCgoLCgMEAwESBLIB
CCkKxAEKBAQDAgASBrcBArwBBBqzASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAgdG8gcmV0cmlldmUuCgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZp
Y2F0aW9uUGxhbnMve3Jlc3RvcmVWZXJpZmljYXRpb25QbGFufWAKCg0KBQQDAgAFEgS3AQII
Cg0KBQQDAgABEgS3AQkNCg0KBQQDAgADEgS3ARARCg8KBQQDAgAIEga3ARK8AQMKEAoIBAMC
AAicCAASBLgBBCoKEQoHBAMCAAifCBIGuQEEuwEFClUKAgQEEgbAAQDkAQEaRyBUaGUgcmVx
dWVzdCBtZXNzYWdlIGZvciBnZXR0aW5nIGEgbGlzdCBvZiBgUmVzdG9yZVZlcmlmaWNhdGlv
blBsYW5zYC4KCgsKAwQEARIEwAEIKwrsAgoEBAQCABIGxwECzAEEGtsCIFJlcXVpcmVkLiBU
aGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZm9yIHdoaWNoIHRvIHJldHJpZXZlCiBgUmVzdG9y
ZVZlcmlmaWNhdGlvblBsYW5zYCBpbmZvcm1hdGlvbi4gRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAuIEluIEdvb2dsZSBDbG91ZCBCYWNrdXAg
YW5kIERSLAogbG9jYXRpb25zIG1hcCB0byBHb29nbGUgQ2xvdWQgcmVnaW9ucywgZm9yIGV4
YW1wbGUgKip1cy1jZW50cmFsMSoqLiBUbwogcmV0cmlldmUgcmVzdG9yZSB2ZXJpZmljYXRp
b24gcGxhbnMgZm9yIGFsbCBsb2NhdGlvbnMsIHVzZQogIi0iIGZvciB0aGUgYHtsb2NhdGlv
bn1gIHZhbHVlLgoKDQoFBAQCAAUSBMcBAggKDQoFBAQCAAESBMcBCQ8KDQoFBAQCAAMSBMcB
EhMKDwoFBAQCAAgSBscBFMwBAwoQCggEBAIACJwIABIEyAEEKgoRCgcEBAIACJ8IEgbJAQTL
AQUKsQMKBAQEAgESBNQBAj8aogMgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBg
UmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zYCB0byByZXR1cm4gaW4gYQogc2luZ2xlIHJlc3Bv
bnNlLiBJZiBub3Qgc3BlY2lmaWVkLCBhIGRlZmF1bHQgdmFsdWUgd2lsbCBiZSBjaG9zZW4g
YnkgdGhlCiBzZXJ2aWNlLiBOb3RlIHRoYXQgdGhlIHJlc3BvbnNlIG1heSBpbmNsdWRlIGEg
cGFydGlhbCBsaXN0IGFuZCBhIGNhbGxlcgogc2hvdWxkIG9ubHkgcmVseSBvbiB0aGUgcmVz
cG9uc2UncwogW25leHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkxp
c3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dCiB0
byBkZXRlcm1pbmUgaWYgdGhlcmUgYXJlIG1vcmUgaW5zdGFuY2VzIGxlZnQgdG8gYmUgcXVl
cmllZC4KCg0KBQQEAgEFEgTUAQIHCg0KBQQEAgEBEgTUAQgRCg0KBQQEAgEDEgTUARQVCg0K
BQQEAgEIEgTUARY+ChAKCAQEAgEInAgAEgTUARc9Cp0DCgQEBAICEgTdAQJBGo4DIE9wdGlv
bmFsLiBUaGUgdmFsdWUgb2YKIFtuZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5iYWNr
dXBkci52MS5MaXN0UmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zUmVzcG9uc2UubmV4dF9wYWdl
X3Rva2VuXQogcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0UmVzdG9yZVZlcmlmaWNh
dGlvblBsYW5zYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1
ZW50IHBhZ2UgaW4gYSBtdWx0aS1wYWdlIGxpc3Qgb2YKIHJlc3VsdHMuIFdoZW4gcGFnaW5h
dGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8KIGBMaXN0UmVzdG9yZVZl
cmlmaWNhdGlvblBsYW5zYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhl
IHBhZ2UKIHRva2VuLgoKDQoFBAQCAgUSBN0BAggKDQoFBAQCAgESBN0BCRMKDQoFBAQCAgMS
BN0BFhcKDQoFBAQCAggSBN0BGEAKEAoIBAQCAgicCAASBN0BGT8KTAoEBAQCAxIE4AECPRo+
IE9wdGlvbmFsLiBGaWVsZCBtYXRjaCBleHByZXNzaW9uIHVzZWQgdG8gZmlsdGVyIHRoZSBy
ZXN1bHRzLgoKDQoFBAQCAwUSBOABAggKDQoFBAQCAwESBOABCQ8KDQoFBAQCAwMSBOABEhMK
DQoFBAQCAwgSBOABFDwKEAoIBAQCAwicCAASBOABFTsKPQoEBAQCBBIE4wECPxovIE9wdGlv
bmFsLiBGaWVsZCBieSB3aGljaCB0byBzb3J0IHRoZSByZXN1bHRzLgoKDQoFBAQCBAUSBOMB
AggKDQoFBAQCBAESBOMBCREKDQoFBAQCBAMSBOMBFBUKDQoFBAQCBAgSBOMBFj4KEAoIBAQC
BAicCAASBOMBFz0KVgoCBAUSBucBAPsBARpIIFRoZSByZXNwb25zZSBtZXNzYWdlIGZvciBn
ZXR0aW5nIGEgbGlzdCBvZiBgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zYC4KCgsKAwQFARIE
5wEILAqhAwoEBAUCABIE8AECQhqSAyBUaGUgbGlzdCBvZiBgUmVzdG9yZVZlcmlmaWNhdGlv
blBsYW5zYCBpbiB0aGUgcHJvamVjdCBmb3IgdGhlIHNwZWNpZmllZAogbG9jYXRpb24uCgog
SWYgdGhlIGB7bG9jYXRpb259YCB2YWx1ZSBpbiB0aGUgcmVxdWVzdCBpcyAiLSIsIHRoZSBy
ZXNwb25zZSBjb250YWlucyBhCiBsaXN0IG9mIHJlc291cmNlcyBmcm9tIGFsbCBsb2NhdGlv
bnMuIEluIGNhc2UgYW55IGxvY2F0aW9uIGlzIHVucmVhY2hhYmxlLAogdGhlIHJlc3BvbnNl
IHdpbGwgb25seSByZXR1cm4gcmVzdG9yZSB2ZXJpZmljYXRpb24gcGxhbnMgaW4gcmVhY2hh
YmxlCiBsb2NhdGlvbnMgYW5kIHRoZSAndW5yZWFjaGFibGUnIGZpZWxkIHdpbGwgYmUgcG9w
dWxhdGVkIHdpdGggYSBsaXN0IG9mCiB1bnJlYWNoYWJsZSBsb2NhdGlvbnMuCgoNCgUEBQIA
BBIE8AECCgoNCgUEBQIABhIE8AELIgoNCgUEBQIAARIE8AEjPQoNCgUEBQIAAxIE8AFAQQqu
AgoEBAUCARIE9wECHRqfAiBBIHRva2VuIHdoaWNoIG1heSBiZSBzZW50IGFzCiBbcGFnZV90
b2tlbl1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkxpc3RSZXN0b3JlVmVyaWZpY2F0aW9u
UGxhbnNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiBpbiBhIHN1YnNlcXVlbnQgYExpc3RSZXN0b3Jl
VmVyaWZpY2F0aW9uUGxhbnNgIGNhbGwgdG8gcmV0cmlldmUgdGhlIG5leHQKIHBhZ2Ugb2Yg
cmVzdWx0cy4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkIG9yIGVtcHR5LCB0aGVuIHRoZXJl
IGFyZSBubyBtb3JlCiByZXN1bHRzIHRvIHJldHVybi4KCg0KBQQFAgEFEgT3AQIICg0KBQQF
AgEBEgT3AQkYCg0KBQQFAgEDEgT3ARscCjQKBAQFAgISBPoBAiIaJiBMb2NhdGlvbnMgdGhh
dCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQFAgIEEgT6AQIKCg0KBQQFAgIFEgT6AQsR
Cg0KBQQFAgIBEgT6ARIdCg0KBQQFAgIDEgT6ASAhCk0KAgQGEgb+AQCfAgEaPyBUaGUgcmVx
dWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAu
CgoLCgMEBgESBP4BCCwKwgEKBAQGAgASBoMCAogCBBqxASBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAgdG8gZGVsZXRlLgoK
IEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVz
dG9yZVZlcmlmaWNhdGlvblBsYW5zL3tyZXN0b3JlVmVyaWZpY2F0aW9uUGxhbn1gCgoNCgUE
BgIABRIEgwICCAoNCgUEBgIAARIEgwIJDQoNCgUEBgIAAxIEgwIQEQoPCgUEBgIACBIGgwIS
iAIDChAKCAQGAgAInAgAEgSEAgQqChEKBwQGAgAInwgSBoUCBIcCBQqRBgoEBAYCARIGlwIC
mgIEGoAGIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJl
cXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11
c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3Jl
IHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2Vy
dmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIGFmdGVy
IHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlv
biB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUgcmVxdWVzdCB0
aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUg
cmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlv
biB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3
aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMg
ZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRo
ZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0
aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAw
MDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQGAgEFEgSXAgIICg0KBQQGAgEBEgSXAgkTCg0KBQQG
AgEDEgSXAhYXCg8KBQQGAgEIEgaXAhiaAgMKEwoLBAYCAQjM8fmKAQESBJgCBCoKEAoIBAYC
AQicCAASBJkCBCoKkAEKBAQGAgISBJ4CAjoagQEgT3B0aW9uYWwuIElmIHNldCB0byB0cnVl
LCBhbnkgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbnMgbGlua2VkIHRvCiB0
aGlzIFJlc3RvcmVWZXJpZmljYXRpb25QbGFuIHdpbGwgYWxzbyBiZSBkZWxldGVkLgoKDQoF
BAYCAgUSBJ4CAgYKDQoFBAYCAgESBJ4CBwwKDQoFBAYCAgMSBJ4CDxAKDQoFBAYCAggSBJ4C
ETkKEAoIBAYCAgicCAASBJ4CEjhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan ===
    # Fields for RestoreVerificationPlan
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationPlan.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.backupdr.v1.RestoreVerificationPlan.State)
    # Field: schedule Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: success_cleanup_rule Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationCleanupRule)
    # Field: failure_cleanup_rule Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationCleanupRule)

# Enum: RestoreVerificationPlan::State
our $RestoreVerificationPlan_STATE_UNSPECIFIED = 0;
our $RestoreVerificationPlan_CREATING = 1;
our $RestoreVerificationPlan_ACTIVE = 2;
our $RestoreVerificationPlan_DELETING = 3;
our $RestoreVerificationPlan_INACTIVE = 4;
our $RestoreVerificationPlan_UPDATING = 5;
our $RestoreVerificationPlan_ERROR = 6;

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule ===
    # Fields for RestoreVerificationCleanupRule
    # Field: cleanup_delay Type: 11 (.google.protobuf.Duration)
    # Field: skip_cleanup Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest ===
    # Fields for CreateRestoreVerificationPlanRequest
    # Field: parent Type: 9 ()
    # Field: restore_verification_plan_id Type: 9 ()
    # Field: restore_verification_plan Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationPlan)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::GetRestoreVerificationPlanRequest ===
    # Fields for GetRestoreVerificationPlanRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansRequest ===
    # Fields for ListRestoreVerificationPlansRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansResponse ===
    # Fields for ListRestoreVerificationPlansResponse
    # Field: restore_verification_plans Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationPlan)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest ===
    # Fields for DeleteRestoreVerificationPlanRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: force Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreVerificationPlan - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/restore_verification_plan.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::RestoreVerificationPlan;

    my $msg = Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/restore_verification_plan.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan

A `RestoreVerificationPlan` specifies the scheduling and clean-up template
for automated restore verification. It contains a `schedule` to dictate when
the verifications should run, and a `RestoreVerificationCleanupRule` for
post-verification resource deletion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
`RestoreVerificationPlan`.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restoreVerificationPlan}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the `RestoreVerificationPlan` resource.

The description allows for additional details about
`RestoreVerificationPlan` and its use cases to be provided. An example
description is the following: "This is a restore verification plan that
performs a daily verification and cleans up the resources immediately
after." The description must be at most 2048 characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the `RestoreVerificationPlan` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the `RestoreVerificationPlan` was last updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan::LabelsEntry>)

Optional. User-defined labels.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::State>)

Output only. The `State` for the `RestoreVerificationPlan`.

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<String>

Required. Describes the schedule on which the restore verification will be
executed.

The schedule is specified as a
[Crontab](https://en.wikipedia.org/wiki/Cron#Overview) string.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Optional. Specifies the time zone to be used in interpreting
[schedule][google.cloud.backupdr.v1.RestoreVerificationPlan.schedule].
The value of this field must be a time zone name from the [tz
database](https://en.wikipedia.org/wiki/Tz_database), like
"America/New_York" or "UTC". Defaults to `UTC` if not specified.

=item * C<< $msg->success_cleanup_rule() >> / C<< $msg->success_cleanup_rule($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule>)

Optional. The cleanup rule to apply if the restore verification succeeds.

=item * C<< $msg->failure_cleanup_rule() >> / C<< $msg->failure_cleanup_rule($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule>)

Optional. The cleanup rule to apply if the restore verification fails.

=back

=head3 Enum: RestoreVerificationPlan::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=item * C<INACTIVE> => C<4>

=item * C<UPDATING> => C<5>

=item * C<ERROR> => C<6>

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule

Defines the specific cleanup action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cleanup_delay() >> / C<< $msg->cleanup_delay($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Duration after restore finishes when cleanup triggers.
Delay must be non-negative and at most 30 days (2592000 seconds).

=item * C<< $msg->skip_cleanup() >> / C<< $msg->skip_cleanup($value) >>

Type: C<Bool>

Optional. If set to true, the restored resource will not be cleaned up.

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest

The request message for creating a `RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The `RestoreVerificationPlan` project and location in the format
`projects/{project}/locations/{location}`. In Google Cloud Backup and DR
locations map to Google Cloud regions, for example B<us-central1>.

=item * C<< $msg->restore_verification_plan_id() >> / C<< $msg->restore_verification_plan_id($value) >>

Type: C<String>

Required. The name of the `RestoreVerificationPlan` to create. The name
must be unique for the specified project and location. The name must start
with a lowercase letter followed by up to 62 lowercase letters, numbers, or
hyphens. Pattern, `^[a-z]([-a-z0-9]*[a-z0-9])?$`.

=item * C<< $msg->restore_verification_plan() >> / C<< $msg->restore_verification_plan($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan>)

Required. The `RestoreVerificationPlan` resource object to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::GetRestoreVerificationPlanRequest

The request message for getting a `RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `RestoreVerificationPlan` to retrieve.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restoreVerificationPlan}`

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansRequest

The request message for getting a list of `RestoreVerificationPlans`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve
`RestoreVerificationPlans` information. Format:
`projects/{project}/locations/{location}`. In Google Cloud Backup and DR,
locations map to Google Cloud regions, for example B<us-central1>. To
retrieve restore verification plans for all locations, use
"-" for the `{location}` value.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `RestoreVerificationPlans` to return in a
single response. If not specified, a default value will be chosen by the
service. Note that the response may include a partial list and a caller
should only rely on the response's
[next_page_token][google.cloud.backupdr.v1.ListRestoreVerificationPlansResponse.next_page_token]
to determine if there are more instances left to be queried.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value of
[next_page_token][google.cloud.backupdr.v1.ListRestoreVerificationPlansResponse.next_page_token]
received from a previous `ListRestoreVerificationPlans` call.
Provide this to retrieve the subsequent page in a multi-page list of
results. When paginating, all other parameters provided to
`ListRestoreVerificationPlans` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Field match expression used to filter the results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field by which to sort the results.

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansResponse

The response message for getting a list of `RestoreVerificationPlans`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_verification_plans() >> / C<< $msg->restore_verification_plans($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan>)

The list of `RestoreVerificationPlans` in the project for the specified
location.

If the `{location}` value in the request is "-", the response contains a
list of resources from all locations. In case any location is unreachable,
the response will only return restore verification plans in reachable
locations and the 'unreachable' field will be populated with a list of
unreachable locations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token which may be sent as
[page_token][google.cloud.backupdr.v1.ListRestoreVerificationPlansRequest.page_token]
in a subsequent `ListRestoreVerificationPlans` call to retrieve the next
page of results. If this field is omitted or empty, then there are no more
results to return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest

The request message for deleting a `RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `RestoreVerificationPlan` to delete.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restoreVerificationPlan}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, any RestoreVerificationPlanAssociations linked to
this RestoreVerificationPlan will also be deleted.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::RestoreVerificationPlan::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
