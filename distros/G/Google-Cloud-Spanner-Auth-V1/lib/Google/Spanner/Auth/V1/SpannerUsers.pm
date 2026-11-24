package Google::Spanner::Auth::V1::SpannerUsers;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Spanner::Auth::V1::Authentication };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvc3Bhbm5lci9hdXRoL3YxL3NwYW5uZXJfdXNlcnMucHJvdG8SFmdvb2dsZS5z
cGFubmVyLmF1dGgudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdv
b2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGitnb29nbGUvc3Bhbm5lci9hdXRoL3Yx
L2F1dGhlbnRpY2F0aW9uLnByb3RvIr8CCgRVc2VyEhcKBG5hbWUYASABKAlCA+BBCFIEbmFt
ZRIcCgd1c2VyX2lkGAIgASgJQgPgQQJSBnVzZXJJZBI9CgVzdGF0ZRgDIAEoDjIiLmdvb2ds
ZS5zcGFubmVyLmF1dGgudjEuVXNlci5TdGF0ZUID4EEDUgVzdGF0ZRI5CgVyb2xlcxgEIAMo
CUIj4EEB+kEdChtzcGFubmVyLmdvb2dsZWFwaXMuY29tL1JvbGVSBXJvbGVzIkkKBVN0YXRl
EhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESDAoIQ1JFQVRJTkcQAhIPCgtE
RUFDVElWQVRFRBADOjvqQTgKG3NwYW5uZXIuZ29vZ2xlYXBpcy5jb20vVXNlchIMdXNlcnMv
e3VzZXJ9KgV1c2VyczIEdXNlciKhAQoEUm9sZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUS
HAoHcm9sZV9pZBgCIAEoCUID4EEDUgZyb2xlSWQSJQoLcGVybWlzc2lvbnMYAyADKAlCA+BB
A1ILcGVybWlzc2lvbnM6O+pBOAobc3Bhbm5lci5nb29nbGVhcGlzLmNvbS9Sb2xlEgxyb2xl
cy97cm9sZX0qBXJvbGVzMgRyb2xlIooDChFDcmVhdGVVc2VyUmVxdWVzdBI1CgR1c2VyGAEg
ASgLMhwuZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5Vc2VyQgPgQQJSBHVzZXISXQoNc2NyYW1f
cmVxdWVzdBgDIAEoCzIxLmdvb2dsZS5zcGFubmVyLmF1dGgudjEuU2NyYW1OZXdDcmVkZW50
aWFsUmVxdWVzdEID4EEBSABSDHNjcmFtUmVxdWVzdBJgCg5vcGFxdWVfcmVxdWVzdBgEIAEo
CzIyLmdvb2dsZS5zcGFubmVyLmF1dGgudjEuT3BhcXVlTmV3Q3JlZGVudGlhbFJlcXVlc3RC
A+BBAUgAUg1vcGFxdWVSZXF1ZXN0EnIKEWhhbmRzaGFrZV9yZXF1ZXN0GAUgASgLMj4uZ29v
Z2xlLnNwYW5uZXIuYXV0aC52MS5QYXNzd29yZEF1dGhlbnRpY2F0aW9uSGFuZHNoYWtlUmVx
dWVzdEID4EEBSABSEGhhbmRzaGFrZVJlcXVlc3RCCQoHcmVxdWVzdCKBAwoSQ3JlYXRlVXNl
clJlc3BvbnNlEjAKBHVzZXIYASABKAsyHC5nb29nbGUuc3Bhbm5lci5hdXRoLnYxLlVzZXJS
BHVzZXISWwoOc2NyYW1fcmVzcG9uc2UYAiABKAsyMi5nb29nbGUuc3Bhbm5lci5hdXRoLnYx
LlNjcmFtTmV3Q3JlZGVudGlhbFJlc3BvbnNlSABSDXNjcmFtUmVzcG9uc2USXgoPb3BhcXVl
X3Jlc3BvbnNlGAMgASgLMjMuZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5PcGFxdWVOZXdDcmVk
ZW50aWFsUmVzcG9uc2VIAFIOb3BhcXVlUmVzcG9uc2UScAoSaGFuZHNoYWtlX3Jlc3BvbnNl
GAUgASgLMj8uZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5QYXNzd29yZEF1dGhlbnRpY2F0aW9u
SGFuZHNoYWtlUmVzcG9uc2VIAFIRaGFuZHNoYWtlUmVzcG9uc2VCCgoIcmVzcG9uc2UijAEK
EVVwZGF0ZVVzZXJSZXF1ZXN0EjUKBHVzZXIYASABKAsyHC5nb29nbGUuc3Bhbm5lci5hdXRo
LnYxLlVzZXJCA+BBAlIEdXNlchJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJJCg5HZXRVc2VyUmVxdWVzdBI3CgRu
YW1lGAEgASgJQiPgQQL6QR0KG3NwYW5uZXIuZ29vZ2xlYXBpcy5jb20vVXNlclIEbmFtZSJY
ChBMaXN0VXNlcnNSZXF1ZXN0EiAKCXBhZ2Vfc2l6ZRgBIAEoBUID4EEBUghwYWdlU2l6ZRIi
CgpwYWdlX3Rva2VuGAIgASgJQgPgQQFSCXBhZ2VUb2tlbiJvChFMaXN0VXNlcnNSZXNwb25z
ZRIyCgV1c2VycxgBIAMoCzIcLmdvb2dsZS5zcGFubmVyLmF1dGgudjEuVXNlclIFdXNlcnMS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIkwKEURlbGV0ZVVzZXJS
ZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobc3Bhbm5lci5nb29nbGVhcGlzLmNvbS9V
c2VyUgRuYW1lIlgKEExpc3RSb2xlc1JlcXVlc3QSIAoJcGFnZV9zaXplGAEgASgFQgPgQQFS
CHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2VuIm8KEUxpc3RS
b2xlc1Jlc3BvbnNlEjIKBXJvbGVzGAEgAygLMhwuZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5S
b2xlUgVyb2xlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iSQoO
R2V0Um9sZVJlcXVlc3QSNwoEbmFtZRgBIAEoCUIj4EEC+kEdChtzcGFubmVyLmdvb2dsZWFw
aXMuY29tL1JvbGVSBG5hbWUy7AYKDFVzZXJzU2VydmljZRJpCgpDcmVhdGVVc2VyEikuZ29v
Z2xlLnNwYW5uZXIuYXV0aC52MS5DcmVhdGVVc2VyUmVxdWVzdBoqLmdvb2dsZS5zcGFubmVy
LmF1dGgudjEuQ3JlYXRlVXNlclJlc3BvbnNlIgAoATABEo8BCgpVcGRhdGVVc2VyEikuZ29v
Z2xlLnNwYW5uZXIuYXV0aC52MS5VcGRhdGVVc2VyUmVxdWVzdBocLmdvb2dsZS5zcGFubmVy
LmF1dGgudjEuVXNlciI4gtPkkwIfMhcvdjEve3VzZXIubmFtZT11c2Vycy8qfToEdXNlctpB
EHVzZXIsdXBkYXRlX21hc2sScgoHR2V0VXNlchImLmdvb2dsZS5zcGFubmVyLmF1dGgudjEu
R2V0VXNlclJlcXVlc3QaHC5nb29nbGUuc3Bhbm5lci5hdXRoLnYxLlVzZXIiIYLT5JMCFBIS
L3YxL3tuYW1lPXVzZXJzLyp92kEEbmFtZRJzCglMaXN0VXNlcnMSKC5nb29nbGUuc3Bhbm5l
ci5hdXRoLnYxLkxpc3RVc2Vyc1JlcXVlc3QaKS5nb29nbGUuc3Bhbm5lci5hdXRoLnYxLkxp
c3RVc2Vyc1Jlc3BvbnNlIhGC0+STAgsSCS92MS91c2VycxJyCgpEZWxldGVVc2VyEikuZ29v
Z2xlLnNwYW5uZXIuYXV0aC52MS5EZWxldGVVc2VyUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1
Zi5FbXB0eSIhgtPkkwIUKhIvdjEve25hbWU9dXNlcnMvKn3aQQRuYW1lEnMKCUxpc3RSb2xl
cxIoLmdvb2dsZS5zcGFubmVyLmF1dGgudjEuTGlzdFJvbGVzUmVxdWVzdBopLmdvb2dsZS5z
cGFubmVyLmF1dGgudjEuTGlzdFJvbGVzUmVzcG9uc2UiEYLT5JMCCxIJL3YxL3JvbGVzEnIK
B0dldFJvbGUSJi5nb29nbGUuc3Bhbm5lci5hdXRoLnYxLkdldFJvbGVSZXF1ZXN0GhwuZ29v
Z2xlLnNwYW5uZXIuYXV0aC52MS5Sb2xlIiGC0+STAhQSEi92MS97bmFtZT1yb2xlcy8qfdpB
BG5hbWUaGcpBFnNwYW5uZXIuZ29vZ2xlYXBpcy5jb21CyAEKGmNvbS5nb29nbGUuc3Bhbm5l
ci5hdXRoLnYxQhFTcGFubmVyVXNlcnNQcm90b1ABWjRjbG91ZC5nb29nbGUuY29tL2dvL3Nw
YW5uZXIvYXV0aC9hcGl2MS9hdXRocGI7YXV0aHBiqgIcR29vZ2xlLkNsb3VkLlNwYW5uZXIu
QXV0aC5WMcoCHEdvb2dsZVxDbG91ZFxTcGFubmVyXEF1dGhcVjHqAiBHb29nbGU6OkNsb3Vk
OjpTcGFubmVyOjpBdXRoOjpWMUq6RQoHEgUOAKECAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQA
KQoJCgIDAxIDFQAjCgkKAgMEEgMWACUKCQoCAwUSAxcAKgoJCgIDBhIDGAA1CggKAQgSAxoA
OQoJCgIIJRIDGgA5CggKAQgSAxsASwoJCgIICxIDGwBLCggKAQgSAxwAIgoJCgIIChIDHAAi
CggKAQgSAx0AMgoJCgIICBIDHQAyCggKAQgSAx4AMwoJCgIIARIDHgAzCggKAQgSAx8AOgoJ
CgIIKRIDHwA6CggKAQgSAyAAOQoJCgIILRIDIAA5CjoKAgYAEgQjAFgBGi4gUHJvdmlkZXMg
bWV0aG9kcyBmb3IgbWFuYWdpbmcgU3Bhbm5lciB1c2Vycy4KCgoKAwYAARIDIwgUCgoKAwYA
AxIDJAI+CgwKBQYAA5kIEgMkAj4KQQoEBgACABIEJwIoAxozIENyZWF0ZXMgYSBuZXcgdXNl
ciB1c2luZyB0aGUgcHJvdmlkZWQgY3JlZGVudGlhbC4KCgwKBQYAAgABEgMnBhAKDAoFBgAC
AAUSAycRFwoMCgUGAAIAAhIDJxgpCgwKBQYAAgAGEgMnNDoKDAoFBgACAAMSAyc7TQomCgQG
AAIBEgQrAjEDGhggVXBkYXRlcyBhIHNpbmdsZSB1c2VyLgoKDAoFBgACAQESAysGEAoMCgUG
AAIBAhIDKxEiCgwKBQYAAgEDEgMrLTEKDQoFBgACAQQSBCwELwYKEQoJBgACAQSwyrwiEgQs
BC8GCgwKBQYAAgEEEgMwBD4KDwoIBgACAQSbCAASAzAEPgovCgQGAAICEgQ0AjkDGiEgR2V0
cyBhIHNpbmdsZSB1c2VyIGJ5IHVzZXJuYW1lLgoKDAoFBgACAgESAzQGDQoMCgUGAAICAhID
NA4cCgwKBQYAAgIDEgM0JysKDQoFBgACAgQSBDUENwYKEQoJBgACAgSwyrwiEgQ1BDcGCgwK
BQYAAgIEEgM4BDIKDwoIBgACAgSbCAASAzgEMgouCgQGAAIDEgQ8AkADGiAgTGlzdHMgYWxs
IHVzZXJzIGluIHRoZSBzeXN0ZW0uCgoMCgUGAAIDARIDPAYPCgwKBQYAAgMCEgM8ECAKDAoF
BgACAwMSAzwrPAoNCgUGAAIDBBIEPQQ/BgoRCgkGAAIDBLDKvCISBD0EPwYKMgoEBgACBBIE
QwJIAxokIERlbGV0ZXMgYSBzaW5nbGUgdXNlciBieSB1c2VybmFtZS4KCgwKBQYAAgQBEgND
BhAKDAoFBgACBAISA0MRIgoMCgUGAAIEAxIDQy1CCg0KBQYAAgQEEgREBEYGChEKCQYAAgQE
sMq8IhIERARGBgoMCgUGAAIEBBIDRwQyCg8KCAYAAgQEmwgAEgNHBDIKPwoEBgACBRIESwJP
AxoxIExpc3RzIHRoZSByb2xlcyB0aGF0IGNhbiBiZSBhc3NpZ25lZCB0byBhIHVzZXIuCgoM
CgUGAAIFARIDSwYPCgwKBQYAAgUCEgNLECAKDAoFBgACBQMSA0srPAoNCgUGAAIFBBIETARO
BgoRCgkGAAIFBLDKvCISBEwETgYKKwoEBgACBhIEUgJXAxodIEdldHMgYSBzaW5nbGUgcm9s
ZSBieSBuYW1lLgoKDAoFBgACBgESA1IGDQoMCgUGAAIGAhIDUg4cCgwKBQYAAgYDEgNSJysK
DQoFBgACBgQSBFMEVQYKEQoJBgACBgSwyrwiEgRTBFUGCgwKBQYAAgYEEgNWBDIKDwoIBgAC
BgSbCAASA1YEMgqjAQoCBAASBVwAhAEBGpUBIEEgdXNlciBpbiB0aGUgc3lzdGVtLiAgVXNl
cnMgYXJlIGlkZW50aWZpZWQgYnkgdGhlaXIgdXNlcm5hbWUgYW5kIGNhbiBiZQogYXNzaWdu
ZWQgcm9sZXMgdGhhdCBncmFudCB0aGVtIHBlcm1pc3Npb25zIHRvIHBlcmZvcm0gYWN0aW9u
cyBpbiBTcGFubmVyLgoKCgoDBAABEgNcCAwKCwoDBAAHEgRdAmIECg0KBQQAB50IEgRdAmIE
CisKBAQABAASBGUCcQMaHSBQb3NzaWJsZSBzdGF0ZXMgZm9yIGEgdXNlci4KCgwKBQQABAAB
EgNlBwwKVgoGBAAEAAIAEgNnBBoaRyBUaGUgdXNlciBpcyBpbiBhbiB1bnNwZWNpZmllZCBz
dGF0ZSwgaXQgY2Fubm90IGJlIHVzZWQgaW4gdGhpcyBzdGF0ZS4KCg4KBwQABAACAAESA2cE
FQoOCgcEAAQAAgACEgNnGBkKQQoGBAAEAAIBEgNqBA8aMiBUaGUgdXNlciBpcyBhY3RpdmUg
YW5kIGNhbiBsb2cgaW4gdG8gdGhlIHN5c3RlbS4KCg4KBwQABAACAQESA2oECgoOCgcEAAQA
AgECEgNqDQ4KTAoGBAAEAAICEgNtBBEaPSBUaGUgdXNlciBpcyBiZWluZyBjcmVhdGVkLCBp
dCBjYW5ub3QgYmUgdXNlZCBpbiB0aGlzIHN0YXRlLgoKDgoHBAAEAAICARIDbQQMCg4KBwQA
BAACAgISA20PEApQCgYEAAQAAgMSA3AEFBpBIFRoZSB1c2VyIGhhcyBiZWVuIGRlYWN0aXZh
dGVkLCBpdCBjYW5ub3QgYmUgdXNlZCBpbiB0aGlzIHN0YXRlLgoKDgoHBAAEAAIDARIDcAQP
Cg4KBwQABAACAwISA3ASEwplCgQEAAIAEgN1Aj0aWCBJZGVudGlmaWVyLiBUaGUgbmFtZSBv
ZiB0aGUgdXNlciwgbXVzdCBiZSB1bmlxdWUuICBUaGUgZm9ybWF0IHNob3VsZCBiZQogdXNl
cnMve3VzZXJ9LgoKDAoFBAACAAUSA3UCCAoMCgUEAAIAARIDdQkNCgwKBQQAAgADEgN1EBEK
DAoFBAACAAgSA3USPAoPCggEAAIACJwIABIDdRM7CmkKBAQAAgESA3kCPhpcIFJlcXVpcmVk
LiBUaGUgaWQgb2YgdGhlIHVzZXIsIHRoaXMgaXMgdGhlIHBhcnQgYWZ0ZXIgdGhlIHVzZXJz
LyBwcmVmaXggaW4KIHRoZSBuYW1lIGZpZWxkLgoKDAoFBAACAQUSA3kCCAoMCgUEAAIBARID
eQkQCgwKBQQAAgEDEgN5ExQKDAoFBAACAQgSA3kVPQoPCggEAAIBCJwIABIDeRY8CjIKBAQA
AgISA3wCPholIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIHVzZXIuCgoMCgUEAAIC
BhIDfAIHCgwKBQQAAgIBEgN8CA0KDAoFBAACAgMSA3wQEQoMCgUEAAICCBIDfBI9Cg8KCAQA
AgIInAgAEgN8EzwKYAoEBAACAxIGgAECgwEEGlAgT3B0aW9uYWwuIFRoZSByb2xlcyBhc3Np
Z25lZCB0byB0aGUgdXNlci4gIFRoZSBmb3JtYXQgc2hvdWxkIGJlCiByb2xlcy97cm9sZX0u
CgoNCgUEAAIDBBIEgAECCgoNCgUEAAIDBRIEgAELEQoNCgUEAAIDARIEgAESFwoNCgUEAAID
AxIEgAEaGwoPCgUEAAIDCBIGgAEcgwEDChAKCAQAAgMInAgAEgSBAQQqCg8KBwQAAgMInwgS
BIIBBE0KagoCBAESBogBAJoBARpcIEEgcm9sZSB0aGF0IGdyYW50cyBwZXJtaXNzaW9ucyB0
byBwZXJmb3JtIGFjdGlvbnMgdG8gdXNlcnMgdGhhdCBhcmUgYXNzaWduZWQKIHRvIHRoZSBy
b2xlLgoKCwoDBAEBEgSIAQgMCg0KAwQBBxIGiQECjgEECg8KBQQBB50IEgaJAQKOAQQKVAoE
BAECABIEkQECPRpGIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSByb2xlLCB0aGUgZm9y
bWF0IHNob3VsZCBiZSByb2xlcy97cm9sZX0uCgoNCgUEAQIABRIEkQECCAoNCgUEAQIAARIE
kQEJDQoNCgUEAQIAAxIEkQEQEQoNCgUEAQIACBIEkQESPAoQCggEAQIACJwIABIEkQETOwpt
CgQEAQIBEgSVAQJBGl8gT3V0cHV0IG9ubHkuIFRoZSBpZCBvZiB0aGUgcm9sZSwgdGhpcyBp
cyB0aGUgcGFydCBhZnRlciB0aGUgcm9sZXMvIHByZWZpeAogaW4gdGhlIG5hbWUgZmllbGQu
CgoNCgUEAQIBBRIElQECCAoNCgUEAQIBARIElQEJEAoNCgUEAQIBAxIElQETFAoNCgUEAQIB
CBIElQEVQAoQCggEAQIBCJwIABIElQEWPwp0CgQEAQICEgSZAQJOGmYgT3V0cHV0IG9ubHku
IEFsbCB0aGUgcGVybWlzc2lvbnMgdGhhdCBhcmUgZ3JhbnRlZCB0byB0aGlzIHJvbGUsIHRo
aXMgaXMgbm90CiByZXR1cm5lZCBpbiBMaXN0IGNhbGxzLgoKDQoFBAECAgQSBJkBAgoKDQoF
BAECAgUSBJkBCxEKDQoFBAECAgESBJkBEh0KDQoFBAECAgMSBJkBICEKDQoFBAECAggSBJkB
Ik0KEAoIBAECAgicCAASBJkBI0wKjgMKAgQCEgaiAQC1AQEa/wIgQSByZXF1ZXN0IHRvIGNy
ZWF0ZSBhIG5ldyB1c2VyLiAgTmV3IHVzZXJzIGFyZSBjcmVhdGVkIGluIHRocmVlIHN0ZXBz
OgogMS4gVGhlIGZpcnN0IHN0ZXAgaXMgYSBoYW5kc2hha2UgcmVxdWVzdCB0byBkZXRlcm1p
bmUgaG93IHRoZSBjbGllbnQgc2hvdWxkCiAgICBhdXRoZW50aWNhdGUuCiAyLiBUaGUgc2Vj
b25kIHN0ZXAgaXMgdG8gaW5pdGlhdGUgdGhlIGNyZWF0aW9uIG9mIGEgbmV3IHVzZXIsIHdo
aWNoIHJldHVybnMKICAgIGluZm9ybWF0aW9uIHRoZSBjbGllbnQgdXNlcyB0byBnZW5lcmF0
ZSB0aGUgY29ycmVjdCB0eXBlIG9mIGNyZWRlbnRpYWwuCiAzLiBUaGUgZmluYWwgc3RlcCBp
cyB0byBjcmVhdGUgdGhlIHVzZXIgdXNpbmcgdGhlIGNyZWRlbnRpYWwuCgoLCgMEAgESBKIB
CBkKTgoEBAICABIEpAECORpAIFJlcXVpcmVkLiBUaGUgbmV3IHVzZXIgdG8gY3JlYXRlLCB0
aGUgdXNlcm5hbWUgbXVzdCBiZSB1bmlxdWUuCgoNCgUEAgIABhIEpAECBgoNCgUEAgIAARIE
pAEHCwoNCgUEAgIAAxIEpAEODwoNCgUEAgIACBIEpAEQOAoQCggEAgIACJwIABIEpAERNwpP
CgQEAggAEganAQK0AQMaPyBVc2VycyBjYW4gYmUgY3JlYXRlZCB3aXRoIGVpdGhlciBTQ1JB
TSBvciBPUEFRVUUgY3JlZGVudGlhbHMuCgoNCgUEAggAARIEpwEIDwpGCgQEAgIBEgapAQSq
ATEaNiBPcHRpb25hbC4gVGhlIFNDUkFNIHJlcXVlc3QgZm9yIGNyZWF0aW5nIGEgbmV3IHVz
ZXIuCgoNCgUEAgIBBhIEqQEEHQoNCgUEAgIBARIEqQEeKwoNCgUEAgIBAxIEqQEuLwoNCgUE
AgIBCBIEqgEIMAoQCggEAgIBCJwIABIEqgEJLwpHCgQEAgICEgatAQSuATEaNyBPcHRpb25h
bC4gVGhlIE9QQVFVRSByZXF1ZXN0IGZvciBjcmVhdGluZyBhIG5ldyB1c2VyLgoKDQoFBAIC
AgYSBK0BBB4KDQoFBAICAgESBK0BHy0KDQoFBAICAgMSBK0BMDEKDQoFBAICAggSBK4BCDAK
EAoIBAICAgicCAASBK4BCS8KXwoEBAICAxIGsgEEswExGk8gT3B0aW9uYWwuIEhhbmRzaGFr
ZSByZXF1ZXN0IGZvciB0aGUgY2xpZW50IHRvIGRldGVybWluZSBob3cgdG8KIGF1dGhlbnRp
Y2F0ZS4KCg0KBQQCAgMGEgSyAQQqCg0KBQQCAgMBEgSyASs8Cg0KBQQCAgMDEgSyAT9ACg0K
BQQCAgMIEgSzAQgwChAKCAQCAgMInAgAEgSzAQkvCl8KAgQDEga5AQDJAQEaUSBUaGUgcmVz
cG9uc2UgZm9yCiBbQ3JlYXRlVXNlcl1bZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5Vc2Vyc1Nl
cnZpY2UuQ3JlYXRlVXNlcl0uCgoLCgMEAwESBLkBCBoKaAoEBAMCABIEvAECEBpaIFRoZSB1
c2VyIHRoYXQgd2FzIGNyZWF0ZWQsIHRoaXMgd2lsbCBvbmx5IGJlIHNldCBvbiB0aGUgZmlu
YWwgcmVzcG9uc2UKIGZyb20gdGhlIHNlcnZlci4KCg0KBQQDAgAGEgS8AQIGCg0KBQQDAgAB
EgS8AQcLCg0KBQQDAgADEgS8AQ4PCjEKBAQDCAASBr8BAsgBAxohIFRoZSByZXNwb25zZSBm
b3IgdXNlciBjcmVhdGlvbi4KCg0KBQQDCAABEgS/AQgQCjsKBAQDAgESBMEBBDIaLSBUaGUg
U0NSQU0gcmVzcG9uc2UgZm9yIGNyZWF0aW5nIGEgbmV3IHVzZXIuCgoNCgUEAwIBBhIEwQEE
HgoNCgUEAwIBARIEwQEfLQoNCgUEAwIBAxIEwQEwMQo8CgQEAwICEgTEAQQ0Gi4gVGhlIE9Q
QVFVRSByZXNwb25zZSBmb3IgY3JlYXRpbmcgYSBuZXcgdXNlci4KCg0KBQQDAgIGEgTEAQQf
Cg0KBQQDAgIBEgTEASAvCg0KBQQDAgIDEgTEATIzClMKBAQDAgMSBMcBBEMaRSBIYW5kc2hh
a2UgcmVzcG9uc2UgZm9yIHRoZSBzZXJ2ZXIgdG8gZGV0ZXJtaW5lIGhvdyB0byBhdXRoZW50
aWNhdGUuCgoNCgUEAwIDBhIExwEEKwoNCgUEAwIDARIExwEsPgoNCgUEAwIDAxIExwFBQgoy
CgIEBBIGzAEA0wEBGiQgQSByZXF1ZXN0IHRvIHVwZGF0ZSBhIHNpbmdsZSB1c2VyLgoKCwoD
BAQBEgTMAQgZCi0KBAQEAgASBM4BAjkaHyBSZXF1aXJlZC4gVGhlIHVzZXIgdG8gdXBkYXRl
LgoKDQoFBAQCAAYSBM4BAgYKDQoFBAQCAAESBM4BBwsKDQoFBAQCAAMSBM4BDg8KDQoFBAQC
AAgSBM4BEDgKEAoIBAQCAAicCAASBM4BETcKOQoEBAQCARIG0QEC0gEvGikgT3B0aW9uYWwu
IFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCgoNCgUEBAIBBhIE0QECGwoNCgUEBAIB
ARIE0QEcJwoNCgUEBAIBAxIE0QEqKwoNCgUEBAIBCBIE0gEGLgoQCggEBAIBCJwIABIE0gEH
LQoqCgIEBRIG1gEA3QEBGhwgUmVxdWVzdCBmb3IgYSBzaW5nbGUgdXNlci4KCgsKAwQFARIE
1gEIFgpnCgQEBQIAEgbZAQLcAQQaVyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHVzZXIg
dG8gZ2V0LCB0aGlzIHNob3VsZCBiZSBpbiB0aGUgZm9ybWF0IG9mCiB1c2Vycy97dXNlcn0u
CgoNCgUEBQIABRIE2QECCAoNCgUEBQIAARIE2QEJDQoNCgUEBQIAAxIE2QEQEQoPCgUEBQIA
CBIG2QES3AEDChAKCAQFAgAInAgAEgTaAQQqCg8KBwQFAgAInwgSBNsBBE0KJgoCBAYSBuAB
AOoBARoYIFJlcXVlc3QgZm9yIGFsbCB1c2Vycy4KCgsKAwQGARIE4AEIGAp/CgQEBgIAEgTj
AQI/GnEgT3B0aW9uYWwuIE51bWJlciBvZiB1c2VycyB0byByZXR1cm4gaW4gdGhlIHJlc3Bv
bnNlLiBJZiAwLCBkZWZhdWx0cyB0bwogdGhlIHNlcnZlcidzIG1heGltdW0gYWxsb3dlZCBw
YWdlIHNpemUuCgoNCgUEBgIABRIE4wECBwoNCgUEBgIAARIE4wEIEQoNCgUEBgIAAxIE4wEU
FQoNCgUEBgIACBIE4wEWPgoQCggEBgIACJwIABIE4wEXPQrkAQoEBAYCARIE6QECQRrVASBP
cHRpb25hbC4gSWYgbm9uLWVtcHR5LCBgcGFnZV90b2tlbmAgc2hvdWxkIGNvbnRhaW4gYQog
W25leHRfcGFnZV90b2tlbl1bZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5MaXN0VXNlcnNSZXNw
b25zZS5uZXh0X3BhZ2VfdG9rZW5dCiBmcm9tIGEgcHJldmlvdXMKIFtMaXN0VXNlcnNSZXNw
b25zZV1bZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5MaXN0VXNlcnNSZXNwb25zZV0uCgoNCgUE
BgIBBRIE6QECCAoNCgUEBgIBARIE6QEJEwoNCgUEBgIBAxIE6QEWFwoNCgUEBgIBCBIE6QEY
QAoQCggEBgIBCJwIABIE6QEZPwovCgIEBxIG7QEA9QEBGiEgVGhlIHJlc3BvbnNlIHRvIGxp
c3QgYWxsIHVzZXJzLgoKCwoDBAcBEgTtAQgZCiIKBAQHAgASBO8BAhoaFCBUaGUgbGlzdCBv
ZiB1c2Vycy4KCg0KBQQHAgAEEgTvAQIKCg0KBQQHAgAGEgTvAQsPCg0KBQQHAgABEgTvARAV
Cg0KBQQHAgADEgTvARgZCqUBCgQEBwIBEgT0AQIdGpYBIGBuZXh0X3BhZ2VfdG9rZW5gIGNh
biBiZSBzZW50IGluIGEgc3Vic2VxdWVudAogW0xpc3RVc2Vyc11bZ29vZ2xlLnNwYW5uZXIu
YXV0aC52MS5Vc2Vyc1NlcnZpY2UuTGlzdFVzZXJzXSBjYWxsIHRvIGZldGNoCiBtb3JlIG9m
IHRoZSBtYXRjaGluZyB1c2Vycy4KCg0KBQQHAgEFEgT0AQIICg0KBQQHAgEBEgT0AQkYCg0K
BQQHAgEDEgT0ARscCjAKAgQIEgb4AQD/AQEaIiBSZXF1ZXN0IHRvIGRlbGV0ZSBhIHNpbmds
ZSB1c2VyLgoKCwoDBAgBEgT4AQgZCmoKBAQIAgASBvsBAv4BBBpaIFJlcXVpcmVkLiBUaGUg
bmFtZSBvZiB0aGUgdXNlciB0byBkZWxldGUsIHRoaXMgc2hvdWxkIGJlIGluIHRoZSBmb3Jt
YXQgb2YKIHVzZXJzL3t1c2VyfS4KCg0KBQQIAgAFEgT7AQIICg0KBQQIAgABEgT7AQkNCg0K
BQQIAgADEgT7ARARCg8KBQQIAgAIEgb7ARL+AQMKEAoIBAgCAAicCAASBPwBBCoKDwoHBAgC
AAifCBIE/QEETQo2CgIECRIGggIAjAIBGiggQSByZXF1ZXN0IHRvIGxpc3QgYWxsIGF2YWls
YWJsZSByb2xlcy4KCgsKAwQJARIEggIIGAp/CgQECQIAEgSFAgI/GnEgT3B0aW9uYWwuIE51
bWJlciBvZiByb2xlcyB0byByZXR1cm4gaW4gdGhlIHJlc3BvbnNlLiBJZiAwLCBkZWZhdWx0
cwogdG8gdGhlIHNlcnZlcidzIG1heGltdW0gYWxsb3dlZCBwYWdlIHNpemUuCgoNCgUECQIA
BRIEhQICBwoNCgUECQIAARIEhQIIEQoNCgUECQIAAxIEhQIUFQoNCgUECQIACBIEhQIWPgoQ
CggECQIACJwIABIEhQIXPQrkAQoEBAkCARIEiwICQRrVASBPcHRpb25hbC4gSWYgbm9uLWVt
cHR5LCBgcGFnZV90b2tlbmAgc2hvdWxkIGNvbnRhaW4gYQogW25leHRfcGFnZV90b2tlbl1b
Z29vZ2xlLnNwYW5uZXIuYXV0aC52MS5MaXN0Um9sZXNSZXNwb25zZS5uZXh0X3BhZ2VfdG9r
ZW5dCiBmcm9tIGEgcHJldmlvdXMKIFtMaXN0Um9sZXNSZXNwb25zZV1bZ29vZ2xlLnNwYW5u
ZXIuYXV0aC52MS5MaXN0Um9sZXNSZXNwb25zZV0uCgoNCgUECQIBBRIEiwICCAoNCgUECQIB
ARIEiwIJEwoNCgUECQIBAxIEiwIWFwoNCgUECQIBCBIEiwIYQAoQCggECQIBCJwIABIEiwIZ
Pwo5CgIEChIGjwIAlwIBGisgVGhlIHJlc3BvbnNlIHRvIGxpc3QgYWxsIGF2YWlsYWJsZSBy
b2xlcy4KCgsKAwQKARIEjwIIGQoiCgQECgIAEgSRAgIaGhQgVGhlIGxpc3Qgb2Ygcm9sZXMu
CgoNCgUECgIABBIEkQICCgoNCgUECgIABhIEkQILDwoNCgUECgIAARIEkQIQFQoNCgUECgIA
AxIEkQIYGQqlAQoEBAoCARIElgICHRqWASBgbmV4dF9wYWdlX3Rva2VuYCBjYW4gYmUgc2Vu
dCBpbiBhIHN1YnNlcXVlbnQKIFtMaXN0Um9sZXNdW2dvb2dsZS5zcGFubmVyLmF1dGgudjEu
VXNlcnNTZXJ2aWNlLkxpc3RSb2xlc10gY2FsbCB0byBmZXRjaAogbW9yZSBvZiB0aGUgbWF0
Y2hpbmcgcm9sZXMuCgoNCgUECgIBBRIElgICCAoNCgUECgIBARIElgIJGAoNCgUECgIBAxIE
lgIbHAo3CgIECxIGmgIAoQIBGikgQSByZXF1ZXN0IHRvIGdldCBhIHNpbmdsZSByb2xlIGJ5
IG5hbWUuCgoLCgMECwESBJoCCBYKYwoEBAsCABIGnQICoAIEGlMgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSByb2xlIHRvIGdldC4gIFNob3VsZCBiZSBpbiB0aGUgZm9ybWF0IG9mCiBy
b2xlcy97cm9sZX0uCgoNCgUECwIABRIEnQICCAoNCgUECwIAARIEnQIJDQoNCgUECwIAAxIE
nQIQEQoPCgUECwIACBIGnQISoAIDChAKCAQLAgAInAgAEgSeAgQqCg8KBwQLAgAInwgSBJ8C
BE1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::Auth::V1::SpannerUsers::User ===
    # Fields for User
    # Field: name Type: 9 ()
    # Field: user_id Type: 9 ()
    # Field: state Type: 14 (.google.spanner.auth.v1.User.State)
    # Field: roles Type: 9 ()

