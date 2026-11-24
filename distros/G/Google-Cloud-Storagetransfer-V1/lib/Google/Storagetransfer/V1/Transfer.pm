package Google::Storagetransfer::V1::Transfer;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Storagetransfer::V1::TransferTypes };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvc3RvcmFnZXRyYW5zZmVyL3YxL3RyYW5zZmVyLnByb3RvEhlnb29nbGUuc3Rv
cmFnZXRyYW5zZmVyLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxojZ29v
Z2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0
eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aLmdvb2dsZS9zdG9y
YWdldHJhbnNmZXIvdjEvdHJhbnNmZXJfdHlwZXMucHJvdG8iRAoeR2V0R29vZ2xlU2Vydmlj
ZUFjY291bnRSZXF1ZXN0EiIKCnByb2plY3RfaWQYASABKAlCA+BBAlIJcHJvamVjdElkImoK
GENyZWF0ZVRyYW5zZmVySm9iUmVxdWVzdBJOCgx0cmFuc2Zlcl9qb2IYASABKAsyJi5nb29n
bGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iQgPgQQJSC3RyYW5zZmVySm9iIo4C
ChhVcGRhdGVUcmFuc2ZlckpvYlJlcXVlc3QSHgoIam9iX25hbWUYASABKAlCA+BBAlIHam9i
TmFtZRIiCgpwcm9qZWN0X2lkGAIgASgJQgPgQQJSCXByb2plY3RJZBJOCgx0cmFuc2Zlcl9q
b2IYAyABKAsyJi5nb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iQgPgQQJS
C3RyYW5zZmVySm9iEl4KHnVwZGF0ZV90cmFuc2Zlcl9qb2JfZmllbGRfbWFzaxgEIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSGnVwZGF0ZVRyYW5zZmVySm9iRmllbGRNYXNr
IlsKFUdldFRyYW5zZmVySm9iUmVxdWVzdBIeCghqb2JfbmFtZRgBIAEoCUID4EECUgdqb2JO
YW1lEiIKCnByb2plY3RfaWQYAiABKAlCA+BBAlIJcHJvamVjdElkIl4KGERlbGV0ZVRyYW5z
ZmVySm9iUmVxdWVzdBIeCghqb2JfbmFtZRgBIAEoCUID4EECUgdqb2JOYW1lEiIKCnByb2pl
Y3RfaWQYAiABKAlCA+BBAlIJcHJvamVjdElkInIKF0xpc3RUcmFuc2ZlckpvYnNSZXF1ZXN0
EhsKBmZpbHRlchgBIAEoCUID4EECUgZmaWx0ZXISGwoJcGFnZV9zaXplGAQgASgFUghwYWdl
U2l6ZRIdCgpwYWdlX3Rva2VuGAUgASgJUglwYWdlVG9rZW4ijwEKGExpc3RUcmFuc2Zlckpv
YnNSZXNwb25zZRJLCg10cmFuc2Zlcl9qb2JzGAEgAygLMiYuZ29vZ2xlLnN0b3JhZ2V0cmFu
c2Zlci52MS5UcmFuc2ZlckpvYlIMdHJhbnNmZXJKb2JzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbiI4Ch1QYXVzZVRyYW5zZmVyT3BlcmF0aW9uUmVxdWVzdBIX
CgRuYW1lGAEgASgJQgPgQQJSBG5hbWUiOQoeUmVzdW1lVHJhbnNmZXJPcGVyYXRpb25SZXF1
ZXN0EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZSJbChVSdW5UcmFuc2ZlckpvYlJlcXVlc3QS
HgoIam9iX25hbWUYASABKAlCA+BBAlIHam9iTmFtZRIiCgpwcm9qZWN0X2lkGAIgASgJQgPg
QQJSCXByb2plY3RJZCKvAQoWQ3JlYXRlQWdlbnRQb29sUmVxdWVzdBIiCgpwcm9qZWN0X2lk
GAEgASgJQgPgQQJSCXByb2plY3RJZBJICgphZ2VudF9wb29sGAIgASgLMiQuZ29vZ2xlLnN0
b3JhZ2V0cmFuc2Zlci52MS5BZ2VudFBvb2xCA+BBAlIJYWdlbnRQb29sEicKDWFnZW50X3Bv
b2xfaWQYAyABKAlCA+BBAlILYWdlbnRQb29sSWQinwEKFlVwZGF0ZUFnZW50UG9vbFJlcXVl
c3QSSAoKYWdlbnRfcG9vbBgBIAEoCzIkLmdvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuQWdl
bnRQb29sQgPgQQJSCWFnZW50UG9vbBI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siLgoTR2V0QWdlbnRQb29sUmVxdWVzdBIX
CgRuYW1lGAEgASgJQgPgQQJSBG5hbWUiMQoWRGVsZXRlQWdlbnRQb29sUmVxdWVzdBIXCgRu
YW1lGAEgASgJQgPgQQJSBG5hbWUijwEKFUxpc3RBZ2VudFBvb2xzUmVxdWVzdBIiCgpwcm9q
ZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZBIWCgZmaWx0ZXIYAiABKAlSBmZpbHRlchIb
CglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBCABKAlSCXBhZ2VU
b2tlbiKHAQoWTGlzdEFnZW50UG9vbHNSZXNwb25zZRJFCgthZ2VudF9wb29scxgBIAMoCzIk
Lmdvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuQWdlbnRQb29sUgphZ2VudFBvb2xzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbjKREwoWU3RvcmFnZVRyYW5zZmVy
U2VydmljZRK1AQoXR2V0R29vZ2xlU2VydmljZUFjY291bnQSOS5nb29nbGUuc3RvcmFnZXRy
YW5zZmVyLnYxLkdldEdvb2dsZVNlcnZpY2VBY2NvdW50UmVxdWVzdBovLmdvb2dsZS5zdG9y
YWdldHJhbnNmZXIudjEuR29vZ2xlU2VydmljZUFjY291bnQiLoLT5JMCKBImL3YxL2dvb2ds
ZVNlcnZpY2VBY2NvdW50cy97cHJvamVjdF9pZH0SmAEKEUNyZWF0ZVRyYW5zZmVySm9iEjMu
Z29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5DcmVhdGVUcmFuc2ZlckpvYlJlcXVlc3QaJi5n
b29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iIiaC0+STAiAiEC92MS90cmFu
c2ZlckpvYnM6DHRyYW5zZmVyX2pvYhKbAQoRVXBkYXRlVHJhbnNmZXJKb2ISMy5nb29nbGUu
c3RvcmFnZXRyYW5zZmVyLnYxLlVwZGF0ZVRyYW5zZmVySm9iUmVxdWVzdBomLmdvb2dsZS5z
dG9yYWdldHJhbnNmZXIudjEuVHJhbnNmZXJKb2IiKYLT5JMCIzIeL3YxL3tqb2JfbmFtZT10
cmFuc2ZlckpvYnMvKip9OgEqEpIBCg5HZXRUcmFuc2ZlckpvYhIwLmdvb2dsZS5zdG9yYWdl
dHJhbnNmZXIudjEuR2V0VHJhbnNmZXJKb2JSZXF1ZXN0GiYuZ29vZ2xlLnN0b3JhZ2V0cmFu
c2Zlci52MS5UcmFuc2ZlckpvYiImgtPkkwIgEh4vdjEve2pvYl9uYW1lPXRyYW5zZmVySm9i
cy8qKn0SlQEKEExpc3RUcmFuc2ZlckpvYnMSMi5nb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYx
Lkxpc3RUcmFuc2ZlckpvYnNSZXF1ZXN0GjMuZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5M
aXN0VHJhbnNmZXJKb2JzUmVzcG9uc2UiGILT5JMCEhIQL3YxL3RyYW5zZmVySm9icxKdAQoW
UGF1c2VUcmFuc2Zlck9wZXJhdGlvbhI4Lmdvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuUGF1
c2VUcmFuc2Zlck9wZXJhdGlvblJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiMYLT
5JMCKyImL3YxL3tuYW1lPXRyYW5zZmVyT3BlcmF0aW9ucy8qKn06cGF1c2U6ASoSoAEKF1Jl
c3VtZVRyYW5zZmVyT3BlcmF0aW9uEjkuZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5SZXN1
bWVUcmFuc2Zlck9wZXJhdGlvblJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiMoLT
5JMCLCInL3YxL3tuYW1lPXRyYW5zZmVyT3BlcmF0aW9ucy8qKn06cmVzdW1lOgEqEr0BCg5S
dW5UcmFuc2ZlckpvYhIwLmdvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuUnVuVHJhbnNmZXJK
b2JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJagtPkkwInIiIvdjEv
e2pvYl9uYW1lPXRyYW5zZmVySm9icy8qKn06cnVuOgEqykEqChVnb29nbGUucHJvdG9idWYu
RW1wdHkSEVRyYW5zZmVyT3BlcmF0aW9uEogBChFEZWxldGVUcmFuc2ZlckpvYhIzLmdvb2ds
ZS5zdG9yYWdldHJhbnNmZXIudjEuRGVsZXRlVHJhbnNmZXJKb2JSZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IiaC0+STAiAqHi92MS97am9iX25hbWU9dHJhbnNmZXJKb2JzLyoq
fRLMAQoPQ3JlYXRlQWdlbnRQb29sEjEuZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5DcmVh
dGVBZ2VudFBvb2xSZXF1ZXN0GiQuZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5BZ2VudFBv
b2wiYILT5JMCNCImL3YxL3Byb2plY3RzL3twcm9qZWN0X2lkPSp9L2FnZW50UG9vbHM6CmFn
ZW50X3Bvb2zaQSNwcm9qZWN0X2lkLGFnZW50X3Bvb2wsYWdlbnRfcG9vbF9pZBLGAQoPVXBk
YXRlQWdlbnRQb29sEjEuZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5VcGRhdGVBZ2VudFBv
b2xSZXF1ZXN0GiQuZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5BZ2VudFBvb2wiWoLT5JMC
OzItL3YxL3thZ2VudF9wb29sLm5hbWU9cHJvamVjdHMvKi9hZ2VudFBvb2xzLyp9OgphZ2Vu
dF9wb29s2kEWYWdlbnRfcG9vbCx1cGRhdGVfbWFzaxKXAQoMR2V0QWdlbnRQb29sEi4uZ29v
Z2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5HZXRBZ2VudFBvb2xSZXF1ZXN0GiQuZ29vZ2xlLnN0
b3JhZ2V0cmFuc2Zlci52MS5BZ2VudFBvb2wiMYLT5JMCJBIiL3YxL3tuYW1lPXByb2plY3Rz
LyovYWdlbnRQb29scy8qfdpBBG5hbWUSsgEKDkxpc3RBZ2VudFBvb2xzEjAuZ29vZ2xlLnN0
b3JhZ2V0cmFuc2Zlci52MS5MaXN0QWdlbnRQb29sc1JlcXVlc3QaMS5nb29nbGUuc3RvcmFn
ZXRyYW5zZmVyLnYxLkxpc3RBZ2VudFBvb2xzUmVzcG9uc2UiO4LT5JMCKBImL3YxL3Byb2pl
Y3RzL3twcm9qZWN0X2lkPSp9L2FnZW50UG9vbHPaQQpwcm9qZWN0X2lkEo8BCg9EZWxldGVB
Z2VudFBvb2wSMS5nb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLkRlbGV0ZUFnZW50UG9vbFJl
cXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiMYLT5JMCJCoiL3YxL3tuYW1lPXByb2pl
Y3RzLyovYWdlbnRQb29scy8qfdpBBG5hbWUaUspBHnN0b3JhZ2V0cmFuc2Zlci5nb29nbGVh
cGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZv
cm1C7AEKI2NvbS5nb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLnByb3RvQg1UcmFuc2ZlclBy
b3RvWk1jbG91ZC5nb29nbGUuY29tL2dvL3N0b3JhZ2V0cmFuc2Zlci9hcGl2MS9zdG9yYWdl
dHJhbnNmZXJwYjtzdG9yYWdldHJhbnNmZXJwYqoCH0dvb2dsZS5DbG91ZC5TdG9yYWdlVHJh
bnNmZXIuVjHKAh9Hb29nbGVcQ2xvdWRcU3RvcmFnZVRyYW5zZmVyXFYx6gIiR29vZ2xlOjpD
bG91ZDo6U3RvcmFnZVRyYW5zZmVyOjpWMUqvaQoHEgUOAJwDAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQAtCgkKAgMEEgMWACUKCQoCAwUSAxcAKgoJCgIDBhIDGAA4CggK
AQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsAZAoJCgIICxIDGwBkCggKAQgSAxwALgoJCgII
CBIDHAAuCggKAQgSAx0APAoJCgIIARIDHQA8CggKAQgSAx4APAoJCgIIKRIDHgA8CggKAQgS
Ax8AOwoJCgIILRIDHwA7CroBCgIGABIFJACzAQEarAEgU3RvcmFnZSBUcmFuc2ZlciBTZXJ2
aWNlIGFuZCBpdHMgcHJvdG9zLgogVHJhbnNmZXJzIGRhdGEgYmV0d2VlbiBiZXR3ZWVuIEdv
b2dsZSBDbG91ZCBTdG9yYWdlIGJ1Y2tldHMgb3IgZnJvbSBhIGRhdGEKIHNvdXJjZSBleHRl
cm5hbCB0byBHb29nbGUgdG8gYSBDbG91ZCBTdG9yYWdlIGJ1Y2tldC4KCgoKAwYAARIDJAge
CgoKAwYAAxIDJQJGCgwKBQYAA5kIEgMlAkYKCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3
CuoDCgQGAAIAEgQxAjYDGtsDIFJldHVybnMgdGhlIEdvb2dsZSBzZXJ2aWNlIGFjY291bnQg
dGhhdCBpcyB1c2VkIGJ5IFN0b3JhZ2UgVHJhbnNmZXIKIFNlcnZpY2UgdG8gYWNjZXNzIGJ1
Y2tldHMgaW4gdGhlIHByb2plY3Qgd2hlcmUgdHJhbnNmZXJzCiBydW4gb3IgaW4gb3RoZXIg
cHJvamVjdHMuIEVhY2ggR29vZ2xlIHNlcnZpY2UgYWNjb3VudCBpcyBhc3NvY2lhdGVkCiB3
aXRoIG9uZSBHb29nbGUgQ2xvdWQgcHJvamVjdC4gVXNlcnMKIHNob3VsZCBhZGQgdGhpcyBz
ZXJ2aWNlIGFjY291bnQgdG8gdGhlIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGJ1Y2tldAogQUNM
cyB0byBncmFudCBhY2Nlc3MgdG8gU3RvcmFnZSBUcmFuc2ZlciBTZXJ2aWNlLiBUaGlzIHNl
cnZpY2UKIGFjY291bnQgaXMgY3JlYXRlZCBhbmQgb3duZWQgYnkgU3RvcmFnZSBUcmFuc2Zl
ciBTZXJ2aWNlIGFuZCBjYW4KIG9ubHkgYmUgdXNlZCBieSBTdG9yYWdlIFRyYW5zZmVyIFNl
cnZpY2UuCgoMCgUGAAIAARIDMQYdCgwKBQYAAgACEgMxHjwKDAoFBgACAAMSAzIPIwoNCgUG
AAIABBIEMwQ1BgoRCgkGAAIABLDKvCISBDMENQYKPgoEBgACARIEOQI+AxowIENyZWF0ZXMg
YSB0cmFuc2ZlciBqb2IgdGhhdCBydW5zIHBlcmlvZGljYWxseS4KCgwKBQYAAgEBEgM5BhcK
DAoFBgACAQISAzkYMAoMCgUGAAIBAxIDOTtGCg0KBQYAAgEEEgQ6BD0GChEKCQYAAgEEsMq8
IhIEOgQ9BgrsAwoEBgACAhIESAJNAxrdAyBVcGRhdGVzIGEgdHJhbnNmZXIgam9iLiBVcGRh
dGluZyBhIGpvYidzIHRyYW5zZmVyIHNwZWMgZG9lcyBub3QgYWZmZWN0CiB0cmFuc2ZlciBv
cGVyYXRpb25zIHRoYXQgYXJlIHJ1bm5pbmcgYWxyZWFkeS4KCiAqKk5vdGU6KiogVGhlIGpv
YidzIFtzdGF0dXNdW2dvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuVHJhbnNmZXJKb2Iuc3Rh
dHVzXQogZmllbGQgY2FuIGJlIG1vZGlmaWVkIHVzaW5nIHRoaXMgUlBDIChmb3IgZXhhbXBs
ZSwgdG8gc2V0IGEgam9iJ3Mgc3RhdHVzIHRvCiBbREVMRVRFRF1bZ29vZ2xlLnN0b3JhZ2V0
cmFuc2Zlci52MS5UcmFuc2ZlckpvYi5TdGF0dXMuREVMRVRFRF0sCiBbRElTQUJMRURdW2dv
b2dsZS5zdG9yYWdldHJhbnNmZXIudjEuVHJhbnNmZXJKb2IuU3RhdHVzLkRJU0FCTEVEXSwg
b3IKIFtFTkFCTEVEXVtnb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iLlN0
YXR1cy5FTkFCTEVEXSkuCgoMCgUGAAICARIDSAYXCgwKBQYAAgICEgNIGDAKDAoFBgACAgMS
A0g7RgoNCgUGAAICBBIESQRMBgoRCgkGAAICBLDKvCISBEkETAYKJAoEBgACAxIEUAJUAxoW
IEdldHMgYSB0cmFuc2ZlciBqb2IuCgoMCgUGAAIDARIDUAYUCgwKBQYAAgMCEgNQFSoKDAoF
BgACAwMSA1A1QAoNCgUGAAIDBBIEUQRTBgoRCgkGAAIDBLDKvCISBFEEUwYKJAoEBgACBBIE
VwJcAxoWIExpc3RzIHRyYW5zZmVyIGpvYnMuCgoMCgUGAAIEARIDVwYWCgwKBQYAAgQCEgNX
Fy4KDAoFBgACBAMSA1gPJwoNCgUGAAIEBBIEWQRbBgoRCgkGAAIEBLDKvCISBFkEWwYKLAoE
BgACBRIEXwJlAxoeIFBhdXNlcyBhIHRyYW5zZmVyIG9wZXJhdGlvbi4KCgwKBQYAAgUBEgNf
BhwKDAoFBgACBQISA18dOgoMCgUGAAIFAxIDYA8kCg0KBQYAAgUEEgRhBGQGChEKCQYAAgUE
sMq8IhIEYQRkBgo8CgQGAAIGEgRoAm4DGi4gUmVzdW1lcyBhIHRyYW5zZmVyIG9wZXJhdGlv
biB0aGF0IGlzIHBhdXNlZC4KCgwKBQYAAgYBEgNoBh0KDAoFBgACBgISA2gePAoMCgUGAAIG
AxIDaQ8kCg0KBQYAAgYEEgRqBG0GChEKCQYAAgYEsMq8IhIEagRtBgrhAQoEBgACBxIEdAJ+
AxrSASBTdGFydHMgYSBuZXcgb3BlcmF0aW9uIGZvciB0aGUgc3BlY2lmaWVkIHRyYW5zZmVy
IGpvYi4KIEEgYFRyYW5zZmVySm9iYCBoYXMgYSBtYXhpbXVtIG9mIG9uZSBhY3RpdmUgYFRy
YW5zZmVyT3BlcmF0aW9uYC4gSWYgdGhpcwogbWV0aG9kIGlzIGNhbGxlZCB3aGlsZSBhIGBU
cmFuc2Zlck9wZXJhdGlvbmAgaXMgYWN0aXZlLCBhbiBlcnJvciBpcwogcmV0dXJuZWQuCgoM
CgUGAAIHARIDdAYUCgwKBQYAAgcCEgN0FSoKDAoFBgACBwMSA3UPKwoNCgUGAAIHBBIEdgR5
BgoRCgkGAAIHBLDKvCISBHYEeQYKDQoFBgACBwQSBHoEfQYKDwoHBgACBwSZCBIEegR9BgqX
AQoEBgACCBIGggEChwEDGoYBIERlbGV0ZXMgYSB0cmFuc2ZlciBqb2IuIERlbGV0aW5nIGEg
dHJhbnNmZXIgam9iIHNldHMgaXRzIHN0YXR1cyB0bwogW0RFTEVURURdW2dvb2dsZS5zdG9y
YWdldHJhbnNmZXIudjEuVHJhbnNmZXJKb2IuU3RhdHVzLkRFTEVURURdLgoKDQoFBgACCAES
BIIBBhcKDQoFBgACCAISBIIBGDAKDQoFBgACCAMSBIMBDyQKDwoFBgACCAQSBoQBBIYBBgoT
CgkGAAIIBLDKvCISBoQBBIYBBgoxCgQGAAIJEgaKAQKRAQMaISBDcmVhdGVzIGFuIGFnZW50
IHBvb2wgcmVzb3VyY2UuCgoNCgUGAAIJARIEigEGFQoNCgUGAAIJAhIEigEWLAoNCgUGAAIJ
AxIEigE3QAoPCgUGAAIJBBIGiwEEjgEGChMKCQYAAgkEsMq8IhIGiwEEjgEGCg8KBQYAAgkE
EgaPAQSQAS4KEgoIBgACCQSbCAASBo8BBJABLgo6CgQGAAIKEgaUAQKaAQMaKiBVcGRhdGVz
IGFuIGV4aXN0aW5nIGFnZW50IHBvb2wgcmVzb3VyY2UuCgoNCgUGAAIKARIElAEGFQoNCgUG
AAIKAhIElAEWLAoNCgUGAAIKAxIElAE3QAoPCgUGAAIKBBIGlQEEmAEGChMKCQYAAgoEsMq8
IhIGlQEEmAEGCg0KBQYAAgoEEgSZAQREChAKCAYAAgoEmwgAEgSZAQRECiUKBAYAAgsSBp0B
AqIBAxoVIEdldHMgYW4gYWdlbnQgcG9vbC4KCg0KBQYAAgsBEgSdAQYSCg0KBQYAAgsCEgSd
ARMmCg0KBQYAAgsDEgSdATE6Cg8KBQYAAgsEEgaeAQSgAQYKEwoJBgACCwSwyrwiEgaeAQSg
AQYKDQoFBgACCwQSBKEBBDIKEAoIBgACCwSbCAASBKEBBDIKJAoEBgACDBIGpQECqgEDGhQg
TGlzdHMgYWdlbnQgcG9vbHMuCgoNCgUGAAIMARIEpQEGFAoNCgUGAAIMAhIEpQEVKgoNCgUG
AAIMAxIEpQE1SwoPCgUGAAIMBBIGpgEEqAEGChMKCQYAAgwEsMq8IhIGpgEEqAEGCg0KBQYA
AgwEEgSpAQQ4ChAKCAYAAgwEmwgAEgSpAQQ4CigKBAYAAg0SBq0BArIBAxoYIERlbGV0ZXMg
YW4gYWdlbnQgcG9vbC4KCg0KBQYAAg0BEgStAQYVCg0KBQYAAg0CEgStARYsCg0KBQYAAg0D
EgStATdMCg8KBQYAAg0EEgauAQSwAQYKEwoJBgACDQSwyrwiEgauAQSwAQYKDQoFBgACDQQS
BLEBBDIKEAoIBgACDQSbCAASBLEBBDIKOgoCBAASBrYBALoBARosIFJlcXVlc3QgcGFzc2Vk
IHRvIEdldEdvb2dsZVNlcnZpY2VBY2NvdW50LgoKCwoDBAABEgS2AQgmCnEKBAQAAgASBLkB
AkEaYyBSZXF1aXJlZC4gVGhlIElEIG9mIHRoZSBHb29nbGUgQ2xvdWQgcHJvamVjdCB0aGF0
IHRoZSBHb29nbGUgc2VydmljZQogYWNjb3VudCBpcyBhc3NvY2lhdGVkIHdpdGguCgoNCgUE
AAIABRIEuQECCAoNCgUEAAIAARIEuQEJEwoNCgUEAAIAAxIEuQEWFwoNCgUEAAIACBIEuQEY
QAoQCggEAAIACJwIABIEuQEZPwo0CgIEARIGvQEAwAEBGiYgUmVxdWVzdCBwYXNzZWQgdG8g
Q3JlYXRlVHJhbnNmZXJKb2IuCgoLCgMEAQESBL0BCCAKLAoEBAECABIEvwECSBoeIFJlcXVp
cmVkLiBUaGUgam9iIHRvIGNyZWF0ZS4KCg0KBQQBAgAGEgS/AQINCg0KBQQBAgABEgS/AQ4a
Cg0KBQQBAgADEgS/AR0eCg0KBQQBAgAIEgS/AR9HChAKCAQBAgAInAgAEgS/ASBGCjQKAgQC
EgbDAQDlAQEaJiBSZXF1ZXN0IHBhc3NlZCB0byBVcGRhdGVUcmFuc2ZlckpvYi4KCgsKAwQC
ARIEwwEIIAo0CgQEAgIAEgTFAQI/GiYgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIGpvYiB0byB1
cGRhdGUuCgoNCgUEAgIABRIExQECCAoNCgUEAgIAARIExQEJEQoNCgUEAgIAAxIExQEUFQoN
CgUEAgIACBIExQEWPgoQCggEAgIACJwIABIExQEXPQpQCgQEAgIBEgTJAQJBGkIgUmVxdWly
ZWQuIFRoZSBJRCBvZiB0aGUgR29vZ2xlIENsb3VkIHByb2plY3QgdGhhdCBvd25zIHRoZQog
am9iLgoKDQoFBAICAQUSBMkBAggKDQoFBAICAQESBMkBCRMKDQoFBAICAQMSBMkBFhcKDQoF
BAICAQgSBMkBGEAKEAoIBAICAQicCAASBMkBGT8K8AUKBAQCAgISBNcBAkga4QUgUmVxdWly
ZWQuIFRoZSBqb2IgdG8gdXBkYXRlLiBgdHJhbnNmZXJKb2JgIGlzIGV4cGVjdGVkIHRvIHNw
ZWNpZnkgb25lIG9yCiBtb3JlIG9mIGZpdmUgZmllbGRzOgogW2Rlc2NyaXB0aW9uXVtnb29n
bGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iLmRlc2NyaXB0aW9uXSwKIFt0cmFu
c2Zlcl9zcGVjXVtnb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iLnRyYW5z
ZmVyX3NwZWNdLAogW25vdGlmaWNhdGlvbl9jb25maWddW2dvb2dsZS5zdG9yYWdldHJhbnNm
ZXIudjEuVHJhbnNmZXJKb2Iubm90aWZpY2F0aW9uX2NvbmZpZ10sCiBbbG9nZ2luZ19jb25m
aWddW2dvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuVHJhbnNmZXJKb2IubG9nZ2luZ19jb25m
aWddLCBhbmQKIFtzdGF0dXNdW2dvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuVHJhbnNmZXJK
b2Iuc3RhdHVzXS4gIEFuCiBgVXBkYXRlVHJhbnNmZXJKb2JSZXF1ZXN0YCB0aGF0IHNwZWNp
ZmllcyBvdGhlciBmaWVsZHMgYXJlIHJlamVjdGVkIHdpdGgKIHRoZSBlcnJvciBbSU5WQUxJ
RF9BUkdVTUVOVF1bZ29vZ2xlLnJwYy5Db2RlLklOVkFMSURfQVJHVU1FTlRdLiBVcGRhdGlu
ZyBhCiBqb2Igc3RhdHVzIHRvCiBbREVMRVRFRF1bZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52
MS5UcmFuc2ZlckpvYi5TdGF0dXMuREVMRVRFRF0gcmVxdWlyZXMKIGBzdG9yYWdldHJhbnNm
ZXIuam9icy5kZWxldGVgIHBlcm1pc3Npb24uCgoNCgUEAgICBhIE1wECDQoNCgUEAgICARIE
1wEOGgoNCgUEAgICAxIE1wEdHgoNCgUEAgICCBIE1wEfRwoQCggEAgICCJwIABIE1wEgRgro
BQoEBAICAxIE5AECPxrZBSBUaGUgZmllbGQgbWFzayBvZiB0aGUgZmllbGRzIGluIGB0cmFu
c2ZlckpvYmAgdGhhdCBhcmUgdG8gYmUgdXBkYXRlZCBpbgogdGhpcyByZXF1ZXN0LiAgRmll
bGRzIGluIGB0cmFuc2ZlckpvYmAgdGhhdCBjYW4gYmUgdXBkYXRlZCBhcmU6CiBbZGVzY3Jp
cHRpb25dW2dvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuVHJhbnNmZXJKb2IuZGVzY3JpcHRp
b25dLAogW3RyYW5zZmVyX3NwZWNdW2dvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuVHJhbnNm
ZXJKb2IudHJhbnNmZXJfc3BlY10sCiBbbm90aWZpY2F0aW9uX2NvbmZpZ11bZ29vZ2xlLnN0
b3JhZ2V0cmFuc2Zlci52MS5UcmFuc2ZlckpvYi5ub3RpZmljYXRpb25fY29uZmlnXSwKIFts
b2dnaW5nX2NvbmZpZ11bZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5UcmFuc2ZlckpvYi5s
b2dnaW5nX2NvbmZpZ10sIGFuZAogW3N0YXR1c11bZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52
MS5UcmFuc2ZlckpvYi5zdGF0dXNdLiAgVG8gdXBkYXRlIHRoZQogYHRyYW5zZmVyX3NwZWNg
IG9mIHRoZSBqb2IsIGEgY29tcGxldGUgdHJhbnNmZXIgc3BlY2lmaWNhdGlvbiBtdXN0IGJl
CiBwcm92aWRlZC4gQW4gaW5jb21wbGV0ZSBzcGVjaWZpY2F0aW9uIG1pc3NpbmcgYW55IHJl
cXVpcmVkIGZpZWxkcyBpcwogcmVqZWN0ZWQgd2l0aCB0aGUgZXJyb3IKIFtJTlZBTElEX0FS
R1VNRU5UXVtnb29nbGUucnBjLkNvZGUuSU5WQUxJRF9BUkdVTUVOVF0uCgoNCgUEAgIDBhIE
5AECGwoNCgUEAgIDARIE5AEcOgoNCgUEAgIDAxIE5AE9PgoxCgIEAxIG6AEA7wEBGiMgUmVx
dWVzdCBwYXNzZWQgdG8gR2V0VHJhbnNmZXJKb2IuCgoLCgMEAwESBOgBCB0KKQoEBAMCABIE
6gECPxobIFJlcXVpcmVkLiBUaGUgam9iIHRvIGdldC4KCg0KBQQDAgAFEgTqAQIICg0KBQQD
AgABEgTqAQkRCg0KBQQDAgADEgTqARQVCg0KBQQDAgAIEgTqARY+ChAKCAQDAgAInAgAEgTq
ARc9ClAKBAQDAgESBO4BAkEaQiBSZXF1aXJlZC4gVGhlIElEIG9mIHRoZSBHb29nbGUgQ2xv
dWQgcHJvamVjdCB0aGF0IG93bnMgdGhlCiBqb2IuCgoNCgUEAwIBBRIE7gECCAoNCgUEAwIB
ARIE7gEJEwoNCgUEAwIBAxIE7gEWFwoNCgUEAwIBCBIE7gEYQAoQCggEAwIBCJwIABIE7gEZ
Pwo0CgIEBBIG8gEA+QEBGiYgUmVxdWVzdCBwYXNzZWQgdG8gRGVsZXRlVHJhbnNmZXJKb2Iu
CgoLCgMEBAESBPIBCCAKLAoEBAQCABIE9AECPxoeIFJlcXVpcmVkLiBUaGUgam9iIHRvIGRl
bGV0ZS4KCg0KBQQEAgAFEgT0AQIICg0KBQQEAgABEgT0AQkRCg0KBQQEAgADEgT0ARQVCg0K
BQQEAgAIEgT0ARY+ChAKCAQEAgAInAgAEgT0ARc9ClAKBAQEAgESBPgBAkEaQiBSZXF1aXJl
ZC4gVGhlIElEIG9mIHRoZSBHb29nbGUgQ2xvdWQgcHJvamVjdCB0aGF0IG93bnMgdGhlCiBq
b2IuCgoNCgUEBAIBBRIE+AECCAoNCgUEBAIBARIE+AEJEwoNCgUEBAIBAxIE+AEWFwoNCgUE
BAIBCBIE+AEYQAoQCggEBAIBCJwIABIE+AEZPwqCAQoCBAUSBv0BAKACARp0IGBwcm9qZWN0
SWRgLCBgam9iTmFtZXNgLCBhbmQgYGpvYlN0YXR1c2VzYCBhcmUgcXVlcnkgcGFyYW1ldGVy
cyB0aGF0IGNhbgogYmUgc3BlY2lmaWVkIHdoZW4gbGlzdGluZyB0cmFuc2ZlciBqb2JzLgoK
CwoDBAUBEgT9AQgfCvcICgQEBQIAEgSZAgI9GugIIFJlcXVpcmVkLiBBIGxpc3Qgb2YgcXVl
cnkgcGFyYW1ldGVycyBzcGVjaWZpZWQgYXMgSlNPTiB0ZXh0IGluIHRoZSBmb3JtIG9mOgoK
IGBgYAogewogICAicHJvamVjdElkIjoibXlfcHJvamVjdF9pZCIsCiAgICJqb2JOYW1lcyI6
WyJqb2JpZDEiLCJqb2JpZDIiLC4uLl0sCiAgICJqb2JTdGF0dXNlcyI6WyJzdGF0dXMxIiwi
c3RhdHVzMiIsLi4uXSwKICAgImRhdGFCYWNrZW5kIjoiUVVFUllfUkVQTElDQVRJT05fQ09O
RklHUyIsCiAgICJzb3VyY2VCdWNrZXQiOiJzb3VyY2UtYnVja2V0LW5hbWUiLAogICAic2lu
a0J1Y2tldCI6InNpbmstYnVja2V0LW5hbWUiLAogfQogYGBgCgogVGhlIEpTT04gZm9ybWF0
dGluZyBpbiB0aGUgZXhhbXBsZSBpcyBmb3IgZGlzcGxheSBvbmx5OyBwcm92aWRlIHRoZQog
cXVlcnkgcGFyYW1ldGVycyB3aXRob3V0IHNwYWNlcyBvciBsaW5lIGJyZWFrcy4KCiAqIGBw
cm9qZWN0SWRgIGlzIHJlcXVpcmVkLgogKiBTaW5jZSBgam9iTmFtZXNgIGFuZCBgam9iU3Rh
dHVzZXNgIHN1cHBvcnQgbXVsdGlwbGUgdmFsdWVzLCB0aGVpciB2YWx1ZXMKICAgbXVzdCBi
ZSBzcGVjaWZpZWQgd2l0aCBhcnJheSBub3RhdGlvbi4gYGpvYk5hbWVzYCBhbmQgYGpvYlN0
YXR1c2VzYCBhcmUKICAgb3B0aW9uYWwuIFZhbGlkIHZhbHVlcyBhcmUgY2FzZS1pbnNlbnNp
dGl2ZToKICAgICAqIFtFTkFCTEVEXVtnb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5z
ZmVySm9iLlN0YXR1cy5FTkFCTEVEXQogICAgICogW0RJU0FCTEVEXVtnb29nbGUuc3RvcmFn
ZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iLlN0YXR1cy5ESVNBQkxFRF0KICAgICAqIFtERUxF
VEVEXVtnb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLlRyYW5zZmVySm9iLlN0YXR1cy5ERUxF
VEVEXQogKiBTcGVjaWZ5IGAiZGF0YUJhY2tlbmQiOiJRVUVSWV9SRVBMSUNBVElPTl9DT05G
SUdTImAgdG8gcmV0dXJuIGEgbGlzdCBvZgogICBjcm9zcy1idWNrZXQgcmVwbGljYXRpb24g
am9icy4KICogTGltaXQgdGhlIHJlc3VsdHMgdG8gam9icyBmcm9tIGEgcGFydGljdWxhciBi
dWNrZXQgd2l0aCBgc291cmNlQnVja2V0YAogICBhbmQvb3IgdG8gYSBwYXJ0aWN1bGFyIGJ1
Y2tldCB3aXRoIGBzaW5rQnVja2V0YC4KCg0KBQQFAgAFEgSZAgIICg0KBQQFAgABEgSZAgkP
Cg0KBQQFAgADEgSZAhITCg0KBQQFAgAIEgSZAhQ8ChAKCAQFAgAInAgAEgSZAhU7CkEKBAQF
AgESBJwCAhYaMyBUaGUgbGlzdCBwYWdlIHNpemUuIFRoZSBtYXggYWxsb3dlZCB2YWx1ZSBp
cyAyNTYuCgoNCgUEBQIBBRIEnAICBwoNCgUEBQIBARIEnAIIEQoNCgUEBQIBAxIEnAIUFQok
CgQEBQICEgSfAgIYGhYgVGhlIGxpc3QgcGFnZSB0b2tlbi4KCg0KBQQFAgIFEgSfAgIICg0K
BQQFAgIBEgSfAgkTCg0KBQQFAgIDEgSfAhYXCi8KAgQGEgajAgCpAgEaISBSZXNwb25zZSBm
cm9tIExpc3RUcmFuc2ZlckpvYnMuCgoLCgMEBgESBKMCCCAKKAoEBAYCABIEpQICKRoaIEEg
bGlzdCBvZiB0cmFuc2ZlciBqb2JzLgoKDQoFBAYCAAQSBKUCAgoKDQoFBAYCAAYSBKUCCxYK
DQoFBAYCAAESBKUCFyQKDQoFBAYCAAMSBKUCJygKKQoEBAYCARIEqAICHRobIFRoZSBsaXN0
IG5leHQgcGFnZSB0b2tlbi4KCg0KBQQGAgEFEgSoAgIICg0KBQQGAgEBEgSoAgkYCg0KBQQG
AgEDEgSoAhscCjkKAgQHEgasAgCvAgEaKyBSZXF1ZXN0IHBhc3NlZCB0byBQYXVzZVRyYW5z
ZmVyT3BlcmF0aW9uLgoKCwoDBAcBEgSsAgglCj0KBAQHAgASBK4CAjsaLyBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIHRyYW5zZmVyIG9wZXJhdGlvbi4KCg0KBQQHAgAFEgSuAgIICg0K
BQQHAgABEgSuAgkNCg0KBQQHAgADEgSuAhARCg0KBQQHAgAIEgSuAhI6ChAKCAQHAgAInAgA
EgSuAhM5CjoKAgQIEgayAgC1AgEaLCBSZXF1ZXN0IHBhc3NlZCB0byBSZXN1bWVUcmFuc2Zl
ck9wZXJhdGlvbi4KCgsKAwQIARIEsgIIJgo9CgQECAIAEgS0AgI7Gi8gUmVxdWlyZWQuIFRo
ZSBuYW1lIG9mIHRoZSB0cmFuc2ZlciBvcGVyYXRpb24uCgoNCgUECAIABRIEtAICCAoNCgUE
CAIAARIEtAIJDQoNCgUECAIAAxIEtAIQEQoNCgUECAIACBIEtAISOgoQCggECAIACJwIABIE
tAITOQoxCgIECRIGuAIAvwIBGiMgUmVxdWVzdCBwYXNzZWQgdG8gUnVuVHJhbnNmZXJKb2Iu
CgoLCgMECQESBLgCCB0KNwoEBAkCABIEugICPxopIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgdHJhbnNmZXIgam9iLgoKDQoFBAkCAAUSBLoCAggKDQoFBAkCAAESBLoCCREKDQoFBAkC
AAMSBLoCFBUKDQoFBAkCAAgSBLoCFj4KEAoIBAkCAAicCAASBLoCFz0KWQoEBAkCARIEvgIC
QRpLIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIEdvb2dsZSBDbG91ZCBwcm9qZWN0IHRoYXQg
b3ducyB0aGUgdHJhbnNmZXIKIGpvYi4KCg0KBQQJAgEFEgS+AgIICg0KBQQJAgEBEgS+AgkT
Cg0KBQQJAgEDEgS+AhYXCg0KBQQJAgEIEgS+AhhAChAKCAQJAgEInAgAEgS+Ahk/CkAKAgQK
EgbCAgDYAgEaMiBTcGVjaWZpZXMgdGhlIHJlcXVlc3QgcGFzc2VkIHRvIENyZWF0ZUFnZW50
UG9vbC4KCgsKAwQKARIEwgIIHgpXCgQECgIAEgTFAgJBGkkgUmVxdWlyZWQuIFRoZSBJRCBv
ZiB0aGUgR29vZ2xlIENsb3VkIHByb2plY3QgdGhhdCBvd25zIHRoZQogYWdlbnQgcG9vbC4K
Cg0KBQQKAgAFEgTFAgIICg0KBQQKAgABEgTFAgkTCg0KBQQKAgADEgTFAhYXCg0KBQQKAgAI
EgTFAhhAChAKCAQKAgAInAgAEgTFAhk/CjMKBAQKAgESBMgCAkQaJSBSZXF1aXJlZC4gVGhl
IGFnZW50IHBvb2wgdG8gY3JlYXRlLgoKDQoFBAoCAQYSBMgCAgsKDQoFBAoCAQESBMgCDBYK
DQoFBAoCAQMSBMgCGRoKDQoFBAoCAQgSBMgCG0MKEAoIBAoCAQicCAASBMgCHEIKpwQKBAQK
AgISBNcCAkQamAQgUmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgYWdlbnQgcG9vbCB0byBjcmVh
dGUuCgogVGhlIGBhZ2VudF9wb29sX2lkYCBtdXN0IG1lZXQgdGhlIGZvbGxvd2luZyByZXF1
aXJlbWVudHM6CgogKiAgIExlbmd0aCBvZiAxMjggY2hhcmFjdGVycyBvciBsZXNzLgogKiAg
IE5vdCBzdGFydCB3aXRoIHRoZSBzdHJpbmcgYGdvb2dgLgogKiAgIFN0YXJ0IHdpdGggYSBs
b3dlcmNhc2UgQVNDSUkgY2hhcmFjdGVyLCBmb2xsb3dlZCBieToKICAgICAqICAgWmVybyBv
ciBtb3JlOiBsb3dlcmNhc2UgTGF0aW4gYWxwaGFiZXQgY2hhcmFjdGVycywgbnVtZXJhbHMs
CiAgICAgICAgIGh5cGhlbnMgKGAtYCksIHBlcmlvZHMgKGAuYCksIHVuZGVyc2NvcmVzIChg
X2ApLCBvciB0aWxkZXMgKGB+YCkuCiAgICAgKiAgIE9uZSBvciBtb3JlIG51bWVyYWxzIG9y
IGxvd2VyY2FzZSBBU0NJSSBjaGFyYWN0ZXJzLgoKIEFzIGV4cHJlc3NlZCBieSB0aGUgcmVn
dWxhciBleHByZXNzaW9uOgogYF4oPyFnb29nKVthLXpdKFthLXowLTktLl9+XSpbYS16MC05
XSk/JGAuCgoNCgUECgICBRIE1wICCAoNCgUECgICARIE1wIJFgoNCgUECgICAxIE1wIZGgoN
CgUECgICCBIE1wIbQwoQCggECgICCJwIABIE1wIcQgpACgIECxIG2wIA8QIBGjIgU3BlY2lm
aWVzIHRoZSByZXF1ZXN0IHBhc3NlZCB0byBVcGRhdGVBZ2VudFBvb2wuCgoLCgMECwESBNsC
CB4KuAMKBAQLAgASBOYCAkQaqQMgUmVxdWlyZWQuIFRoZSBhZ2VudCBwb29sIHRvIHVwZGF0
ZS4gYGFnZW50X3Bvb2xgIGlzIGV4cGVjdGVkIHRvIHNwZWNpZnkKIGZvbGxvd2luZyBmaWVs
ZHM6CgogKiAgW25hbWVdW2dvb2dsZS5zdG9yYWdldHJhbnNmZXIudjEuQWdlbnRQb29sLm5h
bWVdCgogKiAgW2Rpc3BsYXlfbmFtZV1bZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52MS5BZ2Vu
dFBvb2wuZGlzcGxheV9uYW1lXQoKICogIFtiYW5kd2lkdGhfbGltaXRdW2dvb2dsZS5zdG9y
YWdldHJhbnNmZXIudjEuQWdlbnRQb29sLmJhbmR3aWR0aF9saW1pdF0KIEFuIGBVcGRhdGVB
Z2VudFBvb2xSZXF1ZXN0YCB3aXRoIGFueSBvdGhlciBmaWVsZHMgaXMgcmVqZWN0ZWQKIHdp
dGggdGhlIGVycm9yIFtJTlZBTElEX0FSR1VNRU5UXVtnb29nbGUucnBjLkNvZGUuSU5WQUxJ
RF9BUkdVTUVOVF0uCgoNCgUECwIABhIE5gICCwoNCgUECwIAARIE5gIMFgoNCgUECwIAAxIE
5gIZGgoNCgUECwIACBIE5gIbQwoQCggECwIACJwIABIE5gIcQgrvAgoEBAsCARIE8AICLBrg
AiBUaGUgW2ZpZWxkIG1hc2tdCiAoaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJv
dG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYpCiBvZiB0aGUg
ZmllbGRzIGluIGBhZ2VudFBvb2xgIHRvIHVwZGF0ZSBpbiB0aGlzIHJlcXVlc3QuCiBUaGUg
Zm9sbG93aW5nIGBhZ2VudFBvb2xgIGZpZWxkcyBjYW4gYmUgdXBkYXRlZDoKCiAqICBbZGlz
cGxheV9uYW1lXVtnb29nbGUuc3RvcmFnZXRyYW5zZmVyLnYxLkFnZW50UG9vbC5kaXNwbGF5
X25hbWVdCgogKiAgW2JhbmR3aWR0aF9saW1pdF1bZ29vZ2xlLnN0b3JhZ2V0cmFuc2Zlci52
MS5BZ2VudFBvb2wuYmFuZHdpZHRoX2xpbWl0XQoKDQoFBAsCAQYSBPACAhsKDQoFBAsCAQES
BPACHCcKDQoFBAsCAQMSBPACKisKPQoCBAwSBvQCAPcCARovIFNwZWNpZmllcyB0aGUgcmVx
dWVzdCBwYXNzZWQgdG8gR2V0QWdlbnRQb29sLgoKCwoDBAwBEgT0AggbCjwKBAQMAgASBPYC
AjsaLiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGFnZW50IHBvb2wgdG8gZ2V0LgoKDQoF
BAwCAAUSBPYCAggKDQoFBAwCAAESBPYCCQ0KDQoFBAwCAAMSBPYCEBEKDQoFBAwCAAgSBPYC
EjoKEAoIBAwCAAicCAASBPYCEzkKQAoCBA0SBvoCAP0CARoyIFNwZWNpZmllcyB0aGUgcmVx
dWVzdCBwYXNzZWQgdG8gRGVsZXRlQWdlbnRQb29sLgoKCwoDBA0BEgT6AggeCj8KBAQNAgAS
BPwCAjsaMSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGFnZW50IHBvb2wgdG8gZGVsZXRl
LgoKDQoFBA0CAAUSBPwCAggKDQoFBA0CAAESBPwCCQ0KDQoFBA0CAAMSBPwCEBEKDQoFBA0C
AAgSBPwCEjoKEAoIBA0CAAicCAASBPwCEzkKNQoCBA4SBoADAJMDARonIFRoZSByZXF1ZXN0
IHBhc3NlZCB0byBMaXN0QWdlbnRQb29scy4KCgsKAwQOARIEgAMIHQpPCgQEDgIAEgSCAwJB
GkEgUmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgR29vZ2xlIENsb3VkIHByb2plY3QgdGhhdCBv
d25zIHRoZSBqb2IuCgoNCgUEDgIABRIEggMCCAoNCgUEDgIAARIEggMJEwoNCgUEDgIAAxIE
ggMWFwoNCgUEDgIACBIEggMYQAoQCggEDgIACJwIABIEggMZPwrdAgoEBA4CARIEjAMCFBrO
AiBBbiBvcHRpb25hbCBsaXN0IG9mIHF1ZXJ5IHBhcmFtZXRlcnMgc3BlY2lmaWVkIGFzIEpT
T04gdGV4dCBpbiB0aGUKIGZvcm0gb2Y6CgogYHsiYWdlbnRQb29sTmFtZXMiOlsiYWdlbnRw
b29sMSIsImFnZW50cG9vbDIiLC4uLl19YAoKIFNpbmNlIGBhZ2VudFBvb2xOYW1lc2Agc3Vw
cG9ydCBtdWx0aXBsZSB2YWx1ZXMsIGl0cyB2YWx1ZXMgbXVzdCBiZQogc3BlY2lmaWVkIHdp
dGggYXJyYXkgbm90YXRpb24uIFdoZW4gdGhlIGZpbHRlciBpcyBlaXRoZXIgZW1wdHkgb3Ig
bm90CiBwcm92aWRlZCwgdGhlIGxpc3QgcmV0dXJucyBhbGwgYWdlbnQgcG9vbHMgZm9yIHRo
ZSBwcm9qZWN0LgoKDQoFBA4CAQUSBIwDAggKDQoFBA4CAQESBIwDCQ8KDQoFBA4CAQMSBIwD
EhMKQwoEBA4CAhIEjwMCFho1IFRoZSBsaXN0IHBhZ2Ugc2l6ZS4gVGhlIG1heCBhbGxvd2Vk
IHZhbHVlIGlzIGAyNTZgLgoKDQoFBA4CAgUSBI8DAgcKDQoFBA4CAgESBI8DCBEKDQoFBA4C
AgMSBI8DFBUKJAoEBA4CAxIEkgMCGBoWIFRoZSBsaXN0IHBhZ2UgdG9rZW4uCgoNCgUEDgID
BRIEkgMCCAoNCgUEDgIDARIEkgMJEwoNCgUEDgIDAxIEkgMWFwotCgIEDxIGlgMAnAMBGh8g
UmVzcG9uc2UgZnJvbSBMaXN0QWdlbnRQb29scy4KCgsKAwQPARIElgMIHgomCgQEDwIAEgSY
AwIlGhggQSBsaXN0IG9mIGFnZW50IHBvb2xzLgoKDQoFBA8CAAQSBJgDAgoKDQoFBA8CAAYS
BJgDCxQKDQoFBA8CAAESBJgDFSAKDQoFBA8CAAMSBJgDIyQKKQoEBA8CARIEmwMCHRobIFRo
ZSBsaXN0IG5leHQgcGFnZSB0b2tlbi4KCg0KBQQPAgEFEgSbAwIICg0KBQQPAgEBEgSbAwkY
Cg0KBQQPAgEDEgSbAxscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest ===
    # Fields for GetGoogleServiceAccountRequest
    # Field: project_id Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest ===
    # Fields for CreateTransferJobRequest
    # Field: transfer_job Type: 11 (.google.storagetransfer.v1.TransferJob)

