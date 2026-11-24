package Google::Cloud::Backupdr::V1::BackupvaultDisk;

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
    eval { require Google::Cloud::Backupdr::V1::BackupvaultGce };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYmFja3VwdmF1bHRfZGlzay5wcm90bxIYZ29v
Z2xlLmNsb3VkLmJhY2t1cGRyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2xvdWQvYmFja3VwZHIvdjEv
YmFja3VwdmF1bHRfZ2NlLnByb3RvIk8KFURpc2tUYXJnZXRFbnZpcm9ubWVudBIdCgdwcm9q
ZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSFwoEem9uZRgCIAEoCUID4EECUgR6b25lIoMBChtS
ZWdpb25EaXNrVGFyZ2V0RW52aXJvbm1lbnQSHQoHcHJvamVjdBgBIAEoCUID4EECUgdwcm9q
ZWN0EhsKBnJlZ2lvbhgCIAEoCUID4EECUgZyZWdpb24SKAoNcmVwbGljYV96b25lcxgDIAMo
CUID4EECUgxyZXBsaWNhWm9uZXMiuw0KFURpc2tSZXN0b3JlUHJvcGVydGllcxIcCgRuYW1l
GAEgASgJQgPgQQJIAFIEbmFtZYgBARIqCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBSAFSC2Rl
c2NyaXB0aW9uiAEBEiEKB3NpemVfZ2IYAyABKANCA+BBAkgCUgZzaXplR2KIAQESHwoIbGlj
ZW5zZXMYBCADKAlCA+BBAVIIbGljZW5zZXMSVwoQZ3Vlc3Rfb3NfZmVhdHVyZRgFIAMoCzIo
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5HdWVzdE9zRmVhdHVyZUID4EEBUg5ndWVzdE9z
RmVhdHVyZRJpChNkaXNrX2VuY3J5cHRpb25fa2V5GAYgASgLMi8uZ29vZ2xlLmNsb3VkLmJh
Y2t1cGRyLnYxLkN1c3RvbWVyRW5jcnlwdGlvbktleUID4EEBSANSEWRpc2tFbmNyeXB0aW9u
S2V5iAEBEkMKGXBoeXNpY2FsX2Jsb2NrX3NpemVfYnl0ZXMYByABKANCA+BBAUgEUhZwaHlz
aWNhbEJsb2NrU2l6ZUJ5dGVziAEBEjMKEHByb3Zpc2lvbmVkX2lvcHMYCCABKANCA+BBAUgF
Ug9wcm92aXNpb25lZElvcHOIAQESPwoWcHJvdmlzaW9uZWRfdGhyb3VnaHB1dBgJIAEoA0ID
4EEBSAZSFXByb3Zpc2lvbmVkVGhyb3VnaHB1dIgBARJIChtlbmFibGVfY29uZmlkZW50aWFs
X2NvbXB1dGUYCiABKAhCA+BBAUgHUhllbmFibGVDb25maWRlbnRpYWxDb21wdXRliAEBElIK
DHN0b3JhZ2VfcG9vbBgLIAEoCUIq4EEB+kEkCiJjb21wdXRlLmdvb2dsZWFwaXMuY29tL1N0
b3JhZ2VQb29sSAhSC3N0b3JhZ2VQb29siAEBEmUKC2FjY2Vzc19tb2RlGAwgASgOMjouZ29v
Z2xlLmNsb3VkLmJhY2t1cGRyLnYxLkRpc2tSZXN0b3JlUHJvcGVydGllcy5BY2Nlc3NNb2Rl
QgPgQQFICVIKYWNjZXNzTW9kZYgBARJqCgxhcmNoaXRlY3R1cmUYDiABKA4yPC5nb29nbGUu
Y2xvdWQuYmFja3VwZHIudjEuRGlza1Jlc3RvcmVQcm9wZXJ0aWVzLkFyY2hpdGVjdHVyZUID
4EEBSApSDGFyY2hpdGVjdHVyZYgBARIsCg9yZXNvdXJjZV9wb2xpY3kYDyADKAlCA+BBAVIO
cmVzb3VyY2VQb2xpY3kSHAoEdHlwZRgQIAEoCUID4EECSAtSBHR5cGWIAQESWAoGbGFiZWxz
GBEgAygLMjsuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkRpc2tSZXN0b3JlUHJvcGVydGll
cy5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSgQEKFXJlc291cmNlX21hbmFnZXJfdGFncxgS
IAMoCzJILmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5EaXNrUmVzdG9yZVByb3BlcnRpZXMu
UmVzb3VyY2VNYW5hZ2VyVGFnc0VudHJ5QgPgQQFSE3Jlc291cmNlTWFuYWdlclRhZ3MaOQoL
TGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4
ARpGChhSZXNvdXJjZU1hbmFnZXJUYWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFs
dWUYAiABKAlSBXZhbHVlOgI4ASJMCgpBY2Nlc3NNb2RlEhUKEVJFQURfV1JJVEVfU0lOR0xF
EAASEwoPUkVBRF9XUklURV9NQU5ZEAESEgoOUkVBRF9PTkxZX01BTlkQAiJDCgxBcmNoaXRl
Y3R1cmUSHAoYQVJDSElURUNUVVJFX1VOU1BFQ0lGSUVEEAASCgoGWDg2XzY0EAESCQoFQVJN
NjQQAkIHCgVfbmFtZUIOCgxfZGVzY3JpcHRpb25CCgoIX3NpemVfZ2JCFgoUX2Rpc2tfZW5j
cnlwdGlvbl9rZXlCHAoaX3BoeXNpY2FsX2Jsb2NrX3NpemVfYnl0ZXNCEwoRX3Byb3Zpc2lv
bmVkX2lvcHNCGQoXX3Byb3Zpc2lvbmVkX3Rocm91Z2hwdXRCHgocX2VuYWJsZV9jb25maWRl
bnRpYWxfY29tcHV0ZUIPCg1fc3RvcmFnZV9wb29sQg4KDF9hY2Nlc3NfbW9kZUIPCg1fYXJj
aGl0ZWN0dXJlQgcKBV90eXBlIuoEChREaXNrQmFja3VwUHJvcGVydGllcxIlCgtkZXNjcmlw
dGlvbhgBIAEoCUgAUgtkZXNjcmlwdGlvbogBARIaCghsaWNlbnNlcxgCIAMoCVIIbGljZW5z
ZXMSUgoQZ3Vlc3Rfb3NfZmVhdHVyZRgDIAMoCzIoLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MS5HdWVzdE9zRmVhdHVyZVIOZ3Vlc3RPc0ZlYXR1cmUSZAoMYXJjaGl0ZWN0dXJlGAQgASgO
MjsuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkRpc2tCYWNrdXBQcm9wZXJ0aWVzLkFyY2hp
dGVjdHVyZUgBUgxhcmNoaXRlY3R1cmWIAQESFwoEdHlwZRgFIAEoCUgCUgR0eXBliAEBEhwK
B3NpemVfZ2IYBiABKANIA1IGc2l6ZUdiiAEBEhsKBnJlZ2lvbhgHIAEoCUgEUgZyZWdpb26I
AQESFwoEem9uZRgIIAEoCUgFUgR6b25liAEBEiMKDXJlcGxpY2Ffem9uZXMYCSADKAlSDHJl
cGxpY2Fab25lcxIkCgtzb3VyY2VfZGlzaxgKIAEoCUgGUgpzb3VyY2VEaXNriAEBIkMKDEFy
Y2hpdGVjdHVyZRIcChhBUkNISVRFQ1RVUkVfVU5TUEVDSUZJRUQQABIKCgZYODZfNjQQARIJ
CgVBUk02NBACQg4KDF9kZXNjcmlwdGlvbkIPCg1fYXJjaGl0ZWN0dXJlQgcKBV90eXBlQgoK
CF9zaXplX2diQgkKB19yZWdpb25CBwoFX3pvbmVCDgoMX3NvdXJjZV9kaXNrIn0KGERpc2tE
YXRhU291cmNlUHJvcGVydGllcxISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9u
GAIgASgJUgtkZXNjcmlwdGlvbhISCgR0eXBlGAMgASgJUgR0eXBlEhcKB3NpemVfZ2IYBCAB
KANSBnNpemVHYkKoAgocY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MUIUQmFja3VwdmF1
bHREaXNrUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby9iYWNrdXBkci9hcGl2MS9iYWNr
dXBkcnBiO2JhY2t1cGRycGKqAhhHb29nbGUuQ2xvdWQuQmFja3VwRFIuVjHKAhhHb29nbGVc
Q2xvdWRcQmFja3VwRFJcVjHqAhtHb29nbGU6OkNsb3VkOjpCYWNrdXBEUjo6VjHqQWEKImNv
bXB1dGUuZ29vZ2xlYXBpcy5jb20vU3RvcmFnZVBvb2wSO3Byb2plY3RzL3twcm9qZWN0fS96
b25lcy97em9uZX0vc3RvcmFnZVBvb2xzL3tzdG9yYWdlX3Bvb2x9SutBCgcSBQ4A4gEBCrwE
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
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoJCgIDAhIDFAA4CggKAQgSAxYANQoJCgIIJRIDFgA1CggKAQgSAxcATwoJ
CgIICxIDFwBPCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkANQoJCgIICBIDGQA1CggK
AQgSAxoANQoJCgIIARIDGgA1CggKAQgSAxsANQoJCgIIKRIDGwA1CggKAQgSAxwANAoJCgII
LRIDHAA0CgkKAQgSBB0AIAIKDAoECJ0IABIEHQAgAgpTCgIEABIEIwApARpHIERpc2tUYXJn
ZXRFbnZpcm9ubWVudCByZXByZXNlbnRzIHRoZSB0YXJnZXQgZW52aXJvbm1lbnQgZm9yIHRo
ZSBkaXNrLgoKCgoDBAABEgMjCB0KNQoEBAACABIDJQI+GiggUmVxdWlyZWQuIFRhcmdldCBw
cm9qZWN0IGZvciB0aGUgZGlzay4KCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJEAoMCgUE
AAIAAxIDJRMUCgwKBQQAAgAIEgMlFT0KDwoIBAACAAicCAASAyUWPAoyCgQEAAIBEgMoAjsa
JSBSZXF1aXJlZC4gVGFyZ2V0IHpvbmUgZm9yIHRoZSBkaXNrLgoKDAoFBAACAQUSAygCCAoM
CgUEAAIBARIDKAkNCgwKBQQAAgEDEgMoEBEKDAoFBAACAQgSAygSOgoPCggEAAIBCJwIABID
KBM5ClkKAgQBEgQsADUBGk0gUmVnaW9uRGlza1RhcmdldEVudmlyb25tZW50IHJlcHJlc2Vu
dHMgdGhlIHRhcmdldCBlbnZpcm9ubWVudCBmb3IgdGhlIGRpc2suCgoKCgMEAQESAywIIwo1
CgQEAQIAEgMuAj4aKCBSZXF1aXJlZC4gVGFyZ2V0IHByb2plY3QgZm9yIHRoZSBkaXNrLgoK
DAoFBAECAAUSAy4CCAoMCgUEAQIAARIDLgkQCgwKBQQBAgADEgMuExQKDAoFBAECAAgSAy4V
PQoPCggEAQIACJwIABIDLhY8CjQKBAQBAgESAzECPRonIFJlcXVpcmVkLiBUYXJnZXQgcmVn
aW9uIGZvciB0aGUgZGlzay4KCgwKBQQBAgEFEgMxAggKDAoFBAECAQESAzEJDwoMCgUEAQIB
AxIDMRITCgwKBQQBAgEIEgMxFDwKDwoIBAECAQicCAASAzEVOwpHCgQEAQICEgM0Ak0aOiBS
ZXF1aXJlZC4gVGFyZ2V0IFVSTHMgb2YgdGhlIHJlcGxpY2Egem9uZXMgZm9yIHRoZSBkaXNr
LgoKDAoFBAECAgQSAzQCCgoMCgUEAQICBRIDNAsRCgwKBQQBAgIBEgM0Eh8KDAoFBAECAgMS
AzQiIwoMCgUEAQICCBIDNCRMCg8KCAQBAgIInAgAEgM0JUsKUQoCBAISBTgAoAEBGkQgRGlz
a1Jlc3RvcmVQcm9wZXJ0aWVzIHJlcHJlc2VudHMgdGhlIHByb3BlcnRpZXMgb2YgYSBEaXNr
IHJlc3RvcmUuCgoKCgMEAgESAzgIHQo3CgQEAgQAEgQ6AkYDGikgVGhlIHN1cHBvcnRlZCBh
Y2Nlc3MgbW9kZXMgb2YgdGhlIGRpc2suCgoMCgUEAgQAARIDOgcRCmcKBgQCBAACABIDPQQa
GlggVGhlIGRlZmF1bHQgQWNjZXNzTW9kZSwgbWVhbnMgdGhlIGRpc2sgY2FuIGJlIGF0dGFj
aGVkIHRvIHNpbmdsZSBpbnN0YW5jZQogaW4gUlcgbW9kZS4KCg4KBwQCBAACAAESAz0EFQoO
CgcEAgQAAgACEgM9GBkKYQoGBAIEAAIBEgNBBBgaUiBUaGUgQWNjZXNzTW9kZSBtZWFucyB0
aGUgZGlzayBjYW4gYmUgYXR0YWNoZWQgdG8gbXVsdGlwbGUgaW5zdGFuY2VzIGluIFJXCiBt
b2RlLgoKDgoHBAIEAAIBARIDQQQTCg4KBwQCBAACAQISA0EWFwphCgYEAgQAAgISA0UEFxpS
IFRoZSBBY2Nlc3NNb2RlIG1lYW5zIHRoZSBkaXNrIGNhbiBiZSBhdHRhY2hlZCB0byBtdWx0
aXBsZSBpbnN0YW5jZXMgaW4gUk8KIG1vZGUuCgoOCgcEAgQAAgIBEgNFBBIKDgoHBAIEAAIC
AhIDRRUWCjAKBAQCBAESBEkCUgMaIiBBcmNoaXRlY3R1cmUgb2YgdGhlIHNvdXJjZSBkaXNr
LgoKDAoFBAIEAQESA0kHEwo1CgYEAgQBAgASA0sEIRomIERlZmF1bHQgdmFsdWUuIFRoaXMg
dmFsdWUgaXMgdW51c2VkLgoKDgoHBAIEAQIAARIDSwQcCg4KBwQCBAECAAISA0sfIAovCgYE
AgQBAgESA04EDxogIERpc2tzIHdpdGggYXJjaGl0ZWN0dXJlIFg4Nl82NAoKDgoHBAIEAQIB
ARIDTgQKCg4KBwQCBAECAQISA04NDgouCgYEAgQBAgISA1EEDhofIERpc2tzIHdpdGggYXJj
aGl0ZWN0dXJlIEFSTTY0CgoOCgcEAgQBAgIBEgNRBAkKDgoHBAIEAQICAhIDUQwNCioKBAQC
AgASA1UCRBodIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBkaXNrLgoKDAoFBAICAAQSA1UCCgoM
CgUEAgIABRIDVQsRCgwKBQQCAgABEgNVEhYKDAoFBAICAAMSA1UZGgoMCgUEAgIACBIDVRtD
Cg8KCAQCAgAInAgAEgNVHEIKdwoEBAICARIDWQJLGmogT3B0aW9uYWwuIEFuIG9wdGlvbmFs
IGRlc2NyaXB0aW9uIG9mIHRoaXMgcmVzb3VyY2UuIFByb3ZpZGUgdGhpcyBwcm9wZXJ0eQog
d2hlbiB5b3UgY3JlYXRlIHRoZSByZXNvdXJjZS4KCgwKBQQCAgEEEgNZAgoKDAoFBAICAQUS
A1kLEQoMCgUEAgIBARIDWRIdCgwKBQQCAgEDEgNZICEKDAoFBAICAQgSA1kiSgoPCggEAgIB
CJwIABIDWSNJCjQKBAQCAgISA1wCRhonIFJlcXVpcmVkLiBUaGUgc2l6ZSBvZiB0aGUgZGlz
ayBpbiBHQi4KCgwKBQQCAgIEEgNcAgoKDAoFBAICAgUSA1wLEAoMCgUEAgICARIDXBEYCgwK
BQQCAgIDEgNcGxwKDAoFBAICAggSA1wdRQoPCggEAgICCJwIABIDXB5ECrgBCgQEAgIDEgNh
AkgaqgEgT3B0aW9uYWwuIEEgbGlzdCBvZiBwdWJsaWNseSBhdmFpbGFibGUgbGljZW5zZXMg
dGhhdCBhcmUgYXBwbGljYWJsZSB0byB0aGlzCiBiYWNrdXAuIFRoaXMgaXMgYXBwbGljYWJs
ZSBpZiB0aGUgb3JpZ2luYWwgaW1hZ2UgaGFkIGxpY2Vuc2VzIGF0dGFjaGVkLAogZS5nLiBX
aW5kb3dzIGltYWdlCgoMCgUEAgIDBBIDYQIKCgwKBQQCAgMFEgNhCxEKDAoFBAICAwESA2ES
GgoMCgUEAgIDAxIDYR0eCgwKBQQCAgMIEgNhH0cKDwoIBAICAwicCAASA2EgRgqDAQoEBAIC
BBIEZQJmLxp1IE9wdGlvbmFsLiBBIGxpc3Qgb2YgZmVhdHVyZXMgdG8gZW5hYmxlIGluIHRo
ZSBndWVzdCBvcGVyYXRpbmcgc3lzdGVtLiBUaGlzCiBpcyBhcHBsaWNhYmxlIG9ubHkgZm9y
IGJvb3RhYmxlIGltYWdlcy4KCgwKBQQCAgQEEgNlAgoKDAoFBAICBAYSA2ULGQoMCgUEAgIE
ARIDZRoqCgwKBQQCAgQDEgNlLS4KDAoFBAICBAgSA2YGLgoPCggEAgIECJwIABIDZgctCnsK
BAQCAgUSBGoCay8abSBPcHRpb25hbC4gRW5jcnlwdHMgdGhlIGRpc2sgdXNpbmcgYQogY3Vz
dG9tZXItc3VwcGxpZWQgZW5jcnlwdGlvbiBrZXkgb3IgYSBjdXN0b21lci1tYW5hZ2VkIGVu
Y3J5cHRpb24ga2V5LgoKDAoFBAICBQQSA2oCCgoMCgUEAgIFBhIDagsgCgwKBQQCAgUBEgNq
ITQKDAoFBAICBQMSA2o3OAoMCgUEAgIFCBIDawYuCg8KCAQCAgUInAgAEgNrBy0KrwEKBAQC
AgYSBHACcS8aoAEgT3B0aW9uYWwuIFBoeXNpY2FsIGJsb2NrIHNpemUgb2YgdGhlIHBlcnNp
c3RlbnQgZGlzaywgaW4gYnl0ZXMuCiBJZiBub3QgcHJlc2VudCBpbiBhIHJlcXVlc3QsIGEg
ZGVmYXVsdCB2YWx1ZSBpcyB1c2VkLgogQ3VycmVudGx5LCB0aGUgc3VwcG9ydGVkIHNpemUg
aXMgNDA5Ni4KCgwKBQQCAgYEEgNwAgoKDAoFBAICBgUSA3ALEAoMCgUEAgIGARIDcBEqCgwK
BQQCAgYDEgNwLS4KDAoFBAICBggSA3EGLgoPCggEAgIGCJwIABIDcQctCpkBCgQEAgIHEgN1
Ak8aiwEgT3B0aW9uYWwuIEluZGljYXRlcyBob3cgbWFueSBJT1BTIHRvIHByb3Zpc2lvbiBm
b3IgdGhlIGRpc2suIFRoaXMgc2V0cyB0aGUKIG51bWJlciBvZiBJL08gb3BlcmF0aW9ucyBw
ZXIgc2Vjb25kIHRoYXQgdGhlIGRpc2sgY2FuIGhhbmRsZS4KCgwKBQQCAgcEEgN1AgoKDAoF
BAICBwUSA3ULEAoMCgUEAgIHARIDdREhCgwKBQQCAgcDEgN1JCUKDAoFBAICBwgSA3UmTgoP
CggEAgIHCJwIABIDdSdNCp8BCgQEAgIIEgR5AnovGpABIE9wdGlvbmFsLiBJbmRpY2F0ZXMg
aG93IG11Y2ggdGhyb3VnaHB1dCB0byBwcm92aXNpb24gZm9yIHRoZSBkaXNrLiBUaGlzCiBz
ZXRzIHRoZSBudW1iZXIgb2YgdGhyb3VnaHB1dCBNQiBwZXIgc2Vjb25kIHRoYXQgdGhlIGRp
c2sgY2FuIGhhbmRsZS4KCgwKBQQCAggEEgN5AgoKDAoFBAICCAUSA3kLEAoMCgUEAgIIARID
eREnCgwKBQQCAggDEgN5KisKDAoFBAICCAgSA3oGLgoPCggEAgIICJwIABIDegctCp4BCgQE
AgIJEgR+An8vGo8BIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0aGlzIGRpc2sgaXMg
dXNpbmcgY29uZmlkZW50aWFsIGNvbXB1dGUgbW9kZS4KIEVuY3J5cHRpb24gd2l0aCBhIENs
b3VkIEtNUyBrZXkgaXMgcmVxdWlyZWQgdG8gZW5hYmxlIHRoaXMgb3B0aW9uLgoKDAoFBAIC
CQQSA34CCgoMCgUEAgIJBRIDfgsPCgwKBQQCAgkBEgN+ECsKDAoFBAICCQMSA34uMAoMCgUE
AgIJCBIDfwYuCg8KCAQCAgkInAgAEgN/By0KjgEKBAQCAgoSBoMBAogBBBp+IE9wdGlvbmFs
LiBUaGUgc3RvcmFnZSBwb29sIGluIHdoaWNoIHRoZSBuZXcgZGlzayBpcyBjcmVhdGVkLiBZ
b3UgY2FuCiBwcm92aWRlIHRoaXMgYXMgYSBwYXJ0aWFsIG9yIGZ1bGwgVVJMIHRvIHRoZSBy
ZXNvdXJjZS4KCg0KBQQCAgoEEgSDAQIKCg0KBQQCAgoFEgSDAQsRCg0KBQQCAgoBEgSDARIe
Cg0KBQQCAgoDEgSDASEjCg8KBQQCAgoIEgaDASSIAQMKEAoIBAICCgicCAASBIQBBCoKEQoH
BAICCgifCBIGhQEEhwEFCjYKBAQCAgsSBIsBAlAaKCBPcHRpb25hbC4gVGhlIGFjY2VzcyBt
b2RlIG9mIHRoZSBkaXNrLgoKDQoFBAICCwQSBIsBAgoKDQoFBAICCwYSBIsBCxUKDQoFBAIC
CwESBIsBFiEKDQoFBAICCwMSBIsBJCYKDQoFBAICCwgSBIsBJ08KEAoIBAICCwicCAASBIsB
KE4KYwoEBAICDBIGjwECkAEvGlMgT3B0aW9uYWwuIFRoZSBhcmNoaXRlY3R1cmUgb2YgdGhl
IHNvdXJjZSBkaXNrLiBWYWxpZCB2YWx1ZXMgYXJlCiBBUk02NCBvciBYODZfNjQuCgoNCgUE
AgIMBBIEjwECCgoNCgUEAgIMBhIEjwELFwoNCgUEAgIMARIEjwEYJAoNCgUEAgIMAxIEjwEn
KQoNCgUEAgIMCBIEkAEGLgoQCggEAgIMCJwIABIEkAEHLQpBCgQEAgINEgSTAQJQGjMgT3B0
aW9uYWwuIFJlc291cmNlIHBvbGljaWVzIGFwcGxpZWQgdG8gdGhpcyBkaXNrLgoKDQoFBAIC
DQQSBJMBAgoKDQoFBAICDQUSBJMBCxEKDQoFBAICDQESBJMBEiEKDQoFBAICDQMSBJMBJCYK
DQoFBAICDQgSBJMBJ08KEAoIBAICDQicCAASBJMBKE4KbgoEBAICDhIElwECRRpgIFJlcXVp
cmVkLiBVUkwgb2YgdGhlIGRpc2sgdHlwZSByZXNvdXJjZSBkZXNjcmliaW5nIHdoaWNoIGRp
c2sgdHlwZSB0byB1c2UKIHRvIGNyZWF0ZSB0aGUgZGlzay4KCg0KBQQCAg4EEgSXAQIKCg0K
BQQCAg4FEgSXAQsRCg0KBQQCAg4BEgSXARIWCg0KBQQCAg4DEgSXARkbCg0KBQQCAg4IEgSX
ARxEChAKCAQCAg4InAgAEgSXAR1DCpUBCgQEAgIPEgSbAQJLGoYBIE9wdGlvbmFsLiBMYWJl
bHMgdG8gYXBwbHkgdG8gdGhpcyBkaXNrLiBUaGVzZSBjYW4gYmUgbW9kaWZpZWQgbGF0ZXIg
dXNpbmcKIDxjb2RlPnNldExhYmVsczwvY29kZT4gbWV0aG9kLiBMYWJlbCB2YWx1ZXMgY2Fu
IGJlIGVtcHR5LgoKDQoFBAICDwYSBJsBAhUKDQoFBAICDwESBJsBFhwKDQoFBAICDwMSBJsB
HyEKDQoFBAICDwgSBJsBIkoKEAoIBAICDwicCAASBJsBI0kKSgoEBAICEBIGngECnwEvGjog
T3B0aW9uYWwuIFJlc291cmNlIG1hbmFnZXIgdGFncyB0byBiZSBib3VuZCB0byB0aGUgZGlz
ay4KCg0KBQQCAhAGEgSeAQIVCg0KBQQCAhABEgSeARYrCg0KBQQCAhADEgSeAS4wCg0KBQQC
AhAIEgSfAQYuChAKCAQCAhAInAgAEgSfAQctClAKAgQDEgajAQDRAQEaQiBEaXNrQmFja3Vw
UHJvcGVydGllcyByZXByZXNlbnRzIHRoZSBwcm9wZXJ0aWVzIG9mIGEgRGlzayBiYWNrdXAu
CgoLCgMEAwESBKMBCBwKMgoEBAMEABIGpQECrgEDGiIgQXJjaGl0ZWN0dXJlIG9mIHRoZSBz
b3VyY2UgZGlzay4KCg0KBQQDBAABEgSlAQcTCjYKBgQDBAACABIEpwEEIRomIERlZmF1bHQg
dmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDwoHBAMEAAIAARIEpwEEHAoPCgcEAwQA
AgACEgSnAR8gCjAKBgQDBAACARIEqgEEDxogIERpc2tzIHdpdGggYXJjaGl0ZWN0dXJlIFg4
Nl82NAoKDwoHBAMEAAIBARIEqgEECgoPCgcEAwQAAgECEgSqAQ0OCi8KBgQDBAACAhIErQEE
DhofIERpc2tzIHdpdGggYXJjaGl0ZWN0dXJlIEFSTTY0CgoPCgcEAwQAAgIBEgStAQQJCg8K
BwQDBAACAgISBK0BDA0KMQoEBAMCABIEsQECIhojIEEgZGVzY3JpcHRpb24gb2YgdGhlIHNv
dXJjZSBkaXNrLgoKDQoFBAMCAAQSBLEBAgoKDQoFBAMCAAUSBLEBCxEKDQoFBAMCAAESBLEB
Eh0KDQoFBAMCAAMSBLEBICEKsAEKBAQDAgESBLYBAh8aoQEgQSBsaXN0IG9mIHB1YmxpY2x5
IGF2YWlsYWJsZSBsaWNlbnNlcyB0aGF0IGFyZSBhcHBsaWNhYmxlIHRvIHRoaXMgYmFja3Vw
LgogVGhpcyBpcyBhcHBsaWNhYmxlIGlmIHRoZSBvcmlnaW5hbCBpbWFnZSBoYWQgbGljZW5z
ZXMgYXR0YWNoZWQsIGUuZy4KIFdpbmRvd3MgaW1hZ2UuCgoNCgUEAwIBBBIEtgECCgoNCgUE
AwIBBRIEtgELEQoNCgUEAwIBARIEtgESGgoNCgUEAwIBAxIEtgEdHgpPCgQEAwICEgS5AQIv
GkEgQSBsaXN0IG9mIGd1ZXN0IE9TIGZlYXR1cmVzIHRoYXQgYXJlIGFwcGxpY2FibGUgdG8g
dGhpcyBiYWNrdXAuCgoNCgUEAwICBBIEuQECCgoNCgUEAwICBhIEuQELGQoNCgUEAwICARIE
uQEaKgoNCgUEAwICAxIEuQEtLgpXCgQEAwIDEgS9AQIpGkkgVGhlIGFyY2hpdGVjdHVyZSBv
ZiB0aGUgc291cmNlIGRpc2suIFZhbGlkIHZhbHVlcyBhcmUKIEFSTTY0IG9yIFg4Nl82NC4K
Cg0KBQQDAgMEEgS9AQIKCg0KBQQDAgMGEgS9AQsXCg0KBQQDAgMBEgS9ARgkCg0KBQQDAgMD
EgS9AScoCjAKBAQDAgQSBMABAhsaIiBUaGUgVVJMIG9mIHRoZSB0eXBlIG9mIHRoZSBkaXNr
LgoKDQoFBAMCBAQSBMABAgoKDQoFBAMCBAUSBMABCxEKDQoFBAMCBAESBMABEhYKDQoFBAMC
BAMSBMABGRoKLwoEBAMCBRIEwwECHRohIFNpemUoaW4gR0IpIG9mIHRoZSBzb3VyY2UgZGlz
ay4KCg0KBQQDAgUEEgTDAQIKCg0KBQQDAgUFEgTDAQsQCg0KBQQDAgUBEgTDAREYCg0KBQQD
AgUDEgTDARscCmkKBAQDAgYSBMcBAh0aWyBSZWdpb24gYW5kIHpvbmUgYXJlIG11dHVhbGx5
IGV4Y2x1c2l2ZSBmaWVsZHMuCiBUaGUgVVJMIG9mIHRoZSByZWdpb24gb2YgdGhlIHNvdXJj
ZSBkaXNrLgoKDQoFBAMCBgQSBMcBAgoKDQoFBAMCBgUSBMcBCxEKDQoFBAMCBgESBMcBEhgK
DQoFBAMCBgMSBMcBGxwKOgoEBAMCBxIEygECGxosIFRoZSBVUkwgb2YgdGhlIFpvbmUgd2hl
cmUgdGhlIHNvdXJjZSBkaXNrLgoKDQoFBAMCBwQSBMoBAgoKDQoFBAMCBwUSBMoBCxEKDQoF
BAMCBwESBMoBEhYKDQoFBAMCBwMSBMoBGRoKUAoEBAMCCBIEzQECJBpCIFRoZSBVUkwgb2Yg
dGhlIFpvbmVzIHdoZXJlIHRoZSBzb3VyY2UgZGlzayBzaG91bGQgYmUgcmVwbGljYXRlZC4K
Cg0KBQQDAggEEgTNAQIKCg0KBQQDAggFEgTNAQsRCg0KBQQDAggBEgTNARIfCg0KBQQDAggD
EgTNASIjCjsKBAQDAgkSBNABAiMaLSBUaGUgc291cmNlIGRpc2sgdXNlZCB0byBjcmVhdGUg
dGhpcyBiYWNrdXAuCgoNCgUEAwIJBBIE0AECCgoNCgUEAwIJBRIE0AELEQoNCgUEAwIJARIE
0AESHQoNCgUEAwIJAxIE0AEgIgp8CgIEBBIG1gEA4gEBGm4gRGlza0RhdGFTb3VyY2VQcm9w
ZXJ0aWVzIHJlcHJlc2VudHMgdGhlIHByb3BlcnRpZXMgb2YgYQogRGlzayByZXNvdXJjZSB0
aGF0IGFyZSBzdG9yZWQgaW4gdGhlIERhdGFTb3VyY2UuCiAuCgoLCgMEBAESBNYBCCAKPQoE
BAQCABIE2AECEhovIE5hbWUgb2YgdGhlIGRpc2sgYmFja2VkIHVwIGJ5IHRoZSBkYXRhc291
cmNlLgoKDQoFBAQCAAUSBNgBAggKDQoFBAQCAAESBNgBCQ0KDQoFBAQCAAMSBNgBEBEKLAoE
BAQCARIE2wECGRoeIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgZGlzay4KCg0KBQQEAgEFEgTb
AQIICg0KBQQEAgEBEgTbAQkUCg0KBQQEAgEDEgTbARcYCiUKBAQEAgISBN4BAhIaFyBUaGUg
dHlwZSBvZiB0aGUgZGlzay4KCg0KBQQEAgIFEgTeAQIICg0KBQQEAgIBEgTeAQkNCg0KBQQE
AgIDEgTeARARCisKBAQEAgMSBOEBAhQaHSBUaGUgc2l6ZSBvZiB0aGUgZGlzayBpbiBHQi4K
Cg0KBQQEAgMFEgThAQIHCg0KBQQEAgMBEgThAQgPCg0KBQQEAgMDEgThARITYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskTargetEnvironment ===
    # Fields for DiskTargetEnvironment
    # Field: project Type: 9 ()
    # Field: zone Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::BackupvaultDisk::RegionDiskTargetEnvironment ===
    # Fields for RegionDiskTargetEnvironment
    # Field: project Type: 9 ()
    # Field: region Type: 9 ()
    # Field: replica_zones Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskRestoreProperties ===
    # Fields for DiskRestoreProperties
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: size_gb Type: 3 ()
    # Field: licenses Type: 9 ()
    # Field: guest_os_feature Type: 11 (.google.cloud.backupdr.v1.GuestOsFeature)
    # Field: disk_encryption_key Type: 11 (.google.cloud.backupdr.v1.CustomerEncryptionKey)
    # Field: physical_block_size_bytes Type: 3 ()
    # Field: provisioned_iops Type: 3 ()
    # Field: provisioned_throughput Type: 3 ()
    # Field: enable_confidential_compute Type: 8 ()
    # Field: storage_pool Type: 9 ()
    # Field: access_mode Type: 14 (.google.cloud.backupdr.v1.DiskRestoreProperties.AccessMode)
    # Field: architecture Type: 14 (.google.cloud.backupdr.v1.DiskRestoreProperties.Architecture)
    # Field: resource_policy Type: 9 ()
    # Field: type Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1.DiskRestoreProperties.LabelsEntry)
    # Field: resource_manager_tags Type: 11 (.google.cloud.backupdr.v1.DiskRestoreProperties.ResourceManagerTagsEntry)

