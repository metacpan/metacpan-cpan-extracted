package Google::Devtools::Cloudprofiler::V2::Profiler;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvZGV2dG9vbHMvY2xvdWRwcm9maWxlci92Mi9wcm9maWxlci5wcm90bxIgZ29v
Z2xlLmRldnRvb2xzLmNsb3VkcHJvZmlsZXIudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYv
ZHVyYXRpb24ucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoACChRDcmVhdGVQcm9maWxlUmVxdWVzdBJI
CgZwYXJlbnQYBCABKAlCMPpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5j
b20vUHJvamVjdFIGcGFyZW50EkwKCmRlcGxveW1lbnQYASABKAsyLC5nb29nbGUuZGV2dG9v
bHMuY2xvdWRwcm9maWxlci52Mi5EZXBsb3ltZW50UgpkZXBsb3ltZW50ElAKDHByb2ZpbGVf
dHlwZRgCIAMoDjItLmdvb2dsZS5kZXZ0b29scy5jbG91ZHByb2ZpbGVyLnYyLlByb2ZpbGVU
eXBlUgtwcm9maWxlVHlwZSKsAQobQ3JlYXRlT2ZmbGluZVByb2ZpbGVSZXF1ZXN0EkgKBnBh
cmVudBgBIAEoCUIw+kEtCitjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Q
cm9qZWN0UgZwYXJlbnQSQwoHcHJvZmlsZRgCIAEoCzIpLmdvb2dsZS5kZXZ0b29scy5jbG91
ZHByb2ZpbGVyLnYyLlByb2ZpbGVSB3Byb2ZpbGUimAEKFFVwZGF0ZVByb2ZpbGVSZXF1ZXN0
EkMKB3Byb2ZpbGUYASABKAsyKS5nb29nbGUuZGV2dG9vbHMuY2xvdWRwcm9maWxlci52Mi5Q
cm9maWxlUgdwcm9maWxlEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVm
LkZpZWxkTWFza1IKdXBkYXRlTWFzayLEBAoHUHJvZmlsZRIXCgRuYW1lGAEgASgJQgPgQQNS
BG5hbWUSUAoMcHJvZmlsZV90eXBlGAIgASgOMi0uZ29vZ2xlLmRldnRvb2xzLmNsb3VkcHJv
ZmlsZXIudjIuUHJvZmlsZVR5cGVSC3Byb2ZpbGVUeXBlEkwKCmRlcGxveW1lbnQYAyABKAsy
LC5nb29nbGUuZGV2dG9vbHMuY2xvdWRwcm9maWxlci52Mi5EZXBsb3ltZW50UgpkZXBsb3lt
ZW50EjUKCGR1cmF0aW9uGAQgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJh
dGlvbhIoCg1wcm9maWxlX2J5dGVzGAUgASgMQgPgQQRSDHByb2ZpbGVCeXRlcxJSCgZsYWJl
bHMYBiADKAsyNS5nb29nbGUuZGV2dG9vbHMuY2xvdWRwcm9maWxlci52Mi5Qcm9maWxlLkxh
YmVsc0VudHJ5QgPgQQRSBmxhYmVscxI+CgpzdGFydF90aW1lGAcgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUglzdGFydFRpbWUaOQoLTGFiZWxzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATpQ6kFNCiRjbG91ZHByb2Zp
bGVyLmdvb2dsZWFwaXMuY29tL1Byb2ZpbGUSJXByb2plY3RzL3twcm9qZWN0fS9wcm9maWxl
cy97cHJvZmlsZX0i0AEKCkRlcGxveW1lbnQSHQoKcHJvamVjdF9pZBgBIAEoCVIJcHJvamVj
dElkEhYKBnRhcmdldBgCIAEoCVIGdGFyZ2V0ElAKBmxhYmVscxgDIAMoCzI4Lmdvb2dsZS5k
ZXZ0b29scy5jbG91ZHByb2ZpbGVyLnYyLkRlcGxveW1lbnQuTGFiZWxzRW50cnlSBmxhYmVs
cxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIp4BChNMaXN0UHJvZmlsZXNSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEt
CitjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQS
GwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdl
VG9rZW4isAEKFExpc3RQcm9maWxlc1Jlc3BvbnNlEkUKCHByb2ZpbGVzGAEgAygLMikuZ29v
Z2xlLmRldnRvb2xzLmNsb3VkcHJvZmlsZXIudjIuUHJvZmlsZVIIcHJvZmlsZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEikKEHNraXBwZWRfcHJvZmlsZXMY
AyABKAVSD3NraXBwZWRQcm9maWxlcyqEAQoLUHJvZmlsZVR5cGUSHAoYUFJPRklMRV9UWVBF
X1VOU1BFQ0lGSUVEEAASBwoDQ1BVEAESCAoEV0FMTBACEggKBEhFQVAQAxILCgdUSFJFQURT
EAQSDgoKQ09OVEVOVElPThAFEg0KCVBFQUtfSEVBUBAGEg4KCkhFQVBfQUxMT0MQBzL+BQoP
UHJvZmlsZXJTZXJ2aWNlEp8BCg1DcmVhdGVQcm9maWxlEjYuZ29vZ2xlLmRldnRvb2xzLmNs
b3VkcHJvZmlsZXIudjIuQ3JlYXRlUHJvZmlsZVJlcXVlc3QaKS5nb29nbGUuZGV2dG9vbHMu
Y2xvdWRwcm9maWxlci52Mi5Qcm9maWxlIiuC0+STAiUiIC92Mi97cGFyZW50PXByb2plY3Rz
Lyp9L3Byb2ZpbGVzOgEqEtIBChRDcmVhdGVPZmZsaW5lUHJvZmlsZRI9Lmdvb2dsZS5kZXZ0
b29scy5jbG91ZHByb2ZpbGVyLnYyLkNyZWF0ZU9mZmxpbmVQcm9maWxlUmVxdWVzdBopLmdv
b2dsZS5kZXZ0b29scy5jbG91ZHByb2ZpbGVyLnYyLlByb2ZpbGUiUILT5JMCOSIuL3YyL3tw
YXJlbnQ9cHJvamVjdHMvKn0vcHJvZmlsZXM6Y3JlYXRlT2ZmbGluZToHcHJvZmlsZdpBDnBh
cmVudCxwcm9maWxlEsMBCg1VcGRhdGVQcm9maWxlEjYuZ29vZ2xlLmRldnRvb2xzLmNsb3Vk
cHJvZmlsZXIudjIuVXBkYXRlUHJvZmlsZVJlcXVlc3QaKS5nb29nbGUuZGV2dG9vbHMuY2xv
dWRwcm9maWxlci52Mi5Qcm9maWxlIk+C0+STAjMyKC92Mi97cHJvZmlsZS5uYW1lPXByb2pl
Y3RzLyovcHJvZmlsZXMvKn06B3Byb2ZpbGXaQRNwcm9maWxlLHVwZGF0ZV9tYXNrGq0BykEc
Y2xvdWRwcm9maWxlci5nb29nbGVhcGlzLmNvbdJBigFodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvbW9uaXRvcmluZyxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3Jp
bmcud3JpdGUy8gIKDUV4cG9ydFNlcnZpY2USsAEKDExpc3RQcm9maWxlcxI1Lmdvb2dsZS5k
ZXZ0b29scy5jbG91ZHByb2ZpbGVyLnYyLkxpc3RQcm9maWxlc1JlcXVlc3QaNi5nb29nbGUu
ZGV2dG9vbHMuY2xvdWRwcm9maWxlci52Mi5MaXN0UHJvZmlsZXNSZXNwb25zZSIxgtPkkwIi
EiAvdjIve3BhcmVudD1wcm9qZWN0cy8qfS9wcm9maWxlc9pBBnBhcmVudBqtAcpBHGNsb3Vk
cHJvZmlsZXIuZ29vZ2xlYXBpcy5jb23SQYoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21v
bml0b3JpbmcsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9tb25pdG9yaW5nLndy
aXRlQtQBCiRjb20uZ29vZ2xlLmRldnRvb2xzLmNsb3VkcHJvZmlsZXIudjJCDVByb2ZpbGVy
UHJvdG9QAVpHY2xvdWQuZ29vZ2xlLmNvbS9nby9jbG91ZHByb2ZpbGVyL2FwaXYyL2Nsb3Vk
cHJvZmlsZXJwYjtjbG91ZHByb2ZpbGVycGKqAhhHb29nbGUuQ2xvdWQuUHJvZmlsZXIuVjLK
AhhHb29nbGVcQ2xvdWRcUHJvZmlsZXJcVjLqAhtHb29nbGU6OkNsb3VkOjpQcm9maWxlcjo6
VjJK/FYKBxIFDgC3AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACkKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgID
BBIDFgAoCgkKAgMFEgMXACoKCQoCAwYSAxgAKQoICgEIEgMaADUKCQoCCCUSAxoANQoICgEI
EgMbAF4KCQoCCAsSAxsAXgoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdAC4KCQoCCAgS
Ax0ALgoICgEIEgMeAD0KCQoCCAESAx4APQoICgEIEgMfADUKCQoCCCkSAx8ANQoICgEIEgMg
ADQKCQoCCC0SAyAANAr+AQoCBgASBCcAaAEa8QEgTWFuYWdlIHRoZSBjb2xsZWN0aW9uIG9m
IGNvbnRpbnVvdXMgcHJvZmlsaW5nIGRhdGEgcHJvdmlkZWQgYnkgcHJvZmlsaW5nCiBhZ2Vu
dHMgcnVubmluZyBpbiB0aGUgY2xvdWQgb3IgYnkgYW4gb2ZmbGluZSBwcm92aWRlciBvZiBw
cm9maWxpbmcgZGF0YS4KCiBfX1RoZSBBUElzIGxpc3RlZCBpbiB0aGlzIHNlcnZpY2UgYXJl
IGludGVuZGVkIGZvciB1c2Ugd2l0aGluIG91ciBwcm9maWxlcgogYWdlbnRzIG9ubHkuX18K
CgoKAwYAARIDJwgXCgoKAwYAAxIDKAJECgwKBQYAA5kIEgMoAkQKCwoDBgADEgQpAiw5Cg0K
BQYAA5oIEgQpAiw5CoUHCgQGAAIAEgRBAkYDGvYGIENyZWF0ZVByb2ZpbGUgY3JlYXRlcyBh
IG5ldyBwcm9maWxlIHJlc291cmNlIGluIHRoZSBvbmxpbmUgbW9kZS4KCiBfRGlyZWN0IHVz
ZSBvZiB0aGlzIEFQSSBpcyBkaXNjb3VyYWdlZCwgcGxlYXNlIHVzZSBhIFtzdXBwb3J0ZWQK
IHByb2ZpbGVyCiBhZ2VudF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Byb2ZpbGVyL2Rv
Y3MvYWJvdXQtcHJvZmlsZXIjcHJvZmlsaW5nX2FnZW50KQogaW5zdGVhZCBmb3IgcHJvZmls
ZSBjb2xsZWN0aW9uLl8KCiBUaGUgc2VydmVyIGVuc3VyZXMgdGhhdCB0aGUgbmV3IHByb2Zp
bGVzIGFyZSBjcmVhdGVkIGF0IGEgY29uc3RhbnQgcmF0ZSBwZXIKIGRlcGxveW1lbnQsIHNv
IHRoZSBjcmVhdGlvbiByZXF1ZXN0IG1heSBoYW5nIGZvciBzb21lIHRpbWUgdW50aWwgdGhl
IG5leHQKIHByb2ZpbGUgc2Vzc2lvbiBpcyBhdmFpbGFibGUuCgogVGhlIHJlcXVlc3QgbWF5
IGZhaWwgd2l0aCBBQk9SVEVEIGVycm9yIGlmIHRoZSBjcmVhdGlvbiBpcyBub3QgYXZhaWxh
YmxlCiB3aXRoaW4gfjFtLCB0aGUgcmVzcG9uc2Ugd2lsbCBpbmRpY2F0ZSB0aGUgZHVyYXRp
b24gb2YgdGhlIGJhY2tvZmYgdGhlCiBjbGllbnQgc2hvdWxkIHRha2UgYmVmb3JlIGF0dGVt
cHRpbmcgY3JlYXRpbmcgYSBwcm9maWxlIGFnYWluLiBUaGUgYmFja29mZgogZHVyYXRpb24g
aXMgcmV0dXJuZWQgaW4gZ29vZ2xlLnJwYy5SZXRyeUluZm8gZXh0ZW5zaW9uIG9uIHRoZSBy
ZXNwb25zZQogc3RhdHVzLiBUbyBhIGdSUEMgY2xpZW50LCB0aGUgZXh0ZW5zaW9uIHdpbGwg
YmUgcmV0dXJuIGFzIGEKIGJpbmFyeS1zZXJpYWxpemVkIHByb3RvIGluIHRoZSB0cmFpbGlu
ZyBtZXRhZGF0YSBpdGVtIG5hbWVkCiAiZ29vZ2xlLnJwYy5yZXRyeWluZm8tYmluIi4KCgoM
CgUGAAIAARIDQQYTCgwKBQYAAgACEgNBFCgKDAoFBgACAAMSA0EzOgoNCgUGAAIABBIEQgRF
BgoRCgkGAAIABLDKvCISBEIERQYK9wIKBAYAAgESBFACVgMa6AIgQ3JlYXRlT2ZmbGluZVBy
b2ZpbGUgY3JlYXRlcyBhIG5ldyBwcm9maWxlIHJlc291cmNlIGluIHRoZSBvZmZsaW5lCiBt
b2RlLiBUaGUgY2xpZW50IHByb3ZpZGVzIHRoZSBwcm9maWxlIHRvIGNyZWF0ZSBhbG9uZyB3
aXRoIHRoZSBwcm9maWxlCiBieXRlcywgdGhlIHNlcnZlciByZWNvcmRzIGl0LgoKIF9EaXJl
Y3QgdXNlIG9mIHRoaXMgQVBJIGlzIGRpc2NvdXJhZ2VkLCBwbGVhc2UgdXNlIGEgW3N1cHBv
cnRlZAogcHJvZmlsZXIKIGFnZW50XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcHJvZmls
ZXIvZG9jcy9hYm91dC1wcm9maWxlciNwcm9maWxpbmdfYWdlbnQpCiBpbnN0ZWFkIGZvciBw
cm9maWxlIGNvbGxlY3Rpb24uXwoKDAoFBgACAQESA1AGGgoMCgUGAAIBAhIDUBs2CgwKBQYA
AgEDEgNQQUgKDQoFBgACAQQSBFEEVAYKEQoJBgACAQSwyrwiEgRRBFQGCgwKBQYAAgEEEgNV
BDwKDwoIBgACAQSbCAASA1UEPArZAwoEBgACAhIEYQJnAxrKAyBVcGRhdGVQcm9maWxlIHVw
ZGF0ZXMgdGhlIHByb2ZpbGUgYnl0ZXMgYW5kIGxhYmVscyBvbiB0aGUgcHJvZmlsZSByZXNv
dXJjZQogY3JlYXRlZCBpbiB0aGUgb25saW5lIG1vZGUuIFVwZGF0aW5nIHRoZSBieXRlcyBm
b3IgcHJvZmlsZXMgY3JlYXRlZCBpbiB0aGUKIG9mZmxpbmUgbW9kZSBpcyBjdXJyZW50bHkg
bm90IHN1cHBvcnRlZDogdGhlIHByb2ZpbGUgY29udGVudCBtdXN0IGJlCiBwcm92aWRlZCBh
dCB0aGUgdGltZSBvZiB0aGUgcHJvZmlsZSBjcmVhdGlvbi4KCiBfRGlyZWN0IHVzZSBvZiB0
aGlzIEFQSSBpcyBkaXNjb3VyYWdlZCwgcGxlYXNlIHVzZSBhIFtzdXBwb3J0ZWQKIHByb2Zp
bGVyCiBhZ2VudF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Byb2ZpbGVyL2RvY3MvYWJv
dXQtcHJvZmlsZXIjcHJvZmlsaW5nX2FnZW50KQogaW5zdGVhZCBmb3IgcHJvZmlsZSBjb2xs
ZWN0aW9uLl8KCgwKBQYAAgIBEgNhBhMKDAoFBgACAgISA2EUKAoMCgUGAAICAxIDYTM6Cg0K
BQYAAgIEEgRiBGUGChEKCQYAAgIEsMq8IhIEYgRlBgoMCgUGAAICBBIDZgRBCg8KCAYAAgIE
mwgAEgNmBEEKcQoCBgESBGwAewEaZSBTZXJ2aWNlIGFsbG93cyBleGlzdGluZyBDbG91ZCBQ
cm9maWxlciBjdXN0b21lcnMgdG8gZXhwb3J0IHRoZWlyIHByb2ZpbGUgZGF0YQogb3V0IG9m
IEdvb2dsZSBDbG91ZC4KCgoKAwYBARIDbAgVCgoKAwYBAxIDbQJECgwKBQYBA5kIEgNtAkQK
CwoDBgEDEgRuAnE5Cg0KBQYBA5oIEgRuAnE5CnEKBAYBAgASBHUCegMaYyBMaXN0cyBwcm9m
aWxlcyB3aGljaCBoYXZlIGJlZW4gY29sbGVjdGVkIHNvIGZhciBhbmQgZm9yIHdoaWNoIHRo
ZSBjYWxsZXIKIGhhcyBwZXJtaXNzaW9uIHRvIHZpZXcuCgoMCgUGAQIAARIDdQYSCgwKBQYB
AgACEgN1EyYKDAoFBgECAAMSA3UxRQoNCgUGAQIABBIEdgR4BgoRCgkGAQIABLDKvCISBHYE
eAYKDAoFBgECAAQSA3kENAoPCggGAQIABJsIABIDeQQ0Cq0CCgIEABIGggEAjQEBGp4CIENy
ZWF0ZVByb2ZpbGVSZXF1ZXN0IGRlc2NyaWJlcyBhIHByb2ZpbGUgcmVzb3VyY2Ugb25saW5l
IGNyZWF0aW9uIHJlcXVlc3QuCiBUaGUgZGVwbG95bWVudCBmaWVsZCBtdXN0IGJlIHBvcHVs
YXRlZC4gVGhlIHByb2ZpbGVfdHlwZSBzcGVjaWZpZXMgdGhlIGxpc3QKIG9mIHByb2ZpbGUg
dHlwZXMgc3VwcG9ydGVkIGJ5IHRoZSBhZ2VudC4gVGhlIGNyZWF0aW9uIGNhbGwgd2lsbCBo
YW5nIHVudGlsIGEKIHByb2ZpbGUgb2Ygb25lIG9mIHRoZXNlIHR5cGVzIG5lZWRzIHRvIGJl
IGNvbGxlY3RlZC4KCgoLCgMEAAESBIIBCBwKOgoEBAACABIGhAEChgEFGiogUGFyZW50IHBy
b2plY3QgdG8gY3JlYXRlIHRoZSBwcm9maWxlIGluLgoKDQoFBAACAAUSBIQBAggKDQoFBAAC
AAESBIQBCQ8KDQoFBAACAAMSBIQBEhMKDwoFBAACAAgSBoQBFIYBBAoRCgcEAAIACJ8IEgaE
ARWGAQMKIwoEBAACARIEiQECHBoVIERlcGxveW1lbnQgZGV0YWlscy4KCg0KBQQAAgEGEgSJ
AQIMCg0KBQQAAgEBEgSJAQ0XCg0KBQQAAgEDEgSJARobClEKBAQAAgISBIwBAigaQyBPbmUg
b3IgbW9yZSBwcm9maWxlIHR5cGVzIHRoYXQgdGhlIGFnZW50IGlzIGNhcGFibGUgb2YgcHJv
dmlkaW5nLgoKDQoFBAACAgQSBIwBAgoKDQoFBAACAgYSBIwBCxYKDQoFBAACAgESBIwBFyMK
DQoFBAACAgMSBIwBJicKYwoCBAESBpEBAJkBARpVIENyZWF0ZU9mZmxpbmVQcm9maWxlUmVx
dWVzdCBkZXNjcmliZXMgYSBwcm9maWxlIHJlc291cmNlIG9mZmxpbmUgY3JlYXRpb24KIHJl
cXVlc3QuCgoLCgMEAQESBJEBCCMKOgoEBAECABIGkwEClQEFGiogUGFyZW50IHByb2plY3Qg
dG8gY3JlYXRlIHRoZSBwcm9maWxlIGluLgoKDQoFBAECAAUSBJMBAggKDQoFBAECAAESBJMB
CQ8KDQoFBAECAAMSBJMBEhMKDwoFBAECAAgSBpMBFJUBBAoRCgcEAQIACJ8IEgaTARWVAQMK
MgoEBAECARIEmAECFhokIENvbnRlbnRzIG9mIHRoZSBwcm9maWxlIHRvIGNyZWF0ZS4KCg0K
BQQBAgEGEgSYAQIJCg0KBQQBAgEBEgSYAQoRCg0KBQQBAgEDEgSYARQVCkQKAgQCEgacAQCl
AQEaNiBVcGRhdGVQcm9maWxlUmVxdWVzdCBjb250YWlucyB0aGUgcHJvZmlsZSB0byB1cGRh
dGUuCgoLCgMEAgESBJwBCBwKIgoEBAICABIEngECFhoUIFByb2ZpbGUgdG8gdXBkYXRlLgoK
DQoFBAICAAYSBJ4BAgkKDQoFBAICAAESBJ4BChEKDQoFBAICAAMSBJ4BFBUKhAIKBAQCAgES
BKQBAiwa9QEgRmllbGQgbWFzayB1c2VkIHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBv
dmVyd3JpdHRlbi4gQ3VycmVudGx5IG9ubHkKIHByb2ZpbGVfYnl0ZXMgYW5kIGxhYmVscyBm
aWVsZHMgYXJlIHN1cHBvcnRlZCBieSBVcGRhdGVQcm9maWxlLCBzbyBvbmx5CiB0aG9zZSBm
aWVsZHMgY2FuIGJlIHNwZWNpZmllZCBpbiB0aGUgbWFzay4gV2hlbiBubyBtYXNrIGlzIHBy
b3ZpZGVkLCBhbGwKIGZpZWxkcyBhcmUgb3ZlcndyaXR0ZW4uCgoNCgUEAgIBBhIEpAECGwoN
CgUEAgIBARIEpAEcJwoNCgUEAgIBAxIEpAEqKwohCgIEAxIGqAEAzgEBGhMgUHJvZmlsZSBy
ZXNvdXJjZS4KCgsKAwQDARIEqAEIDwoNCgMEAwcSBqkBAqwBBAoPCgUEAwedCBIGqQECrAEE
ClEKBAQDAgASBK8BAj4aQyBPdXRwdXQgb25seS4gT3BhcXVlLCBzZXJ2ZXItYXNzaWduZWQs
IHVuaXF1ZSBJRCBmb3IgdGhpcyBwcm9maWxlLgoKDQoFBAMCAAUSBK8BAggKDQoFBAMCAAES
BK8BCQ0KDQoFBAMCAAMSBK8BEBEKDQoFBAMCAAgSBK8BEj0KEAoIBAMCAAicCAASBK8BEzwK
ogEKBAQDAgESBLQBAh8akwEgVHlwZSBvZiBwcm9maWxlLgogRm9yIG9mZmxpbmUgbW9kZSwg
dGhpcyBtdXN0IGJlIHNwZWNpZmllZCB3aGVuIGNyZWF0aW5nIHRoZSBwcm9maWxlLiBGb3IK
IG9ubGluZSBtb2RlIGl0IGlzIGFzc2lnbmVkIGFuZCByZXR1cm5lZCBieSB0aGUgc2VydmVy
LgoKDQoFBAMCAQYSBLQBAg0KDQoFBAMCAQESBLQBDhoKDQoFBAMCAQMSBLQBHR4KNwoEBAMC
AhIEtwECHBopIERlcGxveW1lbnQgdGhpcyBwcm9maWxlIGNvcnJlc3BvbmRzIHRvLgoKDQoF
BAMCAgYSBLcBAgwKDQoFBAMCAgESBLcBDRcKDQoFBAMCAgMSBLcBGhsKggMKBAQDAgMSBL8B
Aiga8wIgRHVyYXRpb24gb2YgdGhlIHByb2ZpbGluZyBzZXNzaW9uLgogSW5wdXQgKGZvciB0
aGUgb2ZmbGluZSBtb2RlKSBvciBvdXRwdXQgKGZvciB0aGUgb25saW5lIG1vZGUpLgogVGhl
IGZpZWxkIHJlcHJlc2VudHMgcmVxdWVzdGVkIHByb2ZpbGluZyBkdXJhdGlvbi4gSXQgbWF5
IHNsaWdodGx5IGRpZmZlcgogZnJvbSB0aGUgZWZmZWN0aXZlIHByb2ZpbGluZyBkdXJhdGlv
biwgd2hpY2ggaXMgcmVjb3JkZWQgaW4gdGhlIHByb2ZpbGUKIGRhdGEsIGluIGNhc2UgdGhl
IHByb2ZpbGluZyBjYW4ndCBiZSBzdG9wcGVkIGltbWVkaWF0ZWx5IChlLmcuIGluIGNhc2UK
IHN0b3BwaW5nIHRoZSBwcm9maWxpbmcgaXMgaGFuZGxlZCBhc3luY2hyb25vdXNseSkuCgoN
CgUEAwIDBhIEvwECGgoNCgUEAwIDARIEvwEbIwoNCgUEAwIDAxIEvwEmJwqiAQoEBAMCBBIE
wwECRRqTASBJbnB1dCBvbmx5LiBQcm9maWxlIGJ5dGVzLCBhcyBhIGd6aXAgY29tcHJlc3Nl
ZCBzZXJpYWxpemVkIHByb3RvLCB0aGUKIGZvcm1hdCBpcyBodHRwczovL2dpdGh1Yi5jb20v
Z29vZ2xlL3Bwcm9mL2Jsb2IvbWFzdGVyL3Byb3RvL3Byb2ZpbGUucHJvdG8uCgoNCgUEAwIE
BRIEwwECBwoNCgUEAwIEARIEwwEIFQoNCgUEAwIEAxIEwwEYGQoNCgUEAwIECBIEwwEaRAoQ
CggEAwIECJwIABIEwwEbQwriAQoEBAMCBRIEyAECTBrTASBJbnB1dCBvbmx5LiBMYWJlbHMg
YXNzb2NpYXRlZCB0byB0aGlzIHNwZWNpZmljIHByb2ZpbGUuIFRoZXNlIGxhYmVscyB3aWxs
CiBnZXQgbWVyZ2VkIHdpdGggdGhlIGRlcGxveW1lbnQgbGFiZWxzIGZvciB0aGUgZmluYWwg
ZGF0YSBzZXQuIFNlZQogZG9jdW1lbnRhdGlvbiBvbiBkZXBsb3ltZW50IGxhYmVscyBmb3Ig
dmFsaWRhdGlvbiBydWxlcyBhbmQgbGltaXRzLgoKDQoFBAMCBQYSBMgBAhUKDQoFBAMCBQES
BMgBFhwKDQoFBAMCBQMSBMgBHyAKDQoFBAMCBQgSBMgBIUsKEAoIBAMCBQicCAASBMgBIkoK
gQEKBAQDAgYSBswBAs0BMhpxIE91dHB1dCBvbmx5LiBTdGFydCB0aW1lIGZvciB0aGUgcHJv
ZmlsZS4KIFRoaXMgb3V0cHV0IGlzIG9ubHkgcHJlc2VudCBpbiByZXNwb25zZSBmcm9tIHRo
ZSBMaXN0UHJvZmlsZXMgbWV0aG9kLgoKDQoFBAMCBgYSBMwBAhsKDQoFBAMCBgESBMwBHCYK
DQoFBAMCBgMSBMwBKSoKDQoFBAMCBggSBM0BBjEKEAoIBAMCBgicCAASBM0BBzAKTgoCBAQS
BtEBAOwBARpAIERlcGxveW1lbnQgY29udGFpbnMgdGhlIGRlcGxveW1lbnQgaWRlbnRpZmlj
YXRpb24gaW5mb3JtYXRpb24uCgoLCgMEBAESBNEBCBIKbwoEBAQCABIE1AECGBphIFByb2pl
Y3QgSUQgaXMgdGhlIElEIG9mIGEgY2xvdWQgcHJvamVjdC4KIFZhbGlkYXRpb24gcmVnZXg6
IGBeW2Etel1bLWEtejAtOTouXXs0LDYxfVthLXowLTldJGAuCgoNCgUEBAIABRIE1AECCAoN
CgUEBAIAARIE1AEJEwoNCgUEBAIAAxIE1AEWFwrHAgoEBAQCARIE3AECFBq4AiBUYXJnZXQg
aXMgdGhlIHNlcnZpY2UgbmFtZSB1c2VkIHRvIGdyb3VwIHJlbGF0ZWQgZGVwbG95bWVudHM6
CiAqIFNlcnZpY2UgbmFtZSBmb3IgQXBwIEVuZ2luZSBGbGV4IC8gU3RhbmRhcmQuCiAqIENs
dXN0ZXIgYW5kIGNvbnRhaW5lciBuYW1lIGZvciBHS0UuCiAqIFVzZXItc3BlY2lmaWVkIHN0
cmluZyBmb3IgZGlyZWN0IENvbXB1dGUgRW5naW5lIHByb2ZpbGluZyAoZS5nLiBKYXZhKS4K
ICogSm9iIG5hbWUgZm9yIERhdGFmbG93LgogVmFsaWRhdGlvbiByZWdleDogYF5bYS16MC05
XShbLWEtejAtOV8uXXswLDI1M31bYS16MC05XSk/JGAuCgoNCgUEBAIBBRIE3AECCAoNCgUE
BAIBARIE3AEJDwoNCgUEBAIBAxIE3AESEwrSBQoEBAQCAhIE6wECIRrDBSBMYWJlbHMgaWRl
bnRpZnkgdGhlIGRlcGxveW1lbnQgd2l0aGluIHRoZSB1c2VyIHVuaXZlcnNlIGFuZCBzYW1l
IHRhcmdldC4KIFZhbGlkYXRpb24gcmVnZXggZm9yIGxhYmVsIG5hbWVzOiBgXlthLXowLTld
KFthLXowLTktXXswLDYxfVthLXowLTldKT8kYC4KIFZhbHVlIGZvciBhbiBpbmRpdmlkdWFs
IGxhYmVsIG11c3QgYmUgPD0gNTEyIGJ5dGVzLCB0aGUgdG90YWwKIHNpemUgb2YgYWxsIGxh
YmVsIG5hbWVzIGFuZCB2YWx1ZXMgbXVzdCBiZSA8PSAxMDI0IGJ5dGVzLgoKIExhYmVsIG5h
bWVkICJsYW5ndWFnZSIgY2FuIGJlIHVzZWQgdG8gcmVjb3JkIHRoZSBwcm9ncmFtbWluZyBs
YW5ndWFnZSBvZgogdGhlIHByb2ZpbGVkIGRlcGxveW1lbnQuIFRoZSBzdGFuZGFyZCBjaG9p
Y2VzIGZvciB0aGUgdmFsdWUgaW5jbHVkZSAiamF2YSIsCiAiZ28iLCAicHl0aG9uIiwgInJ1
YnkiLCAibm9kZWpzIiwgInBocCIsICJkb3RuZXQiLgoKIEZvciBkZXBsb3ltZW50cyBydW5u
aW5nIG9uIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSwgInpvbmUiIG9yICJyZWdpb24iIGxhYmVs
CiBzaG91bGQgYmUgcHJlc2VudCBkZXNjcmliaW5nIHRoZSBkZXBsb3ltZW50IGxvY2F0aW9u
LiBBbiBleGFtcGxlIG9mIGEgem9uZQogaXMgInVzLWNlbnRyYWwxLWEiLCBhbiBleGFtcGxl
IG9mIGEgcmVnaW9uIGlzICJ1cy1jZW50cmFsMSIgb3IKICJ1cy1jZW50cmFsIi4KCg0KBQQE
AgIGEgTrAQIVCg0KBQQEAgIBEgTrARYcCg0KBQQEAgIDEgTrAR8gCsABCgIFABIG8QEAjwIB
GrEBIFByb2ZpbGVUeXBlIGlzIHR5cGUgb2YgcHJvZmlsaW5nIGRhdGEuCiBOT1RFOiB0aGUg
ZW51bWVyYXRpb24gbWVtYmVyIG5hbWVzIGFyZSB1c2VkIChpbiBsb3dlcmNhc2UpIGFzIHVu
aXF1ZSBzdHJpbmcKIGlkZW50aWZpZXJzIG9mIHByb2ZpbGUgdHlwZXMsIHNvIHRoZXkgbXVz
dCBub3QgYmUgcmVuYW1lZC4KCgsKAwUAARIE8QEFEAopCgQFAAIAEgTzAQIfGhsgVW5zcGVj
aWZpZWQgcHJvZmlsZSB0eXBlLgoKDQoFBQACAAESBPMBAhoKDQoFBQACAAISBPMBHR4KKQoE
BQACARIE9gECChobIFRocmVhZCBDUFUgdGltZSBzYW1wbGluZy4KCg0KBQUAAgEBEgT2AQIF
Cg0KBQUAAgECEgT2AQgJCk0KBAUAAgISBPkBAgsaPyBXYWxsY2xvY2sgdGltZSBzYW1wbGlu
Zy4gTW9yZSBleHBlbnNpdmUgYXMgc3RvcHMgYWxsIHRocmVhZHMuCgoNCgUFAAICARIE+QEC
BgoNCgUFAAICAhIE+QEJCgp6CgQFAAIDEgT9AQILGmwgSW4tdXNlIGhlYXAgcHJvZmlsZS4g
UmVwcmVzZW50cyBhIHNuYXBzaG90IG9mIHRoZSBhbGxvY2F0aW9ucyB0aGF0IGFyZQogbGl2
ZSBhdCB0aGUgdGltZSBvZiB0aGUgcHJvZmlsaW5nLgoKDQoFBQACAwESBP0BAgYKDQoFBQAC
AwISBP0BCQoKPAoEBQACBBIEgAICDhouIFNpbmdsZS1zaG90IGNvbGxlY3Rpb24gb2YgYWxs
IHRocmVhZCBzdGFja3MuCgoNCgUFAAIEARIEgAICCQoNCgUFAAIEAhIEgAIMDQozCgQFAAIF
EgSDAgIRGiUgU3luY2hyb25pemF0aW9uIGNvbnRlbnRpb24gcHJvZmlsZS4KCg0KBQUAAgUB
EgSDAgIMCg0KBQUAAgUCEgSDAg8QCiIKBAUAAgYSBIYCAhAaFCBQZWFrIGhlYXAgcHJvZmls
ZS4KCg0KBQUAAgYBEgSGAgILCg0KBQUAAgYCEgSGAg4PCrEDCgQFAAIHEgSOAgIRGqIDIEhl
YXAgYWxsb2NhdGlvbiBwcm9maWxlLiBJdCByZXByZXNlbnRzIHRoZSBhZ2dyZWdhdGlvbiBv
ZiBhbGwgYWxsb2NhdGlvbnMKIG1hZGUgb3ZlciB0aGUgZHVyYXRpb24gb2YgdGhlIHByb2Zp
bGUuIEFsbCBhbGxvY2F0aW9ucyBhcmUgaW5jbHVkZWQsCiBpbmNsdWRpbmcgdGhvc2UgdGhh
dCBtaWdodCBoYXZlIGJlZW4gZnJlZWQgYnkgdGhlIGVuZCBvZiB0aGUgcHJvZmlsaW5nCiBp
bnRlcnZhbC4gVGhlIHByb2ZpbGUgaXMgaW4gcGFydGljdWxhciB1c2VmdWwgZm9yIGdhcmJh
Z2UgY29sbGVjdGluZwogbGFuZ3VhZ2VzIHRvIHVuZGVyc3RhbmQgd2hpY2ggcGFydHMgb2Yg
dGhlIGNvZGUgY3JlYXRlIG1vc3Qgb2YgdGhlIGdhcmJhZ2UKIGNvbGxlY3Rpb24gcHJlc3N1
cmUgdG8gc2VlIGlmIHRob3NlIGNhbiBiZSBvcHRpbWl6ZWQuCgoNCgUFAAIHARIEjgICDAoN
CgUFAAIHAhIEjgIPEAqaAQoCBAUSBpMCAKYCARqLASBMaXN0UHJvZmlsZXNSZXF1ZXN0IGNv
bnRhaW5zIHJlcXVlc3QgcGFyYW1ldGVycyBmb3IgbGlzdGluZyBwcm9maWxlcyBmb3IKIGRl
cGxveW1lbnRzIGluIHByb2plY3RzIHdoaWNoIHRoZSB1c2VyIGhhcyBwZXJtaXNzaW9ucyB0
byB2aWV3LgoKCwoDBAUBEgSTAggbCnMKBAQFAgASBpYCApsCBBpjIFJlcXVpcmVkLiBUaGUg
cGFyZW50LCB3aGljaCBvd25zIHRoaXMgY29sbGVjdGlvbiBvZiBwcm9maWxlcy4KIEZvcm1h
dDogcHJvamVjdHMve3VzZXJfcHJvamVjdF9pZH0KCg0KBQQFAgAFEgSWAgIICg0KBQQFAgAB
EgSWAgkPCg0KBQQFAgADEgSWAhITCg8KBQQFAgAIEgaWAhSbAgMKEAoIBAUCAAicCAASBJcC
BCoKEQoHBAUCAAifCBIGmAIEmgIFCmYKBAQFAgESBKACAhYaWCBUaGUgbWF4aW11bSBudW1i
ZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgogRGVmYXVsdCBwYWdlX3NpemUgaXMgMTAwMC4KIE1h
eCBsaW1pdCBpcyAxMDAwLgoKDQoFBAUCAQUSBKACAgcKDQoFBAUCAQESBKACCBEKDQoFBAUC
AQMSBKACFBUKzwEKBAQFAgISBKUCAhgawAEgVGhlIHRva2VuIHRvIGNvbnRpbnVlIHBhZ2lu
YXRpb24gYW5kIGdldCBwcm9maWxlcyBmcm9tIGEgcGFydGljdWxhciBwYWdlLgogV2hlbiBw
YWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBgTGlzdFByb2Zp
bGVzYCBtdXN0IG1hdGNoCiB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2Vu
LgoKDQoFBAUCAgUSBKUCAggKDQoFBAUCAgESBKUCCRMKDQoFBAUCAgMSBKUCFhcKkQEKAgQG
EgaqAgC3AgEaggEgTGlzdFByb2ZpbGVSZXNwb25zZSBjb250YWlucyB0aGUgbGlzdCBvZiBj
b2xsZWN0ZWQgcHJvZmlsZXMgZm9yIGRlcGxveW1lbnRzCiBpbiBwcm9qZWN0cyB3aGljaCB0
aGUgdXNlciBoYXMgcGVybWlzc2lvbnMgdG8gdmlldy4KCgsKAwQGARIEqgIIHAopCgQEBgIA
EgSsAgIgGhsgTGlzdCBvZiBwcm9maWxlcyBmZXRjaGVkLgoKDQoFBAYCAAQSBKwCAgoKDQoF
BAYCAAYSBKwCCxIKDQoFBAYCAAESBKwCExsKDQoFBAYCAAMSBKwCHh8KegoEBAYCARIEsAIC
HRpsIFRva2VuIHRvIHJlY2VpdmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLgogVGhpcyBm
aWVsZCBtYXliZSBlbXB0eSBpZiB0aGVyZSBhcmUgbm8gbW9yZSBwcm9maWxlcyB0byBmZXRj
aC4KCg0KBQQGAgEFEgSwAgIICg0KBQQGAgEBEgSwAgkYCg0KBQQGAgEDEgSwAhscCqcCCgQE
BgICEgS2AgIdGpgCIE51bWJlciBvZiBwcm9maWxlcyB0aGF0IHdlcmUgc2tpcHBlZCBpbiB0
aGUgY3VycmVudCBwYWdlIHNpbmNlIHRoZXkgd2VyZQogbm90IGFibGUgdG8gYmUgZmV0Y2hl
ZCBzdWNjZXNzZnVsbHkuIFRoaXMgc2hvdWxkIHR5cGljYWxseSBiZSB6ZXJvLiBBCiBub24t
emVybyB2YWx1ZSBtYXkgaW5kaWNhdGUgYSB0cmFuc2llbnQgZmFpbHVyZSwgaW4gd2hpY2gg
Y2FzZSBpZiB0aGUKIG51bWJlciBpcyB0b28gaGlnaCBmb3IgeW91ciB1c2UgY2FzZSwgdGhl
IGNhbGwgbWF5IGJlIHJldHJpZWQuCgoNCgUEBgICBRIEtgICBwoNCgUEBgICARIEtgIIGAoN
CgUEBgICAxIEtgIbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest ===
    # Fields for CreateProfileRequest
    # Field: parent Type: 9 ()
    # Field: deployment Type: 11 (.google.devtools.cloudprofiler.v2.Deployment)
    # Field: profile_type Type: 14 (.google.devtools.cloudprofiler.v2.ProfileType)

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::CreateOfflineProfileRequest ===
    # Fields for CreateOfflineProfileRequest
    # Field: parent Type: 9 ()
    # Field: profile Type: 11 (.google.devtools.cloudprofiler.v2.Profile)

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::UpdateProfileRequest ===
    # Fields for UpdateProfileRequest
    # Field: profile Type: 11 (.google.devtools.cloudprofiler.v2.Profile)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::Profile ===
    # Fields for Profile
    # Field: name Type: 9 ()
    # Field: profile_type Type: 14 (.google.devtools.cloudprofiler.v2.ProfileType)
    # Field: deployment Type: 11 (.google.devtools.cloudprofiler.v2.Deployment)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: profile_bytes Type: 12 ()
    # Field: labels Type: 11 (.google.devtools.cloudprofiler.v2.Profile.LabelsEntry)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::Deployment ===
    # Fields for Deployment
    # Field: project_id Type: 9 ()
    # Field: target Type: 9 ()
    # Field: labels Type: 11 (.google.devtools.cloudprofiler.v2.Deployment.LabelsEntry)

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesRequest ===
    # Fields for ListProfilesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesResponse ===
    # Fields for ListProfilesResponse
    # Field: profiles Type: 11 (.google.devtools.cloudprofiler.v2.Profile)
    # Field: next_page_token Type: 9 ()
    # Field: skipped_profiles Type: 5 ()

