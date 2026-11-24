package Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvYmlncXVlcnkvZGF0YXBvbGljaWVzL3YyYmV0YTEvZGF0YXBvbGlj
eS5wcm90bxIqZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MmJldGExGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxoeZ29vZ2xlL2lhbS92MS9pYW1fcG9saWN5LnByb3RvGhpnb29nbGUvaWFtL3YxL3Bv
bGljeS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9i
dWYvZmllbGRfbWFzay5wcm90byLwAQoXQ3JlYXRlRGF0YVBvbGljeVJlcXVlc3QSTAoGcGFy
ZW50GAEgASgJQjTgQQL6QS4SLGJpZ3F1ZXJ5ZGF0YXBvbGljeS5nb29nbGVhcGlzLmNvbS9E
YXRhUG9saWN5UgZwYXJlbnQSKQoOZGF0YV9wb2xpY3lfaWQYAiABKAlCA+BBAlIMZGF0YVBv
bGljeUlkElwKC2RhdGFfcG9saWN5GAMgASgLMjYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRh
dGFwb2xpY2llcy52MmJldGExLkRhdGFQb2xpY3lCA+BBAlIKZGF0YVBvbGljeSK5AQoXVXBk
YXRlRGF0YVBvbGljeVJlcXVlc3QSXAoLZGF0YV9wb2xpY3kYASABKAsyNi5nb29nbGUuY2xv
dWQuYmlncXVlcnkuZGF0YXBvbGljaWVzLnYyYmV0YTEuRGF0YVBvbGljeUID4EECUgpkYXRh
UG9saWN5EkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a0ID4EEBUgp1cGRhdGVNYXNrIowBChJBZGRHcmFudGVlc1JlcXVlc3QSVQoLZGF0YV9wb2xp
Y3kYASABKAlCNOBBAvpBLgosYmlncXVlcnlkYXRhcG9saWN5Lmdvb2dsZWFwaXMuY29tL0Rh
dGFQb2xpY3lSCmRhdGFQb2xpY3kSHwoIZ3JhbnRlZXMYAiADKAlCA+BBAlIIZ3JhbnRlZXMi
jwEKFVJlbW92ZUdyYW50ZWVzUmVxdWVzdBJVCgtkYXRhX3BvbGljeRgBIAEoCUI04EEC+kEu
CixiaWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20vRGF0YVBvbGljeVIKZGF0YVBv
bGljeRIfCghncmFudGVlcxgCIAMoCUID4EECUghncmFudGVlcyJjChdEZWxldGVEYXRhUG9s
aWN5UmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGJpZ3F1ZXJ5ZGF0YXBvbGljeS5n
b29nbGVhcGlzLmNvbS9EYXRhUG9saWN5UgRuYW1lImAKFEdldERhdGFQb2xpY3lSZXF1ZXN0
EkgKBG5hbWUYASABKAlCNOBBAvpBLgosYmlncXVlcnlkYXRhcG9saWN5Lmdvb2dsZWFwaXMu
Y29tL0RhdGFQb2xpY3lSBG5hbWUirQEKF0xpc3REYXRhUG9saWNpZXNSZXF1ZXN0EkwKBnBh
cmVudBgBIAEoCUI04EEC+kEuEixiaWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20v
RGF0YVBvbGljeVIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIi
CgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKfAQoYTGlzdERhdGFQb2xpY2ll
c1Jlc3BvbnNlElsKDWRhdGFfcG9saWNpZXMYASADKAsyNi5nb29nbGUuY2xvdWQuYmlncXVl
cnkuZGF0YXBvbGljaWVzLnYyYmV0YTEuRGF0YVBvbGljeVIMZGF0YVBvbGljaWVzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLlBgoKRGF0YVBvbGljeRJ0ChNk
YXRhX21hc2tpbmdfcG9saWN5GAcgASgLMj0uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFw
b2xpY2llcy52MmJldGExLkRhdGFNYXNraW5nUG9saWN5QgPgQQFIAFIRZGF0YU1hc2tpbmdQ
b2xpY3kSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEikKDmRhdGFfcG9saWN5X2lkGAIgASgJ
QgPgQQNSDGRhdGFQb2xpY3lJZBIXCgRldGFnGAsgASgJSAFSBGV0YWeIAQESdAoQZGF0YV9w
b2xpY3lfdHlwZRgDIAEoDjJFLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMu
djJiZXRhMS5EYXRhUG9saWN5LkRhdGFQb2xpY3lUeXBlQgPgQQJSDmRhdGFQb2xpY3lUeXBl
EksKCnBvbGljeV90YWcYBCABKAlCLOBBA/pBJgokZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5j
b20vUG9saWN5VGFnUglwb2xpY3lUYWcSHwoIZ3JhbnRlZXMYCCADKAlCA+BBAVIIZ3JhbnRl
ZXMSXQoHdmVyc2lvbhgJIAEoDjI+Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNp
ZXMudjJiZXRhMS5EYXRhUG9saWN5LlZlcnNpb25CA+BBA1IHdmVyc2lvbiJnCg5EYXRhUG9s
aWN5VHlwZRIgChxEQVRBX1BPTElDWV9UWVBFX1VOU1BFQ0lGSUVEEAASFwoTREFUQV9NQVNL
SU5HX1BPTElDWRABEhoKFlJBV19EQVRBX0FDQ0VTU19QT0xJQ1kQAiIyCgdWZXJzaW9uEhcK
E1ZFUlNJT05fVU5TUEVDSUZJRUQQABIGCgJWMRABEgYKAlYyEAI6kAHqQYwBCixiaWdxdWVy
eWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20vRGF0YVBvbGljeRJCcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFQb2xpY2llcy97ZGF0YV9wb2xpY3l9Kgxk
YXRhUG9saWNpZXMyCmRhdGFQb2xpY3lCCAoGcG9saWN5QgcKBV9ldGFnIrECChFEYXRhTWFz
a2luZ1BvbGljeRKOAQoVcHJlZGVmaW5lZF9leHByZXNzaW9uGAEgASgOMlIuZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MmJldGExLkRhdGFNYXNraW5nUG9saWN5LlBy
ZWRlZmluZWRFeHByZXNzaW9uQgPgQQFIAFIUcHJlZGVmaW5lZEV4cHJlc3Npb24idQoUUHJl
ZGVmaW5lZEV4cHJlc3Npb24SJQohUFJFREVGSU5FRF9FWFBSRVNTSU9OX1VOU1BFQ0lGSUVE
EAASCgoGU0hBMjU2EAESDwoLQUxXQVlTX05VTEwQAhIZChVERUZBVUxUX01BU0tJTkdfVkFM
VUUQA0IUChJtYXNraW5nX2V4cHJlc3Npb24y9REKEURhdGFQb2xpY3lTZXJ2aWNlEvUBChBD
cmVhdGVEYXRhUG9saWN5EkMuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52
MmJldGExLkNyZWF0ZURhdGFQb2xpY3lSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5
LmRhdGFwb2xpY2llcy52MmJldGExLkRhdGFQb2xpY3kiZILT5JMCOiI1L3YyYmV0YTEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kYXRhUG9saWNpZXM6ASraQSFwYXJlbnQs
ZGF0YV9wb2xpY3ksZGF0YV9wb2xpY3lfaWQS8QEKC0FkZEdyYW50ZWVzEj4uZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MmJldGExLkFkZEdyYW50ZWVzUmVxdWVzdBo2
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjJiZXRhMS5EYXRhUG9saWN5
ImqC0+STAk0iSC92MmJldGExL3tkYXRhX3BvbGljeT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2RhdGFQb2xpY2llcy8qfTphZGRHcmFudGVlczoBKtpBFGRhdGFfcG9saWN5LGdyYW50ZWVz
EvoBCg5SZW1vdmVHcmFudGVlcxJBLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNp
ZXMudjJiZXRhMS5SZW1vdmVHcmFudGVlc1JlcXVlc3QaNi5nb29nbGUuY2xvdWQuYmlncXVl
cnkuZGF0YXBvbGljaWVzLnYyYmV0YTEuRGF0YVBvbGljeSJtgtPkkwJQIksvdjJiZXRhMS97
ZGF0YV9wb2xpY3k9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhUG9saWNpZXMvKn06cmVt
b3ZlR3JhbnRlZXM6ASraQRRkYXRhX3BvbGljeSxncmFudGVlcxKBAgoQVXBkYXRlRGF0YVBv
bGljeRJDLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjJiZXRhMS5VcGRh
dGVEYXRhUG9saWN5UmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNp
ZXMudjJiZXRhMS5EYXRhUG9saWN5InCC0+STAlAyQS92MmJldGExL3tkYXRhX3BvbGljeS5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVzLyp9OgtkYXRhX3BvbGlj
edpBF2RhdGFfcG9saWN5LHVwZGF0ZV9tYXNrErUBChBEZWxldGVEYXRhUG9saWN5EkMuZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MmJldGExLkRlbGV0ZURhdGFQb2xp
Y3lSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkSC0+STAjcqNS92MmJldGExL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVzLyp92kEEbmFtZRLPAQoN
R2V0RGF0YVBvbGljeRJALmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjJi
ZXRhMS5HZXREYXRhUG9saWN5UmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRh
cG9saWNpZXMudjJiZXRhMS5EYXRhUG9saWN5IkSC0+STAjcSNS92MmJldGExL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVzLyp92kEEbmFtZRLlAQoQTGlzdERh
dGFQb2xpY2llcxJDLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjJiZXRh
MS5MaXN0RGF0YVBvbGljaWVzUmVxdWVzdBpELmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRh
cG9saWNpZXMudjJiZXRhMS5MaXN0RGF0YVBvbGljaWVzUmVzcG9uc2UiRoLT5JMCNxI1L3Yy
YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kYXRhUG9saWNpZXPaQQZw
YXJlbnQSnAEKDEdldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuR2V0SWFtUG9saWN5UmVx
dWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IlGC0+STAksiRi92MmJldGExL3tyZXNvdXJj
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xpY2llcy8qfTpnZXRJYW1Qb2xpY3k6
ASoSnAEKDFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuU2V0SWFtUG9saWN5UmVxdWVz
dBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IlGC0+STAksiRi92MmJldGExL3tyZXNvdXJjZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xpY2llcy8qfTpzZXRJYW1Qb2xpY3k6ASoS
wgEKElRlc3RJYW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Np
b25zUmVxdWVzdBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9uc2Ui
V4LT5JMCUSJML3YyYmV0YTEve3Jlc291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0
YVBvbGljaWVzLyp9OnRlc3RJYW1QZXJtaXNzaW9uczoBKhp+ykEhYmlncXVlcnlkYXRhcG9s
aWN5Lmdvb2dsZWFwaXMuY29t0kFXaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9i
aWdxdWVyeSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3Jt
QqIDCi5jb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MmJldGExQg9E
YXRhUG9saWN5UHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS9kYXRhcG9s
aWNpZXMvYXBpdjJiZXRhMS9kYXRhcG9saWNpZXNwYjtkYXRhcG9saWNpZXNwYqoCKkdvb2ds
ZS5DbG91ZC5CaWdRdWVyeS5EYXRhUG9saWNpZXMuVjJCZXRhMcoCKkdvb2dsZVxDbG91ZFxC
aWdRdWVyeVxEYXRhUG9saWNpZXNcVjJiZXRhMeoCLkdvb2dsZTo6Q2xvdWQ6OkJpZ3F1ZXJ5
OjpEYXRhUG9saWNpZXM6OlYyYmV0YTHqQX0KJGRhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29t
L1BvbGljeVRhZxJVcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Rh
eG9ub21pZXMve3RheG9ub215fS9wb2xpY3lUYWdzL3twb2xpY3lfdGFnfUqRZAoHEgUOAJ8D
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMwoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACgKCQoCAwUS
AxcAJAoJCgIDBhIDGAAlCgkKAgMHEgMZACoKCAoBCBIDGwBHCgkKAgglEgMbAEcKCAoBCBID
HABpCgkKAggLEgMcAGkKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAwCgkKAggIEgMe
ADAKCAoBCBIDHwBHCgkKAggBEgMfAEcKCAoBCBIDIABICgkKAggpEgMgAEgKCAoBCBIDIQBH
CgkKAggtEgMhAEcKCQoBCBIEIgAlAgoMCgQInQgAEgQiACUCClcKAgYAEgUoAI8BARpKIERh
dGEgUG9saWN5IFNlcnZpY2UgcHJvdmlkZXMgQVBJcyBmb3IgbWFuYWdpbmcgdGhlIEJpZ1F1
ZXJ5IERhdGEgUG9saWN5LgoKCgoDBgABEgMoCBkKCgoDBgADEgMpAkkKDAoFBgADmQgSAykC
SQoLCgMGAAMSBCoCLDcKDQoFBgADmggSBCoCLDcKjAEKBAYAAgASBDACNgMafiBDcmVhdGVz
IGEgbmV3IGRhdGEgcG9saWN5IHVuZGVyIGEgcHJvamVjdCB3aXRoIHRoZSBnaXZlbiBgZGF0
YV9wb2xpY3lfaWRgCiAodXNlZCBhcyB0aGUgZGlzcGxheSBuYW1lKSwgYW5kIGRhdGEgcG9s
aWN5IHR5cGUuCgoMCgUGAAIAARIDMAYWCgwKBQYAAgACEgMwFy4KDAoFBgACAAMSAzA5QwoN
CgUGAAIABBIEMQQ0BgoRCgkGAAIABLDKvCISBDEENAYKDAoFBgACAAQSAzUETwoPCggGAAIA
BJsIABIDNQRPCo8CCgQGAAIBEgQ9AkMDGoACIEFkZHMgbmV3IGdyYW50ZWVzIHRvIGEgZGF0
YSBwb2xpY3kuCiBUaGUgbmV3IGdyYW50ZWVzIHdpbGwgYmUgYWRkZWQgdG8gdGhlIGV4aXN0
aW5nIGdyYW50ZWVzLgogSWYgdGhlIHJlcXVlc3QgY29udGFpbnMgYSBkdXBsaWNhdGUgZ3Jh
bnRlZSwgdGhlIGdyYW50ZWUgd2lsbCBiZSBpZ25vcmVkLgogSWYgdGhlIHJlcXVlc3QgY29u
dGFpbnMgYSBncmFudGVlIHRoYXQgYWxyZWFkeSBleGlzdHMsIHRoZSBncmFudGVlIHdpbGwg
YmUKIGlnbm9yZWQuCgoMCgUGAAIBARIDPQYRCgwKBQYAAgECEgM9EiQKDAoFBgACAQMSAz0v
OQoNCgUGAAIBBBIEPgRBBgoRCgkGAAIBBLDKvCISBD4EQQYKDAoFBgACAQQSA0IEQgoPCggG
AAIBBJsIABIDQgRCCsUBCgQGAAICEgRJAk8DGrYBIFJlbW92ZXMgZ3JhbnRlZXMgZnJvbSBh
IGRhdGEgcG9saWN5LgogVGhlIGdyYW50ZWVzIHdpbGwgYmUgcmVtb3ZlZCBmcm9tIHRoZSBl
eGlzdGluZyBncmFudGVlcy4KIElmIHRoZSByZXF1ZXN0IGNvbnRhaW5zIGEgZ3JhbnRlZSB0
aGF0IGRvZXMgbm90IGV4aXN0LCB0aGUgZ3JhbnRlZSB3aWxsIGJlCiBpZ25vcmVkLgoKDAoF
BgACAgESA0kGFAoMCgUGAAICAhIDSRUqCgwKBQYAAgIDEgNJNT8KDQoFBgACAgQSBEoETQYK
EQoJBgACAgSwyrwiEgRKBE0GCgwKBQYAAgIEEgNOBEIKDwoIBgACAgSbCAASA04EQgqAAQoE
BgACAxIEUwJZAxpyIFVwZGF0ZXMgdGhlIG1ldGFkYXRhIGZvciBhbiBleGlzdGluZyBkYXRh
IHBvbGljeS4gVGhlIHRhcmdldCBkYXRhIHBvbGljeQogY2FuIGJlIHNwZWNpZmllZCBieSB0
aGUgcmVzb3VyY2UgbmFtZS4KCgwKBQYAAgMBEgNTBhYKDAoFBgACAwISA1MXLgoMCgUGAAID
AxIDUzlDCg0KBQYAAgMEEgRUBFcGChEKCQYAAgMEsMq8IhIEVARXBgoMCgUGAAIDBBIDWARF
Cg8KCAYAAgMEmwgAEgNYBEUKRwoEBgACBBIEXAJiAxo5IERlbGV0ZXMgdGhlIGRhdGEgcG9s
aWN5IHNwZWNpZmllZCBieSBpdHMgcmVzb3VyY2UgbmFtZS4KCgwKBQYAAgQBEgNcBhYKDAoF
BgACBAISA1wXLgoMCgUGAAIEAxIDXQ8kCg0KBQYAAgQEEgReBGAGChEKCQYAAgQEsMq8IhIE
XgRgBgoMCgUGAAIEBBIDYQQyCg8KCAYAAgQEmwgAEgNhBDIKRAoEBgACBRIEZQJqAxo2IEdl
dHMgdGhlIGRhdGEgcG9saWN5IHNwZWNpZmllZCBieSBpdHMgcmVzb3VyY2UgbmFtZS4KCgwK
BQYAAgUBEgNlBhMKDAoFBgACBQISA2UUKAoMCgUGAAIFAxIDZTM9Cg0KBQYAAgUEEgRmBGgG
ChEKCQYAAgUEsMq8IhIEZgRoBgoMCgUGAAIFBBIDaQQyCg8KCAYAAgUEmwgAEgNpBDIKTgoE
BgACBhIEbQJzAxpAIExpc3QgYWxsIG9mIHRoZSBkYXRhIHBvbGljaWVzIGluIHRoZSBzcGVj
aWZpZWQgcGFyZW50IHByb2plY3QuCgoMCgUGAAIGARIDbQYWCgwKBQYAAgYCEgNtFy4KDAoF
BgACBgMSA24PJwoNCgUGAAIGBBIEbwRxBgoRCgkGAAIGBLDKvCISBG8EcQYKDAoFBgACBgQS
A3IENAoPCggGAAIGBJsIABIDcgQ0CkIKBAYAAgcSBHYCfAMaNCBHZXRzIHRoZSBJQU0gcG9s
aWN5IGZvciB0aGUgc3BlY2lmaWVkIGRhdGEgcG9saWN5LgoKDAoFBgACBwESA3YGEgoMCgUG
AAIHAhIDdhM0CgwKBQYAAgcDEgN3DyMKDQoFBgACBwQSBHgEewYKEQoJBgACBwSwyrwiEgR4
BHsGCkMKBAYAAggSBX8ChQEDGjQgU2V0cyB0aGUgSUFNIHBvbGljeSBmb3IgdGhlIHNwZWNp
ZmllZCBkYXRhIHBvbGljeS4KCgwKBQYAAggBEgN/BhIKDAoFBgACCAISA38TNAoNCgUGAAII
AxIEgAEPIwoPCgUGAAIIBBIGgQEEhAEGChMKCQYAAggEsMq8IhIGgQEEhAEGClgKBAYAAgkS
BogBAo4BAxpIIFJldHVybnMgdGhlIGNhbGxlcidzIHBlcm1pc3Npb24gb24gdGhlIHNwZWNp
ZmllZCBkYXRhIHBvbGljeSByZXNvdXJjZS4KCg0KBQYAAgkBEgSIAQYYCg0KBQYAAgkCEgSI
ARlACg0KBQYAAgkDEgSJAQ83Cg8KBQYAAgkEEgaKAQSNAQYKEwoJBgACCQSwyrwiEgaKAQSN
AQYKQAoCBAASBpIBAKQBARoyIFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIENyZWF0ZURhdGFQ
b2xpY3kgbWV0aG9kLgoKCwoDBAABEgSSAQgfCqIBCgQEAAIAEgaVAQKaAQQakQEgUmVxdWly
ZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHByb2plY3QgdGhhdCB0aGUgZGF0YSBwb2xpY3kg
d2lsbCBiZWxvbmcgdG8uCiBUaGUgZm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdF9udW1i
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9YC4KCg0KBQQAAgAFEgSVAQIICg0KBQQAAgAB
EgSVAQkPCg0KBQQAAgADEgSVARITCg8KBQQAAgAIEgaVARSaAQMKEAoIBAACAAicCAASBJYB
BCoKEQoHBAACAAifCBIGlwEEmQEFCrIBCgQEAAIBEgSfAQJFGqMBIFJlcXVpcmVkLiBVc2Vy
LWFzc2lnbmVkIChodW1hbiByZWFkYWJsZSkgSUQgb2YgdGhlIGRhdGEgcG9saWN5IHRoYXQg
bmVlZHMKIHRvIGJlIHVuaXF1ZSB3aXRoaW4gYSBwcm9qZWN0LiBVc2VkIGFzIHtkYXRhX3Bv
bGljeV9pZH0gaW4gcGFydCBvZiB0aGUKIHJlc291cmNlIG5hbWUuCgoNCgUEAAIBBRIEnwEC
CAoNCgUEAAIBARIEnwEJFwoNCgUEAAIBAxIEnwEaGwoNCgUEAAIBCBIEnwEcRAoQCggEAAIB
CJwIABIEnwEdQwqBAQoEBAACAhIEowECRhpzIFJlcXVpcmVkLiBUaGUgZGF0YSBwb2xpY3kg
dG8gY3JlYXRlLiBUaGUgYG5hbWVgIGZpZWxkIGRvZXMgbm90IG5lZWQgdG8gYmUKIHByb3Zp
ZGVkIGZvciB0aGUgZGF0YSBwb2xpY3kgY3JlYXRpb24uCgoNCgUEAAICBhIEowECDAoNCgUE
AAICARIEowENGAoNCgUEAAICAxIEowEbHAoNCgUEAAICCBIEowEdRQoQCggEAAICCJwIABIE
owEeRApACgIEARIGpwEAtgEBGjIgUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgVXBkYXRlRGF0
YVBvbGljeSBtZXRob2QuCgoLCgMEAQESBKcBCB8KxQEKBAQBAgASBKwBAkYatgEgUmVxdWly
ZWQuIFVwZGF0ZSB0aGUgZGF0YSBwb2xpY3kncyBtZXRhZGF0YS4KCiBUaGUgdGFyZ2V0IGRh
dGEgcG9saWN5IGlzIGRldGVybWluZWQgYnkgdGhlIGBuYW1lYCBmaWVsZC4KIE90aGVyIGZp
ZWxkcyBhcmUgdXBkYXRlZCB0byB0aGUgc3BlY2lmaWVkIHZhbHVlcyBiYXNlZCBvbiB0aGUg
ZmllbGQgbWFza3MuCgoNCgUEAQIABhIErAECDAoNCgUEAQIAARIErAENGAoNCgUEAQIAAxIE
rAEbHAoNCgUEAQIACBIErAEdRQoQCggEAQIACJwIABIErAEeRArNAgoEBAECARIGtAECtQEv
GrwCIE9wdGlvbmFsLiBUaGUgdXBkYXRlIG1hc2sgYXBwbGllcyB0byB0aGUgcmVzb3VyY2Uu
IEZvciB0aGUgYEZpZWxkTWFza2AKIGRlZmluaXRpb24sIHNlZQogaHR0cHM6Ly9kZXZlbG9w
ZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUu
cHJvdG9idWYjZmllbGRtYXNrCiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byBhbGwgb2YgdGhl
IGZpZWxkcyB0aGF0IGFyZSBhbGxvd2VkIHRvIHVwZGF0ZS4KCiBVcGRhdGVzIHRvIHRoZSBg
bmFtZWAgYW5kIGBkYXRhUG9saWN5SWRgIGZpZWxkcyBhcmUgbm90IGFsbG93ZWQuCgoNCgUE
AQIBBhIEtAECGwoNCgUEAQIBARIEtAEcJwoNCgUEAQIBAxIEtAEqKwoNCgUEAQIBCBIEtQEG
LgoQCggEAQIBCJwIABIEtQEHLQo7CgIEAhIGuQEAzwEBGi0gUmVxdWVzdCBtZXNzYWdlIGZv
ciB0aGUgQWRkR3JhbnRlZXMgbWV0aG9kLgoKCwoDBAIBEgS5AQgaCqQBCgQEAgIAEga8AQLB
AQQakwEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhpcyBkYXRhIHBvbGljeSwgaW4g
dGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbl9pZH0vZGF0YVBvbGljaWVzL3tkYXRhX3BvbGljeV9pZH1gLgoKDQoFBAICAAUS
BLwBAggKDQoFBAICAAESBLwBCRQKDQoFBAICAAMSBLwBFxgKDwoFBAICAAgSBrwBGcEBAwoQ
CggEAgIACJwIABIEvQEEKgoRCgcEAgIACJ8IEga+AQTAAQUK7wIKBAQCAgESBM4BAkga4AIg
UmVxdWlyZWQuIElBTSBwcmluY2lwYWwgdGhhdCBzaG91bGQgYmUgZ3JhbnRlZCBGaW5lIEdy
YWluZWQgQWNjZXNzIHRvIHRoZQogdW5kZXJseWluZyBkYXRhIGdvdmVyZW5lZCBieSB0aGUg
ZGF0YSBwb2xpY3kuIFRoZSB0YXJnZXQgZGF0YSBwb2xpY3kgaXMKIGRldGVybWluZWQgYnkg
dGhlIGBkYXRhX3BvbGljeWAgZmllbGQuCgogVXNlcyB0aGUgW0lBTSBWMiBwcmluY2lwYWwK
IHN5bnRheF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9kb2NzL3ByaW5jaXBhbC1p
ZGVudGlmaWVycyN2MikuCiBTdXBwb3J0ZWQgcHJpbmNpcGFsIHR5cGVzOgoKICogVXNlcgog
KiBHcm91cAogKiBTZXJ2aWNlIGFjY291bnQKCg0KBQQCAgEEEgTOAQIKCg0KBQQCAgEFEgTO
AQsRCg0KBQQCAgEBEgTOARIaCg0KBQQCAgEDEgTOAR0eCg0KBQQCAgEIEgTOAR9HChAKCAQC
AgEInAgAEgTOASBGCj4KAgQDEgbSAQDoAQEaMCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBS
ZW1vdmVHcmFudGVlcyBtZXRob2QuCgoLCgMEAwESBNIBCB0KpAEKBAQDAgASBtUBAtoBBBqT
ASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGlzIGRhdGEgcG9saWN5LCBpbiB0aGUg
Zm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0
aW9uX2lkfS9kYXRhUG9saWNpZXMve2RhdGFfcG9saWN5X2lkfWAuCgoNCgUEAwIABRIE1QEC
CAoNCgUEAwIAARIE1QEJFAoNCgUEAwIAAxIE1QEXGAoPCgUEAwIACBIG1QEZ2gEDChAKCAQD
AgAInAgAEgTWAQQqChEKBwQDAgAInwgSBtcBBNkBBQr0AgoEBAMCARIE5wECSBrlAiBSZXF1
aXJlZC4gSUFNIHByaW5jaXBhbCB0aGF0IHNob3VsZCBiZSByZXZva2VkIGZyb20gRmluZSBH
cmFpbmVkIEFjY2VzcyB0bwogdGhlIHVuZGVybHlpbmcgZGF0YSBnb3ZlcmVuZWQgYnkgdGhl
IGRhdGEgcG9saWN5LiBUaGUgdGFyZ2V0IGRhdGEgcG9saWN5IGlzCiBkZXRlcm1pbmVkIGJ5
IHRoZSBgZGF0YV9wb2xpY3lgIGZpZWxkLgoKIFVzZXMgdGhlIFtJQU0gVjIgcHJpbmNpcGFs
CiBzeW50YXhdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYW0vZG9jcy9wcmluY2lwYWwt
aWRlbnRpZmllcnMjdjIpLgogU3VwcG9ydGVkIHByaW5jaXBhbCB0eXBlczoKCiAqIFVzZXIK
ICogR3JvdXAKICogU2VydmljZSBhY2NvdW50CgoNCgUEAwIBBBIE5wECCgoNCgUEAwIBBRIE
5wELEQoNCgUEAwIBARIE5wESGgoNCgUEAwIBAxIE5wEdHgoNCgUEAwIBCBIE5wEfRwoQCggE
AwIBCJwIABIE5wEgRgpACgIEBBIG6wEA9AEBGjIgUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUg
RGVsZXRlRGF0YVBvbGljeSBtZXRob2QuCgoLCgMEBAESBOsBCB8KmgEKBAQEAgASBu4BAvMB
BBqJASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgZGF0YSBwb2xpY3kgdG8gZGVs
ZXRlLiBGb3JtYXQgaXMKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb25faWR9L2RhdGFQb2xpY2llcy97aWR9YC4KCg0KBQQEAgAFEgTuAQIICg0KBQQE
AgABEgTuAQkNCg0KBQQEAgADEgTuARARCg8KBQQEAgAIEgbuARLzAQMKEAoIBAQCAAicCAAS
BO8BBCoKEQoHBAQCAAifCBIG8AEE8gEFCj0KAgQFEgb3AQCAAgEaLyBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIHRoZSBHZXREYXRhUG9saWN5IG1ldGhvZC4KCgsKAwQFARIE9wEIHAqaAQoEBAUC
ABIG+gEC/wEEGokBIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSByZXF1ZXN0ZWQg
ZGF0YSBwb2xpY3kuIEZvcm1hdCBpcwogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9j
YXRpb25zL3tsb2NhdGlvbl9pZH0vZGF0YVBvbGljaWVzL3tpZH1gLgoKDQoFBAUCAAUSBPoB
AggKDQoFBAUCAAESBPoBCQ0KDQoFBAUCAAMSBPoBEBEKDwoFBAUCAAgSBvoBEv8BAwoQCggE
BQIACJwIABIE+wEEKgoRCgcEBQIACJ8IEgb8AQT+AQUKQAoCBAYSBoMCAJQCARoyIFJlcXVl
c3QgbWVzc2FnZSBmb3IgdGhlIExpc3REYXRhUG9saWNpZXMgbWV0aG9kLgoKCwoDBAYBEgSD
AggfCpoBCgQEBgIAEgaGAgKLAgQaiQEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhl
IHByb2plY3QgZm9yIHdoaWNoIHRvIGxpc3QgZGF0YSBwb2xpY2llcy4KIEZvcm1hdCBpcyBg
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfWAuCgoN
CgUEBgIABRIEhgICCAoNCgUEBgIAARIEhgIJDwoNCgUEBgIAAxIEhgISEwoPCgUEBgIACBIG
hgIUiwIDChAKCAQGAgAInAgAEgSHAgQqChEKBwQGAgAInwgSBogCBIoCBQqJAQoEBAYCARIE
jwICPxp7IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgZGF0YSBwb2xpY2llcyB0
byByZXR1cm4uIE11c3QgYmUgYSB2YWx1ZQogYmV0d2VlbiAxIGFuZCAxMDAwLiBJZiBub3Qg
c2V0LCBkZWZhdWx0cyB0byA1MC4KCg0KBQQGAgEFEgSPAgIHCg0KBQQGAgEBEgSPAggRCg0K
BQQGAgEDEgSPAhQVCg0KBQQGAgEIEgSPAhY+ChAKCAQGAgEInAgAEgSPAhc9CowBCgQEBgIC
EgSTAgJBGn4gT3B0aW9uYWwuIFRoZSBgbmV4dFBhZ2VUb2tlbmAgdmFsdWUgcmV0dXJuZWQg
ZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdCwKIGlmIGFueS4gSWYgbm90IHNldCwgZGVm
YXVsdHMgdG8gYW4gZW1wdHkgc3RyaW5nLgoKDQoFBAYCAgUSBJMCAggKDQoFBAYCAgESBJMC
CRMKDQoFBAYCAgMSBJMCFhcKDQoFBAYCAggSBJMCGEAKEAoIBAYCAgicCAASBJMCGT8KQQoC
BAcSBpcCAJ4CARozIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIHRoZSBMaXN0RGF0YVBvbGljaWVz
IG1ldGhvZC4KCgsKAwQHARIElwIIIApDCgQEBwIAEgSZAgIoGjUgRGF0YSBwb2xpY2llcyB0
aGF0IGJlbG9uZyB0byB0aGUgcmVxdWVzdGVkIHByb2plY3QuCgoNCgUEBwIABBIEmQICCgoN
CgUEBwIABhIEmQILFQoNCgUEBwIAARIEmQIWIwoNCgUEBwIAAxIEmQImJwpoCgQEBwIBEgSd
AgIdGlogVG9rZW4gdXNlZCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMs
IG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSByZXN1bHRzLgoKDQoFBAcCAQUSBJ0C
AggKDQoFBAcCAQESBJ0CCRgKDQoFBAcCAQMSBJ0CGxwKNAoCBAgSBqECAPMCARomIFJlcHJl
c2VudHMgdGhlIGxhYmVsLXBvbGljeSBiaW5kaW5nLgoKCwoDBAgBEgShAggSCg0KAwQIBxIG
ogICpwIECg8KBQQIB50IEgaiAgKnAgQKOAoEBAgEABIGqgICswIDGiggQSBsaXN0IG9mIHN1
cHBvcnRlZCBkYXRhIHBvbGljeSB0eXBlcy4KCg0KBQQIBAABEgSqAgcVClIKBgQIBAACABIE
rAIEJRpCIERlZmF1bHQgdmFsdWUgZm9yIHRoZSBkYXRhIHBvbGljeSB0eXBlLiBUaGlzIHNo
b3VsZCBub3QgYmUgdXNlZC4KCg8KBwQIBAACAAESBKwCBCAKDwoHBAgEAAIAAhIErAIjJApA
CgYECAQAAgESBK8CBBwaMCBVc2VkIHRvIGNyZWF0ZSBhIGRhdGEgcG9saWN5IGZvciBkYXRh
IG1hc2tpbmcuCgoPCgcECAQAAgEBEgSvAgQXCg8KBwQIBAACAQISBK8CGhsKQwoGBAgEAAIC
EgSyAgQfGjMgVXNlZCB0byBjcmVhdGUgYSBkYXRhIHBvbGljeSBmb3IgcmF3IGRhdGEgYWNj
ZXNzLgoKDwoHBAgEAAICARIEsgIEGgoPCgcECAQAAgICEgSyAh0eCkYKBAQIBAESBrYCAsAC
Axo2IFRoZSBzdXBwb3J0ZWQgdmVyc2lvbnMgZm9yIHRoZSBEYXRhIFBvbGljeSByZXNvdXJj
ZS4KCg0KBQQIBAEBEgS2AgcOClUKBgQIBAECABIEuAIEHBpFIERlZmF1bHQgdmFsdWUgZm9y
IHRoZSBkYXRhIHBvbGljeSB2ZXJzaW9uLiBUaGlzIHNob3VsZCBub3QgYmUgdXNlZC4KCg8K
BwQIBAECAAESBLgCBBcKDwoHBAgEAQIAAhIEuAIaGwqZAQoGBAgEAQIBEgS8AgQLGogBIFYx
IGRhdGEgcG9saWN5IHZlcnNpb24uIFYxIERhdGEgUG9saWNpZXMgd2lsbCBiZSBwcmVzZW50
IGluIFYyIExpc3QgYXBpCiByZXNwb25zZSwgYnV0IGNhbiBub3QgYmUgY3JlYXRlZC91cGRh
dGVkL2RlbGV0ZWQgZnJvbSBWMiBhcGkuCgoPCgcECAQBAgEBEgS8AgQGCg8KBwQIBAECAQIS
BLwCCQoKKQoGBAgEAQICEgS/AgQLGhkgVjIgZGF0YSBwb2xpY3kgdmVyc2lvbi4KCg8KBwQI
BAECAgESBL8CBAYKDwoHBAgEAQICAhIEvwIJCgo/CgQECAgAEgbDAgLIAgMaLyBUaGUgcG9s
aWN5IHRoYXQgaXMgYm91bmQgdG8gdGhpcyBkYXRhIHBvbGljeS4KCg0KBQQICAABEgTDAggO
CqEBCgQECAIAEgbGAgTHAjEakAEgT3B0aW9uYWwuIFRoZSBkYXRhIG1hc2tpbmcgcG9saWN5
IHRoYXQgc3BlY2lmaWVzIHRoZSBkYXRhIG1hc2tpbmcgcnVsZSB0bwogdXNlLiBJdCBtdXN0
IGJlIHNldCBpZiB0aGUgZGF0YSBwb2xpY3kgdHlwZSBpcyBEQVRBX01BU0tJTkdfUE9MSUNZ
LgoKDQoFBAgCAAYSBMYCBBUKDQoFBAgCAAESBMYCFikKDQoFBAgCAAMSBMYCLC0KDQoFBAgC
AAgSBMcCCDAKEAoIBAgCAAicCAASBMcCCS8KpAEKBAQIAgESBMwCAj0alQEgSWRlbnRpZmll
ci4gUmVzb3VyY2UgbmFtZSBvZiB0aGlzIGRhdGEgcG9saWN5LCBpbiB0aGUgZm9ybWF0IG9m
CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9k
YXRhUG9saWNpZXMve2RhdGFfcG9saWN5X2lkfWAuCgoNCgUECAIBBRIEzAICCAoNCgUECAIB
ARIEzAIJDQoNCgUECAIBAxIEzAIQEQoNCgUECAIBCBIEzAISPAoQCggECAIBCJwIABIEzAIT
Owq1AQoEBAgCAhIE0QICSBqmASBPdXRwdXQgb25seS4gVXNlci1hc3NpZ25lZCAoaHVtYW4g
cmVhZGFibGUpIElEIG9mIHRoZSBkYXRhIHBvbGljeSB0aGF0CiBuZWVkcyB0byBiZSB1bmlx
dWUgd2l0aGluIGEgcHJvamVjdC4gVXNlZCBhcyB7ZGF0YV9wb2xpY3lfaWR9IGluIHBhcnQg
b2YKIHRoZSByZXNvdXJjZSBuYW1lLgoKDQoFBAgCAgUSBNECAggKDQoFBAgCAgESBNECCRcK
DQoFBAgCAgMSBNECGhsKDQoFBAgCAggSBNECHEcKEAoIBAgCAgicCAASBNECHUYKnAIKBAQI
AgMSBNgCAhwajQIgVGhlIGV0YWcgZm9yIHRoaXMgRGF0YSBQb2xpY3kuCiBUaGlzIGZpZWxk
IGlzIHVzZWQgZm9yIFVwZGF0ZURhdGFQb2xpY3kgY2FsbHMuIElmIERhdGEgUG9saWN5IGV4
aXN0cywgdGhpcwogZmllbGQgaXMgcmVxdWlyZWQgYW5kIG11c3QgbWF0Y2ggdGhlIHNlcnZl
cidzIGV0YWcuIEl0IHdpbGwgYWxzbyBiZQogcG9wdWxhdGVkIGluIHRoZSByZXNwb25zZSBv
ZiBHZXREYXRhUG9saWN5LCBDcmVhdGVEYXRhUG9saWN5LCBhbmQKIFVwZGF0ZURhdGFQb2xp
Y3kgY2FsbHMuCgoNCgUECAIDBBIE2AICCgoNCgUECAIDBRIE2AILEQoNCgUECAIDARIE2AIS
FgoNCgUECAIDAxIE2AIZGwouCgQECAIEEgTbAgJPGiAgUmVxdWlyZWQuIFR5cGUgb2YgZGF0
YSBwb2xpY3kuCgoNCgUECAIEBhIE2wICEAoNCgUECAIEARIE2wIRIQoNCgUECAIEAxIE2wIk
JQoNCgUECAIECBIE2wImTgoQCggECAIECJwIABIE2wInTQrnAQoEBAgCBRIG4AIC5QIEGtYB
IE91dHB1dCBvbmx5LiBQb2xpY3kgdGFnIHJlc291cmNlIG5hbWUsIGluIHRoZSBmb3JtYXQg
b2YKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9
L3RheG9ub21pZXMve3RheG9ub215X2lkfS9wb2xpY3lUYWdzL3twb2xpY3lUYWdfaWR9YC4K
IHBvbGljeV90YWcgaXMgc3VwcG9ydGVkIG9ubHkgZm9yIFYxIGRhdGEgcG9saWNpZXMuCgoN
CgUECAIFBRIE4AICCAoNCgUECAIFARIE4AIJEwoNCgUECAIFAxIE4AIWFwoPCgUECAIFCBIG
4AIY5QIDChAKCAQIAgUInAgAEgThAgQtChEKBwQIAgUInwgSBuICBOQCBQrOAwoEBAgCBhIE
7wICSBq/AyBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgSUFNIHByaW5jaXBhbHMgdGhhdCBoYXZl
IEZpbmUgR3JhaW5lZCBBY2Nlc3MgdG8gdGhlCiB1bmRlcmx5aW5nIGRhdGEgZ292ZXJlbmVk
IGJ5IHRoaXMgZGF0YSBwb2xpY3kuCgogVXNlcyB0aGUgW0lBTSBWMiBwcmluY2lwYWwKIHN5
bnRheF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9kb2NzL3ByaW5jaXBhbC1pZGVu
dGlmaWVycyN2MikgT25seQogc3VwcG9ydHMgcHJpbmNpcGFsIHR5cGVzIHVzZXJzLCBncm91
cHMsIHNlcnZpY2VhY2NvdW50cywgY2xvdWRpZGVudGl0eS4KIFRoaXMgZmllbGQgaXMgc3Vw
cG9ydGVkIGluIFYyIERhdGEgUG9saWN5IG9ubHkuIEluIGNhc2Ugb2YgVjEgZGF0YSBwb2xp
Y2llcwogKGkuZS4gdmVyaW9uID0gMSBhbmQgcG9saWN5X3RhZyBpcyBzZXQpLCB0aGlzIGZp
ZWxkIGlzIG5vdCBwb3B1bGF0ZWQuCgoNCgUECAIGBBIE7wICCgoNCgUECAIGBRIE7wILEQoN
CgUECAIGARIE7wISGgoNCgUECAIGAxIE7wIdHgoNCgUECAIGCBIE7wIfRwoQCggECAIGCJwI
ABIE7wIgRgpFCgQECAIHEgTyAgJCGjcgT3V0cHV0IG9ubHkuIFRoZSB2ZXJzaW9uIG9mIHRo
ZSBEYXRhIFBvbGljeSByZXNvdXJjZS4KCg0KBQQIAgcGEgTyAgIJCg0KBQQIAgcBEgTyAgoR
Cg0KBQQIAgcDEgTyAhQVCg0KBQQIAgcIEgTyAhZBChAKCAQIAgcInAgAEgTyAhdACj0KAgQJ
Egb2AgCfAwEaLyBUaGUgcG9saWN5IHVzZWQgdG8gc3BlY2lmeSBkYXRhIG1hc2tpbmcgcnVs
ZS4KCgsKAwQJARIE9gIIGQqTAQoEBAkEABIG+QIClwMDGoIBIFRoZSBhdmFpbGFibGUgbWFz
a2luZyBydWxlcy4gTGVhcm4gbW9yZSBoZXJlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L2JpZ3F1ZXJ5L2RvY3MvY29sdW1uLWRhdGEtbWFza2luZy1pbnRybyNtYXNraW5nX29wdGlv
bnMuCgoNCgUECQQAARIE+QIHGwp7CgYECQQAAgASBPwCBCoaayBEZWZhdWx0LCB1bnNwZWNp
ZmllZCBwcmVkZWZpbmVkIGV4cHJlc3Npb24uIE5vIG1hc2tpbmcgd2lsbCB0YWtlIHBsYWNl
CiBzaW5jZSBubyBleHByZXNzaW9uIGlzIHNwZWNpZmllZC4KCg8KBwQJBAACAAESBPwCBCUK
DwoHBAkEAAIAAhIE/AIoKQpHCgYECQQAAgESBP8CBA8aNyBNYXNraW5nIGV4cHJlc3Npb24g
dG8gcmVwbGFjZSBkYXRhIHdpdGggU0hBLTI1NiBoYXNoLgoKDwoHBAkEAAIBARIE/wIECgoP
CgcECQQAAgECEgT/Ag0OCkAKBgQJBAACAhIEggMEFBowIE1hc2tpbmcgZXhwcmVzc2lvbiB0
byByZXBsYWNlIGRhdGEgd2l0aCBOVUxMcy4KCg8KBwQJBAACAgESBIIDBA8KDwoHBAkEAAIC
AhIEggMSEwq4AwoGBAkEAAIDEgSWAwQeGqcDIE1hc2tpbmcgZXhwcmVzc2lvbiB0byByZXBs
YWNlIGRhdGEgd2l0aCB0aGVpciBkZWZhdWx0IG1hc2tpbmcgdmFsdWVzLgogVGhlIGRlZmF1
bHQgbWFza2luZyB2YWx1ZXMgZm9yIGVhY2ggdHlwZSBsaXN0ZWQgYXMgYmVsb3c6CgogKiBT
VFJJTkc6ICIiCiAqIEJZVEVTOiBiJycKICogSU5URUdFUjogMAogKiBGTE9BVDogMC4wCiAq
IE5VTUVSSUM6IDAKICogQk9PTEVBTjogRkFMU0UKICogVElNRVNUQU1QOiAxOTcwLTAxLTAx
IDAwOjAwOjAwIFVUQwogKiBEQVRFOiAxOTcwLTAxLTAxCiAqIFRJTUU6IDAwOjAwOjAwCiAq
IERBVEVUSU1FOiAxOTcwLTAxLTAxVDAwOjAwOjAwCiAqIEdFT0dSQVBIWTogUE9JTlQoMCAw
KQogKiBCSUdOVU1FUklDOiAwCiAqIEFSUkFZOiBbXQogKiBTVFJVQ1Q6IE5PVF9BUFBMSUNB
QkxFCiAqIEpTT046IE5VTEwKCg8KBwQJBAACAwESBJYDBBkKDwoHBAkEAAIDAhIElgMcHQpI
CgQECQgAEgaaAwKeAwMaOCBBIG1hc2tpbmcgZXhwcmVzc2lvbiB0byBiaW5kIHRvIHRoZSBk
YXRhIG1hc2tpbmcgcnVsZS4KCg0KBQQJCAABEgSaAwgaCjwKBAQJAgASBpwDBJ0DMRosIE9w
dGlvbmFsLiBBIHByZWRlZmluZWQgbWFza2luZyBleHByZXNzaW9uLgoKDQoFBAkCAAYSBJwD
BBgKDQoFBAkCAAESBJwDGS4KDQoFBAkCAAMSBJwDMTIKDQoFBAkCAAgSBJ0DCDAKEAoIBAkC
AAicCAASBJ0DCS9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::CreateDataPolicyRequest ===
    # Fields for CreateDataPolicyRequest
    # Field: parent Type: 9 ()
    # Field: data_policy_id Type: 9 ()
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v2beta1.DataPolicy)

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::UpdateDataPolicyRequest ===
    # Fields for UpdateDataPolicyRequest
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v2beta1.DataPolicy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::AddGranteesRequest ===
    # Fields for AddGranteesRequest
    # Field: data_policy Type: 9 ()
    # Field: grantees Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::RemoveGranteesRequest ===
    # Fields for RemoveGranteesRequest
    # Field: data_policy Type: 9 ()
    # Field: grantees Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DeleteDataPolicyRequest ===
    # Fields for DeleteDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::GetDataPolicyRequest ===
    # Fields for GetDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::ListDataPoliciesRequest ===
    # Fields for ListDataPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::ListDataPoliciesResponse ===
    # Fields for ListDataPoliciesResponse
    # Field: data_policies Type: 11 (.google.cloud.bigquery.datapolicies.v2beta1.DataPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy ===
    # Fields for DataPolicy
    # Field: data_masking_policy Type: 11 (.google.cloud.bigquery.datapolicies.v2beta1.DataMaskingPolicy)
    # Field: name Type: 9 ()
    # Field: data_policy_id Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: data_policy_type Type: 14 (.google.cloud.bigquery.datapolicies.v2beta1.DataPolicy.DataPolicyType)
    # Field: policy_tag Type: 9 ()
    # Field: grantees Type: 9 ()
    # Field: version Type: 14 (.google.cloud.bigquery.datapolicies.v2beta1.DataPolicy.Version)

