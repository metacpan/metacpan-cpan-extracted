package Google::Cloud::Documentai::V1beta3::Processor;

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
    eval { require Google::Cloud::Documentai::V1beta3::DocumentSchema };
    eval { require Google::Cloud::Documentai::V1beta3::Evaluation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL3Byb2Nlc3Nvci5wcm90bxIfZ29v
Z2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo1Z29vZ2xlL2Nsb3VkL2RvY3Vt
ZW50YWkvdjFiZXRhMy9kb2N1bWVudF9zY2hlbWEucHJvdG8aMGdvb2dsZS9jbG91ZC9kb2N1
bWVudGFpL3YxYmV0YTMvZXZhbHVhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byK0EwoQUHJvY2Vzc29yVmVyc2lvbhIXCgRuYW1lGAEgASgJQgPgQQhSBG5h
bWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRJdCg9kb2N1bWVudF9zY2hl
bWEYDCABKAsyLy5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLkRvY3VtZW50U2No
ZW1hQgPgQQNSDmRvY3VtZW50U2NoZW1hElIKBXN0YXRlGAYgASgOMjcuZ29vZ2xlLmNsb3Vk
LmRvY3VtZW50YWkudjFiZXRhMy5Qcm9jZXNzb3JWZXJzaW9uLlN0YXRlQgPgQQNSBXN0YXRl
EkAKC2NyZWF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UgpjcmVhdGVUaW1lEmYKEWxhdGVzdF9ldmFsdWF0aW9uGAggASgLMjQuZ29vZ2xlLmNsb3Vk
LmRvY3VtZW50YWkudjFiZXRhMy5FdmFsdWF0aW9uUmVmZXJlbmNlQgPgQQNSEGxhdGVzdEV2
YWx1YXRpb24SJQoMa21zX2tleV9uYW1lGAkgASgJQgPgQQNSCmttc0tleU5hbWUSNAoUa21z
X2tleV92ZXJzaW9uX25hbWUYCiABKAlCA+BBA1IRa21zS2V5VmVyc2lvbk5hbWUSKgoOZ29v
Z2xlX21hbmFnZWQYCyABKAhCA+BBA1INZ29vZ2xlTWFuYWdlZBJxChBkZXByZWNhdGlvbl9p
bmZvGA0gASgLMkEuZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5Qcm9jZXNzb3JW
ZXJzaW9uLkRlcHJlY2F0aW9uSW5mb0ID4EEDUg9kZXByZWNhdGlvbkluZm8SXwoKbW9kZWxf
dHlwZRgPIAEoDjI7Lmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuUHJvY2Vzc29y
VmVyc2lvbi5Nb2RlbFR5cGVCA+BBA1IJbW9kZWxUeXBlEigKDXNhdGlzZmllc19wenMYECAB
KAhCA+BBA1IMc2F0aXNmaWVzUHpzEigKDXNhdGlzZmllc19wemkYESABKAhCA+BBA1IMc2F0
aXNmaWVzUHppEnAKEWdlbl9haV9tb2RlbF9pbmZvGBIgASgLMkAuZ29vZ2xlLmNsb3VkLmRv
Y3VtZW50YWkudjFiZXRhMy5Qcm9jZXNzb3JWZXJzaW9uLkdlbkFpTW9kZWxJbmZvQgPgQQNS
DmdlbkFpTW9kZWxJbmZvEmYKEmdyb3VuZGluZ19zZXR0aW5ncxgVIAEoCzIyLmdvb2dsZS5j
bG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuR3JvdW5kaW5nU2V0dGluZ3NCA+BBA1IRZ3JvdW5k
aW5nU2V0dGluZ3MazQEKD0RlcHJlY2F0aW9uSW5mbxJFChBkZXByZWNhdGlvbl90aW1lGAEg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIPZGVwcmVjYXRpb25UaW1lEnMKHXJl
cGxhY2VtZW50X3Byb2Nlc3Nvcl92ZXJzaW9uGAIgASgJQi/6QSwKKmRvY3VtZW50YWkuZ29v
Z2xlYXBpcy5jb20vUHJvY2Vzc29yVmVyc2lvblIbcmVwbGFjZW1lbnRQcm9jZXNzb3JWZXJz
aW9uGqEGCg5HZW5BaU1vZGVsSW5mbxKbAQocZm91bmRhdGlvbl9nZW5fYWlfbW9kZWxfaW5m
bxgBIAEoCzJZLmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuUHJvY2Vzc29yVmVy
c2lvbi5HZW5BaU1vZGVsSW5mby5Gb3VuZGF0aW9uR2VuQWlNb2RlbEluZm9IAFIYZm91bmRh
dGlvbkdlbkFpTW9kZWxJbmZvEo8BChhjdXN0b21fZ2VuX2FpX21vZGVsX2luZm8YAiABKAsy
VS5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLlByb2Nlc3NvclZlcnNpb24uR2Vu
QWlNb2RlbEluZm8uQ3VzdG9tR2VuQWlNb2RlbEluZm9IAFIUY3VzdG9tR2VuQWlNb2RlbElu
Zm8aiAEKGEZvdW5kYXRpb25HZW5BaU1vZGVsSW5mbxItChJmaW5ldHVuaW5nX2FsbG93ZWQY
ASABKAhSEWZpbmV0dW5pbmdBbGxvd2VkEj0KG21pbl90cmFpbl9sYWJlbGVkX2RvY3VtZW50
cxgCIAEoBVIYbWluVHJhaW5MYWJlbGVkRG9jdW1lbnRzGsUCChRDdXN0b21HZW5BaU1vZGVs
SW5mbxKRAQoRY3VzdG9tX21vZGVsX3R5cGUYASABKA4yZS5nb29nbGUuY2xvdWQuZG9jdW1l
bnRhaS52MWJldGEzLlByb2Nlc3NvclZlcnNpb24uR2VuQWlNb2RlbEluZm8uQ3VzdG9tR2Vu
QWlNb2RlbEluZm8uQ3VzdG9tTW9kZWxUeXBlUg9jdXN0b21Nb2RlbFR5cGUSOQoZYmFzZV9w
cm9jZXNzb3JfdmVyc2lvbl9pZBgCIAEoCVIWYmFzZVByb2Nlc3NvclZlcnNpb25JZCJeCg9D
dXN0b21Nb2RlbFR5cGUSIQodQ1VTVE9NX01PREVMX1RZUEVfVU5TUEVDSUZJRUQQABIYChRW
RVJTSU9ORURfRk9VTkRBVElPThABEg4KCkZJTkVfVFVORUQQAkIMCgptb2RlbF9pbmZvIpMB
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCERFUExPWUVEEAESDQoJREVQTE9Z
SU5HEAISDgoKVU5ERVBMT1lFRBADEg8KC1VOREVQTE9ZSU5HEAQSDAoIQ1JFQVRJTkcQBRIM
CghERUxFVElORxAGEgoKBkZBSUxFRBAHEg0KCUlNUE9SVElORxAIIlkKCU1vZGVsVHlwZRIa
ChZNT0RFTF9UWVBFX1VOU1BFQ0lGSUVEEAASGQoVTU9ERUxfVFlQRV9HRU5FUkFUSVZFEAES
FQoRTU9ERUxfVFlQRV9DVVNUT00QAjqWAepBkgEKKmRvY3VtZW50YWkuZ29vZ2xlYXBpcy5j
b20vUHJvY2Vzc29yVmVyc2lvbhJkcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L3Byb2Nlc3NvcnMve3Byb2Nlc3Nvcn0vcHJvY2Vzc29yVmVyc2lvbnMve3Byb2Nl
c3Nvcl92ZXJzaW9ufSKLAQoVUHJvY2Vzc29yVmVyc2lvbkFsaWFzEhQKBWFsaWFzGAEgASgJ
UgVhbGlhcxJcChFwcm9jZXNzb3JfdmVyc2lvbhgCIAEoCUIv+kEsCipkb2N1bWVudGFpLmdv
b2dsZWFwaXMuY29tL1Byb2Nlc3NvclZlcnNpb25SEHByb2Nlc3NvclZlcnNpb24i5gYKCVBy
b2Nlc3NvchIaCgRuYW1lGAEgASgJQgbgQQXgQQNSBG5hbWUSEgoEdHlwZRgCIAEoCVIEdHlw
ZRIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lEksKBXN0YXRlGAQgASgOMjAu
Z29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5Qcm9jZXNzb3IuU3RhdGVCA+BBA1IF
c3RhdGUSawoZZGVmYXVsdF9wcm9jZXNzb3JfdmVyc2lvbhgJIAEoCUIv+kEsCipkb2N1bWVu
dGFpLmdvb2dsZWFwaXMuY29tL1Byb2Nlc3NvclZlcnNpb25SF2RlZmF1bHRQcm9jZXNzb3JW
ZXJzaW9uEncKGXByb2Nlc3Nvcl92ZXJzaW9uX2FsaWFzZXMYCiADKAsyNi5nb29nbGUuY2xv
dWQuZG9jdW1lbnRhaS52MWJldGEzLlByb2Nlc3NvclZlcnNpb25BbGlhc0ID4EEDUhdwcm9j
ZXNzb3JWZXJzaW9uQWxpYXNlcxIxChBwcm9jZXNzX2VuZHBvaW50GAYgASgJQgbgQQPgQQVS
D3Byb2Nlc3NFbmRwb2ludBJACgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRIgCgxrbXNfa2V5X25hbWUYCCABKAlSCmtt
c0tleU5hbWUSKAoNc2F0aXNmaWVzX3B6cxgMIAEoCEID4EEDUgxzYXRpc2ZpZXNQenMSKAoN
c2F0aXNmaWVzX3B6aRgNIAEoCEID4EEDUgxzYXRpc2ZpZXNQemkifgoFU3RhdGUSFQoRU1RB
VEVfVU5TUEVDSUZJRUQQABILCgdFTkFCTEVEEAESDAoIRElTQUJMRUQQAhIMCghFTkFCTElO
RxADEg0KCURJU0FCTElORxAEEgwKCENSRUFUSU5HEAUSCgoGRkFJTEVEEAYSDAoIREVMRVRJ
TkcQBzpo6kFlCiNkb2N1bWVudGFpLmdvb2dsZWFwaXMuY29tL1Byb2Nlc3NvchI+cHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Byb2Nlc3NvcnMve3Byb2Nlc3Nv
cn0i2gEKEUdyb3VuZGluZ1NldHRpbmdzEmcKDmdyb3VuZGluZ190eXBlGAEgASgOMkAuZ29v
Z2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5Hcm91bmRpbmdTZXR0aW5ncy5Hcm91bmRp
bmdUeXBlUg1ncm91bmRpbmdUeXBlIlwKDUdyb3VuZGluZ1R5cGUSHgoaR1JPVU5ESU5HX1RZ
UEVfVU5TUEVDSUZJRUQQABIICgRIQVJEEAESDwoLT0NSX1JFTEFYRUQQAhIQCgxOT19HUk9V
TkRJTkcQAyKDAQoZUHJvY2Vzc29yVmVyc2lvbk92ZXJyaWRlcxJmChJncm91bmRpbmdfc2V0
dGluZ3MYASABKAsyMi5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLkdyb3VuZGlu
Z1NldHRpbmdzQgPgQQFSEWdyb3VuZGluZ1NldHRpbmdzQuoBCiNjb20uZ29vZ2xlLmNsb3Vk
LmRvY3VtZW50YWkudjFiZXRhM0ITRG9jdW1lbnRBaVByb2Nlc3NvclABWkNjbG91ZC5nb29n
bGUuY29tL2dvL2RvY3VtZW50YWkvYXBpdjFiZXRhMy9kb2N1bWVudGFpcGI7ZG9jdW1lbnRh
aXBiqgIfR29vZ2xlLkNsb3VkLkRvY3VtZW50QUkuVjFCZXRhM8oCH0dvb2dsZVxDbG91ZFxE
b2N1bWVudEFJXFYxYmV0YTPqAiJHb29nbGU6OkNsb3VkOjpEb2N1bWVudEFJOjpWMWJldGEz
SqBdCgcSBQ4AywIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA/CgkKAgMDEgMVADoKCQoCAwQS
AxYAKQoICgEIEgMYADwKCQoCCCUSAxgAPAoICgEIEgMZAFoKCQoCCAsSAxkAWgoICgEIEgMa
ACIKCQoCCAoSAxoAIgoICgEIEgMbADQKCQoCCAgSAxsANAoICgEIEgMcADwKCQoCCAESAxwA
PAoICgEIEgMdADwKCQoCCCkSAx0APAoICgEIEgMeADsKCQoCCC0SAx4AOwqqAgoCBAASBSQA
xwEBGpwCIEEgcHJvY2Vzc29yIHZlcnNpb24gaXMgYW4gaW1wbGVtZW50YXRpb24gb2YgYSBw
cm9jZXNzb3IuIEVhY2ggcHJvY2Vzc29yCiBjYW4gaGF2ZSBtdWx0aXBsZSB2ZXJzaW9ucywg
cHJldHJhaW5lZCBieSBHb29nbGUgaW50ZXJuYWxseSBvciB1cHRyYWluZWQKIGJ5IHRoZSBj
dXN0b21lci4gQSBwcm9jZXNzb3IgY2FuIG9ubHkgaGF2ZSBvbmUgZGVmYXVsdCB2ZXJzaW9u
IGF0IGEgdGltZS4KIEl0cyBkb2N1bWVudC1wcm9jZXNzaW5nIGJlaGF2aW9yIGlzIGRlZmlu
ZWQgYnkgdGhhdCB2ZXJzaW9uLgoKCgoDBAABEgMkCBgKCwoDBAAHEgQlAigECg0KBQQAB50I
EgQlAigEClUKBAQAAwASBCsCNAMaRyBJbmZvcm1hdGlvbiBhYm91dCB0aGUgdXBjb21pbmcg
ZGVwcmVjYXRpb24gb2YgdGhpcyBwcm9jZXNzb3IgdmVyc2lvbi4KCgwKBQQAAwABEgMrChkK
TQoGBAADAAIAEgMtBDMaPiBUaGUgdGltZSBhdCB3aGljaCB0aGlzIHByb2Nlc3NvciB2ZXJz
aW9uIHdpbGwgYmUgZGVwcmVjYXRlZC4KCg4KBwQAAwACAAYSAy0EHQoOCgcEAAMAAgABEgMt
Hi4KDgoHBAADAAIAAxIDLTEyClMKBgQAAwACARIEMAQzCxpDIElmIHNldCwgdGhlIHByb2Nl
c3NvciB2ZXJzaW9uIHRoYXQgd2lsbCBiZSB1c2VkIGFzIGEgcmVwbGFjZW1lbnQuCgoOCgcE
AAMAAgEFEgMwBAoKDgoHBAADAAIBARIDMAsoCg4KBwQAAwACAQMSAzArLAoPCgcEAAMAAgEI
EgQxCDMKChEKCQQAAwACAQifCBIEMQkzCQpPCgQEAAMBEgQ3AmIDGkEgSW5mb3JtYXRpb24g
YWJvdXQgR2VuZXJhdGl2ZSBBSSBtb2RlbC1iYXNlZCBwcm9jZXNzb3IgdmVyc2lvbnMuCgoM
CgUEAAMBARIDNwoYCk8KBgQAAwEDABIEOQRABRo/IEluZm9ybWF0aW9uIGZvciBhIHByZXRy
YWluZWQgR29vZ2xlLW1hbmFnZWQgZm91bmRhdGlvbiBtb2RlbC4KCg4KBwQAAwEDAAESAzkM
JApSCggEAAMBAwACABIDOwYiGkEgV2hldGhlciBmaW5lIHR1bmluZyBpcyBhbGxvd2VkIGZv
ciB0aGlzIGJhc2UgcHJvY2Vzc29yIHZlcnNpb24uCgoQCgkEAAMBAwACAAUSAzsGCgoQCgkE
AAMBAwACAAESAzsLHQoQCgkEAAMBAwACAAMSAzsgIQptCggEAAMBAwACARIDPwYsGlwgVGhl
IG1pbmltdW0gbnVtYmVyIG9mIGxhYmVsZWQgZG9jdW1lbnRzIGluIHRoZSB0cmFpbmluZyBk
YXRhc2V0CiByZXF1aXJlZCBmb3IgZmluZSB0dW5pbmcuCgoQCgkEAAMBAwACAQUSAz8GCwoQ
CgkEAAMBAwACAQESAz8MJwoQCgkEAAMBAwACAQMSAz8qKwq/AQoGBAADAQMBEgRFBFcFGq4B
IEluZm9ybWF0aW9uIGZvciBhIGN1c3RvbSBHZW5lcmF0aXZlIEFJIG1vZGVsIGNyZWF0ZWQg
YnkgdGhlIHVzZXIuIFRoZXNlCiBhcmUgY3JlYXRlZCB3aXRoIGBDcmVhdGUgTmV3IFZlcnNp
b25gIGluIGVpdGhlciB0aGUgYENhbGwgZm91bmRhdGlvbgogbW9kZWxgIG9yIGBGaW5lIHR1
bmluZ2AgdGFicy4KCg4KBwQAAwEDAQESA0UMIApBCggEAAMBAwEEABIERwZQBxovIFRoZSB0
eXBlIG9mIGN1c3RvbSBtb2RlbCBjcmVhdGVkIGJ5IHRoZSB1c2VyLgoKEAoJBAADAQMBBAAB
EgNHCxoKMwoKBAADAQMBBAACABIDSQgqGiAgVGhlIG1vZGVsIHR5cGUgaXMgdW5zcGVjaWZp
ZWQuCgoSCgsEAAMBAwEEAAIAARIDSQglChIKCwQAAwEDAQQAAgACEgNJKCkKPwoKBAADAQMB
BAACARIDTAghGiwgVGhlIG1vZGVsIGlzIGEgdmVyc2lvbmVkIGZvdW5kYXRpb24gbW9kZWwu
CgoSCgsEAAMBAwEEAAIBARIDTAgcChIKCwQAAwEDAQQAAgECEgNMHyAKPwoKBAADAQMBBAAC
AhIDTwgXGiwgVGhlIG1vZGVsIGlzIGEgZmluZXR1bmVkIGZvdW5kYXRpb24gbW9kZWwuCgoS
CgsEAAMBAwEEAAICARIDTwgSChIKCwQAAwEDAQQAAgICEgNPFRYKQAoIBAADAQMBAgASA1MG
LBovIFRoZSB0eXBlIG9mIGN1c3RvbSBtb2RlbCBjcmVhdGVkIGJ5IHRoZSB1c2VyLgoKEAoJ
BAADAQMBAgAGEgNTBhUKEAoJBAADAQMBAgABEgNTFicKEAoJBAADAQMBAgADEgNTKisKRgoI
BAADAQMBAgESA1YGKxo1IFRoZSBiYXNlIHByb2Nlc3NvciB2ZXJzaW9uIElEIGZvciB0aGUg
Y3VzdG9tIG1vZGVsLgoKEAoJBAADAQMBAgEFEgNWBgwKEAoJBAADAQMBAgEBEgNWDSYKEAoJ
BAADAQMBAgEDEgNWKSoKlQEKBgQAAwEIABIEWwRhBRqEASBUaGUgcHJvY2Vzc29yIHZlcnNp
b24gaXMgZWl0aGVyIGEgcHJldHJhaW5lZCBHb29nbGUtbWFuYWdlZCBmb3VuZGF0aW9uCiBt
b2RlbCBvciBhIGN1c3RvbSBHZW5lcmF0aXZlIEFJIG1vZGVsIGNyZWF0ZWQgYnkgdGhlIHVz
ZXIuCgoOCgcEAAMBCAABEgNbChQKTgoGBAADAQIAEgNdBkAaPyBJbmZvcm1hdGlvbiBmb3Ig
YSBwcmV0cmFpbmVkIEdvb2dsZS1tYW5hZ2VkIGZvdW5kYXRpb24gbW9kZWwuCgoOCgcEAAMB
AgAGEgNdBh4KDgoHBAADAQIAARIDXR87Cg4KBwQAAwECAAMSA10+PwpSCgYEAAMBAgESA2AG
OBpDIEluZm9ybWF0aW9uIGZvciBhIGN1c3RvbSBHZW5lcmF0aXZlIEFJIG1vZGVsIGNyZWF0
ZWQgYnkgdGhlIHVzZXIuCgoOCgcEAAMBAgEGEgNgBhoKDgoHBAADAQIBARIDYBszCg4KBwQA
AwECAQMSA2A2Nwo+CgQEAAQAEgVlAoABAxovIFRoZSBwb3NzaWJsZSBzdGF0ZXMgb2YgdGhl
IHByb2Nlc3NvciB2ZXJzaW9uLgoKDAoFBAAEAAESA2UHDApCCgYEAAQAAgASA2cEGhozIFRo
ZSBwcm9jZXNzb3IgdmVyc2lvbiBpcyBpbiBhbiB1bnNwZWNpZmllZCBzdGF0ZS4KCg4KBwQA
BAACAAESA2cEFQoOCgcEAAQAAgACEgNnGBkKUgoGBAAEAAIBEgNqBBEaQyBUaGUgcHJvY2Vz
c29yIHZlcnNpb24gaXMgZGVwbG95ZWQgYW5kIGNhbiBiZSB1c2VkIGZvciBwcm9jZXNzaW5n
LgoKDgoHBAAEAAIBARIDagQMCg4KBwQABAACAQISA2oPEAo5CgYEAAQAAgISA20EEhoqIFRo
ZSBwcm9jZXNzb3IgdmVyc2lvbiBpcyBiZWluZyBkZXBsb3llZC4KCg4KBwQABAACAgESA20E
DQoOCgcEAAQAAgICEgNtEBEKWQoGBAAEAAIDEgNwBBMaSiBUaGUgcHJvY2Vzc29yIHZlcnNp
b24gaXMgbm90IGRlcGxveWVkIGFuZCBjYW5ub3QgYmUgdXNlZCBmb3IgcHJvY2Vzc2luZy4K
Cg4KBwQABAACAwESA3AEDgoOCgcEAAQAAgMCEgNwERIKOwoGBAAEAAIEEgNzBBQaLCBUaGUg
cHJvY2Vzc29yIHZlcnNpb24gaXMgYmVpbmcgdW5kZXBsb3llZC4KCg4KBwQABAACBAESA3ME
DwoOCgcEAAQAAgQCEgNzEhMKOAoGBAAEAAIFEgN2BBEaKSBUaGUgcHJvY2Vzc29yIHZlcnNp
b24gaXMgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACBQESA3YEDAoOCgcEAAQAAgUCEgN2DxAK
OAoGBAAEAAIGEgN5BBEaKSBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaXMgYmVpbmcgZGVsZXRl
ZC4KCg4KBwQABAACBgESA3kEDAoOCgcEAAQAAgYCEgN5DxAKTwoGBAAEAAIHEgN8BA8aQCBU
aGUgcHJvY2Vzc29yIHZlcnNpb24gZmFpbGVkIGFuZCBpcyBpbiBhbiBpbmRldGVybWluYXRl
IHN0YXRlLgoKDgoHBAAEAAIHARIDfAQKCg4KBwQABAACBwISA3wNDgo5CgYEAAQAAggSA38E
EhoqIFRoZSBwcm9jZXNzb3IgdmVyc2lvbiBpcyBiZWluZyBpbXBvcnRlZC4KCg4KBwQABAAC
CAESA38EDQoOCgcEAAQAAggCEgN/EBEKRAoEBAAEARIGgwECjAEDGjQgVGhlIHBvc3NpYmxl
IG1vZGVsIHR5cGVzIG9mIHRoZSBwcm9jZXNzb3IgdmVyc2lvbi4KCg0KBQQABAEBEgSDAQcQ
CkMKBgQABAECABIEhQEEHxozIFRoZSBwcm9jZXNzb3IgdmVyc2lvbiBoYXMgdW5zcGVjaWZp
ZWQgbW9kZWwgdHlwZS4KCg8KBwQABAECAAESBIUBBBoKDwoHBAAEAQIAAhIEhQEdHgpCCgYE
AAQBAgESBIgBBB4aMiBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaGFzIGdlbmVyYXRpdmUgbW9k
ZWwgdHlwZS4KCg8KBwQABAECAQESBIgBBBkKDwoHBAAEAQIBAhIEiAEcHQo+CgYEAAQBAgIS
BIsBBBoaLiBUaGUgcHJvY2Vzc29yIHZlcnNpb24gaGFzIGN1c3RvbSBtb2RlbCB0eXBlLgoK
DwoHBAAEAQICARIEiwEEFQoPCgcEAAQBAgICEgSLARgZCrkBCgQEAAIAEgSRAQI9GqoBIElk
ZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9jZXNzb3IgdmVyc2lvbi4K
IEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJv
Y2Vzc29ycy97cHJvY2Vzc29yfS9wcm9jZXNzb3JWZXJzaW9ucy97cHJvY2Vzc29yX3ZlcnNp
b259YAoKDQoFBAACAAUSBJEBAggKDQoFBAACAAESBJEBCQ0KDQoFBAACAAMSBJEBEBEKDQoF
BAACAAgSBJEBEjwKEAoIBAACAAicCAASBJEBEzsKOgoEBAACARIElAECGhosIFRoZSBkaXNw
bGF5IG5hbWUgb2YgdGhlIHByb2Nlc3NvciB2ZXJzaW9uLgoKDQoFBAACAQUSBJQBAggKDQoF
BAACAQESBJQBCRUKDQoFBAACAQMSBJQBGBkKWQoEBAACAhIGlwECmAEyGkkgT3V0cHV0IG9u
bHkuIFRoZSBzY2hlbWEgb2YgdGhlIHByb2Nlc3NvciB2ZXJzaW9uLiBEZXNjcmliZXMgdGhl
IG91dHB1dC4KCg0KBQQAAgIGEgSXAQIQCg0KBQQAAgIBEgSXAREgCg0KBQQAAgIDEgSXASMl
Cg0KBQQAAgIIEgSYAQYxChAKCAQAAgIInAgAEgSYAQcwCkAKBAQAAgMSBJsBAj4aMiBPdXRw
dXQgb25seS4gVGhlIHN0YXRlIG9mIHRoZSBwcm9jZXNzb3IgdmVyc2lvbi4KCg0KBQQAAgMG
EgSbAQIHCg0KBQQAAgMBEgSbAQgNCg0KBQQAAgMDEgSbARARCg0KBQQAAgMIEgSbARI9ChAK
CAQAAgMInAgAEgSbARM8CkoKBAQAAgQSBp4BAp8BMho6IE91dHB1dCBvbmx5LiBUaGUgdGlt
ZSB0aGUgcHJvY2Vzc29yIHZlcnNpb24gd2FzIGNyZWF0ZWQuCgoNCgUEAAIEBhIEngECGwoN
CgUEAAIEARIEngEcJwoNCgUEAAIEAxIEngEqKwoNCgUEAAIECBIEnwEGMQoQCggEAAIECJwI
ABIEnwEHMApfCgQEAAIFEgajAQKkATIaTyBPdXRwdXQgb25seS4gVGhlIG1vc3QgcmVjZW50
bHkgaW52b2tlZCBldmFsdWF0aW9uIGZvciB0aGUgcHJvY2Vzc29yCiB2ZXJzaW9uLgoKDQoF
BAACBQYSBKMBAhUKDQoFBAACBQESBKMBFicKDQoFBAACBQMSBKMBKisKDQoFBAACBQgSBKQB
BjEKEAoIBAACBQicCAASBKQBBzAKQgoEBAACBhIEpwECRho0IE91dHB1dCBvbmx5LiBUaGUg
S01TIGtleSBuYW1lIHVzZWQgZm9yIGVuY3J5cHRpb24uCgoNCgUEAAIGBRIEpwECCAoNCgUE
AAIGARIEpwEJFQoNCgUEAAIGAxIEpwEYGQoNCgUEAAIGCBIEpwEaRQoQCggEAAIGCJwIABIE
pwEbRApOCgQEAAIHEgSqAQJPGkAgT3V0cHV0IG9ubHkuIFRoZSBLTVMga2V5IHZlcnNpb24g
d2l0aCB3aGljaCBkYXRhIGlzIGVuY3J5cHRlZC4KCg0KBQQAAgcFEgSqAQIICg0KBQQAAgcB
EgSqAQkdCg0KBQQAAgcDEgSqASAiCg0KBQQAAgcIEgSqASNOChAKCAQAAgcInAgAEgSqASRN
ClcKBAQAAggSBK0BAkcaSSBPdXRwdXQgb25seS4gRGVub3RlcyB0aGF0IHRoaXMgYFByb2Nl
c3NvclZlcnNpb25gIGlzIG1hbmFnZWQgYnkgR29vZ2xlLgoKDQoFBAACCAUSBK0BAgYKDQoF
BAACCAESBK0BBxUKDQoFBAACCAMSBK0BGBoKDQoFBAACCAgSBK0BG0YKEAoIBAACCAicCAAS
BK0BHEUKYwoEBAACCRIGsQECsgEyGlMgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5mb3JtYXRp
b24gYWJvdXQgdGhlIGV2ZW50dWFsIGRlcHJlY2F0aW9uIG9mIHRoaXMKIHZlcnNpb24uCgoN
CgUEAAIJBhIEsQECEQoNCgUEAAIJARIEsQESIgoNCgUEAAIJAxIEsQElJwoNCgUEAAIJCBIE
sgEGMQoQCggEAAIJCJwIABIEsgEHMApGCgQEAAIKEgS1AQJIGjggT3V0cHV0IG9ubHkuIFRo
ZSBtb2RlbCB0eXBlIG9mIHRoaXMgcHJvY2Vzc29yIHZlcnNpb24uCgoNCgUEAAIKBhIEtQEC
CwoNCgUEAAIKARIEtQEMFgoNCgUEAAIKAxIEtQEZGwoNCgUEAAIKCBIEtQEcRwoQCggEAAIK
CJwIABIEtQEdRgo1CgQEAAILEgS4AQJGGicgT3V0cHV0IG9ubHkuIFJlc2VydmVkIGZvciBm
dXR1cmUgdXNlLgoKDQoFBAACCwUSBLgBAgYKDQoFBAACCwESBLgBBxQKDQoFBAACCwMSBLgB
FxkKDQoFBAACCwgSBLgBGkUKEAoIBAACCwicCAASBLgBG0QKNQoEBAACDBIEuwECRhonIE91
dHB1dCBvbmx5LiBSZXNlcnZlZCBmb3IgZnV0dXJlIHVzZS4KCg0KBQQAAgwFEgS7AQIGCg0K
BQQAAgwBEgS7AQcUCg0KBQQAAgwDEgS7ARcZCg0KBQQAAgwIEgS7ARpFChAKCAQAAgwInAgA
EgS7ARtECl8KBAQAAg0SBr8BAsABMhpPIE91dHB1dCBvbmx5LiBJbmZvcm1hdGlvbiBhYm91
dCBHZW5lcmF0aXZlIEFJIG1vZGVsLWJhc2VkIHByb2Nlc3NvcgogdmVyc2lvbnMuCgoNCgUE
AAINBhIEvwECEAoNCgUEAAINARIEvwERIgoNCgUEAAINAxIEvwElJwoNCgUEAAINCBIEwAEG
MQoQCggEAAINCJwIABIEwAEHMAq2AQoEBAACDhIGxQECxgEyGqUBIE91dHB1dCBvbmx5LiBU
aGUgZ3JvdW5kaW5nIHNldHRpbmdzIG9mIHRoZSBwcm9jZXNzb3IgdmVyc2lvbi4gVGhpcyBj
YW4gb25seQogYmUgc2V0IHVzaW5nIFRyYWluUHJvY2Vzc29yVmVyc2lvblJlcXVlc3QgdG8g
b3ZlcnJpZGUgdGhlIGRlZmF1bHQgZ3JvdW5kaW5nCiBzZXR0aW5ncy4KCg0KBQQAAg4GEgTF
AQITCg0KBQQAAg4BEgTFARQmCg0KBQQAAg4DEgTFASkrCg0KBQQAAg4IEgTGAQYxChAKCAQA
Ag4InAgAEgTGAQcwClYKAgQBEgbKAQDSAQEaSCBDb250YWlucyB0aGUgYWxpYXMgYW5kIHRo
ZSBhbGlhc2VkIHJlc291cmNlIG5hbWUgb2YgcHJvY2Vzc29yIHZlcnNpb24uCgoLCgMEAQES
BMoBCB0KSwoEBAECABIEzAECExo9IFRoZSBhbGlhcyBpbiB0aGUgZm9ybSBvZiBgcHJvY2Vz
c29yX3ZlcnNpb25gIHJlc291cmNlIG5hbWUuCgoNCgUEAQIABRIEzAECCAoNCgUEAQIAARIE
zAEJDgoNCgUEAQIAAxIEzAEREgpBCgQEAQIBEgbPAQLRAQUaMSBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiBhbGlhc2VkIHByb2Nlc3NvciB2ZXJzaW9uLgoKDQoFBAECAQUSBM8BAggKDQoFBAEC
AQESBM8BCRoKDQoFBAECAQMSBM8BHR4KDwoFBAECAQgSBs8BH9EBBAoRCgcEAQIBCJ8IEgbP
ASDRAQMKhwEKAgQCEgbWAQCuAgEaeSBUaGUgZmlyc3QtY2xhc3MgY2l0aXplbiBmb3IgRG9j
dW1lbnQgQUkuIEVhY2ggcHJvY2Vzc29yIGRlZmluZXMgaG93IHRvCiBleHRyYWN0IHN0cnVj
dHVyYWwgaW5mb3JtYXRpb24gZnJvbSBhIGRvY3VtZW50LgoKCwoDBAIBEgTWAQgRCg0KAwQC
BxIG1wEC2gEECg8KBQQCB50IEgbXAQLaAQQKNwoEBAIEABIG3QEC/QEDGicgVGhlIHBvc3Np
YmxlIHN0YXRlcyBvZiB0aGUgcHJvY2Vzc29yLgoKDQoFBAIEAAESBN0BBwwKOwoGBAIEAAIA
EgTfAQQaGisgVGhlIHByb2Nlc3NvciBpcyBpbiBhbiB1bnNwZWNpZmllZCBzdGF0ZS4KCg8K
BwQCBAACAAESBN8BBBUKDwoHBAIEAAIAAhIE3wEYGQq+AQoGBAIEAAIBEgTkAQQQGq0BIFRo
ZSBwcm9jZXNzb3IgaXMgZW5hYmxlZCwgaS5lLiwgaGFzIGFuIGVuYWJsZWQgdmVyc2lvbiB3
aGljaCBjYW4KIGN1cnJlbnRseSBzZXJ2ZSBwcm9jZXNzaW5nIHJlcXVlc3RzIGFuZCBhbGwg
dGhlIGZlYXR1cmUgZGVwZW5kZW5jaWVzIGhhdmUKIGJlZW4gc3VjY2Vzc2Z1bGx5IGluaXRp
YWxpemVkLgoKDwoHBAIEAAIBARIE5AEECwoPCgcEAgQAAgECEgTkAQ4PCiwKBgQCBAACAhIE
5wEEERocIFRoZSBwcm9jZXNzb3IgaXMgZGlzYWJsZWQuCgoPCgcEAgQAAgIBEgTnAQQMCg8K
BwQCBAACAgISBOcBDxAKVgoGBAIEAAIDEgTqAQQRGkYgVGhlIHByb2Nlc3NvciBpcyBiZWlu
ZyBlbmFibGVkLCB3aWxsIGJlY29tZSBgRU5BQkxFRGAgaWYgc3VjY2Vzc2Z1bC4KCg8KBwQC
BAACAwESBOoBBAwKDwoHBAIEAAIDAhIE6gEPEApYCgYEAgQAAgQSBO0BBBIaSCBUaGUgcHJv
Y2Vzc29yIGlzIGJlaW5nIGRpc2FibGVkLCB3aWxsIGJlY29tZSBgRElTQUJMRURgIGlmIHN1
Y2Nlc3NmdWwuCgoPCgcEAgQAAgQBEgTtAQQNCg8KBwQCBAACBAISBO0BEBEKqgIKBgQCBAAC
BRIE9AEEERqZAiBUaGUgcHJvY2Vzc29yIGlzIGJlaW5nIGNyZWF0ZWQsIHdpbGwgYmVjb21l
IGVpdGhlciBgRU5BQkxFRGAgKGZvcgogc3VjY2Vzc2Z1bCBjcmVhdGlvbikgb3IgYEZBSUxF
RGAgKGZvciBmYWlsZWQgb25lcykuCiBPbmNlIGEgcHJvY2Vzc29yIGlzIGluIHRoaXMgc3Rh
dGUsIGl0IGNhbiB0aGVuIGJlIHVzZWQgZm9yIGRvY3VtZW50CiBwcm9jZXNzaW5nLCBidXQg
dGhlIGZlYXR1cmUgZGVwZW5kZW5jaWVzIG9mIHRoZSBwcm9jZXNzb3IgbWlnaHQgbm90IGJl
CiBmdWxseSBjcmVhdGVkIHlldC4KCg8KBwQCBAACBQESBPQBBAwKDwoHBAIEAAIFAhIE9AEP
EArUAQoGBAIEAAIGEgT5AQQPGsMBIFRoZSBwcm9jZXNzb3IgZmFpbGVkIGR1cmluZyBjcmVh
dGlvbiBvciBpbml0aWFsaXphdGlvbiBvZiBmZWF0dXJlCiBkZXBlbmRlbmNpZXMuIFRoZSB1
c2VyIHNob3VsZCBkZWxldGUgdGhlIHByb2Nlc3NvciBhbmQgcmVjcmVhdGUgb25lIGFzCiBh
bGwgdGhlIGZ1bmN0aW9uYWxpdGllcyBvZiB0aGUgcHJvY2Vzc29yIGFyZSBkaXNhYmxlZC4K
Cg8KBwQCBAACBgESBPkBBAoKDwoHBAIEAAIGAhIE+QENDgpQCgYEAgQAAgcSBPwBBBEaQCBU
aGUgcHJvY2Vzc29yIGlzIGJlaW5nIGRlbGV0ZWQsIHdpbGwgYmUgcmVtb3ZlZCBpZiBzdWNj
ZXNzZnVsLgoKDwoHBAIEAAIHARIE/AEEDAoPCgcEAgQAAgcCEgT8AQ8QCpgBCgQEAgIAEgaB
AgKEAgQahwEgT3V0cHV0IG9ubHkuIEltbXV0YWJsZS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIHByb2Nlc3Nvci4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9wcm9jZXNzb3JzL3twcm9jZXNzb3J9YAoKDQoFBAICAAUSBIECAggKDQoF
BAICAAESBIECCQ0KDQoFBAICAAMSBIECEBEKDwoFBAICAAgSBoECEoQCAwoQCggEAgIACJwI
ABIEggIEKwoQCggEAgIACJwIARIEgwIELQrgAQoEBAICARIEiQICEhrRASBUaGUgcHJvY2Vz
c29yIHR5cGUsIHN1Y2ggYXM6IGBPQ1JfUFJPQ0VTU09SYCwgYElOVk9JQ0VfUFJPQ0VTU09S
YC4KIFRvIGdldCBhIGxpc3Qgb2YgcHJvY2Vzc29yIHR5cGVzLCBzZWUKIFtGZXRjaFByb2Nl
c3NvclR5cGVzXVtnb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLkRvY3VtZW50UHJv
Y2Vzc29yU2VydmljZS5GZXRjaFByb2Nlc3NvclR5cGVzXS4KCg0KBQQCAgEFEgSJAgIICg0K
BQQCAgEBEgSJAgkNCg0KBQQCAgEDEgSJAhARCjIKBAQCAgISBIwCAhoaJCBUaGUgZGlzcGxh
eSBuYW1lIG9mIHRoZSBwcm9jZXNzb3IuCgoNCgUEAgICBRIEjAICCAoNCgUEAgICARIEjAIJ
FQoNCgUEAgICAxIEjAIYGQo4CgQEAgIDEgSPAgI+GiogT3V0cHV0IG9ubHkuIFRoZSBzdGF0
ZSBvZiB0aGUgcHJvY2Vzc29yLgoKDQoFBAICAwYSBI8CAgcKDQoFBAICAwESBI8CCA0KDQoF
BAICAwMSBI8CEBEKDQoFBAICAwgSBI8CEj0KEAoIBAICAwicCAASBI8CEzwKMAoEBAICBBIG
kgIClAIFGiAgVGhlIGRlZmF1bHQgcHJvY2Vzc29yIHZlcnNpb24uCgoNCgUEAgIEBRIEkgIC
CAoNCgUEAgIEARIEkgIJIgoNCgUEAgIEAxIEkgIlJgoPCgUEAgIECBIGkgInlAIEChEKBwQC
AgQInwgSBpICKJQCAwo9CgQEAgIFEgaXAgKYAjIaLSBPdXRwdXQgb25seS4gVGhlIHByb2Nl
c3NvciB2ZXJzaW9uIGFsaWFzZXMuCgoNCgUEAgIFBBIElwICCgoNCgUEAgIFBhIElwILIAoN
CgUEAgIFARIElwIhOgoNCgUEAgIFAxIElwI9PwoNCgUEAgIFCBIEmAIGMQoQCggEAgIFCJwI
ABIEmAIHMAplCgQEAgIGEgacAgKfAgQaVSBPdXRwdXQgb25seS4gSW1tdXRhYmxlLiBUaGUg
aHR0cCBlbmRwb2ludCB0aGF0IGNhbiBiZSBjYWxsZWQgdG8gaW52b2tlCiBwcm9jZXNzaW5n
LgoKDQoFBAICBgUSBJwCAggKDQoFBAICBgESBJwCCRkKDQoFBAICBgMSBJwCHB0KDwoFBAIC
BggSBpwCHp8CAwoQCggEAgIGCJwIABIEnQIELQoQCggEAgIGCJwIARIEngIEKwpCCgQEAgIH
EgaiAgKjAjIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIHByb2Nlc3NvciB3YXMgY3Jl
YXRlZC4KCg0KBQQCAgcGEgSiAgIbCg0KBQQCAgcBEgSiAhwnCg0KBQQCAgcDEgSiAiorCg0K
BQQCAgcIEgSjAgYxChAKCAQCAgcInAgAEgSjAgcwCoYBCgQEAgIIEgSnAgIaGnggVGhlIFtL
TVMga2V5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc2VjdXJpdHkta2V5LW1hbmFnZW1l
bnQpIHVzZWQgZm9yCiBlbmNyeXB0aW9uIGFuZCBkZWNyeXB0aW9uIGluIENNRUsgc2NlbmFy
aW9zLgoKDQoFBAICCAUSBKcCAggKDQoFBAICCAESBKcCCRUKDQoFBAICCAMSBKcCGBkKNQoE
BAICCRIEqgICRhonIE91dHB1dCBvbmx5LiBSZXNlcnZlZCBmb3IgZnV0dXJlIHVzZS4KCg0K
BQQCAgkFEgSqAgIGCg0KBQQCAgkBEgSqAgcUCg0KBQQCAgkDEgSqAhcZCg0KBQQCAgkIEgSq
AhpFChAKCAQCAgkInAgAEgSqAhtECjUKBAQCAgoSBK0CAkYaJyBPdXRwdXQgb25seS4gUmVz
ZXJ2ZWQgZm9yIGZ1dHVyZSB1c2UuCgoNCgUEAgIKBRIErQICBgoNCgUEAgIKARIErQIHFAoN
CgUEAgIKAxIErQIXGQoNCgUEAgIKCBIErQIaRQoQCggEAgIKCJwIABIErQIbRAozCgIEAxIG
sQIAxAIBGiUgU2V0dGluZ3MgZm9yIGdyb3VuZGluZyBleHRyYWN0aW9ucy4KCgsKAwQDARIE
sQIIGQopCgQEAwQAEgazAgLAAgMaGSBHcm91bmRpbmcgdHlwZSBvcHRpb25zLgoKDQoFBAME
AAESBLMCBxQKNwoGBAMEAAIAEgS1AgQjGicgVGhlIGRlZmF1bHQgdmFsdWUuIEJlaGF2ZXMg
bGlrZSBIQVJELgoKDwoHBAMEAAIAARIEtQIEHgoPCgcEAwQAAgACEgS1AiEiCkUKBgQDBAAC
ARIEuAIEDRo1IFJlcXVpcmVzIGV4YWN0IG1hdGNoIHdpdGggT0NSIHRleHQgZm9yIGV4dHJh
Y3Rpb25zLgoKDwoHBAMEAAIBARIEuAIECAoPCgcEAwQAAgECEgS4AgsMClEKBgQDBAACAhIE
uwIEFBpBIEFsbG93cyBmb3IgbWlub3IgZGlzY3JlcGFuY2llcyBiZXR3ZWVuIExMTSBvdXRw
dXQgYW5kIE9DUiB0ZXh0LgoKDwoHBAMEAAICARIEuwIEDwoPCgcEAwQAAgICEgS7AhITCnYK
BgQDBAACAxIEvwIEFRpmIExMTSBleHRyYWN0aW9ucyBhcmUgdXNlZCB3aXRob3V0IHN0cmlj
dCBPQ1IgbWF0Y2hpbmcuIEJvdW5kaW5nIGJveGVzIG1heQogYmUgYXBwcm94aW1hdGVkIG9y
IGFic2VudC4KCg8KBwQDBAACAwESBL8CBBAKDwoHBAMEAAIDAhIEvwITFAovCgQEAwIAEgTD
AgIjGiEgVGhlIHR5cGUgb2YgZ3JvdW5kaW5nIHRvIGFwcGx5LgoKDQoFBAMCAAYSBMMCAg8K
DQoFBAMCAAESBMMCEB4KDQoFBAMCAAMSBMMCISIKSQoCBAQSBscCAMsCARo7IE92ZXJyaWRl
cyB0byBhcHBseSB3aGVuIGNyZWF0aW5nIGEgbmV3IHByb2Nlc3NvciB2ZXJzaW9uLgoKCwoD
BAQBEgTHAgghCk4KBAQEAgASBskCAsoCLxo+IE9wdGlvbmFsLiBHcm91bmRpbmcgc2V0dGlu
Z3MgdG8gb3ZlcnJpZGUgdGhlIGRlZmF1bHQgdmFsdWVzLgoKDQoFBAQCAAYSBMkCAhMKDQoF
BAQCAAESBMkCFCYKDQoFBAQCAAMSBMkCKSoKDQoFBAQCAAgSBMoCBi4KEAoIBAQCAAicCAAS
BMoCBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersion ===
    # Fields for ProcessorVersion
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: document_schema Type: 11 (.google.cloud.documentai.v1beta3.DocumentSchema)
    # Field: state Type: 14 (.google.cloud.documentai.v1beta3.ProcessorVersion.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: latest_evaluation Type: 11 (.google.cloud.documentai.v1beta3.EvaluationReference)
    # Field: kms_key_name Type: 9 ()
    # Field: kms_key_version_name Type: 9 ()
    # Field: google_managed Type: 8 ()
    # Field: deprecation_info Type: 11 (.google.cloud.documentai.v1beta3.ProcessorVersion.DeprecationInfo)
    # Field: model_type Type: 14 (.google.cloud.documentai.v1beta3.ProcessorVersion.ModelType)
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()
    # Field: gen_ai_model_info Type: 11 (.google.cloud.documentai.v1beta3.ProcessorVersion.GenAiModelInfo)
    # Field: grounding_settings Type: 11 (.google.cloud.documentai.v1beta3.GroundingSettings)

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

# === Message: Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersionAlias ===
    # Fields for ProcessorVersionAlias
    # Field: alias Type: 9 ()
    # Field: processor_version Type: 9 ()

# === Message: Google::Cloud::Documentai::V1beta3::Processor::Processor ===
    # Fields for Processor
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.documentai.v1beta3.Processor.State)
    # Field: default_processor_version Type: 9 ()
    # Field: processor_version_aliases Type: 11 (.google.cloud.documentai.v1beta3.ProcessorVersionAlias)
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

