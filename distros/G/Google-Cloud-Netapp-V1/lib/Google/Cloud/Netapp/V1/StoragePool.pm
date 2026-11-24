package Google::Cloud::Netapp::V1::StoragePool;

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
    eval { require Google::Cloud::Netapp::V1::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvbmV0YXBwL3YxL3N0b3JhZ2VfcG9vbC5wcm90bxIWZ29vZ2xlLmNs
b3VkLm5ldGFwcC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL25ldGFwcC92MS9jb21tb24ucHJv
dG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvIlYKFUdldFN0b3JhZ2VQb29sUmVxdWVzdBI9CgRuYW1lGAEgASgJ
QingQQL6QSMKIW5ldGFwcC5nb29nbGVhcGlzLmNvbS9TdG9yYWdlUG9vbFIEbmFtZSLfAQoX
TGlzdFN0b3JhZ2VQb29sc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIW5ldGFw
cC5nb29nbGVhcGlzLmNvbS9TdG9yYWdlUG9vbFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEo
BUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIe
CghvcmRlcl9ieRgEIAEoCUID4EEBUgdvcmRlckJ5EhsKBmZpbHRlchgFIAEoCUID4EEBUgZm
aWx0ZXIirgEKGExpc3RTdG9yYWdlUG9vbHNSZXNwb25zZRJICg1zdG9yYWdlX3Bvb2xzGAEg
AygLMiMuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TdG9yYWdlUG9vbFIMc3RvcmFnZVBvb2xz
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJs
ZRgDIAMoCVILdW5yZWFjaGFibGUi1wEKGENyZWF0ZVN0b3JhZ2VQb29sUmVxdWVzdBJBCgZw
YXJlbnQYASABKAlCKeBBAvpBIxIhbmV0YXBwLmdvb2dsZWFwaXMuY29tL1N0b3JhZ2VQb29s
UgZwYXJlbnQSKwoPc3RvcmFnZV9wb29sX2lkGAIgASgJQgPgQQJSDXN0b3JhZ2VQb29sSWQS
SwoMc3RvcmFnZV9wb29sGAMgASgLMiMuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TdG9yYWdl
UG9vbEID4EECUgtzdG9yYWdlUG9vbCKpAQoYVXBkYXRlU3RvcmFnZVBvb2xSZXF1ZXN0EkAK
C3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1
cGRhdGVNYXNrEksKDHN0b3JhZ2VfcG9vbBgCIAEoCzIjLmdvb2dsZS5jbG91ZC5uZXRhcHAu
djEuU3RvcmFnZVBvb2xCA+BBAlILc3RvcmFnZVBvb2wiWQoYRGVsZXRlU3RvcmFnZVBvb2xS
ZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohbmV0YXBwLmdvb2dsZWFwaXMuY29tL1N0
b3JhZ2VQb29sUgRuYW1lIl8KHlN3aXRjaEFjdGl2ZVJlcGxpY2Fab25lUmVxdWVzdBI9CgRu
YW1lGAEgASgJQingQQL6QSMKIW5ldGFwcC5nb29nbGVhcGlzLmNvbS9TdG9yYWdlUG9vbFIE
bmFtZSKVEgoLU3RvcmFnZVBvb2wSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEk4KDXNlcnZp
Y2VfbGV2ZWwYAiABKA4yJC5nb29nbGUuY2xvdWQubmV0YXBwLnYxLlNlcnZpY2VMZXZlbEID
4EECUgxzZXJ2aWNlTGV2ZWwSJgoMY2FwYWNpdHlfZ2liGAMgASgDQgPgQQJSC2NhcGFjaXR5
R2liEjMKE3ZvbHVtZV9jYXBhY2l0eV9naWIYBCABKANCA+BBA1IRdm9sdW1lQ2FwYWNpdHlH
aWISJgoMdm9sdW1lX2NvdW50GAUgASgFQgPgQQNSC3ZvbHVtZUNvdW50EkQKBXN0YXRlGAYg
ASgOMikuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TdG9yYWdlUG9vbC5TdGF0ZUID4EEDUgVz
dGF0ZRIoCg1zdGF0ZV9kZXRhaWxzGAcgASgJQgPgQQNSDHN0YXRlRGV0YWlscxJACgtjcmVh
dGVfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRIlCgtkZXNjcmlwdGlvbhgJIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJMCgZsYWJlbHMY
CiADKAsyLy5nb29nbGUuY2xvdWQubmV0YXBwLnYxLlN0b3JhZ2VQb29sLkxhYmVsc0VudHJ5
QgPgQQFSBmxhYmVscxJACgduZXR3b3JrGAsgASgJQibgQQL6QSAKHmNvbXB1dGUuZ29vZ2xl
YXBpcy5jb20vTmV0d29ya1IHbmV0d29yaxJYChBhY3RpdmVfZGlyZWN0b3J5GAwgASgJQi3g
QQH6QScKJW5ldGFwcC5nb29nbGVhcGlzLmNvbS9BY3RpdmVEaXJlY3RvcnlSD2FjdGl2ZURp
cmVjdG9yeRJGCgprbXNfY29uZmlnGA0gASgJQifgQQH6QSEKH25ldGFwcC5nb29nbGVhcGlz
LmNvbS9LbXNDb25maWdSCWttc0NvbmZpZxImCgxsZGFwX2VuYWJsZWQYDiABKAhCA+BBAVIL
bGRhcEVuYWJsZWQSIAoJcHNhX3JhbmdlGA8gASgJQgPgQQFSCHBzYVJhbmdlElQKD2VuY3J5
cHRpb25fdHlwZRgQIAEoDjImLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuRW5jcnlwdGlvblR5
cGVCA+BBA1IOZW5jcnlwdGlvblR5cGUSOwoVZ2xvYmFsX2FjY2Vzc19hbGxvd2VkGBEgASgI
QgIYAUgAUhNnbG9iYWxBY2Nlc3NBbGxvd2VkiAEBEjEKEmFsbG93X2F1dG9fdGllcmluZxgS
IAEoCEID4EEBUhBhbGxvd0F1dG9UaWVyaW5nEiYKDHJlcGxpY2Ffem9uZRgUIAEoCUID4EEB
UgtyZXBsaWNhWm9uZRIXCgR6b25lGBUgASgJQgPgQQFSBHpvbmUSKAoNc2F0aXNmaWVzX3B6
cxgXIAEoCEID4EEDUgxzYXRpc2ZpZXNQenMSKAoNc2F0aXNmaWVzX3B6aRgYIAEoCEID4EED
UgxzYXRpc2ZpZXNQemkSQQoaY3VzdG9tX3BlcmZvcm1hbmNlX2VuYWJsZWQYGSABKAhCA+BB
AVIYY3VzdG9tUGVyZm9ybWFuY2VFbmFibGVkEjkKFnRvdGFsX3Rocm91Z2hwdXRfbWlicHMY
GiABKANCA+BBAVIUdG90YWxUaHJvdWdocHV0TWlicHMSIgoKdG90YWxfaW9wcxgbIAEoA0ID
4EEBUgl0b3RhbElvcHMSLgoRaG90X3RpZXJfc2l6ZV9naWIYHCABKANCA+BBAVIOaG90VGll
clNpemVHaWISRgobZW5hYmxlX2hvdF90aWVyX2F1dG9fcmVzaXplGB0gASgIQgPgQQFIAVIX
ZW5hYmxlSG90VGllckF1dG9SZXNpemWIAQESPwoIcW9zX3R5cGUYHiABKA4yHy5nb29nbGUu
Y2xvdWQubmV0YXBwLnYxLlFvc1R5cGVCA+BBAVIHcW9zVHlwZRJBChphdmFpbGFibGVfdGhy
b3VnaHB1dF9taWJwcxgfIAEoAUID4EEDUhhhdmFpbGFibGVUaHJvdWdocHV0TWlicHMSOQoX
Y29sZF90aWVyX3NpemVfdXNlZF9naWIYISABKANCA+BBA1ITY29sZFRpZXJTaXplVXNlZEdp
YhI3ChZob3RfdGllcl9zaXplX3VzZWRfZ2liGCIgASgDQgPgQQNSEmhvdFRpZXJTaXplVXNl
ZEdpYhJFCgR0eXBlGCMgASgOMicuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TdG9yYWdlUG9v
bFR5cGVCA+BBAUgCUgR0eXBliAEBEjoKBG1vZGUYJCABKA4yHC5nb29nbGUuY2xvdWQubmV0
YXBwLnYxLk1vZGVCA+BBAUgDUgRtb2RliAEBEkUKCnNjYWxlX3R5cGUYJiABKA4yIS5nb29n
bGUuY2xvdWQubmV0YXBwLnYxLlNjYWxlVHlwZUID4EEBUglzY2FsZVR5cGUaOQoLTGFiZWxz
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJ7CgVT
dGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgkKBVJFQURZEAESDAoIQ1JFQVRJTkcQAhIM
CghERUxFVElORxADEgwKCFVQREFUSU5HEAQSDQoJUkVTVE9SSU5HEAUSDAoIRElTQUJMRUQQ
BhIJCgVFUlJPUhAHOocB6kGDAQohbmV0YXBwLmdvb2dsZWFwaXMuY29tL1N0b3JhZ2VQb29s
EkNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc3RvcmFnZVBvb2xz
L3tzdG9yYWdlX3Bvb2x9KgxzdG9yYWdlUG9vbHMyC3N0b3JhZ2VQb29sQhgKFl9nbG9iYWxf
YWNjZXNzX2FsbG93ZWRCHgocX2VuYWJsZV9ob3RfdGllcl9hdXRvX3Jlc2l6ZUIHCgVfdHlw
ZUIHCgVfbW9kZSLEAQofVmFsaWRhdGVEaXJlY3RvcnlTZXJ2aWNlUmVxdWVzdBI9CgRuYW1l
GAEgASgJQingQQL6QSMKIW5ldGFwcC5nb29nbGVhcGlzLmNvbS9TdG9yYWdlUG9vbFIEbmFt
ZRJiChZkaXJlY3Rvcnlfc2VydmljZV90eXBlGAIgASgOMiwuZ29vZ2xlLmNsb3VkLm5ldGFw
cC52MS5EaXJlY3RvcnlTZXJ2aWNlVHlwZVIUZGlyZWN0b3J5U2VydmljZVR5cGUqNAoETW9k
ZRIUChBNT0RFX1VOU1BFQ0lGSUVEEAASCwoHREVGQVVMVBABEgkKBU9OVEFQEAJCsgEKGmNv
bS5nb29nbGUuY2xvdWQubmV0YXBwLnYxQhBTdG9yYWdlUG9vbFByb3RvUAFaMmNsb3VkLmdv
b2dsZS5jb20vZ28vbmV0YXBwL2FwaXYxL25ldGFwcHBiO25ldGFwcHBiqgIWR29vZ2xlLkNs
b3VkLk5ldEFwcC5WMcoCFkdvb2dsZVxDbG91ZFxOZXRBcHBcVjHqAhlHb29nbGU6OkNsb3Vk
OjpOZXRBcHA6OlYxSpBgCgcSBQ4A2AIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
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
bnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAtCgkKAgMD
EgMVACoKCQoCAwQSAxYAKQoICgEIEgMYADMKCQoCCCUSAxgAMwoICgEIEgMZAEkKCQoCCAsS
AxkASQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADEKCQoCCAgSAxsAMQoICgEIEgMc
ADMKCQoCCAESAxwAMwoICgEIEgMdADMKCQoCCCkSAx0AMwoICgEIEgMeADIKCQoCCC0SAx4A
MgqhAQoCBQASBCIAKwEalAEgYE1vZGVgIG9mIHRoZSBzdG9yYWdlIHBvb2wgb3Igdm9sdW1l
LiBUaGlzIGZpZWxkIGlzIHVzZWQgdG8gY29udHJvbCB3aGV0aGVyCiB0aGUgcmVzb3VyY2Ug
aXMgbWFuYWdlZCBieSB0aGUgR0NOViBBUElzIG9yIHRoZSBHQ05WIE9OVEFQIE1vZGUgQVBJ
cy4KCgoKAwUAARIDIgUJCisKBAUAAgASAyQCFxoeIFRoZSBgTW9kZWAgaXMgbm90IHNwZWNp
ZmllZC4KCgwKBQUAAgABEgMkAhIKDAoFBQACAAISAyQVFgo4CgQFAAIBEgMnAg4aKyBUaGUg
cmVzb3VyY2UgaXMgbWFuYWdlZCBieSB0aGUgR0NOViBBUElzLgoKDAoFBQACAQESAycCCQoM
CgUFAAIBAhIDJwwNCkMKBAUAAgISAyoCDBo2IFRoZSByZXNvdXJjZSBpcyBtYW5hZ2VkIGJ5
IHRoZSBHQ05WIE9OVEFQIE1vZGUgQVBJcy4KCgwKBQUAAgIBEgMqAgcKDAoFBQACAgISAyoK
Cwo4CgIEABIELgA2ARosIEdldFN0b3JhZ2VQb29sUmVxdWVzdCBnZXRzIGEgU3RvcmFnZSBQ
b29sLgoKCgoDBAABEgMuCB0KMgoEBAACABIEMAI1BBokIFJlcXVpcmVkLiBOYW1lIG9mIHRo
ZSBzdG9yYWdlIHBvb2wKCgwKBQQAAgAFEgMwAggKDAoFBAACAAESAzAJDQoMCgUEAAIAAxID
MBARCg0KBQQAAgAIEgQwEjUDCg8KCAQAAgAInAgAEgMxBCoKDwoHBAACAAifCBIEMgQ0BQo6
CgIEARIEOQBPARouIExpc3RTdG9yYWdlUG9vbHNSZXF1ZXN0IGxpc3RzIFN0b3JhZ2UgUG9v
bHMuCgoKCgMEAQESAzkIHwomCgQEAQIAEgQ7AkAEGhggUmVxdWlyZWQuIFBhcmVudCB2YWx1
ZQoKDAoFBAECAAUSAzsCCAoMCgUEAQIAARIDOwkPCgwKBQQBAgADEgM7EhMKDQoFBAECAAgS
BDsUQAMKDwoIBAECAAicCAASAzwEKgoPCgcEAQIACJ8IEgQ9BD8FCj8KBAQBAgESA0MCPxoy
IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgoKDAoF
BAECAQUSA0MCBwoMCgUEAQIBARIDQwgRCgwKBQQBAgEDEgNDFBUKDAoFBAECAQgSA0MWPgoP
CggEAQIBCJwIABIDQxc9Cn0KBAQBAgISA0cCQRpwIE9wdGlvbmFsLiBUaGUgbmV4dF9wYWdl
X3Rva2VuIHZhbHVlIHRvIHVzZSBpZiB0aGVyZSBhcmUgYWRkaXRpb25hbAogcmVzdWx0cyB0
byByZXRyaWV2ZSBmb3IgdGhpcyBsaXN0IHJlcXVlc3QuCgoMCgUEAQICBRIDRwIICgwKBQQB
AgIBEgNHCRMKDAoFBAECAgMSA0cWFwoMCgUEAQICCBIDRxhACg8KCAQBAgIInAgAEgNHGT8K
YgoEBAECAxIDSwI/GlUgT3B0aW9uYWwuIFNvcnQgcmVzdWx0cy4gU3VwcG9ydGVkIHZhbHVl
cyBhcmUgIm5hbWUiLCAibmFtZSBkZXNjIiBvciAiIgogKHVuc29ydGVkKS4KCgwKBQQBAgMF
EgNLAggKDAoFBAECAwESA0sJEQoMCgUEAQIDAxIDSxQVCgwKBQQBAgMIEgNLFj4KDwoIBAEC
AwicCAASA0sXPQolCgQEAQIEEgNOAj0aGCBPcHRpb25hbC4gTGlzdCBmaWx0ZXIuCgoMCgUE
AQIEBRIDTgIICgwKBQQBAgQBEgNOCQ8KDAoFBAECBAMSA04SEwoMCgUEAQIECBIDThQ8Cg8K
CAQBAgQInAgAEgNOFTsKVAoCBAISBFIAWwEaSCBMaXN0U3RvcmFnZVBvb2xzUmVzcG9uc2Ug
aXMgdGhlIHJlc3BvbnNlIHRvIGEgTGlzdFN0b3JhZ2VQb29sc1JlcXVlc3QuCgoKCgMEAgES
A1IIIAonCgQEAgIAEgNUAikaGiBUaGUgbGlzdCBvZiBTdG9yYWdlUG9vbHMKCgwKBQQCAgAE
EgNUAgoKDAoFBAICAAYSA1QLFgoMCgUEAgIAARIDVBckCgwKBQQCAgADEgNUJygKTgoEBAIC
ARIDVwIdGkEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2Vy
dmVyIHNob3VsZCByZXR1cm4uCgoMCgUEAgIBBRIDVwIICgwKBQQCAgEBEgNXCRgKDAoFBAIC
AQMSA1cbHAozCgQEAgICEgNaAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVh
Y2hlZC4KCgwKBQQCAgIEEgNaAgoKDAoFBAICAgUSA1oLEQoMCgUEAgICARIDWhIdCgwKBQQC
AgIDEgNaICEKPgoCBAMSBF4AbwEaMiBDcmVhdGVTdG9yYWdlUG9vbFJlcXVlc3QgY3JlYXRl
cyBhIFN0b3JhZ2UgUG9vbC4KCgoKAwQDARIDXgggCisKBAQDAgASBGACZQQaHSBSZXF1aXJl
ZC4gVmFsdWUgZm9yIHBhcmVudC4KCgwKBQQDAgAFEgNgAggKDAoFBAMCAAESA2AJDwoMCgUE
AwIAAxIDYBITCg0KBQQDAgAIEgRgFGUDCg8KCAQDAgAInAgAEgNhBCoKDwoHBAMCAAifCBIE
YgRkBQr3AQoEBAMCARIDawJGGukBIFJlcXVpcmVkLiBJZCBvZiB0aGUgcmVxdWVzdGluZyBz
dG9yYWdlIHBvb2wuIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUKIHBhcmVudCByZXNvdXJj
ZS4gTXVzdCBjb250YWluIG9ubHkgbGV0dGVycywgbnVtYmVycyBhbmQgaHlwaGVuLCB3aXRo
IHRoZQogZmlyc3QgY2hhcmFjdGVyIGEgbGV0dGVyLCB0aGUgbGFzdCBhIGxldHRlciBvciBh
IG51bWJlciwgYW5kIGEgNjMgY2hhcmFjdGVyCiBtYXhpbXVtLgoKDAoFBAMCAQUSA2sCCAoM
CgUEAwIBARIDawkYCgwKBQQDAgEDEgNrGxwKDAoFBAMCAQgSA2sdRQoPCggEAwIBCJwIABID
ax5ECk4KBAQDAgISA24CSBpBIFJlcXVpcmVkLiBUaGUgcmVxdWlyZWQgcGFyYW1ldGVycyB0
byBjcmVhdGUgYSBuZXcgc3RvcmFnZSBwb29sLgoKDAoFBAMCAgYSA24CDQoMCgUEAwICARID
bg4aCgwKBQQDAgIDEgNuHR4KDAoFBAMCAggSA24fRwoPCggEAwICCJwIABIDbiBGCj4KAgQE
EgRyAH0BGjIgVXBkYXRlU3RvcmFnZVBvb2xSZXF1ZXN0IHVwZGF0ZXMgYSBTdG9yYWdlIFBv
b2wuCgoKCgMEBAESA3IIIArbAgoEBAQCABIEeAJ5LxrMAiBSZXF1aXJlZC4gRmllbGQgbWFz
ayBpcyB1c2VkIHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0
aGUKIFN0b3JhZ2VQb29sIHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNw
ZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJj
ZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4g
aWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92aWRlIGEg
bWFzayB0aGVuIGFsbCBmaWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCgwKBQQEAgAGEgN4
AhsKDAoFBAQCAAESA3gcJwoMCgUEBAIAAxIDeCorCgwKBQQEAgAIEgN5Bi4KDwoIBAQCAAic
CAASA3kHLQovCgQEBAIBEgN8AkgaIiBSZXF1aXJlZC4gVGhlIHBvb2wgYmVpbmcgdXBkYXRl
ZAoKDAoFBAQCAQYSA3wCDQoMCgUEBAIBARIDfA4aCgwKBQQEAgEDEgN8HR4KDAoFBAQCAQgS
A3wfRwoPCggEBAIBCJwIABIDfCBGCkAKAgQFEgaAAQCIAQEaMiBEZWxldGVTdG9yYWdlUG9v
bFJlcXVlc3QgZGVsZXRlcyBhIFN0b3JhZ2UgUG9vbC4KCgsKAwQFARIEgAEIIAo0CgQEBQIA
EgaCAQKHAQQaJCBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgc3RvcmFnZSBwb29sCgoNCgUEBQIA
BRIEggECCAoNCgUEBQIAARIEggEJDQoNCgUEBQIAAxIEggEQEQoPCgUEBQIACBIGggEShwED
ChAKCAQFAgAInAgAEgSDAQQqChEKBwQFAgAInwgSBoQBBIYBBQpqCgIEBhIGjAEAlAEBGlwg
U3dpdGNoQWN0aXZlUmVwbGljYVpvbmVSZXF1ZXN0IHN3aXRjaCB0aGUgYWN0aXZlL3JlcGxp
Y2Egem9uZSBmb3IgYSByZWdpb25hbAogc3RvcmFnZVBvb2wuCgoLCgMEBgESBIwBCCYKNAoE
BAYCABIGjgECkwEEGiQgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHN0b3JhZ2UgcG9vbAoKDQoF
BAYCAAUSBI4BAggKDQoFBAYCAAESBI4BCQ0KDQoFBAYCAAMSBI4BEBEKDwoFBAYCAAgSBo4B
EpMBAwoQCggEBgIACJwIABIEjwEEKgoRCgcEBgIACJ8IEgaQAQSSAQUK0AEKAgQHEgaZAQDJ
AgEawQEgU3RvcmFnZVBvb2wgaXMgYSBjb250YWluZXIgZm9yIHZvbHVtZXMgd2l0aCBhIHNl
cnZpY2UgbGV2ZWwgYW5kIGNhcGFjaXR5LgogVm9sdW1lcyBjYW4gYmUgY3JlYXRlZCBpbiBh
IHBvb2wgb2Ygc3VmZmljaWVudCBhdmFpbGFibGUgY2FwYWNpdHkuCiBTdG9yYWdlUG9vbCBj
YXBhY2l0eSBpcyB3aGF0IHlvdSBhcmUgYmlsbGVkIGZvci4KCgsKAwQHARIEmQEIEwoNCgME
BwcSBpoBAp8BBAoPCgUEBwedCBIGmgECnwEECikKBAQHBAASBqIBAroBAxoZIFRoZSBTdG9y
YWdlIFBvb2wgU3RhdGVzCgoNCgUEBwQAARIEogEHDAowCgYEBwQAAgASBKQBBBoaICBVbnNw
ZWNpZmllZCBTdG9yYWdlIFBvb2wgU3RhdGUKCg8KBwQHBAACAAESBKQBBBUKDwoHBAcEAAIA
AhIEpAEYGQotCgYEBwQAAgESBKcBBA4aHSBTdG9yYWdlIFBvb2wgU3RhdGUgaXMgUmVhZHkK
Cg8KBwQHBAACAQESBKcBBAkKDwoHBAcEAAIBAhIEpwEMDQowCgYEBwQAAgISBKoBBBEaICBT
dG9yYWdlIFBvb2wgU3RhdGUgaXMgQ3JlYXRpbmcKCg8KBwQHBAACAgESBKoBBAwKDwoHBAcE
AAICAhIEqgEPEAowCgYEBwQAAgMSBK0BBBEaICBTdG9yYWdlIFBvb2wgU3RhdGUgaXMgRGVs
ZXRpbmcKCg8KBwQHBAACAwESBK0BBAwKDwoHBAcEAAIDAhIErQEPEAowCgYEBwQAAgQSBLAB
BBEaICBTdG9yYWdlIFBvb2wgU3RhdGUgaXMgVXBkYXRpbmcKCg8KBwQHBAACBAESBLABBAwK
DwoHBAcEAAIEAhIEsAEPEAoxCgYEBwQAAgUSBLMBBBIaISBTdG9yYWdlIFBvb2wgU3RhdGUg
aXMgUmVzdG9yaW5nCgoPCgcEBwQAAgUBEgSzAQQNCg8KBwQHBAACBQISBLMBEBEKMAoGBAcE
AAIGEgS2AQQRGiAgU3RvcmFnZSBQb29sIFN0YXRlIGlzIERpc2FibGVkCgoPCgcEBwQAAgYB
EgS2AQQMCg8KBwQHBAACBgISBLYBDxAKLQoGBAcEAAIHEgS5AQQOGh0gU3RvcmFnZSBQb29s
IFN0YXRlIGlzIEVycm9yCgoPCgcEBwQAAgcBEgS5AQQJCg8KBwQHBAACBwISBLkBDA0KNAoE
BAcCABIEvQECPRomIElkZW50aWZpZXIuIE5hbWUgb2YgdGhlIHN0b3JhZ2UgcG9vbAoKDQoF
BAcCAAUSBL0BAggKDQoFBAcCAAESBL0BCQ0KDQoFBAcCAAMSBL0BEBEKDQoFBAcCAAgSBL0B
EjwKEAoIBAcCAAicCAASBL0BEzsKOwoEBAcCARIEwAECShotIFJlcXVpcmVkLiBTZXJ2aWNl
IGxldmVsIG9mIHRoZSBzdG9yYWdlIHBvb2wKCg0KBQQHAgEGEgTAAQIOCg0KBQQHAgEBEgTA
AQ8cCg0KBQQHAgEDEgTAAR8gCg0KBQQHAgEIEgTAASFJChAKCAQHAgEInAgAEgTAASJICjUK
BAQHAgISBMMBAkIaJyBSZXF1aXJlZC4gQ2FwYWNpdHkgaW4gR0lCIG9mIHRoZSBwb29sCgoN
CgUEBwICBRIEwwECBwoNCgUEBwICARIEwwEIFAoNCgUEBwICAxIEwwEXGAoNCgUEBwICCBIE
wwEZQQoQCggEBwICCJwIABIEwwEaQApVCgQEBwIDEgTGAQJMGkcgT3V0cHV0IG9ubHkuIEFs
bG9jYXRlZCBzaXplIG9mIGFsbCB2b2x1bWVzIGluIEdJQiBpbiB0aGUgc3RvcmFnZSBwb29s
CgoNCgUEBwIDBRIExgECBwoNCgUEBwIDARIExgEIGwoNCgUEBwIDAxIExgEeHwoNCgUEBwID
CBIExgEgSwoQCggEBwIDCJwIABIExgEhSgo9CgQEBwIEEgTJAQJFGi8gT3V0cHV0IG9ubHku
IFZvbHVtZSBjb3VudCBvZiB0aGUgc3RvcmFnZSBwb29sCgoNCgUEBwIEBRIEyQECBwoNCgUE
BwIEARIEyQEIFAoNCgUEBwIEAxIEyQEXGAoNCgUEBwIECBIEyQEZRAoQCggEBwIECJwIABIE
yQEaQwo2CgQEBwIFEgTMAQI+GiggT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBzdG9yYWdl
IHBvb2wKCg0KBQQHAgUGEgTMAQIHCg0KBQQHAgUBEgTMAQgNCg0KBQQHAgUDEgTMARARCg0K
BQQHAgUIEgTMARI9ChAKCAQHAgUInAgAEgTMARM8Cj4KBAQHAgYSBM8BAkcaMCBPdXRwdXQg
b25seS4gU3RhdGUgZGV0YWlscyBvZiB0aGUgc3RvcmFnZSBwb29sCgoNCgUEBwIGBRIEzwEC
CAoNCgUEBwIGARIEzwEJFgoNCgUEBwIGAxIEzwEZGgoNCgUEBwIGCBIEzwEbRgoQCggEBwIG
CJwIABIEzwEcRQo+CgQEBwIHEgbSAQLTATIaLiBPdXRwdXQgb25seS4gQ3JlYXRlIHRpbWUg
b2YgdGhlIHN0b3JhZ2UgcG9vbAoKDQoFBAcCBwYSBNIBAhsKDQoFBAcCBwESBNIBHCcKDQoF
BAcCBwMSBNIBKisKDQoFBAcCBwgSBNMBBjEKEAoIBAcCBwicCAASBNMBBzAKOQoEBAcCCBIE
1gECQhorIE9wdGlvbmFsLiBEZXNjcmlwdGlvbiBvZiB0aGUgc3RvcmFnZSBwb29sCgoNCgUE
BwIIBRIE1gECCAoNCgUEBwIIARIE1gEJFAoNCgUEBwIIAxIE1gEXGAoNCgUEBwIICBIE1gEZ
QQoQCggEBwIICJwIABIE1gEaQAozCgQEBwIJEgTZAQJLGiUgT3B0aW9uYWwuIExhYmVscyBh
cyBrZXkgdmFsdWUgcGFpcnMKCg0KBQQHAgkGEgTZAQIVCg0KBQQHAgkBEgTZARYcCg0KBQQH
AgkDEgTZAR8hCg0KBQQHAgkIEgTZASJKChAKCAQHAgkInAgAEgTZASNJCmMKBAQHAgoSBt0B
AuABBBpTIFJlcXVpcmVkLiBWUEMgTmV0d29yayBuYW1lLgogRm9ybWF0OiBwcm9qZWN0cy97
cHJvamVjdH0vZ2xvYmFsL25ldHdvcmtzL3tuZXR3b3JrfQoKDQoFBAcCCgUSBN0BAggKDQoF
BAcCCgESBN0BCRAKDQoFBAcCCgMSBN0BExUKDwoFBAcCCggSBt0BFuABAwoQCggEBwIKCJwI
ABIE3gEEKgoPCgcEBwIKCJ8IEgTfAQRQCmEKBAQHAgsSBuQBAukBBBpRIE9wdGlvbmFsLiBT
cGVjaWZpZXMgdGhlIEFjdGl2ZSBEaXJlY3RvcnkgdG8gYmUgdXNlZCBmb3IgY3JlYXRpbmcg
YSBTTUIKIHZvbHVtZS4KCg0KBQQHAgsFEgTkAQIICg0KBQQHAgsBEgTkAQkZCg0KBQQHAgsD
EgTkARweCg8KBQQHAgsIEgbkAR/pAQMKEAoIBAcCCwicCAASBOUBBCoKEQoHBAcCCwifCBIG
5gEE6AEFClYKBAQHAgwSBuwBAvEBBBpGIE9wdGlvbmFsLiBTcGVjaWZpZXMgdGhlIEtNUyBj
b25maWcgdG8gYmUgdXNlZCBmb3Igdm9sdW1lIGVuY3J5cHRpb24uCgoNCgUEBwIMBRIE7AEC
CAoNCgUEBwIMARIE7AEJEwoNCgUEBwIMAxIE7AEWGAoPCgUEBwIMCBIG7AEZ8QEDChAKCAQH
AgwInAgAEgTtAQQqChEKBwQHAgwInwgSBu4BBPABBQpRCgQEBwINEgT0AQJCGkMgT3B0aW9u
YWwuIEZsYWcgaW5kaWNhdGluZyBpZiB0aGUgcG9vbCBpcyBORlMgTERBUCBlbmFibGVkIG9y
IG5vdC4KCg0KBQQHAg0FEgT0AQIGCg0KBQQHAg0BEgT0AQcTCg0KBQQHAg0DEgT0ARYYCg0K
BQQHAg0IEgT0ARlBChAKCAQHAg0InAgAEgT0ARpACmgKBAQHAg4SBPgBAkEaWiBPcHRpb25h
bC4gVGhpcyBmaWVsZCBpcyBub3QgaW1wbGVtZW50ZWQuIFRoZSB2YWx1ZXMgcHJvdmlkZWQg
aW4gdGhpcyBmaWVsZAogYXJlIGlnbm9yZWQuCgoNCgUEBwIOBRIE+AECCAoNCgUEBwIOARIE
+AEJEgoNCgUEBwIOAxIE+AEVFwoNCgUEBwIOCBIE+AEYQAoQCggEBwIOCJwIABIE+AEZPwpQ
CgQEBwIPEgb7AQL8ATIaQCBPdXRwdXQgb25seS4gU3BlY2lmaWVzIHRoZSBjdXJyZW50IHBv
b2wgZW5jcnlwdGlvbiBrZXkgc291cmNlLgoKDQoFBAcCDwYSBPsBAhAKDQoFBAcCDwESBPsB
ESAKDQoFBAcCDwMSBPsBIyUKDQoFBAcCDwgSBPwBBjEKEAoIBAcCDwicCAASBPwBBzAKYQoE
BAcCEBIEgAICPxpTIERlcHJlY2F0ZWQuIFVzZWQgdG8gYWxsb3cgU08gcG9vbCB0byBhY2Nl
c3MgQUQgb3IgRE5TIHNlcnZlciBmcm9tIG90aGVyCiByZWdpb25zLgoKDQoFBAcCEAQSBIAC
AgoKDQoFBAcCEAUSBIACCw8KDQoFBAcCEAESBIACECUKDQoFBAcCEAMSBIACKCoKDQoFBAcC
EAgSBIACKz4KDgoGBAcCEAgDEgSAAiw9Cs0BCgQEBwIREgSFAgJIGr4BIE9wdGlvbmFsLiBU
cnVlIGlmIHRoZSBzdG9yYWdlIHBvb2wgc3VwcG9ydHMgQXV0byBUaWVyaW5nIGVuYWJsZWQg
dm9sdW1lcy4KIERlZmF1bHQgaXMgZmFsc2UuIEF1dG8tdGllcmluZyBjYW4gYmUgZW5hYmxl
ZCBhZnRlciBzdG9yYWdlIHBvb2wgY3JlYXRpb24KIGJ1dCBpdCBjYW4ndCBiZSBkaXNhYmxl
ZCBvbmNlIGVuYWJsZWQuCgoNCgUEBwIRBRIEhQICBgoNCgUEBwIRARIEhQIHGQoNCgUEBwIR
AxIEhQIcHgoNCgUEBwIRCBIEhQIfRwoQCggEBwIRCJwIABIEhQIgRgpOCgQEBwISEgSIAgJE
GkAgT3B0aW9uYWwuIFNwZWNpZmllcyB0aGUgcmVwbGljYSB6b25lIGZvciByZWdpb25hbCBz
dG9yYWdlUG9vbC4KCg0KBQQHAhIFEgSIAgIICg0KBQQHAhIBEgSIAgkVCg0KBQQHAhIDEgSI
AhgaCg0KBQQHAhIIEgSIAhtDChAKCAQHAhIInAgAEgSIAhxCCk0KBAQHAhMSBIsCAjwaPyBP
cHRpb25hbC4gU3BlY2lmaWVzIHRoZSBhY3RpdmUgem9uZSBmb3IgcmVnaW9uYWwgc3RvcmFn
ZVBvb2wuCgoNCgUEBwITBRIEiwICCAoNCgUEBwITARIEiwIJDQoNCgUEBwITAxIEiwIQEgoN
CgUEBwITCBIEiwITOwoQCggEBwITCJwIABIEiwIUOgo0CgQEBwIUEgSOAgJGGiYgT3V0cHV0
IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlCgoNCgUEBwIUBRIEjgICBgoNCgUEBwIU
ARIEjgIHFAoNCgUEBwIUAxIEjgIXGQoNCgUEBwIUCBIEjgIaRQoQCggEBwIUCJwIABIEjgIb
RAo0CgQEBwIVEgSRAgJGGiYgT3V0cHV0IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNl
CgoNCgUEBwIVBRIEkQICBgoNCgUEBwIVARIEkQIHFAoNCgUEBwIVAxIEkQIXGQoNCgUEBwIV
CBIEkQIaRQoQCggEBwIVCJwIABIEkQIbRAp8CgQEBwIWEgSVAgJQGm4gT3B0aW9uYWwuIFRy
dWUgaWYgdXNpbmcgSW5kZXBlbmRlbnQgU2NhbGluZyBvZiBjYXBhY2l0eSBhbmQgcGVyZm9y
bWFuY2UKIChIeXBlcmRpc2spIEJ5IGRlZmF1bHQgc2V0IHRvIGZhbHNlCgoNCgUEBwIWBRIE
lQICBgoNCgUEBwIWARIElQIHIQoNCgUEBwIWAxIElQIkJgoNCgUEBwIWCBIElQInTwoQCggE
BwIWCJwIABIElQIoTgpUCgQEBwIXEgSYAgJNGkYgT3B0aW9uYWwuIEN1c3RvbSBQZXJmb3Jt
YW5jZSBUb3RhbCBUaHJvdWdocHV0IG9mIHRoZSBwb29sIChpbiBNaUJwcykKCg0KBQQHAhcF
EgSYAgIHCg0KBQQHAhcBEgSYAggeCg0KBQQHAhcDEgSYAiEjCg0KBQQHAhcIEgSYAiRMChAK
CAQHAhcInAgAEgSYAiVLCpABCgQEBwIYEgScAgJBGoEBIE9wdGlvbmFsLiBDdXN0b20gUGVy
Zm9ybWFuY2UgVG90YWwgSU9QUyBvZiB0aGUgcG9vbAogaWYgbm90IHByb3ZpZGVkLCBpdCB3
aWxsIGJlIGNhbGN1bGF0ZWQgYmFzZWQgb24gdGhlIHRvdGFsX3Rocm91Z2hwdXRfbWlicHMK
Cg0KBQQHAhgFEgScAgIHCg0KBQQHAhgBEgScAggSCg0KBQQHAhgDEgScAhUXCg0KBQQHAhgI
EgScAhhAChAKCAQHAhgInAgAEgScAhk/CoUCCgQEBwIZEgSiAgJIGvYBIE9wdGlvbmFsLiBU
b3RhbCBob3QgdGllciBjYXBhY2l0eSBmb3IgdGhlIFN0b3JhZ2UgUG9vbC4gSXQgaXMgYXBw
bGljYWJsZQogb25seSB0byBGbGV4IHNlcnZpY2UgbGV2ZWwuIEl0IHNob3VsZCBiZSBsZXNz
IHRoYW4gdGhlIG1pbmltdW0gc3RvcmFnZSBwb29sCiBzaXplIGFuZCBjYW5ub3QgYmUgbW9y
ZSB0aGFuIHRoZSBjdXJyZW50IHN0b3JhZ2UgcG9vbCBzaXplLiBJdCBjYW5ub3QgYmUKIGRl
Y3JlYXNlZCBvbmNlIHNldC4KCg0KBQQHAhkFEgSiAgIHCg0KBQQHAhkBEgSiAggZCg0KBQQH
AhkDEgSiAhweCg0KBQQHAhkIEgSiAh9HChAKCAQHAhkInAgAEgSiAiBGCo8CCgQEBwIaEgao
AgKpAi8a/gEgT3B0aW9uYWwuIEZsYWcgaW5kaWNhdGluZyB0aGF0IHRoZSBob3QtdGllciB0
aHJlc2hvbGQgd2lsbCBiZQogYXV0by1pbmNyZWFzZWQgYnkgMTAlIG9mIHRoZSBob3QtdGll
ciB3aGVuIGl0IGhpdHMgMTAwJS4gRGVmYXVsdCBpcyB0cnVlLgogVGhlIGluY3JlbWVudCB3
aWxsIGtpY2sgaW4gb25seSBpZiB0aGUgbmV3IHNpemUgYWZ0ZXIgaW5jcmVtZW50IGlzCiBz
dGlsbCBsZXNzIHRoYW4gb3IgZXF1YWwgdG8gc3RvcmFnZSBwb29sIHNpemUuCgoNCgUEBwIa
BBIEqAICCgoNCgUEBwIaBRIEqAILDwoNCgUEBwIaARIEqAIQKwoNCgUEBwIaAxIEqAIuMAoN
CgUEBwIaCBIEqQIGLgoQCggEBwIaCJwIABIEqQIHLQpLCgQEBwIbEgSsAgJBGj0gT3B0aW9u
YWwuIFFvUyAoUXVhbGl0eSBvZiBTZXJ2aWNlKSBUeXBlIG9mIHRoZSBzdG9yYWdlIHBvb2wK
Cg0KBQQHAhsGEgSsAgIJCg0KBQQHAhsBEgSsAgoSCg0KBQQHAhsDEgSsAhUXCg0KBQQHAhsI
EgSsAhhAChAKCAQHAhsInAgAEgSsAhk/ClMKBAQHAhwSBq8CArACMhpDIE91dHB1dCBvbmx5
LiBBdmFpbGFibGUgdGhyb3VnaHB1dCBvZiB0aGUgc3RvcmFnZSBwb29sIChpbiBNaUIvcyku
CgoNCgUEBwIcBRIErwICCAoNCgUEBwIcARIErwIJIwoNCgUEBwIcAxIErwImKAoNCgUEBwIc
CBIEsAIGMQoQCggEBwIcCJwIABIEsAIHMApuCgQEBwIdEga0AgK1AjIaXiBPdXRwdXQgb25s
eS4gVG90YWwgY29sZCB0aWVyIGRhdGEgcm91bmRlZCBkb3duIHRvIHRoZSBuZWFyZXN0IEdp
QiB1c2VkIGJ5CiB0aGUgc3RvcmFnZSBwb29sLgoKDQoFBAcCHQUSBLQCAgcKDQoFBAcCHQES
BLQCCB8KDQoFBAcCHQMSBLQCIiQKDQoFBAcCHQgSBLUCBjEKEAoIBAcCHQicCAASBLUCBzAK
awoEBAcCHhIEuQICUBpdIE91dHB1dCBvbmx5LiBUb3RhbCBob3QgdGllciBkYXRhIHJvdW5k
ZWQgZG93biB0byB0aGUgbmVhcmVzdCBHaUIgdXNlZCBieQogdGhlIHN0b3JhZ2UgcG9vbC4K
Cg0KBQQHAh4FEgS5AgIHCg0KBQQHAh4BEgS5AggeCg0KBQQHAh4DEgS5AiEjCg0KBQQHAh4I
EgS5AiRPChAKCAQHAh4InAgAEgS5AiVOCvEBCgQEBwIfEgS+AgJOGuIBIE9wdGlvbmFsLiBU
eXBlIG9mIHRoZSBzdG9yYWdlIHBvb2wuIFRoaXMgZmllbGQgaXMgdXNlZCB0byBjb250cm9s
IHdoZXRoZXIKIHRoZSBwb29sIHN1cHBvcnRzIGBGSUxFYCBiYXNlZCB2b2x1bWVzIG9ubHkg
b3IgYFVOSUZJRURgIChib3RoIGBGSUxFYCBhbmQKIGBCTE9DS2ApIHZvbHVtZXMuIElmIG5v
dCBzcGVjaWZpZWQgZHVyaW5nIGNyZWF0aW9uLCBpdCBkZWZhdWx0cyB0byBgRklMRWAuCgoN
CgUEBwIfBBIEvgICCgoNCgUEBwIfBhIEvgILGgoNCgUEBwIfARIEvgIbHwoNCgUEBwIfAxIE
vgIiJAoNCgUEBwIfCBIEvgIlTQoQCggEBwIfCJwIABIEvgImTArzAQoEBAcCIBIExAICQxrk
ASBPcHRpb25hbC4gTW9kZSBvZiB0aGUgc3RvcmFnZSBwb29sLiBUaGlzIGZpZWxkIGlzIHVz
ZWQgdG8gY29udHJvbCB3aGV0aGVyCiB0aGUgdXNlciBjYW4gcGVyZm9ybSBPTlRBUCBvcGVy
YXRpb25zIG9uIHRoZSBzdG9yYWdlIHBvb2wgdXNpbmcgdGhlIEdDTlYKIE9OVEFQIE1vZGUg
QVBJcy4gSWYgbm90IHNwZWNpZmllZCBkdXJpbmcgY3JlYXRpb24sIGl0IGRlZmF1bHRzIHRv
CiBgREVGQVVMVGAuCgoNCgUEBwIgBBIExAICCgoNCgUEBwIgBhIExAILDwoNCgUEBwIgARIE
xAIQFAoNCgUEBwIgAxIExAIXGQoNCgUEBwIgCBIExAIaQgoQCggEBwIgCJwIABIExAIbQQpx
CgQEBwIhEgTIAgJFGmMgT3B0aW9uYWwuIFRoZSBzY2FsZSB0eXBlIG9mIHRoZSBzdG9yYWdl
IHBvb2wuIERlZmF1bHRzIHRvCiBgU0NBTEVfVFlQRV9ERUZBVUxUYCBpZiBub3Qgc3BlY2lm
aWVkLgoKDQoFBAcCIQYSBMgCAgsKDQoFBAcCIQESBMgCDBYKDQoFBAcCIQMSBMgCGRsKDQoF
BAcCIQgSBMgCHEQKEAoIBAcCIQicCAASBMgCHUMKdQoCBAgSBs0CANgCARpnIFZhbGlkYXRl
RGlyZWN0b3J5U2VydmljZVJlcXVlc3QgdmFsaWRhdGVzIHRoZSBkaXJlY3Rvcnkgc2Vydmlj
ZSBwb2xpY3kKIGF0dGFjaGVkIHRvIHRoZSBzdG9yYWdlIHBvb2wuCgoLCgMECAESBM0CCCcK
NAoEBAgCABIGzwIC1AIEGiQgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHN0b3JhZ2UgcG9vbAoK
DQoFBAgCAAUSBM8CAggKDQoFBAgCAAESBM8CCQ0KDQoFBAgCAAMSBM8CEBEKDwoFBAgCAAgS
Bs8CEtQCAwoQCggECAIACJwIABIE0AIEKgoRCgcECAIACJ8IEgbRAgTTAgUKTgoEBAgCARIE
1wICMhpAIFR5cGUgb2YgZGlyZWN0b3J5IHNlcnZpY2UgcG9saWN5IGF0dGFjaGVkIHRvIHRo
ZSBzdG9yYWdlIHBvb2wuCgoNCgUECAIBBhIE1wICFgoNCgUECAIBARIE1wIXLQoNCgUECAIB
AxIE1wIwMWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest ===
    # Fields for GetStoragePoolRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsRequest ===
    # Fields for ListStoragePoolsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsResponse ===
    # Fields for ListStoragePoolsResponse
    # Field: storage_pools Type: 11 (.google.cloud.netapp.v1.StoragePool)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::StoragePool::CreateStoragePoolRequest ===
    # Fields for CreateStoragePoolRequest
    # Field: parent Type: 9 ()
    # Field: storage_pool_id Type: 9 ()
    # Field: storage_pool Type: 11 (.google.cloud.netapp.v1.StoragePool)

# === Message: Google::Cloud::Netapp::V1::StoragePool::UpdateStoragePoolRequest ===
    # Fields for UpdateStoragePoolRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: storage_pool Type: 11 (.google.cloud.netapp.v1.StoragePool)

# === Message: Google::Cloud::Netapp::V1::StoragePool::DeleteStoragePoolRequest ===
    # Fields for DeleteStoragePoolRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::StoragePool::SwitchActiveReplicaZoneRequest ===
    # Fields for SwitchActiveReplicaZoneRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::StoragePool::StoragePool ===
    # Fields for StoragePool
    # Field: name Type: 9 ()
    # Field: service_level Type: 14 (.google.cloud.netapp.v1.ServiceLevel)
    # Field: capacity_gib Type: 3 ()
    # Field: volume_capacity_gib Type: 3 ()
    # Field: volume_count Type: 5 ()
    # Field: state Type: 14 (.google.cloud.netapp.v1.StoragePool.State)
    # Field: state_details Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.netapp.v1.StoragePool.LabelsEntry)
    # Field: network Type: 9 ()
    # Field: active_directory Type: 9 ()
    # Field: kms_config Type: 9 ()
    # Field: ldap_enabled Type: 8 ()
    # Field: psa_range Type: 9 ()
    # Field: encryption_type Type: 14 (.google.cloud.netapp.v1.EncryptionType)
    # Field: global_access_allowed Type: 8 ()
    # Field: allow_auto_tiering Type: 8 ()
    # Field: replica_zone Type: 9 ()
    # Field: zone Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()
    # Field: custom_performance_enabled Type: 8 ()
    # Field: total_throughput_mibps Type: 3 ()
    # Field: total_iops Type: 3 ()
    # Field: hot_tier_size_gib Type: 3 ()
    # Field: enable_hot_tier_auto_resize Type: 8 ()
    # Field: qos_type Type: 14 (.google.cloud.netapp.v1.QosType)
    # Field: available_throughput_mibps Type: 1 ()
    # Field: cold_tier_size_used_gib Type: 3 ()
    # Field: hot_tier_size_used_gib Type: 3 ()
    # Field: type Type: 14 (.google.cloud.netapp.v1.StoragePoolType)
    # Field: mode Type: 14 (.google.cloud.netapp.v1.Mode)
    # Field: scale_type Type: 14 (.google.cloud.netapp.v1.ScaleType)

# Enum: StoragePool::State
our $StoragePool_STATE_UNSPECIFIED = 0;
our $StoragePool_READY = 1;
our $StoragePool_CREATING = 2;
our $StoragePool_DELETING = 3;
our $StoragePool_UPDATING = 4;
our $StoragePool_RESTORING = 5;
our $StoragePool_DISABLED = 6;
our $StoragePool_ERROR = 7;

# === Message: Google::Cloud::Netapp::V1::StoragePool::ValidateDirectoryServiceRequest ===
    # Fields for ValidateDirectoryServiceRequest
    # Field: name Type: 9 ()
    # Field: directory_service_type Type: 14 (.google.cloud.netapp.v1.DirectoryServiceType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::StoragePool - Compiled Protocol Buffers messages for google/cloud/netapp/v1/storage_pool.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::StoragePool;

    my $msg = Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/storage_pool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest

GetStoragePoolRequest gets a Storage Pool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the storage pool

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsRequest

ListStoragePoolsRequest lists Storage Pools.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value to use if there are additional
results to retrieve for this list request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Sort results. Supported values are "name", "name desc" or ""
(unsorted).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. List filter.

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsResponse

ListStoragePoolsResponse is the response to a ListStoragePoolsRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->storage_pools() >> / C<< $msg->storage_pools($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::StoragePool::StoragePool>)

The list of StoragePools

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::CreateStoragePoolRequest

CreateStoragePoolRequest creates a Storage Pool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Value for parent.

=item * C<< $msg->storage_pool_id() >> / C<< $msg->storage_pool_id($value) >>

Type: C<String>

Required. Id of the requesting storage pool. Must be unique within the
parent resource. Must contain only letters, numbers and hyphen, with the
first character a letter, the last a letter or a number, and a 63 character
maximum.

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::StoragePool::StoragePool>)

