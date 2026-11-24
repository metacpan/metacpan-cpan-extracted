package Google::Cloud::Discoveryengine::V1alpha::Session;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Answer };
    eval { require Google::Cloud::Discoveryengine::V1alpha::Common };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2Vzc2lvbi5wcm90bxIk
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUvY2xv
dWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvYW5zd2VyLnByb3RvGjFnb29nbGUvY2xvdWQv
ZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tbW9uLnByb3RvGh5nb29nbGUvcHJvdG9idWYv
ZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i3gkKB1Nl
c3Npb24SFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgHIAEoCUID
4EEBUgtkaXNwbGF5TmFtZRJJCgVzdGF0ZRgCIAEoDjIzLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5TZXNzaW9uLlN0YXRlUgVzdGF0ZRIkCg51c2VyX3BzZXVkb19p
ZBgDIAEoCVIMdXNlclBzZXVkb0lkEkgKBXR1cm5zGAQgAygLMjIuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlNlc3Npb24uVHVyblIFdHVybnMSPgoKc3RhcnRfdGlt
ZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEjoK
CGVuZF90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRU
aW1lEiAKCWlzX3Bpbm5lZBgIIAEoCEID4EEBUghpc1Bpbm5lZBqeAwoEVHVybhJGCgVxdWVy
eRgBIAEoCzIrLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5RdWVyeUID
4EEBUgVxdWVyeRJFCgZhbnN3ZXIYAiABKAlCLeBBAfpBJwolZGlzY292ZXJ5ZW5naW5lLmdv
b2dsZWFwaXMuY29tL0Fuc3dlclIGYW5zd2VyEloKD2RldGFpbGVkX2Fuc3dlchgHIAEoCzIs
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5BbnN3ZXJCA+BBA1IOZGV0
YWlsZWRBbnN3ZXISawoMcXVlcnlfY29uZmlnGBAgAygLMkMuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLlNlc3Npb24uVHVybi5RdWVyeUNvbmZpZ0VudHJ5QgPgQQFS
C3F1ZXJ5Q29uZmlnGj4KEFF1ZXJ5Q29uZmlnRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoF
dmFsdWUYAiABKAlSBXZhbHVlOgI4ASIvCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
Eg8KC0lOX1BST0dSRVNTEAE65gLqQeICCiZkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5j
b20vU2Vzc2lvbhJScHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Rh
dGFTdG9yZXMve2RhdGFfc3RvcmV9L3Nlc3Npb25zL3tzZXNzaW9ufRJrcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9k
YXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zZXNzaW9ucy97c2Vzc2lvbn0SZHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0v
ZW5naW5lcy97ZW5naW5lfS9zZXNzaW9ucy97c2Vzc2lvbn0qCHNlc3Npb25zMgdzZXNzaW9u
IkgKBVF1ZXJ5EhQKBHRleHQYAiABKAlIAFIEdGV4dBIeCghxdWVyeV9pZBgBIAEoCUID4EED
UgdxdWVyeUlkQgkKB2NvbnRlbnQiygIKFEltYWdlQ2hhcmFjdGVyaXN0aWNzEhkKBXdpZHRo
GAEgASgFQgPgQQNSBXdpZHRoEhsKBmhlaWdodBgCIAEoBUID4EEDUgZoZWlnaHQSawoLY29s
b3Jfc3BhY2UYAyABKA4yRS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
SW1hZ2VDaGFyYWN0ZXJpc3RpY3MuQ29sb3JTcGFjZUID4EEDUgpjb2xvclNwYWNlEiAKCWJp
dF9kZXB0aBgEIAEoBUID4EEDUghiaXREZXB0aCJrCgpDb2xvclNwYWNlEhsKF0NPTE9SX1NQ
QUNFX1VOU1BFQ0lGSUVEEAASBwoDUkdCEAESCAoEQ01ZSxACEg0KCUdSQVlTQ0FMRRADEgcK
A1lVVhAEEhUKEU9USEVSX0NPTE9SX1NQQUNFEAUi5AIKFFZpZGVvQ2hhcmFjdGVyaXN0aWNz
EhkKBXdpZHRoGAEgASgFQgPgQQNSBXdpZHRoEhsKBmhlaWdodBgCIAEoBUID4EEDUgZoZWln
aHQSOgoIZHVyYXRpb24YAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBA1II
ZHVyYXRpb24SIgoKZnJhbWVfcmF0ZRgEIAEoAUID4EEDUglmcmFtZVJhdGUSJgoMYXVkaW9f
Y29kZWNzGAUgAygJQgPgQQNSC2F1ZGlvQ29kZWNzEiYKDHZpZGVvX2NvZGVjcxgGIAMoCUID
4EEDUgt2aWRlb0NvZGVjcxIxChJ2aWRlb19iaXRyYXRlX2ticHMYByABKAVCA+BBA1IQdmlk
ZW9CaXRyYXRlS2JwcxIxChJhdWRpb19iaXRyYXRlX2ticHMYCCABKAVCA+BBA1IQYXVkaW9C
aXRyYXRlS2JwcyLYAQoTRmlsZUNoYXJhY3RlcmlzdGljcxJ9Cg9jaGFyYWN0ZXJpc3RpY3MY
BiADKAsyTi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRmlsZUNoYXJh
Y3RlcmlzdGljcy5DaGFyYWN0ZXJpc3RpY3NFbnRyeUID4EEDUg9jaGFyYWN0ZXJpc3RpY3Ma
QgoUQ2hhcmFjdGVyaXN0aWNzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ASK9BAoIRmlsZVZpZXcSdgoVaW1hZ2VfY2hhcmFjdGVyaXN0aWNzGAYg
ASgLMjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkltYWdlQ2hhcmFj
dGVyaXN0aWNzQgPgQQNIAFIUaW1hZ2VDaGFyYWN0ZXJpc3RpY3MSdgoVdmlkZW9fY2hhcmFj
dGVyaXN0aWNzGAcgASgLMjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlZpZGVvQ2hhcmFjdGVyaXN0aWNzQgPgQQNIAFIUdmlkZW9DaGFyYWN0ZXJpc3RpY3MScwoU
ZmlsZV9jaGFyYWN0ZXJpc3RpY3MYCCABKAsyOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuRmlsZUNoYXJhY3RlcmlzdGljc0ID4EEDSABSE2ZpbGVDaGFyYWN0ZXJp
c3RpY3MSHAoHdmlld19pZBgBIAEoCUID4EEDUgZ2aWV3SWQSFQoDdXJpGAIgASgJQgPgQQNS
A3VyaRIgCgltaW1lX3R5cGUYAyABKAlCA+BBA1IIbWltZVR5cGUSIAoJYnl0ZV9zaXplGAQg
ASgDQgPgQQNSCGJ5dGVTaXplEkAKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lQhEKD2NoYXJhY3RlcmlzdGljcyKNBwoM
RmlsZU1ldGFkYXRhEhwKB2ZpbGVfaWQYASABKAlCA+BBA1IGZmlsZUlkEhcKBG5hbWUYAiAB
KAlCA+BBA1IEbmFtZRIbCgltaW1lX3R5cGUYAyABKAlSCG1pbWVUeXBlEiAKCWJ5dGVfc2l6
ZRgEIAEoA0ID4EEDUghieXRlU2l6ZRImCgxvcmlnaW5hbF91cmkYCSABKAlCA+BBAVILb3Jp
Z2luYWxVcmkSZwoUb3JpZ2luYWxfc291cmNlX3R5cGUYCiABKA4yMC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRmlsZVNvdXJjZUID4EEBUhJvcmlnaW5hbFNvdXJj
ZVR5cGUSQAoLdXBsb2FkX3RpbWUYDCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCnVwbG9hZFRpbWUSQwoNbGFzdF9hZGRfdGltZRgNIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1ILbGFzdEFkZFRpbWUSYQoIbWV0YWRhdGEYEiADKAsyQC5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRmlsZU1ldGFkYXRhLk1ldGFk
YXRhRW50cnlCA+BBAVIIbWV0YWRhdGESJgoMZG93bmxvYWRfdXJpGBQgASgJQgPgQQNSC2Rv
d25sb2FkVXJpEmMKEGZpbGVfb3JpZ2luX3R5cGUYFSABKA4yNC5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuRmlsZU9yaWdpblR5cGVCA+BBAVIOZmlsZU9yaWdpblR5
cGUSWAoFdmlld3MYFiADKAsyPS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRmlsZU1ldGFkYXRhLlZpZXdzRW50cnlCA+BBA1IFdmlld3MaOwoNTWV0YWRhdGFFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGmgKClZpZXdz
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSRAoFdmFsdWUYAiABKAsyLi5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRmlsZVZpZXdSBXZhbHVlOgI4ASqpAQoKRmlsZVNv
dXJjZRIbChdGSUxFX1NPVVJDRV9VTlNQRUNJRklFRBAAEhYKEkZJTEVfU09VUkNFX0lOTElO
RRABEhUKEUZJTEVfU09VUkNFX0xPQ0FMEAISHQoZRklMRV9TT1VSQ0VfQ0xPVURfU1RPUkFH
RRADEhsKF0ZJTEVfU09VUkNFX0NMT1VEX0RSSVZFEAQSEwoPRklMRV9TT1VSQ0VfVVJMEAVC
mAIKKGNvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCDFNlc3Npb25Q
cm90b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhh
L2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5F
qgIkR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3Vk
XERpc2NvdmVyeUVuZ2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5n
aW5lOjpWMWFscGhhSuVdCgcSBQ4AxgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA7CgkKAgMD
EgMVADsKCQoCAwQSAxYAKAoJCgIDBRIDFwApCggKAQgSAxkAQQoJCgIIJRIDGQBBCggKAQgS
AxoAaQoJCgIICxIDGgBpCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwALQoJCgIICBID
HAAtCggKAQgSAx0AQQoJCgIIARIDHQBBCggKAQgSAx4ALQoJCgIIJBIDHgAtCggKAQgSAx8A
QQoJCgIIKRIDHwBBCggKAQgSAyAAQAoJCgIILRIDIABACioKAgUAEgQjADUBGh4gT3JpZ2lu
YWwgc291cmNlIG9mIHRoZSBmaWxlLgoKCgoDBQABEgMjBQ8KLQoEBQACABIDJQIeGiAgRGVm
YXVsdCB2YWx1ZS4gVW5rbm93biBzb3VyY2UuCgoMCgUFAAIAARIDJQIZCgwKBQUAAgACEgMl
HB0KWQoEBQACARIDKAIZGkwgVGhlIGRhdGEgb2YgdGhlIGZpbGUgd2FzIHByb3ZpZGVkIGlu
bGluZSAoZS5nLiBwYXN0ZWQgZnJvbSB0aGUgY2xpcGJvYXJkKS4KCgwKBQUAAgEBEgMoAhQK
DAoFBQACAQISAygXGAo3CgQFAAICEgMrAhgaKiBUaGUgZmlsZSB3YXMgdXBsb2FkZWQgZnJv
bSBhIGxvY2FsIGZpbGUuCgoMCgUFAAICARIDKwITCgwKBQUAAgICEgMrFhcKOAoEBQACAxID
LgIgGisgVGhlIGZpbGUgd2FzIHVwbG9hZGVkIGZyb20gQ2xvdWQgU3RvcmFnZS4KCgwKBQUA
AgMBEgMuAhsKDAoFBQACAwISAy4eHwowCgQFAAIEEgMxAh4aIyBUaGUgZmlsZSB3YXMgdXBs
b2FkZWQgZnJvbSBEcml2ZS4KCgwKBQUAAgQBEgMxAhkKDAoFBQACBAISAzEcHQpDCgQFAAIF
EgM0AhYaNiBUaGUgZmlsZSB3YXMgcmV0cmlldmVkIGZyb20gYSBVUkwgKGUuZy4gcHVibGlj
IHdlYikuCgoMCgUFAAIFARIDNAIRCgwKBQUAAgUCEgM0FBUKMQoCBAASBTgAiwEBGiQgRXh0
ZXJuYWwgc2Vzc2lvbiBwcm90byBkZWZpbml0aW9uLgoKCgoDBAABEgM4CA8KCwoDBAAHEgQ5
AkAECg0KBQQAB50IEgQ5AkAECl4KBAQAAwASBEQCYgMaUCBSZXByZXNlbnRzIGEgdHVybiwg
aW5jbHVkaW5nIGEgcXVlcnkgZnJvbSB0aGUgdXNlciBhbmQgYQogYW5zd2VyIGZyb20gc2Vy
dmljZS4KCgwKBQQAAwABEgNECg4KfAoGBAADAAIAEgNHBD0abSBPcHRpb25hbC4gVGhlIHVz
ZXIgcXVlcnkuIE1heSBub3QgYmUgc2V0IGlmIHRoaXMgdHVybiBpcyBtZXJlbHkKIHJlZ2Vu
ZXJhdGluZyBhbiBhbnN3ZXIgdG8gYSBkaWZmZXJlbnQgdHVybgoKDgoHBAADAAIABhIDRwQJ
Cg4KBwQAAwACAAESA0cKDwoOCgcEAAMAAgADEgNHEhMKDgoHBAADAAIACBIDRxQ8ChEKCgQA
AwACAAicCAASA0cVOwqeAQoGBAADAAIBEgRNBFIGGo0BIE9wdGlvbmFsLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgYW5zd2VyIHRvIHRoZSB1c2VyIHF1ZXJ5LgoKIE9ubHkgc2V0IGlm
IHRoZSBhbnN3ZXIgZ2VuZXJhdGlvbiAoL2Fuc3dlciBBUEkgY2FsbCkgaGFwcGVuZWQgaW4g
dGhpcwogdHVybi4KCg4KBwQAAwACAQUSA00ECgoOCgcEAAMAAgEBEgNNCxEKDgoHBAADAAIB
AxIDTRQVCg8KBwQAAwACAQgSBE0WUgUKEQoKBAADAAIBCJwIABIDTgYsChEKCQQAAwACAQif
CBIETwZRBwruAgoGBAADAAICEgNaBEsa3gIgT3V0cHV0IG9ubHkuIEluCiBbQ29udmVyc2F0
aW9uYWxTZWFyY2hTZXJ2aWNlLkdldFNlc3Npb25dW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5Db252ZXJzYXRpb25hbFNlYXJjaFNlcnZpY2UuR2V0U2Vzc2lvbl0K
IEFQSSwgaWYKIFtHZXRTZXNzaW9uUmVxdWVzdC5pbmNsdWRlX2Fuc3dlcl9kZXRhaWxzXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuR2V0U2Vzc2lvblJlcXVlc3Qu
aW5jbHVkZV9hbnN3ZXJfZGV0YWlsc10KIGlzIHNldCB0byB0cnVlLCB0aGlzIGZpZWxkIHdp
bGwgYmUgcG9wdWxhdGVkIHdoZW4gZ2V0dGluZyBhbnN3ZXIgcXVlcnkKIHNlc3Npb24uCgoO
CgcEAAMAAgIGEgNaBAoKDgoHBAADAAICARIDWgsaCg4KBwQAAwACAgMSA1odHgoOCgcEAAMA
AgIIEgNaH0oKEQoKBAADAAICCJwIABIDWiBJCvkBCgYEAAMAAgMSBGAEYTEa6AEgT3B0aW9u
YWwuIFJlcHJlc2VudHMgbWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcXVlcnkgY29uZmlnLCBm
b3IgZXhhbXBsZQogTExNIG1vZGVsIGFuZCB2ZXJzaW9uIHVzZWQsIG1vZGVsIHBhcmFtZXRl
cnMgKHRlbXBlcmF0dXJlLCBncm91bmRpbmcKIHBhcmFtZXRlcnMsIGV0Yy4pLiBUaGUgcHJl
Zml4ICJnb29nbGUuIiBpcyByZXNlcnZlZCBmb3IgR29vZ2xlLWRldmVsb3BlZAogZnVuY3Rp
b25hbGl0eS4KCg4KBwQAAwACAwYSA2AEFwoOCgcEAAMAAgMBEgNgGCQKDgoHBAADAAIDAxID
YCcpCg4KBwQAAwACAwgSA2EIMAoRCgoEAAMAAgMInAgAEgNhCS8KOAoEBAAEABIEZQJrAxoq
IEVudW1lcmF0aW9uIG9mIHRoZSBzdGF0ZSBvZiB0aGUgc2Vzc2lvbi4KCgwKBQQABAABEgNl
BwwKJgoGBAAEAAIAEgNnBBoaFyBTdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAES
A2cEFQoOCgcEAAQAAgACEgNnGBkKLwoGBAAEAAIBEgNqBBQaICBUaGUgc2Vzc2lvbiBpcyBj
dXJyZW50bHkgb3Blbi4KCg4KBwQABAACAQESA2oEDwoOCgcEAAQAAgECEgNqEhMKigEKBAQA
AgASA28CPBp9IEltbXV0YWJsZS4gRnVsbHkgcXVhbGlmaWVkIG5hbWUKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL2dsb2JhbC9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZW5n
aW5lcy97ZW5naW5lfS9zZXNzaW9ucy8qYAoKDAoFBAACAAUSA28CCAoMCgUEAAIAARIDbwkN
CgwKBQQAAgADEgNvEBEKDAoFBAACAAgSA28SOwoPCggEAAIACJwIABIDbxM6Cr0BCgQEAAIB
EgN1AkMarwEgT3B0aW9uYWwuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHNlc3Npb24uCgog
VGhpcyBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRoZSBzZXNzaW9uIGluIHRoZSBVSS4K
IEJ5IGRlZmF1bHQsIHRoZSBkaXNwbGF5IG5hbWUgaXMgdGhlIGZpcnN0IHR1cm4gcXVlcnkg
dGV4dCBpbiB0aGUgc2Vzc2lvbi4KCgwKBQQAAgEFEgN1AggKDAoFBAACAQESA3UJFQoMCgUE
AAIBAxIDdRgZCgwKBQQAAgEIEgN1GkIKDwoIBAACAQicCAASA3UbQQooCgQEAAICEgN4AhIa
GyBUaGUgc3RhdGUgb2YgdGhlIHNlc3Npb24uCgoMCgUEAAICBhIDeAIHCgwKBQQAAgIBEgN4
CA0KDAoFBAACAgMSA3gQEQo2CgQEAAIDEgN7AhwaKSBBIHVuaXF1ZSBpZGVudGlmaWVyIGZv
ciB0cmFja2luZyB1c2Vycy4KCgwKBQQAAgMFEgN7AggKDAoFBAACAwESA3sJFwoMCgUEAAID
AxIDexobChUKBAQAAgQSA34CGhoIIFR1cm5zLgoKDAoFBAACBAQSA34CCgoMCgUEAAIEBhID
fgsPCgwKBQQAAgQBEgN+EBUKDAoFBAACBAMSA34YGQo8CgQEAAIFEgaBAQKCATIaLCBPdXRw
dXQgb25seS4gVGhlIHRpbWUgdGhlIHNlc3Npb24gc3RhcnRlZC4KCg0KBQQAAgUGEgSBAQIb
Cg0KBQQAAgUBEgSBARwmCg0KBQQAAgUDEgSBASkqCg0KBQQAAgUIEgSCAQYxChAKCAQAAgUI
nAgAEgSCAQcwCj0KBAQAAgYSBoUBAoYBMhotIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUg
c2Vzc2lvbiBmaW5pc2hlZC4KCg0KBQQAAgYGEgSFAQIbCg0KBQQAAgYBEgSFARwkCg0KBQQA
AgYDEgSFAScoCg0KBQQAAgYIEgSGAQYxChAKCAQAAgYInAgAEgSGAQcwCnoKBAQAAgcSBIoB
Aj4abCBPcHRpb25hbC4gV2hldGhlciB0aGUgc2Vzc2lvbiBpcyBwaW5uZWQsIHBpbm5lZCBz
ZXNzaW9uIHdpbGwgYmUgZGlzcGxheWVkCiBvbiB0aGUgdG9wIG9mIHRoZSBzZXNzaW9uIGxp
c3QuCgoNCgUEAAIHBRIEigECBgoNCgUEAAIHARIEigEHEAoNCgUEAAIHAxIEigETFAoNCgUE
AAIHCBIEigEVPQoQCggEAAIHCJwIABIEigEWPAotCgIEARIGjgEAlwEBGh8gRGVmaW5lcyBh
IHVzZXIgaW5wdXRlZCBxdWVyeS4KCgsKAwQBARIEjgEIDQogCgQEAQgAEgaQAQKTAQMaECBR
dWVyeSBjb250ZW50LgoKDQoFBAEIAAESBJABCA8KGwoEBAECABIEkgEEFBoNIFBsYWluIHRl
eHQuCgoNCgUEAQIABRIEkgEECgoNCgUEAQIAARIEkgELDwoNCgUEAQIAAxIEkgESEwo1CgQE
AQIBEgSWAQJCGicgT3V0cHV0IG9ubHkuIFVuaXF1ZSBJZCBmb3IgdGhlIHF1ZXJ5LgoKDQoF
BAECAQUSBJYBAggKDQoFBAECAQESBJYBCREKDQoFBAECAQMSBJYBFBUKDQoFBAECAQgSBJYB
FkEKEAoIBAECAQicCAASBJYBF0AKQAoCBAISBpoBALsBARoyIFN0YW5kYXJkIGNoYXJhY3Rl
cmlzdGljcyBvZiBhbiBpbWFnZSBtZWRpYSB2aWV3LgoKCwoDBAIBEgSaAQgcClcKBAQCBAAS
BpwBAq4BAxpHIFBvc3NpYmxlIGNvbG9yIHNwYWNlcyBvZiBhbiBpbWFnZSAoZS5nLiwgIlJH
QiIsICJDTVlLIiwgIkdyYXlzY2FsZSIpLgoKDQoFBAIEAAESBJwBBxEKNQoGBAIEAAIAEgSe
AQQgGiUgRGVmYXVsdCB2YWx1ZS4gVW5rbm93biBjb2xvciBzcGFjZS4KCg8KBwQCBAACAAES
BJ4BBBsKDwoHBAIEAAIAAhIEngEeHwouCgYEAgQAAgESBKEBBAwaHiBSZWQsIGdyZWVuLCBi
bHVlIGNvbG9yc3BhY2UuCgoPCgcEAgQAAgEBEgShAQQHCg8KBwQCBAACAQISBKEBCgsKPgoG
BAIEAAICEgSkAQQNGi4gQ3lhbiwgbWFnZW50YSwgeWVsbG93LCBhbmQgYmxhY2sgY29sb3Jz
cGFjZS4KCg8KBwQCBAACAgESBKQBBAgKDwoHBAIEAAICAhIEpAELDAonCgYEAgQAAgMSBKcB
BBIaFyBHcmF5c2NhbGUgY29sb3JzcGFjZS4KCg8KBwQCBAACAwESBKcBBA0KDwoHBAIEAAID
AhIEpwEQEQohCgYEAgQAAgQSBKoBBAwaESBZVVYgY29sb3JzcGFjZS4KCg8KBwQCBAACBAES
BKoBBAcKDwoHBAIEAAIEAhIEqgEKCwojCgYEAgQAAgUSBK0BBBoaEyBPdGhlciBjb2xvcnNw
YWNlLgoKDwoHBAIEAAIFARIErQEEFQoPCgcEAgQAAgUCEgStARgZCjMKBAQCAgASBLEBAj4a
JSBPdXRwdXQgb25seS4gSW1hZ2Ugd2lkdGggaW4gcGl4ZWxzLgoKDQoFBAICAAUSBLEBAgcK
DQoFBAICAAESBLEBCA0KDQoFBAICAAMSBLEBEBEKDQoFBAICAAgSBLEBEj0KEAoIBAICAAic
CAASBLEBEzwKNAoEBAICARIEtAECPxomIE91dHB1dCBvbmx5LiBJbWFnZSBoZWlnaHQgaW4g
cGl4ZWxzLgoKDQoFBAICAQUSBLQBAgcKDQoFBAICAQESBLQBCA4KDQoFBAICAQMSBLQBERIK
DQoFBAICAQgSBLQBEz4KEAoIBAICAQicCAASBLQBFD0KWQoEBAICAhIEtwECSRpLIE91dHB1
dCBvbmx5LiBDb2xvciBzcGFjZSBvZiB0aGUgaW1hZ2UgKGUuZy4sICJSR0IiLCAiQ01ZSyIs
ICJHcmF5c2NhbGUiKS4KCg0KBQQCAgIGEgS3AQIMCg0KBQQCAgIBEgS3AQ0YCg0KBQQCAgID
EgS3ARscCg0KBQQCAgIIEgS3AR1IChAKCAQCAgIInAgAEgS3AR5HCkoKBAQCAgMSBLoBAkIa
PCBPdXRwdXQgb25seS4gQml0IGRlcHRoIG9mIHRoZSBpbWFnZSAoZS5nLiwgOC1iaXQsIDE2
LWJpdCkuCgoNCgUEAgIDBRIEugECBwoNCgUEAgIDARIEugEIEQoNCgUEAgIDAxIEugEUFQoN
CgUEAgIDCBIEugEWQQoQCggEAgIDCJwIABIEugEXQAo/CgIEAxIGvgEA1wEBGjEgU3RhbmRh
cmQgY2hhcmFjdGVyaXN0aWNzIG9mIGEgdmlkZW8gbWVkaWEgdmlldy4KCgsKAwQDARIEvgEI
HAozCgQEAwIAEgTAAQI+GiUgT3V0cHV0IG9ubHkuIFZpZGVvIHdpZHRoIGluIHBpeGVscy4K
Cg0KBQQDAgAFEgTAAQIHCg0KBQQDAgABEgTAAQgNCg0KBQQDAgADEgTAARARCg0KBQQDAgAI
EgTAARI9ChAKCAQDAgAInAgAEgTAARM8CjQKBAQDAgESBMMBAj8aJiBPdXRwdXQgb25seS4g
VmlkZW8gaGVpZ2h0IGluIHBpeGVscy4KCg0KBQQDAgEFEgTDAQIHCg0KBQQDAgEBEgTDAQgO
Cg0KBQQDAgEDEgTDARESCg0KBQQDAgEIEgTDARM+ChAKCAQDAgEInAgAEgTDARQ9Ci4KBAQD
AgISBsYBAscBMhoeIE91dHB1dCBvbmx5LiBWaWRlbyBkdXJhdGlvbi4KCg0KBQQDAgIGEgTG
AQIaCg0KBQQDAgIBEgTGARsjCg0KBQQDAgIDEgTGASYnCg0KBQQDAgIIEgTHAQYxChAKCAQD
AgIInAgAEgTHAQcwCjwKBAQDAgMSBMoBAkQaLiBPdXRwdXQgb25seS4gRnJhbWUgcmF0ZSAo
ZnJhbWVzIHBlciBzZWNvbmQpLgoKDQoFBAMCAwUSBMoBAggKDQoFBAMCAwESBMoBCRMKDQoF
BAMCAwMSBMoBFhcKDQoFBAMCAwgSBMoBGEMKEAoIBAMCAwicCAASBMoBGUIKPAoEBAMCBBIE
zQECTxouIE91dHB1dCBvbmx5LiBBdWRpbyBjb2RlY3MgdXNlZCBpbiB0aGUgdmlkZW8uCgoN
CgUEAwIEBBIEzQECCgoNCgUEAwIEBRIEzQELEQoNCgUEAwIEARIEzQESHgoNCgUEAwIEAxIE
zQEhIgoNCgUEAwIECBIEzQEjTgoQCggEAwIECJwIABIEzQEkTQo8CgQEAwIFEgTQAQJPGi4g
T3V0cHV0IG9ubHkuIFZpZGVvIGNvZGVjcyB1c2VkIGluIHRoZSB2aWRlby4KCg0KBQQDAgUE
EgTQAQIKCg0KBQQDAgUFEgTQAQsRCg0KBQQDAgUBEgTQARIeCg0KBQQDAgUDEgTQASEiCg0K
BQQDAgUIEgTQASNOChAKCAQDAgUInAgAEgTQASRNCjoKBAQDAgYSBNMBAksaLCBPdXRwdXQg
b25seS4gQml0cmF0ZSBvZiB0aGUgdmlkZW8gaW4ga2Jwcy4KCg0KBQQDAgYFEgTTAQIHCg0K
BQQDAgYBEgTTAQgaCg0KBQQDAgYDEgTTAR0eCg0KBQQDAgYIEgTTAR9KChAKCAQDAgYInAgA
EgTTASBJCjoKBAQDAgcSBNYBAksaLCBPdXRwdXQgb25seS4gQml0cmF0ZSBvZiB0aGUgYXVk
aW8gaW4ga2Jwcy4KCg0KBQQDAgcFEgTWAQIHCg0KBQQDAgcBEgTWAQgaCg0KBQQDAgcDEgTW
AR0eCg0KBQQDAgcIEgTWAR9KChAKCAQDAgcInAgAEgTWASBJCjMKAgQEEgbaAQDeAQEaJSBD
YXJhY3RlcmlzdGljcyBvZiBvdGhlciBmaWxlIHR5cGVzLgoKCwoDBAQBEgTaAQgbCj4KBAQE
AgASBtwBAt0BMhouIE91dHB1dCBvbmx5LiBHZW5lcmljIG1hcCBvZiBjaGFyYWN0ZXJpc3Rp
Y3MuCgoNCgUEBAIABhIE3AECFQoNCgUEBAIAARIE3AEWJQoNCgUEBAIAAxIE3AEoKQoNCgUE
BAIACBIE3QEGMQoQCggEBAIACJwIABIE3QEHMAqQAQoCBAUSBuIBAIQCARqBASBSZXByZXNl
bnRzIGEgc3BlY2lmaWMgYWx0ZXJuYXRlIHZlcnNpb24gb3IgInZpZXciIG9mIGEgZmlsZSBv
YmplY3QsCiBzdWNoIGFzIGEgc3VtbWFyeSwgYSB0aHVtYm5haWwsIGEgdHJhbnNsYXRlZCB2
ZXJzaW9uLCBldGMuCgoLCgMEBQESBOIBCBAKowEKBAQFCAASBuYBAvIBAxqSASBDaGFyYWN0
ZXJpc3RpY3Mgb2YgdGhlIG1lZGlhIHZpZXcsIGFsbG93aW5nIGZvciBmbGV4aWJsZSBleHRl
bnNpb25zLgogTWV0YWRhdGEgaXMgYWx3YXlzIGludGVybmFsbHkgZ2VuZXJhdGVkIGJ5IHRo
ZSBwcm9jZXNzIGNyZWF0aW5nCiB0aGUgdmlldy4KCg0KBQQFCAABEgTmAQgXCkYKBAQFAgAS
BugBBOkBNBo2IE91dHB1dCBvbmx5LiBDaGFyYWN0ZXJpc3RpY3Mgb2YgYW4gaW1hZ2UgbWVk
aWEgdmlldy4KCg0KBQQFAgAGEgToAQQYCg0KBQQFAgABEgToARkuCg0KBQQFAgADEgToATEy
Cg0KBQQFAgAIEgTpAQgzChAKCAQFAgAInAgAEgTpAQkyCkUKBAQFAgESBuwBBO0BNBo1IE91
dHB1dCBvbmx5LiBDaGFyYWN0ZXJpc3RpY3Mgb2YgYSB2aWRlbyBtZWRpYSB2aWV3LgoKDQoF
BAUCAQYSBOwBBBgKDQoFBAUCAQESBOwBGS4KDQoFBAUCAQMSBOwBMTIKDQoFBAUCAQgSBO0B
CDMKEAoIBAUCAQicCAASBO0BCTIKQwoEBAUCAhIG8AEE8QE0GjMgT3V0cHV0IG9ubHkuIENo
YXJhY3RlcmlzdGljcyBvZiBvdGhlciBmaWxlIHR5cGVzLgoKDQoFBAUCAgYSBPABBBcKDQoF
BAUCAgESBPABGCwKDQoFBAUCAgMSBPABLzAKDQoFBAUCAggSBPEBCDMKEAoIBAUCAgicCAAS
BPEBCTIKRwoEBAUCAxIE9QECQRo5IE91dHB1dCBvbmx5LiBHbG9iYWxseSBVbmlxdWUgaWQg
Zm9yIHRoaXMgc3BlY2lmaWMgdmlldy4KCg0KBQQFAgMFEgT1AQIICg0KBQQFAgMBEgT1AQkQ
Cg0KBQQFAgMDEgT1ARMUCg0KBQQFAgMIEgT1ARVAChAKCAQFAgMInAgAEgT1ARY/Cj8KBAQF
AgQSBPgBAj0aMSBPdXRwdXQgb25seS4gVGhlIFVSSSB0byBhY2Nlc3MgdGhpcyBtZWRpYSB2
aWV3LgoKDQoFBAUCBAUSBPgBAggKDQoFBAUCBAESBPgBCQwKDQoFBAUCBAMSBPgBDxAKDQoF
BAUCBAgSBPgBETwKEAoIBAUCBAicCAASBPgBEjsKZAoEBAUCBRIE/AECQxpWIE91dHB1dCBv
bmx5LiBNSU1FIHR5cGUgKGUuZy4sICJpbWFnZS9qcGVnIiwgImltYWdlL3BuZyIsICJ0ZXh0
L3BsYWluIiwKICJ2aWRlby9tcDQiKQoKDQoFBAUCBQUSBPwBAggKDQoFBAUCBQESBPwBCRIK
DQoFBAUCBQMSBPwBFRYKDQoFBAUCBQgSBPwBF0IKEAoIBAUCBQicCAASBPwBGEEKOwoEBAUC
BhIE/wECQhotIE91dHB1dCBvbmx5LiBUaGUgc2l6ZSBvZiB0aGUgdmlldyBpbiBieXRlcy4K
Cg0KBQQFAgYFEgT/AQIHCg0KBQQFAgYBEgT/AQgRCg0KBQQFAgYDEgT/ARQVCg0KBQQFAgYI
EgT/ARZBChAKCAQFAgYInAgAEgT/ARdACj0KBAQFAgcSBoICAoMCMhotIE91dHB1dCBvbmx5
LiBUaGUgdGltZSB0aGUgdmlldyB3YXMgY3JlYXRlZC4KCg0KBQQFAgcGEgSCAgIbCg0KBQQF
AgcBEgSCAhwnCg0KBQQFAgcDEgSCAiorCg0KBQQFAgcIEgSDAgYxChAKCAQFAgcInAgAEgSD
AgcwCkYKAgQGEgaHAgDGAgEaOCBSZXByZXNlbnRzIGEgZmlsZSBhdHRhY2hlZCB0byBhIHNl
c3Npb24gKGNvbnRleHQgZmlsZSkKCgsKAwQGARIEhwIIFAowCgQEBgIAEgSJAgJBGiIgT3V0
cHV0IG9ubHkuIFRoZSBJRCBvZiB0aGUgZmlsZS4KCg0KBQQGAgAFEgSJAgIICg0KBQQGAgAB
EgSJAgkQCg0KBQQGAgADEgSJAhMUCg0KBQQGAgAIEgSJAhVAChAKCAQGAgAInAgAEgSJAhY/
CjsKBAQGAgESBIwCAj4aLSBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIGZpbGUgdXBs
b2FkZWQuCgoNCgUEBgIBBRIEjAICCAoNCgUEBgIBARIEjAIJDQoNCgUEBgIBAxIEjAIQEQoN
CgUEBgIBCBIEjAISPQoQCggEBgIBCJwIABIEjAITPApyCgQEBgICEgSQAgIXGmQgVGhlIGNv
bnRlbnQgdHlwZSBvZiB0aGUgZmlsZSwgc2VlCiBodHRwczovL3d3dy5pYW5hLm9yZy9hc3Np
Z25tZW50cy9tZWRpYS10eXBlcy9tZWRpYS10eXBlcy54aHRtbC4KCg0KBQQGAgIFEgSQAgII
Cg0KBQQGAgIBEgSQAgkSCg0KBQQGAgIDEgSQAhUWCkMKBAQGAgMSBJMCAkIaNSBPdXRwdXQg
b25seS4gVGhlIHNpemUgb2YgdGhlIGNvbnRleHQgZmlsZSBpbiBieXRlcy4KCg0KBQQGAgMF
EgSTAgIHCg0KBQQGAgMBEgSTAggRCg0KBQQGAgMDEgSTAhQVCg0KBQQGAgMIEgSTAhZBChAK
CAQGAgMInAgAEgSTAhdACqMECgQEBgIEEgSeAgJDGpQEIE9wdGlvbmFsLiBUaGUgb3JpZ2lu
YWwgbG9jYXRpb24gb2YgdGhlIGZpbGUuIEl0IG1heSBiZSBhIGxvY2FsIGZpbGUgcGF0aCwK
IG9yIGFueSBvdGhlciBVUkkgdGhhdCBhbGxvd3MgYWNjZXNzaW5nIHRoZSBmaWxlIGluIGFu
IGV4dGVybmFsIHN5c3RlbS4KIFRoZXJlIGFyZSB0d28gc2NlbmFyaW9zIGluIHdoaWNoIHRo
aXMgdXJsIG1heSBiZSBlbXB0eToKIDEuIElmIHRoZSBmaWxlIHdhcyBzZW50IGFzIGlubGlu
ZSBkYXRhIChlLmcuIHBhc3RlZCBmcm9tIHRoZSBjbGlwYm9hcmQpLgogMi4gSWYgdGhlIG9y
aWdpbmFsIGxvY2F0aW9uIGlzIG5vdCBhdmFpbGFibGUuCgogTm90ZSB0aGF0IHRoZXJlJ3Mg
bm8gZ3VhcmFudGVlIHRoYXQgdGhlIFVSSSB3aWxsIGJlIHBvaW50aW5nIHRvIGEgdmFsaWQK
IG9yIGFjdHVhbGx5IGV4aXN0aW5nIGZpbGUuIEZvciBleGFtcGxlLCBhIGZpbGUgbWlnaHQg
aGF2ZSBiZWVuIHVwbG9hZGVkCiB0byB0aGUgc2Vzc2lvbiwgYW5kIHRoZW4gZGVsZXRlZCBm
cm9tIHRoZSBvcmlnaW5hbCBzb3VyY2UuCgoNCgUEBgIEBRIEngICCAoNCgUEBgIEARIEngIJ
FQoNCgUEBgIEAxIEngIYGQoNCgUEBgIECBIEngIaQgoQCggEBgIECJwIABIEngIbQQpGCgQE
BgIFEgShAgJQGjggT3B0aW9uYWwuIFRoZSB0eXBlIG9mIHRoZSBvcmlnaW5hbCBzb3VyY2Ug
b2YgdGhlIGZpbGUuCgoNCgUEBgIFBhIEoQICDAoNCgUEBgIFARIEoQINIQoNCgUEBgIFAxIE
oQIkJgoNCgUEBgIFCBIEoQInTwoQCggEBgIFCJwIABIEoQIoTgrEAQoEBAYCBhIGpgICpwIy
GrMBIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgZmlsZSB3YXMgdXBsb2FkZWQgKElmIHRo
aXMgaXMgYSBmaWxlCiBnZW5lcmF0ZWQgYnkgYW4gaW50ZXJuYWwgcHJvY2VzcyBhbmQgdGhl
biBtYWRlIGF2YWlsYWJsZSB0byB0aGUgc2Vzc2lvbiwKIHRoaXMgaW5kaWNhdGVzIHRoZSBt
b21lbnQgaXQgaGFwcGVuZWQpLgoKDQoFBAYCBgYSBKYCAhsKDQoFBAYCBgESBKYCHCcKDQoF
BAYCBgMSBKYCKiwKDQoFBAYCBggSBKcCBjEKEAoIBAYCBgicCAASBKcCBzAKtgEKBAQGAgcS
BqwCAq0CMhqlASBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIGZpbGUgd2FzIGFkZGVkIHRv
IHRoZSBzZXNzaW9uLiBOb3RlIHRoYXQgaWYgYQogZmlsZSB3YXMgYWRkZWQsIHRoZW4gbW9k
aWZpZWQgZXh0ZXJuYWxseSwgdGhlbiBhZGRlZCBhZ2FpbiwgdGhlIGFkZCB0aW1lCiB3aWxs
IGJlIHVwZGF0ZWQuCgoNCgUEBgIHBhIErAICGwoNCgUEBgIHARIErAIcKQoNCgUEBgIHAxIE
rAIsLgoNCgUEBgIHCBIErQIGMQoQCggEBgIHCJwIABIErQIHMArPAQoEBAYCCBIEsgICTRrA
ASBPcHRpb25hbC4gUmVwcmVzZW50cyBtZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBmaWxlIHRo
YXQgY2FuIHN1aXQgcGFydGljdWxhcgogdXNlIGNhc2VzLiBUaGUgcHJlZml4ICJnb29nbGUu
IiBpcyByZXNlcnZlZCBmb3IgdGhlIGtleSBmb3IgdXNlIGJ5CiBHb29nbGUsIGJ1dCBvdGhl
ciBwcmVmaXhlcyBjYW4gYmUgZnJlZWx5IHVzZWQuCgoNCgUEBgIIBhIEsgICFQoNCgUEBgII
ARIEsgIWHgoNCgUEBgIIAxIEsgIhIwoNCgUEBgIICBIEsgIkTAoQCggEBgIICJwIABIEsgIl
Swr8AgoEBAYCCRIEuQICRxrtAiBPdXRwdXQgb25seS4gVGhlCiBbQXNzaXN0YW50U2Vydmlj
ZS5Eb3dubG9hZFNlc3Npb25GaWxlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuQXNzaXN0YW50U2VydmljZS5Eb3dubG9hZFNlc3Npb25GaWxlXQogVVJMIHRvIGRv
d25sb2FkIHRoZSBmaWxlLiBUaGlzIFVSTCB3aWxsIG5lZWQgdGhlIHNhbWUgY3JlZGVudGlh
bHMgYXMKIFtBc3Npc3RhbnRTZXJ2aWNlLkxpc3RTZXNzaW9uRmlsZU1ldGFkYXRhXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQXNzaXN0YW50U2VydmljZS5MaXN0
U2Vzc2lvbkZpbGVNZXRhZGF0YV0KIG1ldGhvZCBhbmQgd2lsbCBwcm92aWRlIHRoZSByZXNv
dXJjZS4KCg0KBQQGAgkFEgS5AgIICg0KBQQGAgkBEgS5AgkVCg0KBQQGAgkDEgS5AhgaCg0K
BQQGAgkIEgS5AhtGChAKCAQGAgkInAgAEgS5AhxFCjEKBAQGAgoSBLwCAlAaIyBPcHRpb25h
bC4gVGhlIG9yaWdpbiBvZiB0aGUgZmlsZS4KCg0KBQQGAgoGEgS8AgIQCg0KBQQGAgoBEgS8
AhEhCg0KBQQGAgoDEgS8AiQmCg0KBQQGAgoIEgS8AidPChAKCAQGAgoInAgAEgS8AihOCuAB
CgQEBgILEgTFAgJPGtEBIE91dHB1dCBvbmx5LiBBbHRlcm5hdGUgdmlld3Mgb2YgdGhpcyBm
aWxlIG9iamVjdC4gRWFjaCBmaWxlIHZpZXcgaXMKIGF0dGFjaGVkIHRvIGEgc3BlY2lmaWMg
cm9sZS4gUG9zc2libGUgZXhhbXBsZSBrZXlzOgogICAtICJ0aHVtYm5haWwiCiAgIC0gIm1v
YmlsZV90aHVtYm5haWwiCiAgIC0gImNsaXAiCiAgIC0gInN1bW1hcnkiCiAgIC0gInRyYW5z
bGF0aW9uIgoKDQoFBAYCCwYSBMUCAhcKDQoFBAYCCwESBMUCGB0KDQoFBAYCCwMSBMUCICIK
DQoFBAYCCwgSBMUCI04KEAoIBAYCCwicCAASBMUCJE1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::Session ===
    # Fields for Session
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1alpha.Session.State)
    # Field: user_pseudo_id Type: 9 ()
    # Field: turns Type: 11 (.google.cloud.discoveryengine.v1alpha.Session.Turn)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: is_pinned Type: 8 ()

