package Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings };
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::ResponseMessage };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2Z1bGZpbGxtZW50LnByb3Rv
EiJnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjpnb29nbGUvY2xv
dWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2FkdmFuY2VkX3NldHRpbmdzLnByb3RvGjlnb29n
bGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3Jlc3BvbnNlX21lc3NhZ2UucHJvdG8a
HGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8iug0KC0Z1bGZpbGxtZW50Ek8KCG1lc3Nh
Z2VzGAEgAygLMjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5SZXNwb25z
ZU1lc3NhZ2VSCG1lc3NhZ2VzEkAKB3dlYmhvb2sYAiABKAlCJvpBIwohZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9XZWJob29rUgd3ZWJob29rEjgKGHJldHVybl9wYXJ0aWFsX3Jlc3Bv
bnNlcxgIIAEoCFIWcmV0dXJuUGFydGlhbFJlc3BvbnNlcxIQCgN0YWcYAyABKAlSA3RhZxIz
ChNjb2RlX2Jsb2NrX2Z1bmN0aW9uGBEgASgJQgPgQQFSEWNvZGVCbG9ja0Z1bmN0aW9uEnYK
FXNldF9wYXJhbWV0ZXJfYWN0aW9ucxgEIAMoCzJCLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuRnVsZmlsbG1lbnQuU2V0UGFyYW1ldGVyQWN0aW9uUhNzZXRQYXJhbWV0
ZXJBY3Rpb25zEm0KEWNvbmRpdGlvbmFsX2Nhc2VzGAUgAygLMkAuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5GdWxmaWxsbWVudC5Db25kaXRpb25hbENhc2VzUhBjb25k
aXRpb25hbENhc2VzEmEKEWFkdmFuY2VkX3NldHRpbmdzGAcgASgLMjQuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5BZHZhbmNlZFNldHRpbmdzUhBhZHZhbmNlZFNldHRp
bmdzEjwKGmVuYWJsZV9nZW5lcmF0aXZlX2ZhbGxiYWNrGAwgASgIUhhlbmFibGVHZW5lcmF0
aXZlRmFsbGJhY2sSYQoKZ2VuZXJhdG9ycxgNIAMoCzJBLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuRnVsZmlsbG1lbnQuR2VuZXJhdG9yU2V0dGluZ3NSCmdlbmVyYXRv
cnMaYAoSU2V0UGFyYW1ldGVyQWN0aW9uEhwKCXBhcmFtZXRlchgBIAEoCVIJcGFyYW1ldGVy
EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZRrwAwoQQ29u
ZGl0aW9uYWxDYXNlcxJbCgVjYXNlcxgBIAMoCzJFLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuRnVsZmlsbG1lbnQuQ29uZGl0aW9uYWxDYXNlcy5DYXNlUgVjYXNlcxr+
AgoEQ2FzZRIcCgljb25kaXRpb24YASABKAlSCWNvbmRpdGlvbhJ0CgxjYXNlX2NvbnRlbnQY
AiADKAsyUS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkZ1bGZpbGxtZW50
LkNvbmRpdGlvbmFsQ2FzZXMuQ2FzZS5DYXNlQ29udGVudFILY2FzZUNvbnRlbnQa4QEKC0Nh
c2VDb250ZW50Ek8KB21lc3NhZ2UYASABKAsyMy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLlJlc3BvbnNlTWVzc2FnZUgAUgdtZXNzYWdlEm0KEGFkZGl0aW9uYWxfY2Fz
ZXMYAiABKAsyQC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkZ1bGZpbGxt
ZW50LkNvbmRpdGlvbmFsQ2FzZXNIAFIPYWRkaXRpb25hbENhc2VzQhIKEGNhc2VzX29yX21l
c3NhZ2Ua1gIKEUdlbmVyYXRvclNldHRpbmdzEkkKCWdlbmVyYXRvchgBIAEoCUIr4EEC+kEl
CiNkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0dlbmVyYXRvclIJZ2VuZXJhdG9yEoEBChBp
bnB1dF9wYXJhbWV0ZXJzGAIgAygLMlYuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5GdWxmaWxsbWVudC5HZW5lcmF0b3JTZXR0aW5ncy5JbnB1dFBhcmFtZXRlcnNFbnRy
eVIPaW5wdXRQYXJhbWV0ZXJzEi4KEG91dHB1dF9wYXJhbWV0ZXIYAyABKAlCA+BBAlIPb3V0
cHV0UGFyYW1ldGVyGkIKFElucHV0UGFyYW1ldGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCxwEKJmNvbS5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52M2JldGExQhBGdWxmaWxsbWVudFByb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20v
Z28vZGlhbG9nZmxvdy9jeC9hcGl2M2JldGExL2N4cGI7Y3hwYqICAkRGqgIiR29vZ2xlLkNs
b3VkLkRpYWxvZ2Zsb3cuQ3guVjNCZXRhMeoCJkdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6
OkNYOjpWM2JldGExSoI3CgcSBQ4AsAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABECgkKAgMD
EgMVAEMKCQoCAwQSAxYAJgoICgEIEgMYAD8KCQoCCCUSAxgAPwoICgEIEgMZAE0KCQoCCAsS
AxkATQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADEKCQoCCAgSAxsAMQoICgEIEgMc
AD8KCQoCCAESAxwAPwoICgEIEgMdACAKCQoCCCQSAx0AIAoICgEIEgMeAD8KCQoCCC0SAx4A
PwqUBgoCBAASBTEAsAEBGoYGIEEgZnVsZmlsbG1lbnQgY2FuIGRvIG9uZSBvciBtb3JlIG9m
IHRoZSBmb2xsb3dpbmcgYWN0aW9ucyBhdCB0aGUgc2FtZSB0aW1lOgoKICAgKiBHZW5lcmF0
ZSByaWNoIG1lc3NhZ2UgcmVzcG9uc2VzLgogICAqIFNldCBwYXJhbWV0ZXIgdmFsdWVzLgog
ICAqIENhbGwgdGhlIHdlYmhvb2suCgogRnVsZmlsbG1lbnRzIGNhbiBiZSBjYWxsZWQgYXQg
dmFyaW91cyBzdGFnZXMgaW4gdGhlCiBbUGFnZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5QYWdlXSBvcgogW0Zvcm1dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuRm9ybV0gbGlmZWN5Y2xlLiBGb3IgZXhhbXBsZSwgd2hlbgogYQogW0RldGVj
dEludGVudFJlcXVlc3RdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRGV0
ZWN0SW50ZW50UmVxdWVzdF0KIGRyaXZlcyBhIHNlc3Npb24gdG8gZW50ZXIgYSBuZXcgcGFn
ZSwgdGhlIHBhZ2UncyBlbnRyeSBmdWxmaWxsbWVudCBjYW4gYWRkIGEKIHN0YXRpYyByZXNw
b25zZSB0byB0aGUKIFtRdWVyeVJlc3VsdF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djNiZXRhMS5RdWVyeVJlc3VsdF0gaW4gdGhlCiByZXR1cm5pbmcKIFtEZXRlY3RJbnRlbnRS
ZXNwb25zZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5EZXRlY3RJbnRl
bnRSZXNwb25zZV0sCiBjYWxsIHRoZSB3ZWJob29rIChmb3IgZXhhbXBsZSwgdG8gbG9hZCB1
c2VyIGRhdGEgZnJvbSBhIGRhdGFiYXNlKSwgb3IgYm90aC4KCgoKAwQAARIDMQgTCioKBAQA
AwASBDMCOQMaHCBTZXR0aW5nIGEgcGFyYW1ldGVyIHZhbHVlLgoKDAoFBAADAAESAzMKHAov
CgYEAAMAAgASAzUEGRogIERpc3BsYXkgbmFtZSBvZiB0aGUgcGFyYW1ldGVyLgoKDgoHBAAD
AAIABRIDNQQKCg4KBwQAAwACAAESAzULFAoOCgcEAAMAAgADEgM1FxgKUwoGBAADAAIBEgM4
BCQaRCBUaGUgbmV3IHZhbHVlIG9mIHRoZSBwYXJhbWV0ZXIuIEEgbnVsbCB2YWx1ZSBjbGVh
cnMgdGhlIHBhcmFtZXRlci4KCg4KBwQAAwACAQYSAzgEGQoOCgcEAAMAAgEBEgM4Gh8KDgoH
BAADAAIBAxIDOCIjCqIBCgQEAAMBEgQ9AlwDGpMBIEEgbGlzdCBvZiBjYXNjYWRpbmcgaWYt
ZWxzZSBjb25kaXRpb25zLiBDYXNlcyBhcmUgbXV0dWFsbHkgZXhjbHVzaXZlLgogVGhlIGZp
cnN0IG9uZSB3aXRoIGEgbWF0Y2hpbmcgY29uZGl0aW9uIGlzIHNlbGVjdGVkLCBhbGwgdGhl
IHJlc3QgaWdub3JlZC4KCgwKBQQAAwEBEgM9ChoKngEKBgQAAwEDABIEQARYBRqNASBFYWNo
IGNhc2UgaGFzIGEgQm9vbGVhbiBjb25kaXRpb24uIFdoZW4gaXQgaXMgZXZhbHVhdGVkIHRv
IGJlIFRydWUsIHRoZQogY29ycmVzcG9uZGluZyBtZXNzYWdlcyB3aWxsIGJlIHNlbGVjdGVk
IGFuZCBldmFsdWF0ZWQgcmVjdXJzaXZlbHkuCgoOCgcEAAMBAwABEgNADBAKWAoIBAADAQMA
AwASBEIGSwcaRiBUaGUgbGlzdCBvZiBtZXNzYWdlcyBvciBjb25kaXRpb25hbCBjYXNlcyB0
byBhY3RpdmF0ZSBmb3IgdGhpcyBjYXNlLgoKEAoJBAADAQMAAwABEgNCDhkKVwoKBAADAQMA
AwAIABIERAhKCRpDIEVpdGhlciBhIG1lc3NhZ2UgaXMgcmV0dXJuZWQgb3IgYWRkaXRpb25h
bCBjYXNlcyB0byBiZSBldmFsdWF0ZWQuCgoSCgsEAAMBAwADAAgAARIDRA4eCiYKCgQAAwED
AAMAAgASA0YKJhoTIFJldHVybmVkIG1lc3NhZ2UuCgoSCgsEAAMBAwADAAIABhIDRgoZChIK
CwQAAwEDAAMAAgABEgNGGiEKEgoLBAADAQMAAwACAAMSA0YkJQo2CgoEAAMBAwADAAIBEgNJ
CjAaIyBBZGRpdGlvbmFsIGNhc2VzIHRvIGJlIGV2YWx1YXRlZC4KChIKCwQAAwEDAAMAAgEG
EgNJChoKEgoLBAADAQMAAwACAQESA0kbKwoSCgsEAAMBAwADAAIBAxIDSS4vCssCCggEAAMB
AwACABIDVAYbGrkCIFRoZSBjb25kaXRpb24gdG8gYWN0aXZhdGUgYW5kIHNlbGVjdCB0aGlz
IGNhc2UuIEVtcHR5IG1lYW5zIHRoZQogY29uZGl0aW9uIGlzIGFsd2F5cyB0cnVlLiBUaGUg
Y29uZGl0aW9uIGlzIGV2YWx1YXRlZCBhZ2FpbnN0IFtmb3JtCiBwYXJhbWV0ZXJzXVtGb3Jt
LnBhcmFtZXRlcnNdIG9yIFtzZXNzaW9uCiBwYXJhbWV0ZXJzXVtTZXNzaW9uSW5mby5wYXJh
bWV0ZXJzXS4KCiBTZWUgdGhlIFtjb25kaXRpb25zCiByZWZlcmVuY2VdKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2N4L2RvY3MvcmVmZXJlbmNlL2NvbmRpdGlvbiku
CgoQCgkEAAMBAwACAAUSA1QGDAoQCgkEAAMBAwACAAESA1QNFgoQCgkEAAMBAwACAAMSA1QZ
GgoqCggEAAMBAwACARIDVwYsGhkgQSBsaXN0IG9mIGNhc2UgY29udGVudC4KChAKCQQAAwED
AAIBBBIDVwYOChAKCQQAAwEDAAIBBhIDVw8aChAKCQQAAwEDAAIBARIDVxsnChAKCQQAAwED
AAIBAxIDVyorCjgKBgQAAwECABIDWwQcGikgQSBsaXN0IG9mIGNhc2NhZGluZyBpZi1lbHNl
IGNvbmRpdGlvbnMuCgoOCgcEAAMBAgAEEgNbBAwKDgoHBAADAQIABhIDWw0RCg4KBwQAAwEC
AAESA1sSFwoOCgcEAAMBAgADEgNbGhsKTwoEBAADAhIEXwJ4AxpBIEdlbmVyYXRvciBzZXR0
aW5ncyB1c2VkIGJ5IHRoZSBMTE0gdG8gZ2VuZXJhdGUgYSB0ZXh0IHJlc3BvbnNlLgoKDAoF
BAADAgESA18KGwqWAQoGBAADAgIAEgRjBGgGGoUBIFJlcXVpcmVkLiBUaGUgZ2VuZXJhdG9y
IHRvIGNhbGwuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxM
b2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2dlbmVyYXRvcnMvPEdlbmVyYXRvcklEPmAu
CgoOCgcEAAMCAgAFEgNjBAoKDgoHBAADAgIAARIDYwsUCg4KBwQAAwICAAMSA2MXGAoPCgcE
AAMCAgAIEgRjGWgFChEKCgQAAwICAAicCAASA2QGLAoRCgkEAAMCAgAInwgSBGUGZwcKzwQK
BgQAAwICARIDdAQtGr8EIE1hcCBmcm9tIFtwbGFjZWhvbGRlciBwYXJhbWV0ZXJdW0dlbmVy
YXRvci5QYXJhbWV0ZXIuaWRdIGluIHRoZQogW0dlbmVyYXRvcl1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5HZW5lcmF0b3JdIHRvCiBjb3JyZXNwb25kaW5nIHNlc3Np
b24gcGFyYW1ldGVycy4gQnkgZGVmYXVsdCwgRGlhbG9nZmxvdyB1c2VzIHRoZSBzZXNzaW9u
CiBwYXJhbWV0ZXIgd2l0aCB0aGUgc2FtZSBuYW1lIHRvIGZpbGwgaW4gdGhlIGdlbmVyYXRv
ciB0ZW1wbGF0ZS4gZS5nLiBJZgogdGhlcmUgaXMgYSBwbGFjZWhvbGRlciBwYXJhbWV0ZXIg
YGNpdHlgIGluIHRoZSBHZW5lcmF0b3IsIERpYWxvZ2Zsb3cKIGRlZmF1bHQgdG8gZmlsbCBp
biB0aGUgYCRjaXR5YCB3aXRoCiBgJHNlc3Npb24ucGFyYW1zLmNpdHlgLiBIb3dldmVyLCB5
b3UgbWF5IGNob29zZSB0byBmaWxsIGAkY2l0eWAgd2l0aAogYCRzZXNzaW9uLnBhcmFtcy5k
ZXNpbmF0aW9uLWNpdHlgLgogLSBNYXAga2V5OiBbcGFyYW1ldGVyIElEXVtHZW5yYXRvci5Q
YXJhbWV0ZXIuaWRdCiAtIE1hcCB2YWx1ZTogc2Vzc2lvbiBwYXJhbWV0ZXIgbmFtZQoKDgoH
BAADAgIBBhIDdAQXCg4KBwQAAwICAQESA3QYKAoOCgcEAAMCAgEDEgN0KywKWAoGBAADAgIC
EgN3BEkaSSBSZXF1aXJlZC4gT3V0cHV0IHBhcmFtZXRlciB3aGljaCBzaG91bGQgY29udGFp
biB0aGUgZ2VuZXJhdG9yIHJlc3BvbnNlLgoKDgoHBAADAgICBRIDdwQKCg4KBwQAAwICAgES
A3cLGwoOCgcEAAMCAgIDEgN3Hh8KDgoHBAADAgICCBIDdyBIChEKCgQAAwICAgicCAASA3ch
RwpJCgQEAAIAEgN7AigaPCBUaGUgbGlzdCBvZiByaWNoIG1lc3NhZ2UgcmVzcG9uc2VzIHRv
IHByZXNlbnQgdG8gdGhlIHVzZXIuCgoMCgUEAAIABBIDewIKCgwKBQQAAgAGEgN7CxoKDAoF
BAACAAESA3sbIwoMCgUEAAIAAxIDeyYnCoUBCgQEAAIBEgaAAQKCAQUadSBUaGUgd2ViaG9v
ayB0byBjYWxsLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88
TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi93ZWJob29rcy88V2ViaG9va0lEPmAuCgoN
CgUEAAIBBRIEgAECCAoNCgUEAAIBARIEgAEJEAoNCgUEAAIBAxIEgAETFAoPCgUEAAIBCBIG
gAEVggEEChEKBwQAAgEInwgSBoABFoIBAwrnAwoEBAACAhIEjQECJBrYAyBXaGV0aGVyIERp
YWxvZ2Zsb3cgc2hvdWxkIHJldHVybiBjdXJyZW50bHkgcXVldWVkIGZ1bGZpbGxtZW50IHJl
c3BvbnNlCiBtZXNzYWdlcyBpbiBzdHJlYW1pbmcgQVBJcy4gSWYgYSB3ZWJob29rIGlzIHNw
ZWNpZmllZCwgaXQgaGFwcGVucyBiZWZvcmUKIERpYWxvZ2Zsb3cgaW52b2tlcyB3ZWJob29r
LgogV2FybmluZzoKIDEpIFRoaXMgZmxhZyBvbmx5IGFmZmVjdHMgc3RyZWFtaW5nIEFQSS4g
UmVzcG9uc2VzIGFyZSBzdGlsbCBxdWV1ZWQKIGFuZCByZXR1cm5lZCBvbmNlIGluIG5vbi1z
dHJlYW1pbmcgQVBJLgogMikgVGhlIGZsYWcgY2FuIGJlIGVuYWJsZWQgaW4gYW55IGZ1bGZp
bGxtZW50IGJ1dCBvbmx5IHRoZSBmaXJzdCAzIHBhcnRpYWwKIHJlc3BvbnNlcyB3aWxsIGJl
IHJldHVybmVkLiBZb3UgbWF5IG9ubHkgd2FudCB0byBhcHBseSBpdCB0byBmdWxmaWxsbWVu
dHMKIHRoYXQgaGF2ZSBzbG93IHdlYmhvb2tzLgoKDQoFBAACAgUSBI0BAgYKDQoFBAACAgES
BI0BBx8KDQoFBAACAgMSBI0BIiMKlwMKBAQAAgMSBJYBAhEaiAMgVGhlIHZhbHVlIG9mIHRo
aXMgZmllbGQgd2lsbCBiZSBwb3B1bGF0ZWQgaW4gdGhlCiBbV2ViaG9va1JlcXVlc3RdW2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuV2ViaG9va1JlcXVlc3RdCiBgZnVs
ZmlsbG1lbnRJbmZvLnRhZ2AgZmllbGQgYnkgRGlhbG9nZmxvdyB3aGVuIHRoZSBhc3NvY2lh
dGVkIHdlYmhvb2sgaXMKIGNhbGxlZC4KIFRoZSB0YWcgaXMgdHlwaWNhbGx5IHVzZWQgYnkg
dGhlIHdlYmhvb2sgc2VydmljZSB0byBpZGVudGlmeSB3aGljaAogZnVsZmlsbG1lbnQgaXMg
YmVpbmcgY2FsbGVkLCBidXQgaXQgY291bGQgYmUgdXNlZCBmb3Igb3RoZXIgcHVycG9zZXMu
CiBUaGlzIGZpZWxkIGlzIHJlcXVpcmVkIGlmIGB3ZWJob29rYCBpcyBzcGVjaWZpZWQuCgoN
CgUEAAIDBRIElgECCAoNCgUEAAIDARIElgEJDAoNCgUEAAIDAxIElgEPEArAAQoEBAACBBIE
mwECSxqxASBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIGNvZGUgYmxvY2sgZnVuY3Rpb24g
dG8gZXhlY3V0ZSwgaWYgdGhpcyBpcyBhIGNvZGUKIGJsb2NrIGZ1bGZpbGxtZW50LiBUaGUg
Y29kZSBibG9jayBpdHNlbGYgaXMgaW1wbGllZCBieSB0aGUgZnVsZmlsbG1lbnQncwogcGFy
ZW50LCBlLmcuIGEgcGxheWJvb2suCgoNCgUEAAIEBRIEmwECCAoNCgUEAAIEARIEmwEJHAoN
CgUEAAIEAxIEmwEfIQoNCgUEAAIECBIEmwEiSgoQCggEAAIECJwIABIEmwEjSQpCCgQEAAIF
EgSeAQI4GjQgU2V0IHBhcmFtZXRlciB2YWx1ZXMgYmVmb3JlIGV4ZWN1dGluZyB0aGUgd2Vi
aG9vay4KCg0KBQQAAgUEEgSeAQIKCg0KBQQAAgUGEgSeAQsdCg0KBQQAAgUBEgSeAR4zCg0K
BQQAAgUDEgSeATY3CjcKBAQAAgYSBKEBAjIaKSBDb25kaXRpb25hbCBjYXNlcyBmb3IgdGhp
cyBmdWxmaWxsbWVudC4KCg0KBQQAAgYEEgShAQIKCg0KBQQAAgYGEgShAQsbCg0KBQQAAgYB
EgShARwtCg0KBQQAAgYDEgShATAxCqIBCgQEAAIHEgSlAQIpGpMBIEhpZXJhcmNoaWNhbCBh
ZHZhbmNlZCBzZXR0aW5ncyBmb3IgdGhpcyBmdWxmaWxsbWVudC4gVGhlIHNldHRpbmdzIGV4
cG9zZWQKIGF0IHRoZSBsb3dlciBsZXZlbCBvdmVycmlkZXMgdGhlIHNldHRpbmdzIGV4cG9z
ZWQgYXQgdGhlIGhpZ2hlciBsZXZlbC4KCg0KBQQAAgcGEgSlAQISCg0KBQQAAgcBEgSlARMk
Cg0KBQQAAgcDEgSlAScoCsQCCgQEAAIIEgSsAQInGrUCIElmIHRoZSBmbGFnIGlzIHRydWUs
IHRoZSBhZ2VudCB3aWxsIHV0aWxpemUgTExNIHRvIGdlbmVyYXRlIGEgdGV4dAogcmVzcG9u
c2UuIElmIExMTSBnZW5lcmF0aW9uIGZhaWxzLCB0aGUgZGVmaW5lZAogW3Jlc3BvbnNlc11b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5GdWxmaWxsbWVudC5tZXNzYWdl
c10gaW4gdGhlCiBmdWxmaWxsbWVudCB3aWxsIGJlIHJlc3BlY3RlZC4gVGhpcyBmbGFnIGlz
IG9ubHkgdXNlZnVsIGZvciBmdWxmaWxsbWVudHMKIGFzc29jaWF0ZWQgd2l0aCBuby1tYXRj
aCBldmVudCBoYW5kbGVycy4KCg0KBQQAAggFEgSsAQIGCg0KBQQAAggBEgSsAQchCg0KBQQA
AggDEgSsASQmCkoKBAQAAgkSBK8BAi0aPCBBIGxpc3Qgb2YgR2VuZXJhdG9ycyB0byBiZSBj
YWxsZWQgZHVyaW5nIHRoaXMgZnVsZmlsbG1lbnQuCgoNCgUEAAIJBBIErwECCgoNCgUEAAIJ
BhIErwELHAoNCgUEAAIJARIErwEdJwoNCgUEAAIJAxIErwEqLGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment ===
    # Fields for Fulfillment
    # Field: messages Type: 11 (.google.cloud.dialogflow.cx.v3beta1.ResponseMessage)
    # Field: webhook Type: 9 ()
    # Field: return_partial_responses Type: 8 ()
    # Field: tag Type: 9 ()
    # Field: code_block_function Type: 9 ()
    # Field: set_parameter_actions Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Fulfillment.SetParameterAction)
    # Field: conditional_cases Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Fulfillment.ConditionalCases)
    # Field: advanced_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.AdvancedSettings)
    # Field: enable_generative_fallback Type: 8 ()
    # Field: generators Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Fulfillment.GeneratorSettings)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/fulfillment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment->new({
        messages => $messages,
        webhook => $webhook,
        return_partial_responses => $return_partial_responses,
        tag => $tag,
    });

    # Read or update a field
    my $val = $msg->messages();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/fulfillment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment

A fulfillment can do one or more of the following actions at the same time:

  * Generate rich message responses.
  * Set parameter values.
  * Call the webhook.

Fulfillments can be called at various stages in the
[Page][google.cloud.dialogflow.cx.v3beta1.Page] or
[Form][google.cloud.dialogflow.cx.v3beta1.Form] lifecycle. For example, when
a
[DetectIntentRequest][google.cloud.dialogflow.cx.v3beta1.DetectIntentRequest]
drives a session to enter a new page, the page's entry fulfillment can add a
static response to the
[QueryResult][google.cloud.dialogflow.cx.v3beta1.QueryResult] in the
returning
[DetectIntentResponse][google.cloud.dialogflow.cx.v3beta1.DetectIntentResponse],
call the webhook (for example, to load user data from a database), or both.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ResponseMessage::ResponseMessage>)

The list of rich message responses to present to the user.

=item * C<< $msg->webhook() >> / C<< $msg->webhook($value) >>

Type: C<String>

The webhook to call.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/webhooks/<WebhookID>`.

=item * C<< $msg->return_partial_responses() >> / C<< $msg->return_partial_responses($value) >>

Type: C<Bool>

Whether Dialogflow should return currently queued fulfillment response
messages in streaming APIs. If a webhook is specified, it happens before
Dialogflow invokes webhook.
Warning:
1) This flag only affects streaming API. Responses are still queued
and returned once in non-streaming API.
2) The flag can be enabled in any fulfillment but only the first 3 partial
responses will be returned. You may only want to apply it to fulfillments
that have slow webhooks.

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

The value of this field will be populated in the
[WebhookRequest][google.cloud.dialogflow.cx.v3beta1.WebhookRequest]
`fulfillmentInfo.tag` field by Dialogflow when the associated webhook is
called.
The tag is typically used by the webhook service to identify which
fulfillment is being called, but it could be used for other purposes.
This field is required if `webhook` is specified.

=item * C<< $msg->code_block_function() >> / C<< $msg->code_block_function($value) >>

Type: C<String>

Optional. The name of the code block function to execute, if this is a code
block fulfillment. The code block itself is implied by the fulfillment's
parent, e.g. a playbook.

=item * C<< $msg->set_parameter_actions() >> / C<< $msg->set_parameter_actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::SetParameterAction>)

Set parameter values before executing the webhook.

=item * C<< $msg->conditional_cases() >> / C<< $msg->conditional_cases($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases>)

Conditional cases for this fulfillment.

=item * C<< $msg->advanced_settings() >> / C<< $msg->advanced_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings>)

Hierarchical advanced settings for this fulfillment. The settings exposed
at the lower level overrides the settings exposed at the higher level.

=item * C<< $msg->enable_generative_fallback() >> / C<< $msg->enable_generative_fallback($value) >>

Type: C<Bool>

If the flag is true, the agent will utilize LLM to generate a text
response. If LLM generation fails, the defined
[responses][google.cloud.dialogflow.cx.v3beta1.Fulfillment.messages] in the
fulfillment will be respected. This flag is only useful for fulfillments
associated with no-match event handlers.

=item * C<< $msg->generators() >> / C<< $msg->generators($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings>)

A list of Generators to be called during this fulfillment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
