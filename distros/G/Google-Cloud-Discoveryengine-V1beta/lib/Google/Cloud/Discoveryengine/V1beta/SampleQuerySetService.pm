package Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::SampleQuerySet };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zYW1wbGVfcXVlcnlfc2V0
X3NlcnZpY2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxo6Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvc2FtcGxlX3F1ZXJ5
X3NldC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9i
dWYvZmllbGRfbWFzay5wcm90byJlChhHZXRTYW1wbGVRdWVyeVNldFJlcXVlc3QSSQoEbmFt
ZRgBIAEoCUI14EEC+kEvCi1kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxl
UXVlcnlTZXRSBG5hbWUioQEKGkxpc3RTYW1wbGVRdWVyeVNldHNSZXF1ZXN0EkcKBnBhcmVu
dBgBIAEoCUIv4EEC+kEpCidkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vTG9jYXRp
b25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
AyABKAlSCXBhZ2VUb2tlbiKmAQobTGlzdFNhbXBsZVF1ZXJ5U2V0c1Jlc3BvbnNlEl8KEXNh
bXBsZV9xdWVyeV9zZXRzGAEgAygLMjMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuU2FtcGxlUXVlcnlTZXRSD3NhbXBsZVF1ZXJ5U2V0cxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i/gEKG0NyZWF0ZVNhbXBsZVF1ZXJ5U2V0UmVxdWVz
dBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMu
Y29tL0xvY2F0aW9uUgZwYXJlbnQSYgoQc2FtcGxlX3F1ZXJ5X3NldBgCIAEoCzIzLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0QgPgQQJSDnNh
bXBsZVF1ZXJ5U2V0EjIKE3NhbXBsZV9xdWVyeV9zZXRfaWQYAyABKAlCA+BBAlIQc2FtcGxl
UXVlcnlTZXRJZCK+AQobVXBkYXRlU2FtcGxlUXVlcnlTZXRSZXF1ZXN0EmIKEHNhbXBsZV9x
dWVyeV9zZXQYASABKAsyMy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5T
YW1wbGVRdWVyeVNldEID4EECUg5zYW1wbGVRdWVyeVNldBI7Cgt1cGRhdGVfbWFzaxgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siaAobRGVsZXRlU2Ft
cGxlUXVlcnlTZXRSZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBBAvpBLwotZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29tL1NhbXBsZVF1ZXJ5U2V0UgRuYW1lMoALChVTYW1wbGVRdWVy
eVNldFNlcnZpY2USzwEKEUdldFNhbXBsZVF1ZXJ5U2V0Ej0uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuR2V0U2FtcGxlUXVlcnlTZXRSZXF1ZXN0GjMuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXQiRoLT5JMCORI3L3Yx
YmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3NhbXBsZVF1ZXJ5U2V0cy8qfdpB
BG5hbWUS4gEKE0xpc3RTYW1wbGVRdWVyeVNldHMSPy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5MaXN0U2FtcGxlUXVlcnlTZXRzUmVxdWVzdBpALmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RTYW1wbGVRdWVyeVNldHNSZXNwb25zZSJI
gtPkkwI5EjcvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vc2FtcGxl
UXVlcnlTZXRz2kEGcGFyZW50Eo4CChRDcmVhdGVTYW1wbGVRdWVyeVNldBJALmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0ZVNhbXBsZVF1ZXJ5U2V0UmVxdWVz
dBozLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0
In+C0+STAksiNy92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9zYW1w
bGVRdWVyeVNldHM6EHNhbXBsZV9xdWVyeV9zZXTaQStwYXJlbnQsc2FtcGxlX3F1ZXJ5X3Nl
dCxzYW1wbGVfcXVlcnlfc2V0X2lkEpECChRVcGRhdGVTYW1wbGVRdWVyeVNldBJALmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVwZGF0ZVNhbXBsZVF1ZXJ5U2V0UmVx
dWVzdBozLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5
U2V0IoEBgtPkkwJcMkgvdjFiZXRhL3tzYW1wbGVfcXVlcnlfc2V0Lm5hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9zYW1wbGVRdWVyeVNldHMvKn06EHNhbXBsZV9xdWVyeV9zZXTaQRxz
YW1wbGVfcXVlcnlfc2V0LHVwZGF0ZV9tYXNrErgBChREZWxldGVTYW1wbGVRdWVyeVNldBJA
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRlbGV0ZVNhbXBsZVF1ZXJ5
U2V0UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJGgtPkkwI5KjcvdjFiZXRhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2FtcGxlUXVlcnlTZXRzLyp92kEEbmFtZRrP
AcpBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBqgFodHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0ZUKhAgonY29t
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhpTYW1wbGVRdWVyeVNldFNl
cnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2
MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllF
TkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxD
bG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5
RW5naW5lOjpWMWJldGFK7kEKBxIFDgCBAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgBECgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMaAEAKCQoC
CCUSAxoAQAoICgEIEgMbAGgKCQoCCAsSAxsAaAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEI
EgMdADsKCQoCCAgSAx0AOwoICgEIEgMeAEAKCQoCCAESAx4AQAoICgEIEgMfAC0KCQoCCCQS
Ax8ALQoICgEIEgMgAEAKCQoCCCkSAyAAQAoICgEIEgMhAD8KCQoCCC0SAyEAPwpqCgIGABIE
JQBfARpeIFNlcnZpY2UgZm9yIG1hbmFnaW5nCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XXMsCgoKCgMGAAES
AyUIHQoKCgMGAAMSAyYCRgoMCgUGAAOZCBIDJgJGCgsKAwYAAxIEJwIqSgoNCgUGAAOaCBIE
JwIqSgpdCgQGAAIAEgQuAjMDGk8gR2V0cyBhCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XS4KCgwKBQYAAgAB
EgMuBhcKDAoFBgACAAISAy4YMAoMCgUGAAIAAxIDLjtJCg0KBQYAAgAEEgQvBDEGChEKCQYA
AgAEsMq8IhIELwQxBgoMCgUGAAIABBIDMgQyCg8KCAYAAgAEmwgAEgMyBDIKZgoEBgACARIE
NwI9AxpYIEdldHMgYSBsaXN0IG9mCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XXMuCgoMCgUGAAIBARIDNwYZ
CgwKBQYAAgECEgM3GjQKDAoFBgACAQMSAzgPKgoNCgUGAAIBBBIEOQQ7BgoRCgkGAAIBBLDK
vCISBDkEOwYKDAoFBgACAQQSAzwENAoPCggGAAIBBJsIABIDPAQ0Cl8KBAYAAgISBEECSQMa
USBDcmVhdGVzIGEKIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRdCgoMCgUGAAICARIDQQYaCgwKBQYAAgICEgNB
GzYKDAoFBgACAgMSA0IPHQoNCgUGAAICBBIEQwRGBgoRCgkGAAICBLDKvCISBEMERgYKDQoF
BgACAgQSBEcESDYKEAoIBgACAgSbCAASBEcESDYKYAoEBgACAxIETQJUAxpSIFVwZGF0ZXMg
YQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TYW1wbGVRdWVyeVNldF0uCgoMCgUGAAIDARIDTQYaCgwKBQYAAgMCEgNNGzYKDAoFBgAC
AwMSA04PHQoNCgUGAAIDBBIETwRSBgoRCgkGAAIDBLDKvCISBE8EUgYKDAoFBgACAwQSA1ME
SgoPCggGAAIDBJsIABIDUwRKCmAKBAYAAgQSBFgCXgMaUiBEZWxldGVzIGEKIFtTYW1wbGVR
dWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVl
cnlTZXRdLgoKDAoFBgACBAESA1gGGgoMCgUGAAIEAhIDWBs2CgwKBQYAAgQDEgNZDyQKDQoF
BgACBAQSBFoEXAYKEQoJBgACBASwyrwiEgRaBFwGCgwKBQYAAgQEEgNdBDIKDwoIBgACBASb
CAASA10EMgqjAQoCBAASBGQAeAEalgEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NhbXBsZVF1
ZXJ5U2V0U2VydmljZS5HZXRTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkdldFNhbXBsZVF1ZXJ5U2V0
XQogbWV0aG9kLgoKCgoDBAABEgNkCCAKpwQKBAQAAgASBHICdwQamAQgUmVxdWlyZWQuIEZ1
bGwgcmVzb3VyY2UgbmFtZSBvZgogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeVNldF0sIHN1Y2gKIGFzCiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NhbXBsZVF1ZXJ5U2V0cy97c2Ft
cGxlX3F1ZXJ5X3NldH1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNz
aW9uIHRvIGFjY2VzcyB0aGUKIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRdLAogcmVnYXJkbGVzcyBvZiB3aGV0
aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMKIHJl
dHVybmVkLgoKIElmIHRoZSByZXF1ZXN0ZWQKIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRdIGRvZXMKIG5vdCBl
eGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUEAAIABRIDcgIICgwK
BQQAAgABEgNyCQ0KDAoFBAACAAMSA3IQEQoNCgUEAAIACBIEchJ3AwoPCggEAAIACJwIABID
cwQqCg8KBwQAAgAInwgSBHQEdgUKqAEKAgQBEgV9AJ8BARqaASBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkxpc3RTYW1wbGVRdWVyeVNldHNdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0U2VydmljZS5M
aXN0U2FtcGxlUXVlcnlTZXRzXQogbWV0aG9kLgoKCgoDBAEBEgN9CCIK3gIKBAQBAgASBoUB
AooBBBrNAiBSZXF1aXJlZC4gVGhlIHBhcmVudCBsb2NhdGlvbiByZXNvdXJjZSBuYW1lLCBz
dWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCiBJ
ZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBsaXN0CiBbU2FtcGxl
UXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1
ZXJ5U2V0XXMgdW5kZXIKIHRoaXMgbG9jYXRpb24sIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciBv
ciBub3QgdGhpcyBsb2NhdGlvbiBleGlzdHMsIGEKIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJy
b3IgaXMgcmV0dXJuZWQuCgoNCgUEAQIABRIEhQECCAoNCgUEAQIAARIEhQEJDwoNCgUEAQIA
AxIEhQESEwoPCgUEAQIACBIGhQEUigEDChAKCAQBAgAInAgAEgSGAQQqChEKBwQBAgAInwgS
BocBBIkBBQqrAgoEBAECARIEkgECFhqcAiBNYXhpbXVtIG51bWJlciBvZgogW1NhbXBsZVF1
ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVy
eVNldF1zIHRvCiByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cyB0byAxMDAuIFRo
ZSBtYXhpbXVtIGFsbG93ZWQgdmFsdWUgaXMgMTAwMC4KIFZhbHVlcyBhYm92ZSAxMDAwIHdp
bGwgYmUgY29lcmNlZCB0byAxMDAwLgoKIElmIHRoaXMgZmllbGQgaXMgbmVnYXRpdmUsIGFu
IGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgEFEgSSAQIH
Cg0KBQQBAgEBEgSSAQgRCg0KBQQBAgEDEgSSARQVCoEFCgQEAQICEgSeAQIYGvIEIEEgcGFn
ZSB0b2tlbgogW0xpc3RTYW1wbGVRdWVyeVNldHNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5d
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RTYW1wbGVRdWVyeVNl
dHNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dLAogcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3Vz
CiBbU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkxpc3RTYW1wbGVRdWVyeVNldHNdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0U2VydmljZS5MaXN0
U2FtcGxlUXVlcnlTZXRzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBz
dWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVy
cyBwcm92aWRlZCB0bwogW1NhbXBsZVF1ZXJ5U2V0U2VydmljZS5MaXN0U2FtcGxlUXVlcnlT
ZXRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeVNl
dFNlcnZpY2UuTGlzdFNhbXBsZVF1ZXJ5U2V0c10KIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhh
dCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4gT3RoZXJ3aXNlLCBhbgogYElOVkFMSURfQVJH
VU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAECAgUSBJ4BAggKDQoFBAECAgESBJ4B
CRMKDQoFBAECAgMSBJ4BFhcKqgEKAgQCEgakAQCtAQEamwEgUmVzcG9uc2UgbWVzc2FnZSBm
b3IKIFtTYW1wbGVRdWVyeVNldFNlcnZpY2UuTGlzdFNhbXBsZVF1ZXJ5U2V0c11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkxp
c3RTYW1wbGVRdWVyeVNldHNdCiBtZXRob2QuCgoLCgMEAgESBKQBCCMKWgoEBAICABIEpgEC
MBpMIFRoZSBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLlNhbXBsZVF1ZXJ5U2V0XXMuCgoNCgUEAgIABBIEpgECCgoNCgUEAgIABhIEpgEL
GQoNCgUEAgIAARIEpgEaKwoNCgUEAgIAAxIEpgEuLwr2AQoEBAICARIErAECHRrnASBBIHRv
a2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMKIFtMaXN0U2FtcGxlUXVlcnlTZXRzUmVxdWVzdC5w
YWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0U2Ft
cGxlUXVlcnlTZXRzUmVxdWVzdC5wYWdlX3Rva2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVl
bnQgcGFnZXMuCgoNCgUEAgIBBRIErAECCAoNCgUEAgIBARIErAEJGAoNCgUEAgIBAxIErAEb
HAqrAQoCBAMSBrIBANUBARqcASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlT
ZXRTZXJ2aWNlLkNyZWF0ZVNhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeVNldFNlcnZpY2UuQ3JlYXRlU2FtcGxlUXVlcnlT
ZXRdCiBtZXRob2QuCgoLCgMEAwESBLIBCCMKaQoEBAMCABIGtQECugEEGlkgUmVxdWlyZWQu
IFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAuCgoNCgUEAwIABRIEtQECCAoNCgUEAwIAARIEtQEJ
DwoNCgUEAwIAAxIEtQESEwoPCgUEAwIACBIGtQEUugEDChAKCAQDAgAInAgAEgS2AQQqChEK
BwQDAgAInwgSBrcBBLkBBQpvCgQEAwIBEgS/AQJPGmEgUmVxdWlyZWQuIFRoZQogW1NhbXBs
ZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVR
dWVyeVNldF0gdG8KIGNyZWF0ZS4KCg0KBQQDAgEGEgS/AQIQCg0KBQQDAgEBEgS/AREhCg0K
BQQDAgEDEgS/ASQlCg0KBQQDAgEIEgS/ASZOChAKCAQDAgEInAgAEgS/ASdNCvsGCgQEAwIC
EgTUAQJKGuwGIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtTYW1wbGVRdWVy
eVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlT
ZXRdLCB3aGljaAogd2lsbCBiZWNvbWUgdGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUKIFtT
YW1wbGVRdWVyeVNldC5uYW1lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TYW1wbGVRdWVyeVNldC5uYW1lXS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUg
cGVybWlzc2lvbiB0byBjcmVhdGUgdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XSwKIHJlZ2FyZGxlc3Mg
b2Ygd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJy
b3IgaXMKIHJldHVybmVkLgoKIFRoaXMgZmllbGQgbXVzdCBiZSB1bmlxdWUgYW1vbmcgYWxs
CiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlNhbXBsZVF1ZXJ5U2V0XXMgd2l0aAogdGhlIHNhbWUKIFtwYXJlbnRdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0ZVNhbXBsZVF1ZXJ5U2V0UmVxdWVzdC5w
YXJlbnRdLgogT3RoZXJ3aXNlLCBhbiBgQUxSRUFEWV9FWElTVFNgIGVycm9yIGlzIHJldHVy
bmVkLgoKIFRoaXMgZmllbGQgbXVzdCBjb25mb3JtIHRvIFtSRkMtMTAzNF0oaHR0cHM6Ly90
b29scy5pZXRmLm9yZy9odG1sL3JmYzEwMzQpCiBzdGFuZGFyZCB3aXRoIGEgbGVuZ3RoIGxp
bWl0IG9mIDYzIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4KIGBJTlZBTElEX0FSR1VNRU5U
YCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQDAgIFEgTUAQIICg0KBQQDAgIBEgTUAQkcCg0K
BQQDAgIDEgTUAR8gCg0KBQQDAgIIEgTUASFJChAKCAQDAgIInAgAEgTUASJICqsBCgIEBBIG
2gEA6QEBGpwBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTYW1wbGVRdWVyeVNldFNlcnZpY2Uu
VXBkYXRlU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLlNhbXBsZVF1ZXJ5U2V0U2VydmljZS5VcGRhdGVTYW1wbGVRdWVyeVNldF0KIG1ldGhv
ZC4KCgsKAwQEARIE2gEIIwqUAwoEBAQCABIE5AECTxqFAyBSZXF1aXJlZC4gVGhlIHNhbXBs
ZSBxdWVyeSBzZXQgdG8gdXBkYXRlLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBw
ZXJtaXNzaW9uIHRvIHVwZGF0ZSB0aGUKIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRdLAogcmVnYXJkbGVzcyBv
ZiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJv
ciBpcwogcmV0dXJuZWQuCgogSWYgdGhlIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRdCiB0byB1cGRhdGUgZG9l
cyBub3QgZXhpc3QgYSBgTk9UX0ZPVU5EYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQEAgAG
EgTkAQIQCg0KBQQEAgABEgTkAREhCg0KBQQEAgADEgTkASQlCg0KBQQEAgAIEgTkASZOChAK
CAQEAgAInAgAEgTkASdNCo0BCgQEBAIBEgToAQIsGn8gSW5kaWNhdGVzIHdoaWNoIGZpZWxk
cyBpbiB0aGUgcHJvdmlkZWQgaW1wb3J0ZWQgJ3NhbXBsZSBxdWVyeSBzZXQnIHRvCiB1cGRh
dGUuIElmIG5vdCBzZXQsIHdpbGwgYnkgZGVmYXVsdCB1cGRhdGUgYWxsIGZpZWxkcy4KCg0K
BQQEAgEGEgToAQIbCg0KBQQEAgEBEgToARwnCg0KBQQEAgEDEgToASorCqsBCgIEBRIG7gEA
gQIBGpwBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTYW1wbGVRdWVyeVNldFNlcnZpY2UuRGVs
ZXRlU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlNhbXBsZVF1ZXJ5U2V0U2VydmljZS5EZWxldGVTYW1wbGVRdWVyeVNldF0KIG1ldGhvZC4K
CgsKAwQFARIE7gEIIwqsBAoEBAUCABIG+wECgAIEGpsEIFJlcXVpcmVkLiBGdWxsIHJlc291
cmNlIG5hbWUgb2YKIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXRdLCBzdWNoCiBhcwogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zYW1wbGVRdWVyeVNldHMve3NhbXBsZV9xdWVy
eV9zZXR9YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBk
ZWxldGUgdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XSwKIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciBvciBu
b3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMKIHJldHVybmVk
LgoKIElmIHRoZSBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XQogdG8gZGVsZXRlIGRvZXMgbm90IGV4aXN0LCBh
IGBOT1RfRk9VTkRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAUCAAUSBPsBAggKDQoFBAUC
AAESBPsBCQ0KDQoFBAUCAAMSBPsBEBEKDwoFBAUCAAgSBvsBEoACAwoQCggEBQIACJwIABIE
/AEEKgoRCgcEBQIACJ8IEgb9AQT/AQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest ===
    # Fields for GetSampleQuerySetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::ListSampleQuerySetsRequest ===
    # Fields for ListSampleQuerySetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::ListSampleQuerySetsResponse ===
    # Fields for ListSampleQuerySetsResponse
    # Field: sample_query_sets Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuerySet)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::CreateSampleQuerySetRequest ===
    # Fields for CreateSampleQuerySetRequest
    # Field: parent Type: 9 ()
    # Field: sample_query_set Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuerySet)
    # Field: sample_query_set_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::UpdateSampleQuerySetRequest ===
    # Fields for UpdateSampleQuerySetRequest
    # Field: sample_query_set Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuerySet)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::DeleteSampleQuerySetRequest ===
    # Fields for DeleteSampleQuerySetRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::SampleQuerySetServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::SampleQuerySetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::SampleQuerySetServiceClient

