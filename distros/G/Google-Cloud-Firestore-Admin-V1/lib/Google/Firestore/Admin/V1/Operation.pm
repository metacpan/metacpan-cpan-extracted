package Google::Firestore::Admin::V1::Operation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Firestore::Admin::V1::Index };
    eval { require Google::Firestore::Admin::V1::Snapshot };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL29wZXJhdGlvbi5wcm90bxIZZ29vZ2xlLmZp
cmVzdG9yZS5hZG1pbi52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxolZ29vZ2xlL2Zp
cmVzdG9yZS9hZG1pbi92MS9pbmRleC5wcm90bxooZ29vZ2xlL2ZpcmVzdG9yZS9hZG1pbi92
MS9zbmFwc2hvdC5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoEDChZJbmRleE9wZXJhdGlvbk1ldGFkYXRh
EjkKCnN0YXJ0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFy
dFRpbWUSNQoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdl
bmRUaW1lEhQKBWluZGV4GAMgASgJUgVpbmRleBI/CgVzdGF0ZRgEIAEoDjIpLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEuT3BlcmF0aW9uU3RhdGVSBXN0YXRlElIKEnByb2dyZXNzX2Rv
Y3VtZW50cxgFIAEoCzIjLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuUHJvZ3Jlc3NSEXBy
b2dyZXNzRG9jdW1lbnRzEkoKDnByb2dyZXNzX2J5dGVzGAYgASgLMiMuZ29vZ2xlLmZpcmVz
dG9yZS5hZG1pbi52MS5Qcm9ncmVzc1INcHJvZ3Jlc3NCeXRlcyLnCAoWRmllbGRPcGVyYXRp
b25NZXRhZGF0YRI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIHZW5kVGltZRIUCgVmaWVsZBgDIAEoCVIFZmllbGQScgoTaW5kZXhfY29uZmln
X2RlbHRhcxgEIAMoCzJCLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuRmllbGRPcGVyYXRp
b25NZXRhZGF0YS5JbmRleENvbmZpZ0RlbHRhUhFpbmRleENvbmZpZ0RlbHRhcxI/CgVzdGF0
ZRgFIAEoDjIpLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuT3BlcmF0aW9uU3RhdGVSBXN0
YXRlElIKEnByb2dyZXNzX2RvY3VtZW50cxgGIAEoCzIjLmdvb2dsZS5maXJlc3RvcmUuYWRt
aW4udjEuUHJvZ3Jlc3NSEXByb2dyZXNzRG9jdW1lbnRzEkoKDnByb2dyZXNzX2J5dGVzGAcg
ASgLMiMuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5Qcm9ncmVzc1INcHJvZ3Jlc3NCeXRl
cxJqChB0dGxfY29uZmlnX2RlbHRhGAggASgLMkAuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52
MS5GaWVsZE9wZXJhdGlvbk1ldGFkYXRhLlR0bENvbmZpZ0RlbHRhUg50dGxDb25maWdEZWx0
YRr6AQoQSW5kZXhDb25maWdEZWx0YRJuCgtjaGFuZ2VfdHlwZRgBIAEoDjJNLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEuRmllbGRPcGVyYXRpb25NZXRhZGF0YS5JbmRleENvbmZpZ0Rl
bHRhLkNoYW5nZVR5cGVSCmNoYW5nZVR5cGUSNgoFaW5kZXgYAiABKAsyIC5nb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxLkluZGV4UgVpbmRleCI+CgpDaGFuZ2VUeXBlEhsKF0NIQU5HRV9U
WVBFX1VOU1BFQ0lGSUVEEAASBwoDQUREEAESCgoGUkVNT1ZFEAIahgIKDlR0bENvbmZpZ0Rl
bHRhEmwKC2NoYW5nZV90eXBlGAEgASgOMksuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5G
aWVsZE9wZXJhdGlvbk1ldGFkYXRhLlR0bENvbmZpZ0RlbHRhLkNoYW5nZVR5cGVSCmNoYW5n
ZVR5cGUSRgoRZXhwaXJhdGlvbl9vZmZzZXQYAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVy
YXRpb25SEGV4cGlyYXRpb25PZmZzZXQiPgoKQ2hhbmdlVHlwZRIbChdDSEFOR0VfVFlQRV9V
TlNQRUNJRklFRBAAEgcKA0FERBABEgoKBlJFTU9WRRACIrgEChdFeHBvcnREb2N1bWVudHNN
ZXRhZGF0YRI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIHZW5kVGltZRJSCg9vcGVyYXRpb25fc3RhdGUYAyABKA4yKS5nb29nbGUuZmlyZXN0
b3JlLmFkbWluLnYxLk9wZXJhdGlvblN0YXRlUg5vcGVyYXRpb25TdGF0ZRJSChJwcm9ncmVz
c19kb2N1bWVudHMYBCABKAsyIy5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLlByb2dyZXNz
UhFwcm9ncmVzc0RvY3VtZW50cxJKCg5wcm9ncmVzc19ieXRlcxgFIAEoCzIjLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEuUHJvZ3Jlc3NSDXByb2dyZXNzQnl0ZXMSJQoOY29sbGVjdGlv
bl9pZHMYBiADKAlSDWNvbGxlY3Rpb25JZHMSKgoRb3V0cHV0X3VyaV9wcmVmaXgYByABKAlS
D291dHB1dFVyaVByZWZpeBIjCg1uYW1lc3BhY2VfaWRzGAggAygJUgxuYW1lc3BhY2VJZHMS
PwoNc25hcHNob3RfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNu
YXBzaG90VGltZSL1AwoXSW1wb3J0RG9jdW1lbnRzTWV0YWRhdGESOQoKc3RhcnRfdGltZRgB
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGlt
ZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSUgoPb3BlcmF0
aW9uX3N0YXRlGAMgASgOMikuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5PcGVyYXRpb25T
dGF0ZVIOb3BlcmF0aW9uU3RhdGUSUgoScHJvZ3Jlc3NfZG9jdW1lbnRzGAQgASgLMiMuZ29v
Z2xlLmZpcmVzdG9yZS5hZG1pbi52MS5Qcm9ncmVzc1IRcHJvZ3Jlc3NEb2N1bWVudHMSSgoO
cHJvZ3Jlc3NfYnl0ZXMYBSABKAsyIy5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLlByb2dy
ZXNzUg1wcm9ncmVzc0J5dGVzEiUKDmNvbGxlY3Rpb25faWRzGAYgAygJUg1jb2xsZWN0aW9u
SWRzEigKEGlucHV0X3VyaV9wcmVmaXgYByABKAlSDmlucHV0VXJpUHJlZml4EiMKDW5hbWVz
cGFjZV9pZHMYCCADKAlSDG5hbWVzcGFjZUlkcyKQBAobQnVsa0RlbGV0ZURvY3VtZW50c01l
dGFkYXRhEjkKCnN0YXJ0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
UglzdGFydFRpbWUSNQoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wUgdlbmRUaW1lElIKD29wZXJhdGlvbl9zdGF0ZRgDIAEoDjIpLmdvb2dsZS5maXJlc3Rv
cmUuYWRtaW4udjEuT3BlcmF0aW9uU3RhdGVSDm9wZXJhdGlvblN0YXRlElIKEnByb2dyZXNz
X2RvY3VtZW50cxgEIAEoCzIjLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuUHJvZ3Jlc3NS
EXByb2dyZXNzRG9jdW1lbnRzEkoKDnByb2dyZXNzX2J5dGVzGAUgASgLMiMuZ29vZ2xlLmZp
cmVzdG9yZS5hZG1pbi52MS5Qcm9ncmVzc1INcHJvZ3Jlc3NCeXRlcxIlCg5jb2xsZWN0aW9u
X2lkcxgGIAMoCVINY29sbGVjdGlvbklkcxIjCg1uYW1lc3BhY2VfaWRzGAcgAygJUgxuYW1l
c3BhY2VJZHMSPwoNc25hcHNob3RfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSDHNuYXBzaG90VGltZSJFChdFeHBvcnREb2N1bWVudHNSZXNwb25zZRIqChFvdXRw
dXRfdXJpX3ByZWZpeBgBIAEoCVIPb3V0cHV0VXJpUHJlZml4IrcDChdSZXN0b3JlRGF0YWJh
c2VNZXRhZGF0YRI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIHZW5kVGltZRJSCg9vcGVyYXRpb25fc3RhdGUYAyABKA4yKS5nb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxLk9wZXJhdGlvblN0YXRlUg5vcGVyYXRpb25TdGF0ZRJCCghkYXRh
YmFzZRgEIAEoCUIm+kEjCiFmaXJlc3RvcmUuZ29vZ2xlYXBpcy5jb20vRGF0YWJhc2VSCGRh
dGFiYXNlEjwKBmJhY2t1cBgFIAEoCUIk+kEhCh9maXJlc3RvcmUuZ29vZ2xlYXBpcy5jb20v
QmFja3VwUgZiYWNrdXASVAoTcHJvZ3Jlc3NfcGVyY2VudGFnZRgIIAEoCzIjLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEuUHJvZ3Jlc3NSEnByb2dyZXNzUGVyY2VudGFnZSLFAwoVQ2xv
bmVEYXRhYmFzZU1ldGFkYXRhEjkKCnN0YXJ0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUglzdGFydFRpbWUSNQoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUgdlbmRUaW1lElIKD29wZXJhdGlvbl9zdGF0ZRgDIAEoDjIpLmdv
b2dsZS5maXJlc3RvcmUuYWRtaW4udjEuT3BlcmF0aW9uU3RhdGVSDm9wZXJhdGlvblN0YXRl
EkIKCGRhdGFiYXNlGAQgASgJQib6QSMKIWZpcmVzdG9yZS5nb29nbGVhcGlzLmNvbS9EYXRh
YmFzZVIIZGF0YWJhc2USTAoNcGl0cl9zbmFwc2hvdBgHIAEoCzInLmdvb2dsZS5maXJlc3Rv
cmUuYWRtaW4udjEuUGl0clNuYXBzaG90UgxwaXRyU25hcHNob3QSVAoTcHJvZ3Jlc3NfcGVy
Y2VudGFnZRgGIAEoCzIjLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuUHJvZ3Jlc3NSEnBy
b2dyZXNzUGVyY2VudGFnZSJYCghQcm9ncmVzcxIlCg5lc3RpbWF0ZWRfd29yaxgBIAEoA1IN
ZXN0aW1hdGVkV29yaxIlCg5jb21wbGV0ZWRfd29yaxgCIAEoA1INY29tcGxldGVkV29yayqe
AQoOT3BlcmF0aW9uU3RhdGUSHwobT1BFUkFUSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAASEAoM
SU5JVElBTElaSU5HEAESDgoKUFJPQ0VTU0lORxACEg4KCkNBTkNFTExJTkcQAxIOCgpGSU5B
TElaSU5HEAQSDgoKU1VDQ0VTU0ZVTBAFEgoKBkZBSUxFRBAGEg0KCUNBTkNFTExFRBAHQt0B
Ch1jb20uZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MUIOT3BlcmF0aW9uUHJvdG9QAVo5Y2xv
dWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYXBpdjEvYWRtaW4vYWRtaW5wYjthZG1pbnBi
ogIER0NGU6oCH0dvb2dsZS5DbG91ZC5GaXJlc3RvcmUuQWRtaW4uVjHKAh9Hb29nbGVcQ2xv
dWRcRmlyZXN0b3JlXEFkbWluXFYx6gIjR29vZ2xlOjpDbG91ZDo6RmlyZXN0b3JlOjpBZG1p
bjo6VjFKg1sKBxIFDgDJAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACIKCQoCAwASAxIAIwoJCgIDARIDEwAvCgkKAgMCEgMUADIKCQoCAwMSAxUAKAoJ
CgIDBBIDFgApCggKAQgSAxgAPAoJCgIIJRIDGAA8CggKAQgSAxkAUAoJCgIICxIDGQBQCggK
AQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALwoJCgIICBIDGwAvCggKAQgSAxwANgoJCgII
ARIDHAA2CggKAQgSAx0AIgoJCgIIJBIDHQAiCggKAQgSAx4APQoJCgIIKRIDHgA9CggKAQgS
Ax8APAoJCgIILRIDHwA8CrsBCgIEABIEJAA4ARquASBNZXRhZGF0YSBmb3IgW2dvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dCiBy
ZXN1bHRzIGZyb20KIFtGaXJlc3RvcmVBZG1pbi5DcmVhdGVJbmRleF1bZ29vZ2xlLmZpcmVz
dG9yZS5hZG1pbi52MS5GaXJlc3RvcmVBZG1pbi5DcmVhdGVJbmRleF0uCgoKCgMEAAESAyQI
HgovCgQEAAIAEgMmAisaIiBUaGUgdGltZSB0aGlzIG9wZXJhdGlvbiBzdGFydGVkLgoKDAoF
BAACAAYSAyYCGwoMCgUEAAIAARIDJhwmCgwKBQQAAgADEgMmKSoKYAoEBAACARIDKgIpGlMg
VGhlIHRpbWUgdGhpcyBvcGVyYXRpb24gY29tcGxldGVkLiBXaWxsIGJlIHVuc2V0IGlmIG9w
ZXJhdGlvbiBzdGlsbCBpbgogcHJvZ3Jlc3MuCgoMCgUEAAIBBhIDKgIbCgwKBQQAAgEBEgMq
HCQKDAoFBAACAQMSAyonKAq2AQoEBAACAhIDLgITGqgBIFRoZSBpbmRleCByZXNvdXJjZSB0
aGF0IHRoaXMgb3BlcmF0aW9uIGlzIGFjdGluZyBvbi4gRm9yIGV4YW1wbGU6CiBgcHJvamVj
dHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25Hcm91
cHMve2NvbGxlY3Rpb25faWR9L2luZGV4ZXMve2luZGV4X2lkfWAKCgwKBQQAAgIFEgMuAggK
DAoFBAACAgESAy4JDgoMCgUEAAICAxIDLhESCioKBAQAAgMSAzECGxodIFRoZSBzdGF0ZSBv
ZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAwYSAzECEAoMCgUEAAIDARIDMREWCgwKBQQAAgMD
EgMxGRoKPQoEBAACBBIDNAIiGjAgVGhlIHByb2dyZXNzLCBpbiBkb2N1bWVudHMsIG9mIHRo
aXMgb3BlcmF0aW9uLgoKDAoFBAACBAYSAzQCCgoMCgUEAAIEARIDNAsdCgwKBQQAAgQDEgM0
ICEKOQoEBAACBRIDNwIeGiwgVGhlIHByb2dyZXNzLCBpbiBieXRlcywgb2YgdGhpcyBvcGVy
YXRpb24uCgoMCgUEAAIFBhIDNwIKCgwKBQQAAgUBEgM3CxkKDAoFBAACBQMSAzccHQq8AQoC
BAESBT0AhAEBGq4BIE1ldGFkYXRhIGZvciBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
bl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0KIHJlc3VsdHMgZnJvbQogW0ZpcmVz
dG9yZUFkbWluLlVwZGF0ZUZpZWxkXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkZpcmVz
dG9yZUFkbWluLlVwZGF0ZUZpZWxkXS4KCgoKAwQBARIDPQgeCkAKBAQBAwASBD8CUQMaMiBJ
bmZvcm1hdGlvbiBhYm91dCBhbiBpbmRleCBjb25maWd1cmF0aW9uIGNoYW5nZS4KCgwKBQQB
AwABEgM/ChoKNgoGBAEDAAQAEgRBBEoFGiYgU3BlY2lmaWVzIGhvdyB0aGUgaW5kZXggaXMg
Y2hhbmdpbmcuCgoOCgcEAQMABAABEgNBCRMKQAoIBAEDAAQAAgASA0MGIhovIFRoZSB0eXBl
IG9mIGNoYW5nZSBpcyBub3Qgc3BlY2lmaWVkIG9yIGtub3duLgoKEAoJBAEDAAQAAgABEgND
Bh0KEAoJBAEDAAQAAgACEgNDICEKOQoIBAEDAAQAAgESA0YGDhooIFRoZSBzaW5nbGUgZmll
bGQgaW5kZXggaXMgYmVpbmcgYWRkZWQuCgoQCgkEAQMABAACAQESA0YGCQoQCgkEAQMABAAC
AQISA0YMDQo7CggEAQMABAACAhIDSQYRGiogVGhlIHNpbmdsZSBmaWVsZCBpbmRleCBpcyBi
ZWluZyByZW1vdmVkLgoKEAoJBAEDAAQAAgIBEgNJBgwKEAoJBAEDAAQAAgICEgNJDxAKNQoG
BAEDAAIAEgNNBB8aJiBTcGVjaWZpZXMgaG93IHRoZSBpbmRleCBpcyBjaGFuZ2luZy4KCg4K
BwQBAwACAAYSA00EDgoOCgcEAQMAAgABEgNNDxoKDgoHBAEDAAIAAxIDTR0eCikKBgQBAwAC
ARIDUAQUGhogVGhlIGluZGV4IGJlaW5nIGNoYW5nZWQuCgoOCgcEAQMAAgEGEgNQBAkKDgoH
BAEDAAIBARIDUAoPCg4KBwQBAwACAQMSA1ASEwo9CgQEAQMBEgRUAmcDGi8gSW5mb3JtYXRp
b24gYWJvdXQgYSBUVEwgY29uZmlndXJhdGlvbiBjaGFuZ2UuCgoMCgUEAQMBARIDVAoYCjsK
BgQBAwEEABIEVgRfBRorIFNwZWNpZmllcyBob3cgdGhlIFRUTCBjb25maWcgaXMgY2hhbmdp
bmcuCgoOCgcEAQMBBAABEgNWCRMKQAoIBAEDAQQAAgASA1gGIhovIFRoZSB0eXBlIG9mIGNo
YW5nZSBpcyBub3Qgc3BlY2lmaWVkIG9yIGtub3duLgoKEAoJBAEDAQQAAgABEgNYBh0KEAoJ
BAEDAQQAAgACEgNYICEKMQoIBAEDAQQAAgESA1sGDhogIFRoZSBUVEwgY29uZmlnIGlzIGJl
aW5nIGFkZGVkLgoKEAoJBAEDAQQAAgEBEgNbBgkKEAoJBAEDAQQAAgECEgNbDA0KMwoIBAED
AQQAAgISA14GERoiIFRoZSBUVEwgY29uZmlnIGlzIGJlaW5nIHJlbW92ZWQuCgoQCgkEAQMB
BAACAgESA14GDAoQCgkEAQMBBAACAgISA14PEApBCgYEAQMBAgASA2IEHxoyIFNwZWNpZmll
cyBob3cgdGhlIFRUTCBjb25maWd1cmF0aW9uIGlzIGNoYW5naW5nLgoKDgoHBAEDAQIABhID
YgQOCg4KBwQBAwECAAESA2IPGgoOCgcEAQMBAgADEgNiHR4KhgEKBgQBAwECARIDZgQzGncg
VGhlIG9mZnNldCwgcmVsYXRpdmUgdG8gdGhlIHRpbWVzdGFtcCB2YWx1ZSBpbiB0aGUgVFRM
LWVuYWJsZWQgZmllbGQsCiB1c2VkIGRldGVybWluZSB0aGUgZG9jdW1lbnQncyBleHBpcmF0
aW9uIHRpbWUuCgoOCgcEAQMBAgEGEgNmBBwKDgoHBAEDAQIBARIDZh0uCg4KBwQBAwECAQMS
A2YxMgovCgQEAQIAEgNqAisaIiBUaGUgdGltZSB0aGlzIG9wZXJhdGlvbiBzdGFydGVkLgoK
DAoFBAECAAYSA2oCGwoMCgUEAQIAARIDahwmCgwKBQQBAgADEgNqKSoKYAoEBAECARIDbgIp
GlMgVGhlIHRpbWUgdGhpcyBvcGVyYXRpb24gY29tcGxldGVkLiBXaWxsIGJlIHVuc2V0IGlm
IG9wZXJhdGlvbiBzdGlsbCBpbgogcHJvZ3Jlc3MuCgoMCgUEAQIBBhIDbgIbCgwKBQQBAgEB
EgNuHCQKDAoFBAECAQMSA24nKAq3AQoEBAECAhIDcgITGqkBIFRoZSBmaWVsZCByZXNvdXJj
ZSB0aGF0IHRoaXMgb3BlcmF0aW9uIGlzIGFjdGluZyBvbi4gRm9yIGV4YW1wbGU6CiBgcHJv
amVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25H
cm91cHMve2NvbGxlY3Rpb25faWR9L2ZpZWxkcy97ZmllbGRfcGF0aH1gCgoMCgUEAQICBRID
cgIICgwKBQQBAgIBEgNyCQ4KDAoFBAECAgMSA3IREgqfAQoEBAECAxIDdwI0GpEBIEEgbGlz
dCBvZgogW0luZGV4Q29uZmlnRGVsdGFdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuRmll
bGRPcGVyYXRpb25NZXRhZGF0YS5JbmRleENvbmZpZ0RlbHRhXSwKIHdoaWNoIGRlc2NyaWJl
IHRoZSBpbnRlbnQgb2YgdGhpcyBvcGVyYXRpb24uCgoMCgUEAQIDBBIDdwIKCgwKBQQBAgMG
EgN3CxsKDAoFBAECAwESA3ccLwoMCgUEAQIDAxIDdzIzCioKBAQBAgQSA3oCGxodIFRoZSBz
dGF0ZSBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAECBAYSA3oCEAoMCgUEAQIEARIDehEWCgwK
BQQBAgQDEgN6GRoKPQoEBAECBRIDfQIiGjAgVGhlIHByb2dyZXNzLCBpbiBkb2N1bWVudHMs
IG9mIHRoaXMgb3BlcmF0aW9uLgoKDAoFBAECBQYSA30CCgoMCgUEAQIFARIDfQsdCgwKBQQB
AgUDEgN9ICEKOgoEBAECBhIEgAECHhosIFRoZSBwcm9ncmVzcywgaW4gYnl0ZXMsIG9mIHRo
aXMgb3BlcmF0aW9uLgoKDQoFBAECBgYSBIABAgoKDQoFBAECBgESBIABCxkKDQoFBAECBgMS
BIABHB0KOgoEBAECBxIEgwECJhosIERlc2NyaWJlcyB0aGUgZGVsdGFzIG9mIFRUTCBjb25m
aWd1cmF0aW9uLgoKDQoFBAECBwYSBIMBAhAKDQoFBAECBwESBIMBESEKDQoFBAECBwMSBIMB
JCUKxQEKAgQCEgaJAQCnAQEatgEgTWV0YWRhdGEgZm9yIFtnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXQogcmVzdWx0cyBmcm9t
CiBbRmlyZXN0b3JlQWRtaW4uRXhwb3J0RG9jdW1lbnRzXVtnb29nbGUuZmlyZXN0b3JlLmFk
bWluLnYxLkZpcmVzdG9yZUFkbWluLkV4cG9ydERvY3VtZW50c10uCgoLCgMEAgESBIkBCB8K
MAoEBAICABIEiwECKxoiIFRoZSB0aW1lIHRoaXMgb3BlcmF0aW9uIHN0YXJ0ZWQuCgoNCgUE
AgIABhIEiwECGwoNCgUEAgIAARIEiwEcJgoNCgUEAgIAAxIEiwEpKgphCgQEAgIBEgSPAQIp
GlMgVGhlIHRpbWUgdGhpcyBvcGVyYXRpb24gY29tcGxldGVkLiBXaWxsIGJlIHVuc2V0IGlm
IG9wZXJhdGlvbiBzdGlsbCBpbgogcHJvZ3Jlc3MuCgoNCgUEAgIBBhIEjwECGwoNCgUEAgIB
ARIEjwEcJAoNCgUEAgIBAxIEjwEnKAoyCgQEAgICEgSSAQIlGiQgVGhlIHN0YXRlIG9mIHRo
ZSBleHBvcnQgb3BlcmF0aW9uLgoKDQoFBAICAgYSBJIBAhAKDQoFBAICAgESBJIBESAKDQoF
BAICAgMSBJIBIyQKPgoEBAICAxIElQECIhowIFRoZSBwcm9ncmVzcywgaW4gZG9jdW1lbnRz
LCBvZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQCAgMGEgSVAQIKCg0KBQQCAgMBEgSVAQsdCg0K
BQQCAgMDEgSVASAhCjoKBAQCAgQSBJgBAh4aLCBUaGUgcHJvZ3Jlc3MsIGluIGJ5dGVzLCBv
ZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQCAgQGEgSYAQIKCg0KBQQCAgQBEgSYAQsZCg0KBQQC
AgQDEgSYARwdCjgKBAQCAgUSBJsBAiUaKiBXaGljaCBjb2xsZWN0aW9uIElEcyBhcmUgYmVp
bmcgZXhwb3J0ZWQuCgoNCgUEAgIFBBIEmwECCgoNCgUEAgIFBRIEmwELEQoNCgUEAgIFARIE
mwESIAoNCgUEAgIFAxIEmwEjJAo6CgQEAgIGEgSeAQIfGiwgV2hlcmUgdGhlIGRvY3VtZW50
cyBhcmUgYmVpbmcgZXhwb3J0ZWQgdG8uCgoNCgUEAgIGBRIEngECCAoNCgUEAgIGARIEngEJ
GgoNCgUEAgIGAxIEngEdHgo3CgQEAgIHEgShAQIkGikgV2hpY2ggbmFtZXNwYWNlIElEcyBh
cmUgYmVpbmcgZXhwb3J0ZWQuCgoNCgUEAgIHBBIEoQECCgoNCgUEAgIHBRIEoQELEQoNCgUE
AgIHARIEoQESHwoNCgUEAgIHAxIEoQEiIwrHAQoEBAICCBIEpgECLhq4ASBUaGUgdGltZXN0
YW1wIHRoYXQgY29ycmVzcG9uZHMgdG8gdGhlIHZlcnNpb24gb2YgdGhlIGRhdGFiYXNlIHRo
YXQgaXMgYmVpbmcKIGV4cG9ydGVkLiBJZiB1bnNwZWNpZmllZCwgdGhlcmUgYXJlIG5vIGd1
YXJhbnRlZXMgYWJvdXQgdGhlIGNvbnNpc3RlbmN5IG9mCiB0aGUgZG9jdW1lbnRzIGJlaW5n
IGV4cG9ydGVkLgoKDQoFBAICCAYSBKYBAhsKDQoFBAICCAESBKYBHCkKDQoFBAICCAMSBKYB
LC0KxQEKAgQDEgasAQDFAQEatgEgTWV0YWRhdGEgZm9yIFtnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXQogcmVzdWx0cyBmcm9t
CiBbRmlyZXN0b3JlQWRtaW4uSW1wb3J0RG9jdW1lbnRzXVtnb29nbGUuZmlyZXN0b3JlLmFk
bWluLnYxLkZpcmVzdG9yZUFkbWluLkltcG9ydERvY3VtZW50c10uCgoLCgMEAwESBKwBCB8K
MAoEBAMCABIErgECKxoiIFRoZSB0aW1lIHRoaXMgb3BlcmF0aW9uIHN0YXJ0ZWQuCgoNCgUE
AwIABhIErgECGwoNCgUEAwIAARIErgEcJgoNCgUEAwIAAxIErgEpKgphCgQEAwIBEgSyAQIp
GlMgVGhlIHRpbWUgdGhpcyBvcGVyYXRpb24gY29tcGxldGVkLiBXaWxsIGJlIHVuc2V0IGlm
IG9wZXJhdGlvbiBzdGlsbCBpbgogcHJvZ3Jlc3MuCgoNCgUEAwIBBhIEsgECGwoNCgUEAwIB
ARIEsgEcJAoNCgUEAwIBAxIEsgEnKAoyCgQEAwICEgS1AQIlGiQgVGhlIHN0YXRlIG9mIHRo
ZSBpbXBvcnQgb3BlcmF0aW9uLgoKDQoFBAMCAgYSBLUBAhAKDQoFBAMCAgESBLUBESAKDQoF
BAMCAgMSBLUBIyQKPgoEBAMCAxIEuAECIhowIFRoZSBwcm9ncmVzcywgaW4gZG9jdW1lbnRz
LCBvZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQDAgMGEgS4AQIKCg0KBQQDAgMBEgS4AQsdCg0K
BQQDAgMDEgS4ASAhCjoKBAQDAgQSBLsBAh4aLCBUaGUgcHJvZ3Jlc3MsIGluIGJ5dGVzLCBv
ZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQDAgQGEgS7AQIKCg0KBQQDAgQBEgS7AQsZCg0KBQQD
AgQDEgS7ARwdCjgKBAQDAgUSBL4BAiUaKiBXaGljaCBjb2xsZWN0aW9uIElEcyBhcmUgYmVp
bmcgaW1wb3J0ZWQuCgoNCgUEAwIFBBIEvgECCgoNCgUEAwIFBRIEvgELEQoNCgUEAwIFARIE
vgESIAoNCgUEAwIFAxIEvgEjJAo9CgQEAwIGEgTBAQIeGi8gVGhlIGxvY2F0aW9uIG9mIHRo
ZSBkb2N1bWVudHMgYmVpbmcgaW1wb3J0ZWQuCgoNCgUEAwIGBRIEwQECCAoNCgUEAwIGARIE
wQEJGQoNCgUEAwIGAxIEwQEcHQo3CgQEAwIHEgTEAQIkGikgV2hpY2ggbmFtZXNwYWNlIElE
cyBhcmUgYmVpbmcgaW1wb3J0ZWQuCgoNCgUEAwIHBBIExAECCgoNCgUEAwIHBRIExAELEQoN
CgUEAwIHARIExAESHwoNCgUEAwIHAxIExAEiIwrNAQoCBAQSBsoBAOYBARq+ASBNZXRhZGF0
YSBmb3IgW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb25dCiByZXN1bHRzIGZyb20KIFtGaXJlc3RvcmVBZG1pbi5CdWxrRGVsZXRl
RG9jdW1lbnRzXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkZpcmVzdG9yZUFkbWluLkJ1
bGtEZWxldGVEb2N1bWVudHNdLgoKCwoDBAQBEgTKAQgjCjAKBAQEAgASBMwBAisaIiBUaGUg
dGltZSB0aGlzIG9wZXJhdGlvbiBzdGFydGVkLgoKDQoFBAQCAAYSBMwBAhsKDQoFBAQCAAES
BMwBHCYKDQoFBAQCAAMSBMwBKSoKYQoEBAQCARIE0AECKRpTIFRoZSB0aW1lIHRoaXMgb3Bl
cmF0aW9uIGNvbXBsZXRlZC4gV2lsbCBiZSB1bnNldCBpZiBvcGVyYXRpb24gc3RpbGwgaW4K
IHByb2dyZXNzLgoKDQoFBAQCAQYSBNABAhsKDQoFBAQCAQESBNABHCQKDQoFBAQCAQMSBNAB
JygKKwoEBAQCAhIE0wECJRodIFRoZSBzdGF0ZSBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAQC
AgYSBNMBAhAKDQoFBAQCAgESBNMBESAKDQoFBAQCAgMSBNMBIyQKPgoEBAQCAxIE1gECIhow
IFRoZSBwcm9ncmVzcywgaW4gZG9jdW1lbnRzLCBvZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQE
AgMGEgTWAQIKCg0KBQQEAgMBEgTWAQsdCg0KBQQEAgMDEgTWASAhCjoKBAQEAgQSBNkBAh4a
LCBUaGUgcHJvZ3Jlc3MsIGluIGJ5dGVzLCBvZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQEAgQG
EgTZAQIKCg0KBQQEAgQBEgTZAQsZCg0KBQQEAgQDEgTZARwdCkgKBAQEAgUSBNwBAiUaOiBU
aGUgSURzIG9mIHRoZSBjb2xsZWN0aW9uIGdyb3VwcyB0aGF0IGFyZSBiZWluZyBkZWxldGVk
LgoKDQoFBAQCBQQSBNwBAgoKDQoFBAQCBQUSBNwBCxEKDQoFBAQCBQESBNwBEiAKDQoFBAQC
BQMSBNwBIyQKNgoEBAQCBhIE3wECJBooIFdoaWNoIG5hbWVzcGFjZSBJRHMgYXJlIGJlaW5n
IGRlbGV0ZWQuCgoNCgUEBAIGBBIE3wECCgoNCgUEBAIGBRIE3wELEQoNCgUEBAIGARIE3wES
HwoNCgUEBAIGAxIE3wEiIwr9AQoEBAQCBxIE5QECLhruASBUaGUgdGltZXN0YW1wIHRoYXQg
Y29ycmVzcG9uZHMgdG8gdGhlIHZlcnNpb24gb2YgdGhlIGRhdGFiYXNlIHRoYXQgaXMgYmVp
bmcKIHJlYWQgdG8gZ2V0IHRoZSBsaXN0IG9mIGRvY3VtZW50cyB0byBkZWxldGUuIFRoaXMg
dGltZSBjYW4gYWxzbyBiZSB1c2VkIGFzCiB0aGUgdGltZXN0YW1wIG9mIFBJVFIgaW4gY2Fz
ZSBvZiBkaXNhc3RlciByZWNvdmVyeSAoc3ViamVjdCB0byBQSVRSIHdpbmRvdwogbGltaXQp
LgoKDQoFBAQCBwYSBOUBAhsKDQoFBAQCBwESBOUBHCkKDQoFBAQCBwMSBOUBLC0KbQoCBAUS
BuoBAO8BARpfIFJldHVybmVkIGluIHRoZSBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
bl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0KIHJlc3BvbnNlIGZpZWxkLgoKCwoD
BAUBEgTqAQgfCrcBCgQEBQIAEgTuAQIfGqgBIExvY2F0aW9uIG9mIHRoZSBvdXRwdXQgZmls
ZXMuIFRoaXMgY2FuIGJlIHVzZWQgdG8gYmVnaW4gYW4gaW1wb3J0CiBpbnRvIENsb3VkIEZp
cmVzdG9yZSAodGhpcyBwcm9qZWN0IG9yIGFub3RoZXIgcHJvamVjdCkgYWZ0ZXIgdGhlIG9w
ZXJhdGlvbgogY29tcGxldGVzIHN1Y2Nlc3NmdWxseS4KCg0KBQQFAgAFEgTuAQIICg0KBQQF
AgABEgTuAQkaCg0KBQQFAgADEgTuAR0eCqgBCgIEBhIG8wEAiQIBGpkBIE1ldGFkYXRhIGZv
ciB0aGUgW2xvbmctcnVubmluZyBvcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb25dIGZyb20KIHRoZSBbUmVzdG9yZURhdGFiYXNlXVtnb29nbGUuZmlyZXN0b3JlLmFk
bWluLnYxLlJlc3RvcmVEYXRhYmFzZV0gcmVxdWVzdC4KCgsKAwQGARIE8wEIHwoxCgQEBgIA
EgT1AQIrGiMgVGhlIHRpbWUgdGhlIHJlc3RvcmUgd2FzIHN0YXJ0ZWQuCgoNCgUEBgIABhIE
9QECGwoNCgUEBgIAARIE9QEcJgoNCgUEBgIAAxIE9QEpKgpKCgQEBgIBEgT4AQIpGjwgVGhl
IHRpbWUgdGhlIHJlc3RvcmUgZmluaXNoZWQsIHVuc2V0IGZvciBvbmdvaW5nIHJlc3RvcmVz
LgoKDQoFBAYCAQYSBPgBAhsKDQoFBAYCAQESBPgBHCQKDQoFBAYCAQMSBPgBJygKMwoEBAYC
AhIE+wECJRolIFRoZSBvcGVyYXRpb24gc3RhdGUgb2YgdGhlIHJlc3RvcmUuCgoNCgUEBgIC
BhIE+wECEAoNCgUEBgICARIE+wERIAoNCgUEBgICAxIE+wEjJAo9CgQEBgIDEgb+AQKAAgUa
LSBUaGUgbmFtZSBvZiB0aGUgZGF0YWJhc2UgYmVpbmcgcmVzdG9yZWQgdG8uCgoNCgUEBgID
BRIE/gECCAoNCgUEBgIDARIE/gEJEQoNCgUEBgIDAxIE/gEUFQoPCgUEBgIDCBIG/gEWgAIE
ChEKBwQGAgMInwgSBv4BF4ACAwo4CgQEBgIEEgaDAgKFAgUaKCBUaGUgbmFtZSBvZiB0aGUg
YmFja3VwIHJlc3RvcmluZyBmcm9tLgoKDQoFBAYCBAUSBIMCAggKDQoFBAYCBAESBIMCCQ8K
DQoFBAYCBAMSBIMCEhMKDwoFBAYCBAgSBoMCFIUCBAoRCgcEBgIECJ8IEgaDAhWFAgMKWgoE
BAYCBRIEiAICIxpMIEhvdyBmYXIgYWxvbmcgdGhlIHJlc3RvcmUgaXMgYXMgYW4gZXN0aW1h
dGVkIHBlcmNlbnRhZ2Ugb2YgcmVtYWluaW5nIHRpbWUuCgoNCgUEBgIFBhIEiAICCgoNCgUE
BgIFARIEiAILHgoNCgUEBgIFAxIEiAIhIgqkAQoCBAcSBo0CAKECARqVASBNZXRhZGF0YSBm
b3IgdGhlIFtsb25nLXJ1bm5pbmcgb3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uXSBmcm9tCiB0aGUgW0Nsb25lRGF0YWJhc2VdW2dvb2dsZS5maXJlc3RvcmUuYWRt
aW4udjEuQ2xvbmVEYXRhYmFzZV0gcmVxdWVzdC4KCgsKAwQHARIEjQIIHQovCgQEBwIAEgSP
AgIrGiEgVGhlIHRpbWUgdGhlIGNsb25lIHdhcyBzdGFydGVkLgoKDQoFBAcCAAYSBI8CAhsK
DQoFBAcCAAESBI8CHCYKDQoFBAcCAAMSBI8CKSoKRgoEBAcCARIEkgICKRo4IFRoZSB0aW1l
IHRoZSBjbG9uZSBmaW5pc2hlZCwgdW5zZXQgZm9yIG9uZ29pbmcgY2xvbmVzLgoKDQoFBAcC
AQYSBJICAhsKDQoFBAcCAQESBJICHCQKDQoFBAcCAQMSBJICJygKMQoEBAcCAhIElQICJRoj
IFRoZSBvcGVyYXRpb24gc3RhdGUgb2YgdGhlIGNsb25lLgoKDQoFBAcCAgYSBJUCAhAKDQoF
BAcCAgESBJUCESAKDQoFBAcCAgMSBJUCIyQKOwoEBAcCAxIGmAICmgIFGisgVGhlIG5hbWUg
b2YgdGhlIGRhdGFiYXNlIGJlaW5nIGNsb25lZCB0by4KCg0KBQQHAgMFEgSYAgIICg0KBQQH
AgMBEgSYAgkRCg0KBQQHAgMDEgSYAhQVCg8KBQQHAgMIEgaYAhaaAgQKEQoHBAcCAwifCBIG
mAIXmgIDCkEKBAQHAgQSBJ0CAiEaMyBUaGUgc25hcHNob3QgZnJvbSB3aGljaCB0aGlzIGRh
dGFiYXNlIHdhcyBjbG9uZWQuCgoNCgUEBwIEBhIEnQICDgoNCgUEBwIEARIEnQIPHAoNCgUE
BwIEAxIEnQIfIApYCgQEBwIFEgSgAgIjGkogSG93IGZhciBhbG9uZyB0aGUgY2xvbmUgaXMg
YXMgYW4gZXN0aW1hdGVkIHBlcmNlbnRhZ2Ugb2YgcmVtYWluaW5nIHRpbWUuCgoNCgUEBwIF
BhIEoAICCgoNCgUEBwIFARIEoAILHgoNCgUEBwIFAxIEoAIhIgqyAQoCBAgSBqYCAKwCARqj
ASBEZXNjcmliZXMgdGhlIHByb2dyZXNzIG9mIHRoZSBvcGVyYXRpb24uCiBVbml0IG9mIHdv
cmsgaXMgZ2VuZXJpYyBhbmQgbXVzdCBiZSBpbnRlcnByZXRlZCBiYXNlZCBvbiB3aGVyZQog
W1Byb2dyZXNzXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLlByb2dyZXNzXSBpcyB1c2Vk
LgoKCwoDBAgBEgSmAggQCi0KBAQIAgASBKgCAhsaHyBUaGUgYW1vdW50IG9mIHdvcmsgZXN0
aW1hdGVkLgoKDQoFBAgCAAUSBKgCAgcKDQoFBAgCAAESBKgCCBYKDQoFBAgCAAMSBKgCGRoK
LQoEBAgCARIEqwICGxofIFRoZSBhbW91bnQgb2Ygd29yayBjb21wbGV0ZWQuCgoNCgUECAIB
BRIEqwICBwoNCgUECAIBARIEqwIIFgoNCgUECAIBAxIEqwIZGgo1CgIFABIGrwIAyQIBGicg
RGVzY3JpYmVzIHRoZSBzdGF0ZSBvZiB0aGUgb3BlcmF0aW9uLgoKCwoDBQABEgSvAgUTChwK
BAUAAgASBLECAiIaDiBVbnNwZWNpZmllZC4KCg0KBQUAAgABEgSxAgIdCg0KBQUAAgACEgSx
AiAhCjkKBAUAAgESBLQCAhMaKyBSZXF1ZXN0IGlzIGJlaW5nIHByZXBhcmVkIGZvciBwcm9j
ZXNzaW5nLgoKDQoFBQACAQESBLQCAg4KDQoFBQACAQISBLQCERIKNAoEBQACAhIEtwICERom
IFJlcXVlc3QgaXMgYWN0aXZlbHkgYmVpbmcgcHJvY2Vzc2VkLgoKDQoFBQACAgESBLcCAgwK
DQoFBQACAgISBLcCDxAKkAEKBAUAAgMSBLsCAhEagQEgUmVxdWVzdCBpcyBpbiB0aGUgcHJv
Y2VzcyBvZiBiZWluZyBjYW5jZWxsZWQgYWZ0ZXIgdXNlciBjYWxsZWQKIGdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb25zLkNhbmNlbE9wZXJhdGlvbiBvbiB0aGUgb3BlcmF0aW9uLgoK
DQoFBQACAwESBLsCAgwKDQoFBQACAwISBLsCDxAKTAoEBQACBBIEvgICERo+IFJlcXVlc3Qg
aGFzIGJlZW4gcHJvY2Vzc2VkIGFuZCBpcyBpbiBpdHMgZmluYWxpemF0aW9uIHN0YWdlLgoK
DQoFBQACBAESBL4CAgwKDQoFBQACBAISBL4CDxAKMwoEBQACBRIEwQICERolIFJlcXVlc3Qg
aGFzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoNCgUFAAIFARIEwQICDAoNCgUFAAIFAhIE
wQIPEApPCgQFAAIGEgTEAgINGkEgUmVxdWVzdCBoYXMgZmluaXNoZWQgYmVpbmcgcHJvY2Vz
c2VkLCBidXQgZW5jb3VudGVyZWQgYW4gZXJyb3IuCgoNCgUFAAIGARIExAICCAoNCgUFAAIG
AhIExAILDAp2CgQFAAIHEgTIAgIQGmggUmVxdWVzdCBoYXMgZmluaXNoZWQgYmVpbmcgY2Fu
Y2VsbGVkIGFmdGVyIHVzZXIgY2FsbGVkCiBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
cy5DYW5jZWxPcGVyYXRpb24uCgoNCgUFAAIHARIEyAICCwoNCgUFAAIHAhIEyAIOD2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::Operation::IndexOperationMetadata ===
    # Fields for IndexOperationMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: index Type: 9 ()
    # Field: state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1.Progress)

