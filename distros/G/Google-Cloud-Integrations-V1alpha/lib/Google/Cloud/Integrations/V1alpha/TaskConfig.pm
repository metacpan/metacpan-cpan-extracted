package Google::Cloud::Integrations::V1alpha::TaskConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Integrations::V1alpha::Coordinate };
    eval { require Google::Cloud::Integrations::V1alpha::EventParameter };
    eval { require Google::Cloud::Integrations::V1alpha::JsonValidation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvdGFza19jb25maWcucHJvdG8S
IWdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoyZ29vZ2xlL2Nsb3VkL2ludGVncmF0aW9ucy92MWFscGhhL2Nvb3Jk
aW5hdGUucHJvdG8aN2dvb2dsZS9jbG91ZC9pbnRlZ3JhdGlvbnMvdjFhbHBoYS9ldmVudF9w
YXJhbWV0ZXIucHJvdG8aN2dvb2dsZS9jbG91ZC9pbnRlZ3JhdGlvbnMvdjFhbHBoYS9qc29u
X3ZhbGlkYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i/g4K
ClRhc2tDb25maWcSFwoEdGFzaxgBIAEoCUID4EEBUgR0YXNrEhwKB3Rhc2tfaWQYAiABKAlC
A+BBAlIGdGFza0lkEmIKCnBhcmFtZXRlcnMYAyADKAsyPS5nb29nbGUuY2xvdWQuaW50ZWdy
YXRpb25zLnYxYWxwaGEuVGFza0NvbmZpZy5QYXJhbWV0ZXJzRW50cnlCA+BBAVIKcGFyYW1l
dGVycxJcCg5mYWlsdXJlX3BvbGljeRgEIAEoCzIwLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlv
bnMudjFhbHBoYS5GYWlsdXJlUG9saWN5QgPgQQFSDWZhaWx1cmVQb2xpY3kSfAofc3luY2hy
b25vdXNfY2FsbF9mYWlsdXJlX3BvbGljeRgFIAEoCzIwLmdvb2dsZS5jbG91ZC5pbnRlZ3Jh
dGlvbnMudjFhbHBoYS5GYWlsdXJlUG9saWN5QgPgQQFSHHN5bmNocm9ub3VzQ2FsbEZhaWx1
cmVQb2xpY3kShAEKHGNvbmRpdGlvbmFsX2ZhaWx1cmVfcG9saWNpZXMYEiABKAsyPS5nb29n
bGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuQ29uZGl0aW9uYWxGYWlsdXJlUG9saWNp
ZXNCA+BBAVIaY29uZGl0aW9uYWxGYWlsdXJlUG9saWNpZXMSTwoKbmV4dF90YXNrcxgGIAMo
CzIrLmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5OZXh0VGFza0ID4EEBUglu
ZXh0VGFza3MSigEKG25leHRfdGFza3NfZXhlY3V0aW9uX3BvbGljeRgHIAEoDjJGLmdvb2ds
ZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYS5UYXNrQ29uZmlnLk5leHRUYXNrc0V4ZWN1
dGlvblBvbGljeUID4EEBUhhuZXh0VGFza3NFeGVjdXRpb25Qb2xpY3kSgAEKF3Rhc2tfZXhl
Y3V0aW9uX3N0cmF0ZWd5GAggASgOMkMuZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFs
cGhhLlRhc2tDb25maWcuVGFza0V4ZWN1dGlvblN0cmF0ZWd5QgPgQQFSFXRhc2tFeGVjdXRp
b25TdHJhdGVneRImCgxkaXNwbGF5X25hbWUYCSABKAlCA+BBAVILZGlzcGxheU5hbWUSXAoO
c3VjY2Vzc19wb2xpY3kYCiABKAsyMC5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxw
aGEuU3VjY2Vzc1BvbGljeUID4EEBUg1zdWNjZXNzUG9saWN5EnIKFmpzb25fdmFsaWRhdGlv
bl9vcHRpb24YCyABKA4yNy5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuSnNv
blZhbGlkYXRpb25PcHRpb25CA+BBAVIUanNvblZhbGlkYXRpb25PcHRpb24SJQoLZGVzY3Jp
cHRpb24YDCABKAlCA+BBAVILZGVzY3JpcHRpb24SKAoNdGFza190ZW1wbGF0ZRgNIAEoCUID
4EEBUgx0YXNrVGVtcGxhdGUSLQoQZXJyb3JfY2F0Y2hlcl9pZBgRIAEoCUID4EEBUg5lcnJv
ckNhdGNoZXJJZBJxChJleHRlcm5hbF90YXNrX3R5cGUYDyABKA4yPi5nb29nbGUuY2xvdWQu
aW50ZWdyYXRpb25zLnYxYWxwaGEuVGFza0NvbmZpZy5FeHRlcm5hbFRhc2tUeXBlQgPgQQFS
EGV4dGVybmFsVGFza1R5cGUSTgoIcG9zaXRpb24YECABKAsyLS5nb29nbGUuY2xvdWQuaW50
ZWdyYXRpb25zLnYxYWxwaGEuQ29vcmRpbmF0ZUID4EEBUghwb3NpdGlvbhpwCg9QYXJhbWV0
ZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSRwoFdmFsdWUYAiABKAsyMS5nb29nbGUuY2xv
dWQuaW50ZWdyYXRpb25zLnYxYWxwaGEuRXZlbnRQYXJhbWV0ZXJSBXZhbHVlOgI4ASJvChhO
ZXh0VGFza3NFeGVjdXRpb25Qb2xpY3kSKwonTkVYVF9UQVNLU19FWEVDVVRJT05fUE9MSUNZ
X1VOU1BFQ0lGSUVEEAASEQoNUlVOX0FMTF9NQVRDSBABEhMKD1JVTl9GSVJTVF9NQVRDSBAC
IpcBChVUYXNrRXhlY3V0aW9uU3RyYXRlZ3kSJwojVEFTS19FWEVDVVRJT05fU1RSQVRFR1lf
VU5TUEVDSUZJRUQQABIUChBXSEVOX0FMTF9TVUNDRUVEEAESFAoQV0hFTl9BTllfU1VDQ0VF
RBACEikKJVdIRU5fQUxMX1RBU0tTX0FORF9DT05ESVRJT05TX1NVQ0NFRUQQAyJXChBFeHRl
cm5hbFRhc2tUeXBlEiIKHkVYVEVSTkFMX1RBU0tfVFlQRV9VTlNQRUNJRklFRBAAEg8KC05P
Uk1BTF9UQVNLEAESDgoKRVJST1JfVEFTSxACIrYBCg1TdWNjZXNzUG9saWN5ElwKC2ZpbmFs
X3N0YXRlGAEgASgOMjsuZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLlN1Y2Nl
c3NQb2xpY3kuRmluYWxTdGF0ZVIKZmluYWxTdGF0ZSJHCgpGaW5hbFN0YXRlEhsKF0ZJTkFM
X1NUQVRFX1VOU1BFQ0lGSUVEEAASDQoJU1VDQ0VFREVEEAESDQoJU1VTUEVOREVEEAIisAMK
DUZhaWx1cmVQb2xpY3kSZQoOcmV0cnlfc3RyYXRlZ3kYASABKA4yPi5nb29nbGUuY2xvdWQu
aW50ZWdyYXRpb25zLnYxYWxwaGEuRmFpbHVyZVBvbGljeS5SZXRyeVN0cmF0ZWd5Ug1yZXRy
eVN0cmF0ZWd5Eh8KC21heF9yZXRyaWVzGAIgASgFUgptYXhSZXRyaWVzEj8KDWludGVydmFs
X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxpbnRlcnZhbFRpbWUS
HAoJY29uZGl0aW9uGAQgASgJUgljb25kaXRpb24itwEKDVJldHJ5U3RyYXRlZ3kSHgoaUkVU
UllfU1RSQVRFR1lfVU5TUEVDSUZJRUQQABIKCgZJR05PUkUQARIICgROT05FEAISCQoFRkFU
QUwQAxISCg5GSVhFRF9JTlRFUlZBTBAEEhIKDkxJTkVBUl9CQUNLT0ZGEAUSFwoTRVhQT05F
TlRJQUxfQkFDS09GRhAGEiQKIFJFU1RBUlRfSU5URUdSQVRJT05fV0lUSF9CQUNLT0ZGEAci
rAEKCE5leHRUYXNrEiQKDnRhc2tfY29uZmlnX2lkGAEgASgJUgx0YXNrQ29uZmlnSWQSFwoH
dGFza19pZBgCIAEoCVIGdGFza0lkEhwKCWNvbmRpdGlvbhgDIAEoCVIJY29uZGl0aW9uEiEK
DGRpc3BsYXlfbmFtZRgEIAEoCVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YBSABKAlS
C2Rlc2NyaXB0aW9uIuEBChpDb25kaXRpb25hbEZhaWx1cmVQb2xpY2llcxJbChBmYWlsdXJl
X3BvbGljaWVzGAEgAygLMjAuZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLkZh
aWx1cmVQb2xpY3lSD2ZhaWx1cmVQb2xpY2llcxJmChZkZWZhdWx0X2ZhaWx1cmVfcG9saWN5
GAIgASgLMjAuZ29vZ2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhLkZhaWx1cmVQb2xp
Y3lSFGRlZmF1bHRGYWlsdXJlUG9saWN5QqkBCiVjb20uZ29vZ2xlLmNsb3VkLmludGVncmF0
aW9ucy52MWFscGhhQg9UYXNrQ29uZmlnUHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNvbS9nby9p
bnRlZ3JhdGlvbnMvYXBpdjFhbHBoYS9pbnRlZ3JhdGlvbnNwYjtpbnRlZ3JhdGlvbnNwYqoC
IUdvb2dsZS5DbG91ZC5JbnRlZ3JhdGlvbnMuVjFBbHBoYUrzVwoHEgUOAJgCAQq8BAoBDBID
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
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkKAgMB
EgMTADwKCQoCAwISAxQAQQoJCgIDAxIDFQBBCgkKAgMEEgMWACkKCAoBCBIDGAA+CgkKAggl
EgMYAD4KCAoBCBIDGQBgCgkKAggLEgMZAGAKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBID
GwAwCgkKAggIEgMbADAKCAoBCBIDHAA+CgkKAggBEgMcAD4KjwEKAgQAEgUgAJsBARqBASBU
aGUgdGFzayBjb25maWd1cmF0aW9uIGRldGFpbHMuIFRoaXMgaXMgbm90IHRoZSBpbXBsZW1l
bnRhdGlvbiBvZiBUYXNrLgogVGhlcmUgbWlnaHQgYmUgbXVsdGlwbGUgVGFza0NvbmZpZ3Mg
Zm9yIHRoZSBzYW1lIFRhc2suCgoKCgMEAAESAyAIEgpFCgQEAAQAEgQiAisDGjcgVmFyaW91
cyBwb2xpY2llcyBmb3IgZXhlY3V0aW5nIHRoZSBuZXh0IHNldCBvZiB0YXNrcy4KCgwKBQQA
BAABEgMiBx8KGQoGBAAEAAIAEgMkBDAaCiBEZWZhdWx0LgoKDgoHBAAEAAIAARIDJAQrCg4K
BwQABAACAAISAyQuLwpPCgYEAAQAAgESAycEFhpAIEV4ZWN1dGUgYWxsIHRoZSB0YXNrcyB0
aGF0IHNhdGlzZnkgdGhlaXIgYXNzb2NpYXRlZCBjb25kaXRpb24uCgoOCgcEAAQAAgEBEgMn
BBEKDgoHBAAEAAIBAhIDJxQVClAKBgQABAACAhIDKgQYGkEgRXhlY3V0ZSB0aGUgZmlyc3Qg
dGFzayB0aGF0IHNhdGlzZmllcyB0aGUgYXNzb2NpYXRlZCBjb25kaXRpb24uCgoOCgcEAAQA
AgIBEgMqBBMKDgoHBAAEAAICAhIDKhYXCkcKBAQABAESBC4CQAMaOSBWYXJpb3VzIHBvbGlj
aWVzIHRvIHRyaWdnZXIgdGhlIGV4ZWN1dGlvbiBvZiB0aGlzIHRhc2suCgoMCgUEAAQBARID
LgccCmgKBgQABAECABIDMQQsGlkgRGVmYXVsdC4gSWYgdGhlIHN0cmF0ZWd5IGlzIG5vdCBz
ZXQgZXhwbGljaXRseSwgaXQgd2lsbCBkZWZhdWx0IHRvCiBgV0hFTl9BTExfU1VDQ0VFRGAu
CgoOCgcEAAQBAgABEgMxBCcKDgoHBAAEAQIAAhIDMSorCtIBCgYEAAQBAgESAzYEGRrCASBX
YWl0IHVudGlsIGFsbCBvZiBpdHMgcHJldmlvdXMgdGFza3MgZmluaXNoZWQgZXhlY3V0aW9u
LCB0aGVuIHZlcmlmeSBhdAogbGVhc3Qgb25lIG9mIHRoZSBlZGdlIGNvbmRpdGlvbnMgaXMg
bWV0LCBhbmQgZXhlY3V0ZSBpZiBwb3NzaWJsZS4gVGhpcwogc2hvdWxkIGJlIGNvbnNpZGVy
ZWQgYXMgV0hFTl9BTExfVEFTS1NfU1VDQ0VFRC4KCg4KBwQABAECAQESAzYEFAoOCgcEAAQB
AgECEgM2FxgKzgEKBgQABAECAhIDOwQZGr4BIFN0YXJ0IGV4ZWN1dGlvbiBhcyBsb25nIGFz
IGFueSBvZiBpdHMgcHJldmlvdXMgdGFza3MgZmluaXNoZWQgZXhlY3V0aW9uCiBhbmQgdGhl
IGNvcnJlc3BvbmRpbmcgZWRnZSBjb25kaXRpb24gaXMgbWV0IChzaW5jZSB3ZSB3aWxsIGV4
ZWN1dGUgaWYKIG9ubHkgdGhhdCBzdWNjZWVkaW5nIGVkZ2UgY29uZGl0aW9uIGlzIG1ldCku
CgoOCgcEAAQBAgIBEgM7BBQKDgoHBAAEAQICAhIDOxcYCpABCgYEAAQBAgMSAz8ELhqAASBX
YWl0IHVudGlsIGFsbCBvZiBpdHMgcHJldmlvdXMgdGFza3MgZmluaXNoZWQgZXhlY3V0aW9u
LCB0aGVuIHZlcmlmeQogdGhlIGFsbCBlZGdlIGNvbmRpdGlvbnMgYXJlIG1ldCBhbmQgZXhl
Y3V0ZSBpZiBwb3NzaWJsZS4KCg4KBwQABAECAwESAz8EKQoOCgcEAAQBAgMCEgM/LC0KQgoE
BAAEAhIEQwJMAxo0IERlZmluZXMgdGhlIHR5cGUgb2YgdGhlIHRhc2sgZm9yIGV4dGVybmFs
IGN1c3RvbWVyCgoMCgUEAAQCARIDQwcXCkMKBgQABAICABIDRQQnGjQgRGVmYXVsdCB2YWx1
ZS4gRXh0ZXJuYWwgdGFzayB0eXBlIGlzIG5vdCBzcGVjaWZpZWQKCg4KBwQABAICAAESA0UE
IgoOCgcEAAQCAgACEgNFJSYKNwoGBAAEAgIBEgNIBBQaKCBUYXNrcyBiZWxvbmdzIHRvIHRo
ZSBub3JtYWwgdGFzayBmbG93cwoKDgoHBAAEAgIBARIDSAQPCg4KBwQABAICAQISA0gSEwo7
CgYEAAQCAgISA0sEExosIFRhc2sgYmVsb25ncyB0byB0aGUgZXJyb3IgY2F0Y2ggdGFzayBm
bG93cwoKDgoHBAAEAgICARIDSwQOCg4KBwQABAICAgISA0sREgovCgQEAAIAEgNPAjsaIiBP
cHRpb25hbC4gVGhlIG5hbWUgZm9yIHRoZSB0YXNrLgoKDAoFBAACAAUSA08CCAoMCgUEAAIA
ARIDTwkNCgwKBQQAAgADEgNPEBEKDAoFBAACAAgSA08SOgoPCggEAAIACJwIABIDTxM5CpUC
CgQEAAIBEgNVAj4ahwIgUmVxdWlyZWQuIFRoZSBpZGVudGlmaWVyIG9mIHRoaXMgdGFzayB3
aXRoaW4gaXRzIHBhcmVudCBldmVudCBjb25maWcsCiBzcGVjaWZpZWQgYnkgdGhlIGNsaWVu
dC4gVGhpcyBzaG91bGQgYmUgdW5pcXVlIGFtb25nIGFsbCB0aGUgdGFza3MgYmVsb25nCiB0
byB0aGUgc2FtZSBldmVudCBjb25maWcuIFdlIHVzZSB0aGlzIGZpZWxkIGFzIHRoZSBpZGVu
dGlmaWVyIHRvCiBmaW5kIG5leHQgdGFza3MgKHZpYSBmaWVsZCBgbmV4dF90YXNrcy50YXNr
X2lkYCkuCgoMCgUEAAIBBRIDVQIICgwKBQQAAgEBEgNVCRAKDAoFBAACAQMSA1UTFAoMCgUE
AAIBCBIDVRU9Cg8KCAQAAgEInAgAEgNVFjwKUwoEBAACAhIEWAJZLxpFIE9wdGlvbmFsLiBU
aGUgY3VzdG9taXplZCBwYXJhbWV0ZXJzIHRoZSB1c2VyIGNhbiBwYXNzIHRvIHRoaXMgdGFz
ay4KCgwKBQQAAgIGEgNYAh0KDAoFBAACAgESA1geKAoMCgUEAAICAxIDWCssCgwKBQQAAgII
EgNZBi4KDwoIBAACAgicCAASA1kHLQrZAQoEBAACAxIDXwJMGssBIE9wdGlvbmFsLiBEZXRl
cm1pbmVzIHRoZSBudW1iZXIgb2YgdGltZXMgdGhlCiB0YXNrIHdpbGwgYmUgcmV0cmllZCBv
biBmYWlsdXJlIGFuZCB3aXRoIHdoYXQgcmV0cnkgc3RyYXRlZ3kuCiBUaGlzIGlzIGFwcGxp
Y2FibGUgZm9yIGFzeW5jaHJvbm91cyBjYWxscyB0byBFdmVudGJ1cyBhbG9uZSAoUG9zdCBU
bwogUXVldWUsIFNjaGVkdWxlIGV0Yy4pLgoKDAoFBAACAwYSA18CDwoMCgUEAAIDARIDXxAe
CgwKBQQAAgMDEgNfISIKDAoFBAACAwgSA18jSwoPCggEAAIDCJwIABIDXyRKCsABCgQEAAIE
EgRkAmUvGrEBIE9wdGlvbmFsLiBEZXRlcm1pbmVzIHRoZSBudW1iZXIgb2YgdGltZXMgdGhl
CiB0YXNrIHdpbGwgYmUgcmV0cmllZCBvbiBmYWlsdXJlIGFuZCB3aXRoIHdoYXQgcmV0cnkg
c3RyYXRlZ3kuCiBUaGlzIGlzIGFwcGxpY2FibGUgZm9yIHN5bmNocm9ub3VzIGNhbGxzIHRv
IEV2ZW50YnVzIGFsb25lIChQb3N0KS4KCgwKBQQAAgQGEgNkAg8KDAoFBAACBAESA2QQLwoM
CgUEAAIEAxIDZDIzCgwKBQQAAgQIEgNlBi4KDwoIBAACBAicCAASA2UHLQpuCgQEAAIFEgRp
AmovGmAgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGNvbmRpdGlvbmFsIGZhaWx1cmUgcG9saWNp
ZXMgdGhhdCB3aWxsIGJlIGFwcGxpZWQgdG8KIHRoZSB0YXNrIGluIG9yZGVyLgoKDAoFBAAC
BQYSA2kCHAoMCgUEAAIFARIDaR05CgwKBQQAAgUDEgNpPD4KDAoFBAACBQgSA2oGLgoPCggE
AAIFCJwIABIDagctCo8CCgQEAAIGEgNwAkwagQIgT3B0aW9uYWwuIFRoZSBzZXQgb2YgdGFz
a3MgdGhhdCBhcmUgbmV4dCBpbiBsaW5lIHRvIGJlIGV4ZWN1dGVkIGFzIHBlciB0aGUKIGV4
ZWN1dGlvbiBncmFwaCBkZWZpbmVkIGZvciB0aGUgcGFyZW50IGV2ZW50LCBzcGVjaWZpZWQg
YnkKIGBldmVudF9jb25maWdfaWRgLiBFYWNoIG9mIHRoZXNlIG5leHQgdGFza3MgYXJlIGV4
ZWN1dGVkCiBvbmx5IGlmIHRoZSBjb25kaXRpb24gYXNzb2NpYXRlZCB3aXRoIHRoZW0gZXZh
bHVhdGVzIHRvIHRydWUuCgoMCgUEAAIGBBIDcAIKCgwKBQQAAgYGEgNwCxMKDAoFBAACBgES
A3AUHgoMCgUEAAIGAxIDcCEiCgwKBQQAAgYIEgNwI0sKDwoIBAACBgicCAASA3AkSgpsCgQE
AAIHEgR0AnUvGl4gT3B0aW9uYWwuIFRoZSBwb2xpY3kgZGljdGF0aW5nIHRoZSBleGVjdXRp
b24gb2YgdGhlIG5leHQgc2V0IG9mIHRhc2tzIGZvcgogdGhlIGN1cnJlbnQgdGFzay4KCgwK
BQQAAgcGEgN0AhoKDAoFBAACBwESA3QbNgoMCgUEAAIHAxIDdDk6CgwKBQQAAgcIEgN1Bi4K
DwoIBAACBwicCAASA3UHLQpTCgQEAAIIEgR4AnkvGkUgT3B0aW9uYWwuIFRoZSBwb2xpY3kg
ZGljdGF0aW5nIHRoZSBleGVjdXRpb24gc3RyYXRlZ3kgb2YgdGhpcyB0YXNrLgoKDAoFBAAC
CAYSA3gCFwoMCgUEAAIIARIDeBgvCgwKBQQAAggDEgN4MjMKDAoFBAACCAgSA3kGLgoPCggE
AAIICJwIABIDeQctClwKBAQAAgkSA30CQxpPIE9wdGlvbmFsLiBVc2VyLXByb3ZpZGVkIGxh
YmVsIHRoYXQgaXMgYXR0YWNoZWQgdG8gdGhpcyBUYXNrQ29uZmlnIGluIHRoZQogVUkuCgoM
CgUEAAIJBRIDfQIICgwKBQQAAgkBEgN9CRUKDAoFBAACCQMSA30YGQoMCgUEAAIJCBIDfRpC
Cg8KCAQAAgkInAgAEgN9G0EKWQoEBAACChIEgAECTRpLIE9wdGlvbmFsLiBEZXRlcm1pbmVz
IHdoYXQgYWN0aW9uIHRvIHRha2UgdXBvbiBzdWNjZXNzZnVsIHRhc2sgY29tcGxldGlvbi4K
Cg0KBQQAAgoGEgSAAQIPCg0KBQQAAgoBEgSAARAeCg0KBQQAAgoDEgSAASEjCg0KBQQAAgoI
EgSAASRMChAKCAQAAgoInAgAEgSAASVLCmYKBAQAAgsSBoQBAoUBLxpWIE9wdGlvbmFsLiBJ
ZiBzZXQsIG92ZXJyaWRlcyB0aGUgb3B0aW9uIGNvbmZpZ3VyZWQgaW4gdGhlIFRhc2sKIGlt
cGxlbWVudGF0aW9uIGNsYXNzLgoKDQoFBAACCwYSBIQBAhYKDQoFBAACCwESBIQBFy0KDQoF
BAACCwMSBIQBMDIKDQoFBAACCwgSBIUBBi4KEAoIBAACCwicCAASBIUBBy0KcQoEBAACDBIE
iQECQxpjIE9wdGlvbmFsLiBVc2VyLXByb3ZpZGVkIGRlc2NyaXB0aW9uIGludGVuZGVkIHRv
IGdpdmUgYWRkaXRpb25hbCBidXNpbmVzcwogY29udGV4dCBhYm91dCB0aGUgdGFzay4KCg0K
BQQAAgwFEgSJAQIICg0KBQQAAgwBEgSJAQkUCg0KBQQAAgwDEgSJARcZCg0KBQQAAgwIEgSJ
ARpCChAKCAQAAgwInAgAEgSJARtBCl0KBAQAAg0SBI0BAkUaTyBPcHRpb25hbC4gVXNlZCB0
byBkZWZpbmUgdGFzay10ZW1wbGF0ZSBuYW1lIGlmIHRhc2sgaXMgb2YgdHlwZQogdGFzay10
ZW1wbGF0ZQoKDQoFBAACDQUSBI0BAggKDQoFBAACDQESBI0BCRYKDQoFBAACDQMSBI0BGRsK
DQoFBAACDQgSBI0BHEQKEAoIBAACDQicCAASBI0BHUMKjQEKBAQAAg4SBJIBAkgafyBPcHRp
b25hbC4gT3B0aW9uYWwKIEVycm9yIGNhdGNoZXIgaWQgb2YgdGhlIGVycm9yIGNhdGNoIGZs
b3cgd2hpY2ggd2lsbCBiZSBleGVjdXRlZCB3aGVuCiBleGVjdXRpb24gZXJyb3IgaGFwcGVu
cyBpbiB0aGUgdGFzawoKDQoFBAACDgUSBJIBAggKDQoFBAACDgESBJIBCRkKDQoFBAACDgMS
BJIBHB4KDQoFBAACDggSBJIBH0cKEAoIBAACDgicCAASBJIBIEYKOgoEBAACDxIGlQEClgEv
GiogT3B0aW9uYWwuIEV4dGVybmFsIHRhc2sgdHlwZSBvZiB0aGUgdGFzawoKDQoFBAACDwYS
BJUBAhIKDQoFBAACDwESBJUBEyUKDQoFBAACDwMSBJUBKCoKDQoFBAACDwgSBJYBBi4KEAoI
BAACDwicCAASBJYBBy0KbwoEBAACEBIEmgECRBphIE9wdGlvbmFsLiBJbmZvcm1zIHRoZSBm
cm9udC1lbmQgYXBwbGljYXRpb24gd2hlcmUgdG8gZHJhdyB0aGlzIGVycm9yCiBjYXRjaGVy
IGNvbmZpZyBvbiB0aGUgVUkuCgoNCgUEAAIQBhIEmgECDAoNCgUEAAIQARIEmgENFQoNCgUE
AAIQAxIEmgEYGgoNCgUEAAIQCBIEmgEbQwoQCggEAAIQCJwIABIEmgEcQgpgCgIEARIGnwEA
sQEBGlIgUG9saWN5IHRoYXQgZGljdGF0ZXMgdGhlIGJlaGF2aW9yIGZvciB0aGUgdGFzayBh
ZnRlciBpdCBjb21wbGV0ZXMKIHN1Y2Nlc3NmdWxseS4KCgsKAwQBARIEnwEIFQopCgQEAQQA
EgahAQKsAQMaGSBUaGUgc3RhdGUgb2YgZXhlY3V0aW9uLgoKDQoFBAEEAAESBKEBBxEKHgoG
BAEEAAIAEgSjAQQgGg4gVU5TUEVDSUZJRUQuCgoPCgcEAQQAAgABEgSjAQQbCg8KBwQBBAAC
AAISBKMBHh8KWwoGBAEEAAIBEgSmAQQSGksgVGhlIGRlZmF1bHQgYmVoYXZpb3IsIHdoZXJl
IHN1Y2Nlc3NmdWwgdGFza3Mgd2lsbCBiZSBtYXJrZWQgYXMgU1VDQ0VFREVELgoKDwoHBAEE
AAIBARIEpgEEDQoPCgcEAQQAAgECEgSmARARCuIBCgYEAQQAAgISBKsBBBIa0QEgU2V0cyB0
aGUgc3RhdGUgdG8gU1VTUEVOREVEIGFmdGVyIGV4ZWN1dGluZy4gIFRoaXMgaXMgcmVxdWly
ZWQgZm9yCiBTdXNwZW5zaW9uVGFzazsgZXZlbnQgZXhlY3V0aW9uIHdpbGwgY29udGludWUg
b25jZSB0aGUgdXNlciBjYWxscwogUmVzb2x2ZVN1c3BlbnNpb25zIHdpdGggdGhlIGV2ZW50
X2V4ZWN1dGlvbl9pbmZvX2lkIGFuZCB0aGUgdGFzayBudW1iZXIuCgoPCgcEAQQAAgIBEgSr
AQQNCg8KBwQBBAACAgISBKsBEBEKXwoEBAECABIEsAECHRpRIFN0YXRlIHRvIHdoaWNoIHRo
ZSBleGVjdXRpb24gc25hcHNob3Qgc3RhdHVzIHdpbGwgYmUgc2V0IGlmIHRoZSB0YXNrCiBz
dWNjZWVkcy4KCg0KBQQBAgAGEgSwAQIMCg0KBQQBAgABEgSwAQ0YCg0KBQQBAgADEgSwARsc
CtgBCgIEAhIGtgEA+gEBGskBIFBvbGljeSB0aGF0IGRlZmluZXMgdGhlIHRhc2sgcmV0cnkg
bG9naWMgYW5kIGZhaWx1cmUgdHlwZS4gSWYgbm8KIEZhaWx1cmVQb2xpY3kgaXMgZGVmaW5l
ZCBmb3IgYSB0YXNrLCBhbGwgaXRzIGRlcGVuZGVudCB0YXNrcyB3aWxsIG5vdCBiZQogZXhl
Y3V0ZWQgKGkuZSwgYSBgcmV0cnlfc3RyYXRlZ3lgIG9mIE5PTkUgd2lsbCBiZSBhcHBsaWVk
KS4KCgsKAwQCARIEtgEIFQo0CgQEAgQAEga4AQLoAQMaJCBUaGUgYmVoYXZpb3Igd2hlbiB0
aGUgdGFrcyBmYWlsZWQuCgoNCgUEAgQAARIEuAEHFAoeCgYEAgQAAgASBLoBBCMaDiBVTlNQ
RUNJRklFRC4KCg8KBwQCBAACAAESBLoBBB4KDwoHBAIEAAIAAhIEugEhIgp/CgYEAgQAAgES
BL4BBA8abyBJZ25vcmVzIHRoZSBmYWlsdXJlIG9mIHRoaXMgdGFzay4gVGhlIHJlc3Qgb2Yg
dGhlIGludGVncmF0aW9uIHdpbGwgYmUKIGV4ZWN1dGVkIEFzc3VtaW5nIHRoaXMgdGFzayBz
dWNjZWVkZWQuCgoPCgcEAgQAAgEBEgS+AQQKCg8KBwQCBAACAQISBL4BDQ4KxAEKBgQCBAAC
AhIEwwEEDRqzASBDYXVzZXMgYSBwZXJtYW5lbnQgZmFpbHVyZSBvZiB0aGUgdGFzay4gSG93
ZXZlciwgaWYgdGhlIGxhc3QgdGFzayhzKQogb2YgZXZlbnQgd2FzIHN1Y2Nlc3NmdWxseSBj
b21wbGV0ZWQgZGVzcGl0ZSB0aGUgZmFpbHVyZSBvZiB0aGlzIHRhc2ssCiBpdCBoYXMgbm8g
aW1wYWN0IG9uIHRoZSBpbnRlZ3JhdGlvbi4KCg8KBwQCBAACAgESBMMBBAgKDwoHBAIEAAIC
AhIEwwELDAqoAQoGBAIEAAIDEgTIAQQOGpcBIENhdXNlcyBhIHBlcm1hbmVudCBmYWlsdXJl
IG9mIHRoZSBldmVudC4gSXQgaXMgZGlmZmVyZW50IGZyb20gTk9ORQogYmVjYXVzZSB0aGlz
IHdpbGwgbWFyayB0aGUgZXZlbnQgYXMgRkFJTEVEIGJ5IHNodXR0aW5nIGRvd24gdGhlCiBl
dmVudCBleGVjdXRpb24uCgoPCgcEAgQAAgMBEgTIAQQJCg8KBwQCBAACAwISBMgBDA0KgAMK
BgQCBAACBBIE0AEEFxrvAiBUaGUgdGFzayB3aWxsIGJlIHJldHJpZWQgZnJvbSB0aGUgZmFp
bGVkIHRhc2sgb253YXJkcyBhZnRlciBhIGZpeGVkCiBkZWxheS4gQSBtYXgtcmV0cnkgY291
bnQgaXMgcmVxdWlyZWQgdG8gYmUgc3BlY2lmaWVkIHdpdGggdGhpcwogc3RyYXRlZ3kuIEEg
aml0dGVyIGlzIGFkZGVkIHRvIGVhY2ggZXhwb25lbnRpYWwgaW50ZXJ2YWwgc28gdGhhdAog
Y29uY3VycmVudGx5IGZhaWxpbmcgdGFza3Mgb2YgdGhlIHNhbWUgdHlwZSBkbyBub3QgZW5k
IHVwIHJldHJ5aW5nCiBhZnRlciB0aGUgZXhhY3Qgc2FtZSBleHBvbmVudGlhbCBpbnRlcnZh
bC4gbWF4X3JldHJpZXMgYW5kCiBpbnRlcnZhbF9pbl9zZWNvbmRzIG11c3QgYmUgc3BlY2lm
aWVkLgoKDwoHBAIEAAIEARIE0AEEEgoPCgcEAgQAAgQCEgTQARUWCrEDCgYEAgQAAgUSBNkB
BBcaoAMgVGhlIHRhc2sgd2lsbCBiZSByZXRyaWVkIGZyb20gdGhlIGZhaWxlZCB0YXNrIG9u
d2FyZHMgYWZ0ZXIgYSBmaXhlZAogZGVsYXkgdGhhdCBsaW5lYXJseSBpbmNyZWFzZXMgd2l0
aCBlYWNoIHJldHJ5IGF0dGVtcHQuIEEgaml0dGVyIGlzCiBhZGRlZCB0byBlYWNoIGV4cG9u
ZW50aWFsIGludGVydmFsIHNvIHRoYXQgY29uY3VycmVudGx5IGZhaWxpbmcgdGFza3MKIG9m
IHRoZSBzYW1lIHR5cGUgZG8gbm90IGVuZCB1cCByZXRyeWluZyBhZnRlciB0aGUgZXhhY3Qg
c2FtZQogZXhwb25lbnRpYWwgaW50ZXJ2YWwuIEEgbWF4LXJldHJ5IGNvdW50IGlzIHJlcXVp
cmVkIHRvIGJlIHNwZWNpZmllZAogd2l0aCB0aGlzIHN0cmF0ZWd5LiBtYXhfcmV0cmllcyBh
bmQgaW50ZXJ2YWxfaW5fc2Vjb25kcyBtdXN0IGJlCiBzcGVjaWZpZWQuCgoPCgcEAgQAAgUB
EgTZAQQSCg8KBwQCBAACBQISBNkBFRYKlgMKBgQCBAACBhIE4QEEHBqFAyBUaGUgdGFzayB3
aWxsIGJlIHJldHJpZWQgYWZ0ZXIgYW4gZXhwb25lbnRpYWxseSBpbmNyZWFzaW5nIHBlcmlv
ZCBvZgogdGltZSB3aXRoIGVhY2ggZmFpbHVyZS4gQSBqaXR0ZXIgaXMgYWRkZWQgdG8gZWFj
aCBleHBvbmVudGlhbCBpbnRlcnZhbAogc28gdGhhdCBjb25jdXJyZW50bHkgZmFpbGluZyB0
YXNrcyBvZiB0aGUgc2FtZSB0eXBlIGRvIG5vdCBlbmQgdXAKIHJldHJ5aW5nIGFmdGVyIHRo
ZSBleGFjdCBzYW1lIGV4cG9uZW50aWFsIGludGVydmFsLiBBIG1heC1yZXRyeSBjb3VudAog
aXMgcmVxdWlyZWQgdG8gYmUgc3BlY2lmaWVkIHdpdGggdGhpcyBzdHJhdGVneS4gYG1heF9y
ZXRyaWVzYCBhbmQKIGBpbnRlcnZhbF9pbl9zZWNvbmRzYCBtdXN0IGJlIHNwZWNpZmllZC4K
Cg8KBwQCBAACBgESBOEBBBcKDwoHBAIEAAIGAhIE4QEaGwr/AQoGBAIEAAIHEgTnAQQpGu4B
IFRoZSBlbnRpcmUgaW50ZWdyYXRpb24gd2lsbCBiZSByZXN0YXJ0ZWQgd2l0aCB0aGUgaW5p
dGlhbCBwYXJhbWV0ZXJzIHRoYXQKIHdlcmUgc2V0IHdoZW4gdGhlIGV2ZW50IHdhcyBmaXJl
ZC4gQSBtYXgtcmV0cnkgY291bnQgaXMgcmVxdWlyZWQgdG8gYmUKIHNwZWNpZmllZCB3aXRo
IHRoaXMgc3RyYXRlZ3kuIGBtYXhfcmV0cmllc2AgYW5kIGBpbnRlcnZhbF9pbl9zZWNvbmRz
YAogbXVzdCBiZSBzcGVjaWZpZWQuCgoPCgcEAgQAAgcBEgTnAQQkCg8KBwQCBAACBwISBOcB
JygKPgoEBAICABIE6wECIxowIERlZmluZXMgd2hhdCBoYXBwZW5zIHRvIHRoZSB0YXNrIHVw
b24gZmFpbHVyZS4KCg0KBQQCAgAGEgTrAQIPCg0KBQQCAgABEgTrARAeCg0KBQQCAgADEgTr
ASEiCr8BCgQEAgIBEgTwAQIYGrABIFJlcXVpcmVkIGlmIHJldHJ5X3N0cmF0ZWd5IGlzIEZJ
WEVEX0lOVEVSVkFMIG9yCiBMSU5FQVIvRVhQT05FTlRJQUxfQkFDS09GRi9SRVNUQVJUX0lO
VEVHUkFUSU9OX1dJVEhfQkFDS09GRi4gRGVmaW5lcyB0aGUKIG51bWJlciBvZiB0aW1lcyB0
aGUgdGFzayB3aWxsIGJlIHJldHJpZWQgaWYgZmFpbGVkLgoKDQoFBAICAQUSBPABAgcKDQoF
BAICAQESBPABCBMKDQoFBAICAQMSBPABFhcKtAEKBAQCAgISBPUBAi4apQEgUmVxdWlyZWQg
aWYgcmV0cnlfc3RyYXRlZ3kgaXMgRklYRURfSU5URVJWQUwgb3IKIExJTkVBUi9FWFBPTkVO
VElBTF9CQUNLT0ZGL1JFU1RBUlRfSU5URUdSQVRJT05fV0lUSF9CQUNLT0ZGLiBEZWZpbmVz
IHRoZQogaW5pdGlhbCBpbnRlcnZhbCBpbiBzZWNvbmRzIGZvciBiYWNrb2ZmLgoKDQoFBAIC
AgYSBPUBAhsKDQoFBAICAgESBPUBHCkKDQoFBAICAgMSBPUBLC0KiwEKBAQCAgMSBPkBAhca
fSBPcHRpb25hbC4gVGhlIHN0cmluZyBjb25kaXRpb24gdGhhdCB3aWxsIGJlIGV2YWx1YXRl
ZCB0byBkZXRlcm1pbmUgaWYgdGhlCiB0YXNrIHNob3VsZCBiZSByZXRyaWVkIHdpdGggdGhp
cyBmYWlsdXJlIHBvbGljeS4KCg0KBQQCAgMFEgT5AQIICg0KBQQCAgMBEgT5AQkSCg0KBQQC
AgMDEgT5ARUWCmwKAgQDEgb+AQCOAgEaXiBUaGUgdGFzayB0aGF0IGlzIG5leHQgaW4gbGlu
ZSB0byBiZSBleGVjdXRlZCwgaWYgdGhlCiBjb25kaXRpb24gc3BlY2lmaWVkIGV2YWx1YXRl
ZCB0byB0cnVlLgoKCwoDBAMBEgT+AQgQCiQKBAQDAgASBIACAhwaFiBJRCBvZiB0aGUgbmV4
dCB0YXNrLgoKDQoFBAMCAAUSBIACAggKDQoFBAMCAAESBIACCRcKDQoFBAMCAAMSBIACGhsK
LQoEBAMCARIEgwICFRofIFRhc2sgbnVtYmVyIG9mIHRoZSBuZXh0IHRhc2suCgoNCgUEAwIB
BRIEgwICCAoNCgUEAwIBARIEgwIJEAoNCgUEAwIBAxIEgwITFApZCgQEAwICEgSGAgIXGksg
U3RhbmRhcmQgZmlsdGVyIGV4cHJlc3Npb24gZm9yIHRoaXMgdGFzayB0byBiZWNvbWUgYW4g
ZWxpZ2libGUgbmV4dCB0YXNrLgoKDQoFBAMCAgUSBIYCAggKDQoFBAMCAgESBIYCCRIKDQoF
BAMCAgMSBIYCFRYKTAoEBAMCAxIEiQICGho+IFVzZXItcHJvdmlkZWQgbGFiZWwgdGhhdCBp
cyBhdHRhY2hlZCB0byB0aGlzIGVkZ2UgaW4gdGhlIFVJLgoKDQoFBAMCAwUSBIkCAggKDQoF
BAMCAwESBIkCCRUKDQoFBAMCAwMSBIkCGBkKZwoEBAMCBBIEjQICGRpZIFVzZXItcHJvdmlk
ZWQgZGVzY3JpcHRpb24gaW50ZW5kZWQgdG8gZ2l2ZSBhZGRpdGlvbmFsIGJ1c2luZXNzIGNv
bnRleHQKIGFib3V0IHRoZSB0YXNrLgoKDQoFBAMCBAUSBI0CAggKDQoFBAMCBAESBI0CCRQK
DQoFBAMCBAMSBI0CFxgKOAoCBAQSBpECAJgCARoqIENvbmRpdGlvbmFsIHRhc2sgZmFpbHVy
IHJldHJ5IHN0cmF0ZWdpZXMKCgsKAwQEARIEkQIIIgpXCgQEBAIAEgSTAgIuGkkgVGhlIGxp
c3Qgb2YgZmFpbHVyZSBwb2xpY2llcyB0aGF0IHdpbGwgYmUgYXBwbGllZCB0byB0aGUgdGFz
ayBpbiBvcmRlci4KCg0KBQQEAgAEEgSTAgIKCg0KBQQEAgAGEgSTAgsYCg0KBQQEAgABEgST
AhkpCg0KBQQEAgADEgSTAiwtCmMKBAQEAgESBJcCAisaVSBUaGUgZGVmYXVsdCBmYWlsdXJl
IHBvbGljeSB0byBiZSBhcHBsaWVkIGlmIG5vIGNvbmRpdGlvbmFsIGZhaWx1cmUgcG9saWN5
CiBtYXRjaGVzLgoKDQoFBAQCAQYSBJcCAg8KDQoFBAQCAQESBJcCECYKDQoFBAQCAQMSBJcC
KSpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig ===
    # Fields for TaskConfig
    # Field: task Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.integrations.v1alpha.TaskConfig.ParametersEntry)
    # Field: failure_policy Type: 11 (.google.cloud.integrations.v1alpha.FailurePolicy)
    # Field: synchronous_call_failure_policy Type: 11 (.google.cloud.integrations.v1alpha.FailurePolicy)
    # Field: conditional_failure_policies Type: 11 (.google.cloud.integrations.v1alpha.ConditionalFailurePolicies)
    # Field: next_tasks Type: 11 (.google.cloud.integrations.v1alpha.NextTask)
    # Field: next_tasks_execution_policy Type: 14 (.google.cloud.integrations.v1alpha.TaskConfig.NextTasksExecutionPolicy)
    # Field: task_execution_strategy Type: 14 (.google.cloud.integrations.v1alpha.TaskConfig.TaskExecutionStrategy)
    # Field: display_name Type: 9 ()
    # Field: success_policy Type: 11 (.google.cloud.integrations.v1alpha.SuccessPolicy)
    # Field: json_validation_option Type: 14 (.google.cloud.integrations.v1alpha.JsonValidationOption)
    # Field: description Type: 9 ()
    # Field: task_template Type: 9 ()
    # Field: error_catcher_id Type: 9 ()
    # Field: external_task_type Type: 14 (.google.cloud.integrations.v1alpha.TaskConfig.ExternalTaskType)
    # Field: position Type: 11 (.google.cloud.integrations.v1alpha.Coordinate)

# Enum: TaskConfig::NextTasksExecutionPolicy
our $TaskConfig_NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED = 0;
our $TaskConfig_RUN_ALL_MATCH = 1;
our $TaskConfig_RUN_FIRST_MATCH = 2;

# Enum: TaskConfig::TaskExecutionStrategy
our $TaskConfig_TASK_EXECUTION_STRATEGY_UNSPECIFIED = 0;
our $TaskConfig_WHEN_ALL_SUCCEED = 1;
our $TaskConfig_WHEN_ANY_SUCCEED = 2;
our $TaskConfig_WHEN_ALL_TASKS_AND_CONDITIONS_SUCCEED = 3;

# Enum: TaskConfig::ExternalTaskType
our $TaskConfig_EXTERNAL_TASK_TYPE_UNSPECIFIED = 0;
our $TaskConfig_NORMAL_TASK = 1;
our $TaskConfig_ERROR_TASK = 2;

# === Message: Google::Cloud::Integrations::V1alpha::TaskConfig::SuccessPolicy ===
    # Fields for SuccessPolicy
    # Field: final_state Type: 14 (.google.cloud.integrations.v1alpha.SuccessPolicy.FinalState)

# Enum: SuccessPolicy::FinalState
our $SuccessPolicy_FINAL_STATE_UNSPECIFIED = 0;
our $SuccessPolicy_SUCCEEDED = 1;
our $SuccessPolicy_SUSPENDED = 2;

# === Message: Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy ===
    # Fields for FailurePolicy
    # Field: retry_strategy Type: 14 (.google.cloud.integrations.v1alpha.FailurePolicy.RetryStrategy)
    # Field: max_retries Type: 5 ()
    # Field: interval_time Type: 11 (.google.protobuf.Timestamp)
    # Field: condition Type: 9 ()

# Enum: FailurePolicy::RetryStrategy
our $FailurePolicy_RETRY_STRATEGY_UNSPECIFIED = 0;
our $FailurePolicy_IGNORE = 1;
our $FailurePolicy_NONE = 2;
our $FailurePolicy_FATAL = 3;
our $FailurePolicy_FIXED_INTERVAL = 4;
our $FailurePolicy_LINEAR_BACKOFF = 5;
our $FailurePolicy_EXPONENTIAL_BACKOFF = 6;
our $FailurePolicy_RESTART_INTEGRATION_WITH_BACKOFF = 7;

# === Message: Google::Cloud::Integrations::V1alpha::TaskConfig::NextTask ===
    # Fields for NextTask
    # Field: task_config_id Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: condition Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Integrations::V1alpha::TaskConfig::ConditionalFailurePolicies ===
    # Fields for ConditionalFailurePolicies
    # Field: failure_policies Type: 11 (.google.cloud.integrations.v1alpha.FailurePolicy)
    # Field: default_failure_policy Type: 11 (.google.cloud.integrations.v1alpha.FailurePolicy)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::TaskConfig - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/task_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Integrations::V1alpha::TaskConfig;

    my $msg = Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig->new({
        task => $task,
        task_id => $task_id,
        parameters => $parameters,
        failure_policy => $failure_policy,
    });

    # Read or update a field
    my $val = $msg->task();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/task_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig

The task configuration details. This is not the implementation of Task.
There might be multiple TaskConfigs for the same Task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task() >> / C<< $msg->task($value) >>

Type: C<String>

Optional. The name for the task.

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Required. The identifier of this task within its parent event config,
specified by the client. This should be unique among all the tasks belong
to the same event config. We use this field as the identifier to
find next tasks (via field `next_tasks.task_id`).

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig::ParametersEntry>)