# Enum: User::State
our $User_STATE_UNSPECIFIED = 0;
our $User_ACTIVE = 1;
our $User_CREATING = 2;
our $User_DEACTIVATED = 3;

# === Message: Google::Spanner::Auth::V1::SpannerUsers::Role ===
    # Fields for Role
    # Field: name Type: 9 ()
    # Field: role_id Type: 9 ()
    # Field: permissions Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest ===
    # Fields for CreateUserRequest
    # Field: user Type: 11 (.google.spanner.auth.v1.User)
    # Field: scram_request Type: 11 (.google.spanner.auth.v1.ScramNewCredentialRequest)
    # Field: opaque_request Type: 11 (.google.spanner.auth.v1.OpaqueNewCredentialRequest)
    # Field: handshake_request Type: 11 (.google.spanner.auth.v1.PasswordAuthenticationHandshakeRequest)

# === Message: Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse ===
    # Fields for CreateUserResponse
    # Field: user Type: 11 (.google.spanner.auth.v1.User)
    # Field: scram_response Type: 11 (.google.spanner.auth.v1.ScramNewCredentialResponse)
    # Field: opaque_response Type: 11 (.google.spanner.auth.v1.OpaqueNewCredentialResponse)
    # Field: handshake_response Type: 11 (.google.spanner.auth.v1.PasswordAuthenticationHandshakeResponse)

