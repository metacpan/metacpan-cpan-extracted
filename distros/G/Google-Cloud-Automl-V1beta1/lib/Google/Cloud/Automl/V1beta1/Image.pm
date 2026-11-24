package Google::Cloud::Automl::V1beta1::Image;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::AnnotationSpec };
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvaW1hZ2UucHJvdG8SG2dvb2dsZS5jbG91
ZC5hdXRvbWwudjFiZXRhMRoxZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2Fubm90YXRp
b25fc3BlYy5wcm90bxowZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2NsYXNzaWZpY2F0
aW9uLnByb3RvIoYBCiJJbWFnZUNsYXNzaWZpY2F0aW9uRGF0YXNldE1ldGFkYXRhEmAKE2Ns
YXNzaWZpY2F0aW9uX3R5cGUYASABKA4yLy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEu
Q2xhc3NpZmljYXRpb25UeXBlUhJjbGFzc2lmaWNhdGlvblR5cGUiJQojSW1hZ2VPYmplY3RE
ZXRlY3Rpb25EYXRhc2V0TWV0YWRhdGEiggIKIEltYWdlQ2xhc3NpZmljYXRpb25Nb2RlbE1l
dGFkYXRhEiIKDWJhc2VfbW9kZWxfaWQYASABKAlSC2Jhc2VNb2RlbElkEiEKDHRyYWluX2J1
ZGdldBgCIAEoA1ILdHJhaW5CdWRnZXQSHQoKdHJhaW5fY29zdBgDIAEoA1IJdHJhaW5Db3N0
Eh8KC3N0b3BfcmVhc29uGAUgASgJUgpzdG9wUmVhc29uEh0KCm1vZGVsX3R5cGUYByABKAlS
CW1vZGVsVHlwZRIZCghub2RlX3FwcxgNIAEoAVIHbm9kZVFwcxIdCgpub2RlX2NvdW50GA4g
ASgDUglub2RlQ291bnQinQIKIUltYWdlT2JqZWN0RGV0ZWN0aW9uTW9kZWxNZXRhZGF0YRId
Cgptb2RlbF90eXBlGAEgASgJUgltb2RlbFR5cGUSHQoKbm9kZV9jb3VudBgDIAEoA1IJbm9k
ZUNvdW50EhkKCG5vZGVfcXBzGAQgASgBUgdub2RlUXBzEh8KC3N0b3BfcmVhc29uGAUgASgJ
UgpzdG9wUmVhc29uEkAKHXRyYWluX2J1ZGdldF9taWxsaV9ub2RlX2hvdXJzGAYgASgDUhl0
cmFpbkJ1ZGdldE1pbGxpTm9kZUhvdXJzEjwKG3RyYWluX2Nvc3RfbWlsbGlfbm9kZV9ob3Vy
cxgHIAEoA1IXdHJhaW5Db3N0TWlsbGlOb2RlSG91cnMiSwoqSW1hZ2VDbGFzc2lmaWNhdGlv
bk1vZGVsRGVwbG95bWVudE1ldGFkYXRhEh0KCm5vZGVfY291bnQYASABKANSCW5vZGVDb3Vu
dCJMCitJbWFnZU9iamVjdERldGVjdGlvbk1vZGVsRGVwbG95bWVudE1ldGFkYXRhEh0KCm5v
ZGVfY291bnQYASABKANSCW5vZGVDb3VudEKnAQofY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwu
djFiZXRhMUIKSW1hZ2VQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2
MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx
6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSvVKCgcSBQ4AvQEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSADsKCQoCAwES
AxMAOgoICgEIEgMVAE4KCQoCCAsSAxUATgoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ACsKCQoCCAgSAxcAKwoICgEIEgMYADgKCQoCCAESAxgAOAoICgEIEgMZADgKCQoCCCkSAxkA
OAoICgEIEgMaADcKCQoCCC0SAxoANwpICgIEABIEHQAgARo8IERhdGFzZXQgbWV0YWRhdGEg
dGhhdCBpcyBzcGVjaWZpYyB0byBpbWFnZSBjbGFzc2lmaWNhdGlvbi4KCgoKAwQAARIDHQgq
CjwKBAQAAgASAx8CLRovIFJlcXVpcmVkLiBUeXBlIG9mIHRoZSBjbGFzc2lmaWNhdGlvbiBw
cm9ibGVtLgoKDAoFBAACAAYSAx8CFAoMCgUEAAIAARIDHxUoCgwKBQQAAgADEgMfKywKQgoC
BAESBCMAJQEaNiBEYXRhc2V0IG1ldGFkYXRhIHNwZWNpZmljIHRvIGltYWdlIG9iamVjdCBk
ZXRlY3Rpb24uCgoKCgMEAQESAyMIKwo2CgIEAhIEKABoARoqIE1vZGVsIG1ldGFkYXRhIGZv
ciBpbWFnZSBjbGFzc2lmaWNhdGlvbi4KCgoKAwQCARIDKAgoCrcCCgQEAgIAEgMuAhsaqQIg
T3B0aW9uYWwuIFRoZSBJRCBvZiB0aGUgYGJhc2VgIG1vZGVsLiBJZiBpdCBpcyBzcGVjaWZp
ZWQsIHRoZSBuZXcgbW9kZWwKIHdpbGwgYmUgY3JlYXRlZCBiYXNlZCBvbiB0aGUgYGJhc2Vg
IG1vZGVsLiBPdGhlcndpc2UsIHRoZSBuZXcgbW9kZWwgd2lsbCBiZQogY3JlYXRlZCBmcm9t
IHNjcmF0Y2guIFRoZSBgYmFzZWAgbW9kZWwgbXVzdCBiZSBpbiB0aGUgc2FtZQogYHByb2pl
Y3RgIGFuZCBgbG9jYXRpb25gIGFzIHRoZSBuZXcgbW9kZWwgdG8gY3JlYXRlLCBhbmQgaGF2
ZSB0aGUgc2FtZQogYG1vZGVsX3R5cGVgLgoKDAoFBAICAAUSAy4CCAoMCgUEAgIAARIDLgkW
CgwKBQQCAgADEgMuGRoKlgEKBAQCAgESAzICGRqIASBSZXF1aXJlZC4gVGhlIHRyYWluIGJ1
ZGdldCBvZiBjcmVhdGluZyB0aGlzIG1vZGVsLCBleHByZXNzZWQgaW4gaG91cnMuIFRoZQog
YWN0dWFsIGB0cmFpbl9jb3N0YCB3aWxsIGJlIGVxdWFsIG9yIGxlc3MgdGhhbiB0aGlzIHZh
bHVlLgoKDAoFBAICAQUSAzICBwoMCgUEAgIBARIDMggUCgwKBQQCAgEDEgMyFxgKzwEKBAQC
AgISAzcCFxrBASBPdXRwdXQgb25seS4gVGhlIGFjdHVhbCB0cmFpbiBjb3N0IG9mIGNyZWF0
aW5nIHRoaXMgbW9kZWwsIGV4cHJlc3NlZCBpbgogaG91cnMuIElmIHRoaXMgbW9kZWwgaXMg
Y3JlYXRlZCBmcm9tIGEgYGJhc2VgIG1vZGVsLCB0aGUgdHJhaW4gY29zdCB1c2VkCiB0byBj
cmVhdGUgdGhlIGBiYXNlYCBtb2RlbCBhcmUgbm90IGluY2x1ZGVkLgoKDAoFBAICAgUSAzcC
BwoMCgUEAgICARIDNwgSCgwKBQQCAgIDEgM3FRYKewoEBAICAxIDOwIZGm4gT3V0cHV0IG9u
bHkuIFRoZSByZWFzb24gdGhhdCB0aGlzIGNyZWF0ZSBtb2RlbCBvcGVyYXRpb24gc3RvcHBl
ZCwKIGUuZy4gYEJVREdFVF9SRUFDSEVEYCwgYE1PREVMX0NPTlZFUkdFRGAuCgoMCgUEAgID
BRIDOwIICgwKBQQCAgMBEgM7CRQKDAoFBAICAwMSAzsXGAqREwoEBAICBBIDXgIYGoMTIE9w
dGlvbmFsLiBUeXBlIG9mIHRoZSBtb2RlbC4gVGhlIGF2YWlsYWJsZSB2YWx1ZXMgYXJlOgog
KiAgIGBjbG91ZGAgLSBNb2RlbCB0byBiZSB1c2VkIHZpYSBwcmVkaWN0aW9uIGNhbGxzIHRv
IEF1dG9NTCBBUEkuCiAgICAgICAgICAgICAgIFRoaXMgaXMgdGhlIGRlZmF1bHQgdmFsdWUu
CiAqICAgYG1vYmlsZS1sb3ctbGF0ZW5jeS0xYCAtIEEgbW9kZWwgdGhhdCwgaW4gYWRkaXRp
b24gdG8gcHJvdmlkaW5nCiAgICAgICAgICAgICAgIHByZWRpY3Rpb24gdmlhIEF1dG9NTCBB
UEksIGNhbiBhbHNvIGJlIGV4cG9ydGVkIChzZWUKICAgICAgICAgICAgICAgW0F1dG9NbC5F
eHBvcnRNb2RlbF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkF1dG9NbC5FeHBvcnRN
b2RlbF0pIGFuZCB1c2VkIG9uIGEgbW9iaWxlIG9yIGVkZ2UgZGV2aWNlCiAgICAgICAgICAg
ICAgIHdpdGggVGVuc29yRmxvdyBhZnRlcndhcmRzLiBFeHBlY3RlZCB0byBoYXZlIGxvdyBs
YXRlbmN5LCBidXQKICAgICAgICAgICAgICAgbWF5IGhhdmUgbG93ZXIgcHJlZGljdGlvbiBx
dWFsaXR5IHRoYW4gb3RoZXIgbW9kZWxzLgogKiAgIGBtb2JpbGUtdmVyc2F0aWxlLTFgIC0g
QSBtb2RlbCB0aGF0LCBpbiBhZGRpdGlvbiB0byBwcm92aWRpbmcKICAgICAgICAgICAgICAg
cHJlZGljdGlvbiB2aWEgQXV0b01MIEFQSSwgY2FuIGFsc28gYmUgZXhwb3J0ZWQgKHNlZQog
ICAgICAgICAgICAgICBbQXV0b01sLkV4cG9ydE1vZGVsXVtnb29nbGUuY2xvdWQuYXV0b21s
LnYxYmV0YTEuQXV0b01sLkV4cG9ydE1vZGVsXSkgYW5kIHVzZWQgb24gYSBtb2JpbGUgb3Ig
ZWRnZSBkZXZpY2UKICAgICAgICAgICAgICAgd2l0aCBUZW5zb3JGbG93IGFmdGVyd2FyZHMu
CiAqICAgYG1vYmlsZS1oaWdoLWFjY3VyYWN5LTFgIC0gQSBtb2RlbCB0aGF0LCBpbiBhZGRp
dGlvbiB0byBwcm92aWRpbmcKICAgICAgICAgICAgICAgcHJlZGljdGlvbiB2aWEgQXV0b01M
IEFQSSwgY2FuIGFsc28gYmUgZXhwb3J0ZWQgKHNlZQogICAgICAgICAgICAgICBbQXV0b01s
LkV4cG9ydE1vZGVsXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQXV0b01sLkV4cG9y
dE1vZGVsXSkgYW5kIHVzZWQgb24gYSBtb2JpbGUgb3IgZWRnZSBkZXZpY2UKICAgICAgICAg
ICAgICAgd2l0aCBUZW5zb3JGbG93IGFmdGVyd2FyZHMuICBFeHBlY3RlZCB0byBoYXZlIGEg
aGlnaGVyCiAgICAgICAgICAgICAgIGxhdGVuY3ksIGJ1dCBzaG91bGQgYWxzbyBoYXZlIGEg
aGlnaGVyIHByZWRpY3Rpb24gcXVhbGl0eQogICAgICAgICAgICAgICB0aGFuIG90aGVyIG1v
ZGVscy4KICogICBgbW9iaWxlLWNvcmUtbWwtbG93LWxhdGVuY3ktMWAgLSBBIG1vZGVsIHRo
YXQsIGluIGFkZGl0aW9uIHRvIHByb3ZpZGluZwogICAgICAgICAgICAgICBwcmVkaWN0aW9u
IHZpYSBBdXRvTUwgQVBJLCBjYW4gYWxzbyBiZSBleHBvcnRlZCAoc2VlCiAgICAgICAgICAg
ICAgIFtBdXRvTWwuRXhwb3J0TW9kZWxdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5B
dXRvTWwuRXhwb3J0TW9kZWxdKSBhbmQgdXNlZCBvbiBhIG1vYmlsZSBkZXZpY2Ugd2l0aCBD
b3JlCiAgICAgICAgICAgICAgIE1MIGFmdGVyd2FyZHMuIEV4cGVjdGVkIHRvIGhhdmUgbG93
IGxhdGVuY3ksIGJ1dCBtYXkgaGF2ZQogICAgICAgICAgICAgICBsb3dlciBwcmVkaWN0aW9u
IHF1YWxpdHkgdGhhbiBvdGhlciBtb2RlbHMuCiAqICAgYG1vYmlsZS1jb3JlLW1sLXZlcnNh
dGlsZS0xYCAtIEEgbW9kZWwgdGhhdCwgaW4gYWRkaXRpb24gdG8gcHJvdmlkaW5nCiAgICAg
ICAgICAgICAgIHByZWRpY3Rpb24gdmlhIEF1dG9NTCBBUEksIGNhbiBhbHNvIGJlIGV4cG9y
dGVkIChzZWUKICAgICAgICAgICAgICAgW0F1dG9NbC5FeHBvcnRNb2RlbF1bZ29vZ2xlLmNs
b3VkLmF1dG9tbC52MWJldGExLkF1dG9NbC5FeHBvcnRNb2RlbF0pIGFuZCB1c2VkIG9uIGEg
bW9iaWxlIGRldmljZSB3aXRoIENvcmUKICAgICAgICAgICAgICAgTUwgYWZ0ZXJ3YXJkcy4K
ICogICBgbW9iaWxlLWNvcmUtbWwtaGlnaC1hY2N1cmFjeS0xYCAtIEEgbW9kZWwgdGhhdCwg
aW4gYWRkaXRpb24gdG8KICAgICAgICAgICAgICAgcHJvdmlkaW5nIHByZWRpY3Rpb24gdmlh
IEF1dG9NTCBBUEksIGNhbiBhbHNvIGJlIGV4cG9ydGVkCiAgICAgICAgICAgICAgIChzZWUg
W0F1dG9NbC5FeHBvcnRNb2RlbF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkF1dG9N
bC5FeHBvcnRNb2RlbF0pIGFuZCB1c2VkIG9uIGEgbW9iaWxlIGRldmljZSB3aXRoCiAgICAg
ICAgICAgICAgIENvcmUgTUwgYWZ0ZXJ3YXJkcy4gIEV4cGVjdGVkIHRvIGhhdmUgYSBoaWdo
ZXIgbGF0ZW5jeSwgYnV0CiAgICAgICAgICAgICAgIHNob3VsZCBhbHNvIGhhdmUgYSBoaWdo
ZXIgcHJlZGljdGlvbiBxdWFsaXR5IHRoYW4gb3RoZXIKICAgICAgICAgICAgICAgbW9kZWxz
LgoKDAoFBAICBAUSA14CCAoMCgUEAgIEARIDXgkTCgwKBQQCAgQDEgNeFhcKlwEKBAQCAgUS
A2ICFxqJASBPdXRwdXQgb25seS4gQW4gYXBwcm94aW1hdGUgbnVtYmVyIG9mIG9ubGluZSBw
cmVkaWN0aW9uIFFQUyB0aGF0IGNhbgogYmUgc3VwcG9ydGVkIGJ5IHRoaXMgbW9kZWwgcGVy
IGVhY2ggbm9kZSBvbiB3aGljaCBpdCBpcyBkZXBsb3llZC4KCgwKBQQCAgUFEgNiAggKDAoF
BAICBQESA2IJEQoMCgUEAgIFAxIDYhQWCsQBCgQEAgIGEgNnAhgatgEgT3V0cHV0IG9ubHku
IFRoZSBudW1iZXIgb2Ygbm9kZXMgdGhpcyBtb2RlbCBpcyBkZXBsb3llZCBvbi4gQSBub2Rl
IGlzIGFuCiBhYnN0cmFjdGlvbiBvZiBhIG1hY2hpbmUgcmVzb3VyY2UsIHdoaWNoIGNhbiBo
YW5kbGUgb25saW5lIHByZWRpY3Rpb24gUVBTCiBhcyBnaXZlbiBpbiB0aGUgbm9kZV9xcHMg
ZmllbGQuCgoMCgUEAgIGBRIDZwIHCgwKBQQCAgYBEgNnCBIKDAoFBAICBgMSA2cVFwpBCgIE
AxIFawCnAQEaNCBNb2RlbCBtZXRhZGF0YSBzcGVjaWZpYyB0byBpbWFnZSBvYmplY3QgZGV0
ZWN0aW9uLgoKCgoDBAMBEgNrCCkK+AwKBAQDAgASBIMBAhga6QwgT3B0aW9uYWwuIFR5cGUg
b2YgdGhlIG1vZGVsLiBUaGUgYXZhaWxhYmxlIHZhbHVlcyBhcmU6CiAqICAgYGNsb3VkLWhp
Z2gtYWNjdXJhY3ktMWAgLSAoZGVmYXVsdCkgQSBtb2RlbCB0byBiZSB1c2VkIHZpYSBwcmVk
aWN0aW9uCiAgICAgICAgICAgICAgIGNhbGxzIHRvIEF1dG9NTCBBUEkuIEV4cGVjdGVkIHRv
IGhhdmUgYSBoaWdoZXIgbGF0ZW5jeSwgYnV0CiAgICAgICAgICAgICAgIHNob3VsZCBhbHNv
IGhhdmUgYSBoaWdoZXIgcHJlZGljdGlvbiBxdWFsaXR5IHRoYW4gb3RoZXIKICAgICAgICAg
ICAgICAgbW9kZWxzLgogKiAgIGBjbG91ZC1sb3ctbGF0ZW5jeS0xYCAtICBBIG1vZGVsIHRv
IGJlIHVzZWQgdmlhIHByZWRpY3Rpb24KICAgICAgICAgICAgICAgY2FsbHMgdG8gQXV0b01M
IEFQSS4gRXhwZWN0ZWQgdG8gaGF2ZSBsb3cgbGF0ZW5jeSwgYnV0IG1heQogICAgICAgICAg
ICAgICBoYXZlIGxvd2VyIHByZWRpY3Rpb24gcXVhbGl0eSB0aGFuIG90aGVyIG1vZGVscy4K
ICogICBgbW9iaWxlLWxvdy1sYXRlbmN5LTFgIC0gQSBtb2RlbCB0aGF0LCBpbiBhZGRpdGlv
biB0byBwcm92aWRpbmcKICAgICAgICAgICAgICAgcHJlZGljdGlvbiB2aWEgQXV0b01MIEFQ
SSwgY2FuIGFsc28gYmUgZXhwb3J0ZWQgKHNlZQogICAgICAgICAgICAgICBbQXV0b01sLkV4
cG9ydE1vZGVsXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQXV0b01sLkV4cG9ydE1v
ZGVsXSkgYW5kIHVzZWQgb24gYSBtb2JpbGUgb3IgZWRnZSBkZXZpY2UKICAgICAgICAgICAg
ICAgd2l0aCBUZW5zb3JGbG93IGFmdGVyd2FyZHMuIEV4cGVjdGVkIHRvIGhhdmUgbG93IGxh
dGVuY3ksIGJ1dAogICAgICAgICAgICAgICBtYXkgaGF2ZSBsb3dlciBwcmVkaWN0aW9uIHF1
YWxpdHkgdGhhbiBvdGhlciBtb2RlbHMuCiAqICAgYG1vYmlsZS12ZXJzYXRpbGUtMWAgLSBB
IG1vZGVsIHRoYXQsIGluIGFkZGl0aW9uIHRvIHByb3ZpZGluZwogICAgICAgICAgICAgICBw
cmVkaWN0aW9uIHZpYSBBdXRvTUwgQVBJLCBjYW4gYWxzbyBiZSBleHBvcnRlZCAoc2VlCiAg
ICAgICAgICAgICAgIFtBdXRvTWwuRXhwb3J0TW9kZWxdW2dvb2dsZS5jbG91ZC5hdXRvbWwu
djFiZXRhMS5BdXRvTWwuRXhwb3J0TW9kZWxdKSBhbmQgdXNlZCBvbiBhIG1vYmlsZSBvciBl
ZGdlIGRldmljZQogICAgICAgICAgICAgICB3aXRoIFRlbnNvckZsb3cgYWZ0ZXJ3YXJkcy4K
ICogICBgbW9iaWxlLWhpZ2gtYWNjdXJhY3ktMWAgLSBBIG1vZGVsIHRoYXQsIGluIGFkZGl0
aW9uIHRvIHByb3ZpZGluZwogICAgICAgICAgICAgICBwcmVkaWN0aW9uIHZpYSBBdXRvTUwg
QVBJLCBjYW4gYWxzbyBiZSBleHBvcnRlZCAoc2VlCiAgICAgICAgICAgICAgIFtBdXRvTWwu
RXhwb3J0TW9kZWxdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5BdXRvTWwuRXhwb3J0
TW9kZWxdKSBhbmQgdXNlZCBvbiBhIG1vYmlsZSBvciBlZGdlIGRldmljZQogICAgICAgICAg
ICAgICB3aXRoIFRlbnNvckZsb3cgYWZ0ZXJ3YXJkcy4gIEV4cGVjdGVkIHRvIGhhdmUgYSBo
aWdoZXIKICAgICAgICAgICAgICAgbGF0ZW5jeSwgYnV0IHNob3VsZCBhbHNvIGhhdmUgYSBo
aWdoZXIgcHJlZGljdGlvbiBxdWFsaXR5CiAgICAgICAgICAgICAgIHRoYW4gb3RoZXIgbW9k
ZWxzLgoKDQoFBAMCAAUSBIMBAggKDQoFBAMCAAESBIMBCRMKDQoFBAMCAAMSBIMBFhcKyQEK
BAQDAgESBIgBAhcaugEgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2Ygbm9kZXMgdGhpcyBt
b2RlbCBpcyBkZXBsb3llZCBvbi4gQSBub2RlIGlzIGFuCiBhYnN0cmFjdGlvbiBvZiBhIG1h
Y2hpbmUgcmVzb3VyY2UsIHdoaWNoIGNhbiBoYW5kbGUgb25saW5lIHByZWRpY3Rpb24gUVBT
CiBhcyBnaXZlbiBpbiB0aGUgcXBzX3Blcl9ub2RlIGZpZWxkLgoKDQoFBAMCAQUSBIgBAgcK
DQoFBAMCAQESBIgBCBIKDQoFBAMCAQMSBIgBFRYKmAEKBAQDAgISBIwBAhYaiQEgT3V0cHV0
IG9ubHkuIEFuIGFwcHJveGltYXRlIG51bWJlciBvZiBvbmxpbmUgcHJlZGljdGlvbiBRUFMg
dGhhdCBjYW4KIGJlIHN1cHBvcnRlZCBieSB0aGlzIG1vZGVsIHBlciBlYWNoIG5vZGUgb24g
d2hpY2ggaXQgaXMgZGVwbG95ZWQuCgoNCgUEAwICBRIEjAECCAoNCgUEAwICARIEjAEJEQoN
CgUEAwICAxIEjAEUFQp8CgQEAwIDEgSQAQIZGm4gT3V0cHV0IG9ubHkuIFRoZSByZWFzb24g
dGhhdCB0aGlzIGNyZWF0ZSBtb2RlbCBvcGVyYXRpb24gc3RvcHBlZCwKIGUuZy4gYEJVREdF
VF9SRUFDSEVEYCwgYE1PREVMX0NPTlZFUkdFRGAuCgoNCgUEAwIDBRIEkAECCAoNCgUEAwID
ARIEkAEJFAoNCgUEAwIDAxIEkAEXGArRBwoEBAMCBBIEoQECKhrCByBUaGUgdHJhaW4gYnVk
Z2V0IG9mIGNyZWF0aW5nIHRoaXMgbW9kZWwsIGV4cHJlc3NlZCBpbiBtaWxsaSBub2RlCiBo
b3VycyBpLmUuIDEsMDAwIHZhbHVlIGluIHRoaXMgZmllbGQgbWVhbnMgMSBub2RlIGhvdXIu
IFRoZSBhY3R1YWwKIGB0cmFpbl9jb3N0YCB3aWxsIGJlIGVxdWFsIG9yIGxlc3MgdGhhbiB0
aGlzIHZhbHVlLiBJZiBmdXJ0aGVyIG1vZGVsCiB0cmFpbmluZyBjZWFzZXMgdG8gcHJvdmlk
ZSBhbnkgaW1wcm92ZW1lbnRzLCBpdCB3aWxsIHN0b3Agd2l0aG91dCB1c2luZwogZnVsbCBi
dWRnZXQgYW5kIHRoZSBzdG9wX3JlYXNvbiB3aWxsIGJlIGBNT0RFTF9DT05WRVJHRURgLgog
Tm90ZSwgbm9kZV9ob3VyICA9IGFjdHVhbF9ob3VyICogbnVtYmVyX29mX25vZGVzX2ludm92
bGVkLgogRm9yIG1vZGVsIHR5cGUgYGNsb3VkLWhpZ2gtYWNjdXJhY3ktMWAoZGVmYXVsdCkg
YW5kIGBjbG91ZC1sb3ctbGF0ZW5jeS0xYCwKIHRoZSB0cmFpbiBidWRnZXQgbXVzdCBiZSBi
ZXR3ZWVuIDIwLDAwMCBhbmQgOTAwLDAwMCBtaWxsaSBub2RlIGhvdXJzLAogaW5jbHVzaXZl
LiBUaGUgZGVmYXVsdCB2YWx1ZSBpcyAyMTYsIDAwMCB3aGljaCByZXByZXNlbnRzIG9uZSBk
YXkgaW4KIHdhbGwgdGltZS4KIEZvciBtb2RlbCB0eXBlIGBtb2JpbGUtbG93LWxhdGVuY3kt
MWAsIGBtb2JpbGUtdmVyc2F0aWxlLTFgLAogYG1vYmlsZS1oaWdoLWFjY3VyYWN5LTFgLCBg
bW9iaWxlLWNvcmUtbWwtbG93LWxhdGVuY3ktMWAsCiBgbW9iaWxlLWNvcmUtbWwtdmVyc2F0
aWxlLTFgLCBgbW9iaWxlLWNvcmUtbWwtaGlnaC1hY2N1cmFjeS0xYCwgdGhlIHRyYWluCiBi
dWRnZXQgbXVzdCBiZSBiZXR3ZWVuIDEsMDAwIGFuZCAxMDAsMDAwIG1pbGxpIG5vZGUgaG91
cnMsIGluY2x1c2l2ZS4KIFRoZSBkZWZhdWx0IHZhbHVlIGlzIDI0LCAwMDAgd2hpY2ggcmVw
cmVzZW50cyBvbmUgZGF5IGluIHdhbGwgdGltZS4KCg0KBQQDAgQFEgShAQIHCg0KBQQDAgQB
EgShAQglCg0KBQQDAgQDEgShASgpCskBCgQEAwIFEgSmAQIoGroBIE91dHB1dCBvbmx5LiBU
aGUgYWN0dWFsIHRyYWluIGNvc3Qgb2YgY3JlYXRpbmcgdGhpcyBtb2RlbCwgZXhwcmVzc2Vk
IGluCiBtaWxsaSBub2RlIGhvdXJzLCBpLmUuIDEsMDAwIHZhbHVlIGluIHRoaXMgZmllbGQg
bWVhbnMgMSBub2RlIGhvdXIuCiBHdWFyYW50ZWVkIHRvIG5vdCBleGNlZWQgdGhlIHRyYWlu
IGJ1ZGdldC4KCg0KBQQDAgUFEgSmAQIHCg0KBQQDAgUBEgSmAQgjCg0KBQQDAgUDEgSmASYn
CksKAgQEEgaqAQCyAQEaPSBNb2RlbCBkZXBsb3ltZW50IG1ldGFkYXRhIHNwZWNpZmljIHRv
IEltYWdlIENsYXNzaWZpY2F0aW9uLgoKCwoDBAQBEgSqAQgyCsICCgQEBAIAEgSxAQIXGrMC
IElucHV0IG9ubHkuIFRoZSBudW1iZXIgb2Ygbm9kZXMgdG8gZGVwbG95IHRoZSBtb2RlbCBv
bi4gQSBub2RlIGlzIGFuCiBhYnN0cmFjdGlvbiBvZiBhIG1hY2hpbmUgcmVzb3VyY2UsIHdo
aWNoIGNhbiBoYW5kbGUgb25saW5lIHByZWRpY3Rpb24gUVBTCiBhcyBnaXZlbiBpbiB0aGUg
bW9kZWwncwoKIFtub2RlX3Fwc11bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkltYWdl
Q2xhc3NpZmljYXRpb25Nb2RlbE1ldGFkYXRhLm5vZGVfcXBzXS4KIE11c3QgYmUgYmV0d2Vl
biAxIGFuZCAxMDAsIGluY2x1c2l2ZSBvbiBib3RoIGVuZHMuCgoNCgUEBAIABRIEsQECBwoN
CgUEBAIAARIEsQEIEgoNCgUEBAIAAxIEsQEVFgpNCgIEBRIGtQEAvQEBGj8gTW9kZWwgZGVw
bG95bWVudCBtZXRhZGF0YSBzcGVjaWZpYyB0byBJbWFnZSBPYmplY3QgRGV0ZWN0aW9uLgoK
CwoDBAUBEgS1AQgzCssCCgQEBQIAEgS8AQIXGrwCIElucHV0IG9ubHkuIFRoZSBudW1iZXIg
b2Ygbm9kZXMgdG8gZGVwbG95IHRoZSBtb2RlbCBvbi4gQSBub2RlIGlzIGFuCiBhYnN0cmFj
dGlvbiBvZiBhIG1hY2hpbmUgcmVzb3VyY2UsIHdoaWNoIGNhbiBoYW5kbGUgb25saW5lIHBy
ZWRpY3Rpb24gUVBTCiBhcyBnaXZlbiBpbiB0aGUgbW9kZWwncwoKIFtxcHNfcGVyX25vZGVd
W2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5JbWFnZU9iamVjdERldGVjdGlvbk1vZGVs
TWV0YWRhdGEucXBzX3Blcl9ub2RlXS4KIE11c3QgYmUgYmV0d2VlbiAxIGFuZCAxMDAsIGlu
Y2x1c2l2ZSBvbiBib3RoIGVuZHMuCgoNCgUEBQIABRIEvAECBwoNCgUEBQIAARIEvAEIEgoN
CgUEBQIAAxIEvAEVFmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata ===
    # Fields for ImageClassificationDatasetMetadata
    # Field: classification_type Type: 14 (.google.cloud.automl.v1beta1.ClassificationType)

