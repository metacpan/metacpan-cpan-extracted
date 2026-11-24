package Google::Cloud::Oracledatabase::V1::Database;

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
    eval { require Google::Cloud::Oracledatabase::V1::PluggableDatabase };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Dayofweek };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGF0YWJhc2UucHJvdG8SHmdvb2ds
ZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo3Z29vZ2xlL2Nsb3VkL29yYWNsZWRh
dGFiYXNlL3YxL3BsdWdnYWJsZV9kYXRhYmFzZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxobZ29vZ2xlL3R5cGUvZGF5b2Z3ZWVrLnByb3RvIvcKCghEYXRhYmFz
ZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSHAoHZGJfbmFtZRgCIAEoCUID4EEBUgZkYk5h
bWUSKQoOZGJfdW5pcXVlX25hbWUYAyABKAlCA+BBAVIMZGJVbmlxdWVOYW1lEi0KDmFkbWlu
X3Bhc3N3b3JkGAQgASgJQgbgQQHgQQRSDWFkbWluUGFzc3dvcmQSeAodYWRtaW5fcGFzc3dv
cmRfc2VjcmV0X3ZlcnNpb24YESABKAlCNeBBAeBBBPpBLAoqc2VjcmV0bWFuYWdlci5nb29n
bGVhcGlzLmNvbS9TZWNyZXRWZXJzaW9uUhphZG1pblBhc3N3b3JkU2VjcmV0VmVyc2lvbhI2
ChN0ZGVfd2FsbGV0X3Bhc3N3b3JkGAUgASgJQgbgQQHgQQRSEXRkZVdhbGxldFBhc3N3b3Jk
EoEBCiJ0ZGVfd2FsbGV0X3Bhc3N3b3JkX3NlY3JldF92ZXJzaW9uGBIgASgJQjXgQQHgQQT6
QSwKKnNlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lvblIedGRlV2Fs
bGV0UGFzc3dvcmRTZWNyZXRWZXJzaW9uEigKDWNoYXJhY3Rlcl9zZXQYBiABKAlCA+BBAVIM
Y2hhcmFjdGVyU2V0EioKDm5jaGFyYWN0ZXJfc2V0GAcgASgJQgPgQQFSDW5jaGFyYWN0ZXJT
ZXQSHAoHb2NpX3VybBgIIAEoCUID4EEDUgZvY2lVcmwSQAoLY3JlYXRlX3RpbWUYCSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSVwoKcHJvcGVy
dGllcxgKIAEoCzIyLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYXRhYmFzZVBy
b3BlcnRpZXNCA+BBAVIKcHJvcGVydGllcxIkCgtkYXRhYmFzZV9pZBgLIAEoCUID4EEBUgpk
YXRhYmFzZUlkEiUKDGRiX2hvbWVfbmFtZRgMIAEoCUID4EEBUgpkYkhvbWVOYW1lEisKD2dj
cF9vcmFjbGVfem9uZRgNIAEoCUID4EEDUg1nY3BPcmFjbGVab25lEnYKE29wc19pbnNpZ2h0
c19zdGF0dXMYDiABKA4yQS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRGF0YWJh
c2UuT3BlcmF0aW9uc0luc2lnaHRzU3RhdHVzQgPgQQNSEW9wc0luc2lnaHRzU3RhdHVzEjcK
FXBsdWdnYWJsZV9kYXRhYmFzZV9pZBgPIAEoCUID4EEBUhNwbHVnZ2FibGVEYXRhYmFzZUlk
EjsKF3BsdWdnYWJsZV9kYXRhYmFzZV9uYW1lGBAgASgJQgPgQQFSFXBsdWdnYWJsZURhdGFi
YXNlTmFtZSKsAQoYT3BlcmF0aW9uc0luc2lnaHRzU3RhdHVzEioKJk9QRVJBVElPTlNfSU5T
SUdIVFNfU1RBVFVTX1VOU1BFQ0lGSUVEEAASDAoIRU5BQkxJTkcQARILCgdFTkFCTEVEEAIS
DQoJRElTQUJMSU5HEAMSDwoLTk9UX0VOQUJMRUQQBBITCg9GQUlMRURfRU5BQkxJTkcQBRIU
ChBGQUlMRURfRElTQUJMSU5HEAY6fupBewomb3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5j
b20vRGF0YWJhc2USPHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9k
YXRhYmFzZXMve2RhdGFiYXNlfSoJZGF0YWJhc2VzMghkYXRhYmFzZSLmBAoSRGF0YWJhc2VQ
cm9wZXJ0aWVzEmQKBXN0YXRlGAEgASgOMkkuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNl
LnYxLkRhdGFiYXNlUHJvcGVydGllcy5EYXRhYmFzZUxpZmVjeWNsZVN0YXRlQgPgQQNSBXN0
YXRlEiIKCmRiX3ZlcnNpb24YAiABKAlCA+BBAlIJZGJWZXJzaW9uEl0KEGRiX2JhY2t1cF9j
b25maWcYAyABKAsyLi5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRGJCYWNrdXBD
b25maWdCA+BBAVIOZGJCYWNrdXBDb25maWcSewoaZGF0YWJhc2VfbWFuYWdlbWVudF9jb25m
aWcYBCABKAsyOC5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRGF0YWJhc2VNYW5h
Z2VtZW50Q29uZmlnQgPgQQNSGGRhdGFiYXNlTWFuYWdlbWVudENvbmZpZyLpAQoWRGF0YWJh
c2VMaWZlY3ljbGVTdGF0ZRIoCiREQVRBQkFTRV9MSUZFQ1lDTEVfU1RBVEVfVU5TUEVDSUZJ
RUQQABIQCgxQUk9WSVNJT05JTkcQARINCglBVkFJTEFCTEUQAhIMCghVUERBVElORxADEhYK
EkJBQ0tVUF9JTl9QUk9HUkVTUxAEEg0KCVVQR1JBRElORxAFEg4KCkNPTlZFUlRJTkcQBhIP
CgtURVJNSU5BVElORxAHEg4KClRFUk1JTkFURUQQCBISCg5SRVNUT1JFX0ZBSUxFRBAJEgoK
BkZBSUxFRBAKIsIKCg5EYkJhY2t1cENvbmZpZxIzChNhdXRvX2JhY2t1cF9lbmFibGVkGAEg
ASgIQgPgQQFSEWF1dG9CYWNrdXBFbmFibGVkEooBChpiYWNrdXBfZGVzdGluYXRpb25fZGV0
YWlscxgCIAMoCzJHLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYkJhY2t1cENv
bmZpZy5CYWNrdXBEZXN0aW5hdGlvbkRldGFpbHNCA+BBAVIYYmFja3VwRGVzdGluYXRpb25E
ZXRhaWxzEjcKFXJldGVudGlvbl9wZXJpb2RfZGF5cxgDIAEoBUID4EEBUhNyZXRlbnRpb25Q
ZXJpb2REYXlzEn4KFmJhY2t1cF9kZWxldGlvbl9wb2xpY3kYBCABKA4yQy5nb29nbGUuY2xv
dWQub3JhY2xlZGF0YWJhc2UudjEuRGJCYWNrdXBDb25maWcuQmFja3VwRGVsZXRpb25Qb2xp
Y3lCA+BBAVIUYmFja3VwRGVsZXRpb25Qb2xpY3kSTAoUYXV0b19mdWxsX2JhY2t1cF9kYXkY
BSABKA4yFi5nb29nbGUudHlwZS5EYXlPZldlZWtCA+BBAVIRYXV0b0Z1bGxCYWNrdXBEYXkS
dwoXYXV0b19mdWxsX2JhY2t1cF93aW5kb3cYBiABKA4yOy5nb29nbGUuY2xvdWQub3JhY2xl
ZGF0YWJhc2UudjEuRGJCYWNrdXBDb25maWcuQmFja3VwV2luZG93QgPgQQFSFGF1dG9GdWxs
QmFja3VwV2luZG93EoUBCh5hdXRvX2luY3JlbWVudGFsX2JhY2t1cF93aW5kb3cYByABKA4y
Oy5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRGJCYWNrdXBDb25maWcuQmFja3Vw
V2luZG93QgPgQQFSG2F1dG9JbmNyZW1lbnRhbEJhY2t1cFdpbmRvdxp5ChhCYWNrdXBEZXN0
aW5hdGlvbkRldGFpbHMSXQoEdHlwZRgBIAEoDjJELmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRh
YmFzZS52MS5EYkJhY2t1cENvbmZpZy5CYWNrdXBEZXN0aW5hdGlvblR5cGVCA+BBAVIEdHlw
ZSKIAQoVQmFja3VwRGVzdGluYXRpb25UeXBlEicKI0JBQ0tVUF9ERVNUSU5BVElPTl9UWVBF
X1VOU1BFQ0lGSUVEEAASBwoDTkZTEAESFgoSUkVDT1ZFUllfQVBQTElBTkNFEAISEAoMT0JK
RUNUX1NUT1JFEAMSCQoFTE9DQUwQBBIICgREQlJTEAUi5AEKDEJhY2t1cFdpbmRvdxIdChlC
QUNLVVBfV0lORE9XX1VOU1BFQ0lGSUVEEAASDAoIU0xPVF9PTkUQARIMCghTTE9UX1RXTxAC
Eg4KClNMT1RfVEhSRUUQAxINCglTTE9UX0ZPVVIQBBINCglTTE9UX0ZJVkUQBRIMCghTTE9U
X1NJWBAGEg4KClNMT1RfU0VWRU4QBxIOCgpTTE9UX0VJR0hUEAgSDQoJU0xPVF9OSU5FEAkS
DAoIU0xPVF9URU4QChIPCgtTTE9UX0VMRVZFThALEg8KC1NMT1RfVFdFTFZFEAwieQoUQmFj
a3VwRGVsZXRpb25Qb2xpY3kSJgoiQkFDS1VQX0RFTEVUSU9OX1BPTElDWV9VTlNQRUNJRklF
RBAAEhYKEkRFTEVURV9JTU1FRElBVEVMWRABEiEKHURFTEVURV9BRlRFUl9SRVRFTlRJT05f
UEVSSU9EEAIiWAoSR2V0RGF0YWJhc2VSZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpBKAom
b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vRGF0YWJhc2VSBG5hbWUiwQEKFExpc3RE
YXRhYmFzZXNSZXF1ZXN0EkYKBnBhcmVudBgBIAEoCUIu4EEC+kEoEiZvcmFjbGVkYXRhYmFz
ZS5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZVIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID
4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZm
aWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIocBChVMaXN0RGF0YWJhc2VzUmVzcG9uc2USRgoJ
ZGF0YWJhc2VzGAEgAygLMiguZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkRhdGFi
YXNlUglkYXRhYmFzZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
QucBCiJjb20uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxQg1EYXRhYmFzZVByb3Rv
UAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0
YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xlLkNsb3VkLk9yYWNsZURhdGFiYXNl
LlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURhdGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6
T3JhY2xlRGF0YWJhc2U6OlYxSuZnCgcSBQ4A+gIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABB
CgkKAgMDEgMVACkKCQoCAwQSAxYAJQoICgEIEgMYADsKCQoCCCUSAxgAOwoICgEIEgMZAGEK
CQoCCAsSAxkAYQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC4KCQoCCAgSAxsALgoI
CgEIEgMcADsKCQoCCAESAxwAOwoICgEIEgMdADsKCQoCCCkSAx0AOwoICgEIEgMeADoKCQoC
CC0SAx4AOgp5CgIEABIFIgCeAQEabCBEZXRhaWxzIG9mIHRoZSBEYXRhYmFzZSByZXNvdXJj
ZS4KIGh0dHBzOi8vZG9jcy5vcmFjbGUuY29tL2VuLXVzL2lhYXMvYXBpLyMvZW4vZGF0YWJh
c2UvMjAxNjA5MTgvRGF0YWJhc2UvCgoKCgMEAAESAyIIEAoLCgMEAAcSBCMCKAQKDQoFBAAH
nQgSBCMCKAQKRAoEBAAEABIEKwJAAxo2IFRoZSBTdGF0dXMgb2YgT3BlcmF0aW9ucyBJbnNp
Z2h0cyBmb3IgdGhpcyBEYXRhYmFzZS4KCgwKBQQABAABEgMrBx8KKwoGBAAEAAIAEgMtBC8a
HCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAAEAAIAARIDLQQqCg4KBwQABAAC
AAISAy0tLgpKCgYEAAQAAgESAzAEERo7IEluZGljYXRlcyB0aGF0IHRoZSBvcGVyYXRpb25z
IGluc2lnaHRzIGFyZSBiZWluZyBlbmFibGVkLgoKDgoHBAAEAAIBARIDMAQMCg4KBwQABAAC
AQISAzAPEApECgYEAAQAAgISAzMEEBo1IEluZGljYXRlcyB0aGF0IHRoZSBvcGVyYXRpb25z
IGluc2lnaHRzIGFyZSBlbmFibGVkLgoKDgoHBAAEAAICARIDMwQLCg4KBwQABAACAgISAzMO
DwpLCgYEAAQAAgMSAzYEEho8IEluZGljYXRlcyB0aGF0IHRoZSBvcGVyYXRpb25zIGluc2ln
aHRzIGFyZSBiZWluZyBkaXNhYmxlZC4KCg4KBwQABAACAwESAzYEDQoOCgcEAAQAAgMCEgM2
EBEKSAoGBAAEAAIEEgM5BBQaOSBJbmRpY2F0ZXMgdGhhdCB0aGUgb3BlcmF0aW9ucyBpbnNp
Z2h0cyBhcmUgbm90IGVuYWJsZWQuCgoOCgcEAAQAAgQBEgM5BA8KDgoHBAAEAAIEAhIDORIT
CkkKBgQABAACBRIDPAQYGjogSW5kaWNhdGVzIHRoYXQgdGhlIG9wZXJhdGlvbnMgaW5zaWdo
dHMgZmFpbGVkIHRvIGVuYWJsZS4KCg4KBwQABAACBQESAzwEEwoOCgcEAAQAAgUCEgM8FhcK
SgoGBAAEAAIGEgM/BBkaOyBJbmRpY2F0ZXMgdGhhdCB0aGUgb3BlcmF0aW9ucyBpbnNpZ2h0
cyBmYWlsZWQgdG8gZGlzYWJsZS4KCg4KBwQABAACBgESAz8EFAoOCgcEAAQAAgYCEgM/FxgK
kgEKBAQAAgASA0QCPRqEASBJZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0aGUgRGF0YWJhc2Ug
cmVzb3VyY2UgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tyZWdpb259L2RhdGFiYXNlcy97ZGF0YWJhc2V9CgoMCgUEAAIABRIDRAII
CgwKBQQAAgABEgNECQ0KDAoFBAACAAMSA0QQEQoMCgUEAAIACBIDRBI8Cg8KCAQAAgAInAgA
EgNEEzsKwQEKBAQAAgESA0kCPhqzASBPcHRpb25hbC4gVGhlIGRhdGFiYXNlIG5hbWUuIFRo
ZSBuYW1lIG11c3QgYmVnaW4gd2l0aCBhbiBhbHBoYWJldGljCiBjaGFyYWN0ZXIgYW5kIGNh
biBjb250YWluIGEgbWF4aW11bSBvZiBlaWdodCBhbHBoYW51bWVyaWMgY2hhcmFjdGVycy4K
IFNwZWNpYWwgY2hhcmFjdGVycyBhcmUgbm90IHBlcm1pdHRlZC4KCgwKBQQAAgEFEgNJAggK
DAoFBAACAQESA0kJEAoMCgUEAAIBAxIDSRMUCgwKBQQAAgEIEgNJFT0KDwoIBAACAQicCAAS
A0kWPApTCgQEAAICEgNMAkUaRiBPcHRpb25hbC4gVGhlIERCX1VOSVFVRV9OQU1FIG9mIHRo
ZSBPcmFjbGUgRGF0YWJhc2UgYmVpbmcgYmFja2VkIHVwLgoKDAoFBAACAgUSA0wCCAoMCgUE
AAICARIDTAkXCgwKBQQAAgIDEgNMGhsKDAoFBAACAggSA0wcRAoPCggEAAICCJwIABIDTB1D
CqkBCgQEAAIDEgRRAlQEGpoBIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBUaGUgcGFzc3dvcmQg
Zm9yIHRoZSBkZWZhdWx0IEFETUlOIHVzZXIuCiBOb3RlOiBPbmx5IG9uZSBvZiBgYWRtaW5f
cGFzc3dvcmRfc2VjcmV0X3ZlcnNpb25gIG9yIGBhZG1pbl9wYXNzd29yZGAgY2FuCiBiZSBw
b3B1bGF0ZWQuCgoMCgUEAAIDBRIDUQIICgwKBQQAAgMBEgNRCRcKDAoFBAACAwMSA1EaGwoN
CgUEAAIDCBIEURxUAwoPCggEAAIDCJwIABIDUgQqCg8KCAQAAgMInAgBEgNTBCwKrAIKBAQA
AgQSBFoCYAQanQIgT3B0aW9uYWwuIElucHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IGEgc2VjcmV0IHZlcnNpb24gaW4gU2VjcmV0CiBNYW5hZ2VyIHdoaWNoIGNvbnRhaW5zIHRo
ZSBkYXRhYmFzZSBhZG1pbiB1c2VyJ3MgcGFzc3dvcmQuIEZvcm1hdDoKIHByb2plY3RzL3tw
cm9qZWN0fS9zZWNyZXRzL3tzZWNyZXR9L3ZlcnNpb25zL3t2ZXJzaW9ufS4gTm90ZTogT25s
eSBvbmUgb2YKIGBhZG1pbl9wYXNzd29yZF9zZWNyZXRfdmVyc2lvbmAgb3IgYGFkbWluX3Bh
c3N3b3JkYCBjYW4gYmUgcG9wdWxhdGVkLgoKDAoFBAACBAUSA1oCCAoMCgUEAAIEARIDWgkm
CgwKBQQAAgQDEgNaKSsKDQoFBAACBAgSBFosYAMKDwoIBAACBAicCAASA1sEKgoPCggEAAIE
CJwIARIDXAQsCg8KBwQAAgQInwgSBF0EXwUKtAEKBAQAAgUSBGUCaAQapQEgT3B0aW9uYWwu
IElucHV0IG9ubHkuIFRoZSBUREUgd2FsbGV0IHBhc3N3b3JkIGZvciB0aGUgZGF0YWJhc2Uu
CiBOb3RlOiBPbmx5IG9uZSBvZiBgdGRlX3dhbGxldF9wYXNzd29yZF9zZWNyZXRfdmVyc2lv
bmAgb3IKIGB0ZGVfd2FsbGV0X3Bhc3N3b3JkYCBjYW4gYmUgcG9wdWxhdGVkLgoKDAoFBAAC
BQUSA2UCCAoMCgUEAAIFARIDZQkcCgwKBQQAAgUDEgNlHyAKDQoFBAACBQgSBGUhaAMKDwoI
BAACBQicCAASA2YEKgoPCggEAAIFCJwIARIDZwQsCr0CCgQEAAIGEgRvAnUEGq4CIE9wdGlv
bmFsLiBJbnB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiBhIHNlY3JldCB2ZXJzaW9u
IGluIFNlY3JldAogTWFuYWdlciB3aGljaCBjb250YWlucyB0aGUgVERFIHdhbGxldCBwYXNz
d29yZCBmb3IgdGhlIGRhdGFiYXNlLiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vc2Vj
cmV0cy97c2VjcmV0fS92ZXJzaW9ucy97dmVyc2lvbn0uIE5vdGU6IE9ubHkgb25lIG9mCiBg
dGRlX3dhbGxldF9wYXNzd29yZF9zZWNyZXRfdmVyc2lvbmAgb3IgYHRkZV93YWxsZXRfcGFz
c3dvcmRgIGNhbiBiZQogcG9wdWxhdGVkLgoKDAoFBAACBgUSA28CCAoMCgUEAAIGARIDbwkr
CgwKBQQAAgYDEgNvLjAKDQoFBAACBggSBG8xdQMKDwoIBAACBgicCAASA3AEKgoPCggEAAIG
CJwIARIDcQQsCg8KBwQAAgYInwgSBHIEdAUKVQoEBAACBxIDeAJEGkggT3B0aW9uYWwuIFRo
ZSBjaGFyYWN0ZXIgc2V0IGZvciB0aGUgZGF0YWJhc2UuIFRoZSBkZWZhdWx0IGlzIEFMMzJV
VEY4LgoKDAoFBAACBwUSA3gCCAoMCgUEAAIHARIDeAkWCgwKBQQAAgcDEgN4GRoKDAoFBAAC
BwgSA3gbQwoPCggEAAIHCJwIABIDeBxCCmAKBAQAAggSA3wCRRpTIE9wdGlvbmFsLiBUaGUg
bmF0aW9uYWwgY2hhcmFjdGVyIHNldCBmb3IgdGhlIGRhdGFiYXNlLiBUaGUgZGVmYXVsdCBp
cwogQUwxNlVURjE2LgoKDAoFBAACCAUSA3wCCAoMCgUEAAIIARIDfAkXCgwKBQQAAggDEgN8
GhsKDAoFBAACCAgSA3wcRAoPCggEAAIICJwIABIDfB1DCl8KBAQAAgkSBIABAkEaUSBPdXRw
dXQgb25seS4gSFRUUFMgbGluayB0byBPQ0kgcmVzb3VyY2VzIGV4cG9zZWQgdG8gQ3VzdG9t
ZXIgdmlhIFVJCiBJbnRlcmZhY2UuCgoNCgUEAAIJBRIEgAECCAoNCgUEAAIJARIEgAEJEAoN
CgUEAAIJAxIEgAETFAoNCgUEAAIJCBIEgAEVQAoQCggEAAIJCJwIABIEgAEWPwpPCgQEAAIK
EgaDAQKEATIaPyBPdXRwdXQgb25seS4gVGhlIGRhdGUgYW5kIHRpbWUgdGhhdCB0aGUgRGF0
YWJhc2Ugd2FzIGNyZWF0ZWQuCgoNCgUEAAIKBhIEgwECGwoNCgUEAAIKARIEgwEcJwoNCgUE
AAIKAxIEgwEqKwoNCgUEAAIKCBIEhAEGMQoQCggEAAIKCJwIABIEhAEHMAo5CgQEAAILEgSH
AQJOGisgT3B0aW9uYWwuIFRoZSBwcm9wZXJ0aWVzIG9mIHRoZSBEYXRhYmFzZS4KCg0KBQQA
AgsGEgSHAQIUCg0KBQQAAgsBEgSHARUfCg0KBQQAAgsDEgSHASIkCg0KBQQAAgsIEgSHASVN
ChAKCAQAAgsInAgAEgSHASZMCjoKBAQAAgwSBIoBAkMaLCBPcHRpb25hbC4gVGhlIGRhdGFi
YXNlIElEIG9mIHRoZSBEYXRhYmFzZS4KCg0KBQQAAgwFEgSKAQIICg0KBQQAAgwBEgSKAQkU
Cg0KBQQAAgwDEgSKARcZCg0KBQQAAgwIEgSKARpCChAKCAQAAgwInAgAEgSKARtBClcKBAQA
Ag0SBI0BAkQaSSBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIERiSG9tZSByZXNvdXJjZSBh
c3NvY2lhdGVkIHdpdGggdGhlIERhdGFiYXNlLgoKDQoFBAACDQUSBI0BAggKDQoFBAACDQES
BI0BCRUKDQoFBAACDQMSBI0BGBoKDQoFBAACDQgSBI0BG0MKEAoIBAACDQicCAASBI0BHEIK
TwoEBAACDhIEkAECShpBIE91dHB1dCBvbmx5LiBUaGUgR0NQIE9yYWNsZSB6b25lIHdoZXJl
IHRoZSBEYXRhYmFzZSBpcyBjcmVhdGVkLgoKDQoFBAACDgUSBJABAggKDQoFBAACDgESBJAB
CRgKDQoFBAACDgMSBJABGx0KDQoFBAACDggSBJABHkkKEAoIBAACDgicCAASBJABH0gKUwoE
BAACDxIGkwEClAEyGkMgT3V0cHV0IG9ubHkuIFRoZSBTdGF0dXMgb2YgT3BlcmF0aW9ucyBJ
bnNpZ2h0cyBmb3IgdGhpcyBEYXRhYmFzZS4KCg0KBQQAAg8GEgSTAQIaCg0KBQQAAg8BEgST
ARsuCg0KBQQAAg8DEgSTATEzCg0KBQQAAg8IEgSUAQYxChAKCAQAAg8InAgAEgSUAQcwCpEB
CgQEAAIQEgSYAQJNGoIBIE9wdGlvbmFsLiBUaGUgSUQgb2YgdGhlIHBsdWdnYWJsZSBkYXRh
YmFzZSBhc3NvY2lhdGVkIHdpdGggdGhlIERhdGFiYXNlLgogVGhlIElEIG11c3QgYmUgdW5p
cXVlIHdpdGhpbiB0aGUgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoNCgUEAAIQBRIEmAECCAoN
CgUEAAIQARIEmAEJHgoNCgUEAAIQAxIEmAEhIwoNCgUEAAIQCBIEmAEkTAoQCggEAAIQCJwI
ABIEmAElSwq/AQoEBAACERIEnQECTxqwASBPcHRpb25hbC4gVGhlIHBsdWdnYWJsZSBkYXRh
YmFzZSBhc3NvY2lhdGVkIHdpdGggdGhlIERhdGFiYXNlLiBUaGUgbmFtZQogbXVzdCBiZWdp
biB3aXRoIGFuIGFscGhhYmV0aWMgY2hhcmFjdGVyIGFuZCBjYW4gY29udGFpbiBhIG1heGlt
dW0gb2YgdGhpcnR5CiBhbHBoYW51bWVyaWMgY2hhcmFjdGVycy4KCg0KBQQAAhEFEgSdAQII
Cg0KBQQAAhEBEgSdAQkgCg0KBQQAAhEDEgSdASMlCg0KBQQAAhEIEgSdASZOChAKCAQAAhEI
nAgAEgSdASdNCi0KAgQBEgahAQDSAQEaHyBUaGUgcHJvcGVydGllcyBvZiBhIERhdGFiYXNl
LgoKCwoDBAEBEgShAQgaCj8KBAQBBAASBqMBAsQBAxovIFRoZSB2YXJpb3VzIGxpZmVjeWNs
ZSBzdGF0ZXMgb2YgdGhlIERhdGFiYXNlLgoKDQoFBAEEAAESBKMBBx0KLAoGBAEEAAIAEgSl
AQQtGhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg8KBwQBBAACAAESBKUBBCgKDwoH
BAEEAAIAAhIEpQErLApHCgYEAQQAAgESBKgBBBUaNyBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVz
b3VyY2UgaXMgaW4gcHJvdmlzaW9uaW5nIHN0YXRlLgoKDwoHBAEEAAIBARIEqAEEEAoPCgcE
AQQAAgECEgSoARMUCkQKBgQBBAACAhIEqwEEEho0IEluZGljYXRlcyB0aGF0IHRoZSByZXNv
dXJjZSBpcyBpbiBhdmFpbGFibGUgc3RhdGUuCgoPCgcEAQQAAgIBEgSrAQQNCg8KBwQBBAAC
AgISBKsBEBEKQwoGBAEEAAIDEgSuAQQRGjMgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNl
IGlzIGluIHVwZGF0aW5nIHN0YXRlLgoKDwoHBAEEAAIDARIErgEEDAoPCgcEAQQAAgMCEgSu
AQ8QCk0KBgQBBAACBBIEsQEEGxo9IEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBp
biBiYWNrdXAgaW4gcHJvZ3Jlc3Mgc3RhdGUuCgoPCgcEAQQAAgQBEgSxAQQWCg8KBwQBBAAC
BAISBLEBGRoKRAoGBAEEAAIFEgS0AQQSGjQgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNl
IGlzIGluIHVwZ3JhZGluZyBzdGF0ZS4KCg8KBwQBBAACBQESBLQBBA0KDwoHBAEEAAIFAhIE
tAEQEQpFCgYEAQQAAgYSBLcBBBMaNSBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMg
aW4gY29udmVydGluZyBzdGF0ZS4KCg8KBwQBBAACBgESBLcBBA4KDwoHBAEEAAIGAhIEtwER
EgpGCgYEAQQAAgcSBLoBBBQaNiBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4g
dGVybWluYXRpbmcgc3RhdGUuCgoPCgcEAQQAAgcBEgS6AQQPCg8KBwQBBAACBwISBLoBEhMK
RQoGBAEEAAIIEgS9AQQTGjUgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIHRl
cm1pbmF0ZWQgc3RhdGUuCgoPCgcEAQQAAggBEgS9AQQOCg8KBwQBBAACCAISBL0BERIKSQoG
BAEEAAIJEgTAAQQXGjkgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIHJlc3Rv
cmUgZmFpbGVkIHN0YXRlLgoKDwoHBAEEAAIJARIEwAEEEgoPCgcEAQQAAgkCEgTAARUWCkEK
BgQBBAACChIEwwEEEBoxIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBmYWls
ZWQgc3RhdGUuCgoPCgcEAQQAAgoBEgTDAQQKCg8KBwQBBAACCgISBMMBDQ8KMwoEBAECABIE
xwECTxolIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgRGF0YWJhc2UuCgoNCgUEAQIABhIE
xwECGAoNCgUEAQIAARIExwEZHgoNCgUEAQIAAxIExwEhIgoNCgUEAQIACBIExwEjTgoQCggE
AQIACJwIABIExwEkTQo2CgQEAQIBEgTKAQJBGiggUmVxdWlyZWQuIFRoZSBPcmFjbGUgRGF0
YWJhc2UgdmVyc2lvbi4KCg0KBQQBAgEFEgTKAQIICg0KBQQBAgEBEgTKAQkTCg0KBQQBAgED
EgTKARYXCg0KBQQBAgEIEgTKARhAChAKCAQBAgEInAgAEgTKARk/CjoKBAQBAgISBM0BAk8a
LCBPcHRpb25hbC4gQmFja3VwIG9wdGlvbnMgZm9yIHRoZSBEYXRhYmFzZS4KCg0KBQQBAgIG
EgTNAQIQCg0KBQQBAgIBEgTNAREhCg0KBQQBAgIDEgTNASQlCg0KBQQBAgIIEgTNASZOChAK
CAQBAgIInAgAEgTNASdNCj4KBAQBAgMSBtABAtEBMhouIE91dHB1dCBvbmx5LiBUaGUgRGF0
YWJhc2UgTWFuYWdlbWVudCBjb25maWcuCgoNCgUEAQIDBhIE0AECGgoNCgUEAQIDARIE0AEb
NQoNCgUEAQIDAxIE0AE4OQoNCgUEAQIDCBIE0QEGMQoQCggEAQIDCJwIABIE0QEHMAowCgIE
AhIG1QEAyQIBGiIgQmFja3VwIE9wdGlvbnMgZm9yIHRoZSBEYXRhYmFzZS4KCgsKAwQCARIE
1QEIFgpBCgQEAgMAEgbXAQLaAQMaMSBUaGUgZGV0YWlscyBvZiB0aGUgZGF0YWJhc2UgYmFj
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
DwoPCgcEAgQBAgwCEgSYAhIUClsKBAQCBAISBpwCAqcCAxpLIFRoaXMgZGVmaW5lcyB3aGVu
IHRoZSBiYWNrdXBzIHdpbGwgYmUgZGVsZXRlZCBhZnRlciBEYXRhYmFzZSB0ZXJtaW5hdGlv
bi4KCg0KBQQCBAIBEgScAgcbCiwKBgQCBAICABIEngIEKxocIERlZmF1bHQgdW5zcGVjaWZp
ZWQgdmFsdWUuCgoPCgcEAgQCAgABEgSeAgQmCg8KBwQCBAICAAISBJ4CKSoKYgoGBAIEAgIB
EgSiAgQbGlIgS2VlcHMgdGhlIGJhY2t1cCBmb3IgcHJlZGVmaW5lZCB0aW1lCiBpLmUuIDcy
IGhvdXJzIGFuZCB0aGVuIGRlbGV0ZSBwZXJtYW5lbnRseS4KCg8KBwQCBAICAQESBKICBBYK
DwoHBAIEAgIBAhIEogIZGgpUCgYEAgQCAgISBKYCBCYaRCBLZWVwcyB0aGUgYmFja3VwcyBh
cyBwZXIgdGhlIHBvbGljeSBkZWZpbmVkCiBmb3IgZGF0YWJhc2UgYmFja3Vwcy4KCg8KBwQC
BAICAgESBKYCBCEKDwoHBAIEAgICAhIEpgIkJQpUCgQEAgIAEgSqAgJIGkYgT3B0aW9uYWwu
IElmIHNldCB0byB0cnVlLCBlbmFibGVzIGF1dG9tYXRpYyBiYWNrdXBzIG9uIHRoZSBkYXRh
YmFzZS4KCg0KBQQCAgAFEgSqAgIGCg0KBQQCAgABEgSqAgcaCg0KBQQCAgADEgSqAh0eCg0K
BQQCAgAIEgSqAh9HChAKCAQCAgAInAgAEgSqAiBGCkgKBAQCAgESBq0CAq4CLxo4IE9wdGlv
bmFsLiBEZXRhaWxzIG9mIHRoZSBkYXRhYmFzZSBiYWNrdXAgZGVzdGluYXRpb25zLgoKDQoF
BAICAQQSBK0CAgoKDQoFBAICAQYSBK0CCyMKDQoFBAICAQESBK0CJD4KDQoFBAICAQMSBK0C
QUIKDQoFBAICAQgSBK4CBi4KEAoIBAICAQicCAASBK4CBy0K2gEKBAQCAgISBLMCAksaywEg
T3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgZGF5cyBhbiBhdXRvbWF0aWMgYmFja3VwIGlzIHJl
dGFpbmVkIGJlZm9yZSBiZWluZwogYXV0b21hdGljYWxseSBkZWxldGVkLiBUaGlzIHZhbHVl
IGRldGVybWluZXMgdGhlIGVhcmxpZXN0IHBvaW50IGluIHRpbWUgdG8KIHdoaWNoIGEgZGF0
YWJhc2UgY2FuIGJlIHJlc3RvcmVkLiBNaW46IDEsIE1heDogNjAuCgoNCgUEAgICBRIEswIC
BwoNCgUEAgICARIEswIIHQoNCgUEAgICAxIEswIgIQoNCgUEAgICCBIEswIiSgoQCggEAgIC
CJwIABIEswIjSQpmCgQEAgIDEga3AgK4Ai8aViBPcHRpb25hbC4gVGhpcyBkZWZpbmVzIHdo
ZW4gdGhlIGJhY2t1cHMgd2lsbCBiZSBkZWxldGVkIGFmdGVyIERhdGFiYXNlCiB0ZXJtaW5h
dGlvbi4KCg0KBQQCAgMGEgS3AgIWCg0KBQQCAgMBEgS3AhctCg0KBQQCAgMDEgS3AjAxCg0K
BQQCAgMIEgS4AgYuChAKCAQCAgMInAgAEgS4AgctCqMBCgQEAgIEEga8AgK9Ai8akgEgT3B0
aW9uYWwuIFRoZSBkYXkgb2YgdGhlIHdlZWsgb24gd2hpY2ggdGhlIGZ1bGwgYmFja3VwIHNo
b3VsZCBiZSBwZXJmb3JtZWQKIG9uIHRoZSBkYXRhYmFzZS4gSWYgbm8gdmFsdWUgaXMgcHJv
dmlkZWQsIGl0IHdpbGwgZGVmYXVsdCB0byBTdW5kYXkuCgoNCgUEAgIEBhIEvAICFwoNCgUE
AgIEARIEvAIYLAoNCgUEAgIEAxIEvAIvMAoNCgUEAgIECBIEvQIGLgoQCggEAgIECJwIABIE
vQIHLQqXAQoEBAICBRIGwQICwgIvGoYBIE9wdGlvbmFsLiBUaGUgd2luZG93IGluIHdoaWNo
IHRoZSBmdWxsIGJhY2t1cCBzaG91bGQgYmUgcGVyZm9ybWVkIG9uIHRoZQogZGF0YWJhc2Uu
IElmIG5vIHZhbHVlIGlzIHByb3ZpZGVkLCB0aGUgZGVmYXVsdCBpcyBhbnl0aW1lLgoKDQoF
BAICBQYSBMECAg4KDQoFBAICBQESBMECDyYKDQoFBAICBQMSBMECKSoKDQoFBAICBQgSBMIC
Bi4KEAoIBAICBQicCAASBMICBy0KvwEKBAQCAgYSBscCAsgCLxquASBPcHRpb25hbC4gVGhl
IHdpbmRvdyBpbiB3aGljaCB0aGUgaW5jcmVtZW50YWwgYmFja3VwIHNob3VsZCBiZSBwZXJm
b3JtZWQgb24KIHRoZSBkYXRhYmFzZS4gSWYgbm8gdmFsdWUgaXMgcHJvdmlkZWQsIHRoZSBk
ZWZhdWx0IGlzIGFueXRpbWUgZXhjZXB0IHRoZQogYXV0byBmdWxsIGJhY2t1cCBkYXkuCgoN
CgUEAgIGBhIExwICDgoNCgUEAgIGARIExwIPLQoNCgUEAgIGAxIExwIwMQoNCgUEAgIGCBIE
yAIGLgoQCggEAgIGCJwIABIEyAIHLQovCgIEAxIGzAIA1QIBGiEgVGhlIHJlcXVlc3QgZm9y
IGBEYXRhYmFzZS5HZXRgLgoKCwoDBAMBEgTMAggaCpMBCgQEAwIAEgbPAgLUAgQaggEgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBEYXRhYmFzZSByZXNvdXJjZSBpbiB0aGUgZm9sbG93
aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve3JlZ2lvbn0vZGF0
YWJhc2VzL3tkYXRhYmFzZX0KCg0KBQQDAgAFEgTPAgIICg0KBQQDAgABEgTPAgkNCg0KBQQD
AgADEgTPAhARCg8KBQQDAgAIEgbPAhLUAgMKEAoIBAMCAAicCAASBNACBCoKEQoHBAMCAAif
CBIG0QIE0wIFCjAKAgQEEgbYAgDxAgEaIiBUaGUgcmVxdWVzdCBmb3IgYERhdGFiYXNlLkxp
c3RgLgoKCwoDBAQBEgTYAggcCnQKBAQEAgASBtsCAuACBBpkIFJlcXVpcmVkLiBUaGUgcGFy
ZW50IHJlc291cmNlIG5hbWUgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tyZWdpb259CgoNCgUEBAIABRIE2wICCAoNCgUEBAIAARIE
2wIJDwoNCgUEBAIAAxIE2wISEwoPCgUEBAIACBIG2wIU4AIDChAKCAQEAgAInAgAEgTcAgQq
ChEKBwQEAgAInwgSBt0CBN8CBQrDAQoEBAQCARIE5QICPxq0ASBPcHRpb25hbC4gVGhlIG1h
eGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybi4KIElmIHVuc3BlY2lmaWVkLCBhIG1h
eGltdW0gb2YgNTAgRGF0YWJhc2VzIHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2
YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIHJlc2V0IHRvIDEwMDAu
CgoNCgUEBAIBBRIE5QICBwoNCgUEBAIBARIE5QIIEQoNCgUEBAIBAxIE5QIUFQoNCgUEBAIB
CBIE5QIWPgoQCggEBAIBCJwIABIE5QIXPQq+AQoEBAQCAhIE6gICQRqvASBPcHRpb25hbC4g
QSB0b2tlbiBpZGVudGlmeWluZyB0aGUgcmVxdWVzdGVkIHBhZ2Ugb2YgcmVzdWx0cyB0byBy
ZXR1cm4uIEFsbAogZmllbGRzIGV4Y2VwdCB0aGUgZmlsdGVyIHNob3VsZCByZW1haW4gdGhl
IHNhbWUgYXMgaW4gdGhlIHJlcXVlc3QgdGhhdAogcHJvdmlkZWQgdGhpcyBwYWdlIHRva2Vu
LgoKDQoFBAQCAgUSBOoCAggKDQoFBAQCAgESBOoCCRMKDQoFBAQCAgMSBOoCFhcKDQoFBAQC
AggSBOoCGEAKEAoIBAQCAgicCAASBOoCGT8KkgIKBAQEAgMSBPACAj0agwIgT3B0aW9uYWwu
IEFuIGV4cHJlc3Npb24gZm9yIGZpbHRlcmluZyB0aGUgcmVzdWx0cyBvZiB0aGUgcmVxdWVz
dC4gbGlzdCBmb3IKIGNvbnRhaW5lciBkYXRhYmFzZXMgaXMgc3VwcG9ydGVkIG9ubHkgd2l0
aCBhIHZhbGlkIGRiU3lzdGVtIChmdWxsIHJlc291cmNlCiBuYW1lKSBmaWx0ZXIgaW4gdGhp
cyBmb3JtYXQ6CiBgZGJTeXN0ZW09InByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9kYlN5c3RlbXMve2RiU3lzdGVtSWR9ImAKCg0KBQQEAgMFEgTwAgIICg0KBQQE
AgMBEgTwAgkPCg0KBQQEAgMDEgTwAhITCg0KBQQEAgMIEgTwAhQ8ChAKCAQEAgMInAgAEgTw
AhU7CjEKAgQFEgb0AgD6AgEaIyBUaGUgcmVzcG9uc2UgZm9yIGBEYXRhYmFzZS5MaXN0YC4K
CgsKAwQFARIE9AIIHQomCgQEBQIAEgT2AgIiGhggVGhlIGxpc3Qgb2YgRGF0YWJhc2VzLgoK
DQoFBAUCAAQSBPYCAgoKDQoFBAUCAAYSBPYCCxMKDQoFBAUCAAESBPYCFB0KDQoFBAUCAAMS
BPYCICEKTwoEBAUCARIE+QICHRpBIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJl
c3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDQoFBAUCAQUSBPkCAggKDQoFBAUC
AQESBPkCCRgKDQoFBAUCAQMSBPkCGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::Database::Database ===
    # Fields for Database
    # Field: name Type: 9 ()
    # Field: db_name Type: 9 ()
    # Field: db_unique_name Type: 9 ()
    # Field: admin_password Type: 9 ()
    # Field: admin_password_secret_version Type: 9 ()
    # Field: tde_wallet_password Type: 9 ()
    # Field: tde_wallet_password_secret_version Type: 9 ()
    # Field: character_set Type: 9 ()
    # Field: ncharacter_set Type: 9 ()
    # Field: oci_url Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.DatabaseProperties)
    # Field: database_id Type: 9 ()
    # Field: db_home_name Type: 9 ()
    # Field: gcp_oracle_zone Type: 9 ()
    # Field: ops_insights_status Type: 14 (.google.cloud.oracledatabase.v1.Database.OperationsInsightsStatus)
    # Field: pluggable_database_id Type: 9 ()
    # Field: pluggable_database_name Type: 9 ()

