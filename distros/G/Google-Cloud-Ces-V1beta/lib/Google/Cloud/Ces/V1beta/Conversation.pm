package Google::Cloud::Ces::V1beta::Conversation;

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
    eval { require Google::Cloud::Ces::V1beta::Common };
    eval { require Google::Cloud::Ces::V1beta::Example };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jb252ZXJzYXRpb24ucHJvdG8SF2dvb2dsZS5j
bG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGiRnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jb21tb24u
cHJvdG8aJWdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2V4YW1wbGUucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8ikwwKDENvbnZlcnNhdGlvbhIXCgRuYW1lGAEgASgJ
QgPgQQhSBG5hbWUSPgoKc3RhcnRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IJc3RhcnRUaW1lEjoKCGVuZF90aW1lGAQgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEkUKBXR1cm5zGAYgAygLMiouZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEuQ29udmVyc2F0aW9uLlR1cm5CA+BBAlIFdHVybnMSIgoKdHVybl9j
b3VudBgHIAEoBUID4EEDUgl0dXJuQ291bnQSWAoMY2hhbm5lbF90eXBlGAggASgOMjEuZ29v
Z2xlLmNsb3VkLmNlcy52MWJldGEuQ29udmVyc2F0aW9uLkNoYW5uZWxUeXBlQgIYAVILY2hh
bm5lbFR5cGUSSQoGc291cmNlGAkgASgOMiwuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuQ29u
dmVyc2F0aW9uLlNvdXJjZUID4EEDUgZzb3VyY2USVQoLaW5wdXRfdHlwZXMYCiADKA4yLy5n
b29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Db252ZXJzYXRpb24uSW5wdXRUeXBlQgPgQQNSCmlu
cHV0VHlwZXMSQQoLZW50cnlfYWdlbnQYCyABKAlCIOBBA/pBGgoYY2VzLmdvb2dsZWFwaXMu
Y29tL0FnZW50UgplbnRyeUFnZW50EkUKCmRlcGxveW1lbnQYDCABKAlCJeBBA/pBHwodY2Vz
Lmdvb2dsZWFwaXMuY29tL0RlcGxveW1lbnRSCmRlcGxveW1lbnQSRgoLYXBwX3ZlcnNpb24Y
DSABKAlCJeBBA/pBHwodY2VzLmdvb2dsZWFwaXMuY29tL0FwcFZlcnNpb25SCmFwcFZlcnNp
b24SKAoNbGFuZ3VhZ2VfY29kZRgOIAEoCUID4EEDUgxsYW5ndWFnZUNvZGUSQAoIbWVzc2Fn
ZXMYAiADKAsyIC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5NZXNzYWdlQgIYAVIIbWVzc2Fn
ZXMavQEKBFR1cm4SQQoIbWVzc2FnZXMYASADKAsyIC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0
YS5NZXNzYWdlQgPgQQFSCG1lc3NhZ2VzEj8KCXJvb3Rfc3BhbhgCIAEoCzIdLmdvb2dsZS5j
bG91ZC5jZXMudjFiZXRhLlNwYW5CA+BBAVIIcm9vdFNwYW4SMQoSdXNlcl9pbnRlbmRlZF90
ZXh0GAMgASgJQgPgQQFSEHVzZXJJbnRlbmRlZFRleHQiUAoLQ2hhbm5lbFR5cGUSHAoYQ0hB
Tk5FTF9UWVBFX1VOU1BFQ0lGSUVEEAASCAoEVEVYVBABEgkKBUFVRElPEAISDgoKTVVMVElN
T0RBTBADIlMKBlNvdXJjZRIWChJTT1VSQ0VfVU5TUEVDSUZJRUQQABIICgRMSVZFEAESDQoJ
U0lNVUxBVE9SEAISCAoERVZBTBADEg4KCkFHRU5UX1RPT0wQBCLLAQoJSW5wdXRUeXBlEhoK
FklOUFVUX1RZUEVfVU5TUEVDSUZJRUQQABITCg9JTlBVVF9UWVBFX1RFWFQQARIUChBJTlBV
VF9UWVBFX0VWRU5UEAcSFAoQSU5QVVRfVFlQRV9BVURJTxACEhQKEElOUFVUX1RZUEVfSU1B
R0UQAxITCg9JTlBVVF9UWVBFX0JMT0IQBBIcChhJTlBVVF9UWVBFX1RPT0xfUkVTUE9OU0UQ
BRIYChRJTlBVVF9UWVBFX1ZBUklBQkxFUxAGOpMB6kGPAQofY2VzLmdvb2dsZWFwaXMuY29t
L0NvbnZlcnNhdGlvbhJPcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2FwcHMve2FwcH0vY29udmVyc2F0aW9ucy97Y29udmVyc2F0aW9ufSoNY29udmVyc2F0aW9u
czIMY29udmVyc2F0aW9uQmEKG2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YUIRQ29udmVy
c2F0aW9uUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3Bi
O2Nlc3BiSuEtCgcSBQ4ArwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAuCgkKAgMDEgMVAC8K
CQoCAwQSAxYAKQoICgEIEgMYAEQKCQoCCAsSAxgARAoICgEIEgMZACIKCQoCCAoSAxkAIgoI
CgEIEgMaADIKCQoCCAgSAxoAMgoICgEIEgMbADQKCQoCCAESAxsANApcCgIEABIFHgCvAQEa
TyBBIGNvbnZlcnNhdGlvbiByZXByZXNlbnRzIGFuIGludGVyYWN0aW9uIGJldHdlZW4gYW4g
ZW5kIHVzZXIgYW5kIHRoZSBDRVMgYXBwLgoKCgoDBAABEgMeCBQKCwoDBAAHEgQfAiQECg0K
BQQAB50IEgQfAiQECkgKBAQAAwASBCcCMgMaOiBBbGwgaW5mb3JtYXRpb24gYWJvdXQgYSBz
aW5nbGUgdHVybiBpbiB0aGUgY29udmVyc2F0aW9uLgoKDAoFBAADAAESAycKDgqcAQoGBAAD
AAIAEgMqBEsajAEgT3B0aW9uYWwuIExpc3Qgb2YgbWVzc2FnZXMgaW4gdGhlIGNvbnZlcnNh
dGlvbiB0dXJuLCBpbmNsdWRpbmcgdXNlcgogaW5wdXQsIGFnZW50IHJlc3BvbnNlcyBhbmQg
aW50ZXJtZWRpYXRlIGV2ZW50cyBkdXJpbmcgdGhlIHByb2Nlc3NpbmcuCgoOCgcEAAMAAgAE
EgMqBAwKDgoHBAADAAIABhIDKg0UCg4KBwQAAwACAAESAyoVHQoOCgcEAAMAAgADEgMqICEK
DgoHBAADAAIACBIDKiJKChEKCgQAAwACAAicCAASAyojSQpCCgYEAAMAAgESAy0EQBozIE9w
dGlvbmFsLiBUaGUgcm9vdCBzcGFuIG9mIHRoZSBhY3Rpb24gcHJvY2Vzc2luZy4KCg4KBwQA
AwACAQYSAy0ECAoOCgcEAAMAAgEBEgMtCRIKDgoHBAADAAIBAxIDLRUWCg4KBwQAAwACAQgS
Ay0XPwoRCgoEAAMAAgEInAgAEgMtGD4KmwEKBgQAAwACAhIDMQRLGosBIE9wdGlvbmFsLiBU
aGUgaW50ZW5kZWQgZ3JvdW5kLXRydXRoIHRleHQgZnJvbSB0aGUgU2ltdWxhdGVkIENhbGxl
cgogKFBvbHlzeW50aCkuIE9ubHkgcG9wdWxhdGVkIHdoZW4gd29yZCBlcnJvciByYXRlIG1l
dHJpY3MgYXJlIGVuYWJsZWQuCgoOCgcEAAMAAgIFEgMxBAoKDgoHBAADAAICARIDMQsdCg4K
BwQAAwACAgMSAzEgIQoOCgcEAAMAAgIIEgMxIkoKEQoKBAADAAICCJwIABIDMSNJCjUKBAQA
BAASBDUCRAMaJyBUaGUgY2hhbm5lbCB0eXBlIG9mIHRoZSBjb252ZXJzYXRpb24uCgoMCgUE
AAQAARIDNQcSCioKBgQABAACABIDNwQhGhsgVW5zcGVjaWZpZWQgY2hhbm5lbCB0eXBlLgoK
DgoHBAAEAAIAARIDNwQcCg4KBwQABAACAAISAzcfIApiCgYEAAQAAgESAzsEDRpTIFRoZSBj
b252ZXJzYXRpb24gb25seSBjb250YWlucyB0ZXh0IG1lc3NhZ2VzIGJldHdlZW4gdGhlIGVu
ZCB1c2VyIGFuZCB0aGUKIGFnZW50LgoKDgoHBAAEAAIBARIDOwQICg4KBwQABAACAQISAzsL
DApeCgYEAAQAAgISAz8EDhpPIFRoZSBjb252ZXJzYXRpb24gY29udGFpbnMgYXVkaW8gbWVz
c2FnZXMgYmV0d2VlbiB0aGUgZW5kIHVzZXIgYW5kIHRoZQogYWdlbnQuCgoOCgcEAAQAAgIB
EgM/BAkKDgoHBAAEAAICAhIDPwwNCmgKBgQABAACAxIDQwQTGlkgVGhlIGNvbnZlcnNhdGlv
biBtdWx0aS1tb2RhbCBtZXNzYWdlcyAoZS5nLiBpbWFnZSkgYmV0d2VlbiB0aGUgZW5kIHVz
ZXIKIGFuZCB0aGUgYWdlbnQuCgoOCgcEAAQAAgMBEgNDBA4KDgoHBAAEAAIDAhIDQxESCi8K
BAQABAESBEcCVwMaISBUaGUgc291cmNlIG9mIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAQB
ARIDRwcNCiQKBgQABAECABIDSQQbGhUgVW5zcGVjaWZpZWQgc291cmNlLgoKDgoHBAAEAQIA
ARIDSQQWCg4KBwQABAECAAISA0kZGgo8CgYEAAQBAgESA0wEDRotIFRoZSBjb252ZXJzYXRp
b24gaXMgZnJvbSB0aGUgbGl2ZSBlbmQgdXNlci4KCg4KBwQABAECAQESA0wECAoOCgcEAAQB
AgECEgNMCwwKOAoGBAAEAQICEgNPBBIaKSBUaGUgY29udmVyc2F0aW9uIGlzIGZyb20gdGhl
IHNpbXVsYXRvci4KCg4KBwQABAECAgESA08EDQoOCgcEAAQBAgICEgNPEBEKOQoGBAAEAQID
EgNSBA0aKiBUaGUgY29udmVyc2F0aW9uIGlzIGZyb20gdGhlIGV2YWx1YXRpb24uCgoOCgcE
AAQBAgMBEgNSBAgKDgoHBAAEAQIDAhIDUgsMCqIBCgYEAAQBAgQSA1YEExqSASBUaGUgY29u
dmVyc2F0aW9uIGlzIGZyb20gYW4gYWdlbnQgdG9vbC4gQWdlbnQgdG9vbCBydW5zIHRoZSBh
Z2VudCBpbiBhCiBzZXBhcmF0ZSBzZXNzaW9uLCB3aGljaCBpcyBwZXJzaXN0ZWQgZm9yIHRl
c3RpbmcgYW5kIGRlYnVnZ2luZyBwdXJwb3Nlcy4KCg4KBwQABAECBAESA1YEDgoOCgcEAAQB
AgQCEgNWERIKKgoEBAAEAhIEWgJyAxocIFR5cGUgb2YgdGhlIGlucHV0IG1lc3NhZ2UuCgoM
CgUEAAQCARIDWgcQCigKBgQABAICABIDXAQfGhkgVW5zcGVjaWZpZWQgaW5wdXQgdHlwZS4K
Cg4KBwQABAICAAESA1wEGgoOCgcEAAQCAgACEgNcHR4KHAoGBAAEAgIBEgNfBBgaDSBUZXh0
IGlucHV0LgoKDgoHBAAEAgIBARIDXwQTCg4KBwQABAICAQISA18WFwodCgYEAAQCAgISA2IE
GRoOIEV2ZW50IGlucHV0LgoKDgoHBAAEAgICARIDYgQUCg4KBwQABAICAgISA2IXGAodCgYE
AAQCAgMSA2UEGRoOIEF1ZGlvIGlucHV0LgoKDgoHBAAEAgIDARIDZQQUCg4KBwQABAICAwIS
A2UXGAodCgYEAAQCAgQSA2gEGRoOIEltYWdlIGlucHV0LgoKDgoHBAAEAgIEARIDaAQUCg4K
BwQABAICBAISA2gXGAocCgYEAAQCAgUSA2sEGBoNIEJsb2IgaW5wdXQuCgoOCgcEAAQCAgUB
EgNrBBMKDgoHBAAEAgIFAhIDaxYXCjUKBgQABAICBhIDbgQhGiYgQ2xpZW50IGZ1bmN0aW9u
IHRvb2wgcmVzcG9uc2UgaW5wdXQuCgoOCgcEAAQCAgYBEgNuBBwKDgoHBAAEAgIGAhIDbh8g
CiEKBgQABAICBxIDcQQdGhIgVmFyaWFibGVzIGlucHV0LgoKDgoHBAAEAgIHARIDcQQYCg4K
BwQABAICBwISA3EbHAqiAQoEBAACABIDdwI9GpQBIElkZW50aWZpZXIuIFRoZSB1bmlxdWUg
aWRlbnRpZmllciBvZiB0aGUgY29udmVyc2F0aW9uLgogRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2NvbnZlcnNhdGlvbnMv
e2NvbnZlcnNhdGlvbn1gCgoMCgUEAAIABRIDdwIICgwKBQQAAgABEgN3CQ0KDAoFBAACAAMS
A3cQEQoMCgUEAAIACBIDdxI8Cg8KCAQAAgAInAgAEgN3EzsKSQoEBAACARIEegJ7Mho7IE91
dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUgY29udmVyc2F0aW9uIHdhcyBjcmVhdGVk
LgoKDAoFBAACAQYSA3oCGwoMCgUEAAIBARIDehwmCgwKBQQAAgEDEgN6KSoKDAoFBAACAQgS
A3sGMQoPCggEAAIBCJwIABIDewcwCksKBAQAAgISBH4CfzIaPSBPdXRwdXQgb25seS4gVGlt
ZXN0YW1wIHdoZW4gdGhlIGNvbnZlcnNhdGlvbiB3YXMgY29tcGxldGVkLgoKDAoFBAACAgYS
A34CGwoMCgUEAAICARIDfhwkCgwKBQQAAgIDEgN+JygKDAoFBAACAggSA38GMQoPCggEAAIC
CJwIABIDfwcwCjgKBAQAAgMSBIIBAkMaKiBSZXF1aXJlZC4gVGhlIHR1cm5zIGluIHRoZSBj
b252ZXJzYXRpb24uCgoNCgUEAAIDBBIEggECCgoNCgUEAAIDBhIEggELDwoNCgUEAAIDARIE
ggEQFQoNCgUEAAIDAxIEggEYGQoNCgUEAAIDCBIEggEaQgoQCggEAAIDCJwIABIEggEbQQpF
CgQEAAIEEgSFAQJDGjcgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgdHVybnMgaW4gdGhl
IGNvbnZlcnNhdGlvbi4KCg0KBQQAAgQFEgSFAQIHCg0KBQQAAgQBEgSFAQgSCg0KBQQAAgQD
EgSFARUWCg0KBQQAAgQIEgSFARdCChAKCAQAAgQInAgAEgSFARhBCnAKBAQAAgUSBIkBAjMa
YiBERVBSRUNBVEVELiBQbGVhc2UgdXNlCiBbaW5wdXRfdHlwZXNdW2dvb2dsZS5jbG91ZC5j
ZXMudjFiZXRhLkNvbnZlcnNhdGlvbi5pbnB1dF90eXBlc10gaW5zdGVhZC4KCg0KBQQAAgUG
EgSJAQINCg0KBQQAAgUBEgSJAQ4aCg0KBQQAAgUDEgSJAR0eCg0KBQQAAgUIEgSJAR8yCg4K
BgQAAgUIAxIEiQEgMQpFCgQEAAIGEgSMAQJAGjcgT3V0cHV0IG9ubHkuIEluZGljYXRlIHRo
ZSBzb3VyY2Ugb2YgdGhlIGNvbnZlcnNhdGlvbi4KCg0KBQQAAgYGEgSMAQIICg0KBQQAAgYB
EgSMAQkPCg0KBQQAAgYDEgSMARITCg0KBQQAAgYIEgSMARQ/ChAKCAQAAgYInAgAEgSMARU+
CkMKBAQAAgcSBo8BApABMhozIE91dHB1dCBvbmx5LiBUaGUgaW5wdXQgdHlwZXMgb2YgdGhl
IGNvbnZlcnNhdGlvbi4KCg0KBQQAAgcEEgSPAQIKCg0KBQQAAgcGEgSPAQsUCg0KBQQAAgcB
EgSPARUgCg0KBQQAAgcDEgSPASMlCg0KBQQAAgcIEgSQAQYxChAKCAQAAgcInAgAEgSQAQcw
CuEBCgQEAAIIEgaVAQKYAQQa0AEgT3V0cHV0IG9ubHkuIFRoZSBhZ2VudCB0aGF0IGluaXRp
YWxseSBoYW5kbGVzIHRoZSBjb252ZXJzYXRpb24uIElmIG5vdAogc3BlY2lmaWVkLCB0aGUg
Y29udmVyc2F0aW9uIGlzIGhhbmRsZWQgYnkgdGhlIHJvb3QgYWdlbnQuIEZvcm1hdDoKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9hZ2Vu
dHMve2FnZW50fWAKCg0KBQQAAggFEgSVAQIICg0KBQQAAggBEgSVAQkUCg0KBQQAAggDEgSV
ARcZCg8KBQQAAggIEgaVARqYAQMKEAoIBAACCAicCAASBJYBBC0KDwoHBAACCAifCBIElwEE
Sgq3AQoEBAACCRIGnQECoAEEGqYBIE91dHB1dCBvbmx5LiBUaGUgZGVwbG95bWVudCBvZiB0
aGUgYXBwIHVzZWQgZm9yIHByb2Nlc3NpbmcgdGhlCiBjb252ZXJzYXRpb24uIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9k
ZXBsb3ltZW50cy97ZGVwbG95bWVudH1gCgoNCgUEAAIJBRIEnQECCAoNCgUEAAIJARIEnQEJ
EwoNCgUEAAIJAxIEnQEWGAoPCgUEAAIJCBIGnQEZoAEDChAKCAQAAgkInAgAEgSeAQQtCg8K
BwQAAgkInwgSBJ8BBE8KrgEKBAQAAgoSBqUBAqgBBBqdASBPdXRwdXQgb25seS4gVGhlIHZl
cnNpb24gb2YgdGhlIGFwcCB1c2VkIGZvciBwcm9jZXNzaW5nIHRoZSBjb252ZXJzYXRpb24u
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fw
cHMve2FwcH0vdmVyc2lvbnMve3ZlcnNpb259YAoKDQoFBAACCgUSBKUBAggKDQoFBAACCgES
BKUBCRQKDQoFBAACCgMSBKUBFxkKDwoFBAACCggSBqUBGqgBAwoQCggEAAIKCJwIABIEpgEE
LQoPCgcEAAIKCJ8IEgSnAQRPCkMKBAQAAgsSBKsBAkgaNSBPdXRwdXQgb25seS4gVGhlIGxh
bmd1YWdlIGNvZGUgb2YgdGhlIGNvbnZlcnNhdGlvbi4KCg0KBQQAAgsFEgSrAQIICg0KBQQA
AgsBEgSrAQkWCg0KBQQAAgsDEgSrARkbCg0KBQQAAgsIEgSrARxHChAKCAQAAgsInAgAEgSr
AR1GCi4KBAQAAgwSBK4BAjQaICBEZXByZWNhdGVkLiBVc2UgdHVybnMgaW5zdGVhZC4KCg0K
BQQAAgwEEgSuAQIKCg0KBQQAAgwGEgSuAQsSCg0KBQQAAgwBEgSuARMbCg0KBQQAAgwDEgSu
AR4fCg0KBQQAAgwIEgSuASAzCg4KBgQAAgwIAxIErgEhMmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: turns Type: 11 (.google.cloud.ces.v1beta.Conversation.Turn)
    # Field: turn_count Type: 5 ()
    # Field: channel_type Type: 14 (.google.cloud.ces.v1beta.Conversation.ChannelType)
    # Field: source Type: 14 (.google.cloud.ces.v1beta.Conversation.Source)
    # Field: input_types Type: 14 (.google.cloud.ces.v1beta.Conversation.InputType)
    # Field: entry_agent Type: 9 ()
    # Field: deployment Type: 9 ()
    # Field: app_version Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.ces.v1beta.Message)

