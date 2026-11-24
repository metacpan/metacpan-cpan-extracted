package Google::Cloud::Gkehub::V1alpha::Service;

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
    eval { require Google::Cloud::Gkehub::V1alpha::Feature };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEvc2VydmljZS5wcm90bxIbZ29vZ2xlLmNs
b3VkLmdrZWh1Yi52MWFscGhhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxop
Z29vZ2xlL2Nsb3VkL2drZWh1Yi92MWFscGhhL2ZlYXR1cmUucHJvdG8aI2dvb2dsZS9sb25n
cnVubmluZy9vcGVyYXRpb25zLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5w
cm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKcAQoTTGlzdEZlYXR1cmVz
UmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlS
BmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSKCAQoUTGlzdEZlYXR1cmVzUmVz
cG9uc2USQgoJcmVzb3VyY2VzGAEgAygLMiQuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWFscGhh
LkZlYXR1cmVSCXJlc291cmNlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4iJwoRR2V0RmVhdHVyZVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZSKzAQoUQ3Jl
YXRlRmVhdHVyZVJlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQSHQoKZmVhdHVyZV9p
ZBgCIAEoCVIJZmVhdHVyZUlkEkAKCHJlc291cmNlGAMgASgLMiQuZ29vZ2xlLmNsb3VkLmdr
ZWh1Yi52MWFscGhhLkZlYXR1cmVSCHJlc291cmNlEiIKCnJlcXVlc3RfaWQYBCABKAlCA+BB
AVIJcmVxdWVzdElkImQKFERlbGV0ZUZlYXR1cmVSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5h
bWUSFAoFZm9yY2UYAiABKAhSBWZvcmNlEiIKCnJlcXVlc3RfaWQYAyABKAlCA+BBAVIJcmVx
dWVzdElkIs0BChRVcGRhdGVGZWF0dXJlUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEjsK
C3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRl
TWFzaxJACghyZXNvdXJjZRgDIAEoCzIkLmdvb2dsZS5jbG91ZC5na2VodWIudjFhbHBoYS5G
ZWF0dXJlUghyZXNvdXJjZRIiCgpyZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJlcXVlc3RJZCLH
AgoRT3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJ
QgPgQQNSBnRhcmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKAoNc3RhdHVzX2RldGFp
bBgFIAEoCUID4EEDUgxzdGF0dXNEZXRhaWwSLgoQY2FuY2VsX3JlcXVlc3RlZBgGIAEoCEID
4EEDUg9jYW5jZWxSZXF1ZXN0ZWQSJAoLYXBpX3ZlcnNpb24YByABKAlCA+BBA1IKYXBpVmVy
c2lvbjLQCAoGR2tlSHViErcBCgxMaXN0RmVhdHVyZXMSMC5nb29nbGUuY2xvdWQuZ2tlaHVi
LnYxYWxwaGEuTGlzdEZlYXR1cmVzUmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5na2VodWIudjFh
bHBoYS5MaXN0RmVhdHVyZXNSZXNwb25zZSJCgtPkkwIzEjEvdjFhbHBoYS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyp9L2ZlYXR1cmVz2kEGcGFyZW50EqQBCgpHZXRGZWF0dXJl
Ei4uZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWFscGhhLkdldEZlYXR1cmVSZXF1ZXN0GiQuZ29v
Z2xlLmNsb3VkLmdrZWh1Yi52MWFscGhhLkZlYXR1cmUiQILT5JMCMxIxL3YxYWxwaGEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9mZWF0dXJlcy8qfdpBBG5hbWUS4gEKDUNyZWF0
ZUZlYXR1cmUSMS5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYWxwaGEuQ3JlYXRlRmVhdHVyZVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn+C0+STAj0iMS92MWFscGhh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZmVhdHVyZXM6CHJlc291cmNl2kEa
cGFyZW50LHJlc291cmNlLGZlYXR1cmVfaWTKQRwKB0ZlYXR1cmUSEU9wZXJhdGlvbk1ldGFk
YXRhEtABCg1EZWxldGVGZWF0dXJlEjEuZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWFscGhhLkRl
bGV0ZUZlYXR1cmVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJtgtPk
kwIzKjEvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2ZlYXR1cmVzLyp9
2kEEbmFtZcpBKgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRLh
AQoNVXBkYXRlRmVhdHVyZRIxLmdvb2dsZS5jbG91ZC5na2VodWIudjFhbHBoYS5VcGRhdGVG
ZWF0dXJlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ifoLT5JMCPTIx
L3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9mZWF0dXJlcy8qfToIcmVz
b3VyY2XaQRluYW1lLHJlc291cmNlLHVwZGF0ZV9tYXNrykEcCgdGZWF0dXJlEhFPcGVyYXRp
b25NZXRhZGF0YRpJykEVZ2tlaHViLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULHAQofY29tLmdvb2dsZS5jbG91ZC5n
a2VodWIudjFhbHBoYUIMU2VydmljZVByb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tl
aHViL2FwaXYxYWxwaGEvZ2tlaHVicGI7Z2tlaHVicGKqAhtHb29nbGUuQ2xvdWQuR2tlSHVi
LlYxQWxwaGHKAhtHb29nbGVcQ2xvdWRcR2tlSHViXFYxYWxwaGHqAh5Hb29nbGU6OkNsb3Vk
OjpHa2VIdWI6OlYxYWxwaGFKgU4KBxIFDgCXAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkK
CQoCAwMSAxUAMwoJCgIDBBIDFgAtCgkKAgMFEgMXACoKCQoCAwYSAxgAKQoICgEIEgMaADgK
CQoCCCUSAxoAOAoICgEIEgMbAE4KCQoCCAsSAxsATgoICgEIEgMcACIKCQoCCAoSAxwAIgoI
CgEIEgMdAC0KCQoCCAgSAx0ALQoICgEIEgMeADgKCQoCCAESAx4AOAoICgEIEgMfADgKCQoC
CCkSAx8AOAoICgEIEgMgADcKCQoCCC0SAyAANwrFBAoCBgASBDAAaQEauAQgVGhlIEdLRSBI
dWIgc2VydmljZSBoYW5kbGVzIHRoZSByZWdpc3RyYXRpb24gb2YgbWFueSBLdWJlcm5ldGVz
IGNsdXN0ZXJzIHRvCiBHb29nbGUgQ2xvdWQsIGFuZCB0aGUgbWFuYWdlbWVudCBvZiBtdWx0
aS1jbHVzdGVyIGZlYXR1cmVzIG92ZXIgdGhvc2UKIGNsdXN0ZXJzLgoKIFRoZSBHS0UgSHVi
IHNlcnZpY2Ugb3BlcmF0ZXMgb24gdGhlIGZvbGxvd2luZyByZXNvdXJjZXM6CgogKiBbTWVt
YmVyc2hpcF1bZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWFscGhhLk1lbWJlcnNoaXBdCiAqIFtG
ZWF0dXJlXVtnb29nbGUuY2xvdWQuZ2tlaHViLnYxYWxwaGEuRmVhdHVyZV0KCiBHS0UgSHVi
IGlzIGN1cnJlbnRseSBvbmx5IGF2YWlsYWJsZSBpbiB0aGUgZ2xvYmFsIHJlZ2lvbi4KCiAq
Kk1lbWJlcnNoaXAgbWFuYWdlbWVudCBtYXkgYmUgbm9uLXRyaXZpYWw6KiogaXQgaXMgcmVj
b21tZW5kZWQgdG8gdXNlIG9uZQogb2YgdGhlIEdvb2dsZS1wcm92aWRlZCBjbGllbnQgbGli
cmFyaWVzIG9yIHRvb2xzIHdoZXJlIHBvc3NpYmxlIHdoZW4gd29ya2luZwogd2l0aCBNZW1i
ZXJzaGlwIHJlc291cmNlcy4KCgoKAwYAARIDMAgOCgoKAwYAAxIDMQI9CgwKBQYAA5kIEgMx
Aj0KCgoDBgADEgMyAlYKDAoFBgADmggSAzICVgo/CgQGAAIAEgQ1AjoDGjEgTGlzdHMgRmVh
dHVyZXMgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgM1BhIK
DAoFBgACAAISAzUTJgoMCgUGAAIAAxIDNTFFCg0KBQYAAgAEEgQ2BDgGChEKCQYAAgAEsMq8
IhIENgQ4BgoMCgUGAAIABBIDOQQ0Cg8KCAYAAgAEmwgAEgM5BDQKMQoEBgACARIEPQJCAxoj
IEdldHMgZGV0YWlscyBvZiBhIHNpbmdsZSBGZWF0dXJlLgoKDAoFBgACAQESAz0GEAoMCgUG
AAIBAhIDPREiCgwKBQYAAgEDEgM9LTQKDQoFBgACAQQSBD4EQAYKEQoJBgACAQSwyrwiEgQ+
BEAGCgwKBQYAAgEEEgNBBDIKDwoIBgACAQSbCAASA0EEMgojCgQGAAICEgRFAk8DGhUgQWRk
cyBhIG5ldyBGZWF0dXJlLgoKDAoFBgACAgESA0UGEwoMCgUGAAICAhIDRRQoCgwKBQYAAgID
EgNFM08KDQoFBgACAgQSBEYESQYKEQoJBgACAgSwyrwiEgRGBEkGCgwKBQYAAgIEEgNKBEgK
DwoIBgACAgSbCAASA0oESAoNCgUGAAICBBIESwROBgoPCgcGAAICBJkIEgRLBE4GCiIKBAYA
AgMSBFICWwMaFCBSZW1vdmVzIGEgRmVhdHVyZS4KCgwKBQYAAgMBEgNSBhMKDAoFBgACAwIS
A1IUKAoMCgUGAAIDAxIDUjNPCg0KBQYAAgMEEgRTBFUGChEKCQYAAgMEsMq8IhIEUwRVBgoM
CgUGAAIDBBIDVgQyCg8KCAYAAgMEmwgAEgNWBDIKDQoFBgACAwQSBFcEWgYKDwoHBgACAwSZ
CBIEVwRaBgosCgQGAAIEEgReAmgDGh4gVXBkYXRlcyBhbiBleGlzdGluZyBGZWF0dXJlLgoK
DAoFBgACBAESA14GEwoMCgUGAAIEAhIDXhQoCgwKBQYAAgQDEgNeM08KDQoFBgACBAQSBF8E
YgYKEQoJBgACBASwyrwiEgRfBGIGCgwKBQYAAgQEEgNjBEcKDwoIBgACBASbCAASA2MERwoN
CgUGAAIEBBIEZARnBgoPCgcGAAIEBJkIEgRkBGcGCkAKAgQAEgVsAJABARozIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgYEdrZUh1Yi5MaXN0RmVhdHVyZXNgIG1ldGhvZC4KCgoKAwQAARIDbAgb
CoYBCgQEAAIAEgNvAhQaeSBUaGUgcGFyZW50IChwcm9qZWN0IGFuZCBsb2NhdGlvbikgd2hl
cmUgdGhlIEZlYXR1cmVzIHdpbGwgYmUgbGlzdGVkLgogU3BlY2lmaWVkIGluIHRoZSBmb3Jt
YXQgYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoKDAoFBAACAAUSA28CCAoMCgUEAAIAARID
bwkPCgwKBQQAAgADEgNvEhMKqQEKBAQAAgESA3QCFhqbASBXaGVuIHJlcXVlc3RpbmcgYSAn
cGFnZScgb2YgcmVzb3VyY2VzLCBgcGFnZV9zaXplYCBzcGVjaWZpZXMgbnVtYmVyIG9mCiBy
ZXNvdXJjZXMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCBvciBzZXQgdG8gMCwgYWxsIHJl
c291cmNlcyB3aWxsCiBiZSByZXR1cm5lZC4KCgwKBQQAAgEFEgN0AgcKDAoFBAACAQESA3QI
EQoMCgUEAAIBAxIDdBQVCpoBCgQEAAICEgN5AhgajAEgVG9rZW4gcmV0dXJuZWQgYnkgcHJl
dmlvdXMgY2FsbCB0byBgTGlzdEZlYXR1cmVzYCB3aGljaAogc3BlY2lmaWVzIHRoZSBwb3Np
dGlvbiBpbiB0aGUgbGlzdCBmcm9tIHdoZXJlIHRvIGNvbnRpbnVlIGxpc3RpbmcgdGhlCiBy
ZXNvdXJjZXMuCgoMCgUEAAICBRIDeQIICgwKBQQAAgIBEgN5CRMKDAoFBAACAgMSA3kWFwq2
AwoEBAACAxIEiwECFBqnAyBMaXN0cyBGZWF0dXJlcyB0aGF0IG1hdGNoIHRoZSBmaWx0ZXIg
ZXhwcmVzc2lvbiwgZm9sbG93aW5nIHRoZSBzeW50YXgKIG91dGxpbmVkIGluIGh0dHBzOi8v
Z29vZ2xlLmFpcC5kZXYvMTYwLgoKIEV4YW1wbGVzOgoKICAgLSBGZWF0dXJlIHdpdGggdGhl
IG5hbWUgInNlcnZpY2VtZXNoIiBpbiBwcm9qZWN0ICJmb28tcHJvaiI6CgogICAgICAgbmFt
ZSA9ICJwcm9qZWN0cy9mb28tcHJvai9sb2NhdGlvbnMvZ2xvYmFsL2ZlYXR1cmVzL3NlcnZp
Y2VtZXNoIgoKICAgLSBGZWF0dXJlcyB0aGF0IGhhdmUgYSBsYWJlbCBjYWxsZWQgYGZvb2A6
CgogICAgICAgbGFiZWxzLmZvbzoqCgogICAtIEZlYXR1cmVzIHRoYXQgaGF2ZSBhIGxhYmVs
IGNhbGxlZCBgZm9vYCB3aG9zZSB2YWx1ZSBpcyBgYmFyYDoKCiAgICAgICBsYWJlbHMuZm9v
ID0gYmFyCgoNCgUEAAIDBRIEiwECCAoNCgUEAAIDARIEiwEJDwoNCgUEAAIDAxIEiwESEwpz
CgQEAAIEEgSPAQIWGmUgT25lIG9yIG1vcmUgZmllbGRzIHRvIGNvbXBhcmUgYW5kIHVzZSB0
byBzb3J0IHRoZSBvdXRwdXQuCiBTZWUgaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xMzIjb3Jk
ZXJpbmcuCgoNCgUEAAIEBRIEjwECCAoNCgUEAAIEARIEjwEJEQoNCgUEAAIEAxIEjwEUFQpG
CgIEARIGkwEAmwEBGjggUmVzcG9uc2UgbWVzc2FnZSBmb3IgdGhlIGBHa2VIdWIuTGlzdEZl
YXR1cmVzYCBtZXRob2QuCgoLCgMEAQESBJMBCBwKLQoEBAECABIElQECIRofIFRoZSBsaXN0
IG9mIG1hdGNoaW5nIEZlYXR1cmVzCgoNCgUEAQIABBIElQECCgoNCgUEAQIABhIElQELEgoN
CgUEAQIAARIElQETHAoNCgUEAQIAAxIElQEfIAqvAQoEBAECARIEmgECHRqgASBBIHRva2Vu
IHRvIHJlcXVlc3QgdGhlIG5leHQgcGFnZSBvZiByZXNvdXJjZXMgZnJvbSB0aGUKIGBMaXN0
RmVhdHVyZXNgIG1ldGhvZC4gVGhlIHZhbHVlIG9mIGFuIGVtcHR5IHN0cmluZyBtZWFucwog
dGhhdCB0aGVyZSBhcmUgbm8gbW9yZSByZXNvdXJjZXMgdG8gcmV0dXJuLgoKDQoFBAECAQUS
BJoBAggKDQoFBAECAQESBJoBCRgKDQoFBAECAQMSBJoBGxwKPwoCBAISBp4BAKIBARoxIFJl
cXVlc3QgbWVzc2FnZSBmb3IgYEdrZUh1Yi5HZXRGZWF0dXJlYCBtZXRob2QuCgoLCgMEAgES
BJ4BCBkKXAoEBAICABIEoQECEhpOIFRoZSBGZWF0dXJlIHJlc291cmNlIG5hbWUgaW4gdGhl
IGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovZmVhdHVyZXMvKmAKCg0KBQQCAgAF
EgShAQIICg0KBQQCAgABEgShAQkNCg0KBQQCAgADEgShARARCkYKAgQDEgalAQC+AQEaOCBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBgR2tlSHViLkNyZWF0ZUZlYXR1cmVgIG1ldGhvZC4K
CgsKAwQDARIEpQEIHAqHAQoEBAMCABIEqAECFBp5IFRoZSBwYXJlbnQgKHByb2plY3QgYW5k
IGxvY2F0aW9uKSB3aGVyZSB0aGUgRmVhdHVyZSB3aWxsIGJlIGNyZWF0ZWQuCiBTcGVjaWZp
ZWQgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKmAuCgoNCgUEAwIABRIE
qAECCAoNCgUEAwIAARIEqAEJDwoNCgUEAwIAAxIEqAESEwowCgQEAwIBEgSrAQIYGiIgVGhl
IElEIG9mIHRoZSBmZWF0dXJlIHRvIGNyZWF0ZS4KCg0KBQQDAgEFEgSrAQIICg0KBQQDAgEB
EgSrAQkTCg0KBQQDAgEDEgSrARYXCi8KBAQDAgISBK4BAhcaISBUaGUgRmVhdHVyZSByZXNv
dXJjZSB0byBjcmVhdGUuCgoNCgUEAwICBhIErgECCQoNCgUEAwICARIErgEKEgoNCgUEAwIC
AxIErgEVFgqFBgoEBAMCAxIEvQECQRr2BSBPcHRpb25hbC4gQSByZXF1ZXN0IElEIHRvIGlk
ZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQKIHNvIHRoYXQg
aWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0
byBpZ25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVk
LiBUaGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51
dGVzIGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBh
IHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUg
cmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGgg
dGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFs
IG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5k
IGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMK
IGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1l
bnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4
Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAw
MC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQDAgMFEgS9AQIICg0KBQQDAgMBEgS9
AQkTCg0KBQQDAgMDEgS9ARYXCg0KBQQDAgMIEgS9ARhAChAKCAQDAgMInAgAEgS9ARk/CkIK
AgQEEgbBAQDZAQEaNCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBHa2VIdWIuRGVsZXRlRmVhdHVy
ZWAgbWV0aG9kLgoKCwoDBAQBEgTBAQgcCl0KBAQEAgASBMQBAhIaTyBUaGUgRmVhdHVyZSBy
ZXNvdXJjZSBuYW1lIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Zl
YXR1cmVzLypgLgoKDQoFBAQCAAUSBMQBAggKDQoFBAQCAAESBMQBCQ0KDQoFBAQCAAMSBMQB
EBEK2wEKBAQEAgESBMkBAhEazAEgSWYgc2V0IHRvIHRydWUsIHRoZSBkZWxldGUgd2lsbCBp
Z25vcmUgYW55IG91dHN0YW5kaW5nIHJlc291cmNlcyBmb3IKIHRoaXMgRmVhdHVyZSAodGhh
dCBpcywgYEZlYXR1cmVTdGF0ZS5oYXNfcmVzb3VyY2VzYCBpcyBzZXQgdG8gdHJ1ZSkuIFRo
ZXNlCiByZXNvdXJjZXMgd2lsbCBOT1QgYmUgY2xlYW5lZCB1cCBvciBtb2RpZmllZCBpbiBh
bnkgd2F5LgoKDQoFBAQCAQUSBMkBAgYKDQoFBAQCAQESBMkBBwwKDQoFBAQCAQMSBMkBDxAK
hQYKBAQEAgISBNgBAkEa9gUgT3B0aW9uYWwuIEEgcmVxdWVzdCBJRCB0byBpZGVudGlmeSBy
ZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1ZXN0IElECiBzbyB0aGF0IGlmIHlvdSBt
dXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8gaWdub3Jl
CiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNl
cnZlciB3aWxsIGd1YXJhbnRlZQogdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBhZnRl
ciB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRp
b24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZAogdGhlIHJlcXVlc3Qg
dGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1l
IHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRp
b24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywg
d2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBjbGllbnRz
IGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBU
aGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24g
dGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0w
MDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBAICBRIE2AECCAoNCgUEBAICARIE2AEJEwoNCgUE
BAICAxIE2AEWFwoNCgUEBAICCBIE2AEYQAoQCggEBAICCJwIABIE2AEZPwpCCgIEBRIG3AEA
/AEBGjQgUmVxdWVzdCBtZXNzYWdlIGZvciBgR2tlSHViLlVwZGF0ZUZlYXR1cmVgIG1ldGhv
ZC4KCgsKAwQFARIE3AEIHApdCgQEBQIAEgTfAQISGk8gVGhlIEZlYXR1cmUgcmVzb3VyY2Ug
bmFtZSBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9mZWF0dXJlcy8q
YC4KCg0KBQQFAgAFEgTfAQIICg0KBQQFAgABEgTfAQkNCg0KBQQFAgADEgTfARARCikKBAQF
AgESBOIBAiwaGyBNYXNrIG9mIGZpZWxkcyB0byB1cGRhdGUuCgoNCgUEBQIBBhIE4gECGwoN
CgUEBQIBARIE4gEcJwoNCgUEBQIBAxIE4gEqKwrXAwoEBAUCAhIE7AECFxrIAyBPbmx5IGZp
ZWxkcyBzcGVjaWZpZWQgaW4gdXBkYXRlX21hc2sgYXJlIHVwZGF0ZWQuCiBJZiB5b3Ugc3Bl
Y2lmeSBhIGZpZWxkIGluIHRoZSB1cGRhdGVfbWFzayBidXQgZG9uJ3Qgc3BlY2lmeSBpdHMg
dmFsdWUgaGVyZQogdGhhdCBmaWVsZCB3aWxsIGJlIGRlbGV0ZWQuCiBJZiB5b3UgYXJlIHVw
ZGF0aW5nIGEgbWFwIGZpZWxkLCBzZXQgdGhlIHZhbHVlIG9mIGEga2V5IHRvIG51bGwgb3Ig
ZW1wdHkKIHN0cmluZyB0byBkZWxldGUgdGhlIGtleSBmcm9tIHRoZSBtYXAuIEl0J3Mgbm90
IHBvc3NpYmxlIHRvIHVwZGF0ZSBhIGtleSdzCiB2YWx1ZSB0byB0aGUgZW1wdHkgc3RyaW5n
LgogSWYgeW91IHNwZWNpZnkgdGhlIHVwZGF0ZV9tYXNrIHRvIGJlIGEgc3BlY2lhbCBwYXRo
ICIqIiwgZnVsbHkgcmVwbGFjZXMgYWxsCiB1c2VyLW1vZGlmaWFibGUgZmllbGRzIHRvIG1h
dGNoIGByZXNvdXJjZWAuCgoNCgUEBQICBhIE7AECCQoNCgUEBQICARIE7AEKEgoNCgUEBQIC
AxIE7AEVFgqFBgoEBAUCAxIE+wECQRr2BSBPcHRpb25hbC4gQSByZXF1ZXN0IElEIHRvIGlk
ZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQKIHNvIHRoYXQg
aWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0
byBpZ25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVk
LiBUaGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51
dGVzIGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBh
IHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUg
cmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGgg
dGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFs
IG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5k
IGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMK
IGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1l
bnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4
Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAw
MC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQFAgMFEgT7AQIICg0KBQQFAgMBEgT7
AQkTCg0KBQQFAgMDEgT7ARYXCg0KBQQFAgMIEgT7ARhAChAKCAQFAgMInAgAEgT7ARk/CkYK
AgQGEgb/AQCXAgEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5u
aW5nIG9wZXJhdGlvbi4KCgsKAwQGARIE/wEIGQpACgQEBgIAEgSBAgJYGjIgT3V0cHV0IG9u
bHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoNCgUEBgIABhIEgQIC
GwoNCgUEBgIAARIEgQIcJwoNCgUEBgIAAxIEgQIqKwoNCgUEBgIACBIEgQIsVwoQCggEBgIA
CJwIABIEgQItVgpFCgQEBgIBEgSEAgJVGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBv
cGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCg0KBQQGAgEGEgSEAgIbCg0KBQQGAgEBEgSE
AhwkCg0KBQQGAgEDEgSEAicoCg0KBQQGAgEIEgSEAilUChAKCAQGAgEInAgAEgSEAipTCloK
BAQGAgISBIcCAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0
aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAYCAgUSBIcCAggKDQoF
BAYCAgESBIcCCQ8KDQoFBAYCAgMSBIcCEhMKDQoFBAYCAggSBIcCFD8KEAoIBAYCAgicCAAS
BIcCFT4KSAoEBAYCAxIEigICPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4
ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoNCgUEBgIDBRIEigICCAoNCgUEBgIDARIEigIJ
DQoNCgUEBgIDAxIEigIQEQoNCgUEBgIDCBIEigISPQoQCggEBgIDCJwIABIEigITPApMCgQE
BgIEEgSNAgJHGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUg
b3BlcmF0aW9uLCBpZiBhbnkuCgoNCgUEBgIEBRIEjQICCAoNCgUEBgIEARIEjQIJFgoNCgUE
BgIEAxIEjQIZGgoNCgUEBgIECBIEjQIbRgoQCggEBgIECJwIABIEjQIcRQqaAgoEBAYCBRIE
kwICSBqLAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2VyIGhhcyBy
ZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRpb25zIHRo
YXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQKIGhhdmUgW09wZXJhdGlvbi5l
cnJvcl1bXSB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5y
cGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25kaW5nIHRvIGBDb2RlLkNBTkNFTExF
RGAuCgoNCgUEBgIFBRIEkwICBgoNCgUEBgIFARIEkwIHFwoNCgUEBgIFAxIEkwIaGwoNCgUE
BgIFCBIEkwIcRwoQCggEBgIFCJwIABIEkwIdRgpFCgQEBgIGEgSWAgJFGjcgT3V0cHV0IG9u
bHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQGAgYF
EgSWAgIICg0KBQQGAgYBEgSWAgkUCg0KBQQGAgYDEgSWAhcYCg0KBQQGAgYIEgSWAhlEChAK
CAQGAgYInAgAEgSWAhpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesRequest ===
    # Fields for ListFeaturesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesResponse ===
    # Fields for ListFeaturesResponse
    # Field: resources Type: 11 (.google.cloud.gkehub.v1alpha.Feature)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1alpha::Service::GetFeatureRequest ===
    # Fields for GetFeatureRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1alpha::Service::CreateFeatureRequest ===
    # Fields for CreateFeatureRequest
    # Field: parent Type: 9 ()
    # Field: feature_id Type: 9 ()
    # Field: resource Type: 11 (.google.cloud.gkehub.v1alpha.Feature)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1alpha::Service::DeleteFeatureRequest ===
    # Fields for DeleteFeatureRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1alpha::Service::UpdateFeatureRequest ===
    # Fields for UpdateFeatureRequest
    # Field: name Type: 9 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: resource Type: 11 (.google.cloud.gkehub.v1alpha.Feature)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Gkehub::V1alpha::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_detail Type: 9 ()
    # Field: cancel_requested Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Gkehub::V1alpha::Service::GkeHubClient ===
