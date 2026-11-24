package Google::Cloud::Designcenter::V1::BestPracticesMessages;

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
    eval { require Google::Cloud::Config::V1::Config };
    eval { require Google::Cloud::Designcenter::V1::Assessment };
    eval { require Google::Cloud::Designcenter::V1::BestPractices };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2Jlc3RfcHJhY3RpY2VzX21lc3NhZ2Vz
LnByb3RvEhxnb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiNnb29nbGUvY2xv
dWQvY29uZmlnL3YxL2NvbmZpZy5wcm90bxotZ29vZ2xlL2Nsb3VkL2Rlc2lnbmNlbnRlci92
MS9hc3Nlc3NtZW50LnByb3RvGjFnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2Jlc3Rf
cHJhY3RpY2VzLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byJuCidG
ZXRjaEFwcGxpY2F0aW9uQXNzZXNzbWVudFJlcG9ydFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv
4EEC+kEpCidkZXNpZ25jZW50ZXIuZ29vZ2xlYXBpcy5jb20vQXBwbGljYXRpb25SBG5hbWUi
hwEKKEZldGNoQXBwbGljYXRpb25Bc3Nlc3NtZW50UmVwb3J0UmVzcG9uc2USWwoRYXNzZXNz
bWVudF9yZXBvcnQYASABKAsyLi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkFzc2Vz
c21lbnRSZXBvcnRSEGFzc2Vzc21lbnRSZXBvcnQicQoqR2VuZXJhdGVBcHBsaWNhdGlvbkFz
c2Vzc21lbnRSZXBvcnRSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonZGVzaWduY2Vu
dGVyLmdvb2dsZWFwaXMuY29tL0FwcGxpY2F0aW9uUgRuYW1lIo8BCitHZW5lcmF0ZUFwcGxp
Y2F0aW9uQXNzZXNzbWVudFJlcG9ydFJlc3BvbnNlEmAKEWFzc2Vzc21lbnRfcmVwb3J0GAEg
ASgLMi4uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5Bc3Nlc3NtZW50UmVwb3J0QgPg
QQNSEGFzc2Vzc21lbnRSZXBvcnQisQEKMkdlbmVyYXRlQXBwbGljYXRpb25UZW1wbGF0ZUFz
c2Vzc21lbnRSZXBvcnRSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovZGVzaWduY2Vu
dGVyLmdvb2dsZWFwaXMuY29tL0FwcGxpY2F0aW9uVGVtcGxhdGVSBG5hbWUSLgoPc2Vydmlj
ZV9hY2NvdW50GAIgASgJQgUYAeBBAVIOc2VydmljZUFjY291bnQi0QEKM0dlbmVyYXRlQXBw
bGljYXRpb25UZW1wbGF0ZUFzc2Vzc21lbnRSZXBvcnRSZXNwb25zZRI9CgdwcmV2aWV3GAEg
ASgLMh8uZ29vZ2xlLmNsb3VkLmNvbmZpZy52MS5QcmV2aWV3QgIYAVIHcHJldmlldxJbChFh
c3Nlc3NtZW50X3JlcG9ydBgCIAEoCzIuLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEu
QXNzZXNzbWVudFJlcG9ydFIQYXNzZXNzbWVudFJlcG9ydCLVAQofR2VuZXJhdGVBc3Nlc3Nt
ZW50UmVwb3J0UmVxdWVzdBIqCg50ZXJyYWZvcm1fcGxhbhgBIAEoDEID4EECUg10ZXJyYWZv
cm1QbGFuEjgKFWFkZGl0aW9uYWxfZnJhbWV3b3JrcxgCIAMoCUID4EEBUhRhZGRpdGlvbmFs
RnJhbWV3b3JrcxJICgpzcGFjZV9uYW1lGAMgASgJQingQQL6QSMKIWRlc2lnbmNlbnRlci5n
b29nbGVhcGlzLmNvbS9TcGFjZVIJc3BhY2VOYW1lOgIYASKDAQogR2VuZXJhdGVBc3Nlc3Nt
ZW50UmVwb3J0UmVzcG9uc2USWwoRYXNzZXNzbWVudF9yZXBvcnQYASABKAsyLi5nb29nbGUu
Y2xvdWQuZGVzaWduY2VudGVyLnYxLkFzc2Vzc21lbnRSZXBvcnRSEGFzc2Vzc21lbnRSZXBv
cnQ6AhgBItMBCixHZW5lcmF0ZVRlcnJhZm9ybVBsYW5Bc3Nlc3NtZW50UmVwb3J0UmVxdWVz
dBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWRlc2lnbmNlbnRlci5nb29nbGVhcGlzLmNvbS9T
cGFjZVIEbmFtZRIqCg50ZXJyYWZvcm1fcGxhbhgCIAEoDEID4EECUg10ZXJyYWZvcm1QbGFu
EjgKFWFkZGl0aW9uYWxfZnJhbWV3b3JrcxgDIAMoCUID4EEBUhRhZGRpdGlvbmFsRnJhbWV3
b3JrcyKMAQotR2VuZXJhdGVUZXJyYWZvcm1QbGFuQXNzZXNzbWVudFJlcG9ydFJlc3BvbnNl
ElsKEWFzc2Vzc21lbnRfcmVwb3J0GAEgASgLMi4uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRl
ci52MS5Bc3Nlc3NtZW50UmVwb3J0UhBhc3Nlc3NtZW50UmVwb3J0IrkBChZGZXRjaEZyYW1l
d29ya3NSZXF1ZXN0EhsKBnBhcmVudBgBIAEoCUID4EECUgZwYXJlbnQSHwoIcHJvamVjdHMY
AiADKAlCA+BBAVIIcHJvamVjdHMSIAoJcGFnZV9zaXplGAMgASgFQgPgQQFSCHBhZ2VTaXpl
EiIKCnBhZ2VfdG9rZW4YBCABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgFIAEoCUID
4EEBUgZmaWx0ZXIiigEKF0ZldGNoRnJhbWV3b3Jrc1Jlc3BvbnNlEkcKCmZyYW1ld29ya3MY
ASADKAsyJy5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkZyYW1ld29ya1IKZnJhbWV3
b3JrcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iUgoQR2V0UG9s
aWN5UmVxdWVzdBI+CgRuYW1lGAEgASgJQirgQQL6QSQKImRlc2lnbmNlbnRlci5nb29nbGVh
cGlzLmNvbS9Qb2xpY3lSBG5hbWUi3AEKE0xpc3RQb2xpY2llc1JlcXVlc3QSQgoGcGFyZW50
GAEgASgJQirgQQL6QSQSImRlc2lnbmNlbnRlci5nb29nbGVhcGlzLmNvbS9Qb2xpY3lSBnBh
cmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghv
cmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IoABChRMaXN0UG9saWNpZXNSZXNwb25zZRJA
Cghwb2xpY2llcxgBIAMoCzIkLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuUG9saWN5
Ughwb2xpY2llcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4ivgEK
E0NyZWF0ZVBvbGljeVJlcXVlc3QSQgoGcGFyZW50GAEgASgJQirgQQL6QSQSImRlc2lnbmNl
bnRlci5nb29nbGVhcGlzLmNvbS9Qb2xpY3lSBnBhcmVudBIgCglwb2xpY3lfaWQYAiABKAlC
A+BBAlIIcG9saWN5SWQSQQoGcG9saWN5GAMgASgLMiQuZ29vZ2xlLmNsb3VkLmRlc2lnbmNl
bnRlci52MS5Qb2xpY3lCA+BBAlIGcG9saWN5IpoBChNVcGRhdGVQb2xpY3lSZXF1ZXN0EkAK
C3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1
cGRhdGVNYXNrEkEKBnBvbGljeRgCIAEoCzIkLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIu
djEuUG9saWN5QgPgQQJSBnBvbGljeSJVChNEZWxldGVQb2xpY3lSZXF1ZXN0Ej4KBG5hbWUY
ASABKAlCKuBBAvpBJAoiZGVzaWduY2VudGVyLmdvb2dsZWFwaXMuY29tL1BvbGljeVIEbmFt
ZULpAQogY29tLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjFCHUJlc3RQcmFjdGljZXNS
cGNNZXNzYWdlc1Byb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vZGVzaWduY2VudGVyL2Fw
aXYxL2Rlc2lnbmNlbnRlcnBiO2Rlc2lnbmNlbnRlcnBiqgIcR29vZ2xlLkNsb3VkLkRlc2ln
bkNlbnRlci5WMcoCHEdvb2dsZVxDbG91ZFxEZXNpZ25DZW50ZXJcVjHqAh9Hb29nbGU6OkNs
b3VkOjpEZXNpZ25DZW50ZXI6OlYxSqZRCgcSBQ4AqQIBCrwECgEMEgMOABIysQQgQ29weXJp
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
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhID
FAAtCgkKAgMDEgMVADcKCQoCAwQSAxYAOwoJCgIDBRIDFwAqCggKAQgSAxkAOQoJCgIIJRID
GQA5CggKAQgSAxoAWwoJCgIICxIDGgBbCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwA
PgoJCgIICBIDHAA+CggKAQgSAx0AOQoJCgIIARIDHQA5CggKAQgSAx4AOQoJCgIIKRIDHgA5
CggKAQgSAx8AOAoJCgIILRIDHwA4CkQKAgQAEgQiACsBGjggTWVzc2FnZSBmb3IgZmV0Y2hp
bmcgYW4gYXBwbGljYXRpb24gYXNzZXNzbWVudCByZXBvcnQuCgoKCgMEAAESAyIILwqZAQoE
BAACABIEJQIqBBqKASBSZXF1aXJlZC4gVGhlIGFwcGxpY2F0aW9uIG5hbWUgaW4gdGhlIGZv
bGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlv
bi9zcGFjZXMvJHNwYWNlL2FwcGxpY2F0aW9ucy8kYXBwbGljYXRpb25gCgoMCgUEAAIABRID
JQIICgwKBQQAAgABEgMlCQ0KDAoFBAACAAMSAyUQEQoNCgUEAAIACBIEJRIqAwoPCggEAAIA
CJwIABIDJgQqCg8KBwQAAgAInwgSBCcEKQUKUAoCBAESBC4AMQEaRCBNZXNzYWdlIGZvciBy
ZXNwb25zZSBvZiBmZXRjaGluZyBhbiBhcHBsaWNhdGlvbiBhc3Nlc3NtZW50IHJlcG9ydC4K
CgoKAwQBARIDLggwCjUKBAQBAgASAzACKRooIEFzc2Vzc21lbnQgcmVwb3J0IGZvciB0aGUg
YXBwbGljYXRpb24uCgoMCgUEAQIABhIDMAISCgwKBQQBAgABEgMwEyQKDAoFBAECAAMSAzAn
KApGCgIEAhIENAA9ARo6IE1lc3NhZ2UgZm9yIGdlbmVyYXRpbmcgYW4gYXBwbGljYXRpb24g
YXNzZXNzbWVudCByZXBvcnQuCgoKCgMEAgESAzQIMgqZAQoEBAICABIENwI8BBqKASBSZXF1
aXJlZC4gVGhlIGFwcGxpY2F0aW9uIG5hbWUgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBg
cHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMvJHNwYWNlL2Fw
cGxpY2F0aW9ucy8kYXBwbGljYXRpb25gCgoMCgUEAgIABRIDNwIICgwKBQQCAgABEgM3CQ0K
DAoFBAICAAMSAzcQEQoNCgUEAgIACBIENxI8AwoPCggEAgIACJwIABIDOAQqCg8KBwQCAgAI
nwgSBDkEOwUKPwoCBAMSBEAARAEaMyBSZXNwb25zZSBmb3IgR2VuZXJhdGVBcHBsaWNhdGlv
bkFzc2Vzc21lbnRSZXBvcnQuCgoKCgMEAwESA0AIMwpHCgQEAwIAEgRCAkMyGjkgT3V0cHV0
IG9ubHkuIEJlc3QgcHJhY3RpY2VzIGJ5IERlc2lnbiBBc3Nlc3NtZW50IHJlcG9ydAoKDAoF
BAMCAAYSA0ICEgoMCgUEAwIAARIDQhMkCgwKBQQDAgADEgNCJygKDAoFBAMCAAgSA0MGMQoP
CggEAwIACJwIABIDQwcwCkoKAgQEEgRHAFsBGj4gTWVzc2FnZSBmb3IgZ2VuZXJhdGUgYXNz
ZXNzbWVudCByZXBvcnQgYXBwbGljYXRpb24gdGVtcGxhdGUuCgoKCgMEBAESA0cIOgqyAQoE
BAQCABIESgJPBBqjASBSZXF1aXJlZC4gVGhlIGFwcGxpY2F0aW9uIHRlbXBsYXRlIG5hbWUg
aW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25z
LyRsb2NhdGlvbi9zcGFjZXMvJHNwYWNlL2FwcGxpY2F0aW9uVGVtcGxhdGVzLyRhcHBsaWNh
dGlvblRlbXBsYXRlYAoKDAoFBAQCAAUSA0oCCAoMCgUEBAIAARIDSgkNCgwKBQQEAgADEgNK
EBEKDQoFBAQCAAgSBEoSTwMKDwoIBAQCAAicCAASA0sEKgoPCgcEBAIACJ8IEgRMBE4FCtAC
CgQEBAIBEgRZAlpCGsECIE9wdGlvbmFsLiBEZXByZWNhdGVkOiBUaGlzIGZpZWxkIGlzIG5v
IGxvbmdlciB1c2VkIHNpbmNlIHdlIG1vdmVkIHRvIGZhc3QKIHBsYW4gYXNzZXNzbWVudC4K
CiAtIFRoaXMgc2VydmljZSBhY2NvdW50IHdpbGwgYmUgdXNlZCB0byBleGVjdXRlIHRoZSBw
cmV2aWV3CiAgIHByb2Nlc3MuCiAtIFRoZSBjYWxsZXIgbXVzdCBoYXZlIHRoZSAnaWFtLnNl
cnZpY2VBY2NvdW50cy5hY3RBcycgcGVybWlzc2lvbiBvbiB0aGlzCiAgIHNlcnZpY2UgYWNj
b3VudC4KIEZvcm1hdDogcHJvamVjdHMve1BST0pFQ1R9L3NlcnZpY2VBY2NvdW50cy97RU1B
SUxfQUREUkVTU30KCgwKBQQEAgEFEgNZAggKDAoFBAQCAQESA1kJGAoMCgUEBAIBAxIDWRsc
CgwKBQQEAgEIEgNaBkEKDQoGBAQCAQgDEgNaBxgKDwoIBAQCAQicCAASA1oaQApNCgIEBRIE
XgBmARpBIFJlc3BvbnNlIGZvciBHZW5lcmF0ZUFzc2Vzc21lbnRSZXBvcnQgZm9yIGFwcGxp
Y2F0aW9uIHRlbXBsYXRlLgoKCgoDBAUBEgNeCDsKgQEKBAQFAgASA2ICQRp0IERlcHJlY2F0
ZWQ6IFRoaXMgZmllbGQgaXMgbm8gbG9uZ2VyIHVzZWQgc2luY2Ugd2UgbW92ZWQgdG8gZmFz
dCBwbGFuCiBhc3Nlc3NtZW50LgogSW5mcmFzdHJ1Y3R1cmUgTWFuYWdlciBwcmV2aWV3LgoK
DAoFBAUCAAYSA2ICIAoMCgUEBQIAARIDYiEoCgwKBQQFAgADEgNiKywKDAoFBAUCAAgSA2It
QAoNCgYEBQIACAMSA2IuPwo5CgQEBQIBEgNlAikaLCBCZXN0IHByYWN0aWNlcyBieSBEZXNp
Z24gQXNzZXNzbWVudCByZXBvcnQKCgwKBQQFAgEGEgNlAhIKDAoFBAUCAQESA2UTJAoMCgUE
BQIBAxIDZScoCq4BCgIEBhIEbAB/ARqhASBEZXByZWNhdGVkOiBVc2UgR2VuZXJhdGVUZXJy
YWZvcm1QbGFuQXNzZXNzbWVudFJlcG9ydFJlcXVlc3QgaW5zdGVhZC4KCiBNZXNzYWdlIGZv
ciB0aGUgcmVxdWVzdCB0byBnZW5lcmF0ZSBhIGJlc3QgcHJhY3RpY2UgcmVwb3J0IGZvciBh
IGdpdmVuCiBUZXJyYWZvcm0gcGxhbi4KCgoKAwQGARIDbAgnCgoKAwQGBxIDbQIbCgsKBAQG
BwMSA20CGwouCgQEBgIAEgNwAkQaISBSZXF1aXJlZC4gVGVycmFmb3JtIHBsYW4gYnl0ZXMu
CgoMCgUEBgIABRIDcAIHCgwKBQQGAgABEgNwCBYKDAoFBAYCAAMSA3AZGgoMCgUEBgIACBID
cBtDCg8KCAQGAgAInAgAEgNwHEIKmQEKBAQGAgESBHQCdS8aigEgT3B0aW9uYWwuIEFkZGl0
aW9uYWwgRnJhbWV3b3JrcyB0byBydW4gYXNzZXNzbWVudCBhZ2FpbnN0LiBJZiBlbXB0eSwg
cnVuCiBhZ2FpbnN0IGRlZmF1bHQgZnJhbWV3b3Jrcy4gRnJhbWV3b3JrcyByZWZlcnMgdG8g
dGhlIHBvbGljaWVzLgoKDAoFBAYCAQQSA3QCCgoMCgUEBgIBBRIDdAsRCgwKBQQGAgEBEgN0
EicKDAoFBAYCAQMSA3QqKwoMCgUEBgIBCBIDdQYuCg8KCAQGAgEInAgAEgN1By0KngEKBAQG
AgISBHkCfgQajwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzcGFjZSBhdCB3aGljaCBH
ZW5lcmF0ZSBBc3Nlc3NtZW50IFJlcG9ydCBpcwogY2FsbGVkLiBGb3JtYXQ6IGBwcm9qZWN0
cy8kcHJvamVjdC9sb2NhdGlvbnMvJGxvY2F0aW9uL3NwYWNlcy8kc3BhY2VgCgoMCgUEBgIC
BRIDeQIICgwKBQQGAgIBEgN5CRMKDAoFBAYCAgMSA3kWFwoNCgUEBgICCBIEeRh+AwoPCggE
BgICCJwIABIDegQqCg8KBwQGAgIInwgSBHsEfQUKfwoCBAcSBoQBAIkBARpxIERlcHJlY2F0
ZWQ6IFVzZSBHZW5lcmF0ZVRlcnJhZm9ybVBsYW5Bc3Nlc3NtZW50UmVwb3J0UmVzcG9uc2Ug
aW5zdGVhZC4KCiBSZXNwb25zZSBmb3IgR2VuZXJhdGVBc3Nlc3NtZW50UmVwb3J0LgoKCwoD
BAcBEgSEAQgoCgsKAwQHBxIEhQECGwoMCgQEBwcDEgSFAQIbCj4KBAQHAgASBIgBAikaMCBB
Z2dyZWdhdGVkIGFzc2Vzc21lbnQgcmVwb3J0IGZyb20gYWxsIGRvbWFpbnMuCgoNCgUEBwIA
BhIEiAECEgoNCgUEBwIAARIEiAETJAoNCgUEBwIAAxIEiAEnKAp/CgIECBIGjQEAnwEBGnEg
TWVzc2FnZSBmb3IgdGhlIHJlcXVlc3QgdG8gZ2VuZXJhdGUgYSBiZXN0IHByYWN0aWNlIHJl
cG9ydCBmb3IgYSBnaXZlbgogVGVycmFmb3JtIHBsYW4gYXQgdGhlIGNvbGxlY3Rpb24gbGV2
ZWwuCgoLCgMECAESBI0BCDQKmQEKBAQIAgASBpABApUBBBqIASBSZXF1aXJlZC4gVGhlIHBh
cmVudCByZXNvdXJjZSBpbiB3aGljaCB0byBnZW5lcmF0ZSB0aGUgYXNzZXNzbWVudCByZXBv
cnQuCiBGb3JtYXQ6IHByb2plY3RzLyRwcm9qZWN0L2xvY2F0aW9ucy8kbG9jYXRpb24vc3Bh
Y2VzLyRzcGFjZQoKDQoFBAgCAAUSBJABAggKDQoFBAgCAAESBJABCQ0KDQoFBAgCAAMSBJAB
EBEKDwoFBAgCAAgSBpABEpUBAwoQCggECAIACJwIABIEkQEEKgoRCgcECAIACJ8IEgaSAQSU
AQUKagoEBAgCARIEmQECRBpcIFJlcXVpcmVkLiBUaGUgcmF3IEpTT04gcmVwcmVzZW50YXRp
b24gb2YgdGhlIGdlbmVyYXRlZCBUZXJyYWZvcm0gcGxhbiwKIHByb3ZpZGVkIGFzIGJ5dGVz
LgoKDQoFBAgCAQUSBJkBAgcKDQoFBAgCAQESBJkBCBYKDQoFBAgCAQMSBJkBGRoKDQoFBAgC
AQgSBJkBG0MKEAoIBAgCAQicCAASBJkBHEIKmwEKBAQIAgISBp0BAp4BLxqKASBPcHRpb25h
bC4gQWRkaXRpb25hbCBGcmFtZXdvcmtzIHRvIHJ1biBhc3Nlc3NtZW50IGFnYWluc3QuIElm
IGVtcHR5LCBydW4KIGFnYWluc3QgZGVmYXVsdCBmcmFtZXdvcmtzLiBGcmFtZXdvcmtzIHJl
ZmVycyB0byB0aGUgcG9saWNpZXMuCgoNCgUECAICBBIEnQECCgoNCgUECAICBRIEnQELEQoN
CgUECAICARIEnQESJwoNCgUECAICAxIEnQEqKwoNCgUECAICCBIEngEGLgoQCggECAICCJwI
ABIEngEHLQpDCgIECRIGogEApQEBGjUgUmVzcG9uc2UgZm9yIEdlbmVyYXRlVGVycmFmb3Jt
UGxhbkFzc2Vzc21lbnRSZXBvcnQuCgoLCgMECQESBKIBCDUKPgoEBAkCABIEpAECKRowIEFn
Z3JlZ2F0ZWQgYXNzZXNzbWVudCByZXBvcnQgZnJvbSBhbGwgZG9tYWlucy4KCg0KBQQJAgAG
EgSkAQISCg0KBQQJAgABEgSkARMkCg0KBQQJAgADEgSkAScoCi8KAgQKEgaoAQC+AQEaISBS
ZXF1ZXN0IGZvciBGZXRjaEZyYW1ld29ya3MgcnBjCgoLCgMECgESBKgBCB4KZAoEBAoCABIE
qwECPRpWIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUuCiBGb3JtYXQ6IHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufQoKDQoFBAoCAAUSBKsBAggK
DQoFBAoCAAESBKsBCQ8KDQoFBAoCAAMSBKsBEhMKDQoFBAoCAAgSBKsBFDwKEAoIBAoCAAic
CAASBKsBFTsKVwoEBAoCARIErwECSBpJIE9wdGlvbmFsLiBQcm9qZWN0cyB0byBmZXRjaCBm
cmFtZXdvcmtzIGZvci4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9CgoNCgUECgIBBBIE
rwECCgoNCgUECgIBBRIErwELEQoNCgUECgIBARIErwESGgoNCgUECgIBAxIErwEdHgoNCgUE
CgIBCBIErwEfRwoQCggECgIBCJwIABIErwEgRgrWAQoEBAoCAhIEtAECPxrHASBPcHRpb25h
bC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuIGZyb20gdGhpcyBy
ZXF1ZXN0LgogTm9uLXBvc2l0aXZlIHZhbHVlcyBhcmUgaWdub3JlZC4gVGhlIHByZXNlbmNl
IG9mIG5leHRQYWdlVG9rZW4gaW4gdGhlCiByZXNwb25zZSBpbmRpY2F0ZXMgdGhhdCBtb3Jl
IHJlc3VsdHMgbWlnaHQgYmUgYXZhaWxhYmxlLgoKDQoFBAoCAgUSBLQBAgcKDQoFBAoCAgES
BLQBCBEKDQoFBAoCAgMSBLQBFBUKDQoFBAoCAggSBLQBFj4KEAoIBAoCAgicCAASBLQBFz0K
mwIKBAQKAgMSBLoBAkEajAIgT3B0aW9uYWwuIElmIHByZXNlbnQsIHRoZW4gcmV0cmlldmUg
dGhlIG5leHQgYmF0Y2ggb2YgcmVzdWx0cyBmcm9tIHRoZQogcHJlY2VkaW5nIGNhbGwgdG8g
dGhpcyBtZXRob2QuIHBhZ2VUb2tlbiBtdXN0IGJlIHRoZSB2YWx1ZSBvZiBuZXh0UGFnZVRv
a2VuCiBmcm9tIHRoZSBwcmV2aW91cyByZXNwb25zZS4gVGhlIHZhbHVlcyBvZiBvdGhlciBt
ZXRob2QgcGFyYW1ldGVycyBzaG91bGQgYmUKIGlkZW50aWNhbCB0byB0aG9zZSBpbiB0aGUg
cHJldmlvdXMgY2FsbC4KCg0KBQQKAgMFEgS6AQIICg0KBQQKAgMBEgS6AQkTCg0KBQQKAgMD
EgS6ARYXCg0KBQQKAgMIEgS6ARhAChAKCAQKAgMInAgAEgS6ARk/CjUKBAQKAgQSBL0BAj0a
JyBPcHRpb25hbC4gRmlsdGVyIGZvciBmcmFtZXdvcmtzIGxpc3QuCgoNCgUECgIEBRIEvQEC
CAoNCgUECgIEARIEvQEJDwoNCgUECgIEAxIEvQESEwoNCgUECgIECBIEvQEUPAoQCggECgIE
CJwIABIEvQEVOwowCgIECxIGwQEAyAEBGiIgUmVzcG9uc2UgZm9yIEZldGNoRnJhbWV3b3Jr
cyBycGMKCgsKAwQLARIEwQEIHwonCgQECwIAEgTDAQIkGhkgVGhlIGxpc3Qgb2YgZnJhbWV3
b3Jrcy4KCg0KBQQLAgAEEgTDAQIKCg0KBQQLAgAGEgTDAQsUCg0KBQQLAgABEgTDARUfCg0K
BQQLAgADEgTDASIjCpABCgQECwIBEgTHAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBz
ZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhp
cyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0K
BQQLAgEFEgTHAQIICg0KBQQLAgEBEgTHAQkYCg0KBQQLAgEDEgTHARscCi0KAgQMEgbLAQDU
AQEaHyBNZXNzYWdlIGZvciBnZXR0aW5nIGEgcG9saWN5LgoKCwoDBAwBEgTLAQgYCrcBCgQE
DAIAEgbOAQLTAQQapgEgUmVxdWlyZWQuIFRoZSBwb2xpY3kgbmFtZSBpbiB0aGUgZm9sbG93
aW5nIGZvcm1hdDoKIGBwcm9qZWN0cy8kcHJvamVjdC9sb2NhdGlvbnMvJGxvY2F0aW9uL3Nw
YWNlcy8kc3BhY2UvYXBwbGljYXRpb25UZW1wbGF0ZXMvJGFwcGxpY2F0aW9uVGVtcGxhdGUv
cG9saWNpZXMvJHBvbGljeWAKCg0KBQQMAgAFEgTOAQIICg0KBQQMAgABEgTOAQkNCg0KBQQM
AgADEgTOARARCg8KBQQMAgAIEgbOARLTAQMKEAoIBAwCAAicCAASBM8BBCoKEQoHBAwCAAif
CBIG0AEE0gEFCjoKAgQNEgbXAQDyAQEaLCBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGEgbGlz
dCBvZiBwb2xpY2llcy4KCgsKAwQNARIE1wEIGwrWAQoEBA0CABIG2wEC4AEEGsUBIFJlcXVp
cmVkLiBUaGUgcGFyZW50IGFwcGxpY2F0aW9uIHRlbXBsYXRlIGZyb20gd2hpY2ggcG9saWNp
ZXMgYXJlIGxpc3RlZCBpbgogdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHBy
b2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMvJHNwYWNlL2FwcGxpY2F0aW9uVGVt
cGxhdGVzLyRhcHBsaWNhdGlvblRlbXBsYXRlYAoKDQoFBA0CAAUSBNsBAggKDQoFBA0CAAES
BNsBCQ8KDQoFBA0CAAMSBNsBEhMKDwoFBA0CAAgSBtsBFOABAwoQCggEDQIACJwIABIE3AEE
KgoRCgcEDQIACJ8IEgbdAQTfAQUK1gEKBAQNAgESBOUBAj8axwEgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybiBmcm9tIHRoaXMgcmVxdWVzdC4K
IE5vbi1wb3NpdGl2ZSB2YWx1ZXMgYXJlIGlnbm9yZWQuIFRoZSBwcmVzZW5jZSBvZiBuZXh0
UGFnZVRva2VuIGluIHRoZQogcmVzcG9uc2UgaW5kaWNhdGVzIHRoYXQgbW9yZSByZXN1bHRz
IG1pZ2h0IGJlIGF2YWlsYWJsZS4KCg0KBQQNAgEFEgTlAQIHCg0KBQQNAgEBEgTlAQgRCg0K
BQQNAgEDEgTlARQVCg0KBQQNAgEIEgTlARY+ChAKCAQNAgEInAgAEgTlARc9CpYCCgQEDQIC
EgTrAQJBGocCIE9wdGlvbmFsLiBJZiBwcmVzZW50LCByZXRyaWV2ZSB0aGUgbmV4dCBiYXRj
aCBvZiByZXN1bHRzIGZyb20gdGhlIHByZWNlZGluZwogY2FsbCB0byB0aGlzIG1ldGhvZC4g
cGFnZVRva2VuIG11c3QgYmUgdGhlIHZhbHVlIG9mIG5leHRQYWdlVG9rZW4gZnJvbSB0aGUK
IHByZXZpb3VzIHJlc3BvbnNlLiBUaGUgdmFsdWVzIG9mIG90aGVyIG1ldGhvZCBwYXJhbWV0
ZXJzIHNob3VsZCBiZQogaWRlbnRpY2FsIHRvIHRob3NlIGluIHRoZSBwcmV2aW91cyBjYWxs
LgoKDQoFBA0CAgUSBOsBAggKDQoFBA0CAgESBOsBCRMKDQoFBA0CAgMSBOsBFhcKDQoFBA0C
AggSBOsBGEAKEAoIBA0CAgicCAASBOsBGT8KSQoEBA0CAxIE7gECPRo7IE9wdGlvbmFsLiBB
IGZpbHRlciB0aGF0IGNob29zZXMgd2hpY2ggcG9saWNpZXMgdG8gcmV0dXJuLgoKDQoFBA0C
AwUSBO4BAggKDQoFBA0CAwESBO4BCQ8KDQoFBA0CAwMSBO4BEhMKDQoFBA0CAwgSBO4BFDwK
EAoIBA0CAwicCAASBO4BFTsKOwoEBA0CBBIE8QECPxotIE9wdGlvbmFsLiBIb3cgdGhlIHJl
c3VsdHMgc2hvdWxkIGJlIHNvcnRlZC4KCg0KBQQNAgQFEgTxAQIICg0KBQQNAgQBEgTxAQkR
Cg0KBQQNAgQDEgTxARQVCg0KBQQNAgQIEgTxARY+ChAKCAQNAgQInAgAEgTxARc9CjkKAgQO
Egb1AQD9AQEaKyBNZXNzYWdlIGZvciByZXNwb25zZSB0byBsaXN0aW5nIHBvbGljaWVzLgoK
CwoDBA4BEgT1AQgcCiMKBAQOAgASBPcBAh8aFSBBIGxpc3Qgb2YgcG9saWNpZXMuCgoNCgUE
DgIABBIE9wECCgoNCgUEDgIABhIE9wELEQoNCgUEDgIAARIE9wESGgoNCgUEDgIAAxIE9wEd
HgreAQoEBA4CARIE/AECHRrPASBJZiB0aGVyZSBtaWdodCBiZSBtb3JlIHJlc3VsdHMgdGhh
biB0aG9zZSBhcHBlYXJpbmcgaW4gdGhpcyByZXNwb25zZSwgdGhlbgogbmV4dFBhZ2VUb2tl
biBpcyBpbmNsdWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiByZXN1bHRzLCBjYWxsIHRo
aXMgbWV0aG9kCiBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgbmV4dFBhZ2VUb2tlbiBhcyBw
YWdlVG9rZW4uCgoNCgUEDgIBBRIE/AECCAoNCgUEDgIBARIE/AEJGAoNCgUEDgIBAxIE/AEb
HAouCgIEDxIGgAIAkAIBGiAgTWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBwb2xpY3kuCgoLCgME
DwESBIACCBsKyQEKBAQPAgASBoQCAokCBBq4ASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNv
dXJjZSBpbiB3aGljaCB0byBjcmVhdGUgdGhlIHBvbGljeSBpbiB0aGUKIGZvbGxvd2luZyBm
b3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMv
JHNwYWNlL2FwcGxpY2F0aW9uVGVtcGxhdGVzLyRhcHBsaWNhdGlvblRlbXBsYXRlYAoKDQoF
BA8CAAUSBIQCAggKDQoFBA8CAAESBIQCCQ8KDQoFBA8CAAMSBIQCEhMKDwoFBA8CAAgSBoQC
FIkCAwoQCggEDwIACJwIABIEhQIEKgoRCgcEDwIACJ8IEgaGAgSIAgUKOQoEBA8CARIEjAIC
QBorIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIHBvbGljeSB0byBjcmVhdGUuCgoNCgUEDwIB
BRIEjAICCAoNCgUEDwIBARIEjAIJEgoNCgUEDwIBAxIEjAIVFgoNCgUEDwIBCBIEjAIXPwoQ
CggEDwIBCJwIABIEjAIYPgovCgQEDwICEgSPAgI9GiEgUmVxdWlyZWQuIFRoZSBwb2xpY3kg
dG8gY3JlYXRlLgoKDQoFBA8CAgYSBI8CAggKDQoFBA8CAgESBI8CCQ8KDQoFBA8CAgMSBI8C
EhMKDQoFBA8CAggSBI8CFDwKEAoIBA8CAgicCAASBI8CFTsKLgoCBBASBpMCAJ0CARogIE1l
c3NhZ2UgZm9yIHVwZGF0aW5nIGEgcG9saWN5LgoKCwoDBBABEgSTAggbCpQCCgQEEAIAEgaY
AgKZAi8agwIgT3B0aW9uYWwuIFRoZSBmaWVsZHMgdG8gb3ZlcndyaXRlIGluIHRoZSBwb2xp
Y3kgdXBkYXRlLiBUaGUgZmllbGRzCiBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFy
ZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdCB0aGUgZnVsbAogcmVxdWVzdC4gQSBm
aWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB5b3Ug
ZG9uJ3QKIHByb3ZpZGUgYSBtYXNrLCBhbGwgZmllbGRzIGFyZSBvdmVyd3JpdHRlbi4KCg0K
BQQQAgAGEgSYAgIbCg0KBQQQAgABEgSYAhwnCg0KBQQQAgADEgSYAiorCg0KBQQQAgAIEgSZ
AgYuChAKCAQQAgAInAgAEgSZAgctCi8KBAQQAgESBJwCAj0aISBSZXF1aXJlZC4gVGhlIHBv
bGljeSB0byB1cGRhdGUuCgoNCgUEEAIBBhIEnAICCAoNCgUEEAIBARIEnAIJDwoNCgUEEAIB
AxIEnAISEwoNCgUEEAIBCBIEnAIUPAoQCggEEAIBCJwIABIEnAIVOwouCgIEERIGoAIAqQIB
GiAgTWVzc2FnZSBmb3IgZGVsZXRpbmcgYSBwb2xpY3kuCgoLCgMEEQESBKACCBsKtwEKBAQR
AgASBqMCAqgCBBqmASBSZXF1aXJlZC4gVGhlIHBvbGljeSBuYW1lIGluIHRoZSBmb2xsb3dp
bmcgZm9ybWF0OgogYHByb2plY3RzLyRwcm9qZWN0L2xvY2F0aW9ucy8kbG9jYXRpb24vc3Bh
Y2VzLyRzcGFjZS9hcHBsaWNhdGlvblRlbXBsYXRlcy8kYXBwbGljYXRpb25UZW1wbGF0ZS9w
b2xpY2llcy8kcG9saWN5YAoKDQoFBBECAAUSBKMCAggKDQoFBBECAAESBKMCCQ0KDQoFBBEC
AAMSBKMCEBEKDwoFBBECAAgSBqMCEqgCAwoQCggEEQIACJwIABIEpAIEKgoRCgcEEQIACJ8I
EgalAgSnAgViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest ===
    # Fields for FetchApplicationAssessmentReportRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportResponse ===
    # Fields for FetchApplicationAssessmentReportResponse
    # Field: assessment_report Type: 11 (.google.cloud.designcenter.v1.AssessmentReport)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportRequest ===
    # Fields for GenerateApplicationAssessmentReportRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportResponse ===
    # Fields for GenerateApplicationAssessmentReportResponse
    # Field: assessment_report Type: 11 (.google.cloud.designcenter.v1.AssessmentReport)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportRequest ===
    # Fields for GenerateApplicationTemplateAssessmentReportRequest
    # Field: name Type: 9 ()
    # Field: service_account Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportResponse ===
    # Fields for GenerateApplicationTemplateAssessmentReportResponse
    # Field: preview Type: 11 (.google.cloud.config.v1.Preview)
    # Field: assessment_report Type: 11 (.google.cloud.designcenter.v1.AssessmentReport)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportRequest ===
    # Fields for GenerateAssessmentReportRequest
    # Field: terraform_plan Type: 12 ()
    # Field: additional_frameworks Type: 9 ()
    # Field: space_name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportResponse ===
    # Fields for GenerateAssessmentReportResponse
    # Field: assessment_report Type: 11 (.google.cloud.designcenter.v1.AssessmentReport)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportRequest ===
    # Fields for GenerateTerraformPlanAssessmentReportRequest
    # Field: name Type: 9 ()
    # Field: terraform_plan Type: 12 ()
    # Field: additional_frameworks Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportResponse ===
    # Fields for GenerateTerraformPlanAssessmentReportResponse
    # Field: assessment_report Type: 11 (.google.cloud.designcenter.v1.AssessmentReport)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksRequest ===
    # Fields for FetchFrameworksRequest
    # Field: parent Type: 9 ()
    # Field: projects Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksResponse ===
    # Fields for FetchFrameworksResponse
    # Field: frameworks Type: 11 (.google.cloud.designcenter.v1.Framework)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::GetPolicyRequest ===
    # Fields for GetPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesRequest ===
    # Fields for ListPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesResponse ===
    # Fields for ListPoliciesResponse
    # Field: policies Type: 11 (.google.cloud.designcenter.v1.Policy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::CreatePolicyRequest ===
    # Fields for CreatePolicyRequest
    # Field: parent Type: 9 ()
    # Field: policy_id Type: 9 ()
    # Field: policy Type: 11 (.google.cloud.designcenter.v1.Policy)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::UpdatePolicyRequest ===
    # Fields for UpdatePolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: policy Type: 11 (.google.cloud.designcenter.v1.Policy)

