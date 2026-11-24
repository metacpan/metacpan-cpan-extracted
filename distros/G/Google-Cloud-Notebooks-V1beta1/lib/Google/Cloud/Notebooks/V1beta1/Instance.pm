package Google::Cloud::Notebooks::V1beta1::Instance;

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
    eval { require Google::Cloud::Notebooks::V1beta1::Environment };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxYmV0YTEvaW5zdGFuY2UucHJvdG8SHmdvb2ds
ZS5jbG91ZC5ub3RlYm9va3MudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxowZ29vZ2xlL2Nsb3VkL25vdGVib29r
cy92MWJldGExL2Vudmlyb25tZW50LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIqMCChNSZXNlcnZhdGlvbkFmZmluaXR5EncKGGNvbnN1bWVfcmVzZXJ2YXRpb25f
dHlwZRgBIAEoDjI4Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjFiZXRhMS5SZXNlcnZhdGlv
bkFmZmluaXR5LlR5cGVCA+BBAVIWY29uc3VtZVJlc2VydmF0aW9uVHlwZRIVCgNrZXkYAiAB
KAlCA+BBAVIDa2V5EhsKBnZhbHVlcxgDIAMoCUID4EEBUgZ2YWx1ZXMiXwoEVHlwZRIUChBU
WVBFX1VOU1BFQ0lGSUVEEAASEgoOTk9fUkVTRVJWQVRJT04QARITCg9BTllfUkVTRVJWQVRJ
T04QAhIYChRTUEVDSUZJQ19SRVNFUlZBVElPThADIpUWCghJbnN0YW5jZRIXCgRuYW1lGAEg
ASgJQgPgQQNSBG5hbWUSRAoIdm1faW1hZ2UYAiABKAsyJy5nb29nbGUuY2xvdWQubm90ZWJv
b2tzLnYxYmV0YTEuVm1JbWFnZUgAUgd2bUltYWdlElkKD2NvbnRhaW5lcl9pbWFnZRgDIAEo
CzIuLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjFiZXRhMS5Db250YWluZXJJbWFnZUgAUg5j
b250YWluZXJJbWFnZRIuChNwb3N0X3N0YXJ0dXBfc2NyaXB0GAQgASgJUhFwb3N0U3RhcnR1
cFNjcmlwdBIgCglwcm94eV91cmkYBSABKAlCA+BBA1IIcHJveHlVcmkSLAoPaW5zdGFuY2Vf
b3duZXJzGAYgAygJQgPgQQRSDmluc3RhbmNlT3duZXJzEicKD3NlcnZpY2VfYWNjb3VudBgH
IAEoCVIOc2VydmljZUFjY291bnQSJgoMbWFjaGluZV90eXBlGAggASgJQgPgQQJSC21hY2hp
bmVUeXBlEmkKEmFjY2VsZXJhdG9yX2NvbmZpZxgJIAEoCzI6Lmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjFiZXRhMS5JbnN0YW5jZS5BY2NlbGVyYXRvckNvbmZpZ1IRYWNjZWxlcmF0b3JD
b25maWcSSQoFc3RhdGUYCiABKA4yLi5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxYmV0YTEu
SW5zdGFuY2UuU3RhdGVCA+BBA1IFc3RhdGUSLAoSaW5zdGFsbF9ncHVfZHJpdmVyGAsgASgI
UhBpbnN0YWxsR3B1RHJpdmVyEjMKFmN1c3RvbV9ncHVfZHJpdmVyX3BhdGgYDCABKAlSE2N1
c3RvbUdwdURyaXZlclBhdGgSXAoOYm9vdF9kaXNrX3R5cGUYDSABKA4yMS5nb29nbGUuY2xv
dWQubm90ZWJvb2tzLnYxYmV0YTEuSW5zdGFuY2UuRGlza1R5cGVCA+BBBFIMYm9vdERpc2tU
eXBlEi4KEWJvb3RfZGlza19zaXplX2diGA4gASgDQgPgQQRSDmJvb3REaXNrU2l6ZUdiElwK
DmRhdGFfZGlza190eXBlGBkgASgOMjEuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MWJldGEx
Lkluc3RhbmNlLkRpc2tUeXBlQgPgQQRSDGRhdGFEaXNrVHlwZRIuChFkYXRhX2Rpc2tfc2l6
ZV9nYhgaIAEoA0ID4EEEUg5kYXRhRGlza1NpemVHYhIyChNub19yZW1vdmVfZGF0YV9kaXNr
GBsgASgIQgPgQQRSEG5vUmVtb3ZlRGF0YURpc2sSZQoPZGlza19lbmNyeXB0aW9uGA8gASgO
MjcuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MWJldGExLkluc3RhbmNlLkRpc2tFbmNyeXB0
aW9uQgPgQQRSDmRpc2tFbmNyeXB0aW9uEhwKB2ttc19rZXkYECABKAlCA+BBBFIGa21zS2V5
EiAKDG5vX3B1YmxpY19pcBgRIAEoCFIKbm9QdWJsaWNJcBImCg9ub19wcm94eV9hY2Nlc3MY
EiABKAhSDW5vUHJveHlBY2Nlc3MSGAoHbmV0d29yaxgTIAEoCVIHbmV0d29yaxIWCgZzdWJu
ZXQYFCABKAlSBnN1Ym5ldBJMCgZsYWJlbHMYFSADKAsyNC5nb29nbGUuY2xvdWQubm90ZWJv
b2tzLnYxYmV0YTEuSW5zdGFuY2UuTGFiZWxzRW50cnlSBmxhYmVscxJSCghtZXRhZGF0YRgW
IAMoCzI2Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjFiZXRhMS5JbnN0YW5jZS5NZXRhZGF0
YUVudHJ5UghtZXRhZGF0YRJQCghuaWNfdHlwZRgcIAEoDjIwLmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjFiZXRhMS5JbnN0YW5jZS5OaWNUeXBlQgPgQQFSB25pY1R5cGUSawoUcmVzZXJ2
YXRpb25fYWZmaW5pdHkYHSABKAsyMy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxYmV0YTEu
UmVzZXJ2YXRpb25BZmZpbml0eUID4EEBUhNyZXNlcnZhdGlvbkFmZmluaXR5EikKDmNhbl9p
cF9mb3J3YXJkGB8gASgIQgPgQQFSDGNhbklwRm9yd2FyZBJACgtjcmVhdGVfdGltZRgXIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRh
dGVfdGltZRgYIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRqAAQoRQWNjZWxlcmF0b3JDb25maWcSTAoEdHlwZRgBIAEoDjI4Lmdvb2dsZS5jbG91
ZC5ub3RlYm9va3MudjFiZXRhMS5JbnN0YW5jZS5BY2NlbGVyYXRvclR5cGVSBHR5cGUSHQoK
Y29yZV9jb3VudBgCIAEoA1IJY29yZUNvdW50GjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaOwoNTWV0YWRhdGFFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIoYCCg9BY2NlbGVyYXRv
clR5cGUSIAocQUNDRUxFUkFUT1JfVFlQRV9VTlNQRUNJRklFRBAAEhQKEE5WSURJQV9URVNM
QV9LODAQARIVChFOVklESUFfVEVTTEFfUDEwMBACEhUKEU5WSURJQV9URVNMQV9WMTAwEAMS
EwoPTlZJRElBX1RFU0xBX1A0EAQSEwoPTlZJRElBX1RFU0xBX1Q0EAUSFwoTTlZJRElBX1RF
U0xBX1Q0X1ZXUxAIEhkKFU5WSURJQV9URVNMQV9QMTAwX1ZXUxAJEhcKE05WSURJQV9URVNM
QV9QNF9WV1MQChIKCgZUUFVfVjIQBhIKCgZUUFVfVjMQByLDAQoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIMCghTVEFSVElORxABEhAKDFBST1ZJU0lPTklORxACEgoKBkFDVElW
RRADEgwKCFNUT1BQSU5HEAQSCwoHU1RPUFBFRBAFEgsKB0RFTEVURUQQBhINCglVUEdSQURJ
TkcQBxIQCgxJTklUSUFMSVpJTkcQCBIPCgtSRUdJU1RFUklORxAJEg4KClNVU1BFTkRJTkcQ
ChINCglTVVNQRU5ERUQQCyJTCghEaXNrVHlwZRIZChVESVNLX1RZUEVfVU5TUEVDSUZJRUQQ
ABIPCgtQRF9TVEFOREFSRBABEgoKBlBEX1NTRBACEg8KC1BEX0JBTEFOQ0VEEAMiRQoORGlz
a0VuY3J5cHRpb24SHwobRElTS19FTkNSWVBUSU9OX1VOU1BFQ0lGSUVEEAASCAoER01FSxAB
EggKBENNRUsQAiI+CgdOaWNUeXBlEhgKFFVOU1BFQ0lGSUVEX05JQ19UWVBFEAASDgoKVklS
VElPX05FVBABEgkKBUdWTklDEAI6T+pBTAohbm90ZWJvb2tzLmdvb2dsZWFwaXMuY29tL0lu
c3RhbmNlEidwcm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX1CDQoLZW52
aXJvbm1lbnRC3QEKImNvbS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxYmV0YTFCDUluc3Rh
bmNlUHJvdG9QAVpAY2xvdWQuZ29vZ2xlLmNvbS9nby9ub3RlYm9va3MvYXBpdjFiZXRhMS9u
b3RlYm9va3NwYjtub3RlYm9va3NwYqoCHkdvb2dsZS5DbG91ZC5Ob3RlYm9va3MuVjFCZXRh
McoCHkdvb2dsZVxDbG91ZFxOb3RlYm9va3NcVjFiZXRhMeoCIUdvb2dsZTo6Q2xvdWQ6Ok5v
dGVib29rczo6VjFiZXRhMUqXYQoHEgUOAMwCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
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
TGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOgoJ
CgIDAxIDFQApCggKAQgSAxcAOwoJCgIIJRIDFwA7CggKAQgSAxgAVwoJCgIICxIDGABXCggK
AQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoALgoJCgIICBIDGgAuCggKAQgSAxsAOwoJCgII
ARIDGwA7CggKAQgSAxwAOwoJCgIIKRIDHAA7CggKAQgSAx0AOgoJCgIILRIDHQA6CkMKAgQA
EgQgADkBGjcgUmVzZXJ2YXRpb24gQWZmaW5pdHkgZm9yIGNvbnN1bWluZyBab25hbCByZXNl
cnZhdGlvbi4KCgoKAwQAARIDIAgbClEKBAQABAASBCICLwMaQyBJbmRpY2F0ZXMgd2hldGhl
ciB0byBjb25zdW1lIGNhcGFjaXR5IGZyb20gYW4gcmVzZXJ2YXRpb24gb3Igbm90LgoKDAoF
BAAEAAESAyIHCwoeCgYEAAQAAgASAyQEGRoPIERlZmF1bHQgdHlwZS4KCg4KBwQABAACAAES
AyQEFAoOCgcEAAQAAgACEgMkFxgKPAoGBAAEAAIBEgMnBBcaLSBEbyBub3QgY29uc3VtZSBm
cm9tIGFueSBhbGxvY2F0ZWQgY2FwYWNpdHkuCgoOCgcEAAQAAgEBEgMnBBIKDgoHBAAEAAIB
AhIDJxUWCjMKBgQABAACAhIDKgQYGiQgQ29uc3VtZSBhbnkgcmVzZXJ2YXRpb24gYXZhaWxh
YmxlLgoKDgoHBAAEAAICARIDKgQTCg4KBwQABAACAgISAyoWFwp6CgYEAAQAAgMSAy4EHRpr
IE11c3QgY29uc3VtZSBmcm9tIGEgc3BlY2lmaWMgcmVzZXJ2YXRpb24uIE11c3Qgc3BlY2lm
eSBrZXkgdmFsdWUgZmllbGRzCiBmb3Igc3BlY2lmeWluZyB0aGUgcmVzZXJ2YXRpb25zLgoK
DgoHBAAEAAIDARIDLgQYCg4KBwQABAACAwISAy4bHAo3CgQEAAIAEgMyAk0aKiBPcHRpb25h
bC4gVHlwZSBvZiByZXNlcnZhdGlvbiB0byBjb25zdW1lCgoMCgUEAAIABhIDMgIGCgwKBQQA
AgABEgMyBx8KDAoFBAACAAMSAzIiIwoMCgUEAAIACBIDMiRMCg8KCAQAAgAInAgAEgMyJUsK
TgoEBAACARIDNQI6GkEgT3B0aW9uYWwuIENvcnJlc3BvbmRzIHRvIHRoZSBsYWJlbCBrZXkg
b2YgcmVzZXJ2YXRpb24gcmVzb3VyY2UuCgoMCgUEAAIBBRIDNQIICgwKBQQAAgEBEgM1CQwK
DAoFBAACAQMSAzUPEAoMCgUEAAIBCBIDNRE5Cg8KCAQAAgEInAgAEgM1EjgKUQoEBAACAhID
OAJGGkQgT3B0aW9uYWwuIENvcnJlc3BvbmRzIHRvIHRoZSBsYWJlbCB2YWx1ZXMgb2YgcmVz
ZXJ2YXRpb24gcmVzb3VyY2UuCgoMCgUEAAICBBIDOAIKCgwKBQQAAgIFEgM4CxEKDAoFBAAC
AgESAzgSGAoMCgUEAAICAxIDOBscCgwKBQQAAgIIEgM4HUUKDwoIBAACAgicCAASAzgeRAo1
CgIEARIFPADMAgEaKCBUaGUgZGVmaW5pdGlvbiBvZiBhIG5vdGVib29rIGluc3RhbmNlLgoK
CgoDBAEBEgM8CBAKCwoDBAEHEgQ9AkAECg0KBQQBB50IEgQ9AkAECmQKBAQBBAASBEQCZQMa
ViBEZWZpbml0aW9uIG9mIHRoZSB0eXBlcyBvZiBoYXJkd2FyZSBhY2NlbGVyYXRvcnMgdGhh
dCBjYW4gYmUgdXNlZCBvbiB0aGlzCiBpbnN0YW5jZS4KCgwKBQQBBAABEgNEBxYKMwoGBAEE
AAIAEgNGBCUaJCBBY2NlbGVyYXRvciB0eXBlIGlzIG5vdCBzcGVjaWZpZWQuCgoOCgcEAQQA
AgABEgNGBCAKDgoHBAEEAAIAAhIDRiMkCjYKBgQBBAACARIDSQQZGicgQWNjZWxlcmF0b3Ig
dHlwZSBpcyBOdmlkaWEgVGVzbGEgSzgwLgoKDgoHBAEEAAIBARIDSQQUCg4KBwQBBAACAQIS
A0kXGAo3CgYEAQQAAgISA0wEGhooIEFjY2VsZXJhdG9yIHR5cGUgaXMgTnZpZGlhIFRlc2xh
IFAxMDAuCgoOCgcEAQQAAgIBEgNMBBUKDgoHBAEEAAICAhIDTBgZCjcKBgQBBAACAxIDTwQa
GiggQWNjZWxlcmF0b3IgdHlwZSBpcyBOdmlkaWEgVGVzbGEgVjEwMC4KCg4KBwQBBAACAwES
A08EFQoOCgcEAQQAAgMCEgNPGBkKNQoGBAEEAAIEEgNSBBgaJiBBY2NlbGVyYXRvciB0eXBl
IGlzIE52aWRpYSBUZXNsYSBQNC4KCg4KBwQBBAACBAESA1IEEwoOCgcEAQQAAgQCEgNSFhcK
NQoGBAEEAAIFEgNVBBgaJiBBY2NlbGVyYXRvciB0eXBlIGlzIE52aWRpYSBUZXNsYSBUNC4K
Cg4KBwQBBAACBQESA1UEEwoOCgcEAQQAAgUCEgNVFhcKSgoGBAEEAAIGEgNYBBwaOyBBY2Nl
bGVyYXRvciB0eXBlIGlzIE5WSURJQSBUZXNsYSBUNCBWaXJ0dWFsIFdvcmtzdGF0aW9ucy4K
Cg4KBwQBBAACBgESA1gEFwoOCgcEAQQAAgYCEgNYGhsKTAoGBAEEAAIHEgNbBB4aPSBBY2Nl
bGVyYXRvciB0eXBlIGlzIE5WSURJQSBUZXNsYSBQMTAwIFZpcnR1YWwgV29ya3N0YXRpb25z
LgoKDgoHBAEEAAIHARIDWwQZCg4KBwQBBAACBwISA1scHQpKCgYEAQQAAggSA14EHRo7IEFj
Y2VsZXJhdG9yIHR5cGUgaXMgTlZJRElBIFRlc2xhIFA0IFZpcnR1YWwgV29ya3N0YXRpb25z
LgoKDgoHBAEEAAIIARIDXgQXCg4KBwQBBAACCAISA14aHAo6CgYEAQQAAgkSA2EEDxorIChD
b21pbmcgc29vbikgQWNjZWxlcmF0b3IgdHlwZSBpcyBUUFUgVjIuCgoOCgcEAQQAAgkBEgNh
BAoKDgoHBAEEAAIJAhIDYQ0OCjoKBgQBBAACChIDZAQPGisgKENvbWluZyBzb29uKSBBY2Nl
bGVyYXRvciB0eXBlIGlzIFRQVSBWMy4KCg4KBwQBBAACCgESA2QECgoOCgcEAQQAAgoCEgNk
DQ4KiQIKBAQBAwASBGsCcQMa+gEgRGVmaW5pdGlvbiBvZiBhIGhhcmR3YXJlIGFjY2VsZXJh
dG9yLiBOb3RlIHRoYXQgbm90IGFsbCBjb21iaW5hdGlvbnMKIG9mIGB0eXBlYCBhbmQgYGNv
cmVfY291bnRgIGFyZSB2YWxpZC4gQ2hlY2sgW0dQVXMgb24gQ29tcHV0ZQogRW5naW5lXSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2dwdXMvI2dwdXMtbGlzdCkg
dG8gZmluZCBhCiB2YWxpZCBjb21iaW5hdGlvbi4gVFBVcyBhcmUgbm90IHN1cHBvcnRlZC4K
CgwKBQQBAwABEgNrChsKKgoGBAEDAAIAEgNtBB0aGyBUeXBlIG9mIHRoaXMgYWNjZWxlcmF0
b3IuCgoOCgcEAQMAAgAGEgNtBBMKDgoHBAEDAAIAARIDbRQYCg4KBwQBAwACAAMSA20bHAo0
CgYEAQMAAgESA3AEGRolIENvdW50IG9mIGNvcmVzIG9mIHRoaXMgYWNjZWxlcmF0b3IuCgoO
CgcEAQMAAgEFEgNwBAkKDgoHBAEDAAIBARIDcAoUCg4KBwQBAwACAQMSA3AXGAo/CgQEAQQB
EgV0ApkBAxowIFRoZSBkZWZpbml0aW9uIG9mIHRoZSBzdGF0ZXMgb2YgdGhpcyBpbnN0YW5j
ZS4KCgwKBQQBBAEBEgN0BwwKKAoGBAEEAQIAEgN2BBoaGSBTdGF0ZSBpcyBub3Qgc3BlY2lm
aWVkLgoKDgoHBAEEAQIAARIDdgQVCg4KBwQBBAECAAISA3YYGQo8CgYEAQQBAgESA3kEERot
IFRoZSBjb250cm9sIGxvZ2ljIGlzIHN0YXJ0aW5nIHRoZSBpbnN0YW5jZS4KCg4KBwQBBAEC
AQESA3kEDAoOCgcEAQQBAgECEgN5DxAKdgoGBAEEAQICEgN9BBUaZyBUaGUgY29udHJvbCBs
b2dpYyBpcyBpbnN0YWxsaW5nIHJlcXVpcmVkIGZyYW1ld29ya3MgYW5kIHJlZ2lzdGVyaW5n
IHRoZQogaW5zdGFuY2Ugd2l0aCBub3RlYm9vayBwcm94eQoKDgoHBAEEAQICARIDfQQQCg4K
BwQBBAECAgISA30TFAoqCgYEAQQBAgMSBIABBA8aGiBUaGUgaW5zdGFuY2UgaXMgcnVubmlu
Zy4KCg8KBwQBBAECAwESBIABBAoKDwoHBAEEAQIDAhIEgAENDgo9CgYEAQQBAgQSBIMBBBEa
LSBUaGUgY29udHJvbCBsb2dpYyBpcyBzdG9wcGluZyB0aGUgaW5zdGFuY2UuCgoPCgcEAQQB
AgQBEgSDAQQMCg8KBwQBBAECBAISBIMBDxAKKgoGBAEEAQIFEgSGAQQQGhogVGhlIGluc3Rh
bmNlIGlzIHN0b3BwZWQuCgoPCgcEAQQBAgUBEgSGAQQLCg8KBwQBBAECBQISBIYBDg8KKgoG
BAEEAQIGEgSJAQQQGhogVGhlIGluc3RhbmNlIGlzIGRlbGV0ZWQuCgoPCgcEAQQBAgYBEgSJ
AQQLCg8KBwQBBAECBgISBIkBDg8KLAoGBAEEAQIHEgSMAQQSGhwgVGhlIGluc3RhbmNlIGlz
IHVwZ3JhZGluZy4KCg8KBwQBBAECBwESBIwBBA0KDwoHBAEEAQIHAhIEjAEQEQowCgYEAQQB
AggSBI8BBBUaICBUaGUgaW5zdGFuY2UgaXMgYmVpbmcgY3JlYXRlZC4KCg8KBwQBBAECCAES
BI8BBBAKDwoHBAEEAQIIAhIEjwETFAo1CgYEAQQBAgkSBJIBBBQaJSBUaGUgaW5zdGFuY2Ug
aXMgZ2V0dGluZyByZWdpc3RlcmVkLgoKDwoHBAEEAQIJARIEkgEEDwoPCgcEAQQBAgkCEgSS
ARITCi0KBgQBBAECChIElQEEFBodIFRoZSBpbnN0YW5jZSBpcyBzdXNwZW5kaW5nLgoKDwoH
BAEEAQIKARIElQEEDgoPCgcEAQQBAgoCEgSVARETCiwKBgQBBAECCxIEmAEEExocIFRoZSBp
bnN0YW5jZSBpcyBzdXNwZW5kZWQuCgoPCgcEAQQBAgsBEgSYAQQNCg8KBwQBBAECCwISBJgB
EBIKPQoEBAEEAhIGnAECqAEDGi0gUG9zc2libGUgZGlzayB0eXBlcyBmb3Igbm90ZWJvb2sg
aW5zdGFuY2VzLgoKDQoFBAEEAgESBJwBBw8KJAoGBAEEAgIAEgSeAQQeGhQgRGlzayB0eXBl
IG5vdCBzZXQuCgoPCgcEAQQCAgABEgSeAQQZCg8KBwQBBAICAAISBJ4BHB0KMAoGBAEEAgIB
EgShAQQUGiAgU3RhbmRhcmQgcGVyc2lzdGVudCBkaXNrIHR5cGUuCgoPCgcEAQQCAgEBEgSh
AQQPCg8KBwQBBAICAQISBKEBEhMKKwoGBAEEAgICEgSkAQQPGhsgU1NEIHBlcnNpc3RlbnQg
ZGlzayB0eXBlLgoKDwoHBAEEAgICARIEpAEECgoPCgcEAQQCAgICEgSkAQ0OCjAKBgQBBAIC
AxIEpwEEFBogIEJhbGFuY2VkIHBlcnNpc3RlbnQgZGlzayB0eXBlLgoKDwoHBAEEAgIDARIE
pwEEDwoPCgcEAQQCAgMCEgSnARITCjwKBAQBBAMSBqsBArQBAxosIERlZmluaXRpb24gb2Yg
dGhlIGRpc2sgZW5jcnlwdGlvbiBvcHRpb25zLgoKDQoFBAEEAwESBKsBBxUKMwoGBAEEAwIA
EgStAQQkGiMgRGlzayBlbmNyeXB0aW9uIGlzIG5vdCBzcGVjaWZpZWQuCgoPCgcEAQQDAgAB
EgStAQQfCg8KBwQBBAMCAAISBK0BIiMKTgoGBAEEAwIBEgSwAQQNGj4gVXNlIEdvb2dsZSBt
YW5hZ2VkIGVuY3J5cHRpb24ga2V5cyB0byBlbmNyeXB0IHRoZSBib290IGRpc2suCgoPCgcE
AQQDAgEBEgSwAQQICg8KBwQBBAMCAQISBLABCwwKUAoGBAEEAwICEgSzAQQNGkAgVXNlIGN1
c3RvbWVyIG1hbmFnZWQgZW5jcnlwdGlvbiBrZXlzIHRvIGVuY3J5cHQgdGhlIGJvb3QgZGlz
ay4KCg8KBwQBBAMCAgESBLMBBAgKDwoHBAEEAwICAhIEswELDAoqCgQEAQQEEga3AQLBAQMa
GiBUaGUgdHlwZSBvZiB2TklDIGRyaXZlci4KCg0KBQQBBAQBEgS3AQcOCkwKBgQBBAQCABIE
uQEEHRo8IE5vIHR5cGUgc3BlY2lmaWVkLiBEZWZhdWx0IHNob3VsZCBiZSBVTlNQRUNJRklF
RF9OSUNfVFlQRS4KCg8KBwQBBAQCAAESBLkBBBgKDwoHBAEEBAIAAhIEuQEbHAo0CgYEAQQE
AgESBLwBBBMaJCBWSVJUSU8uIERlZmF1bHQgaW4gTm90ZWJvb2tzIERMVk0uCgoPCgcEAQQE
AgEBEgS8AQQOCg8KBwQBBAQCAQISBLwBERIKdgoGBAEEBAICEgTAAQQOGmYgR1ZOSUMuIEFs
dGVybmF0aXZlIHRvIFZJUlRJTy4KIGh0dHBzOi8vZ2l0aHViLmNvbS9Hb29nbGVDbG91ZFBs
YXRmb3JtL2NvbXB1dGUtdmlydHVhbC1ldGhlcm5ldC1saW51eAoKDwoHBAEEBAICARIEwAEE
CQoPCgcEAQQEAgICEgTAAQwNCo8BCgQEAQIAEgTFAQI+GoABIE91dHB1dCBvbmx5LiBUaGUg
bmFtZSBvZiB0aGlzIG5vdGVib29rIGluc3RhbmNlLiBGb3JtYXQ6CiBgcHJvamVjdHMve3By
b2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2VfaWR9
YAoKDQoFBAECAAUSBMUBAggKDQoFBAECAAESBMUBCQ0KDQoFBAECAAMSBMUBEBEKDQoFBAEC
AAgSBMUBEj0KEAoIBAECAAicCAASBMUBEzwKVgoEBAEIABIGyAECzgEDGkYgVHlwZSBvZiB0
aGUgZW52aXJvbm1lbnQ7IGNhbiBiZSBvbmUgb2YgVk0gaW1hZ2UsIG9yIGNvbnRhaW5lciBp
bWFnZS4KCg0KBQQBCAABEgTIAQgTCk0KBAQBAgESBMoBBBkaPyBVc2UgYSBDb21wdXRlIEVu
Z2luZSBWTSBpbWFnZSB0byBzdGFydCB0aGUgbm90ZWJvb2sgaW5zdGFuY2UuCgoNCgUEAQIB
BhIEygEECwoNCgUEAQIBARIEygEMFAoNCgUEAQIBAxIEygEXGApFCgQEAQICEgTNAQQnGjcg
VXNlIGEgY29udGFpbmVyIGltYWdlIHRvIHN0YXJ0IHRoZSBub3RlYm9vayBpbnN0YW5jZS4K
Cg0KBQQBAgIGEgTNAQQSCg0KBQQBAgIBEgTNARMiCg0KBQQBAgIDEgTNASUmCrgBCgQEAQID
EgTTAQIhGqkBIFBhdGggdG8gYSBCYXNoIHNjcmlwdCB0aGF0IGF1dG9tYXRpY2FsbHkgcnVu
cyBhZnRlciBhIG5vdGVib29rIGluc3RhbmNlCiBmdWxseSBib290cyB1cC4gVGhlIHBhdGgg
bXVzdCBiZSBhIFVSTCBvcgogQ2xvdWQgU3RvcmFnZSBwYXRoIChgZ3M6Ly9wYXRoLXRvLWZp
bGUvZmlsZS1uYW1lYCkuCgoNCgUEAQIDBRIE0wECCAoNCgUEAQIDARIE0wEJHAoNCgUEAQID
AxIE0wEfIApcCgQEAQIEEgTWAQJDGk4gT3V0cHV0IG9ubHkuIFRoZSBwcm94eSBlbmRwb2lu
dCB0aGF0IGlzIHVzZWQgdG8gYWNjZXNzIHRoZSBKdXB5dGVyIG5vdGVib29rLgoKDQoFBAEC
BAUSBNYBAggKDQoFBAECBAESBNYBCRIKDQoFBAECBAMSBNYBFRYKDQoFBAECBAgSBNYBF0IK
EAoIBAECBAicCAASBNYBGEEK+QEKBAQBAgUSBN0BAlEa6gEgSW5wdXQgb25seS4gVGhlIG93
bmVyIG9mIHRoaXMgaW5zdGFuY2UgYWZ0ZXIgY3JlYXRpb24uIEZvcm1hdDogYGFsaWFzQGV4
YW1wbGUuY29tYAoKIEN1cnJlbnRseSBzdXBwb3J0cyBvbmUgb3duZXIgb25seS4gSWYgbm90
IHNwZWNpZmllZCwgYWxsIG9mIHRoZSBzZXJ2aWNlCiBhY2NvdW50IHVzZXJzIG9mIHlvdXIg
Vk0gaW5zdGFuY2UncyBzZXJ2aWNlIGFjY291bnQgY2FuIHVzZQogdGhlIGluc3RhbmNlLgoK
DQoFBAECBQQSBN0BAgoKDQoFBAECBQUSBN0BCxEKDQoFBAECBQESBN0BEiEKDQoFBAECBQMS
BN0BJCUKDQoFBAECBQgSBN0BJlAKEAoIBAECBQicCAASBN0BJ08KjgMKBAQBAgYSBOcBAh0a
/wIgVGhlIHNlcnZpY2UgYWNjb3VudCBvbiB0aGlzIGluc3RhbmNlLCBnaXZpbmcgYWNjZXNz
IHRvIG90aGVyIEdvb2dsZQogQ2xvdWQgc2VydmljZXMuCiBZb3UgY2FuIHVzZSBhbnkgc2Vy
dmljZSBhY2NvdW50IHdpdGhpbiB0aGUgc2FtZSBwcm9qZWN0LCBidXQgeW91CiBtdXN0IGhh
dmUgdGhlIHNlcnZpY2UgYWNjb3VudCB1c2VyIHBlcm1pc3Npb24gdG8gdXNlIHRoZSBpbnN0
YW5jZS4KCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgW0NvbXB1dGUgRW5naW5lIGRlZmF1bHQg
c2VydmljZQogYWNjb3VudF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9j
cy9hY2Nlc3Mvc2VydmljZS1hY2NvdW50cyNkZWZhdWx0X3NlcnZpY2VfYWNjb3VudCkKIGlz
IHVzZWQuCgoNCgUEAQIGBRIE5wECCAoNCgUEAQIGARIE5wEJGAoNCgUEAQIGAxIE5wEbHAqE
AQoEBAECBxIE7AECQxp2IFJlcXVpcmVkLiBUaGUgW0NvbXB1dGUgRW5naW5lIG1hY2hpbmUK
IHR5cGVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3MvbWFjaGluZS10
eXBlcykgb2YgdGhpcwogaW5zdGFuY2UuCgoNCgUEAQIHBRIE7AECCAoNCgUEAQIHARIE7AEJ
FQoNCgUEAQIHAxIE7AEYGQoNCgUEAQIHCBIE7AEaQgoQCggEAQIHCJwIABIE7AEbQQqEAgoE
BAECCBIE8gECKxr1ASBUaGUgaGFyZHdhcmUgYWNjZWxlcmF0b3IgdXNlZCBvbiB0aGlzIGlu
c3RhbmNlLiBJZiB5b3UgdXNlCiBhY2NlbGVyYXRvcnMsIG1ha2Ugc3VyZSB0aGF0IHlvdXIg
Y29uZmlndXJhdGlvbiBoYXMKIFtlbm91Z2ggdkNQVXMgYW5kIG1lbW9yeSB0byBzdXBwb3J0
IHRoZSBgbWFjaGluZV90eXBlYCB5b3UgaGF2ZQogc2VsZWN0ZWRdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9jb21wdXRlL2RvY3MvZ3B1cy8jZ3B1cy1saXN0KS4KCg0KBQQBAggGEgTy
AQITCg0KBQQBAggBEgTyARQmCg0KBQQBAggDEgTyASkqCjgKBAQBAgkSBPUBAj8aKiBPdXRw
dXQgb25seS4gVGhlIHN0YXRlIG9mIHRoaXMgaW5zdGFuY2UuCgoNCgUEAQIJBhIE9QECBwoN
CgUEAQIJARIE9QEIDQoNCgUEAQIJAxIE9QEQEgoNCgUEAQIJCBIE9QETPgoQCggEAQIJCJwI
ABIE9QEUPQrbAQoEBAECChIE+wECHxrMASBXaGV0aGVyIHRoZSBlbmQgdXNlciBhdXRob3Jp
emVzIEdvb2dsZSBDbG91ZCB0byBpbnN0YWxsIEdQVSBkcml2ZXIKIG9uIHRoaXMgaW5zdGFu
Y2UuCiBJZiB0aGlzIGZpZWxkIGlzIGVtcHR5IG9yIHNldCB0byBmYWxzZSwgdGhlIEdQVSBk
cml2ZXIgd29uJ3QgYmUgaW5zdGFsbGVkLgogT25seSBhcHBsaWNhYmxlIHRvIGluc3RhbmNl
cyB3aXRoIEdQVXMuCgoNCgUEAQIKBRIE+wECBgoNCgUEAQIKARIE+wEHGQoNCgUEAQIKAxIE
+wEcHgqdAQoEBAECCxIE/wECJRqOASBTcGVjaWZ5IGEgY3VzdG9tIENsb3VkIFN0b3JhZ2Ug
cGF0aCB3aGVyZSB0aGUgR1BVIGRyaXZlciBpcyBzdG9yZWQuCiBJZiBub3Qgc3BlY2lmaWVk
LCB3ZSdsbCBhdXRvbWF0aWNhbGx5IGNob29zZSBmcm9tIG9mZmljaWFsIEdQVSBkcml2ZXJz
LgoKDQoFBAECCwUSBP8BAggKDQoFBAECCwESBP8BCR8KDQoFBAECCwMSBP8BIiQKhwEKBAQB
AgwSBIMCAkoaeSBJbnB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGUgYm9vdCBkaXNrIGF0dGFj
aGVkIHRvIHRoaXMgaW5zdGFuY2UsIGRlZmF1bHRzIHRvCiBzdGFuZGFyZCBwZXJzaXN0ZW50
IGRpc2sgKGBQRF9TVEFOREFSRGApLgoKDQoFBAECDAYSBIMCAgoKDQoFBAECDAESBIMCCxkK
DQoFBAECDAMSBIMCHB4KDQoFBAECDAgSBIMCH0kKEAoIBAECDAicCAASBIMCIEgKzwEKBAQB
Ag0SBIgCAkoawAEgSW5wdXQgb25seS4gVGhlIHNpemUgb2YgdGhlIGJvb3QgZGlzayBpbiBH
QiBhdHRhY2hlZCB0byB0aGlzIGluc3RhbmNlLCB1cCB0byBhIG1heGltdW0KIG9mIDY0MDAw
IEdCICg2NCBUQikuIFRoZSBtaW5pbXVtIHJlY29tbWVuZGVkIHZhbHVlIGlzIDEwMCBHQi4g
SWYgbm90CiBzcGVjaWZpZWQsIHRoaXMgZGVmYXVsdHMgdG8gMTAwLgoKDQoFBAECDQUSBIgC
AgcKDQoFBAECDQESBIgCCBkKDQoFBAECDQMSBIgCHB4KDQoFBAECDQgSBIgCH0kKEAoIBAEC
DQicCAASBIgCIEgKhwEKBAQBAg4SBIwCAkoaeSBJbnB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0
aGUgZGF0YSBkaXNrIGF0dGFjaGVkIHRvIHRoaXMgaW5zdGFuY2UsIGRlZmF1bHRzIHRvCiBz
dGFuZGFyZCBwZXJzaXN0ZW50IGRpc2sgKGBQRF9TVEFOREFSRGApLgoKDQoFBAECDgYSBIwC
AgoKDQoFBAECDgESBIwCCxkKDQoFBAECDgMSBIwCHB4KDQoFBAECDggSBIwCH0kKEAoIBAEC
DgicCAASBIwCIEgK/QEKBAQBAg8SBJECAkoa7gEgSW5wdXQgb25seS4gVGhlIHNpemUgb2Yg
dGhlIGRhdGEgZGlzayBpbiBHQiBhdHRhY2hlZCB0byB0aGlzIGluc3RhbmNlLCB1cCB0byBh
IG1heGltdW0KIG9mIDY0MDAwIEdCICg2NCBUQikuIFlvdSBjYW4gY2hvb3NlIHRoZSBzaXpl
IG9mIHRoZSBkYXRhIGRpc2sgYmFzZWQgb24gaG93CiBiaWcgeW91ciBub3RlYm9va3MgYW5k
IGRhdGEgYXJlLiBJZiBub3Qgc3BlY2lmaWVkLCB0aGlzIGRlZmF1bHRzIHRvIDEwMC4KCg0K
BQQBAg8FEgSRAgIHCg0KBQQBAg8BEgSRAggZCg0KBQQBAg8DEgSRAhweCg0KBQQBAg8IEgSR
Ah9JChAKCAQBAg8InAgAEgSRAiBICmcKBAQBAhASBJQCAksaWSBJbnB1dCBvbmx5LiBJZiB0
cnVlLCB0aGUgZGF0YSBkaXNrIHdpbGwgbm90IGJlIGF1dG8gZGVsZXRlZCB3aGVuIGRlbGV0
aW5nIHRoZSBpbnN0YW5jZS4KCg0KBQQBAhAFEgSUAgIGCg0KBQQBAhABEgSUAgcaCg0KBQQB
AhADEgSUAh0fCg0KBQQBAhAIEgSUAiBKChAKCAQBAhAInAgAEgSUAiFJCmUKBAQBAhESBJcC
AlEaVyBJbnB1dCBvbmx5LiBEaXNrIGVuY3J5cHRpb24gbWV0aG9kIHVzZWQgb24gdGhlIGJv
b3QgYW5kIGRhdGEgZGlza3MsIGRlZmF1bHRzIHRvIEdNRUsuCgoNCgUEAQIRBhIElwICEAoN
CgUEAQIRARIElwIRIAoNCgUEAQIRAxIElwIjJQoNCgUEAQIRCBIElwImUAoQCggEAQIRCJwI
ABIElwInTwq2AgoEBAECEhIEoAICQRqnAiBJbnB1dCBvbmx5LiBUaGUgS01TIGtleSB1c2Vk
IHRvIGVuY3J5cHQgdGhlIGRpc2tzLCBvbmx5IGFwcGxpY2FibGUgaWYgZGlza19lbmNyeXB0
aW9uCiBpcyBDTUVLLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3JpbmdfaWR9L2NyeXB0b0tleXMve2tleV9p
ZH1gCgogTGVhcm4gbW9yZSBhYm91dCBbdXNpbmcgeW91ciBvd24gZW5jcnlwdGlvbgoga2V5
c10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2ttcy9kb2NzL3F1aWNrc3RhcnQpLgoKDQoF
BAECEgUSBKACAggKDQoFBAECEgESBKACCRAKDQoFBAECEgMSBKACExUKDQoFBAECEggSBKAC
FkAKEAoIBAECEgicCAASBKACFz8KSAoEBAECExIEowICGRo6IElmIHRydWUsIG5vIHB1Ymxp
YyBJUCB3aWxsIGJlIGFzc2lnbmVkIHRvIHRoaXMgaW5zdGFuY2UuCgoNCgUEAQITBRIEowIC
BgoNCgUEAQITARIEowIHEwoNCgUEAQITAxIEowIWGApQCgQEAQIUEgSmAgIcGkIgSWYgdHJ1
ZSwgdGhlIG5vdGVib29rIGluc3RhbmNlIHdpbGwgbm90IHJlZ2lzdGVyIHdpdGggdGhlIHBy
b3h5LgoKDQoFBAECFAUSBKYCAgYKDQoFBAECFAESBKYCBxYKDQoFBAECFAMSBKYCGRsKfAoE
BAECFRIEqwICFhpuIFRoZSBuYW1lIG9mIHRoZSBWUEMgdGhhdCB0aGlzIGluc3RhbmNlIGlz
IGluLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9nbG9iYWwvbmV0d29ya3Mv
e25ldHdvcmtfaWR9YAoKDQoFBAECFQUSBKsCAggKDQoFBAECFQESBKsCCRAKDQoFBAECFQMS
BKsCExUKkAEKBAQBAhYSBLACAhUagQEgVGhlIG5hbWUgb2YgdGhlIHN1Ym5ldCB0aGF0IHRo
aXMgaW5zdGFuY2UgaXMgaW4uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L3Jl
Z2lvbnMve3JlZ2lvbn0vc3VibmV0d29ya3Mve3N1Ym5ldHdvcmtfaWR9YAoKDQoFBAECFgUS
BLACAggKDQoFBAECFgESBLACCQ8KDQoFBAECFgMSBLACEhQKZwoEBAECFxIEtAICIhpZIExh
YmVscyB0byBhcHBseSB0byB0aGlzIGluc3RhbmNlLgogVGhlc2UgY2FuIGJlIGxhdGVyIG1v
ZGlmaWVkIGJ5IHRoZSBzZXRMYWJlbHMgbWV0aG9kLgoKDQoFBAECFwYSBLQCAhUKDQoFBAEC
FwESBLQCFhwKDQoFBAECFwMSBLQCHyEKOgoEBAECGBIEtwICJBosIEN1c3RvbSBtZXRhZGF0
YSB0byBhcHBseSB0byB0aGlzIGluc3RhbmNlLgoKDQoFBAECGAYSBLcCAhUKDQoFBAECGAES
BLcCFh4KDQoFBAECGAMSBLcCISMKaQoEBAECGRIEuwICQRpbIE9wdGlvbmFsLiBUaGUgdHlw
ZSBvZiB2TklDIHRvIGJlIHVzZWQgb24gdGhpcyBpbnRlcmZhY2UuIFRoaXMgbWF5IGJlIGdW
TklDIG9yCiBWaXJ0aW9OZXQuCgoNCgUEAQIZBhIEuwICCQoNCgUEAQIZARIEuwIKEgoNCgUE
AQIZAxIEuwIVFwoNCgUEAQIZCBIEuwIYQAoQCggEAQIZCJwIABIEuwIZPwruAQoEBAECGhIE
wQICWRrfASBPcHRpb25hbC4gVGhlIG9wdGlvbmFsIHJlc2VydmF0aW9uIGFmZmluaXR5LiBT
ZXR0aW5nIHRoaXMgZmllbGQgd2lsbCBhcHBseQogdGhlIHNwZWNpZmllZCBbWm9uYWwgQ29t
cHV0ZQogUmVzZXJ2YXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2Rv
Y3MvaW5zdGFuY2VzL3Jlc2VydmluZy16b25hbC1yZXNvdXJjZXMpCiB0byB0aGlzIG5vdGVi
b29rIGluc3RhbmNlLgoKDQoFBAECGgYSBMECAhUKDQoFBAECGgESBMECFioKDQoFBAECGgMS
BMECLS8KDQoFBAECGggSBMECMFgKEAoIBAECGgicCAASBMECMVcKjwEKBAQBAhsSBMUCAkQa
gAEgT3B0aW9uYWwuIEZsYWcgdG8gZW5hYmxlIGlwIGZvcndhcmRpbmcgb3Igbm90LCBkZWZh
dWx0IGZhbHNlL29mZi4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS92cGMvZG9jcy91c2lu
Zy1yb3V0ZXMjY2FuaXBmb3J3YXJkCgoNCgUEAQIbBRIExQICBgoNCgUEAQIbARIExQIHFQoN
CgUEAQIbAxIExQIYGgoNCgUEAQIbCBIExQIbQwoQCggEAQIbCJwIABIExQIcQgo0CgQEAQIc
EgTIAgJZGiYgT3V0cHV0IG9ubHkuIEluc3RhbmNlIGNyZWF0aW9uIHRpbWUuCgoNCgUEAQIc
BhIEyAICGwoNCgUEAQIcARIEyAIcJwoNCgUEAQIcAxIEyAIqLAoNCgUEAQIcCBIEyAItWAoQ
CggEAQIcCJwIABIEyAIuVwoyCgQEAQIdEgTLAgJZGiQgT3V0cHV0IG9ubHkuIEluc3RhbmNl
IHVwZGF0ZSB0aW1lLgoKDQoFBAECHQYSBMsCAhsKDQoFBAECHQESBMsCHCcKDQoFBAECHQMS
BMsCKiwKDQoFBAECHQgSBMsCLVgKEAoIBAECHQicCAASBMsCLldiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1beta1::Instance::ReservationAffinity ===
    # Fields for ReservationAffinity
    # Field: consume_reservation_type Type: 14 (.google.cloud.notebooks.v1beta1.ReservationAffinity.Type)
    # Field: key Type: 9 ()
    # Field: values Type: 9 ()

