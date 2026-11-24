package Google::Ai::Generativelanguage::V1beta3::Safety;

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
CjFnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvc2FmZXR5LnByb3RvEiRn
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8i3QEKDUNvbnRlbnRGaWx0ZXISWQoGcmVhc29uGAEgASgOMkEuZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkNvbnRlbnRGaWx0ZXIuQmxvY2tl
ZFJlYXNvblIGcmVhc29uEh0KB21lc3NhZ2UYAiABKAlIAFIHbWVzc2FnZYgBASJGCg1CbG9j
a2VkUmVhc29uEh4KGkJMT0NLRURfUkVBU09OX1VOU1BFQ0lGSUVEEAASCgoGU0FGRVRZEAES
CQoFT1RIRVIQAkIKCghfbWVzc2FnZSKrAQoOU2FmZXR5RmVlZGJhY2sSSgoGcmF0aW5nGAEg
ASgLMjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLlNhZmV0eVJhdGlu
Z1IGcmF0aW5nEk0KB3NldHRpbmcYAiABKAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1
YWdlLnYxYmV0YTMuU2FmZXR5U2V0dGluZ1IHc2V0dGluZyKyAgoMU2FmZXR5UmF0aW5nElMK
CGNhdGVnb3J5GAMgASgOMjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEz
Lkhhcm1DYXRlZ29yeUID4EECUghjYXRlZ29yeRJpCgtwcm9iYWJpbGl0eRgEIAEoDjJCLmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5TYWZldHlSYXRpbmcuSGFybVBy
b2JhYmlsaXR5QgPgQQJSC3Byb2JhYmlsaXR5ImIKD0hhcm1Qcm9iYWJpbGl0eRIgChxIQVJN
X1BST0JBQklMSVRZX1VOU1BFQ0lGSUVEEAASDgoKTkVHTElHSUJMRRABEgcKA0xPVxACEgoK
Bk1FRElVTRADEggKBEhJR0gQBCLmAgoNU2FmZXR5U2V0dGluZxJTCghjYXRlZ29yeRgDIAEo
DjIyLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5IYXJtQ2F0ZWdvcnlC
A+BBAlIIY2F0ZWdvcnkSaQoJdGhyZXNob2xkGAQgASgOMkYuZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWJldGEzLlNhZmV0eVNldHRpbmcuSGFybUJsb2NrVGhyZXNob2xkQgPg
QQJSCXRocmVzaG9sZCKUAQoSSGFybUJsb2NrVGhyZXNob2xkEiQKIEhBUk1fQkxPQ0tfVEhS
RVNIT0xEX1VOU1BFQ0lGSUVEEAASFwoTQkxPQ0tfTE9XX0FORF9BQk9WRRABEhoKFkJMT0NL
X01FRElVTV9BTkRfQUJPVkUQAhITCg9CTE9DS19PTkxZX0hJR0gQAxIOCgpCTE9DS19OT05F
EAQq1QEKDEhhcm1DYXRlZ29yeRIdChlIQVJNX0NBVEVHT1JZX1VOU1BFQ0lGSUVEEAASHAoY
SEFSTV9DQVRFR09SWV9ERVJPR0FUT1JZEAESGgoWSEFSTV9DQVRFR09SWV9UT1hJQ0lUWRAC
EhoKFkhBUk1fQ0FURUdPUllfVklPTEVOQ0UQAxIYChRIQVJNX0NBVEVHT1JZX1NFWFVBTBAE
EhkKFUhBUk1fQ0FURUdPUllfTUVESUNBTBAFEhsKF0hBUk1fQ0FURUdPUllfREFOR0VST1VT
EAZCmQEKKGNvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTNCC1NhZmV0
eVByb3RvUAFaXmNsb3VkLmdvb2dsZS5jb20vZ28vYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL2Fw
aXYxYmV0YTMvZ2VuZXJhdGl2ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKoykK
BxIFDgCcAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0K
CQoCAwASAxIAKQoICgEIEgMUAHUKCQoCCAsSAxQAdQoICgEIEgMVACIKCQoCCAoSAxUAIgoI
CgEIEgMWACwKCQoCCAgSAxYALAoICgEIEgMXAEEKCQoCCAESAxcAQQp8CgIFABIEHQAzARpw
IFRoZSBjYXRlZ29yeSBvZiBhIHJhdGluZy4KCiBUaGVzZSBjYXRlZ29yaWVzIGNvdmVyIHZh
cmlvdXMga2luZHMgb2YgaGFybXMgdGhhdCBkZXZlbG9wZXJzCiBtYXkgd2lzaCB0byBhZGp1
c3QuCgoKCgMFAAESAx0FEQonCgQFAAIAEgMfAiAaGiBDYXRlZ29yeSBpcyB1bnNwZWNpZmll
ZC4KCgwKBQUAAgABEgMfAhsKDAoFBQACAAISAx8eHwpaCgQFAAIBEgMiAh8aTSBOZWdhdGl2
ZSBvciBoYXJtZnVsIGNvbW1lbnRzIHRhcmdldGluZyBpZGVudGl0eSBhbmQvb3IgcHJvdGVj
dGVkIGF0dHJpYnV0ZS4KCgwKBQUAAgEBEgMiAhoKDAoFBQACAQISAyIdHgpACgQFAAICEgMl
Ah0aMyBDb250ZW50IHRoYXQgaXMgcnVkZSwgZGlzcmVwc3BlY3RmdWwsIG9yIHByb2ZhbmUu
CgoMCgUFAAICARIDJQIYCgwKBQUAAgICEgMlGxwKdgoEBQACAxIDKQIdGmkgRGVzY3JpYmVz
IHNjZW5hcmlvcyBkZXBpY3RuZyB2aW9sZW5jZSBhZ2FpbnN0IGFuIGluZGl2aWR1YWwgb3Ig
Z3JvdXAsIG9yCiBnZW5lcmFsIGRlc2NyaXB0aW9ucyBvZiBnb3JlLgoKDAoFBQACAwESAykC
GAoMCgUFAAIDAhIDKRscCkgKBAUAAgQSAywCGxo7IENvbnRhaW5zIHJlZmVyZW5jZXMgdG8g
c2V4dWFsIGFjdHMgb3Igb3RoZXIgbGV3ZCBjb250ZW50LgoKDAoFBQACBAESAywCFgoMCgUF
AAIEAhIDLBkaCjEKBAUAAgUSAy8CHBokIFByb21vdGVzIHVuY2hlY2tlZCBtZWRpY2FsIGFk
dmljZS4KCgwKBQUAAgUBEgMvAhcKDAoFBQACBQISAy8aGwpYCgQFAAIGEgMyAh4aSyBEYW5n
ZXJvdXMgY29udGVudCB0aGF0IHByb21vdGVzLCBmYWNpbGl0YXRlcywgb3IgZW5jb3VyYWdl
cyBoYXJtZnVsIGFjdHMuCgoMCgUFAAIGARIDMgIZCgwKBQUAAgYCEgMyHB0KuwEKAgQAEgQ5
AEsBGq4BIENvbnRlbnQgZmlsdGVyaW5nIG1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBwcm9j
ZXNzaW5nIGEgc2luZ2xlIHJlcXVlc3QuCgogQ29udGVudEZpbHRlciBjb250YWlucyBhIHJl
YXNvbiBhbmQgYW4gb3B0aW9uYWwgc3VwcG9ydGluZyBzdHJpbmcuIFRoZSByZWFzb24KIG1h
eSBiZSB1bnNwZWNpZmllZC4KCgoKAwQAARIDOQgVCkQKBAQABAASBDsCRAMaNiBBIGxpc3Qg
b2YgcmVhc29ucyB3aHkgY29udGVudCBtYXkgaGF2ZSBiZWVuIGJsb2NrZWQuCgoMCgUEAAQA
ARIDOwcUCjQKBgQABAACABIDPQQjGiUgQSBibG9ja2VkIHJlYXNvbiB3YXMgbm90IHNwZWNp
ZmllZC4KCg4KBwQABAACAAESAz0EHgoOCgcEAAQAAgACEgM9ISIKOAoGBAAEAAIBEgNABA8a
KSBDb250ZW50IHdhcyBibG9ja2VkIGJ5IHNhZmV0eSBzZXR0aW5ncy4KCg4KBwQABAACAQES
A0AECgoOCgcEAAQAAgECEgNADQ4KRgoGBAAEAAICEgNDBA4aNyBDb250ZW50IHdhcyBibG9j
a2VkLCBidXQgdGhlIHJlYXNvbiBpcyB1bmNhdGVnb3JpemVkLgoKDgoHBAAEAAICARIDQwQJ
Cg4KBwQABAACAgISA0MMDQpICgQEAAIAEgNHAhsaOyBUaGUgcmVhc29uIGNvbnRlbnQgd2Fz
IGJsb2NrZWQgZHVyaW5nIHJlcXVlc3QgcHJvY2Vzc2luZy4KCgwKBQQAAgAGEgNHAg8KDAoF
BAACAAESA0cQFgoMCgUEAAIAAxIDRxkaCk0KBAQAAgESA0oCHhpAIEEgc3RyaW5nIHRoYXQg
ZGVzY3JpYmVzIHRoZSBmaWx0ZXJpbmcgYmVoYXZpb3IgaW4gbW9yZSBkZXRhaWwuCgoMCgUE
AAIBBBIDSgIKCgwKBQQAAgEFEgNKCxEKDAoFBAACAQESA0oSGQoMCgUEAAIBAxIDShwdCvUC
CgIEARIEVABaARroAiBTYWZldHkgZmVlZGJhY2sgZm9yIGFuIGVudGlyZSByZXF1ZXN0LgoK
IFRoaXMgZmllbGQgaXMgcG9wdWxhdGVkIGlmIGNvbnRlbnQgaW4gdGhlIGlucHV0IGFuZC9v
ciByZXNwb25zZSBpcyBibG9ja2VkCiBkdWUgdG8gc2FmZXR5IHNldHRpbmdzLiBTYWZldHlG
ZWVkYmFjayBtYXkgbm90IGV4aXN0IGZvciBldmVyeSBIYXJtQ2F0ZWdvcnkuCiBFYWNoIFNh
ZmV0eUZlZWRiYWNrIHdpbGwgcmV0dXJuIHRoZSBzYWZldHkgc2V0dGluZ3MgdXNlZCBieSB0
aGUgcmVxdWVzdCBhcwogd2VsbCBhcyB0aGUgbG93ZXN0IEhhcm1Qcm9iYWJpbGl0eSB0aGF0
IHNob3VsZCBiZSBhbGxvd2VkIGluIG9yZGVyIHRvIHJldHVybgogYSByZXN1bHQuCgoKCgME
AQESA1QIFgo0CgQEAQIAEgNWAhoaJyBTYWZldHkgcmF0aW5nIGV2YWx1YXRlZCBmcm9tIGNv
bnRlbnQuCgoMCgUEAQIABhIDVgIOCgwKBQQBAgABEgNWDxUKDAoFBAECAAMSA1YYGQo2CgQE
AQIBEgNZAhwaKSBTYWZldHkgc2V0dGluZ3MgYXBwbGllZCB0byB0aGUgcmVxdWVzdC4KCgwK
BQQBAgEGEgNZAg8KDAoFBAECAQESA1kQFwoMCgUEAQIBAxIDWRobCrcCCgIEAhIEYwB+ARqq
AiBTYWZldHkgcmF0aW5nIGZvciBhIHBpZWNlIG9mIGNvbnRlbnQuCgogVGhlIHNhZmV0eSBy
YXRpbmcgY29udGFpbnMgdGhlIGNhdGVnb3J5IG9mIGhhcm0gYW5kIHRoZQogaGFybSBwcm9i
YWJpbGl0eSBsZXZlbCBpbiB0aGF0IGNhdGVnb3J5IGZvciBhIHBpZWNlIG9mIGNvbnRlbnQu
CiBDb250ZW50IGlzIGNsYXNzaWZpZWQgZm9yIHNhZmV0eSBhY3Jvc3MgYSBudW1iZXIgb2YK
IGhhcm0gY2F0ZWdvcmllcyBhbmQgdGhlIHByb2JhYmlsaXR5IG9mIHRoZSBoYXJtIGNsYXNz
aWZpY2F0aW9uIGlzIGluY2x1ZGVkCiBoZXJlLgoKCgoDBAIBEgNjCBQK2AEKBAQCBAASBGgC
dwMayQEgVGhlIHByb2JhYmlsaXR5IHRoYXQgYSBwaWVjZSBvZiBjb250ZW50IGlzIGhhcm1m
dWwuCgogVGhlIGNsYXNzaWZpY2F0aW9uIHN5c3RlbSBnaXZlcyB0aGUgcHJvYmFiaWxpdHkg
b2YgdGhlIGNvbnRlbnQgYmVpbmcKIHVuc2FmZS4gVGhpcyBkb2VzIG5vdCBpbmRpY2F0ZSB0
aGUgc2V2ZXJpdHkgb2YgaGFybSBmb3IgYSBwaWVjZSBvZiBjb250ZW50LgoKDAoFBAIEAAES
A2gHFgosCgYEAgQAAgASA2oEJRodIFByb2JhYmlsaXR5IGlzIHVuc3BlY2lmaWVkLgoKDgoH
BAIEAAIAARIDagQgCg4KBwQCBAACAAISA2ojJApBCgYEAgQAAgESA20EExoyIENvbnRlbnQg
aGFzIGEgbmVnbGlnaWJsZSBjaGFuY2Ugb2YgYmVpbmcgdW5zYWZlLgoKDgoHBAIEAAIBARID
bQQOCg4KBwQCBAACAQISA20REgo6CgYEAgQAAgISA3AEDBorIENvbnRlbnQgaGFzIGEgbG93
IGNoYW5jZSBvZiBiZWluZyB1bnNhZmUuCgoOCgcEAgQAAgIBEgNwBAcKDgoHBAIEAAICAhID
cAoLCj0KBgQCBAACAxIDcwQPGi4gQ29udGVudCBoYXMgYSBtZWRpdW0gY2hhbmNlIG9mIGJl
aW5nIHVuc2FmZS4KCg4KBwQCBAACAwESA3MECgoOCgcEAgQAAgMCEgNzDQ4KOwoGBAIEAAIE
EgN2BA0aLCBDb250ZW50IGhhcyBhIGhpZ2ggY2hhbmNlIG9mIGJlaW5nIHVuc2FmZS4KCg4K
BwQCBAACBAESA3YECAoOCgcEAgQAAgQCEgN2CwwKNgoEBAICABIDegJFGikgUmVxdWlyZWQu
IFRoZSBjYXRlZ29yeSBmb3IgdGhpcyByYXRpbmcuCgoMCgUEAgIABhIDegIOCgwKBQQCAgAB
EgN6DxcKDAoFBAICAAMSA3oaGwoMCgUEAgIACBIDehxECg8KCAQCAgAInAgAEgN6HUMKQgoE
BAICARIDfQJLGjUgUmVxdWlyZWQuIFRoZSBwcm9iYWJpbGl0eSBvZiBoYXJtIGZvciB0aGlz
IGNvbnRlbnQuCgoMCgUEAgIBBhIDfQIRCgwKBQQCAgEBEgN9Eh0KDAoFBAICAQMSA30gIQoM
CgUEAgIBCBIDfSJKCg8KCAQCAgEInAgAEgN9I0kKqwEKAgQDEgaEAQCcAQEanAEgU2FmZXR5
IHNldHRpbmcsIGFmZmVjdGluZyB0aGUgc2FmZXR5LWJsb2NraW5nIGJlaGF2aW9yLgoKIFBh
c3NpbmcgYSBzYWZldHkgc2V0dGluZyBmb3IgYSBjYXRlZ29yeSBjaGFuZ2VzIHRoZSBhbGxv
d2VkIHByb2FiaWxpdHkgdGhhdAogY29udGVudCBpcyBibG9ja2VkLgoKCwoDBAMBEgSEAQgV
CkMKBAQDBAASBoYBApUBAxozIEJsb2NrIGF0IGFuZCBiZXlvbmQgYSBzcGVjaWZpZWQgaGFy
bSBwcm9iYWJpbGl0eS4KCg0KBQQDBAABEgSGAQcZCisKBgQDBAACABIEiAEEKRobIFRocmVz
aG9sZCBpcyB1bnNwZWNpZmllZC4KCg8KBwQDBAACAAESBIgBBCQKDwoHBAMEAAIAAhIEiAEn
KAo6CgYEAwQAAgESBIsBBBwaKiBDb250ZW50IHdpdGggTkVHTElHSUJMRSB3aWxsIGJlIGFs
bG93ZWQuCgoPCgcEAwQAAgEBEgSLAQQXCg8KBwQDBAACAQISBIsBGhsKQgoGBAMEAAICEgSO
AQQfGjIgQ29udGVudCB3aXRoIE5FR0xJR0lCTEUgYW5kIExPVyB3aWxsIGJlIGFsbG93ZWQu
CgoPCgcEAwQAAgIBEgSOAQQaCg8KBwQDBAACAgISBI4BHR4KSwoGBAMEAAIDEgSRAQQYGjsg
Q29udGVudCB3aXRoIE5FR0xJR0lCTEUsIExPVywgYW5kIE1FRElVTSB3aWxsIGJlIGFsbG93
ZWQuCgoPCgcEAwQAAgMBEgSRAQQTCg8KBwQDBAACAwISBJEBFhcKLgoGBAMEAAIEEgSUAQQT
Gh4gQWxsIGNvbnRlbnQgd2lsbCBiZSBhbGxvd2VkLgoKDwoHBAMEAAIEARIElAEEDgoPCgcE
AwQAAgQCEgSUARESCjgKBAQDAgASBJgBAkUaKiBSZXF1aXJlZC4gVGhlIGNhdGVnb3J5IGZv
ciB0aGlzIHNldHRpbmcuCgoNCgUEAwIABhIEmAECDgoNCgUEAwIAARIEmAEPFwoNCgUEAwIA
AxIEmAEaGwoNCgUEAwIACBIEmAEcRAoQCggEAwIACJwIABIEmAEdQwpWCgQEAwIBEgSbAQJM
GkggUmVxdWlyZWQuIENvbnRyb2xzIHRoZSBwcm9iYWJpbGl0eSB0aHJlc2hvbGQgYXQgd2hp
Y2ggaGFybSBpcyBibG9ja2VkLgoKDQoFBAMCAQYSBJsBAhQKDQoFBAMCAQESBJsBFR4KDQoF
BAMCAQMSBJsBISIKDQoFBAMCAQgSBJsBI0sKEAoIBAMCAQicCAASBJsBJEpiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::Safety::ContentFilter ===
    # Fields for ContentFilter
    # Field: reason Type: 14 (.google.ai.generativelanguage.v1beta3.ContentFilter.BlockedReason)
    # Field: message Type: 9 ()

