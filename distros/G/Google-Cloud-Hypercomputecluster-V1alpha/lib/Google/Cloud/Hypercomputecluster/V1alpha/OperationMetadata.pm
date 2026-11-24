package Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata;

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
CkFnb29nbGUvY2xvdWQvaHlwZXJjb21wdXRlY2x1c3Rlci92MWFscGhhL29wZXJhdGlvbl9t
ZXRhZGF0YS5wcm90bxIoZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFhbHBo
YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKHAwoRT3BlcmF0aW9u
TWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdl
dBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgF
IAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YBiABKAlC
A+BBA1IKYXBpVmVyc2lvbhJcCghwcm9ncmVzcxgHIAEoCzI7Lmdvb2dsZS5jbG91ZC5oeXBl
cmNvbXB1dGVjbHVzdGVyLnYxYWxwaGEuT3BlcmF0aW9uUHJvZ3Jlc3NCA+BBA1IIcHJvZ3Jl
c3MiZwoRT3BlcmF0aW9uUHJvZ3Jlc3MSUgoFc3RlcHMYASADKAsyNy5nb29nbGUuY2xvdWQu
aHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLk9wZXJhdGlvblN0ZXBCA+BBA1IFc3RlcHMi
phgKDU9wZXJhdGlvblN0ZXASZQoOY3JlYXRlX25ldHdvcmsYAiABKAsyNy5nb29nbGUuY2xv
dWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLkNyZWF0ZU5ldHdvcmtCA+BBA0gAUg1j
cmVhdGVOZXR3b3JrEo4BCh1jcmVhdGVfcHJpdmF0ZV9zZXJ2aWNlX2FjY2VzcxgDIAEoCzJE
Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYWxwaGEuQ3JlYXRlUHJpdmF0
ZVNlcnZpY2VBY2Nlc3NCA+BBA0gAUhpjcmVhdGVQcml2YXRlU2VydmljZUFjY2VzcxKEAQoZ
Y3JlYXRlX2ZpbGVzdG9yZV9pbnN0YW5jZRgEIAEoCzJBLmdvb2dsZS5jbG91ZC5oeXBlcmNv
bXB1dGVjbHVzdGVyLnYxYWxwaGEuQ3JlYXRlRmlsZXN0b3JlSW5zdGFuY2VCA+BBA0gAUhdj
cmVhdGVGaWxlc3RvcmVJbnN0YW5jZRJ4ChVjcmVhdGVfc3RvcmFnZV9idWNrZXQYBSABKAsy
PS5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLkNyZWF0ZVN0b3Jh
Z2VCdWNrZXRCA+BBA0gAUhNjcmVhdGVTdG9yYWdlQnVja2V0EnsKFmNyZWF0ZV9sdXN0cmVf
aW5zdGFuY2UYBiABKAsyPi5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFs
cGhhLkNyZWF0ZUx1c3RyZUluc3RhbmNlQgPgQQNIAFIUY3JlYXRlTHVzdHJlSW5zdGFuY2US
bwoSY3JlYXRlX2drZV9jbHVzdGVyGAcgASgLMjouZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0
ZWNsdXN0ZXIudjFhbHBoYS5DcmVhdGVHS0VDbHVzdGVyQgPgQQNIAFIQY3JlYXRlR2tlQ2x1
c3RlchJ0ChNjcmVhdGVfb3JjaGVzdHJhdG9yGAggASgLMjwuZ29vZ2xlLmNsb3VkLmh5cGVy
Y29tcHV0ZWNsdXN0ZXIudjFhbHBoYS5DcmVhdGVPcmNoZXN0cmF0b3JCA+BBA0gAUhJjcmVh
dGVPcmNoZXN0cmF0b3ISZQoOY3JlYXRlX25vZGVzZXQYCSABKAsyNy5nb29nbGUuY2xvdWQu
aHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLkNyZWF0ZU5vZGVzZXRCA+BBA0gAUg1jcmVh
dGVOb2Rlc2V0EmsKEGNyZWF0ZV9wYXJ0aXRpb24YCiABKAsyOS5nb29nbGUuY2xvdWQuaHlw
ZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLkNyZWF0ZVBhcnRpdGlvbkID4EEDSABSD2NyZWF0
ZVBhcnRpdGlvbhJsChFjcmVhdGVfbG9naW5fbm9kZRgLIAEoCzI5Lmdvb2dsZS5jbG91ZC5o
eXBlcmNvbXB1dGVjbHVzdGVyLnYxYWxwaGEuQ3JlYXRlTG9naW5Ob2RlQgPgQQNIAFIPY3Jl
YXRlTG9naW5Ob2RlEnUKFGNoZWNrX2NsdXN0ZXJfaGVhbHRoGAwgASgLMjwuZ29vZ2xlLmNs
b3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFhbHBoYS5DaGVja0NsdXN0ZXJIZWFsdGhCA+BB
A0gAUhJjaGVja0NsdXN0ZXJIZWFsdGgSdAoTdXBkYXRlX29yY2hlc3RyYXRvchgNIAEoCzI8
Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYWxwaGEuVXBkYXRlT3JjaGVz
dHJhdG9yQgPgQQNIAFISdXBkYXRlT3JjaGVzdHJhdG9yEmUKDnVwZGF0ZV9ub2Rlc2V0GA4g
ASgLMjcuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFhbHBoYS5VcGRhdGVO
b2Rlc2V0QgPgQQNIAFINdXBkYXRlTm9kZXNldBJrChB1cGRhdGVfcGFydGl0aW9uGA8gASgL
MjkuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFhbHBoYS5VcGRhdGVQYXJ0
aXRpb25CA+BBA0gAUg91cGRhdGVQYXJ0aXRpb24SbAoRdXBkYXRlX2xvZ2luX25vZGUYECAB
KAsyOS5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLlVwZGF0ZUxv
Z2luTm9kZUID4EEDSABSD3VwZGF0ZUxvZ2luTm9kZRJvChJkZWxldGVfZ2tlX2NsdXN0ZXIY
ESABKAsyOi5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLkRlbGV0
ZUdLRUNsdXN0ZXJCA+BBA0gAUhBkZWxldGVHa2VDbHVzdGVyEnQKE2RlbGV0ZV9vcmNoZXN0
cmF0b3IYEiABKAsyPC5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhh
LkRlbGV0ZU9yY2hlc3RyYXRvckID4EEDSABSEmRlbGV0ZU9yY2hlc3RyYXRvchJlCg5kZWxl
dGVfbm9kZXNldBgTIAEoCzI3Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYx
YWxwaGEuRGVsZXRlTm9kZXNldEID4EEDSABSDWRlbGV0ZU5vZGVzZXQSawoQZGVsZXRlX3Bh
cnRpdGlvbhgUIAEoCzI5Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYWxw
aGEuRGVsZXRlUGFydGl0aW9uQgPgQQNIAFIPZGVsZXRlUGFydGl0aW9uEmwKEWRlbGV0ZV9s
b2dpbl9ub2RlGBUgASgLMjkuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFh
bHBoYS5EZWxldGVMb2dpbk5vZGVCA+BBA0gAUg9kZWxldGVMb2dpbk5vZGUShAEKGWRlbGV0
ZV9maWxlc3RvcmVfaW5zdGFuY2UYFiABKAsyQS5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRl
Y2x1c3Rlci52MWFscGhhLkRlbGV0ZUZpbGVzdG9yZUluc3RhbmNlQgPgQQNIAFIXZGVsZXRl
RmlsZXN0b3JlSW5zdGFuY2USeAoVZGVsZXRlX3N0b3JhZ2VfYnVja2V0GBcgASgLMj0uZ29v
Z2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFhbHBoYS5EZWxldGVTdG9yYWdlQnVj
a2V0QgPgQQNIAFITZGVsZXRlU3RvcmFnZUJ1Y2tldBJ7ChZkZWxldGVfbHVzdHJlX2luc3Rh
bmNlGBggASgLMj4uZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFhbHBoYS5E
ZWxldGVMdXN0cmVJbnN0YW5jZUID4EEDSABSFGRlbGV0ZUx1c3RyZUluc3RhbmNlEo4BCh1k
ZWxldGVfcHJpdmF0ZV9zZXJ2aWNlX2FjY2VzcxgZIAEoCzJELmdvb2dsZS5jbG91ZC5oeXBl
cmNvbXB1dGVjbHVzdGVyLnYxYWxwaGEuRGVsZXRlUHJpdmF0ZVNlcnZpY2VBY2Nlc3NCA+BB
A0gAUhpkZWxldGVQcml2YXRlU2VydmljZUFjY2VzcxJlCg5kZWxldGVfbmV0d29yaxgaIAEo
CzI3Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYWxwaGEuRGVsZXRlTmV0
d29ya0ID4EEDSABSDWRlbGV0ZU5ldHdvcmsSWAoFc3RhdGUYASABKA4yPS5nb29nbGUuY2xv
dWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWFscGhhLk9wZXJhdGlvblN0ZXAuU3RhdGVCA+BB
A1IFc3RhdGUiRgoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdXQUlUSU5HEAES
DwoLSU5fUFJPR1JFU1MQAhIICgRET05FEANCBgoEdHlwZSJRCg1DcmVhdGVOZXR3b3JrEkAK
B25ldHdvcmsYASABKAlCJuBBA/pBIAoeY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9OZXR3b3Jr
UgduZXR3b3JrIhwKGkNyZWF0ZVByaXZhdGVTZXJ2aWNlQWNjZXNzImEKF0NyZWF0ZUZpbGVz
dG9yZUluc3RhbmNlEkYKCWZpbGVzdG9yZRgBIAEoCUIo4EED+kEiCiBmaWxlLmdvb2dsZWFw
aXMuY29tL0ZpbGVJbnN0YW5jZVIJZmlsZXN0b3JlIlQKE0NyZWF0ZVN0b3JhZ2VCdWNrZXQS
PQoGYnVja2V0GAEgASgJQiXgQQP6QR8KHXN0b3JhZ2UuZ29vZ2xlYXBpcy5jb20vQnVja2V0
UgZidWNrZXQiVgoUQ3JlYXRlTHVzdHJlSW5zdGFuY2USPgoGbHVzdHJlGAEgASgJQibgQQP6
QSAKHmx1c3RyZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIGbHVzdHJlIjEKEENyZWF0ZUdL
RUNsdXN0ZXISHQoHY2x1c3RlchgBIAEoCUID4EEDUgdjbHVzdGVyIhQKEkNyZWF0ZU9yY2hl
c3RyYXRvciIwCg1DcmVhdGVOb2Rlc2V0Eh8KCG5vZGVzZXRzGAEgAygJQgPgQQNSCG5vZGVz
ZXRzIjYKD0NyZWF0ZVBhcnRpdGlvbhIjCgpwYXJ0aXRpb25zGAEgAygJQgPgQQNSCnBhcnRp
dGlvbnMiEQoPQ3JlYXRlTG9naW5Ob2RlIhQKEkNoZWNrQ2x1c3RlckhlYWx0aCIUChJVcGRh
dGVPcmNoZXN0cmF0b3IiMAoNVXBkYXRlTm9kZXNldBIfCghub2Rlc2V0cxgBIAMoCUID4EED
Ughub2Rlc2V0cyI2Cg9VcGRhdGVQYXJ0aXRpb24SIwoKcGFydGl0aW9ucxgBIAMoCUID4EED
UgpwYXJ0aXRpb25zIhEKD1VwZGF0ZUxvZ2luTm9kZSIxChBEZWxldGVHS0VDbHVzdGVyEh0K
B2NsdXN0ZXIYASABKAlCA+BBA1IHY2x1c3RlciIUChJEZWxldGVPcmNoZXN0cmF0b3IiMAoN
RGVsZXRlTm9kZXNldBIfCghub2Rlc2V0cxgBIAMoCUID4EEDUghub2Rlc2V0cyI2Cg9EZWxl
dGVQYXJ0aXRpb24SIwoKcGFydGl0aW9ucxgBIAMoCUID4EEDUgpwYXJ0aXRpb25zIhEKD0Rl
bGV0ZUxvZ2luTm9kZSJhChdEZWxldGVGaWxlc3RvcmVJbnN0YW5jZRJGCglmaWxlc3RvcmUY
ASABKAlCKOBBA/pBIgogZmlsZS5nb29nbGVhcGlzLmNvbS9GaWxlSW5zdGFuY2VSCWZpbGVz
dG9yZSJUChNEZWxldGVTdG9yYWdlQnVja2V0Ej0KBmJ1Y2tldBgBIAEoCUIl4EED+kEfCh1z
dG9yYWdlLmdvb2dsZWFwaXMuY29tL0J1Y2tldFIGYnVja2V0IlYKFERlbGV0ZUx1c3RyZUlu
c3RhbmNlEj4KBmx1c3RyZRgBIAEoCUIm4EED+kEgCh5sdXN0cmUuZ29vZ2xlYXBpcy5jb20v
SW5zdGFuY2VSBmx1c3RyZSIcChpEZWxldGVQcml2YXRlU2VydmljZUFjY2VzcyJRCg1EZWxl
dGVOZXR3b3JrEkAKB25ldHdvcmsYASABKAlCJuBBA/pBIAoeY29tcHV0ZS5nb29nbGVhcGlz
LmNvbS9OZXR3b3JrUgduZXR3b3JrQo0DCixjb20uZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0
ZWNsdXN0ZXIudjFhbHBoYUIWT3BlcmF0aW9uTWV0YWRhdGFQcm90b1ABWl5jbG91ZC5nb29n
bGUuY29tL2dvL2h5cGVyY29tcHV0ZWNsdXN0ZXIvYXBpdjFhbHBoYS9oeXBlcmNvbXB1dGVj
bHVzdGVycGI7aHlwZXJjb21wdXRlY2x1c3RlcnBiqgIoR29vZ2xlLkNsb3VkLkh5cGVyY29t
cHV0ZUNsdXN0ZXIuVjFBbHBoYcoCKEdvb2dsZVxDbG91ZFxIeXBlcmNvbXB1dGVDbHVzdGVy
XFYxYWxwaGHqAitHb29nbGU6OkNsb3VkOjpIeXBlcmNvbXB1dGVDbHVzdGVyOjpWMWFscGhh
6kFeCh5sdXN0cmUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2USPHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfUrKZwoHEgUOAIQD
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABID
EgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEUKCQoCCCUSAxYARQoICgEIEgMX
AHUKCQoCCAsSAxcAdQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADcKCQoCCAgSAxkA
NwoICgEIEgMaAEUKCQoCCAESAxoARQoICgEIEgMbAEUKCQoCCCkSAxsARQoICgEIEgMcAEQK
CQoCCC0SAxwARAoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKRAoCBAASBCMAPwEaOCBSZXBy
ZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoK
AwQAARIDIwgZCkAKBAQAAgASBCUCJjIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9w
ZXJhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgAGEgMlAhsKDAoFBAACAAESAyUcJwoMCgUE
AAIAAxIDJSorCgwKBQQAAgAIEgMmBjEKDwoIBAACAAicCAASAyYHMApFCgQEAAIBEgQpAioy
GjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmlu
Zy4KCgwKBQQAAgEGEgMpAhsKDAoFBAACAQESAykcJAoMCgUEAAIBAxIDKScoCgwKBQQAAgEI
EgMqBjEKDwoIBAACAQicCAASAyoHMApZCgQEAAICEgMtAkAaTCBPdXRwdXQgb25seS4gU2Vy
dmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0
aW9uLgoKDAoFBAACAgUSAy0CCAoMCgUEAAICARIDLQkPCgwKBQQAAgIDEgMtEhMKDAoFBAAC
AggSAy0UPwoPCggEAAICCJwIABIDLRU+CkcKBAQAAgMSAzACPho6IE91dHB1dCBvbmx5LiBO
YW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRID
MAIICgwKBQQAAgMBEgMwCQ0KDAoFBAACAwMSAzAQEQoMCgUEAAIDCBIDMBI9Cg8KCAQAAgMI
nAgAEgMwEzwK0gIKBAQAAgQSAzgCThrEAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0
aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0
aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBiZWVuIGNhbmNlbGxlZCBzdWNjZXNzZnVsbHkK
IGhhdmUKIFtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXVtnb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXQogdmFsdWUgd2l0aCBhIFtnb29nbGUucnBjLlN0
YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiBgMWAsCiBjb3JyZXNwb25k
aW5nIHRvIGBDb2RlLkNBTkNFTExFRGAuCgoMCgUEAAIEBRIDOAIGCgwKBQQAAgQBEgM4Bx0K
DAoFBAACBAMSAzggIQoMCgUEAAIECBIDOCJNCg8KCAQAAgQInAgAEgM4I0wKRAoEBAACBRID
OwJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJh
dGlvbi4KCgwKBQQAAgUFEgM7AggKDAoFBAACBQESAzsJFAoMCgUEAAIFAxIDOxcYCgwKBQQA
AgUIEgM7GUQKDwoIBAACBQicCAASAzsaQwo2CgQEAAIGEgM+Ak0aKSBPdXRwdXQgb25seS4g
UHJvZ3Jlc3Mgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgYGEgM+AhMKDAoFBAACBgESAz4U
HAoMCgUEAAIGAxIDPh8gCgwKBQQAAgYIEgM+IUwKDwoIBAACBgicCAASAz4iSwpbCgIEARIE
QgBFARpPIE1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgcHJvZ3Jlc3Mgb2YgYSBjbHVzdGVyIG11
dGF0aW9uIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAQESA0IIGQo+CgQEAQIAEgNE
Ak8aMSBPdXRwdXQgb25seS4gU3RlcHMgYW5kIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLgoK
DAoFBAECAAQSA0QCCgoMCgUEAQIABhIDRAsYCgwKBQQBAgABEgNEGR4KDAoFBAECAAMSA0Qh
IgoMCgUEAQIACBIDRCNOCg8KCAQBAgAInAgAEgNEJE0KbAoCBAISBUkA2wEBGl8gTWVzc2Fn
ZSBkZXNjcmliaW5nIHRoZSBzdGF0dXMgb2YgYSBzaW5nbGUgc3RlcCBpbiBhIGNsdXN0ZXIg
bXV0YXRpb24KIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAgESA0kIFQosCgQEAgQA
EgRLAlcDGh4gU3RhdGUgb2YgdGhlIG9wZXJhdGlvbiBzdGVwLgoKDAoFBAIEAAESA0sHDAoj
CgYEAgQAAgASA00EGhoUIFVuc3BlY2lmaWVkIHN0YXRlLgoKDgoHBAIEAAIAARIDTQQVCg4K
BwQCBAACAAISA00YGQo8CgYEAgQAAgESA1AEEBotIEluaXRpYWwgc3RhdGUgYmVmb3JlIHN0
ZXAgZXhlY3V0aW9uIHN0YXJ0cy4KCg4KBwQCBAACAQESA1AECwoOCgcEAgQAAgECEgNQDg8K
NwoGBAIEAAICEgNTBBQaKCBTdGVwIGV4ZWN1dGlvbiBpcyBydW5uaW5nIGluIHByb2dyZXNz
LgoKDgoHBAIEAAICARIDUwQPCg4KBwQCBAACAgISA1MSEwotCgYEAgQAAgMSA1YEDRoeIFN0
ZXAgZXhlY3V0aW9uIGlzIGNvbXBsZXRlZC4KCg4KBwQCBAACAwESA1YECAoOCgcEAgQAAgMC
EgNWCwwKJwoEBAIIABIFWgLXAQMaGCBTdGVwIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAggA
ARIDWggMCmMKBAQCAgASBF0EXjQaVSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMg
dGhhdCBuZXcgbmV0d29yayBjcmVhdGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoK
DAoFBAICAAYSA10EEQoMCgUEAgIAARIDXRIgCgwKBQQCAgADEgNdIyQKDAoFBAICAAgSA14I
MwoPCggEAgIACJwIABIDXgkyCnIKBAQCAgESBGIEYzQaZCBPdXRwdXQgb25seS4gSWYgc2V0
LCBpbmRpY2F0ZXMgdGhhdCBuZXcgcHJpdmF0ZSBzZXJ2aWNlIGFjY2VzcyBjcmVhdGlvbgog
aXMgcGFydCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAICAQYSA2IEHgoMCgUEAgIBARIDYh88
CgwKBQQCAgEDEgNiP0AKDAoFBAICAQgSA2MIMwoPCggEAgIBCJwIABIDYwkyCm4KBAQCAgIS
BGcEaDQaYCBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBuZXcgRmlsZXN0
b3JlIGluc3RhbmNlIGNyZWF0aW9uIGlzCiBwYXJ0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUE
AgICBhIDZwQbCgwKBQQCAgIBEgNnHDUKDAoFBAICAgMSA2c4OQoMCgUEAgICCBIDaAgzCg8K
CAQCAgIInAgAEgNoCTIKcAoEBAICAxIEbARtNBpiIE91dHB1dCBvbmx5LiBJZiBzZXQsIGlu
ZGljYXRlcyB0aGF0IG5ldyBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBjcmVhdGlvbiBpcwogcGFy
dCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAICAwYSA2wEFwoMCgUEAgIDARIDbBgtCgwKBQQC
AgMDEgNsMDEKDAoFBAICAwgSA20IMwoPCggEAgIDCJwIABIDbQkyCmsKBAQCAgQSBHEEcjQa
XSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBuZXcgTHVzdHJlIGluc3Rh
bmNlIGNyZWF0aW9uIGlzIHBhcnQKIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAgIEBhIDcQQY
CgwKBQQCAgQBEgNxGS8KDAoFBAICBAMSA3EyMwoMCgUEAgIECBIDcggzCg8KCAQCAgQInAgA
EgNyCTIKZwoEBAICBRIEdgR3NBpZIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0
aGF0IG5ldyBHS0UgY2x1c3RlciBjcmVhdGlvbiBpcyBwYXJ0IG9mCiB0aGUgb3BlcmF0aW9u
LgoKDAoFBAICBQYSA3YEFAoMCgUEAgIFARIDdhUnCgwKBQQCAgUDEgN2KisKDAoFBAICBQgS
A3cIMwoPCggEAgIFCJwIABIDdwkyCmQKBAQCAgYSBHsEfDQaViBPdXRwdXQgb25seS4gSWYg
c2V0LCBpbmRpY2F0ZXMgdGhhdCBvcmNoZXN0cmF0b3IgY3JlYXRpb24gaXMgcGFydCBvZiB0
aGUKIG9wZXJhdGlvbi4KCgwKBQQCAgYGEgN7BBYKDAoFBAICBgESA3sXKgoMCgUEAgIGAxID
ey0uCgwKBQQCAgYIEgN8CDMKDwoIBAICBgicCAASA3wJMgplCgQEAgIHEgaAAQSBATQaVSBP
dXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBuZXcgbm9kZXNldCBjcmVhdGlv
biBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICBwYSBIABBBEKDQoFBAICBwES
BIABEiAKDQoFBAICBwMSBIABIyQKDQoFBAICBwgSBIEBCDMKEAoIBAICBwicCAASBIEBCTIK
ZwoEBAICCBIGhQEEhgE0GlcgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQg
bmV3IHBhcnRpdGlvbiBjcmVhdGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoF
BAICCAYSBIUBBBMKDQoFBAICCAESBIUBFCQKDQoFBAICCAMSBIUBJykKDQoFBAICCAgSBIYB
CDMKEAoIBAICCAicCAASBIYBCTIKaAoEBAICCRIGigEEiwE0GlggT3V0cHV0IG9ubHkuIElm
IHNldCwgaW5kaWNhdGVzIHRoYXQgbmV3IGxvZ2luIG5vZGUgY3JlYXRpb24gaXMgcGFydCBv
ZgogdGhlIG9wZXJhdGlvbi4KCg0KBQQCAgkGEgSKAQQTCg0KBQQCAgkBEgSKARQlCg0KBQQC
AgkDEgSKASgqCg0KBQQCAgkIEgSLAQgzChAKCAQCAgkInAgAEgSLAQkyCmUKBAQCAgoSBo8B
BJABNBpVIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IGNsdXN0ZXIgaGVh
bHRoIGNoZWNrIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoNCgUEAgIKBhIEjwEEFgoN
CgUEAgIKARIEjwEXKwoNCgUEAgIKAxIEjwEuMAoNCgUEAgIKCBIEkAEIMwoQCggEAgIKCJwI
ABIEkAEJMgpnCgQEAgILEgaUAQSVATQaVyBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0
ZXMgdGhhdCBhbiBvcmNoZXN0cmF0b3IgdXBkYXRlIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRp
b24uCgoNCgUEAgILBhIElAEEFgoNCgUEAgILARIElAEXKgoNCgUEAgILAxIElAEtLwoNCgUE
AgILCBIElQEIMwoQCggEAgILCJwIABIElQEJMgpfCgQEAgIMEgaZAQSaATQaTyBPdXRwdXQg
b25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBub2Rlc2V0IHVwZGF0ZSBpcyBwYXJ0IG9m
IHRoZQogb3BlcmF0aW9uLgoKDQoFBAICDAYSBJkBBBEKDQoFBAICDAESBJkBEiAKDQoFBAIC
DAMSBJkBIyUKDQoFBAICDAgSBJoBCDMKEAoIBAICDAicCAASBJoBCTIKYQoEBAICDRIGngEE
nwE0GlEgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgcGFydGl0aW9uIHVw
ZGF0ZSBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICDQYSBJ4BBBMKDQoFBAIC
DQESBJ4BFCQKDQoFBAICDQMSBJ4BJykKDQoFBAICDQgSBJ8BCDMKEAoIBAICDQicCAASBJ8B
CTIKYgoEBAICDhIGowEEpAE0GlIgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRo
YXQgbG9naW4gbm9kZSB1cGRhdGUgaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQC
Ag4GEgSjAQQTCg0KBQQCAg4BEgSjARQlCg0KBQQCAg4DEgSjASgqCg0KBQQCAg4IEgSkAQgz
ChAKCAQCAg4InAgAEgSkAQkyCmUKBAQCAg8SBqgBBKkBNBpVIE91dHB1dCBvbmx5LiBJZiBz
ZXQsIGluZGljYXRlcyB0aGF0IEdLRSBjbHVzdGVyIGRlbGV0aW9uIGlzIHBhcnQgb2YgdGhl
CiBvcGVyYXRpb24uCgoNCgUEAgIPBhIEqAEEFAoNCgUEAgIPARIEqAEVJwoNCgUEAgIPAxIE
qAEqLAoNCgUEAgIPCBIEqQEIMwoQCggEAgIPCJwIABIEqQEJMgpmCgQEAgIQEgatAQSuATQa
ViBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBvcmNoZXN0cmF0b3IgZGVs
ZXRpb24gaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQCAhAGEgStAQQWCg0KBQQC
AhABEgStARcqCg0KBQQCAhADEgStAS0vCg0KBQQCAhAIEgSuAQgzChAKCAQCAhAInAgAEgSu
AQkyCmEKBAQCAhESBrIBBLMBNBpRIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0
aGF0IG5vZGVzZXQgZGVsZXRpb24gaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQC
AhEGEgSyAQQRCg0KBQQCAhEBEgSyARIgCg0KBQQCAhEDEgSyASMlCg0KBQQCAhEIEgSzAQgz
ChAKCAQCAhEInAgAEgSzAQkyCmMKBAQCAhISBrcBBLgBNBpTIE91dHB1dCBvbmx5LiBJZiBz
ZXQsIGluZGljYXRlcyB0aGF0IHBhcnRpdGlvbiBkZWxldGlvbiBpcyBwYXJ0IG9mIHRoZQog
b3BlcmF0aW9uLgoKDQoFBAICEgYSBLcBBBMKDQoFBAICEgESBLcBFCQKDQoFBAICEgMSBLcB
JykKDQoFBAICEggSBLgBCDMKEAoIBAICEgicCAASBLgBCTIKZAoEBAICExIGvAEEvQE0GlQg
T3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbG9naW4gbm9kZSBkZWxldGlv
biBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICEwYSBLwBBBMKDQoFBAICEwES
BLwBFCUKDQoFBAICEwMSBLwBKCoKDQoFBAICEwgSBL0BCDMKEAoIBAICEwicCAASBL0BCTIK
bAoEBAICFBIGwQEEwgE0GlwgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQg
RmlsZXN0b3JlIGluc3RhbmNlIGRlbGV0aW9uIGlzIHBhcnQKIG9mIHRoZSBvcGVyYXRpb24u
CgoNCgUEAgIUBhIEwQEEGwoNCgUEAgIUARIEwQEcNQoNCgUEAgIUAxIEwQE4OgoNCgUEAgIU
CBIEwgEIMwoQCggEAgIUCJwIABIEwgEJMgpuCgQEAgIVEgbGAQTHATQaXiBPdXRwdXQgb25s
eS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBkZWxldGlv
biBpcyBwYXJ0CiBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAICFQYSBMYBBBcKDQoFBAICFQES
BMYBGC0KDQoFBAICFQMSBMYBMDIKDQoFBAICFQgSBMcBCDMKEAoIBAICFQicCAASBMcBCTIK
aQoEBAICFhIGywEEzAE0GlkgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQg
THVzdHJlIGluc3RhbmNlIGRlbGV0aW9uIGlzIHBhcnQgb2YKIHRoZSBvcGVyYXRpb24uCgoN
CgUEAgIWBhIEywEEGAoNCgUEAgIWARIEywEZLwoNCgUEAgIWAxIEywEyNAoNCgUEAgIWCBIE
zAEIMwoQCggEAgIWCJwIABIEzAEJMgpwCgQEAgIXEgbQAQTRATQaYCBPdXRwdXQgb25seS4g
SWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBwcml2YXRlIHNlcnZpY2UgYWNjZXNzIGRlbGV0aW9u
IGlzCiBwYXJ0IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEAgIXBhIE0AEEHgoNCgUEAgIXARIE
0AEfPAoNCgUEAgIXAxIE0AE/QQoNCgUEAgIXCBIE0QEIMwoQCggEAgIXCJwIABIE0QEJMgph
CgQEAgIYEgbVAQTWATQaUSBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBu
ZXR3b3JrIGRlbGV0aW9uIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoNCgUEAgIYBhIE
1QEEEQoNCgUEAgIYARIE1QESIAoNCgUEAgIYAxIE1QEjJQoNCgUEAgIYCBIE1gEIMwoQCggE
AgIYCJwIABIE1gEJMgo5CgQEAgIZEgTaAQI+GisgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRo
ZSBvcGVyYXRpb24gc3RlcC4KCg0KBQQCAhkGEgTaAQIHCg0KBQQCAhkBEgTaAQgNCg0KBQQC
AhkDEgTaARARCg0KBQQCAhkIEgTaARI9ChAKCAQCAhkInAgAEgTaARM8CloKAgQDEgbeAQDl
AQEaTCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIG5ldyBu
ZXR3b3JrIHNob3VsZCBiZSBjcmVhdGVkLgoKCwoDBAMBEgTeAQgVCnwKBAQDAgASBuEBAuQB
BBpsIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBuZXR3b3JrIHRvIGNyZWF0ZSwgaW4gdGhl
IGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9nbG9iYWwvbmV0d29ya3Mve25ldHdvcmt9
YC4KCg0KBQQDAgAFEgThAQIICg0KBQQDAgABEgThAQkQCg0KBQQDAgADEgThARMUCg8KBQQD
AgAIEgbhARXkAQMKEAoIBAMCAAicCAASBOIBBC0KDwoHBAMCAAifCBIE4wEEUApoCgIEBBIE
6QEAJRpcIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbmV3
IHByaXZhdGUgc2VydmljZSBhY2Nlc3Mgc2hvdWxkCiBiZSBjcmVhdGVkLgoKCwoDBAQBEgTp
AQgiCmYKAgQFEgbtAQD2AQEaWCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0
ZXMgdGhhdCBhIG5ldyBmaWxlc3RvcmUgaW5zdGFuY2Ugc2hvdWxkIGJlCiBjcmVhdGVkLgoK
CwoDBAUBEgTtAQgfCowBCgQEBQIAEgbwAQL1AQQafCBPdXRwdXQgb25seS4gTmFtZSBvZiB0
aGUgRmlsZXN0b3JlIGluc3RhbmNlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBAUC
AAUSBPABAggKDQoFBAUCAAESBPABCRIKDQoFBAUCAAMSBPABFRYKDwoFBAUCAAgSBvABF/UB
AwoQCggEBQIACJwIABIE8QEELQoRCgcEBQIACJ8IEgbyAQT0AQUKYgoCBAYSBvoBAIACARpU
IFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbmV3IHN0b3Jh
Z2UgYnVja2V0IHNob3VsZCBiZQogY3JlYXRlZC4KCgsKAwQGARIE+gEIGwoyCgQEBgIAEgb8
AQL/AQQaIiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgYnVja2V0LgoKDQoFBAYCAAUSBPwB
AggKDQoFBAYCAAESBPwBCQ8KDQoFBAYCAAMSBPwBEhMKDwoFBAYCAAgSBvwBFP8BAwoQCggE
BgIACJwIABIE/QEELQoPCgcEBgIACJ8IEgT+AQRPCmMKAgQHEgaEAgCLAgEaVSBXaGVuIHNl
dCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIG5ldyBsdXN0cmUgaW5zdGFu
Y2Ugc2hvdWxkIGJlCiBjcmVhdGVkLgoKCwoDBAcBEgSEAggcCpIBCgQEBwIAEgaHAgKKAgQa
gQEgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIE1hbmFnZWQgTHVzdHJlIGluc3RhbmNlLCBp
biB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBAcCAAUSBIcCAggKDQoFBAcCAAESBIcCCQ8K
DQoFBAcCAAMSBIcCEhMKDwoFBAcCAAgSBocCFIoCAwoQCggEBwIACJwIABIEiAIELQoPCgcE
BwIACJ8IEgSJAgRQCl8KAgQIEgaPAgCSAgEaUSBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVw
LCBpbmRpY2F0ZXMgdGhhdCBhIG5ldyBHS0UgY2x1c3RlciBzaG91bGQgYmUKIGNyZWF0ZWQu
CgoLCgMECAESBI8CCBgKNQoEBAgCABIEkQICQRonIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRo
ZSBHS0UgY2x1c3Rlci4KCg0KBQQIAgAFEgSRAgIICg0KBQQIAgABEgSRAgkQCg0KBQQIAgAD
EgSRAhMUCg0KBQQIAgAIEgSRAhVAChAKCAQIAgAInAgAEgSRAhY/CloKAgQJEgSVAgAdGk4g
V2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYW4gb3JjaGVzdHJh
dG9yIHNob3VsZCBiZSBjcmVhdGVkLgoKCwoDBAkBEgSVAggaClYKAgQKEgaYAgCbAgEaSCBX
aGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIG5vZGVzZXQgc2hv
dWxkIGJlIGNyZWF0ZWQuCgoLCgMECgESBJgCCBUKOgoEBAoCABIEmgICSxosIE91dHB1dCBv
bmx5LiBOYW1lIG9mIHRoZSBub2Rlc2V0IHRvIGNyZWF0ZQoKDQoFBAoCAAQSBJoCAgoKDQoF
BAoCAAUSBJoCCxEKDQoFBAoCAAESBJoCEhoKDQoFBAoCAAMSBJoCHR4KDQoFBAoCAAgSBJoC
H0oKEAoIBAoCAAicCAASBJoCIEkKWAoCBAsSBp4CAKECARpKIFdoZW4gc2V0IGluIE9wZXJh
dGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgcGFydGl0aW9uIHNob3VsZCBiZSBjcmVhdGVk
LgoKCwoDBAsBEgSeAggXCjwKBAQLAgASBKACAk0aLiBPdXRwdXQgb25seS4gTmFtZSBvZiB0
aGUgcGFydGl0aW9uIHRvIGNyZWF0ZQoKDQoFBAsCAAQSBKACAgoKDQoFBAsCAAUSBKACCxEK
DQoFBAsCAAESBKACEhwKDQoFBAsCAAMSBKACHyAKDQoFBAsCAAgSBKACIUwKEAoIBAsCAAic
CAASBKACIksKVwoCBAwSBKQCABoaSyBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRp
Y2F0ZXMgdGhhdCBhIGxvZ2luIG5vZGUgc2hvdWxkIGJlIGNyZWF0ZWQuCgoLCgMEDAESBKQC
CBcKYgoCBA0SBKgCAB0aViBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMg
dGhhdCBjbHVzdGVyIGhlYWx0aCBjaGVjayBzaG91bGQgYmUKIHBlcmZvcm1lZC4KCgsKAwQN
ARIEqAIIGgpaCgIEDhIEqwIAHRpOIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGlj
YXRlcyB0aGF0IGFuIG9yY2hlc3RyYXRvciBzaG91bGQgYmUgdXBkYXRlZC4KCgsKAwQOARIE
qwIIGgpWCgIEDxIGrgIAsQIBGkggV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNh
dGVzIHRoYXQgYSBub2Rlc2V0IHNob3VsZCBiZSB1cGRhdGVkLgoKCwoDBA8BEgSuAggVCjoK
BAQPAgASBLACAksaLCBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgbm9kZXNldCB0byB1cGRh
dGUKCg0KBQQPAgAEEgSwAgIKCg0KBQQPAgAFEgSwAgsRCg0KBQQPAgABEgSwAhIaCg0KBQQP
AgADEgSwAh0eCg0KBQQPAgAIEgSwAh9KChAKCAQPAgAInAgAEgSwAiBJClgKAgQQEga0AgC3
AgEaSiBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIHBhcnRp
dGlvbiBzaG91bGQgYmUgdXBkYXRlZC4KCgsKAwQQARIEtAIIFwo8CgQEEAIAEgS2AgJNGi4g
T3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHBhcnRpdGlvbiB0byB1cGRhdGUKCg0KBQQQAgAE
EgS2AgIKCg0KBQQQAgAFEgS2AgsRCg0KBQQQAgABEgS2AhIcCg0KBQQQAgADEgS2Ah8gCg0K
BQQQAgAIEgS2AiFMChAKCAQQAgAInAgAEgS2AiJLClcKAgQREgS6AgAaGksgV2hlbiBzZXQg
aW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBsb2dpbiBub2RlIHNob3VsZCBi
ZSB1cGRhdGVkLgoKCwoDBBEBEgS6AggXClsKAgQSEga+AgDBAgEaTSBXaGVuIHNldCBpbiBP
cGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIEdLRSBjbHVzdGVyIHNob3VsZCBiZQog
ZGVsZXRlZC4KCgsKAwQSARIEvgIIGAo1CgQEEgIAEgTAAgJBGicgT3V0cHV0IG9ubHkuIE5h
bWUgb2YgdGhlIEdLRSBjbHVzdGVyLgoKDQoFBBICAAUSBMACAggKDQoFBBICAAESBMACCRAK
DQoFBBICAAMSBMACExQKDQoFBBICAAgSBMACFUAKEAoIBBICAAicCAASBMACFj8KWgoCBBMS
BMQCAB0aTiBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhbiBv
cmNoZXN0cmF0b3Igc2hvdWxkIGJlIGRlbGV0ZWQuCgoLCgMEEwESBMQCCBoKVgoCBBQSBscC
AMoCARpIIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbm9k
ZXNldCBzaG91bGQgYmUgZGVsZXRlZC4KCgsKAwQUARIExwIIFQo6CgQEFAIAEgTJAgJLGiwg
T3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIG5vZGVzZXQgdG8gZGVsZXRlCgoNCgUEFAIABBIE
yQICCgoNCgUEFAIABRIEyQILEQoNCgUEFAIAARIEyQISGgoNCgUEFAIAAxIEyQIdHgoNCgUE
FAIACBIEyQIfSgoQCggEFAIACJwIABIEyQIgSQpYCgIEFRIGzQIA0AIBGkogV2hlbiBzZXQg
aW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBwYXJ0aXRpb24gc2hvdWxkIGJl
IGRlbGV0ZWQuCgoLCgMEFQESBM0CCBcKPAoEBBUCABIEzwICTRouIE91dHB1dCBvbmx5LiBO
YW1lIG9mIHRoZSBwYXJ0aXRpb24gdG8gZGVsZXRlCgoNCgUEFQIABBIEzwICCgoNCgUEFQIA
BRIEzwILEQoNCgUEFQIAARIEzwISHAoNCgUEFQIAAxIEzwIfIAoNCgUEFQIACBIEzwIhTAoQ
CggEFQIACJwIABIEzwIiSwpXCgIEFhIE0wIAGhpLIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0
ZXAsIGluZGljYXRlcyB0aGF0IGEgbG9naW4gbm9kZSBzaG91bGQgYmUgZGVsZXRlZC4KCgsK
AwQWARIE0wIIFwpiCgIEFxIG1wIA4AIBGlQgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwg
aW5kaWNhdGVzIHRoYXQgYSBGaWxlc3RvcmUgaW5zdGFuY2Ugc2hvdWxkIGJlCiBkZWxldGVk
LgoKCwoDBBcBEgTXAggfCowBCgQEFwIAEgbaAgLfAgQafCBPdXRwdXQgb25seS4gTmFtZSBv
ZiB0aGUgRmlsZXN0b3JlIGluc3RhbmNlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoF
BBcCAAUSBNoCAggKDQoFBBcCAAESBNoCCRIKDQoFBBcCAAMSBNoCFRYKDwoFBBcCAAgSBtoC
F98CAwoQCggEFwIACJwIABIE2wIELQoRCgcEFwIACJ8IEgbcAgTeAgUKYgoCBBgSBuQCAOoC
ARpUIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IENsb3VkIFN0
b3JhZ2UgYnVja2V0IHNob3VsZCBiZQogZGVsZXRlZC4KCgsKAwQYARIE5AIIGwoyCgQEGAIA
EgbmAgLpAgQaIiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgYnVja2V0LgoKDQoFBBgCAAUS
BOYCAggKDQoFBBgCAAESBOYCCQ8KDQoFBBgCAAMSBOYCEhMKDwoFBBgCAAgSBuYCFOkCAwoQ
CggEGAIACJwIABIE5wIELQoPCgcEGAIACJ8IEgToAgRPCl8KAgQZEgbuAgD1AgEaUSBXaGVu
IHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIEx1c3RyZSBpbnN0YW5j
ZSBzaG91bGQgYmUKIGRlbGV0ZWQuCgoLCgMEGQESBO4CCBwKkgEKBAQZAgASBvECAvQCBBqB
ASBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgTWFuYWdlZCBMdXN0cmUgaW5zdGFuY2UsIGlu
IHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aW5zdGFuY2VzL3tpbnN0YW5jZX1gCgoNCgUEGQIABRIE8QICCAoNCgUEGQIAARIE8QIJDwoN
CgUEGQIAAxIE8QISEwoPCgUEGQIACBIG8QIU9AIDChAKCAQZAgAInAgAEgTyAgQtCg8KBwQZ
AgAInwgSBPMCBFAKWQoCBBoSBPkCACUaTSBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBp
bmRpY2F0ZXMgcHJpdmF0ZSBzZXJ2aWNlIGFjY2VzcyBkZWxldGlvbgogc3RlcC4KCgsKAwQa
ARIE+QIIIgpjCgIEGxIG/QIAhAMBGlUgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5k
aWNhdGVzIG5ldHdvcmsgZGVsZXRpb24gc3RlcCB3aXRoIHRoZQogcmVzb3VyY2UgbmFtZS4K
CgsKAwQbARIE/QIIFQp8CgQEGwIAEgaAAwKDAwQabCBPdXRwdXQgb25seS4gTmFtZSBvZiB0
aGUgbmV0d29yayB0byBkZWxldGUsIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVj
dH0vZ2xvYmFsL25ldHdvcmtzL3tuZXR3b3JrfWAuCgoNCgUEGwIABRIEgAMCCAoNCgUEGwIA
ARIEgAMJEAoNCgUEGwIAAxIEgAMTFAoPCgUEGwIACBIGgAMVgwMDChAKCAQbAgAInAgAEgSB
AwQtCg8KBwQbAgAInwgSBIIDBFBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: progress Type: 11 (.google.cloud.hypercomputecluster.v1alpha.OperationProgress)

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationProgress ===
    # Fields for OperationProgress
    # Field: steps Type: 11 (.google.cloud.hypercomputecluster.v1alpha.OperationStep)

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationStep ===
    # Fields for OperationStep
    # Field: create_network Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateNetwork)
    # Field: create_private_service_access Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreatePrivateServiceAccess)
    # Field: create_filestore_instance Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateFilestoreInstance)
    # Field: create_storage_bucket Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateStorageBucket)
    # Field: create_lustre_instance Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateLustreInstance)
    # Field: create_gke_cluster Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateGKECluster)
    # Field: create_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateOrchestrator)
    # Field: create_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateNodeset)
    # Field: create_partition Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreatePartition)
    # Field: create_login_node Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CreateLoginNode)
    # Field: check_cluster_health Type: 11 (.google.cloud.hypercomputecluster.v1alpha.CheckClusterHealth)
    # Field: update_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1alpha.UpdateOrchestrator)
    # Field: update_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1alpha.UpdateNodeset)
    # Field: update_partition Type: 11 (.google.cloud.hypercomputecluster.v1alpha.UpdatePartition)
    # Field: update_login_node Type: 11 (.google.cloud.hypercomputecluster.v1alpha.UpdateLoginNode)
    # Field: delete_gke_cluster Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteGKECluster)
    # Field: delete_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteOrchestrator)
    # Field: delete_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteNodeset)
    # Field: delete_partition Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeletePartition)
    # Field: delete_login_node Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteLoginNode)
    # Field: delete_filestore_instance Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteFilestoreInstance)
    # Field: delete_storage_bucket Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteStorageBucket)
    # Field: delete_lustre_instance Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteLustreInstance)
    # Field: delete_private_service_access Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeletePrivateServiceAccess)
    # Field: delete_network Type: 11 (.google.cloud.hypercomputecluster.v1alpha.DeleteNetwork)
    # Field: state Type: 14 (.google.cloud.hypercomputecluster.v1alpha.OperationStep.State)

