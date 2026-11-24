package Google::Cloud::Datalabeling::V1beta1::Annotation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvYW5ub3RhdGlvbi5wcm90bxIh
Z29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExGjtnb29nbGUvY2xvdWQvZGF0YWxh
YmVsaW5nL3YxYmV0YTEvYW5ub3RhdGlvbl9zcGVjX3NldC5wcm90bxoeZ29vZ2xlL3Byb3Rv
YnVmL2R1cmF0aW9uLnByb3RvIrQDCgpBbm5vdGF0aW9uEhIKBG5hbWUYASABKAlSBG5hbWUS
YAoRYW5ub3RhdGlvbl9zb3VyY2UYAiABKA4yMy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5n
LnYxYmV0YTEuQW5ub3RhdGlvblNvdXJjZVIQYW5ub3RhdGlvblNvdXJjZRJdChBhbm5vdGF0
aW9uX3ZhbHVlGAMgASgLMjIuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkFu
bm90YXRpb25WYWx1ZVIPYW5ub3RhdGlvblZhbHVlEmYKE2Fubm90YXRpb25fbWV0YWRhdGEY
BCABKAsyNS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvbk1l
dGFkYXRhUhJhbm5vdGF0aW9uTWV0YWRhdGESaQoUYW5ub3RhdGlvbl9zZW50aW1lbnQYBiAB
KA4yNi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNlbnRp
bWVudFITYW5ub3RhdGlvblNlbnRpbWVudCLcCQoPQW5ub3RhdGlvblZhbHVlEooBCh9pbWFn
ZV9jbGFzc2lmaWNhdGlvbl9hbm5vdGF0aW9uGAEgASgLMkAuZ29vZ2xlLmNsb3VkLmRhdGFs
YWJlbGluZy52MWJldGExLkltYWdlQ2xhc3NpZmljYXRpb25Bbm5vdGF0aW9uSABSHWltYWdl
Q2xhc3NpZmljYXRpb25Bbm5vdGF0aW9uEoUBCh5pbWFnZV9ib3VuZGluZ19wb2x5X2Fubm90
YXRpb24YAiABKAsyPi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuSW1hZ2VC
b3VuZGluZ1BvbHlBbm5vdGF0aW9uSABSG2ltYWdlQm91bmRpbmdQb2x5QW5ub3RhdGlvbhJ4
ChlpbWFnZV9wb2x5bGluZV9hbm5vdGF0aW9uGAggASgLMjouZ29vZ2xlLmNsb3VkLmRhdGFs
YWJlbGluZy52MWJldGExLkltYWdlUG9seWxpbmVBbm5vdGF0aW9uSABSF2ltYWdlUG9seWxp
bmVBbm5vdGF0aW9uEoQBCh1pbWFnZV9zZWdtZW50YXRpb25fYW5ub3RhdGlvbhgJIAEoCzI+
Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5JbWFnZVNlZ21lbnRhdGlvbkFu
bm90YXRpb25IAFIbaW1hZ2VTZWdtZW50YXRpb25Bbm5vdGF0aW9uEocBCh50ZXh0X2NsYXNz
aWZpY2F0aW9uX2Fubm90YXRpb24YAyABKAsyPy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5n
LnYxYmV0YTEuVGV4dENsYXNzaWZpY2F0aW9uQW5ub3RhdGlvbkgAUhx0ZXh0Q2xhc3NpZmlj
YXRpb25Bbm5vdGF0aW9uEo4BCiF0ZXh0X2VudGl0eV9leHRyYWN0aW9uX2Fubm90YXRpb24Y
CiABKAsyQS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuVGV4dEVudGl0eUV4
dHJhY3Rpb25Bbm5vdGF0aW9uSABSHnRleHRFbnRpdHlFeHRyYWN0aW9uQW5ub3RhdGlvbhKK
AQofdmlkZW9fY2xhc3NpZmljYXRpb25fYW5ub3RhdGlvbhgEIAEoCzJALmdvb2dsZS5jbG91
ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5WaWRlb0NsYXNzaWZpY2F0aW9uQW5ub3RhdGlvbkgA
Uh12aWRlb0NsYXNzaWZpY2F0aW9uQW5ub3RhdGlvbhKLAQogdmlkZW9fb2JqZWN0X3RyYWNr
aW5nX2Fubm90YXRpb24YBSABKAsyQC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuVmlkZW9PYmplY3RUcmFja2luZ0Fubm90YXRpb25IAFIddmlkZW9PYmplY3RUcmFja2lu
Z0Fubm90YXRpb24SbwoWdmlkZW9fZXZlbnRfYW5ub3RhdGlvbhgGIAEoCzI3Lmdvb2dsZS5j
bG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5WaWRlb0V2ZW50QW5ub3RhdGlvbkgAUhR2aWRl
b0V2ZW50QW5ub3RhdGlvbkIMCgp2YWx1ZV90eXBlInsKHUltYWdlQ2xhc3NpZmljYXRpb25B
bm5vdGF0aW9uEloKD2Fubm90YXRpb25fc3BlYxgBIAEoCzIxLmdvb2dsZS5jbG91ZC5kYXRh
bGFiZWxpbmcudjFiZXRhMS5Bbm5vdGF0aW9uU3BlY1IOYW5ub3RhdGlvblNwZWMiJAoGVmVy
dGV4EgwKAXgYASABKAVSAXgSDAoBeRgCIAEoBVIBeSIuChBOb3JtYWxpemVkVmVydGV4EgwK
AXgYASABKAJSAXgSDAoBeRgCIAEoAlIBeSJVCgxCb3VuZGluZ1BvbHkSRQoIdmVydGljZXMY
ASADKAsyKS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuVmVydGV4Ugh2ZXJ0
aWNlcyJ+ChZOb3JtYWxpemVkQm91bmRpbmdQb2x5EmQKE25vcm1hbGl6ZWRfdmVydGljZXMY
ASADKAsyMy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuTm9ybWFsaXplZFZl
cnRleFISbm9ybWFsaXplZFZlcnRpY2VzItgCChtJbWFnZUJvdW5kaW5nUG9seUFubm90YXRp
b24SVgoNYm91bmRpbmdfcG9seRgCIAEoCzIvLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcu
djFiZXRhMS5Cb3VuZGluZ1BvbHlIAFIMYm91bmRpbmdQb2x5EnUKGG5vcm1hbGl6ZWRfYm91
bmRpbmdfcG9seRgDIAEoCzI5Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5O
b3JtYWxpemVkQm91bmRpbmdQb2x5SABSFm5vcm1hbGl6ZWRCb3VuZGluZ1BvbHkSWgoPYW5u
b3RhdGlvbl9zcGVjGAEgASgLMjEuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGEx
LkFubm90YXRpb25TcGVjUg5hbm5vdGF0aW9uU3BlY0IOCgxib3VuZGVkX2FyZWEiUQoIUG9s
eWxpbmUSRQoIdmVydGljZXMYASADKAsyKS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYx
YmV0YTEuVmVydGV4Ugh2ZXJ0aWNlcyJ6ChJOb3JtYWxpemVkUG9seWxpbmUSZAoTbm9ybWFs
aXplZF92ZXJ0aWNlcxgBIAMoCzIzLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRh
MS5Ob3JtYWxpemVkVmVydGV4UhJub3JtYWxpemVkVmVydGljZXMisgIKF0ltYWdlUG9seWxp
bmVBbm5vdGF0aW9uEkkKCHBvbHlsaW5lGAIgASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFsYWJl
bGluZy52MWJldGExLlBvbHlsaW5lSABSCHBvbHlsaW5lEmgKE25vcm1hbGl6ZWRfcG9seWxp
bmUYAyABKAsyNS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuTm9ybWFsaXpl
ZFBvbHlsaW5lSABSEm5vcm1hbGl6ZWRQb2x5bGluZRJaCg9hbm5vdGF0aW9uX3NwZWMYASAB
KAsyMS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNwZWNS
DmFubm90YXRpb25TcGVjQgYKBHBvbHki1wIKG0ltYWdlU2VnbWVudGF0aW9uQW5ub3RhdGlv
bhKBAQoRYW5ub3RhdGlvbl9jb2xvcnMYASADKAsyVC5nb29nbGUuY2xvdWQuZGF0YWxhYmVs
aW5nLnYxYmV0YTEuSW1hZ2VTZWdtZW50YXRpb25Bbm5vdGF0aW9uLkFubm90YXRpb25Db2xv
cnNFbnRyeVIQYW5ub3RhdGlvbkNvbG9ycxIbCgltaW1lX3R5cGUYAiABKAlSCG1pbWVUeXBl
Eh8KC2ltYWdlX2J5dGVzGAMgASgMUgppbWFnZUJ5dGVzGnYKFUFubm90YXRpb25Db2xvcnNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRJHCgV2YWx1ZRgCIAEoCzIxLmdvb2dsZS5jbG91ZC5k
YXRhbGFiZWxpbmcudjFiZXRhMS5Bbm5vdGF0aW9uU3BlY1IFdmFsdWU6AjgBInoKHFRleHRD
bGFzc2lmaWNhdGlvbkFubm90YXRpb24SWgoPYW5ub3RhdGlvbl9zcGVjGAEgASgLMjEuZ29v
Z2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkFubm90YXRpb25TcGVjUg5hbm5vdGF0
aW9uU3BlYyLhAQoeVGV4dEVudGl0eUV4dHJhY3Rpb25Bbm5vdGF0aW9uEloKD2Fubm90YXRp
b25fc3BlYxgBIAEoCzIxLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5Bbm5v
dGF0aW9uU3BlY1IOYW5ub3RhdGlvblNwZWMSYwoSc2VxdWVudGlhbF9zZWdtZW50GAIgASgL
MjQuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLlNlcXVlbnRpYWxTZWdtZW50
UhFzZXF1ZW50aWFsU2VnbWVudCI7ChFTZXF1ZW50aWFsU2VnbWVudBIUCgVzdGFydBgBIAEo
BVIFc3RhcnQSEAoDZW5kGAIgASgFUgNlbmQilwEKC1RpbWVTZWdtZW50EkUKEXN0YXJ0X3Rp
bWVfb2Zmc2V0GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg9zdGFydFRpbWVP
ZmZzZXQSQQoPZW5kX3RpbWVfb2Zmc2V0GAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0
aW9uUg1lbmRUaW1lT2Zmc2V0Is4BCh1WaWRlb0NsYXNzaWZpY2F0aW9uQW5ub3RhdGlvbhJR
Cgx0aW1lX3NlZ21lbnQYASABKAsyLi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuVGltZVNlZ21lbnRSC3RpbWVTZWdtZW50EloKD2Fubm90YXRpb25fc3BlYxgCIAEoCzIx
Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5Bbm5vdGF0aW9uU3BlY1IOYW5u
b3RhdGlvblNwZWMisAIKE09iamVjdFRyYWNraW5nRnJhbWUSVgoNYm91bmRpbmdfcG9seRgB
IAEoCzIvLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5Cb3VuZGluZ1BvbHlI
AFIMYm91bmRpbmdQb2x5EnUKGG5vcm1hbGl6ZWRfYm91bmRpbmdfcG9seRgCIAEoCzI5Lmdv
b2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5Ob3JtYWxpemVkQm91bmRpbmdQb2x5
SABSFm5vcm1hbGl6ZWRCb3VuZGluZ1BvbHkSOgoLdGltZV9vZmZzZXQYAyABKAsyGS5nb29n
bGUucHJvdG9idWYuRHVyYXRpb25SCnRpbWVPZmZzZXRCDgoMYm91bmRlZF9hcmVhIrwCCh1W
aWRlb09iamVjdFRyYWNraW5nQW5ub3RhdGlvbhJaCg9hbm5vdGF0aW9uX3NwZWMYASABKAsy
MS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNwZWNSDmFu
bm90YXRpb25TcGVjElEKDHRpbWVfc2VnbWVudBgCIAEoCzIuLmdvb2dsZS5jbG91ZC5kYXRh
bGFiZWxpbmcudjFiZXRhMS5UaW1lU2VnbWVudFILdGltZVNlZ21lbnQSbAoWb2JqZWN0X3Ry
YWNraW5nX2ZyYW1lcxgDIAMoCzI2Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRh
MS5PYmplY3RUcmFja2luZ0ZyYW1lUhRvYmplY3RUcmFja2luZ0ZyYW1lcyLFAQoUVmlkZW9F
dmVudEFubm90YXRpb24SWgoPYW5ub3RhdGlvbl9zcGVjGAEgASgLMjEuZ29vZ2xlLmNsb3Vk
LmRhdGFsYWJlbGluZy52MWJldGExLkFubm90YXRpb25TcGVjUg5hbm5vdGF0aW9uU3BlYxJR
Cgx0aW1lX3NlZ21lbnQYAiABKAsyLi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuVGltZVNlZ21lbnRSC3RpbWVTZWdtZW50InYKEkFubm90YXRpb25NZXRhZGF0YRJgChFv
cGVyYXRvcl9tZXRhZGF0YRgCIAEoCzIzLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFi
ZXRhMS5PcGVyYXRvck1ldGFkYXRhUhBvcGVyYXRvck1ldGFkYXRhIoYBChBPcGVyYXRvck1l
dGFkYXRhEhQKBXNjb3JlGAEgASgCUgVzY29yZRIfCgt0b3RhbF92b3RlcxgCIAEoBVIKdG90
YWxWb3RlcxIfCgtsYWJlbF92b3RlcxgDIAEoBVIKbGFiZWxWb3RlcxIaCghjb21tZW50cxgE
IAMoCVIIY29tbWVudHMqQwoQQW5ub3RhdGlvblNvdXJjZRIhCh1BTk5PVEFUSU9OX1NPVVJD
RV9VTlNQRUNJRklFRBAAEgwKCE9QRVJBVE9SEAMqVwoTQW5ub3RhdGlvblNlbnRpbWVudBIk
CiBBTk5PVEFUSU9OX1NFTlRJTUVOVF9VTlNQRUNJRklFRBAAEgwKCE5FR0FUSVZFEAESDAoI
UE9TSVRJVkUQAiqRBAoOQW5ub3RhdGlvblR5cGUSHwobQU5OT1RBVElPTl9UWVBFX1VOU1BF
Q0lGSUVEEAASIwofSU1BR0VfQ0xBU1NJRklDQVRJT05fQU5OT1RBVElPThABEiEKHUlNQUdF
X0JPVU5ESU5HX0JPWF9BTk5PVEFUSU9OEAISKgomSU1BR0VfT1JJRU5URURfQk9VTkRJTkdf
Qk9YX0FOTk9UQVRJT04QDRIiCh5JTUFHRV9CT1VORElOR19QT0xZX0FOTk9UQVRJT04QChId
ChlJTUFHRV9QT0xZTElORV9BTk5PVEFUSU9OEAsSIQodSU1BR0VfU0VHTUVOVEFUSU9OX0FO
Tk9UQVRJT04QDBIpCiVWSURFT19TSE9UU19DTEFTU0lGSUNBVElPTl9BTk5PVEFUSU9OEAMS
JAogVklERU9fT0JKRUNUX1RSQUNLSU5HX0FOTk9UQVRJT04QBBIlCiFWSURFT19PQkpFQ1Rf
REVURUNUSU9OX0FOTk9UQVRJT04QBRIaChZWSURFT19FVkVOVF9BTk5PVEFUSU9OEAYSIgoe
VEVYVF9DTEFTU0lGSUNBVElPTl9BTk5PVEFUSU9OEAgSJQohVEVYVF9FTlRJVFlfRVhUUkFD
VElPTl9BTk5PVEFUSU9OEAkSJQohR0VORVJBTF9DTEFTU0lGSUNBVElPTl9BTk5PVEFUSU9O
EA5C4wEKJWNvbS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTFQAVpJY2xvdWQu
Z29vZ2xlLmNvbS9nby9kYXRhbGFiZWxpbmcvYXBpdjFiZXRhMS9kYXRhbGFiZWxpbmdwYjtk
YXRhbGFiZWxpbmdwYqoCIUdvb2dsZS5DbG91ZC5EYXRhTGFiZWxpbmcuVjFCZXRhMcoCIUdv
b2dsZVxDbG91ZFxEYXRhTGFiZWxpbmdcVjFiZXRhMeoCJEdvb2dsZTo6Q2xvdWQ6OkRhdGFM
YWJlbGluZzo6VjFiZXRhMUqcVQoHEgUPANgCAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCgoICgECEgMRACoKCQoCAwASAxMARQoJCgIDARIDFAAoCggKAQgSAxYAPgoJ
CgIIJRIDFgA+CggKAQgSAxcAYAoJCgIICxIDFwBgCggKAQgSAxgAIgoJCgIIChIDGAAiCggK
AQgSAxkAPgoJCgIIARIDGQA+CggKAQgSAxoAPgoJCgIIKRIDGgA+CggKAQgSAxsAPQoJCgII
LRIDGwA9CnwKAgUAEgQfACQBGnAgU3BlY2lmaWVzIHdoZXJlIHRoZSBhbm5vdGF0aW9uIGNv
bWVzIGZyb20gKHdoZXRoZXIgaXQgd2FzIHByb3ZpZGVkIGJ5IGEKIGh1bWFuIGxhYmVsZXIg
b3IgYSBkaWZmZXJlbnQgc291cmNlKS4KCgoKAwUAARIDHwUVCgsKBAUAAgASAyACJAoMCgUF
AAIAARIDIAIfCgwKBQUAAgACEgMgIiMKOQoEBQACARIDIwIPGiwgQW5zd2VyIGlzIHByb3Zp
ZGVkIGJ5IGEgaHVtYW4gY29udHJpYnV0b3IuCgoMCgUFAAIBARIDIwIKCgwKBQUAAgECEgMj
DQ4K4wEKAgQAEgQpADwBGtYBIEFubm90YXRpb24gZm9yIEV4YW1wbGUuIEVhY2ggZXhhbXBs
ZSBtYXkgaGF2ZSBvbmUgb3IgbW9yZSBhbm5vdGF0aW9ucy4gRm9yCiBleGFtcGxlIGluIGlt
YWdlIGNsYXNzaWZpY2F0aW9uIHByb2JsZW0sIGVhY2ggaW1hZ2UgbWlnaHQgaGF2ZSBvbmUg
b3IgbW9yZQogbGFiZWxzLiBXZSBjYWxsIGxhYmVscyBiaW5kZWQgd2l0aCB0aGlzIGltYWdl
IGFuIEFubm90YXRpb24uCgoKCgMEAAESAykIEgrNAQoEBAACABIDLQISGr8BIE91dHB1dCBv
bmx5LiBVbmlxdWUgbmFtZSBvZiB0aGlzIGFubm90YXRpb24sIGZvcm1hdCBpczoKCiBwcm9q
ZWN0cy97cHJvamVjdF9pZH0vZGF0YXNldHMve2RhdGFzZXRfaWR9L2Fubm90YXRlZERhdGFz
ZXRzL3thbm5vdGF0ZWRfZGF0YXNldH0vZXhhbXBsZXMve2V4YW1wbGVfaWR9L2Fubm90YXRp
b25zL3thbm5vdGF0aW9uX2lkfQoKDAoFBAACAAUSAy0CCAoMCgUEAAIAARIDLQkNCgwKBQQA
AgADEgMtEBEKOQoEBAACARIDMAIpGiwgT3V0cHV0IG9ubHkuIFRoZSBzb3VyY2Ugb2YgdGhl
IGFubm90YXRpb24uCgoMCgUEAAIBBhIDMAISCgwKBQQAAgEBEgMwEyQKDAoFBAACAQMSAzAn
KAp6CgQEAAICEgM0AicabSBPdXRwdXQgb25seS4gVGhpcyBpcyB0aGUgYWN0dWFsIGFubm90
YXRpb24gdmFsdWUsIGUuZyBjbGFzc2lmaWNhdGlvbiwKIGJvdW5kaW5nIGJveCB2YWx1ZXMg
YXJlIHN0b3JlZCBoZXJlLgoKDAoFBAACAgYSAzQCEQoMCgUEAAICARIDNBIiCgwKBQQAAgID
EgM0JSYKXgoEBAACAxIDOAItGlEgT3V0cHV0IG9ubHkuIEFubm90YXRpb24gbWV0YWRhdGEs
IGluY2x1ZGluZyBpbmZvcm1hdGlvbiBsaWtlIHZvdGVzCiBmb3IgbGFiZWxzLgoKDAoFBAAC
AwYSAzgCFAoMCgUEAAIDARIDOBUoCgwKBQQAAgMDEgM4KywKOgoEBAACBBIDOwIvGi0gT3V0
cHV0IG9ubHkuIFNlbnRpbWVudCBmb3IgdGhpcyBhbm5vdGF0aW9uLgoKDAoFBAACBAYSAzsC
FQoMCgUEAAIEARIDOxYqCgwKBQQAAgQDEgM7LS4KCgoCBQESBD4ARgEKCgoDBQEBEgM+BRgK
CwoEBQECABIDPwInCgwKBQUBAgABEgM/AiIKDAoFBQECAAISAz8lJgpDCgQFAQIBEgNCAg8a
NiBUaGlzIGFubm90YXRpb24gZGVzY3JpYmVzIG5lZ2F0aXZlbHkgYWJvdXQgdGhlIGRhdGEu
CgoMCgUFAQIBARIDQgIKCgwKBQUBAgECEgNCDQ4KPgoEBQECAhIDRQIPGjEgVGhpcyBsYWJl
bCBkZXNjcmliZXMgcG9zaXRpdmVseSBhYm91dCB0aGUgZGF0YS4KCgwKBQUBAgIBEgNFAgoK
DAoFBQECAgISA0UNDgoKCgIFAhIESABzAQoKCgMFAgESA0gFEwoLCgQFAgIAEgNJAiIKDAoF
BQICAAESA0kCHQoMCgUFAgIAAhIDSSAhClkKBAUCAgESA0wCJhpMIENsYXNzaWZpY2F0aW9u
IGFubm90YXRpb25zIGluIGFuIGltYWdlLiBBbGxvd2VkIGZvciBjb250aW51b3VzIGV2YWx1
YXRpb24uCgoMCgUFAgIBARIDTAIhCgwKBQUCAgECEgNMJCUKegoEBQICAhIDUAIkGm0gQm91
bmRpbmcgYm94IGFubm90YXRpb25zIGluIGFuIGltYWdlLiBBIGZvcm0gb2YgaW1hZ2Ugb2Jq
ZWN0IGRldGVjdGlvbi4KIEFsbG93ZWQgZm9yIGNvbnRpbnVvdXMgZXZhbHVhdGlvbi4KCgwK
BQUCAgIBEgNQAh8KDAoFBQICAgISA1AiIwpfCgQFAgIDEgNUAi4aUiBPcmllbnRlZCBib3Vu
ZGluZyBib3guIFRoZSBib3ggZG9lcyBub3QgaGF2ZSB0byBiZSBwYXJhbGxlbCB0byBob3Jp
em9udGFsCiBsaW5lLgoKDAoFBQICAwESA1QCKAoMCgUFAgIDAhIDVCstCjUKBAUCAgQSA1cC
JhooIEJvdW5kaW5nIHBvbHkgYW5ub3RhdGlvbnMgaW4gYW4gaW1hZ2UuCgoMCgUFAgIEARID
VwIgCgwKBQUCAgQCEgNXIyUKMAoEBQICBRIDWgIhGiMgUG9seWxpbmUgYW5ub3RhdGlvbnMg
aW4gYW4gaW1hZ2UuCgoMCgUFAgIFARIDWgIbCgwKBQUCAgUCEgNaHiAKNAoEBQICBhIDXQIl
GicgU2VnbWVudGF0aW9uIGFubm90YXRpb25zIGluIGFuIGltYWdlLgoKDAoFBQICBgESA10C
HwoMCgUFAgIGAhIDXSIkCjkKBAUCAgcSA2ACLBosIENsYXNzaWZpY2F0aW9uIGFubm90YXRp
b25zIGluIHZpZGVvIHNob3RzLgoKDAoFBQICBwESA2ACJwoMCgUFAgIHAhIDYCorCjAKBAUC
AggSA2MCJxojIFZpZGVvIG9iamVjdCB0cmFja2luZyBhbm5vdGF0aW9uLgoKDAoFBQICCAES
A2MCIgoMCgUFAgIIAhIDYyUmCjEKBAUCAgkSA2YCKBokIFZpZGVvIG9iamVjdCBkZXRlY3Rp
b24gYW5ub3RhdGlvbi4KCgwKBQUCAgkBEgNmAiMKDAoFBQICCQISA2YmJwomCgQFAgIKEgNp
Ah0aGSBWaWRlbyBldmVudCBhbm5vdGF0aW9uLgoKDAoFBQICCgESA2kCGAoMCgUFAgIKAhID
aRscCkoKBAUCAgsSA2wCJRo9IENsYXNzaWZpY2F0aW9uIGZvciB0ZXh0LiBBbGxvd2VkIGZv
ciBjb250aW51b3VzIGV2YWx1YXRpb24uCgoMCgUFAgILARIDbAIgCgwKBQUCAgsCEgNsIyQK
KgoEBQICDBIDbwIoGh0gRW50aXR5IGV4dHJhY3Rpb24gZm9yIHRleHQuCgoMCgUFAgIMARID
bwIjCgwKBQUCAgwCEgNvJicKSQoEBQICDRIDcgIpGjwgR2VuZXJhbCBjbGFzc2lmaWNhdGlv
bi4gQWxsb3dlZCBmb3IgY29udGludW91cyBldmFsdWF0aW9uLgoKDAoFBQICDQESA3ICIwoM
CgUFAgINAhIDciYoCi8KAgQBEgV2AJcBARoiIEFubm90YXRpb24gdmFsdWUgZm9yIGFuIGV4
YW1wbGUuCgoKCgMEAQESA3YIFwoNCgQEAQgAEgV3ApYBAwoMCgUEAQgAARIDdwgSCj4KBAQB
AgASA3kERhoxIEFubm90YXRpb24gdmFsdWUgZm9yIGltYWdlIGNsYXNzaWZpY2F0aW9uIGNh
c2UuCgoMCgUEAQIABhIDeQQhCgwKBQQBAgABEgN5IkEKDAoFBAECAAMSA3lERQphCgQEAQIB
EgN9BEMaVCBBbm5vdGF0aW9uIHZhbHVlIGZvciBpbWFnZSBib3VuZGluZyBib3gsIG9yaWVu
dGVkIGJvdW5kaW5nIGJveAogYW5kIHBvbHlnb24gY2FzZXMuCgoMCgUEAQIBBhIDfQQfCgwK
BQQBAgEBEgN9ID4KDAoFBAECAQMSA31BQgruAQoEBAECAhIEgwEEOhrfASBBbm5vdGF0aW9u
IHZhbHVlIGZvciBpbWFnZSBwb2x5bGluZSBjYXNlcy4KIFBvbHlsaW5lIGhlcmUgaXMgZGlm
ZmVyZW50IGZyb20gQm91bmRpbmdQb2x5LiBJdCBpcyBmb3JtZWQgYnkKIGxpbmUgc2VnbWVu
dHMgY29ubmVjdGVkIHRvIGVhY2ggb3RoZXIgYnV0IG5vdCBjbG9zZWQgZm9ybShCb3VuZGlu
ZyBQb2x5KS4KIFRoZSBsaW5lIHNlZ21lbnRzIGNhbiBjcm9zcyBlYWNoIG90aGVyLgoKDQoF
BAECAgYSBIMBBBsKDQoFBAECAgESBIMBHDUKDQoFBAECAgMSBIMBODkKOAoEBAECAxIEhgEE
QhoqIEFubm90YXRpb24gdmFsdWUgZm9yIGltYWdlIHNlZ21lbnRhdGlvbi4KCg0KBQQBAgMG
EgSGAQQfCg0KBQQBAgMBEgSGASA9Cg0KBQQBAgMDEgSGAUBBCj4KBAQBAgQSBIkBBEQaMCBB
bm5vdGF0aW9uIHZhbHVlIGZvciB0ZXh0IGNsYXNzaWZpY2F0aW9uIGNhc2UuCgoNCgUEAQIE
BhIEiQEEIAoNCgUEAQIEARIEiQEhPwoNCgUEAQIEAxIEiQFCQwpBCgQEAQIFEgSMAQRKGjMg
QW5ub3RhdGlvbiB2YWx1ZSBmb3IgdGV4dCBlbnRpdHkgZXh0cmFjdGlvbiBjYXNlLgoKDQoF
BAECBQYSBIwBBCIKDQoFBAECBQESBIwBI0QKDQoFBAECBQMSBIwBR0kKPwoEBAECBhIEjwEE
RhoxIEFubm90YXRpb24gdmFsdWUgZm9yIHZpZGVvIGNsYXNzaWZpY2F0aW9uIGNhc2UuCgoN
CgUEAQIGBhIEjwEEIQoNCgUEAQIGARIEjwEiQQoNCgUEAQIGAxIEjwFERQpOCgQEAQIHEgSS
AQRHGkAgQW5ub3RhdGlvbiB2YWx1ZSBmb3IgdmlkZW8gb2JqZWN0IGRldGVjdGlvbiBhbmQg
dHJhY2tpbmcgY2FzZS4KCg0KBQQBAgcGEgSSAQQhCg0KBQQBAgcBEgSSASJCCg0KBQQBAgcD
EgSSAUVGCjYKBAQBAggSBJUBBDQaKCBBbm5vdGF0aW9uIHZhbHVlIGZvciB2aWRlbyBldmVu
dCBjYXNlLgoKDQoFBAECCAYSBJUBBBgKDQoFBAECCAESBJUBGS8KDQoFBAECCAMSBJUBMjMK
OwoCBAISBpoBAJ0BARotIEltYWdlIGNsYXNzaWZpY2F0aW9uIGFubm90YXRpb24gZGVmaW5p
dGlvbi4KCgsKAwQCARIEmgEIJQofCgQEAgIAEgScAQIlGhEgTGFiZWwgb2YgaW1hZ2UuCgoN
CgUEAgIABhIEnAECEAoNCgUEAgIAARIEnAERIAoNCgUEAgIAAxIEnAEjJAqHAQoCBAMSBqEB
AKcBARp5IEEgdmVydGV4IHJlcHJlc2VudHMgYSAyRCBwb2ludCBpbiB0aGUgaW1hZ2UuCiBO
T1RFOiB0aGUgdmVydGV4IGNvb3JkaW5hdGVzIGFyZSBpbiB0aGUgc2FtZSBzY2FsZSBhcyB0
aGUgb3JpZ2luYWwgaW1hZ2UuCgoLCgMEAwESBKEBCA4KHQoEBAMCABIEowECDhoPIFggY29v
cmRpbmF0ZS4KCg0KBQQDAgAFEgSjAQIHCg0KBQQDAgABEgSjAQgJCg0KBQQDAgADEgSjAQwN
Ch0KBAQDAgESBKYBAg4aDyBZIGNvb3JkaW5hdGUuCgoNCgUEAwIBBRIEpgECBwoNCgUEAwIB
ARIEpgEICQoNCgUEAwIBAxIEpgEMDQqhAQoCBAQSBqwBALIBARqSASBBIHZlcnRleCByZXBy
ZXNlbnRzIGEgMkQgcG9pbnQgaW4gdGhlIGltYWdlLgogTk9URTogdGhlIG5vcm1hbGl6ZWQg
dmVydGV4IGNvb3JkaW5hdGVzIGFyZSByZWxhdGl2ZSB0byB0aGUgb3JpZ2luYWwgaW1hZ2UK
IGFuZCByYW5nZSBmcm9tIDAgdG8gMS4KCgsKAwQEARIErAEIGAodCgQEBAIAEgSuAQIOGg8g
WCBjb29yZGluYXRlLgoKDQoFBAQCAAUSBK4BAgcKDQoFBAQCAAESBK4BCAkKDQoFBAQCAAMS
BK4BDA0KHQoEBAQCARIEsQECDhoPIFkgY29vcmRpbmF0ZS4KCg0KBQQEAgEFEgSxAQIHCg0K
BQQEAgEBEgSxAQgJCg0KBQQEAgEDEgSxAQwNCjAKAgQFEga1AQC4AQEaIiBBIGJvdW5kaW5n
IHBvbHlnb24gaW4gdGhlIGltYWdlLgoKCwoDBAUBEgS1AQgUCi4KBAQFAgASBLcBAh8aICBU
aGUgYm91bmRpbmcgcG9seWdvbiB2ZXJ0aWNlcy4KCg0KBQQFAgAEEgS3AQIKCg0KBQQFAgAG
EgS3AQsRCg0KBQQFAgABEgS3ARIaCg0KBQQFAgADEgS3AR0eCiwKAgQGEga7AQC+AQEaHiBO
b3JtYWxpemVkIGJvdW5kaW5nIHBvbHlnb24uCgoLCgMEBgESBLsBCB4KOQoEBAYCABIEvQEC
NBorIFRoZSBib3VuZGluZyBwb2x5Z29uIG5vcm1hbGl6ZWQgdmVydGljZXMuCgoNCgUEBgIA
BBIEvQECCgoNCgUEBgIABhIEvQELGwoNCgUEBgIAARIEvQEcLwoNCgUEBgIAAxIEvQEyMwpt
CgIEBxIGwgEAzQEBGl8gSW1hZ2UgYm91bmRpbmcgcG9seSBhbm5vdGF0aW9uLiBJdCByZXBy
ZXNlbnRzIGEgcG9seWdvbiBpbmNsdWRpbmcKIGJvdW5kaW5nIGJveCBpbiB0aGUgaW1hZ2Uu
CgoLCgMEBwESBMIBCCMKagoEBAcIABIGxQECyQEDGlogVGhlIHJlZ2lvbiBvZiB0aGUgcG9s
eWdvbi4gSWYgaXQgaXMgYSBib3VuZGluZyBib3gsIGl0IGlzIGd1YXJhbnRlZWQgdG8gYmUK
IGZvdXIgcG9pbnRzLgoKDQoFBAcIAAESBMUBCBQKDAoEBAcCABIExgEEIwoNCgUEBwIABhIE
xgEEEAoNCgUEBwIAARIExgERHgoNCgUEBwIAAxIExgEhIgoMCgQEBwIBEgTIAQQ4Cg0KBQQH
AgEGEgTIAQQaCg0KBQQHAgEBEgTIARszCg0KBQQHAgEDEgTIATY3CjkKBAQHAgISBMwBAiUa
KyBMYWJlbCBvZiBvYmplY3QgaW4gdGhpcyBib3VuZGluZyBwb2x5Z29uLgoKDQoFBAcCAgYS
BMwBAhAKDQoFBAcCAgESBMwBESAKDQoFBAcCAgMSBMwBIyQKMwoCBAgSBtABANMBARolIEEg
bGluZSB3aXRoIG11bHRpcGxlIGxpbmUgc2VnbWVudHMuCgoLCgMECAESBNABCBAKJgoEBAgC
ABIE0gECHxoYIFRoZSBwb2x5bGluZSB2ZXJ0aWNlcy4KCg0KBQQIAgAEEgTSAQIKCg0KBQQI
AgAGEgTSAQsRCg0KBQQIAgABEgTSARIaCg0KBQQIAgADEgTSAR0eCiQKAgQJEgbWAQDZAQEa
FiBOb3JtYWxpemVkIHBvbHlsaW5lLgoKCwoDBAkBEgTWAQgaCjEKBAQJAgASBNgBAjQaIyBU
aGUgbm9ybWFsaXplZCBwb2x5bGluZSB2ZXJ0aWNlcy4KCg0KBQQJAgAEEgTYAQIKCg0KBQQJ
AgAGEgTYAQsbCg0KBQQJAgABEgTYARwvCg0KBQQJAgADEgTYATIzCjQKAgQKEgbcAQDlAQEa
JiBBIHBvbHlsaW5lIGZvciB0aGUgaW1hZ2UgYW5ub3RhdGlvbi4KCgsKAwQKARIE3AEIHwoO
CgQECggAEgbdAQLhAQMKDQoFBAoIAAESBN0BCAwKDAoEBAoCABIE3gEEGgoNCgUECgIABhIE
3gEEDAoNCgUECgIAARIE3gENFQoNCgUECgIAAxIE3gEYGQoMCgQECgIBEgTgAQQvCg0KBQQK
AgEGEgTgAQQWCg0KBQQKAgEBEgTgARcqCg0KBQQKAgEDEgTgAS0uCicKBAQKAgISBOQBAiUa
GSBMYWJlbCBvZiB0aGlzIHBvbHlsaW5lLgoKDQoFBAoCAgYSBOQBAhAKDQoFBAoCAgESBOQB
ESAKDQoFBAoCAgMSBOQBIyQKLgoCBAsSBugBAPMBARogIEltYWdlIHNlZ21lbnRhdGlvbiBh
bm5vdGF0aW9uLgoKCwoDBAsBEgToAQgjCqYBCgQECwIAEgTsAQI0GpcBIFRoZSBtYXBwaW5n
IGJldHdlZW4gcmdiIGNvbG9yIGFuZCBhbm5vdGF0aW9uIHNwZWMuIFRoZSBrZXkgaXMgdGhl
IHJnYgogY29sb3IgcmVwcmVzZW50ZWQgaW4gZm9ybWF0IG9mIHJnYigwLCAwLCAwKS4gVGhl
IHZhbHVlIGlzIHRoZQogQW5ub3RhdGlvblNwZWMuCgoNCgUECwIABhIE7AECHQoNCgUECwIA
ARIE7AEeLwoNCgUECwIAAxIE7AEyMwodCgQECwIBEgTvAQIXGg8gSW1hZ2UgZm9ybWF0LgoK
DQoFBAsCAQUSBO8BAggKDQoFBAsCAQESBO8BCRIKDQoFBAsCAQMSBO8BFRYKOgoEBAsCAhIE
8gECGBosIEEgYnl0ZSBzdHJpbmcgb2YgYSBmdWxsIGltYWdlJ3MgY29sb3IgbWFwLgoKDQoF
BAsCAgUSBPIBAgcKDQoFBAsCAgESBPIBCBMKDQoFBAsCAgMSBPIBFhcKLwoCBAwSBvYBAPkB
ARohIFRleHQgY2xhc3NpZmljYXRpb24gYW5ub3RhdGlvbi4KCgsKAwQMARIE9gEIJAoiCgQE
DAIAEgT4AQIlGhQgTGFiZWwgb2YgdGhlIHRleHQuCgoNCgUEDAIABhIE+AECEAoNCgUEDAIA
ARIE+AERIAoNCgUEDAIAAxIE+AEjJAoyCgIEDRIG/AEAggIBGiQgVGV4dCBlbnRpdHkgZXh0
cmFjdGlvbiBhbm5vdGF0aW9uLgoKCwoDBA0BEgT8AQgmCisKBAQNAgASBP4BAiUaHSBMYWJl
bCBvZiB0aGUgdGV4dCBlbnRpdGllcy4KCg0KBQQNAgAGEgT+AQIQCg0KBQQNAgABEgT+AREg
Cg0KBQQNAgADEgT+ASMkCicKBAQNAgESBIECAisaGSBQb3NpdGlvbiBvZiB0aGUgZW50aXR5
LgoKDQoFBA0CAQYSBIECAhMKDQoFBA0CAQESBIECFCYKDQoFBA0CAQMSBIECKSoKSQoCBA4S
BoUCAIsCARo7IFN0YXJ0IGFuZCBlbmQgcG9zaXRpb24gaW4gYSBzZXF1ZW5jZSAoZS5nLiB0
ZXh0IHNlZ21lbnQpLgoKCwoDBA4BEgSFAggZCisKBAQOAgASBIcCAhIaHSBTdGFydCBwb3Np
dGlvbiAoaW5jbHVzaXZlKS4KCg0KBQQOAgAFEgSHAgIHCg0KBQQOAgABEgSHAggNCg0KBQQO
AgADEgSHAhARCikKBAQOAgESBIoCAhAaGyBFbmQgcG9zaXRpb24gKGV4Y2x1c2l2ZSkuCgoN
CgUEDgIBBRIEigICBwoNCgUEDgIBARIEigIICwoNCgUEDgIBAxIEigIODwpaCgIEDxIGjgIA
lgIBGkwgQSB0aW1lIHBlcmlvZCBpbnNpZGUgb2YgYW4gZXhhbXBsZSB0aGF0IGhhcyBhIHRp
bWUgZGltZW5zaW9uIChlLmcuIHZpZGVvKS4KCgsKAwQPARIEjgIIEwpsCgQEDwIAEgSRAgIx
Gl4gU3RhcnQgb2YgdGhlIHRpbWUgc2VnbWVudCAoaW5jbHVzaXZlKSwgcmVwcmVzZW50ZWQg
YXMgdGhlIGR1cmF0aW9uIHNpbmNlCiB0aGUgZXhhbXBsZSBzdGFydC4KCg0KBQQPAgAGEgSR
AgIaCg0KBQQPAgABEgSRAhssCg0KBQQPAgADEgSRAi8wCmoKBAQPAgESBJUCAi8aXCBFbmQg
b2YgdGhlIHRpbWUgc2VnbWVudCAoZXhjbHVzaXZlKSwgcmVwcmVzZW50ZWQgYXMgdGhlIGR1
cmF0aW9uIHNpbmNlIHRoZQogZXhhbXBsZSBzdGFydC4KCg0KBQQPAgEGEgSVAgIaCg0KBQQP
AgEBEgSVAhsqCg0KBQQPAgEDEgSVAi0uCjAKAgQQEgaZAgCfAgEaIiBWaWRlbyBjbGFzc2lm
aWNhdGlvbiBhbm5vdGF0aW9uLgoKCwoDBBABEgSZAgglCk4KBAQQAgASBJsCAh8aQCBUaGUg
dGltZSBzZWdtZW50IG9mIHRoZSB2aWRlbyB0byB3aGljaCB0aGUgYW5ub3RhdGlvbiBhcHBs
aWVzLgoKDQoFBBACAAYSBJsCAg0KDQoFBBACAAESBJsCDhoKDQoFBBACAAMSBJsCHR4KPwoE
BBACARIEngICJRoxIExhYmVsIG9mIHRoZSBzZWdtZW50IHNwZWNpZmllZCBieSB0aW1lX3Nl
Z21lbnQuCgoNCgUEEAIBBhIEngICEAoNCgUEEAIBARIEngIRIAoNCgUEEAIBAxIEngIjJApP
CgIEERIGogIArAIBGkEgVmlkZW8gZnJhbWUgbGV2ZWwgYW5ub3RhdGlvbiBmb3Igb2JqZWN0
IGRldGVjdGlvbiBhbmQgdHJhY2tpbmcuCgoLCgMEEQESBKICCBsKTwoEBBEIABIGpAICqAID
Gj8gVGhlIGJvdW5kaW5nIGJveCBsb2NhdGlvbiBvZiB0aGlzIG9iamVjdCB0cmFjayBmb3Ig
dGhlIGZyYW1lLgoKDQoFBBEIAAESBKQCCBQKDAoEBBECABIEpQIEIwoNCgUEEQIABhIEpQIE
EAoNCgUEEQIAARIEpQIRHgoNCgUEEQIAAxIEpQIhIgoMCgQEEQIBEgSnAgQ4Cg0KBQQRAgEG
EgSnAgQaCg0KBQQRAgEBEgSnAhszCg0KBQQRAgEDEgSnAjY3ClUKBAQRAgISBKsCAisaRyBU
aGUgdGltZSBvZmZzZXQgb2YgdGhpcyBmcmFtZSByZWxhdGl2ZSB0byB0aGUgYmVnaW5uaW5n
IG9mIHRoZSB2aWRlby4KCg0KBQQRAgIGEgSrAgIaCg0KBQQRAgIBEgSrAhsmCg0KBQQRAgID
EgSrAikqCjEKAgQSEgavAgC4AgEaIyBWaWRlbyBvYmplY3QgdHJhY2tpbmcgYW5ub3RhdGlv
bi4KCgsKAwQSARIErwIIJQo/CgQEEgIAEgSxAgIlGjEgTGFiZWwgb2YgdGhlIG9iamVjdCB0
cmFja2VkIGluIHRoaXMgYW5ub3RhdGlvbi4KCg0KBQQSAgAGEgSxAgIQCg0KBQQSAgABEgSx
AhEgCg0KBQQSAgADEgSxAiMkCk8KBAQSAgESBLQCAh8aQSBUaGUgdGltZSBzZWdtZW50IG9m
IHRoZSB2aWRlbyB0byB3aGljaCBvYmplY3QgdHJhY2tpbmcgYXBwbGllcy4KCg0KBQQSAgEG
EgS0AgINCg0KBQQSAgEBEgS0Ag4aCg0KBQQSAgEDEgS0Ah0eCkMKBAQSAgISBLcCAjoaNSBU
aGUgbGlzdCBvZiBmcmFtZXMgd2hlcmUgdGhpcyBvYmplY3QgdHJhY2sgYXBwZWFycy4KCg0K
BQQSAgIEEgS3AgIKCg0KBQQSAgIGEgS3AgseCg0KBQQSAgIBEgS3Ah81Cg0KBQQSAgIDEgS3
Ajg5CicKAgQTEga7AgDBAgEaGSBWaWRlbyBldmVudCBhbm5vdGF0aW9uLgoKCwoDBBMBEgS7
AggcCjYKBAQTAgASBL0CAiUaKCBMYWJlbCBvZiB0aGUgZXZlbnQgaW4gdGhpcyBhbm5vdGF0
aW9uLgoKDQoFBBMCAAYSBL0CAhAKDQoFBBMCAAESBL0CESAKDQoFBBMCAAMSBL0CIyQKTgoE
BBMCARIEwAICHxpAIFRoZSB0aW1lIHNlZ21lbnQgb2YgdGhlIHZpZGVvIHRvIHdoaWNoIHRo
ZSBhbm5vdGF0aW9uIGFwcGxpZXMuCgoNCgUEEwIBBhIEwAICDQoNCgUEEwIBARIEwAIOGgoN
CgUEEwIBAxIEwAIdHgpGCgIEFBIGxAIAxwIBGjggQWRkaXRpb25hbCBpbmZvcm1hdGlvbiBh
c3NvY2lhdGVkIHdpdGggdGhlIGFubm90YXRpb24uCgoLCgMEFAESBMQCCBoKMwoEBBQCABIE
xgICKRolIE1ldGFkYXRhIHJlbGF0ZWQgdG8gaHVtYW4gbGFiZWxpbmcuCgoNCgUEFAIABhIE
xgICEgoNCgUEFAIAARIExgITJAoNCgUEFAIAAxIExgInKApPCgIEFRIGygIA2AIBGkEgR2Vu
ZXJhbCBpbmZvcm1hdGlvbiB1c2VmdWwgZm9yIGxhYmVscyBjb21pbmcgZnJvbSBjb250cmli
dXRvcnMuCgoLCgMEFQESBMoCCBgKxwEKBAQVAgASBM4CAhIauAEgQ29uZmlkZW5jZSBzY29y
ZSBjb3JyZXNwb25kaW5nIHRvIGEgbGFiZWwuIEZvciBleGFtbGUsIGlmIDMgY29udHJpYnV0
b3JzCiBoYXZlIGFuc3dlcmVkIHRoZSBxdWVzdGlvbiBhbmQgMiBvZiB0aGVtIGFncmVlIG9u
IHRoZSBmaW5hbCBsYWJlbCwgdGhlCiBjb25maWRlbmNlIHNjb3JlIHdpbGwgYmUgMC42NyAo
Mi8zKS4KCg0KBQQVAgAFEgTOAgIHCg0KBQQVAgABEgTOAggNCg0KBQQVAgADEgTOAhARCksK
BAQVAgESBNECAhgaPSBUaGUgdG90YWwgbnVtYmVyIG9mIGNvbnRyaWJ1dG9ycyB0aGF0IGFu
c3dlciB0aGlzIHF1ZXN0aW9uLgoKDQoFBBUCAQUSBNECAgcKDQoFBBUCAQESBNECCBMKDQoF
BBUCAQMSBNECFhcKSAoEBBUCAhIE1AICGBo6IFRoZSB0b3RhbCBudW1iZXIgb2YgY29udHJp
YnV0b3JzIHRoYXQgY2hvb3NlIHRoaXMgbGFiZWwuCgoNCgUEFQICBRIE1AICBwoNCgUEFQIC
ARIE1AIIEwoNCgUEFQICAxIE1AIWFworCgQEFQIDEgTXAgIfGh0gQ29tbWVudHMgZnJvbSBj
b250cmlidXRvcnMuCgoNCgUEFQIDBBIE1wICCgoNCgUEFQIDBRIE1wILEQoNCgUEFQIDARIE
1wISGgoNCgUEFQIDAxIE1wIdHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation ===
    # Fields for Annotation
    # Field: name Type: 9 ()
    # Field: annotation_source Type: 14 (.google.cloud.datalabeling.v1beta1.AnnotationSource)
    # Field: annotation_value Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationValue)
    # Field: annotation_metadata Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationMetadata)
    # Field: annotation_sentiment Type: 14 (.google.cloud.datalabeling.v1beta1.AnnotationSentiment)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationValue ===
    # Fields for AnnotationValue
    # Field: image_classification_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.ImageClassificationAnnotation)
    # Field: image_bounding_poly_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.ImageBoundingPolyAnnotation)
    # Field: image_polyline_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.ImagePolylineAnnotation)
    # Field: image_segmentation_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.ImageSegmentationAnnotation)
    # Field: text_classification_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.TextClassificationAnnotation)
    # Field: text_entity_extraction_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.TextEntityExtractionAnnotation)
    # Field: video_classification_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.VideoClassificationAnnotation)
    # Field: video_object_tracking_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.VideoObjectTrackingAnnotation)
    # Field: video_event_annotation Type: 11 (.google.cloud.datalabeling.v1beta1.VideoEventAnnotation)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::ImageClassificationAnnotation ===
    # Fields for ImageClassificationAnnotation
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex ===
    # Fields for Vertex
    # Field: x Type: 5 ()
    # Field: y Type: 5 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex ===
    # Fields for NormalizedVertex
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly ===
    # Fields for BoundingPoly
    # Field: vertices Type: 11 (.google.cloud.datalabeling.v1beta1.Vertex)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly ===
    # Fields for NormalizedBoundingPoly
    # Field: normalized_vertices Type: 11 (.google.cloud.datalabeling.v1beta1.NormalizedVertex)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::ImageBoundingPolyAnnotation ===
    # Fields for ImageBoundingPolyAnnotation
    # Field: bounding_poly Type: 11 (.google.cloud.datalabeling.v1beta1.BoundingPoly)
    # Field: normalized_bounding_poly Type: 11 (.google.cloud.datalabeling.v1beta1.NormalizedBoundingPoly)
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::Polyline ===
    # Fields for Polyline
    # Field: vertices Type: 11 (.google.cloud.datalabeling.v1beta1.Vertex)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedPolyline ===
    # Fields for NormalizedPolyline
    # Field: normalized_vertices Type: 11 (.google.cloud.datalabeling.v1beta1.NormalizedVertex)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::ImagePolylineAnnotation ===
    # Fields for ImagePolylineAnnotation
    # Field: polyline Type: 11 (.google.cloud.datalabeling.v1beta1.Polyline)
    # Field: normalized_polyline Type: 11 (.google.cloud.datalabeling.v1beta1.NormalizedPolyline)
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation ===
    # Fields for ImageSegmentationAnnotation
    # Field: annotation_colors Type: 11 (.google.cloud.datalabeling.v1beta1.ImageSegmentationAnnotation.AnnotationColorsEntry)
    # Field: mime_type Type: 9 ()
    # Field: image_bytes Type: 12 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::TextClassificationAnnotation ===
    # Fields for TextClassificationAnnotation
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::TextEntityExtractionAnnotation ===
    # Fields for TextEntityExtractionAnnotation
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)
    # Field: sequential_segment Type: 11 (.google.cloud.datalabeling.v1beta1.SequentialSegment)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::SequentialSegment ===
    # Fields for SequentialSegment
    # Field: start Type: 5 ()
    # Field: end Type: 5 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment ===
    # Fields for TimeSegment
    # Field: start_time_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_time_offset Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::VideoClassificationAnnotation ===
    # Fields for VideoClassificationAnnotation
    # Field: time_segment Type: 11 (.google.cloud.datalabeling.v1beta1.TimeSegment)
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::ObjectTrackingFrame ===
    # Fields for ObjectTrackingFrame
    # Field: bounding_poly Type: 11 (.google.cloud.datalabeling.v1beta1.BoundingPoly)
    # Field: normalized_bounding_poly Type: 11 (.google.cloud.datalabeling.v1beta1.NormalizedBoundingPoly)
    # Field: time_offset Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::VideoObjectTrackingAnnotation ===
    # Fields for VideoObjectTrackingAnnotation
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)
    # Field: time_segment Type: 11 (.google.cloud.datalabeling.v1beta1.TimeSegment)
    # Field: object_tracking_frames Type: 11 (.google.cloud.datalabeling.v1beta1.ObjectTrackingFrame)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::VideoEventAnnotation ===
    # Fields for VideoEventAnnotation
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)
    # Field: time_segment Type: 11 (.google.cloud.datalabeling.v1beta1.TimeSegment)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationMetadata ===
    # Fields for AnnotationMetadata
    # Field: operator_metadata Type: 11 (.google.cloud.datalabeling.v1beta1.OperatorMetadata)

