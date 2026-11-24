package Google::Cloud::Support::V2beta::CaseService;

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
    eval { require Google::Cloud::Support::V2beta::Case };
    eval { require Google::Cloud::Support::V2beta::Escalation };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvY2FzZV9zZXJ2aWNlLnByb3RvEhtnb29n
bGUuY2xvdWQuc3VwcG9ydC52MmJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiZnb29nbGUvY2xvdWQvc3VwcG9ydC92
MmJldGEvY2FzZS5wcm90bxosZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjJiZXRhL2VzY2FsYXRp
b24ucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIk4KDkdldENhc2VS
ZXF1ZXN0EjwKBG5hbWUYASABKAlCKOBBAvpBIgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMu
Y29tL0Nhc2VSBG5hbWUikQEKEUNyZWF0ZUNhc2VSZXF1ZXN0EkAKBnBhcmVudBgBIAEoCUIo
4EEC+kEiEiBjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vQ2FzZVIGcGFyZW50EjoKBGNh
c2UYAiABKAsyIS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQ2FzZUID4EECUgRjYXNl
IosCChBMaXN0Q2FzZXNSZXF1ZXN0EkAKBnBhcmVudBgBIAEoCUIo4EEC+kEiEiBjbG91ZHN1
cHBvcnQuZ29vZ2xlYXBpcy5jb20vQ2FzZVIGcGFyZW50EhYKBmZpbHRlchgCIAEoCVIGZmls
dGVyEhsKCXBhZ2Vfc2l6ZRgEIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgFIAEoCVIJ
cGFnZVRva2VuElAKDHByb2R1Y3RfbGluZRgIIAEoDjIoLmdvb2dsZS5jbG91ZC5zdXBwb3J0
LnYyYmV0YS5Qcm9kdWN0TGluZUgAUgtwcm9kdWN0TGluZYgBAUIPCg1fcHJvZHVjdF9saW5l
InQKEUxpc3RDYXNlc1Jlc3BvbnNlEjcKBWNhc2VzGAEgAygLMiEuZ29vZ2xlLmNsb3VkLnN1
cHBvcnQudjJiZXRhLkNhc2VSBWNhc2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiJ+ChJTZWFyY2hDYXNlc1JlcXVlc3QSFgoGcGFyZW50GAQgASgJUgZwYXJl
bnQSFAoFcXVlcnkYASABKAlSBXF1ZXJ5EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUS
HQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuInYKE1NlYXJjaENhc2VzUmVzcG9uc2US
NwoFY2FzZXMYASADKAsyIS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQ2FzZVIFY2Fz
ZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIpwBChNFc2NhbGF0
ZUNhc2VSZXF1ZXN0EjwKBG5hbWUYASABKAlCKOBBAvpBIgogY2xvdWRzdXBwb3J0Lmdvb2ds
ZWFwaXMuY29tL0Nhc2VSBG5hbWUSRwoKZXNjYWxhdGlvbhgCIAEoCzInLmdvb2dsZS5jbG91
ZC5zdXBwb3J0LnYyYmV0YS5Fc2NhbGF0aW9uUgplc2NhbGF0aW9uIowBChFVcGRhdGVDYXNl
UmVxdWVzdBI6CgRjYXNlGAEgASgLMiEuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLkNh
c2VCA+BBAlIEY2FzZRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tSCnVwZGF0ZU1hc2siUAoQQ2xvc2VDYXNlUmVxdWVzdBI8CgRuYW1lGAEgASgJ
QijgQQL6QSIKIGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9DYXNlUgRuYW1lIrkBCiBT
ZWFyY2hDYXNlQ2xhc3NpZmljYXRpb25zUmVxdWVzdBIUCgVxdWVyeRgBIAEoCVIFcXVlcnkS
GwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdl
VG9rZW4SQwoHcHJvZHVjdBgHIAEoCzIkLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5Q
cm9kdWN0QgPgQQFSB3Byb2R1Y3QirwEKIVNlYXJjaENhc2VDbGFzc2lmaWNhdGlvbnNSZXNw
b25zZRJiChRjYXNlX2NsYXNzaWZpY2F0aW9ucxgBIAMoCzIvLmdvb2dsZS5jbG91ZC5zdXBw
b3J0LnYyYmV0YS5DYXNlQ2xhc3NpZmljYXRpb25SE2Nhc2VDbGFzc2lmaWNhdGlvbnMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMssNCgtDYXNlU2VydmljZRK1
AQoHR2V0Q2FzZRIrLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5HZXRDYXNlUmVxdWVz
dBohLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5DYXNlIlqC0+STAk0SIS92MmJldGEv
e25hbWU9cHJvamVjdHMvKi9jYXNlcy8qfVooEiYvdjJiZXRhL3tuYW1lPW9yZ2FuaXphdGlv
bnMvKi9jYXNlcy8qfdpBBG5hbWUSyAEKCUxpc3RDYXNlcxItLmdvb2dsZS5jbG91ZC5zdXBw
b3J0LnYyYmV0YS5MaXN0Q2FzZXNSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJi
ZXRhLkxpc3RDYXNlc1Jlc3BvbnNlIlyC0+STAk0SIS92MmJldGEve3BhcmVudD1wcm9qZWN0
cy8qfS9jYXNlc1ooEiYvdjJiZXRhL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qfS9jYXNlc9pB
BnBhcmVudBLTAQoLU2VhcmNoQ2FzZXMSLy5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEu
U2VhcmNoQ2FzZXNSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLlNlYXJj
aENhc2VzUmVzcG9uc2UiYYLT5JMCWxIoL3YyYmV0YS97cGFyZW50PXByb2plY3RzLyp9L2Nh
c2VzOnNlYXJjaFovEi0vdjJiZXRhL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qfS9jYXNlczpz
ZWFyY2gSzgEKCkNyZWF0ZUNhc2USLi5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQ3Jl
YXRlQ2FzZVJlcXVlc3QaIS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQ2FzZSJtgtPk
kwJZIiEvdjJiZXRhL3twYXJlbnQ9cHJvamVjdHMvKn0vY2FzZXM6BGNhc2VaLiImL3YyYmV0
YS97cGFyZW50PW9yZ2FuaXphdGlvbnMvKn0vY2FzZXM6BGNhc2XaQQtwYXJlbnQsY2FzZRLd
AQoKVXBkYXRlQ2FzZRIuLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5VcGRhdGVDYXNl
UmVxdWVzdBohLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5DYXNlInyC0+STAmMyJi92
MmJldGEve2Nhc2UubmFtZT1wcm9qZWN0cy8qL2Nhc2VzLyp9OgRjYXNlWjMyKy92MmJldGEv
e2Nhc2UubmFtZT1vcmdhbml6YXRpb25zLyovY2FzZXMvKn06BGNhc2XaQRBjYXNlLHVwZGF0
ZV9tYXNrEtABCgxFc2NhbGF0ZUNhc2USMC5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEu
RXNjYWxhdGVDYXNlUmVxdWVzdBohLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5DYXNl
ImuC0+STAmUiKi92MmJldGEve25hbWU9cHJvamVjdHMvKi9jYXNlcy8qfTplc2NhbGF0ZToB
Klo0Ii8vdjJiZXRhL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9jYXNlcy8qfTplc2NhbGF0ZToB
KhLEAQoJQ2xvc2VDYXNlEi0uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLkNsb3NlQ2Fz
ZVJlcXVlc3QaIS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQ2FzZSJlgtPkkwJfIicv
djJiZXRhL3tuYW1lPXByb2plY3RzLyovY2FzZXMvKn06Y2xvc2U6ASpaMSIsL3YyYmV0YS97
bmFtZT1vcmdhbml6YXRpb25zLyovY2FzZXMvKn06Y2xvc2U6ASoSxgEKGVNlYXJjaENhc2VD
bGFzc2lmaWNhdGlvbnMSPS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuU2VhcmNoQ2Fz
ZUNsYXNzaWZpY2F0aW9uc1JlcXVlc3QaPi5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEu
U2VhcmNoQ2FzZUNsYXNzaWZpY2F0aW9uc1Jlc3BvbnNlIiqC0+STAiQSIi92MmJldGEvY2Fz
ZUNsYXNzaWZpY2F0aW9uczpzZWFyY2gaT8pBG2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNv
bdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CzQEK
H2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGFCEENhc2VTZXJ2aWNlUHJvdG9QAVo5
Y2xvdWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2FwaXYyYmV0YS9zdXBwb3J0cGI7c3VwcG9y
dHBiqgIbR29vZ2xlLkNsb3VkLlN1cHBvcnQuVjJCZXRhygIbR29vZ2xlXENsb3VkXFN1cHBv
cnRcVjJiZXRh6gIeR29vZ2xlOjpDbG91ZDo6U3VwcG9ydDo6VjJiZXRhSsxYCgcSBQ4A9wIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAMAoJCgIDBRID
FwA2CgkKAgMGEgMYACoKCAoBCBIDGgA4CgkKAgglEgMaADgKCAoBCBIDGwBQCgkKAggLEgMb
AFAKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQAxCgkKAggIEgMdADEKCAoBCBIDHgA4
CgkKAggBEgMeADgKCAoBCBIDHwA4CgkKAggpEgMfADgKCAoBCBIDIAA3CgkKAggtEgMgADcK
PgoCBgASBSMAlAEBGjEgQSBzZXJ2aWNlIHRvIG1hbmFnZSBHb29nbGUgQ2xvdWQgc3VwcG9y
dCBjYXNlcy4KCgoKAwYAARIDIwgTCgoKAwYAAxIDJAJDCgwKBQYAA5kIEgMkAkMKCwoDBgAD
EgQlAiY3Cg0KBQYAA5oIEgQlAiY3CiAKBAYAAgASBCkCLwMaEiBSZXRyaWV2ZSBhIGNhc2Uu
CgoMCgUGAAIAARIDKQYNCgwKBQYAAgACEgMpDhwKDAoFBgACAAMSAyknKwoNCgUGAAIABBIE
KgQtBgoRCgkGAAIABLDKvCISBCoELQYKDAoFBgACAAQSAy4EMgoPCggGAAIABJsIABIDLgQy
CpQCCgQGAAIBEgQ2AjwDGoUCIFJldHJpZXZlIGFsbCBjYXNlcyB1bmRlciBhIHBhcmVudCwg
YnV0IG5vdCBpdHMgY2hpbGRyZW4uCgogRm9yIGV4YW1wbGUsIGxpc3RpbmcgY2FzZXMgdW5k
ZXIgYW4gb3JnYW5pemF0aW9uIG9ubHkgcmV0dXJucyB0aGUgY2FzZXMKIHRoYXQgYXJlIGRp
cmVjdGx5IHBhcmVudGVkIGJ5IHRoYXQgb3JnYW5pemF0aW9uLiBUbyByZXRyaWV2ZSBjYXNl
cwogdW5kZXIgYW4gb3JnYW5pemF0aW9uIGFuZCBpdHMgcHJvamVjdHMsIHVzZSBgY2FzZXMu
c2VhcmNoYC4KCgwKBQYAAgEBEgM2Bg8KDAoFBgACAQISAzYQIAoMCgUGAAIBAxIDNis8Cg0K
BQYAAgEEEgQ3BDoGChEKCQYAAgEEsMq8IhIENwQ6BgoMCgUGAAIBBBIDOwQ0Cg8KCAYAAgEE
mwgAEgM7BDQKLwoEBgACAhIEPwJGAxohIFNlYXJjaCBmb3IgY2FzZXMgdXNpbmcgYSBxdWVy
eS4KCgwKBQYAAgIBEgM/BhEKDAoFBgACAgISAz8SJAoMCgUGAAICAxIDPy9CCg0KBQYAAgIE
EgRABEUGChEKCQYAAgIEsMq8IhIEQARFBgqRAgoEBgACAxIETQJXAxqCAiBDcmVhdGUgYSBu
ZXcgY2FzZSBhbmQgYXNzb2NpYXRlIGl0IHdpdGggYSBwYXJlbnQuCgogSXQgbXVzdCBoYXZl
IHRoZSBmb2xsb3dpbmcgZmllbGRzIHNldDogYGRpc3BsYXlfbmFtZWAsIGBkZXNjcmlwdGlv
bmAsCiBgY2xhc3NpZmljYXRpb25gLCBhbmQgYHByaW9yaXR5YC4gSWYgeW91J3JlIGp1c3Qg
dGVzdGluZyB0aGUgQVBJIGFuZCBkb24ndAogd2FudCB0byByb3V0ZSB5b3VyIGNhc2UgdG8g
YW4gYWdlbnQsIHNldCBgdGVzdENhc2U9dHJ1ZWAuCgoMCgUGAAIDARIDTQYQCgwKBQYAAgMC
EgNNESIKDAoFBgACAwMSA00tMQoNCgUGAAIDBBIETgRVBgoRCgkGAAIDBLDKvCISBE4EVQYK
DAoFBgACAwQSA1YEOQoPCggGAAIDBJsIABIDVgQ5Cj8KBAYAAgQSBFoCZAMaMSBVcGRhdGUg
YSBjYXNlLiBPbmx5IHNvbWUgZmllbGRzIGNhbiBiZSB1cGRhdGVkLgoKDAoFBgACBAESA1oG
EAoMCgUGAAIEAhIDWhEiCgwKBQYAAgQDEgNaLTEKDQoFBgACBAQSBFsEYgYKEQoJBgACBASw
yrwiEgRbBGIGCgwKBQYAAgQEEgNjBD4KDwoIBgACBASbCAASA2MEPgq0AgoEBgACBRIEbQJ2
AxqlAiBFc2NhbGF0ZSBhIGNhc2UsIHN0YXJ0aW5nIHRoZSBHb29nbGUgQ2xvdWQgU3VwcG9y
dCBlc2NhbGF0aW9uIG1hbmFnZW1lbnQKIHByb2Nlc3MuCgogVGhpcyBvcGVyYXRpb24gaXMg
b25seSBhdmFpbGFibGUgZm9yIHNvbWUgc3VwcG9ydCBzZXJ2aWNlcy4gR28gdG8KIGh0dHBz
Oi8vY2xvdWQuZ29vZ2xlLmNvbS9zdXBwb3J0IGFuZCBsb29rIGZvciAnVGVjaG5pY2FsIHN1
cHBvcnQKIGVzY2FsYXRpb25zJyBpbiB0aGUgZmVhdHVyZSBsaXN0IHRvIGZpbmQgb3V0IHdo
aWNoIG9uZXMgbGV0IHlvdQogZG8gdGhhdC4KCgwKBQYAAgUBEgNtBhIKDAoFBgACBQISA20T
JgoMCgUGAAIFAxIDbTE1Cg0KBQYAAgUEEgRuBHUGChEKCQYAAgUEsMq8IhIEbgR1BgoeCgQG
AAIGEgV5AoIBAxoPIENsb3NlIGEgY2FzZS4KCgwKBQYAAgYBEgN5Bg8KDAoFBgACBgISA3kQ
IAoMCgUGAAIGAxIDeSsvCg4KBQYAAgYEEgV6BIEBBgoSCgkGAAIGBLDKvCISBXoEgQEGCowE
CgQGAAIHEgaOAQKTAQMa+wMgUmV0cmlldmUgdmFsaWQgY2xhc3NpZmljYXRpb25zIHRvIHVz
ZSB3aGVuIGNyZWF0aW5nIGEgc3VwcG9ydCBjYXNlLgoKIENsYXNzaWZpY2F0aW9ucyBhcmUg
aGllcmFyY2hpY2FsLiBFYWNoIGNsYXNzaWZpY2F0aW9uIGlzIGEgc3RyaW5nCiBjb250YWlu
aW5nIGFsbCBsZXZlbHMgb2YgdGhlIGhpZXJhcmNoeSBzZXBhcmF0ZWQgYnkgYCIgPiAiYC4g
Rm9yIGV4YW1wbGUsCiBgIlRlY2huaWNhbCBJc3N1ZSA+IENvbXB1dGUgPiBDb21wdXRlIEVu
Z2luZSJgLgoKIENsYXNzaWZpY2F0aW9uIElEcyByZXR1cm5lZCBieSB0aGlzIGVuZHBvaW50
IGFyZSB2YWxpZCBmb3IgYXQgbGVhc3Qgc2l4CiBtb250aHMuIFdoZW4gYSBjbGFzc2lmaWNh
dGlvbiBpcyBkZWFjdGl2YXRlZCwgdGhpcyBlbmRwb2ludCBpbW1lZGlhdGVseQogc3RvcHMg
cmV0dXJuaW5nIGl0LiBBZnRlciBzaXggbW9udGhzLCBgY2FzZS5jcmVhdGVgIHJlcXVlc3Rz
IHVzaW5nIHRoZQogY2xhc3NpZmljYXRpb24gd2lsbCBmYWlsLgoKDQoFBgACBwESBI4BBh8K
DQoFBgACBwISBI4BIEAKDQoFBgACBwMSBI8BDzAKDwoFBgACBwQSBpABBJIBBgoTCgkGAAIH
BLDKvCISBpABBJIBBgo9CgIEABIGlwEAnwEBGi8gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3Ig
dGhlIEdldENhc2UgZW5kcG9pbnQuCgoLCgMEAAESBJcBCBYKRAoEBAACABIGmQECngEEGjQg
UmVxdWlyZWQuIFRoZSBmdWxsIG5hbWUgb2YgYSBjYXNlIHRvIGJlIHJldHJpZXZlZC4KCg0K
BQQAAgAFEgSZAQIICg0KBQQAAgABEgSZAQkNCg0KBQQAAgADEgSZARARCg8KBQQAAgAIEgaZ
ARKeAQMKEAoIBAACAAicCAASBJoBBCoKEQoHBAACAAifCBIGmwEEnQEFCkAKAgQBEgaiAQCt
AQEaMiBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgQ3JlYXRlQ2FzZSBlbmRwb2ludC4K
CgsKAwQBARIEogEIGQpaCgQEAQIAEgakAQKpAQQaSiBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIHBhcmVudCB1bmRlciB3aGljaCB0aGUgY2FzZSBzaG91bGQgYmUgY3JlYXRlZC4KCg0K
BQQBAgAFEgSkAQIICg0KBQQBAgABEgSkAQkPCg0KBQQBAgADEgSkARITCg8KBQQBAgAIEgak
ARSpAQMKEAoIBAECAAicCAASBKUBBCoKEQoHBAECAAifCBIGpgEEqAEFCjEKBAQBAgESBKwB
AjkaIyBSZXF1aXJlZC4gVGhlIGNhc2UgdG8gYmUgY3JlYXRlZC4KCg0KBQQBAgEGEgSsAQIG
Cg0KBQQBAgEBEgSsAQcLCg0KBQQBAgEDEgSsAQ4PCg0KBQQBAgEIEgSsARA4ChAKCAQBAgEI
nAgAEgSsARE3Cj8KAgQCEgawAQDYAQEaMSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUg
TGlzdENhc2VzIGVuZHBvaW50LgoKCwoDBAIBEgSwAQgYCkUKBAQCAgASBrIBArcBBBo1IFJl
cXVpcmVkLiBUaGUgbmFtZSBvZiBhIHBhcmVudCB0byBsaXN0IGNhc2VzIHVuZGVyLgoKDQoF
BAICAAUSBLIBAggKDQoFBAICAAESBLIBCQ8KDQoFBAICAAMSBLIBEhMKDwoFBAICAAgSBrIB
FLcBAwoQCggEAgIACJwIABIEswEEKgoRCgcEAgIACJ8IEga0AQS2AQUKkwUKBAQCAgESBMwB
AhQahAUgQW4gZXhwcmVzc2lvbiB1c2VkIHRvIGZpbHRlciBjYXNlcy4KCiBJZiBpdCdzIGFu
IGVtcHR5IHN0cmluZywgdGhlbiBubyBmaWx0ZXJpbmcgaGFwcGVucy4gT3RoZXJ3aXNlLCB0
aGUgZW5kcG9pbnQKIHJldHVybnMgdGhlIGNhc2VzIHRoYXQgbWF0Y2ggdGhlIGZpbHRlci4K
CiBFeHByZXNzaW9ucyB1c2UgdGhlIGZvbGxvd2luZyBmaWVsZHMgc2VwYXJhdGVkIGJ5IGBB
TkRgIGFuZCBzcGVjaWZpZWQgd2l0aAogYD1gOgoKIC0gYHN0YXRlYDogQ2FuIGJlIGBPUEVO
YCBvciBgQ0xPU0VEYC4KIC0gYHByaW9yaXR5YDogQ2FuIGJlIGBQMGAsIGBQMWAsIGBQMmAs
IGBQM2AsIG9yIGBQNGAuIFlvdQogY2FuIHNwZWNpZnkgbXVsdGlwbGUgdmFsdWVzIGZvciBw
cmlvcml0eSB1c2luZyB0aGUgYE9SYCBvcGVyYXRvci4gRm9yCiBleGFtcGxlLCBgcHJpb3Jp
dHk9UDEgT1IgcHJpb3JpdHk9UDJgLgogLSBgY3JlYXRvci5lbWFpbGA6IFRoZSBlbWFpbCBh
ZGRyZXNzIG9mIHRoZSBjYXNlIGNyZWF0b3IuCgogRVhBTVBMRVM6CgogLSBgc3RhdGU9Q0xP
U0VEYAogLSBgc3RhdGU9T1BFTiBBTkQgY3JlYXRvci5lbWFpbD0idGVzdGVyQGV4YW1wbGUu
Y29tImAKIC0gYHN0YXRlPU9QRU4gQU5EIChwcmlvcml0eT1QMCBPUiBwcmlvcml0eT1QMSlg
CgoNCgUEAgIBBRIEzAECCAoNCgUEAgIBARIEzAEJDwoNCgUEAgIBAxIEzAESEwpWCgQEAgIC
EgTPAQIWGkggVGhlIG1heGltdW0gbnVtYmVyIG9mIGNhc2VzIGZldGNoZWQgd2l0aCBlYWNo
IHJlcXVlc3QuIERlZmF1bHRzIHRvIDEwLgoKDQoFBAICAgUSBM8BAgcKDQoFBAICAgESBM8B
CBEKDQoFBAICAgMSBM8BFBUKcAoEBAICAxIE0wECGBpiIEEgdG9rZW4gaWRlbnRpZnlpbmcg
dGhlIHBhZ2Ugb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCB0aGUKIGZp
cnN0IHBhZ2UgaXMgcmV0cmlldmVkLgoKDQoFBAICAwUSBNMBAggKDQoFBAICAwESBNMBCRMK
DQoFBAICAwMSBNMBFhcKcQoEBAICBBIE1wECKBpjIFRoZSBwcm9kdWN0IGxpbmUgdG8gcmVx
dWVzdCBjYXNlcyBmb3IuIElmIHVuc3BlY2lmaWVkLCBvbmx5CiBHb29nbGUgQ2xvdWQgY2Fz
ZXMgd2lsbCBiZSByZXR1cm5lZC4KCg0KBQQCAgQEEgTXAQIKCg0KBQQCAgQGEgTXAQsWCg0K
BQQCAgQBEgTXARcjCg0KBQQCAgQDEgTXASYnCkAKAgQDEgbbAQDkAQEaMiBUaGUgcmVzcG9u
c2UgbWVzc2FnZSBmb3IgdGhlIExpc3RDYXNlcyBlbmRwb2ludC4KCgsKAwQDARIE2wEIGQpi
CgQEAwIAEgTeAQIaGlQgVGhlIGxpc3Qgb2YgY2FzZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBw
YXJlbnQgYWZ0ZXIgYW55CiBmaWx0ZXJzIGhhdmUgYmVlbiBhcHBsaWVkLgoKDQoFBAMCAAQS
BN4BAgoKDQoFBAMCAAYSBN4BCw8KDQoFBAMCAAESBN4BEBUKDQoFBAMCAAMSBN4BGBkKvwEK
BAQDAgESBOMBAh0asAEgQSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJl
c3VsdHMuIFNldCB0aGlzIGluIHRoZSBgcGFnZV90b2tlbmAKIGZpZWxkIG9mIHN1YnNlcXVl
bnQgYGNhc2VzLmxpc3RgIHJlcXVlc3RzLiBJZiB1bnNwZWNpZmllZCwgdGhlcmUgYXJlIG5v
CiBtb3JlIHJlc3VsdHMgdG8gcmV0cmlldmUuCgoNCgUEAwIBBRIE4wECCAoNCgUEAwIBARIE
4wEJGAoNCgUEAwIBAxIE4wEbHApBCgIEBBIG5wEApAIBGjMgVGhlIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgdGhlIFNlYXJjaENhc2VzIGVuZHBvaW50LgoKCwoDBAQBEgTnAQgaCkoKBAQEAgAS
BOkBAhQaPCBUaGUgbmFtZSBvZiB0aGUgcGFyZW50IHJlc291cmNlIHRvIHNlYXJjaCBmb3Ig
Y2FzZXMgdW5kZXIuCgoNCgUEBAIABRIE6QECCAoNCgUEBAIAARIE6QEJDwoNCgUEBAIAAxIE
6QESEwqCDwoEBAQCARIEmwICExrzDiBBbiBleHByZXNzaW9uIHVzZWQgdG8gZmlsdGVyIGNh
c2VzLgoKIEV4cHJlc3Npb25zIHVzZSB0aGUgZm9sbG93aW5nIGZpZWxkcyBzZXBhcmF0ZWQg
YnkgYEFORGAgYW5kIHNwZWNpZmllZCB3aXRoCiBgPWA6CgogLSBgc3RhdGVgOiBDYW4gYmUg
YE9QRU5gIG9yIGBDTE9TRURgLgogLSBgcHJpb3JpdHlgOiBDYW4gYmUgYFAwYCwgYFAxYCwg
YFAyYCwgYFAzYCwgb3IgYFA0YC4gWW91CiBjYW4gc3BlY2lmeSBtdWx0aXBsZSB2YWx1ZXMg
Zm9yIHByaW9yaXR5IHVzaW5nIHRoZSBgT1JgIG9wZXJhdG9yLiBGb3IKIGV4YW1wbGUsIGBw
cmlvcml0eT1QMSBPUiBwcmlvcml0eT1QMmAuCiAtIGBjcmVhdG9yLmVtYWlsYDogVGhlIGVt
YWlsIGFkZHJlc3Mgb2YgdGhlIGNhc2UgY3JlYXRvci4KCiBUbyBzZWFyY2ggYWNyb3NzIGBk
aXNwbGF5TmFtZWAsIGBkZXNjcmlwdGlvbmAsIGFuZCBjb21tZW50cywgdXNlIGEgZ2xvYmFs
CiByZXN0cmljdGlvbiB3aXRoIG5vIGtleXdvcmQgb3Igb3BlcmF0b3IuIEZvciBleGFtcGxl
LCBgIm15IHNlYXJjaCJgLgoKIFRvIHNlYXJjaCBvbmx5IGNhc2VzIHVwZGF0ZWQgYWZ0ZXIg
YSBjZXJ0YWluIGRhdGUsIHVzZSBgdXBkYXRlX3RpbWVgCiByZXN0cmljdGVkIHdpdGggdGhh
dCBwYXJ0aWN1bGFyIGRhdGUsIHRpbWUsIGFuZCB0aW1lem9uZSBpbiBJU08gZGF0ZXRpbWUK
IGZvcm1hdC4gRm9yIGV4YW1wbGUsIGB1cGRhdGVfdGltZT4iMjAyMC0wMS0wMVQwMDowMDow
MC0wNTowMCJgLgogYHVwZGF0ZV90aW1lYCBvbmx5IHN1cHBvcnRzIHRoZSBncmVhdGVyIHRo
YW4gb3BlcmF0b3IgKGA+YCkuCgogSWYgeW91IGFyZSB1c2luZyB0aGUgYHYyYCB2ZXJzaW9u
IG9mIHRoZSBBUEksIHlvdSBtdXN0IHNwZWNpZnkgdGhlIGNhc2UKIHBhcmVudCBpbiB0aGUg
YHBhcmVudGAgZmllbGQuIElmIHlvdSBwcm92aWRlIGFuIGVtcHR5IGBxdWVyeWAsIGFsbCBj
YXNlcwogdW5kZXIgdGhlIHBhcmVudCByZXNvdXJjZSB3aWxsIGJlIHJldHVybmVkLgoKIElm
IHlvdSBhcmUgdXNpbmcgdGhlIGB2MmJldGFgIHZlcnNpb24gb2YgdGhlIEFQSSwgeW91IG11
c3Qgc3BlY2lmeSB0aGUgY2FzZQogcGFyZW50IGluIHRoZSBgcXVlcnlgIGZpZWxkIHVzaW5n
IG9uZSBvZiB0aGUgdHdvIGZpZWxkcyBiZWxvdywgd2hpY2ggYXJlCiBvbmx5IGF2YWlsYWJs
ZSBmb3IgYHYyYmV0YWAuIFRoZSBgcGFyZW50YCBmaWVsZCB3aWxsIGJlIGlnbm9yZWQuCgog
LSBgb3JnYW5pemF0aW9uYDogQW4gb3JnYW5pemF0aW9uIG5hbWUgaW4gdGhlIGZvcm0KIGBv
cmdhbml6YXRpb25zLzxvcmdhbml6YXRpb25faWQ+YC4KIC0gYHByb2plY3RgOiBBIHByb2pl
Y3QgbmFtZSBpbiB0aGUgZm9ybSBgcHJvamVjdHMvPHByb2plY3RfaWQ+YC4KCiBFeGFtcGxl
czoKCiBGb3IgYHYyYDoKCiAtIGBzdGF0ZT1DTE9TRURgCiAtIGBzdGF0ZT1PUEVOIEFORCBj
cmVhdG9yLmVtYWlsPSJ0ZXN0ZXJAZXhhbXBsZS5jb20iYAogLSBgc3RhdGU9T1BFTiBBTkQg
KHByaW9yaXR5PVAwIE9SIHByaW9yaXR5PVAxKWAKIC0gYHVwZGF0ZV90aW1lPiIyMDIwLTAx
LTAxVDAwOjAwOjAwLTA1OjAwImAKCiBGb3IgYHYyYmV0YWA6CgogLSBgb3JnYW5pemF0aW9u
PSJvcmdhbml6YXRpb25zLzEyMzQ1Njc4OSJgCiAtIGBwcm9qZWN0PSJwcm9qZWN0cy9teS1w
cm9qZWN0LWlkImAKIC0gYHByb2plY3Q9InByb2plY3RzLzEyMzQ1Njc4OSJgCiAtIGBvcmdh
bml6YXRpb249Im9yZ2FuaXphdGlvbnMvMTIzNDU2Nzg5IiBBTkQgc3RhdGU9Q0xPU0VEYAog
LSBgcHJvamVjdD0icHJvamVjdHMvbXktcHJvamVjdC1pZCIgQU5EIGNyZWF0b3IuZW1haWw9
InRlc3RlckBleGFtcGxlLmNvbSJgCiAtIGBwcm9qZWN0PSJwcm9qZWN0cy9teS1wcm9qZWN0
LWlkIiBBTkQgKHByaW9yaXR5PVAwIE9SIHByaW9yaXR5PVAxKWAKCg0KBQQEAgEFEgSbAgII
Cg0KBQQEAgEBEgSbAgkOCg0KBQQEAgEDEgSbAhESCmQKBAQEAgISBJ8CAhYaViBUaGUgbWF4
aW11bSBudW1iZXIgb2YgY2FzZXMgZmV0Y2hlZCB3aXRoIGVhY2ggcmVxdWVzdC4gVGhlIGRl
ZmF1bHQgcGFnZQogc2l6ZSBpcyAxMC4KCg0KBQQEAgIFEgSfAgIHCg0KBQQEAgIBEgSfAggR
Cg0KBQQEAgIDEgSfAhQVCnAKBAQEAgMSBKMCAhgaYiBBIHRva2VuIGlkZW50aWZ5aW5nIHRo
ZSBwYWdlIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwgdGhlCiBmaXJz
dCBwYWdlIGlzIHJldHJpZXZlZC4KCg0KBQQEAgMFEgSjAgIICg0KBQQEAgMBEgSjAgkTCg0K
BQQEAgMDEgSjAhYXCkIKAgQFEganAgCwAgEaNCBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3Ig
dGhlIFNlYXJjaENhc2VzIGVuZHBvaW50LgoKCwoDBAUBEgSnAggbCmIKBAQFAgASBKoCAhoa
VCBUaGUgbGlzdCBvZiBjYXNlcyBhc3NvY2lhdGVkIHdpdGggdGhlIHBhcmVudCBhZnRlciBh
bnkKIGZpbHRlcnMgaGF2ZSBiZWVuIGFwcGxpZWQuCgoNCgUEBQIABBIEqgICCgoNCgUEBQIA
BhIEqgILDwoNCgUEBQIAARIEqgIQFQoNCgUEBQIAAxIEqgIYGQrBAQoEBAUCARIErwICHRqy
ASBBIHRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4gU2V0IHRo
aXMgaW4gdGhlCiBgcGFnZV90b2tlbmAgZmllbGQgb2Ygc3Vic2VxdWVudCBgY2FzZXMuc2Vh
cmNoYCByZXF1ZXN0cy4gSWYgdW5zcGVjaWZpZWQsCiB0aGVyZSBhcmUgbm8gbW9yZSByZXN1
bHRzIHRvIHJldHJpZXZlLgoKDQoFBAUCAQUSBK8CAggKDQoFBAUCAQESBK8CCRgKDQoFBAUC
AQMSBK8CGxwKQgoCBAYSBrMCAL4CARo0IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBF
c2NhbGF0ZUNhc2UgZW5kcG9pbnQuCgoLCgMEBgESBLMCCBsKQQoEBAYCABIGtQICugIEGjEg
UmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjYXNlIHRvIGJlIGVzY2FsYXRlZC4KCg0KBQQG
AgAFEgS1AgIICg0KBQQGAgABEgS1AgkNCg0KBQQGAgADEgS1AhARCg8KBQQGAgAIEga1AhK6
AgMKEAoIBAYCAAicCAASBLYCBCoKEQoHBAYCAAifCBIGtwIEuQIFClIKBAQGAgESBL0CAhwa
RCBUaGUgZXNjYWxhdGlvbiBpbmZvcm1hdGlvbiB0byBiZSBzZW50IHdpdGggdGhlIGVzY2Fs
YXRpb24gcmVxdWVzdC4KCg0KBQQGAgEGEgS9AgIMCg0KBQQGAgEBEgS9Ag0XCg0KBQQGAgED
EgS9AhobCj8KAgQHEgbBAgDOAgEaMSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgVXBk
YXRlQ2FzZSBlbmRwb2ludAoKCwoDBAcBEgTBAggZCi0KBAQHAgASBMMCAjkaHyBSZXF1aXJl
ZC4gVGhlIGNhc2UgdG8gdXBkYXRlLgoKDQoFBAcCAAYSBMMCAgYKDQoFBAcCAAESBMMCBwsK
DQoFBAcCAAMSBMMCDg8KDQoFBAcCAAgSBMMCEDgKEAoIBAcCAAicCAASBMMCETcK5AMKBAQH
AgESBM0CAiwa1QMgQSBsaXN0IG9mIGF0dHJpYnV0ZXMgb2YgdGhlIGNhc2UgdGhhdCBzaG91
bGQgYmUgdXBkYXRlZC4gU3VwcG9ydGVkIHZhbHVlcwogYXJlIGBwcmlvcml0eWAsIGBkaXNw
bGF5X25hbWVgLCBhbmQgYHN1YnNjcmliZXJfZW1haWxfYWRkcmVzc2VzYC4gSWYgbm8KIGZp
ZWxkcyBhcmUgc3BlY2lmaWVkLCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBhcmUgdXBkYXRlZC4K
CiBCZSBjYXJlZnVsIC0gaWYgeW91IGRvIG5vdCBwcm92aWRlIGEgZmllbGQgbWFzaywgdGhl
biB5b3UgbWlnaHQKIGFjY2lkZW50YWxseSBjbGVhciBzb21lIGZpZWxkcy4gRm9yIGV4YW1w
bGUsIGlmIHlvdSBsZWF2ZSB0aGUgZmllbGQgbWFzawogZW1wdHkgYW5kIGRvIG5vdCBwcm92
aWRlIGEgdmFsdWUgZm9yIGBzdWJzY3JpYmVyX2VtYWlsX2FkZHJlc3Nlc2AsIHRoZW4KIGBz
dWJzY3JpYmVyX2VtYWlsX2FkZHJlc3Nlc2AgaXMgdXBkYXRlZCB0byBlbXB0eS4KCg0KBQQH
AgEGEgTNAgIbCg0KBQQHAgEBEgTNAhwnCg0KBQQHAgEDEgTNAiorCj8KAgQIEgbRAgDZAgEa
MSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgQ2xvc2VDYXNlIGVuZHBvaW50LgoKCwoD
BAgBEgTRAggYCjoKBAQIAgASBtMCAtgCBBoqIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
Y2FzZSB0byBjbG9zZS4KCg0KBQQIAgAFEgTTAgIICg0KBQQIAgABEgTTAgkNCg0KBQQIAgAD
EgTTAhARCg8KBQQIAgAIEgbTAhLYAgMKEAoIBAgCAAicCAASBNQCBCoKEQoHBAgCAAifCBIG
1QIE1wIFCk8KAgQJEgbcAgDsAgEaQSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgU2Vh
cmNoQ2FzZUNsYXNzaWZpY2F0aW9ucyBlbmRwb2ludC4KCgsKAwQJARIE3AIIKArCAQoEBAkC
ABIE4QICExqzASBBbiBleHByZXNzaW9uIHVzZWQgdG8gZmlsdGVyIGNhc2UgY2xhc3NpZmlj
YXRpb25zLgoKIElmIGl0J3MgYW4gZW1wdHkgc3RyaW5nLCB0aGVuIG5vIGZpbHRlcmluZyBo
YXBwZW5zLiBPdGhlcndpc2UsIGNhc2UKIGNsYXNzaWZpY2F0aW9ucyB3aWxsIGJlIHJldHVy
bmVkIHRoYXQgbWF0Y2ggdGhlIGZpbHRlci4KCg0KBQQJAgAFEgThAgIICg0KBQQJAgABEgTh
AgkOCg0KBQQJAgADEgThAhESClAKBAQJAgESBOQCAhYaQiBUaGUgbWF4aW11bSBudW1iZXIg
b2YgY2xhc3NpZmljYXRpb25zIGZldGNoZWQgd2l0aCBlYWNoIHJlcXVlc3QuCgoNCgUECQIB
BRIE5AICBwoNCgUECQIBARIE5AIIEQoNCgUECQIBAxIE5AIUFQpwCgQECQICEgToAgIYGmIg
QSB0b2tlbiBpZGVudGlmeWluZyB0aGUgcGFnZSBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYg
dW5zcGVjaWZpZWQsIHRoZQogZmlyc3QgcGFnZSBpcyByZXRyaWV2ZWQuCgoNCgUECQICBRIE
6AICCAoNCgUECQICARIE6AIJEwoNCgUECQICAxIE6AIWFwpJCgQECQIDEgTrAgI/GjsgT3B0
aW9uYWwuIFRoZSBwcm9kdWN0IHRvIHJldHVybiBjYXNlIGNsYXNzaWZpY2F0aW9ucyBmb3Iu
CgoNCgUECQIDBhIE6wICCQoNCgUECQIDARIE6wIKEQoNCgUECQIDAxIE6wIUFQoNCgUECQID
CBIE6wIWPgoQCggECQIDCJwIABIE6wIXPQpMCgIEChIG7wIA9wIBGj4gVGhlIHJlc3BvbnNl
IG1lc3NhZ2UgZm9yIFNlYXJjaENhc2VDbGFzc2lmaWNhdGlvbnMgZW5kcG9pbnQuCgoLCgME
CgESBO8CCCkKLgoEBAoCABIE8QICNxogIFRoZSBjbGFzc2lmaWNhdGlvbnMgcmV0cmlldmVk
LgoKDQoFBAoCAAQSBPECAgoKDQoFBAoCAAYSBPECCx0KDQoFBAoCAAESBPECHjIKDQoFBAoC
AAMSBPECNTYKzQEKBAQKAgESBPYCAh0avgEgQSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlIG9mIHJlc3VsdHMuIFNldCB0aGlzIGluIHRoZSBgcGFnZV90b2tlbmAKIGZpZWxk
IG9mIHN1YnNlcXVlbnQgYGNhc2VDbGFzc2lmaWNhdGlvbnMubGlzdGAgcmVxdWVzdHMuIElm
IHVuc3BlY2lmaWVkLAogdGhlcmUgYXJlIG5vIG1vcmUgcmVzdWx0cyB0byByZXRyaWV2ZS4K
Cg0KBQQKAgEFEgT2AgIICg0KBQQKAgEBEgT2AgkYCg0KBQQKAgEDEgT2AhscYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::CaseService::GetCaseRequest ===
    # Fields for GetCaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CaseService::CreateCaseRequest ===
    # Fields for CreateCaseRequest
    # Field: parent Type: 9 ()
    # Field: case Type: 11 (.google.cloud.support.v2beta.Case)

