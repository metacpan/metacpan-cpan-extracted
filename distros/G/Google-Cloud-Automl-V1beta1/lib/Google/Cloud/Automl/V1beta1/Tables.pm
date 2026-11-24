package Google::Cloud::Automl::V1beta1::Tables;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    eval { require Google::Cloud::Automl::V1beta1::ColumnSpec };
    eval { require Google::Cloud::Automl::V1beta1::DataItems };
    eval { require Google::Cloud::Automl::V1beta1::DataStats };
    eval { require Google::Cloud::Automl::V1beta1::Ranges };
    eval { require Google::Cloud::Automl::V1beta1::Regression };
    eval { require Google::Cloud::Automl::V1beta1::Temporal };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGFibGVzLnByb3RvEhtnb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTEaMGdvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS9jbGFzc2lm
aWNhdGlvbi5wcm90bxotZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2NvbHVtbl9zcGVj
LnByb3RvGixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZGF0YV9pdGVtcy5wcm90bxos
Z29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2RhdGFfc3RhdHMucHJvdG8aKGdvb2dsZS9j
bG91ZC9hdXRvbWwvdjFiZXRhMS9yYW5nZXMucHJvdG8aLGdvb2dsZS9jbG91ZC9hdXRvbWwv
djFiZXRhMS9yZWdyZXNzaW9uLnByb3RvGipnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEv
dGVtcG9yYWwucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8itwQKFVRhYmxlc0RhdGFzZXRNZXRhZGF0YRIxChVw
cmltYXJ5X3RhYmxlX3NwZWNfaWQYASABKAlSEnByaW1hcnlUYWJsZVNwZWNJZBIxChV0YXJn
ZXRfY29sdW1uX3NwZWNfaWQYAiABKAlSEnRhcmdldENvbHVtblNwZWNJZBIxChV3ZWlnaHRf
Y29sdW1uX3NwZWNfaWQYAyABKAlSEndlaWdodENvbHVtblNwZWNJZBIwChVtbF91c2VfY29s
dW1uX3NwZWNfaWQYBCABKAlSEW1sVXNlQ29sdW1uU3BlY0lkEo4BChp0YXJnZXRfY29sdW1u
X2NvcnJlbGF0aW9ucxgGIAMoCzJQLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UYWJs
ZXNEYXRhc2V0TWV0YWRhdGEuVGFyZ2V0Q29sdW1uQ29ycmVsYXRpb25zRW50cnlSGHRhcmdl
dENvbHVtbkNvcnJlbGF0aW9ucxJGChFzdGF0c191cGRhdGVfdGltZRgHIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSD3N0YXRzVXBkYXRlVGltZRp6Ch1UYXJnZXRDb2x1bW5D
b3JyZWxhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJDCgV2YWx1ZRgCIAEoCzItLmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Db3JyZWxhdGlvblN0YXRzUgV2YWx1ZToCOAEi
gAYKE1RhYmxlc01vZGVsTWV0YWRhdGESTwojb3B0aW1pemF0aW9uX29iamVjdGl2ZV9yZWNh
bGxfdmFsdWUYESABKAJIAFIgb3B0aW1pemF0aW9uT2JqZWN0aXZlUmVjYWxsVmFsdWUSVQom
b3B0aW1pemF0aW9uX29iamVjdGl2ZV9wcmVjaXNpb25fdmFsdWUYEiABKAJIAFIjb3B0aW1p
emF0aW9uT2JqZWN0aXZlUHJlY2lzaW9uVmFsdWUSVQoSdGFyZ2V0X2NvbHVtbl9zcGVjGAIg
ASgLMicuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkNvbHVtblNwZWNSEHRhcmdldENv
bHVtblNwZWMSZAoaaW5wdXRfZmVhdHVyZV9jb2x1bW5fc3BlY3MYAyADKAsyJy5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxYmV0YTEuQ29sdW1uU3BlY1IXaW5wdXRGZWF0dXJlQ29sdW1uU3Bl
Y3MSNQoWb3B0aW1pemF0aW9uX29iamVjdGl2ZRgEIAEoCVIVb3B0aW1pemF0aW9uT2JqZWN0
aXZlEmsKGHRhYmxlc19tb2RlbF9jb2x1bW5faW5mbxgFIAMoCzIyLmdvb2dsZS5jbG91ZC5h
dXRvbWwudjFiZXRhMS5UYWJsZXNNb2RlbENvbHVtbkluZm9SFXRhYmxlc01vZGVsQ29sdW1u
SW5mbxJACh10cmFpbl9idWRnZXRfbWlsbGlfbm9kZV9ob3VycxgGIAEoA1IZdHJhaW5CdWRn
ZXRNaWxsaU5vZGVIb3VycxI8Cht0cmFpbl9jb3N0X21pbGxpX25vZGVfaG91cnMYByABKANS
F3RyYWluQ29zdE1pbGxpTm9kZUhvdXJzEjQKFmRpc2FibGVfZWFybHlfc3RvcHBpbmcYDCAB
KAhSFGRpc2FibGVFYXJseVN0b3BwaW5nQioKKGFkZGl0aW9uYWxfb3B0aW1pemF0aW9uX29i
amVjdGl2ZV9jb25maWcixQIKEFRhYmxlc0Fubm90YXRpb24SFAoFc2NvcmUYASABKAJSBXNj
b3JlElkKE3ByZWRpY3Rpb25faW50ZXJ2YWwYBCABKAsyKC5nb29nbGUuY2xvdWQuYXV0b21s
LnYxYmV0YTEuRG91YmxlUmFuZ2VSEnByZWRpY3Rpb25JbnRlcnZhbBIsCgV2YWx1ZRgCIAEo
CzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIFdmFsdWUSawoYdGFibGVzX21vZGVsX2NvbHVt
bl9pbmZvGAMgAygLMjIuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc01vZGVs
Q29sdW1uSW5mb1IVdGFibGVzTW9kZWxDb2x1bW5JbmZvEiUKDmJhc2VsaW5lX3Njb3JlGAUg
ASgCUg1iYXNlbGluZVNjb3JlIqABChVUYWJsZXNNb2RlbENvbHVtbkluZm8SKAoQY29sdW1u
X3NwZWNfbmFtZRgBIAEoCVIOY29sdW1uU3BlY05hbWUSLgoTY29sdW1uX2Rpc3BsYXlfbmFt
ZRgCIAEoCVIRY29sdW1uRGlzcGxheU5hbWUSLQoSZmVhdHVyZV9pbXBvcnRhbmNlGAMgASgC
UhFmZWF0dXJlSW1wb3J0YW5jZUKbAQofY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRh
MVABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1
dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6
QXV0b01MOjpWMWJldGExSoFfCgcSBQ4AogIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSADoKCQoCAwESAxMANwoJCgIDAhIDFAA2CgkK
AgMDEgMVADYKCQoCAwQSAxYAMgoJCgIDBRIDFwA2CgkKAgMGEgMYADQKCQoCAwcSAxkAJgoJ
CgIDCBIDGgApCggKAQgSAxwATgoJCgIICxIDHABOCggKAQgSAx0AIgoJCgIIChIDHQAiCggK
AQgSAx4AOAoJCgIIARIDHgA4CggKAQgSAx8AOAoJCgIIKRIDHwA4CggKAQgSAyAANwoJCgII
LRIDIAA3CjwKAgQAEgQjAGQBGjAgTWV0YWRhdGEgZm9yIGEgZGF0YXNldCB1c2VkIGZvciBB
dXRvTUwgVGFibGVzLgoKCgoDBAABEgMjCB0KUwoEBAACABIDJQIjGkYgT3V0cHV0IG9ubHku
IFRoZSB0YWJsZV9zcGVjX2lkIG9mIHRoZSBwcmltYXJ5IHRhYmxlIG9mIHRoaXMgZGF0YXNl
dC4KCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJHgoMCgUEAAIAAxIDJSEiCs4DCgQEAAIB
EgM1AiMawAMgY29sdW1uX3NwZWNfaWQgb2YgdGhlIHByaW1hcnkgdGFibGUncyBjb2x1bW4g
dGhhdCBzaG91bGQgYmUgdXNlZCBhcyB0aGUKIHRyYWluaW5nICYgcHJlZGljdGlvbiB0YXJn
ZXQuCiBUaGlzIGNvbHVtbiBtdXN0IGJlIG5vbi1udWxsYWJsZSBhbmQgaGF2ZSBvbmUgb2Yg
Zm9sbG93aW5nIGRhdGEgdHlwZXMKIChvdGhlcndpc2UgbW9kZWwgY3JlYXRpb24gd2lsbCBl
cnJvcik6CgogKiBDQVRFR09SWQoKICogRkxPQVQ2NAoKIElmIHRoZSB0eXBlIGlzIENBVEVH
T1JZICwgb25seSB1cCB0bwogMTAwIHVuaXF1ZSB2YWx1ZXMgbWF5IGV4aXN0IGluIHRoYXQg
Y29sdW1uIGFjcm9zcyBhbGwgcm93cy4KCiBOT1RFOiBVcGRhdGVzIG9mIHRoaXMgZmllbGQg
d2lsbCBpbnN0YW50bHkgYWZmZWN0IGFueSBvdGhlciB1c2VycwogY29uY3VycmVudGx5IHdv
cmtpbmcgd2l0aCB0aGUgZGF0YXNldC4KCgwKBQQAAgEFEgM1AggKDAoFBAACAQESAzUJHgoM
CgUEAAIBAxIDNSEiCusDCgQEAAICEgNAAiMa3QMgY29sdW1uX3NwZWNfaWQgb2YgdGhlIHBy
aW1hcnkgdGFibGUncyBjb2x1bW4gdGhhdCBzaG91bGQgYmUgdXNlZCBhcyB0aGUKIHdlaWdo
dCBjb2x1bW4sIGkuZS4gdGhlIGhpZ2hlciB0aGUgdmFsdWUgdGhlIG1vcmUgaW1wb3J0YW50
IHRoZSByb3cgd2lsbCBiZQogZHVyaW5nIG1vZGVsIHRyYWluaW5nLgogUmVxdWlyZWQgdHlw
ZTogRkxPQVQ2NC4KIEFsbG93ZWQgdmFsdWVzOiAwIHRvIDEwMDAwLCBpbmNsdXNpdmUgb24g
Ym90aCBlbmRzOyAwIG1lYW5zIHRoZSByb3cgaXMKICAgICAgICAgICAgICAgICBpZ25vcmVk
IGZvciB0cmFpbmluZy4KIElmIG5vdCBzZXQgYWxsIHJvd3MgYXJlIGFzc3VtZWQgdG8gaGF2
ZSBlcXVhbCB3ZWlnaHQgb2YgMS4KIE5PVEU6IFVwZGF0ZXMgb2YgdGhpcyBmaWVsZCB3aWxs
IGluc3RhbnRseSBhZmZlY3QgYW55IG90aGVyIHVzZXJzCiBjb25jdXJyZW50bHkgd29ya2lu
ZyB3aXRoIHRoZSBkYXRhc2V0LgoKDAoFBAACAgUSA0ACCAoMCgUEAAICARIDQAkeCgwKBQQA
AgIDEgNAISIKmgYKBAQAAgMSA08CIxqMBiBjb2x1bW5fc3BlY19pZCBvZiB0aGUgcHJpbWFy
eSB0YWJsZSBjb2x1bW4gd2hpY2ggc3BlY2lmaWVzIGEgcG9zc2libGUgTUwKIHVzZSBvZiB0
aGUgcm93LCBpLmUuIHRoZSBjb2x1bW4gd2lsbCBiZSB1c2VkIHRvIHNwbGl0IHRoZSByb3dz
IGludG8gVFJBSU4sCiBWQUxJREFURSBhbmQgVEVTVCBzZXRzLgogUmVxdWlyZWQgdHlwZTog
U1RSSU5HLgogVGhpcyBjb2x1bW4sIGlmIHNldCwgbXVzdCBlaXRoZXIgaGF2ZSBhbGwgb2Yg
YFRSQUlOYCwgYFZBTElEQVRFYCwgYFRFU1RgCiBhbW9uZyBpdHMgdmFsdWVzLCBvciBvbmx5
IGhhdmUgYFRFU1RgLCBgVU5BU1NJR05FRGAgdmFsdWVzLiBJbiB0aGUgbGF0dGVyCiBjYXNl
IHRoZSByb3dzIHdpdGggYFVOQVNTSUdORURgIHZhbHVlIHdpbGwgYmUgYXNzaWduZWQgYnkg
QXV0b01MLiBOb3RlCiB0aGF0IGlmIGEgZ2l2ZW4gbWwgdXNlIGRpc3RyaWJ1dGlvbiBtYWtl
cyBpdCBpbXBvc3NpYmxlIHRvIGNyZWF0ZSBhICJnb29kIgogbW9kZWwsIHRoYXQgY2FsbCB3
aWxsIGVycm9yIGRlc2NyaWJpbmcgdGhlIGlzc3VlLgogSWYgYm90aCB0aGlzIGNvbHVtbl9z
cGVjX2lkIGFuZCBwcmltYXJ5IHRhYmxlJ3MgdGltZV9jb2x1bW5fc3BlY19pZCBhcmUgbm90
CiBzZXQsIHRoZW4gYWxsIHJvd3MgYXJlIHRyZWF0ZWQgYXMgYFVOQVNTSUdORURgLgogTk9U
RTogVXBkYXRlcyBvZiB0aGlzIGZpZWxkIHdpbGwgaW5zdGFudGx5IGFmZmVjdCBhbnkgb3Ro
ZXIgdXNlcnMKIGNvbmN1cnJlbnRseSB3b3JraW5nIHdpdGggdGhlIGRhdGFzZXQuCgoMCgUE
AAIDBRIDTwIICgwKBQQAAgMBEgNPCR4KDAoFBAACAwMSA08hIgqpBAoEBAACBBIDWwI/GpsE
IE91dHB1dCBvbmx5LiBDb3JyZWxhdGlvbnMgYmV0d2VlbgoKIFtUYWJsZXNEYXRhc2V0TWV0
YWRhdGEudGFyZ2V0X2NvbHVtbl9zcGVjX2lkXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuVGFibGVzRGF0YXNldE1ldGFkYXRhLnRhcmdldF9jb2x1bW5fc3BlY19pZF0sCiBhbmQg
b3RoZXIgY29sdW1ucyBvZiB0aGUKCiBbVGFibGVzRGF0YXNldE1ldGFkYXRhcHJpbWFyeV90
YWJsZV1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc0RhdGFzZXRNZXRhZGF0
YS5wcmltYXJ5X3RhYmxlX3NwZWNfaWRdLgogT25seSBzZXQgaWYgdGhlIHRhcmdldCBjb2x1
bW4gaXMgc2V0LiBNYXBwaW5nIGZyb20gb3RoZXIgY29sdW1uIHNwZWMgaWQgdG8KIGl0cyBD
b3JyZWxhdGlvblN0YXRzIHdpdGggdGhlIHRhcmdldCBjb2x1bW4uCiBUaGlzIGZpZWxkIG1h
eSBiZSBzdGFsZSwgc2VlIHRoZSBzdGF0c191cGRhdGVfdGltZSBmaWVsZCBmb3IKIGZvciB0
aGUgdGltZXN0YW1wIGF0IHdoaWNoIHRoZXNlIHN0YXRzIHdlcmUgbGFzdCB1cGRhdGVkLgoK
DAoFBAACBAYSA1sCHwoMCgUEAAIEARIDWyA6CgwKBQQAAgQDEgNbPT4K8gIKBAQAAgUSA2MC
MhrkAiBPdXRwdXQgb25seS4gVGhlIG1vc3QgcmVjZW50IHRpbWVzdGFtcCB3aGVuIHRhcmdl
dF9jb2x1bW5fY29ycmVsYXRpb25zCiBmaWVsZCBhbmQgYWxsIGRlc2NlbmRhbnQgQ29sdW1u
U3BlYy5kYXRhX3N0YXRzIGFuZAogQ29sdW1uU3BlYy50b3BfY29ycmVsYXRlZF9jb2x1bW5z
IGZpZWxkcyB3ZXJlIGxhc3QgKHJlLSlnZW5lcmF0ZWQuIEFueQogY2hhbmdlcyB0aGF0IGhh
cHBlbmVkIHRvIHRoZSBkYXRhc2V0IGFmdGVyd2FyZHMgYXJlIG5vdCByZWZsZWN0ZWQgaW4g
dGhlc2UKIGZpZWxkcyB2YWx1ZXMuIFRoZSByZWdlbmVyYXRpb24gaGFwcGVucyBpbiB0aGUg
YmFja2dyb3VuZCBvbiBhIGJlc3QgZWZmb3J0CiBiYXNpcy4KCgwKBQQAAgUGEgNjAhsKDAoF
BAACBQESA2McLQoMCgUEAAIFAxIDYzAxCjgKAgQBEgVnANABARorIE1vZGVsIG1ldGFkYXRh
IHNwZWNpZmljIHRvIEF1dG9NTCBUYWJsZXMuCgoKCgMEAQESA2cIGwqlAQoEBAEIABIEawJz
AxqWASBBZGRpdGlvbmFsIG9wdGltaXphdGlvbiBvYmplY3RpdmUgY29uZmlndXJhdGlvbi4g
UmVxdWlyZWQgZm9yCiBgTUFYSU1JWkVfUFJFQ0lTSU9OX0FUX1JFQ0FMTGAgYW5kIGBNQVhJ
TUlaRV9SRUNBTExfQVRfUFJFQ0lTSU9OYCwKIG90aGVyd2lzZSB1bnVzZWQuCgoMCgUEAQgA
ARIDawgwCnsKBAQBAgASA24EMxpuIFJlcXVpcmVkIHdoZW4gb3B0aW1pemF0aW9uX29iamVj
dGl2ZSBpcyAiTUFYSU1JWkVfUFJFQ0lTSU9OX0FUX1JFQ0FMTCIuCiBNdXN0IGJlIGJldHdl
ZW4gMCBhbmQgMSwgaW5jbHVzaXZlLgoKDAoFBAECAAUSA24ECQoMCgUEAQIAARIDbgotCgwK
BQQBAgADEgNuMDIKewoEBAECARIDcgQ2Gm4gUmVxdWlyZWQgd2hlbiBvcHRpbWl6YXRpb25f
b2JqZWN0aXZlIGlzICJNQVhJTUlaRV9SRUNBTExfQVRfUFJFQ0lTSU9OIi4KIE11c3QgYmUg
YmV0d2VlbiAwIGFuZCAxLCBpbmNsdXNpdmUuCgoMCgUEAQIBBRIDcgQJCgwKBQQBAgEBEgNy
CjAKDAoFBAECAQMSA3IzNQrBAwoEBAECAhIDfgIkGrMDIENvbHVtbiBzcGVjIG9mIHRoZSBk
YXRhc2V0J3MgcHJpbWFyeSB0YWJsZSdzIGNvbHVtbiB0aGUgbW9kZWwgaXMKIHByZWRpY3Rp
bmcuIFNuYXBzaG90dGVkIHdoZW4gbW9kZWwgY3JlYXRpb24gc3RhcnRlZC4KIE9ubHkgMyBm
aWVsZHMgYXJlIHVzZWQ6CiBuYW1lIC0gTWF5IGJlIHNldCBvbiBDcmVhdGVNb2RlbCwgaWYg
aXQncyBub3QgdGhlbiB0aGUgQ29sdW1uU3BlYwogICAgICAgIGNvcnJlc3BvbmRpbmcgdG8g
dGhlIGN1cnJlbnQgdGFyZ2V0X2NvbHVtbl9zcGVjX2lkIG9mIHRoZSBkYXRhc2V0CiAgICAg
ICAgdGhlIG1vZGVsIGlzIHRyYWluZWQgZnJvbSBpcyB1c2VkLgogICAgICAgIElmIG5laXRo
ZXIgaXMgc2V0LCBDcmVhdGVNb2RlbCB3aWxsIGVycm9yLgogZGlzcGxheV9uYW1lIC0gT3V0
cHV0IG9ubHkuCiBkYXRhX3R5cGUgLSBPdXRwdXQgb25seS4KCgwKBQQBAgIGEgN+AgwKDAoF
BAECAgESA34NHwoMCgUEAQICAxIDfiIjCq8GCgQEAQIDEgSWAQI1GqAGIENvbHVtbiBzcGVj
cyBvZiB0aGUgZGF0YXNldCdzIHByaW1hcnkgdGFibGUncyBjb2x1bW5zLCBvbiB3aGljaAog
dGhlIG1vZGVsIGlzIHRyYWluZWQgYW5kIHdoaWNoIGFyZSB1c2VkIGFzIHRoZSBpbnB1dCBm
b3IgcHJlZGljdGlvbnMuCiBUaGUKCiBbdGFyZ2V0X2NvbHVtbl1bZ29vZ2xlLmNsb3VkLmF1
dG9tbC52MWJldGExLlRhYmxlc01vZGVsTWV0YWRhdGEudGFyZ2V0X2NvbHVtbl9zcGVjXQog
YXMgd2VsbCBhcywgYWNjb3JkaW5nIHRvIGRhdGFzZXQncyBzdGF0ZSB1cG9uIG1vZGVsIGNy
ZWF0aW9uLAoKIFt3ZWlnaHRfY29sdW1uXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEu
VGFibGVzRGF0YXNldE1ldGFkYXRhLndlaWdodF9jb2x1bW5fc3BlY19pZF0sCiBhbmQKCiBb
bWxfdXNlX2NvbHVtbl1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc0RhdGFz
ZXRNZXRhZGF0YS5tbF91c2VfY29sdW1uX3NwZWNfaWRdCiBtdXN0IG5ldmVyIGJlIGluY2x1
ZGVkIGhlcmUuCgogT25seSAzIGZpZWxkcyBhcmUgdXNlZDoKCiAqIG5hbWUgLSBNYXkgYmUg
c2V0IG9uIENyZWF0ZU1vZGVsLCBpZiBzZXQgb25seSB0aGUgY29sdW1ucyBzcGVjaWZpZWQg
YXJlCiAgIHVzZWQsIG90aGVyd2lzZSBhbGwgcHJpbWFyeSB0YWJsZSdzIGNvbHVtbnMgKGV4
Y2VwdCB0aGUgb25lcyBsaXN0ZWQKICAgYWJvdmUpIGFyZSB1c2VkIGZvciB0aGUgdHJhaW5p
bmcgYW5kIHByZWRpY3Rpb24gaW5wdXQuCgogKiBkaXNwbGF5X25hbWUgLSBPdXRwdXQgb25s
eS4KCiAqIGRhdGFfdHlwZSAtIE91dHB1dCBvbmx5LgoKDQoFBAECAwQSBJYBAgoKDQoFBAEC
AwYSBJYBCxUKDQoFBAECAwESBJYBFjAKDQoFBAECAwMSBJYBMzQK/ggKBAQBAgQSBLEBAiQa
7wggT2JqZWN0aXZlIGZ1bmN0aW9uIHRoZSBtb2RlbCBpcyBvcHRpbWl6aW5nIHRvd2FyZHMu
IFRoZSB0cmFpbmluZyBwcm9jZXNzCiBjcmVhdGVzIGEgbW9kZWwgdGhhdCBtYXhpbWl6ZXMv
bWluaW1pemVzIHRoZSB2YWx1ZSBvZiB0aGUgb2JqZWN0aXZlCiBmdW5jdGlvbiBvdmVyIHRo
ZSB2YWxpZGF0aW9uIHNldC4KCiBUaGUgc3VwcG9ydGVkIG9wdGltaXphdGlvbiBvYmplY3Rp
dmVzIGRlcGVuZCBvbiB0aGUgcHJlZGljdGlvbiB0eXBlLgogSWYgdGhlIGZpZWxkIGlzIG5v
dCBzZXQsIGEgZGVmYXVsdCBvYmplY3RpdmUgZnVuY3Rpb24gaXMgdXNlZC4KCiBDTEFTU0lG
SUNBVElPTl9CSU5BUlk6CiAgICJNQVhJTUlaRV9BVV9ST0MiIChkZWZhdWx0KSAtIE1heGlt
aXplIHRoZSBhcmVhIHVuZGVyIHRoZSByZWNlaXZlcgogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICBvcGVyYXRpbmcgY2hhcmFjdGVyaXN0aWMgKFJPQykgY3VydmUuCiAgICJN
SU5JTUlaRV9MT0dfTE9TUyIgLSBNaW5pbWl6ZSBsb2cgbG9zcy4KICAgIk1BWElNSVpFX0FV
X1BSQyIgLSBNYXhpbWl6ZSB0aGUgYXJlYSB1bmRlciB0aGUgcHJlY2lzaW9uLXJlY2FsbCBj
dXJ2ZS4KICAgIk1BWElNSVpFX1BSRUNJU0lPTl9BVF9SRUNBTEwiIC0gTWF4aW1pemUgcHJl
Y2lzaW9uIGZvciBhIHNwZWNpZmllZAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgIHJlY2FsbCB2YWx1ZS4KICAgIk1BWElNSVpFX1JFQ0FMTF9BVF9QUkVDSVNJT04iIC0g
TWF4aW1pemUgcmVjYWxsIGZvciBhIHNwZWNpZmllZAogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICBwcmVjaXNpb24gdmFsdWUuCgogQ0xBU1NJRklDQVRJT05fTVVMVElf
Q0xBU1MgOgogICAiTUlOSU1JWkVfTE9HX0xPU1MiIChkZWZhdWx0KSAtIE1pbmltaXplIGxv
ZyBsb3NzLgoKCiBSRUdSRVNTSU9OOgogICAiTUlOSU1JWkVfUk1TRSIgKGRlZmF1bHQpIC0g
TWluaW1pemUgcm9vdC1tZWFuLXNxdWFyZWQgZXJyb3IgKFJNU0UpLgogICAiTUlOSU1JWkVf
TUFFIiAtIE1pbmltaXplIG1lYW4tYWJzb2x1dGUgZXJyb3IgKE1BRSkuCiAgICJNSU5JTUla
RV9STVNMRSIgLSBNaW5pbWl6ZSByb290LW1lYW4tc3F1YXJlZCBsb2cgZXJyb3IgKFJNU0xF
KS4KCg0KBQQBAgQFEgSxAQIICg0KBQQBAgQBEgSxAQkfCg0KBQQBAgQDEgSxASIjCoUBCgQE
AQIFEgS1AQI+GncgT3V0cHV0IG9ubHkuIEF1eGlsaWFyeSBpbmZvcm1hdGlvbiBmb3IgZWFj
aCBvZiB0aGUKIGlucHV0X2ZlYXR1cmVfY29sdW1uX3NwZWNzIHdpdGggcmVzcGVjdCB0byB0
aGlzIHBhcnRpY3VsYXIgbW9kZWwuCgoNCgUEAQIFBBIEtQECCgoNCgUEAQIFBhIEtQELIAoN
CgUEAQIFARIEtQEhOQoNCgUEAQIFAxIEtQE8PQqkBQoEBAECBhIExQECKhqVBSBSZXF1aXJl
ZC4gVGhlIHRyYWluIGJ1ZGdldCBvZiBjcmVhdGluZyB0aGlzIG1vZGVsLCBleHByZXNzZWQg
aW4gbWlsbGkgbm9kZQogaG91cnMgaS5lLiAxLDAwMCB2YWx1ZSBpbiB0aGlzIGZpZWxkIG1l
YW5zIDEgbm9kZSBob3VyLgoKIFRoZSB0cmFpbmluZyBjb3N0IG9mIHRoZSBtb2RlbCB3aWxs
IG5vdCBleGNlZWQgdGhpcyBidWRnZXQuIFRoZSBmaW5hbCBjb3N0CiB3aWxsIGJlIGF0dGVt
cHRlZCB0byBiZSBjbG9zZSB0byB0aGUgYnVkZ2V0LCB0aG91Z2ggbWF5IGVuZCB1cCBiZWlu
ZyAoZXZlbikKIG5vdGljZWFibHkgc21hbGxlciAtIGF0IHRoZSBiYWNrZW5kJ3MgZGlzY3Jl
dGlvbi4gVGhpcyBlc3BlY2lhbGx5IG1heQogaGFwcGVuIHdoZW4gZnVydGhlciBtb2RlbCB0
cmFpbmluZyBjZWFzZXMgdG8gcHJvdmlkZSBhbnkgaW1wcm92ZW1lbnRzLgoKIElmIHRoZSBi
dWRnZXQgaXMgc2V0IHRvIGEgdmFsdWUga25vd24gdG8gYmUgaW5zdWZmaWNpZW50IHRvIHRy
YWluIGEKIG1vZGVsIGZvciB0aGUgZ2l2ZW4gZGF0YXNldCwgdGhlIHRyYWluaW5nIHdvbid0
IGJlIGF0dGVtcHRlZCBhbmQKIHdpbGwgZXJyb3IuCgogVGhlIHRyYWluIGJ1ZGdldCBtdXN0
IGJlIGJldHdlZW4gMSwwMDAgYW5kIDcyLDAwMCBtaWxsaSBub2RlIGhvdXJzLAogaW5jbHVz
aXZlLgoKDQoFBAECBgUSBMUBAgcKDQoFBAECBgESBMUBCCUKDQoFBAECBgMSBMUBKCkKwgEK
BAQBAgcSBMoBAigaswEgT3V0cHV0IG9ubHkuIFRoZSBhY3R1YWwgdHJhaW5pbmcgY29zdCBv
ZiB0aGUgbW9kZWwsIGV4cHJlc3NlZCBpbiBtaWxsaQogbm9kZSBob3VycywgaS5lLiAxLDAw
MCB2YWx1ZSBpbiB0aGlzIGZpZWxkIG1lYW5zIDEgbm9kZSBob3VyLiBHdWFyYW50ZWVkCiB0
byBub3QgZXhjZWVkIHRoZSB0cmFpbiBidWRnZXQuCgoNCgUEAQIHBRIEygECBwoNCgUEAQIH
ARIEygEIIwoNCgUEAQIHAxIEygEmJwrzAQoEBAECCBIEzwECIxrkASBVc2UgdGhlIGVudGly
ZSB0cmFpbmluZyBidWRnZXQuIFRoaXMgZGlzYWJsZXMgdGhlIGVhcmx5IHN0b3BwaW5nIGZl
YXR1cmUuCiBCeSBkZWZhdWx0LCB0aGUgZWFybHkgc3RvcHBpbmcgZmVhdHVyZSBpcyBlbmFi
bGVkLCB3aGljaCBtZWFucyB0aGF0IEF1dG9NTAogVGFibGVzIG1pZ2h0IHN0b3AgdHJhaW5p
bmcgYmVmb3JlIHRoZSBlbnRpcmUgdHJhaW5pbmcgYnVkZ2V0IGhhcyBiZWVuIHVzZWQuCgoN
CgUEAQIIBRIEzwECBgoNCgUEAQIIARIEzwEHHQoNCgUEAQIIAxIEzwEgIgo/CgIEAhIG0wEA
gwIBGjEgQ29udGFpbnMgYW5ub3RhdGlvbiBkZXRhaWxzIHNwZWNpZmljIHRvIFRhYmxlcy4K
CgsKAwQCARIE0wEIGAqlAgoEBAICABIE2gECEhqWAiBPdXRwdXQgb25seS4gQSBjb25maWRl
bmNlIGVzdGltYXRlIGJldHdlZW4gMC4wIGFuZCAxLjAsIGluY2x1c2l2ZS4gQSBoaWdoZXIK
IHZhbHVlIG1lYW5zIGdyZWF0ZXIgY29uZmlkZW5jZSBpbiB0aGUgcmV0dXJuZWQgdmFsdWUu
CiBGb3IKCiBbdGFyZ2V0X2NvbHVtbl9zcGVjXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuVGFibGVzTW9kZWxNZXRhZGF0YS50YXJnZXRfY29sdW1uX3NwZWNdCiBvZiBGTE9BVDY0
IGRhdGEgdHlwZSB0aGUgc2NvcmUgaXMgbm90IHBvcHVsYXRlZC4KCg0KBQQCAgAFEgTaAQIH
Cg0KBQQCAgABEgTaAQgNCg0KBQQCAgADEgTaARARCvQBCgQEAgIBEgThAQImGuUBIE91dHB1
dCBvbmx5LiBPbmx5IHBvcHVsYXRlZCB3aGVuCgogW3RhcmdldF9jb2x1bW5fc3BlY11bZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc01vZGVsTWV0YWRhdGEudGFyZ2V0X2Nv
bHVtbl9zcGVjXQogaGFzIEZMT0FUNjQgZGF0YSB0eXBlLiBBbiBpbnRlcnZhbCBpbiB3aGlj
aCB0aGUgZXhhY3RseSBjb3JyZWN0IHRhcmdldAogdmFsdWUgaGFzIDk1JSBjaGFuY2UgdG8g
YmUgaW4uCgoNCgUEAgIBBhIE4QECDQoNCgUEAgIBARIE4QEOIQoNCgUEAgIBAxIE4QEkJQrX
AgoEBAICAhIE7AECIhrIAiBUaGUgcHJlZGljdGVkIHZhbHVlIG9mIHRoZSByb3cncwoKIFt0
YXJnZXRfY29sdW1uXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGFibGVzTW9kZWxN
ZXRhZGF0YS50YXJnZXRfY29sdW1uX3NwZWNdLgogVGhlIHZhbHVlIGRlcGVuZHMgb24gdGhl
IGNvbHVtbidzIERhdGFUeXBlOgoKICogQ0FURUdPUlkgLSB0aGUgcHJlZGljdGVkICh3aXRo
IHRoZSBhYm92ZSBjb25maWRlbmNlIGBzY29yZWApIENBVEVHT1JZCiAgIHZhbHVlLgoKICog
RkxPQVQ2NCAtIHRoZSBwcmVkaWN0ZWQgKHdpdGggYWJvdmUgYHByZWRpY3Rpb25faW50ZXJ2
YWxgKSBGTE9BVDY0IHZhbHVlLgoKDQoFBAICAgYSBOwBAhcKDQoFBAICAgESBOwBGB0KDQoF
BAICAgMSBOwBICEK7AMKBAQCAgMSBPkBAj4a3QMgT3V0cHV0IG9ubHkuIEF1eGlsaWFyeSBp
bmZvcm1hdGlvbiBmb3IgZWFjaCBvZiB0aGUgbW9kZWwncwoKIFtpbnB1dF9mZWF0dXJlX2Nv
bHVtbl9zcGVjc11bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc01vZGVsTWV0
YWRhdGEuaW5wdXRfZmVhdHVyZV9jb2x1bW5fc3BlY3NdCiB3aXRoIHJlc3BlY3QgdG8gdGhp
cyBwYXJ0aWN1bGFyIHByZWRpY3Rpb24uCiBJZiBubyBvdGhlciBmaWVsZHMgdGhhbgoKIFtj
b2x1bW5fc3BlY19uYW1lXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGFibGVzTW9k
ZWxDb2x1bW5JbmZvLmNvbHVtbl9zcGVjX25hbWVdCiBhbmQKCiBbY29sdW1uX2Rpc3BsYXlf
bmFtZV1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc01vZGVsQ29sdW1uSW5m
by5jb2x1bW5fZGlzcGxheV9uYW1lXQogd291bGQgYmUgcG9wdWxhdGVkLCB0aGVuIHRoaXMg
d2hvbGUgZmllbGQgaXMgbm90LgoKDQoFBAICAwQSBPkBAgoKDQoFBAICAwYSBPkBCyAKDQoF
BAICAwESBPkBITkKDQoFBAICAwMSBPkBPD0K/gMKBAQCAgQSBIICAhsa7wMgT3V0cHV0IG9u
bHkuIFN0b3JlcyB0aGUgcHJlZGljdGlvbiBzY29yZSBmb3IgdGhlIGJhc2VsaW5lIGV4YW1w
bGUsIHdoaWNoCiBpcyBkZWZpbmVkIGFzIHRoZSBleGFtcGxlIHdpdGggYWxsIHZhbHVlcyBz
ZXQgdG8gdGhlaXIgYmFzZWxpbmUgdmFsdWVzLgogVGhpcyBpcyB1c2VkIGFzIHBhcnQgb2Yg
dGhlIFNhbXBsZWQgU2hhcGxleSBleHBsYW5hdGlvbiBvZiB0aGUgbW9kZWwncwogcHJlZGlj
dGlvbi4gVGhpcyBmaWVsZCBpcyBwb3B1bGF0ZWQgb25seSB3aGVuIGZlYXR1cmUgaW1wb3J0
YW5jZSBpcwogcmVxdWVzdGVkLiBGb3IgcmVncmVzc2lvbiBtb2RlbHMsIHRoaXMgaG9sZHMg
dGhlIGJhc2VsaW5lIHByZWRpY3Rpb24gZm9yCiB0aGUgYmFzZWxpbmUgZXhhbXBsZS4gRm9y
IGNsYXNzaWZpY2F0aW9uIG1vZGVscywgdGhpcyBob2xkcyB0aGUgYmFzZWxpbmUKIHByZWRp
Y3Rpb24gZm9yIHRoZSBiYXNlbGluZSBleGFtcGxlIGZvciB0aGUgYXJnbWF4IGNsYXNzLgoK
DQoFBAICBAUSBIICAgcKDQoFBAICBAESBIICCBYKDQoFBAICBAMSBIICGRoKhQEKAgQDEgaH
AgCiAgEadyBBbiBpbmZvcm1hdGlvbiBzcGVjaWZpYyB0byBnaXZlbiBjb2x1bW4gYW5kIFRh
YmxlcyBNb2RlbCwgaW4gY29udGV4dAogb2YgdGhlIE1vZGVsIGFuZCB0aGUgcHJlZGljdGlv
bnMgY3JlYXRlZCBieSBpdC4KCgsKAwQDARIEhwIIHQqHAQoEBAMCABIEigICHhp5IE91dHB1
dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUgQ29sdW1uU3BlYyBkZXNjcmliaW5nIHRoZSBjb2x1
bW4uIE5vdAogcG9wdWxhdGVkIHdoZW4gdGhpcyBwcm90byBpcyBvdXRwdXR0ZWQgdG8gQmln
UXVlcnkuCgoNCgUEAwIABRIEigICCAoNCgUEAwIAARIEigIJGQoNCgUEAwIAAxIEigIcHQpq
CgQEAwIBEgSOAgIhGlwgT3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGNv
bHVtbiAoc2FtZSBhcyB0aGUgZGlzcGxheV9uYW1lIG9mCiBpdHMgQ29sdW1uU3BlYykuCgoN
CgUEAwIBBRIEjgICCAoNCgUEAwIBARIEjgIJHAoNCgUEAwIBAxIEjgIfIAqOBwoEBAMCAhIE
oQICHxr/BiBPdXRwdXQgb25seS4gV2hlbiBnaXZlbiBhcyBwYXJ0IG9mIGEgTW9kZWwgKGFs
d2F5cyBwb3B1bGF0ZWQpOgogTWVhc3VyZW1lbnQgb2YgaG93IG11Y2ggbW9kZWwgcHJlZGlj
dGlvbnMgY29ycmVjdG5lc3Mgb24gdGhlIFRFU1QgZGF0YQogZGVwZW5kIG9uIHZhbHVlcyBp
biB0aGlzIGNvbHVtbi4gQSB2YWx1ZSBiZXR3ZWVuIDAgYW5kIDEsIGhpZ2hlciBtZWFucwog
aGlnaGVyIGluZmx1ZW5jZS4gVGhlc2UgdmFsdWVzIGFyZSBub3JtYWxpemVkIC0gZm9yIGFs
bCBpbnB1dCBmZWF0dXJlCiBjb2x1bW5zIG9mIGEgZ2l2ZW4gbW9kZWwgdGhleSBhZGQgdG8g
MS4KCiBXaGVuIGdpdmVuIGJhY2sgYnkgUHJlZGljdCAocG9wdWxhdGVkIGlmZgogW2ZlYXR1
cmVfaW1wb3J0YW5jZQogcGFyYW1dW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5QcmVk
aWN0UmVxdWVzdC5wYXJhbXNdIGlzIHNldCkgb3IgQmF0Y2gKIFByZWRpY3QgKHBvcHVsYXRl
ZCBpZmYKIFtmZWF0dXJlX2ltcG9ydGFuY2VdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRh
MS5QcmVkaWN0UmVxdWVzdC5wYXJhbXNdCiBwYXJhbSBpcyBzZXQpOgogTWVhc3VyZW1lbnQg
b2YgaG93IGltcGFjdGZ1bCBmb3IgdGhlIHByZWRpY3Rpb24gcmV0dXJuZWQgZm9yIHRoZSBn
aXZlbiByb3cKIHRoZSB2YWx1ZSBpbiB0aGlzIGNvbHVtbiB3YXMuIFNwZWNpZmljYWxseSwg
dGhlIGZlYXR1cmUgaW1wb3J0YW5jZQogc3BlY2lmaWVzIHRoZSBtYXJnaW5hbCBjb250cmli
dXRpb24gdGhhdCB0aGUgZmVhdHVyZSBtYWRlIHRvIHRoZSBwcmVkaWN0aW9uCiBzY29yZSBj
b21wYXJlZCB0byB0aGUgYmFzZWxpbmUgc2NvcmUuIFRoZXNlIHZhbHVlcyBhcmUgY29tcHV0
ZWQgdXNpbmcgdGhlCiBTYW1wbGVkIFNoYXBsZXkgbWV0aG9kLgoKDQoFBAMCAgUSBKECAgcK
DQoFBAMCAgESBKECCBoKDQoFBAMCAgMSBKECHR5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata ===
    # Fields for TablesDatasetMetadata
    # Field: primary_table_spec_id Type: 9 ()
    # Field: target_column_spec_id Type: 9 ()
    # Field: weight_column_spec_id Type: 9 ()
    # Field: ml_use_column_spec_id Type: 9 ()
    # Field: target_column_correlations Type: 11 (.google.cloud.automl.v1beta1.TablesDatasetMetadata.TargetColumnCorrelationsEntry)
    # Field: stats_update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Automl::V1beta1::Tables::TablesModelMetadata ===
    # Fields for TablesModelMetadata
    # Field: optimization_objective_recall_value Type: 2 ()
    # Field: optimization_objective_precision_value Type: 2 ()
    # Field: target_column_spec Type: 11 (.google.cloud.automl.v1beta1.ColumnSpec)
    # Field: input_feature_column_specs Type: 11 (.google.cloud.automl.v1beta1.ColumnSpec)
    # Field: optimization_objective Type: 9 ()
    # Field: tables_model_column_info Type: 11 (.google.cloud.automl.v1beta1.TablesModelColumnInfo)
    # Field: train_budget_milli_node_hours Type: 3 ()
    # Field: train_cost_milli_node_hours Type: 3 ()
    # Field: disable_early_stopping Type: 8 ()