# Enum: OperationStep::State
our $OperationStep_STATE_UNSPECIFIED = 0;
our $OperationStep_WAITING = 1;
our $OperationStep_IN_PROGRESS = 2;
our $OperationStep_DONE = 3;

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateNetwork ===
    # Fields for CreateNetwork
    # Field: network Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreatePrivateServiceAccess ===
    # Fields for CreatePrivateServiceAccess

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateFilestoreInstance ===
    # Fields for CreateFilestoreInstance
    # Field: filestore Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateStorageBucket ===
    # Fields for CreateStorageBucket
    # Field: bucket Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateLustreInstance ===
    # Fields for CreateLustreInstance
    # Field: lustre Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateGKECluster ===
    # Fields for CreateGKECluster
    # Field: cluster Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateOrchestrator ===
    # Fields for CreateOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateNodeset ===
    # Fields for CreateNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreatePartition ===
    # Fields for CreatePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateLoginNode ===
    # Fields for CreateLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CheckClusterHealth ===
    # Fields for CheckClusterHealth

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateOrchestrator ===
    # Fields for UpdateOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateNodeset ===
    # Fields for UpdateNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdatePartition ===
    # Fields for UpdatePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateLoginNode ===
    # Fields for UpdateLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteGKECluster ===
    # Fields for DeleteGKECluster
    # Field: cluster Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteOrchestrator ===
    # Fields for DeleteOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteNodeset ===
    # Fields for DeleteNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeletePartition ===
    # Fields for DeletePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteLoginNode ===
    # Fields for DeleteLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteFilestoreInstance ===
    # Fields for DeleteFilestoreInstance
    # Field: filestore Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteStorageBucket ===
    # Fields for DeleteStorageBucket
    # Field: bucket Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteLustreInstance ===
    # Fields for DeleteLustreInstance
    # Field: lustre Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeletePrivateServiceAccess ===
    # Fields for DeletePrivateServiceAccess

