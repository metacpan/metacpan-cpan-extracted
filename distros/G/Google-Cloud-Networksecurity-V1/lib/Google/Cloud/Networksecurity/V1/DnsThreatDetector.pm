package Google::Cloud::Networksecurity::V1::DnsThreatDetector;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL2Ruc190aHJlYXRfZGV0ZWN0b3Iu
cHJvdG8SH2dvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEaHGdvb2dsZS9hcGkvYW5u
b3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIuQFChFEbnNUaHJlYXREZXRlY3Rv
chIaCgRuYW1lGAEgASgJQgbgQQjgQQVSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
WwoGbGFiZWxzGAQgAygLMj4uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MS5EbnNU
aHJlYXREZXRlY3Rvci5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSUwoRZXhjbHVkZWRfbmV0
d29ya3MYBSADKAlCJuBBAfpBIAoeY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9OZXR3b3JrUhBl
eGNsdWRlZE5ldHdvcmtzElwKCHByb3ZpZGVyGAYgASgOMjsuZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZWN1cml0eS52MS5EbnNUaHJlYXREZXRlY3Rvci5Qcm92aWRlckID4EECUghwcm92aWRl
cho5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIjIKCFByb3ZpZGVyEhgKFFBST1ZJREVSX1VOU1BFQ0lGSUVEEAASDAoISU5GT0JM
T1gQATqvAepBqwEKMG5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9EbnNUaHJlYXRE
ZXRlY3RvchJQcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Ruc1Ro
cmVhdERldGVjdG9ycy97ZG5zX3RocmVhdF9kZXRlY3Rvcn0qEmRuc1RocmVhdERldGVjdG9y
czIRZG5zVGhyZWF0RGV0ZWN0b3IitwEKHUxpc3REbnNUaHJlYXREZXRlY3RvcnNSZXF1ZXN0
ElAKBnBhcmVudBgBIAEoCUI44EEC+kEyEjBuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5j
b20vRG5zVGhyZWF0RGV0ZWN0b3JSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVII
cGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4i1QEKHkxpc3RE
bnNUaHJlYXREZXRlY3RvcnNSZXNwb25zZRJkChRkbnNfdGhyZWF0X2RldGVjdG9ycxgBIAMo
CzIyLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuRG5zVGhyZWF0RGV0ZWN0b3JS
EmRuc1RocmVhdERldGVjdG9ycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4SJQoLdW5yZWFjaGFibGUYAyADKAlCA+BBBlILdW5yZWFjaGFibGUiawobR2V0RG5z
VGhyZWF0RGV0ZWN0b3JSZXF1ZXN0EkwKBG5hbWUYASABKAlCOOBBAvpBMgowbmV0d29ya3Nl
Y3VyaXR5Lmdvb2dsZWFwaXMuY29tL0Ruc1RocmVhdERldGVjdG9yUgRuYW1lIpUCCh5DcmVh
dGVEbnNUaHJlYXREZXRlY3RvclJlcXVlc3QSUAoGcGFyZW50GAEgASgJQjjgQQL6QTISMG5l
dHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9EbnNUaHJlYXREZXRlY3RvclIGcGFyZW50
EjgKFmRuc190aHJlYXRfZGV0ZWN0b3JfaWQYAiABKAlCA+BBAVITZG5zVGhyZWF0RGV0ZWN0
b3JJZBJnChNkbnNfdGhyZWF0X2RldGVjdG9yGAMgASgLMjIuZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZWN1cml0eS52MS5EbnNUaHJlYXREZXRlY3RvckID4EECUhFkbnNUaHJlYXREZXRlY3Rv
ciLLAQoeVXBkYXRlRG5zVGhyZWF0RGV0ZWN0b3JSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrEmcKE2Ru
c190aHJlYXRfZGV0ZWN0b3IYAiABKAsyMi5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5
LnYxLkRuc1RocmVhdERldGVjdG9yQgPgQQJSEWRuc1RocmVhdERldGVjdG9yIm4KHkRlbGV0
ZURuc1RocmVhdERldGVjdG9yUmVxdWVzdBJMCgRuYW1lGAEgASgJQjjgQQL6QTIKMG5ldHdv
cmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9EbnNUaHJlYXREZXRlY3RvclIEbmFtZTKZCgoY
RG5zVGhyZWF0RGV0ZWN0b3JTZXJ2aWNlEuIBChZMaXN0RG5zVGhyZWF0RGV0ZWN0b3JzEj4u
Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MS5MaXN0RG5zVGhyZWF0RGV0ZWN0b3Jz
UmVxdWVzdBo/Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuTGlzdERuc1RocmVh
dERldGVjdG9yc1Jlc3BvbnNlIkeC0+STAjgSNi92MS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyp9L2Ruc1RocmVhdERldGVjdG9yc9pBBnBhcmVudBLPAQoUR2V0RG5zVGhyZWF0
RGV0ZWN0b3ISPC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLkdldERuc1RocmVh
dERldGVjdG9yUmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuRG5z
VGhyZWF0RGV0ZWN0b3IiRYLT5JMCOBI2L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovZG5zVGhyZWF0RGV0ZWN0b3JzLyp92kEEbmFtZRKYAgoXQ3JlYXRlRG5zVGhyZWF0RGV0
ZWN0b3ISPy5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLkNyZWF0ZURuc1RocmVh
dERldGVjdG9yUmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuRG5z
VGhyZWF0RGV0ZWN0b3IihwGC0+STAk0iNi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyp9L2Ruc1RocmVhdERldGVjdG9yczoTZG5zX3RocmVhdF9kZXRlY3RvctpBMXBhcmVu
dCxkbnNfdGhyZWF0X2RldGVjdG9yLGRuc190aHJlYXRfZGV0ZWN0b3JfaWQSmgIKF1VwZGF0
ZURuc1RocmVhdERldGVjdG9yEj8uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MS5V
cGRhdGVEbnNUaHJlYXREZXRlY3RvclJlcXVlc3QaMi5nb29nbGUuY2xvdWQubmV0d29ya3Nl
Y3VyaXR5LnYxLkRuc1RocmVhdERldGVjdG9yIokBgtPkkwJhMkovdjEve2Ruc190aHJlYXRf
ZGV0ZWN0b3IubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Ruc1RocmVhdERldGVjdG9y
cy8qfToTZG5zX3RocmVhdF9kZXRlY3RvctpBH2Ruc190aHJlYXRfZGV0ZWN0b3IsdXBkYXRl
X21hc2sSuQEKF0RlbGV0ZURuc1RocmVhdERldGVjdG9yEj8uZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZWN1cml0eS52MS5EZWxldGVEbnNUaHJlYXREZXRlY3RvclJlcXVlc3QaFi5nb29nbGUu
cHJvdG9idWYuRW1wdHkiRYLT5JMCOCo2L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovZG5zVGhyZWF0RGV0ZWN0b3JzLyp92kEEbmFtZRpSykEebmV0d29ya3NlY3VyaXR5Lmdv
b2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1w
bGF0Zm9ybULIAgojY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFCFkRuc1Ro
cmVhdERldGVjdG9yUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJp
dHkvYXBpdjEvbmV0d29ya3NlY3VyaXR5cGI7bmV0d29ya3NlY3VyaXR5cGKqAh9Hb29nbGUu
Q2xvdWQuTmV0d29ya1NlY3VyaXR5LlYxygIfR29vZ2xlXENsb3VkXE5ldHdvcmtTZWN1cml0
eVxWMeoCIkdvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjHqQU4KHmNvbXB1dGUu
Z29vZ2xlYXBpcy5jb20vTmV0d29yaxIscHJvamVjdHMve3Byb2plY3R9L2dsb2JhbC9uZXR3
b3Jrcy97bmV0d29ya31KgzMKBxIFDgDpAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
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
Y2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgAlCgkKAgMFEgMXACoKCQoCAwYSAxgAKQoICgEIEgMaADwKCQoC
CCUSAxoAPAoICgEIEgMbAGQKCQoCCAsSAxsAZAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEI
EgMdADcKCQoCCAgSAx0ANwoICgEIEgMeADwKCQoCCAESAx4APAoICgEIEgMfADwKCQoCCCkS
Ax8APAoICgEIEgMgADsKCQoCCC0SAyAAOwoJCgEIEgQhACQCCgwKBAidCAASBCEAJAIKQAoC
BgASBCcAWwEaNCBUaGUgTmV0d29yayBTZWN1cml0eSBBUEkgZm9yIEROUyBUaHJlYXQgRGV0
ZWN0b3JzLgoKCgoDBgABEgMnCCAKCgoDBgADEgMoAkYKDAoFBgADmQgSAygCRgoLCgMGAAMS
BCkCKjcKDQoFBgADmggSBCkCKjcKSQoEBgACABIELQIzAxo7IExpc3RzIERuc1RocmVhdERl
dGVjdG9ycyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAy0G
HAoMCgUGAAIAAhIDLR06CgwKBQYAAgADEgMuDy0KDQoFBgACAAQSBC8EMQYKEQoJBgACAASw
yrwiEgQvBDEGCgwKBQYAAgAEEgMyBDQKDwoIBgACAASbCAASAzIENAo/CgQGAAIBEgQ2AjwD
GjEgR2V0cyB0aGUgZGV0YWlscyBvZiBhIHNpbmdsZSBEbnNUaHJlYXREZXRlY3Rvci4KCgwK
BQYAAgEBEgM2BhoKDAoFBgACAQISAzYbNgoMCgUGAAIBAxIDNw8gCg0KBQYAAgEEEgQ4BDoG
ChEKCQYAAgEEsMq8IhIEOAQ6BgoMCgUGAAIBBBIDOwQyCg8KCAYAAgEEmwgAEgM7BDIKUAoE
BgACAhIEPwJHAxpCIENyZWF0ZXMgYSBuZXcgRG5zVGhyZWF0RGV0ZWN0b3IgaW4gYSBnaXZl
biBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgIBEgM/Bh0KDAoFBgACAgISAz8ePAoM
CgUGAAICAxIDQA8gCg0KBQYAAgIEEgRBBEQGChEKCQYAAgIEsMq8IhIEQQREBgoNCgUGAAIC
BBIERQRGPAoQCggGAAICBJsIABIERQRGPAozCgQGAAIDEgRKAlEDGiUgVXBkYXRlcyBhIHNp
bmdsZSBEbnNUaHJlYXREZXRlY3Rvci4KCgwKBQYAAgMBEgNKBh0KDAoFBgACAwISA0oePAoM
CgUGAAIDAxIDSw8gCg0KBQYAAgMEEgRMBE8GChEKCQYAAgMEsMq8IhIETARPBgoMCgUGAAID
BBIDUARNCg8KCAYAAgMEmwgAEgNQBE0KMwoEBgACBBIEVAJaAxolIERlbGV0ZXMgYSBzaW5n
bGUgRG5zVGhyZWF0RGV0ZWN0b3IuCgoMCgUGAAIEARIDVAYdCgwKBQYAAgQCEgNUHjwKDAoF
BgACBAMSA1UPJAoNCgUGAAIEBBIEVgRYBgoRCgkGAAIEBLDKvCISBFYEWAYKDAoFBgACBAQS
A1kEMgoPCggGAAIEBJsIABIDWQQyCpcCCgIEABIFYQCQAQEaiQIgQSBETlMgdGhyZWF0IGRl
dGVjdG9yIHNlbmRzIEROUyBxdWVyeSBsb2dzIHRvIGEgX3Byb3ZpZGVyXyB0aGF0IHRoZW4K
IGFuYWx5emVzIHRoZSBsb2dzIHRvIGlkZW50aWZ5IHRocmVhdCBldmVudHMgaW4gdGhlIERO
UyBxdWVyaWVzLgogQnkgZGVmYXVsdCwgYWxsIFZQQyBuZXR3b3JrcyBpbiB5b3VyIHByb2pl
Y3RzIGFyZSBpbmNsdWRlZC4gWW91IGNhbiBleGNsdWRlCiBzcGVjaWZpYyBuZXR3b3JrcyBi
eSBzdXBwbHlpbmcgYGV4Y2x1ZGVkX25ldHdvcmtzYC4KCgoKAwQAARIDYQgZCgsKAwQABxIE
YgJnBAoNCgUEAAedCBIEYgJnBApCCgQEAAQAEgRqAnADGjQgTmFtZSBvZiB0aGUgcHJvdmlk
ZXIgdXNlZCBmb3IgRE5TIHRocmVhdCBhbmFseXNpcy4KCgwKBQQABAABEgNqBw8KKQoGBAAE
AAIAEgNsBB0aGiBBbiB1bnNwZWNpZmllZCBwcm92aWRlci4KCg4KBwQABAACAAESA2wEGAoO
CgcEAAQAAgACEgNsGxwKOwoGBAAEAAIBEgNvBBEaLCBUaGUgSW5mb2Jsb3ggRE5TIHRocmVh
dCBkZXRlY3RvciBwcm92aWRlci4KCg4KBwQABAACAQESA28EDAoOCgcEAAQAAgECEgNvDxAK
TgoEBAACABIEcwJ2BBpAIEltbXV0YWJsZS4gSWRlbnRpZmllci4gTmFtZSBvZiB0aGUgRG5z
VGhyZWF0RGV0ZWN0b3IgcmVzb3VyY2UuCgoMCgUEAAIABRIDcwIICgwKBQQAAgABEgNzCQ0K
DAoFBAACAAMSA3MQEQoNCgUEAAIACBIEcxJ2AwoPCggEAAIACJwIABIDdAQsCg8KCAQAAgAI
nAgBEgN1BCsKLwoEBAACARIEeQJ6MhohIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZSBzdGFt
cC4KCgwKBQQAAgEGEgN5AhsKDAoFBAACAQESA3kcJwoMCgUEAAIBAxIDeSorCgwKBQQAAgEI
EgN6BjEKDwoIBAACAQicCAASA3oHMAovCgQEAAICEgR9An4yGiEgT3V0cHV0IG9ubHkuIFVw
ZGF0ZSB0aW1lIHN0YW1wLgoKDAoFBAACAgYSA30CGwoMCgUEAAICARIDfRwnCgwKBQQAAgID
EgN9KisKDAoFBAACAggSA34GMQoPCggEAAICCJwIABIDfgcwCmcKBAQAAgMSBIIBAkoaWSBP
cHRpb25hbC4gQW55IGxhYmVscyBhc3NvY2lhdGVkIHdpdGggdGhlIERuc1RocmVhdERldGVj
dG9yLCBsaXN0ZWQgYXMga2V5CiB2YWx1ZSBwYWlycy4KCg0KBQQAAgMGEgSCAQIVCg0KBQQA
AgMBEgSCARYcCg0KBQQAAgMDEgSCAR8gCg0KBQQAAgMIEgSCASFJChAKCAQAAgMInAgAEgSC
ASJICrABCgQEAAIEEgaJAQKMAQQanwEgT3B0aW9uYWwuIEEgbGlzdCBvZiBuZXR3b3JrIHJl
c291cmNlIG5hbWVzIHdoaWNoIGFyZW4ndCBtb25pdG9yZWQgYnkgdGhpcwogRG5zVGhyZWF0
RGV0ZWN0b3IuCgogRXhhbXBsZToKIGBwcm9qZWN0cy9QUk9KRUNUX0lEL2dsb2JhbC9uZXR3
b3Jrcy9ORVRXT1JLX05BTUVgLgoKDQoFBAACBAQSBIkBAgoKDQoFBAACBAUSBIkBCxEKDQoF
BAACBAESBIkBEiMKDQoFBAACBAMSBIkBJicKDwoFBAACBAgSBokBKIwBAwoQCggEAAIECJwI
ABIEigEEKgoPCgcEAAIECJ8IEgSLAQRQCkQKBAQAAgUSBI8BAkEaNiBSZXF1aXJlZC4gVGhl
IHByb3ZpZGVyIHVzZWQgZm9yIEROUyB0aHJlYXQgYW5hbHlzaXMuCgoNCgUEAAIFBhIEjwEC
CgoNCgUEAAIFARIEjwELEwoNCgUEAAIFAxIEjwEWFwoNCgUEAAIFCBIEjwEYQAoQCggEAAIF
CJwIABIEjwEZPwpXCgIEARIGkwEApAEBGkkgVGhlIG1lc3NhZ2UgZm9yIHJlcXVlc3Rpbmcg
YSBsaXN0IG9mIERuc1RocmVhdERldGVjdG9ycyBpbiB0aGUgcHJvamVjdC4KCgsKAwQBARIE
kwEIJQpRCgQEAQIAEgaVAQKaAQQaQSBSZXF1aXJlZC4gVGhlIHBhcmVudCB2YWx1ZSBmb3Ig
YExpc3REbnNUaHJlYXREZXRlY3RvcnNSZXF1ZXN0YC4KCg0KBQQBAgAFEgSVAQIICg0KBQQB
AgABEgSVAQkPCg0KBQQBAgADEgSVARITCg8KBQQBAgAIEgaVARSaAQMKEAoIBAECAAicCAAS
BJYBBCoKEQoHBAECAAifCBIGlwEEmQEFCp8BCgQEAQIBEgSeAQI/GpABIE9wdGlvbmFsLiBU
aGUgcmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gVGhlIHNlcnZlciBtYXkgcmV0dXJuIGZld2VyIGl0
ZW1zIHRoYW4KIHJlcXVlc3RlZC4gSWYgdW5zcGVjaWZpZWQsIHRoZSBzZXJ2ZXIgcGlja3Mg
YW4gYXBwcm9wcmlhdGUgZGVmYXVsdC4KCg0KBQQBAgEFEgSeAQIHCg0KBQQBAgEBEgSeAQgR
Cg0KBQQBAgEDEgSeARQVCg0KBQQBAgEIEgSeARY+ChAKCAQBAgEInAgAEgSeARc9CpYBCgQE
AQICEgSjAQJBGocBIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4gcmVjZWl2ZWQgZnJvbSBhIHBy
ZXZpb3VzCiBgTGlzdERuc1RocmVhdERldGVjdG9yc1JlcXVlc3RgIGNhbGwuIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQBAgIFEgSjAQII
Cg0KBQQBAgIBEgSjAQkTCg0KBQQBAgIDEgSjARYXCg0KBQQBAgIIEgSjARhAChAKCAQBAgII
nAgAEgSjARk/ClAKAgQCEganAQCxAQEaQiBUaGUgcmVzcG9uc2UgbWVzc2FnZSB0byByZXF1
ZXN0aW5nIGEgbGlzdCBvZiBEbnNUaHJlYXREZXRlY3RvcnMuCgoLCgMEAgESBKcBCCYKOAoE
BAICABIEqQECNhoqIFRoZSBsaXN0IG9mIERuc1RocmVhdERldGVjdG9yIHJlc291cmNlcy4K
Cg0KBQQCAgAEEgSpAQIKCg0KBQQCAgAGEgSpAQscCg0KBQQCAgABEgSpAR0xCg0KBQQCAgAD
EgSpATQ1ClYKBAQCAgESBKwBAh0aSCBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBg
cGFnZV90b2tlbmAsIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgoNCgUEAgIBBRIErAEC
CAoNCgUEAgIBARIErAEJGAoNCgUEAgIBAxIErAEbHApMCgQEAgICEgavAQKwATUaPCBVbm9y
ZGVyZWQgbGlzdC4gVW5yZWFjaGFibGUgYERuc1RocmVhdERldGVjdG9yYCByZXNvdXJjZXMu
CgoNCgUEAgICBBIErwECCgoNCgUEAgICBRIErwELEQoNCgUEAgICARIErwESHQoNCgUEAgIC
AxIErwEgIQoNCgUEAgICCBIEsAEGNAoQCggEAgICCJwIABIEsAEHMwo8CgIEAxIGtAEAvAEB
Gi4gVGhlIG1lc3NhZ2Ugc2VudCB0byBnZXQgYSBEbnNUaHJlYXREZXRlY3Rvci4KCgsKAwQD
ARIEtAEIIwpDCgQEAwIAEga2AQK7AQQaMyBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgRG5zVGhy
ZWF0RGV0ZWN0b3IgcmVzb3VyY2UuCgoNCgUEAwIABRIEtgECCAoNCgUEAwIAARIEtgEJDQoN
CgUEAwIAAxIEtgEQEQoPCgUEAwIACBIGtgESuwEDChAKCAQDAgAInAgAEgS3AQQqChEKBwQD
AgAInwgSBrgBBLoBBQo6CgIEBBIGvwEAzwEBGiwgVGhlIG1lc3NhZ2UgdG8gY3JlYXRlIGEg
RG5zVGhyZWF0RGV0ZWN0b3IuCgoLCgMEBAESBL8BCCYKVwoEBAQCABIGwQECxgEEGkcgUmVx
dWlyZWQuIFRoZSB2YWx1ZSBmb3IgdGhlIHBhcmVudCBvZiB0aGUgRG5zVGhyZWF0RGV0ZWN0
b3IgcmVzb3VyY2UuCgoNCgUEBAIABRIEwQECCAoNCgUEBAIAARIEwQEJDwoNCgUEBAIAAxIE
wQESEwoPCgUEBAIACBIGwQEUxgEDChAKCAQEAgAInAgAEgTCAQQqChEKBwQEAgAInwgSBsMB
BMUBBQqSAQoEBAQCARIEygECTRqDASBPcHRpb25hbC4gVGhlIElEIG9mIHRoZSByZXF1ZXN0
aW5nIERuc1RocmVhdERldGVjdG9yIG9iamVjdC4KIElmIHRoaXMgZmllbGQgaXMgbm90IHN1
cHBsaWVkLCB0aGUgc2VydmljZSBnZW5lcmF0ZXMgYW4gaWRlbnRpZmllci4KCg0KBQQEAgEF
EgTKAQIICg0KBQQEAgEBEgTKAQkfCg0KBQQEAgEDEgTKASIjCg0KBQQEAgEIEgTKASRMChAK
CAQEAgEInAgAEgTKASVLCkcKBAQEAgISBs0BAs4BLxo3IFJlcXVpcmVkLiBUaGUgYERuc1Ro
cmVhdERldGVjdG9yYCByZXNvdXJjZSB0byBjcmVhdGUuCgoNCgUEBAICBhIEzQECEwoNCgUE
BAICARIEzQEUJwoNCgUEBAICAxIEzQEqKwoNCgUEBAICCBIEzgEGLgoQCggEBAICCJwIABIE
zgEHLQo9CgIEBRIG0gEA3gEBGi8gVGhlIG1lc3NhZ2UgZm9yIHVwZGF0aW5nIGEgRG5zVGhy
ZWF0RGV0ZWN0b3IuCgoLCgMEBQESBNIBCCYK9gIKBAQFAgASBtgBAtkBLxrlAiBPcHRpb25h
bC4gVGhlIGZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUg
b3ZlcndyaXR0ZW4gaW4KIHRoZSBEbnNUaHJlYXREZXRlY3RvciByZXNvdXJjZSBieSB0aGUg
dXBkYXRlLiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUKIHVwZGF0ZV9tYXNrIGFyZSBy
ZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdCB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxk
CiB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUgbWFz
ayBpcyBub3QgcHJvdmlkZWQgdGhlbgogYWxsIGZpZWxkcyBwcmVzZW50IGluIHRoZSByZXF1
ZXN0IHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEBQIABhIE2AECGwoNCgUEBQIAARIE2AEc
JwoNCgUEBQIAAxIE2AEqKwoNCgUEBQIACBIE2QEGLgoQCggEBQIACJwIABIE2QEHLQpJCgQE
BQIBEgbcAQLdAS8aOSBSZXF1aXJlZC4gVGhlIERuc1RocmVhdERldGVjdG9yIHJlc291cmNl
IGJlaW5nIHVwZGF0ZWQuCgoNCgUEBQIBBhIE3AECEwoNCgUEBQIBARIE3AEUJwoNCgUEBQIB
AxIE3AEqKwoNCgUEBQIBCBIE3QEGLgoQCggEBQIBCJwIABIE3QEHLQo9CgIEBhIG4QEA6QEB
Gi8gVGhlIG1lc3NhZ2UgZm9yIGRlbGV0aW5nIGEgRG5zVGhyZWF0RGV0ZWN0b3IuCgoLCgME
BgESBOEBCCYKQwoEBAYCABIG4wEC6AEEGjMgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIERuc1Ro
cmVhdERldGVjdG9yIHJlc291cmNlLgoKDQoFBAYCAAUSBOMBAggKDQoFBAYCAAESBOMBCQ0K
DQoFBAYCAAMSBOMBEBEKDwoFBAYCAAgSBuMBEugBAwoQCggEBgIACJwIABIE5AEEKgoRCgcE
BgIACJ8IEgblAQTnAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector ===
    # Fields for DnsThreatDetector
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1.DnsThreatDetector.LabelsEntry)
    # Field: excluded_networks Type: 9 ()
    # Field: provider Type: 14 (.google.cloud.networksecurity.v1.DnsThreatDetector.Provider)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<labels>

