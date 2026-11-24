package Google::Cloud::Notebooks::V1::Execution;

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
Cilnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL2V4ZWN1dGlvbi5wcm90bxIZZ29vZ2xlLmNs
b3VkLm5vdGVib29rcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
byKODwoRRXhlY3V0aW9uVGVtcGxhdGUSXAoKc2NhbGVfdGllchgBIAEoDjI2Lmdvb2dsZS5j
bG91ZC5ub3RlYm9va3MudjEuRXhlY3V0aW9uVGVtcGxhdGUuU2NhbGVUaWVyQgUYAeBBAlIJ
c2NhbGVUaWVyEh8KC21hc3Rlcl90eXBlGAIgASgJUgptYXN0ZXJUeXBlEnYKEmFjY2VsZXJh
dG9yX2NvbmZpZxgDIAEoCzJHLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuRXhlY3V0aW9u
VGVtcGxhdGUuU2NoZWR1bGVyQWNjZWxlcmF0b3JDb25maWdSEWFjY2VsZXJhdG9yQ29uZmln
ElAKBmxhYmVscxgEIAMoCzI4Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuRXhlY3V0aW9u
VGVtcGxhdGUuTGFiZWxzRW50cnlSBmxhYmVscxIuChNpbnB1dF9ub3RlYm9va19maWxlGAUg
ASgJUhFpbnB1dE5vdGVib29rRmlsZRIuChNjb250YWluZXJfaW1hZ2VfdXJpGAYgASgJUhFj
b250YWluZXJJbWFnZVVyaRI0ChZvdXRwdXRfbm90ZWJvb2tfZm9sZGVyGAcgASgJUhRvdXRw
dXROb3RlYm9va0ZvbGRlchIoChBwYXJhbXNfeWFtbF9maWxlGAggASgJUg5wYXJhbXNZYW1s
RmlsZRIeCgpwYXJhbWV0ZXJzGAkgASgJUgpwYXJhbWV0ZXJzEicKD3NlcnZpY2VfYWNjb3Vu
dBgKIAEoCVIOc2VydmljZUFjY291bnQSTwoIam9iX3R5cGUYCyABKA4yNC5nb29nbGUuY2xv
dWQubm90ZWJvb2tzLnYxLkV4ZWN1dGlvblRlbXBsYXRlLkpvYlR5cGVSB2pvYlR5cGUScgoT
ZGF0YXByb2NfcGFyYW1ldGVycxgMIAEoCzI/Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEu
RXhlY3V0aW9uVGVtcGxhdGUuRGF0YXByb2NQYXJhbWV0ZXJzSABSEmRhdGFwcm9jUGFyYW1l
dGVycxJzChR2ZXJ0ZXhfYWlfcGFyYW1ldGVycxgNIAEoCzI/Lmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjEuRXhlY3V0aW9uVGVtcGxhdGUuVmVydGV4QUlQYXJhbWV0ZXJzSABSEnZlcnRl
eEFpUGFyYW1ldGVycxIfCgtrZXJuZWxfc3BlYxgOIAEoCVIKa2VybmVsU3BlYxJMCgt0ZW5z
b3Jib2FyZBgPIAEoCUIq+kEnCiVhaXBsYXRmb3JtLmdvb2dsZWFwaXMuY29tL1RlbnNvcmJv
YXJkUgt0ZW5zb3Jib2FyZBqWAQoaU2NoZWR1bGVyQWNjZWxlcmF0b3JDb25maWcSWQoEdHlw
ZRgBIAEoDjJFLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuRXhlY3V0aW9uVGVtcGxhdGUu
U2NoZWR1bGVyQWNjZWxlcmF0b3JUeXBlUgR0eXBlEh0KCmNvcmVfY291bnQYAiABKANSCWNv
cmVDb3VudBouChJEYXRhcHJvY1BhcmFtZXRlcnMSGAoHY2x1c3RlchgBIAEoCVIHY2x1c3Rl
chrCAQoSVmVydGV4QUlQYXJhbWV0ZXJzEhgKB25ldHdvcmsYASABKAlSB25ldHdvcmsSWgoD
ZW52GAIgAygLMkguZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MS5FeGVjdXRpb25UZW1wbGF0
ZS5WZXJ0ZXhBSVBhcmFtZXRlcnMuRW52RW50cnlSA2Vudho2CghFbnZFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGjkKC0xhYmVsc0VudHJ5EhAK
A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiewoJU2NhbGVUaWVy
EhoKFlNDQUxFX1RJRVJfVU5TUEVDSUZJRUQQABIJCgVCQVNJQxABEg4KClNUQU5EQVJEXzEQ
AhINCglQUkVNSVVNXzEQAxINCglCQVNJQ19HUFUQBBINCglCQVNJQ19UUFUQBRIKCgZDVVNU
T00QBiLjAQoYU2NoZWR1bGVyQWNjZWxlcmF0b3JUeXBlEioKJlNDSEVEVUxFUl9BQ0NFTEVS
QVRPUl9UWVBFX1VOU1BFQ0lGSUVEEAASFAoQTlZJRElBX1RFU0xBX0s4MBABEhUKEU5WSURJ
QV9URVNMQV9QMTAwEAISFQoRTlZJRElBX1RFU0xBX1YxMDAQAxITCg9OVklESUFfVEVTTEFf
UDQQBBITCg9OVklESUFfVEVTTEFfVDQQBRIVChFOVklESUFfVEVTTEFfQTEwMBAKEgoKBlRQ
VV9WMhAGEgoKBlRQVV9WMxAHIkAKB0pvYlR5cGUSGAoUSk9CX1RZUEVfVU5TUEVDSUZJRUQQ
ABINCglWRVJURVhfQUkQARIMCghEQVRBUFJPQxACQhAKDmpvYl9wYXJhbWV0ZXJzIvAFCglF
eGVjdXRpb24SWwoSZXhlY3V0aW9uX3RlbXBsYXRlGAEgASgLMiwuZ29vZ2xlLmNsb3VkLm5v
dGVib29rcy52MS5FeGVjdXRpb25UZW1wbGF0ZVIRZXhlY3V0aW9uVGVtcGxhdGUSFwoEbmFt
ZRgCIAEoCUID4EEDUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgDIAEoCUID4EEDUgtkaXNwbGF5
TmFtZRIgCgtkZXNjcmlwdGlvbhgEIAEoCVILZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUY
BSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSRQoFc3RhdGUYByABKA4yKi5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLkV4
ZWN1dGlvbi5TdGF0ZUID4EEDUgVzdGF0ZRIwChRvdXRwdXRfbm90ZWJvb2tfZmlsZRgIIAEo
CVISb3V0cHV0Tm90ZWJvb2tGaWxlEhwKB2pvYl91cmkYCSABKAlCA+BBA1IGam9iVXJpIp8B
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBlFVRVVFRBABEg0KCVBSRVBBUklO
RxACEgsKB1JVTk5JTkcQAxINCglTVUNDRUVERUQQBBIKCgZGQUlMRUQQBRIOCgpDQU5DRUxM
SU5HEAYSDQoJQ0FOQ0VMTEVEEAcSCwoHRVhQSVJFRBAJEhAKDElOSVRJQUxJWklORxAKOmbq
QWMKIm5vdGVib29rcy5nb29nbGVhcGlzLmNvbS9FeGVjdXRpb24SPXByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbi97bG9jYXRpb259L2V4ZWN1dGlvbnMve2V4ZWN1dGlvbn1C3AEKHWNv
bS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxQg5FeGVjdXRpb25Qcm90b1ABWjtjbG91ZC5n
b29nbGUuY29tL2dvL25vdGVib29rcy9hcGl2MS9ub3RlYm9va3NwYjtub3RlYm9va3NwYupB
awolYWlwbGF0Zm9ybS5nb29nbGVhcGlzLmNvbS9UZW5zb3Jib2FyZBJCcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3RlbnNvcmJvYXJkcy97dGVuc29yYm9hcmR9
SpJeCgcSBQ4A3QIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAiCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAUgoJCgIICxID
FgBSCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALwoJCgIICBIDGAAvCggKAQgSAxkA
NgoJCgIIARIDGQA2CgkKAQgSBBoAHQIKDAoECJ0IABIEGgAdAgo9CgIEABIFIACTAgEaMCBU
aGUgZGVzY3JpcHRpb24gYSBub3RlYm9vayBleGVjdXRpb24gd29ya2xvYWQuCgoKCgMEAAES
AyAIGQpxCgQEAAQAEgQjAj8DGmMgUmVxdWlyZWQuIFNwZWNpZmllcyB0aGUgbWFjaGluZSB0
eXBlcywgdGhlIG51bWJlciBvZiByZXBsaWNhcyBmb3Igd29ya2VycwogYW5kIHBhcmFtZXRl
ciBzZXJ2ZXJzLgoKDAoFBAAEAAESAyMHEAooCgYEAAQAAgASAyUEHxoZIFVuc3BlY2lmaWVk
IFNjYWxlIFRpZXIuCgoOCgcEAAQAAgABEgMlBBoKDgoHBAAEAAIAAhIDJR0eCqABCgYEAAQA
AgESAykEDhqQASBBIHNpbmdsZSB3b3JrZXIgaW5zdGFuY2UuIFRoaXMgdGllciBpcyBzdWl0
YWJsZSBmb3IgbGVhcm5pbmcgaG93IHRvIHVzZQogQ2xvdWQgTUwsIGFuZCBmb3IgZXhwZXJp
bWVudGluZyB3aXRoIG5ldyBtb2RlbHMgdXNpbmcgc21hbGwgZGF0YXNldHMuCgoOCgcEAAQA
AgEBEgMpBAkKDgoHBAAEAAIBAhIDKQwNCjoKBgQABAACAhIDLAQTGisgTWFueSB3b3JrZXJz
IGFuZCBhIGZldyBwYXJhbWV0ZXIgc2VydmVycy4KCg4KBwQABAACAgESAywEDgoOCgcEAAQA
AgICEgMsERIKRwoGBAAEAAIDEgMvBBIaOCBBIGxhcmdlIG51bWJlciBvZiB3b3JrZXJzIHdp
dGggbWFueSBwYXJhbWV0ZXIgc2VydmVycy4KCg4KBwQABAACAwESAy8EDQoOCgcEAAQAAgMC
EgMvEBEKOQoGBAAEAAIEEgMyBBIaKiBBIHNpbmdsZSB3b3JrZXIgaW5zdGFuY2Ugd2l0aCBh
IEs4MCBHUFUuCgoOCgcEAAQAAgQBEgMyBA0KDgoHBAAEAAIEAhIDMhARCjsKBgQABAACBRID
NQQSGiwgQSBzaW5nbGUgd29ya2VyIGluc3RhbmNlIHdpdGggYSBDbG91ZCBUUFUuCgoOCgcE
AAQAAgUBEgM1BA0KDgoHBAAEAAIFAhIDNRARCvgCCgYEAAQAAgYSAz4EDxroAiBUaGUgQ1VT
VE9NIHRpZXIgaXMgbm90IGEgc2V0IHRpZXIsIGJ1dCByYXRoZXIgZW5hYmxlcyB5b3UgdG8g
dXNlIHlvdXIKIG93biBjbHVzdGVyIHNwZWNpZmljYXRpb24uIFdoZW4geW91IHVzZSB0aGlz
IHRpZXIsIHNldCB2YWx1ZXMgdG8KIGNvbmZpZ3VyZSB5b3VyIHByb2Nlc3NpbmcgY2x1c3Rl
ciBhY2NvcmRpbmcgdG8gdGhlc2UgZ3VpZGVsaW5lczoKCiAqICAgWW91IF9tdXN0XyBzZXQg
YEV4ZWN1dGlvblRlbXBsYXRlLm1hc3RlclR5cGVgIHRvIHNwZWNpZnkgdGhlIHR5cGUKICAg
ICBvZiBtYWNoaW5lIHRvIHVzZSBmb3IgeW91ciBtYXN0ZXIgbm9kZS4gVGhpcyBpcyB0aGUg
b25seSByZXF1aXJlZAogICAgIHNldHRpbmcuCgoOCgcEAAQAAgYBEgM+BAoKDgoHBAAEAAIG
AhIDPg0OCkkKBAQABAESBEICXQMaOyBIYXJkd2FyZSBhY2NlbGVyYXRvciB0eXBlcyBmb3Ig
QUkgUGxhdGZvcm0gVHJhaW5pbmcgam9icy4KCgwKBQQABAEBEgNCBx8KQQoGBAAEAQIAEgNE
BC8aMiBVbnNwZWNpZmllZCBhY2NlbGVyYXRvciB0eXBlLiBEZWZhdWx0IHRvIG5vIEdQVS4K
Cg4KBwQABAECAAESA0QEKgoOCgcEAAQBAgACEgNELS4KJgoGBAAEAQIBEgNHBBkaFyBOdmlk
aWEgVGVzbGEgSzgwIEdQVS4KCg4KBwQABAECAQESA0cEFAoOCgcEAAQBAgECEgNHFxgKJwoG
BAAEAQICEgNKBBoaGCBOdmlkaWEgVGVzbGEgUDEwMCBHUFUuCgoOCgcEAAQBAgIBEgNKBBUK
DgoHBAAEAQICAhIDShgZCicKBgQABAECAxIDTQQaGhggTnZpZGlhIFRlc2xhIFYxMDAgR1BV
LgoKDgoHBAAEAQIDARIDTQQVCg4KBwQABAECAwISA00YGQolCgYEAAQBAgQSA1AEGBoWIE52
aWRpYSBUZXNsYSBQNCBHUFUuCgoOCgcEAAQBAgQBEgNQBBMKDgoHBAAEAQIEAhIDUBYXCiUK
BgQABAECBRIDUwQYGhYgTnZpZGlhIFRlc2xhIFQ0IEdQVS4KCg4KBwQABAECBQESA1MEEwoO
CgcEAAQBAgUCEgNTFhcKJwoGBAAEAQIGEgNWBBsaGCBOdmlkaWEgVGVzbGEgQTEwMCBHUFUu
CgoOCgcEAAQBAgYBEgNWBBUKDgoHBAAEAQIGAhIDVhgaChgKBgQABAECBxIDWQQPGgkgVFBV
IHYyLgoKDgoHBAAEAQIHARIDWQQKCg4KBwQABAECBwISA1kNDgoYCgYEAAQBAggSA1wEDxoJ
IFRQVSB2My4KCg4KBwQABAECCAESA1wECgoOCgcEAAQBAggCEgNcDQ4K/gEKBAQAAwASBGMC
aQMa7wEgRGVmaW5pdGlvbiBvZiBhIGhhcmR3YXJlIGFjY2VsZXJhdG9yLiBOb3RlIHRoYXQg
bm90IGFsbCBjb21iaW5hdGlvbnMKIG9mIGB0eXBlYCBhbmQgYGNvcmVfY291bnRgIGFyZSB2
YWxpZC4gQ2hlY2sgW0dQVXMgb24KIENvbXB1dGUgRW5naW5lXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vY29tcHV0ZS9kb2NzL2dwdXMpIHRvIGZpbmQgYSB2YWxpZAogY29tYmluYXRp
b24uIFRQVXMgYXJlIG5vdCBzdXBwb3J0ZWQuCgoMCgUEAAMAARIDYwokCioKBgQAAwACABID
ZQQmGhsgVHlwZSBvZiB0aGlzIGFjY2VsZXJhdG9yLgoKDgoHBAADAAIABhIDZQQcCg4KBwQA
AwACAAESA2UdIQoOCgcEAAMAAgADEgNlJCUKNAoGBAADAAIBEgNoBBkaJSBDb3VudCBvZiBj
b3JlcyBvZiB0aGlzIGFjY2VsZXJhdG9yLgoKDgoHBAADAAIBBRIDaAQJCg4KBwQAAwACAQES
A2gKFAoOCgcEAAMAAgEDEgNoFxgKNAoEBAAEAhIEbAJ3AxomIFRoZSBiYWNrZW5kIHVzZWQg
Zm9yIHRoaXMgZXhlY3V0aW9uLgoKDAoFBAAEAgESA2wHDgojCgYEAAQCAgASA24EHRoUIE5v
IHR5cGUgc3BlY2lmaWVkLgoKDgoHBAAEAgIAARIDbgQYCg4KBwQABAICAAISA24bHApcCgYE
AAQCAgESA3IEEhpNIEN1c3RvbSBKb2IgaW4gYGFpcGxhdGZvcm0uZ29vZ2xlYXBpcy5jb21g
LgogRGVmYXVsdCB2YWx1ZSBmb3IgYW4gZXhlY3V0aW9uLgoKDgoHBAAEAgIBARIDcgQNCg4K
BwQABAICAQISA3IQEQqUAQoGBAAEAgICEgN2BBEahAEgUnVuIGV4ZWN1dGlvbiBvbiBhIGNs
dXN0ZXIgd2l0aCBEYXRhcHJvYyBhcyBhIGpvYi4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9kYXRhcHJvYy9kb2NzL3JlZmVyZW5jZS9yZXN0L3YxL3Byb2plY3RzLnJlZ2lvbnMuam9i
cwoKDgoHBAAEAgICARIDdgQMCg4KBwQABAICAgISA3YPEAo/CgQEAAMBEgR6An4DGjEgUGFy
YW1ldGVycyB1c2VkIGluIERhdGFwcm9jIEpvYlR5cGUgZXhlY3V0aW9ucy4KCgwKBQQAAwEB
EgN6ChwKigEKBgQAAwECABIDfQQXGnsgVVJJIGZvciBjbHVzdGVyIHVzZWQgdG8gcnVuIERh
dGFwcm9jIGV4ZWN1dGlvbi4KIEZvcm1hdDogYHByb2plY3RzL3tQUk9KRUNUX0lEfS9yZWdp
b25zL3tSRUdJT059L2NsdXN0ZXJzL3tDTFVTVEVSX05BTUV9YAoKDgoHBAADAQIABRIDfQQK
Cg4KBwQAAwECAAESA30LEgoOCgcEAAMBAgADEgN9FRYKQgoEBAADAhIGgQECkwEDGjIgUGFy
YW1ldGVycyB1c2VkIGluIFZlcnRleCBBSSBKb2JUeXBlIGV4ZWN1dGlvbnMuCgoNCgUEAAMC
ARIEgQEKHArUBAoGBAADAgIAEgSNAQQXGsMEIFRoZSBmdWxsIG5hbWUgb2YgdGhlIENvbXB1
dGUgRW5naW5lCiBbbmV0d29ya10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUv
ZG9jcy9uZXR3b3Jrcy1hbmQtZmlyZXdhbGxzI25ldHdvcmtzKQogdG8gd2hpY2ggdGhlIEpv
YiBzaG91bGQgYmUgcGVlcmVkLiBGb3IgZXhhbXBsZSwKIGBwcm9qZWN0cy8xMjM0NS9nbG9i
YWwvbmV0d29ya3MvbXlWUENgLgogW0Zvcm1hdF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L2NvbXB1dGUvZG9jcy9yZWZlcmVuY2UvcmVzdC92MS9uZXR3b3Jrcy9pbnNlcnQpCiBpcyBv
ZiB0aGUgZm9ybSBgcHJvamVjdHMve3Byb2plY3R9L2dsb2JhbC9uZXR3b3Jrcy97bmV0d29y
a31gLgogV2hlcmUgYHtwcm9qZWN0fWAgaXMgYSBwcm9qZWN0IG51bWJlciwgYXMgaW4gYDEy
MzQ1YCwgYW5kIGB7bmV0d29ya31gIGlzCiBhIG5ldHdvcmsgbmFtZS4KCiBQcml2YXRlIHNl
cnZpY2VzIGFjY2VzcyBtdXN0IGFscmVhZHkgYmUgY29uZmlndXJlZCBmb3IgdGhlIG5ldHdv
cmsuIElmCiBsZWZ0IHVuc3BlY2lmaWVkLCB0aGUgam9iIGlzIG5vdCBwZWVyZWQgd2l0aCBh
bnkgbmV0d29yay4KCg8KBwQAAwICAAUSBI0BBAoKDwoHBAADAgIAARIEjQELEgoPCgcEAAMC
AgADEgSNARUWCpgBCgYEAAMCAgESBJIBBCAahwEgRW52aXJvbm1lbnQgdmFyaWFibGVzLgog
QXQgbW9zdCAxMDAgZW52aXJvbm1lbnQgdmFyaWFibGVzIGNhbiBiZSBzcGVjaWZpZWQgYW5k
IHVuaXF1ZS4KIEV4YW1wbGU6IGBHQ1BfQlVDS0VUPWdzOi8vbXktYnVja2V0L3NhbXBsZXMv
YAoKDwoHBAADAgIBBhIEkgEEFwoPCgcEAAMCAgEBEgSSARgbCg8KBwQAAwICAQMSBJIBHh8K
nQEKBAQAAgASBpcBApoBBBqMASBSZXF1aXJlZC4gU2NhbGUgdGllciBvZiB0aGUgaGFyZHdh
cmUgdXNlZCBmb3Igbm90ZWJvb2sgZXhlY3V0aW9uLgogREVQUkVDQVRFRCBXaWxsIGJlIGRp
c2NvbnRpbnVlZC4gQXMgcmlnaHQgbm93IG9ubHkgQ1VTVE9NIGlzIHN1cHBvcnRlZC4KCg0K
BQQAAgAGEgSXAQILCg0KBQQAAgABEgSXAQwWCg0KBQQAAgADEgSXARkaCg8KBQQAAgAIEgaX
ARuaAQMKDgoGBAACAAgDEgSYAQQVChAKCAQAAgAInAgAEgSZAQQqCs8JCgQEAAIBEgTMAQIZ
GsAJIFNwZWNpZmllcyB0aGUgdHlwZSBvZiB2aXJ0dWFsIG1hY2hpbmUgdG8gdXNlIGZvciB5
b3VyIHRyYWluaW5nCiBqb2IncyBtYXN0ZXIgd29ya2VyLiBZb3UgbXVzdCBzcGVjaWZ5IHRo
aXMgZmllbGQgd2hlbiBgc2NhbGVUaWVyYCBpcyBzZXQgdG8KIGBDVVNUT01gLgoKIFlvdSBj
YW4gdXNlIGNlcnRhaW4gQ29tcHV0ZSBFbmdpbmUgbWFjaGluZSB0eXBlcyBkaXJlY3RseSBp
biB0aGlzIGZpZWxkLgogVGhlIGZvbGxvd2luZyB0eXBlcyBhcmUgc3VwcG9ydGVkOgoKIC0g
YG4xLXN0YW5kYXJkLTRgCiAtIGBuMS1zdGFuZGFyZC04YAogLSBgbjEtc3RhbmRhcmQtMTZg
CiAtIGBuMS1zdGFuZGFyZC0zMmAKIC0gYG4xLXN0YW5kYXJkLTY0YAogLSBgbjEtc3RhbmRh
cmQtOTZgCiAtIGBuMS1oaWdobWVtLTJgCiAtIGBuMS1oaWdobWVtLTRgCiAtIGBuMS1oaWdo
bWVtLThgCiAtIGBuMS1oaWdobWVtLTE2YAogLSBgbjEtaGlnaG1lbS0zMmAKIC0gYG4xLWhp
Z2htZW0tNjRgCiAtIGBuMS1oaWdobWVtLTk2YAogLSBgbjEtaGlnaGNwdS0xNmAKIC0gYG4x
LWhpZ2hjcHUtMzJgCiAtIGBuMS1oaWdoY3B1LTY0YAogLSBgbjEtaGlnaGNwdS05NmAKCgog
QWx0ZXJuYXRpdmVseSwgeW91IGNhbiB1c2UgdGhlIGZvbGxvd2luZyBsZWdhY3kgbWFjaGlu
ZSB0eXBlczoKCiAtIGBzdGFuZGFyZGAKIC0gYGxhcmdlX21vZGVsYAogLSBgY29tcGxleF9t
b2RlbF9zYAogLSBgY29tcGxleF9tb2RlbF9tYAogLSBgY29tcGxleF9tb2RlbF9sYAogLSBg
c3RhbmRhcmRfZ3B1YAogLSBgY29tcGxleF9tb2RlbF9tX2dwdWAKIC0gYGNvbXBsZXhfbW9k
ZWxfbF9ncHVgCiAtIGBzdGFuZGFyZF9wMTAwYAogLSBgY29tcGxleF9tb2RlbF9tX3AxMDBg
CiAtIGBzdGFuZGFyZF92MTAwYAogLSBgbGFyZ2VfbW9kZWxfdjEwMGAKIC0gYGNvbXBsZXhf
bW9kZWxfbV92MTAwYAogLSBgY29tcGxleF9tb2RlbF9sX3YxMDBgCgoKIEZpbmFsbHksIGlm
IHlvdSB3YW50IHRvIHVzZSBhIFRQVSBmb3IgdHJhaW5pbmcsIHNwZWNpZnkgYGNsb3VkX3Rw
dWAgaW4gdGhpcwogZmllbGQuIExlYXJuIG1vcmUgYWJvdXQgdGhlIFtzcGVjaWFsIGNvbmZp
Z3VyYXRpb24gb3B0aW9ucyBmb3IgdHJhaW5pbmcKIHdpdGgKIFRQVV0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2FpLXBsYXRmb3JtL3RyYWluaW5nL2RvY3MvdXNpbmctdHB1cyNjb25m
aWd1cmluZ19hX2N1c3RvbV90cHVfbWFjaGluZSkuCgoNCgUEAAIBBRIEzAECCAoNCgUEAAIB
ARIEzAEJFAoNCgUEAAIBAxIEzAEXGApkCgQEAAICEgTQAQI0GlYgQ29uZmlndXJhdGlvbiAo
Y291bnQgYW5kIGFjY2VsZXJhdG9yIHR5cGUpIGZvciBoYXJkd2FyZSBydW5uaW5nIG5vdGVi
b29rCiBleGVjdXRpb24uCgoNCgUEAAICBhIE0AECHAoNCgUEAAICARIE0AEdLwoNCgUEAAIC
AxIE0AEyMwqMAgoEBAACAxIE1wECIRr9ASBMYWJlbHMgZm9yIGV4ZWN1dGlvbi4KIElmIGV4
ZWN1dGlvbiBpcyBzY2hlZHVsZWQsIGEgZmllbGQgaW5jbHVkZWQgd2lsbCBiZSAnbmJzLXNj
aGVkdWxlZCcuCiBPdGhlcndpc2UsIGl0IGlzIGFuIGltbWVkaWF0ZSBleGVjdXRpb24sIGFu
ZCBhbiBpbmNsdWRlZCBmaWVsZCB3aWxsIGJlCiAnbmJzLWltbWVkaWF0ZScuIFVzZSBmaWVs
ZHMgdG8gZWZmaWNpZW50bHkgaW5kZXggYmV0d2VlbiB2YXJpb3VzIHR5cGVzIG9mCiBleGVj
dXRpb25zLgoKDQoFBAACAwYSBNcBAhUKDQoFBAACAwESBNcBFhwKDQoFBAACAwMSBNcBHyAK
5AEKBAQAAgQSBN0BAiEa1QEgUGF0aCB0byB0aGUgbm90ZWJvb2sgZmlsZSB0byBleGVjdXRl
LgogTXVzdCBiZSBpbiBhIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGJ1Y2tldC4KIEZvcm1hdDog
YGdzOi8ve2J1Y2tldF9uYW1lfS97Zm9sZGVyfS97bm90ZWJvb2tfZmlsZV9uYW1lfWAKIEV4
OiBgZ3M6Ly9ub3RlYm9va191c2VyL3NjaGVkdWxlZF9ub3RlYm9va3Mvc2VudGltZW50X25v
dGVib29rLmlweW5iYAoKDQoFBAACBAUSBN0BAggKDQoFBAACBAESBN0BCRwKDQoFBAACBAMS
BN0BHyAK4QEKBAQAAgUSBOMBAiEa0gEgQ29udGFpbmVyIEltYWdlIFVSSSB0byBhIERMVk0K
IEV4YW1wbGU6ICdnY3IuaW8vZGVlcGxlYXJuaW5nLXBsYXRmb3JtLXJlbGVhc2UvYmFzZS1j
dTEwMCcKIE1vcmUgZXhhbXBsZXMgY2FuIGJlIGZvdW5kIGF0OgogaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2FpLXBsYXRmb3JtL2RlZXAtbGVhcm5pbmctY29udGFpbmVycy9kb2NzL2No
b29zaW5nLWNvbnRhaW5lcgoKDQoFBAACBQUSBOMBAggKDQoFBAACBQESBOMBCRwKDQoFBAAC
BQMSBOMBHyAKvgEKBAQAAgYSBOkBAiQarwEgUGF0aCB0byB0aGUgbm90ZWJvb2sgZm9sZGVy
IHRvIHdyaXRlIHRvLgogTXVzdCBiZSBpbiBhIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGJ1Y2tl
dCBwYXRoLgogRm9ybWF0OiBgZ3M6Ly97YnVja2V0X25hbWV9L3tmb2xkZXJ9YAogRXg6IGBn
czovL25vdGVib29rX3VzZXIvc2NoZWR1bGVkX25vdGVib29rc2AKCg0KBQQAAgYFEgTpAQII
Cg0KBQQAAgYBEgTpAQkfCg0KBQQAAgYDEgTpASIjCr8CCgQEAAIHEgTwAQIeGrACIFBhcmFt
ZXRlcnMgdG8gYmUgb3ZlcnJpZGRlbiBpbiB0aGUgbm90ZWJvb2sgZHVyaW5nIGV4ZWN1dGlv
bi4KIFJlZiBodHRwczovL3BhcGVybWlsbC5yZWFkdGhlZG9jcy5pby9lbi9sYXRlc3QvdXNh
Z2UtcGFyYW1ldGVyaXplLmh0bWwgb24KIGhvdyB0byBzcGVjaWZ5aW5nIHBhcmFtZXRlcnMg
aW4gdGhlIGlucHV0IG5vdGVib29rIGFuZCBwYXNzIHRoZW0gaGVyZQogaW4gYW4gWUFNTCBm
aWxlLgogRXg6IGBnczovL25vdGVib29rX3VzZXIvc2NoZWR1bGVkX25vdGVib29rcy9zZW50
aW1lbnRfbm90ZWJvb2tfcGFyYW1zLnlhbWxgCgoNCgUEAAIHBRIE8AECCAoNCgUEAAIHARIE
8AEJGQoNCgUEAAIHAxIE8AEcHQpKCgQEAAIIEgTzAQIYGjwgUGFyYW1ldGVycyB1c2VkIHdp
dGhpbiB0aGUgJ2lucHV0X25vdGVib29rX2ZpbGUnIG5vdGVib29rLgoKDQoFBAACCAUSBPMB
AggKDQoFBAACCAESBPMBCRMKDQoFBAACCAMSBPMBFhcKuAEKBAQAAgkSBPgBAh4aqQEgVGhl
IGVtYWlsIGFkZHJlc3Mgb2YgYSBzZXJ2aWNlIGFjY291bnQgdG8gdXNlIHdoZW4gcnVubmlu
ZyB0aGUgZXhlY3V0aW9uLgogWW91IG11c3QgaGF2ZSB0aGUgYGlhbS5zZXJ2aWNlQWNjb3Vu
dHMuYWN0QXNgIHBlcm1pc3Npb24gZm9yIHRoZSBzcGVjaWZpZWQKIHNlcnZpY2UgYWNjb3Vu
dC4KCg0KBQQAAgkFEgT4AQIICg0KBQQAAgkBEgT4AQkYCg0KBQQAAgkDEgT4ARsdCj0KBAQA
AgoSBPsBAhgaLyBUaGUgdHlwZSBvZiBKb2IgdG8gYmUgdXNlZCBvbiB0aGlzIGV4ZWN1dGlv
bi4KCg0KBQQAAgoGEgT7AQIJCg0KBQQAAgoBEgT7AQoSCg0KBQQAAgoDEgT7ARUXCnUKBAQA
CAASBv8BAoUCAxplIFBhcmFtZXRlcnMgZm9yIGFuIGV4ZWN1dGlvbiB0eXBlLgogTk9URTog
VGhlcmUgYXJlIGN1cnJlbnRseSBubyBleHRyYSBwYXJhbWV0ZXJzIGZvciBWZXJ0ZXhBSSBq
b2JzLgoKDQoFBAAIAAESBP8BCBYKPwoEBAACCxIEgQIEMBoxIFBhcmFtZXRlcnMgdXNlZCBp
biBEYXRhcHJvYyBKb2JUeXBlIGV4ZWN1dGlvbnMuCgoNCgUEAAILBhIEgQIEFgoNCgUEAAIL
ARIEgQIXKgoNCgUEAAILAxIEgQItLwpACgQEAAIMEgSEAgQxGjIgUGFyYW1ldGVycyB1c2Vk
IGluIFZlcnRleCBBSSBKb2JUeXBlIGV4ZWN1dGlvbnMuCgoNCgUEAAIMBhIEhAIEFgoNCgUE
AAIMARIEhAIXKwoNCgUEAAIMAxIEhAIuMAqtAQoEBAACDRIEigICGhqeASBOYW1lIG9mIHRo
ZSBrZXJuZWwgc3BlYyB0byB1c2UuIFRoaXMgbXVzdCBiZSBzcGVjaWZpZWQgaWYgdGhlCiBr
ZXJuZWwgc3BlYyBuYW1lIG9uIHRoZSBleGVjdXRpb24gdGFyZ2V0IGRvZXMgbm90IG1hdGNo
IHRoZSBuYW1lIGluIHRoZQogaW5wdXQgbm90ZWJvb2sgZmlsZS4KCg0KBQQAAg0FEgSKAgII
Cg0KBQQAAg0BEgSKAgkUCg0KBQQAAg0DEgSKAhcZCscBCgQEAAIOEgaQAgKSAh4atgEgVGhl
IG5hbWUgb2YgYSBWZXJ0ZXggQUkgW1RlbnNvcmJvYXJkXSByZXNvdXJjZSB0byB3aGljaCB0
aGlzIGV4ZWN1dGlvbgogd2lsbCB1cGxvYWQgVGVuc29yYm9hcmQgbG9ncy4KIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdGVuc29yYm9hcmRz
L3t0ZW5zb3Jib2FyZH1gCgoNCgUEAAIOBRIEkAICCAoNCgUEAAIOARIEkAIJFAoNCgUEAAIO
AxIEkAIXGQoPCgUEAAIOCBIGkAIakgIdChEKBwQAAg4InwgSBpACG5ICHAo9CgIEARIGlgIA
3QIBGi8gVGhlIGRlZmluaXRpb24gb2YgYSBzaW5nbGUgZXhlY3V0ZWQgbm90ZWJvb2suCgoL
CgMEAQESBJYCCBEKDQoDBAEHEgaXAgKaAgQKDwoFBAEHnQgSBpcCApoCBApKCgQEAQQAEgad
AgK/AgMaOiBFbnVtIGRlc2NyaXB0aW9uIG9mIHRoZSBzdGF0ZSBvZiB0aGUgdW5kZXJseWlu
ZyBBSVAgam9iLgoKDQoFBAEEAAESBJ0CBwwKLwoGBAEEAAIAEgSfAgQaGh8gVGhlIGpvYiBz
dGF0ZSBpcyB1bnNwZWNpZmllZC4KCg8KBwQBBAACAAESBJ8CBBUKDwoHBAEEAAIAAhIEnwIY
GQpRCgYEAQQAAgESBKICBA8aQSBUaGUgam9iIGhhcyBiZWVuIGp1c3QgY3JlYXRlZCBhbmQg
cHJvY2Vzc2luZyBoYXMgbm90IHlldCBiZWd1bi4KCg8KBwQBBAACAQESBKICBAoKDwoHBAEE
AAIBAhIEogINDgpACgYEAQQAAgISBKUCBBIaMCBUaGUgc2VydmljZSBpcyBwcmVwYXJpbmcg
dG8gZXhlY3V0aW9uIHRoZSBqb2IuCgoPCgcEAQQAAgIBEgSlAgQNCg8KBwQBBAACAgISBKUC
EBEKKQoGBAEEAAIDEgSoAgQQGhkgVGhlIGpvYiBpcyBpbiBwcm9ncmVzcy4KCg8KBwQBBAAC
AwESBKgCBAsKDwoHBAEEAAIDAhIEqAIODwoxCgYEAQQAAgQSBKsCBBIaISBUaGUgam9iIGNv
bXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoPCgcEAQQAAgQBEgSrAgQNCg8KBwQBBAACBAISBKsC
EBEKXQoGBAEEAAIFEgSvAgQPGk0gVGhlIGpvYiBmYWlsZWQuCiBgZXJyb3JfbWVzc2FnZWAg
c2hvdWxkIGNvbnRhaW4gdGhlIGRldGFpbHMgb2YgdGhlIGZhaWx1cmUuCgoPCgcEAQQAAgUB
EgSvAgQKCg8KBwQBBAACBQISBK8CDQ4KbwoGBAEEAAIGEgSzAgQTGl8gVGhlIGpvYiBpcyBi
ZWluZyBjYW5jZWxsZWQuCiBgZXJyb3JfbWVzc2FnZWAgc2hvdWxkIGRlc2NyaWJlIHRoZSBy
ZWFzb24gZm9yIHRoZSBjYW5jZWxsYXRpb24uCgoPCgcEAQQAAgYBEgSzAgQOCg8KBwQBBAAC
BgISBLMCERIKbwoGBAEEAAIHEgS3AgQSGl8gVGhlIGpvYiBoYXMgYmVlbiBjYW5jZWxsZWQu
CiBgZXJyb3JfbWVzc2FnZWAgc2hvdWxkIGRlc2NyaWJlIHRoZSByZWFzb24gZm9yIHRoZSBj
YW5jZWxsYXRpb24uCgoPCgcEAQQAAgcBEgS3AgQNCg8KBwQBBAACBwISBLcCEBEKjQEKBgQB
BAACCBIEuwIEEBp9IFRoZSBqb2IgaGFzIGJlY29tZSBleHBpcmVkIChyZWxldmFudCB0byBW
ZXJ0ZXggQUkgam9icykKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS92ZXJ0ZXgtYWkvZG9j
cy9yZWZlcmVuY2UvcmVzdC92MS9Kb2JTdGF0ZQoKDwoHBAEEAAIIARIEuwIECwoPCgcEAQQA
AggCEgS7Ag4PCjEKBgQBBAACCRIEvgIEFhohIFRoZSBFeGVjdXRpb24gaXMgYmVpbmcgY3Jl
YXRlZC4KCg8KBwQBBAACCQESBL4CBBAKDwoHBAEEAAIJAhIEvgITFQpUCgQEAQIAEgTCAgIr
GkYgZXhlY3V0ZSBtZXRhZGF0YSBpbmNsdWRpbmcgbmFtZSwgaGFyZHdhcmUgc3BlYywgcmVn
aW9uLCBsYWJlbHMsIGV0Yy4KCg0KBQQBAgAGEgTCAgITCg0KBQQBAgABEgTCAhQmCg0KBQQB
AgADEgTCAikqCo8BCgQEAQIBEgTGAgI+GoABIE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZXhlY3V0ZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9leGVjdXRpb25zL3tleGVjdXRpb25faWR9YAoKDQoFBAEC
AQUSBMYCAggKDQoFBAECAQESBMYCCQ0KDQoFBAECAQMSBMYCEBEKDQoFBAECAQgSBMYCEj0K
EAoIBAECAQicCAASBMYCEzwKewoEBAECAhIEygICRhptIE91dHB1dCBvbmx5LiBOYW1lIHVz
ZWQgZm9yIFVJIHB1cnBvc2VzLgogTmFtZSBjYW4gb25seSBjb250YWluIGFscGhhbnVtZXJp
YyBjaGFyYWN0ZXJzIGFuZCB1bmRlcnNjb3JlcyAnXycuCgoNCgUEAQICBRIEygICCAoNCgUE
AQICARIEygIJFQoNCgUEAQICAxIEygIYGQoNCgUEAQICCBIEygIaRQoQCggEAQICCJwIABIE
ygIbRAo2CgQEAQIDEgTNAgIZGiggQSBicmllZiBkZXNjcmlwdGlvbiBvZiB0aGlzIGV4ZWN1
dGlvbi4KCg0KBQQBAgMFEgTNAgIICg0KBQQBAgMBEgTNAgkUCg0KBQQBAgMDEgTNAhcYCkEK
BAQBAgQSBNACAlgaMyBPdXRwdXQgb25seS4gVGltZSB0aGUgRXhlY3V0aW9uIHdhcyBpbnN0
YW50aWF0ZWQuCgoNCgUEAQIEBhIE0AICGwoNCgUEAQIEARIE0AIcJwoNCgUEAQIEAxIE0AIq
KwoNCgUEAQIECBIE0AIsVwoQCggEAQIECJwIABIE0AItVgpBCgQEAQIFEgTTAgJYGjMgT3V0
cHV0IG9ubHkuIFRpbWUgdGhlIEV4ZWN1dGlvbiB3YXMgbGFzdCB1cGRhdGVkLgoKDQoFBAEC
BQYSBNMCAhsKDQoFBAECBQESBNMCHCcKDQoFBAECBQMSBNMCKisKDQoFBAECBQgSBNMCLFcK
EAoIBAECBQicCAASBNMCLVYKRQoEBAECBhIE1gICPho3IE91dHB1dCBvbmx5LiBTdGF0ZSBv
ZiB0aGUgdW5kZXJseWluZyBBSSBQbGF0Zm9ybSBqb2IuCgoNCgUEAQIGBhIE1gICBwoNCgUE
AQIGARIE1gIIDQoNCgUEAQIGAxIE1gIQEQoNCgUEAQIGCBIE1gISPQoQCggEAQIGCJwIABIE
1gITPApACgQEAQIHEgTZAgIiGjIgT3V0cHV0IG5vdGVib29rIGZpbGUgZ2VuZXJhdGVkIGJ5
IHRoaXMgZXhlY3V0aW9uCgoNCgUEAQIHBRIE2QICCAoNCgUEAQIHARIE2QIJHQoNCgUEAQIH
AxIE2QIgIQpWCgQEAQIIEgTcAgJBGkggT3V0cHV0IG9ubHkuIFRoZSBVUkkgb2YgdGhlIGV4
dGVybmFsIGpvYiB1c2VkIHRvIGV4ZWN1dGUgdGhlIG5vdGVib29rLgoKDQoFBAECCAUSBNwC
AggKDQoFBAECCAESBNwCCRAKDQoFBAECCAMSBNwCExQKDQoFBAECCAgSBNwCFUAKEAoIBAEC
CAicCAASBNwCFj9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate ===
    # Fields for ExecutionTemplate
    # Field: scale_tier Type: 14 (.google.cloud.notebooks.v1.ExecutionTemplate.ScaleTier)
    # Field: master_type Type: 9 ()
    # Field: accelerator_config Type: 11 (.google.cloud.notebooks.v1.ExecutionTemplate.SchedulerAcceleratorConfig)
    # Field: labels Type: 11 (.google.cloud.notebooks.v1.ExecutionTemplate.LabelsEntry)
    # Field: input_notebook_file Type: 9 ()
    # Field: container_image_uri Type: 9 ()
    # Field: output_notebook_folder Type: 9 ()
    # Field: params_yaml_file Type: 9 ()
    # Field: parameters Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: job_type Type: 14 (.google.cloud.notebooks.v1.ExecutionTemplate.JobType)
    # Field: dataproc_parameters Type: 11 (.google.cloud.notebooks.v1.ExecutionTemplate.DataprocParameters)
    # Field: vertex_ai_parameters Type: 11 (.google.cloud.notebooks.v1.ExecutionTemplate.VertexAIParameters)
    # Field: kernel_spec Type: 9 ()
    # Field: tensorboard Type: 9 ()