# === Message: Google::Cloud::Datalabeling::V1beta1::Annotation::OperatorMetadata ===
    # Fields for OperatorMetadata
    # Field: score Type: 2 ()
    # Field: total_votes Type: 5 ()
    # Field: label_votes Type: 5 ()
    # Field: comments Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Annotation - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/annotation.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::Annotation;

    my $msg = Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation->new({
        name => $name,
        annotation_source => $annotation_source,
        annotation_value => $annotation_value,
        annotation_metadata => $annotation_metadata,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/annotation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation

Annotation for Example. Each example may have one or more annotations. For
example in image classification problem, each image might have one or more
labels. We call labels binded with this image an Annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Unique name of this annotation, format is:

projects/{project_id}/datasets/{dataset_id}/annotatedDatasets/{annotated_dataset}/examples/{example_id}/annotations/{annotation_id}

=item * C<< $msg->annotation_source() >> / C<< $msg->annotation_source($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSource>)

Output only. The source of the annotation.

=item * C<< $msg->annotation_value() >> / C<< $msg->annotation_value($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationValue>)

Output only. This is the actual annotation value, e.g classification,
bounding box values are stored here.

=item * C<< $msg->annotation_metadata() >> / C<< $msg->annotation_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationMetadata>)

Output only. Annotation metadata, including information like votes
for labels.

=item * C<< $msg->annotation_sentiment() >> / C<< $msg->annotation_sentiment($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSentiment>)

Output only. Sentiment for this annotation.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationValue

Annotation value for an example.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_classification_annotation() >> / C<< $msg->image_classification_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::ImageClassificationAnnotation>)

