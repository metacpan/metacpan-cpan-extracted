package Google::Cloud::Designcenter::V1::Ingestion;

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
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2luZ2VzdGlvbi5wcm90bxIcZ29vZ2xl
LmNsb3VkLmRlc2lnbmNlbnRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byL0AQoJR2l0U291cmNlEhcKBHJlcG8YASAB
KAlCA+BBAlIEcmVwbxIVCgNkaXIYAiABKAlCA+BBAVIDZGlyEiIKCmNvbW1pdF9zaGEYAyAB
KAlCA+BBA1IJY29tbWl0U2hhEnUKGGRldmVsb3Blcl9jb25uZWN0X2NvbmZpZxgEIAEoCzI0
Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuRGV2ZWxvcGVyQ29ubmVjdENvbmZpZ0IF
GAHgQQFSFmRldmVsb3BlckNvbm5lY3RDb25maWcSHAoHcmVmX3RhZxgFIAEoCUID4EECUgZy
ZWZUYWciTQoWRGV2ZWxvcGVyQ29ubmVjdENvbmZpZxIzChNnaXRfcmVwb3NpdG9yeV9saW5r
GAEgASgJQgPgQQJSEWdpdFJlcG9zaXRvcnlMaW5rIq8CChxEZXZlbG9wZXJDb25uZWN0U291
cmNlQ29uZmlnEnYKGmRldmVsb3Blcl9jb25uZWN0X3JlcG9fdXJpGAEgASgJQjngQQL6QTMK
MWRldmVsb3BlcmNvbm5lY3QuZ29vZ2xlYXBpcy5jb20vR2l0UmVwb3NpdG9yeUxpbmtSF2Rl
dmVsb3BlckNvbm5lY3RSZXBvVXJpEk0KCXJlZmVyZW5jZRgIIAEoCzIqLmdvb2dsZS5jbG91
ZC5kZXNpZ25jZW50ZXIudjEuR2l0UmVmZXJlbmNlQgPgQQJSCXJlZmVyZW5jZRIVCgNkaXIY
BSABKAlCA+BBAlIDZGlyEjEKEmZldGNoZWRfY29tbWl0X3NoYRgJIAEoCUID4EEDUhBmZXRj
aGVkQ29tbWl0U2hhIoABCgxHaXRSZWZlcmVuY2USHQoGYnJhbmNoGAEgASgJQgPgQQFIAFIG
YnJhbmNoEh4KB3JlZl90YWcYAiABKAlCA+BBAUgAUgZyZWZUYWcSJAoKY29tbWl0X3NoYRgD
IAEoCUID4EEBSABSCWNvbW1pdFNoYUILCglyZWZlcmVuY2UicAoHT2NpUmVwbxIVCgN1cmkY
ASABKAlCA+BBAlIDdXJpEh0KB3ZlcnNpb24YAiABKAlCA+BBAVIHdmVyc2lvbhIvChFtb2R1
bGVfc291cmNlX3VyaRgDIAEoCUID4EEBUg9tb2R1bGVTb3VyY2VVcmkiTQoJSWFDTW9kdWxl
EkAKBWZpbGVzGAEgAygLMiUuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5JYUNGaWxl
QgPgQQFSBWZpbGVzIkEKB0lhQ0ZpbGUSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEh0KB2Nv
bnRlbnQYAiABKAlCA+BBAVIHY29udGVudCKXBwoOSW1wb3J0SWFDRXJyb3ISLgoQcmVzb3Vy
Y2VfYWRkcmVzcxgBIAEoCUID4EEDUg9yZXNvdXJjZUFkZHJlc3MSFwoEZmlsZRgCIAEoCUID
4EEDUgRmaWxlEkIKBXJhbmdlGAMgASgLMicuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52
MS5Db2RlUmFuZ2VCA+BBA1IFcmFuZ2USJQoLZGVzY3JpcHRpb24YBCABKAlCA+BBA1ILZGVz
Y3JpcHRpb24SSgoEdHlwZRgFIAEoDjIxLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEu
SW1wb3J0SWFDRXJyb3IuVHlwZUID4EEDUgR0eXBlEloKCmVycm9yX2NvZGUYBiABKA4yNi5n
b29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkltcG9ydElhQ0Vycm9yLkVycm9yQ29kZUID
4EEDUgllcnJvckNvZGUiPAoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASCwoHSU5WQUxJ
RBABEhEKDU5PVF9TVVBQT1JURUQQAiLqAwoJRXJyb3JDb2RlEhoKFkVSUk9SX0NPREVfVU5T
UEVDSUZJRUQQABIbChdFUlJPUl9DT0RFX1NZTlRBWF9FUlJPUhABEiUKIUVSUk9SX0NPREVf
VU5TVVBQT1JURURfQkxPQ0tfVFlQRRACEiIKHkVSUk9SX0NPREVfVE9QX0xFVkVMX0FUVFJJ
QlVURRADEiEKHUVSUk9SX0NPREVfVU5TVVBQT1JURURfTU9EVUxFEAQSMQotRVJST1JfQ09E
RV9NT0RVTEVfVU5TVVBQT1JURURfQVRUUklCVVRFX0FEREVEEAUSMAosRVJST1JfQ09ERV9N
T0RVTEVfUkVRVUlSRURfQVRUUklCVVRFX1JFTU9WRUQQBhImCiJFUlJPUl9DT0RFX1BBUkFN
RVRFUl9WQUxVRV9JTlZBTElEEAcSKgomRVJST1JfQ09ERV9VTlNVUFBPUlRFRF9WQVJJQUJM
RV9DSEFOR0UQCBIoCiRFUlJPUl9DT0RFX1VOU1VQUE9SVEVEX09VVFBVVF9DSEFOR0UQCRIq
CiZFUlJPUl9DT0RFX1VOU1VQUE9SVEVEX1BST1ZJREVSX0NIQU5HRRAKEicKI0VSUk9SX0NP
REVfVU5TVVBQT1JURURfVEZWQVJfQ0hBTkdFEAsilQEKCUNvZGVSYW5nZRJFCgVzdGFydBgB
IAEoCzIqLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuQ29kZVBvc2l0aW9uQgPgQQNS
BXN0YXJ0EkEKA2VuZBgCIAEoCzIqLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuQ29k
ZVBvc2l0aW9uQgPgQQNSA2VuZCJqCgxDb2RlUG9zaXRpb24SFwoEbGluZRgBIAEoBUID4EED
UgRsaW5lEiQKC2J5dGVfb2Zmc2V0GAIgASgFQgPgQQNSCmJ5dGVPZmZzZXQSGwoGY29sdW1u
GAMgASgFQgPgQQNSBmNvbHVtbkL8AgogY29tLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIu
djFCDkluZ2VzdGlvblByb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vZGVzaWduY2VudGVy
L2FwaXYxL2Rlc2lnbmNlbnRlcnBiO2Rlc2lnbmNlbnRlcnBiqgIcR29vZ2xlLkNsb3VkLkRl
c2lnbkNlbnRlci5WMcoCHEdvb2dsZVxDbG91ZFxEZXNpZ25DZW50ZXJcVjHqAh9Hb29nbGU6
OkNsb3VkOjpEZXNpZ25DZW50ZXI6OlYx6kGeAQoxZGV2ZWxvcGVyY29ubmVjdC5nb29nbGVh
cGlzLmNvbS9HaXRSZXBvc2l0b3J5TGluaxJpcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2Nvbm5lY3Rpb25zL3tjb25uZWN0aW9ufS9naXRSZXBvc2l0b3J5TGlu
a3Mve2dpdF9yZXBvc2l0b3J5X2xpbmt9SsdICgcSBQ4A/gEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEI
EgMVADkKCQoCCCUSAxUAOQoICgEIEgMWAFsKCQoCCAsSAxYAWwoICgEIEgMXACIKCQoCCAoS
AxcAIgoICgEIEgMYAC8KCQoCCAgSAxgALwoICgEIEgMZADkKCQoCCAESAxkAOQoICgEIEgMa
ADkKCQoCCCkSAxoAOQoICgEIEgMbADgKCQoCCC0SAxsAOAoJCgEIEgQcAB8CCgwKBAidCAAS
BBwAHwIKMQoCBAASBCIANQEaJSBEZWZpbmVzIGhvdyB0byBhY2Nlc3MgYSBHaXQgc291cmNl
LgoKCgoDBAABEgMiCBEKOwoEBAACABIDJAI7Gi4gUmVxdWlyZWQuIExvY2F0aW9uIG9mIHRo
ZSBnaXQgcmVwbyB0byBidWlsZC4KCgwKBQQAAgAFEgMkAggKDAoFBAACAAESAyQJDQoMCgUE
AAIAAxIDJBARCgwKBQQAAgAIEgMkEjoKDwoIBAACAAicCAASAyQTOQrlAQoEBAACARIDKQI6
GtcBIE9wdGlvbmFsLiBEaXJlY3RvcnksIHJlbGF0aXZlIHRvIHRoZSBzb3VyY2Ugcm9vdCwg
aW4gd2hpY2ggdG8gcnVuIHRoZQogYnVpbGQuIFRoaXMgbXVzdCBiZSBhIHJlbGF0aXZlIHBh
dGguIElmIGEgc3RlcCdzIGBkaXJgIGlzIHNwZWNpZmllZCBhbmQgaXMKIGFuIGFic29sdXRl
IHBhdGgsIHRoaXMgdmFsdWUgaXMgaWdub3JlZCBmb3IgdGhhdCBzdGVwJ3MgZXhlY3V0aW9u
LgoKDAoFBAACAQUSAykCCAoMCgUEAAIBARIDKQkMCgwKBQQAAgEDEgMpDxAKDAoFBAACAQgS
AykROQoPCggEAAIBCJwIABIDKRI4ClYKBAQAAgISAywCRBpJIE91dHB1dCBvbmx5LiBUaGUg
Y29tbWl0IFNIQSBvZiB0aGUgZ2l0IHJlcG8gZGVkdWNlZCBmcm9tIGdpdmVuIHJlZl90YWcu
CgoMCgUEAAICBRIDLAIICgwKBQQAAgIBEgMsCRMKDAoFBAACAgMSAywWFwoMCgUEAAICCBID
LBhDCg8KCAQAAgIInAgAEgMsGUIKhAEKBAQAAgMSBDACMUIadiBPcHRpb25hbC4gVGhpcyBj
b25maWcgZGVmaW5lcyB0aGUgbG9jYXRpb24gb2YgYSBzb3VyY2UgdGhyb3VnaCBEZXZlbG9w
ZXIKIENvbm5lY3QuIFVzZWQgdG8gYWNjZXNzIHByaXZhdGUgZ2l0IHJlcG9zLgoKDAoFBAAC
AwYSAzACGAoMCgUEAAIDARIDMBkxCgwKBQQAAgMDEgMwNDUKDAoFBAACAwgSAzEGQQoNCgYE
AAIDCAMSAzEHGAoPCggEAAIDCJwIABIDMRpACjsKBAQAAgQSAzQCPhouIFJlcXVpcmVkLiBU
aGUgcmVmZXJlbmNlIHRhZyBvZiB0aGUgZ2l0IHJlcG8uCgoMCgUEAAIEBRIDNAIICgwKBQQA
AgQBEgM0CRAKDAoFBAACBAMSAzQTFAoMCgUEAAIECBIDNBU9Cg8KCAQAAgQInAgAEgM0FjwK
VQoCBAESBDgAPAEaSSBUaGlzIGNvbmZpZyBkZWZpbmVzIHRoZSBsb2NhdGlvbiBvZiBhIHNv
dXJjZSB0aHJvdWdoIERldmVsb3BlciBDb25uZWN0LgoKCgoDBAEBEgM4CB4KjgEKBAQBAgAS
AzsCShqAASBSZXF1aXJlZC4gVGhlIERldmVsb3BlciBDb25uZWN0IEdpdCByZXBvc2l0b3J5
IGxpbmssIGZvcm1hdHRlZCBhcwogYHByb2plY3RzLyovbG9jYXRpb25zLyovY29ubmVjdGlv
bnMvKi9naXRSZXBvc2l0b3J5TGluay8qYC4KCgwKBQQBAgAFEgM7AggKDAoFBAECAAESAzsJ
HAoMCgUEAQIAAxIDOx8gCgwKBQQBAgAIEgM7IUkKDwoIBAECAAicCAASAzsiSAp2CgIEAhIE
QABWARpqIFRoaXMgY29uZmlnIHNwZWNpZmllcyB0aGUgbG9jYXRpb24gb2YgYSBzb3VyY2Ug
KHN1Y2ggYXMgR2l0SHViIG9yIEJpdGJ1Y2tldCkKIHRocm91Z2ggRGV2ZWxvcGVyIENvbm5l
Y3QuCgoKCgMEAgESA0AIJAqQAQoEBAICABIEQwJIBBqBASBSZXF1aXJlZC4gVGhlIERldmVs
b3BlciBDb25uZWN0IEdpdCByZXBvc2l0b3J5IGxpbmssIGZvcm1hdHRlZCBhcwogYHByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29ubmVjdGlvbnMvKi9naXRSZXBvc2l0b3J5TGlua3MvKmAu
CgoMCgUEAgIABRIDQwIICgwKBQQCAgABEgNDCSMKDAoFBAICAAMSA0MmJwoNCgUEAgIACBIE
QyhIAwoPCggEAgIACJwIABIDRAQqCg8KBwQCAgAInwgSBEUERwUKegoEBAICARIDTAJGGm0g
UmVxdWlyZWQuIFRoZSByZWZlcmVuY2UgKGZvciBleGFtcGxlLCBhIGJyYW5jaCwgdGFnLCBv
ciBjb21taXQgU0hBKSBmcm9tCiB3aGljaCB0aGUgY29udGVudCBzaG91bGQgYmUgcmVhZC4K
CgwKBQQCAgEGEgNMAg4KDAoFBAICAQESA0wPGAoMCgUEAgIBAxIDTBscCgwKBQQCAgEIEgNM
HUUKDwoIBAICAQicCAASA0weRArwAQoEBAICAhIDUgI6GuIBIFJlcXVpcmVkLiBUaGUgc3Vi
LWRpcmVjdG9yeSB3aXRoaW4gdGhlIHJlcG9zaXRvcnkgZnJvbSB3aGljaCB0byByZWFkCiBj
b250ZW50LiBUaGUgcGF0aCBtdXN0IGJlIHJlbGF0aXZlIHRvIHRoZSByZXBvc2l0b3J5J3Mg
cm9vdCBzdWNoIGFzCiBkaXIxL2RpcjIuIFRvIHJlYWQgY29udGVudCBmcm9tIHRoZSByb290
IGRpciwgcHJvdmlkZSAiLyIgYXMgdGhlIHZhbHVlIG9mCiB0aGUgZmllbGQuCgoMCgUEAgIC
BRIDUgIICgwKBQQCAgIBEgNSCQwKDAoFBAICAgMSA1IPEAoMCgUEAgICCBIDUhE5Cg8KCAQC
AgIInAgAEgNSEjgKTAoEBAICAxIDVQJMGj8gT3V0cHV0IG9ubHkuIFRoZSBTSEEgb2YgdGhl
IGNvbW1pdCBkZWR1Y2VkIGZyb20gR2l0UmVmZXJlbmNlLgoKDAoFBAICAwUSA1UCCAoMCgUE
AgIDARIDVQkbCgwKBQQCAgMDEgNVHh8KDAoFBAICAwgSA1UgSwoPCggEAgIDCJwIABIDVSFK
Ck8KAgQDEgRZAGkBGkMgVGhlIEdpdCByZWZlcmVuY2UuIENhbiBiZSBhIGNvbW1pdCBTSEEs
IGJyYW5jaCBuYW1lLCBvciB0YWcgbmFtZS4KCgoKAwQDARIDWQgUCmoKBAQDCAASBFwCaAMa
XCBUaGUgcmVmZXJlbmNlIGZyb20gd2hpY2ggdGhlIGNvbnRlbnQgc3VjaCBhcyBJbmZyYXN0
cnVjdHVyZSBhcyBDb2RlIChJYUMpCiBzaG91bGQgYmUgcmVhZC4KCgwKBQQDCAABEgNcCBEK
ZwoEBAMCABIDXwQ/GlogT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRoZSBicmFuY2ggZnJvbSB3
aGljaCBjb250ZW50IHNob3VsZCBiZSByZWFkLgogRm9yIGV4YW1wbGU6ICJtYWluIgoKDAoF
BAMCAAUSA18ECgoMCgUEAwIAARIDXwsRCgwKBQQDAgADEgNfFBUKDAoFBAMCAAgSA18WPgoP
CggEAwIACJwIABIDXxc9CmQKBAQDAgESA2MEQBpXIE9wdGlvbmFsLiBUaGUgcmVmZXJlbmNl
IHRhZyBmcm9tIHdoaWNoIGNvbnRlbnQgc2hvdWxkIGJlIHJlYWQuCiBGb3IgZXhhbXBsZTog
InYxLjIuMyIKCgwKBQQDAgEFEgNjBAoKDAoFBAMCAQESA2MLEgoMCgUEAwIBAxIDYxUWCgwK
BQQDAgEIEgNjFz8KDwoIBAMCAQicCAASA2MYPgpjCgQEAwICEgNnBEMaViBPcHRpb25hbC4g
VGhlIGZ1bGwgU0hBIGhhc2ggb2YgYSBzcGVjaWZpYyBjb21taXQgZnJvbSB3aGljaCBjb250
ZW50CiBzaG91bGQgYmUgcmVhZC4KCgwKBQQDAgIFEgNnBAoKDAoFBAMCAgESA2cLFQoMCgUE
AwICAxIDZxgZCgwKBQQDAgIIEgNnGkIKDwoIBAMCAgicCAASA2cbQQozCgIEBBIEbAB3ARon
IE9wZW4gQ29udGFpbmVyIEluaXRpYXRpdmUgKE9DSSkgcmVwby4KCgoKAwQEARIDbAgPCosB
CgQEBAIAEgNvAjoafiBSZXF1aXJlZC4gUGF0aCB0byBPcGVuIENvbnRhaW5lciBJbml0aWF0
aXZlIChPQ0kpIHJlcG8uCiBFeGFtcGxlOiBvY2k6Ly91cy13ZXN0MS1kb2NrZXIucGtnLmRl
di9ueWFwLXRlc3QvaGVsbS1yZXBvL215LWNoYXJ0CgoMCgUEBAIABRIDbwIICgwKBQQEAgAB
EgNvCQwKDAoFBAQCAAMSA28PEAoMCgUEBAIACBIDbxE5Cg8KCAQEAgAInAgAEgNvEjgKNwoE
BAQCARIDcgI+GiogT3B0aW9uYWwuIFRoZSB2ZXJzaW9uIG9mIHRoZSBoZWxtIGNoYXJ0LgoK
DAoFBAQCAQUSA3ICCAoMCgUEBAIBARIDcgkQCgwKBQQEAgEDEgNyExQKDAoFBAQCAQgSA3IV
PQoPCggEBAIBCJwIABIDchY8CnAKBAQEAgISA3YCSBpjIE9wdGlvbmFsLiBGaWVsZCBmb3Ig
Y29udGFpbmluZyB0aGUgcmVmZXJlbmNlcyB0byB0aGUgc291cmNlIGZyb20gd2hpY2ggdGhl
CiBPQ0kgcmVwbyB3YXMgY3JlYXRlZC4KCgwKBQQEAgIFEgN2AggKDAoFBAQCAgESA3YJGgoM
CgUEBAICAxIDdh0eCgwKBQQEAgIIEgN2H0cKDwoIBAQCAgicCAASA3YgRgpKCgIEBRIEegB9
ARo+IElhQ01vZHVsZSByZXByZXNlbnRzIGEgc2luZ2xlIGluZnJhc3RydWN0dXJlIGFzIGNv
ZGUgbW9kdWxlLgoKCgoDBAUBEgN6CBEKMQoEBAUCABIDfAJGGiQgT3B0aW9uYWwuIFRoZSBm
aWxlcyBpbiB0aGUgbW9kdWxlLgoKDAoFBAUCAAQSA3wCCgoMCgUEBQIABhIDfAsSCgwKBQQF
AgABEgN8ExgKDAoFBAUCAAMSA3wbHAoMCgUEBQIACBIDfB1FCg8KCAQFAgAInAgAEgN8HkQK
SAoCBAYSBoABAIgBARo6IElhQ0ZpbGUgcmVwcmVzZW50cyBhIHNpbmdsZSBpbmZyYXN0cnVj
dHVyZSBhcyBjb2RlIGZpbGUuCgoLCgMEBgESBIABCA8KLwoEBAYCABIEggECOxohIFJlcXVp
cmVkLiBUaGUgbmFtZSBvZiB0aGUgZmlsZS4KCg0KBQQGAgAFEgSCAQIICg0KBQQGAgABEgSC
AQkNCg0KBQQGAgADEgSCARARCg0KBQQGAgAIEgSCARI6ChAKCAQGAgAInAgAEgSCARM5CsAB
CgQEBgIBEgSHAQI+GrEBIE9wdGlvbmFsLiBUaGUgY29udGVudCBvZiB0aGUgZmlsZS4gVGhl
IGNvbnRlbnQgb2YgdGhlIGZpbGUgY2FuIGJlIHJlYWQgYW5kCiBwYXNzZWQgYXMgYSBzdHJp
bmcuIEZvciBleGFtcGxlLCBmb3IgYSBUZXJyYWZvcm0gZmlsZSwgdGhlIGNvbnRlbnQgaXMg
dGhlCiBIQ0wgY29udGVudCBvZiB0aGUgZmlsZS4KCg0KBQQGAgEFEgSHAQIICg0KBQQGAgEB
EgSHAQkQCg0KBQQGAgEDEgSHARMUCg0KBQQGAgEIEgSHARU9ChAKCAQGAgEInAgAEgSHARY8
Cv0DCgIEBxIGoAEA6QEBGu4DIE1lc3NhZ2UgcmVwcmVzZW50aW5nIHRoZSBlcnJvciBlbmNv
dW50ZXJlZCBkdXJpbmcgaW1wb3J0LgogRXhhbXBsZTogQSB2YXJpYWJsZSB3aXRoIG5hbWUg
Im5hbWUiIGlzIGV4cGVjdGVkIHRvIGJlIG9mIHR5cGUgc3RyaW5nLCBidXQgaXMKIHByb3Zp
ZGVkIGFzIG51bWJlciwgaW5zaWRlIGEgbW9kdWxlIG5hbWVkICJteV9tb2R1bGUiLgogewog
cmVzb3VyY2VfYWRkcmVzczogIm1vZHVsZS5teV9tb2R1bGUubmFtZSIKIGZpbGU6ICJnczov
L215X2J1Y2tldC9tYWluLnRmIgogcmFuZ2U6IHsKIHN0YXJ0OiB7CiBsaW5lOiAyCiBieXRl
X29mZnNldDogMQogY29sdW1uOiAyCiB9CiBlbmQ6IHsKIGxpbmU6IDIKIGJ5dGVfb2Zmc2V0
OiAxMAogY29sdW1uOiAxMAogfQogfQogZGVzY3JpcHRpb246ICJFcnJvciBwYXJzaW5nIGZp
ZWxkOiBcIm5hbWVcIi4gRXhwZWN0ZWQgdHlwZSBcInN0cmluZ1wiIGJ1dCBnb3QKIFwibnVt
YmVyXCIuIgogdHlwZTogSU5WQUxJRAogfQoKCwoDBAcBEgSgAQgWCiQKBAQHBAASBqIBAq8B
AxoUIFRoZSB0eXBlIG9mIGVycm9yLgoKDQoFBAcEAAESBKIBBwsKGgoGBAcEAAIAEgSkAQQZ
GgogRGVmYXVsdC4KCg8KBwQHBAACAAESBKQBBBQKDwoHBAcEAAIAAhIEpAEXGAqeAQoGBAcE
AAIBEgSpAQQQGo0BIFRoZSBjaGFuZ2UgaXMgaW52YWxpZC4KIEV4YW1wbGU6IGEgc3RyaW5n
IHZhbHVlIHByb3ZpZGVkIGZvciBhIG51bWJlciBpbnB1dCBwYXJhbWV0ZXIgdHlwZSwKIHdo
aWNoIHdvdWxkIGJlIGNhdWdodCBieSBUZXJyYWZvcm0gdmFsaWRhdGlvbi4KCg8KBwQHBAAC
AQESBKkBBAsKDwoHBAcEAAIBAhIEqQEODwqgAQoGBAcEAAICEgSuAQQWGo8BIFRoZSBjaGFu
Z2UgaXMgbm90IHN1cHBvcnRlZC4KIEV4YW1wbGU6IGEgdXNlciBkaXJlY3RseSBhZGRpbmcg
YSBUZXJyYWZvcm0gcmVzb3VyY2UgaW4gbWFpbi50ZgogdGhhdCBEZXNpZ24gQ2VudGVyIGRv
ZXMgbm90IHN1cHBvcnQgaW1wb3J0aW5nLgoKDwoHBAcEAAICARIErgEEEQoPCgcEBwQAAgIC
EgSuARQVCkcKBAQHBAESBrIBAtYBAxo3IFNwZWNpZmljIGVycm9yIGNvZGUgZm9yIFVJIGFu
ZCBwcm9ncmFtbWF0aWMgaGFuZGxpbmcuCgoNCgUEBwQBARIEsgEHEAoaCgYEBwQBAgASBLQB
BB8aCiBEZWZhdWx0LgoKDwoHBAcEAQIAARIEtAEEGgoPCgcEBwQBAgACEgS0AR0eCkoKBgQH
BAECARIEtwEEIBo6IEhDTCBTeW50YXggZXJyb3JzIChlLmcuIHVuY2xvc2VkIGJsb2Nrcywg
YmFkIGNoYXJhY3RlcnMpCgoPCgcEBwQBAgEBEgS3AQQbCg8KBwQHBAECAQISBLcBHh8KRgoG
BAcEAQICEgS6AQQqGjYgVG9wLWxldmVsIGJsb2NrIGlzIGUuZy4gInJlc291cmNlIiwgImRh
dGEiLCAibG9jYWxzIgoKDwoHBAcEAQICARIEugEEJQoPCgcEBwQBAgICEgS6ASgpCj4KBgQH
BAECAxIEvQEEJxouIEF0dHJpYnV0ZXMgZGVmaW5lZCBvdXRzaWRlIG9mIGFsbG93ZWQgYmxv
Y2tzCgoPCgcEBwQBAgMBEgS9AQQiCg8KBwQHBAECAwISBL0BJSYKLwoGBAcEAQIEEgTAAQQm
Gh8gTW9kdWxlIG5vdCBwcmVzZW50IGluIGNhdGFsb2cKCg8KBwQHBAECBAESBMABBCEKDwoH
BAcEAQIEAhIEwAEkJQpUCgYEBwQBAgUSBMMBBDYaRCBBdHRyaWJ1dGUgZGVmaW5lZCBpbnNp
ZGUgbW9kdWxlIHRoYXQgaXMgbm90IGluIHRoZSBzaGFyZWQgdGVtcGxhdGUKCg8KBwQHBAEC
BQESBMMBBDEKDwoHBAcEAQIFAhIEwwE0NQpTCgYEBwQBAgYSBMYBBDUaQyBNYW5kYXRvcnkg
YXR0cmlidXRlIG9mIHNoYXJlZCB0ZW1wbGF0ZSBpcyBtaXNzaW5nIGluIG1vZHVsZSBibG9j
awoKDwoHBAcEAQIGARIExgEEMAoPCgcEBwQBAgYCEgTGATM0ClAKBgQHBAECBxIEyQEEKxpA
IFZhbHVlIGZhaWxzIHNoYXJlZCB0ZW1wbGF0ZSBzY2hlbWEgY2hlY2tzIChyZWdleCwgcmFu
Z2UsIGV0Yy4pCgoPCgcEBwQBAgcBEgTJAQQmCg8KBwQHBAECBwISBMkBKSoKTgoGBAcEAQII
EgTMAQQvGj4gVmFyaWFibGUgaW4gdmFyaWFibGVzLnRmIGlzIGFkZGVkLCByZW1vdmVkIG9y
IHNjaGVtYSBjaGFuZ2VkCgoPCgcEBwQBAggBEgTMAQQqCg8KBwQHBAECCAISBMwBLS4KSgoG
BAcEAQIJEgTPAQQtGjogT3V0cHV0IGluIG91dHB1dHMudGYgaXMgYWRkZWQsIHJlbW92ZWQg
b3Igc2NoZW1hIGNoYW5nZWQKCg8KBwQHBAECCQESBM8BBCgKDwoHBAcEAQIJAhIEzwErLApS
CgYEBwQBAgoSBNIBBDAaQiBQcm92aWRlciBpbiBwcm92aWRlcnMudGYgaGFzIGFkZGVkIGJs
b2NrcyBvciBtb2RpZmllZCBhdHRyaWJ1dGVzCgoPCgcEBwQBAgoBEgTSAQQqCg8KBwQHBAEC
CgISBNIBLS8KSgoGBAcEAQILEgTVAQQtGjogVmFsdWUgbW9kaWZpZWQgZm9yIHZhcmlhYmxl
cyBkZWZpbmVkIGluIHRlcnJhZm9ybS50ZnZhcnMKCg8KBwQHBAECCwESBNUBBCcKDwoHBAcE
AQILAhIE1QEqLAo/CgQEBwIAEgTZAQJKGjEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBh
ZGRyZXNzIG9mIHRoZSBlcnJvci4KCg0KBQQHAgAFEgTZAQIICg0KBQQHAgABEgTZAQkZCg0K
BQQHAgADEgTZARwdCg0KBQQHAgAIEgTZAR5JChAKCAQHAgAInAgAEgTZAR9ICkMKBAQHAgES
BNwBAj4aNSBPdXRwdXQgb25seS4gVGhlIGZpbGUgd2hlcmUgdGhlIGVycm9yIGhhcyBvY2N1
cnJlZC4KCg0KBQQHAgEFEgTcAQIICg0KBQQHAgEBEgTcAQkNCg0KBQQHAgEDEgTcARARCg0K
BQQHAgEIEgTcARI9ChAKCAQHAgEInAgAEgTcARM8CkYKBAQHAgISBN8BAkIaOCBPdXRwdXQg
b25seS4gVGhlIGNvZGUgcG9ydGlvbiB3aGVyZSB0aGlzIGVycm9yIG9jY3Vycy4KCg0KBQQH
AgIGEgTfAQILCg0KBQQHAgIBEgTfAQwRCg0KBQQHAgIDEgTfARQVCg0KBQQHAgIIEgTfARZB
ChAKCAQHAgIInAgAEgTfARdACjoKBAQHAgMSBOIBAkUaLCBPdXRwdXQgb25seS4gVGhlIGRl
c2NyaXB0aW9uIG9mIHRoZSBlcnJvci4KCg0KBQQHAgMFEgTiAQIICg0KBQQHAgMBEgTiAQkU
Cg0KBQQHAgMDEgTiARcYCg0KBQQHAgMIEgTiARlEChAKCAQHAgMInAgAEgTiARpDCi8KBAQH
AgQSBOUBAjwaISBPdXRwdXQgb25seS4gVGhlIHR5cGUgb2YgZXJyb3IuCgoNCgUEBwIEBhIE
5QECBgoNCgUEBwIEARIE5QEHCwoNCgUEBwIEAxIE5QEODwoNCgUEBwIECBIE5QEQOwoQCggE
BwIECJwIABIE5QEROgpGCgQEBwIFEgToAQJHGjggT3V0cHV0IG9ubHkuIFNwZWNpZmljIGVy
cm9yIGNvZGUgZm9yIHRoZSBpbXBvcnQgZXJyb3IuCgoNCgUEBwIFBhIE6AECCwoNCgUEBwIF
ARIE6AEMFgoNCgUEBwIFAxIE6AEZGgoNCgUEBwIFCBIE6AEbRgoQCggEBwIFCJwIABIE6AEc
RQo3CgIECBIG7AEA8gEBGikgQ29kZVJhbmdlIHJlcHJlc2VudHMgYSBwb3J0aW9uIG9mIGNv
ZGUuCgoLCgMECAESBOwBCBEKLAoEBAgCABIE7gECRRoeIE91dHB1dCBvbmx5LiBTdGFydCBw
b3NpdGlvbi4KCg0KBQQIAgAGEgTuAQIOCg0KBQQIAgABEgTuAQ8UCg0KBQQIAgADEgTuARcY
Cg0KBQQIAgAIEgTuARlEChAKCAQIAgAInAgAEgTuARpDCioKBAQIAgESBPEBAkMaHCBPdXRw
dXQgb25seS4gRW5kIHBvc2l0aW9uLgoKDQoFBAgCAQYSBPEBAg4KDQoFBAgCAQESBPEBDxIK
DQoFBAgCAQMSBPEBFRYKDQoFBAgCAQgSBPEBF0IKEAoIBAgCAQicCAASBPEBGEEKOAoCBAkS
BvUBAP4BARoqIENvZGVQb3NpdGlvbiByZXByZXNlbnRzIGEgY29kZSBsb2NhdGlvbi4KCgsK
AwQJARIE9QEIFApLCgQECQIAEgT3AQI9Gj0gT3V0cHV0IG9ubHkuIE9uZS1iYXNlZCBsaW5l
IGNvdW50IG9mIHRoZSByZWxldmFudCBwb3NpdGlvbi4KCg0KBQQJAgAFEgT3AQIHCg0KBQQJ
AgABEgT3AQgMCg0KBQQJAgADEgT3AQ8QCg0KBQQJAgAIEgT3ARE8ChAKCAQJAgAInAgAEgT3
ARI7CjgKBAQJAgESBPoBAkQaKiBPdXRwdXQgb25seS4gQnl0ZSBvZmZzZXQgaW4gdGhlIGNv
bnRlbnQuCgoNCgUECQIBBRIE+gECBwoNCgUECQIBARIE+gEIEwoNCgUECQIBAxIE+gEWFwoN
CgUECQIBCBIE+gEYQwoQCggECQIBCJwIABIE+gEZQgpNCgQECQICEgT9AQI/Gj8gT3V0cHV0
IG9ubHkuIE9uZS1iYXNlZCBjb2x1bW4gY291bnQgb2YgdGhlIHJlbGV2YW50IHBvc2l0aW9u
LgoKDQoFBAkCAgUSBP0BAgcKDQoFBAkCAgESBP0BCA4KDQoFBAkCAgMSBP0BERIKDQoFBAkC
AggSBP0BEz4KEAoIBAkCAgicCAASBP0BFD1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::Ingestion::GitSource ===
    # Fields for GitSource
    # Field: repo Type: 9 ()
    # Field: dir Type: 9 ()
    # Field: commit_sha Type: 9 ()
    # Field: developer_connect_config Type: 11 (.google.cloud.designcenter.v1.DeveloperConnectConfig)
    # Field: ref_tag Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectConfig ===
    # Fields for DeveloperConnectConfig
    # Field: git_repository_link Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig ===
    # Fields for DeveloperConnectSourceConfig
    # Field: developer_connect_repo_uri Type: 9 ()
    # Field: reference Type: 11 (.google.cloud.designcenter.v1.GitReference)
    # Field: dir Type: 9 ()
    # Field: fetched_commit_sha Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Ingestion::GitReference ===
    # Fields for GitReference
    # Field: branch Type: 9 ()
    # Field: ref_tag Type: 9 ()
    # Field: commit_sha Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Ingestion::OciRepo ===
    # Fields for OciRepo
    # Field: uri Type: 9 ()
    # Field: version Type: 9 ()
    # Field: module_source_uri Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Ingestion::IaCModule ===
    # Fields for IaCModule
    # Field: files Type: 11 (.google.cloud.designcenter.v1.IaCFile)

