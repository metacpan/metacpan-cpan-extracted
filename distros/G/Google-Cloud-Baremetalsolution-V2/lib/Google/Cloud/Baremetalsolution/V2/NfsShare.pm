package Google::Cloud::Baremetalsolution::V2::NfsShare;

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
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvbmZzX3NoYXJlLnByb3RvEiFn
b29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1
Zi9maWVsZF9tYXNrLnByb3RvIukKCghOZnNTaGFyZRIXCgRuYW1lGAEgASgJQgPgQQVSBG5h
bWUSJQoMbmZzX3NoYXJlX2lkGAIgASgJQgPgQQNSCm5mc1NoYXJlSWQSEwoCaWQYCCABKAlC
A+BBA1ICaWQSTAoFc3RhdGUYAyABKA4yMS5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRp
b24udjIuTmZzU2hhcmUuU3RhdGVCA+BBA1IFc3RhdGUSRwoGdm9sdW1lGAQgASgJQi/gQQP6
QSkKJ2JhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL1ZvbHVtZVIGdm9sdW1lEmIK
D2FsbG93ZWRfY2xpZW50cxgFIAMoCzI5Lmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlv
bi52Mi5OZnNTaGFyZS5BbGxvd2VkQ2xpZW50Ug5hbGxvd2VkQ2xpZW50cxJPCgZsYWJlbHMY
BiADKAsyNy5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuTmZzU2hhcmUuTGFi
ZWxzRW50cnlSBmxhYmVscxIsChJyZXF1ZXN0ZWRfc2l6ZV9naWIYByABKANSEHJlcXVlc3Rl
ZFNpemVHaWISXwoMc3RvcmFnZV90eXBlGAkgASgOMjcuZ29vZ2xlLmNsb3VkLmJhcmVtZXRh
bHNvbHV0aW9uLnYyLk5mc1NoYXJlLlN0b3JhZ2VUeXBlQgPgQQVSC3N0b3JhZ2VUeXBlGpcD
Cg1BbGxvd2VkQ2xpZW50EkcKB25ldHdvcmsYASABKAlCLfpBKgooYmFyZW1ldGFsc29sdXRp
b24uZ29vZ2xlYXBpcy5jb20vTmV0d29ya1IHbmV0d29yaxIeCghzaGFyZV9pcBgCIAEoCUID
4EEDUgdzaGFyZUlwEjAKFGFsbG93ZWRfY2xpZW50c19jaWRyGAMgASgJUhJhbGxvd2VkQ2xp
ZW50c0NpZHISaQoRbW91bnRfcGVybWlzc2lvbnMYBCABKA4yPC5nb29nbGUuY2xvdWQuYmFy
ZW1ldGFsc29sdXRpb24udjIuTmZzU2hhcmUuTW91bnRQZXJtaXNzaW9uc1IQbW91bnRQZXJt
aXNzaW9ucxIbCglhbGxvd19kZXYYBSABKAhSCGFsbG93RGV2Eh0KCmFsbG93X3N1aWQYBiAB
KAhSCWFsbG93U3VpZBIkCg5ub19yb290X3NxdWFzaBgHIAEoCFIMbm9Sb290U3F1YXNoEh4K
CG5mc19wYXRoGAggASgJQgPgQQNSB25mc1BhdGgaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJZCgVTdGF0ZRIVChFTVEFURV9V
TlNQRUNJRklFRBAAEg8KC1BST1ZJU0lPTkVEEAESDAoIQ1JFQVRJTkcQAhIMCghVUERBVElO
RxADEgwKCERFTEVUSU5HEAQiTwoQTW91bnRQZXJtaXNzaW9ucxIhCh1NT1VOVF9QRVJNSVNT
SU9OU19VTlNQRUNJRklFRBAAEggKBFJFQUQQARIOCgpSRUFEX1dSSVRFEAIiPQoLU3RvcmFn
ZVR5cGUSHAoYU1RPUkFHRV9UWVBFX1VOU1BFQ0lGSUVEEAASBwoDU1NEEAESBwoDSEREEAI6
bepBagopYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vTkZTU2hhcmUSPXByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9uZnNTaGFyZXMve25mc19zaGFy
ZX0iWwoSR2V0TmZzU2hhcmVSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopYmFyZW1l
dGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vTkZTU2hhcmVSBG5hbWUirQEKFExpc3ROZnNT
aGFyZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xl
YXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXpl
Eh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZpbHRl
ciKtAQoVTGlzdE5mc1NoYXJlc1Jlc3BvbnNlEkoKCm5mc19zaGFyZXMYASADKAsyKy5nb29n
bGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuTmZzU2hhcmVSCW5mc1NoYXJlcxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyAD
KAlSC3VucmVhY2hhYmxlIqMBChVVcGRhdGVOZnNTaGFyZVJlcXVlc3QSTQoJbmZzX3NoYXJl
GAEgASgLMisuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLk5mc1NoYXJlQgPg
QQJSCG5mc1NoYXJlEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza1IKdXBkYXRlTWFzayKLAQoVUmVuYW1lTmZzU2hhcmVSZXF1ZXN0EkUKBG5hbWUY
ASABKAlCMeBBAvpBKwopYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vTkZTU2hh
cmVSBG5hbWUSKwoPbmV3X25mc3NoYXJlX2lkGAIgASgJQgPgQQJSDW5ld05mc3NoYXJlSWQi
qQEKFUNyZWF0ZU5mc1NoYXJlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9j
YXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSTQoJbmZzX3NoYXJlGAIg
ASgLMisuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLk5mc1NoYXJlQgPgQQJS
CG5mc1NoYXJlIl4KFURlbGV0ZU5mc1NoYXJlUmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6
QSsKKWJhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL05GU1NoYXJlUgRuYW1lQvwB
CiVjb20uZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyQg1OZnNTaGFyZVByb3Rv
UAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28vYmFyZW1ldGFsc29sdXRpb24vYXBpdjIvYmFyZW1l
dGFsc29sdXRpb25wYjtiYXJlbWV0YWxzb2x1dGlvbnBiqgIhR29vZ2xlLkNsb3VkLkJhcmVN
ZXRhbFNvbHV0aW9uLlYyygIhR29vZ2xlXENsb3VkXEJhcmVNZXRhbFNvbHV0aW9uXFYy6gIk
R29vZ2xlOjpDbG91ZDo6QmFyZU1ldGFsU29sdXRpb246OlYySsY7CgcSBQ4A9gEBCrwECgEM
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
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACkKCQoC
AwESAxMAIwoJCgIDAhIDFAAqCggKAQgSAxYAPgoJCgIIJRIDFgA+CggKAQgSAxcAagoJCgII
CxIDFwBqCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALgoJCgIICBIDGQAuCggKAQgS
AxoAPgoJCgIIARIDGgA+CggKAQgSAxsAPgoJCgIIKRIDGwA+CggKAQgSAxwAPQoJCgIILRID
HAA9ChwKAgQAEgUfAJMBARoPIEFuIE5GUyBzaGFyZS4KCgoKAwQAARIDHwgQCgsKAwQABxIE
IAIjBAoNCgUEAAedCBIEIAIjBAo3CgQEAAQAEgQmAjUDGikgVGhlIHBvc3NpYmxlIHN0YXRl
cyBmb3IgdGhpcyBORlMgc2hhcmUuCgoMCgUEAAQAARIDJgcMCjIKBgQABAACABIDKAQaGiMg
VGhlIHNoYXJlIGlzIGluIGFuIHVua25vd24gc3RhdGUuCgoOCgcEAAQAAgABEgMoBBUKDgoH
BAAEAAIAAhIDKBgZCjAKBgQABAACARIDKwQUGiEgVGhlIHNoYXJlIGhhcyBiZWVuIHByb3Zp
c2lvbmVkLgoKDgoHBAAEAAIBARIDKwQPCg4KBwQABAACAQISAysSEwowCgYEAAQAAgISAy4E
ERohIFRoZSBORlMgU2hhcmUgaXMgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACAgESAy4EDAoO
CgcEAAQAAgICEgMuDxAKMAoGBAAEAAIDEgMxBBEaISBUaGUgTkZTIFNoYXJlIGlzIGJlaW5n
IHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgMxBAwKDgoHBAAEAAIDAhIDMQ8QCkAKBgQABAACBBID
NAQRGjEgVGhlIE5GUyBTaGFyZSBoYXMgYmVlbiByZXF1ZXN0ZWQgdG8gYmUgZGVsZXRlZC4K
Cg4KBwQABAACBAESAzQEDAoOCgcEAAQAAgQCEgM0DxAKLwoEBAAEARIEOAJBAxohIFRoZSBw
b3NzaWJsZSBtb3VudCBwZXJtaXNzaW9ucy4KCgwKBQQABAEBEgM4BxcKMAoGBAAEAQIAEgM6
BCYaISBQZXJtaXNzaW9ucyB3ZXJlIG5vdCBzcGVjaWZpZWQuCgoOCgcEAAQBAgABEgM6BCEK
DgoHBAAEAQIAAhIDOiQlCkMKBgQABAECARIDPQQNGjQgTkZTIHNoYXJlIGNhbiBiZSBtb3Vu
dCB3aXRoIHJlYWQtb25seSBwZXJtaXNzaW9ucy4KCg4KBwQABAECAQESAz0ECAoOCgcEAAQB
AgECEgM9CwwKRAoGBAAEAQICEgNABBMaNSBORlMgc2hhcmUgY2FuIGJlIG1vdW50IHdpdGgg
cmVhZC13cml0ZSBwZXJtaXNzaW9ucy4KCg4KBwQABAECAgESA0AEDgoOCgcEAAQBAgICEgNA
ERIKOwoEBAADABIERAJjAxotIFJlcHJlc2VudHMgYW4gJ2FjY2VzcyBwb2ludCcgZm9yIHRo
ZSBzaGFyZS4KCgwKBQQAAwABEgNEChcKNwoGBAADAAIAEgRGBEgHGicgVGhlIG5ldHdvcmsg
dGhlIGFjY2VzcyBwb2ludCBzaXRzIG9uLgoKDgoHBAADAAIABRIDRgQKCg4KBwQAAwACAAES
A0YLEgoOCgcEAAMAAgADEgNGFRYKDwoHBAADAAIACBIERhdIBgoRCgkEAAMAAgAInwgSBEYY
SAUKnQEKBgQAAwACARIDTAREGo0BIE91dHB1dCBvbmx5LiBUaGUgSVAgYWRkcmVzcyBvZiB0
aGUgc2hhcmUgb24gdGhpcyBuZXR3b3JrLiBBc3NpZ25lZAogYXV0b21hdGljYWxseSBkdXJp
bmcgcHJvdmlzaW9uaW5nIGJhc2VkIG9uIHRoZSBuZXR3b3JrJ3Mgc2VydmljZXNfY2lkci4K
Cg4KBwQAAwACAQUSA0wECgoOCgcEAAMAAgEBEgNMCxMKDgoHBAADAAIBAxIDTBYXCg4KBwQA
AwACAQgSA0wYQwoRCgoEAAMAAgEInAgAEgNMGUIKSgoGBAADAAICEgNPBCQaOyBUaGUgc3Vi
bmV0IG9mIElQIGFkZHJlc3NlcyBwZXJtaXR0ZWQgdG8gYWNjZXNzIHRoZSBzaGFyZS4KCg4K
BwQAAwACAgUSA08ECgoOCgcEAAMAAgIBEgNPCx8KDgoHBAADAAICAxIDTyIjCiMKBgQAAwAC
AxIDUgQrGhQgTW91bnQgcGVybWlzc2lvbnMuCgoOCgcEAAMAAgMGEgNSBBQKDgoHBAADAAID
ARIDUhUmCg4KBwQAAwACAwMSA1IpKgpWCgYEAAMAAgQSA1UEFxpHIEFsbG93IGRldiBmbGFn
LiAgV2hpY2ggY29udHJvbHMgd2hldGhlciB0byBhbGxvdyBjcmVhdGlvbiBvZiBkZXZpY2Vz
LgoKDgoHBAADAAIEBRIDVQQICg4KBwQAAwACBAESA1UJEgoOCgcEAAMAAgQDEgNVFRYKJwoG
BAADAAIFEgNYBBgaGCBBbGxvdyB0aGUgc2V0dWlkIGZsYWcuCgoOCgcEAAMAAgUFEgNYBAgK
DgoHBAADAAIFARIDWAkTCg4KBwQAAwACBQMSA1gWFwqzAQoGBAADAAIGEgNdBBwaowEgRGlz
YWJsZSByb290IHNxdWFzaGluZywgd2hpY2ggaXMgYSBmZWF0dXJlIG9mIE5GUy4KIFJvb3Qg
c3F1YXNoIGlzIGEgc3BlY2lhbCBtYXBwaW5nIG9mIHRoZSByZW1vdGUgc3VwZXJ1c2VyIChy
b290KSBpZGVudGl0eQogd2hlbiB1c2luZyBpZGVudGl0eSBhdXRoZW50aWNhdGlvbi4KCg4K
BwQAAwACBgUSA10ECAoOCgcEAAMAAgYBEgNdCRcKDgoHBAADAAIGAxIDXRobCsMBCgYEAAMA
AgcSA2IERBqzASBPdXRwdXQgb25seS4gVGhlIHBhdGggdG8gYWNjZXNzIE5GUywgaW4gZm9y
bWF0IHNoYXJlSVA6L0luc3RhbmNlSUQKIEluc3RhbmNlSUQgaXMgdGhlIGdlbmVyYXRlZCBJ
RCBpbnN0ZWFkIG9mIGN1c3RvbWVyIHByb3ZpZGVkIG5hbWUuCiBleGFtcGxlIGxpa2UgIjEw
LjAuMC4wOi9nMTIzNDU2Nzg5LW5mczAwMSIKCg4KBwQAAwACBwUSA2IECgoOCgcEAAMAAgcB
EgNiCxMKDgoHBAADAAIHAxIDYhYXCg4KBwQAAwACBwgSA2IYQwoRCgoEAAMAAgcInAgAEgNi
GUIKLgoEBAAEAhIEZgJvAxogIFRoZSBzdG9yYWdlIHR5cGUgZm9yIGEgdm9sdW1lLgoKDAoF
BAAEAgESA2YHEgo9CgYEAAQCAgASA2gEIRouIFRoZSBzdG9yYWdlIHR5cGUgZm9yIHRoaXMg
dm9sdW1lIGlzIHVua25vd24uCgoOCgcEAAQCAgABEgNoBBwKDgoHBAAEAgIAAhIDaB8gCjkK
BgQABAICARIDawQMGiogVGhlIHN0b3JhZ2UgdHlwZSBmb3IgdGhpcyB2b2x1bWUgaXMgU1NE
LgoKDgoHBAAEAgIBARIDawQHCg4KBwQABAICAQISA2sKCwo6CgYEAAQCAgISA24EDBorIFRo
aXMgc3RvcmFnZSB0eXBlIGZvciB0aGlzIHZvbHVtZSBpcyBIREQuCgoOCgcEAAQCAgIBEgNu
BAcKDgoHBAAEAgICAhIDbgoLCjQKBAQAAgASA3ICPBonIEltbXV0YWJsZS4gVGhlIG5hbWUg
b2YgdGhlIE5GUyBzaGFyZS4KCgwKBQQAAgAFEgNyAggKDAoFBAACAAESA3IJDQoMCgUEAAIA
AxIDchARCgwKBQQAAgAIEgNyEjsKDwoIBAACAAicCAASA3ITOgqXAQoEBAACARIDdgJGGokB
IE91dHB1dCBvbmx5LiBBbiBpZGVudGlmaWVyIGZvciB0aGUgTkZTIHNoYXJlLCBnZW5lcmF0
ZWQgYnkgdGhlIGJhY2tlbmQuCiBUaGlzIGZpZWxkIHdpbGwgYmUgZGVwcmVjYXRlZCBpbiB0
aGUgZnV0dXJlLCB1c2UgYGlkYCBpbnN0ZWFkLgoKDAoFBAACAQUSA3YCCAoMCgUEAAIBARID
dgkVCgwKBQQAAgEDEgN2GBkKDAoFBAACAQgSA3YaRQoPCggEAAIBCJwIABIDdhtECqIBCgQE
AAICEgN6AjwalAEgT3V0cHV0IG9ubHkuIEFuIGlkZW50aWZpZXIgZm9yIHRoZSBORlMgc2hh
cmUsIGdlbmVyYXRlZCBieSB0aGUgYmFja2VuZC4KIFRoaXMgaXMgdGhlIHNhbWUgdmFsdWUg
YXMgbmZzX3NoYXJlX2lkIGFuZCB3aWxsIHJlcGxhY2UgaXQgaW4gdGhlIGZ1dHVyZS4KCgwK
BQQAAgIFEgN6AggKDAoFBAACAgESA3oJCwoMCgUEAAICAxIDeg4PCgwKBQQAAgIIEgN6EDsK
DwoIBAACAgicCAASA3oROgo3CgQEAAIDEgN9Aj4aKiBPdXRwdXQgb25seS4gVGhlIHN0YXRl
IG9mIHRoZSBORlMgc2hhcmUuCgoMCgUEAAIDBhIDfQIHCgwKBQQAAgMBEgN9CA0KDAoFBAAC
AwMSA30QEQoMCgUEAAIDCBIDfRI9Cg8KCAQAAgMInAgAEgN9EzwKbgoEBAACBBIGgQEChgEE
Gl4gT3V0cHV0IG9ubHkuIFRoZSB1bmRlcmx5aW5nIHZvbHVtZSBvZiB0aGUgc2hhcmUuIENy
ZWF0ZWQgYXV0b21hdGljYWxseQogZHVyaW5nIHByb3Zpc2lvbmluZy4KCg0KBQQAAgQFEgSB
AQIICg0KBQQAAgQBEgSBAQkPCg0KBQQAAgQDEgSBARITCg8KBQQAAgQIEgaBARSGAQMKEAoI
BAACBAicCAASBIIBBC0KEQoHBAACBAifCBIGgwEEhQEFCi4KBAQAAgUSBIkBAi0aICBMaXN0
IG9mIGFsbG93ZWQgYWNjZXNzIHBvaW50cy4KCg0KBQQAAgUEEgSJAQIKCg0KBQQAAgUGEgSJ
AQsYCg0KBQQAAgUBEgSJARkoCg0KBQQAAgUDEgSJASssCioKBAQAAgYSBIwBAiEaHCBMYWJl
bHMgYXMga2V5IHZhbHVlIHBhaXJzLgoKDQoFBAACBgYSBIwBAhUKDQoFBAACBgESBIwBFhwK
DQoFBAACBgMSBIwBHyAKKwoEBAACBxIEjwECHxodIFRoZSByZXF1ZXN0ZWQgc2l6ZSwgaW4g
R2lCLgoKDQoFBAACBwUSBI8BAgcKDQoFBAACBwESBI8BCBoKDQoFBAACBwMSBI8BHR4KRQoE
BAACCBIEkgECSRo3IEltbXV0YWJsZS4gVGhlIHN0b3JhZ2UgdHlwZSBvZiB0aGUgdW5kZXJs
eWluZyB2b2x1bWUuCgoNCgUEAAIIBhIEkgECDQoNCgUEAAIIARIEkgEOGgoNCgUEAAIIAxIE
kgEdHgoNCgUEAAIICBIEkgEfSAoQCggEAAIICJwIABIEkgEgRwo9CgIEARIGlgEAngEBGi8g
TWVzc2FnZSBmb3IgcmVxdWVzdGluZyBORlMgc2hhcmUgaW5mb3JtYXRpb24uCgoLCgMEAQES
BJYBCBoKMQoEBAECABIGmAECnQEEGiEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHJlc291cmNl
LgoKDQoFBAECAAUSBJgBAggKDQoFBAECAAESBJgBCQ0KDQoFBAECAAMSBJgBEBEKDwoFBAEC
AAgSBpgBEp0BAwoQCggEAQIACJwIABIEmQEEKgoRCgcEAQIACJ8IEgaaAQScAQUKPAoCBAIS
BqEBALMBARouIE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgYSBsaXN0IG9mIE5GUyBzaGFyZXMu
CgoLCgMEAgESBKEBCBwKQgoEBAICABIGowECqAEEGjIgUmVxdWlyZWQuIFBhcmVudCB2YWx1
ZSBmb3IgTGlzdE5mc1NoYXJlc1JlcXVlc3QuCgoNCgUEAgIABRIEowECCAoNCgUEAgIAARIE
owEJDwoNCgUEAgIAAxIEowESEwoPCgUEAgIACBIGowEUqAEDChAKCAQCAgAInAgAEgSkAQQq
ChEKBwQCAgAInwgSBqUBBKcBBQqTAQoEBAICARIErAECFhqEASBSZXF1ZXN0ZWQgcGFnZSBz
aXplLiBUaGUgc2VydmVyIG1pZ2h0IHJldHVybiBmZXdlciBpdGVtcyB0aGFuIHJlcXVlc3Rl
ZC4KIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRl
ZmF1bHQuCgoNCgUEAgIBBRIErAECBwoNCgUEAgIBARIErAEIEQoNCgUEAgIBAxIErAEUFQpG
CgQEAgICEgSvAQIYGjggQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyBm
cm9tIHRoZSBzZXJ2ZXIuCgoNCgUEAgICBRIErwECCAoNCgUEAgICARIErwEJEwoNCgUEAgIC
AxIErwEWFwocCgQEAgIDEgSyAQIUGg4gTGlzdCBmaWx0ZXIuCgoNCgUEAgIDBRIEsgECCAoN
CgUEAgIDARIEsgEJDwoNCgUEAgIDAxIEsgESEwpDCgIEAxIGtgEAvwEBGjUgUmVzcG9uc2Ug
bWVzc2FnZSBjb250YWluaW5nIHRoZSBsaXN0IG9mIE5GUyBzaGFyZXMuCgoLCgMEAwESBLYB
CB0KJwoEBAMCABIEuAECIxoZIFRoZSBsaXN0IG9mIE5GUyBzaGFyZXMuCgoNCgUEAwIABBIE
uAECCgoNCgUEAwIABhIEuAELEwoNCgUEAwIAARIEuAEUHgoNCgUEAwIAAxIEuAEhIgpGCgQE
AwIBEgS7AQIdGjggQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyBmcm9t
IHRoZSBzZXJ2ZXIuCgoNCgUEAwIBBRIEuwECCAoNCgUEAwIBARIEuwEJGAoNCgUEAwIBAxIE
uwEbHAo0CgQEAwICEgS+AQIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNo
ZWQuCgoNCgUEAwICBBIEvgECCgoNCgUEAwICBRIEvgELEQoNCgUEAwICARIEvgESHQoNCgUE
AwICAxIEvgEgIQo8CgIEBBIGwgEAzgEBGi4gTWVzc2FnZSByZXF1ZXN0aW5nIHRvIHVwZGF0
aW5nIGFuIE5GUyBzaGFyZS4KCgsKAwQEARIEwgEIHQq6AQoEBAQCABIExwECQhqrASBSZXF1
aXJlZC4gVGhlIE5GUyBzaGFyZSB0byB1cGRhdGUuCgogVGhlIGBuYW1lYCBmaWVsZCBpcyB1
c2VkIHRvIGlkZW50aWZ5IHRoZSBORlMgc2hhcmUgdG8gdXBkYXRlLgogRm9ybWF0OiBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbmZzU2hhcmVzL3tuZnNfc2hh
cmV9CgoNCgUEBAIABhIExwECCgoNCgUEBAIAARIExwELFAoNCgUEBAIAAxIExwEXGAoNCgUE
BAIACBIExwEZQQoQCggEBAIACJwIABIExwEaQAp4CgQEBAIBEgTNAQIsGmogVGhlIGxpc3Qg
b2YgZmllbGRzIHRvIHVwZGF0ZS4KIFRoZSBvbmx5IGN1cnJlbnRseSBzdXBwb3J0ZWQgZmll
bGRzIGFyZToKICAgYGxhYmVsc2AKICAgYGFsbG93ZWRfY2xpZW50c2AKCg0KBQQEAgEGEgTN
AQIbCg0KBQQEAgEBEgTNARwnCg0KBQQEAgEDEgTNASorCjYKAgQFEgbRAQDdAQEaKCBNZXNz
YWdlIHJlcXVlc3RpbmcgcmVuYW1lIG9mIGEgc2VydmVyLgoKCwoDBAUBEgTRAQgdCpUBCgQE
BQIAEgbUAQLZAQQahAEgUmVxdWlyZWQuIFRoZSBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBp
ZGVudGlmeSB0aGUgbmZzc2hhcmUuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9uZnNzaGFyZXMve25mc3NoYXJlfQoKDQoFBAUCAAUSBNQBAggK
DQoFBAUCAAESBNQBCQ0KDQoFBAUCAAMSBNQBEBEKDwoFBAUCAAgSBtQBEtkBAwoQCggEBQIA
CJwIABIE1QEEKgoRCgcEBQIACJ8IEgbWAQTYAQUKNwoEBAUCARIE3AECRhopIFJlcXVpcmVk
LiBUaGUgbmV3IGBpZGAgb2YgdGhlIG5mc3NoYXJlLgoKDQoFBAUCAQUSBNwBAggKDQoFBAUC
AQESBNwBCRgKDQoFBAUCAQMSBNwBGxwKDQoFBAUCAQgSBNwBHUUKEAoIBAUCAQicCAASBNwB
HkQKMgoCBAYSBuABAOsBARokIE1lc3NhZ2UgZm9yIGNyZWF0aW5nIGFuIE5GUyBzaGFyZS4K
CgsKAwQGARIE4AEIHQo8CgQEBgIAEgbiAQLnAQQaLCBSZXF1aXJlZC4gVGhlIHBhcmVudCBw
cm9qZWN0IGFuZCBsb2NhdGlvbi4KCg0KBQQGAgAFEgTiAQIICg0KBQQGAgABEgTiAQkPCg0K
BQQGAgADEgTiARITCg8KBQQGAgAIEgbiARTnAQMKEAoIBAYCAAicCAASBOMBBCoKEQoHBAYC
AAifCBIG5AEE5gEFCjEKBAQGAgESBOoBAkIaIyBSZXF1aXJlZC4gVGhlIE5mc1NoYXJlIHRv
IGNyZWF0ZS4KCg0KBQQGAgEGEgTqAQIKCg0KBQQGAgEBEgTqAQsUCg0KBQQGAgEDEgTqARcY
Cg0KBQQGAgEIEgTqARlBChAKCAQGAgEInAgAEgTqARpACjIKAgQHEgbuAQD2AQEaJCBNZXNz
YWdlIGZvciBkZWxldGluZyBhbiBORlMgc2hhcmUuCgoLCgMEBwESBO4BCB0KQAoEBAcCABIG
8AEC9QEEGjAgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBORlMgc2hhcmUgdG8gZGVsZXRl
LgoKDQoFBAcCAAUSBPABAggKDQoFBAcCAAESBPABCQ0KDQoFBAcCAAMSBPABEBEKDwoFBAcC
AAgSBvABEvUBAwoQCggEBwIACJwIABIE8QEEKgoRCgcEBwIACJ8IEgbyAQT0AQViBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare ===
    # Fields for NfsShare
    # Field: name Type: 9 ()
    # Field: nfs_share_id Type: 9 ()
    # Field: id Type: 9 ()
    # Field: state Type: 14 (.google.cloud.baremetalsolution.v2.NfsShare.State)
    # Field: volume Type: 9 ()
    # Field: allowed_clients Type: 11 (.google.cloud.baremetalsolution.v2.NfsShare.AllowedClient)
    # Field: labels Type: 11 (.google.cloud.baremetalsolution.v2.NfsShare.LabelsEntry)
    # Field: requested_size_gib Type: 3 ()
    # Field: storage_type Type: 14 (.google.cloud.baremetalsolution.v2.NfsShare.StorageType)

