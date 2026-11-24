package Google::Cloud::Dialogflow::V2beta1::Version;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3ZlcnNpb24ucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIv4DCgdWZXJzaW9uEhcKBG5hbWUYASABKAlCA+BBA1IE
bmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhIqCg52ZXJzaW9u
X251bWJlchgDIAEoBUID4EEDUg12ZXJzaW9uTnVtYmVyEkAKC2NyZWF0ZV90aW1lGAQgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lElMKBnN0YXR1
cxgGIAEoDjI2Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuVmVyc2lvbi5WZXJz
aW9uU3RhdHVzQgPgQQNSBnN0YXR1cyJXCg1WZXJzaW9uU3RhdHVzEh4KGlZFUlNJT05fU1RB
VFVTX1VOU1BFQ0lGSUVEEAASDwoLSU5fUFJPR1JFU1MQARIJCgVSRUFEWRACEgoKBkZBSUxF
RBADOpYB6kGSAQohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9WZXJzaW9uEitwcm9qZWN0
cy97cHJvamVjdH0vYWdlbnQvdmVyc2lvbnMve3ZlcnNpb259EkBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnQvdmVyc2lvbnMve3ZlcnNpb259Ip4BChNM
aXN0VmVyc2lvbnNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFkaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BB
AVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4ihAEKFExp
c3RWZXJzaW9uc1Jlc3BvbnNlEkQKCHZlcnNpb25zGAEgAygLMiguZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjJiZXRhMS5WZXJzaW9uUgh2ZXJzaW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4Y
AiABKAlSDW5leHRQYWdlVG9rZW4iUgoRR2V0VmVyc2lvblJlcXVlc3QSPQoEbmFtZRgBIAEo
CUIp4EEC+kEjCiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SBG5hbWUiogEK
FENyZWF0ZVZlcnNpb25SZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SBnBhcmVudBJHCgd2ZXJzaW9uGAIgASgLMigu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5WZXJzaW9uQgPgQQJSB3ZlcnNpb24i
oQEKFFVwZGF0ZVZlcnNpb25SZXF1ZXN0EkcKB3ZlcnNpb24YASABKAsyKC5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MmJldGExLlZlcnNpb25CA+BBAlIHdmVyc2lvbhJACgt1cGRhdGVf
bWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFz
ayJVChREZWxldGVWZXJzaW9uUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWRpYWxv
Z2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblIEbmFtZTLbCgoIVmVyc2lvbnMS9AEKDExp
c3RWZXJzaW9ucxI0Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuTGlzdFZlcnNp
b25zUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuTGlzdFZlcnNp
b25zUmVzcG9uc2Uid4LT5JMCaBIrL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50
fS92ZXJzaW9uc1o5EjcvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
YWdlbnR9L3ZlcnNpb25z2kEGcGFyZW50EuEBCgpHZXRWZXJzaW9uEjIuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjJiZXRhMS5HZXRWZXJzaW9uUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuVmVyc2lvbiJ1gtPkkwJoEisvdjJiZXRhMS97bmFtZT1wcm9q
ZWN0cy8qL2FnZW50L3ZlcnNpb25zLyp9WjkSNy92MmJldGExL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovYWdlbnQvdmVyc2lvbnMvKn3aQQRuYW1lEoQCCg1DcmVhdGVWZXJzaW9u
EjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5DcmVhdGVWZXJzaW9uUmVxdWVz
dBooLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuVmVyc2lvbiKRAYLT5JMCeiIr
L3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50fS92ZXJzaW9uczoHdmVyc2lvblpC
IjcvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnR9L3ZlcnNp
b25zOgd2ZXJzaW9u2kEOcGFyZW50LHZlcnNpb24SmgIKDVVwZGF0ZVZlcnNpb24SNS5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlVwZGF0ZVZlcnNpb25SZXF1ZXN0GiguZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5WZXJzaW9uIqcBgtPkkwKKATIzL3YyYmV0
YTEve3ZlcnNpb24ubmFtZT1wcm9qZWN0cy8qL2FnZW50L3ZlcnNpb25zLyp9Ogd2ZXJzaW9u
WkoyPy92MmJldGExL3t2ZXJzaW9uLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2Vu
dC92ZXJzaW9ucy8qfToHdmVyc2lvbtpBE3ZlcnNpb24sdXBkYXRlX21hc2sS1QEKDURlbGV0
ZVZlcnNpb24SNS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkRlbGV0ZVZlcnNp
b25SZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5InWC0+STAmgqKy92MmJldGExL3tu
YW1lPXByb2plY3RzLyovYWdlbnQvdmVyc2lvbnMvKn1aOSo3L3YyYmV0YTEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC92ZXJzaW9ucy8qfdpBBG5hbWUaeMpBGWRpYWxv
Z2Zsb3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlhbG9n
Zmxvd0KhAQojY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTFCDFZlcnNpb25Q
cm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRhMS9kaWFs
b2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5W
MkJldGExSqE7CgcSBQ4AiwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMK
CQoCAwQSAxYAJQoJCgIDBRIDFwAqCgkKAgMGEgMYACkKCAoBCBIDGgA8CgkKAgglEgMaADwK
CAoBCBIDGwBaCgkKAggLEgMbAFoKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQAtCgkK
AggIEgMdAC0KCAoBCBIDHgA8CgkKAggBEgMeADwKCAoBCBIDHwAgCgkKAggkEgMfACAKVwoC
BgASBCIAaAEaSyBTZXJ2aWNlIGZvciBtYW5hZ2luZyBbVmVyc2lvbnNdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuVmVyc2lvbl0uCgoKCgMGAAESAyIIEAoKCgMGAAMSAyMC
QQoMCgUGAAOZCBIDIwJBCgsKAwYAAxIEJAImMwoNCgUGAAOaCBIEJAImMwpICgQGAAIAEgQp
AjEDGjogUmV0dXJucyB0aGUgbGlzdCBvZiBhbGwgdmVyc2lvbnMgb2YgdGhlIHNwZWNpZmll
ZCBhZ2VudC4KCgwKBQYAAgABEgMpBhIKDAoFBgACAAISAykTJgoMCgUGAAIAAxIDKTFFCg0K
BQYAAgAEEgQqBC8GChEKCQYAAgAEsMq8IhIEKgQvBgoMCgUGAAIABBIDMAQ0Cg8KCAYAAgAE
mwgAEgMwBDQKNgoEBgACARIENAI8AxooIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIGFnZW50
IHZlcnNpb24uCgoMCgUGAAIBARIDNAYQCgwKBQYAAgECEgM0ESIKDAoFBgACAQMSAzQtNAoN
CgUGAAIBBBIENQQ6BgoRCgkGAAIBBLDKvCISBDUEOgYKDAoFBgACAQQSAzsEMgoPCggGAAIB
BJsIABIDOwQyCnYKBAYAAgISBEECSwMaaCBDcmVhdGVzIGFuIGFnZW50IHZlcnNpb24uCgog
VGhlIG5ldyB2ZXJzaW9uIHBvaW50cyB0byB0aGUgYWdlbnQgaW5zdGFuY2UgaW4gdGhlICJk
ZWZhdWx0IiBlbnZpcm9ubWVudC4KCgwKBQYAAgIBEgNBBhMKDAoFBgACAgISA0EUKAoMCgUG
AAICAxIDQTM6Cg0KBQYAAgIEEgRCBEkGChEKCQYAAgIEsMq8IhIEQgRJBgoMCgUGAAICBBID
SgQ8Cg8KCAYAAgIEmwgAEgNKBDwK6QEKBAYAAgMSBFICXAMa2gEgVXBkYXRlcyB0aGUgc3Bl
Y2lmaWVkIGFnZW50IHZlcnNpb24uCgogTm90ZSB0aGF0IHRoaXMgbWV0aG9kIGRvZXMgbm90
IGFsbG93IHlvdSB0byB1cGRhdGUgdGhlIHN0YXRlIG9mIHRoZSBhZ2VudAogdGhlIGdpdmVu
IHZlcnNpb24gcG9pbnRzIHRvLiBJdCBhbGxvd3MgeW91IHRvIHVwZGF0ZSBvbmx5IG11dGFi
bGUKIHByb3BlcnRpZXMgb2YgdGhlIHZlcnNpb24gcmVzb3VyY2UuCgoMCgUGAAIDARIDUgYT
CgwKBQYAAgMCEgNSFCgKDAoFBgACAwMSA1IzOgoNCgUGAAIDBBIEUwRaBgoRCgkGAAIDBLDK
vCISBFMEWgYKDAoFBgACAwQSA1sEQQoPCggGAAIDBJsIABIDWwRBCjMKBAYAAgQSBF8CZwMa
JSBEZWxldGUgdGhlIHNwZWNpZmllZCBhZ2VudCB2ZXJzaW9uLgoKDAoFBgACBAESA18GEwoM
CgUGAAIEAhIDXxQoCgwKBQYAAgQDEgNfM0gKDQoFBgACBAQSBGAEZQYKEQoJBgACBASwyrwi
EgRgBGUGCgwKBQYAAgQEEgNmBDIKDwoIBgACBASbCAASA2YEMgqVBQoCBAASBXwAqAEBGocF
IFlvdSBjYW4gY3JlYXRlIG11bHRpcGxlIHZlcnNpb25zIG9mIHlvdXIgYWdlbnQgYW5kIHB1
Ymxpc2ggdGhlbSB0byBzZXBhcmF0ZQogZW52aXJvbm1lbnRzLgoKIFdoZW4geW91IGVkaXQg
YW4gYWdlbnQsIHlvdSBhcmUgZWRpdGluZyB0aGUgZHJhZnQgYWdlbnQuIEF0IGFueSBwb2lu
dCwgeW91CiBjYW4gc2F2ZSB0aGUgZHJhZnQgYWdlbnQgYXMgYW4gYWdlbnQgdmVyc2lvbiwg
d2hpY2ggaXMgYW4gaW1tdXRhYmxlIHNuYXBzaG90CiBvZiB5b3VyIGFnZW50LgoKIFdoZW4g
eW91IHNhdmUgdGhlIGRyYWZ0IGFnZW50LCBpdCBpcyBwdWJsaXNoZWQgdG8gdGhlIGRlZmF1
bHQgZW52aXJvbm1lbnQuCiBXaGVuIHlvdSBjcmVhdGUgYWdlbnQgdmVyc2lvbnMsIHlvdSBj
YW4gcHVibGlzaCB0aGVtIHRvIGN1c3RvbSBlbnZpcm9ubWVudHMuCiBZb3UgY2FuIGNyZWF0
ZSBhIHZhcmlldHkgb2YgY3VzdG9tIGVudmlyb25tZW50cyBmb3I6CgogLSB0ZXN0aW5nCiAt
IGRldmVsb3BtZW50CiAtIHByb2R1Y3Rpb24KIC0gZXRjLgoKIEZvciBtb3JlIGluZm9ybWF0
aW9uLCBzZWUgdGhlIFt2ZXJzaW9ucyBhbmQgZW52aXJvbm1lbnRzCiBndWlkZV0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvZG9jcy9hZ2VudHMtdmVyc2lvbnMpLgoK
CgoDBAABEgN8CA8KDAoDBAAHEgV9AoEBBAoOCgUEAAedCBIFfQKBAQQKKgoEBAAEABIGhAEC
kAEDGhogVGhlIHN0YXR1cyBvZiBhIHZlcnNpb24uCgoNCgUEAAQAARIEhAEHFAo4CgYEAAQA
AgASBIYBBCMaKCBOb3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIGlzIG5vdCB1c2VkLgoKDwoH
BAAEAAIAARIEhgEEHgoPCgcEAAQAAgACEgSGASEiCk8KBgQABAACARIEiQEEFBo/IFZlcnNp
b24gaXMgbm90IHJlYWR5IHRvIHNlcnZlIChlLmcuIHRyYWluaW5nIGlzIGluIHByb2dyZXNz
KS4KCg8KBwQABAACAQESBIkBBA8KDwoHBAAEAAIBAhIEiQESEwosCgYEAAQAAgISBIwBBA4a
HCBWZXJzaW9uIGlzIHJlYWR5IHRvIHNlcnZlLgoKDwoHBAAEAAICARIEjAEECQoPCgcEAAQA
AgICEgSMAQwNCioKBgQABAACAxIEjwEEDxoaIFZlcnNpb24gdHJhaW5pbmcgZmFpbGVkLgoK
DwoHBAAEAAIDARIEjwEECgoPCgcEAAQAAgMCEgSPAQ0OCucBCgQEAAIAEgSXAQI+GtgBIE91
dHB1dCBvbmx5LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhpcyBhZ2VudCB2ZXJzaW9u
LgogU3VwcG9ydGVkIGZvcm1hdHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQv
dmVyc2lvbnMvPFZlcnNpb24gSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0
aW9ucy88TG9jYXRpb24gSUQ+L2FnZW50L3ZlcnNpb25zLzxWZXJzaW9uCiAgIElEPmAKCg0K
BQQAAgAFEgSXAQIICg0KBQQAAgABEgSXAQkNCg0KBQQAAgADEgSXARARCg0KBQQAAgAIEgSX
ARI9ChAKCAQAAgAInAgAEgSXARM8Ck0KBAQAAgESBJoBAkIaPyBPcHRpb25hbC4gVGhlIGRl
dmVsb3Blci1wcm92aWRlZCBkZXNjcmlwdGlvbiBvZiB0aGlzIHZlcnNpb24uCgoNCgUEAAIB
BRIEmgECCAoNCgUEAAIBARIEmgEJFAoNCgUEAAIBAxIEmgEXGAoNCgUEAAIBCBIEmgEZQQoQ
CggEAAIBCJwIABIEmgEaQAqYAQoEBAACAhIEngECRxqJASBPdXRwdXQgb25seS4gVGhlIHNl
cXVlbnRpYWwgbnVtYmVyIG9mIHRoaXMgdmVyc2lvbi4gVGhpcyBmaWVsZCBpcyByZWFkLW9u
bHkKIHdoaWNoIG1lYW5zIGl0IGNhbm5vdCBiZSBzZXQgYnkgY3JlYXRlIGFuZCB1cGRhdGUg
bWV0aG9kcy4KCg0KBQQAAgIFEgSeAQIHCg0KBQQAAgIBEgSeAQgWCg0KBQQAAgIDEgSeARka
Cg0KBQQAAgIIEgSeARtGChAKCAQAAgIInAgAEgSeARxFCpEBCgQEAAIDEgaiAQKjATIagAEg
T3V0cHV0IG9ubHkuIFRoZSBjcmVhdGlvbiB0aW1lIG9mIHRoaXMgdmVyc2lvbi4gVGhpcyBm
aWVsZCBpcyByZWFkLW9ubHksCiBpLmUuLCBpdCBjYW5ub3QgYmUgc2V0IGJ5IGNyZWF0ZSBh
bmQgdXBkYXRlIG1ldGhvZHMuCgoNCgUEAAIDBhIEogECGwoNCgUEAAIDARIEogEcJwoNCgUE
AAIDAxIEogEqKwoNCgUEAAIDCBIEowEGMQoQCggEAAIDCJwIABIEowEHMAqBAQoEBAACBBIE
pwECRxpzIE91dHB1dCBvbmx5LiBUaGUgc3RhdHVzIG9mIHRoaXMgdmVyc2lvbi4gVGhpcyBm
aWVsZCBpcyByZWFkLW9ubHkgYW5kIGNhbm5vdAogYmUgc2V0IGJ5IGNyZWF0ZSBhbmQgdXBk
YXRlIG1ldGhvZHMuCgoNCgUEAAIEBhIEpwECDwoNCgUEAAIEARIEpwEQFgoNCgUEAAIEAxIE
pwEZGgoNCgUEAAIECBIEpwEbRgoQCggEAAIECJwIABIEpwEcRQp4CgIEARIGrAEAvgEBGmog
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5MaXN0VmVyc2lvbnNdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuVmVyc2lvbnMuTGlzdFZlcnNpb25zXS4KCgsK
AwQBARIErAEIGwqvAQoEBAECABIGsQECtgEEGp4BIFJlcXVpcmVkLiBUaGUgYWdlbnQgdG8g
bGlzdCBhbGwgdmVyc2lvbnMgZnJvbS4KIFN1cHBvcnRlZCBmb3JtYXRzOgogLSBgcHJvamVj
dHMvPFByb2plY3QgSUQ+L2FnZW50YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0
aW9ucy88TG9jYXRpb24gSUQ+L2FnZW50YAoKDQoFBAECAAUSBLEBAggKDQoFBAECAAESBLEB
CQ8KDQoFBAECAAMSBLEBEhMKDwoFBAECAAgSBrEBFLYBAwoQCggEAQIACJwIABIEsgEEKgoR
CgcEAQIACJ8IEgazAQS1AQUKcwoEBAECARIEugECPxplIE9wdGlvbmFsLiBUaGUgbWF4aW11
bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHBhZ2UuIEJ5CiBkZWZh
dWx0IDEwMCBhbmQgYXQgbW9zdCAxMDAwLgoKDQoFBAECAQUSBLoBAgcKDQoFBAECAQESBLoB
CBEKDQoFBAECAQMSBLoBFBUKDQoFBAECAQgSBLoBFj4KEAoIBAECAQicCAASBLoBFz0KWgoE
BAECAhIEvQECQRpMIE9wdGlvbmFsLiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVy
bmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QuCgoNCgUEAQICBRIEvQECCAoNCgUE
AQICARIEvQEJEwoNCgUEAQICAxIEvQEWFwoNCgUEAQICCBIEvQEYQAoQCggEAQICCJwIABIE
vQEZPwp5CgIEAhIGwgEAygEBGmsgVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbVmVyc2lv
bnMuTGlzdFZlcnNpb25zXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlZlcnNp
b25zLkxpc3RWZXJzaW9uc10uCgoLCgMEAgESBMIBCBwKigEKBAQCAgASBMUBAiAafCBUaGUg
bGlzdCBvZiBhZ2VudCB2ZXJzaW9ucy4gVGhlcmUgd2lsbCBiZSBhIG1heGltdW0gbnVtYmVy
IG9mIGl0ZW1zCiByZXR1cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGluIHRo
ZSByZXF1ZXN0LgoKDQoFBAICAAQSBMUBAgoKDQoFBAICAAYSBMUBCxIKDQoFBAICAAESBMUB
ExsKDQoFBAICAAMSBMUBHh8KbwoEBAICARIEyQECHRphIFRva2VuIHRvIHJldHJpZXZlIHRo
ZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3Jl
IHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAgIBBRIEyQECCAoNCgUEAgIBARIEyQEJGAoN
CgUEAgIBAxIEyQEbHAp0CgIEAxIGzgEA2gEBGmYgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtWZXJzaW9ucy5HZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LlZlcnNpb25zLkdldFZlcnNpb25dLgoKCwoDBAMBEgTOAQgZCtIBCgQEAwIAEgbUAQLZAQQa
wQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uLgogU3VwcG9ydGVkIGZvcm1h
dHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvdmVyc2lvbnMvPFZlcnNpb24g
SUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+
L2FnZW50L3ZlcnNpb25zLzxWZXJzaW9uCiAgIElEPmAKCg0KBQQDAgAFEgTUAQIICg0KBQQD
AgABEgTUAQkNCg0KBQQDAgADEgTUARARCg8KBQQDAgAIEgbUARLZAQMKEAoIBAMCAAicCAAS
BNUBBCoKEQoHBAMCAAifCBIG1gEE2AEFCnoKAgQEEgbeAQDsAQEabCBUaGUgcmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1ZlcnNpb25zLkNyZWF0ZVZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuVmVyc2lvbnMuQ3JlYXRlVmVyc2lvbl0uCgoLCgMEBAESBN4BCBwK
rQEKBAQEAgASBuMBAugBBBqcASBSZXF1aXJlZC4gVGhlIGFnZW50IHRvIGNyZWF0ZSBhIHZl
cnNpb24gZm9yLgogU3VwcG9ydGVkIGZvcm1hdHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vYWdlbnRgCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlv
biBJRD4vYWdlbnRgCgoNCgUEBAIABRIE4wECCAoNCgUEBAIAARIE4wEJDwoNCgUEBAIAAxIE
4wESEwoPCgUEBAIACBIG4wEU6AEDChAKCAQEAgAInAgAEgTkAQQqChEKBwQEAgAInwgSBuUB
BOcBBQowCgQEBAIBEgTrAQI/GiIgUmVxdWlyZWQuIFRoZSB2ZXJzaW9uIHRvIGNyZWF0ZS4K
Cg0KBQQEAgEGEgTrAQIJCg0KBQQEAgEBEgTrAQoRCg0KBQQEAgEDEgTrARQVCg0KBQQEAgEI
EgTrARY+ChAKCAQEAgEInAgAEgTrARc9CnoKAgQFEgbwAQD7AQEabCBUaGUgcmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1ZlcnNpb25zLlVwZGF0ZVZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuVmVyc2lvbnMuVXBkYXRlVmVyc2lvbl0uCgoLCgMEBQESBPABCBwK
zgEKBAQFAgASBPYBAj8avwEgUmVxdWlyZWQuIFRoZSB2ZXJzaW9uIHRvIHVwZGF0ZS4KIFN1
cHBvcnRlZCBmb3JtYXRzOgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3ZlcnNp
b25zLzxWZXJzaW9uIElEPmAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMv
PExvY2F0aW9uIElEPi9hZ2VudC92ZXJzaW9ucy88VmVyc2lvbgogICBJRD5gCgoNCgUEBQIA
BhIE9gECCQoNCgUEBQIAARIE9gEKEQoNCgUEBQIAAxIE9gEUFQoNCgUEBQIACBIE9gEWPgoQ
CggEBQIACJwIABIE9gEXPQpJCgQEBQIBEgb5AQL6AS8aOSBSZXF1aXJlZC4gVGhlIG1hc2sg
dG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBQIBBhIE+QECGwoN
CgUEBQIBARIE+QEcJwoNCgUEBQIBAxIE+QEqKwoNCgUEBQIBCBIE+gEGLgoQCggEBQIBCJwI
ABIE+gEHLQp6CgIEBhIG/wEAiwIBGmwgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWZXJz
aW9ucy5EZWxldGVWZXJzaW9uXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlZl
cnNpb25zLkRlbGV0ZVZlcnNpb25dLgoKCwoDBAYBEgT/AQgcCtwBCgQEBgIAEgaFAgKKAgQa
ywEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uIHRvIGRlbGV0ZS4KIFN1cHBv
cnRlZCBmb3JtYXRzOgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3ZlcnNpb25z
LzxWZXJzaW9uIElEPmAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExv
Y2F0aW9uIElEPi9hZ2VudC92ZXJzaW9ucy88VmVyc2lvbgogICBJRD5gCgoNCgUEBgIABRIE
hQICCAoNCgUEBgIAARIEhQIJDQoNCgUEBgIAAxIEhQIQEQoPCgUEBgIACBIGhQISigIDChAK
CAQGAgAInAgAEgSGAgQqChEKBwQGAgAInwgSBocCBIkCBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: version_number Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status Type: 14 (.google.cloud.dialogflow.v2beta1.Version.VersionStatus)

