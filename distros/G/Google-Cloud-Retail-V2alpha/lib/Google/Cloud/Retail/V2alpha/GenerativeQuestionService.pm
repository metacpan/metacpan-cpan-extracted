package Google::Cloud::Retail::V2alpha::GenerativeQuestionService;

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
    eval { require Google::Cloud::Retail::V2alpha::GenerativeQuestion };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvZ2VuZXJhdGl2ZV9xdWVzdGlvbl9zZXJ2
aWNlLnByb3RvEhtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2dsZS9hcGkvYW5u
b3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjVnb29nbGUv
Y2xvdWQvcmV0YWlsL3YyYWxwaGEvZ2VuZXJhdGl2ZV9xdWVzdGlvbi5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8ihQIKLVVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlv
bnNGZWF0dXJlQ29uZmlnUmVxdWVzdBKRAQojZ2VuZXJhdGl2ZV9xdWVzdGlvbnNfZmVhdHVy
ZV9jb25maWcYAiABKAsyPS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuR2VuZXJhdGl2
ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWdCA+BBAlIgZ2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1
cmVDb25maWcSQAoLdXBkYXRlX21hc2sYBCABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRN
YXNrQgPgQQFSCnVwZGF0ZU1hc2sibQoqR2V0R2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVD
b25maWdSZXF1ZXN0Ej8KB2NhdGFsb2cYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFw
aXMuY29tL0NhdGFsb2dSB2NhdGFsb2ciZQokTGlzdEdlbmVyYXRpdmVRdWVzdGlvbkNvbmZp
Z3NSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5j
b20vQ2F0YWxvZ1IGcGFyZW50Ip4BCiVMaXN0R2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnc1Jl
c3BvbnNlEnUKG2dlbmVyYXRpdmVfcXVlc3Rpb25fY29uZmlncxgBIAMoCzI1Lmdvb2dsZS5j
bG91ZC5yZXRhaWwudjJhbHBoYS5HZW5lcmF0aXZlUXVlc3Rpb25Db25maWdSGWdlbmVyYXRp
dmVRdWVzdGlvbkNvbmZpZ3Mi4wEKJVVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ1Jl
cXVlc3QSeAoaZ2VuZXJhdGl2ZV9xdWVzdGlvbl9jb25maWcYAyABKAsyNS5nb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnQgPgQQJSGGdlbmVy
YXRpdmVRdWVzdGlvbkNvbmZpZxJACgt1cGRhdGVfbWFzaxgEIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayLRAQorQmF0Y2hVcGRhdGVHZW5lcmF0
aXZlUXVlc3Rpb25Db25maWdzUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAfpBHwodcmV0
YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJjCghyZXF1ZXN0cxgCIAMoCzJC
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5VcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25D
b25maWdSZXF1ZXN0QgPgQQJSCHJlcXVlc3RzIqoBCixCYXRjaFVwZGF0ZUdlbmVyYXRpdmVR
dWVzdGlvbkNvbmZpZ3NSZXNwb25zZRJ6ChtnZW5lcmF0aXZlX3F1ZXN0aW9uX2NvbmZpZ3MY
ASADKAsyNS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuR2VuZXJhdGl2ZVF1ZXN0aW9u
Q29uZmlnQgPgQQFSGWdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ3Myhg0KGUdlbmVyYXRpdmVR
dWVzdGlvblNlcnZpY2USiAMKJlVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29u
ZmlnEkouZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlVwZGF0ZUdlbmVyYXRpdmVRdWVz
dGlvbnNGZWF0dXJlQ29uZmlnUmVxdWVzdBo9Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBo
YS5HZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZyLSAYLT5JMCmQEyci92MmFscGhh
L3tnZW5lcmF0aXZlX3F1ZXN0aW9uc19mZWF0dXJlX2NvbmZpZy5jYXRhbG9nPXByb2plY3Rz
LyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0vZ2VuZXJhdGl2ZVF1ZXN0aW9uRmVhdHVyZToj
Z2VuZXJhdGl2ZV9xdWVzdGlvbnNfZmVhdHVyZV9jb25maWfaQS9nZW5lcmF0aXZlX3F1ZXN0
aW9uc19mZWF0dXJlX2NvbmZpZyx1cGRhdGVfbWFzaxKPAgojR2V0R2VuZXJhdGl2ZVF1ZXN0
aW9uc0ZlYXR1cmVDb25maWcSRy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuR2V0R2Vu
ZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWdSZXF1ZXN0Gj0uZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLkdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnImCC0+STAlAS
Ti92MmFscGhhL3tjYXRhbG9nPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0v
Z2VuZXJhdGl2ZVF1ZXN0aW9uRmVhdHVyZdpBB2NhdGFsb2cSgAIKHUxpc3RHZW5lcmF0aXZl
UXVlc3Rpb25Db25maWdzEkEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxpc3RHZW5l
cmF0aXZlUXVlc3Rpb25Db25maWdzUmVxdWVzdBpCLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5MaXN0R2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnc1Jlc3BvbnNlIliC0+STAkkSRy92
MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9nZW5l
cmF0aXZlUXVlc3Rpb25z2kEGcGFyZW50Es4CCh5VcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25D
b25maWcSQi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVXBkYXRlR2VuZXJhdGl2ZVF1
ZXN0aW9uQ29uZmlnUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5HZW5l
cmF0aXZlUXVlc3Rpb25Db25maWcisAGC0+STAoABMmIvdjJhbHBoYS97Z2VuZXJhdGl2ZV9x
dWVzdGlvbl9jb25maWcuY2F0YWxvZz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dz
Lyp9L2dlbmVyYXRpdmVRdWVzdGlvbjoaZ2VuZXJhdGl2ZV9xdWVzdGlvbl9jb25maWfaQSZn
ZW5lcmF0aXZlX3F1ZXN0aW9uX2NvbmZpZyx1cGRhdGVfbWFzaxKsAgokQmF0Y2hVcGRhdGVH
ZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzEkguZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhh
LkJhdGNoVXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnc1JlcXVlc3QaSS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGEuQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25m
aWdzUmVzcG9uc2Uib4LT5JMCVyJSL3YyYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NhdGFsb2dzLyp9L2dlbmVyYXRpdmVRdWVzdGlvbjpiYXRjaFVwZGF0ZToBKtpB
D3BhcmVudCxyZXF1ZXN0cxpJykEVcmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULiAQofY29tLmdvb2dsZS5j
bG91ZC5yZXRhaWwudjJhbHBoYUIeR2VuZXJhdGl2ZVF1ZXN0aW9uU2VydmljZVByb3RvUAFa
N2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxwaGEvcmV0YWlscGI7cmV0YWls
cGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQWxwaGHKAhtHb29nbGVcQ2xv
dWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYWxwaGFK4SMK
BxIFDgCrAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQK
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA/
CgkKAgMFEgMXACoKCAoBCBIDGQA4CgkKAgglEgMZADgKCAoBCBIDGgBOCgkKAggLEgMaAE4K
CAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA/CgkKAggIEgMcAD8KCAoBCBIDHQA4CgkK
AggBEgMdADgKCAoBCBIDHgAkCgkKAggkEgMeACQKCAoBCBIDHwA4CgkKAggpEgMfADgKCAoB
CBIDIAA3CgkKAggtEgMgADcKTQoCBgASBCMAXgEaQSBTZXJ2aWNlIGZvciBtYW5hZ2luZyBM
TE0gZ2VuZXJhdGVkIHF1ZXN0aW9ucyBpbiBzZWFyY2ggc2VydmluZy4KCgoKAwYAARIDIwgh
CgoKAwYAAxIDJAI9CgwKBQYAA5kIEgMkAj0KCwoDBgADEgQlAiY3Cg0KBQYAA5oIEgQlAiY3
CmkKBAYAAgASBCoCMwMaWyBNYW5hZ2VzIG92ZXJhbCBnZW5lcmF0aXZlIHF1ZXN0aW9uIGZl
YXR1cmUgc3RhdGUgLS0gZW5hYmxlcyB0b2dnbGluZwogZmVhdHVyZSBvbiBhbmQgb2ZmLgoK
DAoFBgACAAESAyoGLAoMCgUGAAIAAhIDKwYzCgwKBQYAAgADEgMsDy8KDQoFBgACAAQSBC0E
MAYKEQoJBgACAASwyrwiEgQtBDAGCg0KBQYAAgAEEgQxBDI6ChAKCAYAAgAEmwgAEgQxBDI6
CmkKBAYAAgESBDcCPgMaWyBNYW5hZ2VzIG92ZXJhbCBnZW5lcmF0aXZlIHF1ZXN0aW9uIGZl
YXR1cmUgc3RhdGUgLS0gZW5hYmxlcyB0b2dnbGluZwogZmVhdHVyZSBvbiBhbmQgb2ZmLgoK
DAoFBgACAQESAzcGKQoMCgUGAAIBAhIDOAYwCgwKBQYAAgEDEgM5Dy8KDQoFBgACAQQSBDoE
PAYKEQoJBgACAQSwyrwiEgQ6BDwGCgwKBQYAAgEEEgM9BDUKDwoIBgACAQSbCAASAz0ENQo6
CgQGAAICEgRBAkcDGiwgUmV0dXJucyBhbGwgcXVlc3Rpb25zIGZvciBhIGdpdmVuIGNhdGFs
b2cuCgoMCgUGAAICARIDQQYjCgwKBQYAAgICEgNBJEgKDAoFBgACAgMSA0IPNAoNCgUGAAIC
BBIEQwRFBgoRCgkGAAICBLDKvCISBEMERQYKDAoFBgACAgQSA0YENAoPCggGAAICBJsIABID
RgQ0CjoKBAYAAgMSBEoCUgMaLCBBbGxvd3MgbWFuYWdlbWVudCBvZiBpbmRpdmlkdWFsIHF1
ZXN0aW9ucy4KCgwKBQYAAgMBEgNKBiQKDAoFBgACAwISA0olSgoMCgUGAAIDAxIDSw8nCg0K
BQYAAgMEEgRMBE8GChEKCQYAAgMEsMq8IhIETARPBgoNCgUGAAIDBBIEUARRMQoQCggGAAID
BJsIABIEUARRMQo4CgQGAAIEEgRVAl0DGiogQWxsb3dzIG1hbmFnZW1lbnQgb2YgbXVsdGlw
bGUgcXVlc3Rpb25zLgoKDAoFBgACBAESA1UGKgoMCgUGAAIEAhIDVgYxCgwKBQYAAgQDEgNX
DzsKDQoFBgACBAQSBFgEWwYKEQoJBgACBASwyrwiEgRYBFsGCgwKBQYAAgQEEgNcBD0KDwoI
BgACBASbCAASA1wEPQpICgIEABIEYQBrARo8IFJlcXVlc3QgZm9yIFVwZGF0ZUdlbmVyYXRp
dmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnIG1ldGhvZC4KCgoKAwQAARIDYQg1CkcKBAQAAgAS
BGMCZC8aOSBSZXF1aXJlZC4gVGhlIGNvbmZpZ3VyYXRpb24gbWFuYWdpbmcgdGhlIGZlYXR1
cmUgc3RhdGUuCgoMCgUEAAIABhIDYwIiCgwKBQQAAgABEgNjI0YKDAoFBAACAAMSA2NJSgoM
CgUEAAIACBIDZAYuCg8KCAQAAgAInAgAEgNkBy0K5gEKBAQAAgESBGkCai8a1wEgT3B0aW9u
YWwuIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHByb3ZpZGVkCiBbR2VuZXJhdGl2
ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5H
ZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZ10KIHRvIHVwZGF0ZS4gSWYgbm90IHNl
dCBvciBlbXB0eSwgYWxsIHN1cHBvcnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoMCgUEAAIB
BhIDaQIbCgwKBQQAAgEBEgNpHCcKDAoFBAACAQMSA2kqKwoMCgUEAAIBCBIDagYuCg8KCAQA
AgEInAgAEgNqBy0KRQoCBAESBG4AdQEaOSBSZXF1ZXN0IGZvciBHZXRHZW5lcmF0aXZlUXVl
c3Rpb25zRmVhdHVyZUNvbmZpZyBtZXRob2QuCgoKCgMEAQESA24IMgqCAQoEBAECABIEcQJ0
BBp0IFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXJlbnQgY2F0YWxvZy4KIEZv
cm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NhdGFsb2dz
L3tjYXRhbG9nfQoKDAoFBAECAAUSA3ECCAoMCgUEAQIAARIDcQkQCgwKBQQBAgADEgNxExQK
DQoFBAECAAgSBHEVdAMKDwoIBAECAAicCAASA3IEKgoOCgcEAQIACJ8IEgNzBE8KLwoCBAIS
BHgAfwEaIyBSZXF1ZXN0IGZvciBMaXN0UXVlc3Rpb25zIG1ldGhvZC4KCgoKAwQCARIDeAgs
CoIBCgQEAgIAEgR7An4EGnQgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHBhcmVu
dCBjYXRhbG9nLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vY2F0YWxvZ3Mve2NhdGFsb2d9CgoMCgUEAgIABRIDewIICgwKBQQCAgABEgN7CQ8K
DAoFBAICAAMSA3sSEwoNCgUEAgIACBIEexR+AwoPCggEAgIACJwIABIDfAQqCg4KBwQCAgAI
nwgSA30ETwoyCgIEAxIGggEAhQEBGiQgUmVzcG9uc2UgZm9yIExpc3RRdWVzdGlvbnMgbWV0
aG9kLgoKCwoDBAMBEgSCAQgtCjYKBAQDAgASBIQBAkQaKCBBbGwgdGhlIHF1ZXN0aW9ucyBm
b3IgYSBnaXZlbiBjYXRhbG9nLgoKDQoFBAMCAAQSBIQBAgoKDQoFBAMCAAYSBIQBCyMKDQoF
BAMCAAESBIQBJD8KDQoFBAMCAAMSBIQBQkMKQgoCBAQSBogBAJYBARo0IFJlcXVlc3QgZm9y
IFVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZyBtZXRob2QuCgoLCgMEBAESBIgBCC0K
MwoEBAQCABIGigECiwEvGiMgUmVxdWlyZWQuIFRoZSBxdWVzdGlvbiB0byB1cGRhdGUuCgoN
CgUEBAIABhIEigECGgoNCgUEBAIAARIEigEbNQoNCgUEBAIAAxIEigE4OQoNCgUEBAIACBIE
iwEGLgoQCggEBAIACJwIABIEiwEHLQrkAgoEBAQCARIGlAEClQEvGtMCIE9wdGlvbmFsLiBJ
bmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0dlbmVyYXRpdmVRdWVz
dGlvbkNvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkdlbmVyYXRpdmVRdWVz
dGlvbkNvbmZpZ10KIHRvIHVwZGF0ZS4gVGhlIGZvbGxvd2luZyBhcmUgTk9UIHN1cHBvcnRl
ZDoKCiAqIFtHZW5lcmF0aXZlUXVlc3Rpb25Db25maWcuZnJlcXVlbmN5XVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnLmZyZXF1ZW5jeV0K
CiBJZiBub3Qgc2V0IG9yIGVtcHR5LCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBhcmUgdXBkYXRl
ZC4KCg0KBQQEAgEGEgSUAQIbCg0KBQQEAgEBEgSUARwnCg0KBQQEAgEDEgSUASorCg0KBQQE
AgEIEgSVAQYuChAKCAQEAgEInAgAEgSVAQctCkcKAgQFEgaZAQCkAQEaOSBSZXF1ZXN0IGZv
ciBCYXRjaFVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZyBtZXRob2QuCgoLCgMEBQES
BJkBCDMKhAEKBAQFAgASBpwBAp8BBBp0IE9wdGlvbmFsLiBSZXNvdXJjZSBuYW1lIG9mIHRo
ZSBwYXJlbnQgY2F0YWxvZy4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfQoKDQoFBAUCAAUSBJwBAggKDQoFBAUC
AAESBJwBCQ8KDQoFBAUCAAMSBJwBEhMKDwoFBAUCAAgSBpwBFJ8BAwoQCggEBQIACJwIABIE
nQEEKgoPCgcEBQIACJ8IEgSeAQRPCjkKBAQFAgESBqIBAqMBLxopIFJlcXVpcmVkLiBUaGUg
dXBkYXRlcyBxdWVzdGlvbiBjb25maWdzLgoKDQoFBAUCAQQSBKIBAgoKDQoFBAUCAQYSBKIB
CzAKDQoFBAUCAQESBKIBMTkKDQoFBAUCAQMSBKIBPD0KDQoFBAUCAQgSBKMBBi4KEAoIBAUC
AQicCAASBKMBBy0KTgoCBAYSBqcBAKsBARpAIEFnZ3JlZ2F0ZWQgcmVzcG9uc2UgZm9yIFVw
ZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZyBtZXRob2QuCgoLCgMEBgESBKcBCDQKOQoE
BAYCABIGqQECqgEvGikgT3B0aW9uYWwuIFRoZSB1cGRhdGVzIHF1ZXN0aW9uIGNvbmZpZ3Mu
CgoNCgUEBgIABBIEqQECCgoNCgUEBgIABhIEqQELIwoNCgUEBgIAARIEqQEkPwoNCgUEBgIA
AxIEqQFCQwoNCgUEBgIACBIEqgEGLgoQCggEBgIACJwIABIEqgEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest ===
    # Fields for UpdateGenerativeQuestionsFeatureConfigRequest
    # Field: generative_questions_feature_config Type: 11 (.google.cloud.retail.v2alpha.GenerativeQuestionsFeatureConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest ===
    # Fields for GetGenerativeQuestionsFeatureConfigRequest
    # Field: catalog Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest ===
    # Fields for ListGenerativeQuestionConfigsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse ===
    # Fields for ListGenerativeQuestionConfigsResponse
    # Field: generative_question_configs Type: 11 (.google.cloud.retail.v2alpha.GenerativeQuestionConfig)

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest ===
    # Fields for UpdateGenerativeQuestionConfigRequest
    # Field: generative_question_config Type: 11 (.google.cloud.retail.v2alpha.GenerativeQuestionConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest ===
    # Fields for BatchUpdateGenerativeQuestionConfigsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.retail.v2alpha.UpdateGenerativeQuestionConfigRequest)

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse ===
    # Fields for BatchUpdateGenerativeQuestionConfigsResponse
    # Field: generative_question_configs Type: 11 (.google.cloud.retail.v2alpha.GenerativeQuestionConfig)

