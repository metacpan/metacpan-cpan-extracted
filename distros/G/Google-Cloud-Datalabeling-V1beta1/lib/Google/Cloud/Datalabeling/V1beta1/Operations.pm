package Google::Cloud::Datalabeling::V1beta1::Operations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Datalabeling::V1beta1::Dataset };
    eval { require Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvb3BlcmF0aW9ucy5wcm90bxIh
Z29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExGi9nb29nbGUvY2xvdWQvZGF0YWxh
YmVsaW5nL3YxYmV0YTEvZGF0YXNldC5wcm90bxo/Z29vZ2xlL2Nsb3VkL2RhdGFsYWJlbGlu
Zy92MWJldGExL2h1bWFuX2Fubm90YXRpb25fY29uZmlnLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byJ7ChtJbXBvcnRE
YXRhT3BlcmF0aW9uUmVzcG9uc2USGAoHZGF0YXNldBgBIAEoCVIHZGF0YXNldBIfCgt0b3Rh
bF9jb3VudBgCIAEoBVIKdG90YWxDb3VudBIhCgxpbXBvcnRfY291bnQYAyABKAVSC2ltcG9y
dENvdW50IqECChtFeHBvcnREYXRhT3BlcmF0aW9uUmVzcG9uc2USGAoHZGF0YXNldBgBIAEo
CVIHZGF0YXNldBIfCgt0b3RhbF9jb3VudBgCIAEoBVIKdG90YWxDb3VudBIhCgxleHBvcnRf
Y291bnQYAyABKAVSC2V4cG9ydENvdW50Ek4KC2xhYmVsX3N0YXRzGAQgASgLMi0uZ29vZ2xl
LmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkxhYmVsU3RhdHNSCmxhYmVsU3RhdHMSVAoN
b3V0cHV0X2NvbmZpZxgFIAEoCzIvLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRh
MS5PdXRwdXRDb25maWdSDG91dHB1dENvbmZpZyKzAQobSW1wb3J0RGF0YU9wZXJhdGlvbk1l
dGFkYXRhEhgKB2RhdGFzZXQYASABKAlSB2RhdGFzZXQSPQoQcGFydGlhbF9mYWlsdXJlcxgC
IAMoCzISLmdvb2dsZS5ycGMuU3RhdHVzUg9wYXJ0aWFsRmFpbHVyZXMSOwoLY3JlYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lIrMBChtF
eHBvcnREYXRhT3BlcmF0aW9uTWV0YWRhdGESGAoHZGF0YXNldBgBIAEoCVIHZGF0YXNldBI9
ChBwYXJ0aWFsX2ZhaWx1cmVzGAIgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSD3BhcnRpYWxG
YWlsdXJlcxI7CgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSCmNyZWF0ZVRpbWUigw8KFkxhYmVsT3BlcmF0aW9uTWV0YWRhdGESkAEKHGltYWdlX2Ns
YXNzaWZpY2F0aW9uX2RldGFpbHMYAyABKAsyTC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5n
LnYxYmV0YTEuTGFiZWxJbWFnZUNsYXNzaWZpY2F0aW9uT3BlcmF0aW9uTWV0YWRhdGFIAFIa
aW1hZ2VDbGFzc2lmaWNhdGlvbkRldGFpbHMSiAEKGmltYWdlX2JvdW5kaW5nX2JveF9kZXRh
aWxzGAQgASgLMkkuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkxhYmVsSW1h
Z2VCb3VuZGluZ0JveE9wZXJhdGlvbk1ldGFkYXRhSABSF2ltYWdlQm91bmRpbmdCb3hEZXRh
aWxzEosBChtpbWFnZV9ib3VuZGluZ19wb2x5X2RldGFpbHMYCyABKAsySi5nb29nbGUuY2xv
dWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuTGFiZWxJbWFnZUJvdW5kaW5nUG9seU9wZXJhdGlv
bk1ldGFkYXRhSABSGGltYWdlQm91bmRpbmdQb2x5RGV0YWlscxKhAQojaW1hZ2Vfb3JpZW50
ZWRfYm91bmRpbmdfYm94X2RldGFpbHMYDiABKAsyUS5nb29nbGUuY2xvdWQuZGF0YWxhYmVs
aW5nLnYxYmV0YTEuTGFiZWxJbWFnZU9yaWVudGVkQm91bmRpbmdCb3hPcGVyYXRpb25NZXRh
ZGF0YUgAUh9pbWFnZU9yaWVudGVkQm91bmRpbmdCb3hEZXRhaWxzEn4KFmltYWdlX3BvbHls
aW5lX2RldGFpbHMYDCABKAsyRi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEu
TGFiZWxJbWFnZVBvbHlsaW5lT3BlcmF0aW9uTWV0YWRhdGFIAFIUaW1hZ2VQb2x5bGluZURl
dGFpbHMSigEKGmltYWdlX3NlZ21lbnRhdGlvbl9kZXRhaWxzGA8gASgLMkouZ29vZ2xlLmNs
b3VkLmRhdGFsYWJlbGluZy52MWJldGExLkxhYmVsSW1hZ2VTZWdtZW50YXRpb25PcGVyYXRp
b25NZXRhZGF0YUgAUhhpbWFnZVNlZ21lbnRhdGlvbkRldGFpbHMSkAEKHHZpZGVvX2NsYXNz
aWZpY2F0aW9uX2RldGFpbHMYBSABKAsyTC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYx
YmV0YTEuTGFiZWxWaWRlb0NsYXNzaWZpY2F0aW9uT3BlcmF0aW9uTWV0YWRhdGFIAFIadmlk
ZW9DbGFzc2lmaWNhdGlvbkRldGFpbHMSlAEKHnZpZGVvX29iamVjdF9kZXRlY3Rpb25fZGV0
YWlscxgGIAEoCzJNLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5MYWJlbFZp
ZGVvT2JqZWN0RGV0ZWN0aW9uT3BlcmF0aW9uTWV0YWRhdGFIAFIbdmlkZW9PYmplY3REZXRl
Y3Rpb25EZXRhaWxzEpEBCh12aWRlb19vYmplY3RfdHJhY2tpbmdfZGV0YWlscxgHIAEoCzJM
Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5MYWJlbFZpZGVvT2JqZWN0VHJh
Y2tpbmdPcGVyYXRpb25NZXRhZGF0YUgAUhp2aWRlb09iamVjdFRyYWNraW5nRGV0YWlscxJ1
ChN2aWRlb19ldmVudF9kZXRhaWxzGAggASgLMkMuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGlu
Zy52MWJldGExLkxhYmVsVmlkZW9FdmVudE9wZXJhdGlvbk1ldGFkYXRhSABSEXZpZGVvRXZl
bnREZXRhaWxzEo0BCht0ZXh0X2NsYXNzaWZpY2F0aW9uX2RldGFpbHMYCSABKAsySy5nb29n
bGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuTGFiZWxUZXh0Q2xhc3NpZmljYXRpb25P
cGVyYXRpb25NZXRhZGF0YUgAUhl0ZXh0Q2xhc3NpZmljYXRpb25EZXRhaWxzEpQBCh50ZXh0
X2VudGl0eV9leHRyYWN0aW9uX2RldGFpbHMYDSABKAsyTS5nb29nbGUuY2xvdWQuZGF0YWxh
YmVsaW5nLnYxYmV0YTEuTGFiZWxUZXh0RW50aXR5RXh0cmFjdGlvbk9wZXJhdGlvbk1ldGFk
YXRhSABSG3RleHRFbnRpdHlFeHRyYWN0aW9uRGV0YWlscxIpChBwcm9ncmVzc19wZXJjZW50
GAEgASgFUg9wcm9ncmVzc1BlcmNlbnQSPQoQcGFydGlhbF9mYWlsdXJlcxgCIAMoCzISLmdv
b2dsZS5ycGMuU3RhdHVzUg9wYXJ0aWFsRmFpbHVyZXMSOwoLY3JlYXRlX3RpbWUYECABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lQgkKB2RldGFpbHMiiAEK
KUxhYmVsSW1hZ2VDbGFzc2lmaWNhdGlvbk9wZXJhdGlvbk1ldGFkYXRhElsKDGJhc2ljX2Nv
bmZpZxgBIAEoCzI4Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5IdW1hbkFu
bm90YXRpb25Db25maWdSC2Jhc2ljQ29uZmlnIoUBCiZMYWJlbEltYWdlQm91bmRpbmdCb3hP
cGVyYXRpb25NZXRhZGF0YRJbCgxiYXNpY19jb25maWcYASABKAsyOC5nb29nbGUuY2xvdWQu
ZGF0YWxhYmVsaW5nLnYxYmV0YTEuSHVtYW5Bbm5vdGF0aW9uQ29uZmlnUgtiYXNpY0NvbmZp
ZyKNAQouTGFiZWxJbWFnZU9yaWVudGVkQm91bmRpbmdCb3hPcGVyYXRpb25NZXRhZGF0YRJb
CgxiYXNpY19jb25maWcYASABKAsyOC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuSHVtYW5Bbm5vdGF0aW9uQ29uZmlnUgtiYXNpY0NvbmZpZyKGAQonTGFiZWxJbWFnZUJv
dW5kaW5nUG9seU9wZXJhdGlvbk1ldGFkYXRhElsKDGJhc2ljX2NvbmZpZxgBIAEoCzI4Lmdv
b2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5IdW1hbkFubm90YXRpb25Db25maWdS
C2Jhc2ljQ29uZmlnIoIBCiNMYWJlbEltYWdlUG9seWxpbmVPcGVyYXRpb25NZXRhZGF0YRJb
CgxiYXNpY19jb25maWcYASABKAsyOC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuSHVtYW5Bbm5vdGF0aW9uQ29uZmlnUgtiYXNpY0NvbmZpZyKGAQonTGFiZWxJbWFnZVNl
Z21lbnRhdGlvbk9wZXJhdGlvbk1ldGFkYXRhElsKDGJhc2ljX2NvbmZpZxgBIAEoCzI4Lmdv
b2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5IdW1hbkFubm90YXRpb25Db25maWdS
C2Jhc2ljQ29uZmlnIogBCilMYWJlbFZpZGVvQ2xhc3NpZmljYXRpb25PcGVyYXRpb25NZXRh
ZGF0YRJbCgxiYXNpY19jb25maWcYASABKAsyOC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5n
LnYxYmV0YTEuSHVtYW5Bbm5vdGF0aW9uQ29uZmlnUgtiYXNpY0NvbmZpZyKJAQoqTGFiZWxW
aWRlb09iamVjdERldGVjdGlvbk9wZXJhdGlvbk1ldGFkYXRhElsKDGJhc2ljX2NvbmZpZxgB
IAEoCzI4Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5IdW1hbkFubm90YXRp
b25Db25maWdSC2Jhc2ljQ29uZmlnIogBCilMYWJlbFZpZGVvT2JqZWN0VHJhY2tpbmdPcGVy
YXRpb25NZXRhZGF0YRJbCgxiYXNpY19jb25maWcYASABKAsyOC5nb29nbGUuY2xvdWQuZGF0
YWxhYmVsaW5nLnYxYmV0YTEuSHVtYW5Bbm5vdGF0aW9uQ29uZmlnUgtiYXNpY0NvbmZpZyJ/
CiBMYWJlbFZpZGVvRXZlbnRPcGVyYXRpb25NZXRhZGF0YRJbCgxiYXNpY19jb25maWcYASAB
KAsyOC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuSHVtYW5Bbm5vdGF0aW9u
Q29uZmlnUgtiYXNpY0NvbmZpZyKHAQooTGFiZWxUZXh0Q2xhc3NpZmljYXRpb25PcGVyYXRp
b25NZXRhZGF0YRJbCgxiYXNpY19jb25maWcYASABKAsyOC5nb29nbGUuY2xvdWQuZGF0YWxh
YmVsaW5nLnYxYmV0YTEuSHVtYW5Bbm5vdGF0aW9uQ29uZmlnUgtiYXNpY0NvbmZpZyKJAQoq
TGFiZWxUZXh0RW50aXR5RXh0cmFjdGlvbk9wZXJhdGlvbk1ldGFkYXRhElsKDGJhc2ljX2Nv
bmZpZxgBIAEoCzI4Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5IdW1hbkFu
bm90YXRpb25Db25maWdSC2Jhc2ljQ29uZmlnIrkBChlDcmVhdGVJbnN0cnVjdGlvbk1ldGFk
YXRhEiAKC2luc3RydWN0aW9uGAEgASgJUgtpbnN0cnVjdGlvbhI9ChBwYXJ0aWFsX2ZhaWx1
cmVzGAIgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSD3BhcnRpYWxGYWlsdXJlcxI7CgtjcmVh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWVC
4wEKJWNvbS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTFQAVpJY2xvdWQuZ29v
Z2xlLmNvbS9nby9kYXRhbGFiZWxpbmcvYXBpdjFiZXRhMS9kYXRhbGFiZWxpbmdwYjtkYXRh
bGFiZWxpbmdwYqoCIUdvb2dsZS5DbG91ZC5EYXRhTGFiZWxpbmcuVjFCZXRhMcoCIUdvb2ds
ZVxDbG91ZFxEYXRhTGFiZWxpbmdcVjFiZXRhMeoCJEdvb2dsZTo6Q2xvdWQ6OkRhdGFMYWJl
bGluZzo6VjFiZXRhMUr7PAoHEgUPAOcBAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCgoICgECEgMRACoKCQoCAwASAxMAOQoJCgIDARIDFABJCgkKAgMCEgMVACkKCQoC
AwMSAxYAIQoICgEIEgMYAD4KCQoCCCUSAxgAPgoICgEIEgMZAGAKCQoCCAsSAxkAYAoICgEI
EgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAD4KCQoCCAESAxsAPgoICgEIEgMcAD4KCQoCCCkS
AxwAPgoICgEIEgMdAD0KCQoCCC0SAx0APQpBCgIEABIEIAApARo1IFJlc3BvbnNlIHVzZWQg
Zm9yIEltcG9ydERhdGEgbG9uZ3J1bm5pbmcgb3BlcmF0aW9uLgoKCgoDBAABEgMgCCMKOQoE
BAACABIDIgIVGiwgT3VwdHV0IG9ubHkuIFRoZSBuYW1lIG9mIGltcG9ydGVkIGRhdGFzZXQu
CgoMCgUEAAIABRIDIgIICgwKBQQAAgABEgMiCRAKDAoFBAACAAMSAyITFApICgQEAAIBEgMl
AhgaOyBPdXRwdXQgb25seS4gVG90YWwgbnVtYmVyIG9mIGV4YW1wbGVzIHJlcXVlc3RlZCB0
byBpbXBvcnQKCgwKBQQAAgEFEgMlAgcKDAoFBAACAQESAyUIEwoMCgUEAAIBAxIDJRYXCkUK
BAQAAgISAygCGRo4IE91dHB1dCBvbmx5LiBOdW1iZXIgb2YgZXhhbXBsZXMgaW1wb3J0ZWQg
c3VjY2Vzc2Z1bGx5LgoKDAoFBAACAgUSAygCBwoMCgUEAAICARIDKAgUCgwKBQQAAgIDEgMo
FxgKRAoCBAESBCwAPAEaOCBSZXNwb25zZSB1c2VkIGZvciBFeHBvcnREYXRhc2V0IGxvbmdy
dW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQBARIDLAgjCkkKBAQBAgASAy8CFRo8IE91cHR1dCBv
bmx5LiBUaGUgbmFtZSBvZiBkYXRhc2V0LgogInByb2plY3RzLyovZGF0YXNldHMvKiIKCgwK
BQQBAgAFEgMvAggKDAoFBAECAAESAy8JEAoMCgUEAQIAAxIDLxMUCkgKBAQBAgESAzICGBo7
IE91dHB1dCBvbmx5LiBUb3RhbCBudW1iZXIgb2YgZXhhbXBsZXMgcmVxdWVzdGVkIHRvIGV4
cG9ydAoKDAoFBAECAQUSAzICBwoMCgUEAQIBARIDMggTCgwKBQQBAgEDEgMyFhcKRQoEBAEC
AhIDNQIZGjggT3V0cHV0IG9ubHkuIE51bWJlciBvZiBleGFtcGxlcyBleHBvcnRlZCBzdWNj
ZXNzZnVsbHkuCgoMCgUEAQICBRIDNQIHCgwKBQQBAgIBEgM1CBQKDAoFBAECAgMSAzUXGApO
CgQEAQIDEgM4Ah0aQSBPdXRwdXQgb25seS4gU3RhdGlzdGljIGluZm9zIG9mIGxhYmVscyBp
biB0aGUgZXhwb3J0ZWQgZGF0YXNldC4KCgwKBQQBAgMGEgM4AgwKDAoFBAECAwESAzgNGAoM
CgUEAQIDAxIDOBscCkQKBAQBAgQSAzsCIRo3IE91dHB1dCBvbmx5LiBvdXRwdXRfY29uZmln
IGluIHRoZSBFeHBvcnREYXRhIHJlcXVlc3QuCgoMCgUEAQIEBhIDOwIOCgwKBQQBAgQBEgM7
DxwKDAoFBAECBAMSAzsfIAoyCgIEAhIEPwBLARomIE1ldGFkYXRhIG9mIGFuIEltcG9ydERh
dGEgb3BlcmF0aW9uLgoKCgoDBAIBEgM/CCMKUgoEBAICABIDQgIVGkUgT3V0cHV0IG9ubHku
IFRoZSBuYW1lIG9mIGltcG9ydGVkIGRhdGFzZXQuCiAicHJvamVjdHMvKi9kYXRhc2V0cy8q
IgoKDAoFBAICAAUSA0ICCAoMCgUEAgIAARIDQgkQCgwKBQQCAgADEgNCExQKowEKBAQCAgES
A0cCMhqVASBPdXRwdXQgb25seS4gUGFydGlhbCBmYWlsdXJlcyBlbmNvdW50ZXJlZC4KIEUu
Zy4gc2luZ2xlIGZpbGVzIHRoYXQgY291bGRuJ3QgYmUgcmVhZC4KIFN0YXR1cyBkZXRhaWxz
IGZpZWxkIHdpbGwgY29udGFpbiBzdGFuZGFyZCBHQ1AgZXJyb3IgZGV0YWlscy4KCgwKBQQC
AgEEEgNHAgoKDAoFBAICAQYSA0cLHAoMCgUEAgIBARIDRx0tCgwKBQQCAgEDEgNHMDEKTgoE
BAICAhIDSgIsGkEgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIGltcG9ydCBkYXRhc2V0
IHJlcXVlc3Qgd2FzIGNyZWF0ZWQuCgoMCgUEAgICBhIDSgIbCgwKBQQCAgIBEgNKHCcKDAoF
BAICAgMSA0oqKwoyCgIEAxIETgBaARomIE1ldGFkYXRhIG9mIGFuIEV4cG9ydERhdGEgb3Bl
cmF0aW9uLgoKCgoDBAMBEgNOCCMKWAoEBAMCABIDUQIVGksgT3V0cHV0IG9ubHkuIFRoZSBu
YW1lIG9mIGRhdGFzZXQgdG8gYmUgZXhwb3J0ZWQuCiAicHJvamVjdHMvKi9kYXRhc2V0cy8q
IgoKDAoFBAMCAAUSA1ECCAoMCgUEAwIAARIDUQkQCgwKBQQDAgADEgNRExQKowEKBAQDAgES
A1YCMhqVASBPdXRwdXQgb25seS4gUGFydGlhbCBmYWlsdXJlcyBlbmNvdW50ZXJlZC4KIEUu
Zy4gc2luZ2xlIGZpbGVzIHRoYXQgY291bGRuJ3QgYmUgcmVhZC4KIFN0YXR1cyBkZXRhaWxz
IGZpZWxkIHdpbGwgY29udGFpbiBzdGFuZGFyZCBHQ1AgZXJyb3IgZGV0YWlscy4KCgwKBQQD
AgEEEgNWAgoKDAoFBAMCAQYSA1YLHAoMCgUEAwIBARIDVh0tCgwKBQQDAgEDEgNWMDEKTgoE
BAMCAhIDWQIsGkEgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIGV4cG9ydCBkYXRhc2V0
IHJlcXVlc3Qgd2FzIGNyZWF0ZWQuCgoMCgUEAwICBhIDWQIbCgwKBQQDAgIBEgNZHCcKDAoF
BAMCAgMSA1kqKwpgCgIEBBIFXgCQAQEaUyBNZXRhZGF0YSBvZiBhIGxhYmVsaW5nIG9wZXJh
dGlvbiwgc3VjaCBhcyBMYWJlbEltYWdlIG9yIExhYmVsVmlkZW8uCiBOZXh0IHRhZzogMjAK
CgoKAwQEARIDXggeCkIKBAQECAASBWAChAEDGjMgT3VwdHV0IG9ubHkuIERldGFpbHMgb2Yg
c3BlY2lmaWMgbGFiZWwgb3BlcmF0aW9uLgoKDAoFBAQIAAESA2AIDwo/CgQEBAIAEgNiBE8a
MiBEZXRhaWxzIG9mIGxhYmVsIGltYWdlIGNsYXNzaWZpY2F0aW9uIG9wZXJhdGlvbi4KCgwK
BQQEAgAGEgNiBC0KDAoFBAQCAAESA2IuSgoMCgUEBAIAAxIDYk1OCj0KBAQEAgESA2UEShow
IERldGFpbHMgb2YgbGFiZWwgaW1hZ2UgYm91bmRpbmcgYm94IG9wZXJhdGlvbi4KCgwKBQQE
AgEGEgNlBCoKDAoFBAQCAQESA2UrRQoMCgUEBAIBAxIDZUhJCj4KBAQEAgISA2gETRoxIERl
dGFpbHMgb2YgbGFiZWwgaW1hZ2UgYm91bmRpbmcgcG9seSBvcGVyYXRpb24uCgoMCgUEBAIC
BhIDaAQrCgwKBQQEAgIBEgNoLEcKDAoFBAQCAgMSA2hKTApGCgQEBAIDEgNrBFwaOSBEZXRh
aWxzIG9mIGxhYmVsIGltYWdlIG9yaWVudGVkIGJvdW5kaW5nIGJveCBvcGVyYXRpb24uCgoM
CgUEBAIDBhIDawQyCgwKBQQEAgMBEgNrM1YKDAoFBAQCAwMSA2tZWwo5CgQEBAIEEgNuBEQa
LCBEZXRhaWxzIG9mIGxhYmVsIGltYWdlIHBvbHlsaW5lIG9wZXJhdGlvbi4KCgwKBQQEAgQG
EgNuBCcKDAoFBAQCBAESA24oPgoMCgUEBAIEAxIDbkFDCj0KBAQEAgUSA3EETBowIERldGFp
bHMgb2YgbGFiZWwgaW1hZ2Ugc2VnbWVudGF0aW9uIG9wZXJhdGlvbi4KCgwKBQQEAgUGEgNx
BCsKDAoFBAQCBQESA3EsRgoMCgUEBAIFAxIDcUlLCj8KBAQEAgYSA3QETxoyIERldGFpbHMg
b2YgbGFiZWwgdmlkZW8gY2xhc3NpZmljYXRpb24gb3BlcmF0aW9uLgoKDAoFBAQCBgYSA3QE
LQoMCgUEBAIGARIDdC5KCgwKBQQEAgYDEgN0TU4KQQoEBAQCBxIDdwRSGjQgRGV0YWlscyBv
ZiBsYWJlbCB2aWRlbyBvYmplY3QgZGV0ZWN0aW9uIG9wZXJhdGlvbi4KCgwKBQQEAgcGEgN3
BC4KDAoFBAQCBwESA3cvTQoMCgUEBAIHAxIDd1BRCkAKBAQEAggSA3oEUBozIERldGFpbHMg
b2YgbGFiZWwgdmlkZW8gb2JqZWN0IHRyYWNraW5nIG9wZXJhdGlvbi4KCgwKBQQEAggGEgN6
BC0KDAoFBAQCCAESA3ouSwoMCgUEBAIIAxIDek5PCjYKBAQEAgkSA30EPRopIERldGFpbHMg
b2YgbGFiZWwgdmlkZW8gZXZlbnQgb3BlcmF0aW9uLgoKDAoFBAQCCQYSA30EJAoMCgUEBAIJ
ARIDfSU4CgwKBQQEAgkDEgN9OzwKPwoEBAQCChIEgAEETRoxIERldGFpbHMgb2YgbGFiZWwg
dGV4dCBjbGFzc2lmaWNhdGlvbiBvcGVyYXRpb24uCgoNCgUEBAIKBhIEgAEELAoNCgUEBAIK
ARIEgAEtSAoNCgUEBAIKAxIEgAFLTApCCgQEBAILEgSDAQRTGjQgRGV0YWlscyBvZiBsYWJl
bCB0ZXh0IGVudGl0eSBleHRyYWN0aW9uIG9wZXJhdGlvbi4KCg0KBQQEAgsGEgSDAQQuCg0K
BQQEAgsBEgSDAS9NCg0KBQQEAgsDEgSDAVBSCkoKBAQEAgwSBIcBAh0aPCBPdXRwdXQgb25s
eS4gUHJvZ3Jlc3Mgb2YgbGFiZWwgb3BlcmF0aW9uLiBSYW5nZTogWzAsIDEwMF0uCgoNCgUE
BAIMBRIEhwECBwoNCgUEBAIMARIEhwEIGAoNCgUEBAIMAxIEhwEbHAqkAQoEBAQCDRIEjAEC
MhqVASBPdXRwdXQgb25seS4gUGFydGlhbCBmYWlsdXJlcyBlbmNvdW50ZXJlZC4KIEUuZy4g
c2luZ2xlIGZpbGVzIHRoYXQgY291bGRuJ3QgYmUgcmVhZC4KIFN0YXR1cyBkZXRhaWxzIGZp
ZWxkIHdpbGwgY29udGFpbiBzdGFuZGFyZCBHQ1AgZXJyb3IgZGV0YWlscy4KCg0KBQQEAg0E
EgSMAQIKCg0KBQQEAg0GEgSMAQscCg0KBQQEAg0BEgSMAR0tCg0KBQQEAg0DEgSMATAxCkkK
BAQEAg4SBI8BAi0aOyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gbGFiZWxpbmcgcmVx
dWVzdCB3YXMgY3JlYXRlZC4KCg0KBQQEAg4GEgSPAQIbCg0KBQQEAg4BEgSPARwnCg0KBQQE
Ag4DEgSPASosCkEKAgQFEgaTAQCWAQEaMyBNZXRhZGF0YSBvZiBhIExhYmVsSW1hZ2VDbGFz
c2lmaWNhdGlvbiBvcGVyYXRpb24uCgoLCgMEBQESBJMBCDEKRwoEBAUCABIElQECKRo5IEJh
c2ljIGh1bWFuIGFubm90YXRpb24gY29uZmlnIHVzZWQgaW4gbGFiZWxpbmcgcmVxdWVzdC4K
Cg0KBQQFAgAGEgSVAQIXCg0KBQQFAgABEgSVARgkCg0KBQQFAgADEgSVAScoCkYKAgQGEgaZ
AQCcAQEaOCBEZXRhaWxzIG9mIGEgTGFiZWxJbWFnZUJvdW5kaW5nQm94IG9wZXJhdGlvbiBt
ZXRhZGF0YS4KCgsKAwQGARIEmQEILgpHCgQEBgIAEgSbAQIpGjkgQmFzaWMgaHVtYW4gYW5u
b3RhdGlvbiBjb25maWcgdXNlZCBpbiBsYWJlbGluZyByZXF1ZXN0LgoKDQoFBAYCAAYSBJsB
AhcKDQoFBAYCAAESBJsBGCQKDQoFBAYCAAMSBJsBJygKTgoCBAcSBp8BAKIBARpAIERldGFp
bHMgb2YgYSBMYWJlbEltYWdlT3JpZW50ZWRCb3VuZGluZ0JveCBvcGVyYXRpb24gbWV0YWRh
dGEuCgoLCgMEBwESBJ8BCDYKLgoEBAcCABIEoQECKRogIEJhc2ljIGh1bWFuIGFubm90YXRp
b24gY29uZmlnLgoKDQoFBAcCAAYSBKEBAhcKDQoFBAcCAAESBKEBGCQKDQoFBAcCAAMSBKEB
JygKRQoCBAgSBqUBAKgBARo3IERldGFpbHMgb2YgTGFiZWxJbWFnZUJvdW5kaW5nUG9seSBv
cGVyYXRpb24gbWV0YWRhdGEuCgoLCgMECAESBKUBCC8KRwoEBAgCABIEpwECKRo5IEJhc2lj
IGh1bWFuIGFubm90YXRpb24gY29uZmlnIHVzZWQgaW4gbGFiZWxpbmcgcmVxdWVzdC4KCg0K
BQQIAgAGEgSnAQIXCg0KBQQIAgABEgSnARgkCg0KBQQIAgADEgSnAScoCkEKAgQJEgarAQCu
AQEaMyBEZXRhaWxzIG9mIExhYmVsSW1hZ2VQb2x5bGluZSBvcGVyYXRpb24gbWV0YWRhdGEu
CgoLCgMECQESBKsBCCsKRwoEBAkCABIErQECKRo5IEJhc2ljIGh1bWFuIGFubm90YXRpb24g
Y29uZmlnIHVzZWQgaW4gbGFiZWxpbmcgcmVxdWVzdC4KCg0KBQQJAgAGEgStAQIXCg0KBQQJ
AgABEgStARgkCg0KBQQJAgADEgStAScoCkcKAgQKEgaxAQC0AQEaOSBEZXRhaWxzIG9mIGEg
TGFiZWxJbWFnZVNlZ21lbnRhdGlvbiBvcGVyYXRpb24gbWV0YWRhdGEuCgoLCgMECgESBLEB
CC8KLgoEBAoCABIEswECKRogIEJhc2ljIGh1bWFuIGFubm90YXRpb24gY29uZmlnLgoKDQoF
BAoCAAYSBLMBAhcKDQoFBAoCAAESBLMBGCQKDQoFBAoCAAMSBLMBJygKSQoCBAsSBrcBALoB
ARo7IERldGFpbHMgb2YgYSBMYWJlbFZpZGVvQ2xhc3NpZmljYXRpb24gb3BlcmF0aW9uIG1l
dGFkYXRhLgoKCwoDBAsBEgS3AQgxCkcKBAQLAgASBLkBAikaOSBCYXNpYyBodW1hbiBhbm5v
dGF0aW9uIGNvbmZpZyB1c2VkIGluIGxhYmVsaW5nIHJlcXVlc3QuCgoNCgUECwIABhIEuQEC
FwoNCgUECwIAARIEuQEYJAoNCgUECwIAAxIEuQEnKApKCgIEDBIGvQEAwAEBGjwgRGV0YWls
cyBvZiBhIExhYmVsVmlkZW9PYmplY3REZXRlY3Rpb24gb3BlcmF0aW9uIG1ldGFkYXRhLgoK
CwoDBAwBEgS9AQgyCkcKBAQMAgASBL8BAikaOSBCYXNpYyBodW1hbiBhbm5vdGF0aW9uIGNv
bmZpZyB1c2VkIGluIGxhYmVsaW5nIHJlcXVlc3QuCgoNCgUEDAIABhIEvwECFwoNCgUEDAIA
ARIEvwEYJAoNCgUEDAIAAxIEvwEnKApJCgIEDRIGwwEAxgEBGjsgRGV0YWlscyBvZiBhIExh
YmVsVmlkZW9PYmplY3RUcmFja2luZyBvcGVyYXRpb24gbWV0YWRhdGEuCgoLCgMEDQESBMMB
CDEKRwoEBA0CABIExQECKRo5IEJhc2ljIGh1bWFuIGFubm90YXRpb24gY29uZmlnIHVzZWQg
aW4gbGFiZWxpbmcgcmVxdWVzdC4KCg0KBQQNAgAGEgTFAQIXCg0KBQQNAgABEgTFARgkCg0K
BQQNAgADEgTFAScoCkAKAgQOEgbJAQDMAQEaMiBEZXRhaWxzIG9mIGEgTGFiZWxWaWRlb0V2
ZW50IG9wZXJhdGlvbiBtZXRhZGF0YS4KCgsKAwQOARIEyQEIKApHCgQEDgIAEgTLAQIpGjkg
QmFzaWMgaHVtYW4gYW5ub3RhdGlvbiBjb25maWcgdXNlZCBpbiBsYWJlbGluZyByZXF1ZXN0
LgoKDQoFBA4CAAYSBMsBAhcKDQoFBA4CAAESBMsBGCQKDQoFBA4CAAMSBMsBJygKSAoCBA8S
Bs8BANIBARo6IERldGFpbHMgb2YgYSBMYWJlbFRleHRDbGFzc2lmaWNhdGlvbiBvcGVyYXRp
b24gbWV0YWRhdGEuCgoLCgMEDwESBM8BCDAKRwoEBA8CABIE0QECKRo5IEJhc2ljIGh1bWFu
IGFubm90YXRpb24gY29uZmlnIHVzZWQgaW4gbGFiZWxpbmcgcmVxdWVzdC4KCg0KBQQPAgAG
EgTRAQIXCg0KBQQPAgABEgTRARgkCg0KBQQPAgADEgTRAScoCkoKAgQQEgbVAQDYAQEaPCBE
ZXRhaWxzIG9mIGEgTGFiZWxUZXh0RW50aXR5RXh0cmFjdGlvbiBvcGVyYXRpb24gbWV0YWRh
dGEuCgoLCgMEEAESBNUBCDIKRwoEBBACABIE1wECKRo5IEJhc2ljIGh1bWFuIGFubm90YXRp
b24gY29uZmlnIHVzZWQgaW4gbGFiZWxpbmcgcmVxdWVzdC4KCg0KBQQQAgAGEgTXAQIXCg0K
BQQQAgABEgTXARgkCg0KBQQQAgADEgTXAScoCjoKAgQREgbbAQDnAQEaLCBNZXRhZGF0YSBv
ZiBhIENyZWF0ZUluc3RydWN0aW9uIG9wZXJhdGlvbi4KCgsKAwQRARIE2wEIIQppCgQEEQIA
EgTeAQIZGlsgVGhlIG5hbWUgb2YgdGhlIGNyZWF0ZWQgSW5zdHJ1Y3Rpb24uCiBwcm9qZWN0
cy97cHJvamVjdF9pZH0vaW5zdHJ1Y3Rpb25zL3tpbnN0cnVjdGlvbl9pZH0KCg0KBQQRAgAF
EgTeAQIICg0KBQQRAgABEgTeAQkUCg0KBQQRAgADEgTeARcYCpcBCgQEEQIBEgTjAQIyGogB
IFBhcnRpYWwgZmFpbHVyZXMgZW5jb3VudGVyZWQuCiBFLmcuIHNpbmdsZSBmaWxlcyB0aGF0
IGNvdWxkbid0IGJlIHJlYWQuCiBTdGF0dXMgZGV0YWlscyBmaWVsZCB3aWxsIGNvbnRhaW4g
c3RhbmRhcmQgR0NQIGVycm9yIGRldGFpbHMuCgoNCgUEEQIBBBIE4wECCgoNCgUEEQIBBhIE
4wELHAoNCgUEEQIBARIE4wEdLQoNCgUEEQIBAxIE4wEwMQpGCgQEEQICEgTmAQIsGjggVGlt
ZXN0YW1wIHdoZW4gY3JlYXRlIGluc3RydWN0aW9uIHJlcXVlc3Qgd2FzIGNyZWF0ZWQuCgoN
CgUEEQICBhIE5gECGwoNCgUEEQICARIE5gEcJwoNCgUEEQICAxIE5gEqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse ===
    # Fields for ImportDataOperationResponse
    # Field: dataset Type: 9 ()
    # Field: total_count Type: 5 ()
    # Field: import_count Type: 5 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationResponse ===
    # Fields for ExportDataOperationResponse
    # Field: dataset Type: 9 ()
    # Field: total_count Type: 5 ()
    # Field: export_count Type: 5 ()
    # Field: label_stats Type: 11 (.google.cloud.datalabeling.v1beta1.LabelStats)
    # Field: output_config Type: 11 (.google.cloud.datalabeling.v1beta1.OutputConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationMetadata ===
    # Fields for ImportDataOperationMetadata
    # Field: dataset Type: 9 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationMetadata ===
    # Fields for ExportDataOperationMetadata
    # Field: dataset Type: 9 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelOperationMetadata ===
    # Fields for LabelOperationMetadata
    # Field: image_classification_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelImageClassificationOperationMetadata)
    # Field: image_bounding_box_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelImageBoundingBoxOperationMetadata)
    # Field: image_bounding_poly_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelImageBoundingPolyOperationMetadata)
    # Field: image_oriented_bounding_box_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelImageOrientedBoundingBoxOperationMetadata)
    # Field: image_polyline_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelImagePolylineOperationMetadata)
    # Field: image_segmentation_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelImageSegmentationOperationMetadata)
    # Field: video_classification_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelVideoClassificationOperationMetadata)
    # Field: video_object_detection_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelVideoObjectDetectionOperationMetadata)
    # Field: video_object_tracking_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelVideoObjectTrackingOperationMetadata)
    # Field: video_event_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelVideoEventOperationMetadata)
    # Field: text_classification_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelTextClassificationOperationMetadata)
    # Field: text_entity_extraction_details Type: 11 (.google.cloud.datalabeling.v1beta1.LabelTextEntityExtractionOperationMetadata)
    # Field: progress_percent Type: 5 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageClassificationOperationMetadata ===
    # Fields for LabelImageClassificationOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingBoxOperationMetadata ===
    # Fields for LabelImageBoundingBoxOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageOrientedBoundingBoxOperationMetadata ===
    # Fields for LabelImageOrientedBoundingBoxOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingPolyOperationMetadata ===
    # Fields for LabelImageBoundingPolyOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelImagePolylineOperationMetadata ===
    # Fields for LabelImagePolylineOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageSegmentationOperationMetadata ===
    # Fields for LabelImageSegmentationOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoClassificationOperationMetadata ===
    # Fields for LabelVideoClassificationOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectDetectionOperationMetadata ===
    # Fields for LabelVideoObjectDetectionOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectTrackingOperationMetadata ===
    # Fields for LabelVideoObjectTrackingOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoEventOperationMetadata ===
    # Fields for LabelVideoEventOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextClassificationOperationMetadata ===
    # Fields for LabelTextClassificationOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextEntityExtractionOperationMetadata ===
    # Fields for LabelTextEntityExtractionOperationMetadata
    # Field: basic_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Operations::CreateInstructionMetadata ===
    # Fields for CreateInstructionMetadata
    # Field: instruction Type: 9 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Operations - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::Operations;

    my $msg = Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse->new({
        dataset => $dataset,
        total_count => $total_count,
        import_count => $import_count,
    });

    # Read or update a field
    my $val = $msg->dataset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse

Response used for ImportData longrunning operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Ouptut only. The name of imported dataset.

=item * C<< $msg->total_count() >> / C<< $msg->total_count($value) >>

Type: C<Int32>

Output only. Total number of examples requested to import

=item * C<< $msg->import_count() >> / C<< $msg->import_count($value) >>

Type: C<Int32>

Output only. Number of examples imported successfully.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationResponse

Response used for ExportDataset longrunning operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Ouptut only. The name of dataset.
"projects/*/datasets/*"

=item * C<< $msg->total_count() >> / C<< $msg->total_count($value) >>

Type: C<Int32>

Output only. Total number of examples requested to export

=item * C<< $msg->export_count() >> / C<< $msg->export_count($value) >>

Type: C<Int32>

Output only. Number of examples exported successfully.

=item * C<< $msg->label_stats() >> / C<< $msg->label_stats($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats>)

Output only. Statistic infos of labels in the exported dataset.

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::OutputConfig>)