Required. The required parameters to create a new storage pool.

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::UpdateStoragePoolRequest

UpdateStoragePoolRequest updates a Storage Pool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
StoragePool resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::StoragePool::StoragePool>)

Required. The pool being updated

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::DeleteStoragePoolRequest

DeleteStoragePoolRequest deletes a Storage Pool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the storage pool

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::SwitchActiveReplicaZoneRequest

SwitchActiveReplicaZoneRequest switch the active/replica zone for a regional
storagePool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the storage pool

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::StoragePool

StoragePool is a container for volumes with a service level and capacity.
Volumes can be created in a pool of sufficient available capacity.
StoragePool capacity is what you are billed for.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the storage pool

=item * C<< $msg->service_level() >> / C<< $msg->service_level($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::ServiceLevel>)

Required. Service level of the storage pool

=item * C<< $msg->capacity_gib() >> / C<< $msg->capacity_gib($value) >>

Type: C<Int64>

Required. Capacity in GIB of the pool

=item * C<< $msg->volume_capacity_gib() >> / C<< $msg->volume_capacity_gib($value) >>

Type: C<Int64>

Output only. Allocated size of all volumes in GIB in the storage pool

=item * C<< $msg->volume_count() >> / C<< $msg->volume_count($value) >>

Type: C<Int32>