# === Message: Google::Firestore::Admin::V1::Operation::FieldOperationMetadata ===
    # Fields for FieldOperationMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: field Type: 9 ()
    # Field: index_config_deltas Type: 11 (.google.firestore.admin.v1.FieldOperationMetadata.IndexConfigDelta)
    # Field: state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: ttl_config_delta Type: 11 (.google.firestore.admin.v1.FieldOperationMetadata.TtlConfigDelta)

# === Message: Google::Firestore::Admin::V1::Operation::ExportDocumentsMetadata ===
    # Fields for ExportDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: output_uri_prefix Type: 9 ()
    # Field: namespace_ids Type: 9 ()
    # Field: snapshot_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::Admin::V1::Operation::ImportDocumentsMetadata ===
    # Fields for ImportDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: input_uri_prefix Type: 9 ()
    # Field: namespace_ids Type: 9 ()

# === Message: Google::Firestore::Admin::V1::Operation::BulkDeleteDocumentsMetadata ===
    # Fields for BulkDeleteDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: namespace_ids Type: 9 ()
    # Field: snapshot_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::Admin::V1::Operation::ExportDocumentsResponse ===
    # Fields for ExportDocumentsResponse
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1::Operation::RestoreDatabaseMetadata ===
    # Fields for RestoreDatabaseMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: database Type: 9 ()
    # Field: backup Type: 9 ()
    # Field: progress_percentage Type: 11 (.google.firestore.admin.v1.Progress)

