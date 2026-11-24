package Google::Cloud::Oracledatabase::V1::VmCluster;

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
    eval { require Google::Cloud::Oracledatabase::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Datetime };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvdm1fY2x1c3Rlci5wcm90bxIeZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGitnb29nbGUvY2xvdWQvb3JhY2xl
ZGF0YWJhc2UvdjEvY29tbW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvGhpnb29nbGUvdHlwZS9kYXRldGltZS5wcm90byL8CwoOQ2xvdWRWbUNsdXN0ZXISFwoE
bmFtZRgBIAEoCUID4EEIUgRuYW1lEnoKFmV4YWRhdGFfaW5mcmFzdHJ1Y3R1cmUYAiABKAlC
Q+BBAuBBBfpBOgo4b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vQ2xvdWRFeGFkYXRh
SW5mcmFzdHJ1Y3R1cmVSFWV4YWRhdGFJbmZyYXN0cnVjdHVyZRIpCgxkaXNwbGF5X25hbWUY
AyABKAlCBuBBAeBBBVILZGlzcGxheU5hbWUSYAoKcHJvcGVydGllcxgGIAEoCzI4Lmdvb2ds
ZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5DbG91ZFZtQ2x1c3RlclByb3BlcnRpZXNCBuBB
AeBBBVIKcHJvcGVydGllcxJXCgZsYWJlbHMYByADKAsyOi5nb29nbGUuY2xvdWQub3JhY2xl
ZGF0YWJhc2UudjEuQ2xvdWRWbUNsdXN0ZXIuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEkAK
C2NyZWF0ZV90aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpj
cmVhdGVUaW1lEhoKBGNpZHIYCSABKAlCBuBBAeBBBVIEY2lkchI0ChJiYWNrdXBfc3VibmV0
X2NpZHIYCiABKAlCBuBBAeBBBVIQYmFja3VwU3VibmV0Q2lkchJDCgduZXR3b3JrGAsgASgJ
QingQQHgQQX6QSAKHmNvbXB1dGUuZ29vZ2xlYXBpcy5jb20vTmV0d29ya1IHbmV0d29yaxIr
Cg9nY3Bfb3JhY2xlX3pvbmUYDCABKAlCA+BBA1INZ2NwT3JhY2xlWm9uZRJUCgtvZGJfbmV0
d29yaxgNIAEoCUIz4EEB4EEF+kEqCihvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9P
ZGJOZXR3b3JrUgpvZGJOZXR3b3JrElEKCm9kYl9zdWJuZXQYDiABKAlCMuBBAeBBBfpBKQon
b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vT2RiU3VibmV0UglvZGJTdWJuZXQSXgoR
YmFja3VwX29kYl9zdWJuZXQYDyABKAlCMuBBAeBBBfpBKQonb3JhY2xlZGF0YWJhc2UuZ29v
Z2xlYXBpcy5jb20vT2RiU3VibmV0Ug9iYWNrdXBPZGJTdWJuZXQSVQoMb2RiX2Ruc196b25l
GBIgASgJQjPgQQHgQQX6QSoKKG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL09kYkRu
c1pvbmVSCm9kYkRuc1pvbmUSZQoSaWRlbnRpdHlfY29ubmVjdG9yGBAgASgLMjEuZ29vZ2xl
LmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLklkZW50aXR5Q29ubmVjdG9yQgPgQQNSEWlkZW50
aXR5Q29ubmVjdG9yEnoKGWV4YXNjYWxlX2RiX3N0b3JhZ2VfdmF1bHQYESABKAlCP+BBAeBB
BfpBNgo0b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vRXhhc2NhbGVEYlN0b3JhZ2VW
YXVsdFIWZXhhc2NhbGVEYlN0b3JhZ2VWYXVsdBJJChtpZGVudGl0eV9jb25uZWN0b3JfZGlz
YWJsZWQYEyABKAhCCeBBAeBBBOBBBVIZaWRlbnRpdHlDb25uZWN0b3JEaXNhYmxlZBo5CgtM
YWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB
Op8B6kGbAQosb3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vQ2xvdWRWbUNsdXN0ZXIS
SnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbG91ZFZtQ2x1c3Rl
cnMve2Nsb3VkX3ZtX2NsdXN0ZXJ9Kg9jbG91ZFZtQ2x1c3RlcnMyDmNsb3VkVm1DbHVzdGVy
Iu0WChhDbG91ZFZtQ2x1c3RlclByb3BlcnRpZXMSFwoEb2NpZBgBIAEoCUID4EEDUgRvY2lk
EmwKDGxpY2Vuc2VfdHlwZRgCIAEoDjJELmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52
MS5DbG91ZFZtQ2x1c3RlclByb3BlcnRpZXMuTGljZW5zZVR5cGVCA+BBAlILbGljZW5zZVR5
cGUSIgoKZ2lfdmVyc2lvbhgDIAEoCUID4EEBUglnaVZlcnNpb24SNwoJdGltZV96b25lGAQg
ASgLMhUuZ29vZ2xlLnR5cGUuVGltZVpvbmVCA+BBAVIIdGltZVpvbmUSKwoPc3NoX3B1Ymxp
Y19rZXlzGAUgAygJQgPgQQFSDXNzaFB1YmxpY0tleXMSIgoKbm9kZV9jb3VudBgGIAEoBUID
4EEBUglub2RlQ291bnQSGQoFc2hhcGUYByABKAlCA+BBA1IFc2hhcGUSIgoKb2NwdV9jb3Vu
dBgIIAEoAkID4EEBUglvY3B1Q291bnQSKQoObWVtb3J5X3NpemVfZ2IYCSABKAVCA+BBAVIM
bWVtb3J5U2l6ZUdiEjkKF2RiX25vZGVfc3RvcmFnZV9zaXplX2diGAogASgFQgPgQQFSE2Ri
Tm9kZVN0b3JhZ2VTaXplR2ISKwoPc3RvcmFnZV9zaXplX2diGAsgASgFQgPgQQNSDXN0b3Jh
Z2VTaXplR2ISNAoUZGF0YV9zdG9yYWdlX3NpemVfdGIYDCABKAFCA+BBAVIRZGF0YVN0b3Jh
Z2VTaXplVGISdQoPZGlza19yZWR1bmRhbmN5GA0gASgOMkcuZ29vZ2xlLmNsb3VkLm9yYWNs
ZWRhdGFiYXNlLnYxLkNsb3VkVm1DbHVzdGVyUHJvcGVydGllcy5EaXNrUmVkdW5kYW5jeUID
4EEBUg5kaXNrUmVkdW5kYW5jeRI9ChhzcGFyc2VfZGlza2dyb3VwX2VuYWJsZWQYDiABKAhC
A+BBAVIWc3BhcnNlRGlza2dyb3VwRW5hYmxlZBI1ChRsb2NhbF9iYWNrdXBfZW5hYmxlZBgP
IAEoCEID4EEBUhJsb2NhbEJhY2t1cEVuYWJsZWQSLAoPaG9zdG5hbWVfcHJlZml4GBAgASgJ
QgPgQQFSDmhvc3RuYW1lUHJlZml4EokBCiNkaWFnbm9zdGljc19kYXRhX2NvbGxlY3Rpb25f
b3B0aW9ucxgTIAEoCzI1Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYXRhQ29s
bGVjdGlvbk9wdGlvbnNCA+BBAVIgZGlhZ25vc3RpY3NEYXRhQ29sbGVjdGlvbk9wdGlvbnMS
WQoFc3RhdGUYFCABKA4yPi5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuQ2xvdWRW
bUNsdXN0ZXJQcm9wZXJ0aWVzLlN0YXRlQgPgQQNSBXN0YXRlEjgKFnNjYW5fbGlzdGVuZXJf
cG9ydF90Y3AYFSABKAVCA+BBAVITc2Nhbkxpc3RlbmVyUG9ydFRjcBI/ChpzY2FuX2xpc3Rl
bmVyX3BvcnRfdGNwX3NzbBgWIAEoBUID4EEBUhZzY2FuTGlzdGVuZXJQb3J0VGNwU3NsEhsK
BmRvbWFpbhgXIAEoCUID4EEDUgZkb21haW4SHgoIc2Nhbl9kbnMYGCABKAlCA+BBA1IHc2Nh
bkRucxIfCghob3N0bmFtZRgZIAEoCUID4EEDUghob3N0bmFtZRIpCg5jcHVfY29yZV9jb3Vu
dBgaIAEoBUID4EECUgxjcHVDb3JlQ291bnQSKgoOc3lzdGVtX3ZlcnNpb24YGyABKAlCA+BB
AVINc3lzdGVtVmVyc2lvbhIjCgtzY2FuX2lwX2lkcxgcIAMoCUID4EEDUglzY2FuSXBJZHMS
MAoSc2Nhbl9kbnNfcmVjb3JkX2lkGB0gASgJQgPgQQNSD3NjYW5EbnNSZWNvcmRJZBIcCgdv
Y2lfdXJsGB4gASgJQgPgQQNSBm9jaVVybBIrCg9kYl9zZXJ2ZXJfb2NpZHMYHyADKAlCA+BB
AVINZGJTZXJ2ZXJPY2lkcxIqCg5jb21wYXJ0bWVudF9pZBggIAEoCUID4EEDUg1jb21wYXJ0
bWVudElkEisKD2Ruc19saXN0ZW5lcl9pcBgjIAEoCUID4EEDUg1kbnNMaXN0ZW5lcklwEiYK
DGNsdXN0ZXJfbmFtZRgkIAEoCUID4EEBUgtjbHVzdGVyTmFtZRJWCg1jb21wdXRlX21vZGVs
GCUgASgOMiwuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkNvbXB1dGVNb2RlbEID
4EEDUgxjb21wdXRlTW9kZWwSiwEKF3N0b3JhZ2VfbWFuYWdlbWVudF90eXBlGCYgASgOMk4u
Z29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkNsb3VkVm1DbHVzdGVyUHJvcGVydGll
cy5TdG9yYWdlTWFuYWdlbWVudFR5cGVCA+BBA1IVc3RvcmFnZU1hbmFnZW1lbnRUeXBlEpMB
Cht2bV9maWxlX3N5c3RlbV9zdG9yYWdlX3R5cGUYJyABKA4yUC5nb29nbGUuY2xvdWQub3Jh
Y2xlZGF0YWJhc2UudjEuQ2xvdWRWbUNsdXN0ZXJQcm9wZXJ0aWVzLlZtRmlsZVN5c3RlbVN0
b3JhZ2VUeXBlQgPgQQFSF3ZtRmlsZVN5c3RlbVN0b3JhZ2VUeXBlEoYBChZ2bV9iYWNrdXBf
c3RvcmFnZV90eXBlGCggASgOMkwuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkNs
b3VkVm1DbHVzdGVyUHJvcGVydGllcy5WbUJhY2t1cFN0b3JhZ2VUeXBlQgPgQQFSE3ZtQmFj
a3VwU3RvcmFnZVR5cGUiXQoLTGljZW5zZVR5cGUSHAoYTElDRU5TRV9UWVBFX1VOU1BFQ0lG
SUVEEAASFAoQTElDRU5TRV9JTkNMVURFRBABEhoKFkJSSU5HX1lPVVJfT1dOX0xJQ0VOU0UQ
AiJHCg5EaXNrUmVkdW5kYW5jeRIfChtESVNLX1JFRFVOREFOQ1lfVU5TUEVDSUZJRUQQABII
CgRISUdIEAESCgoGTk9STUFMEAIilwEKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAAS
EAoMUFJPVklTSU9OSU5HEAESDQoJQVZBSUxBQkxFEAISDAoIVVBEQVRJTkcQAxIPCgtURVJN
SU5BVElORxAEEg4KClRFUk1JTkFURUQQBRIKCgZGQUlMRUQQBhIbChdNQUlOVEVOQU5DRV9J
Tl9QUk9HUkVTUxAHIlcKFVN0b3JhZ2VNYW5hZ2VtZW50VHlwZRInCiNTVE9SQUdFX01BTkFH
RU1FTlRfVFlQRV9VTlNQRUNJRklFRBAAEgcKA0FTTRABEgwKCEVYQVNDQUxFEAIilwEKF1Zt
RmlsZVN5c3RlbVN0b3JhZ2VUeXBlEisKJ1ZNX0ZJTEVfU1lTVEVNX1NUT1JBR0VfVFlQRV9V
TlNQRUNJRklFRBAAEiUKIVZNX0ZJTEVfU1lTVEVNX1NUT1JBR0VfVFlQRV9MT0NBTBABEigK
JFZNX0ZJTEVfU1lTVEVNX1NUT1JBR0VfVFlQRV9FWEFTQ0FMRRACIoQBChNWbUJhY2t1cFN0
b3JhZ2VUeXBlEiYKIlZNX0JBQ0tVUF9TVE9SQUdFX1RZUEVfVU5TUEVDSUZJRUQQABIgChxW
TV9CQUNLVVBfU1RPUkFHRV9UWVBFX0xPQ0FMEAESIwofVk1fQkFDS1VQX1NUT1JBR0VfVFlQ
RV9FWEFTQ0FMRRACItQBChVEYXRhQ29sbGVjdGlvbk9wdGlvbnMSQQoaZGlhZ25vc3RpY3Nf
ZXZlbnRzX2VuYWJsZWQYASABKAhCA+BBAVIYZGlhZ25vc3RpY3NFdmVudHNFbmFibGVkEj8K
GWhlYWx0aF9tb25pdG9yaW5nX2VuYWJsZWQYAiABKAhCA+BBAVIXaGVhbHRoTW9uaXRvcmlu
Z0VuYWJsZWQSNwoVaW5jaWRlbnRfbG9nc19lbmFibGVkGAMgASgIQgPgQQFSE2luY2lkZW50
TG9nc0VuYWJsZWRC7QEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjFCE0Ns
b3VkVm1DbHVzdGVyUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9vcmFjbGVkYXRhYmFz
ZS9hcGl2MS9vcmFjbGVkYXRhYmFzZXBiO29yYWNsZWRhdGFiYXNlcGKqAh5Hb29nbGUuQ2xv
dWQuT3JhY2xlRGF0YWJhc2UuVjHKAh5Hb29nbGVcQ2xvdWRcT3JhY2xlRGF0YWJhc2VcVjHq
AiFHb29nbGU6OkNsb3VkOjpPcmFjbGVEYXRhYmFzZTo6VjFKsW0KBxIFDgCNAwEKvAQKAQwS
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
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUADUKCQoCAwMSAxUAKQoJCgIDBBIDFgAkCggKAQgSAxgAOwoJCgII
JRIDGAA7CggKAQgSAxkAYQoJCgIICxIDGQBhCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgS
AxsANAoJCgIICBIDGwA0CggKAQgSAxwAOwoJCgIIARIDHAA7CggKAQgSAx0AOwoJCgIIKRID
HQA7CggKAQgSAx4AOgoJCgIILRIDHgA6CocBCgIEABIFIgCuAQEaeiBEZXRhaWxzIG9mIHRo
ZSBDbG91ZCBWTSBDbHVzdGVyIHJlc291cmNlLgogaHR0cHM6Ly9kb2NzLm9yYWNsZS5jb20v
ZW4tdXMvaWFhcy9hcGkvIy9lbi9kYXRhYmFzZS8yMDE2MDkxOC9DbG91ZFZtQ2x1c3Rlci8K
CgoKAwQAARIDIggWCgsKAwQABxIEIwIoBAoNCgUEAAedCBIEIwIoBAqaAQoEBAACABIDLAI9
GowBIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBWTSBDbHVzdGVyIHJlc291cmNlIHdp
dGggdGhlIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve3JlZ2lvbn0v
Y2xvdWRWbUNsdXN0ZXJzL3tjbG91ZF92bV9jbHVzdGVyfQoKDAoFBAACAAUSAywCCAoMCgUE
AAIAARIDLAkNCgwKBQQAAgADEgMsEBEKDAoFBAACAAgSAywSPAoPCggEAAIACJwIABIDLBM7
CvsBCgQEAAIBEgQxAjcEGuwBIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBuYW1lIG9mIHRo
ZSBFeGFkYXRhIEluZnJhc3RydWN0dXJlIHJlc291cmNlIG9uCiB3aGljaCBWTSBjbHVzdGVy
IHJlc291cmNlIGlzIGNyZWF0ZWQsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97cmVnaW9ufS9jbG91ZEV4YWRhdGFJbmZyYXN0dWN0
dXJlcy97Y2xvdWRfZXh0cmFkYXRhX2luZnJhc3RydWN0dXJlfQoKDAoFBAACAQUSAzECCAoM
CgUEAAIBARIDMQkfCgwKBQQAAgEDEgMxIiMKDQoFBAACAQgSBDEkNwMKDwoIBAACAQicCAAS
AzIEKgoPCggEAAIBCJwIARIDMwQrCg8KBwQAAgEInwgSBDQENgUKSgoEBAACAhIEOgI9BBo8
IE9wdGlvbmFsLiBJbW11dGFibGUuIFVzZXIgZnJpZW5kbHkgbmFtZSBmb3IgdGhpcyByZXNv
dXJjZS4KCgwKBQQAAgIFEgM6AggKDAoFBAACAgESAzoJFQoMCgUEAAICAxIDOhgZCg0KBQQA
AgIIEgQ6Gj0DCg8KCAQAAgIInAgAEgM7BCoKDwoIBAACAgicCAESAzwEKwpKCgQEAAIDEgRA
AkMEGjwgT3B0aW9uYWwuIEltbXV0YWJsZS4gVmFyaW91cyBwcm9wZXJ0aWVzIG9mIHRoZSBW
TSBDbHVzdGVyLgoKDAoFBAACAwYSA0ACGgoMCgUEAAIDARIDQBslCgwKBQQAAgMDEgNAKCkK
DQoFBAACAwgSBEAqQwMKDwoIBAACAwicCAASA0EEKgoPCggEAAIDCJwIARIDQgQrCkcKBAQA
AgQSA0YCSho6IE9wdGlvbmFsLiBMYWJlbHMgb3IgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhl
IFZNIENsdXN0ZXIuCgoMCgUEAAIEBhIDRgIVCgwKBQQAAgQBEgNGFhwKDAoFBAACBAMSA0Yf
IAoMCgUEAAIECBIDRiFJCg8KCAQAAgQInAgAEgNGIkgKTwoEBAACBRIESQJKMhpBIE91dHB1
dCBvbmx5LiBUaGUgZGF0ZSBhbmQgdGltZSB0aGF0IHRoZSBWTSBjbHVzdGVyIHdhcyBjcmVh
dGVkLgoKDAoFBAACBQYSA0kCGwoMCgUEAAIFARIDSRwnCgwKBQQAAgUDEgNJKisKDAoFBAAC
BQgSA0oGMQoPCggEAAIFCJwIABIDSgcwCl4KBAQAAgYSBE4CUQQaUCBPcHRpb25hbC4gSW1t
dXRhYmxlLiBOZXR3b3JrIHNldHRpbmdzLiBDSURSIHRvIHVzZSBmb3IgY2x1c3RlciBJUAog
YWxsb2NhdGlvbi4KCgwKBQQAAgYFEgNOAggKDAoFBAACBgESA04JDQoMCgUEAAIGAxIDThAR
Cg0KBQQAAgYIEgROElEDCg8KCAQAAgYInAgAEgNPBCoKDwoIBAACBgicCAESA1AEKwpFCgQE
AAIHEgRUAlcEGjcgT3B0aW9uYWwuIEltbXV0YWJsZS4gQ0lEUiByYW5nZSBvZiB0aGUgYmFj
a3VwIHN1Ym5ldC4KCgwKBQQAAgcFEgNUAggKDAoFBAACBwESA1QJGwoMCgUEAAIHAxIDVB4g
Cg0KBQQAAgcIEgRUIVcDCg8KCAQAAgcInAgAEgNVBCoKDwoIBAACBwicCAESA1YEKwp3CgQE
AAIIEgRbAl8EGmkgT3B0aW9uYWwuIEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIFZQQyBu
ZXR3b3JrLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vZ2xvYmFsL25ldHdvcmtzL3tu
ZXR3b3JrfQoKDAoFBAACCAUSA1sCCAoMCgUEAAIIARIDWwkQCgwKBQQAAggDEgNbExUKDQoF
BAACCAgSBFsWXwMKDwoIBAACCAicCAASA1wEKgoPCggEAAIICJwIARIDXQQrCg4KBwQAAggI
nwgSA14EUArBAQoEBAACCRIDZAJKGrMBIE91dHB1dCBvbmx5LiBUaGUgR0NQIE9yYWNsZSB6
b25lIHdoZXJlIE9yYWNsZSBDbG91ZFZtQ2x1c3RlciBpcyBob3N0ZWQuCiBUaGlzIHdpbGwg
YmUgdGhlIHNhbWUgYXMgdGhlIGdjcF9vcmFjbGVfem9uZSBvZiB0aGUKIENsb3VkRXhhZGF0
YUluZnJhc3RydWN0dXJlLiBFeGFtcGxlOiB1cy1lYXN0NC1iLXIyLgoKDAoFBAACCQUSA2QC
CAoMCgUEAAIJARIDZAkYCgwKBQQAAgkDEgNkGx0KDAoFBAACCQgSA2QeSQoPCggEAAIJCJwI
ABIDZB9ICqACCgQEAAIKEgRrAnEEGpECIE9wdGlvbmFsLiBJbW11dGFibGUuIFRoZSBuYW1l
IG9mIHRoZSBPZGJOZXR3b3JrIGFzc29jaWF0ZWQgd2l0aCB0aGUgVk0KIENsdXN0ZXIuIEZv
cm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vZGJOZXR3
b3Jrcy97b2RiX25ldHdvcmt9CiBJdCBpcyBvcHRpb25hbCBidXQgaWYgc3BlY2lmaWVkLCB0
aGlzIHNob3VsZCBtYXRjaCB0aGUgcGFyZW50IE9EQk5ldHdvcmsgb2YKIHRoZSBvZGJfc3Vi
bmV0IGFuZCBiYWNrdXBfb2RiX3N1Ym5ldC4KCgwKBQQAAgoFEgNrAggKDAoFBAACCgESA2sJ
FAoMCgUEAAIKAxIDaxcZCg0KBQQAAgoIEgRrGnEDCg8KCAQAAgoInAgAEgNsBCoKDwoIBAAC
CgicCAESA20EKwoPCgcEAAIKCJ8IEgRuBHAFCtUBCgQEAAILEgR2AnwEGsYBIE9wdGlvbmFs
LiBJbW11dGFibGUuIFRoZSBuYW1lIG9mIHRoZSBPZGJTdWJuZXQgYXNzb2NpYXRlZCB3aXRo
IHRoZSBWTQogQ2x1c3RlciBmb3IgSVAgYWxsb2NhdGlvbi4gRm9ybWF0OgogcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29y
a30vb2RiU3VibmV0cy97b2RiX3N1Ym5ldH0KCgwKBQQAAgsFEgN2AggKDAoFBAACCwESA3YJ
EwoMCgUEAAILAxIDdhYYCg0KBQQAAgsIEgR2GXwDCg8KCAQAAgsInAgAEgN3BCoKDwoIBAAC
CwicCAESA3gEKwoPCgcEAAILCJ8IEgR5BHsFCswBCgQEAAIMEgaBAQKHAQQauwEgT3B0aW9u
YWwuIEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIGJhY2t1cCBPZGJTdWJuZXQgYXNzb2Np
YXRlZCB3aXRoIHRoZQogVk0gQ2x1c3Rlci4gRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30vb2RiU3Vi
bmV0cy97b2RiX3N1Ym5ldH0KCg0KBQQAAgwFEgSBAQIICg0KBQQAAgwBEgSBAQkaCg0KBQQA
AgwDEgSBAR0fCg8KBQQAAgwIEgaBASCHAQMKEAoIBAACDAicCAASBIIBBCoKEAoIBAACDAic
CAESBIMBBCsKEQoHBAACDAifCBIGhAEEhgEFCtoBCgQEAAINEgaMAQKSAQQayQEgT3B0aW9u
YWwuIEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIE9kYkRuc1pvbmUgZm9yIHVzaW5nIGN1
c3RvbSBkb21haW4KIG5hbWUgZm9yIHRoZSBWTSBDbHVzdGVyLiBGb3JtYXQ6CiBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vb2RiTmV0d29ya3Mve29kYl9uZXR3
b3JrfS9vZGJEbnNab25lcy97b2RiX2Ruc196b25lfQoKDQoFBAACDQUSBIwBAggKDQoFBAAC
DQESBIwBCRUKDQoFBAACDQMSBIwBGBoKDwoFBAACDQgSBowBG5IBAwoQCggEAAINCJwIABIE
jQEEKgoQCggEAAINCJwIARIEjgEEKwoRCgcEAAINCJ8IEgaPAQSRAQUKjQEKBAQAAg4SBpYB
ApcBMhp9IE91dHB1dCBvbmx5LiBUaGUgaWRlbnRpdHkgY29ubmVjdG9yIGRldGFpbHMgd2hp
Y2ggd2lsbCBhbGxvdyBPQ0kgdG8KIHNlY3VyZWx5IGFjY2VzcyB0aGUgcmVzb3VyY2VzIGlu
IHRoZSBjdXN0b21lciBwcm9qZWN0LgoKDQoFBAACDgYSBJYBAhMKDQoFBAACDgESBJYBFCYK
DQoFBAACDgMSBJYBKSsKDQoFBAACDggSBJcBBjEKEAoIBAACDgicCAASBJcBBzAK0AEKBAQA
Ag8SBpwBAqIBBBq/ASBPcHRpb25hbC4gSW1tdXRhYmxlLiBUaGUgbmFtZSBvZiBFeGFzY2Fs
ZURiU3RvcmFnZVZhdWx0IGFzc29jaWF0ZWQgd2l0aCB0aGUKIFZNIENsdXN0ZXIuIEZvcm1h
dDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9leGFzY2FsZURi
U3RvcmFnZVZhdWx0cy97ZXhhc2NhbGVfZGJfc3RvcmFnZV92YXVsdH0KCg0KBQQAAg8FEgSc
AQIICg0KBQQAAg8BEgScAQkiCg0KBQQAAg8DEgScASUnCg8KBQQAAg8IEgacASiiAQMKEAoI
BAACDwicCAASBJ0BBCoKEAoIBAACDwicCAESBJ4BBCsKEQoHBAACDwifCBIGnwEEoQEFCu4C
CgQEAAIQEgapAQKtAQQa3QIgT3B0aW9uYWwuIElucHV0IG9ubHkuIEltbXV0YWJsZS4gSWYg
c2V0IHRvIHRydWUsIGRpc2FibGVzIHRoZSBhdXRvbWF0aWMKIHByb3Zpc2lvbmluZyBvZiB0
aGUgV29ya2xvYWQgSWRlbnRpdHkgQ29ubmVjdG9yIGR1cmluZyBjcmVhdGlvbi4gSWYgc2V0
IHRvCiBmYWxzZSBvciBvbWl0dGVkLCB0aGUgV29ya2xvYWQgSWRlbnRpdHkgQ29ubmVjdG9y
IHdpbGwgYmUgYXV0b21hdGljYWxseQogcHJvdmlzaW9uZWQgYnkgZGVmYXVsdC4gTm90ZTog
UHJvdmlzaW9uaW5nIHRoZSBXb3JrbG9hZCBJZGVudGl0eSBDb25uZWN0b3IKIGlzIGEgcHJl
cmVxdWlzaXRlIGZvciBlbmFibGluZyBHb29nbGUgQ2xvdWQgQ01FSy4KCg0KBQQAAhAFEgSp
AQIGCg0KBQQAAhABEgSpAQciCg0KBQQAAhADEgSpASUnCg8KBQQAAhAIEgapASitAQMKEAoI
BAACEAicCAASBKoBBCoKEAoIBAACEAicCAESBKsBBCwKEAoIBAACEAicCAISBKwBBCsKUwoC
BAESBrEBAP8CARpFIFZhcmlvdXMgcHJvcGVydGllcyBhbmQgc2V0dGluZ3MgYXNzb2NpYXRl
ZCB3aXRoIEV4YWRhdGEgVk0gY2x1c3Rlci4KCgsKAwQBARIEsQEIIAovCgQEAQQAEgazAQK8
AQMaHyBEaWZmZXJlbnQgbGljZW5zZXMgc3VwcG9ydGVkLgoKDQoFBAEEAAESBLMBBxIKHQoG
BAEEAAIAEgS1AQQhGg0gVW5zcGVjaWZpZWQKCg8KBwQBBAACAAESBLUBBBwKDwoHBAEEAAIA
AhIEtQEfIAowCgYEAQQAAgESBLgBBBkaICBMaWNlbnNlIGluY2x1ZGVkIHBhcnQgb2Ygb2Zm
ZXIKCg8KBwQBBAACAQESBLgBBBQKDwoHBAEEAAIBAhIEuAEXGAooCgYEAQQAAgISBLsBBB8a
GCBCcmluZyB5b3VyIG93biBsaWNlbnNlCgoPCgcEAQQAAgIBEgS7AQQaCg8KBwQBBAACAgIS
BLsBHR4KPgoEBAEEARIGvwECyAEDGi4gVHlwZXMgb2YgZGlzayByZWR1bmRhbmN5IHByb3Zp
ZGVkIGJ5IE9yYWNsZS4KCg0KBQQBBAEBEgS/AQcVCh4KBgQBBAECABIEwQEEJBoOIFVuc3Bl
Y2lmaWVkLgoKDwoHBAEEAQIAARIEwQEEHwoPCgcEAQQBAgACEgTBASIjCicKBgQBBAECARIE
xAEEDRoXIEhpZ2ggLSAgMyB3YXkgbWlycm9yLgoKDwoHBAEEAQIBARIExAEECAoPCgcEAQQB
AgECEgTEAQsMCigKBgQBBAECAhIExwEEDxoYIE5vcm1hbCAtIDIgd2F5IG1pcnJvci4KCg8K
BwQBBAECAgESBMcBBAoKDwoHBAEEAQICAhIExwENDgpBCgQEAQQCEgbLAQLjAQMaMSBUaGUg
dmFyaW91cyBsaWZlY3ljbGUgc3RhdGVzIG9mIHRoZSBWTSBjbHVzdGVyLgoKDQoFBAEEAgES
BMsBBwwKLAoGBAEEAgIAEgTNAQQaGhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg8K
BwQBBAICAAESBM0BBBUKDwoHBAEEAgIAAhIEzQEYGQpHCgYEAQQCAgESBNABBBUaNyBJbmRp
Y2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gcHJvdmlzaW9uaW5nIHN0YXRlLgoKDwoH
BAEEAgIBARIE0AEEEAoPCgcEAQQCAgECEgTQARMUCkQKBgQBBAICAhIE0wEEEho0IEluZGlj
YXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBhdmFpbGFibGUgc3RhdGUuCgoPCgcEAQQC
AgIBEgTTAQQNCg8KBwQBBAICAgISBNMBEBEKQwoGBAEEAgIDEgTWAQQRGjMgSW5kaWNhdGVz
IHRoYXQgdGhlIHJlc291cmNlIGlzIGluIHVwZGF0aW5nIHN0YXRlLgoKDwoHBAEEAgIDARIE
1gEEDAoPCgcEAQQCAgMCEgTWAQ8QCkYKBgQBBAICBBIE2QEEFBo2IEluZGljYXRlcyB0aGF0
IHRoZSByZXNvdXJjZSBpcyBpbiB0ZXJtaW5hdGluZyBzdGF0ZS4KCg8KBwQBBAICBAESBNkB
BA8KDwoHBAEEAgIEAhIE2QESEwpFCgYEAQQCAgUSBNwBBBMaNSBJbmRpY2F0ZXMgdGhhdCB0
aGUgcmVzb3VyY2UgaXMgaW4gdGVybWluYXRlZCBzdGF0ZS4KCg8KBwQBBAICBQESBNwBBA4K
DwoHBAEEAgIFAhIE3AEREgpBCgYEAQQCAgYSBN8BBA8aMSBJbmRpY2F0ZXMgdGhhdCB0aGUg
cmVzb3VyY2UgaXMgaW4gZmFpbGVkIHN0YXRlLgoKDwoHBAEEAgIGARIE3wEECgoPCgcEAQQC
AgYCEgTfAQ0OClIKBgQBBAICBxIE4gEEIBpCIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJj
ZSBpcyBpbiBtYWludGVuYW5jZSBpbiBwcm9ncmVzcyBzdGF0ZS4KCg8KBwQBBAICBwESBOIB
BBsKDwoHBAEEAgIHAhIE4gEeHwpKCgQEAQQDEgbmAQLvAQMaOiBUaGUgdHlwZSBvZiBzdG9y
YWdlIG1hbmFnZW1lbnQgZm9yIHRoZSBDbG91ZCBWTSBDbHVzdGVyLgoKDQoFBAEEAwESBOYB
BxwKNgoGBAEEAwIAEgToAQQsGiYgVW5zcGVjaWZpZWQgc3RvcmFnZSBtYW5hZ2VtZW50IHR5
cGUuCgoPCgcEAQQDAgABEgToAQQnCg8KBwQBBAMCAAISBOgBKisKLwoGBAEEAwIBEgTrAQQM
Gh8gQXV0b21hdGljIFN0b3JhZ2UgTWFuYWdlbWVudC4KCg8KBwQBBAMCAQESBOsBBAcKDwoH
BAEEAwIBAhIE6wEKCwouCgYEAQQDAgISBO4BBBEaHiBFeGFzY2FsZSBzdG9yYWdlIG1hbmFn
ZW1lbnQuCgoPCgcEAQQDAgIBEgTuAQQMCg8KBwQBBAMCAgISBO4BDxAKMwoEBAEEBBIG8gEC
+wEDGiMgU3RvcmFnZSB0eXBlcyBmb3IgVk0gRmlsZSBTeXN0ZW0uCgoNCgUEAQQEARIE8gEH
HgorCgYEAQQEAgASBPQBBDAaGyBVbnNwZWNpZmllZCBzdG9yYWdlIHR5cGUuCgoPCgcEAQQE
AgABEgT0AQQrCg8KBwQBBAQCAAISBPQBLi8KKgoGBAEEBAIBEgT3AQQqGhogTG9jYWwgREIg
c2VydmVyIHN0b3JhZ2UuCgoPCgcEAQQEAgEBEgT3AQQlCg8KBwQBBAQCAQISBPcBKCkKIwoG
BAEEBAICEgT6AQQtGhMgRXhhc2NhbGUgc3RvcmFnZS4KCg8KBwQBBAQCAgESBPoBBCgKDwoH
BAEEBAICAhIE+gErLAouCgQEAQQFEgb+AQKHAgMaHiBTdG9yYWdlIHR5cGVzIGZvciBWTSBC
YWNrdXAuCgoNCgUEAQQFARIE/gEHGgorCgYEAQQFAgASBIACBCsaGyBVbnNwZWNpZmllZCBz
dG9yYWdlIHR5cGUuCgoPCgcEAQQFAgABEgSAAgQmCg8KBwQBBAUCAAISBIACKSoKKgoGBAEE
BQIBEgSDAgQlGhogTG9jYWwgREIgc2VydmVyIHN0b3JhZ2UuCgoPCgcEAQQFAgEBEgSDAgQg
Cg8KBwQBBAUCAQISBIMCIyQKIwoGBAEEBQICEgSGAgQoGhMgRXhhc2NhbGUgc3RvcmFnZS4K
Cg8KBwQBBAUCAgESBIYCBCMKDwoHBAEEBQICAhIEhgImJwpKCgQEAQIAEgSKAgI+GjwgT3V0
cHV0IG9ubHkuIE9yYWNsZSBDbG91ZCBJbmZyYXN0cnVjdHVyZSBJRCBvZiBWTSBDbHVzdGVy
LgoKDQoFBAECAAUSBIoCAggKDQoFBAECAAESBIoCCQ0KDQoFBAECAAMSBIoCEBEKDQoFBAEC
AAgSBIoCEj0KEAoIBAECAAicCAASBIoCEzwKNQoEBAECARIEjQICSBonIFJlcXVpcmVkLiBM
aWNlbnNlIHR5cGUgb2YgVk0gQ2x1c3Rlci4KCg0KBQQBAgEGEgSNAgINCg0KBQQBAgEBEgSN
Ag4aCg0KBQQBAgEDEgSNAh0eCg0KBQQBAgEIEgSNAh9HChAKCAQBAgEInAgAEgSNAiBGCjYK
BAQBAgISBJACAkEaKCBPcHRpb25hbC4gR3JpZCBJbmZyYXN0cnVjdHVyZSBWZXJzaW9uLgoK
DQoFBAECAgUSBJACAggKDQoFBAECAgESBJACCRMKDQoFBAECAgMSBJACFhcKDQoFBAECAggS
BJACGEAKEAoIBAECAgicCAASBJACGT8KWwoEBAECAxIEkwICThpNIE9wdGlvbmFsLiBUaW1l
IHpvbmUgb2YgVk0gQ2x1c3RlciB0byBzZXQuIERlZmF1bHRzIHRvIFVUQyBpZiBub3Qgc3Bl
Y2lmaWVkLgoKDQoFBAECAwYSBJMCAhYKDQoFBAECAwESBJMCFyAKDQoFBAECAwMSBJMCIyQK
DQoFBAECAwgSBJMCJU0KEAoIBAECAwicCAASBJMCJkwKRAoEBAECBBIElgICTxo2IE9wdGlv
bmFsLiBTU0ggcHVibGljIGtleXMgdG8gYmUgc3RvcmVkIHdpdGggY2x1c3Rlci4KCg0KBQQB
AgQEEgSWAgIKCg0KBQQBAgQFEgSWAgsRCg0KBQQBAgQBEgSWAhIhCg0KBQQBAgQDEgSWAiQl
Cg0KBQQBAgQIEgSWAiZOChAKCAQBAgQInAgAEgSWAidNCjUKBAQBAgUSBJkCAkAaJyBPcHRp
b25hbC4gTnVtYmVyIG9mIGRhdGFiYXNlIHNlcnZlcnMuCgoNCgUEAQIFBRIEmQICBwoNCgUE
AQIFARIEmQIIEgoNCgUEAQIFAxIEmQIVFgoNCgUEAQIFCBIEmQIXPwoQCggEAQIFCJwIABIE
mQIYPgoxCgQEAQIGEgScAgI/GiMgT3V0cHV0IG9ubHkuIFNoYXBlIG9mIFZNIENsdXN0ZXIu
CgoNCgUEAQIGBRIEnAICCAoNCgUEAQIGARIEnAIJDgoNCgUEAQIGAxIEnAIREgoNCgUEAQIG
CBIEnAITPgoQCggEAQIGCJwIABIEnAIUPQo8CgQEAQIHEgSfAgJAGi4gT3B0aW9uYWwuIE9D
UFUgY291bnQgcGVyIFZNLiBNaW5pbXVtIGlzIDAuMS4KCg0KBQQBAgcFEgSfAgIHCg0KBQQB
AgcBEgSfAggSCg0KBQQBAgcDEgSfAhUWCg0KBQQBAgcIEgSfAhc/ChAKCAQBAgcInAgAEgSf
Ahg+CjIKBAQBAggSBKICAkQaJCBPcHRpb25hbC4gTWVtb3J5IGFsbG9jYXRlZCBpbiBHQnMu
CgoNCgUEAQIIBRIEogICBwoNCgUEAQIIARIEogIIFgoNCgUEAQIIAxIEogIZGgoNCgUEAQII
CBIEogIbQwoQCggEAQIICJwIABIEogIcQgovCgQEAQIJEgSlAgJOGiEgT3B0aW9uYWwuIExv
Y2FsIHN0b3JhZ2UgcGVyIFZNLgoKDQoFBAECCQUSBKUCAgcKDQoFBAECCQESBKUCCB8KDQoF
BAECCQMSBKUCIiQKDQoFBAECCQgSBKUCJU0KEAoIBAECCQicCAASBKUCJkwKWgoEBAECChIE
qAICSRpMIE91dHB1dCBvbmx5LiBUaGUgc3RvcmFnZSBhbGxvY2F0aW9uIGZvciB0aGUgZGlz
ayBncm91cCwgaW4gZ2lnYWJ5dGVzIChHQikuCgoNCgUEAQIKBRIEqAICBwoNCgUEAQIKARIE
qAIIFwoNCgUEAQIKAxIEqAIaHAoNCgUEAQIKCBIEqAIdSAoQCggEAQIKCJwIABIEqAIeRwpK
CgQEAQILEgSrAgJMGjwgT3B0aW9uYWwuIFRoZSBkYXRhIGRpc2sgZ3JvdXAgc2l6ZSB0byBi
ZSBhbGxvY2F0ZWQgaW4gVEJzLgoKDQoFBAECCwUSBKsCAggKDQoFBAECCwESBKsCCR0KDQoF
BAECCwMSBKsCICIKDQoFBAECCwgSBKsCI0sKEAoIBAECCwicCAASBKsCJEoKMQoEBAECDBIE
rgICTxojIE9wdGlvbmFsLiBUaGUgdHlwZSBvZiByZWR1bmRhbmN5LgoKDQoFBAECDAYSBK4C
AhAKDQoFBAECDAESBK4CESAKDQoFBAECDAMSBK4CIyUKDQoFBAECDAgSBK4CJk4KEAoIBAEC
DAicCAASBK4CJ00KNwoEBAECDRIEsQICThopIE9wdGlvbmFsLiBVc2UgZXhhZGF0YSBzcGFy
c2Ugc25hcHNob3RzLgoKDQoFBAECDQUSBLECAgYKDQoFBAECDQESBLECBx8KDQoFBAECDQMS
BLECIiQKDQoFBAECDQgSBLECJU0KEAoIBAECDQicCAASBLECJkwKKwoEBAECDhIEtAICShod
IE9wdGlvbmFsLiBVc2UgbG9jYWwgYmFja3VwLgoKDQoFBAECDgUSBLQCAgYKDQoFBAECDgES
BLQCBxsKDQoFBAECDgMSBLQCHiAKDQoFBAECDggSBLQCIUkKEAoIBAECDgicCAASBLQCIkgK
OwoEBAECDxIEtwICRxotIE9wdGlvbmFsLiBQcmVmaXggZm9yIFZNIGNsdXN0ZXIgaG9zdCBu
YW1lcy4KCg0KBQQBAg8FEgS3AgIICg0KBQQBAg8BEgS3AgkYCg0KBQQBAg8DEgS3AhsdCg0K
BQQBAg8IEgS3Ah5GChAKCAQBAg8InAgAEgS3Ah9FCkQKBAQBAhASBroCArsCLxo0IE9wdGlv
bmFsLiBEYXRhIGNvbGxlY3Rpb24gb3B0aW9ucyBmb3IgZGlhZ25vc3RpY3MuCgoNCgUEAQIQ
BhIEugICFwoNCgUEAQIQARIEugIYOwoNCgUEAQIQAxIEugI+QAoNCgUEAQIQCBIEuwIGLgoQ
CggEAQIQCJwIABIEuwIHLQoyCgQEAQIREgS+AgI/GiQgT3V0cHV0IG9ubHkuIFN0YXRlIG9m
IHRoZSBjbHVzdGVyLgoKDQoFBAECEQYSBL4CAgcKDQoFBAECEQESBL4CCA0KDQoFBAECEQMS
BL4CEBIKDQoFBAECEQgSBL4CEz4KEAoIBAECEQicCAASBL4CFD0KMgoEBAECEhIEwQICTRok
IE9wdGlvbmFsLiBTQ0FOIGxpc3RlbmVyIHBvcnQgLSBUQ1AKCg0KBQQBAhIFEgTBAgIHCg0K
BQQBAhIBEgTBAggeCg0KBQQBAhIDEgTBAiEjCg0KBQQBAhIIEgTBAiRMChAKCAQBAhIInAgA
EgTBAiVLCjQKBAQBAhMSBsQCAsUCLxokIE9wdGlvbmFsLiBTQ0FOIGxpc3RlbmVyIHBvcnQg
LSBUTFMKCg0KBQQBAhMFEgTEAgIHCg0KBQQBAhMBEgTEAggiCg0KBQQBAhMDEgTEAiUnCg0K
BQQBAhMIEgTFAgYuChAKCAQBAhMInAgAEgTFAgctCosBCgQEAQIUEgTJAgJBGn0gT3V0cHV0
IG9ubHkuIFBhcmVudCBETlMgZG9tYWluIHdoZXJlIFNDQU4gRE5TIGFuZCBob3N0cyBuYW1l
cyBhcmUKIHF1YWxpZmllZC4gZXg6IG9jaXNwZGVsZWdhdGVkLm9jaXNwMTBqdm5ldC5vcmFj
bGV2Y24uY29tCgoNCgUEAQIUBRIEyQICCAoNCgUEAQIUARIEyQIJDwoNCgUEAQIUAxIEyQIS
FAoNCgUEAQIUCBIEyQIVQAoQCggEAQIUCJwIABIEyQIWPwppCgQEAQIVEgTNAgJDGlsgT3V0
cHV0IG9ubHkuIFNDQU4gRE5TIG5hbWUuCiBleDogc3AyLXlpMHhxLXNjYW4ub2Npc3BkZWxl
Z2F0ZWQub2Npc3AxMGp2bmV0Lm9yYWNsZXZjbi5jb20KCg0KBQQBAhUFEgTNAgIICg0KBQQB
AhUBEgTNAgkRCg0KBQQBAhUDEgTNAhQWCg0KBQQBAhUIEgTNAhdCChAKCAQBAhUInAgAEgTN
AhhBCpoBCgQEAQIWEgTSAgJDGosBIE91dHB1dCBvbmx5LiBob3N0IG5hbWUgd2l0aG91dCBk
b21haW4uCiBmb3JtYXQ6ICI8aG9zdG5hbWVfcHJlZml4Pi0iIHdpdGggc29tZSBzdWZmaXgu
CiBleDogc3AyLXlpMHhxIHdoZXJlICJzcDIiIGlzIHRoZSBob3N0bmFtZV9wcmVmaXguCgoN
CgUEAQIWBRIE0gICCAoNCgUEAQIWARIE0gIJEQoNCgUEAQIWAxIE0gIUFgoNCgUEAQIWCBIE
0gIXQgoQCggEAQIWCJwIABIE0gIYQQo2CgQEAQIXEgTVAgJFGiggUmVxdWlyZWQuIE51bWJl
ciBvZiBlbmFibGVkIENQVSBjb3Jlcy4KCg0KBQQBAhcFEgTVAgIHCg0KBQQBAhcBEgTVAggW
Cg0KBQQBAhcDEgTVAhkbCg0KBQQBAhcIEgTVAhxEChAKCAQBAhcInAgAEgTVAh1DCkAKBAQB
AhgSBNgCAkYaMiBPcHRpb25hbC4gT3BlcmF0aW5nIHN5c3RlbSB2ZXJzaW9uIG9mIHRoZSBp
bWFnZS4KCg0KBQQBAhgFEgTYAgIICg0KBQQBAhgBEgTYAgkXCg0KBQQBAhgDEgTYAhocCg0K
BQQBAhgIEgTYAh1FChAKCAQBAhgInAgAEgTYAh5ECi8KBAQBAhkSBNsCAk8aISBPdXRwdXQg
b25seS4gT0NJRHMgb2Ygc2NhbiBJUHMuCgoNCgUEAQIZBBIE2wICCgoNCgUEAQIZBRIE2wIL
EQoNCgUEAQIZARIE2wISHQoNCgUEAQIZAxIE2wIgIgoNCgUEAQIZCBIE2wIjTgoQCggEAQIZ
CJwIABIE2wIkTQo1CgQEAQIaEgTeAgJNGicgT3V0cHV0IG9ubHkuIE9DSUQgb2Ygc2NhbiBE
TlMgcmVjb3JkLgoKDQoFBAECGgUSBN4CAggKDQoFBAECGgESBN4CCRsKDQoFBAECGgMSBN4C
HiAKDQoFBAECGggSBN4CIUwKEAoIBAECGgicCAASBN4CIksKUAoEBAECGxIE4QICQhpCIE91
dHB1dCBvbmx5LiBEZWVwIGxpbmsgdG8gdGhlIE9DSSBjb25zb2xlIHRvIHZpZXcgdGhpcyBy
ZXNvdXJjZS4KCg0KBQQBAhsFEgThAgIICg0KBQQBAhsBEgThAgkQCg0KBQQBAhsDEgThAhMV
Cg0KBQQBAhsIEgThAhZBChAKCAQBAhsInAgAEgThAhdACjMKBAQBAhwSBOQCAlAaJSBPcHRp
b25hbC4gT0NJRCBvZiBkYXRhYmFzZSBzZXJ2ZXJzLgoKDQoFBAECHAQSBOQCAgoKDQoFBAEC
HAUSBOQCCxEKDQoFBAECHAESBOQCEiEKDQoFBAECHAMSBOQCJCYKDQoFBAECHAgSBOQCJ08K
EAoIBAECHAicCAASBOQCKE4KNwoEBAECHRIE5wICSRopIE91dHB1dCBvbmx5LiBDb21wYXJ0
bWVudCBJRCBvZiBjbHVzdGVyLgoKDQoFBAECHQUSBOcCAggKDQoFBAECHQESBOcCCRcKDQoF
BAECHQMSBOcCGhwKDQoFBAECHQgSBOcCHUgKEAoIBAECHQicCAASBOcCHkcKLQoEBAECHhIE
6gICShofIE91dHB1dCBvbmx5LiBETlMgbGlzdGVuZXIgSVAuCgoNCgUEAQIeBRIE6gICCAoN
CgUEAQIeARIE6gIJGAoNCgUEAQIeAxIE6gIbHQoNCgUEAQIeCBIE6gIeSQoQCggEAQIeCJwI
ABIE6gIfSAorCgQEAQIfEgTtAgJEGh0gT3B0aW9uYWwuIE9DSSBDbHVzdGVyIG5hbWUuCgoN
CgUEAQIfBRIE7QICCAoNCgUEAQIfARIE7QIJFQoNCgUEAQIfAxIE7QIYGgoNCgUEAQIfCBIE
7QIbQwoQCggEAQIfCJwIABIE7QIcQgpBCgQEAQIgEgTwAgJOGjMgT3V0cHV0IG9ubHkuIFRo
ZSBjb21wdXRlIG1vZGVsIG9mIHRoZSBWTSBDbHVzdGVyLgoKDQoFBAECIAYSBPACAg4KDQoF
BAECIAESBPACDxwKDQoFBAECIAMSBPACHyEKDQoFBAECIAgSBPACIk0KEAoIBAECIAicCAAS
BPACI0wKTQoEBAECIRIG8wIC9AIyGj0gT3V0cHV0IG9ubHkuIFRoZSBzdG9yYWdlIG1hbmFn
ZW1lbnQgdHlwZSBvZiB0aGUgVk0gQ2x1c3Rlci4KCg0KBQQBAiEGEgTzAgIXCg0KBQQBAiEB
EgTzAhgvCg0KBQQBAiEDEgTzAjI0Cg0KBQQBAiEIEgT0AgYxChAKCAQBAiEInAgAEgT0Agcw
CowBCgQEAQIiEgb4AgL5Ai8afCBPcHRpb25hbC4gU3BlY2lmaWVzIHdoZXRoZXIgVk0gZmls
ZSBzeXN0ZW0gc3RvcmFnZSAvIFZNIGltYWdlcyBhcmUgc3RvcmVkCiBvbiBsb2NhbCBEQiBz
ZXJ2ZXIgc3RvcmFnZSBvciBFeGFzY2FsZSBzdG9yYWdlLgoKDQoFBAECIgYSBPgCAhkKDQoF
BAECIgESBPgCGjUKDQoFBAECIgMSBPgCODoKDQoFBAECIggSBPkCBi4KEAoIBAECIgicCAAS
BPkCBy0KdAoEBAECIxIG/QIC/gIvGmQgT3B0aW9uYWwuIFNwZWNpZmllcyB3aGV0aGVyIFZN
IGJhY2t1cHMgYXJlIHN0b3JlZCBvbiBsb2NhbCBEQiBzZXJ2ZXIKIHN0b3JhZ2Ugb3IgRXhh
c2NhbGUgc3RvcmFnZS4KCg0KBQQBAiMGEgT9AgIVCg0KBQQBAiMBEgT9AhYsCg0KBQQBAiMD
EgT9Ai8xCg0KBQQBAiMIEgT+AgYuChAKCAQBAiMInAgAEgT+AgctCjgKAgQCEgaCAwCNAwEa
KiBEYXRhIGNvbGxlY3Rpb24gb3B0aW9ucyBmb3IgZGlhZ25vc3RpY3MuCgoLCgMEAgESBIID
CB0KYAoEBAICABIEhQMCTxpSIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciBkaWFnbm9z
dGljIGNvbGxlY3Rpb24gaXMgZW5hYmxlZCBmb3IgdGhlIFZNCiBjbHVzdGVyCgoNCgUEAgIA
BRIEhQMCBgoNCgUEAgIAARIEhQMHIQoNCgUEAgIAAxIEhQMkJQoNCgUEAgIACBIEhQMmTgoQ
CggEAgIACJwIABIEhQMnTQpbCgQEAgIBEgSIAwJOGk0gT3B0aW9uYWwuIEluZGljYXRlcyB3
aGV0aGVyIGhlYWx0aCBtb25pdG9yaW5nIGlzIGVuYWJsZWQgZm9yIHRoZSBWTSBjbHVzdGVy
CgoNCgUEAgIBBRIEiAMCBgoNCgUEAgIBARIEiAMHIAoNCgUEAgIBAxIEiAMjJAoNCgUEAgIB
CBIEiAMlTQoQCggEAgIBCJwIABIEiAMmTApuCgQEAgICEgSMAwJKGmAgT3B0aW9uYWwuIElu
ZGljYXRlcyB3aGV0aGVyIGluY2lkZW50IGxvZ3MgYW5kIHRyYWNlIGNvbGxlY3Rpb24gYXJl
IGVuYWJsZWQKIGZvciB0aGUgVk0gY2x1c3RlcgoKDQoFBAICAgUSBIwDAgYKDQoFBAICAgES
BIwDBxwKDQoFBAICAgMSBIwDHyAKDQoFBAICAggSBIwDIUkKEAoIBAICAgicCAASBIwDIkhi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster ===
    # Fields for CloudVmCluster
    # Field: name Type: 9 ()
    # Field: exadata_infrastructure Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties)
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.CloudVmCluster.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: cidr Type: 9 ()
    # Field: backup_subnet_cidr Type: 9 ()
    # Field: network Type: 9 ()
    # Field: gcp_oracle_zone Type: 9 ()
    # Field: odb_network Type: 9 ()
    # Field: odb_subnet Type: 9 ()
    # Field: backup_odb_subnet Type: 9 ()
    # Field: odb_dns_zone Type: 9 ()
    # Field: identity_connector Type: 11 (.google.cloud.oracledatabase.v1.IdentityConnector)
    # Field: exascale_db_storage_vault Type: 9 ()
    # Field: identity_connector_disabled Type: 8 ()

