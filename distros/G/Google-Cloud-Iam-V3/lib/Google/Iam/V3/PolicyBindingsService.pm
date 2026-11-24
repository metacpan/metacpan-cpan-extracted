package Google::Iam::V3::PolicyBindingsService;

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
    eval { require Google::Api::Resource };
    eval { require Google::Iam::V3::OperationMetadata };
    eval { require Google::Iam::V3::PolicyBindingResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvaWFtL3YzL3BvbGljeV9iaW5kaW5nc19zZXJ2aWNlLnByb3RvEg1nb29nbGUu
aWFtLnYzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVu
dC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxomZ29vZ2xlL2lhbS92My9vcGVyYXRpb25fbWV0YWRhdGEucHJvdG8a
LGdvb2dsZS9pYW0vdjMvcG9saWN5X2JpbmRpbmdfcmVzb3VyY2VzLnByb3RvGiNnb29nbGUv
bG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnBy
b3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKDAgoaQ3JlYXRlUG9saWN5
QmluZGluZ1JlcXVlc3QSQAoGcGFyZW50GAEgASgJQijgQQL6QSISIGlhbS5nb29nbGVhcGlz
LmNvbS9Qb2xpY3lCaW5kaW5nUgZwYXJlbnQSLwoRcG9saWN5X2JpbmRpbmdfaWQYAiABKAlC
A+BBAlIPcG9saWN5QmluZGluZ0lkEkgKDnBvbGljeV9iaW5kaW5nGAMgASgLMhwuZ29vZ2xl
LmlhbS52My5Qb2xpY3lCaW5kaW5nQgPgQQJSDXBvbGljeUJpbmRpbmcSKAoNdmFsaWRhdGVf
b25seRgEIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHkiVwoXR2V0UG9saWN5QmluZGluZ1JlcXVl
c3QSPAoEbmFtZRgBIAEoCUIo4EEC+kEiCiBpYW0uZ29vZ2xlYXBpcy5jb20vUG9saWN5Qmlu
ZGluZ1IEbmFtZSLSAQoaVXBkYXRlUG9saWN5QmluZGluZ1JlcXVlc3QSSAoOcG9saWN5X2Jp
bmRpbmcYASABKAsyHC5nb29nbGUuaWFtLnYzLlBvbGljeUJpbmRpbmdCA+BBAlINcG9saWN5
QmluZGluZxIoCg12YWxpZGF0ZV9vbmx5GAIgASgIQgPgQQFSDHZhbGlkYXRlT25seRJACgt1
cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBk
YXRlTWFzayKdAQoaRGVsZXRlUG9saWN5QmluZGluZ1JlcXVlc3QSPAoEbmFtZRgBIAEoCUIo
4EEC+kEiCiBpYW0uZ29vZ2xlYXBpcy5jb20vUG9saWN5QmluZGluZ1IEbmFtZRIXCgRldGFn
GAIgASgJQgPgQQFSBGV0YWcSKAoNdmFsaWRhdGVfb25seRgDIAEoCEID4EEBUgx2YWxpZGF0
ZU9ubHkiwAEKGUxpc3RQb2xpY3lCaW5kaW5nc1JlcXVlc3QSQAoGcGFyZW50GAEgASgJQijg
QQL6QSISIGlhbS5nb29nbGVhcGlzLmNvbS9Qb2xpY3lCaW5kaW5nUgZwYXJlbnQSIAoJcGFn
ZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJ
cGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIikAEKGkxpc3RQb2xpY3lC
aW5kaW5nc1Jlc3BvbnNlEkUKD3BvbGljeV9iaW5kaW5ncxgBIAMoCzIcLmdvb2dsZS5pYW0u
djMuUG9saWN5QmluZGluZ1IOcG9saWN5QmluZGluZ3MSKwoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJQgPgQQFSDW5leHRQYWdlVG9rZW4i5QEKIVNlYXJjaFRhcmdldFBvbGljeUJpbmRpbmdz
UmVxdWVzdBIbCgZ0YXJnZXQYASABKAlCA+BBAlIGdGFyZ2V0EiAKCXBhZ2Vfc2l6ZRgCIAEo
BUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhJA
CgZwYXJlbnQYBSABKAlCKOBBAvpBIhIgaWFtLmdvb2dsZWFwaXMuY29tL1BvbGljeUJpbmRp
bmdSBnBhcmVudBIbCgZmaWx0ZXIYBiABKAlCA+BBAVIGZmlsdGVyIpgBCiJTZWFyY2hUYXJn
ZXRQb2xpY3lCaW5kaW5nc1Jlc3BvbnNlEkUKD3BvbGljeV9iaW5kaW5ncxgBIAMoCzIcLmdv
b2dsZS5pYW0udjMuUG9saWN5QmluZGluZ1IOcG9saWN5QmluZGluZ3MSKwoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJQgPgQQFSDW5leHRQYWdlVG9rZW4yoBEKDlBvbGljeUJpbmRpbmdzEowD
ChNDcmVhdGVQb2xpY3lCaW5kaW5nEikuZ29vZ2xlLmlhbS52My5DcmVhdGVQb2xpY3lCaW5k
aW5nUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iqgKC0+STAtQBIjIv
djMve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nczoOcG9s
aWN5X2JpbmRpbmdaQyIxL3YzL3twYXJlbnQ9Zm9sZGVycy8qL2xvY2F0aW9ucy8qfS9wb2xp
Y3lCaW5kaW5nczoOcG9saWN5X2JpbmRpbmdaSSI3L3YzL3twYXJlbnQ9b3JnYW5pemF0aW9u
cy8qL2xvY2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nczoOcG9saWN5X2JpbmRpbmfaQSdwYXJl
bnQscG9saWN5X2JpbmRpbmcscG9saWN5X2JpbmRpbmdfaWTKQSIKDVBvbGljeUJpbmRpbmcS
EU9wZXJhdGlvbk1ldGFkYXRhEo0CChBHZXRQb2xpY3lCaW5kaW5nEiYuZ29vZ2xlLmlhbS52
My5HZXRQb2xpY3lCaW5kaW5nUmVxdWVzdBocLmdvb2dsZS5pYW0udjMuUG9saWN5QmluZGlu
ZyKyAYLT5JMCpAESMi92My97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3BvbGljeUJp
bmRpbmdzLyp9WjMSMS92My97bmFtZT1mb2xkZXJzLyovbG9jYXRpb25zLyovcG9saWN5Qmlu
ZGluZ3MvKn1aORI3L3YzL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9wb2xp
Y3lCaW5kaW5ncy8qfdpBBG5hbWUSrAMKE1VwZGF0ZVBvbGljeUJpbmRpbmcSKS5nb29nbGUu
aWFtLnYzLlVwZGF0ZVBvbGljeUJpbmRpbmdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbiLKAoLT5JMCgQIyQS92My97cG9saWN5X2JpbmRpbmcubmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3BvbGljeUJpbmRpbmdzLyp9Og5wb2xpY3lfYmluZGluZ1pSMkAv
djMve3BvbGljeV9iaW5kaW5nLm5hbWU9Zm9sZGVycy8qL2xvY2F0aW9ucy8qL3BvbGljeUJp
bmRpbmdzLyp9Og5wb2xpY3lfYmluZGluZ1pYMkYvdjMve3BvbGljeV9iaW5kaW5nLm5hbWU9
b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL3BvbGljeUJpbmRpbmdzLyp9Og5wb2xpY3lf
YmluZGluZ9pBGnBvbGljeV9iaW5kaW5nLHVwZGF0ZV9tYXNrykEiCg1Qb2xpY3lCaW5kaW5n
EhFPcGVyYXRpb25NZXRhZGF0YRLBAgoTRGVsZXRlUG9saWN5QmluZGluZxIpLmdvb2dsZS5p
YW0udjMuRGVsZXRlUG9saWN5QmluZGluZ1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uIt8BgtPkkwKkASoyL3YzL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
cG9saWN5QmluZGluZ3MvKn1aMyoxL3YzL3tuYW1lPWZvbGRlcnMvKi9sb2NhdGlvbnMvKi9w
b2xpY3lCaW5kaW5ncy8qfVo5KjcvdjMve25hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9u
cy8qL3BvbGljeUJpbmRpbmdzLyp92kEEbmFtZcpBKgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5
EhFPcGVyYXRpb25NZXRhZGF0YRKgAgoSTGlzdFBvbGljeUJpbmRpbmdzEiguZ29vZ2xlLmlh
bS52My5MaXN0UG9saWN5QmluZGluZ3NSZXF1ZXN0GikuZ29vZ2xlLmlhbS52My5MaXN0UG9s
aWN5QmluZGluZ3NSZXNwb25zZSK0AYLT5JMCpAESMi92My97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyp9L3BvbGljeUJpbmRpbmdzWjMSMS92My97cGFyZW50PWZvbGRlcnMvKi9s
b2NhdGlvbnMvKn0vcG9saWN5QmluZGluZ3NaORI3L3YzL3twYXJlbnQ9b3JnYW5pemF0aW9u
cy8qL2xvY2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nc9pBBnBhcmVudBKQAwoaU2VhcmNoVGFy
Z2V0UG9saWN5QmluZGluZ3MSMC5nb29nbGUuaWFtLnYzLlNlYXJjaFRhcmdldFBvbGljeUJp
bmRpbmdzUmVxdWVzdBoxLmdvb2dsZS5pYW0udjMuU2VhcmNoVGFyZ2V0UG9saWN5QmluZGlu
Z3NSZXNwb25zZSKMAoLT5JMC9QESTS92My97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
Lyp9L3BvbGljeUJpbmRpbmdzOnNlYXJjaFRhcmdldFBvbGljeUJpbmRpbmdzWk4STC92My97
cGFyZW50PWZvbGRlcnMvKi9sb2NhdGlvbnMvKn0vcG9saWN5QmluZGluZ3M6c2VhcmNoVGFy
Z2V0UG9saWN5QmluZGluZ3NaVBJSL3YzL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0
aW9ucy8qfS9wb2xpY3lCaW5kaW5nczpzZWFyY2hUYXJnZXRQb2xpY3lCaW5kaW5nc9pBDXBh
cmVudCx0YXJnZXQaRspBEmlhbS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CtAIKEWNvbS5nb29nbGUuaWFtLnYzQhpQ
b2xpY3lCaW5kaW5nc1NlcnZpY2VQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2lhbS9h
cGl2My9pYW1wYjtpYW1wYqoCE0dvb2dsZS5DbG91ZC5JYW0uVjPKAhNHb29nbGVcQ2xvdWRc
SWFtXFYz6kFcCidpYW0uZ29vZ2xlYXBpcy5jb20vT3JnYW5pemF0aW9uTG9jYXRpb24SMW9y
Z2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn3qQUoKIWlh
bS5nb29nbGVhcGlzLmNvbS9Gb2xkZXJMb2NhdGlvbhIlZm9sZGVycy97Zm9sZGVyfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufUq4VQoHEgUOAIEDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAFgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJ
CgIDAxIDFQAjCgkKAgMEEgMWADAKCQoCAwUSAxcANgoJCgIDBhIDGAAtCgkKAgMHEgMZACUK
CQoCAwgSAxoAKgoICgEIEgMcADAKCQoCCCUSAxwAMAoICgEIEgMdAEAKCQoCCAsSAx0AQAoI
CgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADsKCQoCCAgSAx8AOwoICgEIEgMgACoKCQoC
CAESAyAAKgoICgEIEgMhADAKCQoCCCkSAyEAMAoJCgEIEgQiACUCCgwKBAidCAASBCIAJQIK
CQoBCBIEJgApAgoMCgQInQgBEgQmACkCCl8KAgYAEgUtAKQBARpSIEFuIGludGVyZmFjZSBm
b3IgbWFuYWdpbmcgSWRlbnRpdHkgYW5kIEFjY2VzcyBNYW5hZ2VtZW50IChJQU0pIHBvbGlj
eQogYmluZGluZ3MuCgoKCgMGAAESAy0IFgoKCgMGAAMSAy4COgoMCgUGAAOZCBIDLgI6CgsK
AwYAAxIELwIwNwoNCgUGAAOaCBIELwIwNwrZAQoEBgACABIENQJJAxrKASBDcmVhdGVzIGEg
cG9saWN5IGJpbmRpbmcgYW5kIHJldHVybnMgYSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgog
Q2FsbGVycyB3aWxsIG5lZWQgdGhlIElBTSBwZXJtaXNzaW9ucyBvbiBib3RoIHRoZSBwb2xp
Y3kgYW5kIHRhcmdldC4KIEFmdGVyIHRoZSBiaW5kaW5nIGlzIGNyZWF0ZWQsIHRoZSBwb2xp
Y3kgaXMgYXBwbGllZCB0byB0aGUgdGFyZ2V0LgoKDAoFBgACAAESAzUGGQoMCgUGAAIAAhID
NRo0CgwKBQYAAgADEgM2DysKDQoFBgACAAQSBDcEQgYKEQoJBgACAASwyrwiEgQ3BEIGCg0K
BQYAAgAEEgRDBEQyChAKCAYAAgAEmwgAEgRDBEQyCg0KBQYAAgAEEgRFBEgGCg8KBwYAAgAE
mQgSBEUESAYKJgoEBgACARIETAJXAxoYIEdldHMgYSBwb2xpY3kgYmluZGluZy4KCgwKBQYA
AgEBEgNMBhYKDAoFBgACAQISA0wXLgoMCgUGAAIBAxIDTDlGCg0KBQYAAgEEEgRNBFUGChEK
CQYAAgEEsMq8IhIETQRVBgoMCgUGAAIBBBIDVgQyCg8KCAYAAgEEmwgAEgNWBDIK4QEKBAYA
AgISBFwCbwMa0gEgVXBkYXRlcyBhIHBvbGljeSBiaW5kaW5nIGFuZCByZXR1cm5zIGEgbG9u
Zy1ydW5uaW5nIG9wZXJhdGlvbi4KIENhbGxlcnMgd2lsbCBuZWVkIHRoZSBJQU0gcGVybWlz
c2lvbnMgb24gdGhlIHBvbGljeSBhbmQgdGFyZ2V0IGluIHRoZQogYmluZGluZyB0byB1cGRh
dGUuIFRhcmdldCBhbmQgcG9saWN5IGFyZSBpbW11dGFibGUgYW5kIGNhbm5vdCBiZSB1cGRh
dGVkLgoKDAoFBgACAgESA1wGGQoMCgUGAAICAhIDXBo0CgwKBQYAAgIDEgNdDysKDQoFBgAC
AgQSBF4EaQYKEQoJBgACAgSwyrwiEgReBGkGCgwKBQYAAgIEEgNqBEgKDwoIBgACAgSbCAAS
A2oESAoNCgUGAAICBBIEawRuBgoPCgcGAAICBJkIEgRrBG4GCuEBCgQGAAIDEgV0AoQBAxrR
ASBEZWxldGVzIGEgcG9saWN5IGJpbmRpbmcgYW5kIHJldHVybnMgYSBsb25nLXJ1bm5pbmcg
b3BlcmF0aW9uLgogQ2FsbGVycyB3aWxsIG5lZWQgdGhlIElBTSBwZXJtaXNzaW9ucyBvbiBi
b3RoIHRoZSBwb2xpY3kgYW5kIHRhcmdldC4KIEFmdGVyIHRoZSBiaW5kaW5nIGlzIGRlbGV0
ZWQsIHRoZSBwb2xpY3kgbm8gbG9uZ2VyIGFwcGxpZXMgdG8gdGhlIHRhcmdldC4KCgwKBQYA
AgMBEgN0BhkKDAoFBgACAwISA3QaNAoMCgUGAAIDAxIDdQ8rCg0KBQYAAgMEEgR2BH4GChEK
CQYAAgMEsMq8IhIEdgR+BgoMCgUGAAIDBBIDfwQyCg8KCAYAAgMEmwgAEgN/BDIKDwoFBgAC
AwQSBoABBIMBBgoRCgcGAAIDBJkIEgaAAQSDAQYKKAoEBgACBBIGhwECkwEDGhggTGlzdHMg
cG9saWN5IGJpbmRpbmdzLgoKDQoFBgACBAESBIcBBhgKDQoFBgACBAISBIcBGTIKDQoFBgAC
BAMSBIgBDykKDwoFBgACBAQSBokBBJEBBgoTCgkGAAIEBLDKvCISBokBBJEBBgoNCgUGAAIE
BBIEkgEENAoQCggGAAIEBJsIABIEkgEENApxCgQGAAIFEgaXAQKjAQMaYSBTZWFyY2ggcG9s
aWN5IGJpbmRpbmdzIGJ5IHRhcmdldC4gUmV0dXJucyBhbGwgcG9saWN5IGJpbmRpbmcgb2Jq
ZWN0cyBib3VuZAogZGlyZWN0bHkgdG8gdGFyZ2V0LgoKDQoFBgACBQESBJcBBiAKDQoFBgAC
BQISBJcBIUIKDQoFBgACBQMSBJgBDzEKDwoFBgACBQQSBpkBBKEBBgoTCgkGAAIFBLDKvCIS
BpkBBKEBBgoNCgUGAAIFBBIEogEEOwoQCggGAAIFBJsIABIEogEEOwo/CgIEABIGpwEAxwEB
GjEgUmVxdWVzdCBtZXNzYWdlIGZvciBDcmVhdGVQb2xpY3lCaW5kaW5nIG1ldGhvZC4KCgsK
AwQAARIEpwEIIgqpAwoEBAACABIGsgECtwEEGpgDIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJl
c291cmNlIHdoZXJlIHRoaXMgcG9saWN5IGJpbmRpbmcgd2lsbCBiZSBjcmVhdGVkLgogVGhl
IGJpbmRpbmcgcGFyZW50IGlzIHRoZSBjbG9zZXN0IFJlc291cmNlIE1hbmFnZXIgcmVzb3Vy
Y2UgKHByb2plY3QsCiBmb2xkZXIgb3Igb3JnYW5pemF0aW9uKSB0byB0aGUgYmluZGluZyB0
YXJnZXQuCgogRm9ybWF0OgoKICogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufWAKICogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbn1gCiAqIGBmb2xkZXJzL3tmb2xkZXJfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259
YAogKiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0
aW9ufWAKCg0KBQQAAgAFEgSyAQIICg0KBQQAAgABEgSyAQkPCg0KBQQAAgADEgSyARITCg8K
BQQAAgAIEgayARS3AQMKEAoIBAACAAicCAASBLMBBCoKEQoHBAACAAifCBIGtAEEtgEFCqYC
CgQEAAIBEgS/AQJIGpcCIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgcG9saWN5
IGJpbmRpbmcsIHdoaWNoIHdpbGwgYmVjb21lIHRoZSBmaW5hbAogY29tcG9uZW50IG9mIHRo
ZSBwb2xpY3kgYmluZGluZydzIHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBtdXN0IHN0
YXJ0IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIGZvbGxvd2VkIGJ5IHVwIHRvIDYyCiBsb3dl
cmNhc2UgbGV0dGVycywgbnVtYmVycywgaHlwaGVucywgb3IgZG90cy4gUGF0dGVybiwKIC9b
YS16XVthLXowLTktXC5dezIsNjJ9Ly4KCg0KBQQAAgEFEgS/AQIICg0KBQQAAgEBEgS/AQka
Cg0KBQQAAgEDEgS/AR0eCg0KBQQAAgEIEgS/AR9HChAKCAQAAgEInAgAEgS/ASBGCjcKBAQA
AgISBMIBAkwaKSBSZXF1aXJlZC4gVGhlIHBvbGljeSBiaW5kaW5nIHRvIGNyZWF0ZS4KCg0K
BQQAAgIGEgTCAQIPCg0KBQQAAgIBEgTCARAeCg0KBQQAAgIDEgTCASEiCg0KBQQAAgIIEgTC
ASNLChAKCAQAAgIInAgAEgTCASRKCm4KBAQAAgMSBMYBAkIaYCBPcHRpb25hbC4gSWYgc2V0
LCB2YWxpZGF0ZSB0aGUgcmVxdWVzdCBhbmQgcHJldmlldyB0aGUgY3JlYXRpb24sIGJ1dCBk
byBub3QKIGFjdHVhbGx5IHBvc3QgaXQuCgoNCgUEAAIDBRIExgECBgoNCgUEAAIDARIExgEH
FAoNCgUEAAIDAxIExgEXGAoNCgUEAAIDCBIExgEZQQoQCggEAAIDCJwIABIExgEaQAo8CgIE
ARIGygEA2QEBGi4gUmVxdWVzdCBtZXNzYWdlIGZvciBHZXRQb2xpY3lCaW5kaW5nIG1ldGhv
ZC4KCgsKAwQBARIEygEIHwqrAwoEBAECABIG0wEC2AEEGpoDIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUgcG9saWN5IGJpbmRpbmcgdG8gcmV0cmlldmUuCgogRm9ybWF0OgoKICogYHBy
b2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5n
cy97cG9saWN5X2JpbmRpbmdfaWR9YAogKiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9saWN5X2JpbmRpbmdfaWR9
YAogKiBgZm9sZGVycy97Zm9sZGVyX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lC
aW5kaW5ncy97cG9saWN5X2JpbmRpbmdfaWR9YAogKiBgb3JnYW5pemF0aW9ucy97b3JnYW5p
emF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9saWN5
X2JpbmRpbmdfaWR9YAoKDQoFBAECAAUSBNMBAggKDQoFBAECAAESBNMBCQ0KDQoFBAECAAMS
BNMBEBEKDwoFBAECAAgSBtMBEtgBAwoQCggEAQIACJwIABIE1AEEKgoRCgcEAQIACJ8IEgbV
AQTXAQUKPwoCBAISBtwBAOoBARoxIFJlcXVlc3QgbWVzc2FnZSBmb3IgVXBkYXRlUG9saWN5
QmluZGluZyBtZXRob2QuCgoLCgMEAgESBNwBCCIKjwEKBAQCAgASBOEBAkwagAEgUmVxdWly
ZWQuIFRoZSBwb2xpY3kgYmluZGluZyB0byB1cGRhdGUuCgogVGhlIHBvbGljeSBiaW5kaW5n
J3MgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIHBvbGljeSBiaW5kaW5n
IHRvCiB1cGRhdGUuCgoNCgUEAgIABhIE4QECDwoNCgUEAgIAARIE4QEQHgoNCgUEAgIAAxIE
4QEhIgoNCgUEAgIACBIE4QEjSwoQCggEAgIACJwIABIE4QEkSgpsCgQEAgIBEgTlAQJCGl4g
T3B0aW9uYWwuIElmIHNldCwgdmFsaWRhdGUgdGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhl
IHVwZGF0ZSwgYnV0IGRvIG5vdAogYWN0dWFsbHkgcG9zdCBpdC4KCg0KBQQCAgEFEgTlAQIG
Cg0KBQQCAgEBEgTlAQcUCg0KBQQCAgEDEgTlARcYCg0KBQQCAgEIEgTlARlBChAKCAQCAgEI
nAgAEgTlARpACjgKBAQCAgISBugBAukBLxooIE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVs
ZHMgdG8gdXBkYXRlCgoNCgUEAgICBhIE6AECGwoNCgUEAgICARIE6AEcJwoNCgUEAgICAxIE
6AEqKwoNCgUEAgICCBIE6QEGLgoQCggEAgICCJwIABIE6QEHLQo/CgIEAxIG7QEAhAIBGjEg
UmVxdWVzdCBtZXNzYWdlIGZvciBEZWxldGVQb2xpY3lCaW5kaW5nIG1ldGhvZC4KCgsKAwQD
ARIE7QEIIgqpAwoEBAMCABIG9gEC+wEEGpgDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
cG9saWN5IGJpbmRpbmcgdG8gZGVsZXRlLgoKIEZvcm1hdDoKCiAqIGBwcm9qZWN0cy97cHJv
amVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9i
aW5kaW5nX2lkfWAKICogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKICogYGZvbGRl
cnMve2ZvbGRlcl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3Bv
bGljeV9iaW5kaW5nX2lkfWAKICogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lk
fWAKCg0KBQQDAgAFEgT2AQIICg0KBQQDAgABEgT2AQkNCg0KBQQDAgADEgT2ARARCg8KBQQD
AgAIEgb2ARL7AQMKEAoIBAMCAAicCAASBPcBBCoKEQoHBAMCAAifCBIG+AEE+gEFCnAKBAQD
AgESBP8BAjsaYiBPcHRpb25hbC4gVGhlIGV0YWcgb2YgdGhlIHBvbGljeSBiaW5kaW5nLgog
SWYgdGhpcyBpcyBwcm92aWRlZCwgaXQgbXVzdCBtYXRjaCB0aGUgc2VydmVyJ3MgZXRhZy4K
Cg0KBQQDAgEFEgT/AQIICg0KBQQDAgEBEgT/AQkNCg0KBQQDAgEDEgT/ARARCg0KBQQDAgEI
EgT/ARI6ChAKCAQDAgEInAgAEgT/ARM5Cm4KBAQDAgISBIMCAkIaYCBPcHRpb25hbC4gSWYg
c2V0LCB2YWxpZGF0ZSB0aGUgcmVxdWVzdCBhbmQgcHJldmlldyB0aGUgZGVsZXRpb24sIGJ1
dCBkbyBub3QKIGFjdHVhbGx5IHBvc3QgaXQuCgoNCgUEAwICBRIEgwICBgoNCgUEAwICARIE
gwIHFAoNCgUEAwICAxIEgwIXGAoNCgUEAwICCBIEgwIZQQoQCggEAwICCJwIABIEgwIaQAo+
CgIEBBIGhwIAsgIBGjAgUmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0UG9saWN5QmluZGluZ3Mg
bWV0aG9kLgoKCwoDBAQBEgSHAgghCrcCCgQEBAIAEgaRAgKWAgQapgIgUmVxdWlyZWQuIFRo
ZSBwYXJlbnQgcmVzb3VyY2UsIHdoaWNoIG93bnMgdGhlIGNvbGxlY3Rpb24gb2YgcG9saWN5
CiBiaW5kaW5ncy4KCiBGb3JtYXQ6CgogKiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0
aW9ucy97bG9jYXRpb259YAogKiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlv
bnMve2xvY2F0aW9ufWAKICogYGZvbGRlcnMve2ZvbGRlcl9pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn1gCiAqIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97
bG9jYXRpb259YAoKDQoFBAQCAAUSBJECAggKDQoFBAQCAAESBJECCQ8KDQoFBAQCAAMSBJEC
EhMKDwoFBAQCAAgSBpECFJYCAwoQCggEBAIACJwIABIEkgIEKgoRCgcEBAIACJ8IEgaTAgSV
AgUKsAEKBAQEAgESBJwCAj8aoQEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBw
b2xpY3kgYmluZGluZ3MgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkKIHJldHVybiBmZXdl
ciB0aGFuIHRoaXMgdmFsdWUuCgogVGhlIGRlZmF1bHQgdmFsdWUgaXMgNTAuIFRoZSBtYXhp
bXVtIHZhbHVlIGlzIDEwMDAuCgoNCgUEBAIBBRIEnAICBwoNCgUEBAIBARIEnAIIEQoNCgUE
BAIBAxIEnAIUFQoNCgUEBAIBCBIEnAIWPgoQCggEBAIBCJwIABIEnAIXPQqHAgoEBAQCAhIE
owICQRr4ASBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlv
dXMgYExpc3RQb2xpY3lCaW5kaW5nc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2
ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBh
cmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RQb2xpY3lCaW5kaW5nc2AgbXVzdAogbWF0Y2gg
dGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQEAgIFEgSjAgII
Cg0KBQQEAgIBEgSjAgkTCg0KBQQEAgIDEgSjAhYXCg0KBQQEAgIIEgSjAhhAChAKCAQEAgII
nAgAEgSjAhk/CqEDCgQEBAIDEgSxAgI9GpIDIE9wdGlvbmFsLiBBbiBleHByZXNzaW9uIGZv
ciBmaWx0ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhlIHJlcXVlc3QuIEZpbHRlcgogcnVsZXMg
YXJlIGNhc2UgaW5zZW5zaXRpdmUuIFNvbWUgZWxpZ2libGUgZmllbGRzIGZvciBmaWx0ZXJp
bmcgYXJlIHRoZQogZm9sbG93aW5nOgoKICsgYHRhcmdldGAKICsgYHBvbGljeWAKCiBTb21l
IGV4YW1wbGVzIG9mIGZpbHRlciBxdWVyaWVzOgoKICogYHRhcmdldDpleCpgOiBUaGUgYmlu
ZGluZyB0YXJnZXQncyBuYW1lIHN0YXJ0cyB3aXRoICJleCIuCiAqIGB0YXJnZXQ6ZXhhbXBs
ZWA6IFRoZSBiaW5kaW5nIHRhcmdldCdzIG5hbWUgaXMgYGV4YW1wbGVgLgogKiBgcG9saWN5
OmV4YW1wbGVgOiBUaGUgYmluZGluZyBwb2xpY3kncyBuYW1lIGlzIGBleGFtcGxlYC4KCg0K
BQQEAgMFEgSxAgIICg0KBQQEAgMBEgSxAgkPCg0KBQQEAgMDEgSxAhITCg0KBQQEAgMIEgSx
AhQ8ChAKCAQEAgMInAgAEgSxAhU7Cj8KAgQFEga1AgC8AgEaMSBSZXNwb25zZSBtZXNzYWdl
IGZvciBMaXN0UG9saWN5QmluZGluZ3MgbWV0aG9kLgoKCwoDBAUBEgS1AggiCj4KBAQFAgAS
BLcCAi0aMCBUaGUgcG9saWN5IGJpbmRpbmdzIGZyb20gdGhlIHNwZWNpZmllZCBwYXJlbnQu
CgoNCgUEBQIABBIEtwICCgoNCgUEBQIABhIEtwILGAoNCgUEBQIAARIEtwIZKAoNCgUEBQIA
AxIEtwIrLAqaAQoEBAUCARIEuwICRhqLASBPcHRpb25hbC4gQSB0b2tlbiwgd2hpY2ggY2Fu
IGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0CiBwYWdlLiBJ
ZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2Vz
LgoKDQoFBAUCAQUSBLsCAggKDQoFBAUCAQESBLsCCRgKDQoFBAUCAQMSBLsCGxwKDQoFBAUC
AQgSBLsCHUUKEAoIBAUCAQicCAASBLsCHkQKRgoCBAYSBr8CAPcCARo4IFJlcXVlc3QgbWVz
c2FnZSBmb3IgU2VhcmNoVGFyZ2V0UG9saWN5QmluZGluZ3MgbWV0aG9kLgoKCwoDBAYBEgS/
AggpCpsECgQEBgIAEgTKAgI9GowEIFJlcXVpcmVkLiBUaGUgdGFyZ2V0IHJlc291cmNlLCB3
aGljaCBpcyBib3VuZCB0byB0aGUgcG9saWN5IGluIHRoZSBiaW5kaW5nLgoKIEZvcm1hdDoK
CiAqIGAvL2lhbS5nb29nbGVhcGlzLmNvbS9sb2NhdGlvbnMvZ2xvYmFsL3dvcmtmb3JjZVBv
b2xzL1BPT0xfSURgCiAqIGAvL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9QUk9KRUNU
X05VTUJFUi9sb2NhdGlvbnMvZ2xvYmFsL3dvcmtsb2FkSWRlbnRpdHlQb29scy9QT09MX0lE
YAogKiBgLy9pYW0uZ29vZ2xlYXBpcy5jb20vbG9jYXRpb25zL2dsb2JhbC93b3Jrc3BhY2Uv
V09SS1NQQUNFX0lEYAogKiBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNv
bS9wcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9YAogKiBgLy9jbG91ZHJlc291cmNlbWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9mb2xkZXJzL3tmb2xkZXJfaWR9YAogKiBgLy9jbG91ZHJlc291
cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25f
aWR9YAoKDQoFBAYCAAUSBMoCAggKDQoFBAYCAAESBMoCCQ8KDQoFBAYCAAMSBMoCEhMKDQoF
BAYCAAgSBMoCFDwKEAoIBAYCAAicCAASBMoCFTsKsAEKBAQGAgESBNACAj8aoQEgT3B0aW9u
YWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBwb2xpY3kgYmluZGluZ3MgdG8gcmV0dXJuLiBU
aGUgc2VydmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCgogVGhlIGRl
ZmF1bHQgdmFsdWUgaXMgNTAuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDAuCgoNCgUEBgIB
BRIE0AICBwoNCgUEBgIBARIE0AIIEQoNCgUEBgIBAxIE0AIUFQoNCgUEBgIBCBIE0AIWPgoQ
CggEBgIBCJwIABIE0AIXPQqnAgoEBAYCAhIE2QICQRqYAiBPcHRpb25hbC4gQSBwYWdlIHRv
a2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIGBTZWFyY2hUYXJnZXRQb2xpY3lCaW5k
aW5nc1JlcXVlc3RgIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNl
cXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHBy
b3ZpZGVkIHRvCiBgU2VhcmNoVGFyZ2V0UG9saWN5QmluZGluZ3NSZXF1ZXN0YCBtdXN0IG1h
dGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlCiBwYWdlIHRva2VuLgoKDQoFBAYCAgUS
BNkCAggKDQoFBAYCAgESBNkCCRMKDQoFBAYCAgMSBNkCFhcKDQoFBAYCAggSBNkCGEAKEAoI
BAYCAgicCAASBNkCGT8KlQMKBAQGAgMSBuUCAuoCBBqEAyBSZXF1aXJlZC4gVGhlIHBhcmVu
dCByZXNvdXJjZSB3aGVyZSB0aGlzIHNlYXJjaCB3aWxsIGJlIHBlcmZvcm1lZC4gVGhpcwog
c2hvdWxkIGJlIHRoZSBuZWFyZXN0IFJlc291cmNlIE1hbmFnZXIgcmVzb3VyY2UgKHByb2pl
Y3QsIGZvbGRlciwgb3IKIG9yZ2FuaXphdGlvbikgdG8gdGhlIHRhcmdldC4KCiBGb3JtYXQ6
CgogKiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAogKiBg
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKICogYGZv
bGRlcnMve2ZvbGRlcl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCiAqIGBvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAYCAwUS
BOUCAggKDQoFBAYCAwESBOUCCQ8KDQoFBAYCAwMSBOUCEhMKDwoFBAYCAwgSBuUCFOoCAwoQ
CggEBgIDCJwIABIE5gIEKgoRCgcEBgIDCJ8IEgbnAgTpAgUK2gIKBAQGAgQSBPYCAj0aywIg
T3B0aW9uYWwuIEZpbHRlcmluZyBjdXJyZW50bHkgb25seSBzdXBwb3J0cyB0aGUga2luZCBv
ZiBwb2xpY2llcyB0byByZXR1cm4sCiBhbmQgbXVzdCBiZSBpbiB0aGUgZm9ybWF0ICJwb2xp
Y3lfa2luZD17cG9saWN5X2tpbmR9Ii4KCiBJZiBTdHJpbmcgaXMgZW1wdHksIGJpbmRpbmdz
IGJvdW5kIHRvIGFsbCBraW5kcyBvZiBwb2xpY2llcyB3b3VsZCBiZQogcmV0dXJuZWQuCgog
VGhlIG9ubHkgc3VwcG9ydGVkIHZhbHVlcyBhcmUgdGhlIGZvbGxvd2luZzoKCiAqICJwb2xp
Y3lfa2luZD1QUklOQ0lQQUxfQUNDRVNTX0JPVU5EQVJZIiwKICogInBvbGljeV9raW5kPUFD
Q0VTUyIKCg0KBQQGAgQFEgT2AgIICg0KBQQGAgQBEgT2AgkPCg0KBQQGAgQDEgT2AhITCg0K
BQQGAgQIEgT2AhQ8ChAKCAQGAgQInAgAEgT2AhU7CkcKAgQHEgb6AgCBAwEaOSBSZXNwb25z
ZSBtZXNzYWdlIGZvciBTZWFyY2hUYXJnZXRQb2xpY3lCaW5kaW5ncyBtZXRob2QuCgoLCgME
BwESBPoCCCoKQgoEBAcCABIE/AICLRo0IFRoZSBwb2xpY3kgYmluZGluZ3MgYm91bmQgdG8g
dGhlIHNwZWNpZmllZCB0YXJnZXQuCgoNCgUEBwIABBIE/AICCgoNCgUEBwIABhIE/AILGAoN
CgUEBwIAARIE/AIZKAoNCgUEBwIAAxIE/AIrLAqaAQoEBAcCARIEgAMCRhqLASBPcHRpb25h
bC4gQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJp
ZXZlIHRoZSBuZXh0CiBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFy
ZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAcCAQUSBIADAggKDQoFBAcCAQESBIADCRgK
DQoFBAcCAQMSBIADGxwKDQoFBAcCAQgSBIADHUUKEAoIBAcCAQicCAASBIADHkRiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest ===
    # Fields for CreatePolicyBindingRequest
    # Field: parent Type: 9 ()
    # Field: policy_binding_id Type: 9 ()
    # Field: policy_binding Type: 11 (.google.iam.v3.PolicyBinding)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3::PolicyBindingsService::GetPolicyBindingRequest ===
    # Fields for GetPolicyBindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V3::PolicyBindingsService::UpdatePolicyBindingRequest ===
    # Fields for UpdatePolicyBindingRequest
    # Field: policy_binding Type: 11 (.google.iam.v3.PolicyBinding)
    # Field: validate_only Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Iam::V3::PolicyBindingsService::DeletePolicyBindingRequest ===
    # Fields for DeletePolicyBindingRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsRequest ===
    # Fields for ListPolicyBindingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsResponse ===
    # Fields for ListPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsRequest ===
    # Fields for SearchTargetPolicyBindingsRequest
    # Field: target Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsResponse ===
    # Fields for SearchTargetPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Iam::V3::PolicyBindingsService::PolicyBindingsClient ===
package Google::Iam::V3::PolicyBindingsService::PolicyBindingsClient;

=pod

=head2 Service Client: Google::Iam::V3::PolicyBindingsService::PolicyBindingsClient

Client stub representing the remote C<PolicyBindings> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<iam.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iam.googleapis.com:443' );

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

sub create_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PolicyBindings',
        method         => 'CreatePolicyBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PolicyBindingsService::GetPolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PolicyBindings',
        method         => 'GetPolicyBinding',
        request        => $req,
        response_class => 'Google::Iam::V3::PolicyBindingResources::PolicyBinding',
    });
}

