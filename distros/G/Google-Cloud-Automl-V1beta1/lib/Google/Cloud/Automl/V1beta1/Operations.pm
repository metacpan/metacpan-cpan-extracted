package Google::Cloud::Automl::V1beta1::Operations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Io };
    eval { require Google::Cloud::Automl::V1beta1::Model };
    eval { require Google::Cloud::Automl::V1beta1::ModelEvaluation };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvb3BlcmF0aW9ucy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExGiRnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvaW8u
cHJvdG8aJ2dvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS9tb2RlbC5wcm90bxoyZ29vZ2xl
L2Nsb3VkL2F1dG9tbC92MWJldGExL21vZGVsX2V2YWx1YXRpb24ucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIoIKChFP
cGVyYXRpb25NZXRhZGF0YRJdCg5kZWxldGVfZGV0YWlscxgIIAEoCzI0Lmdvb2dsZS5jbG91
ZC5hdXRvbWwudjFiZXRhMS5EZWxldGVPcGVyYXRpb25NZXRhZGF0YUgAUg1kZWxldGVEZXRh
aWxzEm0KFGRlcGxveV9tb2RlbF9kZXRhaWxzGBggASgLMjkuZ29vZ2xlLmNsb3VkLmF1dG9t
bC52MWJldGExLkRlcGxveU1vZGVsT3BlcmF0aW9uTWV0YWRhdGFIAFISZGVwbG95TW9kZWxE
ZXRhaWxzEnMKFnVuZGVwbG95X21vZGVsX2RldGFpbHMYGSABKAsyOy5nb29nbGUuY2xvdWQu
YXV0b21sLnYxYmV0YTEuVW5kZXBsb3lNb2RlbE9wZXJhdGlvbk1ldGFkYXRhSABSFHVuZGVw
bG95TW9kZWxEZXRhaWxzEm0KFGNyZWF0ZV9tb2RlbF9kZXRhaWxzGAogASgLMjkuZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExLkNyZWF0ZU1vZGVsT3BlcmF0aW9uTWV0YWRhdGFIAFIS
Y3JlYXRlTW9kZWxEZXRhaWxzEmoKE2ltcG9ydF9kYXRhX2RldGFpbHMYDyABKAsyOC5nb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuSW1wb3J0RGF0YU9wZXJhdGlvbk1ldGFkYXRhSABS
EWltcG9ydERhdGFEZXRhaWxzEnAKFWJhdGNoX3ByZWRpY3RfZGV0YWlscxgQIAEoCzI6Lmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5CYXRjaFByZWRpY3RPcGVyYXRpb25NZXRhZGF0
YUgAUhNiYXRjaFByZWRpY3REZXRhaWxzEmoKE2V4cG9ydF9kYXRhX2RldGFpbHMYFSABKAsy
OC5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuRXhwb3J0RGF0YU9wZXJhdGlvbk1ldGFk
YXRhSABSEWV4cG9ydERhdGFEZXRhaWxzEm0KFGV4cG9ydF9tb2RlbF9kZXRhaWxzGBYgASgL
MjkuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkV4cG9ydE1vZGVsT3BlcmF0aW9uTWV0
YWRhdGFIAFISZXhwb3J0TW9kZWxEZXRhaWxzEpIBCiFleHBvcnRfZXZhbHVhdGVkX2V4YW1w
bGVzX2RldGFpbHMYGiABKAsyRS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuRXhwb3J0
RXZhbHVhdGVkRXhhbXBsZXNPcGVyYXRpb25NZXRhZGF0YUgAUh5leHBvcnRFdmFsdWF0ZWRF
eGFtcGxlc0RldGFpbHMSKQoQcHJvZ3Jlc3NfcGVyY2VudBgNIAEoBVIPcHJvZ3Jlc3NQZXJj
ZW50Ej0KEHBhcnRpYWxfZmFpbHVyZXMYAiADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IPcGFy
dGlhbEZhaWx1cmVzEjsKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWVCCQoHZGV0YWlscyIZChdEZWxldGVPcGVyYXRp
b25NZXRhZGF0YSIeChxEZXBsb3lNb2RlbE9wZXJhdGlvbk1ldGFkYXRhIiAKHlVuZGVwbG95
TW9kZWxPcGVyYXRpb25NZXRhZGF0YSIeChxDcmVhdGVNb2RlbE9wZXJhdGlvbk1ldGFkYXRh
Ih0KG0ltcG9ydERhdGFPcGVyYXRpb25NZXRhZGF0YSKnAgobRXhwb3J0RGF0YU9wZXJhdGlv
bk1ldGFkYXRhEm4KC291dHB1dF9pbmZvGAEgASgLMk0uZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MWJldGExLkV4cG9ydERhdGFPcGVyYXRpb25NZXRhZGF0YS5FeHBvcnREYXRhT3V0cHV0SW5m
b1IKb3V0cHV0SW5mbxqXAQoURXhwb3J0RGF0YU91dHB1dEluZm8SMgoUZ2NzX291dHB1dF9k
aXJlY3RvcnkYASABKAlIAFISZ2NzT3V0cHV0RGlyZWN0b3J5EjgKF2JpZ3F1ZXJ5X291dHB1
dF9kYXRhc2V0GAIgASgJSABSFWJpZ3F1ZXJ5T3V0cHV0RGF0YXNldEIRCg9vdXRwdXRfbG9j
YXRpb24iiAMKHUJhdGNoUHJlZGljdE9wZXJhdGlvbk1ldGFkYXRhElcKDGlucHV0X2NvbmZp
ZxgBIAEoCzI0Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5CYXRjaFByZWRpY3RJbnB1
dENvbmZpZ1ILaW5wdXRDb25maWcScgoLb3V0cHV0X2luZm8YAiABKAsyUS5nb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTEuQmF0Y2hQcmVkaWN0T3BlcmF0aW9uTWV0YWRhdGEuQmF0Y2hQ
cmVkaWN0T3V0cHV0SW5mb1IKb3V0cHV0SW5mbxqZAQoWQmF0Y2hQcmVkaWN0T3V0cHV0SW5m
bxIyChRnY3Nfb3V0cHV0X2RpcmVjdG9yeRgBIAEoCUgAUhJnY3NPdXRwdXREaXJlY3RvcnkS
OAoXYmlncXVlcnlfb3V0cHV0X2RhdGFzZXQYAiABKAlIAFIVYmlncXVlcnlPdXRwdXREYXRh
c2V0QhEKD291dHB1dF9sb2NhdGlvbiLbAQocRXhwb3J0TW9kZWxPcGVyYXRpb25NZXRhZGF0
YRJwCgtvdXRwdXRfaW5mbxgCIAEoCzJPLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5F
eHBvcnRNb2RlbE9wZXJhdGlvbk1ldGFkYXRhLkV4cG9ydE1vZGVsT3V0cHV0SW5mb1IKb3V0
cHV0SW5mbxpJChVFeHBvcnRNb2RlbE91dHB1dEluZm8SMAoUZ2NzX291dHB1dF9kaXJlY3Rv
cnkYASABKAlSEmdjc091dHB1dERpcmVjdG9yeSKSAgooRXhwb3J0RXZhbHVhdGVkRXhhbXBs
ZXNPcGVyYXRpb25NZXRhZGF0YRKIAQoLb3V0cHV0X2luZm8YAiABKAsyZy5nb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTEuRXhwb3J0RXZhbHVhdGVkRXhhbXBsZXNPcGVyYXRpb25NZXRh
ZGF0YS5FeHBvcnRFdmFsdWF0ZWRFeGFtcGxlc091dHB1dEluZm9SCm91dHB1dEluZm8aWwoh
RXhwb3J0RXZhbHVhdGVkRXhhbXBsZXNPdXRwdXRJbmZvEjYKF2JpZ3F1ZXJ5X291dHB1dF9k
YXRhc2V0GAIgASgJUhViaWdxdWVyeU91dHB1dERhdGFzZXRCmwEKH2NvbS5nb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTFQAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby9hdXRvbWwvYXBpdjFi
ZXRhMS9hdXRvbWxwYjthdXRvbWxwYsoCG0dvb2dsZVxDbG91ZFxBdXRvTWxcVjFiZXRhMeoC
Hkdvb2dsZTo6Q2xvdWQ6OkF1dG9NTDo6VjFiZXRhMUrOLQoHEgUOALoBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAuCgkKAgMBEgMT
ADEKCQoCAwISAxQAPAoJCgIDAxIDFQApCgkKAgMEEgMWACEKCAoBCBIDGABOCgkKAggLEgMY
AE4KCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgA4CgkKAggBEgMaADgKCAoBCBIDGwA4
CgkKAggpEgMbADgKCAoBCBIDHAA3CgkKAggtEgMcADcKVgoCBAASBB8ATgEaSiBNZXRhZGF0
YSB1c2VkIGFjcm9zcyBhbGwgbG9uZyBydW5uaW5nIG9wZXJhdGlvbnMgcmV0dXJuZWQgYnkg
QXV0b01MIEFQSS4KCgoKAwQAARIDHwgZCpwBCgQEAAgAEgQiAj0DGo0BIE91cHR1dCBvbmx5
LiBEZXRhaWxzIG9mIHNwZWNpZmljIG9wZXJhdGlvbi4gRXZlbiBpZiB0aGlzIGZpZWxkIGlz
IGVtcHR5LAogdGhlIHByZXNlbmNlIGFsbG93cyB0byBkaXN0aW5ndWlzaCBkaWZmZXJlbnQg
dHlwZXMgb2Ygb3BlcmF0aW9ucy4KCgwKBQQACAABEgMiCA8KLQoEBAACABIDJAQvGiAgRGV0
YWlscyBvZiBhIERlbGV0ZSBvcGVyYXRpb24uCgoMCgUEAAIABhIDJAQbCgwKBQQAAgABEgMk
HCoKDAoFBAACAAMSAyQtLgoyCgQEAAIBEgMnBDsaJSBEZXRhaWxzIG9mIGEgRGVwbG95TW9k
ZWwgb3BlcmF0aW9uLgoKDAoFBAACAQYSAycEIAoMCgUEAAIBARIDJyE1CgwKBQQAAgEDEgMn
ODoKNQoEBAACAhIDKgQ/GiggRGV0YWlscyBvZiBhbiBVbmRlcGxveU1vZGVsIG9wZXJhdGlv
bi4KCgwKBQQAAgIGEgMqBCIKDAoFBAACAgESAyojOQoMCgUEAAICAxIDKjw+CjAKBAQAAgMS
Ay0EOxojIERldGFpbHMgb2YgQ3JlYXRlTW9kZWwgb3BlcmF0aW9uLgoKDAoFBAACAwYSAy0E
IAoMCgUEAAIDARIDLSE1CgwKBQQAAgMDEgMtODoKLwoEBAACBBIDMAQ5GiIgRGV0YWlscyBv
ZiBJbXBvcnREYXRhIG9wZXJhdGlvbi4KCgwKBQQAAgQGEgMwBB8KDAoFBAACBAESAzAgMwoM
CgUEAAIEAxIDMDY4CjEKBAQAAgUSAzMEPRokIERldGFpbHMgb2YgQmF0Y2hQcmVkaWN0IG9w
ZXJhdGlvbi4KCgwKBQQAAgUGEgMzBCEKDAoFBAACBQESAzMiNwoMCgUEAAIFAxIDMzo8Ci8K
BAQAAgYSAzYEORoiIERldGFpbHMgb2YgRXhwb3J0RGF0YSBvcGVyYXRpb24uCgoMCgUEAAIG
BhIDNgQfCgwKBQQAAgYBEgM2IDMKDAoFBAACBgMSAzY2OAowCgQEAAIHEgM5BDsaIyBEZXRh
aWxzIG9mIEV4cG9ydE1vZGVsIG9wZXJhdGlvbi4KCgwKBQQAAgcGEgM5BCAKDAoFBAACBwES
AzkhNQoMCgUEAAIHAxIDOTg6CjwKBAQAAggSAzwEVBovIERldGFpbHMgb2YgRXhwb3J0RXZh
bHVhdGVkRXhhbXBsZXMgb3BlcmF0aW9uLgoKDAoFBAACCAYSAzwELAoMCgUEAAIIARIDPC1O
CgwKBQQAAggDEgM8UVMKWAoEBAACCRIDQQIeGksgT3V0cHV0IG9ubHkuIFByb2dyZXNzIG9m
IG9wZXJhdGlvbi4gUmFuZ2U6IFswLCAxMDBdLgogTm90IHVzZWQgY3VycmVudGx5LgoKDAoF
BAACCQUSA0ECBwoMCgUEAAIJARIDQQgYCgwKBQQAAgkDEgNBGx0KzwEKBAQAAgoSA0cCMhrB
ASBPdXRwdXQgb25seS4gUGFydGlhbCBmYWlsdXJlcyBlbmNvdW50ZXJlZC4KIEUuZy4gc2lu
Z2xlIGZpbGVzIHRoYXQgY291bGRuJ3QgYmUgcmVhZC4KIFRoaXMgZmllbGQgc2hvdWxkIG5l
dmVyIGV4Y2VlZCAyMCBlbnRyaWVzLgogU3RhdHVzIGRldGFpbHMgZmllbGQgd2lsbCBjb250
YWluIHN0YW5kYXJkIEdDUCBlcnJvciBkZXRhaWxzLgoKDAoFBAACCgQSA0cCCgoMCgUEAAIK
BhIDRwscCgwKBQQAAgoBEgNHHS0KDAoFBAACCgMSA0cwMQpACgQEAAILEgNKAiwaMyBPdXRw
dXQgb25seS4gVGltZSB3aGVuIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoMCgUEAAIL
BhIDSgIbCgwKBQQAAgsBEgNKHCcKDAoFBAACCwMSA0oqKwpSCgQEAAIMEgNNAiwaRSBPdXRw
dXQgb25seS4gVGltZSB3aGVuIHRoZSBvcGVyYXRpb24gd2FzIHVwZGF0ZWQgZm9yIHRoZSBs
YXN0IHRpbWUuCgoMCgUEAAIMBhIDTQIbCgwKBQQAAgwBEgNNHCcKDAoFBAACDAMSA00qKwpJ
CgIEARIEUQBTARo9IERldGFpbHMgb2Ygb3BlcmF0aW9ucyB0aGF0IHBlcmZvcm0gZGVsZXRl
cyBvZiBhbnkgZW50aXRpZXMuCgoKCgMEAQESA1EIHwovCgIEAhIEVgBYARojIERldGFpbHMg
b2YgRGVwbG95TW9kZWwgb3BlcmF0aW9uLgoKCgoDBAIBEgNWCCQKMQoCBAMSBFsAXQEaJSBE
ZXRhaWxzIG9mIFVuZGVwbG95TW9kZWwgb3BlcmF0aW9uLgoKCgoDBAMBEgNbCCYKLwoCBAQS
BGAAYgEaIyBEZXRhaWxzIG9mIENyZWF0ZU1vZGVsIG9wZXJhdGlvbi4KCgoKAwQEARIDYAgk
Ci4KAgQFEgRlAGcBGiIgRGV0YWlscyBvZiBJbXBvcnREYXRhIG9wZXJhdGlvbi4KCgoKAwQF
ARIDZQgjCi4KAgQGEgRqAH0BGiIgRGV0YWlscyBvZiBFeHBvcnREYXRhIG9wZXJhdGlvbi4K
CgoKAwQGARIDaggjCoQBCgQEBgMAEgRuAnkDGnYgRnVydGhlciBkZXNjcmliZXMgdGhpcyBl
eHBvcnQgZGF0YSdzIG91dHB1dC4KIFN1cHBsZW1lbnRzCiBbT3V0cHV0Q29uZmlnXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuT3V0cHV0Q29uZmlnXS4KCgwKBQQGAwABEgNuCh4K
TAoGBAYDAAgAEgRwBHgFGjwgVGhlIG91dHB1dCBsb2NhdGlvbiB0byB3aGljaCB0aGUgZXhw
b3J0ZWQgZGF0YSBpcyB3cml0dGVuLgoKDgoHBAYDAAgAARIDcAoZCncKBgQGAwACABIDcwYm
GmggVGhlIGZ1bGwgcGF0aCBvZiB0aGUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgZGlyZWN0b3J5
IGNyZWF0ZWQsIGludG8gd2hpY2gKIHRoZSBleHBvcnRlZCBkYXRhIGlzIHdyaXR0ZW4uCgoO
CgcEBgMAAgAFEgNzBgwKDgoHBAYDAAIAARIDcw0hCg4KBwQGAwACAAMSA3MkJQqKAQoGBAYD
AAIBEgN3BikaeyBUaGUgcGF0aCBvZiB0aGUgQmlnUXVlcnkgZGF0YXNldCBjcmVhdGVkLCBp
biBicTovL3Byb2plY3RJZC5icURhdGFzZXRJZAogZm9ybWF0LCBpbnRvIHdoaWNoIHRoZSBl
eHBvcnRlZCBkYXRhIGlzIHdyaXR0ZW4uCgoOCgcEBgMAAgEFEgN3BgwKDgoHBAYDAAIBARID
dw0kCg4KBwQGAwACAQMSA3cnKApVCgQEBgIAEgN8AicaSCBPdXRwdXQgb25seS4gSW5mb3Jt
YXRpb24gZnVydGhlciBkZXNjcmliaW5nIHRoaXMgZXhwb3J0IGRhdGEncyBvdXRwdXQuCgoM
CgUEBgIABhIDfAIWCgwKBQQGAgABEgN8FyIKDAoFBAYCAAMSA3wlJgoyCgIEBxIGgAEAmAEB
GiQgRGV0YWlscyBvZiBCYXRjaFByZWRpY3Qgb3BlcmF0aW9uLgoKCwoDBAcBEgSAAQglCqIB
CgQEBwMAEgaFAQKQAQMakQEgRnVydGhlciBkZXNjcmliZXMgdGhpcyBiYXRjaCBwcmVkaWN0
J3Mgb3V0cHV0LgogU3VwcGxlbWVudHMKCiBbQmF0Y2hQcmVkaWN0T3V0cHV0Q29uZmlnXVtn
b29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQmF0Y2hQcmVkaWN0T3V0cHV0Q29uZmlnXS4K
Cg0KBQQHAwABEgSFAQogClAKBgQHAwAIABIGhwEEjwEFGj4gVGhlIG91dHB1dCBsb2NhdGlv
biBpbnRvIHdoaWNoIHByZWRpY3Rpb24gb3V0cHV0IGlzIHdyaXR0ZW4uCgoPCgcEBwMACAAB
EgSHAQoZCnwKBgQHAwACABIEigEGJhpsIFRoZSBmdWxsIHBhdGggb2YgdGhlIEdvb2dsZSBD
bG91ZCBTdG9yYWdlIGRpcmVjdG9yeSBjcmVhdGVkLCBpbnRvIHdoaWNoCiB0aGUgcHJlZGlj
dGlvbiBvdXRwdXQgaXMgd3JpdHRlbi4KCg8KBwQHAwACAAUSBIoBBgwKDwoHBAcDAAIAARIE
igENIQoPCgcEBwMAAgADEgSKASQlCo8BCgYEBwMAAgESBI4BBikafyBUaGUgcGF0aCBvZiB0
aGUgQmlnUXVlcnkgZGF0YXNldCBjcmVhdGVkLCBpbiBicTovL3Byb2plY3RJZC5icURhdGFz
ZXRJZAogZm9ybWF0LCBpbnRvIHdoaWNoIHRoZSBwcmVkaWN0aW9uIG91dHB1dCBpcyB3cml0
dGVuLgoKDwoHBAcDAAIBBRIEjgEGDAoPCgcEBwMAAgEBEgSOAQ0kCg8KBwQHAwACAQMSBI4B
JygKaQoEBAcCABIElAECKxpbIE91dHB1dCBvbmx5LiBUaGUgaW5wdXQgY29uZmlnIHRoYXQg
d2FzIGdpdmVuIHVwb24gc3RhcnRpbmcgdGhpcwogYmF0Y2ggcHJlZGljdCBvcGVyYXRpb24u
CgoNCgUEBwIABhIElAECGQoNCgUEBwIAARIElAEaJgoNCgUEBwIAAxIElAEpKgpYCgQEBwIB
EgSXAQIpGkogT3V0cHV0IG9ubHkuIEluZm9ybWF0aW9uIGZ1cnRoZXIgZGVzY3JpYmluZyB0
aGlzIGJhdGNoIHByZWRpY3QncyBvdXRwdXQuCgoNCgUEBwIBBhIElwECGAoNCgUEBwIBARIE
lwEZJAoNCgUEBwIBAxIElwEnKAoxCgIECBIGmwEAqQEBGiMgRGV0YWlscyBvZiBFeHBvcnRN
b2RlbCBvcGVyYXRpb24uCgoLCgMECAESBJsBCCQKnwEKBAQIAwASBqABAqQBAxqOASBGdXJ0
aGVyIGRlc2NyaWJlcyB0aGUgb3V0cHV0IG9mIG1vZGVsIGV4cG9ydC4KIFN1cHBsZW1lbnRz
CgogW01vZGVsRXhwb3J0T3V0cHV0Q29uZmlnXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuTW9kZWxFeHBvcnRPdXRwdXRDb25maWddLgoKDQoFBAgDAAESBKABCh8KdgoGBAgDAAIA
EgSjAQQkGmYgVGhlIGZ1bGwgcGF0aCBvZiB0aGUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgZGly
ZWN0b3J5IGNyZWF0ZWQsIGludG8gd2hpY2gKIHRoZSBtb2RlbCB3aWxsIGJlIGV4cG9ydGVk
LgoKDwoHBAgDAAIABRIEowEECgoPCgcECAMAAgABEgSjAQsfCg8KBwQIAwACAAMSBKMBIiMK
XQoEBAgCABIEqAECKBpPIE91dHB1dCBvbmx5LiBJbmZvcm1hdGlvbiBmdXJ0aGVyIGRlc2Ny
aWJpbmcgdGhlIG91dHB1dCBvZiB0aGlzIG1vZGVsCiBleHBvcnQuCgoNCgUECAIABhIEqAEC
FwoNCgUECAIAARIEqAEYIwoNCgUECAIAAxIEqAEmJwo3CgIECRIGrAEAugEBGikgRGV0YWls
cyBvZiBFdmFsdWF0ZWRFeGFtcGxlcyBvcGVyYXRpb24uCgoLCgMECQESBKwBCDAKyAEKBAQJ
AwASBrEBArUBAxq3ASBGdXJ0aGVyIGRlc2NyaWJlcyB0aGUgb3V0cHV0IG9mIHRoZSBldmFs
dWF0ZWQgZXhhbXBsZXMgZXhwb3J0LgogU3VwcGxlbWVudHMKCiBbRXhwb3J0RXZhbHVhdGVk
RXhhbXBsZXNPdXRwdXRDb25maWddW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5FeHBv
cnRFdmFsdWF0ZWRFeGFtcGxlc091dHB1dENvbmZpZ10uCgoNCgUECQMAARIEsQEKKwqiAQoG
BAkDAAIAEgS0AQQnGpEBIFRoZSBwYXRoIG9mIHRoZSBCaWdRdWVyeSBkYXRhc2V0IGNyZWF0
ZWQsIGluIGJxOi8vcHJvamVjdElkLmJxRGF0YXNldElkCiBmb3JtYXQsIGludG8gd2hpY2gg
dGhlIG91dHB1dCBvZiBleHBvcnQgZXZhbHVhdGVkIGV4YW1wbGVzIGlzIHdyaXR0ZW4uCgoP
CgcECQMAAgAFEgS0AQQKCg8KBwQJAwACAAESBLQBCyIKDwoHBAkDAAIAAxIEtAElJgpqCgQE
CQIAEgS5AQI0GlwgT3V0cHV0IG9ubHkuIEluZm9ybWF0aW9uIGZ1cnRoZXIgZGVzY3JpYmlu
ZyB0aGUgb3V0cHV0IG9mIHRoaXMgZXZhbHVhdGVkCiBleGFtcGxlcyBleHBvcnQuCgoNCgUE
CQIABhIEuQECIwoNCgUECQIAARIEuQEkLwoNCgUECQIAAxIEuQEyM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Operations::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: delete_details Type: 11 (.google.cloud.automl.v1beta1.DeleteOperationMetadata)
    # Field: deploy_model_details Type: 11 (.google.cloud.automl.v1beta1.DeployModelOperationMetadata)
    # Field: undeploy_model_details Type: 11 (.google.cloud.automl.v1beta1.UndeployModelOperationMetadata)
    # Field: create_model_details Type: 11 (.google.cloud.automl.v1beta1.CreateModelOperationMetadata)
    # Field: import_data_details Type: 11 (.google.cloud.automl.v1beta1.ImportDataOperationMetadata)
    # Field: batch_predict_details Type: 11 (.google.cloud.automl.v1beta1.BatchPredictOperationMetadata)
    # Field: export_data_details Type: 11 (.google.cloud.automl.v1beta1.ExportDataOperationMetadata)
    # Field: export_model_details Type: 11 (.google.cloud.automl.v1beta1.ExportModelOperationMetadata)
    # Field: export_evaluated_examples_details Type: 11 (.google.cloud.automl.v1beta1.ExportEvaluatedExamplesOperationMetadata)
    # Field: progress_percent Type: 5 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Automl::V1beta1::Operations::DeleteOperationMetadata ===
    # Fields for DeleteOperationMetadata