# Enum: Version::VersionStatus
our $Version_VERSION_STATUS_UNSPECIFIED = 0;
our $Version_IN_PROGRESS = 1;
our $Version_READY = 2;
our $Version_FAILED = 3;

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.cloud.dialogflow.v2beta1.Version)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::GetVersionRequest ===
    # Fields for GetVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::CreateVersionRequest ===
    # Fields for CreateVersionRequest
    # Field: parent Type: 9 ()
    # Field: version Type: 11 (.google.cloud.dialogflow.v2beta1.Version)

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::UpdateVersionRequest ===
    # Fields for UpdateVersionRequest
    # Field: version Type: 11 (.google.cloud.dialogflow.v2beta1.Version)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2beta1::Version::DeleteVersionRequest ===
    # Fields for DeleteVersionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2beta1::Version::VersionsClient ===
package Google::Cloud::Dialogflow::V2beta1::Version::VersionsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::Version::VersionsClient

Client stub representing the remote C<Versions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub list_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'ListVersions',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse',
    });
}

sub get_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Version::GetVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'GetVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Version::Version',
    });
}

sub create_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Version::CreateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'CreateVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Version::Version',
    });
}

sub update_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Version::UpdateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'UpdateVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Version::Version',
    });
}

sub delete_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Version::DeleteVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'DeleteVersion',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Version - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/version.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Version;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Version::Version->new({
        name => $name,
        description => $description,
        version_number => $version_number,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Version::Version->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Version::Version

You can create multiple versions of your agent and publish them to separate
environments.

When you edit an agent, you are editing the draft agent. At any point, you
can save the draft agent as an agent version, which is an immutable snapshot
of your agent.

When you save the draft agent, it is published to the default environment.
When you create agent versions, you can publish them to custom environments.
You can create a variety of custom environments for:

- testing
- development
- production
- etc.

For more information, see the [versions and environments
guide](https://cloud.google.com/dialogflow/docs/agents-versions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique identifier of this agent version.
Supported formats:
- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The developer-provided description of this version.

=item * C<< $msg->version_number() >> / C<< $msg->version_number($value) >>

Type: C<Int32>

Output only. The sequential number of this version. This field is read-only
which means it cannot be set by create and update methods.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time of this version. This field is read-only,
i.e., it cannot be set by create and update methods.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::Version::VersionStatus>)

Output only. The status of this version. This field is read-only and cannot
be set by create and update methods.

=back

=head3 Enum: Version::VersionStatus

=over 4

=item * C<VERSION_STATUS_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<READY> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsRequest

The request message for
[Versions.ListVersions][google.cloud.dialogflow.v2beta1.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all versions from.
Supported formats:
- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse

The response message for
[Versions.ListVersions][google.cloud.dialogflow.v2beta1.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Version::Version>)

The list of agent versions. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Version::GetVersionRequest

The request message for
[Versions.GetVersion][google.cloud.dialogflow.v2beta1.Versions.GetVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the version.
Supported formats:
- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Version::CreateVersionRequest

The request message for
[Versions.CreateVersion][google.cloud.dialogflow.v2beta1.Versions.CreateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to create a version for.
Supported formats:
- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Version::Version>)

Required. The version to create.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Version::UpdateVersionRequest

The request message for
[Versions.UpdateVersion][google.cloud.dialogflow.v2beta1.Versions.UpdateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Version::Version>)

Required. The version to update.
Supported formats:
- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Version::DeleteVersionRequest

The request message for
[Versions.DeleteVersion][google.cloud.dialogflow.v2beta1.Versions.DeleteVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the version to delete.
Supported formats:
- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
