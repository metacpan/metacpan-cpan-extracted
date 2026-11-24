package Google::Devtools::Resultstore::V2::TestSuite;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Devtools::Resultstore::V2::Common };
    eval { require Google::Devtools::Resultstore::V2::File };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvdGVzdF9zdWl0ZS5wcm90bxIeZ29v
Z2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyGitnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3Rv
cmUvdjIvY29tbW9uLnByb3RvGilnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvZmls
ZS5wcm90byK4AwoJVGVzdFN1aXRlEh0KCnN1aXRlX25hbWUYASABKAlSCXN1aXRlTmFtZRI6
CgV0ZXN0cxgCIAMoCzIkLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5UZXN0UgV0
ZXN0cxJHCghmYWlsdXJlcxgDIAMoCzIrLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52
Mi5UZXN0RmFpbHVyZVIIZmFpbHVyZXMSQQoGZXJyb3JzGAQgAygLMikuZ29vZ2xlLmRldnRv
b2xzLnJlc3VsdHN0b3JlLnYyLlRlc3RFcnJvclIGZXJyb3JzEj4KBnRpbWluZxgGIAEoCzIm
Lmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5UaW1pbmdSBnRpbWluZxJICgpwcm9w
ZXJ0aWVzGAcgAygLMiguZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlByb3BlcnR5
Ugpwcm9wZXJ0aWVzEjoKBWZpbGVzGAggAygLMiQuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0
b3JlLnYyLkZpbGVSBWZpbGVzIqgBCgRUZXN0EkcKCXRlc3RfY2FzZRgBIAEoCzIoLmdvb2ds
ZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5UZXN0Q2FzZUgAUgh0ZXN0Q2FzZRJKCgp0ZXN0
X3N1aXRlGAIgASgLMikuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlRlc3RTdWl0
ZUgAUgl0ZXN0U3VpdGVCCwoJdGVzdF90eXBlIqUFCghUZXN0Q2FzZRIbCgljYXNlX25hbWUY
ASABKAlSCGNhc2VOYW1lEh0KCmNsYXNzX25hbWUYAiABKAlSCWNsYXNzTmFtZRJHCgZyZXN1
bHQYAyABKA4yLy5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuVGVzdENhc2UuUmVz
dWx0UgZyZXN1bHQSRwoIZmFpbHVyZXMYBCADKAsyKy5nb29nbGUuZGV2dG9vbHMucmVzdWx0
c3RvcmUudjIuVGVzdEZhaWx1cmVSCGZhaWx1cmVzEkEKBmVycm9ycxgFIAMoCzIpLmdvb2ds
ZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5UZXN0RXJyb3JSBmVycm9ycxI+CgZ0aW1pbmcY
ByABKAsyJi5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuVGltaW5nUgZ0aW1pbmcS
SAoKcHJvcGVydGllcxgIIAMoCzIoLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5Q
cm9wZXJ0eVIKcHJvcGVydGllcxI6CgVmaWxlcxgJIAMoCzIkLmdvb2dsZS5kZXZ0b29scy5y
ZXN1bHRzdG9yZS52Mi5GaWxlUgVmaWxlcxIhCgxyZXRyeV9udW1iZXIYCiABKAVSC3JldHJ5
TnVtYmVyEiMKDXJlcGVhdF9udW1iZXIYCyABKAVSDHJlcGVhdE51bWJlciJ6CgZSZXN1bHQS
FgoSUkVTVUxUX1VOU1BFQ0lGSUVEEAASDQoJQ09NUExFVEVEEAESDwoLSU5URVJSVVBURUQQ
AhINCglDQU5DRUxMRUQQAxIMCghGSUxURVJFRBAEEgsKB1NLSVBQRUQQBRIOCgpTVVBQUkVT
U0VEEAYisgEKC1Rlc3RGYWlsdXJlEicKD2ZhaWx1cmVfbWVzc2FnZRgBIAEoCVIOZmFpbHVy
ZU1lc3NhZ2USJQoOZXhjZXB0aW9uX3R5cGUYAiABKAlSDWV4Y2VwdGlvblR5cGUSHwoLc3Rh
Y2tfdHJhY2UYAyABKAlSCnN0YWNrVHJhY2USGgoIZXhwZWN0ZWQYBCADKAlSCGV4cGVjdGVk
EhYKBmFjdHVhbBgFIAMoCVIGYWN0dWFsIngKCVRlc3RFcnJvchIjCg1lcnJvcl9tZXNzYWdl
GAEgASgJUgxlcnJvck1lc3NhZ2USJQoOZXhjZXB0aW9uX3R5cGUYAiABKAlSDWV4Y2VwdGlv
blR5cGUSHwoLc3RhY2tfdHJhY2UYAyABKAlSCnN0YWNrVHJhY2VCgQEKImNvbS5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjJCDlRlc3RTdWl0ZVByb3RvUAFaSWdvb2dsZS5nb2xh
bmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjI7cmVz
dWx0c3RvcmVKs0UKBxIFDgDPAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACcKCQoCAwASAxIANQoJCgIDARIDEwAzCggKAQgSAxUAYAoJCgIICxIDFQBg
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgAOwoJ
CgIIARIDGAA7CmYKAgQAEgQcADsBGlogVGhlIHJlc3VsdCBvZiBydW5uaW5nIGEgdGVzdCBz
dWl0ZSwgYXMgcmVwb3J0ZWQgaW4gYSA8dGVzdHN1aXRlPiBlbGVtZW50IG9mCiBhbiBYTUwg
bG9nLgoKCgoDBAABEgMcCBEKwAEKBAQAAgASAyACGBqyASBUaGUgZnVsbCBuYW1lIG9mIHRo
aXMgc3VpdGUsIGFzIHJlcG9ydGVkIGluIHRoZSBuYW1lIGF0dHJpYnV0ZS4gRm9yIEphdmEK
IHRlc3RzLCB0aGlzIGlzIG5vcm1hbGx5IHRoZSBmdWxseSBxdWFsaWZpZWQgY2xhc3MgbmFt
ZS4gRWcuCiAiY29tLmdvb2dsZS5jb21tb24uaGFzaC5CbG9vbUZpbHRlclRlc3QiLgoKDAoF
BAACAAUSAyACCAoMCgUEAAIAARIDIAkTCgwKBQQAAgADEgMgFhcKsgEKBAQAAgESAyUCGhqk
ASBUaGUgcmVzdWx0cyBvZiB0aGUgdGVzdCBjYXNlcyBhbmQgdGVzdCBzdWl0ZXMgY29udGFp
bmVkIGluIHRoaXMgc3VpdGUsCiBhcyByZXBvcnRlZCBpbiB0aGUgPHRlc3RjYXNlPiBhbmQg
PHRlc3RzdWl0ZT4gZWxlbWVudHMgY29udGFpbmVkIHdpdGhpbgogdGhpcyA8dGVzdHN1aXRl
Pi4KCgwKBQQAAgEEEgMlAgoKDAoFBAACAQYSAyULDwoMCgUEAAIBARIDJRAVCgwKBQQAAgED
EgMlGBkKTwoEBAACAhIDKAIkGkIgRmFpbHVyZXMgcmVwb3J0ZWQgaW4gPGZhaWx1cmU+IGVs
ZW1lbnRzIHdpdGhpbiB0aGlzIDx0ZXN0c3VpdGU+LgoKDAoFBAACAgQSAygCCgoMCgUEAAIC
BhIDKAsWCgwKBQQAAgIBEgMoFx8KDAoFBAACAgMSAygiIwpLCgQEAAIDEgMrAiAaPiBFcnJv
cnMgcmVwb3J0ZWQgaW4gPGVycm9yPiBlbGVtZW50cyB3aXRoaW4gdGhpcyA8dGVzdHN1aXRl
Pi4KCgwKBQQAAgMEEgMrAgoKDAoFBAACAwYSAysLFAoMCgUEAAIDARIDKxUbCgwKBQQAAgMD
EgMrHh8KVgoEBAACBBIDLgIUGkkgVGhlIHRpbWluZyBmb3IgdGhlIGVudGlyZSBUZXN0U3Vp
dGUsIGFzIHJlcG9ydGVkIGJ5IHRoZSB0aW1lIGF0dHJpYnV0ZS4KCgwKBQQAAgQGEgMuAggK
DAoFBAACBAESAy4JDwoMCgUEAAIEAxIDLhITCvUBCgQEAAIFEgM0AiMa5wEgQXJiaXRyYXJ5
IG5hbWUtdmFsdWUgcGFpcnMsIGFzIHJlcG9ydGVkIGluIGN1c3RvbSBhdHRyaWJ1dGVzIG9y
IGluIGEKIDxwcm9wZXJ0aWVzPiBlbGVtZW50IHdpdGhpbiB0aGlzIDx0ZXN0c3VpdGU+LiBN
dWx0aXBsZSBwcm9wZXJ0aWVzIGFyZQogYWxsb3dlZCB3aXRoIHRoZSBzYW1lIGtleS4gUHJv
cGVydGllcyB3aWxsIGJlIHJldHVybmVkIGluIGxleGljb2dyYXBoaWNhbAogb3JkZXIgYnkg
a2V5LgoKDAoFBAACBQQSAzQCCgoMCgUEAAIFBhIDNAsTCgwKBQQAAgUBEgM0FB4KDAoFBAAC
BQMSAzQhIgr0AQoEBAACBhIDOgIaGuYBIEZpbGVzIHByb2R1Y2VkIGJ5IHRoaXMgdGVzdCBz
dWl0ZSwgYXMgcmVwb3J0ZWQgYnkgdW5kZWNsYXJlZCBvdXRwdXQKIGFubm90YXRpb25zLgog
VGhlIGZpbGUgSURzIG11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGlzIGxpc3QuIER1cGxpY2F0
ZSBmaWxlIElEcyB3aWxsCiByZXN1bHQgaW4gYW4gZXJyb3IuIEZpbGVzIHdpbGwgYmUgcmV0
dXJuZWQgaW4gbGV4aWNvZ3JhcGhpY2FsIG9yZGVyIGJ5IElELgoKDAoFBAACBgQSAzoCCgoM
CgUEAAIGBhIDOgsPCgwKBQQAAgYBEgM6EBUKDAoFBAACBgMSAzoYGQqIAQoCBAESBD8ASAEa
fCBUaGUgcmVzdWx0IG9mIHJ1bm5pbmcgYSB0ZXN0IGNhc2Ugb3IgdGVzdCBzdWl0ZS4gSlVu
aXQzIFRlc3REZWNvcmF0b3JzIGFyZQogcmVwcmVzZW50ZWQgYXMgYSBUZXN0U3VpdGUgd2l0
aCBhIHNpbmdsZSB0ZXN0LgoKCgoDBAEBEgM/CAwKMAoEBAEIABIEQQJHAxoiIEVpdGhlciBh
IFRlc3RDYXNlIG9mIGEgVGVzdFN1aXRlCgoMCgUEAQgAARIDQQgRCjgKBAQBAgASA0MEGxor
IFdoZW4gdGhpcyBjb250YWlucyBqdXN0IGEgc2luZ2xlIFRlc3RDYXNlCgoMCgUEAQIABhID
QwQMCgwKBQQBAgABEgNDDRYKDAoFBAECAAMSA0MZGgo8CgQEAQIBEgNGBB0aLyBXaGVuIHRo
aXMgY29udGFpbnMgYSBUZXN0U3VpdGUgb2YgdGVzdCBjYXNlcy4KCgwKBQQBAgEGEgNGBA0K
DAoFBAECAQESA0YOGAoMCgUEAQIBAxIDRhscCmUKAgQCEgVMAJcBARpYIFRoZSByZXN1bHQg
b2YgcnVubmluZyBhIHRlc3QgY2FzZSwgYXMgcmVwb3J0ZWQgaW4gYSA8dGVzdGNhc2U+IGVs
ZW1lbnQgb2YKIGFuIFhNTCBsb2cuCgoKCgMEAgESA0wIEAoyCgQEAgQAEgROAmoDGiQgVGhl
IHJlc3VsdCBvZiBydW5uaW5nIGEgdGVzdCBjYXNlLgoKDAoFBAIEAAESA04HDQo9CgYEAgQA
AgASA1AEGxouIFRoZSBpbXBsaWNpdCBkZWZhdWx0IGVudW0gdmFsdWUuIERvIG5vdCB1c2Uu
CgoOCgcEAgQAAgABEgNQBBYKDgoHBAIEAAIAAhIDUBkaCn4KBgQCBAACARIDVAQSGm8gVGVz
dCBjYXNlIHJhbiB0byBjb21wbGV0aW9uLiBMb29rIGZvciBmYWlsdXJlcyBvciBlcnJvcnMg
dG8gZGV0ZXJtaW5lCiB3aGV0aGVyIGl0IHBhc3NlZCwgZmFpbGVkLCBvciBlcnJvcmVkLgoK
DgoHBAIEAAIBARIDVAQNCg4KBwQCBAACAQISA1QQEQqGAQoGBAIEAAICEgNYBBQadyBUZXN0
IGNhc2Ugc3RhcnRlZCBidXQgZGlkIG5vdCBjb21wbGV0ZSBiZWNhdXNlIHRoZSB0ZXN0IGhh
cm5lc3MgcmVjZWl2ZWQKIGEgc2lnbmFsIGFuZCBkZWNpZGVkIHRvIHN0b3AgcnVubmluZyB0
ZXN0cy4KCg4KBwQCBAACAgESA1gEDwoOCgcEAgQAAgICEgNYEhMKZAoGBAIEAAIDEgNcBBIa
VSBUZXN0IGNhc2Ugd2FzIG5vdCBzdGFydGVkIGJlY2F1c2UgdGhlIHRlc3QgaGFybmVzcyBy
ZWNlaXZlZCBhIFNJR0lOVCBvcgogdGltZWQgb3V0LgoKDgoHBAIEAAIDARIDXAQNCg4KBwQC
BAACAwISA1wQEQqFAQoGBAIEAAIEEgNgBBEadiBUZXN0IGNhc2Ugd2FzIG5vdCBydW4gYmVj
YXVzZSB0aGUgdXNlciBvciBwcm9jZXNzIHJ1bm5pbmcgdGhlIHRlc3QKIHNwZWNpZmllZCBh
IGZpbHRlciB0aGF0IGV4Y2x1ZGVkIHRoaXMgdGVzdCBjYXNlLgoKDgoHBAIEAAIEARIDYAQM
Cg4KBwQCBAACBAISA2APEArSAQoGBAIEAAIFEgNlBBAawgEgVGVzdCBjYXNlIHdhcyBub3Qg
cnVuIHRvIGNvbXBsZXRpb24gYmVjYXVzZSB0aGUgdGVzdCBjYXNlIGRlY2lkZWQgaXQKIHNo
b3VsZCBub3QgYmUgcnVuIChlZy4gZHVlIHRvIGEgZmFpbGVkIGFzc3VtcHRpb24gaW4gYSBK
VW5pdDQgdGVzdCkuCiBQZXItdGVzdCBzZXR1cCBvciB0ZWFyLWRvd24gbWF5IG9yIG1heSBu
b3QgaGF2ZSBydW4uCgoOCgcEAgQAAgUBEgNlBAsKDgoHBAIEAAIFAhIDZQ4PCpoBCgYEAgQA
AgYSA2kEExqKASBUaGUgdGVzdCBmcmFtZXdvcmsgZGlkIG5vdCBydW4gdGhlIHRlc3QgY2Fz
ZSBiZWNhdXNlIGl0IHdhcyBsYWJlbGVkIGFzCiBzdXBwcmVzc2VkLiAgRWcuIGlmIHNvbWVv
bmUgdGVtcG9yYXJpbHkgZGlzYWJsZXMgYSBmYWlsaW5nIHRlc3QuCgoOCgcEAgQAAgYBEgNp
BA4KDgoHBAIEAAIGAhIDaRESCooBCgQEAgIAEgNuAhcafSBUaGUgbmFtZSBvZiB0aGUgdGVz
dCBjYXNlLCBhcyByZXBvcnRlZCBpbiB0aGUgbmFtZSBhdHRyaWJ1dGUuIEZvciBKYXZhLAog
dGhpcyBpcyBub3JtYWxseSB0aGUgbWV0aG9kIG5hbWUuIEVnLiAidGVzdEJhc2ljIi4KCgwK
BQQCAgAFEgNuAggKDAoFBAICAAESA24JEgoMCgUEAgIAAxIDbhUWCtwBCgQEAgIBEgNzAhga
zgEgVGhlIG5hbWUgb2YgdGhlIGNsYXNzIGluIHdoaWNoIHRoZSB0ZXN0IGNhc2Ugd2FzIGRl
ZmluZWQsIGFzIHJlcG9ydGVkIGluCiB0aGUgY2xhc3NuYW1lIGF0dHJpYnV0ZS4gRm9yIEph
dmEsIHRoaXMgaXMgbm9ybWFsbHkgdGhlIGZ1bGx5IHF1YWxpZmllZAogY2xhc3MgbmFtZS4g
RWcuICJjb20uZ29vZ2xlLmNvbW1vbi5oYXNoLkJsb29tRmlsdGVyVGVzdCIuCgoMCgUEAgIB
BRIDcwIICgwKBQQCAgEBEgNzCRMKDAoFBAICAQMSA3MWFwqKAQoEBAICAhIDdwIUGn0gQW4g
ZW51bSByZXBvcnRlZCBpbiB0aGUgcmVzdWx0IGF0dHJpYnV0ZSB0aGF0IGlzIHVzZWQgaW4g
Y29uanVuY3Rpb24gd2l0aAogZmFpbHVyZXMgYW5kIGVycm9ycyBiZWxvdyB0byByZXBvcnQg
dGhlIG91dGNvbWUuCgoMCgUEAgICBhIDdwIICgwKBQQCAgIBEgN3CQ8KDAoFBAICAgMSA3cS
EwpOCgQEAgIDEgN6AiQaQSBGYWlsdXJlcyByZXBvcnRlZCBpbiA8ZmFpbHVyZT4gZWxlbWVu
dHMgd2l0aGluIHRoaXMgPHRlc3RjYXNlPi4KCgwKBQQCAgMEEgN6AgoKDAoFBAICAwYSA3oL
FgoMCgUEAgIDARIDehcfCgwKBQQCAgMDEgN6IiMKSgoEBAICBBIDfQIgGj0gRXJyb3JzIHJl
cG9ydGVkIGluIDxlcnJvcj4gZWxlbWVudHMgd2l0aGluIHRoaXMgPHRlc3RjYXNlPi4KCgwK
BQQCAgQEEgN9AgoKDAoFBAICBAYSA30LFAoMCgUEAgIEARIDfRUbCgwKBQQCAgQDEgN9Hh8K
TwoEBAICBRIEgAECFBpBIFRoZSB0aW1pbmcgZm9yIHRoZSBUZXN0Q2FzZSwgYXMgcmVwb3J0
ZWQgYnkgdGhlIHRpbWUgYXR0cmlidXRlLgoKDQoFBAICBQYSBIABAggKDQoFBAICBQESBIAB
CQ8KDQoFBAICBQMSBIABEhMK9QEKBAQCAgYSBIYBAiMa5gEgQXJiaXRyYXJ5IG5hbWUtdmFs
dWUgcGFpcnMsIGFzIHJlcG9ydGVkIGluIGN1c3RvbSBhdHRyaWJ1dGVzIG9yIGluIGEKIDxw
cm9wZXJ0aWVzPiBlbGVtZW50IHdpdGhpbiB0aGlzIDx0ZXN0Y2FzZT4uIE11bHRpcGxlIHBy
b3BlcnRpZXMgYXJlCiBhbGxvd2VkIHdpdGggdGhlIHNhbWUga2V5LiBQcm9wZXJ0aWVzIHdp
bGwgYmUgcmV0dXJuZWQgaW4gbGV4aWNvZ3JhcGhpY2FsCiBvcmRlciBieSBrZXkuCgoNCgUE
AgIGBBIEhgECCgoNCgUEAgIGBhIEhgELEwoNCgUEAgIGARIEhgEUHgoNCgUEAgIGAxIEhgEh
Igr0AQoEBAICBxIEjAECGhrlASBGaWxlcyBwcm9kdWNlZCBieSB0aGlzIHRlc3QgY2FzZSwg
YXMgcmVwb3J0ZWQgYnkgdW5kZWNsYXJlZCBvdXRwdXQKIGFubm90YXRpb25zLgogVGhlIGZp
bGUgSURzIG11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGlzIGxpc3QuIER1cGxpY2F0ZSBmaWxl
IElEcyB3aWxsCiByZXN1bHQgaW4gYW4gZXJyb3IuIEZpbGVzIHdpbGwgYmUgcmV0dXJuZWQg
aW4gbGV4aWNvZ3JhcGhpY2FsIG9yZGVyIGJ5IElELgoKDQoFBAICBwQSBIwBAgoKDQoFBAIC
BwYSBIwBCw8KDQoFBAICBwESBIwBEBUKDQoFBAICBwMSBIwBGBkKtAEKBAQCAggSBJEBAhoa
pQEgVGhlIDAtaW5kZXhlZCByZXRyeSBudW1iZXIgb2YgdGhlIHRlc3QgY2FzZS4gQSB2YWx1
ZSBvZiBgMGAgbWF5IGluZGljYXRlCiBlaXRoZXIgdGhhdCB0aGlzIGlzIHRoZSBmaXJzdCBp
biBhIHNlcmllcyBvZiByZXRyaWVzLCBvciB0aGF0IG5vIHJldHJpZXMKIHdlcmUgcmVxdWVz
dGVkLgoKDQoFBAICCAUSBJEBAgcKDQoFBAICCAESBJEBCBQKDQoFBAICCAMSBJEBFxkKtQEK
BAQCAgkSBJYBAhsapgEgVGhlIDAtaW5kZXhlZCByZXBlYXQgbnVtYmVyIG9mIHRoZSB0ZXN0
IGNhc2UuIEEgdmFsdWUgb2YgYDBgIG1heSBpbmRpY2F0ZQogZWl0aGVyIHRoYXQgdGhpcyBp
cyB0aGUgZmlyc3QgaW4gYSBzZXJpZXMgb2YgcmVwZWF0cywgb3IgdGhhdCBubyByZXBlYXRz
CiB3ZXJlIHJlcXVlc3RlZC4KCg0KBQQCAgkFEgSWAQIHCg0KBQQCAgkBEgSWAQgVCg0KBQQC
AgkDEgSWARgaCroCCgIEAxIGnQEAugEBGqsCIFJlcHJlc2VudHMgYSB2aW9sYXRlZCBhc3Nl
cnRpb24sIGFzIHJlcG9ydGVkIGluIGEgPGZhaWx1cmU+IGVsZW1lbnQgd2l0aGluIGEKIDx0
ZXN0Y2FzZT4uIFNvbWUgbGFuZ3VhZ2VzIGFsbG93IGFzc2VydGlvbnMgdG8gYmUgbWFkZSB3
aXRob3V0IHN0b3BwaW5nIHRoZQogdGVzdCBjYXNlIHdoZW4gdGhleSdyZSB2aW9sYXRlZCwg
bGVhZGluZyB0byBtdWx0aXBsZSBUZXN0RmFpbHVyZXMuIEZvciBKYXZhLAogbXVsdGlwbGUg
VGVzdEZhaWx1cmVzIGFyZSB1c2VkIHRvIHJlcHJlc2VudCBhIGNoYWluZWQgZXhjZXB0aW9u
LgoKCwoDBAMBEgSdAQgTCpYBCgQEAwIAEgSgAQIdGocBIFRoZSBleGNlcHRpb24gbWVzc2Fn
ZSByZXBvcnRlZCBpbiB0aGUgbWVzc2FnZSBhdHRyaWJ1dGUuIFR5cGljYWxseSBzaG9ydCwK
IGJ1dCBtYXkgYmUgbXVsdGktbGluZS4gRWcuICJFeHBlY3RlZCAnZm9vJyBidXQgd2FzICdi
YXInIi4KCg0KBQQDAgAFEgSgAQIICg0KBQQDAgABEgSgAQkYCg0KBQQDAgADEgSgARscCnoK
BAQDAgESBKQBAhwabCBUaGUgdHlwZSBvZiB0aGUgZXhjZXB0aW9uIGJlaW5nIHRocm93biwg
cmVwb3J0ZWQgaW4gdGhlIHR5cGUgYXR0cmlidXRlLgogRWc6ICJvcmcuanVuaXQuQ29tcGFy
aXNvbkZhaWx1cmUiCgoNCgUEAwIBBRIEpAECCAoNCgUEAwIBARIEpAEJFwoNCgUEAwIBAxIE
pAEaGwrYAgoEBAMCAhIEqwECGRrJAiBUaGUgc3RhY2sgdHJhY2UgcmVwb3J0ZWQgYXMgdGhl
IGNvbnRlbnQgb2YgdGhlIDxmYWlsdXJlPiBlbGVtZW50LCBvZnRlbiBpbgogYSBDREFUQSBi
bG9jay4gVGhpcyBjb250YWlucyBvbmUgbGluZSBmb3IgZWFjaCBzdGFjayBmcmFtZSwgZWFj
aCBpbmNsdWRpbmcKIGEgbWV0aG9kL2Z1bmN0aW9uIG5hbWUsIGEgY2xhc3MvZmlsZSBuYW1l
LCBhbmQgYSBsaW5lIG51bWJlci4gTW9zdCByZWNlbnQKIGNhbGwgaXMgdXN1YWxseSBmaXJz
dCwgYnV0IG5vdCBmb3IgUHl0aG9uIHN0YWNrIHRyYWNlcy4gTWF5IGNvbnRhaW4gdGhlCiBl
eGNlcHRpb25fdHlwZSBhbmQgbWVzc2FnZS4KCg0KBQQDAgIFEgSrAQIICg0KBQQDAgIBEgSr
AQkUCg0KBQQDAgIDEgSrARcYCuYBCgQEAwIDEgSyAQIfGtcBIFRoZSBleHBlY3RlZCB2YWx1
ZXMuCgogVGhlc2UgdmFsdWVzIGNhbiBiZSBkaWZmZWQgYWdhaW5zdCB0aGUgYWN0dWFsIHZh
bHVlcy4gT2Z0ZW4sIHRoZXJlIGlzIGp1c3QKIG9uZSBhY3R1YWwgYW5kIG9uZSBleHBlY3Rl
ZCB2YWx1ZS4gSWYgdGhlcmUgaXMgbW9yZSB0aGFuIG9uZSwgdGhleSBzaG91bGQKIGJlIGNv
bXBhcmVkIGFzIGFuIHVub3JkZXJlZCBjb2xsZWN0aW9uLgoKDQoFBAMCAwQSBLIBAgoKDQoF
BAMCAwUSBLIBCxEKDQoFBAMCAwESBLIBEhoKDQoFBAMCAwMSBLIBHR4K5gEKBAQDAgQSBLkB
Ah0a1wEgVGhlIGFjdHVhbCB2YWx1ZXMuCgogVGhlc2UgdmFsdWVzIGNhbiBiZSBkaWZmZWQg
YWdhaW5zdCB0aGUgZXhwZWN0ZWQgdmFsdWVzLiBPZnRlbiwgdGhlcmUgaXMKIGp1c3Qgb25l
IGFjdHVhbCBhbmQgb25lIGV4cGVjdGVkIHZhbHVlLiBJZiB0aGVyZSBpcyBtb3JlIHRoYW4g
b25lLCB0aGV5CiBzaG91bGQgYmUgY29tcGFyZWQgYXMgYW4gdW5vcmRlcmVkIGNvbGxlY3Rp
b24uCgoNCgUEAwIEBBIEuQECCgoNCgUEAwIEBRIEuQELEQoNCgUEAwIEARIEuQESGAoNCgUE
AwIEAxIEuQEbHArWAQoCBAQSBr8BAM8BARrHASBSZXByZXNlbnRzIGFuIGV4Y2VwdGlvbiB0
aGF0IHByZXZlbnRlZCBhIHRlc3QgY2FzZSBmcm9tIGNvbXBsZXRpbmcsIGFzCiByZXBvcnRl
ZCBpbiBhbiA8ZXJyb3I+IGVsZW1lbnQgd2l0aGluIGEgPHRlc3RjYXNlPi4gRm9yIEphdmEs
IG11bHRpcGxlCiBUZXN0RXJyb3JzIGFyZSB1c2VkIHRvIHJlcHJlc2VudCBhIGNoYWluZWQg
ZXhjZXB0aW9uLgoKCwoDBAQBEgS/AQgRCpUBCgQEBAIAEgTCAQIbGoYBIFRoZSBleGNlcHRp
b24gbWVzc2FnZSwgYXMgcmVwb3J0ZWQgaW4gdGhlIG1lc3NhZ2UgYXR0cmlidXRlLiBUeXBp
Y2FsbHkKIHNob3J0LCBidXQgbWF5IGJlIG11bHRpLWxpbmUuIEVnLiAiYXJndW1lbnQgY2Fu
bm90IGJlIG51bGwiLgoKDQoFBAQCAAUSBMIBAggKDQoFBAQCAAESBMIBCRYKDQoFBAQCAAMS
BMIBGRoKvQEKBAQEAgESBMcBAhwargEgVGhlIHR5cGUgb2YgdGhlIGV4Y2VwdGlvbiBiZWlu
ZyB0aHJvd24sIHJlcG9ydGVkIGluIHRoZSB0eXBlIGF0dHJpYnV0ZS4KIEZvciBKYXZhLCB0
aGlzIGlzIGEgZnVsbHkgcXVhbGlmaWVkIFRocm93YWJsZSBjbGFzcyBuYW1lLgogRWc6ICJq
YXZhLmxhbmcuSWxsZWdhbEFyZ3VtZW50RXhjZXB0aW9uIgoKDQoFBAQCAQUSBMcBAggKDQoF
BAQCAQESBMcBCRcKDQoFBAQCAQMSBMcBGhsK1gIKBAQEAgISBM4BAhkaxwIgVGhlIHN0YWNr
IHRyYWNlIHJlcG9ydGVkIGFzIHRoZSBjb250ZW50IG9mIHRoZSA8ZXJyb3I+IGVsZW1lbnQs
IG9mdGVuIGluCiBhIENEQVRBIGJsb2NrLiBUaGlzIGNvbnRhaW5zIG9uZSBsaW5lIGZvciBl
YWNoIHN0YWNrIGZyYW1lLCBlYWNoIGluY2x1ZGluZwogYSBtZXRob2QvZnVuY3Rpb24gbmFt
ZSwgYSBjbGFzcy9maWxlIG5hbWUsIGFuZCBhIGxpbmUgbnVtYmVyLiBNb3N0IHJlY2VudAog
Y2FsbCBpcyB1c3VhbGx5IGZpcnN0LCBidXQgbm90IGZvciBQeXRob24gc3RhY2sgdHJhY2Vz
LiBNYXkgY29udGFpbiB0aGUKIGV4Y2VwdGlvbl90eXBlIGFuZCBtZXNzYWdlLgoKDQoFBAQC
AgUSBM4BAggKDQoFBAQCAgESBM4BCRQKDQoFBAQCAgMSBM4BFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::TestSuite::TestSuite ===
    # Fields for TestSuite
    # Field: suite_name Type: 9 ()
    # Field: tests Type: 11 (.google.devtools.resultstore.v2.Test)
    # Field: failures Type: 11 (.google.devtools.resultstore.v2.TestFailure)
    # Field: errors Type: 11 (.google.devtools.resultstore.v2.TestError)
    # Field: timing Type: 11 (.google.devtools.resultstore.v2.Timing)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)

