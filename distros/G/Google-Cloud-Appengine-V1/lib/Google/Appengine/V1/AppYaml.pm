package Google::Appengine::V1::AppYaml;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvYXBwZW5naW5lL3YxL2FwcF95YW1sLnByb3RvEhNnb29nbGUuYXBwZW5naW5l
LnYxGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8ikwIKEEFwaUNvbmZpZ0hhbmRs
ZXISTQoQYXV0aF9mYWlsX2FjdGlvbhgBIAEoDjIjLmdvb2dsZS5hcHBlbmdpbmUudjEuQXV0
aEZhaWxBY3Rpb25SDmF1dGhGYWlsQWN0aW9uEjsKBWxvZ2luGAIgASgOMiUuZ29vZ2xlLmFw
cGVuZ2luZS52MS5Mb2dpblJlcXVpcmVtZW50UgVsb2dpbhIWCgZzY3JpcHQYAyABKAlSBnNj
cmlwdBJJCg5zZWN1cml0eV9sZXZlbBgEIAEoDjIiLmdvb2dsZS5hcHBlbmdpbmUudjEuU2Vj
dXJpdHlMZXZlbFINc2VjdXJpdHlMZXZlbBIQCgN1cmwYBSABKAlSA3VybCKwAgoMRXJyb3JI
YW5kbGVyEkoKCmVycm9yX2NvZGUYASABKA4yKy5nb29nbGUuYXBwZW5naW5lLnYxLkVycm9y
SGFuZGxlci5FcnJvckNvZGVSCWVycm9yQ29kZRIfCgtzdGF0aWNfZmlsZRgCIAEoCVIKc3Rh
dGljRmlsZRIbCgltaW1lX3R5cGUYAyABKAlSCG1pbWVUeXBlIpUBCglFcnJvckNvZGUSGgoW
RVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEhYKEkVSUk9SX0NPREVfREVGQVVMVBAAEhkKFUVS
Uk9SX0NPREVfT1ZFUl9RVU9UQRABEh0KGUVSUk9SX0NPREVfRE9TX0FQSV9ERU5JQUwQAhIW
ChJFUlJPUl9DT0RFX1RJTUVPVVQQAxoCEAEiuQYKBlVybE1hcBIbCgl1cmxfcmVnZXgYASAB
KAlSCHVybFJlZ2V4EkwKDHN0YXRpY19maWxlcxgCIAEoCzInLmdvb2dsZS5hcHBlbmdpbmUu
djEuU3RhdGljRmlsZXNIYW5kbGVySABSC3N0YXRpY0ZpbGVzEjwKBnNjcmlwdBgDIAEoCzIi
Lmdvb2dsZS5hcHBlbmdpbmUudjEuU2NyaXB0SGFuZGxlckgAUgZzY3JpcHQSTAoMYXBpX2Vu
ZHBvaW50GAQgASgLMicuZ29vZ2xlLmFwcGVuZ2luZS52MS5BcGlFbmRwb2ludEhhbmRsZXJI
AFILYXBpRW5kcG9pbnQSSQoOc2VjdXJpdHlfbGV2ZWwYBSABKA4yIi5nb29nbGUuYXBwZW5n
aW5lLnYxLlNlY3VyaXR5TGV2ZWxSDXNlY3VyaXR5TGV2ZWwSOwoFbG9naW4YBiABKA4yJS5n
b29nbGUuYXBwZW5naW5lLnYxLkxvZ2luUmVxdWlyZW1lbnRSBWxvZ2luEk0KEGF1dGhfZmFp
bF9hY3Rpb24YByABKA4yIy5nb29nbGUuYXBwZW5naW5lLnYxLkF1dGhGYWlsQWN0aW9uUg5h
dXRoRmFpbEFjdGlvbhJzChtyZWRpcmVjdF9odHRwX3Jlc3BvbnNlX2NvZGUYCCABKA4yNC5n
b29nbGUuYXBwZW5naW5lLnYxLlVybE1hcC5SZWRpcmVjdEh0dHBSZXNwb25zZUNvZGVSGHJl
ZGlyZWN0SHR0cFJlc3BvbnNlQ29kZSLbAQoYUmVkaXJlY3RIdHRwUmVzcG9uc2VDb2RlEisK
J1JFRElSRUNUX0hUVFBfUkVTUE9OU0VfQ09ERV9VTlNQRUNJRklFRBAAEiMKH1JFRElSRUNU
X0hUVFBfUkVTUE9OU0VfQ09ERV8zMDEQARIjCh9SRURJUkVDVF9IVFRQX1JFU1BPTlNFX0NP
REVfMzAyEAISIwofUkVESVJFQ1RfSFRUUF9SRVNQT05TRV9DT0RFXzMwMxADEiMKH1JFRElS
RUNUX0hUVFBfUkVTUE9OU0VfQ09ERV8zMDcQBEIOCgxoYW5kbGVyX3R5cGUisAMKElN0YXRp
Y0ZpbGVzSGFuZGxlchISCgRwYXRoGAEgASgJUgRwYXRoEioKEXVwbG9hZF9wYXRoX3JlZ2V4
GAIgASgJUg91cGxvYWRQYXRoUmVnZXgSWwoMaHR0cF9oZWFkZXJzGAMgAygLMjguZ29vZ2xl
LmFwcGVuZ2luZS52MS5TdGF0aWNGaWxlc0hhbmRsZXIuSHR0cEhlYWRlcnNFbnRyeVILaHR0
cEhlYWRlcnMSGwoJbWltZV90eXBlGAQgASgJUghtaW1lVHlwZRI5CgpleHBpcmF0aW9uGAUg
ASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgpleHBpcmF0aW9uEjIKFXJlcXVpcmVf
bWF0Y2hpbmdfZmlsZRgGIAEoCFITcmVxdWlyZU1hdGNoaW5nRmlsZRIxChRhcHBsaWNhdGlv
bl9yZWFkYWJsZRgHIAEoCFITYXBwbGljYXRpb25SZWFkYWJsZRo+ChBIdHRwSGVhZGVyc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiMAoNU2Ny
aXB0SGFuZGxlchIfCgtzY3JpcHRfcGF0aBgBIAEoCVIKc2NyaXB0UGF0aCI1ChJBcGlFbmRw
b2ludEhhbmRsZXISHwoLc2NyaXB0X3BhdGgYASABKAlSCnNjcmlwdFBhdGgi1QIKC0hlYWx0
aENoZWNrEjAKFGRpc2FibGVfaGVhbHRoX2NoZWNrGAEgASgIUhJkaXNhYmxlSGVhbHRoQ2hl
Y2sSEgoEaG9zdBgCIAEoCVIEaG9zdBIrChFoZWFsdGh5X3RocmVzaG9sZBgDIAEoDVIQaGVh
bHRoeVRocmVzaG9sZBIvChN1bmhlYWx0aHlfdGhyZXNob2xkGAQgASgNUhJ1bmhlYWx0aHlU
aHJlc2hvbGQSKwoRcmVzdGFydF90aHJlc2hvbGQYBSABKA1SEHJlc3RhcnRUaHJlc2hvbGQS
QAoOY2hlY2tfaW50ZXJ2YWwYBiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SDWNo
ZWNrSW50ZXJ2YWwSMwoHdGltZW91dBgHIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
blIHdGltZW91dCLQAgoOUmVhZGluZXNzQ2hlY2sSEgoEcGF0aBgBIAEoCVIEcGF0aBISCgRo
b3N0GAIgASgJUgRob3N0EisKEWZhaWx1cmVfdGhyZXNob2xkGAMgASgNUhBmYWlsdXJlVGhy
ZXNob2xkEisKEXN1Y2Nlc3NfdGhyZXNob2xkGAQgASgNUhBzdWNjZXNzVGhyZXNob2xkEkAK
DmNoZWNrX2ludGVydmFsGAUgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg1jaGVj
a0ludGVydmFsEjMKB3RpbWVvdXQYBiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25S
B3RpbWVvdXQSRQoRYXBwX3N0YXJ0X3RpbWVvdXQYByABKAsyGS5nb29nbGUucHJvdG9idWYu
RHVyYXRpb25SD2FwcFN0YXJ0VGltZW91dCLIAgoNTGl2ZW5lc3NDaGVjaxISCgRwYXRoGAEg
ASgJUgRwYXRoEhIKBGhvc3QYAiABKAlSBGhvc3QSKwoRZmFpbHVyZV90aHJlc2hvbGQYAyAB
KA1SEGZhaWx1cmVUaHJlc2hvbGQSKwoRc3VjY2Vzc190aHJlc2hvbGQYBCABKA1SEHN1Y2Nl
c3NUaHJlc2hvbGQSQAoOY2hlY2tfaW50ZXJ2YWwYBSABKAsyGS5nb29nbGUucHJvdG9idWYu
RHVyYXRpb25SDWNoZWNrSW50ZXJ2YWwSMwoHdGltZW91dBgGIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvblIHdGltZW91dBI+Cg1pbml0aWFsX2RlbGF5GAcgASgLMhkuZ29vZ2xl
LnByb3RvYnVmLkR1cmF0aW9uUgxpbml0aWFsRGVsYXkiNwoHTGlicmFyeRISCgRuYW1lGAEg
ASgJUgRuYW1lEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24qdAoOQXV0aEZhaWxBY3Rpb24S
IAocQVVUSF9GQUlMX0FDVElPTl9VTlNQRUNJRklFRBAAEh0KGUFVVEhfRkFJTF9BQ1RJT05f
UkVESVJFQ1QQARIhCh1BVVRIX0ZBSUxfQUNUSU9OX1VOQVVUSE9SSVpFRBACKmIKEExvZ2lu
UmVxdWlyZW1lbnQSFQoRTE9HSU5fVU5TUEVDSUZJRUQQABISCg5MT0dJTl9PUFRJT05BTBAB
Eg8KC0xPR0lOX0FETUlOEAISEgoOTE9HSU5fUkVRVUlSRUQQAyp5Cg1TZWN1cml0eUxldmVs
EhYKElNFQ1VSRV9VTlNQRUNJRklFRBAAEhIKDlNFQ1VSRV9ERUZBVUxUEAASEAoMU0VDVVJF
X05FVkVSEAESEwoPU0VDVVJFX09QVElPTkFMEAISEQoNU0VDVVJFX0FMV0FZUxADGgIQAUK9
AQoXY29tLmdvb2dsZS5hcHBlbmdpbmUudjFCDEFwcFlhbWxQcm90b1ABWjtjbG91ZC5nb29n
bGUuY29tL2dvL2FwcGVuZ2luZS9hcGl2MS9hcHBlbmdpbmVwYjthcHBlbmdpbmVwYqoCGUdv
b2dsZS5DbG91ZC5BcHBFbmdpbmUuVjHKAhlHb29nbGVcQ2xvdWRcQXBwRW5naW5lXFYx6gIc
R29vZ2xlOjpDbG91ZDo6QXBwRW5naW5lOjpWMUqMYQoHEgUOANsCAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAoCggKAQgSAxQANgoJ
CgIIJRIDFAA2CggKAQgSAxUAUgoJCgIICxIDFQBSCggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcALQoJCgIICBIDFwAtCggKAQgSAxgAMAoJCgIIARIDGAAwCggKAQgSAxkANgoJCgII
KRIDGQA2CggKAQgSAxoANQoJCgIILRIDGgA1CoIBCgIEABIEHgAvARp2IFtHb29nbGUgQ2xv
dWQgRW5kcG9pbnRzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3Mv
cHl0aG9uL2VuZHBvaW50cy8pCiBjb25maWd1cmF0aW9uIGZvciBBUEkgaGFuZGxlcnMuCgoK
CgMEAAESAx4IGApvCgQEAAIAEgMhAiYaYiBBY3Rpb24gdG8gdGFrZSB3aGVuIHVzZXJzIGFj
Y2VzcyByZXNvdXJjZXMgdGhhdCByZXF1aXJlCiBhdXRoZW50aWNhdGlvbi4gRGVmYXVsdHMg
dG8gYHJlZGlyZWN0YC4KCgwKBQQAAgAGEgMhAhAKDAoFBAACAAESAyERIQoMCgUEAAIAAxID
ISQlClgKBAQAAgESAyUCHRpLIExldmVsIG9mIGxvZ2luIHJlcXVpcmVkIHRvIGFjY2VzcyB0
aGlzIHJlc291cmNlLiBEZWZhdWx0cyB0bwogYG9wdGlvbmFsYC4KCgwKBQQAAgEGEgMlAhIK
DAoFBAACAQESAyUTGAoMCgUEAAIBAxIDJRscCkYKBAQAAgISAygCFBo5IFBhdGggdG8gdGhl
IHNjcmlwdCBmcm9tIHRoZSBhcHBsaWNhdGlvbiByb290IGRpcmVjdG9yeS4KCgwKBQQAAgIF
EgMoAggKDAoFBAACAgESAygJDwoMCgUEAAICAxIDKBITCjkKBAQAAgMSAysCIxosIFNlY3Vy
aXR5IChIVFRQUykgZW5mb3JjZW1lbnQgZm9yIHRoaXMgVVJMLgoKDAoFBAACAwYSAysCDwoM
CgUEAAIDARIDKxAeCgwKBQQAAgMDEgMrISIKLAoEBAACBBIDLgIRGh8gVVJMIHRvIHNlcnZl
IHRoZSBlbmRwb2ludCBhdC4KCgwKBQQAAgQFEgMuAggKDAoFBAACBAESAy4JDAoMCgUEAAIE
AxIDLg8QCkkKAgQBEgQyAFABGj0gQ3VzdG9tIHN0YXRpYyBlcnJvciBwYWdlIHRvIGJlIHNl
cnZlZCB3aGVuIGFuIGVycm9yIG9jY3Vycy4KCgoKAwQBARIDMggUChwKBAQBBAASBDQCRgMa
DiBFcnJvciBjb2Rlcy4KCgwKBQQBBAABEgM0BxAKDAoFBAEEAAMSAzUEHgoNCgYEAQQAAwIS
AzUEHgo+CgYEAQQAAgASAzgEHxovIE5vdCBzcGVjaWZpZWQuIEVSUk9SX0NPREVfREVGQVVM
VCBpcyBhc3N1bWVkLgoKDgoHBAEEAAIAARIDOAQaCg4KBwQBBAACAAISAzgdHgonCgYEAQQA
AgESAzsEGxoYIEFsbCBvdGhlciBlcnJvciB0eXBlcy4KCg4KBwQBBAACAQESAzsEFgoOCgcE
AQQAAgECEgM7GRoKOwoGBAEEAAICEgM+BB4aLCBBcHBsaWNhdGlvbiBoYXMgZXhjZWVkZWQg
YSByZXNvdXJjZSBxdW90YS4KCg4KBwQBBAACAgESAz4EGQoOCgcEAQQAAgICEgM+HB0KYQoG
BAEEAAIDEgNCBCIaUiBDbGllbnQgYmxvY2tlZCBieSB0aGUgYXBwbGljYXRpb24ncyBEZW5p
YWwgb2YgU2VydmljZSBwcm90ZWN0aW9uCiBjb25maWd1cmF0aW9uLgoKDgoHBAEEAAIDARID
QgQdCg4KBwQBBAACAwISA0IgIQpCCgYEAQQAAgQSA0UEGxozIERlYWRsaW5lIHJlYWNoZWQg
YmVmb3JlIHRoZSBhcHBsaWNhdGlvbiByZXNwb25kcy4KCg4KBwQBBAACBAESA0UEFgoOCgcE
AQQAAgQCEgNFGRoKNwoEBAECABIDSQIbGiogRXJyb3IgY29uZGl0aW9uIHRoaXMgaGFuZGxl
ciBhcHBsaWVzIHRvLgoKDAoFBAECAAYSA0kCCwoMCgUEAQIAARIDSQwWCgwKBQQBAgADEgNJ
GRoKPwoEBAECARIDTAIZGjIgU3RhdGljIGZpbGUgY29udGVudCB0byBiZSBzZXJ2ZWQgZm9y
IHRoaXMgZXJyb3IuCgoMCgUEAQIBBRIDTAIICgwKBQQBAgEBEgNMCRQKDAoFBAECAQMSA0wX
GAo6CgQEAQICEgNPAhcaLSBNSU1FIHR5cGUgb2YgZmlsZS4gRGVmYXVsdHMgdG8gYHRleHQv
aHRtbGAuCgoMCgUEAQICBRIDTwIICgwKBQQBAgIBEgNPCRIKDAoFBAECAgMSA08VFgriAQoC
BAISBVUAigEBGtQBIFVSTCBwYXR0ZXJuIGFuZCBkZXNjcmlwdGlvbiBvZiBob3cgdGhlIFVS
TCBzaG91bGQgYmUgaGFuZGxlZC4gQXBwIEVuZ2luZSBjYW4KIGhhbmRsZSBVUkxzIGJ5IGV4
ZWN1dGluZyBhcHBsaWNhdGlvbiBjb2RlIG9yIGJ5IHNlcnZpbmcgc3RhdGljIGZpbGVzCiB1
cGxvYWRlZCB3aXRoIHRoZSB2ZXJzaW9uLCBzdWNoIGFzIGltYWdlcywgQ1NTLCBvciBKYXZh
U2NyaXB0LgoKCgoDBAIBEgNVCA4KHwoEBAIEABIEVwJmAxoRIFJlZGlyZWN0IGNvZGVzLgoK
DAoFBAIEAAESA1cHHwoxCgYEAgQAAgASA1kEMBoiIE5vdCBzcGVjaWZpZWQuIGAzMDJgIGlz
IGFzc3VtZWQuCgoOCgcEAgQAAgABEgNZBCsKDgoHBAIEAAIAAhIDWS4vCi4KBgQCBAACARID
XAQoGh8gYDMwMSBNb3ZlZCBQZXJtYW5lbnRseWAgY29kZS4KCg4KBwQCBAACAQESA1wEIwoO
CgcEAgQAAgECEgNcJicKLgoGBAIEAAICEgNfBCgaHyBgMzAyIE1vdmVkIFRlbXBvcmFyaWx5
YCBjb2RlLgoKDgoHBAIEAAICARIDXwQjCg4KBwQCBAACAgISA18mJwomCgYEAgQAAgMSA2IE
KBoXIGAzMDMgU2VlIE90aGVyYCBjb2RlLgoKDgoHBAIEAAIDARIDYgQjCg4KBwQCBAACAwIS
A2ImJwovCgYEAgQAAgQSA2UEKBogIGAzMDcgVGVtcG9yYXJ5IFJlZGlyZWN0YCBjb2RlLgoK
DgoHBAIEAAIEARIDZQQjCg4KBwQCBAACBAISA2UmJwqhAgoEBAICABIDbAIXGpMCIFVSTCBw
cmVmaXguIFVzZXMgcmVndWxhciBleHByZXNzaW9uIHN5bnRheCwgd2hpY2ggbWVhbnMgcmVn
ZXhwCiBzcGVjaWFsIGNoYXJhY3RlcnMgbXVzdCBiZSBlc2NhcGVkLCBidXQgc2hvdWxkIG5v
dCBjb250YWluIGdyb3VwaW5ncy4KIEFsbCBVUkxzIHRoYXQgYmVnaW4gd2l0aCB0aGlzIHBy
ZWZpeCBhcmUgaGFuZGxlZCBieSB0aGlzIGhhbmRsZXIsIHVzaW5nIHRoZQogcG9ydGlvbiBv
ZiB0aGUgVVJMIGFmdGVyIHRoZSBwcmVmaXggYXMgcGFydCBvZiB0aGUgZmlsZSBwYXRoLgoK
DAoFBAICAAUSA2wCCAoMCgUEAgIAARIDbAkSCgwKBQQCAgADEgNsFRYKNQoEBAIIABIEbwJ6
AxonIFR5cGUgb2YgaGFuZGxlciBmb3IgdGhpcyBVUkwgcGF0dGVybi4KCgwKBQQCCAABEgNv
CBQKUQoEBAICARIDcQQoGkQgUmV0dXJucyB0aGUgY29udGVudHMgb2YgYSBmaWxlLCBzdWNo
IGFzIGFuIGltYWdlLCBhcyB0aGUgcmVzcG9uc2UuCgoMCgUEAgIBBhIDcQQWCgwKBQQCAgEB
EgNxFyMKDAoFBAICAQMSA3EmJwrOAQoEBAICAhIDdgQdGsABIEV4ZWN1dGVzIGEgc2NyaXB0
IHRvIGhhbmRsZSB0aGUgcmVxdWVzdHMgdGhhdCBtYXRjaCB0aGlzIFVSTAogcGF0dGVybi4g
T25seSB0aGUgYGF1dG9gIHZhbHVlIGlzIHN1cHBvcnRlZCBmb3IgTm9kZS5qcyBpbiB0aGUK
IEFwcCBFbmdpbmUgc3RhbmRhcmQgZW52aXJvbm1lbnQsIGZvciBleGFtcGxlIGAic2NyaXB0
IjogImF1dG8iYC4KCgwKBQQCAgIGEgN2BBEKDAoFBAICAgESA3YSGAoMCgUEAgICAxIDdhsc
CjUKBAQCAgMSA3kEKBooIFVzZXMgQVBJIEVuZHBvaW50cyB0byBoYW5kbGUgcmVxdWVzdHMu
CgoMCgUEAgIDBhIDeQQWCgwKBQQCAgMBEgN5FyMKDAoFBAICAwMSA3kmJwo5CgQEAgIEEgN9
AiMaLCBTZWN1cml0eSAoSFRUUFMpIGVuZm9yY2VtZW50IGZvciB0aGlzIFVSTC4KCgwKBQQC
AgQGEgN9Ag8KDAoFBAICBAESA30QHgoMCgUEAgIEAxIDfSEiCoMBCgQEAgIFEgSBAQIdGnUg
TGV2ZWwgb2YgbG9naW4gcmVxdWlyZWQgdG8gYWNjZXNzIHRoaXMgcmVzb3VyY2UuIE5vdCBz
dXBwb3J0ZWQgZm9yIE5vZGUuanMKIGluIHRoZSBBcHAgRW5naW5lIHN0YW5kYXJkIGVudmly
b25tZW50LgoKDQoFBAICBQYSBIEBAhIKDQoFBAICBQESBIEBExgKDQoFBAICBQMSBIEBGxwK
cAoEBAICBhIEhQECJhpiIEFjdGlvbiB0byB0YWtlIHdoZW4gdXNlcnMgYWNjZXNzIHJlc291
cmNlcyB0aGF0IHJlcXVpcmUKIGF1dGhlbnRpY2F0aW9uLiBEZWZhdWx0cyB0byBgcmVkaXJl
Y3RgLgoKDQoFBAICBgYSBIUBAhAKDQoFBAICBgESBIUBESEKDQoFBAICBgMSBIUBJCUKZwoE
BAICBxIEiQECOxpZIGAzMHhgIGNvZGUgdG8gdXNlIHdoZW4gcGVyZm9ybWluZyByZWRpcmVj
dHMgZm9yIHRoZSBgc2VjdXJlYCBmaWVsZC4KIERlZmF1bHRzIHRvIGAzMDJgLgoKDQoFBAIC
BwYSBIkBAhoKDQoFBAICBwESBIkBGzYKDQoFBAICBwMSBIkBOToK9wEKAgQDEgaQAQCxAQEa
6AEgRmlsZXMgc2VydmVkIGRpcmVjdGx5IHRvIHRoZSB1c2VyIGZvciBhIGdpdmVuIFVSTCwg
c3VjaCBhcyBpbWFnZXMsIENTUwogc3R5bGVzaGVldHMsIG9yIEphdmFTY3JpcHQgc291cmNl
IGZpbGVzLiBTdGF0aWMgZmlsZSBoYW5kbGVycyBkZXNjcmliZSB3aGljaAogZmlsZXMgaW4g
dGhlIGFwcGxpY2F0aW9uIGRpcmVjdG9yeSBhcmUgc3RhdGljIGZpbGVzLCBhbmQgd2hpY2gg
VVJMcyBzZXJ2ZQogdGhlbS4KCgsKAwQDARIEkAEIGgqwAQoEBAMCABIElAECEhqhASBQYXRo
IHRvIHRoZSBzdGF0aWMgZmlsZXMgbWF0Y2hlZCBieSB0aGUgVVJMIHBhdHRlcm4sIGZyb20g
dGhlCiBhcHBsaWNhdGlvbiByb290IGRpcmVjdG9yeS4gVGhlIHBhdGggY2FuIHJlZmVyIHRv
IHRleHQgbWF0Y2hlZCBpbiBncm91cGluZ3MKIGluIHRoZSBVUkwgcGF0dGVybi4KCg0KBQQD
AgAFEgSUAQIICg0KBQQDAgABEgSUAQkNCg0KBQQDAgADEgSUARARCngKBAQDAgESBJgBAh8a
aiBSZWd1bGFyIGV4cHJlc3Npb24gdGhhdCBtYXRjaGVzIHRoZSBmaWxlIHBhdGhzIGZvciBh
bGwgZmlsZXMgdGhhdCBzaG91bGQgYmUKIHJlZmVyZW5jZWQgYnkgdGhpcyBoYW5kbGVyLgoK
DQoFBAMCAQUSBJgBAggKDQoFBAMCAQESBJgBCRoKDQoFBAMCAQMSBJgBHR4KRgoEBAMCAhIE
mwECJxo4IEhUVFAgaGVhZGVycyB0byB1c2UgZm9yIGFsbCByZXNwb25zZXMgZnJvbSB0aGVz
ZSBVUkxzLgoKDQoFBAMCAgYSBJsBAhUKDQoFBAMCAgESBJsBFiIKDQoFBAMCAgMSBJsBJSYK
qgEKBAQDAgMSBKEBAhcamwEgTUlNRSB0eXBlIHVzZWQgdG8gc2VydmUgYWxsIGZpbGVzIHNl
cnZlZCBieSB0aGlzIGhhbmRsZXIuCgogRGVmYXVsdHMgdG8gZmlsZS1zcGVjaWZpYyBNSU1F
IHR5cGVzLCB3aGljaCBhcmUgZGVyaXZlZCBmcm9tIGVhY2ggZmlsZSdzCiBmaWxlbmFtZSBl
eHRlbnNpb24uCgoNCgUEAwIDBRIEoQECCAoNCgUEAwIDARIEoQEJEgoNCgUEAwIDAxIEoQEV
FgpoCgQEAwIEEgSlAQIqGlogVGltZSBhIHN0YXRpYyBmaWxlIHNlcnZlZCBieSB0aGlzIGhh
bmRsZXIgc2hvdWxkIGJlIGNhY2hlZAogYnkgd2ViIHByb3hpZXMgYW5kIGJyb3dzZXJzLgoK
DQoFBAMCBAYSBKUBAhoKDQoFBAMCBAESBKUBGyUKDQoFBAMCBAMSBKUBKCkKdAoEBAMCBRIE
qQECIRpmIFdoZXRoZXIgdGhpcyBoYW5kbGVyIHNob3VsZCBtYXRjaCB0aGUgcmVxdWVzdCBp
ZiB0aGUgZmlsZQogcmVmZXJlbmNlZCBieSB0aGUgaGFuZGxlciBkb2VzIG5vdCBleGlzdC4K
Cg0KBQQDAgUFEgSpAQIGCg0KBQQDAgUBEgSpAQccCg0KBQQDAgUDEgSpAR8gCsECCgQEAwIG
EgSwAQIgGrICIFdoZXRoZXIgZmlsZXMgc2hvdWxkIGFsc28gYmUgdXBsb2FkZWQgYXMgY29k
ZSBkYXRhLiBCeSBkZWZhdWx0LCBmaWxlcwogZGVjbGFyZWQgaW4gc3RhdGljIGZpbGUgaGFu
ZGxlcnMgYXJlIHVwbG9hZGVkIGFzIHN0YXRpYwogZGF0YSBhbmQgYXJlIG9ubHkgc2VydmVk
IHRvIGVuZCB1c2VyczsgdGhleSBjYW5ub3QgYmUgcmVhZCBieSB0aGUKIGFwcGxpY2F0aW9u
LiBJZiBlbmFibGVkLCB1cGxvYWRzIGFyZSBjaGFyZ2VkIGFnYWluc3QgYm90aCB5b3VyIGNv
ZGUgYW5kCiBzdGF0aWMgZGF0YSBzdG9yYWdlIHJlc291cmNlIHF1b3Rhcy4KCg0KBQQDAgYF
EgSwAQIGCg0KBQQDAgYBEgSwAQcbCg0KBQQDAgYDEgSwAR4fClUKAgQEEga0AQC3AQEaRyBF
eGVjdXRlcyBhIHNjcmlwdCB0byBoYW5kbGUgdGhlIHJlcXVlc3QgdGhhdCBtYXRjaGVzIHRo
ZSBVUkwgcGF0dGVybi4KCgsKAwQEARIEtAEIFQpHCgQEBAIAEgS2AQIZGjkgUGF0aCB0byB0
aGUgc2NyaXB0IGZyb20gdGhlIGFwcGxpY2F0aW9uIHJvb3QgZGlyZWN0b3J5LgoKDQoFBAQC
AAUSBLYBAggKDQoFBAQCAAESBLYBCRQKDQoFBAQCAAMSBLYBFxgKPwoCBAUSBroBAL0BARox
IFVzZXMgR29vZ2xlIENsb3VkIEVuZHBvaW50cyB0byBoYW5kbGUgcmVxdWVzdHMuCgoLCgME
BQESBLoBCBoKRwoEBAUCABIEvAECGRo5IFBhdGggdG8gdGhlIHNjcmlwdCBmcm9tIHRoZSBh
cHBsaWNhdGlvbiByb290IGRpcmVjdG9yeS4KCg0KBQQFAgAFEgS8AQIICg0KBQQFAgABEgS8
AQkUCg0KBQQFAgADEgS8ARcYCsQBCgIEBhIGwgEA2wEBGrUBIEhlYWx0aCBjaGVja2luZyBj
b25maWd1cmF0aW9uIGZvciBWTSBpbnN0YW5jZXMuIFVuaGVhbHRoeSBpbnN0YW5jZXMKIGFy
ZSBraWxsZWQgYW5kIHJlcGxhY2VkIHdpdGggbmV3IGluc3RhbmNlcy4gT25seSBhcHBsaWNh
YmxlIGZvcgogaW5zdGFuY2VzIGluIEFwcCBFbmdpbmUgZmxleGlibGUgZW52aXJvbm1lbnQu
CgoLCgMEBgESBMIBCBMKTgoEBAYCABIExAECIBpAIFdoZXRoZXIgdG8gZXhwbGljaXRseSBk
aXNhYmxlIGhlYWx0aCBjaGVja3MgZm9yIHRoaXMgaW5zdGFuY2UuCgoNCgUEBgIABRIExAEC
BgoNCgUEBgIAARIExAEHGwoNCgUEBgIAAxIExAEeHwpnCgQEBgIBEgTIAQISGlkgSG9zdCBo
ZWFkZXIgdG8gc2VuZCB3aGVuIHBlcmZvcm1pbmcgYW4gSFRUUCBoZWFsdGggY2hlY2suCiBF
eGFtcGxlOiAibXlhcHAuYXBwc3BvdC5jb20iCgoNCgUEBgIBBRIEyAECCAoNCgUEBgIBARIE
yAEJDQoNCgUEBgIBAxIEyAEQEQpiCgQEBgICEgTMAQIfGlQgTnVtYmVyIG9mIGNvbnNlY3V0
aXZlIHN1Y2Nlc3NmdWwgaGVhbHRoIGNoZWNrcyByZXF1aXJlZCBiZWZvcmUgcmVjZWl2aW5n
CiB0cmFmZmljLgoKDQoFBAYCAgUSBMwBAggKDQoFBAYCAgESBMwBCRoKDQoFBAYCAgMSBMwB
HR4KXQoEBAYCAxIE0AECIRpPIE51bWJlciBvZiBjb25zZWN1dGl2ZSBmYWlsZWQgaGVhbHRo
IGNoZWNrcyByZXF1aXJlZCBiZWZvcmUgcmVtb3ZpbmcKIHRyYWZmaWMuCgoNCgUEBgIDBRIE
0AECCAoNCgUEBgIDARIE0AEJHAoNCgUEBgIDAxIE0AEfIAplCgQEBgIEEgTUAQIfGlcgTnVt
YmVyIG9mIGNvbnNlY3V0aXZlIGZhaWxlZCBoZWFsdGggY2hlY2tzIHJlcXVpcmVkIGJlZm9y
ZSBhbiBpbnN0YW5jZSBpcwogcmVzdGFydGVkLgoKDQoFBAYCBAUSBNQBAggKDQoFBAYCBAES
BNQBCRoKDQoFBAYCBAMSBNQBHR4KLwoEBAYCBRIE1wECLhohIEludGVydmFsIGJldHdlZW4g
aGVhbHRoIGNoZWNrcy4KCg0KBQQGAgUGEgTXAQIaCg0KBQQGAgUBEgTXARspCg0KBQQGAgUD
EgTXASwtCkIKBAQGAgYSBNoBAicaNCBUaW1lIGJlZm9yZSB0aGUgaGVhbHRoIGNoZWNrIGlz
IGNvbnNpZGVyZWQgZmFpbGVkLgoKDQoFBAYCBgYSBNoBAhoKDQoFBAYCBgESBNoBGyIKDQoF
BAYCBgMSBNoBJSYKegoCBAcSBt8BAPkBARpsIFJlYWRpbmVzcyBjaGVja2luZyBjb25maWd1
cmF0aW9uIGZvciBWTSBpbnN0YW5jZXMuIFVuaGVhbHRoeSBpbnN0YW5jZXMKIGFyZSByZW1v
dmVkIGZyb20gdHJhZmZpYyByb3RhdGlvbi4KCgsKAwQHARIE3wEIFgohCgQEBwIAEgThAQIS
GhMgVGhlIHJlcXVlc3QgcGF0aC4KCg0KBQQHAgAFEgThAQIICg0KBQQHAgABEgThAQkNCg0K
BQQHAgADEgThARARCmkKBAQHAgESBOUBAhIaWyBIb3N0IGhlYWRlciB0byBzZW5kIHdoZW4g
cGVyZm9ybWluZyBhIEhUVFAgUmVhZGluZXNzIGNoZWNrLgogRXhhbXBsZTogIm15YXBwLmFw
cHNwb3QuY29tIgoKDQoFBAcCAQUSBOUBAggKDQoFBAcCAQESBOUBCQ0KDQoFBAcCAQMSBOUB
EBEKVgoEBAcCAhIE6QECHxpIIE51bWJlciBvZiBjb25zZWN1dGl2ZSBmYWlsZWQgY2hlY2tz
IHJlcXVpcmVkIGJlZm9yZSByZW1vdmluZwogdHJhZmZpYy4KCg0KBQQHAgIFEgTpAQIICg0K
BQQHAgIBEgTpAQkaCg0KBQQHAgIDEgTpAR0eClsKBAQHAgMSBO0BAh8aTSBOdW1iZXIgb2Yg
Y29uc2VjdXRpdmUgc3VjY2Vzc2Z1bCBjaGVja3MgcmVxdWlyZWQgYmVmb3JlIHJlY2Vpdmlu
ZwogdHJhZmZpYy4KCg0KBQQHAgMFEgTtAQIICg0KBQQHAgMBEgTtAQkaCg0KBQQHAgMDEgTt
AR0eCi8KBAQHAgQSBPABAi4aISBJbnRlcnZhbCBiZXR3ZWVuIGhlYWx0aCBjaGVja3MuCgoN
CgUEBwIEBhIE8AECGgoNCgUEBwIEARIE8AEbKQoNCgUEBwIEAxIE8AEsLQo7CgQEBwIFEgTz
AQInGi0gVGltZSBiZWZvcmUgdGhlIGNoZWNrIGlzIGNvbnNpZGVyZWQgZmFpbGVkLgoKDQoF
BAcCBQYSBPMBAhoKDQoFBAcCBQESBPMBGyIKDQoFBAcCBQMSBPMBJSYKtQEKBAQHAgYSBPgB
AjEapgEgQSBtYXhpbXVtIHRpbWUgbGltaXQgb24gYXBwbGljYXRpb24gaW5pdGlhbGl6YXRp
b24sIG1lYXN1cmVkIGZyb20gbW9tZW50CiB0aGUgYXBwbGljYXRpb24gc3VjY2Vzc2Z1bGx5
IHJlcGxpZXMgdG8gYSBoZWFsdGhjaGVjayB1bnRpbCBpdCBpcyByZWFkeSB0bwogc2VydmUg
dHJhZmZpYy4KCg0KBQQHAgYGEgT4AQIaCg0KBQQHAgYBEgT4ARssCg0KBQQHAgYDEgT4AS8w
CoABCgIECBIG/QEAlQIBGnIgSGVhbHRoIGNoZWNraW5nIGNvbmZpZ3VyYXRpb24gZm9yIFZN
IGluc3RhbmNlcy4gVW5oZWFsdGh5IGluc3RhbmNlcwogYXJlIGtpbGxlZCBhbmQgcmVwbGFj
ZWQgd2l0aCBuZXcgaW5zdGFuY2VzLgoKCwoDBAgBEgT9AQgVCiEKBAQIAgASBP8BAhIaEyBU
aGUgcmVxdWVzdCBwYXRoLgoKDQoFBAgCAAUSBP8BAggKDQoFBAgCAAESBP8BCQ0KDQoFBAgC
AAMSBP8BEBEKaAoEBAgCARIEgwICEhpaIEhvc3QgaGVhZGVyIHRvIHNlbmQgd2hlbiBwZXJm
b3JtaW5nIGEgSFRUUCBMaXZlbmVzcyBjaGVjay4KIEV4YW1wbGU6ICJteWFwcC5hcHBzcG90
LmNvbSIKCg0KBQQIAgEFEgSDAgIICg0KBQQIAgEBEgSDAgkNCg0KBQQIAgEDEgSDAhARCmIK
BAQIAgISBIcCAh8aVCBOdW1iZXIgb2YgY29uc2VjdXRpdmUgZmFpbGVkIGNoZWNrcyByZXF1
aXJlZCBiZWZvcmUgY29uc2lkZXJpbmcgdGhlCiBWTSB1bmhlYWx0aHkuCgoNCgUECAICBRIE
hwICCAoNCgUECAICARIEhwIJGgoNCgUECAICAxIEhwIdHgpkCgQECAIDEgSLAgIfGlYgTnVt
YmVyIG9mIGNvbnNlY3V0aXZlIHN1Y2Nlc3NmdWwgY2hlY2tzIHJlcXVpcmVkIGJlZm9yZSBj
b25zaWRlcmluZwogdGhlIFZNIGhlYWx0aHkuCgoNCgUECAIDBRIEiwICCAoNCgUECAIDARIE
iwIJGgoNCgUECAIDAxIEiwIdHgovCgQECAIEEgSOAgIuGiEgSW50ZXJ2YWwgYmV0d2VlbiBo
ZWFsdGggY2hlY2tzLgoKDQoFBAgCBAYSBI4CAhoKDQoFBAgCBAESBI4CGykKDQoFBAgCBAMS
BI4CLC0KOwoEBAgCBRIEkQICJxotIFRpbWUgYmVmb3JlIHRoZSBjaGVjayBpcyBjb25zaWRl
cmVkIGZhaWxlZC4KCg0KBQQIAgUGEgSRAgIaCg0KBQQIAgUBEgSRAhsiCg0KBQQIAgUDEgSR
AiUmCkgKBAQIAgYSBJQCAi0aOiBUaGUgaW5pdGlhbCBkZWxheSBiZWZvcmUgc3RhcnRpbmcg
dG8gZXhlY3V0ZSB0aGUgY2hlY2tzLgoKDQoFBAgCBgYSBJQCAhoKDQoFBAgCBgESBJQCGygK
DQoFBAgCBgMSBJQCKywKVwoCBAkSBpgCAJ4CARpJIFRoaXJkLXBhcnR5IFB5dGhvbiBydW50
aW1lIGxpYnJhcnkgdGhhdCBpcyByZXF1aXJlZCBieSB0aGUgYXBwbGljYXRpb24uCgoLCgME
CQESBJgCCA8KNwoEBAkCABIEmgICEhopIE5hbWUgb2YgdGhlIGxpYnJhcnkuIEV4YW1wbGU6
ICJkamFuZ28iLgoKDQoFBAkCAAUSBJoCAggKDQoFBAkCAAESBJoCCQ0KDQoFBAkCAAMSBJoC
EBEKPgoEBAkCARIEnQICFRowIFZlcnNpb24gb2YgdGhlIGxpYnJhcnkgdG8gc2VsZWN0LCBv
ciAibGF0ZXN0Ii4KCg0KBQQJAgEFEgSdAgIICg0KBQQJAgEBEgSdAgkQCg0KBQQJAgEDEgSd
AhMUCj8KAgUAEgahAgCsAgEaMSBBY3Rpb25zIHRvIHRha2Ugd2hlbiB0aGUgdXNlciBpcyBu
b3QgbG9nZ2VkIGluLgoKCwoDBQABEgShAgUTCkYKBAUAAgASBKMCAiMaOCBOb3Qgc3BlY2lm
aWVkLiBgQVVUSF9GQUlMX0FDVElPTl9SRURJUkVDVGAgaXMgYXNzdW1lZC4KCg0KBQUAAgAB
EgSjAgIeCg0KBQUAAgACEgSjAiEiCpYBCgQFAAIBEgSnAgIgGocBIFJlZGlyZWN0cyB1c2Vy
IHRvICJhY2NvdW50cy5nb29nbGUuY29tIi4gVGhlIHVzZXIgaXMgcmVkaXJlY3RlZCBiYWNr
IHRvIHRoZQogYXBwbGljYXRpb24gVVJMIGFmdGVyIHNpZ25pbmcgaW4gb3IgY3JlYXRpbmcg
YW4gYWNjb3VudC4KCg0KBQUAAgEBEgSnAgIbCg0KBQUAAgECEgSnAh4fClQKBAUAAgISBKsC
AiQaRiBSZWplY3RzIHJlcXVlc3Qgd2l0aCBhIGA0MDFgIEhUVFAgc3RhdHVzIGNvZGUgYW5k
IGFuIGVycm9yCiBtZXNzYWdlLgoKDQoFBQACAgESBKsCAh8KDQoFBQACAgISBKsCIiMKSgoC
BQESBq8CAMACARo8IE1ldGhvZHMgdG8gcmVzdHJpY3QgYWNjZXNzIHRvIGEgVVJMIGJhc2Vk
IG9uIGxvZ2luIHN0YXR1cy4KCgsKAwUBARIErwIFFQo7CgQFAQIAEgSxAgIYGi0gTm90IHNw
ZWNpZmllZC4gYExPR0lOX09QVElPTkFMYCBpcyBhc3N1bWVkLgoKDQoFBQECAAESBLECAhMK
DQoFBQECAAISBLECFhcKPAoEBQECARIEtAICFRouIERvZXMgbm90IHJlcXVpcmUgdGhhdCB0
aGUgdXNlciBpcyBzaWduZWQgaW4uCgoNCgUFAQIBARIEtAICEAoNCgUFAQIBAhIEtAITFAqS
AgoEBQECAhIEuwICEhqDAiBJZiB0aGUgdXNlciBpcyBub3Qgc2lnbmVkIGluLCB0aGUgYGF1
dGhfZmFpbF9hY3Rpb25gIGlzIHRha2VuLgogSW4gYWRkaXRpb24sIGlmIHRoZSB1c2VyIGlz
IG5vdCBhbiBhZG1pbmlzdHJhdG9yIGZvciB0aGUKIGFwcGxpY2F0aW9uLCB0aGV5IGFyZSBn
aXZlbiBhbiBlcnJvciBtZXNzYWdlIHJlZ2FyZGxlc3Mgb2YKIGBhdXRoX2ZhaWxfYWN0aW9u
YC4gSWYgdGhlIHVzZXIgaXMgYW4gYWRtaW5pc3RyYXRvciwgdGhlIGhhbmRsZXIKIHByb2Nl
ZWRzLgoKDQoFBQECAgESBLsCAg0KDQoFBQECAgISBLsCEBEKdAoEBQECAxIEvwICFRpmIElm
IHRoZSB1c2VyIGhhcyBzaWduZWQgaW4sIHRoZSBoYW5kbGVyIHByb2NlZWRzIG5vcm1hbGx5
LiBPdGhlcndpc2UsIHRoZQogYXV0aF9mYWlsX2FjdGlvbiBpcyB0YWtlbi4KCg0KBQUBAgMB
EgS/AgIQCg0KBQUBAgMCEgS/AhMUCj0KAgUCEgbDAgDbAgEaLyBNZXRob2RzIHRvIGVuZm9y
Y2Ugc2VjdXJpdHkgKEhUVFBTKSBvbiBhIFVSTC4KCgsKAwUCARIEwwIFEgoLCgMFAgMSBMQC
AhwKDAoEBQIDAhIExAICHAoeCgQFAgIAEgTHAgIZGhAgTm90IHNwZWNpZmllZC4KCg0KBQUC
AgABEgTHAgIUCg0KBQUCAgACEgTHAhcYCtIBCgQFAgIBEgTMAgIVGsMBIEJvdGggSFRUUCBh
bmQgSFRUUFMgcmVxdWVzdHMgd2l0aCBVUkxzIHRoYXQgbWF0Y2ggdGhlIGhhbmRsZXIgc3Vj
Y2VlZAogd2l0aG91dCByZWRpcmVjdHMuIFRoZSBhcHBsaWNhdGlvbiBjYW4gZXhhbWluZSB0
aGUgcmVxdWVzdCB0byBkZXRlcm1pbmUKIHdoaWNoIHByb3RvY29sIHdhcyB1c2VkLCBhbmQg
cmVzcG9uZCBhY2NvcmRpbmdseS4KCg0KBQUCAgEBEgTMAgIQCg0KBQUCAgECEgTMAhMUCoMB
CgQFAgICEgTQAgITGnUgUmVxdWVzdHMgZm9yIGEgVVJMIHRoYXQgbWF0Y2ggdGhpcyBoYW5k
bGVyIHRoYXQgdXNlIEhUVFBTIGFyZSBhdXRvbWF0aWNhbGx5CiByZWRpcmVjdGVkIHRvIHRo
ZSBIVFRQIGVxdWl2YWxlbnQgVVJMLgoKDQoFBQICAgESBNACAg4KDQoFBQICAgISBNACERIK
0QEKBAUCAgMSBNUCAhYawgEgQm90aCBIVFRQIGFuZCBIVFRQUyByZXF1ZXN0cyB3aXRoIFVS
THMgdGhhdCBtYXRjaCB0aGUgaGFuZGxlciBzdWNjZWVkCiB3aXRob3V0IHJlZGlyZWN0cy4g
VGhlIGFwcGxpY2F0aW9uIGNhbiBleGFtaW5lIHRoZSByZXF1ZXN0IHRvIGRldGVybWluZQog
d2hpY2ggcHJvdG9jb2wgd2FzIHVzZWQgYW5kIHJlc3BvbmQgYWNjb3JkaW5nbHkuCgoNCgUF
AgIDARIE1QICEQoNCgUFAgIDAhIE1QIUFQrFAQoEBQICBBIE2gICFBq2ASBSZXF1ZXN0cyBm
b3IgYSBVUkwgdGhhdCBtYXRjaCB0aGlzIGhhbmRsZXIgdGhhdCBkbyBub3QgdXNlIEhUVFBT
IGFyZQogYXV0b21hdGljYWxseSByZWRpcmVjdGVkIHRvIHRoZSBIVFRQUyBVUkwgd2l0aCB0
aGUgc2FtZSBwYXRoLiBRdWVyeQogcGFyYW1ldGVycyBhcmUgcmVzZXJ2ZWQgZm9yIHRoZSBy
ZWRpcmVjdC4KCg0KBQUCAgQBEgTaAgIPCg0KBQUCAgQCEgTaAhITYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::AppYaml::ApiConfigHandler ===
    # Fields for ApiConfigHandler
    # Field: auth_fail_action Type: 14 (.google.appengine.v1.AuthFailAction)
    # Field: login Type: 14 (.google.appengine.v1.LoginRequirement)
    # Field: script Type: 9 ()
    # Field: security_level Type: 14 (.google.appengine.v1.SecurityLevel)
    # Field: url Type: 9 ()