# === Message: Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteNetwork ===
    # Fields for DeleteNetwork
    # Field: network Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata - Compiled Protocol Buffers messages for google/cloud/hypercomputecluster/v1alpha/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata;

    my $msg = Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/hypercomputecluster/v1alpha/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationMetadata

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

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationProgress>)

Output only. Progress of the operation.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationProgress

Message describing the progress of a cluster mutation long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->steps() >> / C<< $msg->steps($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationStep>)

Output only. Steps and status of the operation.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::OperationStep

Message describing the status of a single step in a cluster mutation
long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_network() >> / C<< $msg->create_network($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateNetwork>)

Output only. If set, indicates that new network creation is part of the
operation.

=item * C<< $msg->create_private_service_access() >> / C<< $msg->create_private_service_access($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreatePrivateServiceAccess>)

Output only. If set, indicates that new private service access creation
is part of the operation.

=item * C<< $msg->create_filestore_instance() >> / C<< $msg->create_filestore_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateFilestoreInstance>)

Output only. If set, indicates that new Filestore instance creation is
part of the operation.

=item * C<< $msg->create_storage_bucket() >> / C<< $msg->create_storage_bucket($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateStorageBucket>)

Output only. If set, indicates that new Cloud Storage bucket creation is
part of the operation.

