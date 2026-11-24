package Google::Cloud::Retail::V2::GenerativeQuestionService;

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
    eval { require Google::Cloud::Retail::V2::GenerativeQuestion };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2dlbmVyYXRpdmVfcXVlc3Rpb25fc2VydmljZS5w
cm90bxIWZ29vZ2xlLmNsb3VkLnJldGFpbC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMGdvb2dsZS9jbG91ZC9yZXRh
aWwvdjIvZ2VuZXJhdGl2ZV9xdWVzdGlvbi5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxk
X21hc2sucHJvdG8igAIKLVVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmln
UmVxdWVzdBKMAQojZ2VuZXJhdGl2ZV9xdWVzdGlvbnNfZmVhdHVyZV9jb25maWcYAiABKAsy
OC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29u
ZmlnQgPgQQJSIGdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnEkAKC3VwZGF0ZV9t
YXNrGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNr
Im0KKkdldEdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnUmVxdWVzdBI/CgdjYXRh
bG9nGAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9nUgdjYXRh
bG9nImUKJExpc3RHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzUmVxdWVzdBI9CgZwYXJlbnQY
ASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudCKZ
AQolTGlzdEdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ3NSZXNwb25zZRJwChtnZW5lcmF0aXZl
X3F1ZXN0aW9uX2NvbmZpZ3MYASADKAsyMC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkdlbmVy
YXRpdmVRdWVzdGlvbkNvbmZpZ1IZZ2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlncyLeAQolVXBk
YXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnUmVxdWVzdBJzChpnZW5lcmF0aXZlX3F1ZXN0
aW9uX2NvbmZpZxgDIAEoCzIwLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2VuZXJhdGl2ZVF1
ZXN0aW9uQ29uZmlnQgPgQQJSGGdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZxJACgt1cGRhdGVf
bWFzaxgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFz
ayLMAQorQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzUmVxdWVzdBI9CgZw
YXJlbnQYASABKAlCJeBBAfpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBh
cmVudBJeCghyZXF1ZXN0cxgCIAMoCzI9Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXBkYXRl
R2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnUmVxdWVzdEID4EECUghyZXF1ZXN0cyKlAQosQmF0
Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzUmVzcG9uc2USdQobZ2VuZXJhdGl2
ZV9xdWVzdGlvbl9jb25maWdzGAEgAygLMjAuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5HZW5l
cmF0aXZlUXVlc3Rpb25Db25maWdCA+BBAVIZZ2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnczK6
DAoZR2VuZXJhdGl2ZVF1ZXN0aW9uU2VydmljZRL5AgomVXBkYXRlR2VuZXJhdGl2ZVF1ZXN0
aW9uc0ZlYXR1cmVDb25maWcSRS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlVwZGF0ZUdlbmVy
YXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5yZXRh
aWwudjIuR2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWcizQGC0+STApQBMm0vdjIv
e2dlbmVyYXRpdmVfcXVlc3Rpb25zX2ZlYXR1cmVfY29uZmlnLmNhdGFsb2c9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9nZW5lcmF0aXZlUXVlc3Rpb25GZWF0dXJlOiNn
ZW5lcmF0aXZlX3F1ZXN0aW9uc19mZWF0dXJlX2NvbmZpZ9pBL2dlbmVyYXRpdmVfcXVlc3Rp
b25zX2ZlYXR1cmVfY29uZmlnLHVwZGF0ZV9tYXNrEoACCiNHZXRHZW5lcmF0aXZlUXVlc3Rp
b25zRmVhdHVyZUNvbmZpZxJCLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2V0R2VuZXJhdGl2
ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWdSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5HZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZyJbgtPkkwJLEkkvdjIve2NhdGFs
b2c9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9nZW5lcmF0aXZlUXVlc3Rp
b25GZWF0dXJl2kEHY2F0YWxvZxLxAQodTGlzdEdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ3MS
PC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkxpc3RHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdz
UmVxdWVzdBo9Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuTGlzdEdlbmVyYXRpdmVRdWVzdGlv
bkNvbmZpZ3NSZXNwb25zZSJTgtPkkwJEEkIvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NhdGFsb2dzLyp9L2dlbmVyYXRpdmVRdWVzdGlvbnPaQQZwYXJlbnQSvgIKHlVw
ZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZxI9Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjIu
VXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnIqoBgtPkkwJ7Ml0vdjIve2dlbmVy
YXRpdmVfcXVlc3Rpb25fY29uZmlnLmNhdGFsb2c9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
YXRhbG9ncy8qfS9nZW5lcmF0aXZlUXVlc3Rpb246GmdlbmVyYXRpdmVfcXVlc3Rpb25fY29u
Zmln2kEmZ2VuZXJhdGl2ZV9xdWVzdGlvbl9jb25maWcsdXBkYXRlX21hc2sSnQIKJEJhdGNo
VXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlncxJDLmdvb2dsZS5jbG91ZC5yZXRhaWwu
djIuQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzUmVxdWVzdBpELmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjIuQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdz
UmVzcG9uc2UiaoLT5JMCUiJNL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
YXRhbG9ncy8qfS9nZW5lcmF0aXZlUXVlc3Rpb246YmF0Y2hVcGRhdGU6ASraQQ9wYXJlbnQs
cmVxdWVzdHMaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CyQEKGmNvbS5nb29nbGUuY2xvdWQucmV0
YWlsLnYyQh5HZW5lcmF0aXZlUXVlc3Rpb25TZXJ2aWNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xl
LmNvbS9nby9yZXRhaWwvYXBpdjIvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhZHb29n
bGUuQ2xvdWQuUmV0YWlsLlYyygIWR29vZ2xlXENsb3VkXFJldGFpbFxWMuoCGUdvb2dsZTo6
Q2xvdWQ6OlJldGFpbDo6VjJK0iMKBxIFDgCrAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkK
CQoCAwMSAxUAIwoJCgIDBBIDFgA6CgkKAgMFEgMXACoKCAoBCBIDGQAzCgkKAgglEgMZADMK
CAoBCBIDGgBJCgkKAggLEgMaAEkKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA/CgkK
AggIEgMcAD8KCAoBCBIDHQAzCgkKAggBEgMdADMKCAoBCBIDHgAkCgkKAggkEgMeACQKCAoB
CBIDHwAzCgkKAggpEgMfADMKCAoBCBIDIAAyCgkKAggtEgMgADIKTQoCBgASBCMAXgEaQSBT
ZXJ2aWNlIGZvciBtYW5hZ2luZyBMTE0gZ2VuZXJhdGVkIHF1ZXN0aW9ucyBpbiBzZWFyY2gg
c2VydmluZy4KCgoKAwYAARIDIwghCgoKAwYAAxIDJAI9CgwKBQYAA5kIEgMkAj0KCwoDBgAD
EgQlAiY3Cg0KBQYAA5oIEgQlAiY3CmkKBAYAAgASBCoCMwMaWyBNYW5hZ2VzIG92ZXJhbCBn
ZW5lcmF0aXZlIHF1ZXN0aW9uIGZlYXR1cmUgc3RhdGUgLS0gZW5hYmxlcyB0b2dnbGluZwog
ZmVhdHVyZSBvbiBhbmQgb2ZmLgoKDAoFBgACAAESAyoGLAoMCgUGAAIAAhIDKwYzCgwKBQYA
AgADEgMsDy8KDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAGCg0KBQYAAgAEEgQx
BDI6ChAKCAYAAgAEmwgAEgQxBDI6CmkKBAYAAgESBDcCPgMaWyBNYW5hZ2VzIG92ZXJhbCBn
ZW5lcmF0aXZlIHF1ZXN0aW9uIGZlYXR1cmUgc3RhdGUgLS0gZW5hYmxlcyB0b2dnbGluZwog
ZmVhdHVyZSBvbiBhbmQgb2ZmLgoKDAoFBgACAQESAzcGKQoMCgUGAAIBAhIDOAYwCgwKBQYA
AgEDEgM5Dy8KDQoFBgACAQQSBDoEPAYKEQoJBgACAQSwyrwiEgQ6BDwGCgwKBQYAAgEEEgM9
BDUKDwoIBgACAQSbCAASAz0ENQo6CgQGAAICEgRBAkcDGiwgUmV0dXJucyBhbGwgcXVlc3Rp
b25zIGZvciBhIGdpdmVuIGNhdGFsb2cuCgoMCgUGAAICARIDQQYjCgwKBQYAAgICEgNBJEgK
DAoFBgACAgMSA0IPNAoNCgUGAAICBBIEQwRFBgoRCgkGAAICBLDKvCISBEMERQYKDAoFBgAC
AgQSA0YENAoPCggGAAICBJsIABIDRgQ0CjoKBAYAAgMSBEoCUgMaLCBBbGxvd3MgbWFuYWdl
bWVudCBvZiBpbmRpdmlkdWFsIHF1ZXN0aW9ucy4KCgwKBQYAAgMBEgNKBiQKDAoFBgACAwIS
A0olSgoMCgUGAAIDAxIDSw8nCg0KBQYAAgMEEgRMBE8GChEKCQYAAgMEsMq8IhIETARPBgoN
CgUGAAIDBBIEUARRMQoQCggGAAIDBJsIABIEUARRMQo4CgQGAAIEEgRVAl0DGiogQWxsb3dz
IG1hbmFnZW1lbnQgb2YgbXVsdGlwbGUgcXVlc3Rpb25zLgoKDAoFBgACBAESA1UGKgoMCgUG
AAIEAhIDVgYxCgwKBQYAAgQDEgNXDzsKDQoFBgACBAQSBFgEWwYKEQoJBgACBASwyrwiEgRY
BFsGCgwKBQYAAgQEEgNcBD0KDwoIBgACBASbCAASA1wEPQpICgIEABIEYQBrARo8IFJlcXVl
c3QgZm9yIFVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnIG1ldGhvZC4K
CgoKAwQAARIDYQg1CkcKBAQAAgASBGMCZC8aOSBSZXF1aXJlZC4gVGhlIGNvbmZpZ3VyYXRp
b24gbWFuYWdpbmcgdGhlIGZlYXR1cmUgc3RhdGUuCgoMCgUEAAIABhIDYwIiCgwKBQQAAgAB
EgNjI0YKDAoFBAACAAMSA2NJSgoMCgUEAAIACBIDZAYuCg8KCAQAAgAInAgAEgNkBy0K4QEK
BAQAAgESBGkCai8a0gEgT3B0aW9uYWwuIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhl
IHByb3ZpZGVkCiBbR2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWddW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjIuR2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWddCiB0byB1
cGRhdGUuIElmIG5vdCBzZXQgb3IgZW1wdHksIGFsbCBzdXBwb3J0ZWQgZmllbGRzIGFyZSB1
cGRhdGVkLgoKDAoFBAACAQYSA2kCGwoMCgUEAAIBARIDaRwnCgwKBQQAAgEDEgNpKisKDAoF
BAACAQgSA2oGLgoPCggEAAIBCJwIABIDagctCkUKAgQBEgRuAHUBGjkgUmVxdWVzdCBmb3Ig
R2V0R2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWcgbWV0aG9kLgoKCgoDBAEBEgNu
CDIKggEKBAQBAgASBHECdAQadCBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgcGFy
ZW50IGNhdGFsb2cuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jYXRhbG9ncy97Y2F0YWxvZ30KCgwKBQQBAgAFEgNxAggKDAoFBAECAAESA3EJ
EAoMCgUEAQIAAxIDcRMUCg0KBQQBAgAIEgRxFXQDCg8KCAQBAgAInAgAEgNyBCoKDgoHBAEC
AAifCBIDcwRPCi8KAgQCEgR4AH8BGiMgUmVxdWVzdCBmb3IgTGlzdFF1ZXN0aW9ucyBtZXRo
b2QuCgoKCgMEAgESA3gILAqCAQoEBAICABIEewJ+BBp0IFJlcXVpcmVkLiBSZXNvdXJjZSBu
YW1lIG9mIHRoZSBwYXJlbnQgY2F0YWxvZy4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfQoKDAoFBAICAAUSA3sC
CAoMCgUEAgIAARIDewkPCgwKBQQCAgADEgN7EhMKDQoFBAICAAgSBHsUfgMKDwoIBAICAAic
CAASA3wEKgoOCgcEAgIACJ8IEgN9BE8KMgoCBAMSBoIBAIUBARokIFJlc3BvbnNlIGZvciBM
aXN0UXVlc3Rpb25zIG1ldGhvZC4KCgsKAwQDARIEggEILQo2CgQEAwIAEgSEAQJEGiggQWxs
IHRoZSBxdWVzdGlvbnMgZm9yIGEgZ2l2ZW4gY2F0YWxvZy4KCg0KBQQDAgAEEgSEAQIKCg0K
BQQDAgAGEgSEAQsjCg0KBQQDAgABEgSEASQ/Cg0KBQQDAgADEgSEAUJDCkIKAgQEEgaIAQCW
AQEaNCBSZXF1ZXN0IGZvciBVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWcgbWV0aG9k
LgoKCwoDBAQBEgSIAQgtCjMKBAQEAgASBooBAosBLxojIFJlcXVpcmVkLiBUaGUgcXVlc3Rp
b24gdG8gdXBkYXRlLgoKDQoFBAQCAAYSBIoBAhoKDQoFBAQCAAESBIoBGzUKDQoFBAQCAAMS
BIoBODkKDQoFBAQCAAgSBIsBBi4KEAoIBAQCAAicCAASBIsBBy0K2gIKBAQEAgESBpQBApUB
LxrJAiBPcHRpb25hbC4gSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQK
IFtHZW5lcmF0aXZlUXVlc3Rpb25Db25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2Vu
ZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnXQogdG8gdXBkYXRlLiBUaGUgZm9sbG93aW5nIGFyZSBO
T1Qgc3VwcG9ydGVkOgoKICogW0dlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZy5mcmVxdWVuY3ld
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnLmZyZXF1
ZW5jeV0KCiBJZiBub3Qgc2V0IG9yIGVtcHR5LCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBhcmUg
dXBkYXRlZC4KCg0KBQQEAgEGEgSUAQIbCg0KBQQEAgEBEgSUARwnCg0KBQQEAgEDEgSUASor
Cg0KBQQEAgEIEgSVAQYuChAKCAQEAgEInAgAEgSVAQctCkcKAgQFEgaZAQCkAQEaOSBSZXF1
ZXN0IGZvciBCYXRjaFVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZyBtZXRob2QuCgoL
CgMEBQESBJkBCDMKhAEKBAQFAgASBpwBAp8BBBp0IE9wdGlvbmFsLiBSZXNvdXJjZSBuYW1l
IG9mIHRoZSBwYXJlbnQgY2F0YWxvZy4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfQoKDQoFBAUCAAUSBJwBAggK
DQoFBAUCAAESBJwBCQ8KDQoFBAUCAAMSBJwBEhMKDwoFBAUCAAgSBpwBFJ8BAwoQCggEBQIA
CJwIABIEnQEEKgoPCgcEBQIACJ8IEgSeAQRPCjkKBAQFAgESBqIBAqMBLxopIFJlcXVpcmVk
LiBUaGUgdXBkYXRlcyBxdWVzdGlvbiBjb25maWdzLgoKDQoFBAUCAQQSBKIBAgoKDQoFBAUC
AQYSBKIBCzAKDQoFBAUCAQESBKIBMTkKDQoFBAUCAQMSBKIBPD0KDQoFBAUCAQgSBKMBBi4K
EAoIBAUCAQicCAASBKMBBy0KTgoCBAYSBqcBAKsBARpAIEFnZ3JlZ2F0ZWQgcmVzcG9uc2Ug
Zm9yIFVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZyBtZXRob2QuCgoLCgMEBgESBKcB
CDQKOQoEBAYCABIGqQECqgEvGikgT3B0aW9uYWwuIFRoZSB1cGRhdGVzIHF1ZXN0aW9uIGNv
bmZpZ3MuCgoNCgUEBgIABBIEqQECCgoNCgUEBgIABhIEqQELIwoNCgUEBgIAARIEqQEkPwoN
CgUEBgIAAxIEqQFCQwoNCgUEBgIACBIEqgEGLgoQCggEBgIACJwIABIEqgEHLWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest ===
    # Fields for UpdateGenerativeQuestionsFeatureConfigRequest
    # Field: generative_questions_feature_config Type: 11 (.google.cloud.retail.v2.GenerativeQuestionsFeatureConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest ===
    # Fields for GetGenerativeQuestionsFeatureConfigRequest
    # Field: catalog Type: 9 ()

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest ===
    # Fields for ListGenerativeQuestionConfigsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse ===
    # Fields for ListGenerativeQuestionConfigsResponse
    # Field: generative_question_configs Type: 11 (.google.cloud.retail.v2.GenerativeQuestionConfig)

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest ===
    # Fields for UpdateGenerativeQuestionConfigRequest
    # Field: generative_question_config Type: 11 (.google.cloud.retail.v2.GenerativeQuestionConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest ===
    # Fields for BatchUpdateGenerativeQuestionConfigsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.retail.v2.UpdateGenerativeQuestionConfigRequest)