# Enum: ReservationAffinity::Type
our $ReservationAffinity_TYPE_UNSPECIFIED = 0;
our $ReservationAffinity_NO_RESERVATION = 1;
our $ReservationAffinity_ANY_RESERVATION = 2;
our $ReservationAffinity_SPECIFIC_RESERVATION = 3;

# === Message: Google::Cloud::Notebooks::V1beta1::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: vm_image Type: 11 (.google.cloud.notebooks.v1beta1.VmImage)
    # Field: container_image Type: 11 (.google.cloud.notebooks.v1beta1.ContainerImage)
    # Field: post_startup_script Type: 9 ()
    # Field: proxy_uri Type: 9 ()
    # Field: instance_owners Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: machine_type Type: 9 ()
    # Field: accelerator_config Type: 11 (.google.cloud.notebooks.v1beta1.Instance.AcceleratorConfig)
    # Field: state Type: 14 (.google.cloud.notebooks.v1beta1.Instance.State)
    # Field: install_gpu_driver Type: 8 ()
    # Field: custom_gpu_driver_path Type: 9 ()
    # Field: boot_disk_type Type: 14 (.google.cloud.notebooks.v1beta1.Instance.DiskType)
    # Field: boot_disk_size_gb Type: 3 ()
    # Field: data_disk_type Type: 14 (.google.cloud.notebooks.v1beta1.Instance.DiskType)
    # Field: data_disk_size_gb Type: 3 ()
    # Field: no_remove_data_disk Type: 8 ()
    # Field: disk_encryption Type: 14 (.google.cloud.notebooks.v1beta1.Instance.DiskEncryption)
    # Field: kms_key Type: 9 ()
    # Field: no_public_ip Type: 8 ()
    # Field: no_proxy_access Type: 8 ()
    # Field: network Type: 9 ()
    # Field: subnet Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.notebooks.v1beta1.Instance.LabelsEntry)
    # Field: metadata Type: 11 (.google.cloud.notebooks.v1beta1.Instance.MetadataEntry)
    # Field: nic_type Type: 14 (.google.cloud.notebooks.v1beta1.Instance.NicType)
    # Field: reservation_affinity Type: 11 (.google.cloud.notebooks.v1beta1.ReservationAffinity)
    # Field: can_ip_forward Type: 8 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Instance::AcceleratorType