# Enum: Database::OperationsInsightsStatus
our $Database_OPERATIONS_INSIGHTS_STATUS_UNSPECIFIED = 0;
our $Database_ENABLING = 1;
our $Database_ENABLED = 2;
our $Database_DISABLING = 3;
our $Database_NOT_ENABLED = 4;
our $Database_FAILED_ENABLING = 5;
our $Database_FAILED_DISABLING = 6;

# === Message: Google::Cloud::Oracledatabase::V1::Database::DatabaseProperties ===
    # Fields for DatabaseProperties
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.DatabaseProperties.DatabaseLifecycleState)
    # Field: db_version Type: 9 ()
    # Field: db_backup_config Type: 11 (.google.cloud.oracledatabase.v1.DbBackupConfig)
    # Field: database_management_config Type: 11 (.google.cloud.oracledatabase.v1.DatabaseManagementConfig)

# Enum: DatabaseProperties::DatabaseLifecycleState
our $DatabaseProperties_DATABASE_LIFECYCLE_STATE_UNSPECIFIED = 0;
our $DatabaseProperties_PROVISIONING = 1;
our $DatabaseProperties_AVAILABLE = 2;
our $DatabaseProperties_UPDATING = 3;
our $DatabaseProperties_BACKUP_IN_PROGRESS = 4;
our $DatabaseProperties_UPGRADING = 5;
our $DatabaseProperties_CONVERTING = 6;
our $DatabaseProperties_TERMINATING = 7;
our $DatabaseProperties_TERMINATED = 8;
our $DatabaseProperties_RESTORE_FAILED = 9;
our $DatabaseProperties_FAILED = 10;

