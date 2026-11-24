package Google::Cloud::Dialogflow::V2::ToolCall;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi90b29sX2NhbGwucHJvdG8SGmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItoFCghUb29sQ2FsbBI8CgR0b29s
GAEgASgJQibgQQH6QSAKHmRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVG9vbEgAUgR0b29s
EjwKCGNlc190b29sGAsgASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVhcGlzLmNvbS9Ub29sSABS
B2Nlc1Rvb2wSRQoLY2VzX3Rvb2xzZXQYDCABKAlCIuBBAfpBHAoaY2VzLmdvb2dsZWFwaXMu
Y29tL1Rvb2xzZXRIAFIKY2VzVG9vbHNldBI5CgdjZXNfYXBwGAggASgJQh7gQQH6QRgKFmNl
cy5nb29nbGVhcGlzLmNvbS9BcHBIAFIGY2VzQXBwEi8KEXRvb2xfZGlzcGxheV9uYW1lGAkg
ASgJQgPgQQFSD3Rvb2xEaXNwbGF5TmFtZRI1ChR0b29sX2Rpc3BsYXlfZGV0YWlscxgKIAEo
CUID4EEBUhJ0b29sRGlzcGxheURldGFpbHMSGwoGYWN0aW9uGAIgASgJQgPgQQFSBmFjdGlv
bhJHChBpbnB1dF9wYXJhbWV0ZXJzGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID
4EEBUg9pbnB1dFBhcmFtZXRlcnMSQAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSKAoNYW5zd2VyX3JlY29yZBgGIAEo
CUID4EEBUgxhbnN3ZXJSZWNvcmQSRQoFc3RhdGUYByABKA4yKi5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52Mi5Ub29sQ2FsbC5TdGF0ZUID4EEDUgVzdGF0ZSJFCgVTdGF0ZRIVChFTVEFU
RV9VTlNQRUNJRklFRBAAEg0KCVRSSUdHRVJFRBABEhYKEk5FRURTX0NPTkZJUk1BVElPThAC
QggKBnNvdXJjZSKOBQoOVG9vbENhbGxSZXN1bHQSPAoEdG9vbBgBIAEoCUIm4EEB+kEgCh5k
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Rvb2xIAFIEdG9vbBJFCgtjZXNfdG9vbHNldBgN
IAEoCUIi4EEB+kEcChpjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbHNldEgAUgpjZXNUb29sc2V0
EjwKCGNlc190b29sGAwgASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVhcGlzLmNvbS9Ub29sSABS
B2Nlc1Rvb2wSOQoHY2VzX2FwcBgLIAEoCUIe4EEB+kEYChZjZXMuZ29vZ2xlYXBpcy5jb20v
QXBwSABSBmNlc0FwcBIbCgZhY3Rpb24YAiABKAlCA+BBAVIGYWN0aW9uEk0KBWVycm9yGAMg
ASgLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVG9vbENhbGxSZXN1bHQuRXJyb3JC
A+BBAUgBUgVlcnJvchImCgtyYXdfY29udGVudBgFIAEoDEID4EEBSAFSCnJhd0NvbnRlbnQS
HwoHY29udGVudBgGIAEoCUID4EEBSAFSB2NvbnRlbnQSQAoLY3JlYXRlX3RpbWUYByABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSKAoNYW5zd2Vy
X3JlY29yZBgJIAEoCUID4EEBUgxhbnN3ZXJSZWNvcmQaSQoFRXJyb3ISHQoHbWVzc2FnZRgB
IAEoCUID4EEBUgdtZXNzYWdlEiEKCXJldHJ5YWJsZRgCIAEoCEID4EEBUglyZXRyeWFibGVC
CAoGc291cmNlQggKBnJlc3VsdEKTAQoeY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
Qg1Ub29sQ2FsbFByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2
Mi9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9n
Zmxvdy5WMkrJLAoHEgUOAK8BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAIwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgIDAxIDFQAp
CggKAQgSAxcANwoJCgIIJRIDFwA3CggKAQgSAxgAVQoJCgIICxIDGABVCggKAQgSAxkAIgoJ
CgIIChIDGQAiCggKAQgSAxoALgoJCgIICBIDGgAuCggKAQgSAxsANwoJCgIIARIDGwA3CggK
AQgSAxwAIAoJCgIIJBIDHAAgClYKAgQAEgQfAGcBGkogUmVwcmVzZW50cyBhIGNhbGwgb2Yg
YSBzcGVjaWZpYyB0b29sJ3MgYWN0aW9uIHdpdGggdGhlIHNwZWNpZmllZCBpbnB1dHMuCgoK
CgMEAAESAx8IEAohCgQEAAQAEgQhAioDGhMgVG9vbCBjYWxsIHN0YXRlcy4KCgwKBQQABAAB
EgMhBwwKHwoGBAAEAAIAEgMjBBoaECBEZWZhdWx0IHZhbHVlLgoKDgoHBAAEAAIAARIDIwQV
Cg4KBwQABAACAAISAyMYGQoyCgYEAAQAAgESAyYEEhojIFRoZSB0b29sIGNhbGwgaGFzIGJl
ZW4gdHJpZ2dlcmVkLgoKDgoHBAAEAAIBARIDJgQNCg4KBwQABAACAQISAyYQEQpCCgYEAAQA
AgISAykEGxozIFRoZSB0b29sIGNhbGwgcmVxdWlyZXMgY29uZmlybWF0aW9uIGZyb20gYSBo
dW1hbi4KCg4KBwQABAACAgESAykEFgoOCgcEAAQAAgICEgMpGRoKNwoEBAAIABIELQJPAxop
IFNwZWNpZmllcyB0aGUgc291cmNlIG9mIHRoaXMgdG9vbCBjYWxsLgoKDAoFBAAIAAESAy0I
DgqpAQoEBAACABIEMQQ2BhqaASBPcHRpb25hbC4gVGhlIFt0b29sXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5Ub29sXSBhc3NvY2lhdGVkIHdpdGgKIHRoaXMgY2FsbC4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vdG9vbHMv
PFRvb2xJRD5gLgoKDAoFBAACAAUSAzEECgoMCgUEAAIAARIDMQsPCgwKBQQAAgADEgMxEhMK
DQoFBAACAAgSBDEUNgUKDwoIBAACAAicCAASAzIGLAoPCgcEAAIACJ8IEgQzBjUHCosBCgQE
AAIBEgQ7BD4GGn0gT3B0aW9uYWwuIENFUyB0b29sIG5hbWUgZm9yIHRoaXMgY2FsbC4KIEZv
cm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2Fw
cHMvPEFwcElEPi90b29scy88VG9vbElEPmAuCgoMCgUEAAIBBRIDOwQKCgwKBQQAAgEBEgM7
CxMKDAoFBAACAQMSAzsWGAoNCgUEAAIBCBIEOxk+BQoPCggEAAIBCJwIABIDPAYsCg4KBwQA
AgEInwgSAz0GSwqUAQoEBAACAhIEQwRGBhqFASBPcHRpb25hbC4gQ0VTIHRvb2xzZXQgbmFt
ZSBmb3IgdGhpcyBjYWxsLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0
aW9ucy88TG9jYXRpb25JRD4vYXBwcy88QXBwSUQ+L3Rvb2xzZXRzL1Rvb2xzZXRJRD5gLgoK
DAoFBAACAgUSA0MECgoMCgUEAAICARIDQwsWCgwKBQQAAgIDEgNDGRsKDQoFBAACAggSBEMc
RgUKDwoIBAACAgicCAASA0QGLAoOCgcEAAICCJ8IEgNFBk4KewoEBAACAxIESwROBhptIE9w
dGlvbmFsLiBDRVMgYXBwIG5hbWUgZm9yIHRoaXMgY2FsbC4KIEZvcm1hdDoKIGBwcm9qZWN0
cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FwcHMvPEFwcElEPmAuCgoM
CgUEAAIDBRIDSwQKCgwKBQQAAgMBEgNLCxIKDAoFBAACAwMSA0sVFgoNCgUEAAIDCBIESxdO
BQoPCggEAAIDCJwIABIDTAYsCg4KBwQAAgMInwgSA00GSgpYCgQEAAIEEgNSAkgaSyBPcHRp
b25hbC4gQSBodW1hbiByZWFkYWJsZSBzaG9ydCBuYW1lIG9mIHRoZSB0b29sLCB0byBiZSBz
aG93biBvbiB0aGUgVUkuCgoMCgUEAAIEBRIDUgIICgwKBQQAAgQBEgNSCRoKDAoFBAACBAMS
A1IdHgoMCgUEAAIECBIDUh9HCg8KCAQAAgQInAgAEgNSIEYKQgoEBAACBRIDVQJMGjUgT3B0
aW9uYWwuIEEgaHVtYW4gcmVhZGFibGUgZGVzY3JpcHRpb24gb2YgdGhlIHRvb2wuCgoMCgUE
AAIFBRIDVQIICgwKBQQAAgUBEgNVCR0KDAoFBAACBQMSA1UgIgoMCgUEAAIFCBIDVSNLCg8K
CAQAAgUInAgAEgNVJEoKUQoEBAACBhIDWAI9GkQgT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRo
ZSB0b29sJ3MgYWN0aW9uIGFzc29jaWF0ZWQgd2l0aCB0aGlzIGNhbGwuCgoMCgUEAAIGBRID
WAIICgwKBQQAAgYBEgNYCQ8KDAoFBAACBgMSA1gSEwoMCgUEAAIGCBIDWBQ8Cg8KCAQAAgYI
nAgAEgNYFTsKOAoEBAACBxIEWwJcLxoqIE9wdGlvbmFsLiBUaGUgYWN0aW9uJ3MgaW5wdXQg
cGFyYW1ldGVycy4KCgwKBQQAAgcGEgNbAhgKDAoFBAACBwESA1sZKQoMCgUEAAIHAxIDWywt
CgwKBQQAAgcIEgNcBi4KDwoIBAACBwicCAASA1wHLQo6CgQEAAIIEgRfAmAyGiwgT3V0cHV0
IG9ubHkuIENyZWF0ZSB0aW1lIG9mIHRoZSB0b29sIGNhbGwuCgoMCgUEAAIIBhIDXwIbCgwK
BQQAAggBEgNfHCcKDAoFBAACCAMSA18qKwoMCgUEAAIICBIDYAYxCg8KCAQAAggInAgAEgNg
BzAKSgoEBAACCRIDYwJEGj0gT3B0aW9uYWwuIFRoZSBhbnN3ZXIgcmVjb3JkIGFzc29jaWF0
ZWQgd2l0aCB0aGlzIHRvb2wgY2FsbC4KCgwKBQQAAgkFEgNjAggKDAoFBAACCQESA2MJFgoM
CgUEAAIJAxIDYxkaCgwKBQQAAgkIEgNjG0MKDwoIBAACCQicCAASA2McQgozCgQEAAIKEgNm
Aj4aJiBPdXRwdXQgb25seS4gU3RhdGUgb2YgdGhlIHRvb2wgY2FsbC4KCgwKBQQAAgoGEgNm
AgcKDAoFBAACCgESA2YIDQoMCgUEAAIKAxIDZhARCgwKBQQAAgoIEgNmEj0KDwoIBAACCgic
CAASA2YTPAo1CgIEARIFagCvAQEaKCBUaGUgcmVzdWx0IG9mIGNhbGxpbmcgYSB0b29sJ3Mg
YWN0aW9uLgoKCgoDBAEBEgNqCBYKMwoEBAEDABIEbAJyAxolIEFuIGVycm9yIHByb2R1Y2Vk
IGJ5IHRoZSB0b29sIGNhbGwuCgoMCgUEAQMAARIDbAoPCj0KBgQBAwACABIDbgRAGi4gT3B0
aW9uYWwuIFRoZSBlcnJvciBtZXNzYWdlIG9mIHRoZSBmdW5jdGlvbi4KCg4KBwQBAwACAAUS
A24ECgoOCgcEAQMAAgABEgNuCxIKDgoHBAEDAAIAAxIDbhUWCg4KBwQBAwACAAgSA24XPwoR
CgoEAQMAAgAInAgAEgNuGD4KSAoGBAEDAAIBEgNxBEAaOSBPcHRpb25hbC4gU3BlY2lmaWVz
IHdoZXRoZXIgdGhlIHRvb2wgY2FsbCBpcyByZXRyeWFibGUuCgoOCgcEAQMAAgEFEgNxBAgK
DgoHBAEDAAIBARIDcQkSCg4KBwQBAwACAQMSA3EVFgoOCgcEAQMAAgEIEgNxFz8KEQoKBAED
AAIBCJwIABIDcRg+CjgKBAQBCAASBXUClwEDGikgU3BlY2lmaWVzIHRoZSBzb3VyY2Ugb2Yg
dGhpcyB0b29sIGNhbGwuCgoMCgUEAQgAARIDdQgOCqkBCgQEAQIAEgR5BH4GGpoBIE9wdGlv
bmFsLiBUaGUgW3Rvb2xdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlRvb2xdIGFzc29j
aWF0ZWQgd2l0aAogdGhpcyBjYWxsLiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4v
bG9jYXRpb25zLzxMb2NhdGlvbklEPi90b29scy88VG9vbElEPmAuCgoMCgUEAQIABRIDeQQK
CgwKBQQBAgABEgN5Cw8KDAoFBAECAAMSA3kSEwoNCgUEAQIACBIEeRR+BQoPCggEAQIACJwI
ABIDegYsCg8KBwQBAgAInwgSBHsGfQcKlgEKBAQBAgESBoMBBIYBBhqFASBPcHRpb25hbC4g
Q0VTIHRvb2xzZXQgbmFtZSBmb3IgdGhpcyBjYWxsLgogRm9ybWF0OgogYHByb2plY3RzLzxQ
cm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYXBwcy88QXBwSUQ+L3Rvb2xzZXRz
L1Rvb2xzZXRJRD5gLgoKDQoFBAECAQUSBIMBBAoKDQoFBAECAQESBIMBCxYKDQoFBAECAQMS
BIMBGRsKDwoFBAECAQgSBoMBHIYBBQoQCggEAQIBCJwIABIEhAEGLAoPCgcEAQIBCJ8IEgSF
AQZOCo0BCgQEAQICEgaLAQSOAQYafSBPcHRpb25hbC4gQ0VTIHRvb2wgbmFtZSBmb3IgdGhp
cyBjYWxsLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9j
YXRpb25JRD4vYXBwcy88QXBwSUQ+L3Rvb2xzLzxUb29sSUQ+YC4KCg0KBQQBAgIFEgSLAQQK
Cg0KBQQBAgIBEgSLAQsTCg0KBQQBAgIDEgSLARYYCg8KBQQBAgIIEgaLARmOAQUKEAoIBAEC
AgicCAASBIwBBiwKDwoHBAECAgifCBIEjQEGSwp9CgQEAQIDEgaTAQSWAQYabSBPcHRpb25h
bC4gQ0VTIGFwcCBuYW1lIGZvciB0aGlzIGNhbGwuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFBy
b2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hcHBzLzxBcHBJRD5gLgoKDQoFBAEC
AwUSBJMBBAoKDQoFBAECAwESBJMBCxIKDQoFBAECAwMSBJMBFRcKDwoFBAECAwgSBpMBGJYB
BQoQCggEAQIDCJwIABIElAEGLAoPCgcEAQIDCJ8IEgSVAQZKClIKBAQBAgQSBJoBAj0aRCBP
cHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wncyBhY3Rpb24gYXNzb2NpYXRlZCB3aXRo
IHRoaXMgY2FsbC4KCg0KBQQBAgQFEgSaAQIICg0KBQQBAgQBEgSaAQkPCg0KBQQBAgQDEgSa
ARITCg0KBQQBAgQIEgSaARQ8ChAKCAQBAgQInAgAEgSaARU7CikKBAQBCAESBp0BAqcBAxoZ
IFRoZSB0b29sIGNhbGwncyByZXN1bHQuCgoNCgUEAQgBARIEnQEIDgowCgQEAQIFEgSfAQQ9
GiIgT3B0aW9uYWwuIFRoZSB0b29sIGNhbGwncyBlcnJvci4KCg0KBQQBAgUGEgSfAQQJCg0K
BQQBAgUBEgSfAQoPCg0KBQQBAgUDEgSfARITCg0KBQQBAgUIEgSfARQ8ChAKCAQBAgUInAgA
EgSfARU7CocBCgQEAQIGEgSjAQRDGnkgT3B0aW9uYWwuIE9ubHkgcG9wdWxhdGVkIGlmIHRo
ZSByZXNwb25zZSBjb250ZW50IGlzIG5vdCB1dGYtOCBlbmNvZGVkLgogKGJ5IGRlZmluaXRp
b24gYnl0ZSBmaWVsZHMgYXJlIGJhc2U2NCBlbmNvZGVkKS4KCg0KBQQBAgYFEgSjAQQJCg0K
BQQBAgYBEgSjAQoVCg0KBQQBAgYDEgSjARgZCg0KBQQBAgYIEgSjARpCChAKCAQBAgYInAgA
EgSjARtBClIKBAQBAgcSBKYBBEAaRCBPcHRpb25hbC4gT25seSBwb3B1bGF0ZWQgaWYgdGhl
IHJlc3BvbnNlIGNvbnRlbnQgaXMgdXRmLTggZW5jb2RlZC4KCg0KBQQBAgcFEgSmAQQKCg0K
BQQBAgcBEgSmAQsSCg0KBQQBAgcDEgSmARUWCg0KBQQBAgcIEgSmARc/ChAKCAQBAgcInAgA
EgSmARg+CkMKBAQBAggSBqoBAqsBMhozIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZSBvZiB0
aGUgdG9vbCBjYWxsIHJlc3VsdC4KCg0KBQQBAggGEgSqAQIbCg0KBQQBAggBEgSqARwnCg0K
BQQBAggDEgSqASorCg0KBQQBAggIEgSrAQYxChAKCAQBAggInAgAEgSrAQcwClIKBAQBAgkS
BK4BAkQaRCBPcHRpb25hbC4gVGhlIGFuc3dlciByZWNvcmQgYXNzb2NpYXRlZCB3aXRoIHRo
aXMgdG9vbCBjYWxsIHJlc3VsdC4KCg0KBQQBAgkFEgSuAQIICg0KBQQBAgkBEgSuAQkWCg0K
BQQBAgkDEgSuARkaCg0KBQQBAgkIEgSuARtDChAKCAQBAgkInAgAEgSuARxCYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::ToolCall::ToolCall ===
    # Fields for ToolCall
    # Field: tool Type: 9 ()
    # Field: ces_tool Type: 9 ()
    # Field: ces_toolset Type: 9 ()
    # Field: ces_app Type: 9 ()
    # Field: tool_display_name Type: 9 ()
    # Field: tool_display_details Type: 9 ()
    # Field: action Type: 9 ()
    # Field: input_parameters Type: 11 (.google.protobuf.Struct)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: answer_record Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.v2.ToolCall.State)

