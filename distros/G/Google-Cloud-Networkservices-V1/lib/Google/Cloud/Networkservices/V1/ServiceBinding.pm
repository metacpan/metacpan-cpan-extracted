package Google::Cloud::Networkservices::V1::ServiceBinding;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL3NlcnZpY2VfYmluZGluZy5wcm90
bxIfZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLbBAoOU2VydmljZUJpbmRpbmcSFwoEbmFt
ZRgBIAEoCUID4EEIUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0
aW9uEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEksKB3NlcnZpY2UYBSABKAlCMRgB4EEB+kEp
CidzZXJ2aWNlZGlyZWN0b3J5Lmdvb2dsZWFwaXMuY29tL1NlcnZpY2VSB3NlcnZpY2USJAoK
c2VydmljZV9pZBgIIAEoCUIFGAHgQQNSCXNlcnZpY2VJZBJYCgZsYWJlbHMYByADKAsyOy5n
b29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLlNlcnZpY2VCaW5kaW5nLkxhYmVsc0Vu
dHJ5QgPgQQFSBmxhYmVscxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2
YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOn3qQXoKLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlz
LmNvbS9TZXJ2aWNlQmluZGluZxJJcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L3NlcnZpY2VCaW5kaW5ncy97c2VydmljZV9iaW5kaW5nfSKnAQoaTGlzdFNlcnZp
Y2VCaW5kaW5nc1JlcXVlc3QSTQoGcGFyZW50GAEgASgJQjXgQQL6QS8SLW5ldHdvcmtzZXJ2
aWNlcy5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlQmluZGluZ1IGcGFyZW50EhsKCXBhZ2Vfc2l6
ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIsMBChtM
aXN0U2VydmljZUJpbmRpbmdzUmVzcG9uc2USWgoQc2VydmljZV9iaW5kaW5ncxgBIAMoCzIv
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuU2VydmljZUJpbmRpbmdSD3NlcnZp
Y2VCaW5kaW5ncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoL
dW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlImUKGEdldFNlcnZpY2VCaW5kaW5nUmVx
dWVzdBJJCgRuYW1lGAEgASgJQjXgQQL6QS8KLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlz
LmNvbS9TZXJ2aWNlQmluZGluZ1IEbmFtZSL+AQobQ3JlYXRlU2VydmljZUJpbmRpbmdSZXF1
ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC+kEvEi1uZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBp
cy5jb20vU2VydmljZUJpbmRpbmdSBnBhcmVudBIxChJzZXJ2aWNlX2JpbmRpbmdfaWQYAiAB
KAlCA+BBAlIQc2VydmljZUJpbmRpbmdJZBJdCg9zZXJ2aWNlX2JpbmRpbmcYAyABKAsyLy5n
b29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLlNlcnZpY2VCaW5kaW5nQgPgQQJSDnNl
cnZpY2VCaW5kaW5nIr4BChtVcGRhdGVTZXJ2aWNlQmluZGluZ1JlcXVlc3QSQAoLdXBkYXRl
X21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1h
c2sSXQoPc2VydmljZV9iaW5kaW5nGAIgASgLMi8uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2
aWNlcy52MS5TZXJ2aWNlQmluZGluZ0ID4EECUg5zZXJ2aWNlQmluZGluZyJoChtEZWxldGVT
ZXJ2aWNlQmluZGluZ1JlcXVlc3QSSQoEbmFtZRgBIAEoCUI14EEC+kEvCi1uZXR3b3Jrc2Vy
dmljZXMuZ29vZ2xlYXBpcy5jb20vU2VydmljZUJpbmRpbmdSBG5hbWVC8wIKI2NvbS5nb29n
bGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxQhNTZXJ2aWNlQmluZGluZ1Byb3RvUAFaTWNs
b3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya3NlcnZpY2VzL2FwaXYxL25ldHdvcmtzZXJ2aWNl
c3BiO25ldHdvcmtzZXJ2aWNlc3BiqgIfR29vZ2xlLkNsb3VkLk5ldHdvcmtTZXJ2aWNlcy5W
McoCH0dvb2dsZVxDbG91ZFxOZXR3b3JrU2VydmljZXNcVjHqAiJHb29nbGU6OkNsb3VkOjpO
ZXR3b3JrU2VydmljZXM6OlYx6kF8CidzZXJ2aWNlZGlyZWN0b3J5Lmdvb2dsZWFwaXMuY29t
L1NlcnZpY2USUXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9uYW1l
c3BhY2VzL3tuYW1lc3BhY2V9L3NlcnZpY2VzL3tzZXJ2aWNlfUr2LwoHEgUOALMBAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkK
AgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGAA8CgkK
AgglEgMYADwKCAoBCBIDGQBkCgkKAggLEgMZAGQKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoB
CBIDGwA0CgkKAggIEgMbADQKCAoBCBIDHAA8CgkKAggBEgMcADwKCAoBCBIDHQA8CgkKAggp
EgMdADwKCAoBCBIDHgA7CgkKAggtEgMeADsKCQoBCBIEHwAiAgoMCgQInQgAEgQfACICCooD
CgIEABIEKwBXARr9AiBTZXJ2aWNlQmluZGluZyBjYW4gYmUgdXNlZCB0bzoKIC0gQmluZCBh
IFNlcnZpY2UgRGlyZWN0b3J5IFNlcnZpY2UgdG8gYmUgdXNlZCBpbiBhIEJhY2tlbmRTZXJ2
aWNlIHJlc291cmNlLgogICBUaGlzIGZlYXR1cmUgd2lsbCBiZSBkZXByZWNhdGVkIHNvb24u
CiAtIEJpbmQgYSBQcml2YXRlIFNlcnZpY2UgQ29ubmVjdCBwcm9kdWNlciBzZXJ2aWNlIHRv
IGJlIHVzZWQgaW4gY29uc3VtZXIKICAgQ2xvdWQgU2VydmljZSBNZXNoIG9yIEFwcGxpY2F0
aW9uIExvYWQgQmFsYW5jZXJzLgogLSBCaW5kIGEgQ2xvdWQgUnVuIHNlcnZpY2UgdG8gYmUg
dXNlZCBpbiBjb25zdW1lciBDbG91ZCBTZXJ2aWNlIE1lc2ggb3IKICAgQXBwbGljYXRpb24g
TG9hZCBCYWxhbmNlcnMuCgoKCgMEAAESAysIFgoLCgMEAAcSBCwCLwQKDQoFBAAHnQgSBCwC
LwQKlQEKBAQAAgASAzMCPRqHASBJZGVudGlmaWVyLiBOYW1lIG9mIHRoZSBTZXJ2aWNlQmlu
ZGluZyByZXNvdXJjZS4gSXQgbWF0Y2hlcyBwYXR0ZXJuCiBgcHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9zZXJ2aWNlQmluZGluZ3MvPHNlcnZpY2VfYmluZGluZ19uYW1lPmAuCgoMCgUEAAIA
BRIDMwIICgwKBQQAAgABEgMzCQ0KDAoFBAACAAMSAzMQEQoMCgUEAAIACBIDMxI8Cg8KCAQA
AgAInAgAEgMzEzsKXgoEBAACARIDNwJCGlEgT3B0aW9uYWwuIEEgZnJlZS10ZXh0IGRlc2Ny
aXB0aW9uIG9mIHRoZSByZXNvdXJjZS4gTWF4IGxlbmd0aCAxMDI0CiBjaGFyYWN0ZXJzLgoK
DAoFBAACAQUSAzcCCAoMCgUEAAIBARIDNwkUCgwKBQQAAgEDEgM3FxgKDAoFBAACAQgSAzcZ
QQoPCggEAAIBCJwIABIDNxpACkkKBAQAAgISBDoCOzIaOyBPdXRwdXQgb25seS4gVGhlIHRp
bWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgY3JlYXRlZC4KCgwKBQQAAgIGEgM6AhsK
DAoFBAACAgESAzocJwoMCgUEAAICAxIDOiorCgwKBQQAAgIIEgM7BjEKDwoIBAACAgicCAAS
AzsHMApJCgQEAAIDEgQ+Aj8yGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0
aGUgcmVzb3VyY2Ugd2FzIHVwZGF0ZWQuCgoMCgUEAAIDBhIDPgIbCgwKBQQAAgMBEgM+HCcK
DAoFBAACAwMSAz4qKwoMCgUEAAIDCBIDPwYxCg8KCAQAAgMInAgAEgM/BzAK1AEKBAQAAgQS
BEUCSwQaxQEgT3B0aW9uYWwuIFRoZSBmdWxsIFNlcnZpY2UgRGlyZWN0b3J5IFNlcnZpY2Ug
bmFtZSBvZiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9uYW1lc3BhY2Vz
Lyovc2VydmljZXMvKmAuCiBUaGlzIGZpZWxkIGlzIGZvciBTZXJ2aWNlIERpcmVjdG9yeSBp
bnRlZ3JhdGlvbiB3aGljaCB3aWxsIGJlIGRlcHJlY2F0ZWQKIHNvb24uCgoMCgUEAAIEBRID
RQIICgwKBQQAAgQBEgNFCRAKDAoFBAACBAMSA0UTFAoNCgUEAAIECBIERRVLAwoNCgYEAAIE
CAMSA0YEFQoPCggEAAIECJwIABIDRwQqCg8KBwQAAgQInwgSBEgESgUK5AIKBAQAAgUSBFIC
U0Ua1QIgT3V0cHV0IG9ubHkuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgU2Vydmlj
ZSBEaXJlY3RvcnkgU2VydmljZSBhZ2FpbnN0CiB3aGljaCB0aGUgU2VydmljZUJpbmRpbmcg
cmVzb3VyY2UgaXMgdmFsaWRhdGVkLiBUaGlzIGlzIHBvcHVsYXRlZCB3aGVuIHRoZQogU2Vy
dmljZSBCaW5kaW5nIHJlc291cmNlIGlzIHVzZWQgaW4gYW5vdGhlciByZXNvdXJjZSAobGlr
ZSBCYWNrZW5kCiBTZXJ2aWNlKS4gVGhpcyBpcyBvZiB0aGUgVVVJRDQgZm9ybWF0LiBUaGlz
IGZpZWxkIGlzIGZvciBTZXJ2aWNlIERpcmVjdG9yeQogaW50ZWdyYXRpb24gd2hpY2ggd2ls
bCBiZSBkZXByZWNhdGVkIHNvb24uCgoMCgUEAAIFBRIDUgIICgwKBQQAAgUBEgNSCRMKDAoF
BAACBQMSA1IWFwoMCgUEAAIFCBIDUwZECg0KBgQAAgUIAxIDUwcYCg8KCAQAAgUInAgAEgNT
GkMKVwoEBAACBhIDVgJKGkogT3B0aW9uYWwuIFNldCBvZiBsYWJlbCB0YWdzIGFzc29jaWF0
ZWQgd2l0aCB0aGUgU2VydmljZUJpbmRpbmcgcmVzb3VyY2UuCgoMCgUEAAIGBhIDVgIVCgwK
BQQAAgYBEgNWFhwKDAoFBAACBgMSA1YfIAoMCgUEAAIGCBIDViFJCg8KCAQAAgYInAgAEgNW
IkgKPwoCBAESBFoAawEaMyBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgTGlzdFNlcnZpY2VCaW5k
aW5ncyBtZXRob2QuCgoKCgMEAQESA1oIIgqXAQoEBAECABIEXQJiBBqIASBSZXF1aXJlZC4g
VGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZyb20gd2hpY2ggdGhlIFNlcnZpY2VCaW5kaW5n
cyBzaG91bGQgYmUKIGxpc3RlZCwgc3BlY2lmaWVkIGluIHRoZSBmb3JtYXQgYHByb2plY3Rz
LyovbG9jYXRpb25zLypgLgoKDAoFBAECAAUSA10CCAoMCgUEAQIAARIDXQkPCgwKBQQBAgAD
EgNdEhMKDQoFBAECAAgSBF0UYgMKDwoIBAECAAicCAASA14EKgoPCgcEAQIACJ8IEgRfBGEF
CkQKBAQBAgESA2UCFho3IE1heGltdW0gbnVtYmVyIG9mIFNlcnZpY2VCaW5kaW5ncyB0byBy
ZXR1cm4gcGVyIGNhbGwuCgoMCgUEAQIBBRIDZQIHCgwKBQQBAgEBEgNlCBEKDAoFBAECAQMS
A2UUFQrMAQoEBAECAhIDagIYGr4BIFRoZSB2YWx1ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBg
TGlzdFNlcnZpY2VCaW5kaW5nc1Jlc3BvbnNlYAogSW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBh
IGNvbnRpbnVhdGlvbiBvZiBhIHByaW9yIGBMaXN0Um91dGVyc2AgY2FsbCwKIGFuZCB0aGF0
IHRoZSBzeXN0ZW0gc2hvdWxkIHJldHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoMCgUE
AQICBRIDagIICgwKBQQBAgIBEgNqCRMKDAoFBAECAgMSA2oWFwpCCgIEAhIEbgB7ARo2IFJl
c3BvbnNlIHJldHVybmVkIGJ5IHRoZSBMaXN0U2VydmljZUJpbmRpbmdzIG1ldGhvZC4KCgoK
AwQCARIDbggjCjAKBAQCAgASA3ACLxojIExpc3Qgb2YgU2VydmljZUJpbmRpbmcgcmVzb3Vy
Y2VzLgoKDAoFBAICAAQSA3ACCgoMCgUEAgIABhIDcAsZCgwKBQQCAgABEgNwGioKDAoFBAIC
AAMSA3AtLgroAQoEBAICARIDdQIdGtoBIElmIHRoZXJlIG1pZ2h0IGJlIG1vcmUgcmVzdWx0
cyB0aGFuIHRob3NlIGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBgbmV4dF9w
YWdlX3Rva2VuYCBpcyBpbmNsdWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiByZXN1bHRz
LCBjYWxsIHRoaXMKIG1ldGhvZCBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgYG5leHRfcGFn
ZV90b2tlbmAgYXMgYHBhZ2VfdG9rZW5gLgoKDAoFBAICAQUSA3UCCAoMCgUEAgIBARIDdQkY
CgwKBQQCAgEDEgN1GxwKtAEKBAQCAgISA3oCIhqmASBVbnJlYWNoYWJsZSByZXNvdXJjZXMu
IFBvcHVsYXRlZCB3aGVuIHRoZSByZXF1ZXN0IGF0dGVtcHRzIHRvIGxpc3QgYWxsCiByZXNv
dXJjZXMgYWNyb3NzIGFsbCBzdXBwb3J0ZWQgbG9jYXRpb25zLCB3aGlsZSBzb21lIGxvY2F0
aW9ucyBhcmUKIHRlbXBvcmFyaWx5IHVuYXZhaWxhYmxlLgoKDAoFBAICAgQSA3oCCgoMCgUE
AgICBRIDegsRCgwKBQQCAgIBEgN6Eh0KDAoFBAICAgMSA3ogIQo8CgIEAxIFfgCHAQEaLyBS
ZXF1ZXN0IHVzZWQgYnkgdGhlIEdldFNlcnZpY2VCaW5kaW5nIG1ldGhvZC4KCgoKAwQDARID
fgggCoMBCgQEAwIAEgaBAQKGAQQacyBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBTZXJ2aWNl
QmluZGluZyB0byBnZXQuIE11c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9j
YXRpb25zLyovc2VydmljZUJpbmRpbmdzLypgLgoKDQoFBAMCAAUSBIEBAggKDQoFBAMCAAES
BIEBCQ0KDQoFBAMCAAMSBIEBEBEKDwoFBAMCAAgSBoEBEoYBAwoQCggEAwIACJwIABIEggEE
KgoRCgcEAwIACJ8IEgaDAQSFAQUKOgoCBAQSBooBAJkBARosIFJlcXVlc3QgdXNlZCBieSB0
aGUgU2VydmljZUJpbmRpbmcgbWV0aG9kLgoKCwoDBAQBEgSKAQgjCncKBAQEAgASBo0BApIB
BBpnIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBTZXJ2aWNlQmluZGlu
Zy4gTXVzdCBiZSBpbiB0aGUKIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKmAuCgoN
CgUEBAIABRIEjQECCAoNCgUEBAIAARIEjQEJDwoNCgUEBAIAAxIEjQESEwoPCgUEBAIACBIG
jQEUkgEDChAKCAQEAgAInAgAEgSOAQQqChEKBwQEAgAInwgSBo8BBJEBBQpSCgQEBAIBEgSV
AQJJGkQgUmVxdWlyZWQuIFNob3J0IG5hbWUgb2YgdGhlIFNlcnZpY2VCaW5kaW5nIHJlc291
cmNlIHRvIGJlIGNyZWF0ZWQuCgoNCgUEBAIBBRIElQECCAoNCgUEBAIBARIElQEJGwoNCgUE
BAIBAxIElQEeHwoNCgUEBAIBCBIElQEgSAoQCggEBAIBCJwIABIElQEhRwpACgQEBAICEgSY
AQJOGjIgUmVxdWlyZWQuIFNlcnZpY2VCaW5kaW5nIHJlc291cmNlIHRvIGJlIGNyZWF0ZWQu
CgoNCgUEBAICBhIEmAECEAoNCgUEBAICARIEmAERIAoNCgUEBAICAxIEmAEjJAoNCgUEBAIC
CBIEmAElTQoQCggEBAICCJwIABIEmAEmTApACgIEBRIGnAEApwEBGjIgUmVxdWVzdCB1c2Vk
IGJ5IHRoZSBVcGRhdGVTZXJ2aWNlQmluZGluZyBtZXRob2QuCgoLCgMEBQESBJwBCCMK4AIK
BAQFAgASBqIBAqMBLxrPAiBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1c2VkIHRvIHNwZWNp
ZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIFNlcnZpY2VCaW5kaW5n
IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUg
dXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVs
bCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhl
IG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBm
aWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCg0KBQQFAgAGEgSiAQIbCg0KBQQFAgABEgSi
ARwnCg0KBQQFAgADEgSiASorCg0KBQQFAgAIEgSjAQYuChAKCAQFAgAInAgAEgSjAQctCjoK
BAQFAgESBKYBAk4aLCBSZXF1aXJlZC4gVXBkYXRlZCBTZXJ2aWNlQmluZGluZyByZXNvdXJj
ZS4KCg0KBQQFAgEGEgSmAQIQCg0KBQQFAgEBEgSmAREgCg0KBQQFAgEDEgSmASMkCg0KBQQF
AgEIEgSmASVNChAKCAQFAgEInAgAEgSmASZMCkAKAgQGEgaqAQCzAQEaMiBSZXF1ZXN0IHVz
ZWQgYnkgdGhlIERlbGV0ZVNlcnZpY2VCaW5kaW5nIG1ldGhvZC4KCgsKAwQGARIEqgEIIwqG
AQoEBAYCABIGrQECsgEEGnYgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgU2VydmljZUJpbmRp
bmcgdG8gZGVsZXRlLiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL3NlcnZpY2VCaW5kaW5ncy8qYC4KCg0KBQQGAgAFEgStAQIICg0KBQQGAgABEgSt
AQkNCg0KBQQGAgADEgStARARCg8KBQQGAgAIEgatARKyAQMKEAoIBAYCAAicCAASBK4BBCoK
EQoHBAYCAAifCBIGrwEEsQEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding ===
    # Fields for ServiceBinding
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: service Type: 9 ()
    # Field: service_id Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.ServiceBinding.LabelsEntry)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<description>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<service>