# Enum: DataPolicy::DataPolicyType
our $DataPolicy_DATA_POLICY_TYPE_UNSPECIFIED = 0;
our $DataPolicy_DATA_MASKING_POLICY = 1;
our $DataPolicy_RAW_DATA_ACCESS_POLICY = 2;

# Enum: DataPolicy::Version
our $DataPolicy_VERSION_UNSPECIFIED = 0;
our $DataPolicy_V1 = 1;
our $DataPolicy_V2 = 2;

# === Message: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataMaskingPolicy ===
    # Fields for DataMaskingPolicy
    # Field: predefined_expression Type: 14 (.google.cloud.bigquery.datapolicies.v2beta1.DataMaskingPolicy.PredefinedExpression)

# Enum: DataMaskingPolicy::PredefinedExpression
our $DataMaskingPolicy_PREDEFINED_EXPRESSION_UNSPECIFIED = 0;
our $DataMaskingPolicy_SHA256 = 1;
our $DataMaskingPolicy_ALWAYS_NULL = 2;
our $DataMaskingPolicy_DEFAULT_MASKING_VALUE = 3;

# === Service Client: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicyServiceClient ===
package Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicyServiceClient

Client stub representing the remote C<DataPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::CreateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'CreateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy',
    });
}

sub add_grantees {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::AddGranteesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'AddGrantees',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy',
    });
}

