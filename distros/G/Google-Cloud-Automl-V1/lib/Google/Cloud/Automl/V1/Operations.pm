package Google::Cloud::Automl::V1::Operations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1::Io };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXV0b21sL3YxL29wZXJhdGlvbnMucHJvdG8SFmdvb2dsZS5jbG91
ZC5hdXRvbWwudjEaH2dvb2dsZS9jbG91ZC9hdXRvbWwvdjEvaW8ucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIrUJChFP
cGVyYXRpb25NZXRhZGF0YRJYCg5kZWxldGVfZGV0YWlscxgIIAEoCzIvLmdvb2dsZS5jbG91
ZC5hdXRvbWwudjEuRGVsZXRlT3BlcmF0aW9uTWV0YWRhdGFIAFINZGVsZXRlRGV0YWlscxJo
ChRkZXBsb3lfbW9kZWxfZGV0YWlscxgYIAEoCzI0Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjEu
RGVwbG95TW9kZWxPcGVyYXRpb25NZXRhZGF0YUgAUhJkZXBsb3lNb2RlbERldGFpbHMSbgoW
dW5kZXBsb3lfbW9kZWxfZGV0YWlscxgZIAEoCzI2Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjEu
VW5kZXBsb3lNb2RlbE9wZXJhdGlvbk1ldGFkYXRhSABSFHVuZGVwbG95TW9kZWxEZXRhaWxz
EmgKFGNyZWF0ZV9tb2RlbF9kZXRhaWxzGAogASgLMjQuZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MS5DcmVhdGVNb2RlbE9wZXJhdGlvbk1ldGFkYXRhSABSEmNyZWF0ZU1vZGVsRGV0YWlscxJu
ChZjcmVhdGVfZGF0YXNldF9kZXRhaWxzGB4gASgLMjYuZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MS5DcmVhdGVEYXRhc2V0T3BlcmF0aW9uTWV0YWRhdGFIAFIUY3JlYXRlRGF0YXNldERldGFp
bHMSZQoTaW1wb3J0X2RhdGFfZGV0YWlscxgPIAEoCzIzLmdvb2dsZS5jbG91ZC5hdXRvbWwu
djEuSW1wb3J0RGF0YU9wZXJhdGlvbk1ldGFkYXRhSABSEWltcG9ydERhdGFEZXRhaWxzEmsK
FWJhdGNoX3ByZWRpY3RfZGV0YWlscxgQIAEoCzI1Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjEu
QmF0Y2hQcmVkaWN0T3BlcmF0aW9uTWV0YWRhdGFIAFITYmF0Y2hQcmVkaWN0RGV0YWlscxJl
ChNleHBvcnRfZGF0YV9kZXRhaWxzGBUgASgLMjMuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5F
eHBvcnREYXRhT3BlcmF0aW9uTWV0YWRhdGFIAFIRZXhwb3J0RGF0YURldGFpbHMSaAoUZXhw
b3J0X21vZGVsX2RldGFpbHMYFiABKAsyNC5nb29nbGUuY2xvdWQuYXV0b21sLnYxLkV4cG9y
dE1vZGVsT3BlcmF0aW9uTWV0YWRhdGFIAFISZXhwb3J0TW9kZWxEZXRhaWxzEikKEHByb2dy
ZXNzX3BlcmNlbnQYDSABKAVSD3Byb2dyZXNzUGVyY2VudBI9ChBwYXJ0aWFsX2ZhaWx1cmVz
GAIgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSD3BhcnRpYWxGYWlsdXJlcxI7CgtjcmVhdGVf
dGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoL
dXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVU
aW1lQgkKB2RldGFpbHMiGQoXRGVsZXRlT3BlcmF0aW9uTWV0YWRhdGEiHgocRGVwbG95TW9k
ZWxPcGVyYXRpb25NZXRhZGF0YSIgCh5VbmRlcGxveU1vZGVsT3BlcmF0aW9uTWV0YWRhdGEi
IAoeQ3JlYXRlRGF0YXNldE9wZXJhdGlvbk1ldGFkYXRhIh4KHENyZWF0ZU1vZGVsT3BlcmF0
aW9uTWV0YWRhdGEiHQobSW1wb3J0RGF0YU9wZXJhdGlvbk1ldGFkYXRhIucBChtFeHBvcnRE
YXRhT3BlcmF0aW9uTWV0YWRhdGESaQoLb3V0cHV0X2luZm8YASABKAsySC5nb29nbGUuY2xv
dWQuYXV0b21sLnYxLkV4cG9ydERhdGFPcGVyYXRpb25NZXRhZGF0YS5FeHBvcnREYXRhT3V0
cHV0SW5mb1IKb3V0cHV0SW5mbxpdChRFeHBvcnREYXRhT3V0cHV0SW5mbxIyChRnY3Nfb3V0
cHV0X2RpcmVjdG9yeRgBIAEoCUgAUhJnY3NPdXRwdXREaXJlY3RvcnlCEQoPb3V0cHV0X2xv
Y2F0aW9uIsMCCh1CYXRjaFByZWRpY3RPcGVyYXRpb25NZXRhZGF0YRJSCgxpbnB1dF9jb25m
aWcYASABKAsyLy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLkJhdGNoUHJlZGljdElucHV0Q29u
ZmlnUgtpbnB1dENvbmZpZxJtCgtvdXRwdXRfaW5mbxgCIAEoCzJMLmdvb2dsZS5jbG91ZC5h
dXRvbWwudjEuQmF0Y2hQcmVkaWN0T3BlcmF0aW9uTWV0YWRhdGEuQmF0Y2hQcmVkaWN0T3V0
cHV0SW5mb1IKb3V0cHV0SW5mbxpfChZCYXRjaFByZWRpY3RPdXRwdXRJbmZvEjIKFGdjc19v
dXRwdXRfZGlyZWN0b3J5GAEgASgJSABSEmdjc091dHB1dERpcmVjdG9yeUIRCg9vdXRwdXRf
bG9jYXRpb24i1gEKHEV4cG9ydE1vZGVsT3BlcmF0aW9uTWV0YWRhdGESawoLb3V0cHV0X2lu
Zm8YAiABKAsySi5nb29nbGUuY2xvdWQuYXV0b21sLnYxLkV4cG9ydE1vZGVsT3BlcmF0aW9u
TWV0YWRhdGEuRXhwb3J0TW9kZWxPdXRwdXRJbmZvUgpvdXRwdXRJbmZvGkkKFUV4cG9ydE1v
ZGVsT3V0cHV0SW5mbxIwChRnY3Nfb3V0cHV0X2RpcmVjdG9yeRgBIAEoCVISZ2NzT3V0cHV0
RGlyZWN0b3J5QqABChpjb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MVABWjJjbG91ZC5nb29n
bGUuY29tL2dvL2F1dG9tbC9hcGl2MS9hdXRvbWxwYjthdXRvbWxwYqoCFkdvb2dsZS5DbG91
ZC5BdXRvTUwuVjHKAhZHb29nbGVcQ2xvdWRcQXV0b01sXFYx6gIZR29vZ2xlOjpDbG91ZDo6
QXV0b01MOjpWMUrdJQoHEgUOAKMBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
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
ZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTACkKCQoCAwISAxQAIQoICgEIEgMW
ADMKCQoCCCUSAxYAMwoICgEIEgMXAEkKCQoCCAsSAxcASQoICgEIEgMYACIKCQoCCAoSAxgA
IgoICgEIEgMZADMKCQoCCAESAxkAMwoICgEIEgMaADMKCQoCCCkSAxoAMwoICgEIEgMbADIK
CQoCCC0SAxsAMgpWCgIEABIEHgBNARpKIE1ldGFkYXRhIHVzZWQgYWNyb3NzIGFsbCBsb25n
IHJ1bm5pbmcgb3BlcmF0aW9ucyByZXR1cm5lZCBieSBBdXRvTUwgQVBJLgoKCgoDBAABEgMe
CBkKnAEKBAQACAASBCECPAMajQEgT3VwdHV0IG9ubHkuIERldGFpbHMgb2Ygc3BlY2lmaWMg
b3BlcmF0aW9uLiBFdmVuIGlmIHRoaXMgZmllbGQgaXMgZW1wdHksCiB0aGUgcHJlc2VuY2Ug
YWxsb3dzIHRvIGRpc3Rpbmd1aXNoIGRpZmZlcmVudCB0eXBlcyBvZiBvcGVyYXRpb25zLgoK
DAoFBAAIAAESAyEIDwotCgQEAAIAEgMjBC8aICBEZXRhaWxzIG9mIGEgRGVsZXRlIG9wZXJh
dGlvbi4KCgwKBQQAAgAGEgMjBBsKDAoFBAACAAESAyMcKgoMCgUEAAIAAxIDIy0uCjIKBAQA
AgESAyYEOxolIERldGFpbHMgb2YgYSBEZXBsb3lNb2RlbCBvcGVyYXRpb24uCgoMCgUEAAIB
BhIDJgQgCgwKBQQAAgEBEgMmITUKDAoFBAACAQMSAyY4Ogo1CgQEAAICEgMpBD8aKCBEZXRh
aWxzIG9mIGFuIFVuZGVwbG95TW9kZWwgb3BlcmF0aW9uLgoKDAoFBAACAgYSAykEIgoMCgUE
AAICARIDKSM5CgwKBQQAAgIDEgMpPD4KMAoEBAACAxIDLAQ7GiMgRGV0YWlscyBvZiBDcmVh
dGVNb2RlbCBvcGVyYXRpb24uCgoMCgUEAAIDBhIDLAQgCgwKBQQAAgMBEgMsITUKDAoFBAAC
AwMSAyw4OgoyCgQEAAIEEgMvBD8aJSBEZXRhaWxzIG9mIENyZWF0ZURhdGFzZXQgb3BlcmF0
aW9uLgoKDAoFBAACBAYSAy8EIgoMCgUEAAIEARIDLyM5CgwKBQQAAgQDEgMvPD4KLwoEBAAC
BRIDMgQ5GiIgRGV0YWlscyBvZiBJbXBvcnREYXRhIG9wZXJhdGlvbi4KCgwKBQQAAgUGEgMy
BB8KDAoFBAACBQESAzIgMwoMCgUEAAIFAxIDMjY4CjEKBAQAAgYSAzUEPRokIERldGFpbHMg
b2YgQmF0Y2hQcmVkaWN0IG9wZXJhdGlvbi4KCgwKBQQAAgYGEgM1BCEKDAoFBAACBgESAzUi
NwoMCgUEAAIGAxIDNTo8Ci8KBAQAAgcSAzgEORoiIERldGFpbHMgb2YgRXhwb3J0RGF0YSBv
cGVyYXRpb24uCgoMCgUEAAIHBhIDOAQfCgwKBQQAAgcBEgM4IDMKDAoFBAACBwMSAzg2OAow
CgQEAAIIEgM7BDsaIyBEZXRhaWxzIG9mIEV4cG9ydE1vZGVsIG9wZXJhdGlvbi4KCgwKBQQA
AggGEgM7BCAKDAoFBAACCAESAzshNQoMCgUEAAIIAxIDOzg6ClgKBAQAAgkSA0ACHhpLIE91
dHB1dCBvbmx5LiBQcm9ncmVzcyBvZiBvcGVyYXRpb24uIFJhbmdlOiBbMCwgMTAwXS4KIE5v
dCB1c2VkIGN1cnJlbnRseS4KCgwKBQQAAgkFEgNAAgcKDAoFBAACCQESA0AIGAoMCgUEAAIJ
AxIDQBsdCs8BCgQEAAIKEgNGAjIawQEgT3V0cHV0IG9ubHkuIFBhcnRpYWwgZmFpbHVyZXMg
ZW5jb3VudGVyZWQuCiBFLmcuIHNpbmdsZSBmaWxlcyB0aGF0IGNvdWxkbid0IGJlIHJlYWQu
CiBUaGlzIGZpZWxkIHNob3VsZCBuZXZlciBleGNlZWQgMjAgZW50cmllcy4KIFN0YXR1cyBk
ZXRhaWxzIGZpZWxkIHdpbGwgY29udGFpbiBzdGFuZGFyZCBHQ1AgZXJyb3IgZGV0YWlscy4K
CgwKBQQAAgoEEgNGAgoKDAoFBAACCgYSA0YLHAoMCgUEAAIKARIDRh0tCgwKBQQAAgoDEgNG
MDEKQAoEBAACCxIDSQIsGjMgT3V0cHV0IG9ubHkuIFRpbWUgd2hlbiB0aGUgb3BlcmF0aW9u
IHdhcyBjcmVhdGVkLgoKDAoFBAACCwYSA0kCGwoMCgUEAAILARIDSRwnCgwKBQQAAgsDEgNJ
KisKUgoEBAACDBIDTAIsGkUgT3V0cHV0IG9ubHkuIFRpbWUgd2hlbiB0aGUgb3BlcmF0aW9u
IHdhcyB1cGRhdGVkIGZvciB0aGUgbGFzdCB0aW1lLgoKDAoFBAACDAYSA0wCGwoMCgUEAAIM
ARIDTBwnCgwKBQQAAgwDEgNMKisKSQoCBAESBFAAUgEaPSBEZXRhaWxzIG9mIG9wZXJhdGlv
bnMgdGhhdCBwZXJmb3JtIGRlbGV0ZXMgb2YgYW55IGVudGl0aWVzLgoKCgoDBAEBEgNQCB8K
LwoCBAISBFUAVwEaIyBEZXRhaWxzIG9mIERlcGxveU1vZGVsIG9wZXJhdGlvbi4KCgoKAwQC
ARIDVQgkCjEKAgQDEgRaAFwBGiUgRGV0YWlscyBvZiBVbmRlcGxveU1vZGVsIG9wZXJhdGlv
bi4KCgoKAwQDARIDWggmCjEKAgQEEgRfAGEBGiUgRGV0YWlscyBvZiBDcmVhdGVEYXRhc2V0
IG9wZXJhdGlvbi4KCgoKAwQEARIDXwgmCi8KAgQFEgRkAGYBGiMgRGV0YWlscyBvZiBDcmVh
dGVNb2RlbCBvcGVyYXRpb24uCgoKCgMEBQESA2QIJAouCgIEBhIEaQBrARoiIERldGFpbHMg
b2YgSW1wb3J0RGF0YSBvcGVyYXRpb24uCgoKCgMEBgESA2kIIwouCgIEBxIEbgB9ARoiIERl
dGFpbHMgb2YgRXhwb3J0RGF0YSBvcGVyYXRpb24uCgoKCgMEBwESA24IIwp/CgQEBwMAEgRy
AnkDGnEgRnVydGhlciBkZXNjcmliZXMgdGhpcyBleHBvcnQgZGF0YSdzIG91dHB1dC4KIFN1
cHBsZW1lbnRzCiBbT3V0cHV0Q29uZmlnXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLk91dHB1
dENvbmZpZ10uCgoMCgUEBwMAARIDcgoeCkwKBgQHAwAIABIEdAR4BRo8IFRoZSBvdXRwdXQg
bG9jYXRpb24gdG8gd2hpY2ggdGhlIGV4cG9ydGVkIGRhdGEgaXMgd3JpdHRlbi4KCg4KBwQH
AwAIAAESA3QKGQp3CgYEBwMAAgASA3cGJhpoIFRoZSBmdWxsIHBhdGggb2YgdGhlIEdvb2ds
ZSBDbG91ZCBTdG9yYWdlIGRpcmVjdG9yeSBjcmVhdGVkLCBpbnRvIHdoaWNoCiB0aGUgZXhw
b3J0ZWQgZGF0YSBpcyB3cml0dGVuLgoKDgoHBAcDAAIABRIDdwYMCg4KBwQHAwACAAESA3cN
IQoOCgcEBwMAAgADEgN3JCUKVQoEBAcCABIDfAInGkggT3V0cHV0IG9ubHkuIEluZm9ybWF0
aW9uIGZ1cnRoZXIgZGVzY3JpYmluZyB0aGlzIGV4cG9ydCBkYXRhJ3Mgb3V0cHV0LgoKDAoF
BAcCAAYSA3wCFgoMCgUEBwIAARIDfBciCgwKBQQHAgADEgN8JSYKMgoCBAgSBoABAJMBARok
IERldGFpbHMgb2YgQmF0Y2hQcmVkaWN0IG9wZXJhdGlvbi4KCgsKAwQIARIEgAEIJQqcAQoE
BAgDABIGhAECiwEDGosBIEZ1cnRoZXIgZGVzY3JpYmVzIHRoaXMgYmF0Y2ggcHJlZGljdCdz
IG91dHB1dC4KIFN1cHBsZW1lbnRzCiBbQmF0Y2hQcmVkaWN0T3V0cHV0Q29uZmlnXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxLkJhdGNoUHJlZGljdE91dHB1dENvbmZpZ10uCgoNCgUECAMA
ARIEhAEKIApQCgYECAMACAASBoYBBIoBBRo+IFRoZSBvdXRwdXQgbG9jYXRpb24gaW50byB3
aGljaCBwcmVkaWN0aW9uIG91dHB1dCBpcyB3cml0dGVuLgoKDwoHBAgDAAgAARIEhgEKGQp8
CgYECAMAAgASBIkBBiYabCBUaGUgZnVsbCBwYXRoIG9mIHRoZSBHb29nbGUgQ2xvdWQgU3Rv
cmFnZSBkaXJlY3RvcnkgY3JlYXRlZCwgaW50byB3aGljaAogdGhlIHByZWRpY3Rpb24gb3V0
cHV0IGlzIHdyaXR0ZW4uCgoPCgcECAMAAgAFEgSJAQYMCg8KBwQIAwACAAESBIkBDSEKDwoH
BAgDAAIAAxIEiQEkJQppCgQECAIAEgSPAQIrGlsgT3V0cHV0IG9ubHkuIFRoZSBpbnB1dCBj
b25maWcgdGhhdCB3YXMgZ2l2ZW4gdXBvbiBzdGFydGluZyB0aGlzCiBiYXRjaCBwcmVkaWN0
IG9wZXJhdGlvbi4KCg0KBQQIAgAGEgSPAQIZCg0KBQQIAgABEgSPARomCg0KBQQIAgADEgSP
ASkqClgKBAQIAgESBJIBAikaSiBPdXRwdXQgb25seS4gSW5mb3JtYXRpb24gZnVydGhlciBk
ZXNjcmliaW5nIHRoaXMgYmF0Y2ggcHJlZGljdCdzIG91dHB1dC4KCg0KBQQIAgEGEgSSAQIY
Cg0KBQQIAgEBEgSSARkkCg0KBQQIAgEDEgSSAScoCjEKAgQJEgaWAQCjAQEaIyBEZXRhaWxz
IG9mIEV4cG9ydE1vZGVsIG9wZXJhdGlvbi4KCgsKAwQJARIElgEIJAqZAQoEBAkDABIGmgEC
ngEDGogBIEZ1cnRoZXIgZGVzY3JpYmVzIHRoZSBvdXRwdXQgb2YgbW9kZWwgZXhwb3J0Lgog
U3VwcGxlbWVudHMKIFtNb2RlbEV4cG9ydE91dHB1dENvbmZpZ11bZ29vZ2xlLmNsb3VkLmF1
dG9tbC52MS5Nb2RlbEV4cG9ydE91dHB1dENvbmZpZ10uCgoNCgUECQMAARIEmgEKHwp2CgYE
CQMAAgASBJ0BBCQaZiBUaGUgZnVsbCBwYXRoIG9mIHRoZSBHb29nbGUgQ2xvdWQgU3RvcmFn
ZSBkaXJlY3RvcnkgY3JlYXRlZCwgaW50byB3aGljaAogdGhlIG1vZGVsIHdpbGwgYmUgZXhw
b3J0ZWQuCgoPCgcECQMAAgAFEgSdAQQKCg8KBwQJAwACAAESBJ0BCx8KDwoHBAkDAAIAAxIE
nQEiIwpdCgQECQIAEgSiAQIoGk8gT3V0cHV0IG9ubHkuIEluZm9ybWF0aW9uIGZ1cnRoZXIg
ZGVzY3JpYmluZyB0aGUgb3V0cHV0IG9mIHRoaXMgbW9kZWwKIGV4cG9ydC4KCg0KBQQJAgAG
EgSiAQIXCg0KBQQJAgABEgSiARgjCg0KBQQJAgADEgSiASYnYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Operations::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: delete_details Type: 11 (.google.cloud.automl.v1.DeleteOperationMetadata)
    # Field: deploy_model_details Type: 11 (.google.cloud.automl.v1.DeployModelOperationMetadata)
    # Field: undeploy_model_details Type: 11 (.google.cloud.automl.v1.UndeployModelOperationMetadata)
    # Field: create_model_details Type: 11 (.google.cloud.automl.v1.CreateModelOperationMetadata)
    # Field: create_dataset_details Type: 11 (.google.cloud.automl.v1.CreateDatasetOperationMetadata)
    # Field: import_data_details Type: 11 (.google.cloud.automl.v1.ImportDataOperationMetadata)
    # Field: batch_predict_details Type: 11 (.google.cloud.automl.v1.BatchPredictOperationMetadata)
    # Field: export_data_details Type: 11 (.google.cloud.automl.v1.ExportDataOperationMetadata)
    # Field: export_model_details Type: 11 (.google.cloud.automl.v1.ExportModelOperationMetadata)
    # Field: progress_percent Type: 5 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Automl::V1::Operations::DeleteOperationMetadata ===
    # Fields for DeleteOperationMetadata

