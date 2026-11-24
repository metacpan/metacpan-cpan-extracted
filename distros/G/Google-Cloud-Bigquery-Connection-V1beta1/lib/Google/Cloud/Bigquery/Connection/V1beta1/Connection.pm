package Google::Cloud::Bigquery::Connection::V1beta1::Connection;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvYmlncXVlcnkvY29ubmVjdGlvbi92MWJldGExL2Nvbm5lY3Rpb24u
cHJvdG8SKGdvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gh5nb29nbGUvaWFtL3YxL2lhbV9wb2xpY3kucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5
LnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9m
aWVsZF9tYXNrLnByb3RvGh5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8i4QEKF0Ny
ZWF0ZUNvbm5lY3Rpb25SZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlv
bnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIoCg1jb25uZWN0aW9uX2lkGAIg
ASgJQgPgQQFSDGNvbm5lY3Rpb25JZBJZCgpjb25uZWN0aW9uGAMgASgLMjQuZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LmNvbm5lY3Rpb24udjFiZXRhMS5Db25uZWN0aW9uQgPgQQJSCmNvbm5l
Y3Rpb24iYAoUR2V0Q29ubmVjdGlvblJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixi
aWdxdWVyeWNvbm5lY3Rpb24uZ29vZ2xlYXBpcy5jb20vQ29ubmVjdGlvblIEbmFtZSK+AQoW
TGlzdENvbm5lY3Rpb25zUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9jYXRp
b25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSQgoLbWF4X3Jlc3VsdHMYAiAB
KAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFsdWVCA+BBAlIKbWF4UmVzdWx0cxIdCgpw
YWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4imQEKF0xpc3RDb25uZWN0aW9uc1Jlc3BvbnNl
EiYKD25leHRfcGFnZV90b2tlbhgBIAEoCVINbmV4dFBhZ2VUb2tlbhJWCgtjb25uZWN0aW9u
cxgCIAMoCzI0Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ29u
bmVjdGlvblILY29ubmVjdGlvbnMigAIKF1VwZGF0ZUNvbm5lY3Rpb25SZXF1ZXN0EkgKBG5h
bWUYASABKAlCNOBBAvpBLgosYmlncXVlcnljb25uZWN0aW9uLmdvb2dsZWFwaXMuY29tL0Nv
bm5lY3Rpb25SBG5hbWUSWQoKY29ubmVjdGlvbhgCIAEoCzI0Lmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ29ubmVjdGlvbkID4EECUgpjb25uZWN0aW9uEkAK
C3VwZGF0ZV9tYXNrGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1
cGRhdGVNYXNrIqEBCiFVcGRhdGVDb25uZWN0aW9uQ3JlZGVudGlhbFJlcXVlc3QSFwoEbmFt
ZRgBIAEoCUID4EECUgRuYW1lEmMKCmNyZWRlbnRpYWwYAiABKAsyPi5nb29nbGUuY2xvdWQu
YmlncXVlcnkuY29ubmVjdGlvbi52MWJldGExLkNvbm5lY3Rpb25DcmVkZW50aWFsQgPgQQJS
CmNyZWRlbnRpYWwiYwoXRGVsZXRlQ29ubmVjdGlvblJlcXVlc3QSSAoEbmFtZRgBIAEoCUI0
4EEC+kEuCixiaWdxdWVyeWNvbm5lY3Rpb24uZ29vZ2xlYXBpcy5jb20vQ29ubmVjdGlvblIE
bmFtZSLQAwoKQ29ubmVjdGlvbhISCgRuYW1lGAEgASgJUgRuYW1lEiMKDWZyaWVuZGx5X25h
bWUYAiABKAlSDGZyaWVuZGx5TmFtZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRp
b24SWwoJY2xvdWRfc3FsGAQgASgLMjwuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmNvbm5lY3Rp
b24udjFiZXRhMS5DbG91ZFNxbFByb3BlcnRpZXNIAFIIY2xvdWRTcWwSKAoNY3JlYXRpb25f
dGltZRgFIAEoA0ID4EEDUgxjcmVhdGlvblRpbWUSMQoSbGFzdF9tb2RpZmllZF90aW1lGAYg
ASgDQgPgQQNSEGxhc3RNb2RpZmllZFRpbWUSKgoOaGFzX2NyZWRlbnRpYWwYByABKAhCA+BB
A1INaGFzQ3JlZGVudGlhbDpz6kFwCixiaWdxdWVyeWNvbm5lY3Rpb24uZ29vZ2xlYXBpcy5j
b20vQ29ubmVjdGlvbhJAcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2Nvbm5lY3Rpb25zL3tjb25uZWN0aW9ufUIMCgpwcm9wZXJ0aWVzIoEBChRDb25uZWN0aW9u
Q3JlZGVudGlhbBJbCgljbG91ZF9zcWwYASABKAsyPC5nb29nbGUuY2xvdWQuYmlncXVlcnku
Y29ubmVjdGlvbi52MWJldGExLkNsb3VkU3FsQ3JlZGVudGlhbEgAUghjbG91ZFNxbEIMCgpj
cmVkZW50aWFsIo4DChJDbG91ZFNxbFByb3BlcnRpZXMSHwoLaW5zdGFuY2VfaWQYASABKAlS
Cmluc3RhbmNlSWQSGgoIZGF0YWJhc2UYAiABKAlSCGRhdGFiYXNlEl0KBHR5cGUYAyABKA4y
SS5nb29nbGUuY2xvdWQuYmlncXVlcnkuY29ubmVjdGlvbi52MWJldGExLkNsb3VkU3FsUHJv
cGVydGllcy5EYXRhYmFzZVR5cGVSBHR5cGUSYQoKY3JlZGVudGlhbBgEIAEoCzI8Lmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ2xvdWRTcWxDcmVkZW50aWFs
QgPgQQRSCmNyZWRlbnRpYWwSMQoSc2VydmljZV9hY2NvdW50X2lkGAUgASgJQgPgQQNSEHNl
cnZpY2VBY2NvdW50SWQiRgoMRGF0YWJhc2VUeXBlEh0KGURBVEFCQVNFX1RZUEVfVU5TUEVD
SUZJRUQQABIMCghQT1NUR1JFUxABEgkKBU1ZU1FMEAIiTAoSQ2xvdWRTcWxDcmVkZW50aWFs
EhoKCHVzZXJuYW1lGAEgASgJUgh1c2VybmFtZRIaCghwYXNzd29yZBgCIAEoCVIIcGFzc3dv
cmQymBAKEUNvbm5lY3Rpb25TZXJ2aWNlEvcBChBDcmVhdGVDb25uZWN0aW9uEkEuZ29vZ2xl
LmNsb3VkLmJpZ3F1ZXJ5LmNvbm5lY3Rpb24udjFiZXRhMS5DcmVhdGVDb25uZWN0aW9uUmVx
dWVzdBo0Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ29ubmVj
dGlvbiJqgtPkkwJCIjQvdjFiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
L2Nvbm5lY3Rpb25zOgpjb25uZWN0aW9u2kEfcGFyZW50LGNvbm5lY3Rpb24sY29ubmVjdGlv
bl9pZBLKAQoNR2V0Q29ubmVjdGlvbhI+Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0
aW9uLnYxYmV0YTEuR2V0Q29ubmVjdGlvblJlcXVlc3QaNC5nb29nbGUuY2xvdWQuYmlncXVl
cnkuY29ubmVjdGlvbi52MWJldGExLkNvbm5lY3Rpb24iQ4LT5JMCNhI0L3YxYmV0YTEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0aW9ucy8qfdpBBG5hbWUS6QEKD0xp
c3RDb25uZWN0aW9ucxJALmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0
YTEuTGlzdENvbm5lY3Rpb25zUmVxdWVzdBpBLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25u
ZWN0aW9uLnYxYmV0YTEuTGlzdENvbm5lY3Rpb25zUmVzcG9uc2UiUYLT5JMCNhI0L3YxYmV0
YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jb25uZWN0aW9uc9pBEnBhcmVu
dCxtYXhfcmVzdWx0cxLzAQoQVXBkYXRlQ29ubmVjdGlvbhJBLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuVXBkYXRlQ29ubmVjdGlvblJlcXVlc3QaNC5nb29n
bGUuY2xvdWQuYmlncXVlcnkuY29ubmVjdGlvbi52MWJldGExLkNvbm5lY3Rpb24iZoLT5JMC
QjI0L3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0aW9ucy8q
fToKY29ubmVjdGlvbtpBG25hbWUsY29ubmVjdGlvbix1cGRhdGVfbWFzaxLoAQoaVXBkYXRl
Q29ubmVjdGlvbkNyZWRlbnRpYWwSSy5nb29nbGUuY2xvdWQuYmlncXVlcnkuY29ubmVjdGlv
bi52MWJldGExLlVwZGF0ZUNvbm5lY3Rpb25DcmVkZW50aWFsUmVxdWVzdBoWLmdvb2dsZS5w
cm90b2J1Zi5FbXB0eSJlgtPkkwJNMj8vdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2Nvbm5lY3Rpb25zLyovY3JlZGVudGlhbH06CmNyZWRlbnRpYWzaQQ9uYW1lLGNy
ZWRlbnRpYWwSsgEKEERlbGV0ZUNvbm5lY3Rpb24SQS5nb29nbGUuY2xvdWQuYmlncXVlcnku
Y29ubmVjdGlvbi52MWJldGExLkRlbGV0ZUNvbm5lY3Rpb25SZXF1ZXN0GhYuZ29vZ2xlLnBy
b3RvYnVmLkVtcHR5IkOC0+STAjYqNC92MWJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovY29ubmVjdGlvbnMvKn3aQQRuYW1lEq4BCgxHZXRJYW1Qb2xpY3kSIi5nb29nbGUu
aWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGljeSJjgtPk
kwJKIkUvdjFiZXRhMS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0
aW9ucy8qfTpnZXRJYW1Qb2xpY3k6ASraQRByZXNvdXJjZSxvcHRpb25zEq0BCgxTZXRJYW1Q
b2xpY3kSIi5nb29nbGUuaWFtLnYxLlNldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFt
LnYxLlBvbGljeSJigtPkkwJKIkUvdjFiZXRhMS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb25uZWN0aW9ucy8qfTpzZXRJYW1Qb2xpY3k6ASraQQ9yZXNvdXJjZSxwb2xp
Y3kS2AEKElRlc3RJYW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1p
c3Npb25zUmVxdWVzdBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9u
c2UibYLT5JMCUCJLL3YxYmV0YTEve3Jlc291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyov
Y29ubmVjdGlvbnMvKn06dGVzdElhbVBlcm1pc3Npb25zOgEq2kEUcmVzb3VyY2UscGVybWlz
c2lvbnMafspBIWJpZ3F1ZXJ5Y29ubmVjdGlvbi5nb29nbGVhcGlzLmNvbdJBV2h0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvYmlncXVlcnksaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULjAQosY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVy
eS5jb25uZWN0aW9uLnYxYmV0YTFCD0Nvbm5lY3Rpb25Qcm90b1pMY2xvdWQuZ29vZ2xlLmNv
bS9nby9iaWdxdWVyeS9jb25uZWN0aW9uL2FwaXYxYmV0YTEvY29ubmVjdGlvbnBiO2Nvbm5l
Y3Rpb25wYqoCKEdvb2dsZS5DbG91ZC5CaWdRdWVyeS5Db25uZWN0aW9uLlYxQmV0YTHKAihH
b29nbGVcQ2xvdWRcQmlnUXVlcnlcQ29ubmVjdGlvblxWMWJldGExSppLCgcSBQ4AyAIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAxCgkKAgMAEgMSACYK
CQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAKAoJCgIDBRIDFwAk
CgkKAgMGEgMYACUKCQoCAwcSAxkAKgoJCgIDCBIDGgAoCggKAQgSAxwARQoJCgIIJRIDHABF
CggKAQgSAx0AYwoJCgIICxIDHQBjCggKAQgSAx4AMAoJCgIICBIDHgAwCggKAQgSAx8ARQoJ
CgIIARIDHwBFCggKAQgSAyAARgoJCgIIKRIDIABGCkgKAgYAEgUjAIgBARo7IE1hbmFnZXMg
ZXh0ZXJuYWwgZGF0YSBzb3VyY2UgY29ubmVjdGlvbnMgYW5kIGNyZWRlbnRpYWxzLgoKCgoD
BgABEgMjCBkKCgoDBgADEgMkAkkKDAoFBgADmQgSAyQCSQoLCgMGAAMSBCUCJzcKDQoFBgAD
mggSBCUCJzcKKQoEBgACABIEKgIwAxobIENyZWF0ZXMgYSBuZXcgY29ubmVjdGlvbi4KCgwK
BQYAAgABEgMqBhYKDAoFBgACAAISAyoXLgoMCgUGAAIAAxIDKjlDCg0KBQYAAgAEEgQrBC4G
ChEKCQYAAgAEsMq8IhIEKwQuBgoMCgUGAAIABBIDLwRNCg8KCAYAAgAEmwgAEgMvBE0KLQoE
BgACARIEMwI4AxofIFJldHVybnMgc3BlY2lmaWVkIGNvbm5lY3Rpb24uCgoMCgUGAAIBARID
MwYTCgwKBQYAAgECEgMzFCgKDAoFBgACAQMSAzMzPQoNCgUGAAIBBBIENAQ2BgoRCgkGAAIB
BLDKvCISBDQENgYKDAoFBgACAQQSAzcEMgoPCggGAAIBBJsIABIDNwQyCkMKBAYAAgISBDsC
QQMaNSBSZXR1cm5zIGEgbGlzdCBvZiBjb25uZWN0aW9ucyBpbiB0aGUgZ2l2ZW4gcHJvamVj
dC4KCgwKBQYAAgIBEgM7BhUKDAoFBgACAgISAzsWLAoMCgUGAAICAxIDPA8mCg0KBQYAAgIE
EgQ9BD8GChEKCQYAAgIEsMq8IhIEPQQ/BgoMCgUGAAICBBIDQARACg8KCAYAAgIEmwgAEgNA
BEAKlwEKBAYAAgMSBEUCSwMaiAEgVXBkYXRlcyB0aGUgc3BlY2lmaWVkIGNvbm5lY3Rpb24u
IEZvciBzZWN1cml0eSByZWFzb25zLCBhbHNvIHJlc2V0cwogY3JlZGVudGlhbCBpZiBjb25u
ZWN0aW9uIHByb3BlcnRpZXMgYXJlIGluIHRoZSB1cGRhdGUgZmllbGQgbWFzay4KCgwKBQYA
AgMBEgNFBhYKDAoFBgACAwISA0UXLgoMCgUGAAIDAxIDRTlDCg0KBQYAAgMEEgRGBEkGChEK
CQYAAgMEsMq8IhIERgRJBgoMCgUGAAIDBBIDSgRJCg8KCAYAAgMEmwgAEgNKBEkKQQoEBgAC
BBIETgJVAxozIFNldHMgdGhlIGNyZWRlbnRpYWwgZm9yIHRoZSBzcGVjaWZpZWQgY29ubmVj
dGlvbi4KCgwKBQYAAgQBEgNOBiAKDAoFBgACBAISA04hQgoMCgUGAAIEAxIDTw8kCg0KBQYA
AgQEEgRQBFMGChEKCQYAAgQEsMq8IhIEUARTBgoMCgUGAAIEBBIDVAQ9Cg8KCAYAAgQEmwgA
EgNUBD0KPQoEBgACBRIEWAJeAxovIERlbGV0ZXMgY29ubmVjdGlvbiBhbmQgYXNzb2NpYXRl
ZCBjcmVkZW50aWFsLgoKDAoFBgACBQESA1gGFgoMCgUGAAIFAhIDWBcuCgwKBQYAAgUDEgNZ
DyQKDQoFBgACBQQSBFoEXAYKEQoJBgACBQSwyrwiEgRaBFwGCgwKBQYAAgUEEgNdBDIKDwoI
BgACBQSbCAASA10EMgqQAQoEBgACBhIEYwJqAxqBASBHZXRzIHRoZSBhY2Nlc3MgY29udHJv
bCBwb2xpY3kgZm9yIGEgcmVzb3VyY2UuCiBSZXR1cm5zIGFuIGVtcHR5IHBvbGljeSBpZiB0
aGUgcmVzb3VyY2UgZXhpc3RzIGFuZCBkb2VzIG5vdCBoYXZlIGEgcG9saWN5CiBzZXQuCgoM
CgUGAAIGARIDYwYSCgwKBQYAAgYCEgNjEzQKDAoFBgACBgMSA2QPIwoNCgUGAAIGBBIEZQRo
BgoRCgkGAAIGBLDKvCISBGUEaAYKDAoFBgACBgQSA2kEPgoPCggGAAIGBJsIABIDaQQ+CrcB
CgQGAAIHEgRwAncDGqgBIFNldHMgdGhlIGFjY2VzcyBjb250cm9sIHBvbGljeSBvbiB0aGUg
c3BlY2lmaWVkIHJlc291cmNlLiBSZXBsYWNlcyBhbnkKIGV4aXN0aW5nIHBvbGljeS4KCiBD
YW4gcmV0dXJuIGBOT1RfRk9VTkRgLCBgSU5WQUxJRF9BUkdVTUVOVGAsIGFuZCBgUEVSTUlT
U0lPTl9ERU5JRURgIGVycm9ycy4KCgwKBQYAAgcBEgNwBhIKDAoFBgACBwISA3ATNAoMCgUG
AAIHAxIDcQ8jCg0KBQYAAgcEEgRyBHUGChEKCQYAAgcEsMq8IhIEcgR1BgoMCgUGAAIHBBID
dgQ9Cg8KCAYAAgcEmwgAEgN2BD0K9gIKBAYAAggSBoABAocBAxrlAiBSZXR1cm5zIHBlcm1p
c3Npb25zIHRoYXQgYSBjYWxsZXIgaGFzIG9uIHRoZSBzcGVjaWZpZWQgcmVzb3VyY2UuCiBJ
ZiB0aGUgcmVzb3VyY2UgZG9lcyBub3QgZXhpc3QsIHRoaXMgd2lsbCByZXR1cm4gYW4gZW1w
dHkgc2V0IG9mCiBwZXJtaXNzaW9ucywgbm90IGEgYE5PVF9GT1VORGAgZXJyb3IuCgogTm90
ZTogVGhpcyBvcGVyYXRpb24gaXMgZGVzaWduZWQgdG8gYmUgdXNlZCBmb3IgYnVpbGRpbmcg
cGVybWlzc2lvbi1hd2FyZQogVUlzIGFuZCBjb21tYW5kLWxpbmUgdG9vbHMsIG5vdCBmb3Ig
YXV0aG9yaXphdGlvbiBjaGVja2luZy4gVGhpcyBvcGVyYXRpb24KIG1heSAiZmFpbCBvcGVu
IiB3aXRob3V0IHdhcm5pbmcuCgoNCgUGAAIIARIEgAEGGAoNCgUGAAIIAhIEgAEZQAoNCgUG
AAIIAxIEgQEPNwoPCgUGAAIIBBIGggEEhQEGChMKCQYAAggEsMq8IhIGggEEhQEGCg0KBQYA
AggEEgSGAQRCChAKCAYAAggEmwgAEgSGAQRCCpQBCgIEABIGjAEAmwEBGoUBIFRoZSByZXF1
ZXN0IGZvcgogW0Nvbm5lY3Rpb25TZXJ2aWNlLkNyZWF0ZUNvbm5lY3Rpb25dW2dvb2dsZS5j
bG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ29ubmVjdGlvblNlcnZpY2UuQ3Jl
YXRlQ29ubmVjdGlvbl0uCgoLCgMEAAESBIwBCB8KeAoEBAACABIGjwEClAEEGmggUmVxdWly
ZWQuIFBhcmVudCByZXNvdXJjZSBuYW1lLgogTXVzdCBiZSBpbiB0aGUgZm9ybWF0IGBwcm9q
ZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH1gCgoNCgUEAAIABRIE
jwECCAoNCgUEAAIAARIEjwEJDwoNCgUEAAIAAxIEjwESEwoPCgUEAAIACBIGjwEUlAEDChAK
CAQAAgAInAgAEgSQAQQqChEKBwQAAgAInwgSBpEBBJMBBQpaCgQEAAIBEgSXAQJEGkwgT3B0
aW9uYWwuIENvbm5lY3Rpb24gaWQgdGhhdCBzaG91bGQgYmUgYXNzaWduZWQgdG8gdGhlIGNy
ZWF0ZWQgY29ubmVjdGlvbi4KCg0KBQQAAgEFEgSXAQIICg0KBQQAAgEBEgSXAQkWCg0KBQQA
AgEDEgSXARkaCg0KBQQAAgEIEgSXARtDChAKCAQAAgEInAgAEgSXARxCCi8KBAQAAgISBJoB
AkUaISBSZXF1aXJlZC4gQ29ubmVjdGlvbiB0byBjcmVhdGUuCgoNCgUEAAICBhIEmgECDAoN
CgUEAAICARIEmgENFwoNCgUEAAICAxIEmgEaGwoNCgUEAAICCBIEmgEcRAoQCggEAAICCJwI
ABIEmgEdQwqNAQoCBAESBp8BAKgBARp/IFRoZSByZXF1ZXN0IGZvcgogW0Nvbm5lY3Rpb25T
ZXJ2aWNlLkdldENvbm5lY3Rpb25dW2dvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9u
LnYxYmV0YTEuQ29ubmVjdGlvblNlcnZpY2UuR2V0Q29ubmVjdGlvbl0uCgoLCgMEAQESBJ8B
CBwKmAEKBAQBAgASBqIBAqcBBBqHASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVxdWVzdGVk
IGNvbm5lY3Rpb24sIGZvciBleGFtcGxlOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9uX2lkfS9jb25uZWN0aW9ucy97Y29ubmVjdGlvbl9pZH1gCgoNCgUE
AQIABRIEogECCAoNCgUEAQIAARIEogEJDQoNCgUEAQIAAxIEogEQEQoPCgUEAQIACBIGogES
pwEDChAKCAQBAgAInAgAEgSjAQQqChEKBwQBAgAInwgSBqQBBKYBBQqSAQoCBAISBqwBALwB
ARqDASBUaGUgcmVxdWVzdCBmb3IKIFtDb25uZWN0aW9uU2VydmljZS5MaXN0Q29ubmVjdGlv
bnNdW2dvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ29ubmVjdGlv
blNlcnZpY2UuTGlzdENvbm5lY3Rpb25zXS4KCgsKAwQCARIErAEIHgp3CgQEAgIAEgavAQK0
AQQaZyBSZXF1aXJlZC4gUGFyZW50IHJlc291cmNlIG5hbWUuCiBNdXN0IGJlIGluIHRoZSBm
b3JtOiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9YAoK
DQoFBAICAAUSBK8BAggKDQoFBAICAAESBK8BCQ8KDQoFBAICAAMSBK8BEhMKDwoFBAICAAgS
Bq8BFLQBAwoQCggEAgIACJwIABIEsAEEKgoRCgcEAgIACJ8IEgaxAQSzAQUKPwoEBAICARIG
twECuAEvGi8gUmVxdWlyZWQuIE1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgcGVyIHBhZ2Uu
CgoNCgUEAgIBBhIEtwECHQoNCgUEAgIBARIEtwEeKQoNCgUEAgIBAxIEtwEsLQoNCgUEAgIB
CBIEuAEGLgoQCggEAgIBCJwIABIEuAEHLQobCgQEAgICEgS7AQIYGg0gUGFnZSB0b2tlbi4K
Cg0KBQQCAgIFEgS7AQIICg0KBQQCAgIBEgS7AQkTCg0KBQQCAgIDEgS7ARYXCpMBCgIEAxIG
wAEAxgEBGoQBIFRoZSByZXNwb25zZSBmb3IKIFtDb25uZWN0aW9uU2VydmljZS5MaXN0Q29u
bmVjdGlvbnNdW2dvb2dsZS5jbG91ZC5iaWdxdWVyeS5jb25uZWN0aW9uLnYxYmV0YTEuQ29u
bmVjdGlvblNlcnZpY2UuTGlzdENvbm5lY3Rpb25zXS4KCgsKAwQDARIEwAEIHwogCgQEAwIA
EgTCAQIdGhIgTmV4dCBwYWdlIHRva2VuLgoKDQoFBAMCAAUSBMIBAggKDQoFBAMCAAESBMIB
CRgKDQoFBAMCAAMSBMIBGxwKJAoEBAMCARIExQECJhoWIExpc3Qgb2YgY29ubmVjdGlvbnMu
CgoNCgUEAwIBBBIExQECCgoNCgUEAwIBBhIExQELFQoNCgUEAwIBARIExQEWIQoNCgUEAwIB
AxIExQEkJQqUAQoCBAQSBsoBANoBARqFASBUaGUgcmVxdWVzdCBmb3IKIFtDb25uZWN0aW9u
U2VydmljZS5VcGRhdGVDb25uZWN0aW9uXVtnb29nbGUuY2xvdWQuYmlncXVlcnkuY29ubmVj
dGlvbi52MWJldGExLkNvbm5lY3Rpb25TZXJ2aWNlLlVwZGF0ZUNvbm5lY3Rpb25dLgoKCwoD
BAQBEgTKAQgfCpgBCgQEBAIAEgbNAQLSAQQahwEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGNv
bm5lY3Rpb24gdG8gdXBkYXRlLCBmb3IgZXhhbXBsZToKIGBwcm9qZWN0cy97cHJvamVjdF9p
ZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY29ubmVjdGlvbnMve2Nvbm5lY3Rpb25faWR9
YAoKDQoFBAQCAAUSBM0BAggKDQoFBAQCAAESBM0BCQ0KDQoFBAQCAAMSBM0BEBEKDwoFBAQC
AAgSBs0BEtIBAwoQCggEBAIACJwIABIEzgEEKgoRCgcEBAIACJ8IEgbPAQTRAQUKQwoEBAQC
ARIE1QECRRo1IFJlcXVpcmVkLiBDb25uZWN0aW9uIGNvbnRhaW5pbmcgdGhlIHVwZGF0ZWQg
ZmllbGRzLgoKDQoFBAQCAQYSBNUBAgwKDQoFBAQCAQESBNUBDRcKDQoFBAQCAQMSBNUBGhsK
DQoFBAQCAQgSBNUBHEQKEAoIBAQCAQicCAASBNUBHUMKUAoEBAQCAhIG2AEC2QEvGkAgUmVx
dWlyZWQuIFVwZGF0ZSBtYXNrIGZvciB0aGUgY29ubmVjdGlvbiBmaWVsZHMgdG8gYmUgdXBk
YXRlZC4KCg0KBQQEAgIGEgTYAQIbCg0KBQQEAgIBEgTYARwnCg0KBQQEAgIDEgTYASorCg0K
BQQEAgIIEgTZAQYuChAKCAQEAgIInAgAEgTZAQctCqgBCgIEBRIG3gEA5QEBGpkBIFRoZSBy
ZXF1ZXN0IGZvcgogW0Nvbm5lY3Rpb25TZXJ2aWNlLlVwZGF0ZUNvbm5lY3Rpb25DcmVkZW50
aWFsXVtnb29nbGUuY2xvdWQuYmlncXVlcnkuY29ubmVjdGlvbi52MWJldGExLkNvbm5lY3Rp
b25TZXJ2aWNlLlVwZGF0ZUNvbm5lY3Rpb25DcmVkZW50aWFsXS4KCgsKAwQFARIE3gEIKQqX
AQoEBAUCABIE4QECOxqIASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgY29ubmVjdGlvbiwgZm9y
IGV4YW1wbGU6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25f
aWR9L2Nvbm5lY3Rpb25zL3tjb25uZWN0aW9uX2lkfS9jcmVkZW50aWFsYAoKDQoFBAUCAAUS
BOEBAggKDQoFBAUCAAESBOEBCQ0KDQoFBAUCAAMSBOEBEBEKDQoFBAUCAAgSBOEBEjoKEAoI
BAUCAAicCAASBOEBEzkKQAoEBAUCARIE5AECTxoyIFJlcXVpcmVkLiBDcmVkZW50aWFsIHRv
IHVzZSB3aXRoIHRoZSBjb25uZWN0aW9uLgoKDQoFBAUCAQYSBOQBAhYKDQoFBAUCAQESBOQB
FyEKDQoFBAUCAQMSBOQBJCUKDQoFBAUCAQgSBOQBJk4KEAoIBAUCAQicCAASBOQBJ00KTgoC
BAYSBugBAPEBARpAIFRoZSByZXF1ZXN0IGZvciBbQ29ubmVjdGlvblNlcnZpY2UuRGVsZXRl
Q29ubmVjdGlvblJlcXVlc3RdW10uCgoLCgMEBgESBOgBCB8KlgEKBAQGAgASBusBAvABBBqF
ASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgZGVsZXRlZCBjb25uZWN0aW9uLCBmb3IgZXhhbXBs
ZToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY29u
bmVjdGlvbnMve2Nvbm5lY3Rpb25faWR9YAoKDQoFBAYCAAUSBOsBAggKDQoFBAYCAAESBOsB
CQ0KDQoFBAYCAAMSBOsBEBEKDwoFBAYCAAgSBusBEvABAwoQCggEBgIACJwIABIE7AEEKgoR
CgcEBgIACJ8IEgbtAQTvAQUKgQEKAgQHEgb1AQCTAgEacyBDb25maWd1cmF0aW9uIHBhcmFt
ZXRlcnMgdG8gZXN0YWJsaXNoIGNvbm5lY3Rpb24gd2l0aCBhbiBleHRlcm5hbCBkYXRhCiBz
b3VyY2UsIGV4Y2VwdCB0aGUgY3JlZGVudGlhbCBhdHRyaWJ1dGVzLgoKCwoDBAcBEgT1AQgS
Cg0KAwQHBxIG9gEC+QEECg8KBQQHB50IEgb2AQL5AQQKkQEKBAQHAgASBP0BAhIaggEgVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIGNvbm5lY3Rpb24gaW4gdGhlIGZvcm0gb2Y6CiBgcHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2Nvbm5lY3Rpb25z
L3tjb25uZWN0aW9uX2lkfWAKCg0KBQQHAgAFEgT9AQIICg0KBQQHAgABEgT9AQkNCg0KBQQH
AgADEgT9ARARCj4KBAQHAgESBIACAhsaMCBVc2VyIHByb3ZpZGVkIGRpc3BsYXkgbmFtZSBm
b3IgdGhlIGNvbm5lY3Rpb24uCgoNCgUEBwIBBRIEgAICCAoNCgUEBwIBARIEgAIJFgoNCgUE
BwIBAxIEgAIZGgoqCgQEBwICEgSDAgIZGhwgVXNlciBwcm92aWRlZCBkZXNjcmlwdGlvbi4K
Cg0KBQQHAgIFEgSDAgIICg0KBQQHAgIBEgSDAgkUCg0KBQQHAgIDEgSDAhcYCkQKBAQHCAAS
BoYCAokCAxo0IFByb3BlcnRpZXMgc3BlY2lmaWMgdG8gdGhlIHVuZGVybHlpbmcgZGF0YSBz
b3VyY2UuCgoNCgUEBwgAARIEhgIIEgolCgQEBwIDEgSIAgQlGhcgQ2xvdWQgU1FMIHByb3Bl
cnRpZXMuCgoNCgUEBwIDBhIEiAIEFgoNCgUEBwIDARIEiAIXIAoNCgUEBwIDAxIEiAIjJApG
CgQEBwIEEgSMAgJGGjggT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGlvbiB0aW1lc3RhbXAgb2Yg
dGhlIGNvbm5lY3Rpb24uCgoNCgUEBwIEBRIEjAICBwoNCgUEBwIEARIEjAIIFQoNCgUEBwIE
AxIEjAIYGQoNCgUEBwIECBIEjAIaRQoQCggEBwIECJwIABIEjAIbRApJCgQEBwIFEgSPAgJL
GjsgT3V0cHV0IG9ubHkuIFRoZSBsYXN0IHVwZGF0ZSB0aW1lc3RhbXAgb2YgdGhlIGNvbm5l
Y3Rpb24uCgoNCgUEBwIFBRIEjwICBwoNCgUEBwIFARIEjwIIGgoNCgUEBwIFAxIEjwIdHgoN
CgUEBwIFCBIEjwIfSgoQCggEBwIFCJwIABIEjwIgSQpTCgQEBwIGEgSSAgJGGkUgT3V0cHV0
IG9ubHkuIFRydWUsIGlmIGNyZWRlbnRpYWwgaXMgY29uZmlndXJlZCBmb3IgdGhpcyBjb25u
ZWN0aW9uLgoKDQoFBAcCBgUSBJICAgYKDQoFBAcCBgESBJICBxUKDQoFBAcCBgMSBJICGBkK
DQoFBAcCBggSBJICGkUKEAoIBAcCBgicCAASBJICG0QKNAoCBAgSBpYCAJwCARomIENyZWRl
bnRpYWwgdG8gdXNlIHdpdGggYSBjb25uZWN0aW9uLgoKCwoDBAgBEgSWAggcCkQKBAQICAAS
BpgCApsCAxo0IENyZWRlbnRpYWwgc3BlY2lmaWMgdG8gdGhlIHVuZGVybHlpbmcgZGF0YSBz
b3VyY2UuCgoNCgUECAgAARIEmAIIEgoyCgQECAIAEgSaAgQlGiQgQ3JlZGVudGlhbCBmb3Ig
Q2xvdWQgU1FMIGRhdGFiYXNlLgoKDQoFBAgCAAYSBJoCBBYKDQoFBAgCAAESBJoCFyAKDQoF
BAgCAAMSBJoCIyQKQAoCBAkSBp8CAL8CARoyIENvbm5lY3Rpb24gcHJvcGVydGllcyBzcGVj
aWZpYyB0byB0aGUgQ2xvdWQgU1FMLgoKCwoDBAkBEgSfAggaCjUKBAQJBAASBqECAqoCAxol
IFN1cHBvcnRlZCBDbG91ZCBTUUwgZGF0YWJhc2UgdHlwZXMuCgoNCgUECQQAARIEoQIHEwos
CgYECQQAAgASBKMCBCIaHCBVbnNwZWNpZmllZCBkYXRhYmFzZSB0eXBlLgoKDwoHBAkEAAIA
ARIEowIEHQoPCgcECQQAAgACEgSjAiAhCisKBgQJBAACARIEpgIEERobIENsb3VkIFNRTCBm
b3IgUG9zdGdyZVNRTC4KCg8KBwQJBAACAQESBKYCBAwKDwoHBAkEAAIBAhIEpgIPEAomCgYE
CQQAAgISBKkCBA4aFiBDbG91ZCBTUUwgZm9yIE15U1FMLgoKDwoHBAkEAAICARIEqQIECQoP
CgcECQQAAgICEgSpAgwNCk4KBAQJAgASBK0CAhkaQCBDbG91ZCBTUUwgaW5zdGFuY2UgSUQg
aW4gdGhlIGZvcm0gYHByb2plY3Q6bG9jYXRpb246aW5zdGFuY2VgLgoKDQoFBAkCAAUSBK0C
AggKDQoFBAkCAAESBK0CCRQKDQoFBAkCAAMSBK0CFxgKHgoEBAkCARIEsAICFhoQIERhdGFi
YXNlIG5hbWUuCgoNCgUECQIBBRIEsAICCAoNCgUECQIBARIEsAIJEQoNCgUECQIBAxIEsAIU
FQovCgQECQICEgSzAgIYGiEgVHlwZSBvZiB0aGUgQ2xvdWQgU1FMIGRhdGFiYXNlLgoKDQoF
BAkCAgYSBLMCAg4KDQoFBAkCAgESBLMCDxMKDQoFBAkCAgMSBLMCFhcKMQoEBAkCAxIEtgIC
TxojIElucHV0IG9ubHkuIENsb3VkIFNRTCBjcmVkZW50aWFsLgoKDQoFBAkCAwYSBLYCAhQK
DQoFBAkCAwESBLYCFR8KDQoFBAkCAwMSBLYCIiMKDQoFBAkCAwgSBLYCJE4KEAoIBAkCAwic
CAASBLYCJU0KsgIKBAQJAgQSBL4CAkwaowIgT3V0cHV0IG9ubHkuIFRoZSBhY2NvdW50IElE
IG9mIHRoZSBzZXJ2aWNlIHVzZWQgZm9yIHRoZSBwdXJwb3NlIG9mIHRoaXMKIGNvbm5lY3Rp
b24uCgogV2hlbiB0aGUgY29ubmVjdGlvbiBpcyB1c2VkIGluIHRoZSBjb250ZXh0IG9mIGFu
IG9wZXJhdGlvbiBpbgogQmlnUXVlcnksIHRoaXMgc2VydmljZSBhY2NvdW50IHdpbGwgc2Vy
dmUgYXMgdGhlIGlkZW50aXR5IGJlaW5nIHVzZWQgZm9yCiBjb25uZWN0aW5nIHRvIHRoZSBD
bG91ZFNRTCBpbnN0YW5jZSBzcGVjaWZpZWQgaW4gdGhpcyBjb25uZWN0aW9uLgoKDQoFBAkC
BAUSBL4CAggKDQoFBAkCBAESBL4CCRsKDQoFBAkCBAMSBL4CHh8KDQoFBAkCBAgSBL4CIEsK
EAoIBAkCBAicCAASBL4CIUoKMgoCBAoSBsICAMgCARokIENyZWRlbnRpYWwgaW5mbyBmb3Ig
dGhlIENsb3VkIFNRTC4KCgsKAwQKARIEwgIIGgowCgQECgIAEgTEAgIWGiIgVGhlIHVzZXJu
YW1lIGZvciB0aGUgY3JlZGVudGlhbC4KCg0KBQQKAgAFEgTEAgIICg0KBQQKAgABEgTEAgkR
Cg0KBQQKAgADEgTEAhQVCjAKBAQKAgESBMcCAhYaIiBUaGUgcGFzc3dvcmQgZm9yIHRoZSBj
cmVkZW50aWFsLgoKDQoFBAoCAQUSBMcCAggKDQoFBAoCAQESBMcCCREKDQoFBAoCAQMSBMcC
FBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest ===
    # Fields for CreateConnectionRequest
    # Field: parent Type: 9 ()
    # Field: connection_id Type: 9 ()
    # Field: connection Type: 11 (.google.cloud.bigquery.connection.v1beta1.Connection)

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::GetConnectionRequest ===
    # Fields for GetConnectionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsRequest ===
    # Fields for ListConnectionsRequest
    # Field: parent Type: 9 ()
    # Field: max_results Type: 11 (.google.protobuf.UInt32Value)
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsResponse ===
    # Fields for ListConnectionsResponse
    # Field: next_page_token Type: 9 ()
    # Field: connections Type: 11 (.google.cloud.bigquery.connection.v1beta1.Connection)

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionRequest ===
    # Fields for UpdateConnectionRequest
    # Field: name Type: 9 ()
    # Field: connection Type: 11 (.google.cloud.bigquery.connection.v1beta1.Connection)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionCredentialRequest ===
    # Fields for UpdateConnectionCredentialRequest
    # Field: name Type: 9 ()
    # Field: credential Type: 11 (.google.cloud.bigquery.connection.v1beta1.ConnectionCredential)

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::DeleteConnectionRequest ===
    # Fields for DeleteConnectionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection ===
    # Fields for Connection
    # Field: name Type: 9 ()
    # Field: friendly_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: cloud_sql Type: 11 (.google.cloud.bigquery.connection.v1beta1.CloudSqlProperties)
    # Field: creation_time Type: 3 ()
    # Field: last_modified_time Type: 3 ()
    # Field: has_credential Type: 8 ()

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionCredential ===
    # Fields for ConnectionCredential
    # Field: cloud_sql Type: 11 (.google.cloud.bigquery.connection.v1beta1.CloudSqlCredential)

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlProperties ===
    # Fields for CloudSqlProperties
    # Field: instance_id Type: 9 ()
    # Field: database Type: 9 ()
    # Field: type Type: 14 (.google.cloud.bigquery.connection.v1beta1.CloudSqlProperties.DatabaseType)
    # Field: credential Type: 11 (.google.cloud.bigquery.connection.v1beta1.CloudSqlCredential)
    # Field: service_account_id Type: 9 ()

