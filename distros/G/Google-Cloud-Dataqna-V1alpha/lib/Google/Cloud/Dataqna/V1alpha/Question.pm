package Google::Cloud::Dataqna::V1alpha::Question;

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
    eval { require Google::Cloud::Dataqna::V1alpha::AnnotatedString };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFscGhhL3F1ZXN0aW9uLnByb3RvEhxnb29nbGUu
Y2xvdWQuZGF0YXFuYS52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjNnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFs
cGhhL2Fubm90YXRlZF9zdHJpbmcucHJvdG8aGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnBy
b3RvIpgFCghRdWVzdGlvbhIaCgRuYW1lGAEgASgJQgbgQQPgQQVSBG5hbWUSHgoGc2NvcGVz
GAIgAygJQgbgQQLgQQVSBnNjb3BlcxIcCgVxdWVyeRgDIAEoCUIG4EEC4EEFUgVxdWVyeRI2
ChdkYXRhX3NvdXJjZV9hbm5vdGF0aW9ucxgEIAMoCVIVZGF0YVNvdXJjZUFubm90YXRpb25z
ElUKD2ludGVycHJldF9lcnJvchgFIAEoCzIsLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxw
aGEuSW50ZXJwcmV0RXJyb3JSDmludGVycHJldEVycm9yElYKD2ludGVycHJldGF0aW9ucxgG
IAMoCzIsLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50ZXJwcmV0YXRpb25SD2lu
dGVycHJldGF0aW9ucxI7CgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCmNyZWF0ZVRpbWUSIgoKdXNlcl9lbWFpbBgIIAEoCUID4EEDUgl1c2VyRW1h
aWwSUQoLZGVidWdfZmxhZ3MYCSABKAsyKC5nb29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhh
LkRlYnVnRmxhZ3NCBuBBBeBBBFIKZGVidWdGbGFncxIzCgpkZWJ1Z19pbmZvGAogASgLMhQu
Z29vZ2xlLnByb3RvYnVmLkFueVIJZGVidWdJbmZvOmLqQV8KH2RhdGFxbmEuZ29vZ2xlYXBp
cy5jb20vUXVlc3Rpb24SPHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9xdWVzdGlvbnMve3F1ZXN0aW9ufSLPBwoOSW50ZXJwcmV0RXJyb3ISGAoHbWVzc2FnZRgB
IAEoCVIHbWVzc2FnZRJTCgRjb2RlGAIgASgOMj8uZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFh
bHBoYS5JbnRlcnByZXRFcnJvci5JbnRlcnByZXRFcnJvckNvZGVSBGNvZGUSXAoHZGV0YWls
cxgDIAEoCzJCLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50ZXJwcmV0RXJyb3Iu
SW50ZXJwcmV0RXJyb3JEZXRhaWxzUgdkZXRhaWxzGpADChVJbnRlcnByZXRFcnJvckRldGFp
bHMSeQoTdW5zdXBwb3J0ZWRfZGV0YWlscxgBIAEoCzJILmdvb2dsZS5jbG91ZC5kYXRhcW5h
LnYxYWxwaGEuSW50ZXJwcmV0RXJyb3IuSW50ZXJwcmV0VW5zdXBwb3J0ZWREZXRhaWxzUhJ1
bnN1cHBvcnRlZERldGFpbHMShgEKGGluY29tcGxldGVfcXVlcnlfZGV0YWlscxgCIAEoCzJM
Lmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50ZXJwcmV0RXJyb3IuSW50ZXJwcmV0
SW5jb21wbGV0ZVF1ZXJ5RGV0YWlsc1IWaW5jb21wbGV0ZVF1ZXJ5RGV0YWlscxJzChFhbWJp
Z3VpdHlfZGV0YWlscxgDIAEoCzJGLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50
ZXJwcmV0RXJyb3IuSW50ZXJwcmV0QW1iaWd1aXR5RGV0YWlsc1IQYW1iaWd1aXR5RGV0YWls
cxpTChtJbnRlcnByZXRVbnN1cHBvcnRlZERldGFpbHMSHAoJb3BlcmF0b3JzGAEgAygJUglv
cGVyYXRvcnMSFgoGaW50ZW50GAIgAygJUgZpbnRlbnQabAofSW50ZXJwcmV0SW5jb21wbGV0
ZVF1ZXJ5RGV0YWlscxJJCghlbnRpdGllcxgBIAMoDjItLmdvb2dsZS5jbG91ZC5kYXRhcW5h
LnYxYWxwaGEuSW50ZXJwcmV0RW50aXR5UghlbnRpdGllcxobChlJbnRlcnByZXRBbWJpZ3Vp
dHlEZXRhaWxzIn0KEkludGVycHJldEVycm9yQ29kZRIkCiBJTlRFUlBSRVRfRVJST1JfQ09E
RV9VTlNQRUNJRklFRBAAEhEKDUlOVkFMSURfUVVFUlkQARIYChRGQUlMRURfVE9fVU5ERVJT
VEFORBACEhQKEEZBSUxFRF9UT19BTlNXRVIQAyLBAwoNRXhlY3V0aW9uSW5mbxJCChNqb2Jf
Y3JlYXRpb25fc3RhdHVzGAEgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSEWpvYkNyZWF0aW9u
U3RhdHVzEm0KE2pvYl9leGVjdXRpb25fc3RhdGUYAiABKA4yPS5nb29nbGUuY2xvdWQuZGF0
YXFuYS52MWFscGhhLkV4ZWN1dGlvbkluZm8uSm9iRXhlY3V0aW9uU3RhdGVSEWpvYkV4ZWN1
dGlvblN0YXRlEjsKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKY3JlYXRlVGltZRJMCgxiaWdxdWVyeV9qb2IYBCABKAsyKS5nb29nbGUuY2xvdWQu
ZGF0YXFuYS52MWFscGhhLkJpZ1F1ZXJ5Sm9iUgtiaWdxdWVyeUpvYiJyChFKb2JFeGVjdXRp
b25TdGF0ZRIjCh9KT0JfRVhFQ1VUSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAASEAoMTk9UX0VY
RUNVVEVEEAESCwoHUlVOTklORxACEg0KCVNVQ0NFRURFRBADEgoKBkZBSUxFRBAEIl8KC0Jp
Z1F1ZXJ5Sm9iEhUKBmpvYl9pZBgBIAEoCVIFam9iSWQSHQoKcHJvamVjdF9pZBgCIAEoCVIJ
cHJvamVjdElkEhoKCGxvY2F0aW9uGAMgASgJUghsb2NhdGlvbiLcAwoOSW50ZXJwcmV0YXRp
b24SIQoMZGF0YV9zb3VyY2VzGAEgAygJUgtkYXRhU291cmNlcxIeCgpjb25maWRlbmNlGAIg
ASgBUgpjb25maWRlbmNlEiUKDnVudXNlZF9waHJhc2VzGAMgAygJUg11bnVzZWRQaHJhc2Vz
ElIKDmh1bWFuX3JlYWRhYmxlGAQgASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBo
YS5IdW1hblJlYWRhYmxlUg1odW1hblJlYWRhYmxlEnAKGGludGVycHJldGF0aW9uX3N0cnVj
dHVyZRgFIAEoCzI1Lmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50ZXJwcmV0YXRp
b25TdHJ1Y3R1cmVSF2ludGVycHJldGF0aW9uU3RydWN0dXJlEkYKCmRhdGFfcXVlcnkYBiAB
KAsyJy5nb29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhhLkRhdGFRdWVyeVIJZGF0YVF1ZXJ5
ElIKDmV4ZWN1dGlvbl9pbmZvGAcgASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBo
YS5FeGVjdXRpb25JbmZvUg1leGVjdXRpb25JbmZvIh0KCURhdGFRdWVyeRIQCgNzcWwYASAB
KAlSA3NxbCLVAQoNSHVtYW5SZWFkYWJsZRJoChhnZW5lcmF0ZWRfaW50ZXJwcmV0YXRpb24Y
ASABKAsyLS5nb29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhhLkFubm90YXRlZFN0cmluZ1IX
Z2VuZXJhdGVkSW50ZXJwcmV0YXRpb24SWgoRb3JpZ2luYWxfcXVlc3Rpb24YAiABKAsyLS5n
b29nbGUuY2xvdWQuZGF0YXFuYS52MWFscGhhLkFubm90YXRlZFN0cmluZ1IQb3JpZ2luYWxR
dWVzdGlvbiLMBAoXSW50ZXJwcmV0YXRpb25TdHJ1Y3R1cmUSeAoTdmlzdWFsaXphdGlvbl90
eXBlcxgBIAMoDjJHLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50ZXJwcmV0YXRp
b25TdHJ1Y3R1cmUuVmlzdWFsaXphdGlvblR5cGVSEnZpc3VhbGl6YXRpb25UeXBlcxJhCgtj
b2x1bW5faW5mbxgCIAMoCzJALmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuSW50ZXJw
cmV0YXRpb25TdHJ1Y3R1cmUuQ29sdW1uSW5mb1IKY29sdW1uSW5mbxpSCgpDb2x1bW5JbmZv
EiEKDG91dHB1dF9hbGlhcxgBIAEoCVILb3V0cHV0QWxpYXMSIQoMZGlzcGxheV9uYW1lGAIg
ASgJUgtkaXNwbGF5TmFtZSL/AQoRVmlzdWFsaXphdGlvblR5cGUSIgoeVklTVUFMSVpBVElP
Tl9UWVBFX1VOU1BFQ0lGSUVEEAASCQoFVEFCTEUQARINCglCQVJfQ0hBUlQQAhIQCgxDT0xV
TU5fQ0hBUlQQAxIMCghUSU1FTElORRAEEhAKDFNDQVRURVJfUExPVBAFEg0KCVBJRV9DSEFS
VBAGEg4KCkxJTkVfQ0hBUlQQBxIOCgpBUkVBX0NIQVJUEAgSDwoLQ09NQk9fQ0hBUlQQCRIN
CglISVNUT0dSQU0QChIRCg1HRU5FUklDX0NIQVJUEAsSGAoUQ0hBUlRfTk9UX1VOREVSU1RP
T0QQDCKhBQoKRGVidWdGbGFncxIoChBpbmNsdWRlX3ZhX3F1ZXJ5GAEgASgIUg5pbmNsdWRl
VmFRdWVyeRI1ChdpbmNsdWRlX25lc3RlZF92YV9xdWVyeRgCIAEoCFIUaW5jbHVkZU5lc3Rl
ZFZhUXVlcnkSQAocaW5jbHVkZV9odW1hbl9pbnRlcnByZXRhdGlvbhgDIAEoCFIaaW5jbHVk
ZUh1bWFuSW50ZXJwcmV0YXRpb24SPQobaW5jbHVkZV9hcXVhX2RlYnVnX3Jlc3BvbnNlGAQg
ASgIUhhpbmNsdWRlQXF1YURlYnVnUmVzcG9uc2USIwoNdGltZV9vdmVycmlkZRgFIAEoA1IM
dGltZU92ZXJyaWRlEjUKF2lzX2ludGVybmFsX2dvb2dsZV91c2VyGAYgASgIUhRpc0ludGVy
bmFsR29vZ2xlVXNlchIhCgxpZ25vcmVfY2FjaGUYByABKAhSC2lnbm9yZUNhY2hlEj0KG2lu
Y2x1ZGVfc2VhcmNoX2VudGl0aWVzX3JwYxgIIAEoCFIYaW5jbHVkZVNlYXJjaEVudGl0aWVz
UnBjEkwKI2luY2x1ZGVfbGlzdF9jb2x1bW5fYW5ub3RhdGlvbnNfcnBjGAkgASgIUh9pbmNs
dWRlTGlzdENvbHVtbkFubm90YXRpb25zUnBjEkcKIGluY2x1ZGVfdmlydHVhbF9hbmFseXN0
X2VudGl0aWVzGAogASgIUh1pbmNsdWRlVmlydHVhbEFuYWx5c3RFbnRpdGllcxIsChJpbmNs
dWRlX3RhYmxlX2xpc3QYCyABKAhSEGluY2x1ZGVUYWJsZUxpc3QSLgoTaW5jbHVkZV9kb21h
aW5fbGlzdBgMIAEoCFIRaW5jbHVkZURvbWFpbkxpc3QqTgoPSW50ZXJwcmV0RW50aXR5EiAK
HElOVEVSUFJFVF9FTlRJVFlfVU5TUEVDSUZJRUQQABINCglESU1FTlNJT04QARIKCgZNRVRS
SUMQAkLPAQogY29tLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGFCDVF1ZXN0aW9uUHJv
dG9QAVo6Y2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhcW5hL2FwaXYxYWxwaGEvZGF0YXFuYXBi
O2RhdGFxbmFwYqoCHEdvb2dsZS5DbG91ZC5EYXRhUW5BLlYxQWxwaGHKAhxHb29nbGVcQ2xv
dWRcRGF0YVFuQVxWMWFscGhh6gIfR29vZ2xlOjpDbG91ZDo6RGF0YVFuQTo6VjFhbHBoYUrX
bwoHEgUOAJADAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAPQoJCgIDAxIDFQAjCgkKAgMEEgMW
ACkKCQoCAwUSAxcAIQoICgEIEgMZADkKCQoCCCUSAxkAOQoICgEIEgMaAFEKCQoCCAsSAxoA
UQoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcAC4KCQoCCAgSAxwALgoICgEIEgMdADkK
CQoCCAESAx0AOQoICgEIEgMeADkKCQoCCCkSAx4AOQoICgEIEgMfADgKCQoCCC0SAx8AOAq8
AQoCBAASBCQAZQEarwEgVGhlIHF1ZXN0aW9uIHJlc291cmNlIHJlcHJlc2VudHMgYSBuYXR1
cmFsIGxhbmd1YWdlIHF1ZXJ5LCBpdHMgc2V0dGluZ3MsCiB1bmRlcnN0YW5kaW5nIGdlbmVy
YXRlZCBieSB0aGUgc3lzdGVtLCBhbmQgYW5zd2VyIHJldHJpZXZhbCBzdGF0dXMuCiBBIHF1
ZXN0aW9uIGNhbm5vdCBiZSBtb2RpZmllZC4KCgoKAwQAARIDJAgQCgsKAwQABxIEJQIoBAoN
CgUEAAedCBIEJQIoBAqhAQoEBAACABIELAIvBBqSASBPdXRwdXQgb25seS4gSW1tdXRhYmxl
LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBRdWVzdGlvbi4gVGhlIElEIGlzIHNl
cnZlci1nZW5lcmF0ZWQuCiBFeGFtcGxlOiBgcHJvamVjdHMvZm9vL2xvY2F0aW9ucy9iYXIv
cXVlc3Rpb25zLzEyM2AKCgwKBQQAAgAFEgMsAggKDAoFBAACAAESAywJDQoMCgUEAAIAAxID
LBARCg0KBQQAAgAIEgQsEi8DCg8KCAQAAgAInAgAEgMtBC0KDwoIBAACAAicCAESAy4EKwqG
AwoEBAACARIEOAI7BBr3AiBSZXF1aXJlZC4gSW1tdXRhYmxlLiBTY29wZXMgdG8gYmUgdXNl
ZCBmb3IgdGhlIHF1ZXN0aW9uLiBBIHNjb3BlIGRlZmluZXMgdGhlIHJlbGV2YW50IGRhdGEg
c2V0CiBzY29wZS4gSXQgY2FuIGJlIGEgcmVmZXJlbmNlIHRvIGEgc3BlY2lmaWMgZGF0YSBz
b3VyY2Ugb3IgYSBjb2xsZWN0aW9uIG9mCiBkYXRhIHNvdXJjZXMuIEN1cnJlbnRseSwgc3Vw
cG9ydCBpcyBsaW1pdGVkIHRvIGEgc2luZ2xlIEJpZ1F1ZXJ5IHRhYmxlLgogVGhlcmUgbXVz
dCBiZSBleGFjdGx5IG9uZSBgc2NvcGVzYCBlbGVtZW50LgoKIEV4YW1wbGU6CiBgLy9iaWdx
dWVyeS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy90ZXN0LXByb2plY3QvZGF0YXNldHMvZm9v
L3RhYmxlcy9iYXJgCgoMCgUEAAIBBBIDOAIKCgwKBQQAAgEFEgM4CxEKDAoFBAACAQESAzgS
GAoMCgUEAAIBAxIDOBscCg0KBQQAAgEIEgQ4HTsDCg8KCAQAAgEInAgAEgM5BCoKDwoIBAAC
AQicCAESAzoEKwpDCgQEAAICEgQ+AkEEGjUgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHF1
ZXJ5IGluIG5hdHVyYWwgbGFuZ3VhZ2UuCgoMCgUEAAICBRIDPgIICgwKBQQAAgIBEgM+CQ4K
DAoFBAACAgMSAz4REgoNCgUEAAICCBIEPhNBAwoPCggEAAICCJwIABIDPwQqCg8KCAQAAgII
nAgBEgNABCsK3gEKBAQAAgMSA0YCLhrQASBBIGxpc3Qgb2YgYW5ub3RhdGlvbnMgdG8gdXNl
IGluc3RlYWQgb2YgdGhlIGRlZmF1bHQgYW5ub3RhdGlvbiBvZiBhIGRhdGEKIHNvdXJjZSAo
c2V0IGluIHRoZSBkYXRhIHNvdXJjZSByZWZlcmVuY2UgcmVzb3VyY2UpLiBUaGVyZSBtdXN0
IG5vdCBiZQogbW9yZSB0aGFuIG9uZSBhbm5vdGF0aW9uIHdpdGggdGhlIHNhbWUgZGF0YSBz
b3VyY2UgcmVmZXJlbmNlLgoKDAoFBAACAwQSA0YCCgoMCgUEAAIDBRIDRgsRCgwKBQQAAgMB
EgNGEikKDAoFBAACAwMSA0YsLQqjAwoEBAACBBIDTwIlGpUDIEFuIGVycm9yIGZpZWxkIGV4
cGxhaW5pbmcgd2h5IGludGVycHJldGF0aW9uIGZhaWxlZC4gVGhpcyBpcyBvbmx5IHBvcHVs
YXRlZAogaWYgdGhlIGludGVycHJldGF0aW9uIGZhaWxlZC4KCiBOb3RlOiBUaGlzIGlzIGRp
ZmZlcmVudCBmcm9tIGdldHRpbmcgYSBzdGF0dXMgZXJyb3Igb24gdGhlIHJlcXVlc3QgaXRz
ZWxmLgogVGhpcyBpcyBub3QgYSBjbGllbnQgb3Igc2VydmVyIGVycm9yIGFuZCB0aGUgUXVl
c3Rpb24gcmVzb3VyY2UgaXMgc3RpbGwKIHBlcnNpc3RlZCwgYnV0IHRoZSBzZXJ2aWNlIGNv
dWxkIG5vdCBpbnRlcnByZXQgdGhlIHF1ZXN0aW9uLiBDbGllbnRzIHNob3VsZAogcHJlc2Vu
dCB0aGUgZXJyb3IgdG8gdGhlIHVzZXIgc28gdGhlIHVzZXIgY2FuIHJlcGhyYXNlIHRoZSBx
dWVzdGlvbi4KCgwKBQQAAgQGEgNPAhAKDAoFBAACBAESA08RIAoMCgUEAAIEAxIDTyMkCjsK
BAQAAgUSA1ICLhouIEEgbGlzdCBvZiBpbnRlcnByZXRhdGlvbnMgZm9yIHRoaXMgcXVlc3Rp
b24uCgoMCgUEAAIFBBIDUgIKCgwKBQQAAgUGEgNSCxkKDAoFBAACBQESA1IaKQoMCgUEAAIF
AxIDUiwtCjIKBAQAAgYSA1UCLBolIFRpbWUgd2hlbiB0aGUgcXVlc3Rpb24gd2FzIGNyZWF0
ZWQuCgoMCgUEAAIGBhIDVQIbCgwKBQQAAgYBEgNVHCcKDAoFBAACBgMSA1UqKwpWCgQEAAIH
EgNYAkQaSSBPdXRwdXQgb25seS4gVGhlIGUtbWFpbCBhZGRyZXNzIG9mIHRoZSB1c2VyIHRo
YXQgY3JlYXRlZCB0aGlzIHF1ZXN0aW9uLgoKDAoFBAACBwUSA1gCCAoMCgUEAAIHARIDWAkT
CgwKBQQAAgcDEgNYFhcKDAoFBAACBwgSA1gYQwoPCggEAAIHCJwIABIDWBlCCmYKBAQAAggS
BFsCXgQaWCBJbnB1dCBvbmx5LiBJbW11dGFibGUuIEZsYWdzIHRvIHJlcXVlc3QgYWRkaXRp
b25hbCBpbmZvcm1hdGlvbiBmb3IgZGVidWdnaW5nIHB1cnBvc2VzLgoKDAoFBAACCAYSA1sC
DAoMCgUEAAIIARIDWw0YCgwKBQQAAggDEgNbGxwKDQoFBAACCAgSBFsdXgMKDwoIBAACCAic
CAASA1wEKwoPCggEAAIICJwIARIDXQQsCq8BCgQEAAIJEgNkAiYaoQEgVG9wIGxldmVsIGRl
YnVnIGluZm9ybWF0aW9uLgogVGhpcyB3aWxsIGJlIHN0b3JlZCBhcyB0aGUgdHlwZSBEZWJ1
Z0luZm9ybWF0aW9uLgogVXNpbmcgQW55IHNvIGNsaWVudHMgZG9uJ3QgbmVlZCB0byBwdWxs
IGluIGFueXRoaW5nCiBpbnNpZGUgdGhlIGRlYnVnIG1lc3NhZ2UuCgoMCgUEAAIJBhIDZAIV
CgwKBQQAAgkBEgNkFiAKDAoFBAACCQMSA2QjJQpACgIEARIFaAClAQEaMyBEZXRhaWxzIG9u
IHRoZSBmYWlsdXJlIHRvIGludGVycHJldCB0aGUgcXVlc3Rpb24uCgoKCgMEAQESA2gIFgoy
CgQEAQMAEgRqAnMDGiQgRGV0YWlscyBvbiBpbnRlcnByZXRhdGlvbiBmYWlsdXJlLgoKDAoF
BAEDAAESA2oKHwpBCgYEAQMAAgASA2wEOBoyIFBvcHVsYXRlZCBpZiBwYXJ0cyBvZiB0aGUg
cXVlcnkgYXJlIHVuc3VwcG9ydGVkLgoKDgoHBAEDAAIABhIDbAQfCg4KBwQBAwACAAESA2wg
MwoOCgcEAQMAAgADEgNsNjcKNgoGBAEDAAIBEgNvBEEaJyBQb3B1bGF0ZWQgaWYgdGhlIHF1
ZXJ5IGlzIGluY29tcGxldGUuCgoOCgcEAQMAAgEGEgNvBCMKDgoHBAEDAAIBARIDbyQ8Cg4K
BwQBAwACAQMSA28/QAo6CgYEAQMAAgISA3IENBorIFBvcHVsYXRlZCBpZiB0aGUgcXVlcnkg
d2FzIHRvbyBhbWJpZ3VvdXMuCgoOCgcEAQMAAgIGEgNyBB0KDgoHBAEDAAICARIDch4vCg4K
BwQBAwACAgMSA3IyMwo7CgQEAQMBEgR2AnwDGi0gRGV0YWlscyBhYm91dCB1bnN1cHBvcnRl
ZCBwYXJ0cyBpbiBhIHF1ZXJ5LgoKDAoFBAEDAQESA3YKJQo8CgYEAQMBAgASA3gEIhotIFVu
c3VwcG9ydGVkIG9wZXJhdG9ycy4gRm9yIGV4YW1wbGU6IG1lZGlhbi4KCg4KBwQBAwECAAQS
A3gEDAoOCgcEAQMBAgAFEgN4DRMKDgoHBAEDAQIAARIDeBQdCg4KBwQBAwECAAMSA3ggIQol
CgYEAQMBAgESA3sEHxoWIFVuc3VwcG9ydGVkIGludGVudHMuCgoOCgcEAQMBAgEEEgN7BAwK
DgoHBAEDAQIBBRIDew0TCg4KBwQBAwECAQESA3sUGgoOCgcEAQMBAgEDEgN7HR4KMwoEBAED
AhIFfwKCAQMaJCBEZXRhaWxzIGFib3V0IGFuIGluY29tcGxldGUgcXVlcnkuCgoMCgUEAQMC
ARIDfwopCjUKBgQBAwICABIEgQEEKholIExpc3Qgb2YgbWlzc2luZyBpbnRlcnByZXQgZW50
aXRpZXMuCgoPCgcEAQMCAgAEEgSBAQQMCg8KBwQBAwICAAYSBIEBDRwKDwoHBAEDAgIAARIE
gQEdJQoPCgcEAQMCAgADEgSBASgpCpkBCgQEAQMDEgaGAQKIAQMaiAEgRGV0YWlscyBhYm91
dCBhIHF1ZXJ5IHRoYXQgd2FzIHRvbyBhbWJpZ3VvdXMuIEN1cnJlbnRseSwgdGhlIG1lc3Nh
Z2UKIGhhcyBubyBmaWVsZHMgYW5kIGl0cyBwcmVzZW5jZSBzaWduYWxzIHRoYXQgdGhlcmUg
d2FzIGFtYmlndWl0eS4KCg0KBQQBAwMBEgSGAQojCmUKBAQBBAASBowBApsBAxpVIFRoZSBp
bnRlcnByZXQgZXJyb3IgY29kZSBwcm92aWRlcyBhbiBlcnJvciBjYXRlZ29yeSB3aHkgdGhl
IGludGVycHJldGF0aW9uCiBmYWlsZWQuCgoNCgUEAQQAARIEjAEHGQo4CgYEAQQAAgASBI4B
BCkaKCBObyBpbnRlcnByZXQgZXJyb3IgY29kZSB3YXMgc3BlY2lmaWVkLgoKDwoHBAEEAAIA
ARIEjgEEJAoPCgcEAQQAAgACEgSOAScoCikKBgQBBAACARIEkQEEFhoZIFRoZSBxdWVyeSBp
cyBub3QgdmFsaWQuCgoPCgcEAQQAAgEBEgSRAQQRCg8KBwQBBAACAQISBJEBFBUKcAoGBAEE
AAICEgSVAQQdGmAgVGhlIGludGVycHJldGVyIGZhaWxlZCB0byB1bmRlcnN0YW5kIHRoZSBx
dWVzdGlvbi4gRm9yIGV4YW1wbGUsIGJlY2F1c2UKIGl0IHdhcyB0b28gYW1iaWd1b3VzLgoK
DwoHBAEEAAICARIElQEEGAoPCgcEAQQAAgICEgSVARscCqkBCgYEAQQAAgMSBJoBBBkamAEg
VGhlIGludGVycHJldGVyIGNvdWxkIHVuZGVyc3RhbmQgdGhlIHF1ZXN0aW9uLCBidXQgd2Fz
IG5vdCBhYmxlIHRvIGFycml2ZQogYXQgYW4gYW5zd2VyLiBGb3IgZXhhbXBsZSwgYmVjYXVz
ZSBhIHJlcXVlc3RlZCBvcGVyYXRpb24gaXMgbm90CiBzdXBwb3J0ZWQuCgoPCgcEAQQAAgMB
EgSaAQQUCg8KBwQBBAACAwISBJoBFxgKVAoEBAECABIEngECFRpGIEVycm9yIG1lc3NhZ2Ug
ZXhwbGFpbmluZyB3aHkgdGhpcyBxdWVzdGlvbiBjb3VsZCBub3QgYmUgaW50ZXJwcmV0ZWQu
CgoNCgUEAQIABRIEngECCAoNCgUEAQIAARIEngEJEAoNCgUEAQIAAxIEngETFApOCgQEAQIB
EgShAQIeGkAgVGhlIGNvZGUgZm9yIHRoZSBlcnJvciBjYXRlZ29yeSB3aHkgdGhlIGludGVy
cHJldGF0aW9uIGZhaWxlZC4KCg0KBQQBAgEGEgShAQIUCg0KBQQBAgEBEgShARUZCg0KBQQB
AgEDEgShARwdCjIKBAQBAgISBKQBAiQaJCBEZXRhaWxzIG9uIGludGVycHJldGF0aW9uIGZh
aWx1cmUuCgoNCgUEAQICBhIEpAECFwoNCgUEAQICARIEpAEYHwoNCgUEAQICAxIEpAEiIwpZ
CgIEAhIGqAEAyAEBGksgSW5mb3JtYXRpb24gYWJvdXQgdGhlIGJhY2tlbmQgc3RhdHVzIChz
dWNoIGFzIEJpZ1F1ZXJ5KSBvZiB0aGUgZXhlY3V0aW9uLgoKCwoDBAIBEgSoAQgVCjoKBAQC
BAASBqoBArkBAxoqIEVudW0gb2YgcG9zc2libGUgam9iIGV4ZWN1dGlvbiBzdGF0dXNlcy4K
Cg0KBQQCBAABEgSqAQcYCjEKBgQCBAACABIErAEEKBohIE5vIGpvYiBleGVjdXRpb24gd2Fz
IHNwZWNpZmllZC4KCg8KBwQCBAACAAESBKwBBCMKDwoHBAIEAAIAAhIErAEmJwo2CgYEAgQA
AgESBK8BBBUaJiBObyBqb2IgZXhlY3V0aW9uIHdhcyByZXF1ZXN0ZWQsIHlldC4KCg8KBwQC
BAACAQESBK8BBBAKDwoHBAIEAAIBAhIErwETFAolCgYEAgQAAgISBLIBBBAaFSBUaGUgam9i
IGlzIHJ1bm5pbmcuCgoPCgcEAgQAAgIBEgSyAQQLCg8KBwQCBAACAgISBLIBDg8KMQoGBAIE
AAIDEgS1AQQSGiEgVGhlIGpvYiBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDwoHBAIEAAID
ARIEtQEEDQoPCgcEAgQAAgMCEgS1ARARCjMKBgQCBAACBBIEuAEEDxojIFRoZSBqb2IgY29t
cGxldGVkIHVuc3VjY2Vzc2Z1bGx5LgoKDwoHBAIEAAIEARIEuAEECgoPCgcEAgQAAgQCEgS4
AQ0OCkgKBAQCAgASBLwBAiwaOiBTdGF0dXMgcmV0dXJuZWQgYnkgdGhlIGJhY2tlbmQgd2hl
biB0aGUgam9iIHdhcyBjcmVhdGVkLgoKDQoFBAICAAYSBLwBAhMKDQoFBAICAAESBLwBFCcK
DQoFBAICAAMSBLwBKisKLAoEBAICARIEvwECLBoeIFN0YXR1cyBvZiB0aGUgam9iIGV4ZWN1
dGlvbi4KCg0KBQQCAgEGEgS/AQITCg0KBQQCAgEBEgS/ARQnCg0KBQQCAgEDEgS/ASorCjYK
BAQCAgISBMIBAiwaKCBUaW1lIHdoZW4gdGhlIGV4ZWN1dGlvbiB3YXMgdHJpZ2dlcmVkLgoK
DQoFBAICAgYSBMIBAhsKDQoFBAICAgESBMIBHCcKDQoFBAICAgMSBMIBKisKrQEKBAQCAgMS
BMcBAh8angEgQmlnUXVlcnkgam9iIGluZm9ybWF0aW9uLgogRnV0dXJlIHZlcnNpb25zIHdp
bGwgaGF2ZSBkaWZmZXJlbnQgYmFja2VuZHMuIEhlbmNlLCBjbGllbnRzIG11c3QgbWFrZSBz
dXJlCiB0aGV5IGNhbiBoYW5kbGUgaXQgd2hlbiB0aGlzIGZpZWxkIGlzIG5vdCBwb3B1bGF0
ZWQuCgoNCgUEAgIDBhIExwECDQoNCgUEAgIDARIExwEOGgoNCgUEAgIDAxIExwEdHgrUAQoC
BAMSBs0BANYBARrFASBCaWdRdWVyeSBqb2IgaW5mb3JtYXRpb24uIFRoaXMgY2FuIGJlIHVz
ZWQgdG8gcXVlcnkgdGhlIEJpZ1F1ZXJ5IEFQSSBhbmQKIHJldHJpZXZlIHRoZSBjdXJyZW50
IGpvYidzIHN0YXR1cyAodXNpbmcKIFtqb2JzLmdldF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2JpZ3F1ZXJ5L2RvY3MvcmVmZXJlbmNlL3Jlc3QvdjIvam9icy9nZXQpKS4KCgsKAwQD
ARIEzQEIEwobCgQEAwIAEgTPAQIUGg0gVGhlIGpvYiBJRC4KCg0KBQQDAgAFEgTPAQIICg0K
BQQDAgABEgTPAQkPCg0KBQQDAgADEgTPARITCioKBAQDAgESBNIBAhgaHCBUaGUgcHJvamVj
dCBJRCBvZiB0aGUgam9iLgoKDQoFBAMCAQUSBNIBAggKDQoFBAMCAQESBNIBCRMKDQoFBAMC
AQMSBNIBFhcKNgoEBAMCAhIE1QECFhooIFRoZSBsb2NhdGlvbiB3aGVyZSB0aGUgam9iIGlz
IHJ1bm5pbmcuCgoNCgUEAwICBRIE1QECCAoNCgUEAwICARIE1QEJEQoNCgUEAwICAxIE1QEU
FQo+CgIEBBIG2QEA8wEBGjAgQW4gaW50ZXJwcmV0YXRpb24gb2YgYSBuYXR1cmFsIGxhbmd1
YWdlIHF1ZXJ5LgoKCwoDBAQBEgTZAQgWCkcKBAQEAgASBNsBAiMaOSBMaXN0IG9mIGRhdGEg
c291cmNlcyB1c2VkIGluIHRoZSBjdXJyZW50IHVuZGVyc3RhbmRpbmcuCgoNCgUEBAIABBIE
2wECCgoNCgUEBAIABRIE2wELEQoNCgUEBAIAARIE2wESHgoNCgUEBAIAAxIE2wEhIgq+AQoE
BAQCARIE4AECGBqvASBUaGUgbGV2ZWwgb2YgY29uZmlkZW5jZSB0aGF0IG9uZSBvZiB0aGUg
aW50ZXJwcmV0YXRpb25zIGlzIGNvcnJlY3QuIFRoaXMgaXMKIGEgdmFsdWUgaW4gdGhlIHJh
bmdlIFswLCAxXSB3aGVyZSBhIHZhbHVlIG9mIDAuNSBvciBiZWxvdyBpcyB0byBiZQogY29u
c2lkZXJlZCBhIGxvdyBjb25maWRlbmNlLgoKDQoFBAQCAQUSBOABAggKDQoFBAQCAQESBOAB
CRMKDQoFBAQCAQMSBOABFhcKngEKBAQEAgISBOQBAiUajwEgQSBsaXN0IG9mIHVudXNlZCBw
aHJhc2VzLiBDbGllbnRzIHNob3VsZCBkaXNwbGF5IGEgRGlkIFlvdSBNZWFuIChEWU0pCiAg
ZGlhbG9nIGlmIHRoaXMgaXMgbm9uLWVtcHR5LCBldmVuIGlmIHRoaXMgaXMgdGhlIG9ubHkg
aW50ZXJwcmV0YXRpb24uCgoNCgUEBAICBBIE5AECCgoNCgUEBAICBRIE5AELEQoNCgUEBAIC
ARIE5AESIAoNCgUEBAICAxIE5AEjJAo7CgQEBAIDEgTnAQIjGi0gSHVtYW4gcmVhZGFibGUg
cmVwcmVzZW50YXRpb24gb2YgdGhlIHF1ZXJ5LgoKDQoFBAQCAwYSBOcBAg8KDQoFBAQCAwES
BOcBEB4KDQoFBAQCAwMSBOcBISIKdAoEBAQCBBIE6wECNxpmIEluZm9ybWF0aW9uIGFib3V0
IHRoZSBpbnRlcnByZXRhdGlvbiBzdHJ1Y3R1cmUgdGhhdCBoZWxwcyB0byB1bmRlcnN0YW5k
IGFuZAogdmlzdWFsaXplIHRoZSByZXNwb25zZS4KCg0KBQQEAgQGEgTrAQIZCg0KBQQEAgQB
EgTrARoyCg0KBQQEAgQDEgTrATU2CksKBAQEAgUSBO4BAhsaPSBSZXByZXNlbnRhdGlvbiBv
ZiB0aGUgZGF0YSBxdWVyeSB0byBiZSBzZW50IHRvIHRoZSBiYWNrZW5kLgoKDQoFBAQCBQYS
BO4BAgsKDQoFBAQCBQESBO4BDBYKDQoFBAQCBQMSBO4BGRoKgAEKBAQEAgYSBPIBAiMaciBJ
bmZvcm1hdGlvbiBhYm91dCB0aGUgYmFja2VuZCByZXNwb25zZS4gVGhpcyBpcyBwb3B1bGF0
ZWQgb25seSBpZiBleGVjdXRpb24KIG9mIGFuIGludGVycHJldGF0aW9uIHdhcyByZXF1ZXN0
ZWQuCgoNCgUEBAIGBhIE8gECDwoNCgUEBAIGARIE8gEQHgoNCgUEBAIGAxIE8gEhIgr1AgoC
BAUSBvsBAP4BARrmAiBSZXByZXNlbnRhdGlvbiBvZiB0aGUgZGF0YSBxdWVyeSBmb3IgdGhl
IGJhY2tlbmQuCiBUaGlzIGlzIHByb3ZpZGVkIGZvciBpbmZvcm1hdGlvbmFsIHB1cnBvc2Vz
IG9ubHkuIENsaWVudHMgc2hvdWxkIG5vdCB1c2UKIGl0IHRvIHNlbmQgaXQgdG8gdGhlIGJh
Y2tlbmQgZGlyZWN0bHksIGJ1dCByYXRoZXIgdXNlIHRoZSBgZXhlY3V0ZWAgUlBDCiB0byB0
cmlnZ2VyIHRoZSBleGVjdXRpb24uIFVzaW5nIHRoZSBgZXhlY3V0ZWAgUlBDIGlzIG5lZWRl
ZCBpbiBvcmRlciB0bwogdHJhY2sgdGhlIHN0YXRlIG9mIGEgcXVlc3Rpb24gYW5kIHJlcG9y
dCBvbiBpdCBjb3JyZWN0bHkgdG8gdGhlIGRhdGEKIGFkbWluaXN0cmF0b3JzLgoKCwoDBAUB
EgT7AQgRCkIKBAQFAgASBP0BAhEaNCBUaGUgZ2VuZXJhdGVkIFNRTCBxdWVyeSB0byBiZSBz
ZW50IHRvIHRoZSBiYWNrZW5kLgoKDQoFBAUCAAUSBP0BAggKDQoFBAUCAAESBP0BCQwKDQoF
BAUCAAMSBP0BDxAKLgoCBAYSBoECAIcCARogIEh1bWFuIHJlYWRhYmxlIGludGVycHJldGF0
aW9uLgoKCwoDBAYBEgSBAggVCj4KBAQGAgASBIMCAi8aMCBHZW5lcmF0ZWQgcXVlcnkgZXhw
bGFpbmluZyB0aGUgaW50ZXJwcmV0YXRpb24uCgoNCgUEBgIABhIEgwICEQoNCgUEBgIAARIE
gwISKgoNCgUEBgIAAxIEgwItLgoyCgQEBgIBEgSGAgIoGiQgQW5ub3RhdGlvbnMgb24gdGhl
IG9yaWdpbmFsIHF1ZXJ5LgoKDQoFBAYCAQYSBIYCAhEKDQoFBAYCAQESBIYCEiMKDQoFBAYC
AQMSBIYCJicKdAoCBAcSBosCANUCARpmIEluZm9ybWF0aW9uIGFib3V0IHRoZSBpbnRlcnBy
ZXRhdGlvbiBzdHJ1Y3R1cmUgdGhhdCBoZWxwcyB0byB1bmRlcnN0YW5kIGFuZAogdmlzdWFs
aXplIHRoZSByZXNwb25zZS4KCgsKAwQHARIEiwIIHwotCgQEBwMAEgaNAgKUAgMaHSBJbmZv
cm1hdGlvbiBhYm91dCBhIGNvbHVtbi4KCg0KBQQHAwABEgSNAgoUCqABCgYEBwMAAgASBJAC
BBwajwEgVGhlIGFsaWFzIG9mIHRoZSBvdXRwdXQgY29sdW1uIGFzIHVzZWQgYnkgdGhlIGJh
Y2tlbmQuIEZvciBleGFtcGxlLCB0aGUKIGZpZWxkIG5hbWUgaW4gdGhlIHNjaGVtYSBwcm92
aWRlZCBpbiB0aGUgcXVlcnkgcmVzcG9uc2UgaW4gQmlnUXVlcnkuCgoPCgcEBwMAAgAFEgSQ
AgQKCg8KBwQHAwACAAESBJACCxcKDwoHBAcDAAIAAxIEkAIaGwo7CgYEBwMAAgESBJMCBBwa
KyBIdW1hbiByZWFkYWJsZSBuYW1lIG9mIHRoZSBvdXRwdXQgY29sdW1uLgoKDwoHBAcDAAIB
BRIEkwIECgoPCgcEBwMAAgEBEgSTAgsXCg8KBwQHAwACAQMSBJMCGhsKUwoEBAcEABIGlwIC
zAIDGkMgRW51bWVyYXRpb24gb2YgdmlzdWFsemF0aW9uIHR5cGVzIHRvIHVzZSBmb3IgcXVl
cnkgcmVzcG9uc2UgZGF0YS4KCg0KBQQHBAABEgSXAgcYCjYKBgQHBAACABIEmQIEJxomIE5v
IHZpc3VhbGl6YXRpb24gdHlwZSB3YXMgc3BlY2lmaWVkLgoKDwoHBAcEAAIAARIEmQIEIgoP
CgcEBwQAAgACEgSZAiUmCh8KBgQHBAACARIEnAIEDhoPIFNob3cgYSB0YWJsZS4KCg8KBwQH
BAACAQESBJwCBAkKDwoHBAcEAAIBAhIEnAIMDQptCgYEBwQAAgISBKACBBIaXSBTaG93IGEg
W2JhcgogY2hhcnRdKGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2NoYXJ0L2ludGVy
YWN0aXZlL2RvY3MvZ2FsbGVyeS9iYXJjaGFydCkuCgoPCgcEBwQAAgIBEgSgAgQNCg8KBwQH
BAACAgISBKACEBEKcwoGBAcEAAIDEgSkAgQVGmMgU2hvdyBhIFtjb2x1bW4KIGNoYXJ0XSho
dHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9jaGFydC9pbnRlcmFjdGl2ZS9kb2NzL2dh
bGxlcnkvY29sdW1uY2hhcnQpLgoKDwoHBAcEAAIDARIEpAIEEAoPCgcEBwQAAgMCEgSkAhMU
CmwKBgQHBAACBBIEqAIEERpcIFNob3cgYQogW3RpbWVsaW5lXShodHRwczovL2RldmVsb3Bl
cnMuZ29vZ2xlLmNvbS9jaGFydC9pbnRlcmFjdGl2ZS9kb2NzL2dhbGxlcnkvdGltZWxpbmUp
LgoKDwoHBAcEAAIEARIEqAIEDAoPCgcEBwQAAgQCEgSoAg8QCnQKBgQHBAACBRIErAIEFRpk
IFNob3cgYSBbc2NhdHRlcgogcGxvdF0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20v
Y2hhcnQvaW50ZXJhY3RpdmUvZG9jcy9nYWxsZXJ5L3NjYXR0ZXJjaGFydCkuCgoPCgcEBwQA
AgUBEgSsAgQQCg8KBwQHBAACBQISBKwCExQKbQoGBAcEAAIGEgSwAgQSGl0gU2hvdyBhIFtw
aWUKIGNoYXJ0XShodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9jaGFydC9pbnRlcmFj
dGl2ZS9kb2NzL2dhbGxlcnkvcGllY2hhcnQpLgoKDwoHBAcEAAIGARIEsAIEDQoPCgcEBwQA
AgYCEgSwAhARCm8KBgQHBAACBxIEtAIEExpfIFNob3cgYSBbbGluZQogY2hhcnRdKGh0dHBz
Oi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2NoYXJ0L2ludGVyYWN0aXZlL2RvY3MvZ2FsbGVy
eS9saW5lY2hhcnQpLgoKDwoHBAcEAAIHARIEtAIEDgoPCgcEBwQAAgcCEgS0AhESCnAKBgQH
BAACCBIEuAIEExpgIFNob3cgYW4gW2FyZWEKIGNoYXJ0XShodHRwczovL2RldmVsb3BlcnMu
Z29vZ2xlLmNvbS9jaGFydC9pbnRlcmFjdGl2ZS9kb2NzL2dhbGxlcnkvYXJlYWNoYXJ0KS4K
Cg8KBwQHBAACCAESBLgCBA4KDwoHBAcEAAIIAhIEuAIREgpxCgYEBwQAAgkSBLwCBBQaYSBT
aG93IGEgW2NvbWJvCiBjaGFydF0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vY2hh
cnQvaW50ZXJhY3RpdmUvZG9jcy9nYWxsZXJ5L2NvbWJvY2hhcnQpLgoKDwoHBAcEAAIJARIE
vAIEDwoPCgcEBwQAAgkCEgS8AhITCm4KBgQHBAACChIEwAIEExpeIFNob3cgYQogW2hpc3Rv
Z3JhbV0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vY2hhcnQvaW50ZXJhY3RpdmUv
ZG9jcy9nYWxsZXJ5L2hpc3RvZ3JhbSkuCgoPCgcEBwQAAgoBEgTAAgQNCg8KBwQHBAACCgIS
BMACEBIKmQIKBgQHBAACCxIExgIEFxqIAiBUaGlzIGRlbm90ZXMgcXVlcmllcyB3aGVuIHRo
ZSB1c2VyIGhhcyBub3Qgc3BlY2lmaWVkIHRoZSBwYXJ0aWN1bGFyIHR5cGUKIG9mIGNoYXJ0
IGFuZCBoYXMgbWVudGlvbmVkIG9ubHkgYSBnZW5lcmljIGNoYXJ0IG5hbWUgc3VjaCBhcyAi
Q2hhcnQiLAogIlBsb3QiLCAiR3JhcGgiLCBldGMuIFRoaXMgd2lsbCBkaWZmZXJlbnRpYXRl
IGl0IGZyb20gc3BlY2lmaWMgY2hhcnRpbmcKIHRlcm1zIHN1Y2ggYXMgIkJhciBjaGFydCIs
ICJQaWUgY2hhcnQiLCBldGMuCgoPCgcEBwQAAgsBEgTGAgQRCg8KBwQHBAACCwISBMYCFBYK
5QEKBgQHBAACDBIEywIEHhrUASBUaGUgdXNlciB0cmllZCB0byBzcGVjaWZ5IGEgY2hhcnQg
dHlwZSwgYnV0IHRoZSBpbnRlcnByZXRlciBjb3VsZCBub3QKIHVuZGVyc3RhbmQgdGhlIHR5
cGUuIFRoZSBjbGllbnQgc2hvdWxkIGRpc3BsYXkgYSBnZW5lcmljIGNoYXJ0IGFuZCBtYXkK
IGdpdmUgYSBoaW50IHRvIHRoZSB1c2VyIHRoYXQgdGhlIHJlcXVlc3RlZCB0eXBlIHdhcyBu
b3QgdW5kZXJzdG9vZC4KCg8KBwQHBAACDAESBMsCBBgKDwoHBAcEAAIMAhIEywIbHQpzCgQE
BwIAEgTQAgI1GmUgTGlzdCBvZiBwb3NzaWJsZSB2aXN1YWxpemF0aW9uIHR5cGVzIHRvIGFw
cGx5IGZvciB0aGlzIGludGVycHJldGF0aW9uLiBUaGUKIG9yZGVyIGhhcyBubyByZWxldmFu
Y2UuCgoNCgUEBwIABBIE0AICCgoNCgUEBwIABhIE0AILHAoNCgUEBwIAARIE0AIdMAoNCgUE
BwIAAxIE0AIzNApxCgQEBwIBEgTUAgImGmMgSW5mb3JtYXRpb24gYWJvdXQgdGhlIG91dHB1
dCBjb2x1bW5zLCB0aGF0IGlzLCB0aGUgY29sdW1ucyB0aGF0IHdpbGwgYmUKIHJldHVybmVk
IGJ5IHRoZSBiYWNrZW5kLgoKDQoFBAcCAQQSBNQCAgoKDQoFBAcCAQYSBNQCCxUKDQoFBAcC
AQESBNQCFiEKDQoFBAcCAQMSBNQCJCUKLgoCBAgSBtgCAIQDARogIENvbmZpZ3VyaWF0aW9u
IG9mIGRlYnVnIGZsYWdzLgoKCwoDBAgBEgTYAggSCjgKBAQIAgASBNoCAhwaKiBXaGV0aGVy
IHRvIGluY2x1ZGUgdGhlIG9yaWdpbmFsIFZBUXVlcnkuCgoNCgUECAIABRIE2gICBgoNCgUE
CAIAARIE2gIHFwoNCgUECAIAAxIE2gIaGwo/CgQECAIBEgTdAgIjGjEgV2hldGhlciB0byBp
bmNsdWRlIHRoZSBvcmlnaW5hbCBuZXN0ZWQgVkFRdWVyeS4KCg0KBQQIAgEFEgTdAgIGCg0K
BQQIAgEBEgTdAgceCg0KBQQIAgEDEgTdAiEiCmMKBAQIAgISBOECAigaVSBXaGV0aGVyIHRv
IGluY2x1ZGUgdGhlIG9yaWdpbmFsIGh1bWFuIGludGVycHJldGF0aW9uIHN0cmluZ3MgZ2Vu
ZXJhdGVkCiBieSBBbmFseXphLgoKDQoFBAgCAgUSBOECAgYKDQoFBAgCAgESBOECByMKDQoF
BAgCAgMSBOECJicKOwoEBAgCAxIE5AICJxotIFdoZXRoZXIgdG8gaW5jbHVkZSB0aGUgQXF1
YSBkZWJ1ZyByZXNwb25zZS4KCg0KBQQIAgMFEgTkAgIGCg0KBQQIAgMBEgTkAgciCg0KBQQI
AgMDEgTkAiUmCuABCgQECAIEEgTrAgIaGtEBIFRoZSB0aW1lIGluIG1pbGxpc2Vjb25kcyBm
cm9tIFVuaXggZXBvY2ggdG8gYmUgdXNlZAogdG8gcHJvY2VzcyB0aGUgcXVlcnkuIFRoaXMg
aXMgdXNlZnVsIGZvciB0ZXN0aW5nCiB0aGUgcXVlcmllcyBhdCBkaWZmZXJlbnQgdGltZSBw
ZXJpb2QuCiBJZiBub3Qgc2V0IG9yIHRpbWVfb3ZlcnJpZGUgPD0gMCwgdGhlbiB0aGUgY3Vy
cmVudAogdGltZSBpcyB1c2VkLgoKDQoFBAgCBAUSBOsCAgcKDQoFBAgCBAESBOsCCBUKDQoF
BAgCBAMSBOsCGBkKTwoEBAgCBRIE7gICIxpBIFNldCB0byB0cnVlIGlmIHJlcXVlc3QgaXMg
aW5pdGlhdGVkIGJ5IGFuIGludGVybmFsIEdvb2dsZSB1c2VyLgoKDQoFBAgCBQUSBO4CAgYK
DQoFBAgCBQESBO4CBx4KDQoFBAgCBQMSBO4CISIKcgoEBAgCBhIE8gICGBpkIERldGVybWlu
ZXMgd2hldGhlciBjYWNoZSBuZWVkcyB0byBiZSBpZ25vcmVkLiBJZiBzZXQgdG8KIHRydWUs
IGNhY2hlIHdvbid0IGJlIHF1ZXJpZWQgYW5kIHVwZGF0ZWQuCgoNCgUECAIGBRIE8gICBgoN
CgUECAIGARIE8gIHEwoNCgUECAIGAxIE8gIWFwpyCgQECAIHEgT2AgInGmQgV2hldGhlciB0
byBpbmNsdWRlIHRoZSByZXF1ZXN0L3Jlc3BvbnNlIHBhaXIgZnJvbSB0aGUgY2FsbCB0byB0
aGUKIEVudGl0eUluZGV4IGZvciBTZWFyY2hFbnRpdGllcy4KCg0KBQQIAgcFEgT2AgIGCg0K
BQQIAgcBEgT2AgciCg0KBQQIAgcDEgT2AiUmCoEBCgQECAIIEgT6AgIvGnMgV2hldGhlciB0
byBpbmNsdWRlIHRoZSByZXF1ZXN0L3Jlc3BvbnNlIHBhaXIgZnJvbSB0aGUgY2FsbCB0byB0
aGUKIEFubm90YXRpb25zIHNlcnZpY2UgZm9yIExpc3RDb2x1bW5Bbm5vdGF0aW9ucy4KCg0K
BQQIAggFEgT6AgIGCg0KBQQIAggBEgT6AgcqCg0KBQQIAggDEgT6Ai0uCkUKBAQIAgkSBP0C
Ai0aNyBXaGV0aGVyIHRvIGluY2x1ZGUgdGhlIGVudGl0eSBsaXN0IHBhc3NlZCB0byBBbmFs
eXphLgoKDQoFBAgCCQUSBP0CAgYKDQoFBAgCCQESBP0CBycKDQoFBAgCCQMSBP0CKiwKMgoE
BAgCChIEgAMCHxokIFdoZXRoZXIgdG8gaW5jbHVkZSB0aGUgdGFibGUgbGlzdC4KCg0KBQQI
AgoFEgSAAwIGCg0KBQQIAgoBEgSAAwcZCg0KBQQIAgoDEgSAAxweCjMKBAQIAgsSBIMDAiAa
JSBXaGV0aGVyIHRvIGluY2x1ZGUgdGhlIGRvbWFpbiBsaXN0LgoKDQoFBAgCCwUSBIMDAgYK
DQoFBAgCCwESBIMDBxoKDQoFBAgCCwMSBIMDHR8KNAoCBQASBocDAJADARomIFF1ZXJ5IGVu
dGl0aWVzIG9mIGFuIGludGVycHJldGF0aW9uLgoKCwoDBQABEgSHAwUUCjIKBAUAAgASBIkD
AiMaJCBObyBpbnRlcnByZXQgZW50aXR5IHdhcyBzcGVjaWZpZWQuCgoNCgUFAAIAARIEiQMC
HgoNCgUFAAIAAhIEiQMhIgokCgQFAAIBEgSMAwIQGhYgQSBkaW1lbnN0aW9uIGVudGl0eS4K
Cg0KBQUAAgEBEgSMAwILCg0KBQUAAgECEgSMAw4PCiAKBAUAAgISBI8DAg0aEiBBIG1ldHJp
YyBlbnRpdHkuCgoNCgUFAAICARIEjwMCCAoNCgUFAAICAhIEjwMLDGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataqna::V1alpha::Question::Question ===
    # Fields for Question
    # Field: name Type: 9 ()
    # Field: scopes Type: 9 ()
    # Field: query Type: 9 ()
    # Field: data_source_annotations Type: 9 ()
    # Field: interpret_error Type: 11 (.google.cloud.dataqna.v1alpha.InterpretError)
    # Field: interpretations Type: 11 (.google.cloud.dataqna.v1alpha.Interpretation)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: user_email Type: 9 ()
    # Field: debug_flags Type: 11 (.google.cloud.dataqna.v1alpha.DebugFlags)
    # Field: debug_info Type: 11 (.google.protobuf.Any)