# === Message: Google::Cloud::Support::V2beta::CaseService::ListCasesRequest ===
    # Fields for ListCasesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: product_line Type: 14 (.google.cloud.support.v2beta.ProductLine)

# === Message: Google::Cloud::Support::V2beta::CaseService::ListCasesResponse ===
    # Fields for ListCasesResponse
    # Field: cases Type: 11 (.google.cloud.support.v2beta.Case)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CaseService::SearchCasesRequest ===
    # Fields for SearchCasesRequest
    # Field: parent Type: 9 ()
    # Field: query Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CaseService::SearchCasesResponse ===
    # Fields for SearchCasesResponse
    # Field: cases Type: 11 (.google.cloud.support.v2beta.Case)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CaseService::EscalateCaseRequest ===
    # Fields for EscalateCaseRequest
    # Field: name Type: 9 ()
    # Field: escalation Type: 11 (.google.cloud.support.v2beta.Escalation)

# === Message: Google::Cloud::Support::V2beta::CaseService::UpdateCaseRequest ===
    # Fields for UpdateCaseRequest
    # Field: case Type: 11 (.google.cloud.support.v2beta.Case)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Support::V2beta::CaseService::CloseCaseRequest ===
    # Fields for CloseCaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest ===
    # Fields for SearchCaseClassificationsRequest
    # Field: query Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: product Type: 11 (.google.cloud.support.v2beta.Product)

