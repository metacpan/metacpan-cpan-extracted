package Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2F1dG9wcm90ZWN0aW9ucG9saWN5Ymlu
ZGluZy5wcm90bxIcZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IqgGChtBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmcSGgoEbmFtZRgBIAEoCUIG4EED4EEI
UgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEloKBXN0YXRl
GAMgASgOMj8uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5BdXRvUHJvdGVjdGlvblBv
bGljeUJpbmRpbmcuU3RhdGVCA+BBA1IFc3RhdGUSIgoFc2NvcGUYBCABKAlCDOBBAuBBBfpB
AwoBKlIFc2NvcGUSeQoaYmluZGluZ19ldmFsdWF0aW9uX3N1bW1hcnkYBSABKAsyNi5nb29n
bGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkJpbmRpbmdFdmFsdWF0aW9uU3VtbWFyeUID4EED
UhhiaW5kaW5nRXZhbHVhdGlvblN1bW1hcnkSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUY
ByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSEgoE
ZXRhZxgIIAEoCVIEZXRhZyJQCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENS
RUFUSU5HEAESCgoGQUNUSVZFEAISFgoSREVMRVRJT05fSU5JVElBVEVEEAM64AHqQdwBCjNi
YWNrdXBkci5nb29nbGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmcSanBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRvUHJvdGVjdGlvblBv
bGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9saWN5fS9iaW5kaW5ncy97YmluZGluZ30qHGF1
dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZ3MyG2F1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGlu
ZyLPAQoYQmluZGluZ0V2YWx1YXRpb25TdW1tYXJ5EjsKF21hdGNoaW5nX3Jlc291cmNlX2Nv
dW50GAEgASgDQgPgQQNSFW1hdGNoaW5nUmVzb3VyY2VDb3VudBI9Chhwcm90ZWN0ZWRfcmVz
b3VyY2VfY291bnQYAiABKANCA+BBA1IWcHJvdGVjdGVkUmVzb3VyY2VDb3VudBI3ChVmYWls
ZWRfcmVzb3VyY2VfY291bnQYAyABKANCA+BBA1ITZmFpbGVkUmVzb3VyY2VDb3VudCL5Agoo
Q3JlYXRlQXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nUmVxdWVzdBJMCgZwYXJlbnQYASAB
KAlCNOBBAvpBLgosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0b1Byb3RlY3Rpb25Qb2xp
Y3lSBnBhcmVudBJNCiFhdXRvX3Byb3RlY3Rpb25fcG9saWN5X2JpbmRpbmdfaWQYAiABKAlC
A+BBAlIdYXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nSWQSgwEKHmF1dG9fcHJvdGVjdGlv
bl9wb2xpY3lfYmluZGluZxgDIAEoCzI5Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEu
QXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nQgPgQQJSG2F1dG9Qcm90ZWN0aW9uUG9saWN5
QmluZGluZxIqCgpyZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkIngK
JUdldEF1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZ1JlcXVlc3QSTwoEbmFtZRgBIAEoCUI7
4EEC+kE1CjNiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeUJp
bmRpbmdSBG5hbWUi+gEKJ0xpc3RBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdzUmVxdWVz
dBJMCgZwYXJlbnQYASABKAlCNOBBAvpBLgosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0
b1Byb3RlY3Rpb25Qb2xpY3lSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFn
ZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQg
ASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IvwBCihM
aXN0QXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nc1Jlc3BvbnNlEoABCh9hdXRvX3Byb3Rl
Y3Rpb25fcG9saWN5X2JpbmRpbmdzGAEgAygLMjkuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYx
YmV0YS5BdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdSHGF1dG9Qcm90ZWN0aW9uUG9saWN5
QmluZGluZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiUKC3Vu
cmVhY2hhYmxlGAMgAygJQgPgQQZSC3VucmVhY2hhYmxlIsgBCjBJbml0aWF0ZURlbGV0ZUF1
dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZ1JlcXVlc3QSTwoEbmFtZRgBIAEoCUI74EEC+kE1
CjNiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdS
BG5hbWUSFwoEZXRhZxgCIAEoCUID4EEBUgRldGFnEioKCnJlcXVlc3RfaWQYAyABKAlCC+KM
z9cIAggB4EEBUglyZXF1ZXN0SWRC5AEKIGNvbS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFi
ZXRhQiBBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmdQcm90b1ABWjxjbG91ZC5nb29nbGUu
Y29tL2dvL2JhY2t1cGRyL2FwaXYxYmV0YS9iYWNrdXBkcnBiO2JhY2t1cGRycGKqAhxHb29n
bGUuQ2xvdWQuQmFja3VwRFIuVjFCZXRhygIcR29vZ2xlXENsb3VkXEJhY2t1cERSXFYxYmV0
YeoCH0dvb2dsZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMWJldGFKhUIKBxIFDgDsAQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAKQoJCgID
ARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKQoICgEIEgMXADkKCQoCCCUSAxcAOQoICgEI
EgMYAFMKCQoCCAsSAxgAUwoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAEEKCQoCCAgS
AxoAQQoICgEIEgMbADkKCQoCCAESAxsAOQoICgEIEgMcADkKCQoCCCkSAxwAOQoICgEIEgMd
ADgKCQoCCC0SAx0AOAq+AQoCBAASBCIAYAEasQEgQW4gQXV0b3Byb3RlY3Rpb25Qb2xpY3lC
aW5kaW5nIChBUFBBKSBhY3RzIGFzIHRoZSBicmlkZ2UgYmV0d2VlbiBhbgogQXV0b3Byb3Rl
Y3Rpb25Qb2xpY3kgYW5kIHRoZSBzY29wZSAoUHJvamVjdCwgRm9sZGVyLCBvciBPcmdhbml6
YXRpb24pIHdoZXJlCiB0aGUgcG9saWN5IHNob3VsZCBiZSBhcHBsaWVkLgoKCgoDBAABEgMi
CCMKCwoDBAAHEgQjAigECg0KBQQAB50IEgQjAigECjwKBAQABAASBCsCNwMaLiBUaGUgc3Rh
dGUgb2YgYW4gQXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nLgoKDAoFBAAEAAESAysHDAo5
CgYEAAQAAgASAy0EGhoqIFRoZSBzdGF0ZSBvZiB0aGUgYmluZGluZyBpcyB1bnNwZWNpZmll
ZC4KCg4KBwQABAACAAESAy0EFQoOCgcEAAQAAgACEgMtGBkKLgoGBAAEAAIBEgMwBBEaHyBU
aGUgYmluZGluZyBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDMAQMCg4KBwQABAAC
AQISAzAPEAonCgYEAAQAAgISAzMEDxoYIFRoZSBiaW5kaW5nIGlzIGFjdGl2ZS4KCg4KBwQA
BAACAgESAzMECgoOCgcEAAQAAgICEgMzDQ4KMwoGBAAEAAIDEgM2BBsaJCBUaGUgYmluZGlu
ZyBkZWxldGlvbiBpcyBpbml0aWF0ZWQuCgoOCgcEAAQAAgMBEgM2BBYKDgoHBAAEAAIDAhID
NhkaCtYBCgQEAAIAEgQ8Aj8EGscBIE91dHB1dCBvbmx5LiBJZGVudGlmaWVyLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUKIEF1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZy4gRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRvUHJvdGVj
dGlvblBvbGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9saWN5fS9iaW5kaW5ncy97YmluZGlu
Z31gCgoMCgUEAAIABRIDPAIICgwKBQQAAgABEgM8CQ0KDAoFBAACAAMSAzwQEQoNCgUEAAIA
CBIEPBI/AwoPCggEAAIACJwIABIDPQQtCg8KCAQAAgAInAgBEgM+BCwKaAoEBAACARIDQwJC
GlsgT3B0aW9uYWwuIEEgZGVzY3JpcHRpb24gb2YgdGhlIGJpbmRpbmcuIFRoZSBkZXNjcmlw
dGlvbiBtdXN0IGJlIGF0IG1vc3QKIDIwNDggY2hhcmFjdGVycy4KCgwKBQQAAgEFEgNDAggK
DAoFBAACAQESA0MJFAoMCgUEAAIBAxIDQxcYCgwKBQQAAgEIEgNDGUEKDwoIBAACAQicCAAS
A0MaQApRCgQEAAICEgNGAj4aRCBPdXRwdXQgb25seS4gVGhlIGN1cnJlbnQgc3RhdGUgb2Yg
dGhlIEF1dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZy4KCgwKBQQAAgIGEgNGAgcKDAoFBAAC
AgESA0YIDQoMCgUEAAICAxIDRhARCgwKBQQAAgIIEgNGEj0KDwoIBAACAgicCAASA0YTPAqE
AQoEBAACAxIESgJOBBp2IFJlcXVpcmVkLiBJbW11dGFibGUuIFJlc291cmNlIElkIG9mIHRh
cmdldCBjb250YWluZXIgb24gd2hpY2ggcG9saWN5IHdpbGwKIGJlIGFwcGxpZWQuIEZvcm1h
dDogcHJvamVjdHMve3Byb2plY3RfaWR9CgoMCgUEAAIDBRIDSgIICgwKBQQAAgMBEgNKCQ4K
DAoFBAACAwMSA0oREgoNCgUEAAIDCBIEShNOAwoPCggEAAIDCJwIABIDSwQqCg8KCAQAAgMI
nAgBEgNMBCsKDgoHBAACAwifCBIDTQQzCqUBCgQEAAIEEgRSAlMyGpYBIE91dHB1dCBvbmx5
LiBTdW1tYXJpZXMgb2YgdGhlIGxhc3QgcG9saWN5IGFwcGxpY2F0aW9uIHdoZW4gdGhlIGpv
YiBoYXMgcnVuLAogd2l0aCBvbmUgZW50cnkgcGVyIHJlc291cmNlIHR5cGUgc3BlY2lmaWVk
IGluIHRoZSBBdXRvUHJvdGVjdGlvblBvbGljeS4KCgwKBQQAAgQGEgNSAhoKDAoFBAACBAES
A1IbNQoMCgUEAAIEAxIDUjg5CgwKBQQAAgQIEgNTBjEKDwoIBAACBAicCAASA1MHMApICgQE
AAIFEgRWAlcyGjogT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgYmluZGlu
ZyB3YXMgY3JlYXRlZC4KCgwKBQQAAgUGEgNWAhsKDAoFBAACBQESA1YcJwoMCgUEAAIFAxID
ViorCgwKBQQAAgUIEgNXBjEKDwoIBAACBQicCAASA1cHMApNCgQEAAIGEgRaAlsyGj8gT3V0
cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgYmluZGluZyB3YXMgbGFzdCB1cGRh
dGVkLgoKDAoFBAACBgYSA1oCGwoMCgUEAAIGARIDWhwnCgwKBQQAAgYDEgNaKisKDAoFBAAC
BggSA1sGMQoPCggEAAIGCJwIABIDWwcwCnYKBAQAAgcSA18CEhppIE91dHB1dCBvbmx5LiBU
aGUgZXRhZyBmb3IgdGhlIGJpbmRpbmcuCiBJZiB0aGlzIGlzIHByb3ZpZGVkIG9uIHVwZGF0
ZSwgaXQgbXVzdCBtYXRjaCB0aGUgc2VydmVyJ3MgZXRhZy4KCgwKBQQAAgcFEgNfAggKDAoF
BAACBwESA18JDQoMCgUEAAIHAxIDXxARCpMBCgIEARIEZABxARqGASBCaW5kaW5nRXZhbHVh
dGlvblN1bW1hcnkgY29udGFpbnMgdGhlIHN1bW1hcnkgb2YgdGhlIGxhc3QgcnVuIG9mIGpv
YgogdGhhdCBhcHBsaWVzIHBvbGljeSB0byBtYXRjaGluZyByZXNvdXJjZXMgZm9yIGEgZ2l2
ZW4gYmluZGluZy4KCgoKAwQBARIDZAggCmAKBAQBAgASA2cCUBpTIE91dHB1dCBvbmx5LiBU
aGUgbnVtYmVyIG9mIHJlc291cmNlcyB0aGF0IGN1cnJlbnRseSBtYXRjaCB0aGUgcG9saWN5
J3MKIGNyaXRlcmlhLgoKDAoFBAECAAUSA2cCBwoMCgUEAQIAARIDZwgfCgwKBQQBAgADEgNn
IiMKDAoFBAECAAgSA2ckTwoPCggEAQIACJwIABIDZyVOCl8KBAQBAgESBGsCbDIaUSBPdXRw
dXQgb25seS4gVGhlIG51bWJlciBvZiBtYXRjaGluZyByZXNvdXJjZXMgdGhhdCBhcmUgc3Vj
Y2Vzc2Z1bGx5CiBwcm90ZWN0ZWQuCgoMCgUEAQIBBRIDawIHCgwKBQQBAgEBEgNrCCAKDAoF
BAECAQMSA2sjJAoMCgUEAQIBCBIDbAYxCg8KCAQBAgEInAgAEgNsBzAKZQoEBAECAhIDcAJO
GlggT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgbWF0Y2hpbmcgcmVzb3VyY2VzIHdob3Nl
IHByb3RlY3Rpb24gZmFpbGVkCiBkdXJpbmcgam9iIHJ1bi4KCgwKBQQBAgIFEgNwAgcKDAoF
BAECAgESA3AIHQoMCgUEAQICAxIDcCAhCgwKBQQBAgIIEgNwIk0KDwoIBAECAgicCAASA3Aj
TApLCgIEAhIFdACWAQEaPiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGNyZWF0aW5nIGFuIEF1dG9Q
cm90ZWN0aW9uUG9saWN5QmluZGluZy4KCgoKAwQCARIDdAgwCrQBCgQEAgIAEgR4An0EGqUB
IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIHdoZXJlIHRoaXMgYmluZGluZyB3aWxs
IGJlIGNyZWF0ZWQuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vYXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97YXV0b19wcm90ZWN0aW9uX3BvbGlj
eX0KCgwKBQQCAgAFEgN4AggKDAoFBAICAAESA3gJDwoMCgUEAgIAAxIDeBITCg0KBQQCAgAI
EgR4FH0DCg8KCAQCAgAInAgAEgN5BCoKDwoHBAICAAifCBIEegR8BQqNAgoEBAICARIGhAEC
hQEvGvwBIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgYmluZGluZy4KIFRoaXMg
d2lsbCBiZWNvbWUgdGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUgYmluZGluZydzIHJlc291
cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBtdXN0IHN0YXJ0IHdpdGggYSBsb3dlcmNhc2UgbGV0
dGVyIGZvbGxvd2VkIGJ5IHVwIHRvIDYyCiBsb3dlcmNhc2UgbGV0dGVycywgbnVtYmVycywg
b3IgaHlwaGVucywgYW5kIGNhbm5vdCBlbmQgd2l0aCBhIGh5cGhlbi4KCg0KBQQCAgEFEgSE
AQIICg0KBQQCAgEBEgSEAQkqCg0KBQQCAgEDEgSEAS0uCg0KBQQCAgEIEgSFAQYuChAKCAQC
AgEInAgAEgSFAQctCk8KBAQCAgISBogBAokBLxo/IFJlcXVpcmVkLiBUaGUgQXV0b1Byb3Rl
Y3Rpb25Qb2xpY3lCaW5kaW5nIHJlc291cmNlIHRvIGNyZWF0ZS4KCg0KBQQCAgIGEgSIAQId
Cg0KBQQCAgIBEgSIAR48Cg0KBQQCAgIDEgSIAT9ACg0KBQQCAgIIEgSJAQYuChAKCAQCAgII
nAgAEgSJAQctCq8DCgQEAgIDEgaSAQKVAQQangMgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJl
cXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVl
c3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2
ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkg
YmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0
IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogVGhlIHJlcXVl
c3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVy
byBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAw
MDAwMDAwMDApLgoKDQoFBAICAwUSBJIBAggKDQoFBAICAwESBJIBCRMKDQoFBAICAwMSBJIB
FhcKDwoFBAICAwgSBpIBGJUBAwoTCgsEAgIDCMzx+YoBARIEkwEEKgoQCggEAgIDCJwIABIE
lAEEKgpLCgIEAxIGmQEAowEBGj0gUmVxdWVzdCBtZXNzYWdlIGZvciBnZXR0aW5nIGFuIEF1
dG9Qcm90ZWN0aW9uUG9saWN5QmluZGluZy4KCgsKAwQDARIEmQEILQq2AQoEBAMCABIGnQEC
ogEEGqUBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYmluZGluZyB0byByZXRyaWV2ZS4K
IEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRv
UHJvdGVjdGlvblBvbGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9saWN5fS9iaW5kaW5ncy97
YmluZGluZ30KCg0KBQQDAgAFEgSdAQIICg0KBQQDAgABEgSdAQkNCg0KBQQDAgADEgSdARAR
Cg8KBQQDAgAIEgadARKiAQMKEAoIBAMCAAicCAASBJ4BBCoKEQoHBAMCAAifCBIGnwEEoQEF
CkUKAgQEEgamAQDAAQEaNyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIExpc3RBdXRvUHJvdGVjdGlv
blBvbGljeUJpbmRpbmdzLgoKCwoDBAQBEgSmAQgvCpIBCgQEBAIAEgapAQKuAQQagQEgUmVx
dWlyZWQuIFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiBmb3Igd2hpY2ggdG8gcmV0cmlldmUg
dGhlIGxpc3Qgb2YKIHBvbGljaWVzLiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufQoKDQoFBAQCAAUSBKkBAggKDQoFBAQCAAESBKkBCQ8KDQoFBAQC
AAMSBKkBEhMKDwoFBAQCAAgSBqkBFK4BAwoQCggEBAIACJwIABIEqgEEKgoRCgcEBAIACJ8I
EgarAQStAQUKigEKBAQEAgESBLIBAj8afCBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVy
IG9mIHBvbGljaWVzIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLgogSWYgdW5zcGVjaWZp
ZWQsIGEgc2VydmVyLWRlZmF1bHQgdmFsdWUgd2lsbCBiZSB1c2VkLgoKDQoFBAQCAQUSBLIB
AgcKDQoFBAQCAQESBLIBCBEKDQoFBAQCAQMSBLIBFBUKDQoFBAQCAQgSBLIBFj4KEAoIBAQC
AQicCAASBLIBFz0KlAEKBAQEAgISBLcBAkEahQEgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwg
cmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdEF1dG9Qcm90ZWN0aW9uUG9saWNpZXNg
IGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudAogcGFnZS4K
Cg0KBQQEAgIFEgS3AQIICg0KBQQEAgIBEgS3AQkTCg0KBQQEAgIDEgS3ARYXCg0KBQQEAgII
EgS3ARhAChAKCAQEAgIInAgAEgS3ARk/CoIBCgQEBAIDEgS7AQI9GnQgT3B0aW9uYWwuIEEg
ZmlsdGVyIGV4cHJlc3Npb24gdGhhdCBmaWx0ZXJzIHJlc291cmNlcyBsaXN0ZWQgaW4gdGhl
CiByZXNwb25zZS4gVGhlIGZvbGxvd2luZyBmaWVsZHMgYXJlIGZpbHRlcmFibGU6CgoNCgUE
BAIDBRIEuwECCAoNCgUEBAIDARIEuwEJDwoNCgUEBAIDAxIEuwESEwoNCgUEBAIDCBIEuwEU
PAoQCggEBAIDCJwIABIEuwEVOwpzCgQEBAIEEgS/AQI/GmUgT3B0aW9uYWwuIEFuIGV4cHJl
c3Npb24gdGhhdCBzb3J0cyB0aGUgcmVzdWx0cyBpbiB0aGUgcmVzcG9uc2UuIFRoZQogZm9s
bG93aW5nIGZpZWxkcyBhcmUgc29ydGFibGU6CgoNCgUEBAIEBRIEvwECCAoNCgUEBAIEARIE
vwEJEQoNCgUEBAIEAxIEvwEUFQoNCgUEBAIECBIEvwEWPgoQCggEBAIECJwIABIEvwEXPQpG
CgIEBRIGwwEAzgEBGjggUmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdEF1dG9Qcm90ZWN0aW9u
UG9saWN5QmluZGluZ3MuCgoLCgMEBQESBMMBCDAKSwoEBAUCABIExQECSxo9IEEgbGlzdCBv
ZiB0aGUgQXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5ncyByZXNvdXJjZXMgZm91bmQuCgoN
CgUEBQIABBIExQECCgoNCgUEBQIABhIExQELJgoNCgUEBQIAARIExQEnRgoNCgUEBQIAAxIE
xQFJSgqNAQoEBAUCARIEyQECHRp/IEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcyBgcGFn
ZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMg
b21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEBQIBBRIEyQEC
CAoNCgUEBQIBARIEyQEJGAoNCgUEBQIBAxIEyQEbHApGCgQEBQICEgbMAQLNATUaNiBVbm9y
ZGVyZWQgbGlzdC4gTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUE
BQICBBIEzAECCgoNCgUEBQICBRIEzAELEQoNCgUEBQICARIEzAESHQoNCgUEBQICAxIEzAEg
IQoNCgUEBQICCBIEzQEGNAoQCggEBQICCJwIABIEzQEHMwpYCgIEBhIG0QEA7AEBGkogUmVx
dWVzdCBtZXNzYWdlIGZvciBpbml0aWF0aW5nIGRlbGV0ZSBvZiBhbiBBdXRvUHJvdGVjdGlv
blBvbGljeUJpbmRpbmcuCgoLCgMEBgESBNEBCDgKtAEKBAQGAgASBtUBAtoBBBqjASBSZXF1
aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGJpbmRpbmcgdG8gZGVsZXRlLgogRm9ybWF0OgogcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9s
aWNpZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdzL3tiaW5kaW5nfQoKDQoF
BAYCAAUSBNUBAggKDQoFBAYCAAESBNUBCQ0KDQoFBAYCAAMSBNUBEBEKDwoFBAYCAAgSBtUB
EtoBAwoQCggEBgIACJwIABIE1gEEKgoRCgcEBgIACJ8IEgbXAQTZAQUK3AEKBAQGAgESBN8B
AjsazQEgT3B0aW9uYWwuIFRoZSBjdXJyZW50IGV0YWcgb2YgdGhlIEF1dG9Qcm90ZWN0aW9u
UG9saWN5QmluZGluZy4KIElmIGFuIGV0YWcgaXMgcHJvdmlkZWQgYW5kIGRvZXMgbm90IG1h
dGNoIHRoZSBjdXJyZW50IGV0YWcgb2YgdGhlCiBiaW5kaW5nLCBkZWxldGlvbiB3aWxsIGJl
IGJsb2NrZWQgYW5kIGFuIEFCT1JURUQgZXJyb3Igd2lsbCBiZSByZXR1cm5lZC4KCg0KBQQG
AgEFEgTfAQIICg0KBQQGAgEBEgTfAQkNCg0KBQQGAgEDEgTfARARCg0KBQQGAgEIEgTfARI6
ChAKCAQGAgEInAgAEgTfARM5Cq8DCgQEBgICEgboAQLrAQQangMgT3B0aW9uYWwuIEFuIG9w
dGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlx
dWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3Qs
IHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFz
IGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRo
YXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgog
VGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9u
IHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAt
MDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAYCAgUSBOgBAggKDQoFBAYCAgESBOgBCRMKDQoF
BAYCAgMSBOgBFhcKDwoFBAYCAggSBugBGOsBAwoTCgsEBgICCMzx+YoBARIE6QEEKgoQCggE
BgICCJwIABIE6gEEKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding ===
    # Fields for AutoProtectionPolicyBinding
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.AutoProtectionPolicyBinding.State)
    # Field: scope Type: 9 ()
    # Field: binding_evaluation_summary Type: 11 (.google.cloud.backupdr.v1beta.BindingEvaluationSummary)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

