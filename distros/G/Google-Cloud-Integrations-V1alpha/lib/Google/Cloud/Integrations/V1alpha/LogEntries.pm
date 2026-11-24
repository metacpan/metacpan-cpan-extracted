package Google::Cloud::Integrations::V1alpha::LogEntries;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Integrations::V1alpha::CloudLoggingDetails };
    eval { require Google::Cloud::Integrations::V1alpha::EventParameter };
    eval { require Google::Cloud::Integrations::V1alpha::IntegrationState };
    eval { require Google::Cloud::Integrations::V1alpha::TaskConfig };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvbG9nX2VudHJpZXMucHJvdG8S
IWdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxo9Z29vZ2xlL2Nsb3VkL2ludGVncmF0aW9ucy92MWFscGhhL2Nsb3Vk
X2xvZ2dpbmdfZGV0YWlscy5wcm90bxo3Z29vZ2xlL2Nsb3VkL2ludGVncmF0aW9ucy92MWFs
cGhhL2V2ZW50X3BhcmFtZXRlci5wcm90bxo5Z29vZ2xlL2Nsb3VkL2ludGVncmF0aW9ucy92
MWFscGhhL2ludGVncmF0aW9uX3N0YXRlLnByb3RvGjNnb29nbGUvY2xvdWQvaW50ZWdyYXRp
b25zL3YxYWxwaGEvdGFza19jb25maWcucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8iphAKDUV4ZWN1dGlvbkluZm8SIAoLaW50ZWdyYXRpb24YAiABKAlSC2ludGVn
cmF0aW9uEh0KCnByb2plY3RfaWQYBCABKAlSCXByb2plY3RJZBIdCgp0cmlnZ2VyX2lkGAUg
ASgJUgl0cmlnZ2VySWQSagoOcmVxdWVzdF9wYXJhbXMYBiADKAsyQy5nb29nbGUuY2xvdWQu
aW50ZWdyYXRpb25zLnYxYWxwaGEuRXhlY3V0aW9uSW5mby5SZXF1ZXN0UGFyYW1zRW50cnlS
DXJlcXVlc3RQYXJhbXMSbQoPcmVzcG9uc2VfcGFyYW1zGAcgAygLMkQuZ29vZ2xlLmNsb3Vk
LmludGVncmF0aW9ucy52MWFscGhhLkV4ZWN1dGlvbkluZm8uUmVzcG9uc2VQYXJhbXNFbnRy
eVIOcmVzcG9uc2VQYXJhbXMSRgoGZXJyb3JzGAogAygLMi4uZ29vZ2xlLmNsb3VkLmludGVn
cmF0aW9ucy52MWFscGhhLkVycm9yRGV0YWlsUgZlcnJvcnMSUAoMdGFza19jb25maWdzGA0g
AygLMi0uZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLlRhc2tDb25maWdSC3Rh
c2tDb25maWdzEjwKGmludGVncmF0aW9uX3ZlcnNpb25fbnVtYmVyGA4gASgJUhhpbnRlZ3Jh
dGlvblZlcnNpb25OdW1iZXISIQoMZXhlY3V0aW9uX2lkGA8gASgJUgtleGVjdXRpb25JZBJ0
ChlpbnRlZ3JhdGlvbl92ZXJzaW9uX3N0YXRlGBAgASgOMjMuZ29vZ2xlLmNsb3VkLmludGVn
cmF0aW9ucy52MWFscGhhLkludGVncmF0aW9uU3RhdGVCA+BBA1IXaW50ZWdyYXRpb25WZXJz
aW9uU3RhdGUSPgobZW5hYmxlX2RhdGFiYXNlX3BlcnNpc3RlbmNlGBEgASgIUhllbmFibGVE
YXRhYmFzZVBlcnNpc3RlbmNlEmoKFWNsb3VkX2xvZ2dpbmdfZGV0YWlscxgSIAEoCzI2Lmdv
b2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5DbG91ZExvZ2dpbmdEZXRhaWxzUhNj
bG91ZExvZ2dpbmdEZXRhaWxzEoIBCh1pbnRlZ3JhdGlvbl9leGVjdXRpb25fZGV0YWlscxgT
IAEoCzI+Lmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5JbnRlZ3JhdGlvbkV4
ZWN1dGlvbkRldGFpbHNSG2ludGVncmF0aW9uRXhlY3V0aW9uRGV0YWlscxJXCg5leGVjdXRp
b25fdHlwZRgUIAEoDjIwLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5FeGVj
dXRpb25UeXBlUg1leGVjdXRpb25UeXBlEmsKEGV4ZWN1dGlvbl9tZXRob2QYFSABKA4yQC5n
b29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuRXhlY3V0aW9uSW5mby5FeGVjdXRp
b25NZXRob2RSD2V4ZWN1dGlvbk1ldGhvZBI+ChtpbnRlZ3JhdGlvbl9zbmFwc2hvdF9udW1i
ZXIYFiABKANSGWludGVncmF0aW9uU25hcHNob3ROdW1iZXISXAoLcmVwbGF5X2luZm8YFyAB
KAsyOy5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuRXhlY3V0aW9uSW5mby5S
ZXBsYXlJbmZvUgpyZXBsYXlJbmZvGogDCgpSZXBsYXlJbmZvEjsKGm9yaWdpbmFsX2V4ZWN1
dGlvbl9pbmZvX2lkGAEgASgJUhdvcmlnaW5hbEV4ZWN1dGlvbkluZm9JZBI9ChtyZXBsYXll
ZF9leGVjdXRpb25faW5mb19pZHMYAiADKAlSGHJlcGxheWVkRXhlY3V0aW9uSW5mb0lkcxIj
Cg1yZXBsYXlfcmVhc29uGAMgASgJUgxyZXBsYXlSZWFzb24SbAoLcmVwbGF5X21vZGUYBCAB
KA4yRi5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuRXhlY3V0aW9uSW5mby5S
ZXBsYXlJbmZvLlJlcGxheU1vZGVCA+BBAVIKcmVwbGF5TW9kZSJrCgpSZXBsYXlNb2RlEhsK
F1JFUExBWV9NT0RFX1VOU1BFQ0lGSUVEEAASHgoaUkVQTEFZX01PREVfRlJPTV9CRUdJTk5J
TkcQARIgChxSRVBMQVlfTU9ERV9QT0lOVF9PRl9GQUlMVVJFEAIacwoSUmVxdWVzdFBhcmFt
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkcKBXZhbHVlGAIgASgLMjEuZ29vZ2xlLmNsb3Vk
LmludGVncmF0aW9ucy52MWFscGhhLkV2ZW50UGFyYW1ldGVyUgV2YWx1ZToCOAEadAoTUmVz
cG9uc2VQYXJhbXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJHCgV2YWx1ZRgCIAEoCzIxLmdv
b2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5FdmVudFBhcmFtZXRlclIFdmFsdWU6
AjgBIl4KD0V4ZWN1dGlvbk1ldGhvZBIgChxFWEVDVVRJT05fTUVUSE9EX1VOU1BFQ0lGSUVE
EAASCAoEUE9TVBABEgwKCFNDSEVEVUxFEAISEQoNUE9TVF9UT19RVUVVRRADIosGChtJbnRl
Z3JhdGlvbkV4ZWN1dGlvbkRldGFpbHMSnQEKG2ludGVncmF0aW9uX2V4ZWN1dGlvbl9zdGF0
ZRgBIAEoDjJYLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5JbnRlZ3JhdGlv
bkV4ZWN1dGlvbkRldGFpbHMuSW50ZWdyYXRpb25FeGVjdXRpb25TdGF0ZUID4EEDUhlpbnRl
Z3JhdGlvbkV4ZWN1dGlvblN0YXRlEoUBCh5pbnRlZ3JhdGlvbl9leGVjdXRpb25fc25hcHNo
b3QYAiADKAsyPy5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuSW50ZWdyYXRp
b25FeGVjdXRpb25TbmFwc2hvdFIcaW50ZWdyYXRpb25FeGVjdXRpb25TbmFwc2hvdBJnChdl
eGVjdXRpb25fYXR0ZW1wdF9zdGF0cxgDIAMoCzIvLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlv
bnMudjFhbHBoYS5BdHRlbXB0U3RhdHNSFWV4ZWN1dGlvbkF0dGVtcHRTdGF0cxJKChNuZXh0
X2V4ZWN1dGlvbl90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIRbmV4
dEV4ZWN1dGlvblRpbWUSNgoXZXhlY3V0aW9uX3JldHJpZXNfY291bnQYBSABKAVSFWV4ZWN1
dGlvblJldHJpZXNDb3VudBIjCg1jYW5jZWxfcmVhc29uGAYgASgJUgxjYW5jZWxSZWFzb24i
sQEKGUludGVncmF0aW9uRXhlY3V0aW9uU3RhdGUSKwonSU5URUdSQVRJT05fRVhFQ1VUSU9O
X1NUQVRFX1VOU1BFQ0lGSUVEEAASCwoHT05fSE9MRBABEg4KCklOX1BST0NFU1MQAhINCglT
VUNDRUVERUQQAxIKCgZGQUlMRUQQBBINCglDQU5DRUxMRUQQBRIRCg1SRVRSWV9PTl9IT0xE
EAYSDQoJU1VTUEVOREVEEAcioQkKHEludGVncmF0aW9uRXhlY3V0aW9uU25hcHNob3QSNAoW
Y2hlY2twb2ludF90YXNrX251bWJlchgBIAEoCVIUY2hlY2twb2ludFRhc2tOdW1iZXISPwoN
c25hcHNob3RfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNuYXBz
aG90VGltZRK7AQonaW50ZWdyYXRpb25fZXhlY3V0aW9uX3NuYXBzaG90X21ldGFkYXRhGAMg
ASgLMmQuZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLkludGVncmF0aW9uRXhl
Y3V0aW9uU25hcHNob3QuSW50ZWdyYXRpb25FeGVjdXRpb25TbmFwc2hvdE1ldGFkYXRhUiRp
bnRlZ3JhdGlvbkV4ZWN1dGlvblNuYXBzaG90TWV0YWRhdGESbQoWdGFza19leGVjdXRpb25f
ZGV0YWlscxgEIAMoCzI3Lmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5UYXNr
RXhlY3V0aW9uRGV0YWlsc1IUdGFza0V4ZWN1dGlvbkRldGFpbHMSXwoRY29uZGl0aW9uX3Jl
c3VsdHMYBSADKAsyMi5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuQ29uZGl0
aW9uUmVzdWx0UhBjb25kaXRpb25SZXN1bHRzEn8KEGV4ZWN1dGlvbl9wYXJhbXMYBiADKAsy
VC5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuSW50ZWdyYXRpb25FeGVjdXRp
b25TbmFwc2hvdC5FeGVjdXRpb25QYXJhbXNFbnRyeVIPZXhlY3V0aW9uUGFyYW1zGoMDCiRJ
bnRlZ3JhdGlvbkV4ZWN1dGlvblNuYXBzaG90TWV0YWRhdGESHwoLdGFza19udW1iZXIYASAB
KAlSCnRhc2tOdW1iZXISEgoEdGFzaxgCIAEoCVIEdGFzaxJJCiFpbnRlZ3JhdGlvbl9leGVj
dXRpb25fYXR0ZW1wdF9udW0YAyABKAVSHmludGVncmF0aW9uRXhlY3V0aW9uQXR0ZW1wdE51
bRIoChB0YXNrX2F0dGVtcHRfbnVtGAQgASgFUg50YXNrQXR0ZW1wdE51bRIdCgp0YXNrX2xh
YmVsGAUgASgJUgl0YXNrTGFiZWwSMgoVYW5jZXN0b3JfdGFza19udW1iZXJzGAYgAygJUhNh
bmNlc3RvclRhc2tOdW1iZXJzEjwKGmFuY2VzdG9yX2l0ZXJhdGlvbl9udW1iZXJzGAcgAygJ
UhhhbmNlc3Rvckl0ZXJhdGlvbk51bWJlcnMSIAoLaW50ZWdyYXRpb24YCCABKAlSC2ludGVn
cmF0aW9uGnUKFEV4ZWN1dGlvblBhcmFtc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkcKBXZh
bHVlGAIgASgLMjEuZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLkV2ZW50UGFy
YW1ldGVyUgV2YWx1ZToCOAEimQQKFFRhc2tFeGVjdXRpb25EZXRhaWxzEh8KC3Rhc2tfbnVt
YmVyGAEgASgJUgp0YXNrTnVtYmVyEnwKFHRhc2tfZXhlY3V0aW9uX3N0YXRlGAIgASgOMkou
Z29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLlRhc2tFeGVjdXRpb25EZXRhaWxz
LlRhc2tFeGVjdXRpb25TdGF0ZVISdGFza0V4ZWN1dGlvblN0YXRlEl0KEnRhc2tfYXR0ZW1w
dF9zdGF0cxgDIAMoCzIvLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5BdHRl
bXB0U3RhdHNSEHRhc2tBdHRlbXB0U3RhdHMiggIKElRhc2tFeGVjdXRpb25TdGF0ZRIkCiBU
QVNLX0VYRUNVVElPTl9TVEFURV9VTlNQRUNJRklFRBAAEhUKEVBFTkRJTkdfRVhFQ1VUSU9O
EAESDgoKSU5fUFJPQ0VTUxACEgsKB1NVQ0NFRUQQAxIKCgZGQUlMRUQQBBIJCgVGQVRBTBAF
EhEKDVJFVFJZX09OX0hPTEQQBhILCgdTS0lQUEVEEAcSDQoJQ0FOQ0VMTEVEEAgSFAoQUEVO
RElOR19ST0xMQkFDSxAJEhcKE1JPTExCQUNLX0lOX1BST0NFU1MQChIOCgpST0xMRURCQUNL
EAsSDQoJU1VTUEVOREVEEAwigAEKDEF0dGVtcHRTdGF0cxI5CgpzdGFydF90aW1lGAEgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5kVGltZSJTCgtFcnJvckRldGFp
bBIjCg1lcnJvcl9tZXNzYWdlGAEgASgJUgxlcnJvck1lc3NhZ2USHwoLdGFza19udW1iZXIY
AiABKAVSCnRhc2tOdW1iZXIigwEKD0NvbmRpdGlvblJlc3VsdBIuChNjdXJyZW50X3Rhc2tf
bnVtYmVyGAEgASgJUhFjdXJyZW50VGFza051bWJlchIoChBuZXh0X3Rhc2tfbnVtYmVyGAIg
ASgJUg5uZXh0VGFza051bWJlchIWCgZyZXN1bHQYAyABKAhSBnJlc3VsdCpXCg1FeGVjdXRp
b25UeXBlEh4KGkVYRUNVVElPTl9UWVBFX1VOU1BFQ0lGSUVEEAASFwoTSU5URUdSQVRJT05f
VkVSU0lPThABEg0KCVRFU1RfQ0FTRRACQqkBCiVjb20uZ29vZ2xlLmNsb3VkLmludGVncmF0
aW9ucy52MWFscGhhQg9Mb2dFbnRyaWVzUHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNvbS9nby9p
bnRlZ3JhdGlvbnMvYXBpdjFhbHBoYS9pbnRlZ3JhdGlvbnNwYjtpbnRlZ3JhdGlvbnNwYqoC
IUdvb2dsZS5DbG91ZC5JbnRlZ3JhdGlvbnMuVjFBbHBoYUrgYQoHEgUOAOUCAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkKAgMB
EgMTAEcKCQoCAwISAxQAQQoJCgIDAxIDFQBDCgkKAgMEEgMWAD0KCQoCAwUSAxcAKQoICgEI
EgMZAD4KCQoCCCUSAxkAPgoICgEIEgMaAGAKCQoCCAsSAxoAYAoICgEIEgMbACIKCQoCCAoS
AxsAIgoICgEIEgMcADAKCQoCCAgSAxwAMAoICgEIEgMdAD4KCQoCCAESAx0APgp8CgIEABIF
IQCLAQEabyBMb2cgZW50cnkgdG8gbG9nIGV4ZWN1dGlvbiBpbmZvIGZvciB0aGUgbW9uaXRv
cmVkIHJlc291cmNlCiBgaW50ZWdyYXRpb25zLmdvb2dsZWFwaXMuY29tL0ludGVncmF0aW9u
VmVyc2lvbmAuCgoKCgMEAAESAyEIFQokCgQEAAQAEgQjAi8DGhYgRXhlY3V0aW9uTWV0aG9k
IEVudW0KCgwKBQQABAABEgMjBxYKHwoGBAAEAAIAEgMlBCUaECBEZWZhdWx0IHZhbHVlLgoK
DgoHBAAEAAIAARIDJQQgCg4KBwQABAACAAISAyUjJAobCgYEAAQAAgESAygEDRoMIFN5bmMg
cG9zdC4KCg4KBwQABAACAQESAygECAoOCgcEAAQAAgECEgMoCwwKLwoGBAAEAAICEgMrBBEa
ICBBc3luYyBwb3N0IHdpdGggc2NoZWR1bGUgdGltZS4KCg4KBwQABAACAgESAysEDAoOCgcE
AAQAAgICEgMrDxAKHAoGBAAEAAIDEgMuBBYaDSBBc3luYyBwb3N0LgoKDgoHBAAEAAIDARID
LgQRCg4KBwQABAACAwISAy4UFQqiAQoEBAADABIEMwJPAxqTASBDb250YWlucyB0aGUgZGV0
YWlscyBvZiB0aGUgZXhlY3V0aW9uIGluZm86IHRoaXMgaW5jbHVkZXMgdGhlIHJlcGxheSBy
ZWFzb24KIGFuZCByZXBsYXkgdHJlZSBjb25uZWN0aW5nIGV4ZWN1dGlvbnMgaW4gYSBwYXJl
bnQtY2hpbGQgcmVsYXRpb25zaGlwCgoMCgUEAAMAARIDMwoUCswBCgYEAAMABAASBDcEQAUa
uwEgUmVwbGF5IG1vZGUgZm9yIHRoZSBleGVjdXRpb24uIFRoZSBkZWZhdWx0IGJlaGF2b2ly
IGlzIHJlcGxheSBmcm9tCiBiZWdpbm5pbmcuIElmIHRoZSByZXBsYXkgbW9kZSBpcyBzZXQg
dG8gcG9pbnQgb2YgZmFpbHVyZSwgdGhlIGV4ZWN1dGlvbgogd2lsbCBiZSByZXBsYXllZCBm
cm9tIHRoZSBmaXJzdCBmYWlsZWQgdGFzay4KCg4KBwQAAwAEAAESAzcJEwohCggEAAMABAAC
ABIDOQYiGhAgRGVmYXVsdCB2YWx1ZS4KChAKCQQAAwAEAAIAARIDOQYdChAKCQQAAwAEAAIA
AhIDOSAhCjEKCAQAAwAEAAIBEgM8BiUaICBSZXBsYXkgdGhlIG9yaWdpbmFsIGV4ZWN1dGlv
bi4KChAKCQQAAwAEAAIBARIDPAYgChAKCQQAAwAEAAIBAhIDPCMkCkUKCAQAAwAEAAICEgM/
BicaNCBSZXBsYXkgdGhlIGV4ZWN1dGlvbiB3aXRoIHRoZSBtb2RpZmllZCBwYXJhbWV0ZXJz
LgoKEAoJBAADAAQAAgIBEgM/BiIKEAoJBAADAAQAAgICEgM/JSYKeQoGBAADAAIAEgNEBCoa
aiBJZiB0aGlzIGV4ZWN1dGlvbiBpcyBhIHJlcGxheSBvZiBhbm90aGVyIGV4ZWN1dGlvbiwg
dGhlbiB0aGlzIGZpZWxkCiBjb250YWlucyB0aGUgb3JpZ2luYWwgZXhlY3V0aW9uIGlkLgoK
DgoHBAADAAIABRIDRAQKCg4KBwQAAwACAAESA0QLJQoOCgcEAAMAAgADEgNEKCkKfQoGBAAD
AAIBEgNIBDQabiBJZiB0aGlzIGV4ZWN1dGlvbiBoYXMgYmVlbiByZXBsYXllZCwgdGhlbiB0
aGlzIGZpZWxkIGNvbnRhaW5zIHRoZQogZXhlY3V0aW9uIGlkcyBvZiB0aGUgcmVwbGF5ZWQg
ZXhlY3V0aW9ucy4KCg4KBwQAAwACAQQSA0gEDAoOCgcEAAMAAgEFEgNIDRMKDgoHBAADAAIB
ARIDSBQvCg4KBwQAAwACAQMSA0gyMwoiCgYEAAMAAgISA0sEHRoTIHJlYXNvbiBmb3IgcmVw
bGF5CgoOCgcEAAMAAgIFEgNLBAoKDgoHBAADAAICARIDSwsYCg4KBwQAAwACAgMSA0sbHAoy
CgYEAAMAAgMSA04ESBojIE9wdGlvbmFsLiBUaGUgbW9kZSBvZiB0aGUgcmVwbGF5LgoKDgoH
BAADAAIDBhIDTgQOCg4KBwQAAwACAwESA04PGgoOCgcEAAMAAgMDEgNOHR4KDgoHBAADAAID
CBIDTh9HChEKCgQAAwACAwicCAASA04gRgonCgQEAAIAEgNSAhkaGiBOYW1lIG9mIHRoZSBp
bnRlZ3JhdGlvbi4KCgwKBQQAAgAFEgNSAggKDAoFBAACAAESA1IJFAoMCgUEAAIAAxIDUhcY
Ci0KBAQAAgESA1UCGBogIFRoZSBjdXN0b21lcidzIHByb2plY3QgbnVtYmVyLgoKDAoFBAAC
AQUSA1UCCAoMCgUEAAIBARIDVQkTCgwKBQQAAgEDEgNVFhcKgQIKBAQAAgISA1sCGBrzASBU
aGUgdHJpZ2dlciBpZCBvZiB0aGUgaW50ZWdyYXRpb24gdHJpZ2dlciBjb25maWcuIElmIGJv
dGggdHJpZ2dlcl9pZAogYW5kIGNsaWVudF9pZCBpcyBwcmVzZW50LCB0aGUgaW50ZWdyYXRp
b24gaXMgZXhlY3V0ZWQgZnJvbSB0aGUgc3RhcnQgdGFza3MKIHByb3ZpZGVkIGJ5IHRoZSBt
YXRjaGluZyB0cmlnZ2VyIGNvbmZpZyBvdGhlcndpc2UgaXQgaXMgZXhlY3V0ZWQgZnJvbSB0
aGUKIGRlZmF1bHQgc3RhcnQgdGFza3MuCgoMCgUEAAICBRIDWwIICgwKBQQAAgIBEgNbCRMK
DAoFBAACAgMSA1sWFwpDCgQEAAIDEgNeAjEaNiBFeGVjdXRpb24gcGFyYW1ldGVycyBjb21l
IGluIGFzIHBhcnQgb2YgdGhlIHJlcXVlc3QuCgoMCgUEAAIDBhIDXgIdCgwKBQQAAgMBEgNe
HiwKDAoFBAACAwMSA14vMApFCgQEAAIEEgNhAjIaOCBFeGVjdXRpb24gcGFyYW1ldGVycyBj
b21lIG91dCBhcyBwYXJ0IG9mIHRoZSByZXNwb25zZS4KCgwKBQQAAgQGEgNhAh0KDAoFBAAC
BAESA2EeLQoMCgUEAAIEAxIDYTAxCqYBCgQEAAIFEgNmAiMamAEgRXJyb3JzLCB3YXJuaW5n
cywgYW5kIGluZm9ybWF0aW9uYWxzIGFzc29jaWF0ZWQgd2l0aCB0aGUgd29ya2Zsb3cvdGFz
ay4KIFRoZSBvcmRlciBpbiB3aGljaCB0aGUgZXJyb3JzIHdlcmUgYWRkZWQgYnkgdGhlIHdv
cmtmbG93L3Rhc2sgaXMKIG1haW50YWluZWQuCgoMCgUEAAIFBBIDZgIKCgwKBQQAAgUGEgNm
CxYKDAoFBAACBQESA2YXHQoMCgUEAAIFAxIDZiAiCjQKBAQAAgYSA2kCKBonIFRoZSBjb25m
aWd1cmF0aW9uIGRldGFpbHMgZm9yIGEgdGFzay4KCgwKBQQAAgYEEgNpAgoKDAoFBAACBgYS
A2kLFQoMCgUEAAIGARIDaRYiCgwKBQQAAgYDEgNpJScKPQoEBAACBxIDbAIpGjAgUG9pbnRl
ciB0byB0aGUgYWN0aXZlIHZlcnNpb24gaXQgaXMgZXhlY3V0aW5nLgoKDAoFBAACBwUSA2wC
CAoMCgUEAAIHARIDbAkjCgwKBQQAAgcDEgNsJigKKgoEBAACCBIDbwIbGh0gQXV0by1nZW5l
cmF0ZWQgcHJpbWFyeSBrZXkuCgoMCgUEAAIIBRIDbwIICgwKBQQAAggBEgNvCRUKDAoFBAAC
CAMSA28YGgo9CgQEAAIJEgRyAnMyGi8gT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBpbnRl
Z3JhdGlvbiB2ZXJzaW9uCgoMCgUEAAIJBhIDcgISCgwKBQQAAgkBEgNyEywKDAoFBAACCQMS
A3IvMQoMCgUEAAIJCBIDcwYxCg8KCAQAAgkInAgAEgNzBzAKPQoEBAACChIDdgIoGjAgRGF0
YWJhc2UgcGVyc2lzdGVuY2UgcG9saWN5IGZvciBleGVjdXRpb24gaW5mbwoKDAoFBAACCgUS
A3YCBgoMCgUEAAIKARIDdgciCgwKBQQAAgoDEgN2JScKNwoEBAACCxIDeQIxGiogQ2xvdWQg
TG9nZ2luZyBkZXRhaWxzIGZvciBleGVjdXRpb24gaW5mbwoKDAoFBAACCwYSA3kCFQoMCgUE
AAILARIDeRYrCgwKBQQAAgsDEgN5LjAKPAoEBAACDBIDfAJBGi8gVGhlIGRldGFpbHMgYWJv
dXQgdGhpcyBpbnRlZ3JhdGlvbiBleGVjdXRpb24uCgoMCgUEAAIMBhIDfAIdCgwKBQQAAgwB
EgN8HjsKDAoFBAACDAMSA3w+QApmCgQEAAINEgSAAQIkGlggU3BlY2lmaWVzIHdoZXRoZXIg
dGhpcyBleGVjdXRpb24gaW5mbyBjb3JyZXNwb25kcyB0byBhY3R1YWwgaW50ZWdyYXRpb24g
b3IKIHRlc3QgY2FzZS4KCg0KBQQAAg0GEgSAAQIPCg0KBQQAAg0BEgSAARAeCg0KBQQAAg0D
EgSAASEjCi8KBAQAAg4SBIMBAigaISBUaGUgd2F5cyB1c2VyIHBvc3RzIHRoaXMgZXZlbnQu
CgoNCgUEAAIOBhIEgwECEQoNCgUEAAIOARIEgwESIgoNCgUEAAIOAxIEgwElJwppCgQEAAIP
EgSHAQIpGlsgQW4gaW5jcmVhc2luZyBzZXF1ZW5jZSB0aGF0IGlzIHNldCB3aGVuIGEgbmV3
IHNuYXBzaG90IChJbnRlZ3JhdGlvbgogVmVyc2lvbikgaXMgY3JlYXRlZC4KCg0KBQQAAg8F
EgSHAQIHCg0KBQQAAg8BEgSHAQgjCg0KBQQAAg8DEgSHASYoCi0KBAQAAhASBIoBAh4aHyBS
ZXBsYXkgaW5mbyBmb3IgdGhlIGV4ZWN1dGlvbgoKDQoFBAACEAYSBIoBAgwKDQoFBAACEAES
BIoBDRgKDQoFBAACEAMSBIoBGx0KkgEKAgQBEgaPAQDDAQEagwEgQ29udGFpbnMgdGhlIGRl
dGFpbHMgb2YgdGhlIGV4ZWN1dGlvbiBpbmZvOiB0aGlzIGluY2x1ZGVzIHRoZSB0YXNrcyBl
eGVjdXRpb24KIGRldGFpbHMgcGx1cyB0aGUgaW50ZWdyYXRpb24gZXhlY3V0aW9uIHN0YXRp
c3RpY3MuCgoLCgMEAQESBI8BCCMKJgoEBAEEABIGkQECrAEDGhYgRW51bSBFeGVjdXRpb25T
dGF0ZS4KCg0KBQQBBAABEgSRAQcgCiAKBgQBBAACABIEkwEEMBoQIERlZmF1bHQgdmFsdWUu
CgoPCgcEAQQAAgABEgSTAQQrCg8KBwQBBAACAAISBJMBLi8KlAEKBgQBBAACARIElwEEEBqD
ASBJbnRlZ3JhdGlvbiBpcyByZWNlaXZlZCBhbmQgd2FpdGluZyBmb3IgdGhlIGV4ZWN1dGlv
bi4gVGhpcyBoYXBwZW5zIHdoZW4KIGZpcmluZyB0aGUgSW50ZWdyYXRpb24gdmlhICJwb3N0
VG9RdWV1ZSIgb3IgInNjaGVkdWxlIi4KCg8KBwQBBAACAQESBJcBBAsKDwoHBAEEAAIBAhIE
lwEODwoyCgYEAQQAAgISBJoBBBMaIiBJbnRlZ3JhdGlvbiBpcyB1bmRlciBwcm9jZXNzaW5n
LgoKDwoHBAEEAAICARIEmgEEDgoPCgcEAQQAAgICEgSaARESCmgKBgQBBAACAxIEngEEEhpY
IEludGVncmF0aW9uIGV4ZWN1dGlvbiBzdWNjZXNzZnVsbHkgZmluaXNoZWQuIFRoZXJlJ3Mg
bm8gbW9yZSBjaGFuZ2UgYWZ0ZXIKIHRoaXMgc3RhdGUuCgoPCgcEAQQAAgMBEgSeAQQNCg8K
BwQBBAACAwISBJ4BEBEKWAoGBAEEAAIEEgShAQQPGkggSW50ZWdyYXRpb24gZXhlY3V0aW9u
IGZhaWxlZC4gVGhlcmUncyBubyBtb3JlIGNoYW5nZSBhZnRlciB0aGlzIHN0YXRlLgoKDwoH
BAEEAAIEARIEoQEECgoPCgcEAQQAAgQCEgShAQ0OCmMKBgQBBAACBRIEpQEEEhpTIEludGVn
cmF0aW9uIGV4ZWN1dGlvbiBjYW5jZWxlZCBieSB1c2VyLiBUaGVyZSdzIG5vIG1vcmUgY2hh
bmdlIGFmdGVyIHRoaXMKIHN0YXRlLgoKDwoHBAEEAAIFARIEpQEEDQoPCgcEAQQAAgUCEgSl
ARARCkUKBgQBBAACBhIEqAEEFho1IEludGVncmF0aW9uIGV4ZWN1dGlvbiBmYWlsZWQgYW5k
IHdhaXRpbmcgZm9yIHJldHJ5LgoKDwoHBAEEAAIGARIEqAEEEQoPCgcEAQQAAgYCEgSoARQV
ClYKBgQBBAACBxIEqwEEEhpGIEludGVncmF0aW9uIGV4ZWN1dGlvbiBzdXNwZW5kZWQgYW5k
IHdhaXRpbmcgZm9yIG1hbnVhbCBpbnRlcnZlbnRpb24uCgoPCgcEAQQAAgcBEgSrAQQNCg8K
BwQBBAACBwISBKsBEBEKRwoEBAECABIGrwECsAEyGjcgT3V0cHV0IG9ubHkuIFRoZSBleGVj
dXRpb24gc3RhdGUgb2YgdGhpcyBJbnRlZ3JhdGlvbi4KCg0KBQQBAgAGEgSvAQIbCg0KBQQB
AgABEgSvARw3Cg0KBQQBAgADEgSvATo7Cg0KBQQBAgAIEgSwAQYxChAKCAQBAgAInAgAEgSw
AQcwCiMKBAQBAgESBLMBAksaFSBFeGVjdXRpb24gc25hcHNob3QuCgoNCgUEAQIBBBIEswEC
CgoNCgUEAQIBBhIEswELJwoNCgUEAQIBARIEswEoRgoNCgUEAQIBAxIEswFJSgo5CgQEAQIC
EgS2AQI0GisgU3RhdHVzIGZvciB0aGUgY3VycmVudCBleGVjdXRpb24gYXR0ZW1wdC4KCg0K
BQQBAgIEEgS2AQIKCg0KBQQBAgIGEgS2AQsXCg0KBQQBAgIBEgS2ARgvCg0KBQQBAgIDEgS2
ATIzCl4KBAQBAgMSBLoBAjQaUCBOZXh0IHNjaGVkdWxlZCBleGVjdXRpb24gdGltZSBpbiBj
YXNlIHRoZSBleGVjdXRpb24gc3RhdHVzIHdhcwogUkVUUllfT05fSE9MRC4KCg0KBQQBAgMG
EgS6AQIbCg0KBQQBAgMBEgS6ARwvCg0KBQQBAgMDEgS6ATIzCl4KBAQBAgQSBL4BAiQaUCBJ
bmRpY2F0ZXMgdGhlIG51bWJlciBvZiB0aW1lcyB0aGUgZXhlY3V0aW9uIGhhcyByZXN0YXJ0
ZWQgZnJvbSB0aGUKIGJlZ2lubmluZy4KCg0KBQQBAgQFEgS+AQIHCg0KBQQBAgQBEgS+AQgf
Cg0KBQQBAgQDEgS+ASIjCmwKBAQBAgUSBMIBAhsaXiBJZiB0aGUgZXhlY3V0aW9uIGlzIG1h
bnVhbGx5IGNhbmNlbGVkLCB0aGlzIGZpZWxkIHdpbGwgY29udGFpbiB0aGUgcmVhc29uCiBm
b3IgY2FuY2VsbGF0aW9uLgoKDQoFBAECBQUSBMIBAggKDQoFBAECBQESBMIBCRYKDQoFBAEC
BQMSBMIBGRoKWgoCBAISBsYBAPcBARpMIENvbnRhaW5zIHRoZSBzbmFwc2hvdCBvZiB0aGUg
aW50ZWdyYXRpb24gZXhlY3V0aW9uIGZvciBhIGdpdmVuIGNoZWNrcG9pbnQuCgoLCgMEAgES
BMYBCCQKOgoEBAIDABIGyAEC4gEDGiogTWV0YWRhdGEgZm9yIHRoZSBpbnRlZ3JhdGlvbi90
YXNrIHJldHJ5LgoKDQoFBAIDAAESBMgBCi4KUAoGBAIDAAIAEgTKAQQbGkAgVGhlIHRhc2sg
bnVtYmVyIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHNuYXBzaG90LiBDb3VsZCBiZSBlbXB0eS4K
Cg8KBwQCAwACAAUSBMoBBAoKDwoHBAIDAAIAARIEygELFgoPCgcEAgMAAgADEgTKARkaCk4K
BgQCAwACARIEzQEEFBo+IHRoZSB0YXNrIG5hbWUgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc25h
cHNob3QuIENvdWxkIGJlIGVtcHR5LgoKDwoHBAIDAAIBBRIEzQEECgoPCgcEAgMAAgEBEgTN
AQsPCg8KBwQCAwACAQMSBM0BEhMKVAoGBAIDAAICEgTQAQQwGkQgdGhlIGludGVncmF0aW9u
IGV4ZWN1dGlvbiBhdHRlbXB0IG51bWJlciB0aGlzIHNuYXBzaG90IGJlbG9uZ3MgdG8uCgoP
CgcEAgMAAgIFEgTQAQQJCg8KBwQCAwACAgESBNABCisKDwoHBAIDAAICAxIE0AEuLwpTCgYE
AgMAAgMSBNMBBB8aQyB0aGUgdGFzayBhdHRlbXB0IG51bWJlciB0aGlzIHNuYXBzaG90IGJl
bG9uZ3MgdG8uIENvdWxkIGJlIGVtcHR5LgoKDwoHBAIDAAIDBRIE0wEECQoPCgcEAgMAAgMB
EgTTAQoaCg8KBwQCAwACAwMSBNMBHR4KTwoGBAIDAAIEEgTWAQQaGj8gdGhlIHRhc2sgbGFi
ZWwgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc25hcHNob3QuIENvdWxkIGJlIGVtcHR5LgoKDwoH
BAIDAAIEBRIE1gEECgoPCgcEAgMAAgQBEgTWAQsVCg8KBwQCAwACBAMSBNYBGBkKdwoGBAID
AAIFEgTaAQQuGmcgQW5jZXN0b3IgdGFzayBudW1iZXIgZm9yIHRoZSB0YXNrKGl0IHdpbGwg
b25seSBiZSBub24tZW1wdHkgaWYgdGhlIHRhc2sKIGlzIHVuZGVyICdwcml2YXRlIHdvcmtm
bG93JykKCg8KBwQCAwACBQQSBNoBBAwKDwoHBAIDAAIFBRIE2gENEwoPCgcEAgMAAgUBEgTa
ARQpCg8KBwQCAwACBQMSBNoBLC0KfAoGBAIDAAIGEgTeAQQzGmwgQW5jZXN0b3IgaXRlcmF0
aW9uIG51bWJlciBmb3IgdGhlIHRhc2soaXQgd2lsbCBvbmx5IGJlIG5vbi1lbXB0eSBpZiB0
aGUKIHRhc2sgaXMgdW5kZXIgJ3ByaXZhdGUgd29ya2Zsb3cnKQoKDwoHBAIDAAIGBBIE3gEE
DAoPCgcEAgMAAgYFEgTeAQ0TCg8KBwQCAwACBgESBN4BFC4KDwoHBAIDAAIGAxIE3gExMgpX
CgYEAgMAAgcSBOEBBBsaRyBUaGUgZGlyZWN0IGludGVncmF0aW9uIHdoaWNoIHRoZSBldmVu
dCBleGVjdXRpb24gc25hcHNob3RzIGJlbG9uZ3MgdG8KCg8KBwQCAwACBwUSBOEBBAoKDwoH
BAIDAAIHARIE4QELFgoPCgcEAgMAAgcDEgThARkaCmIKBAQCAgASBOYBAiQaVCBJbmRpY2F0
ZXMgInJpZ2h0IGFmdGVyIHdoaWNoIGNoZWNrcG9pbnQgdGFzaydzIGV4ZWN1dGlvbiIgdGhp
cyBzbmFwc2hvdAogaXMgdGFrZW4uCgoNCgUEAgIABRIE5gECCAoNCgUEAgIAARIE5gEJHwoN
CgUEAgIAAxIE5gEiIwo2CgQEAgIBEgTpAQIuGiggSW5kaWNhdGVzIHdoZW4gdGhpcyBzbmFw
c2hvdCBpcyB0YWtlbi4KCg0KBQQCAgEGEgTpAQIbCg0KBQQCAgEBEgTpARwpCg0KBQQCAgED
EgTpASwtCiQKBAQCAgISBuwBAu0BCBoUIFNuYXBzaG90IG1ldGFkYXRhLgoKDQoFBAICAgYS
BOwBAiYKDQoFBAICAgESBOwBJ04KDQoFBAICAgMSBO0BBgcKTQoEBAICAxIE8AECOxo/IEFs
bCBvZiB0aGUgdGFzayBleGVjdXRpb24gZGV0YWlscyBhdCB0aGUgZ2l2ZW4gcG9pbnQgb2Yg
dGltZS4KCg0KBQQCAgMEEgTwAQIKCg0KBQQCAgMGEgTwAQsfCg0KBQQCAgMBEgTwASA2Cg0K
BQQCAgMDEgTwATk6CkQKBAQCAgQSBPMBAjEaNiBBbGwgb2YgdGhlIGNvbXB1dGVkIGNvbmRp
dGlvbnMgdGhhdCBiZWVuIGNhbGN1bGF0ZWQuCgoNCgUEAgIEBBIE8wECCgoNCgUEAgIEBhIE
8wELGgoNCgUEAgIEARIE8wEbLAoNCgUEAgIEAxIE8wEvMAovCgQEAgIFEgT2AQIzGiEgVGhl
IHBhcmFtZXRlcnMgaW4gRXZlbnQgb2JqZWN0LgoKDQoFBAICBQYSBPYBAh0KDQoFBAICBQES
BPYBHi4KDQoFBAICBQMSBPYBMTIKQwoCBAMSBvoBALYCARo1IENvbnRhaW5zIHRoZSBkZXRh
aWxzIG9mIHRoZSBleGVjdXRpb24gb2YgdGhpcyB0YXNrLgoKCwoDBAMBEgT6AQgcCioKBAQD
BAASBvwBAqwCAxoaIEVudW0gVGFza0V4ZWN1dGlvblN0YXRlLgoKDQoFBAMEAAESBPwBBxkK
IAoGBAMEAAIAEgT+AQQpGhAgRGVmYXVsdCB2YWx1ZS4KCg8KBwQDBAACAAESBP4BBCQKDwoH
BAMEAAIAAhIE/gEnKApfCgYEAwQAAgESBIICBBoaTyBUYXNrIGlzIHdhaXRpbmcgZm9yIGl0
cyBwcmVjb25kaXRpb24gdGFza3MgdG8gZmluaXNoIHRvIHN0YXJ0IHRoZQogZXhlY3V0aW9u
LgoKDwoHBAMEAAIBARIEggIEFQoPCgcEAwQAAgECEgSCAhgZCisKBgQDBAACAhIEhQIEExob
IFRhc2sgaXMgdW5kZXIgcHJvY2Vzc2luZy4KCg8KBwQDBAACAgESBIUCBA4KDwoHBAMEAAIC
AhIEhQIREgphCgYEAwQAAgMSBIkCBBAaUSBUYXNrIGV4ZWN1dGlvbiBzdWNjZXNzZnVsbHkg
ZmluaXNoZWQuIFRoZXJlJ3Mgbm8gbW9yZSBjaGFuZ2UgYWZ0ZXIKIHRoaXMgc3RhdGUuCgoP
CgcEAwQAAgMBEgSJAgQLCg8KBwQDBAACAwISBIkCDg8KUQoGBAMEAAIEEgSMAgQPGkEgVGFz
ayBleGVjdXRpb24gZmFpbGVkLiBUaGVyZSdzIG5vIG1vcmUgY2hhbmdlIGFmdGVyIHRoaXMg
c3RhdGUuCgoPCgcEAwQAAgQBEgSMAgQKCg8KBwQDBAACBAISBIwCDQ4KkQEKBgQDBAACBRIE
kAIEDhqAASBUYXNrIGV4ZWN1dGlvbiBmYWlsZWQgYW5kIGNhdXNlIHRoZSB3aG9sZSBpbnRl
Z3JhdGlvbiBleGVjdXRpb24gdG8gZmFpbAogaW1tZWRpYXRlbHkuIFRoZXJlJ3Mgbm8gbW9y
ZSBjaGFuZ2UgYWZ0ZXIgdGhpcyBzdGF0ZS4KCg8KBwQDBAACBQESBJACBAkKDwoHBAMEAAIF
AhIEkAIMDQo+CgYEAwQAAgYSBJMCBBYaLiBUYXNrIGV4ZWN1dGlvbiBmYWlsZWQgYW5kIHdh
aXRpbmcgZm9yIHJldHJ5LgoKDwoHBAMEAAIGARIEkwIEEQoPCgcEAwQAAgYCEgSTAhQVCsoB
CgYEAwQAAgcSBJgCBBAauQEgVGFzayBleGVjdXRpb24gc2tpcHBlZC4gVGhpcyBoYXBwZW5z
IHdoZW4gaXRzIHByZWNvbmRpdGlvbiB3YXNuJ3QgbWV0LAogb3IgdGhlIGludGVncmF0aW9u
IGV4ZWN1dGlvbiBiZWVuIGNhbmNlbGVkIGJlZm9yZSByZWFjaCB0byB0aGUgdGFzay4KIFRo
ZXJlJ3Mgbm8gbW9yZSBjaGFuZ2VzIGFmdGVyIHRoaXMgc3RhdGUuCgoPCgcEAwQAAgcBEgSY
AgQLCg8KBwQDBAACBwISBJgCDg8KmgEKBgQDBAACCBIEnAIEEhqJASBUYXNrIGV4ZWN1dGlv
biBjYW5jZWxlZCB3aGVuIGluIHByb2dyZXNzLiBUaGlzIGhhcHBlbnMgd2hlbiBpbnRlZ3Jh
dGlvbgogZXhlY3V0aW9uIGJlZW4gY2FuY2VsZWQgb3IgYW55IG90aGVyIHRhc2sgZmFsbCBp
biBmYXRhbCBzdGF0ZS4KCg8KBwQDBAACCAESBJwCBA0KDwoHBAMEAAIIAhIEnAIQEQpmCgYE
AwQAAgkSBKACBBkaViBUYXNrIGlzIHdhaXRpbmcgZm9yIGl0cyBkZXBlbmRlbmN5IHRhc2tz
JyByb2xsYmFjayB0byBmaW5pc2ggdG8gc3RhcnQKIGl0cyByb2xsYmFjay4KCg8KBwQDBAAC
CQESBKACBBQKDwoHBAMEAAIJAhIEoAIXGAonCgYEAwQAAgoSBKMCBB0aFyBUYXNrIGlzIHJv
bGxpbmcgYmFjay4KCg8KBwQDBAACCgESBKMCBBcKDwoHBAMEAAIKAhIEowIaHApzCgYEAwQA
AgsSBKcCBBQaYyBUYXNrIGlzIHJvbGxlZCBiYWNrLiBUaGlzIGlzIHRoZSBzdGF0ZSB3ZSB3
aWxsIHNldCByZWdhcmRsZXNzIG9mCiByb2xsYmFjayBzdWNjZWVkaW5nIG9yIGZhaWxpbmcu
CgoPCgcEAwQAAgsBEgSnAgQOCg8KBwQDBAACCwISBKcCERMKYwoGBAMEAAIMEgSrAgQTGlMg
VGFzayBpcyBhIFN1c3BlbnNpb25UYXNrIHdoaWNoIGhhcyBleGVjdXRlZCBvbmNlLCBjcmVh
dGluZyBhIHBlbmRpbmcKIHN1c3BlbnNpb24uCgoPCgcEAwQAAgwBEgSrAgQNCg8KBwQDBAAC
DAISBKsCEBIKQQoEBAMCABIErwICGRozIFBvaW50ZXIgdG8gdGhlIHRhc2sgY29uZmlnIGl0
IHVzZWQgZm9yIGV4ZWN1dGlvbi4KCg0KBQQDAgAFEgSvAgIICg0KBQQDAgABEgSvAgkUCg0K
BQQDAgADEgSvAhcYCjEKBAQDAgESBLICAi4aIyBUaGUgZXhlY3V0aW9uIHN0YXRlIG9mIHRo
aXMgdGFzay4KCg0KBQQDAgEGEgSyAgIUCg0KBQQDAgEBEgSyAhUpCg0KBQQDAgEDEgSyAiwt
Cj4KBAQDAgISBLUCAi8aMCBTdGF0dXMgZm9yIHRoZSBjdXJyZW50IHRhc2sgZXhlY3V0aW9u
IGF0dGVtcHQuCgoNCgUEAwICBBIEtQICCgoNCgUEAwICBhIEtQILFwoNCgUEAwICARIEtQIY
KgoNCgUEAwICAxIEtQItLgoxCgIEBBIGuQIAwAIBGiMgU3RhdHVzIGZvciB0aGUgZXhlY3V0
aW9uIGF0dGVtcHQuCgoLCgMEBAESBLkCCBQKhQEKBAQEAgASBLwCAisadyBUaGUgc3RhcnQg
dGltZSBvZiB0aGUgaW50ZWdyYXRpb24gZXhlY3V0aW9uIGZvciBjdXJyZW50IGF0dGVtcHQu
IFRoaXMgY291bGQKIGJlIGluIHRoZSBmdXR1cmUgaWYgaXQncyBiZWVuIHNjaGVkdWxlZC4K
Cg0KBQQEAgAGEgS8AgIbCg0KBQQEAgABEgS8AhwmCg0KBQQEAgADEgS8AikqCk4KBAQEAgES
BL8CAikaQCBUaGUgZW5kIHRpbWUgb2YgdGhlIGludGVncmF0aW9uIGV4ZWN1dGlvbiBmb3Ig
Y3VycmVudCBhdHRlbXB0LgoKDQoFBAQCAQYSBL8CAhsKDQoFBAQCAQESBL8CHCQKDQoFBAQC
AQMSBL8CJygKWQoCBAUSBsMCAMsCARpLIEFuIGVycm9yLCB3YXJuaW5nLCBvciBpbmZvcm1h
dGlvbiBtZXNzYWdlIGFzc29jaWF0ZWQgd2l0aCBhbiBpbnRlZ3JhdGlvbi4KCgsKAwQFARIE
wwIIEwp4CgQEBQIAEgTGAgIbGmogVGhlIGZ1bGwgdGV4dCBvZiB0aGUgZXJyb3IgbWVzc2Fn
ZSwgaW5jbHVkaW5nIGFueSBwYXJhbWV0ZXJzIHRoYXQgd2VyZQogdGhyb3duIGFsb25nIHdp
dGggdGhlIGV4Y2VwdGlvbi4KCg0KBQQFAgAFEgTGAgIICg0KBQQFAgABEgTGAgkWCg0KBQQF
AgADEgTGAhkaCnoKBAQFAgESBMoCAhgabCBUaGUgdGFzayB0cnktbnVtYmVyLCBpbiB3aGlj
aCwgdGhlIGVycm9yIG9jY3VycmVkLiAgSWYgemVybywgdGhlIGVycm9yCiBoYXBwZW5lZCBh
dCB0aGUgaW50ZWdyYXRpb24gbGV2ZWwuCgoNCgUEBQIBBRIEygICBwoNCgUEBQIBARIEygII
EwoNCgUEBQIBAxIEygIWFwpECgIEBhIGzgIA2AIBGjYgQ29udGFpbnMgdGhlIGNvbWJpbmVk
IGNvbmRpdGlvbiBjYWxjdWxhdGlvbiByZXN1bHRzLgoKCwoDBAYBEgTOAggXCigKBAQGAgAS
BNACAiEaGiB0aGUgY3VycmVudCB0YXNrIG51bWJlci4KCg0KBQQGAgAFEgTQAgIICg0KBQQG
AgABEgTQAgkcCg0KBQQGAgADEgTQAh8gCiUKBAQGAgESBNMCAh4aFyB0aGUgbmV4dCB0YXNr
IG51bWJlci4KCg0KBQQGAgEFEgTTAgIICg0KBQQGAgEBEgTTAgkZCg0KBQQGAgEDEgTTAhwd
Cn0KBAQGAgISBNcCAhIabyB0aGUgcmVzdWx0IGNvbWVzIG91dCBhZnRlciBldmFsdWF0ZSB0
aGUgY29tYmluZWQgY29uZGl0aW9uLiBUcnVlIGlmIHRoZXJlJ3MKIG5vIGNvbWJpbmVkIGNv
bmRpdGlvbiBzcGVjaWZpZWQuCgoNCgUEBgICBRIE1wICBgoNCgUEBgICARIE1wIHDQoNCgUE
BgICAxIE1wIQEQpmCgIFABIG3AIA5QIBGlggU3BlY2lmaWVzIHdoZXRoZXIgdGhpcyBleGVj
dXRpb24gaW5mbyBjb3JyZXNwb25kcyB0byBhY3R1YWwgaW50ZWdyYXRpb24gb3IKIHRlc3Qg
Y2FzZS4KCgsKAwUAARIE3AIFEgoiCgQFAAIAEgTeAgIhGhQgVW5zcGVjaWZpZWQgdmFsdWUu
CgoNCgUFAAIAARIE3gICHAoNCgUFAAIAAhIE3gIfIApHCgQFAAIBEgThAgIaGjkgRXhlY3V0
aW9uIGNvcnJlc3BvbmRzIHRvIHJ1biBvZiBhbiBpbnRlZ3JhdGlvbiB2ZXJzaW9uLgoKDQoF
BQACAQESBOECAhUKDQoFBQACAQISBOECGBkKRwoEBQACAhIE5AICEBo5IEV4ZWN1dGlvbiBj
b3JyZXNwb25kcyB0byBydW4gb2YgYSBmdW5jdGlvbmFsIHRlc3QgY2FzZS4KCg0KBQUAAgIB
EgTkAgILCg0KBQUAAgICEgTkAg4PYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo ===
    # Fields for ExecutionInfo
    # Field: integration Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: trigger_id Type: 9 ()
    # Field: request_params Type: 11 (.google.cloud.integrations.v1alpha.ExecutionInfo.RequestParamsEntry)
    # Field: response_params Type: 11 (.google.cloud.integrations.v1alpha.ExecutionInfo.ResponseParamsEntry)
    # Field: errors Type: 11 (.google.cloud.integrations.v1alpha.ErrorDetail)
    # Field: task_configs Type: 11 (.google.cloud.integrations.v1alpha.TaskConfig)
    # Field: integration_version_number Type: 9 ()
    # Field: execution_id Type: 9 ()
    # Field: integration_version_state Type: 14 (.google.cloud.integrations.v1alpha.IntegrationState)
    # Field: enable_database_persistence Type: 8 ()
    # Field: cloud_logging_details Type: 11 (.google.cloud.integrations.v1alpha.CloudLoggingDetails)
    # Field: integration_execution_details Type: 11 (.google.cloud.integrations.v1alpha.IntegrationExecutionDetails)
    # Field: execution_type Type: 14 (.google.cloud.integrations.v1alpha.ExecutionType)
    # Field: execution_method Type: 14 (.google.cloud.integrations.v1alpha.ExecutionInfo.ExecutionMethod)
    # Field: integration_snapshot_number Type: 3 ()
    # Field: replay_info Type: 11 (.google.cloud.integrations.v1alpha.ExecutionInfo.ReplayInfo)