sub update_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PolicyBindingsService::UpdatePolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PolicyBindings',
        method         => 'UpdatePolicyBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PolicyBindingsService::DeletePolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PolicyBindings',
        method         => 'DeletePolicyBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PolicyBindings',
        method         => 'ListPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsResponse',
    });
}

sub search_target_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PolicyBindings',
        method         => 'SearchTargetPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3::PolicyBindingsService - Compiled Protocol Buffers messages for google/iam/v3/policy_bindings_service.proto

=head1 SYNOPSIS

    use Google::Iam::V3::PolicyBindingsService;

    my $msg = Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest->new({
        parent => $parent,
        policy_binding_id => $policy_binding_id,
        policy_binding => $policy_binding,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/policy_bindings_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest

Request message for CreatePolicyBinding method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this policy binding will be created.
The binding parent is the closest Resource Manager resource (project,
folder or organization) to the binding target.

Format:

* `projects/{project_id}/locations/{location}`
* `projects/{project_number}/locations/{location}`
* `folders/{folder_id}/locations/{location}`
* `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->policy_binding_id() >> / C<< $msg->policy_binding_id($value) >>

Type: C<String>

Required. The ID to use for the policy binding, which will become the final
component of the policy binding's resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, hyphens, or dots. Pattern,
/[a-z][a-z0-9-\.]{2,62}/.

=item * C<< $msg->policy_binding() >> / C<< $msg->policy_binding($value) >>

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding>)

Required. The policy binding to create.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the creation, but do not
actually post it.

=back

=head2 Google::Iam::V3::PolicyBindingsService::GetPolicyBindingRequest

Request message for GetPolicyBinding method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the policy binding to retrieve.

Format:

* `projects/{project_id}/locations/{location}/policyBindings/{policy_binding_id}`
* `projects/{project_number}/locations/{location}/policyBindings/{policy_binding_id}`
* `folders/{folder_id}/locations/{location}/policyBindings/{policy_binding_id}`
* `organizations/{organization_id}/locations/{location}/policyBindings/{policy_binding_id}`

=back

=head2 Google::Iam::V3::PolicyBindingsService::UpdatePolicyBindingRequest

Request message for UpdatePolicyBinding method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_binding() >> / C<< $msg->policy_binding($value) >>

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding>)

Required. The policy binding to update.

The policy binding's `name` field is used to identify the policy binding to
update.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the update, but do not
actually post it.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update

=back

=head2 Google::Iam::V3::PolicyBindingsService::DeletePolicyBindingRequest

Request message for DeletePolicyBinding method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the policy binding to delete.

Format:

* `projects/{project_id}/locations/{location}/policyBindings/{policy_binding_id}`
* `projects/{project_number}/locations/{location}/policyBindings/{policy_binding_id}`
* `folders/{folder_id}/locations/{location}/policyBindings/{policy_binding_id}`
* `organizations/{organization_id}/locations/{location}/policyBindings/{policy_binding_id}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag of the policy binding.
If this is provided, it must match the server's etag.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the deletion, but do not
actually post it.

=back

=head2 Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsRequest

Request message for ListPolicyBindings method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource, which owns the collection of policy
bindings.

Format:

* `projects/{project_id}/locations/{location}`
* `projects/{project_number}/locations/{location}`
* `folders/{folder_id}/locations/{location}`
* `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policy bindings to return. The service may
return fewer than this value.

The default value is 50. The maximum value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListPolicyBindings` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListPolicyBindings` must
match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Filter
rules are case insensitive. Some eligible fields for filtering are the
following:

+ `target`
+ `policy`

Some examples of filter queries:

* `target:ex*`: The binding target's name starts with "ex".
* `target:example`: The binding target's name is `example`.
* `policy:example`: The binding policy's name is `example`.

=back

=head2 Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsResponse

Response message for ListPolicyBindings method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding>)

The policy bindings from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsRequest

Request message for SearchTargetPolicyBindings method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Required. The target resource, which is bound to the policy in the binding.

Format:

* `//iam.googleapis.com/locations/global/workforcePools/POOL_ID`
* `//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID`
* `//iam.googleapis.com/locations/global/workspace/WORKSPACE_ID`
* `//cloudresourcemanager.googleapis.com/projects/{project_number}`
* `//cloudresourcemanager.googleapis.com/folders/{folder_id}`
* `//cloudresourcemanager.googleapis.com/organizations/{organization_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policy bindings to return. The service may
return fewer than this value.

The default value is 50. The maximum value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`SearchTargetPolicyBindingsRequest` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`SearchTargetPolicyBindingsRequest` must match the call that provided the
page token.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this search will be performed. This
should be the nearest Resource Manager resource (project, folder, or
organization) to the target.

Format:

* `projects/{project_id}/locations/{location}`
* `projects/{project_number}/locations/{location}`
* `folders/{folder_id}/locations/{location}`
* `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering currently only supports the kind of policies to return,
and must be in the format "policy_kind={policy_kind}".

If String is empty, bindings bound to all kinds of policies would be
returned.

The only supported values are the following:

* "policy_kind=PRINCIPAL_ACCESS_BOUNDARY",
* "policy_kind=ACCESS"

=back

=head2 Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsResponse

Response message for SearchTargetPolicyBindings method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding>)

The policy bindings bound to the specified target.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::PolicyBindingsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
