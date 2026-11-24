package Google::Cloud::Video::Transcoder::V1::Services;

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
    eval { require Google::Cloud::Video::Transcoder::V1::Resources };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvdmlkZW8vdHJhbnNjb2Rlci92MS9zZXJ2aWNlcy5wcm90bxIgZ29v
Z2xlLmNsb3VkLnZpZGVvLnRyYW5zY29kZXIudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjBnb29nbGUvY2xvdWQvdmlk
ZW8vdHJhbnNjb2Rlci92MS9yZXNvdXJjZXMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0
eS5wcm90byKTAQoQQ3JlYXRlSm9iUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwoh
bG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSPAoDam9iGAIgASgL
MiUuZ29vZ2xlLmNsb3VkLnZpZGVvLnRyYW5zY29kZXIudjEuSm9iQgPgQQJSA2pvYiLDAQoP
TGlzdEpvYnNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29v
Z2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VT
aXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZp
bHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSJKCg1HZXRKb2JSZXF1ZXN0EjkKBG5h
bWUYASABKAlCJeBBAvpBHwoddHJhbnNjb2Rlci5nb29nbGVhcGlzLmNvbS9Kb2JSBG5hbWUi
cgoQRGVsZXRlSm9iUmVxdWVzdBI5CgRuYW1lGAEgASgJQiXgQQL6QR8KHXRyYW5zY29kZXIu
Z29vZ2xlYXBpcy5jb20vSm9iUgRuYW1lEiMKDWFsbG93X21pc3NpbmcYAiABKAhSDGFsbG93
TWlzc2luZyKXAQoQTGlzdEpvYnNSZXNwb25zZRI5CgRqb2JzGAEgAygLMiUuZ29vZ2xlLmNs
b3VkLnZpZGVvLnRyYW5zY29kZXIudjEuSm9iUgRqb2JzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUi
4QEKGENyZWF0ZUpvYlRlbXBsYXRlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwoh
bG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSVQoMam9iX3RlbXBs
YXRlGAIgASgLMi0uZ29vZ2xlLmNsb3VkLnZpZGVvLnRyYW5zY29kZXIudjEuSm9iVGVtcGxh
dGVCA+BBAlILam9iVGVtcGxhdGUSKwoPam9iX3RlbXBsYXRlX2lkGAMgASgJQgPgQQJSDWpv
YlRlbXBsYXRlSWQiywEKF0xpc3RKb2JUZW1wbGF0ZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEo
CUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIb
CglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VU
b2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJC
eSJaChVHZXRKb2JUZW1wbGF0ZVJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt4EEC+kEnCiV0cmFu
c2NvZGVyLmdvb2dsZWFwaXMuY29tL0pvYlRlbXBsYXRlUgRuYW1lIoIBChhEZWxldGVKb2JU
ZW1wbGF0ZVJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt4EEC+kEnCiV0cmFuc2NvZGVyLmdvb2ds
ZWFwaXMuY29tL0pvYlRlbXBsYXRlUgRuYW1lEiMKDWFsbG93X21pc3NpbmcYAiABKAhSDGFs
bG93TWlzc2luZyK4AQoYTGlzdEpvYlRlbXBsYXRlc1Jlc3BvbnNlElIKDWpvYl90ZW1wbGF0
ZXMYASADKAsyLS5nb29nbGUuY2xvdWQudmlkZW8udHJhbnNjb2Rlci52MS5Kb2JUZW1wbGF0
ZVIMam9iVGVtcGxhdGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
bhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUykgwKEVRyYW5zY29kZXJTZXJ2
aWNlEqoBCglDcmVhdGVKb2ISMi5nb29nbGUuY2xvdWQudmlkZW8udHJhbnNjb2Rlci52MS5D
cmVhdGVKb2JSZXF1ZXN0GiUuZ29vZ2xlLmNsb3VkLnZpZGVvLnRyYW5zY29kZXIudjEuSm9i
IkKC0+STAi8iKC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2pvYnM6A2pv
YtpBCnBhcmVudCxqb2ISrAEKCExpc3RKb2JzEjEuZ29vZ2xlLmNsb3VkLnZpZGVvLnRyYW5z
Y29kZXIudjEuTGlzdEpvYnNSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLnZpZGVvLnRyYW5zY29k
ZXIudjEuTGlzdEpvYnNSZXNwb25zZSI5gtPkkwIqEigvdjEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qfS9qb2Jz2kEGcGFyZW50EpkBCgZHZXRKb2ISLy5nb29nbGUuY2xvdWQu
dmlkZW8udHJhbnNjb2Rlci52MS5HZXRKb2JSZXF1ZXN0GiUuZ29vZ2xlLmNsb3VkLnZpZGVv
LnRyYW5zY29kZXIudjEuSm9iIjeC0+STAioSKC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2pvYnMvKn3aQQRuYW1lEpABCglEZWxldGVKb2ISMi5nb29nbGUuY2xvdWQudmlk
ZW8udHJhbnNjb2Rlci52MS5EZWxldGVKb2JSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5IjeC0+STAioqKC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn3a
QQRuYW1lEuwBChFDcmVhdGVKb2JUZW1wbGF0ZRI6Lmdvb2dsZS5jbG91ZC52aWRlby50cmFu
c2NvZGVyLnYxLkNyZWF0ZUpvYlRlbXBsYXRlUmVxdWVzdBotLmdvb2dsZS5jbG91ZC52aWRl
by50cmFuc2NvZGVyLnYxLkpvYlRlbXBsYXRlImyC0+STAkAiMC92MS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyp9L2pvYlRlbXBsYXRlczoMam9iX3RlbXBsYXRl2kEjcGFyZW50
LGpvYl90ZW1wbGF0ZSxqb2JfdGVtcGxhdGVfaWQSzAEKEExpc3RKb2JUZW1wbGF0ZXMSOS5n
b29nbGUuY2xvdWQudmlkZW8udHJhbnNjb2Rlci52MS5MaXN0Sm9iVGVtcGxhdGVzUmVxdWVz
dBo6Lmdvb2dsZS5jbG91ZC52aWRlby50cmFuc2NvZGVyLnYxLkxpc3RKb2JUZW1wbGF0ZXNS
ZXNwb25zZSJBgtPkkwIyEjAvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9q
b2JUZW1wbGF0ZXPaQQZwYXJlbnQSuQEKDkdldEpvYlRlbXBsYXRlEjcuZ29vZ2xlLmNsb3Vk
LnZpZGVvLnRyYW5zY29kZXIudjEuR2V0Sm9iVGVtcGxhdGVSZXF1ZXN0Gi0uZ29vZ2xlLmNs
b3VkLnZpZGVvLnRyYW5zY29kZXIudjEuSm9iVGVtcGxhdGUiP4LT5JMCMhIwL3YxL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovam9iVGVtcGxhdGVzLyp92kEEbmFtZRKoAQoRRGVs
ZXRlSm9iVGVtcGxhdGUSOi5nb29nbGUuY2xvdWQudmlkZW8udHJhbnNjb2Rlci52MS5EZWxl
dGVKb2JUZW1wbGF0ZVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiP4LT5JMCMiow
L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovam9iVGVtcGxhdGVzLyp92kEEbmFt
ZRpNykEZdHJhbnNjb2Rlci5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C6gEKJGNvbS5nb29nbGUuY2xvdWQudmlkZW8u
dHJhbnNjb2Rlci52MUINU2VydmljZXNQcm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dvL3Zp
ZGVvL3RyYW5zY29kZXIvYXBpdjEvdHJhbnNjb2RlcnBiO3RyYW5zY29kZXJwYqoCIEdvb2ds
ZS5DbG91ZC5WaWRlby5UcmFuc2NvZGVyLlYxygIgR29vZ2xlXENsb3VkXFZpZGVvXFRyYW5z
Y29kZXJcVjHqAiRHb29nbGU6OkNsb3VkOjpWaWRlbzo6VHJhbnNjb2Rlcjo6VjFK3j4KBxIF
DgCYAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA6CgkK
AgMFEgMXACUKCAoBCBIDGQA9CgkKAgglEgMZAD0KCAoBCBIDGgBbCgkKAggLEgMaAFsKCAoB
CBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAuCgkKAggIEgMcAC4KCAoBCBIDHQA9CgkKAggB
EgMdAD0KCAoBCBIDHgA+CgkKAggpEgMeAD4KCAoBCBIDHwA9CgkKAggtEgMfAD0KxAMKAgYA
EgQnAHABGrcDIFVzaW5nIHRoZSBUcmFuc2NvZGVyIEFQSSwgeW91IGNhbiBxdWV1ZSBhc3lu
Y2hyb25vdXMgam9icyBmb3IgdHJhbnNjb2RpbmcKIG1lZGlhIGludG8gdmFyaW91cyBvdXRw
dXQgZm9ybWF0cy4gT3V0cHV0IGZvcm1hdHMgbWF5IGluY2x1ZGUgZGlmZmVyZW50CiBzdHJl
YW1pbmcgc3RhbmRhcmRzIHN1Y2ggYXMgSFRUUCBMaXZlIFN0cmVhbWluZyAoSExTKSBhbmQg
RHluYW1pYyBBZGFwdGl2ZQogU3RyZWFtaW5nIG92ZXIgSFRUUCAoREFTSCkuIFlvdSBjYW4g
YWxzbyBjdXN0b21pemUgam9icyB1c2luZyBhZHZhbmNlZAogZmVhdHVyZXMgc3VjaCBhcyBE
aWdpdGFsIFJpZ2h0cyBNYW5hZ2VtZW50IChEUk0pLCBhdWRpbyBlcXVhbGl6YXRpb24sIGNv
bnRlbnQKIGNvbmNhdGVuYXRpb24sIGFuZCBkaWdpdGFsIGFkLXN0aXRjaCByZWFkeSBjb250
ZW50IGdlbmVyYXRpb24uCgoKCgMGAAESAycIGQoKCgMGAAMSAygCQQoMCgUGAAOZCBIDKAJB
CgsKAwYAAxIEKQIqNwoNCgUGAAOaCBIEKQIqNwo2CgQGAAIAEgQtAjMDGiggQ3JlYXRlcyBh
IGpvYiBpbiB0aGUgc3BlY2lmaWVkIHJlZ2lvbi4KCgwKBQYAAgABEgMtBg8KDAoFBgACAAIS
Ay0QIAoMCgUGAAIAAxIDLSsuCg0KBQYAAgAEEgQuBDEGChEKCQYAAgAEsMq8IhIELgQxBgoM
CgUGAAIABBIDMgQ4Cg8KCAYAAgAEmwgAEgMyBDgKMwoEBgACARIENgI7AxolIExpc3RzIGpv
YnMgaW4gdGhlIHNwZWNpZmllZCByZWdpb24uCgoMCgUGAAIBARIDNgYOCgwKBQYAAgECEgM2
Dx4KDAoFBgACAQMSAzYpOQoNCgUGAAIBBBIENwQ5BgoRCgkGAAIBBLDKvCISBDcEOQYKDAoF
BgACAQQSAzoENAoPCggGAAIBBJsIABIDOgQ0CiUKBAYAAgISBD4CQwMaFyBSZXR1cm5zIHRo
ZSBqb2IgZGF0YS4KCgwKBQYAAgIBEgM+BgwKDAoFBgACAgISAz4NGgoMCgUGAAICAxIDPiUo
Cg0KBQYAAgIEEgQ/BEEGChEKCQYAAgIEsMq8IhIEPwRBBgoMCgUGAAICBBIDQgQyCg8KCAYA
AgIEmwgAEgNCBDIKHgoEBgACAxIERgJLAxoQIERlbGV0ZXMgYSBqb2IuCgoMCgUGAAIDARID
RgYPCgwKBQYAAgMCEgNGECAKDAoFBgACAwMSA0YrQAoNCgUGAAIDBBIERwRJBgoRCgkGAAID
BLDKvCISBEcESQYKDAoFBgACAwQSA0oEMgoPCggGAAIDBJsIABIDSgQyCj8KBAYAAgQSBE4C
VQMaMSBDcmVhdGVzIGEgam9iIHRlbXBsYXRlIGluIHRoZSBzcGVjaWZpZWQgcmVnaW9uLgoK
DAoFBgACBAESA04GFwoMCgUGAAIEAhIDThgwCgwKBQYAAgQDEgNOO0YKDQoFBgACBAQSBE8E
UgYKEQoJBgACBASwyrwiEgRPBFIGCg0KBQYAAgQEEgRTBFQuChAKCAYAAgQEmwgAEgRTBFQu
CjwKBAYAAgUSBFgCXgMaLiBMaXN0cyBqb2IgdGVtcGxhdGVzIGluIHRoZSBzcGVjaWZpZWQg
cmVnaW9uLgoKDAoFBgACBQESA1gGFgoMCgUGAAIFAhIDWBcuCgwKBQYAAgUDEgNZDycKDQoF
BgACBQQSBFoEXAYKEQoJBgACBQSwyrwiEgRaBFwGCgwKBQYAAgUEEgNdBDQKDwoIBgACBQSb
CAASA10ENAouCgQGAAIGEgRhAmYDGiAgUmV0dXJucyB0aGUgam9iIHRlbXBsYXRlIGRhdGEu
CgoMCgUGAAIGARIDYQYUCgwKBQYAAgYCEgNhFSoKDAoFBgACBgMSA2E1QAoNCgUGAAIGBBIE
YgRkBgoRCgkGAAIGBLDKvCISBGIEZAYKDAoFBgACBgQSA2UEMgoPCggGAAIGBJsIABIDZQQy
CicKBAYAAgcSBGkCbwMaGSBEZWxldGVzIGEgam9iIHRlbXBsYXRlLgoKDAoFBgACBwESA2kG
FwoMCgUGAAIHAhIDaRgwCgwKBQYAAgcDEgNqDyQKDQoFBgACBwQSBGsEbQYKEQoJBgACBwSw
yrwiEgRrBG0GCgwKBQYAAgcEEgNuBDIKDwoIBgACBwSbCAASA24EMgpACgIEABIEcwB/ARo0
IFJlcXVlc3QgbWVzc2FnZSBmb3IgYFRyYW5zY29kZXJTZXJ2aWNlLkNyZWF0ZUpvYmAuCgoK
CgMEAAESA3MIGAqAAQoEBAACABIEdgJ7BBpyIFJlcXVpcmVkLiBUaGUgcGFyZW50IGxvY2F0
aW9uIHRvIGNyZWF0ZSBhbmQgcHJvY2VzcyB0aGlzIGpvYi4KIEZvcm1hdDogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCgwKBQQAAgAFEgN2AggKDAoFBAAC
AAESA3YJDwoMCgUEAAIAAxIDdhITCg0KBQQAAgAIEgR2FHsDCg8KCAQAAgAInAgAEgN3BCoK
DwoHBAACAAifCBIEeAR6BQpBCgQEAAIBEgN+AjcaNCBSZXF1aXJlZC4gUGFyYW1ldGVycyBm
b3IgY3JlYXRpbmcgdHJhbnNjb2Rpbmcgam9iLgoKDAoFBAACAQYSA34CBQoMCgUEAAIBARID
fgYJCgwKBQQAAgEDEgN+DA0KDAoFBAACAQgSA34ONgoPCggEAAIBCJwIABIDfg81CoUBCgIE
ARIGgwEAmgEBGncgUmVxdWVzdCBtZXNzYWdlIGZvciBgVHJhbnNjb2RlclNlcnZpY2UuTGlz
dEpvYnNgLgogVGhlIHBhcmVudCBsb2NhdGlvbiBmcm9tIHdoaWNoIHRvIHJldHJpZXZlIHRo
ZSBjb2xsZWN0aW9uIG9mIGpvYnMuCgoLCgMEAQESBIMBCBcKTQoEBAECABIGhQECigEEGj0g
UmVxdWlyZWQuIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufWAKCg0KBQQBAgAFEgSFAQIICg0KBQQBAgABEgSFAQkPCg0KBQQBAgADEgSFARITCg8K
BQQBAgAIEgaFARSKAQMKEAoIBAECAAicCAASBIYBBCoKEQoHBAECAAifCBIGhwEEiQEFCjYK
BAQBAgESBI0BAhYaKCBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgoK
DQoFBAECAQUSBI0BAgcKDQoFBAECAQESBI0BCBEKDQoFBAECAQMSBI0BFBUKWwoEBAECAhIE
kQECGBpNIFRoZSBgbmV4dF9wYWdlX3Rva2VuYCB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJl
dmlvdXMgTGlzdCByZXF1ZXN0LCBpZgogYW55LgoKDQoFBAECAgUSBJEBAggKDQoFBAECAgES
BJEBCRMKDQoFBAECAgMSBJEBFhcKZAoEBAECAxIElQECFBpWIFRoZSBmaWx0ZXIgZXhwcmVz
c2lvbiwgZm9sbG93aW5nIHRoZSBzeW50YXggb3V0bGluZWQgaW4KIGh0dHBzOi8vZ29vZ2xl
LmFpcC5kZXYvMTYwLgoKDQoFBAECAwUSBJUBAggKDQoFBAECAwESBJUBCQ8KDQoFBAECAwMS
BJUBEhMKcwoEBAECBBIEmQECFhplIE9uZSBvciBtb3JlIGZpZWxkcyB0byBjb21wYXJlIGFu
ZCB1c2UgdG8gc29ydCB0aGUgb3V0cHV0LgogU2VlIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYv
MTMyI29yZGVyaW5nLgoKDQoFBAECBAUSBJkBAggKDQoFBAECBAESBJkBCREKDQoFBAECBAMS
BJkBFBUKPwoCBAISBp0BAKQBARoxIFJlcXVlc3QgbWVzc2FnZSBmb3IgYFRyYW5zY29kZXJT
ZXJ2aWNlLkdldEpvYmAuCgoLCgMEAgESBJ0BCBUKegoEBAICABIGoAECowEEGmogUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBqb2IgdG8gcmV0cmlldmUuCiBGb3JtYXQ6IGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vam9icy97am9ifWAKCg0KBQQCAgAF
EgSgAQIICg0KBQQCAgABEgSgAQkNCg0KBQQCAgADEgSgARARCg8KBQQCAgAIEgagARKjAQMK
EAoIBAICAAicCAASBKEBBCoKDwoHBAICAAifCBIEogEETwpCCgIEAxIGpwEAsgEBGjQgUmVx
dWVzdCBtZXNzYWdlIGZvciBgVHJhbnNjb2RlclNlcnZpY2UuRGVsZXRlSm9iYC4KCgsKAwQD
ARIEpwEIGAp4CgQEAwIAEgaqAQKtAQQaaCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGpv
YiB0byBkZWxldGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vam9icy97am9ifWAKCg0KBQQDAgAFEgSqAQIICg0KBQQDAgABEgSqAQkNCg0K
BQQDAgADEgSqARARCg8KBQQDAgAIEgaqARKtAQMKEAoIBAMCAAicCAASBKsBBCoKDwoHBAMC
AAifCBIErAEETwp+CgQEAwIBEgSxAQIZGnAgSWYgc2V0IHRvIHRydWUsIGFuZCB0aGUgam9i
IGlzIG5vdCBmb3VuZCwgdGhlIHJlcXVlc3Qgd2lsbCBzdWNjZWVkIGJ1dCBubwogYWN0aW9u
IHdpbGwgYmUgdGFrZW4gb24gdGhlIHNlcnZlci4KCg0KBQQDAgEFEgSxAQIGCg0KBQQDAgEB
EgSxAQcUCg0KBQQDAgEDEgSxARcYCkIKAgQEEga1AQC+AQEaNCBSZXNwb25zZSBtZXNzYWdl
IGZvciBgVHJhbnNjb2RlclNlcnZpY2UuTGlzdEpvYnNgLgoKCwoDBAQBEgS1AQgYCjUKBAQE
AgASBLcBAhgaJyBMaXN0IG9mIGpvYnMgaW4gdGhlIHNwZWNpZmllZCByZWdpb24uCgoNCgUE
BAIABBIEtwECCgoNCgUEBAIABhIEtwELDgoNCgUEBAIAARIEtwEPEwoNCgUEBAIAAxIEtwEW
FwolCgQEBAIBEgS6AQIdGhcgVGhlIHBhZ2luYXRpb24gdG9rZW4uCgoNCgUEBAIBBRIEugEC
CAoNCgUEBAIBARIEugEJGAoNCgUEBAIBAxIEugEbHAo6CgQEBAICEgS9AQIiGiwgTGlzdCBv
ZiByZWdpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEBAICBBIEvQECCgoN
CgUEBAICBRIEvQELEQoNCgUEBAICARIEvQESHQoNCgUEBAICAxIEvQEgIQpKCgIEBRIGwQEA
1AEBGjwgUmVxdWVzdCBtZXNzYWdlIGZvciBgVHJhbnNjb2RlclNlcnZpY2UuQ3JlYXRlSm9i
VGVtcGxhdGVgLgoKCwoDBAUBEgTBAQggCn8KBAQFAgASBsQBAskBBBpvIFJlcXVpcmVkLiBU
aGUgcGFyZW50IGxvY2F0aW9uIHRvIGNyZWF0ZSB0aGlzIGpvYiB0ZW1wbGF0ZS4KIEZvcm1h
dDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCg0KBQQFAgAF
EgTEAQIICg0KBQQFAgABEgTEAQkPCg0KBQQFAgADEgTEARITCg8KBQQFAgAIEgbEARTJAQMK
EAoIBAUCAAicCAASBMUBBCoKEQoHBAUCAAifCBIGxgEEyAEFCj8KBAQFAgESBMwBAkgaMSBS
ZXF1aXJlZC4gUGFyYW1ldGVycyBmb3IgY3JlYXRpbmcgam9iIHRlbXBsYXRlLgoKDQoFBAUC
AQYSBMwBAg0KDQoFBAUCAQESBMwBDhoKDQoFBAUCAQMSBMwBHR4KDQoFBAUCAQgSBMwBH0cK
EAoIBAUCAQicCAASBMwBIEYKhAIKBAQFAgISBNMBAkYa9QEgUmVxdWlyZWQuIFRoZSBJRCB0
byB1c2UgZm9yIHRoZSBqb2IgdGVtcGxhdGUsIHdoaWNoIHdpbGwgYmVjb21lIHRoZSBmaW5h
bAogY29tcG9uZW50IG9mIHRoZSBqb2IgdGVtcGxhdGUncyByZXNvdXJjZSBuYW1lLgoKIFRo
aXMgdmFsdWUgc2hvdWxkIGJlIDQtNjMgY2hhcmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3Rl
cnMgbXVzdCBtYXRjaCB0aGUKIHJlZ3VsYXIgZXhwcmVzc2lvbiBgW2EtekEtWl1bYS16QS1a
MC05Xy1dKmAuCgoNCgUEBQICBRIE0wECCAoNCgUEBQICARIE0wEJGAoNCgUEBQICAxIE0wEb
HAoNCgUEBQICCBIE0wEdRQoQCggEBQICCJwIABIE0wEeRApJCgIEBhIG1wEA7wEBGjsgUmVx
dWVzdCBtZXNzYWdlIGZvciBgVHJhbnNjb2RlclNlcnZpY2UuTGlzdEpvYlRlbXBsYXRlc2Au
CgoLCgMEBgESBNcBCB8KmwEKBAQGAgASBtoBAt8BBBqKASBSZXF1aXJlZC4gVGhlIHBhcmVu
dCBsb2NhdGlvbiBmcm9tIHdoaWNoIHRvIHJldHJpZXZlIHRoZSBjb2xsZWN0aW9uIG9mIGpv
YgogdGVtcGxhdGVzLiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn1gCgoNCgUEBgIABRIE2gECCAoNCgUEBgIAARIE2gEJDwoNCgUEBgIAAxIE2gES
EwoPCgUEBgIACBIG2gEU3wEDChAKCAQGAgAInAgAEgTbAQQqChEKBwQGAgAInwgSBtwBBN4B
BQo2CgQEBgIBEgTiAQIWGiggVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVy
bi4KCg0KBQQGAgEFEgTiAQIHCg0KBQQGAgEBEgTiAQgRCg0KBQQGAgEDEgTiARQVClsKBAQG
AgISBOYBAhgaTSBUaGUgYG5leHRfcGFnZV90b2tlbmAgdmFsdWUgcmV0dXJuZWQgZnJvbSBh
IHByZXZpb3VzIExpc3QgcmVxdWVzdCwgaWYKIGFueS4KCg0KBQQGAgIFEgTmAQIICg0KBQQG
AgIBEgTmAQkTCg0KBQQGAgIDEgTmARYXCmQKBAQGAgMSBOoBAhQaViBUaGUgZmlsdGVyIGV4
cHJlc3Npb24sIGZvbGxvd2luZyB0aGUgc3ludGF4IG91dGxpbmVkIGluCiBodHRwczovL2dv
b2dsZS5haXAuZGV2LzE2MC4KCg0KBQQGAgMFEgTqAQIICg0KBQQGAgMBEgTqAQkPCg0KBQQG
AgMDEgTqARITCnMKBAQGAgQSBO4BAhYaZSBPbmUgb3IgbW9yZSBmaWVsZHMgdG8gY29tcGFy
ZSBhbmQgdXNlIHRvIHNvcnQgdGhlIG91dHB1dC4KIFNlZSBodHRwczovL2dvb2dsZS5haXAu
ZGV2LzEzMiNvcmRlcmluZy4KCg0KBQQGAgQFEgTuAQIICg0KBQQGAgQBEgTuAQkRCg0KBQQG
AgQDEgTuARQVCkcKAgQHEgbyAQD8AQEaOSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBUcmFuc2Nv
ZGVyU2VydmljZS5HZXRKb2JUZW1wbGF0ZWAuCgoLCgMEBwESBPIBCB0KlgEKBAQHAgASBvYB
AvsBBBqFASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGpvYiB0ZW1wbGF0ZSB0byByZXRy
aWV2ZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vam9iVGVtcGxhdGVzL3tqb2JfdGVtcGxhdGV9YAoKDQoFBAcCAAUSBPYBAggKDQoFBAcC
AAESBPYBCQ0KDQoFBAcCAAMSBPYBEBEKDwoFBAcCAAgSBvYBEvsBAwoQCggEBwIACJwIABIE
9wEEKgoRCgcEBwIACJ8IEgb4AQT6AQUKSgoCBAgSBv8BAIwCARo8IFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgYFRyYW5zY29kZXJTZXJ2aWNlLkRlbGV0ZUpvYlRlbXBsYXRlYC4KCgsKAwQIARIE
/wEIIAqKAQoEBAgCABIGggIChwIEGnogUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBqb2Ig
dGVtcGxhdGUgdG8gZGVsZXRlLgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9qb2JUZW1wbGF0ZXMve2pvYl90ZW1wbGF0ZX1gCgoNCgUECAIABRIEggICCAoN
CgUECAIAARIEggIJDQoNCgUECAIAAxIEggIQEQoPCgUECAIACBIGggIShwIDChAKCAQIAgAI
nAgAEgSDAgQqChEKBwQIAgAInwgSBoQCBIYCBQqHAQoEBAgCARIEiwICGRp5IElmIHNldCB0
byB0cnVlLCBhbmQgdGhlIGpvYiB0ZW1wbGF0ZSBpcyBub3QgZm91bmQsIHRoZSByZXF1ZXN0
IHdpbGwgc3VjY2VlZAogYnV0IG5vIGFjdGlvbiB3aWxsIGJlIHRha2VuIG9uIHRoZSBzZXJ2
ZXIuCgoNCgUECAIBBRIEiwICBgoNCgUECAIBARIEiwIHFAoNCgUECAIBAxIEiwIXGApKCgIE
CRIGjwIAmAIBGjwgUmVzcG9uc2UgbWVzc2FnZSBmb3IgYFRyYW5zY29kZXJTZXJ2aWNlLkxp
c3RKb2JUZW1wbGF0ZXNgLgoKCwoDBAkBEgSPAgggCj4KBAQJAgASBJECAikaMCBMaXN0IG9m
IGpvYiB0ZW1wbGF0ZXMgaW4gdGhlIHNwZWNpZmllZCByZWdpb24uCgoNCgUECQIABBIEkQIC
CgoNCgUECQIABhIEkQILFgoNCgUECQIAARIEkQIXJAoNCgUECQIAAxIEkQInKAolCgQECQIB
EgSUAgIdGhcgVGhlIHBhZ2luYXRpb24gdG9rZW4uCgoNCgUECQIBBRIElAICCAoNCgUECQIB
ARIElAIJGAoNCgUECQIBAxIElAIbHAo6CgQECQICEgSXAgIiGiwgTGlzdCBvZiByZWdpb25z
IHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUECQICBBIElwICCgoNCgUECQICBRIE
lwILEQoNCgUECQICARIElwISHQoNCgUECQICAxIElwIgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest ===
    # Fields for CreateJobRequest
    # Field: parent Type: 9 ()
    # Field: job Type: 11 (.google.cloud.video.transcoder.v1.Job)

