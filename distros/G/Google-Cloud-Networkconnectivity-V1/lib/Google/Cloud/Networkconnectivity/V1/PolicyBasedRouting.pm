package Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting;

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
    eval { require Google::Cloud::Networkconnectivity::V1::Common };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvbmV0d29ya2Nvbm5lY3Rpdml0eS92MS9wb2xpY3lfYmFzZWRfcm91
dGluZy5wcm90bxIjZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GjBnb29nbGUvY2xvdWQvbmV0d29ya2Nvbm5lY3Rpdml0eS92MS9jb21tb24ucHJvdG8aI2dv
b2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i+BAKEFBvbGljeUJh
c2VkUm91dGUSdAoPdmlydHVhbF9tYWNoaW5lGBIgASgLMkQuZ29vZ2xlLmNsb3VkLm5ldHdv
cmtjb25uZWN0aXZpdHkudjEuUG9saWN5QmFzZWRSb3V0ZS5WaXJ0dWFsTWFjaGluZUID4EEB
SABSDnZpcnR1YWxNYWNoaW5lEowBChdpbnRlcmNvbm5lY3RfYXR0YWNobWVudBgJIAEoCzJM
Lmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxLlBvbGljeUJhc2VkUm91dGUu
SW50ZXJjb25uZWN0QXR0YWNobWVudEID4EEBSABSFmludGVyY29ubmVjdEF0dGFjaG1lbnQS
LAoPbmV4dF9ob3BfaWxiX2lwGAwgASgJQgPgQQFIAVIMbmV4dEhvcElsYklwEnsKFW5leHRf
aG9wX290aGVyX3JvdXRlcxgVIAEoDjJBLmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2
aXR5LnYxLlBvbGljeUJhc2VkUm91dGUuT3RoZXJSb3V0ZXNCA+BBAUgBUhJuZXh0SG9wT3Ro
ZXJSb3V0ZXMSFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0
ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVU
aW1lElkKBmxhYmVscxgEIAMoCzJBLmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5
LnYxLlBvbGljeUJhc2VkUm91dGUuTGFiZWxzRW50cnlSBmxhYmVscxIlCgtkZXNjcmlwdGlv
bhgFIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJACgduZXR3b3JrGAYgASgJQibgQQL6QSAKHmNv
bXB1dGUuZ29vZ2xlYXBpcy5jb20vTmV0d29ya1IHbmV0d29yaxJZCgZmaWx0ZXIYCiABKAsy
PC5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MS5Qb2xpY3lCYXNlZFJvdXRl
LkZpbHRlckID4EECUgZmaWx0ZXISHwoIcHJpb3JpdHkYCyABKAVCA+BBAVIIcHJpb3JpdHkS
XwoId2FybmluZ3MYDiADKAsyPi5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52
MS5Qb2xpY3lCYXNlZFJvdXRlLldhcm5pbmdzQgPgQQNSCHdhcm5pbmdzEiAKCXNlbGZfbGlu
axgPIAEoCUID4EEDUghzZWxmTGluaxIXCgRraW5kGBAgASgJQgPgQQNSBGtpbmQaKQoOVmly
dHVhbE1hY2hpbmUSFwoEdGFncxgBIAMoCUID4EEBUgR0YWdzGjUKFkludGVyY29ubmVjdEF0
dGFjaG1lbnQSGwoGcmVnaW9uGAEgASgJQgPgQQFSBnJlZ2lvbhqxAgoGRmlsdGVyEiQKC2lw
X3Byb3RvY29sGAEgASgJQgPgQQFSCmlwUHJvdG9jb2wSIAoJc3JjX3JhbmdlGAIgASgJQgPg
QQFSCHNyY1JhbmdlEiIKCmRlc3RfcmFuZ2UYAyABKAlCA+BBAVIJZGVzdFJhbmdlEnwKEHBy
b3RvY29sX3ZlcnNpb24YBiABKA4yTC5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0
eS52MS5Qb2xpY3lCYXNlZFJvdXRlLkZpbHRlci5Qcm90b2NvbFZlcnNpb25CA+BBAlIPcHJv
dG9jb2xWZXJzaW9uIj0KD1Byb3RvY29sVmVyc2lvbhIgChxQUk9UT0NPTF9WRVJTSU9OX1VO
U1BFQ0lGSUVEEAASCAoESVBWNBABGokDCghXYXJuaW5ncxJcCgRjb2RlGAEgASgOMkMuZ29v
Z2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjEuUG9saWN5QmFzZWRSb3V0ZS5XYXJu
aW5ncy5Db2RlQgPgQQNSBGNvZGUSYQoEZGF0YRgCIAMoCzJILmdvb2dsZS5jbG91ZC5uZXR3
b3JrY29ubmVjdGl2aXR5LnYxLlBvbGljeUJhc2VkUm91dGUuV2FybmluZ3MuRGF0YUVudHJ5
QgPgQQNSBGRhdGESLAoPd2FybmluZ19tZXNzYWdlGAMgASgJQgPgQQNSDndhcm5pbmdNZXNz
YWdlGjcKCURhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIlUKBENvZGUSFwoTV0FSTklOR19VTlNQRUNJRklFRBAAEhcKE1JFU09VUkNFX05P
VF9BQ1RJVkUQARIbChdSRVNPVVJDRV9CRUlOR19NT0RJRklFRBACGjkKC0xhYmVsc0VudHJ5
EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiQAoLT3RoZXJS
b3V0ZXMSHAoYT1RIRVJfUk9VVEVTX1VOU1BFQ0lGSUVEEAASEwoPREVGQVVMVF9ST1VUSU5H
EAE6hQHqQYEBCjNuZXR3b3JrY29ubmVjdGl2aXR5Lmdvb2dsZWFwaXMuY29tL1BvbGljeUJh
c2VkUm91dGUSSnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMvZ2xvYmFsL1BvbGljeUJh
c2VkUm91dGVzL3twb2xpY3lfYmFzZWRfcm91dGV9QggKBnRhcmdldEIKCghuZXh0X2hvcCLQ
AQocTGlzdFBvbGljeUJhc2VkUm91dGVzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpB
IwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSGwoJcGFnZV9z
aXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoG
ZmlsdGVyGAQgASgJUgZmaWx0ZXISGQoIb3JkZXJfYnkYBSABKAlSB29yZGVyQnki0AEKHUxp
c3RQb2xpY3lCYXNlZFJvdXRlc1Jlc3BvbnNlEmUKE3BvbGljeV9iYXNlZF9yb3V0ZXMYASAD
KAsyNS5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MS5Qb2xpY3lCYXNlZFJv
dXRlUhFwb2xpY3lCYXNlZFJvdXRlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIm0KGkdldFBvbGlj
eUJhc2VkUm91dGVSZXF1ZXN0Ek8KBG5hbWUYASABKAlCO+BBAvpBNQozbmV0d29ya2Nvbm5l
Y3Rpdml0eS5nb29nbGVhcGlzLmNvbS9Qb2xpY3lCYXNlZFJvdXRlUgRuYW1lIqgCCh1DcmVh
dGVQb2xpY3lCYXNlZFJvdXRlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9j
YXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSNgoVcG9saWN5X2Jhc2Vk
X3JvdXRlX2lkGAIgASgJQgPgQQJSEnBvbGljeUJhc2VkUm91dGVJZBJoChJwb2xpY3lfYmFz
ZWRfcm91dGUYAyABKAsyNS5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MS5Q
b2xpY3lCYXNlZFJvdXRlQgPgQQJSEHBvbGljeUJhc2VkUm91dGUSIgoKcmVxdWVzdF9pZBgE
IAEoCUID4EEBUglyZXF1ZXN0SWQilAEKHURlbGV0ZVBvbGljeUJhc2VkUm91dGVSZXF1ZXN0
Ek8KBG5hbWUYASABKAlCO+BBAvpBNQozbmV0d29ya2Nvbm5lY3Rpdml0eS5nb29nbGVhcGlz
LmNvbS9Qb2xpY3lCYXNlZFJvdXRlUgRuYW1lEiIKCnJlcXVlc3RfaWQYAiABKAlCA+BBAVIJ
cmVxdWVzdElkMuMIChlQb2xpY3lCYXNlZFJvdXRpbmdTZXJ2aWNlEusBChVMaXN0UG9saWN5
QmFzZWRSb3V0ZXMSQS5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MS5MaXN0
UG9saWN5QmFzZWRSb3V0ZXNSZXF1ZXN0GkIuZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0
aXZpdHkudjEuTGlzdFBvbGljeUJhc2VkUm91dGVzUmVzcG9uc2UiS4LT5JMCPBI6L3YxL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsfS9wb2xpY3lCYXNlZFJvdXRlc9pB
BnBhcmVudBLYAQoTR2V0UG9saWN5QmFzZWRSb3V0ZRI/Lmdvb2dsZS5jbG91ZC5uZXR3b3Jr
Y29ubmVjdGl2aXR5LnYxLkdldFBvbGljeUJhc2VkUm91dGVSZXF1ZXN0GjUuZ29vZ2xlLmNs
b3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjEuUG9saWN5QmFzZWRSb3V0ZSJJgtPkkwI8Ejov
djEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL3BvbGljeUJhc2VkUm91dGVz
Lyp92kEEbmFtZRKuAgoWQ3JlYXRlUG9saWN5QmFzZWRSb3V0ZRJCLmdvb2dsZS5jbG91ZC5u
ZXR3b3JrY29ubmVjdGl2aXR5LnYxLkNyZWF0ZVBvbGljeUJhc2VkUm91dGVSZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKwAYLT5JMCUCI6L3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsfS9wb2xpY3lCYXNlZFJvdXRlczoScG9saWN5X2Jh
c2VkX3JvdXRl2kEvcGFyZW50LHBvbGljeV9iYXNlZF9yb3V0ZSxwb2xpY3lfYmFzZWRfcm91
dGVfaWTKQSUKEFBvbGljeUJhc2VkUm91dGUSEU9wZXJhdGlvbk1ldGFkYXRhEvMBChZEZWxl
dGVQb2xpY3lCYXNlZFJvdXRlEkIuZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHku
djEuRGVsZXRlUG9saWN5QmFzZWRSb3V0ZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uInaC0+STAjwqOi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9i
YWwvcG9saWN5QmFzZWRSb3V0ZXMvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9idWYuRW1w
dHkSEU9wZXJhdGlvbk1ldGFkYXRhGlbKQSJuZXR3b3JrY29ubmVjdGl2aXR5Lmdvb2dsZWFw
aXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bUKUAgonY29tLmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxQhdQb2xpY3lC
YXNlZFJvdXRpbmdQcm90b1ABWlljbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtjb25uZWN0
aXZpdHkvYXBpdjEvbmV0d29ya2Nvbm5lY3Rpdml0eXBiO25ldHdvcmtjb25uZWN0aXZpdHlw
YqoCI0dvb2dsZS5DbG91ZC5OZXR3b3JrQ29ubmVjdGl2aXR5LlYxygIjR29vZ2xlXENsb3Vk
XE5ldHdvcmtDb25uZWN0aXZpdHlcVjHqAiZHb29nbGU6OkNsb3VkOjpOZXR3b3JrQ29ubmVj
dGl2aXR5OjpWMUqlbwoHEgUOAP8CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
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
ZS4KCggKAQISAxAALAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWADoKCQoCAwUSAxcALQoJCgIDBhIDGAAlCgkKAgMHEgMZACkKCAoBCBID
GwBACgkKAgglEgMbAEAKCAoBCBIDHABwCgkKAggLEgMcAHAKCAoBCBIDHQAiCgkKAggKEgMd
ACIKCAoBCBIDHgA4CgkKAggIEgMeADgKCAoBCBIDHwBACgkKAggBEgMfAEAKCAoBCBIDIABA
CgkKAggpEgMgAEAKCAoBCBIDIQA/CgkKAggtEgMhAD8KnQEKAgYAEgQlAFcBGpABIFBvbGlj
eS1CYXNlZCBSb3V0aW5nIGFsbG93cyBHQ1AgY3VzdG9tZXJzIHRvIHNwZWNpZnkgZmxleGli
aWxlIHJvdXRpbmcKIHBvbGljaWVzIGZvciBMYXllciA0IHRyYWZmaWMgdHJhdmVyc2luZyB0
aHJvdWdoIHRoZSBjb25uZWN0ZWQgc2VydmljZS4KCgoKAwYAARIDJQghCgoKAwYAAxIDJgJK
CgwKBQYAA5kIEgMmAkoKCwoDBgADEgQnAig3Cg0KBQYAA5oIEgQnAig3CkoKBAYAAgASBCsC
MQMaPCBMaXN0cyBwb2xpY3ktYmFzZWQgcm91dGVzIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQg
bG9jYXRpb24uCgoMCgUGAAIAARIDKwYbCgwKBQYAAgACEgMrHDgKDAoFBgACAAMSAywPLAoN
CgUGAAIABBIELQQvBgoRCgkGAAIABLDKvCISBC0ELwYKDAoFBgACAAQSAzAENAoPCggGAAIA
BJsIABIDMAQ0CjwKBAYAAgESBDQCOgMaLiBHZXRzIGRldGFpbHMgb2YgYSBzaW5nbGUgcG9s
aWN5LWJhc2VkIHJvdXRlLgoKDAoFBgACAQESAzQGGQoMCgUGAAIBAhIDNBo0CgwKBQYAAgED
EgM1Dx8KDQoFBgACAQQSBDYEOAYKEQoJBgACAQSwyrwiEgQ2BDgGCgwKBQYAAgEEEgM5BDIK
DwoIBgACAQSbCAASAzkEMgpRCgQGAAICEgQ9AkkDGkMgQ3JlYXRlcyBhIG5ldyBwb2xpY3kt
YmFzZWQgcm91dGUgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgIB
EgM9BhwKDAoFBgACAgISAz0dOgoMCgUGAAICAxIDPg8rCg0KBQYAAgIEEgQ/BEIGChEKCQYA
AgIEsMq8IhIEPwRCBgoNCgUGAAICBBIEQwREOgoQCggGAAICBJsIABIEQwREOgoNCgUGAAIC
BBIERQRIBgoPCgcGAAICBJkIEgRFBEgGCjQKBAYAAgMSBEwCVgMaJiBEZWxldGVzIGEgc2lu
Z2xlIHBvbGljeS1iYXNlZCByb3V0ZS4KCgwKBQYAAgMBEgNMBhwKDAoFBgACAwISA0wdOgoM
CgUGAAIDAxIDTQ8rCg0KBQYAAgMEEgROBFAGChEKCQYAAgMEsMq8IhIETgRQBgoMCgUGAAID
BBIDUQQyCg8KCAYAAgMEmwgAEgNRBDIKDQoFBgACAwQSBFIEVQYKDwoHBgACAwSZCBIEUgRV
BgqHAgoCBAASBV0AhAIBGvkBIFBvbGljeS1iYXNlZCByb3V0ZXMgcm91dGUgTDQgbmV0d29y
ayB0cmFmZmljIGJhc2VkIG9uIG5vdCBqdXN0IGRlc3RpbmF0aW9uIElQCiBhZGRyZXNzLCBi
dXQgYWxzbyBzb3VyY2UgSVAgYWRkcmVzcywgcHJvdG9jb2wsIGFuZCBtb3JlLiBJZiBhIHBv
bGljeS1iYXNlZAogcm91dGUgY29uZmxpY3RzIHdpdGggb3RoZXIgdHlwZXMgb2Ygcm91dGVz
LCB0aGUgcG9saWN5LWJhc2VkIHJvdXRlIGFsd2F5cwogdGFrZXMgcHJlY2VkZW5jZS4KCgoK
AwQAARIDXQgYCgsKAwQABxIEXgJhBAoNCgUEAAedCBIEXgJhBApFCgQEAAMAEgRkAmgDGjcg
Vk0gaW5zdGFuY2VzIHRoYXQgdGhpcyBwb2xpY3ktYmFzZWQgcm91dGUgYXBwbGllcyB0by4K
CgwKBQQAAwABEgNkChgKpQEKBgQAAwACABIDZwRGGpUBIE9wdGlvbmFsLiBBIGxpc3Qgb2Yg
Vk0gaW5zdGFuY2UgdGFncyB0aGF0IHRoaXMgcG9saWN5LWJhc2VkIHJvdXRlIGFwcGxpZXMK
IHRvLiBWTSBpbnN0YW5jZXMgdGhhdCBoYXZlIEFOWSBvZiB0YWdzIHNwZWNpZmllZCBoZXJl
IGluc3RhbGxzIHRoaXMgUEJSLgoKDgoHBAADAAIABBIDZwQMCg4KBwQAAwACAAUSA2cNEwoO
CgcEAAMAAgABEgNnFBgKDgoHBAADAAIAAxIDZxscCg4KBwQAAwACAAgSA2cdRQoRCgoEAAMA
AgAInAgAEgNnHkQKQgoEBAADARIEawJvAxo0IEludGVyY29ubmVjdEF0dGFjaG1lbnQgdGhh
dCB0aGlzIHJvdXRlIGFwcGxpZXMgdG8uCgoMCgUEAAMBARIDawogCqEBCgYEAAMBAgASA24E
PxqRASBPcHRpb25hbC4gQ2xvdWQgcmVnaW9uIHRvIGluc3RhbGwgdGhpcyBwb2xpY3ktYmFz
ZWQgcm91dGUgb24gaW50ZXJjb25uZWN0CiBhdHRhY2htZW50LiBVc2UgYGFsbGAgdG8gaW5z
dGFsbCBpdCBvbiBhbGwgaW50ZXJjb25uZWN0IGF0dGFjaG1lbnRzLgoKDgoHBAADAQIABRID
bgQKCg4KBwQAAwECAAESA24LEQoOCgcEAAMBAgADEgNuFBUKDgoHBAADAQIACBIDbhY+ChEK
CgQAAwECAAicCAASA24XPQorCgQEAAMCEgVyAo0BAxocIEZpbHRlciBtYXRjaGVzIEw0IHRy
YWZmaWMuCgoMCgUEAAMCARIDcgoQCjAKBgQAAwIEABIEdAR6BRogIFRoZSBpbnRlcm5ldCBw
cm90b2NvbCB2ZXJzaW9uLgoKDgoHBAADAgQAARIDdAkYCiEKCAQAAwIEAAIAEgN2BicaECBE
ZWZhdWx0IHZhbHVlLgoKEAoJBAADAgQAAgABEgN2BiIKEAoJBAADAgQAAgACEgN2JSYKQQoI
BAADAgQAAgESA3kGDxowIFRoZSBQQlIgaXMgZm9yIElQdjQgaW50ZXJuZXQgcHJvdG9jb2wg
dHJhZmZpYy4KChAKCQQAAwIEAAIBARIDeQYKChAKCQQAAwIEAAIBAhIDeQ0OCpEBCgYEAAMC
AgASA34ERBqBASBPcHRpb25hbC4gVGhlIElQIHByb3RvY29sIHRoYXQgdGhpcyBwb2xpY3kt
YmFzZWQgcm91dGUgYXBwbGllcyB0by4gVmFsaWQKIHZhbHVlcyBhcmUgJ1RDUCcsICdVRFAn
LCBhbmQgJ0FMTCcuIERlZmF1bHQgaXMgJ0FMTCcuCgoOCgcEAAMCAgAFEgN+BAoKDgoHBAAD
AgIAARIDfgsWCg4KBwQAAwICAAMSA34ZGgoOCgcEAAMCAgAIEgN+G0MKEQoKBAADAgIACJwI
ABIDfhxCCqIBCgYEAAMCAgESBIIBBEIakQEgT3B0aW9uYWwuIFRoZSBzb3VyY2UgSVAgcmFu
Z2Ugb2Ygb3V0Z29pbmcgcGFja2V0cyB0aGF0IHRoaXMgcG9saWN5LWJhc2VkCiByb3V0ZSBh
cHBsaWVzIHRvLiBEZWZhdWx0IGlzICIwLjAuMC4wLzAiIGlmIHByb3RvY29sIHZlcnNpb24g
aXMgSVB2NC4KCg8KBwQAAwICAQUSBIIBBAoKDwoHBAADAgIBARIEggELFAoPCgcEAAMCAgED
EgSCARcYCg8KBwQAAwICAQgSBIIBGUEKEgoKBAADAgIBCJwIABIEggEaQAqoAQoGBAADAgIC
EgSHAQRDGpcBIE9wdGlvbmFsLiBUaGUgZGVzdGluYXRpb24gSVAgcmFuZ2Ugb2Ygb3V0Z29p
bmcgcGFja2V0cyB0aGF0IHRoaXMKIHBvbGljeS1iYXNlZCByb3V0ZSBhcHBsaWVzIHRvLiBE
ZWZhdWx0IGlzICIwLjAuMC4wLzAiIGlmIHByb3RvY29sIHZlcnNpb24KIGlzIElQdjQuCgoP
CgcEAAMCAgIFEgSHAQQKCg8KBwQAAwICAgESBIcBCxUKDwoHBAADAgICAxIEhwEYGQoPCgcE
AAMCAgIIEgSHARpCChIKCgQAAwICAgicCAASBIcBG0EKpgEKBgQAAwICAxIGiwEEjAExGpMB
IFJlcXVpcmVkLiBJbnRlcm5ldCBwcm90b2NvbCB2ZXJzaW9ucyB0aGlzIHBvbGljeS1iYXNl
ZCByb3V0ZSBhcHBsaWVzIHRvLgogRm9yIHRoaXMgdmVyc2lvbiwgb25seSBJUFY0IGlzIHN1
cHBvcnRlZC4gSVBWNiBpcyBzdXBwb3J0ZWQgaW4gcHJldmlldy4KCg8KBwQAAwICAwYSBIsB
BBMKDwoHBAADAgIDARIEiwEUJAoPCgcEAAMCAgMDEgSLAScoCg8KBwQAAwICAwgSBIwBCDAK
EgoKBAADAgIDCJwIABIEjAEJLwowCgQEAAMDEgaQAQKuAQMaICBJbmZvcm1hdGlvbmFsIHdh
cm5pbmcgbWVzc2FnZS4KCg0KBQQAAwMBEgSQAQoSCl8KBgQAAwMEABIGkwEEnwEFGk0gV2Fy
bmluZyBjb2RlIGZvciBwb2xpY3ktYmFzZWQgcm91dGluZy4gRXhwZWN0IHRvIGFkZCB2YWx1
ZXMgaW4gdGhlCiBmdXR1cmUuCgoPCgcEAAMDBAABEgSTAQkNCiIKCAQAAwMEAAIAEgSVAQYe
GhAgRGVmYXVsdCB2YWx1ZS4KChEKCQQAAwMEAAIAARIElQEGGQoRCgkEAAMDBAACAAISBJUB
HB0KrQEKCAQAAwMEAAIBEgSaAQYeGpoBIFRoZSBwb2xpY3ktYmFzZWQgcm91dGUgaXMgbm90
IGFjdGl2ZSBhbmQgZnVuY3Rpb25pbmcuIENvbW1vbiBjYXVzZXMgYXJlCiB0aGF0IHRoZSBk
ZXBlbmRlbnQgbmV0d29yayB3YXMgZGVsZXRlZCBvciB0aGUgcmVzb3VyY2UgcHJvamVjdCB3
YXMKIHR1cm5lZCBvZmYuCgoRCgkEAAMDBAACAQESBJoBBhkKEQoJBAADAwQAAgECEgSaARwd
CmIKCAQAAwMEAAICEgSeAQYiGlAgVGhlIHBvbGljeS1iYXNlZCByb3V0ZSBpcyBiZWluZyBt
b2RpZmllZCAoZS5nLiBjcmVhdGVkL2RlbGV0ZWQpIGF0IHRoaXMKIHRpbWUuCgoRCgkEAAMD
BAACAgESBJ4BBh0KEQoJBAADAwQAAgICEgSeASAhCj0KBgQAAwMCABIEogEEPhotIE91dHB1
dCBvbmx5LiBBIHdhcm5pbmcgY29kZSwgaWYgYXBwbGljYWJsZS4KCg8KBwQAAwMCAAYSBKIB
BAgKDwoHBAADAwIAARIEogEJDQoPCgcEAAMDAgADEgSiARARCg8KBwQAAwMCAAgSBKIBEj0K
EgoKBAADAwIACJwIABIEogETPAqVAwoGBAADAwIBEgSqAQRNGoQDIE91dHB1dCBvbmx5LiBN
ZXRhZGF0YSBhYm91dCB0aGlzIHdhcm5pbmcgaW4ga2V5OiB2YWx1ZSBmb3JtYXQuIFRoZSBr
ZXkKIHNob3VsZCBwcm92aWRlcyBtb3JlIGRldGFpbCBvbiB0aGUgd2FybmluZyBiZWluZyBy
ZXR1cm5lZC4gRm9yIGV4YW1wbGUsCiBmb3Igd2FybmluZ3Mgd2hlcmUgdGhlcmUgYXJlIG5v
IHJlc3VsdHMgaW4gYSBsaXN0IHJlcXVlc3QgZm9yIGEKIHBhcnRpY3VsYXIgem9uZSwgdGhp
cyBrZXkgbWlnaHQgYmUgc2NvcGUgYW5kIHRoZSBrZXkgdmFsdWUgbWlnaHQgYmUgdGhlCiB6
b25lIG5hbWUuIE90aGVyIGV4YW1wbGVzIG1pZ2h0IGJlIGEga2V5IGluZGljYXRpbmcgYSBk
ZXByZWNhdGVkIHJlc291cmNlCiBhbmQgYSBzdWdnZXN0ZWQgcmVwbGFjZW1lbnQuCgoPCgcE
AAMDAgEGEgSqAQQXCg8KBwQAAwMCAQESBKoBGBwKDwoHBAADAwIBAxIEqgEfIAoPCgcEAAMD
AgEIEgSqASFMChIKCgQAAwMCAQicCAASBKoBIksKUAoGBAADAwICEgStAQRLGkAgT3V0cHV0
IG9ubHkuIEEgaHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24gb2YgdGhlIHdhcm5pbmcgY29k
ZS4KCg8KBwQAAwMCAgUSBK0BBAoKDwoHBAADAwICARIErQELGgoPCgcEAAMDAgIDEgStAR0e
Cg8KBwQAAwMCAggSBK0BH0oKEgoKBAADAwICCJwIABIErQEgSQoqCgQEAAQAEgaxAQK6AQMa
GiBUaGUgb3RoZXIgcm91dGluZyBjYXNlcy4KCg0KBQQABAABEgSxAQcSCiAKBgQABAACABIE
swEEIRoQIERlZmF1bHQgdmFsdWUuCgoPCgcEAAQAAgABEgSzAQQcCg8KBwQABAACAAISBLMB
HyAK9QEKBgQABAACARIEuQEEGBrkASBVc2UgdGhlIHJvdXRlcyBmcm9tIHRoZSBkZWZhdWx0
IHJvdXRpbmcgdGFibGVzIChzeXN0ZW0tZ2VuZXJhdGVkIHJvdXRlcywKIGN1c3RvbSByb3V0
ZXMsIHBlZXJpbmcgcm91dGUpIHRvIGRldGVybWluZSB0aGUgbmV4dCBob3AuIFRoaXMgZWZm
ZWN0aXZlbHkKIGV4Y2x1ZGVzIG1hdGNoaW5nIHBhY2tldHMgYmVpbmcgYXBwbGllZCBvbiBv
dGhlciBQQlJzIHdpdGggYSBsb3dlcgogcHJpb3JpdHkuCgoPCgcEAAQAAgEBEgS5AQQTCg8K
BwQABAACAQISBLkBFhcK3gEKBAQACAASBr8BAsgBAxrNASBUYXJnZXQgc3BlY2lmaWVzIG5l
dHdvcmsgZW5kcG9pbnRzIHRoYXQgdGhpcyBwb2xpY3ktYmFzZWQgcm91dGUgYXBwbGllcyB0
by4KIElmIG5vIHRhcmdldCBpcyBzcGVjaWZpZWQsIHRoZSBQQlIgd2lsbCBiZSBpbnN0YWxs
ZWQgb24gYWxsIG5ldHdvcmsKIGVuZHBvaW50cyAoZS5nLiBWTXMsIFZQTnMsIGFuZCBJbnRl
cmNvbm5lY3RzKSBpbiB0aGUgVlBDLgoKDQoFBAAIAAESBL8BCA4KUQoEBAACABIGwQEEwgEx
GkEgT3B0aW9uYWwuIFZNIGluc3RhbmNlcyB0aGF0IHRoaXMgcG9saWN5LWJhc2VkIHJvdXRl
IGFwcGxpZXMgdG8uCgoNCgUEAAIABhIEwQEEEgoNCgUEAAIAARIEwQETIgoNCgUEAAIAAxIE
wQElJwoNCgUEAAIACBIEwgEIMAoQCggEAAIACJwIABIEwgEJLwpiCgQEAAIBEgbGAQTHATEa
UiBPcHRpb25hbC4gVGhlIGludGVyY29ubmVjdCBhdHRhY2htZW50cyB0aGF0IHRoaXMgcG9s
aWN5LWJhc2VkIHJvdXRlCiBhcHBsaWVzIHRvLgoKDQoFBAACAQYSBMYBBBoKDQoFBAACAQES
BMYBGzIKDQoFBAACAQMSBMYBNTYKDQoFBAACAQgSBMcBCDAKEAoIBAACAQicCAASBMcBCS8K
DgoEBAAIARIGygEC1AEDCg0KBQQACAEBEgTKAQgQCqoBCgQEAAICEgTOAQRJGpsBIE9wdGlv
bmFsLiBUaGUgSVAgYWRkcmVzcyBvZiBhIGdsb2JhbC1hY2Nlc3MtZW5hYmxlZCBMNCBJTEIg
dGhhdCBpcyB0aGUKIG5leHQgaG9wIGZvciBtYXRjaGluZyBwYWNrZXRzLiBGb3IgdGhpcyB2
ZXJzaW9uLCBvbmx5IG5leHRIb3BJbGJJcCBpcwogc3VwcG9ydGVkLgoKDQoFBAACAgUSBM4B
BAoKDQoFBAACAgESBM4BCxoKDQoFBAACAgMSBM4BHR8KDQoFBAACAggSBM4BIEgKEAoIBAAC
AgicCAASBM4BIUcKagoEBAACAxIG0gEE0wExGlogT3B0aW9uYWwuIE90aGVyIHJvdXRlcyB0
aGF0IHdpbGwgYmUgcmVmZXJlbmNlZCB0byBkZXRlcm1pbmUgdGhlIG5leHQgaG9wCiBvZiB0
aGUgcGFja2V0LgoKDQoFBAACAwYSBNIBBA8KDQoFBAACAwESBNIBECUKDQoFBAACAwMSBNIB
KCoKDQoFBAACAwgSBNMBCDAKEAoIBAACAwicCAASBNMBCS8KoAEKBAQAAgQSBNgBAjwakQEg
SW1tdXRhYmxlLiBBIHVuaXF1ZSBuYW1lIG9mIHRoZSByZXNvdXJjZSBpbiB0aGUgZm9ybSBv
ZgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL2dsb2JhbC9Qb2xpY3lC
YXNlZFJvdXRlcy97cG9saWN5X2Jhc2VkX3JvdXRlX2lkfWAKCg0KBQQAAgQFEgTYAQIICg0K
BQQAAgQBEgTYAQkNCg0KBQQAAgQDEgTYARARCg0KBQQAAgQIEgTYARI7ChAKCAQAAgQInAgA
EgTYARM6CkwKBAQAAgUSBtsBAtwBMho8IE91dHB1dCBvbmx5LiBUaW1lIHdoZW4gdGhlIHBv
bGljeS1iYXNlZCByb3V0ZSB3YXMgY3JlYXRlZC4KCg0KBQQAAgUGEgTbAQIbCg0KBQQAAgUB
EgTbARwnCg0KBQQAAgUDEgTbASorCg0KBQQAAgUIEgTcAQYxChAKCAQAAgUInAgAEgTcAQcw
CkwKBAQAAgYSBt8BAuABMho8IE91dHB1dCBvbmx5LiBUaW1lIHdoZW4gdGhlIHBvbGljeS1i
YXNlZCByb3V0ZSB3YXMgdXBkYXRlZC4KCg0KBQQAAgYGEgTfAQIbCg0KBQQAAgYBEgTfARwn
Cg0KBQQAAgYDEgTfASorCg0KBQQAAgYIEgTgAQYxChAKCAQAAgYInAgAEgTgAQcwCiQKBAQA
AgcSBOMBAiEaFiBVc2VyLWRlZmluZWQgbGFiZWxzLgoKDQoFBAACBwYSBOMBAhUKDQoFBAAC
BwESBOMBFhwKDQoFBAACBwMSBOMBHyAKdQoEBAACCBIE5wECQhpnIE9wdGlvbmFsLiBBbiBv
cHRpb25hbCBkZXNjcmlwdGlvbiBvZiB0aGlzIHJlc291cmNlLiBQcm92aWRlIHRoaXMgZmll
bGQgd2hlbgogeW91IGNyZWF0ZSB0aGUgcmVzb3VyY2UuCgoNCgUEAAIIBRIE5wECCAoNCgUE
AAIIARIE5wEJFAoNCgUEAAIIAxIE5wEXGAoNCgUEAAIICBIE5wEZQQoQCggEAAIICJwIABIE
5wEaQAqZAQoEBAACCRIG6wEC7gEEGogBIFJlcXVpcmVkLiBGdWxseS1xdWFsaWZpZWQgVVJM
IG9mIHRoZSBuZXR3b3JrIHRoYXQgdGhpcyByb3V0ZSBhcHBsaWVzIHRvLAogZm9yIGV4YW1w
bGU6IHByb2plY3RzL215LXByb2plY3QvZ2xvYmFsL25ldHdvcmtzL215LW5ldHdvcmsuCgoN
CgUEAAIJBRIE6wECCAoNCgUEAAIJARIE6wEJEAoNCgUEAAIJAxIE6wETFAoPCgUEAAIJCBIG
6wEV7gEDChAKCAQAAgkInAgAEgTsAQQqCg8KBwQAAgkInwgSBO0BBFAKOQoEBAACChIE8QEC
PhorIFJlcXVpcmVkLiBUaGUgZmlsdGVyIHRvIG1hdGNoIEw0IHRyYWZmaWMuCgoNCgUEAAIK
BhIE8QECCAoNCgUEAAIKARIE8QEJDwoNCgUEAAIKAxIE8QESFAoNCgUEAAIKCBIE8QEVPQoQ
CggEAAIKCJwIABIE8QEWPAryAgoEBAACCxIE+AECPxrjAiBPcHRpb25hbC4gVGhlIHByaW9y
aXR5IG9mIHRoaXMgcG9saWN5LWJhc2VkIHJvdXRlLiBQcmlvcml0eSBpcyB1c2VkIHRvCiBi
cmVhayB0aWVzIGluIGNhc2VzIHdoZXJlIHRoZXJlIGFyZSBtb3JlIHRoYW4gb25lIG1hdGNo
aW5nIHBvbGljeS1iYXNlZAogcm91dGVzIGZvdW5kLiBJbiBjYXNlcyB3aGVyZSBtdWx0aXBs
ZSBwb2xpY3ktYmFzZWQgcm91dGVzIGFyZSBtYXRjaGVkLCB0aGUKIG9uZSB3aXRoIHRoZSBs
b3dlc3QtbnVtYmVyZWQgcHJpb3JpdHkgdmFsdWUgd2lucy4gVGhlIGRlZmF1bHQgdmFsdWUg
aXMKIDEwMDAuIFRoZSBwcmlvcml0eSB2YWx1ZSBtdXN0IGJlIGZyb20gMSB0byA2NTUzNSwg
aW5jbHVzaXZlLgoKDQoFBAACCwUSBPgBAgcKDQoFBAACCwESBPgBCBAKDQoFBAACCwMSBPgB
ExUKDQoFBAACCwgSBPgBFj4KEAoIBAACCwicCAASBPgBFz0KjQEKBAQAAgwSBPwBAk4afyBP
dXRwdXQgb25seS4gSWYgcG90ZW50aWFsIG1pc2NvbmZpZ3VyYXRpb25zIGFyZSBkZXRlY3Rl
ZCBmb3IgdGhpcyByb3V0ZSwKIHRoaXMgZmllbGQgd2lsbCBiZSBwb3B1bGF0ZWQgd2l0aCB3
YXJuaW5nIG1lc3NhZ2VzLgoKDQoFBAACDAQSBPwBAgoKDQoFBAACDAYSBPwBCxMKDQoFBAAC
DAESBPwBFBwKDQoFBAACDAMSBPwBHyEKDQoFBAACDAgSBPwBIk0KEAoIBAACDAicCAASBPwB
I0wKUgoEBAACDRIE/wECRBpEIE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCBmdWxseS1x
dWFsaWZpZWQgVVJMIGZvciB0aGlzIHJlc291cmNlLgoKDQoFBAACDQUSBP8BAggKDQoFBAAC
DQESBP8BCRIKDQoFBAACDQMSBP8BFRcKDQoFBAACDQgSBP8BGEMKEAoIBAACDQicCAASBP8B
GUIKggEKBAQAAg4SBIMCAj8adCBPdXRwdXQgb25seS4gVHlwZSBvZiB0aGlzIHJlc291cmNl
LiBBbHdheXMKIG5ldHdvcmtjb25uZWN0aXZpdHkjcG9saWN5QmFzZWRSb3V0ZSBmb3IgcG9s
aWN5LWJhc2VkIFJvdXRlIHJlc291cmNlcy4KCg0KBQQAAg4FEgSDAgIICg0KBQQAAg4BEgSD
AgkNCg0KBQQAAg4DEgSDAhASCg0KBQQAAg4IEgSDAhM+ChAKCAQAAg4InAgAEgSDAhQ9Cq0B
CgIEARIGiQIAnQIBGp4BIFJlcXVlc3QgZm9yCiBbUG9saWN5QmFzZWRSb3V0aW5nU2Vydmlj
ZS5MaXN0UG9saWN5QmFzZWRSb3V0ZXNdW2dvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2
aXR5LnYxLlBvbGljeUJhc2VkUm91dGluZ1NlcnZpY2UuTGlzdFBvbGljeUJhc2VkUm91dGVz
XQogbWV0aG9kLgoKCwoDBAEBEgSJAggkCjcKBAQBAgASBosCApACBBonIFJlcXVpcmVkLiBU
aGUgcGFyZW50IHJlc291cmNlJ3MgbmFtZS4KCg0KBQQBAgAFEgSLAgIICg0KBQQBAgABEgSL
AgkPCg0KBQQBAgADEgSLAhITCg8KBQQBAgAIEgaLAhSQAgMKEAoIBAECAAicCAASBIwCBCoK
EQoHBAECAAifCBIGjQIEjwIFCk8KBAQBAgESBJMCAhYaQSBUaGUgbWF4aW11bSBudW1iZXIg
b2YgcmVzdWx0cyBwZXIgcGFnZSB0aGF0IHNob3VsZCBiZSByZXR1cm5lZC4KCg0KBQQBAgEF
EgSTAgIHCg0KBQQBAgEBEgSTAggRCg0KBQQBAgEDEgSTAhQVCh8KBAQBAgISBJYCAhgaESBU
aGUgcGFnZSB0b2tlbi4KCg0KBQQBAgIFEgSWAgIICg0KBQQBAgIBEgSWAgkTCg0KBQQBAgID
EgSWAhYXClQKBAQBAgMSBJkCAhQaRiBBIGZpbHRlciBleHByZXNzaW9uIHRoYXQgZmlsdGVy
cyB0aGUgcmVzdWx0cyBsaXN0ZWQgaW4gdGhlIHJlc3BvbnNlLgoKDQoFBAECAwUSBJkCAggK
DQoFBAECAwESBJkCCQ8KDQoFBAECAwMSBJkCEhMKNAoEBAECBBIEnAICFhomIFNvcnQgdGhl
IHJlc3VsdHMgYnkgYSBjZXJ0YWluIG9yZGVyLgoKDQoFBAECBAUSBJwCAggKDQoFBAECBAES
BJwCCREKDQoFBAECBAMSBJwCFBUKrgEKAgQCEgaiAgCsAgEanwEgUmVzcG9uc2UgZm9yCiBb
UG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5MaXN0UG9saWN5QmFzZWRSb3V0ZXNdW2dvb2ds
ZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxLlBvbGljeUJhc2VkUm91dGluZ1NlcnZp
Y2UuTGlzdFBvbGljeUJhc2VkUm91dGVzXQogbWV0aG9kLgoKCwoDBAIBEgSiAgglCjMKBAQC
AgASBKQCAjQaJSBQb2xpY3ktYmFzZWQgcm91dGVzIHRvIGJlIHJldHVybmVkLgoKDQoFBAIC
AAQSBKQCAgoKDQoFBAICAAYSBKQCCxsKDQoFBAICAAESBKQCHC8KDQoFBAICAAMSBKQCMjMK
oQEKBAQCAgESBKgCAh0akgEgVGhlIG5leHQgcGFnaW5hdGlvbiB0b2tlbiBpbiB0aGUgTGlz
dCByZXNwb25zZS4gSXQgc2hvdWxkIGJlIHVzZWQgYXMKIHBhZ2VfdG9rZW4gZm9yIHRoZSBm
b2xsb3dpbmcgcmVxdWVzdC4gQW4gZW1wdHkgdmFsdWUgbWVhbnMgbm8gbW9yZSByZXN1bHQu
CgoNCgUEAgIBBRIEqAICCAoNCgUEAgIBARIEqAIJGAoNCgUEAgIBAxIEqAIbHAo0CgQEAgIC
EgSrAgIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAgIC
BBIEqwICCgoNCgUEAgICBRIEqwILEQoNCgUEAgICARIEqwISHQoNCgUEAgICAxIEqwIgIQqp
AQoCBAMSBrECALkCARqaASBSZXF1ZXN0IGZvcgogW1BvbGljeUJhc2VkUm91dGluZ1NlcnZp
Y2UuR2V0UG9saWN5QmFzZWRSb3V0ZV1bZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZp
dHkudjEuUG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5HZXRQb2xpY3lCYXNlZFJvdXRlXQog
bWV0aG9kLgoKCwoDBAMBEgSxAggiCkkKBAQDAgASBrMCArgCBBo5IFJlcXVpcmVkLiBOYW1l
IG9mIHRoZSBQb2xpY3lCYXNlZFJvdXRlIHJlc291cmNlIHRvIGdldC4KCg0KBQQDAgAFEgSz
AgIICg0KBQQDAgABEgSzAgkNCg0KBQQDAgADEgSzAhARCg8KBQQDAgAIEgazAhK4AgMKEAoI
BAMCAAicCAASBLQCBCoKEQoHBAMCAAifCBIGtQIEtwIFCq8BCgIEBBIGvgIA4wIBGqABIFJl
cXVlc3QgZm9yCiBbUG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5DcmVhdGVQb2xpY3lCYXNl
ZFJvdXRlXVtnb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MS5Qb2xpY3lCYXNl
ZFJvdXRpbmdTZXJ2aWNlLkNyZWF0ZVBvbGljeUJhc2VkUm91dGVdCiBtZXRob2QuCgoLCgME
BAESBL4CCCUKTwoEBAQCABIGwAICxQIEGj8gUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3Vy
Y2UncyBuYW1lIG9mIHRoZSBQb2xpY3lCYXNlZFJvdXRlLgoKDQoFBAQCAAUSBMACAggKDQoF
BAQCAAESBMACCQ8KDQoFBAQCAAMSBMACEhMKDwoFBAQCAAgSBsACFMUCAwoQCggEBAIACJwI
ABIEwQIEKgoRCgcEBAIACJ8IEgbCAgTEAgUKkwQKBAQEAgESBM8CAkwahAQgUmVxdWlyZWQu
IFVuaXF1ZSBpZCBmb3IgdGhlIHBvbGljeS1iYXNlZCByb3V0ZSB0byBjcmVhdGUuIFByb3Zp
ZGVkIGJ5IHRoZQogY2xpZW50IHdoZW4gdGhlIHJlc291cmNlIGlzIGNyZWF0ZWQuIFRoZSBu
YW1lIG11c3QgY29tcGx5IHdpdGgKIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTIyI3Jlc291
cmNlLWlkLXNlZ21lbnRzLiBTcGVjaWZpY2FsbHksIHRoZSBuYW1lCiBtdXN0IGJlIDEtNjMg
Y2hhcmFjdGVycyBsb25nIGFuZCBtYXRjaCB0aGUgcmVndWxhciBleHByZXNzaW9uCiBbYS16
XShbYS16MC05LV0qW2EtejAtOV0pPy4gVGhlIGZpcnN0IGNoYXJhY3RlciBtdXN0IGJlIGEg
bG93ZXJjYXNlIGxldHRlciwKIGFuZCBhbGwgZm9sbG93aW5nIGNoYXJhY3RlcnMgKGV4Y2Vw
dCBmb3IgdGhlIGxhc3QgY2hhcmFjdGVyKSBtdXN0IGJlIGEKIGRhc2gsIGxvd2VyY2FzZSBs
ZXR0ZXIsIG9yIGRpZ2l0LiBUaGUgbGFzdCBjaGFyYWN0ZXIgbXVzdCBiZSBhIGxvd2VyY2Fz
ZQogbGV0dGVyIG9yIGRpZ2l0LgoKDQoFBAQCAQUSBM8CAggKDQoFBAQCAQESBM8CCR4KDQoF
BAQCAQMSBM8CISIKDQoFBAQCAQgSBM8CI0sKEAoIBAQCAQicCAASBM8CJEoKSAoEBAQCAhIG
0gIC0wIvGjggUmVxdWlyZWQuIEluaXRpYWwgdmFsdWVzIGZvciBhIG5ldyBwb2xpY3ktYmFz
ZWQgcm91dGUuCgoNCgUEBAICBhIE0gICEgoNCgUEBAICARIE0gITJQoNCgUEBAICAxIE0gIo
KQoNCgUEBAICCBIE0wIGLgoQCggEBAICCJwIABIE0wIHLQqDBgoEBAQCAxIE4gICQRr0BSBP
cHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4g
U3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5
IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciBrbm93cyB0bwogaWdub3JlIHRoZSByZXF1ZXN0
IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIGd1YXJhbnRl
ZXMKIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVl
c3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtl
IGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRoZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91
IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhl
IHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUg
cmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIGlnbm9yZXMgdGhlIHNlY29u
ZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzIGNsaWVudHMKIGZyb20gYWNjaWRlbnRhbGx5IGNy
ZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJl
IGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5v
dCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoN
CgUEBAIDBRIE4gICCAoNCgUEBAIDARIE4gIJEwoNCgUEBAIDAxIE4gIWFwoNCgUEBAIDCBIE
4gIYQAoQCggEBAIDCJwIABIE4gIZPwqvAQoCBAUSBugCAP8CARqgASBSZXF1ZXN0IGZvcgog
W1BvbGljeUJhc2VkUm91dGluZ1NlcnZpY2UuRGVsZXRlUG9saWN5QmFzZWRSb3V0ZV1bZ29v
Z2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjEuUG9saWN5QmFzZWRSb3V0aW5nU2Vy
dmljZS5EZWxldGVQb2xpY3lCYXNlZFJvdXRlXQogbWV0aG9kLgoKCwoDBAUBEgToAgglCk4K
BAQFAgASBuoCAu8CBBo+IFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBwb2xpY3ktYmFzZWQgcm91
dGUgcmVzb3VyY2UgdG8gZGVsZXRlLgoKDQoFBAUCAAUSBOoCAggKDQoFBAUCAAESBOoCCQ0K
DQoFBAUCAAMSBOoCEBEKDwoFBAUCAAgSBuoCEu8CAwoQCggEBQIACJwIABIE6wIEKgoRCgcE
BQIACJ8IEgbsAgTuAgUKgwYKBAQFAgESBP4CAkEa9AUgT3B0aW9uYWwuIEFuIG9wdGlvbmFs
IHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJl
cXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBz
ZXJ2ZXIga25vd3MgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBi
ZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciBndWFyYW50ZWVzCiB0aGF0IGZvciBhdCBsZWFz
dCA2MCBtaW51dGVzIGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBj
b25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3Qg
YW5kCiB0aGUgcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFn
YWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlm
IG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNl
aXZlZCwgYW5kIGlmIHNvLCBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2
ZW50cyBjbGllbnRzCiBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29t
bWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0
aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAw
MC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAUCAQUSBP4CAggKDQoFBAUC
AQESBP4CCRMKDQoFBAUCAQMSBP4CFhcKDQoFBAUCAQgSBP4CGEAKEAoIBAUCAQicCAASBP4C
GT9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute ===
    # Fields for PolicyBasedRoute
    # Field: virtual_machine Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute.VirtualMachine)
    # Field: interconnect_attachment Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute.InterconnectAttachment)
    # Field: next_hop_ilb_ip Type: 9 ()
    # Field: next_hop_other_routes Type: 14 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute.OtherRoutes)
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: network Type: 9 ()
    # Field: filter Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute.Filter)
    # Field: priority Type: 5 ()
    # Field: warnings Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute.Warnings)
    # Field: self_link Type: 9 ()
    # Field: kind Type: 9 ()

