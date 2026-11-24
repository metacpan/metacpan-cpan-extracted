package Google::Cloud::Discoveryengine::V1beta::EngineService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Engine };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9lbmdpbmVfc2VydmljZS5w
cm90bxIjZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjBnb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9lbmdpbmUucHJvdG8aHmdvb2dsZS9p
YW0vdjEvaWFtX3BvbGljeS5wcm90bxoaZ29vZ2xlL2lhbS92MS9wb2xpY3kucHJvdG8aI2dv
b2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIswBChNDcmVhdGVFbmdpbmVSZXF1ZXN0EkkKBnBhcmVu
dBgBIAEoCUIx4EEC+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVj
dGlvblIGcGFyZW50EkgKBmVuZ2luZRgCIAEoCzIrLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkVuZ2luZUID4EECUgZlbmdpbmUSIAoJZW5naW5lX2lkGAMgASgJQgPg
QQJSCGVuZ2luZUlkIpABChRDcmVhdGVFbmdpbmVNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgB
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRl
X3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lIlgK
E0RlbGV0ZUVuZ2luZVJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt4EEC+kEnCiVkaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb20vRW5naW5lUgRuYW1lIpABChREZWxldGVFbmdpbmVNZXRh
ZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
CmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wUgp1cGRhdGVUaW1lIlUKEEdldEVuZ2luZVJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt
4EEC+kEnCiVkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRW5naW5lUgRuYW1lIsIB
ChJMaXN0RW5naW5lc1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWRpc2NvdmVy
eWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSIAoJcGFnZV9zaXpl
GAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRv
a2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIihAEKE0xpc3RFbmdpbmVzUmVzcG9u
c2USRQoHZW5naW5lcxgBIAMoCzIrLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkVuZ2luZVIHZW5naW5lcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4inAEKE1VwZGF0ZUVuZ2luZVJlcXVlc3QSSAoGZW5naW5lGAEgASgLMisuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lQgPgQQJSBmVuZ2luZRI7Cgt1
cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1h
c2siVwoSUGF1c2VFbmdpbmVSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0VuZ2luZVIEbmFtZSJYChNSZXN1bWVFbmdpbmVS
ZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0VuZ2luZVIEbmFtZSJWChFUdW5lRW5naW5lUmVxdWVzdBJBCgRuYW1lGAEgASgJ
Qi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9FbmdpbmVSBG5hbWUi
WwoSVHVuZUVuZ2luZU1ldGFkYXRhEkUKBmVuZ2luZRgBIAEoCUIt4EEC+kEnCiVkaXNjb3Zl
cnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRW5naW5lUgZlbmdpbmUiFAoSVHVuZUVuZ2luZVJl
c3BvbnNlMo0TCg1FbmdpbmVTZXJ2aWNlEroCCgxDcmVhdGVFbmdpbmUSOC5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DcmVhdGVFbmdpbmVSZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiLQAYLT5JMCRyI9L3YxYmV0YS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKn0vZW5naW5lczoGZW5naW5l2kEXcGFy
ZW50LGVuZ2luZSxlbmdpbmVfaWTKQWYKKmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkVuZ2luZRI4Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ3Jl
YXRlRW5naW5lTWV0YWRhdGESigIKDERlbGV0ZUVuZ2luZRI4Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkRlbGV0ZUVuZ2luZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uIqABgtPkkwI/Kj0vdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyp92kEEbmFtZcpBUQoVZ29vZ2xlLnBy
b3RvYnVmLkVtcHR5Ejhnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EZWxl
dGVFbmdpbmVNZXRhZGF0YRLgAQoMVXBkYXRlRW5naW5lEjguZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuVXBkYXRlRW5naW5lUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZSJpgtPkkwJOMkQvdjFiZXRhL3tlbmdpbmUu
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qfToG
ZW5naW5l2kESZW5naW5lLHVwZGF0ZV9tYXNrEr0BCglHZXRFbmdpbmUSNS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5HZXRFbmdpbmVSZXF1ZXN0GisuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lIkyC0+STAj8SPS92MWJldGEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn3aQQRu
YW1lEtABCgtMaXN0RW5naW5lcxI3Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkxpc3RFbmdpbmVzUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkxpc3RFbmdpbmVzUmVzcG9uc2UiToLT5JMCPxI9L3YxYmV0YS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKn0vZW5naW5lc9pBBnBhcmVudBLK
AQoLUGF1c2VFbmdpbmUSNy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Q
YXVzZUVuZ2luZVJlcXVlc3QaKy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5FbmdpbmUiVYLT5JMCSCJDL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NvbGxlY3Rpb25zLyovZW5naW5lcy8qfTpwYXVzZToBKtpBBG5hbWUSzQEKDFJlc3VtZUVu
Z2luZRI4Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlc3VtZUVuZ2lu
ZVJlcXVlc3QaKy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmUi
VoLT5JMCSSJEL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rp
b25zLyovZW5naW5lcy8qfTpyZXN1bWU6ASraQQRuYW1lEuQBCgpUdW5lRW5naW5lEjYuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVHVuZUVuZ2luZVJlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn+C0+STAkciQi92MWJldGEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn06dHVuZToBKtpB
BG5hbWXKQSgKElR1bmVFbmdpbmVSZXNwb25zZRISVHVuZUVuZ2luZU1ldGFkYXRhEqwBCgxH
ZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29n
bGUuaWFtLnYxLlBvbGljeSJhgtPkkwJQEk4vdjFiZXRhL3tyZXNvdXJjZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qfTpnZXRJYW1Qb2xpY3naQQhy
ZXNvdXJjZRK2AQoMU2V0SWFtUG9saWN5EiIuZ29vZ2xlLmlhbS52MS5TZXRJYW1Qb2xpY3lS
ZXF1ZXN0GhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3kia4LT5JMCUyJOL3YxYmV0YS97cmVzb3Vy
Y2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn06c2V0
SWFtUG9saWN5OgEq2kEPcmVzb3VyY2UscG9saWN5Gs8BykEeZGlzY292ZXJ5ZW5naW5lLmdv
b2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQt
cGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zlcnllbmdp
bmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5
ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQpkCCidjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGFCEkVuZ2luZVNlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUuY29t
L2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292
ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5
RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gIm
R29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKrFgKBxIFDgD5Ah0KvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAJgoJ
CgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA6CgkKAgMFEgMXACgK
CQoCAwYSAxgAJAoJCgIDBxIDGQAtCgkKAgMIEgMaACUKCQoCAwkSAxsAKgoJCgIDChIDHAAp
CggKAQgSAx4AQAoJCgIIJRIDHgBACggKAQgSAx8AaAoJCgIICxIDHwBoCggKAQgSAyAAIgoJ
CgIIChIDIAAiCggKAQgSAyEAMwoJCgIICBIDIQAzCggKAQgSAyIAQAoJCgIIARIDIgBACggK
AQgSAyMALQoJCgIIJBIDIwAtCggKAQgSAyQAQAoJCgIIKRIDJABACggKAQgSAyUAPwoJCgII
LRIDJQA/CmgKAgYAEgUpAKwBARpbIFNlcnZpY2UgZm9yIG1hbmFnaW5nIFtFbmdpbmVdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZV0KIGNvbmZpZ3VyYXRp
b24uCgoKCgMGAAESAykIFQoKCgMGAAMSAyoCRgoMCgUGAAOZCBIDKgJGCgsKAwYAAxIEKwIu
SgoNCgUGAAOaCBIEKwIuSgpQCgQGAAIAEgQxAjsDGkIgQ3JlYXRlcyBhbiBbRW5naW5lXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdLgoKDAoFBgACAAES
AzEGEgoMCgUGAAIAAhIDMRMmCgwKBQYAAgADEgMxMU0KDQoFBgACAAQSBDIENQYKEQoJBgAC
AASwyrwiEgQyBDUGCgwKBQYAAgAEEgM2BEUKDwoIBgACAASbCAASAzYERQoNCgUGAAIABBIE
NwQ6BgoPCgcGAAIABJkIEgQ3BDoGClAKBAYAAgESBD4CRwMaQiBEZWxldGVzIGFuIFtFbmdp
bmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZV0uCgoMCgUG
AAIBARIDPgYSCgwKBQYAAgECEgM+EyYKDAoFBgACAQMSAz4xTQoNCgUGAAIBBBIEPwRBBgoR
CgkGAAIBBLDKvCISBD8EQQYKDAoFBgACAQQSA0IEMgoPCggGAAIBBJsIABIDQgQyCg0KBQYA
AgEEEgRDBEYGCg8KBwYAAgEEmQgSBEMERgYKTwoEBgACAhIESgJQAxpBIFVwZGF0ZXMgYW4g
W0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lXQoK
DAoFBgACAgESA0oGEgoMCgUGAAICAhIDShMmCgwKBQYAAgIDEgNKMTcKDQoFBgACAgQSBEsE
TgYKEQoJBgACAgSwyrwiEgRLBE4GCgwKBQYAAgIEEgNPBEAKDwoIBgACAgSbCAASA08EQApN
CgQGAAIDEgRTAlgDGj8gR2V0cyBhbiBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5FbmdpbmVdLgoKDAoFBgACAwESA1MGDwoMCgUGAAIDAhIDUxAgCgwK
BQYAAgMDEgNTKzEKDQoFBgACAwQSBFQEVgYKEQoJBgACAwSwyrwiEgRUBFYGCgwKBQYAAgME
EgNXBDIKDwoIBgACAwSbCAASA1cEMgpxCgQGAAIEEgRcAmEDGmMgTGlzdHMgYWxsIHRoZSBb
RW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdcwog
YXNzb2NpYXRlZCB3aXRoIHRoZSBwcm9qZWN0LgoKDAoFBgACBAESA1wGEQoMCgUGAAIEAhID
XBIkCgwKBQYAAgQDEgNcL0IKDQoFBgACBAQSBF0EXwYKEQoJBgACBASwyrwiEgRdBF8GCgwK
BQYAAgQEEgNgBDQKDwoIBgACBASbCAASA2AENAqyAgoEBgACBRIEZwJtAxqjAiBQYXVzZXMg
dGhlIHRyYWluaW5nIG9mIGFuIGV4aXN0aW5nCiBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdLiBPbmx5IGFwcGxpY2FibGUgaWYKIFtTb2x1
dGlvblR5cGVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNvbHV0aW9u
VHlwZV0gaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Tb2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9SRUNP
TU1FTkRBVElPTl0uCgoMCgUGAAIFARIDZwYRCgwKBQYAAgUCEgNnEiQKDAoFBgACBQMSA2cv
NQoNCgUGAAIFBBIEaARrBgoRCgkGAAIFBLDKvCISBGgEawYKDAoFBgACBQQSA2wEMgoPCggG
AAIFBJsIABIDbAQyCrMCCgQGAAIGEgRzAnkDGqQCIFJlc3VtZXMgdGhlIHRyYWluaW5nIG9m
IGFuIGV4aXN0aW5nCiBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5FbmdpbmVdLiBPbmx5IGFwcGxpY2FibGUgaWYKIFtTb2x1dGlvblR5cGVdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNvbHV0aW9uVHlwZV0gaXMKIFtTT0xV
VElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5Tb2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPTl0uCgoM
CgUGAAIGARIDcwYSCgwKBQYAAgYCEgNzEyYKDAoFBgACBgMSA3MxNwoNCgUGAAIGBBIEdAR3
BgoRCgkGAAIGBLDKvCISBHQEdwYKDAoFBgACBgQSA3gEMgoPCggGAAIGBJsIABIDeAQyCqIC
CgQGAAIHEgV/AokBAxqSAiBUdW5lcyBhbiBleGlzdGluZyBbRW5naW5lXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdLgogT25seSBhcHBsaWNhYmxlIGlm
CiBbU29sdXRpb25UeXBlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5T
b2x1dGlvblR5cGVdIGlzCiBbU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPTl1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZ
UEVfUkVDT01NRU5EQVRJT05dLgoKDAoFBgACBwESA38GEAoMCgUGAAIHAhIDfxEiCgwKBQYA
AgcDEgN/LUkKDwoFBgACBwQSBoABBIMBBgoTCgkGAAIHBLDKvCISBoABBIMBBgoNCgUGAAIH
BBIEhAEEMgoQCggGAAIHBJsIABIEhAEEMgoPCgUGAAIHBBIGhQEEiAEGChEKBwYAAgcEmQgS
BoUBBIgBBgqOAgoEBgACCBIGjwEClQEDGv0BIEdldHMgdGhlIElBTSBhY2Nlc3MgY29udHJv
bCBwb2xpY3kgZm9yIGFuCiBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5FbmdpbmVdLiBBIGBOT1RfRk9VTkRgIGVycm9yCiBpcyByZXR1cm5lZCBpZiB0
aGUgcmVzb3VyY2UgZG9lcyBub3QgZXhpc3QuIEFuIGVtcHR5IHBvbGljeSBpcyByZXR1cm5l
ZCBpZgogdGhlIHJlc291cmNlIGV4aXN0cyBidXQgZG9lcyBub3QgaGF2ZSBhIHBvbGljeSBz
ZXQgb24gaXQuCgoNCgUGAAIIARIEjwEGEgoNCgUGAAIIAhIEjwETNAoNCgUGAAIIAxIEkAEP
IwoPCgUGAAIIBBIGkQEEkwEGChMKCQYAAggEsMq8IhIGkQEEkwEGCg0KBQYAAggEEgSUAQQ2
ChAKCAYAAggEmwgAEgSUAQQ2CtMECgQGAAIJEgakAQKrAQMawgQgU2V0cyB0aGUgSUFNIGFj
Y2VzcyBjb250cm9sIHBvbGljeSBmb3IgYW4KIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZV0uIEEgYE5PVF9GT1VORGAgZXJyb3IKIGlzIHJl
dHVybmVkIGlmIHRoZSByZXNvdXJjZSBkb2VzIG5vdCBleGlzdC4KCiAqKkltcG9ydGFudDoq
KiBXaGVuIHNldHRpbmcgYSBwb2xpY3kgZGlyZWN0bHkgb24gYW4gRW5naW5lIHJlc291cmNl
LAogdGhlIG9ubHkgcmVjb21tZW5kZWQgcm9sZXMgaW4gdGhlIGJpbmRpbmdzIGFyZToKIGBy
b2xlcy9kaXNjb3ZlcnllbmdpbmUuYWRtaW5gLAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS5h
Z2VudHNwYWNlQWRtaW5gLAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS51c2VyYCwKIGByb2xl
cy9kaXNjb3ZlcnllbmdpbmUuYWdlbnRzcGFjZVVzZXJgLAogYHJvbGVzL2Rpc2NvdmVyeWVu
Z2luZS52aWV3ZXJgLAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS5hZ2VudHNwYWNlVmlld2Vy
YC4KIEF0dGVtcHRpbmcgdG8gZ3JhbnQgYW55IG90aGVyIHJvbGUgd2lsbCByZXN1bHQgaW4g
YSB3YXJuaW5nIGluIGxvZ2dpbmcuCgoNCgUGAAIJARIEpAEGEgoNCgUGAAIJAhIEpAETNAoN
CgUGAAIJAxIEpQEPIwoPCgUGAAIJBBIGpgEEqQEGChMKCQYAAgkEsMq8IhIGpgEEqQEGCg0K
BQYAAgkEEgSqAQQ9ChAKCAYAAgkEmwgAEgSqAQQ9CoIBCgIEABIGsQEAyAEBGnQgUmVxdWVz
dCBmb3IKIFtFbmdpbmVTZXJ2aWNlLkNyZWF0ZUVuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuRW5naW5lU2VydmljZS5DcmVhdGVFbmdpbmVdCiBtZXRob2Qu
CgoLCgMEAAESBLEBCBsKggEKBAQAAgASBrQBArkBBBpyIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259YC4KCg0KBQQAAgAFEgS0AQII
Cg0KBQQAAgABEgS0AQkPCg0KBQQAAgADEgS0ARITCg8KBQQAAgAIEga0ARS5AQMKEAoIBAAC
AAicCAASBLUBBCoKEQoHBAACAAifCBIGtgEEuAEFCl4KBAQAAgESBL0BAj0aUCBSZXF1aXJl
ZC4gVGhlIFtFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkVu
Z2luZV0gdG8KIGNyZWF0ZS4KCg0KBQQAAgEGEgS9AQIICg0KBQQAAgEBEgS9AQkPCg0KBQQA
AgEDEgS9ARITCg0KBQQAAgEIEgS9ARQ8ChAKCAQAAgEInAgAEgS9ARU7CowDCgQEAAICEgTH
AQJAGv0CIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtFbmdpbmVdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZV0sIHdoaWNoIHdpbGwgYmVj
b21lIHRoZQogZmluYWwgY29tcG9uZW50IG9mIHRoZQogW0VuZ2luZV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lXSdzIHJlc291cmNlIG5hbWUuCgogVGhp
cyBmaWVsZCBtdXN0IGNvbmZvcm0gdG8gW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYu
b3JnL2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdpdGggYSBsZW5ndGggbGltaXQgb2YgNjMg
Y2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbgogSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyBy
ZXR1cm5lZC4KCg0KBQQAAgIFEgTHAQIICg0KBQQAAgIBEgTHAQkSCg0KBQQAAgIDEgTHARUW
Cg0KBQQAAgIIEgTHARc/ChAKCAQAAgIInAgAEgTHARg+Cu0BCgIEARIGzgEA1QEBGt4BIE1l
dGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZQogW0VuZ2luZVNlcnZpY2Uu
Q3JlYXRlRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Fbmdp
bmVTZXJ2aWNlLkNyZWF0ZUVuZ2luZV0KIG9wZXJhdGlvbi4gVGhpcyB3aWxsIGJlIHJldHVy
bmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVs
ZC4KCgsKAwQBARIEzgEIHAomCgQEAQIAEgTQAQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1l
LgoKDQoFBAECAAYSBNABAhsKDQoFBAECAAESBNABHCcKDQoFBAECAAMSBNABKisKZAoEBAEC
ARIE1AECLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9u
IGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAECAQYSBNQB
AhsKDQoFBAECAQESBNQBHCcKDQoFBAECAQMSBNQBKisKigEKAgQCEgbaAQDrAQEafCBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbRW5naW5lU2VydmljZS5EZWxldGVFbmdpbmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZVNlcnZpY2UuRGVsZXRlRW5naW5l
XQogbWV0aG9kLgoKCwoDBAIBEgTaAQgbCoMECgQEAgIAEgblAQLqAQQa8gMgUmVxdWlyZWQu
IEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuRW5naW5lXSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZW5naW5l
cy97ZW5naW5lX2lkfWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Np
b24gdG8gZGVsZXRlIHRoZQogW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuRW5naW5lXSwgcmVnYXJkbGVzcyBvZiB3aGV0aGVyCiBvciBub3QgaXQgZXhp
c3RzLCBhIFBFUk1JU1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRoZSBb
RW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdIHRv
IGRlbGV0ZSBkb2VzCiBub3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJldHVybmVk
LgoKDQoFBAICAAUSBOUBAggKDQoFBAICAAESBOUBCQ0KDQoFBAICAAMSBOUBEBEKDwoFBAIC
AAgSBuUBEuoBAwoQCggEAgIACJwIABIE5gEEKgoRCgcEAgIACJ8IEgbnAQTpAQUK7QEKAgQD
EgbxAQD4AQEa3gEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBb
RW5naW5lU2VydmljZS5EZWxldGVFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkVuZ2luZVNlcnZpY2UuRGVsZXRlRW5naW5lXQogb3BlcmF0aW9uLiBUaGlz
IHdpbGwgYmUgcmV0dXJuZWQgYnkgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24u
bWV0YWRhdGEKIGZpZWxkLgoKCwoDBAMBEgTxAQgcCiYKBAQDAgASBPMBAiwaGCBPcGVyYXRp
b24gY3JlYXRlIHRpbWUuCgoNCgUEAwIABhIE8wECGwoNCgUEAwIAARIE8wEcJwoNCgUEAwIA
AxIE8wEqKwpkCgQEAwIBEgT3AQIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElm
IHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUu
CgoNCgUEAwIBBhIE9wECGwoNCgUEAwIBARIE9wEcJwoNCgUEAwIBAxIE9wEqKwqEAQoCBAQS
Bv0BAIcCARp2IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtFbmdpbmVTZXJ2aWNlLkdldEVuZ2lu
ZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lU2VydmljZS5H
ZXRFbmdpbmVdCiBtZXRob2QuCgoLCgMEBAESBP0BCBgKzQEKBAQEAgASBoECAoYCBBq8ASBS
ZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mCiBbRW5naW5lXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdLCBzdWNoIGFzCiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lk
fS9lbmdpbmVzL3tlbmdpbmVfaWR9YC4KCg0KBQQEAgAFEgSBAgIICg0KBQQEAgABEgSBAgkN
Cg0KBQQEAgADEgSBAhARCg8KBQQEAgAIEgaBAhKGAgMKEAoIBAQCAAicCAASBIICBCoKEQoH
BAQCAAifCBIGgwIEhQIFCogBCgIEBRIGjAIAnwIBGnogUmVxdWVzdCBtZXNzYWdlIGZvcgog
W0VuZ2luZVNlcnZpY2UuTGlzdEVuZ2luZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkVuZ2luZVNlcnZpY2UuTGlzdEVuZ2luZXNdCiBtZXRob2QuCgoLCgMEBQES
BIwCCBoKhQEKBAQFAgASBo8CApQCBBp1IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
IG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9YC4KCg0KBQQFAgAFEgSPAgIICg0KBQQF
AgABEgSPAgkPCg0KBQQFAgADEgSPAhITCg8KBQQFAgAIEgaPAhSUAgMKEAoIBAUCAAicCAAS
BJACBCoKEQoHBAUCAAifCBIGkQIEkwIFCigKBAQFAgESBJcCAj8aGiBPcHRpb25hbC4gTm90
IHN1cHBvcnRlZC4KCg0KBQQFAgEFEgSXAgIHCg0KBQQFAgEBEgSXAggRCg0KBQQFAgEDEgSX
AhQVCg0KBQQFAgEIEgSXAhY+ChAKCAQFAgEInAgAEgSXAhc9CigKBAQFAgISBJoCAkEaGiBP
cHRpb25hbC4gTm90IHN1cHBvcnRlZC4KCg0KBQQFAgIFEgSaAgIICg0KBQQFAgIBEgSaAgkT
Cg0KBQQFAgIDEgSaAhYXCg0KBQQFAgIIEgSaAhhAChAKCAQFAgIInAgAEgSaAhk/CmMKBAQF
AgMSBJ4CAj0aVSBPcHRpb25hbC4gRmlsdGVyIGJ5IHNvbHV0aW9uIHR5cGUuIEZvciBleGFt
cGxlOgogc29sdXRpb25fdHlwZT1TT0xVVElPTl9UWVBFX1NFQVJDSAoKDQoFBAUCAwUSBJ4C
AggKDQoFBAUCAwESBJ4CCQ8KDQoFBAUCAwMSBJ4CEhMKDQoFBAUCAwgSBJ4CFDwKEAoIBAUC
AwicCAASBJ4CFTsKiQEKAgQGEgakAgCqAgEaeyBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0Vu
Z2luZVNlcnZpY2UuTGlzdEVuZ2luZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkVuZ2luZVNlcnZpY2UuTGlzdEVuZ2luZXNdCiBtZXRob2QuCgoLCgMEBgESBKQC
CBsKWQoEBAYCABIEpgICHhpLIEFsbCB0aGUgY3VzdG9tZXIncyBbRW5naW5lXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FbmdpbmVdcy4KCg0KBQQGAgAEEgSmAgIK
Cg0KBQQGAgAGEgSmAgsRCg0KBQQGAgABEgSmAhIZCg0KBQQGAgADEgSmAhwdCh4KBAQGAgES
BKkCAh0aECBOb3Qgc3VwcG9ydGVkLgoKDQoFBAYCAQUSBKkCAggKDQoFBAYCAQESBKkCCRgK
DQoFBAYCAQMSBKkCGxwKigEKAgQHEgavAgDBAgEafCBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
RW5naW5lU2VydmljZS5VcGRhdGVFbmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkVuZ2luZVNlcnZpY2UuVXBkYXRlRW5naW5lXQogbWV0aG9kLgoKCwoDBAcB
EgSvAggbCpUDCgQEBwIAEgS5AgI9GoYDIFJlcXVpcmVkLiBUaGUgW0VuZ2luZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lXSB0bwogdXBkYXRlLgoKIElm
IHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZSB0aGUKIFtF
bmdpbmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkVuZ2luZV0sIHJl
Z2FyZGxlc3Mgb2Ygd2hldGhlcgogb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RF
TklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0VuZ2luZV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lXSB0byB1cGRhdGUgZG9lcwogbm90IGV4
aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQHAgAGEgS5AgIICg0K
BQQHAgABEgS5AgkPCg0KBQQHAgADEgS5AhITCg0KBQQHAgAIEgS5AhQ8ChAKCAQHAgAInAgA
EgS5AhU7CtIBCgQEBwIBEgTAAgIsGsMBIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhl
IHByb3ZpZGVkCiBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5FbmdpbmVdIHRvIHVwZGF0ZS4KCiBJZiBhbiB1bnN1cHBvcnRlZCBvciB1bmtub3duIGZp
ZWxkIGlzIHByb3ZpZGVkLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yCiBpcyByZXR1cm5l
ZC4KCg0KBQQHAgEGEgTAAgIbCg0KBQQHAgEBEgTAAhwnCg0KBQQHAgEDEgTAAiorCjoKAgQI
EgbEAgDOAgEaLCBSZXF1ZXN0IGZvciBwYXVzaW5nIHRyYWluaW5nIG9mIGFuIGVuZ2luZS4K
CgsKAwQIARIExAIIGgqhAQoEBAgCABIGyAICzQIEGpABIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgZW5naW5lIHRvIHBhdXNlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZW5naW5l
cy97ZW5naW5lX2lkfWAKCg0KBQQIAgAFEgTIAgIICg0KBQQIAgABEgTIAgkNCg0KBQQIAgAD
EgTIAhARCg8KBQQIAgAIEgbIAhLNAgMKEAoIBAgCAAicCAASBMkCBCoKEQoHBAgCAAifCBIG
ygIEzAIFCjsKAgQJEgbRAgDbAgEaLSBSZXF1ZXN0IGZvciByZXN1bWluZyB0cmFpbmluZyBv
ZiBhbiBlbmdpbmUuCgoLCgMECQESBNECCBsKogEKBAQJAgASBtUCAtoCBBqRASBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIGVuZ2luZSB0byByZXN1bWUuCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0
aW9uX2lkfS9lbmdpbmVzL3tlbmdpbmVfaWR9YAoKDQoFBAkCAAUSBNUCAggKDQoFBAkCAAES
BNUCCQ0KDQoFBAkCAAMSBNUCEBEKDwoFBAkCAAgSBtUCEtoCAwoQCggECQIACJwIABIE1gIE
KgoRCgcECQIACJ8IEgbXAgTZAgUKhQEKAgQKEgbfAgDpAgEadyBSZXF1ZXN0IHRvIG1hbnVh
bGx5IHN0YXJ0IGEgdHVuaW5nIHByb2Nlc3Mgbm93IChpbnN0ZWFkIG9mIHdhaXRpbmcgZm9y
CiB0aGUgcGVyaW9kaWNhbGx5IHNjaGVkdWxlZCB0dW5pbmcgdG8gaGFwcGVuKS4KCgsKAwQK
ARIE3wIIGQqpAQoEBAoCABIG4wIC6AIEGpgBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgZW5naW5lIHRvIHR1bmUuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9lbmdp
bmVzL3tlbmdpbmVfaWR9YAoKDQoFBAoCAAUSBOMCAggKDQoFBAoCAAESBOMCCQ0KDQoFBAoC
AAMSBOMCEBEKDwoFBAoCAAgSBuMCEugCAwoQCggECgIACJwIABIE5AIEKgoRCgcECgIACJ8I
EgblAgTnAgUKOgoCBAsSBuwCAPYCARosIE1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBhIHR1
bmUgb3BlcmF0aW9uLgoKCwoDBAsBEgTsAggaCrsBCgQECwIAEgbwAgL1AgQaqgEgUmVxdWly
ZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBlbmdpbmUgdGhhdCB0aGlzIHR1bmUgYXBw
bGllcyB0by4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9L2VuZ2luZXMve2VuZ2luZV9pZH1g
CgoNCgUECwIABRIE8AICCAoNCgUECwIAARIE8AIJDwoNCgUECwIAAxIE8AISEwoPCgUECwIA
CBIG8AIU9QIDChAKCAQLAgAInAgAEgTxAgQqChEKBwQLAgAInwgSBvICBPQCBQo4CgIEDBIE
+QIAHRosIFJlc3BvbnNlIGFzc29jaWF0ZWQgd2l0aCBhIHR1bmUgb3BlcmF0aW9uLgoKCwoD
BAwBEgT5AggaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest ===
    # Fields for CreateEngineRequest
    # Field: parent Type: 9 ()
    # Field: engine Type: 11 (.google.cloud.discoveryengine.v1beta.Engine)
    # Field: engine_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineMetadata ===
    # Fields for CreateEngineMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::DeleteEngineRequest ===
    # Fields for DeleteEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::DeleteEngineMetadata ===
    # Fields for DeleteEngineMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::GetEngineRequest ===
    # Fields for GetEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::ListEnginesRequest ===
    # Fields for ListEnginesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::ListEnginesResponse ===
    # Fields for ListEnginesResponse
    # Field: engines Type: 11 (.google.cloud.discoveryengine.v1beta.Engine)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::UpdateEngineRequest ===
    # Fields for UpdateEngineRequest
    # Field: engine Type: 11 (.google.cloud.discoveryengine.v1beta.Engine)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::PauseEngineRequest ===
    # Fields for PauseEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::ResumeEngineRequest ===
    # Fields for ResumeEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineRequest ===
    # Fields for TuneEngineRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineMetadata ===
    # Fields for TuneEngineMetadata
    # Field: engine Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineResponse ===
    # Fields for TuneEngineResponse

