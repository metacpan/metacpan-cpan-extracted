package Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations;

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
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkVnb29nbGUvY2xvdWQvc3RvcmFnZWJhdGNob3BlcmF0aW9ucy92MS9zdG9yYWdlX2JhdGNo
X29wZXJhdGlvbnMucHJvdG8SJmdvb2dsZS5jbG91ZC5zdG9yYWdlYmF0Y2hvcGVyYXRpb25z
LnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5w
cm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9maWVs
ZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGktnb29nbGUvY2xvdWQv
c3RvcmFnZWJhdGNob3BlcmF0aW9ucy92MS9zdG9yYWdlX2JhdGNoX29wZXJhdGlvbnNfdHlw
ZXMucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
3wEKD0xpc3RKb2JzUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKxIpc3RvcmFnZWJh
dGNob3BlcmF0aW9ucy5nb29nbGVhcGlzLmNvbS9Kb2JSBnBhcmVudBIbCgZmaWx0ZXIYAiAB
KAlCA+BBAVIGZmlsdGVyEiAKCXBhZ2Vfc2l6ZRgDIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAQgASgJQgPgQQFSCXBhZ2VUb2tlbhIeCghvcmRlcl9ieRgFIAEoCUID4EEB
UgdvcmRlckJ5Ip0BChBMaXN0Sm9ic1Jlc3BvbnNlEj8KBGpvYnMYASADKAsyKy5nb29nbGUu
Y2xvdWQuc3RvcmFnZWJhdGNob3BlcmF0aW9ucy52MS5Kb2JSBGpvYnMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJl
YWNoYWJsZSJWCg1HZXRKb2JSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopc3RvcmFn
ZWJhdGNob3BlcmF0aW9ucy5nb29nbGVhcGlzLmNvbS9Kb2JSBG5hbWUi6QEKEENyZWF0ZUpv
YlJlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsSKXN0b3JhZ2ViYXRjaG9wZXJhdGlv
bnMuZ29vZ2xlYXBpcy5jb20vSm9iUgZwYXJlbnQSGgoGam9iX2lkGAIgASgJQgPgQQJSBWpv
YklkEkIKA2pvYhgDIAEoCzIrLmdvb2dsZS5jbG91ZC5zdG9yYWdlYmF0Y2hvcGVyYXRpb25z
LnYxLkpvYkID4EECUgNqb2ISKgoKcmVxdWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHgQQFSCXJl
cXVlc3RJZCKFAQoQQ2FuY2VsSm9iUmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6QSsKKXN0
b3JhZ2ViYXRjaG9wZXJhdGlvbnMuZ29vZ2xlYXBpcy5jb20vSm9iUgRuYW1lEioKCnJlcXVl
c3RfaWQYAyABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQioAEKEERlbGV0ZUpvYlJlcXVl
c3QSRQoEbmFtZRgBIAEoCUIx4EEC+kErCilzdG9yYWdlYmF0Y2hvcGVyYXRpb25zLmdvb2ds
ZWFwaXMuY29tL0pvYlIEbmFtZRIqCgpyZXF1ZXN0X2lkGAIgASgJQgvijM/XCAIIAeBBAVIJ
cmVxdWVzdElkEhkKBWZvcmNlGAMgASgIQgPgQQFSBWZvcmNlIhMKEUNhbmNlbEpvYlJlc3Bv
bnNlIvcBChtMaXN0QnVja2V0T3BlcmF0aW9uc1JlcXVlc3QSVQoGcGFyZW50GAEgASgJQj3g
QQL6QTcSNXN0b3JhZ2ViYXRjaG9wZXJhdGlvbnMuZ29vZ2xlYXBpcy5jb20vQnVja2V0T3Bl
cmF0aW9uUgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQFSBmZpbHRlchIgCglwYWdlX3Np
emUYAyABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgEIAEoCUID4EEBUglwYWdl
VG9rZW4SHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLOAQocTGlzdEJ1Y2tldE9w
ZXJhdGlvbnNSZXNwb25zZRJkChFidWNrZXRfb3BlcmF0aW9ucxgBIAMoCzI3Lmdvb2dsZS5j
bG91ZC5zdG9yYWdlYmF0Y2hvcGVyYXRpb25zLnYxLkJ1Y2tldE9wZXJhdGlvblIQYnVja2V0
T3BlcmF0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoL
dW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIm4KGUdldEJ1Y2tldE9wZXJhdGlvblJl
cXVlc3QSUQoEbmFtZRgBIAEoCUI94EEC+kE3CjVzdG9yYWdlYmF0Y2hvcGVyYXRpb25zLmdv
b2dsZWFwaXMuY29tL0J1Y2tldE9wZXJhdGlvblIEbmFtZSLaAgoRT3BlcmF0aW9uTWV0YWRh
dGESIQoJb3BlcmF0aW9uGAEgASgJQgPgQQNSCW9wZXJhdGlvbhJACgtjcmVhdGVfdGltZRgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6Cghl
bmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGlt
ZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAcgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNl
bGxhdGlvbhIkCgthcGlfdmVyc2lvbhgIIAEoCUID4EEDUgphcGlWZXJzaW9uEkIKA2pvYhgK
IAEoCzIrLmdvb2dsZS5jbG91ZC5zdG9yYWdlYmF0Y2hvcGVyYXRpb25zLnYxLkpvYkID4EED
UgNqb2Iy0wsKFlN0b3JhZ2VCYXRjaE9wZXJhdGlvbnMSuAEKCExpc3RKb2JzEjcuZ29vZ2xl
LmNsb3VkLnN0b3JhZ2ViYXRjaG9wZXJhdGlvbnMudjEuTGlzdEpvYnNSZXF1ZXN0GjguZ29v
Z2xlLmNsb3VkLnN0b3JhZ2ViYXRjaG9wZXJhdGlvbnMudjEuTGlzdEpvYnNSZXNwb25zZSI5
gtPkkwIqEigvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9qb2Jz2kEGcGFy
ZW50EqUBCgZHZXRKb2ISNS5nb29nbGUuY2xvdWQuc3RvcmFnZWJhdGNob3BlcmF0aW9ucy52
MS5HZXRKb2JSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLnN0b3JhZ2ViYXRjaG9wZXJhdGlvbnMu
djEuSm9iIjeC0+STAioSKC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMv
Kn3aQQRuYW1lEsoBCglDcmVhdGVKb2ISOC5nb29nbGUuY2xvdWQuc3RvcmFnZWJhdGNob3Bl
cmF0aW9ucy52MS5DcmVhdGVKb2JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbiJkgtPkkwIvIigvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9qb2Jz
OgNqb2LaQRFwYXJlbnQsam9iLGpvYl9pZMpBGAoDSm9iEhFPcGVyYXRpb25NZXRhZGF0YRKW
AQoJRGVsZXRlSm9iEjguZ29vZ2xlLmNsb3VkLnN0b3JhZ2ViYXRjaG9wZXJhdGlvbnMudjEu
RGVsZXRlSm9iUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI3gtPkkwIqKigvdjEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyp92kEEbmFtZRLDAQoJQ2FuY2Vs
Sm9iEjguZ29vZ2xlLmNsb3VkLnN0b3JhZ2ViYXRjaG9wZXJhdGlvbnMudjEuQ2FuY2VsSm9i
UmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5zdG9yYWdlYmF0Y2hvcGVyYXRpb25zLnYxLkNhbmNl
bEpvYlJlc3BvbnNlIkGC0+STAjQiLy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2pvYnMvKn06Y2FuY2VsOgEq2kEEbmFtZRLvAQoUTGlzdEJ1Y2tldE9wZXJhdGlvbnMSQy5n
b29nbGUuY2xvdWQuc3RvcmFnZWJhdGNob3BlcmF0aW9ucy52MS5MaXN0QnVja2V0T3BlcmF0
aW9uc1JlcXVlc3QaRC5nb29nbGUuY2xvdWQuc3RvcmFnZWJhdGNob3BlcmF0aW9ucy52MS5M
aXN0QnVja2V0T3BlcmF0aW9uc1Jlc3BvbnNlIkyC0+STAj0SOy92MS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovam9icy8qfS9idWNrZXRPcGVyYXRpb25z2kEGcGFyZW50EtwB
ChJHZXRCdWNrZXRPcGVyYXRpb24SQS5nb29nbGUuY2xvdWQuc3RvcmFnZWJhdGNob3BlcmF0
aW9ucy52MS5HZXRCdWNrZXRPcGVyYXRpb25SZXF1ZXN0GjcuZ29vZ2xlLmNsb3VkLnN0b3Jh
Z2ViYXRjaG9wZXJhdGlvbnMudjEuQnVja2V0T3BlcmF0aW9uIkqC0+STAj0SOy92MS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKi9idWNrZXRPcGVyYXRpb25zLyp92kEE
bmFtZRpZykElc3RvcmFnZWJhdGNob3BlcmF0aW9ucy5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CrQIKKmNvbS5nb29n
bGUuY2xvdWQuc3RvcmFnZWJhdGNob3BlcmF0aW9ucy52MUIbU3RvcmFnZUJhdGNoT3BlcmF0
aW9uc1Byb3RvUAFaYmNsb3VkLmdvb2dsZS5jb20vZ28vc3RvcmFnZWJhdGNob3BlcmF0aW9u
cy9hcGl2MS9zdG9yYWdlYmF0Y2hvcGVyYXRpb25zcGI7c3RvcmFnZWJhdGNob3BlcmF0aW9u
c3BiqgImR29vZ2xlLkNsb3VkLlN0b3JhZ2VCYXRjaE9wZXJhdGlvbnMuVjHKAiZHb29nbGVc
Q2xvdWRcU3RvcmFnZUJhdGNoT3BlcmF0aW9uc1xWMeoCKUdvb2dsZTo6Q2xvdWQ6OlN0b3Jh
Z2VCYXRjaE9wZXJhdGlvbnM6OlYxSsNMCgcSBQ4AuwIBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAvCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAApCgkKAgMDEgMVACUKCQoCAwQSAxYAIwoJCgIDBRIDFwBVCgkKAgMGEgMYAC0KCQoCAwcS
AxkAJQoJCgIDCBIDGgApCggKAQgSAxwAQwoJCgIIJRIDHABDCggKAQgSAx0AeQoJCgIICxID
HQB5CggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8APAoJCgIICBIDHwA8CggKAQgSAyAA
QwoJCgIIARIDIABDCggKAQgSAyEAQwoJCgIIKRIDIQBDCggKAQgSAyIAQgoJCgIILRIDIgBC
CpACCgIGABIEKABrARqDAiBTdG9yYWdlIEJhdGNoIE9wZXJhdGlvbnMgb2ZmZXJzIGEgbWFu
YWdlZCBleHBlcmllbmNlIHRvIHBlcmZvcm0gYmF0Y2gKIG9wZXJhdGlvbnMgb24gbWlsbGlv
bnMgb2YgQ2xvdWQgU3RvcmFnZSBvYmplY3RzIGluIGEgc2VydmVybGVzcyBmYXNoaW9uLiBX
aXRoCiB0aGlzIHNlcnZpY2UsIHlvdSBjYW4gYXV0b21hdGUgYW5kIHNpbXBsaWZ5IGxhcmdl
IHNjYWxlIEFQSSBvcGVyYXRpb25zCiBwZXJmb3JtZWQgb24gQ2xvdWQgU3RvcmFnZSBvYmpl
Y3RzLgoKCgoDBgABEgMoCB4KCgoDBgADEgMpAk0KDAoFBgADmQgSAykCTQoLCgMGAAMSBCoC
KzcKDQoFBgADmggSBCoCKzcKLgoEBgACABIELgIzAxogIExpc3RzIEpvYnMgaW4gYSBnaXZl
biBwcm9qZWN0LgoKDAoFBgACAAESAy4GDgoMCgUGAAIAAhIDLg8eCgwKBQYAAgADEgMuKTkK
DQoFBgACAAQSBC8EMQYKEQoJBgACAASwyrwiEgQvBDEGCgwKBQYAAgAEEgMyBDQKDwoIBgAC
AASbCAASAzIENAohCgQGAAIBEgQ2AjsDGhMgR2V0cyBhIGJhdGNoIGpvYi4KCgwKBQYAAgEB
EgM2BgwKDAoFBgACAQISAzYNGgoMCgUGAAIBAxIDNiUoCg0KBQYAAgEEEgQ3BDkGChEKCQYA
AgEEsMq8IhIENwQ5BgoMCgUGAAIBBBIDOgQyCg8KCAYAAgEEmwgAEgM6BDIKJAoEBgACAhIE
PgJIAxoWIENyZWF0ZXMgYSBiYXRjaCBqb2IuCgoMCgUGAAICARIDPgYPCgwKBQYAAgICEgM+
ECAKDAoFBgACAgMSAz4rRwoNCgUGAAICBBIEPwRCBgoRCgkGAAICBLDKvCISBD8EQgYKDAoF
BgACAgQSA0MEPwoPCggGAAICBJsIABIDQwQ/Cg0KBQYAAgIEEgREBEcGCg8KBwYAAgIEmQgS
BEQERwYKJAoEBgACAxIESwJQAxoWIERlbGV0ZXMgYSBiYXRjaCBqb2IuCgoMCgUGAAIDARID
SwYPCgwKBQYAAgMCEgNLECAKDAoFBgACAwMSA0srQAoNCgUGAAIDBBIETAROBgoRCgkGAAID
BLDKvCISBEwETgYKDAoFBgACAwQSA08EMgoPCggGAAIDBJsIABIDTwQyCiQKBAYAAgQSBFMC
WQMaFiBDYW5jZWxzIGEgYmF0Y2ggam9iLgoKDAoFBgACBAESA1MGDwoMCgUGAAIEAhIDUxAg
CgwKBQYAAgQDEgNTKzwKDQoFBgACBAQSBFQEVwYKEQoJBgACBASwyrwiEgRUBFcGCgwKBQYA
AgQEEgNYBDIKDwoIBgACBASbCAASA1gEMgpCCgQGAAIFEgRcAmIDGjQgTGlzdHMgQnVja2V0
T3BlcmF0aW9ucyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGpvYi4KCgwKBQYAAgUBEgNcBhoK
DAoFBgACBQISA1wbNgoMCgUGAAIFAxIDXQ8rCg0KBQYAAgUEEgReBGAGChEKCQYAAgUEsMq8
IhIEXgRgBgoMCgUGAAIFBBIDYQQ0Cg8KCAYAAgUEmwgAEgNhBDQKJwoEBgACBhIEZQJqAxoZ
IEdldHMgYSBCdWNrZXRPcGVyYXRpb24uCgoMCgUGAAIGARIDZQYYCgwKBQYAAgYCEgNlGTIK
DAoFBgACBgMSA2U9TAoNCgUGAAIGBBIEZgRoBgoRCgkGAAIGBLDKvCISBGYEaAYKDAoFBgAC
BgQSA2kEMgoPCggGAAIGBJsIABIDaQQyCi8KAgQAEgVuAIIBARoiIE1lc3NhZ2UgZm9yIHJl
cXVlc3QgdG8gbGlzdCBKb2JzCgoKCgMEAAESA24IFwpJCgQEAAIAEgRwAnUEGjsgUmVxdWly
ZWQuIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwuCgoM
CgUEAAIABRIDcAIICgwKBQQAAgABEgNwCQ8KDAoFBAACAAMSA3ASEwoNCgUEAAIACBIEcBR1
AwoPCggEAAIACJwIABIDcQQqCg8KBwQAAgAInwgSBHIEdAUKUgoEBAACARIDeAI9GkUgT3B0
aW9uYWwuIEZpbHRlcnMgcmVzdWx0cyBhcyBkZWZpbmVkIGJ5IGh0dHBzOi8vZ29vZ2xlLmFp
cC5kZXYvMTYwLgoKDAoFBAACAQUSA3gCCAoMCgUEAAIBARIDeAkPCgwKBQQAAgEDEgN4EhMK
DAoFBAACAQgSA3gUPAoPCggEAAIBCJwIABIDeBU7CkYKBAQAAgISA3sCPxo5IE9wdGlvbmFs
LiBUaGUgbGlzdCBwYWdlIHNpemUuIGRlZmF1bHQgcGFnZSBzaXplIGlzIDEwMC4KCgwKBQQA
AgIFEgN7AgcKDAoFBAACAgESA3sIEQoMCgUEAAICAxIDexQVCgwKBQQAAgIIEgN7Fj4KDwoI
BAACAgicCAASA3sXPQotCgQEAAIDEgN+AkEaICBPcHRpb25hbC4gVGhlIGxpc3QgcGFnZSB0
b2tlbi4KCgwKBQQAAgMFEgN+AggKDAoFBAACAwESA34JEwoMCgUEAAIDAxIDfhYXCgwKBQQA
AgMIEgN+GEAKDwoIBAACAwicCAASA34ZPwpTCgQEAAIEEgSBAQI/GkUgT3B0aW9uYWwuIEZp
ZWxkIHRvIHNvcnQgYnkuIFN1cHBvcnRlZCBmaWVsZHMgYXJlIG5hbWUsIGNyZWF0ZV90aW1l
LgoKDQoFBAACBAUSBIEBAggKDQoFBAACBAESBIEBCREKDQoFBAACBAMSBIEBFBUKDQoFBAAC
BAgSBIEBFj4KEAoIBAACBAicCAASBIEBFz0KNAoCBAESBoUBAI4BARomIE1lc3NhZ2UgZm9y
IHJlc3BvbnNlIHRvIGxpc3RpbmcgSm9icwoKCwoDBAEBEgSFAQgYCi0KBAQBAgASBIcBAhga
HyBBIGxpc3Qgb2Ygc3RvcmFnZSBiYXRjaCBqb2JzLgoKDQoFBAECAAQSBIcBAgoKDQoFBAEC
AAYSBIcBCw4KDQoFBAECAAESBIcBDxMKDQoFBAECAAMSBIcBFhcKNgoEBAECARIEigECHRoo
IEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMuCgoNCgUEAQIBBRIEigEC
CAoNCgUEAQIBARIEigEJGAoNCgUEAQIBAxIEigEbHAo0CgQEAQICEgSNAQIiGiYgTG9jYXRp
b25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAQICBBIEjQECCgoNCgUEAQIC
BRIEjQELEQoNCgUEAQICARIEjQESHQoNCgUEAQICAxIEjQEgIQopCgIEAhIGkQEAmgEBGhsg
TWVzc2FnZSBmb3IgZ2V0dGluZyBhIEpvYgoKCwoDBAIBEgSRAQgVCnoKBAQCAgASBpQBApkB
BBpqIFJlcXVpcmVkLiBgbmFtZWAgb2YgdGhlIGpvYiB0byByZXRyaWV2ZS4KIEZvcm1hdDog
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvam9icy97am9iX2lkfSAu
CgoNCgUEAgIABRIElAECCAoNCgUEAgIAARIElAEJDQoNCgUEAgIAAxIElAEQEQoPCgUEAgIA
CBIGlAESmQEDChAKCAQCAgAInAgAEgSVAQQqChEKBwQCAgAInwgSBpYBBJgBBQoqCgIEAxIG
nQEAuAEBGhwgTWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBKb2IKCgsKAwQDARIEnQEIGAotCgQE
AwIAEgafAQKkAQQaHSBSZXF1aXJlZC4gVmFsdWUgZm9yIHBhcmVudC4KCg0KBQQDAgAFEgSf
AQIICg0KBQQDAgABEgSfAQkPCg0KBQQDAgADEgSfARITCg8KBQQDAgAIEgafARSkAQMKEAoI
BAMCAAicCAASBKABBCoKEQoHBAMCAAifCBIGoQEEowEFCugBCgQEAwIBEgSqAQI9GtkBIFJl
cXVpcmVkLiBUaGUgb3B0aW9uYWwgYGpvYl9pZGAgZm9yIHRoaXMgSm9iIC4gSWYgbm90CiBz
cGVjaWZpZWQsIGFuIGlkIGlzIGdlbmVyYXRlZC4gYGpvYl9pZGAgc2hvdWxkIGJlIG5vIG1v
cmUgdGhhbiAxMjgKIGNoYXJhY3RlcnMgYW5kIG11c3QgaW5jbHVkZSBvbmx5IGNoYXJhY3Rl
cnMgYXZhaWxhYmxlIGluIEROUyBuYW1lcywgYXMKIGRlZmluZWQgYnkgUkZDLTExMjMuCgoN
CgUEAwIBBRIEqgECCAoNCgUEAwIBARIEqgEJDwoNCgUEAwIBAxIEqgESEwoNCgUEAwIBCBIE
qgEUPAoQCggEAwIBCJwIABIEqgEVOwo0CgQEAwICEgStAQI3GiYgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBiZWluZyBjcmVhdGVkCgoNCgUEAwICBhIErQECBQoNCgUEAwICARIErQEGCQoN
CgUEAwICAxIErQEMDQoNCgUEAwICCBIErQEONgoQCggEAwICCJwIABIErQEPNQrxAgoEBAMC
AxIGtAECtwEEGuACIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50
aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIGluIGNhc2UgeW91
IG5lZWQgdG8gcmV0cnkgeW91ciByZXF1ZXN0LiBSZXF1ZXN0cyB3aXRoIHNhbWUKIGByZXF1
ZXN0X2lkYCB3aWxsIGJlIGlnbm9yZWQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2Ug
dGhlIGZpcnN0CiByZXF1ZXN0LiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJ
RCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvCiBVVUlEIGlzIG5vdCBzdXBwb3J0ZWQg
KDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEAwIDBRIEtAEC
CAoNCgUEAwIDARIEtAEJEwoNCgUEAwIDAxIEtAEWFwoPCgUEAwIDCBIGtAEYtwEDChMKCwQD
AgMIzPH5igEBEgS1AQQqChAKCAQDAgMInAgAEgS2AQQqCikKAgQEEga7AQDOAQEaGyBNZXNz
YWdlIGZvciBKb2IgdG8gQ2FuY2VsCgoLCgMEBAESBLsBCBgKewoEBAQCABIGvgECwwEEGmsg
UmVxdWlyZWQuIFRoZSBgbmFtZWAgb2YgdGhlIGpvYiB0byBjYW5jZWwuCiBGb3JtYXQ6IHBy
b2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL2pvYnMve2pvYl9pZH0uCgoN
CgUEBAIABRIEvgECCAoNCgUEBAIAARIEvgEJDQoNCgUEBAIAAxIEvgEQEQoPCgUEBAIACBIG
vgESwwEDChAKCAQEAgAInAgAEgS/AQQqChEKBwQEAgAInwgSBsABBMIBBQrxAgoEBAQCARIG
ygECzQEEGuACIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5
IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIGluIGNhc2UgeW91IG5l
ZWQgdG8gcmV0cnkgeW91ciByZXF1ZXN0LiBSZXF1ZXN0cyB3aXRoIHNhbWUKIGByZXF1ZXN0
X2lkYCB3aWxsIGJlIGlnbm9yZWQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhl
IGZpcnN0CiByZXF1ZXN0LiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3
aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvCiBVVUlEIGlzIG5vdCBzdXBwb3J0ZWQgKDAw
MDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBAIBBRIEygECCAoN
CgUEBAIBARIEygEJEwoNCgUEBAIBAxIEygEWFwoPCgUEBAIBCBIGygEYzQEDChMKCwQEAgEI
zPH5igEBEgTLAQQqChAKCAQEAgEInAgAEgTMAQQqCioKAgQFEgbRAQDqAQEaHCBNZXNzYWdl
IGZvciBkZWxldGluZyBhIEpvYgoKCwoDBAUBEgTRAQgYCnwKBAQFAgASBtQBAtkBBBpsIFJl
cXVpcmVkLiBUaGUgYG5hbWVgIG9mIHRoZSBqb2IgdG8gZGVsZXRlLgogRm9ybWF0OiBwcm9q
ZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbC9qb2JzL3tqb2JfaWR9IC4KCg0K
BQQFAgAFEgTUAQIICg0KBQQFAgABEgTUAQkNCg0KBQQFAgADEgTUARARCg8KBQQFAgAIEgbU
ARLZAQMKEAoIBAUCAAicCAASBNUBBCoKEQoHBAUCAAifCBIG1gEE2AEFCvECCgQEBQIBEgbg
AQLjAQQa4AIgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkg
cmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgaW4gY2FzZSB5b3UgbmVl
ZCB0byByZXRyeSB5b3VyIHJlcXVlc3QuIFJlcXVlc3RzIHdpdGggc2FtZQogYHJlcXVlc3Rf
aWRgIHdpbGwgYmUgaWdub3JlZCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUg
Zmlyc3QKIHJlcXVlc3QuIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdp
dGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8KIFVVSUQgaXMgbm90IHN1cHBvcnRlZCAoMDAw
MDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQFAgEFEgTgAQIICg0K
BQQFAgEBEgTgAQkTCg0KBQQFAgEDEgTgARYXCg8KBQQFAgEIEgbgARjjAQMKEwoLBAUCAQjM
8fmKAQESBOEBBCoKEAoIBAUCAQicCAASBOIBBCoKsQIKBAQFAgISBOkBAjoaogIgT3B0aW9u
YWwuIElmIHNldCB0byB0cnVlLCBhbnkgY2hpbGQgYnVja2V0IG9wZXJhdGlvbnMgb2YgdGhl
IGpvYiB3aWxsIGFsc28KIGJlIGRlbGV0ZWQuIEhpZ2hseSByZWNvbW1lbmRlZCB0byBiZSBz
ZXQgdG8gdHJ1ZSBieSBhbGwgY2xpZW50cy4gVXNlcnMKIGNhbm5vdCBtdXRhdGUgYnVja2V0
IG9wZXJhdGlvbnMgZGlyZWN0bHksIHNvIG9ubHkgdGhlIGpvYnMuZGVsZXRlCiBwZXJtaXNz
aW9uIGlzIHJlcXVpcmVkIHRvIGRlbGV0ZSBhIGpvYiAoYW5kIGl0cyBjaGlsZCBidWNrZXQg
b3BlcmF0aW9ucykuCgoNCgUEBQICBRIE6QECBgoNCgUEBQICARIE6QEHDAoNCgUEBQICAxIE
6QEPEAoNCgUEBQICCBIE6QEROQoQCggEBQICCJwIABIE6QESOAoxCgIEBhIE7QEAHBolIE1l
c3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGNhbmNlbCBKb2IuCgoLCgMEBgESBO0BCBkKPAoCBAcS
BvABAIQCARouIE1lc3NhZ2UgZm9yIHJlcXVlc3QgdG8gbGlzdCBCdWNrZXRPcGVyYXRpb25z
CgoLCgMEBwESBPABCCMKWQoEBAcCABIG8gEC9wEEGkkgUmVxdWlyZWQuIEZvcm1hdDogcHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvam9icy97am9iX2lkfS4KCg0K
BQQHAgAFEgTyAQIICg0KBQQHAgABEgTyAQkPCg0KBQQHAgADEgTyARITCg8KBQQHAgAIEgby
ART3AQMKEAoIBAcCAAicCAASBPMBBCoKEQoHBAcCAAifCBIG9AEE9gEFClMKBAQHAgESBPoB
Aj0aRSBPcHRpb25hbC4gRmlsdGVycyByZXN1bHRzIGFzIGRlZmluZWQgYnkgaHR0cHM6Ly9n
b29nbGUuYWlwLmRldi8xNjAuCgoNCgUEBwIBBRIE+gECCAoNCgUEBwIBARIE+gEJDwoNCgUE
BwIBAxIE+gESEwoNCgUEBwIBCBIE+gEUPAoQCggEBwIBCJwIABIE+gEVOwpHCgQEBwICEgT9
AQI/GjkgT3B0aW9uYWwuIFRoZSBsaXN0IHBhZ2Ugc2l6ZS4gRGVmYXVsdCBwYWdlIHNpemUg
aXMgMTAwLgoKDQoFBAcCAgUSBP0BAgcKDQoFBAcCAgESBP0BCBEKDQoFBAcCAgMSBP0BFBUK
DQoFBAcCAggSBP0BFj4KEAoIBAcCAgicCAASBP0BFz0KLgoEBAcCAxIEgAICQRogIE9wdGlv
bmFsLiBUaGUgbGlzdCBwYWdlIHRva2VuLgoKDQoFBAcCAwUSBIACAggKDQoFBAcCAwESBIAC
CRMKDQoFBAcCAwMSBIACFhcKDQoFBAcCAwgSBIACGEAKEAoIBAcCAwicCAASBIACGT8KUwoE
BAcCBBIEgwICPxpFIE9wdGlvbmFsLiBGaWVsZCB0byBzb3J0IGJ5LiBTdXBwb3J0ZWQgZmll
bGRzIGFyZSBuYW1lLCBjcmVhdGVfdGltZS4KCg0KBQQHAgQFEgSDAgIICg0KBQQHAgQBEgSD
AgkRCg0KBQQHAgQDEgSDAhQVCg0KBQQHAgQIEgSDAhY+ChAKCAQHAgQInAgAEgSDAhc9CkAK
AgQIEgaHAgCQAgEaMiBNZXNzYWdlIGZvciByZXNwb25zZSB0byBsaXN0aW5nIEJ1Y2tldE9w
ZXJhdGlvbnMKCgsKAwQIARIEhwIIJAo6CgQECAIAEgSJAgIxGiwgQSBsaXN0IG9mIHN0b3Jh
Z2UgYmF0Y2ggYnVja2V0IG9wZXJhdGlvbnMuCgoNCgUECAIABBIEiQICCgoNCgUECAIABhIE
iQILGgoNCgUECAIAARIEiQIbLAoNCgUECAIAAxIEiQIvMAo2CgQECAIBEgSMAgIdGiggQSB0
b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cy4KCg0KBQQIAgEFEgSMAgIICg0K
BQQIAgEBEgSMAgkYCg0KBQQIAgEDEgSMAhscCjQKBAQIAgISBI8CAiIaJiBMb2NhdGlvbnMg
dGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQIAgIEEgSPAgIKCg0KBQQIAgIFEgSP
AgsRCg0KBQQIAgIBEgSPAhIdCg0KBQQIAgIDEgSPAiAhCjYKAgQJEgaTAgCdAgEaKCBNZXNz
YWdlIGZvciBnZXR0aW5nIGEgQnVja2V0T3BlcmF0aW9uLgoKCwoDBAkBEgSTAgghCq8BCgQE
CQIAEgaXAgKcAgQangEgUmVxdWlyZWQuIGBuYW1lYCBvZiB0aGUgYnVja2V0IG9wZXJhdGlv
biB0byByZXRyaWV2ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlv
bnMvZ2xvYmFsL2pvYnMve2pvYl9pZH0vYnVja2V0T3BlcmF0aW9ucy97YnVja2V0X29wZXJh
dGlvbl9pZH0uCgoNCgUECQIABRIElwICCAoNCgUECQIAARIElwIJDQoNCgUECQIAAxIElwIQ
EQoPCgUECQIACBIGlwISnAIDChAKCAQJAgAInAgAEgSYAgQqChEKBwQJAgAInwgSBpkCBJsC
BQpGCgIEChIGoAIAuwIBGjggUmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmct
cnVubmluZyBvcGVyYXRpb24uCgoLCgMECgESBKACCBkKhQEKBAQKAgASBKMCAkMadyBPdXRw
dXQgb25seS4gVGhlIHVuaXF1ZSBvcGVyYXRpb24gcmVzb3VyY2UgbmFtZS4KIEZvcm1hdDog
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy9nbG9iYWwvb3BlcmF0aW9ucy97b3BlcmF0
aW9ufS4KCg0KBQQKAgAFEgSjAgIICg0KBQQKAgABEgSjAgkSCg0KBQQKAgADEgSjAhUWCg0K
BQQKAgAIEgSjAhdCChAKCAQKAgAInAgAEgSjAhhBCkIKBAQKAgESBqYCAqcCMhoyIE91dHB1
dCBvbmx5LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDQoFBAoCAQYS
BKYCAhsKDQoFBAoCAQESBKYCHCcKDQoFBAoCAQMSBKYCKisKDQoFBAoCAQgSBKcCBjEKEAoI
BAoCAQicCAASBKcCBzAKRwoEBAoCAhIGqgICqwIyGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
IHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCg0KBQQKAgIGEgSqAgIbCg0KBQQK
AgIBEgSqAhwkCg0KBQQKAgIDEgSqAicoCg0KBQQKAgIIEgSrAgYxChAKCAQKAgIInAgAEgSr
AgcwCu8CCgQECgIDEgS0AgJOGuACIE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIg
dGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24u
IE9wZXJhdGlvbnMgdGhhdCBoYXZlIGJlZW4gY2FuY2VsbGVkIHN1Y2Nlc3NmdWxseQogaGF2
ZQogW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24uZXJyb3JdW2dvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb24uZXJyb3JdCiB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3RhdHVz
LmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25kaW5nIHRv
CiBgW0NvZGUuQ0FOQ0VMTEVEXVtnb29nbGUucnBjLkNvZGUuQ0FOQ0VMTEVEXWAuCgoNCgUE
CgIDBRIEtAICBgoNCgUECgIDARIEtAIHHQoNCgUECgIDAxIEtAIgIQoNCgUECgIDCBIEtAIi
TQoQCggECgIDCJwIABIEtAIjTApFCgQECgIEEgS3AgJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2
ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQKAgQFEgS3AgIICg0K
BQQKAgQBEgS3AgkUCg0KBQQKAgQDEgS3AhcYCg0KBQQKAgQIEgS3AhlEChAKCAQKAgQInAgA
EgS3AhpDCkMKBAQKAgUSBLoCAjsaNSBPdXRwdXQgb25seS4gVGhlIEpvYiBhc3NvY2lhdGVk
IHdpdGggdGhlIG9wZXJhdGlvbi4KCg0KBQQKAgUGEgS6AgIFCg0KBQQKAgUBEgS6AgYJCg0K
BQQKAgUDEgS6AgwOCg0KBQQKAgUIEgS6Ag86ChAKCAQKAgUInAgAEgS6AhA5YgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest ===
    # Fields for ListJobsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsResponse ===
    # Fields for ListJobsResponse
    # Field: jobs Type: 11 (.google.cloud.storagebatchoperations.v1.Job)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetJobRequest ===
    # Fields for GetJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CreateJobRequest ===
    # Fields for CreateJobRequest
    # Field: parent Type: 9 ()
    # Field: job_id Type: 9 ()
    # Field: job Type: 11 (.google.cloud.storagebatchoperations.v1.Job)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobRequest ===
    # Fields for CancelJobRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::DeleteJobRequest ===
    # Fields for DeleteJobRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobResponse ===
    # Fields for CancelJobResponse

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsRequest ===
    # Fields for ListBucketOperationsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsResponse ===
    # Fields for ListBucketOperationsResponse
    # Field: bucket_operations Type: 11 (.google.cloud.storagebatchoperations.v1.BucketOperation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetBucketOperationRequest ===
    # Fields for GetBucketOperationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: operation Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: job Type: 11 (.google.cloud.storagebatchoperations.v1.Job)

