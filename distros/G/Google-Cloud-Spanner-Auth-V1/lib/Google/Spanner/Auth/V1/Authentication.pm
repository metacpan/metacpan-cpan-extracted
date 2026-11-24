package Google::Spanner::Auth::V1::Authentication;

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
Citnb29nbGUvc3Bhbm5lci9hdXRoL3YxL2F1dGhlbnRpY2F0aW9uLnByb3RvEhZnb29nbGUu
c3Bhbm5lci5hdXRoLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIsECCg5I
YXNoUGFyYW1ldGVycxJtChRhcmdvbjJfaWRfcGFyYW1ldGVycxgBIAEoCzI5Lmdvb2dsZS5z
cGFubmVyLmF1dGgudjEuSGFzaFBhcmFtZXRlcnMuQXJnb24ySWRQYXJhbWV0ZXJzSABSEmFy
Z29uMklkUGFyYW1ldGVycxqxAQoSQXJnb24ySWRQYXJhbWV0ZXJzEicKD2l0ZXJhdGlvbl9j
b3VudBgBIAEoBVIOaXRlcmF0aW9uQ291bnQSKAoQbWVtb3J5X3VzYWdlX2tpYhgCIAEoBVIO
bWVtb3J5VXNhZ2VLaWISIAoLcGFyYWxsZWxpc20YAyABKAVSC3BhcmFsbGVsaXNtEiYKD2hh
c2hfc2l6ZV9ieXRlcxgEIAEoBVINaGFzaFNpemVCeXRlc0IMCgpwYXJhbWV0ZXJzIigKJlBh
c3N3b3JkQXV0aGVudGljYXRpb25IYW5kc2hha2VSZXF1ZXN0Iv0BCidQYXNzd29yZEF1dGhl
bnRpY2F0aW9uSGFuZHNoYWtlUmVzcG9uc2USgAEKIHBhc3N3b3JkX2F1dGhlbnRpY2F0aW9u
X3Byb3RvY29sGAEgASgOMjYuZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5QYXNzd29yZEF1dGhl
bnRpY2F0aW9uUHJvdG9jb2xSHnBhc3N3b3JkQXV0aGVudGljYXRpb25Qcm90b2NvbBJPCg9o
YXNoX3BhcmFtZXRlcnMYAiABKAsyJi5nb29nbGUuc3Bhbm5lci5hdXRoLnYxLkhhc2hQYXJh
bWV0ZXJzUg5oYXNoUGFyYW1ldGVycyK4AwoSUGFzc3dvcmRDcmVkZW50aWFsEkgKBXNjcmFt
GAEgASgLMjAuZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5QYXNzd29yZENyZWRlbnRpYWwuU2Ny
YW1IAFIFc2NyYW0SSwoGb3BhcXVlGAIgASgLMjEuZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5Q
YXNzd29yZENyZWRlbnRpYWwuT3BhcXVlSABSBm9wYXF1ZRpPCgVTY3JhbRIiCgpzZXJ2ZXJf
a2V5GAEgASgMQgPgQQJSCXNlcnZlcktleRIiCgpzdG9yZWRfa2V5GAIgASgMQgPgQQJSCXN0
b3JlZEtleRqrAQoGT3BhcXVlEi8KEWNsaWVudF9wdWJsaWNfa2V5GAEgASgMQgPgQQJSD2Ns
aWVudFB1YmxpY0tleRIkCgttYXNraW5nX2tleRgCIAEoDEID4EECUgptYXNraW5nS2V5EioK
DmVudmVsb3BlX25vbmNlGAMgASgMQgPgQQJSDWVudmVsb3BlTm9uY2USHgoIYXV0aF90YWcY
BCABKAxCA+BBAlIHYXV0aFRhZ0IMCgpjcmVkZW50aWFsIk0KFEluaXRpYWxTY3JhbVJlc3Bv
bnNlEhIKBHNhbHQYASABKAxSBHNhbHQSIQoMc2VydmVyX25vbmNlGAIgASgMUgtzZXJ2ZXJO
b25jZSLtAgoZU2NyYW1OZXdDcmVkZW50aWFsUmVxdWVzdBJrCg9pbml0aWFsX3JlcXVlc3QY
ASABKAsyQC5nb29nbGUuc3Bhbm5lci5hdXRoLnYxLlNjcmFtTmV3Q3JlZGVudGlhbFJlcXVl
c3QuSW5pdGlhbFJlcXVlc3RIAFIOaW5pdGlhbFJlcXVlc3QSZQoNZmluYWxfcmVxdWVzdBgC
IAEoCzI+Lmdvb2dsZS5zcGFubmVyLmF1dGgudjEuU2NyYW1OZXdDcmVkZW50aWFsUmVxdWVz
dC5GaW5hbFJlcXVlc3RIAFIMZmluYWxSZXF1ZXN0GhAKDkluaXRpYWxSZXF1ZXN0Gl8KDEZp
bmFsUmVxdWVzdBJPCgpjcmVkZW50aWFsGAEgASgLMiouZ29vZ2xlLnNwYW5uZXIuYXV0aC52
MS5QYXNzd29yZENyZWRlbnRpYWxCA+BBAlIKY3JlZGVudGlhbEIJCgdyZXF1ZXN0Iv8BChpT
Y3JhbU5ld0NyZWRlbnRpYWxSZXNwb25zZRJZChBpbml0aWFsX3Jlc3BvbnNlGAEgASgLMiwu
Z29vZ2xlLnNwYW5uZXIuYXV0aC52MS5Jbml0aWFsU2NyYW1SZXNwb25zZUgAUg9pbml0aWFs
UmVzcG9uc2USaQoOZmluYWxfcmVzcG9uc2UYAiABKAsyQC5nb29nbGUuc3Bhbm5lci5hdXRo
LnYxLlNjcmFtTmV3Q3JlZGVudGlhbFJlc3BvbnNlLkZpbmFsUmVzcG9uc2VIAFINZmluYWxS
ZXNwb25zZRoPCg1GaW5hbFJlc3BvbnNlQgoKCHJlc3BvbnNlIp4DChpPcGFxdWVOZXdDcmVk
ZW50aWFsUmVxdWVzdBJsCg9pbml0aWFsX3JlcXVlc3QYASABKAsyQS5nb29nbGUuc3Bhbm5l
ci5hdXRoLnYxLk9wYXF1ZU5ld0NyZWRlbnRpYWxSZXF1ZXN0LkluaXRpYWxSZXF1ZXN0SABS
DmluaXRpYWxSZXF1ZXN0EmYKDWZpbmFsX3JlcXVlc3QYAiABKAsyPy5nb29nbGUuc3Bhbm5l
ci5hdXRoLnYxLk9wYXF1ZU5ld0NyZWRlbnRpYWxSZXF1ZXN0LkZpbmFsUmVxdWVzdEgAUgxm
aW5hbFJlcXVlc3QaPgoOSW5pdGlhbFJlcXVlc3QSLAoPYmxpbmRlZF9tZXNzYWdlGAEgASgM
QgPgQQJSDmJsaW5kZWRNZXNzYWdlGl8KDEZpbmFsUmVxdWVzdBJPCgpjcmVkZW50aWFsGAEg
ASgLMiouZ29vZ2xlLnNwYW5uZXIuYXV0aC52MS5QYXNzd29yZENyZWRlbnRpYWxCA+BBAlIK
Y3JlZGVudGlhbEIJCgdyZXF1ZXN0IoQDChtPcGFxdWVOZXdDcmVkZW50aWFsUmVzcG9uc2US
cAoQaW5pdGlhbF9yZXNwb25zZRgBIAEoCzJDLmdvb2dsZS5zcGFubmVyLmF1dGgudjEuT3Bh
cXVlTmV3Q3JlZGVudGlhbFJlc3BvbnNlLkluaXRpYWxSZXNwb25zZUgAUg9pbml0aWFsUmVz
cG9uc2USagoOZmluYWxfcmVzcG9uc2UYAiABKAsyQS5nb29nbGUuc3Bhbm5lci5hdXRoLnYx
Lk9wYXF1ZU5ld0NyZWRlbnRpYWxSZXNwb25zZS5GaW5hbFJlc3BvbnNlSABSDWZpbmFsUmVz
cG9uc2UaagoPSW5pdGlhbFJlc3BvbnNlEisKEWV2YWx1YXRlZF9tZXNzYWdlGAEgASgMUhBl
dmFsdWF0ZWRNZXNzYWdlEioKEXNlcnZlcl9wdWJsaWNfa2V5GAIgASgMUg9zZXJ2ZXJQdWJs
aWNLZXkaDwoNRmluYWxSZXNwb25zZUIKCghyZXNwb25zZSqgAQoeUGFzc3dvcmRBdXRoZW50
aWNhdGlvblByb3RvY29sEjAKLFBBU1NXT1JEX0FVVEhFTlRJQ0FUSU9OX1BST1RPQ09MX1VO
U1BFQ0lGSUVEEAASDwoLVU5TUEVDSUZJRUQQABIrCidQQVNTV09SRF9BVVRIRU5USUNBVElP
Tl9QUk9UT0NPTF9PUEFRVUUQAhIKCgZPUEFRVUUQAhoCEAFCygEKGmNvbS5nb29nbGUuc3Bh
bm5lci5hdXRoLnYxQhNBdXRoZW50aWNhdGlvblByb3RvUAFaNGNsb3VkLmdvb2dsZS5jb20v
Z28vc3Bhbm5lci9hdXRoL2FwaXYxL2F1dGhwYjthdXRocGKqAhxHb29nbGUuQ2xvdWQuU3Bh
bm5lci5BdXRoLlYxygIcR29vZ2xlXENsb3VkXFNwYW5uZXJcQXV0aFxWMeoCIEdvb2dsZTo6
Q2xvdWQ6OlNwYW5uZXI6OkF1dGg6OlYxSpZACgcSBQ4A5gEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCAoBCBIDFAA5CgkKAggl
EgMUADkKCAoBCBIDFQBLCgkKAggLEgMVAEsKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBID
FwA0CgkKAggIEgMXADQKCAoBCBIDGAAzCgkKAggBEgMYADMKCAoBCBIDGQA6CgkKAggpEgMZ
ADoKCAoBCBIDGgA5CgkKAggtEgMaADkKTwoCBAASBB0AMgEaQyBIYXNoUGFyYW1ldGVycyBj
b250YWlucyB0aGUgcGFyYW1ldGVycyB1c2VkIHRvIGhhc2ggdGhlIHBhc3N3b3JkLgoKCgoD
BAABEgMdCBYKQAoEBAADABIEHwIrAxoyIFRoZSBBcmdvbjIgcGFyYW1ldGVycyB1c2VkIHRv
IGhhc2ggdGhlIHBhc3N3b3JkLgoKDAoFBAADAAESAx8KHApLCgYEAAMAAgASAyEEHho8IFRo
ZSBudW1iZXIgb2YgaXRlcmF0aW9ucyB0byB1c2Ugd2hlbiBoYXNoaW5nIHRoZSBwYXNzd29y
ZC4KCg4KBwQAAwACAAUSAyEECQoOCgcEAAMAAgABEgMhChkKDgoHBAADAAIAAxIDIRwdCkwK
BgQAAwACARIDJAQfGj0gVGhlIG1lbW9yeSB1c2FnZSAoaW4gS2lCKSB0byB1c2Ugd2hlbiBo
YXNoaW5nIHRoZSBwYXNzd29yZC4KCg4KBwQAAwACAQUSAyQECQoOCgcEAAMAAgEBEgMkChoK
DgoHBAADAAIBAxIDJB0eClYKBgQAAwACAhIDJwQaGkcgVGhlIHBhcmFsbGVsaXNtIChudW1i
ZXIgb2YgdGhyZWFkcykgdG8gdXNlIHdoZW4gaGFzaGluZyB0aGUgcGFzc3dvcmQuCgoOCgcE
AAMAAgIFEgMnBAkKDgoHBAADAAICARIDJwoVCg4KBwQAAwACAgMSAycYGQpSCgYEAAMAAgMS
AyoEHhpDIFRoZSBzaXplIG9mIHRoZSBoYXNoIChpbiBieXRlcykgdG8gdXNlIHdoZW4gaGFz
aGluZyB0aGUgcGFzc3dvcmQuCgoOCgcEAAMAAgMFEgMqBAkKDgoHBAADAAIDARIDKgoZCg4K
BwQAAwACAwMSAyocHQo5CgQEAAgAEgQuAjEDGisgVGhlIHBhcmFtZXRlcnMgdXNlZCB0byBo
YXNoIHRoZSBwYXNzd29yZC4KCgwKBQQACAABEgMuCBIKPwoEBAACABIDMAQwGjIgVGhlIEFy
Z29uMiBwYXJhbWV0ZXJzIHVzZWQgdG8gaGFzaCB0aGUgcGFzc3dvcmQuCgoMCgUEAAIABhID
MAQWCgwKBQQAAgABEgMwFysKDAoFBAACAAMSAzAuLwqvAQoCBAESAzcAMRqjASBQYXNzd29y
ZEF1dGhlbnRpY2F0aW9uSGFuZHNoYWtlUmVxdWVzdCBpcyB1c2VkIHRvIGluaXRpYXRlIHRo
ZSBhdXRoZW50aWNhdGlvbgogcHJvY2VzcyBieSByZXF1ZXN0aW5nIHRoZSBzZXJ2ZXIgdG8g
ZGV0ZXJtaW5lIGhvdyB0aGUgY2xpZW50IHNob3VsZAogYXV0aGVudGljYXRlLgoKCgoDBAEB
EgM3CC4KjQEKAgQCEgQ7AEIBGoABIFBhc3N3b3JkQXV0aGVudGljYXRpb25IYW5kc2hha2VS
ZXNwb25zZSBpcyByZXR1cm5lZCBieSB0aGUgc2VydmVyIHRvCiBkZXRlcm1pbmUgd2hpY2gg
cHJvdG9jb2wgc2hvdWxkIGJlIHVzZWQgdG8gYXV0aGVudGljYXRlLgoKCgoDBAIBEgM7CC8K
TwoEBAICABIDPQJGGkIgVGhlIGF1dGhlbnRpY2F0aW9uIG1ldGhvZCB0aGUgY2xpZW50IHNo
b3VsZCB1c2UgdG8gYXV0aGVudGljYXRlLgoKDAoFBAICAAYSAz0CIAoMCgUEAgIAARIDPSFB
CgwKBQQCAgADEgM9REUKigEKBAQCAgESA0ECJRp9IFRoZSBoYXNoIHBhcmFtZXRlcnMgdXNl
ZCB0byBoYXNoIHRoZSBwYXNzd29yZCwgdGhpcyBpcyB1c2VkIHRvIGVuc3VyZSB0aGUKIGNs
aWVudCBhbmQgc2VydmVyIGFyZSB1c2luZyB0aGUgc2FtZSBwYXJhbWV0ZXJzLgoKDAoFBAIC
AQYSA0ECEAoMCgUEAgIBARIDQREgCgwKBQQCAgEDEgNBIyQKcwoCBAMSBEYAcQEaZyBUaGUg
cGFzc3dvcmQgY3JlZGVudGlhbCBmb3IgYSB1c2VyIHRoYXQgaXMgc2VudCBmcm9tIHRoZSBj
bGllbnQgdG8gdGhlCiBzZXJ2ZXIgZHVyaW5nIGF1dGhlbnRpY2F0aW9uLgoKCgoDBAMBEgNG
CBoKLwoEBAMDABIESAJTAxohIFNjcmFtIGlzIHRoZSBTQ1JBTSBjcmVkZW50aWFscy4KCgwK
BQQDAwABEgNICg8KyQEKBgQDAwACABIDTARCGrkBIFJlcXVpcmVkLiBUaGUgc2VydmVyIGtl
eSBkZXJpdmVkIGZyb20gdGhlIHNhbHRlZCBwYXNzd29yZC4gIFRoZSBzZXJ2ZXIKIGtleSBp
cyB1c2VkIHRvIGdlbmVyYXRlIHRoZSBzZXJ2ZXIgc2lnbmF0dXJlLCB3aGljaCBpcyBzZW50
IHRvIHRoZSBjbGllbnQKIHNvIHRoZSBjbGllbnQgY2FuIHZlcmlmeSB0aGUgc2VydmVyLgoK
DgoHBAMDAAIABRIDTAQJCg4KBwQDAwACAAESA0wKFAoOCgcEAwMAAgADEgNMFxgKDgoHBAMD
AAIACBIDTBlBChEKCgQDAwACAAicCAASA0waQAqEAgoGBAMDAAIBEgNSBEIa9AEgUmVxdWly
ZWQuIFRoZSBzdG9yZWQga2V5IGRlcml2ZWQgZnJvbSB0aGUgc2FsdGVkIHBhc3N3b3JkLiAg
VGhlIHN0b3JlZAoga2V5IGlzIHVzZWQgdG8gdmVyaWZ5IHRoYXQgdGhlIGNsaWVudCdzIHBy
b29mIGluIHRoZSBjcmVkZW50aWFsIGlzIHZhbGlkLgogVGhlIHN0b3JlZCBrZXkgaXMgZGVy
aXZlZCBmcm9tIHRoZSBjbGllbnQgcHJvb2YgYW5kIGNvbXBhcmVkIHRvIHRoZQogc3RvcmVk
IGtleSB0aGUgc2VydmVyIGhhcy4KCg4KBwQDAwACAQUSA1IECQoOCgcEAwMAAgEBEgNSChQK
DgoHBAMDAAIBAxIDUhcYCg4KBwQDAwACAQgSA1IZQQoRCgoEAwMAAgEInAgAEgNSGkAKXQoE
BAMDARIEVwJmAxpPIE9wYXF1ZSBjb250YWlucyB0aGUgT1BBUVVFIGNyZWRlbnRpYWxzIHRo
YXQgYXJlIHVzZWQgdG8gYXV0aGVudGljYXRlIGEKIHVzZXIuCgoMCgUEAwMBARIDVwoQCjMK
BgQDAwECABIDWQRJGiQgUmVxdWlyZWQuIFRoZSBjbGllbnQncyBwdWJsaWMga2V5LgoKDgoH
BAMDAQIABRIDWQQJCg4KBwQDAwECAAESA1kKGwoOCgcEAwMBAgADEgNZHh8KDgoHBAMDAQIA
CBIDWSBIChEKCgQDAwECAAicCAASA1khRwreAQoGBAMDAQIBEgNeBEMazgEgUmVxdWlyZWQu
IFRoZSBtYXNraW5nIGtleSBpcyB1c2VkIHRvIHByZXZlbnQgY2xpZW50IGVudW1lcmF0aW9u
IGF0dGFja3MsCiB3aGVyZSB1bmF1dGhvcml6ZWQgY2xpZW50cyB0cnkgdG8gZ2FpbiBpbmZv
cm1hdGlvbiBzdWNoIGFzIHRoZSBleGlzdGVuY2UKIG9mIGEgdXNlciwgdGhlaXIgZW1haWwg
YWRkcmVzcywgb3IgdGhlIHJvbGVzIGEgdXNlciBoYXMuCgoOCgcEAwMBAgEFEgNeBAkKDgoH
BAMDAQIBARIDXgoVCg4KBwQDAwECAQMSA14YGQoOCgcEAwMBAgEIEgNeGkIKEQoKBAMDAQIB
CJwIABIDXhtBCk4KBgQDAwECAhIDYQRGGj8gUmVxdWlyZWQuIFJhbmRvbSB2YWx1ZSB1c2Vk
IHRvIHByb3RlY3QgdGhlIGVudmVsb3BlIGNvbnRlbnRzLgoKDgoHBAMDAQICBRIDYQQJCg4K
BwQDAwECAgESA2EKGAoOCgcEAwMBAgIDEgNhGxwKDgoHBAMDAQICCBIDYR1FChEKCgQDAwEC
AgicCAASA2EeRApjCgYEAwMBAgMSA2UEQBpUIFJlcXVpcmVkLiBUaGUgYXV0aF90YWcgaXMg
dXNlZCB0byBwcm90ZWN0IHRoZSBwdWJsaWMga2V5cyBhbmQgdGhlCiBlbnZlbG9wZSBub25j
ZS4KCg4KBwQDAwECAwUSA2UECQoOCgcEAwMBAgMBEgNlChIKDgoHBAMDAQIDAxIDZRUWCg4K
BwQDAwECAwgSA2UXPwoRCgoEAwMBAgMInAgAEgNlGD4KLAoEBAMIABIEaQJwAxoeIFRoZSBj
cmVkZW50aWFsIGZvciB0aGUgdXNlci4KCgwKBQQDCAABEgNpCBIKSAoEBAMCABIDawQUGjsg
VGhlIFNDUkFNIGNyZWRlbnRpYWwgY29udGFpbnMgdGhlIHNlcnZlciBhbmQgc3RvcmVkIGtl
eXMuCgoMCgUEAwIABhIDawQJCgwKBQQDAgABEgNrCg8KDAoFBAMCAAMSA2sSEwpwCgQEAwIB
EgNvBBYaYyBUaGUgT1BBUVVFIGNyZWRlbnRpYWwgY29udGFpbnMgdGhlIGNsaWVudCBwdWJs
aWMga2V5LCBtYXNraW5nIGtleSwKIGVudmVsb3BlIG5vbmNlLCBhbmQgYXV0aCB0YWcuCgoM
CgUEAwIBBhIDbwQKCgwKBQQDAgEBEgNvCxEKDAoFBAMCAQMSA28UFQqGAQoCBAQSBHUAewEa
eiBJbml0aWFsU2NyYW1SZXNwb25zZSBpcyByZXR1cm5lZCBieSB0aGUgc2VydmVyIHNvIHRo
YXQgdGhlIGNsaWVudCBjYW4KIGdlbmVyYXRlIHRoZSBjcmVkZW50aWFsIHVzaW5nIHRoZSBT
Q1JBTSBwcm90b2NvbC4KCgoKAwQEARIDdQgcCjkKBAQEAgASA3cCERosIFRoZSBzYWx0IHRv
IHVzZSB3aGVuIGhhc2hpbmcgdGhlIHBhc3N3b3JkLgoKDAoFBAQCAAUSA3cCBwoMCgUEBAIA
ARIDdwgMCgwKBQQEAgADEgN3DxAKLAoEBAQCARIDegIZGh8gTm9uY2UgcHJvdmlkZWQgYnkg
dGhlIHNlcnZlci4KCgwKBQQEAgEFEgN6AgcKDAoFBAQCAQESA3oIFAoMCgUEBAIBAxIDehcY
CjsKAgQFEgV+AJIBARouIEEgcmVxdWVzdCB0byBjcmVhdGUgYSBuZXcgU0NSQU0gY3JlZGVu
dGlhbHMuCgoKCgMEBQESA34IIQq5AQoEBAUDABIEggECGxqqASBUaGUgaW5pdGlhbCByZXF1
ZXN0IHRvIHN0YXJ0IHRoZSBTQ1JBTSBoYW5kc2hha2UsIHRoaXMgbXVzdCBiZSBzZXQgb24g
dGhlCiBmaXJzdCByZXF1ZXN0LCBldmVuIHRob3VnaCBpdCBpcyBhbiBlbXB0eSBtZXNzYWdl
LCB0byBkaXN0aW5ndWlzaCBpdCBmcm9tCiB0aGUgZmluYWwgcmVxdWVzdC4KCg0KBQQFAwAB
EgSCAQoYCkQKBAQFAwESBoUBAogBAxo0IFRoZSBmaW5hbCByZXF1ZXN0IHRvIGNvbXBsZXRl
IHRoZSBTQ1JBTSBoYW5kc2hha2UuCgoNCgUEBQMBARIEhQEKFgpCCgYEBQMBAgASBIcBBE8a
MiBSZXF1aXJlZC4gVGhlIGNyZWRlbnRpYWwgcHJvdmlkZWQgYnkgdGhlIGNsaWVudC4KCg8K
BwQFAwECAAYSBIcBBBYKDwoHBAUDAQIAARIEhwEXIQoPCgcEBQMBAgADEgSHASQlCg8KBwQF
AwECAAgSBIcBJk4KEgoKBAUDAQIACJwIABIEhwEnTQo2CgQEBQgAEgaLAQKRAQMaJiBUaGUg
cmVxdWVzdCBmb3IgU0NSQU0gdXNlciBjcmVhdGlvbi4KCg0KBQQFCAABEgSLAQgPCkEKBAQF
AgASBI0BBCcaMyBUaGUgaW5pdGlhbCByZXF1ZXN0IHRvIHN0YXJ0IHRoZSBTQ1JBTSBoYW5k
c2hha2UuCgoNCgUEBQIABhIEjQEEEgoNCgUEBQIAARIEjQETIgoNCgUEBQIAAxIEjQElJgpC
CgQEBQIBEgSQAQQjGjQgVGhlIGZpbmFsIHJlcXVlc3QgdG8gY29tcGxldGUgdGhlIFNDUkFN
IGhhbmRzaGFrZS4KCg0KBQQFAgEGEgSQAQQQCg0KBQQFAgEBEgSQAREeCg0KBQQFAgEDEgSQ
ASEiCkoKAgQGEgaVAQChAQEaPCBUaGUgcmVzcG9uc2UgdG8gY3JlYXRlIGEgbmV3IHVzZXIg
dXNpbmcgU0NSQU0gY3JlZGVudGlhbHMuCgoLCgMEBgESBJUBCCIKMwoEBAYDABIElwECGhol
IFRoZSBmaW5hbCByZXNwb25zZSBmcm9tIHRoZSBzZXJ2ZXIuCgoNCgUEBgMAARIElwEKFwo3
CgQEBggAEgaaAQKgAQMaJyBUaGUgcmVzcG9uc2UgZm9yIFNDUkFNIHVzZXIgY3JlYXRpb24u
CgoNCgUEBggAARIEmgEIEAo1CgQEBgIAEgScAQQuGicgVGhlIGluaXRpYWwgcmVzcG9uc2Ug
ZnJvbSB0aGUgc2VydmVyLgoKDQoFBAYCAAYSBJwBBBgKDQoFBAYCAAESBJwBGSkKDQoFBAYC
AAMSBJwBLC0KMwoEBAYCARIEnwEEJRolIFRoZSBmaW5hbCByZXNwb25zZSBmcm9tIHRoZSBz
ZXJ2ZXIuCgoNCgUEBgIBBhIEnwEEEQoNCgUEBgIBARIEnwESIAoNCgUEBgIBAxIEnwEjJAo7
CgIEBxIGpAEAuQEBGi0gQSByZXF1ZXN0IHRvIGNyZWF0ZSBuZXcgT1BBUVVFIGNyZWRlbnRp
YWxzLgoKCwoDBAcBEgSkAQgiCj8KBAQHAwASBqYBAqkBAxovIFRoZSBpbml0aWFsIHJlcXVl
c3QgZm9yIE9QQVFVRSB1c2VyIGNyZWF0aW9uLgoKDQoFBAcDAAESBKYBChgKTgoGBAcDAAIA
EgSoAQRHGj4gUmVxdWlyZWQuIFRoZSBibGluZGVkIG1lc3NhZ2UgdGhhdCB0aGUgY2xpZW50
IGhhcyBnZW5lcmF0ZWQuCgoPCgcEBwMAAgAFEgSoAQQJCg8KBwQHAwACAAESBKgBChkKDwoH
BAcDAAIAAxIEqAEcHQoPCgcEBwMAAgAIEgSoAR5GChIKCgQHAwACAAicCAASBKgBH0UKPQoE
BAcDARIGrAECrwEDGi0gVGhlIGZpbmFsIHJlcXVlc3QgZm9yIE9QQVFVRSB1c2VyIGNyZWF0
aW9uLgoKDQoFBAcDAQESBKwBChYKQgoGBAcDAQIAEgSuAQRPGjIgUmVxdWlyZWQuIFRoZSBj
cmVkZW50aWFsIHByb3ZpZGVkIGJ5IHRoZSBjbGllbnQuCgoPCgcEBwMBAgAGEgSuAQQWCg8K
BwQHAwECAAESBK4BFyEKDwoHBAcDAQIAAxIErgEkJQoPCgcEBwMBAgAIEgSuASZOChIKCgQH
AwECAAicCAASBK4BJ00KNwoEBAcIABIGsgECuAEDGicgVGhlIHJlcXVlc3QgZm9yIE9QQVFV
RSB1c2VyIGNyZWF0aW9uLgoKDQoFBAcIAAESBLIBCA8KPQoEBAcCABIEtAEEJxovIFRoZSBp
bml0aWFsIHJlcXVlc3QgZm9yIE9QQVFVRSB1c2VyIGNyZWF0aW9uLgoKDQoFBAcCAAYSBLQB
BBIKDQoFBAcCAAESBLQBEyIKDQoFBAcCAAMSBLQBJSYKOwoEBAcCARIEtwEEIxotIFRoZSBm
aW5hbCByZXF1ZXN0IGZvciBPUEFRVUUgdXNlciBjcmVhdGlvbi4KCg0KBQQHAgEGEgS3AQQQ
Cg0KBQQHAgEBEgS3AREeCg0KBQQHAgEDEgS3ASEiCmAKAgQIEga9AQDUAQEaUiBUaGUgcmVz
cG9uc2UgZnJvbSB0aGUgc2VydmVyIHdoZW4gY3JlYXRpbmcgYSBuZXcgdXNlciB1c2luZyBP
UEFRVUUKIGNyZWRlbnRpYWxzLgoKCwoDBAgBEgS9AQgjCkAKBAQIAwASBr8BAscBAxowIFRo
ZSBpbml0aWFsIHJlc3BvbnNlIGZvciBPUEFRVUUgdXNlciBjcmVhdGlvbi4KCg0KBQQIAwAB
EgS/AQoZCpQBCgYECAMAAgASBMIBBCAagwEgVGhlIGV2YWx1YXRlZCBtZXNzYWdlIGNvbnRh
aW5zIHRoZSBPUFJGIG91dHB1dCB3aGljaCBpcyBjcmVhdGVkIHVzaW5nCiB0aGUgc2VydmVy
J3MgcHJpdmF0ZSBrZXkgYW5kIHRoZSBjbGllbnQncyBibGluZGVkIG1lc3NhZ2UuCgoPCgcE
CAMAAgAFEgTCAQQJCg8KBwQIAwACAAESBMIBChsKDwoHBAgDAAIAAxIEwgEeHwp3CgYECAMA
AgESBMYBBCAaZyBUaGUgc2VydmVyJ3MgcHVibGljIGtleSB1c2VkIHRvIGdlbmVyYXRlIHRo
ZSBjbGllbnQgZGF0YSB0aGUgc2VydmVyCiBzdG9yZXMgdG8gYXV0aGVudGljYXRlIHRoZSB1
c2VyLgoKDwoHBAgDAAIBBRIExgEECQoPCgcECAMAAgEBEgTGAQobCg8KBwQIAwACAQMSBMYB
Hh8KPAoEBAgDARIEygECGhouIFRoZSBmaW5hbCByZXNwb25zZSBmb3IgT1BBUVVFIHVzZXIg
Y3JlYXRpb24uCgoNCgUECAMBARIEygEKFwo4CgQECAgAEgbNAQLTAQMaKCBUaGUgcmVzcG9u
c2UgZm9yIE9QQVFVRSB1c2VyIGNyZWF0aW9uLgoKDQoFBAgIAAESBM0BCBAKPgoEBAgCABIE
zwEEKRowIFRoZSBpbml0aWFsIHJlc3BvbnNlIGZvciBPUEFRVUUgdXNlciBjcmVhdGlvbi4K
Cg0KBQQIAgAGEgTPAQQTCg0KBQQIAgABEgTPARQkCg0KBQQIAgADEgTPAScoCjwKBAQIAgES
BNIBBCUaLiBUaGUgZmluYWwgcmVzcG9uc2UgZm9yIE9QQVFVRSB1c2VyIGNyZWF0aW9uLgoK
DQoFBAgCAQYSBNIBBBEKDQoFBAgCAQESBNIBEiAKDQoFBAgCAQMSBNIBIyQKdwoCBQASBtgB
AOYBARppIFBhc3N3b3JkQXV0aGVudGljYXRpb25Qcm90b2NvbCBpcyB0aGUgcHJvdG9jb2wg
dXNlZCB0byBhdXRoZW50aWNhdGUgdGhlCiB1c2luZyBhIHVzZXJuYW1lIGFuZCBwYXNzd29y
ZC4KCgsKAwUAARIE2AEFIwoLCgMFAAMSBNkBAhwKDAoEBQADAhIE2QECHApECgQFAAIAEgTc
AQIzGjYgVGhlIHBhc3N3b3JkIGF1dGhlbnRpY2F0aW9uIHByb3RvY29sIGlzIHVuc3BlY2lm
aWVkLgoKDQoFBQACAAESBNwBAi4KDQoFBQACAAISBNwBMTIKRAoEBQACARIE3wECEho2IFRo
ZSBwYXNzd29yZCBhdXRoZW50aWNhdGlvbiBwcm90b2NvbCBpcyB1bnNwZWNpZmllZC4KCg0K
BQUAAgEBEgTfAQINCg0KBQUAAgECEgTfARARCjQKBAUAAgISBOIBAi4aJiBUaGUgYXV0aGVu
dGljYXRpb24gbWV0aG9kIGlzIE9QQVFVRS4KCg0KBQUAAgIBEgTiAQIpCg0KBQUAAgICEgTi
ASwtCjQKBAUAAgMSBOUBAg0aJiBUaGUgYXV0aGVudGljYXRpb24gbWV0aG9kIGlzIE9QQVFV
RS4KCg0KBQUAAgMBEgTlAQIICg0KBQUAAgMCEgTlAQsMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::Auth::V1::Authentication::HashParameters ===
    # Fields for HashParameters
    # Field: argon2_id_parameters Type: 11 (.google.spanner.auth.v1.HashParameters.Argon2IdParameters)

