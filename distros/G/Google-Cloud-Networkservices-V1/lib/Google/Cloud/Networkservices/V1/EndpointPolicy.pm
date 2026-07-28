package Google::Cloud::Networkservices::V1::EndpointPolicy;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Networkservices::V1::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL2VuZHBvaW50X3BvbGljeS5wcm90
bxIfZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3Vk
L25ldHdvcmtzZXJ2aWNlcy92MS9jb21tb24ucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVs
ZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIq4JCg5FbmRw
b2ludFBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBk
YXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0
ZVRpbWUSWAoGbGFiZWxzGAQgAygLMjsuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52
MS5FbmRwb2ludFBvbGljeS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSWwoEdHlwZRgFIAEo
DjJCLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuRW5kcG9pbnRQb2xpY3kuRW5k
cG9pbnRQb2xpY3lUeXBlQgPgQQJSBHR5cGUSbQoUYXV0aG9yaXphdGlvbl9wb2xpY3kYByAB
KAlCOuBBAfpBNAoybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0F1dGhvcml6YXRp
b25Qb2xpY3lSE2F1dGhvcml6YXRpb25Qb2xpY3kSYAoQZW5kcG9pbnRfbWF0Y2hlchgJIAEo
CzIwLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuRW5kcG9pbnRNYXRjaGVyQgPg
QQJSD2VuZHBvaW50TWF0Y2hlchJtChV0cmFmZmljX3BvcnRfc2VsZWN0b3IYCiABKAsyNC5n
b29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLlRyYWZmaWNQb3J0U2VsZWN0b3JCA+BB
AVITdHJhZmZpY1BvcnRTZWxlY3RvchIlCgtkZXNjcmlwdGlvbhgLIAEoCUID4EEBUgtkZXNj
cmlwdGlvbhJiChFzZXJ2ZXJfdGxzX3BvbGljeRgMIAEoCUI24EEB+kEwCi5uZXR3b3Jrc2Vj
dXJpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmVyVGxzUG9saWN5Ug9zZXJ2ZXJUbHNQb2xpY3kS
YgoRY2xpZW50X3Rsc19wb2xpY3kYDSABKAlCNuBBAfpBMAoubmV0d29ya3NlY3VyaXR5Lmdv
b2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGljeVIPY2xpZW50VGxzUG9saWN5GjkKC0xhYmVs
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiXgoS
RW5kcG9pbnRQb2xpY3lUeXBlEiQKIEVORFBPSU5UX1BPTElDWV9UWVBFX1VOU1BFQ0lGSUVE
EAASEQoNU0lERUNBUl9QUk9YWRABEg8KC0dSUENfU0VSVkVSEAI6fupBewotbmV0d29ya3Nl
cnZpY2VzLmdvb2dsZWFwaXMuY29tL0VuZHBvaW50UG9saWN5Ekpwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZW5kcG9pbnRQb2xpY2llcy97ZW5kcG9pbnRfcG9s
aWN5fSLjAQobTGlzdEVuZHBvaW50UG9saWNpZXNSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI1
4EEC+kEvEi1uZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnRQb2xpY3lS
BnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyAB
KAlSCXBhZ2VUb2tlbhI5ChZyZXR1cm5fcGFydGlhbF9zdWNjZXNzGAQgASgIQgPgQQFSFHJl
dHVyblBhcnRpYWxTdWNjZXNzIsYBChxMaXN0RW5kcG9pbnRQb2xpY2llc1Jlc3BvbnNlElwK
EWVuZHBvaW50X3BvbGljaWVzGAEgAygLMi8uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNl
cy52MS5FbmRwb2ludFBvbGljeVIQZW5kcG9pbnRQb2xpY2llcxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hh
YmxlImUKGEdldEVuZHBvaW50UG9saWN5UmVxdWVzdBJJCgRuYW1lGAEgASgJQjXgQQL6QS8K
LW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmRwb2ludFBvbGljeVIEbmFtZSL+
AQobQ3JlYXRlRW5kcG9pbnRQb2xpY3lSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC+kEv
Ei1uZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnRQb2xpY3lSBnBhcmVu
dBIxChJlbmRwb2ludF9wb2xpY3lfaWQYAiABKAlCA+BBAlIQZW5kcG9pbnRQb2xpY3lJZBJd
Cg9lbmRwb2ludF9wb2xpY3kYAyABKAsyLy5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2Vz
LnYxLkVuZHBvaW50UG9saWN5QgPgQQJSDmVuZHBvaW50UG9saWN5Ir4BChtVcGRhdGVFbmRw
b2ludFBvbGljeVJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29nbGUucHJvdG9i
dWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSXQoPZW5kcG9pbnRfcG9saWN5GAIgASgL
Mi8uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5FbmRwb2ludFBvbGljeUID4EEC
Ug5lbmRwb2ludFBvbGljeSJoChtEZWxldGVFbmRwb2ludFBvbGljeVJlcXVlc3QSSQoEbmFt
ZRgBIAEoCUI14EEC+kEvCi1uZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5kcG9p
bnRQb2xpY3lSBG5hbWVChgUKI2NvbS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYx
QhNFbmRwb2ludFBvbGljeVByb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya3Nl
cnZpY2VzL2FwaXYxL25ldHdvcmtzZXJ2aWNlc3BiO25ldHdvcmtzZXJ2aWNlc3BiqgIfR29v
Z2xlLkNsb3VkLk5ldHdvcmtTZXJ2aWNlcy5WMcoCH0dvb2dsZVxDbG91ZFxOZXR3b3JrU2Vy
dmljZXNcVjHqAiJHb29nbGU6OkNsb3VkOjpOZXR3b3JrU2VydmljZXM6OlYx6kGKAQoybmV0
d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0F1dGhvcml6YXRpb25Qb2xpY3kSVHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRob3JpemF0aW9uUG9saWNp
ZXMve2F1dGhvcml6YXRpb25fcG9saWN5fepBfwoubmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFw
aXMuY29tL1NlcnZlclRsc1BvbGljeRJNcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L3NlcnZlclRsc1BvbGljaWVzL3tzZXJ2ZXJfdGxzX3BvbGljeX3qQX8KLm5l
dHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9DbGllbnRUbHNQb2xpY3kSTXByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbGllbnRUbHNQb2xpY2llcy97Y2xp
ZW50X3Rsc19wb2xpY3l9SrY/CgcSBQ4A6wEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA2CgkK
AgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYADwKCQoCCCUSAxgAPAoICgEIEgMZAGQKCQoC
CAsSAxkAZAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADQKCQoCCAgSAxsANAoICgEI
EgMcADwKCQoCCAESAxwAPAoICgEIEgMdADwKCQoCCCkSAx0APAoICgEIEgMeADsKCQoCCC0S
Ax4AOwoJCgEIEgQfACICCgwKBAidCAASBB8AIgIKCQoBCBIEIwAmAgoMCgQInQgBEgQjACYC
CgkKAQgSBCcAKgIKDAoECJ0IAhIEJwAqAgr3AQoCBAASBTAAhwEBGukBIEVuZHBvaW50UG9s
aWN5IGlzIGEgcmVzb3VyY2UgdGhhdCBoZWxwcyBhcHBseSBkZXNpcmVkIGNvbmZpZ3VyYXRp
b24KIG9uIHRoZSBlbmRwb2ludHMgdGhhdCBtYXRjaCBzcGVjaWZpYyBjcml0ZXJpYS4KIEZv
ciBleGFtcGxlLCB0aGlzIHJlc291cmNlIGNhbiBiZSB1c2VkIHRvIGFwcGx5ICJhdXRoZW50
aWNhdGlvbiBjb25maWciCiBhbiBhbGwgZW5kcG9pbnRzIHRoYXQgc2VydmUgb24gcG9ydCA4
MDgwLgoKCgoDBAABEgMwCBYKCwoDBAAHEgQxAjQECg0KBQQAB50IEgQxAjQECiwKBAQABAAS
BDcCQAMaHiBUaGUgdHlwZSBvZiBlbmRwb2ludCBwb2xpY3kuCgoMCgUEAAQAARIDNwcZCjEK
BgQABAACABIDOQQpGiIgRGVmYXVsdCB2YWx1ZS4gTXVzdCBub3QgYmUgdXNlZC4KCg4KBwQA
BAACAAESAzkEJAoOCgcEAAQAAgACEgM5JygKOgoGBAAEAAIBEgM8BBYaKyBSZXByZXNlbnRz
IGEgcHJveHkgZGVwbG95ZWQgYXMgYSBzaWRlY2FyLgoKDgoHBAAEAAIBARIDPAQRCg4KBwQA
BAACAQISAzwUFQo1CgYEAAQAAgISAz8EFBomIFJlcHJlc2VudHMgYSBwcm94eWxlc3MgZ1JQ
QyBiYWNrZW5kLgoKDgoHBAAEAAICARIDPwQPCg4KBwQABAACAgISAz8SEwqZAQoEBAACABID
RAI9GosBIElkZW50aWZpZXIuIE5hbWUgb2YgdGhlIEVuZHBvaW50UG9saWN5IHJlc291cmNl
LiBJdCBtYXRjaGVzIHBhdHRlcm4KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zLyov
ZW5kcG9pbnRQb2xpY2llcy97ZW5kcG9pbnRfcG9saWN5fWAuCgoMCgUEAAIABRIDRAIICgwK
BQQAAgABEgNECQ0KDAoFBAACAAMSA0QQEQoMCgUEAAIACBIDRBI8Cg8KCAQAAgAInAgAEgNE
EzsKSQoEBAACARIERwJIMho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhl
IHJlc291cmNlIHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSA0cCGwoMCgUEAAIBARIDRxwnCgwK
BQQAAgEDEgNHKisKDAoFBAACAQgSA0gGMQoPCggEAAIBCJwIABIDSAcwCkkKBAQAAgISBEsC
TDIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMg
dXBkYXRlZC4KCgwKBQQAAgIGEgNLAhsKDAoFBAACAgESA0scJwoMCgUEAAICAxIDSyorCgwK
BQQAAgIIEgNMBjEKDwoIBAACAgicCAASA0wHMApXCgQEAAIDEgNPAkoaSiBPcHRpb25hbC4g
U2V0IG9mIGxhYmVsIHRhZ3MgYXNzb2NpYXRlZCB3aXRoIHRoZSBFbmRwb2ludFBvbGljeSBy
ZXNvdXJjZS4KCgwKBQQAAgMGEgNPAhUKDAoFBAACAwESA08WHAoMCgUEAAIDAxIDTx8gCgwK
BQQAAgMIEgNPIUkKDwoIBAACAwicCAASA08iSApsCgQEAAIEEgNTAkcaXyBSZXF1aXJlZC4g
VGhlIHR5cGUgb2YgZW5kcG9pbnQgcG9saWN5LiBUaGlzIGlzIHByaW1hcmlseSB1c2VkIHRv
IHZhbGlkYXRlCiB0aGUgY29uZmlndXJhdGlvbi4KCgwKBQQAAgQGEgNTAhQKDAoFBAACBAES
A1MVGQoMCgUEAAIEAxIDUxwdCgwKBQQAAgQIEgNTHkYKDwoIBAACBAicCAASA1MfRQqmAgoE
BAACBRIEWgJfBBqXAiBPcHRpb25hbC4gVGhpcyBmaWVsZCBzcGVjaWZpZXMgdGhlIFVSTCBv
ZiBBdXRob3JpemF0aW9uUG9saWN5IHJlc291cmNlIHRoYXQKIGFwcGxpZXMgYXV0aG9yaXph
dGlvbiBwb2xpY2llcyB0byB0aGUgaW5ib3VuZCB0cmFmZmljIGF0IHRoZQogbWF0Y2hlZCBl
bmRwb2ludHMuIFJlZmVyIHRvIEF1dGhvcml6YXRpb24uIElmIHRoaXMgZmllbGQgaXMgbm90
CiBzcGVjaWZpZWQsIGF1dGhvcml6YXRpb24gaXMgZGlzYWJsZWQobm8gYXV0aHogY2hlY2tz
KSBmb3IgdGhpcwogZW5kcG9pbnQuCgoMCgUEAAIFBRIDWgIICgwKBQQAAgUBEgNaCR0KDAoF
BAACBQMSA1ogIQoNCgUEAAIFCBIEWiJfAwoPCggEAAIFCJwIABIDWwQqCg8KBwQAAgUInwgS
BFwEXgUKYwoEBAACBhIDYwJQGlYgUmVxdWlyZWQuIEEgbWF0Y2hlciB0aGF0IHNlbGVjdHMg
ZW5kcG9pbnRzIHRvIHdoaWNoIHRoZSBwb2xpY2llcyBzaG91bGQgYmUKIGFwcGxpZWQuCgoM
CgUEAAIGBhIDYwIRCgwKBQQAAgYBEgNjEiIKDAoFBAACBgMSA2MlJgoMCgUEAAIGCBIDYydP
Cg8KCAQAAgYInAgAEgNjKE4KkwEKBAQAAgcSBGcCaC8ahAEgT3B0aW9uYWwuIFBvcnQgc2Vs
ZWN0b3IgZm9yIHRoZSAobWF0Y2hlZCkgZW5kcG9pbnRzLiBJZiBubyBwb3J0IHNlbGVjdG9y
IGlzCiBwcm92aWRlZCwgdGhlIG1hdGNoZWQgY29uZmlnIGlzIGFwcGxpZWQgdG8gYWxsIHBv
cnRzLgoKDAoFBAACBwYSA2cCFQoMCgUEAAIHARIDZxYrCgwKBQQAAgcDEgNnLjAKDAoFBAAC
BwgSA2gGLgoPCggEAAIHCJwIABIDaActCl4KBAQAAggSA2wCQxpRIE9wdGlvbmFsLiBBIGZy
ZWUtdGV4dCBkZXNjcmlwdGlvbiBvZiB0aGUgcmVzb3VyY2UuIE1heCBsZW5ndGggMTAyNAog
Y2hhcmFjdGVycy4KCgwKBQQAAggFEgNsAggKDAoFBAACCAESA2wJFAoMCgUEAAIIAxIDbBcZ
CgwKBQQAAggIEgNsGkIKDwoIBAACCAicCAASA2wbQQqiAgoEBAACCRIEcgJ3BBqTAiBPcHRp
b25hbC4gQSBVUkwgcmVmZXJyaW5nIHRvIFNlcnZlclRsc1BvbGljeSByZXNvdXJjZS4gU2Vy
dmVyVGxzUG9saWN5IGlzCiB1c2VkIHRvIGRldGVybWluZSB0aGUgYXV0aGVudGljYXRpb24g
cG9saWN5IHRvIGJlIGFwcGxpZWQgdG8gdGVybWluYXRlIHRoZQogaW5ib3VuZCB0cmFmZmlj
IGF0IHRoZSBpZGVudGlmaWVkIGJhY2tlbmRzLiBJZiB0aGlzIGZpZWxkIGlzIG5vdCBzZXQs
CiBhdXRoZW50aWNhdGlvbiBpcyBkaXNhYmxlZChvcGVuKSBmb3IgdGhpcyBlbmRwb2ludC4K
CgwKBQQAAgkFEgNyAggKDAoFBAACCQESA3IJGgoMCgUEAAIJAxIDch0fCg0KBQQAAgkIEgRy
IHcDCg8KCAQAAgkInAgAEgNzBCoKDwoHBAACCQifCBIEdAR2BQrGBAoEBAACChIGgQEChgEE
GrUEIE9wdGlvbmFsLiBBIFVSTCByZWZlcnJpbmcgdG8gYSBDbGllbnRUbHNQb2xpY3kgcmVz
b3VyY2UuIENsaWVudFRsc1BvbGljeQogY2FuIGJlIHNldCB0byBzcGVjaWZ5IHRoZSBhdXRo
ZW50aWNhdGlvbiBmb3IgdHJhZmZpYyBmcm9tIHRoZSBwcm94eSB0byB0aGUKIGFjdHVhbCBl
bmRwb2ludHMuIE1vcmUgc3BlY2lmaWNhbGx5LCBpdCBpcyBhcHBsaWVkIHRvIHRoZSBvdXRn
b2luZyB0cmFmZmljCiBmcm9tIHRoZSBwcm94eSB0byB0aGUgZW5kcG9pbnQuIFRoaXMgaXMg
dHlwaWNhbGx5IHVzZWQgZm9yIHNpZGVjYXIgbW9kZWwKIHdoZXJlIHRoZSBwcm94eSBpZGVu
dGlmaWVzIGl0c2VsZiBhcyBlbmRwb2ludCB0byB0aGUgY29udHJvbCBwbGFuZSwgd2l0aAog
dGhlIGNvbm5lY3Rpb24gYmV0d2VlbiBzaWRlY2FyIGFuZCBlbmRwb2ludCByZXF1aXJpbmcg
YXV0aGVudGljYXRpb24uIElmCiB0aGlzIGZpZWxkIGlzIG5vdCBzZXQsIGF1dGhlbnRpY2F0
aW9uIGlzIGRpc2FibGVkKG9wZW4pLiBBcHBsaWNhYmxlIG9ubHkKIHdoZW4gRW5kcG9pbnRQ
b2xpY3lUeXBlIGlzIFNJREVDQVJfUFJPWFkuCgoNCgUEAAIKBRIEgQECCAoNCgUEAAIKARIE
gQEJGgoNCgUEAAIKAxIEgQEdHwoPCgUEAAIKCBIGgQEghgEDChAKCAQAAgoInAgAEgSCAQQq
ChEKBwQAAgoInwgSBoMBBIUBBQpCCgIEARIGigEAoQEBGjQgUmVxdWVzdCB1c2VkIHdpdGgg
dGhlIExpc3RFbmRwb2ludFBvbGljaWVzIG1ldGhvZC4KCgsKAwQBARIEigEIIwqaAQoEBAEC
ABIGjQECkgEEGokBIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3
aGljaCB0aGUgRW5kcG9pbnRQb2xpY2llcyBzaG91bGQKIGJlIGxpc3RlZCwgc3BlY2lmaWVk
IGluIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoKDQoFBAECAAUSBI0B
AggKDQoFBAECAAESBI0BCQ8KDQoFBAECAAMSBI0BEhMKDwoFBAECAAgSBo0BFJIBAwoQCggE
AQIACJwIABIEjgEEKgoRCgcEAQIACJ8IEgaPAQSRAQUKRgoEBAECARIElQECFho4IE1heGlt
dW0gbnVtYmVyIG9mIEVuZHBvaW50UG9saWNpZXMgdG8gcmV0dXJuIHBlciBjYWxsLgoKDQoF
BAECAQUSBJUBAgcKDQoFBAECAQESBJUBCBEKDQoFBAECAQMSBJUBFBUK2AEKBAQBAgISBJsB
AhgayQEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0IGBMaXN0RW5kcG9pbnRQb2xp
Y2llc1Jlc3BvbnNlYAogSW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBhIGNvbnRpbnVhdGlvbiBv
ZiBhIHByaW9yCiBgTGlzdEVuZHBvaW50UG9saWNpZXNgIGNhbGwsIGFuZCB0aGF0IHRoZSBz
eXN0ZW0gc2hvdWxkIHJldHVybiB0aGUKIG5leHQgcGFnZSBvZiBkYXRhLgoKDQoFBAECAgUS
BJsBAggKDQoFBAECAgESBJsBCRMKDQoFBAECAgMSBJsBFhcKywEKBAQBAgMSBKABAksavAEg
T3B0aW9uYWwuIElmIHRydWUsIGFsbG93IHBhcnRpYWwgcmVzcG9uc2VzIGZvciBtdWx0aS1y
ZWdpb25hbCBBZ2dyZWdhdGVkCiBMaXN0IHJlcXVlc3RzLiBPdGhlcndpc2UgaWYgb25lIG9m
IHRoZSBsb2NhdGlvbnMgaXMgZG93biBvciB1bnJlYWNoYWJsZSwKIHRoZSBBZ2dyZWdhdGVk
IExpc3QgcmVxdWVzdCB3aWxsIGZhaWwuCgoNCgUEAQIDBRIEoAECBgoNCgUEAQIDARIEoAEH
HQoNCgUEAQIDAxIEoAEgIQoNCgUEAQIDCBIEoAEiSgoQCggEAQIDCJwIABIEoAEjSQpFCgIE
AhIGpAEAsgEBGjcgUmVzcG9uc2UgcmV0dXJuZWQgYnkgdGhlIExpc3RFbmRwb2ludFBvbGlj
aWVzIG1ldGhvZC4KCgsKAwQCARIEpAEIJAoxCgQEAgIAEgSmAQIwGiMgTGlzdCBvZiBFbmRw
b2ludFBvbGljeSByZXNvdXJjZXMuCgoNCgUEAgIABBIEpgECCgoNCgUEAgIABhIEpgELGQoN
CgUEAgIAARIEpgEaKwoNCgUEAgIAAxIEpgEuLwrpAQoEBAICARIEqwECHRraASBJZiB0aGVy
ZSBtaWdodCBiZSBtb3JlIHJlc3VsdHMgdGhhbiB0aG9zZSBhcHBlYXJpbmcgaW4gdGhpcyBy
ZXNwb25zZSwgdGhlbgogYG5leHRfcGFnZV90b2tlbmAgaXMgaW5jbHVkZWQuIFRvIGdldCB0
aGUgbmV4dCBzZXQgb2YgcmVzdWx0cywgY2FsbCB0aGlzCiBtZXRob2QgYWdhaW4gdXNpbmcg
dGhlIHZhbHVlIG9mIGBuZXh0X3BhZ2VfdG9rZW5gIGFzIGBwYWdlX3Rva2VuYC4KCg0KBQQC
AgEFEgSrAQIICg0KBQQCAgEBEgSrAQkYCg0KBQQCAgEDEgSrARscCqYCCgQEAgICEgSxAQIi
GpcCIFVucmVhY2hhYmxlIHJlc291cmNlcy4gUG9wdWxhdGVkIHdoZW4gdGhlIHJlcXVlc3Qg
b3B0cyBpbnRvCiBbcmV0dXJuX3BhcnRpYWxfc3VjY2Vzc11bZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZXJ2aWNlcy52MS5MaXN0RW5kcG9pbnRQb2xpY2llc1JlcXVlc3QucmV0dXJuX3BhcnRp
YWxfc3VjY2Vzc10KIGFuZCByZWFkaW5nIGFjcm9zcyBjb2xsZWN0aW9ucyBlLmcuIHdoZW4K
IGF0dGVtcHRpbmcgdG8gbGlzdCBhbGwgcmVzb3VyY2VzIGFjcm9zcyBhbGwgc3VwcG9ydGVk
IGxvY2F0aW9ucy4KCg0KBQQCAgIEEgSxAQIKCg0KBQQCAgIFEgSxAQsRCg0KBQQCAgIBEgSx
ARIdCg0KBQQCAgIDEgSxASAhCj8KAgQDEga1AQC+AQEaMSBSZXF1ZXN0IHVzZWQgd2l0aCB0
aGUgR2V0RW5kcG9pbnRQb2xpY3kgbWV0aG9kLgoKCwoDBAMBEgS1AQggCoQBCgQEAwIAEga4
AQK9AQQadCBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBFbmRwb2ludFBvbGljeSB0byBnZXQu
IE11c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovZW5kcG9p
bnRQb2xpY2llcy8qYC4KCg0KBQQDAgAFEgS4AQIICg0KBQQDAgABEgS4AQkNCg0KBQQDAgAD
EgS4ARARCg8KBQQDAgAIEga4ARK9AQMKEAoIBAMCAAicCAASBLkBBCoKEQoHBAMCAAifCBIG
ugEEvAEFCkIKAgQEEgbBAQDRAQEaNCBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgQ3JlYXRlRW5k
cG9pbnRQb2xpY3kgbWV0aG9kLgoKCwoDBAQBEgTBAQgjCncKBAQEAgASBsQBAskBBBpnIFJl
cXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBFbmRwb2ludFBvbGljeS4gTXVz
dCBiZSBpbiB0aGUKIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKmAuCgoNCgUEBAIA
BRIExAECCAoNCgUEBAIAARIExAEJDwoNCgUEBAIAAxIExAESEwoPCgUEBAIACBIGxAEUyQED
ChAKCAQEAgAInAgAEgTFAQQqChEKBwQEAgAInwgSBsYBBMgBBQplCgQEBAIBEgTNAQJJGlcg
UmVxdWlyZWQuIFNob3J0IG5hbWUgb2YgdGhlIEVuZHBvaW50UG9saWN5IHJlc291cmNlIHRv
IGJlIGNyZWF0ZWQuCiBFLmcuICJDdXN0b21FQ1MiLgoKDQoFBAQCAQUSBM0BAggKDQoFBAQC
AQESBM0BCRsKDQoFBAQCAQMSBM0BHh8KDQoFBAQCAQgSBM0BIEgKEAoIBAQCAQicCAASBM0B
IUcKQAoEBAQCAhIE0AECThoyIFJlcXVpcmVkLiBFbmRwb2ludFBvbGljeSByZXNvdXJjZSB0
byBiZSBjcmVhdGVkLgoKDQoFBAQCAgYSBNABAhAKDQoFBAQCAgESBNABESAKDQoFBAQCAgMS
BNABIyQKDQoFBAQCAggSBNABJU0KEAoIBAQCAgicCAASBNABJkwKQgoCBAUSBtQBAN8BARo0
IFJlcXVlc3QgdXNlZCB3aXRoIHRoZSBVcGRhdGVFbmRwb2ludFBvbGljeSBtZXRob2QuCgoL
CgMEBQESBNQBCCMK4AIKBAQFAgASBtoBAtsBLxrPAiBPcHRpb25hbC4gRmllbGQgbWFzayBp
cyB1c2VkIHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUK
IEVuZHBvaW50UG9saWN5IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNw
ZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJj
ZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4g
aWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92aWRlIGEg
bWFzayB0aGVuIGFsbCBmaWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCg0KBQQFAgAGEgTa
AQIbCg0KBQQFAgABEgTaARwnCg0KBQQFAgADEgTaASorCg0KBQQFAgAIEgTbAQYuChAKCAQF
AgAInAgAEgTbAQctCjoKBAQFAgESBN4BAk4aLCBSZXF1aXJlZC4gVXBkYXRlZCBFbmRwb2lu
dFBvbGljeSByZXNvdXJjZS4KCg0KBQQFAgEGEgTeAQIQCg0KBQQFAgEBEgTeAREgCg0KBQQF
AgEDEgTeASMkCg0KBQQFAgEIEgTeASVNChAKCAQFAgEInAgAEgTeASZMCkIKAgQGEgbiAQDr
AQEaNCBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgRGVsZXRlRW5kcG9pbnRQb2xpY3kgbWV0aG9k
LgoKCwoDBAYBEgTiAQgjCocBCgQEBgIAEgblAQLqAQQadyBSZXF1aXJlZC4gQSBuYW1lIG9m
IHRoZSBFbmRwb2ludFBvbGljeSB0byBkZWxldGUuIE11c3QgYmUgaW4gdGhlIGZvcm1hdAog
YHByb2plY3RzLyovbG9jYXRpb25zLyovZW5kcG9pbnRQb2xpY2llcy8qYC4KCg0KBQQGAgAF
EgTlAQIICg0KBQQGAgABEgTlAQkNCg0KBQQGAgADEgTlARARCg8KBQQGAgAIEgblARLqAQMK
EAoIBAYCAAicCAASBOYBBCoKEQoHBAYCAAifCBIG5wEE6QEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy ===
    # Fields for EndpointPolicy
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy.LabelsEntry)
    # Field: type Type: 14 (.google.cloud.networkservices.v1.EndpointPolicy.EndpointPolicyType)
    # Field: authorization_policy Type: 9 ()
    # Field: endpoint_matcher Type: 11 (.google.cloud.networkservices.v1.EndpointMatcher)
    # Field: traffic_port_selector Type: 11 (.google.cloud.networkservices.v1.TrafficPortSelector)
    # Field: description Type: 9 ()
    # Field: server_tls_policy Type: 9 ()
    # Field: client_tls_policy Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<labels>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy.LabelsEntry)

