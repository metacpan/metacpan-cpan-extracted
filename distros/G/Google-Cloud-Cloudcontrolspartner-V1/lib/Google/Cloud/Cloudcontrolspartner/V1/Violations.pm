package Google::Cloud::Cloudcontrolspartner::V1::Violations;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvdmlvbGF0aW9ucy5wcm90
bxIkZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhpnb29nbGUvdHlwZS9pbnRlcnZhbC5wcm90byK/
DwoJVmlvbGF0aW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIlCgtkZXNjcmlwdGlvbhgC
IAEoCUID4EEDUgtkZXNjcmlwdGlvbhI+CgpiZWdpbl90aW1lGAMgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgliZWdpblRpbWUSQAoLdXBkYXRlX3RpbWUYBCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQgoMcmVzb2x2
ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgtyZXNvbHZl
VGltZRIfCghjYXRlZ29yeRgGIAEoCUID4EEDUghjYXRlZ29yeRJQCgVzdGF0ZRgHIAEoDjI1
Lmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5WaW9sYXRpb24uU3RhdGVC
A+BBA1IFc3RhdGUSPwoYbm9uX2NvbXBsaWFudF9vcmdfcG9saWN5GAggASgJQgbgQQPgQQVS
FW5vbkNvbXBsaWFudE9yZ1BvbGljeRIbCglmb2xkZXJfaWQYCSABKANSCGZvbGRlcklkEmIK
C3JlbWVkaWF0aW9uGA0gASgLMjsuZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVy
LnYxLlZpb2xhdGlvbi5SZW1lZGlhdGlvbkID4EEDUgtyZW1lZGlhdGlvbhroCAoLUmVtZWRp
YXRpb24ScQoMaW5zdHJ1Y3Rpb25zGAEgASgLMkguZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJv
bHNwYXJ0bmVyLnYxLlZpb2xhdGlvbi5SZW1lZGlhdGlvbi5JbnN0cnVjdGlvbnNCA+BBAlIM
aW5zdHJ1Y3Rpb25zEikKEGNvbXBsaWFudF92YWx1ZXMYAiADKAlSD2NvbXBsaWFudFZhbHVl
cxJ7ChByZW1lZGlhdGlvbl90eXBlGAMgASgOMksuZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJv
bHNwYXJ0bmVyLnYxLlZpb2xhdGlvbi5SZW1lZGlhdGlvbi5SZW1lZGlhdGlvblR5cGVCA+BB
A1IPcmVtZWRpYXRpb25UeXBlGvoDCgxJbnN0cnVjdGlvbnMSgAEKE2djbG91ZF9pbnN0cnVj
dGlvbnMYASABKAsyTy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuVmlv
bGF0aW9uLlJlbWVkaWF0aW9uLkluc3RydWN0aW9ucy5HY2xvdWRSEmdjbG91ZEluc3RydWN0
aW9ucxKDAQoUY29uc29sZV9pbnN0cnVjdGlvbnMYAiABKAsyUC5nb29nbGUuY2xvdWQuY2xv
dWRjb250cm9sc3BhcnRuZXIudjEuVmlvbGF0aW9uLlJlbWVkaWF0aW9uLkluc3RydWN0aW9u
cy5Db25zb2xlUhNjb25zb2xlSW5zdHJ1Y3Rpb25zGnIKBkdjbG91ZBInCg9nY2xvdWRfY29t
bWFuZHMYASADKAlSDmdjbG91ZENvbW1hbmRzEhQKBXN0ZXBzGAIgAygJUgVzdGVwcxIpChBh
ZGRpdGlvbmFsX2xpbmtzGAMgAygJUg9hZGRpdGlvbmFsTGlua3MabQoHQ29uc29sZRIhCgxj
b25zb2xlX3VyaXMYASADKAlSC2NvbnNvbGVVcmlzEhQKBXN0ZXBzGAIgAygJUgVzdGVwcxIp
ChBhZGRpdGlvbmFsX2xpbmtzGAMgAygJUg9hZGRpdGlvbmFsTGlua3MiwAIKD1JlbWVkaWF0
aW9uVHlwZRIgChxSRU1FRElBVElPTl9UWVBFX1VOU1BFQ0lGSUVEEAASLAooUkVNRURJQVRJ
T05fQk9PTEVBTl9PUkdfUE9MSUNZX1ZJT0xBVElPThABEjgKNFJFTUVESUFUSU9OX0xJU1Rf
QUxMT1dFRF9WQUxVRVNfT1JHX1BPTElDWV9WSU9MQVRJT04QAhI3CjNSRU1FRElBVElPTl9M
SVNUX0RFTklFRF9WQUxVRVNfT1JHX1BPTElDWV9WSU9MQVRJT04QAxJGCkJSRU1FRElBVElP
Tl9SRVNUUklDVF9DTUVLX0NSWVBUT19LRVlfUFJPSkVDVFNfT1JHX1BPTElDWV9WSU9MQVRJ
T04QBBIiCh5SRU1FRElBVElPTl9SRVNPVVJDRV9WSU9MQVRJT04QBSJLCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEgwKCFJFU09MVkVEEAESDgoKVU5SRVNPTFZFRBACEg0KCUVY
Q0VQVElPThADOr4B6kG6AQotY2xvdWRjb250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5jb20v
VmlvbGF0aW9uEnJvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9j
YXRpb259L2N1c3RvbWVycy97Y3VzdG9tZXJ9L3dvcmtsb2Fkcy97d29ya2xvYWR9L3Zpb2xh
dGlvbnMve3Zpb2xhdGlvbn0qCnZpb2xhdGlvbnMyCXZpb2xhdGlvbiKhAgoVTGlzdFZpb2xh
dGlvbnNSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC+kEvEi1jbG91ZGNvbnRyb2xzcGFy
dG5lci5nb29nbGVhcGlzLmNvbS9WaW9sYXRpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiAB
KAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4S
GwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdv
cmRlckJ5EjYKCGludGVydmFsGAYgASgLMhUuZ29vZ2xlLnR5cGUuSW50ZXJ2YWxCA+BBAVII
aW50ZXJ2YWwiswEKFkxpc3RWaW9sYXRpb25zUmVzcG9uc2USTwoKdmlvbGF0aW9ucxgBIAMo
CzIvLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5WaW9sYXRpb25SCnZp
b2xhdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3Vu
cmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJgChNHZXRWaW9sYXRpb25SZXF1ZXN0EkkK
BG5hbWUYASABKAlCNeBBAvpBLwotY2xvdWRjb250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5j
b20vVmlvbGF0aW9uUgRuYW1lQpMCCihjb20uZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNw
YXJ0bmVyLnYxQg9WaW9sYXRpb25zUHJvdG9QAVpcY2xvdWQuZ29vZ2xlLmNvbS9nby9jbG91
ZGNvbnRyb2xzcGFydG5lci9hcGl2MS9jbG91ZGNvbnRyb2xzcGFydG5lcnBiO2Nsb3VkY29u
dHJvbHNwYXJ0bmVycGKqAiRHb29nbGUuQ2xvdWQuQ2xvdWRDb250cm9sc1BhcnRuZXIuVjHK
AiRHb29nbGVcQ2xvdWRcQ2xvdWRDb250cm9sc1BhcnRuZXJcVjHqAidHb29nbGU6OkNsb3Vk
OjpDbG91ZENvbnRyb2xzUGFydG5lcjo6VjFK3EEKBxIFDgDoAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkK
AgMCEgMUACkKCQoCAwMSAxUAJAoICgEIEgMXAEEKCQoCCCUSAxcAQQoICgEIEgMYAHMKCQoC
CAsSAxgAcwoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADAKCQoCCAgSAxoAMAoICgEI
EgMbAEEKCQoCCAESAxsAQQoICgEIEgMcAEEKCQoCCCkSAxwAQQoICgEIEgMdAEAKCQoCCC0S
Ax0AQAosCgIEABIFIACuAQEaHyBEZXRhaWxzIG9mIHJlc291cmNlIFZpb2xhdGlvbgoKCgoD
BAABEgMgCBEKCwoDBAAHEgQhAiYECg0KBQQAB50IEgQhAiYECmQKBAQAAwASBCoCcgMaViBS
ZXByZXNlbnRzIHJlbWVkaWF0aW9uIGd1aWRhbmNlIHRvIHJlc29sdmUgY29tcGxpYW5jZSB2
aW9sYXRpb24gZm9yCiBBc3N1cmVkV29ya2xvYWQKCgwKBQQAAwABEgMqChUKNQoGBAADAAMA
EgQsBEoFGiUgSW5zdHJ1Y3Rpb25zIHRvIHJlbWVkaWF0ZSB2aW9sYXRpb24KCg4KBwQAAwAD
AAESAywMGApQCggEAAMAAwADABIELgY3Bxo+IFJlbWVkaWF0aW9uIGluc3RydWN0aW9ucyB0
byByZXNvbHZlIHZpb2xhdGlvbiB2aWEgZ2Nsb3VkIGNsaQoKEAoJBAADAAMAAwABEgMuDhQK
OAoKBAADAAMAAwACABIDMAgsGiUgR2Nsb3VkIGNvbW1hbmQgdG8gcmVzb2x2ZSB2aW9sYXRp
b24KChIKCwQAAwADAAMAAgAEEgMwCBAKEgoLBAADAAMAAwACAAUSAzARFwoSCgsEAAMAAwAD
AAIAARIDMBgnChIKCwQAAwADAAMAAgADEgMwKisKPgoKBAADAAMAAwACARIDMwgiGisgU3Rl
cHMgdG8gcmVzb2x2ZSB2aW9sYXRpb24gdmlhIGdjbG91ZCBjbGkKChIKCwQAAwADAAMAAgEE
EgMzCBAKEgoLBAADAAMAAwACAQUSAzMRFwoSCgsEAAMAAwADAAIBARIDMxgdChIKCwQAAwAD
AAMAAgEDEgMzICEKRQoKBAADAAMAAwACAhIDNggtGjIgQWRkaXRpb25hbCB1cmxzIGZvciBt
b3JlIGluZm9ybWF0aW9uIGFib3V0IHN0ZXBzCgoSCgsEAAMAAwADAAICBBIDNggQChIKCwQA
AwADAAMAAgIFEgM2ERcKEgoLBAADAAMAAwACAgESAzYYKAoSCgsEAAMAAwADAAICAxIDNiss
ClMKCAQAAwADAAMBEgQ6BkMHGkEgUmVtZWRpYXRpb24gaW5zdHJ1Y3Rpb25zIHRvIHJlc29s
dmUgdmlvbGF0aW9uIHZpYSBjbG91ZCBjb25zb2xlCgoQCgkEAAMAAwADAQESAzoOFQpKCgoE
AAMAAwADAQIAEgM8CCkaNyBMaW5rIHRvIGNvbnNvbGUgcGFnZSB3aGVyZSB2aW9sYXRpb25z
IGNhbiBiZSByZXNvbHZlZAoKEgoLBAADAAMAAwECAAQSAzwIEAoSCgsEAAMAAwADAQIABRID
PBEXChIKCwQAAwADAAMBAgABEgM8GCQKEgoLBAADAAMAAwECAAMSAzwnKApBCgoEAAMAAwAD
AQIBEgM/CCIaLiBTdGVwcyB0byByZXNvbHZlIHZpb2xhdGlvbiB2aWEgY2xvdWQgY29uc29s
ZQoKEgoLBAADAAMAAwECAQQSAz8IEAoSCgsEAAMAAwADAQIBBRIDPxEXChIKCwQAAwADAAMB
AgEBEgM/GB0KEgoLBAADAAMAAwECAQMSAz8gIQpFCgoEAAMAAwADAQICEgNCCC0aMiBBZGRp
dGlvbmFsIHVybHMgZm9yIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQgc3RlcHMKChIKCwQAAwAD
AAMBAgIEEgNCCBAKEgoLBAADAAMAAwECAgUSA0IRFwoSCgsEAAMAAwADAQICARIDQhgoChIK
CwQAAwADAAMBAgIDEgNCKywKTwoIBAADAAMAAgASA0YGJRo+IFJlbWVkaWF0aW9uIGluc3Ry
dWN0aW9ucyB0byByZXNvbHZlIHZpb2xhdGlvbiB2aWEgZ2Nsb3VkIGNsaQoKEAoJBAADAAMA
AgAGEgNGBgwKEAoJBAADAAMAAgABEgNGDSAKEAoJBAADAAMAAgADEgNGIyQKUgoIBAADAAMA
AgESA0kGJxpBIFJlbWVkaWF0aW9uIGluc3RydWN0aW9ucyB0byByZXNvbHZlIHZpb2xhdGlv
biB2aWEgY2xvdWQgY29uc29sZQoKEAoJBAADAAMAAgEGEgNJBg0KEAoJBAADAAMAAgEBEgNJ
DiIKEAoJBAADAAMAAgEDEgNJJSYKogIKBgQAAwAEABIEUARkBRqRAiBDbGFzc2lmeWluZyBy
ZW1lZGlhdGlvbiBpbnRvIHZhcmlvdXMgdHlwZXMgYmFzZWQgb24gdGhlIGtpbmQgb2YKIHZp
b2xhdGlvbi4gRm9yIGV4YW1wbGUsIHZpb2xhdGlvbnMgY2F1c2VkIGR1ZSB0byBjaGFuZ2Vz
IGluIGJvb2xlYW4gb3JnCiBwb2xpY3kgcmVxdWlyZXMgZGlmZmVyZW50IHJlbWVkaWF0aW9u
IGluc3RydWN0aW9ucyBjb21wYXJlZCB0byB2aW9sYXRpb24KIGNhdXNlZCBkdWUgdG8gY2hh
bmdlcyBpbiBhbGxvd2VkIHZhbHVlcyBvZiBsaXN0IG9yZyBwb2xpY3kuCgoOCgcEAAMABAAB
EgNQCRgKLwoIBAADAAQAAgASA1IGJxoeIFVuc3BlY2lmaWVkIHJlbWVkaWF0aW9uIHR5cGUK
ChAKCQQAAwAEAAIAARIDUgYiChAKCQQAAwAEAAIAAhIDUiUmCjoKCAQAAwAEAAIBEgNVBjMa
KSBSZW1lZGlhdGlvbiB0eXBlIGZvciBib29sZWFuIG9yZyBwb2xpY3kKChAKCQQAAwAEAAIB
ARIDVQYuChAKCQQAAwAEAAIBAhIDVTEyCmkKCAQAAwAEAAICEgNZBj8aWCBSZW1lZGlhdGlv
biB0eXBlIGZvciBsaXN0IG9yZyBwb2xpY3kgd2hpY2ggaGF2ZSBhbGxvd2VkIHZhbHVlcyBp
biB0aGUKIG1vbml0b3JpbmcgcnVsZQoKEAoJBAADAAQAAgIBEgNZBjoKEAoJBAADAAQAAgIC
EgNZPT4KaAoIBAADAAQAAgMSA10GPhpXIFJlbWVkaWF0aW9uIHR5cGUgZm9yIGxpc3Qgb3Jn
IHBvbGljeSB3aGljaCBoYXZlIGRlbmllZCB2YWx1ZXMgaW4gdGhlCiBtb25pdG9yaW5nIHJ1
bGUKChAKCQQAAwAEAAIDARIDXQY5ChAKCQQAAwAEAAIDAhIDXTw9CkkKCAQAAwAEAAIEEgNg
Bk0aOCBSZW1lZGlhdGlvbiB0eXBlIGZvciBnY3AucmVzdHJpY3RDbWVrQ3J5cHRvS2V5UHJv
amVjdHMKChAKCQQAAwAEAAIEARIDYAZIChAKCQQAAwAEAAIEAhIDYEtMCjsKCAQAAwAEAAIF
EgNjBikaKiBSZW1lZGlhdGlvbiB0eXBlIGZvciByZXNvdXJjZSB2aW9sYXRpb24uCgoQCgkE
AAMABAACBQESA2MGJAoQCgkEAAMABAACBQISA2MnKApJCgYEAAMAAgASA2cESxo6IFJlcXVp
cmVkLiBSZW1lZGlhdGlvbiBpbnN0cnVjdGlvbnMgdG8gcmVzb2x2ZSB2aW9sYXRpb25zCgoO
CgcEAAMAAgAGEgNnBBAKDgoHBAADAAIAARIDZxEdCg4KBwQAAwACAAMSA2cgIQoOCgcEAAMA
AgAIEgNnIkoKEQoKBAADAAIACJwIABIDZyNJCp8BCgYEAAMAAgESA2wEKRqPASBWYWx1ZXMg
dGhhdCBjYW4gcmVzb2x2ZSB0aGUgdmlvbGF0aW9uCiBGb3IgZXhhbXBsZTogZm9yIGxpc3Qg
b3JnIHBvbGljeSB2aW9sYXRpb25zLCB0aGlzIHdpbGwgZWl0aGVyIGJlIHRoZSBsaXN0CiBv
ZiBhbGxvd2VkIG9yIGRlbmllZCB2YWx1ZXMKCg4KBwQAAwACAQQSA2wEDAoOCgcEAAMAAgEF
EgNsDRMKDgoHBAADAAIBARIDbBQkCg4KBwQAAwACAQMSA2wnKApgCgYEAAMAAgISBHAEcTQa
UCBPdXRwdXQgb25seS4gUmVtZWRpYXRpb24gdHlwZSBiYXNlZCBvbiB0aGUgdHlwZSBvZiBv
cmcgcG9saWN5IHZhbHVlcwogdmlvbGF0ZWQKCg4KBwQAAwACAgYSA3AEEwoOCgcEAAMAAgIB
EgNwFCQKDgoHBAADAAICAxIDcCcoCg4KBwQAAwACAggSA3EIMwoRCgoEAAMAAgIInAgAEgNx
CTIKJwoEBAAEABIFdQKBAQMaGCBWaW9sYXRpb24gU3RhdGUgVmFsdWVzCgoMCgUEAAQAARID
dQcMCiMKBgQABAACABIDdwQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgABEgN3
BBUKDgoHBAAEAAIAAhIDdxgZCicKBgQABAACARIDegQRGhggVmlvbGF0aW9uIGlzIHJlc29s
dmVkLgoKDgoHBAAEAAIBARIDegQMCg4KBwQABAACAQISA3oPEAooCgYEAAQAAgISA30EExoZ
IFZpb2xhdGlvbiBpcyBVbnJlc29sdmVkCgoOCgcEAAQAAgIBEgN9BA4KDgoHBAAEAAICAhID
fRESCigKBgQABAACAxIEgAEEEhoYIFZpb2xhdGlvbiBpcyBFeGNlcHRpb24KCg8KBwQABAAC
AwESBIABBA0KDwoHBAAEAAIDAhIEgAEQEQqaAQoEBAACABIEhQECPRqLASBJZGVudGlmaWVy
LiBGb3JtYXQ6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jdXN0b21lcnMve2N1c3RvbWVyfS93b3JrbG9hZHMve3dvcmtsb2FkfS92aW9s
YXRpb25zL3t2aW9sYXRpb259YAoKDQoFBAACAAUSBIUBAggKDQoFBAACAAESBIUBCQ0KDQoF
BAACAAMSBIUBEBEKDQoFBAACAAgSBIUBEjwKEAoIBAACAAicCAASBIUBEzsKegoEBAACARIE
iQECRRpsIE91dHB1dCBvbmx5LiBEZXNjcmlwdGlvbiBmb3IgdGhlIFZpb2xhdGlvbi4KIGUu
Zy4gT3JnUG9saWN5IGdjcC5yZXNvdXJjZUxvY2F0aW9ucyBoYXMgbm9uIGNvbXBsaWFudCB2
YWx1ZS4KCg0KBQQAAgEFEgSJAQIICg0KBQQAAgEBEgSJAQkUCg0KBQQAAgEDEgSJARcYCg0K
BQQAAgEIEgSJARlEChAKCAQAAgEInAgAEgSJARpDCk8KBAQAAgISBowBAo0BMho/IE91dHB1
dCBvbmx5LiBUaW1lIG9mIHRoZSBldmVudCB3aGljaCB0cmlnZ2VyZWQgdGhlIFZpb2xhdGlv
bi4KCg0KBQQAAgIGEgSMAQIbCg0KBQQAAgIBEgSMARwmCg0KBQQAAgIDEgSMASkqCg0KBQQA
AgIIEgSNAQYxChAKCAQAAgIInAgAEgSNAQcwClMKBAQAAgMSBpABApEBMhpDIE91dHB1dCBv
bmx5LiBUaGUgbGFzdCB0aW1lIHdoZW4gdGhlIFZpb2xhdGlvbiByZWNvcmQgd2FzIHVwZGF0
ZWQuCgoNCgUEAAIDBhIEkAECGwoNCgUEAAIDARIEkAEcJwoNCgUEAAIDAxIEkAEqKwoNCgUE
AAIDCBIEkQEGMQoQCggEAAIDCJwIABIEkQEHMAp7CgQEAAIEEgaVAQKWATIaayBPdXRwdXQg
b25seS4gVGltZSBvZiB0aGUgZXZlbnQgd2hpY2ggZml4ZWQgdGhlIFZpb2xhdGlvbi4KIElm
IHRoZSB2aW9sYXRpb24gaXMgQUNUSVZFIHRoaXMgd2lsbCBiZSBlbXB0eS4KCg0KBQQAAgQG
EgSVAQIbCg0KBQQAAgQBEgSVARwoCg0KBQQAAgQDEgSVASssCg0KBQQAAgQIEgSWAQYxChAK
CAQAAgQInAgAEgSWAQcwCoMBCgQEAAIFEgSaAQJCGnUgT3V0cHV0IG9ubHkuIENhdGVnb3J5
IHVuZGVyIHdoaWNoIHRoaXMgdmlvbGF0aW9uIGlzIG1hcHBlZC4KIGUuZy4gTG9jYXRpb24s
IFNlcnZpY2UgVXNhZ2UsIEFjY2VzcywgRW5jcnlwdGlvbiwgZXRjLgoKDQoFBAACBQUSBJoB
AggKDQoFBAACBQESBJoBCREKDQoFBAACBQMSBJoBFBUKDQoFBAACBQgSBJoBFkEKEAoIBAAC
BQicCAASBJoBF0AKMwoEBAACBhIEnQECPholIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUg
dmlvbGF0aW9uCgoNCgUEAAIGBhIEnQECBwoNCgUEAAIGARIEnQEIDQoNCgUEAAIGAxIEnQEQ
EQoNCgUEAAIGCBIEnQESPQoQCggEAAIGCJwIABIEnQETPAq+AgoEBAACBxIGpAECpwEEGq0C
IE91dHB1dCBvbmx5LiBJbW11dGFibGUuIE5hbWUgb2YgdGhlIE9yZ1BvbGljeSB3aGljaCB3
YXMgbW9kaWZpZWQgd2l0aAogbm9uLWNvbXBsaWFudCBjaGFuZ2UgYW5kIHJlc3VsdGVkIHRo
aXMgdmlvbGF0aW9uLiBGb3JtYXQ6CiAgYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vcG9s
aWNpZXMve2NvbnN0cmFpbnRfbmFtZX1gCiAgYGZvbGRlcnMve2ZvbGRlcl9pZH0vcG9saWNp
ZXMve2NvbnN0cmFpbnRfbmFtZX1gCiAgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9p
ZH0vcG9saWNpZXMve2NvbnN0cmFpbnRfbmFtZX1gCgoNCgUEAAIHBRIEpAECCAoNCgUEAAIH
ARIEpAEJIQoNCgUEAAIHAxIEpAEkJQoPCgUEAAIHCBIGpAEmpwEDChAKCAQAAgcInAgAEgSl
AQQtChAKCAQAAgcInAgBEgSmAQQrCi4KBAQAAggSBKoBAhYaICBUaGUgZm9sZGVyX2lkIG9m
IHRoZSB2aW9sYXRpb24KCg0KBQQAAggFEgSqAQIHCg0KBQQAAggBEgSqAQgRCg0KBQQAAggD
EgSqARQVCj0KBAQAAgkSBK0BAksaLyBPdXRwdXQgb25seS4gQ29tcGxpYW5jZSB2aW9sYXRp
b24gcmVtZWRpYXRpb24KCg0KBQQAAgkGEgStAQINCg0KBQQAAgkBEgStAQ4ZCg0KBQQAAgkD
EgStARweCg0KBQQAAgkIEgStAR9KChAKCAQAAgkInAgAEgStASBJCjkKAgQBEgaxAQDOAQEa
KyBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGxpc3Qgb2YgVmlvbGF0aW9ucwoKCwoDBAEBEgSx
AQgdCpMBCgQEAQIAEga1AQK6AQQaggEgUmVxdWlyZWQuIFBhcmVudCByZXNvdXJjZQogRm9y
bWF0CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jdXN0b21lcnMve2N1c3RvbWVyfS93b3JrbG9hZHMve3dvcmtsb2FkfWAKCg0KBQQBAgAF
EgS1AQIICg0KBQQBAgABEgS1AQkPCg0KBQQBAgADEgS1ARITCg8KBQQBAgAIEga1ARS6AQMK
EAoIBAECAAicCAASBLYBBCoKEQoHBAECAAifCBIGtwEEuQEFCrABCgQEAQIBEgS/AQI/GqEB
IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgY3VzdG9tZXJzIHJvdyB0byByZXR1
cm4uIFRoZSBzZXJ2aWNlIG1heQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYg
dW5zcGVjaWZpZWQsIGF0IG1vc3QgMTAgY3VzdG9tZXJzIHdpbGwgYmUKIHJldHVybmVkLgoK
DQoFBAECAQUSBL8BAgcKDQoFBAECAQESBL8BCBEKDQoFBAECAQMSBL8BFBUKDQoFBAECAQgS
BL8BFj4KEAoIBAECAQicCAASBL8BFz0KhgEKBAQBAgISBMMBAkEaeCBPcHRpb25hbC4gQSBw
YWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RWaW9sYXRpb25zYCBj
YWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoN
CgUEAQICBRIEwwECCAoNCgUEAQICARIEwwEJEwoNCgUEAQICAxIEwwEWFwoNCgUEAQICCBIE
wwEYQAoQCggEAQICCJwIABIEwwEZPworCgQEAQIDEgTGAQI9Gh0gT3B0aW9uYWwuIEZpbHRl
cmluZyByZXN1bHRzCgoNCgUEAQIDBRIExgECCAoNCgUEAQIDARIExgEJDwoNCgUEAQIDAxIE
xgESEwoNCgUEAQIDCBIExgEUPAoQCggEAQIDCJwIABIExgEVOwo7CgQEAQIEEgTJAQI/Gi0g
T3B0aW9uYWwuIEhpbnQgZm9yIGhvdyB0byBvcmRlciB0aGUgcmVzdWx0cwoKDQoFBAECBAUS
BMkBAggKDQoFBAECBAESBMkBCREKDQoFBAECBAMSBMkBFBUKDQoFBAECBAgSBMkBFj4KEAoI
BAECBAicCAASBMkBFz0KfQoEBAECBRIEzQECTRpvIE9wdGlvbmFsLiBTcGVjaWZpZXMgdGhl
IGludGVydmFsIGZvciByZXRyaWV2aW5nIHZpb2xhdGlvbnMuCiBpZiB1bnNwZWNpZmllZCwg
YWxsIHZpb2xhdGlvbnMgd2lsbCBiZSByZXR1cm5lZC4KCg0KBQQBAgUGEgTNAQIWCg0KBQQB
AgUBEgTNARcfCg0KBQQBAgUDEgTNASIjCg0KBQQBAgUIEgTNASRMChAKCAQBAgUInAgAEgTN
ASVLCkUKAgQCEgbRAQDcAQEaNyBSZXNwb25zZSBtZXNzYWdlIGZvciBsaXN0IGN1c3RvbWVy
IHZpb2xhdGlvbiByZXF1ZXN0cwoKCwoDBAIBEgTRAQgeCiEKBAQCAgASBNMBAiQaEyBMaXN0
IG9mIHZpb2xhdGlvbgoKDQoFBAICAAQSBNMBAgoKDQoFBAICAAYSBNMBCxQKDQoFBAICAAES
BNMBFR8KDQoFBAICAAMSBNMBIiMKjQEKBAQCAgESBNcBAh0afyBBIHRva2VuIHRoYXQgY2Fu
IGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJ
ZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2Vz
LgoKDQoFBAICAQUSBNcBAggKDQoFBAICAQESBNcBCRgKDQoFBAICAQMSBNcBGxwKgQEKBAQC
AgISBNsBAiIacyBXb3JrbG9hZHMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZCBkdWUgdG8g
cGVybWlzc2lvbiBlcnJvcnMgb3IgYW55IG90aGVyCiBlcnJvci4gUmVmOiBodHRwczovL2dv
b2dsZS5haXAuZGV2LzIxNwoKDQoFBAICAgQSBNsBAgoKDQoFBAICAgUSBNsBCxEKDQoFBAIC
AgESBNsBEh0KDQoFBAICAgMSBNsBICEKLwoCBAMSBt8BAOgBARohIE1lc3NhZ2UgZm9yIGdl
dHRpbmcgYSBWaW9sYXRpb24KCgsKAwQDARIE3wEIGwqaAQoEBAMCABIG4gEC5wEEGokBIFJl
cXVpcmVkLiBGb3JtYXQ6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9jdXN0b21lcnMve2N1c3RvbWVyfS93b3JrbG9hZHMve3dvcmtsb2Fk
fS92aW9sYXRpb25zL3t2aW9sYXRpb259YAoKDQoFBAMCAAUSBOIBAggKDQoFBAMCAAESBOIB
CQ0KDQoFBAMCAAMSBOIBEBEKDwoFBAMCAAgSBuIBEucBAwoQCggEAwIACJwIABIE4wEEKgoR
CgcEAwIACJ8IEgbkAQTmAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation ===
    # Fields for Violation
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: begin_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: resolve_time Type: 11 (.google.protobuf.Timestamp)
    # Field: category Type: 9 ()
    # Field: state Type: 14 (.google.cloud.cloudcontrolspartner.v1.Violation.State)
    # Field: non_compliant_org_policy Type: 9 ()
    # Field: folder_id Type: 3 ()
    # Field: remediation Type: 11 (.google.cloud.cloudcontrolspartner.v1.Violation.Remediation)