Client stub representing the remote C<SampleQuerySetService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQuerySetService',
        method         => 'GetSampleQuerySet',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet',
    });
}

sub list_sample_query_sets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::ListSampleQuerySetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQuerySetService',
        method         => 'ListSampleQuerySets',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::ListSampleQuerySetsResponse',
    });
}

sub create_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::CreateSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQuerySetService',
        method         => 'CreateSampleQuerySet',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet',
    });
}

sub update_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::UpdateSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQuerySetService',
        method         => 'UpdateSampleQuerySet',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet',
    });
}

sub delete_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::DeleteSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQuerySetService',
        method         => 'DeleteSampleQuerySet',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/sample_query_set_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/sample_query_set_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest

Request message for
[SampleQuerySetService.GetSampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySetService.GetSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet], such
as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}`.

If the caller does not have permission to access the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet],
regardless of whether or not it exists, a PERMISSION_DENIED error is
returned.

If the requested
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet] does
not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::ListSampleQuerySetsRequest

Request message for
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1beta.SampleQuerySetService.ListSampleQuerySets]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location resource name, such as
`projects/{project}/locations/{location}`.

If the caller does not have permission to list
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet]s under
this location, regardless of whether or not this location exists, a
`PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet]s to
return. If unspecified, defaults to 100. The maximum allowed value is 1000.
Values above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListSampleQuerySetsResponse.next_page_token][google.cloud.discoveryengine.v1beta.ListSampleQuerySetsResponse.next_page_token],
received from a previous
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1beta.SampleQuerySetService.ListSampleQuerySets]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1beta.SampleQuerySetService.ListSampleQuerySets]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::ListSampleQuerySetsResponse