# Enum: ExecutionTemplate::ScaleTier
our $ExecutionTemplate_SCALE_TIER_UNSPECIFIED = 0;
our $ExecutionTemplate_BASIC = 1;
our $ExecutionTemplate_STANDARD_1 = 2;
our $ExecutionTemplate_PREMIUM_1 = 3;
our $ExecutionTemplate_BASIC_GPU = 4;
our $ExecutionTemplate_BASIC_TPU = 5;
our $ExecutionTemplate_CUSTOM = 6;

# Enum: ExecutionTemplate::SchedulerAcceleratorType
our $ExecutionTemplate_SCHEDULER_ACCELERATOR_TYPE_UNSPECIFIED = 0;
our $ExecutionTemplate_NVIDIA_TESLA_K80 = 1;
our $ExecutionTemplate_NVIDIA_TESLA_P100 = 2;
our $ExecutionTemplate_NVIDIA_TESLA_V100 = 3;
our $ExecutionTemplate_NVIDIA_TESLA_P4 = 4;
our $ExecutionTemplate_NVIDIA_TESLA_T4 = 5;
our $ExecutionTemplate_NVIDIA_TESLA_A100 = 10;
our $ExecutionTemplate_TPU_V2 = 6;
our $ExecutionTemplate_TPU_V3 = 7;

