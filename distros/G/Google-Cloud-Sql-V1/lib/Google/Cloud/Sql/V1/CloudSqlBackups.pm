package Google::Cloud::Sql::V1::CloudSqlBackups;

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
    eval { require Google::Cloud::Sql::V1::CloudSqlBackupRuns };
    eval { require Google::Cloud::Sql::V1::CloudSqlInstances };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Protobuf::Wrappers };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9iYWNrdXBzLnByb3RvEhNnb29nbGUu
Y2xvdWQuc3FsLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxovZ29vZ2xlL2Nsb3VkL3NxbC92MS9jbG91ZF9zcWxfYmFj
a3VwX3J1bnMucHJvdG8aLWdvb2dsZS9jbG91ZC9zcWwvdjEvY2xvdWRfc3FsX2luc3RhbmNl
cy5wcm90bxotZ29vZ2xlL2Nsb3VkL3NxbC92MS9jbG91ZF9zcWxfcmVzb3VyY2VzLnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnByb3RvGhpnb29nbGUv
dHlwZS9pbnRlcnZhbC5wcm90byKPAQoTQ3JlYXRlQmFja3VwUmVxdWVzdBI+CgZwYXJlbnQY
ASABKAlCJuBBAvpBIBIec3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vQmFja3VwUgZwYXJlbnQS
OAoGYmFja3VwGAIgASgLMhsuZ29vZ2xlLmNsb3VkLnNxbC52MS5CYWNrdXBCA+BBAlIGYmFj
a3VwIk4KEEdldEJhY2t1cFJlcXVlc3QSOgoEbmFtZRgBIAEoCUIm4EEC+kEgCh5zcWxhZG1p
bi5nb29nbGVhcGlzLmNvbS9CYWNrdXBSBG5hbWUiqAEKEkxpc3RCYWNrdXBzUmVxdWVzdBI+
CgZwYXJlbnQYASABKAlCJuBBAvpBIBIec3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vQmFja3Vw
UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMg
ASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXIisQEKE0xpc3RCYWNrdXBz
UmVzcG9uc2USNQoHYmFja3VwcxgBIAMoCzIbLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3Vw
UgdiYWNrdXBzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhI7Cgh3
YXJuaW5ncxgDIAMoCzIfLmdvb2dsZS5jbG91ZC5zcWwudjEuQXBpV2FybmluZ1IId2Fybmlu
Z3MijAEKE1VwZGF0ZUJhY2t1cFJlcXVlc3QSOAoGYmFja3VwGAEgASgLMhsuZ29vZ2xlLmNs
b3VkLnNxbC52MS5CYWNrdXBCA+BBAlIGYmFja3VwEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJRChNEZWxldGVCYWNrdXBS
ZXF1ZXN0EjoKBG5hbWUYASABKAlCJuBBAvpBIAoec3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20v
QmFja3VwUgRuYW1lIrQMCgZCYWNrdXASFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEhcKBGtp
bmQYAiABKAlCA+BBA1IEa2luZBIgCglzZWxmX2xpbmsYAyABKAlCA+BBA1IIc2VsZkxpbmsS
QgoEdHlwZRgEIAEoDjIpLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3VwLlNxbEJhY2t1cFR5
cGVCA+BBA1IEdHlwZRIgCgtkZXNjcmlwdGlvbhgFIAEoCVILZGVzY3JpcHRpb24SGgoIaW5z
dGFuY2UYBiABKAlSCGluc3RhbmNlEhoKCGxvY2F0aW9uGAcgASgJUghsb2NhdGlvbhJDCg9i
YWNrdXBfaW50ZXJ2YWwYCCABKAsyFS5nb29nbGUudHlwZS5JbnRlcnZhbEID4EEDUg5iYWNr
dXBJbnRlcnZhbBJFCgVzdGF0ZRgJIAEoDjIqLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3Vw
LlNxbEJhY2t1cFN0YXRlQgPgQQNSBXN0YXRlEj4KBWVycm9yGAogASgLMiMuZ29vZ2xlLmNs
b3VkLnNxbC52MS5PcGVyYXRpb25FcnJvckID4EEDUgVlcnJvchIcCgdrbXNfa2V5GAsgASgJ
QgPgQQNSBmttc0tleRIrCg9rbXNfa2V5X3ZlcnNpb24YDCABKAlCA+BBA1INa21zS2V5VmVy
c2lvbhJICgtiYWNrdXBfa2luZBgNIAEoDjIiLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsQmFj
a3VwS2luZEID4EEDUgpiYWNrdXBLaW5kEiAKCXRpbWVfem9uZRgPIAEoCUID4EEDUgh0aW1l
Wm9uZRIgCgh0dGxfZGF5cxgQIAEoA0ID4EEESABSB3R0bERheXMSPQoLZXhwaXJ5X3RpbWUY
ESABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSCmV4cGlyeVRpbWUSVwoQZGF0
YWJhc2VfdmVyc2lvbhgUIAEoDjInLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsRGF0YWJhc2VW
ZXJzaW9uQgPgQQNSD2RhdGFiYXNlVmVyc2lvbhI6ChRtYXhfY2hhcmdlYWJsZV9ieXRlcxgX
IAEoA0ID4EEDSAFSEm1heENoYXJnZWFibGVCeXRlc4gBARJYChZpbnN0YW5jZV9kZWxldGlv
bl90aW1lGBggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEIG4EEB4EEDUhRpbnN0
YW5jZURlbGV0aW9uVGltZRJaChFpbnN0YW5jZV9zZXR0aW5ncxgZIAEoCzIlLmdvb2dsZS5j
bG91ZC5zcWwudjEuRGF0YWJhc2VJbnN0YW5jZUIG4EEB4EEDUhBpbnN0YW5jZVNldHRpbmdz
EiIKCmJhY2t1cF9ydW4YGiABKAlCA+BBA1IJYmFja3VwUnVuEkQKDXNhdGlzZmllc19wenMY
GyABKAsyGi5nb29nbGUucHJvdG9idWYuQm9vbFZhbHVlQgPgQQNSDHNhdGlzZmllc1B6cxJE
Cg1zYXRpc2ZpZXNfcHppGBwgASgLMhouZ29vZ2xlLnByb3RvYnVmLkJvb2xWYWx1ZUID4EED
UgxzYXRpc2ZpZXNQemkiWQoNU3FsQmFja3VwVHlwZRIfChtTUUxfQkFDS1VQX1RZUEVfVU5T
UEVDSUZJRUQQABINCglBVVRPTUFURUQQARINCglPTl9ERU1BTkQQAhIJCgVGSU5BTBADIowB
Cg5TcWxCYWNrdXBTdGF0ZRIgChxTUUxfQkFDS1VQX1NUQVRFX1VOU1BFQ0lGSUVEEAASDAoI
RU5RVUVVRUQQARILCgdSVU5OSU5HEAISCgoGRkFJTEVEEAMSDgoKU1VDQ0VTU0ZVTBAEEgwK
CERFTEVUSU5HEAUSEwoPREVMRVRJT05fRkFJTEVEEAY6SOpBRQoec3FsYWRtaW4uZ29vZ2xl
YXBpcy5jb20vQmFja3VwEiNwcm9qZWN0cy97cHJvamVjdH0vYmFja3Vwcy97YmFja3VwfUIM
CgpleHBpcmF0aW9uQhcKFV9tYXhfY2hhcmdlYWJsZV9ieXRlczL4BgoRU3FsQmFja3Vwc1Nl
cnZpY2USmgEKDENyZWF0ZUJhY2t1cBIoLmdvb2dsZS5jbG91ZC5zcWwudjEuQ3JlYXRlQmFj
a3VwUmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0aW9uIkCC0+STAikiHy92
MS97cGFyZW50PXByb2plY3RzLyp9L2JhY2t1cHM6BmJhY2t1cNpBDnBhcmVudCwgYmFja3Vw
En8KCUdldEJhY2t1cBIlLmdvb2dsZS5jbG91ZC5zcWwudjEuR2V0QmFja3VwUmVxdWVzdBob
Lmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3VwIi6C0+STAiESHy92MS97bmFtZT1wcm9qZWN0
cy8qL2JhY2t1cHMvKn3aQQRuYW1lEpIBCgtMaXN0QmFja3VwcxInLmdvb2dsZS5jbG91ZC5z
cWwudjEuTGlzdEJhY2t1cHNSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLnNxbC52MS5MaXN0QmFj
a3Vwc1Jlc3BvbnNlIjCC0+STAiESHy92MS97cGFyZW50PXByb2plY3RzLyp9L2JhY2t1cHPa
QQZwYXJlbnQSpgEKDFVwZGF0ZUJhY2t1cBIoLmdvb2dsZS5jbG91ZC5zcWwudjEuVXBkYXRl
QmFja3VwUmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0aW9uIkyC0+STAjAy
Ji92MS97YmFja3VwLm5hbWU9cHJvamVjdHMvKi9iYWNrdXBzLyp9OgZiYWNrdXDaQRNiYWNr
dXAsIHVwZGF0ZV9tYXNrEogBCgxEZWxldGVCYWNrdXASKC5nb29nbGUuY2xvdWQuc3FsLnYx
LkRlbGV0ZUJhY2t1cFJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiIu
gtPkkwIhKh8vdjEve25hbWU9cHJvamVjdHMvKi9iYWNrdXBzLyp92kEEbmFtZRp8ykEXc3Fs
YWRtaW4uZ29vZ2xlYXBpcy5jb23SQV9odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvc3Fsc2Vy
dmljZS5hZG1pbkJcChdjb20uZ29vZ2xlLmNsb3VkLnNxbC52MUIUQ2xvdWRTcWxCYWNrdXBz
UHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9zcWwvYXBpdjEvc3FscGI7c3FscGJK3VIK
BxIFDgDGAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwK
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA5
CgkKAgMFEgMXADcKCQoCAwYSAxgANwoJCgIDBxIDGQAqCgkKAgMIEgMaACkKCQoCAwkSAxsA
KAoJCgIDChIDHAAkCggKAQgSAx4AQAoJCgIICxIDHgBACggKAQgSAx8AIgoJCgIIChIDHwAi
CggKAQgSAyAANQoJCgIICBIDIAA1CggKAQgSAyEAMAoJCgIIARIDIQAwCgoKAgYAEgQjAFQB
CgoKAwYAARIDIwgZCgoKAwYAAxIDJAI/CgwKBQYAA5kIEgMkAj8KCwoDBgADEgQlAic5Cg0K
BQYAA5oIEgQlAic5CnIKBAYAAgASBCsCMQMaZCBDcmVhdGVzIGEgYmFja3VwIGZvciBhIENs
b3VkIFNRTCBpbnN0YW5jZS4gVGhpcyBBUEkgY2FuIGJlIHVzZWQgb25seSB0bwogY3JlYXRl
IG9uLWRlbWFuZCBiYWNrdXBzLgoKDAoFBgACAAESAysGEgoMCgUGAAIAAhIDKxMmCgwKBQYA
AgADEgMrMToKDQoFBgACAAQSBCwELwYKEQoJBgACAASwyrwiEgQsBC8GCgwKBQYAAgAEEgMw
BDwKDwoIBgACAASbCAASAzAEPApLCgQGAAIBEgQ0AjkDGj0gUmV0cmlldmVzIGEgcmVzb3Vy
Y2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBhIGJhY2t1cC4KCgwKBQYAAgEBEgM0
Bg8KDAoFBgACAQISAzQQIAoMCgUGAAIBAxIDNCsxCg0KBQYAAgEEEgQ1BDcGChEKCQYAAgEE
sMq8IhIENQQ3BgoMCgUGAAIBBBIDOAQyCg8KCAYAAgEEmwgAEgM4BDIKPgoEBgACAhIEPAJB
AxowIExpc3RzIGFsbCBiYWNrdXBzIGFzc29jaWF0ZWQgd2l0aCB0aGUgcHJvamVjdC4KCgwK
BQYAAgIBEgM8BhEKDAoFBgACAgISAzwSJAoMCgUGAAICAxIDPC9CCg0KBQYAAgIEEgQ9BD8G
ChEKCQYAAgIEsMq8IhIEPQQ/BgoMCgUGAAICBBIDQAQ0Cg8KCAYAAgIEmwgAEgNABDQKfwoE
BgACAxIERQJLAxpxIFVwZGF0ZXMgdGhlIHJldGVudGlvbiBwZXJpb2QgYW5kIGRlc2NyaXB0
aW9uIG9mIHRoZSBiYWNrdXAuIFlvdSBjYW4gdXNlCiB0aGlzIEFQSSB0byB1cGRhdGUgZmlu
YWwgYmFja3VwcyBvbmx5LgoKDAoFBgACAwESA0UGEgoMCgUGAAIDAhIDRRMmCgwKBQYAAgMD
EgNFMToKDQoFBgACAwQSBEYESQYKEQoJBgACAwSwyrwiEgRGBEkGCgwKBQYAAgMEEgNKBEEK
DwoIBgACAwSbCAASA0oEQQojCgQGAAIEEgROAlMDGhUgRGVsZXRlcyB0aGUgYmFja3VwLgoK
DAoFBgACBAESA04GEgoMCgUGAAIEAhIDThMmCgwKBQYAAgQDEgNOMToKDQoFBgACBAQSBE8E
UQYKEQoJBgACBASwyrwiEgRPBFEGCgwKBQYAAgQEEgNSBDIKDwoIBgACBASbCAASA1IEMgo2
CgIEABIEVwBjARoqIFRoZSByZXF1ZXN0IHBheWxvYWQgdG8gY3JlYXRlIHRoZSBiYWNrdXAK
CgoKAwQAARIDVwgbCmcKBAQAAgASBFoCXwQaWSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNv
dXJjZSB3aGVyZSB0aGlzIGJhY2t1cCBpcyBjcmVhdGVkLgogRm9ybWF0OiBwcm9qZWN0cy97
cHJvamVjdH0KCgwKBQQAAgAFEgNaAggKDAoFBAACAAESA1oJDwoMCgUEAAIAAxIDWhITCg0K
BQQAAgAIEgRaFF8DCg8KCAQAAgAInAgAEgNbBCoKDwoHBAACAAifCBIEXAReBQouCgQEAAIB
EgNiAj0aISBSZXF1aXJlZC4gVGhlIEJhY2t1cCB0byBjcmVhdGUuCgoMCgUEAAIBBhIDYgII
CgwKBQQAAgEBEgNiCQ8KDAoFBAACAQMSA2ISEwoMCgUEAAIBCBIDYhQ8Cg8KCAQAAgEInAgA
EgNiFTsKNAoCBAESBGYAbQEaKCBUaGUgcmVxdWVzdCBwYXlsb2FkIHRvIGdldCB0aGUgYmFj
a3VwLgoKCgoDBAEBEgNmCBgKagoEBAECABIEaQJsBBpcIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgYmFja3VwIHRvIHJldHJpZXZlLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0v
YmFja3Vwcy97YmFja3VwfQoKDAoFBAECAAUSA2kCCAoMCgUEAQIAARIDaQkNCgwKBQQBAgAD
EgNpEBEKDQoFBAECAAgSBGkSbAMKDwoIBAECAAicCAASA2oEKgoOCgcEAQIACJ8IEgNrBFAK
NwoCBAISBXAAjQEBGiogVGhlIHJlcXVlc3QgcGF5bG9hZCB0byBsaXN0IHRoZSBiYWNrdXBz
LgoKCgoDBAIBEgNwCBoKZgoEBAICABIEcwJ4BBpYIFJlcXVpcmVkLiBUaGUgcGFyZW50IHRo
YXQgb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YgYmFja3Vwcy4KIEZvcm1hdDogcHJvamVjdHMv
e3Byb2plY3R9CgoMCgUEAgIABRIDcwIICgwKBQQCAgABEgNzCQ8KDAoFBAICAAMSA3MSEwoN
CgUEAgIACBIEcxR4AwoPCggEAgIACJwIABIDdAQqCg8KBwQCAgAInwgSBHUEdwUKwgIKBAQC
AgESA38CFhq0AiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYmFja3VwcyB0byByZXR1cm4gcGVy
IHJlc3BvbnNlLiBUaGUgc2VydmljZSBtaWdodAogcmV0dXJuIGZld2VyIGJhY2t1cHMgdGhh
biB0aGlzIHZhbHVlLiBJZiBhIHZhbHVlIGZvciB0aGlzIHBhcmFtZXRlciBpc24ndAogc3Bl
Y2lmaWVkLCB0aGVuLCBhdCBtb3N0LCA1MDAgYmFja3VwcyBhcmUgcmV0dXJuZWQuIFRoZSBt
YXhpbXVtIHZhbHVlIGlzCiAyLDAwMC4gQW55IHZhbHVlcyB0aGF0IHlvdSBzZXQsIHdoaWNo
IGFyZSBncmVhdGVyIHRoYW4gMiwwMDAsIGFyZSBjaGFuZ2VkCiB0byAyLDAwMC4KCgwKBQQC
AgEFEgN/AgcKDAoFBAICAQESA38IEQoMCgUEAgIBAxIDfxQVCu8BCgQEAgICEgSGAQIYGuAB
IEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0QmFja3Vwc2Ag
Y2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoK
IFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExp
c3RCYWNrdXBzYCBtdXN0IG1hdGNoCiB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdl
IHRva2VuLgoKDQoFBAICAgUSBIYBAggKDQoFBAICAgESBIYBCRMKDQoFBAICAgMSBIYBFhcK
jQIKBAQCAgMSBIwBAhQa/gEgTXVsdGlwbGUgZmlsdGVyIHF1ZXJpZXMgYXJlIHNlcGFyYXRl
ZCBieSBzcGFjZXMuIEZvciBleGFtcGxlLAogJ2luc3RhbmNlOmFiYyBBTkQgdHlwZTpGSU5B
TCwgJ2xvY2F0aW9uOnVzJywKICdiYWNrdXBJbnRlcnZhbC5zdGFydFRpbWU+PTE5NTAtMDEt
MDFUMDE6MDE6MjUuNzcxWicuIFlvdSBjYW4gZmlsdGVyIGJ5CiB0eXBlLCBpbnN0YW5jZSwg
YmFja3VwSW50ZXJ2YWwuc3RhcnRUaW1lIChjcmVhdGlvbiB0aW1lKSwgb3IgbG9jYXRpb24u
CgoNCgUEAgIDBRIEjAECCAoNCgUEAgIDARIEjAEJDwoNCgUEAgIDAxIEjAESEwpGCgIEAxIG
kAEAmwEBGjggVGhlIHJlc3BvbnNlIHBheWxvYWQgY29udGFpbmluZyBhIGxpc3Qgb2YgdGhl
IGJhY2t1cHMuCgoLCgMEAwESBJABCBsKIgoEBAMCABIEkgECHhoUIEEgbGlzdCBvZiBiYWNr
dXBzLgoKDQoFBAMCAAQSBJIBAgoKDQoFBAMCAAYSBJIBCxEKDQoFBAMCAAESBJIBEhkKDQoF
BAMCAAMSBJIBHB0KlQEKBAQDAgESBJYBAh0ahgEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNl
bnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlz
IGZpZWxkIGlzIG9taXR0ZWQsIHRoZW4gdGhlcmUgYXJlbid0IHN1YnNlcXVlbnQgcGFnZXMu
CgoNCgUEAwIBBRIElgECCAoNCgUEAwIBARIElgEJGAoNCgUEAwIBAxIElgEbHApxCgQEAwIC
EgSaAQIjGmMgSWYgYSByZWdpb24gaXNuJ3QgdW5hdmFpbGFibGUgb3IgaWYgYW4gdW5rbm93
biBlcnJvciBvY2N1cnMsIHRoZW4gYSB3YXJuaW5nCiBtZXNzYWdlIGlzIHJldHVybmVkLgoK
DQoFBAMCAgQSBJoBAgoKDQoFBAMCAgYSBJoBCxUKDQoFBAMCAgESBJoBFh4KDQoFBAMCAgMS
BJoBISIKOQoCBAQSBp4BAKcBARorIFRoZSByZXF1ZXN0IHBheWxvYWQgdG8gdXBkYXRlIHRo
ZSBiYWNrdXAuCgoLCgMEBAESBJ4BCBsKpAEKBAQEAgASBKIBAj0alQEgUmVxdWlyZWQuIFRo
ZSBiYWNrdXAgdG8gdXBkYXRlLgogVGhlIGJhY2t1cOKAmXMgYG5hbWVgIGZpZWxkIGlzIHVz
ZWQgdG8gaWRlbnRpZnkgdGhlIGJhY2t1cCB0byB1cGRhdGUuCiBGb3JtYXQ6IHByb2plY3Rz
L3twcm9qZWN0fS9iYWNrdXBzL3tiYWNrdXB9CgoNCgUEBAIABhIEogECCAoNCgUEBAIAARIE
ogEJDwoNCgUEBAIAAxIEogESEwoNCgUEBAIACBIEogEUPAoQCggEBAIACJwIABIEogEVOwqG
AQoEBAQCARIEpgECLBp4IFRoZSBsaXN0IG9mIGZpZWxkcyB0aGF0IHlvdSBjYW4gdXBkYXRl
LiBZb3UgY2FuIHVwZGF0ZSBvbmx5IHRoZSBkZXNjcmlwdGlvbgogYW5kIHJldGVudGlvbiBw
ZXJpb2Qgb2YgdGhlIGZpbmFsIGJhY2t1cC4KCg0KBQQEAgEGEgSmAQIbCg0KBQQEAgEBEgSm
ARwnCg0KBQQEAgEDEgSmASorCjkKAgQFEgaqAQCxAQEaKyBUaGUgcmVxdWVzdCBwYXlsb2Fk
IHRvIGRlbGV0ZSB0aGUgYmFja3VwLgoKCwoDBAUBEgSqAQgbCmoKBAQFAgASBq0BArABBBpa
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYmFja3VwIHRvIGRlbGV0ZS4KIEZvcm1hdDog
cHJvamVjdHMve3Byb2plY3R9L2JhY2t1cHMve2JhY2t1cH0KCg0KBQQFAgAFEgStAQIICg0K
BQQFAgABEgStAQkNCg0KBQQFAgADEgStARARCg8KBQQFAgAIEgatARKwAQMKEAoIBAUCAAic
CAASBK4BBCoKDwoHBAUCAAifCBIErwEEUAoiCgIEBhIGtAEAxgIBGhQgQSBiYWNrdXAgcmVz
b3VyY2UuCgoLCgMEBgESBLQBCA4KDQoDBAYHEga1AQK4AQQKDwoFBAYHnQgSBrUBArgBBAoi
CgQEBgQAEga7AQLHAQMaEiBUaGUgYmFja3VwIHR5cGUuCgoNCgUEBgQAARIEuwEHFAoxCgYE
BgQAAgASBL0BBCQaISBUaGlzIGlzIGFuIHVua25vd24gYmFja3VwIHR5cGUuCgoPCgcEBgQA
AgABEgS9AQQfCg8KBwQGBAACAAISBL0BIiMKRgoGBAYEAAIBEgTAAQQSGjYgVGhlIGJhY2t1
cCBzY2hlZHVsZSB0cmlnZ2VycyBhIGJhY2t1cCBhdXRvbWF0aWNhbGx5LgoKDwoHBAYEAAIB
ARIEwAEEDQoPCgcEBgQAAgECEgTAARARCjYKBgQGBAACAhIEwwEEEhomIFRoZSB1c2VyIHRy
aWdnZXJzIGEgYmFja3VwIG1hbnVhbGx5LgoKDwoHBAYEAAICARIEwwEEDQoPCgcEBgQAAgIC
EgTDARARCj4KBgQGBAACAxIExgEEDhouIFRoZSBiYWNrdXAgY3JlYXRlZCB3aGVuIGluc3Rh
bmNlIGlzIGRlbGV0ZWQuCgoPCgcEBgQAAgMBEgTGAQQJCg8KBwQGBAACAwISBMYBDA0KJAoE
BAYEARIGygEC3wEDGhQgVGhlIGJhY2t1cCdzIHN0YXRlCgoNCgUEBgQBARIEygEHFQo1CgYE
BgQBAgASBMwBBCUaJSBUaGUgc3RhdGUgb2YgdGhlIGJhY2t1cCBpcyB1bmtub3duLgoKDwoH
BAYEAQIAARIEzAEEIAoPCgcEBgQBAgACEgTMASMkCjUKBgQGBAECARIEzwEEERolIFRoZSBi
YWNrdXAgdGhhdCdzIGFkZGVkIHRvIGEgcXVldWUuCgoPCgcEBgQBAgEBEgTPAQQMCg8KBwQG
BAECAQISBM8BDxAKLAoGBAYEAQICEgTSAQQQGhwgVGhlIGJhY2t1cCBpcyBpbiBwcm9ncmVz
cy4KCg8KBwQGBAECAgESBNIBBAsKDwoHBAYEAQICAhIE0gEODwokCgYEBgQBAgMSBNUBBA8a
FCBUaGUgYmFja3VwIGZhaWxlZC4KCg8KBwQGBAECAwESBNUBBAoKDwoHBAYEAQIDAhIE1QEN
DgorCgYEBgQBAgQSBNgBBBMaGyBUaGUgYmFja3VwIGlzIHN1Y2Nlc3NmdWwuCgoPCgcEBgQB
AgQBEgTYAQQOCg8KBwQGBAECBAISBNgBERIKLgoGBAYEAQIFEgTbAQQRGh4gVGhlIGJhY2t1
cCBpcyBiZWluZyBkZWxldGVkLgoKDwoHBAYEAQIFARIE2wEEDAoPCgcEBgQBAgUCEgTbAQ8Q
CjAKBgQGBAECBhIE3gEEGBogIERlbGV0aW9uIG9mIHRoZSBiYWNrdXAgZmFpbGVkLgoKDwoH
BAYEAQIGARIE3gEEEwoPCgcEBgQBAgYCEgTeARYXCmsKBAQGAgASBOMBAj4aXSBPdXRwdXQg
b25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGJhY2t1cC4KIEZvcm1hdDogcHJvamVj
dHMve3Byb2plY3R9L2JhY2t1cHMve2JhY2t1cH0uCgoNCgUEBgIABRIE4wECCAoNCgUEBgIA
ARIE4wEJDQoNCgUEBgIAAxIE4wEQEQoNCgUEBgIACBIE4wESPQoQCggEBgIACJwIABIE4wET
PAo5CgQEBgIBEgTmAQI+GisgT3V0cHV0IG9ubHkuIFRoaXMgaXMgYWx3YXlzIGBzcWwjYmFj
a3VwYC4KCg0KBQQGAgEFEgTmAQIICg0KBQQGAgEBEgTmAQkNCg0KBQQGAgEDEgTmARARCg0K
BQQGAgEIEgTmARI9ChAKCAQGAgEInAgAEgTmARM8CjYKBAQGAgISBOkBAkMaKCBPdXRwdXQg
b25seS4gVGhlIFVSSSBvZiB0aGlzIHJlc291cmNlLgoKDQoFBAYCAgUSBOkBAggKDQoFBAYC
AgESBOkBCRIKDQoFBAYCAgMSBOkBFRYKDQoFBAYCAggSBOkBF0IKEAoIBAYCAgicCAASBOkB
GEEKbwoEBAYCAxIE7QECRRphIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGlzIGJhY2t1
cC4gVGhlIHR5cGUgY2FuIGJlICJBVVRPTUFURUQiLAogIk9OX0RFTUFORCIgb3Ig4oCcRklO
QUzigJ0uCgoNCgUEBgIDBhIE7QECDwoNCgUEBgIDARIE7QEQFAoNCgUEBgIDAxIE7QEXGAoN
CgUEBgIDCBIE7QEZRAoQCggEBgIDCJwIABIE7QEaQwovCgQEBgIEEgTwAQIZGiEgVGhlIGRl
c2NyaXB0aW9uIG9mIHRoaXMgYmFja3VwLgoKDQoFBAYCBAUSBPABAggKDQoFBAYCBAESBPAB
CRQKDQoFBAYCBAMSBPABFxgKOQoEBAYCBRIE8wECFhorIFRoZSBuYW1lIG9mIHRoZSBzb3Vy
Y2UgZGF0YWJhc2UgaW5zdGFuY2UuCgoNCgUEBgIFBRIE8wECCAoNCgUEBgIFARIE8wEJEQoN
CgUEBgIFAxIE8wEUFQpYCgQEBgIGEgT2AQIWGkogVGhlIHN0b3JhZ2UgbG9jYXRpb24gb2Yg
dGhlIGJhY2t1cHMuIFRoZSBsb2NhdGlvbiBjYW4gYmUgbXVsdGktcmVnaW9uYWwuCgoNCgUE
BgIGBRIE9gECCAoNCgUEBgIGARIE9gEJEQoNCgUEBgIGAxIE9gEUFQrLAQoEBAYCBxIG+wEC
/AEyGroBIE91dHB1dCBvbmx5LiBUaGlzIG91dHB1dCBjb250YWlucyB0aGUgZm9sbG93aW5n
IHZhbHVlczoKIHN0YXJ0X3RpbWU6IEFsbCBkYXRhYmFzZSB3cml0ZXMgdXAgdG8gdGhpcyB0
aW1lIGFyZSBhdmFpbGFibGUuCiBlbmRfdGltZTogQW55IGRhdGFiYXNlIHdyaXRlcyBhZnRl
ciB0aGlzIHRpbWUgYXJlbid0IGF2YWlsYWJsZS4KCg0KBQQGAgcGEgT7AQIWCg0KBQQGAgcB
EgT7ARcmCg0KBQQGAgcDEgT7ASkqCg0KBQQGAgcIEgT8AQYxChAKCAQGAgcInAgAEgT8AQcw
CjcKBAQGAggSBP8BAkcaKSBPdXRwdXQgb25seS4gVGhlIHN0YXR1cyBvZiB0aGlzIGJhY2t1
cC4KCg0KBQQGAggGEgT/AQIQCg0KBQQGAggBEgT/AREWCg0KBQQGAggDEgT/ARkaCg0KBQQG
AggIEgT/ARtGChAKCAQGAggInAgAEgT/ARxFCnoKBAQGAgkSBIMCAkgabCBPdXRwdXQgb25s
eS4gSW5mb3JtYXRpb24gYWJvdXQgd2h5IHRoZSBiYWNrdXAgb3BlcmF0aW9uIGZhaWxzIChm
b3IgZXhhbXBsZSwKIHdoZW4gdGhlIGJhY2t1cCBzdGF0ZSBmYWlscykuCgoNCgUEBgIJBhIE
gwICEAoNCgUEBgIJARIEgwIRFgoNCgUEBgIJAxIEgwIZGwoNCgUEBgIJCBIEgwIcRwoQCggE
BgIJCJwIABIEgwIdRgqXAQoEBAYCChIEhwICQhqIASBPdXRwdXQgb25seS4gVGhpcyBvdXRw
dXQgY29udGFpbnMgdGhlIGVuY3J5cHRpb24gY29uZmlndXJhdGlvbiBmb3IgYSBiYWNrdXAK
IGFuZCB0aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgS01TIGtleSBmb3IgZGlzayBlbmNyeXB0
aW9uLgoKDQoFBAYCCgUSBIcCAggKDQoFBAYCCgESBIcCCRAKDQoFBAYCCgMSBIcCExUKDQoF
BAYCCggSBIcCFkEKEAoIBAYCCgicCAASBIcCF0AKpAEKBAQGAgsSBIsCAkoalQEgT3V0cHV0
IG9ubHkuIFRoaXMgb3V0cHV0IGNvbnRhaW5zIHRoZSBlbmNyeXB0aW9uIHN0YXR1cyBmb3Ig
YSBiYWNrdXAgYW5kCiB0aGUgdmVyc2lvbiBvZiB0aGUgS01TIGtleSB0aGF0J3MgdXNlZCB0
byBlbmNyeXB0IHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoNCgUEBgILBRIEiwICCAoNCgUE
BgILARIEiwIJGAoNCgUEBgILAxIEiwIbHQoNCgUEBgILCBIEiwIeSQoQCggEBgILCJwIABIE
iwIfSApYCgQEBgIMEgSOAgJNGkogT3V0cHV0IG9ubHkuIFNwZWNpZmllcyB0aGUga2luZCBv
ZiBiYWNrdXAsIFBIWVNJQ0FMIG9yIERFRkFVTFRfU05BUFNIT1QuCgoNCgUEBgIMBhIEjgIC
DwoNCgUEBgIMARIEjgIQGwoNCgUEBgIMAxIEjgIeIAoNCgUEBgIMCBIEjgIhTAoQCggEBgIM
CJwIABIEjgIiSwrXAQoEBAYCDRIEkwICRBrIASBPdXRwdXQgb25seS4gVGhpcyBvdXRwdXQg
Y29udGFpbnMgYSBiYWNrdXAgdGltZSB6b25lLiBJZiBhIENsb3VkIFNRTCBmb3IKIFNRTCBT
ZXJ2ZXIgaW5zdGFuY2UgaGFzIGEgZGlmZmVyZW50IHRpbWUgem9uZSBmcm9tIHRoZSBiYWNr
dXAncyB0aW1lIHpvbmUsCiB0aGVuIHRoZSByZXN0b3JlIHRvIHRoZSBpbnN0YW5jZSBkb2Vz
bid0IGhhcHBlbi4KCg0KBQQGAg0FEgSTAgIICg0KBQQGAg0BEgSTAgkSCg0KBQQGAg0DEgST
AhUXCg0KBQQGAg0IEgSTAhhDChAKCAQGAg0InAgAEgSTAhlCCg4KBAQGCAASBpUCAp8CAwoN
CgUEBggAARIElQIIEgrsAQoEBAYCDhIEmgIEQxrdASBJbnB1dCBvbmx5LiBUaGUgdGltZS10
by1saXZlIChUVEwpIGludGVydmFsIGZvciB0aGlzIHJlc291cmNlIChpbiBkYXlzKS4KIEZv
ciBleGFtcGxlOiB0dGxEYXlzOjcsIG1lYW5zIDcgZGF5cyBmcm9tIHRoZSBjdXJyZW50IHRp
bWUuIFRoZQogZXhwaXJhdGlvbiB0aW1lIGNhbid0IGV4Y2VlZCAzNjUgZGF5cyBmcm9tIHRo
ZSB0aW1lIHRoYXQgdGhlIGJhY2t1cCBpcwogY3JlYXRlZC4KCg0KBQQGAg4FEgSaAgQJCg0K
BQQGAg4BEgSaAgoSCg0KBQQGAg4DEgSaAhUXCg0KBQQGAg4IEgSaAhhCChAKCAQGAg4InAgA
EgSaAhlBClUKBAQGAg8SBJ4CBC8aRyBCYWNrdXAgZXhwaXJhdGlvbiB0aW1lLgogQSBVVEMg
dGltZXN0YW1wIG9mIHdoZW4gdGhpcyBiYWNrdXAgZXhwaXJlZC4KCg0KBQQGAg8GEgSeAgQd
Cg0KBQQGAg8BEgSeAh4pCg0KBQQGAg8DEgSeAiwuCmkKBAQGAhASBqMCAqQCMhpZIE91dHB1
dCBvbmx5LiBUaGUgZGF0YWJhc2UgdmVyc2lvbiBvZiB0aGUgaW5zdGFuY2Ugb2YgYXQgdGhl
IHRpbWUgdGhpcwogYmFja3VwIHdhcyBtYWRlLgoKDQoFBAYCEAYSBKMCAhQKDQoFBAYCEAES
BKMCFSUKDQoFBAYCEAMSBKMCKCoKDQoFBAYCEAgSBKQCBjEKEAoIBAYCEAicCAASBKQCBzAK
SwoEBAYCERIGpwICqAIyGjsgT3V0cHV0IG9ubHkuIFRoZSBtYXhpbXVtIGNoYXJnZWFibGUg
Ynl0ZXMgZm9yIHRoZSBiYWNrdXAuCgoNCgUEBgIRBBIEpwICCgoNCgUEBgIRBRIEpwILEAoN
CgUEBgIRARIEpwIRJQoNCgUEBgIRAxIEpwIoKgoNCgUEBgIRCBIEqAIGMQoQCggEBgIRCJwI
ABIEqAIHMAp3CgQEBgISEgasAgKvAgQaZyBPcHRpb25hbC4gT3V0cHV0IG9ubHkuIFRpbWVz
dGFtcCBpbiBVVEMgb2Ygd2hlbiB0aGUgaW5zdGFuY2UgYXNzb2NpYXRlZAogd2l0aCB0aGlz
IGJhY2t1cCBpcyBkZWxldGVkLgoKDQoFBAYCEgYSBKwCAhsKDQoFBAYCEgESBKwCHDIKDQoF
BAYCEgMSBKwCNTcKDwoFBAYCEggSBqwCOK8CAwoQCggEBgISCJwIABIErQIEKgoQCggEBgIS
CJwIARIErgIELQp5CgQEBgITEgazAgK2AgQaaSBPcHRpb25hbC4gT3V0cHV0IG9ubHkuIFRo
ZSBpbnN0YW5jZSBzZXR0aW5nIG9mIHRoZSBzb3VyY2UgaW5zdGFuY2UgdGhhdCdzCiBhc3Nv
Y2lhdGVkIHdpdGggdGhpcyBiYWNrdXAuCgoNCgUEBgITBhIEswICEgoNCgUEBgITARIEswIT
JAoNCgUEBgITAxIEswInKQoPCgUEBgITCBIGswIqtgIDChAKCAQGAhMInAgAEgS0AgQqChAK
CAQGAhMInAgBEgS1AgQtClkKBAQGAhQSBLkCAkUaSyBPdXRwdXQgb25seS4gVGhlIG1hcHBp
bmcgdG8gYmFja3VwIHJ1biByZXNvdXJjZSB1c2VkIGZvciBJQU0gdmFsaWRhdGlvbnMuCgoN
CgUEBgIUBRIEuQICCAoNCgUEBgIUARIEuQIJEwoNCgUEBgIUAxIEuQIWGAoNCgUEBgIUCBIE
uQIZRAoQCggEBgIUCJwIABIEuQIaQwp/CgQEBgIVEga+AgK/AjIabyBPdXRwdXQgb25seS4g
VGhpcyBzdGF0dXMgaW5kaWNhdGVzIHdoZXRoZXIgdGhlIGJhY2t1cCBzYXRpc2ZpZXMgUFpT
LgoKIFRoZSBzdGF0dXMgaXMgcmVzZXJ2ZWQgZm9yIGZ1dHVyZSB1c2UuCgoNCgUEBgIVBhIE
vgICGwoNCgUEBgIVARIEvgIcKQoNCgUEBgIVAxIEvgIsLgoNCgUEBgIVCBIEvwIGMQoQCggE
BgIVCJwIABIEvwIHMAp/CgQEBgIWEgbEAgLFAjIabyBPdXRwdXQgb25seS4gVGhpcyBzdGF0
dXMgaW5kaWNhdGVzIHdoZXRoZXIgdGhlIGJhY2t1cCBzYXRpc2ZpZXMgUFpJLgoKIFRoZSBz
dGF0dXMgaXMgcmVzZXJ2ZWQgZm9yIGZ1dHVyZSB1c2UuCgoNCgUEBgIWBhIExAICGwoNCgUE
BgIWARIExAIcKQoNCgUEBgIWAxIExAIsLgoNCgUEBgIWCBIExQIGMQoQCggEBgIWCJwIABIE
xQIHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest ===
    # Fields for CreateBackupRequest
    # Field: parent Type: 9 ()
    # Field: backup Type: 11 (.google.cloud.sql.v1.Backup)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<backup>