# === Message: Google::Firestore::Admin::V1::Operation::CloneDatabaseMetadata ===
    # Fields for CloneDatabaseMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1.OperationState)
    # Field: database Type: 9 ()
    # Field: pitr_snapshot Type: 11 (.google.firestore.admin.v1.PitrSnapshot)
    # Field: progress_percentage Type: 11 (.google.firestore.admin.v1.Progress)

# === Message: Google::Firestore::Admin::V1::Operation::Progress ===
    # Fields for Progress
    # Field: estimated_work Type: 3 ()
    # Field: completed_work Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::Operation - Compiled Protocol Buffers messages for google/firestore/admin/v1/operation.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::Operation;

    my $msg = Google::Firestore::Admin::V1::Operation::IndexOperationMetadata->new({
        start_time => $start_time,
        end_time => $end_time,
        index => $index,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->start_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::Operation::IndexOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/operation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::Operation::IndexOperationMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation]
results from
[FirestoreAdmin.CreateIndex][google.firestore.admin.v1.FirestoreAdmin.CreateIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<String>

The index resource that this operation is acting on. For example:
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The state of the operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in bytes, of this operation.

=back

=head2 Google::Firestore::Admin::V1::Operation::FieldOperationMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation]
results from
[FirestoreAdmin.UpdateField][google.firestore.admin.v1.FirestoreAdmin.UpdateField].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->field() >> / C<< $msg->field($value) >>

Type: C<String>

The field resource that this operation is acting on. For example:
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_path}`

=item * C<< $msg->index_config_deltas() >> / C<< $msg->index_config_deltas($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::IndexConfigDelta>)

A list of
[IndexConfigDelta][google.firestore.admin.v1.FieldOperationMetadata.IndexConfigDelta],
which describe the intent of this operation.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The state of the operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in bytes, of this operation.

=item * C<< $msg->ttl_config_delta() >> / C<< $msg->ttl_config_delta($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::TtlConfigDelta>)

Describes the deltas of TTL configuration.

=back

=head2 Google::Firestore::Admin::V1::Operation::ExportDocumentsMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation]
results from
[FirestoreAdmin.ExportDocuments][google.firestore.admin.v1.FirestoreAdmin.ExportDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The state of the export operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in bytes, of this operation.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection IDs are being exported.

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Where the documents are being exported to.

=item * C<< $msg->namespace_ids() >> / C<< $msg->namespace_ids($value) >>

Type: C<String>

Which namespace IDs are being exported.

=item * C<< $msg->snapshot_time() >> / C<< $msg->snapshot_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp that corresponds to the version of the database that is being
exported. If unspecified, there are no guarantees about the consistency of
the documents being exported.

=back

=head2 Google::Firestore::Admin::V1::Operation::ImportDocumentsMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation]
results from
[FirestoreAdmin.ImportDocuments][google.firestore.admin.v1.FirestoreAdmin.ImportDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The state of the import operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in bytes, of this operation.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection IDs are being imported.

=item * C<< $msg->input_uri_prefix() >> / C<< $msg->input_uri_prefix($value) >>

Type: C<String>

The location of the documents being imported.

=item * C<< $msg->namespace_ids() >> / C<< $msg->namespace_ids($value) >>

Type: C<String>

Which namespace IDs are being imported.

=back

=head2 Google::Firestore::Admin::V1::Operation::BulkDeleteDocumentsMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation]
results from
[FirestoreAdmin.BulkDeleteDocuments][google.firestore.admin.v1.FirestoreAdmin.BulkDeleteDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The state of the operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

The progress, in bytes, of this operation.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

The IDs of the collection groups that are being deleted.

=item * C<< $msg->namespace_ids() >> / C<< $msg->namespace_ids($value) >>

Type: C<String>

Which namespace IDs are being deleted.

=item * C<< $msg->snapshot_time() >> / C<< $msg->snapshot_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp that corresponds to the version of the database that is being
read to get the list of documents to delete. This time can also be used as
the timestamp of PITR in case of disaster recovery (subject to PITR window
limit).

=back

=head2 Google::Firestore::Admin::V1::Operation::ExportDocumentsResponse

Returned in the [google.longrunning.Operation][google.longrunning.Operation]
response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Location of the output files. This can be used to begin an import
into Cloud Firestore (this project or another project) after the operation
completes successfully.

=back

=head2 Google::Firestore::Admin::V1::Operation::RestoreDatabaseMetadata

Metadata for the [long-running operation][google.longrunning.Operation] from
the [RestoreDatabase][google.firestore.admin.v1.RestoreDatabase] request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the restore was started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the restore finished, unset for ongoing restores.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The operation state of the restore.

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

The name of the database being restored to.

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<String>

The name of the backup restoring from.

=item * C<< $msg->progress_percentage() >> / C<< $msg->progress_percentage($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

How far along the restore is as an estimated percentage of remaining time.

=back

=head2 Google::Firestore::Admin::V1::Operation::CloneDatabaseMetadata

Metadata for the [long-running operation][google.longrunning.Operation] from
the [CloneDatabase][google.firestore.admin.v1.CloneDatabase] request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the clone was started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the clone finished, unset for ongoing clones.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::OperationState>)

The operation state of the clone.

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

The name of the database being cloned to.

=item * C<< $msg->pitr_snapshot() >> / C<< $msg->pitr_snapshot($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Snapshot::PitrSnapshot>)

The snapshot from which this database was cloned.

=item * C<< $msg->progress_percentage() >> / C<< $msg->progress_percentage($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Operation::Progress>)

How far along the clone is as an estimated percentage of remaining time.

=back

=head2 Google::Firestore::Admin::V1::Operation::Progress

Describes the progress of the operation.
Unit of work is generic and must be interpreted based on where
[Progress][google.firestore.admin.v1.Progress] is used.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->estimated_work() >> / C<< $msg->estimated_work($value) >>

Type: C<Int64>

The amount of work estimated.

=item * C<< $msg->completed_work() >> / C<< $msg->completed_work($value) >>

Type: C<Int64>

The amount of work completed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::Operation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