our $Instance_ACCELERATOR_TYPE_UNSPECIFIED = 0;
our $Instance_NVIDIA_TESLA_K80 = 1;
our $Instance_NVIDIA_TESLA_P100 = 2;
our $Instance_NVIDIA_TESLA_V100 = 3;
our $Instance_NVIDIA_TESLA_P4 = 4;
our $Instance_NVIDIA_TESLA_T4 = 5;
our $Instance_NVIDIA_TESLA_T4_VWS = 8;
our $Instance_NVIDIA_TESLA_P100_VWS = 9;
our $Instance_NVIDIA_TESLA_P4_VWS = 10;
our $Instance_TPU_V2 = 6;
our $Instance_TPU_V3 = 7;

# Enum: Instance::State
our $Instance_STATE_UNSPECIFIED = 0;
our $Instance_STARTING = 1;
our $Instance_PROVISIONING = 2;
our $Instance_ACTIVE = 3;
our $Instance_STOPPING = 4;
our $Instance_STOPPED = 5;
our $Instance_DELETED = 6;
our $Instance_UPGRADING = 7;
our $Instance_INITIALIZING = 8;
our $Instance_REGISTERING = 9;
our $Instance_SUSPENDING = 10;
our $Instance_SUSPENDED = 11;

# Enum: Instance::DiskType
our $Instance_DISK_TYPE_UNSPECIFIED = 0;
our $Instance_PD_STANDARD = 1;
our $Instance_PD_SSD = 2;
our $Instance_PD_BALANCED = 3;

