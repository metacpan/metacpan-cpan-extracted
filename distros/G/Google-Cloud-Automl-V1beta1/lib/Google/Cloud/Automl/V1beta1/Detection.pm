package Google::Cloud::Automl::V1beta1::Detection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Geometry };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZGV0ZWN0aW9uLnByb3RvEhtnb29nbGUu
Y2xvdWQuYXV0b21sLnYxYmV0YTEaKmdvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS9nZW9t
ZXRyeS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIoQBCh5JbWFnZU9i
amVjdERldGVjdGlvbkFubm90YXRpb24STAoMYm91bmRpbmdfYm94GAEgASgLMikuZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExLkJvdW5kaW5nUG9seVILYm91bmRpbmdCb3gSFAoFc2Nv
cmUYAiABKAJSBXNjb3JlIuABCh1WaWRlb09iamVjdFRyYWNraW5nQW5ub3RhdGlvbhIfCgtp
bnN0YW5jZV9pZBgBIAEoCVIKaW5zdGFuY2VJZBI6Cgt0aW1lX29mZnNldBgCIAEoCzIZLmdv
b2dsZS5wcm90b2J1Zi5EdXJhdGlvblIKdGltZU9mZnNldBJMCgxib3VuZGluZ19ib3gYAyAB
KAsyKS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQm91bmRpbmdQb2x5Ugtib3VuZGlu
Z0JveBIUCgVzY29yZRgEIAEoAlIFc2NvcmUinwMKF0JvdW5kaW5nQm94TWV0cmljc0VudHJ5
EiMKDWlvdV90aHJlc2hvbGQYASABKAJSDGlvdVRocmVzaG9sZBI0ChZtZWFuX2F2ZXJhZ2Vf
cHJlY2lzaW9uGAIgASgCUhRtZWFuQXZlcmFnZVByZWNpc2lvbhKJAQoaY29uZmlkZW5jZV9t
ZXRyaWNzX2VudHJpZXMYAyADKAsySy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQm91
bmRpbmdCb3hNZXRyaWNzRW50cnkuQ29uZmlkZW5jZU1ldHJpY3NFbnRyeVIYY29uZmlkZW5j
ZU1ldHJpY3NFbnRyaWVzGpwBChZDb25maWRlbmNlTWV0cmljc0VudHJ5EjEKFGNvbmZpZGVu
Y2VfdGhyZXNob2xkGAEgASgCUhNjb25maWRlbmNlVGhyZXNob2xkEhYKBnJlY2FsbBgCIAEo
AlIGcmVjYWxsEhwKCXByZWNpc2lvbhgDIAEoAlIJcHJlY2lzaW9uEhkKCGYxX3Njb3JlGAQg
ASgCUgdmMVNjb3JlIq0CCiVJbWFnZU9iamVjdERldGVjdGlvbkV2YWx1YXRpb25NZXRyaWNz
Ej8KHGV2YWx1YXRlZF9ib3VuZGluZ19ib3hfY291bnQYASABKAVSGWV2YWx1YXRlZEJvdW5k
aW5nQm94Q291bnQSdQocYm91bmRpbmdfYm94X21ldHJpY3NfZW50cmllcxgCIAMoCzI0Lmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Cb3VuZGluZ0JveE1ldHJpY3NFbnRyeVIZYm91
bmRpbmdCb3hNZXRyaWNzRW50cmllcxJMCiNib3VuZGluZ19ib3hfbWVhbl9hdmVyYWdlX3By
ZWNpc2lvbhgDIAEoAlIfYm91bmRpbmdCb3hNZWFuQXZlcmFnZVByZWNpc2lvbiLgAgokVmlk
ZW9PYmplY3RUcmFja2luZ0V2YWx1YXRpb25NZXRyaWNzEjIKFWV2YWx1YXRlZF9mcmFtZV9j
b3VudBgBIAEoBVITZXZhbHVhdGVkRnJhbWVDb3VudBI/ChxldmFsdWF0ZWRfYm91bmRpbmdf
Ym94X2NvdW50GAIgASgFUhlldmFsdWF0ZWRCb3VuZGluZ0JveENvdW50EnUKHGJvdW5kaW5n
X2JveF9tZXRyaWNzX2VudHJpZXMYBCADKAsyNC5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuQm91bmRpbmdCb3hNZXRyaWNzRW50cnlSGWJvdW5kaW5nQm94TWV0cmljc0VudHJpZXMS
TAojYm91bmRpbmdfYm94X21lYW5fYXZlcmFnZV9wcmVjaXNpb24YBiABKAJSH2JvdW5kaW5n
Qm94TWVhbkF2ZXJhZ2VQcmVjaXNpb25CmwEKH2NvbS5nb29nbGUuY2xvdWQuYXV0b21sLnYx
YmV0YTFQAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby9hdXRvbWwvYXBpdjFiZXRhMS9hdXRvbWxw
YjthdXRvbWxwYsoCG0dvb2dsZVxDbG91ZFxBdXRvTWxcVjFiZXRhMeoCHkdvb2dsZTo6Q2xv
dWQ6OkF1dG9NTDo6VjFiZXRhMUqUKwoHEgUOAIUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
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
aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgA0CgkKAgMBEgMTACgKCAoBCBIDFQBO
CgkKAggLEgMVAE4KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA4CgkKAggBEgMXADgK
CAoBCBIDGAA4CgkKAggpEgMYADgKCAoBCBIDGQA3CgkKAggtEgMZADcKPAoCBAASBBwAIwEa
MCBBbm5vdGF0aW9uIGRldGFpbHMgZm9yIGltYWdlIG9iamVjdCBkZXRlY3Rpb24uCgoKCgME
AAESAxwIJgpLCgQEAAIAEgMeAiAaPiBPdXRwdXQgb25seS4gVGhlIHJlY3RhbmdsZSByZXBy
ZXNlbnRpbmcgdGhlIG9iamVjdCBsb2NhdGlvbi4KCgwKBQQAAgAGEgMeAg4KDAoFBAACAAES
Ax4PGwoMCgUEAAIAAxIDHh4fCqEBCgQEAAIBEgMiAhIakwEgT3V0cHV0IG9ubHkuIFRoZSBj
b25maWRlbmNlIHRoYXQgdGhpcyBhbm5vdGF0aW9uIGlzIHBvc2l0aXZlIGZvciB0aGUgcGFy
ZW50IGV4YW1wbGUsCiB2YWx1ZSBpbiBbMCwgMV0sIGhpZ2hlciBtZWFucyBoaWdoZXIgcG9z
aXRpdml0eSBjb25maWRlbmNlLgoKDAoFBAACAQUSAyICBwoMCgUEAAIBARIDIggNCgwKBQQA
AgEDEgMiEBEKOwoCBAESBCYAPgEaLyBBbm5vdGF0aW9uIGRldGFpbHMgZm9yIHZpZGVvIG9i
amVjdCB0cmFja2luZy4KCgoKAwQBARIDJgglCrYDCgQEAQIAEgMuAhkaqAMgT3B0aW9uYWwu
IFRoZSBpbnN0YW5jZSBvZiB0aGUgb2JqZWN0LCBleHByZXNzZWQgYXMgYSBwb3NpdGl2ZSBp
bnRlZ2VyLiBVc2VkIHRvIHRlbGwKIGFwYXJ0IG9iamVjdHMgb2YgdGhlIHNhbWUgdHlwZSAo
aS5lLiBBbm5vdGF0aW9uU3BlYykgd2hlbiBtdWx0aXBsZSBhcmUKIHByZXNlbnQgb24gYSBz
aW5nbGUgZXhhbXBsZS4KIE5PVEU6IEluc3RhbmNlIElEIHByZWRpY3Rpb24gcXVhbGl0eSBp
cyBub3QgYSBwYXJ0IG9mIG1vZGVsIGV2YWx1YXRpb24gYW5kCiBpcyBkb25lIGFzIGJlc3Qg
ZWZmb3J0LiBFc3BlY2lhbGx5IGluIGNhc2VzIHdoZW4gYW4gZW50aXR5IGdvZXMKIG9mZi1z
Y3JlZW4gZm9yIGEgbG9uZ2VyIHRpbWUgKG1pbnV0ZXMpLCB3aGVuIGl0IGNvbWVzIGJhY2sg
aXQgbWF5IGJlIGdpdmVuCiBhIG5ldyBpbnN0YW5jZSBJRC4KCgwKBQQBAgAFEgMuAggKDAoF
BAECAAESAy4JFAoMCgUEAQIAAxIDLhcYCosBCgQEAQIBEgMyAisafiBSZXF1aXJlZC4gQSB0
aW1lIChmcmFtZSkgb2YgYSB2aWRlbyB0byB3aGljaCB0aGlzIGFubm90YXRpb24gcGVydGFp
bnMuCiBSZXByZXNlbnRlZCBhcyB0aGUgZHVyYXRpb24gc2luY2UgdGhlIHZpZGVvJ3Mgc3Rh
cnQuCgoMCgUEAQIBBhIDMgIaCgwKBQQBAgEBEgMyGyYKDAoFBAECAQMSAzIpKgp9CgQEAQIC
EgM2AiAacCBSZXF1aXJlZC4gVGhlIHJlY3RhbmdsZSByZXByZXNlbnRpbmcgdGhlIG9iamVj
dCBsb2NhdGlvbiBvbiB0aGUgZnJhbWUgKGkuZS4KIGF0IHRoZSB0aW1lX29mZnNldCBvZiB0
aGUgdmlkZW8pLgoKDAoFBAECAgYSAzYCDgoMCgUEAQICARIDNg8bCgwKBQQBAgIDEgM2Hh8K
vQIKBAQBAgMSAz0CEhqvAiBPdXRwdXQgb25seS4gVGhlIGNvbmZpZGVuY2UgdGhhdCB0aGlz
IGFubm90YXRpb24gaXMgcG9zaXRpdmUgZm9yIHRoZSB2aWRlbyBhdAogdGhlIHRpbWVfb2Zm
c2V0LCB2YWx1ZSBpbiBbMCwgMV0sIGhpZ2hlciBtZWFucyBoaWdoZXIgcG9zaXRpdml0eQog
Y29uZmlkZW5jZS4gRm9yIGFubm90YXRpb25zIGNyZWF0ZWQgYnkgdGhlIHVzZXIgdGhlIHNj
b3JlIGlzIDEuIFdoZW4KIHVzZXIgYXBwcm92ZXMgYW4gYW5ub3RhdGlvbiwgdGhlIG9yaWdp
bmFsIGZsb2F0IHNjb3JlIGlzIGtlcHQgKGFuZCBub3QKIGNoYW5nZWQgdG8gMSkuCgoMCgUE
AQIDBRIDPQIHCgwKBQQBAgMBEgM9CA0KDAoFBAECAwMSAz0QEQqSAQoCBAISBEIAXQEahQEg
Qm91bmRpbmcgYm94IG1hdGNoaW5nIG1vZGVsIG1ldHJpY3MgZm9yIGEgc2luZ2xlIGludGVy
c2VjdGlvbi1vdmVyLXVuaW9uCiB0aHJlc2hvbGQgYW5kIG11bHRpcGxlIGxhYmVsIG1hdGNo
IGNvbmZpZGVuY2UgdGhyZXNob2xkcy4KCgoKAwQCARIDQggfCjoKBAQCAwASBEQCUAMaLCBN
ZXRyaWNzIGZvciBhIHNpbmdsZSBjb25maWRlbmNlIHRocmVzaG9sZC4KCgwKBQQCAwABEgNE
CiAKWQoGBAIDAAIAEgNGBCMaSiBPdXRwdXQgb25seS4gVGhlIGNvbmZpZGVuY2UgdGhyZXNo
b2xkIHZhbHVlIHVzZWQgdG8gY29tcHV0ZSB0aGUgbWV0cmljcy4KCg4KBwQCAwACAAUSA0YE
CQoOCgcEAgMAAgABEgNGCh4KDgoHBAIDAAIAAxIDRiEiCkoKBgQCAwACARIDSQQVGjsgT3V0
cHV0IG9ubHkuIFJlY2FsbCB1bmRlciB0aGUgZ2l2ZW4gY29uZmlkZW5jZSB0aHJlc2hvbGQu
CgoOCgcEAgMAAgEFEgNJBAkKDgoHBAIDAAIBARIDSQoQCg4KBwQCAwACAQMSA0kTFApNCgYE
AgMAAgISA0wEGBo+IE91dHB1dCBvbmx5LiBQcmVjaXNpb24gdW5kZXIgdGhlIGdpdmVuIGNv
bmZpZGVuY2UgdGhyZXNob2xkLgoKDgoHBAIDAAICBRIDTAQJCg4KBwQCAwACAgESA0wKEwoO
CgcEAgMAAgIDEgNMFhcKSAoGBAIDAAIDEgNPBBcaOSBPdXRwdXQgb25seS4gVGhlIGhhcm1v
bmljIG1lYW4gb2YgcmVjYWxsIGFuZCBwcmVjaXNpb24uCgoOCgcEAgMAAgMFEgNPBAkKDgoH
BAIDAAIDARIDTwoSCg4KBwQCAwACAwMSA08VFgpsCgQEAgIAEgNUAhoaXyBPdXRwdXQgb25s
eS4gVGhlIGludGVyc2VjdGlvbi1vdmVyLXVuaW9uIHRocmVzaG9sZCB2YWx1ZSB1c2VkIHRv
IGNvbXB1dGUKIHRoaXMgbWV0cmljcyBlbnRyeS4KCgwKBQQCAgAFEgNUAgcKDAoFBAICAAES
A1QIFQoMCgUEAgIAAxIDVBgZClMKBAQCAgESA1cCIxpGIE91dHB1dCBvbmx5LiBUaGUgbWVh
biBhdmVyYWdlIHByZWNpc2lvbiwgbW9zdCBvZnRlbiBjbG9zZSB0byBhdV9wcmMuCgoMCgUE
AgIBBRIDVwIHCgwKBQQCAgEBEgNXCB4KDAoFBAICAQMSA1chIgqqAQoEBAICAhIDXAJBGpwB
IE91dHB1dCBvbmx5LiBNZXRyaWNzIGZvciBlYWNoIGxhYmVsLW1hdGNoIGNvbmZpZGVuY2Vf
dGhyZXNob2xkIGZyb20KIDAuMDUsMC4xMCwuLi4sMC45NSwwLjk2LDAuOTcsMC45OCwwLjk5
LiBQcmVjaXNpb24tcmVjYWxsIGN1cnZlIGlzCiBkZXJpdmVkIGZyb20gdGhlbS4KCgwKBQQC
AgIEEgNcAgoKDAoFBAICAgYSA1wLIQoMCgUEAgICARIDXCI8CgwKBQQCAgIDEgNcP0AKhAEK
AgQDEgRhAG8BGnggTW9kZWwgZXZhbHVhdGlvbiBtZXRyaWNzIGZvciBpbWFnZSBvYmplY3Qg
ZGV0ZWN0aW9uIHByb2JsZW1zLgogRXZhbHVhdGVzIHByZWRpY3Rpb24gcXVhbGl0eSBvZiBs
YWJlbGVkIGJvdW5kaW5nIGJveGVzLgoKCgoDBAMBEgNhCC0KkwEKBAQDAgASA2QCKRqFASBP
dXRwdXQgb25seS4gVGhlIHRvdGFsIG51bWJlciBvZiBib3VuZGluZyBib3hlcyAoaS5lLiBz
dW1tZWQgb3ZlciBhbGwKIGltYWdlcykgdGhlIGdyb3VuZCB0cnV0aCB1c2VkIHRvIGNyZWF0
ZSB0aGlzIGV2YWx1YXRpb24gaGFkLgoKDAoFBAMCAAUSA2QCBwoMCgUEAwIAARIDZAgkCgwK
BQQDAgADEgNkJygK4wEKBAQDAgESA2oCRBrVASBPdXRwdXQgb25seS4gVGhlIGJvdW5kaW5n
IGJveGVzIG1hdGNoIG1ldHJpY3MgZm9yIGVhY2gKIEludGVyc2VjdGlvbi1vdmVyLXVuaW9u
IHRocmVzaG9sZCAwLjA1LDAuMTAsLi4uLDAuOTUsMC45NiwwLjk3LDAuOTgsMC45OQogYW5k
IGVhY2ggbGFiZWwgY29uZmlkZW5jZSB0aHJlc2hvbGQgMC4wNSwwLjEwLC4uLiwwLjk1LDAu
OTYsMC45NywwLjk4LDAuOTkKIHBhaXIuCgoMCgUEAwIBBBIDagIKCgwKBQQDAgEGEgNqCyIK
DAoFBAMCAQESA2ojPwoMCgUEAwIBAxIDakJDCpkBCgQEAwICEgNuAjAaiwEgT3V0cHV0IG9u
bHkuIFRoZSBzaW5nbGUgbWV0cmljIGZvciBib3VuZGluZyBib3hlcyBldmFsdWF0aW9uOgog
dGhlIG1lYW5fYXZlcmFnZV9wcmVjaXNpb24gYXZlcmFnZWQgb3ZlciBhbGwgYm91bmRpbmdf
Ym94X21ldHJpY3NfZW50cmllcy4KCgwKBQQDAgIFEgNuAgcKDAoFBAMCAgESA24IKwoMCgUE
AwICAxIDbi4vCuEBCgIEBBIFdACFAQEa0wEgTW9kZWwgZXZhbHVhdGlvbiBtZXRyaWNzIGZv
ciB2aWRlbyBvYmplY3QgdHJhY2tpbmcgcHJvYmxlbXMuCiBFdmFsdWF0ZXMgcHJlZGljdGlv
biBxdWFsaXR5IG9mIGJvdGggbGFiZWxlZCBib3VuZGluZyBib3hlcyBhbmQgbGFiZWxlZAog
dHJhY2tzIChpLmUuIHNlcmllcyBvZiBib3VuZGluZyBib3hlcyBzaGFyaW5nIHNhbWUgbGFi
ZWwgYW5kIGluc3RhbmNlIElEKS4KCgoKAwQEARIDdAgsClYKBAQEAgASA3YCIhpJIE91dHB1
dCBvbmx5LiBUaGUgbnVtYmVyIG9mIHZpZGVvIGZyYW1lcyB1c2VkIHRvIGNyZWF0ZSB0aGlz
IGV2YWx1YXRpb24uCgoMCgUEBAIABRIDdgIHCgwKBQQEAgABEgN2CB0KDAoFBAQCAAMSA3Yg
IQqTAQoEBAQCARIDegIpGoUBIE91dHB1dCBvbmx5LiBUaGUgdG90YWwgbnVtYmVyIG9mIGJv
dW5kaW5nIGJveGVzIChpLmUuIHN1bW1lZCBvdmVyIGFsbAogZnJhbWVzKSB0aGUgZ3JvdW5k
IHRydXRoIHVzZWQgdG8gY3JlYXRlIHRoaXMgZXZhbHVhdGlvbiBoYWQuCgoMCgUEBAIBBRID
egIHCgwKBQQEAgEBEgN6CCQKDAoFBAQCAQMSA3onKArkAQoEBAQCAhIEgAECRBrVASBPdXRw
dXQgb25seS4gVGhlIGJvdW5kaW5nIGJveGVzIG1hdGNoIG1ldHJpY3MgZm9yIGVhY2gKIElu
dGVyc2VjdGlvbi1vdmVyLXVuaW9uIHRocmVzaG9sZCAwLjA1LDAuMTAsLi4uLDAuOTUsMC45
NiwwLjk3LDAuOTgsMC45OQogYW5kIGVhY2ggbGFiZWwgY29uZmlkZW5jZSB0aHJlc2hvbGQg
MC4wNSwwLjEwLC4uLiwwLjk1LDAuOTYsMC45NywwLjk4LDAuOTkKIHBhaXIuCgoNCgUEBAIC
BBIEgAECCgoNCgUEBAICBhIEgAELIgoNCgUEBAICARIEgAEjPwoNCgUEBAICAxIEgAFCQwqa
AQoEBAQCAxIEhAECMBqLASBPdXRwdXQgb25seS4gVGhlIHNpbmdsZSBtZXRyaWMgZm9yIGJv
dW5kaW5nIGJveGVzIGV2YWx1YXRpb246CiB0aGUgbWVhbl9hdmVyYWdlX3ByZWNpc2lvbiBh
dmVyYWdlZCBvdmVyIGFsbCBib3VuZGluZ19ib3hfbWV0cmljc19lbnRyaWVzLgoKDQoFBAQC
AwUSBIQBAgcKDQoFBAQCAwESBIQBCCsKDQoFBAQCAwMSBIQBLi9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation ===
    # Fields for ImageObjectDetectionAnnotation
    # Field: bounding_box Type: 11 (.google.cloud.automl.v1beta1.BoundingPoly)
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingAnnotation ===
    # Fields for VideoObjectTrackingAnnotation
    # Field: instance_id Type: 9 ()
    # Field: time_offset Type: 11 (.google.protobuf.Duration)
    # Field: bounding_box Type: 11 (.google.cloud.automl.v1beta1.BoundingPoly)
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry ===
    # Fields for BoundingBoxMetricsEntry
    # Field: iou_threshold Type: 2 ()
    # Field: mean_average_precision Type: 2 ()
    # Field: confidence_metrics_entries Type: 11 (.google.cloud.automl.v1beta1.BoundingBoxMetricsEntry.ConfidenceMetricsEntry)