# === Message: Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig ===
    # Fields for DbBackupConfig
    # Field: auto_backup_enabled Type: 8 ()
    # Field: backup_destination_details Type: 11 (.google.cloud.oracledatabase.v1.DbBackupConfig.BackupDestinationDetails)
    # Field: retention_period_days Type: 5 ()
    # Field: backup_deletion_policy Type: 14 (.google.cloud.oracledatabase.v1.DbBackupConfig.BackupDeletionPolicy)
    # Field: auto_full_backup_day Type: 14 (.google.type.DayOfWeek)
    # Field: auto_full_backup_window Type: 14 (.google.cloud.oracledatabase.v1.DbBackupConfig.BackupWindow)
    # Field: auto_incremental_backup_window Type: 14 (.google.cloud.oracledatabase.v1.DbBackupConfig.BackupWindow)

# Enum: DbBackupConfig::BackupDestinationType
our $DbBackupConfig_BACKUP_DESTINATION_TYPE_UNSPECIFIED = 0;
our $DbBackupConfig_NFS = 1;
our $DbBackupConfig_RECOVERY_APPLIANCE = 2;
our $DbBackupConfig_OBJECT_STORE = 3;
our $DbBackupConfig_LOCAL = 4;
our $DbBackupConfig_DBRS = 5;

