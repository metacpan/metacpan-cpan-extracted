package Google::Cloud::Resourcemanager::V3::TagHolds;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcmVzb3VyY2VtYW5hZ2VyL3YzL3RhZ19ob2xkcy5wcm90bxIfZ29v
Z2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9sb25ncnVubmlu
Zy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8inQIKB1RhZ0hvbGQSFwoEbmFtZRgBIAEoCUID
4EEDUgRuYW1lEhsKBmhvbGRlchgCIAEoCUID4EECUgZob2xkZXISGwoGb3JpZ2luGAMgASgJ
QgPgQQFSBm9yaWdpbhIgCgloZWxwX2xpbmsYBCABKAlCA+BBAVIIaGVscExpbmsSQAoLY3Jl
YXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0
ZVRpbWU6W+pBWAorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVGFnSG9s
ZBIpdGFnVmFsdWVzL3t0YWdfdmFsdWV9L3RhZ0hvbGRzL3t0YWdfaG9sZH0i1wEKFENyZWF0
ZVRhZ0hvbGRSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtEitjbG91ZHJlc291cmNl
bWFuYWdlci5nb29nbGVhcGlzLmNvbS9UYWdIb2xkUgZwYXJlbnQSSAoIdGFnX2hvbGQYAiAB
KAsyKC5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLlRhZ0hvbGRCA+BBAlIHdGFn
SG9sZBIoCg12YWxpZGF0ZV9vbmx5GAMgASgIQgPgQQFSDHZhbGlkYXRlT25seSIXChVDcmVh
dGVUYWdIb2xkTWV0YWRhdGEiiQEKFERlbGV0ZVRhZ0hvbGRSZXF1ZXN0EkcKBG5hbWUYASAB
KAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVGFnSG9s
ZFIEbmFtZRIoCg12YWxpZGF0ZV9vbmx5GAIgASgIQgPgQQFSDHZhbGlkYXRlT25seSIXChVE
ZWxldGVUYWdIb2xkTWV0YWRhdGEixQEKE0xpc3RUYWdIb2xkc1JlcXVlc3QSSwoGcGFyZW50
GAEgASgJQjPgQQL6QS0SK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Rh
Z0hvbGRSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFn
ZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZp
bHRlciKFAQoUTGlzdFRhZ0hvbGRzUmVzcG9uc2USRQoJdGFnX2hvbGRzGAEgAygLMiguZ29v
Z2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5UYWdIb2xkUgh0YWdIb2xkcxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4y7AUKCFRhZ0hvbGRzEs8BCg1DcmVh
dGVUYWdIb2xkEjUuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5DcmVhdGVUYWdI
b2xkUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iaILT5JMCLSIhL3Yz
L3twYXJlbnQ9dGFnVmFsdWVzLyp9L3RhZ0hvbGRzOgh0YWdfaG9sZNpBD3BhcmVudCx0YWdf
aG9sZMpBIAoHVGFnSG9sZBIVQ3JlYXRlVGFnSG9sZE1ldGFkYXRhEsgBCg1EZWxldGVUYWdI
b2xkEjUuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5EZWxldGVUYWdIb2xkUmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iYYLT5JMCIyohL3YzL3tuYW1l
PXRhZ1ZhbHVlcy8qL3RhZ0hvbGRzLyp92kEEbmFtZcpBLgoVZ29vZ2xlLnByb3RvYnVmLkVt
cHR5EhVEZWxldGVUYWdIb2xkTWV0YWRhdGESrwEKDExpc3RUYWdIb2xkcxI0Lmdvb2dsZS5j
bG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuTGlzdFRhZ0hvbGRzUmVxdWVzdBo1Lmdvb2dsZS5j
bG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuTGlzdFRhZ0hvbGRzUmVzcG9uc2UiMoLT5JMCIxIh
L3YzL3twYXJlbnQ9dGFnVmFsdWVzLyp9L3RhZ0hvbGRz2kEGcGFyZW50GpABykEjY2xvdWRy
ZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb23SQWdodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0ucmVhZC1vbmx5Qu4BCiNjb20uZ29vZ2xlLmNsb3VkLnJlc291
cmNlbWFuYWdlci52M0INVGFnSG9sZHNQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL3Jl
c291cmNlbWFuYWdlci9hcGl2My9yZXNvdXJjZW1hbmFnZXJwYjtyZXNvdXJjZW1hbmFnZXJw
YqoCH0dvb2dsZS5DbG91ZC5SZXNvdXJjZU1hbmFnZXIuVjPKAh9Hb29nbGVcQ2xvdWRcUmVz
b3VyY2VNYW5hZ2VyXFYz6gIiR29vZ2xlOjpDbG91ZDo6UmVzb3VyY2VNYW5hZ2VyOjpWM0qO
OAoHEgUOANcBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
KAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
AC0KCQoCAwUSAxcAJQoJCgIDBhIDGAApCggKAQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsA
ZAoJCgIICxIDGwBkCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ALgoJCgIICBIDHQAu
CggKAQgSAx4APAoJCgIIARIDHgA8CggKAQgSAx8APAoJCgIIKRIDHwA8CggKAQgSAyAAOwoJ
CgIILRIDIAA7CvUCCgIGABIEJwBQARroAiBBbGxvdyB1c2VycyB0byBjcmVhdGUgYW5kIG1h
bmFnZSBUYWdIb2xkcyBmb3IgVGFnVmFsdWVzLiBUYWdIb2xkcyByZXByZXNlbnQKIHRoZSB1
c2Ugb2YgYSBUYWcgVmFsdWUgdGhhdCBpcyBub3QgY2FwdHVyZWQgYnkgVGFnQmluZGluZ3Mg
YnV0CiBzaG91bGQgc3RpbGwgYmxvY2sgVGFnVmFsdWUgZGVsZXRpb24gKHN1Y2ggYXMgYSBy
ZWZlcmVuY2UgaW4gYSBwb2xpY3kKIGNvbmRpdGlvbikuIFRoaXMgc2VydmljZSBwcm92aWRl
cyBpc29sYXRlZCBmYWlsdXJlIGRvbWFpbnMgYnkgY2xvdWQgbG9jYXRpb24KIHNvIHRoYXQg
VGFnSG9sZHMgY2FuIGJlIG1hbmFnZWQgaW4gdGhlIHNhbWUgbG9jYXRpb24gYXMgdGhlaXIg
dXNhZ2UuCgoKCgMGAAESAycIEAoKCgMGAAMSAygCSwoMCgUGAAOZCBIDKAJLCgsKAwYAAxIE
KQIrQQoNCgUGAAOaCBIEKQIrQQqJAQoEBgACABIELwI6Axp7IENyZWF0ZXMgYSBUYWdIb2xk
LiBSZXR1cm5zIEFMUkVBRFlfRVhJU1RTIGlmIGEgVGFnSG9sZCB3aXRoIHRoZSBzYW1lCiBy
ZXNvdXJjZSBhbmQgb3JpZ2luIGV4aXN0cyB1bmRlciB0aGUgc2FtZSBUYWdWYWx1ZS4KCgwK
BQYAAgABEgMvBhMKDAoFBgACAAISAy8UKAoMCgUGAAIAAxIDMA8rCg0KBQYAAgAEEgQxBDQG
ChEKCQYAAgAEsMq8IhIEMQQ0BgoMCgUGAAIABBIDNQQ9Cg8KCAYAAgAEmwgAEgM1BD0KDQoF
BgACAAQSBDYEOQYKDwoHBgACAASZCBIENgQ5BgoiCgQGAAIBEgQ9AkcDGhQgRGVsZXRlcyBh
IFRhZ0hvbGQuCgoMCgUGAAIBARIDPQYTCgwKBQYAAgECEgM9FCgKDAoFBgACAQMSAz4PKwoN
CgUGAAIBBBIEPwRBBgoRCgkGAAIBBLDKvCISBD8EQQYKDAoFBgACAQQSA0IEMgoPCggGAAIB
BJsIABIDQgQyCg0KBQYAAgEEEgRDBEYGCg8KBwYAAgEEmQgSBEMERgYKMAoEBgACAhIESgJP
AxoiIExpc3RzIFRhZ0hvbGRzIHVuZGVyIGEgVGFnVmFsdWUuCgoMCgUGAAICARIDSgYSCgwK
BQYAAgICEgNKEyYKDAoFBgACAgMSA0oxRQoNCgUGAAICBBIESwRNBgoRCgkGAAICBLDKvCIS
BEsETQYKDAoFBgACAgQSA04ENAoPCggGAAICBJsIABIDTgQ0Cu8BCgIEABIEVgB1ARriASBB
IFRhZ0hvbGQgcmVwcmVzZW50cyB0aGUgdXNlIG9mIGEgVGFnVmFsdWUgdGhhdCBpcyBub3Qg
Y2FwdHVyZWQgYnkKIFRhZ0JpbmRpbmdzLiBJZiBhIFRhZ1ZhbHVlIGhhcyBhbnkgVGFnSG9s
ZHMsIGRlbGV0aW9uIHdpbGwgYmUgYmxvY2tlZC4KIFRoaXMgcmVzb3VyY2UgaXMgaW50ZW5k
ZWQgdG8gYmUgY3JlYXRlZCBpbiB0aGUgc2FtZSBjbG91ZCBsb2NhdGlvbiBhcyB0aGUKIGBo
b2xkZXJgLgoKCgoDBAABEgNWCA8KCwoDBAAHEgRXAloECg0KBQQAB50IEgRXAloECuMBCgQE
AAIAEgNgAj4a1QEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIGEgVGFnSG9s
ZC4gVGhpcyBpcyBhIFN0cmluZyBvZiB0aGUgZm9ybToKIGB0YWdWYWx1ZXMve3RhZy12YWx1
ZS1pZH0vdGFnSG9sZHMve3RhZy1ob2xkLWlkfWAKIChlLmcuIGB0YWdWYWx1ZXMvMTIzL3Rh
Z0hvbGRzLzQ1NmApLiBUaGlzIHJlc291cmNlIG5hbWUgaXMgZ2VuZXJhdGVkIGJ5CiB0aGUg
c2VydmVyLgoKDAoFBAACAAUSA2ACCAoMCgUEAAIAARIDYAkNCgwKBQQAAgADEgNgEBEKDAoF
BAACAAgSA2ASPQoPCggEAAIACJwIABIDYBM8CuoBCgQEAAIBEgNlAj0a3AEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSByZXNvdXJjZSB3aGVyZSB0aGUgVGFnVmFsdWUgaXMgYmVpbmcg
dXNlZC4gTXVzdAogYmUgbGVzcyB0aGFuIDIwMCBjaGFyYWN0ZXJzLiBFLmcuCiBgLy9jb21w
dXRlLmdvb2dsZWFwaXMuY29tL2NvbXB1dGUvcHJvamVjdHMvbXlwcm9qZWN0L3JlZ2lvbnMv
dXMtZWFzdC0xL2luc3RhbmNlR3JvdXBNYW5hZ2Vycy9pbnN0YW5jZS1ncm91cGAKCgwKBQQA
AgEFEgNlAggKDAoFBAACAQESA2UJDwoMCgUEAAIBAxIDZRITCgwKBQQAAgEIEgNlFDwKDwoI
BAACAQicCAASA2UVOwryAQoEBAACAhIDawI9GuQBIE9wdGlvbmFsLiBBbiBvcHRpb25hbCBz
dHJpbmcgcmVwcmVzZW50aW5nIHRoZSBvcmlnaW4gb2YgdGhpcyByZXF1ZXN0LiBUaGlzCiBm
aWVsZCBzaG91bGQgaW5jbHVkZSBodW1hbi11bmRlcnN0YW5kYWJsZSBpbmZvcm1hdGlvbiB0
byBkaXN0aW5ndWlzaAogb3JpZ2lucyBmcm9tIGVhY2ggb3RoZXIuIE11c3QgYmUgbGVzcyB0
aGFuIDIwMCBjaGFyYWN0ZXJzLiBFLmcuCiBgbWlncy0zNTY3ODIzNGAKCgwKBQQAAgIFEgNr
AggKDAoFBAACAgESA2sJDwoMCgUEAAICAxIDaxITCgwKBQQAAgIIEgNrFDwKDwoIBAACAgic
CAASA2sVOwqyAQoEBAACAxIDcAJAGqQBIE9wdGlvbmFsLiBBIFVSTCB3aGVyZSBhbiBlbmQg
dXNlciBjYW4gbGVhcm4gbW9yZSBhYm91dCByZW1vdmluZyB0aGlzIGhvbGQuCiBFLmcuCiBg
aHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy90YWdzL3Rh
Z3MtY3JlYXRpbmctYW5kLW1hbmFnaW5nYAoKDAoFBAACAwUSA3ACCAoMCgUEAAIDARIDcAkS
CgwKBQQAAgMDEgNwFRYKDAoFBAACAwgSA3AXPwoPCggEAAIDCJwIABIDcBg+Cj8KBAQAAgQS
BHMCdDIaMSBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhpcyBUYWdIb2xkIHdhcyBjcmVhdGVk
LgoKDAoFBAACBAYSA3MCGwoMCgUEAAIEARIDcxwnCgwKBQQAAgQDEgNzKisKDAoFBAACBAgS
A3QGMQoPCggEAAIECJwIABIDdAcwCjcKAgQBEgV4AIgBARoqIFRoZSByZXF1ZXN0IG1lc3Nh
Z2UgdG8gY3JlYXRlIGEgVGFnSG9sZC4KCgoKAwQBARIDeAgcCoABCgQEAQIAEgV7AoABBBpx
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgVGFnSG9sZCdzIHBhcmVudCBU
YWdWYWx1ZS4gTXVzdCBiZSBvZgogdGhlIGZvcm06IGB0YWdWYWx1ZXMve3RhZy12YWx1ZS1p
ZH1gLgoKDAoFBAECAAUSA3sCCAoMCgUEAQIAARIDewkPCgwKBQQBAgADEgN7EhMKDgoFBAEC
AAgSBXsUgAEDCg8KCAQBAgAInAgAEgN8BCoKDwoHBAECAAifCBIEfQR/BQo0CgQEAQIBEgSD
AQJAGiYgUmVxdWlyZWQuIFRoZSBUYWdIb2xkIHRvIGJlIGNyZWF0ZWQuCgoNCgUEAQIBBhIE
gwECCQoNCgUEAQIBARIEgwEKEgoNCgUEAQIBAxIEgwEVFgoNCgUEAQIBCBIEgwEXPwoQCggE
AQIBCJwIABIEgwEYPgqLAQoEBAECAhIEhwECQhp9IE9wdGlvbmFsLiBTZXQgdG8gdHJ1ZSB0
byBwZXJmb3JtIHRoZSB2YWxpZGF0aW9ucyBuZWNlc3NhcnkgZm9yIGNyZWF0aW5nIHRoZQog
cmVzb3VyY2UsIGJ1dCBub3QgYWN0dWFsbHkgcGVyZm9ybSB0aGUgYWN0aW9uLgoKDQoFBAEC
AgUSBIcBAgYKDQoFBAECAgESBIcBBxQKDQoFBAECAgMSBIcBFxgKDQoFBAECAggSBIcBGUEK
EAoIBAECAgicCAASBIcBGkAKmgEKAgQCEgSNAQAgGo0BIFJ1bnRpbWUgb3BlcmF0aW9uIGlu
Zm9ybWF0aW9uIGZvciBjcmVhdGluZyBhIFRhZ0hvbGQuCiAoLS0gVGhlIG1ldGFkYXRhIGlz
IGN1cnJlbnRseSBlbXB0eSwgYnV0IG1heSBpbmNsdWRlIGluZm9ybWF0aW9uIGluIHRoZQog
ZnV0dXJlLiAtLSkKCgsKAwQCARIEjQEIHQo4CgIEAxIGkAEAnQEBGiogVGhlIHJlcXVlc3Qg
bWVzc2FnZSB0byBkZWxldGUgYSBUYWdIb2xkLgoKCwoDBAMBEgSQAQgcCpEBCgQEAwIAEgaT
AQKYAQQagAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBUYWdIb2xkIHRv
IGRlbGV0ZS4gTXVzdCBiZSBvZiB0aGUgZm9ybToKIGB0YWdWYWx1ZXMve3RhZy12YWx1ZS1p
ZH0vdGFnSG9sZHMve3RhZy1ob2xkLWlkfWAuCgoNCgUEAwIABRIEkwECCAoNCgUEAwIAARIE
kwEJDQoNCgUEAwIAAxIEkwEQEQoPCgUEAwIACBIGkwESmAEDChAKCAQDAgAInAgAEgSUAQQq
ChEKBwQDAgAInwgSBpUBBJcBBQqLAQoEBAMCARIEnAECQhp9IE9wdGlvbmFsLiBTZXQgdG8g
dHJ1ZSB0byBwZXJmb3JtIHRoZSB2YWxpZGF0aW9ucyBuZWNlc3NhcnkgZm9yIGRlbGV0aW5n
IHRoZQogcmVzb3VyY2UsIGJ1dCBub3QgYWN0dWFsbHkgcGVyZm9ybSB0aGUgYWN0aW9uLgoK
DQoFBAMCAQUSBJwBAgYKDQoFBAMCAQESBJwBBxQKDQoFBAMCAQMSBJwBFxgKDQoFBAMCAQgS
BJwBGUEKEAoIBAMCAQicCAASBJwBGkAKmgEKAgQEEgSiAQAgGo0BIFJ1bnRpbWUgb3BlcmF0
aW9uIGluZm9ybWF0aW9uIGZvciBkZWxldGluZyBhIFRhZ0hvbGQuCiAoLS0gVGhlIG1ldGFk
YXRhIGlzIGN1cnJlbnRseSBlbXB0eSwgYnV0IG1heSBpbmNsdWRlIGluZm9ybWF0aW9uIGlu
IHRoZQogZnV0dXJlLiAtLSkKCgsKAwQEARIEogEIHQpOCgIEBRIGpQEAxAEBGkAgVGhlIHJl
cXVlc3QgbWVzc2FnZSBmb3IgbGlzdGluZyB0aGUgVGFnSG9sZHMgdW5kZXIgYSBUYWdWYWx1
ZS4KCgsKAwQFARIEpQEIGwp3CgQEBQIAEgaoAQKtAQQaZyBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBUYWdWYWx1ZS4gTXVzdCBiZSBvZiB0aGUgZm9ybToK
IGB0YWdWYWx1ZXMve3RhZy12YWx1ZS1pZH1gLgoKDQoFBAUCAAUSBKgBAggKDQoFBAUCAAES
BKgBCQ8KDQoFBAUCAAMSBKgBEhMKDwoFBAUCAAgSBqgBFK0BAwoQCggEBQIACJwIABIEqQEE
KgoRCgcEBQIACJ8IEgaqAQSsAQUKxQEKBAQFAgESBLIBAj8atgEgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBUYWdIb2xkcyB0byByZXR1cm4gaW4gdGhlIHJlc3BvbnNlLiBU
aGUKIHNlcnZlciBhbGxvd3MgYSBtYXhpbXVtIG9mIDMwMCBUYWdIb2xkcyB0byByZXR1cm4u
IElmIHVuc3BlY2lmaWVkLCB0aGUKIHNlcnZlciB3aWxsIHVzZSAxMDAgYXMgdGhlIGRlZmF1
bHQuCgoNCgUEBQIBBRIEsgECBwoNCgUEBQIBARIEsgEIEQoNCgUEBQIBAxIEsgEUFQoNCgUE
BQIBCBIEsgEWPgoQCggEBQIBCJwIABIEsgEXPQqWAQoEBAUCAhIEtgECQRqHASBPcHRpb25h
bC4gQSBwYWdpbmF0aW9uIHRva2VuIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIHRv
CiBgTGlzdFRhZ0hvbGRzYCB0aGF0IGluZGljYXRlcyB3aGVyZSB0aGlzIGxpc3Rpbmcgc2hv
dWxkIGNvbnRpbnVlIGZyb20uCgoNCgUEBQICBRIEtgECCAoNCgUEBQICARIEtgEJEwoNCgUE
BQICAxIEtgEWFwoNCgUEBQICCBIEtgEYQAoQCggEBQICCJwIABIEtgEZPwrbBAoEBAUCAxIE
wwECPRrMBCBPcHRpb25hbC4gQ3JpdGVyaWEgdXNlZCB0byBzZWxlY3QgYSBzdWJzZXQgb2Yg
VGFnSG9sZHMgcGFyZW50ZWQgYnkgdGhlCiBUYWdWYWx1ZSB0byByZXR1cm4uIFRoaXMgZmll
bGQgZm9sbG93cyB0aGUgc3ludGF4IGRlZmluZWQgYnkgYWlwLmRldi8xNjA7CiB0aGUgYGhv
bGRlcmAgYW5kIGBvcmlnaW5gIGZpZWxkcyBhcmUgc3VwcG9ydGVkIGZvciBmaWx0ZXJpbmcu
IEN1cnJlbnRseQogb25seSBgQU5EYCBzeW50YXggaXMgc3VwcG9ydGVkLiBTb21lIGV4YW1w
bGUgcXVlcmllcyBhcmU6CgogICAqIGBob2xkZXIgPQogICAgIC8vY29tcHV0ZS5nb29nbGVh
cGlzLmNvbS9jb21wdXRlL3Byb2plY3RzL215cHJvamVjdC9yZWdpb25zL3VzLWVhc3QtMS9p
bnN0YW5jZUdyb3VwTWFuYWdlcnMvaW5zdGFuY2UtZ3JvdXBgCiAgICogYG9yaWdpbiA9IDM1
Njc4MjM0YAogICAqIGBob2xkZXIgPQogICAgIC8vY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9j
b21wdXRlL3Byb2plY3RzL215cHJvamVjdC9yZWdpb25zL3VzLWVhc3QtMS9pbnN0YW5jZUdy
b3VwTWFuYWdlcnMvaW5zdGFuY2UtZ3JvdXAKICAgICBBTkQgb3JpZ2luID0gMzU2NzgyMzRg
CgoNCgUEBQIDBRIEwwECCAoNCgUEBQIDARIEwwEJDwoNCgUEBQIDAxIEwwESEwoNCgUEBQID
CBIEwwEUPAoQCggEBQIDCJwIABIEwwEVOwoqCgIEBhIGxwEA1wEBGhwgVGhlIExpc3RUYWdI
b2xkcyByZXNwb25zZS4KCgsKAwQGARIExwEIHAo2CgQEBgIAEgTJAQIhGiggQSBwb3NzaWJs
eSBwYWdpbmF0ZWQgbGlzdCBvZiBUYWdIb2xkcy4KCg0KBQQGAgAEEgTJAQIKCg0KBQQGAgAG
EgTJAQsSCg0KBQQGAgABEgTJARMcCg0KBQQGAgADEgTJAR8gCskDCgQEBgIBEgTWAQIdGroD
IFBhZ2luYXRpb24gdG9rZW4uCgogSWYgdGhlIHJlc3VsdCBzZXQgaXMgdG9vIGxhcmdlIHRv
IGZpdCBpbiBhIHNpbmdsZSByZXNwb25zZSwgdGhpcyB0b2tlbgogaXMgcmV0dXJuZWQuIEl0
IGVuY29kZXMgdGhlIHBvc2l0aW9uIG9mIHRoZSBjdXJyZW50IHJlc3VsdCBjdXJzb3IuCiBG
ZWVkaW5nIHRoaXMgdmFsdWUgaW50byBhIG5ldyBsaXN0IHJlcXVlc3Qgd2l0aCB0aGUgYHBh
Z2VfdG9rZW5gIHBhcmFtZXRlcgogZ2l2ZXMgdGhlIG5leHQgcGFnZSBvZiB0aGUgcmVzdWx0
cy4KCiBXaGVuIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIG5vdCBmaWxsZWQgaW4sIHRoZXJlIGlz
IG5vIG5leHQgcGFnZSBhbmQKIHRoZSBsaXN0IHJldHVybmVkIGlzIHRoZSBsYXN0IHBhZ2Ug
aW4gdGhlIHJlc3VsdCBzZXQuCgogUGFnaW5hdGlvbiB0b2tlbnMgaGF2ZSBhIGxpbWl0ZWQg
bGlmZXRpbWUuCgoNCgUEBgIBBRIE1gECCAoNCgUEBgIBARIE1gEJGAoNCgUEBgIBAxIE1gEb
HGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::TagHold ===
    # Fields for TagHold
    # Field: name Type: 9 ()
    # Field: holder Type: 9 ()
    # Field: origin Type: 9 ()
    # Field: help_link Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest ===
    # Fields for CreateTagHoldRequest
    # Field: parent Type: 9 ()
    # Field: tag_hold Type: 11 (.google.cloud.resourcemanager.v3.TagHold)
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldMetadata ===
    # Fields for CreateTagHoldMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldRequest ===
    # Fields for DeleteTagHoldRequest
    # Field: name Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldMetadata ===
    # Fields for DeleteTagHoldMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest ===
    # Fields for ListTagHoldsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse ===
    # Fields for ListTagHoldsResponse
    # Field: tag_holds Type: 11 (.google.cloud.resourcemanager.v3.TagHold)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Resourcemanager::V3::TagHolds::TagHoldsClient ===
