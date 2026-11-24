package Google::Cloud::Vectorsearch::V1beta::DataObjectService;

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
    eval { require Google::Cloud::Vectorsearch::V1beta::DataObject };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxYmV0YS9kYXRhX29iamVjdF9zZXJ2aWNl
LnByb3RvEiBnb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YRocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdvb2ds
ZS9jbG91ZC92ZWN0b3JzZWFyY2gvdjFiZXRhL2RhdGFfb2JqZWN0LnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
IuABChdDcmVhdGVEYXRhT2JqZWN0UmVxdWVzdBJGCgZwYXJlbnQYASABKAlCLuBBAvpBKAom
dmVjdG9yc2VhcmNoLmdvb2dsZWFwaXMuY29tL0NvbGxlY3Rpb25SBnBhcmVudBIpCg5kYXRh
X29iamVjdF9pZBgCIAEoCUID4EECUgxkYXRhT2JqZWN0SWQSUgoLZGF0YV9vYmplY3QYAyAB
KAsyLC5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YS5EYXRhT2JqZWN0QgPgQQJS
CmRhdGFPYmplY3QiwwEKHUJhdGNoQ3JlYXRlRGF0YU9iamVjdHNSZXF1ZXN0EkYKBnBhcmVu
dBgBIAEoCUIu4EEC+kEoCiZ2ZWN0b3JzZWFyY2guZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlv
blIGcGFyZW50EloKCHJlcXVlc3RzGAIgAygLMjkuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJj
aC52MWJldGEuQ3JlYXRlRGF0YU9iamVjdFJlcXVlc3RCA+BBAlIIcmVxdWVzdHMidgoeQmF0
Y2hDcmVhdGVEYXRhT2JqZWN0c1Jlc3BvbnNlElQKDGRhdGFfb2JqZWN0cxgBIAMoCzIsLmdv
b2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkRhdGFPYmplY3RCA+BBA1ILZGF0YU9i
amVjdHMiWgoUR2V0RGF0YU9iamVjdFJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZ2
ZWN0b3JzZWFyY2guZ29vZ2xlYXBpcy5jb20vRGF0YU9iamVjdFIEbmFtZSKvAQoXVXBkYXRl
RGF0YU9iamVjdFJlcXVlc3QSUgoLZGF0YV9vYmplY3QYASABKAsyLC5nb29nbGUuY2xvdWQu
dmVjdG9yc2VhcmNoLnYxYmV0YS5EYXRhT2JqZWN0QgPgQQJSCmRhdGFPYmplY3QSQAoLdXBk
YXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0
ZU1hc2siwwEKHUJhdGNoVXBkYXRlRGF0YU9iamVjdHNSZXF1ZXN0EkYKBnBhcmVudBgBIAEo
CUIu4EEC+kEoCiZ2ZWN0b3JzZWFyY2guZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvblIGcGFy
ZW50EloKCHJlcXVlc3RzGAIgAygLMjkuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJl
dGEuVXBkYXRlRGF0YU9iamVjdFJlcXVlc3RCA+BBAlIIcmVxdWVzdHMiIAoeQmF0Y2hVcGRh
dGVEYXRhT2JqZWN0c1Jlc3BvbnNlInYKF0RlbGV0ZURhdGFPYmplY3RSZXF1ZXN0EkIKBG5h
bWUYASABKAlCLuBBAvpBKAomdmVjdG9yc2VhcmNoLmdvb2dsZWFwaXMuY29tL0RhdGFPYmpl
Y3RSBG5hbWUSFwoEZXRhZxgCIAEoCUID4EEBUgRldGFnIsMBCh1CYXRjaERlbGV0ZURhdGFP
YmplY3RzUmVxdWVzdBJGCgZwYXJlbnQYASABKAlCLuBBAvpBKAomdmVjdG9yc2VhcmNoLmdv
b2dsZWFwaXMuY29tL0NvbGxlY3Rpb25SBnBhcmVudBJaCghyZXF1ZXN0cxgDIAMoCzI5Lmdv
b2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkRlbGV0ZURhdGFPYmplY3RSZXF1ZXN0
QgPgQQJSCHJlcXVlc3RzMsANChFEYXRhT2JqZWN0U2VydmljZRL3AQoQQ3JlYXRlRGF0YU9i
amVjdBI5Lmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkNyZWF0ZURhdGFPYmpl
Y3RSZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGEuRGF0YU9iamVj
dCJ6gtPkkwJQIkEvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xs
ZWN0aW9ucy8qfS9kYXRhT2JqZWN0czoLZGF0YV9vYmplY3TaQSFwYXJlbnQsZGF0YV9vYmpl
Y3QsZGF0YV9vYmplY3RfaWQS9QEKFkJhdGNoQ3JlYXRlRGF0YU9iamVjdHMSPy5nb29nbGUu
Y2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YS5CYXRjaENyZWF0ZURhdGFPYmplY3RzUmVxdWVz
dBpALmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkJhdGNoQ3JlYXRlRGF0YU9i
amVjdHNSZXNwb25zZSJYgtPkkwJSIk0vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb2xsZWN0aW9ucy8qfS9kYXRhT2JqZWN0czpiYXRjaENyZWF0ZToBKhLHAQoN
R2V0RGF0YU9iamVjdBI2Lmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkdldERh
dGFPYmplY3RSZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGEuRGF0
YU9iamVjdCJQgtPkkwJDEkEvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
Y29sbGVjdGlvbnMvKi9kYXRhT2JqZWN0cy8qfdpBBG5hbWUS+QEKEFVwZGF0ZURhdGFPYmpl
Y3QSOS5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YS5VcGRhdGVEYXRhT2JqZWN0
UmVxdWVzdBosLmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkRhdGFPYmplY3Qi
fILT5JMCXDJNL3YxYmV0YS97ZGF0YV9vYmplY3QubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NvbGxlY3Rpb25zLyovZGF0YU9iamVjdHMvKn06C2RhdGFfb2JqZWN02kEXZGF0YV9v
YmplY3QsdXBkYXRlX21hc2sShwIKFkJhdGNoVXBkYXRlRGF0YU9iamVjdHMSPy5nb29nbGUu
Y2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YS5CYXRjaFVwZGF0ZURhdGFPYmplY3RzUmVxdWVz
dBpALmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkJhdGNoVXBkYXRlRGF0YU9i
amVjdHNSZXNwb25zZSJqgtPkkwJSIk0vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb2xsZWN0aW9ucy8qfS9kYXRhT2JqZWN0czpiYXRjaFVwZGF0ZToBKtpBD3Bh
cmVudCxyZXF1ZXN0cxK3AQoQRGVsZXRlRGF0YU9iamVjdBI5Lmdvb2dsZS5jbG91ZC52ZWN0
b3JzZWFyY2gudjFiZXRhLkRlbGV0ZURhdGFPYmplY3RSZXF1ZXN0GhYuZ29vZ2xlLnByb3Rv
YnVmLkVtcHR5IlCC0+STAkMqQS92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jb2xsZWN0aW9ucy8qL2RhdGFPYmplY3RzLyp92kEEbmFtZRLdAQoWQmF0Y2hEZWxldGVE
YXRhT2JqZWN0cxI/Lmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkJhdGNoRGVs
ZXRlRGF0YU9iamVjdHNSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5ImqC0+STAlIi
TS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyp9
L2RhdGFPYmplY3RzOmJhdGNoRGVsZXRlOgEq2kEPcGFyZW50LHJlcXVlc3RzGk/KQRt2ZWN0
b3JzZWFyY2guZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Nsb3VkLXBsYXRmb3JtQvYBCiRjb20uZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52
MWJldGFCFkRhdGFPYmplY3RTZXJ2aWNlUHJvdG9QAVpIY2xvdWQuZ29vZ2xlLmNvbS9nby92
ZWN0b3JzZWFyY2gvYXBpdjFiZXRhL3ZlY3RvcnNlYXJjaHBiO3ZlY3RvcnNlYXJjaHBiqgIg
R29vZ2xlLkNsb3VkLlZlY3RvclNlYXJjaC5WMUJldGHKAiBHb29nbGVcQ2xvdWRcVmVjdG9y
U2VhcmNoXFYxYmV0YeoCI0dvb2dsZTo6Q2xvdWQ6OlZlY3RvclNlYXJjaDo6VjFiZXRhStU4
CgcSBQ4A8QEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAp
CgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYA
PAoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA9CgkKAgglEgMaAD0KCAoBCBIDGwBf
CgkKAggLEgMbAF8KCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA3CgkKAggIEgMdADcK
CAoBCBIDHgA9CgkKAggBEgMeAD0KCAoBCBIDHwA9CgkKAggpEgMfAD0KCAoBCBIDIAA8CgkK
AggtEgMgADwKPQoCBgASBCMAZwEaMSBTZXJ2aWNlIGZvciBjcmVhdGluZyBhbmQgbWFuYWdp
bmcgZGF0YSBvYmplY3RzLgoKCgoDBgABEgMjCBkKCgoDBgADEgMkAkMKDAoFBgADmQgSAyQC
QwoLCgMGAAMSBCUCJjcKDQoFBgADmggSBCUCJjcKJQoEBgACABIEKQIvAxoXIENyZWF0ZXMg
YSBkYXRhT2JqZWN0LgoKDAoFBgACAAESAykGFgoMCgUGAAIAAhIDKRcuCgwKBQYAAgADEgMp
OUMKDQoFBgACAAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0GCgwKBQYAAgAEEgMuBE8KDwoI
BgACAASbCAASAy4ETwovCgQGAAIBEgQyAjgDGiEgQ3JlYXRlcyBhIGJhdGNoIG9mIGRhdGFP
YmplY3RzLgoKDAoFBgACAQESAzIGHAoMCgUGAAIBAhIDMh06CgwKBQYAAgEDEgMzDy0KDQoF
BgACAQQSBDQENwYKEQoJBgACAQSwyrwiEgQ0BDcGCiMKBAYAAgISBDsCQAMaFSBHZXRzIGEg
ZGF0YSBvYmplY3QuCgoMCgUGAAICARIDOwYTCgwKBQYAAgICEgM7FCgKDAoFBgACAgMSAzsz
PQoNCgUGAAICBBIEPAQ+BgoRCgkGAAICBLDKvCISBDwEPgYKDAoFBgACAgQSAz8EMgoPCggG
AAICBJsIABIDPwQyCiUKBAYAAgMSBEMCSQMaFyBVcGRhdGVzIGEgZGF0YU9iamVjdC4KCgwK
BQYAAgMBEgNDBhYKDAoFBgACAwISA0MXLgoMCgUGAAIDAxIDQzlDCg0KBQYAAgMEEgREBEcG
ChEKCQYAAgMEsMq8IhIERARHBgoMCgUGAAIDBBIDSARFCg8KCAYAAgMEmwgAEgNIBEUKLwoE
BgACBBIETAJTAxohIFVwZGF0ZXMgZGF0YU9iamVjdHMgaW4gYSBiYXRjaC4KCgwKBQYAAgQB
EgNMBhwKDAoFBgACBAISA0wdOgoMCgUGAAIEAxIDTQ8tCg0KBQYAAgQEEgROBFEGChEKCQYA
AgQEsMq8IhIETgRRBgoMCgUGAAIEBBIDUgQ9Cg8KCAYAAgQEmwgAEgNSBD0KJQoEBgACBRIE
VgJcAxoXIERlbGV0ZXMgYSBkYXRhT2JqZWN0LgoKDAoFBgACBQESA1YGFgoMCgUGAAIFAhID
VhcuCgwKBQYAAgUDEgNXDyQKDQoFBgACBQQSBFgEWgYKEQoJBgACBQSwyrwiEgRYBFoGCgwK
BQYAAgUEEgNbBDIKDwoIBgACBQSbCAASA1sEMgovCgQGAAIGEgRfAmYDGiEgRGVsZXRlcyBk
YXRhT2JqZWN0cyBpbiBhIGJhdGNoLgoKDAoFBgACBgESA18GHAoMCgUGAAIGAhIDXx06CgwK
BQYAAgYDEgNgDyQKDQoFBgACBgQSBGEEZAYKEQoJBgACBgSwyrwiEgRhBGQGCgwKBQYAAgYE
EgNlBD0KDwoIBgACBgSbCAASA2UEPQqOAQoCBAASBGsAfgEagQEgUmVxdWVzdCBtZXNzYWdl
IGZvcgogW0RhdGFPYmplY3RTZXJ2aWNlLkNyZWF0ZURhdGFPYmplY3RdW2dvb2dsZS5jbG91
ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkRhdGFPYmplY3RTZXJ2aWNlLkNyZWF0ZURhdGFPYmpl
Y3RdLgoKCgoDBAABEgNrCB8KpwEKBAQAAgASBG4CcwQamAEgUmVxdWlyZWQuIFRoZSByZXNv
dXJjZSBuYW1lIG9mIHRoZSBDb2xsZWN0aW9uIHRvIGNyZWF0ZSB0aGUgRGF0YU9iamVjdCBp
bi4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b2xsZWN0aW9ucy97Y29sbGVjdGlvbn1gCgoMCgUEAAIABRIDbgIICgwKBQQAAgABEgNuCQ8K
DAoFBAACAAMSA24SEwoNCgUEAAIACBIEbhRzAwoPCggEAAIACJwIABIDbwQqCg8KBwQAAgAI
nwgSBHAEcgUKmwIKBAQAAgESA3oCRRqNAiBSZXF1aXJlZC4gVGhlIGlkIG9mIHRoZSBkYXRh
T2JqZWN0IHRvIGNyZWF0ZS4KIFRoZSBpZCBtdXN0IGJlIDEtNjMgY2hhcmFjdGVycyBsb25n
LCBhbmQgY29tcGx5IHdpdGgKIFtSRkMxMDM1XShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMv
cmZjMTAzNS50eHQpLgogU3BlY2lmaWNhbGx5LCBpdCBtdXN0IGJlIDEtNjMgY2hhcmFjdGVy
cyBsb25nIGFuZCBtYXRjaCB0aGUgcmVndWxhcgogZXhwcmVzc2lvbiBgW2Etel0oPzpbLWEt
ejAtOV17MCw2MX1bYS16MC05XSk/YC4KCgwKBQQAAgEFEgN6AggKDAoFBAACAQESA3oJFwoM
CgUEAAIBAxIDehobCgwKBQQAAgEIEgN6HEQKDwoIBAACAQicCAASA3odQwoyCgQEAAICEgN9
AkYaJSBSZXF1aXJlZC4gVGhlIERhdGFPYmplY3QgdG8gY3JlYXRlLgoKDAoFBAACAgYSA30C
DAoMCgUEAAICARIDfQ0YCgwKBQQAAgIDEgN9GxwKDAoFBAACAggSA30dRQoPCggEAAICCJwI
ABIDfR5ECpwBCgIEARIGggEAkgEBGo0BIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEYXRhT2Jq
ZWN0U2VydmljZS5CYXRjaENyZWF0ZURhdGFPYmplY3RzXVtnb29nbGUuY2xvdWQudmVjdG9y
c2VhcmNoLnYxYmV0YS5EYXRhT2JqZWN0U2VydmljZS5CYXRjaENyZWF0ZURhdGFPYmplY3Rz
XS4KCgsKAwQBARIEggEIJQr9AQoEBAECABIGhwECjAEEGuwBIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgQ29sbGVjdGlvbiB0byBjcmVhdGUgdGhlIERhdGFPYmplY3Rz
IGluLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufWAuCiBUaGUgcGFyZW50IGZpZWxkIGluIHRoZSBD
cmVhdGVEYXRhT2JqZWN0UmVxdWVzdCBtZXNzYWdlcyBtdXN0IG1hdGNoIHRoaXMKIGZpZWxk
LgoKDQoFBAECAAUSBIcBAggKDQoFBAECAAESBIcBCQ8KDQoFBAECAAMSBIcBEhMKDwoFBAEC
AAgSBocBFIwBAwoQCggEAQIACJwIABIEiAEEKgoRCgcEAQIACJ8IEgaJAQSLAQUKjQEKBAQB
AgESBpABApEBLxp9IFJlcXVpcmVkLiBUaGUgcmVxdWVzdCBtZXNzYWdlIHNwZWNpZnlpbmcg
dGhlIHJlc291cmNlcyB0byBjcmVhdGUuCiBBIG1heGltdW0gb2YgMTAwMCBEYXRhT2JqZWN0
cyBjYW4gYmUgY3JlYXRlZCBpbiBhIGJhdGNoLgoKDQoFBAECAQQSBJABAgoKDQoFBAECAQYS
BJABCyIKDQoFBAECAQESBJABIysKDQoFBAECAQMSBJABLi8KDQoFBAECAQgSBJEBBi4KEAoI
BAECAQicCAASBJEBBy0KnQEKAgQCEgaWAQCaAQEajgEgUmVzcG9uc2UgbWVzc2FnZSBmb3IK
IFtEYXRhT2JqZWN0U2VydmljZS5CYXRjaENyZWF0ZURhdGFPYmplY3RzXVtnb29nbGUuY2xv
dWQudmVjdG9yc2VhcmNoLnYxYmV0YS5EYXRhT2JqZWN0U2VydmljZS5CYXRjaENyZWF0ZURh
dGFPYmplY3RzXS4KCgsKAwQCARIElgEIJgozCgQEAgIAEgaYAQKZATIaIyBPdXRwdXQgb25s
eS4gRGF0YU9iamVjdHMgY3JlYXRlZC4KCg0KBQQCAgAEEgSYAQIKCg0KBQQCAgAGEgSYAQsV
Cg0KBQQCAgABEgSYARYiCg0KBQQCAgADEgSYASUmCg0KBQQCAgAIEgSZAQYxChAKCAQCAgAI
nAgAEgSZAQcwCokBCgIEAxIGngEAqAEBGnsgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFP
YmplY3RTZXJ2aWNlLkdldERhdGFPYmplY3RdW2dvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gu
djFiZXRhLkRhdGFPYmplY3RTZXJ2aWNlLkdldERhdGFPYmplY3RdLgoKCwoDBAMBEgSeAQgc
CqcBCgQEAwIAEgaiAQKnAQQalgEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBEYXRhT2Jq
ZWN0IHJlc291cmNlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YU9iamVjdHMve2RhdGFP
YmplY3R9YAoKDQoFBAMCAAUSBKIBAggKDQoFBAMCAAESBKIBCQ0KDQoFBAMCAAMSBKIBEBEK
DwoFBAMCAAgSBqIBEqcBAwoQCggEAwIACJwIABIEowEEKgoRCgcEAwIACJ8IEgakAQSmAQUK
kAEKAgQEEgasAQC0AQEagQEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFPYmplY3RTZXJ2
aWNlLlVwZGF0ZURhdGFPYmplY3RdW2dvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRh
LkRhdGFPYmplY3RTZXJ2aWNlLlVwZGF0ZURhdGFPYmplY3RdLgoKCwoDBAQBEgSsAQgfClMK
BAQEAgASBK4BAkYaRSBSZXF1aXJlZC4gVGhlIERhdGFPYmplY3Qgd2hpY2ggcmVwbGFjZXMg
dGhlIHJlc291cmNlIG9uIHRoZSBzZXJ2ZXIuCgoNCgUEBAIABhIErgECDAoNCgUEBAIAARIE
rgENGAoNCgUEBAIAAxIErgEbHAoNCgUEBAIACBIErgEdRQoQCggEBAIACJwIABIErgEeRAqB
AQoEBAQCARIGsgECswEvGnEgT3B0aW9uYWwuIFRoZSB1cGRhdGUgbWFzayBhcHBsaWVzIHRv
IHRoZSByZXNvdXJjZS4gU2VlCiBbZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza11bZ29vZ2xl
LnByb3RvYnVmLkZpZWxkTWFza10uCgoNCgUEBAIBBhIEsgECGwoNCgUEBAIBARIEsgEcJwoN
CgUEBAIBAxIEsgEqKwoNCgUEBAIBCBIEswEGLgoQCggEBAIBCJwIABIEswEHLQqcAQoCBAUS
BrgBAMgBARqNASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YU9iamVjdFNlcnZpY2UuQmF0
Y2hVcGRhdGVEYXRhT2JqZWN0c11bZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGEu
RGF0YU9iamVjdFNlcnZpY2UuQmF0Y2hVcGRhdGVEYXRhT2JqZWN0c10uCgoLCgMEBQESBLgB
CCUK/QEKBAQFAgASBr0BAsIBBBrsASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIENvbGxlY3Rpb24gdG8gdXBkYXRlIHRoZSBEYXRhT2JqZWN0cyBpbi4KIEZvcm1hdDog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97
Y29sbGVjdGlvbn1gLgogVGhlIHBhcmVudCBmaWVsZCBpbiB0aGUgVXBkYXRlRGF0YU9iamVj
dFJlcXVlc3QgbWVzc2FnZXMgbXVzdCBtYXRjaCB0aGlzCiBmaWVsZC4KCg0KBQQFAgAFEgS9
AQIICg0KBQQFAgABEgS9AQkPCg0KBQQFAgADEgS9ARITCg8KBQQFAgAIEga9ARTCAQMKEAoI
BAUCAAicCAASBL4BBCoKEQoHBAUCAAifCBIGvwEEwQEFCo0BCgQEBQIBEgbGAQLHAS8afSBS
ZXF1aXJlZC4gVGhlIHJlcXVlc3QgbWVzc2FnZSBzcGVjaWZ5aW5nIHRoZSByZXNvdXJjZXMg
dG8gdXBkYXRlLgogQSBtYXhpbXVtIG9mIDEwMDAgRGF0YU9iamVjdHMgY2FuIGJlIHVwZGF0
ZWQgaW4gYSBiYXRjaC4KCg0KBQQFAgEEEgTGAQIKCg0KBQQFAgEGEgTGAQsiCg0KBQQFAgEB
EgTGASMrCg0KBQQFAgEDEgTGAS4vCg0KBQQFAgEIEgTHAQYuChAKCAQFAgEInAgAEgTHAQct
CpsBCgIEBhIEzAEAKRqOASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0RhdGFPYmplY3RTZXJ2
aWNlLkJhdGNoVXBkYXRlRGF0YU9iamVjdHNdW2dvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gu
djFiZXRhLkRhdGFPYmplY3RTZXJ2aWNlLkJhdGNoVXBkYXRlRGF0YU9iamVjdHNdLgoKCwoD
BAYBEgTMAQgmCpABCgIEBxIG0AEA3wEBGoEBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEYXRh
T2JqZWN0U2VydmljZS5EZWxldGVEYXRhT2JqZWN0XVtnb29nbGUuY2xvdWQudmVjdG9yc2Vh
cmNoLnYxYmV0YS5EYXRhT2JqZWN0U2VydmljZS5EZWxldGVEYXRhT2JqZWN0XS4KCgsKAwQH
ARIE0AEIHwq1AQoEBAcCABIG1AEC2QEEGqQBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
RGF0YU9iamVjdCByZXNvdXJjZSB0byBiZSBkZWxldGVkLgogRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlv
bn0vZGF0YU9iamVjdHMve2RhdGFPYmplY3R9YAoKDQoFBAcCAAUSBNQBAggKDQoFBAcCAAES
BNQBCQ0KDQoFBAcCAAMSBNQBEBEKDwoFBAcCAAgSBtQBEtkBAwoQCggEBwIACJwIABIE1QEE
KgoRCgcEBwIACJ8IEgbWAQTYAQUKzgEKBAQHAgESBN4BAjsavwEgT3B0aW9uYWwuIFRoZSBj
dXJyZW50IGV0YWcgb2YgdGhlIERhdGFPYmplY3QuCiBJZiBhbiBldGFnIGlzIHByb3ZpZGVk
IGFuZCBkb2VzIG5vdCBtYXRjaCB0aGUgY3VycmVudCBldGFnIG9mIHRoZQogRGF0YU9iamVj
dCwgZGVsZXRpb24gd2lsbCBiZSBibG9ja2VkIGFuZCBhbiBBQk9SVEVEIGVycm9yIHdpbGwg
YmUgcmV0dXJuZWQuCgoNCgUEBwIBBRIE3gECCAoNCgUEBwIBARIE3gEJDQoNCgUEBwIBAxIE
3gEQEQoNCgUEBwIBCBIE3gESOgoQCggEBwIBCJwIABIE3gETOQqcAQoCBAgSBuMBAPEBARqN
ASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YU9iamVjdFNlcnZpY2UuQmF0Y2hEZWxldGVE
YXRhT2JqZWN0c11bZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGEuRGF0YU9iamVj
dFNlcnZpY2UuQmF0Y2hEZWxldGVEYXRhT2JqZWN0c10uCgoLCgMECAESBOMBCCUKqwEKBAQI
AgASBuYBAusBBBqaASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIENvbGxl
Y3Rpb24gdG8gZGVsZXRlIHRoZSBEYXRhT2JqZWN0cyBpbi4KIEZvcm1hdDogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlv
bn1gLgoKDQoFBAgCAAUSBOYBAggKDQoFBAgCAAESBOYBCQ8KDQoFBAgCAAMSBOYBEhMKDwoF
BAgCAAgSBuYBFOsBAwoQCggECAIACJwIABIE5wEEKgoRCgcECAIACJ8IEgboAQTqAQUKjQEK
BAQIAgESBu8BAvABLxp9IFJlcXVpcmVkLiBUaGUgcmVxdWVzdCBtZXNzYWdlIHNwZWNpZnlp
bmcgdGhlIHJlc291cmNlcyB0byBkZWxldGUuCiBBIG1heGltdW0gb2YgMTAwMCBEYXRhT2Jq
ZWN0cyBjYW4gYmUgZGVsZXRlZCBpbiBhIGJhdGNoLgoKDQoFBAgCAQQSBO8BAgoKDQoFBAgC
AQYSBO8BCyIKDQoFBAgCAQESBO8BIysKDQoFBAgCAQMSBO8BLi8KDQoFBAgCAQgSBPABBi4K
EAoIBAgCAQicCAASBPABBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest ===
    # Fields for CreateDataObjectRequest
    # Field: parent Type: 9 ()
    # Field: data_object_id Type: 9 ()
    # Field: data_object Type: 11 (.google.cloud.vectorsearch.v1beta.DataObject)

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsRequest ===
    # Fields for BatchCreateDataObjectsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.vectorsearch.v1beta.CreateDataObjectRequest)

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsResponse ===
    # Fields for BatchCreateDataObjectsResponse
    # Field: data_objects Type: 11 (.google.cloud.vectorsearch.v1beta.DataObject)

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::GetDataObjectRequest ===
    # Fields for GetDataObjectRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest ===
    # Fields for UpdateDataObjectRequest
    # Field: data_object Type: 11 (.google.cloud.vectorsearch.v1beta.DataObject)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsRequest ===
    # Fields for BatchUpdateDataObjectsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.vectorsearch.v1beta.UpdateDataObjectRequest)

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsResponse ===
    # Fields for BatchUpdateDataObjectsResponse

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest ===
    # Fields for DeleteDataObjectRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchDeleteDataObjectsRequest ===
    # Fields for BatchDeleteDataObjectsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.vectorsearch.v1beta.DeleteDataObjectRequest)