# Enum: ExecutionInfo::ExecutionMethod
our $ExecutionInfo_EXECUTION_METHOD_UNSPECIFIED = 0;
our $ExecutionInfo_POST = 1;
our $ExecutionInfo_SCHEDULE = 2;
our $ExecutionInfo_POST_TO_QUEUE = 3;

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionDetails ===
    # Fields for IntegrationExecutionDetails
    # Field: integration_execution_state Type: 14 (.google.cloud.integrations.v1alpha.IntegrationExecutionDetails.IntegrationExecutionState)
    # Field: integration_execution_snapshot Type: 11 (.google.cloud.integrations.v1alpha.IntegrationExecutionSnapshot)
    # Field: execution_attempt_stats Type: 11 (.google.cloud.integrations.v1alpha.AttemptStats)
    # Field: next_execution_time Type: 11 (.google.protobuf.Timestamp)
    # Field: execution_retries_count Type: 5 ()
    # Field: cancel_reason Type: 9 ()

# Enum: IntegrationExecutionDetails::IntegrationExecutionState
our $IntegrationExecutionDetails_INTEGRATION_EXECUTION_STATE_UNSPECIFIED = 0;
our $IntegrationExecutionDetails_ON_HOLD = 1;
our $IntegrationExecutionDetails_IN_PROCESS = 2;
our $IntegrationExecutionDetails_SUCCEEDED = 3;
our $IntegrationExecutionDetails_FAILED = 4;
our $IntegrationExecutionDetails_CANCELLED = 5;
our $IntegrationExecutionDetails_RETRY_ON_HOLD = 6;
our $IntegrationExecutionDetails_SUSPENDED = 7;

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot ===
    # Fields for IntegrationExecutionSnapshot
    # Field: checkpoint_task_number Type: 9 ()
    # Field: snapshot_time Type: 11 (.google.protobuf.Timestamp)
    # Field: integration_execution_snapshot_metadata Type: 11 (.google.cloud.integrations.v1alpha.IntegrationExecutionSnapshot.IntegrationExecutionSnapshotMetadata)
    # Field: task_execution_details Type: 11 (.google.cloud.integrations.v1alpha.TaskExecutionDetails)
    # Field: condition_results Type: 11 (.google.cloud.integrations.v1alpha.ConditionResult)
    # Field: execution_params Type: 11 (.google.cloud.integrations.v1alpha.IntegrationExecutionSnapshot.ExecutionParamsEntry)

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::TaskExecutionDetails ===
    # Fields for TaskExecutionDetails
    # Field: task_number Type: 9 ()
    # Field: task_execution_state Type: 14 (.google.cloud.integrations.v1alpha.TaskExecutionDetails.TaskExecutionState)
    # Field: task_attempt_stats Type: 11 (.google.cloud.integrations.v1alpha.AttemptStats)

