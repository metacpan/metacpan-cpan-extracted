package Google::Cloud::Apihub::V1::CollectService;

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
    eval { require Google::Cloud::Apihub::V1::CommonFields };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXBpaHViL3YxL2NvbGxlY3Rfc2VydmljZS5wcm90bxIWZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKmdvb2dsZS9jbG91ZC9hcGlodWIvdjEvY29tbW9u
X2ZpZWxkcy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i7gIKFUNvbGxlY3RBcGlEYXRhUmVxdWVz
dBJFCghsb2NhdGlvbhgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20v
TG9jYXRpb25SCGxvY2F0aW9uElQKD2NvbGxlY3Rpb25fdHlwZRgCIAEoDjImLmdvb2dsZS5j
bG91ZC5hcGlodWIudjEuQ29sbGVjdGlvblR5cGVCA+BBAlIOY29sbGVjdGlvblR5cGUSVQoP
cGx1Z2luX2luc3RhbmNlGAMgASgJQizgQQL6QSYKJGFwaWh1Yi5nb29nbGVhcGlzLmNvbS9Q
bHVnaW5JbnN0YW5jZVIOcGx1Z2luSW5zdGFuY2USIAoJYWN0aW9uX2lkGAQgASgJQgPgQQJS
CGFjdGlvbklkEj8KCGFwaV9kYXRhGAUgASgLMh8uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5B
cGlEYXRhQgPgQQJSB2FwaURhdGEibQoHQXBpRGF0YRJaChFhcGlfbWV0YWRhdGFfbGlzdBgB
IAEoCzInLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuQXBpTWV0YWRhdGFMaXN0QgPgQQFIAFIP
YXBpTWV0YWRhdGFMaXN0QgYKBERhdGEiXgoPQXBpTWV0YWRhdGFMaXN0EksKDGFwaV9tZXRh
ZGF0YRgBIAMoCzIjLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuQVBJTWV0YWRhdGFCA+BBAlIL
YXBpTWV0YWRhdGEi1wIKC0FQSU1ldGFkYXRhEjIKA2FwaRgBIAEoCzIbLmdvb2dsZS5jbG91
ZC5hcGlodWIudjEuQXBpQgPgQQJSA2FwaRJICgh2ZXJzaW9ucxgCIAMoCzInLmdvb2dsZS5j
bG91ZC5hcGlodWIudjEuVmVyc2lvbk1ldGFkYXRhQgPgQQFSCHZlcnNpb25zEiQKC29yaWdp
bmFsX2lkGAMgASgJQgPgQQFSCm9yaWdpbmFsSWQSUQoUb3JpZ2luYWxfY3JlYXRlX3RpbWUY
BCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQFSEm9yaWdpbmFsQ3JlYXRl
VGltZRJRChRvcmlnaW5hbF91cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBAlISb3JpZ2luYWxVcGRhdGVUaW1lIrEDCg9WZXJzaW9uTWV0YWRhdGES
PgoHdmVyc2lvbhgBIAEoCzIfLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuVmVyc2lvbkID4EEC
Ugd2ZXJzaW9uEj8KBXNwZWNzGAIgAygLMiQuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5TcGVj
TWV0YWRhdGFCA+BBAVIFc3BlY3MSUQoLZGVwbG95bWVudHMYBCADKAsyKi5nb29nbGUuY2xv
dWQuYXBpaHViLnYxLkRlcGxveW1lbnRNZXRhZGF0YUID4EEBUgtkZXBsb3ltZW50cxIkCgtv
cmlnaW5hbF9pZBgFIAEoCUID4EEBUgpvcmlnaW5hbElkElEKFG9yaWdpbmFsX2NyZWF0ZV90
aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUhJvcmlnaW5hbENy
ZWF0ZVRpbWUSUQoUb3JpZ2luYWxfdXBkYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQJSEm9yaWdpbmFsVXBkYXRlVGltZSKRAgoMU3BlY01ldGFkYXRh
EjUKBHNwZWMYASABKAsyHC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLlNwZWNCA+BBAlIEc3Bl
YxIkCgtvcmlnaW5hbF9pZBgCIAEoCUID4EEBUgpvcmlnaW5hbElkElEKFG9yaWdpbmFsX2Ny
ZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUhJvcmln
aW5hbENyZWF0ZVRpbWUSUQoUb3JpZ2luYWxfdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQJSEm9yaWdpbmFsVXBkYXRlVGltZSKpAgoSRGVwbG95
bWVudE1ldGFkYXRhEkcKCmRlcGxveW1lbnQYASABKAsyIi5nb29nbGUuY2xvdWQuYXBpaHVi
LnYxLkRlcGxveW1lbnRCA+BBAlIKZGVwbG95bWVudBIkCgtvcmlnaW5hbF9pZBgCIAEoCUID
4EEBUgpvcmlnaW5hbElkElEKFG9yaWdpbmFsX2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUhJvcmlnaW5hbENyZWF0ZVRpbWUSUQoUb3JpZ2lu
YWxfdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQJS
Em9yaWdpbmFsVXBkYXRlVGltZSIYChZDb2xsZWN0QXBpRGF0YVJlc3BvbnNlKmkKDkNvbGxl
Y3Rpb25UeXBlEh8KG0NPTExFQ1RJT05fVFlQRV9VTlNQRUNJRklFRBAAEhoKFkNPTExFQ1RJ
T05fVFlQRV9VUFNFUlQQARIaChZDT0xMRUNUSU9OX1RZUEVfREVMRVRFEAIyzwIKDUFwaUh1
YkNvbGxlY3QS8gEKDkNvbGxlY3RBcGlEYXRhEi0uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5D
b2xsZWN0QXBpRGF0YVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpEB
gtPkkwI5IjQvdjEve2xvY2F0aW9uPXByb2plY3RzLyovbG9jYXRpb25zLyp9OmNvbGxlY3RB
cGlEYXRhOgEq2kEhbG9jYXRpb24sY29sbGVjdGlvbl90eXBlLGFwaV9kYXRhykErChZDb2xs
ZWN0QXBpRGF0YVJlc3BvbnNlEhFPcGVyYXRpb25NZXRhZGF0YRpJykEVYXBpaHViLmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybUK1AQoaY29tLmdvb2dsZS5jbG91ZC5hcGlodWIudjFCE0NvbGxlY3RTZXJ2aWNlUHJv
dG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlodWIvYXBpdjEvYXBpaHVicGI7YXBpaHVi
cGKqAhZHb29nbGUuQ2xvdWQuQXBpSHViLlYxygIWR29vZ2xlXENsb3VkXEFwaUh1YlxWMeoC
GUdvb2dsZTo6Q2xvdWQ6OkFwaUh1Yjo6VjFK/DkKBxIFDgDaASEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA0CgkKAgMFEgMXAC0KCQoCAwYSAxgAKQoI
CgEIEgMaADMKCQoCCCUSAxoAMwoICgEIEgMbAEkKCQoCCAsSAxsASQoICgEIEgMcACIKCQoC
CAoSAxwAIgoICgEIEgMdADQKCQoCCAgSAx0ANAoICgEIEgMeADMKCQoCCAESAx4AMwoICgEI
EgMfADMKCQoCCCkSAx8AMwoICgEIEgMgADIKCQoCCC0SAyAAMgquAQoCBgASBCUANwEaoQEg
VGhpcyBzZXJ2aWNlIGV4cG9zZXMgbWV0aG9kcyB1c2VkIGZvciBjb2xsZWN0aW5nIHZhcmlv
dXMgdHlwZXMgb2YgZGF0YSBmcm9tCiBkaWZmZXJlbnQgZmlyc3QgcGFydHkgYW5kIHRoaXJk
IHBhcnR5IHNvdXJjZXMgYW5kIHB1c2ggaXQgdG8gSHViJ3MgY29sbGVjdAogbGF5ZXIuCgoK
CgMGAAESAyUIFQoKCgMGAAMSAyYCPQoMCgUGAAOZCBIDJgI9CgsKAwYAAxIEJwIoNwoNCgUG
AAOaCBIEJwIoNwpSCgQGAAIAEgQrAjYDGkQgQ29sbGVjdCBBUEkgZGF0YSBmcm9tIGEgc291
cmNlIGFuZCBwdXNoIGl0IHRvIEh1YidzIGNvbGxlY3QgbGF5ZXIuCgoMCgUGAAIAARIDKwYU
CgwKBQYAAgACEgMrFSoKDAoFBgACAAMSAywPKwoNCgUGAAIABBIELQQwBgoRCgkGAAIABLDK
vCISBC0EMAYKDAoFBgACAAQSAzEETwoPCggGAAIABJsIABIDMQRPCg0KBQYAAgAEEgQyBDUG
Cg8KBwYAAgAEmQgSBDIENQYKLgoCBQASBDoARQEaIiBUaGUgdHlwZSBvZiB0aGUgY29sbGVj
dCByZXF1ZXN0LgoKCgoDBQABEgM6BRMKVwoEBQACABIDPAIiGkogVGhlIGRlZmF1bHQgdmFs
dWUuIFRoaXMgdmFsdWUgaXMgdXNlZCBpZiB0aGUgY29sbGVjdGlvbiB0eXBlIGlzIG9taXR0
ZWQuCgoMCgUFAAIAARIDPAIdCgwKBQUAAgACEgM8ICEKcwoEBQACARIDQAIdGmYgVGhlIGNv
bGxlY3Rpb24gdHlwZSBpcyB1cHNlcnQuIFRoaXMgc2hvdWxkIGJlIHVzZWQgd2hlbiBhbiBB
UEkgaXMgY3JlYXRlZAogb3IgdXBkYXRlZCBhdCB0aGUgc291cmNlLgoKDAoFBQACAQESA0AC
GAoMCgUFAAIBAhIDQBscCmgKBAUAAgISA0QCHRpbIFRoZSBjb2xsZWN0aW9uIHR5cGUgaXMg
ZGVsZXRlLiBUaGlzIHNob3VsZCBiZSB1c2VkIHdoZW4gYW4gQVBJIGlzIGRlbGV0ZWQKIGF0
IHRoZSBzb3VyY2UuCgoMCgUFAAICARIDRAIYCgwKBQUAAgICEgNEGxwKMgoCBAASBEgAZwEa
JiBUaGUgQ29sbGVjdEFwaURhdGEgbWV0aG9kJ3MgcmVxdWVzdC4KCgoKAwQAARIDSAgdCo0B
CgQEAAIAEgRLAlAEGn8gUmVxdWlyZWQuIFRoZSByZWdpb25hbCBsb2NhdGlvbiBvZiB0aGUg
QVBJIGh1YiBpbnN0YW5jZSBhbmQgaXRzIHJlc291cmNlcy4KIEZvcm1hdDogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCgwKBQQAAgAFEgNLAggKDAoFBAAC
AAESA0sJEQoMCgUEAAIAAxIDSxQVCg0KBQQAAgAIEgRLFlADCg8KCAQAAgAInAgAEgNMBCoK
DwoHBAACAAifCBIETQRPBQqPAQoEBAACARIDVAJOGoEBIFJlcXVpcmVkLiBUaGUgdHlwZSBv
ZiBjb2xsZWN0aW9uLiBBcHBsaWVzIHRvIGFsbCBlbnRyaWVzIGluCiBbYXBpX2RhdGFdW2dv
b2dsZS5jbG91ZC5hcGlodWIudjEuQ29sbGVjdEFwaURhdGFSZXF1ZXN0LmFwaV9kYXRhXS4K
CgwKBQQAAgEGEgNUAhAKDAoFBAACAQESA1QRIAoMCgUEAAIBAxIDVCMkCgwKBQQAAgEIEgNU
JU0KDwoIBAACAQicCAASA1QmTAqiAQoEBAACAhIEWQJeBBqTASBSZXF1aXJlZC4gVGhlIHBs
dWdpbiBpbnN0YW5jZSBjb2xsZWN0aW5nIHRoZSBBUEkgZGF0YS4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcGx1Z2lucy97cGx1Z2lufS9p
bnN0YW5jZXMve2luc3RhbmNlfWAuCgoMCgUEAAICBRIDWQIICgwKBQQAAgIBEgNZCRgKDAoF
BAACAgMSA1kbHAoNCgUEAAICCBIEWR1eAwoPCggEAAICCJwIABIDWgQqCg8KBwQAAgIInwgS
BFsEXQUKpQEKBAQAAgMSA2MCQBqXASBSZXF1aXJlZC4gVGhlIGFjdGlvbiBJRCB0byBiZSB1
c2VkIGZvciBjb2xsZWN0aW5nIHRoZSBBUEkgZGF0YS4KIFRoaXMgc2hvdWxkIG1hcCB0byBv
bmUgb2YgdGhlIGFjdGlvbiBJRHMgc3BlY2lmaWVkCiBpbiBhY3Rpb24gY29uZmlncyBpbiB0
aGUgcGx1Z2luLgoKDAoFBAACAwUSA2MCCAoMCgUEAAIDARIDYwkSCgwKBQQAAgMDEgNjFRYK
DAoFBAACAwgSA2MXPwoPCggEAAIDCJwIABIDYxg+CjYKBAQAAgQSA2YCQBopIFJlcXVpcmVk
LiBUaGUgQVBJIGRhdGEgdG8gYmUgY29sbGVjdGVkLgoKDAoFBAACBAYSA2YCCQoMCgUEAAIE
ARIDZgoSCgwKBQQAAgQDEgNmFRYKDAoFBAACBAgSA2YXPwoPCggEAAIECJwIABIDZhg+CisK
AgQBEgRqAHEBGh8gVGhlIEFQSSBkYXRhIHRvIGJlIGNvbGxlY3RlZC4KCgoKAwQBARIDaggP
CikKBAQBCAASBGwCcAMaGyBUaGUgZGF0YSB0byBiZSBjb2xsZWN0ZWQuCgoMCgUEAQgAARID
bAgMCjMKBAQBAgASBG4EbzEaJSBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgQVBJIG1ldGFkYXRh
LgoKDAoFBAECAAYSA24EEwoMCgUEAQIAARIDbhQlCgwKBQQBAgADEgNuKCkKDAoFBAECAAgS
A28IMAoPCggEAQIACJwIABIDbwkvCjgKAgQCEgR0AHgBGiwgVGhlIG1lc3NhZ2UgdG8gaG9s
ZCByZXBlYXRlZCBBUEkgbWV0YWRhdGEuCgoKCgMEAgESA3QIFwozCgQEAgIAEgR2AncvGiUg
UmVxdWlyZWQuIFRoZSBsaXN0IG9mIEFQSSBtZXRhZGF0YS4KCgwKBQQCAgAEEgN2AgoKDAoF
BAICAAYSA3YLFgoMCgUEAgIAARIDdhcjCgwKBQQCAgADEgN2JicKDAoFBAICAAgSA3cGLgoP
CggEAgIACJwIABIDdwctCiAKAgQDEgV7AJABARoTIFRoZSBBUEkgbWV0YWRhdGEuCgoKCgME
AwESA3sIEwq6AQoEBAMCABIDfwI3GqwBIFJlcXVpcmVkLiBUaGUgQVBJIHJlc291cmNlIHRv
IGJlIHB1c2hlZCB0byBIdWIncyBjb2xsZWN0IGxheWVyLiBUaGUgSUQgb2YKIHRoZSBBUEkg
cmVzb3VyY2Ugd2lsbCBiZSBnZW5lcmF0ZWQgYnkgSHViIHRvIGVuc3VyZSB1bmlxdWVuZXNz
IGFjcm9zcyBhbGwKIEFQSXMgYWNyb3NzIHN5c3RlbXMuCgoMCgUEAwIABhIDfwIFCgwKBQQD
AgABEgN/BgkKDAoFBAMCAAMSA38MDQoMCgUEAwIACBIDfw42Cg8KCAQDAgAInAgAEgN/DzUK
TAoEBAMCARIGggECgwEvGjwgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIHZlcnNpb25zIHByZXNl
bnQgaW4gYW4gQVBJIHJlc291cmNlLgoKDQoFBAMCAQQSBIIBAgoKDQoFBAMCAQYSBIIBCxoK
DQoFBAMCAQESBIIBGyMKDQoFBAMCAQMSBIIBJicKDQoFBAMCAQgSBIMBBi4KEAoIBAMCAQic
CAASBIMBBy0KagoEBAMCAhIEhwECQhpcIE9wdGlvbmFsLiBUaGUgdW5pcXVlIGlkZW50aWZp
ZXIgb2YgdGhlIEFQSSBpbiB0aGUgc3lzdGVtIHdoZXJlIGl0IHdhcwogb3JpZ2luYWxseSBj
cmVhdGVkLgoKDQoFBAMCAgUSBIcBAggKDQoFBAMCAgESBIcBCRQKDQoFBAMCAgMSBIcBFxgK
DQoFBAMCAggSBIcBGUEKEAoIBAMCAgicCAASBIcBGkAKWAoEBAMCAxIGigECiwEvGkggT3B0
aW9uYWwuIFRpbWVzdGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIEFQSSB3YXMgY3JlYXRlZCBh
dCB0aGUgc291cmNlLgoKDQoFBAMCAwYSBIoBAhsKDQoFBAMCAwESBIoBHDAKDQoFBAMCAwMS
BIoBMzQKDQoFBAMCAwgSBIsBBi4KEAoIBAMCAwicCAASBIsBBy0KXQoEBAMCBBIGjgECjwEv
Gk0gUmVxdWlyZWQuIFRpbWVzdGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIEFQSSB3YXMgbGFz
dCB1cGRhdGVkIGF0IHRoZSBzb3VyY2UuCgoNCgUEAwIEBhIEjgECGwoNCgUEAwIEARIEjgEc
MAoNCgUEAwIEAxIEjgEzNAoNCgUEAwIECBIEjwEGLgoQCggEAwIECJwIABIEjwEHLQpLCgIE
BBIGkwEArgEBGj0gVGhlIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBhIHZlcnNpb24gb2Yg
dGhlIEFQSSByZXNvdXJjZS4KCgsKAwQEARIEkwEIFwp/CgQEBAIAEgSWAQI/GnEgUmVxdWly
ZWQuIFJlcHJlc2VudHMgYSB2ZXJzaW9uIG9mIHRoZSBBUEkgcmVzb3VyY2UgaW4gQVBJIGh1
Yi4gVGhlIElEIG9mCiB0aGUgdmVyc2lvbiB3aWxsIGJlIGdlbmVyYXRlZCBieSBIdWIuCgoN
CgUEBAIABhIElgECCQoNCgUEBAIAARIElgEKEQoNCgUEBAIAAxIElgEUFQoNCgUEBAIACBIE
lgEWPgoQCggEBAIACJwIABIElgEXPQqCAQoEBAQCARIEmgECSxp0IE9wdGlvbmFsLiBUaGUg
c3BlY3MgYXNzb2NpYXRlZCB3aXRoIHRoaXMgdmVyc2lvbi4KIE5vdGUgdGhhdCBhbiBBUEkg
dmVyc2lvbiBjYW4gYmUgYXNzb2NpYXRlZCB3aXRoIG11bHRpcGxlIHNwZWNzLgoKDQoFBAQC
AQQSBJoBAgoKDQoFBAQCAQYSBJoBCxcKDQoFBAQCAQESBJoBGB0KDQoFBAQCAQMSBJoBICEK
DQoFBAQCAQgSBJoBIkoKEAoIBAQCAQicCAASBJoBI0kKvgEKBAQEAgISBp8BAqABLxqtASBP
cHRpb25hbC4gVGhlIGRlcGxveW1lbnRzIGxpbmtlZCB0byB0aGlzIEFQSSB2ZXJzaW9uLgog
Tm90ZTogQSBwYXJ0aWN1bGFyIEFQSSB2ZXJzaW9uIGNvdWxkIGJlIGRlcGxveWVkIHRvIG11
bHRpcGxlIGRlcGxveW1lbnRzCiAoZm9yIGRldiBkZXBsb3ltZW50LCBVQVQgZGVwbG95bWVu
dCwgZXRjLikKCg0KBQQEAgIEEgSfAQIKCg0KBQQEAgIGEgSfAQsdCg0KBQQEAgIBEgSfAR4p
Cg0KBQQEAgIDEgSfASwtCg0KBQQEAgIIEgSgAQYuChAKCAQEAgIInAgAEgSgAQctCm4KBAQE
AgMSBKQBAkIaYCBPcHRpb25hbC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSB2ZXJz
aW9uIGluIHRoZSBzeXN0ZW0gd2hlcmUgaXQgd2FzCiBvcmlnaW5hbGx5IGNyZWF0ZWQuCgoN
CgUEBAIDBRIEpAECCAoNCgUEBAIDARIEpAEJFAoNCgUEBAIDAxIEpAEXGAoNCgUEBAIDCBIE
pAEZQQoQCggEBAIDCJwIABIEpAEaQApcCgQEBAIEEganAQKoAS8aTCBPcHRpb25hbC4gVGlt
ZXN0YW1wIGluZGljYXRpbmcgd2hlbiB0aGUgdmVyc2lvbiB3YXMgY3JlYXRlZCBhdCB0aGUg
c291cmNlLgoKDQoFBAQCBAYSBKcBAhsKDQoFBAQCBAESBKcBHDAKDQoFBAQCBAMSBKcBMzQK
DQoFBAQCBAgSBKgBBi4KEAoIBAQCBAicCAASBKgBBy0KYgoEBAQCBRIGrAECrQEvGlIgUmVx
dWlyZWQuIFRpbWVzdGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIHZlcnNpb24gd2FzIGxhc3Qg
dXBkYXRlZCBhdCB0aGUKIHNvdXJjZS4KCg0KBQQEAgUGEgSsAQIbCg0KBQQEAgUBEgSsARww
Cg0KBQQEAgUDEgSsATM0Cg0KBQQEAgUIEgStAQYuChAKCAQEAgUInAgAEgStAQctCkcKAgQF
EgaxAQDCAQEaOSBUaGUgbWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIGEgc3BlYyBvZiB0aGUg
QVBJIHZlcnNpb24uCgoLCgMEBQESBLEBCBQKfgoEBAUCABIEtAECORpwIFJlcXVpcmVkLiBU
aGUgc3BlYyByZXNvdXJjZSB0byBiZSBwdXNoZWQgdG8gSHViJ3MgY29sbGVjdCBsYXllci4g
VGhlIElEIG9mCiB0aGUgc3BlYyB3aWxsIGJlIGdlbmVyYXRlZCBieSBIdWIuCgoNCgUEBQIA
BhIEtAECBgoNCgUEBQIAARIEtAEHCwoNCgUEBQIAAxIEtAEODwoNCgUEBQIACBIEtAEQOAoQ
CggEBQIACJwIABIEtAERNwprCgQEBQIBEgS4AQJCGl0gT3B0aW9uYWwuIFRoZSB1bmlxdWUg
aWRlbnRpZmllciBvZiB0aGUgc3BlYyBpbiB0aGUgc3lzdGVtIHdoZXJlIGl0IHdhcwogb3Jp
Z2luYWxseSBjcmVhdGVkLgoKDQoFBAUCAQUSBLgBAggKDQoFBAUCAQESBLgBCRQKDQoFBAUC
AQMSBLgBFxgKDQoFBAUCAQgSBLgBGUEKEAoIBAUCAQicCAASBLgBGkAKWQoEBAUCAhIGuwEC
vAEvGkkgT3B0aW9uYWwuIFRpbWVzdGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIHNwZWMgd2Fz
IGNyZWF0ZWQgYXQgdGhlIHNvdXJjZS4KCg0KBQQFAgIGEgS7AQIbCg0KBQQFAgIBEgS7ARww
Cg0KBQQFAgIDEgS7ATM0Cg0KBQQFAgIIEgS8AQYuChAKCAQFAgIInAgAEgS8AQctCl8KBAQF
AgMSBsABAsEBLxpPIFJlcXVpcmVkLiBUaW1lc3RhbXAgaW5kaWNhdGluZyB3aGVuIHRoZSBz
cGVjIHdhcyBsYXN0IHVwZGF0ZWQgYXQgdGhlCiBzb3VyY2UuCgoNCgUEBQIDBhIEwAECGwoN
CgUEBQIDARIEwAEcMAoNCgUEBQIDAxIEwAEzNAoNCgUEBQIDCBIEwQEGLgoQCggEBQIDCJwI
ABIEwQEHLQo6CgIEBhIGxQEA1wEBGiwgVGhlIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBh
IGRlcGxveW1lbnQuCgoLCgMEBgESBMUBCBoKigEKBAQGAgASBMgBAkUafCBSZXF1aXJlZC4g
VGhlIGRlcGxveW1lbnQgcmVzb3VyY2UgdG8gYmUgcHVzaGVkIHRvIEh1YidzIGNvbGxlY3Qg
bGF5ZXIuIFRoZQogSUQgb2YgdGhlIGRlcGxveW1lbnQgd2lsbCBiZSBnZW5lcmF0ZWQgYnkg
SHViLgoKDQoFBAYCAAYSBMgBAgwKDQoFBAYCAAESBMgBDRcKDQoFBAYCAAMSBMgBGhsKDQoF
BAYCAAgSBMgBHEQKEAoIBAYCAAicCAASBMgBHUMKcQoEBAYCARIEzAECQhpjIE9wdGlvbmFs
LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGRlcGxveW1lbnQgaW4gdGhlIHN5c3Rl
bSB3aGVyZSBpdAogd2FzIG9yaWdpbmFsbHkgY3JlYXRlZC4KCg0KBQQGAgEFEgTMAQIICg0K
BQQGAgEBEgTMAQkUCg0KBQQGAgEDEgTMARcYCg0KBQQGAgEIEgTMARlBChAKCAQGAgEInAgA
EgTMARpACmAKBAQGAgISBtABAtEBLxpQIE9wdGlvbmFsLiBUaW1lc3RhbXAgaW5kaWNhdGlu
ZyB3aGVuIHRoZSBkZXBsb3ltZW50IHdhcyBjcmVhdGVkIGF0IHRoZQogc291cmNlLgoKDQoF
BAYCAgYSBNABAhsKDQoFBAYCAgESBNABHDAKDQoFBAYCAgMSBNABMzQKDQoFBAYCAggSBNEB
Bi4KEAoIBAYCAgicCAASBNEBBy0KZQoEBAYCAxIG1QEC1gEvGlUgUmVxdWlyZWQuIFRpbWVz
dGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIGRlcGxveW1lbnQgd2FzIGxhc3QgdXBkYXRlZCBh
dCB0aGUKIHNvdXJjZS4KCg0KBQQGAgMGEgTVAQIbCg0KBQQGAgMBEgTVARwwCg0KBQQGAgMD
EgTVATM0Cg0KBQQGAgMIEgTWAQYuChAKCAQGAgMInAgAEgTWAQctCjMKAgQHEgTaAQAhGicg
VGhlIENvbGxlY3RBcGlEYXRhIG1ldGhvZCdzIHJlc3BvbnNlLgoKCwoDBAcBEgTaAQgeYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest ===
    # Fields for CollectApiDataRequest
    # Field: location Type: 9 ()
    # Field: collection_type Type: 14 (.google.cloud.apihub.v1.CollectionType)
    # Field: plugin_instance Type: 9 ()
    # Field: action_id Type: 9 ()
    # Field: api_data Type: 11 (.google.cloud.apihub.v1.ApiData)