# === Message: Google::Cloud::Designcenter::V1::Ingestion::IaCFile ===
    # Fields for IaCFile
    # Field: name Type: 9 ()
    # Field: content Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Ingestion::ImportIaCError ===
    # Fields for ImportIaCError
    # Field: resource_address Type: 9 ()
    # Field: file Type: 9 ()
    # Field: range Type: 11 (.google.cloud.designcenter.v1.CodeRange)
    # Field: description Type: 9 ()
    # Field: type Type: 14 (.google.cloud.designcenter.v1.ImportIaCError.Type)
    # Field: error_code Type: 14 (.google.cloud.designcenter.v1.ImportIaCError.ErrorCode)

# Enum: ImportIaCError::Type
our $ImportIaCError_TYPE_UNSPECIFIED = 0;
our $ImportIaCError_INVALID = 1;
our $ImportIaCError_NOT_SUPPORTED = 2;

# Enum: ImportIaCError::ErrorCode
our $ImportIaCError_ERROR_CODE_UNSPECIFIED = 0;
our $ImportIaCError_ERROR_CODE_SYNTAX_ERROR = 1;
our $ImportIaCError_ERROR_CODE_UNSUPPORTED_BLOCK_TYPE = 2;
our $ImportIaCError_ERROR_CODE_TOP_LEVEL_ATTRIBUTE = 3;
our $ImportIaCError_ERROR_CODE_UNSUPPORTED_MODULE = 4;
our $ImportIaCError_ERROR_CODE_MODULE_UNSUPPORTED_ATTRIBUTE_ADDED = 5;
our $ImportIaCError_ERROR_CODE_MODULE_REQUIRED_ATTRIBUTE_REMOVED = 6;
our $ImportIaCError_ERROR_CODE_PARAMETER_VALUE_INVALID = 7;
our $ImportIaCError_ERROR_CODE_UNSUPPORTED_VARIABLE_CHANGE = 8;
our $ImportIaCError_ERROR_CODE_UNSUPPORTED_OUTPUT_CHANGE = 9;
our $ImportIaCError_ERROR_CODE_UNSUPPORTED_PROVIDER_CHANGE = 10;
our $ImportIaCError_ERROR_CODE_UNSUPPORTED_TFVAR_CHANGE = 11;