# Enum: Session::State
our $Session_STATE_UNSPECIFIED = 0;
our $Session_IN_PROGRESS = 1;

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::Query ===
    # Fields for Query
    # Field: text Type: 9 ()
    # Field: query_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::ImageCharacteristics ===
    # Fields for ImageCharacteristics
    # Field: width Type: 5 ()
    # Field: height Type: 5 ()
    # Field: color_space Type: 14 (.google.cloud.discoveryengine.v1alpha.ImageCharacteristics.ColorSpace)
    # Field: bit_depth Type: 5 ()

# Enum: ImageCharacteristics::ColorSpace
our $ImageCharacteristics_COLOR_SPACE_UNSPECIFIED = 0;
our $ImageCharacteristics_RGB = 1;
our $ImageCharacteristics_CMYK = 2;
our $ImageCharacteristics_GRAYSCALE = 3;
our $ImageCharacteristics_YUV = 4;
our $ImageCharacteristics_OTHER_COLOR_SPACE = 5;

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::VideoCharacteristics ===
    # Fields for VideoCharacteristics
    # Field: width Type: 5 ()
    # Field: height Type: 5 ()
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: frame_rate Type: 1 ()
    # Field: audio_codecs Type: 9 ()
    # Field: video_codecs Type: 9 ()
    # Field: video_bitrate_kbps Type: 5 ()
    # Field: audio_bitrate_kbps Type: 5 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics ===
    # Fields for FileCharacteristics
    # Field: characteristics Type: 11 (.google.cloud.discoveryengine.v1alpha.FileCharacteristics.CharacteristicsEntry)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::FileView ===
    # Fields for FileView
    # Field: image_characteristics Type: 11 (.google.cloud.discoveryengine.v1alpha.ImageCharacteristics)
    # Field: video_characteristics Type: 11 (.google.cloud.discoveryengine.v1alpha.VideoCharacteristics)
    # Field: file_characteristics Type: 11 (.google.cloud.discoveryengine.v1alpha.FileCharacteristics)
    # Field: view_id Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: byte_size Type: 3 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata ===
    # Fields for FileMetadata
    # Field: file_id Type: 9 ()
    # Field: name Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: byte_size Type: 3 ()
    # Field: original_uri Type: 9 ()
    # Field: original_source_type Type: 14 (.google.cloud.discoveryengine.v1alpha.FileSource)
    # Field: upload_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_add_time Type: 11 (.google.protobuf.Timestamp)
    # Field: metadata Type: 11 (.google.cloud.discoveryengine.v1alpha.FileMetadata.MetadataEntry)
    # Field: download_uri Type: 9 ()
    # Field: file_origin_type Type: 14 (.google.cloud.discoveryengine.v1alpha.FileOriginType)
    # Field: views Type: 11 (.google.cloud.discoveryengine.v1alpha.FileMetadata.ViewsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Session - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/session.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Session;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Session::Session->new({
        name => $name,
        display_name => $display_name,
        state => $state,
        user_pseudo_id => $user_pseudo_id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Session::Session->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/session.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::Session

