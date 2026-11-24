package Google::Cloud::Ces::V1::Tool;

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
    eval { require Google::Cloud::Ces::V1::AgentCard };
    eval { require Google::Cloud::Ces::V1::AgentTool };
    eval { require Google::Cloud::Ces::V1::ClientFunction };
    eval { require Google::Cloud::Ces::V1::Common };
    eval { require Google::Cloud::Ces::V1::ConnectorTool };
    eval { require Google::Cloud::Ces::V1::DataStoreTool };
    eval { require Google::Cloud::Ces::V1::Fakes };
    eval { require Google::Cloud::Ces::V1::FileSearchTool };
    eval { require Google::Cloud::Ces::V1::GoogleSearchTool };
    eval { require Google::Cloud::Ces::V1::McpTool };
    eval { require Google::Cloud::Ces::V1::OpenApiTool };
    eval { require Google::Cloud::Ces::V1::PythonFunction };
    eval { require Google::Cloud::Ces::V1::SystemTool };
    eval { require Google::Cloud::Ces::V1::WidgetTool };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ch5nb29nbGUvY2xvdWQvY2VzL3YxL3Rvb2wucHJvdG8SE2dvb2dsZS5jbG91ZC5jZXMudjEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aJGdvb2dsZS9jbG91ZC9jZXMvdjEvYWdlbnRfY2FyZC5wcm90bxokZ29vZ2xlL2Ns