# === Message: Google::Cloud::Automl::V1::Operations::DeployModelOperationMetadata ===
    # Fields for DeployModelOperationMetadata

# === Message: Google::Cloud::Automl::V1::Operations::UndeployModelOperationMetadata ===
    # Fields for UndeployModelOperationMetadata

# === Message: Google::Cloud::Automl::V1::Operations::CreateDatasetOperationMetadata ===
    # Fields for CreateDatasetOperationMetadata

# === Message: Google::Cloud::Automl::V1::Operations::CreateModelOperationMetadata ===
    # Fields for CreateModelOperationMetadata

# === Message: Google::Cloud::Automl::V1::Operations::ImportDataOperationMetadata ===
    # Fields for ImportDataOperationMetadata

# === Message: Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata ===
    # Fields for ExportDataOperationMetadata
    # Field: output_info Type: 11 (.google.cloud.automl.v1.ExportDataOperationMetadata.ExportDataOutputInfo)

# === Message: Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata ===
    # Fields for BatchPredictOperationMetadata
    # Field: input_config Type: 11 (.google.cloud.automl.v1.BatchPredictInputConfig)
    # Field: output_info Type: 11 (.google.cloud.automl.v1.BatchPredictOperationMetadata.BatchPredictOutputInfo)

# === Message: Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata ===
    # Fields for ExportModelOperationMetadata
    # Field: output_info Type: 11 (.google.cloud.automl.v1.ExportModelOperationMetadata.ExportModelOutputInfo)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Operations - Compiled Protocol Buffers messages for google/cloud/automl/v1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Operations;

    my $msg = Google::Cloud::Automl::V1::Operations::OperationMetadata->new({
        delete_details => $delete_details,
        deploy_model_details => $deploy_model_details,
        undeploy_model_details => $undeploy_model_details,
        create_model_details => $create_model_details,
    });

    # Read or update a field
    my $val = $msg->delete_details();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Operations::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Operations::OperationMetadata