# === Message: Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest ===
    # Fields for UpdateTransferJobRequest
    # Field: job_name Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: transfer_job Type: 11 (.google.storagetransfer.v1.TransferJob)
    # Field: update_transfer_job_field_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Storagetransfer::V1::Transfer::GetTransferJobRequest ===
    # Fields for GetTransferJobRequest
    # Field: job_name Type: 9 ()
    # Field: project_id Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::DeleteTransferJobRequest ===
    # Fields for DeleteTransferJobRequest
    # Field: job_name Type: 9 ()
    # Field: project_id Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::ListTransferJobsRequest ===
    # Fields for ListTransferJobsRequest
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::ListTransferJobsResponse ===
    # Fields for ListTransferJobsResponse
    # Field: transfer_jobs Type: 11 (.google.storagetransfer.v1.TransferJob)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::PauseTransferOperationRequest ===
    # Fields for PauseTransferOperationRequest
    # Field: name Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::ResumeTransferOperationRequest ===
    # Fields for ResumeTransferOperationRequest
    # Field: name Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::RunTransferJobRequest ===
    # Fields for RunTransferJobRequest
    # Field: job_name Type: 9 ()
    # Field: project_id Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::CreateAgentPoolRequest ===
    # Fields for CreateAgentPoolRequest
    # Field: project_id Type: 9 ()
    # Field: agent_pool Type: 11 (.google.storagetransfer.v1.AgentPool)
    # Field: agent_pool_id Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::UpdateAgentPoolRequest ===
    # Fields for UpdateAgentPoolRequest
    # Field: agent_pool Type: 11 (.google.storagetransfer.v1.AgentPool)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Storagetransfer::V1::Transfer::GetAgentPoolRequest ===
    # Fields for GetAgentPoolRequest
    # Field: name Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::DeleteAgentPoolRequest ===
    # Fields for DeleteAgentPoolRequest
    # Field: name Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::ListAgentPoolsRequest ===
    # Fields for ListAgentPoolsRequest
    # Field: project_id Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Storagetransfer::V1::Transfer::ListAgentPoolsResponse ===
    # Fields for ListAgentPoolsResponse
    # Field: agent_pools Type: 11 (.google.storagetransfer.v1.AgentPool)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Storagetransfer::V1::Transfer::StorageTransferServiceClient ===