b3VkL2Nlcy92MS9hZ2VudF90b29sLnByb3RvGilnb29nbGUvY2xvdWQvY2VzL3YxL2NsaWVu
dF9mdW5jdGlvbi5wcm90bxogZ29vZ2xlL2Nsb3VkL2Nlcy92MS9jb21tb24ucHJvdG8aKGdv
b2dsZS9jbG91ZC9jZXMvdjEvY29ubmVjdG9yX3Rvb2wucHJvdG8aKWdvb2dsZS9jbG91ZC9j
ZXMvdjEvZGF0YV9zdG9yZV90b29sLnByb3RvGh9nb29nbGUvY2xvdWQvY2VzL3YxL2Zha2Vz
LnByb3RvGipnb29nbGUvY2xvdWQvY2VzL3YxL2ZpbGVfc2VhcmNoX3Rvb2wucHJvdG8aLGdv
b2dsZS9jbG91ZC9jZXMvdjEvZ29vZ2xlX3NlYXJjaF90b29sLnByb3RvGiJnb29nbGUvY2xv
dWQvY2VzL3YxL21jcF90b29sLnByb3RvGidnb29nbGUvY2xvdWQvY2VzL3YxL29wZW5fYXBp
X3Rvb2wucHJvdG8aKWdvb2dsZS9jbG91ZC9jZXMvdjEvcHl0aG9uX2Z1bmN0aW9uLnByb3Rv
GiVnb29nbGUvY2xvdWQvY2VzL3YxL3N5c3RlbV90b29sLnByb3RvGiVnb29nbGUvY2xvdWQv
Y2VzL3YxL3dpZGdldF90b29sLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipwwKBFRvb2wSUwoPY2xpZW50
X2Z1bmN0aW9uGAIgASgLMiMuZ29vZ2xlLmNsb3VkLmNlcy52MS5DbGllbnRGdW5jdGlvbkID
4EEBSABSDmNsaWVudEZ1bmN0aW9uEksKDW9wZW5fYXBpX3Rvb2wYAyABKAsyIC5nb29nbGUu
Y2xvdWQuY2VzLnYxLk9wZW5BcGlUb29sQgPgQQFIAFILb3BlbkFwaVRvb2wSWgoSZ29vZ2xl
X3NlYXJjaF90b29sGAUgASgLMiUuZ29vZ2xlLmNsb3VkLmNlcy52MS5Hb29nbGVTZWFyY2hU
b29sQgPgQQFIAFIQZ29vZ2xlU2VhcmNoVG9vbBJQCg5jb25uZWN0b3JfdG9vbBgIIAEoCzIi
Lmdvb2dsZS5jbG91ZC5jZXMudjEuQ29ubmVjdG9yVG9vbEID4EEBSABSDWNvbm5lY3RvclRv
b2wSUQoPZGF0YV9zdG9yZV90b29sGAogASgLMiIuZ29vZ2xlLmNsb3VkLmNlcy52MS5EYXRh
U3RvcmVUb29sQgPgQQFIAFINZGF0YVN0b3JlVG9vbBJTCg9weXRob25fZnVuY3Rpb24YCyAB
KAsyIy5nb29nbGUuY2xvdWQuY2VzLnYxLlB5dGhvbkZ1bmN0aW9uQgPgQQFIAFIOcHl0aG9u
RnVuY3Rpb24SPgoIbWNwX3Rvb2wYECABKAsyHC5nb29nbGUuY2xvdWQuY2VzLnYxLk1jcFRv
b2xCA+BBAUgAUgdtY3BUb29sElQKEGZpbGVfc2VhcmNoX3Rvb2wYESABKAsyIy5nb29nbGUu
Y2xvdWQuY2VzLnYxLkZpbGVTZWFyY2hUb29sQgPgQQFIAFIOZmlsZVNlYXJjaFRvb2wSRwoL
c3lzdGVtX3Rvb2wYEiABKAsyHy5nb29nbGUuY2xvdWQuY2VzLnYxLlN5c3RlbVRvb2xCA+BB
AUgAUgpzeXN0ZW1Ub29sEkQKCmFnZW50X3Rvb2wYFyABKAsyHi5nb29nbGUuY2xvdWQuY2Vz
LnYxLkFnZW50VG9vbEID4EEBSABSCWFnZW50VG9vbBJHCgt3aWRnZXRfdG9vbBgYIAEoCzIf
Lmdvb2dsZS5jbG91ZC5jZXMudjEuV2lkZ2V0VG9vbEID4EEBSABSCndpZGdldFRvb2wSVwoR
cmVtb3RlX2FnZW50X3Rvb2wYGSABKAsyJC5nb29nbGUuY2xvdWQuY2VzLnYxLlJlbW90ZUFn
ZW50VG9vbEID4EEBSABSD3JlbW90ZUFnZW50VG9vbBIXCgRuYW1lGAEgASgJQgPgQQhSBG5h
bWUSJgoMZGlzcGxheV9uYW1lGA0gASgJQgPgQQNSC2Rpc3BsYXlOYW1lEk4KDmV4ZWN1dGlv
bl90eXBlGAwgASgOMiIuZ29vZ2xlLmNsb3VkLmNlcy52MS5FeGVjdXRpb25UeXBlQgPgQQFS
DWV4ZWN1dGlvblR5cGUSOAoHdGltZW91dBgWIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJh
dGlvbkID4EEBUgd0aW1lb3V0EkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAcgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEhIKBGV0YWcYDiAB
KAlSBGV0YWcSMAoRZ2VuZXJhdGVkX3N1bW1hcnkYDyABKAlCA+BBA1IQZ2VuZXJhdGVkU3Vt
bWFyeRJSChB0b29sX2Zha2VfY29uZmlnGBQgASgLMiMuZ29vZ2xlLmNsb3VkLmNlcy52MS5U
b29sRmFrZUNvbmZpZ0ID4EEBUg50b29sRmFrZUNvbmZpZzpq6kFnChdjZXMuZ29vZ2xlYXBp
cy5jb20vVG9vbBI/cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fw
cHMve2FwcH0vdG9vbHMve3Rvb2x9KgV0b29sczIEdG9vbEILCgl0b29sX3R5cGVCUQoXY29t
Lmdvb2dsZS5jbG91ZC5jZXMudjFCCVRvb2xQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dv
L2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkr5IwoHEgUOAIwBAQq8BAoBDBIDDgASMrEEIENvcHly
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
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQALgoJCgIDAxIDFQAuCgkKAgMEEgMWADMKCQoCAwUSAxcAKgoJCgIDBhIDGAAyCgkKAgMH
EgMZADMKCQoCAwgSAxoAKQoJCgIDCRIDGwA0CgkKAgMKEgMcADYKCQoCAwsSAx0ALAoJCgID
DBIDHgAxCgkKAgMNEgMfADMKCQoCAw4SAyAALwoJCgIDDxIDIQAvCgkKAgMQEgMiACgKCQoC
AxESAyMAKQoICgEIEgMlAEAKCQoCCAsSAyUAQAoICgEIEgMmACIKCQoCCAoSAyYAIgoICgEI
EgMnACoKCQoCCAgSAycAKgoICgEIEgMoADAKCQoCCAESAygAMAphCgIEABIFLACMAQEaVCBB
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
ASQmCg0KBQQAAhQIEgSLASdPChAKCAQAAhQInAgAEgSLAShOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Tool::Tool ===
    # Fields for Tool
    # Field: client_function Type: 11 (.google.cloud.ces.v1.ClientFunction)
    # Field: open_api_tool Type: 11 (.google.cloud.ces.v1.OpenApiTool)
    # Field: google_search_tool Type: 11 (.google.cloud.ces.v1.GoogleSearchTool)
    # Field: connector_tool Type: 11 (.google.cloud.ces.v1.ConnectorTool)
    # Field: data_store_tool Type: 11 (.google.cloud.ces.v1.DataStoreTool)
    # Field: python_function Type: 11 (.google.cloud.ces.v1.PythonFunction)
    # Field: mcp_tool Type: 11 (.google.cloud.ces.v1.McpTool)
    # Field: file_search_tool Type: 11 (.google.cloud.ces.v1.FileSearchTool)
    # Field: system_tool Type: 11 (.google.cloud.ces.v1.SystemTool)
    # Field: agent_tool Type: 11 (.google.cloud.ces.v1.AgentTool)
    # Field: widget_tool Type: 11 (.google.cloud.ces.v1.WidgetTool)
    # Field: remote_agent_tool Type: 11 (.google.cloud.ces.v1.RemoteAgentTool)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: execution_type Type: 14 (.google.cloud.ces.v1.ExecutionType)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: generated_summary Type: 9 ()
    # Field: tool_fake_config Type: 11 (.google.cloud.ces.v1.ToolFakeConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Tool - Compiled Protocol Buffers messages for google/cloud/ces/v1/tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Tool;

    my $msg = Google::Cloud::Ces::V1::Tool::Tool->new({
        client_function => $client_function,
        open_api_tool => $open_api_tool,
        google_search_tool => $google_search_tool,
        connector_tool => $connector_tool,
    });

    # Read or update a field
    my $val = $msg->client_function();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Tool::Tool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Tool::Tool