# Enum: Violation::State
our $Violation_STATE_UNSPECIFIED = 0;
our $Violation_RESOLVED = 1;
our $Violation_UNRESOLVED = 2;
our $Violation_EXCEPTION = 3;

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsRequest ===
    # Fields for ListViolationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: interval Type: 11 (.google.type.Interval)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsResponse ===
    # Fields for ListViolationsResponse
    # Field: violations Type: 11 (.google.cloud.cloudcontrolspartner.v1.Violation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Violations::GetViolationRequest ===
    # Fields for GetViolationRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Violations - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/violations.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::Violations;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation->new({
        name => $name,
        description => $description,
        begin_time => $begin_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/violations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation

Details of resource Violation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/violations/{violation}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Description for the Violation.
e.g. OrgPolicy gcp.resourceLocations has non compliant value.

=item * C<< $msg->begin_time() >> / C<< $msg->begin_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time of the event which triggered the Violation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time when the Violation record was updated.

=item * C<< $msg->resolve_time() >> / C<< $msg->resolve_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time of the event which fixed the Violation.
If the violation is ACTIVE this will be empty.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

Output only. Category under which this violation is mapped.
e.g. Location, Service Usage, Access, Encryption, etc.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::Violation::State>)

Output only. State of the violation

=item * C<< $msg->non_compliant_org_policy() >> / C<< $msg->non_compliant_org_policy($value) >>

