package Google::Cloud::Ids::V1::Ids;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ch1nb29nbGUvY2xvdWQvaWRzL3YxL2lkcy5wcm90bxITZ29vZ2xlLmNsb3VkLmlkcy52MRoc
Z29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8a
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIoQHCghFbmRwb2ludBIXCgRuYW1lGAEgASgJQgPgQQNS
BG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQQoGbGFiZWxzGAQgAygLMikuZ29vZ2xl
LmNsb3VkLmlkcy52MS5FbmRwb2ludC5MYWJlbHNFbnRyeVIGbGFiZWxzEh0KB25ldHdvcmsY
BSABKAlCA+BBAlIHbmV0d29yaxI9ChhlbmRwb2ludF9mb3J3YXJkaW5nX3J1bGUYBiABKAlC
A+BBA1IWZW5kcG9pbnRGb3J3YXJkaW5nUnVsZRIkCgtlbmRwb2ludF9pcBgHIAEoCUID4EED
UgplbmRwb2ludElwEiAKC2Rlc2NyaXB0aW9uGAggASgJUgtkZXNjcmlwdGlvbhJHCghzZXZl
cml0eRgJIAEoDjImLmdvb2dsZS5jbG91ZC5pZHMudjEuRW5kcG9pbnQuU2V2ZXJpdHlCA+BB
AlIIc2V2ZXJpdHkSPgoFc3RhdGUYDCABKA4yIy5nb29nbGUuY2xvdWQuaWRzLnYxLkVuZHBv
aW50LlN0YXRlQgPgQQNSBXN0YXRlEiEKDHRyYWZmaWNfbG9ncxgNIAEoCFILdHJhZmZpY0xv
Z3MaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZh
bHVlOgI4ASJkCghTZXZlcml0eRIYChRTRVZFUklUWV9VTlNQRUNJRklFRBAAEhEKDUlORk9S
TUFUSU9OQUwQARIHCgNMT1cQAhIKCgZNRURJVU0QAxIICgRISUdIEAQSDAoIQ1JJVElDQUwQ
BSJFCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCQoFUkVB
RFkQAhIMCghERUxFVElORxADOl7qQVsKG2lkcy5nb29nbGVhcGlzLmNvbS9FbmRwb2ludBI8
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2VuZHBvaW50cy97ZW5k
cG9pbnR9ItYBChRMaXN0RW5kcG9pbnRzUmVxdWVzdBI7CgZwYXJlbnQYASABKAlCI+BBAvpB
HRIbaWRzLmdvb2dsZWFwaXMuY29tL0VuZHBvaW50UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIg
ASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2Vu
EhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIH
b3JkZXJCeSKeAQoVTGlzdEVuZHBvaW50c1Jlc3BvbnNlEjsKCWVuZHBvaW50cxgBIAMoCzId
Lmdvb2dsZS5jbG91ZC5pZHMudjEuRW5kcG9pbnRSCWVuZHBvaW50cxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVh
Y2hhYmxlIk0KEkdldEVuZHBvaW50UmVxdWVzdBI3CgRuYW1lGAEgASgJQiPgQQL6QR0KG2lk
cy5nb29nbGVhcGlzLmNvbS9FbmRwb2ludFIEbmFtZSLZAQoVQ3JlYXRlRW5kcG9pbnRSZXF1
ZXN0EjsKBnBhcmVudBgBIAEoCUIj4EEC+kEdEhtpZHMuZ29vZ2xlYXBpcy5jb20vRW5kcG9p
bnRSBnBhcmVudBIkCgtlbmRwb2ludF9pZBgCIAEoCUID4EECUgplbmRwb2ludElkEj4KCGVu
ZHBvaW50GAMgASgLMh0uZ29vZ2xlLmNsb3VkLmlkcy52MS5FbmRwb2ludEID4EECUghlbmRw
b2ludBIdCgpyZXF1ZXN0X2lkGAQgASgJUglyZXF1ZXN0SWQibwoVRGVsZXRlRW5kcG9pbnRS
ZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobaWRzLmdvb2dsZWFwaXMuY29tL0VuZHBv
aW50UgRuYW1lEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJZCLVAgoRT3BlcmF0aW9u
TWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdl
dBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSABKAlCA+BB
A1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgIQgPgQQNS
FXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EEDUgphcGlW
ZXJzaW9uMrIGCgNJRFMSpgEKDUxpc3RFbmRwb2ludHMSKS5nb29nbGUuY2xvdWQuaWRzLnYx
Lkxpc3RFbmRwb2ludHNSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmlkcy52MS5MaXN0RW5kcG9p
bnRzUmVzcG9uc2UiPoLT5JMCLxItL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Kn0vZW5kcG9pbnRz2kEGcGFyZW50EpMBCgtHZXRFbmRwb2ludBInLmdvb2dsZS5jbG91ZC5p
ZHMudjEuR2V0RW5kcG9pbnRSZXF1ZXN0Gh0uZ29vZ2xlLmNsb3VkLmlkcy52MS5FbmRwb2lu
dCI8gtPkkwIvEi0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9lbmRwb2ludHMv
Kn3aQQRuYW1lEtoBCg5DcmVhdGVFbmRwb2ludBIqLmdvb2dsZS5jbG91ZC5pZHMudjEuQ3Jl
YXRlRW5kcG9pbnRSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ9gtPk
kwI5Ii0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9lbmRwb2ludHM6CGVu
ZHBvaW502kEbcGFyZW50LGVuZHBvaW50LGVuZHBvaW50X2lkykEdCghFbmRwb2ludBIRT3Bl
cmF0aW9uTWV0YWRhdGESxgEKDkRlbGV0ZUVuZHBvaW50EiouZ29vZ2xlLmNsb3VkLmlkcy52
MS5EZWxldGVFbmRwb2ludFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
ImmC0+STAi8qLS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2VuZHBvaW50cy8q
fdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIRT3BlcmF0aW9uTWV0YWRhdGEa
RspBEmlkcy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm1CaQoXY29tLmdvb2dsZS5jbG91ZC5pZHMudjFCCElkc1Byb3Rv
UAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vaWRzL2FwaXYxL2lkc3BiO2lkc3Bi6gIWR29vZ2xl
OjpDbG91ZDo6SURTOjpWMUryTAoHEgUOAKcCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJ
CgIDAxIDFQAjCgkKAgMEEgMWAC0KCQoCAwUSAxcAKQoICgEIEgMZAEAKCQoCCAsSAxkAQAoI
CgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbACkKCQoCCAgSAxsAKQoICgEIEgMcADAKCQoC
CAESAxwAMAoICgEIEgMdAC8KCQoCCC0SAx0ALwodCgIGABIEIABMARoRIFRoZSBJRFMgU2Vy
dmljZQoKCgoDBgABEgMgCAsKCgoDBgADEgMhAjoKDAoFBgADmQgSAyECOgoKCgMGAAMSAyIC
VgoMCgUGAAOaCBIDIgJWCkAKBAYAAgASBCUCKgMaMiBMaXN0cyBFbmRwb2ludHMgaW4gYSBn
aXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMlBhMKDAoFBgACAAISAyUU
KAoMCgUGAAIAAxIDJTNICg0KBQYAAgAEEgQmBCgGChEKCQYAAgAEsMq8IhIEJgQoBgoMCgUG
AAIABBIDKQQ0Cg8KCAYAAgAEmwgAEgMpBDQKMgoEBgACARIELQIyAxokIEdldHMgZGV0YWls
cyBvZiBhIHNpbmdsZSBFbmRwb2ludC4KCgwKBQYAAgEBEgMtBhEKDAoFBgACAQISAy0SJAoM
CgUGAAIBAxIDLS83Cg0KBQYAAgEEEgQuBDAGChEKCQYAAgEEsMq8IhIELgQwBgoMCgUGAAIB
BBIDMQQyCg8KCAYAAgEEmwgAEgMxBDIKRwoEBgACAhIENQI/Axo5IENyZWF0ZXMgYSBuZXcg
RW5kcG9pbnQgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgIBEgM1
BhQKDAoFBgACAgISAzUVKgoMCgUGAAICAxIDNTVRCg0KBQYAAgIEEgQ2BDkGChEKCQYAAgIE
sMq8IhIENgQ5BgoMCgUGAAICBBIDOgRJCg8KCAYAAgIEmwgAEgM6BEkKDQoFBgACAgQSBDsE
PgYKDwoHBgACAgSZCBIEOwQ+BgoqCgQGAAIDEgRCAksDGhwgRGVsZXRlcyBhIHNpbmdsZSBF
bmRwb2ludC4KCgwKBQYAAgMBEgNCBhQKDAoFBgACAwISA0IVKgoMCgUGAAIDAxIDQjVRCg0K
BQYAAgMEEgRDBEUGChEKCQYAAgMEsMq8IhIEQwRFBgoMCgUGAAIDBBIDRgQyCg8KCAYAAgME
mwgAEgNGBDIKDQoFBgACAwQSBEcESgYKDwoHBgACAwSZCBIERwRKBgqHAQoCBAASBVAAmwEB
GnogRW5kcG9pbnQgZGVzY3JpYmVzIGEgc2luZ2xlIElEUyBlbmRwb2ludC4gSXQgZGVmaW5l
cyBhIGZvcndhcmRpbmcgcnVsZSB0bwogd2hpY2ggcGFja2V0cyBjYW4gYmUgc2VudCBmb3Ig
SURTIGluc3BlY3Rpb24uCgoKCgMEAAESA1AIEAoLCgMEAAcSBFECVAQKDQoFBAAHnQgSBFEC
VAQKJwoEBAAEABIEVwJpAxoZIFRocmVhdCBzZXZlcml0eSBsZXZlbHMuCgoMCgUEAAQAARID
VwcPChkKBgQABAACABIDWQQdGgogTm90IHNldC4KCg4KBwQABAACAAESA1kEGAoOCgcEAAQA
AgACEgNZGxwKJgoGBAAEAAIBEgNcBBYaFyBJbmZvcm1hdGlvbmFsIGFsZXJ0cy4KCg4KBwQA
BAACAQESA1wEEQoOCgcEAAQAAgECEgNcFBUKJQoGBAAEAAICEgNfBAwaFiBMb3cgc2V2ZXJp
dHkgYWxlcnRzLgoKDgoHBAAEAAICARIDXwQHCg4KBwQABAACAgISA18KCwooCgYEAAQAAgMS
A2IEDxoZIE1lZGl1bSBzZXZlcml0eSBhbGVydHMuCgoOCgcEAAQAAgMBEgNiBAoKDgoHBAAE
AAIDAhIDYg0OCiYKBgQABAACBBIDZQQNGhcgSGlnaCBzZXZlcml0eSBhbGVydHMuCgoOCgcE
AAQAAgQBEgNlBAgKDgoHBAAEAAIEAhIDZQsMCioKBgQABAACBRIDaAQRGhsgQ3JpdGljYWwg
c2V2ZXJpdHkgYWxlcnRzLgoKDgoHBAAEAAIFARIDaAQMCg4KBwQABAACBQISA2gPEAoeCgQE
AAQBEgRsAngDGhAgRW5kcG9pbnQgc3RhdGUKCgwKBQQABAEBEgNsBwwKGQoGBAAEAQIAEgNu
BBoaCiBOb3Qgc2V0LgoKDgoHBAAEAQIAARIDbgQVCg4KBwQABAECAAISA24YGQofCgYEAAQB
AgESA3EEERoQIEJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQBAgEBEgNxBAwKDgoHBAAEAQIBAhID
cQ8QCi4KBgQABAECAhIDdAQOGh8gQWN0aXZlIGFuZCByZWFkeSBmb3IgdHJhZmZpYy4KCg4K
BwQABAECAgESA3QECQoOCgcEAAQBAgICEgN0DA0KHwoGBAAEAQIDEgN3BBEaECBCZWluZyBk
ZWxldGVkLgoKDgoHBAAEAQIDARIDdwQMCg4KBwQABAECAwISA3cPEAo1CgQEAAIAEgN7Aj4a
KCBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIGVuZHBvaW50LgoKDAoFBAACAAUSA3sC
CAoMCgUEAAIAARIDewkNCgwKBQQAAgADEgN7EBEKDAoFBAACAAgSA3sSPQoPCggEAAIACJwI
ABIDexM8CjYKBAQAAgESA34CWBopIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRlIHRpbWUgdGlt
ZXN0YW1wLgoKDAoFBAACAQYSA34CGwoMCgUEAAIBARIDfhwnCgwKBQQAAgEDEgN+KisKDAoF
BAACAQgSA34sVwoPCggEAAIBCJwIABIDfi1WCjcKBAQAAgISBIEBAlgaKSBPdXRwdXQgb25s
eS4gVGhlIHVwZGF0ZSB0aW1lIHRpbWVzdGFtcC4KCg0KBQQAAgIGEgSBAQIbCg0KBQQAAgIB
EgSBARwnCg0KBQQAAgIDEgSBASorCg0KBQQAAgIIEgSBASxXChAKCAQAAgIInAgAEgSBAS1W
CisKBAQAAgMSBIQBAiEaHSBUaGUgbGFiZWxzIG9mIHRoZSBlbmRwb2ludC4KCg0KBQQAAgMG
EgSEAQIVCg0KBQQAAgMBEgSEARYcCg0KBQQAAgMDEgSEAR8gCmgKBAQAAgQSBIgBAj4aWiBS
ZXF1aXJlZC4gVGhlIGZ1bGx5IHF1YWxpZmllZCBVUkwgb2YgdGhlIG5ldHdvcmsgdG8gd2hp
Y2ggdGhlIElEUyBFbmRwb2ludCBpcwogYXR0YWNoZWQuCgoNCgUEAAIEBRIEiAECCAoNCgUE
AAIEARIEiAEJEAoNCgUEAAIEAxIEiAETFAoNCgUEAAIECBIEiAEVPQoQCggEAAIECJwIABIE
iAEWPApbCgQEAAIFEgSLAQJSGk0gT3V0cHV0IG9ubHkuIFRoZSBmdWxseSBxdWFsaWZpZWQg
VVJMIG9mIHRoZSBlbmRwb2ludCdzIElMQiBGb3J3YXJkaW5nIFJ1bGUuCgoNCgUEAAIFBRIE
iwECCAoNCgUEAAIFARIEiwEJIQoNCgUEAAIFAxIEiwEkJQoNCgUEAAIFCBIEiwEmUQoQCggE
AAIFCJwIABIEiwEnUApGCgQEAAIGEgSOAQJFGjggT3V0cHV0IG9ubHkuIFRoZSBJUCBhZGRy
ZXNzIG9mIHRoZSBJRFMgRW5kcG9pbnQncyBJTEIuCgoNCgUEAAIGBRIEjgECCAoNCgUEAAIG
ARIEjgEJFAoNCgUEAAIGAxIEjgEXGAoNCgUEAAIGCBIEjgEZRAoQCggEAAIGCJwIABIEjgEa
Qwo5CgQEAAIHEgSRAQIZGisgVXNlci1wcm92aWRlZCBkZXNjcmlwdGlvbiBvZiB0aGUgZW5k
cG9pbnQKCg0KBQQAAgcFEgSRAQIICg0KBQQAAgcBEgSRAQkUCg0KBQQAAgcDEgSRARcYClIK
BAQAAggSBJQBAkEaRCBSZXF1aXJlZC4gTG93ZXN0IHRocmVhdCBzZXZlcml0eSB0aGF0IHRo
aXMgZW5kcG9pbnQgd2lsbCBhbGVydCBvbi4KCg0KBQQAAggGEgSUAQIKCg0KBQQAAggBEgSU
AQsTCg0KBQQAAggDEgSUARYXCg0KBQQAAggIEgSUARhAChAKCAQAAggInAgAEgSUARk/CjsK
BAQAAgkSBJcBAj8aLSBPdXRwdXQgb25seS4gQ3VycmVudCBzdGF0ZSBvZiB0aGUgZW5kcG9p
bnQuCgoNCgUEAAIJBhIElwECBwoNCgUEAAIJARIElwEIDQoNCgUEAAIJAxIElwEQEgoNCgUE
AAIJCBIElwETPgoQCggEAAIJCJwIABIElwEUPQpbCgQEAAIKEgSaAQIZGk0gV2hldGhlciB0
aGUgZW5kcG9pbnQgc2hvdWxkIHJlcG9ydCB0cmFmZmljIGxvZ3MgaW4gYWRkaXRpb24gdG8g
dGhyZWF0IGxvZ3MuCgoNCgUEAAIKBRIEmgECBgoNCgUEAAIKARIEmgEHEwoNCgUEAAIKAxIE
mgEWGAoMCgIEARIGnQEAuAEBCgsKAwQBARIEnQEIHApQCgQEAQIAEgafAQKkAQQaQCBSZXF1
aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YgZW5kcG9p
bnRzLgoKDQoFBAECAAUSBJ8BAggKDQoFBAECAAESBJ8BCQ8KDQoFBAECAAMSBJ8BEhMKDwoF
BAECAAgSBp8BFKQBAwoQCggEAQIACJwIABIEoAEEKgoRCgcEAQIACJ8IEgahAQSjAQUKcwoE
BAECARIEqAECPxplIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgZW5kcG9pbnRz
IHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybiBmZXdlcgogdGhhbiB0aGlzIHZh
bHVlLgoKDQoFBAECAQUSBKgBAgcKDQoFBAECAQESBKgBCBEKDQoFBAECAQMSBKgBFBUKDQoF
BAECAQgSBKgBFj4KEAoIBAECAQicCAASBKgBFz0K/QEKBAQBAgISBK8BAkEa7gEgT3B0aW9u
YWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0RW5kcG9p
bnRzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBh
Z2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0
byBgTGlzdEVuZHBvaW50c2AgbXVzdAogbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0
aGUgcGFnZSB0b2tlbi4KCg0KBQQBAgIFEgSvAQIICg0KBQQBAgIBEgSvAQkTCg0KBQQBAgID
EgSvARYXCg0KBQQBAgIIEgSvARhAChAKCAQBAgIInAgAEgSvARk/Cm4KBAQBAgMSBLMBAj0a
YCBPcHRpb25hbC4gVGhlIGZpbHRlciBleHByZXNzaW9uLCBmb2xsb3dpbmcgdGhlIHN5bnRh
eCBvdXRsaW5lZCBpbgogaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xNjAuCgoNCgUEAQIDBRIE
swECCAoNCgUEAQIDARIEswEJDwoNCgUEAQIDAxIEswESEwoNCgUEAQIDCBIEswEUPAoQCggE
AQIDCJwIABIEswEVOwp9CgQEAQIEEgS3AQI/Gm8gT3B0aW9uYWwuIE9uZSBvciBtb3JlIGZp
ZWxkcyB0byBjb21wYXJlIGFuZCB1c2UgdG8gc29ydCB0aGUgb3V0cHV0LgogU2VlIGh0dHBz
Oi8vZ29vZ2xlLmFpcC5kZXYvMTMyI29yZGVyaW5nLgoKDQoFBAECBAUSBLcBAggKDQoFBAEC
BAESBLcBCREKDQoFBAECBAMSBLcBFBUKDQoFBAECBAgSBLcBFj4KEAoIBAECBAicCAASBLcB
Fz0KDAoCBAISBroBAMQBAQoLCgMEAgESBLoBCB0KLwoEBAICABIEvAECIhohIFRoZSBsaXN0
IG9mIGVuZHBvaW50cyByZXNwb25zZS4KCg0KBQQCAgAEEgS8AQIKCg0KBQQCAgAGEgS8AQsT
Cg0KBQQCAgABEgS8ARQdCg0KBQQCAgADEgS8ASAhCpABCgQEAgIBEgTAAQIdGoEBIEEgdG9r
ZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vi
c2VxdWVudCBwYWdlcy4KCg0KBQQCAgEFEgTAAQIICg0KBQQCAgEBEgTAAQkYCg0KBQQCAgED
EgTAARscCjQKBAQCAgISBMMBAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVh
Y2hlZC4KCg0KBQQCAgIEEgTDAQIKCg0KBQQCAgIFEgTDAQsRCg0KBQQCAgIBEgTDARIdCg0K
BQQCAgIDEgTDASAhCgwKAgQDEgbGAQDPAQEKCwoDBAMBEgTGAQgaCokBCgQEAwIAEgbJAQLO
AQQaeSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVuZHBvaW50IHRvIHJldHJpZXZlLgog
Rm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2VuZHBv
aW50cy97ZW5kcG9pbnR9YAoKDQoFBAMCAAUSBMkBAggKDQoFBAMCAAESBMkBCQ0KDQoFBAMC
AAMSBMkBEBEKDwoFBAMCAAgSBskBEs4BAwoQCggEAwIACJwIABIEygEEKgoRCgcEAwIACJ8I
EgbLAQTNAQUKDAoCBAQSBtEBAPMBAQoLCgMEBAESBNEBCB0KMgoEBAQCABIG0wEC2AEEGiIg
UmVxdWlyZWQuIFRoZSBlbmRwb2ludCdzIHBhcmVudC4KCg0KBQQEAgAFEgTTAQIICg0KBQQE
AgABEgTTAQkPCg0KBQQEAgADEgTTARITCg8KBQQEAgAIEgbTARTYAQMKEAoIBAQCAAicCAAS
BNQBBCoKEQoHBAQCAAifCBIG1QEE1wEFCsICCgQEBAIBEgTgAQJCGrMCIFJlcXVpcmVkLiBU
aGUgZW5kcG9pbnQgaWRlbnRpZmllci4gVGhpcyB3aWxsIGJlIHBhcnQgb2YgdGhlIGVuZHBv
aW50J3MKIHJlc291cmNlIG5hbWUuCiBUaGlzIHZhbHVlIG11c3Qgc3RhcnQgd2l0aCBhIGxv
d2VyY2FzZSBsZXR0ZXIgZm9sbG93ZWQgYnkgdXAgdG8gNjIKIGxvd2VyY2FzZSBsZXR0ZXJz
LCBudW1iZXJzLCBvciBoeXBoZW5zLCBhbmQgY2Fubm90IGVuZCB3aXRoIGEgaHlwaGVuLgog
VmFsdWVzIHRoYXQgZG8gbm90IG1hdGNoIHRoaXMgcGF0dGVybiB3aWxsIHRyaWdnZXIgYW4g
SU5WQUxJRF9BUkdVTUVOVAogZXJyb3IuCgoNCgUEBAIBBRIE4AECCAoNCgUEBAIBARIE4AEJ
FAoNCgUEBAIBAxIE4AEXGAoNCgUEBAIBCBIE4AEZQQoQCggEBAIBCJwIABIE4AEaQAoxCgQE
BAICEgTjAQJBGiMgUmVxdWlyZWQuIFRoZSBlbmRwb2ludCB0byBjcmVhdGUuCgoNCgUEBAIC
BhIE4wECCgoNCgUEBAICARIE4wELEwoNCgUEBAICAxIE4wEWFwoNCgUEBAICCBIE4wEYQAoQ
CggEBAICCJwIABIE4wEZPwqGBgoEBAQCAxIE8gECGBr3BSBBbiBvcHRpb25hbCByZXF1ZXN0
IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQK
IHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdp
bGwga25vdyB0byBpZ25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4g
Y29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0aGF0IGZvciBhdCBsZWFz
dCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBj
b25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3Qg
YW5kIHQKIGhlIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBh
Z2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBp
ZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVj
ZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlz
IHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0
ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3
aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAw
MDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBAIDBRIE8gECCAoN
CgUEBAIDARIE8gEJEwoNCgUEBAIDAxIE8gEWFwoMCgIEBRIG9QEAjAIBCgsKAwQFARIE9QEI
HQo/CgQEBQIAEgb3AQL8AQQaLyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVuZHBvaW50
IHRvIGRlbGV0ZS4KCg0KBQQFAgAFEgT3AQIICg0KBQQFAgABEgT3AQkNCg0KBQQFAgADEgT3
ARARCg8KBQQFAgAIEgb3ARL8AQMKEAoIBAUCAAicCAASBPgBBCoKEQoHBAUCAAifCBIG+QEE
+wEFCoYGCgQEBQIBEgSLAgIYGvcFIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRp
ZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUgcmVxdWVzdCBJRAogc28gdGhhdCBpZiB5
b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvIGln
bm9yZQogdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRo
ZSBzZXJ2ZXIgd2lsbCBndWFyYW50ZWUKIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMg
YWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0
dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdAogaGUgcmVx
dWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhl
IHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9w
ZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlm
IHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNs
aWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRz
LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2Vw
dGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0w
MDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQFAgEFEgSLAgIICg0KBQQFAgEBEgSLAgkT
Cg0KBQQFAgEDEgSLAhYXCkYKAgQGEgaPAgCnAgEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0
YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgsKAwQGARIEjwIIGQpACgQEBgIA
EgSRAgJYGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0
ZWQuCgoNCgUEBgIABhIEkQICGwoNCgUEBgIAARIEkQIcJwoNCgUEBgIAAxIEkQIqKwoNCgUE
BgIACBIEkQIsVwoQCggEBgIACJwIABIEkQItVgpFCgQEBgIBEgSUAgJVGjcgT3V0cHV0IG9u
bHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCg0KBQQGAgEG
EgSUAgIbCg0KBQQGAgEBEgSUAhwkCg0KBQQGAgEDEgSUAicoCg0KBQQGAgEIEgSUAilUChAK
CAQGAgEInAgAEgSUAipTCloKBAQGAgISBJcCAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRl
ZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoK
DQoFBAYCAgUSBJcCAggKDQoFBAYCAgESBJcCCQ8KDQoFBAYCAgMSBJcCEhMKDQoFBAYCAggS
BJcCFD8KEAoIBAYCAgicCAASBJcCFT4KSAoEBAYCAxIEmgICPho6IE91dHB1dCBvbmx5LiBO
YW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoNCgUEBgIDBRIE
mgICCAoNCgUEBgIDARIEmgIJDQoNCgUEBgIDAxIEmgIQEQoNCgUEBgIDCBIEmgISPQoQCggE
BgIDCJwIABIEmgITPApMCgQEBgIEEgSdAgJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRh
YmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoNCgUEBgIEBRIEnQICCAoN
CgUEBgIEARIEnQIJFwoNCgUEBgIEAxIEnQIaGwoNCgUEBgIECBIEnQIcRwoQCggEBgIECJwI
ABIEnQIdRgqaAgoEBAYCBRIEowICThqLAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0
aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0
aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQK
IGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3Rh
dHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25kaW5n
IHRvIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUEBgIFBRIEowICBgoNCgUEBgIFARIEowIHHQoN
CgUEBgIFAxIEowIgIQoNCgUEBgIFCBIEowIiTQoQCggEBgIFCJwIABIEowIjTApFCgQEBgIG
EgSmAgJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9w
ZXJhdGlvbi4KCg0KBQQGAgYFEgSmAgIICg0KBQQGAgYBEgSmAgkUCg0KBQQGAgYDEgSmAhcY
Cg0KBQQGAgYIEgSmAhlEChAKCAQGAgYInAgAEgSmAhpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ids::V1::Ids::Endpoint ===
    # Fields for Endpoint
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.ids.v1.Endpoint.LabelsEntry)
    # Field: network Type: 9 ()
    # Field: endpoint_forwarding_rule Type: 9 ()
    # Field: endpoint_ip Type: 9 ()
    # Field: description Type: 9 ()
    # Field: severity Type: 14 (.google.cloud.ids.v1.Endpoint.Severity)
    # Field: state Type: 14 (.google.cloud.ids.v1.Endpoint.State)
    # Field: traffic_logs Type: 8 ()