Type: Message (.google.cloud.networksecurity.v1.DnsThreatDetector.LabelsEntry)

=item * B<excluded_networks>

Type: String

=item * B<provider>

Type: Enum (.google.cloud.networksecurity.v1.DnsThreatDetector.Provider)

=back

=cut

# Enum: DnsThreatDetector::Provider
our $DnsThreatDetector_PROVIDER_UNSPECIFIED = 0;
our $DnsThreatDetector_INFOBLOX = 1;

=pod

=head2 Enum: DnsThreatDetector::Provider

Values:

=over 4

=item * C<PROVIDER_UNSPECIFIED> => 0

=item * C<INFOBLOX> => 1

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest ===
    # Fields for ListDnsThreatDetectorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse ===
    # Fields for ListDnsThreatDetectorsResponse
    # Field: dns_threat_detectors Type: 11 (.google.cloud.networksecurity.v1.DnsThreatDetector)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse->new(
        dns_threat_detectors => $value,
    );

=head1 FIELDS

=over 4

=item * B<dns_threat_detectors>

Type: Message (.google.cloud.networksecurity.v1.DnsThreatDetector)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest ===
    # Fields for GetDnsThreatDetectorRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest ===
    # Fields for CreateDnsThreatDetectorRequest
    # Field: parent Type: 9 ()
    # Field: dns_threat_detector_id Type: 9 ()
    # Field: dns_threat_detector Type: 11 (.google.cloud.networksecurity.v1.DnsThreatDetector)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<dns_threat_detector_id>

