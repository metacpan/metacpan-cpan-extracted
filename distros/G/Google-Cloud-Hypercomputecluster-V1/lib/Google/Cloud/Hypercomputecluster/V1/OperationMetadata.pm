package Google::Cloud::Hypercomputecluster::V1::OperationMetadata;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvaHlwZXJjb21wdXRlY2x1c3Rlci92MS9vcGVyYXRpb25fbWV0YWRh
dGEucHJvdG8SI2dvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoIDChFPcGVyYXRpb25NZXRhZGF0YRJA
CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IHZW5kVGltZRIbCgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZlcmIY
BCABKAlCA+BBA1IEdmVyYhI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAUgASgIQgPgQQNS
FXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgGIAEoCUID4EEDUgphcGlW
ZXJzaW9uElcKCHByb2dyZXNzGAcgASgLMjYuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNs
dXN0ZXIudjEuT3BlcmF0aW9uUHJvZ3Jlc3NCA+BBA1IIcHJvZ3Jlc3MiYgoRT3BlcmF0aW9u
UHJvZ3Jlc3MSTQoFc3RlcHMYASADKAsyMi5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1
c3Rlci52MS5PcGVyYXRpb25TdGVwQgPgQQNSBXN0ZXBzIsoVCg1PcGVyYXRpb25TdGVwEmAK
DmNyZWF0ZV9uZXR3b3JrGAIgASgLMjIuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0
ZXIudjEuQ3JlYXRlTmV0d29ya0ID4EEDSABSDWNyZWF0ZU5ldHdvcmsSiQEKHWNyZWF0ZV9w
cml2YXRlX3NlcnZpY2VfYWNjZXNzGAMgASgLMj8uZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0
ZWNsdXN0ZXIudjEuQ3JlYXRlUHJpdmF0ZVNlcnZpY2VBY2Nlc3NCA+BBA0gAUhpjcmVhdGVQ
cml2YXRlU2VydmljZUFjY2VzcxJ/ChljcmVhdGVfZmlsZXN0b3JlX2luc3RhbmNlGAQgASgL
MjwuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjEuQ3JlYXRlRmlsZXN0b3Jl
SW5zdGFuY2VCA+BBA0gAUhdjcmVhdGVGaWxlc3RvcmVJbnN0YW5jZRJzChVjcmVhdGVfc3Rv
cmFnZV9idWNrZXQYBSABKAsyOC5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52
MS5DcmVhdGVTdG9yYWdlQnVja2V0QgPgQQNIAFITY3JlYXRlU3RvcmFnZUJ1Y2tldBJ2ChZj
cmVhdGVfbHVzdHJlX2luc3RhbmNlGAYgASgLMjkuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0
ZWNsdXN0ZXIudjEuQ3JlYXRlTHVzdHJlSW5zdGFuY2VCA+BBA0gAUhRjcmVhdGVMdXN0cmVJ
bnN0YW5jZRJvChNjcmVhdGVfb3JjaGVzdHJhdG9yGAggASgLMjcuZ29vZ2xlLmNsb3VkLmh5
cGVyY29tcHV0ZWNsdXN0ZXIudjEuQ3JlYXRlT3JjaGVzdHJhdG9yQgPgQQNIAFISY3JlYXRl
T3JjaGVzdHJhdG9yEmAKDmNyZWF0ZV9ub2Rlc2V0GAkgASgLMjIuZ29vZ2xlLmNsb3VkLmh5
cGVyY29tcHV0ZWNsdXN0ZXIudjEuQ3JlYXRlTm9kZXNldEID4EEDSABSDWNyZWF0ZU5vZGVz
ZXQSZgoQY3JlYXRlX3BhcnRpdGlvbhgKIAEoCzI0Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1
dGVjbHVzdGVyLnYxLkNyZWF0ZVBhcnRpdGlvbkID4EEDSABSD2NyZWF0ZVBhcnRpdGlvbhJn
ChFjcmVhdGVfbG9naW5fbm9kZRgLIAEoCzI0Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVj
bHVzdGVyLnYxLkNyZWF0ZUxvZ2luTm9kZUID4EEDSABSD2NyZWF0ZUxvZ2luTm9kZRJwChRj
aGVja19jbHVzdGVyX2hlYWx0aBgMIAEoCzI3Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVj
bHVzdGVyLnYxLkNoZWNrQ2x1c3RlckhlYWx0aEID4EEDSABSEmNoZWNrQ2x1c3RlckhlYWx0
aBJvChN1cGRhdGVfb3JjaGVzdHJhdG9yGA0gASgLMjcuZ29vZ2xlLmNsb3VkLmh5cGVyY29t
cHV0ZWNsdXN0ZXIudjEuVXBkYXRlT3JjaGVzdHJhdG9yQgPgQQNIAFISdXBkYXRlT3JjaGVz
dHJhdG9yEmAKDnVwZGF0ZV9ub2Rlc2V0GA4gASgLMjIuZ29vZ2xlLmNsb3VkLmh5cGVyY29t
cHV0ZWNsdXN0ZXIudjEuVXBkYXRlTm9kZXNldEID4EEDSABSDXVwZGF0ZU5vZGVzZXQSZgoQ
dXBkYXRlX3BhcnRpdGlvbhgPIAEoCzI0Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVz
dGVyLnYxLlVwZGF0ZVBhcnRpdGlvbkID4EEDSABSD3VwZGF0ZVBhcnRpdGlvbhJnChF1cGRh
dGVfbG9naW5fbm9kZRgQIAEoCzI0Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVy
LnYxLlVwZGF0ZUxvZ2luTm9kZUID4EEDSABSD3VwZGF0ZUxvZ2luTm9kZRJvChNkZWxldGVf
b3JjaGVzdHJhdG9yGBIgASgLMjcuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIu
djEuRGVsZXRlT3JjaGVzdHJhdG9yQgPgQQNIAFISZGVsZXRlT3JjaGVzdHJhdG9yEmAKDmRl
bGV0ZV9ub2Rlc2V0GBMgASgLMjIuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIu
djEuRGVsZXRlTm9kZXNldEID4EEDSABSDWRlbGV0ZU5vZGVzZXQSZgoQZGVsZXRlX3BhcnRp
dGlvbhgUIAEoCzI0Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxLkRlbGV0
ZVBhcnRpdGlvbkID4EEDSABSD2RlbGV0ZVBhcnRpdGlvbhJnChFkZWxldGVfbG9naW5fbm9k
ZRgVIAEoCzI0Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxLkRlbGV0ZUxv
Z2luTm9kZUID4EEDSABSD2RlbGV0ZUxvZ2luTm9kZRJ/ChlkZWxldGVfZmlsZXN0b3JlX2lu
c3RhbmNlGBYgASgLMjwuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjEuRGVs
ZXRlRmlsZXN0b3JlSW5zdGFuY2VCA+BBA0gAUhdkZWxldGVGaWxlc3RvcmVJbnN0YW5jZRJz
ChVkZWxldGVfc3RvcmFnZV9idWNrZXQYFyABKAsyOC5nb29nbGUuY2xvdWQuaHlwZXJjb21w
dXRlY2x1c3Rlci52MS5EZWxldGVTdG9yYWdlQnVja2V0QgPgQQNIAFITZGVsZXRlU3RvcmFn
ZUJ1Y2tldBJ2ChZkZWxldGVfbHVzdHJlX2luc3RhbmNlGBggASgLMjkuZ29vZ2xlLmNsb3Vk
Lmh5cGVyY29tcHV0ZWNsdXN0ZXIudjEuRGVsZXRlTHVzdHJlSW5zdGFuY2VCA+BBA0gAUhRk
ZWxldGVMdXN0cmVJbnN0YW5jZRKJAQodZGVsZXRlX3ByaXZhdGVfc2VydmljZV9hY2Nlc3MY
GSABKAsyPy5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MS5EZWxldGVQcml2
YXRlU2VydmljZUFjY2Vzc0ID4EEDSABSGmRlbGV0ZVByaXZhdGVTZXJ2aWNlQWNjZXNzEmAK
DmRlbGV0ZV9uZXR3b3JrGBogASgLMjIuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0
ZXIudjEuRGVsZXRlTmV0d29ya0ID4EEDSABSDWRlbGV0ZU5ldHdvcmsSUwoFc3RhdGUYASAB
KA4yOC5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MS5PcGVyYXRpb25TdGVw
LlN0YXRlQgPgQQNSBXN0YXRlIkYKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoH
V0FJVElORxABEg8KC0lOX1BST0dSRVNTEAISCAoERE9ORRADQgYKBHR5cGUiUQoNQ3JlYXRl
TmV0d29yaxJACgduZXR3b3JrGAEgASgJQibgQQP6QSAKHmNvbXB1dGUuZ29vZ2xlYXBpcy5j
b20vTmV0d29ya1IHbmV0d29yayIcChpDcmVhdGVQcml2YXRlU2VydmljZUFjY2VzcyJhChdD
cmVhdGVGaWxlc3RvcmVJbnN0YW5jZRJGCglmaWxlc3RvcmUYASABKAlCKOBBA/pBIgogZmls
ZS5nb29nbGVhcGlzLmNvbS9GaWxlSW5zdGFuY2VSCWZpbGVzdG9yZSJUChNDcmVhdGVTdG9y
YWdlQnVja2V0Ej0KBmJ1Y2tldBgBIAEoCUIl4EED+kEfCh1zdG9yYWdlLmdvb2dsZWFwaXMu
Y29tL0J1Y2tldFIGYnVja2V0IlYKFENyZWF0ZUx1c3RyZUluc3RhbmNlEj4KBmx1c3RyZRgB
IAEoCUIm4EED+kEgCh5sdXN0cmUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBmx1c3RyZSIU
ChJDcmVhdGVPcmNoZXN0cmF0b3IiMAoNQ3JlYXRlTm9kZXNldBIfCghub2Rlc2V0cxgBIAMo
CUID4EEDUghub2Rlc2V0cyI2Cg9DcmVhdGVQYXJ0aXRpb24SIwoKcGFydGl0aW9ucxgBIAMo
CUID4EEDUgpwYXJ0aXRpb25zIhEKD0NyZWF0ZUxvZ2luTm9kZSIUChJDaGVja0NsdXN0ZXJI
ZWFsdGgiFAoSVXBkYXRlT3JjaGVzdHJhdG9yIjAKDVVwZGF0ZU5vZGVzZXQSHwoIbm9kZXNl
dHMYASADKAlCA+BBA1IIbm9kZXNldHMiNgoPVXBkYXRlUGFydGl0aW9uEiMKCnBhcnRpdGlv
bnMYASADKAlCA+BBA1IKcGFydGl0aW9ucyIRCg9VcGRhdGVMb2dpbk5vZGUiFAoSRGVsZXRl
T3JjaGVzdHJhdG9yIjAKDURlbGV0ZU5vZGVzZXQSHwoIbm9kZXNldHMYASADKAlCA+BBA1II
bm9kZXNldHMiNgoPRGVsZXRlUGFydGl0aW9uEiMKCnBhcnRpdGlvbnMYASADKAlCA+BBA1IK
cGFydGl0aW9ucyIRCg9EZWxldGVMb2dpbk5vZGUiYQoXRGVsZXRlRmlsZXN0b3JlSW5zdGFu
Y2USRgoJZmlsZXN0b3JlGAEgASgJQijgQQP6QSIKIGZpbGUuZ29vZ2xlYXBpcy5jb20vRmls
ZUluc3RhbmNlUglmaWxlc3RvcmUiVAoTRGVsZXRlU3RvcmFnZUJ1Y2tldBI9CgZidWNrZXQY
ASABKAlCJeBBA/pBHwodc3RvcmFnZS5nb29nbGVhcGlzLmNvbS9CdWNrZXRSBmJ1Y2tldCJW
ChREZWxldGVMdXN0cmVJbnN0YW5jZRI+CgZsdXN0cmUYASABKAlCJuBBA/pBIAoebHVzdHJl
Lmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgZsdXN0cmUiHAoaRGVsZXRlUHJpdmF0ZVNlcnZp
Y2VBY2Nlc3MiUQoNRGVsZXRlTmV0d29yaxJACgduZXR3b3JrGAEgASgJQibgQQP6QSAKHmNv
bXB1dGUuZ29vZ2xlYXBpcy5jb20vTmV0d29ya1IHbmV0d29ya0L0AgonY29tLmdvb2dsZS5j
bG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxQhZPcGVyYXRpb25NZXRhZGF0YVByb3RvUAFa
WWNsb3VkLmdvb2dsZS5jb20vZ28vaHlwZXJjb21wdXRlY2x1c3Rlci9hcGl2MS9oeXBlcmNv
bXB1dGVjbHVzdGVycGI7aHlwZXJjb21wdXRlY2x1c3RlcnBiqgIjR29vZ2xlLkNsb3VkLkh5
cGVyY29tcHV0ZUNsdXN0ZXIuVjHKAiNHb29nbGVcQ2xvdWRcSHlwZXJjb21wdXRlQ2x1c3Rl
clxWMeoCJkdvb2dsZTo6Q2xvdWQ6Okh5cGVyY29tcHV0ZUNsdXN0ZXI6OlYx6kFeCh5sdXN0
cmUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2USPHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfUr6YAoHEgUOAOwCAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMB
EgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEAKCQoCCCUSAxYAQAoICgEIEgMXAHAKCQoCCAsS
AxcAcAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADcKCQoCCAgSAxkANwoICgEIEgMa
AEAKCQoCCAESAxoAQAoICgEIEgMbAEAKCQoCCCkSAxsAQAoICgEIEgMcAD8KCQoCCC0SAxwA
PwoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKRAoCBAASBCMAPwEaOCBSZXByZXNlbnRzIHRo
ZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQAARIDIwgZ
CkAKBAQAAgASBCUCJjIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3
YXMgY3JlYXRlZC4KCgwKBQQAAgAGEgMlAhsKDAoFBAACAAESAyUcJwoMCgUEAAIAAxIDJSor
CgwKBQQAAgAIEgMmBjEKDwoIBAACAAicCAASAyYHMApFCgQEAAIBEgQpAioyGjcgT3V0cHV0
IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCgwKBQQA
AgEGEgMpAhsKDAoFBAACAQESAykcJAoMCgUEAAIBAxIDKScoCgwKBQQAAgEIEgMqBjEKDwoI
BAACAQicCAASAyoHMApZCgQEAAICEgMtAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmlu
ZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoF
BAACAgUSAy0CCAoMCgUEAAICARIDLQkPCgwKBQQAAgIDEgMtEhMKDAoFBAACAggSAy0UPwoP
CggEAAICCJwIABIDLRU+CkcKBAQAAgMSAzACPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRo
ZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRIDMAIICgwKBQQA
AgMBEgMwCQ0KDAoFBAACAwMSAzAQEQoMCgUEAAIDCBIDMBI9Cg8KCAQAAgMInAgAEgMwEzwK
0gIKBAQAAgQSAzgCThrEAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1
c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVy
YXRpb25zIHRoYXQgaGF2ZSBiZWVuIGNhbmNlbGxlZCBzdWNjZXNzZnVsbHkKIGhhdmUKIFtn
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXVtnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uLmVycm9yXQogdmFsdWUgd2l0aCBhIFtnb29nbGUucnBjLlN0YXR1cy5jb2Rl
XVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiBgMWAsCiBjb3JyZXNwb25kaW5nIHRvIGBD
b2RlLkNBTkNFTExFRGAuCgoMCgUEAAIEBRIDOAIGCgwKBQQAAgQBEgM4Bx0KDAoFBAACBAMS
AzggIQoMCgUEAAIECBIDOCJNCg8KCAQAAgQInAgAEgM4I0wKRAoEBAACBRIDOwJFGjcgT3V0
cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCgwK
BQQAAgUFEgM7AggKDAoFBAACBQESAzsJFAoMCgUEAAIFAxIDOxcYCgwKBQQAAgUIEgM7GUQK
DwoIBAACBQicCAASAzsaQwo2CgQEAAIGEgM+Ak0aKSBPdXRwdXQgb25seS4gUHJvZ3Jlc3Mg
b2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgYGEgM+AhMKDAoFBAACBgESAz4UHAoMCgUEAAIG
AxIDPh8gCgwKBQQAAgYIEgM+IUwKDwoIBAACBgicCAASAz4iSwpbCgIEARIEQgBFARpPIE1l
c3NhZ2UgZGVzY3JpYmluZyB0aGUgcHJvZ3Jlc3Mgb2YgYSBjbHVzdGVyIG11dGF0aW9uIGxv
bmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAQESA0IIGQo+CgQEAQIAEgNEAk8aMSBPdXRw
dXQgb25seS4gU3RlcHMgYW5kIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAECAAQS
A0QCCgoMCgUEAQIABhIDRAsYCgwKBQQBAgABEgNEGR4KDAoFBAECAAMSA0QhIgoMCgUEAQIA
CBIDRCNOCg8KCAQBAgAInAgAEgNEJE0KbAoCBAISBUkA0QEBGl8gTWVzc2FnZSBkZXNjcmli
aW5nIHRoZSBzdGF0dXMgb2YgYSBzaW5nbGUgc3RlcCBpbiBhIGNsdXN0ZXIgbXV0YXRpb24K
IGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAgESA0kIFQosCgQEAgQAEgRLAlcDGh4g
U3RhdGUgb2YgdGhlIG9wZXJhdGlvbiBzdGVwLgoKDAoFBAIEAAESA0sHDAojCgYEAgQAAgAS
A00EGhoUIFVuc3BlY2lmaWVkIHN0YXRlLgoKDgoHBAIEAAIAARIDTQQVCg4KBwQCBAACAAIS
A00YGQo8CgYEAgQAAgESA1AEEBotIEluaXRpYWwgc3RhdGUgYmVmb3JlIHN0ZXAgZXhlY3V0
aW9uIHN0YXJ0cy4KCg4KBwQCBAACAQESA1AECwoOCgcEAgQAAgECEgNQDg8KNwoGBAIEAAIC
EgNTBBQaKCBTdGVwIGV4ZWN1dGlvbiBpcyBydW5uaW5nIGluIHByb2dyZXNzLgoKDgoHBAIE
AAICARIDUwQPCg4KBwQCBAACAgISA1MSEwotCgYEAgQAAgMSA1YEDRoeIFN0ZXAgZXhlY3V0
aW9uIGlzIGNvbXBsZXRlZC4KCg4KBwQCBAACAwESA1YECAoOCgcEAgQAAgMCEgNWCwwKJwoE
BAIIABIFWgLNAQMaGCBTdGVwIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAggAARIDWggMCmMK
BAQCAgASBF0EXjQaVSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBuZXcg
bmV0d29yayBjcmVhdGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDAoFBAICAAYS
A10EEQoMCgUEAgIAARIDXRIgCgwKBQQCAgADEgNdIyQKDAoFBAICAAgSA14IMwoPCggEAgIA
CJwIABIDXgkyCnIKBAQCAgESBGIEYzQaZCBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0
ZXMgdGhhdCBuZXcgcHJpdmF0ZSBzZXJ2aWNlIGFjY2VzcyBjcmVhdGlvbgogaXMgcGFydCBv
ZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAICAQYSA2IEHgoMCgUEAgIBARIDYh88CgwKBQQCAgED
EgNiP0AKDAoFBAICAQgSA2MIMwoPCggEAgIBCJwIABIDYwkyCm4KBAQCAgISBGcEaDQaYCBP
dXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBuZXcgRmlsZXN0b3JlIGluc3Rh
bmNlIGNyZWF0aW9uIGlzCiBwYXJ0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAgICBhIDZwQb
CgwKBQQCAgIBEgNnHDUKDAoFBAICAgMSA2c4OQoMCgUEAgICCBIDaAgzCg8KCAQCAgIInAgA
EgNoCTIKcAoEBAICAxIEbARtNBpiIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0
aGF0IG5ldyBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBjcmVhdGlvbiBpcwogcGFydCBvZiB0aGUg
b3BlcmF0aW9uLgoKDAoFBAICAwYSA2wEFwoMCgUEAgIDARIDbBgtCgwKBQQCAgMDEgNsMDEK
DAoFBAICAwgSA20IMwoPCggEAgIDCJwIABIDbQkyCmsKBAQCAgQSBHEEcjQaXSBPdXRwdXQg
b25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBuZXcgTHVzdHJlIGluc3RhbmNlIGNyZWF0
aW9uIGlzIHBhcnQKIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAgIEBhIDcQQYCgwKBQQCAgQB
EgNxGS8KDAoFBAICBAMSA3EyMwoMCgUEAgIECBIDcggzCg8KCAQCAgQInAgAEgNyCTIKZAoE
BAICBRIEdgR3NBpWIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IG9yY2hl
c3RyYXRvciBjcmVhdGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDAoFBAICBQYS
A3YEFgoMCgUEAgIFARIDdhcqCgwKBQQCAgUDEgN2LS4KDAoFBAICBQgSA3cIMwoPCggEAgIF
CJwIABIDdwkyCmMKBAQCAgYSBHsEfDQaVSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0
ZXMgdGhhdCBuZXcgbm9kZXNldCBjcmVhdGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9u
LgoKDAoFBAICBgYSA3sEEQoMCgUEAgIGARIDexIgCgwKBQQCAgYDEgN7IyQKDAoFBAICBggS
A3wIMwoPCggEAgIGCJwIABIDfAkyCmcKBAQCAgcSBoABBIEBNBpXIE91dHB1dCBvbmx5LiBJ
ZiBzZXQsIGluZGljYXRlcyB0aGF0IG5ldyBwYXJ0aXRpb24gY3JlYXRpb24gaXMgcGFydCBv
ZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQCAgcGEgSAAQQTCg0KBQQCAgcBEgSAARQkCg0KBQQC
AgcDEgSAAScpCg0KBQQCAgcIEgSBAQgzChAKCAQCAgcInAgAEgSBAQkyCmgKBAQCAggSBoUB
BIYBNBpYIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IG5ldyBsb2dpbiBu
b2RlIGNyZWF0aW9uIGlzIHBhcnQgb2YKIHRoZSBvcGVyYXRpb24uCgoNCgUEAgIIBhIEhQEE
EwoNCgUEAgIIARIEhQEUJQoNCgUEAgIIAxIEhQEoKgoNCgUEAgIICBIEhgEIMwoQCggEAgII
CJwIABIEhgEJMgplCgQEAgIJEgaKAQSLATQaVSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRp
Y2F0ZXMgdGhhdCBjbHVzdGVyIGhlYWx0aCBjaGVjayBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0
aW9uLgoKDQoFBAICCQYSBIoBBBYKDQoFBAICCQESBIoBFysKDQoFBAICCQMSBIoBLjAKDQoF
BAICCQgSBIsBCDMKEAoIBAICCQicCAASBIsBCTIKZwoEBAICChIGjwEEkAE0GlcgT3V0cHV0
IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgYW4gb3JjaGVzdHJhdG9yIHVwZGF0ZSBp
cyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICCgYSBI8BBBYKDQoFBAICCgESBI8B
FyoKDQoFBAICCgMSBI8BLS8KDQoFBAICCggSBJABCDMKEAoIBAICCgicCAASBJABCTIKXwoE
BAICCxIGlAEElQE0Gk8gT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbm9k
ZXNldCB1cGRhdGUgaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQCAgsGEgSUAQQR
Cg0KBQQCAgsBEgSUARIgCg0KBQQCAgsDEgSUASMlCg0KBQQCAgsIEgSVAQgzChAKCAQCAgsI
nAgAEgSVAQkyCmEKBAQCAgwSBpkBBJoBNBpRIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGlj
YXRlcyB0aGF0IHBhcnRpdGlvbiB1cGRhdGUgaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4K
Cg0KBQQCAgwGEgSZAQQTCg0KBQQCAgwBEgSZARQkCg0KBQQCAgwDEgSZAScpCg0KBQQCAgwI
EgSaAQgzChAKCAQCAgwInAgAEgSaAQkyCmIKBAQCAg0SBp4BBJ8BNBpSIE91dHB1dCBvbmx5
LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IGxvZ2luIG5vZGUgdXBkYXRlIGlzIHBhcnQgb2Yg
dGhlCiBvcGVyYXRpb24uCgoNCgUEAgINBhIEngEEEwoNCgUEAgINARIEngEUJQoNCgUEAgIN
AxIEngEoKgoNCgUEAgINCBIEnwEIMwoQCggEAgINCJwIABIEnwEJMgpmCgQEAgIOEgajAQSk
ATQaViBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBvcmNoZXN0cmF0b3Ig
ZGVsZXRpb24gaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQCAg4GEgSjAQQWCg0K
BQQCAg4BEgSjARcqCg0KBQQCAg4DEgSjAS0vCg0KBQQCAg4IEgSkAQgzChAKCAQCAg4InAgA
EgSkAQkyCmEKBAQCAg8SBqgBBKkBNBpRIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRl
cyB0aGF0IG5vZGVzZXQgZGVsZXRpb24gaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0K
BQQCAg8GEgSoAQQRCg0KBQQCAg8BEgSoARIgCg0KBQQCAg8DEgSoASMlCg0KBQQCAg8IEgSp
AQgzChAKCAQCAg8InAgAEgSpAQkyCmMKBAQCAhASBq0BBK4BNBpTIE91dHB1dCBvbmx5LiBJ
ZiBzZXQsIGluZGljYXRlcyB0aGF0IHBhcnRpdGlvbiBkZWxldGlvbiBpcyBwYXJ0IG9mIHRo
ZQogb3BlcmF0aW9uLgoKDQoFBAICEAYSBK0BBBMKDQoFBAICEAESBK0BFCQKDQoFBAICEAMS
BK0BJykKDQoFBAICEAgSBK4BCDMKEAoIBAICEAicCAASBK4BCTIKZAoEBAICERIGsgEEswE0
GlQgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbG9naW4gbm9kZSBkZWxl
dGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICEQYSBLIBBBMKDQoFBAIC
EQESBLIBFCUKDQoFBAICEQMSBLIBKCoKDQoFBAICEQgSBLMBCDMKEAoIBAICEQicCAASBLMB
CTIKbAoEBAICEhIGtwEEuAE0GlwgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRo
YXQgRmlsZXN0b3JlIGluc3RhbmNlIGRlbGV0aW9uIGlzIHBhcnQKIG9mIHRoZSBvcGVyYXRp
b24uCgoNCgUEAgISBhIEtwEEGwoNCgUEAgISARIEtwEcNQoNCgUEAgISAxIEtwE4OgoNCgUE
AgISCBIEuAEIMwoQCggEAgISCJwIABIEuAEJMgpuCgQEAgITEga8AQS9ATQaXiBPdXRwdXQg
b25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBkZWxl
dGlvbiBpcyBwYXJ0CiBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAICEwYSBLwBBBcKDQoFBAIC
EwESBLwBGC0KDQoFBAICEwMSBLwBMDIKDQoFBAICEwgSBL0BCDMKEAoIBAICEwicCAASBL0B
CTIKaQoEBAICFBIGwQEEwgE0GlkgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRo
YXQgTHVzdHJlIGluc3RhbmNlIGRlbGV0aW9uIGlzIHBhcnQgb2YKIHRoZSBvcGVyYXRpb24u
CgoNCgUEAgIUBhIEwQEEGAoNCgUEAgIUARIEwQEZLwoNCgUEAgIUAxIEwQEyNAoNCgUEAgIU
CBIEwgEIMwoQCggEAgIUCJwIABIEwgEJMgpwCgQEAgIVEgbGAQTHATQaYCBPdXRwdXQgb25s
eS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBwcml2YXRlIHNlcnZpY2UgYWNjZXNzIGRlbGV0
aW9uIGlzCiBwYXJ0IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEAgIVBhIExgEEHgoNCgUEAgIV
ARIExgEfPAoNCgUEAgIVAxIExgE/QQoNCgUEAgIVCBIExwEIMwoQCggEAgIVCJwIABIExwEJ
MgphCgQEAgIWEgbLAQTMATQaUSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhh
dCBuZXR3b3JrIGRlbGV0aW9uIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoNCgUEAgIW
BhIEywEEEQoNCgUEAgIWARIEywESIAoNCgUEAgIWAxIEywEjJQoNCgUEAgIWCBIEzAEIMwoQ
CggEAgIWCJwIABIEzAEJMgo5CgQEAgIXEgTQAQI+GisgT3V0cHV0IG9ubHkuIFN0YXRlIG9m
IHRoZSBvcGVyYXRpb24gc3RlcC4KCg0KBQQCAhcGEgTQAQIHCg0KBQQCAhcBEgTQAQgNCg0K
BQQCAhcDEgTQARARCg0KBQQCAhcIEgTQARI9ChAKCAQCAhcInAgAEgTQARM8CloKAgQDEgbU
AQDbAQEaTCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIG5l
dyBuZXR3b3JrIHNob3VsZCBiZSBjcmVhdGVkLgoKCwoDBAMBEgTUAQgVCnwKBAQDAgASBtcB
AtoBBBpsIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBuZXR3b3JrIHRvIGNyZWF0ZSwgaW4g
dGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9nbG9iYWwvbmV0d29ya3Mve25ldHdv
cmt9YC4KCg0KBQQDAgAFEgTXAQIICg0KBQQDAgABEgTXAQkQCg0KBQQDAgADEgTXARMUCg8K
BQQDAgAIEgbXARXaAQMKEAoIBAMCAAicCAASBNgBBC0KDwoHBAMCAAifCBIE2QEEUApoCgIE
BBIE3wEAJRpcIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEg
bmV3IHByaXZhdGUgc2VydmljZSBhY2Nlc3Mgc2hvdWxkCiBiZSBjcmVhdGVkLgoKCwoDBAQB
EgTfAQgiCmYKAgQFEgbjAQDsAQEaWCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRp
Y2F0ZXMgdGhhdCBhIG5ldyBmaWxlc3RvcmUgaW5zdGFuY2Ugc2hvdWxkIGJlCiBjcmVhdGVk
LgoKCwoDBAUBEgTjAQgfCowBCgQEBQIAEgbmAQLrAQQafCBPdXRwdXQgb25seS4gTmFtZSBv
ZiB0aGUgRmlsZXN0b3JlIGluc3RhbmNlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoF
BAUCAAUSBOYBAggKDQoFBAUCAAESBOYBCRIKDQoFBAUCAAMSBOYBFRYKDwoFBAUCAAgSBuYB
F+sBAwoQCggEBQIACJwIABIE5wEELQoRCgcEBQIACJ8IEgboAQTqAQUKYgoCBAYSBvABAPYB
ARpUIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbmV3IHN0
b3JhZ2UgYnVja2V0IHNob3VsZCBiZQogY3JlYXRlZC4KCgsKAwQGARIE8AEIGwoyCgQEBgIA
EgbyAQL1AQQaIiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgYnVja2V0LgoKDQoFBAYCAAUS
BPIBAggKDQoFBAYCAAESBPIBCQ8KDQoFBAYCAAMSBPIBEhMKDwoFBAYCAAgSBvIBFPUBAwoQ
CggEBgIACJwIABIE8wEELQoPCgcEBgIACJ8IEgT0AQRPCmMKAgQHEgb6AQCBAgEaVSBXaGVu
IHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIG5ldyBsdXN0cmUgaW5z
dGFuY2Ugc2hvdWxkIGJlCiBjcmVhdGVkLgoKCwoDBAcBEgT6AQgcCpIBCgQEBwIAEgb9AQKA
AgQagQEgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIE1hbmFnZWQgTHVzdHJlIGluc3RhbmNl
LCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBAcCAAUSBP0BAggKDQoFBAcCAAESBP0B
CQ8KDQoFBAcCAAMSBP0BEhMKDwoFBAcCAAgSBv0BFIACAwoQCggEBwIACJwIABIE/gEELQoP
CgcEBwIACJ8IEgT/AQRQCloKAgQIEgSEAgAdGk4gV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3Rl
cCwgaW5kaWNhdGVzIHRoYXQgYW4gb3JjaGVzdHJhdG9yIHNob3VsZCBiZSBjcmVhdGVkLgoK
CwoDBAgBEgSEAggaClYKAgQJEgaHAgCKAgEaSCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVw
LCBpbmRpY2F0ZXMgdGhhdCBhIG5vZGVzZXQgc2hvdWxkIGJlIGNyZWF0ZWQuCgoLCgMECQES
BIcCCBUKOgoEBAkCABIEiQICSxosIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBub2Rlc2V0
IHRvIGNyZWF0ZQoKDQoFBAkCAAQSBIkCAgoKDQoFBAkCAAUSBIkCCxEKDQoFBAkCAAESBIkC
EhoKDQoFBAkCAAMSBIkCHR4KDQoFBAkCAAgSBIkCH0oKEAoIBAkCAAicCAASBIkCIEkKWAoC
BAoSBo0CAJACARpKIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0
IGEgcGFydGl0aW9uIHNob3VsZCBiZSBjcmVhdGVkLgoKCwoDBAoBEgSNAggXCjwKBAQKAgAS
BI8CAk0aLiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgcGFydGl0aW9uIHRvIGNyZWF0ZQoK
DQoFBAoCAAQSBI8CAgoKDQoFBAoCAAUSBI8CCxEKDQoFBAoCAAESBI8CEhwKDQoFBAoCAAMS
BI8CHyAKDQoFBAoCAAgSBI8CIUwKEAoIBAoCAAicCAASBI8CIksKVwoCBAsSBJMCABoaSyBX
aGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIGxvZ2luIG5vZGUg
c2hvdWxkIGJlIGNyZWF0ZWQuCgoLCgMECwESBJMCCBcKYgoCBAwSBJcCAB0aViBXaGVuIHNl
dCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBjbHVzdGVyIGhlYWx0aCBjaGVj
ayBzaG91bGQgYmUKIHBlcmZvcm1lZC4KCgsKAwQMARIElwIIGgpaCgIEDRIEmgIAHRpOIFdo
ZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGFuIG9yY2hlc3RyYXRv
ciBzaG91bGQgYmUgdXBkYXRlZC4KCgsKAwQNARIEmgIIGgpWCgIEDhIGnQIAoAIBGkggV2hl
biBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBub2Rlc2V0IHNob3Vs
ZCBiZSB1cGRhdGVkLgoKCwoDBA4BEgSdAggVCjoKBAQOAgASBJ8CAksaLCBPdXRwdXQgb25s
eS4gTmFtZSBvZiB0aGUgbm9kZXNldCB0byB1cGRhdGUKCg0KBQQOAgAEEgSfAgIKCg0KBQQO
AgAFEgSfAgsRCg0KBQQOAgABEgSfAhIaCg0KBQQOAgADEgSfAh0eCg0KBQQOAgAIEgSfAh9K
ChAKCAQOAgAInAgAEgSfAiBJClgKAgQPEgajAgCmAgEaSiBXaGVuIHNldCBpbiBPcGVyYXRp
b25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIHBhcnRpdGlvbiBzaG91bGQgYmUgdXBkYXRlZC4K
CgsKAwQPARIEowIIFwo8CgQEDwIAEgSlAgJNGi4gT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhl
IHBhcnRpdGlvbiB0byB1cGRhdGUKCg0KBQQPAgAEEgSlAgIKCg0KBQQPAgAFEgSlAgsRCg0K
BQQPAgABEgSlAhIcCg0KBQQPAgADEgSlAh8gCg0KBQQPAgAIEgSlAiFMChAKCAQPAgAInAgA
EgSlAiJLClcKAgQQEgSpAgAaGksgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNh
dGVzIHRoYXQgYSBsb2dpbiBub2RlIHNob3VsZCBiZSB1cGRhdGVkLgoKCwoDBBABEgSpAggX
CloKAgQREgSsAgAdGk4gV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRo
YXQgYW4gb3JjaGVzdHJhdG9yIHNob3VsZCBiZSBkZWxldGVkLgoKCwoDBBEBEgSsAggaClYK
AgQSEgavAgCyAgEaSCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhh
dCBhIG5vZGVzZXQgc2hvdWxkIGJlIGRlbGV0ZWQuCgoLCgMEEgESBK8CCBUKOgoEBBICABIE
sQICSxosIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBub2Rlc2V0IHRvIGRlbGV0ZQoKDQoF
BBICAAQSBLECAgoKDQoFBBICAAUSBLECCxEKDQoFBBICAAESBLECEhoKDQoFBBICAAMSBLEC
HR4KDQoFBBICAAgSBLECH0oKEAoIBBICAAicCAASBLECIEkKWAoCBBMSBrUCALgCARpKIFdo
ZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgcGFydGl0aW9uIHNo
b3VsZCBiZSBkZWxldGVkLgoKCwoDBBMBEgS1AggXCjwKBAQTAgASBLcCAk0aLiBPdXRwdXQg
b25seS4gTmFtZSBvZiB0aGUgcGFydGl0aW9uIHRvIGRlbGV0ZQoKDQoFBBMCAAQSBLcCAgoK
DQoFBBMCAAUSBLcCCxEKDQoFBBMCAAESBLcCEhwKDQoFBBMCAAMSBLcCHyAKDQoFBBMCAAgS
BLcCIUwKEAoIBBMCAAicCAASBLcCIksKVwoCBBQSBLsCABoaSyBXaGVuIHNldCBpbiBPcGVy
YXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIGxvZ2luIG5vZGUgc2hvdWxkIGJlIGRlbGV0
ZWQuCgoLCgMEFAESBLsCCBcKYgoCBBUSBr8CAMgCARpUIFdoZW4gc2V0IGluIE9wZXJhdGlv
blN0ZXAsIGluZGljYXRlcyB0aGF0IGEgRmlsZXN0b3JlIGluc3RhbmNlIHNob3VsZCBiZQog
ZGVsZXRlZC4KCgsKAwQVARIEvwIIHwqMAQoEBBUCABIGwgICxwIEGnwgT3V0cHV0IG9ubHku
IE5hbWUgb2YgdGhlIEZpbGVzdG9yZSBpbnN0YW5jZSwgaW4gdGhlIGZvcm1hdAogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNl
fWAKCg0KBQQVAgAFEgTCAgIICg0KBQQVAgABEgTCAgkSCg0KBQQVAgADEgTCAhUWCg8KBQQV
AgAIEgbCAhfHAgMKEAoIBBUCAAicCAASBMMCBC0KEQoHBBUCAAifCBIGxAIExgIFCmIKAgQW
EgbMAgDSAgEaVCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBD
bG91ZCBTdG9yYWdlIGJ1Y2tldCBzaG91bGQgYmUKIGRlbGV0ZWQuCgoLCgMEFgESBMwCCBsK
MgoEBBYCABIGzgIC0QIEGiIgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIGJ1Y2tldC4KCg0K
BQQWAgAFEgTOAgIICg0KBQQWAgABEgTOAgkPCg0KBQQWAgADEgTOAhITCg8KBQQWAgAIEgbO
AhTRAgMKEAoIBBYCAAicCAASBM8CBC0KDwoHBBYCAAifCBIE0AIETwpfCgIEFxIG1gIA3QIB
GlEgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBMdXN0cmUg
aW5zdGFuY2Ugc2hvdWxkIGJlCiBkZWxldGVkLgoKCwoDBBcBEgTWAggcCpIBCgQEFwIAEgbZ
AgLcAgQagQEgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIE1hbmFnZWQgTHVzdHJlIGluc3Rh
bmNlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBBcCAAUSBNkCAggKDQoFBBcCAAES
BNkCCQ8KDQoFBBcCAAMSBNkCEhMKDwoFBBcCAAgSBtkCFNwCAwoQCggEFwIACJwIABIE2gIE
LQoPCgcEFwIACJ8IEgTbAgRQClkKAgQYEgThAgAlGk0gV2hlbiBzZXQgaW4gT3BlcmF0aW9u
U3RlcCwgaW5kaWNhdGVzIHByaXZhdGUgc2VydmljZSBhY2Nlc3MgZGVsZXRpb24KIHN0ZXAu
CgoLCgMEGAESBOECCCIKYwoCBBkSBuUCAOwCARpVIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0
ZXAsIGluZGljYXRlcyBuZXR3b3JrIGRlbGV0aW9uIHN0ZXAgd2l0aCB0aGUKIHJlc291cmNl
IG5hbWUuCgoLCgMEGQESBOUCCBUKfAoEBBkCABIG6AIC6wIEGmwgT3V0cHV0IG9ubHkuIE5h
bWUgb2YgdGhlIG5ldHdvcmsgdG8gZGVsZXRlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMv
e3Byb2plY3R9L2dsb2JhbC9uZXR3b3Jrcy97bmV0d29ya31gLgoKDQoFBBkCAAUSBOgCAggK
DQoFBBkCAAESBOgCCRAKDQoFBBkCAAMSBOgCExQKDwoFBBkCAAgSBugCFesCAwoQCggEGQIA
CJwIABIE6QIELQoPCgcEGQIACJ8IEgTqAgRQYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: progress Type: 11 (.google.cloud.hypercomputecluster.v1.OperationProgress)

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationProgress ===
    # Fields for OperationProgress
    # Field: steps Type: 11 (.google.cloud.hypercomputecluster.v1.OperationStep)

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationStep ===
    # Fields for OperationStep
    # Field: create_network Type: 11 (.google.cloud.hypercomputecluster.v1.CreateNetwork)
    # Field: create_private_service_access Type: 11 (.google.cloud.hypercomputecluster.v1.CreatePrivateServiceAccess)
    # Field: create_filestore_instance Type: 11 (.google.cloud.hypercomputecluster.v1.CreateFilestoreInstance)
    # Field: create_storage_bucket Type: 11 (.google.cloud.hypercomputecluster.v1.CreateStorageBucket)
    # Field: create_lustre_instance Type: 11 (.google.cloud.hypercomputecluster.v1.CreateLustreInstance)
    # Field: create_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1.CreateOrchestrator)
    # Field: create_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1.CreateNodeset)
    # Field: create_partition Type: 11 (.google.cloud.hypercomputecluster.v1.CreatePartition)
    # Field: create_login_node Type: 11 (.google.cloud.hypercomputecluster.v1.CreateLoginNode)
    # Field: check_cluster_health Type: 11 (.google.cloud.hypercomputecluster.v1.CheckClusterHealth)
    # Field: update_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1.UpdateOrchestrator)
    # Field: update_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1.UpdateNodeset)
    # Field: update_partition Type: 11 (.google.cloud.hypercomputecluster.v1.UpdatePartition)
    # Field: update_login_node Type: 11 (.google.cloud.hypercomputecluster.v1.UpdateLoginNode)
    # Field: delete_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteOrchestrator)
    # Field: delete_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteNodeset)
    # Field: delete_partition Type: 11 (.google.cloud.hypercomputecluster.v1.DeletePartition)
    # Field: delete_login_node Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteLoginNode)
    # Field: delete_filestore_instance Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteFilestoreInstance)
    # Field: delete_storage_bucket Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteStorageBucket)
    # Field: delete_lustre_instance Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteLustreInstance)
    # Field: delete_private_service_access Type: 11 (.google.cloud.hypercomputecluster.v1.DeletePrivateServiceAccess)
    # Field: delete_network Type: 11 (.google.cloud.hypercomputecluster.v1.DeleteNetwork)
    # Field: state Type: 14 (.google.cloud.hypercomputecluster.v1.OperationStep.State)