# === Message: Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionEvaluationMetrics ===
    # Fields for ImageObjectDetectionEvaluationMetrics
    # Field: evaluated_bounding_box_count Type: 5 ()
    # Field: bounding_box_metrics_entries Type: 11 (.google.cloud.automl.v1beta1.BoundingBoxMetricsEntry)
    # Field: bounding_box_mean_average_precision Type: 2 ()

# === Message: Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingEvaluationMetrics ===
    # Fields for VideoObjectTrackingEvaluationMetrics
    # Field: evaluated_frame_count Type: 5 ()
    # Field: evaluated_bounding_box_count Type: 5 ()
    # Field: bounding_box_metrics_entries Type: 11 (.google.cloud.automl.v1beta1.BoundingBoxMetricsEntry)
    # Field: bounding_box_mean_average_precision Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Detection - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/detection.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Detection;

    my $msg = Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation->new({
        bounding_box => $bounding_box,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->bounding_box();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/detection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation

Annotation details for image object detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly>)

Output only. The rectangle representing the object location.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Output only. The confidence that this annotation is positive for the parent example,
value in [0, 1], higher means higher positivity confidence.

=back

=head2 Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingAnnotation

Annotation details for video object tracking.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Optional. The instance of the object, expressed as a positive integer. Used to tell
apart objects of the same type (i.e. AnnotationSpec) when multiple are
present on a single example.
NOTE: Instance ID prediction quality is not a part of model evaluation and
is done as best effort. Especially in cases when an entity goes
off-screen for a longer time (minutes), when it comes back it may be given
a new instance ID.

=item * C<< $msg->time_offset() >> / C<< $msg->time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. A time (frame) of a video to which this annotation pertains.
Represented as the duration since the video's start.

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly>)

