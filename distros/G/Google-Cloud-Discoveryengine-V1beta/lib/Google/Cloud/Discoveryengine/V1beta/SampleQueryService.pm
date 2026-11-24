package Google::Cloud::Discoveryengine::V1beta::SampleQueryService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1beta::SampleQuery };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zYW1wbGVfcXVlcnlfc2Vy
dmljZS5wcm90bxIjZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gjdnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9pbXBvcnRfY29uZmlnLnBy
b3RvGjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zYW1wbGVfcXVlcnku
cHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJv
dG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIl8K
FUdldFNhbXBsZVF1ZXJ5UmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKmRpc2NvdmVy
eWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TYW1wbGVRdWVyeVIEbmFtZSKlAQoYTGlzdFNhbXBs
ZVF1ZXJpZXNSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC+kEvCi1kaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxlUXVlcnlTZXRSBnBhcmVudBIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKcAQoZTGlz
dFNhbXBsZVF1ZXJpZXNSZXNwb25zZRJXCg5zYW1wbGVfcXVlcmllcxgBIAMoCzIwLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5Ug1zYW1wbGVRdWVy
aWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLwAQoYQ3JlYXRl
U2FtcGxlUXVlcnlSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC+kEvCi1kaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxlUXVlcnlTZXRSBnBhcmVudBJYCgxzYW1wbGVf
cXVlcnkYAiABKAsyMC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1w
bGVRdWVyeUID4EECUgtzYW1wbGVRdWVyeRIrCg9zYW1wbGVfcXVlcnlfaWQYAyABKAlCA+BB
AlINc2FtcGxlUXVlcnlJZCKxAQoYVXBkYXRlU2FtcGxlUXVlcnlSZXF1ZXN0ElgKDHNhbXBs
ZV9xdWVyeRgBIAEoCzIwLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNh
bXBsZVF1ZXJ5QgPgQQJSC3NhbXBsZVF1ZXJ5EjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJiChhEZWxldGVTYW1wbGVRdWVy
eVJlcXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCipkaXNjb3ZlcnllbmdpbmUuZ29vZ2xl
YXBpcy5jb20vU2FtcGxlUXVlcnlSBG5hbWUy6Q0KElNhbXBsZVF1ZXJ5U2VydmljZRLWAQoO
R2V0U2FtcGxlUXVlcnkSOi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5H
ZXRTYW1wbGVRdWVyeVJlcXVlc3QaMC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5TYW1wbGVRdWVyeSJWgtPkkwJJEkcvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovc2FtcGxlUXVlcnlTZXRzLyovc2FtcGxlUXVlcmllcy8qfdpBBG5hbWUS7AEK
EUxpc3RTYW1wbGVRdWVyaWVzEj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuTGlzdFNhbXBsZVF1ZXJpZXNSZXF1ZXN0Gj4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuTGlzdFNhbXBsZVF1ZXJpZXNSZXNwb25zZSJYgtPkkwJJEkcvdjFiZXRh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zYW1wbGVRdWVyeVNldHMvKn0vc2Ft
cGxlUXVlcmllc9pBBnBhcmVudBKKAgoRQ3JlYXRlU2FtcGxlUXVlcnkSPS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DcmVhdGVTYW1wbGVRdWVyeVJlcXVlc3QaMC5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeSKDAYLT5JMC
VyJHL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovc2FtcGxlUXVlcnlT
ZXRzLyp9L3NhbXBsZVF1ZXJpZXM6DHNhbXBsZV9xdWVyedpBI3BhcmVudCxzYW1wbGVfcXVl
cnksc2FtcGxlX3F1ZXJ5X2lkEowCChFVcGRhdGVTYW1wbGVRdWVyeRI9Lmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVwZGF0ZVNhbXBsZVF1ZXJ5UmVxdWVzdBowLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5IoUBgtPkkwJk
MlQvdjFiZXRhL3tzYW1wbGVfcXVlcnkubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Nh
bXBsZVF1ZXJ5U2V0cy8qL3NhbXBsZVF1ZXJpZXMvKn06DHNhbXBsZV9xdWVyedpBGHNhbXBs
ZV9xdWVyeSx1cGRhdGVfbWFzaxLCAQoRRGVsZXRlU2FtcGxlUXVlcnkSPS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EZWxldGVTYW1wbGVRdWVyeVJlcXVlc3QaFi5n
b29nbGUucHJvdG9idWYuRW1wdHkiVoLT5JMCSSpHL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL3NhbXBsZVF1ZXJ5U2V0cy8qL3NhbXBsZVF1ZXJpZXMvKn3aQQRuYW1l
EtcCChNJbXBvcnRTYW1wbGVRdWVyaWVzEj8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuSW1wb3J0U2FtcGxlUXVlcmllc1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIt8BgtPkkwJTIk4vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9zYW1wbGVRdWVyeVNldHMvKn0vc2FtcGxlUXVlcmllczppbXBvcnQ6ASrKQYIB
Cj9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JbXBvcnRTYW1wbGVRdWVy
aWVzUmVzcG9uc2USP2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkltcG9y
dFNhbXBsZVF1ZXJpZXNNZXRhZGF0YRrPAcpBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbdJBqgFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3Jt
LGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3
cml0ZSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5z
ZXJ2aW5nLnJlYWR3cml0ZUKeAgonY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhQhdTYW1wbGVRdWVyeVNlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dv
L2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5
ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5n
aW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29v
Z2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKvUQKBxIFDgCJAgEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAJgoJCgID
ARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgBBCgkKAgMFEgMXAEAKCQoC
AwYSAxgALQoJCgIDBxIDGQAlCgkKAgMIEgMaACoKCAoBCBIDHABACgkKAgglEgMcAEAKCAoB
CBIDHQBoCgkKAggLEgMdAGgKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwA4CgkKAggI
EgMfADgKCAoBCBIDIABACgkKAggBEgMgAEAKCAoBCBIDIQAtCgkKAggkEgMhAC0KCAoBCBID
IgBACgkKAggpEgMiAEAKCAoBCBIDIwA/CgkKAggtEgMjAD8KZAoCBgASBCcAbgEaWCBTZXJ2
aWNlIGZvciBtYW5hZ2luZwogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV1zLAoKCgoDBgABEgMnCBoKCgoDBgADEgMoAkYK
DAoFBgADmQgSAygCRgoLCgMGAAMSBCkCLEoKDQoFBgADmggSBCkCLEoKVgoEBgACABIELwI0
AxpIIEdldHMgYSBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLlNhbXBsZVF1ZXJ5XS4KCgwKBQYAAgABEgMvBhQKDAoFBgACAAISAy8VKgoMCgUG
AAIAAxIDLzVACg0KBQYAAgAEEgQwBDIGChEKCQYAAgAEsMq8IhIEMAQyBgoMCgUGAAIABBID
MwQyCg8KCAYAAgAEmwgAEgMzBDIKYAoEBgACARIEOAI+AxpSIEdldHMgYSBsaXN0IG9mCiBb
U2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBs
ZVF1ZXJ5XXMuCgoMCgUGAAIBARIDOAYXCgwKBQYAAgECEgM4GDAKDAoFBgACAQMSAzkPKAoN
CgUGAAIBBBIEOgQ8BgoRCgkGAAIBBLDKvCISBDoEPAYKDAoFBgACAQQSAz0ENAoPCggGAAIB
BJsIABIDPQQ0ClgKBAYAAgISBEECSAMaSiBDcmVhdGVzIGEgW1NhbXBsZVF1ZXJ5XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV0KCgwKBQYAAgIB
EgNBBhcKDAoFBgACAgISA0EYMAoMCgUGAAICAxIDQTtGCg0KBQYAAgIEEgRCBEUGChEKCQYA
AgIEsMq8IhIEQgRFBgoNCgUGAAICBBIERgRHLgoQCggGAAICBJsIABIERgRHLgpZCgQGAAID
EgRLAlEDGksgVXBkYXRlcyBhIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldLgoKDAoFBgACAwESA0sGFwoMCgUGAAIDAhID
SxgwCgwKBQYAAgMDEgNLO0YKDQoFBgACAwQSBEwETwYKEQoJBgACAwSwyrwiEgRMBE8GCgwK
BQYAAgMEEgNQBEYKDwoIBgACAwSbCAASA1AERgpZCgQGAAIEEgRUAloDGksgRGVsZXRlcyBh
IFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2Ft
cGxlUXVlcnldLgoKDAoFBgACBAESA1QGFwoMCgUGAAIEAhIDVBgwCgwKBQYAAgQDEgNVDyQK
DQoFBgACBAQSBFYEWAYKEQoJBgACBASwyrwiEgRWBFgGCgwKBQYAAgQEEgNZBDIKDwoIBgAC
BASbCAASA1kEMgqnAgoEBgACBRIEYwJtAxqYAiBCdWxrIGltcG9ydCBvZiBtdWx0aXBsZQog
W1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1w
bGVRdWVyeV1zLiBTYW1wbGUKIHF1ZXJpZXMgdGhhdCBhbHJlYWR5IGV4aXN0IG1heSBiZSBk
ZWxldGVkLgoKIE5vdGU6IEl0IGlzIHBvc3NpYmxlIGZvciBhIHN1YnNldCBvZiB0aGUKIFtT
YW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxl
UXVlcnldcyB0byBiZQogc3VjY2Vzc2Z1bGx5IGltcG9ydGVkLgoKDAoFBgACBQESA2MGGQoM
CgUGAAIFAhIDYxo0CgwKBQYAAgUDEgNkDysKDQoFBgACBQQSBGUEaAYKEQoJBgACBQSwyrwi
EgRlBGgGCg0KBQYAAgUEEgRpBGwGCg8KBwYAAgUEmQgSBGkEbAYKmAEKAgQAEgVzAIUBARqK
ASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlTZXJ2aWNlLkdldFNhbXBsZVF1
ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeVNl
cnZpY2UuR2V0U2FtcGxlUXVlcnldCiBtZXRob2QuCgoKCgMEAAESA3MIHQqxBAoEBAACABIF
fwKEAQQaoQQgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW1NhbXBsZVF1ZXJ5
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV0sIHN1
Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2FtcGxl
UXVlcnlTZXRzL3tzYW1wbGVfcXVlcnlfc2V0fS9zYW1wbGVRdWVyaWVzL3tzYW1wbGVfcXVl
cnl9YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBhY2Nl
c3MgdGhlCiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLlNhbXBsZVF1ZXJ5XSwgcmVnYXJkbGVzcwogb2Ygd2hldGhlciBvciBub3QgaXQgZXhp
c3RzLCBhIFBFUk1JU1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRoZSBy
ZXF1ZXN0ZWQKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuU2FtcGxlUXVlcnldIGRvZXMgbm90CiBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3Ig
aXMgcmV0dXJuZWQuCgoMCgUEAAIABRIDfwIICgwKBQQAAgABEgN/CQ0KDAoFBAACAAMSA38Q
EQoOCgUEAAIACBIFfxKEAQMKEAoIBAACAAicCAASBIABBCoKEQoHBAACAAifCBIGgQEEgwEF
Cp8BCgIEARIGigEArAEBGpABIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTYW1wbGVRdWVyeVNl
cnZpY2UuTGlzdFNhbXBsZVF1ZXJpZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLlNhbXBsZVF1ZXJ5U2VydmljZS5MaXN0U2FtcGxlUXVlcmllc10KIG1ldGhvZC4K
CgsKAwQBARIEigEIIAqRAwoEBAECABIGkgEClwEEGoADIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHNhbXBsZSBxdWVyeSBzZXQgcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zYW1wbGVRdWVyeVNldHMve3NhbXBsZVF1
ZXJ5U2V0fWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8g
bGlzdAogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TYW1wbGVRdWVyeV1zIHVuZGVyIHRoaXMKIHNhbXBsZSBxdWVyeSBzZXQsIHJlZ2FyZGxl
c3Mgb2Ygd2hldGhlciBvciBub3QgdGhpcyBzYW1wbGUgcXVlcnkgc2V0CiBleGlzdHMsIGEg
YFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgAFEgSSAQII
Cg0KBQQBAgABEgSSAQkPCg0KBQQBAgADEgSSARITCg8KBQQBAgAIEgaSARSXAQMKEAoIBAEC
AAicCAASBJMBBCoKEQoHBAECAAifCBIGlAEElgEFCqUCCgQEAQIBEgSfAQIWGpYCIE1heGlt
dW0gbnVtYmVyIG9mCiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNhbXBsZVF1ZXJ5XXMgdG8gcmV0dXJuLgogSWYgdW5zcGVjaWZpZWQsIGRl
ZmF1bHRzIHRvIDEwMC4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLiBWYWx1
ZXMKIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgogSWYgdGhpcyBmaWVs
ZCBpcyBuZWdhdGl2ZSwgYW4gYElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVk
LgoKDQoFBAECAQUSBJ8BAgcKDQoFBAECAQESBJ8BCBEKDQoFBAECAQMSBJ8BFBUK6QQKBAQB
AgISBKsBAhga2gQgQSBwYWdlIHRva2VuCiBbTGlzdFNhbXBsZVF1ZXJpZXNSZXNwb25zZS5u
ZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxp
c3RTYW1wbGVRdWVyaWVzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXSwKIHJlY2VpdmVkIGZy
b20gYSBwcmV2aW91cwogW1NhbXBsZVF1ZXJ5U2VydmljZS5MaXN0U2FtcGxlUXVlcmllc11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXJ2aWNl
Lkxpc3RTYW1wbGVRdWVyaWVzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRo
ZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1l
dGVycyBwcm92aWRlZCB0bwogW1NhbXBsZVF1ZXJ5U2VydmljZS5MaXN0U2FtcGxlUXVlcmll
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXJ2
aWNlLkxpc3RTYW1wbGVRdWVyaWVzXQogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3Zp
ZGVkIHRoZSBwYWdlIHRva2VuLiBPdGhlcndpc2UsIGFuCiBgSU5WQUxJRF9BUkdVTUVOVGAg
ZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAQICBRIEqwECCAoNCgUEAQICARIEqwEJEwoNCgUE
AQICAxIEqwEWFwqgAQoCBAISBrEBALoBARqRASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1Nh
bXBsZVF1ZXJ5U2VydmljZS5MaXN0U2FtcGxlUXVlcmllc11bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXJ2aWNlLkxpc3RTYW1wbGVRdWVyaWVz
XQogbWV0aG9kLgoKCwoDBAIBEgSxAQghClQKBAQCAgASBLMBAioaRiBUaGUgW1NhbXBsZVF1
ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV1z
LgoKDQoFBAICAAQSBLMBAgoKDQoFBAICAAYSBLMBCxYKDQoFBAICAAESBLMBFyUKDQoFBAIC
AAMSBLMBKCkK8gEKBAQCAgESBLkBAh0a4wEgQSB0b2tlbiB0aGF0IGNhbiBiZSBzZW50IGFz
CiBbTGlzdFNhbXBsZVF1ZXJpZXNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RTYW1wbGVRdWVyaWVzUmVxdWVzdC5wYWdlX3Rv
a2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0
dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAgIBBRIEuQECCAoN
CgUEAgIBARIEuQEJGAoNCgUEAgIBAxIEuQEbHAqfAQoCBAMSBr8BAOABARqQASBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbU2FtcGxlUXVlcnlTZXJ2aWNlLkNyZWF0ZVNhbXBsZVF1ZXJ5XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeVNlcnZpY2Uu
Q3JlYXRlU2FtcGxlUXVlcnldCiBtZXRob2QuCgoLCgMEAwESBL8BCCAKigEKBAQDAgASBsIB
AscBBBp6IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2FtcGxlUXVlcnlTZXRz
L3tzYW1wbGVRdWVyeVNldH1gLgoKDQoFBAMCAAUSBMIBAggKDQoFBAMCAAESBMIBCQ8KDQoF
BAMCAAMSBMIBEhMKDwoFBAMCAAgSBsIBFMcBAwoQCggEAwIACJwIABIEwwEEKgoRCgcEAwIA
CJ8IEgbEAQTGAQUKaAoEBAMCARIEywECSBpaIFJlcXVpcmVkLiBUaGUKIFtTYW1wbGVRdWVy
eV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldIHRv
IGNyZWF0ZS4KCg0KBQQDAgEGEgTLAQINCg0KBQQDAgEBEgTLAQ4aCg0KBQQDAgEDEgTLAR0e
Cg0KBQQDAgEIEgTLAR9HChAKCAQDAgEInAgAEgTLASBGCt8GCgQEAwICEgTfAQJGGtAGIFJl
cXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldLCB3aGljaCB3aWxsCiBi
ZWNvbWUgdGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUKIFtTYW1wbGVRdWVyeS5uYW1lXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeS5uYW1lXS4K
CiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBjcmVhdGUgdGhl
CiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNh
bXBsZVF1ZXJ5XSwgcmVnYXJkbGVzcwogb2Ygd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBh
IGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBmaWVsZCBt
dXN0IGJlIHVuaXF1ZSBhbW9uZyBhbGwKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldcyB3aXRoIHRoZQogc2FtZQogW3Bh
cmVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ3JlYXRlU2FtcGxl
UXVlcnlSZXF1ZXN0LnBhcmVudF0uCiBPdGhlcndpc2UsIGFuIGBBTFJFQURZX0VYSVNUU2Ag
ZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBmaWVsZCBtdXN0IGNvbmZvcm0gdG8gW1JGQy0x
MDM0XShodHRwczovL3Rvb2xzLmlldGYub3JnL2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdp
dGggYSBsZW5ndGggbGltaXQgb2YgNjMgY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbgogYElO
VkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAMCAgUSBN8BAggKDQoF
BAMCAgESBN8BCRgKDQoFBAMCAgMSBN8BGxwKDQoFBAMCAggSBN8BHUUKEAoIBAMCAgicCAAS
BN8BHkQKnwEKAgQEEgblAQDzAQEakAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NhbXBsZVF1
ZXJ5U2VydmljZS5VcGRhdGVTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXJ2aWNlLlVwZGF0ZVNhbXBsZVF1ZXJ5XQogbWV0
aG9kLgoKCwoDBAQBEgTlAQggCoMDCgQEBAIAEgTuAQJIGvQCIFJlcXVpcmVkLiBUaGUgc2lt
cGxlIHF1ZXJ5IHRvIHVwZGF0ZS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVy
bWlzc2lvbiB0byB1cGRhdGUgdGhlCiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5XSwgcmVnYXJkbGVzcwogb2Ygd2hldGhl
ciBvciBub3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMgcmV0
dXJuZWQuCgogSWYgdGhlIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuU2FtcGxlUXVlcnldIHRvCiB1cGRhdGUgZG9lcyBub3QgZXhpc3QgYSBg
Tk9UX0ZPVU5EYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQEAgAGEgTuAQINCg0KBQQEAgAB
EgTuAQ4aCg0KBQQEAgADEgTuAR0eCg0KBQQEAgAIEgTuAR9HChAKCAQEAgAInAgAEgTuASBG
CokBCgQEBAIBEgTyAQIsGnsgSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlk
ZWQgaW1wb3J0ZWQgJ3NpbXBsZSBxdWVyeScgdG8gdXBkYXRlLgogSWYgbm90IHNldCwgd2ls
bCBieSBkZWZhdWx0IHVwZGF0ZSBhbGwgZmllbGRzLgoKDQoFBAQCAQYSBPIBAhsKDQoFBAQC
AQESBPIBHCcKDQoFBAQCAQMSBPIBKisKnwEKAgQFEgb4AQCJAgEakAEgUmVxdWVzdCBtZXNz
YWdlIGZvcgogW1NhbXBsZVF1ZXJ5U2VydmljZS5EZWxldGVTYW1wbGVRdWVyeV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnlTZXJ2aWNlLkRlbGV0
ZVNhbXBsZVF1ZXJ5XQogbWV0aG9kLgoKCwoDBAUBEgT4AQggCrUECgQEBQIAEgaDAgKIAgQa
pAQgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW1NhbXBsZVF1ZXJ5XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV0sIHN1Y2ggYXMK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2FtcGxlUXVlcnlT
ZXRzL3tzYW1wbGVfcXVlcnlfc2V0fS9zYW1wbGVRdWVyaWVzL3tzYW1wbGVfcXVlcnl9YC4K
CiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBkZWxldGUgdGhl
CiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNh
bXBsZVF1ZXJ5XSwgcmVnYXJkbGVzcwogb2Ygd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBh
IGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIFtTYW1w
bGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVl
cnldIHRvCiBkZWxldGUgZG9lcyBub3QgZXhpc3QsIGEgYE5PVF9GT1VORGAgZXJyb3IgaXMg
cmV0dXJuZWQuCgoNCgUEBQIABRIEgwICCAoNCgUEBQIAARIEgwIJDQoNCgUEBQIAAxIEgwIQ
EQoPCgUEBQIACBIGgwISiAIDChAKCAQFAgAInAgAEgSEAgQqChEKBwQFAgAInwgSBoUCBIcC
BWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest ===
    # Fields for GetSampleQueryRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::ListSampleQueriesRequest ===
    # Fields for ListSampleQueriesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::ListSampleQueriesResponse ===
    # Fields for ListSampleQueriesResponse
    # Field: sample_queries Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuery)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::CreateSampleQueryRequest ===
    # Fields for CreateSampleQueryRequest
    # Field: parent Type: 9 ()
    # Field: sample_query Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuery)
    # Field: sample_query_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::UpdateSampleQueryRequest ===
    # Fields for UpdateSampleQueryRequest
    # Field: sample_query Type: 11 (.google.cloud.discoveryengine.v1beta.SampleQuery)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::DeleteSampleQueryRequest ===
    # Fields for DeleteSampleQueryRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::SampleQueryServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::SampleQueryService::SampleQueryServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::SampleQueryService::SampleQueryServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'GetSampleQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery',
    });
}

