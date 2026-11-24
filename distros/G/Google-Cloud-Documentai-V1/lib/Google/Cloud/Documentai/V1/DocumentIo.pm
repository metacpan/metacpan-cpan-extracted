package Google::Cloud::Documentai::V1::DocumentIo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9kb2N1bWVudF9pby5wcm90bxIaZ29vZ2xl
LmNsb3VkLmRvY3VtZW50YWkudjEaIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
ImcKC1Jhd0RvY3VtZW50EhgKB2NvbnRlbnQYASABKAxSB2NvbnRlbnQSGwoJbWltZV90eXBl
GAIgASgJUghtaW1lVHlwZRIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lIkMK
C0djc0RvY3VtZW50EhcKB2djc191cmkYASABKAlSBmdjc1VyaRIbCgltaW1lX3R5cGUYAiAB
KAlSCG1pbWVUeXBlIlUKDEdjc0RvY3VtZW50cxJFCglkb2N1bWVudHMYASADKAsyJy5nb29n
bGUuY2xvdWQuZG9jdW1lbnRhaS52MS5HY3NEb2N1bWVudFIJZG9jdW1lbnRzIjEKCUdjc1By
ZWZpeBIkCg5nY3NfdXJpX3ByZWZpeBgBIAEoCVIMZ2NzVXJpUHJlZml4Ir4BChlCYXRjaERv
Y3VtZW50c0lucHV0Q29uZmlnEkYKCmdjc19wcmVmaXgYASABKAsyJS5nb29nbGUuY2xvdWQu
ZG9jdW1lbnRhaS52MS5HY3NQcmVmaXhIAFIJZ2NzUHJlZml4Ek8KDWdjc19kb2N1bWVudHMY
AiABKAsyKC5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MS5HY3NEb2N1bWVudHNIAFIMZ2Nz
RG9jdW1lbnRzQggKBnNvdXJjZSLWAwoURG9jdW1lbnRPdXRwdXRDb25maWcSbgoRZ2NzX291
dHB1dF9jb25maWcYASABKAsyQC5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MS5Eb2N1bWVu
dE91dHB1dENvbmZpZy5HY3NPdXRwdXRDb25maWdIAFIPZ2NzT3V0cHV0Q29uZmlnGr4CCg9H
Y3NPdXRwdXRDb25maWcSFwoHZ2NzX3VyaRgBIAEoCVIGZ2NzVXJpEjkKCmZpZWxkX21hc2sY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUglmaWVsZE1hc2sSeAoPc2hhcmRp
bmdfY29uZmlnGAMgASgLMk8uZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjEuRG9jdW1lbnRP
dXRwdXRDb25maWcuR2NzT3V0cHV0Q29uZmlnLlNoYXJkaW5nQ29uZmlnUg5zaGFyZGluZ0Nv
bmZpZxpdCg5TaGFyZGluZ0NvbmZpZxImCg9wYWdlc19wZXJfc2hhcmQYASABKAVSDXBhZ2Vz
UGVyU2hhcmQSIwoNcGFnZXNfb3ZlcmxhcBgCIAEoBVIMcGFnZXNPdmVybGFwQg0KC2Rlc3Rp
bmF0aW9uIt8FCglPY3JDb25maWcSQQoFaGludHMYAiABKAsyKy5nb29nbGUuY2xvdWQuZG9j
dW1lbnRhaS52MS5PY3JDb25maWcuSGludHNSBWhpbnRzEjkKGWVuYWJsZV9uYXRpdmVfcGRm
X3BhcnNpbmcYAyABKAhSFmVuYWJsZU5hdGl2ZVBkZlBhcnNpbmcSPQobZW5hYmxlX2ltYWdl
X3F1YWxpdHlfc2NvcmVzGAQgASgIUhhlbmFibGVJbWFnZVF1YWxpdHlTY29yZXMSMAoUYWR2
YW5jZWRfb2NyX29wdGlvbnMYBSADKAlSEmFkdmFuY2VkT2NyT3B0aW9ucxIjCg1lbmFibGVf
c3ltYm9sGAYgASgIUgxlbmFibGVTeW1ib2wSMAoSY29tcHV0ZV9zdHlsZV9pbmZvGAggASgI
QgIYAVIQY29tcHV0ZVN0eWxlSW5mbxJJCiFkaXNhYmxlX2NoYXJhY3Rlcl9ib3hlc19kZXRl
Y3Rpb24YCiABKAhSHmRpc2FibGVDaGFyYWN0ZXJCb3hlc0RldGVjdGlvbhJgChBwcmVtaXVt
X2ZlYXR1cmVzGAsgASgLMjUuZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjEuT2NyQ29uZmln
LlByZW1pdW1GZWF0dXJlc1IPcHJlbWl1bUZlYXR1cmVzGi4KBUhpbnRzEiUKDmxhbmd1YWdl
X2hpbnRzGAEgAygJUg1sYW5ndWFnZUhpbnRzGq4BCg9QcmVtaXVtRmVhdHVyZXMSRQofZW5h
YmxlX3NlbGVjdGlvbl9tYXJrX2RldGVjdGlvbhgDIAEoCFIcZW5hYmxlU2VsZWN0aW9uTWFy
a0RldGVjdGlvbhIsChJjb21wdXRlX3N0eWxlX2luZm8YBCABKAhSEGNvbXB1dGVTdHlsZUlu
Zm8SJgoPZW5hYmxlX21hdGhfb2NyGAUgASgIUg1lbmFibGVNYXRoT2NyQs0BCh5jb20uZ29v
Z2xlLmNsb3VkLmRvY3VtZW50YWkudjFCD0RvY3VtZW50SW9Qcm90b1ABWj5jbG91ZC5nb29n
bGUuY29tL2dvL2RvY3VtZW50YWkvYXBpdjEvZG9jdW1lbnRhaXBiO2RvY3VtZW50YWlwYqoC
Gkdvb2dsZS5DbG91ZC5Eb2N1bWVudEFJLlYxygIaR29vZ2xlXENsb3VkXERvY3VtZW50QUlc
VjHqAh1Hb29nbGU6OkNsb3VkOjpEb2N1bWVudEFJOjpWMUqKMgoHEgUOAK4BAQq8BAoBDBID
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
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAqCggKAQgS
AxQANwoJCgIIJRIDFAA3CggKAQgSAxUAVQoJCgIICxIDFQBVCggKAQgSAxYAIgoJCgIIChID
FgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgANwoJCgIIARIDGAA3CggKAQgSAxkA
NwoJCgIIKRIDGQA3CggKAQgSAxoANgoJCgIILRIDGgA2Cj4KAgQAEgQdACsBGjIgUGF5bG9h
ZCBtZXNzYWdlIG9mIHJhdyBkb2N1bWVudCBjb250ZW50IChieXRlcykuCgoKCgMEAAESAx0I
EwonCgQEAAIAEgMfAhQaGiBJbmxpbmUgZG9jdW1lbnQgY29udGVudC4KCgwKBQQAAgAFEgMf
AgcKDAoFBAACAAESAx8IDwoMCgUEAAIAAxIDHxITCo8BCgQEAAIBEgMjAhcagQEgQW4gSUFO
QSBNSU1FIHR5cGUgKFJGQzY4MzgpIGluZGljYXRpbmcgdGhlIG5hdHVyZSBhbmQgZm9ybWF0
IG9mIHRoZQogW2NvbnRlbnRdW2dvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxLlJhd0RvY3Vt
ZW50LmNvbnRlbnRdLgoKDAoFBAACAQUSAyMCCAoMCgUEAAIBARIDIwkSCgwKBQQAAgEDEgMj
FRYK6wEKBAQAAgISAyoCGhrdASBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBkb2N1bWVudCwg
aXQgc3VwcG9ydHMgYWxsIFVuaWNvZGUgY2hhcmFjdGVycyBleGNlcHQKIHRoZSBmb2xsb3dp
bmc6CiBgKmAsIGA/YCwgYFtgLCBgXWAsIGAlYCwgYHtgLCBgfWAsYCdgLCBgXCJgLCBgLGAK
IGB+YCwgYD1gIGFuZCBgOmAgYXJlIHJlc2VydmVkLgogSWYgbm90IHNwZWNpZmllZCwgYSBk
ZWZhdWx0IElEIGlzIGdlbmVyYXRlZC4KCgwKBQQAAgIFEgMqAggKDAoFBAACAgESAyoJFQoM
CgUEAAICAxIDKhgZCjsKAgQBEgQuADQBGi8gU3BlY2lmaWVzIGEgZG9jdW1lbnQgc3RvcmVk
IG9uIENsb3VkIFN0b3JhZ2UuCgoKCgMEAQESAy4IEwosCgQEAQIAEgMwAhUaHyBUaGUgQ2xv
dWQgU3RvcmFnZSBvYmplY3QgdXJpLgoKDAoFBAECAAUSAzACCAoMCgUEAQIAARIDMAkQCgwK
BQQBAgADEgMwExQKOgoEBAECARIDMwIXGi0gQW4gSUFOQSBNSU1FIHR5cGUgKFJGQzY4Mzgp
IG9mIHRoZSBjb250ZW50LgoKDAoFBAECAQUSAzMCCAoMCgUEAQIBARIDMwkSCgwKBQQBAgED
EgMzFRYKPAoCBAISBDcAOgEaMCBTcGVjaWZpZXMgYSBzZXQgb2YgZG9jdW1lbnRzIG9uIENs
b3VkIFN0b3JhZ2UuCgoKCgMEAgESAzcIFAolCgQEAgIAEgM5AiUaGCBUaGUgbGlzdCBvZiBk
b2N1bWVudHMuCgoMCgUEAgIABBIDOQIKCgwKBQQCAgAGEgM5CxYKDAoFBAICAAESAzkXIAoM
CgUEAgIAAxIDOSMkCkwKAgQDEgQ9AEABGkAgU3BlY2lmaWVzIGFsbCBkb2N1bWVudHMgb24g
Q2xvdWQgU3RvcmFnZSB3aXRoIGEgY29tbW9uIHByZWZpeC4KCgoKAwQDARIDPQgRCh4KBAQD
AgASAz8CHBoRIFRoZSBVUkkgcHJlZml4LgoKDAoFBAMCAAUSAz8CCAoMCgUEAwIAARIDPwkX
CgwKBQQDAgADEgM/GhsKTAoCBAQSBEMATQEaQCBUaGUgY29tbW9uIGNvbmZpZyB0byBzcGVj
aWZ5IGEgc2V0IG9mIGRvY3VtZW50cyB1c2VkIGFzIGlucHV0LgoKCgoDBAQBEgNDCCEKcAoE
BAQIABIERgJMAxpiIFRoZSBzb3VyY2UuIE1ha2Ugc3VyZSB0aGF0IHRoZSBjYWxsZXIgb2Yg
dGhlIEFQSSBoYXMgc3RvcmFnZS5vYmplY3RzLmdldAogYWNjZXNzIHRvIHRoZSBidWNrZXRz
LgoKDAoFBAQIAAESA0YIDgpYCgQEBAIAEgNIBB0aSyBUaGUgc2V0IG9mIGRvY3VtZW50cyB0
aGF0IG1hdGNoIHRoZSBzcGVjaWZpZWQgQ2xvdWQgU3RvcmFnZSBgZ2NzX3ByZWZpeGAuCgoM
CgUEBAIABhIDSAQNCgwKBQQEAgABEgNIDhgKDAoFBAQCAAMSA0gbHApMCgQEBAIBEgNLBCMa
PyBUaGUgc2V0IG9mIGRvY3VtZW50cyBpbmRpdmlkdWFsbHkgc3BlY2lmaWVkIG9uIENsb3Vk
IFN0b3JhZ2UuCgoMCgUEBAIBBhIDSwQQCgwKBQQEAgEBEgNLER4KDAoFBAQCAQMSA0shIgpq
CgIEBRIEUQBuARpeIENvbmZpZyB0aGF0IGNvbnRyb2xzIHRoZSBvdXRwdXQgb2YgZG9jdW1l
bnRzLiBBbGwgZG9jdW1lbnRzIHdpbGwgYmUgd3JpdHRlbgogYXMgYSBKU09OIGZpbGUuCgoK
CgMEBQESA1EIHApBCgQEBQMAEgRTAmcDGjMgVGhlIGNvbmZpZ3VyYXRpb24gdXNlZCB3aGVu
IG91dHB1dHRpbmcgZG9jdW1lbnRzLgoKDAoFBAUDAAESA1MKGQo+CgYEBQMAAwASBFUEWwUa
LiBUaGUgc2hhcmRpbmcgY29uZmlnIGZvciB0aGUgb3V0cHV0IGRvY3VtZW50LgoKDgoHBAUD
AAMAARIDVQwaCjEKCAQFAwADAAIAEgNXBiAaICBUaGUgbnVtYmVyIG9mIHBhZ2VzIHBlciBz
aGFyZC4KChAKCQQFAwADAAIABRIDVwYLChAKCQQFAwADAAIAARIDVwwbChAKCQQFAwADAAIA
AxIDVx4fCk4KCAQFAwADAAIBEgNaBh4aPSBUaGUgbnVtYmVyIG9mIG92ZXJsYXBwaW5nIHBh
Z2VzIGJldHdlZW4gY29uc2VjdXRpdmUgc2hhcmRzLgoKEAoJBAUDAAMAAgEFEgNaBgsKEAoJ
BAUDAAMAAgEBEgNaDBkKEAoJBAUDAAMAAgEDEgNaHB0KQwoGBAUDAAIAEgNeBBcaNCBUaGUg
Q2xvdWQgU3RvcmFnZSB1cmkgKGEgZGlyZWN0b3J5KSBvZiB0aGUgb3V0cHV0LgoKDgoHBAUD
AAIABRIDXgQKCg4KBwQFAwACAAESA14LEgoOCgcEBQMAAgADEgNeFRYK0gEKBgQFAwACARID
YwQtGsIBIFNwZWNpZmllcyB3aGljaCBmaWVsZHMgdG8gaW5jbHVkZSBpbiB0aGUgb3V0cHV0
IGRvY3VtZW50cy4KIE9ubHkgc3VwcG9ydHMgdG9wIGxldmVsIGRvY3VtZW50IGFuZCBwYWdl
cyBmaWVsZCBzbyBpdCBtdXN0IGJlIGluIHRoZQogZm9ybSBvZiBge2RvY3VtZW50X2ZpZWxk
X25hbWV9YCBvciBgcGFnZXMue3BhZ2VfZmllbGRfbmFtZX1gLgoKDgoHBAUDAAIBBhIDYwQd
Cg4KBwQFAwACAQESA2MeKAoOCgcEBQMAAgEDEgNjKywKRwoGBAUDAAICEgNmBCcaOCBTcGVj
aWZpZXMgdGhlIHNoYXJkaW5nIGNvbmZpZyBmb3IgdGhlIG91dHB1dCBkb2N1bWVudC4KCg4K
BwQFAwACAgYSA2YEEgoOCgcEBQMAAgIBEgNmEyIKDgoHBAUDAAICAxIDZiUmCi8KBAQFCAAS
BGoCbQMaISBUaGUgZGVzdGluYXRpb24gb2YgdGhlIHJlc3VsdHMuCgoMCgUEBQgAARIDaggT
CkMKBAQFAgASA2wEKho2IE91dHB1dCBjb25maWcgdG8gd3JpdGUgdGhlIHJlc3VsdHMgdG8g
Q2xvdWQgU3RvcmFnZS4KCgwKBQQFAgAGEgNsBBMKDAoFBAUCAAESA2wUJQoMCgUEBQIAAxID
bCgpCicKAgQGEgVxAK4BARoaIENvbmZpZyBmb3IgRG9jdW1lbnQgT0NSLgoKCgoDBAYBEgNx
CBEKJAoEBAYDABIEcwJ7AxoWIEhpbnRzIGZvciBPQ1IgRW5naW5lCgoMCgUEBgMAARIDcwoP
CqgDCgYEBgMAAgASA3oEJxqYAyBMaXN0IG9mIEJDUC00NyBsYW5ndWFnZSBjb2RlcyB0byB1
c2UgZm9yIE9DUi4gSW4gbW9zdCBjYXNlcywgbm90CiBzcGVjaWZ5aW5nIGl0IHlpZWxkcyB0
aGUgYmVzdCByZXN1bHRzIHNpbmNlIGl0IGVuYWJsZXMgYXV0b21hdGljIGxhbmd1YWdlCiBk
ZXRlY3Rpb24uIEZvciBsYW5ndWFnZXMgYmFzZWQgb24gdGhlIExhdGluIGFscGhhYmV0LCBz
ZXR0aW5nIGhpbnRzIGlzCiBub3QgbmVlZGVkLiBJbiByYXJlIGNhc2VzLCB3aGVuIHRoZSBs
YW5ndWFnZSBvZiB0aGUgdGV4dCBpbiB0aGUKIGltYWdlIGlzIGtub3duLCBzZXR0aW5nIGEg
aGludCB3aWxsIGhlbHAgZ2V0IGJldHRlciByZXN1bHRzIChhbHRob3VnaCBpdAogd2lsbCBi
ZSBhIHNpZ25pZmljYW50IGhpbmRyYW5jZSBpZiB0aGUgaGludCBpcyB3cm9uZykuCgoOCgcE
BgMAAgAEEgN6BAwKDgoHBAYDAAIABRIDeg0TCg4KBwQGAwACAAESA3oUIgoOCgcEBgMAAgAD
EgN6JSYKOQoEBAYDARIFfgKIAQMaKiBDb25maWd1cmF0aW9ucyBmb3IgcHJlbWl1bSBPQ1Ig
ZmVhdHVyZXMuCgoMCgUEBgMBARIDfgoZCnMKBgQGAwECABIEgQEELRpjIFR1cm4gb24gc2Vs
ZWN0aW9uIG1hcmsgZGV0ZWN0b3IgaW4gT0NSIGVuZ2luZS4gT25seSBhdmFpbGFibGUgaW4g
T0NSIDIuMAogKGFuZCBsYXRlcikgcHJvY2Vzc29ycy4KCg8KBwQGAwECAAUSBIEBBAgKDwoH
BAYDAQIAARIEgQEJKAoPCgcEBgMBAgADEgSBASssClYKBgQGAwECARIEhAEEIBpGIFR1cm4g
b24gZm9udCBpZGVudGlmaWNhdGlvbiBtb2RlbCBhbmQgcmV0dXJuIGZvbnQgc3R5bGUgaW5m
b3JtYXRpb24uCgoPCgcEBgMBAgEFEgSEAQQICg8KBwQGAwECAQESBIQBCRsKDwoHBAYDAQIB
AxIEhAEeHwpJCgYEBgMBAgISBIcBBB0aOSBUdXJuIG9uIHRoZSBtb2RlbCB0aGF0IGNhbiBl
eHRyYWN0IExhVGVYIG1hdGggZm9ybXVsYXMuCgoPCgcEBgMBAgIFEgSHAQQICg8KBwQGAwEC
AgESBIcBCRgKDwoHBAYDAQICAxIEhwEbHAooCgQEBgIAEgSLAQISGhogSGludHMgZm9yIHRo
ZSBPQ1IgbW9kZWwuCgoNCgUEBgIABhIEiwECBwoNCgUEBgIAARIEiwEIDQoNCgUEBgIAAxIE
iwEQEQqRAQoEBAYCARIEjwECJRqCASBFbmFibGVzIHNwZWNpYWwgaGFuZGxpbmcgZm9yIFBE
RnMgd2l0aCBleGlzdGluZyB0ZXh0IGluZm9ybWF0aW9uLiBSZXN1bHRzCiBpbiBiZXR0ZXIg
dGV4dCBleHRyYWN0aW9uIHF1YWxpdHkgaW4gc3VjaCBQREYgaW5wdXRzLgoKDQoFBAYCAQUS
BI8BAgYKDQoFBAYCAQESBI8BByAKDQoFBAYCAQMSBI8BIyQK4gEKBAQGAgISBJQBAica0wEg
RW5hYmxlcyBpbnRlbGxpZ2VudCBkb2N1bWVudCBxdWFsaXR5IHNjb3JlcyBhZnRlciBPQ1Iu
IENhbiBoZWxwIHdpdGgKIGRpYWdub3Npbmcgd2h5IE9DUiByZXNwb25zZXMgYXJlIG9mIHBv
b3IgcXVhbGl0eSBmb3IgYSBnaXZlbiBpbnB1dC4KIEFkZHMgYWRkaXRpb25hbCBsYXRlbmN5
IGNvbXBhcmFibGUgdG8gcmVndWxhciBPQ1IgdG8gdGhlIHByb2Nlc3MgY2FsbC4KCg0KBQQG
AgIFEgSUAQIGCg0KBQQGAgIBEgSUAQciCg0KBQQGAgIDEgSUASUmCtMCCgQEBgIDEgSdAQIr
GsQCIEEgbGlzdCBvZiBhZHZhbmNlZCBPQ1Igb3B0aW9ucyB0byBmdXJ0aGVyIGZpbmUtdHVu
ZSBPQ1IgYmVoYXZpb3IuIEN1cnJlbnQKIHZhbGlkIHZhbHVlcyBhcmU6CgogLSBgbGVnYWN5
X2xheW91dGA6IGEgaGV1cmlzdGljcyBsYXlvdXQgZGV0ZWN0aW9uIGFsZ29yaXRobSwgd2hp
Y2ggc2VydmVzIGFzCiBhbiBhbHRlcm5hdGl2ZSB0byB0aGUgY3VycmVudCBNTC1iYXNlZCBs
YXlvdXQgZGV0ZWN0aW9uIGFsZ29yaXRobS4KIEN1c3RvbWVycyBjYW4gY2hvb3NlIHRoZSBi
ZXN0IHN1aXRhYmxlIGxheW91dCBhbGdvcml0aG0gYmFzZWQgb24gdGhlaXIKIHNpdHVhdGlv
bi4KCg0KBQQGAgMEEgSdAQIKCg0KBQQGAgMFEgSdAQsRCg0KBQQGAgMBEgSdARImCg0KBQQG
AgMDEgSdASkqCkUKBAQGAgQSBKABAhkaNyBJbmNsdWRlcyBzeW1ib2wgbGV2ZWwgT0NSIGlu
Zm9ybWF0aW9uIGlmIHNldCB0byB0cnVlLgoKDQoFBAYCBAUSBKABAgYKDQoFBAYCBAESBKAB
BxQKDQoFBAYCBAMSBKABFxgK3wEKBAQGAgUSBKYBAjIa0AEgVHVybiBvbiBmb250IGlkZW50
aWZpY2F0aW9uIG1vZGVsIGFuZCByZXR1cm4gZm9udCBzdHlsZSBpbmZvcm1hdGlvbi4KIERl
cHJlY2F0ZWQsIHVzZQogW1ByZW1pdW1GZWF0dXJlcy5jb21wdXRlX3N0eWxlX2luZm9dW2dv
b2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxLk9jckNvbmZpZy5QcmVtaXVtRmVhdHVyZXMuY29t
cHV0ZV9zdHlsZV9pbmZvXQogaW5zdGVhZC4KCg0KBQQGAgUFEgSmAQIGCg0KBQQGAgUBEgSm
AQcZCg0KBQQGAgUDEgSmARwdCg0KBQQGAgUIEgSmAR4xCg4KBgQGAgUIAxIEpgEfMAqRAQoE
BAYCBhIEqgECLhqCASBUdXJuIG9mZiBjaGFyYWN0ZXIgYm94IGRldGVjdG9yIGluIE9DUiBl
bmdpbmUuIENoYXJhY3RlciBib3ggZGV0ZWN0aW9uIGlzCiBlbmFibGVkIGJ5IGRlZmF1bHQg
aW4gT0NSIDIuMCAoYW5kIGxhdGVyKSBwcm9jZXNzb3JzLgoKDQoFBAYCBgUSBKoBAgYKDQoF
BAYCBgESBKoBBygKDQoFBAYCBgMSBKoBKy0KOAoEBAYCBxIErQECKBoqIENvbmZpZ3VyYXRp
b25zIGZvciBwcmVtaXVtIE9DUiBmZWF0dXJlcy4KCg0KBQQGAgcGEgStAQIRCg0KBQQGAgcB
EgStARIiCg0KBQQGAgcDEgStASUnYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1::DocumentIo::RawDocument ===
    # Fields for RawDocument
    # Field: content Type: 12 ()
    # Field: mime_type Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Documentai::V1::DocumentIo::GcsDocument ===
    # Fields for GcsDocument
    # Field: gcs_uri Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Cloud::Documentai::V1::DocumentIo::GcsDocuments ===
    # Fields for GcsDocuments
    # Field: documents Type: 11 (.google.cloud.documentai.v1.GcsDocument)

