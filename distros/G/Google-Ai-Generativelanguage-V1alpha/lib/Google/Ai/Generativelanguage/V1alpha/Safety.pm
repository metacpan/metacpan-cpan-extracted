package Google::Ai::Generativelanguage::V1alpha::Safety;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvc2FmZXR5LnByb3RvEiRn
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8i3QEKDUNvbnRlbnRGaWx0ZXISWQoGcmVhc29uGAEgASgOMkEuZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkNvbnRlbnRGaWx0ZXIuQmxvY2tl
ZFJlYXNvblIGcmVhc29uEh0KB21lc3NhZ2UYAiABKAlIAFIHbWVzc2FnZYgBASJGCg1CbG9j
a2VkUmVhc29uEh4KGkJMT0NLRURfUkVBU09OX1VOU1BFQ0lGSUVEEAASCgoGU0FGRVRZEAES
CQoFT1RIRVIQAkIKCghfbWVzc2FnZSKrAQoOU2FmZXR5RmVlZGJhY2sSSgoGcmF0aW5nGAEg
ASgLMjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlNhZmV0eVJhdGlu
Z1IGcmF0aW5nEk0KB3NldHRpbmcYAiABKAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1
YWdlLnYxYWxwaGEuU2FmZXR5U2V0dGluZ1IHc2V0dGluZyLMAgoMU2FmZXR5UmF0aW5nElMK
CGNhdGVnb3J5GAMgASgOMjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhh
Lkhhcm1DYXRlZ29yeUID4EECUghjYXRlZ29yeRJpCgtwcm9iYWJpbGl0eRgEIAEoDjJCLmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5TYWZldHlSYXRpbmcuSGFybVBy
b2JhYmlsaXR5QgPgQQJSC3Byb2JhYmlsaXR5EhgKB2Jsb2NrZWQYBSABKAhSB2Jsb2NrZWQi
YgoPSGFybVByb2JhYmlsaXR5EiAKHEhBUk1fUFJPQkFCSUxJVFlfVU5TUEVDSUZJRUQQABIO
CgpORUdMSUdJQkxFEAESBwoDTE9XEAISCgoGTUVESVVNEAMSCAoESElHSBAEIu8CCg1TYWZl
dHlTZXR0aW5nElMKCGNhdGVnb3J5GAMgASgOMjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWFscGhhLkhhcm1DYXRlZ29yeUID4EECUghjYXRlZ29yeRJpCgl0aHJlc2hvbGQY
BCABKA4yRi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuU2FmZXR5U2V0
dGluZy5IYXJtQmxvY2tUaHJlc2hvbGRCA+BBAlIJdGhyZXNob2xkIp0BChJIYXJtQmxvY2tU
aHJlc2hvbGQSJAogSEFSTV9CTE9DS19USFJFU0hPTERfVU5TUEVDSUZJRUQQABIXChNCTE9D
S19MT1dfQU5EX0FCT1ZFEAESGgoWQkxPQ0tfTUVESVVNX0FORF9BQk9WRRACEhMKD0JMT0NL
X09OTFlfSElHSBADEg4KCkJMT0NLX05PTkUQBBIHCgNPRkYQBSr/AgoMSGFybUNhdGVnb3J5
Eh0KGUhBUk1fQ0FURUdPUllfVU5TUEVDSUZJRUQQABIcChhIQVJNX0NBVEVHT1JZX0RFUk9H
QVRPUlkQARIaChZIQVJNX0NBVEVHT1JZX1RPWElDSVRZEAISGgoWSEFSTV9DQVRFR09SWV9W
SU9MRU5DRRADEhgKFEhBUk1fQ0FURUdPUllfU0VYVUFMEAQSGQoVSEFSTV9DQVRFR09SWV9N
RURJQ0FMEAUSGwoXSEFSTV9DQVRFR09SWV9EQU5HRVJPVVMQBhIcChhIQVJNX0NBVEVHT1JZ
X0hBUkFTU01FTlQQBxIdChlIQVJNX0NBVEVHT1JZX0hBVEVfU1BFRUNIEAgSIwofSEFSTV9D
QVRFR09SWV9TRVhVQUxMWV9FWFBMSUNJVBAJEiMKH0hBUk1fQ0FURUdPUllfREFOR0VST1VT
X0NPTlRFTlQQChIhCh1IQVJNX0NBVEVHT1JZX0NJVklDX0lOVEVHUklUWRALQpkBCihjb20u
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhQgtTYWZldHlQcm90b1ABWl5j
bG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWFscGhhL2dl
bmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSuouCgcSBQ4AswEBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkK
CAoBCBIDFAB1CgkKAggLEgMUAHUKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAsCgkK
AggIEgMWACwKCAoBCBIDFwBBCgkKAggBEgMXAEEKfAoCBQASBB0ARAEacCBUaGUgY2F0ZWdv
cnkgb2YgYSByYXRpbmcuCgogVGhlc2UgY2F0ZWdvcmllcyBjb3ZlciB2YXJpb3VzIGtpbmRz
IG9mIGhhcm1zIHRoYXQgZGV2ZWxvcGVycwogbWF5IHdpc2ggdG8gYWRqdXN0LgoKCgoDBQAB
EgMdBREKJwoEBQACABIDHwIgGhogQ2F0ZWdvcnkgaXMgdW5zcGVjaWZpZWQuCgoMCgUFAAIA
ARIDHwIbCgwKBQUAAgACEgMfHh8KZgoEBQACARIDIwIfGlkgKipQYUxNKiogLSBOZWdhdGl2
ZSBvciBoYXJtZnVsIGNvbW1lbnRzIHRhcmdldGluZyBpZGVudGl0eSBhbmQvb3IgcHJvdGVj
dGVkCiBhdHRyaWJ1dGUuCgoMCgUFAAIBARIDIwIaCgwKBQUAAgECEgMjHR4KSgoEBQACAhID
JgIdGj0gKipQYUxNKiogLSBDb250ZW50IHRoYXQgaXMgcnVkZSwgZGlzcmVzcGVjdGZ1bCwg
b3IgcHJvZmFuZS4KCgwKBQUAAgIBEgMmAhgKDAoFBQACAgISAyYbHAqCAQoEBQACAxIDKgId
GnUgKipQYUxNKiogLSBEZXNjcmliZXMgc2NlbmFyaW9zIGRlcGljdGluZyB2aW9sZW5jZSBh
Z2FpbnN0IGFuIGluZGl2aWR1YWwgb3IKIGdyb3VwLCBvciBnZW5lcmFsIGRlc2NyaXB0aW9u
cyBvZiBnb3JlLgoKDAoFBQACAwESAyoCGAoMCgUFAAIDAhIDKhscClMKBAUAAgQSAy0CGxpG
ICoqUGFMTSoqIC0gQ29udGFpbnMgcmVmZXJlbmNlcyB0byBzZXh1YWwgYWN0cyBvciBvdGhl
ciBsZXdkIGNvbnRlbnQuCgoMCgUFAAIEARIDLQIWCgwKBQUAAgQCEgMtGRoKPAoEBQACBRID
MAIcGi8gKipQYUxNKiogLSBQcm9tb3RlcyB1bmNoZWNrZWQgbWVkaWNhbCBhZHZpY2UuCgoM
CgUFAAIFARIDMAIXCgwKBQUAAgUCEgMwGhsKZAoEBQACBhIDNAIeGlcgKipQYUxNKiogLSBE
YW5nZXJvdXMgY29udGVudCB0aGF0IHByb21vdGVzLCBmYWNpbGl0YXRlcywgb3IgZW5jb3Vy
YWdlcwogaGFybWZ1bCBhY3RzLgoKDAoFBQACBgESAzQCGQoMCgUFAAIGAhIDNBwdCi8KBAUA
AgcSAzcCHxoiICoqR2VtaW5pKiogLSBIYXJhc3NtZW50IGNvbnRlbnQuCgoMCgUFAAIHARID
NwIaCgwKBQUAAgcCEgM3HR4KNAoEBQACCBIDOgIgGicgKipHZW1pbmkqKiAtIEhhdGUgc3Bl
ZWNoIGFuZCBjb250ZW50LgoKDAoFBQACCAESAzoCGwoMCgUFAAIIAhIDOh4fCjYKBAUAAgkS
Az0CJhopICoqR2VtaW5pKiogLSBTZXh1YWxseSBleHBsaWNpdCBjb250ZW50LgoKDAoFBQAC
CQESAz0CIQoMCgUFAAIJAhIDPSQlCi4KBAUAAgoSA0ACJxohICoqR2VtaW5pKiogLSBEYW5n
ZXJvdXMgY29udGVudC4KCgwKBQUAAgoBEgNAAiEKDAoFBQACCgISA0AkJgpNCgQFAAILEgND
AiUaQCAqKkdlbWluaSoqIC0gQ29udGVudCB0aGF0IG1heSBiZSB1c2VkIHRvIGhhcm0gY2l2
aWMgaW50ZWdyaXR5LgoKDAoFBQACCwESA0MCHwoMCgUFAAILAhIDQyIkCrsBCgIEABIESgBc
ARquASBDb250ZW50IGZpbHRlcmluZyBtZXRhZGF0YSBhc3NvY2lhdGVkIHdpdGggcHJvY2Vz
c2luZyBhIHNpbmdsZSByZXF1ZXN0LgoKIENvbnRlbnRGaWx0ZXIgY29udGFpbnMgYSByZWFz
b24gYW5kIGFuIG9wdGlvbmFsIHN1cHBvcnRpbmcgc3RyaW5nLiBUaGUgcmVhc29uCiBtYXkg
YmUgdW5zcGVjaWZpZWQuCgoKCgMEAAESA0oIFQpECgQEAAQAEgRMAlUDGjYgQSBsaXN0IG9m
IHJlYXNvbnMgd2h5IGNvbnRlbnQgbWF5IGhhdmUgYmVlbiBibG9ja2VkLgoKDAoFBAAEAAES
A0wHFAo0CgYEAAQAAgASA04EIxolIEEgYmxvY2tlZCByZWFzb24gd2FzIG5vdCBzcGVjaWZp
ZWQuCgoOCgcEAAQAAgABEgNOBB4KDgoHBAAEAAIAAhIDTiEiCjgKBgQABAACARIDUQQPGikg
Q29udGVudCB3YXMgYmxvY2tlZCBieSBzYWZldHkgc2V0dGluZ3MuCgoOCgcEAAQAAgEBEgNR
BAoKDgoHBAAEAAIBAhIDUQ0OCkYKBgQABAACAhIDVAQOGjcgQ29udGVudCB3YXMgYmxvY2tl
ZCwgYnV0IHRoZSByZWFzb24gaXMgdW5jYXRlZ29yaXplZC4KCg4KBwQABAACAgESA1QECQoO
CgcEAAQAAgICEgNUDA0KSAoEBAACABIDWAIbGjsgVGhlIHJlYXNvbiBjb250ZW50IHdhcyBi
bG9ja2VkIGR1cmluZyByZXF1ZXN0IHByb2Nlc3NpbmcuCgoMCgUEAAIABhIDWAIPCgwKBQQA
AgABEgNYEBYKDAoFBAACAAMSA1gZGgpNCgQEAAIBEgNbAh4aQCBBIHN0cmluZyB0aGF0IGRl
c2NyaWJlcyB0aGUgZmlsdGVyaW5nIGJlaGF2aW9yIGluIG1vcmUgZGV0YWlsLgoKDAoFBAAC
AQQSA1sCCgoMCgUEAAIBBRIDWwsRCgwKBQQAAgEBEgNbEhkKDAoFBAACAQMSA1scHQr1AgoC
BAESBGUAawEa6AIgU2FmZXR5IGZlZWRiYWNrIGZvciBhbiBlbnRpcmUgcmVxdWVzdC4KCiBU
aGlzIGZpZWxkIGlzIHBvcHVsYXRlZCBpZiBjb250ZW50IGluIHRoZSBpbnB1dCBhbmQvb3Ig
cmVzcG9uc2UgaXMgYmxvY2tlZAogZHVlIHRvIHNhZmV0eSBzZXR0aW5ncy4gU2FmZXR5RmVl
ZGJhY2sgbWF5IG5vdCBleGlzdCBmb3IgZXZlcnkgSGFybUNhdGVnb3J5LgogRWFjaCBTYWZl
dHlGZWVkYmFjayB3aWxsIHJldHVybiB0aGUgc2FmZXR5IHNldHRpbmdzIHVzZWQgYnkgdGhl
IHJlcXVlc3QgYXMKIHdlbGwgYXMgdGhlIGxvd2VzdCBIYXJtUHJvYmFiaWxpdHkgdGhhdCBz
aG91bGQgYmUgYWxsb3dlZCBpbiBvcmRlciB0byByZXR1cm4KIGEgcmVzdWx0LgoKCgoDBAEB
EgNlCBYKNAoEBAECABIDZwIaGicgU2FmZXR5IHJhdGluZyBldmFsdWF0ZWQgZnJvbSBjb250
ZW50LgoKDAoFBAECAAYSA2cCDgoMCgUEAQIAARIDZw8VCgwKBQQBAgADEgNnGBkKNgoEBAEC
ARIDagIcGikgU2FmZXR5IHNldHRpbmdzIGFwcGxpZWQgdG8gdGhlIHJlcXVlc3QuCgoMCgUE
AQIBBhIDagIPCgwKBQQBAgEBEgNqEBcKDAoFBAECAQMSA2oaGwq4AgoCBAISBXQAkgEBGqoC
IFNhZmV0eSByYXRpbmcgZm9yIGEgcGllY2Ugb2YgY29udGVudC4KCiBUaGUgc2FmZXR5IHJh
dGluZyBjb250YWlucyB0aGUgY2F0ZWdvcnkgb2YgaGFybSBhbmQgdGhlCiBoYXJtIHByb2Jh
YmlsaXR5IGxldmVsIGluIHRoYXQgY2F0ZWdvcnkgZm9yIGEgcGllY2Ugb2YgY29udGVudC4K
IENvbnRlbnQgaXMgY2xhc3NpZmllZCBmb3Igc2FmZXR5IGFjcm9zcyBhIG51bWJlciBvZgog
aGFybSBjYXRlZ29yaWVzIGFuZCB0aGUgcHJvYmFiaWxpdHkgb2YgdGhlIGhhcm0gY2xhc3Np
ZmljYXRpb24gaXMgaW5jbHVkZWQKIGhlcmUuCgoKCgMEAgESA3QIFArZAQoEBAIEABIFeQKI
AQMayQEgVGhlIHByb2JhYmlsaXR5IHRoYXQgYSBwaWVjZSBvZiBjb250ZW50IGlzIGhhcm1m
dWwuCgogVGhlIGNsYXNzaWZpY2F0aW9uIHN5c3RlbSBnaXZlcyB0aGUgcHJvYmFiaWxpdHkg
b2YgdGhlIGNvbnRlbnQgYmVpbmcKIHVuc2FmZS4gVGhpcyBkb2VzIG5vdCBpbmRpY2F0ZSB0
aGUgc2V2ZXJpdHkgb2YgaGFybSBmb3IgYSBwaWVjZSBvZiBjb250ZW50LgoKDAoFBAIEAAES
A3kHFgosCgYEAgQAAgASA3sEJRodIFByb2JhYmlsaXR5IGlzIHVuc3BlY2lmaWVkLgoKDgoH
BAIEAAIAARIDewQgCg4KBwQCBAACAAISA3sjJApBCgYEAgQAAgESA34EExoyIENvbnRlbnQg
aGFzIGEgbmVnbGlnaWJsZSBjaGFuY2Ugb2YgYmVpbmcgdW5zYWZlLgoKDgoHBAIEAAIBARID
fgQOCg4KBwQCBAACAQISA34REgo7CgYEAgQAAgISBIEBBAwaKyBDb250ZW50IGhhcyBhIGxv
dyBjaGFuY2Ugb2YgYmVpbmcgdW5zYWZlLgoKDwoHBAIEAAICARIEgQEEBwoPCgcEAgQAAgIC
EgSBAQoLCj4KBgQCBAACAxIEhAEEDxouIENvbnRlbnQgaGFzIGEgbWVkaXVtIGNoYW5jZSBv
ZiBiZWluZyB1bnNhZmUuCgoPCgcEAgQAAgMBEgSEAQQKCg8KBwQCBAACAwISBIQBDQ4KPAoG
BAIEAAIEEgSHAQQNGiwgQ29udGVudCBoYXMgYSBoaWdoIGNoYW5jZSBvZiBiZWluZyB1bnNh
ZmUuCgoPCgcEAgQAAgQBEgSHAQQICg8KBwQCBAACBAISBIcBCwwKNwoEBAICABIEiwECRRop
IFJlcXVpcmVkLiBUaGUgY2F0ZWdvcnkgZm9yIHRoaXMgcmF0aW5nLgoKDQoFBAICAAYSBIsB
Ag4KDQoFBAICAAESBIsBDxcKDQoFBAICAAMSBIsBGhsKDQoFBAICAAgSBIsBHEQKEAoIBAIC
AAicCAASBIsBHUMKQwoEBAICARIEjgECSxo1IFJlcXVpcmVkLiBUaGUgcHJvYmFiaWxpdHkg
b2YgaGFybSBmb3IgdGhpcyBjb250ZW50LgoKDQoFBAICAQYSBI4BAhEKDQoFBAICAQESBI4B
Eh0KDQoFBAICAQMSBI4BICEKDQoFBAICAQgSBI4BIkoKEAoIBAICAQicCAASBI4BI0kKQAoE
BAICAhIEkQECExoyIFdhcyB0aGlzIGNvbnRlbnQgYmxvY2tlZCBiZWNhdXNlIG9mIHRoaXMg
cmF0aW5nPwoKDQoFBAICAgUSBJEBAgYKDQoFBAICAgESBJEBBw4KDQoFBAICAgMSBJEBERIK
rAEKAgQDEgaYAQCzAQEanQEgU2FmZXR5IHNldHRpbmcsIGFmZmVjdGluZyB0aGUgc2FmZXR5
LWJsb2NraW5nIGJlaGF2aW9yLgoKIFBhc3NpbmcgYSBzYWZldHkgc2V0dGluZyBmb3IgYSBj
YXRlZ29yeSBjaGFuZ2VzIHRoZSBhbGxvd2VkIHByb2JhYmlsaXR5IHRoYXQKIGNvbnRlbnQg
aXMgYmxvY2tlZC4KCgsKAwQDARIEmAEIFQpDCgQEAwQAEgaaAQKsAQMaMyBCbG9jayBhdCBh
bmQgYmV5b25kIGEgc3BlY2lmaWVkIGhhcm0gcHJvYmFiaWxpdHkuCgoNCgUEAwQAARIEmgEH
GQorCgYEAwQAAgASBJwBBCkaGyBUaHJlc2hvbGQgaXMgdW5zcGVjaWZpZWQuCgoPCgcEAwQA
AgABEgScAQQkCg8KBwQDBAACAAISBJwBJygKOgoGBAMEAAIBEgSfAQQcGiogQ29udGVudCB3
aXRoIE5FR0xJR0lCTEUgd2lsbCBiZSBhbGxvd2VkLgoKDwoHBAMEAAIBARIEnwEEFwoPCgcE
AwQAAgECEgSfARobCkIKBgQDBAACAhIEogEEHxoyIENvbnRlbnQgd2l0aCBORUdMSUdJQkxF
IGFuZCBMT1cgd2lsbCBiZSBhbGxvd2VkLgoKDwoHBAMEAAICARIEogEEGgoPCgcEAwQAAgIC
EgSiAR0eCksKBgQDBAACAxIEpQEEGBo7IENvbnRlbnQgd2l0aCBORUdMSUdJQkxFLCBMT1cs
IGFuZCBNRURJVU0gd2lsbCBiZSBhbGxvd2VkLgoKDwoHBAMEAAIDARIEpQEEEwoPCgcEAwQA
AgMCEgSlARYXCi4KBgQDBAACBBIEqAEEExoeIEFsbCBjb250ZW50IHdpbGwgYmUgYWxsb3dl
ZC4KCg8KBwQDBAACBAESBKgBBA4KDwoHBAMEAAIEAhIEqAEREgotCgYEAwQAAgUSBKsBBAwa
HSBUdXJuIG9mZiB0aGUgc2FmZXR5IGZpbHRlci4KCg8KBwQDBAACBQESBKsBBAcKDwoHBAME
AAIFAhIEqwEKCwo4CgQEAwIAEgSvAQJFGiogUmVxdWlyZWQuIFRoZSBjYXRlZ29yeSBmb3Ig
dGhpcyBzZXR0aW5nLgoKDQoFBAMCAAYSBK8BAg4KDQoFBAMCAAESBK8BDxcKDQoFBAMCAAMS
BK8BGhsKDQoFBAMCAAgSBK8BHEQKEAoIBAMCAAicCAASBK8BHUMKVgoEBAMCARIEsgECTBpI
IFJlcXVpcmVkLiBDb250cm9scyB0aGUgcHJvYmFiaWxpdHkgdGhyZXNob2xkIGF0IHdoaWNo
IGhhcm0gaXMgYmxvY2tlZC4KCg0KBQQDAgEGEgSyAQIUCg0KBQQDAgEBEgSyARUeCg0KBQQD
AgEDEgSyASEiCg0KBQQDAgEIEgSyASNLChAKCAQDAgEInAgAEgSyASRKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::Safety::ContentFilter ===
    # Fields for ContentFilter
    # Field: reason Type: 14 (.google.ai.generativelanguage.v1alpha.ContentFilter.BlockedReason)
    # Field: message Type: 9 ()