=item * C<< $msg->create_lustre_instance() >> / C<< $msg->create_lustre_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateLustreInstance>)

Output only. If set, indicates that new Lustre instance creation is part
of the operation.

=item * C<< $msg->create_gke_cluster() >> / C<< $msg->create_gke_cluster($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateGKECluster>)

Output only. If set, indicates that new GKE cluster creation is part of
the operation.

=item * C<< $msg->create_orchestrator() >> / C<< $msg->create_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateOrchestrator>)

Output only. If set, indicates that orchestrator creation is part of the
operation.

=item * C<< $msg->create_nodeset() >> / C<< $msg->create_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateNodeset>)

Output only. If set, indicates that new nodeset creation is part of the
operation.

=item * C<< $msg->create_partition() >> / C<< $msg->create_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreatePartition>)

Output only. If set, indicates that new partition creation is part of the
operation.

=item * C<< $msg->create_login_node() >> / C<< $msg->create_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateLoginNode>)

Output only. If set, indicates that new login node creation is part of
the operation.

=item * C<< $msg->check_cluster_health() >> / C<< $msg->check_cluster_health($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CheckClusterHealth>)

Output only. If set, indicates that cluster health check is part of the
operation.

=item * C<< $msg->update_orchestrator() >> / C<< $msg->update_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateOrchestrator>)