package Google::Storagetransfer::V1::Transfer::StorageTransferServiceClient;

=pod

=head2 Service Client: Google::Storagetransfer::V1::Transfer::StorageTransferServiceClient

Client stub representing the remote C<StorageTransferService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<storagetransfer.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'storagetransfer.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub get_google_service_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'GetGoogleServiceAccount',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount',
    });
}

sub create_transfer_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'CreateTransferJob',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::TransferJob',
    });
}

sub update_transfer_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'UpdateTransferJob',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::TransferJob',
    });
}

sub get_transfer_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::GetTransferJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'GetTransferJob',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::TransferJob',
    });
}

sub list_transfer_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::ListTransferJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'ListTransferJobs',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::Transfer::ListTransferJobsResponse',
    });
}

sub pause_transfer_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::PauseTransferOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'PauseTransferOperation',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub resume_transfer_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::ResumeTransferOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'ResumeTransferOperation',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub run_transfer_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::RunTransferJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'RunTransferJob',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_transfer_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::DeleteTransferJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'DeleteTransferJob',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub create_agent_pool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::CreateAgentPoolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'CreateAgentPool',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::AgentPool',
    });
}

sub update_agent_pool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::UpdateAgentPoolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'UpdateAgentPool',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::AgentPool',
    });
}