Type: String

=item * B<dns_threat_detector>

Type: Message (.google.cloud.networksecurity.v1.DnsThreatDetector)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest ===
    # Fields for UpdateDnsThreatDetectorRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: dns_threat_detector Type: 11 (.google.cloud.networksecurity.v1.DnsThreatDetector)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<dns_threat_detector>

Type: Message (.google.cloud.networksecurity.v1.DnsThreatDetector)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest ===
    # Fields for DeleteDnsThreatDetectorRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetectorServiceClient ===
package Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetectorServiceClient;

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetectorServiceClient - Client stub representing the remote DnsThreatDetectorService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<networksecurity.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networksecurity.googleapis.com:443' );

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

sub list_dns_threat_detectors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1.DnsThreatDetectorService',
        method         => 'ListDnsThreatDetectors',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse',
    });
}

sub get_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1::DnsThreatDetector::GetDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1.DnsThreatDetectorService',
        method         => 'GetDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector',
    });
}

sub create_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1::DnsThreatDetector::CreateDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1.DnsThreatDetectorService',
        method         => 'CreateDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector',
    });
}

sub update_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1::DnsThreatDetector::UpdateDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1.DnsThreatDetectorService',
        method         => 'UpdateDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::DnsThreatDetector',
    });
}

sub delete_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1::DnsThreatDetector::DeleteDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1.DnsThreatDetectorService',
        method         => 'DeleteDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::DnsThreatDetector - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