External session proto definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/{project}/locations/global/collections/{collection}/engines/{engine}/sessions/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the session.

This field is used to identify the session in the UI.
By default, the display name is the first turn query text in the session.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::Session::State>)

The state of the session.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking users.

=item * C<< $msg->turns() >> / C<< $msg->turns($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn>)

Turns.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the session started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the session finished.

=item * C<< $msg->is_pinned() >> / C<< $msg->is_pinned($value) >>

Type: C<Bool>

Optional. Whether the session is pinned, pinned session will be displayed
on the top of the session list.

=back

=head3 Enum: Session::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::Query

Defines a user inputed query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Plain text.

=item * C<< $msg->query_id() >> / C<< $msg->query_id($value) >>

Type: C<String>

Output only. Unique Id for the query.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::ImageCharacteristics

Standard characteristics of an image media view.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Int32>

Output only. Image width in pixels.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Int32>

Output only. Image height in pixels.

=item * C<< $msg->color_space() >> / C<< $msg->color_space($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::ImageCharacteristics::ColorSpace>)

Output only. Color space of the image (e.g., "RGB", "CMYK", "Grayscale").

=item * C<< $msg->bit_depth() >> / C<< $msg->bit_depth($value) >>

Type: C<Int32>

Output only. Bit depth of the image (e.g., 8-bit, 16-bit).