# Enum: PolicyBasedRoute::OtherRoutes
our $PolicyBasedRoute_OTHER_ROUTES_UNSPECIFIED = 0;
our $PolicyBasedRoute_DEFAULT_ROUTING = 1;

# === Message: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest ===
    # Fields for ListPolicyBasedRoutesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse ===
    # Fields for ListPolicyBasedRoutesResponse
    # Field: policy_based_routes Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::GetPolicyBasedRouteRequest ===
    # Fields for GetPolicyBasedRouteRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::CreatePolicyBasedRouteRequest ===
    # Fields for CreatePolicyBasedRouteRequest
    # Field: parent Type: 9 ()
    # Field: policy_based_route_id Type: 9 ()
    # Field: policy_based_route Type: 11 (.google.cloud.networkconnectivity.v1.PolicyBasedRoute)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest ===
    # Fields for DeletePolicyBasedRouteRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Service Client: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoutingServiceClient ===
package Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoutingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoutingServiceClient

Client stub representing the remote C<PolicyBasedRoutingService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networkconnectivity.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networkconnectivity.googleapis.com:443' );

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

sub list_policy_based_routes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService',
        method         => 'ListPolicyBasedRoutes',
        request        => $req,
        response_class => 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse',
    });
}

sub get_policy_based_route {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::GetPolicyBasedRouteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService',
        method         => 'GetPolicyBasedRoute',
        request        => $req,
        response_class => 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute',
    });
}