Metadata used across all long running operations returned by AutoML API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->delete_details() >> / C<< $msg->delete_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::DeleteOperationMetadata>)

Details of a Delete operation.

=item * C<< $msg->deploy_model_details() >> / C<< $msg->deploy_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::DeployModelOperationMetadata>)

Details of a DeployModel operation.

=item * C<< $msg->undeploy_model_details() >> / C<< $msg->undeploy_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::UndeployModelOperationMetadata>)

Details of an UndeployModel operation.

=item * C<< $msg->create_model_details() >> / C<< $msg->create_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::CreateModelOperationMetadata>)

Details of CreateModel operation.

=item * C<< $msg->create_dataset_details() >> / C<< $msg->create_dataset_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::CreateDatasetOperationMetadata>)

Details of CreateDataset operation.

=item * C<< $msg->import_data_details() >> / C<< $msg->import_data_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::ImportDataOperationMetadata>)

Details of ImportData operation.

=item * C<< $msg->batch_predict_details() >> / C<< $msg->batch_predict_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata>)

Details of BatchPredict operation.

=item * C<< $msg->export_data_details() >> / C<< $msg->export_data_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata>)

Details of ExportData operation.

=item * C<< $msg->export_model_details() >> / C<< $msg->export_model_details($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata>)