# === Service Client: Google::Devtools::Cloudprofiler::V2::Profiler::ProfilerServiceClient ===
package Google::Devtools::Cloudprofiler::V2::Profiler::ProfilerServiceClient;

=pod

=head2 Service Client: Google::Devtools::Cloudprofiler::V2::Profiler::ProfilerServiceClient

Client stub representing the remote C<ProfilerService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub create_profile {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudprofiler.v2.ProfilerService',
        method         => 'CreateProfile',
        request        => $req,
        response_class => 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile',
    });
}

sub create_offline_profile {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudprofiler::V2::Profiler::CreateOfflineProfileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudprofiler.v2.ProfilerService',
        method         => 'CreateOfflineProfile',
        request        => $req,
        response_class => 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile',
    });
}

sub update_profile {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudprofiler::V2::Profiler::UpdateProfileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudprofiler.v2.ProfilerService',
        method         => 'UpdateProfile',
        request        => $req,
        response_class => 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile',
    });
}

# === Service Client: Google::Devtools::Cloudprofiler::V2::Profiler::ExportServiceClient ===
package Google::Devtools::Cloudprofiler::V2::Profiler::ExportServiceClient;

=pod

=head2 Service Client: Google::Devtools::Cloudprofiler::V2::Profiler::ExportServiceClient

