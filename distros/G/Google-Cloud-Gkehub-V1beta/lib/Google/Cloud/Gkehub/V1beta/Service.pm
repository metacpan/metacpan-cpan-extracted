package Google::Cloud::Gkehub::V1beta::Service;

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
    eval { require Google::Cloud::Gkehub::V1beta::Feature };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZ2tlaHViL3YxYmV0YS9zZXJ2aWNlLnByb3RvEhpnb29nbGUuY2xv
dWQuZ2tlaHViLnYxYmV0YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aKGdv
b2dsZS9jbG91ZC9na2VodWIvdjFiZXRhL2ZlYXR1cmUucHJvdG8aI2dvb2dsZS9sb25ncnVu
bmluZy9vcGVyYXRpb25zLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKcAQoTTGlzdEZlYXR1cmVzUmVx
dWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VT
aXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZp
bHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSKBAQoUTGlzdEZlYXR1cmVzUmVzcG9u
c2USQQoJcmVzb3VyY2VzGAEgAygLMiMuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWJldGEuRmVh
dHVyZVIJcmVzb3VyY2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
biInChFHZXRGZWF0dXJlUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lIrIBChRDcmVhdGVG
ZWF0dXJlUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIdCgpmZWF0dXJlX2lkGAIg
ASgJUglmZWF0dXJlSWQSPwoIcmVzb3VyY2UYAyABKAsyIy5nb29nbGUuY2xvdWQuZ2tlaHVi
LnYxYmV0YS5GZWF0dXJlUghyZXNvdXJjZRIiCgpyZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJl
cXVlc3RJZCJkChREZWxldGVGZWF0dXJlUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEhQK
BWZvcmNlGAIgASgIUgVmb3JjZRIiCgpyZXF1ZXN0X2lkGAMgASgJQgPgQQFSCXJlcXVlc3RJ
ZCLMAQoUVXBkYXRlRmVhdHVyZVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRI7Cgt1cGRh
dGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sS
PwoIcmVzb3VyY2UYAyABKAsyIy5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0YS5GZWF0dXJl
UghyZXNvdXJjZRIiCgpyZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJlcXVlc3RJZCLHAgoRT3Bl
cmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNS
BnRhcmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKAoNc3RhdHVzX2RldGFpbBgFIAEo
CUID4EEDUgxzdGF0dXNEZXRhaWwSLgoQY2FuY2VsX3JlcXVlc3RlZBgGIAEoCEID4EEDUg9j
YW5jZWxSZXF1ZXN0ZWQSJAoLYXBpX3ZlcnNpb24YByABKAlCA+BBA1IKYXBpVmVyc2lvbjLE
CAoGR2tlSHViErQBCgxMaXN0RmVhdHVyZXMSLy5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0
YS5MaXN0RmVhdHVyZXNSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWJldGEuTGlz
dEZlYXR1cmVzUmVzcG9uc2UiQYLT5JMCMhIwL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyp9L2ZlYXR1cmVz2kEGcGFyZW50EqEBCgpHZXRGZWF0dXJlEi0uZ29vZ2xl
LmNsb3VkLmdrZWh1Yi52MWJldGEuR2V0RmVhdHVyZVJlcXVlc3QaIy5nb29nbGUuY2xvdWQu
Z2tlaHViLnYxYmV0YS5GZWF0dXJlIj+C0+STAjISMC92MWJldGEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9mZWF0dXJlcy8qfdpBBG5hbWUS4AEKDUNyZWF0ZUZlYXR1cmUSMC5n
b29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0YS5DcmVhdGVGZWF0dXJlUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24ifoLT5JMCPCIwL3YxYmV0YS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyp9L2ZlYXR1cmVzOghyZXNvdXJjZdpBGnBhcmVudCxyZXNvdXJj
ZSxmZWF0dXJlX2lkykEcCgdGZWF0dXJlEhFPcGVyYXRpb25NZXRhZGF0YRLOAQoNRGVsZXRl
RmVhdHVyZRIwLmdvb2dsZS5jbG91ZC5na2VodWIudjFiZXRhLkRlbGV0ZUZlYXR1cmVSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJsgtPkkwIyKjAvdjFiZXRhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZmVhdHVyZXMvKn3aQQRuYW1lykEqChVnb29n
bGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEt8BCg1VcGRhdGVGZWF0dXJl
EjAuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWJldGEuVXBkYXRlRmVhdHVyZVJlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn2C0+STAjwyMC92MWJldGEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9mZWF0dXJlcy8qfToIcmVzb3VyY2XaQRluYW1lLHJlc291
cmNlLHVwZGF0ZV9tYXNrykEcCgdGZWF0dXJlEhFPcGVyYXRpb25NZXRhZGF0YRpJykEVZ2tl
aHViLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybULCAQoeY29tLmdvb2dsZS5jbG91ZC5na2VodWIudjFiZXRhQgxTZXJ2
aWNlUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9na2VodWIvYXBpdjFiZXRhL2drZWh1
YnBiO2drZWh1YnBiqgIaR29vZ2xlLkNsb3VkLkdrZUh1Yi5WMUJldGHKAhpHb29nbGVcQ2xv
dWRcR2tlSHViXFYxYmV0YeoCHUdvb2dsZTo6Q2xvdWQ6OkdrZUh1Yjo6VjFiZXRhSv9NCgcS
BQ4AlwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkK
AgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVADIKCQoCAwQSAxYALQoJ
CgIDBRIDFwAqCgkKAgMGEgMYACkKCAoBCBIDGgA3CgkKAgglEgMaADcKCAoBCBIDGwBNCgkK
AggLEgMbAE0KCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQAtCgkKAggIEgMdAC0KCAoB
CBIDHgA3CgkKAggBEgMeADcKCAoBCBIDHwA3CgkKAggpEgMfADcKCAoBCBIDIAA2CgkKAggt
EgMgADYKwwQKAgYAEgQwAGkBGrYEIFRoZSBHS0UgSHViIHNlcnZpY2UgaGFuZGxlcyB0aGUg
cmVnaXN0cmF0aW9uIG9mIG1hbnkgS3ViZXJuZXRlcyBjbHVzdGVycyB0bwogR29vZ2xlIENs
b3VkLCBhbmQgdGhlIG1hbmFnZW1lbnQgb2YgbXVsdGktY2x1c3RlciBmZWF0dXJlcyBvdmVy
IHRob3NlCiBjbHVzdGVycy4KCiBUaGUgR0tFIEh1YiBzZXJ2aWNlIG9wZXJhdGVzIG9uIHRo
ZSBmb2xsb3dpbmcgcmVzb3VyY2VzOgoKICogW01lbWJlcnNoaXBdW2dvb2dsZS5jbG91ZC5n
a2VodWIudjFiZXRhLk1lbWJlcnNoaXBdCiAqIFtGZWF0dXJlXVtnb29nbGUuY2xvdWQuZ2tl
aHViLnYxYmV0YS5GZWF0dXJlXQoKIEdLRSBIdWIgaXMgY3VycmVudGx5IG9ubHkgYXZhaWxh
YmxlIGluIHRoZSBnbG9iYWwgcmVnaW9uLgoKICoqTWVtYmVyc2hpcCBtYW5hZ2VtZW50IG1h
eSBiZSBub24tdHJpdmlhbDoqKiBpdCBpcyByZWNvbW1lbmRlZCB0byB1c2Ugb25lCiBvZiB0
aGUgR29vZ2xlLXByb3ZpZGVkIGNsaWVudCBsaWJyYXJpZXMgb3IgdG9vbHMgd2hlcmUgcG9z
c2libGUgd2hlbiB3b3JraW5nCiB3aXRoIE1lbWJlcnNoaXAgcmVzb3VyY2VzLgoKCgoDBgAB
EgMwCA4KCgoDBgADEgMxAj0KDAoFBgADmQgSAzECPQoKCgMGAAMSAzICVgoMCgUGAAOaCBID
MgJWCj8KBAYAAgASBDUCOgMaMSBMaXN0cyBGZWF0dXJlcyBpbiBhIGdpdmVuIHByb2plY3Qg
YW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAzUGEgoMCgUGAAIAAhIDNRMmCgwKBQYAAgADEgM1
MUUKDQoFBgACAAQSBDYEOAYKEQoJBgACAASwyrwiEgQ2BDgGCgwKBQYAAgAEEgM5BDQKDwoI
BgACAASbCAASAzkENAoxCgQGAAIBEgQ9AkIDGiMgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xl
IEZlYXR1cmUuCgoMCgUGAAIBARIDPQYQCgwKBQYAAgECEgM9ESIKDAoFBgACAQMSAz0tNAoN
CgUGAAIBBBIEPgRABgoRCgkGAAIBBLDKvCISBD4EQAYKDAoFBgACAQQSA0EEMgoPCggGAAIB
BJsIABIDQQQyCiMKBAYAAgISBEUCTwMaFSBBZGRzIGEgbmV3IEZlYXR1cmUuCgoMCgUGAAIC
ARIDRQYTCgwKBQYAAgICEgNFFCgKDAoFBgACAgMSA0UzTwoNCgUGAAICBBIERgRJBgoRCgkG
AAICBLDKvCISBEYESQYKDAoFBgACAgQSA0oESAoPCggGAAICBJsIABIDSgRICg0KBQYAAgIE
EgRLBE4GCg8KBwYAAgIEmQgSBEsETgYKIgoEBgACAxIEUgJbAxoUIFJlbW92ZXMgYSBGZWF0
dXJlLgoKDAoFBgACAwESA1IGEwoMCgUGAAIDAhIDUhQoCgwKBQYAAgMDEgNSM08KDQoFBgAC
AwQSBFMEVQYKEQoJBgACAwSwyrwiEgRTBFUGCgwKBQYAAgMEEgNWBDIKDwoIBgACAwSbCAAS
A1YEMgoNCgUGAAIDBBIEVwRaBgoPCgcGAAIDBJkIEgRXBFoGCiwKBAYAAgQSBF4CaAMaHiBV
cGRhdGVzIGFuIGV4aXN0aW5nIEZlYXR1cmUuCgoMCgUGAAIEARIDXgYTCgwKBQYAAgQCEgNe
FCgKDAoFBgACBAMSA14zTwoNCgUGAAIEBBIEXwRiBgoRCgkGAAIEBLDKvCISBF8EYgYKDAoF
BgACBAQSA2MERwoPCggGAAIEBJsIABIDYwRHCg0KBQYAAgQEEgRkBGcGCg8KBwYAAgQEmQgS
BGQEZwYKQAoCBAASBWwAkAEBGjMgUmVxdWVzdCBtZXNzYWdlIGZvciBgR2tlSHViLkxpc3RG
ZWF0dXJlc2AgbWV0aG9kLgoKCgoDBAABEgNsCBsKhgEKBAQAAgASA28CFBp5IFRoZSBwYXJl
bnQgKHByb2plY3QgYW5kIGxvY2F0aW9uKSB3aGVyZSB0aGUgRmVhdHVyZXMgd2lsbCBiZSBs
aXN0ZWQuCiBTcGVjaWZpZWQgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMv
KmAuCgoMCgUEAAIABRIDbwIICgwKBQQAAgABEgNvCQ8KDAoFBAACAAMSA28SEwqpAQoEBAAC
ARIDdAIWGpsBIFdoZW4gcmVxdWVzdGluZyBhICdwYWdlJyBvZiByZXNvdXJjZXMsIGBwYWdl
X3NpemVgIHNwZWNpZmllcyBudW1iZXIgb2YKIHJlc291cmNlcyB0byByZXR1cm4uIElmIHVu
c3BlY2lmaWVkIG9yIHNldCB0byAwLCBhbGwgcmVzb3VyY2VzIHdpbGwKIGJlIHJldHVybmVk
LgoKDAoFBAACAQUSA3QCBwoMCgUEAAIBARIDdAgRCgwKBQQAAgEDEgN0FBUKmgEKBAQAAgIS
A3kCGBqMASBUb2tlbiByZXR1cm5lZCBieSBwcmV2aW91cyBjYWxsIHRvIGBMaXN0RmVhdHVy
ZXNgIHdoaWNoCiBzcGVjaWZpZXMgdGhlIHBvc2l0aW9uIGluIHRoZSBsaXN0IGZyb20gd2hl
cmUgdG8gY29udGludWUgbGlzdGluZyB0aGUKIHJlc291cmNlcy4KCgwKBQQAAgIFEgN5AggK
DAoFBAACAgESA3kJEwoMCgUEAAICAxIDeRYXCrYDCgQEAAIDEgSLAQIUGqcDIExpc3RzIEZl
YXR1cmVzIHRoYXQgbWF0Y2ggdGhlIGZpbHRlciBleHByZXNzaW9uLCBmb2xsb3dpbmcgdGhl
IHN5bnRheAogb3V0bGluZWQgaW4gaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xNjAuCgogRXhh
bXBsZXM6CgogICAtIEZlYXR1cmUgd2l0aCB0aGUgbmFtZSAic2VydmljZW1lc2giIGluIHBy
b2plY3QgImZvby1wcm9qIjoKCiAgICAgICBuYW1lID0gInByb2plY3RzL2Zvby1wcm9qL2xv
Y2F0aW9ucy9nbG9iYWwvZmVhdHVyZXMvc2VydmljZW1lc2giCgogICAtIEZlYXR1cmVzIHRo
YXQgaGF2ZSBhIGxhYmVsIGNhbGxlZCBgZm9vYDoKCiAgICAgICBsYWJlbHMuZm9vOioKCiAg
IC0gRmVhdHVyZXMgdGhhdCBoYXZlIGEgbGFiZWwgY2FsbGVkIGBmb29gIHdob3NlIHZhbHVl
IGlzIGBiYXJgOgoKICAgICAgIGxhYmVscy5mb28gPSBiYXIKCg0KBQQAAgMFEgSLAQIICg0K
BQQAAgMBEgSLAQkPCg0KBQQAAgMDEgSLARITCnMKBAQAAgQSBI8BAhYaZSBPbmUgb3IgbW9y
ZSBmaWVsZHMgdG8gY29tcGFyZSBhbmQgdXNlIHRvIHNvcnQgdGhlIG91dHB1dC4KIFNlZSBo
dHRwczovL2dvb2dsZS5haXAuZGV2LzEzMiNvcmRlcmluZy4KCg0KBQQAAgQFEgSPAQIICg0K
BQQAAgQBEgSPAQkRCg0KBQQAAgQDEgSPARQVCkYKAgQBEgaTAQCbAQEaOCBSZXNwb25zZSBt
ZXNzYWdlIGZvciB0aGUgYEdrZUh1Yi5MaXN0RmVhdHVyZXNgIG1ldGhvZC4KCgsKAwQBARIE
kwEIHAotCgQEAQIAEgSVAQIhGh8gVGhlIGxpc3Qgb2YgbWF0Y2hpbmcgRmVhdHVyZXMKCg0K
BQQBAgAEEgSVAQIKCg0KBQQBAgAGEgSVAQsSCg0KBQQBAgABEgSVARMcCg0KBQQBAgADEgSV
AR8gCq8BCgQEAQIBEgSaAQIdGqABIEEgdG9rZW4gdG8gcmVxdWVzdCB0aGUgbmV4dCBwYWdl
IG9mIHJlc291cmNlcyBmcm9tIHRoZQogYExpc3RGZWF0dXJlc2AgbWV0aG9kLiBUaGUgdmFs
dWUgb2YgYW4gZW1wdHkgc3RyaW5nIG1lYW5zCiB0aGF0IHRoZXJlIGFyZSBubyBtb3JlIHJl
c291cmNlcyB0byByZXR1cm4uCgoNCgUEAQIBBRIEmgECCAoNCgUEAQIBARIEmgEJGAoNCgUE
AQIBAxIEmgEbHAo/CgIEAhIGngEAogEBGjEgUmVxdWVzdCBtZXNzYWdlIGZvciBgR2tlSHVi
LkdldEZlYXR1cmVgIG1ldGhvZC4KCgsKAwQCARIEngEIGQpcCgQEAgIAEgShAQISGk4gVGhl
IEZlYXR1cmUgcmVzb3VyY2UgbmFtZSBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9mZWF0dXJlcy8qYAoKDQoFBAICAAUSBKEBAggKDQoFBAICAAESBKEBCQ0KDQoF
BAICAAMSBKEBEBEKRgoCBAMSBqUBAL4BARo4IFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBH
a2VIdWIuQ3JlYXRlRmVhdHVyZWAgbWV0aG9kLgoKCwoDBAMBEgSlAQgcCocBCgQEAwIAEgSo
AQIUGnkgVGhlIHBhcmVudCAocHJvamVjdCBhbmQgbG9jYXRpb24pIHdoZXJlIHRoZSBGZWF0
dXJlIHdpbGwgYmUgY3JlYXRlZC4KIFNwZWNpZmllZCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0
cy8qL2xvY2F0aW9ucy8qYC4KCg0KBQQDAgAFEgSoAQIICg0KBQQDAgABEgSoAQkPCg0KBQQD
AgADEgSoARITCjAKBAQDAgESBKsBAhgaIiBUaGUgSUQgb2YgdGhlIGZlYXR1cmUgdG8gY3Jl
YXRlLgoKDQoFBAMCAQUSBKsBAggKDQoFBAMCAQESBKsBCRMKDQoFBAMCAQMSBKsBFhcKLwoE
BAMCAhIErgECFxohIFRoZSBGZWF0dXJlIHJlc291cmNlIHRvIGNyZWF0ZS4KCg0KBQQDAgIG
EgSuAQIJCg0KBQQDAgIBEgSuAQoSCg0KBQQDAgIDEgSuARUWCoUGCgQEAwIDEgS9AQJBGvYF
IE9wdGlvbmFsLiBBIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkg
YSB1bmlxdWUgcmVxdWVzdCBJRAogc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJl
cXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvIGlnbm9yZQogdGhlIHJlcXVlc3QgaWYg
aXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbCBndWFyYW50
ZWUKIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVl
c3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtl
IGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRoZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91
IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhl
IHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUg
cmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBz
ZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxs
eSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVz
dCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlz
CiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAp
LgoKDQoFBAMCAwUSBL0BAggKDQoFBAMCAwESBL0BCRMKDQoFBAMCAwMSBL0BFhcKDQoFBAMC
AwgSBL0BGEAKEAoIBAMCAwicCAASBL0BGT8KQgoCBAQSBsEBANkBARo0IFJlcXVlc3QgbWVz
c2FnZSBmb3IgYEdrZUh1Yi5EZWxldGVGZWF0dXJlYCBtZXRob2QuCgoLCgMEBAESBMEBCBwK
XQoEBAQCABIExAECEhpPIFRoZSBGZWF0dXJlIHJlc291cmNlIG5hbWUgaW4gdGhlIGZvcm1h
dAogYHByb2plY3RzLyovbG9jYXRpb25zLyovZmVhdHVyZXMvKmAuCgoNCgUEBAIABRIExAEC
CAoNCgUEBAIAARIExAEJDQoNCgUEBAIAAxIExAEQEQrbAQoEBAQCARIEyQECERrMASBJZiBz
ZXQgdG8gdHJ1ZSwgdGhlIGRlbGV0ZSB3aWxsIGlnbm9yZSBhbnkgb3V0c3RhbmRpbmcgcmVz
b3VyY2VzIGZvcgogdGhpcyBGZWF0dXJlICh0aGF0IGlzLCBgRmVhdHVyZVN0YXRlLmhhc19y
ZXNvdXJjZXNgIGlzIHNldCB0byB0cnVlKS4gVGhlc2UKIHJlc291cmNlcyB3aWxsIE5PVCBi
ZSBjbGVhbmVkIHVwIG9yIG1vZGlmaWVkIGluIGFueSB3YXkuCgoNCgUEBAIBBRIEyQECBgoN
CgUEBAIBARIEyQEHDAoNCgUEBAIBAxIEyQEPEAqFBgoEBAQCAhIE2AECQRr2BSBPcHRpb25h
bC4gQSByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVl
IHJlcXVlc3QgSUQKIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0
aGUgc2VydmVyIHdpbGwga25vdyB0byBpZ25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBh
bHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0aGF0
IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZv
ciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0
aWFsIHJlcXVlc3QgYW5kCiB0aGUgcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRo
ZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIg
Y2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3Qg
SUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJl
cXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRp
bmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2
YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1
cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQE
AgIFEgTYAQIICg0KBQQEAgIBEgTYAQkTCg0KBQQEAgIDEgTYARYXCg0KBQQEAgIIEgTYARhA
ChAKCAQEAgIInAgAEgTYARk/CkIKAgQFEgbcAQD8AQEaNCBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IGBHa2VIdWIuVXBkYXRlRmVhdHVyZWAgbWV0aG9kLgoKCwoDBAUBEgTcAQgcCl0KBAQFAgAS
BN8BAhIaTyBUaGUgRmVhdHVyZSByZXNvdXJjZSBuYW1lIGluIHRoZSBmb3JtYXQKIGBwcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2ZlYXR1cmVzLypgLgoKDQoFBAUCAAUSBN8BAggKDQoFBAUC
AAESBN8BCQ0KDQoFBAUCAAMSBN8BEBEKKQoEBAUCARIE4gECLBobIE1hc2sgb2YgZmllbGRz
IHRvIHVwZGF0ZS4KCg0KBQQFAgEGEgTiAQIbCg0KBQQFAgEBEgTiARwnCg0KBQQFAgEDEgTi
ASorCtcDCgQEBQICEgTsAQIXGsgDIE9ubHkgZmllbGRzIHNwZWNpZmllZCBpbiB1cGRhdGVf
bWFzayBhcmUgdXBkYXRlZC4KIElmIHlvdSBzcGVjaWZ5IGEgZmllbGQgaW4gdGhlIHVwZGF0
ZV9tYXNrIGJ1dCBkb24ndCBzcGVjaWZ5IGl0cyB2YWx1ZSBoZXJlCiB0aGF0IGZpZWxkIHdp
bGwgYmUgZGVsZXRlZC4KIElmIHlvdSBhcmUgdXBkYXRpbmcgYSBtYXAgZmllbGQsIHNldCB0
aGUgdmFsdWUgb2YgYSBrZXkgdG8gbnVsbCBvciBlbXB0eQogc3RyaW5nIHRvIGRlbGV0ZSB0
aGUga2V5IGZyb20gdGhlIG1hcC4gSXQncyBub3QgcG9zc2libGUgdG8gdXBkYXRlIGEga2V5
J3MKIHZhbHVlIHRvIHRoZSBlbXB0eSBzdHJpbmcuCiBJZiB5b3Ugc3BlY2lmeSB0aGUgdXBk
YXRlX21hc2sgdG8gYmUgYSBzcGVjaWFsIHBhdGggIioiLCBmdWxseSByZXBsYWNlcyBhbGwK
IHVzZXItbW9kaWZpYWJsZSBmaWVsZHMgdG8gbWF0Y2ggYHJlc291cmNlYC4KCg0KBQQFAgIG
EgTsAQIJCg0KBQQFAgIBEgTsAQoSCg0KBQQFAgIDEgTsARUWCoUGCgQEBQIDEgT7AQJBGvYF
IE9wdGlvbmFsLiBBIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkg
YSB1bmlxdWUgcmVxdWVzdCBJRAogc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJl
cXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvIGlnbm9yZQogdGhlIHJlcXVlc3QgaWYg
aXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbCBndWFyYW50
ZWUKIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVl
c3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtl
IGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRoZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91
IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhl
IHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUg
cmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBz
ZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxs
eSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVz
dCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlz
CiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAp
LgoKDQoFBAUCAwUSBPsBAggKDQoFBAUCAwESBPsBCRMKDQoFBAUCAwMSBPsBFhcKDQoFBAUC
AwgSBPsBGEAKEAoIBAUCAwicCAASBPsBGT8KRgoCBAYSBv8BAJcCARo4IFJlcHJlc2VudHMg
dGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgoKCwoDBAYBEgT/
AQgZCkAKBAQGAgASBIECAlgaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlv
biB3YXMgY3JlYXRlZC4KCg0KBQQGAgAGEgSBAgIbCg0KBQQGAgABEgSBAhwnCg0KBQQGAgAD
EgSBAiorCg0KBQQGAgAIEgSBAixXChAKCAQGAgAInAgAEgSBAi1WCkUKBAQGAgESBIQCAlUa
NyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5n
LgoKDQoFBAYCAQYSBIQCAhsKDQoFBAYCAQESBIQCHCQKDQoFBAYCAQMSBIQCJygKDQoFBAYC
AQgSBIQCKVQKEAoIBAYCAQicCAASBIQCKlMKWgoEBAYCAhIEhwICQBpMIE91dHB1dCBvbmx5
LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBv
cGVyYXRpb24uCgoNCgUEBgICBRIEhwICCAoNCgUEBgICARIEhwIJDwoNCgUEBgICAxIEhwIS
EwoNCgUEBgICCBIEhwIUPwoQCggEBgICCJwIABIEhwIVPgpICgQEBgIDEgSKAgI+GjogT3V0
cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4K
Cg0KBQQGAgMFEgSKAgIICg0KBQQGAgMBEgSKAgkNCg0KBQQGAgMDEgSKAhARCg0KBQQGAgMI
EgSKAhI9ChAKCAQGAgMInAgAEgSKAhM8CkwKBAQGAgQSBI0CAkcaPiBPdXRwdXQgb25seS4g
SHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCg0KBQQG
AgQFEgSNAgIICg0KBQQGAgQBEgSNAgkWCg0KBQQGAgQDEgSNAhkaCg0KBQQGAgQIEgSNAhtG
ChAKCAQGAgQInAgAEgSNAhxFCpoCCgQEBgIFEgSTAgJIGosCIE91dHB1dCBvbmx5LiBJZGVu
dGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9m
IHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVu
IGNhbmNlbGxlZAogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtdIHZhbHVlIHdpdGggYSBbZ29v
Z2xlLnJwYy5TdGF0dXMuY29kZV1bZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV0gb2YgMSwKIGNv
cnJlc3BvbmRpbmcgdG8gYENvZGUuQ0FOQ0VMTEVEYC4KCg0KBQQGAgUFEgSTAgIGCg0KBQQG
AgUBEgSTAgcXCg0KBQQGAgUDEgSTAhobCg0KBQQGAgUIEgSTAhxHChAKCAQGAgUInAgAEgST
Ah1GCkUKBAQGAgYSBJYCAkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNpb24gdXNlZCB0byBz
dGFydCB0aGUgb3BlcmF0aW9uLgoKDQoFBAYCBgUSBJYCAggKDQoFBAYCBgESBJYCCRQKDQoF
BAYCBgMSBJYCFxgKDQoFBAYCBggSBJYCGUQKEAoIBAYCBgicCAASBJYCGkNiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest ===
    # Fields for ListFeaturesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1beta::Service::ListFeaturesResponse ===
    # Fields for ListFeaturesResponse
    # Field: resources Type: 11 (.google.cloud.gkehub.v1beta.Feature)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1beta::Service::GetFeatureRequest ===
    # Fields for GetFeatureRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1beta::Service::CreateFeatureRequest ===
    # Fields for CreateFeatureRequest
    # Field: parent Type: 9 ()
    # Field: feature_id Type: 9 ()
    # Field: resource Type: 11 (.google.cloud.gkehub.v1beta.Feature)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1beta::Service::DeleteFeatureRequest ===
    # Fields for DeleteFeatureRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1beta::Service::UpdateFeatureRequest ===
    # Fields for UpdateFeatureRequest
    # Field: name Type: 9 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: resource Type: 11 (.google.cloud.gkehub.v1beta.Feature)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1beta::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_detail Type: 9 ()
    # Field: cancel_requested Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Gkehub::V1beta::Service::GkeHubClient ===