# === Message: Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmClusterProperties ===
    # Fields for CloudVmClusterProperties
    # Field: ocid Type: 9 ()
    # Field: license_type Type: 14 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties.LicenseType)
    # Field: gi_version Type: 9 ()
    # Field: time_zone Type: 11 (.google.type.TimeZone)
    # Field: ssh_public_keys Type: 9 ()
    # Field: node_count Type: 5 ()
    # Field: shape Type: 9 ()
    # Field: ocpu_count Type: 2 ()
    # Field: memory_size_gb Type: 5 ()
    # Field: db_node_storage_size_gb Type: 5 ()
    # Field: storage_size_gb Type: 5 ()
    # Field: data_storage_size_tb Type: 1 ()
    # Field: disk_redundancy Type: 14 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties.DiskRedundancy)
    # Field: sparse_diskgroup_enabled Type: 8 ()
    # Field: local_backup_enabled Type: 8 ()
    # Field: hostname_prefix Type: 9 ()
    # Field: diagnostics_data_collection_options Type: 11 (.google.cloud.oracledatabase.v1.DataCollectionOptions)
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties.State)
    # Field: scan_listener_port_tcp Type: 5 ()
    # Field: scan_listener_port_tcp_ssl Type: 5 ()
    # Field: domain Type: 9 ()
    # Field: scan_dns Type: 9 ()
    # Field: hostname Type: 9 ()
    # Field: cpu_core_count Type: 5 ()
    # Field: system_version Type: 9 ()
    # Field: scan_ip_ids Type: 9 ()
    # Field: scan_dns_record_id Type: 9 ()
    # Field: oci_url Type: 9 ()
    # Field: db_server_ocids Type: 9 ()
    # Field: compartment_id Type: 9 ()
    # Field: dns_listener_ip Type: 9 ()
    # Field: cluster_name Type: 9 ()
    # Field: compute_model Type: 14 (.google.cloud.oracledatabase.v1.ComputeModel)
    # Field: storage_management_type Type: 14 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties.StorageManagementType)
    # Field: vm_file_system_storage_type Type: 14 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties.VmFileSystemStorageType)
    # Field: vm_backup_storage_type Type: 14 (.google.cloud.oracledatabase.v1.CloudVmClusterProperties.VmBackupStorageType)