Client stub representing the remote C<ExportService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub list_profiles {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudprofiler.v2.ExportService',
        method         => 'ListProfiles',
        request        => $req,
        response_class => 'Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Cloudprofiler::V2::Profiler - Compiled Protocol Buffers messages for google/devtools/cloudprofiler/v2/profiler.proto

=head1 SYNOPSIS

    use Google::Devtools::Cloudprofiler::V2::Profiler;

    my $msg = Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest->new({
        parent => $parent,
        deployment => $deployment,
        profile_type => $profile_type,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/cloudprofiler/v2/profiler.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest

CreateProfileRequest describes a profile resource online creation request.
The deployment field must be populated. The profile_type specifies the list
of profile types supported by the agent. The creation call will hang until a
profile of one of these types needs to be collected.


Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Parent project to create the profile in.

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Deployment>)

Deployment details.

=item * C<< $msg->profile_type() >> / C<< $msg->profile_type($value) >>

Type: C<Enum> (L<Google::Devtools::Cloudprofiler::V2::ProfileType>)

One or more profile types that the agent is capable of providing.

=back

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::CreateOfflineProfileRequest

CreateOfflineProfileRequest describes a profile resource offline creation
request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Parent project to create the profile in.

=item * C<< $msg->profile() >> / C<< $msg->profile($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Profile>)

Contents of the profile to create.

=back

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::UpdateProfileRequest

UpdateProfileRequest contains the profile to update.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->profile() >> / C<< $msg->profile($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Profile>)

Profile to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask used to specify the fields to be overwritten. Currently only
profile_bytes and labels fields are supported by UpdateProfile, so only
those fields can be specified in the mask. When no mask is provided, all
fields are overwritten.

=back

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::Profile

Profile resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Opaque, server-assigned, unique ID for this profile.

=item * C<< $msg->profile_type() >> / C<< $msg->profile_type($value) >>

Type: C<Enum> (L<Google::Devtools::Cloudprofiler::V2::ProfileType>)

Type of profile.
For offline mode, this must be specified when creating the profile. For
online mode it is assigned and returned by the server.

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Deployment>)

Deployment this profile corresponds to.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration of the profiling session.
Input (for the offline mode) or output (for the online mode).
The field represents requested profiling duration. It may slightly differ
from the effective profiling duration, which is recorded in the profile
data, in case the profiling can't be stopped immediately (e.g. in case
stopping the profiling is handled asynchronously).

