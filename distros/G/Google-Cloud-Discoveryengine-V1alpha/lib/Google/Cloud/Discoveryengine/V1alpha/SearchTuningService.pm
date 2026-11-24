package Google::Cloud::Discoveryengine::V1alpha::SearchTuningService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel };
    eval { require Google::Cloud::Discoveryengine::V1alpha::ImportConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2VhcmNoX3R1bmluZ19z
ZXJ2aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdv
b2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGj5nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY3VzdG9tX3R1bmlu
Z19tb2RlbC5wcm90bxo4Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL2lt
cG9ydF9jb25maWcucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5w
cm90byJqChdMaXN0Q3VzdG9tTW9kZWxzUmVxdWVzdBJPCgpkYXRhX3N0b3JlGAEgASgJQjDg
QQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSCWRhdGFT
dG9yZSJrChhMaXN0Q3VzdG9tTW9kZWxzUmVzcG9uc2USTwoGbW9kZWxzGAEgAygLMjcuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkN1c3RvbVR1bmluZ01vZGVsUgZt
b2RlbHMixwQKF1RyYWluQ3VzdG9tTW9kZWxSZXF1ZXN0En4KEmdjc190cmFpbmluZ19pbnB1
dBgCIAEoCzJOLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5UcmFpbkN1
c3RvbU1vZGVsUmVxdWVzdC5HY3NUcmFpbmluZ0lucHV0SABSEGdjc1RyYWluaW5nSW5wdXQS
TwoKZGF0YV9zdG9yZRgBIAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb20vRGF0YVN0b3JlUglkYXRhU3RvcmUSHQoKbW9kZWxfdHlwZRgDIAEoCVIJbW9kZWxU
eXBlEloKDGVycm9yX2NvbmZpZxgEIAEoCzI3Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5JbXBvcnRFcnJvckNvbmZpZ1ILZXJyb3JDb25maWcSGQoIbW9kZWxfaWQY
BSABKAlSB21vZGVsSWQasgEKEEdjc1RyYWluaW5nSW5wdXQSKAoQY29ycHVzX2RhdGFfcGF0
aBgBIAEoCVIOY29ycHVzRGF0YVBhdGgSJgoPcXVlcnlfZGF0YV9wYXRoGAIgASgJUg1xdWVy
eURhdGFQYXRoEiYKD3RyYWluX2RhdGFfcGF0aBgDIAEoCVINdHJhaW5EYXRhUGF0aBIkCg50
ZXN0X2RhdGFfcGF0aBgEIAEoCVIMdGVzdERhdGFQYXRoQhAKDnRyYWluaW5nX2lucHV0IpQD
ChhUcmFpbkN1c3RvbU1vZGVsUmVzcG9uc2USNwoNZXJyb3Jfc2FtcGxlcxgBIAMoCzISLmdv
b2dsZS5ycGMuU3RhdHVzUgxlcnJvclNhbXBsZXMSWgoMZXJyb3JfY29uZmlnGAIgASgLMjcu
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkltcG9ydEVycm9yQ29uZmln
UgtlcnJvckNvbmZpZxIhCgxtb2RlbF9zdGF0dXMYAyABKAlSC21vZGVsU3RhdHVzEmUKB21l
dHJpY3MYBCADKAsySy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuVHJh
aW5DdXN0b21Nb2RlbFJlc3BvbnNlLk1ldHJpY3NFbnRyeVIHbWV0cmljcxIdCgptb2RlbF9u
YW1lGAUgASgJUgltb2RlbE5hbWUaOgoMTWV0cmljc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgBUgV2YWx1ZToCOAEilAEKGFRyYWluQ3VzdG9tTW9kZWxNZXRhZGF0
YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNy
ZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wUgp1cGRhdGVUaW1lMrUFChNTZWFyY2hUdW5pbmdTZXJ2aWNlEtcCChBUcmFpbkN1c3Rv
bU1vZGVsEj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlRyYWluQ3Vz
dG9tTW9kZWxSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLkAYLT5JMC
XSJYL3YxYWxwaGEve2RhdGFfc3RvcmU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2RhdGFTdG9yZXMvKn06dHJhaW5DdXN0b21Nb2RlbDoBKspBfgo9Z29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlRyYWluQ3VzdG9tTW9kZWxSZXNwb25zZRI9
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlRyYWluQ3VzdG9tTW9kZWxN
ZXRhZGF0YRLvAQoQTGlzdEN1c3RvbU1vZGVscxI9Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5MaXN0Q3VzdG9tTW9kZWxzUmVxdWVzdBo+Lmdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0Q3VzdG9tTW9kZWxzUmVzcG9uc2UiXILT5JMC
VhJUL3YxYWxwaGEve2RhdGFfc3RvcmU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2RhdGFTdG9yZXMvKn0vY3VzdG9tTW9kZWxzGlLKQR5kaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3Vk
LXBsYXRmb3JtQqQCCihjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
QhhTZWFyY2hUdW5pbmdTZXJ2aWNlUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNj
b3ZlcnllbmdpbmUvYXBpdjFhbHBoYS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3Zlcnllbmdp
bmVwYqICD0RJU0NPVkVSWUVOR0lORaoCJEdvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUu
VjFBbHBoYcoCJEdvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2ds
ZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFhbHBoYUqeMQoHEgUOAMMBAQq8BAoBDBID
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
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEgKCQoCAwUSAxcAQgoJCgID
BhIDGAAtCgkKAgMHEgMZACkKCQoCAwgSAxoAIQoICgEIEgMcAEEKCQoCCCUSAxwAQQoICgEI
EgMdAGkKCQoCCAsSAx0AaQoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADkKCQoCCAgS
Ax8AOQoICgEIEgMgAEEKCQoCCAESAyAAQQoICgEIEgMhAC0KCQoCCCQSAyEALQoICgEIEgMi
AEEKCQoCCCkSAyIAQQoICgEIEgMjAEAKCQoCCC0SAyMAQAooCgIGABIEJgA/ARocIFNlcnZp
Y2UgZm9yIHNlYXJjaCB0dW5pbmcuCgoKCgMGAAESAyYIGwoKCgMGAAMSAycCRgoMCgUGAAOZ
CBIDJwJGCgsKAwYAAxIEKAIpNwoNCgUGAAOaCBIEKAIpNwomCgQGAAIAEgQsAjYDGhggVHJh
aW5zIGEgY3VzdG9tIG1vZGVsLgoKDAoFBgACAAESAywGFgoMCgUGAAIAAhIDLBcuCgwKBQYA
AgADEgMtDysKDQoFBgACAAQSBC4EMQYKEQoJBgACAASwyrwiEgQuBDEGCg0KBQYAAgAEEgQy
BDUGCg8KBwYAAgAEmQgSBDIENQYKNQoEBgACARIEOQI+AxonIEdldHMgYSBsaXN0IG9mIGFs
bCB0aGUgY3VzdG9tIG1vZGVscy4KCgwKBQYAAgEBEgM5BhYKDAoFBgACAQISAzkXLgoMCgUG
AAIBAxIDOg8nCg0KBQYAAgEEEgQ7BD0GChEKCQYAAgEEsMq8IhIEOwQ9BgqeAQoCBAASBEQA
TwEakQEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NlYXJjaFR1bmluZ1NlcnZpY2UuTGlzdEN1
c3RvbU1vZGVsc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJj
aFR1bmluZ1NlcnZpY2UuTGlzdEN1c3RvbU1vZGVsc10KIG1ldGhvZC4KCgoKAwQAARIDRAgf
CvsBCgQEAAIAEgRJAk4EGuwBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
cGFyZW50IERhdGEgU3RvcmUsIHN1Y2ggYXMKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9i
YWwvY29sbGVjdGlvbnMvZGVmYXVsdF9jb2xsZWN0aW9uL2RhdGFTdG9yZXMvZGVmYXVsdF9k
YXRhX3N0b3JlYC4KIFRoaXMgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUgZGF0YSBz
dG9yZSB3aGVyZSB0byBmZXRjaCB0aGUgbW9kZWxzCiBmcm9tLgoKDAoFBAACAAUSA0kCCAoM
CgUEAAIAARIDSQkTCgwKBQQAAgADEgNJFhcKDQoFBAACAAgSBEkYTgMKDwoIBAACAAicCAAS
A0oEKgoPCgcEAAIACJ8IEgRLBE0FCp8BCgIEARIEVABXARqSASBSZXNwb25zZSBtZXNzYWdl
IGZvcgogW1NlYXJjaFR1bmluZ1NlcnZpY2UuTGlzdEN1c3RvbU1vZGVsc11bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFR1bmluZ1NlcnZpY2UuTGlzdEN1
c3RvbU1vZGVsc10KIG1ldGhvZC4KCgoKAwQBARIDVAggCiwKBAQBAgASA1YCKBofIExpc3Qg
b2YgY3VzdG9tIHR1bmluZyBtb2RlbHMuCgoMCgUEAQIABBIDVgIKCgwKBQQBAgAGEgNWCxwK
DAoFBAECAAESA1YdIwoMCgUEAQIAAxIDViYnCp8BCgIEAhIFXACcAQEakQEgUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1NlYXJjaFR1bmluZ1NlcnZpY2UuVHJhaW5DdXN0b21Nb2RlbF1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFR1bmluZ1NlcnZpY2Uu
VHJhaW5DdXN0b21Nb2RlbF0KIG1ldGhvZC4KCgoKAwQCARIDXAgfCjIKBAQCAwASBF4CfwMa
JCBDbG91ZCBTdG9yYWdlIHRyYWluaW5nIGRhdGEgaW5wdXQuCgoMCgUEAgMAARIDXgoaCtsC
CgYEAgMAAgASA2YEIBrLAiBUaGUgQ2xvdWQgU3RvcmFnZSBjb3JwdXMgZGF0YSB3aGljaCBj
b3VsZCBiZSBhc3NvY2lhdGVkIGluIHRyYWluIGRhdGEuCiBUaGUgZGF0YSBwYXRoIGZvcm1h
dCBpcyBgZ3M6Ly88YnVja2V0X3RvX2RhdGE+Lzxqc29ubF9maWxlX25hbWU+YC4KIEEgbmV3
bGluZSBkZWxpbWl0ZWQganNvbmwvbmRqc29uIGZpbGUuCgogRm9yIHNlYXJjaC10dW5pbmcg
bW9kZWwsIGVhY2ggbGluZSBzaG91bGQgaGF2ZSB0aGUgX2lkLCB0aXRsZQogYW5kIHRleHQu
IEV4YW1wbGU6CiBgeyJfaWQiOiAiZG9jMSIsIHRpdGxlOiAicmVsZXZhbnQgZG9jIiwgInRl
eHQiOiAicmVsZXZhbnQgdGV4dCJ9YAoKDgoHBAIDAAIABRIDZgQKCg4KBwQCAwACAAESA2YL
GwoOCgcEAgMAAgADEgNmHh8KsgIKBgQCAwACARIDbgQfGqICIFRoZSBnY3MgcXVlcnkgZGF0
YSB3aGljaCBjb3VsZCBiZSBhc3NvY2lhdGVkIGluIHRyYWluIGRhdGEuCiBUaGUgZGF0YSBw
YXRoIGZvcm1hdCBpcyBgZ3M6Ly88YnVja2V0X3RvX2RhdGE+Lzxqc29ubF9maWxlX25hbWU+
YC4KIEEgbmV3bGluZSBkZWxpbWl0ZWQganNvbmwvbmRqc29uIGZpbGUuCgogRm9yIHNlYXJj
aC10dW5pbmcgbW9kZWwsIGVhY2ggbGluZSBzaG91bGQgaGF2ZSB0aGUgX2lkCiBhbmQgdGV4
dC4gRXhhbXBsZTogeyJfaWQiOiAicXVlcnkxIiwgICJ0ZXh0IjogImV4YW1wbGUgcXVlcnki
fQoKDgoHBAIDAAIBBRIDbgQKCg4KBwQCAwACAQESA24LGgoOCgcEAgMAAgEDEgNuHR4K2gMK
BgQCAwACAhIDegQfGsoDIENsb3VkIFN0b3JhZ2UgdHJhaW5pbmcgZGF0YSBwYXRoIHdob3Nl
IGZvcm1hdCBzaG91bGQgYmUKIGBnczovLzxidWNrZXRfdG9fZGF0YT4vPHRzdl9maWxlX25h
bWU+YC4gVGhlIGZpbGUgc2hvdWxkIGJlIGluIHRzdgogZm9ybWF0LiBFYWNoIGxpbmUgc2hv
dWxkIGhhdmUgdGhlIGRvY19pZCBhbmQgcXVlcnlfaWQgYW5kIHNjb3JlIChudW1iZXIpLgoK
IEZvciBzZWFyY2gtdHVuaW5nIG1vZGVsLCBpdCBzaG91bGQgaGF2ZSB0aGUgcXVlcnktaWQg
Y29ycHVzLWlkCiBzY29yZSBhcyB0c3YgZmlsZSBoZWFkZXIuIFRoZSBzY29yZSBzaG91bGQg
YmUgYSBudW1iZXIgaW4gYFswLCBpbmYrKWAuCiBUaGUgbGFyZ2VyIHRoZSBudW1iZXIgaXMs
IHRoZSBtb3JlIHJlbGV2YW50IHRoZSBwYWlyIGlzLiBFeGFtcGxlOgoKICogYHF1ZXJ5LWlk
XHRjb3JwdXMtaWRcdHNjb3JlYAogKiBgcXVlcnkxXHRkb2MxXHQxYAoKDgoHBAIDAAICBRID
egQKCg4KBwQCAwACAgESA3oLGgoOCgcEAgMAAgIDEgN6HR4KogEKBgQCAwACAxIDfgQeGpIB
IENsb3VkIFN0b3JhZ2UgdGVzdCBkYXRhLiBTYW1lIGZvcm1hdCBhcyB0cmFpbl9kYXRhX3Bh
dGguIElmIG5vdCBwcm92aWRlZCwKIGEgcmFuZG9tIDgwLzIwIHRyYWluL3Rlc3Qgc3BsaXQg
d2lsbCBiZSBwZXJmb3JtZWQgb24gdHJhaW5fZGF0YV9wYXRoLgoKDgoHBAIDAAIDBRIDfgQK
Cg4KBwQCAwACAwESA34LGQoOCgcEAgMAAgMDEgN+HB0KJwoEBAIIABIGggEChQEDGhcgTW9k
ZWwgdHJhaW5pbmcgaW5wdXQuCgoNCgUEAggAARIEggEIFgotCgQEAgIAEgSEAQQsGh8gQ2xv
dWQgU3RvcmFnZSB0cmFpbmluZyBpbnB1dC4KCg0KBQQCAgAGEgSEAQQUCg0KBQQCAgABEgSE
ARUnCg0KBQQCAgADEgSEASorCvABCgQEAgIBEgaKAQKPAQQa3wEgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBEYXRhIFN0b3JlLCBzdWNoIGFzCiBgcHJvamVjdHMvKi9s
b2NhdGlvbnMvZ2xvYmFsL2NvbGxlY3Rpb25zL2RlZmF1bHRfY29sbGVjdGlvbi9kYXRhU3Rv
cmVzL2RlZmF1bHRfZGF0YV9zdG9yZWAuCiBUaGlzIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRp
ZnkgdGhlIGRhdGEgc3RvcmUgd2hlcmUgdG8gdHJhaW4gdGhlIG1vZGVscy4KCg0KBQQCAgEF
EgSKAQIICg0KBQQCAgEBEgSKAQkTCg0KBQQCAgEDEgSKARYXCg8KBQQCAgEIEgaKARiPAQMK
EAoIBAICAQicCAASBIsBBCoKEQoHBAICAQifCBIGjAEEjgEFCogBCgQEAgICEgSUAQIYGnog
TW9kZWwgdG8gYmUgdHJhaW5lZC4gU3VwcG9ydGVkIHZhbHVlcyBhcmU6CgogICogKipzZWFy
Y2gtdHVuaW5nKio6IEZpbmUgdHVuaW5nIHRoZSBzZWFyY2ggc3lzdGVtIGJhc2VkIG9uIGRh
dGEgcHJvdmlkZWQuCgoNCgUEAgICBRIElAECCAoNCgUEAgICARIElAEJEwoNCgUEAgICAxIE
lAEWFwpgCgQEAgIDEgSYAQIlGlIgVGhlIGRlc2lyZWQgbG9jYXRpb24gb2YgZXJyb3JzIGlu
Y3VycmVkIGR1cmluZyB0aGUgZGF0YSBpbmdlc3Rpb24gYW5kCiB0cmFpbmluZy4KCg0KBQQC
AgMGEgSYAQITCg0KBQQCAgMBEgSYARQgCg0KBQQCAgMDEgSYASMkCjoKBAQCAgQSBJsBAhYa
LCBJZiBub3QgcHJvdmlkZWQsIGEgVVVJRCB3aWxsIGJlIGdlbmVyYXRlZC4KCg0KBQQCAgQF
EgSbAQIICg0KBQQCAgQBEgSbAQkRCg0KBQQCAgQDEgSbARQVCskBCgIEAxIGoQEAuAEBGroB
IFJlc3BvbnNlIG9mIHRoZQogW1RyYWluQ3VzdG9tTW9kZWxSZXF1ZXN0XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuVHJhaW5DdXN0b21Nb2RlbFJlcXVlc3RdLgog
VGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9ucy5yZXNwb25zZSBmaWVsZC4KCgsKAwQDARIEoQEIIApJCgQEAwIAEgSjAQIvGjsg
QSBzYW1wbGUgb2YgZXJyb3JzIGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3NpbmcgdGhlIGRh
dGEuCgoNCgUEAwIABBIEowECCgoNCgUEAwIABhIEowELHAoNCgUEAwIAARIEowEdKgoNCgUE
AwIAAxIEowEtLgpVCgQEAwIBEgSmAQIlGkcgRWNob2VzIHRoZSBkZXN0aW5hdGlvbiBmb3Ig
dGhlIGNvbXBsZXRlIGVycm9ycyBpbiB0aGUgcmVxdWVzdCBpZiBzZXQuCgoNCgUEAwIBBhIE
pgECEwoNCgUEAwIBARIEpgEUIAoNCgUEAwIBAxIEpgEjJArSAwoEBAMCAhIEsQECGhrDAyBU
aGUgdHJhaW5lZCBtb2RlbCBzdGF0dXMuIFBvc3NpYmxlIHZhbHVlcyBhcmU6CgogICogKipi
YWQtZGF0YSoqOiBUaGUgdHJhaW5pbmcgZGF0YSBxdWFsaXR5IGlzIGJhZC4KICAqICoqbm8t
aW1wcm92ZW1lbnQqKjogVHVuaW5nIGRpZG4ndCBpbXByb3ZlIHBlcmZvcm1hbmNlLiBXb24n
dCBkZXBsb3kuCiAgKiAqKmluLXByb2dyZXNzKio6IE1vZGVsIHRyYWluaW5nIGpvYiBjcmVh
dGlvbiBpcyBpbiBwcm9ncmVzcy4KICAqICoqdHJhaW5pbmcqKjogTW9kZWwgaXMgYWN0aXZl
bHkgdHJhaW5pbmcuCiAgKiAqKmV2YWx1YXRpbmcqKjogVGhlIG1vZGVsIGlzIGV2YWx1YXRp
bmcgdHJhaW5lZCBtZXRyaWNzLgogICogKippbmRleGluZyoqOiBUaGUgbW9kZWwgdHJhaW5l
ZCBtZXRyaWNzIGFyZSBpbmRleGluZy4KICAqICoqcmVhZHkqKjogVGhlIG1vZGVsIGlzIHJl
YWR5IGZvciBzZXJ2aW5nLgoKDQoFBAMCAgUSBLEBAggKDQoFBAMCAgESBLEBCRUKDQoFBAMC
AgMSBLEBGBkKMQoEBAMCAxIEtAECIhojIFRoZSBtZXRyaWNzIG9mIHRoZSB0cmFpbmVkIG1v
ZGVsLgoKDQoFBAMCAwYSBLQBAhUKDQoFBAMCAwESBLQBFh0KDQoFBAMCAwMSBLQBICEKPgoE
BAMCBBIEtwECGBowIEZ1bGx5IHF1YWxpZmllZCBuYW1lIG9mIHRoZSBDdXN0b21UdW5pbmdN
b2RlbC4KCg0KBQQDAgQFEgS3AQIICg0KBQQDAgQBEgS3AQkTCg0KBQQDAgQDEgS3ARYXCpoB
CgIEBBIGvAEAwwEBGosBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRo
ZSBUcmFpbkN1c3RvbU1vZGVsIG9wZXJhdGlvbi4gVGhpcyBpcwogcmV0dXJuZWQgYnkgdGhl
IGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEgZmllbGQuCgoLCgMEBAES
BLwBCCAKJgoEBAQCABIEvgECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQEAgAG
EgS+AQIbCg0KBQQEAgABEgS+ARwnCg0KBQQEAgADEgS+ASorCmQKBAQEAgESBMIBAiwaViBP
cGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0
aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQEAgEGEgTCAQIbCg0KBQQEAgEB
EgTCARwnCg0KBQQEAgEDEgTCASorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsRequest ===
    # Fields for ListCustomModelsRequest
    # Field: data_store Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsResponse ===
    # Fields for ListCustomModelsResponse
    # Field: models Type: 11 (.google.cloud.discoveryengine.v1alpha.CustomTuningModel)

# === Message: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest ===
    # Fields for TrainCustomModelRequest
    # Field: gcs_training_input Type: 11 (.google.cloud.discoveryengine.v1alpha.TrainCustomModelRequest.GcsTrainingInput)
    # Field: data_store Type: 9 ()
    # Field: model_type Type: 9 ()
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1alpha.ImportErrorConfig)
    # Field: model_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelResponse ===
    # Fields for TrainCustomModelResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1alpha.ImportErrorConfig)
    # Field: model_status Type: 9 ()
    # Field: metrics Type: 11 (.google.cloud.discoveryengine.v1alpha.TrainCustomModelResponse.MetricsEntry)
    # Field: model_name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelMetadata ===
    # Fields for TrainCustomModelMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::SearchTuningServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::SearchTuningServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::SearchTuningServiceClient

