package Google::Cloud::Netapp::V1::Snapshot;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvbmV0YXBwL3YxL3NuYXBzaG90LnByb3RvEhZnb29nbGUuY2xvdWQu
bmV0YXBwLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLFAQoUTGlzdFNuYXBzaG90c1JlcXVlc3QS
PgoGcGFyZW50GAEgASgJQibgQQL6QSASHm5ldGFwcC5nb29nbGVhcGlzLmNvbS9TbmFwc2hv
dFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuEhkKCG9yZGVyX2J5GAQgASgJUgdvcmRlckJ5EhYKBmZpbHRlchgF
IAEoCVIGZmlsdGVyIqEBChVMaXN0U25hcHNob3RzUmVzcG9uc2USPgoJc25hcHNob3RzGAEg
AygLMiAuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TbmFwc2hvdFIJc25hcHNob3RzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMo
CVILdW5yZWFjaGFibGUiUAoSR2V0U25hcHNob3RSZXF1ZXN0EjoKBG5hbWUYASABKAlCJuBB
AvpBIAoebmV0YXBwLmdvb2dsZWFwaXMuY29tL1NuYXBzaG90UgRuYW1lIsABChVDcmVhdGVT
bmFwc2hvdFJlcXVlc3QSPgoGcGFyZW50GAEgASgJQibgQQL6QSASHm5ldGFwcC5nb29nbGVh
cGlzLmNvbS9TbmFwc2hvdFIGcGFyZW50EkEKCHNuYXBzaG90GAIgASgLMiAuZ29vZ2xlLmNs
b3VkLm5ldGFwcC52MS5TbmFwc2hvdEID4EECUghzbmFwc2hvdBIkCgtzbmFwc2hvdF9pZBgD
IAEoCUID4EECUgpzbmFwc2hvdElkIlMKFURlbGV0ZVNuYXBzaG90UmVxdWVzdBI6CgRuYW1l
GAEgASgJQibgQQL6QSAKHm5ldGFwcC5nb29nbGVhcGlzLmNvbS9TbmFwc2hvdFIEbmFtZSKc
AQoVVXBkYXRlU25hcHNob3RSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xl
LnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrEkEKCHNuYXBzaG90GAIgASgL
MiAuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TbmFwc2hvdEID4EECUghzbmFwc2hvdCKSBQoI
U25hcHNob3QSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEkEKBXN0YXRlGAIgASgOMiYuZ29v
Z2xlLmNsb3VkLm5ldGFwcC52MS5TbmFwc2hvdC5TdGF0ZUID4EEDUgVzdGF0ZRIoCg1zdGF0
ZV9kZXRhaWxzGAMgASgJQgPgQQNSDHN0YXRlRGV0YWlscxIgCgtkZXNjcmlwdGlvbhgEIAEo
CVILZGVzY3JpcHRpb24SIgoKdXNlZF9ieXRlcxgFIAEoAUID4EEDUgl1c2VkQnl0ZXMSQAoL
Y3JlYXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSRAoGbGFiZWxzGAcgAygLMiwuZ29vZ2xlLmNsb3VkLm5ldGFwcC52MS5TbmFw
c2hvdC5MYWJlbHNFbnRyeVIGbGFiZWxzGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEibAoFU3RhdGUSFQoRU1RBVEVfVU5TUEVD
SUZJRUQQABIJCgVSRUFEWRABEgwKCENSRUFUSU5HEAISDAoIREVMRVRJTkcQAxIMCghVUERB
VElORxAEEgwKCERJU0FCTEVEEAUSCQoFRVJST1IQBjqIAepBhAEKHm5ldGFwcC5nb29nbGVh
cGlzLmNvbS9TbmFwc2hvdBJNcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L3ZvbHVtZXMve3ZvbHVtZX0vc25hcHNob3RzL3tzbmFwc2hvdH0qCXNuYXBzaG90czII
c25hcHNob3RCrwEKGmNvbS5nb29nbGUuY2xvdWQubmV0YXBwLnYxQg1TbmFwc2hvdFByb3Rv
UAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vbmV0YXBwL2FwaXYxL25ldGFwcHBiO25ldGFwcHBi
qgIWR29vZ2xlLkNsb3VkLk5ldEFwcC5WMcoCFkdvb2dsZVxDbG91ZFxOZXRBcHBcVjHqAhlH
b29nbGU6OkNsb3VkOjpOZXRBcHA6OlYxSqYsCgcSBQ4AswEBCrwECgEMEgMOABIysQQgQ29w
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
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgID
AhIDFAAqCgkKAgMDEgMVACkKCAoBCBIDFwAzCgkKAgglEgMXADMKCAoBCBIDGABJCgkKAggL
EgMYAEkKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAuCgkKAggIEgMaAC4KCAoBCBID
GwAzCgkKAggBEgMbADMKCAoBCBIDHAAzCgkKAggpEgMcADMKCAoBCBIDHQAyCgkKAggtEgMd
ADIKMwoCBAASBCAANwEaJyBMaXN0U25hcHNob3RzUmVxdWVzdCBsaXN0cyBzbmFwc2hvdHMu
CgoKCgMEAAESAyAIHAqjAQoEBAACABIEJAIpBBqUASBSZXF1aXJlZC4gVGhlIHZvbHVtZSBm
b3Igd2hpY2ggdG8gcmV0cmlldmUgc25hcHNob3QgaW5mb3JtYXRpb24sCiBpbiB0aGUgZm9y
bWF0CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3ZvbHVt
ZXMve3ZvbHVtZV9pZH1gLgoKDAoFBAACAAUSAyQCCAoMCgUEAAIAARIDJAkPCgwKBQQAAgAD
EgMkEhMKDQoFBAACAAgSBCQUKQMKDwoIBAACAAicCAASAyUEKgoPCgcEAAIACJ8IEgQmBCgF
CjUKBAQAAgESAywCFhooIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4u
CgoMCgUEAAIBBRIDLAIHCgwKBQQAAgEBEgMsCBEKDAoFBAACAQMSAywUFQpzCgQEAAICEgMw
AhgaZiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHRvIHVzZSBpZiB0aGVyZSBhcmUgYWRk
aXRpb25hbAogcmVzdWx0cyB0byByZXRyaWV2ZSBmb3IgdGhpcyBsaXN0IHJlcXVlc3QuCgoM
CgUEAAICBRIDMAIICgwKBQQAAgIBEgMwCRMKDAoFBAACAgMSAzAWFwpXCgQEAAIDEgMzAhYa
SiBTb3J0IHJlc3VsdHMuIFN1cHBvcnRlZCB2YWx1ZXMgYXJlICJuYW1lIiwgIm5hbWUgZGVz
YyIgb3IgIiIgKHVuc29ydGVkKS4KCgwKBQQAAgMFEgMzAggKDAoFBAACAwESAzMJEQoMCgUE
AAIDAxIDMxQVChsKBAQAAgQSAzYCFBoOIExpc3QgZmlsdGVyLgoKDAoFBAACBAUSAzYCCAoM
CgUEAAIEARIDNgkPCgwKBQQAAgQDEgM2EhMKSgoCBAESBDoARAEaPiBMaXN0U25hcHNob3Rz
UmVzcG9uc2UgaXMgdGhlIHJlc3VsdCBvZiBMaXN0U25hcHNob3RzUmVxdWVzdC4KCgoKAwQB
ARIDOggdCksKBAQBAgASAzwCIho+IEEgbGlzdCBvZiBzbmFwc2hvdHMgaW4gdGhlIHByb2pl
Y3QgZm9yIHRoZSBzcGVjaWZpZWQgdm9sdW1lLgoKDAoFBAECAAQSAzwCCgoMCgUEAQIABhID
PAsTCgwKBQQBAgABEgM8FB0KDAoFBAECAAMSAzwgIQqCAQoEBAECARIDQAIdGnUgVGhlIHRv
a2VuIHlvdSBjYW4gdXNlIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4g
Tm90IHJldHVybmVkCiBpZiB0aGVyZSBhcmUgbm8gbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0
LgoKDAoFBAECAQUSA0ACCAoMCgUEAQIBARIDQAkYCgwKBQQBAgEDEgNAGxwKMwoEBAECAhID
QwIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoMCgUEAQICBBID
QwIKCgwKBQQBAgIFEgNDCxEKDAoFBAECAgESA0MSHQoMCgUEAQICAxIDQyAhCj4KAgQCEgRH
AE4BGjIgR2V0U25hcHNob3RSZXF1ZXN0IGdldHMgdGhlIHN0YXRlIG9mIGEgc25hcHNob3Qu
CgoKCgMEAgESA0cIGgqeAQoEBAICABIESgJNBBqPASBSZXF1aXJlZC4gVGhlIHNuYXBzaG90
IHJlc291cmNlIG5hbWUsIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vdm9sdW1lcy97dm9sdW1lX2lkfS9zbmFwc2hvdHMve3Nu
YXBzaG90X2lkfWAKCgwKBQQCAgAFEgNKAggKDAoFBAICAAESA0oJDQoMCgUEAgIAAxIDShAR
Cg0KBQQCAgAIEgRKEk0DCg8KCAQCAgAInAgAEgNLBCoKDgoHBAICAAifCBIDTARQCjcKAgQD
EgRRAGMBGisgQ3JlYXRlU25hcHNob3RSZXF1ZXN0IGNyZWF0ZXMgYSBzbmFwc2hvdC4KCgoK
AwQDARIDUQgdCpgBCgQEAwIAEgRUAlkEGokBIFJlcXVpcmVkLiBUaGUgTmV0QXBwIHZvbHVt
ZSB0byBjcmVhdGUgdGhlIHNuYXBzaG90cyBvZiwgaW4gdGhlIGZvcm1hdAogYHByb2plY3Rz
L3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS92b2x1bWVzL3t2b2x1bWVfaWR9
YAoKDAoFBAMCAAUSA1QCCAoMCgUEAwIAARIDVAkPCgwKBQQDAgADEgNUEhMKDQoFBAMCAAgS
BFQUWQMKDwoIBAMCAAicCAASA1UEKgoPCgcEAwIACJ8IEgRWBFgFCiwKBAQDAgESA1wCQRof
IFJlcXVpcmVkLiBBIHNuYXBzaG90IHJlc291cmNlCgoMCgUEAwIBBhIDXAIKCgwKBQQDAgEB
EgNcCxMKDAoFBAMCAQMSA1wWFwoMCgUEAwIBCBIDXBhACg8KCAQDAgEInAgAEgNcGT8K8gEK
BAQDAgISA2ICQhrkASBSZXF1aXJlZC4gSUQgb2YgdGhlIHNuYXBzaG90IHRvIGNyZWF0ZS4g
TXVzdCBiZSB1bmlxdWUgd2l0aGluIHRoZSBwYXJlbnQKIHJlc291cmNlLiBNdXN0IGNvbnRh
aW4gb25seSBsZXR0ZXJzLCBudW1iZXJzIGFuZCBoeXBoZW4sIHdpdGggdGhlIGZpcnN0CiBj
aGFyYWN0ZXIgYSBsZXR0ZXIsIHRoZSBsYXN0IGEgbGV0dGVyIG9yIGEKIG51bWJlciwgYW5k
IGEgNjMgY2hhcmFjdGVyIG1heGltdW0uCgoMCgUEAwICBRIDYgIICgwKBQQDAgIBEgNiCRQK
DAoFBAMCAgMSA2IXGAoMCgUEAwICCBIDYhlBCg8KCAQDAgIInAgAEgNiGkAKNwoCBAQSBGYA
bQEaKyBEZWxldGVTbmFwc2hvdFJlcXVlc3QgZGVsZXRlcyBhIHNuYXBzaG90LgoKCgoDBAQB
EgNmCB0KfwoEBAQCABIEaQJsBBpxIFJlcXVpcmVkLiBUaGUgc25hcHNob3QgcmVzb3VyY2Ug
bmFtZSwgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovdm9sdW1lcy8q
L3NuYXBzaG90cy97c25hcHNob3RfaWR9YAoKDAoFBAQCAAUSA2kCCAoMCgUEBAIAARIDaQkN
CgwKBQQEAgADEgNpEBEKDQoFBAQCAAgSBGkSbAMKDwoIBAQCAAicCAASA2oEKgoOCgcEBAIA
CJ8IEgNrBFAKVQoCBAUSBHAAeAEaSSBVcGRhdGVTbmFwc2hvdFJlcXVlc3QgdXBkYXRlcyBk
ZXNjcmlwdGlvbiBhbmQvb3IgbGFiZWxzIGZvciBhIHNuYXBzaG90LgoKCgoDBAUBEgNwCB0K
ZwoEBAUCABIEcwJ0LxpZIFJlcXVpcmVkLiBNYXNrIG9mIGZpZWxkcyB0byB1cGRhdGUuICBB
dCBsZWFzdCBvbmUgcGF0aCBtdXN0IGJlIHN1cHBsaWVkIGluCiB0aGlzIGZpZWxkLgoKDAoF
BAUCAAYSA3MCGwoMCgUEBQIAARIDcxwnCgwKBQQFAgADEgNzKisKDAoFBAUCAAgSA3QGLgoP
CggEBQIACJwIABIDdActCiwKBAQFAgESA3cCQRofIFJlcXVpcmVkLiBBIHNuYXBzaG90IHJl
c291cmNlCgoMCgUEBQIBBhIDdwIKCgwKBQQFAgEBEgN3CxMKDAoFBAUCAQMSA3cWFwoMCgUE
BQIBCBIDdxhACg8KCAQFAgEInAgAEgN3GT8KSQoCBAYSBXsAswEBGjwgU25hcHNob3QgaXMg
YSBwb2ludC1pbi10aW1lIHZlcnNpb24gb2YgYSBWb2x1bWUncyBjb250ZW50LgoKCgoDBAYB
EgN7CBAKDAoDBAYHEgV8AoEBBAoOCgUEBgedCBIFfAKBAQQKJQoEBAYEABIGhAECmQEDGhUg
VGhlIFNuYXBzaG90IFN0YXRlcwoKDQoFBAYEAAESBIQBBwwKLAoGBAYEAAIAEgSGAQQaGhwg
VW5zcGVjaWZpZWQgU25hcHNob3QgU3RhdGUKCg8KBwQGBAACAAESBIYBBBUKDwoHBAYEAAIA
AhIEhgEYGQopCgYEBgQAAgESBIkBBA4aGSBTbmFwc2hvdCBTdGF0ZSBpcyBSZWFkeQoKDwoH
BAYEAAIBARIEiQEECQoPCgcEBgQAAgECEgSJAQwNCiwKBgQGBAACAhIEjAEEERocIFNuYXBz
aG90IFN0YXRlIGlzIENyZWF0aW5nCgoPCgcEBgQAAgIBEgSMAQQMCg8KBwQGBAACAgISBIwB
DxAKLAoGBAYEAAIDEgSPAQQRGhwgU25hcHNob3QgU3RhdGUgaXMgRGVsZXRpbmcKCg8KBwQG
BAACAwESBI8BBAwKDwoHBAYEAAIDAhIEjwEPEAosCgYEBgQAAgQSBJIBBBEaHCBTbmFwc2hv
dCBTdGF0ZSBpcyBVcGRhdGluZwoKDwoHBAYEAAIEARIEkgEEDAoPCgcEBgQAAgQCEgSSAQ8Q
CiwKBgQGBAACBRIElQEEERocIFNuYXBzaG90IFN0YXRlIGlzIERpc2FibGVkCgoPCgcEBgQA
AgUBEgSVAQQMCg8KBwQGBAACBQISBJUBDxAKKQoGBAYEAAIGEgSYAQQOGhkgU25hcHNob3Qg
U3RhdGUgaXMgRXJyb3IKCg8KBwQGBAACBgESBJgBBAkKDwoHBAYEAAIGAhIEmAEMDQqjAQoE
BAYCABIEngECPRqUASBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgc25h
cHNob3QuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9j
YXRpb259L3ZvbHVtZXMve3ZvbHVtZV9pZH0vc25hcHNob3RzL3tzbmFwc2hvdF9pZH1gLgoK
DQoFBAYCAAUSBJ4BAggKDQoFBAYCAAESBJ4BCQ0KDQoFBAYCAAMSBJ4BEBEKDQoFBAYCAAgS
BJ4BEjwKEAoIBAYCAAicCAASBJ4BEzsKMAoEBAYCARIEoQECPhoiIE91dHB1dCBvbmx5LiBU
aGUgc25hcHNob3Qgc3RhdGUuCgoNCgUEBgIBBhIEoQECBwoNCgUEBgIBARIEoQEIDQoNCgUE
BgIBAxIEoQEQEQoNCgUEBgIBCBIEoQESPQoQCggEBgIBCJwIABIEoQETPAo+CgQEBgICEgSk
AQJHGjAgT3V0cHV0IG9ubHkuIFN0YXRlIGRldGFpbHMgb2YgdGhlIHN0b3JhZ2UgcG9vbAoK
DQoFBAYCAgUSBKQBAggKDQoFBAYCAgESBKQBCRYKDQoFBAYCAgMSBKQBGRoKDQoFBAYCAggS
BKQBG0YKEAoIBAYCAgicCAASBKQBHEUKgAEKBAQGAgMSBKgBAhkaciBBIGRlc2NyaXB0aW9u
IG9mIHRoZSBzbmFwc2hvdCB3aXRoIDIwNDggY2hhcmFjdGVycyBvciBsZXNzLgogUmVxdWVz
dHMgd2l0aCBsb25nZXIgZGVzY3JpcHRpb25zIHdpbGwgYmUgcmVqZWN0ZWQuCgoNCgUEBgID
BRIEqAECCAoNCgUEBgIDARIEqAEJFAoNCgUEBgIDAxIEqAEXGApNCgQEBgIEEgSrAQJEGj8g
T3V0cHV0IG9ubHkuIEN1cnJlbnQgc3RvcmFnZSB1c2FnZSBmb3IgdGhlIHNuYXBzaG90IGlu
IGJ5dGVzLgoKDQoFBAYCBAUSBKsBAggKDQoFBAYCBAESBKsBCRMKDQoFBAYCBAMSBKsBFhcK
DQoFBAYCBAgSBKsBGEMKEAoIBAYCBAicCAASBKsBGUIKRgoEBAYCBRIGrgECrwEyGjYgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIHNuYXBzaG90IHdhcyBjcmVhdGVkLgoKDQoF
BAYCBQYSBK4BAhsKDQoFBAYCBQESBK4BHCcKDQoFBAYCBQMSBK4BKisKDQoFBAYCBQgSBK8B
BjEKEAoIBAYCBQicCAASBK8BBzAKRAoEBAYCBhIEsgECIRo2IFJlc291cmNlIGxhYmVscyB0
byByZXByZXNlbnQgdXNlciBwcm92aWRlZCBtZXRhZGF0YS4KCg0KBQQGAgYGEgSyAQIVCg0K
BQQGAgYBEgSyARYcCg0KBQQGAgYDEgSyAR8gYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest ===
    # Fields for ListSnapshotsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsResponse ===
    # Fields for ListSnapshotsResponse
    # Field: snapshots Type: 11 (.google.cloud.netapp.v1.Snapshot)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Snapshot::GetSnapshotRequest ===
    # Fields for GetSnapshotRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Snapshot::CreateSnapshotRequest ===
    # Fields for CreateSnapshotRequest
    # Field: parent Type: 9 ()
    # Field: snapshot Type: 11 (.google.cloud.netapp.v1.Snapshot)
    # Field: snapshot_id Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Snapshot::DeleteSnapshotRequest ===
    # Fields for DeleteSnapshotRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Snapshot::UpdateSnapshotRequest ===
    # Fields for UpdateSnapshotRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: snapshot Type: 11 (.google.cloud.netapp.v1.Snapshot)