sub remove_grantees {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::RemoveGranteesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'RemoveGrantees',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy',
    });
}

sub update_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::UpdateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'UpdateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy',
    });
}

sub delete_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DeleteDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'DeleteDataPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::GetDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'GetDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy',
    });
}

sub list_data_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::ListDataPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'ListDataPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::ListDataPoliciesResponse',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2beta1.DataPolicyService',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy - Compiled Protocol Buffers messages for google/cloud/bigquery/datapolicies/v2beta1/datapolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy;

    my $msg = Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::CreateDataPolicyRequest->new({
        parent => $parent,
        data_policy_id => $data_policy_id,
        data_policy => $data_policy,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::CreateDataPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/datapolicies/v2beta1/datapolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::CreateDataPolicyRequest

Request message for the CreateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the data policy will belong to.
The format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->data_policy_id() >> / C<< $msg->data_policy_id($value) >>

Type: C<String>

Required. User-assigned (human readable) ID of the data policy that needs
to be unique within a project. Used as {data_policy_id} in part of the
resource name.

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy>)

Required. The data policy to create. The `name` field does not need to be
provided for the data policy creation.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::UpdateDataPolicyRequest

Request message for the UpdateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy>)

Required. Update the data policy's metadata.

The target data policy is determined by the `name` field.
Other fields are updated to the specified values based on the field masks.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The update mask applies to the resource. For the `FieldMask`
definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
If not set, defaults to all of the fields that are allowed to update.

