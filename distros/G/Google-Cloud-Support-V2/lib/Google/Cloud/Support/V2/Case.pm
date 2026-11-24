package Google::Cloud::Support::V2::Case;

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
    eval { require Google::Cloud::Support::V2::Actor };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9jYXNlLnByb3RvEhdnb29nbGUuY2xvdWQuc3Vw
cG9ydC52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIvYWN0b3IucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8inQgKBENhc2USFwoEbmFtZRgBIAEoCUID
4EEIUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3Jp
cHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uElMKDmNsYXNzaWZpY2F0aW9uGAQgASgLMisuZ29v
Z2xlLmNsb3VkLnN1cHBvcnQudjIuQ2FzZUNsYXNzaWZpY2F0aW9uUg5jbGFzc2lmaWNhdGlv
bhIbCgl0aW1lX3pvbmUYCCABKAlSCHRpbWVab25lEjwKGnN1YnNjcmliZXJfZW1haWxfYWRk
cmVzc2VzGAkgAygJUhhzdWJzY3JpYmVyRW1haWxBZGRyZXNzZXMSPgoFc3RhdGUYDCABKA4y
Iy5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5DYXNlLlN0YXRlQgPgQQNSBXN0YXRlEkAKC2Ny
ZWF0ZV90aW1lGA0gASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEkAKC3VwZGF0ZV90aW1lGA4gASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lEjgKB2NyZWF0b3IYDyABKAsyHi5nb29nbGUuY2xvdWQuc3Vw
cG9ydC52Mi5BY3RvclIHY3JlYXRvchIjCg1jb250YWN0X2VtYWlsGCMgASgJUgxjb250YWN0
RW1haWwSHAoJZXNjYWxhdGVkGBEgASgIUgllc2NhbGF0ZWQSGwoJdGVzdF9jYXNlGBMgASgI
Ugh0ZXN0Q2FzZRIjCg1sYW5ndWFnZV9jb2RlGBcgASgJUgxsYW5ndWFnZUNvZGUSQgoIcHJp
b3JpdHkYICABKA4yJi5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5DYXNlLlByaW9yaXR5Ughw
cmlvcml0eSJ/CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgcKA05FVxABEh4KGklO
X1BST0dSRVNTX0dPT0dMRV9TVVBQT1JUEAISEwoPQUNUSU9OX1JFUVVJUkVEEAMSFQoRU09M
VVRJT05fUFJPVklERUQQBBIKCgZDTE9TRUQQBSJMCghQcmlvcml0eRIYChRQUklPUklUWV9V
TlNQRUNJRklFRBAAEgYKAlAwEAESBgoCUDEQAhIGCgJQMhADEgYKAlAzEAQSBgoCUDQQBTpx
6kFuCiBjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vQ2FzZRIpb3JnYW5pemF0aW9ucy97
b3JnYW5pemF0aW9ufS9jYXNlcy97Y2FzZX0SH3Byb2plY3RzL3twcm9qZWN0fS9jYXNlcy97
Y2FzZX0iRwoSQ2FzZUNsYXNzaWZpY2F0aW9uEg4KAmlkGAMgASgJUgJpZBIhCgxkaXNwbGF5
X25hbWUYBCABKAlSC2Rpc3BsYXlOYW1lQrIBChtjb20uZ29vZ2xlLmNsb3VkLnN1cHBvcnQu
djJCCUNhc2VQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL3N1cHBvcnQvYXBpdjIvc3Vw
cG9ydHBiO3N1cHBvcnRwYqoCF0dvb2dsZS5DbG91ZC5TdXBwb3J0LlYyygIXR29vZ2xlXENs
b3VkXFN1cHBvcnRcVjLqAhpHb29nbGU6OkNsb3VkOjpTdXBwb3J0OjpWMkq+NAoHEgUOAMQB
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
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABID
EgApCgkKAgMBEgMTACMKCQoCAwISAxQALQoJCgIDAxIDFQApCggKAQgSAxcANAoJCgIIJRID
FwA0CggKAQgSAxgATAoJCgIICxIDGABMCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoA
KgoJCgIICBIDGgAqCggKAQgSAxsANAoJCgIIARIDGwA0CggKAQgSAxwANAoJCgIIKRIDHAA0
CggKAQgSAx0AMwoJCgIILRIDHQAzCv8FCgIEABIFOgCrAQEa8QUgQSBDYXNlIGlzIGFuIG9i
amVjdCB0aGF0IGNvbnRhaW5zIHRoZSBkZXRhaWxzIG9mIGEgc3VwcG9ydCBjYXNlLiBJdAog
Y29udGFpbnMgZmllbGRzIGZvciB0aGUgdGltZSBpdCB3YXMgY3JlYXRlZCwgaXRzIHByaW9y
aXR5LCBpdHMKIGNsYXNzaWZpY2F0aW9uLCBhbmQgbW9yZS4gQ2FzZXMgY2FuIGFsc28gaGF2
ZSBjb21tZW50cyBhbmQgYXR0YWNobWVudHMgdGhhdAogZ2V0IGFkZGVkIG92ZXIgdGltZS4K
CiBBIGNhc2UgaXMgcGFyZW50ZWQgYnkgYSBHb29nbGUgQ2xvdWQgb3JnYW5pemF0aW9uIG9y
IHByb2plY3QuCgogT3JnYW5pemF0aW9ucyBhcmUgaWRlbnRpZmllZCBieSBhIG51bWJlciwg
c28gdGhlIG5hbWUgb2YgYSBjYXNlIHBhcmVudGVkIGJ5CiBhbiBvcmdhbml6YXRpb24gd291
bGQgbG9vayBsaWtlIHRoaXM6CgogYGBgCiBvcmdhbml6YXRpb25zLzEyMy9jYXNlcy80NTYK
IGBgYAoKIFByb2plY3RzIGhhdmUgdHdvIHVuaXF1ZSBpZGVudGlmaWVycywgYW4gSUQgYW5k
IGEgbnVtYmVyLCBhbmQgdGhleSBsb29rIGxpa2UKIHRoaXM6CgogYGBgCiBwcm9qZWN0cy9h
YmMvY2FzZXMvNDU2CiBgYGAKCiBgYGAKIHByb2plY3RzLzEyMy9jYXNlcy80NTYKIGBgYAoK
IFlvdSBjYW4gdXNlIGVpdGhlciBvZiB0aGVtIHdoZW4gY2FsbGluZyB0aGUgQVBJLiBUbyBs
ZWFybiBtb3JlCiBhYm91dCBwcm9qZWN0IGlkZW50aWZpZXJzLCBzZWUgW0FJUC0yNTEwXSho
dHRwczovL2dvb2dsZS5haXAuZGV2L2Nsb3VkLzI1MTApLgoKCgoDBAABEgM6CAwKCwoDBAAH
EgQ7Aj8ECg0KBQQAB50IEgQ7Aj8ECi0KBAQABAASBEICVAMaHyBUaGUgc3RhdHVzIG9mIGEg
c3VwcG9ydCBjYXNlLgoKDAoFBAAEAAESA0IHDAotCgYEAAQAAgASA0QEGhoeIENhc2UgaXMg
aW4gYW4gdW5rbm93biBzdGF0ZS4KCg4KBwQABAACAAESA0QEFQoOCgcEAAQAAgACEgNEGBkK
VAoGBAAEAAIBEgNHBAwaRSBUaGUgY2FzZSBoYXMgYmVlbiBjcmVhdGVkIGJ1dCBubyBvbmUg
aXMgYXNzaWduZWQgdG8gd29yayBvbiBpdCB5ZXQuCgoOCgcEAAQAAgEBEgNHBAcKDgoHBAAE
AAIBAhIDRwoLCkcKBgQABAACAhIDSgQjGjggVGhlIGNhc2UgaXMgY3VycmVudGx5IGJlaW5n
IGhhbmRsZWQgYnkgR29vZ2xlIHN1cHBvcnQuCgoOCgcEAAQAAgIBEgNKBB4KDgoHBAAEAAIC
AhIDSiEiCjIKBgQABAACAxIDTQQYGiMgR29vZ2xlIGlzIHdhaXRpbmcgZm9yIGEgcmVzcG9u
c2UuCgoOCgcEAAQAAgMBEgNNBBMKDgoHBAAEAAIDAhIDTRYXClMKBgQABAACBBIDUAQaGkQg
QSBzb2x1dGlvbiBoYXMgYmVlbiBvZmZlcmVkIGZvciB0aGUgY2FzZSwgYnV0IGl0IGlzbid0
IHlldCBjbG9zZWQuCgoOCgcEAAQAAgQBEgNQBBUKDgoHBAAEAAIEAhIDUBgZCiwKBgQABAAC
BRIDUwQPGh0gVGhlIGNhc2UgaGFzIGJlZW4gcmVzb2x2ZWQuCgoOCgcEAAQAAgUBEgNTBAoK
DgoHBAAEAAIFAhIDUw0OCkYKBAQABAESBFcCbAMaOCBUaGUgY2FzZSBQcmlvcml0eS4gUDAg
aXMgbW9zdCB1cmdlbnQgYW5kIFA0IHRoZSBsZWFzdC4KCgwKBQQABAEBEgNXBw8KPwoGBAAE
AQIAEgNZBB0aMCBQcmlvcml0eSBpcyB1bmRlZmluZWQgb3IgaGFzIG5vdCBiZWVuIHNldCB5
ZXQuCgoOCgcEAAQBAgABEgNZBBgKDgoHBAAEAQIAAhIDWRscCk4KBgQABAECARIDXAQLGj8g
RXh0cmVtZSBpbXBhY3Qgb24gYSBwcm9kdWN0aW9uIHNlcnZpY2UuIFNlcnZpY2UgaXMgaGFy
ZCBkb3duLgoKDgoHBAAEAQIBARIDXAQGCg4KBwQABAECAQISA1wJCgpYCgYEAAQBAgISA18E
CxpJIENyaXRpY2FsIGltcGFjdCBvbiBhIHByb2R1Y3Rpb24gc2VydmljZS4gU2VydmljZSBp
cyBjdXJyZW50bHkgdW51c2FibGUuCgoOCgcEAAQBAgIBEgNfBAYKDgoHBAAEAQICAhIDXwkK
CmAKBgQABAECAxIDYwQLGlEgU2V2ZXJlIGltcGFjdCBvbiBhIHByb2R1Y3Rpb24gc2Vydmlj
ZS4gU2VydmljZSBpcyB1c2FibGUgYnV0IGdyZWF0bHkKIGltcGFpcmVkLgoKDgoHBAAEAQID
ARIDYwQGCg4KBwQABAECAwISA2MJCgpoCgYEAAQBAgQSA2cECxpZIE1lZGl1bSBpbXBhY3Qg
b24gYSBwcm9kdWN0aW9uIHNlcnZpY2UuICBTZXJ2aWNlIGlzIGF2YWlsYWJsZSwgYnV0CiBt
b2RlcmF0ZWx5IGltcGFpcmVkLgoKDgoHBAAEAQIEARIDZwQGCg4KBwQABAECBAISA2cJCgpc
CgYEAAQBAgUSA2sECxpNIEdlbmVyYWwgcXVlc3Rpb25zIG9yIG1pbm9yIGlzc3Vlcy4gIFBy
b2R1Y3Rpb24gc2VydmljZSBpcyBmdWxseQogYXZhaWxhYmxlLgoKDgoHBAAEAQIFARIDawQG
Cg4KBwQABAECBQISA2sJCgo6CgQEAAIAEgNvAj0aLSBJZGVudGlmaWVyLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBmb3IgdGhlIGNhc2UuCgoMCgUEAAIABRIDbwIICgwKBQQAAgABEgNvCQ0KDAoF
BAACAAMSA28QEQoMCgUEAAIACBIDbxI8Cg8KCAQAAgAInAgAEgNvEzsKRAoEBAACARIDcgIa
GjcgVGhlIHNob3J0IHN1bW1hcnkgb2YgdGhlIGlzc3VlIHJlcG9ydGVkIGluIHRoaXMgY2Fz
ZS4KCgwKBQQAAgEFEgNyAggKDAoFBAACAQESA3IJFQoMCgUEAAIBAxIDchgZCjAKBAQAAgIS
A3UCGRojIEEgYnJvYWQgZGVzY3JpcHRpb24gb2YgdGhlIGlzc3VlLgoKDAoFBAACAgUSA3UC
CAoMCgUEAAICARIDdQkUCgwKBQQAAgIDEgN1FxgKQAoEBAACAxIDeAIoGjMgVGhlIGlzc3Vl
IGNsYXNzaWZpY2F0aW9uIGFwcGxpY2FibGUgdG8gdGhpcyBjYXNlLgoKDAoFBAACAwYSA3gC
FAoMCgUEAAIDARIDeBUjCgwKBQQAAgMDEgN4JicKxgEKBAQAAgQSA30CFxq4ASBUaGUgdGlt
ZXpvbmUgb2YgdGhlIHVzZXIgd2hvIGNyZWF0ZWQgdGhlIHN1cHBvcnQgY2FzZS4KIEl0IHNo
b3VsZCBiZSBpbiBhIGZvcm1hdCBJQU5BIHJlY29nbml6ZXM6IGh0dHBzOi8vd3d3LmlhbmEu
b3JnL3RpbWUtem9uZXMuCiBUaGVyZSBpcyBubyBhZGRpdGlvbmFsIHZhbGlkYXRpb24gZG9u
ZSBieSB0aGUgQVBJLgoKDAoFBAACBAUSA30CCAoMCgUEAAIEARIDfQkSCgwKBQQAAgQDEgN9
FRYKRAoEBAACBRIEgAECMRo2IFRoZSBlbWFpbCBhZGRyZXNzZXMgdG8gcmVjZWl2ZSB1cGRh
dGVzIG9uIHRoaXMgY2FzZS4KCg0KBQQAAgUEEgSAAQIKCg0KBQQAAgUFEgSAAQsRCg0KBQQA
AgUBEgSAARIsCg0KBQQAAgUDEgSAAS8wCkQKBAQAAgYSBIMBAj8aNiBPdXRwdXQgb25seS4g
VGhlIGN1cnJlbnQgc3RhdHVzIG9mIHRoZSBzdXBwb3J0IGNhc2UuCgoNCgUEAAIGBhIEgwEC
BwoNCgUEAAIGARIEgwEIDQoNCgUEAAIGAxIEgwEQEgoNCgUEAAIGCBIEgwETPgoQCggEAAIG
CJwIABIEgwEUPQo+CgQEAAIHEgaGAQKHATIaLiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhp
cyBjYXNlIHdhcyBjcmVhdGVkLgoKDQoFBAACBwYSBIYBAhsKDQoFBAACBwESBIYBHCcKDQoF
BAACBwMSBIYBKiwKDQoFBAACBwgSBIcBBjEKEAoIBAACBwicCAASBIcBBzAKQwoEBAACCBIG
igECiwEyGjMgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoaXMgY2FzZSB3YXMgbGFzdCB1cGRh
dGVkLgoKDQoFBAACCAYSBIoBAhsKDQoFBAACCAESBIoBHCcKDQoFBAACCAMSBIoBKiwKDQoF
BAACCAgSBIsBBjEKEAoIBAACCAicCAASBIsBBzAKiAEKBAQAAgkSBJEBAhUaeiBUaGUgdXNl
ciB3aG8gY3JlYXRlZCB0aGUgY2FzZS4KCiBOb3RlOiBUaGUgbmFtZSBhbmQgZW1haWwgd2ls
bCBiZSBvYmZ1c2NhdGVkIGlmIHRoZSBjYXNlIHdhcyBjcmVhdGVkIGJ5CiBHb29nbGUgU3Vw
cG9ydC4KCg0KBQQAAgkGEgSRAQIHCg0KBQQAAgkBEgSRAQgPCg0KBQQAAgkDEgSRARIUCskB
CgQEAAIKEgSWAQIcGroBIEEgdXNlci1zdXBwbGllZCBlbWFpbCBhZGRyZXNzIHRvIHNlbmQg
Y2FzZSB1cGRhdGUgbm90aWZpY2F0aW9ucyBmb3IuIFRoaXMKIHNob3VsZCBvbmx5IGJlIHVz
ZWQgaW4gQllPSUQgZmxvd3MsIHdoZXJlIHdlIGNhbm5vdCBpbmZlciB0aGUgdXNlcidzIGVt
YWlsCiBhZGRyZXNzIGRpcmVjdGx5IGZyb20gdGhlaXIgRVVDcy4KCg0KBQQAAgoFEgSWAQII
Cg0KBQQAAgoBEgSWAQkWCg0KBQQAAgoDEgSWARkbCjgKBAQAAgsSBJkBAhYaKiBXaGV0aGVy
IHRoZSBjYXNlIGlzIGN1cnJlbnRseSBlc2NhbGF0ZWQuCgoNCgUEAAILBRIEmQECBgoNCgUE
AAILARIEmQEHEAoNCgUEAAILAxIEmQETFQp3CgQEAAIMEgSdAQIWGmkgV2hldGhlciB0aGlz
IGNhc2Ugd2FzIGNyZWF0ZWQgZm9yIGludGVybmFsIEFQSSB0ZXN0aW5nIGFuZCBzaG91bGQg
bm90IGJlCiBhY3RlZCBvbiBieSB0aGUgc3VwcG9ydCB0ZWFtLgoKDQoFBAACDAUSBJ0BAgYK
DQoFBAACDAESBJ0BBxAKDQoFBAACDAMSBJ0BExUK4wMKBAQAAg0SBKcBAhwa1AMgVGhlIGxh
bmd1YWdlIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgdG8gcmVjZWl2ZSBzdXBwb3J0IGluLiBU
aGlzIHNob3VsZCBiZSBhCiBCQ1AgNDcgbGFuZ3VhZ2UgY29kZSAoZS5nLiwgYCJlbiJgLCBg
InpoLUNOImAsIGAiemgtVFciYCwgYCJqYSJgLCBgImtvImApLgogSWYgbm8gbGFuZ3VhZ2Ug
b3IgYW4gdW5zdXBwb3J0ZWQgbGFuZ3VhZ2UgaXMgc3BlY2lmaWVkLCB0aGlzIGZpZWxkIGRl
ZmF1bHRzCiB0byBFbmdsaXNoIChlbikuCgogTGFuZ3VhZ2Ugc2VsZWN0aW9uIGR1cmluZyBj
YXNlIGNyZWF0aW9uIG1heSBhZmZlY3QgeW91ciBhdmFpbGFibGUgc3VwcG9ydAogb3B0aW9u
cy4gRm9yIGEgbGlzdCBvZiBzdXBwb3J0ZWQgbGFuZ3VhZ2VzIGFuZCB0aGVpciBzdXBwb3J0
IHdvcmtpbmcgaG91cnMsCiBzZWU6IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zdXBwb3J0
L2RvY3MvbGFuZ3VhZ2Utd29ya2luZy1ob3VycwoKDQoFBAACDQUSBKcBAggKDQoFBAACDQES
BKcBCRYKDQoFBAACDQMSBKcBGRsKKgoEBAACDhIEqgECGRocIFRoZSBwcmlvcml0eSBvZiB0
aGlzIGNhc2UuCgoNCgUEAAIOBhIEqgECCgoNCgUEAAIOARIEqgELEwoNCgUEAAIOAxIEqgEW
GArDAgoCBAESBrMBAMQBARq0AiBBIENhc2UgQ2xhc3NpZmljYXRpb24gcmVwcmVzZW50cyB0
aGUgdG9waWMgdGhhdCBhIGNhc2UgaXMgYWJvdXQuIEl0J3MgdmVyeQogaW1wb3J0YW50IHRv
IHVzZSBhY2N1cmF0ZSBjbGFzc2lmaWNhdGlvbnMsIGJlY2F1c2UgdGhleSdyZQogdXNlZCB0
byByb3V0ZSB5b3VyIGNhc2VzIHRvIHNwZWNpYWxpc3RzIHdobyBjYW4gaGVscCB5b3UuCgog
QSBjbGFzc2lmaWNhdGlvbiBhbHdheXMgaGFzIGFuIElEIHRoYXQgaXMgaXRzIHVuaXF1ZSBp
ZGVudGlmaWVyLgogQSB2YWxpZCBJRCBpcyByZXF1aXJlZCB3aGVuIGNyZWF0aW5nIGEgY2Fz
ZS4KCgsKAwQBARIEswEIGgrLAwoEBAECABIEvQECEBq8AyBUaGUgdW5pcXVlIElEIGZvciBh
IGNsYXNzaWZpY2F0aW9uLiBNdXN0IGJlIHNwZWNpZmllZCBmb3IgY2FzZSBjcmVhdGlvbi4K
CiBUbyByZXRyaWV2ZSB2YWxpZCBjbGFzc2lmaWNhdGlvbiBJRHMgZm9yIGNhc2UgY3JlYXRp
b24sIHVzZQogYGNhc2VDbGFzc2lmaWNhdGlvbnMuc2VhcmNoYC4KCiBDbGFzc2lmaWNhdGlv
biBJRHMgcmV0dXJuZWQgYnkgYGNhc2VDbGFzc2lmaWNhdGlvbnMuc2VhcmNoYCBhcmUgZ3Vh
cmFudGVlZAogdG8gYmUgdmFsaWQgZm9yIGF0IGxlYXN0IDYgbW9udGhzLiBJZiBhIGdpdmVu
IGNsYXNzaWZpY2F0aW9uIGlzCiBkZWFjdGl2ZWF0ZWQsIGl0IHdpbGwgaW1tZWRpYXRlbHkg
c3RvcCBiZWluZyByZXR1cm5lZC4gQWZ0ZXIgNiBtb250aHMsCiBgY2FzZS5jcmVhdGVgIHJl
cXVlc3RzIHVzaW5nIHRoZSBjbGFzc2lmaWNhdGlvbiBJRCB3aWxsIGZhaWwuCgoNCgUEAQIA
BRIEvQECCAoNCgUEAQIAARIEvQEJCwoNCgUEAQIAAxIEvQEODwrHAQoEBAECARIEwwECGhq4
ASBBIGRpc3BsYXkgbmFtZSBmb3IgdGhlIGNsYXNzaWZpY2F0aW9uLgoKIFRoZSBkaXNwbGF5
IG5hbWUgaXMgbm90IHN0YXRpYyBhbmQgY2FuIGNoYW5nZS4gVG8gdW5pcXVlbHkgYW5kIGNv
bnNpc3RlbnRseQogaWRlbnRpZnkgY2xhc3NpZmljYXRpb25zLCB1c2UgdGhlIGBDYXNlQ2xh
c3NpZmljYXRpb24uaWRgIGZpZWxkLgoKDQoFBAECAQUSBMMBAggKDQoFBAECAQESBMMBCRUK
DQoFBAECAQMSBMMBGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::Case::Case ===
    # Fields for Case
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: classification Type: 11 (.google.cloud.support.v2.CaseClassification)
    # Field: time_zone Type: 9 ()
    # Field: subscriber_email_addresses Type: 9 ()
    # Field: state Type: 14 (.google.cloud.support.v2.Case.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 11 (.google.cloud.support.v2.Actor)
    # Field: contact_email Type: 9 ()
    # Field: escalated Type: 8 ()
    # Field: test_case Type: 8 ()
    # Field: language_code Type: 9 ()
    # Field: priority Type: 14 (.google.cloud.support.v2.Case.Priority)

