package Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine;

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
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zaXRlX3NlYXJjaF9lbmdp
bmUucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpsCChBTaXRlU2VhcmNoRW5naW5lEhIK
BG5hbWUYASABKAlSBG5hbWU68gHqQe4BCi9kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5j
b20vU2l0ZVNlYXJjaEVuZ2luZRJQcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NpdGVTZWFyY2hFbmdpbmUSaXByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVj
dGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2l0ZVNlYXJjaEVuZ2luZSL+CgoKVGFy
Z2V0U2l0ZRIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSOAoUcHJvdmlkZWRfdXJpX3BhdHRl
cm4YAiABKAlCBuBBAuBBBFIScHJvdmlkZWRVcmlQYXR0ZXJuEkgKBHR5cGUYAyABKA4yNC5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5UYXJnZXRTaXRlLlR5cGVSBHR5
cGUSJAoLZXhhY3RfbWF0Y2gYBiABKAhCA+BBBVIKZXhhY3RNYXRjaBI3ChVnZW5lcmF0ZWRf
dXJpX3BhdHRlcm4YBCABKAlCA+BBA1ITZ2VuZXJhdGVkVXJpUGF0dGVybhIrCg9yb290X2Rv
bWFpbl91cmkYCiABKAlCA+BBA1INcm9vdERvbWFpblVyaRJ0ChZzaXRlX3ZlcmlmaWNhdGlv
bl9pbmZvGAcgASgLMjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2l0
ZVZlcmlmaWNhdGlvbkluZm9CA+BBA1IUc2l0ZVZlcmlmaWNhdGlvbkluZm8SbAoPaW5kZXhp
bmdfc3RhdHVzGAggASgOMj4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
VGFyZ2V0U2l0ZS5JbmRleGluZ1N0YXR1c0ID4EEDUg5pbmRleGluZ1N0YXR1cxJACgt1cGRh
dGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRJpCg5mYWlsdXJlX3JlYXNvbhgJIAEoCzI9Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLlRhcmdldFNpdGUuRmFpbHVyZVJlYXNvbkID4EEDUg1mYWlsdXJlUmVh
c29uGs8BCg1GYWlsdXJlUmVhc29uEnEKDXF1b3RhX2ZhaWx1cmUYASABKAsySi5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5UYXJnZXRTaXRlLkZhaWx1cmVSZWFzb24u
UXVvdGFGYWlsdXJlSABSDHF1b3RhRmFpbHVyZRpACgxRdW90YUZhaWx1cmUSMAoUdG90YWxf
cmVxdWlyZWRfcXVvdGEYASABKANSEnRvdGFsUmVxdWlyZWRRdW90YUIJCgdmYWlsdXJlIjYK
BFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEgsKB0lOQ0xVREUQARILCgdFWENMVURFEAIi
hwEKDkluZGV4aW5nU3RhdHVzEh8KG0lOREVYSU5HX1NUQVRVU19VTlNQRUNJRklFRBAAEgsK
B1BFTkRJTkcQARIKCgZGQUlMRUQQAhINCglTVUNDRUVERUQQAxIMCghERUxFVElORxAEEg8K
C0NBTkNFTExBQkxFEAUSDQoJQ0FOQ0VMTEVEEAY6oQLqQZ0CCilkaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb20vVGFyZ2V0U2l0ZRJqcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NpdGVTZWFyY2hFbmdpbmUv
dGFyZ2V0U2l0ZXMve3RhcmdldF9zaXRlfRKDAXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0
YV9zdG9yZX0vc2l0ZVNlYXJjaEVuZ2luZS90YXJnZXRTaXRlcy97dGFyZ2V0X3NpdGV9IssC
ChRTaXRlVmVyaWZpY2F0aW9uSW5mbxKHAQoXc2l0ZV92ZXJpZmljYXRpb25fc3RhdGUYASAB
KA4yTy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TaXRlVmVyaWZpY2F0
aW9uSW5mby5TaXRlVmVyaWZpY2F0aW9uU3RhdGVSFXNpdGVWZXJpZmljYXRpb25TdGF0ZRI7
Cgt2ZXJpZnlfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnZlcmlm
eVRpbWUibAoVU2l0ZVZlcmlmaWNhdGlvblN0YXRlEicKI1NJVEVfVkVSSUZJQ0FUSU9OX1NU
QVRFX1VOU1BFQ0lGSUVEEAASDAoIVkVSSUZJRUQQARIOCgpVTlZFUklGSUVEEAISDAoIRVhF
TVBURUQQAyKSAwoHU2l0ZW1hcBISCgN1cmkYAiABKAlIAFIDdXJpEhcKBG5hbWUYASABKAlC
A+BBA1IEbmFtZRJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKY3JlYXRlVGltZTqPAupBiwIKJmRpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9TaXRlbWFwEmNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2l0ZVNlYXJjaEVuZ2luZS9zaXRlbWFwcy97
c2l0ZW1hcH0SfHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xs
ZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2l0ZVNlYXJj
aEVuZ2luZS9zaXRlbWFwcy97c2l0ZW1hcH1CBgoEZmVlZEKcAgonY29tLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhVTaXRlU2VhcmNoRW5naW5lUHJvdG9QAVpRY2xv
dWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVu
Z2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNs
b3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5n
aW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSsUz
CgcSBQ4AygEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAs
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAQAoJCgIIJRIDFgBA
CggKAQgSAxcAaAoJCgIICxIDFwBoCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkANgoJ
CgIICBIDGQA2CggKAQgSAxoAQAoJCgIIARIDGgBACggKAQgSAxsALQoJCgIIJBIDGwAtCggK
AQgSAxwAQAoJCgIIKRIDHABACggKAQgSAx0APwoJCgIILRIDHQA/CocBCgIEABIEIQArARp7
IFNpdGVTZWFyY2hFbmdpbmUgY2FwdHVyZXMgRGF0YVN0b3JlIGxldmVsIHNpdGUgc2VhcmNo
IHBlcnNpc3RpbmcKIGNvbmZpZ3VyYXRpb25zLiBJdCBpcyBhIHNpbmdsZXRvbiB2YWx1ZSBw
ZXIgZGF0YSBzdG9yZS4KCgoKAwQAARIDIQgYCgsKAwQABxIEIgImBAoNCgUEAAedCBIEIgIm
BAqLAQoEBAACABIDKgISGn4gVGhlIGZ1bGx5IHF1YWxpZmllZCByZXNvdXJjZSBuYW1lIG9m
IHRoZSBzaXRlIHNlYXJjaCBlbmdpbmUuCiBGb3JtYXQ6IGBwcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2RhdGFTdG9yZXMvKi9zaXRlU2VhcmNoRW5naW5lYAoKDAoFBAACAAUSAyoCCAoMCgUE
AAIAARIDKgkNCgwKBQQAAgADEgMqEBEKNgoCBAESBS4AmgEBGikgQSB0YXJnZXQgc2l0ZSBm
b3IgdGhlIFNpdGVTZWFyY2hFbmdpbmUuCgoKCgMEAQESAy4IEgoLCgMEAQcSBC8CMwQKDQoF
BAEHnQgSBC8CMwQKNQoEBAEDABIENgJDAxonIFNpdGUgc2VhcmNoIGluZGV4aW5nIGZhaWx1
cmUgcmVhc29ucy4KCgwKBQQBAwABEgM2ChcKMwoGBAEDAAMAEgQ4BDwFGiMgRmFpbGVkIGR1
ZSB0byBpbnN1ZmZpY2llbnQgcXVvdGEuCgoOCgcEAQMAAwABEgM4DBgKfgoIBAEDAAMAAgAS
AzsGJRptIFRoaXMgbnVtYmVyIGlzIGFuIGVzdGltYXRpb24gb24gaG93IG11Y2ggdG90YWwg
cXVvdGEgdGhpcyBwcm9qZWN0IG5lZWRzCiB0byBzdWNjZXNzZnVsbHkgY29tcGxldGUgaW5k
ZXhpbmcuCgoQCgkEAQMAAwACAAUSAzsGCwoQCgkEAQMAAwACAAESAzsMIAoQCgkEAQMAAwAC
AAMSAzsjJAohCgYEAQMACAASBD8EQgUaESBGYWlsdXJlIHJlYXNvbi4KCg4KBwQBAwAIAAES
Az8KEQoyCgYEAQMAAgASA0EGJRojIEZhaWxlZCBkdWUgdG8gaW5zdWZmaWNpZW50IHF1b3Rh
LgoKDgoHBAEDAAIABhIDQQYSCg4KBwQBAwACAAESA0ETIAoOCgcEAQMAAgADEgNBIyQKKwoE
BAEEABIERgJQAxodIFBvc3NpYmxlIHRhcmdldCBzaXRlIHR5cGVzLgoKDAoFBAEEAAESA0YH
CwqfAQoGBAEEAAIAEgNJBBkajwEgVGhpcyB2YWx1ZSBpcyB1bnVzZWQuIEluIHRoaXMgY2Fz
ZSwgc2VydmVyIGJlaGF2aW9yIGRlZmF1bHRzIHRvCiBbVHlwZS5JTkNMVURFXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5UYXJnZXRTaXRlLlR5cGUuSU5DTFVERV0u
CgoOCgcEAQQAAgABEgNJBBQKDgoHBAEEAAIAAhIDSRcYCikKBgQBBAACARIDTAQQGhogSW5j
bHVkZSB0aGUgdGFyZ2V0IHNpdGUuCgoOCgcEAQQAAgEBEgNMBAsKDgoHBAEEAAIBAhIDTA4P
CikKBgQBBAACAhIDTwQQGhogRXhjbHVkZSB0aGUgdGFyZ2V0IHNpdGUuCgoOCgcEAQQAAgIB
EgNPBAsKDgoHBAEEAAICAhIDTw4PCjgKBAQBBAESBFMCbAMaKiBUYXJnZXQgc2l0ZSBpbmRl
eGluZyBzdGF0dXMgZW51bWVyYXRpb24uCgoMCgUEAQQBARIDUwcVCicKBgQBBAECABIDVQQk
GhggRGVmYXVsdHMgdG8gU1VDQ0VFREVELgoKDgoHBAEEAQIAARIDVQQfCg4KBwQBBAECAAIS
A1UiIwpkCgYEAQQBAgESA1kEEBpVIFRoZSB0YXJnZXQgc2l0ZSBpcyBpbiB0aGUgdXBkYXRl
IHF1ZXVlIGFuZCB3aWxsIGJlIHBpY2tlZCB1cCBieSBpbmRleGluZwogcGlwZWxpbmUuCgoO
CgcEAQQBAgEBEgNZBAsKDgoHBAEEAQIBAhIDWQ4PCjUKBgQBBAECAhIDXAQPGiYgVGhlIHRh
cmdldCBzaXRlIGZhaWxzIHRvIGJlIGluZGV4ZWQuCgoOCgcEAQQBAgIBEgNcBAoKDgoHBAEE
AQICAhIDXA0OCjIKBgQBBAECAxIDXwQSGiMgVGhlIHRhcmdldCBzaXRlIGhhcyBiZWVuIGlu
ZGV4ZWQuCgoOCgcEAQQBAgMBEgNfBA0KDgoHBAEEAQIDAhIDXxARCv4BCgYEAQQBAgQSA2UE
ERruASBUaGUgcHJldmlvdXNseSBpbmRleGVkIHRhcmdldCBzaXRlIGhhcyBiZWVuIG1hcmtl
ZCB0byBiZSBkZWxldGVkLiBUaGlzIGlzCiBhIHRyYW5zaXRpb25pbmcgc3RhdGUgd2hpY2gg
d2lsbCByZXN1bHRlZCBpbiBlaXRoZXI6CiAxLiB0YXJnZXQgc2l0ZSBkZWxldGVkIGlmIHVu
aW5kZXhpbmcgaXMgc3VjY2Vzc2Z1bDsKIDIuIHN0YXRlIHJldmVydHMgdG8gU1VDQ0VFREVE
IGlmIHRoZSB1bmluZGV4aW5nIGZhaWxzLgoKDgoHBAEEAQIEARIDZQQMCg4KBwQBBAECBAIS
A2UPEApDCgYEAQQBAgUSA2gEFBo0IFRoZSB0YXJnZXQgc2l0ZSBjaGFuZ2UgaXMgcGVuZGlu
ZyBidXQgY2FuY2VsbGFibGUuCgoOCgcEAQQBAgUBEgNoBA8KDgoHBAEEAQIFAhIDaBITCjUK
BgQBBAECBhIDawQSGiYgVGhlIHRhcmdldCBzaXRlIGNoYW5nZSBpcyBjYW5jZWxsZWQuCgoO
CgcEAQQBAgYBEgNrBA0KDgoHBAEEAQIGAhIDaxARCoQCCgQEAQIAEgNxAj4a9gEgT3V0cHV0
IG9ubHkuIFRoZSBmdWxseSBxdWFsaWZpZWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgdGFyZ2V0
IHNpdGUuCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxl
Y3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zaXRlU2VhcmNo
RW5naW5lL3RhcmdldFNpdGVzL3t0YXJnZXRfc2l0ZX1gCiBUaGUgYHRhcmdldF9zaXRlX2lk
YCBpcyBzeXN0ZW0tZ2VuZXJhdGVkLgoKDAoFBAECAAUSA3ECCAoMCgUEAQIAARIDcQkNCgwK
BQQBAgADEgNxEBEKDAoFBAECAAgSA3ESPQoPCggEAQIACJwIABIDcRM8CnkKBAQBAgESBHUC
eAQaayBSZXF1aXJlZC4gSW5wdXQgb25seS4gVGhlIHVzZXIgcHJvdmlkZWQgVVJJIHBhdHRl
cm4gZnJvbSB3aGljaCB0aGUKIGBnZW5lcmF0ZWRfdXJpX3BhdHRlcm5gIGlzIGdlbmVyYXRl
ZC4KCgwKBQQBAgEFEgN1AggKDAoFBAECAQESA3UJHQoMCgUEAQIBAxIDdSAhCg0KBQQBAgEI
EgR1IngDCg8KCAQBAgEInAgAEgN2BCoKDwoIBAECAQicCAESA3cELApiCgQEAQICEgN8AhAa
VSBUaGUgdHlwZSBvZiB0aGUgdGFyZ2V0IHNpdGUsIGUuZy4sIHdoZXRoZXIgdGhlIHNpdGUg
aXMgdG8gYmUgaW5jbHVkZWQgb3IKIGV4Y2x1ZGVkLgoKDAoFBAECAgYSA3wCBgoMCgUEAQIC
ARIDfAcLCgwKBQQBAgIDEgN8Dg8KpgMKBAQBAgMSBIQBAkEalwMgSW1tdXRhYmxlLiBJZiBz
ZXQgdG8gZmFsc2UsIGEgdXJpX3BhdHRlcm4gaXMgZ2VuZXJhdGVkIHRvIGluY2x1ZGUgYWxs
IHBhZ2VzCiB3aG9zZSBhZGRyZXNzIGNvbnRhaW5zIHRoZSBwcm92aWRlZF91cmlfcGF0dGVy
bi4gSWYgc2V0IHRvIHRydWUsIGFuCiB1cmlfcGF0dGVybiBpcyBnZW5lcmF0ZWQgdG8gdHJ5
IHRvIGJlIGFuIGV4YWN0IG1hdGNoIG9mIHRoZQogcHJvdmlkZWRfdXJpX3BhdHRlcm4gb3Ig
anVzdCB0aGUgc3BlY2lmaWMgcGFnZSBpZiB0aGUgcHJvdmlkZWRfdXJpX3BhdHRlcm4KIGlz
IGEgc3BlY2lmaWMgb25lLiBwcm92aWRlZF91cmlfcGF0dGVybiBpcyBhbHdheXMgbm9ybWFs
aXplZCB0bwogZ2VuZXJhdGUgdGhlIFVSSSBwYXR0ZXJuIHRvIGJlIHVzZWQgYnkgdGhlIHNl
YXJjaCBlbmdpbmUuCgoNCgUEAQIDBRIEhAECBgoNCgUEAQIDARIEhAEHEgoNCgUEAQIDAxIE
hAEVFgoNCgUEAQIDCBIEhAEXQAoQCggEAQIDCJwIABIEhAEYPwpYCgQEAQIEEgSHAQJPGkog
T3V0cHV0IG9ubHkuIFRoaXMgaXMgc3lzdGVtLWdlbmVyYXRlZCBiYXNlZCBvbiB0aGUgcHJv
dmlkZWRfdXJpX3BhdHRlcm4uCgoNCgUEAQIEBRIEhwECCAoNCgUEAQIEARIEhwEJHgoNCgUE
AQIEAxIEhwEhIgoNCgUEAQIECBIEhwEjTgoQCggEAQIECJwIABIEhwEkTQpFCgQEAQIFEgSK
AQJKGjcgT3V0cHV0IG9ubHkuIFJvb3QgZG9tYWluIG9mIHRoZSBwcm92aWRlZF91cmlfcGF0
dGVybi4KCg0KBQQBAgUFEgSKAQIICg0KBQQBAgUBEgSKAQkYCg0KBQQBAgUDEgSKARsdCg0K
BQQBAgUIEgSKAR5JChAKCAQBAgUInAgAEgSKAR9ICk8KBAQBAgYSBo0BAo4BMho/IE91dHB1
dCBvbmx5LiBTaXRlIG93bmVyc2hpcCBhbmQgdmFsaWRpdHkgdmVyaWZpY2F0aW9uIHN0YXR1
cy4KCg0KBQQBAgYGEgSNAQIWCg0KBQQBAgYBEgSNARctCg0KBQQBAgYDEgSNATAxCg0KBQQB
AgYIEgSOAQYxChAKCAQBAgYInAgAEgSOAQcwCi8KBAQBAgcSBpEBApIBMhofIE91dHB1dCBv
bmx5LiBJbmRleGluZyBzdGF0dXMuCgoNCgUEAQIHBhIEkQECEAoNCgUEAQIHARIEkQERIAoN
CgUEAQIHAxIEkQEjJAoNCgUEAQIHCBIEkgEGMQoQCggEAQIHCJwIABIEkgEHMApDCgQEAQII
EgaVAQKWATIaMyBPdXRwdXQgb25seS4gVGhlIHRhcmdldCBzaXRlJ3MgbGFzdCB1cGRhdGVk
IHRpbWUuCgoNCgUEAQIIBhIElQECGwoNCgUEAQIIARIElQEcJwoNCgUEAQIIAxIElQEqKwoN
CgUEAQIICBIElgEGMQoQCggEAQIICJwIABIElgEHMAosCgQEAQIJEgSZAQJPGh4gT3V0cHV0
IG9ubHkuIEZhaWx1cmUgcmVhc29uLgoKDQoFBAECCQYSBJkBAg8KDQoFBAECCQESBJkBEB4K
DQoFBAECCQMSBJkBISIKDQoFBAECCQgSBJkBI04KEAoIBAECCQicCAASBJkBJE0KUgoCBAIS
Bp0BALIBARpEIFZlcmlmaWNhdGlvbiBpbmZvcm1hdGlvbiBmb3IgdGFyZ2V0IHNpdGVzIGlu
IGFkdmFuY2VkIHNpdGUgc2VhcmNoLgoKCwoDBAIBEgSdAQgcCioKBAQCBAASBp8BAqsBAxoa
IFNpdGUgdmVyaWZpY2F0aW9uIHN0YXRlLgoKDQoFBAIEAAESBJ8BBxwKJwoGBAIEAAIAEgSh
AQQsGhcgRGVmYXVsdHMgdG8gVkVSSUZJRUQuCgoPCgcEAgQAAgABEgShAQQnCg8KBwQCBAAC
AAISBKEBKisKKgoGBAIEAAIBEgSkAQQRGhogU2l0ZSBvd25lcnNoaXAgdmVyaWZpZWQuCgoP
CgcEAgQAAgEBEgSkAQQMCg8KBwQCBAACAQISBKQBDxAKTQoGBAIEAAICEgSnAQQTGj0gU2l0
ZSBvd25lcnNoaXAgcGVuZGluZyB2ZXJpZmljYXRpb24gb3IgdmVyaWZpY2F0aW9uIGZhaWxl
ZC4KCg8KBwQCBAACAgESBKcBBA4KDwoHBAIEAAICAhIEpwEREgpaCgYEAgQAAgMSBKoBBBEa
SiBTaXRlIGV4ZW1wdCBmcm9tIHZlcmlmaWNhdGlvbiwgZS5nLiwgYSBwdWJsaWMgd2Vic2l0
ZSB0aGF0IG9wZW5zIHRvIGFsbC4KCg8KBwQCBAACAwESBKoBBAwKDwoHBAIEAAIDAhIEqgEP
EApOCgQEAgIAEgSuAQI0GkAgU2l0ZSB2ZXJpZmljYXRpb24gc3RhdGUgaW5kaWNhdGluZyB0
aGUgb3duZXJzaGlwIGFuZCB2YWxpZGl0eS4KCg0KBQQCAgAGEgSuAQIXCg0KBQQCAgABEgSu
ARgvCg0KBQQCAgADEgSuATIzCi4KBAQCAgESBLEBAiwaICBMYXRlc3Qgc2l0ZSB2ZXJpZmlj
YXRpb24gdGltZS4KCg0KBQQCAgEGEgSxAQIbCg0KBQQCAgEBEgSxARwnCg0KBQQCAgEDEgSx
ASorCjMKAgQDEga1AQDKAQEaJSBBIHNpdGVtYXAgZm9yIHRoZSBTaXRlU2VhcmNoRW5naW5l
LgoKCwoDBAMBEgS1AQgPCg0KAwQDBxIGtgECugEECg8KBQQDB50IEga2AQK6AQQKKQoEBAMI
ABIGvQECwAEDGhkgU3VwcG9ydGVkIGZlZWQgc291cmNlcy4KCg0KBQQDCAABEgS9AQgMCk8K
BAQDAgASBL8BBBMaQSBQdWJsaWMgVVJJIGZvciB0aGUgc2l0ZW1hcCwgZS5nLiBgd3d3LmV4
YW1wbGUuY29tL3NpdGVtYXAueG1sYC4KCg0KBQQDAgAFEgS/AQQKCg0KBQQDAgABEgS/AQsO
Cg0KBQQDAgADEgS/ARESCs4BCgQEAwIBEgTFAQI+Gr8BIE91dHB1dCBvbmx5LiBUaGUgZnVs
bHkgcXVhbGlmaWVkIHJlc291cmNlIG5hbWUgb2YgdGhlIHNpdGVtYXAuCiBgcHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9zaXRlU2VhcmNoRW5n
aW5lL3NpdGVtYXBzLypgCiBUaGUgYHNpdGVtYXBfaWRgIHN1ZmZpeCBpcyBzeXN0ZW0tZ2Vu
ZXJhdGVkLgoKDQoFBAMCAQUSBMUBAggKDQoFBAMCAQESBMUBCQ0KDQoFBAMCAQMSBMUBEBEK
DQoFBAMCAQgSBMUBEj0KEAoIBAMCAQicCAASBMUBEzwKOwoEBAMCAhIGyAECyQEyGisgT3V0
cHV0IG9ubHkuIFRoZSBzaXRlbWFwJ3MgY3JlYXRpb24gdGltZS4KCg0KBQQDAgIGEgTIAQIb
Cg0KBQQDAgIBEgTIARwnCg0KBQQDAgIDEgTIASorCg0KBQQDAgIIEgTJAQYxChAKCAQDAgII
nAgAEgTJAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine ===
    # Fields for SiteSearchEngine
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite ===
    # Fields for TargetSite
    # Field: name Type: 9 ()
    # Field: provided_uri_pattern Type: 9 ()
    # Field: type Type: 14 (.google.cloud.discoveryengine.v1beta.TargetSite.Type)
    # Field: exact_match Type: 8 ()
    # Field: generated_uri_pattern Type: 9 ()
    # Field: root_domain_uri Type: 9 ()
    # Field: site_verification_info Type: 11 (.google.cloud.discoveryengine.v1beta.SiteVerificationInfo)
    # Field: indexing_status Type: 14 (.google.cloud.discoveryengine.v1beta.TargetSite.IndexingStatus)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: failure_reason Type: 11 (.google.cloud.discoveryengine.v1beta.TargetSite.FailureReason)