# Enum: DbBackupConfig::BackupWindow
our $DbBackupConfig_BACKUP_WINDOW_UNSPECIFIED = 0;
our $DbBackupConfig_SLOT_ONE = 1;
our $DbBackupConfig_SLOT_TWO = 2;
our $DbBackupConfig_SLOT_THREE = 3;
our $DbBackupConfig_SLOT_FOUR = 4;
our $DbBackupConfig_SLOT_FIVE = 5;
our $DbBackupConfig_SLOT_SIX = 6;
our $DbBackupConfig_SLOT_SEVEN = 7;
our $DbBackupConfig_SLOT_EIGHT = 8;
our $DbBackupConfig_SLOT_NINE = 9;
our $DbBackupConfig_SLOT_TEN = 10;
our $DbBackupConfig_SLOT_ELEVEN = 11;
our $DbBackupConfig_SLOT_TWELVE = 12;

# Enum: DbBackupConfig::BackupDeletionPolicy
our $DbBackupConfig_BACKUP_DELETION_POLICY_UNSPECIFIED = 0;
our $DbBackupConfig_DELETE_IMMEDIATELY = 1;
our $DbBackupConfig_DELETE_AFTER_RETENTION_PERIOD = 2;

# === Message: Google::Cloud::Oracledatabase::V1::Database::GetDatabaseRequest ===
    # Fields for GetDatabaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::Database::ListDatabasesRequest ===
    # Fields for ListDatabasesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::Database::ListDatabasesResponse ===
    # Fields for ListDatabasesResponse
    # Field: databases Type: 11 (.google.cloud.oracledatabase.v1.Database)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::Database - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/database.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::Database;

    my $msg = Google::Cloud::Oracledatabase::V1::Database::Database->new({
        name => $name,
        db_name => $db_name,
        db_unique_name => $db_unique_name,
        admin_password => $admin_password,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::Database::Database->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/database.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::Database::Database

Details of the Database resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/Database/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Database resource in the following format:
projects/{project}/locations/{region}/databases/{database}

=item * C<< $msg->db_name() >> / C<< $msg->db_name($value) >>

Type: C<String>

Optional. The database name. The name must begin with an alphabetic
character and can contain a maximum of eight alphanumeric characters.
Special characters are not permitted.

=item * C<< $msg->db_unique_name() >> / C<< $msg->db_unique_name($value) >>

Type: C<String>

Optional. The DB_UNIQUE_NAME of the Oracle Database being backed up.

=item * C<< $msg->admin_password() >> / C<< $msg->admin_password($value) >>

Type: C<String>

Optional. Input only. The password for the default ADMIN user.
Note: Only one of `admin_password_secret_version` or `admin_password` can
be populated.

=item * C<< $msg->admin_password_secret_version() >> / C<< $msg->admin_password_secret_version($value) >>

Type: C<String>

Optional. Input only. The resource name of a secret version in Secret
Manager which contains the database admin user's password. Format:
projects/{project}/secrets/{secret}/versions/{version}. Note: Only one of
`admin_password_secret_version` or `admin_password` can be populated.

=item * C<< $msg->tde_wallet_password() >> / C<< $msg->tde_wallet_password($value) >>

Type: C<String>

Optional. Input only. The TDE wallet password for the database.
Note: Only one of `tde_wallet_password_secret_version` or
`tde_wallet_password` can be populated.

=item * C<< $msg->tde_wallet_password_secret_version() >> / C<< $msg->tde_wallet_password_secret_version($value) >>

Type: C<String>

Optional. Input only. The resource name of a secret version in Secret
Manager which contains the TDE wallet password for the database. Format:
projects/{project}/secrets/{secret}/versions/{version}. Note: Only one of
`tde_wallet_password_secret_version` or `tde_wallet_password` can be
populated.

=item * C<< $msg->character_set() >> / C<< $msg->character_set($value) >>

Type: C<String>

Optional. The character set for the database. The default is AL32UTF8.

=item * C<< $msg->ncharacter_set() >> / C<< $msg->ncharacter_set($value) >>

Type: C<String>

Optional. The national character set for the database. The default is
AL16UTF16.

=item * C<< $msg->oci_url() >> / C<< $msg->oci_url($value) >>

Type: C<String>

Output only. HTTPS link to OCI resources exposed to Customer via UI
Interface.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the Database was created.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Database::DatabaseProperties>)

Optional. The properties of the Database.

=item * C<< $msg->database_id() >> / C<< $msg->database_id($value) >>

Type: C<String>

Optional. The database ID of the Database.

=item * C<< $msg->db_home_name() >> / C<< $msg->db_home_name($value) >>

Type: C<String>

Optional. The name of the DbHome resource associated with the Database.

=item * C<< $msg->gcp_oracle_zone() >> / C<< $msg->gcp_oracle_zone($value) >>

Type: C<String>

Output only. The GCP Oracle zone where the Database is created.

=item * C<< $msg->ops_insights_status() >> / C<< $msg->ops_insights_status($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::Database::OperationsInsightsStatus>)

Output only. The Status of Operations Insights for this Database.

=item * C<< $msg->pluggable_database_id() >> / C<< $msg->pluggable_database_id($value) >>

Type: C<String>

Optional. The ID of the pluggable database associated with the Database.
The ID must be unique within the project and location.

=item * C<< $msg->pluggable_database_name() >> / C<< $msg->pluggable_database_name($value) >>

Type: C<String>

Optional. The pluggable database associated with the Database. The name
must begin with an alphabetic character and can contain a maximum of thirty
alphanumeric characters.

=back

=head3 Enum: Database::OperationsInsightsStatus

=over 4

=item * C<OPERATIONS_INSIGHTS_STATUS_UNSPECIFIED> => C<0>

=item * C<ENABLING> => C<1>

=item * C<ENABLED> => C<2>

=item * C<DISABLING> => C<3>

=item * C<NOT_ENABLED> => C<4>

=item * C<FAILED_ENABLING> => C<5>

=item * C<FAILED_DISABLING> => C<6>

=back

=head2 Google::Cloud::Oracledatabase::V1::Database::DatabaseProperties

The properties of a Database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DatabaseProperties::DatabaseLifecycleState>)

