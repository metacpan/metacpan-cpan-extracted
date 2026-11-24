package Google::Iam::V3::PolicyBindingResources;

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
Cixnb29nbGUvaWFtL3YzL3BvbGljeV9iaW5kaW5nX3Jlc291cmNlcy5wcm90bxINZ29vZ2xl
LmlhbS52MxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9m
aWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvGhZnb29nbGUvdHlwZS9leHByLnByb3RvIpQJCg1Qb2xp
Y3lCaW5kaW5nEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIdCgN1aWQYAiABKAlCC+KMz9cI
AggB4EEDUgN1aWQSFwoEZXRhZxgDIAEoCUID4EEBUgRldGFnEiYKDGRpc3BsYXlfbmFtZRgE
IAEoCUID4EEBUgtkaXNwbGF5TmFtZRJUCgthbm5vdGF0aW9ucxgFIAMoCzItLmdvb2dsZS5p
YW0udjMuUG9saWN5QmluZGluZy5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fubm90YXRpb25z
EkMKBnRhcmdldBgGIAEoCzIjLmdvb2dsZS5pYW0udjMuUG9saWN5QmluZGluZy5UYXJnZXRC
BuBBBeBBAlIGdGFyZ2V0Ek0KC3BvbGljeV9raW5kGAsgASgOMicuZ29vZ2xlLmlhbS52My5Q
b2xpY3lCaW5kaW5nLlBvbGljeUtpbmRCA+BBBVIKcG9saWN5S2luZBIeCgZwb2xpY3kYByAB
KAlCBuBBBeBBAlIGcG9saWN5EiIKCnBvbGljeV91aWQYDCABKAlCA+BBA1IJcG9saWN5VWlk
EjQKCWNvbmRpdGlvbhgIIAEoCzIRLmdvb2dsZS50eXBlLkV4cHJCA+BBAVIJY29uZGl0aW9u
EkAKC2NyZWF0ZV90aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lGmEKBlRhcmdldBIqCg1wcmluY2lwYWxfc2V0GAEg
ASgJQgPgQQVIAFIMcHJpbmNpcGFsU2V0EiEKCHJlc291cmNlGAIgASgJQgPgQQVIAFIIcmVz
b3VyY2VCCAoGdGFyZ2V0Gj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJUCgpQb2xpY3lLaW5kEhsKF1BPTElDWV9LSU5E
X1VOU1BFQ0lGSUVEEAASHQoZUFJJTkNJUEFMX0FDQ0VTU19CT1VOREFSWRABEgoKBkFDQ0VT
UxACOqgC6kGkAgogaWFtLmdvb2dsZWFwaXMuY29tL1BvbGljeUJpbmRpbmcSUW9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGlu
Z3Mve3BvbGljeV9iaW5kaW5nfRJFZm9sZGVycy97Zm9sZGVyfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9saWN5X2JpbmRpbmd9Ekdwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5n
fSoOcG9saWN5QmluZGluZ3MyDXBvbGljeUJpbmRpbmdCiQEKEWNvbS5nb29nbGUuaWFtLnYz
QhtQb2xpY3lCaW5kaW5nUmVzb3VyY2VzUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9p
YW0vYXBpdjMvaWFtcGI7aWFtcGKqAhNHb29nbGUuQ2xvdWQuSWFtLlYzygITR29vZ2xlXENs
b3VkXElhbVxWM0rKOgoHEgUOAMoBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAFgoJCgIDABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxID
FQApCgkKAgMEEgMWACAKCAoBCBIDGAAwCgkKAgglEgMYADAKCAoBCBIDGQBACgkKAggLEgMZ
AEAKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA8CgkKAggIEgMbADwKCAoBCBIDHAAq
CgkKAggBEgMcACoKCAoBCBIDHQAwCgkKAggpEgMdADAKKwoCBAASBSAAygEBGh4gSUFNIHBv
bGljeSBiaW5kaW5nIHJlc291cmNlLgoKCgoDBAABEgMgCBUKCwoDBAAHEgQhAigECg0KBQQA
B50IEgQhAigECm4KBAQAAwASBCwCVQMaYCBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRo
ZSByZXNvdXJjZSB0byB3aGljaCB0aGUgcG9saWN5IHdpbGwKIGJlIGJvdW5kLiBJbW11dGFi
bGUgb25jZSBzZXQuCgoMCgUEAAMAARIDLAoQCk8KBgQAAwAIABIELgRUBRo/IFRoZSBkaWZm
ZXJlbnQgdHlwZXMgb2YgdGFyZ2V0cyB0aGF0IGNhbiBiZSBib3VuZCB0byBhIHBvbGljeS4K
Cg4KBwQAAwAIAAESAy4KEAq1CAoGBAADAAIAEgNGBkkapQggSW1tdXRhYmxlLiBUaGUgZnVs
bCByZXNvdXJjZSBuYW1lIHRoYXQncyB1c2VkIGZvciBwcmluY2lwYWwgYWNjZXNzCiBib3Vu
ZGFyeSBwb2xpY3kgYmluZGluZ3MuIFRoZSBwcmluY2lwYWwgc2V0IG11c3QgYmUgZGlyZWN0
bHkgcGFyZW50ZWQKIGJ5IHRoZSBwb2xpY3kgYmluZGluZydzIHBhcmVudCBvciBzYW1lIGFz
IHRoZSBwYXJlbnQgaWYgdGhlIHRhcmdldCBpcyBhCiBwcm9qZWN0LCBmb2xkZXIsIG9yIG9y
Z2FuaXphdGlvbi4KCiBFeGFtcGxlczoKCiAqIEZvciBiaW5kaW5ncyBwYXJlbnRlZCBieSBh
biBvcmdhbml6YXRpb246CiAgICAgKiBPcmdhbml6YXRpb246CiAgICAgYC8vY2xvdWRyZXNv
dXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vb3JnYW5pemF0aW9ucy9PUkdBTklaQVRJT05f
SURgCiAgICAgKiBXb3JrZm9yY2UgSWRlbnRpdHk6CiAgICAgYC8vaWFtLmdvb2dsZWFwaXMu
Y29tL2xvY2F0aW9ucy9nbG9iYWwvd29ya2ZvcmNlUG9vbHMvV09SS0ZPUkNFX1BPT0xfSURg
CiAgICAgKiBXb3Jrc3BhY2UgSWRlbnRpdHk6CiAgICAgYC8vaWFtLmdvb2dsZWFwaXMuY29t
L2xvY2F0aW9ucy9nbG9iYWwvd29ya3NwYWNlL1dPUktTUEFDRV9JRGAKICogRm9yIGJpbmRp
bmdzIHBhcmVudGVkIGJ5IGEgZm9sZGVyOgogICAgICogRm9sZGVyOgogICAgICAgYC8vY2xv
dWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vZm9sZGVycy9GT0xERVJfSURgCiAq
IEZvciBiaW5kaW5ncyBwYXJlbnRlZCBieSBhIHByb2plY3Q6CiAgICAgKiBQcm9qZWN0Ogog
ICAgICAgICAqIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL3Byb2pl
Y3RzL1BST0pFQ1RfTlVNQkVSYAogICAgICAgICAqIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2Vy
Lmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL1BST0pFQ1RfSURgCiAgICAgKiBXb3JrbG9hZCBJ
ZGVudGl0eSBQb29sOgogICAgIGAvL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9QUk9K
RUNUX05VTUJFUi9sb2NhdGlvbnMvTE9DQVRJT04vd29ya2xvYWRJZGVudGl0eVBvb2xzL1dP
UktMT0FEX1BPT0xfSURgCgoOCgcEAAMAAgAFEgNGBgwKDgoHBAADAAIAARIDRg0aCg4KBwQA
AwACAAMSA0YdHgoOCgcEAAMAAgAIEgNGH0gKEQoKBAADAAIACJwIABIDRiBHCpwDCgYEAAMA
AgESA1MGRBqMAyBJbW11dGFibGUuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgdGhhdCdzIHVz
ZWQgZm9yIGFjY2VzcyBwb2xpY3kKIGJpbmRpbmdzLgoKIEV4YW1wbGVzOgoKICogT3JnYW5p
emF0aW9uOgogYC8vY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vb3JnYW5p
emF0aW9ucy9PUkdBTklaQVRJT05fSURgCiAqIEZvbGRlcjogYC8vY2xvdWRyZXNvdXJjZW1h
bmFnZXIuZ29vZ2xlYXBpcy5jb20vZm9sZGVycy9GT0xERVJfSURgCiAqIFByb2plY3Q6CiAg
ICAgKiBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9Q
Uk9KRUNUX05VTUJFUmAKICAgICAqIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFw
aXMuY29tL3Byb2plY3RzL1BST0pFQ1RfSURgCgoOCgcEAAMAAgEFEgNTBgwKDgoHBAADAAIB
ARIDUw0VCg4KBwQAAwACAQMSA1MYGQoOCgcEAAMAAgEIEgNTGkMKEQoKBAADAAIBCJwIABID
UxtCCkUKBAQABAASBFgCYQMaNyBUaGUgZGlmZmVyZW50IHBvbGljeSBraW5kcyBzdXBwb3J0
ZWQgaW4gdGhpcyBiaW5kaW5nLgoKDAoFBAAEAAESA1gHEQo7CgYEAAQAAgASA1oEIBosIFVu
c3BlY2lmaWVkIHBvbGljeSBraW5kOyBOb3QgYSB2YWxpZCBzdGF0ZQoKDgoHBAAEAAIAARID
WgQbCg4KBwQABAACAAISA1oeHwo2CgYEAAQAAgESA10EIhonIFByaW5jaXBhbCBhY2Nlc3Mg
Ym91bmRhcnkgcG9saWN5IGtpbmQKCg4KBwQABAACAQESA10EHQoOCgcEAAQAAgECEgNdICEK
JAoGBAAEAAICEgNgBA8aFSBBY2Nlc3MgcG9saWN5IGtpbmQuCgoOCgcEAAQAAgIBEgNgBAoK
DgoHBAAEAAICAhIDYA0OCvAECgQEAAIAEgNuAj0a4gQgSWRlbnRpZmllci4gVGhlIG5hbWUg
b2YgdGhlIHBvbGljeSBiaW5kaW5nLCBpbiB0aGUgZm9ybWF0CiBge2JpbmRpbmdfcGFyZW50
L2xvY2F0aW9ucy97bG9jYXRpb259L3BvbGljeUJpbmRpbmdzL3twb2xpY3lfYmluZGluZ19p
ZH1gLgogVGhlIGJpbmRpbmcgcGFyZW50IGlzIHRoZSBjbG9zZXN0IFJlc291cmNlIE1hbmFn
ZXIgcmVzb3VyY2UgKHByb2plY3QsCiBmb2xkZXIsIG9yIG9yZ2FuaXphdGlvbikgdG8gdGhl
IGJpbmRpbmcgdGFyZ2V0LgoKIEZvcm1hdDoKCiAqIGBwcm9qZWN0cy97cHJvamVjdF9pZH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lk
fWAKICogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKICogYGZvbGRlcnMve2ZvbGRl
cl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5k
aW5nX2lkfWAKICogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKCgwKBQQA
AgAFEgNuAggKDAoFBAACAAESA24JDQoMCgUEAAIAAxIDbhARCgwKBQQAAgAIEgNuEjwKDwoI
BAACAAicCAASA24TOwp4CgQEAAIBEgRyAnUEGmogT3V0cHV0IG9ubHkuIFRoZSBnbG9iYWxs
eSB1bmlxdWUgSUQgb2YgdGhlIHBvbGljeSBiaW5kaW5nLiBBc3NpZ25lZCB3aGVuCiB0aGUg
cG9saWN5IGJpbmRpbmcgaXMgY3JlYXRlZC4KCgwKBQQAAgEFEgNyAggKDAoFBAACAQESA3IJ
DAoMCgUEAAIBAxIDcg8QCg0KBQQAAgEIEgRyEXUDChIKCwQAAgEIzPH5igEBEgNzBCoKDwoI
BAACAQicCAASA3QELQp6CgQEAAICEgN5AjsabSBPcHRpb25hbC4gVGhlIGV0YWcgZm9yIHRo
ZSBwb2xpY3kgYmluZGluZy4KIElmIHRoaXMgaXMgcHJvdmlkZWQgb24gdXBkYXRlLCBpdCBt
dXN0IG1hdGNoIHRoZSBzZXJ2ZXIncyBldGFnLgoKDAoFBAACAgUSA3kCCAoMCgUEAAICARID
eQkNCgwKBQQAAgIDEgN5EBEKDAoFBAACAggSA3kSOgoPCggEAAICCJwIABIDeRM5Cm0KBAQA
AgMSA30CQxpgIE9wdGlvbmFsLiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIHBvbGljeSBiaW5k
aW5nLiBNdXN0IGJlIGxlc3MgdGhhbiBvciBlcXVhbAogdG8gNjMgY2hhcmFjdGVycy4KCgwK
BQQAAgMFEgN9AggKDAoFBAACAwESA30JFQoMCgUEAAIDAxIDfRgZCgwKBQQAAgMIEgN9GkIK
DwoIBAACAwicCAASA30bQQqWAQoEBAACBBIEggECTxqHASBPcHRpb25hbC4gVXNlci1kZWZp
bmVkIGFubm90YXRpb25zLiBTZWUKIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTQ4I2Fubm90
YXRpb25zIGZvciBtb3JlIGRldGFpbHMgc3VjaCBhcyBmb3JtYXQgYW5kCiBzaXplIGxpbWl0
YXRpb25zCgoNCgUEAAIEBhIEggECFQoNCgUEAAIEARIEggEWIQoNCgUEAAIEAxIEggEkJQoN
CgUEAAIECBIEggEmTgoQCggEAAIECJwIABIEggEnTQqFAQoEBAACBRIGhgECiQEEGnUgUmVx
dWlyZWQuIEltbXV0YWJsZS4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVzb3Vy
Y2UgdG8gd2hpY2ggdGhlCiBwb2xpY3kgd2lsbCBiZSBib3VuZC4gSW1tdXRhYmxlIG9uY2Ug
c2V0LgoKDQoFBAACBQYSBIYBAggKDQoFBAACBQESBIYBCQ8KDQoFBAACBQMSBIYBEhMKDwoF
BAACBQgSBoYBFIkBAwoQCggEAAIFCJwIABIEhwEEKwoQCggEAAIFCJwIARIEiAEEKgrOAQoE
BAACBhIEkAECSBq/ASBJbW11dGFibGUuIFRoZSBraW5kIG9mIHRoZSBwb2xpY3kgdG8gYXR0
YWNoIGluIHRoaXMgYmluZGluZy4gVGhpcyBmaWVsZAogbXVzdCBiZSBvbmUgb2YgdGhlIGZv
bGxvd2luZzoKCiAtIExlZnQgZW1wdHkgKHdpbGwgYmUgYXV0b21hdGljYWxseSBzZXQgdG8g
dGhlIHBvbGljeSBraW5kKQogLSBUaGUgaW5wdXQgcG9saWN5IGtpbmQKCg0KBQQAAgYGEgSQ
AQIMCg0KBQQAAgYBEgSQAQ0YCg0KBQQAAgYDEgSQARsdCg0KBQQAAgYIEgSQAR5HChAKCAQA
AgYInAgAEgSQAR9GCpkBCgQEAAIHEgaUAQKXAQQaiAEgUmVxdWlyZWQuIEltbXV0YWJsZS4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHBvbGljeSB0byBiZSBib3VuZC4gVGhlCiBiaW5k
aW5nIHBhcmVudCBhbmQgcG9saWN5IG11c3QgYmVsb25nIHRvIHRoZSBzYW1lIG9yZ2FuaXph
dGlvbi4KCg0KBQQAAgcFEgSUAQIICg0KBQQAAgcBEgSUAQkPCg0KBQQAAgcDEgSUARITCg8K
BQQAAgcIEgaUARSXAQMKEAoIBAACBwicCAASBJUBBCsKEAoIBAACBwicCAESBJYBBCoKTgoE
BAACCBIEmgECRRpAIE91dHB1dCBvbmx5LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIElEIG9mIHRo
ZSBwb2xpY3kgdG8gYmUgYm91bmQuCgoNCgUEAAIIBRIEmgECCAoNCgUEAAIIARIEmgEJEwoN
CgUEAAIIAxIEmgEWGAoNCgUEAAIICBIEmgEZRAoQCggEAAIICJwIABIEmgEaQwqODAoEBAAC
CRIEwQECShr/CyBPcHRpb25hbC4gVGhlIGNvbmRpdGlvbiB0byBhcHBseSB0byB0aGUgcG9s
aWN5IGJpbmRpbmcuIFdoZW4gc2V0LCB0aGUKIGBleHByZXNzaW9uYCBmaWVsZCBpbiB0aGUg
YEV4cHJgIG11c3QgaW5jbHVkZSBmcm9tIDEgdG8gMTAgc3ViZXhwcmVzc2lvbnMsCiBqb2lu
ZWQgYnkgdGhlCiAifHwiKExvZ2ljYWwgT1IpLCAiJiYiKExvZ2ljYWwgQU5EKSBvciAiISIo
TG9naWNhbCBOT1QpIG9wZXJhdG9ycyBhbmQKIGNhbm5vdCBjb250YWluIG1vcmUgdGhhbiAy
NTAgY2hhcmFjdGVycy4KCiBUaGUgY29uZGl0aW9uIGlzIGN1cnJlbnRseSBvbmx5IHN1cHBv
cnRlZCB3aGVuIGJvdW5kIHRvIHBvbGljaWVzIG9mIGtpbmQKIHByaW5jaXBhbCBhY2Nlc3Mg
Ym91bmRhcnkuCgogV2hlbiB0aGUgYm91bmQgcG9saWN5IGlzIGEgcHJpbmNpcGFsIGFjY2Vz
cyBib3VuZGFyeSBwb2xpY3ksIHRoZSBvbmx5CiBzdXBwb3J0ZWQgYXR0cmlidXRlcyBpbiBh
bnkgc3ViZXhwcmVzc2lvbiBhcmUgYHByaW5jaXBhbC50eXBlYCBhbmQKIGBwcmluY2lwYWwu
c3ViamVjdGAuIEFuIGV4YW1wbGUgZXhwcmVzc2lvbiBpczogInByaW5jaXBhbC50eXBlID09
CiAnaWFtLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VBY2NvdW50JyIgb3IgInByaW5jaXBhbC5z
dWJqZWN0ID09CiAnYm9iQGV4YW1wbGUuY29tJyIuCgogQWxsb3dlZCBvcGVyYXRpb25zIGZv
ciBgcHJpbmNpcGFsLnN1YmplY3RgOgoKIC0gYHByaW5jaXBhbC5zdWJqZWN0ID09IDxwcmlu
Y2lwYWwgc3ViamVjdCBzdHJpbmc+YAogLSBgcHJpbmNpcGFsLnN1YmplY3QgIT0gPHByaW5j
aXBhbCBzdWJqZWN0IHN0cmluZz5gCiAtIGBwcmluY2lwYWwuc3ViamVjdCBpbiBbPGxpc3Qg
b2YgcHJpbmNpcGFsIHN1YmplY3RzPl1gCiAtIGBwcmluY2lwYWwuc3ViamVjdC5zdGFydHNX
aXRoKDxzdHJpbmc+KWAKIC0gYHByaW5jaXBhbC5zdWJqZWN0LmVuZHNXaXRoKDxzdHJpbmc+
KWAKCiBBbGxvd2VkIG9wZXJhdGlvbnMgZm9yIGBwcmluY2lwYWwudHlwZWA6CgogLSBgcHJp
bmNpcGFsLnR5cGUgPT0gPHByaW5jaXBhbCB0eXBlIHN0cmluZz5gCiAtIGBwcmluY2lwYWwu
dHlwZSAhPSA8cHJpbmNpcGFsIHR5cGUgc3RyaW5nPmAKIC0gYHByaW5jaXBhbC50eXBlIGlu
IFs8bGlzdCBvZiBwcmluY2lwYWwgdHlwZXM+XWAKCiBTdXBwb3J0ZWQgcHJpbmNpcGFsIHR5
cGVzIGFyZSB3b3Jrc3BhY2UsIHdvcmtmb3JjZSBwb29sLCB3b3JrbG9hZCBwb29sLAogc2Vy
dmljZSBhY2NvdW50LCBhbmQgYWdlbnQgaWRlbnRpdHkuIEFsbG93ZWQgc3RyaW5nIG11c3Qg
YmUgb25lIG9mOgoKIC0gYGlhbS5nb29nbGVhcGlzLmNvbS9Xb3Jrc3BhY2VJZGVudGl0eWAK
IC0gYGlhbS5nb29nbGVhcGlzLmNvbS9Xb3JrZm9yY2VQb29sSWRlbnRpdHlgCiAtIGBpYW0u
Z29vZ2xlYXBpcy5jb20vV29ya2xvYWRQb29sSWRlbnRpdHlgCiAtIGBpYW0uZ29vZ2xlYXBp
cy5jb20vU2VydmljZUFjY291bnRgCiAtIGBpYW0uZ29vZ2xlYXBpcy5jb20vQWdlbnRQb29s
SWRlbnRpdHlgIChhdmFpbGFibGUgaW4gUHJldmlldykKCg0KBQQAAgkGEgTBAQISCg0KBQQA
AgkBEgTBARMcCg0KBQQAAgkDEgTBAR8gCg0KBQQAAgkIEgTBASFJChAKCAQAAgkInAgAEgTB
ASJICkwKBAQAAgoSBsQBAsUBMho8IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBw
b2xpY3kgYmluZGluZyB3YXMgY3JlYXRlZC4KCg0KBQQAAgoGEgTEAQIbCg0KBQQAAgoBEgTE
ARwnCg0KBQQAAgoDEgTEASorCg0KBQQAAgoIEgTFAQYxChAKCAQAAgoInAgAEgTFAQcwCloK
BAQAAgsSBsgBAskBMhpKIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBwb2xpY3kg
YmluZGluZyB3YXMgbW9zdCByZWNlbnRseSB1cGRhdGVkLgoKDQoFBAACCwYSBMgBAhsKDQoF
BAACCwESBMgBHCcKDQoFBAACCwMSBMgBKiwKDQoFBAACCwgSBMkBBjEKEAoIBAACCwicCAAS
BMkBBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::PolicyBindingResources::PolicyBinding ===
    # Fields for PolicyBinding
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v3.PolicyBinding.AnnotationsEntry)
    # Field: target Type: 11 (.google.iam.v3.PolicyBinding.Target)
    # Field: policy_kind Type: 14 (.google.iam.v3.PolicyBinding.PolicyKind)
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

Google::Iam::V3::PolicyBindingResources - Compiled Protocol Buffers messages for google/iam/v3/policy_binding_resources.proto

=head1 SYNOPSIS

    use Google::Iam::V3::PolicyBindingResources;

    my $msg = Google::Iam::V3::PolicyBindingResources::PolicyBinding->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::PolicyBindingResources::PolicyBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/policy_binding_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::PolicyBindingResources::PolicyBinding

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

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding::AnnotationsEntry>)

Optional. User-defined annotations. See
https://google.aip.dev/148#annotations for more details such as format and
size limitations

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding::Target>)

Required. Immutable. The full resource name of the resource to which the
policy will be bound. Immutable once set.

=item * C<< $msg->policy_kind() >> / C<< $msg->policy_kind($value) >>

Type: C<Enum> (L<Google::Iam::V3::PolicyBinding::PolicyKind>)

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
service account, and agent identity. Allowed string must be one of:

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::PolicyBindingResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