# Enum: Endpoint::Severity
our $Endpoint_SEVERITY_UNSPECIFIED = 0;
our $Endpoint_INFORMATIONAL = 1;
our $Endpoint_LOW = 2;
our $Endpoint_MEDIUM = 3;
our $Endpoint_HIGH = 4;
our $Endpoint_CRITICAL = 5;

# Enum: Endpoint::State
our $Endpoint_STATE_UNSPECIFIED = 0;
our $Endpoint_CREATING = 1;
our $Endpoint_READY = 2;
our $Endpoint_DELETING = 3;

# === Message: Google::Cloud::Ids::V1::Ids::ListEndpointsRequest ===
    # Fields for ListEndpointsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Ids::V1::Ids::ListEndpointsResponse ===
    # Fields for ListEndpointsResponse
    # Field: endpoints Type: 11 (.google.cloud.ids.v1.Endpoint)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Ids::V1::Ids::GetEndpointRequest ===
    # Fields for GetEndpointRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Ids::V1::Ids::CreateEndpointRequest ===
    # Fields for CreateEndpointRequest
    # Field: parent Type: 9 ()
    # Field: endpoint_id Type: 9 ()
    # Field: endpoint Type: 11 (.google.cloud.ids.v1.Endpoint)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Ids::V1::Ids::DeleteEndpointRequest ===
    # Fields for DeleteEndpointRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Ids::V1::Ids::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Ids::V1::Ids::IDSClient ===