# === Message: Google::Cloud::Designcenter::V1::BestPracticesMessages::DeletePolicyRequest ===
    # Fields for DeletePolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::BestPracticesMessages - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/best_practices_messages.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::BestPracticesMessages;

    my $msg = Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/best_practices_messages.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportRequest

Message for fetching an application assessment report.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The application name in the following format:
`projects/$project/locations/$location/spaces/$space/applications/$application`

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchApplicationAssessmentReportResponse

Message for response of fetching an application assessment report.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_report() >> / C<< $msg->assessment_report($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport>)

Assessment report for the application.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportRequest

Message for generating an application assessment report.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The application name in the following format:
`projects/$project/locations/$location/spaces/$space/applications/$application`

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationAssessmentReportResponse

Response for GenerateApplicationAssessmentReport.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_report() >> / C<< $msg->assessment_report($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport>)

Output only. Best practices by Design Assessment report

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportRequest

Message for generate assessment report application template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The application template name in the following format:
`projects/$project/locations/$location/spaces/$space/applicationTemplates/$applicationTemplate`

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. Deprecated: This field is no longer used since we moved to fast
plan assessment.

- This service account will be used to execute the preview
  process.
- The caller must have the 'iam.serviceAccounts.actAs' permission on this
  service account.
Format: projects/{PROJECT}/serviceAccounts/{EMAIL_ADDRESS}

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateApplicationTemplateAssessmentReportResponse

Response for GenerateAssessmentReport for application template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->preview() >> / C<< $msg->preview($value) >>

Type: C<Message> (L<Google::Cloud::Config::V1::Config::Preview>)

Deprecated: This field is no longer used since we moved to fast plan
assessment.
Infrastructure Manager preview.

=item * C<< $msg->assessment_report() >> / C<< $msg->assessment_report($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport>)

Best practices by Design Assessment report

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportRequest

Deprecated: Use GenerateTerraformPlanAssessmentReportRequest instead.

Message for the request to generate a best practice report for a given
Terraform plan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->terraform_plan() >> / C<< $msg->terraform_plan($value) >>

Type: C<Bytes>

Required. Terraform plan bytes.

=item * C<< $msg->additional_frameworks() >> / C<< $msg->additional_frameworks($value) >>

Type: C<String>

Optional. Additional Frameworks to run assessment against. If empty, run
against default frameworks. Frameworks refers to the policies.

=item * C<< $msg->space_name() >> / C<< $msg->space_name($value) >>

Type: C<String>

Required. The name of the space at which Generate Assessment Report is
called. Format: `projects/$project/locations/$location/spaces/$space`

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateAssessmentReportResponse

Deprecated: Use GenerateTerraformPlanAssessmentReportResponse instead.

