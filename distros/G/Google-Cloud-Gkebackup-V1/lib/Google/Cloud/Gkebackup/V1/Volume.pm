package Google::Cloud::Gkebackup::V1::Volume;

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
    eval { require Google::Cloud::Gkebackup::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL3ZvbHVtZS5wcm90bxIZZ29vZ2xlLmNsb3Vk
LmdrZWJhY2t1cC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxomZ29vZ2xlL2Nsb3VkL2drZWJhY2t1cC92MS9jb21tb24u
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8inQkKDFZvbHVtZUJhY2t1
cBIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSFQoDdWlkGAIgASgJQgPgQQNSA3VpZBJACgtj
cmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3Jl
YXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKdXBkYXRlVGltZRJNCgpzb3VyY2VfcHZjGAUgASgLMikuZ29vZ2xlLmNsb3Vk
LmdrZWJhY2t1cC52MS5OYW1lc3BhY2VkTmFtZUID4EEDUglzb3VyY2VQdmMSNQoUdm9sdW1l
X2JhY2t1cF9oYW5kbGUYBiABKAlCA+BBA1ISdm9sdW1lQmFja3VwSGFuZGxlElcKBmZvcm1h
dBgHIAEoDjI6Lmdvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuVm9sdW1lQmFja3VwLlZvbHVt
ZUJhY2t1cEZvcm1hdEID4EEDUgZmb3JtYXQSKAoNc3RvcmFnZV9ieXRlcxgIIAEoA0ID4EED
UgxzdG9yYWdlQnl0ZXMSKwoPZGlza19zaXplX2J5dGVzGAkgASgDQgPgQQNSDWRpc2tTaXpl
Qnl0ZXMSRAoNY29tcGxldGVfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IMY29tcGxldGVUaW1lEkgKBXN0YXRlGAsgASgOMi0uZ29vZ2xlLmNsb3VkLmdr
ZWJhY2t1cC52MS5Wb2x1bWVCYWNrdXAuU3RhdGVCA+BBA1IFc3RhdGUSKAoNc3RhdGVfbWVz
c2FnZRgMIAEoCUID4EEDUgxzdGF0ZU1lc3NhZ2USFwoEZXRhZxgNIAEoCUID4EEDUgRldGFn
EigKDXNhdGlzZmllc19wenMYDiABKAhCA+BBA1IMc2F0aXNmaWVzUHpzEigKDXNhdGlzZmll
c19wemkYDyABKAhCA+BBA1IMc2F0aXNmaWVzUHppIlMKElZvbHVtZUJhY2t1cEZvcm1hdBIk
CiBWT0xVTUVfQkFDS1VQX0ZPUk1BVF9VTlNQRUNJRklFRBAAEhcKE0dDRV9QRVJTSVNURU5U
X0RJU0sQASKGAQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxAB
EhAKDFNOQVBTSE9UVElORxACEg0KCVVQTE9BRElORxADEg0KCVNVQ0NFRURFRBAEEgoKBkZB
SUxFRBAFEgwKCERFTEVUSU5HEAYSDgoKQ0xFQU5FRF9VUBAHOp0B6kGZAQolZ2tlYmFja3Vw
Lmdvb2dsZWFwaXMuY29tL1ZvbHVtZUJhY2t1cBJwcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2JhY2t1cFBsYW5zL3tiYWNrdXBfcGxhbn0vYmFja3Vwcy97YmFj
a3VwfS92b2x1bWVCYWNrdXBzL3t2b2x1bWVfYmFja3VwfSLmBwoNVm9sdW1lUmVzdG9yZRIX
CgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSFQoDdWlkGAIgASgJQgPgQQNSA3VpZBJACgtjcmVh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKdXBkYXRlVGltZRIoCg12b2x1bWVfYmFja3VwGAUgASgJQgPgQQNSDHZvbHVtZUJh
Y2t1cBJNCgp0YXJnZXRfcHZjGAYgASgLMikuZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5O
YW1lc3BhY2VkTmFtZUID4EEDUgl0YXJnZXRQdmMSKAoNdm9sdW1lX2hhbmRsZRgHIAEoCUID
4EEDUgx2b2x1bWVIYW5kbGUSWQoLdm9sdW1lX3R5cGUYCCABKA4yMy5nb29nbGUuY2xvdWQu
Z2tlYmFja3VwLnYxLlZvbHVtZVJlc3RvcmUuVm9sdW1lVHlwZUID4EEDUgp2b2x1bWVUeXBl
EkQKDWNvbXBsZXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSDGNvbXBsZXRlVGltZRJJCgVzdGF0ZRgKIAEoDjIuLmdvb2dsZS5jbG91ZC5na2ViYWNr
dXAudjEuVm9sdW1lUmVzdG9yZS5TdGF0ZUID4EEDUgVzdGF0ZRIoCg1zdGF0ZV9tZXNzYWdl
GAsgASgJQgPgQQNSDHN0YXRlTWVzc2FnZRIXCgRldGFnGAwgASgJQgPgQQNSBGV0YWciQgoK
Vm9sdW1lVHlwZRIbChdWT0xVTUVfVFlQRV9VTlNQRUNJRklFRBAAEhcKE0dDRV9QRVJTSVNU
RU5UX0RJU0sQASJkCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5H
EAESDQoJUkVTVE9SSU5HEAISDQoJU1VDQ0VFREVEEAMSCgoGRkFJTEVEEAQSDAoIREVMRVRJ
TkcQBTqkAepBoAEKJmdrZWJhY2t1cC5nb29nbGVhcGlzLmNvbS9Wb2x1bWVSZXN0b3JlEnZw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVzdG9yZVBsYW5zL3ty
ZXN0b3JlX3BsYW59L3Jlc3RvcmVzL3tyZXN0b3JlfS92b2x1bWVSZXN0b3Jlcy97dm9sdW1l
X3Jlc3RvcmV9QsIBCh1jb20uZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MUILVm9sdW1lUHJv
dG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9na2ViYWNrdXAvYXBpdjEvZ2tlYmFja3VwcGI7
Z2tlYmFja3VwcGKqAhlHb29nbGUuQ2xvdWQuR2tlQmFja3VwLlYxygIZR29vZ2xlXENsb3Vk
XEdrZUJhY2t1cFxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkdrZUJhY2t1cDo6VjFKyUkKBxIFDgDw
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACIKCQoCAwAS
AxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADAKCQoCAwMSAxUAKQoICgEIEgMXADYKCQoCCCUS
AxcANgoICgEIEgMYAFIKCQoCCAsSAxgAUgoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMa
ACwKCQoCCAgSAxoALAoICgEIEgMbADYKCQoCCAESAxsANgoICgEIEgMcADYKCQoCCCkSAxwA
NgoICgEIEgMdADUKCQoCCC0SAx0ANQrBAQoCBAASBSIAlQEBGrMBIFJlcHJlc2VudHMgdGhl
IGJhY2t1cCBvZiBhIHNwZWNpZmljIHBlcnNpc3RlbnQgdm9sdW1lIGFzIGEgY29tcG9uZW50
IG9mIGEKIEJhY2t1cCAtIGJvdGggdGhlIHJlY29yZCBvZiB0aGUgb3BlcmF0aW9uIGFuZCBh
IHBvaW50ZXIgdG8gdGhlIHVuZGVybHlpbmcKIHN0b3JhZ2Utc3BlY2lmaWMgYXJ0aWZhY3Rz
LgoKCgoDBAABEgMiCBQKCwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYECkEKBAQABAASBCkC
LwMaMyBJZGVudGlmaWVzIHRoZSBmb3JtYXQgdXNlZCBmb3IgdGhlIHZvbHVtZSBiYWNrdXAu
CgoMCgUEAAQAARIDKQcZCi4KBgQABAACABIDKwQpGh8gRGVmYXVsdCB2YWx1ZSwgbm90IHNw
ZWNpZmllZC4KCg4KBwQABAACAAESAysEJAoOCgcEAAQAAgACEgMrJygKTQoGBAAEAAIBEgMu
BBwaPiBDb21wdXRlIEVuZ2luZSBQZXJzaXN0ZW50IERpc2sgc25hcHNob3QgYmFzZWQgdm9s
dW1lIGJhY2t1cC4KCg4KBwQABAACAQESAy4EFwoOCgcEAAQAAgECEgMuGhsKMwoEBAAEARIE
MgJRAxolIFRoZSBjdXJyZW50IHN0YXRlIG9mIGEgVm9sdW1lQmFja3VwCgoMCgUEAAQBARID
MgcMCkgKBgQABAECABIDNAQaGjkgVGhpcyBpcyBhbiBpbGxlZ2FsIHN0YXRlIGFuZCBzaG91
bGQgbm90IGJlIGVuY291bnRlcmVkLgoKDgoHBAAEAQIAARIDNAQVCg4KBwQABAECAAISAzQY
GQpeCgYEAAQBAgESAzgEERpPIEEgdm9sdW1lIGZvciB0aGUgYmFja3VwIHdhcyBpZGVudGlm
aWVkIGFuZCBiYWNrdXAgcHJvY2VzcyBpcyBhYm91dCB0bwogc3RhcnQuCgoOCgcEAAQBAgEB
EgM4BAwKDgoHBAAEAQIBAhIDOA8QCoUCCgYEAAQBAgISAz4EFRr1ASBUaGUgdm9sdW1lIGJh
Y2t1cCBvcGVyYXRpb24gaGFzIGJlZ3VuIGFuZCBpcyBpbiB0aGUgaW5pdGlhbCAic25hcHNo
b3QiCiBwaGFzZSBvZiB0aGUgcHJvY2Vzcy4gQW55IGRlZmluZWQgUHJvdGVjdGVkQXBwbGlj
YXRpb24gInByZSIgaG9va3Mgd2lsbAogYmUgZXhlY3V0ZWQgYmVmb3JlIGVudGVyaW5nIHRo
aXMgc3RhdGUgYW5kICJwb3N0IiBob29rcyB3aWxsIGJlIGV4ZWN1dGVkCiB1cG9uIGxlYXZp
bmcgdGhpcyBzdGF0ZS4KCg4KBwQABAECAgESAz4EEAoOCgcEAAQBAgICEgM+ExQKiwEKBgQA
BAECAxIDQgQSGnwgVGhlIHNuYXBzaG90IHBoYXNlIG9mIHRoZSB2b2x1bWUgYmFja3VwIG9w
ZXJhdGlvbiBoYXMgY29tcGxldGVkIGFuZAogdGhlIHNuYXBzaG90IGlzIG5vdyBiZWluZyB1
cGxvYWRlZCB0byBiYWNrdXAgc3RvcmFnZS4KCg4KBwQABAECAwESA0IEDQoOCgcEAAQBAgMC
EgNCEBEKSAoGBAAEAQIEEgNFBBIaOSBUaGUgdm9sdW1lIGJhY2t1cCBvcGVyYXRpb24gaGFz
IGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoOCgcEAAQBAgQBEgNFBA0KDgoHBAAEAQIEAhID
RRARCjgKBgQABAECBRIDSAQPGikgVGhlIHZvbHVtZSBiYWNrdXAgb3BlcmF0aW9uIGhhcyBm
YWlsZWQuCgoOCgcEAAQBAgUBEgNIBAoKDgoHBAAEAQIFAhIDSA0OCm8KBgQABAECBhIDTAQR
GmAgVGhpcyBWb2x1bWVCYWNrdXAgcmVzb3VyY2UgKGFuZCBpdHMgYXNzb2NpYXRlZCBhcnRp
ZmFjdHMpIGlzIGluIHRoZQogcHJvY2VzcyBvZiBiZWluZyBkZWxldGVkLgoKDgoHBAAEAQIG
ARIDTAQMCg4KBwQABAECBgISA0wPEApqCgYEAAQBAgcSA1AEExpbIFRoZSB1bmRlcmx5aW5n
IGFydGlmYWN0cyBvZiBhIHZvbHVtZSBiYWNrdXAgKGVnOiBwZXJzaXN0ZW50IGRpc2sKIHNu
YXBzaG90cykgYXJlIGRlbGV0ZWQuCgoOCgcEAAQBAgcBEgNQBA4KDgoHBAAEAQIHAhIDUBES
CpMBCgQEAAIAEgNVAj4ahQEgT3V0cHV0IG9ubHkuIFRoZSBmdWxsIG5hbWUgb2YgdGhlIFZv
bHVtZUJhY2t1cCByZXNvdXJjZS4KIEZvcm1hdDogYHByb2plY3RzLyovbG9jYXRpb25zLyov
YmFja3VwUGxhbnMvKi9iYWNrdXBzLyovdm9sdW1lQmFja3Vwcy8qYC4KCgwKBQQAAgAFEgNV
AggKDAoFBAACAAESA1UJDQoMCgUEAAIAAxIDVRARCgwKBQQAAgAIEgNVEj0KDwoIBAACAAic
CAASA1UTPAqWAQoEBAACARIDWQI9GogBIE91dHB1dCBvbmx5LiBTZXJ2ZXIgZ2VuZXJhdGVk
IGdsb2JhbCB1bmlxdWUgaWRlbnRpZmllciBvZgogW1VVSURdKGh0dHBzOi8vZW4ud2lraXBl
ZGlhLm9yZy93aWtpL1VuaXZlcnNhbGx5X3VuaXF1ZV9pZGVudGlmaWVyKSBmb3JtYXQuCgoM
CgUEAAIBBRIDWQIICgwKBQQAAgEBEgNZCQwKDAoFBAACAQMSA1kPEAoMCgUEAAIBCBIDWRE8
Cg8KCAQAAgEInAgAEgNZEjsKWAoEBAACAhIEXQJeMhpKIE91dHB1dCBvbmx5LiBUaGUgdGlt
ZXN0YW1wIHdoZW4gdGhpcyBWb2x1bWVCYWNrdXAgcmVzb3VyY2Ugd2FzCiBjcmVhdGVkLgoK
DAoFBAACAgYSA10CGwoMCgUEAAICARIDXRwnCgwKBQQAAgIDEgNdKisKDAoFBAACAggSA14G
MQoPCggEAAICCJwIABIDXgcwCl0KBAQAAgMSBGICYzIaTyBPdXRwdXQgb25seS4gVGhlIHRp
bWVzdGFtcCB3aGVuIHRoaXMgVm9sdW1lQmFja3VwIHJlc291cmNlIHdhcyBsYXN0CiB1cGRh
dGVkLgoKDAoFBAACAwYSA2ICGwoMCgUEAAIDARIDYhwnCgwKBQQAAgMDEgNiKisKDAoFBAAC
AwgSA2MGMQoPCggEAAIDCJwIABIDYwcwCm8KBAQAAgQSA2cCTBpiIE91dHB1dCBvbmx5LiBB
IHJlZmVyZW5jZSB0byB0aGUgc291cmNlIEt1YmVybmV0ZXMgUFZDIGZyb20gd2hpY2ggdGhp
cwogVm9sdW1lQmFja3VwIHdhcyBjcmVhdGVkLgoKDAoFBAACBAYSA2cCEAoMCgUEAAIEARID
ZxEbCgwKBQQAAgQDEgNnHh8KDAoFBAACBAgSA2cgSwoPCggEAAIECJwIABIDZyFKCmUKBAQA
AgUSA2sCThpYIE91dHB1dCBvbmx5LiBBIHN0b3JhZ2Ugc3lzdGVtLXNwZWNpZmljIG9wYXF1
ZSBoYW5kbGUgdG8gdGhlIHVuZGVybHlpbmcKIHZvbHVtZSBiYWNrdXAuCgoMCgUEAAIFBRID
awIICgwKBQQAAgUBEgNrCR0KDAoFBAACBQMSA2sgIQoMCgUEAAIFCBIDayJNCg8KCAQAAgUI
nAgAEgNrI0wKQgoEBAACBhIDbgJMGjUgT3V0cHV0IG9ubHkuIFRoZSBmb3JtYXQgdXNlZCBm
b3IgdGhlIHZvbHVtZSBiYWNrdXAuCgoMCgUEAAIGBhIDbgIUCgwKBQQAAgYBEgNuFRsKDAoF
BAACBgMSA24eHwoMCgUEAAIGCBIDbiBLCg8KCAQAAgYInAgAEgNuIUoK6gIKBAQAAgcSA3UC
RhrcAiBPdXRwdXQgb25seS4gVGhlIGFnZ3JlZ2F0ZSBzaXplIG9mIHRoZSB1bmRlcmx5aW5n
IGFydGlmYWN0cyBhc3NvY2lhdGVkIHdpdGgKIHRoaXMgVm9sdW1lQmFja3VwIGluIHRoZSBi
YWNrdXAgc3RvcmFnZS4gVGhpcyBtYXkgY2hhbmdlIG92ZXIgdGltZSB3aGVuCiBtdWx0aXBs
ZSBiYWNrdXBzIG9mIHRoZSBzYW1lIHZvbHVtZSBzaGFyZSB0aGUgc2FtZSBiYWNrdXAgc3Rv
cmFnZQogbG9jYXRpb24uIEluIHBhcnRpY3VsYXIsIHRoaXMgaXMgbGlrZWx5IHRvIGluY3Jl
YXNlIGluIHNpemUgd2hlbgogdGhlIGltbWVkaWF0ZWx5IHByZWNlZGluZyBiYWNrdXAgb2Yg
dGhlIHNhbWUgdm9sdW1lIGlzIGRlbGV0ZWQuCgoMCgUEAAIHBRIDdQIHCgwKBQQAAgcBEgN1
CBUKDAoFBAACBwMSA3UYGQoMCgUEAAIHCBIDdRpFCg8KCAQAAgcInAgAEgN1G0QKZQoEBAAC
CBIDeQJIGlggT3V0cHV0IG9ubHkuIFRoZSBtaW5pbXVtIHNpemUgb2YgdGhlIGRpc2sgdG8g
d2hpY2ggdGhpcyBWb2x1bWVCYWNrdXAgY2FuIGJlCiByZXN0b3JlZC4KCgwKBQQAAggFEgN5
AgcKDAoFBAACCAESA3kIFwoMCgUEAAIIAxIDeRobCgwKBQQAAggIEgN5HEcKDwoIBAACCAic
CAASA3kdRgptCgQEAAIJEgR9An4yGl8gT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hl
biB0aGUgYXNzb2NpYXRlZCB1bmRlcmx5aW5nIHZvbHVtZSBiYWNrdXAKIG9wZXJhdGlvbiBj
b21wbGV0ZWQuCgoMCgUEAAIJBhIDfQIbCgwKBQQAAgkBEgN9HCkKDAoFBAACCQMSA30sLgoM
CgUEAAIJCBIDfgYxCg8KCAQAAgkInAgAEgN+BzAKRAoEBAACChIEgQECPxo2IE91dHB1dCBv
bmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGlzIFZvbHVtZUJhY2t1cC4KCg0KBQQAAgoG
EgSBAQIHCg0KBQQAAgoBEgSBAQgNCg0KBQQAAgoDEgSBARASCg0KBQQAAgoIEgSBARM+ChAK
CAQAAgoInAgAEgSBARQ9CvsBCgQEAAILEgSHAQJIGuwBIE91dHB1dCBvbmx5LiBBIGh1bWFu
IHJlYWRhYmxlIG1lc3NhZ2UgZXhwbGFpbmluZyB3aHkgdGhlIFZvbHVtZUJhY2t1cCBpcyBp
bgogaXRzIGN1cnJlbnQgc3RhdGUuIFRoaXMgZmllbGQgaXMgb25seSBtZWFudCBmb3IgaHVt
YW4gY29uc3VtcHRpb24gYW5kCiBzaG91bGQgbm90IGJlIHVzZWQgcHJvZ3JhbW1hdGljYWxs
eSBhcyB0aGlzIGZpZWxkIGlzIG5vdCBndWFyYW50ZWVkIHRvIGJlCiBjb25zaXN0ZW50LgoK
DQoFBAACCwUSBIcBAggKDQoFBAACCwESBIcBCRYKDQoFBAACCwMSBIcBGRsKDQoFBAACCwgS
BIcBHEcKEAoIBAACCwicCAASBIcBHUYK0QIKBAQAAgwSBI4BAj8awgIgT3V0cHV0IG9ubHku
IGBldGFnYCBpcyB1c2VkIGZvciBvcHRpbWlzdGljIGNvbmN1cnJlbmN5IGNvbnRyb2wgYXMg
YSB3YXkgdG8KIGhlbHAgcHJldmVudCBzaW11bHRhbmVvdXMgdXBkYXRlcyBvZiBhIHZvbHVt
ZSBiYWNrdXAgZnJvbSBvdmVyd3JpdGluZyBlYWNoCiBvdGhlci4gSXQgaXMgc3Ryb25nbHkg
c3VnZ2VzdGVkIHRoYXQgc3lzdGVtcyBtYWtlIHVzZSBvZiB0aGUgYGV0YWdgIGluIHRoZQog
cmVhZC1tb2RpZnktd3JpdGUgY3ljbGUgdG8gcGVyZm9ybSB2b2x1bWUgYmFja3VwIHVwZGF0
ZXMgaW4gb3JkZXIgdG8gYXZvaWQKIHJhY2UgY29uZGl0aW9ucy4KCg0KBQQAAgwFEgSOAQII
Cg0KBQQAAgwBEgSOAQkNCg0KBQQAAgwDEgSOARASCg0KBQQAAgwIEgSOARM+ChAKCAQAAgwI
nAgAEgSOARQ9CkMKBAQAAg0SBJEBAkYaNSBPdXRwdXQgb25seS4gW091dHB1dCBPbmx5XSBS
ZXNlcnZlZCBmb3IgZnV0dXJlIHVzZS4KCg0KBQQAAg0FEgSRAQIGCg0KBQQAAg0BEgSRAQcU
Cg0KBQQAAg0DEgSRARcZCg0KBQQAAg0IEgSRARpFChAKCAQAAg0InAgAEgSRARtECkMKBAQA
Ag4SBJQBAkYaNSBPdXRwdXQgb25seS4gW091dHB1dCBPbmx5XSBSZXNlcnZlZCBmb3IgZnV0
dXJlIHVzZS4KCg0KBQQAAg4FEgSUAQIGCg0KBQQAAg4BEgSUAQcUCg0KBQQAAg4DEgSUARcZ
Cg0KBQQAAg4IEgSUARpFChAKCAQAAg4InAgAEgSUARtEClMKAgQBEgaYAQDwAQEaRSBSZXBy
ZXNlbnRzIHRoZSBvcGVyYXRpb24gb2YgcmVzdG9yaW5nIGEgdm9sdW1lIGZyb20gYSBWb2x1
bWVCYWNrdXAuCgoLCgMEAQESBJgBCBUKDQoDBAEHEgaZAQKcAQQKDwoFBAEHnQgSBpkBApwB
BAopCgQEAQQAEgafAQKlAQMaGSBTdXBwb3J0ZWQgdm9sdW1lIHR5cGVzLgoKDQoFBAEEAAES
BJ8BBxEKGQoGBAEEAAIAEgShAQQgGgkgRGVmYXVsdAoKDwoHBAEEAAIAARIEoQEEGwoPCgcE
AQQAAgACEgShAR4fCjcKBgQBBAACARIEpAEEHBonIENvbXB1dGUgRW5naW5lIFBlcnNpc3Rl
bnQgRGlzayB2b2x1bWUKCg8KBwQBBAACAQESBKQBBBcKDwoHBAEEAAIBAhIEpAEaGwo2CgQE
AQQBEgaoAQK7AQMaJiBUaGUgY3VycmVudCBzdGF0ZSBvZiBhIFZvbHVtZVJlc3RvcmUKCg0K
BQQBBAEBEgSoAQcMCkkKBgQBBAECABIEqgEEGho5IFRoaXMgaXMgYW4gaWxsZWdhbCBzdGF0
ZSBhbmQgc2hvdWxkIG5vdCBiZSBlbmNvdW50ZXJlZC4KCg8KBwQBBAECAAESBKoBBBUKDwoH
BAEEAQIAAhIEqgEYGQphCgYEAQQBAgESBK4BBBEaUSBBIHZvbHVtZSBmb3IgdGhlIHJlc3Rv
cmUgd2FzIGlkZW50aWZpZWQgYW5kIHJlc3RvcmUgcHJvY2VzcyBpcyBhYm91dCB0bwogc3Rh
cnQuCgoPCgcEAQQBAgEBEgSuAQQMCg8KBwQBBAECAQISBK4BDxAKOQoGBAEEAQICEgSxAQQS
GikgVGhlIHZvbHVtZSBpcyBjdXJyZW50bHkgYmVpbmcgcmVzdG9yZWQuCgoPCgcEAQQBAgIB
EgSxAQQNCg8KBwQBBAECAgISBLEBEBEKPAoGBAEEAQIDEgS0AQQSGiwgVGhlIHZvbHVtZSBo
YXMgYmVlbiBzdWNjZXNzZnVsbHkgcmVzdG9yZWQuCgoPCgcEAQQBAgMBEgS0AQQNCg8KBwQB
BAECAwISBLQBEBEKOAoGBAEEAQIEEgS3AQQPGiggVGhlIHZvbHVtZSByZXN0b3JhdGlvbiBw
cm9jZXNzIGZhaWxlZC4KCg8KBwQBBAECBAESBLcBBAoKDwoHBAEEAQIEAhIEtwENDgpRCgYE
AQQBAgUSBLoBBBEaQSBUaGlzIFZvbHVtZVJlc3RvcmUgcmVzb3VyY2UgaXMgaW4gdGhlIHBy
b2Nlc3Mgb2YgYmVpbmcgZGVsZXRlZC4KCg8KBwQBBAECBQESBLoBBAwKDwoHBAEEAQIFAhIE
ugEPEAqTAQoEBAECABIEvwECPhqEASBPdXRwdXQgb25seS4gRnVsbCBuYW1lIG9mIHRoZSBW
b2x1bWVSZXN0b3JlIHJlc291cmNlLgogRm9ybWF0OiBgcHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9yZXN0b3JlUGxhbnMvKi9yZXN0b3Jlcy8qL3ZvbHVtZVJlc3RvcmVzLypgCgoNCgUEAQIA
BRIEvwECCAoNCgUEAQIAARIEvwEJDQoNCgUEAQIAAxIEvwEQEQoNCgUEAQIACBIEvwESPQoQ
CggEAQIACJwIABIEvwETPAqXAQoEBAECARIEwwECPRqIASBPdXRwdXQgb25seS4gU2VydmVy
IGdlbmVyYXRlZCBnbG9iYWwgdW5pcXVlIGlkZW50aWZpZXIgb2YKIFtVVUlEXShodHRwczov
L2VuLndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxseV91bmlxdWVfaWRlbnRpZmllcikg
Zm9ybWF0LgoKDQoFBAECAQUSBMMBAggKDQoFBAECAQESBMMBCQwKDQoFBAECAQMSBMMBDxAK
DQoFBAECAQgSBMMBETwKEAoIBAECAQicCAASBMMBEjsKWwoEBAECAhIGxwECyAEyGksgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIFZvbHVtZVJlc3RvcmUgcmVzb3Vy
Y2Ugd2FzCiBjcmVhdGVkLgoKDQoFBAECAgYSBMcBAhsKDQoFBAECAgESBMcBHCcKDQoFBAEC
AgMSBMcBKisKDQoFBAECAggSBMgBBjEKEAoIBAECAgicCAASBMgBBzAKYAoEBAECAxIGzAEC
zQEyGlAgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIFZvbHVtZVJlc3Rv
cmUgcmVzb3VyY2Ugd2FzIGxhc3QKIHVwZGF0ZWQuCgoNCgUEAQIDBhIEzAECGwoNCgUEAQID
ARIEzAEcJwoNCgUEAQIDAxIEzAEqKwoNCgUEAQIDCBIEzQEGMQoQCggEAQIDCJwIABIEzQEH
MAqzAQoEBAECBBIE0gECRxqkASBPdXRwdXQgb25seS4gVGhlIGZ1bGwgbmFtZSBvZiB0aGUg
Vm9sdW1lQmFja3VwIGZyb20gd2hpY2ggdGhlIHZvbHVtZSB3aWxsCiBiZSByZXN0b3JlZC4g
Rm9ybWF0OgogYHByb2plY3RzLyovbG9jYXRpb25zLyovYmFja3VwUGxhbnMvKi9iYWNrdXBz
Lyovdm9sdW1lQmFja3Vwcy8qYC4KCg0KBQQBAgQFEgTSAQIICg0KBQQBAgQBEgTSAQkWCg0K
BQQBAgQDEgTSARkaCg0KBQQBAgQIEgTSARtGChAKCAQBAgQInAgAEgTSARxFClcKBAQBAgUS
BNUBAkwaSSBPdXRwdXQgb25seS4gVGhlIHJlZmVyZW5jZSB0byB0aGUgdGFyZ2V0IEt1YmVy
bmV0ZXMgUFZDIHRvIGJlIHJlc3RvcmVkLgoKDQoFBAECBQYSBNUBAhAKDQoFBAECBQESBNUB
ERsKDQoFBAECBQMSBNUBHh8KDQoFBAECBQgSBNUBIEsKEAoIBAECBQicCAASBNUBIUoKkwEK
BAQBAgYSBNkBAkcahAEgT3V0cHV0IG9ubHkuIEEgc3RvcmFnZSBzeXN0ZW0tc3BlY2lmaWMg
b3BhcXVlIGhhbmRsZXIgdG8gdGhlIHVuZGVybHlpbmcKIHZvbHVtZSBjcmVhdGVkIGZvciB0
aGUgdGFyZ2V0IFBWQyBmcm9tIHRoZSB2b2x1bWUgYmFja3VwLgoKDQoFBAECBgUSBNkBAggK
DQoFBAECBgESBNkBCRYKDQoFBAECBgMSBNkBGRoKDQoFBAECBggSBNkBG0YKEAoIBAECBgic
CAASBNkBHEUKOwoEBAECBxIE3AECSRotIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB2b2x1
bWUgcHJvdmlzaW9uZWQKCg0KBQQBAgcGEgTcAQIMCg0KBQQBAgcBEgTcAQ0YCg0KBQQBAgcD
EgTcARscCg0KBQQBAgcIEgTcAR1IChAKCAQBAgcInAgAEgTcAR5HCmoKBAQBAggSBuABAuEB
MhpaIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIGFzc29jaWF0ZWQgdW5k
ZXJseWluZyB2b2x1bWUKIHJlc3RvcmF0aW9uIGNvbXBsZXRlZC4KCg0KBQQBAggGEgTgAQIb
Cg0KBQQBAggBEgTgARwpCg0KBQQBAggDEgTgASwtCg0KBQQBAggIEgThAQYxChAKCAQBAggI
nAgAEgThAQcwCkUKBAQBAgkSBOQBAj8aNyBPdXRwdXQgb25seS4gVGhlIGN1cnJlbnQgc3Rh
dGUgb2YgdGhpcyBWb2x1bWVSZXN0b3JlLgoKDQoFBAECCQYSBOQBAgcKDQoFBAECCQESBOQB
CA0KDQoFBAECCQMSBOQBEBIKDQoFBAECCQgSBOQBEz4KEAoIBAECCQicCAASBOQBFD0KcAoE
BAECChIE6AECSBpiIE91dHB1dCBvbmx5LiBBIGh1bWFuIHJlYWRhYmxlIG1lc3NhZ2UgZXhw
bGFpbmluZyB3aHkgdGhlIFZvbHVtZVJlc3RvcmUgaXMKIGluIGl0cyBjdXJyZW50IHN0YXRl
LgoKDQoFBAECCgUSBOgBAggKDQoFBAECCgESBOgBCRYKDQoFBAECCgMSBOgBGRsKDQoFBAEC
CggSBOgBHEcKEAoIBAECCgicCAASBOgBHUYK0wIKBAQBAgsSBO8BAj8axAIgT3V0cHV0IG9u
bHkuIGBldGFnYCBpcyB1c2VkIGZvciBvcHRpbWlzdGljIGNvbmN1cnJlbmN5IGNvbnRyb2wg
YXMgYSB3YXkgdG8KIGhlbHAgcHJldmVudCBzaW11bHRhbmVvdXMgdXBkYXRlcyBvZiBhIHZv
bHVtZSByZXN0b3JlIGZyb20gb3ZlcndyaXRpbmcgZWFjaAogb3RoZXIuIEl0IGlzIHN0cm9u
Z2x5IHN1Z2dlc3RlZCB0aGF0IHN5c3RlbXMgbWFrZSB1c2Ugb2YgdGhlIGBldGFnYCBpbiB0
aGUKIHJlYWQtbW9kaWZ5LXdyaXRlIGN5Y2xlIHRvIHBlcmZvcm0gdm9sdW1lIHJlc3RvcmUg
dXBkYXRlcyBpbiBvcmRlciB0byBhdm9pZAogcmFjZSBjb25kaXRpb25zLgoKDQoFBAECCwUS
BO8BAggKDQoFBAECCwESBO8BCQ0KDQoFBAECCwMSBO8BEBIKDQoFBAECCwgSBO8BEz4KEAoI
BAECCwicCAASBO8BFD1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::Volume::VolumeBackup ===
    # Fields for VolumeBackup
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: source_pvc Type: 11 (.google.cloud.gkebackup.v1.NamespacedName)
    # Field: volume_backup_handle Type: 9 ()
    # Field: format Type: 14 (.google.cloud.gkebackup.v1.VolumeBackup.VolumeBackupFormat)
    # Field: storage_bytes Type: 3 ()
    # Field: disk_size_bytes Type: 3 ()
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.gkebackup.v1.VolumeBackup.State)
    # Field: state_message Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()