Output only. State of the Database.

=item * C<< $msg->db_version() >> / C<< $msg->db_version($value) >>

Type: C<String>

Required. The Oracle Database version.

=item * C<< $msg->db_backup_config() >> / C<< $msg->db_backup_config($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig>)

Optional. Backup options for the Database.

=item * C<< $msg->database_management_config() >> / C<< $msg->database_management_config($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig>)

Output only. The Database Management config.

=back

=head3 Enum: DatabaseProperties::DatabaseLifecycleState

=over 4

=item * C<DATABASE_LIFECYCLE_STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<BACKUP_IN_PROGRESS> => C<4>

=item * C<UPGRADING> => C<5>

=item * C<CONVERTING> => C<6>

=item * C<TERMINATING> => C<7>

=item * C<TERMINATED> => C<8>

=item * C<RESTORE_FAILED> => C<9>

=item * C<FAILED> => C<10>

=back

=head2 Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig

Backup Options for the Database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_backup_enabled() >> / C<< $msg->auto_backup_enabled($value) >>

Type: C<Bool>

Optional. If set to true, enables automatic backups on the database.

=item * C<< $msg->backup_destination_details() >> / C<< $msg->backup_destination_details($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig::BackupDestinationDetails>)

Optional. Details of the database backup destinations.