Annotation value for image classification case.

=item * C<< $msg->image_bounding_poly_annotation() >> / C<< $msg->image_bounding_poly_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::ImageBoundingPolyAnnotation>)

Annotation value for image bounding box, oriented bounding box
and polygon cases.

=item * C<< $msg->image_polyline_annotation() >> / C<< $msg->image_polyline_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::ImagePolylineAnnotation>)

Annotation value for image polyline cases.
Polyline here is different from BoundingPoly. It is formed by
line segments connected to each other but not closed form(Bounding Poly).
The line segments can cross each other.

=item * C<< $msg->image_segmentation_annotation() >> / C<< $msg->image_segmentation_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation>)

Annotation value for image segmentation.

=item * C<< $msg->text_classification_annotation() >> / C<< $msg->text_classification_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::TextClassificationAnnotation>)

Annotation value for text classification case.

=item * C<< $msg->text_entity_extraction_annotation() >> / C<< $msg->text_entity_extraction_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::TextEntityExtractionAnnotation>)

Annotation value for text entity extraction case.

=item * C<< $msg->video_classification_annotation() >> / C<< $msg->video_classification_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::VideoClassificationAnnotation>)

Annotation value for video classification case.

=item * C<< $msg->video_object_tracking_annotation() >> / C<< $msg->video_object_tracking_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::VideoObjectTrackingAnnotation>)