# Enum: ExecutionTemplate::JobType
our $ExecutionTemplate_JOB_TYPE_UNSPECIFIED = 0;
our $ExecutionTemplate_VERTEX_AI = 1;
our $ExecutionTemplate_DATAPROC = 2;

# === Message: Google::Cloud::Notebooks::V1::Execution::Execution ===
    # Fields for Execution
    # Field: execution_template Type: 11 (.google.cloud.notebooks.v1.ExecutionTemplate)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.notebooks.v1.Execution.State)
    # Field: output_notebook_file Type: 9 ()
    # Field: job_uri Type: 9 ()

# Enum: Execution::State
our $Execution_STATE_UNSPECIFIED = 0;
our $Execution_QUEUED = 1;
our $Execution_PREPARING = 2;
our $Execution_RUNNING = 3;
our $Execution_SUCCEEDED = 4;
our $Execution_FAILED = 5;
our $Execution_CANCELLING = 6;
our $Execution_CANCELLED = 7;
our $Execution_EXPIRED = 9;
our $Execution_INITIALIZING = 10;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::Execution - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/execution.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::Execution;

    my $msg = Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate->new({
        scale_tier => $scale_tier,
        master_type => $master_type,
        accelerator_config => $accelerator_config,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->scale_tier();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/execution.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate

The description a notebook execution workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scale_tier() >> / C<< $msg->scale_tier($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1::ExecutionTemplate::ScaleTier>)

Required. Scale tier of the hardware used for notebook execution.
DEPRECATED Will be discontinued. As right now only CUSTOM is supported.

=item * C<< $msg->master_type() >> / C<< $msg->master_type($value) >>

Type: C<String>

Specifies the type of virtual machine to use for your training
job's master worker. You must specify this field when `scaleTier` is set to
`CUSTOM`.

You can use certain Compute Engine machine types directly in this field.
The following types are supported:

- `n1-standard-4`
- `n1-standard-8`
- `n1-standard-16`
- `n1-standard-32`
- `n1-standard-64`
- `n1-standard-96`
- `n1-highmem-2`
- `n1-highmem-4`
- `n1-highmem-8`
- `n1-highmem-16`
- `n1-highmem-32`
- `n1-highmem-64`
- `n1-highmem-96`
- `n1-highcpu-16`
- `n1-highcpu-32`
- `n1-highcpu-64`
- `n1-highcpu-96`


Alternatively, you can use the following legacy machine types:

- `standard`
- `large_model`
- `complex_model_s`
- `complex_model_m`
- `complex_model_l`
- `standard_gpu`
- `complex_model_m_gpu`
- `complex_model_l_gpu`
- `standard_p100`
- `complex_model_m_p100`
- `standard_v100`
- `large_model_v100`
- `complex_model_m_v100`
- `complex_model_l_v100`


Finally, if you want to use a TPU for training, specify `cloud_tpu` in this
field. Learn more about the [special configuration options for training
with
TPU](https://cloud.google.com/ai-platform/training/docs/using-tpus#configuring_a_custom_tpu_machine).

=item * C<< $msg->accelerator_config() >> / C<< $msg->accelerator_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::SchedulerAcceleratorConfig>)

Configuration (count and accelerator type) for hardware running notebook
execution.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::LabelsEntry>)

Labels for execution.
If execution is scheduled, a field included will be 'nbs-scheduled'.
Otherwise, it is an immediate execution, and an included field will be
'nbs-immediate'. Use fields to efficiently index between various types of
executions.

=item * C<< $msg->input_notebook_file() >> / C<< $msg->input_notebook_file($value) >>

Type: C<String>

Path to the notebook file to execute.
Must be in a Google Cloud Storage bucket.
Format: `gs://{bucket_name}/{folder}/{notebook_file_name}`
Ex: `gs://notebook_user/scheduled_notebooks/sentiment_notebook.ipynb`

=item * C<< $msg->container_image_uri() >> / C<< $msg->container_image_uri($value) >>

Type: C<String>

Container Image URI to a DLVM
Example: 'gcr.io/deeplearning-platform-release/base-cu100'
More examples can be found at:
https://cloud.google.com/ai-platform/deep-learning-containers/docs/choosing-container

=item * C<< $msg->output_notebook_folder() >> / C<< $msg->output_notebook_folder($value) >>

Type: C<String>

Path to the notebook folder to write to.
Must be in a Google Cloud Storage bucket path.
Format: `gs://{bucket_name}/{folder}`
Ex: `gs://notebook_user/scheduled_notebooks`

=item * C<< $msg->params_yaml_file() >> / C<< $msg->params_yaml_file($value) >>

Type: C<String>

Parameters to be overridden in the notebook during execution.
Ref https://papermill.readthedocs.io/en/latest/usage-parameterize.html on
how to specifying parameters in the input notebook and pass them here
in an YAML file.
Ex: `gs://notebook_user/scheduled_notebooks/sentiment_notebook_params.yaml`

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<String>

Parameters used within the 'input_notebook_file' notebook.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

The email address of a service account to use when running the execution.
You must have the `iam.serviceAccounts.actAs` permission for the specified
service account.

=item * C<< $msg->job_type() >> / C<< $msg->job_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1::ExecutionTemplate::JobType>)