Optional. The customized parameters the user can pass to this task.

=item * C<< $msg->failure_policy() >> / C<< $msg->failure_policy($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy>)

Optional. Determines the number of times the
task will be retried on failure and with what retry strategy.
This is applicable for asynchronous calls to Eventbus alone (Post To
Queue, Schedule etc.).

=item * C<< $msg->synchronous_call_failure_policy() >> / C<< $msg->synchronous_call_failure_policy($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy>)

Optional. Determines the number of times the
task will be retried on failure and with what retry strategy.
This is applicable for synchronous calls to Eventbus alone (Post).

=item * C<< $msg->conditional_failure_policies() >> / C<< $msg->conditional_failure_policies($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::ConditionalFailurePolicies>)

Optional. The list of conditional failure policies that will be applied to
the task in order.

=item * C<< $msg->next_tasks() >> / C<< $msg->next_tasks($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::NextTask>)

Optional. The set of tasks that are next in line to be executed as per the
execution graph defined for the parent event, specified by
`event_config_id`. Each of these next tasks are executed
only if the condition associated with them evaluates to true.

=item * C<< $msg->next_tasks_execution_policy() >> / C<< $msg->next_tasks_execution_policy($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::NextTasksExecutionPolicy>)

Optional. The policy dictating the execution of the next set of tasks for
the current task.