# === Message: Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeRequest ===
    # Fields for PasswordAuthenticationHandshakeRequest

# === Message: Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeResponse ===
    # Fields for PasswordAuthenticationHandshakeResponse
    # Field: password_authentication_protocol Type: 14 (.google.spanner.auth.v1.PasswordAuthenticationProtocol)
    # Field: hash_parameters Type: 11 (.google.spanner.auth.v1.HashParameters)

# === Message: Google::Spanner::Auth::V1::Authentication::PasswordCredential ===
    # Fields for PasswordCredential
    # Field: scram Type: 11 (.google.spanner.auth.v1.PasswordCredential.Scram)
    # Field: opaque Type: 11 (.google.spanner.auth.v1.PasswordCredential.Opaque)

# === Message: Google::Spanner::Auth::V1::Authentication::InitialScramResponse ===
    # Fields for InitialScramResponse
    # Field: salt Type: 12 ()
    # Field: server_nonce Type: 12 ()

# === Message: Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest ===
    # Fields for ScramNewCredentialRequest
    # Field: initial_request Type: 11 (.google.spanner.auth.v1.ScramNewCredentialRequest.InitialRequest)
    # Field: final_request Type: 11 (.google.spanner.auth.v1.ScramNewCredentialRequest.FinalRequest)

# === Message: Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse ===
    # Fields for ScramNewCredentialResponse
    # Field: initial_response Type: 11 (.google.spanner.auth.v1.InitialScramResponse)
    # Field: final_response Type: 11 (.google.spanner.auth.v1.ScramNewCredentialResponse.FinalResponse)

