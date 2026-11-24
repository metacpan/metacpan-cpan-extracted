package Google::Cloud::Scheduler::V1::Target;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvc2NoZWR1bGVyL3YxL3RhcmdldC5wcm90bxIZZ29vZ2xlLmNsb3Vk
LnNjaGVkdWxlci52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKtAwoKSHR0cFRhcmdl
dBIQCgN1cmkYASABKAlSA3VyaRJGCgtodHRwX21ldGhvZBgCIAEoDjIlLmdvb2dsZS5jbG91
ZC5zY2hlZHVsZXIudjEuSHR0cE1ldGhvZFIKaHR0cE1ldGhvZBJMCgdoZWFkZXJzGAMgAygL
MjIuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5IdHRwVGFyZ2V0LkhlYWRlcnNFbnRyeVIH
aGVhZGVycxISCgRib2R5GAQgASgMUgRib2R5EkgKC29hdXRoX3Rva2VuGAUgASgLMiUuZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MS5PQXV0aFRva2VuSABSCm9hdXRoVG9rZW4SRQoKb2lk
Y190b2tlbhgGIAEoCzIkLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuT2lkY1Rva2VuSABS
CW9pZGNUb2tlbho6CgxIZWFkZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4AUIWChRhdXRob3JpemF0aW9uX2hlYWRlciKCAwoTQXBwRW5naW5l
SHR0cFRhcmdldBJGCgtodHRwX21ldGhvZBgBIAEoDjIlLmdvb2dsZS5jbG91ZC5zY2hlZHVs
ZXIudjEuSHR0cE1ldGhvZFIKaHR0cE1ldGhvZBJZChJhcHBfZW5naW5lX3JvdXRpbmcYAiAB
KAsyKy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkFwcEVuZ2luZVJvdXRpbmdSEGFwcEVu
Z2luZVJvdXRpbmcSIQoMcmVsYXRpdmVfdXJpGAMgASgJUgtyZWxhdGl2ZVVyaRJVCgdoZWFk
ZXJzGAQgAygLMjsuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5BcHBFbmdpbmVIdHRwVGFy
Z2V0LkhlYWRlcnNFbnRyeVIHaGVhZGVycxISCgRib2R5GAUgASgMUgRib2R5GjoKDEhlYWRl
cnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIvsB
CgxQdWJzdWJUYXJnZXQSPwoKdG9waWNfbmFtZRgBIAEoCUIg+kEdChtwdWJzdWIuZ29vZ2xl
YXBpcy5jb20vVG9waWNSCXRvcGljTmFtZRISCgRkYXRhGAMgASgMUgRkYXRhElcKCmF0dHJp
YnV0ZXMYBCADKAsyNy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLlB1YnN1YlRhcmdldC5B
dHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0ZXMaPQoPQXR0cmlidXRlc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEidgoQQXBwRW5naW5lUm91dGlu
ZxIYCgdzZXJ2aWNlGAEgASgJUgdzZXJ2aWNlEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24S
GgoIaW5zdGFuY2UYAyABKAlSCGluc3RhbmNlEhIKBGhvc3QYBCABKAlSBGhvc3QiVgoKT0F1
dGhUb2tlbhIyChVzZXJ2aWNlX2FjY291bnRfZW1haWwYASABKAlSE3NlcnZpY2VBY2NvdW50
RW1haWwSFAoFc2NvcGUYAiABKAlSBXNjb3BlIlsKCU9pZGNUb2tlbhIyChVzZXJ2aWNlX2Fj
Y291bnRfZW1haWwYASABKAlSE3NlcnZpY2VBY2NvdW50RW1haWwSGgoIYXVkaWVuY2UYAiAB
KAlSCGF1ZGllbmNlKnMKCkh0dHBNZXRob2QSGwoXSFRUUF9NRVRIT0RfVU5TUEVDSUZJRUQQ
ABIICgRQT1NUEAESBwoDR0VUEAISCAoESEVBRBADEgcKA1BVVBAEEgoKBkRFTEVURRAFEgkK
BVBBVENIEAYSCwoHT1BUSU9OUxAHQq4BCh1jb20uZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52
MUILVGFyZ2V0UHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9zY2hlZHVsZXIvYXBpdjEv
c2NoZWR1bGVycGI7c2NoZWR1bGVycGLqQUAKG3B1YnN1Yi5nb29nbGVhcGlzLmNvbS9Ub3Bp
YxIhcHJvamVjdHMve3Byb2plY3R9L3RvcGljcy97dG9waWN9SoN4CgcSBQ4A/QIBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACMKCAoB
CBIDFABSCgkKAggLEgMUAFIKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAsCgkKAggI
EgMWACwKCAoBCBIDFwA2CgkKAggBEgMXADYKCQoBCBIEGAAbAgoMCgQInQgAEgQYABsCCr0D
CgIEABIEJABzARqwAyBIdHRwIHRhcmdldC4gVGhlIGpvYiB3aWxsIGJlIHB1c2hlZCB0byB0
aGUgam9iIGhhbmRsZXIgYnkgbWVhbnMgb2YKIGFuIEhUVFAgcmVxdWVzdCB2aWEgYW4KIFto
dHRwX21ldGhvZF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5IdHRwVGFyZ2V0Lmh0dHBf
bWV0aG9kXSBzdWNoIGFzIEhUVFAKIFBPU1QsIEhUVFAgR0VULCBldGMuIFRoZSBqb2IgaXMg
YWNrbm93bGVkZ2VkIGJ5IG1lYW5zIG9mIGFuIEhUVFAKIHJlc3BvbnNlIGNvZGUgaW4gdGhl
IHJhbmdlIFsyMDAgLSAyOTldLiBBIGZhaWx1cmUgdG8gcmVjZWl2ZSBhIHJlc3BvbnNlCiBj
b25zdGl0dXRlcyBhIGZhaWxlZCBleGVjdXRpb24uIEZvciBhIHJlZGlyZWN0ZWQgcmVxdWVz
dCwgdGhlIHJlc3BvbnNlCiByZXR1cm5lZCBieSB0aGUgcmVkaXJlY3RlZCByZXF1ZXN0IGlz
IGNvbnNpZGVyZWQuCgoKCgMEAAESAyQIEgqmAwoEBAACABIDKwIRGpgDIFJlcXVpcmVkLiBU
aGUgZnVsbCBVUkkgcGF0aCB0aGF0IHRoZSByZXF1ZXN0IHdpbGwgYmUgc2VudCB0by4gVGhp
cyBzdHJpbmcKIG11c3QgYmVnaW4gd2l0aCBlaXRoZXIgImh0dHA6Ly8iIG9yICJodHRwczov
LyIuIFNvbWUgZXhhbXBsZXMgb2YKIHZhbGlkIHZhbHVlcyBmb3IgW3VyaV1bZ29vZ2xlLmNs
b3VkLnNjaGVkdWxlci52MS5IdHRwVGFyZ2V0LnVyaV0gYXJlOgogYGh0dHA6Ly9hY21lLmNv
bWAgYW5kIGBodHRwczovL2FjbWUuY29tL3NhbGVzOjgwODBgLiBDbG91ZCBTY2hlZHVsZXIg
d2lsbAogZW5jb2RlIHNvbWUgY2hhcmFjdGVycyBmb3Igc2FmZXR5IGFuZCBjb21wYXRpYmls
aXR5LiBUaGUgbWF4aW11bSBhbGxvd2VkCiBVUkwgbGVuZ3RoIGlzIDIwODMgY2hhcmFjdGVy
cyBhZnRlciBlbmNvZGluZy4KCgwKBQQAAgAFEgMrAggKDAoFBAACAAESAysJDAoMCgUEAAIA
AxIDKw8QCjgKBAQAAgESAy4CHRorIFdoaWNoIEhUVFAgbWV0aG9kIHRvIHVzZSBmb3IgdGhl
IHJlcXVlc3QuCgoMCgUEAAIBBhIDLgIMCgwKBQQAAgEBEgMuDRgKDAoFBAACAQMSAy4bHAq0
DAoEBAACAhIDUwIiGqYMIEhUVFAgcmVxdWVzdCBoZWFkZXJzLgoKIFRoaXMgbWFwIGNvbnRh
aW5zIHRoZSBoZWFkZXIgZmllbGQgbmFtZXMgYW5kIHZhbHVlcy4KCiBUaGUgdXNlciBjYW4g
c3BlY2lmeSBIVFRQIHJlcXVlc3QgaGVhZGVycyB0byBzZW5kIHdpdGggdGhlIGpvYidzCiBI
VFRQIHJlcXVlc3QuIFJlcGVhdGVkIGhlYWRlcnMgYXJlIG5vdCBzdXBwb3J0ZWQsIGJ1dCBh
IGhlYWRlciB2YWx1ZSBjYW4KIGNvbnRhaW4gY29tbWFzLgoKIFRoZSBmb2xsb3dpbmcgaGVh
ZGVycyByZXByZXNlbnQgYSBzdWJzZXQgb2YgdGhlIGhlYWRlcnMKIHRoYXQgYWNjb21wYW55
IHRoZSBqb2IncyBIVFRQIHJlcXVlc3QuIFNvbWUgSFRUUCByZXF1ZXN0CiBoZWFkZXJzIGFy
ZSBpZ25vcmVkIG9yIHJlcGxhY2VkLiBBIHBhcnRpYWwgbGlzdCBvZiBoZWFkZXJzIHRoYXQK
IGFyZSBpZ25vcmVkIG9yIHJlcGxhY2VkIGlzIGJlbG93OgoKICogSG9zdDogVGhpcyB3aWxs
IGJlIGNvbXB1dGVkIGJ5IENsb3VkIFNjaGVkdWxlciBhbmQgZGVyaXZlZCBmcm9tCiBbdXJp
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkh0dHBUYXJnZXQudXJpXS4KICogYENvbnRl
bnQtTGVuZ3RoYDogVGhpcyB3aWxsIGJlIGNvbXB1dGVkIGJ5IENsb3VkIFNjaGVkdWxlci4K
ICogYFVzZXItQWdlbnRgOiBUaGlzIHdpbGwgYmUgc2V0IHRvIGAiR29vZ2xlLUNsb3VkLVNj
aGVkdWxlciJgLgogKiBgWC1Hb29nbGUtKmA6IEdvb2dsZSBpbnRlcm5hbCB1c2Ugb25seS4K
ICogYFgtQXBwRW5naW5lLSpgOiBHb29nbGUgaW50ZXJuYWwgdXNlIG9ubHkuCiAqIGBYLUNs
b3VkU2NoZWR1bGVyYDogVGhpcyBoZWFkZXIgd2lsbCBiZSBzZXQgdG8gdHJ1ZS4KICogYFgt
Q2xvdWRTY2hlZHVsZXItSm9iTmFtZWA6IFRoaXMgaGVhZGVyIHdpbGwgY29udGFpbiB0aGUg
am9iIG5hbWUuCiAqIGBYLUNsb3VkU2NoZWR1bGVyLVNjaGVkdWxlVGltZWA6IEZvciBDbG91
ZCBTY2hlZHVsZXIgam9icyBzcGVjaWZpZWQgaW4KIHRoZSB1bml4LWNyb24gZm9ybWF0LCB0
aGlzIGhlYWRlciB3aWxsIGNvbnRhaW4gdGhlIGpvYiBzY2hlZHVsZSBhcyBhbgogb2Zmc2V0
IG9mIFVUQyBwYXJzZWQgYWNjb3JkaW5nIHRvIFJGQzMzMzkuCgogSWYgdGhlIGpvYiBoYXMg
YSBbYm9keV1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5IdHRwVGFyZ2V0LmJvZHldIGFu
ZCB0aGUKIGZvbGxvd2luZyBoZWFkZXJzIGFyZSBub3Qgc2V0IGJ5IHRoZSB1c2VyLCBDbG91
ZCBTY2hlZHVsZXIgc2V0cyBkZWZhdWx0CiB2YWx1ZXM6CgogKiBgQ29udGVudC1UeXBlYDog
VGhpcyB3aWxsIGJlIHNldCB0byBgImFwcGxpY2F0aW9uL29jdGV0LXN0cmVhbSJgLiBZb3UK
ICAgY2FuIG92ZXJyaWRlIHRoaXMgZGVmYXVsdCBieSBleHBsaWNpdGx5IHNldHRpbmcgYENv
bnRlbnQtVHlwZWAgdG8gYQogICBwYXJ0aWN1bGFyIG1lZGlhIHR5cGUgd2hlbiBjcmVhdGlu
ZyB0aGUgam9iLiBGb3IgZXhhbXBsZSwgeW91IGNhbiBzZXQKICAgYENvbnRlbnQtVHlwZWAg
dG8gYCJhcHBsaWNhdGlvbi9qc29uImAuCgogVGhlIHRvdGFsIHNpemUgb2YgaGVhZGVycyBt
dXN0IGJlIGxlc3MgdGhhbiA4MEtCLgoKDAoFBAACAgYSA1MCFQoMCgUEAAICARIDUxYdCgwK
BQQAAgIDEgNTICEK2wEKBAQAAgMSA1gCERrNASBIVFRQIHJlcXVlc3QgYm9keS4gQSByZXF1
ZXN0IGJvZHkgaXMgYWxsb3dlZCBvbmx5IGlmIHRoZSBIVFRQCiBtZXRob2QgaXMgUE9TVCwg
UFVULCBvciBQQVRDSC4gSXQgaXMgYW4gZXJyb3IgdG8gc2V0IGJvZHkgb24gYSBqb2Igd2l0
aCBhbgogaW5jb21wYXRpYmxlIFtIdHRwTWV0aG9kXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVy
LnYxLkh0dHBNZXRob2RdLgoKDAoFBAACAwUSA1gCBwoMCgUEAAIDARIDWAgMCgwKBQQAAgMD
EgNYDxAK5wEKBAQACAASBF8CcgMa2AEgVGhlIG1vZGUgZm9yIGdlbmVyYXRpbmcgYW4gYEF1
dGhvcml6YXRpb25gIGhlYWRlciBmb3IgSFRUUCByZXF1ZXN0cy4KCiBJZiBzcGVjaWZpZWQs
IGFsbCBgQXV0aG9yaXphdGlvbmAgaGVhZGVycyBpbiB0aGUKIFtIdHRwVGFyZ2V0LmhlYWRl
cnNdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuSHR0cFRhcmdldC5oZWFkZXJzXSBmaWVs
ZAogd2lsbCBiZSBvdmVycmlkZGVuLgoKDAoFBAAIAAESA18IHAqsAgoEBAACBBIDZwQfGp4C
IElmIHNwZWNpZmllZCwgYW4KIFtPQXV0aCB0b2tlbl0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdv
b2dsZS5jb20vaWRlbnRpdHkvcHJvdG9jb2xzL09BdXRoMikKIHdpbGwgYmUgZ2VuZXJhdGVk
IGFuZCBhdHRhY2hlZCBhcyBhbiBgQXV0aG9yaXphdGlvbmAgaGVhZGVyIGluIHRoZSBIVFRQ
CiByZXF1ZXN0LgoKIFRoaXMgdHlwZSBvZiBhdXRob3JpemF0aW9uIHNob3VsZCBnZW5lcmFs
bHkgb25seSBiZSB1c2VkIHdoZW4gY2FsbGluZwogR29vZ2xlIEFQSXMgaG9zdGVkIG9uICou
Z29vZ2xlYXBpcy5jb20uCgoMCgUEAAIEBhIDZwQOCgwKBQQAAgQBEgNnDxoKDAoFBAACBAMS
A2cdHgrbAgoEBAACBRIDcQQdGs0CIElmIHNwZWNpZmllZCwgYW4KIFtPSURDXShodHRwczov
L2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9pZGVudGl0eS9wcm90b2NvbHMvT3BlbklEQ29ubmVj
dCkKIHRva2VuIHdpbGwgYmUgZ2VuZXJhdGVkIGFuZCBhdHRhY2hlZCBhcyBhbiBgQXV0aG9y
aXphdGlvbmAgaGVhZGVyIGluIHRoZQogSFRUUCByZXF1ZXN0LgoKIFRoaXMgdHlwZSBvZiBh
dXRob3JpemF0aW9uIGNhbiBiZSB1c2VkIGZvciBtYW55IHNjZW5hcmlvcywgaW5jbHVkaW5n
CiBjYWxsaW5nIENsb3VkIFJ1biwgb3IgZW5kcG9pbnRzIHdoZXJlIHlvdSBpbnRlbmQgdG8g
dmFsaWRhdGUgdGhlIHRva2VuCiB5b3Vyc2VsZi4KCgwKBQQAAgUGEgNxBA0KDAoFBAACBQES
A3EOGAoMCgUEAAIFAxIDcRscCu0ECgIEARIFfwC7AQEa3wQgQXBwIEVuZ2luZSB0YXJnZXQu
IFRoZSBqb2Igd2lsbCBiZSBwdXNoZWQgdG8gYSBqb2IgaGFuZGxlciBieSBtZWFucwogb2Yg
YW4gSFRUUCByZXF1ZXN0IHZpYSBhbgogW2h0dHBfbWV0aG9kXVtnb29nbGUuY2xvdWQuc2No
ZWR1bGVyLnYxLkFwcEVuZ2luZUh0dHBUYXJnZXQuaHR0cF9tZXRob2RdIHN1Y2gKIGFzIEhU
VFAgUE9TVCwgSFRUUCBHRVQsIGV0Yy4gVGhlIGpvYiBpcyBhY2tub3dsZWRnZWQgYnkgbWVh
bnMgb2YgYW4KIEhUVFAgcmVzcG9uc2UgY29kZSBpbiB0aGUgcmFuZ2UgWzIwMCAtIDI5OV0u
IEVycm9yIDUwMyBpcwogY29uc2lkZXJlZCBhbiBBcHAgRW5naW5lIHN5c3RlbSBlcnJvciBp
bnN0ZWFkIG9mIGFuIGFwcGxpY2F0aW9uCiBlcnJvci4gUmVxdWVzdHMgcmV0dXJuaW5nIGVy
cm9yIDUwMyB3aWxsIGJlIHJldHJpZWQgcmVnYXJkbGVzcyBvZgogcmV0cnkgY29uZmlndXJh
dGlvbiBhbmQgbm90IGNvdW50ZWQgYWdhaW5zdCByZXRyeSBjb3VudHMuIEFueSBvdGhlcgog
cmVzcG9uc2UgY29kZSwgb3IgYSBmYWlsdXJlIHRvIHJlY2VpdmUgYSByZXNwb25zZSBiZWZv
cmUgdGhlCiBkZWFkbGluZSwgY29uc3RpdHV0ZXMgYSBmYWlsZWQgYXR0ZW1wdC4KCgoKAwQB
ARIDfwgbCl0KBAQBAgASBIIBAh0aTyBUaGUgSFRUUCBtZXRob2QgdG8gdXNlIGZvciB0aGUg
cmVxdWVzdC4gUEFUQ0ggYW5kIE9QVElPTlMgYXJlIG5vdAogcGVybWl0dGVkLgoKDQoFBAEC
AAYSBIIBAgwKDQoFBAECAAESBIIBDRgKDQoFBAECAAMSBIIBGxwKNwoEBAECARIEhQECKhop
IEFwcCBFbmdpbmUgUm91dGluZyBzZXR0aW5nIGZvciB0aGUgam9iLgoKDQoFBAECAQYSBIUB
AhIKDQoFBAECAQESBIUBEyUKDQoFBAECAQMSBIUBKCkKwgIKBAQBAgISBI0BAhoaswIgVGhl
IHJlbGF0aXZlIFVSSS4KCiBUaGUgcmVsYXRpdmUgVVJMIG11c3QgYmVnaW4gd2l0aCAiLyIg
YW5kIG11c3QgYmUgYSB2YWxpZCBIVFRQIHJlbGF0aXZlIFVSTC4KIEl0IGNhbiBjb250YWlu
IGEgcGF0aCwgcXVlcnkgc3RyaW5nIGFyZ3VtZW50cywgYW5kIGAjYCBmcmFnbWVudHMuCiBJ
ZiB0aGUgcmVsYXRpdmUgVVJMIGlzIGVtcHR5LCB0aGVuIHRoZSByb290IHBhdGggIi8iIHdp
bGwgYmUgdXNlZC4KIE5vIHNwYWNlcyBhcmUgYWxsb3dlZCwgYW5kIHRoZSBtYXhpbXVtIGxl
bmd0aCBhbGxvd2VkIGlzIDIwODMgY2hhcmFjdGVycy4KCg0KBQQBAgIFEgSNAQIICg0KBQQB
AgIBEgSNAQkVCg0KBQQBAgIDEgSNARgZCosMCgQEAQIDEgSyAQIiGvwLIEhUVFAgcmVxdWVz
dCBoZWFkZXJzLgoKIFRoaXMgbWFwIGNvbnRhaW5zIHRoZSBoZWFkZXIgZmllbGQgbmFtZXMg
YW5kIHZhbHVlcy4gSGVhZGVycyBjYW4gYmUgc2V0CiB3aGVuIHRoZSBqb2IgaXMgY3JlYXRl
ZC4KCiBDbG91ZCBTY2hlZHVsZXIgc2V0cyBzb21lIGhlYWRlcnMgdG8gZGVmYXVsdCB2YWx1
ZXM6CgogKiBgVXNlci1BZ2VudGA6IEJ5IGRlZmF1bHQsIHRoaXMgaGVhZGVyIGlzCiAgIGAi
QXBwRW5naW5lLUdvb2dsZTsgKCtodHRwOi8vY29kZS5nb29nbGUuY29tL2FwcGVuZ2luZSki
YC4KICAgVGhpcyBoZWFkZXIgY2FuIGJlIG1vZGlmaWVkLCBidXQgQ2xvdWQgU2NoZWR1bGVy
IHdpbGwgYXBwZW5kCiAgIGAiQXBwRW5naW5lLUdvb2dsZTsgKCtodHRwOi8vY29kZS5nb29n
bGUuY29tL2FwcGVuZ2luZSkiYCB0byB0aGUKICAgbW9kaWZpZWQgYFVzZXItQWdlbnRgLgog
KiBgWC1DbG91ZFNjaGVkdWxlcmA6IFRoaXMgaGVhZGVyIHdpbGwgYmUgc2V0IHRvIHRydWUu
CiAqIGBYLUNsb3VkU2NoZWR1bGVyLUpvYk5hbWVgOiBUaGlzIGhlYWRlciB3aWxsIGNvbnRh
aW4gdGhlIGpvYiBuYW1lLgogKiBgWC1DbG91ZFNjaGVkdWxlci1TY2hlZHVsZVRpbWVgOiBG
b3IgQ2xvdWQgU2NoZWR1bGVyIGpvYnMgc3BlY2lmaWVkIGluCiB0aGUgdW5peC1jcm9uIGZv
cm1hdCwgdGhpcyBoZWFkZXIgd2lsbCBjb250YWluIHRoZSBqb2Igc2NoZWR1bGUgYXMgYW4K
IG9mZnNldCBvZiBVVEMgcGFyc2VkIGFjY29yZGluZyB0byBSRkMzMzM5LgoKIElmIHRoZSBq
b2IgaGFzIGEgW2JvZHldW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQXBwRW5naW5lSHR0
cFRhcmdldC5ib2R5XQogYW5kIHRoZSBmb2xsb3dpbmcgaGVhZGVycyBhcmUgbm90IHNldCBi
eSB0aGUgdXNlciwgQ2xvdWQgU2NoZWR1bGVyIHNldHMKIGRlZmF1bHQgdmFsdWVzOgoKICog
YENvbnRlbnQtVHlwZWA6IFRoaXMgd2lsbCBiZSBzZXQgdG8gYCJhcHBsaWNhdGlvbi9vY3Rl
dC1zdHJlYW0iYC4gWW91CiAgIGNhbiBvdmVycmlkZSB0aGlzIGRlZmF1bHQgYnkgZXhwbGlj
aXRseSBzZXR0aW5nIGBDb250ZW50LVR5cGVgIHRvIGEKICAgcGFydGljdWxhciBtZWRpYSB0
eXBlIHdoZW4gY3JlYXRpbmcgdGhlIGpvYi4gRm9yIGV4YW1wbGUsIHlvdSBjYW4gc2V0CiAg
IGBDb250ZW50LVR5cGVgIHRvIGAiYXBwbGljYXRpb24vanNvbiJgLgoKIFRoZSBoZWFkZXJz
IGJlbG93IGFyZSBvdXRwdXQgb25seS4gVGhleSBjYW5ub3QgYmUgc2V0IG9yIG92ZXJyaWRk
ZW46CgogKiBgQ29udGVudC1MZW5ndGhgOiBUaGlzIGlzIGNvbXB1dGVkIGJ5IENsb3VkIFNj
aGVkdWxlci4KICogYFgtR29vZ2xlLSpgOiBGb3IgR29vZ2xlIGludGVybmFsIHVzZSBvbmx5
LgogKiBgWC1BcHBFbmdpbmUtKmA6IEZvciBHb29nbGUgaW50ZXJuYWwgdXNlIG9ubHkuCgog
SW4gYWRkaXRpb24sIHNvbWUgQXBwIEVuZ2luZSBoZWFkZXJzLCB3aGljaCBjb250YWluCiBq
b2Itc3BlY2lmaWMgaW5mb3JtYXRpb24sIGFyZSBhbHNvIGJlIHNlbnQgdG8gdGhlIGpvYiBo
YW5kbGVyLgoKDQoFBAECAwYSBLIBAhUKDQoFBAECAwESBLIBFh0KDQoFBAECAwMSBLIBICEK
+QEKBAQBAgQSBLoBAhEa6gEgQm9keS4KCiBIVFRQIHJlcXVlc3QgYm9keS4gQSByZXF1ZXN0
IGJvZHkgaXMgYWxsb3dlZCBvbmx5IGlmIHRoZSBIVFRQIG1ldGhvZCBpcwogUE9TVCBvciBQ
VVQuIEl0IHdpbGwgcmVzdWx0IGluIGludmFsaWQgYXJndW1lbnQgZXJyb3IgdG8gc2V0IGEg
Ym9keSBvbiBhCiBqb2Igd2l0aCBhbiBpbmNvbXBhdGlibGUKIFtIdHRwTWV0aG9kXVtnb29n
bGUuY2xvdWQuc2NoZWR1bGVyLnYxLkh0dHBNZXRob2RdLgoKDQoFBAECBAUSBLoBAgcKDQoF
BAECBAESBLoBCAwKDQoFBAECBAMSBLoBDxAKbgoCBAISBr8BANYBARpgIFB1Yi9TdWIgdGFy
Z2V0LiBUaGUgam9iIHdpbGwgYmUgZGVsaXZlcmVkIGJ5IHB1Ymxpc2hpbmcgYSBtZXNzYWdl
IHRvCiB0aGUgZ2l2ZW4gUHViL1N1YiB0b3BpYy4KCgsKAwQCARIEvwEIFAqmAwoEBAICABIG
xwECyQEEGpUDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgQ2xvdWQgUHViL1N1YiB0b3Bp
YyB0byB3aGljaCBtZXNzYWdlcyB3aWxsCiBiZSBwdWJsaXNoZWQgd2hlbiBhIGpvYiBpcyBk
ZWxpdmVyZWQuIFRoZSB0b3BpYyBuYW1lIG11c3QgYmUgaW4gdGhlCiBzYW1lIGZvcm1hdCBh
cyByZXF1aXJlZCBieSBQdWIvU3ViJ3MKIFtQdWJsaXNoUmVxdWVzdC5uYW1lXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vcHVic3ViL2RvY3MvcmVmZXJlbmNlL3JwYy9nb29nbGUucHVi
c3ViLnYxI3B1Ymxpc2hyZXF1ZXN0KSwKIGZvciBleGFtcGxlIGBwcm9qZWN0cy9QUk9KRUNU
X0lEL3RvcGljcy9UT1BJQ19JRGAuCgogVGhlIHRvcGljIG11c3QgYmUgaW4gdGhlIHNhbWUg
cHJvamVjdCBhcyB0aGUgQ2xvdWQgU2NoZWR1bGVyIGpvYi4KCg0KBQQCAgAFEgTHAQIICg0K
BQQCAgABEgTHAQkTCg0KBQQCAgADEgTHARYXCg8KBQQCAgAIEgbHARjJAQMKDwoHBAICAAif
CBIEyAEETQqHAQoEBAICARIEzwECERp5IFRoZSBtZXNzYWdlIHBheWxvYWQgZm9yIFB1YnN1
Yk1lc3NhZ2UuCgogUHVic3ViIG1lc3NhZ2UgbXVzdCBjb250YWluIGVpdGhlciBub24tZW1w
dHkgZGF0YSwgb3IgYXQgbGVhc3Qgb25lCiBhdHRyaWJ1dGUuCgoNCgUEAgIBBRIEzwECBwoN
CgUEAgIBARIEzwEIDAoNCgUEAgIBAxIEzwEPEAp+CgQEAgICEgTVAQIlGnAgQXR0cmlidXRl
cyBmb3IgUHVic3ViTWVzc2FnZS4KCiBQdWJzdWIgbWVzc2FnZSBtdXN0IGNvbnRhaW4gZWl0
aGVyIG5vbi1lbXB0eSBkYXRhLCBvciBhdCBsZWFzdCBvbmUKIGF0dHJpYnV0ZS4KCg0KBQQC
AgIGEgTVAQIVCg0KBQQCAgIBEgTVARYgCg0KBQQCAgIDEgTVASMkCsUECgIEAxIG4wEAvwIB
GrYEIEFwcCBFbmdpbmUgUm91dGluZy4KCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBhYm91dCBz
ZXJ2aWNlcywgdmVyc2lvbnMsIGFuZCBpbnN0YW5jZXMgc2VlCiBbQW4gT3ZlcnZpZXcgb2Yg
QXBwCiBFbmdpbmVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9w
eXRob24vYW4tb3ZlcnZpZXctb2YtYXBwLWVuZ2luZSksCiBbTWljcm9zZXJ2aWNlcyBBcmNo
aXRlY3R1cmUgb24gR29vZ2xlIEFwcAogRW5naW5lXShodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vYXBwZW5naW5lL2RvY3MvcHl0aG9uL21pY3Jvc2VydmljZXMtb24tYXBwLWVuZ2luZSks
CiBbQXBwIEVuZ2luZSBTdGFuZGFyZCByZXF1ZXN0CiByb3V0aW5nXShodHRwczovL2Nsb3Vk
Lmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9uL2hvdy1yZXF1ZXN0
cy1hcmUtcm91dGVkKSwKIGFuZCBbQXBwIEVuZ2luZSBGbGV4IHJlcXVlc3QKIHJvdXRpbmdd
KGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9mbGV4aWJsZS9weXRo
b24vaG93LXJlcXVlc3RzLWFyZS1yb3V0ZWQpLgoKCwoDBAMBEgTjAQgYCoIBCgQEAwIAEgTo
AQIVGnQgQXBwIHNlcnZpY2UuCgogQnkgZGVmYXVsdCwgdGhlIGpvYiBpcyBzZW50IHRvIHRo
ZSBzZXJ2aWNlIHdoaWNoIGlzIHRoZSBkZWZhdWx0CiBzZXJ2aWNlIHdoZW4gdGhlIGpvYiBp
cyBhdHRlbXB0ZWQuCgoNCgUEAwIABRIE6AECCAoNCgUEAwIAARIE6AEJEAoNCgUEAwIAAxIE
6AETFAqCAQoEBAMCARIE7gECFRp0IEFwcCB2ZXJzaW9uLgoKIEJ5IGRlZmF1bHQsIHRoZSBq
b2IgaXMgc2VudCB0byB0aGUgdmVyc2lvbiB3aGljaCBpcyB0aGUgZGVmYXVsdAogdmVyc2lv
biB3aGVuIHRoZSBqb2IgaXMgYXR0ZW1wdGVkLgoKDQoFBAMCAQUSBO4BAggKDQoFBAMCAQES
BO4BCRAKDQoFBAMCAQMSBO4BExQKiwUKBAQDAgISBP0BAhYa/AQgQXBwIGluc3RhbmNlLgoK
IEJ5IGRlZmF1bHQsIHRoZSBqb2IgaXMgc2VudCB0byBhbiBpbnN0YW5jZSB3aGljaCBpcyBh
dmFpbGFibGUgd2hlbgogdGhlIGpvYiBpcyBhdHRlbXB0ZWQuCgogUmVxdWVzdHMgY2FuIG9u
bHkgYmUgc2VudCB0byBhIHNwZWNpZmljIGluc3RhbmNlIGlmCiBbbWFudWFsIHNjYWxpbmcg
aXMgdXNlZCBpbiBBcHAgRW5naW5lCiBTdGFuZGFyZF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FwcGVuZ2luZS9kb2NzL3B5dGhvbi9hbi1vdmVydmlldy1vZi1hcHAtZW5naW5lPyNz
Y2FsaW5nX3R5cGVzX2FuZF9pbnN0YW5jZV9jbGFzc2VzKS4KIEFwcCBFbmdpbmUgRmxleCBk
b2VzIG5vdCBzdXBwb3J0IGluc3RhbmNlcy4gRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQog
W0FwcCBFbmdpbmUgU3RhbmRhcmQgcmVxdWVzdAogcm91dGluZ10oaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi9ob3ctcmVxdWVzdHMt
YXJlLXJvdXRlZCkKIGFuZCBbQXBwIEVuZ2luZSBGbGV4IHJlcXVlc3QKIHJvdXRpbmddKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9mbGV4aWJsZS9weXRob24v
aG93LXJlcXVlc3RzLWFyZS1yb3V0ZWQpLgoKDQoFBAMCAgUSBP0BAggKDQoFBAMCAgESBP0B
CREKDQoFBAMCAgMSBP0BFBUKrhUKBAQDAgMSBL4CAhIanxUgT3V0cHV0IG9ubHkuIFRoZSBo
b3N0IHRoYXQgdGhlIGpvYiBpcyBzZW50IHRvLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uIGFi
b3V0IGhvdyBBcHAgRW5naW5lIHJlcXVlc3RzIGFyZSByb3V0ZWQsIHNlZQogW2hlcmVdKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9zdGFuZGFyZC9weXRob24v
aG93LXJlcXVlc3RzLWFyZS1yb3V0ZWQpLgoKIFRoZSBob3N0IGlzIGNvbnN0cnVjdGVkIGFz
OgoKCiAqIGBob3N0ID0gW2FwcGxpY2F0aW9uX2RvbWFpbl9uYW1lXWA8L2JyPgogICBgfCBb
c2VydmljZV0gKyAnLicgKyBbYXBwbGljYXRpb25fZG9tYWluX25hbWVdYDwvYnI+CiAgIGB8
IFt2ZXJzaW9uXSArICcuJyArIFthcHBsaWNhdGlvbl9kb21haW5fbmFtZV1gPC9icj4KICAg
YHwgW3ZlcnNpb25fZG90X3NlcnZpY2VdKyAnLicgKyBbYXBwbGljYXRpb25fZG9tYWluX25h
bWVdYDwvYnI+CiAgIGB8IFtpbnN0YW5jZV0gKyAnLicgKyBbYXBwbGljYXRpb25fZG9tYWlu
X25hbWVdYDwvYnI+CiAgIGB8IFtpbnN0YW5jZV9kb3Rfc2VydmljZV0gKyAnLicgKyBbYXBw
bGljYXRpb25fZG9tYWluX25hbWVdYDwvYnI+CiAgIGB8IFtpbnN0YW5jZV9kb3RfdmVyc2lv
bl0gKyAnLicgKyBbYXBwbGljYXRpb25fZG9tYWluX25hbWVdYDwvYnI+CiAgIGB8IFtpbnN0
YW5jZV9kb3RfdmVyc2lvbl9kb3Rfc2VydmljZV0gKyAnLicgKyBbYXBwbGljYXRpb25fZG9t
YWluX25hbWVdYAoKICogYGFwcGxpY2F0aW9uX2RvbWFpbl9uYW1lYCA9IFRoZSBkb21haW4g
bmFtZSBvZiB0aGUgYXBwLCBmb3IKICAgZXhhbXBsZSA8YXBwLWlkPi5hcHBzcG90LmNvbSwg
d2hpY2ggaXMgYXNzb2NpYXRlZCB3aXRoIHRoZQogICBqb2IncyBwcm9qZWN0IElELgoKICog
YHNlcnZpY2UgPWAgW3NlcnZpY2VdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQXBwRW5n
aW5lUm91dGluZy5zZXJ2aWNlXQoKICogYHZlcnNpb24gPWAgW3ZlcnNpb25dW2dvb2dsZS5j
bG91ZC5zY2hlZHVsZXIudjEuQXBwRW5naW5lUm91dGluZy52ZXJzaW9uXQoKICogYHZlcnNp
b25fZG90X3NlcnZpY2UgPWAKICAgW3ZlcnNpb25dW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIu
djEuQXBwRW5naW5lUm91dGluZy52ZXJzaW9uXSBgKyAnLicgK2AKICAgW3NlcnZpY2VdW2dv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQXBwRW5naW5lUm91dGluZy5zZXJ2aWNlXQoKICog
YGluc3RhbmNlID1gCiBbaW5zdGFuY2VdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQXBw
RW5naW5lUm91dGluZy5pbnN0YW5jZV0KCiAqIGBpbnN0YW5jZV9kb3Rfc2VydmljZSA9YAog
ICBbaW5zdGFuY2VdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQXBwRW5naW5lUm91dGlu
Zy5pbnN0YW5jZV0gYCsgJy4nICtgCiAgIFtzZXJ2aWNlXVtnb29nbGUuY2xvdWQuc2NoZWR1
bGVyLnYxLkFwcEVuZ2luZVJvdXRpbmcuc2VydmljZV0KCiAqIGBpbnN0YW5jZV9kb3RfdmVy
c2lvbiA9YAogICBbaW5zdGFuY2VdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQXBwRW5n
aW5lUm91dGluZy5pbnN0YW5jZV0gYCsgJy4nICtgCiAgIFt2ZXJzaW9uXVtnb29nbGUuY2xv
dWQuc2NoZWR1bGVyLnYxLkFwcEVuZ2luZVJvdXRpbmcudmVyc2lvbl0KCiAqIGBpbnN0YW5j
ZV9kb3RfdmVyc2lvbl9kb3Rfc2VydmljZSA9YAogICBbaW5zdGFuY2VdW2dvb2dsZS5jbG91
ZC5zY2hlZHVsZXIudjEuQXBwRW5naW5lUm91dGluZy5pbnN0YW5jZV0gYCsgJy4nICtgCiAg
IFt2ZXJzaW9uXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkFwcEVuZ2luZVJvdXRpbmcu
dmVyc2lvbl0gYCsgJy4nICtgCiAgIFtzZXJ2aWNlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVy
LnYxLkFwcEVuZ2luZVJvdXRpbmcuc2VydmljZV0KCgogSWYgW3NlcnZpY2VdW2dvb2dsZS5j
bG91ZC5zY2hlZHVsZXIudjEuQXBwRW5naW5lUm91dGluZy5zZXJ2aWNlXSBpcyBlbXB0eSwK
IHRoZW4gdGhlIGpvYiB3aWxsIGJlIHNlbnQgdG8gdGhlIHNlcnZpY2Ugd2hpY2ggaXMgdGhl
IGRlZmF1bHQgc2VydmljZSB3aGVuCiB0aGUgam9iIGlzIGF0dGVtcHRlZC4KCiBJZiBbdmVy
c2lvbl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5BcHBFbmdpbmVSb3V0aW5nLnZlcnNp
b25dIGlzIGVtcHR5LAogdGhlbiB0aGUgam9iIHdpbGwgYmUgc2VudCB0byB0aGUgdmVyc2lv
biB3aGljaCBpcyB0aGUgZGVmYXVsdCB2ZXJzaW9uIHdoZW4KIHRoZSBqb2IgaXMgYXR0ZW1w
dGVkLgoKIElmIFtpbnN0YW5jZV1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5BcHBFbmdp
bmVSb3V0aW5nLmluc3RhbmNlXSBpcwogZW1wdHksIHRoZW4gdGhlIGpvYiB3aWxsIGJlIHNl
bnQgdG8gYW4gaW5zdGFuY2Ugd2hpY2ggaXMgYXZhaWxhYmxlIHdoZW4gdGhlCiBqb2IgaXMg
YXR0ZW1wdGVkLgoKIElmIFtzZXJ2aWNlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkFw
cEVuZ2luZVJvdXRpbmcuc2VydmljZV0sCiBbdmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNjaGVk
dWxlci52MS5BcHBFbmdpbmVSb3V0aW5nLnZlcnNpb25dLCBvcgogW2luc3RhbmNlXVtnb29n
bGUuY2xvdWQuc2NoZWR1bGVyLnYxLkFwcEVuZ2luZVJvdXRpbmcuaW5zdGFuY2VdIGlzIGlu
dmFsaWQsCiB0aGVuIHRoZSBqb2Igd2lsbCBiZSBzZW50IHRvIHRoZSBkZWZhdWx0IHZlcnNp
b24gb2YgdGhlIGRlZmF1bHQgc2VydmljZQogd2hlbiB0aGUgam9iIGlzIGF0dGVtcHRlZC4K
Cg0KBQQDAgMFEgS+AgIICg0KBQQDAgMBEgS+AgkNCg0KBQQDAgMDEgS+AhARCjgKAgUAEgbC
AgDaAgEaKiBUaGUgSFRUUCBtZXRob2QgdXNlZCB0byBleGVjdXRlIHRoZSBqb2IuCgoLCgMF
AAESBMICBQ8KOgoEBQACABIExAICHhosIEhUVFAgbWV0aG9kIHVuc3BlY2lmaWVkLiBEZWZh
dWx0cyB0byBQT1NULgoKDQoFBQACAAESBMQCAhkKDQoFBQACAAISBMQCHB0KGQoEBQACARIE
xwICCxoLIEhUVFAgUE9TVAoKDQoFBQACAQESBMcCAgYKDQoFBQACAQISBMcCCQoKGAoEBQAC
AhIEygICChoKIEhUVFAgR0VUCgoNCgUFAAICARIEygICBQoNCgUFAAICAhIEygIICQoZCgQF
AAIDEgTNAgILGgsgSFRUUCBIRUFECgoNCgUFAAIDARIEzQICBgoNCgUFAAIDAhIEzQIJCgoY
CgQFAAIEEgTQAgIKGgogSFRUUCBQVVQKCg0KBQUAAgQBEgTQAgIFCg0KBQUAAgQCEgTQAggJ
ChsKBAUAAgUSBNMCAg0aDSBIVFRQIERFTEVURQoKDQoFBQACBQESBNMCAggKDQoFBQACBQIS
BNMCCwwKGgoEBQACBhIE1gICDBoMIEhUVFAgUEFUQ0gKCg0KBQUAAgYBEgTWAgIHCg0KBQUA
AgYCEgTWAgoLChwKBAUAAgcSBNkCAg4aDiBIVFRQIE9QVElPTlMKCg0KBQUAAgcBEgTZAgIJ
Cg0KBQUAAgcCEgTZAgwNCvcBCgIEBBIG4AIA6wIBGugBIENvbnRhaW5zIGluZm9ybWF0aW9u
IG5lZWRlZCBmb3IgZ2VuZXJhdGluZyBhbgogW09BdXRoIHRva2VuXShodHRwczovL2RldmVs
b3BlcnMuZ29vZ2xlLmNvbS9pZGVudGl0eS9wcm90b2NvbHMvT0F1dGgyKS4KIFRoaXMgdHlw
ZSBvZiBhdXRob3JpemF0aW9uIHNob3VsZCBnZW5lcmFsbHkgb25seSBiZSB1c2VkIHdoZW4g
Y2FsbGluZyBHb29nbGUKIEFQSXMgaG9zdGVkIG9uICouZ29vZ2xlYXBpcy5jb20uCgoLCgME
BAESBOACCBIKmQIKBAQEAgASBOUCAiMaigIgW1NlcnZpY2UgYWNjb3VudCBlbWFpbF0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9kb2NzL3NlcnZpY2UtYWNjb3VudHMpCiB0byBi
ZSB1c2VkIGZvciBnZW5lcmF0aW5nIE9BdXRoIHRva2VuLgogVGhlIHNlcnZpY2UgYWNjb3Vu
dCBtdXN0IGJlIHdpdGhpbiB0aGUgc2FtZSBwcm9qZWN0IGFzIHRoZSBqb2IuIFRoZSBjYWxs
ZXIKIG11c3QgaGF2ZSBpYW0uc2VydmljZUFjY291bnRzLmFjdEFzIHBlcm1pc3Npb24gZm9y
IHRoZSBzZXJ2aWNlIGFjY291bnQuCgoNCgUEBAIABRIE5QICCAoNCgUEBAIAARIE5QIJHgoN
CgUEBAIAAxIE5QIhIgqdAQoEBAQCARIE6gICExqOASBPQXV0aCBzY29wZSB0byBiZSB1c2Vk
IGZvciBnZW5lcmF0aW5nIE9BdXRoIGFjY2VzcyB0b2tlbi4KIElmIG5vdCBzcGVjaWZpZWQs
ICJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtIgogd2ls
bCBiZSB1c2VkLgoKDQoFBAQCAQUSBOoCAggKDQoFBAQCAQESBOoCCQ4KDQoFBAQCAQMSBOoC
ERIKsQIKAgQFEgbzAgD9AgEaogIgQ29udGFpbnMgaW5mb3JtYXRpb24gbmVlZGVkIGZvciBn
ZW5lcmF0aW5nIGFuCiBbT3BlbklEIENvbm5lY3QKIHRva2VuXShodHRwczovL2RldmVsb3Bl
cnMuZ29vZ2xlLmNvbS9pZGVudGl0eS9wcm90b2NvbHMvT3BlbklEQ29ubmVjdCkuCiBUaGlz
IHR5cGUgb2YgYXV0aG9yaXphdGlvbiBjYW4gYmUgdXNlZCBmb3IgbWFueSBzY2VuYXJpb3Ms
IGluY2x1ZGluZwogY2FsbGluZyBDbG91ZCBSdW4sIG9yIGVuZHBvaW50cyB3aGVyZSB5b3Ug
aW50ZW5kIHRvIHZhbGlkYXRlIHRoZSB0b2tlbgogeW91cnNlbGYuCgoLCgMEBQESBPMCCBEK
mAIKBAQFAgASBPgCAiMaiQIgW1NlcnZpY2UgYWNjb3VudCBlbWFpbF0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2lhbS9kb2NzL3NlcnZpY2UtYWNjb3VudHMpCiB0byBiZSB1c2VkIGZv
ciBnZW5lcmF0aW5nIE9JREMgdG9rZW4uCiBUaGUgc2VydmljZSBhY2NvdW50IG11c3QgYmUg
d2l0aGluIHRoZSBzYW1lIHByb2plY3QgYXMgdGhlIGpvYi4gVGhlIGNhbGxlcgogbXVzdCBo
YXZlIGlhbS5zZXJ2aWNlQWNjb3VudHMuYWN0QXMgcGVybWlzc2lvbiBmb3IgdGhlIHNlcnZp
Y2UgYWNjb3VudC4KCg0KBQQFAgAFEgT4AgIICg0KBQQFAgABEgT4AgkeCg0KBQQFAgADEgT4
AiEiCnwKBAQFAgESBPwCAhYabiBBdWRpZW5jZSB0byBiZSB1c2VkIHdoZW4gZ2VuZXJhdGlu
ZyBPSURDIHRva2VuLiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgVVJJCiBzcGVjaWZpZWQgaW4g
dGFyZ2V0IHdpbGwgYmUgdXNlZC4KCg0KBQQFAgEFEgT8AgIICg0KBQQFAgEBEgT8AgkRCg0K
BQQFAgEDEgT8AhQVYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Scheduler::V1::Target::HttpTarget ===
    # Fields for HttpTarget
    # Field: uri Type: 9 ()
    # Field: http_method Type: 14 (.google.cloud.scheduler.v1.HttpMethod)
    # Field: headers Type: 11 (.google.cloud.scheduler.v1.HttpTarget.HeadersEntry)
    # Field: body Type: 12 ()
    # Field: oauth_token Type: 11 (.google.cloud.scheduler.v1.OAuthToken)
    # Field: oidc_token Type: 11 (.google.cloud.scheduler.v1.OidcToken)