Output only. Volume count of the storage pool

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::StoragePool::State>)

Output only. State of the storage pool

=item * C<< $msg->state_details() >> / C<< $msg->state_details($value) >>

Type: C<String>

Output only. State details of the storage pool

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the storage pool

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the storage pool

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::StoragePool::StoragePool::LabelsEntry>)

Optional. Labels as key value pairs

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Required. VPC Network name.
Format: projects/{project}/global/networks/{network}

=item * C<< $msg->active_directory() >> / C<< $msg->active_directory($value) >>

Type: C<String>

Optional. Specifies the Active Directory to be used for creating a SMB
volume.

=item * C<< $msg->kms_config() >> / C<< $msg->kms_config($value) >>

Type: C<String>

Optional. Specifies the KMS config to be used for volume encryption.

=item * C<< $msg->ldap_enabled() >> / C<< $msg->ldap_enabled($value) >>

Type: C<Bool>

Optional. Flag indicating if the pool is NFS LDAP enabled or not.

=item * C<< $msg->psa_range() >> / C<< $msg->psa_range($value) >>

Type: C<String>

Optional. This field is not implemented. The values provided in this field
are ignored.

=item * C<< $msg->encryption_type() >> / C<< $msg->encryption_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::EncryptionType>)

Output only. Specifies the current pool encryption key source.

