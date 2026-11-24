package Google::Cloud::Ces::V1beta::Omnichannel;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9vbW5pY2hhbm5lbC5wcm90bxIXZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
ggQKC09tbmljaGFubmVsEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25h
bWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSFwoEZXRhZxgGIAEoCUID4EED
UgRldGFnEmkKEmludGVncmF0aW9uX2NvbmZpZxgHIAEoCzI1Lmdvb2dsZS5jbG91ZC5jZXMu
djFiZXRhLk9tbmljaGFubmVsSW50ZWdyYXRpb25Db25maWdCA+BBAVIRaW50ZWdyYXRpb25D
b25maWc6ggHqQX8KHmNlcy5nb29nbGVhcGlzLmNvbS9PbW5pY2hhbm5lbBJCcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L29tbmljaGFubmVscy97b21uaWNoYW5u
ZWx9KgxvbW5pY2hhbm5lbHMyC29tbmljaGFubmVsIpwMChxPbW5pY2hhbm5lbEludGVncmF0
aW9uQ29uZmlnEncKD2NoYW5uZWxfY29uZmlncxgBIAMoCzJJLmdvb2dsZS5jbG91ZC5jZXMu
djFiZXRhLk9tbmljaGFubmVsSW50ZWdyYXRpb25Db25maWcuQ2hhbm5lbENvbmZpZ3NFbnRy
eUID4EEBUg5jaGFubmVsQ29uZmlncxKAAQoSc3Vic2NyaWJlcl9jb25maWdzGAIgAygLMkwu
Z29vZ2xlLmNsb3VkLmNlcy52MWJldGEuT21uaWNoYW5uZWxJbnRlZ3JhdGlvbkNvbmZpZy5T
dWJzY3JpYmVyQ29uZmlnc0VudHJ5QgPgQQFSEXN1YnNjcmliZXJDb25maWdzEncKD3JvdXRp
bmdfY29uZmlncxgDIAMoCzJJLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLk9tbmljaGFubmVs
SW50ZWdyYXRpb25Db25maWcuUm91dGluZ0NvbmZpZ3NFbnRyeUID4EEBUg5yb3V0aW5nQ29u
ZmlncxqSAQoNQ2hhbm5lbENvbmZpZxJvCg93aGF0c2FwcF9jb25maWcYASABKAsyRC5nb29n
bGUuY2xvdWQuY2VzLnYxYmV0YS5PbW5pY2hhbm5lbEludGVncmF0aW9uQ29uZmlnLldoYXRz
YXBwQ29uZmlnSABSDndoYXRzYXBwQ29uZmlnQhAKDmNoYW5uZWxfY29uZmlnGsMCCg5XaGF0
c2FwcENvbmZpZxImCg9waG9uZV9udW1iZXJfaWQYASABKAlSDXBob25lTnVtYmVySWQSIQoM
cGhvbmVfbnVtYmVyGAIgASgJUgtwaG9uZU51bWJlchI/Chx3aGF0c2FwcF9idXNpbmVzc19h
Y2NvdW50X2lkGAMgASgJUhl3aGF0c2FwcEJ1c2luZXNzQWNjb3VudElkEjAKFHdlYmhvb2tf
dmVyaWZ5X3Rva2VuGAQgASgJUhJ3ZWJob29rVmVyaWZ5VG9rZW4SNgoXd2hhdHNhcHBfYnVz
aW5lc3NfdG9rZW4YBSABKAlSFXdoYXRzYXBwQnVzaW5lc3NUb2tlbhI7ChptZXRhX2J1c2lu
ZXNzX3BvcnRmb2xpb19pZBgGIAEoCVIXbWV0YUJ1c2luZXNzUG9ydGZvbGlvSWQakwEKEFN1
YnNjcmliZXJDb25maWcSagoOY2VzX2FwcF9jb25maWcYASABKAsyQi5nb29nbGUuY2xvdWQu
Y2VzLnYxYmV0YS5PbW5pY2hhbm5lbEludGVncmF0aW9uQ29uZmlnLkNlc0FwcENvbmZpZ0gA
UgxjZXNBcHBDb25maWdCEwoRc3Vic2NyaWJlcl9jb25maWcaPQoMQ2VzQXBwQ29uZmlnEi0K
A2FwcBgBIAEoCUIb+kEYChZjZXMuZ29vZ2xlYXBpcy5jb20vQXBwUgNhcHAaNgoNUm91dGlu
Z0NvbmZpZxIlCg5zdWJzY3JpYmVyX2tleRgBIAEoCVINc3Vic2NyaWJlcktleRqGAQoTQ2hh
bm5lbENvbmZpZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRJZCgV2YWx1ZRgCIAEoCzJDLmdv
b2dsZS5jbG91ZC5jZXMudjFiZXRhLk9tbmljaGFubmVsSW50ZWdyYXRpb25Db25maWcuQ2hh
bm5lbENvbmZpZ1IFdmFsdWU6AjgBGowBChZTdWJzY3JpYmVyQ29uZmlnc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5ElwKBXZhbHVlGAIgASgLMkYuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEu
T21uaWNoYW5uZWxJbnRlZ3JhdGlvbkNvbmZpZy5TdWJzY3JpYmVyQ29uZmlnUgV2YWx1ZToC
OAEahgEKE1JvdXRpbmdDb25maWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSWQoFdmFsdWUY
AiABKAsyQy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5PbW5pY2hhbm5lbEludGVncmF0aW9u
Q29uZmlnLlJvdXRpbmdDb25maWdSBXZhbHVlOgI4AUJgChtjb20uZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGFCEE9tbmljaGFubmVsUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMv
YXBpdjFiZXRhL2Nlc3BiO2Nlc3BiSqQjCgcSBQ4AhgEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhID
FAApCggKAQgSAxYARAoJCgIICxIDFgBECggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgA
MQoJCgIICBIDGAAxCggKAQgSAxkANAoJCgIIARIDGQA0CjEKAgQAEgQcAD4BGiUgUmVwcmVz
ZW50cyBhbiBPbW5pY2hhbm5lbCByZXNvdXJjZS4KCgoKAwQAARIDHAgTCgsKAwQABxIEHQIi
BAoNCgUEAAedCBIEHQIiBAqdAQoEBAACABIDJwI9Go8BIElkZW50aWZpZXIuIFRoZSB1bmlx
dWUgaWRlbnRpZmllciBvZiB0aGUgb21uaWNoYW5uZWwgcmVzb3VyY2UuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L29tbmljaGFubmVscy97
b21uaWNoYW5uZWx9YAoKDAoFBAACAAUSAycCCAoMCgUEAAIAARIDJwkNCgwKBQQAAgADEgMn
EBEKDAoFBAACAAgSAycSPAoPCggEAAIACJwIABIDJxM7CkIKBAQAAgESAyoCQxo1IFJlcXVp
cmVkLiBEaXNwbGF5IG5hbWUgb2YgdGhlIG9tbmljaGFubmVsIHJlc291cmNlLgoKDAoFBAAC
AQUSAyoCCAoMCgUEAAIBARIDKgkVCgwKBQQAAgEDEgMqGBkKDAoFBAACAQgSAyoaQgoPCggE
AAIBCJwIABIDKhtBClAKBAQAAgISAy0CQhpDIE9wdGlvbmFsLiBIdW1hbi1yZWFkYWJsZSBk
ZXNjcmlwdGlvbiBvZiB0aGUgb21uaWNoYW5uZWwgcmVzb3VyY2UuCgoMCgUEAAICBRIDLQII
CgwKBQQAAgIBEgMtCRQKDAoFBAACAgMSAy0XGAoMCgUEAAICCBIDLRlBCg8KCAQAAgIInAgA
EgMtGkAKUQoEBAACAxIEMAIxMhpDIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUg
b21uaWNoYW5uZWwgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQuCgoMCgUEAAIDBhIDMAIbCgwKBQQA
AgMBEgMwHCcKDAoFBAACAwMSAzAqKwoMCgUEAAIDCBIDMQYxCg8KCAQAAgMInAgAEgMxBzAK
VgoEBAACBBIENAI1MhpIIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUgb21uaWNo
YW5uZWwgcmVzb3VyY2Ugd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgQGEgM0AhsKDAoFBAAC
BAESAzQcJwoMCgUEAAIEAxIDNCorCgwKBQQAAgQIEgM1BjEKDwoIBAACBAicCAASAzUHMApw
CgQEAAIFEgM5Aj4aYyBPdXRwdXQgb25seS4gRXRhZyB1c2VkIHRvIGVuc3VyZSB0aGUgb2Jq
ZWN0IGhhc24ndCBjaGFuZ2VkIGR1cmluZyBhCiByZWFkLW1vZGlmeS13cml0ZSBvcGVyYXRp
b24uCgoMCgUEAAIFBRIDOQIICgwKBQQAAgUBEgM5CQ0KDAoFBAACBQMSAzkQEQoMCgUEAAIF
CBIDORI9Cg8KCAQAAgUInAgAEgM5EzwKTgoEBAACBhIEPAI9LxpAIE9wdGlvbmFsLiBUaGUg
aW50ZWdyYXRpb24gY29uZmlnIGZvciB0aGUgb21uaWNoYW5uZWwgcmVzb3VyY2UuCgoMCgUE
AAIGBhIDPAIeCgwKBQQAAgYBEgM8HzEKDAoFBAACBgMSAzw0NQoMCgUEAAIGCBIDPQYuCg8K
CAQAAgYInAgAEgM9By0KUQoCBAESBUEAhgEBGkQgT21uaWNoYW5uZWxJbnRlZ3JhdGlvbkNv
bmZpZyBjb250YWlucyBhbGwgQXBwIGludGVncmF0aW9uIGNvbmZpZ3MuCgoKCgMEAQESA0EI
JApNCgQEAQMAEgRDAkkDGj8gQ2hhbm5lbENvbmZpZyBjb250YWlucyBjb25maWcgZm9yIHZh
cmlvdXMgb2YgYXBwIGludGVncmF0aW9uLgoKDAoFBAEDAAESA0MKFwopCgYEAQMACAASBEUE
SAUaGSBUaGUgY29uZmlnIGZvciB0aGUgYXBwLgoKDgoHBAEDAAgAARIDRQoYCiEKBgQBAwAC
ABIDRwYpGhIgV2hhdHNBcHAgY29uZmlnLgoKDgoHBAEDAAIABhIDRwYUCg4KBwQBAwACAAES
A0cVJAoOCgcEAQMAAgADEgNHJygKSgoEBAEDARIETAJhAxo8IEhvdyBPbW5pY2hhbm5lbCBz
aG91bGQgcmVjZWl2ZS9yZXBseSBldmVudHMgZnJvbSBXaGF0c0FwcC4KCgwKBQQBAwEBEgNM
ChgKUwoGBAEDAQIAEgNOBB8aRCBUaGUgUGhvbmUgTnVtYmVyIElEIGFzc29jaWF0ZWQgd2l0
aCB0aGUgV2hhdHNBcHAgQnVzaW5lc3MgQWNjb3VudC4KCg4KBwQBAwECAAUSA04ECgoOCgcE
AQMBAgABEgNOCxoKDgoHBAEDAQIAAxIDTh0eCkYKBgQBAwECARIDUQQcGjcgVGhlIHBob25l
IG51bWJlciB1c2VkIGZvciBzZW5kaW5nL3JlY2VpdmluZyBtZXNzYWdlcy4KCg4KBwQBAwEC
AQUSA1EECgoOCgcEAQMBAgEBEgNRCxcKDgoHBAEDAQIBAxIDURobCkQKBgQBAwECAhIDVAQs
GjUgVGhlIGN1c3RvbWVyJ3MgV2hhdHNBcHAgQnVzaW5lc3MgQWNjb3VudCAoV0FCQSkgSUQu
CgoOCgcEAQMBAgIFEgNUBAoKDgoHBAEDAQICARIDVAsnCg4KBwQBAwECAgMSA1QqKwphCgYE
AQMBAgMSA1gEJBpSIFRoZSB2ZXJpZnkgdG9rZW4gY29uZmlndXJlZCBpbiB0aGUgTWV0YSBB
cHAgRGFzaGJvYXJkIGZvciB3ZWJob29rCiB2ZXJpZmljYXRpb24uCgoOCgcEAQMBAgMFEgNY
BAoKDgoHBAEDAQIDARIDWAsfCg4KBwQBAwECAwMSA1giIwrdAQoGBAEDAQIEEgNcBCcazQEg
VGhlIGFjY2VzcyB0b2tlbiBmb3IgYXV0aGVudGljYXRpbmcgQVBJIGNhbGxzIHRvIHRoZSBX
aGF0c0FwcCBDbG91ZCBBUEkuCiBodHRwczovL2RldmVsb3BlcnMuZmFjZWJvb2suY29tL2Rv
Y3Mvd2hhdHNhcHAvYnVzaW5lc3MtbWFuYWdlbWVudC1hcGkvZ2V0LXN0YXJ0ZWQvI2J1c2lu
ZXNzLWludGVncmF0aW9uLXN5c3RlbS11c2VyLWFjY2Vzcy10b2tlbnMKCg4KBwQBAwECBAUS
A1wECgoOCgcEAQMBAgQBEgNcCyIKDgoHBAEDAQIEAxIDXCUmCm8KBgQBAwECBRIDYAQqGmAg
VGhlIE1ldGEgQnVzaW5lc3MgUG9ydGZvbGlvIChNQlApIElELgogaHR0cHM6Ly93d3cuZmFj
ZWJvb2suY29tL2J1c2luZXNzL2hlbHAvMTcxMDA3NzM3OTIwMzY1NwoKDgoHBAEDAQIFBRID
YAQKCg4KBwQBAwECBQESA2ALJQoOCgcEAQMBAgUDEgNgKCkKJwoEBAEDAhIEZAJqAxoZIENv
bmZpZ3Mgb2Ygc3Vic2NyaWJlcnMuCgoMCgUEAQMCARIDZAoaCjAKBgQBAwIIABIEZgRpBRog
IFRoZSBjb25maWcgZm9yIHRoZSBzdWJzY3JpYmVyLgoKDgoHBAEDAggAARIDZgobCiAKBgQB
AwICABIDaAYmGhEgQ2VzIGFwcCBjb25maWcuCgoOCgcEAQMCAgAGEgNoBhIKDgoHBAEDAgIA
ARIDaBMhCg4KBwQBAwICAAMSA2gkJQokCgQEAQMDEgRtAnIDGhYgQ29uZmlncyBmb3IgQ0VT
IGFwcC4KCgwKBQQBAwMBEgNtChYKdQoGBAEDAwIAEgRwBHFPGmUgVGhlIHVuaXF1ZSBpZGVu
dGlmaWVyIG9mIHRoZSBDRVMgYXBwLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH1gCgoOCgcEAQMDAgAFEgNwBAoKDgoHBAED
AwIAARIDcAsOCg4KBwQBAwMCAAMSA3AREgoOCgcEAQMDAgAIEgNxCE4KEAoJBAEDAwIACJ8I
EgNxCU0KUwoEBAEDBBIEdQJ4AxpFIFJvdXRpbmcgY29uZmlnIHNwZWNpZnkgaG93L3dobyB0
byByb3V0ZSBhcHAgZXZlbnRzIHRvIGEgc3Vic2NyaWJlci4KCgwKBQQBAwQBEgN1ChcKKwoG
BAEDBAIAEgN3BB4aHCBUaGUga2V5IG9mIHRoZSBzdWJzY3JpYmVyLgoKDgoHBAEDBAIABRID
dwQKCg4KBwQBAwQCAAESA3cLGQoOCgcEAQMEAgADEgN3HB0KSwoEBAECABIEewJ8Lxo9IE9w
dGlvbmFsLiBWYXJpb3VzIG9mIGNvbmZpZ3VyYXRpb24gZm9yIGhhbmRsaW5nIEFwcCBldmVu
dHMuCgoMCgUEAQIABhIDewIcCgwKBQQBAgABEgN7HSwKDAoFBAECAAMSA3svMAoMCgUEAQIA
CBIDfAYuCg8KCAQBAgAInAgAEgN8By0KOgoEBAECARIFfwKAAS8aKyBPcHRpb25hbC4gVmFy
aW91cyBvZiBzdWJzY3JpYmVycyBjb25maWdzLgoKDAoFBAECAQYSA38CHwoMCgUEAQIBARID
fyAyCgwKBQQBAgEDEgN/NTYKDQoFBAECAQgSBIABBi4KEAoIBAECAQicCAASBIABBy0KjwEK
BAQBAgISBoQBAoUBLxp/IE9wdGlvbmFsLiBUaGUga2V5IG9mIHJvdXRpbmdfY29uZmlncyBp
cyBhIGtleSBvZiBgYXBwX2NvbmZpZ3NgLCB2YWx1ZSBpcyBhCiBgUm91dGluZ0NvbmZpZ2As
IHdoaWNoIGNvbnRhaW5zIHN1YnNjcmliZXIncyBrZXkuCgoNCgUEAQICBhIEhAECHAoNCgUE
AQICARIEhAEdLAoNCgUEAQICAxIEhAEvMAoNCgUEAQICCBIEhQEGLgoQCggEAQICCJwIABIE
hQEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel ===
    # Fields for Omnichannel
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: integration_config Type: 11 (.google.cloud.ces.v1beta.OmnichannelIntegrationConfig)