=item * C<< $msg->task_execution_strategy() >> / C<< $msg->task_execution_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::TaskExecutionStrategy>)

Optional. The policy dictating the execution strategy of this task.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-provided label that is attached to this TaskConfig in the
UI.

=item * C<< $msg->success_policy() >> / C<< $msg->success_policy($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::SuccessPolicy>)

Optional. Determines what action to take upon successful task completion.

=item * C<< $msg->json_validation_option() >> / C<< $msg->json_validation_option($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::JsonValidationOption>)

Optional. If set, overrides the option configured in the Task
implementation class.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-provided description intended to give additional business
context about the task.

=item * C<< $msg->task_template() >> / C<< $msg->task_template($value) >>

Type: C<String>

Optional. Used to define task-template name if task is of type
task-template

=item * C<< $msg->error_catcher_id() >> / C<< $msg->error_catcher_id($value) >>

Type: C<String>

Optional. Optional
Error catcher id of the error catch flow which will be executed when
execution error happens in the task

=item * C<< $msg->external_task_type() >> / C<< $msg->external_task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::ExternalTaskType>)

Optional. External task type of the task

=item * C<< $msg->position() >> / C<< $msg->position($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate>)

Optional. Informs the front-end application where to draw this error
catcher config on the UI.

=back

=head3 Enum: TaskConfig::NextTasksExecutionPolicy

