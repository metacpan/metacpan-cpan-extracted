package Google::Cloud::Resourcemanager::V3::TagKeys;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmVzb3VyY2VtYW5hZ2VyL3YzL3RhZ19rZXlzLnByb3RvEh9nb29n
bGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL2lhbS92MS9pYW1f
cG9saWN5LnByb3RvGhpnb29nbGUvaWFtL3YxL3BvbGljeS5wcm90bxojZ29vZ2xlL2xvbmdy
dW5uaW5nL29wZXJhdGlvbnMucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIowFCgZUYWdLZXkSFwoEbmFt
ZRgBIAEoCUID4EEFUgRuYW1lEhsKBnBhcmVudBgCIAEoCUID4EEFUgZwYXJlbnQSJQoKc2hv
cnRfbmFtZRgDIAEoCUIG4EEC4EEFUglzaG9ydE5hbWUSLwoPbmFtZXNwYWNlZF9uYW1lGAQg
ASgJQgbgQQPgQQVSDm5hbWVzcGFjZWROYW1lEiUKC2Rlc2NyaXB0aW9uGAUgASgJQgPgQQFS
C2Rlc2NyaXB0aW9uEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAcgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEhcKBGV0YWcYCCABKAlCA+BB
AVIEZXRhZxJHCgdwdXJwb3NlGAsgASgOMiguZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdl
ci52My5QdXJwb3NlQgPgQQFSB3B1cnBvc2USYAoMcHVycG9zZV9kYXRhGAwgAygLMjguZ29v
Z2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5UYWdLZXkuUHVycG9zZURhdGFFbnRyeUID
4EEBUgtwdXJwb3NlRGF0YRo+ChBQdXJwb3NlRGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6RepBQgoqY2xvdWRyZXNvdXJjZW1hbmFnZXIu
Z29vZ2xlYXBpcy5jb20vVGFnS2V5EhF0YWdLZXlzL3t0YWdfa2V5fVIBASJ9ChJMaXN0VGFn
S2V5c1JlcXVlc3QSIQoGcGFyZW50GAEgASgJQgngQQL6QQMSASpSBnBhcmVudBIgCglwYWdl
X3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglw
YWdlVG9rZW4igQEKE0xpc3RUYWdLZXlzUmVzcG9uc2USQgoIdGFnX2tleXMYASADKAsyJy5n
b29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLlRhZ0tleVIHdGFnS2V5cxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iWgoQR2V0VGFnS2V5UmVxdWVzdBJG
CgRuYW1lGAEgASgJQjLgQQL6QSwKKmNsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMu
Y29tL1RhZ0tleVIEbmFtZSJkChpHZXROYW1lc3BhY2VkVGFnS2V5UmVxdWVzdBJGCgRuYW1l
GAEgASgJQjLgQQL6QSwKKmNsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Rh
Z0tleVIEbmFtZSKGAQoTQ3JlYXRlVGFnS2V5UmVxdWVzdBJFCgd0YWdfa2V5GAEgASgLMicu
Z29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5UYWdLZXlCA+BBAlIGdGFnS2V5EigK
DXZhbGlkYXRlX29ubHkYAiABKAhCA+BBAVIMdmFsaWRhdGVPbmx5IhYKFENyZWF0ZVRhZ0tl
eU1ldGFkYXRhIr4BChNVcGRhdGVUYWdLZXlSZXF1ZXN0EkUKB3RhZ19rZXkYASABKAsyJy5n
b29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLlRhZ0tleUID4EECUgZ0YWdLZXkSOwoL
dXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVN
YXNrEiMKDXZhbGlkYXRlX29ubHkYAyABKAhSDHZhbGlkYXRlT25seSIWChRVcGRhdGVUYWdL
ZXlNZXRhZGF0YSKgAQoTRGVsZXRlVGFnS2V5UmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6
QSwKKmNsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1RhZ0tleVIEbmFtZRIo
Cg12YWxpZGF0ZV9vbmx5GAIgASgIQgPgQQFSDHZhbGlkYXRlT25seRIXCgRldGFnGAMgASgJ
QgPgQQFSBGV0YWciFgoURGVsZXRlVGFnS2V5TWV0YWRhdGEqNAoHUHVycG9zZRIXChNQVVJQ
T1NFX1VOU1BFQ0lGSUVEEAASEAoMR0NFX0ZJUkVXQUxMEAEy5AwKB1RhZ0tleXMSlgEKC0xp
c3RUYWdLZXlzEjMuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5MaXN0VGFnS2V5
c1JlcXVlc3QaNC5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLkxpc3RUYWdLZXlz
UmVzcG9uc2UiHILT5JMCDRILL3YzL3RhZ0tleXPaQQZwYXJlbnQSjAEKCUdldFRhZ0tleRIx
Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuR2V0VGFnS2V5UmVxdWVzdBonLmdv
b2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuVGFnS2V5IiOC0+STAhYSFC92My97bmFt
ZT10YWdLZXlzLyp92kEEbmFtZRKiAQoTR2V0TmFtZXNwYWNlZFRhZ0tleRI7Lmdvb2dsZS5j
bG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuR2V0TmFtZXNwYWNlZFRhZ0tleVJlcXVlc3QaJy5n
b29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLlRhZ0tleSIlgtPkkwIYEhYvdjMvdGFn
S2V5cy9uYW1lc3BhY2Vk2kEEbmFtZRKsAQoMQ3JlYXRlVGFnS2V5EjQuZ29vZ2xlLmNsb3Vk
LnJlc291cmNlbWFuYWdlci52My5DcmVhdGVUYWdLZXlSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbiJHgtPkkwIWIgsvdjMvdGFnS2V5czoHdGFnX2tledpBB3RhZ19r
ZXnKQR4KBlRhZ0tleRIUQ3JlYXRlVGFnS2V5TWV0YWRhdGESyQEKDFVwZGF0ZVRhZ0tleRI0
Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuVXBkYXRlVGFnS2V5UmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iZILT5JMCJzIcL3YzL3t0YWdfa2V5Lm5h
bWU9dGFnS2V5cy8qfToHdGFnX2tledpBE3RhZ19rZXksdXBkYXRlX21hc2vKQR4KBlRhZ0tl
eRIUVXBkYXRlVGFnS2V5TWV0YWRhdGESqQEKDERlbGV0ZVRhZ0tleRI0Lmdvb2dsZS5jbG91
ZC5yZXNvdXJjZW1hbmFnZXIudjMuRGVsZXRlVGFnS2V5UmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24iRILT5JMCFioUL3YzL3tuYW1lPXRhZ0tleXMvKn3aQQRuYW1l
ykEeCgZUYWdLZXkSFERlbGV0ZVRhZ0tleU1ldGFkYXRhEoYBCgxHZXRJYW1Qb2xpY3kSIi5n
b29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGlj
eSI7gtPkkwIqIiUvdjMve3Jlc291cmNlPXRhZ0tleXMvKn06Z2V0SWFtUG9saWN5OgEq2kEI
cmVzb3VyY2USjQEKDFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuU2V0SWFtUG9saWN5
UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IkKC0+STAioiJS92My97cmVzb3VyY2U9
dGFnS2V5cy8qfTpzZXRJYW1Qb2xpY3k6ASraQQ9yZXNvdXJjZSxwb2xpY3kSuAEKElRlc3RJ
YW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVxdWVz
dBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9uc2UiTYLT5JMCMCIr
L3YzL3tyZXNvdXJjZT10YWdLZXlzLyp9OnRlc3RJYW1QZXJtaXNzaW9uczoBKtpBFHJlc291
cmNlLHBlcm1pc3Npb25zGpABykEjY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5j
b23SQWdodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0ucmVhZC1vbmx5
Qu0BCiNjb20uZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52M0IMVGFnS2V5c1Byb3Rv
UAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vcmVzb3VyY2VtYW5hZ2VyL2FwaXYzL3Jlc291cmNl
bWFuYWdlcnBiO3Jlc291cmNlbWFuYWdlcnBiqgIfR29vZ2xlLkNsb3VkLlJlc291cmNlTWFu
YWdlci5WM8oCH0dvb2dsZVxDbG91ZFxSZXNvdXJjZU1hbmFnZXJcVjPqAiJHb29nbGU6OkNs
b3VkOjpSZXNvdXJjZU1hbmFnZXI6OlYzSoFcCgcSBQ4A7gIBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgID
AhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAKAoJCgIDBRIDFwAkCgkKAgMGEgMYAC0KCQoC
AwcSAxkAKgoJCgIDCBIDGgApCggKAQgSAxwAPAoJCgIIJRIDHAA8CggKAQgSAx0AZAoJCgII
CxIDHQBkCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8ALQoJCgIICBIDHwAtCggKAQgS
AyAAPAoJCgIIARIDIAA8CggKAQgSAyEAPAoJCgIIKRIDIQA8CggKAQgSAyIAOwoJCgIILRID
IgA7CjkKAgYAEgUlAJoBARosIEFsbG93IHVzZXJzIHRvIGNyZWF0ZSBhbmQgbWFuYWdlIHRh
ZyBrZXlzLgoKCgoDBgABEgMlCA8KCgoDBgADEgMmAksKDAoFBgADmQgSAyYCSwoLCgMGAAMS
BCcCKUEKDQoFBgADmggSBCcCKUEKOAoEBgACABIELAIxAxoqIExpc3RzIGFsbCBUYWdLZXlz
IGZvciBhIHBhcmVudCByZXNvdXJjZS4KCgwKBQYAAgABEgMsBhEKDAoFBgACAAISAywSJAoM
CgUGAAIAAxIDLC9CCg0KBQYAAgAEEgQtBC8GChEKCQYAAgAEsMq8IhIELQQvBgoMCgUGAAIA
BBIDMAQ0Cg8KCAYAAgAEmwgAEgMwBDQKnAEKBAYAAgESBDUCOgMajQEgUmV0cmlldmVzIGEg
VGFnS2V5LiBUaGlzIG1ldGhvZCB3aWxsIHJldHVybiBgUEVSTUlTU0lPTl9ERU5JRURgIGlm
IHRoZQoga2V5IGRvZXMgbm90IGV4aXN0IG9yIHRoZSB1c2VyIGRvZXMgbm90IGhhdmUgcGVy
bWlzc2lvbiB0byB2aWV3IGl0LgoKDAoFBgACAQESAzUGDwoMCgUGAAIBAhIDNRAgCgwKBQYA
AgEDEgM1KzEKDQoFBgACAQQSBDYEOAYKEQoJBgACAQSwyrwiEgQ2BDgGCgwKBQYAAgEEEgM5
BDIKDwoIBgACAQSbCAASAzkEMgq0AQoEBgACAhIEPwJEAxqlASBSZXRyaWV2ZXMgYSBUYWdL
ZXkgYnkgaXRzIG5hbWVzcGFjZWQgbmFtZS4KIFRoaXMgbWV0aG9kIHdpbGwgcmV0dXJuIGBQ
RVJNSVNTSU9OX0RFTklFRGAgaWYgdGhlIGtleSBkb2VzIG5vdCBleGlzdAogb3IgdGhlIHVz
ZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIHZpZXcgaXQuCgoMCgUGAAICARIDPwYZ
CgwKBQYAAgICEgM/GjQKDAoFBgACAgMSAz8/RQoNCgUGAAICBBIEQARCBgoRCgkGAAICBLDK
vCISBEAEQgYKDAoFBgACAgQSA0MEMgoPCggGAAICBJsIABIDQwQyCvcBCgQGAAIDEgRKAlQD
GugBIENyZWF0ZXMgYSBuZXcgVGFnS2V5LiBJZiBhbm90aGVyIHJlcXVlc3Qgd2l0aCB0aGUg
c2FtZSBwYXJhbWV0ZXJzIGlzCiBzZW50IHdoaWxlIHRoZSBvcmlnaW5hbCByZXF1ZXN0IGlz
IGluIHByb2Nlc3MsIHRoZSBzZWNvbmQgcmVxdWVzdAogd2lsbCByZWNlaXZlIGFuIGVycm9y
LiBBIG1heGltdW0gb2YgMTAwMCBUYWdLZXlzIGNhbiBleGlzdCB1bmRlciBhIHBhcmVudAog
YXQgYW55IGdpdmVuIHRpbWUuCgoMCgUGAAIDARIDSgYSCgwKBQYAAgMCEgNKEyYKDAoFBgAC
AwMSA0oxTQoNCgUGAAIDBBIESwROBgoRCgkGAAIDBLDKvCISBEsETgYKDAoFBgACAwQSA08E
NQoPCggGAAIDBJsIABIDTwQ1Cg0KBQYAAgMEEgRQBFMGCg8KBwYAAgMEmQgSBFAEUwYKPgoE
BgACBBIEVwJhAxowIFVwZGF0ZXMgdGhlIGF0dHJpYnV0ZXMgb2YgdGhlIFRhZ0tleSByZXNv
dXJjZS4KCgwKBQYAAgQBEgNXBhIKDAoFBgACBAISA1cTJgoMCgUGAAIEAxIDVzFNCg0KBQYA
AgQEEgRYBFsGChEKCQYAAgQEsMq8IhIEWARbBgoMCgUGAAIEBBIDXARBCg8KCAYAAgQEmwgA
EgNcBEEKDQoFBgACBAQSBF0EYAYKDwoHBgACBASZCBIEXQRgBgpeCgQGAAIFEgRlAm4DGlAg
RGVsZXRlcyBhIFRhZ0tleS4gVGhlIFRhZ0tleSBjYW5ub3QgYmUgZGVsZXRlZCBpZiBpdCBo
YXMgYW55IGNoaWxkCiBUYWdWYWx1ZXMuCgoMCgUGAAIFARIDZQYSCgwKBQYAAgUCEgNlEyYK
DAoFBgACBQMSA2UxTQoNCgUGAAIFBBIEZgRoBgoRCgkGAAIFBLDKvCISBGYEaAYKDAoFBgAC
BQQSA2kEMgoPCggGAAIFBJsIABIDaQQyCg0KBQYAAgUEEgRqBG0GCg8KBwYAAgUEmQgSBGoE
bQYK1QIKBAYAAgYSBHYCfQMaxgIgR2V0cyB0aGUgYWNjZXNzIGNvbnRyb2wgcG9saWN5IGZv
ciBhIFRhZ0tleS4gVGhlIHJldHVybmVkIHBvbGljeSBtYXkgYmUKIGVtcHR5IGlmIG5vIHN1
Y2ggcG9saWN5IG9yIHJlc291cmNlIGV4aXN0cy4gVGhlIGByZXNvdXJjZWAgZmllbGQgc2hv
dWxkCiBiZSB0aGUgVGFnS2V5J3MgcmVzb3VyY2UgbmFtZS4gRm9yIGV4YW1wbGUsICJ0YWdL
ZXlzLzEyMzQiLgogVGhlIGNhbGxlciBtdXN0IGhhdmUKIGBjbG91ZHJlc291cmNlbWFuYWdl
ci5nb29nbGVhcGlzLmNvbS90YWdLZXlzLmdldElhbVBvbGljeWAgcGVybWlzc2lvbiBvbgog
dGhlIHNwZWNpZmllZCBUYWdLZXkuCgoMCgUGAAIGARIDdgYSCgwKBQYAAgYCEgN2EzQKDAoF
BgACBgMSA3cPIwoNCgUGAAIGBBIEeAR7BgoRCgkGAAIGBLDKvCISBHgEewYKDAoFBgACBgQS
A3wENgoPCggGAAIGBJsIABIDfAQ2CpwCCgQGAAIHEgaEAQKLAQMaiwIgU2V0cyB0aGUgYWNj
ZXNzIGNvbnRyb2wgcG9saWN5IG9uIGEgVGFnS2V5LCByZXBsYWNpbmcgYW55IGV4aXN0aW5n
CiBwb2xpY3kuIFRoZSBgcmVzb3VyY2VgIGZpZWxkIHNob3VsZCBiZSB0aGUgVGFnS2V5J3Mg
cmVzb3VyY2UgbmFtZS4KIEZvciBleGFtcGxlLCAidGFnS2V5cy8xMjM0Ii4KIFRoZSBjYWxs
ZXIgbXVzdCBoYXZlIGByZXNvdXJjZW1hbmFnZXIudGFnS2V5cy5zZXRJYW1Qb2xpY3lgIHBl
cm1pc3Npb24KIG9uIHRoZSBpZGVudGlmaWVkIHRhZ1ZhbHVlLgoKDQoFBgACBwESBIQBBhIK
DQoFBgACBwISBIQBEzQKDQoFBgACBwMSBIUBDyMKDwoFBgACBwQSBoYBBIkBBgoTCgkGAAIH
BLDKvCISBoYBBIkBBgoNCgUGAAIHBBIEigEEPQoQCggGAAIHBJsIABIEigEEPQrpAQoEBgAC
CBIGkgECmQEDGtgBIFJldHVybnMgcGVybWlzc2lvbnMgdGhhdCBhIGNhbGxlciBoYXMgb24g
dGhlIHNwZWNpZmllZCBUYWdLZXkuCiBUaGUgYHJlc291cmNlYCBmaWVsZCBzaG91bGQgYmUg
dGhlIFRhZ0tleSdzIHJlc291cmNlIG5hbWUuCiBGb3IgZXhhbXBsZSwgInRhZ0tleXMvMTIz
NCIuCgogVGhlcmUgYXJlIG5vIHBlcm1pc3Npb25zIHJlcXVpcmVkIGZvciBtYWtpbmcgdGhp
cyBBUEkgY2FsbC4KCg0KBQYAAggBEgSSAQYYCg0KBQYAAggCEgSSARlACg0KBQYAAggDEgST
AQ83Cg8KBQYAAggEEgaUAQSXAQYKEwoJBgACCASwyrwiEgaUAQSXAQYKDQoFBgACCAQSBJgB
BEIKEAoIBgACCASbCAASBJgBBEIKOwoCBAASBp0BAOMBARotIEEgVGFnS2V5LCB1c2VkIHRv
IGdyb3VwIGEgc2V0IG9mIFRhZ1ZhbHVlcy4KCgsKAwQAARIEnQEIDgoNCgMEAAcSBp4BAqIB
BAoPCgUEAAedCBIGngECogEECqoBCgQEAAIAEgSnAQI8GpsBIEltbXV0YWJsZS4gVGhlIHJl
c291cmNlIG5hbWUgZm9yIGEgVGFnS2V5LiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGB0YWdL
ZXlzL3t0YWdfa2V5X2lkfWAsIHdoZXJlIGB0YWdfa2V5X2lkYCBpcyB0aGUgZ2VuZXJhdGVk
IG51bWVyaWMgaWQgZm9yCiB0aGUgVGFnS2V5LgoKDQoFBAACAAUSBKcBAggKDQoFBAACAAES
BKcBCQ0KDQoFBAACAAMSBKcBEBEKDQoFBAACAAgSBKcBEjsKEAoIBAACAAicCAASBKcBEzoK
4AIKBAQAAgESBK4BAj4a0QIgSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
VGFnS2V5J3MgcGFyZW50LiBBIFRhZ0tleSBjYW4gYmUKIHBhcmVudGVkIGJ5IGFuIE9yZ2Fu
aXphdGlvbiBvciBhIFByb2plY3QuIEZvciBhIFRhZ0tleSBwYXJlbnRlZCBieSBhbgogT3Jn
YW5pemF0aW9uLCBpdHMgcGFyZW50IG11c3QgYmUgaW4gdGhlIGZvcm0gYG9yZ2FuaXphdGlv
bnMve29yZ19pZH1gLiBGb3IKIGEgVGFnS2V5IHBhcmVudGVkIGJ5IGEgUHJvamVjdCwgaXRz
IHBhcmVudCBjYW4gYmUgaW4gdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdF9pZH1gIG9y
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9YC4KCg0KBQQAAgEFEgSuAQIICg0KBQQAAgEB
EgSuAQkPCg0KBQQAAgEDEgSuARITCg0KBQQAAgEIEgSuARQ9ChAKCAQAAgEInAgAEgSuARU8
Cs0CCgQEAAICEga2AQK5AQQavAIgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHVzZXIgZnJp
ZW5kbHkgbmFtZSBmb3IgYSBUYWdLZXkuIFRoZSBzaG9ydCBuYW1lCiBzaG91bGQgYmUgdW5p
cXVlIGZvciBUYWdLZXlzIHdpdGhpbiB0aGUgc2FtZSB0YWcgbmFtZXNwYWNlLgoKIFRoZSBz
aG9ydCBuYW1lIG11c3QgYmUgMS02MyBjaGFyYWN0ZXJzLCBiZWdpbm5pbmcgYW5kIGVuZGlu
ZyB3aXRoCiBhbiBhbHBoYW51bWVyaWMgY2hhcmFjdGVyIChbYS16MC05QS1aXSkgd2l0aCBk
YXNoZXMgKC0pLCB1bmRlcnNjb3JlcyAoXyksCiBkb3RzICguKSwgYW5kIGFscGhhbnVtZXJp
Y3MgYmV0d2Vlbi4KCg0KBQQAAgIFEgS2AQIICg0KBQQAAgIBEgS2AQkTCg0KBQQAAgIDEgS2
ARYXCg8KBQQAAgIIEga2ARi5AQMKEAoIBAACAgicCAASBLcBBCoKEAoIBAACAgicCAESBLgB
BCsKSAoEBAACAxIGvAECvwEEGjggT3V0cHV0IG9ubHkuIEltbXV0YWJsZS4gTmFtZXNwYWNl
ZCBuYW1lIG9mIHRoZSBUYWdLZXkuCgoNCgUEAAIDBRIEvAECCAoNCgUEAAIDARIEvAEJGAoN
CgUEAAIDAxIEvAEbHAoPCgUEAAIDCBIGvAEdvwEDChAKCAQAAgMInAgAEgS9AQQtChAKCAQA
AgMInAgBEgS+AQQrCnEKBAQAAgQSBMUBAkIaYyBPcHRpb25hbC4gVXNlci1hc3NpZ25lZCBk
ZXNjcmlwdGlvbiBvZiB0aGUgVGFnS2V5LiBNdXN0IG5vdCBleGNlZWQgMjU2CiBjaGFyYWN0
ZXJzLgoKIFJlYWQtd3JpdGUuCgoNCgUEAAIEBRIExQECCAoNCgUEAAIEARIExQEJFAoNCgUE
AAIEAxIExQEXGAoNCgUEAAIECBIExQEZQQoQCggEAAIECJwIABIExQEaQAotCgQEAAIFEgbI
AQLJATIaHSBPdXRwdXQgb25seS4gQ3JlYXRpb24gdGltZS4KCg0KBQQAAgUGEgTIAQIbCg0K
BQQAAgUBEgTIARwnCg0KBQQAAgUDEgTIASorCg0KBQQAAgUIEgTJAQYxChAKCAQAAgUInAgA
EgTJAQcwCisKBAQAAgYSBswBAs0BMhobIE91dHB1dCBvbmx5LiBVcGRhdGUgdGltZS4KCg0K
BQQAAgYGEgTMAQIbCg0KBQQAAgYBEgTMARwnCg0KBQQAAgYDEgTMASorCg0KBQQAAgYIEgTN
AQYxChAKCAQAAgYInAgAEgTNAQcwCqsBCgQEAAIHEgTSAQI7GpwBIE9wdGlvbmFsLiBFbnRp
dHkgdGFnIHdoaWNoIHVzZXJzIGNhbiBwYXNzIHRvIHByZXZlbnQgcmFjZSBjb25kaXRpb25z
LiBUaGlzCiBmaWVsZCBpcyBhbHdheXMgc2V0IGluIHNlcnZlciByZXNwb25zZXMuIFNlZSBV
cGRhdGVUYWdLZXlSZXF1ZXN0IGZvcgogZGV0YWlscy4KCg0KBQQAAgcFEgTSAQIICg0KBQQA
AgcBEgTSAQkNCg0KBQQAAgcDEgTSARARCg0KBQQAAgcIEgTSARI6ChAKCAQAAgcInAgAEgTS
ARM5CuwCCgQEAAIIEgTbAQJAGt0CIE9wdGlvbmFsLiBBIHB1cnBvc2UgZGVub3RlcyB0aGF0
IHRoaXMgVGFnIGlzIGludGVuZGVkIGZvciB1c2UgaW4gcG9saWNpZXMKIG9mIGEgc3BlY2lm
aWMgcG9saWN5IGVuZ2luZSwgYW5kIHdpbGwgaW52b2x2ZSB0aGF0IHBvbGljeSBlbmdpbmUg
aW4KIG1hbmFnZW1lbnQgb3BlcmF0aW9ucyBpbnZvbHZpbmcgdGhpcyBUYWcuIEEgcHVycG9z
ZSBkb2VzIG5vdCBncmFudCBhCiBwb2xpY3kgZW5naW5lIGV4Y2x1c2l2ZSByaWdodHMgdG8g
dGhlIFRhZywgYW5kIGl0IG1heSBiZSByZWZlcmVuY2VkIGJ5CiBvdGhlciBwb2xpY3kgZW5n
aW5lcy4KCiBBIHB1cnBvc2UgY2Fubm90IGJlIGNoYW5nZWQgb25jZSBzZXQuCgoNCgUEAAII
BhIE2wECCQoNCgUEAAIIARIE2wEKEQoNCgUEAAIIAxIE2wEUFgoNCgUEAAIICBIE2wEXPwoQ
CggEAAIICJwIABIE2wEYPgrSAQoEBAACCRIG4QEC4gEvGsEBIE9wdGlvbmFsLiBQdXJwb3Nl
IGRhdGEgY29ycmVzcG9uZHMgdG8gdGhlIHBvbGljeSBzeXN0ZW0gdGhhdCB0aGUgdGFnIGlz
CiBpbnRlbmRlZCBmb3IuIFNlZSBkb2N1bWVudGF0aW9uIGZvciBgUHVycG9zZWAgZm9yIGZv
cm1hdHRpbmcgb2YgdGhpcyBmaWVsZC4KCiBQdXJwb3NlIGRhdGEgY2Fubm90IGJlIGNoYW5n
ZWQgb25jZSBzZXQuCgoNCgUEAAIJBhIE4QECFQoNCgUEAAIJARIE4QEWIgoNCgUEAAIJAxIE
4QElJwoNCgUEAAIJCBIE4gEGLgoQCggEAAIJCJwIABIE4gEHLQpUCgIEARIG5gEA9wEBGkYg
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgbGlzdGluZyBhbGwgVGFnS2V5cyB1bmRlciBhIHBh
cmVudCByZXNvdXJjZS4KCgsKAwQBARIE5gEIGgqvAQoEBAECABIG6gEC7QEEGp4BIFJlcXVp
cmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgVGFnS2V5J3MgcGFyZW50LgogTXVzdCBi
ZSBvZiB0aGUgZm9ybSBgb3JnYW5pemF0aW9ucy97b3JnX2lkfWAgb3IgYHByb2plY3RzL3tw
cm9qZWN0X2lkfWAgb3IKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9YAoKDQoFBAECAAUS
BOoBAggKDQoFBAECAAESBOoBCQ8KDQoFBAECAAMSBOoBEhMKDwoFBAECAAgSBuoBFO0BAwoQ
CggEAQIACJwIABIE6wEEKgoPCgcEAQIACJ8IEgTsAQQ5CsMBCgQEAQIBEgTyAQI/GrQBIE9w
dGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgVGFnS2V5cyB0byByZXR1cm4gaW4gdGhl
IHJlc3BvbnNlLiBUaGUKIHNlcnZlciBhbGxvd3MgYSBtYXhpbXVtIG9mIDMwMCBUYWdLZXlz
IHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIHRoZQogc2VydmVyIHdpbGwgdXNlIDEwMCBh
cyB0aGUgZGVmYXVsdC4KCg0KBQQBAgEFEgTyAQIHCg0KBQQBAgEBEgTyAQgRCg0KBQQBAgED
EgTyARQVCg0KBQQBAgEIEgTyARY+ChAKCAQBAgEInAgAEgTyARc9CpQBCgQEAQICEgT2AQJB
GoUBIE9wdGlvbmFsLiBBIHBhZ2luYXRpb24gdG9rZW4gcmV0dXJuZWQgZnJvbSBhIHByZXZp
b3VzIGNhbGwgdG8gYExpc3RUYWdLZXlgCiB0aGF0IGluZGljYXRlcyB3aGVyZSB0aGlzIGxp
c3Rpbmcgc2hvdWxkIGNvbnRpbnVlIGZyb20uCgoNCgUEAQICBRIE9gECCAoNCgUEAQICARIE
9gEJEwoNCgUEAQICAxIE9gEWFwoNCgUEAQICCBIE9gEYQAoQCggEAQICCJwIABIE9gEZPwox
CgIEAhIG+gEAgQIBGiMgVGhlIExpc3RUYWdLZXlzIHJlc3BvbnNlIG1lc3NhZ2UuCgoLCgME
AgESBPoBCBsKVAoEBAICABIE/AECHxpGIExpc3Qgb2YgVGFnS2V5cyB0aGF0IGxpdmUgdW5k
ZXIgdGhlIHNwZWNpZmllZCBwYXJlbnQgaW4gdGhlIHJlcXVlc3QuCgoNCgUEAgIABBIE/AEC
CgoNCgUEAgIABhIE/AELEQoNCgUEAgIAARIE/AESGgoNCgUEAgIAAxIE/AEdHgqFAQoEBAIC
ARIEgAICHRp3IEEgcGFnaW5hdGlvbiB0b2tlbiByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMg
Y2FsbCB0byBgTGlzdFRhZ0tleXNgCiB0aGF0IGluZGljYXRlcyBmcm9tIHdoZXJlIGxpc3Rp
bmcgc2hvdWxkIGNvbnRpbnVlLgoKDQoFBAICAQUSBIACAggKDQoFBAICAQESBIACCRgKDQoF
BAICAQMSBIACGxwKOQoCBAMSBoQCAI0CARorIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGdl
dHRpbmcgYSBUYWdLZXkuCgoLCgMEAwESBIQCCBgKYQoEBAMCABIGhwICjAIEGlEgUmVxdWly
ZWQuIEEgcmVzb3VyY2UgbmFtZSBpbiB0aGUgZm9ybWF0IGB0YWdLZXlzL3tpZH1gLCBzdWNo
IGFzCiBgdGFnS2V5cy8xMjNgLgoKDQoFBAMCAAUSBIcCAggKDQoFBAMCAAESBIcCCQ0KDQoF
BAMCAAMSBIcCEBEKDwoFBAMCAAgSBocCEowCAwoQCggEAwIACJwIABIEiAIEKgoRCgcEAwIA
CJ8IEgaJAgSLAgUKUAoCBAQSBpACAJsCARpCIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGdl
dHRpbmcgYSBUYWdLZXkgYnkgaXRzIG5hbWVzcGFjZWQgbmFtZS4KCgsKAwQEARIEkAIIIgqA
AgoEBAQCABIGlQICmgIEGu8BIFJlcXVpcmVkLiBBIG5hbWVzcGFjZWQgdGFnIGtleSBuYW1l
IGluIHRoZSBmb3JtYXQKIGB7cGFyZW50SWR9L3t0YWdLZXlTaG9ydH1gLCBzdWNoIGFzIGA0
Mi9mb29gIGZvciBhIGtleSB3aXRoIHNob3J0IG5hbWUKICJmb28iIHVuZGVyIHRoZSBvcmdh
bml6YXRpb24gd2l0aCBJRCA0MiBvciBgcjItZDIvYmFyYCBmb3IgYSBrZXkgd2l0aCBzaG9y
dAogbmFtZSAiYmFyIiB1bmRlciB0aGUgcHJvamVjdCBgcjItZDJgLgoKDQoFBAQCAAUSBJUC
AggKDQoFBAQCAAESBJUCCQ0KDQoFBAQCAAMSBJUCEBEKDwoFBAQCAAgSBpUCEpoCAwoQCggE
BAIACJwIABIElgIEKgoRCgcEBAIACJ8IEgaXAgSZAgUKOgoCBAUSBp4CAKYCARosIFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yIGNyZWF0aW5nIGEgVGFnS2V5LgoKCwoDBAUBEgSeAggbCpcB
CgQEBQIAEgShAgI+GogBIFJlcXVpcmVkLiBUaGUgVGFnS2V5IHRvIGJlIGNyZWF0ZWQuIE9u
bHkgZmllbGRzIGBzaG9ydF9uYW1lYCwKIGBkZXNjcmlwdGlvbmAsIGFuZCBgcGFyZW50YCBh
cmUgY29uc2lkZXJlZCBkdXJpbmcgdGhlIGNyZWF0aW9uIHJlcXVlc3QuCgoNCgUEBQIABhIE
oQICCAoNCgUEBQIAARIEoQIJEAoNCgUEBQIAAxIEoQITFAoNCgUEBQIACBIEoQIVPQoQCggE
BQIACJwIABIEoQIWPAqHAQoEBAUCARIEpQICQhp5IE9wdGlvbmFsLiBTZXQgdG8gdHJ1ZSB0
byBwZXJmb3JtIHZhbGlkYXRpb25zIG5lY2Vzc2FyeSBmb3IgY3JlYXRpbmcgdGhlCiByZXNv
dXJjZSwgYnV0IG5vdCBhY3R1YWxseSBwZXJmb3JtIHRoZSBhY3Rpb24uCgoNCgUEBQIBBRIE
pQICBgoNCgUEBQIBARIEpQIHFAoNCgUEBQIBAxIEpQIXGAoNCgUEBQIBCBIEpQIZQQoQCggE
BQIBCJwIABIEpQIaQApCCgIEBhIEqQIAHxo2IFJ1bnRpbWUgb3BlcmF0aW9uIGluZm9ybWF0
aW9uIGZvciBjcmVhdGluZyBhIFRhZ0tleS4KCgsKAwQGARIEqQIIHAo6CgIEBxIGrAIAuwIB
GiwgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdXBkYXRpbmcgYSBUYWdLZXkuCgoLCgMEBwES
BKwCCBsKiQIKBAQHAgASBLECAj4a+gEgUmVxdWlyZWQuIFRoZSBuZXcgZGVmaW5pdGlvbiBv
ZiB0aGUgVGFnS2V5LiBPbmx5IHRoZSBgZGVzY3JpcHRpb25gIGFuZAogYGV0YWdgIGZpZWxk
cyBjYW4gYmUgdXBkYXRlZCBieSB0aGlzIHJlcXVlc3QuIElmIHRoZSBgZXRhZ2AgZmllbGQg
aXMgbm90CiBlbXB0eSwgaXQgbXVzdCBtYXRjaCB0aGUgYGV0YWdgIGZpZWxkIG9mIHRoZSBl
eGlzdGluZyB0YWcga2V5LiBPdGhlcndpc2UsCiBgQUJPUlRFRGAgd2lsbCBiZSByZXR1cm5l
ZC4KCg0KBQQHAgAGEgSxAgIICg0KBQQHAgABEgSxAgkQCg0KBQQHAgADEgSxAhMUCg0KBQQH
AgAIEgSxAhU9ChAKCAQHAgAInAgAEgSxAhY8Cq0BCgQEBwIBEgS2AgIsGp4BIEZpZWxkcyB0
byBiZSB1cGRhdGVkLiBUaGUgbWFzayBtYXkgb25seSBjb250YWluIGBkZXNjcmlwdGlvbmAg
b3IKIGBldGFnYC4gSWYgb21pdHRlZCBlbnRpcmVseSwgYm90aCBgZGVzY3JpcHRpb25gIGFu
ZCBgZXRhZ2AgYXJlIGFzc3VtZWQgdG8KIGJlIHNpZ25pZmljYW50LgoKDQoFBAcCAQYSBLYC
AhsKDQoFBAcCAQESBLYCHCcKDQoFBAcCAQMSBLYCKisKfQoEBAcCAhIEugICGRpvIFNldCBh
cyB0cnVlIHRvIHBlcmZvcm0gdmFsaWRhdGlvbnMgbmVjZXNzYXJ5IGZvciB1cGRhdGluZyB0
aGUgcmVzb3VyY2UsIGJ1dAogbm90IGFjdHVhbGx5IHBlcmZvcm0gdGhlIGFjdGlvbi4KCg0K
BQQHAgIFEgS6AgIGCg0KBQQHAgIBEgS6AgcUCg0KBQQHAgIDEgS6AhcYCkIKAgQIEgS+AgAf
GjYgUnVudGltZSBvcGVyYXRpb24gaW5mb3JtYXRpb24gZm9yIHVwZGF0aW5nIGEgVGFnS2V5
LgoKCwoDBAgBEgS+AggcCjoKAgQJEgbBAgDTAgEaLCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZv
ciBkZWxldGluZyBhIFRhZ0tleS4KCgsKAwQJARIEwQIIGwrHAQoEBAkCABIGxQICygIEGrYB
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiBhIFRhZ0tleSB0byBiZSBkZWxldGVk
IGluIHRoZSBmb3JtYXQKIGB0YWdLZXlzLzEyM2AuIFRoZSBUYWdLZXkgY2Fubm90IGJlIGEg
cGFyZW50IG9mIGFueSBleGlzdGluZyBUYWdWYWx1ZXMgb3IKIGl0IHdpbGwgbm90IGJlIGRl
bGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDQoFBAkCAAUSBMUCAggKDQoFBAkCAAESBMUCCQ0KDQoF
BAkCAAMSBMUCEBEKDwoFBAkCAAgSBsUCEsoCAwoQCggECQIACJwIABIExgIEKgoRCgcECQIA
CJ8IEgbHAgTJAgUKegoEBAkCARIEzgICQhpsIE9wdGlvbmFsLiBTZXQgYXMgdHJ1ZSB0byBw
ZXJmb3JtIHZhbGlkYXRpb25zIG5lY2Vzc2FyeSBmb3IgZGVsZXRpb24sIGJ1dAogbm90IGFj
dHVhbGx5IHBlcmZvcm0gdGhlIGFjdGlvbi4KCg0KBQQJAgEFEgTOAgIGCg0KBQQJAgEBEgTO
AgcUCg0KBQQJAgEDEgTOAhcYCg0KBQQJAgEIEgTOAhlBChAKCAQJAgEInAgAEgTOAhpACowB
CgQECQICEgTSAgI7Gn4gT3B0aW9uYWwuIFRoZSBldGFnIGtub3duIHRvIHRoZSBjbGllbnQg
Zm9yIHRoZSBleHBlY3RlZCBzdGF0ZSBvZiB0aGUKIFRhZ0tleS4gVGhpcyBpcyB0byBiZSB1
c2VkIGZvciBvcHRpbWlzdGljIGNvbmN1cnJlbmN5LgoKDQoFBAkCAgUSBNICAggKDQoFBAkC
AgESBNICCQ0KDQoFBAkCAgMSBNICEBEKDQoFBAkCAggSBNICEjoKEAoIBAkCAgicCAASBNIC
EzkKQgoCBAoSBNYCAB8aNiBSdW50aW1lIG9wZXJhdGlvbiBpbmZvcm1hdGlvbiBmb3IgZGVs
ZXRpbmcgYSBUYWdLZXkuCgoLCgMECgESBNYCCBwKwQEKAgUAEgbbAgDuAgEasgEgQSBwdXJw
b3NlIGZvciBlYWNoIHBvbGljeSBlbmdpbmUgcmVxdWlyaW5nIHN1Y2ggYW4gaW50ZWdyYXRp
b24uIEEgc2luZ2xlCiBwb2xpY3kgZW5naW5lIG1heSBoYXZlIG11bHRpcGxlIHB1cnBvc2Vz
IGRlZmluZWQsIGhvd2V2ZXIgYSBUYWdLZXkgbWF5IG9ubHkKIHNwZWNpZnkgYSBzaW5nbGUg
cHVycG9zZS4KCgsKAwUAARIE2wIFDAokCgQFAAIAEgTdAgIaGhYgVW5zcGVjaWZpZWQgcHVy
cG9zZS4KCg0KBQUAAgABEgTdAgIVCg0KBQUAAgACEgTdAhgZCq0ECgQFAAIBEgTtAgITGp4E
IFB1cnBvc2UgZm9yIENvbXB1dGUgRW5naW5lIGZpcmV3YWxscy4KIEEgY29ycmVzcG9uZGlu
ZyBgcHVycG9zZV9kYXRhYCBzaG91bGQgYmUgc2V0IGZvciB0aGUgbmV0d29yayB0aGUgdGFn
IGlzCiBpbnRlbmRlZCBmb3IuIFRoZSBrZXkgc2hvdWxkIGJlIGBuZXR3b3JrYCBhbmQgdGhl
IHZhbHVlIHNob3VsZCBiZSBpbgogZWl0aGVyIG9mIHRoZXNlIHR3byBmb3JtYXRzOgoKIC0K
IGBodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9jb21wdXRlL3tjb21wdXRlX3ZlcnNpb259
L3Byb2plY3RzL3twcm9qZWN0X2lkfS9nbG9iYWwvbmV0d29ya3Mve25ldHdvcmtfaWR9YAog
LSBge3Byb2plY3RfaWR9L3tuZXR3b3JrX25hbWV9YAoKIEV4YW1wbGVzOgoKIC0KIGBodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9jb21wdXRlL3N0YWdpbmdfdjEvcHJvamVjdHMvZmFp
bC1jbG9zZWQtbG9hZC10ZXN0aW5nL2dsb2JhbC9uZXR3b3Jrcy82OTkyOTUzNjk4ODMxNzI1
NjAwYAogLSBgZmFpbC1jbG9zZWQtbG9hZC10ZXN0aW5nL2xvYWQtdGVzdGluZy1uZXR3b3Jr
YAoKDQoFBQACAQESBO0CAg4KDQoFBQACAQISBO0CERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::TagKey ===
    # Fields for TagKey
    # Field: name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: short_name Type: 9 ()
    # Field: namespaced_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: purpose Type: 14 (.google.cloud.resourcemanager.v3.Purpose)
    # Field: purpose_data Type: 11 (.google.cloud.resourcemanager.v3.TagKey.PurposeDataEntry)

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest ===
    # Fields for ListTagKeysRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse ===
    # Fields for ListTagKeysResponse
    # Field: tag_keys Type: 11 (.google.cloud.resourcemanager.v3.TagKey)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest ===
    # Fields for GetTagKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest ===
    # Fields for GetNamespacedTagKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest ===
    # Fields for CreateTagKeyRequest
    # Field: tag_key Type: 11 (.google.cloud.resourcemanager.v3.TagKey)
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyMetadata ===
    # Fields for CreateTagKeyMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest ===
    # Fields for UpdateTagKeyRequest
    # Field: tag_key Type: 11 (.google.cloud.resourcemanager.v3.TagKey)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyMetadata ===
    # Fields for UpdateTagKeyMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest ===
    # Fields for DeleteTagKeyRequest
    # Field: name Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyMetadata ===
    # Fields for DeleteTagKeyMetadata

