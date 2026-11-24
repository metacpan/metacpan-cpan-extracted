package Google::Devtools::Artifactregistry::V1beta2::Repository;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3JlcG9zaXRvcnku
cHJvdG8SKGdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
IGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvIsEICgpSZXBvc2l0b3J5Em8KDG1hdmVuX2NvbmZpZxgJIAEoCzJKLmdv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuUmVwb3NpdG9yeS5NYXZl
blJlcG9zaXRvcnlDb25maWdIAFILbWF2ZW5Db25maWcSEgoEbmFtZRgBIAEoCVIEbmFtZRJT
CgZmb3JtYXQYAiABKA4yOy5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJl
dGEyLlJlcG9zaXRvcnkuRm9ybWF0UgZmb3JtYXQSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rl
c2NyaXB0aW9uElgKBmxhYmVscxgEIAMoCzJALmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJl
Z2lzdHJ5LnYxYmV0YTIuUmVwb3NpdG9yeS5MYWJlbHNFbnRyeVIGbGFiZWxzEjsKC2NyZWF0
ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7
Cgt1cGRhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0
ZVRpbWUSIAoMa21zX2tleV9uYW1lGAggASgJUgprbXNLZXlOYW1lGqACChVNYXZlblJlcG9z
aXRvcnlDb25maWcSOgoZYWxsb3dfc25hcHNob3Rfb3ZlcndyaXRlcxgBIAEoCFIXYWxsb3dT
bmFwc2hvdE92ZXJ3cml0ZXMSfwoOdmVyc2lvbl9wb2xpY3kYAiABKA4yWC5nb29nbGUuZGV2
dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLlJlcG9zaXRvcnkuTWF2ZW5SZXBvc2l0
b3J5Q29uZmlnLlZlcnNpb25Qb2xpY3lSDXZlcnNpb25Qb2xpY3kiSgoNVmVyc2lvblBvbGlj
eRIeChpWRVJTSU9OX1BPTElDWV9VTlNQRUNJRklFRBAAEgsKB1JFTEVBU0UQARIMCghTTkFQ
U0hPVBACGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEiXgoGRm9ybWF0EhYKEkZPUk1BVF9VTlNQRUNJRklFRBAAEgoKBkRPQ0tF
UhABEgkKBU1BVkVOEAISBwoDTlBNEAMSBwoDQVBUEAUSBwoDWVVNEAYSCgoGUFlUSE9OEAg6
cupBbwoqYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9SZXBvc2l0b3J5EkFwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBv
c2l0b3J5fUIPCg1mb3JtYXRfY29uZmlnIqEBChdMaXN0UmVwb3NpdG9yaWVzUmVxdWVzdBJK
CgZwYXJlbnQYASABKAlCMuBBAvpBLBIqYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNv
bS9SZXBvc2l0b3J5UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpw
YWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4inAEKGExpc3RSZXBvc2l0b3JpZXNSZXNwb25z
ZRJYCgxyZXBvc2l0b3JpZXMYASADKAsyNC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdp
c3RyeS52MWJldGEyLlJlcG9zaXRvcnlSDHJlcG9zaXRvcmllcxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iXgoUR2V0UmVwb3NpdG9yeVJlcXVlc3QSRgoEbmFt
ZRgBIAEoCUIy4EEC+kEsCiphcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1JlcG9z
aXRvcnlSBG5hbWUi4AEKF0NyZWF0ZVJlcG9zaXRvcnlSZXF1ZXN0EkoKBnBhcmVudBgBIAEo
CUIy4EEC+kEsEiphcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1JlcG9zaXRvcnlS
BnBhcmVudBIjCg1yZXBvc2l0b3J5X2lkGAIgASgJUgxyZXBvc2l0b3J5SWQSVAoKcmVwb3Np
dG9yeRgDIAEoCzI0Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIu
UmVwb3NpdG9yeVIKcmVwb3NpdG9yeSKsAQoXVXBkYXRlUmVwb3NpdG9yeVJlcXVlc3QSVAoK
cmVwb3NpdG9yeRgBIAEoCzI0Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYx
YmV0YTIuUmVwb3NpdG9yeVIKcmVwb3NpdG9yeRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siYQoXRGVsZXRlUmVwb3NpdG9y
eVJlcXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCiphcnRpZmFjdHJlZ2lzdHJ5Lmdvb2ds
ZWFwaXMuY29tL1JlcG9zaXRvcnlSBG5hbWVCkwIKLGNvbS5nb29nbGUuZGV2dG9vbHMuYXJ0
aWZhY3RyZWdpc3RyeS52MWJldGEyQg9SZXBvc2l0b3J5UHJvdG9QAVpVY2xvdWQuZ29vZ2xl
LmNvbS9nby9hcnRpZmFjdHJlZ2lzdHJ5L2FwaXYxYmV0YTIvYXJ0aWZhY3RyZWdpc3RyeXBi
O2FydGlmYWN0cmVnaXN0cnlwYqoCJUdvb2dsZS5DbG91ZC5BcnRpZmFjdFJlZ2lzdHJ5LlYx
QmV0YTLKAiVHb29nbGVcQ2xvdWRcQXJ0aWZhY3RSZWdpc3RyeVxWMWJldGEy6gIoR29vZ2xl
OjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFiZXRhMkqFMAoHEgUOAMgBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgApCgkKAgMB
EgMTACMKCQoCAwISAxQAKgoJCgIDAxIDFQApCggKAQgSAxcAQgoJCgIIJRIDFwBCCggKAQgS
AxgAbAoJCgIICxIDGABsCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMAoJCgIICBID
GgAwCggKAQgSAxsARQoJCgIIARIDGwBFCggKAQgSAxwAQgoJCgIIKRIDHABCCggKAQgSAx0A
QQoJCgIILRIDHQBBCkgKAgQAEgQgAHsBGjwgQSBSZXBvc2l0b3J5IGZvciBzdG9yaW5nIGFy
dGlmYWN0cyB3aXRoIGEgc3BlY2lmaWMgZm9ybWF0LgoKCgoDBAABEgMgCBIKCwoDBAAHEgQh
AiQECg0KBQQAB50IEgQhAiQECqIBCgQEAAMAEgQpAj4DGpMBIE1hdmVuUmVwb3NpdG9yeUNv
bmZpZyBpcyBtYXZlbiByZWxhdGVkIHJlcG9zaXRvcnkgZGV0YWlscy4KIFByb3ZpZGVzIGFk
ZGl0aW9uYWwgY29uZmlndXJhdGlvbiBkZXRhaWxzIGZvciByZXBvc2l0b3JpZXMgb2YgdGhl
IG1hdmVuCiBmb3JtYXQgdHlwZS4KCgwKBQQAAwABEgMpCh8KSQoGBAADAAQAEgQrBDYFGjkg
VmVyc2lvblBvbGljeSBpcyB0aGUgdmVyc2lvbiBwb2xpY3kgZm9yIHRoZSByZXBvc2l0b3J5
LgoKDgoHBAADAAQAARIDKwkWCqoBCggEAAMABAACABIDLwYlGpgBIFZFUlNJT05fUE9MSUNZ
X1VOU1BFQ0lGSUVEIC0gdGhlIHZlcnNpb24gcG9saWN5IGlzIG5vdCBkZWZpbmVkLgogV2hl
biB0aGUgdmVyc2lvbiBwb2xpY3kgaXMgbm90IGRlZmluZWQsIG5vIHZhbGlkYXRpb24gaXMg
cGVyZm9ybWVkCiBmb3IgdGhlIHZlcnNpb25zLgoKEAoJBAADAAQAAgABEgMvBiAKEAoJBAAD
AAQAAgACEgMvIyQKSgoIBAADAAQAAgESAzIGEho5IFJFTEVBU0UgLSByZXBvc2l0b3J5IHdp
bGwgYWNjZXB0IG9ubHkgUmVsZWFzZSB2ZXJzaW9ucy4KChAKCQQAAwAEAAIBARIDMgYNChAK
CQQAAwAEAAIBAhIDMhARCkwKCAQAAwAEAAICEgM1BhMaOyBTTkFQU0hPVCAtIHJlcG9zaXRv
cnkgd2lsbCBhY2NlcHQgb25seSBTbmFwc2hvdCB2ZXJzaW9ucy4KChAKCQQAAwAEAAICARID
NQYOChAKCQQAAwAEAAICAhIDNRESCmEKBgQAAwACABIDOgQnGlIgVGhlIHJlcG9zaXRvcnkg
d2l0aCB0aGlzIGZsYWcgd2lsbCBhbGxvdyBwdWJsaXNoaW5nCiB0aGUgc2FtZSBzbmFwc2hv
dCB2ZXJzaW9ucy4KCg4KBwQAAwACAAUSAzoECAoOCgcEAAMAAgABEgM6CSIKDgoHBAADAAIA
AxIDOiUmClMKBgQAAwACARIDPQQlGkQgVmVyc2lvbiBwb2xpY3kgZGVmaW5lcyB0aGUgdmVy
c2lvbnMgdGhhdCB0aGUgcmVnaXN0cnkgd2lsbCBhY2NlcHQuCgoOCgcEAAMAAgEGEgM9BBEK
DgoHBAADAAIBARIDPRIgCg4KBwQAAwACAQMSAz0jJAohCgQEAAQAEgRBAlYDGhMgQSBwYWNr
YWdlIGZvcm1hdC4KCgwKBQQABAABEgNBBw0KLAoGBAAEAAIAEgNDBBsaHSBVbnNwZWNpZmll
ZCBwYWNrYWdlIGZvcm1hdC4KCg4KBwQABAACAAESA0MEFgoOCgcEAAQAAgACEgNDGRoKJwoG
BAAEAAIBEgNGBA8aGCBEb2NrZXIgcGFja2FnZSBmb3JtYXQuCgoOCgcEAAQAAgEBEgNGBAoK
DgoHBAAEAAIBAhIDRg0OCiYKBgQABAACAhIDSQQOGhcgTWF2ZW4gcGFja2FnZSBmb3JtYXQu
CgoOCgcEAAQAAgIBEgNJBAkKDgoHBAAEAAICAhIDSQwNCiQKBgQABAACAxIDTAQMGhUgTlBN
IHBhY2thZ2UgZm9ybWF0LgoKDgoHBAAEAAIDARIDTAQHCg4KBwQABAACAwISA0wKCwokCgYE
AAQAAgQSA08EDBoVIEFQVCBwYWNrYWdlIGZvcm1hdC4KCg4KBwQABAACBAESA08EBwoOCgcE
AAQAAgQCEgNPCgsKJAoGBAAEAAIFEgNSBAwaFSBZVU0gcGFja2FnZSBmb3JtYXQuCgoOCgcE
AAQAAgUBEgNSBAcKDgoHBAAEAAIFAhIDUgoLCicKBgQABAACBhIDVQQPGhggUHl0aG9uIHBh
Y2thZ2UgZm9ybWF0LgoKDgoHBAAEAAIGARIDVQQKCg4KBwQABAACBgISA1UNDgozCgQEAAgA
EgRZAl0DGiUgUmVwb3NpdG9yeS1zcGVjaWZpYyBjb25maWd1cmF0aW9ucy4KCgwKBQQACAAB
EgNZCBUKcwoEBAACABIDXAQrGmYgTWF2ZW4gcmVwb3NpdG9yeSBjb25maWcgY29udGFpbnMg
cmVwb3NpdG9yeSBsZXZlbCBjb25maWd1cmF0aW9uCiBmb3IgdGhlIHJlcG9zaXRvcmllcyBv
ZiBtYXZlbiB0eXBlLgoKDAoFBAACAAYSA1wEGQoMCgUEAAIAARIDXBomCgwKBQQAAgADEgNc
KSoKcAoEBAACARIDYQISGmMgVGhlIG5hbWUgb2YgdGhlIHJlcG9zaXRvcnksIGZvciBleGFt
cGxlOgogInByb2plY3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMv
cmVwbzEiLgoKDAoFBAACAQUSA2ECCAoMCgUEAAIBARIDYQkNCgwKBQQAAgEDEgNhEBEKSAoE
BAACAhIDZAIUGjsgVGhlIGZvcm1hdCBvZiBwYWNrYWdlcyB0aGF0IGFyZSBzdG9yZWQgaW4g
dGhlIHJlcG9zaXRvcnkuCgoMCgUEAAICBhIDZAIICgwKBQQAAgIBEgNkCQ8KDAoFBAACAgMS
A2QSEwo/CgQEAAIDEgNnAhkaMiBUaGUgdXNlci1wcm92aWRlZCBkZXNjcmlwdGlvbiBvZiB0
aGUgcmVwb3NpdG9yeS4KCgwKBQQAAgMFEgNnAggKDAoFBAACAwESA2cJFAoMCgUEAAIDAxID
ZxcYCp0CCgQEAAIEEgNuAiEajwIgTGFiZWxzIHdpdGggdXNlci1kZWZpbmVkIG1ldGFkYXRh
LgogVGhpcyBmaWVsZCBtYXkgY29udGFpbiB1cCB0byA2NCBlbnRyaWVzLiBMYWJlbCBrZXlz
IGFuZCB2YWx1ZXMgbWF5IGJlIG5vCiBsb25nZXIgdGhhbiA2MyBjaGFyYWN0ZXJzLiBMYWJl
bCBrZXlzIG11c3QgYmVnaW4gd2l0aCBhIGxvd2VyY2FzZSBsZXR0ZXIKIGFuZCBtYXkgb25s
eSBjb250YWluIGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1lcmljIGNoYXJhY3RlcnMsIHVuZGVy
c2NvcmVzLAogYW5kIGRhc2hlcy4KCgwKBQQAAgQGEgNuAhUKDAoFBAACBAESA24WHAoMCgUE
AAIEAxIDbh8gCjgKBAQAAgUSA3ECLBorIFRoZSB0aW1lIHdoZW4gdGhlIHJlcG9zaXRvcnkg
d2FzIGNyZWF0ZWQuCgoMCgUEAAIFBhIDcQIbCgwKBQQAAgUBEgNxHCcKDAoFBAACBQMSA3Eq
Kwo9CgQEAAIGEgN0AiwaMCBUaGUgdGltZSB3aGVuIHRoZSByZXBvc2l0b3J5IHdhcyBsYXN0
IHVwZGF0ZWQuCgoMCgUEAAIGBhIDdAIbCgwKBQQAAgYBEgN0HCcKDAoFBAACBgMSA3QqKwqt
AgoEBAACBxIDegIaGp8CIFRoZSBDbG91ZCBLTVMgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY3Vz
dG9tZXIgbWFuYWdlZCBlbmNyeXB0aW9uIGtleSB0aGF04oCZcwogdXNlZCB0byBlbmNyeXB0
IHRoZSBjb250ZW50cyBvZiB0aGUgUmVwb3NpdG9yeS4gSGFzIHRoZSBmb3JtOgogYHByb2pl
Y3RzL215LXByb2plY3QvbG9jYXRpb25zL215LXJlZ2lvbi9rZXlSaW5ncy9teS1rci9jcnlw
dG9LZXlzL215LWtleWAuCiBUaGlzIHZhbHVlIG1heSBub3QgYmUgY2hhbmdlZCBhZnRlciB0
aGUgUmVwb3NpdG9yeSBoYXMgYmVlbiBjcmVhdGVkLgoKDAoFBAACBwUSA3oCCAoMCgUEAAIH
ARIDegkVCgwKBQQAAgcDEgN6GBkKMAoCBAESBX4AjAEBGiMgVGhlIHJlcXVlc3QgdG8gbGlz
dCByZXBvc2l0b3JpZXMuCgoKCgMEAQESA34IHwpeCgQEAQIAEgaAAQKFAQQaTiBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZSB3aG9zZSByZXBvc2l0b3JpZXMg
d2lsbCBiZSBsaXN0ZWQuCgoNCgUEAQIABRIEgAECCAoNCgUEAQIAARIEgAEJDwoNCgUEAQIA
AxIEgAESEwoPCgUEAQIACBIGgAEUhQEDChAKCAQBAgAInAgAEgSBAQQqChEKBwQBAgAInwgS
BoIBBIQBBQpZCgQEAQIBEgSIAQIWGksgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlcG9zaXRv
cmllcyB0byByZXR1cm4uIE1heGltdW0gcGFnZSBzaXplIGlzIDEsMDAwLgoKDQoFBAECAQUS
BIgBAgcKDQoFBAECAQESBIgBCBEKDQoFBAECAQMSBIgBFBUKWAoEBAECAhIEiwECGBpKIFRo
ZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxpc3Qg
cmVxdWVzdCwgaWYgYW55LgoKDQoFBAECAgUSBIsBAggKDQoFBAECAgESBIsBCRMKDQoFBAEC
AgMSBIsBFhcKNwoCBAISBo8BAJYBARopIFRoZSByZXNwb25zZSBmcm9tIGxpc3RpbmcgcmVw
b3NpdG9yaWVzLgoKCwoDBAIBEgSPAQggCioKBAQCAgASBJEBAicaHCBUaGUgcmVwb3NpdG9y
aWVzIHJldHVybmVkLgoKDQoFBAICAAQSBJEBAgoKDQoFBAICAAYSBJEBCxUKDQoFBAICAAES
BJEBFiIKDQoFBAICAAMSBJEBJSYKewoEBAICARIElQECHRptIFRoZSB0b2tlbiB0byByZXRy
aWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlcG9zaXRvcmllcywgb3IgZW1wdHkgaWYgdGhlcmUg
YXJlCiBubyBtb3JlIHJlcG9zaXRvcmllcyB0byByZXR1cm4uCgoNCgUEAgIBBRIElQECCAoN
CgUEAgIBARIElQEJGAoNCgUEAgIBAxIElQEbHAo1CgIEAxIGmQEAoQEBGicgVGhlIHJlcXVl
c3QgdG8gcmV0cmlldmUgYSByZXBvc2l0b3J5LgoKCwoDBAMBEgSZAQgcCkMKBAQDAgASBpsB
AqABBBozIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcmVwb3NpdG9yeSB0byByZXRyaWV2
ZS4KCg0KBQQDAgAFEgSbAQIICg0KBQQDAgABEgSbAQkNCg0KBQQDAgADEgSbARARCg8KBQQD
AgAIEgabARKgAQMKEAoIBAMCAAicCAASBJwBBCoKEQoHBAMCAAifCBIGnQEEnwEFCjcKAgQE
EgakAQCyAQEaKSBUaGUgcmVxdWVzdCB0byBjcmVhdGUgYSBuZXcgcmVwb3NpdG9yeS4KCgsK
AwQEARIEpAEIHwphCgQEBAIAEgamAQKrAQQaUSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IHBhcmVudCByZXNvdXJjZSB3aGVyZSB0aGUgcmVwb3NpdG9yeSB3aWxsIGJlIGNyZWF0ZWQu
CgoNCgUEBAIABRIEpgECCAoNCgUEBAIAARIEpgEJDwoNCgUEBAIAAxIEpgESEwoPCgUEBAIA
CBIGpgEUqwEDChAKCAQEAgAInAgAEgSnAQQqChEKBwQEAgAInwgSBqgBBKoBBQo9CgQEBAIB
EgSuAQIbGi8gVGhlIHJlcG9zaXRvcnkgaWQgdG8gdXNlIGZvciB0aGlzIHJlcG9zaXRvcnku
CgoNCgUEBAIBBRIErgECCAoNCgUEBAIBARIErgEJFgoNCgUEBAIBAxIErgEZGgotCgQEBAIC
EgSxAQIcGh8gVGhlIHJlcG9zaXRvcnkgdG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgSxAQIM
Cg0KBQQEAgIBEgSxAQ0XCg0KBQQEAgIDEgSxARobCjMKAgQFEga1AQC9AQEaJSBUaGUgcmVx
dWVzdCB0byB1cGRhdGUgYSByZXBvc2l0b3J5LgoKCwoDBAUBEgS1AQgfCkgKBAQFAgASBLcB
AhwaOiBUaGUgcmVwb3NpdG9yeSB0aGF0IHJlcGxhY2VzIHRoZSByZXNvdXJjZSBvbiB0aGUg
c2VydmVyLgoKDQoFBAUCAAYSBLcBAgwKDQoFBAUCAAESBLcBDRcKDQoFBAUCAAMSBLcBGhsK
twEKBAQFAgESBLwBAiwaqAEgVGhlIHVwZGF0ZSBtYXNrIGFwcGxpZXMgdG8gdGhlIHJlc291
cmNlLiBGb3IgdGhlIGBGaWVsZE1hc2tgIGRlZmluaXRpb24sCiBzZWUKIGh0dHBzOi8vZGV2
ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9yZWZlcmVuY2UvZ29v
Z2xlLnByb3RvYnVmI2ZpZWxkbWFzawoKDQoFBAUCAQYSBLwBAhsKDQoFBAUCAQESBLwBHCcK
DQoFBAUCAQMSBLwBKisKMwoCBAYSBsABAMgBARolIFRoZSByZXF1ZXN0IHRvIGRlbGV0ZSBh
IHJlcG9zaXRvcnkuCgoLCgMEBgESBMABCB8KQQoEBAYCABIGwgECxwEEGjEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSByZXBvc2l0b3J5IHRvIGRlbGV0ZS4KCg0KBQQGAgAFEgTCAQII
Cg0KBQQGAgABEgTCAQkNCg0KBQQGAgADEgTCARARCg8KBQQGAgAIEgbCARLHAQMKEAoIBAYC
AAicCAASBMMBBCoKEQoHBAYCAAifCBIGxAEExgEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::Repository ===
    # Fields for Repository
    # Field: maven_config Type: 11 (.google.devtools.artifactregistry.v1beta2.Repository.MavenRepositoryConfig)
    # Field: name Type: 9 ()
    # Field: format Type: 14 (.google.devtools.artifactregistry.v1beta2.Repository.Format)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.devtools.artifactregistry.v1beta2.Repository.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: kms_key_name Type: 9 ()

