package Google::Cloud::Apigeeconnect::V1::Tether;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    eval { require Google::Rpc::Status };
    eval { require Google::Api::Client };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvYXBpZ2VlY29ubmVjdC92MS90ZXRoZXIucHJvdG8SHWdvb2dsZS5j
bG91ZC5hcGlnZWVjb25uZWN0LnYxGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8a
F2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90byKWAgoN
RWdyZXNzUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSQAoHcGF5bG9hZBgCIAEoCzImLmdvb2ds
ZS5jbG91ZC5hcGlnZWVjb25uZWN0LnYxLlBheWxvYWRSB3BheWxvYWQSSQoIZW5kcG9pbnQY
AyABKA4yLS5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MS5UZXRoZXJFbmRwb2ludFII
ZW5kcG9pbnQSGAoHcHJvamVjdBgEIAEoCVIHcHJvamVjdBIZCgh0cmFjZV9pZBgFIAEoCVIH
dHJhY2VJZBIzCgd0aW1lb3V0GAYgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgd0
aW1lb3V0IvEBCgdQYXlsb2FkEk8KDGh0dHBfcmVxdWVzdBgBIAEoCzIqLmdvb2dsZS5jbG91
ZC5hcGlnZWVjb25uZWN0LnYxLkh0dHBSZXF1ZXN0SABSC2h0dHBSZXF1ZXN0EkwKC3N0cmVh
bV9pbmZvGAIgASgLMikuZ29vZ2xlLmNsb3VkLmFwaWdlZWNvbm5lY3QudjEuU3RyZWFtSW5m
b0gAUgpzdHJlYW1JbmZvEj8KBmFjdGlvbhgDIAEoDjIlLmdvb2dsZS5jbG91ZC5hcGlnZWVj
b25uZWN0LnYxLkFjdGlvbkgAUgZhY3Rpb25CBgoEa2luZCIcCgpTdHJlYW1JbmZvEg4KAmlk
GAEgASgJUgJpZCKyAgoORWdyZXNzUmVzcG9uc2USDgoCaWQYASABKAlSAmlkElAKDWh0dHBf
cmVzcG9uc2UYAiABKAsyKy5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MS5IdHRwUmVz
cG9uc2VSDGh0dHBSZXNwb25zZRIqCgZzdGF0dXMYAyABKAsyEi5nb29nbGUucnBjLlN0YXR1
c1IGc3RhdHVzEhgKB3Byb2plY3QYBCABKAlSB3Byb2plY3QSGQoIdHJhY2VfaWQYBSABKAlS
B3RyYWNlSWQSSQoIZW5kcG9pbnQYBiABKA4yLS5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVj
dC52MS5UZXRoZXJFbmRwb2ludFIIZW5kcG9pbnQSEgoEbmFtZRgHIAEoCVIEbmFtZSLAAQoL
SHR0cFJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhYKBm1ldGhvZBgCIAEoCVIGbWV0aG9kEjQK
A3VybBgDIAEoCzIiLmdvb2dsZS5jbG91ZC5hcGlnZWVjb25uZWN0LnYxLlVybFIDdXJsEj8K
B2hlYWRlcnMYBCADKAsyJS5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MS5IZWFkZXJS
B2hlYWRlcnMSEgoEYm9keRgFIAEoDFIEYm9keSJsCgNVcmwSPQoGc2NoZW1lGAEgASgOMiUu
Z29vZ2xlLmNsb3VkLmFwaWdlZWNvbm5lY3QudjEuU2NoZW1lUgZzY2hlbWUSEgoEaG9zdBgC
IAEoCVIEaG9zdBISCgRwYXRoGAMgASgJUgRwYXRoIjIKBkhlYWRlchIQCgNrZXkYASABKAlS
A2tleRIWCgZ2YWx1ZXMYAiADKAlSBnZhbHVlcyLTAQoMSHR0cFJlc3BvbnNlEg4KAmlkGAEg
ASgJUgJpZBIWCgZzdGF0dXMYAiABKAlSBnN0YXR1cxIfCgtzdGF0dXNfY29kZRgDIAEoBVIK
c3RhdHVzQ29kZRISCgRib2R5GAQgASgMUgRib2R5Ej8KB2hlYWRlcnMYBSADKAsyJS5nb29n
bGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MS5IZWFkZXJSB2hlYWRlcnMSJQoOY29udGVudF9s
ZW5ndGgYBiABKANSDWNvbnRlbnRMZW5ndGgqNQoGQWN0aW9uEhYKEkFDVElPTl9VTlNQRUNJ
RklFRBAAEhMKD09QRU5fTkVXX1NUUkVBTRABKm4KDlRldGhlckVuZHBvaW50Eh8KG1RFVEhF
Ul9FTkRQT0lOVF9VTlNQRUNJRklFRBAAEg8KC0FQSUdFRV9NQVJUEAESEgoOQVBJR0VFX1JV
TlRJTUUQAhIWChJBUElHRUVfTUlOVF9SQVRJTkcQAyorCgZTY2hlbWUSFgoSU0NIRU1FX1VO
U1BFQ0lGSUVEEAASCQoFSFRUUFMQATLHAQoGVGV0aGVyEmsKBkVncmVzcxItLmdvb2dsZS5j
bG91ZC5hcGlnZWVjb25uZWN0LnYxLkVncmVzc1Jlc3BvbnNlGiwuZ29vZ2xlLmNsb3VkLmFw
aWdlZWNvbm5lY3QudjEuRWdyZXNzUmVxdWVzdCIAKAEwARpQykEcYXBpZ2VlY29ubmVjdC5n
b29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQt
cGxhdGZvcm1C3gEKIWNvbS5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MUILVGV0aGVy
UHJvdG9QAVpHY2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlnZWVjb25uZWN0L2FwaXYxL2FwaWdl
ZWNvbm5lY3RwYjthcGlnZWVjb25uZWN0cGKqAh1Hb29nbGUuQ2xvdWQuQXBpZ2VlQ29ubmVj
dC5WMcoCHUdvb2dsZVxDbG91ZFxBcGlnZWVDb25uZWN0XFYx6gIgR29vZ2xlOjpDbG91ZDo6
QXBpZ2VlQ29ubmVjdDo6VjFK8jEKBxIFDgDWAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAKAoJCgIDARIDEwAhCgkKAgMCEgMUACEK
CAoBCBIDFgA6CgkKAgglEgMWADoKCAoBCBIDFwBeCgkKAggLEgMXAF4KCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgA6CgkKAggBEgMaADoKCAoB
CBIDGwA6CgkKAggpEgMbADoKCAoBCBIDHAA5CgkKAggtEgMcADkK2AEKAgYAEgQhAC4BGssB
IFRldGhlciBwcm92aWRlcyBhIHdheSBmb3IgdGhlIGNvbnRyb2wgcGxhbmUgdG8gc2VuZCBI
VFRQIEFQSSByZXF1ZXN0cyB0bwogc2VydmljZXMgaW4gZGF0YSBwbGFuZXMgdGhhdCBydW5z
IGluIGEgcmVtb3RlIGRhdGFjZW50ZXIgd2l0aG91dAogcmVxdWlyaW5nIGN1c3RvbWVycyB0
byBvcGVuIGZpcmV3YWxscyBvbiB0aGVpciBydW50aW1lIHBsYW5lLgoKCgoDBgABEgMhCA4K
CgoDBgADEgMiAkQKDAoFBgADmQgSAyICRAoKCgMGAAMSAyMCVgoMCgUGAAOaCBIDIwJWCo8D
CgQGAAIAEgQsAi0DGoADIEVncmVzcyBzdHJlYW1zIGVncmVzcyByZXF1ZXN0cyBhbmQgcmVz
cG9uc2VzLiBMb2dpY2FsbHksIHRoaXMgaXMgbm90CiBhY3R1YWxseSBhIHN0cmVhbWluZyBy
ZXF1ZXN0LCBidXQgdXNlcyBzdHJlYW1pbmcgYXMgYSBtZWNoYW5pc20gdG8gZmxpcAogdGhl
IGNsaWVudC1zZXJ2ZXIgcmVsYXRpb25zaGlwIG9mIGdSUEMgc28gdGhhdCB0aGUgc2VydmVy
IGNhbiBhY3QgYXMgYQogY2xpZW50LgogVGhlIGxpc3RlbmVyLCB0aGUgUlBDIHNlcnZlciwg
YWNjZXB0cyBjb25uZWN0aW9ucyBmcm9tIHRoZSBkaWFsZXIsCiB0aGUgUlBDIGNsaWVudC4K
IFRoZSBsaXN0ZW5lciBzdHJlYW1zIGh0dHAgcmVxdWVzdHMgYW5kIHRoZSBkaWFsZXIgc3Ry
ZWFtcyBodHRwIHJlc3BvbnNlcy4KCgwKBQYAAgABEgMsBgwKDAoFBgACAAUSAywNEwoMCgUG
AAIAAhIDLBQiCgwKBQYAAgAGEgMsLTMKDAoFBgACAAMSAyw0QQouCgIEABIEMQBEARoiIGdS
UEMgcmVxdWVzdCBwYXlsb2FkIGZvciB0ZXRoZXIuCgoKCgMEAAESAzEIFQoxCgQEAAIAEgMz
AhAaJCBVbmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIHJlcXVlc3QuCgoMCgUEAAIABRIDMwII
CgwKBQQAAgABEgMzCQsKDAoFBAACAAMSAzMODwovCgQEAAIBEgM2AhYaIiBBY3R1YWwgcGF5
bG9hZCB0byBzZW5kIHRvIGFnZW50LgoKDAoFBAACAQYSAzYCCQoMCgUEAAIBARIDNgoRCgwK
BQQAAgEDEgM2FBUKHwoEBAACAhIDOQIeGhIgVGV0aGVyIEVuZHBvaW50LgoKDAoFBAACAgYS
AzkCEAoMCgUEAAICARIDOREZCgwKBQQAAgIDEgM5HB0KQQoEBAACAxIDPQIVGjQgR0NQIFBy
b2plY3QuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9YC4KCgwKBQQAAgMF
EgM9AggKDAoFBAACAwESAz0JEAoMCgUEAAIDAxIDPRMUCk0KBAQAAgQSA0ACFhpAIFVuaXF1
ZSBpZGVudGlmaWVyIGZvciBjbGllbnRzIHRvIHRyYWNlIHRoZWlyIHJlcXVlc3QvcmVzcG9u
c2UuCgoMCgUEAAIEBRIDQAIICgwKBQQAAgQBEgNACREKDAoFBAACBAMSA0AUFQosCgQEAAIF
EgNDAicaHyBUaW1lb3V0IGZvciB0aGUgSFRUUCByZXF1ZXN0LgoKDAoFBAACBQYSA0MCGgoM
CgUEAAIFARIDQxsiCgwKBQQAAgUDEgNDJSYKKAoCBAESBEcAUwEaHCBQYXlsb2FkIGZvciBF
Z3Jlc3NSZXF1ZXN0LgoKCgoDBAEBEgNHCA8KJAoEBAEIABIESQJSAxoWIFRoZSBraW5kIG9m
IHBheWxvYWQuCgoMCgUEAQgAARIDSQgMCiUKBAQBAgASA0sEIRoYIFRoZSBIdHRwUmVxdWVz
dCBwcm90by4KCgwKBQQBAgAGEgNLBA8KDAoFBAECAAESA0sQHAoMCgUEAQIAAxIDSx8gCikK
BAQBAgESA04EHxocIFRoZSBpbmZvcm1hdGlvbiBvZiBzdHJlYW0uCgoMCgUEAQIBBhIDTgQO
CgwKBQQBAgEBEgNODxoKDAoFBAECAQMSA04dHgopCgQEAQICEgNRBBYaHCBUaGUgYWN0aW9u
IHRha2VuIGJ5IGFnZW50LgoKDAoFBAECAgYSA1EECgoMCgUEAQICARIDUQsRCgwKBQQBAgID
EgNRFBUKNwoCBAISBFYAWQEaKyBUaGUgSW5mb3JtYXRpb24gb2YgYmktZGlyZWN0aW9uYWwg
c3RyZWFtLgoKCgoDBAIBEgNWCBIKMAoEBAICABIDWAIQGiMgVW5pcXVlIGlkZW50aWZpZXIg
Zm9yIHRoZSBzdHJlYW0uCgoMCgUEAgIABRIDWAIICgwKBQQCAgABEgNYCQsKDAoFBAICAAMS
A1gODwooCgIFABIEXABiARocIFRoZSBhY3Rpb24gdGFrZW4gYnkgYWdlbnQuCgoKCgMFAAES
A1wFCwoiCgQFAAIAEgNeAhkaFSBVbnNwZWNpZmllZCBBY3Rpb24uCgoMCgUFAAIAARIDXgIU
CgwKBQUAAgACEgNeFxgKPQoEBQACARIDYQIWGjAgSW5kaWNhdGVzIHRoYXQgYWdlbnQgc2hv
dWxkIG9wZW4gYSBuZXcgc3RyZWFtLgoKDAoFBQACAQESA2ECEQoMCgUFAAIBAhIDYRQVCi8K
AgQDEgRlAH0BGiMgZ1JQQyByZXNwb25zZSBwYXlsb2FkIGZvciB0ZXRoZXIuCgoKCgMEAwES
A2UIFgpSCgQEAwIAEgNnAhAaRSBVbmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIHJlc3BvbnNl
LiBNYXRjaGVzIHRoZSBFZ3Jlc3NSZXF1ZXN0J3MgaWQuCgoMCgUEAwIABRIDZwIICgwKBQQD
AgABEgNnCQsKDAoFBAMCAAMSA2cODwocCgQEAwIBEgNqAiEaDyBIdHRwUmVzcG9uc2UuCgoM
CgUEAwIBBhIDagIOCgwKBQQDAgEBEgNqDxwKDAoFBAMCAQMSA2ofIApGCgQEAwICEgNtAh8a
OSBFcnJvcnMgZnJvbSBhcHBsaWNhdGlvbiB3aGVuIGhhbmRsaW5nIHRoZSBodHRwIHJlcXVl
c3QuCgoMCgUEAwICBhIDbQITCgwKBQQDAgIBEgNtFBoKDAoFBAMCAgMSA20dHgpBCgQEAwID
EgNxAhUaNCBHQ1AgUHJvamVjdC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0X251bWJl
cn1gLgoKDAoFBAMCAwUSA3ECCAoMCgUEAwIDARIDcQkQCgwKBQQDAgMDEgNxExQKcwoEBAMC
BBIDdQIWGmYgVW5pcXVlIGlkZW50aWZpZXIgZm9yIGNsaWVudHMgdG8gdHJhY2UgdGhlaXIg
cmVxdWVzdC9yZXNwb25zZS4gTWF0Y2hlcyB0aGUKIEVncmVzc1JlcXVlc3QncyB0cmFjZSBp
ZAoKDAoFBAMCBAUSA3UCCAoMCgUEAwIEARIDdQkRCgwKBQQDAgQDEgN1FBUKHwoEBAMCBRID
eAIeGhIgVGV0aGVyIEVuZHBvaW50LgoKDAoFBAMCBQYSA3gCEAoMCgUEAwIFARIDeBEZCgwK
BQQDAgUDEgN4HB0KggEKBAQDAgYSA3wCEhp1IE5hbWUgaXMgdGhlIGZ1bGwgcmVzb3VyY2Ug
cGF0aCBvZiBlbmRwb2ludC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0X251bWJlciBv
ciBwcm9qZWN0X2lkfS9lbmRwb2ludHMve2VuZHBvaW50fWAKCgwKBQQDAgYFEgN8AggKDAoF
BAMCBgESA3wJDQoMCgUEAwIGAxIDfBARCkgKAgUBEgaAAQCMAQEaOiBFbmRwb2ludCBpbmRp
Y2F0ZXMgd2hlcmUgdGhlIG1lc3NhZ2VzIHdpbGwgYmUgZGVsaXZlcmVkLgoKCwoDBQEBEgSA
AQUTCiwKBAUBAgASBIIBAiIaHiBVbnNwZWNpZmllZCB0ZXRoZXIgZW5kcG9pbnQuCgoNCgUF
AQIAARIEggECHQoNCgUFAQIAAhIEggEgIQolCgQFAQIBEgSFAQISGhcgQXBpZ2VlIE1BUlQg
ZW5kcG9pbnQuCgoNCgUFAQIBARIEhQECDQoNCgUFAQIBAhIEhQEQEQooCgQFAQICEgSIAQIV
GhogQXBpZ2VlIFJ1bnRpbWUgZW5kcG9pbnQuCgoNCgUFAQICARIEiAECEAoNCgUFAQICAhIE
iAETFAosCgQFAQIDEgSLAQIZGh4gQXBpZ2VlIE1pbnQgUmF0aW5nIGVuZHBvaW50LgoKDQoF
BQECAwESBIsBAhQKDQoFBQECAwISBIsBFxgKHAoCBQISBo8BAJUBARoOIEhUVFAgU2NoZW1l
LgoKCwoDBQIBEgSPAQULCiMKBAUCAgASBJEBAhkaFSBVbnNwZWNpZmllZCBzY2hlbWUuCgoN
CgUFAgIAARIEkQECFAoNCgUFAgIAAhIEkQEXGAofCgQFAgIBEgSUAQIMGhEgSFRUUFMgcHJv
dG9jb2wuCgoNCgUFAgIBARIElAECBwoNCgUFAgIBAhIElAEKCwo1CgIEBBIGmAEAqAEBGicg
VGhlIHByb3RvIGRlZmluaXRpb24gb2YgaHR0cCByZXF1ZXN0LgoKCwoDBAQBEgSYAQgTCjQK
BAQEAgASBJoBAhAaJiBBIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUgcmVxdWVzdC4KCg0K
BQQEAgAFEgSaAQIICg0KBQQEAgABEgSaAQkLCg0KBQQEAgADEgSaAQ4PCmgKBAQEAgESBJ4B
AhQaWiBUaGUgSFRUUCByZXF1ZXN0IG1ldGhvZC4KIFZhbGlkIG1ldGhvZHM6ICJHRVQiLCAi
SEVBRCIsICJQT1NUIiwgIlBVVCIsICJQQVRDSCIsIkRFTEVURSIuCgoNCgUEBAIBBRIEngEC
CAoNCgUEBAIBARIEngEJDwoNCgUEBAIBAxIEngESEwolCgQEBAICEgShAQIOGhcgVGhlIEhU
VFAgcmVxdWVzdCBVUkwuCgoNCgUEBAICBhIEoQECBQoNCgUEBAICARIEoQEGCQoNCgUEBAIC
AxIEoQEMDQopCgQEBAIDEgSkAQIeGhsgVGhlIEhUVFAgcmVxdWVzdCBoZWFkZXJzLgoKDQoF
BAQCAwQSBKQBAgoKDQoFBAQCAwYSBKQBCxEKDQoFBAQCAwESBKQBEhkKDQoFBAQCAwMSBKQB
HB0KIgoEBAQCBBIEpwECERoUIEhUVFAgcmVxdWVzdCBib2R5LgoKDQoFBAQCBAUSBKcBAgcK
DQoFBAQCBAESBKcBCAwKDQoFBAQCBAMSBKcBDxAKqQEKAgQFEgauAQC3AQEamgEgVGhlIHBy
b3RvIGRlZmluaXRpb24gb2YgdXJsLgogQSB1cmwgcmVwcmVzZW50cyBhIFVSTCBhbmQgdGhl
IGdlbmVyYWwgZm9ybSByZXByZXNlbnRlZCBpczoKCiAgYFtzY2hlbWU6Ly9dW2dvb2dsZS5j
bG91ZC5hcGlnZWVjb25uZWN0LnYxLlVybC5ob3N0XVtwYXRoXWAKCgsKAwQFARIErgEICwoX
CgQEBQIAEgSwAQIUGgkgU2NoZW1lLgoKDQoFBAUCAAYSBLABAggKDQoFBAUCAAESBLABCQ8K
DQoFBAUCAAMSBLABEhMKIgoEBAUCARIEswECEhoUIEhvc3Qgb3IgSG9zdDpQb3J0LgoKDQoF
BAUCAQUSBLMBAggKDQoFBAUCAQESBLMBCQ0KDQoFBAUCAQMSBLMBEBEKJQoEBAUCAhIEtgEC
EhoXIFBhdGggc3RhcnRzIHdpdGggYC9gLgoKDQoFBAUCAgUSBLYBAggKDQoFBAUCAgESBLYB
CQ0KDQoFBAUCAgMSBLYBEBEKIQoCBAYSBroBAL4BARoTIFRoZSBodHRwIGhlYWRlcnMuCgoL
CgMEBgESBLoBCA4KDAoEBAYCABIEuwECEQoNCgUEBgIABRIEuwECCAoNCgUEBgIAARIEuwEJ
DAoNCgUEBgIAAxIEuwEPEAoMCgQEBgIBEgS9AQIdCg0KBQQGAgEEEgS9AQIKCg0KBQQGAgEF
EgS9AQsRCg0KBQQGAgEBEgS9ARIYCg0KBQQGAgEDEgS9ARscCjYKAgQHEgbBAQDWAQEaKCBU
aGUgcHJvdG8gZGVmaW5pdGlvbiBvZiBodHRwIHJlc3BvbnNlLgoKCwoDBAcBEgTBAQgUCkAK
BAQHAgASBMMBAhAaMiBBIHVuaXF1ZSBpZGVudGlmaWVyIHRoYXQgbWF0Y2hlcyB0aGUgcmVx
dWVzdCBJRC4KCg0KBQQHAgAFEgTDAQIICg0KBQQHAgABEgTDAQkLCg0KBQQHAgADEgTDAQ4P
CjcKBAQHAgESBMYBAhQaKSBTdGF0dXMgb2YgaHR0cCByZXNwb25zZSwgZS5nLiAiMjAwIE9L
Ii4KCg0KBQQHAgEFEgTGAQIICg0KBQQHAgEBEgTGAQkPCg0KBQQHAgEDEgTGARITCjcKBAQH
AgISBMkBAhgaKSBTdGF0dXMgY29kZSBvZiBodHRwIHJlc3BvbnNlLCBlLmcuIDIwMC4KCg0K
BQQHAgIFEgTJAQIHCg0KBQQHAgIBEgTJAQgTCg0KBQQHAgIDEgTJARYXCisKBAQHAgMSBMwB
AhEaHSBUaGUgSFRUUCAxLjEgcmVzcG9uc2UgYm9keS4KCg0KBQQHAgMFEgTMAQIHCg0KBQQH
AgMBEgTMAQgMCg0KBQQHAgMDEgTMAQ8QCioKBAQHAgQSBM8BAh4aHCBUaGUgSFRUUCByZXNw
b25zZSBoZWFkZXJzLgoKDQoFBAcCBAQSBM8BAgoKDQoFBAcCBAYSBM8BCxEKDQoFBAcCBAES
BM8BEhkKDQoFBAcCBAMSBM8BHB0K7AEKBAQHAgUSBNUBAhsa3QEgQ29udGVudCBsZW5ndGgg
cmVjb3JkcyB0aGUgbGVuZ3RoIG9mIHRoZSBhc3NvY2lhdGVkIGNvbnRlbnQuIFRoZQogdmFs
dWUgLTEgaW5kaWNhdGVzIHRoYXQgdGhlIGxlbmd0aCBpcyB1bmtub3duLiBVbmxlc3MgaHR0
cCBtZXRob2QKIGlzICJIRUFEIiwgdmFsdWVzID49IDAgaW5kaWNhdGUgdGhhdCB0aGUgZ2l2
ZW4gbnVtYmVyIG9mIGJ5dGVzIG1heQogYmUgcmVhZCBmcm9tIEJvZHkuCgoNCgUEBwIFBRIE
1QECBwoNCgUEBwIFARIE1QEIFgoNCgUEBwIFAxIE1QEZGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest ===
    # Fields for EgressRequest
    # Field: id Type: 9 ()
    # Field: payload Type: 11 (.google.cloud.apigeeconnect.v1.Payload)
    # Field: endpoint Type: 14 (.google.cloud.apigeeconnect.v1.TetherEndpoint)
    # Field: project Type: 9 ()
    # Field: trace_id Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::Payload ===
    # Fields for Payload
    # Field: http_request Type: 11 (.google.cloud.apigeeconnect.v1.HttpRequest)
    # Field: stream_info Type: 11 (.google.cloud.apigeeconnect.v1.StreamInfo)
    # Field: action Type: 14 (.google.cloud.apigeeconnect.v1.Action)

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::StreamInfo ===
    # Fields for StreamInfo
    # Field: id Type: 9 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::EgressResponse ===
    # Fields for EgressResponse
    # Field: id Type: 9 ()
    # Field: http_response Type: 11 (.google.cloud.apigeeconnect.v1.HttpResponse)
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: project Type: 9 ()
    # Field: trace_id Type: 9 ()
    # Field: endpoint Type: 14 (.google.cloud.apigeeconnect.v1.TetherEndpoint)
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::HttpRequest ===
    # Fields for HttpRequest
    # Field: id Type: 9 ()
    # Field: method Type: 9 ()
    # Field: url Type: 11 (.google.cloud.apigeeconnect.v1.Url)
    # Field: headers Type: 11 (.google.cloud.apigeeconnect.v1.Header)
    # Field: body Type: 12 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::Url ===
    # Fields for Url
    # Field: scheme Type: 14 (.google.cloud.apigeeconnect.v1.Scheme)
    # Field: host Type: 9 ()
    # Field: path Type: 9 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::Header ===
    # Fields for Header
    # Field: key Type: 9 ()
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Tether::HttpResponse ===
    # Fields for HttpResponse
    # Field: id Type: 9 ()
    # Field: status Type: 9 ()
    # Field: status_code Type: 5 ()
    # Field: body Type: 12 ()
    # Field: headers Type: 11 (.google.cloud.apigeeconnect.v1.Header)
    # Field: content_length Type: 3 ()