# === Message: Google::Cloud::Dataqna::V1alpha::Question::InterpretError ===
    # Fields for InterpretError
    # Field: message Type: 9 ()
    # Field: code Type: 14 (.google.cloud.dataqna.v1alpha.InterpretError.InterpretErrorCode)
    # Field: details Type: 11 (.google.cloud.dataqna.v1alpha.InterpretError.InterpretErrorDetails)

# Enum: InterpretError::InterpretErrorCode
our $InterpretError_INTERPRET_ERROR_CODE_UNSPECIFIED = 0;
our $InterpretError_INVALID_QUERY = 1;
our $InterpretError_FAILED_TO_UNDERSTAND = 2;
our $InterpretError_FAILED_TO_ANSWER = 3;

# === Message: Google::Cloud::Dataqna::V1alpha::Question::ExecutionInfo ===
    # Fields for ExecutionInfo
    # Field: job_creation_status Type: 11 (.google.rpc.Status)
    # Field: job_execution_state Type: 14 (.google.cloud.dataqna.v1alpha.ExecutionInfo.JobExecutionState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: bigquery_job Type: 11 (.google.cloud.dataqna.v1alpha.BigQueryJob)

# Enum: ExecutionInfo::JobExecutionState
our $ExecutionInfo_JOB_EXECUTION_STATE_UNSPECIFIED = 0;
our $ExecutionInfo_NOT_EXECUTED = 1;
our $ExecutionInfo_RUNNING = 2;
our $ExecutionInfo_SUCCEEDED = 3;
our $ExecutionInfo_FAILED = 4;

