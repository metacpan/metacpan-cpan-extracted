package Google::Cloud::Databasecenter::V1beta::Maintenance;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Date };
    eval { require Google::Type::Dayofweek };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGF0YWJhc2VjZW50ZXIvdjFiZXRhL21haW50ZW5hbmNlLnByb3Rv
EiJnb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhZnb29n
bGUvdHlwZS9kYXRlLnByb3RvGhtnb29nbGUvdHlwZS9kYXlvZndlZWsucHJvdG8aG2dvb2ds
ZS90eXBlL3RpbWVvZmRheS5wcm90byLOAQobUmVzb3VyY2VNYWludGVuYW5jZVNjaGVkdWxl
EjoKCnN0YXJ0X3RpbWUYASABKAsyFi5nb29nbGUudHlwZS5UaW1lT2ZEYXlCA+BBAVIJc3Rh
cnRUaW1lEi0KA2RheRgCIAEoDjIWLmdvb2dsZS50eXBlLkRheU9mV2Vla0ID4EEBUgNkYXkS
RAoFcGhhc2UYAyABKA4yKS5nb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhLlBo
YXNlQgPgQQFSBXBoYXNlIrwBCh9SZXNvdXJjZU1haW50ZW5hbmNlRGVueVNjaGVkdWxlEjUK
CnN0YXJ0X2RhdGUYASABKAsyES5nb29nbGUudHlwZS5EYXRlQgPgQQFSCXN0YXJ0RGF0ZRIx
CghlbmRfZGF0ZRgCIAEoCzIRLmdvb2dsZS50eXBlLkRhdGVCA+BBAVIHZW5kRGF0ZRIvCgR0
aW1lGAMgASgLMhYuZ29vZ2xlLnR5cGUuVGltZU9mRGF5QgPgQQFSBHRpbWUikQEKE1VwY29t
aW5nTWFpbnRlbmFuY2USPgoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lIqUGCg9NYWludGVuYW5jZUluZm8SdwoU
bWFpbnRlbmFuY2Vfc2NoZWR1bGUYASABKAsyPy5nb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50
ZXIudjFiZXRhLlJlc291cmNlTWFpbnRlbmFuY2VTY2hlZHVsZUID4EEBUhNtYWludGVuYW5j
ZVNjaGVkdWxlEoYBChpkZW55X21haW50ZW5hbmNlX3NjaGVkdWxlcxgCIAMoCzJDLmdvb2ds
ZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGEuUmVzb3VyY2VNYWludGVuYW5jZURlbnlT
Y2hlZHVsZUID4EEBUhhkZW55TWFpbnRlbmFuY2VTY2hlZHVsZXMSNAoTbWFpbnRlbmFuY2Vf
dmVyc2lvbhgDIAEoCUID4EEDUhJtYWludGVuYW5jZVZlcnNpb24SVwocY3VycmVudF92ZXJz
aW9uX3JlbGVhc2VfZGF0ZRgEIAEoCzIRLmdvb2dsZS50eXBlLkRhdGVCA+BBA1IZY3VycmVu
dFZlcnNpb25SZWxlYXNlRGF0ZRJvChR1cGNvbWluZ19tYWludGVuYW5jZRgFIAEoCzI3Lmdv
b2dsZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGEuVXBjb21pbmdNYWludGVuYW5jZUID
4EEDUhN1cGNvbWluZ01haW50ZW5hbmNlEk8KBXN0YXRlGAYgASgOMjQuZ29vZ2xlLmNsb3Vk
LmRhdGFiYXNlY2VudGVyLnYxYmV0YS5NYWludGVuYW5jZVN0YXRlQgPgQQNSBXN0YXRlEngK
GHBvc3NpYmxlX2ZhaWx1cmVfcmVhc29ucxgHIAMoDjI5Lmdvb2dsZS5jbG91ZC5kYXRhYmFz
ZWNlbnRlci52MWJldGEuUG9zc2libGVGYWlsdXJlUmVhc29uQgPgQQNSFnBvc3NpYmxlRmFp
bHVyZVJlYXNvbnMSRQoccHJldmlvdXNfbWFpbnRlbmFuY2VfdmVyc2lvbhgIIAEoCUID4EED
UhpwcmV2aW91c01haW50ZW5hbmNlVmVyc2lvbipgCgVQaGFzZRIVChFQSEFTRV9VTlNQRUNJ
RklFRBAAEg8KC1BIQVNFX1dFRUsxEAESDwoLUEhBU0VfV0VFSzIQAhIPCgtQSEFTRV9XRUVL
NRADEg0KCVBIQVNFX0FOWRAEKrgBChBNYWludGVuYW5jZVN0YXRlEiEKHU1BSU5URU5BTkNF
X1NUQVRFX1VOU1BFQ0lGSUVEEAASHwobTUFJTlRFTkFOQ0VfU1RBVEVfU0NIRURVTEVEEAES
IQodTUFJTlRFTkFOQ0VfU1RBVEVfSU5fUFJPR1JFU1MQAhIfChtNQUlOVEVOQU5DRV9TVEFU
RV9DT01QTEVURUQQAxIcChhNQUlOVEVOQU5DRV9TVEFURV9GQUlMRUQQBCqpAQoVUG9zc2li
bGVGYWlsdXJlUmVhc29uEicKI1BPU1NJQkxFX0ZBSUxVUkVfUkVBU09OX1VOU1BFQ0lGSUVE
EAASMAosUE9TU0lCTEVfRkFJTFVSRV9SRUFTT05fREVOWV9QT0xJQ1lfQ09ORkxJQ1QQARI1
CjFQT1NTSUJMRV9GQUlMVVJFX1JFQVNPTl9JTlNUQU5DRV9JTl9TVE9QUEVEX1NUQVRFEAJC
/gEKJmNvbS5nb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhQhBNYWludGVuYW5j
ZVByb3RvUAFaTmNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWJhc2VjZW50ZXIvYXBpdjFiZXRh
L2RhdGFiYXNlY2VudGVycGI7ZGF0YWJhc2VjZW50ZXJwYqoCIkdvb2dsZS5DbG91ZC5EYXRh
YmFzZUNlbnRlci5WMUJldGHKAiJHb29nbGVcQ2xvdWRcRGF0YWJhc2VDZW50ZXJcVjFiZXRh
6gIlR29vZ2xlOjpDbG91ZDo6RGF0YWJhc2VDZW50ZXI6OlYxYmV0YUruMwoHEgUOALIBAQq8
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
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgAp
CgkKAgMBEgMTACkKCQoCAwISAxQAIAoJCgIDAxIDFQAlCgkKAgMEEgMWACUKCAoBCBIDGAA/
CgkKAgglEgMYAD8KCAoBCBIDGQBlCgkKAggLEgMZAGUKCAoBCBIDGgAiCgkKAggKEgMaACIK
CAoBCBIDGwAxCgkKAggIEgMbADEKCAoBCBIDHAA/CgkKAggBEgMcAD8KCAoBCBIDHQA/CgkK
AggpEgMdAD8KCAoBCBIDHgA+CgkKAggtEgMeAD4KoAIKAgUAEgQlADQBGpMCIFBoYXNlL1dl
ZWsgb2YgdGhlIG1haW50ZW5hbmNlIHdpbmRvdy4gVGhpcyBpcyB0byBjYXB0dXJlIG9yZGVy
IG9mCiBtYWludGVuYW5jZS4gRm9yIGV4YW1wbGUsIGZvciBDbG91ZCBTUUwgcmVzb3VyY2Vz
IC0KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcWwvZG9jcy9teXNxbC9tYWludGVuYW5j
ZS4KIFRoaXMgZW51bSBjYW4gYmUgZXh0ZW5kZWQgdG8gc3VwcG9ydCBEQiBDZW50ZXIgc3Bl
Y2lmaWMgcGhhc2VzIGZvcgogcmVjb21tZW5kYXRpb24gcGxhbiBnZW5lcmF0aW9uLgoKCgoD
BQABEgMlBQoKJAoEBQACABIDJwIYGhcgUGhhc2UgaXMgdW5zcGVjaWZpZWQuCgoMCgUFAAIA
ARIDJwITCgwKBQUAAgACEgMnFhcKFgoEBQACARIDKgISGgkgV2VlayAxLgoKDAoFBQACAQES
AyoCDQoMCgUFAAIBAhIDKhARChYKBAUAAgISAy0CEhoJIFdlZWsgMi4KCgwKBQUAAgIBEgMt
Ag0KDAoFBQACAgISAy0QEQoWCgQFAAIDEgMwAhIaCSBXZWVrIDUuCgoMCgUFAAIDARIDMAIN
CgwKBQUAAgMCEgMwEBEKGQoEBQACBBIDMwIQGgwgQW55IHBoYXNlLgoKDAoFBQACBAESAzMC
CwoMCgUFAAIEAhIDMw4PCikKAgUBEgQ3AEYBGh0gUmVzb3VyY2UgbWFpbnRlbmFuY2Ugc3Rh
dGUuCgoKCgMFAQESAzcFFQolCgQFAQIAEgM5AiQaGCBTdGF0dXMgaXMgdW5zcGVjaWZpZWQu
CgoMCgUFAQIAARIDOQIfCgwKBQUBAgACEgM5IiMKKAoEBQECARIDPAIiGhsgTWFpbnRlbmFu
Y2UgaXMgc2NoZWR1bGVkLgoKDAoFBQECAQESAzwCHQoMCgUFAQIBAhIDPCAhCioKBAUBAgIS
Az8CJBodIE1haW50ZW5hbmNlIGlzIGluIHByb2dyZXNzLgoKDAoFBQECAgESAz8CHwoMCgUF
AQICAhIDPyIjCigKBAUBAgMSA0ICIhobIE1haW50ZW5hbmNlIGlzIGNvbXBsZXRlZC4KCgwK
BQUBAgMBEgNCAh0KDAoFBQECAwISA0IgIQomCgQFAQIEEgNFAh8aGSBNYWludGVuYW5jZSBo
YXMgZmFpbGVkLgoKDAoFBQECBAESA0UCGgoMCgUFAQIEAhIDRR0eCooBCgIFAhIESgBUARp+
IFBvc3NpYmxlIHJlYXNvbnMgd2h5IHRoZSBtYWludGVuYW5jZSBpcyBub3QgY29tcGxldGVk
LgogU1RBVEVfRkFJTEVEIG1haW50ZW5hbmNlIHN0YXRlIG1heSBub3QgYWx3YXlzIGhhdmUg
YSBmYWlsdXJlIHJlYXNvbi4KCgoKAwUCARIDSgUaCi0KBAUCAgASA0wCKhogIEZhaWx1cmUg
cmVhc29uIGlzIHVuc3BlY2lmaWVkLgoKDAoFBQICAAESA0wCJQoMCgUFAgIAAhIDTCgpCn8K
BAUCAgESA1ACMxpyIE1haW50ZW5hbmNlIG1heSBub3QgYmUgY29tcGxldGVkIGJlY2F1c2Ug
dGhlcmUgaXMgYSBkZW55IHBvbGljeQogb3ZlcmxhcHBpbmcgd2l0aCB1cGNvbWluZyBtYWlu
dGVuYW5jZSBzY2hlZHVsZS4KCgwKBQUCAgEBEgNQAi4KDAoFBQICAQISA1AxMgpQCgQFAgIC
EgNTAjgaQyBNYWludGVuYW5jZSBtYXkgbm90IGJlIGNvbXBsZXRlZCBiZWNhdXNlIHRoZSBp
bnN0YW5jZSBpcyBzdG9wcGVkLgoKDAoFBQICAgESA1MCMwoMCgUFAgICAhIDUzY3CqYBCgIE
ABIEWABoARqZASBNYWludGVuYW5jZSB3aW5kb3cgZm9yIHRoZSBkYXRhYmFzZSByZXNvdXJj
ZS4gSXQgc3BlY2lmaWVzIHByZWZlcnJlZCB0aW1lCiBhbmQgZGF5IG9mIHRoZSB3ZWVrIGFu
ZCBwaGFzZSBpbiBzb21lIGNhc2VzLCB3aGVuIHRoZSBtYWludGVuYW5jZSBjYW4gc3RhcnQu
CgoKCgMEAAESA1gIIwphCgQEAAIAEgNbAlAaVCBPcHRpb25hbC4gUHJlZmVycmVkIHRpbWUg
dG8gc3RhcnQgdGhlIG1haW50ZW5hbmNlIG9wZXJhdGlvbiBvbiB0aGUKIHNwZWNpZmllZCBk
YXkuCgoMCgUEAAIABhIDWwIXCgwKBQQAAgABEgNbGCIKDAoFBAACAAMSA1slJgoMCgUEAAIA
CBIDWydPCg8KCAQAAgAInAgAEgNbKE4KXwoEBAACARIDXwJJGlIgT3B0aW9uYWwuIFByZWZl
cnJlZCBkYXkgb2YgdGhlIHdlZWsgZm9yIG1haW50ZW5hbmNlLCBlLmcuIE1PTkRBWSwgVFVF
U0RBWSwKIGV0Yy4KCgwKBQQAAgEGEgNfAhcKDAoFBAACAQESA18YGwoMCgUEAAIBAxIDXx4f
CgwKBQQAAgEIEgNfIEgKDwoIBAACAQicCAASA18hRwqDAwoEBAACAhIDZwI7GvUCIE9wdGlv
bmFsLiBQaGFzZSBvZiB0aGUgbWFpbnRlbmFuY2Ugd2luZG93LiBUaGlzIGlzIHRvIGNhcHR1
cmUgb3JkZXIgb2YKIG1haW50ZW5hbmNlLiBGb3IgZXhhbXBsZSwgZm9yIENsb3VkIFNRTCBy
ZXNvdXJjZXMsIHRoaXMgY2FuIGJlIHVzZWQgdG8KIGNhcHR1cmUgaWYgdGhlIG1haW50ZW5h
bmNlIHdpbmRvdyBpcyBpbiBXZWVrMSwgV2VlazIsIFdlZWs1LCBldGMuIE5vbgogcHJvZHVj
dGlvbiByZXNvdXJjZXMgYXJlIHVzdWFsbHkgcGFydCBvZiBlYXJseSBwaGFzZS4KIEZvciBt
b3JlIGRldGFpbHMsIHJlZmVyIHRvIENsb3VkIFNRTCByZXNvdXJjZXMgLQogaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL3NxbC9kb2NzL215c3FsL21haW50ZW5hbmNlCgoMCgUEAAICBhID
ZwIHCgwKBQQAAgIBEgNnCA0KDAoFBAACAgMSA2cQEQoMCgUEAAICCBIDZxI6Cg8KCAQAAgII
nAgAEgNnEzkKrgEKAgQBEgRtAHcBGqEBIERlbnkgbWFpbnRlbmFuY2UgcGVyaW9kIGZvciB0
aGUgZGF0YWJhc2UgcmVzb3VyY2UuIEl0IHNwZWNpZmllcyB0aGUgdGltZQogcmFuZ2UgZHVy
aW5nIHdoaWNoIHRoZSBtYWludGVuYW5jZSBjYW5ub3Qgc3RhcnQuIFRoaXMgaXMgY29uZmln
dXJlZCBieSB0aGUKIGN1c3RvbWVyLgoKCgoDBAEBEgNtCCcKRwoEBAECABIDbwJLGjogT3B0
aW9uYWwuIFRoZSBzdGFydCBkYXRlIG9mIHRoZSBkZW55IG1haW50ZW5hbmNlIHBlcmlvZC4K
CgwKBQQBAgAGEgNvAhIKDAoFBAECAAESA28THQoMCgUEAQIAAxIDbyAhCgwKBQQBAgAIEgNv
IkoKDwoIBAECAAicCAASA28jSQouCgQEAQIBEgNyAkkaISBPcHRpb25hbC4gRGVueSBwZXJp
b2QgZW5kIGRhdGUuCgoMCgUEAQIBBhIDcgISCgwKBQQBAgEBEgNyExsKDAoFBAECAQMSA3Ie
HwoMCgUEAQIBCBIDciBICg8KCAQBAgEInAgAEgNyIUcKZQoEBAECAhIDdgJKGlggT3B0aW9u
YWwuIFRpbWUgaW4gVVRDIHdoZW4gdGhlIGRlbnkgcGVyaW9kIHN0YXJ0cyBvbiBzdGFydF9k
YXRlIGFuZCBlbmRzIG9uCiBlbmRfZGF0ZS4KCgwKBQQBAgIGEgN2AhcKDAoFBAECAgESA3YY
HAoMCgUEAQICAxIDdh8gCgwKBQQBAgIIEgN2IUkKDwoIBAECAgicCAASA3YiSApFCgIEAhIF
egCFAQEaOCBVcGNvbWluZyBtYWludGVuYW5jZSB3aW5kb3cgZm9yIHRoZSBkYXRhYmFzZSBy
ZXNvdXJjZS4KCgoKAwQCARIDeggbCpEBCgQEAgIAEgR+An8yGoIBIE91dHB1dCBvbmx5LiBT
dGFydCB0aW1lIG9mIHRoZSB1cGNvbWluZyBtYWludGVuYW5jZS4KIFN0YXJ0IHRpbWUgaXMg
YWx3YXlzIHBvcHVsYXRlZCB3aGVuIGFuIHVwY29taW5nIG1haW50ZW5hbmNlIGlzCiBzY2hl
ZHVsZWQuCgoMCgUEAgIABhIDfgIbCgwKBQQCAgABEgN+HCYKDAoFBAICAAMSA34pKgoMCgUE
AgIACBIDfwYxCg8KCAQCAgAInAgAEgN/BzAKkgEKBAQCAgESBoMBAoQBMhqBASBPdXRwdXQg
b25seS4gRW5kIHRpbWUgb2YgdGhlIHVwY29taW5nIG1haW50ZW5hbmNlLiBUaGlzIGlzIG9u
bHkgcG9wdWxhdGVkCiBmb3IgYW4gZW5naW5lLCBpZiBlbmQgdGltZSBpcyBwdWJsaWMgZm9y
IHRoZSBlbmdpbmUuCgoNCgUEAgIBBhIEgwECGwoNCgUEAgIBARIEgwEcJAoNCgUEAgIBAxIE
gwEnKAoNCgUEAgIBCBIEhAEGMQoQCggEAgIBCJwIABIEhAEHMApYCgIEAxIGiAEAsgEBGkog
TWFpbnRlbmFuY2VJbmZvIHRvIGNhcHR1cmUgdGhlIG1haW50ZW5hbmNlIGRldGFpbHMgb2Yg
ZGF0YWJhc2UgcmVzb3VyY2UuCgoLCgMEAwESBIgBCBcKSQoEBAMCABIGigECiwEvGjkgT3B0
aW9uYWwuIE1haW50ZW5hbmNlIHdpbmRvdyBmb3IgdGhlIGRhdGFiYXNlIHJlc291cmNlLgoK
DQoFBAMCAAYSBIoBAh0KDQoFBAMCAAESBIoBHjIKDQoFBAMCAAMSBIoBNTYKDQoFBAMCAAgS
BIsBBi4KEAoIBAMCAAicCAASBIsBBy0KVgoEBAMCARIGjgECjwEvGkYgT3B0aW9uYWwuIExp
c3Qgb2YgRGVueSBtYWludGVuYW5jZSBwZXJpb2QgZm9yIHRoZSBkYXRhYmFzZSByZXNvdXJj
ZS4KCg0KBQQDAgEEEgSOAQIKCg0KBQQDAgEGEgSOAQsqCg0KBQQDAgEBEgSOAStFCg0KBQQD
AgEDEgSOAUhJCg0KBQQDAgEIEgSPAQYuChAKCAQDAgEInAgAEgSPAQctCnsKBAQDAgISBJMB
Ak0abSBPdXRwdXQgb25seS4gQ3VycmVudCBNYWludGVuYW5jZSB2ZXJzaW9uIG9mIHRoZSBk
YXRhYmFzZSByZXNvdXJjZS4gRXhhbXBsZToKICJNWVNRTF84XzBfNDEuUjIwMjUwNTMxLjAx
XzE1IgoKDQoFBAMCAgUSBJMBAggKDQoFBAMCAgESBJMBCRwKDQoFBAMCAgMSBJMBHyAKDQoF
BAMCAggSBJMBIUwKEAoIBAMCAgicCAASBJMBIksKUgoEBAMCAxIGlgEClwEyGkIgT3V0cHV0
IG9ubHkuIFRoZSBkYXRlIHdoZW4gdGhlIG1haW50ZW5hbmNlIHZlcnNpb24gd2FzIHJlbGVh
c2VkLgoKDQoFBAMCAwYSBJYBAhIKDQoFBAMCAwESBJYBEy8KDQoFBAMCAwMSBJYBMjMKDQoF
BAMCAwgSBJcBBjEKEAoIBAMCAwicCAASBJcBBzAKxwMKBAQDAgQSBp8BAqABMhq2AyBPdXRw
dXQgb25seS4gVXBjb21pbmcgbWFpbnRlbmFuY2Ugd2luZG93IGZvciB0aGUgZGF0YWJhc2Ug
cmVzb3VyY2UuIFRoaXMgaXMKIG9ubHkgcG9wdWxhdGVkIGZvciBhbiBlbmdpbmUsIGlmIHVw
Y29taW5nIG1haW50ZW5hbmNlIGlzIHNjaGVkdWxlZCBmb3IgdGhlCiByZXNvdXJjZS4gVGhp
cyBzY2hlZHVsZSBpcyBnZW5lcmF0ZWQgcGVyIGVuZ2luZSBhbmQgZW5naW5lIHZlcnNpb24s
IGFuZAogdGhlcmUgaXMgb25seSBvbmUgdXBjb21pbmcgbWFpbnRlbmFuY2Ugd2luZG93IGF0
IGFueSBnaXZlbiB0aW1lLiBJbiBjYXNlIG9mCiB1cGNvbWluZyBtYWludGVuYW5jZSwgdGhl
IG1haW50ZW5hbmNlX3N0YXRlIHdpbGwgYmUgc2V0IHRvIFNDSEVEVUxFRCBmaXJzdCwKIGFu
ZCB0aGVuIElOX1BST0dSRVNTIHdoZW4gdGhlIG1haW50ZW5hbmNlIHdpbmRvdyBzdGFydHMu
CgoNCgUEAwIEBhIEnwECFQoNCgUEAwIEARIEnwEWKgoNCgUEAwIEAxIEnwEtLgoNCgUEAwIE
CBIEoAEGMQoQCggEAwIECJwIABIEoAEHMApyCgQEAwIFEgSkAQJJGmQgT3V0cHV0IG9ubHku
IFJlc291cmNlIG1haW50ZW5hbmNlIHN0YXRlLiBUaGlzIGlzIHRvIGNhcHR1cmUgdGhlIGN1
cnJlbnQKIHN0YXRlIG9mIHRoZSBtYWludGVuYW5jZS4KCg0KBQQDAgUGEgSkAQISCg0KBQQD
AgUBEgSkARMYCg0KBQQDAgUDEgSkARscCg0KBQQDAgUIEgSkAR1IChAKCAQDAgUInAgAEgSk
AR5HCqMCCgQEAwIGEgaqAQKrATIakgIgT3V0cHV0IG9ubHkuIExpc3Qgb2YgcG9zc2libGUg
cmVhc29ucyB3aHkgdGhlIG1haW50ZW5hbmNlIGlzIG5vdCBjb21wbGV0ZWQuCiBUaGlzIGlz
IGFuIG9wdGlvbmFsIGZpZWxkIGFuZCBpcyBvbmx5IHBvcHVsYXRlZCBpZiB0aGVyZSBhcmUg
YW55CiByZWFzb25zIGZvciBmYWlsdXJlcyByZWNvcmRlZCBmb3IgdGhlIG1haW50ZW5hbmNl
IGJ5IERCIENlbnRlci4KIEZBSUxVUkUgbWFpbnRlbmFuY2Ugc3RhdHVzIG1heSBub3QgYWx3
YXlzIGhhdmUgYSBmYWlsdXJlIHJlYXNvbi4KCg0KBQQDAgYEEgSqAQIKCg0KBQQDAgYGEgSq
AQsgCg0KBQQDAgYBEgSqASE5Cg0KBQQDAgYDEgSqATw9Cg0KBQQDAgYIEgSrAQYxChAKCAQD
AgYInAgAEgSrAQcwCtgBCgQEAwIHEgawAQKxATIaxwEgT3V0cHV0IG9ubHkuIFByZXZpb3Vz
IG1haW50ZW5hbmNlIHZlcnNpb24gb2YgdGhlIGRhdGFiYXNlIHJlc291cmNlLgogRXhhbXBs
ZTogIk1ZU1FMXzhfMF80MS5SMjAyNTA1MzEuMDFfMTUiLiBUaGlzIGlzIGF2YWlsYWJsZSBv
bmNlIGEgbWlub3IKIHZlcnNpb24gbWFpbnRlbmFuY2UgaXMgY29tcGxldGUgb24gYSBkYXRh
YmFzZSByZXNvdXJjZS4KCg0KBQQDAgcFEgSwAQIICg0KBQQDAgcBEgSwAQklCg0KBQQDAgcD
EgSwASgpCg0KBQQDAgcIEgSxAQYxChAKCAQDAgcInAgAEgSxAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule ===
    # Fields for ResourceMaintenanceSchedule
    # Field: start_time Type: 11 (.google.type.TimeOfDay)
    # Field: day Type: 14 (.google.type.DayOfWeek)
    # Field: phase Type: 14 (.google.cloud.databasecenter.v1beta.Phase)

