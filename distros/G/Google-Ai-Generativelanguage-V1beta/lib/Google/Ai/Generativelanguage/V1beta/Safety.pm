package Google::Ai::Generativelanguage::V1beta::Safety;

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
CjBnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9zYWZldHkucHJvdG8SI2dv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvItwBCg1Db250ZW50RmlsdGVyElgKBnJlYXNvbhgBIAEoDjJALmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkNvbnRlbnRGaWx0ZXIuQmxvY2tlZFJl
YXNvblIGcmVhc29uEh0KB21lc3NhZ2UYAiABKAlIAFIHbWVzc2FnZYgBASJGCg1CbG9ja2Vk
UmVhc29uEh4KGkJMT0NLRURfUkVBU09OX1VOU1BFQ0lGSUVEEAASCgoGU0FGRVRZEAESCQoF
T1RIRVIQAkIKCghfbWVzc2FnZSKpAQoOU2FmZXR5RmVlZGJhY2sSSQoGcmF0aW5nGAEgASgL
MjEuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuU2FmZXR5UmF0aW5nUgZy
YXRpbmcSTAoHc2V0dGluZxgCIAEoCzIyLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFiZXRhLlNhZmV0eVNldHRpbmdSB3NldHRpbmciygIKDFNhZmV0eVJhdGluZxJSCghjYXRl
Z29yeRgDIAEoDjIxLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkhhcm1D
YXRlZ29yeUID4EECUghjYXRlZ29yeRJoCgtwcm9iYWJpbGl0eRgEIAEoDjJBLmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlNhZmV0eVJhdGluZy5IYXJtUHJvYmFiaWxp
dHlCA+BBAlILcHJvYmFiaWxpdHkSGAoHYmxvY2tlZBgFIAEoCFIHYmxvY2tlZCJiCg9IYXJt
UHJvYmFiaWxpdHkSIAocSEFSTV9QUk9CQUJJTElUWV9VTlNQRUNJRklFRBAAEg4KCk5FR0xJ
R0lCTEUQARIHCgNMT1cQAhIKCgZNRURJVU0QAxIICgRISUdIEAQi7QIKDVNhZmV0eVNldHRp
bmcSUgoIY2F0ZWdvcnkYAyABKA4yMS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YmV0YS5IYXJtQ2F0ZWdvcnlCA+BBAlIIY2F0ZWdvcnkSaAoJdGhyZXNob2xkGAQgASgOMkUu
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuU2FmZXR5U2V0dGluZy5IYXJt
QmxvY2tUaHJlc2hvbGRCA+BBAlIJdGhyZXNob2xkIp0BChJIYXJtQmxvY2tUaHJlc2hvbGQS
JAogSEFSTV9CTE9DS19USFJFU0hPTERfVU5TUEVDSUZJRUQQABIXChNCTE9DS19MT1dfQU5E
X0FCT1ZFEAESGgoWQkxPQ0tfTUVESVVNX0FORF9BQk9WRRACEhMKD0JMT0NLX09OTFlfSElH
SBADEg4KCkJMT0NLX05PTkUQBBIHCgNPRkYQBSqDAwoMSGFybUNhdGVnb3J5Eh0KGUhBUk1f
Q0FURUdPUllfVU5TUEVDSUZJRUQQABIcChhIQVJNX0NBVEVHT1JZX0RFUk9HQVRPUlkQARIa
ChZIQVJNX0NBVEVHT1JZX1RPWElDSVRZEAISGgoWSEFSTV9DQVRFR09SWV9WSU9MRU5DRRAD
EhgKFEhBUk1fQ0FURUdPUllfU0VYVUFMEAQSGQoVSEFSTV9DQVRFR09SWV9NRURJQ0FMEAUS
GwoXSEFSTV9DQVRFR09SWV9EQU5HRVJPVVMQBhIcChhIQVJNX0NBVEVHT1JZX0hBUkFTU01F
TlQQBxIdChlIQVJNX0NBVEVHT1JZX0hBVEVfU1BFRUNIEAgSIwofSEFSTV9DQVRFR09SWV9T
RVhVQUxMWV9FWFBMSUNJVBAJEiMKH0hBUk1fQ0FURUdPUllfREFOR0VST1VTX0NPTlRFTlQQ
ChIlCh1IQVJNX0NBVEVHT1JZX0NJVklDX0lOVEVHUklUWRALGgIIAUKXAQonY29tLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhQgtTYWZldHlQcm90b1ABWl1jbG91ZC5n
b29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWJldGEvZ2VuZXJhdGl2
ZWxhbmd1YWdlcGI7Z2VuZXJhdGl2ZWxhbmd1YWdlcGJKwC8KBxIFDgC0AQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoICgEIEgMU
AHQKCQoCCAsSAxQAdAoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWACwKCQoCCAgSAxYA
LAoICgEIEgMXAEAKCQoCCAESAxcAQAp8CgIFABIEHQBFARpwIFRoZSBjYXRlZ29yeSBvZiBh
IHJhdGluZy4KCiBUaGVzZSBjYXRlZ29yaWVzIGNvdmVyIHZhcmlvdXMga2luZHMgb2YgaGFy
bXMgdGhhdCBkZXZlbG9wZXJzCiBtYXkgd2lzaCB0byBhZGp1c3QuCgoKCgMFAAESAx0FEQon
CgQFAAIAEgMfAiAaGiBDYXRlZ29yeSBpcyB1bnNwZWNpZmllZC4KCgwKBQUAAgABEgMfAhsK
DAoFBQACAAISAx8eHwpmCgQFAAIBEgMjAh8aWSAqKlBhTE0qKiAtIE5lZ2F0aXZlIG9yIGhh
cm1mdWwgY29tbWVudHMgdGFyZ2V0aW5nIGlkZW50aXR5IGFuZC9vciBwcm90ZWN0ZWQKIGF0
dHJpYnV0ZS4KCgwKBQUAAgEBEgMjAhoKDAoFBQACAQISAyMdHgpKCgQFAAICEgMmAh0aPSAq
KlBhTE0qKiAtIENvbnRlbnQgdGhhdCBpcyBydWRlLCBkaXNyZXNwZWN0ZnVsLCBvciBwcm9m
YW5lLgoKDAoFBQACAgESAyYCGAoMCgUFAAICAhIDJhscCoIBCgQFAAIDEgMqAh0adSAqKlBh
TE0qKiAtIERlc2NyaWJlcyBzY2VuYXJpb3MgZGVwaWN0aW5nIHZpb2xlbmNlIGFnYWluc3Qg
YW4gaW5kaXZpZHVhbCBvcgogZ3JvdXAsIG9yIGdlbmVyYWwgZGVzY3JpcHRpb25zIG9mIGdv
cmUuCgoMCgUFAAIDARIDKgIYCgwKBQUAAgMCEgMqGxwKUwoEBQACBBIDLQIbGkYgKipQYUxN
KiogLSBDb250YWlucyByZWZlcmVuY2VzIHRvIHNleHVhbCBhY3RzIG9yIG90aGVyIGxld2Qg
Y29udGVudC4KCgwKBQUAAgQBEgMtAhYKDAoFBQACBAISAy0ZGgo8CgQFAAIFEgMwAhwaLyAq
KlBhTE0qKiAtIFByb21vdGVzIHVuY2hlY2tlZCBtZWRpY2FsIGFkdmljZS4KCgwKBQUAAgUB
EgMwAhcKDAoFBQACBQISAzAaGwpkCgQFAAIGEgM0Ah4aVyAqKlBhTE0qKiAtIERhbmdlcm91
cyBjb250ZW50IHRoYXQgcHJvbW90ZXMsIGZhY2lsaXRhdGVzLCBvciBlbmNvdXJhZ2VzCiBo
YXJtZnVsIGFjdHMuCgoMCgUFAAIGARIDNAIZCgwKBQUAAgYCEgM0HB0KLwoEBQACBxIDNwIf
GiIgKipHZW1pbmkqKiAtIEhhcmFzc21lbnQgY29udGVudC4KCgwKBQUAAgcBEgM3AhoKDAoF
BQACBwISAzcdHgo0CgQFAAIIEgM6AiAaJyAqKkdlbWluaSoqIC0gSGF0ZSBzcGVlY2ggYW5k
IGNvbnRlbnQuCgoMCgUFAAIIARIDOgIbCgwKBQUAAggCEgM6Hh8KNgoEBQACCRIDPQImGikg
KipHZW1pbmkqKiAtIFNleHVhbGx5IGV4cGxpY2l0IGNvbnRlbnQuCgoMCgUFAAIJARIDPQIh
CgwKBQUAAgkCEgM9JCUKLgoEBQACChIDQAInGiEgKipHZW1pbmkqKiAtIERhbmdlcm91cyBj
b250ZW50LgoKDAoFBQACCgESA0ACIQoMCgUFAAIKAhIDQCQmCoUBCgQFAAILEgNEAjkaeCAq
KkdlbWluaSoqIC0gQ29udGVudCB0aGF0IG1heSBiZSB1c2VkIHRvIGhhcm0gY2l2aWMgaW50
ZWdyaXR5LgogREVQUkVDQVRFRDogdXNlIGVuYWJsZV9lbmhhbmNlZF9jaXZpY19hbnN3ZXJz
IGluc3RlYWQuCgoMCgUFAAILARIDRAIfCgwKBQUAAgsCEgNEIiQKDAoFBQACCwMSA0QlOAoN
CgYFAAILAwESA0QmNwq7AQoCBAASBEsAXQEargEgQ29udGVudCBmaWx0ZXJpbmcgbWV0YWRh
dGEgYXNzb2NpYXRlZCB3aXRoIHByb2Nlc3NpbmcgYSBzaW5nbGUgcmVxdWVzdC4KCiBDb250
ZW50RmlsdGVyIGNvbnRhaW5zIGEgcmVhc29uIGFuZCBhbiBvcHRpb25hbCBzdXBwb3J0aW5n
IHN0cmluZy4gVGhlIHJlYXNvbgogbWF5IGJlIHVuc3BlY2lmaWVkLgoKCgoDBAABEgNLCBUK
RAoEBAAEABIETQJWAxo2IEEgbGlzdCBvZiByZWFzb25zIHdoeSBjb250ZW50IG1heSBoYXZl
IGJlZW4gYmxvY2tlZC4KCgwKBQQABAABEgNNBxQKNAoGBAAEAAIAEgNPBCMaJSBBIGJsb2Nr
ZWQgcmVhc29uIHdhcyBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDTwQeCg4KBwQABAAC
AAISA08hIgo4CgYEAAQAAgESA1IEDxopIENvbnRlbnQgd2FzIGJsb2NrZWQgYnkgc2FmZXR5
IHNldHRpbmdzLgoKDgoHBAAEAAIBARIDUgQKCg4KBwQABAACAQISA1INDgpGCgYEAAQAAgIS
A1UEDho3IENvbnRlbnQgd2FzIGJsb2NrZWQsIGJ1dCB0aGUgcmVhc29uIGlzIHVuY2F0ZWdv
cml6ZWQuCgoOCgcEAAQAAgIBEgNVBAkKDgoHBAAEAAICAhIDVQwNCkgKBAQAAgASA1kCGxo7
IFRoZSByZWFzb24gY29udGVudCB3YXMgYmxvY2tlZCBkdXJpbmcgcmVxdWVzdCBwcm9jZXNz
aW5nLgoKDAoFBAACAAYSA1kCDwoMCgUEAAIAARIDWRAWCgwKBQQAAgADEgNZGRoKTQoEBAAC
ARIDXAIeGkAgQSBzdHJpbmcgdGhhdCBkZXNjcmliZXMgdGhlIGZpbHRlcmluZyBiZWhhdmlv
ciBpbiBtb3JlIGRldGFpbC4KCgwKBQQAAgEEEgNcAgoKDAoFBAACAQUSA1wLEQoMCgUEAAIB
ARIDXBIZCgwKBQQAAgEDEgNcHB0K9QIKAgQBEgRmAGwBGugCIFNhZmV0eSBmZWVkYmFjayBm
b3IgYW4gZW50aXJlIHJlcXVlc3QuCgogVGhpcyBmaWVsZCBpcyBwb3B1bGF0ZWQgaWYgY29u
dGVudCBpbiB0aGUgaW5wdXQgYW5kL29yIHJlc3BvbnNlIGlzIGJsb2NrZWQKIGR1ZSB0byBz
YWZldHkgc2V0dGluZ3MuIFNhZmV0eUZlZWRiYWNrIG1heSBub3QgZXhpc3QgZm9yIGV2ZXJ5
IEhhcm1DYXRlZ29yeS4KIEVhY2ggU2FmZXR5RmVlZGJhY2sgd2lsbCByZXR1cm4gdGhlIHNh
ZmV0eSBzZXR0aW5ncyB1c2VkIGJ5IHRoZSByZXF1ZXN0IGFzCiB3ZWxsIGFzIHRoZSBsb3dl
c3QgSGFybVByb2JhYmlsaXR5IHRoYXQgc2hvdWxkIGJlIGFsbG93ZWQgaW4gb3JkZXIgdG8g
cmV0dXJuCiBhIHJlc3VsdC4KCgoKAwQBARIDZggWCjQKBAQBAgASA2gCGhonIFNhZmV0eSBy
YXRpbmcgZXZhbHVhdGVkIGZyb20gY29udGVudC4KCgwKBQQBAgAGEgNoAg4KDAoFBAECAAES
A2gPFQoMCgUEAQIAAxIDaBgZCjYKBAQBAgESA2sCHBopIFNhZmV0eSBzZXR0aW5ncyBhcHBs
aWVkIHRvIHRoZSByZXF1ZXN0LgoKDAoFBAECAQYSA2sCDwoMCgUEAQIBARIDaxAXCgwKBQQB
AgEDEgNrGhsKuAIKAgQCEgV1AJMBARqqAiBTYWZldHkgcmF0aW5nIGZvciBhIHBpZWNlIG9m
IGNvbnRlbnQuCgogVGhlIHNhZmV0eSByYXRpbmcgY29udGFpbnMgdGhlIGNhdGVnb3J5IG9m
IGhhcm0gYW5kIHRoZQogaGFybSBwcm9iYWJpbGl0eSBsZXZlbCBpbiB0aGF0IGNhdGVnb3J5
IGZvciBhIHBpZWNlIG9mIGNvbnRlbnQuCiBDb250ZW50IGlzIGNsYXNzaWZpZWQgZm9yIHNh
ZmV0eSBhY3Jvc3MgYSBudW1iZXIgb2YKIGhhcm0gY2F0ZWdvcmllcyBhbmQgdGhlIHByb2Jh
YmlsaXR5IG9mIHRoZSBoYXJtIGNsYXNzaWZpY2F0aW9uIGlzIGluY2x1ZGVkCiBoZXJlLgoK
CgoDBAIBEgN1CBQK2QEKBAQCBAASBXoCiQEDGskBIFRoZSBwcm9iYWJpbGl0eSB0aGF0IGEg
cGllY2Ugb2YgY29udGVudCBpcyBoYXJtZnVsLgoKIFRoZSBjbGFzc2lmaWNhdGlvbiBzeXN0
ZW0gZ2l2ZXMgdGhlIHByb2JhYmlsaXR5IG9mIHRoZSBjb250ZW50IGJlaW5nCiB1bnNhZmUu
IFRoaXMgZG9lcyBub3QgaW5kaWNhdGUgdGhlIHNldmVyaXR5IG9mIGhhcm0gZm9yIGEgcGll
Y2Ugb2YgY29udGVudC4KCgwKBQQCBAABEgN6BxYKLAoGBAIEAAIAEgN8BCUaHSBQcm9iYWJp
bGl0eSBpcyB1bnNwZWNpZmllZC4KCg4KBwQCBAACAAESA3wEIAoOCgcEAgQAAgACEgN8IyQK
QQoGBAIEAAIBEgN/BBMaMiBDb250ZW50IGhhcyBhIG5lZ2xpZ2libGUgY2hhbmNlIG9mIGJl
aW5nIHVuc2FmZS4KCg4KBwQCBAACAQESA38EDgoOCgcEAgQAAgECEgN/ERIKOwoGBAIEAAIC
EgSCAQQMGisgQ29udGVudCBoYXMgYSBsb3cgY2hhbmNlIG9mIGJlaW5nIHVuc2FmZS4KCg8K
BwQCBAACAgESBIIBBAcKDwoHBAIEAAICAhIEggEKCwo+CgYEAgQAAgMSBIUBBA8aLiBDb250
ZW50IGhhcyBhIG1lZGl1bSBjaGFuY2Ugb2YgYmVpbmcgdW5zYWZlLgoKDwoHBAIEAAIDARIE
hQEECgoPCgcEAgQAAgMCEgSFAQ0OCjwKBgQCBAACBBIEiAEEDRosIENvbnRlbnQgaGFzIGEg
aGlnaCBjaGFuY2Ugb2YgYmVpbmcgdW5zYWZlLgoKDwoHBAIEAAIEARIEiAEECAoPCgcEAgQA
AgQCEgSIAQsMCjcKBAQCAgASBIwBAkUaKSBSZXF1aXJlZC4gVGhlIGNhdGVnb3J5IGZvciB0
aGlzIHJhdGluZy4KCg0KBQQCAgAGEgSMAQIOCg0KBQQCAgABEgSMAQ8XCg0KBQQCAgADEgSM
ARobCg0KBQQCAgAIEgSMARxEChAKCAQCAgAInAgAEgSMAR1DCkMKBAQCAgESBI8BAksaNSBS
ZXF1aXJlZC4gVGhlIHByb2JhYmlsaXR5IG9mIGhhcm0gZm9yIHRoaXMgY29udGVudC4KCg0K
BQQCAgEGEgSPAQIRCg0KBQQCAgEBEgSPARIdCg0KBQQCAgEDEgSPASAhCg0KBQQCAgEIEgSP
ASJKChAKCAQCAgEInAgAEgSPASNJCkAKBAQCAgISBJIBAhMaMiBXYXMgdGhpcyBjb250ZW50
IGJsb2NrZWQgYmVjYXVzZSBvZiB0aGlzIHJhdGluZz8KCg0KBQQCAgIFEgSSAQIGCg0KBQQC
AgIBEgSSAQcOCg0KBQQCAgIDEgSSARESCqwBCgIEAxIGmQEAtAEBGp0BIFNhZmV0eSBzZXR0
aW5nLCBhZmZlY3RpbmcgdGhlIHNhZmV0eS1ibG9ja2luZyBiZWhhdmlvci4KCiBQYXNzaW5n
IGEgc2FmZXR5IHNldHRpbmcgZm9yIGEgY2F0ZWdvcnkgY2hhbmdlcyB0aGUgYWxsb3dlZCBw
cm9iYWJpbGl0eSB0aGF0CiBjb250ZW50IGlzIGJsb2NrZWQuCgoLCgMEAwESBJkBCBUKQwoE
BAMEABIGmwECrQEDGjMgQmxvY2sgYXQgYW5kIGJleW9uZCBhIHNwZWNpZmllZCBoYXJtIHBy
b2JhYmlsaXR5LgoKDQoFBAMEAAESBJsBBxkKKwoGBAMEAAIAEgSdAQQpGhsgVGhyZXNob2xk
IGlzIHVuc3BlY2lmaWVkLgoKDwoHBAMEAAIAARIEnQEEJAoPCgcEAwQAAgACEgSdAScoCjoK
BgQDBAACARIEoAEEHBoqIENvbnRlbnQgd2l0aCBORUdMSUdJQkxFIHdpbGwgYmUgYWxsb3dl
ZC4KCg8KBwQDBAACAQESBKABBBcKDwoHBAMEAAIBAhIEoAEaGwpCCgYEAwQAAgISBKMBBB8a
MiBDb250ZW50IHdpdGggTkVHTElHSUJMRSBhbmQgTE9XIHdpbGwgYmUgYWxsb3dlZC4KCg8K
BwQDBAACAgESBKMBBBoKDwoHBAMEAAICAhIEowEdHgpLCgYEAwQAAgMSBKYBBBgaOyBDb250
ZW50IHdpdGggTkVHTElHSUJMRSwgTE9XLCBhbmQgTUVESVVNIHdpbGwgYmUgYWxsb3dlZC4K
Cg8KBwQDBAACAwESBKYBBBMKDwoHBAMEAAIDAhIEpgEWFwouCgYEAwQAAgQSBKkBBBMaHiBB
bGwgY29udGVudCB3aWxsIGJlIGFsbG93ZWQuCgoPCgcEAwQAAgQBEgSpAQQOCg8KBwQDBAAC
BAISBKkBERIKLQoGBAMEAAIFEgSsAQQMGh0gVHVybiBvZmYgdGhlIHNhZmV0eSBmaWx0ZXIu
CgoPCgcEAwQAAgUBEgSsAQQHCg8KBwQDBAACBQISBKwBCgsKOAoEBAMCABIEsAECRRoqIFJl
cXVpcmVkLiBUaGUgY2F0ZWdvcnkgZm9yIHRoaXMgc2V0dGluZy4KCg0KBQQDAgAGEgSwAQIO
Cg0KBQQDAgABEgSwAQ8XCg0KBQQDAgADEgSwARobCg0KBQQDAgAIEgSwARxEChAKCAQDAgAI
nAgAEgSwAR1DClYKBAQDAgESBLMBAkwaSCBSZXF1aXJlZC4gQ29udHJvbHMgdGhlIHByb2Jh
YmlsaXR5IHRocmVzaG9sZCBhdCB3aGljaCBoYXJtIGlzIGJsb2NrZWQuCgoNCgUEAwIBBhIE
swECFAoNCgUEAwIBARIEswEVHgoNCgUEAwIBAxIEswEhIgoNCgUEAwIBCBIEswEjSwoQCggE
AwIBCJwIABIEswEkSmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::Safety::ContentFilter ===
    # Fields for ContentFilter
    # Field: reason Type: 14 (.google.ai.generativelanguage.v1beta.ContentFilter.BlockedReason)
    # Field: message Type: 9 ()

