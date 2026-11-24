package Google::Cloud::Apptopology::V1::Query;

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
Cidnb29nbGUvY2xvdWQvYXBwdG9wb2xvZ3kvdjEvcXVlcnkucHJvdG8SG2dvb2dsZS5jbG91
ZC5hcHB0b3BvbG9neS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byK4AQoM
R3JhcGhQYXR0ZXJuElIKDXN0YXJ0aW5nX25vZGUYASABKAsyKC5nb29nbGUuY2xvdWQuYXBw
dG9wb2xvZ3kudjEuTm9kZVBhdHRlcm5CA+BBAlIMc3RhcnRpbmdOb2RlElQKCW5laWdoYm9y
cxgCIAMoCzIxLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Db25uZWN0ZWROb2RlUGF0
dGVybkID4EEBUgluZWlnaGJvcnMinAEKC05vZGVQYXR0ZXJuEhkKBWFsaWFzGAEgASgJQgPg
QQFSBWFsaWFzEnIKGGxhYmVsX3Byb3BlcnRpZXNfcGF0dGVybhgDIAEoCzIzLmdvb2dsZS5j
bG91ZC5hcHB0b3BvbG9neS52MS5MYWJlbFByb3BlcnRpZXNQYXR0ZXJuQgPgQQFSFmxhYmVs
UHJvcGVydGllc1BhdHRlcm4itgIKC0VkZ2VQYXR0ZXJuElUKCWRpcmVjdGlvbhgBIAEoDjIy
Lmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5FZGdlUGF0dGVybi5EaXJlY3Rpb25CA+BB
AlIJZGlyZWN0aW9uEnIKGGxhYmVsX3Byb3BlcnRpZXNfcGF0dGVybhgCIAEoCzIzLmdvb2ds
ZS5jbG91ZC5hcHB0b3BvbG9neS52MS5MYWJlbFByb3BlcnRpZXNQYXR0ZXJuQgPgQQJSFmxh
YmVsUHJvcGVydGllc1BhdHRlcm4SGQoFYWxpYXMYAyABKAlCA+BBAVIFYWxpYXMiQQoJRGly
ZWN0aW9uEhkKFURJUkVDVElPTl9VTlNQRUNJRklFRBAAEgcKA0FOWRABEgYKAlRPEAISCAoE
RlJPTRADIp8BChRDb25uZWN0ZWROb2RlUGF0dGVybhJBCgRlZGdlGAEgASgLMiguZ29vZ2xl
LmNsb3VkLmFwcHRvcG9sb2d5LnYxLkVkZ2VQYXR0ZXJuQgPgQQJSBGVkZ2USRAoFZ3JhcGgY
AiABKAsyKS5nb29nbGUuY2xvdWQuYXBwdG9wb2xvZ3kudjEuR3JhcGhQYXR0ZXJuQgPgQQJS
BWdyYXBoIoQBChZMYWJlbFByb3BlcnRpZXNQYXR0ZXJuEjEKEmxhYmVsX21hdGNoZXJfZXhw
chgBIAEoCUID4EECUhBsYWJlbE1hdGNoZXJFeHByEjcKFXByb3BlcnR5X21hdGNoZXJfZXhw
chgCIAEoCUID4EEBUhNwcm9wZXJ0eU1hdGNoZXJFeHByQs8BCh9jb20uZ29vZ2xlLmNsb3Vk
LmFwcHRvcG9sb2d5LnYxQgpRdWVyeVByb3RvUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vYXBw
dG9wb2xvZ3kvYXBpdjEvYXBwdG9wb2xvZ3lwYjthcHB0b3BvbG9neXBiqgIbR29vZ2xlLkNs
b3VkLkFwcFRvcG9sb2d5LlYxygIbR29vZ2xlXENsb3VkXEFwcFRvcG9sb2d5XFYx6gIeR29v
Z2xlOjpDbG91ZDo6QXBwVG9wb2xvZ3k6OlYxStlFCgcSBQ4A2QEBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCAoBCBIDFAA4CgkK
AgglEgMUADgKCAoBCBIDFQBYCgkKAggLEgMVAFgKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoB
CBIDFwArCgkKAggIEgMXACsKCAoBCBIDGAA4CgkKAggBEgMYADgKCAoBCBIDGQA4CgkKAggp
EgMZADgKCAoBCBIDGgA3CgkKAggtEgMaADcKkAIKAgQAEgQhACkBGoMCIFJlY3Vyc2l2ZSBn
cmFwaCBwYXR0ZXJuIG1hdGNoZXIgdG8gc2VsZWN0IGFuZCBjb25zdHJhaW4gdGhlIHJldHVy
bmVkCiB0b3BvbG9neS4KIEFwcFRvcG9sb2d5IEFQSSBhbGxvd3MgY3ljbGUgaW4gdGhlIGdy
YXBoIHRyYXZlcnNhbCBhbmQgd2lsbCByZXR1cm4gdW5pcXVlCiBub2RlIGFuZCBlZGdlIHJl
c3VsdHMgaW4gdGhlIHJlc3BvbnNlLgogU0xPIGlzIGd1YXJhbnRlZWQgZm9yIGF0IG1vc3Qg
NSBob3BzIGluIHRoZSBncmFwaCB0cmF2ZXJzYWwuCgoKCgMEAAESAyEIFApTCgQEAAIAEgMj
AkkaRiBSZXF1aXJlZC4gUGF0dGVybiBtYXRjaGVyIHRvIHNlbGVjdCB0aGUgc3RhcnRpbmcg
bm9kZXMgaW4gdGhlIGdyYXBoLgoKDAoFBAACAAYSAyMCDQoMCgUEAAIAARIDIw4bCgwKBQQA
AgADEgMjHh8KDAoFBAACAAgSAyMgSAoPCggEAAIACJwIABIDIyFHCmQKBAQAAgESBCcCKC8a
ViBPcHRpb25hbC4gUGF0dGVybiBtYXRjaGVyIHRvIG1hdGNoIHRoZSBjb25uZWN0ZWQgc3Vi
Z3JhcGhzOyBhbGwgb2YgdGhlc2UKIGFyZSBBTkRlZC4KCgwKBQQAAgEEEgMnAgoKDAoFBAAC
AQYSAycLHwoMCgUEAAIBARIDJyApCgwKBQQAAgEDEgMnLC0KDAoFBAACAQgSAygGLgoPCggE
AAIBCJwIABIDKActCk8KAgQBEgQsADYBGkMgTm9kZSBwYXR0ZXJuIG1hdGNoZXIgdG8gbWF0
Y2ggdGhlIG5vZGUgaWQsIGxhYmVscyBhbmQgcHJvcGVydGllcy4KCgoKAwQBARIDLAgTCogC
CgQEAQIAEgMxAjwa+gEgT3B0aW9uYWwuIFJlcHJlc2VudHMgYW4gaWRlbnRpZmllciB0byBi
ZSByZWZlcmVuY2VkIGluCiBgcHJvcGVydHlfbWF0Y2hlcl9leHByYC4gRm9yIGV4YW1wbGUs
IGFuIGFsaWFzIGZvciBgYXBwYCBjYW4gYmUgcmVmZXJlbmNlZAogYXMgYGFwcC5CYXNlL2xv
Y2F0aW9uPSJ1cy1jZW50cmFsMSJgLiBgYWxpYXNgIG11c3QgYmUgdW5pcXVlIHdpdGhpbiB0
aGUKIHF1ZXJ5LCBvdGhlcndpc2UgYW4gZXJyb3Igd2lsbCBiZSByZXR1cm5lZC4KCgwKBQQB
AgAFEgMxAggKDAoFBAECAAESAzEJDgoMCgUEAQIAAxIDMRESCgwKBQQBAgAIEgMxEzsKDwoI
BAECAAicCAASAzEUOgo4CgQEAQIBEgQ0AjUvGiogT3B0aW9uYWwuIE1hdGNoZXIgZm9yIGxh
YmVscy9wcm9wZXJ0aWVzLgoKDAoFBAECAQYSAzQCGAoMCgUEAQIBARIDNBkxCgwKBQQBAgED
EgM0NDUKDAoFBAECAQgSAzUGLgoPCggEAQIBCJwIABIDNQctClYKAgQCEgQ5AFUBGkogRWRn
ZSBwYXR0ZXJuIG1hdGNoZXIgdG8gbWF0Y2ggdGhlIGVkZ2UgZGlyZWN0aW9uLCBsYWJlbHMg
YW5kIHByb3BlcnRpZXMuCgoKCgMEAgESAzkIEwozCgQEAgQAEgQ7AkcDGiUgVGhlIGRpcmVj
dGlvbiBvZiB0aGUgZWRnZSB0byBtYXRjaC4KCgwKBQQCBAABEgM7BxAKMwoGBAIEAAIAEgM9
BB4aJCBEZWZhdWx0cyB0byBESVJFQ1RJT05fVU5TUEVDSUZJRUQuCgoOCgcEAgQAAgABEgM9
BBkKDgoHBAIEAAIAAhIDPRwdCioKBgQCBAACARIDQAQMGhsgTWF0Y2ggYW55IGVkZ2UgZGly
ZWN0aW9uLgoKDgoHBAIEAAIBARIDQAQHCg4KBwQCBAACAQISA0AKCwpFCgYEAgQAAgISA0ME
Cxo2IE1hdGNoIHRoZSBlZGdlIGRpcmVjdGlvbiBmcm9tIHNvdXJjZSB0byBkZXN0aW5hdGlv
bi4KCg4KBwQCBAACAgESA0MEBgoOCgcEAgQAAgICEgNDCQoKRQoGBAIEAAIDEgNGBA0aNiBN
YXRjaCB0aGUgZWRnZSBkaXJlY3Rpb24gZnJvbSBkZXN0aW5hdGlvbiB0byBzb3VyY2UuCgoO
CgcEAgQAAgMBEgNGBAgKDgoHBAIEAAIDAhIDRgsMCjwKBAQCAgASA0oCQxovIFJlcXVpcmVk
LiBUaGUgZGlyZWN0aW9uIG9mIHRoZSBlZGdlIHRvIG1hdGNoLgoKDAoFBAICAAYSA0oCCwoM
CgUEAgIAARIDSgwVCgwKBQQCAgADEgNKGBkKDAoFBAICAAgSA0oaQgoPCggEAgIACJwIABID
ShtBCjgKBAQCAgESBE0CTi8aKiBSZXF1aXJlZC4gTWF0Y2hlciBmb3IgbGFiZWxzL3Byb3Bl
cnRpZXMuCgoMCgUEAgIBBhIDTQIYCgwKBQQCAgEBEgNNGTEKDAoFBAICAQMSA000NQoMCgUE
AgIBCBIDTgYuCg8KCAQCAgEInAgAEgNOBy0KhgIKBAQCAgISA1QCPBr4ASBPcHRpb25hbC4g
UmVwcmVzZW50cyBhbiBpZGVudGlmaWVyIHRvIGJlIHJlZmVyZW5jZWQgaW4KIGBwcm9wZXJ0
eV9tYXRjaGVyX2V4cHJgLiBGb3IgZXhhbXBsZSwgYW4gYWxpYXMgZm9yIGBlZGdlYCBjYW4g
YmUgcmVmZXJlbmNlZAogYXMgYGVkZ2UuZGVzY3JpcHRpb24gPSAidmFsdWVfMSJgLiBgYWxp
YXNgIG11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgcXVlcnksCiBvdGhlcndpc2UgYW4gZXJy
b3Igd2lsbCBiZSByZXR1cm5lZC4KCgwKBQQCAgIFEgNUAggKDAoFBAICAgESA1QJDgoMCgUE
AgICAxIDVBESCgwKBQQCAgIIEgNUEzsKDwoIBAICAgicCAASA1QUOgpWCgIEAxIEWABeARpK
IEVkZ2UgcGF0dGVybiBtYXRjaGVyIHRvIG1hdGNoIHRoZSBlZGdlIGRpcmVjdGlvbiwgbGFi
ZWxzIGFuZCBwcm9wZXJ0aWVzLgoKCgoDBAMBEgNYCBwKSwoEBAMCABIDWgJAGj4gUmVxdWly
ZWQuIFRvIG1hdGNoIHRoZSBlZGdlIGNvbm5lY3RlZCB0aGUgbmVpZ2hib3Igc3ViZ3JhcGgu
CgoMCgUEAwIABhIDWgINCgwKBQQDAgABEgNaDhIKDAoFBAMCAAMSA1oVFgoMCgUEAwIACBID
Whc/Cg8KCAQDAgAInAgAEgNaGD4KSgoEBAMCARIDXQJCGj0gUmVxdWlyZWQuIFJlY3Vyc2l2
ZSBtYXRjaGVyIHRvIG1hdGNoIHRoZSBuZWlnaGJvciBzdWJncmFwaC4KCgwKBQQDAgEGEgNd
Ag4KDAoFBAMCAQESA10PFAoMCgUEAwIBAxIDXRcYCgwKBQQDAgEIEgNdGUEKDwoIBAMCAQic
CAASA10aQApkCgIEBBIFYgDZAQEaVyBNYXRjaGVyIGZvciBsYWJlbCBhbmQgcHJvcGVydHku
IFRoZSBtYXRjaGVyIGFjY2VwdHMgYm90aCBleGFjdCBtYXRjaCBhbmQKIGV4cHJlc3Npb24u
CgoKCgMEBAESA2IIHgqqAgoEBAQCABIDaAJJGpwCIFJlcXVpcmVkLiBNYXRjaGVyIGV4cHJl
c3Npb24gZm9yIGxhYmVscy4gQWxsb3cgT1IgLyBBTkQgb3BlcmF0b3JzOwogVGhlIHN5bnRh
eCBpcyBkZWZpbmVkIGJ5IHRoZSBmb2xsb3dpbmcgZ3JhbW1hcjoKICAtIFRoZSBsYWJlbCBl
eHByZXNzaW9uIGNhbiB1c2UgZWl0aGVyIGBPUmAgb3IgYEFORGAgb3BlcmF0b3IsIGJ1dCBu
b3QgYQogICAgY29tYmluYXRpb24gb2YgYm90aC4KIEV4YW1wbGU6IGBBcHBIdWIvQXBwbGlj
YXRpb25gLCBgQXBwSHViL1dvcmtsb2FkIE9SIEFwcEh1Yi9TZXJ2aWNlYAoKDAoFBAQCAAUS
A2gCCAoMCgUEBAIAARIDaAkbCgwKBQQEAgADEgNoHh8KDAoFBAQCAAgSA2ggSAoPCggEBAIA
CJwIABIDaCFHCoEmCgQEBAIBEgTYAQJMGvIlIE9wdGlvbmFsLiBUaGUgc3ludGF4IG9mIHRo
ZSBmaWx0ZXIgaXMgZGVmaW5lZCBieSB0aGUgZm9sbG93aW5nIGdyYW1tYXI6CiBodHRwczov
L2dvb2dsZS5haXAuZGV2LzE2MC4KCiBSZWZlcmVuY2luZyBwcm9wZXJ0aWVzIG9mIGdyYXBo
IGVsZW1lbnRzIHVzaW5nIHRyYXZlcnNhbCBvcGVyYXRvciBgLmAuCiBSZXBlYXRlZCBwcm9w
ZXJ0aWVzIGNhbm5vdCBiZSB0cmF2ZXJzZWQuCiBlLmcuIGBlLk5vZGVOYW1lYCwgd2hlcmUg
YGVgIGlzIGEgbm9kZSBvciBlZGdlIGFsaWFzLgoKIFRoZSBmb2xsb3dpbmcgcHJvcGVydGll
cyBhcmUgc3VwcG9ydGVkIGZvciBhbGwgbm9kZSBhbmQgZWRnZSB0eXBlczoKCiAtIGBMYWJl
bHNgOiByZXBlYXRlZCBzdHJpbmcgcHJvcGVydHkuIENhbiBiZSB1c2VkIHRvIGNvbWJpbmUg
Y29uZGl0aW9ucwogYmV0d2VlbiBsYWJlbHMgYW5kIHByb3BlcnRpZXMuCiAgICBlLmcuIGBl
LkxhYmVscyA6ICJsYWJlbF8xImAgdG8gbWF0Y2ggYSBub2RlL2VkZ2Ugd2l0aCBsYWJlbAog
ICAgYGxhYmVsXzFgLgogLSBgTm9kZU5hbWUvRWRnZU5hbWVgOiBzdHJpbmcgcHJvcGVydHku
IFN1cHBvcnQgZm9yIGZpbHRlcmluZyBieSBub2RlIG9yCiBlZGdlIG5hbWVzLgogICAgZS5n
LiBgYXBwLk5vZGVOYW1lID0gImFwcGh1Yi5pby9BcHBsaWNhdGlvbiJgCgogT3RoZXIgcHJv
cGVydGllcyB0eXBlcyBjYW4gYmUgZm91bmQgYXQKIGh0dHBzOi8vYXBwdG9wb2xvZ3kuZ29v
Z2xlYXBpcy5jb20vdjEvR2V0U2NoZW1hCgogVGhlIGZvbGxvd2luZyBvcGVyYXRvcnMgYXJl
IHN1cHBvcnRlZCBvbiBwcm9wZXJ0aWVzOgogMS4gQ2hlY2tpbmcgaWYgYSBub24tcmVwZWF0
ZWQgcHJvcGVydHkgb2YgYSBncmFwaCBlbGVtZW50IGlzIGVxdWFsIHRvIGEKIHNjYWxhciB2
YWx1ZSB1c2luZyB0aGUgZXF1YWxpdHkgb3BlcmF0b3IgYD1gLgogIC0gTEhTIG11c3QgYmUg
YSBub2RlL2VkZ2UgcHJvcGVydHkuCiAgLSBSSFMgbXVzdCBiZSBhIHNjYWxhciBsaXRlcmFs
LgogIC0gU3VwcG9ydGVkIHZhbHVlIHR5cGVzOiBzdHJpbmcgKGVuY2xvc2VkIGluIGRvdWJs
ZSBxdW90ZXMpLCBpbnQsIGRvdWJsZSwKICAgIGFuZCBib29sZWFuLgogZS5nLiBgZS5wcm9q
ZWN0ID0gInByb2plY3RfMSJgCgogMi4gQ2hlY2tpbmcgaWYgYSBub24tcmVwZWF0ZWQgcHJv
cGVydHkgb2YgYSBncmFwaCBlbGVtZW50IHNhdGlzZmllcyBhCiBjb25kaXRpb24gdXNpbmcg
dGhlIGNvbXBhcmlzb24gb3BlcmF0b3JzIGA+YCwgYDxgLCBgPj1gLCBgPD1gLgogIC0gTEhT
IG11c3QgYmUgYSBub2RlL2VkZ2UgcHJvcGVydHkuCiAgLSBSSFMgbXVzdCBiZSBhIHNjYWxh
ciBsaXRlcmFsLgogIC0gU3VwcG9ydGVkIHZhbHVlIHR5cGVzOiBzdHJpbmcgKGVuY2xvc2Vk
IGluIGRvdWJsZSBxdW90ZXMpLCBpbnQsIGRvdWJsZS4KIGUuZy4gYGUuTnVtZXJpY1Byb3Bl
cnR5IDwgMC4xYAoKIDMuIENoZWNraW5nIGlmIGEgc2NhbGFyIHZhbHVlIGlzIHByZXNlbnQg
aW4gYSByZXBlYXRlZCBwcm9wZXJ0eQogSEFTIG9wZXJhdG9yIGA6YC4KICAtIExIUyBtdXN0
IGJlIGEgcmVwZWF0ZWQgcHJvcGVydHkuCiAgLSBSSFMgbXVzdCBiZSBhIHNjYWxhciBsaXRl
cmFsLgogIC0gU3VwcG9ydGVkIHZhbHVlIHR5cGVzOiBzdHJpbmcgKGVuY2xvc2VkIGluIGRv
dWJsZSBxdW90ZXMpLCBpbnQsIGRvdWJsZS4KIGUuZy4gYGUuTGFiZWxzIDogImxhYmVsXzEi
YCwgd2hlcmUgYGUuTGFiZWxzYCBpcyBhIHJlcGVhdGVkIHN0cmluZwogcHJvcGVydHkuCgog
NC4gQ2hlY2tpbmcgaWYgYSBwcm9wZXJ0eSBpcyBwcmVzZW50IHVzaW5nIEhBU19QUk9QRVJU
WSBvcGVyYXRvciBgOmAuCiAgLSBMSFMgbXVzdCBiZSBhIG5vZGUgb3IgZWRnZSBhbGlhcy4K
ICAtIFJIUyBtdXN0IGJlIGEgcHJvcGVydHkgbmFtZS4KIGUuZy4gYGUgOiBCYXNlL0xvY2F0
aW9uYCwgd2hlcmUgYGVgIGlzIGEgbm9kZSBvciBlZGdlIGFsaWFzLgoKIDUuIENvbWJpbmlu
ZyBtdWx0aXBsZSBmaWx0ZXJzIHVzaW5nIGxvZ2ljYWwgb3BlcmF0b3JzIDogYEFORGAsIGFu
ZCBgT1JgLgogIC0gUGFyZW50aGVzZXMgbXVzdCBiZSB1c2VkIHRvIHJlc29sdmUgYW1iaWd1
aXR5LgogZS5nLiBgZS5CYXNlL0xvY2F0aW9uID0gInVzLWNlbnRyYWwxIiBBTkQgZS5wcm9q
ZWN0ID0gInByb2plY3RfMSJgCgogNi4gVGhlIGZvbGxvd2luZyBjdXN0b20gZnVuY3Rpb25z
IGFyZSBzdXBwb3J0ZWQ6CiAgICAtICoqRVFVQUxTX0FOWShhcmcxLCBhcmcyLCBhcmczLCAu
Li4pKioKICAgICAgKiBDaGVja3MgaWYgYGFyZzFgIChhIG5vbi1yZXBlYXRlZCBwcm9wZXJ0
eSkgZXF1YWxzIGFueSBvZiB0aGUKICAgICAgICBzdWJzZXF1ZW50IHNjYWxhciBsaXRlcmFs
IGFyZ3VtZW50cy4KICAgICAgKiBhcmcxOiBub24tcmVwZWF0ZWQgcHJvcGVydHkuIFN1cHBv
cnRlZCB2YWx1ZSB0eXBlczogc3RyaW5nCiAgICAgICAgKGVuY2xvc2VkIGluIGRvdWJsZSBx
dW90ZXMpLCBpbnQsIGRvdWJsZS4KICAgICAgKiBhcmcyLCBhcmczLCAuLi46IFRoZSByZW1h
aW5pbmcgYXJndW1lbnRzIGFyZSBsaXRlcmFsIHZhbHVlcyB0bwogICAgICAgIGNvbXBhcmUg
YWdhaW5zdC4gQWxsIHRoZSBhcmd1bWVudHMgbXVzdCBiZSBvZiB0aGUgc2FtZSB0eXBlLgog
ICAgICAqIGUuZy4gYEVRVUFMU19BTlkoZS5wcm9qZWN0LCAicHJvamVjdF8xIiwgInByb2pl
Y3RfMiIpYAoKICAgIC0gKipDT05UQUlOU19BTlkoYXJnMSwgYXJnMiwgYXJnMywgLi4uKSoq
CiAgICAgICogQ2hlY2tzIGlmIGEgcmVwZWF0ZWQgcHJvcGVydHkgaGFzIGFueSBvZiB0aGUg
Z2l2ZW4gc2NhbGFyIGxpdGVyYWxzLgogICAgICAgIGFyZzE6IHJlcGVhdGVkX3Byb3BlcnR5
LiBTdXBwb3J0ZWQgZWxlbWVudCB0eXBlczogc3RyaW5nCiAgICAgICAgKGVuY2xvc2VkIGlu
IGRvdWJsZSBxdW90ZXMpLCBpbnQsIGRvdWJsZS4KICAgICAgKiBhcmcyLCBhcmczLCAuLi46
IFRoZSByZW1haW5pbmcgYXJndW1lbnRzIGFyZSBsaXRlcmFsIHZhbHVlcyB0bwogICAgICAg
IGNvbXBhcmUgYWdhaW5zdC4gQWxsIHRoZSBhcmd1bWVudHMgbXVzdCBiZSBvZiB0aGUgc2Ft
ZSB0eXBlLgogICAgICAqIGUuZy4gYENPTlRBSU5TX0FOWShlLmZvbGRlcnMsICJmb2xkZXJf
MSIsICJmb2xkZXJfMiIpYAoKICAgIC0gKipDT05UQUlOU19BTllfTEVTU19USEFOKGFyZzEs
IGFyZzIpKioKICAgICAgKiBDaGVja3MgaWYgYSByZXBlYXRlZCBwcm9wZXJ0eSBoYXMgYW55
IGVsZW1lbnQgbGVzcyB0aGFuIHRoZSBnaXZlbgogICAgICAgIHNjYWxhciBsaXRlcmFsLgog
ICAgICAqIGFyZzE6IHJlcGVhdGVkX3Byb3BlcnR5LiBTdXBwb3J0ZWQgZWxlbWVudCB0eXBl
cyBhcmU6IGludCwKICAgICAgICBkb3VibGUuCiAgICAgICogYXJnMjogc2NhbGFyIGxpdGVy
YWwKICAgICAgKiBlLmcuIGBDT05UQUlOU19BTllfTEVTU19USEFOKGUuTnVtZXJpY1Byb3Bl
cnR5LCAwLjEpYAoKICAgIC0gKipDT05UQUlOU19BTllfR1JFQVRFUl9USEFOKGFyZzEsIGFy
ZzIpKioKICAgICAgKiBDaGVja3MgaWYgYSByZXBlYXRlZCBwcm9wZXJ0eSBoYXMgYW55IGVs
ZW1lbnQgZ3JlYXRlciB0aGFuIHRoZSBnaXZlbgogICAgICAgIHNjYWxhciBsaXRlcmFsLgog
ICAgICAqIGFyZzE6IHJlcGVhdGVkX3Byb3BlcnR5LiBTdXBwb3J0ZWQgZWxlbWVudCB0eXBl
cyBhcmU6IGludCwKICAgICAgICBkb3VibGUuCiAgICAgICogYXJnMjogc2NhbGFyIGxpdGVy
YWwKICAgICAgKiBlLmcuIGBDT05UQUlOU19BTllfR1JFQVRFUl9USEFOKGUuTnVtZXJpY1By
b3BlcnR5LCAwLjEpYAoKICAgIC0gKipDT05UQUlOU19BTllfTEVTU19PUl9FUVVBTChhcmcx
LCBhcmcyKSoqCiAgICAgICogQ2hlY2tzIGlmIGEgcmVwZWF0ZWQgcHJvcGVydHkgaGFzIGFu
eSBlbGVtZW50IGxlc3MgdGhhbiBvciBlcXVhbCB0bwogICAgICAgIHRoZSBnaXZlbiBzY2Fs
YXIgbGl0ZXJhbC4KICAgICAgKiBhcmcxOiByZXBlYXRlZF9wcm9wZXJ0eS4gU3VwcG9ydGVk
IGVsZW1lbnQgdHlwZXMgYXJlOiBpbnQsCiAgICAgICAgZG91YmxlLgogICAgICAqIGFyZzI6
IHNjYWxhciBsaXRlcmFsCiAgICAgICogZS5nLiBgQ09OVEFJTlNfQU5ZX0xFU1NfT1JfRVFV
QUwoZS5OdW1lcmljUHJvcGVydHksIDAuMSlgCgogICAgLSAqKkNPTlRBSU5TX0FOWV9HUkVB
VEVSX09SX0VRVUFMKGFyZzEsIGFyZzIpKioKICAgICAgKiBDaGVja3MgaWYgYSByZXBlYXRl
ZCBwcm9wZXJ0eSBoYXMgYW55IGVsZW1lbnQgZ3JlYXRlciB0aGFuIG9yIGVxdWFsCiAgICAg
ICAgdG8gdGhlIGdpdmVuIHNjYWxhciBsaXRlcmFsLgogICAgICAqIGFyZzE6IHJlcGVhdGVk
X3Byb3BlcnR5LiBTdXBwb3J0ZWQgZWxlbWVudCB0eXBlcyBhcmU6IGludCwKICAgICAgICBk
b3VibGUuCiAgICAgICogYXJnMjogc2NhbGFyIGxpdGVyYWwKICAgICAgKiBlLmcuIGBDT05U
QUlOU19BTllfR1JFQVRFUl9PUl9FUVVBTChlLk51bWVyaWNQcm9wZXJ0eSwgMC4xKWAKCiBO
T1RFOgogIC0gRm9yIEFsZXJ0IG5vZGVzLCBvbmx5IHRoZSBlcXVhbGl0eSBvcGVyYXRvciBg
PWAgaXMgc3VwcG9ydGVkLgogICAgVGhlIGV4cHJlc3Npb24gY2Fubm90IGJlIGEgY29tcG9z
aXRlIGJvb2xlYW4gZXhwcmVzc2lvbiAoaS5lLiwgY29tYmluaW5nCiAgICBtdWx0aXBsZSBj
b25kaXRpb25zIHdpdGggQU5EL09SIGlzIG5vdCBzdXBwb3J0ZWQ7IGl0IG11c3QgYmUgc2lt
cGxlKS4KICAgIGUuZy4gYGEuTm9kZU5hbWUgPSAiYWxlcnQtMSJgIGlzIHN1cHBvcnRlZCwg
YnV0CiAgICBgYS5Ob2RlTmFtZSA9ICJhbGVydC0xIiBPUiBhLk5vZGVOYW1lID0gImFsZXJ0
LTIiYCBpcyBub3Qgc3VwcG9ydGVkLgogIC0gRm9yIHRyYWZmaWMgZWRnZXMsIGZpbHRlcnMg
Y2Fubm90IGJlIGFkZGVkLgoKDQoFBAQCAQUSBNgBAggKDQoFBAQCAQESBNgBCR4KDQoFBAQC
AQMSBNgBISIKDQoFBAQCAQgSBNgBI0sKEAoIBAQCAQicCAASBNgBJEpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apptopology::V1::Query::GraphPattern ===
    # Fields for GraphPattern
    # Field: starting_node Type: 11 (.google.cloud.apptopology.v1.NodePattern)
    # Field: neighbors Type: 11 (.google.cloud.apptopology.v1.ConnectedNodePattern)