# Enum: Case::State
our $Case_STATE_UNSPECIFIED = 0;
our $Case_NEW = 1;
our $Case_IN_PROGRESS_GOOGLE_SUPPORT = 2;
our $Case_ACTION_REQUIRED = 3;
our $Case_SOLUTION_PROVIDED = 4;
our $Case_CLOSED = 5;

# Enum: Case::Priority
our $Case_PRIORITY_UNSPECIFIED = 0;
our $Case_P0 = 1;
our $Case_P1 = 2;
our $Case_P2 = 3;
our $Case_P3 = 4;
our $Case_P4 = 5;

# === Message: Google::Cloud::Support::V2::Case::CaseClassification ===
    # Fields for CaseClassification
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::Case - Compiled Protocol Buffers messages for google/cloud/support/v2/case.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::Case;

    my $msg = Google::Cloud::Support::V2::Case::Case->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        classification => $classification,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::Case::Case->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/case.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::Case::Case

A Case is an object that contains the details of a support case. It
contains fields for the time it was created, its priority, its
classification, and more. Cases can also have comments and attachments that
get added over time.

A case is parented by a Google Cloud organization or project.

Organizations are identified by a number, so the name of a case parented by
an organization would look like this:

```
organizations/123/cases/456
```

Projects have two unique identifiers, an ID and a number, and they look like
this:

