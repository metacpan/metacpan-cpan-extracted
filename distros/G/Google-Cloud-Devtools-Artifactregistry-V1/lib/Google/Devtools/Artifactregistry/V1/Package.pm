package Google::Devtools::Artifactregistry::V1::Package;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9wYWNrYWdlLnByb3RvEiNn
b29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3Rv
YnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
5QMKB1BhY2thZ2USEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlS
C2Rpc3BsYXlOYW1lEjsKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSZAoLYW5ub3RhdGlvbnMYByADKAsyPS5nb29n
bGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5QYWNrYWdlLkFubm90YXRpb25zRW50
cnlCA+BBAVILYW5ub3RhdGlvbnMaPgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlS
A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOoIB6kF/CidhcnRpZmFjdHJlZ2lzdHJ5
Lmdvb2dsZWFwaXMuY29tL1BhY2thZ2USVHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9yZXBvc2l0b3JpZXMve3JlcG9zaXRvcnl9L3BhY2thZ2VzL3twYWNrYWdl
fSLXAQoTTGlzdFBhY2thZ2VzUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKRInYXJ0
aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9QYWNrYWdlUgZwYXJlbnQSGwoJcGFnZV9z
aXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SGwoG
ZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRl
ckJ5IogBChRMaXN0UGFja2FnZXNSZXNwb25zZRJICghwYWNrYWdlcxgBIAMoCzIsLmdvb2ds
ZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlBhY2thZ2VSCHBhY2thZ2VzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJYChFHZXRQYWNrYWdlUmVxdWVz
dBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5j
b20vUGFja2FnZVIEbmFtZSJbChREZWxldGVQYWNrYWdlUmVxdWVzdBJDCgRuYW1lGAEgASgJ
Qi/gQQL6QSkKJ2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vUGFja2FnZVIEbmFt
ZSKbAQoUVXBkYXRlUGFja2FnZVJlcXVlc3QSRgoHcGFja2FnZRgBIAEoCzIsLmdvb2dsZS5k
ZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlBhY2thZ2VSB3BhY2thZ2USOwoLdXBkYXRl
X21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrQvcB
Cidjb20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFCDFBhY2thZ2VQcm90
b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2FydGlmYWN0cmVnaXN0cnkvYXBpdjEvYXJ0aWZh
Y3RyZWdpc3RyeXBiO2FydGlmYWN0cmVnaXN0cnlwYqoCIEdvb2dsZS5DbG91ZC5BcnRpZmFj
dFJlZ2lzdHJ5LlYxygIgR29vZ2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlcVjHqAiNHb29n
bGU6OkNsb3VkOjpBcnRpZmFjdFJlZ2lzdHJ5OjpWMUqUKgoHEgUOAKUBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAKgoJCgIDAxIDFQApCggKAQgSAxcAPQoJCgIIJRIDFwA9CggKAQgSAxgA
ZwoJCgIICxIDGABnCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoALQoJCgIICBIDGgAt
CggKAQgSAxsAQAoJCgIIARIDGwBACggKAQgSAxwAPQoJCgIIKRIDHAA9CggKAQgSAx0APAoJ
CgIILRIDHQA8CjkKAgQAEgQgADcBGi0gUGFja2FnZXMgYXJlIG5hbWVkIGNvbGxlY3Rpb25z
IG9mIHZlcnNpb25zLgoKCgoDBAABEgMgCA8KCwoDBAAHEgQhAiQECg0KBQQAB50IEgQhAiQE
Cr8BCgQEAAIAEgMpAhIasQEgVGhlIG5hbWUgb2YgdGhlIHBhY2thZ2UsIGZvciBleGFtcGxl
OgogYHByb2plY3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMvcmVw
bzEvcGFja2FnZXMvcGtnMWAuCiBJZiB0aGUgcGFja2FnZSBJRCBwYXJ0IGNvbnRhaW5zIHNs
YXNoZXMsIHRoZSBzbGFzaGVzIGFyZSBlc2NhcGVkLgoKDAoFBAACAAUSAykCCAoMCgUEAAIA
ARIDKQkNCgwKBQQAAgADEgMpEBEKLwoEBAACARIDLAIaGiIgVGhlIGRpc3BsYXkgbmFtZSBv
ZiB0aGUgcGFja2FnZS4KCgwKBQQAAgEFEgMsAggKDAoFBAACAQESAywJFQoMCgUEAAIBAxID
LBgZCjUKBAQAAgISAy8CLBooIFRoZSB0aW1lIHdoZW4gdGhlIHBhY2thZ2Ugd2FzIGNyZWF0
ZWQuCgoMCgUEAAICBhIDLwIbCgwKBQQAAgIBEgMvHCcKDAoFBAACAgMSAy8qKwpyCgQEAAID
EgMzAiwaZSBUaGUgdGltZSB3aGVuIHRoZSBwYWNrYWdlIHdhcyBsYXN0IHVwZGF0ZWQuIFRo
aXMgaW5jbHVkZXMgcHVibGlzaGluZyBhIG5ldwogdmVyc2lvbiBvZiB0aGUgcGFja2FnZS4K
CgwKBQQAAgMGEgMzAhsKDAoFBAACAwESAzMcJwoMCgUEAAIDAxIDMyorCjYKBAQAAgQSAzYC
TxopIE9wdGlvbmFsLiBDbGllbnQgc3BlY2lmaWVkIGFubm90YXRpb25zLgoKDAoFBAACBAYS
AzYCFQoMCgUEAAIEARIDNhYhCgwKBQQAAgQDEgM2JCUKDAoFBAACBAgSAzYmTgoPCggEAAIE
CJwIABIDNidNCisKAgQBEgQ6AHoBGh8gVGhlIHJlcXVlc3QgdG8gbGlzdCBwYWNrYWdlcy4K
CgoKAwQBARIDOggbClgKBAQBAgASBDwCQQQaSiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IHBhcmVudCByZXNvdXJjZSB3aG9zZSBwYWNrYWdlcyB3aWxsIGJlIGxpc3RlZC4KCgwKBQQB
AgAFEgM8AggKDAoFBAECAAESAzwJDwoMCgUEAQIAAxIDPBITCg0KBQQBAgAIEgQ8FEEDCg8K
CAQBAgAInAgAEgM9BCoKDwoHBAECAAifCBIEPgRABQpUCgQEAQIBEgNEAhYaRyBUaGUgbWF4
aW11bSBudW1iZXIgb2YgcGFja2FnZXMgdG8gcmV0dXJuLiBNYXhpbXVtIHBhZ2Ugc2l6ZSBp
cyAxLDAwMC4KCgwKBQQBAgEFEgNEAgcKDAoFBAECAQESA0QIEQoMCgUEAQIBAxIDRBQVClcK
BAQBAgISA0cCGBpKIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBh
IHByZXZpb3VzIGxpc3QgcmVxdWVzdCwgaWYgYW55LgoKDAoFBAECAgUSA0cCCAoMCgUEAQIC
ARIDRwkTCgwKBQQBAgIDEgNHFhcK8w4KBAQBAgMSA3YCPRrlDiBPcHRpb25hbC4gQW4gZXhw
cmVzc2lvbiBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LiBGaWx0
ZXIKIHJ1bGVzIGFyZSBjYXNlIGluc2Vuc2l0aXZlLiBUaGUgZmllbGRzIGVsaWdpYmxlIGZv
ciBmaWx0ZXJpbmcgYXJlOgoKICAgKiBgbmFtZWAKICAgKiBgYW5ub3RhdGlvbnNgCgogRXhh
bXBsZXMgb2YgdXNpbmcgYSBmaWx0ZXI6CgogIFRvIGZpbHRlciB0aGUgcmVzdWx0cyBvZiB5
b3VyIHJlcXVlc3QgdG8gcGFja2FnZXMgd2l0aCB0aGUgbmFtZQogIGBteS1wYWNrYWdlYCBp
biBwcm9qZWN0IGBteS1wcm9qZWN0YCBpbiB0aGUgYHVzLWNlbnRyYWxgIHJlZ2lvbiwgaW4K
ICByZXBvc2l0b3J5IGBteS1yZXBvYCwgYXBwZW5kIHRoZSBmb2xsb3dpbmcgZmlsdGVyIGV4
cHJlc3Npb24gdG8geW91cgogIHJlcXVlc3Q6CgogICAqIGBuYW1lPSJwcm9qZWN0cy9teS1w
cm9qZWN0L2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMvbXktcmVwby9wYWNr
YWdlcy9teS1wYWNrYWdlImAKCiAgWW91IGNhbiBhbHNvIHVzZSB3aWxkY2FyZHMgdG8gbWF0
Y2ggYW55IG51bWJlciBvZiBjaGFyYWN0ZXJzIGJlZm9yZSBvcgogIGFmdGVyIHRoZSB2YWx1
ZToKCiAgICogYG5hbWU9InByb2plY3RzL215LXByb2plY3QvbG9jYXRpb25zL3VzLWNlbnRy
YWwxL3JlcG9zaXRvcmllcy9teS1yZXBvL3BhY2thZ2VzL215LSoiYAogICAqIGBuYW1lPSJw
cm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMv
bXktcmVwby9wYWNrYWdlcy8qcGFja2FnZSJgCiAgICogYG5hbWU9InByb2plY3RzL215LXBy
b2plY3QvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9teS1yZXBvL3BhY2th
Z2VzLypwYWNrKiJgCgogIFRvIGZpbHRlciB0aGUgcmVzdWx0cyBvZiB5b3VyIHJlcXVlc3Qg
dG8gcGFja2FnZXMgd2l0aCB0aGUgYW5ub3RhdGlvbgogIGtleS12YWx1ZSBwYWlyIFtgZXh0
ZXJuYWxfbGlua2A6IGBleHRlcm5hbF9saW5rX3ZhbHVlYF0sIGFwcGVuZCB0aGUKICBmb2xs
b3dpbmcgZmlsdGVyIGV4cHJlc3Npb24gdG8geW91ciByZXF1ZXN0IjoKCiAgICogYCJhbm5v
dGF0aW9ucy5leHRlcm5hbF9saW5rOmV4dGVybmFsX2xpbmtfdmFsdWUiYAoKICBUbyBmaWx0
ZXIgdGhlIHJlc3VsdHMganVzdCBmb3IgYSBzcGVjaWZpYyBhbm5vdGF0aW9uIGtleSBgZXh0
ZXJuYWxfbGlua2AsCiAgYXBwZW5kIHRoZSBmb2xsb3dpbmcgZmlsdGVyIGV4cHJlc3Npb24g
dG8geW91ciByZXF1ZXN0OgoKICAgKiBgImFubm90YXRpb25zLmV4dGVybmFsX2xpbmsiYAoK
ICBJZiB0aGUgYW5ub3RhdGlvbiBrZXkgb3IgdmFsdWUgY29udGFpbnMgc3BlY2lhbCBjaGFy
YWN0ZXJzLCB5b3UgY2FuIGVzY2FwZQogIHRoZW0gYnkgc3Vycm91bmRpbmcgdGhlIHZhbHVl
IHdpdGggYmFja3RpY2tzLiBGb3IgZXhhbXBsZSwgdG8gZmlsdGVyIHRoZQogIHJlc3VsdHMg
b2YgeW91ciByZXF1ZXN0IHRvIHBhY2thZ2VzIHdpdGggdGhlIGFubm90YXRpb24ga2V5LXZh
bHVlIHBhaXIKICBbYGV4dGVybmFsLmxpbmtgOmBodHRwczovL2V4YW1wbGUuY29tL215LXBh
Y2thZ2VgXSwgYXBwZW5kIHRoZSBmb2xsb3dpbmcKICBmaWx0ZXIgZXhwcmVzc2lvbiB0byB5
b3VyIHJlcXVlc3Q6CgogICAqIGBgICJhbm5vdGF0aW9ucy5gZXh0ZXJuYWwubGlua2A6YGh0
dHBzOi8vZXhhbXBsZS5jb20vbXktcGFja2FnZWAiIGBgCgogIFlvdSBjYW4gYWxzbyBmaWx0
ZXIgd2l0aCBhbm5vdGF0aW9ucyB3aXRoIGEgd2lsZGNhcmQgdG8KICBtYXRjaCBhbnkgbnVt
YmVyIG9mIGNoYXJhY3RlcnMgYmVmb3JlIG9yIGFmdGVyIHRoZSB2YWx1ZToKCiAgICogYGAg
ImFubm90YXRpb25zLipfbGluazpgKmV4YW1wbGUuY29tKmAiIGBgCgoMCgUEAQIDBRIDdgII
CgwKBQQBAgMBEgN2CQ8KDAoFBAECAwMSA3YSEwoMCgUEAQIDCBIDdhQ8Cg8KCAQBAgMInAgA
EgN2FTsKOwoEBAECBBIDeQI/Gi4gT3B0aW9uYWwuIFRoZSBmaWVsZCB0byBvcmRlciB0aGUg
cmVzdWx0cyBieS4KCgwKBQQBAgQFEgN5AggKDAoFBAECBAESA3kJEQoMCgUEAQIEAxIDeRQV
CgwKBQQBAgQIEgN5Fj4KDwoIBAECBAicCAASA3kXPQoyCgIEAhIFfQCEAQEaJSBUaGUgcmVz
cG9uc2UgZnJvbSBsaXN0aW5nIHBhY2thZ2VzLgoKCgoDBAIBEgN9CBwKJQoEBAICABIDfwIg
GhggVGhlIHBhY2thZ2VzIHJldHVybmVkLgoKDAoFBAICAAQSA38CCgoMCgUEAgIABhIDfwsS
CgwKBQQCAgABEgN/ExsKDAoFBAICAAMSA38eHwpzCgQEAgIBEgSDAQIdGmUgVGhlIHRva2Vu
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcGFja2FnZXMsIG9yIGVtcHR5IGlmIHRo
ZXJlIGFyZSBubwogbW9yZSBwYWNrYWdlcyB0byByZXR1cm4uCgoNCgUEAgIBBRIEgwECCAoN
CgUEAgIBARIEgwEJGAoNCgUEAgIBAxIEgwEbHAoyCgIEAxIGhwEAjwEBGiQgVGhlIHJlcXVl
c3QgdG8gcmV0cmlldmUgYSBwYWNrYWdlLgoKCwoDBAMBEgSHAQgZCkAKBAQDAgASBokBAo4B
BBowIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcGFja2FnZSB0byByZXRyaWV2ZS4KCg0K
BQQDAgAFEgSJAQIICg0KBQQDAgABEgSJAQkNCg0KBQQDAgADEgSJARARCg8KBQQDAgAIEgaJ
ARKOAQMKEAoIBAMCAAicCAASBIoBBCoKEQoHBAMCAAifCBIGiwEEjQEFCjAKAgQEEgaSAQCa
AQEaIiBUaGUgcmVxdWVzdCB0byBkZWxldGUgYSBwYWNrYWdlLgoKCwoDBAQBEgSSAQgcCj4K
BAQEAgASBpQBApkBBBouIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcGFja2FnZSB0byBk
ZWxldGUuCgoNCgUEBAIABRIElAECCAoNCgUEBAIAARIElAEJDQoNCgUEBAIAAxIElAEQEQoP
CgUEBAIACBIGlAESmQEDChAKCAQEAgAInAgAEgSVAQQqChEKBwQEAgAInwgSBpYBBJgBBQow
CgIEBRIGnQEApQEBGiIgVGhlIHJlcXVlc3QgdG8gdXBkYXRlIGEgcGFja2FnZS4KCgsKAwQF
ARIEnQEIHApFCgQEBQIAEgSfAQIWGjcgVGhlIHBhY2thZ2UgdGhhdCByZXBsYWNlcyB0aGUg
cmVzb3VyY2Ugb24gdGhlIHNlcnZlci4KCg0KBQQFAgAGEgSfAQIJCg0KBQQFAgABEgSfAQoR
Cg0KBQQFAgADEgSfARQVCrcBCgQEBQIBEgSkAQIsGqgBIFRoZSB1cGRhdGUgbWFzayBhcHBs
aWVzIHRvIHRoZSByZXNvdXJjZS4gRm9yIHRoZSBgRmllbGRNYXNrYCBkZWZpbml0aW9uLAog
c2VlCiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2Rv
Y3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNmaWVsZG1hc2sKCg0KBQQFAgEGEgSkAQIb
Cg0KBQQFAgEBEgSkARwnCg0KBQQFAgEDEgSkASorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Package::Package ===
    # Fields for Package
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: annotations Type: 11 (.google.devtools.artifactregistry.v1.Package.AnnotationsEntry)