# === Message: Google::Cloud::Apptopology::V1::Query::NodePattern ===
    # Fields for NodePattern
    # Field: alias Type: 9 ()
    # Field: label_properties_pattern Type: 11 (.google.cloud.apptopology.v1.LabelPropertiesPattern)

# === Message: Google::Cloud::Apptopology::V1::Query::EdgePattern ===
    # Fields for EdgePattern
    # Field: direction Type: 14 (.google.cloud.apptopology.v1.EdgePattern.Direction)
    # Field: label_properties_pattern Type: 11 (.google.cloud.apptopology.v1.LabelPropertiesPattern)
    # Field: alias Type: 9 ()

# Enum: EdgePattern::Direction
our $EdgePattern_DIRECTION_UNSPECIFIED = 0;
our $EdgePattern_ANY = 1;
our $EdgePattern_TO = 2;
our $EdgePattern_FROM = 3;

# === Message: Google::Cloud::Apptopology::V1::Query::ConnectedNodePattern ===
    # Fields for ConnectedNodePattern
    # Field: edge Type: 11 (.google.cloud.apptopology.v1.EdgePattern)
    # Field: graph Type: 11 (.google.cloud.apptopology.v1.GraphPattern)

# === Message: Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern ===
    # Fields for LabelPropertiesPattern
    # Field: label_matcher_expr Type: 9 ()
    # Field: property_matcher_expr Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apptopology::V1::Query - Compiled Protocol Buffers messages for google/cloud/apptopology/v1/query.proto