# === Message: Google::Cloud::Apihub::V1::CollectService::ApiData ===
    # Fields for ApiData
    # Field: api_metadata_list Type: 11 (.google.cloud.apihub.v1.ApiMetadataList)

# === Message: Google::Cloud::Apihub::V1::CollectService::ApiMetadataList ===
    # Fields for ApiMetadataList
    # Field: api_metadata Type: 11 (.google.cloud.apihub.v1.APIMetadata)

# === Message: Google::Cloud::Apihub::V1::CollectService::APIMetadata ===
    # Fields for APIMetadata
    # Field: api Type: 11 (.google.cloud.apihub.v1.Api)
    # Field: versions Type: 11 (.google.cloud.apihub.v1.VersionMetadata)
    # Field: original_id Type: 9 ()
    # Field: original_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: original_update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Apihub::V1::CollectService::VersionMetadata ===
    # Fields for VersionMetadata
    # Field: version Type: 11 (.google.cloud.apihub.v1.Version)
    # Field: specs Type: 11 (.google.cloud.apihub.v1.SpecMetadata)
    # Field: deployments Type: 11 (.google.cloud.apihub.v1.DeploymentMetadata)
    # Field: original_id Type: 9 ()
    # Field: original_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: original_update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Apihub::V1::CollectService::SpecMetadata ===
    # Fields for SpecMetadata
    # Field: spec Type: 11 (.google.cloud.apihub.v1.Spec)
    # Field: original_id Type: 9 ()
    # Field: original_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: original_update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Apihub::V1::CollectService::DeploymentMetadata ===
    # Fields for DeploymentMetadata
    # Field: deployment Type: 11 (.google.cloud.apihub.v1.Deployment)
    # Field: original_id Type: 9 ()
    # Field: original_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: original_update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Apihub::V1::CollectService::CollectApiDataResponse ===
    # Fields for CollectApiDataResponse