# Enum: DiskRestoreProperties::AccessMode
our $DiskRestoreProperties_READ_WRITE_SINGLE = 0;
our $DiskRestoreProperties_READ_WRITE_MANY = 1;
our $DiskRestoreProperties_READ_ONLY_MANY = 2;

# Enum: DiskRestoreProperties::Architecture
our $DiskRestoreProperties_ARCHITECTURE_UNSPECIFIED = 0;
our $DiskRestoreProperties_X86_64 = 1;
our $DiskRestoreProperties_ARM64 = 2;

# === Message: Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskBackupProperties ===
    # Fields for DiskBackupProperties
    # Field: description Type: 9 ()
    # Field: licenses Type: 9 ()
    # Field: guest_os_feature Type: 11 (.google.cloud.backupdr.v1.GuestOsFeature)
    # Field: architecture Type: 14 (.google.cloud.backupdr.v1.DiskBackupProperties.Architecture)
    # Field: type Type: 9 ()
    # Field: size_gb Type: 3 ()
    # Field: region Type: 9 ()
    # Field: zone Type: 9 ()
    # Field: replica_zones Type: 9 ()
    # Field: source_disk Type: 9 ()

# Enum: DiskBackupProperties::Architecture
our $DiskBackupProperties_ARCHITECTURE_UNSPECIFIED = 0;
our $DiskBackupProperties_X86_64 = 1;
our $DiskBackupProperties_ARM64 = 2;