# === Message: Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionDatasetMetadata ===
    # Fields for ImageObjectDetectionDatasetMetadata

# === Message: Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelMetadata ===
    # Fields for ImageClassificationModelMetadata
    # Field: base_model_id Type: 9 ()
    # Field: train_budget Type: 3 ()
    # Field: train_cost Type: 3 ()
    # Field: stop_reason Type: 9 ()
    # Field: model_type Type: 9 ()
    # Field: node_qps Type: 1 ()
    # Field: node_count Type: 3 ()

# === Message: Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelMetadata ===
    # Fields for ImageObjectDetectionModelMetadata
    # Field: model_type Type: 9 ()
    # Field: node_count Type: 3 ()
    # Field: node_qps Type: 1 ()
    # Field: stop_reason Type: 9 ()
    # Field: train_budget_milli_node_hours Type: 3 ()
    # Field: train_cost_milli_node_hours Type: 3 ()

# === Message: Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelDeploymentMetadata ===
    # Fields for ImageClassificationModelDeploymentMetadata
    # Field: node_count Type: 3 ()

# === Message: Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelDeploymentMetadata ===
    # Fields for ImageObjectDetectionModelDeploymentMetadata
    # Field: node_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Image - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/image.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Image;

    my $msg = Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata->new({
        classification_type => $classification_type,
    });

    # Read or update a field
    my $val = $msg->classification_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/image.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata

Dataset metadata that is specific to image classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_type() >> / C<< $msg->classification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1beta1::ClassificationType>)

Required. Type of the classification problem.

=back

=head2 Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionDatasetMetadata

Dataset metadata specific to image object detection.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelMetadata

Model metadata for image classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_model_id() >> / C<< $msg->base_model_id($value) >>

Type: C<String>

Optional. The ID of the `base` model. If it is specified, the new model
will be created based on the `base` model. Otherwise, the new model will be
created from scratch. The `base` model must be in the same
`project` and `location` as the new model to create, and have the same
`model_type`.

=item * C<< $msg->train_budget() >> / C<< $msg->train_budget($value) >>

Type: C<Int64>

Required. The train budget of creating this model, expressed in hours. The
actual `train_cost` will be equal or less than this value.

=item * C<< $msg->train_cost() >> / C<< $msg->train_cost($value) >>

Type: C<Int64>

Output only. The actual train cost of creating this model, expressed in
hours. If this model is created from a `base` model, the train cost used
to create the `base` model are not included.

=item * C<< $msg->stop_reason() >> / C<< $msg->stop_reason($value) >>

Type: C<String>

Output only. The reason that this create model operation stopped,
e.g. `BUDGET_REACHED`, `MODEL_CONVERGED`.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Optional. Type of the model. The available values are:
*   `cloud` - Model to be used via prediction calls to AutoML API.
              This is the default value.