# Enum: TaskExecutionDetails::TaskExecutionState
our $TaskExecutionDetails_TASK_EXECUTION_STATE_UNSPECIFIED = 0;
our $TaskExecutionDetails_PENDING_EXECUTION = 1;
our $TaskExecutionDetails_IN_PROCESS = 2;
our $TaskExecutionDetails_SUCCEED = 3;
our $TaskExecutionDetails_FAILED = 4;
our $TaskExecutionDetails_FATAL = 5;
our $TaskExecutionDetails_RETRY_ON_HOLD = 6;
our $TaskExecutionDetails_SKIPPED = 7;
our $TaskExecutionDetails_CANCELLED = 8;
our $TaskExecutionDetails_PENDING_ROLLBACK = 9;
our $TaskExecutionDetails_ROLLBACK_IN_PROCESS = 10;
our $TaskExecutionDetails_ROLLEDBACK = 11;
our $TaskExecutionDetails_SUSPENDED = 12;

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats ===
    # Fields for AttemptStats
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::ErrorDetail ===
    # Fields for ErrorDetail
    # Field: error_message Type: 9 ()
    # Field: task_number Type: 5 ()

# === Message: Google::Cloud::Integrations::V1alpha::LogEntries::ConditionResult ===
    # Fields for ConditionResult
    # Field: current_task_number Type: 9 ()
    # Field: next_task_number Type: 9 ()
    # Field: result Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::LogEntries - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/log_entries.proto