# === Message: Google::Devtools::Resultstore::V2::TestSuite::Test ===
    # Fields for Test
    # Field: test_case Type: 11 (.google.devtools.resultstore.v2.TestCase)
    # Field: test_suite Type: 11 (.google.devtools.resultstore.v2.TestSuite)

# === Message: Google::Devtools::Resultstore::V2::TestSuite::TestCase ===
    # Fields for TestCase
    # Field: case_name Type: 9 ()
    # Field: class_name Type: 9 ()
    # Field: result Type: 14 (.google.devtools.resultstore.v2.TestCase.Result)
    # Field: failures Type: 11 (.google.devtools.resultstore.v2.TestFailure)
    # Field: errors Type: 11 (.google.devtools.resultstore.v2.TestError)
    # Field: timing Type: 11 (.google.devtools.resultstore.v2.Timing)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)
    # Field: retry_number Type: 5 ()
    # Field: repeat_number Type: 5 ()

# Enum: TestCase::Result
our $TestCase_RESULT_UNSPECIFIED = 0;
our $TestCase_COMPLETED = 1;
our $TestCase_INTERRUPTED = 2;
our $TestCase_CANCELLED = 3;
our $TestCase_FILTERED = 4;
our $TestCase_SKIPPED = 5;
our $TestCase_SUPPRESSED = 6;

