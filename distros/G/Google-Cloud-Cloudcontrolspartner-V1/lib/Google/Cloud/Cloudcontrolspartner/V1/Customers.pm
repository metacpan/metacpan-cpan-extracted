package Google::Cloud::Cloudcontrolspartner::V1::Customers;

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
    eval { require Google::Cloud::Cloudcontrolspartner::V1::CompletionState };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvY3VzdG9tZXJzLnByb3Rv
EiRnb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aO2dvb2dsZS9j
bG91ZC9jbG91ZGNvbnRyb2xzcGFydG5lci92MS9jb21wbGV0aW9uX3N0YXRlLnByb3RvGiBn
b29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byK7AwoIQ3VzdG9tZXISFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRp
c3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRJ+ChljdXN0b21lcl9vbmJvYXJk
aW5nX3N0YXRlGAMgASgLMj0uZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYx
LkN1c3RvbWVyT25ib2FyZGluZ1N0YXRlQgPgQQNSF2N1c3RvbWVyT25ib2FyZGluZ1N0YXRl
EiYKDGlzX29uYm9hcmRlZBgEIAEoCEID4EEDUgtpc09uYm9hcmRlZBI0ChNvcmdhbml6YXRp
b25fZG9tYWluGAUgASgJQgPgQQNSEm9yZ2FuaXphdGlvbkRvbWFpbjqPAepBiwEKLGNsb3Vk
Y29udHJvbHNwYXJ0bmVyLmdvb2dsZWFwaXMuY29tL0N1c3RvbWVyEkZvcmdhbml6YXRpb25z
L3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbWVycy97Y3VzdG9t
ZXJ9KgljdXN0b21lcnMyCGN1c3RvbWVyIt0BChRMaXN0Q3VzdG9tZXJzUmVxdWVzdBJMCgZw
YXJlbnQYASABKAlCNOBBAvpBLhIsY2xvdWRjb250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5j
b20vQ3VzdG9tZXJSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBh
Z2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVy
Eh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkirwEKFUxpc3RDdXN0b21lcnNSZXNw
b25zZRJMCgljdXN0b21lcnMYASADKAsyLi5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3Bh
cnRuZXIudjEuQ3VzdG9tZXJSCWN1c3RvbWVycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlItwBChVD
cmVhdGVDdXN0b21lclJlcXVlc3QSTAoGcGFyZW50GAEgASgJQjTgQQL6QS4SLGNsb3VkY29u
dHJvbHNwYXJ0bmVyLmdvb2dsZWFwaXMuY29tL0N1c3RvbWVyUgZwYXJlbnQSTwoIY3VzdG9t
ZXIYAiABKAsyLi5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuQ3VzdG9t
ZXJCA+BBAlIIY3VzdG9tZXISJAoLY3VzdG9tZXJfaWQYAyABKAlCA+BBAlIKY3VzdG9tZXJJ
ZCJeChJHZXRDdXN0b21lclJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixjbG91ZGNv
bnRyb2xzcGFydG5lci5nb29nbGVhcGlzLmNvbS9DdXN0b21lclIEbmFtZSKCAQoXQ3VzdG9t
ZXJPbmJvYXJkaW5nU3RhdGUSZwoQb25ib2FyZGluZ19zdGVwcxgBIAMoCzI8Lmdvb2dsZS5j
bG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5DdXN0b21lck9uYm9hcmRpbmdTdGVwUg9v
bmJvYXJkaW5nU3RlcHMiogMKFkN1c3RvbWVyT25ib2FyZGluZ1N0ZXASVQoEc3RlcBgBIAEo
DjJBLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5DdXN0b21lck9uYm9h
cmRpbmdTdGVwLlN0ZXBSBHN0ZXASOQoKc3RhcnRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRJDCg9jb21wbGV0aW9uX3RpbWUYAyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUg5jb21wbGV0aW9uVGltZRJlChBjb21wbGV0aW9u
X3N0YXRlGAQgASgOMjUuZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLkNv
bXBsZXRpb25TdGF0ZUID4EEDUg9jb21wbGV0aW9uU3RhdGUiSgoEU3RlcBIUChBTVEVQX1VO
U1BFQ0lGSUVEEAASEgoOS0FKX0VOUk9MTE1FTlQQARIYChRDVVNUT01FUl9FTlZJUk9OTUVO
VBACIqoBChVVcGRhdGVDdXN0b21lclJlcXVlc3QSTwoIY3VzdG9tZXIYASABKAsyLi5nb29n
bGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuQ3VzdG9tZXJCA+BBAlIIY3VzdG9t
ZXISQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPg
QQFSCnVwZGF0ZU1hc2siYQoVRGVsZXRlQ3VzdG9tZXJSZXF1ZXN0EkgKBG5hbWUYASABKAlC
NOBBAvpBLgosY2xvdWRjb250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5jb20vQ3VzdG9tZXJS
BG5hbWVCkgIKKGNvbS5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjFCDkN1
c3RvbWVyc1Byb3RvUAFaXGNsb3VkLmdvb2dsZS5jb20vZ28vY2xvdWRjb250cm9sc3BhcnRu
ZXIvYXBpdjEvY2xvdWRjb250cm9sc3BhcnRuZXJwYjtjbG91ZGNvbnRyb2xzcGFydG5lcnBi
qgIkR29vZ2xlLkNsb3VkLkNsb3VkQ29udHJvbHNQYXJ0bmVyLlYxygIkR29vZ2xlXENsb3Vk
XENsb3VkQ29udHJvbHNQYXJ0bmVyXFYx6gInR29vZ2xlOjpDbG91ZDo6Q2xvdWRDb250cm9s
c1BhcnRuZXI6OlYxSvorCgcSBQ4AuwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABFCgkKAgMD
EgMVACoKCQoCAwQSAxYAKQoICgEIEgMYAEEKCQoCCCUSAxgAQQoICgEIEgMZAHMKCQoCCAsS
AxkAcwoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC8KCQoCCAgSAxsALwoICgEIEgMc
AEEKCQoCCAESAxwAQQoICgEIEgMdAEEKCQoCCCkSAx0AQQoICgEIEgMeAEAKCQoCCC0SAx4A
QApICgIEABIEIQA6ARo8IENvbnRhaW5zIG1ldGFkYXRhIGFyb3VuZCBhIENsb3VkIENvbnRy
b2xzIFBhcnRuZXIgQ3VzdG9tZXIKCgoKAwQAARIDIQgQCgsKAwQABxIEIgInBAoNCgUEAAed
CBIEIgInBApsCgQEAAIAEgMrAj0aXyBJZGVudGlmaWVyLiBGb3JtYXQ6CiBgb3JnYW5pemF0
aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jdXN0b21lcnMve2N1
c3RvbWVyfWAKCgwKBQQAAgAFEgMrAggKDAoFBAACAAESAysJDQoMCgUEAAIAAxIDKxARCgwK
BQQAAgAIEgMrEjwKDwoIBAACAAicCAASAysTOwo2CgQEAAIBEgMuAkMaKSBSZXF1aXJlZC4g
RGlzcGxheSBuYW1lIGZvciB0aGUgY3VzdG9tZXIKCgwKBQQAAgEFEgMuAggKDAoFBAACAQES
Ay4JFQoMCgUEAAIBAxIDLhgZCgwKBQQAAgEIEgMuGkIKDwoIBAACAQicCAASAy4bQQpECgQE
AAICEgQxAjIyGjYgT3V0cHV0IG9ubHkuIENvbnRhaW5lciBmb3IgY3VzdG9tZXIgb25ib2Fy
ZGluZyBzdGVwcwoKDAoFBAACAgYSAzECGQoMCgUEAAICARIDMRozCgwKBQQAAgIDEgMxNjcK
DAoFBAACAggSAzIGMQoPCggEAAICCJwIABIDMgcwCksKBAQAAgMSAzUCRBo+IE91dHB1dCBv
bmx5LiBJbmRpY2F0ZXMgd2hldGhlciBhIGN1c3RvbWVyIGlzIGZ1bGx5IG9uYm9hcmRlZAoK
DAoFBAACAwUSAzUCBgoMCgUEAAIDARIDNQcTCgwKBQQAAgMDEgM1FhcKDAoFBAACAwgSAzUY
QwoPCggEAAIDCJwIABIDNRlCCogBCgQEAAIEEgM5Ak0aeyBPdXRwdXQgb25seS4gVGhlIGN1
c3RvbWVyIG9yZ2FuaXphdGlvbiBkb21haW4sIGV4dHJhY3RlZCBmcm9tCiBDUk0gT3JnYW5p
emF0aW9u4oCZcyBkaXNwbGF5X25hbWUgZmllbGQuIGUuZy4gImdvb2dsZS5jb20iCgoMCgUE
AAIEBRIDOQIICgwKBQQAAgQBEgM5CRwKDAoFBAACBAMSAzkfIAoMCgUEAAIECBIDOSFMCg8K
CAQAAgQInAgAEgM5IksKJwoCBAESBD0AVAEaGyBSZXF1ZXN0IHRvIGxpc3QgY3VzdG9tZXJz
CgoKCgMEAQESAz0IHApmCgQEAQIAEgRAAkUEGlggUmVxdWlyZWQuIFBhcmVudCByZXNvdXJj
ZQogRm9ybWF0OiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xv
Y2F0aW9ufWAKCgwKBQQBAgAFEgNAAggKDAoFBAECAAESA0AJDwoMCgUEAQIAAxIDQBITCg0K
BQQBAgAIEgRAFEUDCg8KCAQBAgAInAgAEgNBBCoKDwoHBAECAAifCBIEQgREBQqhAQoEBAEC
ARIDSQIWGpMBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBDdXN0b21lcnMgdG8gcmV0dXJuLiBU
aGUgc2VydmljZSBtYXkgcmV0dXJuIGZld2VyCiB0aGFuIHRoaXMgdmFsdWUuIElmIHVuc3Bl
Y2lmaWVkLCBhdCBtb3N0IDUwMCBDdXN0b21lcnMgd2lsbCBiZSByZXR1cm5lZC4KCgwKBQQB
AgEFEgNJAgcKDAoFBAECAQESA0kIEQoMCgUEAQIBAxIDSRQVCnoKBAQBAgISA00CGBptIEEg
cGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0Q3VzdG9tZXJzYCBj
YWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoM
CgUEAQICBRIDTQIICgwKBQQBAgIBEgNNCRMKDAoFBAECAgMSA00WFwoqCgQEAQIDEgNQAj0a
HSBPcHRpb25hbC4gRmlsdGVyaW5nIHJlc3VsdHMKCgwKBQQBAgMFEgNQAggKDAoFBAECAwES
A1AJDwoMCgUEAQIDAxIDUBITCgwKBQQBAgMIEgNQFDwKDwoIBAECAwicCAASA1AVOwo6CgQE
AQIEEgNTAj8aLSBPcHRpb25hbC4gSGludCBmb3IgaG93IHRvIG9yZGVyIHRoZSByZXN1bHRz
CgoMCgUEAQIEBRIDUwIICgwKBQQBAgQBEgNTCREKDAoFBAECBAMSA1MUFQoMCgUEAQIECBID
UxY+Cg8KCAQBAgQInAgAEgNTFz0KQwoCBAISBFcAYQEaNyBSZXNwb25zZSBtZXNzYWdlIGZv
ciBsaXN0IGN1c3RvbWVyIEN1c3RvbWVycyByZXF1ZXN0cwoKCgoDBAIBEgNXCB0KIAoEBAIC
ABIDWQIiGhMgTGlzdCBvZiBjdXN0b21lcnMKCgwKBQQCAgAEEgNZAgoKDAoFBAICAAYSA1kL
EwoMCgUEAgIAARIDWRQdCgwKBQQCAgADEgNZICEKjAEKBAQCAgESA10CHRp/IEEgdG9rZW4g
dGhhdCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVl
bnQgcGFnZXMuCgoMCgUEAgIBBRIDXQIICgwKBQQCAgEBEgNdCRgKDAoFBAICAQMSA10bHAoz
CgQEAgICEgNgAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCgwK
BQQCAgIEEgNgAgoKDAoFBAICAgUSA2ALEQoMCgUEAgICARIDYBIdCgwKBQQCAgIDEgNgICEK
KgoCBAMSBGQAdQEaHiBSZXF1ZXN0IHRvIGNyZWF0ZSBhIGN1c3RvbWVyCgoKCgMEAwESA2QI
HQpmCgQEAwIAEgRnAmwEGlggUmVxdWlyZWQuIFBhcmVudCByZXNvdXJjZQogRm9ybWF0OiBg
b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCgwK
BQQDAgAFEgNnAggKDAoFBAMCAAESA2cJDwoMCgUEAwIAAxIDZxITCg0KBQQDAgAIEgRnFGwD
Cg8KCAQDAgAInAgAEgNoBCoKDwoHBAMCAAifCBIEaQRrBQowCgQEAwIBEgNvAkEaIyBSZXF1
aXJlZC4gVGhlIGN1c3RvbWVyIHRvIGNyZWF0ZS4KCgwKBQQDAgEGEgNvAgoKDAoFBAMCAQES
A28LEwoMCgUEAwIBAxIDbxYXCgwKBQQDAgEIEgNvGEAKDwoIBAMCAQicCAASA28ZPwrNAQoE
BAMCAhIDdAJCGr8BIFJlcXVpcmVkLiBUaGUgY3VzdG9tZXIgaWQgdG8gdXNlIGZvciB0aGUg
Y3VzdG9tZXIsIHdoaWNoIHdpbGwgYmVjb21lIHRoZQogZmluYWwgY29tcG9uZW50IG9mIHRo
ZSBjdXN0b21lcidzIHJlc291cmNlIG5hbWUuIFRoZSBzcGVjaWZpZWQgdmFsdWUgbXVzdAog
YmUgYSB2YWxpZCBHb29nbGUgY2xvdWQgb3JnYW5pemF0aW9uIGlkLgoKDAoFBAMCAgUSA3QC
CAoMCgUEAwICARIDdAkUCgwKBQQDAgIDEgN0FxgKDAoFBAMCAggSA3QZQQoPCggEAwICCJwI
ABIDdBpACi0KAgQEEgV4AIEBARogIE1lc3NhZ2UgZm9yIGdldHRpbmcgYSBjdXN0b21lcgoK
CgoDBAQBEgN4CBoKbAoEBAQCABIFewKAAQQaXSBSZXF1aXJlZC4gRm9ybWF0OgogYG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY3VzdG9tZXJz
L3tjdXN0b21lcn1gCgoMCgUEBAIABRIDewIICgwKBQQEAgABEgN7CQ0KDAoFBAQCAAMSA3sQ
EQoOCgUEBAIACBIFexKAAQMKDwoIBAQCAAicCAASA3wEKgoPCgcEBAIACJ8IEgR9BH8FCjcK
AgQFEgaEAQCHAQEaKSBDb250YWluZXIgZm9yIGN1c3RvbWVyIG9uYm9hcmRpbmcgc3RlcHMK
CgsKAwQFARIEhAEIHwoxCgQEBQIAEgSGAQI3GiMgTGlzdCBvZiBjdXN0b21lciBvbmJvYXJk
aW5nIHN0ZXBzCgoNCgUEBQIABBIEhgECCgoNCgUEBQIABhIEhgELIQoNCgUEBQIAARIEhgEi
MgoNCgUEBQIAAxIEhgE1Ngo9CgIEBhIGigEAowEBGi8gQ29udGFpbmVyIGZvciBjdXN0b21l
ciBvbmJvYXJkaW5nIGluZm9ybWF0aW9uCgoLCgMEBgESBIoBCB4KNAoEBAYEABIGjAEClQED
GiQgRW51bSBmb3IgcG9zc2libGUgb25ib2FyZGluZyBzdGVwcwoKDQoFBAYEAAESBIwBBwsK
IgoGBAYEAAIAEgSOAQQZGhIgVW5zcGVjaWZpZWQgc3RlcAoKDwoHBAYEAAIAARIEjgEEFAoP
CgcEBgQAAgACEgSOARcYCiAKBgQGBAACARIEkQEEFxoQIEtBSiBFbnJvbGxtZW50CgoPCgcE
BgQAAgEBEgSRAQQSCg8KBwQGBAACAQISBJEBFRYKJgoGBAYEAAICEgSUAQQdGhYgQ3VzdG9t
ZXIgRW52aXJvbm1lbnQKCg8KBwQGBAACAgESBJQBBBgKDwoHBAYEAAICAhIElAEbHAojCgQE
BgIAEgSYAQIQGhUgVGhlIG9uYm9hcmRpbmcgc3RlcAoKDQoFBAYCAAYSBJgBAgYKDQoFBAYC
AAESBJgBBwsKDQoFBAYCAAMSBJgBDg8KOAoEBAYCARIEmwECKxoqIFRoZSBzdGFydGluZyB0
aW1lIG9mIHRoZSBvbmJvYXJkaW5nIHN0ZXAKCg0KBQQGAgEGEgSbAQIbCg0KBQQGAgEBEgSb
ARwmCg0KBQQGAgEDEgSbASkqCjoKBAQGAgISBJ4BAjAaLCBUaGUgY29tcGxldGlvbiB0aW1l
IG9mIHRoZSBvbmJvYXJkaW5nIHN0ZXAKCg0KBQQGAgIGEgSeAQIbCg0KBQQGAgIBEgSeARwr
Cg0KBQQGAgIDEgSeAS4vCjgKBAQGAgMSBqEBAqIBMhooIE91dHB1dCBvbmx5LiBDdXJyZW50
IHN0YXRlIG9mIHRoZSBzdGVwCgoNCgUEBgIDBhIEoQECEQoNCgUEBgIDARIEoQESIgoNCgUE
BgIDAxIEoQElJgoNCgUEBgIDCBIEogEGMQoQCggEBgIDCJwIABIEogEHMAosCgIEBxIGpgEA
rwEBGh4gUmVxdWVzdCB0byB1cGRhdGUgYSBjdXN0b21lcgoKCwoDBAcBEgSmAQgdCoMBCgQE
BwIAEgSqAQJBGnUgUmVxdWlyZWQuIFRoZSBjdXN0b21lciB0byB1cGRhdGUKIEZvcm1hdDoK
IGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2N1
c3RvbWVycy97Y3VzdG9tZXJ9YAoKDQoFBAcCAAYSBKoBAgoKDQoFBAcCAAESBKoBCxMKDQoF
BAcCAAMSBKoBFhcKDQoFBAcCAAgSBKoBGEAKEAoIBAcCAAicCAASBKoBGT8KOAoEBAcCARIG
rQECrgEvGiggT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUKCg0KBQQH
AgEGEgStAQIbCg0KBQQHAgEBEgStARwnCg0KBQQHAgEDEgStASorCg0KBQQHAgEIEgSuAQYu
ChAKCAQHAgEInAgAEgSuAQctCi0KAgQIEgayAQC7AQEaHyBNZXNzYWdlIGZvciBkZWxldGlu
ZyBjdXN0b21lcgoKCwoDBAgBEgSyAQgdCnQKBAQIAgASBrUBAroBBBpkIFJlcXVpcmVkLiBu
YW1lIG9mIHRoZSByZXNvdXJjZSB0byBiZSBkZWxldGVkCiBmb3JtYXQ6IG5hbWU9b3JnYW5p
emF0aW9ucy8qL2xvY2F0aW9ucy8qL2N1c3RvbWVycy8qCgoNCgUECAIABRIEtQECCAoNCgUE
CAIAARIEtQEJDQoNCgUECAIAAxIEtQEQEQoPCgUECAIACBIGtQESugEDChAKCAQIAgAInAgA
EgS2AQQqChEKBwQIAgAInwgSBrcBBLkBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer ===
    # Fields for Customer
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: customer_onboarding_state Type: 11 (.google.cloud.cloudcontrolspartner.v1.CustomerOnboardingState)
    # Field: is_onboarded Type: 8 ()
    # Field: organization_domain Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersRequest ===
    # Fields for ListCustomersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersResponse ===
    # Fields for ListCustomersResponse
    # Field: customers Type: 11 (.google.cloud.cloudcontrolspartner.v1.Customer)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::CreateCustomerRequest ===
    # Fields for CreateCustomerRequest
    # Field: parent Type: 9 ()
    # Field: customer Type: 11 (.google.cloud.cloudcontrolspartner.v1.Customer)
    # Field: customer_id Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::GetCustomerRequest ===
    # Fields for GetCustomerRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingState ===
    # Fields for CustomerOnboardingState
    # Field: onboarding_steps Type: 11 (.google.cloud.cloudcontrolspartner.v1.CustomerOnboardingStep)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingStep ===
    # Fields for CustomerOnboardingStep
    # Field: step Type: 14 (.google.cloud.cloudcontrolspartner.v1.CustomerOnboardingStep.Step)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: completion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: completion_state Type: 14 (.google.cloud.cloudcontrolspartner.v1.CompletionState)

