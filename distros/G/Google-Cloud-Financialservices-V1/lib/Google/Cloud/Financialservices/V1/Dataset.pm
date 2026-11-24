package Google::Cloud::Financialservices::V1::Dataset;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Datetime };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvZGF0YXNldC5wcm90bxIhZ29v
Z2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYv
ZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoaZ29v
Z2xlL3R5cGUvZGF0ZXRpbWUucHJvdG8aGmdvb2dsZS90eXBlL2ludGVydmFsLnByb3RvIukG
CgdEYXRhc2V0EhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRJOCgZsYWJlbHMYBCADKAsyNi5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMu
djEuRGF0YXNldC5MYWJlbHNFbnRyeVIGbGFiZWxzEmAKC3RhYmxlX3NwZWNzGAUgAygLMjou
Z29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkRhdGFzZXQuVGFibGVTcGVjc0Vu
dHJ5QgPgQQJSCnRhYmxlU3BlY3MSSwoFc3RhdGUYByABKA4yMC5nb29nbGUuY2xvdWQuZmlu
YW5jaWFsc2VydmljZXMudjEuRGF0YXNldC5TdGF0ZUID4EEDUgVzdGF0ZRI5CgpkYXRlX3Jh
bmdlGAggASgLMhUuZ29vZ2xlLnR5cGUuSW50ZXJ2YWxCA+BBAlIJZGF0ZVJhbmdlEjIKCXRp
bWVfem9uZRgJIAEoCzIVLmdvb2dsZS50eXBlLlRpbWVab25lUgh0aW1lWm9uZRo5CgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj0K
D1RhYmxlU3BlY3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIlQKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIK
CgZBQ1RJVkUQAhIMCghVUERBVElORxADEgwKCERFTEVUSU5HEAQ6ggHqQX8KKGZpbmFuY2lh
bHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0RhdGFzZXQSU3Byb2plY3RzL3twcm9qZWN0X251
bX0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vZGF0YXNldHMv
e2RhdGFzZXR9Is8BChNMaXN0RGF0YXNldHNSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx4EEC
+kErCilmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIGcGFyZW50
EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFn
ZVRva2VuEhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyEhkKCG9yZGVyX2J5GAUgASgJUgdvcmRl
ckJ5IqgBChRMaXN0RGF0YXNldHNSZXNwb25zZRJGCghkYXRhc2V0cxgBIAMoCzIqLmdvb2ds
ZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5EYXRhc2V0UghkYXRhc2V0cxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlS
C3VucmVhY2hhYmxlIlkKEUdldERhdGFzZXRSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpB
KgooZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRGF0YXNldFIEbmFtZSL0AQoU
Q3JlYXRlRGF0YXNldFJlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWZpbmFuY2lh
bHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgZwYXJlbnQSIgoKZGF0YXNldF9p
ZBgCIAEoCUID4EECUglkYXRhc2V0SWQSSQoHZGF0YXNldBgDIAEoCzIqLmdvb2dsZS5jbG91
ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5EYXRhc2V0QgPgQQJSB2RhdGFzZXQSIgoKcmVxdWVz
dF9pZBgEIAEoCUID4EEBUglyZXF1ZXN0SWQixwEKFFVwZGF0ZURhdGFzZXRSZXF1ZXN0EkAK
C3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1
cGRhdGVNYXNrEkkKB2RhdGFzZXQYAiABKAsyKi5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2Vy
dmljZXMudjEuRGF0YXNldEID4EECUgdkYXRhc2V0EiIKCnJlcXVlc3RfaWQYAyABKAlCA+BB
AVIJcmVxdWVzdElkIoABChREZWxldGVEYXRhc2V0UmVxdWVzdBJECgRuYW1lGAEgASgJQjDg
QQL6QSoKKGZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0RhdGFzZXRSBG5hbWUS
IgoKcmVxdWVzdF9pZBgCIAEoCUID4EEBUglyZXF1ZXN0SWRC+wEKJWNvbS5nb29nbGUuY2xv
dWQuZmluYW5jaWFsc2VydmljZXMudjFCDERhdGFzZXRQcm90b1ABWlNjbG91ZC5nb29nbGUu
Y29tL2dvL2ZpbmFuY2lhbHNlcnZpY2VzL2FwaXYxL2ZpbmFuY2lhbHNlcnZpY2VzcGI7Zmlu
YW5jaWFsc2VydmljZXNwYqoCIUdvb2dsZS5DbG91ZC5GaW5hbmNpYWxTZXJ2aWNlcy5WMcoC
IUdvb2dsZVxDbG91ZFxGaW5hbmNpYWxTZXJ2aWNlc1xWMeoCJEdvb2dsZTo6Q2xvdWQ6OkZp
bmFuY2lhbFNlcnZpY2VzOjpWMUqRRAoHEgUOAOwBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQA
KgoJCgIDAxIDFQApCgkKAgMEEgMWACQKCQoCAwUSAxcAJAoICgEIEgMZAD4KCQoCCCUSAxkA
PgoICgEIEgMaAGoKCQoCCAsSAxoAagoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcAC0K
CQoCCAgSAxwALQoICgEIEgMdAD4KCQoCCAESAx0APgoICgEIEgMeAD4KCQoCCCkSAx4APgoI
CgEIEgMfAD0KCQoCCC0SAx8APQpQCgIEABIEIgBfARpEIFRoZSBEYXRhc2V0IHJlc291cmNl
IGNvbnRhaW5zIHN1bW1hcnkgaW5mb3JtYXRpb24gYWJvdXQgYSBkYXRhc2V0LgoKCgoDBAAB
EgMiCA8KCwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYECjIKBAQABAASBCkCOAMaJCBUaGUg
cG9zc2libGUgc3RhdGVzIG9mIGEgcmVzb3VyY2UuCgoMCgUEAAQAARIDKQcMCjgKBgQABAAC
ABIDKwQaGikgU3RhdGUgaXMgdW5zcGVjaWZpZWQsIHNob3VsZCBub3Qgb2NjdXIuCgoOCgcE
AAQAAgABEgMrBBUKDgoHBAAEAAIAAhIDKxgZCj0KBgQABAACARIDLgQRGi4gVGhlIHJlc291
cmNlIGhhcyBub3QgZmluaXNoZWQgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACAQESAy4EDAoO
CgcEAAQAAgECEgMuDxAKOQoGBAAEAAICEgMxBA8aKiBUaGUgcmVzb3VyY2UgaXMgYWN0aXZl
L3JlYWR5IHRvIGJlIHVzZWQuCgoOCgcEAAQAAgIBEgMxBAoKDgoHBAAEAAICAhIDMQ0OCkEK
BgQABAACAxIDNAQRGjIgVGhlIHJlc291cmNlIGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5n
IHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgM0BAwKDgoHBAAEAAIDAhIDNA8QCkEKBgQABAACBBID
NwQRGjIgVGhlIHJlc291cmNlIGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIGRlbGV0ZWQu
CgoOCgcEAAQAAgQBEgM3BAwKDgoHBAAEAAIEAhIDNw8QCp8BCgQEAAIAEgM9Aj4akQEgT3V0
cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBEYXRhc2V0LgogZm9ybWF0Ogog
YC9wcm9qZWN0cy97cHJvamVjdF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNl
cy97aW5zdGFuY2V9L2RhdGFzZXRzL3tkYXRhc2V0fWAKCgwKBQQAAgAFEgM9AggKDAoFBAAC
AAESAz0JDQoMCgUEAAIAAxIDPRARCgwKBQQAAgAIEgM9Ej0KDwoIBAACAAicCAASAz0TPApI
CgQEAAIBEgRAAkEyGjogT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgY3JlYXRpb24g
b2YgdGhpcyByZXNvdXJjZS4KCgwKBQQAAgEGEgNAAhsKDAoFBAACAQESA0AcJwoMCgUEAAIB
AxIDQCorCgwKBQQAAgEIEgNBBjEKDwoIBAACAQicCAASA0EHMApWCgQEAAICEgREAkUyGkgg
T3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgdGhlIG1vc3QgcmVjZW50IHVwZGF0ZSBv
ZiB0aGlzIHJlc291cmNlLgoKDAoFBAACAgYSA0QCGwoMCgUEAAICARIDRBwnCgwKBQQAAgID
EgNEKisKDAoFBAACAggSA0UGMQoPCggEAAICCJwIABIDRQcwChUKBAQAAgMSA0gCIRoIIExh
YmVscwoKDAoFBAACAwYSA0gCFQoMCgUEAAIDARIDSBYcCgwKBQQAAgMDEgNIHyAK0gIKBAQA
AgQSA1QCTxrEAiBSZXF1aXJlZC4gVGhlIHNldCBvZiBCaWdRdWVyeSB0YWJsZXMgaW4gdGhl
IGRhdGFzZXQuICBUaGUga2V5IHNob3VsZCBiZSB0aGUKIHRhYmxlIHR5cGUgYW5kIHRoZSB2
YWx1ZSBzaG91bGQgYmUgdGhlIEJpZ1F1ZXJ5IHRhYmxlcyBpbiB0aGUgZm9ybWF0CiBgYnE6
Ly97cHJvamVjdH0ue2RhdGFzZXR9Lnt0YWJsZX1gLgogQ3VycmVudCB0YWJsZSB0eXBlcyBh
cmU6CgogICAqIGBwYXJ0eWAKICAgKiBgYWNjb3VudF9wYXJ0eV9saW5rYAogICAqIGB0cmFu
c2FjdGlvbmAKICAgKiBgcmlza19jYXNlX2V2ZW50YAogICAqIGBwYXJ0eV9zdXBwbGVtZW50
YXJ5X2RhdGFgCgoMCgUEAAIEBhIDVAIVCgwKBQQAAgQBEgNUFiEKDAoFBAACBAMSA1QkJQoM
CgUEAAIECBIDVCZOCg8KCAQAAgQInAgAEgNUJ00KUwoEBAACBRIDVwI+GkYgT3V0cHV0IG9u
bHkuIFN0YXRlIG9mIHRoZSBkYXRhc2V0IChjcmVhdGluZywgYWN0aXZlLCBkZWxldGluZywg
ZXRjLikKCgwKBQQAAgUGEgNXAgcKDAoFBAACBQESA1cIDQoMCgUEAAIFAxIDVxARCgwKBQQA
AgUIEgNXEj0KDwoIBAACBQicCAASA1cTPAp1CgQEAAIGEgNbAk8aaCBSZXF1aXJlZC4gQ29y
ZSB0aW1lIHdpbmRvdyBvZiB0aGUgZGF0YXNldC4gQWxsIHRhYmxlcyBzaG91bGQgaGF2ZSBj
b21wbGV0ZQogZGF0YSBjb3ZlcmluZyB0aGlzIHBlcmlvZC4KCgwKBQQAAgYGEgNbAhYKDAoF
BAACBgESA1sXIQoMCgUEAAIGAxIDWyQlCgwKBQQAAgYIEgNbJk4KDwoIBAACBgicCAASA1sn
TQpBCgQEAAIHEgNeAiUaNCBUaGUgdGltZXpvbmUgb2YgdGhlIGRhdGEsIGRlZmF1bHQgd2ls
bCBhY3QgYXMgVVRDLgoKDAoFBAACBwYSA14CFgoMCgUEAAIHARIDXhcgCgwKBQQAAgcDEgNe
IyQKbQoCBAESBGMAfAEaYSBSZXF1ZXN0IGZvciByZXRyaWV2aW5nIGEgcGFnaW5hdGVkIGxp
c3Qgb2YgRGF0YXNldCByZXNvdXJjZXMgdGhhdCBtZWV0IHRoZQogc3BlY2lmaWVkIGNyaXRl
cmlhLgoKCgoDBAEBEgNjCBsKRAoEBAECABIEZQJqBBo2IFJlcXVpcmVkLiBUaGUgcGFyZW50
IG9mIHRoZSBEYXRhc2V0IGlzIHRoZSBJbnN0YW5jZS4KCgwKBQQBAgAFEgNlAggKDAoFBAEC
AAESA2UJDwoMCgUEAQIAAxIDZRITCg0KBQQBAgAIEgRlFGoDCg8KCAQBAgAInAgAEgNmBCoK
DwoHBAECAAifCBIEZwRpBQqsAQoEBAECARIDbwIWGp4BIFRoZSBudW1iZXIgb2YgcmVzb3Vy
Y2VzIHRvIGJlIGluY2x1ZGVkIGluIHRoZSByZXNwb25zZS4gVGhlIHJlc3BvbnNlCiBjb250
YWlucyBhIG5leHRfcGFnZV90b2tlbiwgd2hpY2ggY2FuIGJlIHVzZWQgdG8gcmV0cmlldmUg
dGhlIG5leHQgcGFnZSBvZgogcmVzb3VyY2VzLgoKDAoFBAECAQUSA28CBwoMCgUEAQIBARID
bwgRCgwKBQQBAgEDEgNvFBUKowIKBAQBAgISA3UCGBqVAiBJbiBjYXNlIG9mIHBhZ2luYXRl
ZCByZXN1bHRzLCB0aGlzIGlzIHRoZSB0b2tlbiB0aGF0IHdhcyByZXR1cm5lZCBpbiB0aGUK
IHByZXZpb3VzIExpc3REYXRhc2V0UmVzcG9uc2UuIEl0IHNob3VsZCBiZSBjb3BpZWQgaGVy
ZSB0byByZXRyaWV2ZSB0aGUKIG5leHQgcGFnZSBvZiByZXNvdXJjZXMuIEVtcHR5IHdpbGwg
Z2l2ZSB0aGUgZmlyc3QgcGFnZSBvZgogTGlzdERhdGFzZXRSZXF1ZXN0LCBhbmQgdGhlIGxh
c3QgcGFnZSB3aWxsIHJldHVybiBhbiBlbXB0eSBwYWdlX3Rva2VuLgoKDAoFBAECAgUSA3UC
CAoMCgUEAQICARIDdQkTCgwKBQQBAgIDEgN1FhcKOQoEBAECAxIDeAIUGiwgU3BlY2lmeSBh
IGZpbHRlciB0byBuYXJyb3cgc2VhcmNoIHJlc3VsdHMuCgoMCgUEAQIDBRIDeAIICgwKBQQB
AgMBEgN4CQ8KDAoFBAECAwMSA3gSEwozCgQEAQIEEgN7AhYaJiBTcGVjaWZ5IGEgZmllbGQg
dG8gdXNlIGZvciBvcmRlcmluZy4KCgwKBQQBAgQFEgN7AggKDAoFBAECBAESA3sJEQoMCgUE
AQIEAxIDexQVCjkKAgQCEgV/AIkBARosIFJlc3BvbnNlIGZvciByZXRyaWV2aW5nIGEgbGlz
dCBvZiBEYXRhc2V0cwoKCgoDBAIBEgN/CBwKKQoEBAICABIEgQECIBobIExpc3Qgb2YgRGF0
YXNldCByZXNvdXJjZXMKCg0KBQQCAgAEEgSBAQIKCg0KBQQCAgAGEgSBAQsSCg0KBQQCAgAB
EgSBARMbCg0KBQQCAgADEgSBAR4fCpIBCgQEAgIBEgSFAQIdGoMBIFRoaXMgdG9rZW4gc2hv
dWxkIGJlIHBhc3NlZCB0byB0aGUgbmV4dCBMaXN0RGF0YXNldHNSZXF1ZXN0IHRvIHJldHJp
ZXZlCiB0aGUgbmV4dCBwYWdlIG9mIERhdGFzZXRzIChlbXB0eSBpbmRpY2F0ZXMgd2UgYXJl
IGRvbmUpLgoKDQoFBAICAQUSBIUBAggKDQoFBAICAQESBIUBCRgKDQoFBAICAQMSBIUBGxwK
NAoEBAICAhIEiAECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoK
DQoFBAICAgQSBIgBAgoKDQoFBAICAgUSBIgBCxEKDQoFBAICAgESBIgBEh0KDQoFBAICAgMS
BIgBICEKQwoCBAMSBowBAJQBARo1IFJlcXVlc3QgZm9yIHJldHJpZXZpbmcgYSBzcGVjaWZp
YyBEYXRhc2V0IHJlc291cmNlLgoKCwoDBAMBEgSMAQgZCjwKBAQDAgASBo4BApMBBBosIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRGF0YXNldAoKDQoFBAMCAAUSBI4B
AggKDQoFBAMCAAESBI4BCQ0KDQoFBAMCAAMSBI4BEBEKDwoFBAMCAAgSBo4BEpMBAwoQCggE
AwIACJwIABIEjwEEKgoRCgcEAwIACJ8IEgaQAQSSAQUKOAoCBAQSBpcBALQBARoqIFJlcXVl
c3QgZm9yIGNyZWF0aW5nIGEgRGF0YXNldCByZXNvdXJjZS4KCgsKAwQEARIElwEIHApGCgQE
BAIAEgaZAQKeAQQaNiBSZXF1aXJlZC4gVGhlIHBhcmVudCBvZiB0aGUgRGF0YXNldCBpcyB0
aGUgSW5zdGFuY2UuCgoNCgUEBAIABRIEmQECCAoNCgUEBAIAARIEmQEJDwoNCgUEBAIAAxIE
mQESEwoPCgUEBAIACBIGmQEUngEDChAKCAQEAgAInAgAEgSaAQQqChEKBwQEAgAInwgSBpsB
BJ0BBQo4CgQEBAIBEgShAQJBGiogUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBpZCBvZiB0aGUg
ZGF0YXNldAoKDQoFBAQCAQUSBKEBAggKDQoFBAQCAQESBKEBCRMKDQoFBAQCAQMSBKEBFhcK
DQoFBAQCAQgSBKEBGEAKEAoIBAQCAQicCAASBKEBGT8KOwoEBAQCAhIEpAECPxotIFJlcXVp
cmVkLiBUaGUgZGF0YXNldCB0aGF0IHdpbGwgYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgSkAQIJ
Cg0KBQQEAgIBEgSkAQoRCg0KBQQEAgIDEgSkARQVCg0KBQQEAgIIEgSkARY+ChAKCAQEAgII
nAgAEgSkARc9Co8GCgQEBAIDEgSzAQJBGoAGIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1
ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0
IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVy
IHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJl
ZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBs
ZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxl
LCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVl
c3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0
IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNr
IGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyBy
ZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRo
aXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGlj
YXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlE
IHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAo
MDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQEAgMFEgSzAQII
Cg0KBQQEAgMBEgSzAQkTCg0KBQQEAgMDEgSzARYXCg0KBQQEAgMIEgSzARhAChAKCAQEAgMI
nAgAEgSzARk/Ci4KAgQFEga3AQDSAQEaICBSZXF1ZXN0IGZvciB1cGRhdGluZyBhIERhdGFz
ZXQKCgsKAwQFARIEtwEIHArZAgoEBAUCABIGvQECvgEvGsgCIE9wdGlvbmFsLiBGaWVsZCBt
YXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGlu
IHRoZQogRGF0YXNldCByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVj
aWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2Us
IG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlm
IGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1h
c2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEBQIABhIEvQEC
GwoNCgUEBQIAARIEvQEcJwoNCgUEBQIAAxIEvQEqKwoNCgUEBQIACBIEvgEGLgoQCggEBQIA
CJwIABIEvgEHLQpxCgQEBQIBEgTCAQI/GmMgUmVxdWlyZWQuIFRoZSBuZXcgdmFsdWUgb2Yg
dGhlIGRhdGFzZXQgZmllbGRzIHRoYXQgd2lsbCBiZSB1cGRhdGVkCiBhY2NvcmRpbmcgdG8g
dGhlIHVwZGF0ZV9tYXNrLgoKDQoFBAUCAQYSBMIBAgkKDQoFBAUCAQESBMIBChEKDQoFBAUC
AQMSBMIBFBUKDQoFBAUCAQgSBMIBFj4KEAoIBAUCAQicCAASBMIBFz0KjwYKBAQFAgISBNEB
AkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVx
dWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVz
dCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUg
dGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2
ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2Ug
dGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9u
IHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRp
bWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSBy
ZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9u
IHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdp
bGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBm
cm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhl
IHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRo
YXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAw
MC0wMDAwMDAwMDAwMDApLgoKDQoFBAUCAgUSBNEBAggKDQoFBAUCAgESBNEBCRMKDQoFBAUC
AgMSBNEBFhcKDQoFBAUCAggSBNEBGEAKEAoIBAUCAgicCAASBNEBGT8KLwoCBAYSBtUBAOwB
ARohIFJlcXVlc3QgZm9yIGRlbGV0aW5nIGEgRGF0YXNldC4KCgsKAwQGARIE1QEIHAo9CgQE
BgIAEgbXAQLcAQQaLSBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIERhdGFz
ZXQuCgoNCgUEBgIABRIE1wECCAoNCgUEBgIAARIE1wEJDQoNCgUEBgIAAxIE1wEQEQoPCgUE
BgIACBIG1wES3AEDChAKCAQGAgAInAgAEgTYAQQqChEKBwQGAgAInwgSBtkBBNsBBQqPBgoE
BAYCARIE6wECQRqABiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVu
dGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlm
IHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8K
IGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4g
VGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRl
cyBhZnRlciB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBz
aXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZCB0aGUKIHJl
cXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRo
ZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5hbCBv
cGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBp
ZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBj
bGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50
cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNl
cHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAt
MDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBgIBBRIE6wECCAoNCgUEBgIBARIE6wEJ
EwoNCgUEBgIBAxIE6wEWFwoNCgUEBgIBCBIE6wEYQAoQCggEBgIBCJwIABIE6wEZP2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::Dataset::Dataset ===
    # Fields for Dataset
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.financialservices.v1.Dataset.LabelsEntry)
    # Field: table_specs Type: 11 (.google.cloud.financialservices.v1.Dataset.TableSpecsEntry)
    # Field: state Type: 14 (.google.cloud.financialservices.v1.Dataset.State)
    # Field: date_range Type: 11 (.google.type.Interval)
    # Field: time_zone Type: 11 (.google.type.TimeZone)