# === Message: Google::Cloud::Documentai::V1beta3::Processor::GroundingSettings ===
    # Fields for GroundingSettings
    # Field: grounding_type Type: 14 (.google.cloud.documentai.v1beta3.GroundingSettings.GroundingType)

# Enum: GroundingSettings::GroundingType
our $GroundingSettings_GROUNDING_TYPE_UNSPECIFIED = 0;
our $GroundingSettings_HARD = 1;
our $GroundingSettings_OCR_RELAXED = 2;
our $GroundingSettings_NO_GROUNDING = 3;

# === Message: Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersionOverrides ===
    # Fields for ProcessorVersionOverrides
    # Field: grounding_settings Type: 11 (.google.cloud.documentai.v1beta3.GroundingSettings)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::Processor - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/processor.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::Processor;

    my $msg = Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersion->new({
        name => $name,
        display_name => $display_name,
        document_schema => $document_schema,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/processor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersion

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

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentSchema::DocumentSchema>)

Output only. The schema of the processor version. Describes the output.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1beta3::ProcessorVersion::State>)

Output only. The state of the processor version.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the processor version was created.

=item * C<< $msg->latest_evaluation() >> / C<< $msg->latest_evaluation($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Evaluation::EvaluationReference>)

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

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersion::DeprecationInfo>)