Required. The rectangle representing the object location on the frame (i.e.
at the time_offset of the video).

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Output only. The confidence that this annotation is positive for the video at
the time_offset, value in [0, 1], higher means higher positivity
confidence. For annotations created by the user the score is 1. When
user approves an annotation, the original float score is kept (and not
changed to 1).

=back

=head2 Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry

Bounding box matching model metrics for a single intersection-over-union
threshold and multiple label match confidence thresholds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->iou_threshold() >> / C<< $msg->iou_threshold($value) >>

Type: C<Float>

Output only. The intersection-over-union threshold value used to compute
this metrics entry.

=item * C<< $msg->mean_average_precision() >> / C<< $msg->mean_average_precision($value) >>

Type: C<Float>

Output only. The mean average precision, most often close to au_prc.

=item * C<< $msg->confidence_metrics_entries() >> / C<< $msg->confidence_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry::ConfidenceMetricsEntry>)

Output only. Metrics for each label-match confidence_threshold from
0.05,0.10,...,0.95,0.96,0.97,0.98,0.99. Precision-recall curve is
derived from them.

=back

=head2 Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionEvaluationMetrics

Model evaluation metrics for image object detection problems.
Evaluates prediction quality of labeled bounding boxes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluated_bounding_box_count() >> / C<< $msg->evaluated_bounding_box_count($value) >>