Output only. If set, indicates that an orchestrator update is part of the
operation.

=item * C<< $msg->update_nodeset() >> / C<< $msg->update_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateNodeset>)

Output only. If set, indicates that nodeset update is part of the
operation.

=item * C<< $msg->update_partition() >> / C<< $msg->update_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdatePartition>)

Output only. If set, indicates that partition update is part of the
operation.

=item * C<< $msg->update_login_node() >> / C<< $msg->update_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateLoginNode>)

Output only. If set, indicates that login node update is part of the
operation.

=item * C<< $msg->delete_gke_cluster() >> / C<< $msg->delete_gke_cluster($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteGKECluster>)

Output only. If set, indicates that GKE cluster deletion is part of the
operation.

=item * C<< $msg->delete_orchestrator() >> / C<< $msg->delete_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteOrchestrator>)

Output only. If set, indicates that orchestrator deletion is part of the
operation.

=item * C<< $msg->delete_nodeset() >> / C<< $msg->delete_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteNodeset>)

Output only. If set, indicates that nodeset deletion is part of the
operation.

=item * C<< $msg->delete_partition() >> / C<< $msg->delete_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeletePartition>)

Output only. If set, indicates that partition deletion is part of the
operation.

=item * C<< $msg->delete_login_node() >> / C<< $msg->delete_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteLoginNode>)