Response message for
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1beta.SampleQuerySetService.ListSampleQuerySets]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_query_sets() >> / C<< $msg->sample_query_sets($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet>)

The [SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSampleQuerySetsRequest.page_token][google.cloud.discoveryengine.v1beta.ListSampleQuerySetsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::CreateSampleQuerySetRequest

Request message for
[SampleQuerySetService.CreateSampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySetService.CreateSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->sample_query_set() >> / C<< $msg->sample_query_set($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet>)

Required. The
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet] to
create.

=item * C<< $msg->sample_query_set_id() >> / C<< $msg->sample_query_set_id($value) >>

Type: C<String>

Required. The ID to use for the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet], which
will become the final component of the
[SampleQuerySet.name][google.cloud.discoveryengine.v1beta.SampleQuerySet.name].

If the caller does not have permission to create the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet],
regardless of whether or not it exists, a `PERMISSION_DENIED` error is
returned.

This field must be unique among all
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet]s with
the same
[parent][google.cloud.discoveryengine.v1beta.CreateSampleQuerySetRequest.parent].
Otherwise, an `ALREADY_EXISTS` error is returned.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::UpdateSampleQuerySetRequest

Request message for
[SampleQuerySetService.UpdateSampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySetService.UpdateSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_query_set() >> / C<< $msg->sample_query_set($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet>)

Required. The sample query set to update.

If the caller does not have permission to update the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet],
regardless of whether or not it exists, a `PERMISSION_DENIED` error is
returned.

If the [SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet]
to update does not exist a `NOT_FOUND` error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported 'sample query set' to
update. If not set, will by default update all fields.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::DeleteSampleQuerySetRequest

Request message for
[SampleQuerySetService.DeleteSampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySetService.DeleteSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet], such
as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}`.

If the caller does not have permission to delete the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet],
regardless of whether or not it exists, a `PERMISSION_DENIED` error is
returned.

If the [SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet]
to delete does not exist, a `NOT_FOUND` error is returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