Type: Message (.google.cloud.sql.v1.Backup)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest ===
    # Fields for GetBackupRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest ===
    # Fields for ListBackupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest->new(
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

=item * B<filter>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse ===
    # Fields for ListBackupsResponse
    # Field: backups Type: 11 (.google.cloud.sql.v1.Backup)
    # Field: next_page_token Type: 9 ()
    # Field: warnings Type: 11 (.google.cloud.sql.v1.ApiWarning)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse->new(
        backups => $value,
    );

=head1 FIELDS

=over 4

=item * B<backups>

Type: Message (.google.cloud.sql.v1.Backup)

=item * B<next_page_token>

Type: String

=item * B<warnings>

Type: Message (.google.cloud.sql.v1.ApiWarning)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest ===
    # Fields for UpdateBackupRequest
    # Field: backup Type: 11 (.google.cloud.sql.v1.Backup)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest->new(
        backup => $value,
    );

=head1 FIELDS

=over 4

=item * B<backup>

Type: Message (.google.cloud.sql.v1.Backup)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest ===
    # Fields for DeleteBackupRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::Backup ===
    # Fields for Backup
    # Field: name Type: 9 ()
    # Field: kind Type: 9 ()
    # Field: self_link Type: 9 ()
    # Field: type Type: 14 (.google.cloud.sql.v1.Backup.SqlBackupType)
    # Field: description Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: location Type: 9 ()
    # Field: backup_interval Type: 11 (.google.type.Interval)
    # Field: state Type: 14 (.google.cloud.sql.v1.Backup.SqlBackupState)
    # Field: error Type: 11 (.google.cloud.sql.v1.OperationError)
    # Field: kms_key Type: 9 ()
    # Field: kms_key_version Type: 9 ()
    # Field: backup_kind Type: 14 (.google.cloud.sql.v1.SqlBackupKind)
    # Field: time_zone Type: 9 ()
    # Field: ttl_days Type: 3 ()
    # Field: expiry_time Type: 11 (.google.protobuf.Timestamp)
    # Field: database_version Type: 14 (.google.cloud.sql.v1.SqlDatabaseVersion)
    # Field: max_chargeable_bytes Type: 3 ()
    # Field: instance_deletion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_settings Type: 11 (.google.cloud.sql.v1.DatabaseInstance)
    # Field: backup_run Type: 9 ()
    # Field: satisfies_pzs Type: 11 (.google.protobuf.BoolValue)
    # Field: satisfies_pzi Type: 11 (.google.protobuf.BoolValue)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::Backup - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::Backup->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<kind>