=head1 SYNOPSIS

    use Google::Cloud::Apptopology::V1::Query;

    my $msg = Google::Cloud::Apptopology::V1::Query::GraphPattern->new({
        starting_node => $starting_node,
        neighbors => $neighbors,
    });

    # Read or update a field
    my $val = $msg->starting_node();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apptopology::V1::Query::GraphPattern->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apptopology/v1/query.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apptopology::V1::Query::GraphPattern

Recursive graph pattern matcher to select and constrain the returned
topology.
AppTopology API allows cycle in the graph traversal and will return unique
node and edge results in the response.
SLO is guaranteed for at most 5 hops in the graph traversal.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->starting_node() >> / C<< $msg->starting_node($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::NodePattern>)

Required. Pattern matcher to select the starting nodes in the graph.

=item * C<< $msg->neighbors() >> / C<< $msg->neighbors($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::ConnectedNodePattern>)

Optional. Pattern matcher to match the connected subgraphs; all of these
are ANDed.

=back

=head2 Google::Cloud::Apptopology::V1::Query::NodePattern

Node pattern matcher to match the node id, labels and properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alias() >> / C<< $msg->alias($value) >>

Type: C<String>

Optional. Represents an identifier to be referenced in
`property_matcher_expr`. For example, an alias for `app` can be referenced
as `app.Base/location="us-central1"`. `alias` must be unique within the
query, otherwise an error will be returned.