sub get_agent_pool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::GetAgentPoolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'GetAgentPool',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::TransferTypes::AgentPool',
    });
}

sub list_agent_pools {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::ListAgentPoolsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'ListAgentPools',
        request        => $req,
        response_class => 'Google::Storagetransfer::V1::Transfer::ListAgentPoolsResponse',
    });
}

sub delete_agent_pool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Storagetransfer::V1::Transfer::DeleteAgentPoolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'DeleteAgentPool',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Storagetransfer::V1::Transfer - Compiled Protocol Buffers messages for google/storagetransfer/v1/transfer.proto

=head1 SYNOPSIS

    use Google::Storagetransfer::V1::Transfer;

    my $msg = Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest->new({
        project_id => $project_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/storagetransfer/v1/transfer.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest

Request passed to GetGoogleServiceAccount.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that the Google service
account is associated with.

=back

=head2 Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest

Request passed to CreateTransferJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transfer_job() >> / C<< $msg->transfer_job($value) >>

Type: C<Message> (L<Google::Storagetransfer::V1::TransferTypes::TransferJob>)

Required. The job to create.

=back

=head2 Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest

Request passed to UpdateTransferJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_name() >> / C<< $msg->job_name($value) >>

Type: C<String>

Required. The name of job to update.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that owns the
job.

=item * C<< $msg->transfer_job() >> / C<< $msg->transfer_job($value) >>

Type: C<Message> (L<Google::Storagetransfer::V1::TransferTypes::TransferJob>)

Required. The job to update. `transferJob` is expected to specify one or
more of five fields:
[description][google.storagetransfer.v1.TransferJob.description],
[transfer_spec][google.storagetransfer.v1.TransferJob.transfer_spec],
[notification_config][google.storagetransfer.v1.TransferJob.notification_config],
[logging_config][google.storagetransfer.v1.TransferJob.logging_config], and
[status][google.storagetransfer.v1.TransferJob.status].  An
`UpdateTransferJobRequest` that specifies other fields are rejected with
the error [INVALID_ARGUMENT][google.rpc.Code.INVALID_ARGUMENT]. Updating a
job status to
[DELETED][google.storagetransfer.v1.TransferJob.Status.DELETED] requires
`storagetransfer.jobs.delete` permission.

=item * C<< $msg->update_transfer_job_field_mask() >> / C<< $msg->update_transfer_job_field_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The field mask of the fields in `transferJob` that are to be updated in
this request.  Fields in `transferJob` that can be updated are:
[description][google.storagetransfer.v1.TransferJob.description],
[transfer_spec][google.storagetransfer.v1.TransferJob.transfer_spec],
[notification_config][google.storagetransfer.v1.TransferJob.notification_config],
[logging_config][google.storagetransfer.v1.TransferJob.logging_config], and
[status][google.storagetransfer.v1.TransferJob.status].  To update the
`transfer_spec` of the job, a complete transfer specification must be
provided. An incomplete specification missing any required fields is
rejected with the error
[INVALID_ARGUMENT][google.rpc.Code.INVALID_ARGUMENT].

=back

=head2 Google::Storagetransfer::V1::Transfer::GetTransferJobRequest

Request passed to GetTransferJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_name() >> / C<< $msg->job_name($value) >>

Type: C<String>

Required. The job to get.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that owns the
job.

=back

=head2 Google::Storagetransfer::V1::Transfer::DeleteTransferJobRequest

Request passed to DeleteTransferJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_name() >> / C<< $msg->job_name($value) >>

Type: C<String>

Required. The job to delete.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that owns the
job.

=back

=head2 Google::Storagetransfer::V1::Transfer::ListTransferJobsRequest

`projectId`, `jobNames`, and `jobStatuses` are query parameters that can
be specified when listing transfer jobs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. A list of query parameters specified as JSON text in the form of:

```
{
  "projectId":"my_project_id",
  "jobNames":["jobid1","jobid2",...],
  "jobStatuses":["status1","status2",...],
  "dataBackend":"QUERY_REPLICATION_CONFIGS",
  "sourceBucket":"source-bucket-name",
  "sinkBucket":"sink-bucket-name",
}
```

The JSON formatting in the example is for display only; provide the
query parameters without spaces or line breaks.

* `projectId` is required.
* Since `jobNames` and `jobStatuses` support multiple values, their values
  must be specified with array notation. `jobNames` and `jobStatuses` are
  optional. Valid values are case-insensitive:
    * [ENABLED][google.storagetransfer.v1.TransferJob.Status.ENABLED]
    * [DISABLED][google.storagetransfer.v1.TransferJob.Status.DISABLED]
    * [DELETED][google.storagetransfer.v1.TransferJob.Status.DELETED]
* Specify `"dataBackend":"QUERY_REPLICATION_CONFIGS"` to return a list of
  cross-bucket replication jobs.
* Limit the results to jobs from a particular bucket with `sourceBucket`
  and/or to a particular bucket with `sinkBucket`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The list page size. The max allowed value is 256.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The list page token.

=back

=head2 Google::Storagetransfer::V1::Transfer::ListTransferJobsResponse

Response from ListTransferJobs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transfer_jobs() >> / C<< $msg->transfer_jobs($value) >>

Type: C<Message> (L<Google::Storagetransfer::V1::TransferTypes::TransferJob>)

A list of transfer jobs.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The list next page token.

=back

=head2 Google::Storagetransfer::V1::Transfer::PauseTransferOperationRequest

Request passed to PauseTransferOperation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the transfer operation.

=back

=head2 Google::Storagetransfer::V1::Transfer::ResumeTransferOperationRequest

Request passed to ResumeTransferOperation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the transfer operation.

=back

=head2 Google::Storagetransfer::V1::Transfer::RunTransferJobRequest

Request passed to RunTransferJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_name() >> / C<< $msg->job_name($value) >>

Type: C<String>

Required. The name of the transfer job.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that owns the transfer
job.

=back

=head2 Google::Storagetransfer::V1::Transfer::CreateAgentPoolRequest

Specifies the request passed to CreateAgentPool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that owns the
agent pool.

=item * C<< $msg->agent_pool() >> / C<< $msg->agent_pool($value) >>

Type: C<Message> (L<Google::Storagetransfer::V1::TransferTypes::AgentPool>)

Required. The agent pool to create.

=item * C<< $msg->agent_pool_id() >> / C<< $msg->agent_pool_id($value) >>

Type: C<String>

Required. The ID of the agent pool to create.

The `agent_pool_id` must meet the following requirements:

*   Length of 128 characters or less.
*   Not start with the string `goog`.
*   Start with a lowercase ASCII character, followed by:
    *   Zero or more: lowercase Latin alphabet characters, numerals,
        hyphens (`-`), periods (`.`), underscores (`_`), or tildes (`~`).
    *   One or more numerals or lowercase ASCII characters.

As expressed by the regular expression:
`^(?!goog)[a-z]([a-z0-9-._~]*[a-z0-9])?$`.

=back

=head2 Google::Storagetransfer::V1::Transfer::UpdateAgentPoolRequest

Specifies the request passed to UpdateAgentPool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->agent_pool() >> / C<< $msg->agent_pool($value) >>

Type: C<Message> (L<Google::Storagetransfer::V1::TransferTypes::AgentPool>)

Required. The agent pool to update. `agent_pool` is expected to specify
following fields:

*  [name][google.storagetransfer.v1.AgentPool.name]

*  [display_name][google.storagetransfer.v1.AgentPool.display_name]

*  [bandwidth_limit][google.storagetransfer.v1.AgentPool.bandwidth_limit]
An `UpdateAgentPoolRequest` with any other fields is rejected
with the error [INVALID_ARGUMENT][google.rpc.Code.INVALID_ARGUMENT].

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The [field mask]
(https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)
of the fields in `agentPool` to update in this request.
The following `agentPool` fields can be updated:

*  [display_name][google.storagetransfer.v1.AgentPool.display_name]

*  [bandwidth_limit][google.storagetransfer.v1.AgentPool.bandwidth_limit]

=back

=head2 Google::Storagetransfer::V1::Transfer::GetAgentPoolRequest

Specifies the request passed to GetAgentPool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the agent pool to get.

=back

=head2 Google::Storagetransfer::V1::Transfer::DeleteAgentPoolRequest

Specifies the request passed to DeleteAgentPool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the agent pool to delete.

=back

=head2 Google::Storagetransfer::V1::Transfer::ListAgentPoolsRequest

The request passed to ListAgentPools.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the Google Cloud project that owns the job.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An optional list of query parameters specified as JSON text in the
form of:

`{"agentPoolNames":["agentpool1","agentpool2",...]}`

Since `agentPoolNames` support multiple values, its values must be
specified with array notation. When the filter is either empty or not
provided, the list returns all agent pools for the project.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The list page size. The max allowed value is `256`.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The list page token.

=back

=head2 Google::Storagetransfer::V1::Transfer::ListAgentPoolsResponse

Response from ListAgentPools.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->agent_pools() >> / C<< $msg->agent_pools($value) >>

Type: C<Message> (L<Google::Storagetransfer::V1::TransferTypes::AgentPool>)

A list of agent pools.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The list next page token.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Storagetransfer::V1::Transfer::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
