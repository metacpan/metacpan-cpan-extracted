package Google::Cloud::Oracledatabase::V1::ExecuteSql;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZXhlY3V0ZV9zcWwucHJvdG8SHmdv
b2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1
cmF0aW9uLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvItYBChFFeGVjdXRl
U3FsUmVxdWVzdBJMCgRuYW1lGAEgASgJQjjgQQL6QTIKMG9yYWNsZWRhdGFiYXNlLmdvb2ds
ZWFwaXMuY29tL0RhdGFiYXNlQ29ubmVjdGlvblIEbmFtZRIoCg1zcWxfc3RhdGVtZW50GAIg
ASgJQgPgQQJSDHNxbFN0YXRlbWVudBJJCgZwYXJhbXMYAyADKAsyLC5nb29nbGUuY2xvdWQu
b3JhY2xlZGF0YWJhc2UudjEuU3FsUGFyYW1ldGVyQgPgQQFSBnBhcmFtcyJ8CgxTcWxQYXJh
bWV0ZXISFwoEbmFtZRgBIAEoCUID4EEBUgRuYW1lEjEKBXZhbHVlGAIgASgLMhYuZ29vZ2xl
LnByb3RvYnVmLlZhbHVlQgPgQQJSBXZhbHVlEiAKCXR5cGVfbmFtZRgDIAEoCUID4EEBUgh0
eXBlTmFtZSKwAQoSRXhlY3V0ZVNxbFJlc3BvbnNlEkoKC3NxbF9yZXN1bHRzGAEgAygLMiku
Z29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLlNxbFJlc3VsdFIKc3FsUmVzdWx0cxJO
CghtZXRhZGF0YRgCIAEoCzIyLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5FeGVj
dXRlU3FsTWV0YWRhdGFSCG1ldGFkYXRhIvgCCglTcWxSZXN1bHQSSgoHY29sdW1ucxgBIAMo
CzIwLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5TcWxSZXN1bHQuQ29sdW1uUgdj
b2x1bW5zEkEKBHJvd3MYAiADKAsyLS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEu
U3FsUmVzdWx0LlJvd1IEcm93cxo6CgZDb2x1bW4SFwoEbmFtZRgBIAEoCUID4EECUgRuYW1l
EhcKBHR5cGUYAiABKAlCA+BBAlIEdHlwZRpOCgNSb3cSRwoGdmFsdWVzGAEgAygLMi8uZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLlNxbFJlc3VsdC5WYWx1ZVIGdmFsdWVzGlAK
BVZhbHVlEhQKBXZhbHVlGAEgASgJUgV2YWx1ZRIiCgpudWxsX3ZhbHVlGAIgASgISABSCW51
bGxWYWx1ZYgBAUINCgtfbnVsbF92YWx1ZSK5AgoSRXhlY3V0ZVNxbE1ldGFkYXRhEhgKB21l
c3NhZ2UYASABKAlSB21lc3NhZ2USJQoOcGFydGlhbF9yZXN1bHQYAiABKAhSDXBhcnRpYWxS
ZXN1bHQSSAoSZXhlY3V0aW9uX2R1cmF0aW9uGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1
cmF0aW9uUhFleGVjdXRpb25EdXJhdGlvbhJWCgZzdGF0dXMYBCABKA4yOS5nb29nbGUuY2xv
dWQub3JhY2xlZGF0YWJhc2UudjEuRXhlY3V0ZVNxbE1ldGFkYXRhLlN0YXR1c0ID4EEDUgZz
dGF0dXMiQAoGU3RhdHVzEhYKElNUQVRVU19VTlNQRUNJRklFRBAAEgYKAk9LEAESCwoHUEFS
VElBTBACEgkKBUVSUk9SEANC6QEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2Uu
djFCD0V4ZWN1dGVTcWxQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFi
YXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5D
bG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxW
MeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUrbLAoHEgUOAJcBAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAKAoJCgIDAxIDFQAmCggKAQgSAxcAOwoJCgIIJRIDFwA7CggK
AQgSAxgAYQoJCgIICxIDGABhCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMAoJCgII
CBIDGgAwCggKAQgSAxsAOwoJCgIIARIDGwA7CggKAQgSAxwAOwoJCgIIKRIDHAA7CggKAQgS
Ax0AOgoJCgIILRIDHQA6Cj4KAgQAEgQgADEBGjIgVGhlIHJlcXVlc3QgZm9yIGBEYXRhYmFz
ZUNvbm5lY3Rpb24uRXhlY3V0ZVNxbGAuCgoKCgMEAAESAyAIGQqqAQoEBAACABIEIwIoBBqb
ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIERhdGFiYXNlQ29ubmVjdGlvbiBpbiB0aGUg
Zm9sbG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9kYXRhYmFzZUNvbm5lY3Rpb25zL3tkYXRhYmFzZV9jb25uZWN0aW9ufS4KCgwKBQQA
AgAFEgMjAggKDAoFBAACAAESAyMJDQoMCgUEAAIAAxIDIxARCg0KBQQAAgAIEgQjEigDCg8K
CAQAAgAInAgAEgMkBCoKDwoHBAACAAifCBIEJQQnBQo2CgQEAAIBEgMrAkQaKSBSZXF1aXJl
ZC4gVGhlIFNRTCBzdGF0ZW1lbnQgdG8gZXhlY3V0ZS4KCgwKBQQAAgEFEgMrAggKDAoFBAAC
AQESAysJFgoMCgUEAAIBAxIDKxkaCgwKBQQAAgEIEgMrG0MKDwoIBAACAQicCAASAyscQgrN
AQoEBAACAhIDMAJMGr8BIE9wdGlvbmFsLiBPcHRpb25hbDogQmluZCB2YXJpYWJsZXMgKHBh
cmFtZXRlcnMpIHRvIGJlIHVzZWQgd2l0aCB0aGUgU1FMCiBzdGF0ZW1lbnQuIFN1cHBvcnRz
IG5hbWVkIGJpbmQgdmFyaWFibGVzIChlLmcuLCA6ZGVwdF9pZCwgOnN0YXR1cyBpbiBPcmFj
bGUKIFNRTCkgb3IgcG9zaXRpb25hbCBwYXJhbWV0ZXJzICg6MSwgOjIpLgoKDAoFBAACAgQS
AzACCgoMCgUEAAICBhIDMAsXCgwKBQQAAgIBEgMwGB4KDAoFBAACAgMSAzAhIgoMCgUEAAIC
CBIDMCNLCg8KCAQAAgIInAgAEgMwJEoKRwoCBAESBDQAQgEaOyBSZXByZXNlbnRzIGEgYmlu
ZCB2YXJpYWJsZSAocGFyYW1ldGVyKSBmb3IgU1FMIGV4ZWN1dGlvbi4KCgoKAwQBARIDNAgU
CrMBCgQEAQIAEgM4AjsapQEgT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRoZSBTUUwgYmluZCBw
YXJhbWV0ZXIgKGV4Y2x1ZGluZyB0aGUgbGVhZGluZwogY29sb24sIGUuZy4gImlkIikuIElm
IG9taXR0ZWQsIHBhcmFtZXRlcnMgYmluZCBwb3NpdGlvbmFsbHkgYmFzZWQgb24gdGhlaXIK
IG9yZGVyIGluIHRoZSBsaXN0LgoKDAoFBAECAAUSAzgCCAoMCgUEAQIAARIDOAkNCgwKBQQB
AgADEgM4EBEKDAoFBAECAAgSAzgSOgoPCggEAQIACJwIABIDOBM5CmMKBAQBAgESAzwCSxpW
IFJlcXVpcmVkLiBVc2UgcHJvdG9idWYuVmFsdWUgc28gY2xpZW50cyBjYW4gcGFzcyBpbnRz
LCBib29scywgYW5kIHN0cmluZ3MKIG5hdGl2ZWx5LgoKDAoFBAECAQYSAzwCFwoMCgUEAQIB
ARIDPBgdCgwKBQQBAgEDEgM8ICEKDAoFBAECAQgSAzwiSgoPCggEAQIBCJwIABIDPCNJCsEB
CgQEAQICEgNBAkAaswEgT3B0aW9uYWwuIE9wdGlvbmFsOiBEYXRhdHlwZSBoaW50IGZvciB0
aGUgcGFyYW1ldGVyIChlLmcuLCAiVkFSQ0hBUjIiLAogIk5VTUJFUiIsICJEQVRFIiwgIlRJ
TUVTVEFNUCIpLiBJZiBvbWl0dGVkLCB0aGUgT3JhY2xlIGRyaXZlciB3aWxsIGluZmVyCiB0
aGUgdHlwZSBmcm9tIHRoZSB2YWx1ZSBzdHJpbmcuCgoMCgUEAQICBRIDQQIICgwKBQQBAgIB
EgNBCRIKDAoFBAECAgMSA0EVFgoMCgUEAQICCBIDQRc/Cg8KCAQBAgIInAgAEgNBGD4KLwoC
BAISBEUATAEaIyBFeGVjdXRlIGEgU1FMIHN0YXRlbWVudCByZXNwb25zZS4KCgoKAwQCARID
RQgaClQKBAQCAgASA0cCJRpHIFNxbFJlc3VsdCByZXByZXNlbnRzIHRoZSByZXN1bHRzIGZv
ciB0aGUgZXhlY3V0aW9uIG9mIHNxbCBzdGF0ZW1lbnRzLgoKDAoFBAICAAQSA0cCCgoMCgUE
AgIABhIDRwsUCgwKBQQCAgABEgNHFSAKDAoFBAICAAMSA0cjJAphCgQEAgIBEgNLAiIaVCBB
bnkgYWRkaXRpb25hbCBtZXRhZGF0YSBpbmZvcm1hdGlvbiByZWdhcmRpbmcgdGhlIGV4ZWN1
dGlvbiBvZiB0aGUgc3FsCiBzdGF0ZW1lbnQuCgoMCgUEAgIBBhIDSwIUCgwKBQQCAgEBEgNL
FR0KDAoFBAICAQMSA0sgIQpTCgIEAxIETwBvARpHIFNxbFJlc3VsdCByZXByZXNlbnRzIHRo
ZSByZXN1bHQgZm9yIHRoZSBleGVjdXRpb24gb2YgYSBzcWwgc3RhdGVtZW50LgoKCgoDBAMB
EgNPCBEKSwoEBAMDABIEUQJYAxo9IENvbnRhaW5zIHRoZSBuYW1lIGFuZCBkYXRhdHlwZSBv
ZiBhIGNvbHVtbiBpbiBhIFNRTCBSZXN1bHQuCgoMCgUEAwMAARIDUQoQCi4KBgQDAwACABID
UwQ9Gh8gUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGNvbHVtbi4KCg4KBwQDAwACAAUSA1MECgoO
CgcEAwMAAgABEgNTCw8KDgoHBAMDAAIAAxIDUxITCg4KBwQDAwACAAgSA1MUPAoRCgoEAwMA
AgAInAgAEgNTFTsKaQoGBAMDAAIBEgNXBD0aWiBSZXF1aXJlZC4gRGF0YWJhc2Utc3BlY2lm
aWMgdHlwZSBuYW1lIChlLmcuLCAiVkFSQ0hBUjIoMjU1KSIsICJOVU1CRVIiLAogIkRBVEUi
LCAiQ0xPQiIpCgoOCgcEAwMAAgEFEgNXBAoKDgoHBAMDAAIBARIDVwsPCg4KBwQDAwACAQMS
A1cSEwoOCgcEAwMAAgEIEgNXFDwKEQoKBAMDAAIBCJwIABIDVxU7Ci8KBAQDAwESBFsCXgMa
ISBBIHNpbmdsZSByb3cgZnJvbSBhIHNxbCByZXN1bHQuCgoMCgUEAwMBARIDWwoNCjcKBgQD
AwECABIDXQQeGiggTGlzdCBvZiB2YWx1ZXMgaW4gYSByb3cgb2Ygc3FsIHJlc3VsdC4KCg4K
BwQDAwECAAQSA10EDAoOCgcEAwMBAgAGEgNdDRIKDgoHBAMDAQIAARIDXRMZCg4KBwQDAwEC
AAMSA10cHQo6CgQEAwMCEgRhAmgDGiwgQSBzaW5nbGUgdmFsdWUgaW4gYSByb3cgZnJvbSBh
IHNxbCByZXN1bHQuCgoMCgUEAwMCARIDYQoPCncKBgQDAwICABIDZAQVGmggVGhlIGNlbGwg
dmFsdWUgcmVwcmVzZW50ZWQgaW4gc3RyaW5nIGZvcm1hdC4KIFRpbWVzdGFtcHMgc2hvdWxk
IGJlIGNvbnZlcnRlZCB1c2luZyBSRkMzMzM5TmFubyBmb3JtYXQuCgoOCgcEAwMCAgAFEgNk
BAoKDgoHBAMDAgIAARIDZAsQCg4KBwQDAwICAAMSA2QTFAo3CgYEAwMCAgESA2cEIRooIFNl
dCB0byB0cnVlIGlmIHRoZSBjZWxsIHZhbHVlIGlzIE5VTEwuCgoOCgcEAwMCAgEEEgNnBAwK
DgoHBAMDAgIBBRIDZw0RCg4KBwQDAwICAQESA2cSHAoOCgcEAwMCAgEDEgNnHyAKSwoEBAMC
ABIDawIeGj4gTGlzdCBvZiBjb2x1bW5zIGluY2x1ZGVkIGluIHRoZSByZXN1bHQsIGluY2x1
ZGluZyBkYXRhIHR5cGUuCgoMCgUEAwIABBIDawIKCgwKBQQDAgAGEgNrCxEKDAoFBAMCAAES
A2sSGQoMCgUEAwIAAxIDaxwdCjIKBAQDAgESA24CGBolIFJvd3MgcmV0dXJuZWQgYnkgdGhl
IFNRTCBzdGF0ZW1lbnQuCgoMCgUEAwIBBBIDbgIKCgwKBQQDAgEGEgNuCw4KDAoFBAMCAQES
A24PEwoMCgUEAwIBAxIDbhYXClUKAgQEEgVyAJcBARpIIEFueSBhZGRpdGlvbmFsIG1ldGFk
YXRhIGluZm9ybWF0aW9uIHJlZ2FyZGluZyB0aGUgZXhlY3V0aW9uIG9mIHRoZSBTUUwKCgoK
AwQEARIDcggaClIKBAQEBAASBXQCiAEDGkMgU3RhdHVzIGNvbnRhaW5zIGFsbCB2YWxpZCBz
dGF0dXNlcyBhIFNRTCBleGVjdXRpb24gY2FuIGVuZCB1cCBpbi4KCgwKBQQEBAABEgN0Bw0K
PAoGBAQEAAIAEgN2BBsaLSBEZWZhdWx0IHZhbHVlLiBOb3QgcmV0dXJuZWQgYnkgdGhlIHNl
cnZpY2UuCgoOCgcEBAQAAgABEgN2BBYKDgoHBAQEAAIAAhIDdhkaCncKBgQEBAACARIDegQL
GmggTm8gZXJyb3IgZHVyaW5nIFNRTCBleGVjdXRpb24gaS5lLiBBbGwgU1FMIHN0YXRlbWVu
dHMgcmFuIHRvIGNvbXBsZXRpb24uCiBUaGUgIm1lc3NhZ2UiIHdpbGwgYmUgZW1wdHkuCgoO
CgcEBAQAAgEBEgN6BAYKDgoHBAQEAAIBAhIDegkKCuABCgYEBAQAAgISA38EEBrQASBTYW1l
IGFzIE9LLCBleGNlcHQgaW5kaWNhdGVzIHRoYXQgb25seSBwYXJ0aWFsIHJlc3VsdHMgd2Vy
ZQogcmV0dXJuZWQuIFRoZSAibWVzc2FnZSIgZmllbGQgd2lsbCBjb250YWluIGRldGFpbHMg
b24gd2h5IHJlc3VsdHMgd2VyZQogdHJ1bmNhdGVkLiBgcGFydGlhbF9yZXN1bHRgIGlzIHRy
dWUgaWYgYW5kIG9ubHkgaWYgYHN0YXR1c2AgaXMgYFBBUlRJQUxgLgoKDgoHBAQEAAICARID
fwQLCg4KBwQEBAACAgISA38ODwqjAwoGBAQEAAIDEgSHAQQOGpIDIFRoZSBkYXRhYmFzZSBy
ZXR1cm5lZCBhbiBlcnJvciB3aGlsZSBleGVjdXRpbmcgdGhlIFNRTCBzdGF0ZW1lbnQuCiBg
bWVzc2FnZWAgY29udGFpbnMgdGhlIGVycm9yIHRleHQgcmV0dXJuZWQgYnkgT3JhY2xlLiBg
c3FsX3Jlc3VsdHNgIGlzCiBlbXB0eS4gVGhlIHN0YXRlbWVudCBydW5zIGluIGF1dG9jb21t
aXQgbW9kZTsgd2hpY2ggY2hhbmdlcyBhcmUgY29tbWl0dGVkCiBvciByb2xsZWQgYmFjayBm
b2xsb3dzIE9yYWNsZSBEYXRhYmFzZSBiZWhhdmlvci4gQXV0aGVudGljYXRpb24gZmFpbHVy
ZXMsCiBkYXRhYmFzZSBhdmFpbGFiaWxpdHkgZXJyb3JzLCBuZXR3b3JrIGVycm9ycywgYW5k
IHRpbWVvdXRzIGFyZSByZXR1cm5lZAogYXMgQVBJIGVycm9ycyAoQUlQLTE5MyksIG5vdCBh
cyBFUlJPUi4KCg8KBwQEBAACAwESBIcBBAkKDwoHBAQEAAIDAhIEhwEMDQpvCgQEBAIAEgSM
AQIVGmEgTWVzc2FnZSByZWxhdGVkIHRvIFNRTCBleGVjdXRpb24uIFRoaXMgZmllbGQgY2Fu
IGJlIHVzZWQgdG8gY29udmV5IHNpemUKIGxpbWl0IHJlbGF0ZWQgbWVzc2FnZS4KCg0KBQQE
AgAFEgSMAQIICg0KBQQEAgABEgSMAQkQCg0KBQQEAgADEgSMARMUCocBCgQEBAIBEgSQAQIa
GnkgU2V0IHRvIHRydWUgaWYgU1FMIHJldHVybmVkIGEgcmVzdWx0IHNldCBsYXJnZXIgdGhh
biB0aGUgYWNjZXB0YWJsZQogcmVzcG9uc2Ugc2l6ZSBsaW1pdHMgYW5kIHRoZSByZXN1bHQg
d2FzIHRydW5jYXRlZC4KCg0KBQQEAgEFEgSQAQIGCg0KBQQEAgEBEgSQAQcVCg0KBQQEAgED
EgSQARgZCkUKBAQEAgISBJMBAjIaNyBUaGUgdGltZSBkdXJhdGlvbiB0YWtlbiB0byBleGVj
dXRlIHRoZSBzcWwgc3RhdGVtZW50LgoKDQoFBAQCAgYSBJMBAhoKDQoFBAQCAgESBJMBGy0K
DQoFBAQCAgMSBJMBMDEKNQoEBAQCAxIElgECQBonIE91dHB1dCBvbmx5LiBTdGF0dXMgb2Yg
U1FMIGV4ZWN1dGlvbi4KCg0KBQQEAgMGEgSWAQIICg0KBQQEAgMBEgSWAQkPCg0KBQQEAgMD
EgSWARITCg0KBQQEAgMIEgSWARQ/ChAKCAQEAgMInAgAEgSWARU+YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest ===
    # Fields for ExecuteSqlRequest
    # Field: name Type: 9 ()
    # Field: sql_statement Type: 9 ()
    # Field: params Type: 11 (.google.cloud.oracledatabase.v1.SqlParameter)

