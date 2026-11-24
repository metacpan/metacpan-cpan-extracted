package Google::Cloud::Discoveryengine::V1alpha::EngineService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Engine };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZW5naW5lX3NlcnZpY2Uu
cHJvdG8SJGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYRocZ29vZ2xlL2Fw
aS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMWdv
b2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBoYS9lbmdpbmUucHJvdG8aI2dvb2ds
ZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIs0BChNDcmVhdGVFbmdpbmVSZXF1ZXN0EkkKBnBhcmVudBgB
IAEoCUIx4EEC+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlv
blIGcGFyZW50EkkKBmVuZ2luZRgCIAEoCzIsLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5FbmdpbmVCA+BBAlIGZW5naW5lEiAKCWVuZ2luZV9pZBgDIAEoCUID4EEC
UghlbmdpbmVJZCKQAQoUQ3JlYXRlRW5naW5lTWV0YWRhdGESOwoLY3JlYXRlX3RpbWUYASAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90
aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZSJYChNE
ZWxldGVFbmdpbmVSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29tL0VuZ2luZVIEbmFtZSKQAQoURGVsZXRlRW5naW5lTWV0YWRh
dGESOwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpj
cmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKdXBkYXRlVGltZSJVChBHZXRFbmdpbmVSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBB
AvpBJwolZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0VuZ2luZVIEbmFtZSLCAQoS
TGlzdEVuZ2luZXNSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx4EEC+kErCilkaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgC
IAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tl
bhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIoUBChNMaXN0RW5naW5lc1Jlc3BvbnNl
EkYKB2VuZ2luZXMYASADKAsyLC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRW5naW5lUgdlbmdpbmVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiKdAQoTVXBkYXRlRW5naW5lUmVxdWVzdBJJCgZlbmdpbmUYASABKAsyLC5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lQgPgQQJSBmVuZ2luZRI7Cgt1
cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1h
c2siVwoSUGF1c2VFbmdpbmVSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0VuZ2luZVIEbmFtZSJYChNSZXN1bWVFbmdpbmVS
ZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0VuZ2luZVIEbmFtZSJWChFUdW5lRW5naW5lUmVxdWVzdBJBCgRuYW1lGAEgASgJ
Qi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9FbmdpbmVSBG5hbWUi
WwoSVHVuZUVuZ2luZU1ldGFkYXRhEkUKBmVuZ2luZRgBIAEoCUIt4EEC+kEnCiVkaXNjb3Zl
cnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRW5naW5lUgZlbmdpbmUiFAoSVHVuZUVuZ2luZVJl
c3BvbnNlMsAPCg1FbmdpbmVTZXJ2aWNlEr4CCgxDcmVhdGVFbmdpbmUSOS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ3JlYXRlRW5naW5lUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24i0wGC0+STAkgiPi92MWFscGhhL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qfS9lbmdpbmVzOgZlbmdpbmXaQRdw
YXJlbnQsZW5naW5lLGVuZ2luZV9pZMpBaAorZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLkVuZ2luZRI5Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkNyZWF0ZUVuZ2luZU1ldGFkYXRhEo0CCgxEZWxldGVFbmdpbmUSOS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGVsZXRlRW5naW5lUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24iogGC0+STAkAqPi92MWFscGhhL3tuYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyp92kEEbmFtZcpBUgoVZ29v
Z2xlLnByb3RvYnVmLkVtcHR5Ejlnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRGVsZXRlRW5naW5lTWV0YWRhdGES4wEKDFVwZGF0ZUVuZ2luZRI5Lmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5VcGRhdGVFbmdpbmVSZXF1ZXN0GiwuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkVuZ2luZSJqgtPkkwJPMkUvdjFhbHBo
YS97ZW5naW5lLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2Vu
Z2luZXMvKn06BmVuZ2luZdpBEmVuZ2luZSx1cGRhdGVfbWFzaxLAAQoJR2V0RW5naW5lEjYu
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdldEVuZ2luZVJlcXVlc3Qa
LC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lIk2C0+STAkAS
Pi92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9l
bmdpbmVzLyp92kEEbmFtZRLTAQoLTGlzdEVuZ2luZXMSOC5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdEVuZ2luZXNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RFbmdpbmVzUmVzcG9uc2UiT4LT5JMCQBI+L3Yx
YWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyp9L2Vu
Z2luZXPaQQZwYXJlbnQSzQEKC1BhdXNlRW5naW5lEjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlBhdXNlRW5naW5lUmVxdWVzdBosLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmUiVoLT5JMCSSJEL3YxYWxwaGEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn06cGF1c2U6ASra
QQRuYW1lEtABCgxSZXN1bWVFbmdpbmUSOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuUmVzdW1lRW5naW5lUmVxdWVzdBosLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5FbmdpbmUiV4LT5JMCSiJFL3YxYWxwaGEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn06cmVzdW1lOgEq2kEEbmFt
ZRLnAQoKVHVuZUVuZ2luZRI3Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5UdW5lRW5naW5lUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24igAGC
0+STAkgiQy92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlv
bnMvKi9lbmdpbmVzLyp9OnR1bmU6ASraQQRuYW1lykEoChJUdW5lRW5naW5lUmVzcG9uc2US
ElR1bmVFbmdpbmVNZXRhZGF0YRpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKeAgoo
Y29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUISRW5naW5lU2Vydmlj
ZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxw
aGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJ
TkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xv
dWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlF
bmdpbmU6OlYxYWxwaGFK904KBxIFDgDQAh0KvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgA7CgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoJCgIDBxIDGQAqCgkK
AgMIEgMaACkKCAoBCBIDHABBCgkKAgglEgMcAEEKCAoBCBIDHQBpCgkKAggLEgMdAGkKCAoB
CBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwAzCgkKAggIEgMfADMKCAoBCBIDIABBCgkKAggB
EgMgAEEKCAoBCBIDIQAtCgkKAggkEgMhAC0KCAoBCBIDIgBBCgkKAggpEgMiAEEKCAoBCBID
IwBACgkKAggtEgMjAEAKaQoCBgASBScAgwEBGlwgU2VydmljZSBmb3IgbWFuYWdpbmcgW0Vu
Z2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkVuZ2luZV0KIGNv
bmZpZ3VyYXRpb24uCgoKCgMGAAESAycIFQoKCgMGAAMSAygCRgoMCgUGAAOZCBIDKAJGCgsK
AwYAAxIEKQIqNwoNCgUGAAOaCBIEKQIqNwpQCgQGAAIAEgQtAjcDGkIgQ3JlYXRlcyBhIFtF
bmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVdLgoK
DAoFBgACAAESAy0GEgoMCgUGAAIAAhIDLRMmCgwKBQYAAgADEgMtMU0KDQoFBgACAAQSBC4E
MQYKEQoJBgACAASwyrwiEgQuBDEGCgwKBQYAAgAEEgMyBEUKDwoIBgACAASbCAASAzIERQoN
CgUGAAIABBIEMwQ2BgoPCgcGAAIABJkIEgQzBDYGClAKBAYAAgESBDoCQwMaQiBEZWxldGVz
IGEgW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkVuZ2lu
ZV0uCgoMCgUGAAIBARIDOgYSCgwKBQYAAgECEgM6EyYKDAoFBgACAQMSAzoxTQoNCgUGAAIB
BBIEOwQ9BgoRCgkGAAIBBLDKvCISBDsEPQYKDAoFBgACAQQSAz4EMgoPCggGAAIBBJsIABID
PgQyCg0KBQYAAgEEEgQ/BEIGCg8KBwYAAgEEmQgSBD8EQgYKUAoEBgACAhIERgJMAxpCIFVw
ZGF0ZXMgYW4gW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkVuZ2luZV0KCgwKBQYAAgIBEgNGBhIKDAoFBgACAgISA0YTJgoMCgUGAAICAxIDRjE3Cg0K
BQYAAgIEEgRHBEoGChEKCQYAAgIEsMq8IhIERwRKBgoMCgUGAAICBBIDSwRACg8KCAYAAgIE
mwgAEgNLBEAKTQoEBgACAxIETwJUAxo/IEdldHMgYSBbRW5naW5lXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lXS4KCgwKBQYAAgMBEgNPBg8KDAoFBgAC
AwISA08QIAoMCgUGAAIDAxIDTysxCg0KBQYAAgMEEgRQBFIGChEKCQYAAgMEsMq8IhIEUARS
BgoMCgUGAAIDBBIDUwQyCg8KCAYAAgMEmwgAEgNTBDIKcgoEBgACBBIEWAJdAxpkIExpc3Rz
IGFsbCB0aGUgW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkVuZ2luZV1zCiBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3QuCgoMCgUGAAIEARIDWAYR
CgwKBQYAAgQCEgNYEiQKDAoFBgACBAMSA1gvQgoNCgUGAAIEBBIEWQRbBgoRCgkGAAIEBLDK
vCISBFkEWwYKDAoFBgACBAQSA1wENAoPCggGAAIEBJsIABIDXAQ0CoUCCgQGAAIFEgRiAmgD
GvYBIFBhdXNlcyB0aGUgdHJhaW5pbmcgb2YgYW4gZXhpc3RpbmcgZW5naW5lLiBPbmx5IGFw
cGxpY2FibGUgaWYKIFtTb2x1dGlvblR5cGVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5Tb2x1dGlvblR5cGVdIGlzCiBbU09MVVRJT05fVFlQRV9SRUNPTU1FTkRB
VElPTl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNvbHV0aW9uVHlw
ZS5TT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXS4KCgwKBQYAAgUBEgNiBhEKDAoFBgAC
BQISA2ISJAoMCgUGAAIFAxIDYi81Cg0KBQYAAgUEEgRjBGYGChEKCQYAAgUEsMq8IhIEYwRm
BgoMCgUGAAIFBBIDZwQyCg8KCAYAAgUEmwgAEgNnBDIKhgIKBAYAAgYSBG0CcwMa9wEgUmVz
dW1lcyB0aGUgdHJhaW5pbmcgb2YgYW4gZXhpc3RpbmcgZW5naW5lLiBPbmx5IGFwcGxpY2Fi
bGUgaWYKIFtTb2x1dGlvblR5cGVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5Tb2x1dGlvblR5cGVdIGlzCiBbU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPTl1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNvbHV0aW9uVHlwZS5TT0xV
VElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXS4KCgwKBQYAAgYBEgNtBhIKDAoFBgACBgISA20T
JgoMCgUGAAIGAxIDbTE3Cg0KBQYAAgYEEgRuBHEGChEKCQYAAgYEsMq8IhIEbgRxBgoMCgUG
AAIGBBIDcgQyCg8KCAYAAgYEmwgAEgNyBDIK9QEKBAYAAgcSBXgCggEDGuUBIFR1bmVzIGFu
IGV4aXN0aW5nIGVuZ2luZS4gT25seSBhcHBsaWNhYmxlIGlmCiBbU29sdXRpb25UeXBlXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlXSBpcwog
W1NPTFVUSU9OX1RZUEVfUkVDT01NRU5EQVRJT05dW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5Tb2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElP
Tl0uCgoMCgUGAAIHARIDeAYQCgwKBQYAAgcCEgN4ESIKDAoFBgACBwMSA3gtSQoNCgUGAAIH
BBIEeQR8BgoRCgkGAAIHBLDKvCISBHkEfAYKDAoFBgACBwQSA30EMgoPCggGAAIHBJsIABID
fQQyCg4KBQYAAgcEEgV+BIEBBgoQCgcGAAIHBJkIEgV+BIEBBgqDAQoCBAASBogBAJ8BARp1
IFJlcXVlc3QgZm9yCiBbRW5naW5lU2VydmljZS5DcmVhdGVFbmdpbmVdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVTZXJ2aWNlLkNyZWF0ZUVuZ2luZV0K
IG1ldGhvZC4KCgsKAwQAARIEiAEIGwqCAQoEBAACABIGiwECkAEEGnIgUmVxdWlyZWQuIFRo
ZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn1gLgoKDQoFBAAC
AAUSBIsBAggKDQoFBAACAAESBIsBCQ8KDQoFBAACAAMSBIsBEhMKDwoFBAACAAgSBosBFJAB
AwoQCggEAAIACJwIABIEjAEEKgoRCgcEAAIACJ8IEgaNAQSPAQUKXwoEBAACARIElAECPRpR
IFJlcXVpcmVkLiBUaGUgW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkVuZ2luZV0gdG8KIGNyZWF0ZS4KCg0KBQQAAgEGEgSUAQIICg0KBQQAAgEBEgSU
AQkPCg0KBQQAAgEDEgSUARITCg0KBQQAAgEIEgSUARQ8ChAKCAQAAgEInAgAEgSUARU7Co4D
CgQEAAICEgSeAQJAGv8CIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtFbmdp
bmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVdLCB3aGlj
aCB3aWxsIGJlY29tZQogdGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUKIFtFbmdpbmVdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVdJ3MgcmVzb3VyY2Ug
bmFtZS4KCiBUaGlzIGZpZWxkIG11c3QgY29uZm9ybSB0byBbUkZDLTEwMzRdKGh0dHBzOi8v
dG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMxMDM0KQogc3RhbmRhcmQgd2l0aCBhIGxlbmd0aCBs
aW1pdCBvZiA2MyBjaGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFuCiBJTlZBTElEX0FSR1VNRU5U
IGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACAgUSBJ4BAggKDQoFBAACAgESBJ4BCRIKDQoF
BAACAgMSBJ4BFRYKDQoFBAACAggSBJ4BFz8KEAoIBAACAgicCAASBJ4BGD4K7gEKAgQBEgal
AQCsAQEa3wEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBbRW5n
aW5lU2VydmljZS5DcmVhdGVFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5FbmdpbmVTZXJ2aWNlLkNyZWF0ZUVuZ2luZV0KIG9wZXJhdGlvbi4gVGhpcyB3
aWxsIGJlIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1l
dGFkYXRhCiBmaWVsZC4KCgsKAwQBARIEpQEIHAomCgQEAQIAEgSnAQIsGhggT3BlcmF0aW9u
IGNyZWF0ZSB0aW1lLgoKDQoFBAECAAYSBKcBAhsKDQoFBAECAAESBKcBHCcKDQoFBAECAAMS
BKcBKisKZAoEBAECARIEqwECLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0
aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoK
DQoFBAECAQYSBKsBAhsKDQoFBAECAQESBKsBHCcKDQoFBAECAQMSBKsBKisKiwEKAgQCEgax
AQDCAQEafSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRW5naW5lU2VydmljZS5EZWxldGVFbmdp
bmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVTZXJ2aWNl
LkRlbGV0ZUVuZ2luZV0KIG1ldGhvZC4KCgsKAwQCARIEsQEIGwqGBAoEBAICABIGvAECwQEE
GvUDIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YKIFtFbmdpbmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVdLCBzdWNoIGFzCiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0
aW9uX2lkfS9lbmdpbmVzL3tlbmdpbmVfaWR9YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90
IGhhdmUgcGVybWlzc2lvbiB0byBkZWxldGUgdGhlCiBbRW5naW5lXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lXSwgcmVnYXJkbGVzcyBvZgogd2hldGhl
ciBvciBub3QgaXQgZXhpc3RzLCBhIFBFUk1JU1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVy
bmVkLgoKIElmIHRoZSBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuRW5naW5lXSB0byBkZWxldGUgZG9lcwogbm90IGV4aXN0LCBhIE5PVF9GT1VORCBl
cnJvciBpcyByZXR1cm5lZC4KCg0KBQQCAgAFEgS8AQIICg0KBQQCAgABEgS8AQkNCg0KBQQC
AgADEgS8ARARCg8KBQQCAgAIEga8ARLBAQMKEAoIBAICAAicCAASBL0BBCoKEQoHBAICAAif
CBIGvgEEwAEFCu4BCgIEAxIGyAEAzwEBGt8BIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHBy
b2dyZXNzIG9mIHRoZQogW0VuZ2luZVNlcnZpY2UuRGVsZXRlRW5naW5lXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lU2VydmljZS5EZWxldGVFbmdpbmVd
CiBvcGVyYXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMEAwESBMgBCBwKJgoEBAMC
ABIEygECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQDAgAGEgTKAQIbCg0KBQQD
AgABEgTKARwnCg0KBQQDAgADEgTKASorCmQKBAQDAgESBM4BAiwaViBPcGVyYXRpb24gbGFz
dCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28g
dGhlCiBmaW5pc2ggdGltZS4KCg0KBQQDAgEGEgTOAQIbCg0KBQQDAgEBEgTOARwnCg0KBQQD
AgEDEgTOASorCoUBCgIEBBIG1AEA3gEBGncgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0VuZ2lu
ZVNlcnZpY2UuR2V0RW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRW5naW5lU2VydmljZS5HZXRFbmdpbmVdCiBtZXRob2QuCgoLCgMEBAESBNQBCBgKzgEK
BAQEAgASBtgBAt0BBBq9ASBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mCiBbRW5n
aW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lXSwgc3Vj
aCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0
aW9ucy97Y29sbGVjdGlvbl9pZH0vZW5naW5lcy97ZW5naW5lX2lkfWAuCgoNCgUEBAIABRIE
2AECCAoNCgUEBAIAARIE2AEJDQoNCgUEBAIAAxIE2AEQEQoPCgUEBAIACBIG2AES3QEDChAK
CAQEAgAInAgAEgTZAQQqChEKBwQEAgAInwgSBtoBBNwBBQqJAQoCBAUSBuMBAPYBARp7IFJl
cXVlc3QgbWVzc2FnZSBmb3IKIFtFbmdpbmVTZXJ2aWNlLkxpc3RFbmdpbmVzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lU2VydmljZS5MaXN0RW5naW5l
c10KIG1ldGhvZC4KCgsKAwQFARIE4wEIGgqFAQoEBAUCABIG5gEC6wEEGnUgUmVxdWlyZWQu
IFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH1gLgoK
DQoFBAUCAAUSBOYBAggKDQoFBAUCAAESBOYBCQ8KDQoFBAUCAAMSBOYBEhMKDwoFBAUCAAgS
BuYBFOsBAwoQCggEBQIACJwIABIE5wEEKgoRCgcEBQIACJ8IEgboAQTqAQUKKAoEBAUCARIE
7gECPxoaIE9wdGlvbmFsLiBOb3Qgc3VwcG9ydGVkLgoKDQoFBAUCAQUSBO4BAgcKDQoFBAUC
AQESBO4BCBEKDQoFBAUCAQMSBO4BFBUKDQoFBAUCAQgSBO4BFj4KEAoIBAUCAQicCAASBO4B
Fz0KKAoEBAUCAhIE8QECQRoaIE9wdGlvbmFsLiBOb3Qgc3VwcG9ydGVkLgoKDQoFBAUCAgUS
BPEBAggKDQoFBAUCAgESBPEBCRMKDQoFBAUCAgMSBPEBFhcKDQoFBAUCAggSBPEBGEAKEAoI
BAUCAgicCAASBPEBGT8KYwoEBAUCAxIE9QECPRpVIE9wdGlvbmFsLiBGaWx0ZXIgYnkgc29s
dXRpb24gdHlwZS4gRm9yIGV4YW1wbGU6CiBzb2x1dGlvbl90eXBlPVNPTFVUSU9OX1RZUEVf
U0VBUkNICgoNCgUEBQIDBRIE9QECCAoNCgUEBQIDARIE9QEJDwoNCgUEBQIDAxIE9QESEwoN
CgUEBQIDCBIE9QEUPAoQCggEBQIDCJwIABIE9QEVOwqKAQoCBAYSBvsBAIECARp8IFJlc3Bv
bnNlIG1lc3NhZ2UgZm9yCiBbRW5naW5lU2VydmljZS5MaXN0RW5naW5lc11bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkVuZ2luZVNlcnZpY2UuTGlzdEVuZ2luZXNd
CiBtZXRob2QuCgoLCgMEBgESBPsBCBsKWgoEBAYCABIE/QECHhpMIEFsbCB0aGUgY3VzdG9t
ZXIncyBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5n
aW5lXXMuCgoNCgUEBgIABBIE/QECCgoNCgUEBgIABhIE/QELEQoNCgUEBgIAARIE/QESGQoN
CgUEBgIAAxIE/QEcHQoeCgQEBgIBEgSAAgIdGhAgTm90IHN1cHBvcnRlZC4KCg0KBQQGAgEF
EgSAAgIICg0KBQQGAgEBEgSAAgkYCg0KBQQGAgEDEgSAAhscCosBCgIEBxIGhgIAmAIBGn0g
UmVxdWVzdCBtZXNzYWdlIGZvcgogW0VuZ2luZVNlcnZpY2UuVXBkYXRlRW5naW5lXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRW5naW5lU2VydmljZS5VcGRhdGVF
bmdpbmVdCiBtZXRob2QuCgoLCgMEBwESBIYCCBsKmAMKBAQHAgASBJACAj0aiQMgUmVxdWly
ZWQuIFRoZSBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
RW5naW5lXSB0bwogdXBkYXRlLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJt
aXNzaW9uIHRvIHVwZGF0ZSB0aGUKIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5FbmdpbmVdLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBp
dCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYg
dGhlIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Fbmdp
bmVdIHRvIHVwZGF0ZSBkb2VzCiBub3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJl
dHVybmVkLgoKDQoFBAcCAAYSBJACAggKDQoFBAcCAAESBJACCQ8KDQoFBAcCAAMSBJACEhMK
DQoFBAcCAAgSBJACFDwKEAoIBAcCAAicCAASBJACFTsK0wEKBAQHAgESBJcCAiwaxAEgSW5k
aWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtFbmdpbmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FbmdpbmVdIHRvIHVwZGF0ZS4KCiBJZiBh
biB1bnN1cHBvcnRlZCBvciB1bmtub3duIGZpZWxkIGlzIHByb3ZpZGVkLCBhbiBJTlZBTElE
X0FSR1VNRU5UIGVycm9yCiBpcyByZXR1cm5lZC4KCg0KBQQHAgEGEgSXAgIbCg0KBQQHAgEB
EgSXAhwnCg0KBQQHAgEDEgSXAiorCjoKAgQIEgabAgClAgEaLCBSZXF1ZXN0IGZvciBwYXVz
aW5nIHRyYWluaW5nIG9mIGFuIGVuZ2luZS4KCgsKAwQIARIEmwIIGgqrAQoEBAgCABIGnwIC
pAIEGpoBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgZW5naW5lIHRvIHBhdXNlLgogRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9p
ZH0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9L2VuZ2luZXMve2VuZ2luZV9pZH1gCgoN
CgUECAIABRIEnwICCAoNCgUECAIAARIEnwIJDQoNCgUECAIAAxIEnwIQEQoPCgUECAIACBIG
nwISpAIDChAKCAQIAgAInAgAEgSgAgQqChEKBwQIAgAInwgSBqECBKMCBQo7CgIECRIGqAIA
sgIBGi0gUmVxdWVzdCBmb3IgcmVzdW1pbmcgdHJhaW5pbmcgb2YgYW4gZW5naW5lLgoKCwoD
BAkBEgSoAggbCqwBCgQECQIAEgasAgKxAgQamwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRo
ZSBlbmdpbmUgdG8gcmVzdW1lLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJl
cn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9
L2VuZ2luZXMve2VuZ2luZV9pZH1gCgoNCgUECQIABRIErAICCAoNCgUECQIAARIErAIJDQoN
CgUECQIAAxIErAIQEQoPCgUECQIACBIGrAISsQIDChAKCAQJAgAInAgAEgStAgQqChEKBwQJ
AgAInwgSBq4CBLACBQqFAQoCBAoSBrYCAMACARp3IFJlcXVlc3QgdG8gbWFudWFsbHkgc3Rh
cnQgYSB0dW5pbmcgcHJvY2VzcyBub3cgKGluc3RlYWQgb2Ygd2FpdGluZyBmb3IKIHRoZSBw
ZXJpb2RpY2FsbHkgc2NoZWR1bGVkIHR1bmluZyB0byBoYXBwZW4pLgoKCwoDBAoBEgS2AggZ
CrMBCgQECgIAEga6AgK/AgQaogEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZSBlbmdpbmUgdG8gdHVuZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9
L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9l
bmdpbmVzL3tlbmdpbmVfaWR9YAoKDQoFBAoCAAUSBLoCAggKDQoFBAoCAAESBLoCCQ0KDQoF
BAoCAAMSBLoCEBEKDwoFBAoCAAgSBroCEr8CAwoQCggECgIACJwIABIEuwIEKgoRCgcECgIA
CJ8IEga8AgS+AgUKOgoCBAsSBsMCAM0CARosIE1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBh
IHR1bmUgb3BlcmF0aW9uLgoKCwoDBAsBEgTDAggaCsUBCgQECwIAEgbHAgLMAgQatAEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBlbmdpbmUgdGhhdCB0aGlzIHR1bmUg
YXBwbGllcyB0by4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0
aW9ucy97bG9jYXRpb25faWR9L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9lbmdpbmVz
L3tlbmdpbmVfaWR9YAoKDQoFBAsCAAUSBMcCAggKDQoFBAsCAAESBMcCCQ8KDQoFBAsCAAMS
BMcCEhMKDwoFBAsCAAgSBscCFMwCAwoQCggECwIACJwIABIEyAIEKgoRCgcECwIACJ8IEgbJ
AgTLAgUKOAoCBAwSBNACAB0aLCBSZXNwb25zZSBhc3NvY2lhdGVkIHdpdGggYSB0dW5lIG9w
ZXJhdGlvbi4KCgsKAwQMARIE0AIIGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest ===
    # Fields for CreateEngineRequest
    # Field: parent Type: 9 ()
    # Field: engine Type: 11 (.google.cloud.discoveryengine.v1alpha.Engine)
    # Field: engine_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineMetadata ===
    # Fields for CreateEngineMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineRequest ===
    # Fields for DeleteEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineMetadata ===
    # Fields for DeleteEngineMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::GetEngineRequest ===
    # Fields for GetEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesRequest ===
    # Fields for ListEnginesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesResponse ===
    # Fields for ListEnginesResponse
    # Field: engines Type: 11 (.google.cloud.discoveryengine.v1alpha.Engine)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::UpdateEngineRequest ===
    # Fields for UpdateEngineRequest
    # Field: engine Type: 11 (.google.cloud.discoveryengine.v1alpha.Engine)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::PauseEngineRequest ===
    # Fields for PauseEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::ResumeEngineRequest ===
    # Fields for ResumeEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineRequest ===
    # Fields for TuneEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineMetadata ===
    # Fields for TuneEngineMetadata
    # Field: engine Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineResponse ===
    # Fields for TuneEngineResponse

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::EngineService::EngineServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::EngineService::EngineServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::EngineService::EngineServiceClient