# Enum: Instance::DiskEncryption
our $Instance_DISK_ENCRYPTION_UNSPECIFIED = 0;
our $Instance_GMEK = 1;
our $Instance_CMEK = 2;

# Enum: Instance::NicType
our $Instance_UNSPECIFIED_NIC_TYPE = 0;
our $Instance_VIRTIO_NET = 1;
our $Instance_GVNIC = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1beta1::Instance - Compiled Protocol Buffers messages for google/cloud/notebooks/v1beta1/instance.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1beta1::Instance;

    my $msg = Google::Cloud::Notebooks::V1beta1::Instance::ReservationAffinity->new({
        consume_reservation_type => $consume_reservation_type,
        key => $key,
        values => $values,
    });

    # Read or update a field
    my $val = $msg->consume_reservation_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1beta1::Instance::ReservationAffinity->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1beta1/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1beta1::Instance::ReservationAffinity

Reservation Affinity for consuming Zonal reservation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->consume_reservation_type() >> / C<< $msg->consume_reservation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1beta1::ReservationAffinity::Type>)

Optional. Type of reservation to consume

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Optional. Corresponds to the label key of reservation resource.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Optional. Corresponds to the label values of reservation resource.

=back

=head3 Enum: ReservationAffinity::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<NO_RESERVATION> => C<1>