=head1 SYNOPSIS

    use Google::Cloud::Integrations::V1alpha::LogEntries;

    my $msg = Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo->new({
        integration => $integration,
        project_id => $project_id,
        trigger_id => $trigger_id,
        request_params => $request_params,
    });

    # Read or update a field
    my $val = $msg->integration();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/log_entries.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo

Log entry to log execution info for the monitored resource
`integrations.googleapis.com/IntegrationVersion`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->integration() >> / C<< $msg->integration($value) >>

Type: C<String>

Name of the integration.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The customer's project number.

=item * C<< $msg->trigger_id() >> / C<< $msg->trigger_id($value) >>

Type: C<String>

The trigger id of the integration trigger config. If both trigger_id
and client_id is present, the integration is executed from the start tasks
provided by the matching trigger config otherwise it is executed from the
default start tasks.

=item * C<< $msg->request_params() >> / C<< $msg->request_params($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::RequestParamsEntry>)

Execution parameters come in as part of the request.

=item * C<< $msg->response_params() >> / C<< $msg->response_params($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ResponseParamsEntry>)

Execution parameters come out as part of the response.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::ErrorDetail>)

Errors, warnings, and informationals associated with the workflow/task.
The order in which the errors were added by the workflow/task is
maintained.

=item * C<< $msg->task_configs() >> / C<< $msg->task_configs($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig>)