# === Message: Google::Cloud::Automl::V1beta1::Operations::DeployModelOperationMetadata ===
    # Fields for DeployModelOperationMetadata

# === Message: Google::Cloud::Automl::V1beta1::Operations::UndeployModelOperationMetadata ===
    # Fields for UndeployModelOperationMetadata

# === Message: Google::Cloud::Automl::V1beta1::Operations::CreateModelOperationMetadata ===
    # Fields for CreateModelOperationMetadata

# === Message: Google::Cloud::Automl::V1beta1::Operations::ImportDataOperationMetadata ===
    # Fields for ImportDataOperationMetadata

# === Message: Google::Cloud::Automl::V1beta1::Operations::ExportDataOperationMetadata ===
    # Fields for ExportDataOperationMetadata
    # Field: output_info Type: 11 (.google.cloud.automl.v1beta1.ExportDataOperationMetadata.ExportDataOutputInfo)

# === Message: Google::Cloud::Automl::V1beta1::Operations::BatchPredictOperationMetadata ===
    # Fields for BatchPredictOperationMetadata
    # Field: input_config Type: 11 (.google.cloud.automl.v1beta1.BatchPredictInputConfig)
    # Field: output_info Type: 11 (.google.cloud.automl.v1beta1.BatchPredictOperationMetadata.BatchPredictOutputInfo)