```
projects/abc/cases/456
```

```
projects/123/cases/456
```

You can use either of them when calling the API. To learn more
about project identifiers, see [AIP-2510](https://google.aip.dev/cloud/2510).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name for the case.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The short summary of the issue reported in this case.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A broad description of the issue.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Case::CaseClassification>)

The issue classification applicable to this case.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

The timezone of the user who created the support case.
It should be in a format IANA recognizes: https://www.iana.org/time-zones.
There is no additional validation done by the API.

=item * C<< $msg->subscriber_email_addresses() >> / C<< $msg->subscriber_email_addresses($value) >>

Type: C<String>

The email addresses to receive updates on this case.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2::Case::State>)

Output only. The current status of the support case.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this case was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this case was last updated.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Actor::Actor>)

The user who created the case.

Note: The name and email will be obfuscated if the case was created by
Google Support.

=item * C<< $msg->contact_email() >> / C<< $msg->contact_email($value) >>

Type: C<String>

A user-supplied email address to send case update notifications for. This
should only be used in BYOID flows, where we cannot infer the user's email
address directly from their EUCs.

=item * C<< $msg->escalated() >> / C<< $msg->escalated($value) >>

Type: C<Bool>

Whether the case is currently escalated.

=item * C<< $msg->test_case() >> / C<< $msg->test_case($value) >>