Output only. output_config in the ExportData request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationMetadata

Metadata of an ImportData operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Output only. The name of imported dataset.
"projects/*/datasets/*"

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Partial failures encountered.
E.g. single files that couldn't be read.
Status details field will contain standard GCP error details.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when import dataset request was created.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationMetadata

Metadata of an ExportData operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Output only. The name of dataset to be exported.
"projects/*/datasets/*"

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Partial failures encountered.
E.g. single files that couldn't be read.
Status details field will contain standard GCP error details.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when export dataset request was created.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelOperationMetadata

Metadata of a labeling operation, such as LabelImage or LabelVideo.
Next tag: 20

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_classification_details() >> / C<< $msg->image_classification_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageClassificationOperationMetadata>)

Details of label image classification operation.

=item * C<< $msg->image_bounding_box_details() >> / C<< $msg->image_bounding_box_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingBoxOperationMetadata>)

Details of label image bounding box operation.

=item * C<< $msg->image_bounding_poly_details() >> / C<< $msg->image_bounding_poly_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingPolyOperationMetadata>)

Details of label image bounding poly operation.

=item * C<< $msg->image_oriented_bounding_box_details() >> / C<< $msg->image_oriented_bounding_box_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageOrientedBoundingBoxOperationMetadata>)

