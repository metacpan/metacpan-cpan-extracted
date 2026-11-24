package Google::Cloud::Backupdr::V1::Autoprotectionpolicy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYXV0b3Byb3RlY3Rpb25wb2xpY3kucHJvdG8S
GGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byLGBwoUQXV0b1Byb3RlY3Rpb25Qb2xpY3kSGgoEbmFtZRgB
IAEoCUIG4EED4EEIUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0
aW9uEl8KE2JhY2t1cF9wbGFuX2RldGFpbHMYAyADKAsyKi5nb29nbGUuY2xvdWQuYmFja3Vw
ZHIudjEuQmFja3VwUGxhbkRldGFpbEID4EECUhFiYWNrdXBQbGFuRGV0YWlscxJDCghjcml0
ZXJpYRgEIAEoCzIiLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5Dcml0ZXJpYUID4EECUghj
cml0ZXJpYRJPCgVzdGF0ZRgFIAEoDjI0Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5BdXRv
UHJvdGVjdGlvblBvbGljeS5TdGF0ZUID4EEDUgVzdGF0ZRISCgRldGFnGAYgASgJUgRldGFn
ElYKD2JpbmRpbmdfc3VtbWFyeRgHIAEoCzIoLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5C
aW5kaW5nU3VtbWFyeUID4EEDUg5iaW5kaW5nU3VtbWFyeRJyChlwb2xpY3lfZXZhbHVhdGlv
bl9zdW1tYXJ5GAggASgLMjEuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLlBvbGljeUV2YWx1
YXRpb25TdW1tYXJ5QgPgQQNSF3BvbGljeUV2YWx1YXRpb25TdW1tYXJ5EkAKC2NyZWF0ZV90
aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EkAKC3VwZGF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
Ugp1cGRhdGVUaW1lIlQKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJ
TkcQARIKCgZBQ1RJVkUQAhIMCghVUERBVElORxADEgwKCERFTEVUSU5HEAQ6uQHqQbUBCixi
YWNrdXBkci5nb29nbGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeRJXcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNpZXMv
e2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9KhZhdXRvUHJvdGVjdGlvblBvbGljaWVzMhRhdXRv
UHJvdGVjdGlvblBvbGljeSKJAQoQQmFja3VwUGxhbkRldGFpbBIoCg1yZXNvdXJjZV90eXBl
GAEgASgJQgPgQQJSDHJlc291cmNlVHlwZRJLCgtiYWNrdXBfcGxhbhgCIAEoCUIq4EEC+kEk
CiJiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9CYWNrdXBQbGFuUgpiYWNrdXBQbGFuIm0KCENy
aXRlcmlhEmEKE21hdGNoaW5nX2NvbmRpdGlvbnMYASADKAsyKy5nb29nbGUuY2xvdWQuYmFj
a3VwZHIudjEuTWF0Y2hpbmdDb25kaXRpb25CA+BBAlISbWF0Y2hpbmdDb25kaXRpb25zIngK
EU1hdGNoaW5nQ29uZGl0aW9uElYKD2xhYmVsX2NvbmRpdGlvbhgBIAEoCzImLmdvb2dsZS5j
bG91ZC5iYWNrdXBkci52MS5LZXlWYWx1ZVBhaXJCA+BBAUgAUg5sYWJlbENvbmRpdGlvbkIL
Cgljb25kaXRpb24izgEKF1BvbGljeUV2YWx1YXRpb25TdW1tYXJ5EjsKF21hdGNoaW5nX3Jl
c291cmNlX2NvdW50GAEgASgDQgPgQQNSFW1hdGNoaW5nUmVzb3VyY2VDb3VudBI9Chhwcm90
ZWN0ZWRfcmVzb3VyY2VfY291bnQYAiABKANCA+BBA1IWcHJvdGVjdGVkUmVzb3VyY2VDb3Vu
dBI3ChVmYWlsZWRfcmVzb3VyY2VfY291bnQYAyABKANCA+BBA1ITZmFpbGVkUmVzb3VyY2VD
b3VudCI6Cg5CaW5kaW5nU3VtbWFyeRIoCg1wcm9qZWN0X2NvdW50GAEgASgDQgPgQQNSDHBy
b2plY3RDb3VudCJCCgxLZXlWYWx1ZVBhaXISFQoDa2V5GAEgASgJQgPgQQJSA2tleRIbCgZ2
YWx1ZXMYAiADKAlCA+BBAlIGdmFsdWVzIr0CCiFDcmVhdGVBdXRvUHJvdGVjdGlvblBvbGlj
eVJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlz
LmNvbS9Mb2NhdGlvblIGcGFyZW50Ej4KGWF1dG9fcHJvdGVjdGlvbl9wb2xpY3lfaWQYAiAB
KAlCA+BBAlIWYXV0b1Byb3RlY3Rpb25Qb2xpY3lJZBJpChZhdXRvX3Byb3RlY3Rpb25fcG9s
aWN5GAMgASgLMi4uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkF1dG9Qcm90ZWN0aW9uUG9s
aWN5QgPgQQJSFGF1dG9Qcm90ZWN0aW9uUG9saWN5EioKCnJlcXVlc3RfaWQYBCABKAlCC+KM
z9cIAggB4EEBUglyZXF1ZXN0SWQiagoeR2V0QXV0b1Byb3RlY3Rpb25Qb2xpY3lSZXF1ZXN0
EkgKBG5hbWUYASABKAlCNOBBAvpBLgosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0b1By
b3RlY3Rpb25Qb2xpY3lSBG5hbWUi/AEKIVVwZGF0ZUF1dG9Qcm90ZWN0aW9uUG9saWN5UmVx
dWVzdBJpChZhdXRvX3Byb3RlY3Rpb25fcG9saWN5GAEgASgLMi4uZ29vZ2xlLmNsb3VkLmJh
Y2t1cGRyLnYxLkF1dG9Qcm90ZWN0aW9uUG9saWN5QgPgQQJSFGF1dG9Qcm90ZWN0aW9uUG9s
aWN5EkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID
4EEBUgp1cGRhdGVNYXNrEioKCnJlcXVlc3RfaWQYAyABKAlCC+KMz9cIAggB4EEBUglyZXF1
ZXN0SWQisgEKIURlbGV0ZUF1dG9Qcm90ZWN0aW9uUG9saWN5UmVxdWVzdBJICgRuYW1lGAEg
ASgJQjTgQQL6QS4KLGJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0F1dG9Qcm90ZWN0aW9uUG9s
aWN5UgRuYW1lEhcKBGV0YWcYAiABKAlCA+BBAVIEZXRhZxIqCgpyZXF1ZXN0X2lkGAMgASgJ
QgvijM/XCAIIAeBBAVIJcmVxdWVzdElkIukBCiFMaXN0QXV0b1Byb3RlY3Rpb25Qb2xpY2ll
c1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlz
LmNvbS9Mb2NhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6
ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlC
A+BBAVIGZmlsdGVyEh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnki3QEKIkxpc3RB
dXRvUHJvdGVjdGlvblBvbGljaWVzUmVzcG9uc2USaAoYYXV0b19wcm90ZWN0aW9uX3BvbGlj
aWVzGAEgAygLMi4uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkF1dG9Qcm90ZWN0aW9uUG9s
aWN5UhZhdXRvUHJvdGVjdGlvblBvbGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVIN
bmV4dFBhZ2VUb2tlbhIlCgt1bnJlYWNoYWJsZRgDIAMoCUID4EEGUgt1bnJlYWNoYWJsZULJ
AQocY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MUIZQXV0b1Byb3RlY3Rpb25Qb2xpY3lQ
cm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxL2JhY2t1cGRycGI7
YmFja3VwZHJwYqoCGEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5WMcoCGEdvb2dsZVxDbG91ZFxC
YWNrdXBEUlxWMeoCG0dvb2dsZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMUq1XwoHEgUOAMsCAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgAp
CgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGAA1
CgkKAgglEgMYADUKCAoBCBIDGQBPCgkKAggLEgMZAE8KCAoBCBIDGgAiCgkKAggKEgMaACIK
CAoBCBIDGwA6CgkKAggIEgMbADoKCAoBCBIDHAA1CgkKAggBEgMcADUKCAoBCBIDHQA1CgkK
AggpEgMdADUKCAoBCBIDHgA0CgkKAggtEgMeADQKrwIKAgQAEgQkAGkBGqICIEFuIEF1dG9w
cm90ZWN0aW9uUG9saWN5IGlzIGEgcG9saWN5IHJlc291cmNlIGRlc2lnbmVkIHRvIGF1dG9t
YXRlIGJhY2t1cAogbWFuYWdlbWVudCwgbW92aW5nIGZyb20gbWFudWFsIHBlci1yZXNvdXJj
ZSBwcm90ZWN0aW9uIHRvIGEgYnVsayBhcHByb2FjaC4KIFRoZSBwb2xpY3kgZHluYW1pY2Fs
bHkgZGlzY292ZXJzIGFuZCBhcHBsaWVzIGEgc3BlY2lmaWVkIGJhY2t1cCBwbGFuIHRvIGFs
bAogZWxpZ2libGUgcmVzb3VyY2VzIHRoYXQgbWF0Y2ggaXRzIGRlZmluZWQgc2NvcGUgYW5k
IGNyaXRlcmlhLgoKCgoDBAABEgMkCBwKCwoDBAAHEgQlAioECg0KBQQAB50IEgQlAioECjUK
BAQABAASBC0CPAMaJyBUaGUgc3RhdGUgb2YgYW4gQXV0b1Byb3RlY3Rpb25Qb2xpY3kuCgoM
CgUEAAQAARIDLQcMCjgKBgQABAACABIDLwQaGikgVGhlIHN0YXRlIG9mIHRoZSBwb2xpY3kg
aXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMvBBUKDgoHBAAEAAIAAhIDLxgZCi0KBgQA
BAACARIDMgQRGh4gVGhlIHBvbGljeSBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARID
MgQMCg4KBwQABAACAQISAzIPEApICgYEAAQAAgISAzUEDxo5IFRoZSBwb2xpY3kgaXMgYWN0
aXZlIGFuZCBwcm90ZWN0aW5nIG1hdGNoaW5nIHJlc291cmNlcy4KCg4KBwQABAACAgESAzUE
CgoOCgcEAAQAAgICEgM1DQ4KLQoGBAAEAAIDEgM4BBEaHiBUaGUgcG9saWN5IGlzIGJlaW5n
IHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgM4BAwKDgoHBAAEAAIDAhIDOA8QCi0KBgQABAACBBID
OwQRGh4gVGhlIHBvbGljeSBpcyBiZWluZyBkZWxldGVkLgoKDgoHBAAEAAIEARIDOwQMCg4K
BwQABAACBAISAzsPEAq8AQoEBAACABIEQQJEBBqtASBPdXRwdXQgb25seS4gSWRlbnRpZmll
ci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEF1dG9Qcm90ZWN0aW9uUG9saWN5LgogRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRvUHJv
dGVjdGlvblBvbGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9saWN5fWAKCgwKBQQAAgAFEgNB
AggKDAoFBAACAAESA0EJDQoMCgUEAAIAAxIDQRARCg0KBQQAAgAIEgRBEkQDCg8KCAQAAgAI
nAgAEgNCBC0KDwoIBAACAAicCAESA0MELApnCgQEAAIBEgNIAkIaWiBPcHRpb25hbC4gQSBk
ZXNjcmlwdGlvbiBvZiB0aGUgcG9saWN5LiBUaGUgZGVzY3JpcHRpb24gbXVzdCBiZSBhdCBt
b3N0IDIwNDgKIGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDSAIICgwKBQQAAgEBEgNICRQKDAoF
BAACAQMSA0gXGAoMCgUEAAIBCBIDSBlBCg8KCAQAAgEInAgAEgNIGkAKSQoEBAACAhIESwJM
Lxo7IFJlcXVpcmVkLiBUaGUgYmFja3VwIHBsYW4gZGV0YWlscyBmb3IgbWF0Y2hpbmcgcmVz
b3VyY2VzLgoKDAoFBAACAgQSA0sCCgoMCgUEAAICBhIDSwsbCgwKBQQAAgIBEgNLHC8KDAoF
BAACAgMSA0syMwoMCgUEAAICCBIDTAYuCg8KCAQAAgIInAgAEgNMBy0KPQoEBAACAxIDTwJB
GjAgUmVxdWlyZWQuIFRoZSBjcml0ZXJpYSBmb3IgbWF0Y2hpbmcgcmVzb3VyY2VzLgoKDAoF
BAACAwYSA08CCgoMCgUEAAIDARIDTwsTCgwKBQQAAgMDEgNPFhcKDAoFBAACAwgSA08YQAoP
CggEAAIDCJwIABIDTxk/CkoKBAQAAgQSA1ICPho9IE91dHB1dCBvbmx5LiBUaGUgY3VycmVu
dCBzdGF0ZSBvZiB0aGUgQXV0b1Byb3RlY3Rpb25Qb2xpY3kuCgoMCgUEAAIEBhIDUgIHCgwK
BQQAAgQBEgNSCA0KDAoFBAACBAMSA1IQEQoMCgUEAAIECBIDUhI9Cg8KCAQAAgQInAgAEgNS
EzwKdQoEBAACBRIDVgISGmggT3V0cHV0IG9ubHkuIFRoZSBldGFnIGZvciB0aGUgcG9saWN5
LgogSWYgdGhpcyBpcyBwcm92aWRlZCBvbiB1cGRhdGUsIGl0IG11c3QgbWF0Y2ggdGhlIHNl
cnZlcidzIGV0YWcuCgoMCgUEAAIFBRIDVgIICgwKBQQAAgUBEgNWCQ0KDAoFBAACBQMSA1YQ
EQppCgQEAAIGEgRaAlsyGlsgT3V0cHV0IG9ubHkuIFN1bW1hcnkgb2YgdG90YWwgY291bnQg
b2YgZGlmZmVyZW50IGNvbnRhaW5lcnMgY292ZXJlZCB0aHJvdWdoCiB0aGlzIHBvbGljeS4K
CgwKBQQAAgYGEgNaAhAKDAoFBAACBgESA1oRIAoMCgUEAAIGAxIDWiMkCgwKBQQAAgYIEgNb
BjEKDwoIBAACBgicCAASA1sHMApjCgQEAAIHEgRfAmAyGlUgT3V0cHV0IG9ubHkuIFN1bW1h
cnkgb2YgbGFzdCBwb2xpY3kgZXZhbHVhdGlvbiB3aGVuIGpvYiB3YXMgcnVuIHBlcgogd29y
a2xvYWQgdHlwZS4KCgwKBQQAAgcGEgNfAhkKDAoFBAACBwESA18aMwoMCgUEAAIHAxIDXzY3
CgwKBQQAAgcIEgNgBjEKDwoIBAACBwicCAASA2AHMApHCgQEAAIIEgRjAmQyGjkgT3V0cHV0
IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgcG9saWN5IHdhcyBjcmVhdGVkLgoKDAoF
BAACCAYSA2MCGwoMCgUEAAIIARIDYxwnCgwKBQQAAggDEgNjKisKDAoFBAACCAgSA2QGMQoP
CggEAAIICJwIABIDZAcwCkwKBAQAAgkSBGcCaDIaPiBPdXRwdXQgb25seS4gVGhlIHRpbWVz
dGFtcCB3aGVuIHRoZSBwb2xpY3kgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgkGEgNnAhsK
DAoFBAACCQESA2ccJwoMCgUEAAIJAxIDZyosCgwKBQQAAgkIEgNoBjEKDwoIBAACCQicCAAS
A2gHMApDCgIEARIEbAB8ARo3IEJhY2t1cFBsYW5EZXRhaWwgZGVmaW5lcyBjb25maWd1cmF0
aW9uIG9mIHByb3RlY3Rpb24uCgoKCgMEAQESA2wIGArEAQoEBAECABIDcAJEGrYBIFJlcXVp
cmVkLiBUaGUgdHlwZSBvZiByZXNvdXJjZSB0aGF0IHRoaXMgcG9saWN5IHdpbGwgYXV0b21h
dGljYWxseSBwcm90ZWN0LgogQWxsb3dlZCB2YWx1ZXMgYXJlLCBgY29tcHV0ZS5nb29nbGVh
cGlzLmNvbS9JbnN0YW5jZWAgYW5kCiBgY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9EaXNrYCBh
cmUgc3VwcG9ydGVkLgoKDAoFBAECAAUSA3ACCAoMCgUEAQIAARIDcAkWCgwKBQQBAgADEgNw
GRoKDAoFBAECAAgSA3AbQwoPCggEAQIACJwIABIDcBxCCosCCgQEAQIBEgR2AnsEGvwBIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQmFja3VwUGxhbiB0byBhcHBseSB0
byByZXNvdXJjZXMgdGhhdAogbWF0Y2ggdGhlIHBvbGljeSdzIGNyaXRlcmlhLiBUaGlzIGJh
Y2t1cCBwbGFuIG11c3QgYmUgaW4gdGhlIHNhbWUgbG9jYXRpb24KIGFzIEF1dG9Qcm90ZWN0
aW9uUG9saWN5LiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vYmFja3VwUGxhbnMve2JhY2t1cFBsYW5JZH0KCgwKBQQBAgEFEgN2AggKDAoFBAEC
AQESA3YJFAoMCgUEAQIBAxIDdhcYCg0KBQQBAgEIEgR2GXsDCg8KCAQBAgEInAgAEgN3BCoK
DwoHBAECAQifCBIEeAR6BQpLCgIEAhIFfwCEAQEaPiBDcml0ZXJpYSBzcGVjaWZpZXMgYSBz
ZXQgb2YgY3JpdGVyaWEgZm9yIG1hdGNoaW5nIHJlc291cmNlcy4KCgoKAwQCARIDfwgQCnMK
BAQCAgASBoIBAoMBLxpjIFJlcXVpcmVkLiBBIGxpc3Qgb2YgbWF0Y2hpbmcgY29uZGl0aW9u
cyB0aGF0IGEgcmVzb3VyY2UgbXVzdCBtZWV0IHRvIGJlCiBwcm90ZWN0ZWQgYnkgdGhlIHBv
bGljeS4KCg0KBQQCAgAEEgSCAQIKCg0KBQQCAgAGEgSCAQscCg0KBQQCAgABEgSCAR0wCg0K
BQQCAgADEgSCATM0Cg0KBQQCAgAIEgSDAQYuChAKCAQCAgAInAgAEgSDAQctClcKAgQDEgaH
AQCPAQEaSSBNYXRjaGluZ0NvbmRpdGlvbiBzcGVjaWZpZXMgYSBzZXQgb2YgY29uZGl0aW9u
cyBmb3IgbWF0Y2hpbmcgcmVzb3VyY2VzLgoKCwoDBAMBEgSHAQgZClcKBAQDCAASBooBAo4B
AxpHIEEgY29uZGl0aW9uIHRoYXQgYSByZXNvdXJjZSBtdXN0IG1lZXQgdG8gYmUgcHJvdGVj
dGVkIGJ5IHRoZQogcG9saWN5LgoKDQoFBAMIAAESBIoBCBEKhgEKBAQDAgASBI0BBE4aeCBP
cHRpb25hbC4gQSBjb25kaXRpb24gdGhhdCBtYXRjaGVzIHJlc291cmNlcyBiYXNlZCBvbiB0
aGVpciBsYWJlbHMuCiBGb3IgTVZQLCB0aGlzIGlzIGxpbWl0ZWQgdG8gYSBzaW5nbGUgbGFi
ZWwgbWF0Y2guCgoNCgUEAwIABhIEjQEEEAoNCgUEAwIAARIEjQERIAoNCgUEAwIAAxIEjQEj
JAoNCgUEAwIACBIEjQElTQoQCggEAwIACJwIABIEjQEmTAp/CgIEBBIGkwEAoAEBGnEgUG9s
aWN5RXZhbHVhdGlvblN1bW1hcnkgY29udGFpbnMgdGhlIHN1bW1hcnkgb2YgdGhlIGxhc3Qg
cnVuIG9mIGpvYiB0aGF0CiBhcHBsaWVzIHBvbGljeSB0byBtYXRjaGluZyByZXNvdXJjZXMu
CgoLCgMEBAESBJMBCB8KYQoEBAQCABIElgECUBpTIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVy
IG9mIHJlc291cmNlcyB0aGF0IGN1cnJlbnRseSBtYXRjaCB0aGUgcG9saWN5J3MKIGNyaXRl
cmlhLgoKDQoFBAQCAAUSBJYBAgcKDQoFBAQCAAESBJYBCB8KDQoFBAQCAAMSBJYBIiMKDQoF
BAQCAAgSBJYBJE8KEAoIBAQCAAicCAASBJYBJU4KYQoEBAQCARIGmgECmwEyGlEgT3V0cHV0
IG9ubHkuIFRoZSBudW1iZXIgb2YgbWF0Y2hpbmcgcmVzb3VyY2VzIHRoYXQgYXJlIHN1Y2Nl
c3NmdWxseQogcHJvdGVjdGVkLgoKDQoFBAQCAQUSBJoBAgcKDQoFBAQCAQESBJoBCCAKDQoF
BAQCAQMSBJoBIyQKDQoFBAQCAQgSBJsBBjEKEAoIBAQCAQicCAASBJsBBzAKZgoEBAQCAhIE
nwECThpYIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIG1hdGNoaW5nIHJlc291cmNlcyB3
aG9zZSBwcm90ZWN0aW9uIGZhaWxlZAogZHVyaW5nIGpvYiBydW4uCgoNCgUEBAICBRIEnwEC
BwoNCgUEBAICARIEnwEIHQoNCgUEBAICAxIEnwEgIQoNCgUEBAICCBIEnwEiTQoQCggEBAIC
CJwIABIEnwEjTApjCgIEBRIGpAEApwEBGlUgQmluZGluZ1N1bW1hcnkgY29udGFpbnMgY291
bnQgb2YgZGlmZmVyZW50IGNvbnRhaW5lcnMgY292ZXJlZCB0aHJvdWdoIHRoaXMKIHBvbGlj
eS4KCgsKAwQFARIEpAEIFgpQCgQEBQIAEgSmAQJGGkIgT3V0cHV0IG9ubHkuIFRvdGFsIGNv
dW50IG9mIFByb2plY3RzIHByb3RlY3RlZCB3aXRoIHRoaXMgcG9saWN5LgoKDQoFBAUCAAUS
BKYBAgcKDQoFBAUCAAESBKYBCBUKDQoFBAUCAAMSBKYBGBkKDQoFBAUCAAgSBKYBGkUKEAoI
BAUCAAicCAASBKYBG0QKUwoCBAYSBqoBALcBARpFIEtleVZhbHVlUGFpciBkZWZpbmVzIGEg
a2V5LXZhbHVlIHBhaXIgZm9yIG1hdGNoaW5nIHJlc291cmNlIGxhYmVscy4KCgsKAwQGARIE
qgEIFAq3AQoEBAYCABIErwECOhqoASBSZXF1aXJlZC4gVGhlIGtleSBvZiB0aGUgbGFiZWwg
dG8gbWF0Y2guCiBUaGlzIG11c3QgYmUgaW4gdGhlIGZvcm1hdCBge2xhYmVsX2tleX1gLgog
VGhlIGtleSBtdXN0IG1hdGNoIHRoZSByZWdleAogRm9ybWF0OmBbXHB7TGx9XHB7TG99XVtc
cHtMbH1ccHtMb31ccHtOfV8tXXswLDYyfWAuCgoNCgUEBgIABRIErwECCAoNCgUEBgIAARIE
rwEJDAoNCgUEBgIAAxIErwEPEAoNCgUEBgIACBIErwEROQoQCggEBgIACJwIABIErwESOArw
AQoEBAYCARIEtgECRhrhASBSZXF1aXJlZC4gVGhlIHZhbHVlcyBvZiB0aGUgbGFiZWwgdG8g
bWF0Y2guCiBUaGVyZSB3aWxsIGJlIGV4cGxpY2l0ICJPUiIgYmV0d2VlbiB2YWx1ZXMgb2Yg
YXJyYXkuCiBFYWNoIHZhbHVlIG11c3QgYmUgaW4gdGhlIGZvcm1hdCBge2xhYmVsX3ZhbHVl
fWAuCiBUaGUgdmFsdWUgbXVzdCBtYXRjaCB0aGUgcmVnZXgKIEZvcm1hdDogYFtcXHB7TGx9
XFxwe0xvfVxccHtOfV8tXXsxLDYzfWAuCgoNCgUEBgIBBBIEtgECCgoNCgUEBgIBBRIEtgEL
EQoNCgUEBgIBARIEtgESGAoNCgUEBgIBAxIEtgEbHAoNCgUEBgIBCBIEtgEdRQoQCggEBgIB
CJwIABIEtgEeRApFCgIEBxIGugEA2gEBGjcgUmVxdWVzdCBtZXNzYWdlIGZvciBjcmVhdGlu
ZyBhbiBBdXRvUHJvdGVjdGlvblBvbGljeS4KCgsKAwQHARIEugEIKQqDAQoEBAcCABIGvQEC
wgEEGnMgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hlcmUgdGhpcyBwb2xpY3kg
d2lsbCBiZSBjcmVhdGVkLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0KCg0KBQQHAgAFEgS9AQIICg0KBQQHAgABEgS9AQkPCg0KBQQHAgADEgS9
ARITCg8KBQQHAgAIEga9ARTCAQMKEAoIBAcCAAicCAASBL4BBCoKEQoHBAcCAAifCBIGvwEE
wQEFCokCCgQEBwIBEgTJAQJQGvoBIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUg
cG9saWN5LgogVGhpcyB3aWxsIGJlY29tZSB0aGUgZmluYWwgY29tcG9uZW50IG9mIHRoZSBw
b2xpY3kncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgbXVzdCBzdGFydCB3aXRoIGEg
bG93ZXJjYXNlIGxldHRlciBmb2xsb3dlZCBieSB1cCB0byA2MgogbG93ZXJjYXNlIGxldHRl
cnMsIG51bWJlcnMsIG9yIGh5cGhlbnMsIGFuZCBjYW5ub3QgZW5kIHdpdGggYSBoeXBoZW4u
CgoNCgUEBwIBBRIEyQECCAoNCgUEBwIBARIEyQEJIgoNCgUEBwIBAxIEyQElJgoNCgUEBwIB
CBIEyQEnTwoQCggEBwIBCJwIABIEyQEoTgpICgQEBwICEgbMAQLNAS8aOCBSZXF1aXJlZC4g
VGhlIEF1dG9Qcm90ZWN0aW9uUG9saWN5IHJlc291cmNlIHRvIGNyZWF0ZS4KCg0KBQQHAgIG
EgTMAQIWCg0KBQQHAgIBEgTMARctCg0KBQQHAgIDEgTMATAxCg0KBQQHAgIIEgTNAQYuChAK
CAQHAgIInAgAEgTNAQctCq8DCgQEBwIDEgbWAQLZAQQangMgT3B0aW9uYWwuIEFuIG9wdGlv
bmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUK
IHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRo
ZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFs
cmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQg
Zm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogVGhl
IHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRo
YXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAw
MC0wMDAwMDAwMDAwMDApLgoKDQoFBAcCAwUSBNYBAggKDQoFBAcCAwESBNYBCRMKDQoFBAcC
AwMSBNYBFhcKDwoFBAcCAwgSBtYBGNkBAwoTCgsEBwIDCMzx+YoBARIE1wEEKgoQCggEBwID
CJwIABIE2AEEKgpECgIECBIG3QEA5wEBGjYgUmVxdWVzdCBtZXNzYWdlIGZvciBnZXR0aW5n
IGFuIEF1dG9Qcm90ZWN0aW9uUG9saWN5LgoKCwoDBAgBEgTdAQgmCqIBCgQECAIAEgbhAQLm
AQQakQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwb2xpY3kgdG8gcmV0cmlldmUuCiBG
b3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0b1By
b3RlY3Rpb25Qb2xpY2llcy97YXV0b19wcm90ZWN0aW9uX3BvbGljeX0KCg0KBQQIAgAFEgTh
AQIICg0KBQQIAgABEgThAQkNCg0KBQQIAgADEgThARARCg8KBQQIAgAIEgbhARLmAQMKEAoI
BAgCAAicCAASBOIBBCoKEQoHBAgCAAifCBIG4wEE5QEFCkUKAgQJEgbqAQCCAgEaNyBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIHVwZGF0aW5nIGFuIEF1dG9Qcm90ZWN0aW9uUG9saWN5LgoKCwoD
BAkBEgTqAQgpCjEKBAQJAgASBuwBAu0BLxohIFJlcXVpcmVkLiBUaGUgcG9saWN5IHRvIHVw
ZGF0ZS4KCg0KBQQJAgAGEgTsAQIWCg0KBQQJAgABEgTsARctCg0KBQQJAgADEgTsATAxCg0K
BQQJAgAIEgTtAQYuChAKCAQJAgAInAgAEgTtAQctCuYCCgQECQIBEgb0AQL1AS8a1QIgT3B0
aW9uYWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUg
b3ZlcndyaXR0ZW4gaW4gdGhlCiBBdXRvUHJvdGVjdGlvblBvbGljeSByZXNvdXJjZSBieSB0
aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFy
ZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBm
aWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUK
IHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUg
b3ZlcndyaXR0ZW4uCgoNCgUECQIBBhIE9AECGwoNCgUECQIBARIE9AEcJwoNCgUECQIBAxIE
9AEqKwoNCgUECQIBCBIE9QEGLgoQCggECQIBCJwIABIE9QEHLQqvAwoEBAkCAhIG/gECgQIE
Gp4DIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVl
c3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3Qg
cmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRo
ZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVy
IHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRo
ZSBmaXJzdCByZXF1ZXN0LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlE
IHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAo
MDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQJAgIFEgT+AQII
Cg0KBQQJAgIBEgT+AQkTCg0KBQQJAgIDEgT+ARYXCg8KBQQJAgIIEgb+ARiBAgMKEwoLBAkC
AgjM8fmKAQESBP8BBCoKEAoIBAkCAgicCAASBIACBCoKRQoCBAoSBoUCAKACARo3IFJlcXVl
c3QgbWVzc2FnZSBmb3IgZGVsZXRpbmcgYW4gQXV0b1Byb3RlY3Rpb25Qb2xpY3kuCgoLCgME
CgESBIUCCCkKoAEKBAQKAgASBokCAo4CBBqPASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IHBvbGljeSB0byBkZWxldGUuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vYXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97YXV0b19wcm90ZWN0aW9u
X3BvbGljeX0KCg0KBQQKAgAFEgSJAgIICg0KBQQKAgABEgSJAgkNCg0KBQQKAgADEgSJAhAR
Cg8KBQQKAgAIEgaJAhKOAgMKEAoIBAoCAAicCAASBIoCBCoKEQoHBAoCAAifCBIGiwIEjQIF
CrIBCgQECgIBEgSTAgI7GqMBIE9wdGlvbmFsLiBUaGUgY3VycmVudCBldGFnIG9mIHRoZSBh
dXRvcHJvdGVjdGlvbnBvbGljeS4KIElmIGFuIGV0YWcgaXMgcHJvdmlkZWQgYW5kIGRvZXMg
bm90IG1hdGNoIHRoZSBjdXJyZW50IGV0YWcgb2YgdGhlCiBjb25uZWN0aW9uLCBkZWxldGlv
biB3aWxsIGJlIGJsb2NrZWQuCgoNCgUECgIBBRIEkwICCAoNCgUECgIBARIEkwIJDQoNCgUE
CgIBAxIEkwIQEQoNCgUECgIBCBIEkwISOgoQCggECgIBCJwIABIEkwITOQqvAwoEBAoCAhIG
nAICnwIEGp4DIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5
IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91
IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdu
b3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUg
c2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNp
bmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxp
ZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBv
cnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQKAgIF
EgScAgIICg0KBQQKAgIBEgScAgkTCg0KBQQKAgIDEgScAhYXCg8KBQQKAgIIEgacAhifAgMK
EwoLBAoCAgjM8fmKAQESBJ0CBCoKEAoIBAoCAgicCAASBJ4CBCoKPwoCBAsSBqMCAL0CARox
IFJlcXVlc3QgbWVzc2FnZSBmb3IgTGlzdEF1dG9Qcm90ZWN0aW9uUG9saWNpZXMuCgoLCgME
CwESBKMCCCkKkgEKBAQLAgASBqYCAqsCBBqBASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5k
IGxvY2F0aW9uIGZvciB3aGljaCB0byByZXRyaWV2ZSB0aGUgbGlzdCBvZgogcG9saWNpZXMu
IEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259CgoNCgUE
CwIABRIEpgICCAoNCgUECwIAARIEpgIJDwoNCgUECwIAAxIEpgISEwoPCgUECwIACBIGpgIU
qwIDChAKCAQLAgAInAgAEgSnAgQqChEKBwQLAgAInwgSBqgCBKoCBQqKAQoEBAsCARIErwIC
Pxp8IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgcG9saWNpZXMgdG8gcmV0dXJu
IGluIGEgc2luZ2xlIHBhZ2UuCiBJZiB1bnNwZWNpZmllZCwgYSBzZXJ2ZXItZGVmYXVsdCB2
YWx1ZSB3aWxsIGJlIHVzZWQuCgoNCgUECwIBBRIErwICBwoNCgUECwIBARIErwIIEQoNCgUE
CwIBAxIErwIUFQoNCgUECwIBCBIErwIWPgoQCggECwIBCJwIABIErwIXPQqUAQoEBAsCAhIE
tAICQRqFASBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlv
dXMKIGBMaXN0QXV0b1Byb3RlY3Rpb25Qb2xpY2llc2AgY2FsbC4gUHJvdmlkZSB0aGlzIHRv
IHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50CiBwYWdlLgoKDQoFBAsCAgUSBLQCAggKDQoFBAsC
AgESBLQCCRMKDQoFBAsCAgMSBLQCFhcKDQoFBAsCAggSBLQCGEAKEAoIBAsCAgicCAASBLQC
GT8KggEKBAQLAgMSBLgCAj0adCBPcHRpb25hbC4gQSBmaWx0ZXIgZXhwcmVzc2lvbiB0aGF0
IGZpbHRlcnMgcmVzb3VyY2VzIGxpc3RlZCBpbiB0aGUKIHJlc3BvbnNlLiBUaGUgZm9sbG93
aW5nIGZpZWxkcyBhcmUgZmlsdGVyYWJsZToKCg0KBQQLAgMFEgS4AgIICg0KBQQLAgMBEgS4
AgkPCg0KBQQLAgMDEgS4AhITCg0KBQQLAgMIEgS4AhQ8ChAKCAQLAgMInAgAEgS4AhU7CnMK
BAQLAgQSBLwCAj8aZSBPcHRpb25hbC4gQW4gZXhwcmVzc2lvbiB0aGF0IHNvcnRzIHRoZSBy
ZXN1bHRzIGluIHRoZSByZXNwb25zZS4gVGhlCiBmb2xsb3dpbmcgZmllbGRzIGFyZSBzb3J0
YWJsZToKCg0KBQQLAgQFEgS8AgIICg0KBQQLAgQBEgS8AgkRCg0KBQQLAgQDEgS8AhQVCg0K
BQQLAgQIEgS8AhY+ChAKCAQLAgQInAgAEgS8Ahc9CkAKAgQMEgbAAgDLAgEaMiBSZXNwb25z
ZSBtZXNzYWdlIGZvciBMaXN0QXV0b1Byb3RlY3Rpb25Qb2xpY2llcy4KCgsKAwQMARIEwAII
KgpDCgQEDAIAEgTCAgI9GjUgQSBsaXN0IG9mIHRoZSBBdXRvUHJvdGVjdGlvblBvbGljeSBy
ZXNvdXJjZXMgZm91bmQuCgoNCgUEDAIABBIEwgICCgoNCgUEDAIABhIEwgILHwoNCgUEDAIA
ARIEwgIgOAoNCgUEDAIAAxIEwgI7PAqNAQoEBAwCARIExgICHRp/IEEgdG9rZW4gdGhhdCBj
YW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4K
IElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFn
ZXMuCgoNCgUEDAIBBRIExgICCAoNCgUEDAIBARIExgIJGAoNCgUEDAIBAxIExgIbHApGCgQE
DAICEgbJAgLKAjUaNiBVbm9yZGVyZWQgbGlzdC4gTG9jYXRpb25zIHRoYXQgY291bGQgbm90
IGJlIHJlYWNoZWQuCgoNCgUEDAICBBIEyQICCgoNCgUEDAICBRIEyQILEQoNCgUEDAICARIE
yQISHQoNCgUEDAICAxIEyQIgIQoNCgUEDAICCBIEygIGNAoQCggEDAICCJwIABIEygIHM2IG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy ===
    # Fields for AutoProtectionPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: backup_plan_details Type: 11 (.google.cloud.backupdr.v1.BackupPlanDetail)
    # Field: criteria Type: 11 (.google.cloud.backupdr.v1.Criteria)
    # Field: state Type: 14 (.google.cloud.backupdr.v1.AutoProtectionPolicy.State)
    # Field: etag Type: 9 ()
    # Field: binding_summary Type: 11 (.google.cloud.backupdr.v1.BindingSummary)
    # Field: policy_evaluation_summary Type: 11 (.google.cloud.backupdr.v1.PolicyEvaluationSummary)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: AutoProtectionPolicy::State