# Enum: OperationStep::State
our $OperationStep_STATE_UNSPECIFIED = 0;
our $OperationStep_WAITING = 1;
our $OperationStep_IN_PROGRESS = 2;
our $OperationStep_DONE = 3;

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNetwork ===
    # Fields for CreateNetwork
    # Field: network Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePrivateServiceAccess ===
    # Fields for CreatePrivateServiceAccess

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateFilestoreInstance ===
    # Fields for CreateFilestoreInstance
    # Field: filestore Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateStorageBucket ===
    # Fields for CreateStorageBucket
    # Field: bucket Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLustreInstance ===
    # Fields for CreateLustreInstance
    # Field: lustre Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateOrchestrator ===
    # Fields for CreateOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNodeset ===
    # Fields for CreateNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePartition ===
    # Fields for CreatePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLoginNode ===
    # Fields for CreateLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CheckClusterHealth ===
    # Fields for CheckClusterHealth

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateOrchestrator ===
    # Fields for UpdateOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateNodeset ===
    # Fields for UpdateNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdatePartition ===
    # Fields for UpdatePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateLoginNode ===
    # Fields for UpdateLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteOrchestrator ===
    # Fields for DeleteOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNodeset ===
    # Fields for DeleteNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePartition ===
    # Fields for DeletePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLoginNode ===
    # Fields for DeleteLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteFilestoreInstance ===
    # Fields for DeleteFilestoreInstance
    # Field: filestore Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteStorageBucket ===
    # Fields for DeleteStorageBucket
    # Field: bucket Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLustreInstance ===
    # Fields for DeleteLustreInstance
    # Field: lustre Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePrivateServiceAccess ===
    # Fields for DeletePrivateServiceAccess

