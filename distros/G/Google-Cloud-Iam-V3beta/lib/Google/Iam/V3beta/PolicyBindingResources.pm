package Google::Iam::V3beta::PolicyBindingResources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvaWFtL3YzYmV0YS9wb2xpY3lfYmluZGluZ19yZXNvdXJjZXMucHJvdG8SEWdv
b2dsZS5pYW0udjNiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29n
bGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aFmdvb2dsZS90eXBlL2V4cHIucHJvdG8i
oAkKDVBvbGljeUJpbmRpbmcSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEh0KA3VpZBgCIAEo
CUIL4ozP1wgCCAHgQQNSA3VpZBIXCgRldGFnGAMgASgJQgPgQQFSBGV0YWcSJgoMZGlzcGxh
eV9uYW1lGAQgASgJQgPgQQFSC2Rpc3BsYXlOYW1lElgKC2Fubm90YXRpb25zGAUgAygLMjEu
Z29vZ2xlLmlhbS52M2JldGEuUG9saWN5QmluZGluZy5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFS
C2Fubm90YXRpb25zEkcKBnRhcmdldBgGIAEoCzInLmdvb2dsZS5pYW0udjNiZXRhLlBvbGlj
eUJpbmRpbmcuVGFyZ2V0QgbgQQXgQQJSBnRhcmdldBJRCgtwb2xpY3lfa2luZBgLIAEoDjIr
Lmdvb2dsZS5pYW0udjNiZXRhLlBvbGljeUJpbmRpbmcuUG9saWN5S2luZEID4EEFUgpwb2xp
Y3lLaW5kEh4KBnBvbGljeRgHIAEoCUIG4EEF4EECUgZwb2xpY3kSIgoKcG9saWN5X3VpZBgM
IAEoCUID4EEDUglwb2xpY3lVaWQSNAoJY29uZGl0aW9uGAggASgLMhEuZ29vZ2xlLnR5cGUu
RXhwckID4EEBUgljb25kaXRpb24SQAoLY3JlYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCiABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUaYQoGVGFyZ2V0
EioKDXByaW5jaXBhbF9zZXQYASABKAlCA+BBBUgAUgxwcmluY2lwYWxTZXQSIQoIcmVzb3Vy
Y2UYAiABKAlCA+BBBUgAUghyZXNvdXJjZUIICgZ0YXJnZXQaPgoQQW5ub3RhdGlvbnNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIlQKClBvbGlj
eUtpbmQSGwoXUE9MSUNZX0tJTkRfVU5TUEVDSUZJRUQQABIdChlQUklOQ0lQQUxfQUNDRVNT
X0JPVU5EQVJZEAESCgoGQUNDRVNTEAI6qALqQaQCCiBpYW0uZ29vZ2xlYXBpcy5jb20vUG9s
aWN5QmluZGluZxJRb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9saWN5X2JpbmRpbmd9EkVmb2xkZXJzL3tmb2xk
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L3BvbGljeUJpbmRpbmdzL3twb2xpY3lfYmluZGlu
Z30SR3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5k
aW5ncy97cG9saWN5X2JpbmRpbmd9Kg5wb2xpY3lCaW5kaW5nczINcG9saWN5QmluZGluZ0KZ
AQoVY29tLmdvb2dsZS5pYW0udjNiZXRhQhtQb2xpY3lCaW5kaW5nUmVzb3VyY2VzUHJvdG9Q
AVotY2xvdWQuZ29vZ2xlLmNvbS9nby9pYW0vYXBpdjNiZXRhL2lhbXBiO2lhbXBiqgIXR29v
Z2xlLkNsb3VkLklhbS5WM0JldGHKAhdHb29nbGVcQ2xvdWRcSWFtXFYzYmV0YUrKOgoHEgUO
AMoBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAGgoJCgID
ABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQApCgkKAgMEEgMWACAKCAoB
CBIDGAA0CgkKAgglEgMYADQKCAoBCBIDGQBECgkKAggLEgMZAEQKCAoBCBIDGgAiCgkKAggK
EgMaACIKCAoBCBIDGwA8CgkKAggIEgMbADwKCAoBCBIDHAAuCgkKAggBEgMcAC4KCAoBCBID
HQA0CgkKAggpEgMdADQKKwoCBAASBSAAygEBGh4gSUFNIHBvbGljeSBiaW5kaW5nIHJlc291
cmNlLgoKCgoDBAABEgMgCBUKCwoDBAAHEgQhAigECg0KBQQAB50IEgQhAigECm4KBAQAAwAS
BCwCVQMaYCBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSByZXNvdXJjZSB0byB3aGlj
aCB0aGUgcG9saWN5IHdpbGwKIGJlIGJvdW5kLiBJbW11dGFibGUgb25jZSBzZXQuCgoMCgUE
AAMAARIDLAoQCk8KBgQAAwAIABIELgRUBRo/IFRoZSBkaWZmZXJlbnQgdHlwZXMgb2YgdGFy
Z2V0cyB0aGF0IGNhbiBiZSBib3VuZCB0byBhIHBvbGljeS4KCg4KBwQAAwAIAAESAy4KEAq1
CAoGBAADAAIAEgNGBkkapQggSW1tdXRhYmxlLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIHRo
YXQncyB1c2VkIGZvciBwcmluY2lwYWwgYWNjZXNzCiBib3VuZGFyeSBwb2xpY3kgYmluZGlu
Z3MuIFRoZSBwcmluY2lwYWwgc2V0IG11c3QgYmUgZGlyZWN0bHkgcGFyZW50ZWQKIGJ5IHRo
ZSBwb2xpY3kgYmluZGluZydzIHBhcmVudCBvciBzYW1lIGFzIHRoZSBwYXJlbnQgaWYgdGhl
IHRhcmdldCBpcyBhCiBwcm9qZWN0LCBmb2xkZXIsIG9yIG9yZ2FuaXphdGlvbi4KCiBFeGFt
cGxlczoKCiAqIEZvciBiaW5kaW5ncyBwYXJlbnRlZCBieSBhbiBvcmdhbml6YXRpb246CiAg
ICAgKiBPcmdhbml6YXRpb246CiAgICAgYC8vY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xl
YXBpcy5jb20vb3JnYW5pemF0aW9ucy9PUkdBTklaQVRJT05fSURgCiAgICAgKiBXb3JrZm9y
Y2UgSWRlbnRpdHk6CiAgICAgYC8vaWFtLmdvb2dsZWFwaXMuY29tL2xvY2F0aW9ucy9nbG9i
YWwvd29ya2ZvcmNlUG9vbHMvV09SS0ZPUkNFX1BPT0xfSURgCiAgICAgKiBXb3Jrc3BhY2Ug
SWRlbnRpdHk6CiAgICAgYC8vaWFtLmdvb2dsZWFwaXMuY29tL2xvY2F0aW9ucy9nbG9iYWwv
d29ya3NwYWNlL1dPUktTUEFDRV9JRGAKICogRm9yIGJpbmRpbmdzIHBhcmVudGVkIGJ5IGEg
Zm9sZGVyOgogICAgICogRm9sZGVyOgogICAgICAgYC8vY2xvdWRyZXNvdXJjZW1hbmFnZXIu
Z29vZ2xlYXBpcy5jb20vZm9sZGVycy9GT0xERVJfSURgCiAqIEZvciBiaW5kaW5ncyBwYXJl
bnRlZCBieSBhIHByb2plY3Q6CiAgICAgKiBQcm9qZWN0OgogICAgICAgICAqIGAvL2Nsb3Vk
cmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL1BST0pFQ1RfTlVNQkVS
YAogICAgICAgICAqIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL3By
b2plY3RzL1BST0pFQ1RfSURgCiAgICAgKiBXb3JrbG9hZCBJZGVudGl0eSBQb29sOgogICAg
IGAvL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9QUk9KRUNUX05VTUJFUi9sb2NhdGlv
bnMvTE9DQVRJT04vd29ya2xvYWRJZGVudGl0eVBvb2xzL1dPUktMT0FEX1BPT0xfSURgCgoO
CgcEAAMAAgAFEgNGBgwKDgoHBAADAAIAARIDRg0aCg4KBwQAAwACAAMSA0YdHgoOCgcEAAMA
AgAIEgNGH0gKEQoKBAADAAIACJwIABIDRiBHCpwDCgYEAAMAAgESA1MGRBqMAyBJbW11dGFi
bGUuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgdGhhdCdzIHVzZWQgZm9yIGFjY2VzcyBwb2xp
Y3kKIGJpbmRpbmdzLgoKIEV4YW1wbGVzOgoKICogT3JnYW5pemF0aW9uOgogYC8vY2xvdWRy
ZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vb3JnYW5pemF0aW9ucy9PUkdBTklaQVRJ
T05fSURgCiAqIEZvbGRlcjogYC8vY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5j
b20vZm9sZGVycy9GT0xERVJfSURgCiAqIFByb2plY3Q6CiAgICAgKiBgLy9jbG91ZHJlc291
cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9QUk9KRUNUX05VTUJFUmAKICAg
ICAqIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL1BS
T0pFQ1RfSURgCgoOCgcEAAMAAgEFEgNTBgwKDgoHBAADAAIBARIDUw0VCg4KBwQAAwACAQMS
A1MYGQoOCgcEAAMAAgEIEgNTGkMKEQoKBAADAAIBCJwIABIDUxtCCkUKBAQABAASBFgCYQMa
NyBUaGUgZGlmZmVyZW50IHBvbGljeSBraW5kcyBzdXBwb3J0ZWQgaW4gdGhpcyBiaW5kaW5n
LgoKDAoFBAAEAAESA1gHEQo7CgYEAAQAAgASA1oEIBosIFVuc3BlY2lmaWVkIHBvbGljeSBr
aW5kOyBOb3QgYSB2YWxpZCBzdGF0ZQoKDgoHBAAEAAIAARIDWgQbCg4KBwQABAACAAISA1oe
Hwo2CgYEAAQAAgESA10EIhonIFByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5IGtp
bmQKCg4KBwQABAACAQESA10EHQoOCgcEAAQAAgECEgNdICEKJAoGBAAEAAICEgNgBA8aFSBB
Y2Nlc3MgcG9saWN5IGtpbmQuCgoOCgcEAAQAAgIBEgNgBAoKDgoHBAAEAAICAhIDYA0OCvAE
CgQEAAIAEgNuAj0a4gQgSWRlbnRpZmllci4gVGhlIG5hbWUgb2YgdGhlIHBvbGljeSBiaW5k
aW5nLCBpbiB0aGUgZm9ybWF0CiBge2JpbmRpbmdfcGFyZW50L2xvY2F0aW9ucy97bG9jYXRp
b259L3BvbGljeUJpbmRpbmdzL3twb2xpY3lfYmluZGluZ19pZH1gLgogVGhlIGJpbmRpbmcg
cGFyZW50IGlzIHRoZSBjbG9zZXN0IFJlc291cmNlIE1hbmFnZXIgcmVzb3VyY2UgKHByb2pl
Y3QsCiBmb2xkZXIsIG9yIG9yZ2FuaXphdGlvbikgdG8gdGhlIGJpbmRpbmcgdGFyZ2V0LgoK
IEZvcm1hdDoKCiAqIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKICogYHByb2plY3RzL3tw
cm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3Bv
bGljeV9iaW5kaW5nX2lkfWAKICogYGZvbGRlcnMve2ZvbGRlcl9pZH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKICogYG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5
QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKCgwKBQQAAgAFEgNuAggKDAoFBAACAAES
A24JDQoMCgUEAAIAAxIDbhARCgwKBQQAAgAIEgNuEjwKDwoIBAACAAicCAASA24TOwp4CgQE
AAIBEgRyAnUEGmogT3V0cHV0IG9ubHkuIFRoZSBnbG9iYWxseSB1bmlxdWUgSUQgb2YgdGhl
IHBvbGljeSBiaW5kaW5nLiBBc3NpZ25lZCB3aGVuCiB0aGUgcG9saWN5IGJpbmRpbmcgaXMg
Y3JlYXRlZC4KCgwKBQQAAgEFEgNyAggKDAoFBAACAQESA3IJDAoMCgUEAAIBAxIDcg8QCg0K
BQQAAgEIEgRyEXUDChIKCwQAAgEIzPH5igEBEgNzBCoKDwoIBAACAQicCAASA3QELQp6CgQE
AAICEgN5AjsabSBPcHRpb25hbC4gVGhlIGV0YWcgZm9yIHRoZSBwb2xpY3kgYmluZGluZy4K
IElmIHRoaXMgaXMgcHJvdmlkZWQgb24gdXBkYXRlLCBpdCBtdXN0IG1hdGNoIHRoZSBzZXJ2
ZXIncyBldGFnLgoKDAoFBAACAgUSA3kCCAoMCgUEAAICARIDeQkNCgwKBQQAAgIDEgN5EBEK
DAoFBAACAggSA3kSOgoPCggEAAICCJwIABIDeRM5Cm0KBAQAAgMSA30CQxpgIE9wdGlvbmFs
LiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIHBvbGljeSBiaW5kaW5nLiBNdXN0IGJlIGxlc3Mg
dGhhbiBvciBlcXVhbAogdG8gNjMgY2hhcmFjdGVycy4KCgwKBQQAAgMFEgN9AggKDAoFBAAC
AwESA30JFQoMCgUEAAIDAxIDfRgZCgwKBQQAAgMIEgN9GkIKDwoIBAACAwicCAASA30bQQqW
AQoEBAACBBIEggECTxqHASBPcHRpb25hbC4gVXNlci1kZWZpbmVkIGFubm90YXRpb25zLiBT
ZWUKIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTQ4I2Fubm90YXRpb25zIGZvciBtb3JlIGRl
dGFpbHMgc3VjaCBhcyBmb3JtYXQgYW5kCiBzaXplIGxpbWl0YXRpb25zCgoNCgUEAAIEBhIE
ggECFQoNCgUEAAIEARIEggEWIQoNCgUEAAIEAxIEggEkJQoNCgUEAAIECBIEggEmTgoQCggE
AAIECJwIABIEggEnTQqFAQoEBAACBRIGhgECiQEEGnUgUmVxdWlyZWQuIEltbXV0YWJsZS4g
VGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVzb3VyY2UgdG8gd2hpY2ggdGhlCiBw
b2xpY3kgd2lsbCBiZSBib3VuZC4gSW1tdXRhYmxlIG9uY2Ugc2V0LgoKDQoFBAACBQYSBIYB
AggKDQoFBAACBQESBIYBCQ8KDQoFBAACBQMSBIYBEhMKDwoFBAACBQgSBoYBFIkBAwoQCggE
AAIFCJwIABIEhwEEKwoQCggEAAIFCJwIARIEiAEEKgrOAQoEBAACBhIEkAECSBq/ASBJbW11
dGFibGUuIFRoZSBraW5kIG9mIHRoZSBwb2xpY3kgdG8gYXR0YWNoIGluIHRoaXMgYmluZGlu
Zy4gVGhpcyBmaWVsZAogbXVzdCBiZSBvbmUgb2YgdGhlIGZvbGxvd2luZzoKCiAtIExlZnQg
ZW1wdHkgKHdpbGwgYmUgYXV0b21hdGljYWxseSBzZXQgdG8gdGhlIHBvbGljeSBraW5kKQog
LSBUaGUgaW5wdXQgcG9saWN5IGtpbmQKCg0KBQQAAgYGEgSQAQIMCg0KBQQAAgYBEgSQAQ0Y
Cg0KBQQAAgYDEgSQARsdCg0KBQQAAgYIEgSQAR5HChAKCAQAAgYInAgAEgSQAR9GCpkBCgQE
AAIHEgaUAQKXAQQaiAEgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIHBvbGljeSB0byBiZSBib3VuZC4gVGhlCiBiaW5kaW5nIHBhcmVudCBhbmQgcG9s
aWN5IG11c3QgYmVsb25nIHRvIHRoZSBzYW1lIG9yZ2FuaXphdGlvbi4KCg0KBQQAAgcFEgSU
AQIICg0KBQQAAgcBEgSUAQkPCg0KBQQAAgcDEgSUARITCg8KBQQAAgcIEgaUARSXAQMKEAoI
BAACBwicCAASBJUBBCsKEAoIBAACBwicCAESBJYBBCoKTgoEBAACCBIEmgECRRpAIE91dHB1
dCBvbmx5LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIElEIG9mIHRoZSBwb2xpY3kgdG8gYmUgYm91
bmQuCgoNCgUEAAIIBRIEmgECCAoNCgUEAAIIARIEmgEJEwoNCgUEAAIIAxIEmgEWGAoNCgUE
AAIICBIEmgEZRAoQCggEAAIICJwIABIEmgEaQwqODAoEBAACCRIEwQECShr/CyBPcHRpb25h
bC4gVGhlIGNvbmRpdGlvbiB0byBhcHBseSB0byB0aGUgcG9saWN5IGJpbmRpbmcuIFdoZW4g
c2V0LCB0aGUKIGBleHByZXNzaW9uYCBmaWVsZCBpbiB0aGUgYEV4cHJgIG11c3QgaW5jbHVk
ZSBmcm9tIDEgdG8gMTAgc3ViZXhwcmVzc2lvbnMsCiBqb2luZWQgYnkgdGhlCiAifHwiKExv
Z2ljYWwgT1IpLCAiJiYiKExvZ2ljYWwgQU5EKSBvciAiISIoTG9naWNhbCBOT1QpIG9wZXJh
dG9ycyBhbmQKIGNhbm5vdCBjb250YWluIG1vcmUgdGhhbiAyNTAgY2hhcmFjdGVycy4KCiBU
aGUgY29uZGl0aW9uIGlzIGN1cnJlbnRseSBvbmx5IHN1cHBvcnRlZCB3aGVuIGJvdW5kIHRv
IHBvbGljaWVzIG9mIGtpbmQKIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkuCgogV2hlbiB0
aGUgYm91bmQgcG9saWN5IGlzIGEgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3ks
IHRoZSBvbmx5CiBzdXBwb3J0ZWQgYXR0cmlidXRlcyBpbiBhbnkgc3ViZXhwcmVzc2lvbiBh
cmUgYHByaW5jaXBhbC50eXBlYCBhbmQKIGBwcmluY2lwYWwuc3ViamVjdGAuIEFuIGV4YW1w
bGUgZXhwcmVzc2lvbiBpczogInByaW5jaXBhbC50eXBlID09CiAnaWFtLmdvb2dsZWFwaXMu
Y29tL1NlcnZpY2VBY2NvdW50JyIgb3IgInByaW5jaXBhbC5zdWJqZWN0ID09CiAnYm9iQGV4
YW1wbGUuY29tJyIuCgogQWxsb3dlZCBvcGVyYXRpb25zIGZvciBgcHJpbmNpcGFsLnN1Ympl
Y3RgOgoKIC0gYHByaW5jaXBhbC5zdWJqZWN0ID09IDxwcmluY2lwYWwgc3ViamVjdCBzdHJp
bmc+YAogLSBgcHJpbmNpcGFsLnN1YmplY3QgIT0gPHByaW5jaXBhbCBzdWJqZWN0IHN0cmlu
Zz5gCiAtIGBwcmluY2lwYWwuc3ViamVjdCBpbiBbPGxpc3Qgb2YgcHJpbmNpcGFsIHN1Ympl
Y3RzPl1gCiAtIGBwcmluY2lwYWwuc3ViamVjdC5zdGFydHNXaXRoKDxzdHJpbmc+KWAKIC0g
YHByaW5jaXBhbC5zdWJqZWN0LmVuZHNXaXRoKDxzdHJpbmc+KWAKCiBBbGxvd2VkIG9wZXJh
dGlvbnMgZm9yIGBwcmluY2lwYWwudHlwZWA6CgogLSBgcHJpbmNpcGFsLnR5cGUgPT0gPHBy
aW5jaXBhbCB0eXBlIHN0cmluZz5gCiAtIGBwcmluY2lwYWwudHlwZSAhPSA8cHJpbmNpcGFs
IHR5cGUgc3RyaW5nPmAKIC0gYHByaW5jaXBhbC50eXBlIGluIFs8bGlzdCBvZiBwcmluY2lw
YWwgdHlwZXM+XWAKCiBTdXBwb3J0ZWQgcHJpbmNpcGFsIHR5cGVzIGFyZSB3b3Jrc3BhY2Us
IHdvcmtmb3JjZSBwb29sLCB3b3JrbG9hZCBwb29sLAogc2VydmljZSBhY2NvdW50LCBhbmQg
QWdlbnQgSWRlbnRpdHkuIEFsbG93ZWQgc3RyaW5nIG11c3QgYmUgb25lIG9mOgoKIC0gYGlh
bS5nb29nbGVhcGlzLmNvbS9Xb3Jrc3BhY2VJZGVudGl0eWAKIC0gYGlhbS5nb29nbGVhcGlz
LmNvbS9Xb3JrZm9yY2VQb29sSWRlbnRpdHlgCiAtIGBpYW0uZ29vZ2xlYXBpcy5jb20vV29y
a2xvYWRQb29sSWRlbnRpdHlgCiAtIGBpYW0uZ29vZ2xlYXBpcy5jb20vU2VydmljZUFjY291
bnRgCiAtIGBpYW0uZ29vZ2xlYXBpcy5jb20vQWdlbnRQb29sSWRlbnRpdHlgIChhdmFpbGFi
bGUgaW4gUHJldmlldykKCg0KBQQAAgkGEgTBAQISCg0KBQQAAgkBEgTBARMcCg0KBQQAAgkD
EgTBAR8gCg0KBQQAAgkIEgTBASFJChAKCAQAAgkInAgAEgTBASJICkwKBAQAAgoSBsQBAsUB
Mho8IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBwb2xpY3kgYmluZGluZyB3YXMg
Y3JlYXRlZC4KCg0KBQQAAgoGEgTEAQIbCg0KBQQAAgoBEgTEARwnCg0KBQQAAgoDEgTEASor
Cg0KBQQAAgoIEgTFAQYxChAKCAQAAgoInAgAEgTFAQcwCloKBAQAAgsSBsgBAskBMhpKIE91
dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBwb2xpY3kgYmluZGluZyB3YXMgbW9zdCBy
ZWNlbnRseSB1cGRhdGVkLgoKDQoFBAACCwYSBMgBAhsKDQoFBAACCwESBMgBHCcKDQoFBAAC
CwMSBMgBKiwKDQoFBAACCwgSBMkBBjEKEAoIBAACCwicCAASBMkBBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::PolicyBindingResources::PolicyBinding ===
    # Fields for PolicyBinding
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v3beta.PolicyBinding.AnnotationsEntry)
    # Field: target Type: 11 (.google.iam.v3beta.PolicyBinding.Target)
    # Field: policy_kind Type: 14 (.google.iam.v3beta.PolicyBinding.PolicyKind)
    # Field: policy Type: 9 ()
    # Field: policy_uid Type: 9 ()
    # Field: condition Type: 11 (.google.type.Expr)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: PolicyBinding::PolicyKind
