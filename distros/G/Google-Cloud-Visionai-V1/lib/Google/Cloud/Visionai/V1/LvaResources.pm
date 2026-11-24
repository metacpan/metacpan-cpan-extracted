package Google::Cloud::Visionai::V1::LvaResources;

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
    eval { require Google::Cloud::Visionai::V1::Lva };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvbHZhX3Jlc291cmNlcy5wcm90bxIYZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiJnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvbHZh
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIowECghPcGVyYXRvchIS
CgRuYW1lGAEgASgJUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkYKBmxhYmVscxgE
IAMoCzIuLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5PcGVyYXRvci5MYWJlbHNFbnRyeVIG
bGFiZWxzEl0KE29wZXJhdG9yX2RlZmluaXRpb24YBSABKAsyLC5nb29nbGUuY2xvdWQudmlz
aW9uYWkudjEuT3BlcmF0b3JEZWZpbml0aW9uUhJvcGVyYXRvckRlZmluaXRpb24SIQoMZG9j
a2VyX2ltYWdlGAYgASgJUgtkb2NrZXJJbWFnZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOmPqQWAKIHZpc2lvbmFpLmdvb2ds
ZWFwaXMuY29tL09wZXJhdG9yEjxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vb3BlcmF0b3JzL3tvcGVyYXRvcn0ioQcKCEFuYWx5c2lzEhIKBG5hbWUYASABKAlS
BG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSRgoGbGFiZWxzGAQgAygLMi4uZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxLkFuYWx5c2lzLkxhYmVsc0VudHJ5UgZsYWJlbHMSXQoTYW5h
bHlzaXNfZGVmaW5pdGlvbhgFIAEoCzIsLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5BbmFs
eXNpc0RlZmluaXRpb25SEmFuYWx5c2lzRGVmaW5pdGlvbhJvChVpbnB1dF9zdHJlYW1zX21h
cHBpbmcYBiADKAsyOy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuQW5hbHlzaXMuSW5wdXRT
dHJlYW1zTWFwcGluZ0VudHJ5UhNpbnB1dFN0cmVhbXNNYXBwaW5nEnIKFm91dHB1dF9zdHJl
YW1zX21hcHBpbmcYByADKAsyPC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuQW5hbHlzaXMu
T3V0cHV0U3RyZWFtc01hcHBpbmdFbnRyeVIUb3V0cHV0U3RyZWFtc01hcHBpbmcSLgoTZGlz
YWJsZV9ldmVudF93YXRjaBgIIAEoCFIRZGlzYWJsZUV2ZW50V2F0Y2gaOQoLTGFiZWxzRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARpGChhJbnB1
dFN0cmVhbXNNYXBwaW5nRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ARpHChlPdXRwdXRTdHJlYW1zTWFwcGluZ0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6depBcgogdmlzaW9uYWkuZ29vZ2xlYXBp
cy5jb20vQW5hbHlzaXMSTnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jbHVzdGVycy97Y2x1c3Rlcn0vYW5hbHlzZXMve2FuYWx5c2lzfSKFBQoHUHJvY2VzcxIS
CgRuYW1lGAEgASgJUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkQKCGFuYWx5c2lz
GAQgASgJQijgQQL6QSIKIHZpc2lvbmFpLmdvb2dsZWFwaXMuY29tL0FuYWx5c2lzUghhbmFs
eXNpcxI0ChNhdHRyaWJ1dGVfb3ZlcnJpZGVzGAUgAygJQgPgQQFSEmF0dHJpYnV0ZU92ZXJy
aWRlcxJHCgpydW5fc3RhdHVzGAYgASgLMiMuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLlJ1
blN0YXR1c0ID4EEBUglydW5TdGF0dXMSQQoIcnVuX21vZGUYByABKA4yIS5nb29nbGUuY2xv
dWQudmlzaW9uYWkudjEuUnVuTW9kZUID4EEBUgdydW5Nb2RlEh4KCGV2ZW50X2lkGAggASgJ
QgPgQQFSB2V2ZW50SWQSHgoIYmF0Y2hfaWQYCSABKAlCA+BBAVIHYmF0Y2hJZBIkCgtyZXRy
eV9jb3VudBgKIAEoBUID4EEBUgpyZXRyeUNvdW50OnTqQXEKH3Zpc2lvbmFpLmdvb2dsZWFw
aXMuY29tL1Byb2Nlc3MSTnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jbHVzdGVycy97Y2x1c3Rlcn0vcHJvY2Vzc2VzL3twcm9jZXNzfULBAQocY29tLmdvb2ds
ZS5jbG91ZC52aXNpb25haS52MUIRTHZhUmVzb3VyY2VzUHJvdG9QAVo4Y2xvdWQuZ29vZ2xl
LmNvbS9nby92aXNpb25haS9hcGl2MS92aXNpb25haXBiO3Zpc2lvbmFpcGKqAhhHb29nbGUu
Q2xvdWQuVmlzaW9uQUkuVjHKAhhHb29nbGVcQ2xvdWRcVmlzaW9uQUlcVjHqAhtHb29nbGU6
OkNsb3VkOjpWaXNpb25BSTo6VjFKpyUKBxIFDgCYAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMU
ACwKCQoCAwMSAxUAKQoICgEIEgMXADUKCQoCCCUSAxcANQoICgEIEgMYAE8KCQoCCAsSAxgA
TwoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADIKCQoCCAgSAxoAMgoICgEIEgMbADUK
CQoCCAESAxsANQoICgEIEgMcADUKCQoCCCkSAxwANQoICgEIEgMdADQKCQoCCC0SAx0ANAo1
CgIEABIEIAA5ARopIE1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgT3BlcmF0b3Igb2JqZWN0LgoK
CgoDBAABEgMgCBAKCwoDBAAHEgQhAiQECg0KBQQAB50IEgQhAiQECiQKBAQAAgASAycCEhoX
IE5hbWUgb2YgdGhlIHJlc291cmNlLgoKDAoFBAACAAUSAycCCAoMCgUEAAIAARIDJwkNCgwK
BQQAAgADEgMnEBEKMgoEBAACARIEKgIrMhokIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRlIHRp
bWVzdGFtcC4KCgwKBQQAAgEGEgMqAhsKDAoFBAACAQESAyocJwoMCgUEAAIBAxIDKiorCgwK
BQQAAgEIEgMrBjEKDwoIBAACAQicCAASAysHMAoyCgQEAAICEgQuAi8yGiQgT3V0cHV0IG9u
bHkuIFRoZSB1cGRhdGUgdGltZXN0YW1wLgoKDAoFBAACAgYSAy4CGwoMCgUEAAICARIDLhwn
CgwKBQQAAgIDEgMuKisKDAoFBAACAggSAy8GMQoPCggEAAICCJwIABIDLwcwCikKBAQAAgMS
AzICIRocIExhYmVscyBhcyBrZXkgdmFsdWUgcGFpcnMuCgoMCgUEAAIDBhIDMgIVCgwKBQQA
AgMBEgMyFhwKDAoFBAACAwMSAzIfIAouCgQEAAIEEgM1Ai0aISBUaGUgZGVmaW5pdGlvbiBv
ZiB0aGUgb3BlcmF0b3IuCgoMCgUEAAIEBhIDNQIUCgwKBQQAAgQBEgM1FSgKDAoFBAACBAMS
AzUrLAo8CgQEAAIFEgM4AhoaLyBUaGUgbGluayB0byB0aGUgZG9ja2VyIGltYWdlIG9mIHRo
ZSBvcGVyYXRvci4KCgwKBQQAAgUFEgM4AggKDAoFBAACBQESAzgJFQoMCgUEAAIFAxIDOBgZ
CjUKAgQBEgQ8AGQBGikgTWVzc2FnZSBkZXNjcmliaW5nIHRoZSBBbmFseXNpcyBvYmplY3Qu
CgoKCgMEAQESAzwIEAoLCgMEAQcSBD0CQAQKDQoFBAEHnQgSBD0CQAQKJAoEBAECABIDQwIS
GhcgVGhlIG5hbWUgb2YgcmVzb3VyY2UuCgoMCgUEAQIABRIDQwIICgwKBQQBAgABEgNDCQ0K
DAoFBAECAAMSA0MQEQoyCgQEAQIBEgRGAkcyGiQgT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGUg
dGltZXN0YW1wLgoKDAoFBAECAQYSA0YCGwoMCgUEAQIBARIDRhwnCgwKBQQBAgEDEgNGKisK
DAoFBAECAQgSA0cGMQoPCggEAQIBCJwIABIDRwcwCjIKBAQBAgISBEoCSzIaJCBPdXRwdXQg
b25seS4gVGhlIHVwZGF0ZSB0aW1lc3RhbXAuCgoMCgUEAQICBhIDSgIbCgwKBQQBAgIBEgNK
HCcKDAoFBAECAgMSA0oqKwoMCgUEAQICCBIDSwYxCg8KCAQBAgIInAgAEgNLBzAKKQoEBAEC
AxIDTgIhGhwgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycy4KCgwKBQQBAgMGEgNOAhUKDAoF
BAECAwESA04WHAoMCgUEAQIDAxIDTh8gCi4KBAQBAgQSA1ECLRohIFRoZSBkZWZpbml0aW9u
IG9mIHRoZSBhbmFseXNpcy4KCgwKBQQBAgQGEgNRAhQKDAoFBAECBAESA1EVKAoMCgUEAQIE
AxIDUSssCoQCCgQEAQIFEgNXAjAa9gEgTWFwIGZyb20gdGhlIGlucHV0IHBhcmFtZXRlciBp
biB0aGUgZGVmaW5pdGlvbiB0byB0aGUgcmVhbCBzdHJlYW0uCiBFLmcuLCBzdXBwb3NlIHlv
dSBoYWQgYSBzdHJlYW0gc291cmNlIG9wZXJhdG9yIG5hbWVkICJpbnB1dC0wIiBhbmQgeW91
IHRyeQogdG8gcmVjZWl2ZSBmcm9tIHRoZSByZWFsIHN0cmVhbSAic3RyZWFtLTAiLiBZb3Ug
Y2FuIGFkZCB0aGUgZm9sbG93aW5nCiBtYXBwaW5nOiBbaW5wdXQtMDogc3RyZWFtLTBdLgoK
DAoFBAECBQYSA1cCFQoMCgUEAQIFARIDVxYrCgwKBQQBAgUDEgNXLi8KgAIKBAQBAgYSA10C
MRryASBNYXAgZnJvbSB0aGUgb3V0cHV0IHBhcmFtZXRlciBpbiB0aGUgZGVmaW5pdGlvbiB0
byB0aGUgcmVhbCBzdHJlYW0uCiBFLmcuLCBzdXBwb3NlIHlvdSBoYWQgYSBzdHJlYW0gc2lu
ayBvcGVyYXRvciBuYW1lZCAib3V0cHV0LTAiIGFuZCB5b3UgdHJ5CiB0byBzZW5kIHRvIHRo
ZSByZWFsIHN0cmVhbSAic3RyZWFtLTAiLiBZb3UgY2FuIGFkZCB0aGUgZm9sbG93aW5nCiBt
YXBwaW5nOiBbb3V0cHV0LTA6IHN0cmVhbS0wXS4KCgwKBQQBAgYGEgNdAhUKDAoFBAECBgES
A10WLAoMCgUEAQIGAxIDXS8wCvoBCgQEAQIHEgNjAh8a7AEgQm9vbGVhbiBmbGFnIHRvIGlu
ZGljYXRlIHdoZXRoZXIgeW91IHdvdWxkIGxpa2UgdG8gZGlzYWJsZSB0aGUgYWJpbGl0eQog
dG8gYXV0b21hdGljYWxseSBzdGFydCBhIFByb2Nlc3Mgd2hlbiBuZXcgZXZlbnQgaGFwcGVu
aW5nIGluIHRoZSBpbnB1dAogU3RyZWFtLiBJZiB5b3Ugd291bGQgbGlrZSB0byBzdGFydCBh
IFByb2Nlc3MgbWFudWFsbHksIHRoZSBmaWVsZCBuZWVkcwogdG8gYmUgc2V0IHRvIHRydWUu
CgoMCgUEAQIHBRIDYwIGCgwKBQQBAgcBEgNjBxoKDAoFBAECBwMSA2MdHgo1CgIEAhIFZwCY
AQEaKCBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIFByb2Nlc3Mgb2JqZWN0LgoKCgoDBAIBEgNn
CA8KCwoDBAIHEgRoAmsECg0KBQQCB50IEgRoAmsECiQKBAQCAgASA24CEhoXIFRoZSBuYW1l
IG9mIHJlc291cmNlLgoKDAoFBAICAAUSA24CCAoMCgUEAgIAARIDbgkNCgwKBQQCAgADEgNu
EBEKMgoEBAICARIEcQJyMhokIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRlIHRpbWVzdGFtcC4K
CgwKBQQCAgEGEgNxAhsKDAoFBAICAQESA3EcJwoMCgUEAgIBAxIDcSorCgwKBQQCAgEIEgNy
BjEKDwoIBAICAQicCAASA3IHMAoyCgQEAgICEgR1AnYyGiQgT3V0cHV0IG9ubHkuIFRoZSB1
cGRhdGUgdGltZXN0YW1wLgoKDAoFBAICAgYSA3UCGwoMCgUEAgICARIDdRwnCgwKBQQCAgID
EgN1KisKDAoFBAICAggSA3YGMQoPCggEAgICCJwIABIDdgcwCkUKBAQCAgMSBHkCfgQaNyBS
ZXF1aXJlZC4gUmVmZXJlbmNlIHRvIGFuIGV4aXN0aW5nIEFuYWx5c2lzIHJlc291cmNlLgoK
DAoFBAICAwUSA3kCCAoMCgUEAgIDARIDeQkRCgwKBQQCAgMDEgN5FBUKDQoFBAICAwgSBHkW
fgMKDwoIBAICAwicCAASA3oEKgoPCgcEAgIDCJ8IEgR7BH0FCpQBCgQEAgIEEgaDAQKEAS8a
gwEgT3B0aW9uYWwuIEF0dHJpYnV0ZSBvdmVycmlkZXMgb2YgdGhlIEFuYWx5emVycy4KIEZv
cm1hdCBmb3IgZWFjaCBzaW5nbGUgb3ZlcnJpZGUgaXRlbToKICJ7YW5hbHl6ZXJfbmFtZX06
e2F0dHJpYnV0ZV9rZXl9PXt2YWx1ZX0iCgoNCgUEAgIEBBIEgwECCgoNCgUEAgIEBRIEgwEL
EQoNCgUEAgIEARIEgwESJQoNCgUEAgIEAxIEgwEoKQoNCgUEAgIECBIEhAEGLgoQCggEAgIE
CJwIABIEhAEHLQowCgQEAgIFEgSHAQJEGiIgT3B0aW9uYWwuIFN0YXR1cyBvZiB0aGUgUHJv
Y2Vzcy4KCg0KBQQCAgUGEgSHAQILCg0KBQQCAgUBEgSHAQwWCg0KBQQCAgUDEgSHARkaCg0K
BQQCAgUIEgSHARtDChAKCAQCAgUInAgAEgSHARxCCjIKBAQCAgYSBIoBAkAaJCBPcHRpb25h
bC4gUnVuIG1vZGUgb2YgdGhlIFByb2Nlc3MuCgoNCgUEAgIGBhIEigECCQoNCgUEAgIGARIE
igEKEgoNCgUEAgIGAxIEigEVFgoNCgUEAgIGCBIEigEXPwoQCggEAgIGCJwIABIEigEYPgrV
AQoEBAICBxIEjwECPxrGASBPcHRpb25hbC4gRXZlbnQgSUQgb2YgdGhlIGlucHV0L291dHB1
dCBzdHJlYW1zLgogVGhpcyBpcyB1c2VmdWwgd2hlbiB5b3UgaGF2ZSBhIFN0cmVhbVNvdXJj
ZS9TdHJlYW1TaW5rIG9wZXJhdG9yIGluIHRoZQogQW5hbHlzaXMsIGFuZCB5b3Ugd2FudCB0
byBtYW51YWxseSBzcGVjaWZ5IHRoZSBFdmVudCB0byByZWFkIGZyb20vd3JpdGUgdG8uCgoN
CgUEAgIHBRIEjwECCAoNCgUEAgIHARIEjwEJEQoNCgUEAgIHAxIEjwEUFQoNCgUEAgIHCBIE
jwEWPgoQCggEAgIHCJwIABIEjwEXPQo8CgQEAgIIEgSSAQI/Gi4gT3B0aW9uYWwuIE9wdGlv
bmFsOiBCYXRjaCBJRCBvZiB0aGUgUHJvY2Vzcy4KCg0KBQQCAggFEgSSAQIICg0KBQQCAggB
EgSSAQkRCg0KBQQCAggDEgSSARQVCg0KBQQCAggIEgSSARY+ChAKCAQCAggInAgAEgSSARc9
CrUBCgQEAgIJEgSXAQJCGqYBIE9wdGlvbmFsLiBPcHRpb25hbDogVGhlIG51bWJlciBvZiBy
ZXRyaWVzIGZvciBhIHByb2Nlc3MgaW4gc3VibWlzc2lvbiBtb2RlCiB0aGUgc3lzdGVtIHNo
b3VsZCB0cnkgYmVmb3JlIGRlY2xhcmluZyBmYWlsdXJlLiBCeSBkZWZhdWx0LCBubyByZXRy
eSB3aWxsCiBiZSBwZXJmb3JtZWQuCgoNCgUEAgIJBRIElwECBwoNCgUEAgIJARIElwEIEwoN
CgUEAgIJAxIElwEWGAoNCgUEAgIJCBIElwEZQQoQCggEAgIJCJwIABIElwEaQGIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::LvaResources::Operator ===
    # Fields for Operator
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Operator.LabelsEntry)
    # Field: operator_definition Type: 11 (.google.cloud.visionai.v1.OperatorDefinition)
    # Field: docker_image Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::LvaResources::Analysis ===
    # Fields for Analysis
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Analysis.LabelsEntry)
    # Field: analysis_definition Type: 11 (.google.cloud.visionai.v1.AnalysisDefinition)
    # Field: input_streams_mapping Type: 11 (.google.cloud.visionai.v1.Analysis.InputStreamsMappingEntry)
    # Field: output_streams_mapping Type: 11 (.google.cloud.visionai.v1.Analysis.OutputStreamsMappingEntry)
    # Field: disable_event_watch Type: 8 ()