# === Message: Google::Cloud::Automl::V1beta1::Tables::TablesAnnotation ===
    # Fields for TablesAnnotation
    # Field: score Type: 2 ()
    # Field: prediction_interval Type: 11 (.google.cloud.automl.v1beta1.DoubleRange)
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: tables_model_column_info Type: 11 (.google.cloud.automl.v1beta1.TablesModelColumnInfo)
    # Field: baseline_score Type: 2 ()

# === Message: Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo ===
    # Fields for TablesModelColumnInfo
    # Field: column_spec_name Type: 9 ()
    # Field: column_display_name Type: 9 ()
    # Field: feature_importance Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Tables - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/tables.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Tables;

    my $msg = Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata->new({
        primary_table_spec_id => $primary_table_spec_id,
        target_column_spec_id => $target_column_spec_id,
        weight_column_spec_id => $weight_column_spec_id,
        ml_use_column_spec_id => $ml_use_column_spec_id,
    });

    # Read or update a field
    my $val = $msg->primary_table_spec_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/tables.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata

Metadata for a dataset used for AutoML Tables.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->primary_table_spec_id() >> / C<< $msg->primary_table_spec_id($value) >>

Type: C<String>

Output only. The table_spec_id of the primary table of this dataset.

=item * C<< $msg->target_column_spec_id() >> / C<< $msg->target_column_spec_id($value) >>