# === Message: Google::Appengine::V1::AppYaml::ErrorHandler ===
    # Fields for ErrorHandler
    # Field: error_code Type: 14 (.google.appengine.v1.ErrorHandler.ErrorCode)
    # Field: static_file Type: 9 ()
    # Field: mime_type Type: 9 ()

# Enum: ErrorHandler::ErrorCode
our $ErrorHandler_ERROR_CODE_UNSPECIFIED = 0;
our $ErrorHandler_ERROR_CODE_DEFAULT = 0;
our $ErrorHandler_ERROR_CODE_OVER_QUOTA = 1;
our $ErrorHandler_ERROR_CODE_DOS_API_DENIAL = 2;
our $ErrorHandler_ERROR_CODE_TIMEOUT = 3;

# === Message: Google::Appengine::V1::AppYaml::UrlMap ===
    # Fields for UrlMap
    # Field: url_regex Type: 9 ()
    # Field: static_files Type: 11 (.google.appengine.v1.StaticFilesHandler)
    # Field: script Type: 11 (.google.appengine.v1.ScriptHandler)
    # Field: api_endpoint Type: 11 (.google.appengine.v1.ApiEndpointHandler)
    # Field: security_level Type: 14 (.google.appengine.v1.SecurityLevel)
    # Field: login Type: 14 (.google.appengine.v1.LoginRequirement)
    # Field: auth_fail_action Type: 14 (.google.appengine.v1.AuthFailAction)
    # Field: redirect_http_response_code Type: 14 (.google.appengine.v1.UrlMap.RedirectHttpResponseCode)

