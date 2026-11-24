package Google::Dataflow::V1beta3::Streaming;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvZGF0YWZsb3cvdjFiZXRhMy9zdHJlYW1pbmcucHJvdG8SF2dvb2dsZS5kYXRh
Zmxvdy52MWJldGEzIpcECg5Ub3BvbG9neUNvbmZpZxJQCgxjb21wdXRhdGlvbnMYASADKAsy
LC5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5Db21wdXRhdGlvblRvcG9sb2d5Ugxjb21wdXRh
dGlvbnMSXwoVZGF0YV9kaXNrX2Fzc2lnbm1lbnRzGAIgAygLMisuZ29vZ2xlLmRhdGFmbG93
LnYxYmV0YTMuRGF0YURpc2tBc3NpZ25tZW50UhNkYXRhRGlza0Fzc2lnbm1lbnRzEpUBCiJ1
c2VyX3N0YWdlX3RvX2NvbXB1dGF0aW9uX25hbWVfbWFwGAMgAygLMkouZ29vZ2xlLmRhdGFm
bG93LnYxYmV0YTMuVG9wb2xvZ3lDb25maWcuVXNlclN0YWdlVG9Db21wdXRhdGlvbk5hbWVN
YXBFbnRyeVIddXNlclN0YWdlVG9Db21wdXRhdGlvbk5hbWVNYXASLgoTZm9yd2FyZGluZ19r
ZXlfYml0cxgEIAEoBVIRZm9yd2FyZGluZ0tleUJpdHMSOAoYcGVyc2lzdGVudF9zdGF0ZV92
ZXJzaW9uGAUgASgFUhZwZXJzaXN0ZW50U3RhdGVWZXJzaW9uGlAKIlVzZXJTdGFnZVRvQ29t
cHV0YXRpb25OYW1lTWFwRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ASLFAgoOUHVic3ViTG9jYXRpb24SFAoFdG9waWMYASABKAlSBXRvcGljEiIK
DHN1YnNjcmlwdGlvbhgCIAEoCVIMc3Vic2NyaXB0aW9uEicKD3RpbWVzdGFtcF9sYWJlbBgD
IAEoCVIOdGltZXN0YW1wTGFiZWwSGQoIaWRfbGFiZWwYBCABKAlSB2lkTGFiZWwSJAoOZHJv
cF9sYXRlX2RhdGEYBSABKAhSDGRyb3BMYXRlRGF0YRIzChV0cmFja2luZ19zdWJzY3JpcHRp
b24YBiABKAlSFHRyYWNraW5nU3Vic2NyaXB0aW9uEicKD3dpdGhfYXR0cmlidXRlcxgHIAEo
CFIOd2l0aEF0dHJpYnV0ZXMSMQoUZHluYW1pY19kZXN0aW5hdGlvbnMYCCABKAhSE2R5bmFt
aWNEZXN0aW5hdGlvbnMiNQoWU3RyZWFtaW5nU3RhZ2VMb2NhdGlvbhIbCglzdHJlYW1faWQY
ASABKAlSCHN0cmVhbUlkIlEKGlN0cmVhbWluZ1NpZGVJbnB1dExvY2F0aW9uEhAKA3RhZxgB
IAEoCVIDdGFnEiEKDHN0YXRlX2ZhbWlseRgCIAEoCVILc3RhdGVGYW1pbHkiMgoUQ3VzdG9t
U291cmNlTG9jYXRpb24SGgoIc3RhdGVmdWwYASABKAhSCHN0YXRlZnVsIqsDCg5TdHJlYW1M
b2NhdGlvbhJrChhzdHJlYW1pbmdfc3RhZ2VfbG9jYXRpb24YASABKAsyLy5nb29nbGUuZGF0
YWZsb3cudjFiZXRhMy5TdHJlYW1pbmdTdGFnZUxvY2F0aW9uSABSFnN0cmVhbWluZ1N0YWdl
TG9jYXRpb24SUgoPcHVic3ViX2xvY2F0aW9uGAIgASgLMicuZ29vZ2xlLmRhdGFmbG93LnYx
YmV0YTMuUHVic3ViTG9jYXRpb25IAFIOcHVic3ViTG9jYXRpb24SZQoTc2lkZV9pbnB1dF9s
b2NhdGlvbhgDIAEoCzIzLmdvb2dsZS5kYXRhZmxvdy52MWJldGEzLlN0cmVhbWluZ1NpZGVJ
bnB1dExvY2F0aW9uSABSEXNpZGVJbnB1dExvY2F0aW9uEmUKFmN1c3RvbV9zb3VyY2VfbG9j
YXRpb24YBCABKAsyLS5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5DdXN0b21Tb3VyY2VMb2Nh
dGlvbkgAUhRjdXN0b21Tb3VyY2VMb2NhdGlvbkIKCghsb2NhdGlvbiJPChFTdGF0ZUZhbWls
eUNvbmZpZxIhCgxzdGF0ZV9mYW1pbHkYASABKAlSC3N0YXRlRmFtaWx5EhcKB2lzX3JlYWQY
AiABKAhSBmlzUmVhZCKJAwoTQ29tcHV0YXRpb25Ub3BvbG9neRIqChFzeXN0ZW1fc3RhZ2Vf
bmFtZRgBIAEoCVIPc3lzdGVtU3RhZ2VOYW1lEiUKDmNvbXB1dGF0aW9uX2lkGAUgASgJUg1j
b21wdXRhdGlvbklkEkgKCmtleV9yYW5nZXMYAiADKAsyKS5nb29nbGUuZGF0YWZsb3cudjFi
ZXRhMy5LZXlSYW5nZUxvY2F0aW9uUglrZXlSYW5nZXMSPwoGaW5wdXRzGAMgAygLMicuZ29v
Z2xlLmRhdGFmbG93LnYxYmV0YTMuU3RyZWFtTG9jYXRpb25SBmlucHV0cxJBCgdvdXRwdXRz
GAQgAygLMicuZ29vZ2xlLmRhdGFmbG93LnYxYmV0YTMuU3RyZWFtTG9jYXRpb25SB291dHB1
dHMSUQoOc3RhdGVfZmFtaWxpZXMYByADKAsyKi5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5T
dGF0ZUZhbWlseUNvbmZpZ1INc3RhdGVGYW1pbGllcyLQAQoQS2V5UmFuZ2VMb2NhdGlvbhIU
CgVzdGFydBgBIAEoCVIFc3RhcnQSEAoDZW5kGAIgASgJUgNlbmQSKwoRZGVsaXZlcnlfZW5k
cG9pbnQYAyABKAlSEGRlbGl2ZXJ5RW5kcG9pbnQSGwoJZGF0YV9kaXNrGAUgASgJUghkYXRh
RGlzaxJKCh9kZXByZWNhdGVkX3BlcnNpc3RlbnRfZGlyZWN0b3J5GAQgASgJQgIYAVIdZGVw
cmVjYXRlZFBlcnNpc3RlbnREaXJlY3RvcnkiLgoPTW91bnRlZERhdGFEaXNrEhsKCWRhdGFf
ZGlzaxgBIAEoCVIIZGF0YURpc2siVAoSRGF0YURpc2tBc3NpZ25tZW50Eh8KC3ZtX2luc3Rh
bmNlGAEgASgJUgp2bUluc3RhbmNlEh0KCmRhdGFfZGlza3MYAiADKAlSCWRhdGFEaXNrcyJh
ChpLZXlSYW5nZURhdGFEaXNrQXNzaWdubWVudBIUCgVzdGFydBgBIAEoCVIFc3RhcnQSEAoD
ZW5kGAIgASgJUgNlbmQSGwoJZGF0YV9kaXNrGAMgASgJUghkYXRhRGlzayKlAQoaU3RyZWFt
aW5nQ29tcHV0YXRpb25SYW5nZXMSJQoOY29tcHV0YXRpb25faWQYASABKAlSDWNvbXB1dGF0
aW9uSWQSYAoRcmFuZ2VfYXNzaWdubWVudHMYAiADKAsyMy5nb29nbGUuZGF0YWZsb3cudjFi
ZXRhMy5LZXlSYW5nZURhdGFEaXNrQXNzaWdubWVudFIQcmFuZ2VBc3NpZ25tZW50cyJ3CiBT
dHJlYW1pbmdBcHBsaWFuY2VTbmFwc2hvdENvbmZpZxIfCgtzbmFwc2hvdF9pZBgBIAEoCVIK
c25hcHNob3RJZBIyChVpbXBvcnRfc3RhdGVfZW5kcG9pbnQYAiABKAlSE2ltcG9ydFN0YXRl
RW5kcG9pbnRC0QEKG2NvbS5nb29nbGUuZGF0YWZsb3cudjFiZXRhM0IOU3RyZWFtaW5nUHJv
dG9QAVo9Y2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhZmxvdy9hcGl2MWJldGEzL2RhdGFmbG93
cGI7ZGF0YWZsb3dwYqoCHUdvb2dsZS5DbG91ZC5EYXRhZmxvdy5WMUJldGEzygIdR29vZ2xl
XENsb3VkXERhdGFmbG93XFYxYmV0YTPqAiBHb29nbGU6OkNsb3VkOjpEYXRhZmxvdzo6VjFi
ZXRhM0qfQgoHEgUOAOkBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAIAoICgEIEgMSADoKCQoCCCUSAxIAOgoICgEIEgMTAFQKCQoCCAsSAxMAVAoICgEI
EgMUACIKCQoCCAoSAxQAIgoICgEIEgMVAC8KCQoCCAgSAxUALwoICgEIEgMWADQKCQoCCAES
AxYANAoICgEIEgMXADoKCQoCCCkSAxcAOgoICgEIEgMYADkKCQoCCC0SAxgAOQp1CgIEABIE
HAArARppIEdsb2JhbCB0b3BvbG9neSBvZiB0aGUgc3RyZWFtaW5nIERhdGFmbG93IGpvYiwg
aW5jbHVkaW5nIGFsbAogY29tcHV0YXRpb25zIGFuZCB0aGVpciBzaGFyZGVkIGxvY2F0aW9u
cy4KCgoKAwQAARIDHAgWCkkKBAQAAgASAx4CMBo8IFRoZSBjb21wdXRhdGlvbnMgYXNzb2Np
YXRlZCB3aXRoIGEgc3RyZWFtaW5nIERhdGFmbG93IGpvYi4KCgwKBQQAAgAEEgMeAgoKDAoF
BAACAAYSAx4LHgoMCgUEAAIAARIDHh8rCgwKBQQAAgADEgMeLi8KPgoEBAACARIDIQI4GjEg
VGhlIGRpc2tzIGFzc2lnbmVkIHRvIGEgc3RyZWFtaW5nIERhdGFmbG93IGpvYi4KCgwKBQQA
AgEEEgMhAgoKDAoFBAACAQYSAyELHQoMCgUEAAIBARIDIR4zCgwKBQQAAgEDEgMhNjcKQQoE
BAACAhIDJAI9GjQgTWFwcyB1c2VyIHN0YWdlIG5hbWVzIHRvIHN0YWJsZSBjb21wdXRhdGlv
biBuYW1lcy4KCgwKBQQAAgIGEgMkAhUKDAoFBAACAgESAyQWOAoMCgUEAAICAxIDJDs8ClMK
BAQAAgMSAycCIBpGIFRoZSBzaXplIChpbiBiaXRzKSBvZiBrZXlzIHRoYXQgd2lsbCBiZSBh
c3NpZ25lZCB0byBzb3VyY2UgbWVzc2FnZXMuCgoMCgUEAAIDBRIDJwIHCgwKBQQAAgMBEgMn
CBsKDAoFBAACAwMSAyceHwozCgQEAAIEEgMqAiUaJiBWZXJzaW9uIG51bWJlciBmb3IgcGVy
c2lzdGVudCBzdGF0ZS4KCgwKBQQAAgQFEgMqAgcKDAoFBAACBAESAyoIIAoMCgUEAAIEAxID
KiMkCnEKAgQBEgQvAEwBGmUgSWRlbnRpZmllcyBhIHB1YnN1YiBsb2NhdGlvbiB0byB1c2Ug
Zm9yIHRyYW5zZmVycmluZyBkYXRhIGludG8gb3IKIG91dCBvZiBhIHN0cmVhbWluZyBEYXRh
ZmxvdyBqb2IuCgoKCgMEAQESAy8IFgpnCgQEAQIAEgMyAhMaWiBBIHB1YnN1YiB0b3BpYywg
aW4gdGhlIGZvcm0gb2YKICJwdWJzdWIuZ29vZ2xlYXBpcy5jb20vdG9waWNzLzxwcm9qZWN0
LWlkPi88dG9waWMtbmFtZT4iCgoMCgUEAQIABRIDMgIICgwKBQQBAgABEgMyCQ4KDAoFBAEC
AAMSAzIREgp8CgQEAQIBEgM2AhoabyBBIHB1YnN1YiBzdWJzY3JpcHRpb24sIGluIHRoZSBm
b3JtIG9mCiAicHVic3ViLmdvb2dsZWFwaXMuY29tL3N1YnNjcmlwdGlvbnMvPHByb2plY3Qt
aWQ+LzxzdWJzY3JpcHRpb24tbmFtZT4iCgoMCgUEAQIBBRIDNgIICgwKBQQBAgEBEgM2CRUK
DAoFBAECAQMSAzYYGQqaAQoEBAECAhIDOgIdGowBIElmIHNldCwgY29udGFpbnMgYSBwdWJz
dWIgbGFiZWwgZnJvbSB3aGljaCB0byBleHRyYWN0IHJlY29yZCB0aW1lc3RhbXBzLgogSWYg
bGVmdCBlbXB0eSwgcmVjb3JkIHRpbWVzdGFtcHMgd2lsbCBiZSBnZW5lcmF0ZWQgdXBvbiBh
cnJpdmFsLgoKDAoFBAECAgUSAzoCCAoMCgUEAQICARIDOgkYCgwKBQQBAgIDEgM6GxwKlAEK
BAQBAgMSAz4CFhqGASBJZiBzZXQsIGNvbnRhaW5zIGEgcHVic3ViIGxhYmVsIGZyb20gd2hp
Y2ggdG8gZXh0cmFjdCByZWNvcmQgaWRzLgogSWYgbGVmdCBlbXB0eSwgcmVjb3JkIGRlZHVw
bGljYXRpb24gd2lsbCBiZSBzdHJpY3RseSBiZXN0IGVmZm9ydC4KCgwKBQQBAgMFEgM+AggK
DAoFBAECAwESAz4JEQoMCgUEAQIDAxIDPhQVCkgKBAQBAgQSA0ECGho7IEluZGljYXRlcyB3
aGV0aGVyIHRoZSBwaXBlbGluZSBhbGxvd3MgbGF0ZS1hcnJpdmluZyBkYXRhLgoKDAoFBAEC
BAUSA0ECBgoMCgUEAQIEARIDQQcVCgwKBQQBAgQDEgNBGBkKiQEKBAQBAgUSA0UCIxp8IElm
IHNldCwgc3BlY2lmaWVzIHRoZSBwdWJzdWIgc3Vic2NyaXB0aW9uIHRoYXQgd2lsbCBiZSB1
c2VkIGZvciB0cmFja2luZwogY3VzdG9tIHRpbWUgdGltZXN0YW1wcyBmb3Igd2F0ZXJtYXJr
IGVzdGltYXRpb24uCgoMCgUEAQIFBRIDRQIICgwKBQQBAgUBEgNFCR4KDAoFBAECBQMSA0Uh
IgpPCgQEAQIGEgNIAhsaQiBJZiB0cnVlLCB0aGVuIHRoZSBjbGllbnQgaGFzIHJlcXVlc3Rl
ZCB0byBnZXQgcHVic3ViIGF0dHJpYnV0ZXMuCgoMCgUEAQIGBRIDSAIGCgwKBQQBAgYBEgNI
BxYKDAoFBAECBgMSA0gZGgpFCgQEAQIHEgNLAiAaOCBJZiB0cnVlLCB0aGVuIHRoaXMgbG9j
YXRpb24gcmVwcmVzZW50cyBkeW5hbWljIHRvcGljcy4KCgwKBQQBAgcFEgNLAgYKDAoFBAEC
BwESA0sHGwoMCgUEAQIHAxIDSx4fCmoKAgQCEgRQAFQBGl4gSWRlbnRpZmllcyB0aGUgbG9j
YXRpb24gb2YgYSBzdHJlYW1pbmcgY29tcHV0YXRpb24gc3RhZ2UsIGZvcgogc3RhZ2UtdG8t
c3RhZ2UgY29tbXVuaWNhdGlvbi4KCgoKAwQCARIDUAgeClMKBAQCAgASA1MCFxpGIElkZW50
aWZpZXMgdGhlIHBhcnRpY3VsYXIgc3RyZWFtIHdpdGhpbiB0aGUgc3RyZWFtaW5nIERhdGFm
bG93CiBqb2IuCgoMCgUEAgIABRIDUwIICgwKBQQCAgABEgNTCRIKDAoFBAICAAMSA1MVFgpA
CgIEAxIEVwBdARo0IElkZW50aWZpZXMgdGhlIGxvY2F0aW9uIG9mIGEgc3RyZWFtaW5nIHNp
ZGUgaW5wdXQuCgoKCgMEAwESA1cIIgpWCgQEAwIAEgNZAhEaSSBJZGVudGlmaWVzIHRoZSBw
YXJ0aWN1bGFyIHNpZGUgaW5wdXQgd2l0aGluIHRoZSBzdHJlYW1pbmcgRGF0YWZsb3cgam9i
LgoKDAoFBAMCAAUSA1kCCAoMCgUEAwIAARIDWQkMCgwKBQQDAgADEgNZDxAKSwoEBAMCARID
XAIaGj4gSWRlbnRpZmllcyB0aGUgc3RhdGUgZmFtaWx5IHdoZXJlIHRoaXMgc2lkZSBpbnB1
dCBpcyBzdG9yZWQuCgoMCgUEAwIBBRIDXAIICgwKBQQDAgEBEgNcCRUKDAoFBAMCAQMSA1wY
GQo4CgIEBBIEYABjARosIElkZW50aWZpZXMgdGhlIGxvY2F0aW9uIG9mIGEgY3VzdG9tIHNv
dWNlLgoKCgoDBAQBEgNgCBwKLwoEBAQCABIDYgIUGiIgV2hldGhlciB0aGlzIHNvdXJjZSBp
cyBzdGF0ZWZ1bC4KCgwKBQQEAgAFEgNiAgYKDAoFBAQCAAESA2IHDwoMCgUEBAIAAxIDYhIT
CnQKAgQFEgRnAHcBGmggRGVzY3JpYmVzIGEgc3RyZWFtIG9mIGRhdGEsIGVpdGhlciBhcyBp
bnB1dCB0byBiZSBwcm9jZXNzZWQgb3IgYXMKIG91dHB1dCBvZiBhIHN0cmVhbWluZyBEYXRh
ZmxvdyBqb2IuCgoKCgMEBQESA2cIFgo3CgQEBQgAEgRpAnYDGikgQSBzcGVjaWZpY2F0aW9u
IG9mIGEgc3RyZWFtJ3MgbG9jYXRpb24uCgoMCgUEBQgAARIDaQgQCmQKBAQFAgASA2wEOBpX
IFRoZSBzdHJlYW0gaXMgcGFydCBvZiBhbm90aGVyIGNvbXB1dGF0aW9uIHdpdGhpbiB0aGUg
Y3VycmVudAogc3RyZWFtaW5nIERhdGFmbG93IGpvYi4KCgwKBQQFAgAGEgNsBBoKDAoFBAUC
AAESA2wbMwoMCgUEBQIAAxIDbDY3Ci0KBAQFAgESA28EJxogIFRoZSBzdHJlYW0gaXMgYSBw
dWJzdWIgc3RyZWFtLgoKDAoFBAUCAQYSA28EEgoMCgUEBQIBARIDbxMiCgwKBQQFAgEDEgNv
JSYKNAoEBAUCAhIDcgQ3GicgVGhlIHN0cmVhbSBpcyBhIHN0cmVhbWluZyBzaWRlIGlucHV0
LgoKDAoFBAUCAgYSA3IEHgoMCgUEBQICARIDch8yCgwKBQQFAgIDEgNyNTYKLQoEBAUCAxID
dQQ0GiAgVGhlIHN0cmVhbSBpcyBhIGN1c3RvbSBzb3VyY2UuCgoMCgUEBQIDBhIDdQQYCgwK
BQQFAgMBEgN1GS8KDAoFBAUCAwMSA3UyMwoqCgIEBhIFegCAAQEaHSBTdGF0ZSBmYW1pbHkg
Y29uZmlndXJhdGlvbi4KCgoKAwQGARIDeggZCiYKBAQGAgASA3wCGhoZIFRoZSBzdGF0ZSBm
YW1pbHkgdmFsdWUuCgoMCgUEBgIABRIDfAIICgwKBQQGAgABEgN8CRUKDAoFBAYCAAMSA3wY
GQpECgQEBgIBEgN/AhMaNyBJZiB0cnVlLCB0aGlzIGZhbWlseSBjb3JyZXNwb25kcyB0byBh
IHJlYWQgb3BlcmF0aW9uLgoKDAoFBAYCAQUSA38CBgoMCgUEBgIBARIDfwcOCgwKBQQGAgED
EgN/ERIKRAoCBAcSBoMBAJUBARo2IEFsbCBjb25maWd1cmF0aW9uIGRhdGEgZm9yIGEgcGFy
dGljdWxhciBDb21wdXRhdGlvbi4KCgsKAwQHARIEgwEIGwomCgQEBwIAEgSFAQIfGhggVGhl
IHN5c3RlbSBzdGFnZSBuYW1lLgoKDQoFBAcCAAUSBIUBAggKDQoFBAcCAAESBIUBCRoKDQoF
BAcCAAMSBIUBHR4KKgoEBAcCARIEiAECHBocIFRoZSBJRCBvZiB0aGUgY29tcHV0YXRpb24u
CgoNCgUEBwIBBRIEiAECCAoNCgUEBwIBARIEiAEJFwoNCgUEBwIBAxIEiAEaGwo8CgQEBwIC
EgSLAQIrGi4gVGhlIGtleSByYW5nZXMgcHJvY2Vzc2VkIGJ5IHRoZSBjb21wdXRhdGlvbi4K
Cg0KBQQHAgIEEgSLAQIKCg0KBQQHAgIGEgSLAQsbCg0KBQQHAgIBEgSLARwmCg0KBQQHAgID
EgSLASkqCi4KBAQHAgMSBI4BAiUaICBUaGUgaW5wdXRzIHRvIHRoZSBjb21wdXRhdGlvbi4K
Cg0KBQQHAgMEEgSOAQIKCg0KBQQHAgMGEgSOAQsZCg0KBQQHAgMBEgSOARogCg0KBQQHAgMD
EgSOASMkCjEKBAQHAgQSBJEBAiYaIyBUaGUgb3V0cHV0cyBmcm9tIHRoZSBjb21wdXRhdGlv
bi4KCg0KBQQHAgQEEgSRAQIKCg0KBQQHAgQGEgSRAQsZCg0KBQQHAgQBEgSRARohCg0KBQQH
AgQDEgSRASQlCigKBAQHAgUSBJQBAjAaGiBUaGUgc3RhdGUgZmFtaWx5IHZhbHVlcy4KCg0K
BQQHAgUEEgSUAQIKCg0KBQQHAgUGEgSUAQscCg0KBQQHAgUBEgSUAR0rCg0KBQQHAgUDEgSU
AS4vCqsBCgIECBIGmgEArgEBGpwBIExvY2F0aW9uIGluZm9ybWF0aW9uIGZvciBhIHNwZWNp
ZmljIGtleS1yYW5nZSBvZiBhIHNoYXJkZWQgY29tcHV0YXRpb24uCiBDdXJyZW50bHkgd2Ug
b25seSBzdXBwb3J0IFVURi04IGNoYXJhY3RlciBzcGxpdHMgdG8gc2ltcGxpZnkgZW5jb2Rp
bmcgaW50bwogSlNPTi4KCgsKAwQIARIEmgEIGAo3CgQECAIAEgScAQITGikgVGhlIHN0YXJ0
IChpbmNsdXNpdmUpIG9mIHRoZSBrZXkgcmFuZ2UuCgoNCgUECAIABRIEnAECCAoNCgUECAIA
ARIEnAEJDgoNCgUECAIAAxIEnAEREgo1CgQECAIBEgSfAQIRGicgVGhlIGVuZCAoZXhjbHVz
aXZlKSBvZiB0aGUga2V5IHJhbmdlLgoKDQoFBAgCAQUSBJ8BAggKDQoFBAgCAQESBJ8BCQwK
DQoFBAgCAQMSBJ8BDxAKgwEKBAQIAgISBKMBAh8adSBUaGUgcGh5c2ljYWwgbG9jYXRpb24g
b2YgdGhpcyByYW5nZSBhc3NpZ25tZW50IHRvIGJlIHVzZWQgZm9yCiBzdHJlYW1pbmcgY29t
cHV0YXRpb24gY3Jvc3Mtd29ya2VyIG1lc3NhZ2UgZGVsaXZlcnkuCgoNCgUECAICBRIEowEC
CAoNCgUECAICARIEowEJGgoNCgUECAICAxIEowEdHgr6AQoEBAgCAxIEqQECFxrrASBUaGUg
bmFtZSBvZiB0aGUgZGF0YSBkaXNrIHdoZXJlIGRhdGEgZm9yIHRoaXMgcmFuZ2UgaXMgc3Rv
cmVkLgogVGhpcyBuYW1lIGlzIGxvY2FsIHRvIHRoZSBHb29nbGUgQ2xvdWQgUGxhdGZvcm0g
cHJvamVjdCBhbmQgdW5pcXVlbHkKIGlkZW50aWZpZXMgdGhlIGRpc2sgd2l0aGluIHRoYXQg
cHJvamVjdCwgZm9yIGV4YW1wbGUKICJteXByb2plY3QtMTAxNC0xMDQ4MTctNGMyLWhhcm5l
c3MtMC1kaXNrLTEiLgoKDQoFBAgCAwUSBKkBAggKDQoFBAgCAwESBKkBCRIKDQoFBAgCAwMS
BKkBFRYKiwEKBAQIAgQSBK0BAkEafSBERVBSRUNBVEVELiBUaGUgbG9jYXRpb24gb2YgdGhl
IHBlcnNpc3RlbnQgc3RhdGUgZm9yIHRoaXMgcmFuZ2UsIGFzIGEKIHBlcnNpc3RlbnQgZGly
ZWN0b3J5IGluIHRoZSB3b3JrZXIgbG9jYWwgZmlsZXN5c3RlbS4KCg0KBQQIAgQFEgStAQII
Cg0KBQQIAgQBEgStAQkoCg0KBQQIAgQDEgStASssCg0KBQQIAgQIEgStAS1ACg4KBgQIAgQI
AxIErQEuPwosCgIECRIGsQEAtwEBGh4gRGVzY3JpYmVzIG1vdW50ZWQgZGF0YSBkaXNrLgoK
CwoDBAkBEgSxAQgXCtYBCgQECQIAEgS2AQIXGscBIFRoZSBuYW1lIG9mIHRoZSBkYXRhIGRp
c2suCiBUaGlzIG5hbWUgaXMgbG9jYWwgdG8gdGhlIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBw
cm9qZWN0IGFuZCB1bmlxdWVseQogaWRlbnRpZmllcyB0aGUgZGlzayB3aXRoaW4gdGhhdCBw
cm9qZWN0LCBmb3IgZXhhbXBsZQogIm15cHJvamVjdC0xMDE0LTEwNDgxNy00YzItaGFybmVz
cy0wLWRpc2stMSIuCgoNCgUECQIABRIEtgECCAoNCgUECQIAARIEtgEJEgoNCgUECQIAAxIE
tgEVFgo9CgIEChIGugEAxAEBGi8gRGF0YSBkaXNrIGFzc2lnbm1lbnQgZm9yIGEgZ2l2ZW4g
Vk0gaW5zdGFuY2UuCgoLCgMECgESBLoBCBoKbwoEBAoCABIEvQECGRphIFZNIGluc3RhbmNl
IG5hbWUgdGhlIGRhdGEgZGlza3MgbW91bnRlZCB0bywgZm9yIGV4YW1wbGUKICJteXByb2pl
Y3QtMTAxNC0xMDQ4MTctNGMyLWhhcm5lc3MtMCIuCgoNCgUECgIABRIEvQECCAoNCgUECgIA
ARIEvQEJFAoNCgUECgIAAxIEvQEXGAqeAgoEBAoCARIEwwECIRqPAiBNb3VudGVkIGRhdGEg
ZGlza3MuIFRoZSBvcmRlciBpcyBpbXBvcnRhbnQgYSBkYXRhIGRpc2sncyAwLWJhc2VkIGlu
ZGV4IGluCiB0aGlzIGxpc3QgZGVmaW5lcyB3aGljaCBwZXJzaXN0ZW50IGRpcmVjdG9yeSB0
aGUgZGlzayBpcyBtb3VudGVkIHRvLCBmb3IKIGV4YW1wbGUgdGhlIGxpc3Qgb2YgeyAibXlw
cm9qZWN0LTEwMTQtMTA0ODE3LTRjMi1oYXJuZXNzLTAtZGlzay0wIiB9LAogeyAibXlwcm9q
ZWN0LTEwMTQtMTA0ODE3LTRjMi1oYXJuZXNzLTAtZGlzay0xIiB9LgoKDQoFBAoCAQQSBMMB
AgoKDQoFBAoCAQUSBMMBCxEKDQoFBAoCAQESBMMBEhwKDQoFBAoCAQMSBMMBHyAKuAEKAgQL
EgbKAQDWAQEaqQEgRGF0YSBkaXNrIGFzc2lnbm1lbnQgaW5mb3JtYXRpb24gZm9yIGEgc3Bl
Y2lmaWMga2V5LXJhbmdlIG9mIGEgc2hhcmRlZAogY29tcHV0YXRpb24uCiBDdXJyZW50bHkg
d2Ugb25seSBzdXBwb3J0IFVURi04IGNoYXJhY3RlciBzcGxpdHMgdG8gc2ltcGxpZnkgZW5j
b2RpbmcgaW50bwogSlNPTi4KCgsKAwQLARIEygEIIgo3CgQECwIAEgTMAQITGikgVGhlIHN0
YXJ0IChpbmNsdXNpdmUpIG9mIHRoZSBrZXkgcmFuZ2UuCgoNCgUECwIABRIEzAECCAoNCgUE
CwIAARIEzAEJDgoNCgUECwIAAxIEzAEREgo1CgQECwIBEgTPAQIRGicgVGhlIGVuZCAoZXhj
bHVzaXZlKSBvZiB0aGUga2V5IHJhbmdlLgoKDQoFBAsCAQUSBM8BAggKDQoFBAsCAQESBM8B
CQwKDQoFBAsCAQMSBM8BDxAK+gEKBAQLAgISBNUBAhca6wEgVGhlIG5hbWUgb2YgdGhlIGRh
dGEgZGlzayB3aGVyZSBkYXRhIGZvciB0aGlzIHJhbmdlIGlzIHN0b3JlZC4KIFRoaXMgbmFt
ZSBpcyBsb2NhbCB0byB0aGUgR29vZ2xlIENsb3VkIFBsYXRmb3JtIHByb2plY3QgYW5kIHVu
aXF1ZWx5CiBpZGVudGlmaWVzIHRoZSBkaXNrIHdpdGhpbiB0aGF0IHByb2plY3QsIGZvciBl
eGFtcGxlCiAibXlwcm9qZWN0LTEwMTQtMTA0ODE3LTRjMi1oYXJuZXNzLTAtZGlzay0xIi4K
Cg0KBQQLAgIFEgTVAQIICg0KBQQLAgIBEgTVAQkSCg0KBQQLAgIDEgTVARUWCmYKAgQMEgba
AQDgAQEaWCBEZXNjcmliZXMgZnVsbCBvciBwYXJ0aWFsIGRhdGEgZGlzayBhc3NpZ25tZW50
IGluZm9ybWF0aW9uIG9mIHRoZSBjb21wdXRhdGlvbgogcmFuZ2VzLgoKCwoDBAwBEgTaAQgi
CioKBAQMAgASBNwBAhwaHCBUaGUgSUQgb2YgdGhlIGNvbXB1dGF0aW9uLgoKDQoFBAwCAAUS
BNwBAggKDQoFBAwCAAESBNwBCRcKDQoFBAwCAAMSBNwBGhsKRwoEBAwCARIE3wECPBo5IERh
dGEgZGlzayBhc3NpZ25tZW50cyBmb3IgcmFuZ2VzIGZyb20gdGhpcyBjb21wdXRhdGlvbi4K
Cg0KBQQMAgEEEgTfAQIKCg0KBQQMAgEGEgTfAQslCg0KBQQMAgEBEgTfASY3Cg0KBQQMAgED
EgTfATo7CjsKAgQNEgbjAQDpAQEaLSBTdHJlYW1pbmcgYXBwbGlhbmNlIHNuYXBzaG90IGNv
bmZpZ3VyYXRpb24uCgoLCgMEDQESBOMBCCgKUwoEBA0CABIE5QECGRpFIElmIHNldCwgaW5k
aWNhdGVzIHRoZSBzbmFwc2hvdCBpZCBmb3IgdGhlIHNuYXBzaG90IGJlaW5nIHBlcmZvcm1l
ZC4KCg0KBQQNAgAFEgTlAQIICg0KBQQNAgABEgTlAQkUCg0KBQQNAgADEgTlARcYCksKBAQN
AgESBOgBAiMaPSBJbmRpY2F0ZXMgd2hpY2ggZW5kcG9pbnQgaXMgdXNlZCB0byBpbXBvcnQg
YXBwbGlhbmNlIHN0YXRlLgoKDQoFBA0CAQUSBOgBAggKDQoFBA0CAQESBOgBCR4KDQoFBA0C
AQMSBOgBISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Dataflow::V1beta3::Streaming::TopologyConfig ===
    # Fields for TopologyConfig
    # Field: computations Type: 11 (.google.dataflow.v1beta3.ComputationTopology)
    # Field: data_disk_assignments Type: 11 (.google.dataflow.v1beta3.DataDiskAssignment)
    # Field: user_stage_to_computation_name_map Type: 11 (.google.dataflow.v1beta3.TopologyConfig.UserStageToComputationNameMapEntry)
    # Field: forwarding_key_bits Type: 5 ()
    # Field: persistent_state_version Type: 5 ()