# === Message: Google::Devtools::Resultstore::V2::TestSuite::TestFailure ===
    # Fields for TestFailure
    # Field: failure_message Type: 9 ()
    # Field: exception_type Type: 9 ()
    # Field: stack_trace Type: 9 ()
    # Field: expected Type: 9 ()
    # Field: actual Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::TestSuite::TestError ===
    # Fields for TestError
    # Field: error_message Type: 9 ()
    # Field: exception_type Type: 9 ()
    # Field: stack_trace Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::TestSuite - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/test_suite.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::TestSuite;

    my $msg = Google::Devtools::Resultstore::V2::TestSuite::TestSuite->new({
        suite_name => $suite_name,
        tests => $tests,
        failures => $failures,
        errors => $errors,
    });

    # Read or update a field
    my $val = $msg->suite_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::TestSuite::TestSuite->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/test_suite.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::TestSuite::TestSuite

The result of running a test suite, as reported in a <testsuite> element of
an XML log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->suite_name() >> / C<< $msg->suite_name($value) >>

Type: C<String>

The full name of this suite, as reported in the name attribute. For Java
tests, this is normally the fully qualified class name. Eg.
"com.google.common.hash.BloomFilterTest".

=item * C<< $msg->tests() >> / C<< $msg->tests($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::Test>)