# === Message: Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest ===
    # Fields for UpdateUserRequest
    # Field: user Type: 11 (.google.spanner.auth.v1.User)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest ===
    # Fields for GetUserRequest
    # Field: name Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest ===
    # Fields for ListUsersRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse ===
    # Fields for ListUsersResponse
    # Field: users Type: 11 (.google.spanner.auth.v1.User)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest ===
    # Fields for DeleteUserRequest
    # Field: name Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest ===
    # Fields for ListRolesRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse ===
    # Fields for ListRolesResponse
    # Field: roles Type: 11 (.google.spanner.auth.v1.Role)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest ===
    # Fields for GetRoleRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Spanner::Auth::V1::SpannerUsers::UsersServiceClient ===
package Google::Spanner::Auth::V1::SpannerUsers::UsersServiceClient;

=pod

=head2 Service Client: Google::Spanner::Auth::V1::SpannerUsers::UsersServiceClient

Client stub representing the remote C<UsersService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<spanner.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'spanner.googleapis.com:443' );

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

sub create_user {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'CreateUser',
        request        => $req,
        response_class => 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse',
    });
}

sub update_user {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'UpdateUser',
        request        => $req,
        response_class => 'Google::Spanner::Auth::V1::SpannerUsers::User',
    });
}

sub get_user {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'GetUser',
        request        => $req,
        response_class => 'Google::Spanner::Auth::V1::SpannerUsers::User',
    });
}

