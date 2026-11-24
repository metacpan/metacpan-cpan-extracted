package Google::Cloud::Discoveryengine::V1::SiteSearchEngine;

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
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NpdGVfc2VhcmNoX2VuZ2luZS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byKbAgoQU2l0ZVNlYXJjaEVuZ2luZRISCgRuYW1lGAEg
ASgJUgRuYW1lOvIB6kHuAQovZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NpdGVT
ZWFyY2hFbmdpbmUSUHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9k
YXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zaXRlU2VhcmNoRW5naW5lEmlwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2Rh
dGFTdG9yZXMve2RhdGFfc3RvcmV9L3NpdGVTZWFyY2hFbmdpbmUi6goKClRhcmdldFNpdGUS
FwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEjgKFHByb3ZpZGVkX3VyaV9wYXR0ZXJuGAIgASgJ
QgbgQQLgQQRSEnByb3ZpZGVkVXJpUGF0dGVybhJECgR0eXBlGAMgASgOMjAuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5UYXJnZXRTaXRlLlR5cGVSBHR5cGUSJAoLZXhhY3Rf
bWF0Y2gYBiABKAhCA+BBBVIKZXhhY3RNYXRjaBI3ChVnZW5lcmF0ZWRfdXJpX3BhdHRlcm4Y
BCABKAlCA+BBA1ITZ2VuZXJhdGVkVXJpUGF0dGVybhIrCg9yb290X2RvbWFpbl91cmkYCiAB
KAlCA+BBA1INcm9vdERvbWFpblVyaRJwChZzaXRlX3ZlcmlmaWNhdGlvbl9pbmZvGAcgASgL
MjUuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TaXRlVmVyaWZpY2F0aW9uSW5m
b0ID4EEDUhRzaXRlVmVyaWZpY2F0aW9uSW5mbxJoCg9pbmRleGluZ19zdGF0dXMYCCABKA4y
Oi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlRhcmdldFNpdGUuSW5kZXhpbmdT
dGF0dXNCA+BBA1IOaW5kZXhpbmdTdGF0dXMSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSZQoOZmFpbHVyZV9yZWFz
b24YCSABKAsyOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlRhcmdldFNpdGUu
RmFpbHVyZVJlYXNvbkID4EEDUg1mYWlsdXJlUmVhc29uGssBCg1GYWlsdXJlUmVhc29uEm0K
DXF1b3RhX2ZhaWx1cmUYASABKAsyRi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LlRhcmdldFNpdGUuRmFpbHVyZVJlYXNvbi5RdW90YUZhaWx1cmVIAFIMcXVvdGFGYWlsdXJl
GkAKDFF1b3RhRmFpbHVyZRIwChR0b3RhbF9yZXF1aXJlZF9xdW90YRgBIAEoA1ISdG90YWxS
ZXF1aXJlZFF1b3RhQgkKB2ZhaWx1cmUiNgoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAAS
CwoHSU5DTFVERRABEgsKB0VYQ0xVREUQAiKHAQoOSW5kZXhpbmdTdGF0dXMSHwobSU5ERVhJ
TkdfU1RBVFVTX1VOU1BFQ0lGSUVEEAASCwoHUEVORElORxABEgoKBkZBSUxFRBACEg0KCVNV
Q0NFRURFRBADEgwKCERFTEVUSU5HEAQSDwoLQ0FOQ0VMTEFCTEUQBRINCglDQU5DRUxMRUQQ
BjqhAupBnQIKKWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9UYXJnZXRTaXRlEmpw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0
YV9zdG9yZX0vc2l0ZVNlYXJjaEVuZ2luZS90YXJnZXRTaXRlcy97dGFyZ2V0X3NpdGV9EoMB
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tj
b2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zaXRlU2VhcmNoRW5naW5lL3Rh
cmdldFNpdGVzL3t0YXJnZXRfc2l0ZX0ixwIKFFNpdGVWZXJpZmljYXRpb25JbmZvEoMBChdz
aXRlX3ZlcmlmaWNhdGlvbl9zdGF0ZRgBIAEoDjJLLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuU2l0ZVZlcmlmaWNhdGlvbkluZm8uU2l0ZVZlcmlmaWNhdGlvblN0YXRlUhVz
aXRlVmVyaWZpY2F0aW9uU3RhdGUSOwoLdmVyaWZ5X3RpbWUYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUgp2ZXJpZnlUaW1lImwKFVNpdGVWZXJpZmljYXRpb25TdGF0ZRIn
CiNTSVRFX1ZFUklGSUNBVElPTl9TVEFURV9VTlNQRUNJRklFRBAAEgwKCFZFUklGSUVEEAES
DgoKVU5WRVJJRklFRBACEgwKCEVYRU1QVEVEEAMikgMKB1NpdGVtYXASEgoDdXJpGAIgASgJ
SABSA3VyaRIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWU6jwLqQYsCCiZk
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2l0ZW1hcBJjcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NpdGVT
ZWFyY2hFbmdpbmUvc2l0ZW1hcHMve3NpdGVtYXB9Enxwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMv
e2RhdGFfc3RvcmV9L3NpdGVTZWFyY2hFbmdpbmUvc2l0ZW1hcHMve3NpdGVtYXB9QgYKBGZl
ZWRCiAIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxQhVTaXRlU2VhcmNo
RW5naW5lUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBp
djEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJ
TkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERp
c2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFK
wTMKBxIFDgDKAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA8CgkKAgglEgMW
ADwKCAoBCBIDFwBkCgkKAggLEgMXAGQKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA2
CgkKAggIEgMZADYKCAoBCBIDGgA8CgkKAggBEgMaADwKCAoBCBIDGwAtCgkKAggkEgMbAC0K
CAoBCBIDHAA8CgkKAggpEgMcADwKCAoBCBIDHQA7CgkKAggtEgMdADsKhwEKAgQAEgQhACsB
GnsgU2l0ZVNlYXJjaEVuZ2luZSBjYXB0dXJlcyBEYXRhU3RvcmUgbGV2ZWwgc2l0ZSBzZWFy
Y2ggcGVyc2lzdGluZwogY29uZmlndXJhdGlvbnMuIEl0IGlzIGEgc2luZ2xldG9uIHZhbHVl
IHBlciBkYXRhIHN0b3JlLgoKCgoDBAABEgMhCBgKCwoDBAAHEgQiAiYECg0KBQQAB50IEgQi
AiYECosBCgQEAAIAEgMqAhIafiBUaGUgZnVsbHkgcXVhbGlmaWVkIHJlc291cmNlIG5hbWUg
b2YgdGhlIHNpdGUgc2VhcmNoIGVuZ2luZS4KIEZvcm1hdDogYHByb2plY3RzLyovbG9jYXRp
b25zLyovZGF0YVN0b3Jlcy8qL3NpdGVTZWFyY2hFbmdpbmVgCgoMCgUEAAIABRIDKgIICgwK
BQQAAgABEgMqCQ0KDAoFBAACAAMSAyoQEQo2CgIEARIFLgCaAQEaKSBBIHRhcmdldCBzaXRl
IGZvciB0aGUgU2l0ZVNlYXJjaEVuZ2luZS4KCgoKAwQBARIDLggSCgsKAwQBBxIELwIzBAoN
CgUEAQedCBIELwIzBAo1CgQEAQMAEgQ2AkMDGicgU2l0ZSBzZWFyY2ggaW5kZXhpbmcgZmFp
bHVyZSByZWFzb25zLgoKDAoFBAEDAAESAzYKFwozCgYEAQMAAwASBDgEPAUaIyBGYWlsZWQg
ZHVlIHRvIGluc3VmZmljaWVudCBxdW90YS4KCg4KBwQBAwADAAESAzgMGAp+CggEAQMAAwAC
ABIDOwYlGm0gVGhpcyBudW1iZXIgaXMgYW4gZXN0aW1hdGlvbiBvbiBob3cgbXVjaCB0b3Rh
bCBxdW90YSB0aGlzIHByb2plY3QgbmVlZHMKIHRvIHN1Y2Nlc3NmdWxseSBjb21wbGV0ZSBp
bmRleGluZy4KChAKCQQBAwADAAIABRIDOwYLChAKCQQBAwADAAIAARIDOwwgChAKCQQBAwAD
AAIAAxIDOyMkCiEKBgQBAwAIABIEPwRCBRoRIEZhaWx1cmUgcmVhc29uLgoKDgoHBAEDAAgA
ARIDPwoRCjIKBgQBAwACABIDQQYlGiMgRmFpbGVkIGR1ZSB0byBpbnN1ZmZpY2llbnQgcXVv
dGEuCgoOCgcEAQMAAgAGEgNBBhIKDgoHBAEDAAIAARIDQRMgCg4KBwQBAwACAAMSA0EjJAor
CgQEAQQAEgRGAlADGh0gUG9zc2libGUgdGFyZ2V0IHNpdGUgdHlwZXMuCgoMCgUEAQQAARID
RgcLCpsBCgYEAQQAAgASA0kEGRqLASBUaGlzIHZhbHVlIGlzIHVudXNlZC4gSW4gdGhpcyBj
YXNlLCBzZXJ2ZXIgYmVoYXZpb3IgZGVmYXVsdHMgdG8KIFtUeXBlLklOQ0xVREVdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVGFyZ2V0U2l0ZS5UeXBlLklOQ0xVREVdLgoK
DgoHBAEEAAIAARIDSQQUCg4KBwQBBAACAAISA0kXGAopCgYEAQQAAgESA0wEEBoaIEluY2x1
ZGUgdGhlIHRhcmdldCBzaXRlLgoKDgoHBAEEAAIBARIDTAQLCg4KBwQBBAACAQISA0wODwop
CgYEAQQAAgISA08EEBoaIEV4Y2x1ZGUgdGhlIHRhcmdldCBzaXRlLgoKDgoHBAEEAAICARID
TwQLCg4KBwQBBAACAgISA08ODwo4CgQEAQQBEgRTAmwDGiogVGFyZ2V0IHNpdGUgaW5kZXhp
bmcgc3RhdHVzIGVudW1lcmF0aW9uLgoKDAoFBAEEAQESA1MHFQonCgYEAQQBAgASA1UEJBoY
IERlZmF1bHRzIHRvIFNVQ0NFRURFRC4KCg4KBwQBBAECAAESA1UEHwoOCgcEAQQBAgACEgNV
IiMKZAoGBAEEAQIBEgNZBBAaVSBUaGUgdGFyZ2V0IHNpdGUgaXMgaW4gdGhlIHVwZGF0ZSBx
dWV1ZSBhbmQgd2lsbCBiZSBwaWNrZWQgdXAgYnkgaW5kZXhpbmcKIHBpcGVsaW5lLgoKDgoH
BAEEAQIBARIDWQQLCg4KBwQBBAECAQISA1kODwo1CgYEAQQBAgISA1wEDxomIFRoZSB0YXJn
ZXQgc2l0ZSBmYWlscyB0byBiZSBpbmRleGVkLgoKDgoHBAEEAQICARIDXAQKCg4KBwQBBAEC
AgISA1wNDgoyCgYEAQQBAgMSA18EEhojIFRoZSB0YXJnZXQgc2l0ZSBoYXMgYmVlbiBpbmRl
eGVkLgoKDgoHBAEEAQIDARIDXwQNCg4KBwQBBAECAwISA18QEQr+AQoGBAEEAQIEEgNlBBEa
7gEgVGhlIHByZXZpb3VzbHkgaW5kZXhlZCB0YXJnZXQgc2l0ZSBoYXMgYmVlbiBtYXJrZWQg
dG8gYmUgZGVsZXRlZC4gVGhpcyBpcwogYSB0cmFuc2l0aW9uaW5nIHN0YXRlIHdoaWNoIHdp
bGwgcmVzdWx0ZWQgaW4gZWl0aGVyOgogMS4gdGFyZ2V0IHNpdGUgZGVsZXRlZCBpZiB1bmlu
ZGV4aW5nIGlzIHN1Y2Nlc3NmdWw7CiAyLiBzdGF0ZSByZXZlcnRzIHRvIFNVQ0NFRURFRCBp
ZiB0aGUgdW5pbmRleGluZyBmYWlscy4KCg4KBwQBBAECBAESA2UEDAoOCgcEAQQBAgQCEgNl
DxAKQwoGBAEEAQIFEgNoBBQaNCBUaGUgdGFyZ2V0IHNpdGUgY2hhbmdlIGlzIHBlbmRpbmcg
YnV0IGNhbmNlbGxhYmxlLgoKDgoHBAEEAQIFARIDaAQPCg4KBwQBBAECBQISA2gSEwo1CgYE
AQQBAgYSA2sEEhomIFRoZSB0YXJnZXQgc2l0ZSBjaGFuZ2UgaXMgY2FuY2VsbGVkLgoKDgoH
BAEEAQIGARIDawQNCg4KBwQBBAECBgISA2sQEQqEAgoEBAECABIDcQI+GvYBIE91dHB1dCBv
bmx5LiBUaGUgZnVsbHkgcXVhbGlmaWVkIHJlc291cmNlIG5hbWUgb2YgdGhlIHRhcmdldCBz
aXRlLgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0
aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2l0ZVNlYXJjaEVu
Z2luZS90YXJnZXRTaXRlcy97dGFyZ2V0X3NpdGV9YAogVGhlIGB0YXJnZXRfc2l0ZV9pZGAg
aXMgc3lzdGVtLWdlbmVyYXRlZC4KCgwKBQQBAgAFEgNxAggKDAoFBAECAAESA3EJDQoMCgUE
AQIAAxIDcRARCgwKBQQBAgAIEgNxEj0KDwoIBAECAAicCAASA3ETPAp5CgQEAQIBEgR1AngE
GmsgUmVxdWlyZWQuIElucHV0IG9ubHkuIFRoZSB1c2VyIHByb3ZpZGVkIFVSSSBwYXR0ZXJu
IGZyb20gd2hpY2ggdGhlCiBgZ2VuZXJhdGVkX3VyaV9wYXR0ZXJuYCBpcyBnZW5lcmF0ZWQu
CgoMCgUEAQIBBRIDdQIICgwKBQQBAgEBEgN1CR0KDAoFBAECAQMSA3UgIQoNCgUEAQIBCBIE
dSJ4AwoPCggEAQIBCJwIABIDdgQqCg8KCAQBAgEInAgBEgN3BCwKYgoEBAECAhIDfAIQGlUg
VGhlIHR5cGUgb2YgdGhlIHRhcmdldCBzaXRlLCBlLmcuLCB3aGV0aGVyIHRoZSBzaXRlIGlz
IHRvIGJlIGluY2x1ZGVkIG9yCiBleGNsdWRlZC4KCgwKBQQBAgIGEgN8AgYKDAoFBAECAgES
A3wHCwoMCgUEAQICAxIDfA4PCqYDCgQEAQIDEgSEAQJBGpcDIEltbXV0YWJsZS4gSWYgc2V0
IHRvIGZhbHNlLCBhIHVyaV9wYXR0ZXJuIGlzIGdlbmVyYXRlZCB0byBpbmNsdWRlIGFsbCBw
YWdlcwogd2hvc2UgYWRkcmVzcyBjb250YWlucyB0aGUgcHJvdmlkZWRfdXJpX3BhdHRlcm4u
IElmIHNldCB0byB0cnVlLCBhbgogdXJpX3BhdHRlcm4gaXMgZ2VuZXJhdGVkIHRvIHRyeSB0
byBiZSBhbiBleGFjdCBtYXRjaCBvZiB0aGUKIHByb3ZpZGVkX3VyaV9wYXR0ZXJuIG9yIGp1
c3QgdGhlIHNwZWNpZmljIHBhZ2UgaWYgdGhlIHByb3ZpZGVkX3VyaV9wYXR0ZXJuCiBpcyBh
IHNwZWNpZmljIG9uZS4gcHJvdmlkZWRfdXJpX3BhdHRlcm4gaXMgYWx3YXlzIG5vcm1hbGl6
ZWQgdG8KIGdlbmVyYXRlIHRoZSBVUkkgcGF0dGVybiB0byBiZSB1c2VkIGJ5IHRoZSBzZWFy
Y2ggZW5naW5lLgoKDQoFBAECAwUSBIQBAgYKDQoFBAECAwESBIQBBxIKDQoFBAECAwMSBIQB
FRYKDQoFBAECAwgSBIQBF0AKEAoIBAECAwicCAASBIQBGD8KWAoEBAECBBIEhwECTxpKIE91
dHB1dCBvbmx5LiBUaGlzIGlzIHN5c3RlbS1nZW5lcmF0ZWQgYmFzZWQgb24gdGhlIHByb3Zp
ZGVkX3VyaV9wYXR0ZXJuLgoKDQoFBAECBAUSBIcBAggKDQoFBAECBAESBIcBCR4KDQoFBAEC
BAMSBIcBISIKDQoFBAECBAgSBIcBI04KEAoIBAECBAicCAASBIcBJE0KRQoEBAECBRIEigEC
Sho3IE91dHB1dCBvbmx5LiBSb290IGRvbWFpbiBvZiB0aGUgcHJvdmlkZWRfdXJpX3BhdHRl
cm4uCgoNCgUEAQIFBRIEigECCAoNCgUEAQIFARIEigEJGAoNCgUEAQIFAxIEigEbHQoNCgUE
AQIFCBIEigEeSQoQCggEAQIFCJwIABIEigEfSApPCgQEAQIGEgaNAQKOATIaPyBPdXRwdXQg
b25seS4gU2l0ZSBvd25lcnNoaXAgYW5kIHZhbGlkaXR5IHZlcmlmaWNhdGlvbiBzdGF0dXMu
CgoNCgUEAQIGBhIEjQECFgoNCgUEAQIGARIEjQEXLQoNCgUEAQIGAxIEjQEwMQoNCgUEAQIG
CBIEjgEGMQoQCggEAQIGCJwIABIEjgEHMAovCgQEAQIHEgaRAQKSATIaHyBPdXRwdXQgb25s
eS4gSW5kZXhpbmcgc3RhdHVzLgoKDQoFBAECBwYSBJEBAhAKDQoFBAECBwESBJEBESAKDQoF
BAECBwMSBJEBIyQKDQoFBAECBwgSBJIBBjEKEAoIBAECBwicCAASBJIBBzAKQwoEBAECCBIG
lQEClgEyGjMgT3V0cHV0IG9ubHkuIFRoZSB0YXJnZXQgc2l0ZSdzIGxhc3QgdXBkYXRlZCB0
aW1lLgoKDQoFBAECCAYSBJUBAhsKDQoFBAECCAESBJUBHCcKDQoFBAECCAMSBJUBKisKDQoF
BAECCAgSBJYBBjEKEAoIBAECCAicCAASBJYBBzAKLAoEBAECCRIEmQECTxoeIE91dHB1dCBv
bmx5LiBGYWlsdXJlIHJlYXNvbi4KCg0KBQQBAgkGEgSZAQIPCg0KBQQBAgkBEgSZARAeCg0K
BQQBAgkDEgSZASEiCg0KBQQBAgkIEgSZASNOChAKCAQBAgkInAgAEgSZASRNClIKAgQCEgad
AQCyAQEaRCBWZXJpZmljYXRpb24gaW5mb3JtYXRpb24gZm9yIHRhcmdldCBzaXRlcyBpbiBh
ZHZhbmNlZCBzaXRlIHNlYXJjaC4KCgsKAwQCARIEnQEIHAoqCgQEAgQAEgafAQKrAQMaGiBT
aXRlIHZlcmlmaWNhdGlvbiBzdGF0ZS4KCg0KBQQCBAABEgSfAQccCicKBgQCBAACABIEoQEE
LBoXIERlZmF1bHRzIHRvIFZFUklGSUVELgoKDwoHBAIEAAIAARIEoQEEJwoPCgcEAgQAAgAC
EgShASorCioKBgQCBAACARIEpAEEERoaIFNpdGUgb3duZXJzaGlwIHZlcmlmaWVkLgoKDwoH
BAIEAAIBARIEpAEEDAoPCgcEAgQAAgECEgSkAQ8QCk0KBgQCBAACAhIEpwEEExo9IFNpdGUg
b3duZXJzaGlwIHBlbmRpbmcgdmVyaWZpY2F0aW9uIG9yIHZlcmlmaWNhdGlvbiBmYWlsZWQu
CgoPCgcEAgQAAgIBEgSnAQQOCg8KBwQCBAACAgISBKcBERIKWgoGBAIEAAIDEgSqAQQRGkog
U2l0ZSBleGVtcHQgZnJvbSB2ZXJpZmljYXRpb24sIGUuZy4sIGEgcHVibGljIHdlYnNpdGUg
dGhhdCBvcGVucyB0byBhbGwuCgoPCgcEAgQAAgMBEgSqAQQMCg8KBwQCBAACAwISBKoBDxAK
TgoEBAICABIErgECNBpAIFNpdGUgdmVyaWZpY2F0aW9uIHN0YXRlIGluZGljYXRpbmcgdGhl
IG93bmVyc2hpcCBhbmQgdmFsaWRpdHkuCgoNCgUEAgIABhIErgECFwoNCgUEAgIAARIErgEY
LwoNCgUEAgIAAxIErgEyMwouCgQEAgIBEgSxAQIsGiAgTGF0ZXN0IHNpdGUgdmVyaWZpY2F0
aW9uIHRpbWUuCgoNCgUEAgIBBhIEsQECGwoNCgUEAgIBARIEsQEcJwoNCgUEAgIBAxIEsQEq
KwozCgIEAxIGtQEAygEBGiUgQSBzaXRlbWFwIGZvciB0aGUgU2l0ZVNlYXJjaEVuZ2luZS4K
CgsKAwQDARIEtQEIDwoNCgMEAwcSBrYBAroBBAoPCgUEAwedCBIGtgECugEECikKBAQDCAAS
Br0BAsABAxoZIFN1cHBvcnRlZCBmZWVkIHNvdXJjZXMuCgoNCgUEAwgAARIEvQEIDApPCgQE
AwIAEgS/AQQTGkEgUHVibGljIFVSSSBmb3IgdGhlIHNpdGVtYXAsIGUuZy4gYHd3dy5leGFt
cGxlLmNvbS9zaXRlbWFwLnhtbGAuCgoNCgUEAwIABRIEvwEECgoNCgUEAwIAARIEvwELDgoN
CgUEAwIAAxIEvwEREgrOAQoEBAMCARIExQECPhq/ASBPdXRwdXQgb25seS4gVGhlIGZ1bGx5
IHF1YWxpZmllZCByZXNvdXJjZSBuYW1lIG9mIHRoZSBzaXRlbWFwLgogYHByb2plY3RzLyov
bG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2l0ZVNlYXJjaEVuZ2lu
ZS9zaXRlbWFwcy8qYAogVGhlIGBzaXRlbWFwX2lkYCBzdWZmaXggaXMgc3lzdGVtLWdlbmVy
YXRlZC4KCg0KBQQDAgEFEgTFAQIICg0KBQQDAgEBEgTFAQkNCg0KBQQDAgEDEgTFARARCg0K
BQQDAgEIEgTFARI9ChAKCAQDAgEInAgAEgTFARM8CjsKBAQDAgISBsgBAskBMhorIE91dHB1
dCBvbmx5LiBUaGUgc2l0ZW1hcCdzIGNyZWF0aW9uIHRpbWUuCgoNCgUEAwICBhIEyAECGwoN
CgUEAwICARIEyAEcJwoNCgUEAwICAxIEyAEqKwoNCgUEAwICCBIEyQEGMQoQCggEAwICCJwI
ABIEyQEHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine ===
    # Fields for SiteSearchEngine
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SiteSearchEngine::TargetSite ===
    # Fields for TargetSite
    # Field: name Type: 9 ()
    # Field: provided_uri_pattern Type: 9 ()
    # Field: type Type: 14 (.google.cloud.discoveryengine.v1.TargetSite.Type)
    # Field: exact_match Type: 8 ()
    # Field: generated_uri_pattern Type: 9 ()
    # Field: root_domain_uri Type: 9 ()
    # Field: site_verification_info Type: 11 (.google.cloud.discoveryengine.v1.SiteVerificationInfo)
    # Field: indexing_status Type: 14 (.google.cloud.discoveryengine.v1.TargetSite.IndexingStatus)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: failure_reason Type: 11 (.google.cloud.discoveryengine.v1.TargetSite.FailureReason)