# === Message: Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceDenySchedule ===
    # Fields for ResourceMaintenanceDenySchedule
    # Field: start_date Type: 11 (.google.type.Date)
    # Field: end_date Type: 11 (.google.type.Date)
    # Field: time Type: 11 (.google.type.TimeOfDay)

# === Message: Google::Cloud::Databasecenter::V1beta::Maintenance::UpcomingMaintenance ===
    # Fields for UpcomingMaintenance
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Databasecenter::V1beta::Maintenance::MaintenanceInfo ===
    # Fields for MaintenanceInfo
    # Field: maintenance_schedule Type: 11 (.google.cloud.databasecenter.v1beta.ResourceMaintenanceSchedule)
    # Field: deny_maintenance_schedules Type: 11 (.google.cloud.databasecenter.v1beta.ResourceMaintenanceDenySchedule)
    # Field: maintenance_version Type: 9 ()
    # Field: current_version_release_date Type: 11 (.google.type.Date)
    # Field: upcoming_maintenance Type: 11 (.google.cloud.databasecenter.v1beta.UpcomingMaintenance)
    # Field: state Type: 14 (.google.cloud.databasecenter.v1beta.MaintenanceState)
    # Field: possible_failure_reasons Type: 14 (.google.cloud.databasecenter.v1beta.PossibleFailureReason)
    # Field: previous_maintenance_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Maintenance - Compiled Protocol Buffers messages for google/cloud/databasecenter/v1beta/maintenance.proto