# === Message: Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig ===
    # Fields for OmnichannelIntegrationConfig
    # Field: channel_configs Type: 11 (.google.cloud.ces.v1beta.OmnichannelIntegrationConfig.ChannelConfigsEntry)
    # Field: subscriber_configs Type: 11 (.google.cloud.ces.v1beta.OmnichannelIntegrationConfig.SubscriberConfigsEntry)
    # Field: routing_configs Type: 11 (.google.cloud.ces.v1beta.OmnichannelIntegrationConfig.RoutingConfigsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Omnichannel - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/omnichannel.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Omnichannel;

    my $msg = Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/omnichannel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel

Represents an Omnichannel resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the omnichannel resource.
Format:
`projects/{project}/locations/{location}/omnichannels/{omnichannel}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the omnichannel resource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Human-readable description of the omnichannel resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the omnichannel resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the omnichannel resource was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. Etag used to ensure the object hasn't changed during a
read-modify-write operation.

=item * C<< $msg->integration_config() >> / C<< $msg->integration_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig>)

Optional. The integration config for the omnichannel resource.

=back

=head2 Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig

OmnichannelIntegrationConfig contains all App integration configs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->channel_configs() >> / C<< $msg->channel_configs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfigsEntry>)

Optional. Various of configuration for handling App events.

=item * C<< $msg->subscriber_configs() >> / C<< $msg->subscriber_configs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfigsEntry>)

Optional. Various of subscribers configs.

=item * C<< $msg->routing_configs() >> / C<< $msg->routing_configs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfigsEntry>)

Optional. The key of routing_configs is a key of `app_configs`, value is a
`RoutingConfig`, which contains subscriber's key.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Omnichannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