# Enum: ContentFilter::BlockedReason
our $ContentFilter_BLOCKED_REASON_UNSPECIFIED = 0;
our $ContentFilter_SAFETY = 1;
our $ContentFilter_OTHER = 2;

# === Message: Google::Ai::Generativelanguage::V1beta3::Safety::SafetyFeedback ===
    # Fields for SafetyFeedback
    # Field: rating Type: 11 (.google.ai.generativelanguage.v1beta3.SafetyRating)
    # Field: setting Type: 11 (.google.ai.generativelanguage.v1beta3.SafetySetting)

# === Message: Google::Ai::Generativelanguage::V1beta3::Safety::SafetyRating ===
    # Fields for SafetyRating
    # Field: category Type: 14 (.google.ai.generativelanguage.v1beta3.HarmCategory)
    # Field: probability Type: 14 (.google.ai.generativelanguage.v1beta3.SafetyRating.HarmProbability)

# Enum: SafetyRating::HarmProbability
our $SafetyRating_HARM_PROBABILITY_UNSPECIFIED = 0;
our $SafetyRating_NEGLIGIBLE = 1;
our $SafetyRating_LOW = 2;
our $SafetyRating_MEDIUM = 3;
our $SafetyRating_HIGH = 4;

# === Message: Google::Ai::Generativelanguage::V1beta3::Safety::SafetySetting ===
    # Fields for SafetySetting
    # Field: category Type: 14 (.google.ai.generativelanguage.v1beta3.HarmCategory)
    # Field: threshold Type: 14 (.google.ai.generativelanguage.v1beta3.SafetySetting.HarmBlockThreshold)

