package Google::Cloud::Ces::V1::Example;

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
    eval { require Google::Cloud::Ces::V1::ToolsetTool };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQvY2VzL3YxL2V4YW1wbGUucHJvdG8SE2dvb2dsZS5jbG91ZC5jZXMu
djEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aJmdvb2dsZS9jbG91ZC9jZXMvdjEvdG9vbHNldF90b29sLnByb3RvGhxnb29n
bGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvIqUECgdFeGFtcGxlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25h
bWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SQQoLZW50cnlfYWdlbnQYBCABKAlCIOBBAfpBGgoYY2VzLmdvb2dsZWFw
aXMuY29tL0FnZW50UgplbnRyeUFnZW50Ej0KCG1lc3NhZ2VzGAUgAygLMhwuZ29vZ2xlLmNs
b3VkLmNlcy52MS5NZXNzYWdlQgPgQQFSCG1lc3NhZ2VzEkAKC2NyZWF0ZV90aW1lGAYgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0
ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVU
aW1lEh0KB2ludmFsaWQYCCABKAhCA+BBA1IHaW52YWxpZBISCgRldGFnGAkgASgJUgRldGFn
OnnqQXYKGmNlcy5nb29nbGVhcGlzLmNvbS9FeGFtcGxlEkVwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9leGFtcGxlcy97ZXhhbXBsZX0qCGV4
YW1wbGVzMgdleGFtcGxlIpsBCgdNZXNzYWdlEhcKBHJvbGUYASABKAlCA+BBAVIEcm9sZRI3
CgZjaHVua3MYAiADKAsyGi5nb29nbGUuY2xvdWQuY2VzLnYxLkNodW5rQgPgQQFSBmNodW5r
cxI+CgpldmVudF90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEB
UglldmVudFRpbWUi7gQKBUNodW5rEhkKBHRleHQYASABKAlCA+BBAUgAUgR0ZXh0EiUKCnRy
YW5zY3JpcHQYCSABKAlCA+BBAUgAUgp0cmFuc2NyaXB0EjQKBGJsb2IYByABKAsyGS5nb29n
bGUuY2xvdWQuY2VzLnYxLkJsb2JCA+BBAUgAUgRibG9iEjgKB3BheWxvYWQYCyABKAsyFy5n
b29nbGUucHJvdG9idWYuU3RydWN0QgPgQQFIAFIHcGF5bG9hZBI3CgVpbWFnZRgFIAEoCzIa
Lmdvb2dsZS5jbG91ZC5jZXMudjEuSW1hZ2VCA+BBAUgAUgVpbWFnZRJBCgl0b29sX2NhbGwY
AiABKAsyHS5nb29nbGUuY2xvdWQuY2VzLnYxLlRvb2xDYWxsQgPgQQFIAFIIdG9vbENhbGwS
TQoNdG9vbF9yZXNwb25zZRgDIAEoCzIhLmdvb2dsZS5jbG91ZC5jZXMudjEuVG9vbFJlc3Bv
bnNlQgPgQQFIAFIMdG9vbFJlc3BvbnNlElAKDmFnZW50X3RyYW5zZmVyGAQgASgLMiIuZ29v
Z2xlLmNsb3VkLmNlcy52MS5BZ2VudFRyYW5zZmVyQgPgQQFIAFINYWdlbnRUcmFuc2ZlchJG
ChF1cGRhdGVkX3ZhcmlhYmxlcxgIIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RIAFIQ
dXBkYXRlZFZhcmlhYmxlcxJGChFkZWZhdWx0X3ZhcmlhYmxlcxgKIAEoCzIXLmdvb2dsZS5w
cm90b2J1Zi5TdHJ1Y3RIAFIQZGVmYXVsdFZhcmlhYmxlc0IGCgRkYXRhIkEKBEJsb2ISIAoJ
bWltZV90eXBlGAEgASgJQgPgQQJSCG1pbWVUeXBlEhcKBGRhdGEYAiABKAxCA+BBAlIEZGF0
YSJCCgVJbWFnZRIgCgltaW1lX3R5cGUYASABKAlCA+BBAlIIbWltZVR5cGUSFwoEZGF0YRgC
IAEoDEID4EECUgRkYXRhIo8CCghUb29sQ2FsbBI1CgR0b29sGAIgASgJQh/gQQH6QRkKF2Nl
cy5nb29nbGVhcGlzLmNvbS9Ub29sSABSBHRvb2wSSgoMdG9vbHNldF90b29sGAUgASgLMiAu
Z29vZ2xlLmNsb3VkLmNlcy52MS5Ub29sc2V0VG9vbEID4EEBSABSC3Rvb2xzZXRUb29sEhMK
AmlkGAEgASgJQgPgQQFSAmlkEiYKDGRpc3BsYXlfbmFtZRgEIAEoCUID4EEDUgtkaXNwbGF5
TmFtZRIwCgRhcmdzGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBUgRhcmdz
QhEKD3Rvb2xfaWRlbnRpZmllciKbAgoMVG9vbFJlc3BvbnNlEjUKBHRvb2wYAiABKAlCH+BB
AfpBGQoXY2VzLmdvb2dsZWFwaXMuY29tL1Rvb2xIAFIEdG9vbBJKCgx0b29sc2V0X3Rvb2wY
BSABKAsyIC5nb29nbGUuY2xvdWQuY2VzLnYxLlRvb2xzZXRUb29sQgPgQQFIAFILdG9vbHNl
dFRvb2wSEwoCaWQYASABKAlCA+BBAVICaWQSJgoMZGlzcGxheV9uYW1lGAQgASgJQgPgQQNS
C2Rpc3BsYXlOYW1lEjgKCHJlc3BvbnNlGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVj
dEID4EECUghyZXNwb25zZUIRCg90b29sX2lkZW50aWZpZXIifAoNQWdlbnRUcmFuc2ZlchJD
Cgx0YXJnZXRfYWdlbnQYASABKAlCIOBBAvpBGgoYY2VzLmdvb2dsZWFwaXMuY29tL0FnZW50
Ugt0YXJnZXRBZ2VudBImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBA1ILZGlzcGxheU5hbWVC
VAoXY29tLmdvb2dsZS5jbG91ZC5jZXMudjFCDEV4YW1wbGVQcm90b1ABWiljbG91ZC5nb29n
bGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkqtQgoHEgUOAOMBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAMAoJCgIDAxIDFQAmCgkKAgMEEgMWACkKCAoBCBIDGABACgkKAggLEgMY
AEAKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAtCgkKAggIEgMaAC0KCAoBCBIDGwAw
CgkKAggBEgMbADAKXQoCBAASBB8ATgEaUSBBbiBleGFtcGxlIHJlcHJlc2VudHMgYSBzYW1w
bGUgY29udmVyc2F0aW9uIGJldHdlZW4gdGhlIHVzZXIgYW5kIHRoZQogYWdlbnQocykuCgoK
CgMEAAESAx8IDwoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKkwEKBAQAAgASAyoCPRqF
ASBJZGVudGlmaWVyLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGV4YW1wbGUuCiBG
b3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMv
e2FwcH0vZXhhbXBsZXMve2V4YW1wbGV9YAoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkN
CgwKBQQAAgADEgMqEBEKDAoFBAACAAgSAyoSPAoPCggEAAIACJwIABIDKhM7CjUKBAQAAgES
Ay0CQxooIFJlcXVpcmVkLiBEaXNwbGF5IG5hbWUgb2YgdGhlIGV4YW1wbGUuCgoMCgUEAAIB
BRIDLQIICgwKBQQAAgEBEgMtCRUKDAoFBAACAQMSAy0YGQoMCgUEAAIBCBIDLRpCCg8KCAQA
AgEInAgAEgMtG0EKQwoEBAACAhIDMAJCGjYgT3B0aW9uYWwuIEh1bWFuLXJlYWRhYmxlIGRl
c2NyaXB0aW9uIG9mIHRoZSBleGFtcGxlLgoKDAoFBAACAgUSAzACCAoMCgUEAAICARIDMAkU
CgwKBQQAAgIDEgMwFxgKDAoFBAACAggSAzAZQQoPCggEAAICCJwIABIDMBpACvcBCgQEAAID
EgQ2AjkEGugBIE9wdGlvbmFsLiBUaGUgYWdlbnQgdGhhdCBpbml0aWFsbHkgaGFuZGxlcyB0
aGUgY29udmVyc2F0aW9uLiBJZiBub3QKIHNwZWNpZmllZCwgdGhlIGV4YW1wbGUgcmVwcmVz
ZW50cyBhIGNvbnZlcnNhdGlvbiB0aGF0IGlzIGhhbmRsZWQgYnkgdGhlCiByb290IGFnZW50
LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fw
cHMve2FwcH0vYWdlbnRzL3thZ2VudH1gCgoMCgUEAAIDBRIDNgIICgwKBQQAAgMBEgM2CRQK
DAoFBAACAwMSAzYXGAoNCgUEAAIDCBIENhk5AwoPCggEAAIDCJwIABIDNwQqCg4KBwQAAgMI
nwgSAzgESgpSCgQEAAIEEgM8AkkaRSBPcHRpb25hbC4gVGhlIGNvbGxlY3Rpb24gb2YgbWVz
c2FnZXMgdGhhdCBtYWtlIHVwIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAIEBBIDPAIKCgwK
BQQAAgQGEgM8CxIKDAoFBAACBAESAzwTGwoMCgUEAAIEAxIDPB4fCgwKBQQAAgQIEgM8IEgK
DwoIBAACBAicCAASAzwhRwpECgQEAAIFEgQ/AkAyGjYgT3V0cHV0IG9ubHkuIFRpbWVzdGFt
cCB3aGVuIHRoZSBleGFtcGxlIHdhcyBjcmVhdGVkLgoKDAoFBAACBQYSAz8CGwoMCgUEAAIF
ARIDPxwnCgwKBQQAAgUDEgM/KisKDAoFBAACBQgSA0AGMQoPCggEAAIFCJwIABIDQAcwCkkK
BAQAAgYSBEMCRDIaOyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIGV4YW1wbGUg
d2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgYGEgNDAhsKDAoFBAACBgESA0McJwoMCgUEAAIG
AxIDQyorCgwKBQQAAgYIEgNEBjEKDwoIBAACBgicCAASA0QHMAqaAQoEBAACBxIDSAI/GowB
IE91dHB1dCBvbmx5LiBUaGUgZXhhbXBsZSBtYXkgYmVjb21lIGludmFsaWQgaWYgcmVmZXJl
bmNpbmcgcmVzb3VyY2VzIGFyZQogZGVsZXRlZC4gSW52YWxpZCBleGFtcGxlcyB3aWxsIG5v
dCBiZSB1c2VkIGFzIGZldy1zaG90IGV4YW1wbGVzLgoKDAoFBAACBwUSA0gCBgoMCgUEAAIH
ARIDSAcOCgwKBQQAAgcDEgNIERIKDAoFBAACBwgSA0gTPgoPCggEAAIHCJwIABIDSBQ9Cq0B
CgQEAAIIEgNNAhIanwEgRXRhZyB1c2VkIHRvIGVuc3VyZSB0aGUgb2JqZWN0IGhhc24ndCBj
aGFuZ2VkIGR1cmluZyBhIHJlYWQtbW9kaWZ5LXdyaXRlCiBvcGVyYXRpb24uIElmIHRoZSBl
dGFnIGlzIGVtcHR5LCB0aGUgdXBkYXRlIHdpbGwgb3ZlcndyaXRlIGFueSBjb25jdXJyZW50
CiBjaGFuZ2VzLgoKDAoFBAACCAUSA00CCAoMCgUEAAIIARIDTQkNCgwKBQQAAggDEgNNEBEK
LgoCBAESBFEAXAEaIiBBIG1lc3NhZ2Ugd2l0aGluIGEgY29udmVyc2F0aW9uLgoKCgoDBAEB
EgNRCA8KTQoEBAECABIDUwI7GkAgT3B0aW9uYWwuIFRoZSByb2xlIHdpdGhpbiB0aGUgY29u
dmVyc2F0aW9uLCBlLmcuLCB1c2VyLCBhZ2VudC4KCgwKBQQBAgAFEgNTAggKDAoFBAECAAES
A1MJDQoMCgUEAQIAAxIDUxARCgwKBQQBAgAIEgNTEjoKDwoIBAECAAicCAASA1MTOQpGCgQE
AQIBEgNWAkUaOSBPcHRpb25hbC4gQ29udGVudCBvZiB0aGUgbWVzc2FnZSBhcyBhIHNlcmll
cyBvZiBjaHVua3MuCgoMCgUEAQIBBBIDVgIKCgwKBQQBAgEGEgNWCxAKDAoFBAECAQESA1YR
FwoMCgUEAQIBAxIDVhobCgwKBQQBAgEIEgNWHEQKDwoIBAECAQicCAASA1YdQwqkAQoEBAEC
AhIEWgJbLxqVASBPcHRpb25hbC4gVGltZXN0YW1wIHdoZW4gdGhlIG1lc3NhZ2Ugd2FzIHNl
bnQgb3IgcmVjZWl2ZWQuIFNob3VsZCBub3QgYmUKIHVzZWQgaWYgdGhlIG1lc3NhZ2UgaXMg
cGFydCBvZiBhbiBbZXhhbXBsZV1bZ29vZ2xlLmNsb3VkLmNlcy52MS5FeGFtcGxlXS4KCgwK
BQQBAgIGEgNaAhsKDAoFBAECAgESA1ocJgoMCgUEAQICAxIDWikqCgwKBQQBAgIIEgNbBi4K
DwoIBAECAgicCAASA1sHLQozCgIEAhIFXwCDAQEaJiBBIGNodW5rIG9mIGNvbnRlbnQgd2l0
aGluIGEgbWVzc2FnZS4KCgoKAwQCARIDXwgNChwKBAQCCAASBWECggEDGg0gQ2h1bmsgZGF0
YS4KCgwKBQQCCAABEgNhCAwKIwoEBAICABIDYwQ9GhYgT3B0aW9uYWwuIFRleHQgZGF0YS4K
CgwKBQQCAgAFEgNjBAoKDAoFBAICAAESA2MLDwoMCgUEAgIAAxIDYxITCgwKBQQCAgAIEgNj
FDwKDwoIBAICAAicCAASA2MVOwo+CgQEAgIBEgNmBEMaMSBPcHRpb25hbC4gVHJhbnNjcmlw
dCBhc3NvY2lhdGVkIHdpdGggdGhlIGF1ZGlvLgoKDAoFBAICAQUSA2YECgoMCgUEAgIBARID
ZgsVCgwKBQQCAgEDEgNmGBkKDAoFBAICAQgSA2YaQgoPCggEAgIBCJwIABIDZhtBCiMKBAQC
AgISA2kEOxoWIE9wdGlvbmFsLiBCbG9iIGRhdGEuCgoMCgUEAgICBhIDaQQICgwKBQQCAgIB
EgNpCQ0KDAoFBAICAgMSA2kQEQoMCgUEAgICCBIDaRI6Cg8KCAQCAgIInAgAEgNpEzkKLgoE
BAICAxIEbARtMRogIE9wdGlvbmFsLiBDdXN0b20gcGF5bG9hZCBkYXRhLgoKDAoFBAICAwYS
A2wEGgoMCgUEAgIDARIDbBsiCgwKBQQCAgMDEgNsJScKDAoFBAICAwgSA20IMAoPCggEAgID
CJwIABIDbQkvCiQKBAQCAgQSA3AEPRoXIE9wdGlvbmFsLiBJbWFnZSBkYXRhLgoKDAoFBAIC
BAYSA3AECQoMCgUEAgIEARIDcAoPCgwKBQQCAgQDEgNwEhMKDAoFBAICBAgSA3AUPAoPCggE
AgIECJwIABIDcBU7CjAKBAQCAgUSA3MERBojIE9wdGlvbmFsLiBUb29sIGV4ZWN1dGlvbiBy
ZXF1ZXN0LgoKDAoFBAICBQYSA3MEDAoMCgUEAgIFARIDcw0WCgwKBQQCAgUDEgNzGRoKDAoF
BAICBQgSA3MbQwoPCggEAgIFCJwIABIDcxxCCjEKBAQCAgYSA3YETBokIE9wdGlvbmFsLiBU
b29sIGV4ZWN1dGlvbiByZXNwb25zZS4KCgwKBQQCAgYGEgN2BBAKDAoFBAICBgESA3YRHgoM
CgUEAgIGAxIDdiEiCgwKBQQCAgYIEgN2I0sKDwoIBAICBgicCAASA3YkSgouCgQEAgIHEgN5
BE4aISBPcHRpb25hbC4gQWdlbnQgdHJhbnNmZXIgZXZlbnQuCgoMCgUEAgIHBhIDeQQRCgwK
BQQCAgcBEgN5EiAKDAoFBAICBwMSA3kjJAoMCgUEAgIHCBIDeSVNCg8KCAQCAgcInAgAEgN5
JkwKbQoEBAICCBIDfQQxGmAgQSBzdHJ1Y3QgcmVwcmVzZW50cyB2YXJpYWJsZXMgdGhhdCB3
ZXJlIHVwZGF0ZWQgaW4gdGhlIGNvbnZlcnNhdGlvbiwKIGtleWVkIGJ5IHZhcmlhYmxlIG5h
bWVzLgoKDAoFBAICCAYSA30EGgoMCgUEAgIIARIDfRssCgwKBQQCAggDEgN9LzAKcQoEBAIC
CRIEgQEEMhpjIEEgc3RydWN0IHJlcHJlc2VudHMgZGVmYXVsdCB2YXJpYWJsZXMgYXQgdGhl
IHN0YXJ0IG9mIHRoZSBjb252ZXJzYXRpb24sCiBrZXllZCBieSB2YXJpYWJsZSBuYW1lcy4K
Cg0KBQQCAgkGEgSBAQQaCg0KBQQCAgkBEgSBARssCg0KBQQCAgkDEgSBAS8xCkYKAgQDEgaG
AQCMAQEaOCBSZXByZXNlbnRzIGEgYmxvYiBpbnB1dCBvciBvdXRwdXQgaW4gdGhlIGNvbnZl
cnNhdGlvbi4KCgsKAwQDARIEhgEIDApJCgQEAwIAEgSIAQJAGjsgUmVxdWlyZWQuIFRoZSBJ
QU5BIHN0YW5kYXJkIE1JTUUgdHlwZSBvZiB0aGUgc291cmNlIGRhdGEuCgoNCgUEAwIABRIE
iAECCAoNCgUEAwIAARIEiAEJEgoNCgUEAwIAAxIEiAEVFgoNCgUEAwIACBIEiAEXPwoQCggE
AwIACJwIABIEiAEYPgowCgQEAwIBEgSLAQI6GiIgUmVxdWlyZWQuIFJhdyBieXRlcyBvZiB0
aGUgYmxvYi4KCg0KBQQDAgEFEgSLAQIHCg0KBQQDAgEBEgSLAQgMCg0KBQQDAgEDEgSLAQ8Q
Cg0KBQQDAgEIEgSLARE5ChAKCAQDAgEInAgAEgSLARI4CkgKAgQEEgaPAQCZAQEaOiBSZXBy
ZXNlbnRzIGFuIGltYWdlIGlucHV0IG9yIG91dHB1dCBpbiB0aGUgY29udmVyc2F0aW9uLgoK
CwoDBAQBEgSPAQgNCpcBCgQEBAIAEgSVAQJAGogBIFJlcXVpcmVkLiBUaGUgSUFOQSBzdGFu
ZGFyZCBNSU1FIHR5cGUgb2YgdGhlIHNvdXJjZSBkYXRhLgogU3VwcG9ydGVkIGltYWdlIHR5
cGVzIGluY2x1ZGVzOgogICogaW1hZ2UvcG5nCiAgKiBpbWFnZS9qcGVnCiAgKiBpbWFnZS93
ZWJwCgoNCgUEBAIABRIElQECCAoNCgUEBAIAARIElQEJEgoNCgUEBAIAAxIElQEVFgoNCgUE
BAIACBIElQEXPwoQCggEBAIACJwIABIElQEYPgoxCgQEBAIBEgSYAQI6GiMgUmVxdWlyZWQu
IFJhdyBieXRlcyBvZiB0aGUgaW1hZ2UuCgoNCgUEBAIBBRIEmAECBwoNCgUEBAIBARIEmAEI
DAoNCgUEBAIBAxIEmAEPEAoNCgUEBAIBCBIEmAEROQoQCggEBAIBCJwIABIEmAESOApSCgIE
BRIGnAEAtgEBGkQgUmVxdWVzdCBmb3IgdGhlIGNsaWVudCBvciB0aGUgYWdlbnQgdG8gZXhl
Y3V0ZSB0aGUgc3BlY2lmaWVkIHRvb2wuCgoLCgMEBQESBJwBCBAKdwoEBAUIABIGnwECqQED
GmcgVGhlIGlkZW50aWZpZXIgb2YgdGhlIHRvb2wgdG8gZXhlY3V0ZS4gSXQgY291bGQgYmUg
ZWl0aGVyIGEgcGVyc2lzdGVkIHRvb2wKIG9yIGEgdG9vbCBmcm9tIGEgdG9vbHNldC4KCg0K
BQQFCAABEgSfAQgXCocBCgQEBQIAEgaiAQSlAQYadyBPcHRpb25hbC4gVGhlIG5hbWUgb2Yg
dGhlIHRvb2wgdG8gZXhlY3V0ZS4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfWAKCg0KBQQFAgAFEgSi
AQQKCg0KBQQFAgABEgSiAQsPCg0KBQQFAgADEgSiARITCg8KBQQFAgAIEgaiARSlAQUKEAoI
BAUCAAicCAASBKMBBiwKDwoHBAUCAAifCBIEpAEGSwo2CgQEBQIBEgSoAQRKGiggT3B0aW9u
YWwuIFRoZSB0b29sc2V0IHRvb2wgdG8gZXhlY3V0ZS4KCg0KBQQFAgEGEgSoAQQPCg0KBQQF
AgEBEgSoARAcCg0KBQQFAgEDEgSoAR8gCg0KBQQFAgEIEgSoASFJChAKCAQFAgEInAgAEgSo
ASJICs0BCgQEBQICEgSuAQI5Gr4BIE9wdGlvbmFsLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIg
b2YgdGhlIHRvb2wgY2FsbC4gSWYgcG9wdWxhdGVkLCB0aGUgY2xpZW50CiBzaG91bGQgcmV0
dXJuIHRoZSBleGVjdXRpb24gcmVzdWx0IHdpdGggdGhlIG1hdGNoaW5nIElEIGluCiBbVG9v
bFJlc3BvbnNlXVtnb29nbGUuY2xvdWQuY2VzLnYxLlRvb2xSZXNwb25zZS5pZF0uCgoNCgUE
BQICBRIErgECCAoNCgUEBQICARIErgEJCwoNCgUEBQICAxIErgEODwoNCgUEBQICCBIErgEQ
OAoQCggEBQICCJwIABIErgERNwo2CgQEBQIDEgSxAQJGGiggT3V0cHV0IG9ubHkuIERpc3Bs
YXkgbmFtZSBvZiB0aGUgdG9vbC4KCg0KBQQFAgMFEgSxAQIICg0KBQQFAgMBEgSxAQkVCg0K
BQQFAgMDEgSxARgZCg0KBQQFAgMIEgSxARpFChAKCAQFAgMInAgAEgSxARtECl4KBAQFAgQS
BLUBAksaUCBPcHRpb25hbC4gVGhlIGlucHV0IHBhcmFtZXRlcnMgYW5kIHZhbHVlcyBmb3Ig
dGhlIHRvb2wgaW4gSlNPTiBvYmplY3QKIGZvcm1hdC4KCg0KBQQFAgQGEgS1AQIYCg0KBQQF
AgQBEgS1ARkdCg0KBQQFAgQDEgS1ASAhCg0KBQQFAgQIEgS1ASJKChAKCAQFAgQInAgAEgS1
ASNJClUKAgQGEga5AQDUAQEaRyBUaGUgZXhlY3V0aW9uIHJlc3VsdCBvZiBhIHNwZWNpZmlj
IHRvb2wgZnJvbSB0aGUgY2xpZW50IG9yIHRoZSBhZ2VudC4KCgsKAwQGARIEuQEIFAp+CgQE
BggAEga8AQLGAQMabiBUaGUgaWRlbnRpZmllciBvZiB0aGUgdG9vbCB0aGF0IGdvdCBleGVj
dXRlZC4gSXQgY291bGQgYmUgZWl0aGVyIGEKIHBlcnNpc3RlZCB0b29sIG9yIGEgdG9vbCBm
cm9tIGEgdG9vbHNldC4KCg0KBQQGCAABEgS8AQgXCocBCgQEBgIAEga/AQTCAQYadyBPcHRp
b25hbC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wgdG8gZXhlY3V0ZS4KIEZvcm1hdDogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0
b29sfWAKCg0KBQQGAgAFEgS/AQQKCg0KBQQGAgABEgS/AQsPCg0KBQQGAgADEgS/ARITCg8K
BQQGAgAIEga/ARTCAQUKEAoIBAYCAAicCAASBMABBiwKDwoHBAYCAAifCBIEwQEGSwo9CgQE
BgIBEgTFAQRKGi8gT3B0aW9uYWwuIFRoZSB0b29sc2V0IHRvb2wgdGhhdCBnb3QgZXhlY3V0
ZWQuCgoNCgUEBgIBBhIExQEEDwoNCgUEBgIBARIExQEQHAoNCgUEBgIBAxIExQEfIAoNCgUE
BgIBCBIExQEhSQoQCggEBgIBCJwIABIExQEiSApwCgQEBgICEgTKAQI5GmIgT3B0aW9uYWwu
IFRoZSBtYXRjaGluZyBJRCBvZiB0aGUgW3Rvb2wgY2FsbF1bZ29vZ2xlLmNsb3VkLmNlcy52
MS5Ub29sQ2FsbF0KIHRoZSByZXNwb25zZSBpcyBmb3IuCgoNCgUEBgICBRIEygECCAoNCgUE
BgICARIEygEJCwoNCgUEBgICAxIEygEODwoNCgUEBgICCBIEygEQOAoQCggEBgICCJwIABIE
ygERNwo2CgQEBgIDEgTNAQJGGiggT3V0cHV0IG9ubHkuIERpc3BsYXkgbmFtZSBvZiB0aGUg
dG9vbC4KCg0KBQQGAgMFEgTNAQIICg0KBQQGAgMBEgTNAQkVCg0KBQQGAgMDEgTNARgZCg0K
BQQGAgMIEgTNARpFChAKCAQGAgMInAgAEgTNARtECpYCCgQEBgIEEgTTAQJPGocCIFJlcXVp
cmVkLiBUaGUgdG9vbCBleGVjdXRpb24gcmVzdWx0IGluIEpTT04gb2JqZWN0IGZvcm1hdC4K
IFVzZSAib3V0cHV0IiBrZXkgdG8gc3BlY2lmeSB0b29sIHJlc3BvbnNlIGFuZCAiZXJyb3Ii
IGtleSB0byBzcGVjaWZ5CiBlcnJvciBkZXRhaWxzIChpZiBhbnkpLiBJZiAib3V0cHV0IiBh
bmQgImVycm9yIiBrZXlzIGFyZSBub3Qgc3BlY2lmaWVkLAogdGhlbiB3aG9sZSAicmVzcG9u
c2UiIGlzIHRyZWF0ZWQgYXMgdG9vbCBleGVjdXRpb24gcmVzdWx0LgoKDQoFBAYCBAYSBNMB
AhgKDQoFBAYCBAESBNMBGSEKDQoFBAYCBAMSBNMBJCUKDQoFBAYCBAgSBNMBJk4KEAoIBAYC
BAicCAASBNMBJ00KZAoCBAcSBtgBAOMBARpWIFJlcHJlc2VudHMgYW4gZXZlbnQgaW5kaWNh
dGluZyB0aGUgdHJhbnNmZXIgb2YgYSBjb252ZXJzYXRpb24gdG8gYSBkaWZmZXJlbnQKIGFn
ZW50LgoKCwoDBAcBEgTYAQgVCuQBCgQEBwIAEgbcAQLfAQQa0wEgUmVxdWlyZWQuIFRoZSBh
Z2VudCB0byB3aGljaCB0aGUgY29udmVyc2F0aW9uIGlzIGJlaW5nIHRyYW5zZmVycmVkLiBU
aGUKIGFnZW50IHdpbGwgaGFuZGxlIHRoZSBjb252ZXJzYXRpb24gZnJvbSB0aGlzIHBvaW50
IGZvcndhcmQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vYXBwcy97YXBwfS9hZ2VudHMve2FnZW50fWAKCg0KBQQHAgAFEgTcAQIICg0KBQQH
AgABEgTcAQkVCg0KBQQHAgADEgTcARgZCg8KBQQHAgAIEgbcARrfAQMKEAoIBAcCAAicCAAS
BN0BBCoKDwoHBAcCAAifCBIE3gEESgo3CgQEBwIBEgTiAQJGGikgT3V0cHV0IG9ubHkuIERp
c3BsYXkgbmFtZSBvZiB0aGUgYWdlbnQuCgoNCgUEBwIBBRIE4gECCAoNCgUEBwIBARIE4gEJ
FQoNCgUEBwIBAxIE4gEYGQoNCgUEBwIBCBIE4gEaRQoQCggEBwIBCJwIABIE4gEbRGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Example::Example ===
    # Fields for Example
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: entry_agent Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.ces.v1.Message)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: invalid Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Ces::V1::Example::Message ===
    # Fields for Message
    # Field: role Type: 9 ()
    # Field: chunks Type: 11 (.google.cloud.ces.v1.Chunk)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Ces::V1::Example::Chunk ===
    # Fields for Chunk
    # Field: text Type: 9 ()
    # Field: transcript Type: 9 ()
    # Field: blob Type: 11 (.google.cloud.ces.v1.Blob)
    # Field: payload Type: 11 (.google.protobuf.Struct)
    # Field: image Type: 11 (.google.cloud.ces.v1.Image)
    # Field: tool_call Type: 11 (.google.cloud.ces.v1.ToolCall)
    # Field: tool_response Type: 11 (.google.cloud.ces.v1.ToolResponse)
    # Field: agent_transfer Type: 11 (.google.cloud.ces.v1.AgentTransfer)
    # Field: updated_variables Type: 11 (.google.protobuf.Struct)
    # Field: default_variables Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Ces::V1::Example::Blob ===
    # Fields for Blob
    # Field: mime_type Type: 9 ()
    # Field: data Type: 12 ()