# Enum: TargetSite::Type
our $TargetSite_TYPE_UNSPECIFIED = 0;
our $TargetSite_INCLUDE = 1;
our $TargetSite_EXCLUDE = 2;

# Enum: TargetSite::IndexingStatus
our $TargetSite_INDEXING_STATUS_UNSPECIFIED = 0;
our $TargetSite_PENDING = 1;
our $TargetSite_FAILED = 2;
our $TargetSite_SUCCEEDED = 3;
our $TargetSite_DELETING = 4;
our $TargetSite_CANCELLABLE = 5;
our $TargetSite_CANCELLED = 6;

# === Message: Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteVerificationInfo ===
    # Fields for SiteVerificationInfo
    # Field: site_verification_state Type: 14 (.google.cloud.discoveryengine.v1beta.SiteVerificationInfo.SiteVerificationState)
    # Field: verify_time Type: 11 (.google.protobuf.Timestamp)

# Enum: SiteVerificationInfo::SiteVerificationState
our $SiteVerificationInfo_SITE_VERIFICATION_STATE_UNSPECIFIED = 0;
our $SiteVerificationInfo_VERIFIED = 1;
our $SiteVerificationInfo_UNVERIFIED = 2;
our $SiteVerificationInfo_EXEMPTED = 3;

# === Message: Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Sitemap ===
    # Fields for Sitemap
    # Field: uri Type: 9 ()
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/site_search_engine.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/site_search_engine.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine

SiteSearchEngine captures DataStore level site search persisting
configurations. It is a singleton value per data store.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fully qualified resource name of the site search engine.
Format: `projects/*/locations/*/dataStores/*/siteSearchEngine`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite

A target site for the SiteSearchEngine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The fully qualified resource name of the target site.
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/siteSearchEngine/targetSites/{target_site}`
The `target_site_id` is system-generated.

=item * C<< $msg->provided_uri_pattern() >> / C<< $msg->provided_uri_pattern($value) >>

Type: C<String>

Required. Input only. The user provided URI pattern from which the
`generated_uri_pattern` is generated.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::TargetSite::Type>)

The type of the target site, e.g., whether the site is to be included or
excluded.

=item * C<< $msg->exact_match() >> / C<< $msg->exact_match($value) >>

Type: C<Bool>

Immutable. If set to false, a uri_pattern is generated to include all pages
whose address contains the provided_uri_pattern. If set to true, an
uri_pattern is generated to try to be an exact match of the
provided_uri_pattern or just the specific page if the provided_uri_pattern
is a specific one. provided_uri_pattern is always normalized to
generate the URI pattern to be used by the search engine.

=item * C<< $msg->generated_uri_pattern() >> / C<< $msg->generated_uri_pattern($value) >>

Type: C<String>

Output only. This is system-generated based on the provided_uri_pattern.

=item * C<< $msg->root_domain_uri() >> / C<< $msg->root_domain_uri($value) >>

Type: C<String>

Output only. Root domain of the provided_uri_pattern.

=item * C<< $msg->site_verification_info() >> / C<< $msg->site_verification_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteVerificationInfo>)

Output only. Site ownership and validity verification status.

=item * C<< $msg->indexing_status() >> / C<< $msg->indexing_status($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::TargetSite::IndexingStatus>)

Output only. Indexing status.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The target site's last updated time.

=item * C<< $msg->failure_reason() >> / C<< $msg->failure_reason($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason>)

Output only. Failure reason.

=back

=head3 Enum: TargetSite::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<INCLUDE> => C<1>

=item * C<EXCLUDE> => C<2>

=back

=head3 Enum: TargetSite::IndexingStatus

=over 4

=item * C<INDEXING_STATUS_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<FAILED> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<DELETING> => C<4>

=item * C<CANCELLABLE> => C<5>

=item * C<CANCELLED> => C<6>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteVerificationInfo

Verification information for target sites in advanced site search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->site_verification_state() >> / C<< $msg->site_verification_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::SiteVerificationInfo::SiteVerificationState>)

Site verification state indicating the ownership and validity.

=item * C<< $msg->verify_time() >> / C<< $msg->verify_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Latest site verification time.

=back

=head3 Enum: SiteVerificationInfo::SiteVerificationState

=over 4

=item * C<SITE_VERIFICATION_STATE_UNSPECIFIED> => C<0>

=item * C<VERIFIED> => C<1>

=item * C<UNVERIFIED> => C<2>

=item * C<EXEMPTED> => C<3>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Sitemap

A sitemap for the SiteSearchEngine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Public URI for the sitemap, e.g. `www.example.com/sitemap.xml`.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The fully qualified resource name of the sitemap.
`projects/*/locations/*/collections/*/dataStores/*/siteSearchEngine/sitemaps/*`
The `sitemap_id` suffix is system-generated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The sitemap's creation time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