# === Service Client: Google::Cloud::Resourcemanager::V3::TagKeys::TagKeysClient ===
package Google::Cloud::Resourcemanager::V3::TagKeys::TagKeysClient;

=pod

=head2 Service Client: Google::Cloud::Resourcemanager::V3::TagKeys::TagKeysClient

Client stub representing the remote C<TagKeys> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<resourcemanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'resourcemanager.googleapis.com:443' );

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

sub list_tag_keys {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'ListTagKeys',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse',
    });
}

sub get_tag_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'GetTagKey',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey',
    });
}

sub get_namespaced_tag_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'GetNamespacedTagKey',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey',
    });
}

sub create_tag_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'CreateTagKey',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_tag_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'UpdateTagKey',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_tag_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'DeleteTagKey',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
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
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
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
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagKeys - Compiled Protocol Buffers messages for google/cloud/resourcemanager/v3/tag_keys.proto

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::TagKeys;

    my $msg = Google::Cloud::Resourcemanager::V3::TagKeys::TagKey->new({
        name => $name,
        parent => $parent,
        short_name => $short_name,
        namespaced_name => $namespaced_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Resourcemanager::V3::TagKeys::TagKey->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/resourcemanager/v3/tag_keys.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::TagKey

A TagKey, used to group a set of TagValues.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name for a TagKey. Must be in the format
`tagKeys/{tag_key_id}`, where `tag_key_id` is the generated numeric id for
the TagKey.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Immutable. The resource name of the TagKey's parent. A TagKey can be
parented by an Organization or a Project. For a TagKey parented by an
Organization, its parent must be in the form `organizations/{org_id}`. For
a TagKey parented by a Project, its parent can be in the form
`projects/{project_id}` or `projects/{project_number}`.

=item * C<< $msg->short_name() >> / C<< $msg->short_name($value) >>

Type: C<String>

Required. Immutable. The user friendly name for a TagKey. The short name
should be unique for TagKeys within the same tag namespace.

The short name must be 1-63 characters, beginning and ending with
an alphanumeric character ([a-z0-9A-Z]) with dashes (-), underscores (_),
dots (.), and alphanumerics between.

=item * C<< $msg->namespaced_name() >> / C<< $msg->namespaced_name($value) >>

Type: C<String>

Output only. Immutable. Namespaced name of the TagKey.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-assigned description of the TagKey. Must not exceed 256
characters.

Read-write.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. Entity tag which users can pass to prevent race conditions. This
field is always set in server responses. See UpdateTagKeyRequest for
details.

=item * C<< $msg->purpose() >> / C<< $msg->purpose($value) >>

Type: C<Enum> (L<Google::Cloud::Resourcemanager::V3::Purpose>)

Optional. A purpose denotes that this Tag is intended for use in policies
of a specific policy engine, and will involve that policy engine in
management operations involving this Tag. A purpose does not grant a
policy engine exclusive rights to the Tag, and it may be referenced by
other policy engines.

A purpose cannot be changed once set.

=item * C<< $msg->purpose_data() >> / C<< $msg->purpose_data($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey::PurposeDataEntry>)

Optional. Purpose data corresponds to the policy system that the tag is
intended for. See documentation for `Purpose` for formatting of this field.

Purpose data cannot be changed once set.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest

The request message for listing all TagKeys under a parent resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the TagKey's parent.
Must be of the form `organizations/{org_id}` or `projects/{project_id}` or
`projects/{project_number}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of TagKeys to return in the response. The
server allows a maximum of 300 TagKeys to return. If unspecified, the
server will use 100 as the default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to `ListTagKey`
that indicates where this listing should continue from.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse

The ListTagKeys response message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_keys() >> / C<< $msg->tag_keys($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>)

List of TagKeys that live under the specified parent in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to `ListTagKeys`
that indicates from where listing should continue.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest

The request message for getting a TagKey.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A resource name in the format `tagKeys/{id}`, such as
`tagKeys/123`.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest

The request message for getting a TagKey by its namespaced name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A namespaced tag key name in the format
`{parentId}/{tagKeyShort}`, such as `42/foo` for a key with short name
"foo" under the organization with ID 42 or `r2-d2/bar` for a key with short
name "bar" under the project `r2-d2`.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest

The request message for creating a TagKey.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_key() >> / C<< $msg->tag_key($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>)

Required. The TagKey to be created. Only fields `short_name`,
`description`, and `parent` are considered during the creation request.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set to true to perform validations necessary for creating the
resource, but not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyMetadata

Runtime operation information for creating a TagKey.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest

The request message for updating a TagKey.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_key() >> / C<< $msg->tag_key($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>)

Required. The new definition of the TagKey. Only the `description` and
`etag` fields can be updated by this request. If the `etag` field is not
empty, it must match the `etag` field of the existing tag key. Otherwise,
`ABORTED` will be returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Fields to be updated. The mask may only contain `description` or
`etag`. If omitted entirely, both `description` and `etag` are assumed to
be significant.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Set as true to perform validations necessary for updating the resource, but
not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyMetadata

Runtime operation information for updating a TagKey.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest

The request message for deleting a TagKey.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of a TagKey to be deleted in the format
`tagKeys/123`. The TagKey cannot be a parent of any existing TagValues or
it will not be deleted successfully.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set as true to perform validations necessary for deletion, but
not actually perform the action.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag known to the client for the expected state of the
TagKey. This is to be used for optimistic concurrency.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyMetadata

Runtime operation information for deleting a TagKey.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Resourcemanager::V3::TagKeys::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