# === Service Client: Google::Cloud::Vectorsearch::V1beta::DataObjectService::DataObjectServiceClient ===
package Google::Cloud::Vectorsearch::V1beta::DataObjectService::DataObjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Vectorsearch::V1beta::DataObjectService::DataObjectServiceClient

Client stub representing the remote C<DataObjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<vectorsearch.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'vectorsearch.googleapis.com:443' );

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

sub create_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'CreateDataObject',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject',
    });
}

sub batch_create_data_objects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'BatchCreateDataObjects',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsResponse',
    });
}

sub get_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::GetDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'GetDataObject',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject',
    });
}

sub update_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'UpdateDataObject',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject',
    });
}

sub batch_update_data_objects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'BatchUpdateDataObjects',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsResponse',
    });
}

sub delete_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'DeleteDataObject',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub batch_delete_data_objects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchDeleteDataObjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1beta.DataObjectService',
        method         => 'BatchDeleteDataObjects',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::DataObjectService - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1beta/data_object_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1beta::DataObjectService;

    my $msg = Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest->new({
        parent => $parent,
        data_object_id => $data_object_id,
        data_object => $data_object,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1beta/data_object_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest

Request message for
[DataObjectService.CreateDataObject][google.cloud.vectorsearch.v1beta.DataObjectService.CreateDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to create the DataObject in.
Format: `projects/{project}/locations/{location}/collections/{collection}`

=item * C<< $msg->data_object_id() >> / C<< $msg->data_object_id($value) >>

Type: C<String>

Required. The id of the dataObject to create.
The id must be 1-63 characters long, and comply with
[RFC1035](https://www.ietf.org/rfc/rfc1035.txt).
Specifically, it must be 1-63 characters long and match the regular
expression `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?`.

=item * C<< $msg->data_object() >> / C<< $msg->data_object($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject>)

Required. The DataObject to create.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsRequest

Request message for
[DataObjectService.BatchCreateDataObjects][google.cloud.vectorsearch.v1beta.DataObjectService.BatchCreateDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to create the DataObjects in.
Format: `projects/{project}/locations/{location}/collections/{collection}`.
The parent field in the CreateDataObjectRequest messages must match this
field.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest>)

Required. The request message specifying the resources to create.
A maximum of 1000 DataObjects can be created in a batch.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsResponse

Response message for
[DataObjectService.BatchCreateDataObjects][google.cloud.vectorsearch.v1beta.DataObjectService.BatchCreateDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_objects() >> / C<< $msg->data_objects($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject>)

Output only. DataObjects created.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::GetDataObjectRequest

Request message for
[DataObjectService.GetDataObject][google.cloud.vectorsearch.v1beta.DataObjectService.GetDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DataObject resource.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataObjects/{dataObject}`

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest

Request message for
[DataObjectService.UpdateDataObject][google.cloud.vectorsearch.v1beta.DataObjectService.UpdateDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_object() >> / C<< $msg->data_object($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject>)

Required. The DataObject which replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The update mask applies to the resource. See
[google.protobuf.FieldMask][google.protobuf.FieldMask].

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsRequest

Request message for
[DataObjectService.BatchUpdateDataObjects][google.cloud.vectorsearch.v1beta.DataObjectService.BatchUpdateDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to update the DataObjects in.
Format: `projects/{project}/locations/{location}/collections/{collection}`.
The parent field in the UpdateDataObjectRequest messages must match this
field.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest>)

Required. The request message specifying the resources to update.
A maximum of 1000 DataObjects can be updated in a batch.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsResponse

Response message for
[DataObjectService.BatchUpdateDataObjects][google.cloud.vectorsearch.v1beta.DataObjectService.BatchUpdateDataObjects].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest

Request message for
[DataObjectService.DeleteDataObject][google.cloud.vectorsearch.v1beta.DataObjectService.DeleteDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DataObject resource to be deleted.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataObjects/{dataObject}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the DataObject.
If an etag is provided and does not match the current etag of the
DataObject, deletion will be blocked and an ABORTED error will be returned.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchDeleteDataObjectsRequest

Request message for
[DataObjectService.BatchDeleteDataObjects][google.cloud.vectorsearch.v1beta.DataObjectService.BatchDeleteDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to delete the DataObjects in.
Format: `projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest>)

Required. The request message specifying the resources to delete.
A maximum of 1000 DataObjects can be deleted in a batch.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1beta::DataObjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