# === Message: Google::Dataflow::V1beta3::Streaming::PubsubLocation ===
    # Fields for PubsubLocation
    # Field: topic Type: 9 ()
    # Field: subscription Type: 9 ()
    # Field: timestamp_label Type: 9 ()
    # Field: id_label Type: 9 ()
    # Field: drop_late_data Type: 8 ()
    # Field: tracking_subscription Type: 9 ()
    # Field: with_attributes Type: 8 ()
    # Field: dynamic_destinations Type: 8 ()

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingStageLocation ===
    # Fields for StreamingStageLocation
    # Field: stream_id Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation ===
    # Fields for StreamingSideInputLocation
    # Field: tag Type: 9 ()
    # Field: state_family Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Streaming::CustomSourceLocation ===
    # Fields for CustomSourceLocation
    # Field: stateful Type: 8 ()

# === Message: Google::Dataflow::V1beta3::Streaming::StreamLocation ===
    # Fields for StreamLocation
    # Field: streaming_stage_location Type: 11 (.google.dataflow.v1beta3.StreamingStageLocation)
    # Field: pubsub_location Type: 11 (.google.dataflow.v1beta3.PubsubLocation)
    # Field: side_input_location Type: 11 (.google.dataflow.v1beta3.StreamingSideInputLocation)
    # Field: custom_source_location Type: 11 (.google.dataflow.v1beta3.CustomSourceLocation)