Type: C<String>

column_spec_id of the primary table's column that should be used as the
training & prediction target.
This column must be non-nullable and have one of following data types
(otherwise model creation will error):

* CATEGORY

* FLOAT64

If the type is CATEGORY , only up to
100 unique values may exist in that column across all rows.

NOTE: Updates of this field will instantly affect any other users
concurrently working with the dataset.

=item * C<< $msg->weight_column_spec_id() >> / C<< $msg->weight_column_spec_id($value) >>

Type: C<String>

column_spec_id of the primary table's column that should be used as the
weight column, i.e. the higher the value the more important the row will be
during model training.
Required type: FLOAT64.
Allowed values: 0 to 10000, inclusive on both ends; 0 means the row is
                ignored for training.
If not set all rows are assumed to have equal weight of 1.
NOTE: Updates of this field will instantly affect any other users
concurrently working with the dataset.

=item * C<< $msg->ml_use_column_spec_id() >> / C<< $msg->ml_use_column_spec_id($value) >>

Type: C<String>

column_spec_id of the primary table column which specifies a possible ML
use of the row, i.e. the column will be used to split the rows into TRAIN,
VALIDATE and TEST sets.
Required type: STRING.
This column, if set, must either have all of `TRAIN`, `VALIDATE`, `TEST`
among its values, or only have `TEST`, `UNASSIGNED` values. In the latter
case the rows with `UNASSIGNED` value will be assigned by AutoML. Note
that if a given ml use distribution makes it impossible to create a "good"
model, that call will error describing the issue.
If both this column_spec_id and primary table's time_column_spec_id are not
set, then all rows are treated as `UNASSIGNED`.
NOTE: Updates of this field will instantly affect any other users
concurrently working with the dataset.