=item * C<< $msg->global_access_allowed() >> / C<< $msg->global_access_allowed($value) >>

Type: C<Bool>

Deprecated. Used to allow SO pool to access AD or DNS server from other
regions.

=item * C<< $msg->allow_auto_tiering() >> / C<< $msg->allow_auto_tiering($value) >>

Type: C<Bool>

Optional. True if the storage pool supports Auto Tiering enabled volumes.
Default is false. Auto-tiering can be enabled after storage pool creation
but it can't be disabled once enabled.

=item * C<< $msg->replica_zone() >> / C<< $msg->replica_zone($value) >>

Type: C<String>

Optional. Specifies the replica zone for regional storagePool.

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

Optional. Specifies the active zone for regional storagePool.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use

=item * C<< $msg->custom_performance_enabled() >> / C<< $msg->custom_performance_enabled($value) >>

Type: C<Bool>

Optional. True if using Independent Scaling of capacity and performance
(Hyperdisk) By default set to false

=item * C<< $msg->total_throughput_mibps() >> / C<< $msg->total_throughput_mibps($value) >>

Type: C<Int64>

Optional. Custom Performance Total Throughput of the pool (in MiBps)

=item * C<< $msg->total_iops() >> / C<< $msg->total_iops($value) >>

Type: C<Int64>