Annotation value for video object detection and tracking case.

=item * C<< $msg->video_event_annotation() >> / C<< $msg->video_event_annotation($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::VideoEventAnnotation>)

Annotation value for video event case.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::ImageClassificationAnnotation

Image classification annotation definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of image.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex

A vertex represents a 2D point in the image.
NOTE: the vertex coordinates are in the same scale as the original image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Int32>

X coordinate.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Int32>

Y coordinate.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex

A vertex represents a 2D point in the image.
NOTE: the normalized vertex coordinates are relative to the original image
and range from 0 to 1.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Float>

X coordinate.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Float>

Y coordinate.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly

A bounding polygon in the image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vertices() >> / C<< $msg->vertices($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex>)

The bounding polygon vertices.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly

Normalized bounding polygon.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex>)

The bounding polygon normalized vertices.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::ImageBoundingPolyAnnotation

Image bounding poly annotation. It represents a polygon including
bounding box in the image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_poly() >> / C<< $msg->bounding_poly($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly>)

=item * C<< $msg->normalized_bounding_poly() >> / C<< $msg->normalized_bounding_poly($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly>)

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of object in this bounding polygon.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::Polyline

A line with multiple line segments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vertices() >> / C<< $msg->vertices($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex>)

The polyline vertices.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedPolyline

Normalized polyline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex>)

The normalized polyline vertices.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::ImagePolylineAnnotation

A polyline for the image annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->polyline() >> / C<< $msg->polyline($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::Polyline>)

=item * C<< $msg->normalized_polyline() >> / C<< $msg->normalized_polyline($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedPolyline>)

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of this polyline.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation

Image segmentation annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_colors() >> / C<< $msg->annotation_colors($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation::AnnotationColorsEntry>)

The mapping between rgb color and annotation spec. The key is the rgb
color represented in format of rgb(0, 0, 0). The value is the
AnnotationSpec.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Image format.

=item * C<< $msg->image_bytes() >> / C<< $msg->image_bytes($value) >>

Type: C<Bytes>

A byte string of a full image's color map.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::TextClassificationAnnotation

Text classification annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of the text.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::TextEntityExtractionAnnotation

Text entity extraction annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of the text entities.

=item * C<< $msg->sequential_segment() >> / C<< $msg->sequential_segment($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::SequentialSegment>)

Position of the entity.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::SequentialSegment

Start and end position in a sequence (e.g. text segment).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<Int32>

Start position (inclusive).

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<Int32>

End position (exclusive).

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment

A time period inside of an example that has a time dimension (e.g. video).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time_offset() >> / C<< $msg->start_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Start of the time segment (inclusive), represented as the duration since
the example start.