# === Message: Google::Cloud::Ces::V1::Example::Image ===
    # Fields for Image
    # Field: mime_type Type: 9 ()
    # Field: data Type: 12 ()

# === Message: Google::Cloud::Ces::V1::Example::ToolCall ===
    # Fields for ToolCall
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: args Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Ces::V1::Example::ToolResponse ===
    # Fields for ToolResponse
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: response Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Ces::V1::Example::AgentTransfer ===
    # Fields for AgentTransfer
    # Field: target_agent Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Example - Compiled Protocol Buffers messages for google/cloud/ces/v1/example.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Example;

    my $msg = Google::Cloud::Ces::V1::Example::Example->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        entry_agent => $entry_agent,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Example::Example->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/example.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Example::Example

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

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::Message>)

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

=head2 Google::Cloud::Ces::V1::Example::Message

A message within a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Optional. The role within the conversation, e.g., user, agent.

=item * C<< $msg->chunks() >> / C<< $msg->chunks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::Chunk>)

Optional. Content of the message as a series of chunks.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp when the message was sent or received. Should not be
used if the message is part of an [example][google.cloud.ces.v1.Example].

=back

=head2 Google::Cloud::Ces::V1::Example::Chunk

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

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::Blob>)

Optional. Blob data.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. Custom payload data.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::Image>)