=item * C<ANY_RESERVATION> => C<2>

=item * C<SPECIFIC_RESERVATION> => C<3>

=back

=head2 Google::Cloud::Notebooks::V1beta1::Instance::Instance

The definition of a notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of this notebook instance. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=item * C<< $msg->vm_image() >> / C<< $msg->vm_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Environment::VmImage>)

Use a Compute Engine VM image to start the notebook instance.

=item * C<< $msg->container_image() >> / C<< $msg->container_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Environment::ContainerImage>)

Use a container image to start the notebook instance.

=item * C<< $msg->post_startup_script() >> / C<< $msg->post_startup_script($value) >>

Type: C<String>

Path to a Bash script that automatically runs after a notebook instance
fully boots up. The path must be a URL or
Cloud Storage path (`gs://path-to-file/file-name`).

=item * C<< $msg->proxy_uri() >> / C<< $msg->proxy_uri($value) >>

Type: C<String>

Output only. The proxy endpoint that is used to access the Jupyter notebook.

=item * C<< $msg->instance_owners() >> / C<< $msg->instance_owners($value) >>

Type: C<String>

Input only. The owner of this instance after creation. Format: `alias@example.com`

Currently supports one owner only. If not specified, all of the service
account users of your VM instance's service account can use
the instance.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