# Enum: CloudVmClusterProperties::LicenseType
our $CloudVmClusterProperties_LICENSE_TYPE_UNSPECIFIED = 0;
our $CloudVmClusterProperties_LICENSE_INCLUDED = 1;
our $CloudVmClusterProperties_BRING_YOUR_OWN_LICENSE = 2;

# Enum: CloudVmClusterProperties::DiskRedundancy
our $CloudVmClusterProperties_DISK_REDUNDANCY_UNSPECIFIED = 0;
our $CloudVmClusterProperties_HIGH = 1;
our $CloudVmClusterProperties_NORMAL = 2;

# Enum: CloudVmClusterProperties::State
our $CloudVmClusterProperties_STATE_UNSPECIFIED = 0;
our $CloudVmClusterProperties_PROVISIONING = 1;
our $CloudVmClusterProperties_AVAILABLE = 2;
our $CloudVmClusterProperties_UPDATING = 3;
our $CloudVmClusterProperties_TERMINATING = 4;
our $CloudVmClusterProperties_TERMINATED = 5;
our $CloudVmClusterProperties_FAILED = 6;
our $CloudVmClusterProperties_MAINTENANCE_IN_PROGRESS = 7;

# Enum: CloudVmClusterProperties::StorageManagementType
our $CloudVmClusterProperties_STORAGE_MANAGEMENT_TYPE_UNSPECIFIED = 0;
our $CloudVmClusterProperties_ASM = 1;
our $CloudVmClusterProperties_EXASCALE = 2;