# Enum: Dataset::State
our $Dataset_STATE_UNSPECIFIED = 0;
our $Dataset_CREATING = 1;
our $Dataset_ACTIVE = 2;
our $Dataset_UPDATING = 3;
our $Dataset_DELETING = 4;

# === Message: Google::Cloud::Financialservices::V1::Dataset::ListDatasetsRequest ===
    # Fields for ListDatasetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Dataset::ListDatasetsResponse ===
    # Fields for ListDatasetsResponse
    # Field: datasets Type: 11 (.google.cloud.financialservices.v1.Dataset)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Dataset::GetDatasetRequest ===
    # Fields for GetDatasetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Dataset::CreateDatasetRequest ===
    # Fields for CreateDatasetRequest
    # Field: parent Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: dataset Type: 11 (.google.cloud.financialservices.v1.Dataset)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Dataset::UpdateDatasetRequest ===
    # Fields for UpdateDatasetRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: dataset Type: 11 (.google.cloud.financialservices.v1.Dataset)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Dataset::DeleteDatasetRequest ===
    # Fields for DeleteDatasetRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::Dataset - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/dataset.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::Dataset;

    my $msg = Google::Cloud::Financialservices::V1::Dataset::Dataset->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::Dataset::Dataset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/dataset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::Dataset::Dataset