# Enum: ContentFilter::BlockedReason
our $ContentFilter_BLOCKED_REASON_UNSPECIFIED = 0;
our $ContentFilter_SAFETY = 1;
our $ContentFilter_OTHER = 2;

# === Message: Google::Ai::Generativelanguage::V1alpha::Safety::SafetyFeedback ===
    # Fields for SafetyFeedback
    # Field: rating Type: 11 (.google.ai.generativelanguage.v1alpha.SafetyRating)
    # Field: setting Type: 11 (.google.ai.generativelanguage.v1alpha.SafetySetting)

# === Message: Google::Ai::Generativelanguage::V1alpha::Safety::SafetyRating ===
    # Fields for SafetyRating
    # Field: category Type: 14 (.google.ai.generativelanguage.v1alpha.HarmCategory)
    # Field: probability Type: 14 (.google.ai.generativelanguage.v1alpha.SafetyRating.HarmProbability)
    # Field: blocked Type: 8 ()

# Enum: SafetyRating::HarmProbability
our $SafetyRating_HARM_PROBABILITY_UNSPECIFIED = 0;
our $SafetyRating_NEGLIGIBLE = 1;
our $SafetyRating_LOW = 2;
our $SafetyRating_MEDIUM = 3;
our $SafetyRating_HIGH = 4;

