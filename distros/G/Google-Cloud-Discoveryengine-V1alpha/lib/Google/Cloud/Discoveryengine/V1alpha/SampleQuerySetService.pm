package Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2FtcGxlX3F1ZXJ5X3Nl
dF9zZXJ2aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEa
HGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3Rv
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGjtnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2FtcGxlX3F1
ZXJ5X3NldC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJv
dG9idWYvZmllbGRfbWFzay5wcm90byJlChhHZXRTYW1wbGVRdWVyeVNldFJlcXVlc3QSSQoE
bmFtZRgBIAEoCUI14EEC+kEvCi1kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2Ft
cGxlUXVlcnlTZXRSBG5hbWUioQEKGkxpc3RTYW1wbGVRdWVyeVNldHNSZXF1ZXN0EkcKBnBh
cmVudBgBIAEoCUIv4EEC+kEpCidkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vTG9j
YXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9r
ZW4YAyABKAlSCXBhZ2VUb2tlbiKnAQobTGlzdFNhbXBsZVF1ZXJ5U2V0c1Jlc3BvbnNlEmAK
EXNhbXBsZV9xdWVyeV9zZXRzGAEgAygLMjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2V0Ug9zYW1wbGVRdWVyeVNldHMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIv8BChtDcmVhdGVTYW1wbGVRdWVyeVNldFJl
cXVlc3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EmMKEHNhbXBsZV9xdWVyeV9zZXQYAiABKAsyNC5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRCA+BB
AlIOc2FtcGxlUXVlcnlTZXQSMgoTc2FtcGxlX3F1ZXJ5X3NldF9pZBgDIAEoCUID4EECUhBz
YW1wbGVRdWVyeVNldElkIr8BChtVcGRhdGVTYW1wbGVRdWVyeVNldFJlcXVlc3QSYwoQc2Ft
cGxlX3F1ZXJ5X3NldBgBIAEoCzI0Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TYW1wbGVRdWVyeVNldEID4EECUg5zYW1wbGVRdWVyeVNldBI7Cgt1cGRhdGVfbWFz
axgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siaAobRGVs
ZXRlU2FtcGxlUXVlcnlTZXRSZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBBAvpBLwotZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NhbXBsZVF1ZXJ5U2V0UgRuYW1lMpEKChVTYW1w
bGVRdWVyeVNldFNlcnZpY2US0gEKEUdldFNhbXBsZVF1ZXJ5U2V0Ej4uZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdldFNhbXBsZVF1ZXJ5U2V0UmVxdWVzdBo0Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeVNldCJHgtPk
kwI6EjgvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3NhbXBsZVF1ZXJ5
U2V0cy8qfdpBBG5hbWUS5QEKE0xpc3RTYW1wbGVRdWVyeVNldHMSQC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdFNhbXBsZVF1ZXJ5U2V0c1JlcXVlc3QaQS5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdFNhbXBsZVF1ZXJ5U2V0
c1Jlc3BvbnNlIkmC0+STAjoSOC92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKn0vc2FtcGxlUXVlcnlTZXRz2kEGcGFyZW50EpICChRDcmVhdGVTYW1wbGVRdWVyeVNl
dBJBLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DcmVhdGVTYW1wbGVR
dWVyeVNldFJlcXVlc3QaNC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
U2FtcGxlUXVlcnlTZXQigAGC0+STAkwiOC92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKn0vc2FtcGxlUXVlcnlTZXRzOhBzYW1wbGVfcXVlcnlfc2V02kErcGFyZW50
LHNhbXBsZV9xdWVyeV9zZXQsc2FtcGxlX3F1ZXJ5X3NldF9pZBKUAgoUVXBkYXRlU2FtcGxl
UXVlcnlTZXQSQS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuVXBkYXRl
U2FtcGxlUXVlcnlTZXRSZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLlNhbXBsZVF1ZXJ5U2V0IoIBgtPkkwJdMkkvdjFhbHBoYS97c2FtcGxlX3F1ZXJ5
X3NldC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2FtcGxlUXVlcnlTZXRzLyp9OhBz
YW1wbGVfcXVlcnlfc2V02kEcc2FtcGxlX3F1ZXJ5X3NldCx1cGRhdGVfbWFzaxK6AQoURGVs
ZXRlU2FtcGxlUXVlcnlTZXQSQS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRGVsZXRlU2FtcGxlUXVlcnlTZXRSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5
IkeC0+STAjoqOC92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2FtcGxl
UXVlcnlTZXRzLyp92kEEbmFtZRpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKmAgoo
Y29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIaU2FtcGxlUXVlcnlT
ZXRTZXJ2aWNlUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUv
YXBpdjFhbHBoYS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NP
VkVSWUVOR0lORaoCJEdvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdv
b2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRp
c2NvdmVyeUVuZ2luZTo6VjFhbHBoYUqRQgoHEgUOAIECAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEUKCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgS
AxoAQQoJCgIIJRIDGgBBCggKAQgSAxsAaQoJCgIICxIDGwBpCggKAQgSAxwAIgoJCgIIChID
HAAiCggKAQgSAx0AOwoJCgIICBIDHQA7CggKAQgSAx4AQQoJCgIIARIDHgBBCggKAQgSAx8A
LQoJCgIIJBIDHwAtCggKAQgSAyAAQQoJCgIIKRIDIABBCggKAQgSAyEAQAoJCgIILRIDIQBA
CmsKAgYAEgQlAF0BGl8gU2VydmljZSBmb3IgbWFuYWdpbmcKIFtTYW1wbGVRdWVyeVNldF1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2V0XXMs
CgoKCgMGAAESAyUIHQoKCgMGAAMSAyYCRgoMCgUGAAOZCBIDJgJGCgsKAwYAAxIEJwIoNwoN
CgUGAAOaCBIEJwIoNwpeCgQGAAIAEgQsAjEDGlAgR2V0cyBhCiBbU2FtcGxlUXVlcnlTZXRd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeVNldF0u
CgoMCgUGAAIAARIDLAYXCgwKBQYAAgACEgMsGDAKDAoFBgACAAMSAyw7SQoNCgUGAAIABBIE
LQQvBgoRCgkGAAIABLDKvCISBC0ELwYKDAoFBgACAAQSAzAEMgoPCggGAAIABJsIABIDMAQy
CmcKBAYAAgESBDUCOwMaWSBHZXRzIGEgbGlzdCBvZgogW1NhbXBsZVF1ZXJ5U2V0XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdcy4KCgwK
BQYAAgEBEgM1BhkKDAoFBgACAQISAzUaNAoMCgUGAAIBAxIDNg8qCg0KBQYAAgEEEgQ3BDkG
ChEKCQYAAgEEsMq8IhIENwQ5BgoMCgUGAAIBBBIDOgQ0Cg8KCAYAAgEEmwgAEgM6BDQKYAoE
BgACAhIEPwJHAxpSIENyZWF0ZXMgYQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdCgoMCgUGAAICARIDPwYa
CgwKBQYAAgICEgM/GzYKDAoFBgACAgMSA0APHQoNCgUGAAICBBIEQQREBgoRCgkGAAICBLDK
vCISBEEERAYKDQoFBgACAgQSBEUERjYKEAoIBgACAgSbCAASBEUERjYKYQoEBgACAxIESwJS
AxpTIFVwZGF0ZXMgYQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdLgoKDAoFBgACAwESA0sGGgoMCgUGAAID
AhIDSxs2CgwKBQYAAgMDEgNMDx0KDQoFBgACAwQSBE0EUAYKEQoJBgACAwSwyrwiEgRNBFAG
CgwKBQYAAgMEEgNRBEoKDwoIBgACAwSbCAASA1EESgphCgQGAAIEEgRWAlwDGlMgRGVsZXRl
cyBhCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TYW1wbGVRdWVyeVNldF0uCgoMCgUGAAIEARIDVgYaCgwKBQYAAgQCEgNWGzYKDAoF
BgACBAMSA1cPJAoNCgUGAAIEBBIEWARaBgoRCgkGAAIEBLDKvCISBFgEWgYKDAoFBgACBAQS
A1sEMgoPCggGAAIEBJsIABIDWwQyCqQBCgIEABIEYgB2ARqXASBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkdldFNhbXBsZVF1ZXJ5U2V0XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkdl
dFNhbXBsZVF1ZXJ5U2V0XQogbWV0aG9kLgoKCgoDBAABEgNiCCAKqgQKBAQAAgASBHACdQQa
mwQgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW1NhbXBsZVF1ZXJ5U2V0XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdLCBz
dWNoCiBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zYW1w
bGVRdWVyeVNldHMve3NhbXBsZV9xdWVyeV9zZXR9YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMg
bm90IGhhdmUgcGVybWlzc2lvbiB0byBhY2Nlc3MgdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeVNldF0sCiBy
ZWdhcmRsZXNzIG9mIHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RF
TklFRCBlcnJvciBpcwogcmV0dXJuZWQuCgogSWYgdGhlIHJlcXVlc3RlZAogW1NhbXBsZVF1
ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVl
cnlTZXRdIGRvZXMKIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQu
CgoMCgUEAAIABRIDcAIICgwKBQQAAgABEgNwCQ0KDAoFBAACAAMSA3AQEQoNCgUEAAIACBIE
cBJ1AwoPCggEAAIACJwIABIDcQQqCg8KBwQAAgAInwgSBHIEdAUKqQEKAgQBEgV7AJ0BARqb
ASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkxpc3RTYW1w
bGVRdWVyeVNldHNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1w
bGVRdWVyeVNldFNlcnZpY2UuTGlzdFNhbXBsZVF1ZXJ5U2V0c10KIG1ldGhvZC4KCgoKAwQB
ARIDewgiCt8CCgQEAQIAEgaDAQKIAQQazgIgUmVxdWlyZWQuIFRoZSBwYXJlbnQgbG9jYXRp
b24gcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Np
b24gdG8gbGlzdAogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdcwogdW5kZXIgdGhpcyBsb2NhdGlvbiwgcmVn
YXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCB0aGlzIGxvY2F0aW9uIGV4aXN0cywgYQogYFBF
Uk1JU1NJT05fREVOSUVEYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgAFEgSDAQIICg0K
BQQBAgABEgSDAQkPCg0KBQQBAgADEgSDARITCg8KBQQBAgAIEgaDARSIAQMKEAoIBAECAAic
CAASBIQBBCoKEQoHBAECAAifCBIGhQEEhwEFCqwCCgQEAQIBEgSQAQIWGp0CIE1heGltdW0g
bnVtYmVyIG9mCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5TYW1wbGVRdWVyeVNldF1zIHRvCiByZXR1cm4uIElmIHVuc3BlY2lmaWVk
LCBkZWZhdWx0cyB0byAxMDAuIFRoZSBtYXhpbXVtIGFsbG93ZWQgdmFsdWUgaXMgMTAwMC4K
IFZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKIElmIHRoaXMg
ZmllbGQgaXMgbmVnYXRpdmUsIGFuIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyByZXR1
cm5lZC4KCg0KBQQBAgEFEgSQAQIHCg0KBQQBAgEBEgSQAQgRCg0KBQQBAgEDEgSQARQVCoQF
CgQEAQICEgScAQIYGvUEIEEgcGFnZSB0b2tlbgogW0xpc3RTYW1wbGVRdWVyeVNldHNSZXNw
b25zZS5uZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5MaXN0U2FtcGxlUXVlcnlTZXRzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXSwKIHJl
Y2VpdmVkIGZyb20gYSBwcmV2aW91cwogW1NhbXBsZVF1ZXJ5U2V0U2VydmljZS5MaXN0U2Ft
cGxlUXVlcnlTZXRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2Ft
cGxlUXVlcnlTZXRTZXJ2aWNlLkxpc3RTYW1wbGVRdWVyeVNldHNdCiBjYWxsLiBQcm92aWRl
IHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRp
bmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBbU2FtcGxlUXVlcnlTZXRT
ZXJ2aWNlLkxpc3RTYW1wbGVRdWVyeVNldHNdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5TYW1wbGVRdWVyeVNldFNlcnZpY2UuTGlzdFNhbXBsZVF1ZXJ5U2V0c10K
IG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4gT3Ro
ZXJ3aXNlLCBhbgogYElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoF
BAECAgUSBJwBAggKDQoFBAECAgESBJwBCRMKDQoFBAECAgMSBJwBFhcKqwEKAgQCEgaiAQCr
AQEanAEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTYW1wbGVRdWVyeVNldFNlcnZpY2UuTGlz
dFNhbXBsZVF1ZXJ5U2V0c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlNhbXBsZVF1ZXJ5U2V0U2VydmljZS5MaXN0U2FtcGxlUXVlcnlTZXRzXQogbWV0aG9kLgoK
CwoDBAIBEgSiAQgjClsKBAQCAgASBKQBAjAaTSBUaGUgW1NhbXBsZVF1ZXJ5U2V0XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdcy4KCg0K
BQQCAgAEEgSkAQIKCg0KBQQCAgAGEgSkAQsZCg0KBQQCAgABEgSkARorCg0KBQQCAgADEgSk
AS4vCvcBCgQEAgIBEgSqAQIdGugBIEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcwogW0xp
c3RTYW1wbGVRdWVyeVNldHNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0U2FtcGxlUXVlcnlTZXRzUmVxdWVzdC5wYWdlX3Rv
a2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0
dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAgIBBRIEqgECCAoN
CgUEAgIBARIEqgEJGAoNCgUEAgIBAxIEqgEbHAqsAQoCBAMSBrABANMBARqdASBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLkNyZWF0ZVNhbXBsZVF1ZXJ5
U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlT
ZXRTZXJ2aWNlLkNyZWF0ZVNhbXBsZVF1ZXJ5U2V0XQogbWV0aG9kLgoKCwoDBAMBEgSwAQgj
CmkKBAQDAgASBrMBArgBBBpZIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUs
IHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoK
DQoFBAMCAAUSBLMBAggKDQoFBAMCAAESBLMBCQ8KDQoFBAMCAAMSBLMBEhMKDwoFBAMCAAgS
BrMBFLgBAwoQCggEAwIACJwIABIEtAEEKgoRCgcEAwIACJ8IEga1AQS3AQUKcAoEBAMCARIE
vQECTxpiIFJlcXVpcmVkLiBUaGUKIFtTYW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2V0XSB0bwogY3JlYXRlLgoKDQoF
BAMCAQYSBL0BAhAKDQoFBAMCAQESBL0BESEKDQoFBAMCAQMSBL0BJCUKDQoFBAMCAQgSBL0B
Jk4KEAoIBAMCAQicCAASBL0BJ00KgAcKBAQDAgISBNIBAkoa8QYgUmVxdWlyZWQuIFRoZSBJ
RCB0byB1c2UgZm9yIHRoZQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdLAogd2hpY2ggd2lsbCBiZWNvbWUg
dGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUKIFtTYW1wbGVRdWVyeVNldC5uYW1lXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXQubmFtZV0u
CgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gY3JlYXRlIHRo
ZQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuU2FtcGxlUXVlcnlTZXRdLAogcmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCBpdCBl
eGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcwogcmV0dXJuZWQuCgogVGhp
cyBmaWVsZCBtdXN0IGJlIHVuaXF1ZSBhbW9uZyBhbGwKIFtTYW1wbGVRdWVyeVNldF1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2V0XXMgd2l0
aAogdGhlIHNhbWUKIFtwYXJlbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5DcmVhdGVTYW1wbGVRdWVyeVNldFJlcXVlc3QucGFyZW50XS4KIE90aGVyd2lzZSwg
YW4gYEFMUkVBRFlfRVhJU1RTYCBlcnJvciBpcyByZXR1cm5lZC4KCiBUaGlzIGZpZWxkIG11
c3QgY29uZm9ybSB0byBbUkZDLTEwMzRdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9y
ZmMxMDM0KQogc3RhbmRhcmQgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiA2MyBjaGFyYWN0ZXJz
LiBPdGhlcndpc2UsIGFuCiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQu
CgoNCgUEAwICBRIE0gECCAoNCgUEAwICARIE0gEJHAoNCgUEAwICAxIE0gEfIAoNCgUEAwIC
CBIE0gEhSQoQCggEAwICCJwIABIE0gEiSAqsAQoCBAQSBtgBAOgBARqdASBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlTZXRTZXJ2aWNlLlVwZGF0ZVNhbXBsZVF1ZXJ5U2V0
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRT
ZXJ2aWNlLlVwZGF0ZVNhbXBsZVF1ZXJ5U2V0XQogbWV0aG9kLgoKCwoDBAQBEgTYAQgjCpcD
CgQEBAIAEgTjAQJPGogDIFJlcXVpcmVkLiBUaGUgc2FtcGxlIHF1ZXJ5IHNldCB0byB1cGRh
dGUuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gdXBkYXRl
IHRoZQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuU2FtcGxlUXVlcnlTZXRdLAogcmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCBp
dCBleGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcwogcmV0dXJuZWQuCgog
SWYgdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5TYW1wbGVRdWVyeVNldF0gdG8KIHVwZGF0ZSBkb2VzIG5vdCBleGlzdCBhIGBO
T1RfRk9VTkRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAQCAAYSBOMBAhAKDQoFBAQCAAES
BOMBESEKDQoFBAQCAAMSBOMBJCUKDQoFBAQCAAgSBOMBJk4KEAoIBAQCAAicCAASBOMBJ00K
jQEKBAQEAgESBOcBAiwafyBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRl
ZCBpbXBvcnRlZCAnc2FtcGxlIHF1ZXJ5IHNldCcgdG8KIHVwZGF0ZS4gSWYgbm90IHNldCwg
d2lsbCBieSBkZWZhdWx0IHVwZGF0ZSBhbGwgZmllbGRzLgoKDQoFBAQCAQYSBOcBAhsKDQoF
BAQCAQESBOcBHCcKDQoFBAQCAQMSBOcBKisKrAEKAgQFEgbtAQCBAgEanQEgUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1NhbXBsZVF1ZXJ5U2V0U2VydmljZS5EZWxldGVTYW1wbGVRdWVyeVNl
dF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5U2V0
U2VydmljZS5EZWxldGVTYW1wbGVRdWVyeVNldF0KIG1ldGhvZC4KCgsKAwQFARIE7QEIIwqw
BAoEBAUCABIG+wECgAIEGp8EIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YKIFtT
YW1wbGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNh
bXBsZVF1ZXJ5U2V0XSwgc3VjaAogYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vc2FtcGxlUXVlcnlTZXRzL3tzYW1wbGVfcXVlcnlfc2V0fWAuCgogSWYg
dGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gZGVsZXRlIHRoZQogW1Nh
bXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2Ft
cGxlUXVlcnlTZXRdLAogcmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMs
IGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcwogcmV0dXJuZWQuCgogSWYgdGhlCiBb
U2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5T
YW1wbGVRdWVyeVNldF0gdG8KIGRlbGV0ZSBkb2VzIG5vdCBleGlzdCwgYSBgTk9UX0ZPVU5E
YCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQFAgAFEgT7AQIICg0KBQQFAgABEgT7AQkNCg0K
BQQFAgADEgT7ARARCg8KBQQFAgAIEgb7ARKAAgMKEAoIBAUCAAicCAASBPwBBCoKEQoHBAUC
AAifCBIG/QEE/wEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest ===
    # Fields for GetSampleQuerySetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsRequest ===
    # Fields for ListSampleQuerySetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsResponse ===
    # Fields for ListSampleQuerySetsResponse
    # Field: sample_query_sets Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuerySet)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::CreateSampleQuerySetRequest ===
    # Fields for CreateSampleQuerySetRequest
    # Field: parent Type: 9 ()
    # Field: sample_query_set Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuerySet)
    # Field: sample_query_set_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::UpdateSampleQuerySetRequest ===
    # Fields for UpdateSampleQuerySetRequest
    # Field: sample_query_set Type: 11 (.google.cloud.discoveryengine.v1alpha.SampleQuerySet)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::DeleteSampleQuerySetRequest ===
    # Fields for DeleteSampleQuerySetRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::SampleQuerySetServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::SampleQuerySetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::SampleQuerySetServiceClient

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
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService',
        method         => 'GetSampleQuerySet',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet',
    });
}