# Enum: CloudVmClusterProperties::VmFileSystemStorageType
our $CloudVmClusterProperties_VM_FILE_SYSTEM_STORAGE_TYPE_UNSPECIFIED = 0;
our $CloudVmClusterProperties_VM_FILE_SYSTEM_STORAGE_TYPE_LOCAL = 1;
our $CloudVmClusterProperties_VM_FILE_SYSTEM_STORAGE_TYPE_EXASCALE = 2;

# Enum: CloudVmClusterProperties::VmBackupStorageType
our $CloudVmClusterProperties_VM_BACKUP_STORAGE_TYPE_UNSPECIFIED = 0;
our $CloudVmClusterProperties_VM_BACKUP_STORAGE_TYPE_LOCAL = 1;
our $CloudVmClusterProperties_VM_BACKUP_STORAGE_TYPE_EXASCALE = 2;

# === Message: Google::Cloud::Oracledatabase::V1::VmCluster::DataCollectionOptions ===
    # Fields for DataCollectionOptions
    # Field: diagnostics_events_enabled Type: 8 ()
    # Field: health_monitoring_enabled Type: 8 ()
    # Field: incident_logs_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::VmCluster - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/vm_cluster.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::VmCluster;

    my $msg = Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster->new({
        name => $name,
        exadata_infrastructure => $exadata_infrastructure,
        display_name => $display_name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/vm_cluster.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster

Details of the Cloud VM Cluster resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/CloudVmCluster/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the VM Cluster resource with the format:
projects/{project}/locations/{region}/cloudVmClusters/{cloud_vm_cluster}

=item * C<< $msg->exadata_infrastructure() >> / C<< $msg->exadata_infrastructure($value) >>

Type: C<String>

Required. Immutable. The name of the Exadata Infrastructure resource on
which VM cluster resource is created, in the following format:
projects/{project}/locations/{region}/cloudExadataInfrastuctures/{cloud_extradata_infrastructure}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Immutable. User friendly name for this resource.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmClusterProperties>)

Optional. Immutable. Various properties of the VM Cluster.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster::LabelsEntry>)

