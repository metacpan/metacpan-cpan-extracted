package Google::Iam::V3beta::AccessPoliciesService;

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
    eval { require Google::Iam::V3beta::AccessPolicyResources };
    eval { require Google::Iam::V3beta::OperationMetadata };
    eval { require Google::Iam::V3beta::PolicyBindingResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvaWFtL3YzYmV0YS9hY2Nlc3NfcG9saWNpZXNfc2VydmljZS5wcm90bxIRZ29v
Z2xlLmlhbS52M2JldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGi9nb29nbGUvaWFtL3YzYmV0YS9hY2Nlc3NfcG9saWN5
X3Jlc291cmNlcy5wcm90bxoqZ29vZ2xlL2lhbS92M2JldGEvb3BlcmF0aW9uX21ldGFkYXRh
LnByb3RvGjBnb29nbGUvaWFtL3YzYmV0YS9wb2xpY3lfYmluZGluZ19yZXNvdXJjZXMucHJv
dG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9i
dWYvZW1wdHkucHJvdG8igAIKGUNyZWF0ZUFjY2Vzc1BvbGljeVJlcXVlc3QSPwoGcGFyZW50
GAEgASgJQifgQQL6QSESH2lhbS5nb29nbGVhcGlzLmNvbS9BY2Nlc3NQb2xpY3lSBnBhcmVu
dBItChBhY2Nlc3NfcG9saWN5X2lkGAIgASgJQgPgQQJSDmFjY2Vzc1BvbGljeUlkEkkKDWFj
Y2Vzc19wb2xpY3kYAyABKAsyHy5nb29nbGUuaWFtLnYzYmV0YS5BY2Nlc3NQb2xpY3lCA+BB
AlIMYWNjZXNzUG9saWN5EigKDXZhbGlkYXRlX29ubHkYBCABKAhCA+BBAVIMdmFsaWRhdGVP
bmx5IlUKFkdldEFjY2Vzc1BvbGljeVJlcXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC+kEhCh9p
YW0uZ29vZ2xlYXBpcy5jb20vQWNjZXNzUG9saWN5UgRuYW1lIpABChlVcGRhdGVBY2Nlc3NQ
b2xpY3lSZXF1ZXN0EkkKDWFjY2Vzc19wb2xpY3kYASABKAsyHy5nb29nbGUuaWFtLnYzYmV0
YS5BY2Nlc3NQb2xpY3lCA+BBAlIMYWNjZXNzUG9saWN5EigKDXZhbGlkYXRlX29ubHkYAiAB
KAhCA+BBAVIMdmFsaWRhdGVPbmx5IrYBChlEZWxldGVBY2Nlc3NQb2xpY3lSZXF1ZXN0EjsK
BG5hbWUYASABKAlCJ+BBAvpBIQofaWFtLmdvb2dsZWFwaXMuY29tL0FjY2Vzc1BvbGljeVIE
bmFtZRIXCgRldGFnGAIgASgJQgPgQQFSBGV0YWcSKAoNdmFsaWRhdGVfb25seRgDIAEoCEID
4EEBUgx2YWxpZGF0ZU9ubHkSGQoFZm9yY2UYBCABKAhCA+BBAVIFZm9yY2UiogEKGUxpc3RB
Y2Nlc3NQb2xpY2llc1JlcXVlc3QSPwoGcGFyZW50GAEgASgJQifgQQL6QSESH2lhbS5nb29n
bGVhcGlzLmNvbS9BY2Nlc3NQb2xpY3lSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BB
AVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4ikwEKGkxp
c3RBY2Nlc3NQb2xpY2llc1Jlc3BvbnNlEkgKD2FjY2Vzc19wb2xpY2llcxgBIAMoCzIfLmdv
b2dsZS5pYW0udjNiZXRhLkFjY2Vzc1BvbGljeVIOYWNjZXNzUG9saWNpZXMSKwoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJQgPgQQFSDW5leHRQYWdlVG9rZW4ipgEKIVNlYXJjaEFjY2Vzc1Bv
bGljeUJpbmRpbmdzUmVxdWVzdBI7CgRuYW1lGAEgASgJQifgQQL6QSEKH2lhbS5nb29nbGVh
cGlzLmNvbS9BY2Nlc3NQb2xpY3lSBG5hbWUSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBh
Z2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpwBCiJTZWFyY2hB
Y2Nlc3NQb2xpY3lCaW5kaW5nc1Jlc3BvbnNlEkkKD3BvbGljeV9iaW5kaW5ncxgBIAMoCzIg
Lmdvb2dsZS5pYW0udjNiZXRhLlBvbGljeUJpbmRpbmdSDnBvbGljeUJpbmRpbmdzEisKD25l
eHRfcGFnZV90b2tlbhgCIAEoCUID4EEBUg1uZXh0UGFnZVRva2VuMr4RCg5BY2Nlc3NQb2xp
Y2llcxKUAwoSQ3JlYXRlQWNjZXNzUG9saWN5EiwuZ29vZ2xlLmlhbS52M2JldGEuQ3JlYXRl
QWNjZXNzUG9saWN5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24isAKC
0+STAt0BIjYvdjNiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vYWNjZXNz
UG9saWNpZXM6DWFjY2Vzc19wb2xpY3laRiI1L3YzYmV0YS97cGFyZW50PWZvbGRlcnMvKi9s
b2NhdGlvbnMvKn0vYWNjZXNzUG9saWNpZXM6DWFjY2Vzc19wb2xpY3laTCI7L3YzYmV0YS97
cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKn0vYWNjZXNzUG9saWNpZXM6DWFj
Y2Vzc19wb2xpY3naQSVwYXJlbnQsYWNjZXNzX3BvbGljeSxhY2Nlc3NfcG9saWN5X2lkykEh
CgxBY2Nlc3NQb2xpY3kSEU9wZXJhdGlvbk1ldGFkYXRhEp4CCg9HZXRBY2Nlc3NQb2xpY3kS
KS5nb29nbGUuaWFtLnYzYmV0YS5HZXRBY2Nlc3NQb2xpY3lSZXF1ZXN0Gh8uZ29vZ2xlLmlh
bS52M2JldGEuQWNjZXNzUG9saWN5Ir4BgtPkkwKwARI2L3YzYmV0YS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9WjcSNS92M2JldGEve25hbWU9Zm9s
ZGVycy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9Wj0SOy92M2JldGEve25hbWU9
b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp92kEEbmFtZRKW
AwoSVXBkYXRlQWNjZXNzUG9saWN5EiwuZ29vZ2xlLmlhbS52M2JldGEuVXBkYXRlQWNjZXNz
UG9saWN5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24isgKC0+STAocC
MkQvdjNiZXRhL3thY2Nlc3NfcG9saWN5Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9h
Y2Nlc3NQb2xpY2llcy8qfToNYWNjZXNzX3BvbGljeVpUMkMvdjNiZXRhL3thY2Nlc3NfcG9s
aWN5Lm5hbWU9Zm9sZGVycy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9Og1hY2Nl
c3NfcG9saWN5WloySS92M2JldGEve2FjY2Vzc19wb2xpY3kubmFtZT1vcmdhbml6YXRpb25z
LyovbG9jYXRpb25zLyovYWNjZXNzUG9saWNpZXMvKn06DWFjY2Vzc19wb2xpY3nKQSEKDEFj
Y2Vzc1BvbGljeRIRT3BlcmF0aW9uTWV0YWRhdGESzwIKEkRlbGV0ZUFjY2Vzc1BvbGljeRIs
Lmdvb2dsZS5pYW0udjNiZXRhLkRlbGV0ZUFjY2Vzc1BvbGljeVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIusBgtPkkwKwASo2L3YzYmV0YS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9WjcqNS92M2JldGEve25hbWU9Zm9s
ZGVycy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9Wj0qOy92M2JldGEve25hbWU9
b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp92kEEbmFtZcpB
KgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRK0AgoSTGlzdEFj
Y2Vzc1BvbGljaWVzEiwuZ29vZ2xlLmlhbS52M2JldGEuTGlzdEFjY2Vzc1BvbGljaWVzUmVx
dWVzdBotLmdvb2dsZS5pYW0udjNiZXRhLkxpc3RBY2Nlc3NQb2xpY2llc1Jlc3BvbnNlIsAB
gtPkkwKwARI2L3YzYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2FjY2Vz
c1BvbGljaWVzWjcSNS92M2JldGEve3BhcmVudD1mb2xkZXJzLyovbG9jYXRpb25zLyp9L2Fj
Y2Vzc1BvbGljaWVzWj0SOy92M2JldGEve3BhcmVudD1vcmdhbml6YXRpb25zLyovbG9jYXRp
b25zLyp9L2FjY2Vzc1BvbGljaWVz2kEGcGFyZW50EokDChpTZWFyY2hBY2Nlc3NQb2xpY3lC
aW5kaW5ncxI0Lmdvb2dsZS5pYW0udjNiZXRhLlNlYXJjaEFjY2Vzc1BvbGljeUJpbmRpbmdz
UmVxdWVzdBo1Lmdvb2dsZS5pYW0udjNiZXRhLlNlYXJjaEFjY2Vzc1BvbGljeUJpbmRpbmdz
UmVzcG9uc2Ui/QGC0+STAu8BElAvdjNiZXRhL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2Nh
dGlvbnMvKi9hY2Nlc3NQb2xpY2llcy8qfTpzZWFyY2hQb2xpY3lCaW5kaW5nc1pMEkovdjNi
ZXRhL3tuYW1lPWZvbGRlcnMvKi9sb2NhdGlvbnMvKi9hY2Nlc3NQb2xpY2llcy8qfTpzZWFy
Y2hQb2xpY3lCaW5kaW5nc1pNEksvdjNiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovYWNjZXNzUG9saWNpZXMvKn06c2VhcmNoUG9saWN5QmluZGluZ3PaQQRuYW1lGkbKQRJp
YW0uZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtQpEBChVjb20uZ29vZ2xlLmlhbS52M2JldGFCE0FjY2Vzc1BvbGljaWVz
UHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9pYW0vYXBpdjNiZXRhL2lhbXBiO2lhbXBi
qgIXR29vZ2xlLkNsb3VkLklhbS5WM0JldGHKAhdHb29nbGVcQ2xvdWRcSWFtXFYzYmV0YUqU
RgoHEgUOAMgCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
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
GgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
ADkKCQoCAwUSAxcANAoJCgIDBhIDGAA6CgkKAgMHEgMZAC0KCQoCAwgSAxoAJQoICgEIEgMc
ADQKCQoCCCUSAxwANAoICgEIEgMdAEQKCQoCCAsSAx0ARAoICgEIEgMeACIKCQoCCAoSAx4A
IgoICgEIEgMfADQKCQoCCAgSAx8ANAoICgEIEgMgAC4KCQoCCAESAyAALgoICgEIEgMhADQK
CQoCCCkSAyEANApMCgIGABIFJACUAQEaPyBNYW5hZ2VzIElkZW50aXR5IGFuZCBBY2Nlc3Mg
TWFuYWdlbWVudCAoSUFNKSBhY2Nlc3MgcG9saWNpZXMuCgoKCgMGAAESAyQIFgoKCgMGAAMS
AyUCOgoMCgUGAAOZCBIDJQI6CgsKAwYAAxIEJgInNwoNCgUGAAOaCBIEJgInNwpPCgQGAAIA
EgQqAj4DGkEgQ3JlYXRlcyBhbiBhY2Nlc3MgcG9saWN5LCBhbmQgcmV0dXJucyBhIGxvbmcg
cnVubmluZyBvcGVyYXRpb24uCgoMCgUGAAIAARIDKgYYCgwKBQYAAgACEgMqGTIKDAoFBgAC
AAMSAysPKwoNCgUGAAIABBIELAQ3BgoRCgkGAAIABLDKvCISBCwENwYKDQoFBgACAAQSBDgE
OTAKEAoIBgACAASbCAASBDgEOTAKDQoFBgACAAQSBDoEPQYKDwoHBgACAASZCBIEOgQ9Bgom
CgQGAAIBEgRBAkwDGhggR2V0cyBhbiBhY2Nlc3MgcG9saWN5LgoKDAoFBgACAQESA0EGFQoM
CgUGAAIBAhIDQRYsCgwKBQYAAgEDEgNBN0MKDQoFBgACAQQSBEIESgYKEQoJBgACAQSwyrwi
EgRCBEoGCgwKBQYAAgEEEgNLBDIKDwoIBgACAQSbCAASA0sEMgopCgQGAAICEgRPAmEDGhsg
VXBkYXRlcyBhbiBhY2Nlc3MgcG9saWN5LgoKDAoFBgACAgESA08GGAoMCgUGAAICAhIDTxky
CgwKBQYAAgIDEgNQDysKDQoFBgACAgQSBFEEXAYKEQoJBgACAgSwyrwiEgRRBFwGCg0KBQYA
AgIEEgRdBGAGCg8KBwYAAgIEmQgSBF0EYAYKKQoEBgACAxIEZAJ0AxobIERlbGV0ZXMgYW4g
YWNjZXNzIHBvbGljeS4KCgwKBQYAAgMBEgNkBhgKDAoFBgACAwISA2QZMgoMCgUGAAIDAxID
ZQ8rCg0KBQYAAgMEEgRmBG4GChEKCQYAAgMEsMq8IhIEZgRuBgoMCgUGAAIDBBIDbwQyCg8K
CAYAAgMEmwgAEgNvBDIKDQoFBgACAwQSBHAEcwYKDwoHBgACAwSZCBIEcARzBgonCgQGAAIE
EgV3AoMBAxoYIExpc3RzIGFjY2VzcyBwb2xpY2llcy4KCgwKBQYAAgQBEgN3BhgKDAoFBgAC
BAISA3cZMgoMCgUGAAIEAxIDeA8pCg4KBQYAAgQEEgV5BIEBBgoSCgkGAAIEBLDKvCISBXkE
gQEGCg0KBQYAAgQEEgSCAQQ0ChAKCAYAAgQEmwgAEgSCAQQ0CogBCgQGAAIFEgaHAQKTAQMa
eCBSZXR1cm5zIGFsbCBwb2xpY3kgYmluZGluZ3MgdGhhdCBiaW5kIGEgc3BlY2lmaWMgcG9s
aWN5IGlmIGEgdXNlciBoYXMKIHNlYXJjaFBvbGljeUJpbmRpbmdzIHBlcm1pc3Npb24gb24g
dGhhdCBwb2xpY3kuCgoNCgUGAAIFARIEhwEGIAoNCgUGAAIFAhIEhwEhQgoNCgUGAAIFAxIE
iAEPMQoPCgUGAAIFBBIGiQEEkQEGChMKCQYAAgUEsMq8IhIGiQEEkQEGCg0KBQYAAgUEEgSS
AQQyChAKCAYAAgUEmwgAEgSSAQQyCj4KAgQAEgaXAQC3AQEaMCBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIENyZWF0ZUFjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgMEAAESBJcBCCEKsAIKBAQAAgAS
Bp8BAqQBBBqfAiBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSB3aGVyZSB0aGlzIGFj
Y2VzcyBwb2xpY3kgd2lsbCBiZSBjcmVhdGVkLgoKIEZvcm1hdDoKICAgYHByb2plY3RzL3tw
cm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKICAgYHByb2plY3RzL3twcm9qZWN0
X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCiAgIGBmb2xkZXJzL3tmb2xkZXJfaWR9
L2xvY2F0aW9ucy97bG9jYXRpb259YAogICBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9u
X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCg0KBQQAAgAFEgSfAQIICg0KBQQAAgABEgSf
AQkPCg0KBQQAAgADEgSfARITCg8KBQQAAgAIEgafARSkAQMKEAoIBAACAAicCAASBKABBCoK
EQoHBAACAAifCBIGoQEEowEFCvECCgQEAAIBEgSvAQJHGuICIFJlcXVpcmVkLiBUaGUgSUQg
dG8gdXNlIGZvciB0aGUgYWNjZXNzIHBvbGljeSwgd2hpY2gKIHdpbGwgYmVjb21lIHRoZSBm
aW5hbCBjb21wb25lbnQgb2YgdGhlIGFjY2VzcyBwb2xpY3kncwogcmVzb3VyY2UgbmFtZS4K
CiBUaGlzIHZhbHVlIG11c3Qgc3RhcnQgd2l0aCBhIGxvd2VyY2FzZSBsZXR0ZXIgZm9sbG93
ZWQgYnkgdXAgdG8gNjIKIGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1iZXJzLCBoeXBoZW5zLCBv
ciBkb3RzLiBQYXR0ZXJuLAogL1thLXpdW2EtejAtOS1cLl17Miw2Mn0vLgoKIFRoaXMgdmFs
dWUgbXVzdCBiZSB1bmlxdWUgYW1vbmcgYWxsIGFjY2VzcyBwb2xpY2llcyB3aXRoIHRoZSBz
YW1lIHBhcmVudC4KCg0KBQQAAgEFEgSvAQIICg0KBQQAAgEBEgSvAQkZCg0KBQQAAgEDEgSv
ARwdCg0KBQQAAgEIEgSvAR5GChAKCAQAAgEInAgAEgSvAR9FCjYKBAQAAgISBLIBAkoaKCBS
ZXF1aXJlZC4gVGhlIGFjY2VzcyBwb2xpY3kgdG8gY3JlYXRlLgoKDQoFBAACAgYSBLIBAg4K
DQoFBAACAgESBLIBDxwKDQoFBAACAgMSBLIBHyAKDQoFBAACAggSBLIBIUkKEAoIBAACAgic
CAASBLIBIkgKbgoEBAACAxIEtgECQhpgIE9wdGlvbmFsLiBJZiBzZXQsIHZhbGlkYXRlIHRo
ZSByZXF1ZXN0IGFuZCBwcmV2aWV3IHRoZSBjcmVhdGlvbiwgYnV0IGRvIG5vdAogYWN0dWFs
bHkgcG9zdCBpdC4KCg0KBQQAAgMFEgS2AQIGCg0KBQQAAgMBEgS2AQcUCg0KBQQAAgMDEgS2
ARcYCg0KBQQAAgMIEgS2ARlBChAKCAQAAgMInAgAEgS2ARpACjsKAgQBEga6AQDIAQEaLSBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIEdldEFjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgMEAQESBLoB
CB4KpQMKBAQBAgASBsIBAscBBBqUAyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGFjY2Vz
cyBwb2xpY3kgdG8gcmV0cmlldmUuCgogRm9ybWF0OgogICBgcHJvamVjdHMve3Byb2plY3Rf
aWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9saWN5
X2lkfWAKICAgYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3lfaWR9YAogICBgZm9sZGVycy97Zm9s
ZGVyX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97YWNjZXNzX3Bv
bGljeV9pZH1gCiAgIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9u
cy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9saWN5X2lkfWAKCg0KBQQB
AgAFEgTCAQIICg0KBQQBAgABEgTCAQkNCg0KBQQBAgADEgTCARARCg8KBQQBAgAIEgbCARLH
AQMKEAoIBAECAAicCAASBMMBBCoKEQoHBAECAAifCBIGxAEExgEFCj4KAgQCEgbLAQDVAQEa
MCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZUFjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgME
AgESBMsBCCEKhAEKBAQCAgASBNABAkoadiBSZXF1aXJlZC4gVGhlIGFjY2VzcyBwb2xpY3kg
dG8gdXBkYXRlLgoKIFRoZSBhY2Nlc3MgcG9saWN5J3MgYG5hbWVgIGZpZWxkIGlzIHVzZWQg
dG8gaWRlbnRpZnkgdGhlCiBwb2xpY3kgdG8gdXBkYXRlLgoKDQoFBAICAAYSBNABAg4KDQoF
BAICAAESBNABDxwKDQoFBAICAAMSBNABHyAKDQoFBAICAAgSBNABIUkKEAoIBAICAAicCAAS
BNABIkgKbAoEBAICARIE1AECQhpeIE9wdGlvbmFsLiBJZiBzZXQsIHZhbGlkYXRlIHRoZSBy
ZXF1ZXN0IGFuZCBwcmV2aWV3IHRoZSB1cGRhdGUsIGJ1dCBkbyBub3QKIGFjdHVhbGx5IHBv
c3QgaXQuCgoNCgUEAgIBBRIE1AECBgoNCgUEAgIBARIE1AEHFAoNCgUEAgIBAxIE1AEXGAoN
CgUEAgIBCBIE1AEZQQoQCggEAgIBCJwIABIE1AEaQAo+CgIEAxIG2AEA8gEBGjAgUmVxdWVz
dCBtZXNzYWdlIGZvciBEZWxldGVBY2Nlc3NQb2xpY3kgbWV0aG9kLgoKCwoDBAMBEgTYAQgh
CqMDCgQEAwIAEgbgAQLlAQQakgMgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBhY2Nlc3Mg
cG9saWN5IHRvIGRlbGV0ZS4KCiBGb3JtYXQ6CiAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3lfaWR9
YAogICBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9h
Y2Nlc3NQb2xpY2llcy97YWNjZXNzX3BvbGljeV9pZH1gCiAgIGBmb2xkZXJzL3tmb2xkZXJf
aWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9saWN5
X2lkfWAKICAgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3lfaWR9YAoKDQoFBAMCAAUS
BOABAggKDQoFBAMCAAESBOABCQ0KDQoFBAMCAAMSBOABEBEKDwoFBAMCAAgSBuABEuUBAwoQ
CggEAwIACJwIABIE4QEEKgoRCgcEAwIACJ8IEgbiAQTkAQUKbwoEBAMCARIE6QECOxphIE9w
dGlvbmFsLiBUaGUgZXRhZyBvZiB0aGUgYWNjZXNzIHBvbGljeS4gSWYgdGhpcyBpcyBwcm92
aWRlZCwgaXQgbXVzdCBtYXRjaAogdGhlIHNlcnZlcidzIGV0YWcuCgoNCgUEAwIBBRIE6QEC
CAoNCgUEAwIBARIE6QEJDQoNCgUEAwIBAxIE6QEQEQoNCgUEAwIBCBIE6QESOgoQCggEAwIB
CJwIABIE6QETOQpuCgQEAwICEgTtAQJCGmAgT3B0aW9uYWwuIElmIHNldCwgdmFsaWRhdGUg
dGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIGRlbGV0aW9uLCBidXQgZG8gbm90CiBhY3R1
YWxseSBwb3N0IGl0LgoKDQoFBAMCAgUSBO0BAgYKDQoFBAMCAgESBO0BBxQKDQoFBAMCAgMS
BO0BFxgKDQoFBAMCAggSBO0BGUEKEAoIBAMCAgicCAASBO0BGkAKigEKBAQDAgMSBPEBAjoa
fCBPcHRpb25hbC4gSWYgc2V0IHRvIHRydWUsIHRoZSByZXF1ZXN0IHdpbGwgZm9yY2UgdGhl
IGRlbGV0aW9uIG9mIHRoZSBQb2xpY3kKIGV2ZW4gaWYgdGhlIFBvbGljeSByZWZlcmVuY2Vz
IFBvbGljeUJpbmRpbmdzLgoKDQoFBAMCAwUSBPEBAgYKDQoFBAMCAwESBPEBBwwKDQoFBAMC
AwMSBPEBDxAKDQoFBAMCAwgSBPEBETkKEAoIBAMCAwicCAASBPEBEjgKPgoCBAQSBvUBAJQC
ARowIFJlcXVlc3QgbWVzc2FnZSBmb3IgTGlzdEFjY2Vzc1BvbGljaWVzIG1ldGhvZC4KCgsK
AwQEARIE9QEIIQq+AgoEBAQCABIG/gECgwIEGq0CIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJl
c291cmNlLCB3aGljaCBvd25zIHRoZSBjb2xsZWN0aW9uIG9mIGFjY2VzcyBwb2xpY3kKIHJl
c291cmNlcy4KCiBGb3JtYXQ6CiAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25z
L3tsb2NhdGlvbn1gCiAgIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb259YAogICBgZm9sZGVycy97Zm9sZGVyX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9u
fWAKICAgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn1gCgoNCgUEBAIABRIE/gECCAoNCgUEBAIAARIE/gEJDwoNCgUEBAIAAxIE/gESEwoP
CgUEBAIACBIG/gEUgwIDChAKCAQEAgAInAgAEgT/AQQqChEKBwQEAgAInwgSBoACBIICBQqI
AgoEBAQCARIEigICPxr5ASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGFjY2Vz
cyBwb2xpY2llcyB0byByZXR1cm4uIFRoZQogc2VydmljZSBtYXkgcmV0dXJuIGZld2VyIHRo
YW4gdGhpcyB2YWx1ZS4KCiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBhY2Nlc3MgcG9s
aWNpZXMgd2lsbCBiZSByZXR1cm5lZC4gVmFsaWQgdmFsdWUKIHJhbmdlcyBmcm9tIDEgdG8g
MTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgoNCgUE
BAIBBRIEigICBwoNCgUEBAIBARIEigIIEQoNCgUEBAIBAxIEigIUFQoNCgUEBAIBCBIEigIW
PgoQCggEBAIBCJwIABIEigIXPQqJAgoEBAQCAhIEkwICQRr6ASBPcHRpb25hbC4gQSBwYWdl
IHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIGBMaXN0QWNjZXNzUG9saWNpZXNg
IGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNlcXVlbnQgcGFnZS4K
CiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBg
TGlzdEFjY2Vzc1BvbGljaWVzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQg
dGhlCiBwYWdlIHRva2VuLgoKDQoFBAQCAgUSBJMCAggKDQoFBAQCAgESBJMCCRMKDQoFBAQC
AgMSBJMCFhcKDQoFBAQCAggSBJMCGEAKEAoIBAQCAgicCAASBJMCGT8KPwoCBAUSBpcCAJ4C
ARoxIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExpc3RBY2Nlc3NQb2xpY2llcyBtZXRob2QuCgoL
CgMEBQESBJcCCCIKPgoEBAUCABIEmQICLBowIFRoZSBhY2Nlc3MgcG9saWNpZXMgZnJvbSB0
aGUgc3BlY2lmaWVkIHBhcmVudC4KCg0KBQQFAgAEEgSZAgIKCg0KBQQFAgAGEgSZAgsXCg0K
BQQFAgABEgSZAhgnCg0KBQQFAgADEgSZAiorCpoBCgQEBQIBEgSdAgJGGosBIE9wdGlvbmFs
LiBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmll
dmUgdGhlIG5leHQKIHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJl
IG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEBQIBBRIEnQICCAoNCgUEBQIBARIEnQIJGAoN
CgUEBQIBAxIEnQIbHAoNCgUEBQIBCBIEnQIdRQoQCggEBQIBCJwIABIEnQIeRApDCgIEBhIG
oQIAvgIBGjUgUmVxdWVzdCBtZXNzYWdlIGZvciBTZWFyY2hBY2Nlc3NQb2xpY3lCaW5kaW5n
cyBycGMuCgoLCgMEBgESBKECCCkKlAMKBAQGAgASBqgCAq0CBBqDAyBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIGFjY2VzcyBwb2xpY3kuCiBGb3JtYXQ6CiAgYG9yZ2FuaXphdGlvbnMv
e29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMv
e2FjY2Vzc19wb2xpY3lfaWR9YAogIGBmb2xkZXJzL3tmb2xkZXJfaWR9L2xvY2F0aW9ucy97
bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9saWN5X2lkfWAKICBgcHJvamVj
dHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3th
Y2Nlc3NfcG9saWN5X2lkfWAKICBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97YWNjZXNzX3BvbGljeV9pZH1gCgoNCgUE
BgIABRIEqAICCAoNCgUEBgIAARIEqAIJDQoNCgUEBgIAAxIEqAIQEQoPCgUEBgIACBIGqAIS
rQIDChAKCAQGAgAInAgAEgSpAgQqChEKBwQGAgAInwgSBqoCBKwCBQqAAgoEBAYCARIEtAIC
PxrxASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHBvbGljeSBiaW5kaW5ncyB0
byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1
ZS4KCiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBwb2xpY3kgYmluZGluZ3Mgd2lsbCBi
ZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAx
MDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBAYCAQUSBLQCAgcKDQoFBAYCAQES
BLQCCBEKDQoFBAYCAQMSBLQCFBUKDQoFBAYCAQgSBLQCFj4KEAoIBAYCAQicCAASBLQCFz0K
pwIKBAQGAgISBL0CAkEamAIgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJv
bSBhIHByZXZpb3VzCiBgU2VhcmNoQWNjZXNzUG9saWN5QmluZGluZ3NSZXF1ZXN0YCBjYWxs
LiBQcm92aWRlIHRoaXMgdG8KIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hl
biBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogYFNlYXJj
aEFjY2Vzc1BvbGljeUJpbmRpbmdzUmVxdWVzdGAgbXVzdCBtYXRjaCB0aGUgY2FsbAogdGhh
dCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQGAgIFEgS9AgIICg0KBQQGAgIBEgS9
AgkTCg0KBQQGAgIDEgS9AhYXCg0KBQQGAgIIEgS9AhhAChAKCAQGAgIInAgAEgS9Ahk/CkQK
AgQHEgbBAgDIAgEaNiBSZXNwb25zZSBtZXNzYWdlIGZvciBTZWFyY2hBY2Nlc3NQb2xpY3lC
aW5kaW5ncyBycGMuCgoLCgMEBwESBMECCCoKSAoEBAcCABIEwwICLRo6IFRoZSBwb2xpY3kg
YmluZGluZ3MgdGhhdCByZWZlcmVuY2UgdGhlIHNwZWNpZmllZCBwb2xpY3kuCgoNCgUEBwIA
BBIEwwICCgoNCgUEBwIABhIEwwILGAoNCgUEBwIAARIEwwIZKAoNCgUEBwIAAxIEwwIrLAqa
AQoEBAcCARIExwICRhqLASBPcHRpb25hbC4gQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQg
YXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0CiBwYWdlLiBJZiB0aGlzIGZp
ZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAcC
AQUSBMcCAggKDQoFBAcCAQESBMcCCRgKDQoFBAcCAQMSBMcCGxwKDQoFBAcCAQgSBMcCHUUK
EAoIBAcCAQicCAASBMcCHkRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::AccessPoliciesService::CreateAccessPolicyRequest ===
    # Fields for CreateAccessPolicyRequest
    # Field: parent Type: 9 ()
    # Field: access_policy_id Type: 9 ()
    # Field: access_policy Type: 11 (.google.iam.v3beta.AccessPolicy)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::GetAccessPolicyRequest ===
    # Fields for GetAccessPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::UpdateAccessPolicyRequest ===
    # Fields for UpdateAccessPolicyRequest
    # Field: access_policy Type: 11 (.google.iam.v3beta.AccessPolicy)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::DeleteAccessPolicyRequest ===
    # Fields for DeleteAccessPolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: force Type: 8 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::ListAccessPoliciesRequest ===
    # Fields for ListAccessPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::ListAccessPoliciesResponse ===
    # Fields for ListAccessPoliciesResponse
    # Field: access_policies Type: 11 (.google.iam.v3beta.AccessPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::SearchAccessPolicyBindingsRequest ===
    # Fields for SearchAccessPolicyBindingsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3beta::AccessPoliciesService::SearchAccessPolicyBindingsResponse ===
    # Fields for SearchAccessPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3beta.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Iam::V3beta::AccessPoliciesService::AccessPoliciesClient ===
package Google::Iam::V3beta::AccessPoliciesService::AccessPoliciesClient;

=pod

=head2 Service Client: Google::Iam::V3beta::AccessPoliciesService::AccessPoliciesClient

Client stub representing the remote C<AccessPolicies> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::AccessPoliciesService::CreateAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.AccessPolicies',
        method         => 'CreateAccessPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::AccessPoliciesService::GetAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.AccessPolicies',
        method         => 'GetAccessPolicy',
        request        => $req,
        response_class => 'Google::Iam::V3beta::AccessPolicyResources::AccessPolicy',
    });
}