# Enum: VolumeBackup::VolumeBackupFormat
our $VolumeBackup_VOLUME_BACKUP_FORMAT_UNSPECIFIED = 0;
our $VolumeBackup_GCE_PERSISTENT_DISK = 1;

# Enum: VolumeBackup::State
our $VolumeBackup_STATE_UNSPECIFIED = 0;
our $VolumeBackup_CREATING = 1;
our $VolumeBackup_SNAPSHOTTING = 2;
our $VolumeBackup_UPLOADING = 3;
our $VolumeBackup_SUCCEEDED = 4;
our $VolumeBackup_FAILED = 5;
our $VolumeBackup_DELETING = 6;
our $VolumeBackup_CLEANED_UP = 7;

# === Message: Google::Cloud::Gkebackup::V1::Volume::VolumeRestore ===
    # Fields for VolumeRestore
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: volume_backup Type: 9 ()
    # Field: target_pvc Type: 11 (.google.cloud.gkebackup.v1.NamespacedName)
    # Field: volume_handle Type: 9 ()
    # Field: volume_type Type: 14 (.google.cloud.gkebackup.v1.VolumeRestore.VolumeType)
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.gkebackup.v1.VolumeRestore.State)
    # Field: state_message Type: 9 ()
    # Field: etag Type: 9 ()

