package Google::Cloud::Designcenter::V1::SharingMessages;

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
    eval { require Google::Cloud::Designcenter::V1::BestPractices };
    eval { require Google::Cloud::Designcenter::V1::Iac };
    eval { require Google::Cloud::Designcenter::V1::Sharing };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL3NoYXJpbmdfbWVzc2FnZXMucHJvdG8S
HGdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMWdvb2dsZS9jbG91ZC9kZXNp
Z25jZW50ZXIvdjEvYmVzdF9wcmFjdGljZXMucHJvdG8aJmdvb2dsZS9jbG91ZC9kZXNpZ25j
ZW50ZXIvdjEvaWFjLnByb3RvGipnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL3NoYXJp
bmcucHJvdG8itwEKEkNyZWF0ZVNoYXJlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpB
IxIhZGVzaWduY2VudGVyLmdvb2dsZWFwaXMuY29tL1NoYXJlUgZwYXJlbnQSHgoIc2hhcmVf
aWQYAiABKAlCA+BBAlIHc2hhcmVJZBI+CgVzaGFyZRgDIAEoCzIjLmdvb2dsZS5jbG91ZC5k
ZXNpZ25jZW50ZXIudjEuU2hhcmVCA+BBAlIFc2hhcmUivAEKEUxpc3RTaGFyZXNSZXF1ZXN0
EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFkZXNpZ25jZW50ZXIuZ29vZ2xlYXBpcy5jb20v
U2hhcmVSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFn
ZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SHgoIb3JkZXJfYnkYBCABKAlCA+BBAVIH
b3JkZXJCeSJ5ChJMaXN0U2hhcmVzUmVzcG9uc2USOwoGc2hhcmVzGAEgAygLMiMuZ29vZ2xl
LmNsb3VkLmRlc2lnbmNlbnRlci52MS5TaGFyZVIGc2hhcmVzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJQCg9HZXRTaGFyZVJlcXVlc3QSPQoEbmFtZRgBIAEo
CUIp4EEC+kEjCiFkZXNpZ25jZW50ZXIuZ29vZ2xlYXBpcy5jb20vU2hhcmVSBG5hbWUiUwoS
RGVsZXRlU2hhcmVSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohZGVzaWduY2VudGVy
Lmdvb2dsZWFwaXMuY29tL1NoYXJlUgRuYW1lIlEKEFN5bmNTaGFyZVJlcXVlc3QSPQoEbmFt
ZRgBIAEoCUIp4EEC+kEjCiFkZXNpZ25jZW50ZXIuZ29vZ2xlYXBpcy5jb20vU2hhcmVSBG5h
bWUiYgoYR2V0U2hhcmVkVGVtcGxhdGVSZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoq
ZGVzaWduY2VudGVyLmdvb2dsZWFwaXMuY29tL1NoYXJlZFRlbXBsYXRlUgRuYW1lIusBChpM
aXN0U2hhcmVkVGVtcGxhdGVzUmVxdWVzdBJKCgZwYXJlbnQYASABKAlCMuBBAvpBLBIqZGVz
aWduY2VudGVyLmdvb2dsZWFwaXMuY29tL1NoYXJlZFRlbXBsYXRlUgZwYXJlbnQSIAoJcGFn
ZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJ
cGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSAB
KAlCA+BBAVIHb3JkZXJCeSKeAQobTGlzdFNoYXJlZFRlbXBsYXRlc1Jlc3BvbnNlElcKEHNo
YXJlZF90ZW1wbGF0ZXMYASADKAsyLC5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlNo
YXJlZFRlbXBsYXRlUg9zaGFyZWRUZW1wbGF0ZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
Ug1uZXh0UGFnZVRva2VuInIKIEdldFNoYXJlZFRlbXBsYXRlUmV2aXNpb25SZXF1ZXN0Ek4K
BG5hbWUYASABKAlCOuBBAvpBNAoyZGVzaWduY2VudGVyLmdvb2dsZWFwaXMuY29tL1NoYXJl
ZFRlbXBsYXRlUmV2aXNpb25SBG5hbWUi+wEKIkxpc3RTaGFyZWRUZW1wbGF0ZVJldmlzaW9u
c1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6QTQSMmRlc2lnbmNlbnRlci5nb29nbGVh
cGlzLmNvbS9TaGFyZWRUZW1wbGF0ZVJldmlzaW9uUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIg
ASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2Vu
EhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIH
b3JkZXJCeSK/AQojTGlzdFNoYXJlZFRlbXBsYXRlUmV2aXNpb25zUmVzcG9uc2UScAoZc2hh
cmVkX3RlbXBsYXRlX3JldmlzaW9ucxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50
ZXIudjEuU2hhcmVkVGVtcGxhdGVSZXZpc2lvblIXc2hhcmVkVGVtcGxhdGVSZXZpc2lvbnMS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuInwKKkZldGNoU2hhcmVk
VGVtcGxhdGVSZXZpc2lvblRGU291cmNlUmVxdWVzdBJOCgRuYW1lGAEgASgJQjrgQQL6QTQK
MmRlc2lnbmNlbnRlci5nb29nbGVhcGlzLmNvbS9TaGFyZWRUZW1wbGF0ZVJldmlzaW9uUgRu
YW1lIsYBCitGZXRjaFNoYXJlZFRlbXBsYXRlUmV2aXNpb25URlNvdXJjZVJlc3BvbnNlEk4K
C3Jvb3RfbW9kdWxlGAEgASgLMi0uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5UZXJy
YWZvcm1Nb2R1bGVSCnJvb3RNb2R1bGUSRwoHbW9kdWxlcxgCIAMoCzItLmdvb2dsZS5jbG91
ZC5kZXNpZ25jZW50ZXIudjEuVGVycmFmb3JtTW9kdWxlUgdtb2R1bGVzIoQBCjJGZXRjaFNo
YXJlZFRlbXBsYXRlUmV2aXNpb25Bc3Nlc3NtZW50UmVwb3J0UmVxdWVzdBJOCgRuYW1lGAEg
ASgJQjrgQQL6QTQKMmRlc2lnbmNlbnRlci5nb29nbGVhcGlzLmNvbS9TaGFyZWRUZW1wbGF0
ZVJldmlzaW9uUgRuYW1lIpIBCjNGZXRjaFNoYXJlZFRlbXBsYXRlUmV2aXNpb25Bc3Nlc3Nt
ZW50UmVwb3J0UmVzcG9uc2USWwoRYXNzZXNzbWVudF9yZXBvcnQYASABKAsyLi5nb29nbGUu
Y2xvdWQuZGVzaWduY2VudGVyLnYxLkFzc2Vzc21lbnRSZXBvcnRSEGFzc2Vzc21lbnRSZXBv
cnRC2AEKIGNvbS5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxQgxTaGFyaW5nUHJvdG9Q
AVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9kZXNpZ25jZW50ZXIvYXBpdjEvZGVzaWduY2VudGVy
cGI7ZGVzaWduY2VudGVycGKqAhxHb29nbGUuQ2xvdWQuRGVzaWduQ2VudGVyLlYxygIcR29v
Z2xlXENsb3VkXERlc2lnbkNlbnRlclxWMeoCH0dvb2dsZTo6Q2xvdWQ6OkRlc2lnbkNlbnRl
cjo6VjFK6kgKBxIFDgCNAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACUKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADsKCQoCAwMSAxUAMAoJ
CgIDBBIDFgA0CggKAQgSAxgAOQoJCgIIJRIDGAA5CggKAQgSAxkAWwoJCgIICxIDGQBbCggK
AQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAOQoJCgII
ARIDHAA5CggKAQgSAx0AOQoJCgIIKRIDHQA5CggKAQgSAx4AOAoJCgIILRIDHgA4CjgKAgQA
EgQhAC8BGiwgTWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBzaGFyZSBvZiBhIGNhdGFsb2cuCgoK
CgMEAAESAyEIGgpKCgQEAAIAEgQjAigEGjwgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3Vy
Y2UgaW4gd2hpY2ggc2hhcmVzIGFyZSBjcmVhdGVkLgoKDAoFBAACAAUSAyMCCAoMCgUEAAIA
ARIDIwkPCgwKBQQAAgADEgMjEhMKDQoFBAACAAgSBCMUKAMKDwoIBAACAAicCAASAyQEKgoP
CgcEAAIACJ8IEgQlBCcFCjcKBAQAAgESAysCPxoqIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhl
IHNoYXJlIHRvIGNyZWF0ZS4KCgwKBQQAAgEFEgMrAggKDAoFBAACAQESAysJEQoMCgUEAAIB
AxIDKxQVCgwKBQQAAgEIEgMrFj4KDwoIBAACAQicCAASAysXPQotCgQEAAICEgMuAjsaICBS
ZXF1aXJlZC4gVGhlIHNoYXJlIHRvIGNyZWF0ZS4KCgwKBQQAAgIGEgMuAgcKDAoFBAACAgES
Ay4IDQoMCgUEAAICAxIDLhARCgwKBQQAAgIIEgMuEjoKDwoIBAACAgicCAASAy4TOQo2CgIE
ARIEMgBJARoqIE1lc3NhZ2UgZm9yIGxpc3Rpbmcgc2hhcmVzIG9mIGEgY2F0YWxvZy4KCgoK
AwQBARIDMggZClcKBAQBAgASBDQCOQQaSSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJj
ZSBmcm9tIHdoaWNoIGEgbGlzdCBvZiBzaGFyZXMgaXMgcmVxdWVzdGVkLgoKDAoFBAECAAUS
AzQCCAoMCgUEAQIAARIDNAkPCgwKBQQBAgADEgM0EhMKDQoFBAECAAgSBDQUOQMKDwoIBAEC
AAicCAASAzUEKgoPCgcEAQIACJ8IEgQ2BDgFCtgBCgQEAQIBEgM/Aj8aygEgT3B0aW9uYWwu
IFRoZSBtYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybiBmcm9tIHRoaXMgcmVx
dWVzdC4KIE5vbi1wb3NpdGl2ZQogIHZhbHVlcyBhcmUgaWdub3JlZC4gVGhlIHByZXNlbmNl
IG9mIG5leHRQYWdlVG9rZW4gaW4gdGhlIHJlc3BvbnNlCiAgaW5kaWNhdGVzIHRoYXQgbW9y
ZSByZXN1bHRzIG1pZ2h0IGJlIGF2YWlsYWJsZS4KCgwKBQQBAgEFEgM/AgcKDAoFBAECAQES
Az8IEQoMCgUEAQIBAxIDPxQVCgwKBQQBAgEIEgM/Fj4KDwoIBAECAQicCAASAz8XPQqaAgoE
BAECAhIDRQJBGowCIE9wdGlvbmFsLiBJZiBwcmVzZW50LCB0aGVuIHJldHJpZXZlIHRoZSBu
ZXh0IGJhdGNoIG9mIHJlc3VsdHMgZnJvbSB0aGUKIHByZWNlZGluZyBjYWxsIHRvIHRoaXMg
bWV0aG9kLiBwYWdlVG9rZW4gbXVzdCBiZSB0aGUgdmFsdWUgb2YgbmV4dFBhZ2VUb2tlbgog
ZnJvbSB0aGUgcHJldmlvdXMgcmVzcG9uc2UuIFRoZSB2YWx1ZXMgb2Ygb3RoZXIgbWV0aG9k
IHBhcmFtZXRlcnMgc2hvdWxkIGJlCiBpZGVudGljYWwgdG8gdGhvc2UgaW4gdGhlIHByZXZp
b3VzIGNhbGwuCgoMCgUEAQICBRIDRQIICgwKBQQBAgIBEgNFCRMKDAoFBAECAgMSA0UWFwoM
CgUEAQICCBIDRRhACg8KCAQBAgIInAgAEgNFGT8KOgoEBAECAxIDSAI/Gi0gT3B0aW9uYWwu
IEhvdyB0aGUgcmVzdWx0cyBzaG91bGQgYmUgc29ydGVkLgoKDAoFBAECAwUSA0gCCAoMCgUE
AQIDARIDSAkRCgwKBQQBAgMDEgNIFBUKDAoFBAECAwgSA0gWPgoPCggEAQIDCJwIABIDSBc9
CkIKAgQCEgRMAFQBGjYgTWVzc2FnZSBmb3IgcmVzcG9uc2UgdG8gbGlzdGluZyBzaGFyZXMg
b2YgYSBjYXRhbG9nLgoKCgoDBAIBEgNMCBoKIgoEBAICABIDTgIcGhUgVGhlIGxpc3Qgb2Yg
c2hhcmVzLgoKDAoFBAICAAQSA04CCgoMCgUEAgIABhIDTgsQCgwKBQQCAgABEgNOERcKDAoF
BAICAAMSA04aGwrdAQoEBAICARIDUwIdGs8BIElmIHRoZXJlIG1pZ2h0IGJlIG1vcmUgcmVz
dWx0cyB0aGFuIHRob3NlIGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBuZXh0
UGFnZVRva2VuIGlzIGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMs
IGNhbGwgdGhpcyBtZXRob2QKIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBuZXh0UGFnZVRv
a2VuIGFzIHBhZ2VUb2tlbi4KCgwKBQQCAgEFEgNTAggKDAoFBAICAQESA1MJGAoMCgUEAgIB
AxIDUxscCjcKAgQDEgRXAGABGisgTWVzc2FnZSBmb3IgZ2V0dGluZyBhIHNoYXJlIG9mIGEg
Y2F0YWxvZy4KCgoKAwQDARIDVwgXCpkBCgQEAwIAEgRaAl8EGooBIFJlcXVpcmVkLiBUaGUg
c2hhcmUgbmFtZSBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIGBwcm9qZWN0cy8kcHJvamVj
dC9sb2NhdGlvbnMvJGxvY2F0aW9uL3NwYWNlcy8kc3BhY2UvY2F0YWxvZ3MvJGNhdGFsb2cv
c2hhcmVzLyRzaGFyZWAKCgwKBQQDAgAFEgNaAggKDAoFBAMCAAESA1oJDQoMCgUEAwIAAxID
WhARCg0KBQQDAgAIEgRaEl8DCg8KCAQDAgAInAgAEgNbBCoKDwoHBAMCAAifCBIEXAReBQo4
CgIEBBIEYwBsARosIE1lc3NhZ2UgZm9yIGRlbGV0aW5nIGEgc2hhcmUgb2YgYSBjYXRhbG9n
LgoKCgoDBAQBEgNjCBoKmQEKBAQEAgASBGYCawQaigEgUmVxdWlyZWQuIFRoZSBzaGFyZSBu
YW1lIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogYHByb2plY3RzLyRwcm9qZWN0L2xvY2F0
aW9ucy8kbG9jYXRpb24vc3BhY2VzLyRzcGFjZS9jYXRhbG9ncy8kY2F0YWxvZy9zaGFyZXMv
JHNoYXJlYAoKDAoFBAQCAAUSA2YCCAoMCgUEBAIAARIDZgkNCgwKBQQEAgADEgNmEBEKDQoF
BAQCAAgSBGYSawMKDwoIBAQCAAicCAASA2cEKgoPCgcEBAIACJ8IEgRoBGoFCjcKAgQFEgRv
AHgBGisgTWVzc2FnZSBmb3Igc3luY2luZyBhIHNoYXJlIG9mIGEgY2F0YWxvZy4KCgoKAwQF
ARIDbwgYCpkBCgQEBQIAEgRyAncEGooBIFJlcXVpcmVkLiBUaGUgc2hhcmUgbmFtZSBpbiB0
aGUgZm9sbG93aW5nIGZvcm1hdDoKIGBwcm9qZWN0cy8kcHJvamVjdC9sb2NhdGlvbnMvJGxv
Y2F0aW9uL3NwYWNlcy8kc3BhY2UvY2F0YWxvZ3MvJGNhdGFsb2cvc2hhcmVzLyRzaGFyZWAK
CgwKBQQFAgAFEgNyAggKDAoFBAUCAAESA3IJDQoMCgUEBQIAAxIDchARCg0KBQQFAgAIEgRy
EncDCg8KCAQFAgAInAgAEgNzBCoKDwoHBAUCAAifCBIEdAR2BQo1CgIEBhIFewCFAQEaKCBN
ZXNzYWdlIGZvciBnZXR0aW5nIGEgc2hhcmVkIHRlbXBsYXRlLgoKCgoDBAYBEgN7CCAKlQEK
BAQGAgASBX8ChAEEGoUBIFJlcXVpcmVkLiBUaGUgc2hhcmVkIHRlbXBsYXRlIG5hbWUuCiBG
b3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMv
JHNwYWNlL3NoYXJlZFRlbXBsYXRlcy8kc2hhcmVkVGVtcGxhdGVgCgoMCgUEBgIABRIDfwII
CgwKBQQGAgABEgN/CQ0KDAoFBAYCAAMSA38QEQoOCgUEBgIACBIFfxKEAQMKEAoIBAYCAAic
CAASBIABBCoKEQoHBAYCAAifCBIGgQEEgwEFCkAKAgQHEgaIAQCiAQEaMiBNZXNzYWdlIGZv
ciByZXF1ZXN0aW5nIGxpc3Qgb2Ygc2hhcmVkIHRlbXBsYXRlcy4KCgsKAwQHARIEiAEIIgqj
AQoEBAcCABIGiwECkAEEGpIBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHNwYWNlIGZvciB3aGlj
aCBzaGFyZWQgdGVtcGxhdGVzIGFyZSBsaXN0ZWQgaW4gdGhlCiBmb2xsb3dpbmcgZm9ybWF0
OiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMvJHNwYWNl
YAoKDQoFBAcCAAUSBIsBAggKDQoFBAcCAAESBIsBCQ8KDQoFBAcCAAMSBIsBEhMKDwoFBAcC
AAgSBosBFJABAwoQCggEBwIACJwIABIEjAEEKgoRCgcEBwIACJ8IEgaNAQSPAQUK1gEKBAQH
AgESBJUBAj8axwEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRv
IHJldHVybiBmcm9tIHRoaXMgcmVxdWVzdC4KIE5vbi1wb3NpdGl2ZSB2YWx1ZXMgYXJlIGln
bm9yZWQuIFRoZSBwcmVzZW5jZSBvZiBuZXh0UGFnZVRva2VuIGluIHRoZQogcmVzcG9uc2Ug
aW5kaWNhdGVzIHRoYXQgbW9yZSByZXN1bHRzIG1pZ2h0IGJlIGF2YWlsYWJsZS4KCg0KBQQH
AgEFEgSVAQIHCg0KBQQHAgEBEgSVAQgRCg0KBQQHAgEDEgSVARQVCg0KBQQHAgEIEgSVARY+
ChAKCAQHAgEInAgAEgSVARc9CpsCCgQEBwICEgSbAQJBGowCIE9wdGlvbmFsLiBJZiBwcmVz
ZW50LCB0aGVuIHJldHJpZXZlIHRoZSBuZXh0IGJhdGNoIG9mIHJlc3VsdHMgZnJvbSB0aGUK
IHByZWNlZGluZyBjYWxsIHRvIHRoaXMgbWV0aG9kLiBwYWdlVG9rZW4gbXVzdCBiZSB0aGUg
dmFsdWUgb2YgbmV4dFBhZ2VUb2tlbgogZnJvbSB0aGUgcHJldmlvdXMgcmVzcG9uc2UuIFRo
ZSB2YWx1ZXMgb2Ygb3RoZXIgbWV0aG9kIHBhcmFtZXRlcnMgc2hvdWxkIGJlCiBpZGVudGlj
YWwgdG8gdGhvc2UgaW4gdGhlIHByZXZpb3VzIGNhbGwuCgoNCgUEBwICBRIEmwECCAoNCgUE
BwICARIEmwEJEwoNCgUEBwICAxIEmwEWFwoNCgUEBwICCBIEmwEYQAoQCggEBwICCJwIABIE
mwEZPwpRCgQEBwIDEgSeAQI9GkMgT3B0aW9uYWwuIEEgZmlsdGVyIHRoYXQgY2hvb3NlcyB3
aGljaCBzaGFyZWQgdGVtcGxhdGVzIHRvIHJldHVybi4KCg0KBQQHAgMFEgSeAQIICg0KBQQH
AgMBEgSeAQkPCg0KBQQHAgMDEgSeARITCg0KBQQHAgMIEgSeARQ8ChAKCAQHAgMInAgAEgSe
ARU7CjsKBAQHAgQSBKEBAj8aLSBPcHRpb25hbC4gSG93IHRoZSByZXN1bHRzIHNob3VsZCBi
ZSBzb3J0ZWQuCgoNCgUEBwIEBRIEoQECCAoNCgUEBwIEARIEoQEJEQoNCgUEBwIEAxIEoQEU
FQoNCgUEBwIECBIEoQEWPgoQCggEBwIECJwIABIEoQEXPQpBCgIECBIGpQEArQEBGjMgTWVz
c2FnZSBmb3IgcmVzcG9uc2UgdG8gbGlzdGluZyBzaGFyZWQgdGVtcGxhdGVzLgoKCwoDBAgB
EgSlAQgjCi0KBAQIAgASBKcBAi8aHyBUaGUgbGlzdCBvZiBzaGFyZWQgdGVtcGxhdGVzLgoK
DQoFBAgCAAQSBKcBAgoKDQoFBAgCAAYSBKcBCxkKDQoFBAgCAAESBKcBGioKDQoFBAgCAAMS
BKcBLS4K3gEKBAQIAgESBKwBAh0azwEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRz
IHRoYW4gdGhvc2UgYXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIG5leHRQYWdl
VG9rZW4gaXMgaW5jbHVkZWQuIFRvIGdldCB0aGUgbmV4dCBzZXQgb2YgcmVzdWx0cywgY2Fs
bCB0aGlzIG1ldGhvZAogYWdhaW4gdXNpbmcgdGhlIHZhbHVlIG9mIG5leHRQYWdlVG9rZW4g
YXMgcGFnZVRva2VuLgoKDQoFBAgCAQUSBKwBAggKDQoFBAgCAQESBKwBCRgKDQoFBAgCAQMS
BKwBGxwKQAoCBAkSBrABALkBARoyIE1lc3NhZ2UgZm9yIGdldHRpbmcgYSBzaGFyZWQgdGVt
cGxhdGUgcmV2aXNpb25zLgoKCwoDBAkBEgSwAQgoCsMBCgQECQIAEgazAQK4AQQasgEgUmVx
dWlyZWQuIFRoZSBzaGFyZWQgdGVtcGxhdGUgcmV2aXNpb24gbmFtZSwgaW4gdGhlIGZvbGxv
d2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9z
cGFjZXMvJHNwYWNlL3NoYXJlZFRlbXBsYXRlcy8kc2hhcmVkVGVtcGxhdGUvcmV2aXNpb25z
LyRyZXZpc2lvbmAKCg0KBQQJAgAFEgSzAQIICg0KBQQJAgABEgSzAQkNCg0KBQQJAgADEgSz
ARARCg8KBQQJAgAIEgazARK4AQMKEAoIBAkCAAicCAASBLQBBCoKEQoHBAkCAAifCBIGtQEE
twEFCksKAgQKEga8AQDYAQEaPSBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGEgbGlzdCBvZiBz
aGFyZWQgdGVtcGxhdGUgcmV2aXNpb25zLgoKCwoDBAoBEgS8AQgqCs8BCgQECgIAEgbAAQLF
AQQavgEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgZnJvbSB3aGljaCB0byBsaXN0
IHNoYXJlZCB0ZW1wbGF0ZSByZXZpc2lvbnMsCiBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoK
IGBwcm9qZWN0cy8kcHJvamVjdC9sb2NhdGlvbnMvJGxvY2F0aW9uL3NwYWNlcy8kc3BhY2Uv
c2hhcmVkVGVtcGxhdGVzLyRzaGFyZWRUZW1wbGF0ZWAKCg0KBQQKAgAFEgTAAQIICg0KBQQK
AgABEgTAAQkPCg0KBQQKAgADEgTAARITCg8KBQQKAgAIEgbAARTFAQMKEAoIBAoCAAicCAAS
BMEBBCoKEQoHBAoCAAifCBIGwgEExAEFCtkBCgQECgIBEgTLAQI/GsoBIE9wdGlvbmFsLiBU
aGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4gZnJvbSB0aGlzIHJlcXVl
c3QuCiBOb24tcG9zaXRpdmUKICB2YWx1ZXMgYXJlIGlnbm9yZWQuIFRoZSBwcmVzZW5jZSBv
ZiBuZXh0UGFnZVRva2VuIGluIHRoZSByZXNwb25zZQogIGluZGljYXRlcyB0aGF0IG1vcmUg
cmVzdWx0cyBtaWdodCBiZSBhdmFpbGFibGUuCgoNCgUECgIBBRIEywECBwoNCgUECgIBARIE
ywEIEQoNCgUECgIBAxIEywEUFQoNCgUECgIBCBIEywEWPgoQCggECgIBCJwIABIEywEXPQqb
AgoEBAoCAhIE0QECQRqMAiBPcHRpb25hbC4gSWYgcHJlc2VudCwgdGhlbiByZXRyaWV2ZSB0
aGUgbmV4dCBiYXRjaCBvZiByZXN1bHRzIGZyb20gdGhlCiBwcmVjZWRpbmcgY2FsbCB0byB0
aGlzIG1ldGhvZC4gcGFnZVRva2VuIG11c3QgYmUgdGhlIHZhbHVlIG9mIG5leHRQYWdlVG9r
ZW4KIGZyb20gdGhlIHByZXZpb3VzIHJlc3BvbnNlLiBUaGUgdmFsdWVzIG9mIG90aGVyIG1l
dGhvZCBwYXJhbWV0ZXJzIHNob3VsZCBiZQogaWRlbnRpY2FsIHRvIHRob3NlIGluIHRoZSBw
cmV2aW91cyBjYWxsLgoKDQoFBAoCAgUSBNEBAggKDQoFBAoCAgESBNEBCRMKDQoFBAoCAgMS
BNEBFhcKDQoFBAoCAggSBNEBGEAKEAoIBAoCAgicCAASBNEBGT8KWgoEBAoCAxIE1AECPRpM
IE9wdGlvbmFsLiBBIGZpbHRlciB0aGF0IGNob29zZXMgd2hpY2ggc2hhcmVkIHRlbXBsYXRl
IHJldmlzaW9ucyB0byByZXR1cm4uCgoNCgUECgIDBRIE1AECCAoNCgUECgIDARIE1AEJDwoN
CgUECgIDAxIE1AESEwoNCgUECgIDCBIE1AEUPAoQCggECgIDCJwIABIE1AEVOwo7CgQECgIE
EgTXAQI/Gi0gT3B0aW9uYWwuIEhvdyB0aGUgcmVzdWx0cyBzaG91bGQgYmUgc29ydGVkLgoK
DQoFBAoCBAUSBNcBAggKDQoFBAoCBAESBNcBCREKDQoFBAoCBAMSBNcBFBUKDQoFBAoCBAgS
BNcBFj4KEAoIBAoCBAicCAASBNcBFz0KQQoCBAsSBtsBAOMBARozIE1lc3NhZ2UgZm9yIHJl
c3BvbnNlIHRvIGxpc3Rpbmcgc2hhcmVkIHRlbXBsYXRlcy4KCgsKAwQLARIE2wEIKwotCgQE
CwIAEgTdAQJAGh8gVGhlIGxpc3Qgb2Ygc2hhcmVkIHRlbXBsYXRlcy4KCg0KBQQLAgAEEgTd
AQIKCg0KBQQLAgAGEgTdAQshCg0KBQQLAgABEgTdASI7Cg0KBQQLAgADEgTdAT4/Ct4BCgQE
CwIBEgTiAQIdGs8BIElmIHRoZXJlIG1pZ2h0IGJlIG1vcmUgcmVzdWx0cyB0aGFuIHRob3Nl
IGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBuZXh0UGFnZVRva2VuIGlzIGlu
Y2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcyBtZXRo
b2QKIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBuZXh0UGFnZVRva2VuIGFzIHBhZ2VUb2tl
bi4KCg0KBQQLAgEFEgTiAQIICg0KBQQLAgEBEgTiAQkYCg0KBQQLAgEDEgTiARscCmEKAgQM
EgbnAQDxAQEaUyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGZldGNoaW5nIHRoZSBUZXJyYWZvcm0g
c291cmNlIG9mIGEgc2hhcmVkIHRlbXBsYXRlCiByZXZpc2lvbi4KCgsKAwQMARIE5wEIMgqb
AQoEBAwCABIG6wEC8AEEGooBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZQogRWc6
CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMvJHNwYWNl
L3NoYXJlZFRlbXBsYXRlcy8kdGVtcGxhdGUvcmV2aXNpb25zLyRyZXZpc2lvbmAKCg0KBQQM
AgAFEgTrAQIICg0KBQQMAgABEgTrAQkNCg0KBQQMAgADEgTrARARCg8KBQQMAgAIEgbrARLw
AQMKEAoIBAwCAAicCAASBOwBBCoKEQoHBAwCAAifCBIG7QEE7wEFCmEKAgQNEgb1AQD7AQEa
UyBSZXNwb25zZSBtZXNzYWdlIGZvciBnZXR0aW5nIHRoZSBUZXJyYWZvcm0gc291cmNlIG9m
IGEgc2hhcmVkIHRlbXBsYXRlCiByZXZpc2lvbi4KCgsKAwQNARIE9QEIMwpLCgQEDQIAEgT3
AQIiGj0gVGhlIHJvb3QgVGVycmFmb3JtIG1vZHVsZSBvZiB0aGUgY2F0YWxvZyB0ZW1wbGF0
ZSByZXZpc2lvbi4KCg0KBQQNAgAGEgT3AQIRCg0KBQQNAgABEgT3ARIdCg0KBQQNAgADEgT3
ASAhCkgKBAQNAgESBPoBAicaOiBUaGUgZGVwZW5kZW50IFRlcnJhZm9ybSBtb2R1bGVzIHVz
ZWQgYnkgdGhlIHJvb3QgbW9kdWxlLgoKDQoFBA0CAQQSBPoBAgoKDQoFBA0CAQYSBPoBCxoK
DQoFBA0CAQESBPoBGyIKDQoFBA0CAQMSBPoBJSYKUAoCBA4SBv4BAIcCARpCIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgRmV0Y2hTaGFyZWRUZW1wbGF0ZVJldmlzaW9uQXNzZXNzbWVudFJlcG9y
dC4KCgsKAwQOARIE/gEIOgrIAQoEBA4CABIGgQIChgIEGrcBIFJlcXVpcmVkLiBUaGUgc2hh
cmVkIHRlbXBsYXRlIHJldmlzaW9uIG5hbWUgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NwYWNlcy97c3BhY2V9
L3NoYXJlZFRlbXBsYXRlcy97c2hhcmVkX3RlbXBsYXRlfS9yZXZpc2lvbnMve3JldmlzaW9u
fWAKCg0KBQQOAgAFEgSBAgIICg0KBQQOAgABEgSBAgkNCg0KBQQOAgADEgSBAhARCg8KBQQO
AgAIEgaBAhKGAgMKEAoIBA4CAAicCAASBIICBCoKEQoHBA4CAAifCBIGgwIEhQIFClEKAgQP
EgaKAgCNAgEaQyBSZXNwb25zZSBtZXNzYWdlIGZvciBGZXRjaFNoYXJlZFRlbXBsYXRlUmV2
aXNpb25Bc3Nlc3NtZW50UmVwb3J0LgoKCwoDBA8BEgSKAgg7CkMKBAQPAgASBIwCAikaNSBB
c3Nlc3NtZW50IHJlcG9ydCBmb3IgdGhlIHNoYXJlZCB0ZW1wbGF0ZSByZXZpc2lvbi4KCg0K
BQQPAgAGEgSMAgISCg0KBQQPAgABEgSMAhMkCg0KBQQPAgADEgSMAicoYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest ===
    # Fields for CreateShareRequest
    # Field: parent Type: 9 ()
    # Field: share_id Type: 9 ()
    # Field: share Type: 11 (.google.cloud.designcenter.v1.Share)

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::ListSharesRequest ===
    # Fields for ListSharesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::ListSharesResponse ===
    # Fields for ListSharesResponse
    # Field: shares Type: 11 (.google.cloud.designcenter.v1.Share)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::GetShareRequest ===
    # Fields for GetShareRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::DeleteShareRequest ===
    # Fields for DeleteShareRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::SyncShareRequest ===
    # Fields for SyncShareRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRequest ===
    # Fields for GetSharedTemplateRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesRequest ===
    # Fields for ListSharedTemplatesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesResponse ===
    # Fields for ListSharedTemplatesResponse
    # Field: shared_templates Type: 11 (.google.cloud.designcenter.v1.SharedTemplate)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRevisionRequest ===
    # Fields for GetSharedTemplateRevisionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsRequest ===
    # Fields for ListSharedTemplateRevisionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsResponse ===
    # Fields for ListSharedTemplateRevisionsResponse
    # Field: shared_template_revisions Type: 11 (.google.cloud.designcenter.v1.SharedTemplateRevision)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceRequest ===
    # Fields for FetchSharedTemplateRevisionTFSourceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceResponse ===
    # Fields for FetchSharedTemplateRevisionTFSourceResponse
    # Field: root_module Type: 11 (.google.cloud.designcenter.v1.TerraformModule)
    # Field: modules Type: 11 (.google.cloud.designcenter.v1.TerraformModule)

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportRequest ===
    # Fields for FetchSharedTemplateRevisionAssessmentReportRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportResponse ===
    # Fields for FetchSharedTemplateRevisionAssessmentReportResponse
    # Field: assessment_report Type: 11 (.google.cloud.designcenter.v1.AssessmentReport)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::SharingMessages - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/sharing_messages.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::SharingMessages;

    my $msg = Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest->new({
        parent => $parent,
        share_id => $share_id,
        share => $share,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/sharing_messages.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest

Message for creating a share of a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource in which shares are created.

=item * C<< $msg->share_id() >> / C<< $msg->share_id($value) >>

Type: C<String>

Required. The ID of the share to create.

=item * C<< $msg->share() >> / C<< $msg->share($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Sharing::Share>)

Required. The share to create.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::ListSharesRequest

Message for listing shares of a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource from which a list of shares is requested.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive
 values are ignored. The presence of nextPageToken in the response
 indicates that more results might be available.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, then retrieve the next batch of results from the
preceding call to this method. pageToken must be the value of nextPageToken
from the previous response. The values of other method parameters should be
identical to those in the previous call.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. How the results should be sorted.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::ListSharesResponse

Message for response to listing shares of a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->shares() >> / C<< $msg->shares($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Sharing::Share>)

The list of shares.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
nextPageToken is included. To get the next set of results, call this method
again using the value of nextPageToken as pageToken.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::GetShareRequest

Message for getting a share of a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The share name in the following format:
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog/shares/$share`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::DeleteShareRequest

Message for deleting a share of a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The share name in the following format:
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog/shares/$share`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::SyncShareRequest

Message for syncing a share of a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The share name in the following format:
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog/shares/$share`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRequest

Message for getting a shared template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The shared template name.
Format:
`projects/$project/locations/$location/spaces/$space/sharedTemplates/$sharedTemplate`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesRequest

Message for requesting list of shared templates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent space for which shared templates are listed in the
following format: `projects/$project/locations/$location/spaces/$space`

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

Optional. A filter that chooses which shared templates to return.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. How the results should be sorted.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesResponse

Message for response to listing shared templates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->shared_templates() >> / C<< $msg->shared_templates($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Sharing::SharedTemplate>)

The list of shared templates.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
nextPageToken is included. To get the next set of results, call this method
again using the value of nextPageToken as pageToken.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRevisionRequest

Message for getting a shared template revisions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The shared template revision name, in the following format:
`projects/$project/locations/$location/spaces/$space/sharedTemplates/$sharedTemplate/revisions/$revision`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsRequest

Message for requesting a list of shared template revisions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource from which to list shared template revisions,
in the following format:
`projects/$project/locations/$location/spaces/$space/sharedTemplates/$sharedTemplate`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive
 values are ignored. The presence of nextPageToken in the response
 indicates that more results might be available.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, then retrieve the next batch of results from the
preceding call to this method. pageToken must be the value of nextPageToken
from the previous response. The values of other method parameters should be
identical to those in the previous call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter that chooses which shared template revisions to return.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. How the results should be sorted.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsResponse

Message for response to listing shared templates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->shared_template_revisions() >> / C<< $msg->shared_template_revisions($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision>)

The list of shared templates.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
nextPageToken is included. To get the next set of results, call this method
again using the value of nextPageToken as pageToken.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceRequest

Request message for fetching the Terraform source of a shared template
revision.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource
Eg:
`projects/$project/locations/$location/spaces/$space/sharedTemplates/$template/revisions/$revision`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceResponse

Response message for getting the Terraform source of a shared template
revision.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->root_module() >> / C<< $msg->root_module($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::TerraformModule>)

The root Terraform module of the catalog template revision.

=item * C<< $msg->modules() >> / C<< $msg->modules($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::TerraformModule>)

The dependent Terraform modules used by the root module.

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportRequest

Request message for FetchSharedTemplateRevisionAssessmentReport.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The shared template revision name in the following format:
`projects/{project}/locations/{location}/spaces/{space}/sharedTemplates/{shared_template}/revisions/{revision}`

=back

=head2 Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportResponse

Response message for FetchSharedTemplateRevisionAssessmentReport.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_report() >> / C<< $msg->assessment_report($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport>)

Assessment report for the shared template revision.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::SharingMessages::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