=over 4

=item * C<NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED> => C<0>

=item * C<RUN_ALL_MATCH> => C<1>

=item * C<RUN_FIRST_MATCH> => C<2>

=back

=head3 Enum: TaskConfig::TaskExecutionStrategy

=over 4

=item * C<TASK_EXECUTION_STRATEGY_UNSPECIFIED> => C<0>

=item * C<WHEN_ALL_SUCCEED> => C<1>

=item * C<WHEN_ANY_SUCCEED> => C<2>

=item * C<WHEN_ALL_TASKS_AND_CONDITIONS_SUCCEED> => C<3>

=back

=head3 Enum: TaskConfig::ExternalTaskType

=over 4

=item * C<EXTERNAL_TASK_TYPE_UNSPECIFIED> => C<0>

=item * C<NORMAL_TASK> => C<1>

=item * C<ERROR_TASK> => C<2>

=back

=head2 Google::Cloud::Integrations::V1alpha::TaskConfig::SuccessPolicy

Policy that dictates the behavior for the task after it completes
successfully.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->final_state() >> / C<< $msg->final_state($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::SuccessPolicy::FinalState>)

State to which the execution snapshot status will be set if the task
succeeds.

=back

=head3 Enum: SuccessPolicy::FinalState

=over 4

=item * C<FINAL_STATE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<SUSPENDED> => C<2>