Optional. Labels or tags associated with the VM Cluster.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the VM cluster was created.

=item * C<< $msg->cidr() >> / C<< $msg->cidr($value) >>

Type: C<String>

Optional. Immutable. Network settings. CIDR to use for cluster IP
allocation.

=item * C<< $msg->backup_subnet_cidr() >> / C<< $msg->backup_subnet_cidr($value) >>

Type: C<String>

Optional. Immutable. CIDR range of the backup subnet.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Optional. Immutable. The name of the VPC network.
Format: projects/{project}/global/networks/{network}

=item * C<< $msg->gcp_oracle_zone() >> / C<< $msg->gcp_oracle_zone($value) >>

Type: C<String>

Output only. The GCP Oracle zone where Oracle CloudVmCluster is hosted.
This will be the same as the gcp_oracle_zone of the
CloudExadataInfrastructure. Example: us-east4-b-r2.

=item * C<< $msg->odb_network() >> / C<< $msg->odb_network($value) >>

Type: C<String>

Optional. Immutable. The name of the OdbNetwork associated with the VM
Cluster. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}
It is optional but if specified, this should match the parent ODBNetwork of
the odb_subnet and backup_odb_subnet.

=item * C<< $msg->odb_subnet() >> / C<< $msg->odb_subnet($value) >>