sub list_sample_queries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQueryService::ListSampleQueriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'ListSampleQueries',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQueryService::ListSampleQueriesResponse',
    });
}

sub create_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQueryService::CreateSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'CreateSampleQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery',
    });
}

sub update_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQueryService::UpdateSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'UpdateSampleQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery',
    });
}

sub delete_sample_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SampleQueryService::DeleteSampleQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'DeleteSampleQuery',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub import_sample_queries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportSampleQueriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'ImportSampleQueries',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SampleQueryService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/sample_query_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SampleQueryService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/sample_query_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest

Request message for
[SampleQueryService.GetSampleQuery][google.cloud.discoveryengine.v1beta.SampleQueryService.GetSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], such as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}/sampleQueries/{sample_query}`.

If the caller does not have permission to access the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], regardless
of whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery] does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQueryService::ListSampleQueriesRequest

Request message for
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1beta.SampleQueryService.ListSampleQueries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent sample query set resource name, such as
`projects/{project}/locations/{location}/sampleQuerySets/{sampleQuerySet}`.

If the caller does not have permission to list
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]s under this
sample query set, regardless of whether or not this sample query set
exists, a `PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]s to return.
If unspecified, defaults to 100. The maximum allowed value is 1000. Values
above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListSampleQueriesResponse.next_page_token][google.cloud.discoveryengine.v1beta.ListSampleQueriesResponse.next_page_token],
received from a previous
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1beta.SampleQueryService.ListSampleQueries]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1beta.SampleQueryService.ListSampleQueries]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQueryService::ListSampleQueriesResponse