Optional. Custom Performance Total IOPS of the pool
if not provided, it will be calculated based on the total_throughput_mibps

=item * C<< $msg->hot_tier_size_gib() >> / C<< $msg->hot_tier_size_gib($value) >>

Type: C<Int64>

Optional. Total hot tier capacity for the Storage Pool. It is applicable
only to Flex service level. It should be less than the minimum storage pool
size and cannot be more than the current storage pool size. It cannot be
decreased once set.

=item * C<< $msg->enable_hot_tier_auto_resize() >> / C<< $msg->enable_hot_tier_auto_resize($value) >>

Type: C<Bool>

Optional. Flag indicating that the hot-tier threshold will be
auto-increased by 10% of the hot-tier when it hits 100%. Default is true.
The increment will kick in only if the new size after increment is
still less than or equal to storage pool size.

=item * C<< $msg->qos_type() >> / C<< $msg->qos_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::QosType>)

Optional. QoS (Quality of Service) Type of the storage pool

=item * C<< $msg->available_throughput_mibps() >> / C<< $msg->available_throughput_mibps($value) >>

Type: C<Double>

Output only. Available throughput of the storage pool (in MiB/s).

=item * C<< $msg->cold_tier_size_used_gib() >> / C<< $msg->cold_tier_size_used_gib($value) >>

