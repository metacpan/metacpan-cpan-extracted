package Google::Cloud::Video::Stitcher::V1::LiveConfigs;

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
    eval { require Google::Cloud::Video::Stitcher::V1::FetchOptions };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvbGl2ZV9jb25maWdzLnByb3RvEh5n
b29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdvb2dsZS9jbG91ZC92aWRl
by9zdGl0Y2hlci92MS9mZXRjaF9vcHRpb25zLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVy
YXRpb24ucHJvdG8i2gcKCkxpdmVDb25maWcSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEiIK
CnNvdXJjZV91cmkYAiABKAlCA+BBAlIJc291cmNlVXJpEhwKCmFkX3RhZ191cmkYAyABKAlS
CGFkVGFnVXJpElUKD2dhbV9saXZlX2NvbmZpZxgEIAEoCzItLmdvb2dsZS5jbG91ZC52aWRl
by5zdGl0Y2hlci52MS5HYW1MaXZlQ29uZmlnUg1nYW1MaXZlQ29uZmlnEksKBXN0YXRlGAUg
ASgOMjAuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLkxpdmVDb25maWcuU3RhdGVC
A+BBA1IFc3RhdGUSUAoLYWRfdHJhY2tpbmcYBiABKA4yKi5nb29nbGUuY2xvdWQudmlkZW8u
c3RpdGNoZXIudjEuQWRUcmFja2luZ0ID4EECUgphZFRyYWNraW5nEkwKDWRlZmF1bHRfc2xh
dGUYByABKAlCJ/pBJAoidmlkZW9zdGl0Y2hlci5nb29nbGVhcGlzLmNvbS9TbGF0ZVIMZGVm
YXVsdFNsYXRlEmUKEHN0aXRjaGluZ19wb2xpY3kYCCABKA4yOi5nb29nbGUuY2xvdWQudmlk
ZW8uc3RpdGNoZXIudjEuTGl2ZUNvbmZpZy5TdGl0Y2hpbmdQb2xpY3lSD3N0aXRjaGluZ1Bv
bGljeRJXCg9wcmVmZXRjaF9jb25maWcYCiABKAsyLi5nb29nbGUuY2xvdWQudmlkZW8uc3Rp
dGNoZXIudjEuUHJlZmV0Y2hDb25maWdSDnByZWZldGNoQ29uZmlnEl4KFHNvdXJjZV9mZXRj
aF9vcHRpb25zGBAgASgLMiwuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLkZldGNo
T3B0aW9uc1ISc291cmNlRmV0Y2hPcHRpb25zIkUKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lG
SUVEEAASDAoIQ1JFQVRJTkcQARIJCgVSRUFEWRACEgwKCERFTEVUSU5HEAMiVQoPU3RpdGNo
aW5nUG9saWN5EiAKHFNUSVRDSElOR19QT0xJQ1lfVU5TUEVDSUZJRUQQABIPCgtDVVRfQ1VS
UkVOVBABEg8KC0NPTVBMRVRFX0FEEAI6b+pBbAondmlkZW9zdGl0Y2hlci5nb29nbGVhcGlz
LmNvbS9MaXZlQ29uZmlnEkFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vbGl2ZUNvbmZpZ3Mve2xpdmVfY29uZmlnfSKJAQoOUHJlZmV0Y2hDb25maWcSHQoHZW5h
YmxlZBgBIAEoCEID4EECUgdlbmFibGVkElgKG2luaXRpYWxfYWRfcmVxdWVzdF9kdXJhdGlv
bhgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIYaW5pdGlhbEFkUmVxdWVzdER1
cmF0aW9uIogBCg1HYW1MaXZlQ29uZmlnEiYKDG5ldHdvcmtfY29kZRgBIAEoCUID4EECUgtu
ZXR3b3JrQ29kZRIgCglhc3NldF9rZXkYAiABKAlCA+BBA1IIYXNzZXRLZXkSLQoQY3VzdG9t
X2Fzc2V0X2tleRgDIAEoCUID4EEDUg5jdXN0b21Bc3NldEtleSpBCgpBZFRyYWNraW5nEhsK
F0FEX1RSQUNLSU5HX1VOU1BFQ0lGSUVEEAASCgoGQ0xJRU5UEAESCgoGU0VSVkVSEAJCeAoi
Y29tLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MUIQTGl2ZUNvbmZpZ3NQcm90b1AB
Wj5jbG91ZC5nb29nbGUuY29tL2dvL3ZpZGVvL3N0aXRjaGVyL2FwaXYxL3N0aXRjaGVycGI7
c3RpdGNoZXJwYkq+JwoHEgUOAI0BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAPAoJCgIDAxID
FQAoCggKAQgSAxcAVQoJCgIICxIDFwBVCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkA
MQoJCgIICBIDGQAxCggKAQgSAxoAOwoJCgIIARIDGgA7CjAKAgUAEgQdACgBGiQgRGV0ZXJt
aW5lcyB0aGUgYWQgdHJhY2tpbmcgcG9saWN5LgoKCgoDBQABEgMdBQ8KNwoEBQACABIDHwIe
GiogVGhlIGFkIHRyYWNraW5nIHBvbGljeSBpcyBub3Qgc3BlY2lmaWVkLgoKDAoFBQACAAES
Ax8CGQoMCgUFAAIAAhIDHxwdCoMBCgQFAAIBEgMjAg0adiBDbGllbnQtc2lkZSBhZCB0cmFj
a2luZyBpcyBzcGVjaWZpZWQuIFRoZSBjbGllbnQgcGxheWVyIGlzIGV4cGVjdGVkIHRvCiB0
cmlnZ2VyIHBsYXliYWNrIGFuZCBhY3Rpdml0eSBldmVudHMgaXRzZWxmLgoKDAoFBQACAQES
AyMCCAoMCgUFAAIBAhIDIwsMCmMKBAUAAgISAycCDRpWIFRoZSBWaWRlbyBTdGl0Y2hlciBB
UEkgd2lsbCB0cmlnZ2VyIHBsYXliYWNrIGV2ZW50cyBvbiBiZWhhbGYgb2YKIHRoZSBjbGll
bnQgcGxheWVyLgoKDAoFBQACAgESAycCCAoMCgUFAAICAhIDJwsMCjkKAgQAEgQrAHMBGi0g
TWV0YWRhdGEgZm9yIHVzZWQgdG8gcmVnaXN0ZXIgbGl2ZSBjb25maWdzLgoKCgoDBAABEgMr
CBIKCwoDBAAHEgQsAi8ECg0KBQQAB50IEgQsAi8ECikKBAQABAASBDICPgMaGyBTdGF0ZSBv
ZiB0aGUgbGl2ZSBjb25maWcuCgoMCgUEAAQAARIDMgcMCigKBgQABAACABIDNAQaGhkgU3Rh
dGUgaXMgbm90IHNwZWNpZmllZC4KCg4KBwQABAACAAESAzQEFQoOCgcEAAQAAgACEgM0GBkK
LgoGBAAEAAIBEgM3BBEaHyBMaXZlIGNvbmZpZyBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAE
AAIBARIDNwQMCg4KBwQABAACAQISAzcPEAouCgYEAAQAAgISAzoEDhofIExpdmUgY29uZmln
IGlzIHJlYWR5IGZvciB1c2UuCgoOCgcEAAQAAgIBEgM6BAkKDgoHBAAEAAICAhIDOgwNCjcK
BgQABAACAxIDPQQRGiggTGl2ZSBjb25maWcgaXMgcXVldWVkIHVwIGZvciBkZWxldGlvbi4K
Cg4KBwQABAACAwESAz0EDAoOCgcEAAQAAgMCEgM9DxAKsQEKBAQABAESBEMCTAMaogEgRGVm
aW5lcyB0aGUgYWQgc3RpdGNoaW5nIGJlaGF2aW9yIGluIGNhc2UgdGhlIGFkIGR1cmF0aW9u
IGRvZXMgbm90IGFsaWduCiBleGFjdGx5IHdpdGggdGhlIGFkIGJyZWFrIGJvdW5kYXJpZXMu
IElmIG5vdCBzcGVjaWZpZWQsIHRoZSBkZWZhdWx0IGlzCiBgQ1VUX0NVUlJFTlRgLgoKDAoF
BAAEAQESA0MHFgozCgYEAAQBAgASA0UEJRokIFN0aXRjaGluZyBwb2xpY3kgaXMgbm90IHNw
ZWNpZmllZC4KCg4KBwQABAECAAESA0UEIAoOCgcEAAQBAgACEgNFIyQKUQoGBAAEAQIBEgNI
BBQaQiBDdXRzIGFuIGFkIHNob3J0IGFuZCByZXR1cm5zIHRvIGNvbnRlbnQgaW4gdGhlIG1p
ZGRsZSBvZiB0aGUgYWQuCgoOCgcEAAQBAgEBEgNIBA8KDgoHBAAEAQIBAhIDSBITCk8KBgQA
BAECAhIDSwQUGkAgRmluaXNoZXMgc3RpdGNoaW5nIHRoZSBjdXJyZW50IGFkIGJlZm9yZSBy
ZXR1cm5pbmcgdG8gY29udGVudC4KCg4KBwQABAECAgESA0sEDwoOCgcEAAQBAgICEgNLEhMK
jgEKBAQAAgASA1ACPhqAASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IGxpdmUgY29uZmlnLCBpbiB0aGUgZm9ybSBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9saXZlQ29uZmlncy97aWR9YC4KCgwKBQQAAgAFEgNQAggKDAoF
BAACAAESA1AJDQoMCgUEAAIAAxIDUBARCgwKBQQAAgAIEgNQEj0KDwoIBAACAAicCAASA1AT
PApBCgQEAAIBEgNTAkEaNCBSZXF1aXJlZC4gU291cmNlIFVSSSBmb3IgdGhlIGxpdmUgc3Ry
ZWFtIG1hbmlmZXN0LgoKDAoFBAACAQUSA1MCCAoMCgUEAAIBARIDUwkTCgwKBQQAAgEDEgNT
FhcKDAoFBAACAQgSA1MYQAoPCggEAAIBCJwIABIDUxk/CkoKBAQAAgISA1YCGBo9IFRoZSBk
ZWZhdWx0IGFkIHRhZyBhc3NvY2lhdGVkIHdpdGggdGhpcyBsaXZlIHN0cmVhbSBjb25maWcu
CgoMCgUEAAICBRIDVgIICgwKBQQAAgIBEgNWCRMKDAoFBAACAgMSA1YWFwpfCgQEAAIDEgNa
AiQaUiBBZGRpdGlvbmFsIG1ldGFkYXRhIHVzZWQgdG8gcmVnaXN0ZXIgYSBsaXZlIHN0cmVh
bSB3aXRoIEdvb2dsZSBBZCBNYW5hZ2VyCiAoR0FNKQoKDAoFBAACAwYSA1oCDwoMCgUEAAID
ARIDWhAfCgwKBQQAAgMDEgNaIiMKNQoEBAACBBIDXQI+GiggT3V0cHV0IG9ubHkuIFN0YXRl
IG9mIHRoZSBsaXZlIGNvbmZpZy4KCgwKBQQAAgQGEgNdAgcKDAoFBAACBAESA10IDQoMCgUE
AAIEAxIDXRARCgwKBQQAAgQIEgNdEj0KDwoIBAACBAicCAASA10TPAo8CgQEAAIFEgNgAkYa
LyBSZXF1aXJlZC4gRGV0ZXJtaW5lcyBob3cgdGhlIGFkcyBhcmUgdHJhY2tlZC4KCgwKBQQA
AgUGEgNgAgwKDAoFBAACBQESA2ANGAoMCgUEAAIFAxIDYBscCgwKBQQAAgUIEgNgHUUKDwoI
BAACBQicCAASA2AeRAqYAgoEBAACBhIEZgJoBRqJAiBUaGlzIG11c3QgcmVmZXIgdG8gYSBz
bGF0ZSBpbiB0aGUgc2FtZQogcHJvamVjdC4gSWYgR29vZ2xlIEFkIE1hbmFnZXIgKEdBTSkg
aXMgdXNlZCBmb3IgYWRzLCB0aGlzIHN0cmluZyBzZXRzIHRoZQogdmFsdWUgb2YgYHNsYXRl
Q3JlYXRpdmVJZGAgaW4KIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2FkLW1hbmFn
ZXIvYXBpL3JlZmVyZW5jZS92MjAyMjExL0xpdmVTdHJlYW1FdmVudFNlcnZpY2UuTGl2ZVN0
cmVhbUV2ZW50I3NsYXRlQ3JlYXRpdmVJZAoKDAoFBAACBgUSA2YCCAoMCgUEAAIGARIDZgkW
CgwKBQQAAgYDEgNmGRoKDQoFBAACBggSBGYbaAQKDwoHBAACBgifCBIEZhxoAwqhAQoEBAAC
BxIDbAInGpMBIERlZmluZXMgdGhlIHN0aXRjaGVyIGJlaGF2aW9yIGluIGNhc2UgYW4gYWQg
ZG9lcyBub3QgYWxpZ24gZXhhY3RseSB3aXRoCiB0aGUgYWQgYnJlYWsgYm91bmRhcmllcy4g
SWYgbm90IHNwZWNpZmllZCwgdGhlIGRlZmF1bHQgaXMgYENVVF9DVVJSRU5UYC4KCgwKBQQA
AgcGEgNsAhEKDAoFBAACBwESA2wSIgoMCgUEAAIHAxIDbCUmCjUKBAQAAggSA28CJhooIFRo
ZSBjb25maWd1cmF0aW9uIGZvciBwcmVmZXRjaGluZyBhZHMuCgoMCgUEAAIIBhIDbwIQCgwK
BQQAAggBEgNvESAKDAoFBAACCAMSA28jJQpCCgQEAAIJEgNyAikaNSBPcHRpb25zIGZvciBm
ZXRjaGluZyBzb3VyY2UgbWFuaWZlc3RzIGFuZCBzZWdtZW50cy4KCgwKBQQAAgkGEgNyAg4K
DAoFBAACCQESA3IPIwoMCgUEAAIJAxIDciYoCjIKAgQBEgV2AIEBARolIFRoZSBjb25maWd1
cmF0aW9uIGZvciBwcmVmZXRjaCBhZHMuCgoKCgMEAQESA3YIFgpZCgQEAQIAEgN4AjwaTCBS
ZXF1aXJlZC4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIG9wdGlvbiB0byBwcmVmZXRjaCBhZCBy
ZXF1ZXN0cyBpcyBlbmFibGVkLgoKDAoFBAECAAUSA3gCBgoMCgUEAQIAARIDeAcOCgwKBQQB
AgADEgN4ERIKDAoFBAECAAgSA3gTOwoPCggEAQIACJwIABIDeBQ6CoIDCgQEAQIBEgSAAQI7
GvMCIFRoZSBkdXJhdGlvbiBpbiBzZWNvbmRzIG9mIHRoZSBwYXJ0IG9mIHRoZSBicmVhayB0
byBiZSBwcmVmZXRjaGVkLgogVGhpcyBmaWVsZCBpcyBvbmx5IHJlbGV2YW50IGlmIHByZWZl
dGNoIGlzIGVuYWJsZWQuCiBZb3Ugc2hvdWxkIHNldCB0aGlzIGR1cmF0aW9uIHRvIGFzIGxv
bmcgYXMgcG9zc2libGUgdG8gaW5jcmVhc2UgdGhlCiBiZW5lZml0cyBvZiBwcmVmZXRjaGlu
ZywgYnV0IG5vdCBsb25nZXIgdGhhbiB0aGUgc2hvcnRlc3QgYWQgYnJlYWsKIGV4cGVjdGVk
LiBGb3IgZXhhbXBsZSwgZm9yIGEgbGl2ZSBldmVudCB3aXRoIDMwcyBhbmQgNjBzIGFkIGJy
ZWFrcywgdGhlCiBpbml0aWFsIGR1cmF0aW9uIHNob3VsZCBiZSBzZXQgdG8gMzBzLgoKDQoF
BAECAQYSBIABAhoKDQoFBAECAQESBIABGzYKDQoFBAECAQMSBIABOToKVAoCBAISBoQBAI0B
ARpGIE1ldGFkYXRhIHVzZWQgdG8gcmVnaXN0ZXIgYSBsaXZlIHN0cmVhbSB3aXRoIEdvb2ds
ZSBBZCBNYW5hZ2VyIChHQU0pCgoLCgMEAgESBIQBCBUKVAoEBAICABIEhgECQxpGIFJlcXVp
cmVkLiBBZCBNYW5hZ2VyIG5ldHdvcmsgY29kZSB0byBhc3NvY2lhdGUgd2l0aCB0aGUgbGl2
ZSBjb25maWcuCgoNCgUEAgIABRIEhgECCAoNCgUEAgIAARIEhgEJFQoNCgUEAgIAAxIEhgEY
GQoNCgUEAgIACBIEhgEaQgoQCggEAgIACJwIABIEhgEbQQpUCgQEAgIBEgSJAQJDGkYgT3V0
cHV0IG9ubHkuIFRoZSBhc3NldCBrZXkgaWRlbnRpZmllciBnZW5lcmF0ZWQgZm9yIHRoZSBs
aXZlIGNvbmZpZy4KCg0KBQQCAgEFEgSJAQIICg0KBQQCAgEBEgSJAQkSCg0KBQQCAgEDEgSJ
ARUWCg0KBQQCAgEIEgSJARdCChAKCAQCAgEInAgAEgSJARhBClsKBAQCAgISBIwBAkoaTSBP
dXRwdXQgb25seS4gVGhlIGN1c3RvbSBhc3NldCBrZXkgaWRlbnRpZmllciBnZW5lcmF0ZWQg
Zm9yIHRoZSBsaXZlIGNvbmZpZy4KCg0KBQQCAgIFEgSMAQIICg0KBQQCAgIBEgSMAQkZCg0K
BQQCAgIDEgSMARwdCg0KBQQCAgIIEgSMAR5JChAKCAQCAgIInAgAEgSMAR9IYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig ===
    # Fields for LiveConfig
    # Field: name Type: 9 ()
    # Field: source_uri Type: 9 ()
    # Field: ad_tag_uri Type: 9 ()
    # Field: gam_live_config Type: 11 (.google.cloud.video.stitcher.v1.GamLiveConfig)
    # Field: state Type: 14 (.google.cloud.video.stitcher.v1.LiveConfig.State)
    # Field: ad_tracking Type: 14 (.google.cloud.video.stitcher.v1.AdTracking)
    # Field: default_slate Type: 9 ()
    # Field: stitching_policy Type: 14 (.google.cloud.video.stitcher.v1.LiveConfig.StitchingPolicy)
    # Field: prefetch_config Type: 11 (.google.cloud.video.stitcher.v1.PrefetchConfig)
    # Field: source_fetch_options Type: 11 (.google.cloud.video.stitcher.v1.FetchOptions)