# Enum: VolumeRestore::VolumeType
our $VolumeRestore_VOLUME_TYPE_UNSPECIFIED = 0;
our $VolumeRestore_GCE_PERSISTENT_DISK = 1;

# Enum: VolumeRestore::State
our $VolumeRestore_STATE_UNSPECIFIED = 0;
our $VolumeRestore_CREATING = 1;
our $VolumeRestore_RESTORING = 2;
our $VolumeRestore_SUCCEEDED = 3;
our $VolumeRestore_FAILED = 4;
our $VolumeRestore_DELETING = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::Volume - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/volume.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::Volume;

    my $msg = Google::Cloud::Gkebackup::V1::Volume::VolumeBackup->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::Volume::VolumeBackup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/volume.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::Volume::VolumeBackup

Represents the backup of a specific persistent volume as a component of a
Backup - both the record of the operation and a pointer to the underlying
storage-specific artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full name of the VolumeBackup resource.
Format: `projects/*/locations/*/backupPlans/*/backups/*/volumeBackups/*`.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this VolumeBackup resource was
created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this VolumeBackup resource was last
updated.

=item * C<< $msg->source_pvc() >> / C<< $msg->source_pvc($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Common::NamespacedName>)

Output only. A reference to the source Kubernetes PVC from which this
VolumeBackup was created.