The results of the test cases and test suites contained in this suite,
as reported in the <testcase> and <testsuite> elements contained within
this <testsuite>.

=item * C<< $msg->failures() >> / C<< $msg->failures($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestFailure>)

Failures reported in <failure> elements within this <testsuite>.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestError>)

Errors reported in <error> elements within this <testsuite>.

=item * C<< $msg->timing() >> / C<< $msg->timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Timing>)

The timing for the entire TestSuite, as reported by the time attribute.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs, as reported in custom attributes or in a
<properties> element within this <testsuite>. Multiple properties are
allowed with the same key. Properties will be returned in lexicographical
order by key.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

Files produced by this test suite, as reported by undeclared output
annotations.
The file IDs must be unique within this list. Duplicate file IDs will
result in an error. Files will be returned in lexicographical order by ID.

=back

=head2 Google::Devtools::Resultstore::V2::TestSuite::Test

The result of running a test case or test suite. JUnit3 TestDecorators are
represented as a TestSuite with a single test.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_case() >> / C<< $msg->test_case($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestCase>)

When this contains just a single TestCase

=item * C<< $msg->test_suite() >> / C<< $msg->test_suite($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestSuite>)

When this contains a TestSuite of test cases.

=back

=head2 Google::Devtools::Resultstore::V2::TestSuite::TestCase