Client stub representing the remote C<EngineService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub create_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'CreateEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'DeleteEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::UpdateEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'UpdateEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine',
    });
}

sub get_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::GetEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'GetEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine',
    });
}

sub list_engines {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'ListEngines',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesResponse',
    });
}

sub pause_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::PauseEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'PauseEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine',
    });
}

sub resume_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::ResumeEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'ResumeEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine',
    });
}

sub tune_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'TuneEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::EngineService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/engine_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::EngineService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest->new({
        parent => $parent,
        engine => $engine,
        engine_id => $engine_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/engine_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest

Request for
[EngineService.CreateEngine][google.cloud.discoveryengine.v1alpha.EngineService.CreateEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Engine::Engine>)

Required. The [Engine][google.cloud.discoveryengine.v1alpha.Engine] to
create.

=item * C<< $msg->engine_id() >> / C<< $msg->engine_id($value) >>

Type: C<String>

Required. The ID to use for the
[Engine][google.cloud.discoveryengine.v1alpha.Engine], which will become
the final component of the
[Engine][google.cloud.discoveryengine.v1alpha.Engine]'s resource name.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
INVALID_ARGUMENT error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineMetadata

Metadata related to the progress of the
[EngineService.CreateEngine][google.cloud.discoveryengine.v1alpha.EngineService.CreateEngine]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineRequest

Request message for
[EngineService.DeleteEngine][google.cloud.discoveryengine.v1alpha.EngineService.DeleteEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Engine][google.cloud.discoveryengine.v1alpha.Engine], such as
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

If the caller does not have permission to delete the
[Engine][google.cloud.discoveryengine.v1alpha.Engine], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [Engine][google.cloud.discoveryengine.v1alpha.Engine] to delete does
not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineMetadata

Metadata related to the progress of the
[EngineService.DeleteEngine][google.cloud.discoveryengine.v1alpha.EngineService.DeleteEngine]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::GetEngineRequest

Request message for
[EngineService.GetEngine][google.cloud.discoveryengine.v1alpha.EngineService.GetEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Engine][google.cloud.discoveryengine.v1alpha.Engine], such as
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesRequest

Request message for
[EngineService.ListEngines][google.cloud.discoveryengine.v1alpha.EngineService.ListEngines]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Not supported.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Not supported.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter by solution type. For example:
solution_type=SOLUTION_TYPE_SEARCH

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesResponse

Response message for
[EngineService.ListEngines][google.cloud.discoveryengine.v1alpha.EngineService.ListEngines]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engines() >> / C<< $msg->engines($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Engine::Engine>)

All the customer's [Engine][google.cloud.discoveryengine.v1alpha.Engine]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Not supported.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::UpdateEngineRequest

Request message for
[EngineService.UpdateEngine][google.cloud.discoveryengine.v1alpha.EngineService.UpdateEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Engine::Engine>)

Required. The [Engine][google.cloud.discoveryengine.v1alpha.Engine] to
update.

If the caller does not have permission to update the
[Engine][google.cloud.discoveryengine.v1alpha.Engine], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [Engine][google.cloud.discoveryengine.v1alpha.Engine] to update does
not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Engine][google.cloud.discoveryengine.v1alpha.Engine] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::PauseEngineRequest

Request for pausing training of an engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the engine to pause.
Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::ResumeEngineRequest

Request for resuming training of an engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the engine to resume.
Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineRequest

Request to manually start a tuning process now (instead of waiting for
the periodically scheduled tuning to happen).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the engine to tune.
Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineMetadata

Metadata associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<String>

Required. The resource name of the engine that this tune applies to.
Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineResponse

Response associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::EngineService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