Updates to the `name` and `dataPolicyId` fields are not allowed.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::AddGranteesRequest

Request message for the AddGrantees method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<String>

Required. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Required. IAM principal that should be granted Fine Grained Access to the
underlying data goverened by the data policy. The target data policy is
determined by the `data_policy` field.

Uses the [IAM V2 principal
syntax](https://cloud.google.com/iam/docs/principal-identifiers#v2).
Supported principal types:

* User
* Group
* Service account

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::RemoveGranteesRequest

Request message for the RemoveGrantees method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<String>

Required. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Required. IAM principal that should be revoked from Fine Grained Access to
the underlying data goverened by the data policy. The target data policy is
determined by the `data_policy` field.

Uses the [IAM V2 principal
syntax](https://cloud.google.com/iam/docs/principal-identifiers#v2).
Supported principal types:

* User
* Group
* Service account

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DeleteDataPolicyRequest

Request message for the DeleteDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the data policy to delete. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::GetDataPolicyRequest

Request message for the GetDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the requested data policy. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::ListDataPoliciesRequest

Request message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project for which to list data policies.
Format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of data policies to return. Must be a value
between 1 and 1000. If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The `nextPageToken` value returned from a previous list request,
if any. If not set, defaults to an empty string.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::ListDataPoliciesResponse

Response message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policies() >> / C<< $msg->data_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy>)

Data policies that belong to the requested project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token used to retrieve the next page of results, or empty if there are no
more results.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataPolicy

Represents the label-policy binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_masking_policy() >> / C<< $msg->data_masking_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataMaskingPolicy>)