# === Message: Google::Cloud::Automl::V1beta1::Operations::ExportModelOperationMetadata ===
    # Fields for ExportModelOperationMetadata
    # Field: output_info Type: 11 (.google.cloud.automl.v1beta1.ExportModelOperationMetadata.ExportModelOutputInfo)

# === Message: Google::Cloud::Automl::V1beta1::Operations::ExportEvaluatedExamplesOperationMetadata ===
    # Fields for ExportEvaluatedExamplesOperationMetadata
    # Field: output_info Type: 11 (.google.cloud.automl.v1beta1.ExportEvaluatedExamplesOperationMetadata.ExportEvaluatedExamplesOutputInfo)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Operations - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Operations;

    my $msg = Google::Cloud::Automl::V1beta1::Operations::OperationMetadata->new({
        delete_details => $delete_details,
        deploy_model_details => $deploy_model_details,
        undeploy_model_details => $undeploy_model_details,
        create_model_details => $create_model_details,
    });

    # Read or update a field
    my $val = $msg->delete_details();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Operations::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Operations::OperationMetadata

Metadata used across all long running operations returned by AutoML API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->delete_details() >> / C<< $msg->delete_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::DeleteOperationMetadata>)

Details of a Delete operation.

=item * C<< $msg->deploy_model_details() >> / C<< $msg->deploy_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::DeployModelOperationMetadata>)