=item * C<< $msg->target_column_correlations() >> / C<< $msg->target_column_correlations($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata::TargetColumnCorrelationsEntry>)

Output only. Correlations between

[TablesDatasetMetadata.target_column_spec_id][google.cloud.automl.v1beta1.TablesDatasetMetadata.target_column_spec_id],
and other columns of the

[TablesDatasetMetadataprimary_table][google.cloud.automl.v1beta1.TablesDatasetMetadata.primary_table_spec_id].
Only set if the target column is set. Mapping from other column spec id to
its CorrelationStats with the target column.
This field may be stale, see the stats_update_time field for
for the timestamp at which these stats were last updated.

=item * C<< $msg->stats_update_time() >> / C<< $msg->stats_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The most recent timestamp when target_column_correlations
field and all descendant ColumnSpec.data_stats and
ColumnSpec.top_correlated_columns fields were last (re-)generated. Any
changes that happened to the dataset afterwards are not reflected in these
fields values. The regeneration happens in the background on a best effort
basis.

=back

=head2 Google::Cloud::Automl::V1beta1::Tables::TablesModelMetadata

Model metadata specific to AutoML Tables.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->optimization_objective_recall_value() >> / C<< $msg->optimization_objective_recall_value($value) >>

Type: C<Float>

Required when optimization_objective is "MAXIMIZE_PRECISION_AT_RECALL".
Must be between 0 and 1, inclusive.

