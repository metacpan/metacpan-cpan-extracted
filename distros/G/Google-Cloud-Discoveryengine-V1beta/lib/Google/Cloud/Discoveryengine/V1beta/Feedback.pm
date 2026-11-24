package Google::Cloud::Discoveryengine::V1beta::Feedback;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Discoveryengine::V1beta::Session };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9mZWVkYmFjay5wcm90bxIj
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aMWdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL3Nl
c3Npb24ucHJvdG8iiwoKCEZlZWRiYWNrEmQKDWZlZWRiYWNrX3R5cGUYASABKA4yOi5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5GZWVkYmFjay5GZWVkYmFja1R5cGVC
A+BBAlIMZmVlZGJhY2tUeXBlElMKB3JlYXNvbnMYAiADKA4yNC5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5GZWVkYmFjay5SZWFzb25CA+BBAVIHcmVhc29ucxIdCgdj
b21tZW50GAMgASgJQgPgQQFSB2NvbW1lbnQSawoRY29udmVyc2F0aW9uX2luZm8YBCABKAsy
Pi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5GZWVkYmFjay5Db252ZXJz
YXRpb25JbmZvUhBjb252ZXJzYXRpb25JbmZvEioKEWxsbV9tb2RlbF92ZXJzaW9uGAUgASgJ
Ug9sbG1Nb2RlbFZlcnNpb24SagoPZmVlZGJhY2tfc291cmNlGAYgASgOMjwuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRmVlZGJhY2suRmVlZGJhY2tTb3VyY2VCA+BB
AVIOZmVlZGJhY2tTb3VyY2USMAoRY29tcG9uZW50X3ZlcnNpb24YByABKAlCA+BBAVIQY29t
cG9uZW50VmVyc2lvbhIzChNkYXRhX3Rlcm1zX2FjY2VwdGVkGAggASgIQgPgQQFSEWRhdGFU
ZXJtc0FjY2VwdGVkGvUBChBDb252ZXJzYXRpb25JbmZvEiUKDnF1ZXN0aW9uX2luZGV4GAEg
ASgFUg1xdWVzdGlvbkluZGV4EhgKB3Nlc3Npb24YAiABKAlSB3Nlc3Npb24SRQoFcXVlcnkY
AyABKAsyKi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5RdWVyeUID4EEC
UgVxdWVyeRImCgxhc3Npc3RfdG9rZW4YBCABKAlCA+BBAVILYXNzaXN0VG9rZW4SMQoSYW5z
d2VyX3F1ZXJ5X3Rva2VuGAUgASgJQgPgQQFSEGFuc3dlclF1ZXJ5VG9rZW4iRAoMRmVlZGJh
Y2tUeXBlEh0KGUZFRURCQUNLX1RZUEVfVU5TUEVDSUZJRUQQABIICgRMSUtFEAESCwoHRElT
TElLRRACIu4BCgZSZWFzb24SFgoSUkVBU09OX1VOU1BFQ0lGSUVEEAASFwoTSU5BQ0NVUkFU
RV9SRVNQT05TRRABEhAKDE5PVF9SRUxFVkFOVBACEhMKD0lOQ09NUFJFSEVOU0lWRRADEhcK
E09GRkVOU0lWRV9PUl9VTlNBRkUQBBIVChFGT1JNQVRfQU5EX1NUWUxFUxAGEhAKDEJBRF9D
SVRBVElPThAHEhgKFENBTlZBU19OT1RfR0VORVJBVEVEEAgSFgoSQ0FOVkFTX1FVQUxJVFlf
QkFEEAkSGAoUQ0FOVkFTX0VYUE9SVF9GQUlMRUQQCiKJAQoORmVlZGJhY2tTb3VyY2USHwob
RkVFREJBQ0tfU09VUkNFX1VOU1BFQ0lGSUVEEAASEgoOR09PR0xFX0NPTlNPTEUQARIRCg1H
T09HTEVfV0lER0VUEAISEQoNR09PR0xFX1dFQkFQUBADEhwKGEdPT0dMRV9BR0VOVFNQQUNF
X01PQklMRRAEQpQCCidjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFC
DUZlZWRiYWNrUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUv
YXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09W
RVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29n
bGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2Nv
dmVyeUVuZ2luZTo6VjFiZXRhSv0mCgcSBQ4AjwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAOwoICgEIEgMVAEAK
CQoCCCUSAxUAQAoICgEIEgMWAGgKCQoCCAsSAxYAaAoICgEIEgMXACIKCQoCCAoSAxcAIgoI
CgEIEgMYAC4KCQoCCAgSAxgALgoICgEIEgMZAEAKCQoCCAESAxkAQAoICgEIEgMaAC0KCQoC
CCQSAxoALQoICgEIEgMbAEAKCQoCCCkSAxsAQAoICgEIEgMcAD8KCQoCCC0SAxwAPwpzCgIE
ABIFIACPAQEaZiBJbmZvcm1hdGlvbiBhYm91dCB0aGUgdXNlciBmZWVkYmFjay4gVGhpcyBp
bmZvcm1hdGlvbiB3aWxsIGJlIHVzZWQgZm9yCiBsb2dnaW5nIGFuZCBtZXRyaWNzIHB1cnBv
c2UuCgoKCgMEAAESAyAIEApZCgQEAAMAEgQiAjEDGksgVGhlIGNvbnZlcnNhdGlvbiBpbmZv
cm1hdGlvbiBzdWNoIGFzIHRoZSBxdWVzdGlvbiBpbmRleCBhbmQgc2Vzc2lvbiBuYW1lLgoK
DAoFBAADAAESAyIKGgpOCgYEAAMAAgASAyQEHRo/IFRoZSBpbmRleCBvZiB0aGUgdXNlciBp
bnB1dCB3aXRoaW4gdGhlIGNvbnZlcnNhdGlvbiBtZXNzYWdlcy4KCg4KBwQAAwACAAUSAyQE
CQoOCgcEAAMAAgABEgMkChgKDgoHBAADAAIAAxIDJBscCkIKBgQAAwACARIDJwQXGjMgTmFt
ZSBvZiB0aGUgbmV3bHkgZ2VuZXJhdGVkIG9yIGNvbnRpbnVlZCBzZXNzaW9uLgoKDgoHBAAD
AAIBBRIDJwQKCg4KBwQAAwACAQESAycLEgoOCgcEAAMAAgEDEgMnFRYKMwoGBAADAAICEgMq
BD0aJCBSZXF1aXJlZC4gVGhlIHVzZXIncyBzZWFyY2ggcXVlcnkuCgoOCgcEAAMAAgIGEgMq
BAkKDgoHBAADAAICARIDKgoPCg4KBwQAAwACAgMSAyoSEwoOCgcEAAMAAgIIEgMqFDwKEQoK
BAADAAICCJwIABIDKhU7ClQKBgQAAwACAxIDLQRFGkUgT3B0aW9uYWwuIFRoZSB0b2tlbiB3
aGljaCBjb3VsZCBiZSB1c2VkIHRvIGZldGNoIHRoZSBhc3Npc3RhbnQgbG9nLgoKDgoHBAAD
AAIDBRIDLQQKCg4KBwQAAwACAwESAy0LFwoOCgcEAAMAAgMDEgMtGhsKDgoHBAADAAIDCBID
LRxEChEKCgQAAwACAwicCAASAy0dQwpRCgYEAAMAAgQSAzAESxpCIE9wdGlvbmFsLiBUaGUg
dG9rZW4gd2hpY2ggY291bGQgYmUgdXNlZCB0byBmZXRjaCB0aGUgYW5zd2VyIGxvZy4KCg4K
BwQAAwACBAUSAzAECgoOCgcEAAMAAgQBEgMwCx0KDgoHBAADAAIEAxIDMCAhCg4KBwQAAwAC
BAgSAzAiSgoRCgoEAAMAAgQInAgAEgMwI0kKNAoEBAAEABIENAI9AxomIFRoZSB0eXBlIG9m
IHRoZSBmZWVkYmFjayB1c2VyIGdpdmVzLgoKDAoFBAAEAAESAzQHEworCgYEAAQAAgASAzYE
IhocIFVuc3BlY2lmaWVkIGZlZWRiYWNrIHR5cGUuCgoOCgcEAAQAAgABEgM2BB0KDgoHBAAE
AAIAAhIDNiAhCjQKBgQABAACARIDOQQNGiUgVGhlIHVzZXIgZ2l2ZXMgYSBwb3NpdGl2ZSBm
ZWVkYmFjay4KCg4KBwQABAACAQESAzkECAoOCgcEAAQAAgECEgM5CwwKNAoGBAAEAAICEgM8
BBAaJSBUaGUgdXNlciBnaXZlcyBhIG5lZ2F0aXZlIGZlZWRiYWNrLgoKDgoHBAAEAAICARID
PAQLCg4KBwQABAACAgISAzwODwo+CgQEAAQBEgRAAmADGjAgVGhlIHJlYXNvbiB3aHkgdXNl
ciBnaXZlcyBhIG5lZ2F0aXZlIGZlZWRiYWNrLgoKDAoFBAAEAQESA0AHDQokCgYEAAQBAgAS
A0IEGxoVIFVuc3BlY2lmaWVkIHJlYXNvbi4KCg4KBwQABAECAAESA0IEFgoOCgcEAAQBAgAC
EgNCGRoKLAoGBAAEAQIBEgNFBBwaHSBUaGUgcmVzcG9uc2UgaXMgaW5hY2N1cmF0ZS4KCg4K
BwQABAECAQESA0UEFwoOCgcEAAQBAgECEgNFGhsKLgoGBAAEAQICEgNIBBUaHyBUaGUgcmVz
cG9uc2UgaXMgbm90IHJlbGV2YW50LgoKDgoHBAAEAQICARIDSAQQCg4KBwQABAECAgISA0gT
FAoxCgYEAAQBAgMSA0sEGBoiIFRoZSByZXNwb25zZSBpcyBpbmNvbXByZWhlbnNpdmUuCgoO
CgcEAAQBAgMBEgNLBBMKDgoHBAAEAQIDAhIDSxYXCjUKBgQABAECBBIDTgQcGiYgVGhlIHJl
c3BvbnNlIGlzIG9mZmVuc2l2ZSBvciB1bnNhZmUuCgoOCgcEAAQBAgQBEgNOBBcKDgoHBAAE
AQIEAhIDThobCjQKBgQABAECBRIDUQQaGiUgVGhlIHJlc3BvbnNlIGlzIG5vdCB3ZWxsLWZv
cm1hdHRlZC4KCg4KBwQABAECBQESA1EEFQoOCgcEAAQBAgUCEgNRGBkKRAoGBAAEAQIGEgNU
BBUaNSBUaGUgcmVzcG9uc2UgaXMgbm90IHdlbGwtYXNzb2NpYXRlZCB3aXRoIHRoZSBxdWVy
eS4KCg4KBwQABAECBgESA1QEEAoOCgcEAAQBAgYCEgNUExQKSAoGBAAEAQIHEgNXBB0aOSBU
aGUgZXhwZWN0ZWQgY2FudmFzIHdhcyBub3QgZ2VuZXJhdGVkIGZvciB0aGUgcmVzcG9uc2Uu
CgoOCgcEAAQBAgcBEgNXBBgKDgoHBAAEAQIHAhIDVxscCmkKBgQABAECCBIDWwQbGlogVGhl
IGdlbmVyYXRlZCBjYW52YXMgaXMgb2YgYmFkIHF1YWxpdHkgKGUuZy4gaW5hY2N1cmF0ZSwg
aW5jb21wbGV0ZSwKIHBvb3JseSBmb3JtYXR0ZWQpLgoKDgoHBAAEAQIIARIDWwQWCg4KBwQA
BAECCAISA1sZGgqAAQoGBAAEAQIJEgNfBB4acSBFeHBvcnRpbmcgdGhlIGdlbmVyYXRlZCBj
YW52YXMgZmFpbGVkIChlLmcuIGRvd25sb2FkIG9yIGV4dGVybmFsCiBleHBvcnQgYWN0aW9u
IGRpZCBub3QgY29tcGxldGUgc3VjY2Vzc2Z1bGx5KS4KCg4KBwQABAECCQESA18EGAoOCgcE
AAQBAgkCEgNfGx0KOgoEBAAEAhIEYwJyAxosIFNvdXJjZSBvZiB0aGUgZmVlZGJhY2sgYXMg
cGVyIGludGVncmF0aW9uLgoKDAoFBAAEAgESA2MHFQotCgYEAAQCAgASA2UEJBoeIFVuc3Bl
Y2lmaWVkIGZlZWRiYWNrIHNvdXJjZS4KCg4KBwQABAICAAESA2UEHwoOCgcEAAQCAgACEgNl
IiMKMwoGBAAEAgIBEgNoBBcaJCBGZWVkYmFjayBzb3VyY2UgaXMgR29vZ2xlIENvbnNvbGUu
CgoOCgcEAAQCAgEBEgNoBBIKDgoHBAAEAgIBAhIDaBUWCjIKBgQABAICAhIDawQWGiMgRmVl
ZGJhY2sgc291cmNlIGlzIEdvb2dsZSBXaWRnZXQuCgoOCgcEAAQCAgIBEgNrBBEKDgoHBAAE
AgICAhIDaxQVCjIKBgQABAICAxIDbgQWGiMgRmVlZGJhY2sgc291cmNlIGlzIEdvb2dsZSBX
ZWJhcHAuCgoOCgcEAAQCAgMBEgNuBBEKDgoHBAAEAgIDAhIDbhQVCkEKBgQABAICBBIDcQQh
GjIgRmVlZGJhY2sgc291cmNlIGlzIEdvb2dsZSBBZ2VudFNwYWNlIE1vYmlsZSBhcHAuCgoO
CgcEAAQCAgQBEgNxBBwKDgoHBAAEAgIEAhIDcR8gCqkBCgQEAAIAEgN3AkoamwEgUmVxdWly
ZWQuIEluZGljYXRlIHdoZXRoZXIgdGhlIHVzZXIgZ2l2ZXMgYSBwb3NpdGl2ZSBvciBuZWdh
dGl2ZSBmZWVkYmFjay4KIElmIHRoZSB1c2VyIGdpdmVzIGEgbmVnYXRpdmUgZmVlZGJhY2ss
IHRoZXJlIG1pZ2h0IGJlIG1vcmUgZmVlZGJhY2sKIGRldGFpbHMuCgoMCgUEAAIABhIDdwIO
CgwKBQQAAgABEgN3DxwKDAoFBAACAAMSA3cfIAoMCgUEAAIACBIDdyFJCg8KCAQAAgAInAgA
EgN3IkgKPwoEBAACARIDegJHGjIgT3B0aW9uYWwuIFRoZSByZWFzb24gaWYgdXNlciBnaXZl
cyBhIHRodW1iIGRvd24uCgoMCgUEAAIBBBIDegIKCgwKBQQAAgEGEgN6CxEKDAoFBAACAQES
A3oSGQoMCgUEAAIBAxIDehwdCgwKBQQAAgEIEgN6HkYKDwoIBAACAQicCAASA3ofRQphCgQE
AAICEgN+Aj4aVCBPcHRpb25hbC4gVGhlIGFkZGl0aW9uYWwgdXNlciBjb21tZW50IG9mIHRo
ZSBmZWVkYmFjayBpZiB1c2VyIGdpdmVzIGEgdGh1bWIKIGRvd24uCgoMCgUEAAICBRIDfgII
CgwKBQQAAgIBEgN+CRAKDAoFBAACAgMSA34TFAoMCgUEAAICCBIDfhU9Cg8KCAQAAgIInAgA
EgN+FjwKTgoEBAACAxIEgQECKRpAIFRoZSByZWxhdGVkIGNvbnZlcnNhdGlvbiBpbmZvcm1h
dGlvbiB3aGVuIHVzZXIgZ2l2ZXMgZmVlZGJhY2suCgoNCgUEAAIDBhIEgQECEgoNCgUEAAID
ARIEgQETJAoNCgUEAAIDAxIEgQEnKApUCgQEAAIEEgSEAQIfGkYgVGhlIHZlcnNpb24gb2Yg
dGhlIExMTSBtb2RlbCB0aGF0IHdhcyB1c2VkIHRvIGdlbmVyYXRlIHRoZSByZXNwb25zZS4K
Cg0KBQQAAgQFEgSEAQIICg0KBQQAAgQBEgSEAQkaCg0KBQQAAgQDEgSEAR0eCoYBCgQEAAIF
EgSIAQJOGnggT3B0aW9uYWwuIFRoZSBVSSBjb21wb25lbnQgdGhlIHVzZXIgZmVlZGJhY2sg
Y29tZXMgZnJvbSwgd2hpY2ggY291bGQgYmUKIEdPT0dMRV9DT05TT0xFLCBHT09HTEVfV0lE
R0VULCBHT09HTEVfV0VCQVBQLgoKDQoFBAACBQYSBIgBAhAKDQoFBAACBQESBIgBESAKDQoF
BAACBQMSBIgBIyQKDQoFBAACBQgSBIgBJU0KEAoIBAACBQicCAASBIgBJkwKWwoEBAACBhIE
iwECSBpNIE9wdGlvbmFsLiBUaGUgdmVyc2lvbiBvZiB0aGUgY29tcG9uZW50IHRoYXQgdGhp
cyByZXBvcnQgaXMgYmVpbmcgc2VudCBmcm9tLgoKDQoFBAACBgUSBIsBAggKDQoFBAACBgES
BIsBCRoKDQoFBAACBgMSBIsBHR4KDQoFBAACBggSBIsBH0cKEAoIBAACBgicCAASBIsBIEYK
RwoEBAACBxIEjgECSBo5IE9wdGlvbmFsLiBXaGV0aGVyIHRoZSBjdXN0b21lciBhY2NlcHRl
ZCBkYXRhIHVzZSB0ZXJtcy4KCg0KBQQAAgcFEgSOAQIGCg0KBQQAAgcBEgSOAQcaCg0KBQQA
AgcDEgSOAR0eCg0KBQQAAgcIEgSOAR9HChAKCAQAAgcInAgAEgSOASBGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Feedback::Feedback ===
    # Fields for Feedback
    # Field: feedback_type Type: 14 (.google.cloud.discoveryengine.v1beta.Feedback.FeedbackType)
    # Field: reasons Type: 14 (.google.cloud.discoveryengine.v1beta.Feedback.Reason)
    # Field: comment Type: 9 ()
    # Field: conversation_info Type: 11 (.google.cloud.discoveryengine.v1beta.Feedback.ConversationInfo)
    # Field: llm_model_version Type: 9 ()
    # Field: feedback_source Type: 14 (.google.cloud.discoveryengine.v1beta.Feedback.FeedbackSource)
    # Field: component_version Type: 9 ()
    # Field: data_terms_accepted Type: 8 ()