# === Message: Google::Cloud::Visionai::V1::LvaResources::Process ===
    # Fields for Process
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: analysis Type: 9 ()
    # Field: attribute_overrides Type: 9 ()
    # Field: run_status Type: 11 (.google.cloud.visionai.v1.RunStatus)
    # Field: run_mode Type: 14 (.google.cloud.visionai.v1.RunMode)
    # Field: event_id Type: 9 ()
    # Field: batch_id Type: 9 ()
    # Field: retry_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::LvaResources - Compiled Protocol Buffers messages for google/cloud/visionai/v1/lva_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::LvaResources;

    my $msg = Google::Cloud::Visionai::V1::LvaResources::Operator->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::LvaResources::Operator->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/lva_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::LvaResources::Operator

Message describing the Operator object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::LvaResources::Operator::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->operator_definition() >> / C<< $msg->operator_definition($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::OperatorDefinition>)

The definition of the operator.

=item * C<< $msg->docker_image() >> / C<< $msg->docker_image($value) >>

Type: C<String>

The link to the docker image of the operator.

=back

=head2 Google::Cloud::Visionai::V1::LvaResources::Analysis

Message describing the Analysis object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::LvaResources::Analysis::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->analysis_definition() >> / C<< $msg->analysis_definition($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::AnalysisDefinition>)