# === Message: Google::Cloud::Designcenter::V1::Ingestion::CodeRange ===
    # Fields for CodeRange
    # Field: start Type: 11 (.google.cloud.designcenter.v1.CodePosition)
    # Field: end Type: 11 (.google.cloud.designcenter.v1.CodePosition)

# === Message: Google::Cloud::Designcenter::V1::Ingestion::CodePosition ===
    # Fields for CodePosition
    # Field: line Type: 5 ()
    # Field: byte_offset Type: 5 ()
    # Field: column Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::Ingestion - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/ingestion.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::Ingestion;

    my $msg = Google::Cloud::Designcenter::V1::Ingestion::GitSource->new({
        repo => $repo,
        dir => $dir,
        commit_sha => $commit_sha,
        developer_connect_config => $developer_connect_config,
    });

    # Read or update a field
    my $val = $msg->repo();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::Ingestion::GitSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/ingestion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::Ingestion::GitSource

Defines how to access a Git source.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repo() >> / C<< $msg->repo($value) >>

Type: C<String>

Required. Location of the git repo to build.

=item * C<< $msg->dir() >> / C<< $msg->dir($value) >>

Type: C<String>

Optional. Directory, relative to the source root, in which to run the
build. This must be a relative path. If a step's `dir` is specified and is
an absolute path, this value is ignored for that step's execution.