# === Message: Google::Cloud::Dataqna::V1alpha::Question::BigQueryJob ===
    # Fields for BigQueryJob
    # Field: job_id Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Dataqna::V1alpha::Question::Interpretation ===
    # Fields for Interpretation
    # Field: data_sources Type: 9 ()
    # Field: confidence Type: 1 ()
    # Field: unused_phrases Type: 9 ()
    # Field: human_readable Type: 11 (.google.cloud.dataqna.v1alpha.HumanReadable)
    # Field: interpretation_structure Type: 11 (.google.cloud.dataqna.v1alpha.InterpretationStructure)
    # Field: data_query Type: 11 (.google.cloud.dataqna.v1alpha.DataQuery)
    # Field: execution_info Type: 11 (.google.cloud.dataqna.v1alpha.ExecutionInfo)

# === Message: Google::Cloud::Dataqna::V1alpha::Question::DataQuery ===
    # Fields for DataQuery
    # Field: sql Type: 9 ()

# === Message: Google::Cloud::Dataqna::V1alpha::Question::HumanReadable ===
    # Fields for HumanReadable
    # Field: generated_interpretation Type: 11 (.google.cloud.dataqna.v1alpha.AnnotatedString)
    # Field: original_question Type: 11 (.google.cloud.dataqna.v1alpha.AnnotatedString)