# Enum: ContentFilter::BlockedReason
our $ContentFilter_BLOCKED_REASON_UNSPECIFIED = 0;
our $ContentFilter_SAFETY = 1;
our $ContentFilter_OTHER = 2;

# === Message: Google::Ai::Generativelanguage::V1beta::Safety::SafetyFeedback ===
    # Fields for SafetyFeedback
    # Field: rating Type: 11 (.google.ai.generativelanguage.v1beta.SafetyRating)
    # Field: setting Type: 11 (.google.ai.generativelanguage.v1beta.SafetySetting)

# === Message: Google::Ai::Generativelanguage::V1beta::Safety::SafetyRating ===
    # Fields for SafetyRating
    # Field: category Type: 14 (.google.ai.generativelanguage.v1beta.HarmCategory)
    # Field: probability Type: 14 (.google.ai.generativelanguage.v1beta.SafetyRating.HarmProbability)
    # Field: blocked Type: 8 ()

# Enum: SafetyRating::HarmProbability
our $SafetyRating_HARM_PROBABILITY_UNSPECIFIED = 0;
our $SafetyRating_NEGLIGIBLE = 1;
our $SafetyRating_LOW = 2;
our $SafetyRating_MEDIUM = 3;
our $SafetyRating_HIGH = 4;

