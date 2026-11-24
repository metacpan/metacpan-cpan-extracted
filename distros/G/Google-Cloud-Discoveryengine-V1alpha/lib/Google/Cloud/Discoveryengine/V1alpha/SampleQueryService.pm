package Google::Cloud::Discoveryengine::V1alpha::SampleQueryService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1alpha::SampleQuery };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2FtcGxlX3F1ZXJ5X3Nl
cnZpY2UucHJvdG8SJGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aOGdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBoYS9pbXBvcnRfY29uZmln
LnByb3RvGjdnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2FtcGxlX3F1
ZXJ5LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xl
L3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90
byJfChVHZXRTYW1wbGVRdWVyeVJlcXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCipkaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxlUXVlcnlSBG5hbWUipQEKGExpc3RT
YW1wbGVRdWVyaWVzUmVxdWVzdBJNCgZwYXJlbnQYASABKAlCNeBBAvpBLwotZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NhbXBsZVF1ZXJ5U2V0UgZwYXJlbnQSGwoJcGFnZV9z
aXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4inQEK
GUxpc3RTYW1wbGVRdWVyaWVzUmVzcG9uc2USWAoOc2FtcGxlX3F1ZXJpZXMYASADKAsyMS5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlSDXNhbXBs
ZVF1ZXJpZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIvEBChhD
cmVhdGVTYW1wbGVRdWVyeVJlcXVlc3QSTQoGcGFyZW50GAEgASgJQjXgQQL6QS8KLWRpc2Nv
dmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TYW1wbGVRdWVyeVNldFIGcGFyZW50ElkKDHNh
bXBsZV9xdWVyeRgCIAEoCzIxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5TYW1wbGVRdWVyeUID4EECUgtzYW1wbGVRdWVyeRIrCg9zYW1wbGVfcXVlcnlfaWQYAyAB
KAlCA+BBAlINc2FtcGxlUXVlcnlJZCKyAQoYVXBkYXRlU2FtcGxlUXVlcnlSZXF1ZXN0ElkK
DHNhbXBsZV9xdWVyeRgBIAEoCzIxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TYW1wbGVRdWVyeUID4EECUgtzYW1wbGVRdWVyeRI7Cgt1cGRhdGVfbWFzaxgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siYgoYRGVsZXRlU2Ft
cGxlUXVlcnlSZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29tL1NhbXBsZVF1ZXJ5UgRuYW1lMv0MChJTYW1wbGVRdWVyeVNlcnZp
Y2US2QEKDkdldFNhbXBsZVF1ZXJ5EjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkdldFNhbXBsZVF1ZXJ5UmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeSJXgtPkkwJKEkgvdjFhbHBoYS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL3NhbXBsZVF1ZXJ5U2V0cy8qL3NhbXBsZVF1ZXJpZXMvKn3a
QQRuYW1lEu8BChFMaXN0U2FtcGxlUXVlcmllcxI+Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5MaXN0U2FtcGxlUXVlcmllc1JlcXVlc3QaPy5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdFNhbXBsZVF1ZXJpZXNSZXNwb25zZSJZgtPk
kwJKEkgvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovc2FtcGxlUXVl
cnlTZXRzLyp9L3NhbXBsZVF1ZXJpZXPaQQZwYXJlbnQSjQIKEUNyZWF0ZVNhbXBsZVF1ZXJ5
Ej4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNyZWF0ZVNhbXBsZVF1
ZXJ5UmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1w
bGVRdWVyeSKEAYLT5JMCWCJIL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3NhbXBsZVF1ZXJ5U2V0cy8qfS9zYW1wbGVRdWVyaWVzOgxzYW1wbGVfcXVlcnnaQSNw
YXJlbnQsc2FtcGxlX3F1ZXJ5LHNhbXBsZV9xdWVyeV9pZBKPAgoRVXBkYXRlU2FtcGxlUXVl
cnkSPi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuVXBkYXRlU2FtcGxl
UXVlcnlSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNh
bXBsZVF1ZXJ5IoYBgtPkkwJlMlUvdjFhbHBoYS97c2FtcGxlX3F1ZXJ5Lm5hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9zYW1wbGVRdWVyeVNldHMvKi9zYW1wbGVRdWVyaWVzLyp9Ogxz
YW1wbGVfcXVlcnnaQRhzYW1wbGVfcXVlcnksdXBkYXRlX21hc2sSxAEKEURlbGV0ZVNhbXBs
ZVF1ZXJ5Ej4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRlbGV0ZVNh
bXBsZVF1ZXJ5UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJXgtPkkwJKKkgvdjFh
bHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3NhbXBsZVF1ZXJ5U2V0cy8qL3Nh
bXBsZVF1ZXJpZXMvKn3aQQRuYW1lEtsCChNJbXBvcnRTYW1wbGVRdWVyaWVzEkAuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkltcG9ydFNhbXBsZVF1ZXJpZXNSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLiAYLT5JMCVCJPL3YxYWxwaGEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3NhbXBsZVF1ZXJ5U2V0cy8qfS9zYW1w
bGVRdWVyaWVzOmltcG9ydDoBKspBhAEKQGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5JbXBvcnRTYW1wbGVRdWVyaWVzUmVzcG9uc2USQGdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5JbXBvcnRTYW1wbGVRdWVyaWVzTWV0YWRhdGEaUspBHmRp
c2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CowIKKGNvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGFCF1NhbXBsZVF1ZXJ5U2VydmljZVByb3RvUAFaUmNsb3VkLmdvb2ds
ZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7
ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlz
Y292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx
YWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFK3kQKBxIF
DgCHAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgBCCgkK
AgMFEgMXAEEKCQoCAwYSAxgALQoJCgIDBxIDGQAlCgkKAgMIEgMaACoKCAoBCBIDHABBCgkK
AgglEgMcAEEKCAoBCBIDHQBpCgkKAggLEgMdAGkKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoB
CBIDHwA4CgkKAggIEgMfADgKCAoBCBIDIABBCgkKAggBEgMgAEEKCAoBCBIDIQAtCgkKAggk
EgMhAC0KCAoBCBIDIgBBCgkKAggpEgMiAEEKCAoBCBIDIwBACgkKAggtEgMjAEAKZQoCBgAS
BCcAbAEaWSBTZXJ2aWNlIGZvciBtYW5hZ2luZwogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldcywKCgoKAwYAARIDJwga
CgoKAwYAAxIDKAJGCgwKBQYAA5kIEgMoAkYKCwoDBgADEgQpAio3Cg0KBQYAA5oIEgQpAio3
ClcKBAYAAgASBC0CMgMaSSBHZXRzIGEgW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldLgoKDAoFBgACAAESAy0GFAoMCgUG
AAIAAhIDLRUqCgwKBQYAAgADEgMtNUAKDQoFBgACAAQSBC4EMAYKEQoJBgACAASwyrwiEgQu
BDAGCgwKBQYAAgAEEgMxBDIKDwoIBgACAASbCAASAzEEMgphCgQGAAIBEgQ2AjwDGlMgR2V0
cyBhIGxpc3Qgb2YKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLlNhbXBsZVF1ZXJ5XXMuCgoMCgUGAAIBARIDNgYXCgwKBQYAAgECEgM2GDAK
DAoFBgACAQMSAzcPKAoNCgUGAAIBBBIEOAQ6BgoRCgkGAAIBBLDKvCISBDgEOgYKDAoFBgAC
AQQSAzsENAoPCggGAAIBBJsIABIDOwQ0ClkKBAYAAgISBD8CRgMaSyBDcmVhdGVzIGEgW1Nh
bXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxl
UXVlcnldCgoMCgUGAAICARIDPwYXCgwKBQYAAgICEgM/GDAKDAoFBgACAgMSAz87RgoNCgUG
AAICBBIEQARDBgoRCgkGAAICBLDKvCISBEAEQwYKDQoFBgACAgQSBEQERS4KEAoIBgACAgSb
CAASBEQERS4KWgoEBgACAxIESQJPAxpMIFVwZGF0ZXMgYSBbU2FtcGxlUXVlcnldW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeV0uCgoMCgUGAAID
ARIDSQYXCgwKBQYAAgMCEgNJGDAKDAoFBgACAwMSA0k7RgoNCgUGAAIDBBIESgRNBgoRCgkG
AAIDBLDKvCISBEoETQYKDAoFBgACAwQSA04ERgoPCggGAAIDBJsIABIDTgRGCloKBAYAAgQS
BFICWAMaTCBEZWxldGVzIGEgW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldLgoKDAoFBgACBAESA1IGFwoMCgUGAAIEAhID
UhgwCgwKBQYAAgQDEgNTDyQKDQoFBgACBAQSBFQEVgYKEQoJBgACBASwyrwiEgRUBFYGCgwK
BQYAAgQEEgNXBDIKDwoIBgACBASbCAASA1cEMgqpAgoEBgACBRIEYQJrAxqaAiBCdWxrIGlt
cG9ydCBvZiBtdWx0aXBsZQogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldcy4gU2FtcGxlCiBxdWVyaWVzIHRoYXQgYWxy
ZWFkeSBleGlzdCBtYXkgYmUgZGVsZXRlZC4KCiBOb3RlOiBJdCBpcyBwb3NzaWJsZSBmb3Ig
YSBzdWJzZXQgb2YgdGhlCiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeV1zIHRvIGJlCiBzdWNjZXNzZnVsbHkgaW1wb3J0
ZWQuCgoMCgUGAAIFARIDYQYZCgwKBQYAAgUCEgNhGjQKDAoFBgACBQMSA2IPKwoNCgUGAAIF
BBIEYwRmBgoRCgkGAAIFBLDKvCISBGMEZgYKDQoFBgACBQQSBGcEagYKDwoHBgACBQSZCBIE
ZwRqBgqZAQoCBAASBXEAgwEBGosBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTYW1wbGVRdWVy
eVNlcnZpY2UuR2V0U2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5TYW1wbGVRdWVyeVNlcnZpY2UuR2V0U2FtcGxlUXVlcnldCiBtZXRob2QuCgoK
CgMEAAESA3EIHQq0BAoEBAACABIFfQKCAQQapAQgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2Ug
bmFtZSBvZgogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuU2FtcGxlUXVlcnldLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L3NhbXBsZVF1ZXJ5U2V0cy97c2FtcGxlX3F1ZXJ5X3NldH0vc2Ft
cGxlUXVlcmllcy97c2FtcGxlX3F1ZXJ5fWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBo
YXZlIHBlcm1pc3Npb24gdG8gYWNjZXNzIHRoZQogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldLCByZWdhcmRsZXNzCiBv
ZiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3Ig
aXMgcmV0dXJuZWQuCgogSWYgdGhlIHJlcXVlc3RlZAogW1NhbXBsZVF1ZXJ5XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldIGRvZXMgbm90CiBl
eGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUEAAIABRIDfQIICgwK
BQQAAgABEgN9CQ0KDAoFBAACAAMSA30QEQoOCgUEAAIACBIFfRKCAQMKDwoIBAACAAicCAAS
A34EKgoQCgcEAAIACJ8IEgV/BIEBBQqgAQoCBAESBogBAKoBARqRASBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yCiBbU2FtcGxlUXVlcnlTZXJ2aWNlLkxpc3RTYW1wbGVRdWVyaWVzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXJ2aWNlLkxpc3RT
YW1wbGVRdWVyaWVzXQogbWV0aG9kLgoKCwoDBAEBEgSIAQggCpIDCgQEAQIAEgaQAQKVAQQa
gQMgUmVxdWlyZWQuIFRoZSBwYXJlbnQgc2FtcGxlIHF1ZXJ5IHNldCByZXNvdXJjZSBuYW1l
LCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nh
bXBsZVF1ZXJ5U2V0cy97c2FtcGxlUXVlcnlTZXR9YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMg
bm90IGhhdmUgcGVybWlzc2lvbiB0byBsaXN0CiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeV1zIHVuZGVyIHRoaXMKIHNh
bXBsZSBxdWVyeSBzZXQsIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciBvciBub3QgdGhpcyBzYW1w
bGUgcXVlcnkgc2V0CiBleGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcyBy
ZXR1cm5lZC4KCg0KBQQBAgAFEgSQAQIICg0KBQQBAgABEgSQAQkPCg0KBQQBAgADEgSQARIT
Cg8KBQQBAgAIEgaQARSVAQMKEAoIBAECAAicCAASBJEBBCoKEQoHBAECAAifCBIGkgEElAEF
CqYCCgQEAQIBEgSdAQIWGpcCIE1heGltdW0gbnVtYmVyIG9mCiBbU2FtcGxlUXVlcnldW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeV1zIHRvIHJl
dHVybi4KIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cyB0byAxMDAuIFRoZSBtYXhpbXVtIGFs
bG93ZWQgdmFsdWUgaXMgMTAwMC4gVmFsdWVzCiBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNl
ZCB0byAxMDAwLgoKIElmIHRoaXMgZmllbGQgaXMgbmVnYXRpdmUsIGFuIGBJTlZBTElEX0FS
R1VNRU5UYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgEFEgSdAQIHCg0KBQQBAgEBEgSd
AQgRCg0KBQQBAgEDEgSdARQVCuwECgQEAQICEgSpAQIYGt0EIEEgcGFnZSB0b2tlbgogW0xp
c3RTYW1wbGVRdWVyaWVzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdFNhbXBsZVF1ZXJpZXNSZXNwb25zZS5uZXh0
X3BhZ2VfdG9rZW5dLAogcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBbU2FtcGxlUXVlcnlT
ZXJ2aWNlLkxpc3RTYW1wbGVRdWVyaWVzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuU2FtcGxlUXVlcnlTZXJ2aWNlLkxpc3RTYW1wbGVRdWVyaWVzXQogY2FsbC4g
UHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBw
YWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogW1NhbXBsZVF1
ZXJ5U2VydmljZS5MaXN0U2FtcGxlUXVlcmllc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2VydmljZS5MaXN0U2FtcGxlUXVlcmllc10KIG11
c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4gT3RoZXJ3
aXNlLCBhbgogYElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAEC
AgUSBKkBAggKDQoFBAECAgESBKkBCRMKDQoFBAECAgMSBKkBFhcKoQEKAgQCEgavAQC4AQEa
kgEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTYW1wbGVRdWVyeVNlcnZpY2UuTGlzdFNhbXBs
ZVF1ZXJpZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVR
dWVyeVNlcnZpY2UuTGlzdFNhbXBsZVF1ZXJpZXNdCiBtZXRob2QuCgoLCgMEAgESBK8BCCEK
VQoEBAICABIEsQECKhpHIFRoZSBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeV1zLgoKDQoFBAICAAQSBLEBAgoKDQoFBAIC
AAYSBLEBCxYKDQoFBAICAAESBLEBFyUKDQoFBAICAAMSBLEBKCkK8wEKBAQCAgESBLcBAh0a
5AEgQSB0b2tlbiB0aGF0IGNhbiBiZSBzZW50IGFzCiBbTGlzdFNhbXBsZVF1ZXJpZXNSZXF1
ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5M
aXN0U2FtcGxlUXVlcmllc1JlcXVlc3QucGFnZV90b2tlbl0KIHRvIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vCiBzdWJz
ZXF1ZW50IHBhZ2VzLgoKDQoFBAICAQUSBLcBAggKDQoFBAICAQESBLcBCRgKDQoFBAICAQMS
BLcBGxwKoAEKAgQDEga9AQDeAQEakQEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NhbXBsZVF1
ZXJ5U2VydmljZS5DcmVhdGVTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2VydmljZS5DcmVhdGVTYW1wbGVRdWVyeV0KIG1l
dGhvZC4KCgsKAwQDARIEvQEIIAqKAQoEBAMCABIGwAECxQEEGnogUmVxdWlyZWQuIFRoZSBw
YXJlbnQgcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9zYW1wbGVRdWVyeVNldHMve3NhbXBsZVF1ZXJ5U2V0fWAuCgoN
CgUEAwIABRIEwAECCAoNCgUEAwIAARIEwAEJDwoNCgUEAwIAAxIEwAESEwoPCgUEAwIACBIG
wAEUxQEDChAKCAQDAgAInAgAEgTBAQQqChEKBwQDAgAInwgSBsIBBMQBBQppCgQEAwIBEgTJ
AQJIGlsgUmVxdWlyZWQuIFRoZQogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldIHRvIGNyZWF0ZS4KCg0KBQQDAgEGEgTJ
AQINCg0KBQQDAgEBEgTJAQ4aCg0KBQQDAgEDEgTJAR0eCg0KBQQDAgEIEgTJAR9HChAKCAQD
AgEInAgAEgTJASBGCuQGCgQEAwICEgTdAQJGGtUGIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNl
IGZvciB0aGUKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLlNhbXBsZVF1ZXJ5XSwgd2hpY2ggd2lsbAogYmVjb21lIHRoZSBmaW5hbCBjb21w
b25lbnQgb2YgdGhlCiBbU2FtcGxlUXVlcnkubmFtZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5Lm5hbWVdLgoKIElmIHRoZSBjYWxsZXIgZG9l
cyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGNyZWF0ZSB0aGUKIFtTYW1wbGVRdWVyeV1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5XSwgcmVnYXJk
bGVzcwogb2Ygd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklF
RGAgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBmaWVsZCBtdXN0IGJlIHVuaXF1ZSBhbW9u
ZyBhbGwKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLlNhbXBsZVF1ZXJ5XXMgd2l0aCB0aGUKIHNhbWUKIFtwYXJlbnRdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DcmVhdGVTYW1wbGVRdWVyeVJlcXVlc3QucGFy
ZW50XS4KIE90aGVyd2lzZSwgYW4gYEFMUkVBRFlfRVhJU1RTYCBlcnJvciBpcyByZXR1cm5l
ZC4KCiBUaGlzIGZpZWxkIG11c3QgY29uZm9ybSB0byBbUkZDLTEwMzRdKGh0dHBzOi8vdG9v
bHMuaWV0Zi5vcmcvaHRtbC9yZmMxMDM0KQogc3RhbmRhcmQgd2l0aCBhIGxlbmd0aCBsaW1p
dCBvZiA2MyBjaGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFuCiBgSU5WQUxJRF9BUkdVTUVOVGAg
ZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAwICBRIE3QECCAoNCgUEAwICARIE3QEJGAoNCgUE
AwICAxIE3QEbHAoNCgUEAwICCBIE3QEdRQoQCggEAwICCJwIABIE3QEeRAqgAQoCBAQSBuMB
APEBARqRASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlTZXJ2aWNlLlVwZGF0
ZVNhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2Ft
cGxlUXVlcnlTZXJ2aWNlLlVwZGF0ZVNhbXBsZVF1ZXJ5XQogbWV0aG9kLgoKCwoDBAQBEgTj
AQggCoUDCgQEBAIAEgTsAQJIGvYCIFJlcXVpcmVkLiBUaGUgc2ltcGxlIHF1ZXJ5IHRvIHVw
ZGF0ZS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRh
dGUgdGhlCiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TYW1wbGVRdWVyeV0sIHJlZ2FyZGxlc3MKIG9mIHdoZXRoZXIgb3Igbm90IGl0IGV4
aXN0cywgYSBgUEVSTUlTU0lPTl9ERU5JRURgIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRo
ZSBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5T
YW1wbGVRdWVyeV0gdG8KIHVwZGF0ZSBkb2VzIG5vdCBleGlzdCBhIGBOT1RfRk9VTkRgIGVy
cm9yIGlzIHJldHVybmVkLgoKDQoFBAQCAAYSBOwBAg0KDQoFBAQCAAESBOwBDhoKDQoFBAQC
AAMSBOwBHR4KDQoFBAQCAAgSBOwBH0cKEAoIBAQCAAicCAASBOwBIEYKiQEKBAQEAgESBPAB
AiwaeyBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZCBpbXBvcnRlZCAn
c2ltcGxlIHF1ZXJ5JyB0byB1cGRhdGUuCiBJZiBub3Qgc2V0LCB3aWxsIGJ5IGRlZmF1bHQg
dXBkYXRlIGFsbCBmaWVsZHMuCgoNCgUEBAIBBhIE8AECGwoNCgUEBAIBARIE8AEcJwoNCgUE
BAIBAxIE8AEqKwqgAQoCBAUSBvYBAIcCARqRASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Ft
cGxlUXVlcnlTZXJ2aWNlLkRlbGV0ZVNhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXJ2aWNlLkRlbGV0ZVNhbXBsZVF1ZXJ5
XQogbWV0aG9kLgoKCwoDBAUBEgT2AQggCrgECgQEBQIAEgaBAgKGAgQapwQgUmVxdWlyZWQu
IEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldLCBzdWNoIGFzCiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NhbXBsZVF1ZXJ5U2V0cy97c2FtcGxl
X3F1ZXJ5X3NldH0vc2FtcGxlUXVlcmllcy97c2FtcGxlX3F1ZXJ5fWAuCgogSWYgdGhlIGNh
bGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gZGVsZXRlIHRoZQogW1NhbXBsZVF1
ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnld
LCByZWdhcmRsZXNzCiBvZiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgYFBFUk1JU1NJ
T05fREVOSUVEYCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW1NhbXBsZVF1ZXJ5XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldIHRvCiBk
ZWxldGUgZG9lcyBub3QgZXhpc3QsIGEgYE5PVF9GT1VORGAgZXJyb3IgaXMgcmV0dXJuZWQu
CgoNCgUEBQIABRIEgQICCAoNCgUEBQIAARIEgQIJDQoNCgUEBQIAAxIEgQIQEQoPCgUEBQIA
CBIGgQIShgIDChAKCAQFAgAInAgAEgSCAgQqChEKBwQFAgAInwgSBoMCBIUCBWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest ===
    # Fields for GetSampleQueryRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesRequest ===
    # Fields for ListSampleQueriesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesResponse ===
    # Fields for ListSampleQueriesResponse
    # Field: sample_queries Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuery)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::CreateSampleQueryRequest ===
    # Fields for CreateSampleQueryRequest
    # Field: parent Type: 9 ()
    # Field: sample_query Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuery)
    # Field: sample_query_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::UpdateSampleQueryRequest ===
    # Fields for UpdateSampleQueryRequest
    # Field: sample_query Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuery)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::DeleteSampleQueryRequest ===
    # Fields for DeleteSampleQueryRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::SampleQueryServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::SampleQueryServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::SampleQueryServiceClient