Response message for
[SampleQueryService.ListSampleQueries][google.cloud.discoveryengine.v1beta.SampleQueryService.ListSampleQueries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_queries() >> / C<< $msg->sample_queries($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery>)

The [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListSampleQueriesRequest.page_token][google.cloud.discoveryengine.v1beta.ListSampleQueriesRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQueryService::CreateSampleQueryRequest

Request message for
[SampleQueryService.CreateSampleQuery][google.cloud.discoveryengine.v1beta.SampleQueryService.CreateSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/sampleQuerySets/{sampleQuerySet}`.

=item * C<< $msg->sample_query() >> / C<< $msg->sample_query($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery>)

Required. The
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery] to create.

=item * C<< $msg->sample_query_id() >> / C<< $msg->sample_query_id($value) >>

Type: C<String>

Required. The ID to use for the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], which will
become the final component of the
[SampleQuery.name][google.cloud.discoveryengine.v1beta.SampleQuery.name].

If the caller does not have permission to create the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

This field must be unique among all
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]s with the
same
[parent][google.cloud.discoveryengine.v1beta.CreateSampleQueryRequest.parent].
Otherwise, an `ALREADY_EXISTS` error is returned.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQueryService::UpdateSampleQueryRequest

Request message for
[SampleQueryService.UpdateSampleQuery][google.cloud.discoveryengine.v1beta.SampleQueryService.UpdateSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sample_query() >> / C<< $msg->sample_query($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery>)

Required. The simple query to update.

If the caller does not have permission to update the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery] to
update does not exist a `NOT_FOUND` error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported 'simple query' to update.
If not set, will by default update all fields.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SampleQueryService::DeleteSampleQueryRequest

Request message for
[SampleQueryService.DeleteSampleQuery][google.cloud.discoveryengine.v1beta.SampleQueryService.DeleteSampleQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], such as
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}/sampleQueries/{sample_query}`.

If the caller does not have permission to delete the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery] to
delete does not exist, a `NOT_FOUND` error is returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SampleQueryService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