# === Message: Google::Cloud::Documentai::V1::DocumentIo::GcsPrefix ===
    # Fields for GcsPrefix
    # Field: gcs_uri_prefix Type: 9 ()

# === Message: Google::Cloud::Documentai::V1::DocumentIo::BatchDocumentsInputConfig ===
    # Fields for BatchDocumentsInputConfig
    # Field: gcs_prefix Type: 11 (.google.cloud.documentai.v1.GcsPrefix)
    # Field: gcs_documents Type: 11 (.google.cloud.documentai.v1.GcsDocuments)

# === Message: Google::Cloud::Documentai::V1::DocumentIo::DocumentOutputConfig ===
    # Fields for DocumentOutputConfig
    # Field: gcs_output_config Type: 11 (.google.cloud.documentai.v1.DocumentOutputConfig.GcsOutputConfig)

# === Message: Google::Cloud::Documentai::V1::DocumentIo::OcrConfig ===
    # Fields for OcrConfig
    # Field: hints Type: 11 (.google.cloud.documentai.v1.OcrConfig.Hints)
    # Field: enable_native_pdf_parsing Type: 8 ()
    # Field: enable_image_quality_scores Type: 8 ()
    # Field: advanced_ocr_options Type: 9 ()
    # Field: enable_symbol Type: 8 ()
    # Field: compute_style_info Type: 8 ()
    # Field: disable_character_boxes_detection Type: 8 ()
    # Field: premium_features Type: 11 (.google.cloud.documentai.v1.OcrConfig.PremiumFeatures)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1::DocumentIo - Compiled Protocol Buffers messages for google/cloud/documentai/v1/document_io.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1::DocumentIo;

    my $msg = Google::Cloud::Documentai::V1::DocumentIo::RawDocument->new({
        content => $content,
        mime_type => $mime_type,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->content();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1::DocumentIo::RawDocument->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1/document_io.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1::DocumentIo::RawDocument

Payload message of raw document content (bytes).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

Inline document content.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

An IANA MIME type (RFC6838) indicating the nature and format of the
[content][google.cloud.documentai.v1.RawDocument.content].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the document, it supports all Unicode characters except
the following:
`*`, `?`, `[`, `]`, `%`, `{`, `}`,`'`, `\"`, `,`
`~`, `=` and `:` are reserved.
If not specified, a default ID is generated.

=back

=head2 Google::Cloud::Documentai::V1::DocumentIo::GcsDocument

Specifies a document stored on Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_uri() >> / C<< $msg->gcs_uri($value) >>

Type: C<String>

The Cloud Storage object uri.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

An IANA MIME type (RFC6838) of the content.

=back

=head2 Google::Cloud::Documentai::V1::DocumentIo::GcsDocuments

Specifies a set of documents on Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentIo::GcsDocument>)

The list of documents.

=back

=head2 Google::Cloud::Documentai::V1::DocumentIo::GcsPrefix

Specifies all documents on Cloud Storage with a common prefix.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_uri_prefix() >> / C<< $msg->gcs_uri_prefix($value) >>

Type: C<String>

The URI prefix.

=back

=head2 Google::Cloud::Documentai::V1::DocumentIo::BatchDocumentsInputConfig

The common config to specify a set of documents used as input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentIo::GcsPrefix>)