# Enum: LiveConfig::State
our $LiveConfig_STATE_UNSPECIFIED = 0;
our $LiveConfig_CREATING = 1;
our $LiveConfig_READY = 2;
our $LiveConfig_DELETING = 3;

# Enum: LiveConfig::StitchingPolicy
our $LiveConfig_STITCHING_POLICY_UNSPECIFIED = 0;
our $LiveConfig_CUT_CURRENT = 1;
our $LiveConfig_COMPLETE_AD = 2;

# === Message: Google::Cloud::Video::Stitcher::V1::LiveConfigs::PrefetchConfig ===
    # Fields for PrefetchConfig
    # Field: enabled Type: 8 ()
    # Field: initial_ad_request_duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Video::Stitcher::V1::LiveConfigs::GamLiveConfig ===
    # Fields for GamLiveConfig
    # Field: network_code Type: 9 ()
    # Field: asset_key Type: 9 ()
    # Field: custom_asset_key Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::LiveConfigs - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/live_configs.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::LiveConfigs;

    my $msg = Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig->new({
        name => $name,
        source_uri => $source_uri,
        ad_tag_uri => $ad_tag_uri,
        gam_live_config => $gam_live_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/live_configs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig

Metadata for used to register live configs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the live config, in the form of
`projects/{project}/locations/{location}/liveConfigs/{id}`.

=item * C<< $msg->source_uri() >> / C<< $msg->source_uri($value) >>

Type: C<String>

Required. Source URI for the live stream manifest.

=item * C<< $msg->ad_tag_uri() >> / C<< $msg->ad_tag_uri($value) >>

Type: C<String>

The default ad tag associated with this live stream config.

=item * C<< $msg->gam_live_config() >> / C<< $msg->gam_live_config($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::LiveConfigs::GamLiveConfig>)

Additional metadata used to register a live stream with Google Ad Manager
(GAM)

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::LiveConfig::State>)

Output only. State of the live config.

=item * C<< $msg->ad_tracking() >> / C<< $msg->ad_tracking($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::AdTracking>)

Required. Determines how the ads are tracked.

=item * C<< $msg->default_slate() >> / C<< $msg->default_slate($value) >>

Type: C<String>

This must refer to a slate in the same
project. If Google Ad Manager (GAM) is used for ads, this string sets the
value of `slateCreativeId` in
https://developers.google.com/ad-manager/api/reference/v202211/LiveStreamEventService.LiveStreamEvent#slateCreativeId

=item * C<< $msg->stitching_policy() >> / C<< $msg->stitching_policy($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::LiveConfig::StitchingPolicy>)

Defines the stitcher behavior in case an ad does not align exactly with
the ad break boundaries. If not specified, the default is `CUT_CURRENT`.

=item * C<< $msg->prefetch_config() >> / C<< $msg->prefetch_config($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::LiveConfigs::PrefetchConfig>)

The configuration for prefetching ads.

=item * C<< $msg->source_fetch_options() >> / C<< $msg->source_fetch_options($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions>)

Options for fetching source manifests and segments.

=back

=head3 Enum: LiveConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=back

=head3 Enum: LiveConfig::StitchingPolicy

=over 4

=item * C<STITCHING_POLICY_UNSPECIFIED> => C<0>

=item * C<CUT_CURRENT> => C<1>

=item * C<COMPLETE_AD> => C<2>

=back

=head2 Google::Cloud::Video::Stitcher::V1::LiveConfigs::PrefetchConfig

The configuration for prefetch ads.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Required. Indicates whether the option to prefetch ad requests is enabled.

=item * C<< $msg->initial_ad_request_duration() >> / C<< $msg->initial_ad_request_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The duration in seconds of the part of the break to be prefetched.
This field is only relevant if prefetch is enabled.
You should set this duration to as long as possible to increase the
benefits of prefetching, but not longer than the shortest ad break
expected. For example, for a live event with 30s and 60s ad breaks, the
initial duration should be set to 30s.

=back

=head2 Google::Cloud::Video::Stitcher::V1::LiveConfigs::GamLiveConfig

Metadata used to register a live stream with Google Ad Manager (GAM)

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network_code() >> / C<< $msg->network_code($value) >>

Type: C<String>

Required. Ad Manager network code to associate with the live config.

=item * C<< $msg->asset_key() >> / C<< $msg->asset_key($value) >>

Type: C<String>

Output only. The asset key identifier generated for the live config.

=item * C<< $msg->custom_asset_key() >> / C<< $msg->custom_asset_key($value) >>

Type: C<String>

Output only. The custom asset key identifier generated for the live config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::LiveConfigs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