# Enum: Feedback::FeedbackType
our $Feedback_FEEDBACK_TYPE_UNSPECIFIED = 0;
our $Feedback_LIKE = 1;
our $Feedback_DISLIKE = 2;

# Enum: Feedback::Reason
our $Feedback_REASON_UNSPECIFIED = 0;
our $Feedback_INACCURATE_RESPONSE = 1;
our $Feedback_NOT_RELEVANT = 2;
our $Feedback_INCOMPREHENSIVE = 3;
our $Feedback_OFFENSIVE_OR_UNSAFE = 4;
our $Feedback_FORMAT_AND_STYLES = 6;
our $Feedback_BAD_CITATION = 7;
our $Feedback_CANVAS_NOT_GENERATED = 8;
our $Feedback_CANVAS_QUALITY_BAD = 9;
our $Feedback_CANVAS_EXPORT_FAILED = 10;

# Enum: Feedback::FeedbackSource
our $Feedback_FEEDBACK_SOURCE_UNSPECIFIED = 0;
our $Feedback_GOOGLE_CONSOLE = 1;
our $Feedback_GOOGLE_WIDGET = 2;
our $Feedback_GOOGLE_WEBAPP = 3;
our $Feedback_GOOGLE_AGENTSPACE_MOBILE = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Feedback - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/feedback.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Feedback;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Feedback::Feedback->new({
        feedback_type => $feedback_type,
        reasons => $reasons,
        comment => $comment,
        conversation_info => $conversation_info,
    });

    # Read or update a field
    my $val = $msg->feedback_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Feedback::Feedback->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/feedback.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Feedback::Feedback

