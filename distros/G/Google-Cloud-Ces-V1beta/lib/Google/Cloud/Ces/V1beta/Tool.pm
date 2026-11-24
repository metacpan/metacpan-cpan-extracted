package Google::Cloud::Ces::V1beta::Tool;

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
    eval { require Google::Cloud::Ces::V1beta::AgentCard };
    eval { require Google::Cloud::Ces::V1beta::AgentTool };
    eval { require Google::Cloud::Ces::V1beta::ClientFunction };
    eval { require Google::Cloud::Ces::V1beta::Common };
    eval { require Google::Cloud::Ces::V1beta::ConnectorTool };
    eval { require Google::Cloud::Ces::V1beta::DataStoreTool };
    eval { require Google::Cloud::Ces::V1beta::Fakes };
    eval { require Google::Cloud::Ces::V1beta::FileSearchTool };
    eval { require Google::Cloud::Ces::V1beta::GoogleSearchTool };
    eval { require Google::Cloud::Ces::V1beta::McpTool };
    eval { require Google::Cloud::Ces::V1beta::OpenApiTool };
    eval { require Google::Cloud::Ces::V1beta::PythonFunction };
    eval { require Google::Cloud::Ces::V1beta::SystemTool };
    eval { require Google::Cloud::Ces::V1beta::WidgetTool };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS90b29sLnByb3RvEhdnb29nbGUuY2xvdWQuY2Vz
LnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvYWdlbnRfY2FyZC5wcm90
bxooZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvYWdlbnRfdG9vbC5wcm90bxotZ29vZ2xlL2Ns
b3VkL2Nlcy92MWJldGEvY2xpZW50X2Z1bmN0aW9uLnByb3RvGiRnb29nbGUvY2xvdWQvY2Vz
L3YxYmV0YS9jb21tb24ucHJvdG8aLGdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2Nvbm5lY3Rv
cl90b29sLnByb3RvGi1nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9kYXRhX3N0b3JlX3Rvb2wu
cHJvdG8aI2dvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2Zha2VzLnByb3RvGi5nb29nbGUvY2xv
dWQvY2VzL3YxYmV0YS9maWxlX3NlYXJjaF90b29sLnByb3RvGjBnb29nbGUvY2xvdWQvY2Vz
L3YxYmV0YS9nb29nbGVfc2VhcmNoX3Rvb2wucHJvdG8aJmdvb2dsZS9jbG91ZC9jZXMvdjFi
ZXRhL21jcF90b29sLnByb3RvGitnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9vcGVuX2FwaV90
b29sLnByb3RvGi1nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9weXRob25fZnVuY3Rpb24ucHJv
dG8aKWdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL3N5c3RlbV90b29sLnByb3RvGilnb29nbGUv
Y2xvdWQvY2VzL3YxYmV0YS93aWRnZXRfdG9vbC5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1
cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoENCgRUb29s
ElcKD2NsaWVudF9mdW5jdGlvbhgCIAEoCzInLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkNs
aWVudEZ1bmN0aW9uQgPgQQFIAFIOY2xpZW50RnVuY3Rpb24STwoNb3Blbl9hcGlfdG9vbBgD
IAEoCzIkLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLk9wZW5BcGlUb29sQgPgQQFIAFILb3Bl
bkFwaVRvb2wSXgoSZ29vZ2xlX3NlYXJjaF90b29sGAUgASgLMikuZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEuR29vZ2xlU2VhcmNoVG9vbEID4EEBSABSEGdvb2dsZVNlYXJjaFRvb2wSVAoO
Y29ubmVjdG9yX3Rvb2wYCCABKAsyJi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Db25uZWN0
b3JUb29sQgPgQQFIAFINY29ubmVjdG9yVG9vbBJVCg9kYXRhX3N0b3JlX3Rvb2wYCiABKAsy
Ji5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5EYXRhU3RvcmVUb29sQgPgQQFIAFINZGF0YVN0
b3JlVG9vbBJXCg9weXRob25fZnVuY3Rpb24YCyABKAsyJy5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5QeXRob25GdW5jdGlvbkID4EEBSABSDnB5dGhvbkZ1bmN0aW9uEkIKCG1jcF90b29s
GBAgASgLMiAuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuTWNwVG9vbEID4EEBSABSB21jcFRv
b2wSWAoQZmlsZV9zZWFyY2hfdG9vbBgRIAEoCzInLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
LkZpbGVTZWFyY2hUb29sQgPgQQFIAFIOZmlsZVNlYXJjaFRvb2wSSwoLc3lzdGVtX3Rvb2wY
EiABKAsyIy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TeXN0ZW1Ub29sQgPgQQFIAFIKc3lz
dGVtVG9vbBJICgphZ2VudF90b29sGBcgASgLMiIuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEu
QWdlbnRUb29sQgPgQQFIAFIJYWdlbnRUb29sEksKC3dpZGdldF90b29sGBggASgLMiMuZ29v
Z2xlLmNsb3VkLmNlcy52MWJldGEuV2lkZ2V0VG9vbEID4EEBSABSCndpZGdldFRvb2wSWwoR
cmVtb3RlX2FnZW50X3Rvb2wYGSABKAsyKC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5SZW1v
dGVBZ2VudFRvb2xCA+BBAUgAUg9yZW1vdGVBZ2VudFRvb2wSFwoEbmFtZRgBIAEoCUID4EEI
UgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgNIAEoCUID4EEDUgtkaXNwbGF5TmFtZRJSCg5leGVj
dXRpb25fdHlwZRgMIAEoDjImLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkV4ZWN1dGlvblR5
cGVCA+BBAVINZXhlY3V0aW9uVHlwZRI4Cgd0aW1lb3V0GBYgASgLMhkuZ29vZ2xlLnByb3Rv
YnVmLkR1cmF0aW9uQgPgQQFSB3RpbWVvdXQSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUY
ByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSEgoE
ZXRhZxgOIAEoCVIEZXRhZxIwChFnZW5lcmF0ZWRfc3VtbWFyeRgPIAEoCUID4EEDUhBnZW5l
cmF0ZWRTdW1tYXJ5ElYKEHRvb2xfZmFrZV9jb25maWcYFCABKAsyJy5nb29nbGUuY2xvdWQu
Y2VzLnYxYmV0YS5Ub29sRmFrZUNvbmZpZ0ID4EEBUg50b29sRmFrZUNvbmZpZxIgCglyZWFk
X29ubHkYHSABKAhCA+BBA1IIcmVhZE9ubHk6aupBZwoXY2VzLmdvb2dsZWFwaXMuY29tL1Rv
b2wSP3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9
L3Rvb2xzL3t0b29sfSoFdG9vbHMyBHRvb2xCCwoJdG9vbF90eXBlQlkKG2NvbS5nb29nbGUu
Y2xvdWQuY2VzLnYxYmV0YUIJVG9vbFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2Vz
L2FwaXYxYmV0YS9jZXNwYjtjZXNwYkrBJQoHEgUOAJABAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQAMgoJCgIDAxIDFQAyCgkKAgMEEgMWADcKCQoCAwUSAxcALgoJCgIDBhIDGAA2CgkKAgMH
EgMZADcKCQoCAwgSAxoALQoJCgIDCRIDGwA4CgkKAgMKEgMcADoKCQoCAwsSAx0AMAoJCgID
DBIDHgA1CgkKAgMNEgMfADcKCQoCAw4SAyAAMwoJCgIDDxIDIQAzCgkKAgMQEgMiACgKCQoC
AxESAyMAKQoICgEIEgMlAEQKCQoCCAsSAyUARAoICgEIEgMmACIKCQoCCAoSAyYAIgoICgEI
EgMnACoKCQoCCAgSAycAKgoICgEIEgMoADQKCQoCCAESAygANAphCgIEABIFLACQAQEaVCBB
IHRvb2wgcmVwcmVzZW50cyBhbiBhY3Rpb24gdGhhdCB0aGUgQ0VTIGFnZW50IGNhbiB0YWtl
IHRvIGFjaGlldmUgY2VydGFpbgogZ29hbHMuCgoKCgMEAAESAywIDAoLCgMEAAcSBC0CMgQK
DQoFBAAHnQgSBC0CMgQKJQoEBAAIABIENQJeAxoXIFRoZSB0eXBlIG9mIHRoZSB0b29sLgoK
DAoFBAAIAAESAzUIEQotCgQEAAIAEgM3BFAaICBPcHRpb25hbC4gVGhlIGNsaWVudCBmdW5j
dGlvbi4KCgwKBQQAAgAGEgM3BBIKDAoFBAACAAESAzcTIgoMCgUEAAIAAxIDNyUmCgwKBQQA
AgAIEgM3J08KDwoIBAACAAicCAASAzcoTgorCgQEAAIBEgM6BEsaHiBPcHRpb25hbC4gVGhl
IG9wZW4gQVBJIHRvb2wuCgoMCgUEAAIBBhIDOgQPCgwKBQQAAgEBEgM6EB0KDAoFBAACAQMS
AzogIQoMCgUEAAIBCBIDOiJKCg8KCAQAAgEInAgAEgM6I0kKMQoEBAACAhIEPQQ+MRojIE9w
dGlvbmFsLiBUaGUgZ29vZ2xlIHNlYXJjaCB0b29sLgoKDAoFBAACAgYSAz0EFAoMCgUEAAIC
ARIDPRUnCgwKBQQAAgIDEgM9KisKDAoFBAACAggSAz4IMAoPCggEAAICCJwIABIDPgkvCjgK
BAQAAgMSA0EEThorIE9wdGlvbmFsLiBUaGUgSW50ZWdyYXRpb24gQ29ubmVjdG9yIHRvb2wu
CgoMCgUEAAIDBhIDQQQRCgwKBQQAAgMBEgNBEiAKDAoFBAACAwMSA0EjJAoMCgUEAAIDCBID
QSVNCg8KCAQAAgMInAgAEgNBJkwKLQoEBAACBBIDRARQGiAgT3B0aW9uYWwuIFRoZSBkYXRh
IHN0b3JlIHRvb2wuCgoMCgUEAAIEBhIDRAQRCgwKBQQAAgQBEgNEEiEKDAoFBAACBAMSA0Qk
JgoMCgUEAAIECBIDRCdPCg8KCAQAAgQInAgAEgNEKE4KMwoEBAACBRIERwRIMRolIE9wdGlv
bmFsLiBUaGUgcHl0aG9uIGZ1bmN0aW9uIHRvb2wuCgoMCgUEAAIFBhIDRwQSCgwKBQQAAgUB
EgNHEyIKDAoFBAACBQMSA0clJwoMCgUEAAIFCBIDSAgwCg8KCAQAAgUInAgAEgNICS8KfAoE
BAACBhIDTARDGm8gT3B0aW9uYWwuIFRoZSBNQ1AgdG9vbC4gQW4gTUNQIHRvb2wgY2Fubm90
IGJlIGNyZWF0ZWQgb3IgdXBkYXRlZCBkaXJlY3RseQogYW5kIGlzIG1hbmFnZWQgYnkgdGhl
IE1DUCB0b29sc2V0LgoKDAoFBAACBgYSA0wECwoMCgUEAAIGARIDTAwUCgwKBQQAAgYDEgNM
FxkKDAoFBAACBggSA0waQgoPCggEAAIGCJwIABIDTBtBCi8KBAQAAgcSBE8EUDEaISBPcHRp
b25hbC4gVGhlIGZpbGUgc2VhcmNoIHRvb2wuCgoMCgUEAAIHBhIDTwQSCgwKBQQAAgcBEgNP
EyMKDAoFBAACBwMSA08mKAoMCgUEAAIHCBIDUAgwCg8KCAQAAgcInAgAEgNQCS8KKQoEBAAC
CBIDUwRJGhwgT3B0aW9uYWwuIFRoZSBzeXN0ZW0gdG9vbC4KCgwKBQQAAggGEgNTBA4KDAoF
BAACCAESA1MPGgoMCgUEAAIIAxIDUx0fCgwKBQQAAggIEgNTIEgKDwoIBAACCAicCAASA1Mh
RwooCgQEAAIJEgNWBEcaGyBPcHRpb25hbC4gVGhlIGFnZW50IHRvb2wuCgoMCgUEAAIJBhID
VgQNCgwKBQQAAgkBEgNWDhgKDAoFBAACCQMSA1YbHQoMCgUEAAIJCBIDVh5GCg8KCAQAAgkI
nAgAEgNWH0UKKQoEBAACChIDWQRJGhwgT3B0aW9uYWwuIFRoZSB3aWRnZXQgdG9vbC4KCgwK
BQQAAgoGEgNZBA4KDAoFBAACCgESA1kPGgoMCgUEAAIKAxIDWR0fCgwKBQQAAgoIEgNZIEgK
DwoIBAACCgicCAASA1khRwowCgQEAAILEgRcBF0xGiIgT3B0aW9uYWwuIFRoZSByZW1vdGUg
YWdlbnQgdG9vbC4KCgwKBQQAAgsGEgNcBBMKDAoFBAACCwESA1wUJQoMCgUEAAILAxIDXCgq
CgwKBQQAAgsIEgNdCDAKDwoIBAACCwicCAASA10JLwqJAwoEBAACDBIDaQI9GvsCIElkZW50
aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSB0b29sLiBGb3JtYXQ6CgogKiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vdG9vbHMv
e3Rvb2x9YAogICBmb3Igc3RhbmRhbG9uZSB0b29scy4KICogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzZXRzL3t0b29sc2V0fS90
b29scy97dG9vbH1gCiAgIGZvciB0b29scyByZXRyaWV2ZWQgZnJvbSBhIHRvb2xzZXQuCgog
VGhlc2UgdG9vbHMgYXJlIGR5bmFtaWMgYW5kIG91dHB1dC1vbmx5OyB0aGV5IGNhbm5vdCBi
ZSByZWZlcmVuY2VkIGRpcmVjdGx5CiB3aGVyZSBhIHRvb2wgaXMgZXhwZWN0ZWQuCgoMCgUE
AAIMBRIDaQIICgwKBQQAAgwBEgNpCQ0KDAoFBAACDAMSA2kQEQoMCgUEAAIMCBIDaRI8Cg8K
CAQAAgwInAgAEgNpEzsKyAEKBAQAAg0SA24CRxq6ASBPdXRwdXQgb25seS4gVGhlIGRpc3Bs
YXkgbmFtZSBvZiB0aGUgdG9vbCwgZGVyaXZlZCBiYXNlZCBvbiB0aGUgdG9vbCdzCiB0eXBl
LiBGb3IgZXhhbXBsZSwgZGlzcGxheSBuYW1lIG9mIGEgW0NsaWVudEZ1bmN0aW9uXVtUb29s
LkNsaWVudEZ1bmN0aW9uXQogaXMgZGVyaXZlZCBmcm9tIGl0cyBgbmFtZWAgcHJvcGVydHku
CgoMCgUEAAINBRIDbgIICgwKBQQAAg0BEgNuCRUKDAoFBAACDQMSA24YGgoMCgUEAAINCBID
bhtGCg8KCAQAAg0InAgAEgNuHEUKOAoEBAACDhIDcQJNGisgT3B0aW9uYWwuIFRoZSBleGVj
dXRpb24gdHlwZSBvZiB0aGUgdG9vbC4KCgwKBQQAAg4GEgNxAg8KDAoFBAACDgESA3EQHgoM
CgUEAAIOAxIDcSEjCgwKBQQAAg4IEgNxJEwKDwoIBAACDgicCAASA3ElSwqvAQoEBAACDxIE
dgJ3LxqgASBPcHRpb25hbC4gVGhlIHRpbWVvdXQgZm9yIHRoZSB0b29sIGV4ZWN1dGlvbi4g
SWYgbm90IHNldCwgdGhlIGRlZmF1bHQKIHRpbWVvdXQgaXMgMzAgc2Vjb25kcyBmb3IgYFNZ
TkNIUk9OT1VTYCB0b29scyBhbmQgNjAgc2Vjb25kcyBmb3IKIGBBU1lOQ0hST05PVVNgIHRv
b2xzLgoKDAoFBAACDwYSA3YCGgoMCgUEAAIPARIDdhsiCgwKBQQAAg8DEgN2JScKDAoFBAAC
DwgSA3cGLgoPCggEAAIPCJwIABIDdwctCkEKBAQAAhASBHoCezIaMyBPdXRwdXQgb25seS4g
VGltZXN0YW1wIHdoZW4gdGhlIHRvb2wgd2FzIGNyZWF0ZWQuCgoMCgUEAAIQBhIDegIbCgwK
BQQAAhABEgN6HCcKDAoFBAACEAMSA3oqKwoMCgUEAAIQCBIDewYxCg8KCAQAAhAInAgAEgN7
BzAKRgoEBAACERIEfgJ/Mho4IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUgdG9v
bCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACEQYSA34CGwoMCgUEAAIRARIDfhwnCgwKBQQA
AhEDEgN+KisKDAoFBAACEQgSA38GMQoPCggEAAIRCJwIABIDfwcwCq4BCgQEAAISEgSEAQIT
Gp8BIEV0YWcgdXNlZCB0byBlbnN1cmUgdGhlIG9iamVjdCBoYXNuJ3QgY2hhbmdlZCBkdXJp
bmcgYSByZWFkLW1vZGlmeS13cml0ZQogb3BlcmF0aW9uLiBJZiB0aGUgZXRhZyBpcyBlbXB0
eSwgdGhlIHVwZGF0ZSB3aWxsIG92ZXJ3cml0ZSBhbnkgY29uY3VycmVudAogY2hhbmdlcy4K
Cg0KBQQAAhIFEgSEAQIICg0KBQQAAhIBEgSEAQkNCg0KBQQAAhIDEgSEARASCokBCgQEAAIT
EgSIAQJMGnsgT3V0cHV0IG9ubHkuIElmIHRoZSB0b29sIGlzIGdlbmVyYXRlZCBieSB0aGUg
TExNIGFzc2lzdGFudCwgdGhpcyBmaWVsZAogY29udGFpbnMgYSBkZXNjcmlwdGl2ZSBzdW1t
YXJ5IG9mIHRoZSBnZW5lcmF0aW9uLgoKDQoFBAACEwUSBIgBAggKDQoFBAACEwESBIgBCRoK
DQoFBAACEwMSBIgBHR8KDQoFBAACEwgSBIgBIEsKEAoIBAACEwicCAASBIgBIUoKRwoEBAAC
FBIEiwECUBo5IE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIGZvciB0b29sIGJlaGF2aW9yIGlu
IGZha2UgbW9kZS4KCg0KBQQAAhQGEgSLAQIQCg0KBQQAAhQBEgSLAREhCg0KBQQAAhQDEgSL
ASQmCg0KBQQAAhQIEgSLASdPChAKCAQAAhQInAgAEgSLAShOCngKBAQAAhUSBI8BAkIaaiBP
dXRwdXQgb25seS4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIHRvb2wgaXMgcmVhZC1vbmx5LiBJ
ZiB0cnVlLCB0aGUgdG9vbAogY2Fubm90IGJlIG1vZGlmaWVkIGJ5IHRoZSB1c2VyLgoKDQoF
BAACFQUSBI8BAgYKDQoFBAACFQESBI8BBxAKDQoFBAACFQMSBI8BExUKDQoFBAACFQgSBI8B
FkEKEAoIBAACFQicCAASBI8BF0BiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Tool::Tool ===
    # Fields for Tool
    # Field: client_function Type: 11 (.google.cloud.ces.v1beta.ClientFunction)
    # Field: open_api_tool Type: 11 (.google.cloud.ces.v1beta.OpenApiTool)
    # Field: google_search_tool Type: 11 (.google.cloud.ces.v1beta.GoogleSearchTool)
    # Field: connector_tool Type: 11 (.google.cloud.ces.v1beta.ConnectorTool)
    # Field: data_store_tool Type: 11 (.google.cloud.ces.v1beta.DataStoreTool)
    # Field: python_function Type: 11 (.google.cloud.ces.v1beta.PythonFunction)
    # Field: mcp_tool Type: 11 (.google.cloud.ces.v1beta.McpTool)
    # Field: file_search_tool Type: 11 (.google.cloud.ces.v1beta.FileSearchTool)
    # Field: system_tool Type: 11 (.google.cloud.ces.v1beta.SystemTool)
    # Field: agent_tool Type: 11 (.google.cloud.ces.v1beta.AgentTool)
    # Field: widget_tool Type: 11 (.google.cloud.ces.v1beta.WidgetTool)
    # Field: remote_agent_tool Type: 11 (.google.cloud.ces.v1beta.RemoteAgentTool)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: execution_type Type: 14 (.google.cloud.ces.v1beta.ExecutionType)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: generated_summary Type: 9 ()
    # Field: tool_fake_config Type: 11 (.google.cloud.ces.v1beta.ToolFakeConfig)
    # Field: read_only Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Tool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Tool;

    my $msg = Google::Cloud::Ces::V1beta::Tool::Tool->new({
        client_function => $client_function,
        open_api_tool => $open_api_tool,
        google_search_tool => $google_search_tool,
        connector_tool => $connector_tool,
    });

    # Read or update a field
    my $val = $msg->client_function();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Tool::Tool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Tool::Tool