# === Service Client: Google::Cloud::Apihub::V1::CollectService::ApiHubCollectClient ===
package Google::Cloud::Apihub::V1::CollectService::ApiHubCollectClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::CollectService::ApiHubCollectClient

Client stub representing the remote C<ApiHubCollect> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apihub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apihub.googleapis.com:443' );

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

sub collect_api_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubCollect',
        method         => 'CollectApiData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::CollectService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/collect_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::CollectService;

    my $msg = Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest->new({
        location => $location,
        collection_type => $collection_type,
        plugin_instance => $plugin_instance,
        action_id => $action_id,
    });

    # Read or update a field
    my $val = $msg->location();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/collect_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest

The CollectApiData method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. The regional location of the API hub instance and its resources.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->collection_type() >> / C<< $msg->collection_type($value) >>

Type: C<Enum> (L<Google::Cloud::Apihub::V1::CollectionType>)

Required. The type of collection. Applies to all entries in
[api_data][google.cloud.apihub.v1.CollectApiDataRequest.api_data].

=item * C<< $msg->plugin_instance() >> / C<< $msg->plugin_instance($value) >>

Type: C<String>

Required. The plugin instance collecting the API data.
Format:
`projects/{project}/locations/{location}/plugins/{plugin}/instances/{instance}`.