Optional. The data masking policy that specifies the data masking rule to
use. It must be set if the data policy type is DATA_MASKING_POLICY.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->data_policy_id() >> / C<< $msg->data_policy_id($value) >>

Type: C<String>

Output only. User-assigned (human readable) ID of the data policy that
needs to be unique within a project. Used as {data_policy_id} in part of
the resource name.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

The etag for this Data Policy.
This field is used for UpdateDataPolicy calls. If Data Policy exists, this
field is required and must match the server's etag. It will also be
populated in the response of GetDataPolicy, CreateDataPolicy, and
UpdateDataPolicy calls.

=item * C<< $msg->data_policy_type() >> / C<< $msg->data_policy_type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::DataPolicy::DataPolicyType>)

Required. Type of data policy.

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<String>

Output only. Policy tag resource name, in the format of
`projects/{project_number}/locations/{location_id}/taxonomies/{taxonomy_id}/policyTags/{policyTag_id}`.
policy_tag is supported only for V1 data policies.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Optional. The list of IAM principals that have Fine Grained Access to the
underlying data goverened by this data policy.

Uses the [IAM V2 principal
syntax](https://cloud.google.com/iam/docs/principal-identifiers#v2) Only
supports principal types users, groups, serviceaccounts, cloudidentity.
This field is supported in V2 Data Policy only. In case of V1 data policies
(i.e. verion = 1 and policy_tag is set), this field is not populated.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::DataPolicy::Version>)

Output only. The version of the Data Policy resource.

=back

=head3 Enum: DataPolicy::DataPolicyType

=over 4

=item * C<DATA_POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<DATA_MASKING_POLICY> => C<1>

=item * C<RAW_DATA_ACCESS_POLICY> => C<2>

=back

=head3 Enum: DataPolicy::Version

=over 4

=item * C<VERSION_UNSPECIFIED> => C<0>

=item * C<V1> => C<1>

=item * C<V2> => C<2>

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::DataMaskingPolicy

The policy used to specify data masking rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predefined_expression() >> / C<< $msg->predefined_expression($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V2beta1::DataMaskingPolicy::PredefinedExpression>)

Optional. A predefined masking expression.

=back

=head3 Enum: DataMaskingPolicy::PredefinedExpression

=over 4

=item * C<PREDEFINED_EXPRESSION_UNSPECIFIED> => C<0>

=item * C<SHA256> => C<1>

=item * C<ALWAYS_NULL> => C<2>

=item * C<DEFAULT_MASKING_VALUE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Datapolicies::V2beta1::Datapolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