our $AutoProtectionPolicy_STATE_UNSPECIFIED = 0;
our $AutoProtectionPolicy_CREATING = 1;
our $AutoProtectionPolicy_ACTIVE = 2;
our $AutoProtectionPolicy_UPDATING = 3;
our $AutoProtectionPolicy_DELETING = 4;

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail ===
    # Fields for BackupPlanDetail
    # Field: resource_type Type: 9 ()
    # Field: backup_plan Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria ===
    # Fields for Criteria
    # Field: matching_conditions Type: 11 (.google.cloud.backupdr.v1.MatchingCondition)

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::MatchingCondition ===
    # Fields for MatchingCondition
    # Field: label_condition Type: 11 (.google.cloud.backupdr.v1.KeyValuePair)

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::PolicyEvaluationSummary ===
    # Fields for PolicyEvaluationSummary
    # Field: matching_resource_count Type: 3 ()
    # Field: protected_resource_count Type: 3 ()
    # Field: failed_resource_count Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BindingSummary ===
    # Fields for BindingSummary
    # Field: project_count Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::KeyValuePair ===
    # Fields for KeyValuePair
    # Field: key Type: 9 ()
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest ===
    # Fields for CreateAutoProtectionPolicyRequest
    # Field: parent Type: 9 ()
    # Field: auto_protection_policy_id Type: 9 ()
    # Field: auto_protection_policy Type: 11 (.google.cloud.backupdr.v1.AutoProtectionPolicy)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::GetAutoProtectionPolicyRequest ===
    # Fields for GetAutoProtectionPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest ===
    # Fields for UpdateAutoProtectionPolicyRequest
    # Field: auto_protection_policy Type: 11 (.google.cloud.backupdr.v1.AutoProtectionPolicy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest ===
    # Fields for DeleteAutoProtectionPolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest ===
    # Fields for ListAutoProtectionPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse ===
    # Fields for ListAutoProtectionPoliciesResponse
    # Field: auto_protection_policies Type: 11 (.google.cloud.backupdr.v1.AutoProtectionPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::Autoprotectionpolicy - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/autoprotectionpolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::Autoprotectionpolicy;

    my $msg = Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy->new({
        name => $name,
        description => $description,
        backup_plan_details => $backup_plan_details,
        criteria => $criteria,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/autoprotectionpolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy

An AutoprotectionPolicy is a policy resource designed to automate backup
management, moving from manual per-resource protection to a bulk approach.
The policy dynamically discovers and applies a specified backup plan to all
eligible resources that match its defined scope and criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the AutoProtectionPolicy.
Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A description of the policy. The description must be at most 2048
characters.

=item * C<< $msg->backup_plan_details() >> / C<< $msg->backup_plan_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail>)

Required. The backup plan details for matching resources.

=item * C<< $msg->criteria() >> / C<< $msg->criteria($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria>)

Required. The criteria for matching resources.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::AutoProtectionPolicy::State>)