# === Message: Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNetwork ===
    # Fields for DeleteNetwork
    # Field: network Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Hypercomputecluster::V1::OperationMetadata - Compiled Protocol Buffers messages for google/cloud/hypercomputecluster/v1/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Hypercomputecluster::V1::OperationMetadata;

    my $msg = Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/hypercomputecluster/v1/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of `1`,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=item * C<< $msg->progress() >> / C<< $msg->progress($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationProgress>)

Output only. Progress of the operation.

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationProgress

Message describing the progress of a cluster mutation long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->steps() >> / C<< $msg->steps($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationStep>)

Output only. Steps and status of the operation.

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::OperationStep

Message describing the status of a single step in a cluster mutation
long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_network() >> / C<< $msg->create_network($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNetwork>)

Output only. If set, indicates that new network creation is part of the
operation.

=item * C<< $msg->create_private_service_access() >> / C<< $msg->create_private_service_access($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePrivateServiceAccess>)

Output only. If set, indicates that new private service access creation
is part of the operation.

=item * C<< $msg->create_filestore_instance() >> / C<< $msg->create_filestore_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateFilestoreInstance>)

Output only. If set, indicates that new Filestore instance creation is
part of the operation.

=item * C<< $msg->create_storage_bucket() >> / C<< $msg->create_storage_bucket($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateStorageBucket>)

