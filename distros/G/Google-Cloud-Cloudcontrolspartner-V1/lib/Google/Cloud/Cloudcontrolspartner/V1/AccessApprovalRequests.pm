package Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvYWNjZXNzX2FwcHJvdmFs
X3JlcXVlc3RzLnByb3RvEiRnb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipgQKFUFjY2Vzc0FwcHJv
dmFsUmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSPQoMcmVxdWVzdF90aW1lGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFILcmVxdWVzdFRpbWUSXQoQcmVxdWVz
dGVkX3JlYXNvbhgDIAEoCzIyLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52
MS5BY2Nlc3NSZWFzb25SD3JlcXVlc3RlZFJlYXNvbhJWChlyZXF1ZXN0ZWRfZXhwaXJhdGlv
bl90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIXcmVxdWVzdGVkRXhw
aXJhdGlvblRpbWU6/QHqQfkBCjljbG91ZGNvbnRyb2xzcGFydG5lci5nb29nbGVhcGlzLmNv
bS9BY2Nlc3NBcHByb3ZhbFJlcXVlc3QSjAFvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259
L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbWVycy97Y3VzdG9tZXJ9L3dvcmtsb2Fkcy97
d29ya2xvYWR9L2FjY2Vzc0FwcHJvdmFsUmVxdWVzdHMve2FjY2Vzc19hcHByb3ZhbF9yZXF1
ZXN0fSoWYWNjZXNzQXBwcm92YWxSZXF1ZXN0czIVYWNjZXNzQXBwcm92YWxSZXF1ZXN0IoEC
CiFMaXN0QWNjZXNzQXBwcm92YWxSZXF1ZXN0c1JlcXVlc3QSWQoGcGFyZW50GAEgASgJQkHg
QQL6QTsSOWNsb3VkY29udHJvbHNwYXJ0bmVyLmdvb2dsZWFwaXMuY29tL0FjY2Vzc0FwcHJv
dmFsUmVxdWVzdFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIi
CgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BB
AVIGZmlsdGVyEh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnki5QEKIkxpc3RBY2Nl
c3NBcHByb3ZhbFJlcXVlc3RzUmVzcG9uc2USdQoYYWNjZXNzX2FwcHJvdmFsX3JlcXVlc3Rz
GAEgAygLMjsuZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLkFjY2Vzc0Fw
cHJvdmFsUmVxdWVzdFIWYWNjZXNzQXBwcm92YWxSZXF1ZXN0cxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hh
YmxlItACCgxBY2Nlc3NSZWFzb24SSwoEdHlwZRgBIAEoDjI3Lmdvb2dsZS5jbG91ZC5jbG91
ZGNvbnRyb2xzcGFydG5lci52MS5BY2Nlc3NSZWFzb24uVHlwZVIEdHlwZRIWCgZkZXRhaWwY
AiABKAlSBmRldGFpbCLaAQoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASHgoaQ1VTVE9N
RVJfSU5JVElBVEVEX1NVUFBPUlQQARIcChhHT09HTEVfSU5JVElBVEVEX1NFUlZJQ0UQAhIb
ChdHT09HTEVfSU5JVElBVEVEX1JFVklFVxADEhwKGFRISVJEX1BBUlRZX0RBVEFfUkVRVUVT
VBAEEicKI0dPT0dMRV9SRVNQT05TRV9UT19QUk9EVUNUSU9OX0FMRVJUEAUSGgoWQ0xPVURf
SU5JVElBVEVEX0FDQ0VTUxAGQp8CCihjb20uZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNw
YXJ0bmVyLnYxQhtBY2Nlc3NBcHByb3ZhbFJlcXVlc3RzUHJvdG9QAVpcY2xvdWQuZ29vZ2xl
LmNvbS9nby9jbG91ZGNvbnRyb2xzcGFydG5lci9hcGl2MS9jbG91ZGNvbnRyb2xzcGFydG5l
cnBiO2Nsb3VkY29udHJvbHNwYXJ0bmVycGKqAiRHb29nbGUuQ2xvdWQuQ2xvdWRDb250cm9s
c1BhcnRuZXIuVjHKAiRHb29nbGVcQ2xvdWRcQ2xvdWRDb250cm9sc1BhcnRuZXJcVjHqAidH
b29nbGU6OkNsb3VkOjpDbG91ZENvbnRyb2xzUGFydG5lcjo6VjFKlCcKBxIFDgCRAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAKQoJ
CgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBBCgkKAgglEgMWAEEKCAoBCBIDFwBzCgkK
AggLEgMXAHMKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA8CgkKAggIEgMZADwKCAoB
CBIDGgBBCgkKAggBEgMaAEEKCAoBCBIDGwBBCgkKAggpEgMbAEEKCAoBCBIDHABACgkKAggt
EgMcAEAKLwoCBAASBB8ANAEaIyBEZXRhaWxzIGFib3V0IHRoZSBBY2Nlc3MgcmVxdWVzdC4K
CgoKAwQAARIDHwgdCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBAqzAQoEBAACABIDKQI9
GqUBIElkZW50aWZpZXIuIEZvcm1hdDoKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259
L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbWVycy97Y3VzdG9tZXJ9L3dvcmtsb2Fkcy97
d29ya2xvYWR9L2FjY2Vzc0FwcHJvdmFsUmVxdWVzdHMve2FjY2Vzc19hcHByb3ZhbF9yZXF1
ZXN0fWAKCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJDQoMCgUEAAIAAxIDKRARCgwKBQQA
AgAIEgMpEjwKDwoIBAACAAicCAASAykTOwo4CgQEAAIBEgMsAi0aKyBUaGUgdGltZSBhdCB3
aGljaCBhcHByb3ZhbCB3YXMgcmVxdWVzdGVkLgoKDAoFBAACAQYSAywCGwoMCgUEAAIBARID
LBwoCgwKBQQAAgEDEgMsKywKRwoEBAACAhIDLwIkGjogVGhlIGp1c3RpZmljYXRpb24gZm9y
IHdoaWNoIGFwcHJvdmFsIGlzIGJlaW5nIHJlcXVlc3RlZC4KCgwKBQQAAgIGEgMvAg4KDAoF
BAACAgESAy8PHwoMCgUEAAICAxIDLyIjCqMBCgQEAAIDEgMzAjoalQEgVGhlIHJlcXVlc3Rl
ZCBleHBpcmF0aW9uIGZvciB0aGUgYXBwcm92YWwuIElmIHRoZSByZXF1ZXN0IGlzIGFwcHJv
dmVkLAogYWNjZXNzIHdpbGwgYmUgZ3JhbnRlZCBmcm9tIHRoZSB0aW1lIG9mIGFwcHJvdmFs
IHVudGlsIHRoZSBleHBpcmF0aW9uIHRpbWUuCgoMCgUEAAIDBhIDMwIbCgwKBQQAAgMBEgMz
HDUKDAoFBAACAwMSAzM4OQpRCgIEARIENwBRARpFIFJlcXVlc3QgZm9yIGdldHRpbmcgdGhl
IGFjY2VzcyByZXF1ZXN0cyBhc3NvY2lhdGVkIHdpdGggYSB3b3JrbG9hZC4KCgoKAwQBARID
NwgpCpIBCgQEAQIAEgQ7AkAEGoMBIFJlcXVpcmVkLiBQYXJlbnQgcmVzb3VyY2UKIEZvcm1h
dDoKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259
L2N1c3RvbWVycy97Y3VzdG9tZXJ9L3dvcmtsb2Fkcy97d29ya2xvYWR9YAoKDAoFBAECAAUS
AzsCCAoMCgUEAQIAARIDOwkPCgwKBQQBAgADEgM7EhMKDQoFBAECAAgSBDsUQAMKDwoIBAEC
AAicCAASAzwEKgoPCgcEAQIACJ8IEgQ9BD8FCrgBCgQEAQIBEgNFAj8aqgEgT3B0aW9uYWwu
IFRoZSBtYXhpbXVtIG51bWJlciBvZiBhY2Nlc3MgcmVxdWVzdHMgdG8gcmV0dXJuLiBUaGUg
c2VydmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuIElmIHVuc3BlY2lm
aWVkLCBhdCBtb3N0IDUwMCBhY2Nlc3MgcmVxdWVzdHMKIHdpbGwgYmUgcmV0dXJuZWQuCgoM
CgUEAQIBBRIDRQIHCgwKBQQBAgEBEgNFCBEKDAoFBAECAQMSA0UUFQoMCgUEAQIBCBIDRRY+
Cg8KCAQBAgEInAgAEgNFFz0KkwEKBAQBAgISA0oCQRqFASBPcHRpb25hbC4gQSBwYWdlIHRv
a2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIGBMaXN0QWNjZXNzQXBwcm92YWxSZXF1
ZXN0c2AgY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50CiBw
YWdlLgoKDAoFBAECAgUSA0oCCAoMCgUEAQICARIDSgkTCgwKBQQBAgIDEgNKFhcKDAoFBAEC
AggSA0oYQAoPCggEAQICCJwIABIDShk/CisKBAQBAgMSA00CPRoeIE9wdGlvbmFsLiBGaWx0
ZXJpbmcgcmVzdWx0cy4KCgwKBQQBAgMFEgNNAggKDAoFBAECAwESA00JDwoMCgUEAQIDAxID
TRITCgwKBQQBAgMIEgNNFDwKDwoIBAECAwicCAASA00VOwo7CgQEAQIEEgNQAj8aLiBPcHRp
b25hbC4gSGludCBmb3IgaG93IHRvIG9yZGVyIHRoZSByZXN1bHRzLgoKDAoFBAECBAUSA1AC
CAoMCgUEAQIEARIDUAkRCgwKBQQBAgQDEgNQFBUKDAoFBAECBAgSA1AWPgoPCggEAQIECJwI
ABIDUBc9CjgKAgQCEgRUAF4BGiwgUmVzcG9uc2UgbWVzc2FnZSBmb3IgbGlzdCBhY2Nlc3Mg
cmVxdWVzdHMuCgoKCgMEAgESA1QIKgovCgQEAgIAEgNWAj4aIiBMaXN0IG9mIGFjY2VzcyBh
cHByb3ZhbCByZXF1ZXN0cwoKDAoFBAICAAQSA1YCCgoMCgUEAgIABhIDVgsgCgwKBQQCAgAB
EgNWITkKDAoFBAICAAMSA1Y8PQqMAQoEBAICARIDWgIdGn8gQSB0b2tlbiB0aGF0IGNhbiBi
ZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYg
dGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4K
CgwKBQQCAgEFEgNaAggKDAoFBAICAQESA1oJGAoMCgUEAgIBAxIDWhscCjMKBAQCAgISA10C
IhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDAoFBAICAgQSA10C
CgoMCgUEAgICBRIDXQsRCgwKBQQCAgIBEgNdEh0KDAoFBAICAgMSA10gIQolCgIEAxIFYQCR
AQEaGCBSZWFzb24gZm9yIHRoZSBhY2Nlc3MuCgoKCgMEAwESA2EIFAouCgQEAwQAEgVjAooB
AxofIFR5cGUgb2YgYWNjZXNzIGp1c3RpZmljYXRpb24uCgoMCgUEAwQAARIDYwcLCjwKBgQD
BAACABIDZQQZGi0gRGVmYXVsdCB2YWx1ZSBmb3IgcHJvdG8sIHNob3VsZG4ndCBiZSB1c2Vk
LgoKDgoHBAMEAAIAARIDZQQUCg4KBwQDBAACAAISA2UXGAqpAgoGBAMEAAIBEgNwBCMamQIg
Q3VzdG9tZXIgbWFkZSBhIHJlcXVlc3Qgb3IgcmFpc2VkIGFuIGlzc3VlIHRoYXQgcmVxdWly
ZWQgdGhlIHByaW5jaXBhbCB0bwogYWNjZXNzIGN1c3RvbWVyIGRhdGEuIGBkZXRhaWxgIGlz
IG9mIHRoZSBmb3JtICgiIyMjIyMiIGlzIHRoZSBpc3N1ZSBJRCk6CgogLSAiRmVlZGJhY2sg
UmVwb3J0OiAjIyMjIyIKIC0gIkNhc2UgTnVtYmVyOiAjIyMjIyIKIC0gIkNhc2UgSUQ6ICMj
IyMjIgogLSAiRS1QSU4gUmVmZXJlbmNlOiAjIyMjIyIKIC0gIkdvb2dsZS0jIyMjIyIKIC0g
IlQtIyMjIyMiCgoOCgcEAwQAAgEBEgNwBB4KDgoHBAMEAAIBAhIDcCEiCoUCCgYEAwQAAgIS
A3YEIRr1ASBUaGUgcHJpbmNpcGFsIGFjY2Vzc2VkIGN1c3RvbWVyIGRhdGEgaW4gb3JkZXIg
dG8gZGlhZ25vc2Ugb3IgcmVzb2x2ZSBhCiBzdXNwZWN0ZWQgaXNzdWUgaW4gc2VydmljZXMu
IE9mdGVuIHRoaXMgYWNjZXNzIGlzIHVzZWQgdG8gY29uZmlybSB0aGF0CiBjdXN0b21lcnMg
YXJlIG5vdCBhZmZlY3RlZCBieSBhIHN1c3BlY3RlZCBzZXJ2aWNlIGlzc3VlIG9yIHRvIHJl
bWVkaWF0ZSBhCiByZXZlcnNpYmxlIHN5c3RlbSBpc3N1ZS4KCg4KBwQDBAACAgESA3YEHAoO
CgcEAwQAAgICEgN2HyAKXgoGBAMEAAIDEgN6BCAaTyBHb29nbGUgaW5pdGlhdGVkIHNlcnZp
Y2UgZm9yIHNlY3VyaXR5LCBmcmF1ZCwgYWJ1c2UsIG9yIGNvbXBsaWFuY2UKIHB1cnBvc2Vz
LgoKDgoHBAMEAAIDARIDegQbCg4KBwQDBAACAwISA3oeHwrAAQoGBAMEAAIEEgN/BCEasAEg
VGhlIHByaW5jaXBhbCB3YXMgY29tcGVsbGVkIHRvIGFjY2VzcyBjdXN0b21lciBkYXRhIGlu
IG9yZGVyIHRvIHJlc3BvbmQKIHRvIGEgbGVnYWwgdGhpcmQgcGFydHkgZGF0YSByZXF1ZXN0
IG9yIHByb2Nlc3MsIGluY2x1ZGluZyBsZWdhbCBwcm9jZXNzZXMKIGZyb20gY3VzdG9tZXJz
IHRoZW1zZWx2ZXMuCgoOCgcEAwQAAgQBEgN/BBwKDgoHBAMEAAIEAhIDfx8gCogBCgYEAwQA
AgUSBIMBBCwaeCBUaGUgcHJpbmNpcGFsIGFjY2Vzc2VkIGN1c3RvbWVyIGRhdGEgaW4gb3Jk
ZXIgdG8gZGlhZ25vc2Ugb3IgcmVzb2x2ZSBhCiBzdXNwZWN0ZWQgaXNzdWUgaW4gc2Vydmlj
ZXMgb3IgYSBrbm93biBvdXRhZ2UuCgoPCgcEAwQAAgUBEgSDAQQnCg8KBwQDBAACBQISBIMB
KisKsAIKBgQDBAACBhIEiQEEHxqfAiBTaW1pbGFyIHRvICdHT09HTEVfSU5JVElBVEVEX1NF
UlZJQ0UnIG9yICdHT09HTEVfSU5JVElBVEVEX1JFVklFVycsIGJ1dAogd2l0aCB1bml2ZXJz
ZSBhZ25vc3RpYyBuYW1pbmcuIFRoZSBwcmluY2lwYWwgYWNjZXNzZWQgY3VzdG9tZXIgZGF0
YSBpbgogb3JkZXIgdG8gZGlhZ25vc2Ugb3IgcmVzb2x2ZSBhIHN1c3BlY3RlZCBpc3N1ZSBp
biBzZXJ2aWNlcyBvciBhIGtub3duCiBvdXRhZ2UsIG9yIGZvciBzZWN1cml0eSwgZnJhdWQs
IGFidXNlLCBvciBjb21wbGlhbmNlIHJldmlldyBwdXJwb3Nlcy4KCg8KBwQDBAACBgESBIkB
BBoKDwoHBAMEAAIGAhIEiQEdHgotCgQEAwIAEgSNAQIQGh8gVHlwZSBvZiBhY2Nlc3MganVz
dGlmaWNhdGlvbi4KCg0KBQQDAgAGEgSNAQIGCg0KBQQDAgABEgSNAQcLCg0KBQQDAgADEgSN
AQ4PClkKBAQDAgESBJABAhQaSyBNb3JlIGRldGFpbCBhYm91dCBjZXJ0YWluIHJlYXNvbiB0
eXBlcy4gU2VlIGNvbW1lbnRzIGZvciBlYWNoIHR5cGUgYWJvdmUuCgoNCgUEAwIBBRIEkAEC
CAoNCgUEAwIBARIEkAEJDwoNCgUEAwIBAxIEkAESE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest ===
    # Fields for AccessApprovalRequest
    # Field: name Type: 9 ()
    # Field: request_time Type: 11 (.google.protobuf.Timestamp)
    # Field: requested_reason Type: 11 (.google.cloud.cloudcontrolspartner.v1.AccessReason)
    # Field: requested_expiration_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsRequest ===
    # Fields for ListAccessApprovalRequestsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsResponse ===
    # Fields for ListAccessApprovalRequestsResponse
    # Field: access_approval_requests Type: 11 (.google.cloud.cloudcontrolspartner.v1.AccessApprovalRequest)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessReason ===
    # Fields for AccessReason
    # Field: type Type: 14 (.google.cloud.cloudcontrolspartner.v1.AccessReason.Type)
    # Field: detail Type: 9 ()