=item * C<< $msg->commit_sha() >> / C<< $msg->commit_sha($value) >>

Type: C<String>

Output only. The commit SHA of the git repo deduced from given ref_tag.

=item * C<< $msg->developer_connect_config() >> / C<< $msg->developer_connect_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectConfig>)

Optional. This config defines the location of a source through Developer
Connect. Used to access private git repos.

=item * C<< $msg->ref_tag() >> / C<< $msg->ref_tag($value) >>

Type: C<String>

Required. The reference tag of the git repo.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectConfig

This config defines the location of a source through Developer Connect.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->git_repository_link() >> / C<< $msg->git_repository_link($value) >>

Type: C<String>

Required. The Developer Connect Git repository link, formatted as
`projects/*/locations/*/connections/*/gitRepositoryLink/*`.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig

This config specifies the location of a source (such as GitHub or Bitbucket)
through Developer Connect.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->developer_connect_repo_uri() >> / C<< $msg->developer_connect_repo_uri($value) >>

Type: C<String>

Required. The Developer Connect Git repository link, formatted as
`projects/*/locations/*/connections/*/gitRepositoryLinks/*`.

=item * C<< $msg->reference() >> / C<< $msg->reference($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::GitReference>)

Required. The reference (for example, a branch, tag, or commit SHA) from
which the content should be read.