# Enum: AutoProtectionPolicyBinding::State
our $AutoProtectionPolicyBinding_STATE_UNSPECIFIED = 0;
our $AutoProtectionPolicyBinding_CREATING = 1;
our $AutoProtectionPolicyBinding_ACTIVE = 2;
our $AutoProtectionPolicyBinding_DELETION_INITIATED = 3;

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary ===
    # Fields for BindingEvaluationSummary
    # Field: matching_resource_count Type: 3 ()
    # Field: protected_resource_count Type: 3 ()
    # Field: failed_resource_count Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest ===
    # Fields for CreateAutoProtectionPolicyBindingRequest
    # Field: parent Type: 9 ()
    # Field: auto_protection_policy_binding_id Type: 9 ()
    # Field: auto_protection_policy_binding Type: 11 (.google.cloud.backupdr.v1beta.AutoProtectionPolicyBinding)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest ===
    # Fields for GetAutoProtectionPolicyBindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest ===
    # Fields for ListAutoProtectionPolicyBindingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse ===
    # Fields for ListAutoProtectionPolicyBindingsResponse
    # Field: auto_protection_policy_bindings Type: 11 (.google.cloud.backupdr.v1beta.AutoProtectionPolicyBinding)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest ===
    # Fields for InitiateDeleteAutoProtectionPolicyBindingRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/autoprotectionpolicybinding.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding;

    my $msg = Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding->new({
        name => $name,
        description => $description,
        state => $state,
        scope => $scope,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/autoprotectionpolicybinding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding

An AutoprotectionPolicyBinding (APPA) acts as the bridge between an
AutoprotectionPolicy and the scope (Project, Folder, or Organization) where
the policy should be applied.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
AutoProtectionPolicyBinding. Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A description of the binding. The description must be at most
2048 characters.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::AutoProtectionPolicyBinding::State>)

Output only. The current state of the AutoProtectionPolicyBinding.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Required. Immutable. Resource Id of target container on which policy will
be applied. Format: projects/{project_id}

=item * C<< $msg->binding_evaluation_summary() >> / C<< $msg->binding_evaluation_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary>)

