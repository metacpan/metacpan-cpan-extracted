package Google::Cloud::Retail::V2beta::ServingConfig;

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
    eval { require Google::Cloud::Retail::V2beta::Common };
    eval { require Google::Cloud::Retail::V2beta::SearchService };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9zZXJ2aW5nX2NvbmZpZy5wcm90bxIaZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9jbG91ZC9yZXRhaWwvdjJi
ZXRhL2NvbW1vbi5wcm90bxovZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmJldGEvc2VhcmNoX3Nl
cnZpY2UucHJvdG8imgsKDVNlcnZpbmdDb25maWcSFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1l
EiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRIZCghtb2RlbF9pZBgD
IAEoCVIHbW9kZWxJZBIyChVwcmljZV9yZXJhbmtpbmdfbGV2ZWwYBCABKAlSE3ByaWNlUmVy
YW5raW5nTGV2ZWwSKgoRZmFjZXRfY29udHJvbF9pZHMYBSADKAlSD2ZhY2V0Q29udHJvbElk
cxJoChJkeW5hbWljX2ZhY2V0X3NwZWMYBiABKAsyOi5nb29nbGUuY2xvdWQucmV0YWlsLnYy
YmV0YS5TZWFyY2hSZXF1ZXN0LkR5bmFtaWNGYWNldFNwZWNSEGR5bmFtaWNGYWNldFNwZWMS
KgoRYm9vc3RfY29udHJvbF9pZHMYByADKAlSD2Jvb3N0Q29udHJvbElkcxIsChJmaWx0ZXJf
Y29udHJvbF9pZHMYCSADKAlSEGZpbHRlckNvbnRyb2xJZHMSMAoUcmVkaXJlY3RfY29udHJv
bF9pZHMYCiADKAlSEnJlZGlyZWN0Q29udHJvbElkcxI9Cht0d293YXlfc3lub255bXNfY29u
dHJvbF9pZHMYEiADKAlSGHR3b3dheVN5bm9ueW1zQ29udHJvbElkcxI9ChtvbmV3YXlfc3lu
b255bXNfY29udHJvbF9pZHMYDCADKAlSGG9uZXdheVN5bm9ueW1zQ29udHJvbElkcxI+Chxk
b19ub3RfYXNzb2NpYXRlX2NvbnRyb2xfaWRzGA0gAygJUhhkb05vdEFzc29jaWF0ZUNvbnRy
b2xJZHMSNgoXcmVwbGFjZW1lbnRfY29udHJvbF9pZHMYDiADKAlSFXJlcGxhY2VtZW50Q29u
dHJvbElkcxIsChJpZ25vcmVfY29udHJvbF9pZHMYDyADKAlSEGlnbm9yZUNvbnRyb2xJZHMS
JwoPZGl2ZXJzaXR5X2xldmVsGAggASgJUg5kaXZlcnNpdHlMZXZlbBJeCg5kaXZlcnNpdHlf
dHlwZRgUIAEoDjI3Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWcu
RGl2ZXJzaXR5VHlwZVINZGl2ZXJzaXR5VHlwZRI/ChxlbmFibGVfY2F0ZWdvcnlfZmlsdGVy
X2xldmVsGBAgASgJUhllbmFibGVDYXRlZ29yeUZpbHRlckxldmVsEjAKFGlnbm9yZV9yZWNz
X2RlbnlsaXN0GBggASgIUhJpZ25vcmVSZWNzRGVueWxpc3QScAoUcGVyc29uYWxpemF0aW9u
X3NwZWMYFSABKAsyPS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZWFyY2hSZXF1ZXN0
LlBlcnNvbmFsaXphdGlvblNwZWNSE3BlcnNvbmFsaXphdGlvblNwZWMSVwoOc29sdXRpb25f
dHlwZXMYEyADKA4yKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Tb2x1dGlvblR5cGVC
BuBBAuBBBVINc29sdXRpb25UeXBlcyJkCg1EaXZlcnNpdHlUeXBlEh4KGkRJVkVSU0lUWV9U
WVBFX1VOU1BFQ0lGSUVEEAASGAoUUlVMRV9CQVNFRF9ESVZFUlNJVFkQAhIZChVEQVRBX0RS
SVZFTl9ESVZFUlNJVFkQAzqFAepBgQEKI3JldGFpbC5nb29nbGVhcGlzLmNvbS9TZXJ2aW5n
Q29uZmlnElpwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2F0YWxv
Z3Mve2NhdGFsb2d9L3NlcnZpbmdDb25maWdzL3tzZXJ2aW5nX2NvbmZpZ31C0QEKHmNvbS5n
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YUISU2VydmluZ0NvbmZpZ1Byb3RvUAFaNmNsb3Vk
Lmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYmV0YS9yZXRhaWxwYjtyZXRhaWxwYqICBlJF
VEFJTKoCGkdvb2dsZS5DbG91ZC5SZXRhaWwuVjJCZXRhygIaR29vZ2xlXENsb3VkXFJldGFp
bFxWMmJldGHqAh1Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYmV0YUqkWAoHEgUOAJwCAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAp
CgkKAgMBEgMTACMKCQoCAwISAxQAMQoJCgIDAxIDFQA5CggKAQgSAxcANwoJCgIIJRIDFwA3
CggKAQgSAxgATQoJCgIICxIDGABNCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMwoJ
CgIICBIDGgAzCggKAQgSAxsANwoJCgIIARIDGwA3CggKAQgSAxwAJAoJCgIIJBIDHAAkCggK
AQgSAx0ANwoJCgIIKRIDHQA3CggKAQgSAx4ANgoJCgIILRIDHgA2CoYBCgIEABIFIgCcAgEa
eSBDb25maWd1cmVzIG1ldGFkYXRhIHRoYXQgaXMgdXNlZCB0byBnZW5lcmF0ZSBzZXJ2aW5n
IHRpbWUgcmVzdWx0cyAoZS5nLgogc2VhcmNoIHJlc3VsdHMgb3IgcmVjb21tZW5kYXRpb24g
cHJlZGljdGlvbnMpLgoKCgoDBAABEgMiCBUKCwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYE
CjwKBAQABAASBCkCMgMaLiBXaGF0IHR5cGUgb2YgZGl2ZXJzaXR5IC0gZGF0YSBvciBydWxl
IGJhc2VkLgoKDAoFBAAEAAESAykHFAofCgYEAAQAAgASAysEIxoQIERlZmF1bHQgdmFsdWUu
CgoOCgcEAAQAAgABEgMrBB4KDgoHBAAEAAIAAhIDKyEiCiYKBgQABAACARIDLgQdGhcgUnVs
ZSBiYXNlZCBkaXZlcnNpdHkuCgoOCgcEAAQAAgEBEgMuBBgKDgoHBAAEAAIBAhIDLhscCicK
BgQABAACAhIDMQQeGhggRGF0YSBkcml2ZW4gZGl2ZXJzaXR5LgoKDgoHBAAEAAICARIDMQQZ
Cg4KBwQABAACAgISAzEcHQpoCgQEAAIAEgM2AjwaWyBJbW11dGFibGUuIEZ1bGx5IHF1YWxp
ZmllZCBuYW1lCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzLyovc2Vy
dmluZ0NvbmZpZy8qYAoKDAoFBAACAAUSAzYCCAoMCgUEAAIAARIDNgkNCgwKBQQAAgADEgM2
EBEKDAoFBAACAAgSAzYSOwoPCggEAAIACJwIABIDNhM6CuMBCgQEAAIBEgM9AkMa1QEgUmVx
dWlyZWQuIFRoZSBodW1hbiByZWFkYWJsZSBzZXJ2aW5nIGNvbmZpZyBkaXNwbGF5IG5hbWUu
IFVzZWQgaW4gUmV0YWlsCiBVSS4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNv
ZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3Ro
ZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDAoFBAAC
AQUSAz0CCAoMCgUEAAIBARIDPQkVCgwKBQQAAgEDEgM9GBkKDAoFBAACAQgSAz0aQgoPCggE
AAIBCJwIABIDPRtBCqIECgQEAAICEgNKAhYalAQgVGhlIGlkIG9mIHRoZSBtb2RlbCBpbiB0
aGUgc2FtZQogW0NhdGFsb2ddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkNhdGFsb2dd
IHRvIHVzZSBhdCBzZXJ2aW5nIHRpbWUuCiBDdXJyZW50bHkgb25seSBSZWNvbW1lbmRhdGlv
bk1vZGVscyBhcmUgc3VwcG9ydGVkOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFp
bC9yZWNvbW1lbmRhdGlvbnMtYWkvZG9jcy9jcmVhdGUtbW9kZWxzCiBDYW4gYmUgY2hhbmdl
ZCBidXQgb25seSB0byBhIGNvbXBhdGlibGUgbW9kZWwgKGUuZy4KIG90aGVycy15b3UtbWF5
LWxpa2UgQ1RSIHRvIG90aGVycy15b3UtbWF5LWxpa2UgQ1ZSKS4KCiBSZXF1aXJlZCB3aGVu
CiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdD
b25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVfUkVDT01NRU5EQVRJ
T05dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9U
WVBFX1JFQ09NTUVOREFUSU9OXS4KCgwKBQQAAgIFEgNKAggKDAoFBAACAgESA0oJEQoMCgUE
AAICAxIDShQVCssFCgQEAAIDEgNfAiMavQUgSG93IG11Y2ggcHJpY2UgcmFua2luZyB3ZSB3
YW50IGluIHNlcnZpbmcgcmVzdWx0cy4KIFByaWNlIHJlcmFua2luZyBjYXVzZXMgcHJvZHVj
dCBpdGVtcyB3aXRoIGEgc2ltaWxhcgogcmVjb21tZW5kYXRpb24gcHJvYmFiaWxpdHkgdG8g
YmUgb3JkZXJlZCBieSBwcmljZSwgd2l0aCB0aGUKIGhpZ2hlc3QtcHJpY2VkIGl0ZW1zIGZp
cnN0LiBUaGlzIHNldHRpbmcgY291bGQgcmVzdWx0IGluIGEgZGVjcmVhc2UgaW4KIGNsaWNr
LXRocm91Z2ggYW5kIGNvbnZlcnNpb24gcmF0ZXMuCiAgQWxsb3dlZCB2YWx1ZXMgYXJlOgoK
ICogYG5vLXByaWNlLXJlcmFua2luZ2AKICogYGxvdy1wcmljZS1yZXJhbmtpbmdgCiAqIGBt
ZWRpdW0tcHJpY2UtcmVyYW5raW5nYAogKiBgaGlnaC1wcmljZS1yZXJhbmtpbmdgCgogSWYg
bm90IHNwZWNpZmllZCwgd2UgY2hvb3NlIGRlZmF1bHQgYmFzZWQgb24gbW9kZWwgdHlwZS4g
RGVmYXVsdCB2YWx1ZToKIGBuby1wcmljZS1yZXJhbmtpbmdgLgoKIENhbiBvbmx5IGJlIHNl
dCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2
aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVO
REFUSU9OXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Tb2x1dGlvblR5cGUuU09MVVRJ
T05fVFlQRV9SRUNPTU1FTkRBVElPTl0uCgoMCgUEAAIDBRIDXwIICgwKBQQAAgMBEgNfCR4K
DAoFBAACAwMSA18hIgqEBQoEBAACBBIDbQIoGvYEIEZhY2V0IHNwZWNpZmljYXRpb25zIGZv
ciBmYWNldGVkIHNlYXJjaC4gSWYgZW1wdHksIG5vIGZhY2V0cyBhcmUgcmV0dXJuZWQuCiBU
aGUgaWRzIHJlZmVyIHRvIHRoZSBpZHMgb2YgW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLkNvbnRyb2xdCiByZXNvdXJjZXMgd2l0aCBvbmx5IHRoZSBGYWNldCBjb250
cm9sIHNldC4gVGhlc2UgY29udHJvbHMgYXJlIGFzc3VtZWQgdG8gYmUKIGluIHRoZSBzYW1l
IFtDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5DYXRhbG9nXSBhcyB0aGUK
IFtTZXJ2aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29u
ZmlnXS4KIEEgbWF4aW11bSBvZiAxMDAgdmFsdWVzIGFyZSBhbGxvd2VkLiBPdGhlcndpc2Us
IGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IKIGlzIHJldHVybmVkLgoKIENhbiBvbmx5IGJl
IHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5T
ZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBFX1NFQVJD
SF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZ
UEVfU0VBUkNIXS4KCgwKBQQAAgQEEgNtAgoKDAoFBAACBAUSA20LEQoMCgUEAAIEARIDbRIj
CgwKBQQAAgQDEgNtJicKvQIKBAQAAgUSA3YCOBqvAiBUaGUgc3BlY2lmaWNhdGlvbiBmb3Ig
ZHluYW1pY2FsbHkgZ2VuZXJhdGVkIGZhY2V0cy4gTm90aWNlIHRoYXQgb25seQogdGV4dHVh
bCBmYWNldHMgY2FuIGJlIGR5bmFtaWNhbGx5IGdlbmVyYXRlZC4KCiBDYW4gb25seSBiZSBz
ZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2Vy
dmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlzCiBbU09MVVRJT05fVFlQRV9TRUFSQ0hd
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBF
X1NFQVJDSF0uCgoMCgUEAAIFBhIDdgIgCgwKBQQAAgUBEgN2ITMKDAoFBAACBQMSA3Y2NwrU
BgoEBAACBhIEiQECKBrFBiBDb25kaXRpb24gYm9vc3Qgc3BlY2lmaWNhdGlvbnMuIElmIGEg
cHJvZHVjdCBtYXRjaGVzIG11bHRpcGxlIGNvbmRpdGlvbnMKIGluIHRoZSBzcGVjaWZpY2F0
aW9ucywgYm9vc3Qgc2NvcmVzIGZyb20gdGhlc2Ugc3BlY2lmaWNhdGlvbnMgYXJlIGFsbAog
YXBwbGllZCBhbmQgY29tYmluZWQgaW4gYSBub24tbGluZWFyIHdheS4gTWF4aW11bSBudW1i
ZXIgb2YKIHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCiBOb3RpY2UgdGhhdCBpZiBib3RoCiBb
U2VydmluZ0NvbmZpZy5ib29zdF9jb250cm9sX2lkc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuU2VydmluZ0NvbmZpZy5ib29zdF9jb250cm9sX2lkc10KIGFuZAogW1NlYXJjaFJl
cXVlc3QuYm9vc3Rfc3BlY11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VhcmNoUmVx
dWVzdC5ib29zdF9zcGVjXQogYXJlIHNldCwgdGhlIGJvb3N0IGNvbmRpdGlvbnMgZnJvbSBi
b3RoIHBsYWNlcyBhcmUgZXZhbHVhdGVkLiBJZiBhIHNlYXJjaAogcmVxdWVzdCBtYXRjaGVz
IG11bHRpcGxlIGJvb3N0IGNvbmRpdGlvbnMsIHRoZSBmaW5hbCBib29zdCBzY29yZSBpcyBl
cXVhbAogdG8gdGhlIHN1bSBvZiB0aGUgYm9vc3Qgc2NvcmVzIGZyb20gYWxsIG1hdGNoZWQg
Ym9vc3QgY29uZGl0aW9ucy4KCiBDYW4gb25seSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBl
c11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90
eXBlc10KIGlzCiBbU09MVVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoNCgUEAAIGBBIE
iQECCgoNCgUEAAIGBRIEiQELEQoNCgUEAAIGARIEiQESIwoNCgUEAAIGAxIEiQEmJwqtAwoE
BAACBxIElAECKRqeAyBDb25kaXRpb24gZmlsdGVyIHNwZWNpZmljYXRpb25zLiBJZiBhIHBy
b2R1Y3QgbWF0Y2hlcyBtdWx0aXBsZSBjb25kaXRpb25zCiBpbiB0aGUgc3BlY2lmaWNhdGlv
bnMsIGZpbHRlcnMgZnJvbSB0aGVzZSBzcGVjaWZpY2F0aW9ucyBhcmUgYWxsCiBhcHBsaWVk
IGFuZCBjb21iaW5lZCB2aWEgdGhlIEFORCBvcGVyYXRvci4gTWF4aW11bSBudW1iZXIgb2YK
IHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCiBDYW4gb25seSBiZSBzZXQgaWYKIFtzb2x1dGlv
bl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZy5zb2x1
dGlvbl90eXBlc10KIGlzCiBbU09MVVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJiZXRhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoNCgUE
AAIHBBIElAECCgoNCgUEAAIHBRIElAELEQoNCgUEAAIHARIElAESJAoNCgUEAAIHAxIElAEn
KArnAgoEBAACCBIEngECLBrYAiBDb25kaXRpb24gcmVkaXJlY3Qgc3BlY2lmaWNhdGlvbnMu
IE9ubHkgdGhlIGZpcnN0IHRyaWdnZXJlZCByZWRpcmVjdCBhY3Rpb24KIGlzIGFwcGxpZWQs
IGV2ZW4gaWYgbXVsdGlwbGUgYXBwbHkuIE1heGltdW0gbnVtYmVyIG9mIHNwZWNpZmljYXRp
b25zIGlzCiAxMDAwLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVz
XQogaXMKIFtTT0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAggEEgSeAQIK
Cg0KBQQAAggFEgSeAQsRCg0KBQQAAggBEgSeARImCg0KBQQAAggDEgSeASkrCqcDCgQEAAIJ
EgSpAQIzGpgDIENvbmRpdGlvbiBzeW5vbnltcyBzcGVjaWZpY2F0aW9ucy4gSWYgbXVsdGlw
bGUgc3lvbnltcyBjb25kaXRpb25zIG1hdGNoLAogYWxsIG1hdGNoaW5nIHN5bm9ueW1zIGNv
bnRyb2wgaW4gdGhlIGxpc3Qgd2lsbCBleGVjdXRlLiBPcmRlciBvZiBjb250cm9scwogaW4g
dGhlIGxpc3Qgd2lsbCBub3QgbWF0dGVyLiBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0
aW9ucyBpcwogMTAwLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVz
XQogaXMKIFtTT0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAgkEEgSpAQIK
Cg0KBQQAAgkFEgSpAQsRCg0KBQQAAgkBEgSpARItCg0KBQQAAgkDEgSpATAyCr4DCgQEAAIK
EgS0AQIzGq8DIENvbmRpdGlvbiBvbmV3YXkgc3lub255bXMgc3BlY2lmaWNhdGlvbnMuIElm
IG11bHRpcGxlIG9uZXdheSBzeW5vbnltcwogY29uZGl0aW9ucyBtYXRjaCwgYWxsIG1hdGNo
aW5nIG9uZXdheSBzeW5vbnltcyBjb250cm9scyBpbiB0aGUgbGlzdCB3aWxsCiBleGVjdXRl
LiBPcmRlciBvZiBjb250cm9scyBpbiB0aGUgbGlzdCB3aWxsIG5vdCBtYXR0ZXIuIE1heGlt
dW0gbnVtYmVyIG9mCiBzcGVjaWZpY2F0aW9ucyBpcyAxMDAuCgogQ2FuIG9ubHkgYmUgc2V0
IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZp
bmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Tb2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9T
RUFSQ0hdLgoKDQoFBAACCgQSBLQBAgoKDQoFBAACCgUSBLQBCxEKDQoFBAACCgESBLQBEi0K
DQoFBAACCgMSBLQBMDIKrgMKBAQAAgsSBMABAjQanwMgQ29uZGl0aW9uIGRvIG5vdCBhc3Nv
Y2lhdGUgc3BlY2lmaWNhdGlvbnMuIElmIG11bHRpcGxlIGRvIG5vdCBhc3NvY2lhdGUKIGNv
bmRpdGlvbnMgbWF0Y2gsIGFsbCBtYXRjaGluZyBkbyBub3QgYXNzb2NpYXRlIGNvbnRyb2xz
IGluIHRoZSBsaXN0IHdpbGwKIGV4ZWN1dGUuCiAtIE9yZGVyIGRvZXMgbm90IG1hdHRlci4K
IC0gTWF4aW11bSBudW1iZXIgb2Ygc3BlY2lmaWNhdGlvbnMgaXMgMTAwLgoKIENhbiBvbmx5
IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBFX1NF
QVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU29sdXRpb25UeXBlLlNPTFVUSU9O
X1RZUEVfU0VBUkNIXS4KCg0KBQQAAgsEEgTAAQIKCg0KBQQAAgsFEgTAAQsRCg0KBQQAAgsB
EgTAARIuCg0KBQQAAgsDEgTAATEzCoIDCgQEAAIMEgTLAQIvGvMCIENvbmRpdGlvbiByZXBs
YWNlbWVudCBzcGVjaWZpY2F0aW9ucy4KIC0gQXBwbGllZCBhY2NvcmRpbmcgdG8gdGhlIG9y
ZGVyIGluIHRoZSBsaXN0LgogLSBBIHByZXZpb3VzbHkgcmVwbGFjZWQgdGVybSBjYW4gbm90
IGJlIHJlLXJlcGxhY2VkLgogLSBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBp
cyAxMDAuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwog
W1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Tb2x1
dGlvblR5cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKDQoFBAACDAQSBMsBAgoKDQoFBAAC
DAUSBMsBCxEKDQoFBAACDAESBMsBEikKDQoFBAACDAMSBMsBLC4KkAMKBAQAAg0SBNcBAioa
gQMgQ29uZGl0aW9uIGlnbm9yZSBzcGVjaWZpY2F0aW9ucy4gSWYgbXVsdGlwbGUgaWdub3Jl
CiBjb25kaXRpb25zIG1hdGNoLCBhbGwgbWF0Y2hpbmcgaWdub3JlIGNvbnRyb2xzIGluIHRo
ZSBsaXN0IHdpbGwKIGV4ZWN1dGUuCiAtIE9yZGVyIGRvZXMgbm90IG1hdHRlci4KIC0gTWF4
aW11bSBudW1iZXIgb2Ygc3BlY2lmaWNhdGlvbnMgaXMgMTAwLgoKIENhbiBvbmx5IGJlIHNl
dCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2
aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBFX1NFQVJDSF1b
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVf
U0VBUkNIXS4KCg0KBQQAAg0EEgTXAQIKCg0KBQQAAg0FEgTXAQsRCg0KBQQAAg0BEgTXARIk
Cg0KBQQAAg0DEgTXAScpCq0ECgQEAAIOEgTpAQIdGp4EIEhvdyBtdWNoIGRpdmVyc2l0eSB0
byB1c2UgaW4gcmVjb21tZW5kYXRpb24gbW9kZWwgcmVzdWx0cyBlLmcuCiBgbWVkaXVtLWRp
dmVyc2l0eWAgb3IgYGhpZ2gtZGl2ZXJzaXR5YC4gQ3VycmVudGx5IHN1cHBvcnRlZCB2YWx1
ZXM6CgogKiBgbm8tZGl2ZXJzaXR5YAogKiBgbG93LWRpdmVyc2l0eWAKICogYG1lZGl1bS1k
aXZlcnNpdHlgCiAqIGBoaWdoLWRpdmVyc2l0eWAKICogYGF1dG8tZGl2ZXJzaXR5YAoKIElm
IG5vdCBzcGVjaWZpZWQsIHdlIGNob29zZSBkZWZhdWx0IGJhc2VkIG9uIHJlY29tbWVuZGF0
aW9uIG1vZGVsCiB0eXBlLiBEZWZhdWx0IHZhbHVlOiBgbm8tZGl2ZXJzaXR5YC4KCiBDYW4g
b25seSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlzCiBbU09MVVRJT05fVFlQ
RV9SRUNPTU1FTkRBVElPTl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU29sdXRpb25U
eXBlLlNPTFVUSU9OX1RZUEVfUkVDT01NRU5EQVRJT05dLgoKDQoFBAACDgUSBOkBAggKDQoF
BAACDgESBOkBCRgKDQoFBAACDgMSBOkBGxwK3AEKBAQAAg8SBO4BAiQazQEgV2hhdCBraW5k
IG9mIGRpdmVyc2l0eSB0byB1c2UgLSBkYXRhIGRyaXZlbiBvciBydWxlIGJhc2VkLiBJZiB1
bnNldCwgdGhlCiBzZXJ2ZXIgYmVoYXZpb3IgZGVmYXVsdHMgdG8KIFtSVUxFX0JBU0VEX0RJ
VkVSU0lUWV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZy5EaXZl
cnNpdHlUeXBlLlJVTEVfQkFTRURfRElWRVJTSVRZXS4KCg0KBQQAAg8GEgTuAQIPCg0KBQQA
Ag8BEgTuARAeCg0KBQQAAg8DEgTuASEjCvcFCgQEAAIQEgT/AQIrGugFIFdoZXRoZXIgdG8g
YWRkIGFkZGl0aW9uYWwgY2F0ZWdvcnkgZmlsdGVycyBvbiB0aGUgYHNpbWlsYXItaXRlbXNg
IG1vZGVsLgogSWYgbm90IHNwZWNpZmllZCwgd2UgZW5hYmxlIGl0IGJ5IGRlZmF1bHQuCiAg
QWxsb3dlZCB2YWx1ZXMgYXJlOgoKICogYG5vLWNhdGVnb3J5LW1hdGNoYDogTm8gYWRkaXRp
b25hbCBmaWx0ZXJpbmcgb2Ygb3JpZ2luYWwgcmVzdWx0cyBmcm9tCiAgIHRoZSBtb2RlbCBh
bmQgdGhlIGN1c3RvbWVyJ3MgZmlsdGVycy4KICogYHJlbGF4ZWQtY2F0ZWdvcnktbWF0Y2hg
OiBPbmx5IGtlZXAgcmVzdWx0cyB3aXRoIGNhdGVnb3JpZXMgdGhhdCBtYXRjaAogICBhdCBs
ZWFzdCBvbmUgaXRlbSBjYXRlZ29yaWVzIGluIHRoZSBQcmVkaWN0UmVxdWVzdHMncyBjb250
ZXh0IGl0ZW0uCiAgICogSWYgY3VzdG9tZXIgYWxzbyBzZW5kcyBmaWx0ZXJzIGluIHRoZSBQ
cmVkaWN0UmVxdWVzdCwgdGhlbiB0aGUgcmVzdWx0cwogICB3aWxsIHNhdGlzZnkgYm90aCBj
b25kaXRpb25zICh1c2VyIGdpdmVuIGFuZCBjYXRlZ29yeSBtYXRjaCkuCgogQ2FuIG9ubHkg
YmUgc2V0IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVfUkVD
T01NRU5EQVRJT05dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNvbHV0aW9uVHlwZS5T
T0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXS4KCg0KBQQAAhAFEgT/AQIICg0KBQQAAhAB
EgT/AQklCg0KBQQAAhADEgT/ASgqCokBCgQEAAIREgSDAgIhGnsgV2hlbiB0aGUgZmxhZyBp
cyBlbmFibGVkLCB0aGUgcHJvZHVjdHMgaW4gdGhlIGRlbnlsaXN0IHdpbGwgbm90IGJlIGZp
bHRlcmVkCiBvdXQgaW4gdGhlIHJlY29tbWVuZGF0aW9uIGZpbHRlcmluZyByZXN1bHRzLgoK
DQoFBAACEQUSBIMCAgYKDQoFBAACEQESBIMCBxsKDQoFBAACEQMSBIMCHiAKwAUKBAQAAhIS
BJQCAj4asQUgVGhlIHNwZWNpZmljYXRpb24gZm9yIHBlcnNvbmFsaXphdGlvbiBzcGVjLgoK
IENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElP
Tl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU29sdXRpb25UeXBl
LlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCiBOb3RpY2UgdGhhdCBpZiBib3RoCiBbU2Vydmlu
Z0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuU2VydmluZ0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY10KIGFuZAogW1NlYXJjaFJl
cXVlc3QucGVyc29uYWxpemF0aW9uX3NwZWNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LlNlYXJjaFJlcXVlc3QucGVyc29uYWxpemF0aW9uX3NwZWNdCiBhcmUgc2V0LgogW1NlYXJj
aFJlcXVlc3QucGVyc29uYWxpemF0aW9uX3NwZWNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJi
ZXRhLlNlYXJjaFJlcXVlc3QucGVyc29uYWxpemF0aW9uX3NwZWNdCiB3aWxsIG92ZXJyaWRl
CiBbU2VydmluZ0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY11bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuU2VydmluZ0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY10uCgoNCgUE
AAISBhIElAICIwoNCgUEAAISARIElAIkOAoNCgUEAAISAxIElAI7PQqrAQoEBAACExIGmAIC
mwIEGpoBIFJlcXVpcmVkLiBJbW11dGFibGUuIFNwZWNpZmllcyB0aGUgc29sdXRpb24gdHlw
ZXMgdGhhdCBhIHNlcnZpbmcgY29uZmlnIGNhbgogYmUgYXNzb2NpYXRlZCB3aXRoLiBDdXJy
ZW50bHkgd2Ugc3VwcG9ydCBzZXR0aW5nIG9ubHkgb25lIHR5cGUgb2Ygc29sdXRpb24uCgoN
CgUEAAITBBIEmAICCgoNCgUEAAITBhIEmAILFwoNCgUEAAITARIEmAIYJgoNCgUEAAITAxIE
mAIpKwoPCgUEAAITCBIGmAIsmwIDChAKCAQAAhMInAgAEgSZAgQqChAKCAQAAhMInAgBEgSa
AgQrYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig ===
    # Fields for ServingConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model_id Type: 9 ()
    # Field: price_reranking_level Type: 9 ()
    # Field: facet_control_ids Type: 9 ()
    # Field: dynamic_facet_spec Type: 11 (.google.cloud.retail.v2beta.SearchRequest.DynamicFacetSpec)
    # Field: boost_control_ids Type: 9 ()
    # Field: filter_control_ids Type: 9 ()
    # Field: redirect_control_ids Type: 9 ()
    # Field: twoway_synonyms_control_ids Type: 9 ()
    # Field: oneway_synonyms_control_ids Type: 9 ()
    # Field: do_not_associate_control_ids Type: 9 ()
    # Field: replacement_control_ids Type: 9 ()
    # Field: ignore_control_ids Type: 9 ()
    # Field: diversity_level Type: 9 ()
    # Field: diversity_type Type: 14 (.google.cloud.retail.v2beta.ServingConfig.DiversityType)
    # Field: enable_category_filter_level Type: 9 ()
    # Field: ignore_recs_denylist Type: 8 ()
    # Field: personalization_spec Type: 11 (.google.cloud.retail.v2beta.SearchRequest.PersonalizationSpec)
    # Field: solution_types Type: 14 (.google.cloud.retail.v2beta.SolutionType)