=item * C<< $msg->label_properties_pattern() >> / C<< $msg->label_properties_pattern($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern>)

Optional. Matcher for labels/properties.

=back

=head2 Google::Cloud::Apptopology::V1::Query::EdgePattern

Edge pattern matcher to match the edge direction, labels and properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Cloud::Apptopology::V1::EdgePattern::Direction>)

Required. The direction of the edge to match.

=item * C<< $msg->label_properties_pattern() >> / C<< $msg->label_properties_pattern($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern>)

Required. Matcher for labels/properties.

=item * C<< $msg->alias() >> / C<< $msg->alias($value) >>

Type: C<String>

Optional. Represents an identifier to be referenced in
`property_matcher_expr`. For example, an alias for `edge` can be referenced
as `edge.description = "value_1"`. `alias` must be unique within the query,
otherwise an error will be returned.

=back

=head3 Enum: EdgePattern::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<ANY> => C<1>

=item * C<TO> => C<2>

=item * C<FROM> => C<3>

=back

=head2 Google::Cloud::Apptopology::V1::Query::ConnectedNodePattern

Edge pattern matcher to match the edge direction, labels and properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->edge() >> / C<< $msg->edge($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::EdgePattern>)

Required. To match the edge connected the neighbor subgraph.

=item * C<< $msg->graph() >> / C<< $msg->graph($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Query::GraphPattern>)