# === Message: Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting ===
    # Fields for SafetySetting
    # Field: category Type: 14 (.google.ai.generativelanguage.v1beta.HarmCategory)
    # Field: threshold Type: 14 (.google.ai.generativelanguage.v1beta.SafetySetting.HarmBlockThreshold)

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

Google::Ai::Generativelanguage::V1beta::Safety - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/safety.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::Safety;

    my $msg = Google::Ai::Generativelanguage::V1beta::Safety::ContentFilter->new({
        reason => $reason,
        message => $message,
    });

    # Read or update a field
    my $val = $msg->reason();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::Safety::ContentFilter->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::Safety::ContentFilter

Content filtering metadata associated with processing a single request.

ContentFilter contains a reason and an optional supporting string. The reason
may be unspecified.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::ContentFilter::BlockedReason>)

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

=head2 Google::Ai::Generativelanguage::V1beta::Safety::SafetyFeedback

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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Safety::SafetyRating>)

Safety rating evaluated from content.

=item * C<< $msg->setting() >> / C<< $msg->setting($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting>)

Safety settings applied to the request.

=back

=head2 Google::Ai::Generativelanguage::V1beta::Safety::SafetyRating

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

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::HarmCategory>)

Required. The category for this rating.

=item * C<< $msg->probability() >> / C<< $msg->probability($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::SafetyRating::HarmProbability>)

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

=head2 Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting

Safety setting, affecting the safety-blocking behavior.

Passing a safety setting for a category changes the allowed probability that
content is blocked.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::HarmCategory>)

Required. The category for this setting.

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::SafetySetting::HarmBlockThreshold>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