=item * C<< $msg->dir() >> / C<< $msg->dir($value) >>

Type: C<String>

Required. The sub-directory within the repository from which to read
content. The path must be relative to the repository's root such as
dir1/dir2. To read content from the root dir, provide "/" as the value of
the field.

=item * C<< $msg->fetched_commit_sha() >> / C<< $msg->fetched_commit_sha($value) >>

Type: C<String>

Output only. The SHA of the commit deduced from GitReference.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::GitReference

The Git reference. Can be a commit SHA, branch name, or tag name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->branch() >> / C<< $msg->branch($value) >>

Type: C<String>

Optional. The name of the branch from which content should be read.
For example: "main"

=item * C<< $msg->ref_tag() >> / C<< $msg->ref_tag($value) >>

Type: C<String>

Optional. The reference tag from which content should be read.
For example: "v1.2.3"

=item * C<< $msg->commit_sha() >> / C<< $msg->commit_sha($value) >>

Type: C<String>

Optional. The full SHA hash of a specific commit from which content
should be read.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::OciRepo

Open Container Initiative (OCI) repo.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. Path to Open Container Initiative (OCI) repo.
Example: oci://us-west1-docker.pkg.dev/nyap-test/helm-repo/my-chart

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. The version of the helm chart.

=item * C<< $msg->module_source_uri() >> / C<< $msg->module_source_uri($value) >>