=item * B<type>

Type: Enum (.google.cloud.networkservices.v1.EndpointPolicy.EndpointPolicyType)

=item * B<authorization_policy>

Type: String

=item * B<endpoint_matcher>

Type: Message (.google.cloud.networkservices.v1.EndpointMatcher)

=item * B<traffic_port_selector>

Type: Message (.google.cloud.networkservices.v1.TrafficPortSelector)

=item * B<description>

Type: String

=item * B<server_tls_policy>

Type: String

=item * B<client_tls_policy>

Type: String

=back

=cut

# Enum: EndpointPolicy::EndpointPolicyType
our $EndpointPolicy_ENDPOINT_POLICY_TYPE_UNSPECIFIED = 0;
our $EndpointPolicy_SIDECAR_PROXY = 1;
our $EndpointPolicy_GRPC_SERVER = 2;

=pod

=head2 Enum: EndpointPolicy::EndpointPolicyType

Values:

=over 4

=item * C<ENDPOINT_POLICY_TYPE_UNSPECIFIED> => 0

=item * C<SIDECAR_PROXY> => 1

=item * C<GRPC_SERVER> => 2

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest ===
    # Fields for ListEndpointPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: return_partial_success Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<return_partial_success>

Type: Bool

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse ===
    # Fields for ListEndpointPoliciesResponse
    # Field: endpoint_policies Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse->new(
        endpoint_policies => $value,
    );

=head1 FIELDS

=over 4

=item * B<endpoint_policies>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest ===
    # Fields for GetEndpointPolicyRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest ===
    # Fields for CreateEndpointPolicyRequest
    # Field: parent Type: 9 ()
    # Field: endpoint_policy_id Type: 9 ()
    # Field: endpoint_policy Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<endpoint_policy_id>

Type: String

=item * B<endpoint_policy>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest ===
    # Fields for UpdateEndpointPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: endpoint_policy Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<endpoint_policy>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest ===
    # Fields for DeleteEndpointPolicyRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