# === Message: Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest ===
    # Fields for OpaqueNewCredentialRequest
    # Field: initial_request Type: 11 (.google.spanner.auth.v1.OpaqueNewCredentialRequest.InitialRequest)
    # Field: final_request Type: 11 (.google.spanner.auth.v1.OpaqueNewCredentialRequest.FinalRequest)

# === Message: Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse ===
    # Fields for OpaqueNewCredentialResponse
    # Field: initial_response Type: 11 (.google.spanner.auth.v1.OpaqueNewCredentialResponse.InitialResponse)
    # Field: final_response Type: 11 (.google.spanner.auth.v1.OpaqueNewCredentialResponse.FinalResponse)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::Auth::V1::Authentication - Compiled Protocol Buffers messages for google/spanner/auth/v1/authentication.proto

=head1 SYNOPSIS

    use Google::Spanner::Auth::V1::Authentication;

    my $msg = Google::Spanner::Auth::V1::Authentication::HashParameters->new({
        argon2_id_parameters => $argon2_id_parameters,
    });

    # Read or update a field
    my $val = $msg->argon2_id_parameters();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::Auth::V1::Authentication::HashParameters->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/auth/v1/authentication.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::Auth::V1::Authentication::HashParameters

HashParameters contains the parameters used to hash the password.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->argon2_id_parameters() >> / C<< $msg->argon2_id_parameters($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::HashParameters::Argon2IdParameters>)