# === Message: Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse ===
    # Fields for SearchCaseClassificationsResponse
    # Field: case_classifications Type: 11 (.google.cloud.support.v2beta.CaseClassification)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Support::V2beta::CaseService::CaseServiceClient ===
package Google::Cloud::Support::V2beta::CaseService::CaseServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2beta::CaseService::CaseServiceClient

Client stub representing the remote C<CaseService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<support.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'support.googleapis.com:443' );

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

sub get_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::GetCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'GetCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Case::Case',
    });
}

sub list_cases {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::ListCasesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'ListCases',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::CaseService::ListCasesResponse',
    });
}

sub search_cases {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::SearchCasesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'SearchCases',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::CaseService::SearchCasesResponse',
    });
}

sub create_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::CreateCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'CreateCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Case::Case',
    });
}

sub update_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::UpdateCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'UpdateCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Case::Case',
    });
}

sub escalate_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::EscalateCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'EscalateCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Case::Case',
    });
}

sub close_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::CloseCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'CloseCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Case::Case',
    });
}

sub search_case_classifications {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'SearchCaseClassifications',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::CaseService - Compiled Protocol Buffers messages for google/cloud/support/v2beta/case_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::CaseService;

    my $msg = Google::Cloud::Support::V2beta::CaseService::GetCaseRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::CaseService::GetCaseRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/case_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::CaseService::GetCaseRequest

The request message for the GetCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full name of a case to be retrieved.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::CreateCaseRequest

The request message for the CreateCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent under which the case should be created.

=item * C<< $msg->case() >> / C<< $msg->case($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::Case>)

Required. The case to be created.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::ListCasesRequest

The request message for the ListCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of a parent to list cases under.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An expression used to filter cases.

If it's an empty string, then no filtering happens. Otherwise, the endpoint
returns the cases that match the filter.

Expressions use the following fields separated by `AND` and specified with
`=`:

- `state`: Can be `OPEN` or `CLOSED`.
- `priority`: Can be `P0`, `P1`, `P2`, `P3`, or `P4`. You
can specify multiple values for priority using the `OR` operator. For
example, `priority=P1 OR priority=P2`.
- `creator.email`: The email address of the case creator.

EXAMPLES:

- `state=CLOSED`
- `state=OPEN AND creator.email="tester@example.com"`
- `state=OPEN AND (priority=P0 OR priority=P1)`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of cases fetched with each request. Defaults to 10.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=item * C<< $msg->product_line() >> / C<< $msg->product_line($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::ProductLine>)

The product line to request cases for. If unspecified, only
Google Cloud cases will be returned.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::ListCasesResponse

The response message for the ListCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cases() >> / C<< $msg->cases($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::Case>)

The list of cases associated with the parent after any
filters have been applied.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `cases.list` requests. If unspecified, there are no
more results to retrieve.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::SearchCasesRequest

The request message for the SearchCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource to search for cases under.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

An expression used to filter cases.

Expressions use the following fields separated by `AND` and specified with
`=`:

- `state`: Can be `OPEN` or `CLOSED`.
- `priority`: Can be `P0`, `P1`, `P2`, `P3`, or `P4`. You
can specify multiple values for priority using the `OR` operator. For
example, `priority=P1 OR priority=P2`.
- `creator.email`: The email address of the case creator.

To search across `displayName`, `description`, and comments, use a global
restriction with no keyword or operator. For example, `"my search"`.

To search only cases updated after a certain date, use `update_time`
restricted with that particular date, time, and timezone in ISO datetime
format. For example, `update_time>"2020-01-01T00:00:00-05:00"`.
`update_time` only supports the greater than operator (`>`).

If you are using the `v2` version of the API, you must specify the case
parent in the `parent` field. If you provide an empty `query`, all cases
under the parent resource will be returned.

If you are using the `v2beta` version of the API, you must specify the case
parent in the `query` field using one of the two fields below, which are
only available for `v2beta`. The `parent` field will be ignored.

- `organization`: An organization name in the form
`organizations/<organization_id>`.
- `project`: A project name in the form `projects/<project_id>`.

Examples:

For `v2`:

- `state=CLOSED`
- `state=OPEN AND creator.email="tester@example.com"`
- `state=OPEN AND (priority=P0 OR priority=P1)`
- `update_time>"2020-01-01T00:00:00-05:00"`

For `v2beta`:

- `organization="organizations/123456789"`
- `project="projects/my-project-id"`
- `project="projects/123456789"`
- `organization="organizations/123456789" AND state=CLOSED`
- `project="projects/my-project-id" AND creator.email="tester@example.com"`
- `project="projects/my-project-id" AND (priority=P0 OR priority=P1)`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of cases fetched with each request. The default page
size is 10.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::SearchCasesResponse

The response message for the SearchCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cases() >> / C<< $msg->cases($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::Case>)

The list of cases associated with the parent after any
filters have been applied.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the
`page_token` field of subsequent `cases.search` requests. If unspecified,
there are no more results to retrieve.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::EscalateCaseRequest

The request message for the EscalateCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the case to be escalated.

=item * C<< $msg->escalation() >> / C<< $msg->escalation($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Escalation::Escalation>)

The escalation information to be sent with the escalation request.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::UpdateCaseRequest

The request message for the UpdateCase endpoint

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->case() >> / C<< $msg->case($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::Case>)

Required. The case to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A list of attributes of the case that should be updated. Supported values
are `priority`, `display_name`, and `subscriber_email_addresses`. If no
fields are specified, all supported fields are updated.

Be careful - if you do not provide a field mask, then you might
accidentally clear some fields. For example, if you leave the field mask
empty and do not provide a value for `subscriber_email_addresses`, then
`subscriber_email_addresses` is updated to empty.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::CloseCaseRequest

The request message for the CloseCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the case to close.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest

The request message for the SearchCaseClassifications endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

An expression used to filter case classifications.

If it's an empty string, then no filtering happens. Otherwise, case
classifications will be returned that match the filter.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of classifications fetched with each request.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::Product>)

Optional. The product to return case classifications for.

=back

=head2 Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse

The response message for SearchCaseClassifications endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->case_classifications() >> / C<< $msg->case_classifications($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Case::CaseClassification>)

The classifications retrieved.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `caseClassifications.list` requests. If unspecified,
there are no more results to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::CaseService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