Output only. If set, information about the eventual deprecation of this
version.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1beta3::ProcessorVersion::ModelType>)

Output only. The model type of this processor version.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->gen_ai_model_info() >> / C<< $msg->gen_ai_model_info($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersion::GenAiModelInfo>)

Output only. Information about Generative AI model-based processor
versions.

=item * C<< $msg->grounding_settings() >> / C<< $msg->grounding_settings($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Processor::GroundingSettings>)

Output only. The grounding settings of the processor version. This can only
be set using TrainProcessorVersionRequest to override the default grounding
settings.

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

=head2 Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersionAlias

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

=head2 Google::Cloud::Documentai::V1beta3::Processor::Processor

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
[FetchProcessorTypes][google.cloud.documentai.v1beta3.DocumentProcessorService.FetchProcessorTypes].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the processor.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1beta3::Processor::State>)

Output only. The state of the processor.

=item * C<< $msg->default_processor_version() >> / C<< $msg->default_processor_version($value) >>

Type: C<String>

The default processor version.

=item * C<< $msg->processor_version_aliases() >> / C<< $msg->processor_version_aliases($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersionAlias>)

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

=head2 Google::Cloud::Documentai::V1beta3::Processor::GroundingSettings

Settings for grounding extractions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grounding_type() >> / C<< $msg->grounding_type($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1beta3::GroundingSettings::GroundingType>)

The type of grounding to apply.

=back

=head3 Enum: GroundingSettings::GroundingType

=over 4

=item * C<GROUNDING_TYPE_UNSPECIFIED> => C<0>

=item * C<HARD> => C<1>

=item * C<OCR_RELAXED> => C<2>

=item * C<NO_GROUNDING> => C<3>

=back

=head2 Google::Cloud::Documentai::V1beta3::Processor::ProcessorVersionOverrides

Overrides to apply when creating a new processor version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grounding_settings() >> / C<< $msg->grounding_settings($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Processor::GroundingSettings>)

Optional. Grounding settings to override the default values.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::Processor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