Type: C<String>

Optional. Immutable. The name of the OdbSubnet associated with the VM
Cluster for IP allocation. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}

=item * C<< $msg->backup_odb_subnet() >> / C<< $msg->backup_odb_subnet($value) >>

Type: C<String>

Optional. Immutable. The name of the backup OdbSubnet associated with the
VM Cluster. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}

=item * C<< $msg->odb_dns_zone() >> / C<< $msg->odb_dns_zone($value) >>

Type: C<String>

Optional. Immutable. The name of the OdbDnsZone for using custom domain
name for the VM Cluster. Format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbDnsZones/{odb_dns_zone}

=item * C<< $msg->identity_connector() >> / C<< $msg->identity_connector($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Common::IdentityConnector>)

Output only. The identity connector details which will allow OCI to
securely access the resources in the customer project.

=item * C<< $msg->exascale_db_storage_vault() >> / C<< $msg->exascale_db_storage_vault($value) >>

Type: C<String>

Optional. Immutable. The name of ExascaleDbStorageVault associated with the
VM Cluster. Format:
projects/{project}/locations/{location}/exascaleDbStorageVaults/{exascale_db_storage_vault}

=item * C<< $msg->identity_connector_disabled() >> / C<< $msg->identity_connector_disabled($value) >>

Type: C<Bool>