# Enum: Conversation::ChannelType
our $Conversation_CHANNEL_TYPE_UNSPECIFIED = 0;
our $Conversation_TEXT = 1;
our $Conversation_AUDIO = 2;
our $Conversation_MULTIMODAL = 3;

# Enum: Conversation::Source
our $Conversation_SOURCE_UNSPECIFIED = 0;
our $Conversation_LIVE = 1;
our $Conversation_SIMULATOR = 2;
our $Conversation_EVAL = 3;
our $Conversation_AGENT_TOOL = 4;

# Enum: Conversation::InputType
our $Conversation_INPUT_TYPE_UNSPECIFIED = 0;
our $Conversation_INPUT_TYPE_TEXT = 1;
our $Conversation_INPUT_TYPE_EVENT = 7;
our $Conversation_INPUT_TYPE_AUDIO = 2;
our $Conversation_INPUT_TYPE_IMAGE = 3;
our $Conversation_INPUT_TYPE_BLOB = 4;
our $Conversation_INPUT_TYPE_TOOL_RESPONSE = 5;
our $Conversation_INPUT_TYPE_VARIABLES = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Conversation - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Conversation;

    my $msg = Google::Cloud::Ces::V1beta::Conversation::Conversation->new({
        name => $name,
        start_time => $start_time,
        end_time => $end_time,
        turns => $turns,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Conversation::Conversation

A conversation represents an interaction between an end user and the CES app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the conversation.
Format:
`projects/{project}/locations/{location}/apps/{app}/conversations/{conversation}`

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the conversation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the conversation was completed.

=item * C<< $msg->turns() >> / C<< $msg->turns($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Conversation::Conversation::Turn>)

Required. The turns in the conversation.

=item * C<< $msg->turn_count() >> / C<< $msg->turn_count($value) >>

Type: C<Int32>

Output only. The number of turns in the conversation.

=item * C<< $msg->channel_type() >> / C<< $msg->channel_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::Conversation::ChannelType>)

DEPRECATED. Please use
[input_types][google.cloud.ces.v1beta.Conversation.input_types] instead.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::Conversation::Source>)

