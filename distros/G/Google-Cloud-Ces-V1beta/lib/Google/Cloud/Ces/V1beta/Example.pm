package Google::Cloud::Ces::V1beta::Example;

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
    eval { require Google::Cloud::Ces::V1beta::ToolsetTool };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9leGFtcGxlLnByb3RvEhdnb29nbGUuY2xvdWQu
Y2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxoqZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvdG9vbHNldF90b29s
LnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvIqkECgdFeGFtcGxlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIm
CgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24Y
AyABKAlCA+BBAVILZGVzY3JpcHRpb24SQQoLZW50cnlfYWdlbnQYBCABKAlCIOBBAfpBGgoY
Y2VzLmdvb2dsZWFwaXMuY29tL0FnZW50UgplbnRyeUFnZW50EkEKCG1lc3NhZ2VzGAUgAygL
MiAuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuTWVzc2FnZUID4EEBUghtZXNzYWdlcxJACgtj
cmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3Jl
YXRlVGltZRJACgt1cGRhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKdXBkYXRlVGltZRIdCgdpbnZhbGlkGAggASgIQgPgQQNSB2ludmFsaWQSEgoE
ZXRhZxgJIAEoCVIEZXRhZzp56kF2ChpjZXMuZ29vZ2xlYXBpcy5jb20vRXhhbXBsZRJFcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vZXhhbXBs
ZXMve2V4YW1wbGV9KghleGFtcGxlczIHZXhhbXBsZSKfAQoHTWVzc2FnZRIXCgRyb2xlGAEg
ASgJQgPgQQFSBHJvbGUSOwoGY2h1bmtzGAIgAygLMh4uZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuQ2h1bmtCA+BBAVIGY2h1bmtzEj4KCmV2ZW50X3RpbWUYBCABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQFSCWV2ZW50VGltZSKCBQoFQ2h1bmsSGQoEdGV4dBgBIAEo
CUID4EEBSABSBHRleHQSJQoKdHJhbnNjcmlwdBgJIAEoCUID4EEBSABSCnRyYW5zY3JpcHQS
OAoEYmxvYhgHIAEoCzIdLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkJsb2JCA+BBAUgAUgRi
bG9iEjgKB3BheWxvYWQYCyABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQFIAFIH
cGF5bG9hZBI7CgVpbWFnZRgFIAEoCzIeLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkltYWdl
QgPgQQFIAFIFaW1hZ2USRQoJdG9vbF9jYWxsGAIgASgLMiEuZ29vZ2xlLmNsb3VkLmNlcy52
MWJldGEuVG9vbENhbGxCA+BBAUgAUgh0b29sQ2FsbBJRCg10b29sX3Jlc3BvbnNlGAMgASgL
MiUuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuVG9vbFJlc3BvbnNlQgPgQQFIAFIMdG9vbFJl
c3BvbnNlElQKDmFnZW50X3RyYW5zZmVyGAQgASgLMiYuZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuQWdlbnRUcmFuc2ZlckID4EEBSABSDWFnZW50VHJhbnNmZXISRgoRdXBkYXRlZF92YXJp
YWJsZXMYCCABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0SABSEHVwZGF0ZWRWYXJpYWJs
ZXMSRgoRZGVmYXVsdF92YXJpYWJsZXMYCiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0
SABSEGRlZmF1bHRWYXJpYWJsZXNCBgoEZGF0YSJBCgRCbG9iEiAKCW1pbWVfdHlwZRgBIAEo
CUID4EECUghtaW1lVHlwZRIXCgRkYXRhGAIgASgMQgPgQQJSBGRhdGEiYgoFSW1hZ2USIAoJ
bWltZV90eXBlGAEgASgJQgPgQQJSCG1pbWVUeXBlEhcKBGRhdGEYAiABKAxCA+BBAlIEZGF0
YRIeCghhbHRfdGV4dBgEIAEoCUID4EEBUgdhbHRUZXh0IusCCghUb29sQ2FsbBI1CgR0b29s
GAIgASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVhcGlzLmNvbS9Ub29sSABSBHRvb2wSTgoMdG9v
bHNldF90b29sGAUgASgLMiQuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuVG9vbHNldFRvb2xC
A+BBAUgAUgt0b29sc2V0VG9vbBITCgJpZBgBIAEoCUID4EEBUgJpZBImCgxkaXNwbGF5X25h
bWUYBCABKAlCA+BBA1ILZGlzcGxheU5hbWUSMAoEYXJncxgDIAEoCzIXLmdvb2dsZS5wcm90
b2J1Zi5TdHJ1Y3RCA+BBAVIEYXJncxIyChNwYXJlbnRfdG9vbF9jYWxsX2lkGAYgASgJQgPg
QQNSEHBhcmVudFRvb2xDYWxsSWQSIgoKYWdlbnRfbmFtZRgHIAEoCUID4EEDUglhZ2VudE5h
bWVCEQoPdG9vbF9pZGVudGlmaWVyIvcCCgxUb29sUmVzcG9uc2USNQoEdG9vbBgCIAEoCUIf
4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbEgAUgR0b29sEk4KDHRvb2xzZXRfdG9v
bBgFIAEoCzIkLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlRvb2xzZXRUb29sQgPgQQFIAFIL
dG9vbHNldFRvb2wSEwoCaWQYASABKAlCA+BBAVICaWQSJgoMZGlzcGxheV9uYW1lGAQgASgJ
QgPgQQNSC2Rpc3BsYXlOYW1lEjgKCHJlc3BvbnNlGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVm
LlN0cnVjdEID4EECUghyZXNwb25zZRIyChNwYXJlbnRfdG9vbF9jYWxsX2lkGAYgASgJQgPg
QQNSEHBhcmVudFRvb2xDYWxsSWQSIgoKYWdlbnRfbmFtZRgHIAEoCUID4EEDUglhZ2VudE5h
bWVCEQoPdG9vbF9pZGVudGlmaWVyInwKDUFnZW50VHJhbnNmZXISQwoMdGFyZ2V0X2FnZW50
GAEgASgJQiDgQQL6QRoKGGNlcy5nb29nbGVhcGlzLmNvbS9BZ2VudFILdGFyZ2V0QWdlbnQS
JgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQNSC2Rpc3BsYXlOYW1lQlwKG2NvbS5nb29nbGUu
Y2xvdWQuY2VzLnYxYmV0YUIMRXhhbXBsZVByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28v
Y2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNwYkr9TAoHEgUOAPsBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQANAoJCgIDAxIDFQAmCgkKAgMEEgMWACkKCAoBCBIDGABECgkKAggLEgMYAEQKCAoB
CBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAtCgkKAggIEgMaAC0KCAoBCBIDGwA0CgkKAggB
EgMbADQKXQoCBAASBB8ATgEaUSBBbiBleGFtcGxlIHJlcHJlc2VudHMgYSBzYW1wbGUgY29u
dmVyc2F0aW9uIGJldHdlZW4gdGhlIHVzZXIgYW5kIHRoZQogYWdlbnQocykuCgoKCgMEAAES
Ax8IDwoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKkwEKBAQAAgASAyoCPRqFASBJZGVu
dGlmaWVyLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGV4YW1wbGUuCiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0v
ZXhhbXBsZXMve2V4YW1wbGV9YAoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkNCgwKBQQA
AgADEgMqEBEKDAoFBAACAAgSAyoSPAoPCggEAAIACJwIABIDKhM7CjUKBAQAAgESAy0CQxoo
IFJlcXVpcmVkLiBEaXNwbGF5IG5hbWUgb2YgdGhlIGV4YW1wbGUuCgoMCgUEAAIBBRIDLQII
CgwKBQQAAgEBEgMtCRUKDAoFBAACAQMSAy0YGQoMCgUEAAIBCBIDLRpCCg8KCAQAAgEInAgA
EgMtG0EKQwoEBAACAhIDMAJCGjYgT3B0aW9uYWwuIEh1bWFuLXJlYWRhYmxlIGRlc2NyaXB0
aW9uIG9mIHRoZSBleGFtcGxlLgoKDAoFBAACAgUSAzACCAoMCgUEAAICARIDMAkUCgwKBQQA
AgIDEgMwFxgKDAoFBAACAggSAzAZQQoPCggEAAICCJwIABIDMBpACvcBCgQEAAIDEgQ2AjkE
GugBIE9wdGlvbmFsLiBUaGUgYWdlbnQgdGhhdCBpbml0aWFsbHkgaGFuZGxlcyB0aGUgY29u
dmVyc2F0aW9uLiBJZiBub3QKIHNwZWNpZmllZCwgdGhlIGV4YW1wbGUgcmVwcmVzZW50cyBh
IGNvbnZlcnNhdGlvbiB0aGF0IGlzIGhhbmRsZWQgYnkgdGhlCiByb290IGFnZW50LiBGb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2Fw
cH0vYWdlbnRzL3thZ2VudH1gCgoMCgUEAAIDBRIDNgIICgwKBQQAAgMBEgM2CRQKDAoFBAAC
AwMSAzYXGAoNCgUEAAIDCBIENhk5AwoPCggEAAIDCJwIABIDNwQqCg4KBwQAAgMInwgSAzgE
SgpSCgQEAAIEEgM8AkkaRSBPcHRpb25hbC4gVGhlIGNvbGxlY3Rpb24gb2YgbWVzc2FnZXMg
dGhhdCBtYWtlIHVwIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAIEBBIDPAIKCgwKBQQAAgQG
EgM8CxIKDAoFBAACBAESAzwTGwoMCgUEAAIEAxIDPB4fCgwKBQQAAgQIEgM8IEgKDwoIBAAC
BAicCAASAzwhRwpECgQEAAIFEgQ/AkAyGjYgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVu
IHRoZSBleGFtcGxlIHdhcyBjcmVhdGVkLgoKDAoFBAACBQYSAz8CGwoMCgUEAAIFARIDPxwn
CgwKBQQAAgUDEgM/KisKDAoFBAACBQgSA0AGMQoPCggEAAIFCJwIABIDQAcwCkkKBAQAAgYS
BEMCRDIaOyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIGV4YW1wbGUgd2FzIGxh
c3QgdXBkYXRlZC4KCgwKBQQAAgYGEgNDAhsKDAoFBAACBgESA0McJwoMCgUEAAIGAxIDQyor
CgwKBQQAAgYIEgNEBjEKDwoIBAACBgicCAASA0QHMAqaAQoEBAACBxIDSAI/GowBIE91dHB1
dCBvbmx5LiBUaGUgZXhhbXBsZSBtYXkgYmVjb21lIGludmFsaWQgaWYgcmVmZXJlbmNpbmcg
cmVzb3VyY2VzIGFyZQogZGVsZXRlZC4gSW52YWxpZCBleGFtcGxlcyB3aWxsIG5vdCBiZSB1
c2VkIGFzIGZldy1zaG90IGV4YW1wbGVzLgoKDAoFBAACBwUSA0gCBgoMCgUEAAIHARIDSAcO
CgwKBQQAAgcDEgNIERIKDAoFBAACBwgSA0gTPgoPCggEAAIHCJwIABIDSBQ9Cq0BCgQEAAII
EgNNAhIanwEgRXRhZyB1c2VkIHRvIGVuc3VyZSB0aGUgb2JqZWN0IGhhc24ndCBjaGFuZ2Vk
IGR1cmluZyBhIHJlYWQtbW9kaWZ5LXdyaXRlCiBvcGVyYXRpb24uIElmIHRoZSBldGFnIGlz
IGVtcHR5LCB0aGUgdXBkYXRlIHdpbGwgb3ZlcndyaXRlIGFueSBjb25jdXJyZW50CiBjaGFu
Z2VzLgoKDAoFBAACCAUSA00CCAoMCgUEAAIIARIDTQkNCgwKBQQAAggDEgNNEBEKLgoCBAES
BFEAXQEaIiBBIG1lc3NhZ2Ugd2l0aGluIGEgY29udmVyc2F0aW9uLgoKCgoDBAEBEgNRCA8K
TQoEBAECABIDUwI7GkAgT3B0aW9uYWwuIFRoZSByb2xlIHdpdGhpbiB0aGUgY29udmVyc2F0
aW9uLCBlLmcuLCB1c2VyLCBhZ2VudC4KCgwKBQQBAgAFEgNTAggKDAoFBAECAAESA1MJDQoM
CgUEAQIAAxIDUxARCgwKBQQBAgAIEgNTEjoKDwoIBAECAAicCAASA1MTOQpGCgQEAQIBEgNW
AkUaOSBPcHRpb25hbC4gQ29udGVudCBvZiB0aGUgbWVzc2FnZSBhcyBhIHNlcmllcyBvZiBj
aHVua3MuCgoMCgUEAQIBBBIDVgIKCgwKBQQBAgEGEgNWCxAKDAoFBAECAQESA1YRFwoMCgUE
AQIBAxIDVhobCgwKBQQBAgEIEgNWHEQKDwoIBAECAQicCAASA1YdQwqpAQoEBAECAhIEWwJc
LxqaASBPcHRpb25hbC4gVGltZXN0YW1wIHdoZW4gdGhlIG1lc3NhZ2Ugd2FzIHNlbnQgb3Ig
cmVjZWl2ZWQuIFNob3VsZCBub3QgYmUKIHVzZWQgaWYgdGhlIG1lc3NhZ2UgaXMgcGFydCBv
ZiBhbgogW2V4YW1wbGVdW2dvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkV4YW1wbGVdLgoKDAoF
BAECAgYSA1sCGwoMCgUEAQICARIDWxwmCgwKBQQBAgIDEgNbKSoKDAoFBAECAggSA1wGLgoP
CggEAQICCJwIABIDXActCjMKAgQCEgVgAIQBARomIEEgY2h1bmsgb2YgY29udGVudCB3aXRo
aW4gYSBtZXNzYWdlLgoKCgoDBAIBEgNgCA0KHAoEBAIIABIFYgKDAQMaDSBDaHVuayBkYXRh
LgoKDAoFBAIIAAESA2IIDAojCgQEAgIAEgNkBD0aFiBPcHRpb25hbC4gVGV4dCBkYXRhLgoK
DAoFBAICAAUSA2QECgoMCgUEAgIAARIDZAsPCgwKBQQCAgADEgNkEhMKDAoFBAICAAgSA2QU
PAoPCggEAgIACJwIABIDZBU7Cj4KBAQCAgESA2cEQxoxIE9wdGlvbmFsLiBUcmFuc2NyaXB0
IGFzc29jaWF0ZWQgd2l0aCB0aGUgYXVkaW8uCgoMCgUEAgIBBRIDZwQKCgwKBQQCAgEBEgNn
CxUKDAoFBAICAQMSA2cYGQoMCgUEAgIBCBIDZxpCCg8KCAQCAgEInAgAEgNnG0EKIwoEBAIC
AhIDagQ7GhYgT3B0aW9uYWwuIEJsb2IgZGF0YS4KCgwKBQQCAgIGEgNqBAgKDAoFBAICAgES
A2oJDQoMCgUEAgICAxIDahARCgwKBQQCAgIIEgNqEjoKDwoIBAICAgicCAASA2oTOQouCgQE
AgIDEgRtBG4xGiAgT3B0aW9uYWwuIEN1c3RvbSBwYXlsb2FkIGRhdGEuCgoMCgUEAgIDBhID
bQQaCgwKBQQCAgMBEgNtGyIKDAoFBAICAwMSA20lJwoMCgUEAgIDCBIDbggwCg8KCAQCAgMI
nAgAEgNuCS8KJAoEBAICBBIDcQQ9GhcgT3B0aW9uYWwuIEltYWdlIGRhdGEuCgoMCgUEAgIE
BhIDcQQJCgwKBQQCAgQBEgNxCg8KDAoFBAICBAMSA3ESEwoMCgUEAgIECBIDcRQ8Cg8KCAQC
AgQInAgAEgNxFTsKMAoEBAICBRIDdAREGiMgT3B0aW9uYWwuIFRvb2wgZXhlY3V0aW9uIHJl
cXVlc3QuCgoMCgUEAgIFBhIDdAQMCgwKBQQCAgUBEgN0DRYKDAoFBAICBQMSA3QZGgoMCgUE
AgIFCBIDdBtDCg8KCAQCAgUInAgAEgN0HEIKMQoEBAICBhIDdwRMGiQgT3B0aW9uYWwuIFRv
b2wgZXhlY3V0aW9uIHJlc3BvbnNlLgoKDAoFBAICBgYSA3cEEAoMCgUEAgIGARIDdxEeCgwK
BQQCAgYDEgN3ISIKDAoFBAICBggSA3cjSwoPCggEAgIGCJwIABIDdyRKCi4KBAQCAgcSA3oE
ThohIE9wdGlvbmFsLiBBZ2VudCB0cmFuc2ZlciBldmVudC4KCgwKBQQCAgcGEgN6BBEKDAoF
BAICBwESA3oSIAoMCgUEAgIHAxIDeiMkCgwKBQQCAgcIEgN6JU0KDwoIBAICBwicCAASA3om
TAptCgQEAgIIEgN+BDEaYCBBIHN0cnVjdCByZXByZXNlbnRzIHZhcmlhYmxlcyB0aGF0IHdl
cmUgdXBkYXRlZCBpbiB0aGUgY29udmVyc2F0aW9uLAoga2V5ZWQgYnkgdmFyaWFibGUgbmFt
ZXMuCgoMCgUEAgIIBhIDfgQaCgwKBQQCAggBEgN+GywKDAoFBAICCAMSA34vMApxCgQEAgIJ
EgSCAQQyGmMgQSBzdHJ1Y3QgcmVwcmVzZW50cyBkZWZhdWx0IHZhcmlhYmxlcyBhdCB0aGUg
c3RhcnQgb2YgdGhlIGNvbnZlcnNhdGlvbiwKIGtleWVkIGJ5IHZhcmlhYmxlIG5hbWVzLgoK
DQoFBAICCQYSBIIBBBoKDQoFBAICCQESBIIBGywKDQoFBAICCQMSBIIBLzEKRgoCBAMSBocB
AI0BARo4IFJlcHJlc2VudHMgYSBibG9iIGlucHV0IG9yIG91dHB1dCBpbiB0aGUgY29udmVy
c2F0aW9uLgoKCwoDBAMBEgSHAQgMCkkKBAQDAgASBIkBAkAaOyBSZXF1aXJlZC4gVGhlIElB
TkEgc3RhbmRhcmQgTUlNRSB0eXBlIG9mIHRoZSBzb3VyY2UgZGF0YS4KCg0KBQQDAgAFEgSJ
AQIICg0KBQQDAgABEgSJAQkSCg0KBQQDAgADEgSJARUWCg0KBQQDAgAIEgSJARc/ChAKCAQD
AgAInAgAEgSJARg+CjAKBAQDAgESBIwBAjoaIiBSZXF1aXJlZC4gUmF3IGJ5dGVzIG9mIHRo
ZSBibG9iLgoKDQoFBAMCAQUSBIwBAgcKDQoFBAMCAQESBIwBCAwKDQoFBAMCAQMSBIwBDxAK
DQoFBAMCAQgSBIwBETkKEAoIBAMCAQicCAASBIwBEjgKSAoCBAQSBpABAJ0BARo6IFJlcHJl
c2VudHMgYW4gaW1hZ2UgaW5wdXQgb3Igb3V0cHV0IGluIHRoZSBjb252ZXJzYXRpb24uCgoL
CgMEBAESBJABCA0KlwEKBAQEAgASBJYBAkAaiAEgUmVxdWlyZWQuIFRoZSBJQU5BIHN0YW5k
YXJkIE1JTUUgdHlwZSBvZiB0aGUgc291cmNlIGRhdGEuCiBTdXBwb3J0ZWQgaW1hZ2UgdHlw
ZXMgaW5jbHVkZXM6CiAgKiBpbWFnZS9wbmcKICAqIGltYWdlL2pwZWcKICAqIGltYWdlL3dl
YnAKCg0KBQQEAgAFEgSWAQIICg0KBQQEAgABEgSWAQkSCg0KBQQEAgADEgSWARUWCg0KBQQE
AgAIEgSWARc/ChAKCAQEAgAInAgAEgSWARg+CjEKBAQEAgESBJkBAjoaIyBSZXF1aXJlZC4g
UmF3IGJ5dGVzIG9mIHRoZSBpbWFnZS4KCg0KBQQEAgEFEgSZAQIHCg0KBQQEAgEBEgSZAQgM
Cg0KBQQEAgEDEgSZAQ8QCg0KBQQEAgEIEgSZARE5ChAKCAQEAgEInAgAEgSZARI4Cj0KBAQE
AgISBJwBAj8aLyBPcHRpb25hbC4gVGhlIGFsdGVybmF0aXZlIHRleHQgZm9yIHRoZSBpbWFn
ZS4KCg0KBQQEAgIFEgScAQIICg0KBQQEAgIBEgScAQkRCg0KBQQEAgIDEgScARQVCg0KBQQE
AgIIEgScARY+ChAKCAQEAgIInAgAEgScARc9ClIKAgQFEgagAQDEAQEaRCBSZXF1ZXN0IGZv
ciB0aGUgY2xpZW50IG9yIHRoZSBhZ2VudCB0byBleGVjdXRlIHRoZSBzcGVjaWZpZWQgdG9v
bC4KCgsKAwQFARIEoAEIEAp3CgQEBQgAEgajAQKtAQMaZyBUaGUgaWRlbnRpZmllciBvZiB0
aGUgdG9vbCB0byBleGVjdXRlLiBJdCBjb3VsZCBiZSBlaXRoZXIgYSBwZXJzaXN0ZWQgdG9v
bAogb3IgYSB0b29sIGZyb20gYSB0b29sc2V0LgoKDQoFBAUIAAESBKMBCBcKhwEKBAQFAgAS
BqYBBKkBBhp3IE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdG9vbCB0byBleGVjdXRlLgog
Rm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMv
e2FwcH0vdG9vbHMve3Rvb2x9YAoKDQoFBAUCAAUSBKYBBAoKDQoFBAUCAAESBKYBCw8KDQoF
BAUCAAMSBKYBEhMKDwoFBAUCAAgSBqYBFKkBBQoQCggEBQIACJwIABIEpwEGLAoPCgcEBQIA
CJ8IEgSoAQZLCjYKBAQFAgESBKwBBEoaKCBPcHRpb25hbC4gVGhlIHRvb2xzZXQgdG9vbCB0
byBleGVjdXRlLgoKDQoFBAUCAQYSBKwBBA8KDQoFBAUCAQESBKwBEBwKDQoFBAUCAQMSBKwB
HyAKDQoFBAUCAQgSBKwBIUkKEAoIBAUCAQicCAASBKwBIkgK0QEKBAQFAgISBLIBAjkawgEg
T3B0aW9uYWwuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgdG9vbCBjYWxsLiBJZiBw
b3B1bGF0ZWQsIHRoZSBjbGllbnQKIHNob3VsZCByZXR1cm4gdGhlIGV4ZWN1dGlvbiByZXN1
bHQgd2l0aCB0aGUgbWF0Y2hpbmcgSUQgaW4KIFtUb29sUmVzcG9uc2VdW2dvb2dsZS5jbG91
ZC5jZXMudjFiZXRhLlRvb2xSZXNwb25zZS5pZF0uCgoNCgUEBQICBRIEsgECCAoNCgUEBQIC
ARIEsgEJCwoNCgUEBQICAxIEsgEODwoNCgUEBQICCBIEsgEQOAoQCggEBQICCJwIABIEsgER
Nwo2CgQEBQIDEgS1AQJGGiggT3V0cHV0IG9ubHkuIERpc3BsYXkgbmFtZSBvZiB0aGUgdG9v
bC4KCg0KBQQFAgMFEgS1AQIICg0KBQQFAgMBEgS1AQkVCg0KBQQFAgMDEgS1ARgZCg0KBQQF
AgMIEgS1ARpFChAKCAQFAgMInAgAEgS1ARtECl4KBAQFAgQSBLkBAksaUCBPcHRpb25hbC4g
VGhlIGlucHV0IHBhcmFtZXRlcnMgYW5kIHZhbHVlcyBmb3IgdGhlIHRvb2wgaW4gSlNPTiBv
YmplY3QKIGZvcm1hdC4KCg0KBQQFAgQGEgS5AQIYCg0KBQQFAgQBEgS5ARkdCg0KBQQFAgQD
EgS5ASAhCg0KBQQFAgQIEgS5ASJKChAKCAQFAgQInAgAEgS5ASNJCqMCCgQEBQIFEgS/AQJN
GpQCIE91dHB1dCBvbmx5LiBUaGUgaWQgb2YgdGhlIHRvb2wgY2FsbCB0aGF0IGNhdXNlZCB0
aGlzIG9uZSwgd2hlbiBpdCB3YXMKIGlzc3VlZCBieSBhIHN1Yi1hZ2VudCB3b3JraW5nIG9u
IGJlaGFsZiBvZiBhIHBhcmVudCBjYWxsLiBFbXB0eSBmb3IKIHRvcC1sZXZlbCBjYWxscy4g
TGV0cyBhIGNsaWVudCBncm91cCBhIHN1Yi1hZ2VudCdzIHdvcmsgdW5kZXIgdGhlIGNhbGwg
dGhhdAogc3RhcnRlZCBpdCBpbnN0ZWFkIG9mIHJlbmRlcmluZyBldmVyeSBzdGVwIGFzIGEg
c2libGluZy4KCg0KBQQFAgUFEgS/AQIICg0KBQQFAgUBEgS/AQkcCg0KBQQFAgUDEgS/AR8g
Cg0KBQQFAgUIEgS/ASFMChAKCAQFAgUInAgAEgS/ASJLCpYBCgQEBQIGEgTDAQJEGocBIE91
dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBhZ2VudCB0aGF0IGlzc3Vl
ZCB0aGlzIGNhbGwsIGUuZy4KICJDb250cmFjdCBBcmNoaXRlY3QiLiBFbXB0eSB3aGVuIHRo
ZSByb290IGFnZW50IGlzc3VlZCBpdC4KCg0KBQQFAgYFEgTDAQIICg0KBQQFAgYBEgTDAQkT
Cg0KBQQFAgYDEgTDARYXCg0KBQQFAgYIEgTDARhDChAKCAQFAgYInAgAEgTDARlCClUKAgQG
EgbHAQDsAQEaRyBUaGUgZXhlY3V0aW9uIHJlc3VsdCBvZiBhIHNwZWNpZmljIHRvb2wgZnJv
bSB0aGUgY2xpZW50IG9yIHRoZSBhZ2VudC4KCgsKAwQGARIExwEIFAp+CgQEBggAEgbKAQLU
AQMabiBUaGUgaWRlbnRpZmllciBvZiB0aGUgdG9vbCB0aGF0IGdvdCBleGVjdXRlZC4gSXQg
Y291bGQgYmUgZWl0aGVyIGEKIHBlcnNpc3RlZCB0b29sIG9yIGEgdG9vbCBmcm9tIGEgdG9v
bHNldC4KCg0KBQQGCAABEgTKAQgXCocBCgQEBgIAEgbNAQTQAQYadyBPcHRpb25hbC4gVGhl
IG5hbWUgb2YgdGhlIHRvb2wgdG8gZXhlY3V0ZS4KIEZvcm1hdDogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfWAKCg0K
BQQGAgAFEgTNAQQKCg0KBQQGAgABEgTNAQsPCg0KBQQGAgADEgTNARITCg8KBQQGAgAIEgbN
ARTQAQUKEAoIBAYCAAicCAASBM4BBiwKDwoHBAYCAAifCBIEzwEGSwo9CgQEBgIBEgTTAQRK
Gi8gT3B0aW9uYWwuIFRoZSB0b29sc2V0IHRvb2wgdGhhdCBnb3QgZXhlY3V0ZWQuCgoNCgUE
BgIBBhIE0wEEDwoNCgUEBgIBARIE0wEQHAoNCgUEBgIBAxIE0wEfIAoNCgUEBgIBCBIE0wEh
SQoQCggEBgIBCJwIABIE0wEiSAp0CgQEBgICEgTYAQI5GmYgT3B0aW9uYWwuIFRoZSBtYXRj
aGluZyBJRCBvZiB0aGUgW3Rvb2wKIGNhbGxdW2dvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlRv
b2xDYWxsXSB0aGUgcmVzcG9uc2UgaXMgZm9yLgoKDQoFBAYCAgUSBNgBAggKDQoFBAYCAgES
BNgBCQsKDQoFBAYCAgMSBNgBDg8KDQoFBAYCAggSBNgBEDgKEAoIBAYCAgicCAASBNgBETcK
NgoEBAYCAxIE2wECRhooIE91dHB1dCBvbmx5LiBEaXNwbGF5IG5hbWUgb2YgdGhlIHRvb2wu
CgoNCgUEBgIDBRIE2wECCAoNCgUEBgIDARIE2wEJFQoNCgUEBgIDAxIE2wEYGQoNCgUEBgID
CBIE2wEaRQoQCggEBgIDCJwIABIE2wEbRAqWAgoEBAYCBBIE4QECTxqHAiBSZXF1aXJlZC4g
VGhlIHRvb2wgZXhlY3V0aW9uIHJlc3VsdCBpbiBKU09OIG9iamVjdCBmb3JtYXQuCiBVc2Ug
Im91dHB1dCIga2V5IHRvIHNwZWNpZnkgdG9vbCByZXNwb25zZSBhbmQgImVycm9yIiBrZXkg
dG8gc3BlY2lmeQogZXJyb3IgZGV0YWlscyAoaWYgYW55KS4gSWYgIm91dHB1dCIgYW5kICJl
cnJvciIga2V5cyBhcmUgbm90IHNwZWNpZmllZCwKIHRoZW4gd2hvbGUgInJlc3BvbnNlIiBp
cyB0cmVhdGVkIGFzIHRvb2wgZXhlY3V0aW9uIHJlc3VsdC4KCg0KBQQGAgQGEgThAQIYCg0K
BQQGAgQBEgThARkhCg0KBQQGAgQDEgThASQlCg0KBQQGAgQIEgThASZOChAKCAQGAgQInAgA
EgThASdNCqMCCgQEBgIFEgTnAQJNGpQCIE91dHB1dCBvbmx5LiBUaGUgaWQgb2YgdGhlIHRv
b2wgY2FsbCB0aGF0IGNhdXNlZCB0aGlzIG9uZSwgd2hlbiBpdCB3YXMKIGlzc3VlZCBieSBh
IHN1Yi1hZ2VudCB3b3JraW5nIG9uIGJlaGFsZiBvZiBhIHBhcmVudCBjYWxsLiBFbXB0eSBm
b3IKIHRvcC1sZXZlbCBjYWxscy4gTGV0cyBhIGNsaWVudCBncm91cCBhIHN1Yi1hZ2VudCdz
IHdvcmsgdW5kZXIgdGhlIGNhbGwgdGhhdAogc3RhcnRlZCBpdCBpbnN0ZWFkIG9mIHJlbmRl
cmluZyBldmVyeSBzdGVwIGFzIGEgc2libGluZy4KCg0KBQQGAgUFEgTnAQIICg0KBQQGAgUB
EgTnAQkcCg0KBQQGAgUDEgTnAR8gCg0KBQQGAgUIEgTnASFMChAKCAQGAgUInAgAEgTnASJL
CpYBCgQEBgIGEgTrAQJEGocBIE91dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBuYW1lIG9m
IHRoZSBhZ2VudCB0aGF0IGlzc3VlZCB0aGlzIGNhbGwsIGUuZy4KICJDb250cmFjdCBBcmNo
aXRlY3QiLiBFbXB0eSB3aGVuIHRoZSByb290IGFnZW50IGlzc3VlZCBpdC4KCg0KBQQGAgYF
EgTrAQIICg0KBQQGAgYBEgTrAQkTCg0KBQQGAgYDEgTrARYXCg0KBQQGAgYIEgTrARhDChAK
CAQGAgYInAgAEgTrARlCCmQKAgQHEgbwAQD7AQEaViBSZXByZXNlbnRzIGFuIGV2ZW50IGlu
ZGljYXRpbmcgdGhlIHRyYW5zZmVyIG9mIGEgY29udmVyc2F0aW9uIHRvIGEgZGlmZmVyZW50
CiBhZ2VudC4KCgsKAwQHARIE8AEIFQrkAQoEBAcCABIG9AEC9wEEGtMBIFJlcXVpcmVkLiBU
aGUgYWdlbnQgdG8gd2hpY2ggdGhlIGNvbnZlcnNhdGlvbiBpcyBiZWluZyB0cmFuc2ZlcnJl
ZC4gVGhlCiBhZ2VudCB3aWxsIGhhbmRsZSB0aGUgY29udmVyc2F0aW9uIGZyb20gdGhpcyBw
b2ludCBmb3J3YXJkLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2FwcHMve2FwcH0vYWdlbnRzL3thZ2VudH1gCgoNCgUEBwIABRIE9AECCAoN
CgUEBwIAARIE9AEJFQoNCgUEBwIAAxIE9AEYGQoPCgUEBwIACBIG9AEa9wEDChAKCAQHAgAI
nAgAEgT1AQQqCg8KBwQHAgAInwgSBPYBBEoKNwoEBAcCARIE+gECRhopIE91dHB1dCBvbmx5
LiBEaXNwbGF5IG5hbWUgb2YgdGhlIGFnZW50LgoKDQoFBAcCAQUSBPoBAggKDQoFBAcCAQES
BPoBCRUKDQoFBAcCAQMSBPoBGBkKDQoFBAcCAQgSBPoBGkUKEAoIBAcCAQicCAASBPoBG0Ri
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Example::Example ===
    # Fields for Example
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: entry_agent Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.ces.v1beta.Message)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: invalid Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Example::Message ===
    # Fields for Message
    # Field: role Type: 9 ()
    # Field: chunks Type: 11 (.google.cloud.ces.v1beta.Chunk)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Ces::V1beta::Example::Chunk ===
    # Fields for Chunk
    # Field: text Type: 9 ()
    # Field: transcript Type: 9 ()
    # Field: blob Type: 11 (.google.cloud.ces.v1beta.Blob)
    # Field: payload Type: 11 (.google.protobuf.Struct)
    # Field: image Type: 11 (.google.cloud.ces.v1beta.Image)
    # Field: tool_call Type: 11 (.google.cloud.ces.v1beta.ToolCall)
    # Field: tool_response Type: 11 (.google.cloud.ces.v1beta.ToolResponse)
    # Field: agent_transfer Type: 11 (.google.cloud.ces.v1beta.AgentTransfer)
    # Field: updated_variables Type: 11 (.google.protobuf.Struct)
    # Field: default_variables Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Ces::V1beta::Example::Blob ===
    # Fields for Blob
    # Field: mime_type Type: 9 ()
    # Field: data Type: 12 ()

