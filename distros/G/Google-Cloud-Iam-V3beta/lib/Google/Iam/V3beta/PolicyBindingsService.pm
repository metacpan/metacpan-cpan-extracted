package Google::Iam::V3beta::PolicyBindingsService;

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
    eval { require Google::Iam::V3beta::OperationMetadata };
    eval { require Google::Iam::V3beta::PolicyBindingResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvaWFtL3YzYmV0YS9wb2xpY3lfYmluZGluZ3Nfc2VydmljZS5wcm90bxIRZ29v
Z2xlLmlhbS52M2JldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGipnb29nbGUvaWFtL3YzYmV0YS9vcGVyYXRpb25fbWV0
YWRhdGEucHJvdG8aMGdvb2dsZS9pYW0vdjNiZXRhL3BvbGljeV9iaW5kaW5nX3Jlc291cmNl
cy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9w
cm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i
hwIKGkNyZWF0ZVBvbGljeUJpbmRpbmdSZXF1ZXN0EkAKBnBhcmVudBgBIAEoCUIo4EEC+kEi
EiBpYW0uZ29vZ2xlYXBpcy5jb20vUG9saWN5QmluZGluZ1IGcGFyZW50Ei8KEXBvbGljeV9i
aW5kaW5nX2lkGAIgASgJQgPgQQJSD3BvbGljeUJpbmRpbmdJZBJMCg5wb2xpY3lfYmluZGlu
ZxgDIAEoCzIgLmdvb2dsZS5pYW0udjNiZXRhLlBvbGljeUJpbmRpbmdCA+BBAlINcG9saWN5
QmluZGluZxIoCg12YWxpZGF0ZV9vbmx5GAQgASgIQgPgQQFSDHZhbGlkYXRlT25seSJXChdH
ZXRQb2xpY3lCaW5kaW5nUmVxdWVzdBI8CgRuYW1lGAEgASgJQijgQQL6QSIKIGlhbS5nb29n
bGVhcGlzLmNvbS9Qb2xpY3lCaW5kaW5nUgRuYW1lItYBChpVcGRhdGVQb2xpY3lCaW5kaW5n
UmVxdWVzdBJMCg5wb2xpY3lfYmluZGluZxgBIAEoCzIgLmdvb2dsZS5pYW0udjNiZXRhLlBv
bGljeUJpbmRpbmdCA+BBAlINcG9saWN5QmluZGluZxIoCg12YWxpZGF0ZV9vbmx5GAIgASgI
QgPgQQFSDHZhbGlkYXRlT25seRJACgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayKdAQoaRGVsZXRlUG9saWN5QmluZGlu
Z1JlcXVlc3QSPAoEbmFtZRgBIAEoCUIo4EEC+kEiCiBpYW0uZ29vZ2xlYXBpcy5jb20vUG9s
aWN5QmluZGluZ1IEbmFtZRIXCgRldGFnGAIgASgJQgPgQQFSBGV0YWcSKAoNdmFsaWRhdGVf
b25seRgDIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHkiwAEKGUxpc3RQb2xpY3lCaW5kaW5nc1Jl
cXVlc3QSQAoGcGFyZW50GAEgASgJQijgQQL6QSISIGlhbS5nb29nbGVhcGlzLmNvbS9Qb2xp
Y3lCaW5kaW5nUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIK
CnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEB
UgZmaWx0ZXIilAEKGkxpc3RQb2xpY3lCaW5kaW5nc1Jlc3BvbnNlEkkKD3BvbGljeV9iaW5k
aW5ncxgBIAMoCzIgLmdvb2dsZS5pYW0udjNiZXRhLlBvbGljeUJpbmRpbmdSDnBvbGljeUJp
bmRpbmdzEisKD25leHRfcGFnZV90b2tlbhgCIAEoCUID4EEBUg1uZXh0UGFnZVRva2VuIuUB
CiFTZWFyY2hUYXJnZXRQb2xpY3lCaW5kaW5nc1JlcXVlc3QSGwoGdGFyZ2V0GAEgASgJQgPg
QQJSBnRhcmdldBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90
b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SQAoGcGFyZW50GAUgASgJQijgQQL6QSISIGlh
bS5nb29nbGVhcGlzLmNvbS9Qb2xpY3lCaW5kaW5nUgZwYXJlbnQSGwoGZmlsdGVyGAYgASgJ
QgPgQQFSBmZpbHRlciKcAQoiU2VhcmNoVGFyZ2V0UG9saWN5QmluZGluZ3NSZXNwb25zZRJJ
Cg9wb2xpY3lfYmluZGluZ3MYASADKAsyIC5nb29nbGUuaWFtLnYzYmV0YS5Qb2xpY3lCaW5k
aW5nUg5wb2xpY3lCaW5kaW5ncxIrCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlCA+BBAVINbmV4
dFBhZ2VUb2tlbjKMEgoOUG9saWN5QmluZGluZ3MSnAMKE0NyZWF0ZVBvbGljeUJpbmRpbmcS
LS5nb29nbGUuaWFtLnYzYmV0YS5DcmVhdGVQb2xpY3lCaW5kaW5nUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24itgKC0+STAuABIjYvdjNiZXRhL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKn0vcG9saWN5QmluZGluZ3M6DnBvbGljeV9iaW5kaW5nWkci
NS92M2JldGEve3BhcmVudD1mb2xkZXJzLyovbG9jYXRpb25zLyp9L3BvbGljeUJpbmRpbmdz
Og5wb2xpY3lfYmluZGluZ1pNIjsvdjNiZXRhL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xv
Y2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nczoOcG9saWN5X2JpbmRpbmfaQSdwYXJlbnQscG9s
aWN5X2JpbmRpbmcscG9saWN5X2JpbmRpbmdfaWTKQSIKDVBvbGljeUJpbmRpbmcSEU9wZXJh
dGlvbk1ldGFkYXRhEqECChBHZXRQb2xpY3lCaW5kaW5nEiouZ29vZ2xlLmlhbS52M2JldGEu
R2V0UG9saWN5QmluZGluZ1JlcXVlc3QaIC5nb29nbGUuaWFtLnYzYmV0YS5Qb2xpY3lCaW5k
aW5nIr4BgtPkkwKwARI2L3YzYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Bv
bGljeUJpbmRpbmdzLyp9WjcSNS92M2JldGEve25hbWU9Zm9sZGVycy8qL2xvY2F0aW9ucy8q
L3BvbGljeUJpbmRpbmdzLyp9Wj0SOy92M2JldGEve25hbWU9b3JnYW5pemF0aW9ucy8qL2xv
Y2F0aW9ucy8qL3BvbGljeUJpbmRpbmdzLyp92kEEbmFtZRK8AwoTVXBkYXRlUG9saWN5Qmlu
ZGluZxItLmdvb2dsZS5pYW0udjNiZXRhLlVwZGF0ZVBvbGljeUJpbmRpbmdSZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLWAoLT5JMCjQIyRS92M2JldGEve3BvbGlj
eV9iaW5kaW5nLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9wb2xpY3lCaW5kaW5ncy8q
fToOcG9saWN5X2JpbmRpbmdaVjJEL3YzYmV0YS97cG9saWN5X2JpbmRpbmcubmFtZT1mb2xk
ZXJzLyovbG9jYXRpb25zLyovcG9saWN5QmluZGluZ3MvKn06DnBvbGljeV9iaW5kaW5nWlwy
Si92M2JldGEve3BvbGljeV9iaW5kaW5nLm5hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9u
cy8qL3BvbGljeUJpbmRpbmdzLyp9Og5wb2xpY3lfYmluZGluZ9pBGnBvbGljeV9iaW5kaW5n
LHVwZGF0ZV9tYXNrykEiCg1Qb2xpY3lCaW5kaW5nEhFPcGVyYXRpb25NZXRhZGF0YRLRAgoT
RGVsZXRlUG9saWN5QmluZGluZxItLmdvb2dsZS5pYW0udjNiZXRhLkRlbGV0ZVBvbGljeUJp
bmRpbmdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLrAYLT5JMCsAEq
Ni92M2JldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9wb2xpY3lCaW5kaW5ncy8q
fVo3KjUvdjNiZXRhL3tuYW1lPWZvbGRlcnMvKi9sb2NhdGlvbnMvKi9wb2xpY3lCaW5kaW5n
cy8qfVo9KjsvdjNiZXRhL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9wb2xp
Y3lCaW5kaW5ncy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIRT3BlcmF0
aW9uTWV0YWRhdGEStAIKEkxpc3RQb2xpY3lCaW5kaW5ncxIsLmdvb2dsZS5pYW0udjNiZXRh
Lkxpc3RQb2xpY3lCaW5kaW5nc1JlcXVlc3QaLS5nb29nbGUuaWFtLnYzYmV0YS5MaXN0UG9s
aWN5QmluZGluZ3NSZXNwb25zZSLAAYLT5JMCsAESNi92M2JldGEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nc1o3EjUvdjNiZXRhL3twYXJlbnQ9Zm9s
ZGVycy8qL2xvY2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nc1o9EjsvdjNiZXRhL3twYXJlbnQ9
b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS9wb2xpY3lCaW5kaW5nc9pBBnBhcmVudBKk
AwoaU2VhcmNoVGFyZ2V0UG9saWN5QmluZGluZ3MSNC5nb29nbGUuaWFtLnYzYmV0YS5TZWFy
Y2hUYXJnZXRQb2xpY3lCaW5kaW5nc1JlcXVlc3QaNS5nb29nbGUuaWFtLnYzYmV0YS5TZWFy
Y2hUYXJnZXRQb2xpY3lCaW5kaW5nc1Jlc3BvbnNlIpgCgtPkkwKBAhJRL3YzYmV0YS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3BvbGljeUJpbmRpbmdzOnNlYXJjaFRhcmdl
dFBvbGljeUJpbmRpbmdzWlISUC92M2JldGEve3BhcmVudD1mb2xkZXJzLyovbG9jYXRpb25z
Lyp9L3BvbGljeUJpbmRpbmdzOnNlYXJjaFRhcmdldFBvbGljeUJpbmRpbmdzWlgSVi92M2Jl
dGEve3BhcmVudD1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyp9L3BvbGljeUJpbmRpbmdz
OnNlYXJjaFRhcmdldFBvbGljeUJpbmRpbmdz2kENcGFyZW50LHRhcmdldBpGykESaWFtLmdv
b2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1w
bGF0Zm9ybULEAgoVY29tLmdvb2dsZS5pYW0udjNiZXRhQhpQb2xpY3lCaW5kaW5nc1NlcnZp
Y2VQcm90b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2M2JldGEvaWFtcGI7aWFt
cGKqAhdHb29nbGUuQ2xvdWQuSWFtLlYzQmV0YcoCF0dvb2dsZVxDbG91ZFxJYW1cVjNiZXRh
6kFcCidpYW0uZ29vZ2xlYXBpcy5jb20vT3JnYW5pemF0aW9uTG9jYXRpb24SMW9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn3qQUoKIWlhbS5nb29n
bGVhcGlzLmNvbS9Gb2xkZXJMb2NhdGlvbhIlZm9sZGVycy97Zm9sZGVyfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufUq4VQoHEgUOAIEDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAGgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWADQKCQoCAwUSAxcAOgoJCgIDBhIDGAAtCgkKAgMHEgMZACUKCQoCAwgS
AxoAKgoICgEIEgMcADQKCQoCCCUSAxwANAoICgEIEgMdAEQKCQoCCAsSAx0ARAoICgEIEgMe
ACIKCQoCCAoSAx4AIgoICgEIEgMfADsKCQoCCAgSAx8AOwoICgEIEgMgAC4KCQoCCAESAyAA
LgoICgEIEgMhADQKCQoCCCkSAyEANAoJCgEIEgQiACUCCgwKBAidCAASBCIAJQIKCQoBCBIE
JgApAgoMCgQInQgBEgQmACkCCl8KAgYAEgUtAKQBARpSIEFuIGludGVyZmFjZSBmb3IgbWFu
YWdpbmcgSWRlbnRpdHkgYW5kIEFjY2VzcyBNYW5hZ2VtZW50IChJQU0pIHBvbGljeQogYmlu
ZGluZ3MuCgoKCgMGAAESAy0IFgoKCgMGAAMSAy4COgoMCgUGAAOZCBIDLgI6CgsKAwYAAxIE
LwIwNwoNCgUGAAOaCBIELwIwNwrZAQoEBgACABIENQJJAxrKASBDcmVhdGVzIGEgcG9saWN5
IGJpbmRpbmcgYW5kIHJldHVybnMgYSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgogQ2FsbGVy
cyB3aWxsIG5lZWQgdGhlIElBTSBwZXJtaXNzaW9ucyBvbiBib3RoIHRoZSBwb2xpY3kgYW5k
IHRhcmdldC4KIEFmdGVyIHRoZSBiaW5kaW5nIGlzIGNyZWF0ZWQsIHRoZSBwb2xpY3kgaXMg
YXBwbGllZCB0byB0aGUgdGFyZ2V0LgoKDAoFBgACAAESAzUGGQoMCgUGAAIAAhIDNRo0CgwK
BQYAAgADEgM2DysKDQoFBgACAAQSBDcEQgYKEQoJBgACAASwyrwiEgQ3BEIGCg0KBQYAAgAE
EgRDBEQyChAKCAYAAgAEmwgAEgRDBEQyCg0KBQYAAgAEEgRFBEgGCg8KBwYAAgAEmQgSBEUE
SAYKJgoEBgACARIETAJXAxoYIEdldHMgYSBwb2xpY3kgYmluZGluZy4KCgwKBQYAAgEBEgNM
BhYKDAoFBgACAQISA0wXLgoMCgUGAAIBAxIDTDlGCg0KBQYAAgEEEgRNBFUGChEKCQYAAgEE
sMq8IhIETQRVBgoMCgUGAAIBBBIDVgQyCg8KCAYAAgEEmwgAEgNWBDIK4QEKBAYAAgISBFwC
bwMa0gEgVXBkYXRlcyBhIHBvbGljeSBiaW5kaW5nIGFuZCByZXR1cm5zIGEgbG9uZy1ydW5u
aW5nIG9wZXJhdGlvbi4KIENhbGxlcnMgd2lsbCBuZWVkIHRoZSBJQU0gcGVybWlzc2lvbnMg
b24gdGhlIHBvbGljeSBhbmQgdGFyZ2V0IGluIHRoZQogYmluZGluZyB0byB1cGRhdGUuIFRh
cmdldCBhbmQgcG9saWN5IGFyZSBpbW11dGFibGUgYW5kIGNhbm5vdCBiZSB1cGRhdGVkLgoK
DAoFBgACAgESA1wGGQoMCgUGAAICAhIDXBo0CgwKBQYAAgIDEgNdDysKDQoFBgACAgQSBF4E
aQYKEQoJBgACAgSwyrwiEgReBGkGCgwKBQYAAgIEEgNqBEgKDwoIBgACAgSbCAASA2oESAoN
CgUGAAICBBIEawRuBgoPCgcGAAICBJkIEgRrBG4GCuEBCgQGAAIDEgV0AoQBAxrRASBEZWxl
dGVzIGEgcG9saWN5IGJpbmRpbmcgYW5kIHJldHVybnMgYSBsb25nLXJ1bm5pbmcgb3BlcmF0
aW9uLgogQ2FsbGVycyB3aWxsIG5lZWQgdGhlIElBTSBwZXJtaXNzaW9ucyBvbiBib3RoIHRo
ZSBwb2xpY3kgYW5kIHRhcmdldC4KIEFmdGVyIHRoZSBiaW5kaW5nIGlzIGRlbGV0ZWQsIHRo
ZSBwb2xpY3kgbm8gbG9uZ2VyIGFwcGxpZXMgdG8gdGhlIHRhcmdldC4KCgwKBQYAAgMBEgN0
BhkKDAoFBgACAwISA3QaNAoMCgUGAAIDAxIDdQ8rCg0KBQYAAgMEEgR2BH4GChEKCQYAAgME
sMq8IhIEdgR+BgoMCgUGAAIDBBIDfwQyCg8KCAYAAgMEmwgAEgN/BDIKDwoFBgACAwQSBoAB
BIMBBgoRCgcGAAIDBJkIEgaAAQSDAQYKKAoEBgACBBIGhwECkwEDGhggTGlzdHMgcG9saWN5
IGJpbmRpbmdzLgoKDQoFBgACBAESBIcBBhgKDQoFBgACBAISBIcBGTIKDQoFBgACBAMSBIgB
DykKDwoFBgACBAQSBokBBJEBBgoTCgkGAAIEBLDKvCISBokBBJEBBgoNCgUGAAIEBBIEkgEE
NAoQCggGAAIEBJsIABIEkgEENApxCgQGAAIFEgaXAQKjAQMaYSBTZWFyY2ggcG9saWN5IGJp
bmRpbmdzIGJ5IHRhcmdldC4gUmV0dXJucyBhbGwgcG9saWN5IGJpbmRpbmcgb2JqZWN0cyBi
b3VuZAogZGlyZWN0bHkgdG8gdGFyZ2V0LgoKDQoFBgACBQESBJcBBiAKDQoFBgACBQISBJcB
IUIKDQoFBgACBQMSBJgBDzEKDwoFBgACBQQSBpkBBKEBBgoTCgkGAAIFBLDKvCISBpkBBKEB
BgoNCgUGAAIFBBIEogEEOwoQCggGAAIFBJsIABIEogEEOwo/CgIEABIGpwEAxwEBGjEgUmVx
dWVzdCBtZXNzYWdlIGZvciBDcmVhdGVQb2xpY3lCaW5kaW5nIG1ldGhvZC4KCgsKAwQAARIE
pwEIIgqpAwoEBAACABIGsgECtwEEGpgDIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
IHdoZXJlIHRoaXMgcG9saWN5IGJpbmRpbmcgd2lsbCBiZSBjcmVhdGVkLgogVGhlIGJpbmRp
bmcgcGFyZW50IGlzIHRoZSBjbG9zZXN0IFJlc291cmNlIE1hbmFnZXIgcmVzb3VyY2UgKHBy
b2plY3QsCiBmb2xkZXIgb3Igb3JnYW5pemF0aW9uKSB0byB0aGUgYmluZGluZyB0YXJnZXQu
CgogRm9ybWF0OgoKICogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0
aW9ufWAKICogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn1gCiAqIGBmb2xkZXJzL3tmb2xkZXJfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAogKiBg
b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAK
Cg0KBQQAAgAFEgSyAQIICg0KBQQAAgABEgSyAQkPCg0KBQQAAgADEgSyARITCg8KBQQAAgAI
EgayARS3AQMKEAoIBAACAAicCAASBLMBBCoKEQoHBAACAAifCBIGtAEEtgEFCqYCCgQEAAIB
EgS/AQJIGpcCIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgcG9saWN5IGJpbmRp
bmcsIHdoaWNoIHdpbGwgYmVjb21lIHRoZSBmaW5hbAogY29tcG9uZW50IG9mIHRoZSBwb2xp
Y3kgYmluZGluZydzIHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBtdXN0IHN0YXJ0IHdp
dGggYSBsb3dlcmNhc2UgbGV0dGVyIGZvbGxvd2VkIGJ5IHVwIHRvIDYyCiBsb3dlcmNhc2Ug
bGV0dGVycywgbnVtYmVycywgaHlwaGVucywgb3IgZG90cy4gUGF0dGVybiwKIC9bYS16XVth
LXowLTktXC5dezIsNjJ9Ly4KCg0KBQQAAgEFEgS/AQIICg0KBQQAAgEBEgS/AQkaCg0KBQQA
AgEDEgS/AR0eCg0KBQQAAgEIEgS/AR9HChAKCAQAAgEInAgAEgS/ASBGCjcKBAQAAgISBMIB
AkwaKSBSZXF1aXJlZC4gVGhlIHBvbGljeSBiaW5kaW5nIHRvIGNyZWF0ZS4KCg0KBQQAAgIG
EgTCAQIPCg0KBQQAAgIBEgTCARAeCg0KBQQAAgIDEgTCASEiCg0KBQQAAgIIEgTCASNLChAK
CAQAAgIInAgAEgTCASRKCm4KBAQAAgMSBMYBAkIaYCBPcHRpb25hbC4gSWYgc2V0LCB2YWxp
ZGF0ZSB0aGUgcmVxdWVzdCBhbmQgcHJldmlldyB0aGUgY3JlYXRpb24sIGJ1dCBkbyBub3QK
IGFjdHVhbGx5IHBvc3QgaXQuCgoNCgUEAAIDBRIExgECBgoNCgUEAAIDARIExgEHFAoNCgUE
AAIDAxIExgEXGAoNCgUEAAIDCBIExgEZQQoQCggEAAIDCJwIABIExgEaQAo8CgIEARIGygEA
2QEBGi4gUmVxdWVzdCBtZXNzYWdlIGZvciBHZXRQb2xpY3lCaW5kaW5nIG1ldGhvZC4KCgsK
AwQBARIEygEIHwqrAwoEBAECABIG0wEC2AEEGpoDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgcG9saWN5IGJpbmRpbmcgdG8gcmV0cmlldmUuCgogRm9ybWF0OgoKICogYHByb2plY3Rz
L3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9s
aWN5X2JpbmRpbmdfaWR9YAogKiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9saWN5X2JpbmRpbmdfaWR9YAogKiBg
Zm9sZGVycy97Zm9sZGVyX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5n
cy97cG9saWN5X2JpbmRpbmdfaWR9YAogKiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9u
X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wb2xpY3lCaW5kaW5ncy97cG9saWN5X2JpbmRp
bmdfaWR9YAoKDQoFBAECAAUSBNMBAggKDQoFBAECAAESBNMBCQ0KDQoFBAECAAMSBNMBEBEK
DwoFBAECAAgSBtMBEtgBAwoQCggEAQIACJwIABIE1AEEKgoRCgcEAQIACJ8IEgbVAQTXAQUK
PwoCBAISBtwBAOoBARoxIFJlcXVlc3QgbWVzc2FnZSBmb3IgVXBkYXRlUG9saWN5QmluZGlu
ZyBtZXRob2QuCgoLCgMEAgESBNwBCCIKjwEKBAQCAgASBOEBAkwagAEgUmVxdWlyZWQuIFRo
ZSBwb2xpY3kgYmluZGluZyB0byB1cGRhdGUuCgogVGhlIHBvbGljeSBiaW5kaW5nJ3MgYG5h
bWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIHBvbGljeSBiaW5kaW5nIHRvCiB1
cGRhdGUuCgoNCgUEAgIABhIE4QECDwoNCgUEAgIAARIE4QEQHgoNCgUEAgIAAxIE4QEhIgoN
CgUEAgIACBIE4QEjSwoQCggEAgIACJwIABIE4QEkSgpsCgQEAgIBEgTlAQJCGl4gT3B0aW9u
YWwuIElmIHNldCwgdmFsaWRhdGUgdGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIHVwZGF0
ZSwgYnV0IGRvIG5vdAogYWN0dWFsbHkgcG9zdCBpdC4KCg0KBQQCAgEFEgTlAQIGCg0KBQQC
AgEBEgTlAQcUCg0KBQQCAgEDEgTlARcYCg0KBQQCAgEIEgTlARlBChAKCAQCAgEInAgAEgTl
ARpACjgKBAQCAgISBugBAukBLxooIE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8g
dXBkYXRlCgoNCgUEAgICBhIE6AECGwoNCgUEAgICARIE6AEcJwoNCgUEAgICAxIE6AEqKwoN
CgUEAgICCBIE6QEGLgoQCggEAgICCJwIABIE6QEHLQo/CgIEAxIG7QEAhAIBGjEgUmVxdWVz
dCBtZXNzYWdlIGZvciBEZWxldGVQb2xpY3lCaW5kaW5nIG1ldGhvZC4KCgsKAwQDARIE7QEI
IgqpAwoEBAMCABIG9gEC+wEEGpgDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcG9saWN5
IGJpbmRpbmcgdG8gZGVsZXRlLgoKIEZvcm1hdDoKCiAqIGBwcm9qZWN0cy97cHJvamVjdF9p
ZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5n
X2lkfWAKICogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKICogYGZvbGRlcnMve2Zv
bGRlcl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9i
aW5kaW5nX2lkfWAKICogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcG9saWN5QmluZGluZ3Mve3BvbGljeV9iaW5kaW5nX2lkfWAKCg0K
BQQDAgAFEgT2AQIICg0KBQQDAgABEgT2AQkNCg0KBQQDAgADEgT2ARARCg8KBQQDAgAIEgb2
ARL7AQMKEAoIBAMCAAicCAASBPcBBCoKEQoHBAMCAAifCBIG+AEE+gEFCnAKBAQDAgESBP8B
AjsaYiBPcHRpb25hbC4gVGhlIGV0YWcgb2YgdGhlIHBvbGljeSBiaW5kaW5nLgogSWYgdGhp
cyBpcyBwcm92aWRlZCwgaXQgbXVzdCBtYXRjaCB0aGUgc2VydmVyJ3MgZXRhZy4KCg0KBQQD
AgEFEgT/AQIICg0KBQQDAgEBEgT/AQkNCg0KBQQDAgEDEgT/ARARCg0KBQQDAgEIEgT/ARI6
ChAKCAQDAgEInAgAEgT/ARM5Cm4KBAQDAgISBIMCAkIaYCBPcHRpb25hbC4gSWYgc2V0LCB2
YWxpZGF0ZSB0aGUgcmVxdWVzdCBhbmQgcHJldmlldyB0aGUgZGVsZXRpb24sIGJ1dCBkbyBu
b3QKIGFjdHVhbGx5IHBvc3QgaXQuCgoNCgUEAwICBRIEgwICBgoNCgUEAwICARIEgwIHFAoN
CgUEAwICAxIEgwIXGAoNCgUEAwICCBIEgwIZQQoQCggEAwICCJwIABIEgwIaQAo+CgIEBBIG
hwIAsgIBGjAgUmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0UG9saWN5QmluZGluZ3MgbWV0aG9k
LgoKCwoDBAQBEgSHAgghCrcCCgQEBAIAEgaRAgKWAgQapgIgUmVxdWlyZWQuIFRoZSBwYXJl
bnQgcmVzb3VyY2UsIHdoaWNoIG93bnMgdGhlIGNvbGxlY3Rpb24gb2YgcG9saWN5CiBiaW5k
aW5ncy4KCiBGb3JtYXQ6CgogKiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97
bG9jYXRpb259YAogKiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufWAKICogYGZvbGRlcnMve2ZvbGRlcl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn1g
CiAqIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9jYXRp
b259YAoKDQoFBAQCAAUSBJECAggKDQoFBAQCAAESBJECCQ8KDQoFBAQCAAMSBJECEhMKDwoF
BAQCAAgSBpECFJYCAwoQCggEBAIACJwIABIEkgIEKgoRCgcEBAIACJ8IEgaTAgSVAgUKsAEK
BAQEAgESBJwCAj8aoQEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBwb2xpY3kg
YmluZGluZ3MgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFu
IHRoaXMgdmFsdWUuCgogVGhlIGRlZmF1bHQgdmFsdWUgaXMgNTAuIFRoZSBtYXhpbXVtIHZh
bHVlIGlzIDEwMDAuCgoNCgUEBAIBBRIEnAICBwoNCgUEBAIBARIEnAIIEQoNCgUEBAIBAxIE
nAIUFQoNCgUEBAIBCBIEnAIWPgoQCggEBAIBCJwIABIEnAIXPQqHAgoEBAQCAhIEowICQRr4
ASBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExp
c3RQb2xpY3lCaW5kaW5nc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUg
c3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRl
cnMgcHJvdmlkZWQgdG8gYExpc3RQb2xpY3lCaW5kaW5nc2AgbXVzdAogbWF0Y2ggdGhlIGNh
bGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQEAgIFEgSjAgIICg0KBQQE
AgIBEgSjAgkTCg0KBQQEAgIDEgSjAhYXCg0KBQQEAgIIEgSjAhhAChAKCAQEAgIInAgAEgSj
Ahk/CqEDCgQEBAIDEgSxAgI9GpIDIE9wdGlvbmFsLiBBbiBleHByZXNzaW9uIGZvciBmaWx0
ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhlIHJlcXVlc3QuIEZpbHRlcgogcnVsZXMgYXJlIGNh
c2UgaW5zZW5zaXRpdmUuIFNvbWUgZWxpZ2libGUgZmllbGRzIGZvciBmaWx0ZXJpbmcgYXJl
IHRoZQogZm9sbG93aW5nOgoKICsgYHRhcmdldGAKICsgYHBvbGljeWAKCiBTb21lIGV4YW1w
bGVzIG9mIGZpbHRlciBxdWVyaWVzOgoKICogYHRhcmdldDpleCpgOiBUaGUgYmluZGluZyB0
YXJnZXQncyBuYW1lIHN0YXJ0cyB3aXRoICJleCIuCiAqIGB0YXJnZXQ6ZXhhbXBsZWA6IFRo
ZSBiaW5kaW5nIHRhcmdldCdzIG5hbWUgaXMgYGV4YW1wbGVgLgogKiBgcG9saWN5OmV4YW1w
bGVgOiBUaGUgYmluZGluZyBwb2xpY3kncyBuYW1lIGlzIGBleGFtcGxlYC4KCg0KBQQEAgMF
EgSxAgIICg0KBQQEAgMBEgSxAgkPCg0KBQQEAgMDEgSxAhITCg0KBQQEAgMIEgSxAhQ8ChAK
CAQEAgMInAgAEgSxAhU7Cj8KAgQFEga1AgC8AgEaMSBSZXNwb25zZSBtZXNzYWdlIGZvciBM
aXN0UG9saWN5QmluZGluZ3MgbWV0aG9kLgoKCwoDBAUBEgS1AggiCj4KBAQFAgASBLcCAi0a
MCBUaGUgcG9saWN5IGJpbmRpbmdzIGZyb20gdGhlIHNwZWNpZmllZCBwYXJlbnQuCgoNCgUE
BQIABBIEtwICCgoNCgUEBQIABhIEtwILGAoNCgUEBQIAARIEtwIZKAoNCgUEBQIAAxIEtwIr
LAqaAQoEBAUCARIEuwICRhqLASBPcHRpb25hbC4gQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNl
bnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0CiBwYWdlLiBJZiB0aGlz
IGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoF
BAUCAQUSBLsCAggKDQoFBAUCAQESBLsCCRgKDQoFBAUCAQMSBLsCGxwKDQoFBAUCAQgSBLsC
HUUKEAoIBAUCAQicCAASBLsCHkQKRgoCBAYSBr8CAPcCARo4IFJlcXVlc3QgbWVzc2FnZSBm
b3IgU2VhcmNoVGFyZ2V0UG9saWN5QmluZGluZ3MgbWV0aG9kLgoKCwoDBAYBEgS/AggpCpsE
CgQEBgIAEgTKAgI9GowEIFJlcXVpcmVkLiBUaGUgdGFyZ2V0IHJlc291cmNlLCB3aGljaCBp
cyBib3VuZCB0byB0aGUgcG9saWN5IGluIHRoZSBiaW5kaW5nLgoKIEZvcm1hdDoKCiAqIGAv
L2lhbS5nb29nbGVhcGlzLmNvbS9sb2NhdGlvbnMvZ2xvYmFsL3dvcmtmb3JjZVBvb2xzL1BP
T0xfSURgCiAqIGAvL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9QUk9KRUNUX05VTUJF
Ui9sb2NhdGlvbnMvZ2xvYmFsL3dvcmtsb2FkSWRlbnRpdHlQb29scy9QT09MX0lEYAogKiBg
Ly9pYW0uZ29vZ2xlYXBpcy5jb20vbG9jYXRpb25zL2dsb2JhbC93b3Jrc3BhY2UvV09SS1NQ
QUNFX0lEYAogKiBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9wcm9q
ZWN0cy97cHJvamVjdF9udW1iZXJ9YAogKiBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29n
bGVhcGlzLmNvbS9mb2xkZXJzL3tmb2xkZXJfaWR9YAogKiBgLy9jbG91ZHJlc291cmNlbWFu
YWdlci5nb29nbGVhcGlzLmNvbS9vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9YAoK
DQoFBAYCAAUSBMoCAggKDQoFBAYCAAESBMoCCQ8KDQoFBAYCAAMSBMoCEhMKDQoFBAYCAAgS
BMoCFDwKEAoIBAYCAAicCAASBMoCFTsKsAEKBAQGAgESBNACAj8aoQEgT3B0aW9uYWwuIFRo
ZSBtYXhpbXVtIG51bWJlciBvZiBwb2xpY3kgYmluZGluZ3MgdG8gcmV0dXJuLiBUaGUgc2Vy
dmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCgogVGhlIGRlZmF1bHQg
dmFsdWUgaXMgNTAuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDAuCgoNCgUEBgIBBRIE0AIC
BwoNCgUEBgIBARIE0AIIEQoNCgUEBgIBAxIE0AIUFQoNCgUEBgIBCBIE0AIWPgoQCggEBgIB
CJwIABIE0AIXPQqnAgoEBAYCAhIE2QICQRqYAiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCBy
ZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIGBTZWFyY2hUYXJnZXRQb2xpY3lCaW5kaW5nc1Jl
cXVlc3RgIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNlcXVlbnQg
cGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVk
IHRvCiBgU2VhcmNoVGFyZ2V0UG9saWN5QmluZGluZ3NSZXF1ZXN0YCBtdXN0IG1hdGNoIHRo
ZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlCiBwYWdlIHRva2VuLgoKDQoFBAYCAgUSBNkCAggK
DQoFBAYCAgESBNkCCRMKDQoFBAYCAgMSBNkCFhcKDQoFBAYCAggSBNkCGEAKEAoIBAYCAgic
CAASBNkCGT8KlQMKBAQGAgMSBuUCAuoCBBqEAyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNv
dXJjZSB3aGVyZSB0aGlzIHNlYXJjaCB3aWxsIGJlIHBlcmZvcm1lZC4gVGhpcwogc2hvdWxk
IGJlIHRoZSBuZWFyZXN0IFJlc291cmNlIE1hbmFnZXIgcmVzb3VyY2UgKHByb2plY3QsIGZv
bGRlciwgb3IKIG9yZ2FuaXphdGlvbikgdG8gdGhlIHRhcmdldC4KCiBGb3JtYXQ6CgogKiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAogKiBgcHJvamVj
dHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKICogYGZvbGRlcnMv
e2ZvbGRlcl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCiAqIGBvcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAYCAwUSBOUCAggK
DQoFBAYCAwESBOUCCQ8KDQoFBAYCAwMSBOUCEhMKDwoFBAYCAwgSBuUCFOoCAwoQCggEBgID
CJwIABIE5gIEKgoRCgcEBgIDCJ8IEgbnAgTpAgUK2gIKBAQGAgQSBPYCAj0aywIgT3B0aW9u
YWwuIEZpbHRlcmluZyBjdXJyZW50bHkgb25seSBzdXBwb3J0cyB0aGUga2luZCBvZiBwb2xp
Y2llcyB0byByZXR1cm4sCiBhbmQgbXVzdCBiZSBpbiB0aGUgZm9ybWF0ICJwb2xpY3lfa2lu
ZD17cG9saWN5X2tpbmR9Ii4KCiBJZiBTdHJpbmcgaXMgZW1wdHksIGJpbmRpbmdzIGJvdW5k
IHRvIGFsbCBraW5kcyBvZiBwb2xpY2llcyB3b3VsZCBiZQogcmV0dXJuZWQuCgogVGhlIG9u
bHkgc3VwcG9ydGVkIHZhbHVlcyBhcmUgdGhlIGZvbGxvd2luZzoKCiAqICJwb2xpY3lfa2lu
ZD1QUklOQ0lQQUxfQUNDRVNTX0JPVU5EQVJZIiwKICogInBvbGljeV9raW5kPUFDQ0VTUyIK
Cg0KBQQGAgQFEgT2AgIICg0KBQQGAgQBEgT2AgkPCg0KBQQGAgQDEgT2AhITCg0KBQQGAgQI
EgT2AhQ8ChAKCAQGAgQInAgAEgT2AhU7CkcKAgQHEgb6AgCBAwEaOSBSZXNwb25zZSBtZXNz
YWdlIGZvciBTZWFyY2hUYXJnZXRQb2xpY3lCaW5kaW5ncyBtZXRob2QuCgoLCgMEBwESBPoC
CCoKQgoEBAcCABIE/AICLRo0IFRoZSBwb2xpY3kgYmluZGluZ3MgYm91bmQgdG8gdGhlIHNw
ZWNpZmllZCB0YXJnZXQuCgoNCgUEBwIABBIE/AICCgoNCgUEBwIABhIE/AILGAoNCgUEBwIA
ARIE/AIZKAoNCgUEBwIAAxIE/AIrLAqaAQoEBAcCARIEgAMCRhqLASBPcHRpb25hbC4gQSB0
b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRo
ZSBuZXh0CiBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBz
dWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAcCAQUSBIADAggKDQoFBAcCAQESBIADCRgKDQoFBAcC
AQMSBIADGxwKDQoFBAcCAQgSBIADHUUKEAoIBAcCAQicCAASBIADHkRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::PolicyBindingsService::CreatePolicyBindingRequest ===
    # Fields for CreatePolicyBindingRequest
    # Field: parent Type: 9 ()
    # Field: policy_binding_id Type: 9 ()
    # Field: policy_binding Type: 11 (.google.iam.v3beta.PolicyBinding)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3beta::PolicyBindingsService::GetPolicyBindingRequest ===
    # Fields for GetPolicyBindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V3beta::PolicyBindingsService::UpdatePolicyBindingRequest ===
    # Fields for UpdatePolicyBindingRequest
    # Field: policy_binding Type: 11 (.google.iam.v3beta.PolicyBinding)
    # Field: validate_only Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Iam::V3beta::PolicyBindingsService::DeletePolicyBindingRequest ===
    # Fields for DeletePolicyBindingRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3beta::PolicyBindingsService::ListPolicyBindingsRequest ===
    # Fields for ListPolicyBindingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Iam::V3beta::PolicyBindingsService::ListPolicyBindingsResponse ===
    # Fields for ListPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3beta.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V3beta::PolicyBindingsService::SearchTargetPolicyBindingsRequest ===
    # Fields for SearchTargetPolicyBindingsRequest
    # Field: target Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Iam::V3beta::PolicyBindingsService::SearchTargetPolicyBindingsResponse ===
    # Fields for SearchTargetPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3beta.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Iam::V3beta::PolicyBindingsService::PolicyBindingsClient ===
package Google::Iam::V3beta::PolicyBindingsService::PolicyBindingsClient;

=pod

=head2 Service Client: Google::Iam::V3beta::PolicyBindingsService::PolicyBindingsClient

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
        ? Google::Iam::V3beta::PolicyBindingsService::CreatePolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PolicyBindings',
        method         => 'CreatePolicyBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PolicyBindingsService::GetPolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PolicyBindings',
        method         => 'GetPolicyBinding',
        request        => $req,
        response_class => 'Google::Iam::V3beta::PolicyBindingResources::PolicyBinding',
    });
}