=back

=head3 Enum: ImageCharacteristics::ColorSpace

=over 4

=item * C<COLOR_SPACE_UNSPECIFIED> => C<0>

=item * C<RGB> => C<1>

=item * C<CMYK> => C<2>

=item * C<GRAYSCALE> => C<3>

=item * C<YUV> => C<4>

=item * C<OTHER_COLOR_SPACE> => C<5>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::VideoCharacteristics

Standard characteristics of a video media view.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Int32>

Output only. Video width in pixels.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Int32>

Output only. Video height in pixels.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. Video duration.

=item * C<< $msg->frame_rate() >> / C<< $msg->frame_rate($value) >>

Type: C<Double>

Output only. Frame rate (frames per second).

=item * C<< $msg->audio_codecs() >> / C<< $msg->audio_codecs($value) >>

Type: C<String>

Output only. Audio codecs used in the video.

=item * C<< $msg->video_codecs() >> / C<< $msg->video_codecs($value) >>

Type: C<String>

Output only. Video codecs used in the video.

=item * C<< $msg->video_bitrate_kbps() >> / C<< $msg->video_bitrate_kbps($value) >>

Type: C<Int32>

Output only. Bitrate of the video in kbps.

=item * C<< $msg->audio_bitrate_kbps() >> / C<< $msg->audio_bitrate_kbps($value) >>