The definition of the analysis.

=item * C<< $msg->input_streams_mapping() >> / C<< $msg->input_streams_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::LvaResources::Analysis::InputStreamsMappingEntry>)

Map from the input parameter in the definition to the real stream.
E.g., suppose you had a stream source operator named "input-0" and you try
to receive from the real stream "stream-0". You can add the following
mapping: [input-0: stream-0].

=item * C<< $msg->output_streams_mapping() >> / C<< $msg->output_streams_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::LvaResources::Analysis::OutputStreamsMappingEntry>)

Map from the output parameter in the definition to the real stream.
E.g., suppose you had a stream sink operator named "output-0" and you try
to send to the real stream "stream-0". You can add the following
mapping: [output-0: stream-0].

=item * C<< $msg->disable_event_watch() >> / C<< $msg->disable_event_watch($value) >>

Type: C<Bool>

Boolean flag to indicate whether you would like to disable the ability
to automatically start a Process when new event happening in the input
Stream. If you would like to start a Process manually, the field needs
to be set to true.

=back

=head2 Google::Cloud::Visionai::V1::LvaResources::Process

Message describing the Process object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->analysis() >> / C<< $msg->analysis($value) >>

Type: C<String>

Required. Reference to an existing Analysis resource.

=item * C<< $msg->attribute_overrides() >> / C<< $msg->attribute_overrides($value) >>

Type: C<String>

Optional. Attribute overrides of the Analyzers.
Format for each single override item:
"{analyzer_name}:{attribute_key}={value}"

=item * C<< $msg->run_status() >> / C<< $msg->run_status($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::RunStatus>)

Optional. Status of the Process.

=item * C<< $msg->run_mode() >> / C<< $msg->run_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1::RunMode>)

Optional. Run mode of the Process.

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

Optional. Event ID of the input/output streams.
This is useful when you have a StreamSource/StreamSink operator in the
Analysis, and you want to manually specify the Event to read from/write to.

=item * C<< $msg->batch_id() >> / C<< $msg->batch_id($value) >>

Type: C<String>

Optional. Optional: Batch ID of the Process.

=item * C<< $msg->retry_count() >> / C<< $msg->retry_count($value) >>

Type: C<Int32>

Optional. Optional: The number of retries for a process in submission mode
the system should try before declaring failure. By default, no retry will
be performed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::LvaResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