Type: C<String>

Output only. Immutable. Name of the OrgPolicy which was modified with
non-compliant change and resulted this violation. Format:
 `projects/{project_number}/policies/{constraint_name}`
 `folders/{folder_id}/policies/{constraint_name}`
 `organizations/{organization_id}/policies/{constraint_name}`

=item * C<< $msg->folder_id() >> / C<< $msg->folder_id($value) >>

Type: C<Int64>

The folder_id of the violation

=item * C<< $msg->remediation() >> / C<< $msg->remediation($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation::Remediation>)

Output only. Compliance violation remediation

=back

=head3 Enum: Violation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RESOLVED> => C<1>

=item * C<UNRESOLVED> => C<2>

=item * C<EXCEPTION> => C<3>

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsRequest

Message for requesting list of Violations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource
Format
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of customers row to return. The service may
return fewer than this value. If unspecified, at most 10 customers will be
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListViolations` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=item * C<< $msg->interval() >> / C<< $msg->interval($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

Optional. Specifies the interval for retrieving violations.
if unspecified, all violations will be returned.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsResponse

Response message for list customer violation requests

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->violations() >> / C<< $msg->violations($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation>)

List of violation

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Workloads that could not be reached due to permission errors or any other
error. Ref: https://google.aip.dev/217

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Violations::GetViolationRequest

Message for getting a Violation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/violations/{violation}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::Violations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
