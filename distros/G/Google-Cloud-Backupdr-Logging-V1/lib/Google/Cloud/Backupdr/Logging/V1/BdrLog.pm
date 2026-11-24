package Google::Cloud::Backupdr::Logging::V1::BdrLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYmFja3VwZHIvbG9nZ2luZy92MS9iZHJfbG9nLnByb3RvEiBnb29n
bGUuY2xvdWQuYmFja3VwZHIubG9nZ2luZy52MRofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90byLiDAoWQkRSQmFja3VwUmVzdG9yZUpvYkxvZxIaCgZqb2JfaWQYASABKAlIAFIF
am9iSWSIAQESJgoMam9iX2NhdGVnb3J5GAIgASgJSAFSC2pvYkNhdGVnb3J5iAEBEiIKCmpv
Yl9zdGF0dXMYAyABKAlIAlIJam9iU3RhdHVziAEBEjUKFHNvdXJjZV9yZXNvdXJjZV9uYW1l
GAQgASgJSANSEnNvdXJjZVJlc291cmNlTmFtZYgBARIxChJzb3VyY2VfcmVzb3VyY2VfaWQY
BSABKAlIBFIQc291cmNlUmVzb3VyY2VJZIgBARI3ChVyZXN0b3JlX3Jlc291cmNlX25hbWUY
BiABKAlIBVITcmVzdG9yZVJlc291cmNlTmFtZYgBARIkCgtiYWNrdXBfbmFtZRgHIAEoCUgG
UgpiYWNrdXBOYW1liAEBEigKDXJlc291cmNlX3R5cGUYCCABKAlIB1IMcmVzb3VyY2VUeXBl
iAEBEj4KCnN0YXJ0X3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAhS
CXN0YXJ0VGltZYgBARI6CghlbmRfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBICVIHZW5kVGltZYgBARItChBiYWNrdXBfcGxhbl9uYW1lGAsgASgJSApSDmJhY2t1
cFBsYW5OYW1liAEBEiQKC2JhY2t1cF9ydWxlGAwgASgJSAtSCmJhY2t1cFJ1bGWIAQESNwoV
YmFja3VwX3JldGVudGlvbl9kYXlzGBUgASgFSAxSE2JhY2t1cFJldGVudGlvbkRheXOIAQES
LwoRYmFja3VwX3ZhdWx0X25hbWUYDSABKAlIDVIPYmFja3VwVmF1bHROYW1liAEBEkIKG2lu
Y3JlbWVudGFsX2JhY2t1cF9zaXplX2dpYhgOIAEoAUgOUhhpbmNyZW1lbnRhbEJhY2t1cFNp
emVHaWKIAQESIgoKZXJyb3JfY29kZRgPIAEoBUgPUgllcnJvckNvZGWIAQESIgoKZXJyb3Jf
dHlwZRgQIAEoCUgQUgllcnJvclR5cGWIAQESKAoNZXJyb3JfbWVzc2FnZRgRIAEoCUgRUgxl
cnJvck1lc3NhZ2WIAQESVwoXYmFja3VwX2NvbnNpc3RlbmN5X3RpbWUYEiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wSBJSFWJhY2t1cENvbnNpc3RlbmN5VGltZYgBARI9Chhz
b3VyY2VfcmVzb3VyY2VfbG9jYXRpb24YEyABKAlIE1IWc291cmNlUmVzb3VyY2VMb2NhdGlv
bogBARI/ChlyZXN0b3JlX3Jlc291cmNlX2xvY2F0aW9uGBQgASgJSBRSF3Jlc3RvcmVSZXNv
dXJjZUxvY2F0aW9uiAEBEkoKE3JlY292ZXJ5X3BvaW50X3RpbWUYFiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUhFyZWNvdmVyeVBvaW50VGltZRIoChBkYXRhX3NvdXJjZV9u
YW1lGBcgASgJUg5kYXRhU291cmNlTmFtZUIJCgdfam9iX2lkQg8KDV9qb2JfY2F0ZWdvcnlC
DQoLX2pvYl9zdGF0dXNCFwoVX3NvdXJjZV9yZXNvdXJjZV9uYW1lQhUKE19zb3VyY2VfcmVz
b3VyY2VfaWRCGAoWX3Jlc3RvcmVfcmVzb3VyY2VfbmFtZUIOCgxfYmFja3VwX25hbWVCEAoO
X3Jlc291cmNlX3R5cGVCDQoLX3N0YXJ0X3RpbWVCCwoJX2VuZF90aW1lQhMKEV9iYWNrdXBf
cGxhbl9uYW1lQg4KDF9iYWNrdXBfcnVsZUIYChZfYmFja3VwX3JldGVudGlvbl9kYXlzQhQK
El9iYWNrdXBfdmF1bHRfbmFtZUIeChxfaW5jcmVtZW50YWxfYmFja3VwX3NpemVfZ2liQg0K
C19lcnJvcl9jb2RlQg0KC19lcnJvcl90eXBlQhAKDl9lcnJvcl9tZXNzYWdlQhoKGF9iYWNr
dXBfY29uc2lzdGVuY3lfdGltZUIbChlfc291cmNlX3Jlc291cmNlX2xvY2F0aW9uQhwKGl9y
ZXN0b3JlX3Jlc291cmNlX2xvY2F0aW9uIsMGChdCRFJQcm90ZWN0ZWRSZXNvdXJjZUxvZxI1
ChRzb3VyY2VfcmVzb3VyY2VfbmFtZRgBIAEoCUgAUhJzb3VyY2VSZXNvdXJjZU5hbWWIAQES
MQoSc291cmNlX3Jlc291cmNlX2lkGAIgASgJSAFSEHNvdXJjZVJlc291cmNlSWSIAQESKAoN
cmVzb3VyY2VfdHlwZRgDIAEoCUgCUgxyZXNvdXJjZVR5cGWIAQESRQodc291cmNlX3Jlc291
cmNlX2RhdGFfc2l6ZV9naWIYBCABKAFIA1IZc291cmNlUmVzb3VyY2VEYXRhU2l6ZUdpYogB
ARI8ChhjdXJyZW50X2JhY2t1cF9wbGFuX25hbWUYBSABKAlIBFIVY3VycmVudEJhY2t1cFBs
YW5OYW1liAEBEnEKG2N1cnJlbnRfYmFja3VwX3J1bGVfZGV0YWlscxgGIAMoCzIyLmdvb2ds
ZS5jbG91ZC5iYWNrdXBkci5sb2dnaW5nLnYxLkJhY2t1cFJ1bGVEZXRhaWxSGGN1cnJlbnRC
YWNrdXBSdWxlRGV0YWlscxJLChFsYXN0X3Byb3RlY3RlZF9vbhgHIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBIBVIPbGFzdFByb3RlY3RlZE9uiAEBEj4KGWN1cnJlbnRfYmFj
a3VwX3ZhdWx0X25hbWUYCCABKAlIBlIWY3VycmVudEJhY2t1cFZhdWx0TmFtZYgBARI9Chhz
b3VyY2VfcmVzb3VyY2VfbG9jYXRpb24YCSABKAlIB1IWc291cmNlUmVzb3VyY2VMb2NhdGlv
bogBAUIXChVfc291cmNlX3Jlc291cmNlX25hbWVCFQoTX3NvdXJjZV9yZXNvdXJjZV9pZEIQ
Cg5fcmVzb3VyY2VfdHlwZUIgCh5fc291cmNlX3Jlc291cmNlX2RhdGFfc2l6ZV9naWJCGwoZ
X2N1cnJlbnRfYmFja3VwX3BsYW5fbmFtZUIUChJfbGFzdF9wcm90ZWN0ZWRfb25CHAoaX2N1
cnJlbnRfYmFja3VwX3ZhdWx0X25hbWVCGwoZX3NvdXJjZV9yZXNvdXJjZV9sb2NhdGlvbiKV
AwoQQmFja3VwUnVsZURldGFpbBIgCglydWxlX25hbWUYASABKAlIAFIIcnVsZU5hbWWIAQES
KgoOcmV0ZW50aW9uX2RheXMYAiABKAVIAVINcmV0ZW50aW9uRGF5c4gBARIjCgpyZWN1cnJl
bmNlGAMgASgJSAJSCnJlY3VycmVuY2WIAQESNAoTcmVjdXJyZW5jZV9zY2hlZHVsZRgEIAEo
CUgDUhJyZWN1cnJlbmNlU2NoZWR1bGWIAQESKAoNYmFja3VwX3dpbmRvdxgFIAEoCUgEUgxi
YWNrdXBXaW5kb3eIAQESOQoWYmFja3VwX3dpbmRvd190aW1lem9uZRgGIAEoCUgFUhRiYWNr
dXBXaW5kb3dUaW1lem9uZYgBAUIMCgpfcnVsZV9uYW1lQhEKD19yZXRlbnRpb25fZGF5c0IN
CgtfcmVjdXJyZW5jZUIWChRfcmVjdXJyZW5jZV9zY2hlZHVsZUIQCg5fYmFja3VwX3dpbmRv
d0IZChdfYmFja3VwX3dpbmRvd190aW1lem9uZSLhBgoYQkRSQmFja3VwVmF1bHREZXRhaWxz
TG9nEi8KEWJhY2t1cF92YXVsdF9uYW1lGAEgASgJSABSD2JhY2t1cFZhdWx0TmFtZYgBARI1
ChRzb3VyY2VfcmVzb3VyY2VfbmFtZRgCIAEoCUgBUhJzb3VyY2VSZXNvdXJjZU5hbWWIAQES
KAoNcmVzb3VyY2VfdHlwZRgDIAEoCUgCUgxyZXNvdXJjZVR5cGWIAQESPAoYY3VycmVudF9i
YWNrdXBfcGxhbl9uYW1lGAQgASgJSANSFWN1cnJlbnRCYWNrdXBQbGFuTmFtZYgBARJiCh1m
aXJzdF9hdmFpbGFibGVfcmVzdG9yZV9wb2ludBgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBIBFIaZmlyc3RBdmFpbGFibGVSZXN0b3JlUG9pbnSIAQESYAocbGFzdF9hdmFp
bGFibGVfcmVzdG9yZV9wb2ludBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBI
BVIZbGFzdEF2YWlsYWJsZVJlc3RvcmVQb2ludIgBARItChBzdG9yZWRfYnl0ZXNfZ2liGAcg
ASgBSAZSDnN0b3JlZEJ5dGVzR2liiAEBEkoKH21pbmltdW1fZW5mb3JjZWRfcmV0ZW50aW9u
X2RheXMYCCABKAVIB1IcbWluaW11bUVuZm9yY2VkUmV0ZW50aW9uRGF5c4gBARI9Chhzb3Vy
Y2VfcmVzb3VyY2VfbG9jYXRpb24YCSABKAlICFIWc291cmNlUmVzb3VyY2VMb2NhdGlvbogB
AUIUChJfYmFja3VwX3ZhdWx0X25hbWVCFwoVX3NvdXJjZV9yZXNvdXJjZV9uYW1lQhAKDl9y
ZXNvdXJjZV90eXBlQhsKGV9jdXJyZW50X2JhY2t1cF9wbGFuX25hbWVCIAoeX2ZpcnN0X2F2
YWlsYWJsZV9yZXN0b3JlX3BvaW50Qh8KHV9sYXN0X2F2YWlsYWJsZV9yZXN0b3JlX3BvaW50
QhMKEV9zdG9yZWRfYnl0ZXNfZ2liQiIKIF9taW5pbXVtX2VuZm9yY2VkX3JldGVudGlvbl9k
YXlzQhsKGV9zb3VyY2VfcmVzb3VyY2VfbG9jYXRpb24irgcKE0JEUkJhY2t1cFBsYW5Kb2JM
b2cSFQoGam9iX2lkGAEgASgJUgVqb2JJZBIhCgxqb2JfY2F0ZWdvcnkYAiABKAlSC2pvYkNh
dGVnb3J5Eh0KCmpvYl9zdGF0dXMYAyABKAlSCWpvYlN0YXR1cxIjCg1yZXNvdXJjZV90eXBl
GAQgASgJUgxyZXNvdXJjZVR5cGUSKAoQYmFja3VwX3BsYW5fbmFtZRgFIAEoCVIOYmFja3Vw
UGxhbk5hbWUSRgogcHJldmlvdXNfYmFja3VwX3BsYW5fcmV2aXNpb25faWQYBiABKAlSHHBy
ZXZpb3VzQmFja3VwUGxhblJldmlzaW9uSWQSSgoicHJldmlvdXNfYmFja3VwX3BsYW5fcmV2
aXNpb25fbmFtZRgHIAEoCVIecHJldmlvdXNCYWNrdXBQbGFuUmV2aXNpb25OYW1lEjwKG25l
d19iYWNrdXBfcGxhbl9yZXZpc2lvbl9pZBgIIAEoCVIXbmV3QmFja3VwUGxhblJldmlzaW9u
SWQSQAodbmV3X2JhY2t1cF9wbGFuX3JldmlzaW9uX25hbWUYCSABKAlSGW5ld0JhY2t1cFBs
YW5SZXZpc2lvbk5hbWUSOQoKc3RhcnRfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgLIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSB2VuZFRpbWUSOAoYd29ya2xvYWRzX2FmZmVjdGVkX2NvdW50GAwgASgF
UhZ3b3JrbG9hZHNBZmZlY3RlZENvdW50EmYKFXByZXZpb3VzX2JhY2t1cF9ydWxlcxgNIAMo
CzIyLmdvb2dsZS5jbG91ZC5iYWNrdXBkci5sb2dnaW5nLnYxLkJhY2t1cFJ1bGVEZXRhaWxS
E3ByZXZpb3VzQmFja3VwUnVsZXMSZAoUcmV2aXNlZF9iYWNrdXBfcnVsZXMYDiADKAsyMi5n
b29nbGUuY2xvdWQuYmFja3VwZHIubG9nZ2luZy52MS5CYWNrdXBSdWxlRGV0YWlsUhJyZXZp
c2VkQmFja3VwUnVsZXMSHQoKZXJyb3JfY29kZRgPIAEoBVIJZXJyb3JDb2RlEh0KCmVycm9y
X3R5cGUYECABKAlSCWVycm9yVHlwZRIjCg1lcnJvcl9tZXNzYWdlGBEgASgJUgxlcnJvck1l
c3NhZ2Ui6QsKHkJEUkJhY2t1cFBsYW5Bc3NvY2lhdGlvbkpvYkxvZxIaCgZqb2JfaWQYASAB
KAlIAFIFam9iSWSIAQESJgoMam9iX2NhdGVnb3J5GAIgASgJSAFSC2pvYkNhdGVnb3J5iAEB
EiIKCmpvYl9zdGF0dXMYAyABKAlIAlIJam9iU3RhdHVziAEBEjUKFHNvdXJjZV9yZXNvdXJj
ZV9uYW1lGAQgASgJSANSEnNvdXJjZVJlc291cmNlTmFtZYgBARIxChJzb3VyY2VfcmVzb3Vy
Y2VfaWQYBSABKAlIBFIQc291cmNlUmVzb3VyY2VJZIgBARI9Chhzb3VyY2VfcmVzb3VyY2Vf
bG9jYXRpb24YBiABKAlIBVIWc291cmNlUmVzb3VyY2VMb2NhdGlvbogBARIoCg1yZXNvdXJj
ZV90eXBlGAcgASgJSAZSDHJlc291cmNlVHlwZYgBARJEChxiYWNrdXBfcGxhbl9hc3NvY2lh
dGlvbl9uYW1lGAggASgJSAdSGWJhY2t1cFBsYW5Bc3NvY2lhdGlvbk5hbWWIAQESPgoZcHJl
dmlvdXNfYmFja3VwX3BsYW5fbmFtZRgJIAEoCUgIUhZwcmV2aW91c0JhY2t1cFBsYW5OYW1l
iAEBEksKIHByZXZpb3VzX2JhY2t1cF9wbGFuX3JldmlzaW9uX2lkGAogASgJSAlSHHByZXZp
b3VzQmFja3VwUGxhblJldmlzaW9uSWSIAQESTwoicHJldmlvdXNfYmFja3VwX3BsYW5fcmV2
aXNpb25fbmFtZRgLIAEoCUgKUh5wcmV2aW91c0JhY2t1cFBsYW5SZXZpc2lvbk5hbWWIAQES
NAoUbmV3X2JhY2t1cF9wbGFuX25hbWUYDCABKAlIC1IRbmV3QmFja3VwUGxhbk5hbWWIAQES
QQobbmV3X2JhY2t1cF9wbGFuX3JldmlzaW9uX2lkGA0gASgJSAxSF25ld0JhY2t1cFBsYW5S
ZXZpc2lvbklkiAEBEkUKHW5ld19iYWNrdXBfcGxhbl9yZXZpc2lvbl9uYW1lGA4gASgJSA1S
GW5ld0JhY2t1cFBsYW5SZXZpc2lvbk5hbWWIAQESPgoKc3RhcnRfdGltZRgPIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIDlIJc3RhcnRUaW1liAEBEjoKCGVuZF90aW1lGBAg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgPUgdlbmRUaW1liAEBEiIKCmVycm9y
X2NvZGUYESABKAVIEFIJZXJyb3JDb2RliAEBEiIKCmVycm9yX3R5cGUYEiABKAlIEVIJZXJy
b3JUeXBliAEBEigKDWVycm9yX21lc3NhZ2UYEyABKAlIElIMZXJyb3JNZXNzYWdliAEBQgkK
B19qb2JfaWRCDwoNX2pvYl9jYXRlZ29yeUINCgtfam9iX3N0YXR1c0IXChVfc291cmNlX3Jl
c291cmNlX25hbWVCFQoTX3NvdXJjZV9yZXNvdXJjZV9pZEIbChlfc291cmNlX3Jlc291cmNl
X2xvY2F0aW9uQhAKDl9yZXNvdXJjZV90eXBlQh8KHV9iYWNrdXBfcGxhbl9hc3NvY2lhdGlv
bl9uYW1lQhwKGl9wcmV2aW91c19iYWNrdXBfcGxhbl9uYW1lQiMKIV9wcmV2aW91c19iYWNr
dXBfcGxhbl9yZXZpc2lvbl9pZEIlCiNfcHJldmlvdXNfYmFja3VwX3BsYW5fcmV2aXNpb25f
bmFtZUIXChVfbmV3X2JhY2t1cF9wbGFuX25hbWVCHgocX25ld19iYWNrdXBfcGxhbl9yZXZp
c2lvbl9pZEIgCh5fbmV3X2JhY2t1cF9wbGFuX3JldmlzaW9uX25hbWVCDQoLX3N0YXJ0X3Rp
bWVCCwoJX2VuZF90aW1lQg0KC19lcnJvcl9jb2RlQg0KC19lcnJvcl90eXBlQhAKDl9lcnJv
cl9tZXNzYWdlIrUDCg9CRFJMaWVuRXZlbnRMb2cSHgoIZXZlbnRfaWQYASABKAlIAFIHZXZl
bnRJZIgBARIbCgZhY3Rpb24YAiABKAlIAVIGYWN0aW9uiAEBEhsKBnN0YXR1cxgDIAEoCUgC
UgZzdGF0dXOIAQESPgoKZXZlbnRfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBIA1IJZXZlbnRUaW1liAEBEiQKC2xpZW5fb3JpZ2luGAUgASgJSARSCmxpZW5Pcmln
aW6IAQESIgoKZXJyb3JfY29kZRgGIAEoBUgFUgllcnJvckNvZGWIAQESKAoNZXJyb3JfbWVz
c2FnZRgHIAEoCUgGUgxlcnJvck1lc3NhZ2WIAQESIgoKZXJyb3JfdHlwZRgIIAEoCUgHUgll
cnJvclR5cGWIAQFCCwoJX2V2ZW50X2lkQgkKB19hY3Rpb25CCQoHX3N0YXR1c0INCgtfZXZl
bnRfdGltZUIOCgxfbGllbl9vcmlnaW5CDQoLX2Vycm9yX2NvZGVCEAoOX2Vycm9yX21lc3Nh
Z2VCDQoLX2Vycm9yX3R5cGVCQlABWj5jbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1cGRyL2xv
Z2dpbmcvYXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYkq+aAoHEgUOANkCAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgApCggKAQgSAxQA
VQoJCgIICxIDFABVCggKAQgSAxUAIgoJCgIIChIDFQAiCmQKAgQAEgQZAGMBGlggTG9nIGVu
dHJ5IGZvciBCYWNrdXAgYW5kIFJlc3RvcmUgSm9iIGZvciByZXNvdXJjZXMgdXNpbmcgQmFj
a3VwUGxhbiBiYXNlZAogcHJvdGVjdGlvbi4KCgoKAwQAARIDGQgeClAKBAQAAgASAxsCHRpD
IFRoZSBqb2JfaWQgZmllbGQgZGlzcGxheXMgdGhlIGlkZW50aWZpZXIgb2YgdGhlIGpvYiBi
ZWluZyBsb2dnZWQuCgoMCgUEAAIABBIDGwIKCgwKBQQAAgAFEgMbCxEKDAoFBAACAAESAxsS
GAoMCgUEAAIAAxIDGxscCkMKBAQAAgESAx4CIxo2IFRoZSBjYXRlZ29yeSBmaWVsZCBkaXNw
bGF5cyB0aGUgY2F0ZWdvcnkgb2YgdGhlIGpvYi4KCgwKBQQAAgEEEgMeAgoKDAoFBAACAQUS
Ax4LEQoMCgUEAAIBARIDHhIeCgwKBQQAAgEDEgMeISIKPwoEBAACAhIDIQIhGjIgVGhlIHN0
YXR1cyBmaWVsZCBkaXNwbGF5cyB0aGUgc3RhdHVzIG9mIHRoZSBqb2IuCgoMCgUEAAICBBID
IQIKCgwKBQQAAgIFEgMhCxEKDAoFBAACAgESAyESHAoMCgUEAAICAxIDIR8gCjwKBAQAAgMS
AyQCKxovIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJvdGVjdGVkIHJlc291cmNlLgoK
DAoFBAACAwQSAyQCCgoMCgUEAAIDBRIDJAsRCgwKBQQAAgMBEgMkEiYKDAoFBAACAwMSAyQp
KgomCgQEAAIEEgMnAikaGSBUaGUgc291cmNlIHJlc291cmNlIElELgoKDAoFBAACBAQSAycC
CgoMCgUEAAIEBRIDJwsRCgwKBQQAAgQBEgMnEiQKDAoFBAACBAMSAycnKApbCgQEAAIFEgMr
AiwaTiBGdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHJlc3RvcmUgcmVzb3VyY2UuIE9ubHkg
cG9wdWxhdGVkIGluCiByZXN0b3JlIGpvYnMuCgoMCgUEAAIFBBIDKwIKCgwKBQQAAgUFEgMr
CxEKDAoFBAACBQESAysSJwoMCgUEAAIFAxIDKyorCmEKBAQAAgYSAy8CIhpUIEZ1bGwgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgYmFja3VwIGNyZWF0ZWQgaW4gYmFja3VwIGpvYnMgYW5kIHVz
ZWQgaW4gcmVzdG9yZQogam9icy4KCgwKBQQAAgYEEgMvAgoKDAoFBAACBgUSAy8LEQoMCgUE
AAIGARIDLxIdCgwKBQQAAgYDEgMvICEKUwoEBAACBxIDMgIkGkYgVGhlIHJlc291cmNlX3R5
cGUgZmllbGQgZGlzcGxheXMgdGhlIHR5cGUgb2YgdGhlIHByb3RlY3RlZCByZXNvdXJjZS4K
CgwKBQQAAgcEEgMyAgoKDAoFBAACBwUSAzILEQoMCgUEAAIHARIDMhIfCgwKBQQAAgcDEgMy
IiMKJQoEBAACCBIDNQI0GhggU3RhcnQgdGltZSBvZiB0aGUgam9iLgoKDAoFBAACCAQSAzUC
CgoMCgUEAAIIBhIDNQskCgwKBQQAAggBEgM1JS8KDAoFBAACCAMSAzUyMwojCgQEAAIJEgM4
AjMaFiBFbmQgdGltZSBvZiB0aGUgam9iLgoKDAoFBAACCQQSAzgCCgoMCgUEAAIJBhIDOAsk
CgwKBQQAAgkBEgM4JS0KDAoFBAACCQMSAzgwMgp0CgQEAAIKEgM8AigaZyBGdWxsIHJlc291
cmNlIG5hbWUgZm9yIEJhY2t1cCBQbGFuIG9mIHRoZSBqb2IuIE9ubHkgcG9wdWxhdGVkIGZv
ciBTY2hlZHVsZWQKIEJhY2t1cCBhbmQgQWRob2MgQmFja3VwLgoKDAoFBAACCgQSAzwCCgoM
CgUEAAIKBRIDPAsRCgwKBQQAAgoBEgM8EiIKDAoFBAACCgMSAzwlJwpeCgQEAAILEgNAAiMa
USBOYW1lIG9mIHRoZSBiYWNrdXAgcnVsZS4gT25seSBwb3B1bGF0ZWQgZm9yIFNjaGVkdWxl
ZCBCYWNrdXAgYW5kIEFkaG9jCiBCYWNrdXAuCgoMCgUEAAILBBIDQAIKCgwKBQQAAgsFEgNA
CxEKDAoFBAACCwESA0ASHQoMCgUEAAILAxIDQCAiCigKBAQAAgwSA0MCLBobIEJhY2t1cCBy
ZXRlbnRpb24gaW4gZGF5cy4KCgwKBQQAAgwEEgNDAgoKDAoFBAACDAUSA0MLEAoMCgUEAAIM
ARIDQxEmCgwKBQQAAgwDEgNDKSsKMwoEBAACDRIDRgIpGiYgRnVsbCByZXNvdXJjZSBuYW1l
IGJhY2t1cCB2YXVsdCBuYW1lCgoMCgUEAAINBBIDRgIKCgwKBQQAAg0FEgNGCxEKDAoFBAAC
DQESA0YSIwoMCgUEAAINAxIDRiYoCjwKBAQAAg4SA0kCMxovIFRoZSBhbW91bnQgb2YgaW5j
cmVtZW50YWwgYmFja3VwIGRhdGEgY29waWVkLgoKDAoFBAACDgQSA0kCCgoMCgUEAAIOBRID
SQsRCgwKBQQAAg4BEgNJEi0KDAoFBAACDgMSA0kwMgpBCgQEAAIPEgNMAiEaNCBUaGUgZXJy
b3IgY29kZS4gT25seSBwb3B1bGF0ZWQgaW4gZXJyb3Igc2NlbmFyaW9zLgoKDAoFBAACDwQS
A0wCCgoMCgUEAAIPBRIDTAsQCgwKBQQAAg8BEgNMERsKDAoFBAACDwMSA0weIApkCgQEAAIQ
EgNQAiIaVyBUaGUgbmFtZSBvZiB0aGUgZXJyb3IgdHlwZSBlZy4gUEVSTUlTU0lPTl9ERU5J
RUQuIE9ubHkgcG9wdWxhdGVkIGluIGVycm9yCiBzY2VuYXJpb3MuCgoMCgUEAAIQBBIDUAIK
CgwKBQQAAhAFEgNQCxEKDAoFBAACEAESA1ASHAoMCgUEAAIQAxIDUB8hClIKBAQAAhESA1MC
JRpFIFRoZSB1c2VyIHJlYWRhYmxlIGVycm9yIG1lc3NhZ2UuIE9ubHkgcG9wdWxhdGVkIGlu
IGVycm9yIHNjZW5hcmlvcy4KCgwKBQQAAhEEEgNTAgoKDAoFBAACEQUSA1MLEQoMCgUEAAIR
ARIDUxIfCgwKBQQAAhEDEgNTIiQKJwoEBAACEhIDVgJCGhogQmFja3VwIGNvbnNpc3RlbmN5
IHRpbWUuCgoMCgUEAAISBBIDVgIKCgwKBQQAAhIGEgNWCyQKDAoFBAACEgESA1YlPAoMCgUE
AAISAxIDVj9BCigKBAQAAhMSA1kCMBobIFNvdXJjZSByZXNvdXJjZSBsb2NhdGlvbi4KCgwK
BQQAAhMEEgNZAgoKDAoFBAACEwUSA1kLEQoMCgUEAAITARIDWRIqCgwKBQQAAhMDEgNZLS8K
KQoEBAACFBIDXAIxGhwgUmVzdG9yZSByZXNvdXJjZSBsb2NhdGlvbi4KCgwKBQQAAhQEEgNc
AgoKDAoFBAACFAUSA1wLEQoMCgUEAAIUARIDXBIrCgwKBQQAAhQDEgNcLjAKIwoEBAACFRID
XwI1GhYgUmVjb3ZlcnkgcG9pbnQgdGltZS4KCgwKBQQAAhUGEgNfAhsKDAoFBAACFQESA18c
LwoMCgUEAAIVAxIDXzI0CikKBAQAAhYSA2ICHxocIENhbm9uaWNhbCBEYXRhIFNvdXJjZSBO
YW1lCgoMCgUEAAIWBRIDYgIICgwKBQQAAhYBEgNiCRkKDAoFBAACFgMSA2IcHgpnCgIEARIF
ZwCGAQEaWiBMb2cgZW50cnkgZm9yIEJEUlByb3RlY3RlZFJlc291cmNlIExvZyBmb3IgcmVz
b3VyY2VzIHVzaW5nIEJhY2t1cFBsYW4gYmFzZWQKIHByb3RlY3Rpb24uCgoKCgMEAQESA2cI
HwozCgQEAQIAEgNpAisaJiBGdWxsIGNhbm9uaWNhbCBzb3VyY2UgcmVzb3VyY2UgbmFtZS4K
CgwKBQQBAgAEEgNpAgoKDAoFBAECAAUSA2kLEQoMCgUEAQIAARIDaRImCgwKBQQBAgADEgNp
KSoKOwoEBAECARIDbAIpGi4gVGhlIHNvdXJjZSByZXNvdXJjZSBJRC4gSW5zdGFuY2UgSWQg
Zm9yIEdDRS4KCgwKBQQBAgEEEgNsAgoKDAoFBAECAQUSA2wLEQoMCgUEAQIBARIDbBIkCgwK
BQQBAgEDEgNsJygKQgoEBAECAhIDbwIkGjUgVHlwZSBvZiB0aGUgcmVzb3VyY2UuIEZvciBl
Zy4g4oCcQ29tcHV0ZSBFbmdpbmXigJ0uCgoMCgUEAQICBBIDbwIKCgwKBQQBAgIFEgNvCxEK
DAoFBAECAgESA28SHwoMCgUEAQICAxIDbyIjCl4KBAQBAgMSA3MCNBpRIFRoZSBzaXplIG9m
IHRoZSBwcm90ZWN0ZWQgc291cmNlIHJlc291cmNlIGluIEdpQiwgcm91bmRlZCB0byAyIGRl
Y2ltYWwKIHBsYWNlcy4KCgwKBQQBAgMEEgNzAgoKDAoFBAECAwUSA3MLEQoMCgUEAQIDARID
cxIvCgwKBQQBAgMDEgNzMjMKaQoEBAECBBIDdwIvGlwgQ29tcGxldGUgY2Fub25pY2FsIG5h
bWUgb2YgdGhlIEJhY2t1cCBwbGFuIGN1cnJlbnRseSBhc3NvY2lhdGVkIHdpdGggdGhlCiBz
b3VyY2UgcmVzb3VyY2UuCgoMCgUEAQIEBBIDdwIKCgwKBQQBAgQFEgN3CxEKDAoFBAECBAES
A3cSKgoMCgUEAQIEAxIDdy0uCmUKBAQBAgUSA3sCPBpYIEJhY2t1cCBSdWxlIGRldGFpbHMg
b2YgdGhlIGJhY2t1cCBwbGFuIGN1cnJlbnRseSBhc3NvY2lhdGVkIHdpdGggdGhlIHNvdXJj
ZQogcmVzb3VyY2UuCgoMCgUEAQIFBBIDewIKCgwKBQQBAgUGEgN7CxsKDAoFBAECBQESA3sc
NwoMCgUEAQIFAxIDezo7Cj4KBAQBAgYSA34COxoxIFRpbWVzdGFtcCB3aGVuIHRoZSByZXNv
dXJjZSB3YXMgbGFzdCBwcm90ZWN0ZWQuCgoMCgUEAQIGBBIDfgIKCgwKBQQBAgYGEgN+CyQK
DAoFBAECBgESA34lNgoMCgUEAQIGAxIDfjk6CmYKBAQBAgcSBIIBAjAaWCBGdWxsIFJlc291
cmNlIE5hbWUgb2YgdGhlIGJhY2t1cCB2YXVsdCBjdXJyZW50bHkgYXNzb2NpYXRlZCB3aXRo
IHRoZSBzb3VyY2UKIHJlc291cmNlLgoKDQoFBAECBwQSBIIBAgoKDQoFBAECBwUSBIIBCxEK
DQoFBAECBwESBIIBEisKDQoFBAECBwMSBIIBLi8KKAoEBAECCBIEhQECLxoaIFNvdXJjZSBy
ZXNvdXJjZV9sb2NhdGlvbgoKDQoFBAECCAQSBIUBAgoKDQoFBAECCAUSBIUBCxEKDQoFBAEC
CAESBIUBEioKDQoFBAECCAMSBIUBLS4KDAoCBAISBogBAJoBAQoLCgMEAgESBIgBCBgKIQoE
BAICABIEigECIBoTIEJhY2t1cCBSdWxlIE5hbWUuCgoNCgUEAgIABBIEigECCgoNCgUEAgIA
BRIEigELEQoNCgUEAgIAARIEigESGwoNCgUEAgIAAxIEigEeHwopCgQEAgIBEgSNAQIkGhsg
QmFja3VwIFJldGVudGlvbiBpbiBEYXlzLgoKDQoFBAICAQQSBI0BAgoKDQoFBAICAQUSBI0B
CxAKDQoFBAICAQESBI0BER8KDQoFBAICAQMSBI0BIiMKVAoEBAICAhIEkAECIRpGIFJlY3Vy
cmVuY2UgVHlwZS4gRm9yIEVnLiDigJxXZWVrbHnigJ0s4oCdIE1vbnRobHnigJ0gb3Ig4oCc
RGFpbHnigJ0uCgoNCgUEAgICBBIEkAECCgoNCgUEAgICBRIEkAELEQoNCgUEAgICARIEkAES
HAoNCgUEAgICAxIEkAEfIApYCgQEAgIDEgSTAQIqGkogUmVjdXJyZW5jZSBSZXBlYXQgU2No
ZWR1bGUuIEZvciBFZy4g4oCcMXN0IGFuZCAyNXRoIGRheSBvZiB0aGUgbW9udGgu4oCdCgoN
CgUEAgIDBBIEkwECCgoNCgUEAgIDBRIEkwELEQoNCgUEAgIDARIEkwESJQoNCgUEAgIDAxIE
kwEoKQo6CgQEAgIEEgSWAQIkGiwgQmFja3VwIFdpbmRvdyBGb3IgRWcuIOKAnDAwOjAwIHRv
IDA2OjAw4oCdCgoNCgUEAgIEBBIElgECCgoNCgUEAgIEBRIElgELEQoNCgUEAgIEARIElgES
HwoNCgUEAgIEAxIElgEiIwpYCgQEAgIFEgSZAQItGkogQmFja3VwIFdpbmRvdyBUaW1lem9u
ZSBpbiBJQU5BIGZvcm1hdC4gRm9yIEVnLiDigJxBbWVyaWNhL0xvc19BbmdlbGVz4oCdCgoN
CgUEAgIFBBIEmQECCgoNCgUEAgIFBRIEmQELEQoNCgUEAgIFARIEmQESKAoNCgUEAgIFAxIE
mQErLAppCgIEAxIGngEAugEBGlsgTG9nIGVudHJ5IGZvciBCRFJCYWNrdXBWYXVsdERldGFp
bHMgTG9nIGZvciByZXNvdXJjZXMgdXNpbmcgQmFja3VwUGxhbiBiYXNlZAogcHJvdGVjdGlv
bi4KCgsKAwQDARIEngEIIAo2CgQEAwIAEgSgAQIoGiggUmVsYXRpdmUgcmVzb3VyY2UgbmFt
ZSBvZiBCYWNrdXAgVmF1bHQKCg0KBQQDAgAEEgSgAQIKCg0KBQQDAgAFEgSgAQsRCg0KBQQD
AgABEgSgARIjCg0KBQQDAgADEgSgASYnCi0KBAQDAgESBKMBAisaHyBSZWxhdGl2ZSBzb3Vy
Y2UgcmVzb3VyY2UgbmFtZQoKDQoFBAMCAQQSBKMBAgoKDQoFBAMCAQUSBKMBCxEKDQoFBAMC
AQESBKMBEiYKDQoFBAMCAQMSBKMBKSoKQQoEBAMCAhIEpgECJBozIFR5cGUgb2YgdGhlIHJl
c291cmNlIEZvciBlZy4g4oCcQ29tcHV0ZSBFbmdpbmXigJ0KCg0KBQQDAgIEEgSmAQIKCg0K
BQQDAgIFEgSmAQsRCg0KBQQDAgIBEgSmARIfCg0KBQQDAgIDEgSmASIjCk8KBAQDAgMSBKkB
Ai8aQSBUaGUgbmFtZSBvZiB0aGUgQmFja3VwIFBsYW4gYXBwbGllZCBvbiB0aGUgcmVzb3Vy
Y2UgdG8gcHJvdGVjdC4KCg0KBQQDAgMEEgSpAQIKCg0KBQQDAgMFEgSpAQsRCg0KBQQDAgMB
EgSpARIqCg0KBQQDAgMDEgSpAS0uCkMKBAQDAgQSBKwBAkcaNSBUaW1lc3RhbXAgd2hlbiB0
aGUgZmlyc3QgKG9sZGVzdCkgYmFja3VwIHdhcyB0YWtlbi4KCg0KBQQDAgQEEgSsAQIKCg0K
BQQDAgQGEgSsAQskCg0KBQQDAgQBEgSsASVCCg0KBQQDAgQDEgSsAUVGCjsKBAQDAgUSBK8B
AkYaLSBUaW1lc3RhbXAgd2hlbiB0aGUgbGF0ZXN0IGJhY2t1cCB3YXMgdGFrZW4uCgoNCgUE
AwIFBBIErwECCgoNCgUEAwIFBhIErwELJAoNCgUEAwIFARIErwElQQoNCgUEAwIFAxIErwFE
RQpDCgQEAwIGEgSyAQInGjUgQW1vdW50IG9mIHN0b3JhZ2Ugc3BhY2UgY29uc3VtZWQgYnkg
YmFja3VwcyBpbiBHaUIuCgoNCgUEAwIGBBIEsgECCgoNCgUEAwIGBRIEsgELEQoNCgUEAwIG
ARIEsgESIgoNCgUEAwIGAxIEsgElJgpsCgQEAwIHEgS2AQI1Gl4gVGhlIG1pbmltdW0gdGlt
ZWZyYW1lIGluIGRheXMgdGhhdCBiYWNrdXBzIGluIHRoYXQgdmF1bHQgYXJlIGJlaW5nCiBw
cm90ZWN0ZWQgZnJvbSBkZWxldGlvbi4KCg0KBQQDAgcEEgS2AQIKCg0KBQQDAgcFEgS2AQsQ
Cg0KBQQDAgcBEgS2AREwCg0KBQQDAgcDEgS2ATM0CigKBAQDAggSBLkBAi8aGiBTb3VyY2Ug
cmVzb3VyY2VfbG9jYXRpb24KCg0KBQQDAggEEgS5AQIKCg0KBQQDAggFEgS5AQsRCg0KBQQD
AggBEgS5ARIqCg0KBQQDAggDEgS5AS0uCmMKAgQEEga+AQD0AQEaVSBMb2cgZW50cnkgZm9y
IEJEUkJhY2t1cFBsYW5Kb2JMb2cgZm9yIHJlc291cmNlcyB1c2luZyBCYWNrdXBQbGFuCiBi
YXNlZCBwcm90ZWN0aW9uLgoKCwoDBAQBEgS+AQgbClMKBAQEAgASBMABAhQaRSBUaGUgam9i
X2lkIGZpZWxkIGRpc3BsYXlzIHRoZSBpZGVudGlmaWVyIG9mIHRoZSBqb2IgYmVpbmcgcmVw
b3J0ZWQuCgoNCgUEBAIABRIEwAECCAoNCgUEBAIAARIEwAEJDwoNCgUEBAIAAxIEwAESEwpp
CgQEBAIBEgTEAQIaGlsgVGhlIGNhdGVnb3J5IGZpZWxkIGRpc3BsYXlzIHRoZSBjYXRlZ29y
eSBvZiB0aGUgam9iLiBDYW4gYmUgb25lIG9mCiBbVVBEQVRFX0JBQ0tVUF9QTEFOXS4KCg0K
BQQEAgEFEgTEAQIICg0KBQQEAgEBEgTEAQkVCg0KBQQEAgEDEgTEARgZCm0KBAQEAgISBMgB
AhgaXyBUaGUgc3RhdHVzIGZpZWxkIGRpc3BsYXlzIHRoZSBzdGF0dXMgb2YgdGhlIGpvYi4g
Q2FuIGJlIG9uZSBvZgogW1JVTk5JTkcsU1VDQ0VTU0ZVTCwgRkFJTEVEXS4KCg0KBQQEAgIF
EgTIAQIICg0KBQQEAgIBEgTIAQkTCg0KBQQEAgIDEgTIARYXClQKBAQEAgMSBMsBAhsaRiBU
aGUgcmVzb3VyY2VfdHlwZSBmaWVsZCBkaXNwbGF5cyB0aGUgdHlwZSBvZiB0aGUgcHJvdGVj
dGVkIHJlc291cmNlLgoKDQoFBAQCAwUSBMsBAggKDQoFBAQCAwESBMsBCRYKDQoFBAQCAwMS
BMsBGRoKSAoEBAQCBBIEzgECHho6IENhbm9uaWNhbCByZXNvdXJjZSBuYW1lIGZvciBCYWNr
dXAgUGxhbiBQbGFuIG9mIHRoZSBqb2IuCgoNCgUEBAIEBRIEzgECCAoNCgUEBAIEARIEzgEJ
GQoNCgUEBAIEAxIEzgEcHQo6CgQEBAIFEgTRAQIuGiwgVXNlciBmcmllbmRseSByZXZpc2lv
biBpZCBlLmcuIHYwLCB2MSBldGMuCgoNCgUEBAIFBRIE0QECCAoNCgUEBAIFARIE0QEJKQoN
CgUEBAIFAxIE0QEsLQpECgQEBAIGEgTUAQIwGjYgRnVsbCByZXNvdXJjZSBuYW1lIGZvciBw
cmV2aW91cyBiYWNrdXAgcGxhbiByZXZpc2lvbgoKDQoFBAQCBgUSBNQBAggKDQoFBAQCBgES
BNQBCSsKDQoFBAQCBgMSBNQBLi8KOgoEBAQCBxIE1wECKRosIFVzZXIgZnJpZW5kbHkgcmV2
aXNpb24gaWQgZS5nLiB2MCwgdjEgZXRjLgoKDQoFBAQCBwUSBNcBAggKDQoFBAQCBwESBNcB
CSQKDQoFBAQCBwMSBNcBJygKPwoEBAQCCBIE2gECKxoxIEZ1bGwgcmVzb3VyY2UgbmFtZSBm
b3IgbmV3IGJhY2t1cCBwbGFuIHJldmlzaW9uCgoNCgUEBAIIBRIE2gECCAoNCgUEBAIIARIE
2gEJJgoNCgUEBAIIAxIE2gEpKgomCgQEBAIJEgTdAQIsGhggU3RhcnQgdGltZSBvZiB0aGUg
am9iLgoKDQoFBAQCCQYSBN0BAhsKDQoFBAQCCQESBN0BHCYKDQoFBAQCCQMSBN0BKSsKJAoE
BAQCChIE4AECKhoWIEVuZCB0aW1lIG9mIHRoZSBqb2IuCgoNCgUEBAIKBhIE4AECGwoNCgUE
BAIKARIE4AEcJAoNCgUEBAIKAxIE4AEnKQpCCgQEBAILEgTjAQImGjQgVGhlIHRvdGFsIG51
bWJlciBvZiB3b3JrbG9hZHMgYWZmZWN0ZWQgYnkgdGhlIGpvYi4KCg0KBQQEAgsFEgTjAQIH
Cg0KBQQEAgsBEgTjAQggCg0KBQQEAgsDEgTjASMlCisKBAQEAgwSBOYBAjcaHSBQcmV2aW91
cyBCYWNrdXAgUGxhbiBydWxlcy4KCg0KBQQEAgwEEgTmAQIKCg0KBQQEAgwGEgTmAQsbCg0K
BQQEAgwBEgTmARwxCg0KBQQEAgwDEgTmATQ2CioKBAQEAg0SBOkBAjYaHCBSZXZpc2VkIEJh
Y2t1cCBQbGFuIHJ1bGVzLgoKDQoFBAQCDQQSBOkBAgoKDQoFBAQCDQYSBOkBCxsKDQoFBAQC
DQESBOkBHDAKDQoFBAQCDQMSBOkBMzUKQgoEBAQCDhIE7AECGBo0IFRoZSBlcnJvciBjb2Rl
LiBPbmx5IHBvcHVsYXRlZCBpbiBlcnJvciBzY2VuYXJpb3MuCgoNCgUEBAIOBRIE7AECBwoN
CgUEBAIOARIE7AEIEgoNCgUEBAIOAxIE7AEVFwplCgQEBAIPEgTwAQIZGlcgVGhlIG5hbWUg
b2YgdGhlIGVycm9yIHR5cGUgZWcuIFBFUk1JU1NJT05fREVOSUVELiBPbmx5IHBvcHVsYXRl
ZCBpbiBlcnJvcgogc2NlbmFyaW9zLgoKDQoFBAQCDwUSBPABAggKDQoFBAQCDwESBPABCRMK
DQoFBAQCDwMSBPABFhgKUwoEBAQCEBIE8wECHBpFIFRoZSB1c2VyIHJlYWRhYmxlIGVycm9y
IG1lc3NhZ2UuIE9ubHkgcG9wdWxhdGVkIGluIGVycm9yIHNjZW5hcmlvcy4KCg0KBQQEAhAF
EgTzAQIICg0KBQQEAhABEgTzAQkWCg0KBQQEAhADEgTzARkbCm4KAgQFEgb4AQC1AgEaYCBM
b2cgZW50cnkgZm9yIEJEUkJhY2t1cFBsYW5Bc3NvY2lhdGlvbkpvYkxvZyBmb3IgcmVzb3Vy
Y2VzIHVzaW5nIEJhY2t1cFBsYW4KIGJhc2VkIHByb3RlY3Rpb24uCgoLCgMEBQESBPgBCCYK
UwoEBAUCABIE+gECHRpFIFRoZSBqb2JfaWQgZmllbGQgZGlzcGxheXMgdGhlIGlkZW50aWZp
ZXIgb2YgdGhlIGpvYiBiZWluZyByZXBvcnRlZC4KCg0KBQQFAgAEEgT6AQIKCg0KBQQFAgAF
EgT6AQsRCg0KBQQFAgABEgT6ARIYCg0KBQQFAgADEgT6ARscCl0KBAQFAgESBP4BAiMaTyBU
aGUgY2F0ZWdvcnkgZmllbGQgZGlzcGxheXMgdGhlIGNhdGVnb3J5IG9mIHRoZSBqb2IuIENh
biBiZSBvbmUgb2YKIFtVUERBVEVdLgoKDQoFBAUCAQQSBP4BAgoKDQoFBAUCAQUSBP4BCxEK
DQoFBAUCAQESBP4BEh4KDQoFBAUCAQMSBP4BISIKfwoEBAUCAhIEggICIRpxIFRoZSBzdGF0
dXMgZmllbGQgZGlzcGxheXMgdGhlIHN0YXR1cyBvZiB0aGUgam9iLiBDYW4gYmUgb25lIG9m
IFtSVU5OSU5HLAogUVVFVUVELCBTVUNDRVNTRlVMLCBGQUlMRUQsIFNLSVBQRURdLgoKDQoF
BAUCAgQSBIICAgoKDQoFBAUCAgUSBIICCxEKDQoFBAUCAgESBIICEhwKDQoFBAUCAgMSBIIC
HyAKPQoEBAUCAxIEhQICKxovIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJvdGVjdGVk
IHJlc291cmNlLgoKDQoFBAUCAwQSBIUCAgoKDQoFBAUCAwUSBIUCCxEKDQoFBAUCAwESBIUC
EiYKDQoFBAUCAwMSBIUCKSoKNgoEBAUCBBIEiAICKRooIHJlc291cmNlIGlkIG9mIHRoZSBw
cm90ZWN0ZWQgcmVzb3VyY2UuCgoNCgUEBQIEBBIEiAICCgoNCgUEBQIEBRIEiAILEQoNCgUE
BQIEARIEiAISJAoNCgUEBQIEAxIEiAInKAo8CgQEBQIFEgSLAgIvGi4gcmVzb3VyY2UgbG9j
YXRpb24gb2YgdGhlIHByb3RlY3RlZCByZXNvdXJjZS4KCg0KBQQFAgUEEgSLAgIKCg0KBQQF
AgUFEgSLAgsRCg0KBQQFAgUBEgSLAhIqCg0KBQQFAgUDEgSLAi0uClQKBAQFAgYSBI4CAiQa
RiBUaGUgcmVzb3VyY2VfdHlwZSBmaWVsZCBkaXNwbGF5cyB0aGUgdHlwZSBvZiB0aGUgcHJv
dGVjdGVkIHJlc291cmNlLgoKDQoFBAUCBgQSBI4CAgoKDQoFBAUCBgUSBI4CCxEKDQoFBAUC
BgESBI4CEh8KDQoFBAUCBgMSBI4CIiMKSgoEBAUCBxIEkQICMxo8IEZ1bGwgcmVzb3VyY2Ug
bmFtZSBmb3IgQmFja3VwIFBsYW4gQXNzb2NpYXRpb24gb2YgdGhlIGpvYi4KCg0KBQQFAgcE
EgSRAgIKCg0KBQQFAgcFEgSRAgsRCg0KBQQFAgcBEgSRAhIuCg0KBQQFAgcDEgSRAjEyCmIK
BAQFAggSBJUCAjAaVCBGdWxsIHJlc291cmNlIG5hbWUgZm9yIHByZXZpb3VzIEJhY2t1cCBQ
bGFuIG9mIHRoZSBqb2IuIFBvcHVsYXRlZCBmb3IKIFVwZGF0ZSBCUEEuCgoNCgUEBQIIBBIE
lQICCgoNCgUEBQIIBRIElQILEQoNCgUEBQIIARIElQISKwoNCgUEBQIIAxIElQIuLwo6CgQE
BQIJEgSYAgI4GiwgVXNlciBmcmllbmRseSByZXZpc2lvbiBpZCBlLmcuIHYwLCB2MSBldGMu
CgoNCgUEBQIJBBIEmAICCgoNCgUEBQIJBRIEmAILEQoNCgUEBQIJARIEmAISMgoNCgUEBQIJ
AxIEmAI1NwpECgQEBQIKEgSbAgI6GjYgRnVsbCByZXNvdXJjZSBuYW1lIGZvciBwcmV2aW91
cyBiYWNrdXAgcGxhbiByZXZpc2lvbgoKDQoFBAUCCgQSBJsCAgoKDQoFBAUCCgUSBJsCCxEK
DQoFBAUCCgESBJsCEjQKDQoFBAUCCgMSBJsCNzkKWgoEBAUCCxIEngICLBpMIEZ1bGwgcmVz
b3VyY2UgbmFtZSBmb3IgbmV3IEJhY2t1cCBQbGFuLiBQb3B1bGF0ZWQgZm9yIFVwZGF0ZSAm
IENyZWF0ZSBCUEEuCgoNCgUEBQILBBIEngICCgoNCgUEBQILBRIEngILEQoNCgUEBQILARIE
ngISJgoNCgUEBQILAxIEngIpKwo6CgQEBQIMEgShAgIzGiwgVXNlciBmcmllbmRseSByZXZp
c2lvbiBpZCBlLmcuIHYwLCB2MSBldGMuCgoNCgUEBQIMBBIEoQICCgoNCgUEBQIMBRIEoQIL
EQoNCgUEBQIMARIEoQISLQoNCgUEBQIMAxIEoQIwMgo/CgQEBQINEgSkAgI1GjEgRnVsbCBy
ZXNvdXJjZSBuYW1lIGZvciBuZXcgYmFja3VwIHBsYW4gcmV2aXNpb24KCg0KBQQFAg0EEgSk
AgIKCg0KBQQFAg0FEgSkAgsRCg0KBQQFAg0BEgSkAhIvCg0KBQQFAg0DEgSkAjI0CiYKBAQF
Ag4SBKcCAjUaGCBTdGFydCB0aW1lIG9mIHRoZSBqb2IuCgoNCgUEBQIOBBIEpwICCgoNCgUE
BQIOBhIEpwILJAoNCgUEBQIOARIEpwIlLwoNCgUEBQIOAxIEpwIyNAokCgQEBQIPEgSqAgIz
GhYgRW5kIHRpbWUgb2YgdGhlIGpvYi4KCg0KBQQFAg8EEgSqAgIKCg0KBQQFAg8GEgSqAgsk
Cg0KBQQFAg8BEgSqAiUtCg0KBQQFAg8DEgSqAjAyCkIKBAQFAhASBK0CAiEaNCBUaGUgZXJy
b3IgY29kZS4gT25seSBwb3B1bGF0ZWQgaW4gZXJyb3Igc2NlbmFyaW9zLgoKDQoFBAUCEAQS
BK0CAgoKDQoFBAUCEAUSBK0CCxAKDQoFBAUCEAESBK0CERsKDQoFBAUCEAMSBK0CHiAKZQoE
BAUCERIEsQICIhpXIFRoZSBuYW1lIG9mIHRoZSBlcnJvciB0eXBlIGVnLiBQRVJNSVNTSU9O
X0RFTklFRC4gT25seSBwb3B1bGF0ZWQgaW4gZXJyb3IKIHNjZW5hcmlvcy4KCg0KBQQFAhEE
EgSxAgIKCg0KBQQFAhEFEgSxAgsRCg0KBQQFAhEBEgSxAhIcCg0KBQQFAhEDEgSxAh8hClMK
BAQFAhISBLQCAiUaRSBUaGUgdXNlciByZWFkYWJsZSBlcnJvciBtZXNzYWdlLiBPbmx5IHBv
cHVsYXRlZCBpbiBlcnJvciBzY2VuYXJpb3MuCgoNCgUEBQISBBIEtAICCgoNCgUEBQISBRIE
tAILEQoNCgUEBQISARIEtAISHwoNCgUEBQISAxIEtAIiJAoxCgIEBhIGuAIA2QIBGiMgTG9n
IGVudHJ5IGZvciBCRFIgTGllbiBFdmVudCBMb2cuCgoLCgMEBgESBLgCCBcKOgoEBAYCABIE
ugICHxosIEEgdW5pcXVlIFVVSUQgZm9yIHRoaXMgc3BlY2lmaWMgbG9nIGVudHJ5LgoKDQoF
BAYCAAQSBLoCAgoKDQoFBAYCAAUSBLoCCxEKDQoFBAYCAAESBLoCEhoKDQoFBAYCAAMSBLoC
HR4KSgoEBAYCARIEvQICHRo8IEluZGljYXRlcyB3aGV0aGVyIHByb3RlY3Rpb24gd2FzIGJl
aW5nIGFwcGxpZWQgb3IgcmVtb3ZlZC4KCg0KBQQGAgEEEgS9AgIKCg0KBQQGAgEFEgS9AgsR
Cg0KBQQGAgEBEgS9AhIYCg0KBQQGAgEDEgS9AhscCjoKBAQGAgISBMACAh0aLCBUaGUgb3V0
Y29tZSBvZiB0aGUgYWN0aW9uLCBlLmcuLCAiRkFJTEVEIi4KCg0KBQQGAgIEEgTAAgIKCg0K
BQQGAgIFEgTAAgsRCg0KBQQGAgIBEgTAAhIYCg0KBQQGAgIDEgTAAhscCj4KBAQGAgMSBMMC
AjQaMCBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIGN1cnJlbnQgZXZlbnQgb2NjdXJyZWQuCgoN
CgUEBgIDBBIEwwICCgoNCgUEBgIDBhIEwwILJAoNCgUEBgIDARIEwwIlLwoNCgUEBgIDAxIE
wwIyMwqhAgoEBAYCBBIEyQICIhqSAiBBIHN0cmluZyBkZW5vdGluZyB0aGUgdXNlciBvciBz
eXN0ZW0gd2hpY2ggb3JpZ2luYXRlZCB0aGUgbGllbiAoYXMKIGRlZmluZWQgaW4gdGhlIENs
b3VkIFJlc291cmNlIE1hbmFnZXIgTGllbnMgQVBJKS4gRm9yIGxpZW5zIG1hbmFnZWQgYnkg
dGhlCiBCYWNrdXAgYW5kIERSIFNlcnZpY2UsIHRoaXMgcmVwcmVzZW50cyB0aGUgc2Vydmlj
ZSBhbmQgbG9jYXRpb24gbWFuYWdpbmcKIHRoZSBsaWVuIChlLmcuICdiYWNrdXBkci5nb29n
bGVhcGlzLmNvbS91cy1jZW50cmFsMScpLgoKDQoFBAYCBAQSBMkCAgoKDQoFBAYCBAUSBMkC
CxEKDQoFBAYCBAESBMkCEh0KDQoFBAYCBAMSBMkCICEKuQEKBAQGAgUSBM4CAiAaqgEgVGhl
IGNhbm9uaWNhbCBudW1lcmljIGVycm9yIGNvZGUgKGNvcnJlc3BvbmRpbmcgdG8gYGdvb2ds
ZS5ycGMuQ29kZWAsCiBlLmcuLCA3IGZvciBQRVJNSVNTSU9OX0RFTklFRCkgaW5kaWNhdGlu
ZyB0aGUgZmFpbHVyZSByZWFzb24uCiBPbmx5IHBvcHVsYXRlZCBpbiBlcnJvciBzY2VuYXJp
b3MuCgoNCgUEBgIFBBIEzgICCgoNCgUEBgIFBRIEzgILEAoNCgUEBgIFARIEzgIRGwoNCgUE
BgIFAxIEzgIeHwq9AQoEBAYCBhIE0wICJBquASBBIGRldGFpbGVkLCBodW1hbi1yZWFkYWJs
ZSBlcnJvciBtZXNzYWdlIGV4cGxhaW5pbmcgd2h5IHRoZSBsaWVuIG9wZXJhdGlvbgogZmFp
bGVkIGFuZCBwcm92aWRpbmcgYWN0aW9uYWJsZSBjb250ZXh0IGZvciB0cm91Ymxlc2hvb3Rp
bmcuCiBPbmx5IHBvcHVsYXRlZCBpbiBlcnJvciBzY2VuYXJpb3MuCgoNCgUEBgIGBBIE0wIC
CgoNCgUEBgIGBRIE0wILEQoNCgUEBgIGARIE0wISHwoNCgUEBgIGAxIE0wIiIwqxAQoEBAYC
BxIE2AICIRqiASBUaGUgY2Fub25pY2FsIHN0cmluZyBpZGVudGlmaWVyIG9mIHRoZSBlcnJv
ciBjYXRlZ29yeSAoZS5nLgogJ1BFUk1JU1NJT05fREVOSUVEJywgJ0ZBSUxFRF9QUkVDT05E
SVRJT04nLCAnVU5BVVRIRU5USUNBVEVEJykuCiBPbmx5IHBvcHVsYXRlZCBpbiBlcnJvciBz
Y2VuYXJpb3MuCgoNCgUEBgIHBBIE2AICCgoNCgUEBgIHBRIE2AILEQoNCgUEBgIHARIE2AIS
HAoNCgUEBgIHAxIE2AIfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog ===
    # Fields for BDRBackupRestoreJobLog
    # Field: job_id Type: 9 ()
    # Field: job_category Type: 9 ()
    # Field: job_status Type: 9 ()
    # Field: source_resource_name Type: 9 ()
    # Field: source_resource_id Type: 9 ()
    # Field: restore_resource_name Type: 9 ()
    # Field: backup_name Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: backup_plan_name Type: 9 ()
    # Field: backup_rule Type: 9 ()
    # Field: backup_retention_days Type: 5 ()
    # Field: backup_vault_name Type: 9 ()
    # Field: incremental_backup_size_gib Type: 1 ()
    # Field: error_code Type: 5 ()
    # Field: error_type Type: 9 ()
    # Field: error_message Type: 9 ()
    # Field: backup_consistency_time Type: 11 (.google.protobuf.Timestamp)
    # Field: source_resource_location Type: 9 ()
    # Field: restore_resource_location Type: 9 ()
    # Field: recovery_point_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_source_name Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRProtectedResourceLog ===
    # Fields for BDRProtectedResourceLog
    # Field: source_resource_name Type: 9 ()
    # Field: source_resource_id Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: source_resource_data_size_gib Type: 1 ()
    # Field: current_backup_plan_name Type: 9 ()
    # Field: current_backup_rule_details Type: 11 (.google.cloud.backupdr.logging.v1.BackupRuleDetail)
    # Field: last_protected_on Type: 11 (.google.protobuf.Timestamp)
    # Field: current_backup_vault_name Type: 9 ()
    # Field: source_resource_location Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail ===
    # Fields for BackupRuleDetail
    # Field: rule_name Type: 9 ()
    # Field: retention_days Type: 5 ()
    # Field: recurrence Type: 9 ()
    # Field: recurrence_schedule Type: 9 ()
    # Field: backup_window Type: 9 ()
    # Field: backup_window_timezone Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupVaultDetailsLog ===
    # Fields for BDRBackupVaultDetailsLog
    # Field: backup_vault_name Type: 9 ()
    # Field: source_resource_name Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: current_backup_plan_name Type: 9 ()
    # Field: first_available_restore_point Type: 11 (.google.protobuf.Timestamp)
    # Field: last_available_restore_point Type: 11 (.google.protobuf.Timestamp)
    # Field: stored_bytes_gib Type: 1 ()
    # Field: minimum_enforced_retention_days Type: 5 ()
    # Field: source_resource_location Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanJobLog ===
    # Fields for BDRBackupPlanJobLog
    # Field: job_id Type: 9 ()
    # Field: job_category Type: 9 ()
    # Field: job_status Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: backup_plan_name Type: 9 ()
    # Field: previous_backup_plan_revision_id Type: 9 ()
    # Field: previous_backup_plan_revision_name Type: 9 ()
    # Field: new_backup_plan_revision_id Type: 9 ()
    # Field: new_backup_plan_revision_name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: workloads_affected_count Type: 5 ()
    # Field: previous_backup_rules Type: 11 (.google.cloud.backupdr.logging.v1.BackupRuleDetail)
    # Field: revised_backup_rules Type: 11 (.google.cloud.backupdr.logging.v1.BackupRuleDetail)
    # Field: error_code Type: 5 ()
    # Field: error_type Type: 9 ()
    # Field: error_message Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanAssociationJobLog ===
    # Fields for BDRBackupPlanAssociationJobLog
    # Field: job_id Type: 9 ()
    # Field: job_category Type: 9 ()
    # Field: job_status Type: 9 ()
    # Field: source_resource_name Type: 9 ()
    # Field: source_resource_id Type: 9 ()
    # Field: source_resource_location Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: backup_plan_association_name Type: 9 ()
    # Field: previous_backup_plan_name Type: 9 ()
    # Field: previous_backup_plan_revision_id Type: 9 ()
    # Field: previous_backup_plan_revision_name Type: 9 ()
    # Field: new_backup_plan_name Type: 9 ()
    # Field: new_backup_plan_revision_id Type: 9 ()
    # Field: new_backup_plan_revision_name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: error_code Type: 5 ()
    # Field: error_type Type: 9 ()
    # Field: error_message Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRLienEventLog ===
    # Fields for BDRLienEventLog
    # Field: event_id Type: 9 ()
    # Field: action Type: 9 ()
    # Field: status Type: 9 ()
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: lien_origin Type: 9 ()
    # Field: error_code Type: 5 ()
    # Field: error_message Type: 9 ()
    # Field: error_type Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::Logging::V1::BdrLog - Compiled Protocol Buffers messages for google/cloud/backupdr/logging/v1/bdr_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::Logging::V1::BdrLog;

    my $msg = Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog->new({
        job_id => $job_id,
        job_category => $job_category,
        job_status => $job_status,
        source_resource_name => $source_resource_name,
    });

    # Read or update a field
    my $val = $msg->job_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/logging/v1/bdr_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog

Log entry for Backup and Restore Job for resources using BackupPlan based
protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

The job_id field displays the identifier of the job being logged.

=item * C<< $msg->job_category() >> / C<< $msg->job_category($value) >>

Type: C<String>

The category field displays the category of the job.

=item * C<< $msg->job_status() >> / C<< $msg->job_status($value) >>

Type: C<String>

The status field displays the status of the job.

=item * C<< $msg->source_resource_name() >> / C<< $msg->source_resource_name($value) >>

Type: C<String>

Full resource name of the protected resource.

=item * C<< $msg->source_resource_id() >> / C<< $msg->source_resource_id($value) >>

Type: C<String>

The source resource ID.

=item * C<< $msg->restore_resource_name() >> / C<< $msg->restore_resource_name($value) >>

Type: C<String>

Full resource name of the restore resource. Only populated in
restore jobs.

=item * C<< $msg->backup_name() >> / C<< $msg->backup_name($value) >>

Type: C<String>

Full resource name of the backup created in backup jobs and used in restore
jobs.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

The resource_type field displays the type of the protected resource.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start time of the job.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End time of the job.

=item * C<< $msg->backup_plan_name() >> / C<< $msg->backup_plan_name($value) >>

Type: C<String>

Full resource name for Backup Plan of the job. Only populated for Scheduled
Backup and Adhoc Backup.

