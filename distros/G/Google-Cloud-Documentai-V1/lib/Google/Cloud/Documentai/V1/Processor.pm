package Google::Cloud::Documentai::V1::Processor;

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
    eval { require Google::Cloud::Documentai::V1::DocumentSchema };
    eval { require Google::Cloud::Documentai::V1::Evaluation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9wcm9jZXNzb3IucHJvdG8SGmdvb2dsZS5j
bG91ZC5kb2N1bWVudGFpLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjBnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9k
b2N1bWVudF9zY2hlbWEucHJvdG8aK2dvb2dsZS9jbG91ZC9kb2N1bWVudGFpL3YxL2V2YWx1
YXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8inxIKEFByb2Nl
c3NvclZlcnNpb24SFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgC
IAEoCVILZGlzcGxheU5hbWUSWAoPZG9jdW1lbnRfc2NoZW1hGAwgASgLMiouZ29vZ2xlLmNs
b3VkLmRvY3VtZW50YWkudjEuRG9jdW1lbnRTY2hlbWFCA+BBA1IOZG9jdW1lbnRTY2hlbWES
TQoFc3RhdGUYBiABKA4yMi5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MS5Qcm9jZXNzb3JW
ZXJzaW9uLlN0YXRlQgPgQQNSBXN0YXRlEkAKC2NyZWF0ZV90aW1lGAcgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEmEKEWxhdGVzdF9ldmFsdWF0
aW9uGAggASgLMi8uZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjEuRXZhbHVhdGlvblJlZmVy
ZW5jZUID4EEDUhBsYXRlc3RFdmFsdWF0aW9uEiUKDGttc19rZXlfbmFtZRgJIAEoCUID4EED
UgprbXNLZXlOYW1lEjQKFGttc19rZXlfdmVyc2lvbl9uYW1lGAogASgJQgPgQQNSEWttc0tl
eVZlcnNpb25OYW1lEioKDmdvb2dsZV9tYW5hZ2VkGAsgASgIQgPgQQNSDWdvb2dsZU1hbmFn
ZWQSbAoQZGVwcmVjYXRpb25faW5mbxgNIAEoCzI8Lmdvb2dsZS5jbG91ZC5kb2N1bWVudGFp
LnYxLlByb2Nlc3NvclZlcnNpb24uRGVwcmVjYXRpb25JbmZvQgPgQQNSD2RlcHJlY2F0aW9u
SW5mbxJaCgptb2RlbF90eXBlGA8gASgOMjYuZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjEu
UHJvY2Vzc29yVmVyc2lvbi5Nb2RlbFR5cGVCA+BBA1IJbW9kZWxUeXBlEigKDXNhdGlzZmll
c19wenMYECABKAhCA+BBA1IMc2F0aXNmaWVzUHpzEigKDXNhdGlzZmllc19wemkYESABKAhC
A+BBA1IMc2F0aXNmaWVzUHppEmsKEWdlbl9haV9tb2RlbF9pbmZvGBIgASgLMjsuZ29vZ2xl
LmNsb3VkLmRvY3VtZW50YWkudjEuUHJvY2Vzc29yVmVyc2lvbi5HZW5BaU1vZGVsSW5mb0ID
4EEDUg5nZW5BaU1vZGVsSW5mbxrNAQoPRGVwcmVjYXRpb25JbmZvEkUKEGRlcHJlY2F0aW9u
X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg9kZXByZWNhdGlvblRp
bWUScwodcmVwbGFjZW1lbnRfcHJvY2Vzc29yX3ZlcnNpb24YAiABKAlCL/pBLAoqZG9jdW1l
bnRhaS5nb29nbGVhcGlzLmNvbS9Qcm9jZXNzb3JWZXJzaW9uUhtyZXBsYWNlbWVudFByb2Nl
c3NvclZlcnNpb24akgYKDkdlbkFpTW9kZWxJbmZvEpYBChxmb3VuZGF0aW9uX2dlbl9haV9t
b2RlbF9pbmZvGAEgASgLMlQuZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjEuUHJvY2Vzc29y
VmVyc2lvbi5HZW5BaU1vZGVsSW5mby5Gb3VuZGF0aW9uR2VuQWlNb2RlbEluZm9IAFIYZm91
bmRhdGlvbkdlbkFpTW9kZWxJbmZvEooBChhjdXN0b21fZ2VuX2FpX21vZGVsX2luZm8YAiAB
KAsyUC5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MS5Qcm9jZXNzb3JWZXJzaW9uLkdlbkFp
TW9kZWxJbmZvLkN1c3RvbUdlbkFpTW9kZWxJbmZvSABSFGN1c3RvbUdlbkFpTW9kZWxJbmZv
GogBChhGb3VuZGF0aW9uR2VuQWlNb2RlbEluZm8SLQoSZmluZXR1bmluZ19hbGxvd2VkGAEg
ASgIUhFmaW5ldHVuaW5nQWxsb3dlZBI9ChttaW5fdHJhaW5fbGFiZWxlZF9kb2N1bWVudHMY
AiABKAVSGG1pblRyYWluTGFiZWxlZERvY3VtZW50cxrAAgoUQ3VzdG9tR2VuQWlNb2RlbElu
Zm8SjAEKEWN1c3RvbV9tb2RlbF90eXBlGAEgASgOMmAuZ29vZ2xlLmNsb3VkLmRvY3VtZW50
YWkudjEuUHJvY2Vzc29yVmVyc2lvbi5HZW5BaU1vZGVsSW5mby5DdXN0b21HZW5BaU1vZGVs
SW5mby5DdXN0b21Nb2RlbFR5cGVSD2N1c3RvbU1vZGVsVHlwZRI5ChliYXNlX3Byb2Nlc3Nv
cl92ZXJzaW9uX2lkGAIgASgJUhZiYXNlUHJvY2Vzc29yVmVyc2lvbklkIl4KD0N1c3RvbU1v
ZGVsVHlwZRIhCh1DVVNUT01fTU9ERUxfVFlQRV9VTlNQRUNJRklFRBAAEhgKFFZFUlNJT05F
RF9GT1VOREFUSU9OEAESDgoKRklORV9UVU5FRBACQgwKCm1vZGVsX2luZm8ikwEKBVN0YXRl
EhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIREVQTE9ZRUQQARINCglERVBMT1lJTkcQAhIO
CgpVTkRFUExPWUVEEAMSDwoLVU5ERVBMT1lJTkcQBBIMCghDUkVBVElORxAFEgwKCERFTEVU
SU5HEAYSCgoGRkFJTEVEEAcSDQoJSU1QT1JUSU5HEAgiWQoJTW9kZWxUeXBlEhoKFk1PREVM
X1RZUEVfVU5TUEVDSUZJRUQQABIZChVNT0RFTF9UWVBFX0dFTkVSQVRJVkUQARIVChFNT0RF
TF9UWVBFX0NVU1RPTRACOpYB6kGSAQoqZG9jdW1lbnRhaS5nb29nbGVhcGlzLmNvbS9Qcm9j
ZXNzb3JWZXJzaW9uEmRwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cHJvY2Vzc29ycy97cHJvY2Vzc29yfS9wcm9jZXNzb3JWZXJzaW9ucy97cHJvY2Vzc29yX3Zl
cnNpb259IosBChVQcm9jZXNzb3JWZXJzaW9uQWxpYXMSFAoFYWxpYXMYASABKAlSBWFsaWFz
ElwKEXByb2Nlc3Nvcl92ZXJzaW9uGAIgASgJQi/6QSwKKmRvY3VtZW50YWkuZ29vZ2xlYXBp
cy5jb20vUHJvY2Vzc29yVmVyc2lvblIQcHJvY2Vzc29yVmVyc2lvbiLcBgoJUHJvY2Vzc29y
EhoKBG5hbWUYASABKAlCBuBBBeBBA1IEbmFtZRISCgR0eXBlGAIgASgJUgR0eXBlEiEKDGRp
c3BsYXlfbmFtZRgDIAEoCVILZGlzcGxheU5hbWUSRgoFc3RhdGUYBCABKA4yKy5nb29nbGUu
Y2xvdWQuZG9jdW1lbnRhaS52MS5Qcm9jZXNzb3IuU3RhdGVCA+BBA1IFc3RhdGUSawoZZGVm
YXVsdF9wcm9jZXNzb3JfdmVyc2lvbhgJIAEoCUIv+kEsCipkb2N1bWVudGFpLmdvb2dsZWFw
aXMuY29tL1Byb2Nlc3NvclZlcnNpb25SF2RlZmF1bHRQcm9jZXNzb3JWZXJzaW9uEnIKGXBy
b2Nlc3Nvcl92ZXJzaW9uX2FsaWFzZXMYCiADKAsyMS5nb29nbGUuY2xvdWQuZG9jdW1lbnRh
aS52MS5Qcm9jZXNzb3JWZXJzaW9uQWxpYXNCA+BBA1IXcHJvY2Vzc29yVmVyc2lvbkFsaWFz
ZXMSMQoQcHJvY2Vzc19lbmRwb2ludBgGIAEoCUIG4EED4EEFUg9wcm9jZXNzRW5kcG9pbnQS
QAoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmNyZWF0ZVRpbWUSIAoMa21zX2tleV9uYW1lGAggASgJUgprbXNLZXlOYW1lEigKDXNhdGlz
Zmllc19wenMYDCABKAhCA+BBA1IMc2F0aXNmaWVzUHpzEigKDXNhdGlzZmllc19wemkYDSAB
KAhCA+BBA1IMc2F0aXNmaWVzUHppIn4KBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAAS
CwoHRU5BQkxFRBABEgwKCERJU0FCTEVEEAISDAoIRU5BQkxJTkcQAxINCglESVNBQkxJTkcQ
BBIMCghDUkVBVElORxAFEgoKBkZBSUxFRBAGEgwKCERFTEVUSU5HEAc6aOpBZQojZG9jdW1l
bnRhaS5nb29nbGVhcGlzLmNvbS9Qcm9jZXNzb3ISPnByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9wcm9jZXNzb3JzL3twcm9jZXNzb3J9QtEBCh5jb20uZ29vZ2xl
LmNsb3VkLmRvY3VtZW50YWkudjFCE0RvY3VtZW50QWlQcm9jZXNzb3JQAVo+Y2xvdWQuZ29v
Z2xlLmNvbS9nby9kb2N1bWVudGFpL2FwaXYxL2RvY3VtZW50YWlwYjtkb2N1bWVudGFpcGKq
AhpHb29nbGUuQ2xvdWQuRG9jdW1lbnRBSS5WMcoCGkdvb2dsZVxDbG91ZFxEb2N1bWVudEFJ
XFYx6gIdR29vZ2xlOjpDbG91ZDo6RG9jdW1lbnRBSTo6VjFK71MKBxIFDgCoAgEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUADoKCQoCAwMSAxUANQoJCgIDBBIDFgApCggKAQgSAxgANwoJCgII
JRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgS
AxsANAoJCgIICBIDGwA0CggKAQgSAxwANwoJCgIIARIDHAA3CggKAQgSAx0ANwoJCgIIKRID
HQA3CggKAQgSAx4ANgoJCgIILRIDHgA2CqoCCgIEABIFJADBAQEanAIgQSBwcm9jZXNzb3Ig
dmVyc2lvbiBpcyBhbiBpbXBsZW1lbnRhdGlvbiBvZiBhIHByb2Nlc3Nvci4gRWFjaCBwcm9j
ZXNzb3IKIGNhbiBoYXZlIG11bHRpcGxlIHZlcnNpb25zLCBwcmV0cmFpbmVkIGJ5IEdvb2ds
ZSBpbnRlcm5hbGx5IG9yIHVwdHJhaW5lZAogYnkgdGhlIGN1c3RvbWVyLiBBIHByb2Nlc3Nv
ciBjYW4gb25seSBoYXZlIG9uZSBkZWZhdWx0IHZlcnNpb24gYXQgYSB0aW1lLgogSXRzIGRv
Y3VtZW50LXByb2Nlc3NpbmcgYmVoYXZpb3IgaXMgZGVmaW5lZCBieSB0aGF0IHZlcnNpb24u
CgoKCgMEAAESAyQIGAoLCgMEAAcSBCUCKAQKDQoFBAAHnQgSBCUCKAQKVQoEBAADABIEKwI0
AxpHIEluZm9ybWF0aW9uIGFib3V0IHRoZSB1cGNvbWluZyBkZXByZWNhdGlvbiBvZiB0aGlz
IHByb2Nlc3NvciB2ZXJzaW9uLgoKDAoFBAADAAESAysKGQpNCgYEAAMAAgASAy0EMxo+IFRo
ZSB0aW1lIGF0IHdoaWNoIHRoaXMgcHJvY2Vzc29yIHZlcnNpb24gd2lsbCBiZSBkZXByZWNh
dGVkLgoKDgoHBAADAAIABhIDLQQdCg4KBwQAAwACAAESAy0eLgoOCgcEAAMAAgADEgMtMTIK
UwoGBAADAAIBEgQwBDMLGkMgSWYgc2V0LCB0aGUgcHJvY2Vzc29yIHZlcnNpb24gdGhhdCB3
aWxsIGJlIHVzZWQgYXMgYSByZXBsYWNlbWVudC4KCg4KBwQAAwACAQUSAzAECgoOCgcEAAMA
AgEBEgMwCygKDgoHBAADAAIBAxIDMCssCg8KBwQAAwACAQgSBDEIMwoKEQoJBAADAAIBCJ8I
EgQxCTMJCk8KBAQAAwESBDcCYgMaQSBJbmZvcm1hdGlvbiBhYm91dCBHZW5lcmF0aXZlIEFJ
IG1vZGVsLWJhc2VkIHByb2Nlc3NvciB2ZXJzaW9ucy4KCgwKBQQAAwEBEgM3ChgKTwoGBAAD
AQMAEgQ5BEAFGj8gSW5mb3JtYXRpb24gZm9yIGEgcHJldHJhaW5lZCBHb29nbGUtbWFuYWdl
ZCBmb3VuZGF0aW9uIG1vZGVsLgoKDgoHBAADAQMAARIDOQwkClEKCAQAAwEDAAIAEgM7BiIa
QCBXaGV0aGVyIGZpbmV0dW5pbmcgaXMgYWxsb3dlZCBmb3IgdGhpcyBiYXNlIHByb2Nlc3Nv
ciB2ZXJzaW9uLgoKEAoJBAADAQMAAgAFEgM7BgoKEAoJBAADAQMAAgABEgM7Cx0KEAoJBAAD
AQMAAgADEgM7ICEKbAoIBAADAQMAAgESAz8GLBpbIFRoZSBtaW5pbXVtIG51bWJlciBvZiBs
YWJlbGVkIGRvY3VtZW50cyBpbiB0aGUgdHJhaW5pbmcgZGF0YXNldAogcmVxdWlyZWQgZm9y
IGZpbmV0dW5pbmcuCgoQCgkEAAMBAwACAQUSAz8GCwoQCgkEAAMBAwACAQESAz8MJwoQCgkE
AAMBAwACAQMSAz8qKwq/AQoGBAADAQMBEgRFBFcFGq4BIEluZm9ybWF0aW9uIGZvciBhIGN1
c3RvbSBHZW5lcmF0aXZlIEFJIG1vZGVsIGNyZWF0ZWQgYnkgdGhlIHVzZXIuIFRoZXNlCiBh
cmUgY3JlYXRlZCB3aXRoIGBDcmVhdGUgTmV3IFZlcnNpb25gIGluIGVpdGhlciB0aGUgYENh
bGwgZm91bmRhdGlvbgogbW9kZWxgIG9yIGBGaW5lIHR1bmluZ2AgdGFicy4KCg4KBwQAAwED
AQESA0UMIApBCggEAAMBAwEEABIERwZQBxovIFRoZSB0eXBlIG9mIGN1c3RvbSBtb2RlbCBj
cmVhdGVkIGJ5IHRoZSB1c2VyLgoKEAoJBAADAQMBBAABEgNHCxoKMwoKBAADAQMBBAACABID
SQgqGiAgVGhlIG1vZGVsIHR5cGUgaXMgdW5zcGVjaWZpZWQuCgoSCgsEAAMBAwEEAAIAARID
SQglChIKCwQAAwEDAQQAAgACEgNJKCkKPwoKBAADAQMBBAACARIDTAghGiwgVGhlIG1vZGVs
IGlzIGEgdmVyc2lvbmVkIGZvdW5kYXRpb24gbW9kZWwuCgoSCgsEAAMBAwEEAAIBARIDTAgc
ChIKCwQAAwEDAQQAAgECEgNMHyAKPwoKBAADAQMBBAACAhIDTwgXGiwgVGhlIG1vZGVsIGlz
IGEgZmluZXR1bmVkIGZvdW5kYXRpb24gbW9kZWwuCgoSCgsEAAMBAwEEAAICARIDTwgSChIK
CwQAAwEDAQQAAgICEgNPFRYKQAoIBAADAQMBAgASA1MGLBovIFRoZSB0eXBlIG9mIGN1c3Rv
bSBtb2RlbCBjcmVhdGVkIGJ5IHRoZSB1c2VyLgoKEAoJBAADAQMBAgAGEgNTBhUKEAoJBAAD
AQMBAgABEgNTFicKEAoJBAADAQMBAgADEgNTKisKRgoIBAADAQMBAgESA1YGKxo1IFRoZSBi
YXNlIHByb2Nlc3NvciB2ZXJzaW9uIElEIGZvciB0aGUgY3VzdG9tIG1vZGVsLgoKEAoJBAAD
AQMBAgEFEgNWBgwKEAoJBAADAQMBAgEBEgNWDSYKEAoJBAADAQMBAgEDEgNWKSoKlQEKBgQA
AwEIABIEWwRhBRqEASBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaXMgZWl0aGVyIGEgcHJldHJh
aW5lZCBHb29nbGUtbWFuYWdlZCBmb3VuZGF0aW9uCiBtb2RlbCBvciBhIGN1c3RvbSBHZW5l
cmF0aXZlIEFJIG1vZGVsIGNyZWF0ZWQgYnkgdGhlIHVzZXIuCgoOCgcEAAMBCAABEgNbChQK
TgoGBAADAQIAEgNdBkAaPyBJbmZvcm1hdGlvbiBmb3IgYSBwcmV0cmFpbmVkIEdvb2dsZS1t
YW5hZ2VkIGZvdW5kYXRpb24gbW9kZWwuCgoOCgcEAAMBAgAGEgNdBh4KDgoHBAADAQIAARID
XR87Cg4KBwQAAwECAAMSA10+PwpSCgYEAAMBAgESA2AGOBpDIEluZm9ybWF0aW9uIGZvciBh
IGN1c3RvbSBHZW5lcmF0aXZlIEFJIG1vZGVsIGNyZWF0ZWQgYnkgdGhlIHVzZXIuCgoOCgcE
AAMBAgEGEgNgBhoKDgoHBAADAQIBARIDYBszCg4KBwQAAwECAQMSA2A2Nwo+CgQEAAQAEgVl
AoABAxovIFRoZSBwb3NzaWJsZSBzdGF0ZXMgb2YgdGhlIHByb2Nlc3NvciB2ZXJzaW9uLgoK
DAoFBAAEAAESA2UHDApCCgYEAAQAAgASA2cEGhozIFRoZSBwcm9jZXNzb3IgdmVyc2lvbiBp
cyBpbiBhbiB1bnNwZWNpZmllZCBzdGF0ZS4KCg4KBwQABAACAAESA2cEFQoOCgcEAAQAAgAC
EgNnGBkKUgoGBAAEAAIBEgNqBBEaQyBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaXMgZGVwbG95
ZWQgYW5kIGNhbiBiZSB1c2VkIGZvciBwcm9jZXNzaW5nLgoKDgoHBAAEAAIBARIDagQMCg4K
BwQABAACAQISA2oPEAo5CgYEAAQAAgISA20EEhoqIFRoZSBwcm9jZXNzb3IgdmVyc2lvbiBp
cyBiZWluZyBkZXBsb3llZC4KCg4KBwQABAACAgESA20EDQoOCgcEAAQAAgICEgNtEBEKWQoG
BAAEAAIDEgNwBBMaSiBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaXMgbm90IGRlcGxveWVkIGFu
ZCBjYW5ub3QgYmUgdXNlZCBmb3IgcHJvY2Vzc2luZy4KCg4KBwQABAACAwESA3AEDgoOCgcE
AAQAAgMCEgNwERIKOwoGBAAEAAIEEgNzBBQaLCBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaXMg
YmVpbmcgdW5kZXBsb3llZC4KCg4KBwQABAACBAESA3MEDwoOCgcEAAQAAgQCEgNzEhMKOAoG
BAAEAAIFEgN2BBEaKSBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaXMgYmVpbmcgY3JlYXRlZC4K
Cg4KBwQABAACBQESA3YEDAoOCgcEAAQAAgUCEgN2DxAKOAoGBAAEAAIGEgN5BBEaKSBUaGUg
cHJvY2Vzc29yIHZlcnNpb24gaXMgYmVpbmcgZGVsZXRlZC4KCg4KBwQABAACBgESA3kEDAoO
CgcEAAQAAgYCEgN5DxAKTwoGBAAEAAIHEgN8BA8aQCBUaGUgcHJvY2Vzc29yIHZlcnNpb24g
ZmFpbGVkIGFuZCBpcyBpbiBhbiBpbmRldGVybWluYXRlIHN0YXRlLgoKDgoHBAAEAAIHARID
fAQKCg4KBwQABAACBwISA3wNDgo5CgYEAAQAAggSA38EEhoqIFRoZSBwcm9jZXNzb3IgdmVy
c2lvbiBpcyBiZWluZyBpbXBvcnRlZC4KCg4KBwQABAACCAESA38EDQoOCgcEAAQAAggCEgN/
EBEKRAoEBAAEARIGgwECjAEDGjQgVGhlIHBvc3NpYmxlIG1vZGVsIHR5cGVzIG9mIHRoZSBw
cm9jZXNzb3IgdmVyc2lvbi4KCg0KBQQABAEBEgSDAQcQCkMKBgQABAECABIEhQEEHxozIFRo
ZSBwcm9jZXNzb3IgdmVyc2lvbiBoYXMgdW5zcGVjaWZpZWQgbW9kZWwgdHlwZS4KCg8KBwQA
BAECAAESBIUBBBoKDwoHBAAEAQIAAhIEhQEdHgpCCgYEAAQBAgESBIgBBB4aMiBUaGUgcHJv
Y2Vzc29yIHZlcnNpb24gaGFzIGdlbmVyYXRpdmUgbW9kZWwgdHlwZS4KCg8KBwQABAECAQES
BIgBBBkKDwoHBAAEAQIBAhIEiAEcHQo+CgYEAAQBAgISBIsBBBoaLiBUaGUgcHJvY2Vzc29y
IHZlcnNpb24gaGFzIGN1c3RvbSBtb2RlbCB0eXBlLgoKDwoHBAAEAQICARIEiwEEFQoPCgcE
AAQBAgICEgSLARgZCrkBCgQEAAIAEgSRAQI9GqoBIElkZW50aWZpZXIuIFRoZSByZXNvdXJj
ZSBuYW1lIG9mIHRoZSBwcm9jZXNzb3IgdmVyc2lvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJvY2Vzc29ycy97cHJvY2Vzc29yfS9w
cm9jZXNzb3JWZXJzaW9ucy97cHJvY2Vzc29yX3ZlcnNpb259YAoKDQoFBAACAAUSBJEBAggK
DQoFBAACAAESBJEBCQ0KDQoFBAACAAMSBJEBEBEKDQoFBAACAAgSBJEBEjwKEAoIBAACAAic
CAASBJEBEzsKOgoEBAACARIElAECGhosIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHByb2Nl
c3NvciB2ZXJzaW9uLgoKDQoFBAACAQUSBJQBAggKDQoFBAACAQESBJQBCRUKDQoFBAACAQMS
BJQBGBkKWQoEBAACAhIGlwECmAEyGkkgT3V0cHV0IG9ubHkuIFRoZSBzY2hlbWEgb2YgdGhl
IHByb2Nlc3NvciB2ZXJzaW9uLiBEZXNjcmliZXMgdGhlIG91dHB1dC4KCg0KBQQAAgIGEgSX
AQIQCg0KBQQAAgIBEgSXAREgCg0KBQQAAgIDEgSXASMlCg0KBQQAAgIIEgSYAQYxChAKCAQA
AgIInAgAEgSYAQcwCkAKBAQAAgMSBJsBAj4aMiBPdXRwdXQgb25seS4gVGhlIHN0YXRlIG9m
IHRoZSBwcm9jZXNzb3IgdmVyc2lvbi4KCg0KBQQAAgMGEgSbAQIHCg0KBQQAAgMBEgSbAQgN
Cg0KBQQAAgMDEgSbARARCg0KBQQAAgMIEgSbARI9ChAKCAQAAgMInAgAEgSbARM8CkoKBAQA
AgQSBp4BAp8BMho6IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgcHJvY2Vzc29yIHZlcnNp
b24gd2FzIGNyZWF0ZWQuCgoNCgUEAAIEBhIEngECGwoNCgUEAAIEARIEngEcJwoNCgUEAAIE
AxIEngEqKwoNCgUEAAIECBIEnwEGMQoQCggEAAIECJwIABIEnwEHMApfCgQEAAIFEgajAQKk
ATIaTyBPdXRwdXQgb25seS4gVGhlIG1vc3QgcmVjZW50bHkgaW52b2tlZCBldmFsdWF0aW9u
IGZvciB0aGUgcHJvY2Vzc29yCiB2ZXJzaW9uLgoKDQoFBAACBQYSBKMBAhUKDQoFBAACBQES
BKMBFicKDQoFBAACBQMSBKMBKisKDQoFBAACBQgSBKQBBjEKEAoIBAACBQicCAASBKQBBzAK
QgoEBAACBhIEpwECRho0IE91dHB1dCBvbmx5LiBUaGUgS01TIGtleSBuYW1lIHVzZWQgZm9y
IGVuY3J5cHRpb24uCgoNCgUEAAIGBRIEpwECCAoNCgUEAAIGARIEpwEJFQoNCgUEAAIGAxIE
pwEYGQoNCgUEAAIGCBIEpwEaRQoQCggEAAIGCJwIABIEpwEbRApOCgQEAAIHEgSqAQJPGkAg
T3V0cHV0IG9ubHkuIFRoZSBLTVMga2V5IHZlcnNpb24gd2l0aCB3aGljaCBkYXRhIGlzIGVu
Y3J5cHRlZC4KCg0KBQQAAgcFEgSqAQIICg0KBQQAAgcBEgSqAQkdCg0KBQQAAgcDEgSqASAi
Cg0KBQQAAgcIEgSqASNOChAKCAQAAgcInAgAEgSqASRNClcKBAQAAggSBK0BAkcaSSBPdXRw
dXQgb25seS4gRGVub3RlcyB0aGF0IHRoaXMgYFByb2Nlc3NvclZlcnNpb25gIGlzIG1hbmFn
ZWQgYnkgR29vZ2xlLgoKDQoFBAACCAUSBK0BAgYKDQoFBAACCAESBK0BBxUKDQoFBAACCAMS
BK0BGBoKDQoFBAACCAgSBK0BG0YKEAoIBAACCAicCAASBK0BHEUKYwoEBAACCRIGsQECsgEy
GlMgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5mb3JtYXRpb24gYWJvdXQgdGhlIGV2ZW50dWFs
IGRlcHJlY2F0aW9uIG9mIHRoaXMKIHZlcnNpb24uCgoNCgUEAAIJBhIEsQECEQoNCgUEAAIJ
ARIEsQESIgoNCgUEAAIJAxIEsQElJwoNCgUEAAIJCBIEsgEGMQoQCggEAAIJCJwIABIEsgEH
MApGCgQEAAIKEgS1AQJIGjggT3V0cHV0IG9ubHkuIFRoZSBtb2RlbCB0eXBlIG9mIHRoaXMg
cHJvY2Vzc29yIHZlcnNpb24uCgoNCgUEAAIKBhIEtQECCwoNCgUEAAIKARIEtQEMFgoNCgUE
AAIKAxIEtQEZGwoNCgUEAAIKCBIEtQEcRwoQCggEAAIKCJwIABIEtQEdRgo1CgQEAAILEgS4
AQJGGicgT3V0cHV0IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlLgoKDQoFBAACCwUS
BLgBAgYKDQoFBAACCwESBLgBBxQKDQoFBAACCwMSBLgBFxkKDQoFBAACCwgSBLgBGkUKEAoI
BAACCwicCAASBLgBG0QKNQoEBAACDBIEuwECRhonIE91dHB1dCBvbmx5LiBSZXNlcnZlZCBm
b3IgZnV0dXJlIHVzZS4KCg0KBQQAAgwFEgS7AQIGCg0KBQQAAgwBEgS7AQcUCg0KBQQAAgwD
EgS7ARcZCg0KBQQAAgwIEgS7ARpFChAKCAQAAgwInAgAEgS7ARtECl8KBAQAAg0SBr8BAsAB
MhpPIE91dHB1dCBvbmx5LiBJbmZvcm1hdGlvbiBhYm91dCBHZW5lcmF0aXZlIEFJIG1vZGVs
LWJhc2VkIHByb2Nlc3NvcgogdmVyc2lvbnMuCgoNCgUEAAINBhIEvwECEAoNCgUEAAINARIE
vwERIgoNCgUEAAINAxIEvwElJwoNCgUEAAINCBIEwAEGMQoQCggEAAINCJwIABIEwAEHMApW
CgIEARIGxAEAzAEBGkggQ29udGFpbnMgdGhlIGFsaWFzIGFuZCB0aGUgYWxpYXNlZCByZXNv
dXJjZSBuYW1lIG9mIHByb2Nlc3NvciB2ZXJzaW9uLgoKCwoDBAEBEgTEAQgdCksKBAQBAgAS
BMYBAhMaPSBUaGUgYWxpYXMgaW4gdGhlIGZvcm0gb2YgYHByb2Nlc3Nvcl92ZXJzaW9uYCBy
ZXNvdXJjZSBuYW1lLgoKDQoFBAECAAUSBMYBAggKDQoFBAECAAESBMYBCQ4KDQoFBAECAAMS
BMYBERIKQQoEBAECARIGyQECywEFGjEgVGhlIHJlc291cmNlIG5hbWUgb2YgYWxpYXNlZCBw
cm9jZXNzb3IgdmVyc2lvbi4KCg0KBQQBAgEFEgTJAQIICg0KBQQBAgEBEgTJAQkaCg0KBQQB
AgEDEgTJAR0eCg8KBQQBAgEIEgbJAR/LAQQKEQoHBAECAQifCBIGyQEgywEDCocBCgIEAhIG
0AEAqAIBGnkgVGhlIGZpcnN0LWNsYXNzIGNpdGl6ZW4gZm9yIERvY3VtZW50IEFJLiBFYWNo
IHByb2Nlc3NvciBkZWZpbmVzIGhvdyB0bwogZXh0cmFjdCBzdHJ1Y3R1cmFsIGluZm9ybWF0
aW9uIGZyb20gYSBkb2N1bWVudC4KCgsKAwQCARIE0AEIEQoNCgMEAgcSBtEBAtQBBAoPCgUE
AgedCBIG0QEC1AEECjcKBAQCBAASBtcBAvcBAxonIFRoZSBwb3NzaWJsZSBzdGF0ZXMgb2Yg
dGhlIHByb2Nlc3Nvci4KCg0KBQQCBAABEgTXAQcMCjsKBgQCBAACABIE2QEEGhorIFRoZSBw
cm9jZXNzb3IgaXMgaW4gYW4gdW5zcGVjaWZpZWQgc3RhdGUuCgoPCgcEAgQAAgABEgTZAQQV
Cg8KBwQCBAACAAISBNkBGBkKvgEKBgQCBAACARIE3gEEEBqtASBUaGUgcHJvY2Vzc29yIGlz
IGVuYWJsZWQsIGkuZS4sIGhhcyBhbiBlbmFibGVkIHZlcnNpb24gd2hpY2ggY2FuCiBjdXJy
ZW50bHkgc2VydmUgcHJvY2Vzc2luZyByZXF1ZXN0cyBhbmQgYWxsIHRoZSBmZWF0dXJlIGRl
cGVuZGVuY2llcyBoYXZlCiBiZWVuIHN1Y2Nlc3NmdWxseSBpbml0aWFsaXplZC4KCg8KBwQC
BAACAQESBN4BBAsKDwoHBAIEAAIBAhIE3gEODwosCgYEAgQAAgISBOEBBBEaHCBUaGUgcHJv
Y2Vzc29yIGlzIGRpc2FibGVkLgoKDwoHBAIEAAICARIE4QEEDAoPCgcEAgQAAgICEgThAQ8Q
ClYKBgQCBAACAxIE5AEEERpGIFRoZSBwcm9jZXNzb3IgaXMgYmVpbmcgZW5hYmxlZCwgd2ls
bCBiZWNvbWUgYEVOQUJMRURgIGlmIHN1Y2Nlc3NmdWwuCgoPCgcEAgQAAgMBEgTkAQQMCg8K
BwQCBAACAwISBOQBDxAKWAoGBAIEAAIEEgTnAQQSGkggVGhlIHByb2Nlc3NvciBpcyBiZWlu
ZyBkaXNhYmxlZCwgd2lsbCBiZWNvbWUgYERJU0FCTEVEYCBpZiBzdWNjZXNzZnVsLgoKDwoH
BAIEAAIEARIE5wEEDQoPCgcEAgQAAgQCEgTnARARCqoCCgYEAgQAAgUSBO4BBBEamQIgVGhl
IHByb2Nlc3NvciBpcyBiZWluZyBjcmVhdGVkLCB3aWxsIGJlY29tZSBlaXRoZXIgYEVOQUJM
RURgIChmb3IKIHN1Y2Nlc3NmdWwgY3JlYXRpb24pIG9yIGBGQUlMRURgIChmb3IgZmFpbGVk
IG9uZXMpLgogT25jZSBhIHByb2Nlc3NvciBpcyBpbiB0aGlzIHN0YXRlLCBpdCBjYW4gdGhl
biBiZSB1c2VkIGZvciBkb2N1bWVudAogcHJvY2Vzc2luZywgYnV0IHRoZSBmZWF0dXJlIGRl
cGVuZGVuY2llcyBvZiB0aGUgcHJvY2Vzc29yIG1pZ2h0IG5vdCBiZQogZnVsbHkgY3JlYXRl
ZCB5ZXQuCgoPCgcEAgQAAgUBEgTuAQQMCg8KBwQCBAACBQISBO4BDxAK1AEKBgQCBAACBhIE
8wEEDxrDASBUaGUgcHJvY2Vzc29yIGZhaWxlZCBkdXJpbmcgY3JlYXRpb24gb3IgaW5pdGlh
bGl6YXRpb24gb2YgZmVhdHVyZQogZGVwZW5kZW5jaWVzLiBUaGUgdXNlciBzaG91bGQgZGVs
ZXRlIHRoZSBwcm9jZXNzb3IgYW5kIHJlY3JlYXRlIG9uZSBhcwogYWxsIHRoZSBmdW5jdGlv
bmFsaXRpZXMgb2YgdGhlIHByb2Nlc3NvciBhcmUgZGlzYWJsZWQuCgoPCgcEAgQAAgYBEgTz
AQQKCg8KBwQCBAACBgISBPMBDQ4KUAoGBAIEAAIHEgT2AQQRGkAgVGhlIHByb2Nlc3NvciBp
cyBiZWluZyBkZWxldGVkLCB3aWxsIGJlIHJlbW92ZWQgaWYgc3VjY2Vzc2Z1bC4KCg8KBwQC
BAACBwESBPYBBAwKDwoHBAIEAAIHAhIE9gEPEAqYAQoEBAICABIG+wEC/gEEGocBIE91dHB1
dCBvbmx5LiBJbW11dGFibGUuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9jZXNzb3Iu
CiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJv
Y2Vzc29ycy97cHJvY2Vzc29yfWAKCg0KBQQCAgAFEgT7AQIICg0KBQQCAgABEgT7AQkNCg0K
BQQCAgADEgT7ARARCg8KBQQCAgAIEgb7ARL+AQMKEAoIBAICAAicCAASBPwBBCsKEAoIBAIC
AAicCAESBP0BBC0K2wEKBAQCAgESBIMCAhIazAEgVGhlIHByb2Nlc3NvciB0eXBlLCBzdWNo
IGFzOiBgT0NSX1BST0NFU1NPUmAsIGBJTlZPSUNFX1BST0NFU1NPUmAuCiBUbyBnZXQgYSBs
aXN0IG9mIHByb2Nlc3NvciB0eXBlcywgc2VlCiBbRmV0Y2hQcm9jZXNzb3JUeXBlc11bZ29v
Z2xlLmNsb3VkLmRvY3VtZW50YWkudjEuRG9jdW1lbnRQcm9jZXNzb3JTZXJ2aWNlLkZldGNo
UHJvY2Vzc29yVHlwZXNdLgoKDQoFBAICAQUSBIMCAggKDQoFBAICAQESBIMCCQ0KDQoFBAIC
AQMSBIMCEBEKMgoEBAICAhIEhgICGhokIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHByb2Nl
c3Nvci4KCg0KBQQCAgIFEgSGAgIICg0KBQQCAgIBEgSGAgkVCg0KBQQCAgIDEgSGAhgZCjgK
BAQCAgMSBIkCAj4aKiBPdXRwdXQgb25seS4gVGhlIHN0YXRlIG9mIHRoZSBwcm9jZXNzb3Iu
CgoNCgUEAgIDBhIEiQICBwoNCgUEAgIDARIEiQIIDQoNCgUEAgIDAxIEiQIQEQoNCgUEAgID
CBIEiQISPQoQCggEAgIDCJwIABIEiQITPAowCgQEAgIEEgaMAgKOAgUaICBUaGUgZGVmYXVs
dCBwcm9jZXNzb3IgdmVyc2lvbi4KCg0KBQQCAgQFEgSMAgIICg0KBQQCAgQBEgSMAgkiCg0K
BQQCAgQDEgSMAiUmCg8KBQQCAgQIEgaMAieOAgQKEQoHBAICBAifCBIGjAIojgIDCj0KBAQC
AgUSBpECApICMhotIE91dHB1dCBvbmx5LiBUaGUgcHJvY2Vzc29yIHZlcnNpb24gYWxpYXNl
cy4KCg0KBQQCAgUEEgSRAgIKCg0KBQQCAgUGEgSRAgsgCg0KBQQCAgUBEgSRAiE6Cg0KBQQC
AgUDEgSRAj0/Cg0KBQQCAgUIEgSSAgYxChAKCAQCAgUInAgAEgSSAgcwCmUKBAQCAgYSBpYC
ApkCBBpVIE91dHB1dCBvbmx5LiBJbW11dGFibGUuIFRoZSBodHRwIGVuZHBvaW50IHRoYXQg
Y2FuIGJlIGNhbGxlZCB0byBpbnZva2UKIHByb2Nlc3NpbmcuCgoNCgUEAgIGBRIElgICCAoN
CgUEAgIGARIElgIJGQoNCgUEAgIGAxIElgIcHQoPCgUEAgIGCBIGlgIemQIDChAKCAQCAgYI
nAgAEgSXAgQtChAKCAQCAgYInAgBEgSYAgQrCkIKBAQCAgcSBpwCAp0CMhoyIE91dHB1dCBv
bmx5LiBUaGUgdGltZSB0aGUgcHJvY2Vzc29yIHdhcyBjcmVhdGVkLgoKDQoFBAICBwYSBJwC
AhsKDQoFBAICBwESBJwCHCcKDQoFBAICBwMSBJwCKisKDQoFBAICBwgSBJ0CBjEKEAoIBAIC
BwicCAASBJ0CBzAKhgEKBAQCAggSBKECAhoaeCBUaGUgW0tNUyBrZXldKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9zZWN1cml0eS1rZXktbWFuYWdlbWVudCkgdXNlZCBmb3IKIGVuY3J5
cHRpb24gYW5kIGRlY3J5cHRpb24gaW4gQ01FSyBzY2VuYXJpb3MuCgoNCgUEAgIIBRIEoQIC
CAoNCgUEAgIIARIEoQIJFQoNCgUEAgIIAxIEoQIYGQo1CgQEAgIJEgSkAgJGGicgT3V0cHV0
IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlLgoKDQoFBAICCQUSBKQCAgYKDQoFBAIC
CQESBKQCBxQKDQoFBAICCQMSBKQCFxkKDQoFBAICCQgSBKQCGkUKEAoIBAICCQicCAASBKQC
G0QKNQoEBAICChIEpwICRhonIE91dHB1dCBvbmx5LiBSZXNlcnZlZCBmb3IgZnV0dXJlIHVz
ZS4KCg0KBQQCAgoFEgSnAgIGCg0KBQQCAgoBEgSnAgcUCg0KBQQCAgoDEgSnAhcZCg0KBQQC
AgoIEgSnAhpFChAKCAQCAgoInAgAEgSnAhtEYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1::Processor::ProcessorVersion ===
    # Fields for ProcessorVersion
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: document_schema Type: 11 (.google.cloud.documentai.v1.DocumentSchema)
    # Field: state Type: 14 (.google.cloud.documentai.v1.ProcessorVersion.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: latest_evaluation Type: 11 (.google.cloud.documentai.v1.EvaluationReference)
    # Field: kms_key_name Type: 9 ()
    # Field: kms_key_version_name Type: 9 ()
    # Field: google_managed Type: 8 ()
    # Field: deprecation_info Type: 11 (.google.cloud.documentai.v1.ProcessorVersion.DeprecationInfo)
    # Field: model_type Type: 14 (.google.cloud.documentai.v1.ProcessorVersion.ModelType)
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()
    # Field: gen_ai_model_info Type: 11 (.google.cloud.documentai.v1.ProcessorVersion.GenAiModelInfo)

# Enum: ProcessorVersion::State
our $ProcessorVersion_STATE_UNSPECIFIED = 0;
our $ProcessorVersion_DEPLOYED = 1;
our $ProcessorVersion_DEPLOYING = 2;
our $ProcessorVersion_UNDEPLOYED = 3;
our $ProcessorVersion_UNDEPLOYING = 4;
our $ProcessorVersion_CREATING = 5;
our $ProcessorVersion_DELETING = 6;
our $ProcessorVersion_FAILED = 7;
our $ProcessorVersion_IMPORTING = 8;

# Enum: ProcessorVersion::ModelType
our $ProcessorVersion_MODEL_TYPE_UNSPECIFIED = 0;
our $ProcessorVersion_MODEL_TYPE_GENERATIVE = 1;
our $ProcessorVersion_MODEL_TYPE_CUSTOM = 2;

# === Message: Google::Cloud::Documentai::V1::Processor::ProcessorVersionAlias ===
    # Fields for ProcessorVersionAlias
    # Field: alias Type: 9 ()
    # Field: processor_version Type: 9 ()

# === Message: Google::Cloud::Documentai::V1::Processor::Processor ===
    # Fields for Processor
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.documentai.v1.Processor.State)
    # Field: default_processor_version Type: 9 ()
    # Field: processor_version_aliases Type: 11 (.google.cloud.documentai.v1.ProcessorVersionAlias)
    # Field: process_endpoint Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: kms_key_name Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()