# === Service Client: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::GenerativeQuestionServiceClient ===
package Google::Cloud::Retail::V2alpha::GenerativeQuestionService::GenerativeQuestionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::GenerativeQuestionService::GenerativeQuestionServiceClient

Client stub representing the remote C<GenerativeQuestionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub update_generative_questions_feature_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionsFeatureConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig',
    });
}

sub get_generative_questions_feature_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.GenerativeQuestionService',
        method         => 'GetGenerativeQuestionsFeatureConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig',
    });
}

sub list_generative_question_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.GenerativeQuestionService',
        method         => 'ListGenerativeQuestionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse',
    });
}

sub update_generative_question_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig',
    });
}

sub batch_update_generative_question_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.GenerativeQuestionService',
        method         => 'BatchUpdateGenerativeQuestionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::GenerativeQuestionService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/generative_question_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::GenerativeQuestionService;

    my $msg = Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->new({
        generative_questions_feature_config => $generative_questions_feature_config,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->generative_questions_feature_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/generative_question_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest

Request for UpdateGenerativeQuestionsFeatureConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_questions_feature_config() >> / C<< $msg->generative_questions_feature_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig>)

Required. The configuration managing the feature state.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[GenerativeQuestionsFeatureConfig][google.cloud.retail.v2alpha.GenerativeQuestionsFeatureConfig]
to update. If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest

Request for GetGenerativeQuestionsFeatureConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=back

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest

Request for ListQuestions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=back

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse

Response for ListQuestions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_configs() >> / C<< $msg->generative_question_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig>)

All the questions for a given catalog.

=back

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest

Request for UpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_config() >> / C<< $msg->generative_question_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig>)

Required. The question to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[GenerativeQuestionConfig][google.cloud.retail.v2alpha.GenerativeQuestionConfig]
to update. The following are NOT supported:

* [GenerativeQuestionConfig.frequency][google.cloud.retail.v2alpha.GenerativeQuestionConfig.frequency]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest

Request for BatchUpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Optional. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest>)

Required. The updates question configs.

=back

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse

Aggregated response for UpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_configs() >> / C<< $msg->generative_question_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig>)

Optional. The updates question configs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::GenerativeQuestionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