package Google::Cloud::Gkehub::V1beta::Service::GkeHubClient;

=pod

=head2 Service Client: Google::Cloud::Gkehub::V1beta::Service::GkeHubClient

Client stub representing the remote C<GkeHub> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<gkehub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'gkehub.googleapis.com:443' );

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

sub list_features {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1beta.GkeHub',
        method         => 'ListFeatures',
        request        => $req,
        response_class => 'Google::Cloud::Gkehub::V1beta::Service::ListFeaturesResponse',
    });
}

sub get_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1beta::Service::GetFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1beta.GkeHub',
        method         => 'GetFeature',
        request        => $req,
        response_class => 'Google::Cloud::Gkehub::V1beta::Feature::Feature',
    });
}

sub create_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1beta::Service::CreateFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1beta.GkeHub',
        method         => 'CreateFeature',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1beta::Service::DeleteFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1beta.GkeHub',
        method         => 'DeleteFeature',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1beta::Service::UpdateFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1beta.GkeHub',
        method         => 'UpdateFeature',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::V1beta::Service - Compiled Protocol Buffers messages for google/cloud/gkehub/v1beta/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::V1beta::Service;

    my $msg = Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1beta/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest

Request message for `GkeHub.ListFeatures` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The parent (project and location) where the Features will be listed.
Specified in the format `projects/*/locations/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

When requesting a 'page' of resources, `page_size` specifies number of
resources to return. If unspecified or set to 0, all resources will
be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Token returned by previous call to `ListFeatures` which
specifies the position in the list from where to continue listing the
resources.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Lists Features that match the filter expression, following the syntax
outlined in https://google.aip.dev/160.

Examples:

  - Feature with the name "servicemesh" in project "foo-proj":

      name = "projects/foo-proj/locations/global/features/servicemesh"

  - Features that have a label called `foo`:

      labels.foo:*

  - Features that have a label called `foo` whose value is `bar`:

      labels.foo = bar

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

One or more fields to compare and use to sort the output.
See https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Gkehub::V1beta::Service::ListFeaturesResponse

Response message for the `GkeHub.ListFeatures` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::Feature>)

The list of matching Features

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to request the next page of resources from the
`ListFeatures` method. The value of an empty string means
that there are no more resources to return.

=back

=head2 Google::Cloud::Gkehub::V1beta::Service::GetFeatureRequest

Request message for `GkeHub.GetFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Feature resource name in the format
`projects/*/locations/*/features/*`