# === Message: Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting ===
    # Fields for SafetySetting
    # Field: category Type: 14 (.google.ai.generativelanguage.v1alpha.HarmCategory)
    # Field: threshold Type: 14 (.google.ai.generativelanguage.v1alpha.SafetySetting.HarmBlockThreshold)

# Enum: SafetySetting::HarmBlockThreshold
our $SafetySetting_HARM_BLOCK_THRESHOLD_UNSPECIFIED = 0;
our $SafetySetting_BLOCK_LOW_AND_ABOVE = 1;
our $SafetySetting_BLOCK_MEDIUM_AND_ABOVE = 2;
our $SafetySetting_BLOCK_ONLY_HIGH = 3;
our $SafetySetting_BLOCK_NONE = 4;
our $SafetySetting_OFF = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::Safety - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/safety.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::Safety;

    my $msg = Google::Ai::Generativelanguage::V1alpha::Safety::ContentFilter->new({
        reason => $reason,
        message => $message,
    });

    # Read or update a field
    my $val = $msg->reason();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::Safety::ContentFilter->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::Safety::ContentFilter

Content filtering metadata associated with processing a single request.

ContentFilter contains a reason and an optional supporting string. The reason
may be unspecified.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::ContentFilter::BlockedReason>)

The reason content was blocked during request processing.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