=item * C<< $msg->volume_backup_handle() >> / C<< $msg->volume_backup_handle($value) >>

Type: C<String>

Output only. A storage system-specific opaque handle to the underlying
volume backup.

=item * C<< $msg->format() >> / C<< $msg->format($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::VolumeBackup::VolumeBackupFormat>)

Output only. The format used for the volume backup.

=item * C<< $msg->storage_bytes() >> / C<< $msg->storage_bytes($value) >>

Type: C<Int64>

Output only. The aggregate size of the underlying artifacts associated with
this VolumeBackup in the backup storage. This may change over time when
multiple backups of the same volume share the same backup storage
location. In particular, this is likely to increase in size when
the immediately preceding backup of the same volume is deleted.

=item * C<< $msg->disk_size_bytes() >> / C<< $msg->disk_size_bytes($value) >>

Type: C<Int64>

Output only. The minimum size of the disk to which this VolumeBackup can be
restored.

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the associated underlying volume backup
operation completed.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::VolumeBackup::State>)

Output only. The current state of this VolumeBackup.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

Output only. A human readable message explaining why the VolumeBackup is in
its current state. This field is only meant for human consumption and
should not be used programmatically as this field is not guaranteed to be
consistent.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a volume backup from overwriting each
other. It is strongly suggested that systems make use of the `etag` in the
read-modify-write cycle to perform volume backup updates in order to avoid
race conditions.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. [Output Only] Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. [Output Only] Reserved for future use.