The result of running a test case, as reported in a <testcase> element of
an XML log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->case_name() >> / C<< $msg->case_name($value) >>

Type: C<String>

The name of the test case, as reported in the name attribute. For Java,
this is normally the method name. Eg. "testBasic".

=item * C<< $msg->class_name() >> / C<< $msg->class_name($value) >>

Type: C<String>

The name of the class in which the test case was defined, as reported in
the classname attribute. For Java, this is normally the fully qualified
class name. Eg. "com.google.common.hash.BloomFilterTest".

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::TestCase::Result>)

An enum reported in the result attribute that is used in conjunction with
failures and errors below to report the outcome.

=item * C<< $msg->failures() >> / C<< $msg->failures($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestFailure>)

Failures reported in <failure> elements within this <testcase>.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestError>)

Errors reported in <error> elements within this <testcase>.

=item * C<< $msg->timing() >> / C<< $msg->timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Timing>)

The timing for the TestCase, as reported by the time attribute.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs, as reported in custom attributes or in a
<properties> element within this <testcase>. Multiple properties are
allowed with the same key. Properties will be returned in lexicographical
order by key.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

Files produced by this test case, as reported by undeclared output
annotations.
The file IDs must be unique within this list. Duplicate file IDs will
result in an error. Files will be returned in lexicographical order by ID.