Optional. Input only. Immutable. If set to true, disables the automatic
provisioning of the Workload Identity Connector during creation. If set to
false or omitted, the Workload Identity Connector will be automatically
provisioned by default. Note: Provisioning the Workload Identity Connector
is a prerequisite for enabling Google Cloud CMEK.

=back

=head2 Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmClusterProperties

Various properties and settings associated with Exadata VM cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. Oracle Cloud Infrastructure ID of VM Cluster.

=item * C<< $msg->license_type() >> / C<< $msg->license_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudVmClusterProperties::LicenseType>)

Required. License type of VM Cluster.

=item * C<< $msg->gi_version() >> / C<< $msg->gi_version($value) >>

Type: C<String>

Optional. Grid Infrastructure Version.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<Message> (L<Google::Type::Datetime::TimeZone>)

Optional. Time zone of VM Cluster to set. Defaults to UTC if not specified.

=item * C<< $msg->ssh_public_keys() >> / C<< $msg->ssh_public_keys($value) >>

Type: C<String>

Optional. SSH public keys to be stored with cluster.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int32>

Optional. Number of database servers.

=item * C<< $msg->shape() >> / C<< $msg->shape($value) >>

Type: C<String>

Output only. Shape of VM Cluster.

=item * C<< $msg->ocpu_count() >> / C<< $msg->ocpu_count($value) >>