# === Message: Google::Cloud::Scheduler::V1::Target::AppEngineHttpTarget ===
    # Fields for AppEngineHttpTarget
    # Field: http_method Type: 14 (.google.cloud.scheduler.v1.HttpMethod)
    # Field: app_engine_routing Type: 11 (.google.cloud.scheduler.v1.AppEngineRouting)
    # Field: relative_uri Type: 9 ()
    # Field: headers Type: 11 (.google.cloud.scheduler.v1.AppEngineHttpTarget.HeadersEntry)
    # Field: body Type: 12 ()

# === Message: Google::Cloud::Scheduler::V1::Target::PubsubTarget ===
    # Fields for PubsubTarget
    # Field: topic_name Type: 9 ()
    # Field: data Type: 12 ()
    # Field: attributes Type: 11 (.google.cloud.scheduler.v1.PubsubTarget.AttributesEntry)

# === Message: Google::Cloud::Scheduler::V1::Target::AppEngineRouting ===
    # Fields for AppEngineRouting
    # Field: service Type: 9 ()
    # Field: version Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: host Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Target::OAuthToken ===
    # Fields for OAuthToken
    # Field: service_account_email Type: 9 ()
    # Field: scope Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1::Target::OidcToken ===
    # Fields for OidcToken
    # Field: service_account_email Type: 9 ()
    # Field: audience Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Scheduler::V1::Target - Compiled Protocol Buffers messages for google/cloud/scheduler/v1/target.proto