# === Service Client: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::StorageBatchOperationsClient ===
package Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::StorageBatchOperationsClient;

=pod

=head2 Service Client: Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::StorageBatchOperationsClient

Client stub representing the remote C<StorageBatchOperations> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<storagebatchoperations.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'storagebatchoperations.googleapis.com:443' );

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

sub list_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'ListJobs',
        request        => $req,
        response_class => 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsResponse',
    });
}

sub get_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'GetJob',
        request        => $req,
        response_class => 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job',
    });
}

sub create_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CreateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'CreateJob',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::DeleteJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'DeleteJob',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub cancel_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'CancelJob',
        request        => $req,
        response_class => 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobResponse',
    });
}

sub list_bucket_operations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'ListBucketOperations',
        request        => $req,
        response_class => 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsResponse',
    });
}

sub get_bucket_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetBucketOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.storagebatchoperations.v1.StorageBatchOperations',
        method         => 'GetBucketOperation',
        request        => $req,
        response_class => 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketOperation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations - Compiled Protocol Buffers messages for google/cloud/storagebatchoperations/v1/storage_batch_operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations;

    my $msg = Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest->new({
        parent => $parent,
        filter => $filter,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/storagebatchoperations/v1/storage_batch_operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest

Message for request to list Jobs

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format: projects/{project_id}/locations/global.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filters results as defined by https://google.aip.dev/160.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The list page size. default page size is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The list page token.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field to sort by. Supported fields are name, create_time.

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsResponse

Message for response to listing Jobs

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<Message> (L<Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job>)

A list of storage batch jobs.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetJobRequest

Message for getting a Job

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. `name` of the job to retrieve.
Format: projects/{project_id}/locations/global/jobs/{job_id} .

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CreateJobRequest

Message for creating a Job

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Value for parent.

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

Required. The optional `job_id` for this Job . If not
specified, an id is generated. `job_id` should be no more than 128
characters and must include only characters available in DNS names, as
defined by RFC-1123.

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job>)

Required. The resource being created

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID in case you need to retry your request. Requests with same
`request_id` will be ignored for at least 60 minutes since the first
request. The request ID must be a valid UUID with the exception that zero
UUID is not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobRequest

Message for Job to Cancel

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The `name` of the job to cancel.
Format: projects/{project_id}/locations/global/jobs/{job_id}.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID in case you need to retry your request. Requests with same
`request_id` will be ignored for at least 60 minutes since the first
request. The request ID must be a valid UUID with the exception that zero
UUID is not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::DeleteJobRequest

Message for deleting a Job

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The `name` of the job to delete.
Format: projects/{project_id}/locations/global/jobs/{job_id} .

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID in case you need to retry your request. Requests with same
`request_id` will be ignored for at least 60 minutes since the first
request. The request ID must be a valid UUID with the exception that zero
UUID is not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, any child bucket operations of the job will also
be deleted. Highly recommended to be set to true by all clients. Users
cannot mutate bucket operations directly, so only the jobs.delete
permission is required to delete a job (and its child bucket operations).

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobResponse

Message for response to cancel Job.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsRequest

Message for request to list BucketOperations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format: projects/{project_id}/locations/global/jobs/{job_id}.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filters results as defined by https://google.aip.dev/160.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The list page size. Default page size is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The list page token.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field to sort by. Supported fields are name, create_time.

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsResponse

Message for response to listing BucketOperations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket_operations() >> / C<< $msg->bucket_operations($value) >>

Type: C<Message> (L<Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketOperation>)

A list of storage batch bucket operations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetBucketOperationRequest

Message for getting a BucketOperation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. `name` of the bucket operation to retrieve.
Format:
projects/{project_id}/locations/global/jobs/{job_id}/bucketOperations/{bucket_operation_id}.

=back

=head2 Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<String>

Output only. The unique operation resource name.
Format: projects/{project}/locations/global/operations/{operation}.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to
`[Code.CANCELLED][google.rpc.Code.CANCELLED]`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job>)

Output only. The Job associated with the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