package Google::Cloud::Gkehub::V1alpha::Service::GkeHubClient;

=pod

=head2 Service Client: Google::Cloud::Gkehub::V1alpha::Service::GkeHubClient

Client stub representing the remote C<GkeHub> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<gkehub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'gkehub.googleapis.com:443' );

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

sub list_features {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1alpha.GkeHub',
        method         => 'ListFeatures',
        request        => $req,
        response_class => 'Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesResponse',
    });
}

sub get_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1alpha::Service::GetFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1alpha.GkeHub',
        method         => 'GetFeature',
        request        => $req,
        response_class => 'Google::Cloud::Gkehub::V1alpha::Feature::Feature',
    });
}

sub create_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1alpha::Service::CreateFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1alpha.GkeHub',
        method         => 'CreateFeature',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1alpha::Service::DeleteFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1alpha.GkeHub',
        method         => 'DeleteFeature',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_feature {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Gkehub::V1alpha::Service::UpdateFeatureRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.gkehub.v1alpha.GkeHub',
        method         => 'UpdateFeature',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::V1alpha::Service - Compiled Protocol Buffers messages for google/cloud/gkehub/v1alpha/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::V1alpha::Service;

    my $msg = Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1alpha/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesRequest

Request message for `GkeHub.ListFeatures` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The parent (project and location) where the Features will be listed.
Specified in the format `projects/*/locations/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

When requesting a 'page' of resources, `page_size` specifies number of
resources to return. If unspecified or set to 0, all resources will
be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Token returned by previous call to `ListFeatures` which
specifies the position in the list from where to continue listing the
resources.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Lists Features that match the filter expression, following the syntax
outlined in https://google.aip.dev/160.

Examples:

  - Feature with the name "servicemesh" in project "foo-proj":

      name = "projects/foo-proj/locations/global/features/servicemesh"

  - Features that have a label called `foo`:

      labels.foo:*

  - Features that have a label called `foo` whose value is `bar`:

      labels.foo = bar

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

One or more fields to compare and use to sort the output.
See https://google.aip.dev/132#ordering.

=back

=head2 Google::Cloud::Gkehub::V1alpha::Service::ListFeaturesResponse

Response message for the `GkeHub.ListFeatures` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::Feature>)

The list of matching Features

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to request the next page of resources from the
`ListFeatures` method. The value of an empty string means
that there are no more resources to return.

=back

=head2 Google::Cloud::Gkehub::V1alpha::Service::GetFeatureRequest

Request message for `GkeHub.GetFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Feature resource name in the format
`projects/*/locations/*/features/*`

=back

=head2 Google::Cloud::Gkehub::V1alpha::Service::CreateFeatureRequest

Request message for the `GkeHub.CreateFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The parent (project and location) where the Feature will be created.
Specified in the format `projects/*/locations/*`.

=item * C<< $msg->feature_id() >> / C<< $msg->feature_id($value) >>

Type: C<String>

The ID of the feature to create.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::Feature>)

The Feature resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Gkehub::V1alpha::Service::DeleteFeatureRequest

Request message for `GkeHub.DeleteFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Feature resource name in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If set to true, the delete will ignore any outstanding resources for
this Feature (that is, `FeatureState.has_resources` is set to true). These
resources will NOT be cleaned up or modified in any way.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Gkehub::V1alpha::Service::UpdateFeatureRequest

Request message for `GkeHub.UpdateFeature` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Feature resource name in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Mask of fields to update.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::Feature>)

Only fields specified in update_mask are updated.
If you specify a field in the update_mask but don't specify its value here
that field will be deleted.
If you are updating a map field, set the value of a key to null or empty
string to delete the key from the map. It's not possible to update a key's
value to the empty string.
If you specify the update_mask to be a special path "*", fully replaces all
user-modifiable fields to match `resource`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Gkehub::V1alpha::Service::OperationMetadata

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

=item * C<< $msg->status_detail() >> / C<< $msg->status_detail($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->cancel_requested() >> / C<< $msg->cancel_requested($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::V1alpha::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
