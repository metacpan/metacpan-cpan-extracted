package Google::Cloud::Vision::V1::TextAnnotation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Vision::V1::Geometry };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvdmlzaW9uL3YxL3RleHRfYW5ub3RhdGlvbi5wcm90bxIWZ29vZ2xl
LmNsb3VkLnZpc2lvbi52MRolZ29vZ2xlL2Nsb3VkL3Zpc2lvbi92MS9nZW9tZXRyeS5wcm90
byLvBAoOVGV4dEFubm90YXRpb24SMgoFcGFnZXMYASADKAsyHC5nb29nbGUuY2xvdWQudmlz
aW9uLnYxLlBhZ2VSBXBhZ2VzEhIKBHRleHQYAiABKAlSBHRleHQaVwoQRGV0ZWN0ZWRMYW5n
dWFnZRIjCg1sYW5ndWFnZV9jb2RlGAEgASgJUgxsYW5ndWFnZUNvZGUSHgoKY29uZmlkZW5j
ZRgCIAEoAlIKY29uZmlkZW5jZRrlAQoNRGV0ZWN0ZWRCcmVhaxJSCgR0eXBlGAEgASgOMj4u
Z29vZ2xlLmNsb3VkLnZpc2lvbi52MS5UZXh0QW5ub3RhdGlvbi5EZXRlY3RlZEJyZWFrLkJy
ZWFrVHlwZVIEdHlwZRIbCglpc19wcmVmaXgYAiABKAhSCGlzUHJlZml4ImMKCUJyZWFrVHlw
ZRILCgdVTktOT1dOEAASCQoFU1BBQ0UQARIOCgpTVVJFX1NQQUNFEAISEgoORU9MX1NVUkVf
U1BBQ0UQAxIKCgZIWVBIRU4QBBIOCgpMSU5FX0JSRUFLEAUa0wEKDFRleHRQcm9wZXJ0eRJm
ChJkZXRlY3RlZF9sYW5ndWFnZXMYASADKAsyNy5nb29nbGUuY2xvdWQudmlzaW9uLnYxLlRl
eHRBbm5vdGF0aW9uLkRldGVjdGVkTGFuZ3VhZ2VSEWRldGVjdGVkTGFuZ3VhZ2VzElsKDmRl
dGVjdGVkX2JyZWFrGAIgASgLMjQuZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5UZXh0QW5ub3Rh
dGlvbi5EZXRlY3RlZEJyZWFrUg1kZXRlY3RlZEJyZWFrItwBCgRQYWdlEk8KCHByb3BlcnR5
GAEgASgLMjMuZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5UZXh0QW5ub3RhdGlvbi5UZXh0UHJv
cGVydHlSCHByb3BlcnR5EhQKBXdpZHRoGAIgASgFUgV3aWR0aBIWCgZoZWlnaHQYAyABKAVS
BmhlaWdodBI1CgZibG9ja3MYBCADKAsyHS5nb29nbGUuY2xvdWQudmlzaW9uLnYxLkJsb2Nr
UgZibG9ja3MSHgoKY29uZmlkZW5jZRgFIAEoAlIKY29uZmlkZW5jZSKgAwoFQmxvY2sSTwoI
cHJvcGVydHkYASABKAsyMy5nb29nbGUuY2xvdWQudmlzaW9uLnYxLlRleHRBbm5vdGF0aW9u
LlRleHRQcm9wZXJ0eVIIcHJvcGVydHkSRwoMYm91bmRpbmdfYm94GAIgASgLMiQuZ29vZ2xl
LmNsb3VkLnZpc2lvbi52MS5Cb3VuZGluZ1BvbHlSC2JvdW5kaW5nQm94EkEKCnBhcmFncmFw
aHMYAyADKAsyIS5nb29nbGUuY2xvdWQudmlzaW9uLnYxLlBhcmFncmFwaFIKcGFyYWdyYXBo
cxJGCgpibG9ja190eXBlGAQgASgOMicuZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5CbG9jay5C
bG9ja1R5cGVSCWJsb2NrVHlwZRIeCgpjb25maWRlbmNlGAUgASgCUgpjb25maWRlbmNlIlIK
CUJsb2NrVHlwZRILCgdVTktOT1dOEAASCAoEVEVYVBABEgkKBVRBQkxFEAISCwoHUElDVFVS
RRADEgkKBVJVTEVSEAQSCwoHQkFSQ09ERRAFIvkBCglQYXJhZ3JhcGgSTwoIcHJvcGVydHkY
ASABKAsyMy5nb29nbGUuY2xvdWQudmlzaW9uLnYxLlRleHRBbm5vdGF0aW9uLlRleHRQcm9w
ZXJ0eVIIcHJvcGVydHkSRwoMYm91bmRpbmdfYm94GAIgASgLMiQuZ29vZ2xlLmNsb3VkLnZp
c2lvbi52MS5Cb3VuZGluZ1BvbHlSC2JvdW5kaW5nQm94EjIKBXdvcmRzGAMgAygLMhwuZ29v
Z2xlLmNsb3VkLnZpc2lvbi52MS5Xb3JkUgV3b3JkcxIeCgpjb25maWRlbmNlGAQgASgCUgpj
b25maWRlbmNlIvoBCgRXb3JkEk8KCHByb3BlcnR5GAEgASgLMjMuZ29vZ2xlLmNsb3VkLnZp
c2lvbi52MS5UZXh0QW5ub3RhdGlvbi5UZXh0UHJvcGVydHlSCHByb3BlcnR5EkcKDGJvdW5k
aW5nX2JveBgCIAEoCzIkLmdvb2dsZS5jbG91ZC52aXNpb24udjEuQm91bmRpbmdQb2x5Ugti
b3VuZGluZ0JveBI4CgdzeW1ib2xzGAMgAygLMh4uZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5T
eW1ib2xSB3N5bWJvbHMSHgoKY29uZmlkZW5jZRgEIAEoAlIKY29uZmlkZW5jZSLWAQoGU3lt
Ym9sEk8KCHByb3BlcnR5GAEgASgLMjMuZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5UZXh0QW5u
b3RhdGlvbi5UZXh0UHJvcGVydHlSCHByb3BlcnR5EkcKDGJvdW5kaW5nX2JveBgCIAEoCzIk
Lmdvb2dsZS5jbG91ZC52aXNpb24udjEuQm91bmRpbmdQb2x5Ugtib3VuZGluZ0JveBISCgR0
ZXh0GAMgASgJUgR0ZXh0Eh4KCmNvbmZpZGVuY2UYBCABKAJSCmNvbmZpZGVuY2VCdAoaY29t
Lmdvb2dsZS5jbG91ZC52aXNpb24udjFCE1RleHRBbm5vdGF0aW9uUHJvdG9QAVo1Y2xvdWQu
Z29vZ2xlLmNvbS9nby92aXNpb24vdjIvYXBpdjEvdmlzaW9ucGI7dmlzaW9ucGL4AQGiAgRH
Q1ZOSulDCgcSBQ4AggIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAfCgkKAgMAEgMSAC8KCAoBCBIDFAAfCgkKAggfEgMUAB8KCAoBCBIDFQBMCgkKAggL
EgMVAEwKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA0CgkKAggIEgMXADQKCAoBCBID
GAAzCgkKAggBEgMYADMKCAoBCBIDGQAiCgkKAggkEgMZACIK/QMKAgQAEgQjAFwBGvADIFRl
eHRBbm5vdGF0aW9uIGNvbnRhaW5zIGEgc3RydWN0dXJlZCByZXByZXNlbnRhdGlvbiBvZiBP
Q1IgZXh0cmFjdGVkIHRleHQuCiBUaGUgaGllcmFyY2h5IG9mIGFuIE9DUiBleHRyYWN0ZWQg
dGV4dCBzdHJ1Y3R1cmUgaXMgbGlrZSB0aGlzOgogICAgIFRleHRBbm5vdGF0aW9uIC0+IFBh
Z2UgLT4gQmxvY2sgLT4gUGFyYWdyYXBoIC0+IFdvcmQgLT4gU3ltYm9sCiBFYWNoIHN0cnVj
dHVyYWwgY29tcG9uZW50LCBzdGFydGluZyBmcm9tIFBhZ2UsIG1heSBmdXJ0aGVyIGhhdmUg
dGhlaXIgb3duCiBwcm9wZXJ0aWVzLiBQcm9wZXJ0aWVzIGRlc2NyaWJlIGRldGVjdGVkIGxh
bmd1YWdlcywgYnJlYWtzIGV0Yy4uIFBsZWFzZSByZWZlcgogdG8gdGhlCiBbVGV4dEFubm90
YXRpb24uVGV4dFByb3BlcnR5XVtnb29nbGUuY2xvdWQudmlzaW9uLnYxLlRleHRBbm5vdGF0
aW9uLlRleHRQcm9wZXJ0eV0KIG1lc3NhZ2UgZGVmaW5pdGlvbiBiZWxvdyBmb3IgbW9yZSBk
ZXRhaWwuCgoKCgMEAAESAyMIFgo9CgQEAAMAEgQlAi0DGi8gRGV0ZWN0ZWQgbGFuZ3VhZ2Ug
Zm9yIGEgc3RydWN0dXJhbCBjb21wb25lbnQuCgoMCgUEAAMAARIDJQoaCqUBCgYEAAMAAgAS
AykEHRqVASBUaGUgQkNQLTQ3IGxhbmd1YWdlIGNvZGUsIHN1Y2ggYXMgImVuLVVTIiBvciAi
c3ItTGF0biIuIEZvciBtb3JlCiBpbmZvcm1hdGlvbiwgc2VlCiBodHRwOi8vd3d3LnVuaWNv
ZGUub3JnL3JlcG9ydHMvdHIzNS8jVW5pY29kZV9sb2NhbGVfaWRlbnRpZmllci4KCg4KBwQA
AwACAAUSAykECgoOCgcEAAMAAgABEgMpCxgKDgoHBAADAAIAAxIDKRscCj8KBgQAAwACARID
LAQZGjAgQ29uZmlkZW5jZSBvZiBkZXRlY3RlZCBsYW5ndWFnZS4gUmFuZ2UgWzAsIDFdLgoK
DgoHBAADAAIBBRIDLAQJCg4KBwQAAwACAQESAywKFAoOCgcEAAMAAgEDEgMsFxgKQAoEBAAD
ARIEMAJMAxoyIERldGVjdGVkIHN0YXJ0IG9yIGVuZCBvZiBhIHN0cnVjdHVyYWwgY29tcG9u
ZW50LgoKDAoFBAADAQESAzAKFwpOCgYEAAMBBAASBDIERQUaPiBFbnVtIHRvIGRlbm90ZSB0
aGUgdHlwZSBvZiBicmVhayBmb3VuZC4gTmV3IGxpbmUsIHNwYWNlIGV0Yy4KCg4KBwQAAwEE
AAESAzIJEgosCggEAAMBBAACABIDNAYSGhsgVW5rbm93biBicmVhayBsYWJlbCB0eXBlLgoK
EAoJBAADAQQAAgABEgM0Bg0KEAoJBAADAQQAAgACEgM0EBEKIQoIBAADAQQAAgESAzcGEBoQ
IFJlZ3VsYXIgc3BhY2UuCgoQCgkEAAMBBAACAQESAzcGCwoQCgkEAAMBBAACAQISAzcODwoq
CggEAAMBBAACAhIDOgYVGhkgU3VyZSBzcGFjZSAodmVyeSB3aWRlKS4KChAKCQQAAwEEAAIC
ARIDOgYQChAKCQQAAwEEAAICAhIDOhMUCicKCAQAAwEEAAIDEgM9BhkaFiBMaW5lLXdyYXBw
aW5nIGJyZWFrLgoKEAoJBAADAQQAAgMBEgM9BhQKEAoJBAADAQQAAgMCEgM9FxgKgQEKCAQA
AwEEAAIEEgNBBhEacCBFbmQtbGluZSBoeXBoZW4gdGhhdCBpcyBub3QgcHJlc2VudCBpbiB0
ZXh0OyBkb2VzIG5vdCBjby1vY2N1ciB3aXRoCiBgU1BBQ0VgLCBgTEVBREVSX1NQQUNFYCwg
b3IgYExJTkVfQlJFQUtgLgoKEAoJBAADAQQAAgQBEgNBBgwKEAoJBAADAQQAAgQCEgNBDxAK
NAoIBAADAQQAAgUSA0QGFRojIExpbmUgYnJlYWsgdGhhdCBlbmRzIGEgcGFyYWdyYXBoLgoK
EAoJBAADAQQAAgUBEgNEBhAKEAoJBAADAQQAAgUCEgNEExQKJQoGBAADAQIAEgNIBBcaFiBE
ZXRlY3RlZCBicmVhayB0eXBlLgoKDgoHBAADAQIABhIDSAQNCg4KBwQAAwECAAESA0gOEgoO
CgcEAAMBAgADEgNIFRYKNAoGBAADAQIBEgNLBBcaJSBUcnVlIGlmIGJyZWFrIHByZXBlbmRz
IHRoZSBlbGVtZW50LgoKDgoHBAADAQIBBRIDSwQICg4KBwQAAwECAQESA0sJEgoOCgcEAAMB
AgEDEgNLFRYKTAoEBAADAhIETwJVAxo+IEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZGV0ZWN0
ZWQgb24gdGhlIHN0cnVjdHVyYWwgY29tcG9uZW50LgoKDAoFBAADAgESA08KFgpHCgYEAAMC
AgASA1EENRo4IEEgbGlzdCBvZiBkZXRlY3RlZCBsYW5ndWFnZXMgdG9nZXRoZXIgd2l0aCBj
b25maWRlbmNlLgoKDgoHBAADAgIABBIDUQQMCg4KBwQAAwICAAYSA1ENHQoOCgcEAAMCAgAB
EgNRHjAKDgoHBAADAgIAAxIDUTM0CjkKBgQAAwICARIDVAQlGiogRGV0ZWN0ZWQgc3RhcnQg
b3IgZW5kIG9mIGEgdGV4dCBzZWdtZW50LgoKDgoHBAADAgIBBhIDVAQRCg4KBwQAAwICAQES
A1QSIAoOCgcEAAMCAgEDEgNUIyQKLQoEBAACABIDWAIaGiAgTGlzdCBvZiBwYWdlcyBkZXRl
Y3RlZCBieSBPQ1IuCgoMCgUEAAIABBIDWAIKCgwKBQQAAgAGEgNYCw8KDAoFBAACAAESA1gQ
FQoMCgUEAAIAAxIDWBgZCjAKBAQAAgESA1sCEhojIFVURi04IHRleHQgZGV0ZWN0ZWQgb24g
dGhlIHBhZ2VzLgoKDAoFBAACAQUSA1sCCAoMCgUEAAIBARIDWwkNCgwKBQQAAgEDEgNbEBEK
JQoCBAESBF8AcAEaGSBEZXRlY3RlZCBwYWdlIGZyb20gT0NSLgoKCgoDBAEBEgNfCAwKOwoE
BAECABIDYQIrGi4gQWRkaXRpb25hbCBpbmZvcm1hdGlvbiBkZXRlY3RlZCBvbiB0aGUgcGFn
ZS4KCgwKBQQBAgAGEgNhAh0KDAoFBAECAAESA2EeJgoMCgUEAQIAAxIDYSkqCmkKBAQBAgES
A2UCEhpcIFBhZ2Ugd2lkdGguIEZvciBQREZzIHRoZSB1bml0IGlzIHBvaW50cy4gRm9yIGlt
YWdlcyAoaW5jbHVkaW5nCiBUSUZGcykgdGhlIHVuaXQgaXMgcGl4ZWxzLgoKDAoFBAECAQUS
A2UCBwoMCgUEAQIBARIDZQgNCgwKBQQBAgEDEgNlEBEKagoEBAECAhIDaQITGl0gUGFnZSBo
ZWlnaHQuIEZvciBQREZzIHRoZSB1bml0IGlzIHBvaW50cy4gRm9yIGltYWdlcyAoaW5jbHVk
aW5nCiBUSUZGcykgdGhlIHVuaXQgaXMgcGl4ZWxzLgoKDAoFBAECAgUSA2kCBwoMCgUEAQIC
ARIDaQgOCgwKBQQBAgIDEgNpERIKPwoEBAECAxIDbAIcGjIgTGlzdCBvZiBibG9ja3Mgb2Yg
dGV4dCwgaW1hZ2VzIGV0YyBvbiB0aGlzIHBhZ2UuCgoMCgUEAQIDBBIDbAIKCgwKBQQBAgMG
EgNsCxAKDAoFBAECAwESA2wRFwoMCgUEAQIDAxIDbBobCkcKBAQBAgQSA28CFxo6IENvbmZp
ZGVuY2Ugb2YgdGhlIE9DUiByZXN1bHRzIG9uIHRoZSBwYWdlLiBSYW5nZSBbMCwgMV0uCgoM
CgUEAQIEBRIDbwIHCgwKBQQBAgQBEgNvCBIKDAoFBAECBAMSA28VFgorCgIEAhIFcwCqAQEa
HiBMb2dpY2FsIGVsZW1lbnQgb24gdGhlIHBhZ2UuCgoKCgMEAgESA3MIDQpICgQEAgQAEgV1
AocBAxo5IFR5cGUgb2YgYSBibG9jayAodGV4dCwgaW1hZ2UgZXRjKSBhcyBpZGVudGlmaWVk
IGJ5IE9DUi4KCgwKBQQCBAABEgN1BxAKJAoGBAIEAAIAEgN3BBAaFSBVbmtub3duIGJsb2Nr
IHR5cGUuCgoOCgcEAgQAAgABEgN3BAsKDgoHBAIEAAIAAhIDdw4PCiQKBgQCBAACARIDegQN
GhUgUmVndWxhciB0ZXh0IGJsb2NrLgoKDgoHBAIEAAIBARIDegQICg4KBwQCBAACAQISA3oL
DAodCgYEAgQAAgISA30EDhoOIFRhYmxlIGJsb2NrLgoKDgoHBAIEAAICARIDfQQJCg4KBwQC
BAACAgISA30MDQoeCgYEAgQAAgMSBIABBBAaDiBJbWFnZSBibG9jay4KCg8KBwQCBAACAwES
BIABBAsKDwoHBAIEAAIDAhIEgAEODwovCgYEAgQAAgQSBIMBBA4aHyBIb3Jpem9udGFsL3Zl
cnRpY2FsIGxpbmUgYm94LgoKDwoHBAIEAAIEARIEgwEECQoPCgcEAgQAAgQCEgSDAQwNCiAK
BgQCBAACBRIEhgEEEBoQIEJhcmNvZGUgYmxvY2suCgoPCgcEAgQAAgUBEgSGAQQLCg8KBwQC
BAACBQISBIYBDg8KPgoEBAICABIEigECKxowIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZGV0
ZWN0ZWQgZm9yIHRoZSBibG9jay4KCg0KBQQCAgAGEgSKAQIdCg0KBQQCAgABEgSKAR4mCg0K
BQQCAgADEgSKASkqCtAECgQEAgIBEgSgAQIgGsEEIFRoZSBib3VuZGluZyBib3ggZm9yIHRo
ZSBibG9jay4KIFRoZSB2ZXJ0aWNlcyBhcmUgaW4gdGhlIG9yZGVyIG9mIHRvcC1sZWZ0LCB0
b3AtcmlnaHQsIGJvdHRvbS1yaWdodCwKIGJvdHRvbS1sZWZ0LiBXaGVuIGEgcm90YXRpb24g
b2YgdGhlIGJvdW5kaW5nIGJveCBpcyBkZXRlY3RlZCB0aGUgcm90YXRpb24KIGlzIHJlcHJl
c2VudGVkIGFzIGFyb3VuZCB0aGUgdG9wLWxlZnQgY29ybmVyIGFzIGRlZmluZWQgd2hlbiB0
aGUgdGV4dCBpcwogcmVhZCBpbiB0aGUgJ25hdHVyYWwnIG9yaWVudGF0aW9uLgogRm9yIGV4
YW1wbGU6CgogKiB3aGVuIHRoZSB0ZXh0IGlzIGhvcml6b250YWwgaXQgbWlnaHQgbG9vayBs
aWtlOgoKICAgICAgICAgMC0tLS0xCiAgICAgICAgIHwgICAgfAogICAgICAgICAzLS0tLTIK
CiAqIHdoZW4gaXQncyByb3RhdGVkIDE4MCBkZWdyZWVzIGFyb3VuZCB0aGUgdG9wLWxlZnQg
Y29ybmVyIGl0IGJlY29tZXM6CgogICAgICAgICAyLS0tLTMKICAgICAgICAgfCAgICB8CiAg
ICAgICAgIDEtLS0tMAoKICAgYW5kIHRoZSB2ZXJ0ZXggb3JkZXIgd2lsbCBzdGlsbCBiZSAo
MCwgMSwgMiwgMykuCgoNCgUEAgIBBhIEoAECDgoNCgUEAgIBARIEoAEPGwoNCgUEAgIBAxIE
oAEeHwpSCgQEAgICEgSjAQIkGkQgTGlzdCBvZiBwYXJhZ3JhcGhzIGluIHRoaXMgYmxvY2sg
KGlmIHRoaXMgYmxvY2tzIGlzIG9mIHR5cGUgdGV4dCkuCgoNCgUEAgICBBIEowECCgoNCgUE
AgICBhIEowELFAoNCgUEAgICARIEowEVHwoNCgUEAgICAxIEowEiIwpFCgQEAgIDEgSmAQIb
GjcgRGV0ZWN0ZWQgYmxvY2sgdHlwZSAodGV4dCwgaW1hZ2UgZXRjKSBmb3IgdGhpcyBibG9j
ay4KCg0KBQQCAgMGEgSmAQILCg0KBQQCAgMBEgSmAQwWCg0KBQQCAgMDEgSmARkaCkkKBAQC
AgQSBKkBAhcaOyBDb25maWRlbmNlIG9mIHRoZSBPQ1IgcmVzdWx0cyBvbiB0aGUgYmxvY2su
IFJhbmdlIFswLCAxXS4KCg0KBQQCAgQFEgSpAQIHCg0KBQQCAgQBEgSpAQgSCg0KBQQCAgQD
EgSpARUWClgKAgQDEgatAQDHAQEaSiBTdHJ1Y3R1cmFsIHVuaXQgb2YgdGV4dCByZXByZXNl
bnRpbmcgYSBudW1iZXIgb2Ygd29yZHMgaW4gY2VydGFpbiBvcmRlci4KCgsKAwQDARIErQEI
EQpCCgQEAwIAEgSvAQIrGjQgQWRkaXRpb25hbCBpbmZvcm1hdGlvbiBkZXRlY3RlZCBmb3Ig
dGhlIHBhcmFncmFwaC4KCg0KBQQDAgAGEgSvAQIdCg0KBQQDAgABEgSvAR4mCg0KBQQDAgAD
EgSvASkqCsEECgQEAwIBEgTAAQIgGrIEIFRoZSBib3VuZGluZyBib3ggZm9yIHRoZSBwYXJh
Z3JhcGguCiBUaGUgdmVydGljZXMgYXJlIGluIHRoZSBvcmRlciBvZiB0b3AtbGVmdCwgdG9w
LXJpZ2h0LCBib3R0b20tcmlnaHQsCiBib3R0b20tbGVmdC4gV2hlbiBhIHJvdGF0aW9uIG9m
IHRoZSBib3VuZGluZyBib3ggaXMgZGV0ZWN0ZWQgdGhlIHJvdGF0aW9uCiBpcyByZXByZXNl
bnRlZCBhcyBhcm91bmQgdGhlIHRvcC1sZWZ0IGNvcm5lciBhcyBkZWZpbmVkIHdoZW4gdGhl
IHRleHQgaXMKIHJlYWQgaW4gdGhlICduYXR1cmFsJyBvcmllbnRhdGlvbi4KIEZvciBleGFt
cGxlOgogICAqIHdoZW4gdGhlIHRleHQgaXMgaG9yaXpvbnRhbCBpdCBtaWdodCBsb29rIGxp
a2U6CiAgICAgIDAtLS0tMQogICAgICB8ICAgIHwKICAgICAgMy0tLS0yCiAgICogd2hlbiBp
dCdzIHJvdGF0ZWQgMTgwIGRlZ3JlZXMgYXJvdW5kIHRoZSB0b3AtbGVmdCBjb3JuZXIgaXQg
YmVjb21lczoKICAgICAgMi0tLS0zCiAgICAgIHwgICAgfAogICAgICAxLS0tLTAKICAgYW5k
IHRoZSB2ZXJ0ZXggb3JkZXIgd2lsbCBzdGlsbCBiZSAoMCwgMSwgMiwgMykuCgoNCgUEAwIB
BhIEwAECDgoNCgUEAwIBARIEwAEPGwoNCgUEAwIBAxIEwAEeHwo0CgQEAwICEgTDAQIaGiYg
TGlzdCBvZiBhbGwgd29yZHMgaW4gdGhpcyBwYXJhZ3JhcGguCgoNCgUEAwICBBIEwwECCgoN
CgUEAwICBhIEwwELDwoNCgUEAwICARIEwwEQFQoNCgUEAwICAxIEwwEYGQpOCgQEAwIDEgTG
AQIXGkAgQ29uZmlkZW5jZSBvZiB0aGUgT0NSIHJlc3VsdHMgZm9yIHRoZSBwYXJhZ3JhcGgu
IFJhbmdlIFswLCAxXS4KCg0KBQQDAgMFEgTGAQIHCg0KBQQDAgMBEgTGAQgSCg0KBQQDAgMD
EgTGARUWCiYKAgQEEgbKAQDlAQEaGCBBIHdvcmQgcmVwcmVzZW50YXRpb24uCgoLCgMEBAES
BMoBCAwKPQoEBAQCABIEzAECKxovIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZGV0ZWN0ZWQg
Zm9yIHRoZSB3b3JkLgoKDQoFBAQCAAYSBMwBAh0KDQoFBAQCAAESBMwBHiYKDQoFBAQCAAMS
BMwBKSoKvAQKBAQEAgESBN0BAiAarQQgVGhlIGJvdW5kaW5nIGJveCBmb3IgdGhlIHdvcmQu
CiBUaGUgdmVydGljZXMgYXJlIGluIHRoZSBvcmRlciBvZiB0b3AtbGVmdCwgdG9wLXJpZ2h0
LCBib3R0b20tcmlnaHQsCiBib3R0b20tbGVmdC4gV2hlbiBhIHJvdGF0aW9uIG9mIHRoZSBi
b3VuZGluZyBib3ggaXMgZGV0ZWN0ZWQgdGhlIHJvdGF0aW9uCiBpcyByZXByZXNlbnRlZCBh
cyBhcm91bmQgdGhlIHRvcC1sZWZ0IGNvcm5lciBhcyBkZWZpbmVkIHdoZW4gdGhlIHRleHQg
aXMKIHJlYWQgaW4gdGhlICduYXR1cmFsJyBvcmllbnRhdGlvbi4KIEZvciBleGFtcGxlOgog
ICAqIHdoZW4gdGhlIHRleHQgaXMgaG9yaXpvbnRhbCBpdCBtaWdodCBsb29rIGxpa2U6CiAg
ICAgIDAtLS0tMQogICAgICB8ICAgIHwKICAgICAgMy0tLS0yCiAgICogd2hlbiBpdCdzIHJv
dGF0ZWQgMTgwIGRlZ3JlZXMgYXJvdW5kIHRoZSB0b3AtbGVmdCBjb3JuZXIgaXQgYmVjb21l
czoKICAgICAgMi0tLS0zCiAgICAgIHwgICAgfAogICAgICAxLS0tLTAKICAgYW5kIHRoZSB2
ZXJ0ZXggb3JkZXIgd2lsbCBzdGlsbCBiZSAoMCwgMSwgMiwgMykuCgoNCgUEBAIBBhIE3QEC
DgoNCgUEBAIBARIE3QEPGwoNCgUEBAIBAxIE3QEeHwppCgQEBAICEgThAQIeGlsgTGlzdCBv
ZiBzeW1ib2xzIGluIHRoZSB3b3JkLgogVGhlIG9yZGVyIG9mIHRoZSBzeW1ib2xzIGZvbGxv
d3MgdGhlIG5hdHVyYWwgcmVhZGluZyBvcmRlci4KCg0KBQQEAgIEEgThAQIKCg0KBQQEAgIG
EgThAQsRCg0KBQQEAgIBEgThARIZCg0KBQQEAgIDEgThARwdCkkKBAQEAgMSBOQBAhcaOyBD
b25maWRlbmNlIG9mIHRoZSBPQ1IgcmVzdWx0cyBmb3IgdGhlIHdvcmQuIFJhbmdlIFswLCAx
XS4KCg0KBQQEAgMFEgTkAQIHCg0KBQQEAgMBEgTkAQgSCg0KBQQEAgMDEgTkARUWCi8KAgQF
EgboAQCCAgEaISBBIHNpbmdsZSBzeW1ib2wgcmVwcmVzZW50YXRpb24uCgoLCgMEBQESBOgB
CA4KPwoEBAUCABIE6gECKxoxIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZGV0ZWN0ZWQgZm9y
IHRoZSBzeW1ib2wuCgoNCgUEBQIABhIE6gECHQoNCgUEBQIAARIE6gEeJgoNCgUEBQIAAxIE
6gEpKgq+BAoEBAUCARIE+wECIBqvBCBUaGUgYm91bmRpbmcgYm94IGZvciB0aGUgc3ltYm9s
LgogVGhlIHZlcnRpY2VzIGFyZSBpbiB0aGUgb3JkZXIgb2YgdG9wLWxlZnQsIHRvcC1yaWdo
dCwgYm90dG9tLXJpZ2h0LAogYm90dG9tLWxlZnQuIFdoZW4gYSByb3RhdGlvbiBvZiB0aGUg
Ym91bmRpbmcgYm94IGlzIGRldGVjdGVkIHRoZSByb3RhdGlvbgogaXMgcmVwcmVzZW50ZWQg
YXMgYXJvdW5kIHRoZSB0b3AtbGVmdCBjb3JuZXIgYXMgZGVmaW5lZCB3aGVuIHRoZSB0ZXh0
IGlzCiByZWFkIGluIHRoZSAnbmF0dXJhbCcgb3JpZW50YXRpb24uCiBGb3IgZXhhbXBsZToK
ICAgKiB3aGVuIHRoZSB0ZXh0IGlzIGhvcml6b250YWwgaXQgbWlnaHQgbG9vayBsaWtlOgog
ICAgICAwLS0tLTEKICAgICAgfCAgICB8CiAgICAgIDMtLS0tMgogICAqIHdoZW4gaXQncyBy
b3RhdGVkIDE4MCBkZWdyZWVzIGFyb3VuZCB0aGUgdG9wLWxlZnQgY29ybmVyIGl0IGJlY29t
ZXM6CiAgICAgIDItLS0tMwogICAgICB8ICAgIHwKICAgICAgMS0tLS0wCiAgIGFuZCB0aGUg
dmVydGV4IG9yZGVyIHdpbGwgc3RpbGwgYmUgKDAsIDEsIDIsIDMpLgoKDQoFBAUCAQYSBPsB
Ag4KDQoFBAUCAQESBPsBDxsKDQoFBAUCAQMSBPsBHh8KPgoEBAUCAhIE/gECEhowIFRoZSBh
Y3R1YWwgVVRGLTggcmVwcmVzZW50YXRpb24gb2YgdGhlIHN5bWJvbC4KCg0KBQQFAgIFEgT+
AQIICg0KBQQFAgIBEgT+AQkNCg0KBQQFAgIDEgT+ARARCksKBAQFAgMSBIECAhcaPSBDb25m
aWRlbmNlIG9mIHRoZSBPQ1IgcmVzdWx0cyBmb3IgdGhlIHN5bWJvbC4gUmFuZ2UgWzAsIDFd
LgoKDQoFBAUCAwUSBIECAgcKDQoFBAUCAwESBIECCBIKDQoFBAUCAwMSBIECFRZiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation ===
    # Fields for TextAnnotation
    # Field: pages Type: 11 (.google.cloud.vision.v1.Page)
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Vision::V1::TextAnnotation::Page ===
    # Fields for Page
    # Field: property Type: 11 (.google.cloud.vision.v1.TextAnnotation.TextProperty)
    # Field: width Type: 5 ()
    # Field: height Type: 5 ()
    # Field: blocks Type: 11 (.google.cloud.vision.v1.Block)
    # Field: confidence Type: 2 ()