# Enum: UrlMap::RedirectHttpResponseCode
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED = 0;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_301 = 1;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_302 = 2;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_303 = 3;
our $UrlMap_REDIRECT_HTTP_RESPONSE_CODE_307 = 4;

# === Message: Google::Appengine::V1::AppYaml::StaticFilesHandler ===
    # Fields for StaticFilesHandler
    # Field: path Type: 9 ()
    # Field: upload_path_regex Type: 9 ()
    # Field: http_headers Type: 11 (.google.appengine.v1.StaticFilesHandler.HttpHeadersEntry)
    # Field: mime_type Type: 9 ()
    # Field: expiration Type: 11 (.google.protobuf.Duration)
    # Field: require_matching_file Type: 8 ()
    # Field: application_readable Type: 8 ()

# === Message: Google::Appengine::V1::AppYaml::ScriptHandler ===
    # Fields for ScriptHandler
    # Field: script_path Type: 9 ()

# === Message: Google::Appengine::V1::AppYaml::ApiEndpointHandler ===
    # Fields for ApiEndpointHandler
    # Field: script_path Type: 9 ()

# === Message: Google::Appengine::V1::AppYaml::HealthCheck ===
    # Fields for HealthCheck
    # Field: disable_health_check Type: 8 ()
    # Field: host Type: 9 ()
    # Field: healthy_threshold Type: 13 ()
    # Field: unhealthy_threshold Type: 13 ()
    # Field: restart_threshold Type: 13 ()
    # Field: check_interval Type: 11 (.google.protobuf.Duration)
    # Field: timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1::AppYaml::ReadinessCheck ===
    # Fields for ReadinessCheck
    # Field: path Type: 9 ()
    # Field: host Type: 9 ()
    # Field: failure_threshold Type: 13 ()
    # Field: success_threshold Type: 13 ()
    # Field: check_interval Type: 11 (.google.protobuf.Duration)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: app_start_timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1::AppYaml::LivenessCheck ===
    # Fields for LivenessCheck
    # Field: path Type: 9 ()
    # Field: host Type: 9 ()
    # Field: failure_threshold Type: 13 ()
    # Field: success_threshold Type: 13 ()
    # Field: check_interval Type: 11 (.google.protobuf.Duration)
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: initial_delay Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1::AppYaml::Library ===
    # Fields for Library
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::AppYaml - Compiled Protocol Buffers messages for google/appengine/v1/app_yaml.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::AppYaml;

    my $msg = Google::Appengine::V1::AppYaml::ApiConfigHandler->new({
        auth_fail_action => $auth_fail_action,
        login => $login,
        script => $script,
        security_level => $security_level,
    });

    # Read or update a field
    my $val = $msg->auth_fail_action();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::AppYaml::ApiConfigHandler->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/app_yaml.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::AppYaml::ApiConfigHandler