The configuration details for a task.

=item * C<< $msg->integration_version_number() >> / C<< $msg->integration_version_number($value) >>

Type: C<String>

Pointer to the active version it is executing.

=item * C<< $msg->execution_id() >> / C<< $msg->execution_id($value) >>

Type: C<String>

Auto-generated primary key.

=item * C<< $msg->integration_version_state() >> / C<< $msg->integration_version_state($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::IntegrationState>)

Output only. State of the integration version

=item * C<< $msg->enable_database_persistence() >> / C<< $msg->enable_database_persistence($value) >>

Type: C<Bool>

Database persistence policy for execution info

=item * C<< $msg->cloud_logging_details() >> / C<< $msg->cloud_logging_details($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::CloudLoggingDetails>)

Cloud Logging details for execution info

=item * C<< $msg->integration_execution_details() >> / C<< $msg->integration_execution_details($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionDetails>)

The details about this integration execution.

=item * C<< $msg->execution_type() >> / C<< $msg->execution_type($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::ExecutionType>)

Specifies whether this execution info corresponds to actual integration or
test case.

=item * C<< $msg->execution_method() >> / C<< $msg->execution_method($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::ExecutionInfo::ExecutionMethod>)

The ways user posts this event.

=item * C<< $msg->integration_snapshot_number() >> / C<< $msg->integration_snapshot_number($value) >>