A tool represents an action that the CES agent can take to achieve certain
goals.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_function() >> / C<< $msg->client_function($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ClientFunction::ClientFunction>)

Optional. The client function.

=item * C<< $msg->open_api_tool() >> / C<< $msg->open_api_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool>)

Optional. The open API tool.

=item * C<< $msg->google_search_tool() >> / C<< $msg->google_search_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::GoogleSearchTool::GoogleSearchTool>)

Optional. The google search tool.

=item * C<< $msg->connector_tool() >> / C<< $msg->connector_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ConnectorTool::ConnectorTool>)

Optional. The Integration Connector tool.

=item * C<< $msg->data_store_tool() >> / C<< $msg->data_store_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool>)

Optional. The data store tool.

=item * C<< $msg->python_function() >> / C<< $msg->python_function($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::PythonFunction::PythonFunction>)

Optional. The python function tool.

=item * C<< $msg->mcp_tool() >> / C<< $msg->mcp_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::McpTool::McpTool>)

Optional. The MCP tool. An MCP tool cannot be created or updated directly
and is managed by the MCP toolset.

=item * C<< $msg->file_search_tool() >> / C<< $msg->file_search_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::FileSearchTool::FileSearchTool>)

Optional. The file search tool.

=item * C<< $msg->system_tool() >> / C<< $msg->system_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::SystemTool::SystemTool>)