=item * C<< $msg->action_id() >> / C<< $msg->action_id($value) >>

Type: C<String>

Required. The action ID to be used for collecting the API data.
This should map to one of the action IDs specified
in action configs in the plugin.

=item * C<< $msg->api_data() >> / C<< $msg->api_data($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CollectService::ApiData>)

Required. The API data to be collected.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::ApiData

The API data to be collected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_metadata_list() >> / C<< $msg->api_metadata_list($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CollectService::ApiMetadataList>)

Optional. The list of API metadata.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::ApiMetadataList

The message to hold repeated API metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_metadata() >> / C<< $msg->api_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CollectService::APIMetadata>)

Required. The list of API metadata.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::APIMetadata

The API metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api() >> / C<< $msg->api($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::Api>)

Required. The API resource to be pushed to Hub's collect layer. The ID of
the API resource will be generated by Hub to ensure uniqueness across all
APIs across systems.

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CollectService::VersionMetadata>)

Optional. The list of versions present in an API resource.

=item * C<< $msg->original_id() >> / C<< $msg->original_id($value) >>

Type: C<String>

Optional. The unique identifier of the API in the system where it was
originally created.

=item * C<< $msg->original_create_time() >> / C<< $msg->original_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp indicating when the API was created at the source.

=item * C<< $msg->original_update_time() >> / C<< $msg->original_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Timestamp indicating when the API was last updated at the source.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::VersionMetadata