sub list_sample_query_sets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService',
        method         => 'ListSampleQuerySets',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsResponse',
    });
}

sub create_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::CreateSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService',
        method         => 'CreateSampleQuerySet',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet',
    });
}

sub update_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::UpdateSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService',
        method         => 'UpdateSampleQuerySet',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet',
    });
}

sub delete_sample_query_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::DeleteSampleQuerySetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService',
        method         => 'DeleteSampleQuerySet',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/sample_query_set_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/sample_query_set_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest

Request message for
[SampleQuerySetService.GetSampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.GetSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet], such
as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}`.

If the caller does not have permission to access the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet],
regardless of whether or not it exists, a PERMISSION_DENIED error is
returned.

If the requested
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet] does
not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsRequest

Request message for
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.ListSampleQuerySets]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location resource name, such as
`projects/{project}/locations/{location}`.

If the caller does not have permission to list
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet]s
under this location, regardless of whether or not this location exists, a
`PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet]s to
return. If unspecified, defaults to 100. The maximum allowed value is 1000.
Values above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListSampleQuerySetsResponse.next_page_token][google.cloud.discoveryengine.v1alpha.ListSampleQuerySetsResponse.next_page_token],
received from a previous
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.ListSampleQuerySets]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.ListSampleQuerySets]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsResponse

Response message for
[SampleQuerySetService.ListSampleQuerySets][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.ListSampleQuerySets]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_query_sets() >> / C<< $msg->sample_query_sets($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet>)

The [SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSampleQuerySetsRequest.page_token][google.cloud.discoveryengine.v1alpha.ListSampleQuerySetsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::CreateSampleQuerySetRequest

Request message for
[SampleQuerySetService.CreateSampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.CreateSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->sample_query_set() >> / C<< $msg->sample_query_set($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet>)

Required. The
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet] to
create.

=item * C<< $msg->sample_query_set_id() >> / C<< $msg->sample_query_set_id($value) >>

Type: C<String>

Required. The ID to use for the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet],
which will become the final component of the
[SampleQuerySet.name][google.cloud.discoveryengine.v1alpha.SampleQuerySet.name].

If the caller does not have permission to create the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet],
regardless of whether or not it exists, a `PERMISSION_DENIED` error is
returned.

This field must be unique among all
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet]s with
the same
[parent][google.cloud.discoveryengine.v1alpha.CreateSampleQuerySetRequest.parent].
Otherwise, an `ALREADY_EXISTS` error is returned.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::UpdateSampleQuerySetRequest

Request message for
[SampleQuerySetService.UpdateSampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.UpdateSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_query_set() >> / C<< $msg->sample_query_set($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet>)

Required. The sample query set to update.

If the caller does not have permission to update the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet],
regardless of whether or not it exists, a `PERMISSION_DENIED` error is
returned.

If the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet] to
update does not exist a `NOT_FOUND` error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported 'sample query set' to
update. If not set, will by default update all fields.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::DeleteSampleQuerySetRequest

Request message for
[SampleQuerySetService.DeleteSampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySetService.DeleteSampleQuerySet]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet], such
as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}`.

If the caller does not have permission to delete the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet],
regardless of whether or not it exists, a `PERMISSION_DENIED` error is
returned.

If the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet] to
delete does not exist, a `NOT_FOUND` error is returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