# === Message: Google::Cloud::Ces::V1beta::Example::Image ===
    # Fields for Image
    # Field: mime_type Type: 9 ()
    # Field: data Type: 12 ()
    # Field: alt_text Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Example::ToolCall ===
    # Fields for ToolCall
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: args Type: 11 (.google.protobuf.Struct)
    # Field: parent_tool_call_id Type: 9 ()
    # Field: agent_name Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Example::ToolResponse ===
    # Fields for ToolResponse
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: response Type: 11 (.google.protobuf.Struct)
    # Field: parent_tool_call_id Type: 9 ()
    # Field: agent_name Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Example::AgentTransfer ===
    # Fields for AgentTransfer
    # Field: target_agent Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Example - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/example.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Example;

    my $msg = Google::Cloud::Ces::V1beta::Example::Example->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        entry_agent => $entry_agent,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Example::Example->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/example.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Example::Example

An example represents a sample conversation between the user and the
agent(s).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the example.
Format:
`projects/{project}/locations/{location}/apps/{app}/examples/{example}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the example.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Human-readable description of the example.

=item * C<< $msg->entry_agent() >> / C<< $msg->entry_agent($value) >>

Type: C<String>

Optional. The agent that initially handles the conversation. If not
specified, the example represents a conversation that is handled by the
root agent. Format:
`projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::Message>)