=item * C<< $msg->optimization_objective_precision_value() >> / C<< $msg->optimization_objective_precision_value($value) >>

Type: C<Float>

Required when optimization_objective is "MAXIMIZE_RECALL_AT_PRECISION".
Must be between 0 and 1, inclusive.

=item * C<< $msg->target_column_spec() >> / C<< $msg->target_column_spec($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec>)

Column spec of the dataset's primary table's column the model is
predicting. Snapshotted when model creation started.
Only 3 fields are used:
name - May be set on CreateModel, if it's not then the ColumnSpec
       corresponding to the current target_column_spec_id of the dataset
       the model is trained from is used.
       If neither is set, CreateModel will error.
display_name - Output only.
data_type - Output only.

=item * C<< $msg->input_feature_column_specs() >> / C<< $msg->input_feature_column_specs($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec>)

Column specs of the dataset's primary table's columns, on which
the model is trained and which are used as the input for predictions.
The

[target_column][google.cloud.automl.v1beta1.TablesModelMetadata.target_column_spec]
as well as, according to dataset's state upon model creation,

[weight_column][google.cloud.automl.v1beta1.TablesDatasetMetadata.weight_column_spec_id],
and

[ml_use_column][google.cloud.automl.v1beta1.TablesDatasetMetadata.ml_use_column_spec_id]
must never be included here.