# === Message: Google::Cloud::Netapp::V1::Snapshot::Snapshot ===
    # Fields for Snapshot
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.netapp.v1.Snapshot.State)
    # Field: state_details Type: 9 ()
    # Field: description Type: 9 ()
    # Field: used_bytes Type: 1 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.netapp.v1.Snapshot.LabelsEntry)

# Enum: Snapshot::State
our $Snapshot_STATE_UNSPECIFIED = 0;
our $Snapshot_READY = 1;
our $Snapshot_CREATING = 2;
our $Snapshot_DELETING = 3;
our $Snapshot_UPDATING = 4;
our $Snapshot_DISABLED = 5;
our $Snapshot_ERROR = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::Snapshot - Compiled Protocol Buffers messages for google/cloud/netapp/v1/snapshot.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::Snapshot;

    my $msg = Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        order_by => $order_by,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/snapshot.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsRequest

ListSnapshotsRequest lists snapshots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The volume for which to retrieve snapshot information,
in the format
`projects/{project_id}/locations/{location}/volumes/{volume_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value to use if there are additional
results to retrieve for this list request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Sort results. Supported values are "name", "name desc" or "" (unsorted).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Netapp::V1::Snapshot::ListSnapshotsResponse

ListSnapshotsResponse is the result of ListSnapshotsRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snapshots() >> / C<< $msg->snapshots($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Snapshot::Snapshot>)

A list of snapshots in the project for the specified volume.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token you can use to retrieve the next page of results. Not returned
if there are no more results in the list.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::Snapshot::GetSnapshotRequest

GetSnapshotRequest gets the state of a snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The snapshot resource name, in the format
`projects/{project_id}/locations/{location}/volumes/{volume_id}/snapshots/{snapshot_id}`

=back

=head2 Google::Cloud::Netapp::V1::Snapshot::CreateSnapshotRequest

CreateSnapshotRequest creates a snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The NetApp volume to create the snapshots of, in the format
`projects/{project_id}/locations/{location}/volumes/{volume_id}`

=item * C<< $msg->snapshot() >> / C<< $msg->snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Snapshot::Snapshot>)

Required. A snapshot resource

=item * C<< $msg->snapshot_id() >> / C<< $msg->snapshot_id($value) >>

Type: C<String>

Required. ID of the snapshot to create. Must be unique within the parent
resource. Must contain only letters, numbers and hyphen, with the first
character a letter, the last a letter or a
number, and a 63 character maximum.

=back

=head2 Google::Cloud::Netapp::V1::Snapshot::DeleteSnapshotRequest

DeleteSnapshotRequest deletes a snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The snapshot resource name, in the format
`projects/*/locations/*/volumes/*/snapshots/{snapshot_id}`

=back

=head2 Google::Cloud::Netapp::V1::Snapshot::UpdateSnapshotRequest

UpdateSnapshotRequest updates description and/or labels for a snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask of fields to update.  At least one path must be supplied in
this field.

=item * C<< $msg->snapshot() >> / C<< $msg->snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Snapshot::Snapshot>)

Required. A snapshot resource

=back

=head2 Google::Cloud::Netapp::V1::Snapshot::Snapshot

Snapshot is a point-in-time version of a Volume's content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the snapshot.
Format:
`projects/{project_id}/locations/{location}/volumes/{volume_id}/snapshots/{snapshot_id}`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::Snapshot::State>)

Output only. The snapshot state.

=item * C<< $msg->state_details() >> / C<< $msg->state_details($value) >>

Type: C<String>

Output only. State details of the storage pool

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the snapshot with 2048 characters or less.
Requests with longer descriptions will be rejected.

=item * C<< $msg->used_bytes() >> / C<< $msg->used_bytes($value) >>

Type: C<Double>

Output only. Current storage usage for the snapshot in bytes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the snapshot was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Snapshot::Snapshot::LabelsEntry>)

Resource labels to represent user provided metadata.

=back

=head3 Enum: Snapshot::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<READY> => C<1>

=item * C<CREATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<DISABLED> => C<5>

=item * C<ERROR> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::Snapshot::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