# === Message: Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskDataSourceProperties ===
    # Fields for DiskDataSourceProperties
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: type Type: 9 ()
    # Field: size_gb Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::BackupvaultDisk - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/backupvault_disk.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::BackupvaultDisk;

    my $msg = Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskTargetEnvironment->new({
        project => $project,
        zone => $zone,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskTargetEnvironment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/backupvault_disk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskTargetEnvironment

DiskTargetEnvironment represents the target environment for the disk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Target project for the disk.

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

Required. Target zone for the disk.

=back

=head2 Google::Cloud::Backupdr::V1::BackupvaultDisk::RegionDiskTargetEnvironment

RegionDiskTargetEnvironment represents the target environment for the disk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Target project for the disk.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Required. Target region for the disk.

=item * C<< $msg->replica_zones() >> / C<< $msg->replica_zones($value) >>

Type: C<String>

Required. Target URLs of the replica zones for the disk.

=back

=head2 Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskRestoreProperties

DiskRestoreProperties represents the properties of a Disk restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the disk.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. An optional description of this resource. Provide this property
when you create the resource.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

Required. The size of the disk in GB.

=item * C<< $msg->licenses() >> / C<< $msg->licenses($value) >>

Type: C<String>

Optional. A list of publicly available licenses that are applicable to this
backup. This is applicable if the original image had licenses attached,
e.g. Windows image

=item * C<< $msg->guest_os_feature() >> / C<< $msg->guest_os_feature($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::BackupvaultGce::GuestOsFeature>)

Optional. A list of features to enable in the guest operating system. This
is applicable only for bootable images.

=item * C<< $msg->disk_encryption_key() >> / C<< $msg->disk_encryption_key($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::BackupvaultGce::CustomerEncryptionKey>)

Optional. Encrypts the disk using a
customer-supplied encryption key or a customer-managed encryption key.

=item * C<< $msg->physical_block_size_bytes() >> / C<< $msg->physical_block_size_bytes($value) >>

Type: C<Int64>

Optional. Physical block size of the persistent disk, in bytes.
If not present in a request, a default value is used.
Currently, the supported size is 4096.

=item * C<< $msg->provisioned_iops() >> / C<< $msg->provisioned_iops($value) >>

Type: C<Int64>

Optional. Indicates how many IOPS to provision for the disk. This sets the
number of I/O operations per second that the disk can handle.

=item * C<< $msg->provisioned_throughput() >> / C<< $msg->provisioned_throughput($value) >>

Type: C<Int64>

Optional. Indicates how much throughput to provision for the disk. This
sets the number of throughput MB per second that the disk can handle.

=item * C<< $msg->enable_confidential_compute() >> / C<< $msg->enable_confidential_compute($value) >>

Type: C<Bool>

Optional. Indicates whether this disk is using confidential compute mode.
Encryption with a Cloud KMS key is required to enable this option.

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<String>

Optional. The storage pool in which the new disk is created. You can
provide this as a partial or full URL to the resource.

=item * C<< $msg->access_mode() >> / C<< $msg->access_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::DiskRestoreProperties::AccessMode>)

Optional. The access mode of the disk.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::DiskRestoreProperties::Architecture>)