# === Message: Google::Dataflow::V1beta3::Streaming::StateFamilyConfig ===
    # Fields for StateFamilyConfig
    # Field: state_family Type: 9 ()
    # Field: is_read Type: 8 ()

# === Message: Google::Dataflow::V1beta3::Streaming::ComputationTopology ===
    # Fields for ComputationTopology
    # Field: system_stage_name Type: 9 ()
    # Field: computation_id Type: 9 ()
    # Field: key_ranges Type: 11 (.google.dataflow.v1beta3.KeyRangeLocation)
    # Field: inputs Type: 11 (.google.dataflow.v1beta3.StreamLocation)
    # Field: outputs Type: 11 (.google.dataflow.v1beta3.StreamLocation)
    # Field: state_families Type: 11 (.google.dataflow.v1beta3.StateFamilyConfig)

# === Message: Google::Dataflow::V1beta3::Streaming::KeyRangeLocation ===
    # Fields for KeyRangeLocation
    # Field: start Type: 9 ()
    # Field: end Type: 9 ()
    # Field: delivery_endpoint Type: 9 ()
    # Field: data_disk Type: 9 ()
    # Field: deprecated_persistent_directory Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Streaming::MountedDataDisk ===
    # Fields for MountedDataDisk
    # Field: data_disk Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Streaming::DataDiskAssignment ===
    # Fields for DataDiskAssignment
    # Field: vm_instance Type: 9 ()
    # Field: data_disks Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment ===
    # Fields for KeyRangeDataDiskAssignment
    # Field: start Type: 9 ()
    # Field: end Type: 9 ()
    # Field: data_disk Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges ===
    # Fields for StreamingComputationRanges
    # Field: computation_id Type: 9 ()
    # Field: range_assignments Type: 11 (.google.dataflow.v1beta3.KeyRangeDataDiskAssignment)

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig ===
    # Fields for StreamingApplianceSnapshotConfig
    # Field: snapshot_id Type: 9 ()
    # Field: import_state_endpoint Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Dataflow::V1beta3::Streaming - Compiled Protocol Buffers messages for google/dataflow/v1beta3/streaming.proto

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::TopologyConfig->new({
        computations => $computations,
        data_disk_assignments => $data_disk_assignments,
        user_stage_to_computation_name_map => $user_stage_to_computation_name_map,
        forwarding_key_bits => $forwarding_key_bits,
    });

    # Read or update a field
    my $val = $msg->computations();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Dataflow::V1beta3::Streaming::TopologyConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/dataflow/v1beta3/streaming.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Dataflow::V1beta3::Streaming::TopologyConfig