sub list_users {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'ListUsers',
        request        => $req,
        response_class => 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse',
    });
}

sub delete_user {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'DeleteUser',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_roles {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'ListRoles',
        request        => $req,
        response_class => 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse',
    });
}

sub get_role {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'GetRole',
        request        => $req,
        response_class => 'Google::Spanner::Auth::V1::SpannerUsers::Role',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::Auth::V1::SpannerUsers - Compiled Protocol Buffers messages for google/spanner/auth/v1/spanner_users.proto

=head1 SYNOPSIS

    use Google::Spanner::Auth::V1::SpannerUsers;

    my $msg = Google::Spanner::Auth::V1::SpannerUsers::User->new({
        name => $name,
        user_id => $user_id,
        state => $state,
        roles => $roles,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::Auth::V1::SpannerUsers::User->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/auth/v1/spanner_users.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::Auth::V1::SpannerUsers::User

A user in the system.  Users are identified by their username and can be
assigned roles that grant them permissions to perform actions in Spanner.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the user, must be unique.  The format should be
users/{user}.

=item * C<< $msg->user_id() >> / C<< $msg->user_id($value) >>

Type: C<String>

Required. The id of the user, this is the part after the users/ prefix in
the name field.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Spanner::Auth::V1::User::State>)

Output only. The state of the user.

=item * C<< $msg->roles() >> / C<< $msg->roles($value) >>

Type: C<String>

Optional. The roles assigned to the user.  The format should be
roles/{role}.

=back

=head3 Enum: User::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<CREATING> => C<2>

=item * C<DEACTIVATED> => C<3>

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::Role

A role that grants permissions to perform actions to users that are assigned
to the role.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the role, the format should be roles/{role}.

=item * C<< $msg->role_id() >> / C<< $msg->role_id($value) >>

Type: C<String>

Output only. The id of the role, this is the part after the roles/ prefix
in the name field.

=item * C<< $msg->permissions() >> / C<< $msg->permissions($value) >>

Type: C<String>

Output only. All the permissions that are granted to this role, this is not
returned in List calls.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest

A request to create a new user.  New users are created in three steps:
1. The first step is a handshake request to determine how the client should
   authenticate.
2. The second step is to initiate the creation of a new user, which returns
   information the client uses to generate the correct type of credential.
3. The final step is to create the user using the credential.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user() >> / C<< $msg->user($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::SpannerUsers::User>)

Required. The new user to create, the username must be unique.

=item * C<< $msg->scram_request() >> / C<< $msg->scram_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest>)

Optional. The SCRAM request for creating a new user.

=item * C<< $msg->opaque_request() >> / C<< $msg->opaque_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest>)