Client stub representing the remote C<SearchTuningService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub train_custom_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SearchTuningService',
        method         => 'TrainCustomModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_custom_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SearchTuningService',
        method         => 'ListCustomModels',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SearchTuningService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/search_tuning_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SearchTuningService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsRequest->new({
        data_store => $data_store,
    });

    # Read or update a field
    my $val = $msg->data_store();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/search_tuning_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsRequest

Request message for
[SearchTuningService.ListCustomModels][google.cloud.discoveryengine.v1alpha.SearchTuningService.ListCustomModels]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The resource name of the parent Data Store, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.
This field is used to identify the data store where to fetch the models
from.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::ListCustomModelsResponse

Response message for
[SearchTuningService.ListCustomModels][google.cloud.discoveryengine.v1alpha.SearchTuningService.ListCustomModels]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::CustomTuningModel>)

List of custom tuning models.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest

Request message for
[SearchTuningService.TrainCustomModel][google.cloud.discoveryengine.v1alpha.SearchTuningService.TrainCustomModel]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_training_input() >> / C<< $msg->gcs_training_input($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest::GcsTrainingInput>)

Cloud Storage training input.

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The resource name of the Data Store, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.
This field is used to identify the data store where to train the models.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Model to be trained. Supported values are:

 * B<search-tuning>: Fine tuning the search system based on data provided.

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportErrorConfig>)

The desired location of errors incurred during the data ingestion and
training.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

If not provided, a UUID will be generated.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelResponse

Response of the
[TrainCustomModelRequest][google.cloud.discoveryengine.v1alpha.TrainCustomModelRequest].
This message is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the data.

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportErrorConfig>)

Echoes the destination for the complete errors in the request if set.

=item * C<< $msg->model_status() >> / C<< $msg->model_status($value) >>

Type: C<String>

The trained model status. Possible values are:

 * B<bad-data>: The training data quality is bad.
 * B<no-improvement>: Tuning didn't improve performance. Won't deploy.
 * B<in-progress>: Model training job creation is in progress.
 * B<training>: Model is actively training.
 * B<evaluating>: The model is evaluating trained metrics.
 * B<indexing>: The model trained metrics are indexing.
 * B<ready>: The model is ready for serving.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelResponse::MetricsEntry>)

The metrics of the trained model.

=item * C<< $msg->model_name() >> / C<< $msg->model_name($value) >>

Type: C<String>

Fully qualified name of the CustomTuningModel.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelMetadata

Metadata related to the progress of the TrainCustomModel operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