# Enum: ServingConfig::DiversityType
our $ServingConfig_DIVERSITY_TYPE_UNSPECIFIED = 0;
our $ServingConfig_RULE_BASED_DIVERSITY = 2;
our $ServingConfig_DATA_DRIVEN_DIVERSITY = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ServingConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/serving_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ServingConfig;

    my $msg = Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig->new({
        name => $name,
        display_name => $display_name,
        model_id => $model_id,
        price_reranking_level => $price_reranking_level,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/serving_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig

Configures metadata that is used to generate serving time results (e.g.
search results or recommendation predictions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/*/locations/global/catalogs/*/servingConfig/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human readable serving config display name. Used in Retail
UI.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

The id of the model in the same
[Catalog][google.cloud.retail.v2beta.Catalog] to use at serving time.
Currently only RecommendationModels are supported:
https://cloud.google.com/retail/recommendations-ai/docs/create-models
Can be changed but only to a compatible model (e.g.
others-you-may-like CTR to others-you-may-like CVR).

Required when
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->price_reranking_level() >> / C<< $msg->price_reranking_level($value) >>

Type: C<String>

How much price ranking we want in serving results.
Price reranking causes product items with a similar
recommendation probability to be ordered by price, with the
highest-priced items first. This setting could result in a decrease in
click-through and conversion rates.
 Allowed values are:

* `no-price-reranking`
* `low-price-reranking`
* `medium-price-reranking`
* `high-price-reranking`

If not specified, we choose default based on model type. Default value:
`no-price-reranking`.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->facet_control_ids() >> / C<< $msg->facet_control_ids($value) >>

Type: C<String>

Facet specifications for faceted search. If empty, no facets are returned.
The ids refer to the ids of [Control][google.cloud.retail.v2beta.Control]
resources with only the Facet control set. These controls are assumed to be
in the same [Catalog][google.cloud.retail.v2beta.Catalog] as the
[ServingConfig][google.cloud.retail.v2beta.ServingConfig].
A maximum of 100 values are allowed. Otherwise, an INVALID_ARGUMENT error
is returned.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->dynamic_facet_spec() >> / C<< $msg->dynamic_facet_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::SearchService::SearchRequest::DynamicFacetSpec>)

The specification for dynamically generated facets. Notice that only
textual facets can be dynamically generated.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->boost_control_ids() >> / C<< $msg->boost_control_ids($value) >>

Type: C<String>

Condition boost specifications. If a product matches multiple conditions
in the specifications, boost scores from these specifications are all
applied and combined in a non-linear way. Maximum number of
specifications is 100.

Notice that if both
[ServingConfig.boost_control_ids][google.cloud.retail.v2beta.ServingConfig.boost_control_ids]
and
[SearchRequest.boost_spec][google.cloud.retail.v2beta.SearchRequest.boost_spec]
are set, the boost conditions from both places are evaluated. If a search
request matches multiple boost conditions, the final boost score is equal
to the sum of the boost scores from all matched boost conditions.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->filter_control_ids() >> / C<< $msg->filter_control_ids($value) >>

Type: C<String>

Condition filter specifications. If a product matches multiple conditions
in the specifications, filters from these specifications are all
applied and combined via the AND operator. Maximum number of
specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->redirect_control_ids() >> / C<< $msg->redirect_control_ids($value) >>

Type: C<String>

Condition redirect specifications. Only the first triggered redirect action
is applied, even if multiple apply. Maximum number of specifications is
1000.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->twoway_synonyms_control_ids() >> / C<< $msg->twoway_synonyms_control_ids($value) >>

Type: C<String>

Condition synonyms specifications. If multiple syonyms conditions match,
all matching synonyms control in the list will execute. Order of controls
in the list will not matter. Maximum number of specifications is
100.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->oneway_synonyms_control_ids() >> / C<< $msg->oneway_synonyms_control_ids($value) >>

Type: C<String>

Condition oneway synonyms specifications. If multiple oneway synonyms
conditions match, all matching oneway synonyms controls in the list will
execute. Order of controls in the list will not matter. Maximum number of
specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->do_not_associate_control_ids() >> / C<< $msg->do_not_associate_control_ids($value) >>

Type: C<String>

Condition do not associate specifications. If multiple do not associate
conditions match, all matching do not associate controls in the list will
execute.
- Order does not matter.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->replacement_control_ids() >> / C<< $msg->replacement_control_ids($value) >>

Type: C<String>

Condition replacement specifications.
- Applied according to the order in the list.
- A previously replaced term can not be re-replaced.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->ignore_control_ids() >> / C<< $msg->ignore_control_ids($value) >>

Type: C<String>

Condition ignore specifications. If multiple ignore
conditions match, all matching ignore controls in the list will
execute.
- Order does not matter.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->diversity_level() >> / C<< $msg->diversity_level($value) >>

Type: C<String>

How much diversity to use in recommendation model results e.g.
`medium-diversity` or `high-diversity`. Currently supported values:

* `no-diversity`
* `low-diversity`
* `medium-diversity`
* `high-diversity`
* `auto-diversity`

If not specified, we choose default based on recommendation model
type. Default value: `no-diversity`.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->diversity_type() >> / C<< $msg->diversity_type($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::ServingConfig::DiversityType>)

What kind of diversity to use - data driven or rule based. If unset, the
server behavior defaults to
[RULE_BASED_DIVERSITY][google.cloud.retail.v2beta.ServingConfig.DiversityType.RULE_BASED_DIVERSITY].

=item * C<< $msg->enable_category_filter_level() >> / C<< $msg->enable_category_filter_level($value) >>

Type: C<String>

Whether to add additional category filters on the `similar-items` model.
If not specified, we enable it by default.
 Allowed values are:

* `no-category-match`: No additional filtering of original results from
  the model and the customer's filters.
* `relaxed-category-match`: Only keep results with categories that match
  at least one item categories in the PredictRequests's context item.
  * If customer also sends filters in the PredictRequest, then the results
  will satisfy both conditions (user given and category match).

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->ignore_recs_denylist() >> / C<< $msg->ignore_recs_denylist($value) >>

Type: C<Bool>

When the flag is enabled, the products in the denylist will not be filtered
out in the recommendation filtering results.

=item * C<< $msg->personalization_spec() >> / C<< $msg->personalization_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::SearchService::SearchRequest::PersonalizationSpec>)

The specification for personalization spec.

Can only be set if
[solution_types][google.cloud.retail.v2beta.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

Notice that if both
[ServingConfig.personalization_spec][google.cloud.retail.v2beta.ServingConfig.personalization_spec]
and
[SearchRequest.personalization_spec][google.cloud.retail.v2beta.SearchRequest.personalization_spec]
are set.
[SearchRequest.personalization_spec][google.cloud.retail.v2beta.SearchRequest.personalization_spec]
will override
[ServingConfig.personalization_spec][google.cloud.retail.v2beta.ServingConfig.personalization_spec].

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::SolutionType>)

Required. Immutable. Specifies the solution types that a serving config can
be associated with. Currently we support setting only one type of solution.

=back

=head3 Enum: ServingConfig::DiversityType

=over 4

=item * C<DIVERSITY_TYPE_UNSPECIFIED> => C<0>

=item * C<RULE_BASED_DIVERSITY> => C<2>

=item * C<DATA_DRIVEN_DIVERSITY> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ServingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