Response for GenerateAssessmentReport.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_report() >> / C<< $msg->assessment_report($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport>)

Aggregated assessment report from all domains.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportRequest

Message for the request to generate a best practice report for a given
Terraform plan at the collection level.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The parent resource in which to generate the assessment report.
Format: projects/$project/locations/$location/spaces/$space

=item * C<< $msg->terraform_plan() >> / C<< $msg->terraform_plan($value) >>

Type: C<Bytes>

Required. The raw JSON representation of the generated Terraform plan,
provided as bytes.

=item * C<< $msg->additional_frameworks() >> / C<< $msg->additional_frameworks($value) >>

Type: C<String>

Optional. Additional Frameworks to run assessment against. If empty, run
against default frameworks. Frameworks refers to the policies.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GenerateTerraformPlanAssessmentReportResponse

Response for GenerateTerraformPlanAssessmentReport.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_report() >> / C<< $msg->assessment_report($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport>)

Aggregated assessment report from all domains.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksRequest

Request for FetchFrameworks rpc

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
Format: projects/{project}/locations/{location}

=item * C<< $msg->projects() >> / C<< $msg->projects($value) >>

Type: C<String>

Optional. Projects to fetch frameworks for.
Format: projects/{project}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive values are ignored. The presence of nextPageToken in the
response indicates that more results might be available.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, then retrieve the next batch of results from the
preceding call to this method. pageToken must be the value of nextPageToken
from the previous response. The values of other method parameters should be
identical to those in the previous call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter for frameworks list.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::FetchFrameworksResponse