=item * C<< $msg->backup_rule() >> / C<< $msg->backup_rule($value) >>

Type: C<String>

Name of the backup rule. Only populated for Scheduled Backup and Adhoc
Backup.

=item * C<< $msg->backup_retention_days() >> / C<< $msg->backup_retention_days($value) >>

Type: C<Int32>

Backup retention in days.

=item * C<< $msg->backup_vault_name() >> / C<< $msg->backup_vault_name($value) >>

Type: C<String>

Full resource name backup vault name

=item * C<< $msg->incremental_backup_size_gib() >> / C<< $msg->incremental_backup_size_gib($value) >>

Type: C<Double>

The amount of incremental backup data copied.

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Int32>

The error code. Only populated in error scenarios.

=item * C<< $msg->error_type() >> / C<< $msg->error_type($value) >>

Type: C<String>

The name of the error type eg. PERMISSION_DENIED. Only populated in error
scenarios.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The user readable error message. Only populated in error scenarios.

=item * C<< $msg->backup_consistency_time() >> / C<< $msg->backup_consistency_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Backup consistency time.

=item * C<< $msg->source_resource_location() >> / C<< $msg->source_resource_location($value) >>

Type: C<String>

Source resource location.

=item * C<< $msg->restore_resource_location() >> / C<< $msg->restore_resource_location($value) >>