Only 3 fields are used:

* name - May be set on CreateModel, if set only the columns specified are
  used, otherwise all primary table's columns (except the ones listed
  above) are used for the training and prediction input.

* display_name - Output only.

* data_type - Output only.

=item * C<< $msg->optimization_objective() >> / C<< $msg->optimization_objective($value) >>

Type: C<String>

Objective function the model is optimizing towards. The training process
creates a model that maximizes/minimizes the value of the objective
function over the validation set.

The supported optimization objectives depend on the prediction type.
If the field is not set, a default objective function is used.

CLASSIFICATION_BINARY:
  "MAXIMIZE_AU_ROC" (default) - Maximize the area under the receiver
                                operating characteristic (ROC) curve.
  "MINIMIZE_LOG_LOSS" - Minimize log loss.
  "MAXIMIZE_AU_PRC" - Maximize the area under the precision-recall curve.
  "MAXIMIZE_PRECISION_AT_RECALL" - Maximize precision for a specified
                                  recall value.
  "MAXIMIZE_RECALL_AT_PRECISION" - Maximize recall for a specified
                                   precision value.

CLASSIFICATION_MULTI_CLASS :
  "MINIMIZE_LOG_LOSS" (default) - Minimize log loss.


REGRESSION:
  "MINIMIZE_RMSE" (default) - Minimize root-mean-squared error (RMSE).
  "MINIMIZE_MAE" - Minimize mean-absolute error (MAE).
  "MINIMIZE_RMSLE" - Minimize root-mean-squared log error (RMSLE).