Details of label image oriented bounding box operation.

=item * C<< $msg->image_polyline_details() >> / C<< $msg->image_polyline_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelImagePolylineOperationMetadata>)

Details of label image polyline operation.

=item * C<< $msg->image_segmentation_details() >> / C<< $msg->image_segmentation_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageSegmentationOperationMetadata>)

Details of label image segmentation operation.

=item * C<< $msg->video_classification_details() >> / C<< $msg->video_classification_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoClassificationOperationMetadata>)

Details of label video classification operation.

=item * C<< $msg->video_object_detection_details() >> / C<< $msg->video_object_detection_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectDetectionOperationMetadata>)

Details of label video object detection operation.

=item * C<< $msg->video_object_tracking_details() >> / C<< $msg->video_object_tracking_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectTrackingOperationMetadata>)

Details of label video object tracking operation.

=item * C<< $msg->video_event_details() >> / C<< $msg->video_event_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoEventOperationMetadata>)

Details of label video event operation.

=item * C<< $msg->text_classification_details() >> / C<< $msg->text_classification_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextClassificationOperationMetadata>)

Details of label text classification operation.

=item * C<< $msg->text_entity_extraction_details() >> / C<< $msg->text_entity_extraction_details($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextEntityExtractionOperationMetadata>)

Details of label text entity extraction operation.

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Output only. Progress of label operation. Range: [0, 100].

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Partial failures encountered.
E.g. single files that couldn't be read.
Status details field will contain standard GCP error details.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when labeling request was created.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageClassificationOperationMetadata

Metadata of a LabelImageClassification operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingBoxOperationMetadata

Details of a LabelImageBoundingBox operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageOrientedBoundingBoxOperationMetadata

Details of a LabelImageOrientedBoundingBox operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingPolyOperationMetadata

Details of LabelImageBoundingPoly operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelImagePolylineOperationMetadata

Details of LabelImagePolyline operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageSegmentationOperationMetadata

Details of a LabelImageSegmentation operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoClassificationOperationMetadata

Details of a LabelVideoClassification operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectDetectionOperationMetadata

Details of a LabelVideoObjectDetection operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectTrackingOperationMetadata

Details of a LabelVideoObjectTracking operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoEventOperationMetadata

Details of a LabelVideoEvent operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextClassificationOperationMetadata

Details of a LabelTextClassification operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextEntityExtractionOperationMetadata

Details of a LabelTextEntityExtraction operation metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->basic_config() >> / C<< $msg->basic_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Basic human annotation config used in labeling request.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Operations::CreateInstructionMetadata

Metadata of a CreateInstruction operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instruction() >> / C<< $msg->instruction($value) >>

Type: C<String>

The name of the created Instruction.
projects/{project_id}/instructions/{instruction_id}

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Partial failures encountered.
E.g. single files that couldn't be read.
Status details field will contain standard GCP error details.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when create instruction request was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