our $PolicyBinding_POLICY_KIND_UNSPECIFIED = 0;
our $PolicyBinding_PRINCIPAL_ACCESS_BOUNDARY = 1;
our $PolicyBinding_ACCESS = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3beta::PolicyBindingResources - Compiled Protocol Buffers messages for google/iam/v3beta/policy_binding_resources.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::PolicyBindingResources;

    my $msg = Google::Iam::V3beta::PolicyBindingResources::PolicyBinding->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::PolicyBindingResources::PolicyBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/policy_binding_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::PolicyBindingResources::PolicyBinding

IAM policy binding resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the policy binding, in the format
`{binding_parent/locations/{location}/policyBindings/{policy_binding_id}`.
The binding parent is the closest Resource Manager resource (project,
folder, or organization) to the binding target.

Format:

* `projects/{project_id}/locations/{location}/policyBindings/{policy_binding_id}`
* `projects/{project_number}/locations/{location}/policyBindings/{policy_binding_id}`
* `folders/{folder_id}/locations/{location}/policyBindings/{policy_binding_id}`
* `organizations/{organization_id}/locations/{location}/policyBindings/{policy_binding_id}`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique ID of the policy binding. Assigned when
the policy binding is created.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag for the policy binding.
If this is provided on update, it must match the server's etag.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The description of the policy binding. Must be less than or equal
to 63 characters.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding::AnnotationsEntry>)