Details of a DeployModel operation.

=item * C<< $msg->undeploy_model_details() >> / C<< $msg->undeploy_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::UndeployModelOperationMetadata>)

Details of an UndeployModel operation.

=item * C<< $msg->create_model_details() >> / C<< $msg->create_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::CreateModelOperationMetadata>)

Details of CreateModel operation.

=item * C<< $msg->import_data_details() >> / C<< $msg->import_data_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ImportDataOperationMetadata>)

Details of ImportData operation.

=item * C<< $msg->batch_predict_details() >> / C<< $msg->batch_predict_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::BatchPredictOperationMetadata>)

Details of BatchPredict operation.

=item * C<< $msg->export_data_details() >> / C<< $msg->export_data_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ExportDataOperationMetadata>)

Details of ExportData operation.

=item * C<< $msg->export_model_details() >> / C<< $msg->export_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ExportModelOperationMetadata>)

Details of ExportModel operation.

=item * C<< $msg->export_evaluated_examples_details() >> / C<< $msg->export_evaluated_examples_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ExportEvaluatedExamplesOperationMetadata>)

Details of ExportEvaluatedExamples operation.

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Output only. Progress of operation. Range: [0, 100].
Not used currently.

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Partial failures encountered.
E.g. single files that couldn't be read.
This field should never exceed 20 entries.
Status details field will contain standard GCP error details.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the operation was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the operation was updated for the last time.