# === Message: Google::Cloud::Vision::V1::TextAnnotation::Block ===
    # Fields for Block
    # Field: property Type: 11 (.google.cloud.vision.v1.TextAnnotation.TextProperty)
    # Field: bounding_box Type: 11 (.google.cloud.vision.v1.BoundingPoly)
    # Field: paragraphs Type: 11 (.google.cloud.vision.v1.Paragraph)
    # Field: block_type Type: 14 (.google.cloud.vision.v1.Block.BlockType)
    # Field: confidence Type: 2 ()

# Enum: Block::BlockType
our $Block_UNKNOWN = 0;
our $Block_TEXT = 1;
our $Block_TABLE = 2;
our $Block_PICTURE = 3;
our $Block_RULER = 4;
our $Block_BARCODE = 5;

# === Message: Google::Cloud::Vision::V1::TextAnnotation::Paragraph ===
    # Fields for Paragraph
    # Field: property Type: 11 (.google.cloud.vision.v1.TextAnnotation.TextProperty)
    # Field: bounding_box Type: 11 (.google.cloud.vision.v1.BoundingPoly)
    # Field: words Type: 11 (.google.cloud.vision.v1.Word)
    # Field: confidence Type: 2 ()

# === Message: Google::Cloud::Vision::V1::TextAnnotation::Word ===
    # Fields for Word
    # Field: property Type: 11 (.google.cloud.vision.v1.TextAnnotation.TextProperty)
    # Field: bounding_box Type: 11 (.google.cloud.vision.v1.BoundingPoly)
    # Field: symbols Type: 11 (.google.cloud.vision.v1.Symbol)
    # Field: confidence Type: 2 ()