Type: C<Int64>

An increasing sequence that is set when a new snapshot (Integration
Version) is created.

=item * C<< $msg->replay_info() >> / C<< $msg->replay_info($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ReplayInfo>)

Replay info for the execution

=back

=head3 Enum: ExecutionInfo::ExecutionMethod

=over 4

=item * C<EXECUTION_METHOD_UNSPECIFIED> => C<0>

=item * C<POST> => C<1>

=item * C<SCHEDULE> => C<2>

=item * C<POST_TO_QUEUE> => C<3>

=back

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionDetails

Contains the details of the execution info: this includes the tasks execution
details plus the integration execution statistics.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->integration_execution_state() >> / C<< $msg->integration_execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::IntegrationExecutionDetails::IntegrationExecutionState>)

Output only. The execution state of this Integration.

=item * C<< $msg->integration_execution_snapshot() >> / C<< $msg->integration_execution_snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot>)

Execution snapshot.

=item * C<< $msg->execution_attempt_stats() >> / C<< $msg->execution_attempt_stats($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats>)

Status for the current execution attempt.

=item * C<< $msg->next_execution_time() >> / C<< $msg->next_execution_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Next scheduled execution time in case the execution status was
RETRY_ON_HOLD.

=item * C<< $msg->execution_retries_count() >> / C<< $msg->execution_retries_count($value) >>