Type: C<Bool>

Whether this case was created for internal API testing and should not be
acted on by the support team.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language the user has requested to receive support in. This should be a
BCP 47 language code (e.g., `"en"`, `"zh-CN"`, `"zh-TW"`, `"ja"`, `"ko"`).
If no language or an unsupported language is specified, this field defaults
to English (en).

Language selection during case creation may affect your available support
options. For a list of supported languages and their support working hours,
see: https://cloud.google.com/support/docs/language-working-hours

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2::Case::Priority>)

The priority of this case.

=back

=head3 Enum: Case::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<NEW> => C<1>

=item * C<IN_PROGRESS_GOOGLE_SUPPORT> => C<2>

=item * C<ACTION_REQUIRED> => C<3>

=item * C<SOLUTION_PROVIDED> => C<4>

=item * C<CLOSED> => C<5>

=back

=head3 Enum: Case::Priority

=over 4

=item * C<PRIORITY_UNSPECIFIED> => C<0>

=item * C<P0> => C<1>

=item * C<P1> => C<2>

=item * C<P2> => C<3>

=item * C<P3> => C<4>

=item * C<P4> => C<5>

=back

=head2 Google::Cloud::Support::V2::Case::CaseClassification

A Case Classification represents the topic that a case is about. It's very
important to use accurate classifications, because they're
used to route your cases to specialists who can help you.

A classification always has an ID that is its unique identifier.
A valid ID is required when creating a case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The unique ID for a classification. Must be specified for case creation.

To retrieve valid classification IDs for case creation, use
`caseClassifications.search`.

Classification IDs returned by `caseClassifications.search` are guaranteed
to be valid for at least 6 months. If a given classification is
deactiveated, it will immediately stop being returned. After 6 months,
`case.create` requests using the classification ID will fail.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A display name for the classification.

The display name is not static and can change. To uniquely and consistently
identify classifications, use the `CaseClassification.id` field.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::Case::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