# === Message: Google::Cloud::Vision::V1::TextAnnotation::Symbol ===
    # Fields for Symbol
    # Field: property Type: 11 (.google.cloud.vision.v1.TextAnnotation.TextProperty)
    # Field: bounding_box Type: 11 (.google.cloud.vision.v1.BoundingPoly)
    # Field: text Type: 9 ()
    # Field: confidence Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vision::V1::TextAnnotation - Compiled Protocol Buffers messages for google/cloud/vision/v1/text_annotation.proto

=head1 SYNOPSIS

    use Google::Cloud::Vision::V1::TextAnnotation;

    my $msg = Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation->new({
        pages => $pages,
        text => $text,
    });

    # Read or update a field
    my $val = $msg->pages();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vision/v1/text_annotation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation

TextAnnotation contains a structured representation of OCR extracted text.
The hierarchy of an OCR extracted text structure is like this:
    TextAnnotation -> Page -> Block -> Paragraph -> Word -> Symbol
Each structural component, starting from Page, may further have their own
properties. Properties describe detected languages, breaks etc.. Please refer
to the
[TextAnnotation.TextProperty][google.cloud.vision.v1.TextAnnotation.TextProperty]
message definition below for more detail.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pages() >> / C<< $msg->pages($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::Page>)

List of pages detected by OCR.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

