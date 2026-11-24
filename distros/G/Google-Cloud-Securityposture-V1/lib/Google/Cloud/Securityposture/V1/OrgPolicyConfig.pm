package Google::Cloud::Securityposture::V1::OrgPolicyConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvc2VjdXJpdHlwb3N0dXJlL3YxL29yZ19wb2xpY3lfY29uZmlnLnBy
b3RvEh9nb29nbGUuY2xvdWQuc2VjdXJpdHlwb3N0dXJlLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhZnb29n
bGUvdHlwZS9leHByLnByb3RvIs0CCgpQb2xpY3lSdWxlElIKBnZhbHVlcxgBIAEoCzI4Lmdv
b2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEuUG9saWN5UnVsZS5TdHJpbmdWYWx1ZXNI
AFIGdmFsdWVzEh0KCWFsbG93X2FsbBgCIAEoCEgAUghhbGxvd0FsbBIbCghkZW55X2FsbBgD
IAEoCEgAUgdkZW55QWxsEhoKB2VuZm9yY2UYBCABKAhIAFIHZW5mb3JjZRIvCgljb25kaXRp
b24YBSABKAsyES5nb29nbGUudHlwZS5FeHByUgljb25kaXRpb24aWgoMU3RyaW5nVmFsdWVz
EiUKDmFsbG93ZWRfdmFsdWVzGAEgAygJUg1hbGxvd2VkVmFsdWVzEiMKDWRlbmllZF92YWx1
ZXMYAiADKAlSDGRlbmllZFZhbHVlc0IGCgRraW5kIssEChBDdXN0b21Db25zdHJhaW50EhcK
BG5hbWUYASABKAlCA+BBBVIEbmFtZRIqCg5yZXNvdXJjZV90eXBlcxgCIAMoCUID4EEFUg1y
ZXNvdXJjZVR5cGVzEl8KDG1ldGhvZF90eXBlcxgDIAMoDjI8Lmdvb2dsZS5jbG91ZC5zZWN1
cml0eXBvc3R1cmUudjEuQ3VzdG9tQ29uc3RyYWludC5NZXRob2RUeXBlUgttZXRob2RUeXBl
cxIcCgljb25kaXRpb24YBCABKAlSCWNvbmRpdGlvbhJdCgthY3Rpb25fdHlwZRgFIAEoDjI8
Lmdvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEuQ3VzdG9tQ29uc3RyYWludC5BY3Rp
b25UeXBlUgphY3Rpb25UeXBlEiEKDGRpc3BsYXlfbmFtZRgGIAEoCVILZGlzcGxheU5hbWUS
IAoLZGVzY3JpcHRpb24YByABKAlSC2Rlc2NyaXB0aW9uEkAKC3VwZGF0ZV90aW1lGAggASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lIk0KCk1ldGhv
ZFR5cGUSGwoXTUVUSE9EX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZDUkVBVEUQARIKCgZVUERB
VEUQAhIKCgZERUxFVEUQAyI+CgpBY3Rpb25UeXBlEhsKF0FDVElPTl9UWVBFX1VOU1BFQ0lG
SUVEEAASCQoFQUxMT1cQARIICgRERU5ZEAJCjAEKI2NvbS5nb29nbGUuY2xvdWQuc2VjdXJp
dHlwb3N0dXJlLnYxQhRPcmdQb2xpY3lDb25maWdQcm90b1ABWk1jbG91ZC5nb29nbGUuY29t
L2dvL3NlY3VyaXR5cG9zdHVyZS9hcGl2MS9zZWN1cml0eXBvc3R1cmVwYjtzZWN1cml0eXBv
c3R1cmVwYkq/NAoHEgUOAK0BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACkKCQoCAwISAxQAIAoICgEIEgMWAGQK
CQoCCAsSAxYAZAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADUKCQoCCAgSAxgANQoI
CgEIEgMZADwKCQoCCAESAxkAPAoxCgIEABIEHABWARolIEEgcnVsZSB1c2VkIHRvIGV4cHJl
c3MgdGhpcyBwb2xpY3kuCgoKCgMEAAESAxwIEgqXBwoEBAADABIELgI0AxqIByBBIG1lc3Nh
Z2UgdGhhdCBob2xkcyBzcGVjaWZpYyBhbGxvd2VkIGFuZCBkZW5pZWQgdmFsdWVzLgogVGhp
cyBtZXNzYWdlIGNhbiBkZWZpbmUgc3BlY2lmaWMgdmFsdWVzIGFuZCBzdWJ0cmVlcyBvZiB0
aGUgUmVzb3VyY2UKIE1hbmFnZXIgcmVzb3VyY2UgaGllcmFyY2h5IChgT3JnYW5pemF0aW9u
c2AsIGBGb2xkZXJzYCwgYFByb2plY3RzYCkgdGhhdAogYXJlIGFsbG93ZWQgb3IgZGVuaWVk
LiBUaGlzIGlzIGFjaGlldmVkIGJ5IHVzaW5nIHRoZSBgdW5kZXI6YCBhbmQKIG9wdGlvbmFs
IGBpczpgIHByZWZpeGVzLgogVGhlIGB1bmRlcjpgIHByZWZpeCBpcyB1c2VkIHRvIGRlbm90
ZSByZXNvdXJjZSBzdWJ0cmVlIHZhbHVlcy4KIFRoZSBgaXM6YCBwcmVmaXggaXMgdXNlZCB0
byBkZW5vdGUgc3BlY2lmaWMgdmFsdWVzLCBhbmQgaXMgcmVxdWlyZWQgb25seQogaWYgdGhl
IHZhbHVlIGNvbnRhaW5zIGEgIjoiLiBWYWx1ZXMgcHJlZml4ZWQgd2l0aCAiaXM6IiBhcmUg
dHJlYXRlZCB0aGUKIHNhbWUgYXMgdmFsdWVzIHdpdGggbm8gcHJlZml4LgogQW5jZXN0cnkg
c3VidHJlZXMgbXVzdCBiZSBpbiBvbmUgb2YgdGhlIGZvbGxvd2luZyBmb3JtYXRzOgoKIC0g
YHByb2plY3RzLzxwcm9qZWN0LWlkPmAgKGZvciBleGFtcGxlLCBgcHJvamVjdHMvdG9reW8t
cmFpbi0xMjNgKQogLSBgZm9sZGVycy88Zm9sZGVyLWlkPmAgKGZvciBleGFtcGxlLCBgZm9s
ZGVycy8xMjM0YCkKIC0gYG9yZ2FuaXphdGlvbnMvPG9yZ2FuaXphdGlvbi1pZD5gIChmb3Ig
ZXhhbXBsZSwgYG9yZ2FuaXphdGlvbnMvMTIzNGApCgogVGhlIGBzdXBwb3J0c191bmRlcmAg
ZmllbGQgb2YgdGhlIGFzc29jaWF0ZWQgYENvbnN0cmFpbnRgICBkZWZpbmVzCiB3aGV0aGVy
IGFuY2VzdHJ5IHByZWZpeGVzIGNhbiBiZSB1c2VkLgoKDAoFBAADAAESAy4KFgo5CgYEAAMA
AgASAzAEJxoqIExpc3Qgb2YgdmFsdWVzIGFsbG93ZWQgYXQgdGhpcyByZXNvdXJjZS4KCg4K
BwQAAwACAAQSAzAEDAoOCgcEAAMAAgAFEgMwDRMKDgoHBAADAAIAARIDMBQiCg4KBwQAAwAC
AAMSAzAlJgo4CgYEAAMAAgESAzMEJhopIExpc3Qgb2YgdmFsdWVzIGRlbmllZCBhdCB0aGlz
IHJlc291cmNlLgoKDgoHBAADAAIBBBIDMwQMCg4KBwQAAwACAQUSAzMNEwoOCgcEAAMAAgEB
EgMzFCEKDgoHBAADAAIBAxIDMyQlCgwKBAQACAASBDYCRwMKDAoFBAAIAAESAzYIDAp8CgQE
AAIAEgM5BBwabyBMaXN0IG9mIHZhbHVlcyB0byBiZSB1c2VkIGZvciB0aGlzIHBvbGljeSBy
dWxlLiBUaGlzIGZpZWxkIGNhbiBiZSBzZXQKIG9ubHkgaW4gcG9saWNpZXMgZm9yIGxpc3Qg
Y29uc3RyYWludHMuCgoMCgUEAAIABhIDOQQQCgwKBQQAAgABEgM5ERcKDAoFBAACAAMSAzka
GwqEAQoEBAACARIDPQQXGncgU2V0dGluZyB0aGlzIHRvIHRydWUgbWVhbnMgdGhhdCBhbGwg
dmFsdWVzIGFyZSBhbGxvd2VkLiBUaGlzIGZpZWxkIGNhbgogYmUgc2V0IG9ubHkgaW4gcG9s
aWNpZXMgZm9yIGxpc3QgY29uc3RyYWludHMuCgoMCgUEAAIBBRIDPQQICgwKBQQAAgEBEgM9
CRIKDAoFBAACAQMSAz0VFgqDAQoEBAACAhIDQQQWGnYgU2V0dGluZyB0aGlzIHRvIHRydWUg
bWVhbnMgdGhhdCBhbGwgdmFsdWVzIGFyZSBkZW5pZWQuIFRoaXMgZmllbGQgY2FuCiBiZSBz
ZXQgb25seSBpbiBwb2xpY2llcyBmb3IgbGlzdCBjb25zdHJhaW50cy4KCgwKBQQAAgIFEgNB
BAgKDAoFBAACAgESA0EJEQoMCgUEAAICAxIDQRQVCqsBCgQEAAIDEgNGBBUanQEgSWYgYHRy
dWVgLCB0aGVuIHRoZSBwb2xpY3kgaXMgZW5mb3JjZWQuIElmIGBmYWxzZWAsIHRoZW4gYW55
CiBjb25maWd1cmF0aW9uIGlzIGFjY2VwdGFibGUuCiBUaGlzIGZpZWxkIGNhbiBiZSBzZXQg
b25seSBpbiBwb2xpY2llcyBmb3IgYm9vbGVhbiBjb25zdHJhaW50cy4KCgwKBQQAAgMFEgNG
BAgKDAoFBAACAwESA0YJEAoMCgUEAAIDAxIDRhMUCrMFCgQEAAIEEgNVAiEapQUgQSBjb25k
aXRpb24gd2hpY2ggZGV0ZXJtaW5lcyB3aGV0aGVyIHRoaXMgcnVsZSBpcyB1c2VkCiBpbiB0
aGUgZXZhbHVhdGlvbiBvZiB0aGUgcG9saWN5LiBXaGVuIHNldCwgdGhlIGBleHByZXNzaW9u
YCBmaWVsZCBpbgogdGhlIGBFeHByJyBtdXN0IGluY2x1ZGUgZnJvbSAxIHRvIDEwIHN1YmV4
cHJlc3Npb25zLCBqb2luZWQgYnkgdGhlICJ8fCIKIG9yICImJiIgb3BlcmF0b3JzLiBFYWNo
IHN1YmV4cHJlc3Npb24gbXVzdCBiZSBvZiB0aGUgZm9ybQogInJlc291cmNlLm1hdGNoVGFn
KCc8T1JHX0lEPi90YWdfa2V5X3Nob3J0X25hbWUsCiAndGFnX3ZhbHVlX3Nob3J0X25hbWUn
KSIgb3IgInJlc291cmNlLm1hdGNoVGFnSWQoJ3RhZ0tleXMva2V5X2lkJywKICd0YWdWYWx1
ZXMvdmFsdWVfaWQnKSIgd2hlcmUga2V5X25hbWUgYW5kIHZhbHVlX25hbWUgYXJlIHRoZSBy
ZXNvdXJjZQogbmFtZXMgZm9yIExhYmVsIEtleXMgYW5kIFZhbHVlcy4gVGhlc2UgbmFtZXMg
YXJlIGF2YWlsYWJsZSBmcm9tIHRoZSBUYWcKIE1hbmFnZXIgU2VydmljZS4gQW4gZXhhbXBs
ZSBleHByZXNzaW9uIGlzOgogInJlc291cmNlLm1hdGNoVGFnKCcxMjM0NTY3ODkvZW52aXJv
bm1lbnQsCiAncHJvZCcpIiBvciAicmVzb3VyY2UubWF0Y2hUYWdJZCgndGFnS2V5cy8xMjMn
LAogJ3RhZ1ZhbHVlcy80NTYnKSIuCgoMCgUEAAIEBhIDVQISCgwKBQQAAgQBEgNVExwKDAoF
BAACBAMSA1UfIAqtAgoCBAESBV4ArQEBGp8CIEEgY3VzdG9tIGNvbnN0cmFpbnQgZGVmaW5l
ZCBieSBjdXN0b21lcnMgd2hpY2ggY2FuICpvbmx5KiBiZSBhcHBsaWVkIHRvIHRoZQogZ2l2
ZW4gcmVzb3VyY2UgdHlwZXMgYW5kIG9yZ2FuaXphdGlvbi4KCiBCeSBjcmVhdGluZyBhIGN1
c3RvbSBjb25zdHJhaW50LCBjdXN0b21lcnMgY2FuIGFwcGx5IHBvbGljaWVzIG9mIHRoaXMK
IGN1c3RvbSBjb25zdHJhaW50LiAqQ3JlYXRpbmcgYSBjdXN0b20gY29uc3RyYWludCBpdHNl
bGYgZG9lcyBOT1QgYXBwbHkgYW55CiBwb2xpY3kgZW5mb3JjZW1lbnQqLgoKCgoDBAEBEgNe
CBgK8gIKBAQBBAASBGYCcwMa4wIgVGhlIG9wZXJhdGlvbiBmb3Igd2hpY2ggdGhpcyBjb25z
dHJhaW50IHdpbGwgYmUgYXBwbGllZC4gVG8gYXBwbHkgdGhpcwogY29uc3RyYWludCBvbmx5
IHdoZW4gY3JlYXRpbmcgbmV3IFZNcywgdGhlIGBtZXRob2RfdHlwZXNgIHNob3VsZCBiZQog
YENSRUFURWAgb25seS4gVG8gYXBwbHkgdGhpcyBjb25zdHJhaW50IHdoZW4gY3JlYXRpbmcg
b3IgZGVsZXRpbmcKIFZNcywgdGhlIGBtZXRob2RfdHlwZXNgIHNob3VsZCBiZSBgQ1JFQVRF
YCBhbmQgYERFTEVURWAuCgogYFVQREFURWAgb25seSBjdXN0b20gY29uc3RyYWludHMgYXJl
IG5vdCBzdXBwb3J0ZWQuIFVzZSBgQ1JFQVRFYCBvcgogYENSRUFURSwgVVBEQVRFYC4KCgwK
BQQBBAABEgNmBxEKMgoGBAEEAAIAEgNoBCAaIyBVbnNwZWNpZmllZC4gUmVzdWx0cyBpbiBh
biBlcnJvci4KCg4KBwQBBAACAAESA2gEGwoOCgcEAQQAAgACEgNoHh8KPwoGBAEEAAIBEgNr
BA8aMCBDb25zdHJhaW50IGFwcGxpZWQgd2hlbiBjcmVhdGluZyB0aGUgcmVzb3VyY2UuCgoO
CgcEAQQAAgEBEgNrBAoKDgoHBAEEAAIBAhIDaw0OCj8KBgQBBAACAhIDbgQPGjAgQ29uc3Ry
YWludCBhcHBsaWVkIHdoZW4gdXBkYXRpbmcgdGhlIHJlc291cmNlLgoKDgoHBAEEAAICARID
bgQKCg4KBwQBBAACAgISA24NDgpTCgYEAQQAAgMSA3IEDxpEIENvbnN0cmFpbnQgYXBwbGll
ZCB3aGVuIGRlbGV0aW5nIHRoZSByZXNvdXJjZS4KIE5vdCBzdXBwb3J0ZWQgeWV0LgoKDgoH
BAEEAAIDARIDcgQKCg4KBwQBBAACAwISA3INDgojCgQEAQQBEgR2An8DGhUgQWxsb3cgb3Ig
ZGVueSB0eXBlLgoKDAoFBAEEAQESA3YHEQoyCgYEAQQBAgASA3gEIBojIFVuc3BlY2lmaWVk
LiBSZXN1bHRzIGluIGFuIGVycm9yLgoKDgoHBAEEAQIAARIDeAQbCg4KBwQBBAECAAISA3ge
HwolCgYEAQQBAgESA3sEDhoWIEFsbG93ZWQgYWN0aW9uIHR5cGUuCgoOCgcEAQQBAgEBEgN7
BAkKDgoHBAEEAQIBAhIDewwNCiIKBgQBBAECAhIDfgQNGhMgRGVueSBhY3Rpb24gdHlwZS4K
Cg4KBwQBBAECAgESA34ECAoOCgcEAQQBAgICEgN+CwwKrwMKBAQBAgASBIsBAjwaoAMgSW1t
dXRhYmxlLiBOYW1lIG9mIHRoZSBjb25zdHJhaW50LiBUaGlzIGlzIHVuaXF1ZSB3aXRoaW4g
dGhlIG9yZ2FuaXphdGlvbi4KIEZvcm1hdCBvZiB0aGUgbmFtZSBzaG91bGQgYmUKCiAtCiBg
b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9jdXN0b21Db25zdHJhaW50cy97Y3Vz
dG9tX2NvbnN0cmFpbnRfaWR9YAoKIEV4YW1wbGU6IGBvcmdhbml6YXRpb25zLzEyMy9jdXN0
b21Db25zdHJhaW50cy9jdXN0b20uY3JlYXRlT25seUUyVHlwZVZtc2AKCiBUaGUgbWF4IGxl
bmd0aCBpcyA3MCBjaGFyYWN0ZXJzIGFuZCB0aGUgbWluaW11bSBsZW5ndGggaXMgMS4gTm90
ZSB0aGF0IHRoZQogcHJlZml4IGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2N1
c3RvbUNvbnN0cmFpbnRzL2AgaXMgbm90IGNvdW50ZWQuCgoNCgUEAQIABRIEiwECCAoNCgUE
AQIAARIEiwEJDQoNCgUEAQIAAxIEiwEQEQoNCgUEAQIACBIEiwESOwoQCggEAQIACJwIABIE
iwETOgrFAQoEBAECARIEkQECTxq2ASBJbW11dGFibGUuIFRoZSByZXNvdXJjZSBpbnN0YW5j
ZSB0eXBlIG9uIHdoaWNoIHRoaXMgcG9saWN5IGFwcGxpZXMuIEZvcm1hdAogd2lsbCBiZSBv
ZiB0aGUgZm9ybSA6IGA8Y2Fub25pY2FsIHNlcnZpY2UgbmFtZT4vPHR5cGU+YCBFeGFtcGxl
OgoKICAtIGBjb21wdXRlLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlYC4KCg0KBQQBAgEEEgSR
AQIKCg0KBQQBAgEFEgSRAQsRCg0KBQQBAgEBEgSRARIgCg0KBQQBAgEDEgSRASMkCg0KBQQB
AgEIEgSRASVOChAKCAQBAgEInAgAEgSRASZNCkUKBAQBAgISBJQBAicaNyBBbGwgdGhlIG9w
ZXJhdGlvbnMgYmVpbmcgYXBwbGllZCBmb3IgdGhpcyBjb25zdHJhaW50LgoKDQoFBAECAgQS
BJQBAgoKDQoFBAECAgYSBJQBCxUKDQoFBAECAgESBJQBFiIKDQoFBAECAgMSBJQBJSYK4wEK
BAQBAgMSBJsBAhca1AEgT3JnIHBvbGljeSBjb25kaXRpb24vZXhwcmVzc2lvbi4gRm9yIGV4
YW1wbGU6CiBgcmVzb3VyY2UuaW5zdGFuY2VOYW1lLm1hdGNoZXMoIltwcm9kdWN0aW9ufHRl
c3RdXy4qXyhcZCkrIilgIG9yLAogYHJlc291cmNlLm1hbmFnZW1lbnQuYXV0b191cGdyYWRl
ID09IHRydWVgCgogVGhlIG1heCBsZW5ndGggb2YgdGhlIGNvbmRpdGlvbiBpcyAxMDAwIGNo
YXJhY3RlcnMuCgoNCgUEAQIDBRIEmwECCAoNCgUEAQIDARIEmwEJEgoNCgUEAQIDAxIEmwEV
FgojCgQEAQIEEgSeAQIdGhUgQWxsb3cgb3IgZGVueSB0eXBlLgoKDQoFBAECBAYSBJ4BAgwK
DQoFBAECBAESBJ4BDRgKDQoFBAECBAMSBJ4BGxwKaAoEBAECBRIEogECGhpaIE9uZSBsaW5l
IGRpc3BsYXkgbmFtZSBmb3IgdGhlIFVJLgogVGhlIG1heCBsZW5ndGggb2YgdGhlIGRpc3Bs
YXlfbmFtZSBpcyAyMDAgY2hhcmFjdGVycy4KCg0KBQQBAgUFEgSiAQIICg0KBQQBAgUBEgSi
AQkVCg0KBQQBAgUDEgSiARgZCoABCgQEAQIGEgSmAQIZGnIgRGV0YWlsZWQgaW5mb3JtYXRp
b24gYWJvdXQgdGhpcyBjdXN0b20gcG9saWN5IGNvbnN0cmFpbnQuCiBUaGUgbWF4IGxlbmd0
aCBvZiB0aGUgZGVzY3JpcHRpb24gaXMgMjAwMCBjaGFyYWN0ZXJzLgoKDQoFBAECBgUSBKYB
AggKDQoFBAECBgESBKYBCRQKDQoFBAECBgMSBKYBFxgKvgEKBAQBAgcSBqsBAqwBMhqtASBP
dXRwdXQgb25seS4gVGhlIGxhc3QgdGltZSB0aGlzIGN1c3RvbSBjb25zdHJhaW50IHdhcyB1
cGRhdGVkLiBUaGlzCiByZXByZXNlbnRzIHRoZSBsYXN0IHRpbWUgdGhhdCB0aGUgYENyZWF0
ZUN1c3RvbUNvbnN0cmFpbnRgIG9yCiBgVXBkYXRlQ3VzdG9tQ29uc3RyYWludGAgUlBDIHdh
cyBjYWxsZWQKCg0KBQQBAgcGEgSrAQIbCg0KBQQBAgcBEgSrARwnCg0KBQQBAgcDEgSrASor
Cg0KBQQBAgcIEgSsAQYxChAKCAQBAgcInAgAEgSsAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule ===
    # Fields for PolicyRule
    # Field: values Type: 11 (.google.cloud.securityposture.v1.PolicyRule.StringValues)
    # Field: allow_all Type: 8 ()
    # Field: deny_all Type: 8 ()
    # Field: enforce Type: 8 ()
    # Field: condition Type: 11 (.google.type.Expr)