package Google::Cloud::Ids::V1::Ids::IDSClient;

=pod

=head2 Service Client: Google::Cloud::Ids::V1::Ids::IDSClient

Client stub representing the remote C<IDS> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ids.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ids.googleapis.com:443' );

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

sub list_endpoints {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ids::V1::Ids::ListEndpointsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ids.v1.IDS',
        method         => 'ListEndpoints',
        request        => $req,
        response_class => 'Google::Cloud::Ids::V1::Ids::ListEndpointsResponse',
    });
}

sub get_endpoint {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ids::V1::Ids::GetEndpointRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ids.v1.IDS',
        method         => 'GetEndpoint',
        request        => $req,
        response_class => 'Google::Cloud::Ids::V1::Ids::Endpoint',
    });
}

sub create_endpoint {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ids::V1::Ids::CreateEndpointRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ids.v1.IDS',
        method         => 'CreateEndpoint',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_endpoint {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ids::V1::Ids::DeleteEndpointRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ids.v1.IDS',
        method         => 'DeleteEndpoint',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ids::V1::Ids - Compiled Protocol Buffers messages for google/cloud/ids/v1/ids.proto

=head1 SYNOPSIS

    use Google::Cloud::Ids::V1::Ids;

    my $msg = Google::Cloud::Ids::V1::Ids::Endpoint->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ids::V1::Ids::Endpoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ids/v1/ids.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ids::V1::Ids::Endpoint

Endpoint describes a single IDS endpoint. It defines a forwarding rule to
which packets can be sent for IDS inspection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the endpoint.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create time timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update time timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Ids::V1::Ids::Endpoint::LabelsEntry>)

The labels of the endpoint.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Required. The fully qualified URL of the network to which the IDS Endpoint is
attached.

=item * C<< $msg->endpoint_forwarding_rule() >> / C<< $msg->endpoint_forwarding_rule($value) >>

Type: C<String>

Output only. The fully qualified URL of the endpoint's ILB Forwarding Rule.

=item * C<< $msg->endpoint_ip() >> / C<< $msg->endpoint_ip($value) >>

Type: C<String>

Output only. The IP address of the IDS Endpoint's ILB.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User-provided description of the endpoint

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Ids::V1::Endpoint::Severity>)

