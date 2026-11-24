package Google::Cloud::Dialogflow::Cx::V3::Generator;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9nZW5lcmF0b3IucHJvdG8SHWdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo3Z29vZ2xlL2Nsb3VkL2RpYWxvZ2Zs
b3cvY3gvdjMvZ2VuZXJhdGl2ZV9zZXR0aW5ncy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2Vt
cHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byK2BgoJR2VuZXJh
dG9yEhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rp
c3BsYXlOYW1lEksKC3Byb21wdF90ZXh0GAMgASgLMiUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuUGhyYXNlQgPgQQJSCnByb21wdFRleHQSXQoMcGxhY2Vob2xkZXJzGAUgAygL
MjQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdG9yLlBsYWNlaG9sZGVy
QgPgQQFSDHBsYWNlaG9sZGVycxJdChJsbG1fbW9kZWxfc2V0dGluZ3MYCSABKAsyLy5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5MbG1Nb2RlbFNldHRpbmdzUhBsbG1Nb2RlbFNl
dHRpbmdzEmAKD21vZGVsX3BhcmFtZXRlchgIIAEoCzI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLkdlbmVyYXRvci5Nb2RlbFBhcmFtZXRlclIObW9kZWxQYXJhbWV0ZXIaMQoL
UGxhY2Vob2xkZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUa0wEKDk1v
ZGVsUGFyYW1ldGVyEiUKC3RlbXBlcmF0dXJlGAEgASgCSABSC3RlbXBlcmF0dXJliAEBEi0K
EG1heF9kZWNvZGVfc3RlcHMYAiABKAVIAVIObWF4RGVjb2RlU3RlcHOIAQESGAoFdG9wX3AY
AyABKAJIAlIEdG9wUIgBARIYCgV0b3BfaxgEIAEoBUgDUgR0b3BLiAEBQg4KDF90ZW1wZXJh
dHVyZUITChFfbWF4X2RlY29kZV9zdGVwc0IICgZfdG9wX3BCCAoGX3RvcF9rOnfqQXQKI2Rp
YWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vR2VuZXJhdG9yEk1wcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0vZ2VuZXJhdG9ycy97Z2VuZXJh
dG9yfSIhCgZQaHJhc2USFwoEdGV4dBgBIAEoCUID4EECUgR0ZXh0Ir0BChVMaXN0R2VuZXJh
dG9yc1JlcXVlc3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI2RpYWxvZ2Zsb3cuZ29vZ2xl
YXBpcy5jb20vR2VuZXJhdG9yUgZwYXJlbnQSIwoNbGFuZ3VhZ2VfY29kZRgCIAEoCVIMbGFu
Z3VhZ2VDb2RlEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgE
IAEoCVIJcGFnZVRva2VuIooBChZMaXN0R2VuZXJhdG9yc1Jlc3BvbnNlEkgKCmdlbmVyYXRv
cnMYASADKAsyKC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5HZW5lcmF0b3JSCmdl
bmVyYXRvcnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuInsKE0dl
dEdlbmVyYXRvclJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNkaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29tL0dlbmVyYXRvclIEbmFtZRIjCg1sYW5ndWFnZV9jb2RlGAIgASgJUgxs
YW5ndWFnZUNvZGUizwEKFkNyZWF0ZUdlbmVyYXRvclJlcXVlc3QSQwoGcGFyZW50GAEgASgJ
QivgQQL6QSUSI2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vR2VuZXJhdG9yUgZwYXJlbnQS
SwoJZ2VuZXJhdG9yGAIgASgLMiguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2Vu
ZXJhdG9yQgPgQQJSCWdlbmVyYXRvchIjCg1sYW5ndWFnZV9jb2RlGAMgASgJUgxsYW5ndWFn
ZUNvZGUixwEKFlVwZGF0ZUdlbmVyYXRvclJlcXVlc3QSSwoJZ2VuZXJhdG9yGAEgASgLMigu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdG9yQgPgQQJSCWdlbmVyYXRv
chIjCg1sYW5ndWFnZV9jb2RlGAIgASgJUgxsYW5ndWFnZUNvZGUSOwoLdXBkYXRlX21hc2sY
AyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIm8KFkRlbGV0
ZUdlbmVyYXRvclJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNkaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29tL0dlbmVyYXRvclIEbmFtZRIUCgVmb3JjZRgCIAEoCFIFZm9yY2Uy6QgK
CkdlbmVyYXRvcnMSxwEKDkxpc3RHZW5lcmF0b3JzEjQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuTGlzdEdlbmVyYXRvcnNSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuTGlzdEdlbmVyYXRvcnNSZXNwb25zZSJIgtPkkwI5EjcvdjMve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qfS9nZW5lcmF0b3Jz2kEGcGFyZW50ErQB
CgxHZXRHZW5lcmF0b3ISMi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5HZXRHZW5l
cmF0b3JSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdG9y
IkaC0+STAjkSNy92My97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2dl
bmVyYXRvcnMvKn3aQQRuYW1lEtEBCg9DcmVhdGVHZW5lcmF0b3ISNS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52My5DcmVhdGVHZW5lcmF0b3JSZXF1ZXN0GiguZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdG9yIl2C0+STAkQiNy92My97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyp9L2dlbmVyYXRvcnM6CWdlbmVyYXRvctpBEHBh
cmVudCxnZW5lcmF0b3IS4AEKD1VwZGF0ZUdlbmVyYXRvchI1Lmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLlVwZGF0ZUdlbmVyYXRvclJlcXVlc3QaKC5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5HZW5lcmF0b3IibILT5JMCTjJBL3YzL3tnZW5lcmF0b3IubmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2dlbmVyYXRvcnMvKn06CWdlbmVyYXRv
ctpBFWdlbmVyYXRvcix1cGRhdGVfbWFzaxKoAQoPRGVsZXRlR2VuZXJhdG9yEjUuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRGVsZXRlR2VuZXJhdG9yUmVxdWVzdBoWLmdvb2ds
ZS5wcm90b2J1Zi5FbXB0eSJGgtPkkwI5KjcvdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hZ2VudHMvKi9nZW5lcmF0b3JzLyp92kEEbmFtZRp4ykEZZGlhbG9nZmxvdy5nb29n
bGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxh
dGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFsb2dmbG93QrEBCiFj
b20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNCDkdlbmVyYXRvclByb3RvUAFaMWNs
b3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9jeC9hcGl2My9jeHBiO2N4cGKiAgJERqoC
HUdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LkN4LlYz6gIhR29vZ2xlOjpDbG91ZDo6RGlhbG9n
Zmxvdzo6Q1g6OlYzSp9GCgcSBQ4AkQIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
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
bnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAQQoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA6CgkKAggl
EgMaADoKCAoBCBIDGwBICgkKAggLEgMbAEgKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBID
HQAvCgkKAggIEgMdAC8KCAoBCBIDHgA6CgkKAggBEgMeADoKCAoBCBIDHwAgCgkKAggkEgMf
ACAKCAoBCBIDIAA6CgkKAggtEgMgADoKWAoCBgASBCMAUgEaTCBTZXJ2aWNlIGZvciBtYW5h
Z2luZyBbR2VuZXJhdG9yc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJh
dG9yXQoKCgoDBgABEgMjCBIKCgoDBgADEgMkAkEKDAoFBgADmQgSAyQCQQoLCgMGAAMSBCUC
JzMKDQoFBgADmggSBCUCJzMKSgoEBgACABIEKgIvAxo8IFJldHVybnMgdGhlIGxpc3Qgb2Yg
YWxsIGdlbmVyYXRvcnMgaW4gdGhlIHNwZWNpZmllZCBhZ2VudC4KCgwKBQYAAgABEgMqBhQK
DAoFBgACAAISAyoVKgoMCgUGAAIAAxIDKjVLCg0KBQYAAgAEEgQrBC0GChEKCQYAAgAEsMq8
IhIEKwQtBgoMCgUGAAIABBIDLgQ0Cg8KCAYAAgAEmwgAEgMuBDQKMgoEBgACARIEMgI3Axok
IFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIGdlbmVyYXRvci4KCgwKBQYAAgEBEgMyBhIKDAoF
BgACAQISAzITJgoMCgUGAAIBAxIDMjE6Cg0KBQYAAgEEEgQzBDUGChEKCQYAAgEEsMq8IhIE
MwQ1BgoMCgUGAAIBBBIDNgQyCg8KCAYAAgEEmwgAEgM2BDIKOwoEBgACAhIEOgJAAxotIENy
ZWF0ZXMgYSBnZW5lcmF0b3IgaW4gdGhlIHNwZWNpZmllZCBhZ2VudC4KCgwKBQYAAgIBEgM6
BhUKDAoFBgACAgISAzoWLAoMCgUGAAICAxIDOjdACg0KBQYAAgIEEgQ7BD4GChEKCQYAAgIE
sMq8IhIEOwQ+BgoMCgUGAAICBBIDPwQ+Cg8KCAYAAgIEmwgAEgM/BD4KLwoEBgACAxIEQwJJ
AxohIFVwZGF0ZSB0aGUgc3BlY2lmaWVkIGdlbmVyYXRvci4KCgwKBQYAAgMBEgNDBhUKDAoF
BgACAwISA0MWLAoMCgUGAAIDAxIDQzdACg0KBQYAAgMEEgREBEcGChEKCQYAAgMEsMq8IhIE
RARHBgoMCgUGAAIDBBIDSARDCg8KCAYAAgMEmwgAEgNIBEMKMQoEBgACBBIETAJRAxojIERl
bGV0ZXMgdGhlIHNwZWNpZmllZCBnZW5lcmF0b3JzLgoKDAoFBgACBAESA0wGFQoMCgUGAAIE
AhIDTBYsCgwKBQYAAgQDEgNMN0wKDQoFBgACBAQSBE0ETwYKEQoJBgACBASwyrwiEgRNBE8G
CgwKBQYAAgQEEgNQBDIKDwoIBgACBASbCAASA1AEMgr+AQoCBAASBVgAnAEBGvABIEdlbmVy
YXRvcnMgY29udGFpbiBwcm9tcHQgdG8gYmUgc2VudCB0byB0aGUgTExNIG1vZGVsIHRvIGdl
bmVyYXRlIHRleHQuIFRoZQogcHJvbXB0IGNhbiBjb250YWluIHBhcmFtZXRlcnMgd2hpY2gg
d2lsbCBiZSByZXNvbHZlZCBiZWZvcmUgY2FsbGluZyB0aGUKIG1vZGVsLiBJdCBjYW4gb3B0
aW9uYWxseSBjb250YWluIGJhbm5lZCBwaHJhc2VzIHRvIGVuc3VyZSB0aGUgbW9kZWwgcmVz
cG9uc2VzCiBhcmUgc2FmZS4KCgoKAwQAARIDWAgRCgsKAwQABxIEWQJcBAoNCgUEAAedCBIE
WQJcBApDCgQEAAMAEgRfAmUDGjUgUmVwcmVzZW50cyBhIGN1c3RvbSBwbGFjZWhvbGRlciBp
biB0aGUgcHJvbXB0IHRleHQuCgoMCgUEAAMAARIDXwoVClcKBgQAAwACABIDYQQSGkggVW5p
cXVlIElEIHVzZWQgdG8gbWFwIGN1c3RvbSBwbGFjZWhvbGRlciB0byBwYXJhbWV0ZXJzIGlu
IGZ1bGZpbGxtZW50LgoKDgoHBAADAAIABRIDYQQKCg4KBwQAAwACAAESA2ELDQoOCgcEAAMA
AgADEgNhEBEKPQoGBAADAAIBEgNkBBQaLiBDdXN0b20gcGxhY2Vob2xkZXIgdmFsdWUgaW4g
dGhlIHByb21wdCB0ZXh0LgoKDgoHBAADAAIBBRIDZAQKCg4KBwQAAwACAQESA2QLDwoOCgcE
AAMAAgEDEgNkEhMKXgoEBAADARIFaQKAAQMaTyBQYXJhbWV0ZXJzIHRvIGJlIHBhc3NlZCB0
byB0aGUgTExNLiBJZiBub3Qgc2V0LCBkZWZhdWx0IHZhbHVlcyB3aWxsIGJlCiB1c2VkLgoK
DAoFBAADAQESA2kKGArWAQoGBAADAQIAEgNuBCMaxgEgVGhlIHRlbXBlcmF0dXJlIHVzZWQg
Zm9yIHNhbXBsaW5nLiBUZW1wZXJhdHVyZSBzYW1wbGluZyBvY2N1cnMgYWZ0ZXIgYm90aAog
dG9wUCBhbmQgdG9wSyBoYXZlIGJlZW4gYXBwbGllZC4KIFZhbGlkIHJhbmdlOiBbMC4wLCAx
LjBdCiBMb3cgdGVtcGVyYXR1cmUgPSBsZXNzIHJhbmRvbS4gSGlnaCB0ZW1wZXJhdHVyZSA9
IG1vcmUgcmFuZG9tLgoKDgoHBAADAQIABBIDbgQMCg4KBwQAAwECAAUSA24NEgoOCgcEAAMB
AgABEgNuEx4KDgoHBAADAQIAAxIDbiEiCjoKBgQAAwECARIDcQQoGisgVGhlIG1heGltdW0g
bnVtYmVyIG9mIHRva2VucyB0byBnZW5lcmF0ZS4KCg4KBwQAAwECAQQSA3EEDAoOCgcEAAMB
AgEFEgNxDRIKDgoHBAADAQIBARIDcRMjCg4KBwQAAwECAQMSA3EmJwqeAgoGBAADAQICEgN5
BB0ajgIgSWYgc2V0LCBvbmx5IHRoZSB0b2tlbnMgY29tcHJpc2luZyB0aGUgdG9wIHRvcF9w
IHByb2JhYmlsaXR5IG1hc3MgYXJlCiBjb25zaWRlcmVkLiBJZiBib3RoIHRvcF9wIGFuZCB0
b3BfayBhcmUKIHNldCwgdG9wX3Agd2lsbCBiZSB1c2VkIGZvciBmdXJ0aGVyIHJlZmluaW5n
IGNhbmRpZGF0ZXMgc2VsZWN0ZWQgd2l0aAogdG9wX2suCiBWYWxpZCByYW5nZTogKDAuMCwg
MS4wXS4KIFNtYWxsIHRvcFAgPSBsZXNzIHJhbmRvbS4gTGFyZ2UgdG9wUCA9IG1vcmUgcmFu
ZG9tLgoKDgoHBAADAQICBBIDeQQMCg4KBwQAAwECAgUSA3kNEgoOCgcEAAMBAgIBEgN5ExgK
DgoHBAADAQICAxIDeRscCswBCgYEAAMBAgMSA38EHRq8ASBJZiBzZXQsIHRoZSBzYW1wbGlu
ZyBwcm9jZXNzIGluIGVhY2ggc3RlcCBpcyBsaW1pdGVkIHRvIHRoZSB0b3BfayB0b2tlbnMK
IHdpdGggaGlnaGVzdCBwcm9iYWJpbGl0aWVzLgogVmFsaWQgcmFuZ2U6IFsxLCA0MF0gb3Ig
MTAwMCsuCiBTbWFsbCB0b3BLID0gbGVzcyByYW5kb20uIExhcmdlIHRvcEsgPSBtb3JlIHJh
bmRvbS4KCg4KBwQAAwECAwQSA38EDAoOCgcEAAMBAgMFEgN/DRIKDgoHBAADAQIDARIDfxMY
Cg4KBwQAAwECAwMSA38bHArRAgoEBAACABIEiAECEhrCAiBUaGUgdW5pcXVlIGlkZW50aWZp
ZXIgb2YgdGhlIGdlbmVyYXRvci4KIE11c3QgYmUgc2V0IGZvciB0aGUKIFtHZW5lcmF0b3Jz
LlVwZGF0ZUdlbmVyYXRvcl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJh
dG9ycy5VcGRhdGVHZW5lcmF0b3JdCiBtZXRob2QuIFtHZW5lcmF0b3JzLkNyZWF0ZUdlbmVy
YXRlXVtdIHBvcHVsYXRlcyB0aGUgbmFtZSBhdXRvbWF0aWNhbGx5LgogRm9ybWF0OgogYHBy
b2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2Vu
dElEPi9nZW5lcmF0b3JzLzxHZW5lcmF0b3JJRD5gLgoKDQoFBAACAAUSBIgBAggKDQoFBAAC
AAESBIgBCQ0KDQoFBAACAAMSBIgBEBEKqQIKBAQAAgESBI4BAkMamgIgUmVxdWlyZWQuIFRo
ZSBodW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBnZW5lcmF0b3IsIHVuaXF1ZSB3aXRoaW4g
dGhlCiBhZ2VudC4gVGhlIHByb21wdCBjb250YWlucyBwcmUtZGVmaW5lZCBwYXJhbWV0ZXJz
IHN1Y2ggYXMgJGNvbnZlcnNhdGlvbiwKICRsYXN0LXVzZXItdXR0ZXJhbmNlLCBldGMuIHBv
cHVsYXRlZCBieSBEaWFsb2dmbG93LiBJdCBjYW4gYWxzbyBjb250YWluCiBjdXN0b20gcGxh
Y2Vob2xkZXJzIHdoaWNoIHdpbGwgYmUgcmVzb2x2ZWQgZHVyaW5nIGZ1bGZpbGxtZW50LgoK
DQoFBAACAQUSBI4BAggKDQoFBAACAQESBI4BCRUKDQoFBAACAQMSBI4BGBkKDQoFBAACAQgS
BI4BGkIKEAoIBAACAQicCAASBI4BG0EKMwoEBAACAhIEkQECQholIFJlcXVpcmVkLiBQcm9t
cHQgZm9yIHRoZSBMTE0gbW9kZWwuCgoNCgUEAAICBhIEkQECCAoNCgUEAAICARIEkQEJFAoN
CgUEAAICAxIEkQEXGAoNCgUEAAICCBIEkQEZQQoQCggEAAICCJwIABIEkQEaQApLCgQEAAID
EgaUAQKVAS8aOyBPcHRpb25hbC4gTGlzdCBvZiBjdXN0b20gcGxhY2Vob2xkZXJzIGluIHRo
ZSBwcm9tcHQgdGV4dC4KCg0KBQQAAgMEEgSUAQIKCg0KBQQAAgMGEgSUAQsWCg0KBQQAAgMB
EgSUARcjCg0KBQQAAgMDEgSUASYnCg0KBQQAAgMIEgSVAQYuChAKCAQAAgMInAgAEgSVAQct
CicKBAQAAgQSBJgBAioaGSBUaGUgTExNIG1vZGVsIHNldHRpbmdzLgoKDQoFBAACBAYSBJgB
AhIKDQoFBAACBAESBJgBEyUKDQoFBAACBAMSBJgBKCkKRwoEBAACBRIEmwECJRo5IFBhcmFt
ZXRlcnMgcGFzc2VkIHRvIHRoZSBMTE0gdG8gY29uZmlndXJlIGl0cyBiZWhhdmlvci4KCg0K
BQQAAgUGEgSbAQIQCg0KBQQAAgUBEgSbAREgCg0KBQQAAgUDEgSbASMkCkoKAgQBEgafAQCi
AQEaPCBUZXh0IGlucHV0IHdoaWNoIGNhbiBiZSB1c2VkIGZvciBwcm9tcHQgb3IgYmFubmVk
IHBocmFzZXMuCgoLCgMEAQESBJ8BCA4KVAoEBAECABIEoQECOxpGIFJlcXVpcmVkLiBUZXh0
IGlucHV0IHdoaWNoIGNhbiBiZSB1c2VkIGZvciBwcm9tcHQgb3IgYmFubmVkIHBocmFzZXMu
CgoNCgUEAQIABRIEoQECCAoNCgUEAQIAARIEoQEJDQoNCgUEAQIAAxIEoQEQEQoNCgUEAQIA
CBIEoQESOgoQCggEAQIACJwIABIEoQETOQp+CgIEAhIGpgEAuQEBGnAgVGhlIHJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtHZW5lcmF0b3JzLkxpc3RHZW5lcmF0b3JzXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52My5HZW5lcmF0b3JzLkxpc3RHZW5lcmF0b3JzXS4KCgsKAwQCARIE
pgEIHQqKAQoEBAICABIGqQECrgEEGnogUmVxdWlyZWQuIFRoZSBhZ2VudCB0byBsaXN0IGFs
bCBnZW5lcmF0b3JzIGZvci4KIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0
aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPmAuCgoNCgUEAgIABRIEqQECCAoN
CgUEAgIAARIEqQEJDwoNCgUEAgIAAxIEqQESEwoPCgUEAgIACBIGqQEUrgEDChAKCAQCAgAI
nAgAEgSqAQQqChEKBwQCAgAInwgSBqsBBK0BBQo0CgQEAgIBEgSxAQIbGiYgVGhlIGxhbmd1
YWdlIHRvIGxpc3QgZ2VuZXJhdG9ycyBmb3IuCgoNCgUEAgIBBRIEsQECCAoNCgUEAgIBARIE
sQEJFgoNCgUEAgIBAxIEsQEZGgppCgQEAgICEgS1AQIWGlsgVGhlIG1heGltdW0gbnVtYmVy
IG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeSBkZWZhdWx0IDEwMCBh
bmQKIGF0IG1vc3QgMTAwMC4KCg0KBQQCAgIFEgS1AQIHCg0KBQQCAgIBEgS1AQgRCg0KBQQC
AgIDEgS1ARQVClAKBAQCAgMSBLgBAhgaQiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJl
dHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QuCgoNCgUEAgIDBRIEuAECCAoN
CgUEAgIDARIEuAEJEwoNCgUEAgIDAxIEuAEWFwp/CgIEAxIGvQEAxQEBGnEgVGhlIHJlc3Bv
bnNlIG1lc3NhZ2UgZm9yCiBbR2VuZXJhdG9ycy5MaXN0R2VuZXJhdG9yc11bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdG9ycy5MaXN0R2VuZXJhdG9yc10uCgoLCgME
AwESBL0BCB4KhgEKBAQDAgASBMABAiQaeCBUaGUgbGlzdCBvZiBnZW5lcmF0b3JzLiBUaGVy
ZSB3aWxsIGJlIGEgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgcmV0dXJuZWQKIGJhc2VkIG9u
IHRoZSBwYWdlX3NpemUgZmllbGQgaW4gdGhlIHJlcXVlc3QuCgoNCgUEAwIABBIEwAECCgoN
CgUEAwIABhIEwAELFAoNCgUEAwIAARIEwAEVHwoNCgUEAwIAAxIEwAEiIwpvCgQEAwIBEgTE
AQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBl
bXB0eSBpZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQD
AgEFEgTEAQIICg0KBQQDAgEBEgTEAQkYCg0KBQQDAgEDEgTEARscCnoKAgQEEgbJAQDWAQEa
bCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0dlbmVyYXRvcnMuR2V0R2VuZXJhdG9yXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5HZW5lcmF0b3JzLkdldEdlbmVyYXRvcl0u
CgoLCgMEBAESBMkBCBsKmgEKBAQEAgASBs0BAtIBBBqJASBSZXF1aXJlZC4gVGhlIG5hbWUg
b2YgdGhlIGdlbmVyYXRvci4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZ2VuZXJhdG9ycy88R2VuZXJh
dG9ySUQ+YC4KCg0KBQQEAgAFEgTNAQIICg0KBQQEAgABEgTNAQkNCg0KBQQEAgADEgTNARAR
Cg8KBQQEAgAIEgbNARLSAQMKEAoIBAQCAAicCAASBM4BBCoKEQoHBAQCAAifCBIGzwEE0QEF
CjQKBAQEAgESBNUBAhsaJiBUaGUgbGFuZ3VhZ2UgdG8gbGlzdCBnZW5lcmF0b3JzIGZvci4K
Cg0KBQQEAgEFEgTVAQIICg0KBQQEAgEBEgTVAQkWCg0KBQQEAgEDEgTVARkaCoABCgIEBRIG
2gEA6wEBGnIgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtHZW5lcmF0b3JzLkNyZWF0ZUdl
bmVyYXRvcl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2VuZXJhdG9ycy5DcmVh
dGVHZW5lcmF0b3JdLgoKCwoDBAUBEgTaAQgeCokBCgQEBQIAEgbdAQLiAQQaeSBSZXF1aXJl
ZC4gVGhlIGFnZW50IHRvIGNyZWF0ZSBhIGdlbmVyYXRvciBmb3IuCiBGb3JtYXQ6IGBwcm9q
ZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJ
RD5gLgoKDQoFBAUCAAUSBN0BAggKDQoFBAUCAAESBN0BCQ8KDQoFBAUCAAMSBN0BEhMKDwoF
BAUCAAgSBt0BFOIBAwoQCggEBQIACJwIABIE3gEEKgoRCgcEBQIACJ8IEgbfAQThAQUKMgoE
BAUCARIE5QECQxokIFJlcXVpcmVkLiBUaGUgZ2VuZXJhdG9yIHRvIGNyZWF0ZS4KCg0KBQQF
AgEGEgTlAQILCg0KBQQFAgEBEgTlAQwVCg0KBQQFAgEDEgTlARgZCg0KBQQFAgEIEgTlARpC
ChAKCAQFAgEInAgAEgTlARtBCqYBCgQEBQICEgTqAQIbGpcBIFRoZSBsYW5ndWFnZSB0byBj
cmVhdGUgZ2VuZXJhdG9ycyBmb3IgdGhlIGZvbGxvd2luZyBmaWVsZHM6CiAqICBgR2VuZXJh
dG9yLnByb21wdF90ZXh0LnRleHRgCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgYWdlbnQncyBk
ZWZhdWx0IGxhbmd1YWdlIGlzIHVzZWQuCgoNCgUEBQICBRIE6gECCAoNCgUEBQICARIE6gEJ
FgoNCgUEBQICAxIE6gEZGgqAAQoCBAYSBu8BAPkBARpyIFRoZSByZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbR2VuZXJhdG9ycy5VcGRhdGVHZW5lcmF0b3JdW2dvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLkdlbmVyYXRvcnMuVXBkYXRlR2VuZXJhdG9yXS4KCgsKAwQGARIE7wEIHgoy
CgQEBgIAEgTxAQJDGiQgUmVxdWlyZWQuIFRoZSBnZW5lcmF0b3IgdG8gdXBkYXRlLgoKDQoF
BAYCAAYSBPEBAgsKDQoFBAYCAAESBPEBDBUKDQoFBAYCAAMSBPEBGBkKDQoFBAYCAAgSBPEB
GkIKEAoIBAYCAAicCAASBPEBG0EKNAoEBAYCARIE9AECGxomIFRoZSBsYW5ndWFnZSB0byBs
aXN0IGdlbmVyYXRvcnMgZm9yLgoKDQoFBAYCAQUSBPQBAggKDQoFBAYCAQESBPQBCRYKDQoF
BAYCAQMSBPQBGRoKdgoEBAYCAhIE+AECLBpoIFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hpY2gg
ZmllbGRzIGdldCB1cGRhdGVkLiBJZiB0aGUgbWFzayBpcyBub3QgcHJlc2VudCwKIGFsbCBm
aWVsZHMgd2lsbCBiZSB1cGRhdGVkLgoKDQoFBAYCAgYSBPgBAhsKDQoFBAYCAgESBPgBHCcK
DQoFBAYCAgMSBPgBKisKgAEKAgQHEgb9AQCRAgEaciBUaGUgcmVxdWVzdCBtZXNzYWdlIGZv
cgogW0dlbmVyYXRvcnMuRGVsZXRlR2VuZXJhdG9yXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5HZW5lcmF0b3JzLkRlbGV0ZUdlbmVyYXRvcl0uCgoLCgMEBwESBP0BCB4KpAEK
BAQHAgASBoECAoYCBBqTASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGdlbmVyYXRvciB0
byBkZWxldGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxM
b2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2dlbmVyYXRvcnMvPEdlbmVyYXRvcklEPmAu
CgoNCgUEBwIABRIEgQICCAoNCgUEBwIAARIEgQIJDQoNCgUEBwIAAxIEgQIQEQoPCgUEBwIA
CBIGgQIShgIDChAKCAQHAgAInAgAEgSCAgQqChEKBwQHAgAInwgSBoMCBIUCBQqyAwoEBAcC
ARIEkAICERqjAyBUaGlzIGZpZWxkIGhhcyBubyBlZmZlY3QgZm9yIGdlbmVyYXRvcnMgbm90
IGJlaW5nIHVzZWQuCiBGb3IgZ2VuZXJhdG9ycyB0aGF0IGFyZSB1c2VkIGJ5IHBhZ2VzL2Zs
b3dzL3RyYW5zaXRpb24gcm91dGUgZ3JvdXBzOgoKICogIElmIGBmb3JjZWAgaXMgc2V0IHRv
IGZhbHNlLCBhbiBlcnJvciB3aWxsIGJlIHJldHVybmVkIHdpdGggbWVzc2FnZQogICAgaW5k
aWNhdGluZyB0aGUgcmVmZXJlbmNlZCByZXNvdXJjZXMuCiAqICBJZiBgZm9yY2VgIGlzIHNl
dCB0byB0cnVlLCBEaWFsb2dmbG93IHdpbGwgcmVtb3ZlIHRoZSBnZW5lcmF0b3IsIGFzIHdl
bGwKICAgIGFzIGFueSByZWZlcmVuY2VzIHRvIHRoZSBnZW5lcmF0b3IgKGkuZS4KICAgIFtH
ZW5lcmF0b3JdW0Z1bGZpbGxtZW50LmdlbmVyYXRvcl0pIGluIGZ1bGZpbGxtZW50cy4KCg0K
BQQHAgEFEgSQAgIGCg0KBQQHAgEBEgSQAgcMCg0KBQQHAgEDEgSQAg8QYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::Generator ===
    # Fields for Generator
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: prompt_text Type: 11 (.google.cloud.dialogflow.cx.v3.Phrase)
    # Field: placeholders Type: 11 (.google.cloud.dialogflow.cx.v3.Generator.Placeholder)
    # Field: llm_model_settings Type: 11 (.google.cloud.dialogflow.cx.v3.LlmModelSettings)
    # Field: model_parameter Type: 11 (.google.cloud.dialogflow.cx.v3.Generator.ModelParameter)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::Phrase ===
    # Fields for Phrase
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest ===
    # Fields for ListGeneratorsRequest
    # Field: parent Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse ===
    # Fields for ListGeneratorsResponse
    # Field: generators Type: 11 (.google.cloud.dialogflow.cx.v3.Generator)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::GetGeneratorRequest ===
    # Fields for GetGeneratorRequest
    # Field: name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::CreateGeneratorRequest ===
    # Fields for CreateGeneratorRequest
    # Field: parent Type: 9 ()
    # Field: generator Type: 11 (.google.cloud.dialogflow.cx.v3.Generator)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::UpdateGeneratorRequest ===
    # Fields for UpdateGeneratorRequest
    # Field: generator Type: 11 (.google.cloud.dialogflow.cx.v3.Generator)
    # Field: language_code Type: 9 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Generator::DeleteGeneratorRequest ===
    # Fields for DeleteGeneratorRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::Generator::GeneratorsClient ===