Output only. If set, indicates that new Cloud Storage bucket creation is
part of the operation.

=item * C<< $msg->create_lustre_instance() >> / C<< $msg->create_lustre_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLustreInstance>)

Output only. If set, indicates that new Lustre instance creation is part
of the operation.

=item * C<< $msg->create_orchestrator() >> / C<< $msg->create_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateOrchestrator>)

Output only. If set, indicates that orchestrator creation is part of the
operation.

=item * C<< $msg->create_nodeset() >> / C<< $msg->create_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNodeset>)

Output only. If set, indicates that new nodeset creation is part of the
operation.

=item * C<< $msg->create_partition() >> / C<< $msg->create_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePartition>)

Output only. If set, indicates that new partition creation is part of the
operation.

=item * C<< $msg->create_login_node() >> / C<< $msg->create_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLoginNode>)

Output only. If set, indicates that new login node creation is part of
the operation.

=item * C<< $msg->check_cluster_health() >> / C<< $msg->check_cluster_health($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CheckClusterHealth>)

Output only. If set, indicates that cluster health check is part of the
operation.

=item * C<< $msg->update_orchestrator() >> / C<< $msg->update_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateOrchestrator>)

Output only. If set, indicates that an orchestrator update is part of the
operation.

=item * C<< $msg->update_nodeset() >> / C<< $msg->update_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateNodeset>)