# Enum: CloudSqlProperties::DatabaseType
our $CloudSqlProperties_DATABASE_TYPE_UNSPECIFIED = 0;
our $CloudSqlProperties_POSTGRES = 1;
our $CloudSqlProperties_MYSQL = 2;

# === Message: Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential ===
    # Fields for CloudSqlCredential
    # Field: username Type: 9 ()
    # Field: password Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionServiceClient ===
package Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionServiceClient

Client stub representing the remote C<ConnectionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'CreateConnection',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection',
    });
}

sub get_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Connection::V1beta1::Connection::GetConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'GetConnection',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection',
    });
}

sub list_connections {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'ListConnections',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsResponse',
    });
}

sub update_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'UpdateConnection',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection',
    });
}

sub update_connection_credential {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionCredentialRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'UpdateConnectionCredential',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub delete_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Connection::V1beta1::Connection::DeleteConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'DeleteConnection',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.connection.v1beta1.ConnectionService',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Connection::V1beta1::Connection - Compiled Protocol Buffers messages for google/cloud/bigquery/connection/v1beta1/connection.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Connection::V1beta1::Connection;

    my $msg = Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest->new({
        parent => $parent,
        connection_id => $connection_id,
        connection => $connection,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/connection/v1beta1/connection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest

The request for
[ConnectionService.CreateConnection][google.cloud.bigquery.connection.v1beta1.ConnectionService.CreateConnection].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource name.
Must be in the format `projects/{project_id}/locations/{location_id}`

=item * C<< $msg->connection_id() >> / C<< $msg->connection_id($value) >>

Type: C<String>

Optional. Connection id that should be assigned to the created connection.

=item * C<< $msg->connection() >> / C<< $msg->connection($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection>)

Required. Connection to create.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::GetConnectionRequest

The request for
[ConnectionService.GetConnection][google.cloud.bigquery.connection.v1beta1.ConnectionService.GetConnection].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the requested connection, for example:
`projects/{project_id}/locations/{location_id}/connections/{connection_id}`

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsRequest

The request for
[ConnectionService.ListConnections][google.cloud.bigquery.connection.v1beta1.ConnectionService.ListConnections].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource name.
Must be in the form: `projects/{project_id}/locations/{location_id}`

=item * C<< $msg->max_results() >> / C<< $msg->max_results($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::UInt32Value>)

Required. Maximum number of results per page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsResponse

The response for
[ConnectionService.ListConnections][google.cloud.bigquery.connection.v1beta1.ConnectionService.ListConnections].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Next page token.

=item * C<< $msg->connections() >> / C<< $msg->connections($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection>)

List of connections.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionRequest

The request for
[ConnectionService.UpdateConnection][google.cloud.bigquery.connection.v1beta1.ConnectionService.UpdateConnection].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the connection to update, for example:
`projects/{project_id}/locations/{location_id}/connections/{connection_id}`

=item * C<< $msg->connection() >> / C<< $msg->connection($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection>)

Required. Connection containing the updated fields.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Update mask for the connection fields to be updated.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionCredentialRequest

The request for
[ConnectionService.UpdateConnectionCredential][google.cloud.bigquery.connection.v1beta1.ConnectionService.UpdateConnectionCredential].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the connection, for example:
`projects/{project_id}/locations/{location_id}/connections/{connection_id}/credential`

=item * C<< $msg->credential() >> / C<< $msg->credential($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionCredential>)

Required. Credential to use with the connection.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::DeleteConnectionRequest

The request for [ConnectionService.DeleteConnectionRequest][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the deleted connection, for example:
`projects/{project_id}/locations/{location_id}/connections/{connection_id}`

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection

Configuration parameters to establish connection with an external data
source, except the credential attributes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the connection in the form of:
`projects/{project_id}/locations/{location_id}/connections/{connection_id}`

=item * C<< $msg->friendly_name() >> / C<< $msg->friendly_name($value) >>

Type: C<String>

User provided display name for the connection.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User provided description.

=item * C<< $msg->cloud_sql() >> / C<< $msg->cloud_sql($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlProperties>)

Cloud SQL properties.

=item * C<< $msg->creation_time() >> / C<< $msg->creation_time($value) >>

Type: C<Int64>

Output only. The creation timestamp of the connection.

=item * C<< $msg->last_modified_time() >> / C<< $msg->last_modified_time($value) >>

Type: C<Int64>

Output only. The last update timestamp of the connection.

=item * C<< $msg->has_credential() >> / C<< $msg->has_credential($value) >>

Type: C<Bool>

Output only. True, if credential is configured for this connection.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionCredential

Credential to use with a connection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_sql() >> / C<< $msg->cloud_sql($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential>)

Credential for Cloud SQL database.

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlProperties

Connection properties specific to the Cloud SQL.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Cloud SQL instance ID in the form `project:location:instance`.

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

Database name.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Connection::V1beta1::CloudSqlProperties::DatabaseType>)

Type of the Cloud SQL database.

=item * C<< $msg->credential() >> / C<< $msg->credential($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential>)

Input only. Cloud SQL credential.

=item * C<< $msg->service_account_id() >> / C<< $msg->service_account_id($value) >>

Type: C<String>

Output only. The account ID of the service used for the purpose of this
connection.

When the connection is used in the context of an operation in
BigQuery, this service account will serve as the identity being used for
connecting to the CloudSQL instance specified in this connection.

=back

=head3 Enum: CloudSqlProperties::DatabaseType

=over 4

=item * C<DATABASE_TYPE_UNSPECIFIED> => C<0>

=item * C<POSTGRES> => C<1>

=item * C<MYSQL> => C<2>

=back

=head2 Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential

Credential info for the Cloud SQL.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

The username for the credential.

=item * C<< $msg->password() >> / C<< $msg->password($value) >>

Type: C<String>

The password for the credential.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Connection::V1beta1::Connection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