Required. Recursive matcher to match the neighbor subgraph.

=back

=head2 Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern

Matcher for label and property. The matcher accepts both exact match and
expression.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label_matcher_expr() >> / C<< $msg->label_matcher_expr($value) >>

Type: C<String>

Required. Matcher expression for labels. Allow OR / AND operators;
The syntax is defined by the following grammar:
 - The label expression can use either `OR` or `AND` operator, but not a
   combination of both.
Example: `AppHub/Application`, `AppHub/Workload OR AppHub/Service`

=item * C<< $msg->property_matcher_expr() >> / C<< $msg->property_matcher_expr($value) >>

Type: C<String>

Optional. The syntax of the filter is defined by the following grammar:
https://google.aip.dev/160.

Referencing properties of graph elements using traversal operator `.`.
Repeated properties cannot be traversed.
e.g. `e.NodeName`, where `e` is a node or edge alias.

The following properties are supported for all node and edge types:

- `Labels`: repeated string property. Can be used to combine conditions
between labels and properties.
   e.g. `e.Labels : "label_1"` to match a node/edge with label
   `label_1`.
- `NodeName/EdgeName`: string property. Support for filtering by node or
edge names.
   e.g. `app.NodeName = "apphub.io/Application"`

Other properties types can be found at
https://apptopology.googleapis.com/v1/GetSchema