Type: String

=item * B<self_link>

Type: String

=item * B<type>

Type: Enum (.google.cloud.sql.v1.Backup.SqlBackupType)

=item * B<description>

Type: String

=item * B<instance>

Type: String

=item * B<location>

Type: String

=item * B<backup_interval>

Type: Message (.google.type.Interval)

=item * B<state>

Type: Enum (.google.cloud.sql.v1.Backup.SqlBackupState)

=item * B<error>

Type: Message (.google.cloud.sql.v1.OperationError)

=item * B<kms_key>

Type: String

=item * B<kms_key_version>

Type: String

=item * B<backup_kind>

Type: Enum (.google.cloud.sql.v1.SqlBackupKind)

=item * B<time_zone>

Type: String

=item * B<ttl_days>

Type: Int64

=item * B<expiry_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<database_version>

Type: Enum (.google.cloud.sql.v1.SqlDatabaseVersion)

=item * B<max_chargeable_bytes>

Type: Int64

=item * B<instance_deletion_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<instance_settings>

Type: Message (.google.cloud.sql.v1.DatabaseInstance)

=item * B<backup_run>

Type: String

=item * B<satisfies_pzs>

Type: Message (.google.protobuf.BoolValue)

=item * B<satisfies_pzi>

Type: Message (.google.protobuf.BoolValue)