Type: C<Int32>

Indicates the number of times the execution has restarted from the
beginning.

=item * C<< $msg->cancel_reason() >> / C<< $msg->cancel_reason($value) >>

Type: C<String>

If the execution is manually canceled, this field will contain the reason
for cancellation.

=back

=head3 Enum: IntegrationExecutionDetails::IntegrationExecutionState

=over 4

=item * C<INTEGRATION_EXECUTION_STATE_UNSPECIFIED> => C<0>

=item * C<ON_HOLD> => C<1>

=item * C<IN_PROCESS> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<CANCELLED> => C<5>

=item * C<RETRY_ON_HOLD> => C<6>

=item * C<SUSPENDED> => C<7>

=back

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot

Contains the snapshot of the integration execution for a given checkpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->checkpoint_task_number() >> / C<< $msg->checkpoint_task_number($value) >>

Type: C<String>

Indicates "right after which checkpoint task's execution" this snapshot
is taken.

=item * C<< $msg->snapshot_time() >> / C<< $msg->snapshot_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Indicates when this snapshot is taken.

=item * C<< $msg->integration_execution_snapshot_metadata() >> / C<< $msg->integration_execution_snapshot_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::IntegrationExecutionSnapshotMetadata>)

Snapshot metadata.

=item * C<< $msg->task_execution_details() >> / C<< $msg->task_execution_details($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::TaskExecutionDetails>)