Type: C<String>

Optional. Field for containing the references to the source from which the
OCI repo was created.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::IaCModule

IaCModule represents a single infrastructure as code module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::IaCFile>)

Optional. The files in the module.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::IaCFile

IaCFile represents a single infrastructure as code file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the file.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Optional. The content of the file. The content of the file can be read and
passed as a string. For example, for a Terraform file, the content is the
HCL content of the file.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::ImportIaCError

Message representing the error encountered during import.
Example: A variable with name "name" is expected to be of type string, but is
provided as number, inside a module named "my_module".
{
resource_address: "module.my_module.name"
file: "gs://my_bucket/main.tf"
range: {
start: {
line: 2
byte_offset: 1
column: 2
}
end: {
line: 2
byte_offset: 10
column: 10
}
}
description: "Error parsing field: \"name\". Expected type \"string\" but got
\"number\"."
type: INVALID
}

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_address() >> / C<< $msg->resource_address($value) >>

Type: C<String>

Output only. The resource address of the error.

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<String>

Output only. The file where the error has occurred.

=item * C<< $msg->range() >> / C<< $msg->range($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::CodeRange>)

Output only. The code portion where this error occurs.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the error.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::ImportIaCError::Type>)

Output only. The type of error.

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::ImportIaCError::ErrorCode>)