# === Message: Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure ===
    # Fields for InterpretationStructure
    # Field: visualization_types Type: 14 (.google.cloud.dataqna.v1alpha.InterpretationStructure.VisualizationType)
    # Field: column_info Type: 11 (.google.cloud.dataqna.v1alpha.InterpretationStructure.ColumnInfo)

# Enum: InterpretationStructure::VisualizationType
our $InterpretationStructure_VISUALIZATION_TYPE_UNSPECIFIED = 0;
our $InterpretationStructure_TABLE = 1;
our $InterpretationStructure_BAR_CHART = 2;
our $InterpretationStructure_COLUMN_CHART = 3;
our $InterpretationStructure_TIMELINE = 4;
our $InterpretationStructure_SCATTER_PLOT = 5;
our $InterpretationStructure_PIE_CHART = 6;
our $InterpretationStructure_LINE_CHART = 7;
our $InterpretationStructure_AREA_CHART = 8;
our $InterpretationStructure_COMBO_CHART = 9;
our $InterpretationStructure_HISTOGRAM = 10;
our $InterpretationStructure_GENERIC_CHART = 11;
our $InterpretationStructure_CHART_NOT_UNDERSTOOD = 12;

# === Message: Google::Cloud::Dataqna::V1alpha::Question::DebugFlags ===
    # Fields for DebugFlags
    # Field: include_va_query Type: 8 ()
    # Field: include_nested_va_query Type: 8 ()
    # Field: include_human_interpretation Type: 8 ()
    # Field: include_aqua_debug_response Type: 8 ()
    # Field: time_override Type: 3 ()
    # Field: is_internal_google_user Type: 8 ()
    # Field: ignore_cache Type: 8 ()
    # Field: include_search_entities_rpc Type: 8 ()
    # Field: include_list_column_annotations_rpc Type: 8 ()
    # Field: include_virtual_analyst_entities Type: 8 ()
    # Field: include_table_list Type: 8 ()
    # Field: include_domain_list Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataqna::V1alpha::Question - Compiled Protocol Buffers messages for google/cloud/dataqna/v1alpha/question.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataqna::V1alpha::Question;

    my $msg = Google::Cloud::Dataqna::V1alpha::Question::Question->new({
        name => $name,
        scopes => $scopes,
        query => $query,
        data_source_annotations => $data_source_annotations,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataqna::V1alpha::Question::Question->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataqna/v1alpha/question.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataqna::V1alpha::Question::Question

The question resource represents a natural language query, its settings,
understanding generated by the system, and answer retrieval status.
A question cannot be modified.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Immutable. The unique identifier for the Question. The ID is server-generated.
Example: `projects/foo/locations/bar/questions/123`

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Required. Immutable. Scopes to be used for the question. A scope defines the relevant data set
scope. It can be a reference to a specific data source or a collection of
data sources. Currently, support is limited to a single BigQuery table.
There must be exactly one `scopes` element.

Example:
`//bigquery.googleapis.com/projects/test-project/datasets/foo/tables/bar`

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. Immutable. The query in natural language.

=item * C<< $msg->data_source_annotations() >> / C<< $msg->data_source_annotations($value) >>

Type: C<String>

A list of annotations to use instead of the default annotation of a data
source (set in the data source reference resource). There must not be
more than one annotation with the same data source reference.

=item * C<< $msg->interpret_error() >> / C<< $msg->interpret_error($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::InterpretError>)

An error field explaining why interpretation failed. This is only populated
if the interpretation failed.

Note: This is different from getting a status error on the request itself.
This is not a client or server error and the Question resource is still
persisted, but the service could not interpret the question. Clients should
present the error to the user so the user can rephrase the question.

=item * C<< $msg->interpretations() >> / C<< $msg->interpretations($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::Interpretation>)

A list of interpretations for this question.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the question was created.

=item * C<< $msg->user_email() >> / C<< $msg->user_email($value) >>

Type: C<String>

Output only. The e-mail address of the user that created this question.

=item * C<< $msg->debug_flags() >> / C<< $msg->debug_flags($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::DebugFlags>)

Input only. Immutable. Flags to request additional information for debugging purposes.

=item * C<< $msg->debug_info() >> / C<< $msg->debug_info($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Top level debug information.
This will be stored as the type DebugInformation.
Using Any so clients don't need to pull in anything
inside the debug message.

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::InterpretError

Details on the failure to interpret the question.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Error message explaining why this question could not be interpreted.

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Dataqna::V1alpha::InterpretError::InterpretErrorCode>)

The code for the error category why the interpretation failed.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretErrorDetails>)

Details on interpretation failure.

=back

=head3 Enum: InterpretError::InterpretErrorCode

=over 4

=item * C<INTERPRET_ERROR_CODE_UNSPECIFIED> => C<0>

=item * C<INVALID_QUERY> => C<1>

=item * C<FAILED_TO_UNDERSTAND> => C<2>

=item * C<FAILED_TO_ANSWER> => C<3>

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::ExecutionInfo

Information about the backend status (such as BigQuery) of the execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_creation_status() >> / C<< $msg->job_creation_status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Status returned by the backend when the job was created.

=item * C<< $msg->job_execution_state() >> / C<< $msg->job_execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dataqna::V1alpha::ExecutionInfo::JobExecutionState>)