Output only. Summaries of the last policy application when the job has run,
with one entry per resource type specified in the AutoProtectionPolicy.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the binding was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the binding was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. The etag for the binding.
If this is provided on update, it must match the server's etag.

=back

=head3 Enum: AutoProtectionPolicyBinding::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETION_INITIATED> => C<3>

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary

BindingEvaluationSummary contains the summary of the last run of job
that applies policy to matching resources for a given binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_resource_count() >> / C<< $msg->matching_resource_count($value) >>

Type: C<Int64>

Output only. The number of resources that currently match the policy's
criteria.

=item * C<< $msg->protected_resource_count() >> / C<< $msg->protected_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources that are successfully
protected.

=item * C<< $msg->failed_resource_count() >> / C<< $msg->failed_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources whose protection failed
during job run.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest

Request message for creating an AutoProtectionPolicyBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this binding will be created.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}

=item * C<< $msg->auto_protection_policy_binding_id() >> / C<< $msg->auto_protection_policy_binding_id($value) >>

Type: C<String>

Required. The ID to use for the binding.
This will become the final component of the binding's resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, or hyphens, and cannot end with a hyphen.

=item * C<< $msg->auto_protection_policy_binding() >> / C<< $msg->auto_protection_policy_binding($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding>)

Required. The AutoProtectionPolicyBinding resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest

Request message for getting an AutoProtectionPolicyBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the binding to retrieve.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest

Request message for ListAutoProtectionPolicyBindings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve the list of
policies. Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policies to return in a single page.
If unspecified, a server-default value will be used.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAutoProtectionPolicies` call. Provide this to retrieve the subsequent
page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response. The following fields are filterable:

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression that sorts the results in the response. The
following fields are sortable:

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse

Response message for ListAutoProtectionPolicyBindings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_protection_policy_bindings() >> / C<< $msg->auto_protection_policy_bindings($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding>)

A list of the AutoProtectionPolicyBindings resources found.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest

Request message for initiating delete of an AutoProtectionPolicyBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the binding to delete.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the AutoProtectionPolicyBinding.
If an etag is provided and does not match the current etag of the
binding, deletion will be blocked and an ABORTED error will be returned.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