UTF-8 text detected on the pages.

=back

=head2 Google::Cloud::Vision::V1::TextAnnotation::Page

Detected page from OCR.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty>)

Additional information detected on the page.

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Int32>

Page width. For PDFs the unit is points. For images (including
TIFFs) the unit is pixels.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Int32>

Page height. For PDFs the unit is points. For images (including
TIFFs) the unit is pixels.

=item * C<< $msg->blocks() >> / C<< $msg->blocks($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::Block>)

List of blocks of text, images etc on this page.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Float>

Confidence of the OCR results on the page. Range [0, 1].

=back

=head2 Google::Cloud::Vision::V1::TextAnnotation::Block

Logical element on the page.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty>)

Additional information detected for the block.

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::BoundingPoly>)

The bounding box for the block.
The vertices are in the order of top-left, top-right, bottom-right,
bottom-left. When a rotation of the bounding box is detected the rotation
is represented as around the top-left corner as defined when the text is
read in the 'natural' orientation.
For example:

* when the text is horizontal it might look like:

        0----1
        |    |
        3----2

* when it's rotated 180 degrees around the top-left corner it becomes:

        2----3
        |    |
        1----0

  and the vertex order will still be (0, 1, 2, 3).

=item * C<< $msg->paragraphs() >> / C<< $msg->paragraphs($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::Paragraph>)