Optional. The OPAQUE request for creating a new user.

=item * C<< $msg->handshake_request() >> / C<< $msg->handshake_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeRequest>)

Optional. Handshake request for the client to determine how to
authenticate.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse

The response for
[CreateUser][google.spanner.auth.v1.UsersService.CreateUser].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user() >> / C<< $msg->user($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::SpannerUsers::User>)

The user that was created, this will only be set on the final response
from the server.

=item * C<< $msg->scram_response() >> / C<< $msg->scram_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse>)

The SCRAM response for creating a new user.

=item * C<< $msg->opaque_response() >> / C<< $msg->opaque_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse>)

The OPAQUE response for creating a new user.

=item * C<< $msg->handshake_response() >> / C<< $msg->handshake_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeResponse>)

Handshake response for the server to determine how to authenticate.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest

A request to update a single user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user() >> / C<< $msg->user($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::SpannerUsers::User>)

Required. The user to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest

Request for a single user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the user to get, this should be in the format of
users/{user}.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest

Request for all users.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Number of users to return in the response. If 0, defaults to
the server's maximum allowed page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If non-empty, `page_token` should contain a
[next_page_token][google.spanner.auth.v1.ListUsersResponse.next_page_token]
from a previous
[ListUsersResponse][google.spanner.auth.v1.ListUsersResponse].

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse

The response to list all users.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->users() >> / C<< $msg->users($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::SpannerUsers::User>)

The list of users.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

`next_page_token` can be sent in a subsequent
[ListUsers][google.spanner.auth.v1.UsersService.ListUsers] call to fetch
more of the matching users.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest

Request to delete a single user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the user to delete, this should be in the format of
users/{user}.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest

A request to list all available roles.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Number of roles to return in the response. If 0, defaults
to the server's maximum allowed page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If non-empty, `page_token` should contain a
[next_page_token][google.spanner.auth.v1.ListRolesResponse.next_page_token]
from a previous
[ListRolesResponse][google.spanner.auth.v1.ListRolesResponse].

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse

The response to list all available roles.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->roles() >> / C<< $msg->roles($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::SpannerUsers::Role>)

The list of roles.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

`next_page_token` can be sent in a subsequent
[ListRoles][google.spanner.auth.v1.UsersService.ListRoles] call to fetch
more of the matching roles.

=back

=head2 Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest

A request to get a single role by name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the role to get.  Should be in the format of
roles/{role}.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::Auth::V1::SpannerUsers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