Client stub representing the remote C<SampleQueryService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'GetSampleQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery',
    });
}

sub list_sample_queries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'ListSampleQueries',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesResponse',
    });
}

sub create_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::CreateSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'CreateSampleQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery',
    });
}

sub update_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::UpdateSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'UpdateSampleQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery',
    });
}

sub delete_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::DeleteSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'DeleteSampleQuery',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub import_sample_queries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportSampleQueriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'ImportSampleQueries',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQueryService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/sample_query_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SampleQueryService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/sample_query_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest

Request message for
[SampleQueryService.GetSampleQuery][google.cloud.discoveryengine.v1alpha.SampleQueryService.GetSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], such as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}/sampleQueries/{sample_query}`.

If the caller does not have permission to access the
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], regardless
of whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery] does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesRequest

Request message for
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1alpha.SampleQueryService.ListSampleQueries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent sample query set resource name, such as
`projects/{project}/locations/{location}/sampleQuerySets/{sampleQuerySet}`.

If the caller does not have permission to list
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]s under this
sample query set, regardless of whether or not this sample query set
exists, a `PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]s to return.
If unspecified, defaults to 100. The maximum allowed value is 1000. Values
above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListSampleQueriesResponse.next_page_token][google.cloud.discoveryengine.v1alpha.ListSampleQueriesResponse.next_page_token],
received from a previous
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1alpha.SampleQueryService.ListSampleQueries]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1alpha.SampleQueryService.ListSampleQueries]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesResponse

Response message for
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1alpha.SampleQueryService.ListSampleQueries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_queries() >> / C<< $msg->sample_queries($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery>)

The [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSampleQueriesRequest.page_token][google.cloud.discoveryengine.v1alpha.ListSampleQueriesRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::CreateSampleQueryRequest

Request message for
[SampleQueryService.CreateSampleQuery][google.cloud.discoveryengine.v1alpha.SampleQueryService.CreateSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/sampleQuerySets/{sampleQuerySet}`.

=item * C<< $msg->sample_query() >> / C<< $msg->sample_query($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery>)

Required. The
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery] to create.

=item * C<< $msg->sample_query_id() >> / C<< $msg->sample_query_id($value) >>

Type: C<String>

Required. The ID to use for the
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], which will
become the final component of the
[SampleQuery.name][google.cloud.discoveryengine.v1alpha.SampleQuery.name].

If the caller does not have permission to create the
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

This field must be unique among all
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]s with the
same
[parent][google.cloud.discoveryengine.v1alpha.CreateSampleQueryRequest.parent].
Otherwise, an `ALREADY_EXISTS` error is returned.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::UpdateSampleQueryRequest

Request message for
[SampleQueryService.UpdateSampleQuery][google.cloud.discoveryengine.v1alpha.SampleQueryService.UpdateSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_query() >> / C<< $msg->sample_query($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery>)

Required. The simple query to update.

If the caller does not have permission to update the
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery] to
update does not exist a `NOT_FOUND` error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported 'simple query' to update.
If not set, will by default update all fields.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::DeleteSampleQueryRequest

Request message for
[SampleQueryService.DeleteSampleQuery][google.cloud.discoveryengine.v1alpha.SampleQueryService.DeleteSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], such as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}/sampleQueries/{sample_query}`.

If the caller does not have permission to delete the
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery] to
delete does not exist, a `NOT_FOUND` error is returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