=back

=cut

# Enum: Backup::SqlBackupType
our $Backup_SQL_BACKUP_TYPE_UNSPECIFIED = 0;
our $Backup_AUTOMATED = 1;
our $Backup_ON_DEMAND = 2;
our $Backup_FINAL = 3;

=pod

=head2 Enum: Backup::SqlBackupType

Values:

=over 4

=item * C<SQL_BACKUP_TYPE_UNSPECIFIED> => 0

=item * C<AUTOMATED> => 1

=item * C<ON_DEMAND> => 2

=item * C<FINAL> => 3

=back

=cut

# Enum: Backup::SqlBackupState
our $Backup_SQL_BACKUP_STATE_UNSPECIFIED = 0;
our $Backup_ENQUEUED = 1;
our $Backup_RUNNING = 2;
our $Backup_FAILED = 3;
our $Backup_SUCCESSFUL = 4;
our $Backup_DELETING = 5;
our $Backup_DELETION_FAILED = 6;

=pod

=head2 Enum: Backup::SqlBackupState

Values:

=over 4

=item * C<SQL_BACKUP_STATE_UNSPECIFIED> => 0

=item * C<ENQUEUED> => 1

=item * C<RUNNING> => 2

=item * C<FAILED> => 3

=item * C<SUCCESSFUL> => 4

=item * C<DELETING> => 5

=item * C<DELETION_FAILED> => 6

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlBackups::SqlBackupsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlBackups::SqlBackupsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::SqlBackupsServiceClient - Client stub representing the remote SqlBackupsService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

sub create_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'CreateBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'GetBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlBackups::Backup',
    });
}

sub list_backups {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'ListBackups',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse',
    });
}

sub update_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'UpdateBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub delete_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'DeleteBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