# === Message: Google::Cloud::Video::Transcoder::V1::Services::ListJobsRequest ===
    # Fields for ListJobsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::GetJobRequest ===
    # Fields for GetJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::DeleteJobRequest ===
    # Fields for DeleteJobRequest
    # Field: name Type: 9 ()
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::ListJobsResponse ===
    # Fields for ListJobsResponse
    # Field: jobs Type: 11 (.google.cloud.video.transcoder.v1.Job)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::CreateJobTemplateRequest ===
    # Fields for CreateJobTemplateRequest
    # Field: parent Type: 9 ()
    # Field: job_template Type: 11 (.google.cloud.video.transcoder.v1.JobTemplate)
    # Field: job_template_id Type: 9 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesRequest ===
    # Fields for ListJobTemplatesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::GetJobTemplateRequest ===
    # Fields for GetJobTemplateRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::DeleteJobTemplateRequest ===
    # Fields for DeleteJobTemplateRequest
    # Field: name Type: 9 ()
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesResponse ===
    # Fields for ListJobTemplatesResponse
    # Field: job_templates Type: 11 (.google.cloud.video.transcoder.v1.JobTemplate)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Service Client: Google::Cloud::Video::Transcoder::V1::Services::TranscoderServiceClient ===
package Google::Cloud::Video::Transcoder::V1::Services::TranscoderServiceClient;