=item * C<< $msg->profile_bytes() >> / C<< $msg->profile_bytes($value) >>

Type: C<Bytes>

Input only. Profile bytes, as a gzip compressed serialized proto, the
format is https://github.com/google/pprof/blob/master/proto/profile.proto.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Profile::LabelsEntry>)

Input only. Labels associated to this specific profile. These labels will
get merged with the deployment labels for the final data set. See
documentation on deployment labels for validation rules and limits.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Start time for the profile.
This output is only present in response from the ListProfiles method.

=back

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::Deployment

Deployment contains the deployment identification information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Project ID is the ID of a cloud project.
Validation regex: `^[a-z][-a-z0-9:.]{4,61}[a-z0-9]$`.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Target is the service name used to group related deployments:
* Service name for App Engine Flex / Standard.
* Cluster and container name for GKE.
* User-specified string for direct Compute Engine profiling (e.g. Java).
* Job name for Dataflow.
Validation regex: `^[a-z0-9]([-a-z0-9_.]{0,253}[a-z0-9])?$`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Deployment::LabelsEntry>)

Labels identify the deployment within the user universe and same target.
Validation regex for label names: `^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$`.
Value for an individual label must be <= 512 bytes, the total
size of all label names and values must be <= 1024 bytes.

Label named "language" can be used to record the programming language of
the profiled deployment. The standard choices for the value include "java",
"go", "python", "ruby", "nodejs", "php", "dotnet".

