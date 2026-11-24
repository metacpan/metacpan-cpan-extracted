package Google::Cloud::Retail::V2beta::GenerativeQuestionService;

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
    eval { require Google::Cloud::Retail::V2beta::GenerativeQuestion };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9nZW5lcmF0aXZlX3F1ZXN0aW9uX3NlcnZp
Y2UucHJvdG8SGmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0Z29vZ2xlL2Ns
b3VkL3JldGFpbC92MmJldGEvZ2VuZXJhdGl2ZV9xdWVzdGlvbi5wcm90bxogZ29vZ2xlL3By
b3RvYnVmL2ZpZWxkX21hc2sucHJvdG8ihAIKLVVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbnNG
ZWF0dXJlQ29uZmlnUmVxdWVzdBKQAQojZ2VuZXJhdGl2ZV9xdWVzdGlvbnNfZmVhdHVyZV9j
b25maWcYAiABKAsyPC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5HZW5lcmF0aXZlUXVl
c3Rpb25zRmVhdHVyZUNvbmZpZ0ID4EECUiBnZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNv
bmZpZxJACgt1cGRhdGVfbWFzaxgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tC
A+BBAVIKdXBkYXRlTWFzayJtCipHZXRHZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZp
Z1JlcXVlc3QSPwoHY2F0YWxvZxgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5j
b20vQ2F0YWxvZ1IHY2F0YWxvZyJlCiRMaXN0R2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnc1Jl
cXVlc3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9D
YXRhbG9nUgZwYXJlbnQinQEKJUxpc3RHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzUmVzcG9u
c2USdAobZ2VuZXJhdGl2ZV9xdWVzdGlvbl9jb25maWdzGAEgAygLMjQuZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmJldGEuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnUhlnZW5lcmF0aXZlUXVl
c3Rpb25Db25maWdzIuIBCiVVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWdSZXF1ZXN0
EncKGmdlbmVyYXRpdmVfcXVlc3Rpb25fY29uZmlnGAMgASgLMjQuZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnQgPgQQJSGGdlbmVyYXRpdmVR
dWVzdGlvbkNvbmZpZxJACgt1cGRhdGVfbWFzaxgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayLQAQorQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVl
c3Rpb25Db25maWdzUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAfpBHwodcmV0YWlsLmdv
b2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJiCghyZXF1ZXN0cxgCIAMoCzJBLmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ1Jl
cXVlc3RCA+BBAlIIcmVxdWVzdHMiqQEKLEJhdGNoVXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9u
Q29uZmlnc1Jlc3BvbnNlEnkKG2dlbmVyYXRpdmVfcXVlc3Rpb25fY29uZmlncxgBIAMoCzI0
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ0ID
4EEBUhlnZW5lcmF0aXZlUXVlc3Rpb25Db25maWdzMvYMChlHZW5lcmF0aXZlUXVlc3Rpb25T
ZXJ2aWNlEoUDCiZVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZxJJLmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0
dXJlQ29uZmlnUmVxdWVzdBo8Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkdlbmVyYXRp
dmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnItEBgtPkkwKYATJxL3YyYmV0YS97Z2VuZXJhdGl2
ZV9xdWVzdGlvbnNfZmVhdHVyZV9jb25maWcuY2F0YWxvZz1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NhdGFsb2dzLyp9L2dlbmVyYXRpdmVRdWVzdGlvbkZlYXR1cmU6I2dlbmVyYXRpdmVf
cXVlc3Rpb25zX2ZlYXR1cmVfY29uZmln2kEvZ2VuZXJhdGl2ZV9xdWVzdGlvbnNfZmVhdHVy
ZV9jb25maWcsdXBkYXRlX21hc2sSjAIKI0dldEdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJl
Q29uZmlnEkYuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuR2V0R2VuZXJhdGl2ZVF1ZXN0
aW9uc0ZlYXR1cmVDb25maWdSZXF1ZXN0GjwuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEu
R2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWciX4LT5JMCTxJNL3YyYmV0YS97Y2F0
YWxvZz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L2dlbmVyYXRpdmVRdWVz
dGlvbkZlYXR1cmXaQQdjYXRhbG9nEv0BCh1MaXN0R2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmln
cxJALmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkxpc3RHZW5lcmF0aXZlUXVlc3Rpb25D
b25maWdzUmVxdWVzdBpBLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkxpc3RHZW5lcmF0
aXZlUXVlc3Rpb25Db25maWdzUmVzcG9uc2UiV4LT5JMCSBJGL3YyYmV0YS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0vZ2VuZXJhdGl2ZVF1ZXN0aW9uc9pB
BnBhcmVudBLKAgoeVXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnEkEuZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmJldGEuVXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnUmVxdWVz
dBo0Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkdlbmVyYXRpdmVRdWVzdGlvbkNvbmZp
ZyKuAYLT5JMCfzJhL3YyYmV0YS97Z2VuZXJhdGl2ZV9xdWVzdGlvbl9jb25maWcuY2F0YWxv
Zz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L2dlbmVyYXRpdmVRdWVzdGlv
bjoaZ2VuZXJhdGl2ZV9xdWVzdGlvbl9jb25maWfaQSZnZW5lcmF0aXZlX3F1ZXN0aW9uX2Nv
bmZpZyx1cGRhdGVfbWFzaxKpAgokQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25m
aWdzEkcuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQmF0Y2hVcGRhdGVHZW5lcmF0aXZl
UXVlc3Rpb25Db25maWdzUmVxdWVzdBpILmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkJh
dGNoVXBkYXRlR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnc1Jlc3BvbnNlIm6C0+STAlYiUS92
MmJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L2dlbmVy
YXRpdmVRdWVzdGlvbjpiYXRjaFVwZGF0ZToBKtpBD3BhcmVudCxyZXF1ZXN0cxpJykEVcmV0
YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybULdAQoeY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhQh5HZW5l
cmF0aXZlUXVlc3Rpb25TZXJ2aWNlUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRh
aWwvYXBpdjJiZXRhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xlLkNsb3Vk
LlJldGFpbC5WMkJldGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdvb2dsZTo6
Q2xvdWQ6OlJldGFpbDo6VjJiZXRhSt4jCgcSBQ4AqwEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPgoJCgIDBRIDFwAqCggKAQgSAxkANwoJCgIIJRID
GQA3CggKAQgSAxoATQoJCgIICxIDGgBNCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwA
PwoJCgIICBIDHAA/CggKAQgSAx0ANwoJCgIIARIDHQA3CggKAQgSAx4AJAoJCgIIJBIDHgAk
CggKAQgSAx8ANwoJCgIIKRIDHwA3CggKAQgSAyAANgoJCgIILRIDIAA2Ck0KAgYAEgQjAF4B
GkEgU2VydmljZSBmb3IgbWFuYWdpbmcgTExNIGdlbmVyYXRlZCBxdWVzdGlvbnMgaW4gc2Vh
cmNoIHNlcnZpbmcuCgoKCgMGAAESAyMIIQoKCgMGAAMSAyQCPQoMCgUGAAOZCBIDJAI9CgsK
AwYAAxIEJQImNwoNCgUGAAOaCBIEJQImNwppCgQGAAIAEgQqAjMDGlsgTWFuYWdlcyBvdmVy
YWwgZ2VuZXJhdGl2ZSBxdWVzdGlvbiBmZWF0dXJlIHN0YXRlIC0tIGVuYWJsZXMgdG9nZ2xp
bmcKIGZlYXR1cmUgb24gYW5kIG9mZi4KCgwKBQYAAgABEgMqBiwKDAoFBgACAAISAysGMwoM
CgUGAAIAAxIDLA8vCg0KBQYAAgAEEgQtBDAGChEKCQYAAgAEsMq8IhIELQQwBgoNCgUGAAIA
BBIEMQQyOgoQCggGAAIABJsIABIEMQQyOgppCgQGAAIBEgQ3Aj4DGlsgTWFuYWdlcyBvdmVy
YWwgZ2VuZXJhdGl2ZSBxdWVzdGlvbiBmZWF0dXJlIHN0YXRlIC0tIGVuYWJsZXMgdG9nZ2xp
bmcKIGZlYXR1cmUgb24gYW5kIG9mZi4KCgwKBQYAAgEBEgM3BikKDAoFBgACAQISAzgGMAoM
CgUGAAIBAxIDOQ8vCg0KBQYAAgEEEgQ6BDwGChEKCQYAAgEEsMq8IhIEOgQ8BgoMCgUGAAIB
BBIDPQQ1Cg8KCAYAAgEEmwgAEgM9BDUKOgoEBgACAhIEQQJHAxosIFJldHVybnMgYWxsIHF1
ZXN0aW9ucyBmb3IgYSBnaXZlbiBjYXRhbG9nLgoKDAoFBgACAgESA0EGIwoMCgUGAAICAhID
QSRICgwKBQYAAgIDEgNCDzQKDQoFBgACAgQSBEMERQYKEQoJBgACAgSwyrwiEgRDBEUGCgwK
BQYAAgIEEgNGBDQKDwoIBgACAgSbCAASA0YENAo6CgQGAAIDEgRKAlIDGiwgQWxsb3dzIG1h
bmFnZW1lbnQgb2YgaW5kaXZpZHVhbCBxdWVzdGlvbnMuCgoMCgUGAAIDARIDSgYkCgwKBQYA
AgMCEgNKJUoKDAoFBgACAwMSA0sPJwoNCgUGAAIDBBIETARPBgoRCgkGAAIDBLDKvCISBEwE
TwYKDQoFBgACAwQSBFAEUTEKEAoIBgACAwSbCAASBFAEUTEKOAoEBgACBBIEVQJdAxoqIEFs
bG93cyBtYW5hZ2VtZW50IG9mIG11bHRpcGxlIHF1ZXN0aW9ucy4KCgwKBQYAAgQBEgNVBioK
DAoFBgACBAISA1YGMQoMCgUGAAIEAxIDVw87Cg0KBQYAAgQEEgRYBFsGChEKCQYAAgQEsMq8
IhIEWARbBgoMCgUGAAIEBBIDXAQ9Cg8KCAYAAgQEmwgAEgNcBD0KSAoCBAASBGEAawEaPCBS
ZXF1ZXN0IGZvciBVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZyBtZXRo
b2QuCgoKCgMEAAESA2EINQpHCgQEAAIAEgRjAmQvGjkgUmVxdWlyZWQuIFRoZSBjb25maWd1
cmF0aW9uIG1hbmFnaW5nIHRoZSBmZWF0dXJlIHN0YXRlLgoKDAoFBAACAAYSA2MCIgoMCgUE
AAIAARIDYyNGCgwKBQQAAgADEgNjSUoKDAoFBAACAAgSA2QGLgoPCggEAAIACJwIABIDZAct
CuUBCgQEAAIBEgRpAmovGtYBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGlu
IHRoZSBwcm92aWRlZAogW0dlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YS5HZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZp
Z10KIHRvIHVwZGF0ZS4gSWYgbm90IHNldCBvciBlbXB0eSwgYWxsIHN1cHBvcnRlZCBmaWVs
ZHMgYXJlIHVwZGF0ZWQuCgoMCgUEAAIBBhIDaQIbCgwKBQQAAgEBEgNpHCcKDAoFBAACAQMS
A2kqKwoMCgUEAAIBCBIDagYuCg8KCAQAAgEInAgAEgNqBy0KRQoCBAESBG4AdQEaOSBSZXF1
ZXN0IGZvciBHZXRHZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZyBtZXRob2QuCgoK
CgMEAQESA24IMgqCAQoEBAECABIEcQJ0BBp0IFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9m
IHRoZSBwYXJlbnQgY2F0YWxvZy4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfQoKDAoFBAECAAUSA3ECCAoMCgUE
AQIAARIDcQkQCgwKBQQBAgADEgNxExQKDQoFBAECAAgSBHEVdAMKDwoIBAECAAicCAASA3IE
KgoOCgcEAQIACJ8IEgNzBE8KLwoCBAISBHgAfwEaIyBSZXF1ZXN0IGZvciBMaXN0UXVlc3Rp
b25zIG1ldGhvZC4KCgoKAwQCARIDeAgsCoIBCgQEAgIAEgR7An4EGnQgUmVxdWlyZWQuIFJl
c291cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBjYXRhbG9nLgogRm9ybWF0OiBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2F0YWxvZ3Mve2NhdGFsb2d9CgoMCgUE
AgIABRIDewIICgwKBQQCAgABEgN7CQ8KDAoFBAICAAMSA3sSEwoNCgUEAgIACBIEexR+AwoP
CggEAgIACJwIABIDfAQqCg4KBwQCAgAInwgSA30ETwoyCgIEAxIGggEAhQEBGiQgUmVzcG9u
c2UgZm9yIExpc3RRdWVzdGlvbnMgbWV0aG9kLgoKCwoDBAMBEgSCAQgtCjYKBAQDAgASBIQB
AkQaKCBBbGwgdGhlIHF1ZXN0aW9ucyBmb3IgYSBnaXZlbiBjYXRhbG9nLgoKDQoFBAMCAAQS
BIQBAgoKDQoFBAMCAAYSBIQBCyMKDQoFBAMCAAESBIQBJD8KDQoFBAMCAAMSBIQBQkMKQgoC
BAQSBogBAJYBARo0IFJlcXVlc3QgZm9yIFVwZGF0ZUdlbmVyYXRpdmVRdWVzdGlvbkNvbmZp
ZyBtZXRob2QuCgoLCgMEBAESBIgBCC0KMwoEBAQCABIGigECiwEvGiMgUmVxdWlyZWQuIFRo
ZSBxdWVzdGlvbiB0byB1cGRhdGUuCgoNCgUEBAIABhIEigECGgoNCgUEBAIAARIEigEbNQoN
CgUEBAIAAxIEigE4OQoNCgUEBAIACBIEiwEGLgoQCggEBAIACJwIABIEiwEHLQriAgoEBAQC
ARIGlAEClQEvGtECIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBw
cm92aWRlZAogW0dlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmJldGEuR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnXQogdG8gdXBkYXRlLiBUaGUgZm9s
bG93aW5nIGFyZSBOT1Qgc3VwcG9ydGVkOgoKICogW0dlbmVyYXRpdmVRdWVzdGlvbkNvbmZp
Zy5mcmVxdWVuY3ldW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkdlbmVyYXRpdmVRdWVz
dGlvbkNvbmZpZy5mcmVxdWVuY3ldCgogSWYgbm90IHNldCBvciBlbXB0eSwgYWxsIHN1cHBv
cnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoNCgUEBAIBBhIElAECGwoNCgUEBAIBARIElAEc
JwoNCgUEBAIBAxIElAEqKwoNCgUEBAIBCBIElQEGLgoQCggEBAIBCJwIABIElQEHLQpHCgIE
BRIGmQEApAEBGjkgUmVxdWVzdCBmb3IgQmF0Y2hVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25D
b25maWcgbWV0aG9kLgoKCwoDBAUBEgSZAQgzCoQBCgQEBQIAEgacAQKfAQQadCBPcHRpb25h
bC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgcGFyZW50IGNhdGFsb2cuCiBGb3JtYXQ6IHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jYXRhbG9ncy97Y2F0YWxvZ30K
Cg0KBQQFAgAFEgScAQIICg0KBQQFAgABEgScAQkPCg0KBQQFAgADEgScARITCg8KBQQFAgAI
EgacARSfAQMKEAoIBAUCAAicCAASBJ0BBCoKDwoHBAUCAAifCBIEngEETwo5CgQEBQIBEgai
AQKjAS8aKSBSZXF1aXJlZC4gVGhlIHVwZGF0ZXMgcXVlc3Rpb24gY29uZmlncy4KCg0KBQQF
AgEEEgSiAQIKCg0KBQQFAgEGEgSiAQswCg0KBQQFAgEBEgSiATE5Cg0KBQQFAgEDEgSiATw9
Cg0KBQQFAgEIEgSjAQYuChAKCAQFAgEInAgAEgSjAQctCk4KAgQGEganAQCrAQEaQCBBZ2dy
ZWdhdGVkIHJlc3BvbnNlIGZvciBVcGRhdGVHZW5lcmF0aXZlUXVlc3Rpb25Db25maWcgbWV0
aG9kLgoKCwoDBAYBEgSnAQg0CjkKBAQGAgASBqkBAqoBLxopIE9wdGlvbmFsLiBUaGUgdXBk
YXRlcyBxdWVzdGlvbiBjb25maWdzLgoKDQoFBAYCAAQSBKkBAgoKDQoFBAYCAAYSBKkBCyMK
DQoFBAYCAAESBKkBJD8KDQoFBAYCAAMSBKkBQkMKDQoFBAYCAAgSBKoBBi4KEAoIBAYCAAic
CAASBKoBBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest ===
    # Fields for UpdateGenerativeQuestionsFeatureConfigRequest
    # Field: generative_questions_feature_config Type: 11 (.google.cloud.retail.v2beta.GenerativeQuestionsFeatureConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest ===
    # Fields for GetGenerativeQuestionsFeatureConfigRequest
    # Field: catalog Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest ===
    # Fields for ListGenerativeQuestionConfigsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse ===
    # Fields for ListGenerativeQuestionConfigsResponse
    # Field: generative_question_configs Type: 11 (.google.cloud.retail.v2beta.GenerativeQuestionConfig)

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest ===
    # Fields for UpdateGenerativeQuestionConfigRequest
    # Field: generative_question_config Type: 11 (.google.cloud.retail.v2beta.GenerativeQuestionConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest ===
    # Fields for BatchUpdateGenerativeQuestionConfigsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.retail.v2beta.UpdateGenerativeQuestionConfigRequest)

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse ===
    # Fields for BatchUpdateGenerativeQuestionConfigsResponse
    # Field: generative_question_configs Type: 11 (.google.cloud.retail.v2beta.GenerativeQuestionConfig)