Optional. The collection of messages that make up the conversation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the example was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the example was last updated.

=item * C<< $msg->invalid() >> / C<< $msg->invalid($value) >>

Type: C<Bool>

Output only. The example may become invalid if referencing resources are
deleted. Invalid examples will not be used as few-shot examples.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Etag used to ensure the object hasn't changed during a read-modify-write
operation. If the etag is empty, the update will overwrite any concurrent
changes.

=back

=head2 Google::Cloud::Ces::V1beta::Example::Message

A message within a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Optional. The role within the conversation, e.g., user, agent.

=item * C<< $msg->chunks() >> / C<< $msg->chunks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::Chunk>)

Optional. Content of the message as a series of chunks.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp when the message was sent or received. Should not be
used if the message is part of an
[example][google.cloud.ces.v1beta.Example].

=back

=head2 Google::Cloud::Ces::V1beta::Example::Chunk

A chunk of content within a message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Optional. Text data.

=item * C<< $msg->transcript() >> / C<< $msg->transcript($value) >>

Type: C<String>

Optional. Transcript associated with the audio.

=item * C<< $msg->blob() >> / C<< $msg->blob($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::Blob>)

Optional. Blob data.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. Custom payload data.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::Image>)

Optional. Image data.

=item * C<< $msg->tool_call() >> / C<< $msg->tool_call($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::ToolCall>)