# Enum: ToolCall::State
our $ToolCall_STATE_UNSPECIFIED = 0;
our $ToolCall_TRIGGERED = 1;
our $ToolCall_NEEDS_CONFIRMATION = 2;

# === Message: Google::Cloud::Dialogflow::V2::ToolCall::ToolCallResult ===
    # Fields for ToolCallResult
    # Field: tool Type: 9 ()
    # Field: ces_toolset Type: 9 ()
    # Field: ces_tool Type: 9 ()
    # Field: ces_app Type: 9 ()
    # Field: action Type: 9 ()
    # Field: error Type: 11 (.google.cloud.dialogflow.v2.ToolCallResult.Error)
    # Field: raw_content Type: 12 ()
    # Field: content Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: answer_record Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::ToolCall - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/tool_call.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::ToolCall;

    my $msg = Google::Cloud::Dialogflow::V2::ToolCall::ToolCall->new({
        tool => $tool,
        ces_tool => $ces_tool,
        ces_toolset => $ces_toolset,
        ces_app => $ces_app,
    });

    # Read or update a field
    my $val = $msg->tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::ToolCall::ToolCall->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/tool_call.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::ToolCall::ToolCall

Represents a call of a specific tool's action with the specified inputs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The [tool][google.cloud.dialogflow.v2.Tool] associated with
this call. Format:
`projects/<ProjectID>/locations/<LocationID>/tools/<ToolID>`.