Details of ExportModel operation.

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Output only. Progress of operation. Range: [0, 100].
Not used currently.

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Partial failures encountered.
E.g. single files that couldn't be read.
This field should never exceed 20 entries.
Status details field will contain standard GCP error details.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the operation was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the operation was updated for the last time.

=back

=head2 Google::Cloud::Automl::V1::Operations::DeleteOperationMetadata

Details of operations that perform deletes of any entities.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Operations::DeployModelOperationMetadata

Details of DeployModel operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Operations::UndeployModelOperationMetadata

Details of UndeployModel operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Operations::CreateDatasetOperationMetadata

Details of CreateDataset operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Operations::CreateModelOperationMetadata

Details of CreateModel operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Operations::ImportDataOperationMetadata

Details of ImportData operation.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata

Details of ExportData operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata::ExportDataOutputInfo>)

Output only. Information further describing this export data's output.

=back

=head2 Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata

Details of BatchPredict operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Io::BatchPredictInputConfig>)

Output only. The input config that was given upon starting this
batch predict operation.

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata::BatchPredictOutputInfo>)

Output only. Information further describing this batch predict's output.

=back

=head2 Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata

Details of ExportModel operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_info() >> / C<< $msg->output_info($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata::ExportModelOutputInfo>)

Output only. Information further describing the output of this model
export.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