package Google::Cloud::Resourcemanager::V3::TagHolds::TagHoldsClient;

=pod

=head2 Service Client: Google::Cloud::Resourcemanager::V3::TagHolds::TagHoldsClient

Client stub representing the remote C<TagHolds> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<resourcemanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'resourcemanager.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub create_tag_hold {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagHolds',
        method         => 'CreateTagHold',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_tag_hold {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagHolds',
        method         => 'DeleteTagHold',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_tag_holds {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagHolds',
        method         => 'ListTagHolds',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagHolds - Compiled Protocol Buffers messages for google/cloud/resourcemanager/v3/tag_holds.proto

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::TagHolds;

    my $msg = Google::Cloud::Resourcemanager::V3::TagHolds::TagHold->new({
        name => $name,
        holder => $holder,
        origin => $origin,
        help_link => $help_link,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Resourcemanager::V3::TagHolds::TagHold->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/resourcemanager/v3/tag_holds.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::TagHold

A TagHold represents the use of a TagValue that is not captured by
TagBindings. If a TagValue has any TagHolds, deletion will be blocked.
This resource is intended to be created in the same cloud location as the
`holder`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of a TagHold. This is a String of the form:
`tagValues/{tag-value-id}/tagHolds/{tag-hold-id}`
(e.g. `tagValues/123/tagHolds/456`). This resource name is generated by
the server.

=item * C<< $msg->holder() >> / C<< $msg->holder($value) >>

Type: C<String>

Required. The name of the resource where the TagValue is being used. Must
be less than 200 characters. E.g.
`//compute.googleapis.com/compute/projects/myproject/regions/us-east-1/instanceGroupManagers/instance-group`

=item * C<< $msg->origin() >> / C<< $msg->origin($value) >>

Type: C<String>

Optional. An optional string representing the origin of this request. This
field should include human-understandable information to distinguish
origins from each other. Must be less than 200 characters. E.g.
`migs-35678234`

=item * C<< $msg->help_link() >> / C<< $msg->help_link($value) >>

Type: C<String>

Optional. A URL where an end user can learn more about removing this hold.
E.g.
`https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this TagHold was created.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest

The request message to create a TagHold.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the TagHold's parent TagValue. Must be of
the form: `tagValues/{tag-value-id}`.

=item * C<< $msg->tag_hold() >> / C<< $msg->tag_hold($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagHolds::TagHold>)

Required. The TagHold to be created.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set to true to perform the validations necessary for creating the
resource, but not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldMetadata

Runtime operation information for creating a TagHold.
(-- The metadata is currently empty, but may include information in the
future. --)

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldRequest

The request message to delete a TagHold.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the TagHold to delete. Must be of the form:
`tagValues/{tag-value-id}/tagHolds/{tag-hold-id}`.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set to true to perform the validations necessary for deleting the
resource, but not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldMetadata

Runtime operation information for deleting a TagHold.
(-- The metadata is currently empty, but may include information in the
future. --)

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest

The request message for listing the TagHolds under a TagValue.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the parent TagValue. Must be of the form:
`tagValues/{tag-value-id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of TagHolds to return in the response. The
server allows a maximum of 300 TagHolds to return. If unspecified, the
server will use 100 as the default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to
`ListTagHolds` that indicates where this listing should continue from.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Criteria used to select a subset of TagHolds parented by the
TagValue to return. This field follows the syntax defined by aip.dev/160;
the `holder` and `origin` fields are supported for filtering. Currently
only `AND` syntax is supported. Some example queries are:

  * `holder =
    //compute.googleapis.com/compute/projects/myproject/regions/us-east-1/instanceGroupManagers/instance-group`
  * `origin = 35678234`
  * `holder =
    //compute.googleapis.com/compute/projects/myproject/regions/us-east-1/instanceGroupManagers/instance-group
    AND origin = 35678234`

=back

=head2 Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse

The ListTagHolds response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_holds() >> / C<< $msg->tag_holds($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagHolds::TagHold>)

A possibly paginated list of TagHolds.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token.

If the result set is too large to fit in a single response, this token
is returned. It encodes the position of the current result cursor.
Feeding this value into a new list request with the `page_token` parameter
gives the next page of the results.

When `next_page_token` is not filled in, there is no next page and
the list returned is the last page in the result set.

Pagination tokens have a limited lifetime.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Resourcemanager::V3::TagHolds::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