=item * C<< $msg->end_time_offset() >> / C<< $msg->end_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

End of the time segment (exclusive), represented as the duration since the
example start.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::VideoClassificationAnnotation

Video classification annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_segment() >> / C<< $msg->time_segment($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment>)

The time segment of the video to which the annotation applies.

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of the segment specified by time_segment.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::ObjectTrackingFrame

Video frame level annotation for object detection and tracking.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_poly() >> / C<< $msg->bounding_poly($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly>)

=item * C<< $msg->normalized_bounding_poly() >> / C<< $msg->normalized_bounding_poly($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly>)

=item * C<< $msg->time_offset() >> / C<< $msg->time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The time offset of this frame relative to the beginning of the video.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::VideoObjectTrackingAnnotation

Video object tracking annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of the object tracked in this annotation.

=item * C<< $msg->time_segment() >> / C<< $msg->time_segment($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment>)

The time segment of the video to which object tracking applies.

=item * C<< $msg->object_tracking_frames() >> / C<< $msg->object_tracking_frames($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::ObjectTrackingFrame>)

The list of frames where this object track appears.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::VideoEventAnnotation

Video event annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

Label of the event in this annotation.

=item * C<< $msg->time_segment() >> / C<< $msg->time_segment($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment>)

The time segment of the video to which the annotation applies.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationMetadata

Additional information associated with the annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operator_metadata() >> / C<< $msg->operator_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::OperatorMetadata>)

Metadata related to human labeling.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Annotation::OperatorMetadata

General information useful for labels coming from contributors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Confidence score corresponding to a label. For examle, if 3 contributors
have answered the question and 2 of them agree on the final label, the
confidence score will be 0.67 (2/3).

=item * C<< $msg->total_votes() >> / C<< $msg->total_votes($value) >>

Type: C<Int32>

The total number of contributors that answer this question.

=item * C<< $msg->label_votes() >> / C<< $msg->label_votes($value) >>

Type: C<Int32>

The total number of contributors that choose this label.

=item * C<< $msg->comments() >> / C<< $msg->comments($value) >>

Type: C<String>

Comments from contributors.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::Annotation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