Type: C<Int32>

Output only. Bitrate of the audio in kbps.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics

Caracteristics of other file types.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->characteristics() >> / C<< $msg->characteristics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics::CharacteristicsEntry>)

Output only. Generic map of characteristics.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::FileView

Represents a specific alternate version or "view" of a file object,
such as a summary, a thumbnail, a translated version, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_characteristics() >> / C<< $msg->image_characteristics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::ImageCharacteristics>)

Output only. Characteristics of an image media view.

=item * C<< $msg->video_characteristics() >> / C<< $msg->video_characteristics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::VideoCharacteristics>)

Output only. Characteristics of a video media view.

=item * C<< $msg->file_characteristics() >> / C<< $msg->file_characteristics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics>)

Output only. Characteristics of other file types.

=item * C<< $msg->view_id() >> / C<< $msg->view_id($value) >>

Type: C<String>

Output only. Globally Unique id for this specific view.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Output only. The URI to access this media view.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Output only. MIME type (e.g., "image/jpeg", "image/png", "text/plain",
"video/mp4")

=item * C<< $msg->byte_size() >> / C<< $msg->byte_size($value) >>

Type: C<Int64>

Output only. The size of the view in bytes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the view was created.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata

Represents a file attached to a session (context file)

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_id() >> / C<< $msg->file_id($value) >>