Output only. If set, indicates that nodeset update is part of the
operation.

=item * C<< $msg->update_partition() >> / C<< $msg->update_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdatePartition>)

Output only. If set, indicates that partition update is part of the
operation.

=item * C<< $msg->update_login_node() >> / C<< $msg->update_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateLoginNode>)

Output only. If set, indicates that login node update is part of the
operation.

=item * C<< $msg->delete_orchestrator() >> / C<< $msg->delete_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteOrchestrator>)

Output only. If set, indicates that orchestrator deletion is part of the
operation.

=item * C<< $msg->delete_nodeset() >> / C<< $msg->delete_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNodeset>)

Output only. If set, indicates that nodeset deletion is part of the
operation.

=item * C<< $msg->delete_partition() >> / C<< $msg->delete_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePartition>)

Output only. If set, indicates that partition deletion is part of the
operation.

=item * C<< $msg->delete_login_node() >> / C<< $msg->delete_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLoginNode>)

Output only. If set, indicates that login node deletion is part of the
operation.

=item * C<< $msg->delete_filestore_instance() >> / C<< $msg->delete_filestore_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteFilestoreInstance>)

Output only. If set, indicates that Filestore instance deletion is part
of the operation.

=item * C<< $msg->delete_storage_bucket() >> / C<< $msg->delete_storage_bucket($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteStorageBucket>)