Global topology of the streaming Dataflow job, including all
computations and their sharded locations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->computations() >> / C<< $msg->computations($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::ComputationTopology>)

The computations associated with a streaming Dataflow job.

=item * C<< $msg->data_disk_assignments() >> / C<< $msg->data_disk_assignments($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::DataDiskAssignment>)

The disks assigned to a streaming Dataflow job.

=item * C<< $msg->user_stage_to_computation_name_map() >> / C<< $msg->user_stage_to_computation_name_map($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::TopologyConfig::UserStageToComputationNameMapEntry>)

Maps user stage names to stable computation names.

=item * C<< $msg->forwarding_key_bits() >> / C<< $msg->forwarding_key_bits($value) >>

Type: C<Int32>

The size (in bits) of keys that will be assigned to source messages.

=item * C<< $msg->persistent_state_version() >> / C<< $msg->persistent_state_version($value) >>

Type: C<Int32>

Version number for persistent state.

=back

=head2 Google::Dataflow::V1beta3::Streaming::PubsubLocation

Identifies a pubsub location to use for transferring data into or
out of a streaming Dataflow job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

A pubsub topic, in the form of
"pubsub.googleapis.com/topics/<project-id>/<topic-name>"

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

A pubsub subscription, in the form of
"pubsub.googleapis.com/subscriptions/<project-id>/<subscription-name>"