The Dataset resource contains summary information about a dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the Dataset.
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/datasets/{dataset}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of creation of this resource.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of the most recent update of this resource.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Dataset::Dataset::LabelsEntry>)

Labels

=item * C<< $msg->table_specs() >> / C<< $msg->table_specs($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Dataset::Dataset::TableSpecsEntry>)

Required. The set of BigQuery tables in the dataset.  The key should be the
table type and the value should be the BigQuery tables in the format
`bq://{project}.{dataset}.{table}`.
Current table types are:

  * `party`
  * `account_party_link`
  * `transaction`
  * `risk_case_event`
  * `party_supplementary_data`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::Dataset::State>)

Output only. State of the dataset (creating, active, deleting, etc.)

=item * C<< $msg->date_range() >> / C<< $msg->date_range($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

Required. Core time window of the dataset. All tables should have complete
data covering this period.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<Message> (L<Google::Type::Datetime::TimeZone>)

The timezone of the data, default will act as UTC.

=back

=head3 Enum: Dataset::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Financialservices::V1::Dataset::ListDatasetsRequest

Request for retrieving a paginated list of Dataset resources that meet the
specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Dataset is the Instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of resources to be included in the response. The response
contains a next_page_token, which can be used to retrieve the next page of
resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

In case of paginated results, this is the token that was returned in the
previous ListDatasetResponse. It should be copied here to retrieve the
next page of resources. Empty will give the first page of
ListDatasetRequest, and the last page will return an empty page_token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Specify a filter to narrow search results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::Dataset::ListDatasetsResponse

Response for retrieving a list of Datasets

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->datasets() >> / C<< $msg->datasets($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Dataset::Dataset>)

List of Dataset resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next ListDatasetsRequest to retrieve
the next page of Datasets (empty indicates we are done).

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::Dataset::GetDatasetRequest

Request for retrieving a specific Dataset resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Dataset

=back

=head2 Google::Cloud::Financialservices::V1::Dataset::CreateDatasetRequest

Request for creating a Dataset resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Dataset is the Instance.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The resource id of the dataset

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Dataset::Dataset>)

Required. The dataset that will be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Dataset::UpdateDatasetRequest

Request for updating a Dataset

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Dataset resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Dataset::Dataset>)

Required. The new value of the dataset fields that will be updated
according to the update_mask.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Dataset::DeleteDatasetRequest

Request for deleting a Dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Dataset.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::Dataset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