# Enum: Repository::Format
our $Repository_FORMAT_UNSPECIFIED = 0;
our $Repository_DOCKER = 1;
our $Repository_MAVEN = 2;
our $Repository_NPM = 3;
our $Repository_APT = 5;
our $Repository_YUM = 6;
our $Repository_PYTHON = 8;

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesRequest ===
    # Fields for ListRepositoriesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesResponse ===
    # Fields for ListRepositoriesResponse
    # Field: repositories Type: 11 (.google.devtools.artifactregistry.v1beta2.Repository)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::GetRepositoryRequest ===
    # Fields for GetRepositoryRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::CreateRepositoryRequest ===
    # Fields for CreateRepositoryRequest
    # Field: parent Type: 9 ()
    # Field: repository_id Type: 9 ()
    # Field: repository Type: 11 (.google.devtools.artifactregistry.v1beta2.Repository)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::UpdateRepositoryRequest ===
    # Fields for UpdateRepositoryRequest
    # Field: repository Type: 11 (.google.devtools.artifactregistry.v1beta2.Repository)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Repository::DeleteRepositoryRequest ===
    # Fields for DeleteRepositoryRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Repository - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/repository.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::Repository;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::Repository::Repository->new({
        maven_config => $maven_config,
        name => $name,
        format => $format,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->maven_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::Repository::Repository->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/repository.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::Repository