Type: String

=item * B<service_id>

Type: String

=item * B<labels>

Type: Message (.google.cloud.networkservices.v1.ServiceBinding.LabelsEntry)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsRequest ===
    # Fields for ListServiceBindingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsResponse ===
    # Fields for ListServiceBindingsResponse
    # Field: service_bindings Type: 11 (.google.cloud.networkservices.v1.ServiceBinding)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsResponse->new(
        service_bindings => $value,
    );

=head1 FIELDS

=over 4

=item * B<service_bindings>

Type: Message (.google.cloud.networkservices.v1.ServiceBinding)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::GetServiceBindingRequest ===
    # Fields for GetServiceBindingRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::GetServiceBindingRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::GetServiceBindingRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::CreateServiceBindingRequest ===
    # Fields for CreateServiceBindingRequest
    # Field: parent Type: 9 ()
    # Field: service_binding_id Type: 9 ()
    # Field: service_binding Type: 11 (.google.cloud.networkservices.v1.ServiceBinding)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::CreateServiceBindingRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::CreateServiceBindingRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<service_binding_id>

Type: String

=item * B<service_binding>

Type: Message (.google.cloud.networkservices.v1.ServiceBinding)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::UpdateServiceBindingRequest ===
    # Fields for UpdateServiceBindingRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: service_binding Type: 11 (.google.cloud.networkservices.v1.ServiceBinding)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::UpdateServiceBindingRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::UpdateServiceBindingRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<service_binding>

Type: Message (.google.cloud.networkservices.v1.ServiceBinding)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::ServiceBinding::DeleteServiceBindingRequest ===
    # Fields for DeleteServiceBindingRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::DeleteServiceBindingRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::ServiceBinding;

    my $msg = Google::Cloud::Networkservices::V1::ServiceBinding::DeleteServiceBindingRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