*   `mobile-low-latency-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards. Expected to have low latency, but
              may have lower prediction quality than other models.
*   `mobile-versatile-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.
*   `mobile-high-accuracy-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.  Expected to have a higher
              latency, but should also have a higher prediction quality
              than other models.
*   `mobile-core-ml-low-latency-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile device with Core
              ML afterwards. Expected to have low latency, but may have
              lower prediction quality than other models.
*   `mobile-core-ml-versatile-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile device with Core
              ML afterwards.
*   `mobile-core-ml-high-accuracy-1` - A model that, in addition to
              providing prediction via AutoML API, can also be exported
              (see [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile device with
              Core ML afterwards.  Expected to have a higher latency, but
              should also have a higher prediction quality than other
              models.

=item * C<< $msg->node_qps() >> / C<< $msg->node_qps($value) >>

Type: C<Double>

Output only. An approximate number of online prediction QPS that can
be supported by this model per each node on which it is deployed.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Output only. The number of nodes this model is deployed on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the node_qps field.

=back

=head2 Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelMetadata

Model metadata specific to image object detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Optional. Type of the model. The available values are:
*   `cloud-high-accuracy-1` - (default) A model to be used via prediction
              calls to AutoML API. Expected to have a higher latency, but
              should also have a higher prediction quality than other
              models.
*   `cloud-low-latency-1` -  A model to be used via prediction
              calls to AutoML API. Expected to have low latency, but may
              have lower prediction quality than other models.
*   `mobile-low-latency-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards. Expected to have low latency, but
              may have lower prediction quality than other models.