Optional. The system tool.

=item * C<< $msg->agent_tool() >> / C<< $msg->agent_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentTool::AgentTool>)

Optional. The agent tool.

=item * C<< $msg->widget_tool() >> / C<< $msg->widget_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::WidgetTool::WidgetTool>)

Optional. The widget tool.

=item * C<< $msg->remote_agent_tool() >> / C<< $msg->remote_agent_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentCard::RemoteAgentTool>)

Optional. The remote agent tool.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the tool. Format:

* `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`
  for standalone tools.
* `projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}/tools/{tool}`
  for tools retrieved from a toolset.

These tools are dynamic and output-only; they cannot be referenced directly
where a tool is expected.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the tool, derived based on the tool's
type. For example, display name of a [ClientFunction][Tool.ClientFunction]
is derived from its `name` property.

=item * C<< $msg->execution_type() >> / C<< $msg->execution_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::ExecutionType>)

Optional. The execution type of the tool.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The timeout for the tool execution. If not set, the default
timeout is 30 seconds for `SYNCHRONOUS` tools and 60 seconds for
`ASYNCHRONOUS` tools.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the tool was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the tool was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Etag used to ensure the object hasn't changed during a read-modify-write
operation. If the etag is empty, the update will overwrite any concurrent
changes.

=item * C<< $msg->generated_summary() >> / C<< $msg->generated_summary($value) >>

Type: C<String>

Output only. If the tool is generated by the LLM assistant, this field
contains a descriptive summary of the generation.

=item * C<< $msg->tool_fake_config() >> / C<< $msg->tool_fake_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Fakes::ToolFakeConfig>)

Optional. Configuration for tool behavior in fake mode.

=item * C<< $msg->read_only() >> / C<< $msg->read_only($value) >>

Type: C<Bool>

Output only. Indicates whether the tool is read-only. If true, the tool
cannot be modified by the user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Tool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