=item * C<< $msg->timestamp_label() >> / C<< $msg->timestamp_label($value) >>

Type: C<String>

If set, contains a pubsub label from which to extract record timestamps.
If left empty, record timestamps will be generated upon arrival.

=item * C<< $msg->id_label() >> / C<< $msg->id_label($value) >>

Type: C<String>

If set, contains a pubsub label from which to extract record ids.
If left empty, record deduplication will be strictly best effort.

=item * C<< $msg->drop_late_data() >> / C<< $msg->drop_late_data($value) >>

Type: C<Bool>

Indicates whether the pipeline allows late-arriving data.

=item * C<< $msg->tracking_subscription() >> / C<< $msg->tracking_subscription($value) >>

Type: C<String>

If set, specifies the pubsub subscription that will be used for tracking
custom time timestamps for watermark estimation.

=item * C<< $msg->with_attributes() >> / C<< $msg->with_attributes($value) >>

Type: C<Bool>

If true, then the client has requested to get pubsub attributes.

=item * C<< $msg->dynamic_destinations() >> / C<< $msg->dynamic_destinations($value) >>

Type: C<Bool>

If true, then this location represents dynamic topics.

=back

=head2 Google::Dataflow::V1beta3::Streaming::StreamingStageLocation

Identifies the location of a streaming computation stage, for
stage-to-stage communication.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<String>