Optional. The architecture of the source disk. Valid values are
ARM64 or X86_64.

=item * C<< $msg->resource_policy() >> / C<< $msg->resource_policy($value) >>

Type: C<String>

Optional. Resource policies applied to this disk.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. URL of the disk type resource describing which disk type to use
to create the disk.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskRestoreProperties::LabelsEntry>)

Optional. Labels to apply to this disk. These can be modified later using
<code>setLabels</code> method. Label values can be empty.

=item * C<< $msg->resource_manager_tags() >> / C<< $msg->resource_manager_tags($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskRestoreProperties::ResourceManagerTagsEntry>)

Optional. Resource manager tags to be bound to the disk.

=back

=head3 Enum: DiskRestoreProperties::AccessMode

=over 4

=item * C<READ_WRITE_SINGLE> => C<0>

=item * C<READ_WRITE_MANY> => C<1>

=item * C<READ_ONLY_MANY> => C<2>

=back

=head3 Enum: DiskRestoreProperties::Architecture

=over 4

=item * C<ARCHITECTURE_UNSPECIFIED> => C<0>

=item * C<X86_64> => C<1>

=item * C<ARM64> => C<2>

=back

=head2 Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskBackupProperties

DiskBackupProperties represents the properties of a Disk backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the source disk.

=item * C<< $msg->licenses() >> / C<< $msg->licenses($value) >>