=back

=head2 Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy

Policy that defines the task retry logic and failure type. If no
FailurePolicy is defined for a task, all its dependent tasks will not be
executed (i.e, a `retry_strategy` of NONE will be applied).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->retry_strategy() >> / C<< $msg->retry_strategy($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::FailurePolicy::RetryStrategy>)

Defines what happens to the task upon failure.

=item * C<< $msg->max_retries() >> / C<< $msg->max_retries($value) >>

Type: C<Int32>

Required if retry_strategy is FIXED_INTERVAL or
LINEAR/EXPONENTIAL_BACKOFF/RESTART_INTEGRATION_WITH_BACKOFF. Defines the
number of times the task will be retried if failed.

=item * C<< $msg->interval_time() >> / C<< $msg->interval_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required if retry_strategy is FIXED_INTERVAL or
LINEAR/EXPONENTIAL_BACKOFF/RESTART_INTEGRATION_WITH_BACKOFF. Defines the
initial interval in seconds for backoff.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Optional. The string condition that will be evaluated to determine if the
task should be retried with this failure policy.

=back

=head3 Enum: FailurePolicy::RetryStrategy

=over 4

=item * C<RETRY_STRATEGY_UNSPECIFIED> => C<0>

=item * C<IGNORE> => C<1>

=item * C<NONE> => C<2>

=item * C<FATAL> => C<3>

=item * C<FIXED_INTERVAL> => C<4>

=item * C<LINEAR_BACKOFF> => C<5>

=item * C<EXPONENTIAL_BACKOFF> => C<6>

=item * C<RESTART_INTEGRATION_WITH_BACKOFF> => C<7>

=back

=head2 Google::Cloud::Integrations::V1alpha::TaskConfig::NextTask

The task that is next in line to be executed, if the
condition specified evaluated to true.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task_config_id() >> / C<< $msg->task_config_id($value) >>

Type: C<String>

ID of the next task.

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Task number of the next task.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Standard filter expression for this task to become an eligible next task.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

User-provided label that is attached to this edge in the UI.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User-provided description intended to give additional business context
about the task.

=back

=head2 Google::Cloud::Integrations::V1alpha::TaskConfig::ConditionalFailurePolicies

Conditional task failur retry strategies

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->failure_policies() >> / C<< $msg->failure_policies($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy>)

The list of failure policies that will be applied to the task in order.

=item * C<< $msg->default_failure_policy() >> / C<< $msg->default_failure_policy($value) >>

Type: C<Message> (L<Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy>)

The default failure policy to be applied if no conditional failure policy
matches.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::TaskConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
