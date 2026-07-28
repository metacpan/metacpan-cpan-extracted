package Google::Dataflow::V1beta3::Streaming;

use strict;
use warnings;

our $VERSION = '0.11';

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

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::TopologyConfig - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::TopologyConfig->new(
        computations => $value,
    );

=head1 FIELDS

=over 4

=item * B<computations>

Type: Message (.google.dataflow.v1beta3.ComputationTopology)

=item * B<data_disk_assignments>

Type: Message (.google.dataflow.v1beta3.DataDiskAssignment)

=item * B<user_stage_to_computation_name_map>

Type: Message (.google.dataflow.v1beta3.TopologyConfig.UserStageToComputationNameMapEntry)

=item * B<forwarding_key_bits>

Type: Int32

=item * B<persistent_state_version>

Type: Int32

=back

=cut

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

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::PubsubLocation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::PubsubLocation->new(
        topic => $value,
    );

=head1 FIELDS

=over 4

=item * B<topic>

Type: String

=item * B<subscription>

Type: String

=item * B<timestamp_label>

Type: String

=item * B<id_label>

Type: String

=item * B<drop_late_data>

Type: Bool

=item * B<tracking_subscription>

Type: String

=item * B<with_attributes>

Type: Bool

=item * B<dynamic_destinations>

Type: Bool

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingStageLocation ===
    # Fields for StreamingStageLocation
    # Field: stream_id Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::StreamingStageLocation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::StreamingStageLocation->new(
        stream_id => $value,
    );

=head1 FIELDS

=over 4

=item * B<stream_id>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation ===
    # Fields for StreamingSideInputLocation
    # Field: tag Type: 9 ()
    # Field: state_family Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::StreamingSideInputLocation->new(
        tag => $value,
    );

=head1 FIELDS

=over 4

=item * B<tag>

Type: String

=item * B<state_family>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::CustomSourceLocation ===
    # Fields for CustomSourceLocation
    # Field: stateful Type: 8 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::CustomSourceLocation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::CustomSourceLocation->new(
        stateful => $value,
    );

=head1 FIELDS

=over 4

=item * B<stateful>

Type: Bool

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::StreamLocation ===
    # Fields for StreamLocation
    # Field: streaming_stage_location Type: 11 (.google.dataflow.v1beta3.StreamingStageLocation)
    # Field: pubsub_location Type: 11 (.google.dataflow.v1beta3.PubsubLocation)
    # Field: side_input_location Type: 11 (.google.dataflow.v1beta3.StreamingSideInputLocation)
    # Field: custom_source_location Type: 11 (.google.dataflow.v1beta3.CustomSourceLocation)

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::StreamLocation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::StreamLocation->new(
        streaming_stage_location => $value,
    );

=head1 FIELDS

=over 4

=item * B<streaming_stage_location>

Type: Message (.google.dataflow.v1beta3.StreamingStageLocation)

=item * B<pubsub_location>

Type: Message (.google.dataflow.v1beta3.PubsubLocation)

=item * B<side_input_location>

Type: Message (.google.dataflow.v1beta3.StreamingSideInputLocation)

=item * B<custom_source_location>

Type: Message (.google.dataflow.v1beta3.CustomSourceLocation)

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::StateFamilyConfig ===
    # Fields for StateFamilyConfig
    # Field: state_family Type: 9 ()
    # Field: is_read Type: 8 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::StateFamilyConfig - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::StateFamilyConfig->new(
        state_family => $value,
    );

=head1 FIELDS

=over 4

=item * B<state_family>

Type: String

=item * B<is_read>

Type: Bool

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::ComputationTopology ===
    # Fields for ComputationTopology
    # Field: system_stage_name Type: 9 ()
    # Field: computation_id Type: 9 ()
    # Field: key_ranges Type: 11 (.google.dataflow.v1beta3.KeyRangeLocation)
    # Field: inputs Type: 11 (.google.dataflow.v1beta3.StreamLocation)
    # Field: outputs Type: 11 (.google.dataflow.v1beta3.StreamLocation)
    # Field: state_families Type: 11 (.google.dataflow.v1beta3.StateFamilyConfig)

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::ComputationTopology - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::ComputationTopology->new(
        system_stage_name => $value,
    );

=head1 FIELDS

=over 4

=item * B<system_stage_name>

Type: String

=item * B<computation_id>

Type: String

=item * B<key_ranges>

Type: Message (.google.dataflow.v1beta3.KeyRangeLocation)

=item * B<inputs>

Type: Message (.google.dataflow.v1beta3.StreamLocation)

=item * B<outputs>

Type: Message (.google.dataflow.v1beta3.StreamLocation)

=item * B<state_families>

Type: Message (.google.dataflow.v1beta3.StateFamilyConfig)

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::KeyRangeLocation ===
    # Fields for KeyRangeLocation
    # Field: start Type: 9 ()
    # Field: end Type: 9 ()
    # Field: delivery_endpoint Type: 9 ()
    # Field: data_disk Type: 9 ()
    # Field: deprecated_persistent_directory Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::KeyRangeLocation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::KeyRangeLocation->new(
        start => $value,
    );

=head1 FIELDS

=over 4

=item * B<start>

Type: String

=item * B<end>

Type: String

=item * B<delivery_endpoint>

Type: String

=item * B<data_disk>

Type: String

=item * B<deprecated_persistent_directory>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::MountedDataDisk ===
    # Fields for MountedDataDisk
    # Field: data_disk Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::MountedDataDisk - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::MountedDataDisk->new(
        data_disk => $value,
    );

=head1 FIELDS

=over 4

=item * B<data_disk>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::DataDiskAssignment ===
    # Fields for DataDiskAssignment
    # Field: vm_instance Type: 9 ()
    # Field: data_disks Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::DataDiskAssignment - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::DataDiskAssignment->new(
        vm_instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<vm_instance>

Type: String

=item * B<data_disks>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment ===
    # Fields for KeyRangeDataDiskAssignment
    # Field: start Type: 9 ()
    # Field: end Type: 9 ()
    # Field: data_disk Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::KeyRangeDataDiskAssignment->new(
        start => $value,
    );

=head1 FIELDS

=over 4

=item * B<start>

Type: String

=item * B<end>

Type: String

=item * B<data_disk>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges ===
    # Fields for StreamingComputationRanges
    # Field: computation_id Type: 9 ()
    # Field: range_assignments Type: 11 (.google.dataflow.v1beta3.KeyRangeDataDiskAssignment)

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::StreamingComputationRanges->new(
        computation_id => $value,
    );

=head1 FIELDS

=over 4

=item * B<computation_id>

Type: String

=item * B<range_assignments>

Type: Message (.google.dataflow.v1beta3.KeyRangeDataDiskAssignment)

=back

=cut

# === Message: Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig ===
    # Fields for StreamingApplianceSnapshotConfig
    # Field: snapshot_id Type: 9 ()
    # Field: import_state_endpoint Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Streaming;

    my $msg = Google::Dataflow::V1beta3::Streaming::StreamingApplianceSnapshotConfig->new(
        snapshot_id => $value,
    );

=head1 FIELDS

=over 4

=item * B<snapshot_id>

Type: String

=item * B<import_state_endpoint>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Streaming - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
