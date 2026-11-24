package Google::Cloud::Dialogflow::V2beta1::CompanionAgent;

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
    eval { require Google::Cloud::Dialogflow::V2beta1::CesTool };
    eval { require Google::Cloud::Dialogflow::V2beta1::Toolset };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2NvbXBhbmlvbl9hZ2VudC5wcm90
bxIfZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLmdvb2dsZS9jbG91
ZC9kaWFsb2dmbG93L3YyYmV0YTEvY2VzX3Rvb2wucHJvdG8aLWdvb2dsZS9jbG91ZC9kaWFs
b2dmbG93L3YyYmV0YTEvdG9vbHNldC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnBy
b3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byL5AQobQ3JlYXRlQ29tcGFuaW9uQWdlbnRSZXF1ZXN0EkgKBnBh
cmVudBgBIAEoCUIw4EEC+kEqEihkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbXBhbmlv
bkFnZW50UgZwYXJlbnQSXQoPY29tcGFuaW9uX2FnZW50GAIgASgLMi8uZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjJiZXRhMS5Db21wYW5pb25BZ2VudEID4EECUg5jb21wYW5pb25BZ2Vu
dBIxChJjb21wYW5pb25fYWdlbnRfaWQYAyABKAlCA+BBAVIQY29tcGFuaW9uQWdlbnRJZCJg
ChhHZXRDb21wYW5pb25BZ2VudFJlcXVlc3QSRAoEbmFtZRgBIAEoCUIw4EEC+kEqCihkaWFs
b2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbXBhbmlvbkFnZW50UgRuYW1lIqwBChpMaXN0Q29t
cGFuaW9uQWdlbnRzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKhIoZGlhbG9nZmxv
dy5nb29nbGVhcGlzLmNvbS9Db21wYW5pb25BZ2VudFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgC
IAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tl
biKhAQobTGlzdENvbXBhbmlvbkFnZW50c1Jlc3BvbnNlEloKEGNvbXBhbmlvbl9hZ2VudHMY
ASADKAsyLy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbXBhbmlvbkFnZW50
Ug9jb21wYW5pb25BZ2VudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuIr4BChtVcGRhdGVDb21wYW5pb25BZ2VudFJlcXVlc3QSXQoPY29tcGFuaW9uX2FnZW50
GAEgASgLMi8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db21wYW5pb25BZ2Vu
dEID4EECUg5jb21wYW5pb25BZ2VudBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJjChtEZWxldGVDb21wYW5pb25B
Z2VudFJlcXVlc3QSRAoEbmFtZRgBIAEoCUIw4EEC+kEqCihkaWFsb2dmbG93Lmdvb2dsZWFw
aXMuY29tL0NvbXBhbmlvbkFnZW50UgRuYW1lIsADChNHdWlkYW5jZUluc3RydWN0aW9uEiYK
DGRpc3BsYXlfbmFtZRgBIAEoCUID4EEBUgtkaXNwbGF5TmFtZRIsCg9kaXNwbGF5X2RldGFp
bHMYAiABKAlCA+BBAVIOZGlzcGxheURldGFpbHMSIQoJY29uZGl0aW9uGAMgASgJQgPgQQFS
CWNvbmRpdGlvbhJaCgdhY3Rpb25zGAQgAygLMjsuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMS5HdWlkYW5jZUluc3RydWN0aW9uLkFjdGlvbkID4EEBUgdhY3Rpb25zEmYKDXRy
aWdnZXJfZXZlbnQYBiABKA4yPC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNv
bXBhbmlvbkFnZW50LlRyaWdnZXJFdmVudEID4EEBUgx0cmlnZ2VyRXZlbnQSOwoXZGlzYWJs
ZV9zdWdnZXN0ZWRfcmVwbHkYByABKAhCA+BBAVIVZGlzYWJsZVN1Z2dlc3RlZFJlcGx5Gi8K
BkFjdGlvbhIlCgtkZXNjcmlwdGlvbhgBIAEoCUID4EECUgtkZXNjcmlwdGlvbiKBDAoOQ29t
cGFuaW9uQWdlbnQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3Vw
ZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRh
dGVUaW1lElYKDXRvb2xzZXRfdG9vbHMYBCADKAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52MmJldGExLlRvb2xzZXRUb29sQgPgQQFSDHRvb2xzZXRUb29scxJXCg5jZXNfdG9vbF9z
cGVjcxgFIAMoCzIsLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ2VzVG9vbFNw
ZWNCA+BBAVIMY2VzVG9vbFNwZWNzEiYKDGRpc3BsYXlfbmFtZRgIIAEoCUID4EEBUgtkaXNw
bGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgJIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJlCg1za2ls
bF9jb25maWdzGAcgAygLMjsuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db21w
YW5pb25BZ2VudC5Ta2lsbENvbmZpZ0ID4EEBUgxza2lsbENvbmZpZ3MamwMKC1NraWxsQ29u
ZmlnEn4KFWd1aWRhbmNlX3NraWxsX2NvbmZpZxgCIAEoCzJDLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuQ29tcGFuaW9uQWdlbnQuR3VpZGFuY2VTa2lsbENvbmZpZ0ID4EEB
SABSE2d1aWRhbmNlU2tpbGxDb25maWcSiAEKFnNraWxsX3RyaWdnZXJpbmdfZXZlbnQYASAB
KA4yTS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbXBhbmlvbkFnZW50LlNr
aWxsQ29uZmlnLlNraWxsVHJpZ2dlckV2ZW50QgPgQQFSFHNraWxsVHJpZ2dlcmluZ0V2ZW50
IncKEVNraWxsVHJpZ2dlckV2ZW50EiMKH1NLSUxMX1RSSUdHRVJfRVZFTlRfVU5TUEVDSUZJ
RUQQABIUChBFTkRfT0ZfVVRURVJBTkNFEAESFAoQQ1VTVE9NRVJfTUVTU0FHRRACEhEKDUFH
RU5UX01FU1NBR0UQA0IICgZjb25maWcargIKE0d1aWRhbmNlU2tpbGxDb25maWcSbgoVZ3Vp
ZGFuY2VfaW5zdHJ1Y3Rpb25zGAIgAygLMjQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJi
ZXRhMS5HdWlkYW5jZUluc3RydWN0aW9uQgPgQQFSFGd1aWRhbmNlSW5zdHJ1Y3Rpb25zEjYK
FG92ZXJhcmNoaW5nX2d1aWRhbmNlGAMgASgJQgPgQQFSE292ZXJhcmNoaW5nR3VpZGFuY2US
bwoQa25vd2xlZGdlX3NvdXJjZRgFIAEoCzI/Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
YmV0YTEuQ29tcGFuaW9uQWdlbnQuS25vd2xlZGdlU291cmNlQgPgQQFSD2tub3dsZWRnZVNv
dXJjZRoRCg9Lbm93bGVkZ2VTb3VyY2UibAoMVHJpZ2dlckV2ZW50Eh0KGVRSSUdHRVJfRVZF
TlRfVU5TUEVDSUZJRUQQABIUChBFTkRfT0ZfVVRURVJBTkNFEAESFAoQQ1VTVE9NRVJfTUVT
U0FHRRACEhEKDUFHRU5UX01FU1NBR0UQAzqaAepBlgEKKGRpYWxvZ2Zsb3cuZ29vZ2xlYXBp
cy5jb20vQ29tcGFuaW9uQWdlbnQSSXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jb21wYW5pb25BZ2VudHMve2NvbXBhbmlvbl9hZ2VudH0qD2NvbXBhbmlvbkFn
ZW50czIOY29tcGFuaW9uQWdlbnQy/AkKD0NvbXBhbmlvbkFnZW50cxKEAgoUQ3JlYXRlQ29t
cGFuaW9uQWdlbnQSPC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNyZWF0ZUNv
bXBhbmlvbkFnZW50UmVxdWVzdBovLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
Q29tcGFuaW9uQWdlbnQifYLT5JMCSyI4L3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qfS9jb21wYW5pb25BZ2VudHM6D2NvbXBhbmlvbl9hZ2VudNpBKXBhcmVudCxj
b21wYW5pb25fYWdlbnQsY29tcGFuaW9uX2FnZW50X2lkEsgBChFHZXRDb21wYW5pb25BZ2Vu
dBI5Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuR2V0Q29tcGFuaW9uQWdlbnRS
ZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db21wYW5pb25BZ2Vu
dCJHgtPkkwI6EjgvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbXBh
bmlvbkFnZW50cy8qfdpBBG5hbWUShgIKFFVwZGF0ZUNvbXBhbmlvbkFnZW50EjwuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5VcGRhdGVDb21wYW5pb25BZ2VudFJlcXVlc3Qa
Ly5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbXBhbmlvbkFnZW50In+C0+ST
AlsySC92MmJldGExL3tjb21wYW5pb25fYWdlbnQubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NvbXBhbmlvbkFnZW50cy8qfToPY29tcGFuaW9uX2FnZW502kEbY29tcGFuaW9uX2Fn
ZW50LHVwZGF0ZV9tYXNrErUBChREZWxldGVDb21wYW5pb25BZ2VudBI8Lmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuRGVsZXRlQ29tcGFuaW9uQWdlbnRSZXF1ZXN0GhYuZ29v
Z2xlLnByb3RvYnVmLkVtcHR5IkeC0+STAjoqOC92MmJldGExL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovY29tcGFuaW9uQWdlbnRzLyp92kEEbmFtZRLbAQoTTGlzdENvbXBhbmlv
bkFnZW50cxI7Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuTGlzdENvbXBhbmlv
bkFnZW50c1JlcXVlc3QaPC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkxpc3RD
b21wYW5pb25BZ2VudHNSZXNwb25zZSJJgtPkkwI6EjgvdjJiZXRhMS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyp9L2NvbXBhbmlvbkFnZW50c9pBBnBhcmVudBp4ykEZZGlhbG9n
Zmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFsb2dm
bG93QqgBCiNjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMUITQ29tcGFuaW9u
QWdlbnRQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRh
MS9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9n
Zmxvdy5WMkJldGExSvhPCgcSBQ4AwwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAOAoJCgIDBRIDFwA3CgkKAgMGEgMYACUKCQoCAwcSAxkAKgoJCgID
CBIDGgApCggKAQgSAxwAPAoJCgIIJRIDHAA8CggKAQgSAx0AWgoJCgIICxIDHQBaCggKAQgS
Ax4AIgoJCgIIChIDHgAiCggKAQgSAx8ANAoJCgIICBIDHwA0CggKAQgSAyAAPAoJCgIIARID
IAA8CggKAQgSAyEAIAoJCgIIJBIDIQAgCjQKAgYAEgQkAFgBGiggU2VydmljZSBmb3IgbWFu
YWdpbmcgY29tcGFuaW9uIGFnZW50cy4KCgoKAwYAARIDJAgXCgoKAwYAAxIDJQJBCgwKBQYA
A5kIEgMlAkEKCwoDBgADEgQmAigzCg0KBQYAA5oIEgQmAigzCioKBAYAAgASBCsCMwMaHCBD
cmVhdGVzIGEgY29tcGFuaW9uIGFnZW50LgoKDAoFBgACAAESAysGGgoMCgUGAAIAAhIDKxs2
CgwKBQYAAgADEgMsDx0KDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAGCg0KBQYA
AgAEEgQxBDI0ChAKCAYAAgAEmwgAEgQxBDI0CicKBAYAAgESBDYCOwMaGSBHZXRzIGEgY29t
cGFuaW9uIGFnZW50LgoKDAoFBgACAQESAzYGFwoMCgUGAAIBAhIDNhgwCgwKBQYAAgEDEgM2
O0kKDQoFBgACAQQSBDcEOQYKEQoJBgACAQSwyrwiEgQ3BDkGCgwKBQYAAgEEEgM6BDIKDwoI
BgACAQSbCAASAzoEMgoqCgQGAAICEgQ+AkUDGhwgVXBkYXRlcyBhIGNvbXBhbmlvbiBhZ2Vu
dC4KCgwKBQYAAgIBEgM+BhoKDAoFBgACAgISAz4bNgoMCgUGAAICAxIDPw8dCg0KBQYAAgIE
EgRABEMGChEKCQYAAgIEsMq8IhIEQARDBgoMCgUGAAICBBIDRARJCg8KCAYAAgIEmwgAEgNE
BEkKKgoEBgACAxIESAJOAxocIERlbGV0ZXMgYSBjb21wYW5pb24gYWdlbnQuCgoMCgUGAAID
ARIDSAYaCgwKBQYAAgMCEgNIGzYKDAoFBgACAwMSA0kPJAoNCgUGAAIDBBIESgRMBgoRCgkG
AAIDBLDKvCISBEoETAYKDAoFBgACAwQSA00EMgoPCggGAAIDBJsIABIDTQQyCicKBAYAAgQS
BFECVwMaGSBMaXN0cyBjb21wYW5pb24gYWdlbnRzLgoKDAoFBgACBAESA1EGGQoMCgUGAAIE
AhIDURo0CgwKBQYAAgQDEgNSDyoKDQoFBgACBAQSBFMEVQYKEQoJBgACBASwyrwiEgRTBFUG
CgwKBQYAAgQEEgNWBDQKDwoIBgACBASbCAASA1YENAouCgIEABIEWwBrARoiIFJlcXVlc3Qg
b2YgQ3JlYXRlQ29tcGFuaW9uQWdlbnQuCgoKCgMEAAESA1sIIwqNAQoEBAACABIEXgJjBBp/
IFJlcXVpcmVkLiBSZXNvdXJjZSBpZGVudGlmaWVyIG9mIHRoZSBwcm9qZWN0IGNyZWF0aW5n
IHRoZSBjb21wYW5pb24gYWdlbnQuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn1gCgoMCgUEAAIABRIDXgIICgwKBQQAAgABEgNeCQ8KDAoFBAAC
AAMSA14SEwoNCgUEAAIACBIEXhRjAwoPCggEAAIACJwIABIDXwQqCg8KBwQAAgAInwgSBGAE
YgUKNwoEBAACARIDZgJOGiogUmVxdWlyZWQuIFRoZSBjb21wYW5pb24gYWdlbnQgdG8gY3Jl
YXRlLgoKDAoFBAACAQYSA2YCEAoMCgUEAAIBARIDZhEgCgwKBQQAAgEDEgNmIyQKDAoFBAAC
AQgSA2YlTQoPCggEAAIBCJwIABIDZiZMCokBCgQEAAICEgNqAkkafCBPcHRpb25hbC4gVGhl
IHJlc291cmNlIElEIG9mIHRoZSBjb21wYW5pb24gYWdlbnQgdG8gY3JlYXRlLiBJZiBub3QK
IHByb3ZpZGVkLCB0aGUgc2VydmVyIHdpbGwgYXV0by1nZW5lcmF0ZSBhIHJlc291cmNlIElE
LgoKDAoFBAACAgUSA2oCCAoMCgUEAAICARIDagkbCgwKBQQAAgIDEgNqHh8KDAoFBAACAggS
A2ogSAoPCggEAAICCJwIABIDaiFHCjQKAgQBEgRuAHoBGiggUmVxdWVzdCBtZXNzYWdlIGZv
ciBHZXRDb21wYW5pb25BZ2VudC4KCgoKAwQBARIDbgggCpMCCgQEAQIAEgR0AnkEGoQCIFJl
cXVpcmVkLiBUaGUgdW5pcXVlIHJlc291cmNlIGlkZW50aWZpZXIgb2YgdGhlIENvbXBhbmlv
bkFnZW50IHRvIGdldCBhbGwKIGluZm9ybWF0aW9uIGZvci4gRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb21wYW5pb25BZ2VudHMve2NvbXBh
bmlvbl9hZ2VudH1gLgogQ29udGFpbnMgdGhlIGluZm9ybWF0aW9uIGFib3V0IHRoZSBwcm9q
ZWN0X2lkLCBsb2NhdGlvbl9pZCwKIGNvbXBhbmlvbl9hZ2VudF9pZAoKDAoFBAECAAUSA3QC
CAoMCgUEAQIAARIDdAkNCgwKBQQBAgADEgN0EBEKDQoFBAECAAgSBHQSeQMKDwoIBAECAAic
CAASA3UEKgoPCgcEAQIACJ8IEgR2BHgFCjcKAgQCEgV9AI0BARoqIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgTGlzdENvbXBhbmlvbkFnZW50cy4KCgoKAwQCARIDfQgiCokBCgQEAgIAEgaAAQKF
AQQaeSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lIHRvIGxpc3QgdGhlIGNv
bXBhbmlvbiBhZ2VudHMgZm9yLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259YAoKDQoFBAICAAUSBIABAggKDQoFBAICAAESBIABCQ8KDQoFBAIC
AAMSBIABEhMKDwoFBAICAAgSBoABFIUBAwoQCggEAgIACJwIABIEgQEEKgoRCgcEAgIACJ8I
EgaCAQSEAQUKegoEBAICARIEiQECPxpsIE9wdGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiBj
b21wYW5pb24gYWdlbnRzIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLgogQnkgZGVmYXVs
dCAxMDAgYW5kIGF0IG1vc3QgMTAwMC4KCg0KBQQCAgEFEgSJAQIHCg0KBQQCAgEBEgSJAQgR
Cg0KBQQCAgEDEgSJARQVCg0KBQQCAgEIEgSJARY+ChAKCAQCAgEInAgAEgSJARc9CkgKBAQC
AgISBIwBAkEaOiBPcHRpb25hbC4gVGhlIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBw
cmV2aW91cyBjYWxsLgoKDQoFBAICAgUSBIwBAggKDQoFBAICAgESBIwBCRMKDQoFBAICAgMS
BIwBFhcKDQoFBAICAggSBIwBGEAKEAoIBAICAgicCAASBIwBGT8KOQoCBAMSBpABAJcBARor
IFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExpc3RDb21wYW5pb25BZ2VudHMuCgoLCgMEAwESBJAB
CCMKLQoEBAMCABIEkgECLxofIFRoZSBsaXN0IG9mIGNvbXBhbmlvbiBhZ2VudHMuCgoNCgUE
AwIABBIEkgECCgoNCgUEAwIABhIEkgELGQoNCgUEAwIAARIEkgEaKgoNCgUEAwIAAxIEkgEt
LgpvCgQEAwIBEgSWAQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiBy
ZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUg
bGlzdC4KCg0KBQQDAgEFEgSWAQIICg0KBQQDAgEBEgSWAQkYCg0KBQQDAgEDEgSWARscCjkK
AgQEEgaaAQChAQEaKyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZUNvbXBhbmlvbkFnZW50
LgoKCwoDBAQBEgSaAQgjCjgKBAQEAgASBJwBAk4aKiBSZXF1aXJlZC4gVGhlIENvbXBhbmlv
biBBZ2VudCB0byB1cGRhdGUuCgoNCgUEBAIABhIEnAECEAoNCgUEBAIAARIEnAERIAoNCgUE
BAIAAxIEnAEjJAoNCgUEBAIACBIEnAElTQoQCggEBAIACJwIABIEnAEmTAo8CgQEBAIBEgaf
AQKgAS8aLCBPcHRpb25hbC4gVXBkYXRlIG1hc2sgZm9yIENvbXBhbmlvbiBBZ2VudC4KCg0K
BQQEAgEGEgSfAQIbCg0KBQQEAgEBEgSfARwnCg0KBQQEAgEDEgSfASorCg0KBQQEAgEIEgSg
AQYuChAKCAQEAgEInAgAEgSgAQctCjkKAgQFEgakAQCuAQEaKyBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIERlbGV0ZUNvbXBhbmlvbkFnZW50LgoKCwoDBAUBEgSkAQgjCrMBCgQEBQIAEgaoAQKt
AQQaogEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgcmVzb3VyY2UgaWRlbnRpZmllciBvZiB0aGUg
Q29tcGFuaW9uQWdlbnQgdG8gZGVsZXRlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb21wYW5pb25BZ2VudHMve2NvbXBhbmlvbl9hZ2Vu
dH1gLgoKDQoFBAUCAAUSBKgBAggKDQoFBAUCAAESBKgBCQ0KDQoFBAUCAAMSBKgBEBEKDwoF
BAUCAAgSBqgBEq0BAwoQCggEBQIACJwIABIEqQEEKgoRCgcEBQIACJ8IEgaqAQSsAQUKPQoC
BAYSBrEBANQBARovIEd1aWRhbmNlIGluc3RydWN0aW9uIGZvciB0aGUgY29tcGFuaW9uIGFn
ZW50LgoKCwoDBAYBEgSxAQgbClkKBAQGAwASBrMBArgBAxpJIEFjdGlvbnMgdG8gdGFrZSwg
aW5jbHVkaW5nIGFnZW50IGFjdGlvbiBhbmQgc3lzdGVtIGFjdGlvbiAoYXV0b21hdGlvbiku
CgoNCgUEBgMAARIEswEKEArjAQoGBAYDAAIAEgS3AQREGtIBIFJlcXVpcmVkLiBEZXNjcmlw
dGlvbiBvZiBhY3Rpb24gaXRlbS4gSXQgY2FuIGJlIGEgYWdlbnQgYWN0aW9uIChlLmcuCiAi
U2VuZCBhIG1lc3NhZ2UgdG8gdGhlIGN1c3RvbWVyIiwgImdyZWV0IHRoZSBjdXN0b21lciIp
IG9yIHN5c3RlbSBhY3Rpb24KIChlLmcuICJVcGRhdGUgdGhlIHRpY2tldCIsICJDcmVhdGUg
YSB0YXNrIiwgImNhbmNlbCB0aGUgb3JkZXIiKS4KCg8KBwQGAwACAAUSBLcBBAoKDwoHBAYD
AAIAARIEtwELFgoPCgcEBgMAAgADEgS3ARkaCg8KBwQGAwACAAgSBLcBG0MKEgoKBAYDAAIA
CJwIABIEtwEcQgpzCgQEBgIAEgS8AQJDGmUgT3B0aW9uYWwuIERpc3BsYXkgbmFtZSBmb3Ig
dGhlIGluc3RydWN0aW9uLiBUaGlzIG5hbWUgc2hvdWxkIGJlIHVuaXF1ZQogd2l0aGluIHRo
ZSBjb21wYW5pb24gYWdlbnQuCgoNCgUEBgIABRIEvAECCAoNCgUEBgIAARIEvAEJFQoNCgUE
BgIAAxIEvAEYGQoNCgUEBgIACBIEvAEaQgoQCggEBgIACJwIABIEvAEbQQpHCgQEBgIBEgS/
AQJGGjkgT3B0aW9uYWwuIFRoZSBkZXRhaWxlZCBkZXNjcmlwdGlvbiBvZiB0aGlzIGluc3Ry
dWN0aW9uLgoKDQoFBAYCAQUSBL8BAggKDQoFBAYCAQESBL8BCRgKDQoFBAYCAQMSBL8BGxwK
DQoFBAYCAQgSBL8BHUUKEAoIBAYCAQicCAASBL8BHkQK1AEKBAQGAgISBMQBAkAaxQEgT3B0
aW9uYWwuIFRoZSBjb25kaXRpb24gb2YgdGhlIGluc3RydWN0aW9uLiBGb3IgZXhhbXBsZSwg
InRoZSBjdXN0b21lcgogd2FudHMgdG8gY2FuY2VsIGFuIG9yZGVyIi4gIElmIHRoZSB1c2Vy
cyB3YW50IHRoZSBpbnN0cnVjdGlvbiB0byBiZQogdHJpZ2dlcmVkIHVuY29uZGl0aW9uYWxs
eSwgdGhlIGNvbmRpdGlvbiBjYW4gYmUgZW1wdHkuCgoNCgUEBgICBRIExAECCAoNCgUEBgIC
ARIExAEJEgoNCgUEBgICAxIExAEVFgoNCgUEBgICCBIExAEXPwoQCggEBgICCJwIABIExAEY
PgpBCgQEBgIDEgTHAQJHGjMgT3B0aW9uYWwuIFRoZSBhY3Rpb24gaXRlbXMgdGhhdCBjYW4g
YmUgcHJvY2Vzc2VkLgoKDQoFBAYCAwQSBMcBAgoKDQoFBAYCAwYSBMcBCxEKDQoFBAYCAwES
BMcBEhkKDQoFBAYCAwMSBMcBHB0KDQoFBAYCAwgSBMcBHkYKEAoIBAYCAwicCAASBMcBH0UK
rwEKBAQGAgQSBswBAs0BLxqeASBPcHRpb25hbC4gRXZlbnQgdGhhdCB0cmlnZ2VycyB0aGUg
Z3VpZGFuY2UgaW5zdHJ1Y3Rpb24uCiBJZiBVTlNQRUNJRklFRCwgdGhlIGluc3RydWN0aW9u
IHRyaWdnZXJpbmcgd2lsbCBiZSB0aGUgc2FtZSBhcyB0aGUgc2tpbGwncwogc2tpbGxfdHJp
Z2dlcmluZ19ldmVudC4KCg0KBQQGAgQGEgTMAQIdCg0KBQQGAgQBEgTMAR4rCg0KBQQGAgQD
EgTMAS4vCg0KBQQGAgQIEgTNAQYuChAKCAQGAgQInAgAEgTNAQctCvABCgQEBgIFEgTTAQJM
GuEBIE9wdGlvbmFsLiBXaGV0aGVyIHRvIGRpc2FibGUgc3VnZ2VzdGVkIHJlcGx5IGdlbmVy
YXRpb24gZm9yIHRoaXMKIGluc3RydWN0aW9uLiBXaGVuIHNldCB0byBgdHJ1ZWAsIGd1aWRh
bmNlIGdlbmVyYXRlZCBmcm9tIHRoaXMgaW5zdHJ1Y3Rpb24KIHdpbGwgbm90IGluY2x1ZGUg
YSBzdWdnZXN0ZWQgcmVwbHkuIERlZmF1bHQgaXMgYGZhbHNlYCAoc3VnZ2VzdGVkIHJlcGx5
CiBlbmFibGVkKS4KCg0KBQQGAgUFEgTTAQIGCg0KBQQGAgUBEgTTAQceCg0KBQQGAgUDEgTT
ASEiCg0KBQQGAgUIEgTTASNLChAKCAQGAgUInAgAEgTTASRKCiAKAgQHEgbXAQDDAgEaEiBD
b21wYW5pb24gYWdlbnQuCgoLCgMEBwESBNcBCBYKDQoDBAcHEgbYAQLdAQQKDwoFBAcHnQgS
BtgBAt0BBApXCgQEBwQAEgbgAQLvAQMaRyBFdmVudCB0aGF0IHRyaWdnZXJzIGNvbXBhbmlv
biBhZ2VudCBza2lsbHMgYW5kIGd1aWRhbmNlIGluc3RydWN0aW9ucy4KCg0KBQQHBAABEgTg
AQcTCtYBCgYEBwQAAgASBOUBBCIaxQEgRGVmYXVsdCB2YWx1ZSBmb3IgVHJpZ2dlckV2ZW50
LgogRm9yIHNraWxsX3RyaWdnZXJpbmdfZXZlbnQsIFVOU1BFQ0lGSUVEIGRlZmF1bHRzIHRv
IENVU1RPTUVSX01FU1NBR0UuCiBGb3IgaW5zdHJ1Y3Rpb24gdHJpZ2dlcl9ldmVudCwgVU5T
UEVDSUZJRUQgZGVmYXVsdHMgdG8gdGhlIHNraWxsJ3MKIHNraWxsX3RyaWdnZXJpbmdfZXZl
bnQuCgoPCgcEBwQAAgABEgTlAQQdCg8KBwQHBAACAAISBOUBICEKSgoGBAcEAAIBEgToAQQZ
GjogVHJpZ2dlcnMgd2hlbiBlYWNoIGNoYXQgbWVzc2FnZSBvciB2b2ljZSB1dHRlcmFuY2Ug
ZW5kcy4KCg8KBwQHBAACAQESBOgBBBQKDwoHBAcEAAIBAhIE6AEXGAo3CgYEBwQAAgISBOsB
BBkaJyBUcmlnZ2VycyBhZnRlciBlYWNoIGN1c3RvbWVyIG1lc3NhZ2UuCgoPCgcEBwQAAgIB
EgTrAQQUCg8KBwQHBAACAgISBOsBFxgKNAoGBAcEAAIDEgTuAQQWGiQgVHJpZ2dlcnMgYWZ0
ZXIgZWFjaCBhZ2VudCBtZXNzYWdlLgoKDwoHBAcEAAIDARIE7gEEEQoPCgcEBwQAAgMCEgTu
ARQVCj4KBAQHAwASBvIBAowCAxouIFNraWxsIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSBjb21w
YW5pb24gYWdlbnQuCgoNCgUEBwMAARIE8gEKFQo8CgYEBwMABAASBvQBBIACBRoqIFRoZSBl
dmVudCB0aGF0IHNob3VsZCB0cmlnZ2VyIHRoZSBza2lsbC4KCg8KBwQHAwAEAAESBPQBCRoK
OAoIBAcDAAQAAgASBPYBBioaJiBEZWZhdWx0IHZhbHVlIGZvciBTa2lsbFRyaWdnZXJFdmVu
dC4KChEKCQQHAwAEAAIAARIE9gEGJQoRCgkEBwMABAACAAISBPYBKCkKTAoIBAcDAAQAAgES
BPkBBhsaOiBUcmlnZ2VycyB3aGVuIGVhY2ggY2hhdCBtZXNzYWdlIG9yIHZvaWNlIHV0dGVy
YW5jZSBlbmRzLgoKEQoJBAcDAAQAAgEBEgT5AQYWChEKCQQHAwAEAAIBAhIE+QEZGgo5CggE
BwMABAACAhIE/AEGGxonIFRyaWdnZXJzIGFmdGVyIGVhY2ggY3VzdG9tZXIgbWVzc2FnZS4K
ChEKCQQHAwAEAAICARIE/AEGFgoRCgkEBwMABAACAgISBPwBGRoKNgoIBAcDAAQAAgMSBP8B
BhgaJCBUcmlnZ2VycyBhZnRlciBlYWNoIGFnZW50IG1lc3NhZ2UuCgoRCgkEBwMABAACAwES
BP8BBhMKEQoJBAcDAAQAAgMCEgT/ARYXClkKBgQHAwAIABIGgwIEhwIFGkcgRWFjaCBTa2ls
bENvbmZpZyB3aWxsIGJlIG9uZSBvZiB0aGUgZm9sbG93aW5nIHNwZWNpZmljIHNraWxsIGNv
bmZpZ3MuCgoPCgcEBwMACAABEgSDAgoQCjsKBgQHAwACABIGhQIGhgIzGikgT3B0aW9uYWwu
IEd1aWRhbmNlIHNraWxsIGNvbmZpZ3VyYXRpb24uCgoPCgcEBwMAAgAGEgSFAgYZCg8KBwQH
AwACAAESBIUCGi8KDwoHBAcDAAIAAxIEhQIyMwoPCgcEBwMAAgAIEgSGAgoyChIKCgQHAwAC
AAicCAASBIYCCzEKRgoGBAcDAAIBEgaKAgSLAjEaNCBPcHRpb25hbC4gVGhlIGV2ZW50IHRo
YXQgc2hvdWxkIHRyaWdnZXIgdGhlIHNraWxsLgoKDwoHBAcDAAIBBhIEigIEFQoPCgcEBwMA
AgEBEgSKAhYsCg8KBwQHAwACAQMSBIoCLzAKDwoHBAcDAAIBCBIEiwIIMAoSCgoEBwMAAgEI
nAgAEgSLAgkvCi8KBAQHAwESBo8CApsCAxofIEd1aWRhbmNlIHNraWxsIGNvbmZpZ3VyYXRp
b24uCgoNCgUEBwMBARIEjwIKHQpDCgYEBwMBAgASBpECBJICMRoxIE9wdGlvbmFsLiBDdXN0
b21pemVkIGluc3RydWN0aW9ucyBmb3IgZ3VpZGFuY2UuCgoPCgcEBwMBAgAEEgSRAgQMCg8K
BwQHAwECAAYSBJECDSAKDwoHBAcDAQIAARIEkQIhNgoPCgcEBwMBAgADEgSRAjk6Cg8KBwQH
AwECAAgSBJICCDAKEgoKBAcDAQIACJwIABIEkgIJLwpiCgYEBwMBAgESBJYCBE0aUiBPcHRp
b25hbC4gVGhpcyBpcyBzcGVjaWZpYyBhZGRpdGlvbmFsIGd1aWRhbmNlIHRoYXQgY2FuIGNv
bmZpZ3VyZWQgYnkgdGhlCiB1c2VyLgoKDwoHBAcDAQIBBRIElgIECgoPCgcEBwMBAgEBEgSW
AgsfCg8KBwQHAwECAQMSBJYCIiMKDwoHBAcDAQIBCBIElgIkTAoSCgoEBwMBAgEInAgAEgSW
AiVLCkoKBgQHAwECAhIGmQIEmgIxGjggT3B0aW9uYWwuIEtub3dsZWRnZSBzb3VyY2UgY29u
ZmlndXJhdGlvbiBmb3IgZ3VpZGFuY2UuCgoPCgcEBwMBAgIGEgSZAgQTCg8KBwQHAwECAgES
BJkCFCQKDwoHBAcDAQICAxIEmQInKAoPCgcEBwMBAgIIEgSaAggwChIKCgQHAwECAgicCAAS
BJoCCS8KRwoEBAcDAhIEngICHBo5IEtub3dsZWRnZSBzb3VyY2UgY29uZmlndXJhdGlvbiBm
b3Iga25vd2xlZGdlIHJldHJpZXZhbC4KCg0KBQQHAwIBEgSeAgoZCqABCgQEBwIAEgSjAgI9
GpEBIElkZW50aWZpZXIuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgY29tcGFuaW9u
IGFnZW50LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9jb21wYW5pb25BZ2VudHMve2NvbXBhbmlvbl9hZ2VudH1gCgoNCgUEBwIABRIEowIC
CAoNCgUEBwIAARIEowIJDQoNCgUEBwIAAxIEowIQEQoNCgUEBwIACBIEowISPAoQCggEBwIA
CJwIABIEowITOwpFCgQEBwIBEgamAgKnAjIaNSBPdXRwdXQgb25seS4gQ3JlYXRpb24gdGlt
ZSBvZiB0aGlzIGNvbXBhbmlvbiBhZ2VudC4KCg0KBQQHAgEGEgSmAgIbCg0KBQQHAgEBEgSm
AhwnCg0KBQQHAgEDEgSmAiorCg0KBQQHAgEIEgSnAgYxChAKCAQHAgEInAgAEgSnAgcwCkMK
BAQHAgISBqoCAqsCMhozIE91dHB1dCBvbmx5LiBVcGRhdGUgdGltZSBvZiB0aGlzIGNvbXBh
bmlvbiBhZ2VudC4KCg0KBQQHAgIGEgSqAgIbCg0KBQQHAgIBEgSqAhwnCg0KBQQHAgIDEgSq
AiorCg0KBQQHAgIIEgSrAgYxChAKCAQHAgIInAgAEgSrAgcwCmAKBAQHAgMSBq8CArACLxpQ
IE9wdGlvbmFsLiBMaXN0IG9mIENFUyB0b29sc2V0IHNwZWNzIHRoYXQgdGhlIGNvbXBhbmlv
biBhZ2VudCBjYW4gY2hvb3NlCiBmcm9tLgoKDQoFBAcCAwQSBK8CAgoKDQoFBAcCAwYSBK8C
CxYKDQoFBAcCAwESBK8CFyQKDQoFBAcCAwMSBK8CJygKDQoFBAcCAwgSBLACBi4KEAoIBAcC
AwicCAASBLACBy0KXAoEBAcCBBIGswICtAIvGkwgT3B0aW9uYWwuIExpc3Qgb2YgQ0VTIHRv
b2wgc3BlY3MgdGhhdCB0aGUgY29tcGFuaW9uIGFnZW50IGNhbiBjaG9vc2UgZnJvbS4KCg0K
BQQHAgQEEgSzAgIKCg0KBQQHAgQGEgSzAgsWCg0KBQQHAgQBEgSzAhclCg0KBQQHAgQDEgSz
AigpCg0KBQQHAgQIEgS0AgYuChAKCAQHAgQInAgAEgS0AgctClcKBAQHAgUSBLgCAkMaSSBP
cHRpb25hbC4gRGlzcGxheSBuYW1lIGZvciB0aGUgY29tcGFuaW9uIGFnZW50LgogQ2hhcmFj
dGVyIGxpbWl0IGlzIDYzLgoKDQoFBAcCBQUSBLgCAggKDQoFBAcCBQESBLgCCRUKDQoFBAcC
BQMSBLgCGBkKDQoFBAcCBQgSBLgCGkIKEAoIBAcCBQicCAASBLgCG0EKPgoEBAcCBhIEuwIC
QhowIE9wdGlvbmFsLiBEZXNjcmlwdGlvbiBmb3IgdGhlIGNvbXBhbmlvbiBhZ2VudC4KCg0K
BQQHAgYFEgS7AgIICg0KBQQHAgYBEgS7AgkUCg0KBQQHAgYDEgS7AhcYCg0KBQQHAgYIEgS7
AhlBChAKCAQHAgYInAgAEgS7AhpACsIBCgQEBwIHEgbBAgLCAi8asQEgT3B0aW9uYWwuIExp
c3Qgb2Ygc2tpbGwgY29uZmlncyBmb3IgdGhlIGNvbXBhbmlvbiBhZ2VudC4KIEFsbG93cyBh
dCBtb3N0IG9uZSBpbnN0YW5jZSBvZiBlYWNoCiBbU2tpbGxDb25maWddW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ29tcGFuaW9uQWdlbnQuU2tpbGxDb25maWddCiB0eXBl
LgoKDQoFBAcCBwQSBMECAgoKDQoFBAcCBwYSBMECCxYKDQoFBAcCBwESBMECFyQKDQoFBAcC
BwMSBMECJygKDQoFBAcCBwgSBMICBi4KEAoIBAcCBwicCAASBMICBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest ===
    # Fields for CreateCompanionAgentRequest
    # Field: parent Type: 9 ()
    # Field: companion_agent Type: 11 (.google.cloud.dialogflow.v2beta1.CompanionAgent)
    # Field: companion_agent_id Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::GetCompanionAgentRequest ===
    # Fields for GetCompanionAgentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::ListCompanionAgentsRequest ===
    # Fields for ListCompanionAgentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::ListCompanionAgentsResponse ===
    # Fields for ListCompanionAgentsResponse
    # Field: companion_agents Type: 11 (.google.cloud.dialogflow.v2beta1.CompanionAgent)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::UpdateCompanionAgentRequest ===
    # Fields for UpdateCompanionAgentRequest
    # Field: companion_agent Type: 11 (.google.cloud.dialogflow.v2beta1.CompanionAgent)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::DeleteCompanionAgentRequest ===
    # Fields for DeleteCompanionAgentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::GuidanceInstruction ===
    # Fields for GuidanceInstruction
    # Field: display_name Type: 9 ()
    # Field: display_details Type: 9 ()
    # Field: condition Type: 9 ()
    # Field: actions Type: 11 (.google.cloud.dialogflow.v2beta1.GuidanceInstruction.Action)
    # Field: trigger_event Type: 14 (.google.cloud.dialogflow.v2beta1.CompanionAgent.TriggerEvent)
    # Field: disable_suggested_reply Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent ===
    # Fields for CompanionAgent
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: toolset_tools Type: 11 (.google.cloud.dialogflow.v2beta1.ToolsetTool)
    # Field: ces_tool_specs Type: 11 (.google.cloud.dialogflow.v2beta1.CesToolSpec)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: skill_configs Type: 11 (.google.cloud.dialogflow.v2beta1.CompanionAgent.SkillConfig)