=back

=head3 Enum: VolumeBackup::VolumeBackupFormat

=over 4

=item * C<VOLUME_BACKUP_FORMAT_UNSPECIFIED> => C<0>

=item * C<GCE_PERSISTENT_DISK> => C<1>

=back

=head3 Enum: VolumeBackup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<SNAPSHOTTING> => C<2>

=item * C<UPLOADING> => C<3>

=item * C<SUCCEEDED> => C<4>

=item * C<FAILED> => C<5>

=item * C<DELETING> => C<6>

=item * C<CLEANED_UP> => C<7>

=back

=head2 Google::Cloud::Gkebackup::V1::Volume::VolumeRestore

Represents the operation of restoring a volume from a VolumeBackup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Full name of the VolumeRestore resource.
Format: `projects/*/locations/*/restorePlans/*/restores/*/volumeRestores/*`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this VolumeRestore resource was
created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this VolumeRestore resource was last
updated.

=item * C<< $msg->volume_backup() >> / C<< $msg->volume_backup($value) >>

Type: C<String>

Output only. The full name of the VolumeBackup from which the volume will
be restored. Format:
`projects/*/locations/*/backupPlans/*/backups/*/volumeBackups/*`.

=item * C<< $msg->target_pvc() >> / C<< $msg->target_pvc($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Common::NamespacedName>)

Output only. The reference to the target Kubernetes PVC to be restored.

=item * C<< $msg->volume_handle() >> / C<< $msg->volume_handle($value) >>

Type: C<String>

Output only. A storage system-specific opaque handler to the underlying
volume created for the target PVC from the volume backup.

=item * C<< $msg->volume_type() >> / C<< $msg->volume_type($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::VolumeRestore::VolumeType>)

Output only. The type of volume provisioned

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the associated underlying volume
restoration completed.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::VolumeRestore::State>)

Output only. The current state of this VolumeRestore.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

Output only. A human readable message explaining why the VolumeRestore is
in its current state.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a volume restore from overwriting each
other. It is strongly suggested that systems make use of the `etag` in the
read-modify-write cycle to perform volume restore updates in order to avoid
race conditions.

=back

=head3 Enum: VolumeRestore::VolumeType

=over 4

=item * C<VOLUME_TYPE_UNSPECIFIED> => C<0>

=item * C<GCE_PERSISTENT_DISK> => C<1>

=back

=head3 Enum: VolumeRestore::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<RESTORING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<DELETING> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::Volume::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