A Repository for storing artifacts with a specific format.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->maven_config() >> / C<< $msg->maven_config($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::MavenRepositoryConfig>)

Maven repository config contains repository level configuration
for the repositories of maven type.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the repository, for example:
"projects/p1/locations/us-central1/repositories/repo1".

=item * C<< $msg->format() >> / C<< $msg->format($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::Repository::Format>)

The format of packages that are stored in the repository.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The user-provided description of the repository.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::LabelsEntry>)

Labels with user-defined metadata.
This field may contain up to 64 entries. Label keys and values may be no
longer than 63 characters. Label keys must begin with a lowercase letter
and may only contain lowercase letters, numeric characters, underscores,
and dashes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the repository was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the repository was last updated.

=item * C<< $msg->kms_key_name() >> / C<< $msg->kms_key_name($value) >>

Type: C<String>

The Cloud KMS resource name of the customer managed encryption key that’s
used to encrypt the contents of the Repository. Has the form:
`projects/my-project/locations/my-region/keyRings/my-kr/cryptoKeys/my-key`.
This value may not be changed after the Repository has been created.

=back

=head3 Enum: Repository::Format

=over 4

=item * C<FORMAT_UNSPECIFIED> => C<0>

=item * C<DOCKER> => C<1>

=item * C<MAVEN> => C<2>

=item * C<NPM> => C<3>

=item * C<APT> => C<5>

=item * C<YUM> => C<6>

=item * C<PYTHON> => C<8>

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesRequest

The request to list repositories.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose repositories will be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of repositories to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesResponse

The response from listing repositories.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repositories() >> / C<< $msg->repositories($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Repository::Repository>)

The repositories returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of repositories, or empty if there are
no more repositories to return.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::GetRepositoryRequest

The request to retrieve a repository.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the repository to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::CreateRepositoryRequest

The request to create a new repository.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource where the repository will be created.

=item * C<< $msg->repository_id() >> / C<< $msg->repository_id($value) >>

Type: C<String>

The repository id to use for this repository.

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Repository::Repository>)

The repository to be created.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::UpdateRepositoryRequest

The request to update a repository.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Repository::Repository>)

The repository that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Repository::DeleteRepositoryRequest

The request to delete a repository.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the repository to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::Repository::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