Type: C<Int32>

Output only. The total number of bounding boxes (i.e. summed over all
images) the ground truth used to create this evaluation had.

=item * C<< $msg->bounding_box_metrics_entries() >> / C<< $msg->bounding_box_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry>)

Output only. The bounding boxes match metrics for each
Intersection-over-union threshold 0.05,0.10,...,0.95,0.96,0.97,0.98,0.99
and each label confidence threshold 0.05,0.10,...,0.95,0.96,0.97,0.98,0.99
pair.

=item * C<< $msg->bounding_box_mean_average_precision() >> / C<< $msg->bounding_box_mean_average_precision($value) >>

Type: C<Float>

Output only. The single metric for bounding boxes evaluation:
the mean_average_precision averaged over all bounding_box_metrics_entries.

=back

=head2 Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingEvaluationMetrics

Model evaluation metrics for video object tracking problems.
Evaluates prediction quality of both labeled bounding boxes and labeled
tracks (i.e. series of bounding boxes sharing same label and instance ID).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluated_frame_count() >> / C<< $msg->evaluated_frame_count($value) >>

Type: C<Int32>

Output only. The number of video frames used to create this evaluation.

=item * C<< $msg->evaluated_bounding_box_count() >> / C<< $msg->evaluated_bounding_box_count($value) >>

Type: C<Int32>

Output only. The total number of bounding boxes (i.e. summed over all
frames) the ground truth used to create this evaluation had.

=item * C<< $msg->bounding_box_metrics_entries() >> / C<< $msg->bounding_box_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry>)

Output only. The bounding boxes match metrics for each
Intersection-over-union threshold 0.05,0.10,...,0.95,0.96,0.97,0.98,0.99
and each label confidence threshold 0.05,0.10,...,0.95,0.96,0.97,0.98,0.99
pair.

=item * C<< $msg->bounding_box_mean_average_precision() >> / C<< $msg->bounding_box_mean_average_precision($value) >>

Type: C<Float>

Output only. The single metric for bounding boxes evaluation:
the mean_average_precision averaged over all bounding_box_metrics_entries.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Detection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