# Enum: SafetySetting::HarmBlockThreshold
our $SafetySetting_HARM_BLOCK_THRESHOLD_UNSPECIFIED = 0;
our $SafetySetting_BLOCK_LOW_AND_ABOVE = 1;
our $SafetySetting_BLOCK_MEDIUM_AND_ABOVE = 2;
our $SafetySetting_BLOCK_ONLY_HIGH = 3;
our $SafetySetting_BLOCK_NONE = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::Safety - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/safety.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::Safety;

    my $msg = Google::Ai::Generativelanguage::V1beta3::Safety::ContentFilter->new({
        reason => $reason,
        message => $message,
    });

    # Read or update a field
    my $val = $msg->reason();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::Safety::ContentFilter->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::Safety::ContentFilter

Content filtering metadata associated with processing a single request.

ContentFilter contains a reason and an optional supporting string. The reason
may be unspecified.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::ContentFilter::BlockedReason>)

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

=head2 Google::Ai::Generativelanguage::V1beta3::Safety::SafetyFeedback

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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetyRating>)

Safety rating evaluated from content.

=item * C<< $msg->setting() >> / C<< $msg->setting($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetySetting>)

Safety settings applied to the request.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::Safety::SafetyRating

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

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::HarmCategory>)

Required. The category for this rating.

=item * C<< $msg->probability() >> / C<< $msg->probability($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::SafetyRating::HarmProbability>)

Required. The probability of harm for this content.

=back

=head3 Enum: SafetyRating::HarmProbability

=over 4

=item * C<HARM_PROBABILITY_UNSPECIFIED> => C<0>

=item * C<NEGLIGIBLE> => C<1>

=item * C<LOW> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<HIGH> => C<4>

=back

=head2 Google::Ai::Generativelanguage::V1beta3::Safety::SafetySetting

Safety setting, affecting the safety-blocking behavior.

Passing a safety setting for a category changes the allowed proability that
content is blocked.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::HarmCategory>)

Required. The category for this setting.

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::SafetySetting::HarmBlockThreshold>)

Required. Controls the probability threshold at which harm is blocked.

=back

=head3 Enum: SafetySetting::HarmBlockThreshold

=over 4

=item * C<HARM_BLOCK_THRESHOLD_UNSPECIFIED> => C<0>

=item * C<BLOCK_LOW_AND_ABOVE> => C<1>

=item * C<BLOCK_MEDIUM_AND_ABOVE> => C<2>

=item * C<BLOCK_ONLY_HIGH> => C<3>

=item * C<BLOCK_NONE> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