The metadata associated with a version of the API resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::Version>)

Required. Represents a version of the API resource in API hub. The ID of
the version will be generated by Hub.

=item * C<< $msg->specs() >> / C<< $msg->specs($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CollectService::SpecMetadata>)

Optional. The specs associated with this version.
Note that an API version can be associated with multiple specs.

=item * C<< $msg->deployments() >> / C<< $msg->deployments($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CollectService::DeploymentMetadata>)

Optional. The deployments linked to this API version.
Note: A particular API version could be deployed to multiple deployments
(for dev deployment, UAT deployment, etc.)

=item * C<< $msg->original_id() >> / C<< $msg->original_id($value) >>

Type: C<String>

Optional. The unique identifier of the version in the system where it was
originally created.

=item * C<< $msg->original_create_time() >> / C<< $msg->original_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp indicating when the version was created at the source.

=item * C<< $msg->original_update_time() >> / C<< $msg->original_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Timestamp indicating when the version was last updated at the
source.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::SpecMetadata

The metadata associated with a spec of the API version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->spec() >> / C<< $msg->spec($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::Spec>)

Required. The spec resource to be pushed to Hub's collect layer. The ID of
the spec will be generated by Hub.

=item * C<< $msg->original_id() >> / C<< $msg->original_id($value) >>

Type: C<String>

Optional. The unique identifier of the spec in the system where it was
originally created.

=item * C<< $msg->original_create_time() >> / C<< $msg->original_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp indicating when the spec was created at the source.

=item * C<< $msg->original_update_time() >> / C<< $msg->original_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Timestamp indicating when the spec was last updated at the
source.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::DeploymentMetadata

The metadata associated with a deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::Deployment>)

Required. The deployment resource to be pushed to Hub's collect layer. The
ID of the deployment will be generated by Hub.

=item * C<< $msg->original_id() >> / C<< $msg->original_id($value) >>

Type: C<String>

Optional. The unique identifier of the deployment in the system where it
was originally created.

=item * C<< $msg->original_create_time() >> / C<< $msg->original_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Timestamp indicating when the deployment was created at the
source.

=item * C<< $msg->original_update_time() >> / C<< $msg->original_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Timestamp indicating when the deployment was last updated at the
source.

=back

=head2 Google::Cloud::Apihub::V1::CollectService::CollectApiDataResponse

The CollectApiData method's response.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::CollectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