# Enum: NfsShare::State
our $NfsShare_STATE_UNSPECIFIED = 0;
our $NfsShare_PROVISIONED = 1;
our $NfsShare_CREATING = 2;
our $NfsShare_UPDATING = 3;
our $NfsShare_DELETING = 4;

# Enum: NfsShare::MountPermissions
our $NfsShare_MOUNT_PERMISSIONS_UNSPECIFIED = 0;
our $NfsShare_READ = 1;
our $NfsShare_READ_WRITE = 2;

# Enum: NfsShare::StorageType
our $NfsShare_STORAGE_TYPE_UNSPECIFIED = 0;
our $NfsShare_SSD = 1;
our $NfsShare_HDD = 2;

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::GetNfsShareRequest ===
    # Fields for GetNfsShareRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesRequest ===
    # Fields for ListNfsSharesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesResponse ===
    # Fields for ListNfsSharesResponse
    # Field: nfs_shares Type: 11 (.google.cloud.baremetalsolution.v2.NfsShare)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::UpdateNfsShareRequest ===
    # Fields for UpdateNfsShareRequest
    # Field: nfs_share Type: 11 (.google.cloud.baremetalsolution.v2.NfsShare)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::RenameNfsShareRequest ===
    # Fields for RenameNfsShareRequest
    # Field: name Type: 9 ()
    # Field: new_nfsshare_id Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::CreateNfsShareRequest ===
    # Fields for CreateNfsShareRequest
    # Field: parent Type: 9 ()
    # Field: nfs_share Type: 11 (.google.cloud.baremetalsolution.v2.NfsShare)