Output only. If set, indicates that login node deletion is part of the
operation.

=item * C<< $msg->delete_filestore_instance() >> / C<< $msg->delete_filestore_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteFilestoreInstance>)

Output only. If set, indicates that Filestore instance deletion is part
of the operation.

=item * C<< $msg->delete_storage_bucket() >> / C<< $msg->delete_storage_bucket($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteStorageBucket>)

Output only. If set, indicates that Cloud Storage bucket deletion is part
of the operation.

=item * C<< $msg->delete_lustre_instance() >> / C<< $msg->delete_lustre_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteLustreInstance>)

Output only. If set, indicates that Lustre instance deletion is part of
the operation.

=item * C<< $msg->delete_private_service_access() >> / C<< $msg->delete_private_service_access($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeletePrivateServiceAccess>)

Output only. If set, indicates that private service access deletion is
part of the operation.

=item * C<< $msg->delete_network() >> / C<< $msg->delete_network($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteNetwork>)

Output only. If set, indicates that network deletion is part of the
operation.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Hypercomputecluster::V1alpha::OperationStep::State>)

Output only. State of the operation step.

=back

=head3 Enum: OperationStep::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<WAITING> => C<1>

=item * C<IN_PROGRESS> => C<2>

=item * C<DONE> => C<3>

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateNetwork

When set in OperationStep, indicates that a new network should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Output only. Name of the network to create, in the format
`projects/{project}/global/networks/{network}`.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreatePrivateServiceAccess

When set in OperationStep, indicates that a new private service access should
be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateFilestoreInstance

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

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateStorageBucket

When set in OperationStep, indicates that a new storage bucket should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Name of the bucket.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateLustreInstance

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

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateGKECluster

When set in OperationStep, indicates that a new GKE cluster should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

Output only. Name of the GKE cluster.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateOrchestrator

When set in OperationStep, indicates that an orchestrator should be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateNodeset

When set in OperationStep, indicates that a nodeset should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to create

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreatePartition

When set in OperationStep, indicates that a partition should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to create

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CreateLoginNode

When set in OperationStep, indicates that a login node should be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::CheckClusterHealth

When set in OperationStep, indicates that cluster health check should be
performed.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateOrchestrator

When set in OperationStep, indicates that an orchestrator should be updated.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateNodeset

When set in OperationStep, indicates that a nodeset should be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to update

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdatePartition

When set in OperationStep, indicates that a partition should be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to update

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::UpdateLoginNode

When set in OperationStep, indicates that a login node should be updated.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteGKECluster

When set in OperationStep, indicates that a GKE cluster should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

Output only. Name of the GKE cluster.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteOrchestrator

When set in OperationStep, indicates that an orchestrator should be deleted.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteNodeset

When set in OperationStep, indicates that a nodeset should be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to delete

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeletePartition

When set in OperationStep, indicates that a partition should be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to delete

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteLoginNode

When set in OperationStep, indicates that a login node should be deleted.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteFilestoreInstance

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

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteStorageBucket

When set in OperationStep, indicates that Cloud Storage bucket should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Name of the bucket.

=back

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteLustreInstance

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

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeletePrivateServiceAccess

When set in OperationStep, indicates private service access deletion
step.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::DeleteNetwork

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Hypercomputecluster::V1alpha::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