For deployments running on Google Cloud Platform, "zone" or "region" label
should be present describing the deployment location. An example of a zone
is "us-central1-a", an example of a region is "us-central1" or
"us-central".

=back

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesRequest

ListProfilesRequest contains request parameters for listing profiles for
deployments in projects which the user has permissions to view.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of profiles.
Format: projects/{user_project_id}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.
Default page_size is 1000.
Max limit is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The token to continue pagination and get profiles from a particular page.
When paginating, all other parameters provided to `ListProfiles` must match
the call that provided the page token.

=back

=head2 Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesResponse

ListProfileResponse contains the list of collected profiles for deployments
in projects which the user has permissions to view.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->profiles() >> / C<< $msg->profiles($value) >>

Type: C<Message> (L<Google::Devtools::Cloudprofiler::V2::Profiler::Profile>)

List of profiles fetched.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to receive the next page of results.
This field maybe empty if there are no more profiles to fetch.

=item * C<< $msg->skipped_profiles() >> / C<< $msg->skipped_profiles($value) >>

Type: C<Int32>

Number of profiles that were skipped in the current page since they were
not able to be fetched successfully. This should typically be zero. A
non-zero value may indicate a transient failure, in which case if the
number is too high for your use case, the call may be retried.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Cloudprofiler::V2::Profiler::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