The Argon2 parameters used to hash the password.

=back

=head2 Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeRequest

PasswordAuthenticationHandshakeRequest is used to initiate the authentication
process by requesting the server to determine how the client should
authenticate.

Inherits from L<Protobuf::Message>.

=head2 Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeResponse

PasswordAuthenticationHandshakeResponse is returned by the server to
determine which protocol should be used to authenticate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->password_authentication_protocol() >> / C<< $msg->password_authentication_protocol($value) >>

Type: C<Enum> (L<Google::Spanner::Auth::V1::PasswordAuthenticationProtocol>)

The authentication method the client should use to authenticate.

=item * C<< $msg->hash_parameters() >> / C<< $msg->hash_parameters($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::HashParameters>)

The hash parameters used to hash the password, this is used to ensure the
client and server are using the same parameters.

=back

=head2 Google::Spanner::Auth::V1::Authentication::PasswordCredential

The password credential for a user that is sent from the client to the
server during authentication.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scram() >> / C<< $msg->scram($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::PasswordCredential::Scram>)

The SCRAM credential contains the server and stored keys.

=item * C<< $msg->opaque() >> / C<< $msg->opaque($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::PasswordCredential::Opaque>)

The OPAQUE credential contains the client public key, masking key,
envelope nonce, and auth tag.