Status of the job execution.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the execution was triggered.

=item * C<< $msg->bigquery_job() >> / C<< $msg->bigquery_job($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::BigQueryJob>)

BigQuery job information.
Future versions will have different backends. Hence, clients must make sure
they can handle it when this field is not populated.

=back

=head3 Enum: ExecutionInfo::JobExecutionState

=over 4

=item * C<JOB_EXECUTION_STATE_UNSPECIFIED> => C<0>

=item * C<NOT_EXECUTED> => C<1>

=item * C<RUNNING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::BigQueryJob

BigQuery job information. This can be used to query the BigQuery API and
retrieve the current job's status (using
[jobs.get](https://cloud.google.com/bigquery/docs/reference/rest/v2/jobs/get)).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

The job ID.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID of the job.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The location where the job is running.

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::Interpretation

An interpretation of a natural language query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_sources() >> / C<< $msg->data_sources($value) >>

Type: C<String>

List of data sources used in the current understanding.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Double>

The level of confidence that one of the interpretations is correct. This is
a value in the range [0, 1] where a value of 0.5 or below is to be
considered a low confidence.

=item * C<< $msg->unused_phrases() >> / C<< $msg->unused_phrases($value) >>

Type: C<String>

A list of unused phrases. Clients should display a Did You Mean (DYM)
 dialog if this is non-empty, even if this is the only interpretation.

=item * C<< $msg->human_readable() >> / C<< $msg->human_readable($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::HumanReadable>)

Human readable representation of the query.

=item * C<< $msg->interpretation_structure() >> / C<< $msg->interpretation_structure($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure>)

Information about the interpretation structure that helps to understand and
visualize the response.

=item * C<< $msg->data_query() >> / C<< $msg->data_query($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::DataQuery>)

Representation of the data query to be sent to the backend.

=item * C<< $msg->execution_info() >> / C<< $msg->execution_info($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::ExecutionInfo>)

Information about the backend response. This is populated only if execution
of an interpretation was requested.

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::DataQuery

Representation of the data query for the backend.
This is provided for informational purposes only. Clients should not use
it to send it to the backend directly, but rather use the `execute` RPC
to trigger the execution. Using the `execute` RPC is needed in order to
track the state of a question and report on it correctly to the data
administrators.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sql() >> / C<< $msg->sql($value) >>

Type: C<String>

The generated SQL query to be sent to the backend.

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::HumanReadable

Human readable interpretation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generated_interpretation() >> / C<< $msg->generated_interpretation($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString>)

Generated query explaining the interpretation.

=item * C<< $msg->original_question() >> / C<< $msg->original_question($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString>)

Annotations on the original query.

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure

Information about the interpretation structure that helps to understand and
visualize the response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->visualization_types() >> / C<< $msg->visualization_types($value) >>

Type: C<Enum> (L<Google::Cloud::Dataqna::V1alpha::InterpretationStructure::VisualizationType>)

List of possible visualization types to apply for this interpretation. The
order has no relevance.

=item * C<< $msg->column_info() >> / C<< $msg->column_info($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure::ColumnInfo>)

Information about the output columns, that is, the columns that will be
returned by the backend.

=back

=head3 Enum: InterpretationStructure::VisualizationType

=over 4

=item * C<VISUALIZATION_TYPE_UNSPECIFIED> => C<0>

=item * C<TABLE> => C<1>

=item * C<BAR_CHART> => C<2>

=item * C<COLUMN_CHART> => C<3>

=item * C<TIMELINE> => C<4>

=item * C<SCATTER_PLOT> => C<5>

=item * C<PIE_CHART> => C<6>

=item * C<LINE_CHART> => C<7>

=item * C<AREA_CHART> => C<8>

=item * C<COMBO_CHART> => C<9>

=item * C<HISTOGRAM> => C<10>

=item * C<GENERIC_CHART> => C<11>

=item * C<CHART_NOT_UNDERSTOOD> => C<12>

=back

=head2 Google::Cloud::Dataqna::V1alpha::Question::DebugFlags

Configuriation of debug flags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->include_va_query() >> / C<< $msg->include_va_query($value) >>

Type: C<Bool>

Whether to include the original VAQuery.

=item * C<< $msg->include_nested_va_query() >> / C<< $msg->include_nested_va_query($value) >>

Type: C<Bool>

Whether to include the original nested VAQuery.

=item * C<< $msg->include_human_interpretation() >> / C<< $msg->include_human_interpretation($value) >>

Type: C<Bool>

Whether to include the original human interpretation strings generated
by Analyza.

=item * C<< $msg->include_aqua_debug_response() >> / C<< $msg->include_aqua_debug_response($value) >>

Type: C<Bool>

Whether to include the Aqua debug response.

=item * C<< $msg->time_override() >> / C<< $msg->time_override($value) >>

Type: C<Int64>

The time in milliseconds from Unix epoch to be used
to process the query. This is useful for testing
the queries at different time period.
If not set or time_override <= 0, then the current
time is used.

=item * C<< $msg->is_internal_google_user() >> / C<< $msg->is_internal_google_user($value) >>

Type: C<Bool>

Set to true if request is initiated by an internal Google user.

=item * C<< $msg->ignore_cache() >> / C<< $msg->ignore_cache($value) >>

Type: C<Bool>

Determines whether cache needs to be ignored. If set to
true, cache won't be queried and updated.

=item * C<< $msg->include_search_entities_rpc() >> / C<< $msg->include_search_entities_rpc($value) >>

Type: C<Bool>

Whether to include the request/response pair from the call to the
EntityIndex for SearchEntities.

=item * C<< $msg->include_list_column_annotations_rpc() >> / C<< $msg->include_list_column_annotations_rpc($value) >>

Type: C<Bool>

Whether to include the request/response pair from the call to the
Annotations service for ListColumnAnnotations.

=item * C<< $msg->include_virtual_analyst_entities() >> / C<< $msg->include_virtual_analyst_entities($value) >>

Type: C<Bool>

Whether to include the entity list passed to Analyza.

=item * C<< $msg->include_table_list() >> / C<< $msg->include_table_list($value) >>

Type: C<Bool>

Whether to include the table list.

=item * C<< $msg->include_domain_list() >> / C<< $msg->include_domain_list($value) >>

Type: C<Bool>

Whether to include the domain list.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataqna::V1alpha::Question::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