# === Message: Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlParameter ===
    # Fields for SqlParameter
    # Field: name Type: 9 ()
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: type_name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlResponse ===
    # Fields for ExecuteSqlResponse
    # Field: sql_results Type: 11 (.google.cloud.oracledatabase.v1.SqlResult)
    # Field: metadata Type: 11 (.google.cloud.oracledatabase.v1.ExecuteSqlMetadata)

# === Message: Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult ===
    # Fields for SqlResult
    # Field: columns Type: 11 (.google.cloud.oracledatabase.v1.SqlResult.Column)
    # Field: rows Type: 11 (.google.cloud.oracledatabase.v1.SqlResult.Row)

# === Message: Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlMetadata ===
    # Fields for ExecuteSqlMetadata
    # Field: message Type: 9 ()
    # Field: partial_result Type: 8 ()
    # Field: execution_duration Type: 11 (.google.protobuf.Duration)
    # Field: status Type: 14 (.google.cloud.oracledatabase.v1.ExecuteSqlMetadata.Status)

# Enum: ExecuteSqlMetadata::Status
our $ExecuteSqlMetadata_STATUS_UNSPECIFIED = 0;
our $ExecuteSqlMetadata_OK = 1;
our $ExecuteSqlMetadata_PARTIAL = 2;
our $ExecuteSqlMetadata_ERROR = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExecuteSql - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/execute_sql.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::ExecuteSql;

    my $msg = Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest->new({
        name => $name,
        sql_statement => $sql_statement,
        params => $params,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/execute_sql.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest

The request for `DatabaseConnection.ExecuteSql`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DatabaseConnection in the following format:
projects/{project}/locations/{location}/databaseConnections/{database_connection}.

=item * C<< $msg->sql_statement() >> / C<< $msg->sql_statement($value) >>

Type: C<String>

Required. The SQL statement to execute.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlParameter>)

Optional. Optional: Bind variables (parameters) to be used with the SQL
statement. Supports named bind variables (e.g., :dept_id, :status in Oracle
SQL) or positional parameters (:1, :2).

=back

=head2 Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlParameter

Represents a bind variable (parameter) for SQL execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the SQL bind parameter (excluding the leading
colon, e.g. "id"). If omitted, parameters bind positionally based on their
order in the list.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Required. Use protobuf.Value so clients can pass ints, bools, and strings
natively.

=item * C<< $msg->type_name() >> / C<< $msg->type_name($value) >>

Type: C<String>

Optional. Optional: Datatype hint for the parameter (e.g., "VARCHAR2",
"NUMBER", "DATE", "TIMESTAMP"). If omitted, the Oracle driver will infer
the type from the value string.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlResponse

Execute a SQL statement response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sql_results() >> / C<< $msg->sql_results($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult>)

SqlResult represents the results for the execution of sql statements.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlMetadata>)

Any additional metadata information regarding the execution of the sql
statement.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult

SqlResult represents the result for the execution of a sql statement.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Column>)

List of columns included in the result, including data type.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Row>)

Rows returned by the SQL statement.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlMetadata

Any additional metadata information regarding the execution of the SQL

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Message related to SQL execution. This field can be used to convey size
limit related message.

=item * C<< $msg->partial_result() >> / C<< $msg->partial_result($value) >>

Type: C<Bool>

Set to true if SQL returned a result set larger than the acceptable
response size limits and the result was truncated.

=item * C<< $msg->execution_duration() >> / C<< $msg->execution_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The time duration taken to execute the sql statement.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExecuteSqlMetadata::Status>)

Output only. Status of SQL execution.

=back

=head3 Enum: ExecuteSqlMetadata::Status

=over 4

=item * C<STATUS_UNSPECIFIED> => C<0>

=item * C<OK> => C<1>

=item * C<PARTIAL> => C<2>

=item * C<ERROR> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::ExecuteSql::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