=item * C<< $msg->retry_number() >> / C<< $msg->retry_number($value) >>

Type: C<Int32>

The 0-indexed retry number of the test case. A value of `0` may indicate
either that this is the first in a series of retries, or that no retries
were requested.

=item * C<< $msg->repeat_number() >> / C<< $msg->repeat_number($value) >>

Type: C<Int32>

The 0-indexed repeat number of the test case. A value of `0` may indicate
either that this is the first in a series of repeats, or that no repeats
were requested.

=back

=head3 Enum: TestCase::Result

=over 4

=item * C<RESULT_UNSPECIFIED> => C<0>

=item * C<COMPLETED> => C<1>

=item * C<INTERRUPTED> => C<2>

=item * C<CANCELLED> => C<3>

=item * C<FILTERED> => C<4>

=item * C<SKIPPED> => C<5>

=item * C<SUPPRESSED> => C<6>

=back

=head2 Google::Devtools::Resultstore::V2::TestSuite::TestFailure

Represents a violated assertion, as reported in a <failure> element within a
<testcase>. Some languages allow assertions to be made without stopping the
test case when they're violated, leading to multiple TestFailures. For Java,
multiple TestFailures are used to represent a chained exception.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->failure_message() >> / C<< $msg->failure_message($value) >>

Type: C<String>