# Enum: CustomerOnboardingStep::Step
our $CustomerOnboardingStep_STEP_UNSPECIFIED = 0;
our $CustomerOnboardingStep_KAJ_ENROLLMENT = 1;
our $CustomerOnboardingStep_CUSTOMER_ENVIRONMENT = 2;

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::UpdateCustomerRequest ===
    # Fields for UpdateCustomerRequest
    # Field: customer Type: 11 (.google.cloud.cloudcontrolspartner.v1.Customer)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Customers::DeleteCustomerRequest ===
    # Fields for DeleteCustomerRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Customers - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/customers.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::Customers;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer->new({
        name => $name,
        display_name => $display_name,
        customer_onboarding_state => $customer_onboarding_state,
        is_onboarded => $is_onboarded,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/customers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer

Contains metadata around a Cloud Controls Partner Customer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Format:
`organizations/{organization}/locations/{location}/customers/{customer}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name for the customer

=item * C<< $msg->customer_onboarding_state() >> / C<< $msg->customer_onboarding_state($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingState>)

Output only. Container for customer onboarding steps

=item * C<< $msg->is_onboarded() >> / C<< $msg->is_onboarded($value) >>

Type: C<Bool>

Output only. Indicates whether a customer is fully onboarded

=item * C<< $msg->organization_domain() >> / C<< $msg->organization_domain($value) >>

Type: C<String>

Output only. The customer organization domain, extracted from
CRM Organization’s display_name field. e.g. "google.com"

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersRequest

Request to list customers

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource
Format: `organizations/{organization}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of Customers to return. The service may return fewer
than this value. If unspecified, at most 500 Customers will be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListCustomers` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersResponse

Response message for list customer Customers requests

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->customers() >> / C<< $msg->customers($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer>)

List of customers

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::CreateCustomerRequest

Request to create a customer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource
Format: `organizations/{organization}/locations/{location}`

=item * C<< $msg->customer() >> / C<< $msg->customer($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer>)

Required. The customer to create.

=item * C<< $msg->customer_id() >> / C<< $msg->customer_id($value) >>

Type: C<String>

Required. The customer id to use for the customer, which will become the
final component of the customer's resource name. The specified value must
be a valid Google cloud organization id.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::GetCustomerRequest

Message for getting a customer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`organizations/{organization}/locations/{location}/customers/{customer}`

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingState

Container for customer onboarding steps

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->onboarding_steps() >> / C<< $msg->onboarding_steps($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingStep>)

List of customer onboarding steps

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingStep

Container for customer onboarding information

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->step() >> / C<< $msg->step($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::CustomerOnboardingStep::Step>)

The onboarding step

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The starting time of the onboarding step

=item * C<< $msg->completion_time() >> / C<< $msg->completion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The completion time of the onboarding step

=item * C<< $msg->completion_state() >> / C<< $msg->completion_state($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::CompletionState>)

Output only. Current state of the step

=back

=head3 Enum: CustomerOnboardingStep::Step

=over 4

=item * C<STEP_UNSPECIFIED> => C<0>

=item * C<KAJ_ENROLLMENT> => C<1>

=item * C<CUSTOMER_ENVIRONMENT> => C<2>

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::UpdateCustomerRequest

Request to update a customer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->customer() >> / C<< $msg->customer($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer>)

Required. The customer to update
Format:
`organizations/{organization}/locations/{location}/customers/{customer}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Customers::DeleteCustomerRequest

Message for deleting customer

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. name of the resource to be deleted
format: name=organizations/*/locations/*/customers/*

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::Customers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