# === Message: Google::Cloud::Baremetalsolution::V2::NfsShare::DeleteNfsShareRequest ===
    # Fields for DeleteNfsShareRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::NfsShare - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/nfs_share.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::NfsShare;

    my $msg = Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare->new({
        name => $name,
        nfs_share_id => $nfs_share_id,
        id => $id,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/nfs_share.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare

An NFS share.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The name of the NFS share.

=item * C<< $msg->nfs_share_id() >> / C<< $msg->nfs_share_id($value) >>

Type: C<String>

Output only. An identifier for the NFS share, generated by the backend.
This field will be deprecated in the future, use `id` instead.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. An identifier for the NFS share, generated by the backend.
This is the same value as nfs_share_id and will replace it in the future.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::State>)

Output only. The state of the NFS share.

=item * C<< $msg->volume() >> / C<< $msg->volume($value) >>

Type: C<String>

Output only. The underlying volume of the share. Created automatically
during provisioning.

=item * C<< $msg->allowed_clients() >> / C<< $msg->allowed_clients($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::AllowedClient>)

List of allowed access points.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->requested_size_gib() >> / C<< $msg->requested_size_gib($value) >>

Type: C<Int64>

The requested size, in GiB.

=item * C<< $msg->storage_type() >> / C<< $msg->storage_type($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::StorageType>)

Immutable. The storage type of the underlying volume.

=back

=head3 Enum: NfsShare::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONED> => C<1>

=item * C<CREATING> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head3 Enum: NfsShare::MountPermissions

=over 4

=item * C<MOUNT_PERMISSIONS_UNSPECIFIED> => C<0>

=item * C<READ> => C<1>

=item * C<READ_WRITE> => C<2>

=back

=head3 Enum: NfsShare::StorageType

=over 4

=item * C<STORAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<SSD> => C<1>

=item * C<HDD> => C<2>

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::GetNfsShareRequest

Message for requesting NFS share information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesRequest

Message for requesting a list of NFS shares.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListNfsSharesRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server might return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::ListNfsSharesResponse

Response message containing the list of NFS shares.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nfs_shares() >> / C<< $msg->nfs_shares($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare>)

The list of NFS shares.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::UpdateNfsShareRequest

Message requesting to updating an NFS share.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nfs_share() >> / C<< $msg->nfs_share($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare>)

Required. The NFS share to update.

The `name` field is used to identify the NFS share to update.
Format: projects/{project}/locations/{location}/nfsShares/{nfs_share}

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to update.
The only currently supported fields are:
  `labels`
  `allowed_clients`

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::RenameNfsShareRequest

Message requesting rename of a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The `name` field is used to identify the nfsshare.
Format: projects/{project}/locations/{location}/nfsshares/{nfsshare}

=item * C<< $msg->new_nfsshare_id() >> / C<< $msg->new_nfsshare_id($value) >>

Type: C<String>

Required. The new `id` of the nfsshare.

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::CreateNfsShareRequest

Message for creating an NFS share.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent project and location.

=item * C<< $msg->nfs_share() >> / C<< $msg->nfs_share($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::NfsShare::NfsShare>)

Required. The NfsShare to create.

=back

=head2 Google::Cloud::Baremetalsolution::V2::NfsShare::DeleteNfsShareRequest

Message for deleting an NFS share.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the NFS share to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::NfsShare::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