=pod

=head2 Service Client: Google::Cloud::Video::Transcoder::V1::Services::TranscoderServiceClient

Client stub representing the remote C<TranscoderService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<video.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'video.googleapis.com:443' );

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

sub create_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'CreateJob',
        request        => $req,
        response_class => 'Google::Cloud::Video::Transcoder::V1::Resources::Job',
    });
}

sub list_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::ListJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'ListJobs',
        request        => $req,
        response_class => 'Google::Cloud::Video::Transcoder::V1::Services::ListJobsResponse',
    });
}

sub get_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::GetJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'GetJob',
        request        => $req,
        response_class => 'Google::Cloud::Video::Transcoder::V1::Resources::Job',
    });
}

sub delete_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::DeleteJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'DeleteJob',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub create_job_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::CreateJobTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'CreateJobTemplate',
        request        => $req,
        response_class => 'Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate',
    });
}

sub list_job_templates {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'ListJobTemplates',
        request        => $req,
        response_class => 'Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesResponse',
    });
}

sub get_job_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::GetJobTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'GetJobTemplate',
        request        => $req,
        response_class => 'Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate',
    });
}

sub delete_job_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Video::Transcoder::V1::Services::DeleteJobTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.video.transcoder.v1.TranscoderService',
        method         => 'DeleteJobTemplate',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Transcoder::V1::Services - Compiled Protocol Buffers messages for google/cloud/video/transcoder/v1/services.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Transcoder::V1::Services;

    my $msg = Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest->new({
        parent => $parent,
        job => $job,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/transcoder/v1/services.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest

Request message for `TranscoderService.CreateJob`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location to create and process this job.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Video::Transcoder::V1::Resources::Job>)

Required. Parameters for creating transcoding job.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::ListJobsRequest

Request message for `TranscoderService.ListJobs`.
The parent location from which to retrieve the collection of jobs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The `next_page_token` value returned from a previous List request, if
any.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter expression, following the syntax outlined in
https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

One or more fields to compare and use to sort the output.
See https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::GetJobRequest

Request message for `TranscoderService.GetJob`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the job to retrieve.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::DeleteJobRequest

Request message for `TranscoderService.DeleteJob`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the job to delete.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to true, and the job is not found, the request will succeed but no
action will be taken on the server.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::ListJobsResponse

Response message for `TranscoderService.ListJobs`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<Message> (L<Google::Cloud::Video::Transcoder::V1::Resources::Job>)

List of jobs in the specified region.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

List of regions that could not be reached.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::CreateJobTemplateRequest

Request message for `TranscoderService.CreateJobTemplate`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location to create this job template.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->job_template() >> / C<< $msg->job_template($value) >>

Type: C<Message> (L<Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate>)

Required. Parameters for creating job template.

=item * C<< $msg->job_template_id() >> / C<< $msg->job_template_id($value) >>

Type: C<String>

Required. The ID to use for the job template, which will become the final
component of the job template's resource name.

This value should be 4-63 characters, and valid characters must match the
regular expression `[a-zA-Z][a-zA-Z0-9_-]*`.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesRequest

Request message for `TranscoderService.ListJobTemplates`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location from which to retrieve the collection of job
templates. Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The `next_page_token` value returned from a previous List request, if
any.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter expression, following the syntax outlined in
https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

One or more fields to compare and use to sort the output.
See https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::GetJobTemplateRequest

Request message for `TranscoderService.GetJobTemplate`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the job template to retrieve.
Format:
`projects/{project}/locations/{location}/jobTemplates/{job_template}`

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::DeleteJobTemplateRequest

Request message for `TranscoderService.DeleteJobTemplate`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the job template to delete.
`projects/{project}/locations/{location}/jobTemplates/{job_template}`

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to true, and the job template is not found, the request will succeed
but no action will be taken on the server.

=back

=head2 Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesResponse

Response message for `TranscoderService.ListJobTemplates`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_templates() >> / C<< $msg->job_templates($value) >>

Type: C<Message> (L<Google::Cloud::Video::Transcoder::V1::Resources::JobTemplate>)

List of job templates in the specified region.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The pagination token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

List of regions that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Transcoder::V1::Services::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