package Google::Cloud::Dialogflow::Cx::V3::Generator::GeneratorsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::Generator::GeneratorsClient

Client stub representing the remote C<Generators> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub list_generators {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Generators',
        method         => 'ListGenerators',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse',
    });
}

sub get_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Generator::GetGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Generators',
        method         => 'GetGenerator',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator',
    });
}

sub create_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Generator::CreateGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Generators',
        method         => 'CreateGenerator',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator',
    });
}

sub update_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Generator::UpdateGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Generators',
        method         => 'UpdateGenerator',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator',
    });
}

sub delete_generator {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Generator::DeleteGeneratorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Generators',
        method         => 'DeleteGenerator',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Generator - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/generator.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Generator;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Generator::Generator->new({
        name => $name,
        display_name => $display_name,
        prompt_text => $prompt_text,
        placeholders => $placeholders,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Generator::Generator->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/generator.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::Generator

Generators contain prompt to be sent to the LLM model to generate text. The
prompt can contain parameters which will be resolved before calling the
model. It can optionally contain banned phrases to ensure the model responses
are safe.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the generator.
Must be set for the
[Generators.UpdateGenerator][google.cloud.dialogflow.cx.v3.Generators.UpdateGenerator]
method. [Generators.CreateGenerate][] populates the name automatically.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generators/<GeneratorID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the generator, unique within the
agent. The prompt contains pre-defined parameters such as $conversation,
$last-user-utterance, etc. populated by Dialogflow. It can also contain
custom placeholders which will be resolved during fulfillment.

=item * C<< $msg->prompt_text() >> / C<< $msg->prompt_text($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Generator::Phrase>)

Required. Prompt for the LLM model.

=item * C<< $msg->placeholders() >> / C<< $msg->placeholders($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::Placeholder>)

Optional. List of custom placeholders in the prompt text.

=item * C<< $msg->llm_model_settings() >> / C<< $msg->llm_model_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings>)

The LLM model settings.

=item * C<< $msg->model_parameter() >> / C<< $msg->model_parameter($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::ModelParameter>)

Parameters passed to the LLM to configure its behavior.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::Phrase

Text input which can be used for prompt or banned phrases.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. Text input which can be used for prompt or banned phrases.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest

The request message for
[Generators.ListGenerators][google.cloud.dialogflow.cx.v3.Generators.ListGenerators].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all generators for.
Format: `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list generators for.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 100 and
at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse

The response message for
[Generators.ListGenerators][google.cloud.dialogflow.cx.v3.Generators.ListGenerators].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generators() >> / C<< $msg->generators($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Generator::Generator>)

The list of generators. There will be a maximum number of items returned
based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::GetGeneratorRequest

The request message for
[Generators.GetGenerator][google.cloud.dialogflow.cx.v3.Generators.GetGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the generator.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generators/<GeneratorID>`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list generators for.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::CreateGeneratorRequest

The request message for
[Generators.CreateGenerator][google.cloud.dialogflow.cx.v3.Generators.CreateGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to create a generator for.
Format: `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`.

=item * C<< $msg->generator() >> / C<< $msg->generator($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Generator::Generator>)

Required. The generator to create.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to create generators for the following fields:
*  `Generator.prompt_text.text`
If not specified, the agent's default language is used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::UpdateGeneratorRequest

The request message for
[Generators.UpdateGenerator][google.cloud.dialogflow.cx.v3.Generators.UpdateGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generator() >> / C<< $msg->generator($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Generator::Generator>)

Required. The generator to update.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to list generators for.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The mask to control which fields get updated. If the mask is not present,
all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Generator::DeleteGeneratorRequest

The request message for
[Generators.DeleteGenerator][google.cloud.dialogflow.cx.v3.Generators.DeleteGenerator].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the generator to delete.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/generators/<GeneratorID>`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

This field has no effect for generators not being used.
For generators that are used by pages/flows/transition route groups:

*  If `force` is set to false, an error will be returned with message
   indicating the referenced resources.
*  If `force` is set to true, Dialogflow will remove the generator, as well
   as any references to the generator (i.e.
   [Generator][Fulfillment.generator]) in fulfillments.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Generator::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