=back

=head2 Google::Spanner::Auth::V1::Authentication::InitialScramResponse

InitialScramResponse is returned by the server so that the client can
generate the credential using the SCRAM protocol.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->salt() >> / C<< $msg->salt($value) >>

Type: C<Bytes>

The salt to use when hashing the password.

=item * C<< $msg->server_nonce() >> / C<< $msg->server_nonce($value) >>

Type: C<Bytes>

Nonce provided by the server.

=back

=head2 Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest

A request to create a new SCRAM credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial_request() >> / C<< $msg->initial_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::InitialRequest>)

The initial request to start the SCRAM handshake.

=item * C<< $msg->final_request() >> / C<< $msg->final_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::FinalRequest>)

The final request to complete the SCRAM handshake.

=back

=head2 Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse

The response to create a new user using SCRAM credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial_response() >> / C<< $msg->initial_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::InitialScramResponse>)

The initial response from the server.

=item * C<< $msg->final_response() >> / C<< $msg->final_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse::FinalResponse>)

The final response from the server.

=back

=head2 Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest

A request to create new OPAQUE credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial_request() >> / C<< $msg->initial_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::InitialRequest>)

The initial request for OPAQUE user creation.

=item * C<< $msg->final_request() >> / C<< $msg->final_request($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::FinalRequest>)

The final request for OPAQUE user creation.

=back

=head2 Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse

The response from the server when creating a new user using OPAQUE
credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->initial_response() >> / C<< $msg->initial_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::InitialResponse>)

The initial response for OPAQUE user creation.

=item * C<< $msg->final_response() >> / C<< $msg->final_response($value) >>

Type: C<Message> (L<Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::FinalResponse>)

The final response for OPAQUE user creation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::Auth::V1::Authentication::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