=back

=head2 Google::Cloud::Automl::V1beta1::Operations::DeleteOperationMetadata

Details of operations that perform deletes of any entities.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Operations::DeployModelOperationMetadata

Details of DeployModel operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Operations::UndeployModelOperationMetadata

Details of UndeployModel operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Operations::CreateModelOperationMetadata

Details of CreateModel operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Operations::ImportDataOperationMetadata

Details of ImportData operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Operations::ExportDataOperationMetadata

Details of ExportData operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ExportDataOperationMetadata::ExportDataOutputInfo>)

Output only. Information further describing this export data's output.

=back

=head2 Google::Cloud::Automl::V1beta1::Operations::BatchPredictOperationMetadata

Details of BatchPredict operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Io::BatchPredictInputConfig>)

Output only. The input config that was given upon starting this
batch predict operation.

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::BatchPredictOperationMetadata::BatchPredictOutputInfo>)

Output only. Information further describing this batch predict's output.

=back

=head2 Google::Cloud::Automl::V1beta1::Operations::ExportModelOperationMetadata

Details of ExportModel operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ExportModelOperationMetadata::ExportModelOutputInfo>)

Output only. Information further describing the output of this model
export.

=back

=head2 Google::Cloud::Automl::V1beta1::Operations::ExportEvaluatedExamplesOperationMetadata

Details of EvaluatedExamples operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Operations::ExportEvaluatedExamplesOperationMetadata::ExportEvaluatedExamplesOutputInfo>)

Output only. Information further describing the output of this evaluated
examples export.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