The following operators are supported on properties:
1. Checking if a non-repeated property of a graph element is equal to a
scalar value using the equality operator `=`.
 - LHS must be a node/edge property.
 - RHS must be a scalar literal.
 - Supported value types: string (enclosed in double quotes), int, double,
   and boolean.
e.g. `e.project = "project_1"`

2. Checking if a non-repeated property of a graph element satisfies a
condition using the comparison operators `>`, `<`, `>=`, `<=`.
 - LHS must be a node/edge property.
 - RHS must be a scalar literal.
 - Supported value types: string (enclosed in double quotes), int, double.
e.g. `e.NumericProperty < 0.1`

3. Checking if a scalar value is present in a repeated property
HAS operator `:`.
 - LHS must be a repeated property.
 - RHS must be a scalar literal.
 - Supported value types: string (enclosed in double quotes), int, double.
e.g. `e.Labels : "label_1"`, where `e.Labels` is a repeated string
property.

4. Checking if a property is present using HAS_PROPERTY operator `:`.
 - LHS must be a node or edge alias.
 - RHS must be a property name.
e.g. `e : Base/Location`, where `e` is a node or edge alias.

5. Combining multiple filters using logical operators : `AND`, and `OR`.
 - Parentheses must be used to resolve ambiguity.
e.g. `e.Base/Location = "us-central1" AND e.project = "project_1"`