Information about the user feedback. This information will be used for
logging and metrics purpose.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->feedback_type() >> / C<< $msg->feedback_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::Feedback::FeedbackType>)

Required. Indicate whether the user gives a positive or negative feedback.
If the user gives a negative feedback, there might be more feedback
details.

=item * C<< $msg->reasons() >> / C<< $msg->reasons($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::Feedback::Reason>)

Optional. The reason if user gives a thumb down.

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<String>

Optional. The additional user comment of the feedback if user gives a thumb
down.

=item * C<< $msg->conversation_info() >> / C<< $msg->conversation_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Feedback::Feedback::ConversationInfo>)

The related conversation information when user gives feedback.

=item * C<< $msg->llm_model_version() >> / C<< $msg->llm_model_version($value) >>

Type: C<String>

The version of the LLM model that was used to generate the response.

=item * C<< $msg->feedback_source() >> / C<< $msg->feedback_source($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::Feedback::FeedbackSource>)

Optional. The UI component the user feedback comes from, which could be
GOOGLE_CONSOLE, GOOGLE_WIDGET, GOOGLE_WEBAPP.

=item * C<< $msg->component_version() >> / C<< $msg->component_version($value) >>

Type: C<String>

Optional. The version of the component that this report is being sent from.

=item * C<< $msg->data_terms_accepted() >> / C<< $msg->data_terms_accepted($value) >>