Identifies the particular stream within the streaming Dataflow
job.

=back

=head2 Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation

Identifies the location of a streaming side input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

Identifies the particular side input within the streaming Dataflow job.

=item * C<< $msg->state_family() >> / C<< $msg->state_family($value) >>

Type: C<String>

Identifies the state family where this side input is stored.

=back

=head2 Google::Dataflow::V1beta3::Streaming::CustomSourceLocation

Identifies the location of a custom souce.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stateful() >> / C<< $msg->stateful($value) >>

Type: C<Bool>

Whether this source is stateful.

=back

=head2 Google::Dataflow::V1beta3::Streaming::StreamLocation

Describes a stream of data, either as input to be processed or as
output of a streaming Dataflow job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->streaming_stage_location() >> / C<< $msg->streaming_stage_location($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::StreamingStageLocation>)

The stream is part of another computation within the current
streaming Dataflow job.

=item * C<< $msg->pubsub_location() >> / C<< $msg->pubsub_location($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::PubsubLocation>)

The stream is a pubsub stream.

=item * C<< $msg->side_input_location() >> / C<< $msg->side_input_location($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation>)

The stream is a streaming side input.

=item * C<< $msg->custom_source_location() >> / C<< $msg->custom_source_location($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::CustomSourceLocation>)