Type: C<String>

Restore resource location.

=item * C<< $msg->recovery_point_time() >> / C<< $msg->recovery_point_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Recovery point time.

=item * C<< $msg->data_source_name() >> / C<< $msg->data_source_name($value) >>

Type: C<String>

Canonical Data Source Name

=back

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRProtectedResourceLog

Log entry for BDRProtectedResource Log for resources using BackupPlan based
protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_resource_name() >> / C<< $msg->source_resource_name($value) >>

Type: C<String>

Full canonical source resource name.

=item * C<< $msg->source_resource_id() >> / C<< $msg->source_resource_id($value) >>

Type: C<String>

The source resource ID. Instance Id for GCE.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Type of the resource. For eg. “Compute Engine”.

=item * C<< $msg->source_resource_data_size_gib() >> / C<< $msg->source_resource_data_size_gib($value) >>

Type: C<Double>

The size of the protected source resource in GiB, rounded to 2 decimal
places.

=item * C<< $msg->current_backup_plan_name() >> / C<< $msg->current_backup_plan_name($value) >>

Type: C<String>

Complete canonical name of the Backup plan currently associated with the
source resource.

=item * C<< $msg->current_backup_rule_details() >> / C<< $msg->current_backup_rule_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail>)

Backup Rule details of the backup plan currently associated with the source
resource.