*   `mobile-versatile-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.
*   `mobile-high-accuracy-1` - A model that, in addition to providing
              prediction via AutoML API, can also be exported (see
              [AutoMl.ExportModel][google.cloud.automl.v1beta1.AutoMl.ExportModel]) and used on a mobile or edge device
              with TensorFlow afterwards.  Expected to have a higher
              latency, but should also have a higher prediction quality
              than other models.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Output only. The number of nodes this model is deployed on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the qps_per_node field.

=item * C<< $msg->node_qps() >> / C<< $msg->node_qps($value) >>

Type: C<Double>

Output only. An approximate number of online prediction QPS that can
be supported by this model per each node on which it is deployed.

=item * C<< $msg->stop_reason() >> / C<< $msg->stop_reason($value) >>

Type: C<String>

Output only. The reason that this create model operation stopped,
e.g. `BUDGET_REACHED`, `MODEL_CONVERGED`.

=item * C<< $msg->train_budget_milli_node_hours() >> / C<< $msg->train_budget_milli_node_hours($value) >>

Type: C<Int64>

The train budget of creating this model, expressed in milli node
hours i.e. 1,000 value in this field means 1 node hour. The actual
`train_cost` will be equal or less than this value. If further model
training ceases to provide any improvements, it will stop without using
full budget and the stop_reason will be `MODEL_CONVERGED`.
Note, node_hour  = actual_hour * number_of_nodes_invovled.
For model type `cloud-high-accuracy-1`(default) and `cloud-low-latency-1`,
the train budget must be between 20,000 and 900,000 milli node hours,
inclusive. The default value is 216, 000 which represents one day in
wall time.
For model type `mobile-low-latency-1`, `mobile-versatile-1`,
`mobile-high-accuracy-1`, `mobile-core-ml-low-latency-1`,
`mobile-core-ml-versatile-1`, `mobile-core-ml-high-accuracy-1`, the train
budget must be between 1,000 and 100,000 milli node hours, inclusive.
The default value is 24, 000 which represents one day in wall time.

=item * C<< $msg->train_cost_milli_node_hours() >> / C<< $msg->train_cost_milli_node_hours($value) >>

Type: C<Int64>

Output only. The actual train cost of creating this model, expressed in
milli node hours, i.e. 1,000 value in this field means 1 node hour.
Guaranteed to not exceed the train budget.

=back

=head2 Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelDeploymentMetadata

Model deployment metadata specific to Image Classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Input only. The number of nodes to deploy the model on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the model's

[node_qps][google.cloud.automl.v1beta1.ImageClassificationModelMetadata.node_qps].
Must be between 1 and 100, inclusive on both ends.

=back

=head2 Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelDeploymentMetadata

Model deployment metadata specific to Image Object Detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int64>

Input only. The number of nodes to deploy the model on. A node is an
abstraction of a machine resource, which can handle online prediction QPS
as given in the model's

[qps_per_node][google.cloud.automl.v1beta1.ImageObjectDetectionModelMetadata.qps_per_node].
Must be between 1 and 100, inclusive on both ends.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Image::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