# === Service Client: Google::Cloud::Retail::V2beta::GenerativeQuestionService::GenerativeQuestionServiceClient ===
package Google::Cloud::Retail::V2beta::GenerativeQuestionService::GenerativeQuestionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::GenerativeQuestionService::GenerativeQuestionServiceClient

Client stub representing the remote C<GenerativeQuestionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub update_generative_questions_feature_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionsFeatureConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig',
    });
}

sub get_generative_questions_feature_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.GenerativeQuestionService',
        method         => 'GetGenerativeQuestionsFeatureConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig',
    });
}

sub list_generative_question_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.GenerativeQuestionService',
        method         => 'ListGenerativeQuestionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse',
    });
}

sub update_generative_question_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionConfig',
    });
}

sub batch_update_generative_question_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.GenerativeQuestionService',
        method         => 'BatchUpdateGenerativeQuestionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::GenerativeQuestionService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/generative_question_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::GenerativeQuestionService;

    my $msg = Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->new({
        generative_questions_feature_config => $generative_questions_feature_config,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->generative_questions_feature_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/generative_question_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest

Request for UpdateGenerativeQuestionsFeatureConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_questions_feature_config() >> / C<< $msg->generative_questions_feature_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig>)

Required. The configuration managing the feature state.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[GenerativeQuestionsFeatureConfig][google.cloud.retail.v2beta.GenerativeQuestionsFeatureConfig]
to update. If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest

Request for GetGenerativeQuestionsFeatureConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest

Request for ListQuestions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse

Response for ListQuestions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_configs() >> / C<< $msg->generative_question_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionConfig>)

All the questions for a given catalog.

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest

Request for UpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_config() >> / C<< $msg->generative_question_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionConfig>)

Required. The question to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[GenerativeQuestionConfig][google.cloud.retail.v2beta.GenerativeQuestionConfig]
to update. The following are NOT supported:

* [GenerativeQuestionConfig.frequency][google.cloud.retail.v2beta.GenerativeQuestionConfig.frequency]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest

Request for BatchUpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Optional. Resource name of the parent catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest>)

Required. The updates question configs.

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse

Aggregated response for UpdateGenerativeQuestionConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generative_question_configs() >> / C<< $msg->generative_question_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionConfig>)

Optional. The updates question configs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::GenerativeQuestionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