=item * C<< $msg->tables_model_column_info() >> / C<< $msg->tables_model_column_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo>)

Output only. Auxiliary information for each of the
input_feature_column_specs with respect to this particular model.

=item * C<< $msg->train_budget_milli_node_hours() >> / C<< $msg->train_budget_milli_node_hours($value) >>

Type: C<Int64>

Required. The train budget of creating this model, expressed in milli node
hours i.e. 1,000 value in this field means 1 node hour.

The training cost of the model will not exceed this budget. The final cost
will be attempted to be close to the budget, though may end up being (even)
noticeably smaller - at the backend's discretion. This especially may
happen when further model training ceases to provide any improvements.

If the budget is set to a value known to be insufficient to train a
model for the given dataset, the training won't be attempted and
will error.

The train budget must be between 1,000 and 72,000 milli node hours,
inclusive.

=item * C<< $msg->train_cost_milli_node_hours() >> / C<< $msg->train_cost_milli_node_hours($value) >>

Type: C<Int64>

Output only. The actual training cost of the model, expressed in milli
node hours, i.e. 1,000 value in this field means 1 node hour. Guaranteed
to not exceed the train budget.

=item * C<< $msg->disable_early_stopping() >> / C<< $msg->disable_early_stopping($value) >>

Type: C<Bool>