The set of documents that match the specified Cloud Storage `gcs_prefix`.

=item * C<< $msg->gcs_documents() >> / C<< $msg->gcs_documents($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentIo::GcsDocuments>)

The set of documents individually specified on Cloud Storage.

=back

=head2 Google::Cloud::Documentai::V1::DocumentIo::DocumentOutputConfig

Config that controls the output of documents. All documents will be written
as a JSON file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_output_config() >> / C<< $msg->gcs_output_config($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentIo::DocumentOutputConfig::GcsOutputConfig>)

Output config to write the results to Cloud Storage.

=back

=head2 Google::Cloud::Documentai::V1::DocumentIo::OcrConfig

Config for Document OCR.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->hints() >> / C<< $msg->hints($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentIo::OcrConfig::Hints>)

Hints for the OCR model.

=item * C<< $msg->enable_native_pdf_parsing() >> / C<< $msg->enable_native_pdf_parsing($value) >>

Type: C<Bool>

Enables special handling for PDFs with existing text information. Results
in better text extraction quality in such PDF inputs.

=item * C<< $msg->enable_image_quality_scores() >> / C<< $msg->enable_image_quality_scores($value) >>

Type: C<Bool>

Enables intelligent document quality scores after OCR. Can help with
diagnosing why OCR responses are of poor quality for a given input.
Adds additional latency comparable to regular OCR to the process call.