=item * C<< $msg->last_protected_on() >> / C<< $msg->last_protected_on($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the resource was last protected.

=item * C<< $msg->current_backup_vault_name() >> / C<< $msg->current_backup_vault_name($value) >>

Type: C<String>

Full Resource Name of the backup vault currently associated with the source
resource.

=item * C<< $msg->source_resource_location() >> / C<< $msg->source_resource_location($value) >>

Type: C<String>

Source resource_location

=back

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule_name() >> / C<< $msg->rule_name($value) >>

Type: C<String>

Backup Rule Name.

=item * C<< $msg->retention_days() >> / C<< $msg->retention_days($value) >>

Type: C<Int32>

Backup Retention in Days.

=item * C<< $msg->recurrence() >> / C<< $msg->recurrence($value) >>

Type: C<String>

Recurrence Type. For Eg. “Weekly”,” Monthly” or “Daily”.

=item * C<< $msg->recurrence_schedule() >> / C<< $msg->recurrence_schedule($value) >>

Type: C<String>

Recurrence Repeat Schedule. For Eg. “1st and 25th day of the month.”

=item * C<< $msg->backup_window() >> / C<< $msg->backup_window($value) >>

Type: C<String>

Backup Window For Eg. “00:00 to 06:00”

=item * C<< $msg->backup_window_timezone() >> / C<< $msg->backup_window_timezone($value) >>

Type: C<String>

Backup Window Timezone in IANA format. For Eg. “America/Los_Angeles”

=back

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupVaultDetailsLog

Log entry for BDRBackupVaultDetails Log for resources using BackupPlan based
protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_vault_name() >> / C<< $msg->backup_vault_name($value) >>

Type: C<String>

Relative resource name of Backup Vault

=item * C<< $msg->source_resource_name() >> / C<< $msg->source_resource_name($value) >>

Type: C<String>

Relative source resource name

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Type of the resource For eg. “Compute Engine”

=item * C<< $msg->current_backup_plan_name() >> / C<< $msg->current_backup_plan_name($value) >>

Type: C<String>

The name of the Backup Plan applied on the resource to protect.

=item * C<< $msg->first_available_restore_point() >> / C<< $msg->first_available_restore_point($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the first (oldest) backup was taken.

=item * C<< $msg->last_available_restore_point() >> / C<< $msg->last_available_restore_point($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the latest backup was taken.

=item * C<< $msg->stored_bytes_gib() >> / C<< $msg->stored_bytes_gib($value) >>

Type: C<Double>

Amount of storage space consumed by backups in GiB.

=item * C<< $msg->minimum_enforced_retention_days() >> / C<< $msg->minimum_enforced_retention_days($value) >>

Type: C<Int32>

The minimum timeframe in days that backups in that vault are being
protected from deletion.

=item * C<< $msg->source_resource_location() >> / C<< $msg->source_resource_location($value) >>

Type: C<String>

Source resource_location

=back

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanJobLog

Log entry for BDRBackupPlanJobLog for resources using BackupPlan
based protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

The job_id field displays the identifier of the job being reported.

=item * C<< $msg->job_category() >> / C<< $msg->job_category($value) >>

Type: C<String>

The category field displays the category of the job. Can be one of
[UPDATE_BACKUP_PLAN].

=item * C<< $msg->job_status() >> / C<< $msg->job_status($value) >>

Type: C<String>

The status field displays the status of the job. Can be one of
[RUNNING,SUCCESSFUL, FAILED].

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

The resource_type field displays the type of the protected resource.

=item * C<< $msg->backup_plan_name() >> / C<< $msg->backup_plan_name($value) >>

Type: C<String>

Canonical resource name for Backup Plan Plan of the job.

=item * C<< $msg->previous_backup_plan_revision_id() >> / C<< $msg->previous_backup_plan_revision_id($value) >>

Type: C<String>

User friendly revision id e.g. v0, v1 etc.

=item * C<< $msg->previous_backup_plan_revision_name() >> / C<< $msg->previous_backup_plan_revision_name($value) >>

Type: C<String>

Full resource name for previous backup plan revision

=item * C<< $msg->new_backup_plan_revision_id() >> / C<< $msg->new_backup_plan_revision_id($value) >>

Type: C<String>

User friendly revision id e.g. v0, v1 etc.

=item * C<< $msg->new_backup_plan_revision_name() >> / C<< $msg->new_backup_plan_revision_name($value) >>

Type: C<String>

Full resource name for new backup plan revision

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start time of the job.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End time of the job.

=item * C<< $msg->workloads_affected_count() >> / C<< $msg->workloads_affected_count($value) >>

Type: C<Int32>

The total number of workloads affected by the job.

=item * C<< $msg->previous_backup_rules() >> / C<< $msg->previous_backup_rules($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail>)

Previous Backup Plan rules.

=item * C<< $msg->revised_backup_rules() >> / C<< $msg->revised_backup_rules($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail>)

Revised Backup Plan rules.

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Int32>

The error code. Only populated in error scenarios.

=item * C<< $msg->error_type() >> / C<< $msg->error_type($value) >>

Type: C<String>

The name of the error type eg. PERMISSION_DENIED. Only populated in error
scenarios.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The user readable error message. Only populated in error scenarios.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanAssociationJobLog

Log entry for BDRBackupPlanAssociationJobLog for resources using BackupPlan
based protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

The job_id field displays the identifier of the job being reported.

=item * C<< $msg->job_category() >> / C<< $msg->job_category($value) >>

Type: C<String>

The category field displays the category of the job. Can be one of
[UPDATE].

=item * C<< $msg->job_status() >> / C<< $msg->job_status($value) >>

Type: C<String>

The status field displays the status of the job. Can be one of [RUNNING,
QUEUED, SUCCESSFUL, FAILED, SKIPPED].

=item * C<< $msg->source_resource_name() >> / C<< $msg->source_resource_name($value) >>

Type: C<String>

Full resource name of the protected resource.

=item * C<< $msg->source_resource_id() >> / C<< $msg->source_resource_id($value) >>

Type: C<String>

resource id of the protected resource.

=item * C<< $msg->source_resource_location() >> / C<< $msg->source_resource_location($value) >>

Type: C<String>

resource location of the protected resource.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

The resource_type field displays the type of the protected resource.

=item * C<< $msg->backup_plan_association_name() >> / C<< $msg->backup_plan_association_name($value) >>

Type: C<String>

Full resource name for Backup Plan Association of the job.

=item * C<< $msg->previous_backup_plan_name() >> / C<< $msg->previous_backup_plan_name($value) >>

Type: C<String>

Full resource name for previous Backup Plan of the job. Populated for
Update BPA.

=item * C<< $msg->previous_backup_plan_revision_id() >> / C<< $msg->previous_backup_plan_revision_id($value) >>

Type: C<String>

User friendly revision id e.g. v0, v1 etc.

=item * C<< $msg->previous_backup_plan_revision_name() >> / C<< $msg->previous_backup_plan_revision_name($value) >>

Type: C<String>

Full resource name for previous backup plan revision

=item * C<< $msg->new_backup_plan_name() >> / C<< $msg->new_backup_plan_name($value) >>

Type: C<String>

Full resource name for new Backup Plan. Populated for Update & Create BPA.

=item * C<< $msg->new_backup_plan_revision_id() >> / C<< $msg->new_backup_plan_revision_id($value) >>

Type: C<String>

User friendly revision id e.g. v0, v1 etc.

=item * C<< $msg->new_backup_plan_revision_name() >> / C<< $msg->new_backup_plan_revision_name($value) >>

Type: C<String>

Full resource name for new backup plan revision

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start time of the job.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End time of the job.

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Int32>

The error code. Only populated in error scenarios.

=item * C<< $msg->error_type() >> / C<< $msg->error_type($value) >>

Type: C<String>

The name of the error type eg. PERMISSION_DENIED. Only populated in error
scenarios.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The user readable error message. Only populated in error scenarios.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRLienEventLog

Log entry for BDR Lien Event Log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

A unique UUID for this specific log entry.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Indicates whether protection was being applied or removed.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<String>

The outcome of the action, e.g., "FAILED".

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp when the current event occurred.

=item * C<< $msg->lien_origin() >> / C<< $msg->lien_origin($value) >>

Type: C<String>

A string denoting the user or system which originated the lien (as
defined in the Cloud Resource Manager Liens API). For liens managed by the
Backup and DR Service, this represents the service and location managing
the lien (e.g. 'backupdr.googleapis.com/us-central1').

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Int32>

The canonical numeric error code (corresponding to `google.rpc.Code`,
e.g., 7 for PERMISSION_DENIED) indicating the failure reason.
Only populated in error scenarios.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

A detailed, human-readable error message explaining why the lien operation
failed and providing actionable context for troubleshooting.
Only populated in error scenarios.

=item * C<< $msg->error_type() >> / C<< $msg->error_type($value) >>

Type: C<String>

The canonical string identifier of the error category (e.g.
'PERMISSION_DENIED', 'FAILED_PRECONDITION', 'UNAUTHENTICATED').
Only populated in error scenarios.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::Logging::V1::BdrLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