Response for FetchFrameworks rpc

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->frameworks() >> / C<< $msg->frameworks($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Assessment::Framework>)

The list of frameworks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::GetPolicyRequest

Message for getting a policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The policy name in the following format:
`projects/$project/locations/$location/spaces/$space/applicationTemplates/$applicationTemplate/policies/$policy`

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesRequest

Message for requesting a list of policies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent application template from which policies are listed in
the following format:
`projects/$project/locations/$location/spaces/$space/applicationTemplates/$applicationTemplate`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive values are ignored. The presence of nextPageToken in the
response indicates that more results might be available.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, retrieve the next batch of results from the preceding
call to this method. pageToken must be the value of nextPageToken from the
previous response. The values of other method parameters should be
identical to those in the previous call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter that chooses which policies to return.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. How the results should be sorted.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::ListPoliciesResponse

Message for response to listing policies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policies() >> / C<< $msg->policies($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::Policy>)

A list of policies.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
nextPageToken is included. To get the next set of results, call this method
again using the value of nextPageToken as pageToken.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::CreatePolicyRequest

Message for creating a policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource in which to create the policy in the
following format:
`projects/$project/locations/$location/spaces/$space/applicationTemplates/$applicationTemplate`

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

Required. The ID of the policy to create.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::Policy>)

Required. The policy to create.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::UpdatePolicyRequest

Message for updating a policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The fields to overwrite in the policy update. The fields
specified in the update_mask are relative to the resource, not the full
request. A field will be overwritten if it is in the mask. If you don't
provide a mask, all fields are overwritten.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::Policy>)

Required. The policy to update.

=back

=head2 Google::Cloud::Designcenter::V1::BestPracticesMessages::DeletePolicyRequest

Message for deleting a policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The policy name in the following format:
`projects/$project/locations/$location/spaces/$space/applicationTemplates/$applicationTemplate/policies/$policy`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::BestPracticesMessages::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
