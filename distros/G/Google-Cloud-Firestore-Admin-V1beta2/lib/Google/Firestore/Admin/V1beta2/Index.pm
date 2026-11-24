package Google::Firestore::Admin::V1beta2::Index;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTIvaW5kZXgucHJvdG8SHmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90byKA
BgoFSW5kZXgSEgoEbmFtZRgBIAEoCVIEbmFtZRJRCgtxdWVyeV9zY29wZRgCIAEoDjIwLmdv
b2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5JbmRleC5RdWVyeVNjb3BlUgpxdWVyeVNj
b3BlEkgKBmZpZWxkcxgDIAMoCzIwLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5J
bmRleC5JbmRleEZpZWxkUgZmaWVsZHMSQQoFc3RhdGUYBCABKA4yKy5nb29nbGUuZmlyZXN0
b3JlLmFkbWluLnYxYmV0YTIuSW5kZXguU3RhdGVSBXN0YXRlGuYCCgpJbmRleEZpZWxkEh0K
CmZpZWxkX3BhdGgYASABKAlSCWZpZWxkUGF0aBJOCgVvcmRlchgCIAEoDjI2Lmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMi5JbmRleC5JbmRleEZpZWxkLk9yZGVySABSBW9yZGVy
EmEKDGFycmF5X2NvbmZpZxgDIAEoDjI8Lmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRh
Mi5JbmRleC5JbmRleEZpZWxkLkFycmF5Q29uZmlnSABSC2FycmF5Q29uZmlnIj0KBU9yZGVy
EhUKEU9SREVSX1VOU1BFQ0lGSUVEEAASDQoJQVNDRU5ESU5HEAESDgoKREVTQ0VORElORxAC
IjkKC0FycmF5Q29uZmlnEhwKGEFSUkFZX0NPTkZJR19VTlNQRUNJRklFRBAAEgwKCENPTlRB
SU5TEAFCDAoKdmFsdWVfbW9kZSJPCgpRdWVyeVNjb3BlEhsKF1FVRVJZX1NDT1BFX1VOU1BF
Q0lGSUVEEAASDgoKQ09MTEVDVElPThABEhQKEENPTExFQ1RJT05fR1JPVVAQAiJJCgVTdGF0
ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCQoFUkVBRFkQAhIQCgxO
RUVEU19SRVBBSVIQA0KgAQoiY29tLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMkIK
SW5kZXhQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2ZpcmVzdG9yZS9hZG1pbi9hcGl2
MWJldGEyL2FkbWlucGI7YWRtaW5wYqICBEdDRlOqAiRHb29nbGUuQ2xvdWQuRmlyZXN0b3Jl
LkFkbWluLlYxQmV0YTJK1ywKBxIFDwCVAQEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoKCAoBAhIDEQAnCgkKAgMAEgMTACYKCAoBCBIDFQBBCgkKAgglEgMVAEEKCAoB
CBIDFgBVCgkKAggLEgMWAFUKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAArCgkKAggI
EgMYACsKCAoBCBIDGQA7CgkKAggBEgMZADsKCAoBCBIDGgAiCgkKAggkEgMaACIKagoCBAAS
BR4AlQEBGl0gQ2xvdWQgRmlyZXN0b3JlIGluZGV4ZXMgZW5hYmxlIHNpbXBsZSBhbmQgY29t
cGxleCBxdWVyaWVzIGFnYWluc3QKIGRvY3VtZW50cyBpbiBhIGRhdGFiYXNlLgoKCgoDBAAB
EgMeCA0KkQEKBAQAAwASBCICRgMaggEgQSBmaWVsZCBpbiBhbiBpbmRleC4KIFRoZSBmaWVs
ZF9wYXRoIGRlc2NyaWJlcyB3aGljaCBmaWVsZCBpcyBpbmRleGVkLCB0aGUgdmFsdWVfbW9k
ZSBkZXNjcmliZXMKIGhvdyB0aGUgZmllbGQgdmFsdWUgaXMgaW5kZXhlZC4KCgwKBQQAAwAB
EgMiChQKKgoGBAADAAQAEgQkBC0FGhogVGhlIHN1cHBvcnRlZCBvcmRlcmluZ3MuCgoOCgcE
AAMABAABEgMkCQ4KQwoIBAADAAQAAgASAyYGHBoyIFRoZSBvcmRlcmluZyBpcyB1bnNwZWNp
ZmllZC4gTm90IGEgdmFsaWQgb3B0aW9uLgoKEAoJBAADAAQAAgABEgMmBhcKEAoJBAADAAQA
AgACEgMmGhsKQQoIBAADAAQAAgESAykGFBowIFRoZSBmaWVsZCBpcyBvcmRlcmVkIGJ5IGFz
Y2VuZGluZyBmaWVsZCB2YWx1ZS4KChAKCQQAAwAEAAIBARIDKQYPChAKCQQAAwAEAAIBAhID
KRITCkIKCAQAAwAEAAICEgMsBhUaMSBUaGUgZmllbGQgaXMgb3JkZXJlZCBieSBkZXNjZW5k
aW5nIGZpZWxkIHZhbHVlLgoKEAoJBAADAAQAAgIBEgMsBhAKEAoJBAADAAQAAgICEgMsExQK
OwoGBAADAAQBEgQwBDYFGisgVGhlIHN1cHBvcnRlZCBhcnJheSB2YWx1ZSBjb25maWd1cmF0
aW9ucy4KCg4KBwQAAwAEAQESAzAJFApHCggEAAMABAECABIDMgYjGjYgVGhlIGluZGV4IGRv
ZXMgbm90IHN1cHBvcnQgYWRkaXRpb25hbCBhcnJheSBxdWVyaWVzLgoKEAoJBAADAAQBAgAB
EgMyBh4KEAoJBAADAAQBAgACEgMyISIKQAoIBAADAAQBAgESAzUGExovIFRoZSBpbmRleCBz
dXBwb3J0cyBhcnJheSBjb250YWlubWVudCBxdWVyaWVzLgoKEAoJBAADAAQBAgEBEgM1Bg4K
EAoJBAADAAQBAgECEgM1ERIKdgoGBAADAAIAEgM7BBoaZyBDYW4gYmUgX19uYW1lX18uCiBG
b3Igc2luZ2xlIGZpZWxkIGluZGV4ZXMsIHRoaXMgbXVzdCBtYXRjaCB0aGUgbmFtZSBvZiB0
aGUgZmllbGQgb3IgbWF5CiBiZSBvbWl0dGVkLgoKDgoHBAADAAIABRIDOwQKCg4KBwQAAwAC
AAESAzsLFQoOCgcEAAMAAgADEgM7GBkKMQoGBAADAAgAEgQ+BEUFGiEgSG93IHRoZSBmaWVs
ZCB2YWx1ZSBpcyBpbmRleGVkLgoKDgoHBAADAAgAARIDPgoUCngKBgQAAwACARIDQQYWGmkg
SW5kaWNhdGVzIHRoYXQgdGhpcyBmaWVsZCBzdXBwb3J0cyBvcmRlcmluZyBieSB0aGUgc3Bl
Y2lmaWVkIG9yZGVyIG9yCiBjb21wYXJpbmcgdXNpbmcgPSwgPCwgPD0sID4sID49LgoKDgoH
BAADAAIBBhIDQQYLCg4KBwQAAwACAQESA0EMEQoOCgcEAAMAAgEDEgNBFBUKUQoGBAADAAIC
EgNEBiMaQiBJbmRpY2F0ZXMgdGhhdCB0aGlzIGZpZWxkIHN1cHBvcnRzIG9wZXJhdGlvbnMg
b24gYGFycmF5X3ZhbHVlYHMuCgoOCgcEAAMAAgIGEgNEBhEKDgoHBAADAAICARIDRBIeCg4K
BwQAAwACAgMSA0QhIgp+CgQEAAQAEgRKAlcDGnAgUXVlcnkgU2NvcGUgZGVmaW5lcyB0aGUg
c2NvcGUgYXQgd2hpY2ggYSBxdWVyeSBpcyBydW4uIFRoaXMgaXMgc3BlY2lmaWVkIG9uCiBh
IFN0cnVjdHVyZWRRdWVyeSdzIGBmcm9tYCBmaWVsZC4KCgwKBQQABAABEgNKBxEKRAoGBAAE
AAIAEgNMBCAaNSBUaGUgcXVlcnkgc2NvcGUgaXMgdW5zcGVjaWZpZWQuIE5vdCBhIHZhbGlk
IG9wdGlvbi4KCg4KBwQABAACAAESA0wEGwoOCgcEAAQAAgACEgNMHh8K4AEKBgQABAACARID
UQQTGtABIEluZGV4ZXMgd2l0aCBhIGNvbGxlY3Rpb24gcXVlcnkgc2NvcGUgc3BlY2lmaWVk
IGFsbG93IHF1ZXJpZXMKIGFnYWluc3QgYSBjb2xsZWN0aW9uIHRoYXQgaXMgdGhlIGNoaWxk
IG9mIGEgc3BlY2lmaWMgZG9jdW1lbnQsIHNwZWNpZmllZAogYXQgcXVlcnkgdGltZSwgYW5k
IHRoYXQgaGFzIHRoZSBjb2xsZWN0aW9uIGlkIHNwZWNpZmllZCBieSB0aGUgaW5kZXguCgoO
CgcEAAQAAgEBEgNRBA4KDgoHBAAEAAIBAhIDURESCqIBCgYEAAQAAgISA1YEGRqSASBJbmRl
eGVzIHdpdGggYSBjb2xsZWN0aW9uIGdyb3VwIHF1ZXJ5IHNjb3BlIHNwZWNpZmllZCBhbGxv
dyBxdWVyaWVzCiBhZ2FpbnN0IGFsbCBjb2xsZWN0aW9ucyB0aGF0IGhhcyB0aGUgY29sbGVj
dGlvbiBpZCBzcGVjaWZpZWQgYnkgdGhlCiBpbmRleC4KCg4KBwQABAACAgESA1YEFAoOCgcE
AAQAAgICEgNWFxgKnQIKBAQABAESBF0CdQMajgIgVGhlIHN0YXRlIG9mIGFuIGluZGV4LiBE
dXJpbmcgaW5kZXggY3JlYXRpb24sIGFuIGluZGV4IHdpbGwgYmUgaW4gdGhlCiBgQ1JFQVRJ
TkdgIHN0YXRlLiBJZiB0aGUgaW5kZXggaXMgY3JlYXRlZCBzdWNjZXNzZnVsbHksIGl0IHdp
bGwgdHJhbnNpdGlvbgogdG8gdGhlIGBSRUFEWWAgc3RhdGUuIElmIHRoZSBpbmRleCBjcmVh
dGlvbiBlbmNvdW50ZXJzIGEgcHJvYmxlbSwgdGhlIGluZGV4CiB3aWxsIHRyYW5zaXRpb24g
dG8gdGhlIGBORUVEU19SRVBBSVJgIHN0YXRlLgoKDAoFBAAEAQESA10HDAoqCgYEAAQBAgAS
A18EGhobIFRoZSBzdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAECAAESA18EFQoOCgcE
AAQBAgACEgNfGBkKsgEKBgQABAECARIDZQQRGqIBIFRoZSBpbmRleCBpcyBiZWluZyBjcmVh
dGVkLgogVGhlcmUgaXMgYW4gYWN0aXZlIGxvbmctcnVubmluZyBvcGVyYXRpb24gZm9yIHRo
ZSBpbmRleC4KIFRoZSBpbmRleCBpcyB1cGRhdGVkIHdoZW4gd3JpdGluZyBhIGRvY3VtZW50
LgogU29tZSBpbmRleCBkYXRhIG1heSBleGlzdC4KCg4KBwQABAECAQESA2UEDAoOCgcEAAQB
AgECEgNlDxAKpgEKBgQABAECAhIDagQOGpYBIFRoZSBpbmRleCBpcyByZWFkeSB0byBiZSB1
c2VkLgogVGhlIGluZGV4IGlzIHVwZGF0ZWQgd2hlbiB3cml0aW5nIGEgZG9jdW1lbnQuCiBU
aGUgaW5kZXggaXMgZnVsbHkgcG9wdWxhdGVkIGZyb20gYWxsIHN0b3JlZCBkb2N1bWVudHMg
aXQgYXBwbGllcyB0by4KCg4KBwQABAECAgESA2oECQoOCgcEAAQBAgICEgNqDA0KpwMKBgQA
BAECAxIDdAQVGpcDIFRoZSBpbmRleCB3YXMgYmVpbmcgY3JlYXRlZCwgYnV0IHNvbWV0aGlu
ZyB3ZW50IHdyb25nLgogVGhlcmUgaXMgbm8gYWN0aXZlIGxvbmctcnVubmluZyBvcGVyYXRp
b24gZm9yIHRoZSBpbmRleCwKIGFuZCB0aGUgbW9zdCByZWNlbnRseSBmaW5pc2hlZCBsb25n
LXJ1bm5pbmcgb3BlcmF0aW9uIGZhaWxlZC4KIFRoZSBpbmRleCBpcyBub3QgdXBkYXRlZCB3
aGVuIHdyaXRpbmcgYSBkb2N1bWVudC4KIFNvbWUgaW5kZXggZGF0YSBtYXkgZXhpc3QuCiBV
c2UgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zIEFQSSB0byBkZXRlcm1pbmUg
d2h5IHRoZSBvcGVyYXRpb24KIHRoYXQgbGFzdCBhdHRlbXB0ZWQgdG8gY3JlYXRlIHRoaXMg
aW5kZXggZmFpbGVkLCB0aGVuIHJlLWNyZWF0ZSB0aGUKIGluZGV4LgoKDgoHBAAEAQIDARID
dAQQCg4KBwQABAECAwISA3QTFAqcAgoEBAACABIDewISGo4CIE91dHB1dCBvbmx5LiBBIHNl
cnZlciBkZWZpbmVkIG5hbWUgZm9yIHRoaXMgaW5kZXguCiBUaGUgZm9ybSBvZiB0aGlzIG5h
bWUgZm9yIGNvbXBvc2l0ZSBpbmRleGVzIHdpbGwgYmU6CiBgcHJvamVjdHMve3Byb2plY3Rf
aWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25Hcm91cHMve2NvbGxlY3Rp
b25faWR9L2luZGV4ZXMve2NvbXBvc2l0ZV9pbmRleF9pZH1gCiBGb3Igc2luZ2xlIGZpZWxk
IGluZGV4ZXMsIHRoaXMgZmllbGQgd2lsbCBiZSBlbXB0eS4KCgwKBQQAAgAFEgN7AggKDAoF
BAACAAESA3sJDQoMCgUEAAIAAxIDexARCp4DCgQEAAIBEgSEAQIdGo8DIEluZGV4ZXMgd2l0
aCBhIGNvbGxlY3Rpb24gcXVlcnkgc2NvcGUgc3BlY2lmaWVkIGFsbG93IHF1ZXJpZXMKIGFn
YWluc3QgYSBjb2xsZWN0aW9uIHRoYXQgaXMgdGhlIGNoaWxkIG9mIGEgc3BlY2lmaWMgZG9j
dW1lbnQsIHNwZWNpZmllZCBhdAogcXVlcnkgdGltZSwgYW5kIHRoYXQgaGFzIHRoZSBzYW1l
IGNvbGxlY3Rpb24gaWQuCgogSW5kZXhlcyB3aXRoIGEgY29sbGVjdGlvbiBncm91cCBxdWVy
eSBzY29wZSBzcGVjaWZpZWQgYWxsb3cgcXVlcmllcyBhZ2FpbnN0CiBhbGwgY29sbGVjdGlv
bnMgZGVzY2VuZGVkIGZyb20gYSBzcGVjaWZpYyBkb2N1bWVudCwgc3BlY2lmaWVkIGF0IHF1
ZXJ5CiB0aW1lLCBhbmQgdGhhdCBoYXZlIHRoZSBzYW1lIGNvbGxlY3Rpb24gaWQgYXMgdGhp
cyBpbmRleC4KCg0KBQQAAgEGEgSEAQIMCg0KBQQAAgEBEgSEAQ0YCg0KBQQAAgEDEgSEARsc
CtYECgQEAAICEgSRAQIhGscEIFRoZSBmaWVsZHMgc3VwcG9ydGVkIGJ5IHRoaXMgaW5kZXgu
CgogRm9yIGNvbXBvc2l0ZSBpbmRleGVzLCB0aGlzIGlzIGFsd2F5cyAyIG9yIG1vcmUgZmll
bGRzLgogVGhlIGxhc3QgZmllbGQgZW50cnkgaXMgYWx3YXlzIGZvciB0aGUgZmllbGQgcGF0
aCBgX19uYW1lX19gLiBJZiwgb24KIGNyZWF0aW9uLCBgX19uYW1lX19gIHdhcyBub3Qgc3Bl
Y2lmaWVkIGFzIHRoZSBsYXN0IGZpZWxkLCBpdCB3aWxsIGJlIGFkZGVkCiBhdXRvbWF0aWNh
bGx5IHdpdGggdGhlIHNhbWUgZGlyZWN0aW9uIGFzIHRoYXQgb2YgdGhlIGxhc3QgZmllbGQg
ZGVmaW5lZC4gSWYKIHRoZSBmaW5hbCBmaWVsZCBpbiBhIGNvbXBvc2l0ZSBpbmRleCBpcyBu
b3QgZGlyZWN0aW9uYWwsIHRoZSBgX19uYW1lX19gCiB3aWxsIGJlIG9yZGVyZWQgQVNDRU5E
SU5HICh1bmxlc3MgZXhwbGljaXRseSBzcGVjaWZpZWQpLgoKIEZvciBzaW5nbGUgZmllbGQg
aW5kZXhlcywgdGhpcyB3aWxsIGFsd2F5cyBiZSBleGFjdGx5IG9uZSBlbnRyeSB3aXRoIGEK
IGZpZWxkIHBhdGggZXF1YWwgdG8gdGhlIGZpZWxkIHBhdGggb2YgdGhlIGFzc29jaWF0ZWQg
ZmllbGQuCgoNCgUEAAICBBIEkQECCgoNCgUEAAICBhIEkQELFQoNCgUEAAICARIEkQEWHAoN
CgUEAAICAxIEkQEfIAo8CgQEAAIDEgSUAQISGi4gT3V0cHV0IG9ubHkuIFRoZSBzZXJ2aW5n
IHN0YXRlIG9mIHRoZSBpbmRleC4KCg0KBQQAAgMGEgSUAQIHCg0KBQQAAgMBEgSUAQgNCg0K
BQQAAgMDEgSUARARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta2::Index::Index ===
    # Fields for Index
    # Field: name Type: 9 ()
    # Field: query_scope Type: 14 (.google.firestore.admin.v1beta2.Index.QueryScope)
    # Field: fields Type: 11 (.google.firestore.admin.v1beta2.Index.IndexField)
    # Field: state Type: 14 (.google.firestore.admin.v1beta2.Index.State)