# Enum: TargetSite::Type
our $TargetSite_TYPE_UNSPECIFIED = 0;
our $TargetSite_INCLUDE = 1;
our $TargetSite_EXCLUDE = 2;

# Enum: TargetSite::IndexingStatus
our $TargetSite_INDEXING_STATUS_UNSPECIFIED = 0;
our $TargetSite_PENDING = 1;
our $TargetSite_FAILED = 2;
our $TargetSite_SUCCEEDED = 3;
our $TargetSite_DELETING = 4;
our $TargetSite_CANCELLABLE = 5;
our $TargetSite_CANCELLED = 6;

# === Message: Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteVerificationInfo ===
    # Fields for SiteVerificationInfo
    # Field: site_verification_state Type: 14 (.google.cloud.discoveryengine.v1.SiteVerificationInfo.SiteVerificationState)
    # Field: verify_time Type: 11 (.google.protobuf.Timestamp)

# Enum: SiteVerificationInfo::SiteVerificationState
our $SiteVerificationInfo_SITE_VERIFICATION_STATE_UNSPECIFIED = 0;
our $SiteVerificationInfo_VERIFIED = 1;
our $SiteVerificationInfo_UNVERIFIED = 2;
our $SiteVerificationInfo_EXEMPTED = 3;

# === Message: Google::Cloud::Discoveryengine::V1::SiteSearchEngine::Sitemap ===
    # Fields for Sitemap
    # Field: uri Type: 9 ()
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::SiteSearchEngine - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/site_search_engine.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::SiteSearchEngine;

    my $msg = Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/site_search_engine.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine

SiteSearchEngine captures DataStore level site search persisting
configurations. It is a singleton value per data store.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fully qualified resource name of the site search engine.
Format: `projects/*/locations/*/dataStores/*/siteSearchEngine`

=back

=head2 Google::Cloud::Discoveryengine::V1::SiteSearchEngine::TargetSite

A target site for the SiteSearchEngine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The fully qualified resource name of the target site.
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/siteSearchEngine/targetSites/{target_site}`
The `target_site_id` is system-generated.

=item * C<< $msg->provided_uri_pattern() >> / C<< $msg->provided_uri_pattern($value) >>

Type: C<String>

Required. Input only. The user provided URI pattern from which the
`generated_uri_pattern` is generated.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::TargetSite::Type>)

The type of the target site, e.g., whether the site is to be included or
excluded.

=item * C<< $msg->exact_match() >> / C<< $msg->exact_match($value) >>

Type: C<Bool>

Immutable. If set to false, a uri_pattern is generated to include all pages
whose address contains the provided_uri_pattern. If set to true, an
uri_pattern is generated to try to be an exact match of the
provided_uri_pattern or just the specific page if the provided_uri_pattern
is a specific one. provided_uri_pattern is always normalized to
generate the URI pattern to be used by the search engine.

=item * C<< $msg->generated_uri_pattern() >> / C<< $msg->generated_uri_pattern($value) >>

Type: C<String>

Output only. This is system-generated based on the provided_uri_pattern.

=item * C<< $msg->root_domain_uri() >> / C<< $msg->root_domain_uri($value) >>

Type: C<String>

Output only. Root domain of the provided_uri_pattern.

=item * C<< $msg->site_verification_info() >> / C<< $msg->site_verification_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteVerificationInfo>)

Output only. Site ownership and validity verification status.

=item * C<< $msg->indexing_status() >> / C<< $msg->indexing_status($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::TargetSite::IndexingStatus>)

Output only. Indexing status.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The target site's last updated time.

=item * C<< $msg->failure_reason() >> / C<< $msg->failure_reason($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::SiteSearchEngine::TargetSite::FailureReason>)

Output only. Failure reason.

=back

=head3 Enum: TargetSite::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<INCLUDE> => C<1>

=item * C<EXCLUDE> => C<2>

=back

=head3 Enum: TargetSite::IndexingStatus

=over 4

=item * C<INDEXING_STATUS_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<FAILED> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<DELETING> => C<4>

=item * C<CANCELLABLE> => C<5>

=item * C<CANCELLED> => C<6>

=back

=head2 Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteVerificationInfo

Verification information for target sites in advanced site search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->site_verification_state() >> / C<< $msg->site_verification_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::SiteVerificationInfo::SiteVerificationState>)

Site verification state indicating the ownership and validity.

=item * C<< $msg->verify_time() >> / C<< $msg->verify_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Latest site verification time.

=back

=head3 Enum: SiteVerificationInfo::SiteVerificationState

=over 4

=item * C<SITE_VERIFICATION_STATE_UNSPECIFIED> => C<0>

=item * C<VERIFIED> => C<1>

=item * C<UNVERIFIED> => C<2>

=item * C<EXEMPTED> => C<3>

=back

=head2 Google::Cloud::Discoveryengine::V1::SiteSearchEngine::Sitemap

A sitemap for the SiteSearchEngine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Public URI for the sitemap, e.g. `www.example.com/sitemap.xml`.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The fully qualified resource name of the sitemap.
`projects/*/locations/*/collections/*/dataStores/*/siteSearchEngine/sitemaps/*`
The `sitemap_id` suffix is system-generated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The sitemap's creation time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::SiteSearchEngine::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