sub update_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PolicyBindingsService::UpdatePolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PolicyBindings',
        method         => 'UpdatePolicyBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_policy_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PolicyBindingsService::DeletePolicyBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PolicyBindings',
        method         => 'DeletePolicyBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PolicyBindingsService::ListPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PolicyBindings',
        method         => 'ListPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3beta::PolicyBindingsService::ListPolicyBindingsResponse',
    });
}

sub search_target_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PolicyBindingsService::SearchTargetPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PolicyBindings',
        method         => 'SearchTargetPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3beta::PolicyBindingsService::SearchTargetPolicyBindingsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3beta::PolicyBindingsService - Compiled Protocol Buffers messages for google/iam/v3beta/policy_bindings_service.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::PolicyBindingsService;

    my $msg = Google::Iam::V3beta::PolicyBindingsService::CreatePolicyBindingRequest->new({
        parent => $parent,
        policy_binding_id => $policy_binding_id,
        policy_binding => $policy_binding,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::PolicyBindingsService::CreatePolicyBindingRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/policy_bindings_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::PolicyBindingsService::CreatePolicyBindingRequest

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

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding>)

Required. The policy binding to create.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the creation, but do not
actually post it.

=back

=head2 Google::Iam::V3beta::PolicyBindingsService::GetPolicyBindingRequest

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

=head2 Google::Iam::V3beta::PolicyBindingsService::UpdatePolicyBindingRequest

Request message for UpdatePolicyBinding method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_binding() >> / C<< $msg->policy_binding($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding>)

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

=head2 Google::Iam::V3beta::PolicyBindingsService::DeletePolicyBindingRequest

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

=head2 Google::Iam::V3beta::PolicyBindingsService::ListPolicyBindingsRequest

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

=head2 Google::Iam::V3beta::PolicyBindingsService::ListPolicyBindingsResponse

Response message for ListPolicyBindings method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding>)

The policy bindings from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Iam::V3beta::PolicyBindingsService::SearchTargetPolicyBindingsRequest

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

=head2 Google::Iam::V3beta::PolicyBindingsService::SearchTargetPolicyBindingsResponse

Response message for SearchTargetPolicyBindings method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding>)

The policy bindings bound to the specified target.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::PolicyBindingsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