The service account on this instance, giving access to other Google
Cloud services.
You can use any service account within the same project, but you
must have the service account user permission to use the instance.

If not specified, the [Compute Engine default service
account](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account)
is used.

=item * C<< $msg->machine_type() >> / C<< $msg->machine_type($value) >>

Type: C<String>

Required. The [Compute Engine machine
type](https://cloud.google.com/compute/docs/machine-types) of this
instance.

=item * C<< $msg->accelerator_config() >> / C<< $msg->accelerator_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Instance::Instance::AcceleratorConfig>)

The hardware accelerator used on this instance. If you use
accelerators, make sure that your configuration has
[enough vCPUs and memory to support the `machine_type` you have
selected](https://cloud.google.com/compute/docs/gpus/#gpus-list).

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1beta1::Instance::State>)

Output only. The state of this instance.

=item * C<< $msg->install_gpu_driver() >> / C<< $msg->install_gpu_driver($value) >>

Type: C<Bool>

Whether the end user authorizes Google Cloud to install GPU driver
on this instance.
If this field is empty or set to false, the GPU driver won't be installed.
Only applicable to instances with GPUs.

=item * C<< $msg->custom_gpu_driver_path() >> / C<< $msg->custom_gpu_driver_path($value) >>

Type: C<String>

Specify a custom Cloud Storage path where the GPU driver is stored.
If not specified, we'll automatically choose from official GPU drivers.