The stream is a custom source.

=back

=head2 Google::Dataflow::V1beta3::Streaming::StateFamilyConfig

State family configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state_family() >> / C<< $msg->state_family($value) >>

Type: C<String>

The state family value.

=item * C<< $msg->is_read() >> / C<< $msg->is_read($value) >>

Type: C<Bool>

If true, this family corresponds to a read operation.

=back

=head2 Google::Dataflow::V1beta3::Streaming::ComputationTopology

All configuration data for a particular Computation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->system_stage_name() >> / C<< $msg->system_stage_name($value) >>

Type: C<String>

The system stage name.

=item * C<< $msg->computation_id() >> / C<< $msg->computation_id($value) >>

Type: C<String>

The ID of the computation.

=item * C<< $msg->key_ranges() >> / C<< $msg->key_ranges($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::KeyRangeLocation>)

The key ranges processed by the computation.

=item * C<< $msg->inputs() >> / C<< $msg->inputs($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::StreamLocation>)

The inputs to the computation.

=item * C<< $msg->outputs() >> / C<< $msg->outputs($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::StreamLocation>)

The outputs from the computation.

=item * C<< $msg->state_families() >> / C<< $msg->state_families($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::StateFamilyConfig>)

The state family values.

=back

=head2 Google::Dataflow::V1beta3::Streaming::KeyRangeLocation