=item * C<< $msg->advanced_ocr_options() >> / C<< $msg->advanced_ocr_options($value) >>

Type: C<String>

A list of advanced OCR options to further fine-tune OCR behavior. Current
valid values are:

- `legacy_layout`: a heuristics layout detection algorithm, which serves as
an alternative to the current ML-based layout detection algorithm.
Customers can choose the best suitable layout algorithm based on their
situation.

=item * C<< $msg->enable_symbol() >> / C<< $msg->enable_symbol($value) >>

Type: C<Bool>

Includes symbol level OCR information if set to true.

=item * C<< $msg->compute_style_info() >> / C<< $msg->compute_style_info($value) >>

Type: C<Bool>

Turn on font identification model and return font style information.
Deprecated, use
[PremiumFeatures.compute_style_info][google.cloud.documentai.v1.OcrConfig.PremiumFeatures.compute_style_info]
instead.

=item * C<< $msg->disable_character_boxes_detection() >> / C<< $msg->disable_character_boxes_detection($value) >>

Type: C<Bool>

Turn off character box detector in OCR engine. Character box detection is
enabled by default in OCR 2.0 (and later) processors.

=item * C<< $msg->premium_features() >> / C<< $msg->premium_features($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::DocumentIo::OcrConfig::PremiumFeatures>)

Configurations for premium OCR features.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1::DocumentIo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