# === Message: Google::Cloud::Securityposture::V1::OrgPolicyConfig::CustomConstraint ===
    # Fields for CustomConstraint
    # Field: name Type: 9 ()
    # Field: resource_types Type: 9 ()
    # Field: method_types Type: 14 (.google.cloud.securityposture.v1.CustomConstraint.MethodType)
    # Field: condition Type: 9 ()
    # Field: action_type Type: 14 (.google.cloud.securityposture.v1.CustomConstraint.ActionType)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: CustomConstraint::MethodType
our $CustomConstraint_METHOD_TYPE_UNSPECIFIED = 0;
our $CustomConstraint_CREATE = 1;
our $CustomConstraint_UPDATE = 2;
our $CustomConstraint_DELETE = 3;

# Enum: CustomConstraint::ActionType
our $CustomConstraint_ACTION_TYPE_UNSPECIFIED = 0;
our $CustomConstraint_ALLOW = 1;
our $CustomConstraint_DENY = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securityposture::V1::OrgPolicyConfig - Compiled Protocol Buffers messages for google/cloud/securityposture/v1/org_policy_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securityposture::V1::OrgPolicyConfig;

    my $msg = Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule->new({
        values => $values,
        allow_all => $allow_all,
        deny_all => $deny_all,
        enforce => $enforce,
    });

    # Read or update a field
    my $val = $msg->values();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securityposture/v1/org_policy_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule

A rule used to express this policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule::StringValues>)

List of values to be used for this policy rule. This field can be set
only in policies for list constraints.

=item * C<< $msg->allow_all() >> / C<< $msg->allow_all($value) >>

Type: C<Bool>

Setting this to true means that all values are allowed. This field can
be set only in policies for list constraints.

=item * C<< $msg->deny_all() >> / C<< $msg->deny_all($value) >>

Type: C<Bool>

Setting this to true means that all values are denied. This field can
be set only in policies for list constraints.

=item * C<< $msg->enforce() >> / C<< $msg->enforce($value) >>

Type: C<Bool>

If `true`, then the policy is enforced. If `false`, then any
configuration is acceptable.
This field can be set only in policies for boolean constraints.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

A condition which determines whether this rule is used
in the evaluation of the policy. When set, the `expression` field in
the `Expr' must include from 1 to 10 subexpressions, joined by the "||"
or "&&" operators. Each subexpression must be of the form
"resource.matchTag('<ORG_ID>/tag_key_short_name,
'tag_value_short_name')" or "resource.matchTagId('tagKeys/key_id',
'tagValues/value_id')" where key_name and value_name are the resource
names for Label Keys and Values. These names are available from the Tag
Manager Service. An example expression is:
"resource.matchTag('123456789/environment,
'prod')" or "resource.matchTagId('tagKeys/123',
'tagValues/456')".

=back

=head2 Google::Cloud::Securityposture::V1::OrgPolicyConfig::CustomConstraint

A custom constraint defined by customers which can *only* be applied to the
given resource types and organization.

By creating a custom constraint, customers can apply policies of this
custom constraint. *Creating a custom constraint itself does NOT apply any
policy enforcement*.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Name of the constraint. This is unique within the organization.
Format of the name should be

-
`organizations/{organization_id}/customConstraints/{custom_constraint_id}`

Example: `organizations/123/customConstraints/custom.createOnlyE2TypeVms`

The max length is 70 characters and the minimum length is 1. Note that the
prefix `organizations/{organization_id}/customConstraints/` is not counted.

=item * C<< $msg->resource_types() >> / C<< $msg->resource_types($value) >>

Type: C<String>

Immutable. The resource instance type on which this policy applies. Format
will be of the form : `<canonical service name>/<type>` Example:

 - `compute.googleapis.com/Instance`.

=item * C<< $msg->method_types() >> / C<< $msg->method_types($value) >>

Type: C<Enum> (L<Google::Cloud::Securityposture::V1::CustomConstraint::MethodType>)

All the operations being applied for this constraint.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Org policy condition/expression. For example:
`resource.instanceName.matches("[production|test]_.*_(\d)+")` or,
`resource.management.auto_upgrade == true`

The max length of the condition is 1000 characters.

=item * C<< $msg->action_type() >> / C<< $msg->action_type($value) >>

Type: C<Enum> (L<Google::Cloud::Securityposture::V1::CustomConstraint::ActionType>)

Allow or deny type.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

One line display name for the UI.
The max length of the display_name is 200 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Detailed information about this custom policy constraint.
The max length of the description is 2000 characters.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time this custom constraint was updated. This
represents the last time that the `CreateCustomConstraint` or
`UpdateCustomConstraint` RPC was called

=back

=head3 Enum: CustomConstraint::MethodType

=over 4

=item * C<METHOD_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE> => C<1>

=item * C<UPDATE> => C<2>

=item * C<DELETE> => C<3>

=back

=head3 Enum: CustomConstraint::ActionType

=over 4

=item * C<ACTION_TYPE_UNSPECIFIED> => C<0>

=item * C<ALLOW> => C<1>

=item * C<DENY> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securityposture::V1::OrgPolicyConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