Location information for a specific key-range of a sharded computation.
Currently we only support UTF-8 character splits to simplify encoding into
JSON.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<String>

The start (inclusive) of the key range.

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<String>

The end (exclusive) of the key range.

=item * C<< $msg->delivery_endpoint() >> / C<< $msg->delivery_endpoint($value) >>

Type: C<String>

The physical location of this range assignment to be used for
streaming computation cross-worker message delivery.

=item * C<< $msg->data_disk() >> / C<< $msg->data_disk($value) >>

Type: C<String>

The name of the data disk where data for this range is stored.
This name is local to the Google Cloud Platform project and uniquely
identifies the disk within that project, for example
"myproject-1014-104817-4c2-harness-0-disk-1".

=item * C<< $msg->deprecated_persistent_directory() >> / C<< $msg->deprecated_persistent_directory($value) >>

Type: C<String>

DEPRECATED. The location of the persistent state for this range, as a
persistent directory in the worker local filesystem.

=back

=head2 Google::Dataflow::V1beta3::Streaming::MountedDataDisk

Describes mounted data disk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_disk() >> / C<< $msg->data_disk($value) >>

Type: C<String>

The name of the data disk.
This name is local to the Google Cloud Platform project and uniquely
identifies the disk within that project, for example
"myproject-1014-104817-4c2-harness-0-disk-1".

=back

=head2 Google::Dataflow::V1beta3::Streaming::DataDiskAssignment

Data disk assignment for a given VM instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vm_instance() >> / C<< $msg->vm_instance($value) >>

Type: C<String>

VM instance name the data disks mounted to, for example
"myproject-1014-104817-4c2-harness-0".

=item * C<< $msg->data_disks() >> / C<< $msg->data_disks($value) >>

Type: C<String>

Mounted data disks. The order is important a data disk's 0-based index in
this list defines which persistent directory the disk is mounted to, for
example the list of { "myproject-1014-104817-4c2-harness-0-disk-0" },
{ "myproject-1014-104817-4c2-harness-0-disk-1" }.

=back

=head2 Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment

Data disk assignment information for a specific key-range of a sharded
computation.
Currently we only support UTF-8 character splits to simplify encoding into
JSON.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<String>

The start (inclusive) of the key range.

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<String>

The end (exclusive) of the key range.

=item * C<< $msg->data_disk() >> / C<< $msg->data_disk($value) >>

Type: C<String>

The name of the data disk where data for this range is stored.
This name is local to the Google Cloud Platform project and uniquely
identifies the disk within that project, for example
"myproject-1014-104817-4c2-harness-0-disk-1".

=back

=head2 Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges

Describes full or partial data disk assignment information of the computation
ranges.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->computation_id() >> / C<< $msg->computation_id($value) >>

Type: C<String>

The ID of the computation.

=item * C<< $msg->range_assignments() >> / C<< $msg->range_assignments($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment>)

Data disk assignments for ranges from this computation.

=back

=head2 Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig

Streaming appliance snapshot configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snapshot_id() >> / C<< $msg->snapshot_id($value) >>

Type: C<String>

If set, indicates the snapshot id for the snapshot being performed.

=item * C<< $msg->import_state_endpoint() >> / C<< $msg->import_state_endpoint($value) >>

Type: C<String>

Indicates which endpoint is used to import appliance state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Dataflow::V1beta3::Streaming::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