6. The following custom functions are supported:
   - B<EQUALS_ANY(arg1, arg2, arg3, ...)>
     * Checks if `arg1` (a non-repeated property) equals any of the
       subsequent scalar literal arguments.
     * arg1: non-repeated property. Supported value types: string
       (enclosed in double quotes), int, double.
     * arg2, arg3, ...: The remaining arguments are literal values to
       compare against. All the arguments must be of the same type.
     * e.g. `EQUALS_ANY(e.project, "project_1", "project_2")`

   - B<CONTAINS_ANY(arg1, arg2, arg3, ...)>
     * Checks if a repeated property has any of the given scalar literals.
       arg1: repeated_property. Supported element types: string
       (enclosed in double quotes), int, double.
     * arg2, arg3, ...: The remaining arguments are literal values to
       compare against. All the arguments must be of the same type.
     * e.g. `CONTAINS_ANY(e.folders, "folder_1", "folder_2")`

   - B<CONTAINS_ANY_LESS_THAN(arg1, arg2)>
     * Checks if a repeated property has any element less than the given
       scalar literal.
     * arg1: repeated_property. Supported element types are: int,
       double.
     * arg2: scalar literal
     * e.g. `CONTAINS_ANY_LESS_THAN(e.NumericProperty, 0.1)`

   - B<CONTAINS_ANY_GREATER_THAN(arg1, arg2)>
     * Checks if a repeated property has any element greater than the given
       scalar literal.
     * arg1: repeated_property. Supported element types are: int,
       double.
     * arg2: scalar literal
     * e.g. `CONTAINS_ANY_GREATER_THAN(e.NumericProperty, 0.1)`

   - B<CONTAINS_ANY_LESS_OR_EQUAL(arg1, arg2)>
     * Checks if a repeated property has any element less than or equal to
       the given scalar literal.
     * arg1: repeated_property. Supported element types are: int,
       double.
     * arg2: scalar literal
     * e.g. `CONTAINS_ANY_LESS_OR_EQUAL(e.NumericProperty, 0.1)`

   - B<CONTAINS_ANY_GREATER_OR_EQUAL(arg1, arg2)>
     * Checks if a repeated property has any element greater than or equal
       to the given scalar literal.
     * arg1: repeated_property. Supported element types are: int,
       double.
     * arg2: scalar literal
     * e.g. `CONTAINS_ANY_GREATER_OR_EQUAL(e.NumericProperty, 0.1)`

NOTE:
 - For Alert nodes, only the equality operator `=` is supported.
   The expression cannot be a composite boolean expression (i.e., combining
   multiple conditions with AND/OR is not supported; it must be simple).
   e.g. `a.NodeName = "alert-1"` is supported, but
   `a.NodeName = "alert-1" OR a.NodeName = "alert-2"` is not supported.
 - For traffic edges, filters cannot be added.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apptopology::V1::Query::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