List of paragraphs in this block (if this blocks is of type text).

=item * C<< $msg->block_type() >> / C<< $msg->block_type($value) >>

Type: C<Enum> (L<Google::Cloud::Vision::V1::Block::BlockType>)

Detected block type (text, image etc) for this block.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Float>

Confidence of the OCR results on the block. Range [0, 1].

=back

=head3 Enum: Block::BlockType

=over 4

=item * C<UNKNOWN> => C<0>

=item * C<TEXT> => C<1>

=item * C<TABLE> => C<2>

=item * C<PICTURE> => C<3>

=item * C<RULER> => C<4>

=item * C<BARCODE> => C<5>

=back

=head2 Google::Cloud::Vision::V1::TextAnnotation::Paragraph

Structural unit of text representing a number of words in certain order.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty>)

Additional information detected for the paragraph.

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::BoundingPoly>)

The bounding box for the paragraph.
The vertices are in the order of top-left, top-right, bottom-right,
bottom-left. When a rotation of the bounding box is detected the rotation
is represented as around the top-left corner as defined when the text is
read in the 'natural' orientation.
For example:
  * when the text is horizontal it might look like:
     0----1
     |    |
     3----2
  * when it's rotated 180 degrees around the top-left corner it becomes:
     2----3
     |    |
     1----0
  and the vertex order will still be (0, 1, 2, 3).