=item * C<< $msg->retention_period_days() >> / C<< $msg->retention_period_days($value) >>

Type: C<Int32>

Optional. The number of days an automatic backup is retained before being
automatically deleted. This value determines the earliest point in time to
which a database can be restored. Min: 1, Max: 60.

=item * C<< $msg->backup_deletion_policy() >> / C<< $msg->backup_deletion_policy($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbBackupConfig::BackupDeletionPolicy>)

Optional. This defines when the backups will be deleted after Database
termination.

=item * C<< $msg->auto_full_backup_day() >> / C<< $msg->auto_full_backup_day($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Optional. The day of the week on which the full backup should be performed
on the database. If no value is provided, it will default to Sunday.

=item * C<< $msg->auto_full_backup_window() >> / C<< $msg->auto_full_backup_window($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbBackupConfig::BackupWindow>)

Optional. The window in which the full backup should be performed on the
database. If no value is provided, the default is anytime.

=item * C<< $msg->auto_incremental_backup_window() >> / C<< $msg->auto_incremental_backup_window($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbBackupConfig::BackupWindow>)

Optional. The window in which the incremental backup should be performed on
the database. If no value is provided, the default is anytime except the
auto full backup day.

=back

=head3 Enum: DbBackupConfig::BackupDestinationType

=over 4

=item * C<BACKUP_DESTINATION_TYPE_UNSPECIFIED> => C<0>

=item * C<NFS> => C<1>

=item * C<RECOVERY_APPLIANCE> => C<2>

=item * C<OBJECT_STORE> => C<3>

=item * C<LOCAL> => C<4>

=item * C<DBRS> => C<5>

=back

=head3 Enum: DbBackupConfig::BackupWindow

=over 4

=item * C<BACKUP_WINDOW_UNSPECIFIED> => C<0>

=item * C<SLOT_ONE> => C<1>

=item * C<SLOT_TWO> => C<2>

=item * C<SLOT_THREE> => C<3>

=item * C<SLOT_FOUR> => C<4>

=item * C<SLOT_FIVE> => C<5>

=item * C<SLOT_SIX> => C<6>

=item * C<SLOT_SEVEN> => C<7>

=item * C<SLOT_EIGHT> => C<8>

=item * C<SLOT_NINE> => C<9>

=item * C<SLOT_TEN> => C<10>

=item * C<SLOT_ELEVEN> => C<11>

=item * C<SLOT_TWELVE> => C<12>

=back

=head3 Enum: DbBackupConfig::BackupDeletionPolicy

=over 4

=item * C<BACKUP_DELETION_POLICY_UNSPECIFIED> => C<0>

=item * C<DELETE_IMMEDIATELY> => C<1>

=item * C<DELETE_AFTER_RETENTION_PERIOD> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::Database::GetDatabaseRequest

The request for `Database.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Database resource in the following format:
projects/{project}/locations/{region}/databases/{database}

=back

=head2 Google::Cloud::Oracledatabase::V1::Database::ListDatabasesRequest

The request for `Database.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name in the following format:
projects/{project}/locations/{region}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, a maximum of 50 Databases will be returned.
The maximum value is 1000; values above 1000 will be reset to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the requested page of results to return. All
fields except the filter should remain the same as in the request that
provided this page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. list for
container databases is supported only with a valid dbSystem (full resource
name) filter in this format:
`dbSystem="projects/{project}/locations/{location}/dbSystems/{dbSystemId}"`

=back

=head2 Google::Cloud::Oracledatabase::V1::Database::ListDatabasesResponse

The response for `Database.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->databases() >> / C<< $msg->databases($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Database::Database>)

The list of Databases.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::Database::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