Optional. Tool execution request.

=item * C<< $msg->tool_response() >> / C<< $msg->tool_response($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::ToolResponse>)

Optional. Tool execution response.

=item * C<< $msg->agent_transfer() >> / C<< $msg->agent_transfer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::AgentTransfer>)

Optional. Agent transfer event.

=item * C<< $msg->updated_variables() >> / C<< $msg->updated_variables($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

A struct represents variables that were updated in the conversation,
keyed by variable names.

=item * C<< $msg->default_variables() >> / C<< $msg->default_variables($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

A struct represents default variables at the start of the conversation,
keyed by variable names.

=back

=head2 Google::Cloud::Ces::V1beta::Example::Blob

Represents a blob input or output in the conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Required. The IANA standard MIME type of the source data.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

Required. Raw bytes of the blob.

=back

=head2 Google::Cloud::Ces::V1beta::Example::Image

Represents an image input or output in the conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Required. The IANA standard MIME type of the source data.
Supported image types includes:
 * image/png
 * image/jpeg
 * image/webp

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

Required. Raw bytes of the image.

=item * C<< $msg->alt_text() >> / C<< $msg->alt_text($value) >>

Type: C<String>

Optional. The alternative text for the image.

=back

=head2 Google::Cloud::Ces::V1beta::Example::ToolCall

Request for the client or the agent to execute the specified tool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to execute.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

Optional. The toolset tool to execute.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional. The unique identifier of the tool call. If populated, the client
should return the execution result with the matching ID in
[ToolResponse][google.cloud.ces.v1beta.ToolResponse.id].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name of the tool.

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The input parameters and values for the tool in JSON object
format.

=item * C<< $msg->parent_tool_call_id() >> / C<< $msg->parent_tool_call_id($value) >>

Type: C<String>

Output only. The id of the tool call that caused this one, when it was
issued by a sub-agent working on behalf of a parent call. Empty for
top-level calls. Lets a client group a sub-agent's work under the call that
started it instead of rendering every step as a sibling.

=item * C<< $msg->agent_name() >> / C<< $msg->agent_name($value) >>

Type: C<String>

Output only. Human-readable name of the agent that issued this call, e.g.
"Contract Architect". Empty when the root agent issued it.

=back

=head2 Google::Cloud::Ces::V1beta::Example::ToolResponse

The execution result of a specific tool from the client or the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to execute.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

Optional. The toolset tool that got executed.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional. The matching ID of the [tool
call][google.cloud.ces.v1beta.ToolCall] the response is for.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name of the tool.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Required. The tool execution result in JSON object format.
Use "output" key to specify tool response and "error" key to specify
error details (if any). If "output" and "error" keys are not specified,
then whole "response" is treated as tool execution result.

=item * C<< $msg->parent_tool_call_id() >> / C<< $msg->parent_tool_call_id($value) >>

Type: C<String>

Output only. The id of the tool call that caused this one, when it was
issued by a sub-agent working on behalf of a parent call. Empty for
top-level calls. Lets a client group a sub-agent's work under the call that
started it instead of rendering every step as a sibling.

=item * C<< $msg->agent_name() >> / C<< $msg->agent_name($value) >>

Type: C<String>

Output only. Human-readable name of the agent that issued this call, e.g.
"Contract Architect". Empty when the root agent issued it.

=back

=head2 Google::Cloud::Ces::V1beta::Example::AgentTransfer

Represents an event indicating the transfer of a conversation to a different
agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_agent() >> / C<< $msg->target_agent($value) >>

Type: C<String>

Required. The agent to which the conversation is being transferred. The
agent will handle the conversation from this point forward. Format:
`projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name of the agent.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Example::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
