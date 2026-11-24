package Google::Cloud::Bigquery::Storage::V1alpha::Partition;

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
CjVnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWFscGhhL3BhcnRpdGlvbi5wcm90
bxIlZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFhbHBoYRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byI/CgtGaWVsZFNjaGVtYRIXCgRuYW1lGAEgASgJ
QgPgQQJSBG5hbWUSFwoEdHlwZRgCIAEoCUID4EECUgR0eXBlIuMBChFTdG9yYWdlRGVzY3Jp
cHRvchImCgxsb2NhdGlvbl91cmkYASABKAlCA+BBAVILbG9jYXRpb25VcmkSJgoMaW5wdXRf
Zm9ybWF0GAIgASgJQgPgQQFSC2lucHV0Rm9ybWF0EigKDW91dHB1dF9mb3JtYXQYAyABKAlC
A+BBAVIMb3V0cHV0Rm9ybWF0ElQKCnNlcmRlX2luZm8YBCABKAsyMC5nb29nbGUuY2xvdWQu
YmlncXVlcnkuc3RvcmFnZS52MWFscGhhLlNlckRlSW5mb0ID4EEBUglzZXJkZUluZm8ihAIK
CVNlckRlSW5mbxIXCgRuYW1lGAEgASgJQgPgQQFSBG5hbWUSOAoVc2VyaWFsaXphdGlvbl9s
aWJyYXJ5GAIgASgJQgPgQQJSFHNlcmlhbGl6YXRpb25MaWJyYXJ5EmUKCnBhcmFtZXRlcnMY
AyADKAsyQC5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWFscGhhLlNlckRlSW5m
by5QYXJhbWV0ZXJzRW50cnlCA+BBAVIKcGFyYW1ldGVycxo9Cg9QYXJhbWV0ZXJzRW50cnkS
EAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASLhAwoSTWV0YXN0
b3JlUGFydGl0aW9uEhsKBnZhbHVlcxgBIAMoCUID4EECUgZ2YWx1ZXMSQAoLY3JlYXRlX3Rp
bWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUS
bAoSc3RvcmFnZV9kZXNjcmlwdG9yGAMgASgLMjguZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0
b3JhZ2UudjFhbHBoYS5TdG9yYWdlRGVzY3JpcHRvckID4EEBUhFzdG9yYWdlRGVzY3JpcHRv
chJuCgpwYXJhbWV0ZXJzGAQgAygLMkkuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2Uu
djFhbHBoYS5NZXRhc3RvcmVQYXJ0aXRpb24uUGFyYW1ldGVyc0VudHJ5QgPgQQFSCnBhcmFt
ZXRlcnMSTwoGZmllbGRzGAUgAygLMjIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2Uu
djFhbHBoYS5GaWVsZFNjaGVtYUID4EEBUgZmaWVsZHMaPQoPUGFyYW1ldGVyc0VudHJ5EhAK
A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEieAoWTWV0YXN0b3Jl
UGFydGl0aW9uTGlzdBJeCgpwYXJ0aXRpb25zGAEgAygLMjkuZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5LnN0b3JhZ2UudjFhbHBoYS5NZXRhc3RvcmVQYXJ0aXRpb25CA+BBAlIKcGFydGl0aW9u
cyLAAQoKUmVhZFN0cmVhbRIaCgRuYW1lGAEgASgJQgbgQQPgQQhSBG5hbWU6lQHqQZEBCili
aWdxdWVyeXN0b3JhZ2UuZ29vZ2xlYXBpcy5jb20vUmVhZFN0cmVhbRJLcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nlc3Npb25zL3tzZXNzaW9ufS9zdHJlYW1z
L3tzdHJlYW19KgtyZWFkU3RyZWFtczIKcmVhZFN0cmVhbSJeCgpTdHJlYW1MaXN0ElAKB3N0
cmVhbXMYASADKAsyMS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWFscGhhLlJl
YWRTdHJlYW1CA+BBA1IHc3RyZWFtcyI3ChhNZXRhc3RvcmVQYXJ0aXRpb25WYWx1ZXMSGwoG
dmFsdWVzGAEgAygJQgPgQQJSBnZhbHVlc0LbAQopY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVy
eS5zdG9yYWdlLnYxYWxwaGFCF01ldGFzdG9yZVBhcnRpdGlvblByb3RvUAFaQ2Nsb3VkLmdv
b2dsZS5jb20vZ28vYmlncXVlcnkvc3RvcmFnZS9hcGl2MWFscGhhL3N0b3JhZ2VwYjtzdG9y
YWdlcGKqAiVHb29nbGUuQ2xvdWQuQmlnUXVlcnkuU3RvcmFnZS5WMUFscGhhygIlR29vZ2xl
XENsb3VkXEJpZ1F1ZXJ5XFN0b3JhZ2VcVjFhbHBoYUr3JwoHEgUOAIsBAQq8BAoBDBIDDgAS
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
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALgoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAKQoICgEIEgMWAEIKCQoCCCUSAxYAQgoICgEIEgMXAFoKCQoCCAsSAxcA
WgoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADgKCQoCCAgSAxkAOAoICgEIEgMaAEIK
CQoCCAESAxoAQgoICgEIEgMbAEMKCQoCCCkSAxsAQwpBCgIEABIEHgAmARo1IFNjaGVtYSBk
ZXNjcmlwdGlvbiBvZiBhIG1ldGFzdG9yZSBwYXJ0aXRpb24gY29sdW1uLgoKCgoDBAABEgMe
CBMKYwoEBAACABIDIQI7GlYgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjb2x1bW4uCiBU
aGUgbWF4aW11bSBsZW5ndGggb2YgdGhlIG5hbWUgaXMgMTAyNCBjaGFyYWN0ZXJzCgoMCgUE
AAIABRIDIQIICgwKBQQAAgABEgMhCQ0KDAoFBAACAAMSAyEQEQoMCgUEAAIACBIDIRI6Cg8K
CAQAAgAInAgAEgMhEzkKcAoEBAACARIDJQI7GmMgUmVxdWlyZWQuIFRoZSB0eXBlIG9mIHRo
ZSBtZXRhc3RvcmUgcGFydGl0aW9uIGNvbHVtbi4gTWF4aW11bSBhbGxvd2VkCiBsZW5ndGgg
aXMgMTAyNCBjaGFyYWN0ZXJzLgoKDAoFBAACAQUSAyUCCAoMCgUEAAIBARIDJQkNCgwKBQQA
AgEDEgMlEBEKDAoFBAACAQgSAyUSOgoPCggEAAIBCJwIABIDJRM5CmYKAgQBEgQqADwBGlog
Q29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHBoeXNpY2FsIHN0b3JhZ2Ugb2YgdGhl
IGRhdGEgaW4gdGhlIG1ldGFzdG9yZQogcGFydGl0aW9uLgoKCgoDBAEBEgMqCBkKtwEKBAQB
AgASAy4CQxqpASBPcHRpb25hbC4gVGhlIHBoeXNpY2FsIGxvY2F0aW9uIG9mIHRoZSBtZXRh
c3RvcmUgcGFydGl0aW9uCiAoZS5nLiBgZ3M6Ly9zcGFyay1kYXRhcHJvYy1kYXRhL3Bhbmdl
YS1kYXRhL2Nhc2Vfc2Vuc2l0aXZlL2Agb3IKIGBnczovL3NwYXJrLWRhdGFwcm9jLWRhdGEv
cGFuZ2VhLWRhdGEvKmApLgoKDAoFBAECAAUSAy4CCAoMCgUEAQIAARIDLgkVCgwKBQQBAgAD
EgMuGBkKDAoFBAECAAgSAy4aQgoPCggEAQIACJwIABIDLhtBCrcBCgQEAQIBEgMzAkMaqQEg
T3B0aW9uYWwuIFNwZWNpZmllcyB0aGUgZnVsbHkgcXVhbGlmaWVkIGNsYXNzIG5hbWUgb2Yg
dGhlIElucHV0Rm9ybWF0CiAoZS5nLiAib3JnLmFwYWNoZS5oYWRvb3AuaGl2ZS5xbC5pby5v
cmMuT3JjSW5wdXRGb3JtYXQiKS4KIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyAxMjggY2hhcmFj
dGVycy4KCgwKBQQBAgEFEgMzAggKDAoFBAECAQESAzMJFQoMCgUEAQIBAxIDMxgZCgwKBQQB
AgEIEgMzGkIKDwoIBAECAQicCAASAzMbQQq5AQoEBAECAhIDOAJEGqsBIE9wdGlvbmFsLiBT
cGVjaWZpZXMgdGhlIGZ1bGx5IHF1YWxpZmllZCBjbGFzcyBuYW1lIG9mIHRoZSBPdXRwdXRG
b3JtYXQKIChlLmcuICJvcmcuYXBhY2hlLmhhZG9vcC5oaXZlLnFsLmlvLm9yYy5PcmNPdXRw
dXRGb3JtYXQiKS4KIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyAxMjggY2hhcmFjdGVycy4KCgwK
BQQBAgIFEgM4AggKDAoFBAECAgESAzgJFgoMCgUEAQICAxIDOBkaCgwKBQQBAgIIEgM4G0MK
DwoIBAECAgicCAASAzgcQgpBCgQEAQIDEgM7AkQaNCBPcHRpb25hbC4gU2VyaWFsaXplciBh
bmQgZGVzZXJpYWxpemVyIGluZm9ybWF0aW9uLgoKDAoFBAECAwYSAzsCCwoMCgUEAQIDARID
OwwWCgwKBQQBAgMDEgM7GRoKDAoFBAECAwgSAzsbQwoPCggEAQIDCJwIABIDOxxCCjYKAgQC
EgQ/AE4BGiogU2VyaWFsaXplciBhbmQgZGVzZXJpYWxpemVyIGluZm9ybWF0aW9uLgoKCgoD
BAIBEgM/CBEKUgoEBAICABIDQgI7GkUgT3B0aW9uYWwuIE5hbWUgb2YgdGhlIFNlckRlLgog
VGhlIG1heGltdW0gbGVuZ3RoIGlzIDI1NiBjaGFyYWN0ZXJzLgoKDAoFBAICAAUSA0ICCAoM
CgUEAgIAARIDQgkNCgwKBQQCAgADEgNCEBEKDAoFBAICAAgSA0ISOgoPCggEAgIACJwIABID
QhM5CpQCCgQEAgIBEgNIAkwahgIgUmVxdWlyZWQuIFNwZWNpZmllcyBhIGZ1bGx5LXF1YWxp
ZmllZCBjbGFzcyBuYW1lIG9mIHRoZSBzZXJpYWxpemF0aW9uCiBsaWJyYXJ5IHRoYXQgaXMg
cmVzcG9uc2libGUgZm9yIHRoZSB0cmFuc2xhdGlvbiBvZiBkYXRhIGJldHdlZW4gdGFibGUK
IHJlcHJlc2VudGF0aW9uIGFuZCB0aGUgdW5kZXJseWluZyBsb3ctbGV2ZWwgaW5wdXQgYW5k
IG91dHB1dCBmb3JtYXQKIHN0cnVjdHVyZXMuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyAyNTYg
Y2hhcmFjdGVycy4KCgwKBQQCAgEFEgNIAggKDAoFBAICAQESA0gJHgoMCgUEAgIBAxIDSCEi
CgwKBQQCAgEIEgNII0sKDwoIBAICAQicCAASA0gkSgqIAQoEBAICAhIDTQJOGnsgT3B0aW9u
YWwuIEtleS12YWx1ZSBwYWlycyB0aGF0IGRlZmluZSB0aGUgaW5pdGlhbGl6YXRpb24gcGFy
YW1ldGVycyBmb3IgdGhlCiBzZXJpYWxpemF0aW9uIGxpYnJhcnkuCiBNYXhpbXVtIHNpemUg
MTAgS2liLgoKDAoFBAICAgYSA00CFQoMCgUEAgICARIDTRYgCgwKBQQCAgIDEgNNIyQKDAoF
BAICAggSA00lTQoPCggEAgICCJwIABIDTSZMCjEKAgQDEgRRAGYBGiUgSW5mb3JtYXRpb24g
YWJvdXQgYSBIaXZlIHBhcnRpdGlvbi4KCgoKAwQDARIDUQgaCtcBCgQEAwIAEgNVAkYayQEg
UmVxdWlyZWQuIFJlcHJlc2VudHMgdGhlIHZhbHVlcyBvZiB0aGUgcGFydGl0aW9uIGtleXMs
IHdoZXJlIGVhY2ggdmFsdWUKIGNvcnJlc3BvbmRzIHRvIGEgc3BlY2lmaWMgcGFydGl0aW9u
IGtleSBpbiB0aGUgb3JkZXIgaW4gd2hpY2ggdGhlIGtleXMgYXJlCiBkZWZpbmVkLiBFYWNo
IHZhbHVlIGlzIGxpbWl0ZWQgdG8gMTAyNCBjaGFyYWN0ZXJzLgoKDAoFBAMCAAQSA1UCCgoM
CgUEAwIABRIDVQsRCgwKBQQDAgABEgNVEhgKDAoFBAMCAAMSA1UbHAoMCgUEAwIACBIDVR1F
Cg8KCAQDAgAInAgAEgNVHkQKQAoEBAMCARIEWAJZMhoyIE91dHB1dCBvbmx5LiBUaGUgY3Jl
YXRpb24gdGltZSBvZiB0aGUgcGFydGl0aW9uLgoKDAoFBAMCAQYSA1gCGwoMCgUEAwIBARID
WBwnCgwKBQQDAgEDEgNYKisKDAoFBAMCAQgSA1kGMQoPCggEAwIBCJwIABIDWQcwCmgKBAQD
AgISBF0CXi8aWiBPcHRpb25hbC4gQ29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHBo
eXNpY2FsIHN0b3JhZ2Ugb2YgdGhlIGRhdGEgaW4KIHRoZSBwYXJ0aXRpb24uCgoMCgUEAwIC
BhIDXQITCgwKBQQDAgIBEgNdFCYKDAoFBAMCAgMSA10pKgoMCgUEAwICCBIDXgYuCg8KCAQD
AgIInAgAEgNeBy0KbwoEBAMCAxIDYgJOGmIgT3B0aW9uYWwuIEFkZGl0aW9uYWwgcGFyYW1l
dGVycyBvciBtZXRhZGF0YSBhc3NvY2lhdGVkIHdpdGggdGhlIHBhcnRpdGlvbi4KIE1heGlt
dW0gc2l6ZSAxMCBLaUIuCgoMCgUEAwIDBhIDYgIVCgwKBQQDAgMBEgNiFiAKDAoFBAMCAwMS
A2IjJAoMCgUEAwIDCBIDYiVNCg8KCAQDAgMInAgAEgNiJkwKKQoEBAMCBBIDZQJLGhwgT3B0
aW9uYWwuIExpc3Qgb2YgY29sdW1ucy4KCgwKBQQDAgQEEgNlAgoKDAoFBAMCBAYSA2ULFgoM
CgUEAwIEARIDZRcdCgwKBQQDAgQDEgNlICEKDAoFBAMCBAgSA2UiSgoPCggEAwIECJwIABID
ZSNJCisKAgQEEgRpAG0BGh8gTGlzdCBvZiBtZXRhc3RvcmUgcGFydGl0aW9ucy4KCgoKAwQE
ARIDaQgeCi0KBAQEAgASBGsCbC8aHyBSZXF1aXJlZC4gTGlzdCBvZiBwYXJ0aXRpb25zLgoK
DAoFBAQCAAQSA2sCCgoMCgUEBAIABhIDawsdCgwKBQQEAgABEgNrHigKDAoFBAQCAAMSA2sr
LAoMCgUEBAIACBIDbAYuCg8KCAQEAgAInAgAEgNsBy0KUAoCBAUSBHAAfgEaRCBJbmZvcm1h
dGlvbiBhYm91dCBhIHNpbmdsZSBzdHJlYW0gdGhhdCBpcyB1c2VkIHRvIHJlYWQgcGFydGl0
aW9ucy4KCgoKAwQFARIDcAgSCgsKAwQFBxIEcQJ2BAoNCgUEBQedCBIEcQJ2BAqiAQoEBAUC
ABIEegJ9BBqTASBPdXRwdXQgb25seS4gSWRlbnRpZmllci4gTmFtZSBvZiB0aGUgc3RyZWFt
LCBpbiB0aGUgZm9ybQogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9zZXNzaW9ucy97c2Vzc2lvbl9pZH0vc3RyZWFtcy97c3RyZWFtX2lkfWAuCgoMCgUE
BQIABRIDegIICgwKBQQFAgABEgN6CQ0KDAoFBAUCAAMSA3oQEQoNCgUEBQIACBIEehJ9AwoP
CggEBQIACJwIABIDewQtCg8KCAQFAgAInAgBEgN8BCwKIAoCBAYSBoEBAIQBARoSIExpc3Qg
b2Ygc3RyZWFtcy4KCgsKAwQGARIEgQEIEgotCgQEBgIAEgSDAQJOGh8gT3V0cHV0IG9ubHku
IExpc3Qgb2Ygc3RyZWFtcy4KCg0KBQQGAgAEEgSDAQIKCg0KBQQGAgAGEgSDAQsVCg0KBQQG
AgABEgSDARYdCg0KBQQGAgADEgSDASAhCg0KBQQGAgAIEgSDASJNChAKCAQGAgAInAgAEgSD
ASNMCj8KAgQHEgaHAQCLAQEaMSBSZXByZXNlbnRzIHRoZSB2YWx1ZXMgb2YgYSBtZXRhc3Rv
cmUgcGFydGl0aW9uLgoKCwoDBAcBEgSHAQggCqIBCgQEBwIAEgSKAQJGGpMBIFJlcXVpcmVk
LiBUaGUgdmFsdWVzIG9mIHRoZSBwYXJ0aXRpb24ga2V5cywgd2hlcmUgZWFjaCB2YWx1ZSBj
b3JyZXNwb25kcyB0bwogYSBzcGVjaWZpYyBwYXJ0aXRpb24ga2V5IGluIHRoZSBvcmRlciBp
biB3aGljaCB0aGUga2V5cyBhcmUgZGVmaW5lZC4KCg0KBQQHAgAEEgSKAQIKCg0KBQQHAgAF
EgSKAQsRCg0KBQQHAgABEgSKARIYCg0KBQQHAgADEgSKARscCg0KBQQHAgAIEgSKAR1FChAK
CAQHAgAInAgAEgSKAR5EYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::FieldSchema ===
    # Fields for FieldSchema
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::StorageDescriptor ===
    # Fields for StorageDescriptor
    # Field: location_uri Type: 9 ()
    # Field: input_format Type: 9 ()
    # Field: output_format Type: 9 ()
    # Field: serde_info Type: 11 (.google.cloud.bigquery.storage.v1alpha.SerDeInfo)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::SerDeInfo ===
    # Fields for SerDeInfo
    # Field: name Type: 9 ()
    # Field: serialization_library Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.bigquery.storage.v1alpha.SerDeInfo.ParametersEntry)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition ===
    # Fields for MetastorePartition
    # Field: values Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: storage_descriptor Type: 11 (.google.cloud.bigquery.storage.v1alpha.StorageDescriptor)
    # Field: parameters Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition.ParametersEntry)
    # Field: fields Type: 11 (.google.cloud.bigquery.storage.v1alpha.FieldSchema)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartitionList ===
    # Fields for MetastorePartitionList
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::ReadStream ===
    # Fields for ReadStream
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::StreamList ===
    # Fields for StreamList
    # Field: streams Type: 11 (.google.cloud.bigquery.storage.v1alpha.ReadStream)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartitionValues ===
    # Fields for MetastorePartitionValues
    # Field: values Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1alpha::Partition - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1alpha/partition.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1alpha::Partition;

    my $msg = Google::Cloud::Bigquery::Storage::V1alpha::Partition::FieldSchema->new({
        name => $name,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1alpha::Partition::FieldSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1alpha/partition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::FieldSchema

Schema description of a metastore partition column.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the column.
The maximum length of the name is 1024 characters

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The type of the metastore partition column. Maximum allowed
length is 1024 characters.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::StorageDescriptor

Contains information about the physical storage of the data in the metastore
partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location_uri() >> / C<< $msg->location_uri($value) >>

Type: C<String>

Optional. The physical location of the metastore partition
(e.g. `gs://spark-dataproc-data/pangea-data/case_sensitive/` or
`gs://spark-dataproc-data/pangea-data/*`).

=item * C<< $msg->input_format() >> / C<< $msg->input_format($value) >>

Type: C<String>

Optional. Specifies the fully qualified class name of the InputFormat
(e.g. "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat").
The maximum length is 128 characters.

=item * C<< $msg->output_format() >> / C<< $msg->output_format($value) >>

Type: C<String>

Optional. Specifies the fully qualified class name of the OutputFormat
(e.g. "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat").
The maximum length is 128 characters.

=item * C<< $msg->serde_info() >> / C<< $msg->serde_info($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::SerDeInfo>)

Optional. Serializer and deserializer information.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::SerDeInfo

Serializer and deserializer information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Name of the SerDe.
The maximum length is 256 characters.

=item * C<< $msg->serialization_library() >> / C<< $msg->serialization_library($value) >>

Type: C<String>

Required. Specifies a fully-qualified class name of the serialization
library that is responsible for the translation of data between table
representation and the underlying low-level input and output format
structures. The maximum length is 256 characters.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::SerDeInfo::ParametersEntry>)

Optional. Key-value pairs that define the initialization parameters for the
serialization library.
Maximum size 10 Kib.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition

Information about a Hive partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. Represents the values of the partition keys, where each value
corresponds to a specific partition key in the order in which the keys are
defined. Each value is limited to 1024 characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time of the partition.

=item * C<< $msg->storage_descriptor() >> / C<< $msg->storage_descriptor($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::StorageDescriptor>)

Optional. Contains information about the physical storage of the data in
the partition.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition::ParametersEntry>)

Optional. Additional parameters or metadata associated with the partition.
Maximum size 10 KiB.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::FieldSchema>)

Optional. List of columns.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartitionList

List of metastore partitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition>)

Required. List of partitions.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::ReadStream

Information about a single stream that is used to read partitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. Name of the stream, in the form
`projects/{project_id}/locations/{location}/sessions/{session_id}/streams/{stream_id}`.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::StreamList

List of streams.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->streams() >> / C<< $msg->streams($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::ReadStream>)

Output only. List of streams.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartitionValues

Represents the values of a metastore partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. The values of the partition keys, where each value corresponds to
a specific partition key in the order in which the keys are defined.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