A string that describes the filtering behavior in more detail.

=back

=head3 Enum: ContentFilter::BlockedReason

=over 4

=item * C<BLOCKED_REASON_UNSPECIFIED> => C<0>

=item * C<SAFETY> => C<1>

=item * C<OTHER> => C<2>

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Safety::SafetyFeedback

Safety feedback for an entire request.

This field is populated if content in the input and/or response is blocked
due to safety settings. SafetyFeedback may not exist for every HarmCategory.
Each SafetyFeedback will return the safety settings used by the request as
well as the lowest HarmProbability that should be allowed in order to return
a result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rating() >> / C<< $msg->rating($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetyRating>)

Safety rating evaluated from content.

=item * C<< $msg->setting() >> / C<< $msg->setting($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>)

Safety settings applied to the request.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Safety::SafetyRating

Safety rating for a piece of content.

The safety rating contains the category of harm and the
harm probability level in that category for a piece of content.
Content is classified for safety across a number of
harm categories and the probability of the harm classification is included
here.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::HarmCategory>)

Required. The category for this rating.

=item * C<< $msg->probability() >> / C<< $msg->probability($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::SafetyRating::HarmProbability>)

Required. The probability of harm for this content.

=item * C<< $msg->blocked() >> / C<< $msg->blocked($value) >>

Type: C<Bool>

Was this content blocked because of this rating?

=back

=head3 Enum: SafetyRating::HarmProbability

=over 4

=item * C<HARM_PROBABILITY_UNSPECIFIED> => C<0>

=item * C<NEGLIGIBLE> => C<1>

=item * C<LOW> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<HIGH> => C<4>

=back

=head2 Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting

Safety setting, affecting the safety-blocking behavior.

Passing a safety setting for a category changes the allowed probability that
content is blocked.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::HarmCategory>)

Required. The category for this setting.

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::SafetySetting::HarmBlockThreshold>)

Required. Controls the probability threshold at which harm is blocked.

=back

=head3 Enum: SafetySetting::HarmBlockThreshold

=over 4

=item * C<HARM_BLOCK_THRESHOLD_UNSPECIFIED> => C<0>

=item * C<BLOCK_LOW_AND_ABOVE> => C<1>

=item * C<BLOCK_MEDIUM_AND_ABOVE> => C<2>

=item * C<BLOCK_ONLY_HIGH> => C<3>

=item * C<BLOCK_NONE> => C<4>

=item * C<OFF> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