Output only. Indicate the source of the conversation.

=item * C<< $msg->input_types() >> / C<< $msg->input_types($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::Conversation::InputType>)

Output only. The input types of the conversation.

=item * C<< $msg->entry_agent() >> / C<< $msg->entry_agent($value) >>

Type: C<String>

Output only. The agent that initially handles the conversation. If not
specified, the conversation is handled by the root agent. Format:
`projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<String>

Output only. The deployment of the app used for processing the
conversation. Format:
`projects/{project}/locations/{location}/apps/{app}/deployments/{deployment}`

=item * C<< $msg->app_version() >> / C<< $msg->app_version($value) >>

Type: C<String>

Output only. The version of the app used for processing the conversation.
Format:
`projects/{project}/locations/{location}/apps/{app}/versions/{version}`

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Output only. The language code of the conversation.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::Message>)

Deprecated. Use turns instead.

=back

=head3 Enum: Conversation::ChannelType

=over 4

=item * C<CHANNEL_TYPE_UNSPECIFIED> => C<0>

=item * C<TEXT> => C<1>

=item * C<AUDIO> => C<2>

=item * C<MULTIMODAL> => C<3>

=back

=head3 Enum: Conversation::Source

=over 4

=item * C<SOURCE_UNSPECIFIED> => C<0>

=item * C<LIVE> => C<1>

=item * C<SIMULATOR> => C<2>

=item * C<EVAL> => C<3>

=item * C<AGENT_TOOL> => C<4>

=back

=head3 Enum: Conversation::InputType

=over 4

=item * C<INPUT_TYPE_UNSPECIFIED> => C<0>

=item * C<INPUT_TYPE_TEXT> => C<1>

=item * C<INPUT_TYPE_EVENT> => C<7>

=item * C<INPUT_TYPE_AUDIO> => C<2>

=item * C<INPUT_TYPE_IMAGE> => C<3>

=item * C<INPUT_TYPE_BLOB> => C<4>

=item * C<INPUT_TYPE_TOOL_RESPONSE> => C<5>

=item * C<INPUT_TYPE_VARIABLES> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