=item * C<< $msg->ces_tool() >> / C<< $msg->ces_tool($value) >>

Type: C<String>

Optional. CES tool name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/tools/<ToolID>`.

=item * C<< $msg->ces_toolset() >> / C<< $msg->ces_toolset($value) >>

Type: C<String>

Optional. CES toolset name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/toolsets/ToolsetID>`.

=item * C<< $msg->ces_app() >> / C<< $msg->ces_app($value) >>

Type: C<String>

Optional. CES app name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>`.

=item * C<< $msg->tool_display_name() >> / C<< $msg->tool_display_name($value) >>

Type: C<String>

Optional. A human readable short name of the tool, to be shown on the UI.

=item * C<< $msg->tool_display_details() >> / C<< $msg->tool_display_details($value) >>

Type: C<String>

Optional. A human readable description of the tool.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Optional. The name of the tool's action associated with this call.

=item * C<< $msg->input_parameters() >> / C<< $msg->input_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The action's input parameters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the tool call.

=item * C<< $msg->answer_record() >> / C<< $msg->answer_record($value) >>

Type: C<String>

Optional. The answer record associated with this tool call.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::ToolCall::State>)

Output only. State of the tool call.

=back

=head3 Enum: ToolCall::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<TRIGGERED> => C<1>

=item * C<NEEDS_CONFIRMATION> => C<2>

=back

=head2 Google::Cloud::Dialogflow::V2::ToolCall::ToolCallResult

The result of calling a tool's action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The [tool][google.cloud.dialogflow.v2.Tool] associated with
this call. Format:
`projects/<ProjectID>/locations/<LocationID>/tools/<ToolID>`.

=item * C<< $msg->ces_toolset() >> / C<< $msg->ces_toolset($value) >>

Type: C<String>

Optional. CES toolset name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/toolsets/ToolsetID>`.

=item * C<< $msg->ces_tool() >> / C<< $msg->ces_tool($value) >>

Type: C<String>

Optional. CES tool name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>/tools/<ToolID>`.

=item * C<< $msg->ces_app() >> / C<< $msg->ces_app($value) >>

Type: C<String>

Optional. CES app name for this call.
Format:
`projects/<ProjectID>/locations/<LocationID>/apps/<AppID>`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Optional. The name of the tool's action associated with this call.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ToolCall::ToolCallResult::Error>)

Optional. The tool call's error.

=item * C<< $msg->raw_content() >> / C<< $msg->raw_content($value) >>

Type: C<Bytes>

Optional. Only populated if the response content is not utf-8 encoded.
(by definition byte fields are base64 encoded).

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Optional. Only populated if the response content is utf-8 encoded.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the tool call result.

=item * C<< $msg->answer_record() >> / C<< $msg->answer_record($value) >>

Type: C<String>

Optional. The answer record associated with this tool call result.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::ToolCall::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