Output only. Specific error code for the import error.

=back

=head3 Enum: ImportIaCError::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<INVALID> => C<1>

=item * C<NOT_SUPPORTED> => C<2>

=back

=head3 Enum: ImportIaCError::ErrorCode

=over 4

=item * C<ERROR_CODE_UNSPECIFIED> => C<0>

=item * C<ERROR_CODE_SYNTAX_ERROR> => C<1>

=item * C<ERROR_CODE_UNSUPPORTED_BLOCK_TYPE> => C<2>

=item * C<ERROR_CODE_TOP_LEVEL_ATTRIBUTE> => C<3>

=item * C<ERROR_CODE_UNSUPPORTED_MODULE> => C<4>

=item * C<ERROR_CODE_MODULE_UNSUPPORTED_ATTRIBUTE_ADDED> => C<5>

=item * C<ERROR_CODE_MODULE_REQUIRED_ATTRIBUTE_REMOVED> => C<6>

=item * C<ERROR_CODE_PARAMETER_VALUE_INVALID> => C<7>

=item * C<ERROR_CODE_UNSUPPORTED_VARIABLE_CHANGE> => C<8>

=item * C<ERROR_CODE_UNSUPPORTED_OUTPUT_CHANGE> => C<9>

=item * C<ERROR_CODE_UNSUPPORTED_PROVIDER_CHANGE> => C<10>

=item * C<ERROR_CODE_UNSUPPORTED_TFVAR_CHANGE> => C<11>

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::CodeRange

CodeRange represents a portion of code.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::CodePosition>)

Output only. Start position.

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::CodePosition>)

Output only. End position.

=back

=head2 Google::Cloud::Designcenter::V1::Ingestion::CodePosition

CodePosition represents a code location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->line() >> / C<< $msg->line($value) >>

Type: C<Int32>

Output only. One-based line count of the relevant position.

=item * C<< $msg->byte_offset() >> / C<< $msg->byte_offset($value) >>

Type: C<Int32>

Output only. Byte offset in the content.

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<Int32>

Output only. One-based column count of the relevant position.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::Ingestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