Output only. If set, indicates that Cloud Storage bucket deletion is part
of the operation.

=item * C<< $msg->delete_lustre_instance() >> / C<< $msg->delete_lustre_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLustreInstance>)

Output only. If set, indicates that Lustre instance deletion is part of
the operation.

=item * C<< $msg->delete_private_service_access() >> / C<< $msg->delete_private_service_access($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePrivateServiceAccess>)

Output only. If set, indicates that private service access deletion is
part of the operation.

=item * C<< $msg->delete_network() >> / C<< $msg->delete_network($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNetwork>)

Output only. If set, indicates that network deletion is part of the
operation.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Hypercomputecluster::V1::OperationStep::State>)

Output only. State of the operation step.

=back

=head3 Enum: OperationStep::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<WAITING> => C<1>

=item * C<IN_PROGRESS> => C<2>

=item * C<DONE> => C<3>

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNetwork

When set in OperationStep, indicates that a new network should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Output only. Name of the network to create, in the format
`projects/{project}/global/networks/{network}`.

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePrivateServiceAccess

When set in OperationStep, indicates that a new private service access should
be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateFilestoreInstance

When set in OperationStep, indicates that a new filestore instance should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filestore() >> / C<< $msg->filestore($value) >>

Type: C<String>

Output only. Name of the Filestore instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateStorageBucket

When set in OperationStep, indicates that a new storage bucket should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Name of the bucket.

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLustreInstance

When set in OperationStep, indicates that a new lustre instance should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lustre() >> / C<< $msg->lustre($value) >>

Type: C<String>

Output only. Name of the Managed Lustre instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateOrchestrator

When set in OperationStep, indicates that an orchestrator should be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateNodeset

When set in OperationStep, indicates that a nodeset should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to create

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreatePartition

When set in OperationStep, indicates that a partition should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to create

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CreateLoginNode

When set in OperationStep, indicates that a login node should be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::CheckClusterHealth

When set in OperationStep, indicates that cluster health check should be
performed.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateOrchestrator

When set in OperationStep, indicates that an orchestrator should be updated.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateNodeset

When set in OperationStep, indicates that a nodeset should be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to update

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdatePartition

When set in OperationStep, indicates that a partition should be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to update

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::UpdateLoginNode

When set in OperationStep, indicates that a login node should be updated.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteOrchestrator

When set in OperationStep, indicates that an orchestrator should be deleted.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNodeset

When set in OperationStep, indicates that a nodeset should be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to delete

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePartition

When set in OperationStep, indicates that a partition should be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to delete

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLoginNode

When set in OperationStep, indicates that a login node should be deleted.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteFilestoreInstance

When set in OperationStep, indicates that a Filestore instance should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filestore() >> / C<< $msg->filestore($value) >>

Type: C<String>

Output only. Name of the Filestore instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteStorageBucket

When set in OperationStep, indicates that Cloud Storage bucket should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Name of the bucket.

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteLustreInstance

When set in OperationStep, indicates that a Lustre instance should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lustre() >> / C<< $msg->lustre($value) >>

Type: C<String>

Output only. Name of the Managed Lustre instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeletePrivateServiceAccess

When set in OperationStep, indicates private service access deletion
step.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1::OperationMetadata::DeleteNetwork

When set in OperationStep, indicates network deletion step with the
resource name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Output only. Name of the network to delete, in the format
`projects/{project}/global/networks/{network}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Hypercomputecluster::V1::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