# === Message: Google::Devtools::Artifactregistry::V1::Package::ListPackagesRequest ===
    # Fields for ListPackagesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Package::ListPackagesResponse ===
    # Fields for ListPackagesResponse
    # Field: packages Type: 11 (.google.devtools.artifactregistry.v1.Package)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Package::GetPackageRequest ===
    # Fields for GetPackageRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Package::DeletePackageRequest ===
    # Fields for DeletePackageRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Package::UpdatePackageRequest ===
    # Fields for UpdatePackageRequest
    # Field: package Type: 11 (.google.devtools.artifactregistry.v1.Package)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Package - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/package.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Package;

    my $msg = Google::Devtools::Artifactregistry::V1::Package::Package->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Package::Package->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/package.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Package::Package

Packages are named collections of versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the package, for example:
`projects/p1/locations/us-central1/repositories/repo1/packages/pkg1`.
If the package ID part contains slashes, the slashes are escaped.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the package.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the package was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the package was last updated. This includes publishing a new
version of the package.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Package::Package::AnnotationsEntry>)

Optional. Client specified annotations.

=back

=head2 Google::Devtools::Artifactregistry::V1::Package::ListPackagesRequest

The request to list packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose packages will be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of packages to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Filter
rules are case insensitive. The fields eligible for filtering are:

  * `name`
  * `annotations`