The exception message reported in the message attribute. Typically short,
but may be multi-line. Eg. "Expected 'foo' but was 'bar'".

=item * C<< $msg->exception_type() >> / C<< $msg->exception_type($value) >>

Type: C<String>

The type of the exception being thrown, reported in the type attribute.
Eg: "org.junit.ComparisonFailure"

=item * C<< $msg->stack_trace() >> / C<< $msg->stack_trace($value) >>

Type: C<String>

The stack trace reported as the content of the <failure> element, often in
a CDATA block. This contains one line for each stack frame, each including
a method/function name, a class/file name, and a line number. Most recent
call is usually first, but not for Python stack traces. May contain the
exception_type and message.

=item * C<< $msg->expected() >> / C<< $msg->expected($value) >>

Type: C<String>

The expected values.

These values can be diffed against the actual values. Often, there is just
one actual and one expected value. If there is more than one, they should
be compared as an unordered collection.

=item * C<< $msg->actual() >> / C<< $msg->actual($value) >>

Type: C<String>

The actual values.

These values can be diffed against the expected values. Often, there is
just one actual and one expected value. If there is more than one, they
should be compared as an unordered collection.

=back

=head2 Google::Devtools::Resultstore::V2::TestSuite::TestError

Represents an exception that prevented a test case from completing, as
reported in an <error> element within a <testcase>. For Java, multiple
TestErrors are used to represent a chained exception.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The exception message, as reported in the message attribute. Typically
short, but may be multi-line. Eg. "argument cannot be null".

=item * C<< $msg->exception_type() >> / C<< $msg->exception_type($value) >>

Type: C<String>

The type of the exception being thrown, reported in the type attribute.
For Java, this is a fully qualified Throwable class name.
Eg: "java.lang.IllegalArgumentException"

=item * C<< $msg->stack_trace() >> / C<< $msg->stack_trace($value) >>

Type: C<String>

The stack trace reported as the content of the <error> element, often in
a CDATA block. This contains one line for each stack frame, each including
a method/function name, a class/file name, and a line number. Most recent
call is usually first, but not for Python stack traces. May contain the
exception_type and message.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::TestSuite::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