# Enum: Index::QueryScope
our $Index_QUERY_SCOPE_UNSPECIFIED = 0;
our $Index_COLLECTION = 1;
our $Index_COLLECTION_GROUP = 2;

# Enum: Index::State
our $Index_STATE_UNSPECIFIED = 0;
our $Index_CREATING = 1;
our $Index_READY = 2;
our $Index_NEEDS_REPAIR = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta2::Index - Compiled Protocol Buffers messages for google/firestore/admin/v1beta2/index.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta2::Index;

    my $msg = Google::Firestore::Admin::V1beta2::Index::Index->new({
        name => $name,
        query_scope => $query_scope,
        fields => $fields,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta2::Index::Index->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta2/index.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta2::Index::Index

Cloud Firestore indexes enable simple and complex queries against
documents in a database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. A server defined name for this index.
The form of this name for composite indexes will be:
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{composite_index_id}`
For single field indexes, this field will be empty.

=item * C<< $msg->query_scope() >> / C<< $msg->query_scope($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta2::Index::QueryScope>)

Indexes with a collection query scope specified allow queries
against a collection that is the child of a specific document, specified at
query time, and that has the same collection id.

Indexes with a collection group query scope specified allow queries against
all collections descended from a specific document, specified at query
time, and that have the same collection id as this index.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Index::Index::IndexField>)

The fields supported by this index.

For composite indexes, this is always 2 or more fields.
The last field entry is always for the field path `__name__`. If, on
creation, `__name__` was not specified as the last field, it will be added
automatically with the same direction as that of the last field defined. If
the final field in a composite index is not directional, the `__name__`
will be ordered ASCENDING (unless explicitly specified).

For single field indexes, this will always be exactly one entry with a
field path equal to the field path of the associated field.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta2::Index::State>)

Output only. The serving state of the index.

=back

=head3 Enum: Index::QueryScope

=over 4

=item * C<QUERY_SCOPE_UNSPECIFIED> => C<0>

=item * C<COLLECTION> => C<1>

=item * C<COLLECTION_GROUP> => C<2>

=back

=head3 Enum: Index::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<NEEDS_REPAIR> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta2::Index::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