=item * C<< $msg->boot_disk_type() >> / C<< $msg->boot_disk_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1beta1::Instance::DiskType>)

Input only. The type of the boot disk attached to this instance, defaults to
standard persistent disk (`PD_STANDARD`).

=item * C<< $msg->boot_disk_size_gb() >> / C<< $msg->boot_disk_size_gb($value) >>

Type: C<Int64>

Input only. The size of the boot disk in GB attached to this instance, up to a maximum
of 64000 GB (64 TB). The minimum recommended value is 100 GB. If not
specified, this defaults to 100.

=item * C<< $msg->data_disk_type() >> / C<< $msg->data_disk_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1beta1::Instance::DiskType>)

Input only. The type of the data disk attached to this instance, defaults to
standard persistent disk (`PD_STANDARD`).

=item * C<< $msg->data_disk_size_gb() >> / C<< $msg->data_disk_size_gb($value) >>

Type: C<Int64>

Input only. The size of the data disk in GB attached to this instance, up to a maximum
of 64000 GB (64 TB). You can choose the size of the data disk based on how
big your notebooks and data are. If not specified, this defaults to 100.

=item * C<< $msg->no_remove_data_disk() >> / C<< $msg->no_remove_data_disk($value) >>

Type: C<Bool>

Input only. If true, the data disk will not be auto deleted when deleting the instance.