=item * C<< $msg->words() >> / C<< $msg->words($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::Word>)

List of all words in this paragraph.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Float>

Confidence of the OCR results for the paragraph. Range [0, 1].

=back

=head2 Google::Cloud::Vision::V1::TextAnnotation::Word

A word representation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty>)

Additional information detected for the word.

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::BoundingPoly>)

The bounding box for the word.
The vertices are in the order of top-left, top-right, bottom-right,
bottom-left. When a rotation of the bounding box is detected the rotation
is represented as around the top-left corner as defined when the text is
read in the 'natural' orientation.
For example:
  * when the text is horizontal it might look like:
     0----1
     |    |
     3----2
  * when it's rotated 180 degrees around the top-left corner it becomes:
     2----3
     |    |
     1----0
  and the vertex order will still be (0, 1, 2, 3).

=item * C<< $msg->symbols() >> / C<< $msg->symbols($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::Symbol>)

List of symbols in the word.
The order of the symbols follows the natural reading order.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Float>

Confidence of the OCR results for the word. Range [0, 1].

=back

=head2 Google::Cloud::Vision::V1::TextAnnotation::Symbol

A single symbol representation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->property() >> / C<< $msg->property($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty>)

Additional information detected for the symbol.

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::BoundingPoly>)

The bounding box for the symbol.
The vertices are in the order of top-left, top-right, bottom-right,
bottom-left. When a rotation of the bounding box is detected the rotation
is represented as around the top-left corner as defined when the text is
read in the 'natural' orientation.
For example:
  * when the text is horizontal it might look like:
     0----1
     |    |
     3----2
  * when it's rotated 180 degrees around the top-left corner it becomes:
     2----3
     |    |
     1----0
  and the vertex order will still be (0, 1, 2, 3).

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

The actual UTF-8 representation of the symbol.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Float>

Confidence of the OCR results for the symbol. Range [0, 1].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vision::V1::TextAnnotation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