# === Service Client: Google::Cloud::Discoveryengine::V1beta::EngineService::EngineServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::EngineService::EngineServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::EngineService::EngineServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'CreateEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::DeleteEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'DeleteEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::UpdateEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'UpdateEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Engine::Engine',
    });
}

sub get_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::GetEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'GetEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Engine::Engine',
    });
}

sub list_engines {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::ListEnginesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'ListEngines',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::EngineService::ListEnginesResponse',
    });
}

sub pause_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::PauseEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'PauseEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Engine::Engine',
    });
}

sub resume_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::ResumeEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'ResumeEngine',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Engine::Engine',
    });
}

sub tune_engine {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'TuneEngine',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
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
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::EngineService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/engine_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::EngineService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest->new({
        parent => $parent,
        engine => $engine,
        engine_id => $engine_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/engine_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest

Request for
[EngineService.CreateEngine][google.cloud.discoveryengine.v1beta.EngineService.CreateEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Engine::Engine>)

Required. The [Engine][google.cloud.discoveryengine.v1beta.Engine] to
create.

=item * C<< $msg->engine_id() >> / C<< $msg->engine_id($value) >>

Type: C<String>

Required. The ID to use for the
[Engine][google.cloud.discoveryengine.v1beta.Engine], which will become the
final component of the
[Engine][google.cloud.discoveryengine.v1beta.Engine]'s resource name.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
INVALID_ARGUMENT error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineMetadata

Metadata related to the progress of the
[EngineService.CreateEngine][google.cloud.discoveryengine.v1beta.EngineService.CreateEngine]
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

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::DeleteEngineRequest

Request message for
[EngineService.DeleteEngine][google.cloud.discoveryengine.v1beta.EngineService.DeleteEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Engine][google.cloud.discoveryengine.v1beta.Engine], such as
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

If the caller does not have permission to delete the
[Engine][google.cloud.discoveryengine.v1beta.Engine], regardless of whether
or not it exists, a PERMISSION_DENIED error is returned.

If the [Engine][google.cloud.discoveryengine.v1beta.Engine] to delete does
not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::DeleteEngineMetadata

Metadata related to the progress of the
[EngineService.DeleteEngine][google.cloud.discoveryengine.v1beta.EngineService.DeleteEngine]
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

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::GetEngineRequest

Request message for
[EngineService.GetEngine][google.cloud.discoveryengine.v1beta.EngineService.GetEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Engine][google.cloud.discoveryengine.v1beta.Engine], such as
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::ListEnginesRequest

Request message for
[EngineService.ListEngines][google.cloud.discoveryengine.v1beta.EngineService.ListEngines]
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

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::ListEnginesResponse

Response message for
[EngineService.ListEngines][google.cloud.discoveryengine.v1beta.EngineService.ListEngines]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engines() >> / C<< $msg->engines($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Engine::Engine>)

All the customer's [Engine][google.cloud.discoveryengine.v1beta.Engine]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Not supported.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::UpdateEngineRequest

Request message for
[EngineService.UpdateEngine][google.cloud.discoveryengine.v1beta.EngineService.UpdateEngine]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Engine::Engine>)

Required. The [Engine][google.cloud.discoveryengine.v1beta.Engine] to
update.

If the caller does not have permission to update the
[Engine][google.cloud.discoveryengine.v1beta.Engine], regardless of whether
or not it exists, a PERMISSION_DENIED error is returned.

If the [Engine][google.cloud.discoveryengine.v1beta.Engine] to update does
not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Engine][google.cloud.discoveryengine.v1beta.Engine] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::PauseEngineRequest

Request for pausing training of an engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the engine to pause.
Format:
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::ResumeEngineRequest

Request for resuming training of an engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the engine to resume.
Format:
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineRequest

Request to manually start a tuning process now (instead of waiting for
the periodically scheduled tuning to happen).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the engine to tune.
Format:
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineMetadata

Metadata associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<String>

Required. The resource name of the engine that this tune applies to.
Format:
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EngineService::TuneEngineResponse

Response associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::EngineService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