Type: C<String>

Output only. The ID of the file.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the file uploaded.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

The content type of the file, see
https://www.iana.org/assignments/media-types/media-types.xhtml.

=item * C<< $msg->byte_size() >> / C<< $msg->byte_size($value) >>

Type: C<Int64>

Output only. The size of the context file in bytes.

=item * C<< $msg->original_uri() >> / C<< $msg->original_uri($value) >>

Type: C<String>

Optional. The original location of the file. It may be a local file path,
or any other URI that allows accessing the file in an external system.
There are two scenarios in which this url may be empty:
1. If the file was sent as inline data (e.g. pasted from the clipboard).
2. If the original location is not available.

Note that there's no guarantee that the URI will be pointing to a valid
or actually existing file. For example, a file might have been uploaded
to the session, and then deleted from the original source.

=item * C<< $msg->original_source_type() >> / C<< $msg->original_source_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::FileSource>)

Optional. The type of the original source of the file.

=item * C<< $msg->upload_time() >> / C<< $msg->upload_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the file was uploaded (If this is a file
generated by an internal process and then made available to the session,
this indicates the moment it happened).

=item * C<< $msg->last_add_time() >> / C<< $msg->last_add_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the file was added to the session. Note that if a
file was added, then modified externally, then added again, the add time
will be updated.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::MetadataEntry>)

Optional. Represents metadata related to the file that can suit particular
use cases. The prefix "google." is reserved for the key for use by
Google, but other prefixes can be freely used.

=item * C<< $msg->download_uri() >> / C<< $msg->download_uri($value) >>

Type: C<String>

Output only. The
[AssistantService.DownloadSessionFile][google.cloud.discoveryengine.v1alpha.AssistantService.DownloadSessionFile]
URL to download the file. This URL will need the same credentials as
[AssistantService.ListSessionFileMetadata][google.cloud.discoveryengine.v1alpha.AssistantService.ListSessionFileMetadata]
method and will provide the resource.

=item * C<< $msg->file_origin_type() >> / C<< $msg->file_origin_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::FileOriginType>)

Optional. The origin of the file.

=item * C<< $msg->views() >> / C<< $msg->views($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::ViewsEntry>)

Output only. Alternate views of this file object. Each file view is
attached to a specific role. Possible example keys:
  - "thumbnail"
  - "mobile_thumbnail"
  - "clip"
  - "summary"
  - "translation"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Session::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