=head1 SYNOPSIS

    use Google::Cloud::Scheduler::V1::Target;

    my $msg = Google::Cloud::Scheduler::V1::Target::HttpTarget->new({
        uri => $uri,
        http_method => $http_method,
        headers => $headers,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Scheduler::V1::Target::HttpTarget->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/scheduler/v1/target.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Scheduler::V1::Target::HttpTarget

Http target. The job will be pushed to the job handler by means of
an HTTP request via an
[http_method][google.cloud.scheduler.v1.HttpTarget.http_method] such as HTTP
POST, HTTP GET, etc. The job is acknowledged by means of an HTTP
response code in the range [200 - 299]. A failure to receive a response
constitutes a failed execution. For a redirected request, the response
returned by the redirected request is considered.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The full URI path that the request will be sent to. This string
must begin with either "http://" or "https://". Some examples of
valid values for [uri][google.cloud.scheduler.v1.HttpTarget.uri] are:
`http://acme.com` and `https://acme.com/sales:8080`. Cloud Scheduler will
encode some characters for safety and compatibility. The maximum allowed
URL length is 2083 characters after encoding.

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<Enum> (L<Google::Cloud::Scheduler::V1::HttpMethod>)

Which HTTP method to use for the request.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::HttpTarget::HeadersEntry>)

HTTP request headers.

This map contains the header field names and values.

The user can specify HTTP request headers to send with the job's
HTTP request. Repeated headers are not supported, but a header value can
contain commas.

The following headers represent a subset of the headers
that accompany the job's HTTP request. Some HTTP request
headers are ignored or replaced. A partial list of headers that
are ignored or replaced is below:

* Host: This will be computed by Cloud Scheduler and derived from
[uri][google.cloud.scheduler.v1.HttpTarget.uri].
* `Content-Length`: This will be computed by Cloud Scheduler.
* `User-Agent`: This will be set to `"Google-Cloud-Scheduler"`.
* `X-Google-*`: Google internal use only.
* `X-AppEngine-*`: Google internal use only.
* `X-CloudScheduler`: This header will be set to true.
* `X-CloudScheduler-JobName`: This header will contain the job name.
* `X-CloudScheduler-ScheduleTime`: For Cloud Scheduler jobs specified in
the unix-cron format, this header will contain the job schedule as an
offset of UTC parsed according to RFC3339.

If the job has a [body][google.cloud.scheduler.v1.HttpTarget.body] and the
following headers are not set by the user, Cloud Scheduler sets default
values:

* `Content-Type`: This will be set to `"application/octet-stream"`. You
  can override this default by explicitly setting `Content-Type` to a
  particular media type when creating the job. For example, you can set
  `Content-Type` to `"application/json"`.

The total size of headers must be less than 80KB.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Bytes>

HTTP request body. A request body is allowed only if the HTTP
method is POST, PUT, or PATCH. It is an error to set body on a job with an
incompatible [HttpMethod][google.cloud.scheduler.v1.HttpMethod].

=item * C<< $msg->oauth_token() >> / C<< $msg->oauth_token($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::OAuthToken>)

If specified, an
[OAuth token](https://developers.google.com/identity/protocols/OAuth2)
will be generated and attached as an `Authorization` header in the HTTP
request.

This type of authorization should generally only be used when calling
Google APIs hosted on *.googleapis.com.

=item * C<< $msg->oidc_token() >> / C<< $msg->oidc_token($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::OidcToken>)

If specified, an
[OIDC](https://developers.google.com/identity/protocols/OpenIDConnect)
token will be generated and attached as an `Authorization` header in the
HTTP request.

This type of authorization can be used for many scenarios, including
calling Cloud Run, or endpoints where you intend to validate the token
yourself.

=back

=head2 Google::Cloud::Scheduler::V1::Target::AppEngineHttpTarget

App Engine target. The job will be pushed to a job handler by means
of an HTTP request via an
[http_method][google.cloud.scheduler.v1.AppEngineHttpTarget.http_method] such
as HTTP POST, HTTP GET, etc. The job is acknowledged by means of an
HTTP response code in the range [200 - 299]. Error 503 is
considered an App Engine system error instead of an application
error. Requests returning error 503 will be retried regardless of
retry configuration and not counted against retry counts. Any other
response code, or a failure to receive a response before the
deadline, constitutes a failed attempt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<Enum> (L<Google::Cloud::Scheduler::V1::HttpMethod>)

The HTTP method to use for the request. PATCH and OPTIONS are not
permitted.

=item * C<< $msg->app_engine_routing() >> / C<< $msg->app_engine_routing($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::AppEngineRouting>)

App Engine Routing setting for the job.

=item * C<< $msg->relative_uri() >> / C<< $msg->relative_uri($value) >>

Type: C<String>

The relative URI.

The relative URL must begin with "/" and must be a valid HTTP relative URL.
It can contain a path, query string arguments, and `#` fragments.
If the relative URL is empty, then the root path "/" will be used.
No spaces are allowed, and the maximum length allowed is 2083 characters.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::AppEngineHttpTarget::HeadersEntry>)

HTTP request headers.

This map contains the header field names and values. Headers can be set
when the job is created.

Cloud Scheduler sets some headers to default values:

* `User-Agent`: By default, this header is
  `"AppEngine-Google; (+http://code.google.com/appengine)"`.
  This header can be modified, but Cloud Scheduler will append
  `"AppEngine-Google; (+http://code.google.com/appengine)"` to the
  modified `User-Agent`.
* `X-CloudScheduler`: This header will be set to true.
* `X-CloudScheduler-JobName`: This header will contain the job name.
* `X-CloudScheduler-ScheduleTime`: For Cloud Scheduler jobs specified in
the unix-cron format, this header will contain the job schedule as an
offset of UTC parsed according to RFC3339.

If the job has a [body][google.cloud.scheduler.v1.AppEngineHttpTarget.body]
and the following headers are not set by the user, Cloud Scheduler sets
default values:

* `Content-Type`: This will be set to `"application/octet-stream"`. You
  can override this default by explicitly setting `Content-Type` to a
  particular media type when creating the job. For example, you can set
  `Content-Type` to `"application/json"`.

The headers below are output only. They cannot be set or overridden:

* `Content-Length`: This is computed by Cloud Scheduler.
* `X-Google-*`: For Google internal use only.
* `X-AppEngine-*`: For Google internal use only.

In addition, some App Engine headers, which contain
job-specific information, are also be sent to the job handler.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Bytes>

Body.

HTTP request body. A request body is allowed only if the HTTP method is
POST or PUT. It will result in invalid argument error to set a body on a
job with an incompatible
[HttpMethod][google.cloud.scheduler.v1.HttpMethod].

=back

=head2 Google::Cloud::Scheduler::V1::Target::PubsubTarget

Pub/Sub target. The job will be delivered by publishing a message to
the given Pub/Sub topic.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic_name() >> / C<< $msg->topic_name($value) >>

Type: C<String>

Required. The name of the Cloud Pub/Sub topic to which messages will
be published when a job is delivered. The topic name must be in the
same format as required by Pub/Sub's
[PublishRequest.name](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#publishrequest),
for example `projects/PROJECT_ID/topics/TOPIC_ID`.

The topic must be in the same project as the Cloud Scheduler job.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The message payload for PubsubMessage.

Pubsub message must contain either non-empty data, or at least one
attribute.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::PubsubTarget::AttributesEntry>)

Attributes for PubsubMessage.

Pubsub message must contain either non-empty data, or at least one
attribute.

=back

=head2 Google::Cloud::Scheduler::V1::Target::AppEngineRouting

App Engine Routing.

For more information about services, versions, and instances see
[An Overview of App
Engine](https://cloud.google.com/appengine/docs/python/an-overview-of-app-engine),
[Microservices Architecture on Google App
Engine](https://cloud.google.com/appengine/docs/python/microservices-on-app-engine),
[App Engine Standard request
routing](https://cloud.google.com/appengine/docs/standard/python/how-requests-are-routed),
and [App Engine Flex request
routing](https://cloud.google.com/appengine/docs/flexible/python/how-requests-are-routed).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

App service.

By default, the job is sent to the service which is the default
service when the job is attempted.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

App version.

By default, the job is sent to the version which is the default
version when the job is attempted.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

App instance.

By default, the job is sent to an instance which is available when
the job is attempted.

Requests can only be sent to a specific instance if
[manual scaling is used in App Engine
Standard](https://cloud.google.com/appengine/docs/python/an-overview-of-app-engine?#scaling_types_and_instance_classes).
App Engine Flex does not support instances. For more information, see
[App Engine Standard request
routing](https://cloud.google.com/appengine/docs/standard/python/how-requests-are-routed)
and [App Engine Flex request
routing](https://cloud.google.com/appengine/docs/flexible/python/how-requests-are-routed).

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Output only. The host that the job is sent to.

For more information about how App Engine requests are routed, see
[here](https://cloud.google.com/appengine/docs/standard/python/how-requests-are-routed).

The host is constructed as:


* `host = [application_domain_name]`</br>
  `| [service] + '.' + [application_domain_name]`</br>
  `| [version] + '.' + [application_domain_name]`</br>
  `| [version_dot_service]+ '.' + [application_domain_name]`</br>
  `| [instance] + '.' + [application_domain_name]`</br>
  `| [instance_dot_service] + '.' + [application_domain_name]`</br>
  `| [instance_dot_version] + '.' + [application_domain_name]`</br>
  `| [instance_dot_version_dot_service] + '.' + [application_domain_name]`

* `application_domain_name` = The domain name of the app, for
  example <app-id>.appspot.com, which is associated with the
  job's project ID.

* `service =` [service][google.cloud.scheduler.v1.AppEngineRouting.service]

* `version =` [version][google.cloud.scheduler.v1.AppEngineRouting.version]

* `version_dot_service =`
  [version][google.cloud.scheduler.v1.AppEngineRouting.version] `+ '.' +`
  [service][google.cloud.scheduler.v1.AppEngineRouting.service]

* `instance =`
[instance][google.cloud.scheduler.v1.AppEngineRouting.instance]

* `instance_dot_service =`
  [instance][google.cloud.scheduler.v1.AppEngineRouting.instance] `+ '.' +`
  [service][google.cloud.scheduler.v1.AppEngineRouting.service]

* `instance_dot_version =`
  [instance][google.cloud.scheduler.v1.AppEngineRouting.instance] `+ '.' +`
  [version][google.cloud.scheduler.v1.AppEngineRouting.version]

* `instance_dot_version_dot_service =`
  [instance][google.cloud.scheduler.v1.AppEngineRouting.instance] `+ '.' +`
  [version][google.cloud.scheduler.v1.AppEngineRouting.version] `+ '.' +`
  [service][google.cloud.scheduler.v1.AppEngineRouting.service]


If [service][google.cloud.scheduler.v1.AppEngineRouting.service] is empty,
then the job will be sent to the service which is the default service when
the job is attempted.

If [version][google.cloud.scheduler.v1.AppEngineRouting.version] is empty,
then the job will be sent to the version which is the default version when
the job is attempted.

If [instance][google.cloud.scheduler.v1.AppEngineRouting.instance] is
empty, then the job will be sent to an instance which is available when the
job is attempted.

If [service][google.cloud.scheduler.v1.AppEngineRouting.service],
[version][google.cloud.scheduler.v1.AppEngineRouting.version], or
[instance][google.cloud.scheduler.v1.AppEngineRouting.instance] is invalid,
then the job will be sent to the default version of the default service
when the job is attempted.

=back

=head2 Google::Cloud::Scheduler::V1::Target::OAuthToken

Contains information needed for generating an
[OAuth token](https://developers.google.com/identity/protocols/OAuth2).
This type of authorization should generally only be used when calling Google
APIs hosted on *.googleapis.com.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account_email() >> / C<< $msg->service_account_email($value) >>

Type: C<String>

[Service account email](https://cloud.google.com/iam/docs/service-accounts)
to be used for generating OAuth token.
The service account must be within the same project as the job. The caller
must have iam.serviceAccounts.actAs permission for the service account.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

OAuth scope to be used for generating OAuth access token.
If not specified, "https://www.googleapis.com/auth/cloud-platform"
will be used.

=back

=head2 Google::Cloud::Scheduler::V1::Target::OidcToken

Contains information needed for generating an
[OpenID Connect
token](https://developers.google.com/identity/protocols/OpenIDConnect).
This type of authorization can be used for many scenarios, including
calling Cloud Run, or endpoints where you intend to validate the token
yourself.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account_email() >> / C<< $msg->service_account_email($value) >>

Type: C<String>

[Service account email](https://cloud.google.com/iam/docs/service-accounts)
to be used for generating OIDC token.
The service account must be within the same project as the job. The caller
must have iam.serviceAccounts.actAs permission for the service account.

=item * C<< $msg->audience() >> / C<< $msg->audience($value) >>

Type: C<String>

Audience to be used when generating OIDC token. If not specified, the URI
specified in target will be used.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Scheduler::V1::Target::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