Type: C<String>

A list of publicly available licenses that are applicable to this backup.
This is applicable if the original image had licenses attached, e.g.
Windows image.

=item * C<< $msg->guest_os_feature() >> / C<< $msg->guest_os_feature($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::BackupvaultGce::GuestOsFeature>)

A list of guest OS features that are applicable to this backup.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::DiskBackupProperties::Architecture>)

The architecture of the source disk. Valid values are
ARM64 or X86_64.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The URL of the type of the disk.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

Size(in GB) of the source disk.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Region and zone are mutually exclusive fields.
The URL of the region of the source disk.

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

The URL of the Zone where the source disk.

=item * C<< $msg->replica_zones() >> / C<< $msg->replica_zones($value) >>

Type: C<String>

The URL of the Zones where the source disk should be replicated.

=item * C<< $msg->source_disk() >> / C<< $msg->source_disk($value) >>

Type: C<String>

The source disk used to create this backup.

=back

=head3 Enum: DiskBackupProperties::Architecture

=over 4

=item * C<ARCHITECTURE_UNSPECIFIED> => C<0>

=item * C<X86_64> => C<1>

=item * C<ARM64> => C<2>

=back

=head2 Google::Cloud::Backupdr::V1::BackupvaultDisk::DiskDataSourceProperties

DiskDataSourceProperties represents the properties of a
Disk resource that are stored in the DataSource.
.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the disk backed up by the datasource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the disk.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the disk.

=item * C<< $msg->size_gb() >> / C<< $msg->size_gb($value) >>

Type: C<Int64>

The size of the disk in GB.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::BackupvaultDisk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