# Enum: CompanionAgent::TriggerEvent
our $CompanionAgent_TRIGGER_EVENT_UNSPECIFIED = 0;
our $CompanionAgent_END_OF_UTTERANCE = 1;
our $CompanionAgent_CUSTOMER_MESSAGE = 2;
our $CompanionAgent_AGENT_MESSAGE = 3;

# === Service Client: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgentsClient ===
package Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgentsClient

Client stub representing the remote C<CompanionAgents> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub create_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.CompanionAgents',
        method         => 'CreateCompanionAgent',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent',
    });
}

sub get_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::CompanionAgent::GetCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.CompanionAgents',
        method         => 'GetCompanionAgent',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent',
    });
}

sub update_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::CompanionAgent::UpdateCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.CompanionAgents',
        method         => 'UpdateCompanionAgent',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent',
    });
}

sub delete_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::CompanionAgent::DeleteCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.CompanionAgents',
        method         => 'DeleteCompanionAgent',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_companion_agents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::CompanionAgent::ListCompanionAgentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.CompanionAgents',
        method         => 'ListCompanionAgents',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::ListCompanionAgentsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::CompanionAgent - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/companion_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::CompanionAgent;

    my $msg = Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest->new({
        parent => $parent,
        companion_agent => $companion_agent,
        companion_agent_id => $companion_agent_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/companion_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest

Request of CreateCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource identifier of the project creating the companion agent.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->companion_agent() >> / C<< $msg->companion_agent($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent>)

Required. The companion agent to create.

=item * C<< $msg->companion_agent_id() >> / C<< $msg->companion_agent_id($value) >>

Type: C<String>

Optional. The resource ID of the companion agent to create. If not
provided, the server will auto-generate a resource ID.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::GetCompanionAgentRequest

Request message for GetCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique resource identifier of the CompanionAgent to get all
information for. Format:
`projects/{project}/locations/{location}/companionAgents/{companion_agent}`.
Contains the information about the project_id, location_id,
companion_agent_id

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::ListCompanionAgentsRequest

Request message for ListCompanionAgents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name to list the companion agents for.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of companion agents to return in a single page.
By default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The page token, received from a previous call.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::ListCompanionAgentsResponse

Response message for ListCompanionAgents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->companion_agents() >> / C<< $msg->companion_agents($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent>)

The list of companion agents.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::UpdateCompanionAgentRequest

Request message for UpdateCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->companion_agent() >> / C<< $msg->companion_agent($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent>)

Required. The Companion Agent to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Update mask for Companion Agent.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::DeleteCompanionAgentRequest

Request message for DeleteCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique resource identifier of the CompanionAgent to delete.
Format:
`projects/{project}/locations/{location}/companionAgents/{companion_agent}`.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::GuidanceInstruction

Guidance instruction for the companion agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name for the instruction. This name should be unique
within the companion agent.

=item * C<< $msg->display_details() >> / C<< $msg->display_details($value) >>

Type: C<String>

Optional. The detailed description of this instruction.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Optional. The condition of the instruction. For example, "the customer
wants to cancel an order".  If the users want the instruction to be
triggered unconditionally, the condition can be empty.

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::GuidanceInstruction::Action>)

Optional. The action items that can be processed.

=item * C<< $msg->trigger_event() >> / C<< $msg->trigger_event($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::TriggerEvent>)

Optional. Event that triggers the guidance instruction.
If UNSPECIFIED, the instruction triggering will be the same as the skill's
skill_triggering_event.

=item * C<< $msg->disable_suggested_reply() >> / C<< $msg->disable_suggested_reply($value) >>

Type: C<Bool>

Optional. Whether to disable suggested reply generation for this
instruction. When set to `true`, guidance generated from this instruction
will not include a suggested reply. Default is `false` (suggested reply
enabled).

=back

=head2 Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent

Companion agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the companion agent.
Format:
`projects/{project}/locations/{location}/companionAgents/{companion_agent}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of this companion agent.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time of this companion agent.

=item * C<< $msg->toolset_tools() >> / C<< $msg->toolset_tools($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Toolset::ToolsetTool>)

Optional. List of CES toolset specs that the companion agent can choose
from.

=item * C<< $msg->ces_tool_specs() >> / C<< $msg->ces_tool_specs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::CesTool::CesToolSpec>)

Optional. List of CES tool specs that the companion agent can choose from.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name for the companion agent.
Character limit is 63.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description for the companion agent.

=item * C<< $msg->skill_configs() >> / C<< $msg->skill_configs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent::SkillConfig>)

Optional. List of skill configs for the companion agent.
Allows at most one instance of each
[SkillConfig][google.cloud.dialogflow.v2beta1.CompanionAgent.SkillConfig]
type.

=back

=head3 Enum: CompanionAgent::TriggerEvent

=over 4

=item * C<TRIGGER_EVENT_UNSPECIFIED> => C<0>

=item * C<END_OF_UTTERANCE> => C<1>

=item * C<CUSTOMER_MESSAGE> => C<2>

=item * C<AGENT_MESSAGE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