Optional. Image data.

=item * C<< $msg->tool_call() >> / C<< $msg->tool_call($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::ToolCall>)

Optional. Tool execution request.

=item * C<< $msg->tool_response() >> / C<< $msg->tool_response($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::ToolResponse>)

Optional. Tool execution response.

=item * C<< $msg->agent_transfer() >> / C<< $msg->agent_transfer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::AgentTransfer>)

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

=head2 Google::Cloud::Ces::V1::Example::Blob

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

=head2 Google::Cloud::Ces::V1::Example::Image

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

=back

=head2 Google::Cloud::Ces::V1::Example::ToolCall

Request for the client or the agent to execute the specified tool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to execute.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

Optional. The toolset tool to execute.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional. The unique identifier of the tool call. If populated, the client
should return the execution result with the matching ID in
[ToolResponse][google.cloud.ces.v1.ToolResponse.id].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name of the tool.

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The input parameters and values for the tool in JSON object
format.

=back

=head2 Google::Cloud::Ces::V1::Example::ToolResponse

The execution result of a specific tool from the client or the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to execute.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

Optional. The toolset tool that got executed.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional. The matching ID of the [tool call][google.cloud.ces.v1.ToolCall]
the response is for.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name of the tool.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Required. The tool execution result in JSON object format.
Use "output" key to specify tool response and "error" key to specify
error details (if any). If "output" and "error" keys are not specified,
then whole "response" is treated as tool execution result.

=back

=head2 Google::Cloud::Ces::V1::Example::AgentTransfer

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Example::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