The type of Job to be used on this execution.

=item * C<< $msg->dataproc_parameters() >> / C<< $msg->dataproc_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::DataprocParameters>)

Parameters used in Dataproc JobType executions.

=item * C<< $msg->vertex_ai_parameters() >> / C<< $msg->vertex_ai_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters>)

Parameters used in Vertex AI JobType executions.

=item * C<< $msg->kernel_spec() >> / C<< $msg->kernel_spec($value) >>

Type: C<String>

Name of the kernel spec to use. This must be specified if the
kernel spec name on the execution target does not match the name in the
input notebook file.

=item * C<< $msg->tensorboard() >> / C<< $msg->tensorboard($value) >>

Type: C<String>

The name of a Vertex AI [Tensorboard] resource to which this execution
will upload Tensorboard logs.
Format:
`projects/{project}/locations/{location}/tensorboards/{tensorboard}`

=back

=head3 Enum: ExecutionTemplate::ScaleTier

=over 4

=item * C<SCALE_TIER_UNSPECIFIED> => C<0>

=item * C<BASIC> => C<1>

=item * C<STANDARD_1> => C<2>

=item * C<PREMIUM_1> => C<3>

=item * C<BASIC_GPU> => C<4>

=item * C<BASIC_TPU> => C<5>

=item * C<CUSTOM> => C<6>