[Google Cloud Endpoints](https://cloud.google.com/appengine/docs/python/endpoints/)
configuration for API handlers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_fail_action() >> / C<< $msg->auth_fail_action($value) >>

Type: C<Enum> (L<Google::Appengine::V1::AuthFailAction>)

Action to take when users access resources that require
authentication. Defaults to `redirect`.

=item * C<< $msg->login() >> / C<< $msg->login($value) >>

Type: C<Enum> (L<Google::Appengine::V1::LoginRequirement>)

Level of login required to access this resource. Defaults to
`optional`.

=item * C<< $msg->script() >> / C<< $msg->script($value) >>

Type: C<String>

Path to the script from the application root directory.

=item * C<< $msg->security_level() >> / C<< $msg->security_level($value) >>

Type: C<Enum> (L<Google::Appengine::V1::SecurityLevel>)

Security (HTTPS) enforcement for this URL.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

URL to serve the endpoint at.

=back

=head2 Google::Appengine::V1::AppYaml::ErrorHandler

Custom static error page to be served when an error occurs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Enum> (L<Google::Appengine::V1::ErrorHandler::ErrorCode>)

Error condition this handler applies to.

=item * C<< $msg->static_file() >> / C<< $msg->static_file($value) >>

Type: C<String>

Static file content to be served for this error.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

MIME type of file. Defaults to `text/html`.

=back

=head3 Enum: ErrorHandler::ErrorCode

=over 4

=item * C<ERROR_CODE_UNSPECIFIED> => C<0>

=item * C<ERROR_CODE_DEFAULT> => C<0>

=item * C<ERROR_CODE_OVER_QUOTA> => C<1>

=item * C<ERROR_CODE_DOS_API_DENIAL> => C<2>

=item * C<ERROR_CODE_TIMEOUT> => C<3>

=back

=head2 Google::Appengine::V1::AppYaml::UrlMap

URL pattern and description of how the URL should be handled. App Engine can
handle URLs by executing application code or by serving static files
uploaded with the version, such as images, CSS, or JavaScript.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url_regex() >> / C<< $msg->url_regex($value) >>

Type: C<String>

URL prefix. Uses regular expression syntax, which means regexp
special characters must be escaped, but should not contain groupings.
All URLs that begin with this prefix are handled by this handler, using the
portion of the URL after the prefix as part of the file path.

=item * C<< $msg->static_files() >> / C<< $msg->static_files($value) >>

Type: C<Message> (L<Google::Appengine::V1::AppYaml::StaticFilesHandler>)

Returns the contents of a file, such as an image, as the response.

=item * C<< $msg->script() >> / C<< $msg->script($value) >>

Type: C<Message> (L<Google::Appengine::V1::AppYaml::ScriptHandler>)

Executes a script to handle the requests that match this URL
pattern. Only the `auto` value is supported for Node.js in the
App Engine standard environment, for example `"script": "auto"`.

=item * C<< $msg->api_endpoint() >> / C<< $msg->api_endpoint($value) >>

Type: C<Message> (L<Google::Appengine::V1::AppYaml::ApiEndpointHandler>)

Uses API Endpoints to handle requests.

=item * C<< $msg->security_level() >> / C<< $msg->security_level($value) >>

Type: C<Enum> (L<Google::Appengine::V1::SecurityLevel>)

Security (HTTPS) enforcement for this URL.

=item * C<< $msg->login() >> / C<< $msg->login($value) >>

Type: C<Enum> (L<Google::Appengine::V1::LoginRequirement>)

Level of login required to access this resource. Not supported for Node.js
in the App Engine standard environment.

=item * C<< $msg->auth_fail_action() >> / C<< $msg->auth_fail_action($value) >>

Type: C<Enum> (L<Google::Appengine::V1::AuthFailAction>)

Action to take when users access resources that require
authentication. Defaults to `redirect`.

=item * C<< $msg->redirect_http_response_code() >> / C<< $msg->redirect_http_response_code($value) >>

Type: C<Enum> (L<Google::Appengine::V1::UrlMap::RedirectHttpResponseCode>)

`30x` code to use when performing redirects for the `secure` field.
Defaults to `302`.

=back

=head3 Enum: UrlMap::RedirectHttpResponseCode

=over 4

=item * C<REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED> => C<0>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_301> => C<1>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_302> => C<2>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_303> => C<3>

=item * C<REDIRECT_HTTP_RESPONSE_CODE_307> => C<4>

=back

=head2 Google::Appengine::V1::AppYaml::StaticFilesHandler

Files served directly to the user for a given URL, such as images, CSS
stylesheets, or JavaScript source files. Static file handlers describe which
files in the application directory are static files, and which URLs serve
them.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Path to the static files matched by the URL pattern, from the
application root directory. The path can refer to text matched in groupings
in the URL pattern.

=item * C<< $msg->upload_path_regex() >> / C<< $msg->upload_path_regex($value) >>

Type: C<String>

Regular expression that matches the file paths for all files that should be
referenced by this handler.

=item * C<< $msg->http_headers() >> / C<< $msg->http_headers($value) >>

Type: C<Message> (L<Google::Appengine::V1::AppYaml::StaticFilesHandler::HttpHeadersEntry>)

HTTP headers to use for all responses from these URLs.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

MIME type used to serve all files served by this handler.

Defaults to file-specific MIME types, which are derived from each file's
filename extension.

=item * C<< $msg->expiration() >> / C<< $msg->expiration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time a static file served by this handler should be cached
by web proxies and browsers.

=item * C<< $msg->require_matching_file() >> / C<< $msg->require_matching_file($value) >>

Type: C<Bool>

Whether this handler should match the request if the file
referenced by the handler does not exist.

=item * C<< $msg->application_readable() >> / C<< $msg->application_readable($value) >>

Type: C<Bool>

Whether files should also be uploaded as code data. By default, files
declared in static file handlers are uploaded as static
data and are only served to end users; they cannot be read by the
application. If enabled, uploads are charged against both your code and
static data storage resource quotas.

=back

=head2 Google::Appengine::V1::AppYaml::ScriptHandler

Executes a script to handle the request that matches the URL pattern.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->script_path() >> / C<< $msg->script_path($value) >>

Type: C<String>

Path to the script from the application root directory.

=back

=head2 Google::Appengine::V1::AppYaml::ApiEndpointHandler

Uses Google Cloud Endpoints to handle requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->script_path() >> / C<< $msg->script_path($value) >>

Type: C<String>

Path to the script from the application root directory.

=back

=head2 Google::Appengine::V1::AppYaml::HealthCheck

Health checking configuration for VM instances. Unhealthy instances
are killed and replaced with new instances. Only applicable for
instances in App Engine flexible environment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disable_health_check() >> / C<< $msg->disable_health_check($value) >>

Type: C<Bool>

Whether to explicitly disable health checks for this instance.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host header to send when performing an HTTP health check.
Example: "myapp.appspot.com"

=item * C<< $msg->healthy_threshold() >> / C<< $msg->healthy_threshold($value) >>

Type: C<UInt32>

Number of consecutive successful health checks required before receiving
traffic.

=item * C<< $msg->unhealthy_threshold() >> / C<< $msg->unhealthy_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed health checks required before removing
traffic.

=item * C<< $msg->restart_threshold() >> / C<< $msg->restart_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed health checks required before an instance is
restarted.

=item * C<< $msg->check_interval() >> / C<< $msg->check_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Interval between health checks.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time before the health check is considered failed.

=back

=head2 Google::Appengine::V1::AppYaml::ReadinessCheck

Readiness checking configuration for VM instances. Unhealthy instances
are removed from traffic rotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The request path.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host header to send when performing a HTTP Readiness check.
Example: "myapp.appspot.com"

=item * C<< $msg->failure_threshold() >> / C<< $msg->failure_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed checks required before removing
traffic.

=item * C<< $msg->success_threshold() >> / C<< $msg->success_threshold($value) >>

Type: C<UInt32>

Number of consecutive successful checks required before receiving
traffic.

=item * C<< $msg->check_interval() >> / C<< $msg->check_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Interval between health checks.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time before the check is considered failed.

=item * C<< $msg->app_start_timeout() >> / C<< $msg->app_start_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

A maximum time limit on application initialization, measured from moment
the application successfully replies to a healthcheck until it is ready to
serve traffic.

=back

=head2 Google::Appengine::V1::AppYaml::LivenessCheck

Health checking configuration for VM instances. Unhealthy instances
are killed and replaced with new instances.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The request path.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host header to send when performing a HTTP Liveness check.
Example: "myapp.appspot.com"

=item * C<< $msg->failure_threshold() >> / C<< $msg->failure_threshold($value) >>

Type: C<UInt32>

Number of consecutive failed checks required before considering the
VM unhealthy.

=item * C<< $msg->success_threshold() >> / C<< $msg->success_threshold($value) >>

Type: C<UInt32>

Number of consecutive successful checks required before considering
the VM healthy.

=item * C<< $msg->check_interval() >> / C<< $msg->check_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Interval between health checks.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time before the check is considered failed.

=item * C<< $msg->initial_delay() >> / C<< $msg->initial_delay($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The initial delay before starting to execute the checks.

=back

=head2 Google::Appengine::V1::AppYaml::Library

Third-party Python runtime library that is required by the application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the library. Example: "django".

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of the library to select, or "latest".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::AppYaml::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