A tool represents an action that the CES agent can take to achieve certain
goals.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_function() >> / C<< $msg->client_function($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ClientFunction::ClientFunction>)

Optional. The client function.

=item * C<< $msg->open_api_tool() >> / C<< $msg->open_api_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::OpenApiTool::OpenApiTool>)

Optional. The open API tool.

=item * C<< $msg->google_search_tool() >> / C<< $msg->google_search_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::GoogleSearchTool::GoogleSearchTool>)

Optional. The google search tool.

=item * C<< $msg->connector_tool() >> / C<< $msg->connector_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ConnectorTool::ConnectorTool>)

Optional. The Integration Connector tool.

=item * C<< $msg->data_store_tool() >> / C<< $msg->data_store_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::DataStoreTool::DataStoreTool>)

Optional. The data store tool.

=item * C<< $msg->python_function() >> / C<< $msg->python_function($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::PythonFunction::PythonFunction>)

Optional. The python function tool.

=item * C<< $msg->mcp_tool() >> / C<< $msg->mcp_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::McpTool::McpTool>)

Optional. The MCP tool. An MCP tool cannot be created or updated directly
and is managed by the MCP toolset.

=item * C<< $msg->file_search_tool() >> / C<< $msg->file_search_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::FileSearchTool::FileSearchTool>)

Optional. The file search tool.

=item * C<< $msg->system_tool() >> / C<< $msg->system_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::SystemTool::SystemTool>)

Optional. The system tool.

=item * C<< $msg->agent_tool() >> / C<< $msg->agent_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentTool::AgentTool>)

Optional. The agent tool.

=item * C<< $msg->widget_tool() >> / C<< $msg->widget_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::WidgetTool::WidgetTool>)

Optional. The widget tool.

=item * C<< $msg->remote_agent_tool() >> / C<< $msg->remote_agent_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool>)

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

Type: C<Enum> (L<Google::Cloud::Ces::V1::ExecutionType>)

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

Type: C<Message> (L<Google::Cloud::Ces::V1::Fakes::ToolFakeConfig>)

Optional. Configuration for tool behavior in fake mode.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Tool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