Type: C<Float>

Optional. OCPU count per VM. Minimum is 0.1.

=item * C<< $msg->memory_size_gb() >> / C<< $msg->memory_size_gb($value) >>

Type: C<Int32>

Optional. Memory allocated in GBs.

=item * C<< $msg->db_node_storage_size_gb() >> / C<< $msg->db_node_storage_size_gb($value) >>

Type: C<Int32>

Optional. Local storage per VM.

=item * C<< $msg->storage_size_gb() >> / C<< $msg->storage_size_gb($value) >>

Type: C<Int32>

Output only. The storage allocation for the disk group, in gigabytes (GB).

=item * C<< $msg->data_storage_size_tb() >> / C<< $msg->data_storage_size_tb($value) >>

Type: C<Double>

Optional. The data disk group size to be allocated in TBs.

=item * C<< $msg->disk_redundancy() >> / C<< $msg->disk_redundancy($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudVmClusterProperties::DiskRedundancy>)

Optional. The type of redundancy.

=item * C<< $msg->sparse_diskgroup_enabled() >> / C<< $msg->sparse_diskgroup_enabled($value) >>

Type: C<Bool>

Optional. Use exadata sparse snapshots.

=item * C<< $msg->local_backup_enabled() >> / C<< $msg->local_backup_enabled($value) >>

Type: C<Bool>

Optional. Use local backup.

=item * C<< $msg->hostname_prefix() >> / C<< $msg->hostname_prefix($value) >>

Type: C<String>

Optional. Prefix for VM cluster host names.

=item * C<< $msg->diagnostics_data_collection_options() >> / C<< $msg->diagnostics_data_collection_options($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::VmCluster::DataCollectionOptions>)

Optional. Data collection options for diagnostics.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudVmClusterProperties::State>)

Output only. State of the cluster.

=item * C<< $msg->scan_listener_port_tcp() >> / C<< $msg->scan_listener_port_tcp($value) >>

Type: C<Int32>

Optional. SCAN listener port - TCP

=item * C<< $msg->scan_listener_port_tcp_ssl() >> / C<< $msg->scan_listener_port_tcp_ssl($value) >>

Type: C<Int32>

Optional. SCAN listener port - TLS

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

Output only. Parent DNS domain where SCAN DNS and hosts names are
qualified. ex: ocispdelegated.ocisp10jvnet.oraclevcn.com

=item * C<< $msg->scan_dns() >> / C<< $msg->scan_dns($value) >>

Type: C<String>

Output only. SCAN DNS name.
ex: sp2-yi0xq-scan.ocispdelegated.ocisp10jvnet.oraclevcn.com

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

Output only. host name without domain.
format: "<hostname_prefix>-" with some suffix.
ex: sp2-yi0xq where "sp2" is the hostname_prefix.

=item * C<< $msg->cpu_core_count() >> / C<< $msg->cpu_core_count($value) >>

Type: C<Int32>

Required. Number of enabled CPU cores.

=item * C<< $msg->system_version() >> / C<< $msg->system_version($value) >>

Type: C<String>

Optional. Operating system version of the image.

=item * C<< $msg->scan_ip_ids() >> / C<< $msg->scan_ip_ids($value) >>

Type: C<String>

Output only. OCIDs of scan IPs.

=item * C<< $msg->scan_dns_record_id() >> / C<< $msg->scan_dns_record_id($value) >>

Type: C<String>

Output only. OCID of scan DNS record.

=item * C<< $msg->oci_url() >> / C<< $msg->oci_url($value) >>

Type: C<String>

Output only. Deep link to the OCI console to view this resource.

=item * C<< $msg->db_server_ocids() >> / C<< $msg->db_server_ocids($value) >>

Type: C<String>

Optional. OCID of database servers.

=item * C<< $msg->compartment_id() >> / C<< $msg->compartment_id($value) >>

Type: C<String>

Output only. Compartment ID of cluster.

=item * C<< $msg->dns_listener_ip() >> / C<< $msg->dns_listener_ip($value) >>

Type: C<String>

Output only. DNS listener IP.

=item * C<< $msg->cluster_name() >> / C<< $msg->cluster_name($value) >>

Type: C<String>

Optional. OCI Cluster name.

=item * C<< $msg->compute_model() >> / C<< $msg->compute_model($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ComputeModel>)

Output only. The compute model of the VM Cluster.

=item * C<< $msg->storage_management_type() >> / C<< $msg->storage_management_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudVmClusterProperties::StorageManagementType>)

Output only. The storage management type of the VM Cluster.

=item * C<< $msg->vm_file_system_storage_type() >> / C<< $msg->vm_file_system_storage_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudVmClusterProperties::VmFileSystemStorageType>)

Optional. Specifies whether VM file system storage / VM images are stored
on local DB server storage or Exascale storage.

=item * C<< $msg->vm_backup_storage_type() >> / C<< $msg->vm_backup_storage_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudVmClusterProperties::VmBackupStorageType>)

Optional. Specifies whether VM backups are stored on local DB server
storage or Exascale storage.

=back

=head3 Enum: CloudVmClusterProperties::LicenseType

=over 4

=item * C<LICENSE_TYPE_UNSPECIFIED> => C<0>

=item * C<LICENSE_INCLUDED> => C<1>

=item * C<BRING_YOUR_OWN_LICENSE> => C<2>

=back

=head3 Enum: CloudVmClusterProperties::DiskRedundancy

=over 4

=item * C<DISK_REDUNDANCY_UNSPECIFIED> => C<0>

=item * C<HIGH> => C<1>

=item * C<NORMAL> => C<2>

=back

=head3 Enum: CloudVmClusterProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<TERMINATING> => C<4>

=item * C<TERMINATED> => C<5>

=item * C<FAILED> => C<6>

=item * C<MAINTENANCE_IN_PROGRESS> => C<7>

=back

=head3 Enum: CloudVmClusterProperties::StorageManagementType

=over 4

=item * C<STORAGE_MANAGEMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<ASM> => C<1>

=item * C<EXASCALE> => C<2>

=back

=head3 Enum: CloudVmClusterProperties::VmFileSystemStorageType

=over 4

=item * C<VM_FILE_SYSTEM_STORAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<VM_FILE_SYSTEM_STORAGE_TYPE_LOCAL> => C<1>

=item * C<VM_FILE_SYSTEM_STORAGE_TYPE_EXASCALE> => C<2>

=back

=head3 Enum: CloudVmClusterProperties::VmBackupStorageType

=over 4

=item * C<VM_BACKUP_STORAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<VM_BACKUP_STORAGE_TYPE_LOCAL> => C<1>

=item * C<VM_BACKUP_STORAGE_TYPE_EXASCALE> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::VmCluster::DataCollectionOptions

Data collection options for diagnostics.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->diagnostics_events_enabled() >> / C<< $msg->diagnostics_events_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether diagnostic collection is enabled for the VM
cluster

=item * C<< $msg->health_monitoring_enabled() >> / C<< $msg->health_monitoring_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether health monitoring is enabled for the VM cluster

=item * C<< $msg->incident_logs_enabled() >> / C<< $msg->incident_logs_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether incident logs and trace collection are enabled
for the VM cluster

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::VmCluster::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