Type: C<Int64>

Output only. Total cold tier data rounded down to the nearest GiB used by
the storage pool.

=item * C<< $msg->hot_tier_size_used_gib() >> / C<< $msg->hot_tier_size_used_gib($value) >>

Type: C<Int64>

Output only. Total hot tier data rounded down to the nearest GiB used by
the storage pool.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::StoragePoolType>)

Optional. Type of the storage pool. This field is used to control whether
the pool supports `FILE` based volumes only or `UNIFIED` (both `FILE` and
`BLOCK`) volumes. If not specified during creation, it defaults to `FILE`.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::Mode>)

Optional. Mode of the storage pool. This field is used to control whether
the user can perform ONTAP operations on the storage pool using the GCNV
ONTAP Mode APIs. If not specified during creation, it defaults to
`DEFAULT`.

=item * C<< $msg->scale_type() >> / C<< $msg->scale_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::ScaleType>)

Optional. The scale type of the storage pool. Defaults to
`SCALE_TYPE_DEFAULT` if not specified.

=back

=head3 Enum: StoragePool::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<READY> => C<1>

=item * C<CREATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<RESTORING> => C<5>

=item * C<DISABLED> => C<6>

=item * C<ERROR> => C<7>

=back

=head2 Google::Cloud::Netapp::V1::StoragePool::ValidateDirectoryServiceRequest

ValidateDirectoryServiceRequest validates the directory service policy
attached to the storage pool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the storage pool

=item * C<< $msg->directory_service_type() >> / C<< $msg->directory_service_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::DirectoryServiceType>)

Type of directory service policy attached to the storage pool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::StoragePool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