Use the entire training budget. This disables the early stopping feature.
By default, the early stopping feature is enabled, which means that AutoML
Tables might stop training before the entire training budget has been used.

=back

=head2 Google::Cloud::Automl::V1beta1::Tables::TablesAnnotation

Contains annotation details specific to Tables.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Output only. A confidence estimate between 0.0 and 1.0, inclusive. A higher
value means greater confidence in the returned value.
For

[target_column_spec][google.cloud.automl.v1beta1.TablesModelMetadata.target_column_spec]
of FLOAT64 data type the score is not populated.

=item * C<< $msg->prediction_interval() >> / C<< $msg->prediction_interval($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Ranges::DoubleRange>)

Output only. Only populated when

[target_column_spec][google.cloud.automl.v1beta1.TablesModelMetadata.target_column_spec]
has FLOAT64 data type. An interval in which the exactly correct target
value has 95% chance to be in.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

The predicted value of the row's

[target_column][google.cloud.automl.v1beta1.TablesModelMetadata.target_column_spec].
The value depends on the column's DataType:

* CATEGORY - the predicted (with the above confidence `score`) CATEGORY
  value.

* FLOAT64 - the predicted (with above `prediction_interval`) FLOAT64 value.

=item * C<< $msg->tables_model_column_info() >> / C<< $msg->tables_model_column_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo>)

Output only. Auxiliary information for each of the model's

[input_feature_column_specs][google.cloud.automl.v1beta1.TablesModelMetadata.input_feature_column_specs]
with respect to this particular prediction.
If no other fields than

[column_spec_name][google.cloud.automl.v1beta1.TablesModelColumnInfo.column_spec_name]
and

[column_display_name][google.cloud.automl.v1beta1.TablesModelColumnInfo.column_display_name]
would be populated, then this whole field is not.

=item * C<< $msg->baseline_score() >> / C<< $msg->baseline_score($value) >>

Type: C<Float>

Output only. Stores the prediction score for the baseline example, which
is defined as the example with all values set to their baseline values.
This is used as part of the Sampled Shapley explanation of the model's
prediction. This field is populated only when feature importance is
requested. For regression models, this holds the baseline prediction for
the baseline example. For classification models, this holds the baseline
prediction for the baseline example for the argmax class.

=back

=head2 Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo

An information specific to given column and Tables Model, in context
of the Model and the predictions created by it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->column_spec_name() >> / C<< $msg->column_spec_name($value) >>

Type: C<String>

Output only. The name of the ColumnSpec describing the column. Not
populated when this proto is outputted to BigQuery.

=item * C<< $msg->column_display_name() >> / C<< $msg->column_display_name($value) >>

Type: C<String>

Output only. The display name of the column (same as the display_name of
its ColumnSpec).

=item * C<< $msg->feature_importance() >> / C<< $msg->feature_importance($value) >>

Type: C<Float>

Output only. When given as part of a Model (always populated):
Measurement of how much model predictions correctness on the TEST data
depend on values in this column. A value between 0 and 1, higher means
higher influence. These values are normalized - for all input feature
columns of a given model they add to 1.

When given back by Predict (populated iff
[feature_importance
param][google.cloud.automl.v1beta1.PredictRequest.params] is set) or Batch
Predict (populated iff
[feature_importance][google.cloud.automl.v1beta1.PredictRequest.params]
param is set):
Measurement of how impactful for the prediction returned for the given row
the value in this column was. Specifically, the feature importance
specifies the marginal contribution that the feature made to the prediction
score compared to the baseline score. These values are computed using the
Sampled Shapley method.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Tables::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