# Enum: AccessReason::Type
our $AccessReason_TYPE_UNSPECIFIED = 0;
our $AccessReason_CUSTOMER_INITIATED_SUPPORT = 1;
our $AccessReason_GOOGLE_INITIATED_SERVICE = 2;
our $AccessReason_GOOGLE_INITIATED_REVIEW = 3;
our $AccessReason_THIRD_PARTY_DATA_REQUEST = 4;
our $AccessReason_GOOGLE_RESPONSE_TO_PRODUCTION_ALERT = 5;
our $AccessReason_CLOUD_INITIATED_ACCESS = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/access_approval_requests.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest->new({
        name => $name,
        request_time => $request_time,
        requested_reason => $requested_reason,
        requested_expiration_time => $requested_expiration_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/access_approval_requests.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest

Details about the Access request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/accessApprovalRequests/{access_approval_request}`

=item * C<< $msg->request_time() >> / C<< $msg->request_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which approval was requested.

=item * C<< $msg->requested_reason() >> / C<< $msg->requested_reason($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessReason>)

The justification for which approval is being requested.

=item * C<< $msg->requested_expiration_time() >> / C<< $msg->requested_expiration_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The requested expiration for the approval. If the request is approved,
access will be granted from the time of approval until the expiration time.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsRequest

Request for getting the access requests associated with a workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource
Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of access requests to return. The service may
return fewer than this value. If unspecified, at most 500 access requests
will be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAccessApprovalRequests` call. Provide this to retrieve the subsequent
page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsResponse

Response message for list access requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_approval_requests() >> / C<< $msg->access_approval_requests($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest>)

List of access approval requests

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessReason

Reason for the access.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::AccessReason::Type>)

Type of access justification.

=item * C<< $msg->detail() >> / C<< $msg->detail($value) >>

Type: C<String>

More detail about certain reason types. See comments for each type above.

=back

=head3 Enum: AccessReason::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<CUSTOMER_INITIATED_SUPPORT> => C<1>

=item * C<GOOGLE_INITIATED_SERVICE> => C<2>

=item * C<GOOGLE_INITIATED_REVIEW> => C<3>

=item * C<THIRD_PARTY_DATA_REQUEST> => C<4>

=item * C<GOOGLE_RESPONSE_TO_PRODUCTION_ALERT> => C<5>

=item * C<CLOUD_INITIATED_ACCESS> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