=head1 SYNOPSIS

    use Google::Cloud::Databasecenter::V1beta::Maintenance;

    my $msg = Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule->new({
        start_time => $start_time,
        day => $day,
        phase => $phase,
    });

    # Read or update a field
    my $val = $msg->start_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/databasecenter/v1beta/maintenance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule

Maintenance window for the database resource. It specifies preferred time
and day of the week and phase in some cases, when the maintenance can start.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

Optional. Preferred time to start the maintenance operation on the
specified day.

=item * C<< $msg->day() >> / C<< $msg->day($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Optional. Preferred day of the week for maintenance, e.g. MONDAY, TUESDAY,
etc.

=item * C<< $msg->phase() >> / C<< $msg->phase($value) >>

Type: C<Enum> (L<Google::Cloud::Databasecenter::V1beta::Phase>)

Optional. Phase of the maintenance window. This is to capture order of
maintenance. For example, for Cloud SQL resources, this can be used to
capture if the maintenance window is in Week1, Week2, Week5, etc. Non
production resources are usually part of early phase.
For more details, refer to Cloud SQL resources -
https://cloud.google.com/sql/docs/mysql/maintenance

=back

=head2 Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceDenySchedule

Deny maintenance period for the database resource. It specifies the time
range during which the maintenance cannot start. This is configured by the
customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_date() >> / C<< $msg->start_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Optional. The start date of the deny maintenance period.

=item * C<< $msg->end_date() >> / C<< $msg->end_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Optional. Deny period end date.

=item * C<< $msg->time() >> / C<< $msg->time($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

Optional. Time in UTC when the deny period starts on start_date and ends on
end_date.

=back

=head2 Google::Cloud::Databasecenter::V1beta::Maintenance::UpcomingMaintenance

Upcoming maintenance window for the database resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Start time of the upcoming maintenance.
Start time is always populated when an upcoming maintenance is
scheduled.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. End time of the upcoming maintenance. This is only populated
for an engine, if end time is public for the engine.

=back

=head2 Google::Cloud::Databasecenter::V1beta::Maintenance::MaintenanceInfo

MaintenanceInfo to capture the maintenance details of database resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->maintenance_schedule() >> / C<< $msg->maintenance_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule>)

Optional. Maintenance window for the database resource.

=item * C<< $msg->deny_maintenance_schedules() >> / C<< $msg->deny_maintenance_schedules($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceDenySchedule>)

Optional. List of Deny maintenance period for the database resource.

=item * C<< $msg->maintenance_version() >> / C<< $msg->maintenance_version($value) >>

Type: C<String>

Output only. Current Maintenance version of the database resource. Example:
"MYSQL_8_0_41.R20250531.01_15"

=item * C<< $msg->current_version_release_date() >> / C<< $msg->current_version_release_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Output only. The date when the maintenance version was released.

=item * C<< $msg->upcoming_maintenance() >> / C<< $msg->upcoming_maintenance($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::Maintenance::UpcomingMaintenance>)

Output only. Upcoming maintenance window for the database resource. This is
only populated for an engine, if upcoming maintenance is scheduled for the
resource. This schedule is generated per engine and engine version, and
there is only one upcoming maintenance window at any given time. In case of
upcoming maintenance, the maintenance_state will be set to SCHEDULED first,
and then IN_PROGRESS when the maintenance window starts.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Databasecenter::V1beta::MaintenanceState>)

Output only. Resource maintenance state. This is to capture the current
state of the maintenance.

=item * C<< $msg->possible_failure_reasons() >> / C<< $msg->possible_failure_reasons($value) >>

Type: C<Enum> (L<Google::Cloud::Databasecenter::V1beta::PossibleFailureReason>)

Output only. List of possible reasons why the maintenance is not completed.
This is an optional field and is only populated if there are any
reasons for failures recorded for the maintenance by DB Center.
FAILURE maintenance status may not always have a failure reason.

=item * C<< $msg->previous_maintenance_version() >> / C<< $msg->previous_maintenance_version($value) >>

Type: C<String>

Output only. Previous maintenance version of the database resource.
Example: "MYSQL_8_0_41.R20250531.01_15". This is available once a minor
version maintenance is complete on a database resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Databasecenter::V1beta::Maintenance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