sub update_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::AccessPoliciesService::UpdateAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.AccessPolicies',
        method         => 'UpdateAccessPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::AccessPoliciesService::DeleteAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.AccessPolicies',
        method         => 'DeleteAccessPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_access_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::AccessPoliciesService::ListAccessPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.AccessPolicies',
        method         => 'ListAccessPolicies',
        request        => $req,
        response_class => 'Google::Iam::V3beta::AccessPoliciesService::ListAccessPoliciesResponse',
    });
}

sub search_access_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::AccessPoliciesService::SearchAccessPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.AccessPolicies',
        method         => 'SearchAccessPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3beta::AccessPoliciesService::SearchAccessPolicyBindingsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3beta::AccessPoliciesService - Compiled Protocol Buffers messages for google/iam/v3beta/access_policies_service.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::AccessPoliciesService;

    my $msg = Google::Iam::V3beta::AccessPoliciesService::CreateAccessPolicyRequest->new({
        parent => $parent,
        access_policy_id => $access_policy_id,
        access_policy => $access_policy,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::AccessPoliciesService::CreateAccessPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/access_policies_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::AccessPoliciesService::CreateAccessPolicyRequest

Request message for CreateAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this access policy will be created.

Format:
  `projects/{project_id}/locations/{location}`
  `projects/{project_number}/locations/{location}`
  `folders/{folder_id}/locations/{location}`
  `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->access_policy_id() >> / C<< $msg->access_policy_id($value) >>

Type: C<String>

Required. The ID to use for the access policy, which
will become the final component of the access policy's
resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, hyphens, or dots. Pattern,
/[a-z][a-z0-9-\.]{2,62}/.

This value must be unique among all access policies with the same parent.

=item * C<< $msg->access_policy() >> / C<< $msg->access_policy($value) >>

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicy>)

Required. The access policy to create.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the creation, but do not
actually post it.

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::GetAccessPolicyRequest

Request message for GetAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the access policy to retrieve.

Format:
  `projects/{project_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `projects/{project_number}/locations/{location}/accessPolicies/{access_policy_id}`
  `folders/{folder_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `organizations/{organization_id}/locations/{location}/accessPolicies/{access_policy_id}`

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::UpdateAccessPolicyRequest

Request message for UpdateAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_policy() >> / C<< $msg->access_policy($value) >>

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicy>)

Required. The access policy to update.

The access policy's `name` field is used to identify the
policy to update.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the update, but do not
actually post it.

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::DeleteAccessPolicyRequest

Request message for DeleteAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the access policy to delete.

Format:
  `projects/{project_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `projects/{project_number}/locations/{location}/accessPolicies/{access_policy_id}`
  `folders/{folder_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `organizations/{organization_id}/locations/{location}/accessPolicies/{access_policy_id}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag of the access policy. If this is provided, it must match
the server's etag.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the deletion, but do not
actually post it.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, the request will force the deletion of the Policy
even if the Policy references PolicyBindings.

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::ListAccessPoliciesRequest

Request message for ListAccessPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource, which owns the collection of access policy
resources.

Format:
  `projects/{project_id}/locations/{location}`
  `projects/{project_number}/locations/{location}`
  `folders/{folder_id}/locations/{location}`
  `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of access policies to return. The
service may return fewer than this value.

If unspecified, at most 50 access policies will be returned. Valid value
ranges from 1 to 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAccessPolicies` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`ListAccessPolicies` must match the call that provided the
page token.

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::ListAccessPoliciesResponse

Response message for ListAccessPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_policies() >> / C<< $msg->access_policies($value) >>

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicy>)

The access policies from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::SearchAccessPolicyBindingsRequest

Request message for SearchAccessPolicyBindings rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the access policy.
Format:
 `organizations/{organization_id}/locations/{location}/accessPolicies/{access_policy_id}`
 `folders/{folder_id}/locations/{location}/accessPolicies/{access_policy_id}`
 `projects/{project_id}/locations/{location}/accessPolicies/{access_policy_id}`
 `projects/{project_number}/locations/{location}/accessPolicies/{access_policy_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policy bindings to return. The service may
return fewer than this value.

If unspecified, at most 50 policy bindings will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`SearchAccessPolicyBindingsRequest` call. Provide this to
retrieve the subsequent page.

When paginating, all other parameters provided to
`SearchAccessPolicyBindingsRequest` must match the call
that provided the page token.

=back

=head2 Google::Iam::V3beta::AccessPoliciesService::SearchAccessPolicyBindingsResponse

Response message for SearchAccessPolicyBindings rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding>)

The policy bindings that reference the specified policy.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::AccessPoliciesService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