=back

=head3 Enum: ExecutionTemplate::SchedulerAcceleratorType

=over 4

=item * C<SCHEDULER_ACCELERATOR_TYPE_UNSPECIFIED> => C<0>

=item * C<NVIDIA_TESLA_K80> => C<1>

=item * C<NVIDIA_TESLA_P100> => C<2>

=item * C<NVIDIA_TESLA_V100> => C<3>

=item * C<NVIDIA_TESLA_P4> => C<4>

=item * C<NVIDIA_TESLA_T4> => C<5>

=item * C<NVIDIA_TESLA_A100> => C<10>

=item * C<TPU_V2> => C<6>

=item * C<TPU_V3> => C<7>

=back

=head3 Enum: ExecutionTemplate::JobType

=over 4

=item * C<JOB_TYPE_UNSPECIFIED> => C<0>

=item * C<VERTEX_AI> => C<1>

=item * C<DATAPROC> => C<2>

=back

=head2 Google::Cloud::Notebooks::V1::Execution::Execution

The definition of a single executed notebook.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->execution_template() >> / C<< $msg->execution_template($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate>)

execute metadata including name, hardware spec, region, labels, etc.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the execute. Format:
`projects/{project_id}/locations/{location}/executions/{execution_id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Name used for UI purposes.
Name can only contain alphanumeric characters and underscores '_'.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A brief description of this execution.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the Execution was instantiated.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the Execution was last updated.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1::Execution::State>)

Output only. State of the underlying AI Platform job.

=item * C<< $msg->output_notebook_file() >> / C<< $msg->output_notebook_file($value) >>

Type: C<String>

Output notebook file generated by this execution

=item * C<< $msg->job_uri() >> / C<< $msg->job_uri($value) >>

Type: C<String>

Output only. The URI of the external job used to execute the notebook.

=back

=head3 Enum: Execution::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<QUEUED> => C<1>

=item * C<PREPARING> => C<2>

=item * C<RUNNING> => C<3>

=item * C<SUCCEEDED> => C<4>

=item * C<FAILED> => C<5>

=item * C<CANCELLING> => C<6>

=item * C<CANCELLED> => C<7>

=item * C<EXPIRED> => C<9>

=item * C<INITIALIZING> => C<10>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::Execution::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