# === Message: Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse ===
    # Fields for BatchUpdateGenerativeQuestionConfigsResponse
    # Field: generative_question_configs Type: 11 (.google.cloud.retail.v2.GenerativeQuestionConfig)

# === Service Client: Google::Cloud::Retail::V2::GenerativeQuestionService::GenerativeQuestionServiceClient ===
package Google::Cloud::Retail::V2::GenerativeQuestionService::GenerativeQuestionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::GenerativeQuestionService::GenerativeQuestionServiceClient

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
        ? Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionsFeatureConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig',
    });
}

sub get_generative_questions_feature_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.GenerativeQuestionService',
        method         => 'GetGenerativeQuestionsFeatureConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig',
    });
}

sub list_generative_question_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.GenerativeQuestionService',
        method         => 'ListGenerativeQuestionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse',
    });
}

sub update_generative_question_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionConfig',
    });
}

sub batch_update_generative_question_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.GenerativeQuestionService',
        method         => 'BatchUpdateGenerativeQuestionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::GenerativeQuestionService - Compiled Protocol Buffers messages for google/cloud/retail/v2/generative_question_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::GenerativeQuestionService;

    my $msg = Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->new({
        generative_questions_feature_config => $generative_questions_feature_config,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->generative_questions_feature_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/generative_question_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest

Request for UpdateGenerativeQuestionsFeatureConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_questions_feature_config() >> / C<< $msg->generative_questions_feature_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig>)

Required. The configuration managing the feature state.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[GenerativeQuestionsFeatureConfig][google.cloud.retail.v2.GenerativeQuestionsFeatureConfig]
to update. If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest

Request for GetGenerativeQuestionsFeatureConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=back

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest

Request for ListQuestions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=back

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse

Response for ListQuestions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_configs() >> / C<< $msg->generative_question_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionConfig>)

All the questions for a given catalog.

=back

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest

Request for UpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_config() >> / C<< $msg->generative_question_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionConfig>)

Required. The question to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[GenerativeQuestionConfig][google.cloud.retail.v2.GenerativeQuestionConfig]
to update. The following are NOT supported:

* [GenerativeQuestionConfig.frequency][google.cloud.retail.v2.GenerativeQuestionConfig.frequency]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest

Request for BatchUpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Optional. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest>)

Required. The updates question configs.

=back

=head2 Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse

Aggregated response for UpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_configs() >> / C<< $msg->generative_question_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionConfig>)

Optional. The updates question configs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::GenerativeQuestionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