Type: C<Bool>

Optional. Whether the customer accepted data use terms.

=back

=head3 Enum: Feedback::FeedbackType

=over 4

=item * C<FEEDBACK_TYPE_UNSPECIFIED> => C<0>

=item * C<LIKE> => C<1>

=item * C<DISLIKE> => C<2>

=back

=head3 Enum: Feedback::Reason

=over 4

=item * C<REASON_UNSPECIFIED> => C<0>

=item * C<INACCURATE_RESPONSE> => C<1>

=item * C<NOT_RELEVANT> => C<2>

=item * C<INCOMPREHENSIVE> => C<3>

=item * C<OFFENSIVE_OR_UNSAFE> => C<4>

=item * C<FORMAT_AND_STYLES> => C<6>

=item * C<BAD_CITATION> => C<7>

=item * C<CANVAS_NOT_GENERATED> => C<8>

=item * C<CANVAS_QUALITY_BAD> => C<9>

=item * C<CANVAS_EXPORT_FAILED> => C<10>

=back

=head3 Enum: Feedback::FeedbackSource

=over 4

=item * C<FEEDBACK_SOURCE_UNSPECIFIED> => C<0>

=item * C<GOOGLE_CONSOLE> => C<1>

=item * C<GOOGLE_WIDGET> => C<2>

=item * C<GOOGLE_WEBAPP> => C<3>

=item * C<GOOGLE_AGENTSPACE_MOBILE> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Feedback::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