Required. Lowest threat severity that this endpoint will alert on.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Ids::V1::Endpoint::State>)

Output only. Current state of the endpoint.

=item * C<< $msg->traffic_logs() >> / C<< $msg->traffic_logs($value) >>

Type: C<Bool>

Whether the endpoint should report traffic logs in addition to threat logs.

=back

=head3 Enum: Endpoint::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<INFORMATIONAL> => C<1>

=item * C<LOW> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<HIGH> => C<4>

=item * C<CRITICAL> => C<5>

=back

=head3 Enum: Endpoint::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=back

=head2 Google::Cloud::Ids::V1::Ids::ListEndpointsRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of endpoints.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of endpoints to return. The service may return fewer
than this value.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListEndpoints` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListEndpoints` must
match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter expression, following the syntax outlined in
https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. One or more fields to compare and use to sort the output.
See https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Ids::V1::Ids::ListEndpointsResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoints() >> / C<< $msg->endpoints($value) >>

Type: C<Message> (L<Google::Cloud::Ids::V1::Ids::Endpoint>)

The list of endpoints response.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Ids::V1::Ids::GetEndpointRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the endpoint to retrieve.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`

=back

=head2 Google::Cloud::Ids::V1::Ids::CreateEndpointRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The endpoint's parent.

=item * C<< $msg->endpoint_id() >> / C<< $msg->endpoint_id($value) >>

Type: C<String>

Required. The endpoint identifier. This will be part of the endpoint's
resource name.
This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, or hyphens, and cannot end with a hyphen.
Values that do not match this pattern will trigger an INVALID_ARGUMENT
error.

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<Message> (L<Google::Cloud::Ids::V1::Ids::Endpoint>)

Required. The endpoint to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and t
he request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Ids::V1::Ids::DeleteEndpointRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the endpoint to delete.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and t
he request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Ids::V1::Ids::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ids::V1::Ids::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