Examples of using a filter:

 To filter the results of your request to packages with the name
 `my-package` in project `my-project` in the `us-central` region, in
 repository `my-repo`, append the following filter expression to your
 request:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package"`

 You can also use wildcards to match any number of characters before or
 after the value:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-*"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/*package"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/*pack*"`

 To filter the results of your request to packages with the annotation
 key-value pair [`external_link`: `external_link_value`], append the
 following filter expression to your request":

  * `"annotations.external_link:external_link_value"`

 To filter the results just for a specific annotation key `external_link`,
 append the following filter expression to your request:

  * `"annotations.external_link"`

 If the annotation key or value contains special characters, you can escape
 them by surrounding the value with backticks. For example, to filter the
 results of your request to packages with the annotation key-value pair
 [`external.link`:`https://example.com/my-package`], append the following
 filter expression to your request:

  * `` "annotations.`external.link`:`https://example.com/my-package`" ``

 You can also filter with annotations with a wildcard to
 match any number of characters before or after the value:

  * `` "annotations.*_link:`*example.com*`" ``

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. The field to order the results by.

=back

=head2 Google::Devtools::Artifactregistry::V1::Package::ListPackagesResponse

The response from listing packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->packages() >> / C<< $msg->packages($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Package::Package>)

The packages returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of packages, or empty if there are no
more packages to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Package::GetPackageRequest

The request to retrieve a package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the package to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1::Package::DeletePackageRequest

The request to delete a package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the package to delete.

=back

=head2 Google::Devtools::Artifactregistry::V1::Package::UpdatePackageRequest

The request to update a package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->package() >> / C<< $msg->package($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Package::Package>)

The package that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Package::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