All of the task execution details at the given point of time.

=item * C<< $msg->condition_results() >> / C<< $msg->condition_results($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::ConditionResult>)

All of the computed conditions that been calculated.

=item * C<< $msg->execution_params() >> / C<< $msg->execution_params($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::ExecutionParamsEntry>)

The parameters in Event object.

=back

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::TaskExecutionDetails

Contains the details of the execution of this task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task_number() >> / C<< $msg->task_number($value) >>

Type: C<String>

Pointer to the task config it used for execution.

=item * C<< $msg->task_execution_state() >> / C<< $msg->task_execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::TaskExecutionDetails::TaskExecutionState>)

The execution state of this task.

=item * C<< $msg->task_attempt_stats() >> / C<< $msg->task_attempt_stats($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats>)

Status for the current task execution attempt.

=back

=head3 Enum: TaskExecutionDetails::TaskExecutionState

=over 4

=item * C<TASK_EXECUTION_STATE_UNSPECIFIED> => C<0>

=item * C<PENDING_EXECUTION> => C<1>

=item * C<IN_PROCESS> => C<2>

=item * C<SUCCEED> => C<3>

=item * C<FAILED> => C<4>

=item * C<FATAL> => C<5>

=item * C<RETRY_ON_HOLD> => C<6>

=item * C<SKIPPED> => C<7>

=item * C<CANCELLED> => C<8>

=item * C<PENDING_ROLLBACK> => C<9>

=item * C<ROLLBACK_IN_PROCESS> => C<10>

=item * C<ROLLEDBACK> => C<11>

=item * C<SUSPENDED> => C<12>

=back

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats

Status for the execution attempt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The start time of the integration execution for current attempt. This could
be in the future if it's been scheduled.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The end time of the integration execution for current attempt.

=back

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::ErrorDetail

An error, warning, or information message associated with an integration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The full text of the error message, including any parameters that were
thrown along with the exception.

=item * C<< $msg->task_number() >> / C<< $msg->task_number($value) >>

Type: C<Int32>

The task try-number, in which, the error occurred.  If zero, the error
happened at the integration level.

=back

=head2 Google::Cloud::Integrations::V1alpha::LogEntries::ConditionResult

Contains the combined condition calculation results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->current_task_number() >> / C<< $msg->current_task_number($value) >>

Type: C<String>

the current task number.

=item * C<< $msg->next_task_number() >> / C<< $msg->next_task_number($value) >>

Type: C<String>

the next task number.

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Bool>

the result comes out after evaluate the combined condition. True if there's
no combined condition specified.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::LogEntries::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