=back

=head2 Google::Cloud::Gkehub::V1beta::Service::CreateFeatureRequest

Request message for the `GkeHub.CreateFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The parent (project and location) where the Feature will be created.
Specified in the format `projects/*/locations/*`.

=item * C<< $msg->feature_id() >> / C<< $msg->feature_id($value) >>

Type: C<String>

The ID of the feature to create.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::Feature>)

The Feature resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Gkehub::V1beta::Service::DeleteFeatureRequest

Request message for `GkeHub.DeleteFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Feature resource name in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If set to true, the delete will ignore any outstanding resources for
this Feature (that is, `FeatureState.has_resources` is set to true). These
resources will NOT be cleaned up or modified in any way.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Gkehub::V1beta::Service::UpdateFeatureRequest

Request message for `GkeHub.UpdateFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Feature resource name in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Mask of fields to update.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::Feature>)

Only fields specified in update_mask are updated.
If you specify a field in the update_mask but don't specify its value here
that field will be deleted.
If you are updating a map field, set the value of a key to null or empty
string to delete the key from the map. It's not possible to update a key's
value to the empty string.
If you specify the update_mask to be a special path "*", fully replaces all
user-modifiable fields to match `resource`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Gkehub::V1beta::Service::OperationMetadata

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

=item * C<< $msg->status_detail() >> / C<< $msg->status_detail($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->cancel_requested() >> / C<< $msg->cancel_requested($value) >>

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::V1beta::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