Optional. User-defined annotations. See
https://google.aip.dev/148#annotations for more details such as format and
size limitations

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding::Target>)

Required. Immutable. The full resource name of the resource to which the
policy will be bound. Immutable once set.

=item * C<< $msg->policy_kind() >> / C<< $msg->policy_kind($value) >>

Type: C<Enum> (L<Google::Iam::V3beta::PolicyBinding::PolicyKind>)

Immutable. The kind of the policy to attach in this binding. This field
must be one of the following:

- Left empty (will be automatically set to the policy kind)
- The input policy kind

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<String>

Required. Immutable. The resource name of the policy to be bound. The
binding parent and policy must belong to the same organization.

=item * C<< $msg->policy_uid() >> / C<< $msg->policy_uid($value) >>

Type: C<String>

Output only. The globally unique ID of the policy to be bound.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

Optional. The condition to apply to the policy binding. When set, the
`expression` field in the `Expr` must include from 1 to 10 subexpressions,
joined by the
"||"(Logical OR), "&&"(Logical AND) or "!"(Logical NOT) operators and
cannot contain more than 250 characters.

The condition is currently only supported when bound to policies of kind
principal access boundary.

When the bound policy is a principal access boundary policy, the only
supported attributes in any subexpression are `principal.type` and
`principal.subject`. An example expression is: "principal.type ==
'iam.googleapis.com/ServiceAccount'" or "principal.subject ==
'bob@example.com'".

Allowed operations for `principal.subject`:

- `principal.subject == <principal subject string>`
- `principal.subject != <principal subject string>`
- `principal.subject in [<list of principal subjects>]`
- `principal.subject.startsWith(<string>)`
- `principal.subject.endsWith(<string>)`

Allowed operations for `principal.type`:

- `principal.type == <principal type string>`
- `principal.type != <principal type string>`
- `principal.type in [<list of principal types>]`

Supported principal types are workspace, workforce pool, workload pool,
service account, and Agent Identity. Allowed string must be one of:

- `iam.googleapis.com/WorkspaceIdentity`
- `iam.googleapis.com/WorkforcePoolIdentity`
- `iam.googleapis.com/WorkloadPoolIdentity`
- `iam.googleapis.com/ServiceAccount`
- `iam.googleapis.com/AgentPoolIdentity` (available in Preview)

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the policy binding was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the policy binding was most recently updated.

=back

=head3 Enum: PolicyBinding::PolicyKind

=over 4

=item * C<POLICY_KIND_UNSPECIFIED> => C<0>

=item * C<PRINCIPAL_ACCESS_BOUNDARY> => C<1>

=item * C<ACCESS> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::PolicyBindingResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