# === Service Client: Google::Cloud::Apigeeconnect::V1::Tether::TetherClient ===
package Google::Cloud::Apigeeconnect::V1::Tether::TetherClient;

=pod

=head2 Service Client: Google::Cloud::Apigeeconnect::V1::Tether::TetherClient

Client stub representing the remote C<Tether> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apigeeconnect.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apigeeconnect.googleapis.com:443' );

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

sub egress {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigeeconnect::V1::Tether::EgressResponse->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigeeconnect.v1.Tether',
        method         => 'Egress',
        request        => $req,
        response_class => 'Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apigeeconnect::V1::Tether - Compiled Protocol Buffers messages for google/cloud/apigeeconnect/v1/tether.proto

=head1 SYNOPSIS

    use Google::Cloud::Apigeeconnect::V1::Tether;

    my $msg = Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest->new({
        id => $id,
        payload => $payload,
        endpoint => $endpoint,
        project => $project,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apigeeconnect/v1/tether.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest

gRPC request payload for tether.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Unique identifier for the request.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::Payload>)

Actual payload to send to agent.

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<Enum> (L<Google::Cloud::Apigeeconnect::V1::TetherEndpoint>)

Tether Endpoint.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

GCP Project.
Format: `projects/{project_number}`.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Unique identifier for clients to trace their request/response.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Timeout for the HTTP request.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::Payload

Payload for EgressRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->http_request() >> / C<< $msg->http_request($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::HttpRequest>)

The HttpRequest proto.

=item * C<< $msg->stream_info() >> / C<< $msg->stream_info($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::StreamInfo>)

The information of stream.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Cloud::Apigeeconnect::V1::Action>)

The action taken by agent.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::StreamInfo

The Information of bi-directional stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Unique identifier for the stream.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::EgressResponse

gRPC response payload for tether.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Unique identifier for the response. Matches the EgressRequest's id.

=item * C<< $msg->http_response() >> / C<< $msg->http_response($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::HttpResponse>)

HttpResponse.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Errors from application when handling the http request.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

GCP Project.
Format: `projects/{project_number}`.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Unique identifier for clients to trace their request/response. Matches the
EgressRequest's trace id

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<Enum> (L<Google::Cloud::Apigeeconnect::V1::TetherEndpoint>)

Tether Endpoint.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name is the full resource path of endpoint.
Format: `projects/{project_number or project_id}/endpoints/{endpoint}`

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::HttpRequest

The proto definition of http request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

A unique identifier for the request.

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<String>

The HTTP request method.
Valid methods: "GET", "HEAD", "POST", "PUT", "PATCH","DELETE".

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::Url>)

The HTTP request URL.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::Header>)

The HTTP request headers.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Bytes>

HTTP request body.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::Url

The proto definition of url.
A url represents a URL and the general form represented is:

 `[scheme://][google.cloud.apigeeconnect.v1.Url.host][path]`

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scheme() >> / C<< $msg->scheme($value) >>

Type: C<Enum> (L<Google::Cloud::Apigeeconnect::V1::Scheme>)

Scheme.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host or Host:Port.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Path starts with `/`.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::Header

The http headers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

=back

=head2 Google::Cloud::Apigeeconnect::V1::Tether::HttpResponse

The proto definition of http response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

A unique identifier that matches the request ID.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<String>

Status of http response, e.g. "200 OK".

=item * C<< $msg->status_code() >> / C<< $msg->status_code($value) >>

Type: C<Int32>

Status code of http response, e.g. 200.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Bytes>

The HTTP 1.1 response body.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Tether::Header>)

The HTTP response headers.

=item * C<< $msg->content_length() >> / C<< $msg->content_length($value) >>

Type: C<Int64>

Content length records the length of the associated content. The
value -1 indicates that the length is unknown. Unless http method
is "HEAD", values >= 0 indicate that the given number of bytes may
be read from Body.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apigeeconnect::V1::Tether::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