Output only. The current state of the AutoProtectionPolicy.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. The etag for the policy.
If this is provided on update, it must match the server's etag.

=item * C<< $msg->binding_summary() >> / C<< $msg->binding_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BindingSummary>)

Output only. Summary of total count of different containers covered through
this policy.

=item * C<< $msg->policy_evaluation_summary() >> / C<< $msg->policy_evaluation_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::PolicyEvaluationSummary>)

Output only. Summary of last policy evaluation when job was run per
workload type.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the policy was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the policy was last updated.

=back

=head3 Enum: AutoProtectionPolicy::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail

BackupPlanDetail defines configuration of protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. The type of resource that this policy will automatically protect.
Allowed values are, `compute.googleapis.com/Instance` and
`compute.googleapis.com/Disk` are supported.

=item * C<< $msg->backup_plan() >> / C<< $msg->backup_plan($value) >>

Type: C<String>

Required. The resource name of the BackupPlan to apply to resources that
match the policy's criteria. This backup plan must be in the same location
as AutoProtectionPolicy. Format:
projects/{project}/locations/{location}/backupPlans/{backupPlanId}

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria

Criteria specifies a set of criteria for matching resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_conditions() >> / C<< $msg->matching_conditions($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::MatchingCondition>)

Required. A list of matching conditions that a resource must meet to be
protected by the policy.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::MatchingCondition