# Enum: Processor::State
our $Processor_STATE_UNSPECIFIED = 0;
our $Processor_ENABLED = 1;
our $Processor_DISABLED = 2;
our $Processor_ENABLING = 3;
our $Processor_DISABLING = 4;
our $Processor_CREATING = 5;
our $Processor_FAILED = 6;
our $Processor_DELETING = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1::Processor - Compiled Protocol Buffers messages for google/cloud/documentai/v1/processor.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1::Processor;

    my $msg = Google::Cloud::Documentai::V1::Processor::ProcessorVersion->new({
        name => $name,
        display_name => $display_name,
        document_schema => $document_schema,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1::Processor::ProcessorVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1/processor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1::Processor::ProcessorVersion

A processor version is an implementation of a processor. Each processor
can have multiple versions, pretrained by Google internally or uptrained
by the customer. A processor can only have one default version at a time.
Its document-processing behavior is defined by that version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the processor version.
Format:
`projects/{project}/locations/{location}/processors/{processor}/processorVersions/{processor_version}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the processor version.

=item * C<< $msg->document_schema() >> / C<< $msg->document_schema($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema>)

Output only. The schema of the processor version. Describes the output.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1::ProcessorVersion::State>)

Output only. The state of the processor version.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the processor version was created.

=item * C<< $msg->latest_evaluation() >> / C<< $msg->latest_evaluation($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Evaluation::EvaluationReference>)

Output only. The most recently invoked evaluation for the processor
version.

=item * C<< $msg->kms_key_name() >> / C<< $msg->kms_key_name($value) >>

Type: C<String>

Output only. The KMS key name used for encryption.

=item * C<< $msg->kms_key_version_name() >> / C<< $msg->kms_key_version_name($value) >>

Type: C<String>

Output only. The KMS key version with which data is encrypted.

=item * C<< $msg->google_managed() >> / C<< $msg->google_managed($value) >>

Type: C<Bool>

Output only. Denotes that this `ProcessorVersion` is managed by Google.

=item * C<< $msg->deprecation_info() >> / C<< $msg->deprecation_info($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Processor::ProcessorVersion::DeprecationInfo>)

Output only. If set, information about the eventual deprecation of this
version.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1::ProcessorVersion::ModelType>)

Output only. The model type of this processor version.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->gen_ai_model_info() >> / C<< $msg->gen_ai_model_info($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo>)

Output only. Information about Generative AI model-based processor
versions.

=back

=head3 Enum: ProcessorVersion::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<DEPLOYED> => C<1>

=item * C<DEPLOYING> => C<2>

=item * C<UNDEPLOYED> => C<3>

=item * C<UNDEPLOYING> => C<4>

=item * C<CREATING> => C<5>

=item * C<DELETING> => C<6>

=item * C<FAILED> => C<7>

=item * C<IMPORTING> => C<8>

=back

=head3 Enum: ProcessorVersion::ModelType

=over 4

=item * C<MODEL_TYPE_UNSPECIFIED> => C<0>

=item * C<MODEL_TYPE_GENERATIVE> => C<1>

=item * C<MODEL_TYPE_CUSTOM> => C<2>

=back

=head2 Google::Cloud::Documentai::V1::Processor::ProcessorVersionAlias

Contains the alias and the aliased resource name of processor version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alias() >> / C<< $msg->alias($value) >>

Type: C<String>

The alias in the form of `processor_version` resource name.

=item * C<< $msg->processor_version() >> / C<< $msg->processor_version($value) >>

Type: C<String>

The resource name of aliased processor version.

=back

=head2 Google::Cloud::Documentai::V1::Processor::Processor

The first-class citizen for Document AI. Each processor defines how to
extract structural information from a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Immutable. The resource name of the processor.
Format: `projects/{project}/locations/{location}/processors/{processor}`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The processor type, such as: `OCR_PROCESSOR`, `INVOICE_PROCESSOR`.
To get a list of processor types, see
[FetchProcessorTypes][google.cloud.documentai.v1.DocumentProcessorService.FetchProcessorTypes].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the processor.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1::Processor::State>)

Output only. The state of the processor.

=item * C<< $msg->default_processor_version() >> / C<< $msg->default_processor_version($value) >>

Type: C<String>

The default processor version.

=item * C<< $msg->processor_version_aliases() >> / C<< $msg->processor_version_aliases($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Processor::ProcessorVersionAlias>)

Output only. The processor version aliases.

=item * C<< $msg->process_endpoint() >> / C<< $msg->process_endpoint($value) >>

Type: C<String>

Output only. Immutable. The http endpoint that can be called to invoke
processing.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the processor was created.

=item * C<< $msg->kms_key_name() >> / C<< $msg->kms_key_name($value) >>

Type: C<String>

The [KMS key](https://cloud.google.com/security-key-management) used for
encryption and decryption in CMEK scenarios.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=back

=head3 Enum: Processor::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=item * C<ENABLING> => C<3>

=item * C<DISABLING> => C<4>

=item * C<CREATING> => C<5>

=item * C<FAILED> => C<6>

=item * C<DELETING> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1::Processor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