=item * C<< $msg->disk_encryption() >> / C<< $msg->disk_encryption($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1beta1::Instance::DiskEncryption>)

Input only. Disk encryption method used on the boot and data disks, defaults to GMEK.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Input only. The KMS key used to encrypt the disks, only applicable if disk_encryption
is CMEK.
Format:
`projects/{project_id}/locations/{location}/keyRings/{key_ring_id}/cryptoKeys/{key_id}`

Learn more about [using your own encryption
keys](https://cloud.google.com/kms/docs/quickstart).

=item * C<< $msg->no_public_ip() >> / C<< $msg->no_public_ip($value) >>

Type: C<Bool>

If true, no public IP will be assigned to this instance.

=item * C<< $msg->no_proxy_access() >> / C<< $msg->no_proxy_access($value) >>

Type: C<Bool>

If true, the notebook instance will not register with the proxy.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

The name of the VPC that this instance is in.
Format:
`projects/{project_id}/global/networks/{network_id}`

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<String>

The name of the subnet that this instance is in.
Format:
`projects/{project_id}/regions/{region}/subnetworks/{subnetwork_id}`

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Instance::Instance::LabelsEntry>)

Labels to apply to this instance.
These can be later modified by the setLabels method.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Instance::Instance::MetadataEntry>)

Custom metadata to apply to this instance.

=item * C<< $msg->nic_type() >> / C<< $msg->nic_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1beta1::Instance::NicType>)

Optional. The type of vNIC to be used on this interface. This may be gVNIC or
VirtioNet.

=item * C<< $msg->reservation_affinity() >> / C<< $msg->reservation_affinity($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1beta1::Instance::ReservationAffinity>)

Optional. The optional reservation affinity. Setting this field will apply
the specified [Zonal Compute
Reservation](https://cloud.google.com/compute/docs/instances/reserving-zonal-resources)
to this notebook instance.

=item * C<< $msg->can_ip_forward() >> / C<< $msg->can_ip_forward($value) >>

Type: C<Bool>

Optional. Flag to enable ip forwarding or not, default false/off.
https://cloud.google.com/vpc/docs/using-routes#canipforward

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Instance creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Instance update time.

=back

=head3 Enum: Instance::AcceleratorType

=over 4

=item * C<ACCELERATOR_TYPE_UNSPECIFIED> => C<0>

=item * C<NVIDIA_TESLA_K80> => C<1>

=item * C<NVIDIA_TESLA_P100> => C<2>

=item * C<NVIDIA_TESLA_V100> => C<3>

=item * C<NVIDIA_TESLA_P4> => C<4>

=item * C<NVIDIA_TESLA_T4> => C<5>

=item * C<NVIDIA_TESLA_T4_VWS> => C<8>

=item * C<NVIDIA_TESLA_P100_VWS> => C<9>

=item * C<NVIDIA_TESLA_P4_VWS> => C<10>

=item * C<TPU_V2> => C<6>

=item * C<TPU_V3> => C<7>

=back

=head3 Enum: Instance::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTING> => C<1>

=item * C<PROVISIONING> => C<2>

=item * C<ACTIVE> => C<3>

=item * C<STOPPING> => C<4>

=item * C<STOPPED> => C<5>

=item * C<DELETED> => C<6>

=item * C<UPGRADING> => C<7>

=item * C<INITIALIZING> => C<8>

=item * C<REGISTERING> => C<9>

=item * C<SUSPENDING> => C<10>

=item * C<SUSPENDED> => C<11>

=back

=head3 Enum: Instance::DiskType

=over 4

=item * C<DISK_TYPE_UNSPECIFIED> => C<0>

=item * C<PD_STANDARD> => C<1>

=item * C<PD_SSD> => C<2>

=item * C<PD_BALANCED> => C<3>

=back

=head3 Enum: Instance::DiskEncryption

=over 4

=item * C<DISK_ENCRYPTION_UNSPECIFIED> => C<0>

=item * C<GMEK> => C<1>

=item * C<CMEK> => C<2>

=back

=head3 Enum: Instance::NicType

=over 4

=item * C<UNSPECIFIED_NIC_TYPE> => C<0>

=item * C<VIRTIO_NET> => C<1>

=item * C<GVNIC> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1beta1::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