sub create_policy_based_route {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::CreatePolicyBasedRouteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService',
        method         => 'CreatePolicyBasedRoute',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_policy_based_route {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService',
        method         => 'DeletePolicyBasedRoute',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting - Compiled Protocol Buffers messages for google/cloud/networkconnectivity/v1/policy_based_routing.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting;

    my $msg = Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute->new({
        virtual_machine => $virtual_machine,
        interconnect_attachment => $interconnect_attachment,
        next_hop_ilb_ip => $next_hop_ilb_ip,
        next_hop_other_routes => $next_hop_other_routes,
    });

    # Read or update a field
    my $val = $msg->virtual_machine();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkconnectivity/v1/policy_based_routing.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute

Policy-based routes route L4 network traffic based on not just destination IP
address, but also source IP address, protocol, and more. If a policy-based
route conflicts with other types of routes, the policy-based route always
takes precedence.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->virtual_machine() >> / C<< $msg->virtual_machine($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::VirtualMachine>)

Optional. VM instances that this policy-based route applies to.

=item * C<< $msg->interconnect_attachment() >> / C<< $msg->interconnect_attachment($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::InterconnectAttachment>)

Optional. The interconnect attachments that this policy-based route
applies to.

=item * C<< $msg->next_hop_ilb_ip() >> / C<< $msg->next_hop_ilb_ip($value) >>

Type: C<String>

Optional. The IP address of a global-access-enabled L4 ILB that is the
next hop for matching packets. For this version, only nextHopIlbIp is
supported.

=item * C<< $msg->next_hop_other_routes() >> / C<< $msg->next_hop_other_routes($value) >>

Type: C<Enum> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRoute::OtherRoutes>)

Optional. Other routes that will be referenced to determine the next hop
of the packet.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. A unique name of the resource in the form of
`projects/{project_number}/locations/global/PolicyBasedRoutes/{policy_based_route_id}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the policy-based route was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the policy-based route was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::LabelsEntry>)

User-defined labels.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. An optional description of this resource. Provide this field when
you create the resource.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Required. Fully-qualified URL of the network that this route applies to,
for example: projects/my-project/global/networks/my-network.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Filter>)

Required. The filter to match L4 traffic.

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Int32>

Optional. The priority of this policy-based route. Priority is used to
break ties in cases where there are more than one matching policy-based
routes found. In cases where multiple policy-based routes are matched, the
one with the lowest-numbered priority value wins. The default value is
1000. The priority value must be from 1 to 65535, inclusive.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings>)

Output only. If potential misconfigurations are detected for this route,
this field will be populated with warning messages.

=item * C<< $msg->self_link() >> / C<< $msg->self_link($value) >>

Type: C<String>

Output only. Server-defined fully-qualified URL for this resource.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

Output only. Type of this resource. Always
networkconnectivity#policyBasedRoute for policy-based Route resources.

=back

=head3 Enum: PolicyBasedRoute::OtherRoutes

=over 4

=item * C<OTHER_ROUTES_UNSPECIFIED> => C<0>

=item * C<DEFAULT_ROUTING> => C<1>

=back

=head2 Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest

Request for
[PolicyBasedRoutingService.ListPolicyBasedRoutes][google.cloud.networkconnectivity.v1.PolicyBasedRoutingService.ListPolicyBasedRoutes]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource's name.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results per page that should be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter expression that filters the results listed in the response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Sort the results by a certain order.

=back

=head2 Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse

Response for
[PolicyBasedRoutingService.ListPolicyBasedRoutes][google.cloud.networkconnectivity.v1.PolicyBasedRoutingService.ListPolicyBasedRoutes]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_based_routes() >> / C<< $msg->policy_based_routes($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute>)

Policy-based routes to be returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The next pagination token in the List response. It should be used as
page_token for the following request. An empty value means no more result.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::GetPolicyBasedRouteRequest

Request for
[PolicyBasedRoutingService.GetPolicyBasedRoute][google.cloud.networkconnectivity.v1.PolicyBasedRoutingService.GetPolicyBasedRoute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the PolicyBasedRoute resource to get.

=back

=head2 Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::CreatePolicyBasedRouteRequest

Request for
[PolicyBasedRoutingService.CreatePolicyBasedRoute][google.cloud.networkconnectivity.v1.PolicyBasedRoutingService.CreatePolicyBasedRoute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource's name of the PolicyBasedRoute.

=item * C<< $msg->policy_based_route_id() >> / C<< $msg->policy_based_route_id($value) >>

Type: C<String>

Required. Unique id for the policy-based route to create. Provided by the
client when the resource is created. The name must comply with
https://google.aip.dev/122#resource-id-segments. Specifically, the name
must be 1-63 characters long and match the regular expression
[a-z]([a-z0-9-]*[a-z0-9])?. The first character must be a lowercase letter,
and all following characters (except for the last character) must be a
dash, lowercase letter, or digit. The last character must be a lowercase
letter or digit.

=item * C<< $msg->policy_based_route() >> / C<< $msg->policy_based_route($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute>)

Required. Initial values for a new policy-based route.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server knows to
ignore the request if it has already been completed. The server guarantees
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, ignores the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest

Request for
[PolicyBasedRoutingService.DeletePolicyBasedRoute][google.cloud.networkconnectivity.v1.PolicyBasedRoutingService.DeletePolicyBasedRoute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the policy-based route resource to delete.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server knows to
ignore the request if it has already been completed. The server guarantees
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, ignores the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