MatchingCondition specifies a set of conditions for matching resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label_condition() >> / C<< $msg->label_condition($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::KeyValuePair>)

Optional. A condition that matches resources based on their labels.
For MVP, this is limited to a single label match.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::PolicyEvaluationSummary

PolicyEvaluationSummary contains the summary of the last run of job that
applies policy to matching resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_resource_count() >> / C<< $msg->matching_resource_count($value) >>

Type: C<Int64>

Output only. The number of resources that currently match the policy's
criteria.

=item * C<< $msg->protected_resource_count() >> / C<< $msg->protected_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources that are successfully
protected.

=item * C<< $msg->failed_resource_count() >> / C<< $msg->failed_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources whose protection failed
during job run.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BindingSummary

BindingSummary contains count of different containers covered through this
policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_count() >> / C<< $msg->project_count($value) >>

Type: C<Int64>

Output only. Total count of Projects protected with this policy.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::KeyValuePair

KeyValuePair defines a key-value pair for matching resource labels.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. The key of the label to match.
This must be in the format `{label_key}`.
The key must match the regex
Format:`[\p{Ll}\p{Lo}][\p{Ll}\p{Lo}\p{N}_-]{0,62}`.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. The values of the label to match.
There will be explicit "OR" between values of array.
Each value must be in the format `{label_value}`.
The value must match the regex
Format: `[\\p{Ll}\\p{Lo}\\p{N}_-]{1,63}`.

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest

Request message for creating an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this policy will be created.
Format: projects/{project}/locations/{location}

=item * C<< $msg->auto_protection_policy_id() >> / C<< $msg->auto_protection_policy_id($value) >>

Type: C<String>

Required. The ID to use for the policy.
This will become the final component of the policy's resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, or hyphens, and cannot end with a hyphen.

=item * C<< $msg->auto_protection_policy() >> / C<< $msg->auto_protection_policy($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy>)

Required. The AutoProtectionPolicy resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::GetAutoProtectionPolicyRequest

Request message for getting an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the policy to retrieve.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest

Request message for updating an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_protection_policy() >> / C<< $msg->auto_protection_policy($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy>)

Required. The policy to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
AutoProtectionPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest

Request message for deleting an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the policy to delete.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the autoprotectionpolicy.
If an etag is provided and does not match the current etag of the
connection, deletion will be blocked.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest

Request message for ListAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve the list of
policies. Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policies to return in a single page.
If unspecified, a server-default value will be used.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAutoProtectionPolicies` call. Provide this to retrieve the subsequent
page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response. The following fields are filterable:

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression that sorts the results in the response. The
following fields are sortable:

=back

=head2 Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse

Response message for ListAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_protection_policies() >> / C<< $msg->auto_protection_policies($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy>)

A list of the AutoProtectionPolicy resources found.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
