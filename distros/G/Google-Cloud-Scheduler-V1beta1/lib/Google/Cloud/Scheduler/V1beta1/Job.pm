package Google::Cloud::Scheduler::V1beta1::Job;

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
    eval { require Google::Cloud::Scheduler::V1beta1::Target };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvc2NoZWR1bGVyL3YxYmV0YTEvam9iLnByb3RvEh5nb29nbGUuY2xv
dWQuc2NoZWR1bGVyLnYxYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aK2dvb2dsZS9jbG91ZC9zY2hlZHVsZXIvdjFi
ZXRhMS90YXJnZXQucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8i
0AgKA0pvYhISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNj
cmlwdGlvbhJTCg1wdWJzdWJfdGFyZ2V0GAQgASgLMiwuZ29vZ2xlLmNsb3VkLnNjaGVkdWxl
ci52MWJldGExLlB1YnN1YlRhcmdldEgAUgxwdWJzdWJUYXJnZXQSagoWYXBwX2VuZ2luZV9o
dHRwX3RhcmdldBgFIAEoCzIzLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5BcHBF
bmdpbmVIdHRwVGFyZ2V0SABSE2FwcEVuZ2luZUh0dHBUYXJnZXQSTQoLaHR0cF90YXJnZXQY
BiABKAsyKi5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSHR0cFRhcmdldEgAUgpo
dHRwVGFyZ2V0EhoKCHNjaGVkdWxlGBQgASgJUghzY2hlZHVsZRIbCgl0aW1lX3pvbmUYFSAB
KAlSCHRpbWVab25lEkQKEHVzZXJfdXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUg51c2VyVXBkYXRlVGltZRI/CgVzdGF0ZRgKIAEoDjIpLmdvb2dsZS5j
bG91ZC5zY2hlZHVsZXIudjFiZXRhMS5Kb2IuU3RhdGVSBXN0YXRlEioKBnN0YXR1cxgLIAEo
CzISLmdvb2dsZS5ycGMuU3RhdHVzUgZzdGF0dXMSPwoNc2NoZWR1bGVfdGltZRgRIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVkdWxlVGltZRJGChFsYXN0X2F0dGVt
cHRfdGltZRgSIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD2xhc3RBdHRlbXB0
VGltZRJOCgxyZXRyeV9jb25maWcYEyABKAsyKy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYx
YmV0YTEuUmV0cnlDb25maWdSC3JldHJ5Q29uZmlnEkQKEGF0dGVtcHRfZGVhZGxpbmUYFiAB
KAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SD2F0dGVtcHREZWFkbGluZRI4ChZsZWdh
Y3lfYXBwX2VuZ2luZV9jcm9uGBcgASgIQgPgQQVSE2xlZ2FjeUFwcEVuZ2luZUNyb24iWAoF
U3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdFTkFCTEVEEAESCgoGUEFVU0VEEAIS
DAoIRElTQUJMRUQQAxIRCg1VUERBVEVfRkFJTEVEEAQ6WupBVwohY2xvdWRzY2hlZHVsZXIu
Z29vZ2xlYXBpcy5jb20vSm9iEjJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vam9icy97am9ifUIICgZ0YXJnZXQitgIKC1JldHJ5Q29uZmlnEh8KC3JldHJ5X2Nv
dW50GAEgASgFUgpyZXRyeUNvdW50EkcKEm1heF9yZXRyeV9kdXJhdGlvbhgCIAEoCzIZLmdv
b2dsZS5wcm90b2J1Zi5EdXJhdGlvblIQbWF4UmV0cnlEdXJhdGlvbhJLChRtaW5fYmFja29m
Zl9kdXJhdGlvbhgDIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblISbWluQmFja29m
ZkR1cmF0aW9uEksKFG1heF9iYWNrb2ZmX2R1cmF0aW9uGAQgASgLMhkuZ29vZ2xlLnByb3Rv
YnVmLkR1cmF0aW9uUhJtYXhCYWNrb2ZmRHVyYXRpb24SIwoNbWF4X2RvdWJsaW5ncxgFIAEo
BVIMbWF4RG91YmxpbmdzQnIKImNvbS5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTFC
CEpvYlByb3RvUAFaQGNsb3VkLmdvb2dsZS5jb20vZ28vc2NoZWR1bGVyL2FwaXYxYmV0YTEv
c2NoZWR1bGVycGI7c2NoZWR1bGVycGJKjFMKBxIFDgCLAgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMC
EgMUADUKCQoCAwMSAxUAKAoJCgIDBBIDFgApCgkKAgMFEgMXACEKCAoBCBIDGQBXCgkKAggL
EgMZAFcKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwApCgkKAggIEgMbACkKCAoBCBID
HAA7CgkKAggBEgMcADsKUwoCBAASBSAAwgEBGkYgQ29uZmlndXJhdGlvbiBmb3IgYSBqb2Iu
CiBUaGUgbWF4aW11bSBhbGxvd2VkIHNpemUgZm9yIGEgam9iIGlzIDFNQi4KCgoKAwQAARID
IAgLCgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBAohCgQEAAQAEgQnAj0DGhMgU3RhdGUg
b2YgdGhlIGpvYi4KCgwKBQQABAABEgMnBwwKIwoGBAAEAAIAEgMpBBoaFCBVbnNwZWNpZmll
ZCBzdGF0ZS4KCg4KBwQABAACAAESAykEFQoOCgcEAAQAAgACEgMpGBkKLwoGBAAEAAIBEgMs
BBAaICBUaGUgam9iIGlzIGV4ZWN1dGluZyBub3JtYWxseS4KCg4KBwQABAACAQESAywECwoO
CgcEAAQAAgECEgMsDg8KtwEKBgQABAACAhIDMQQPGqcBIFRoZSBqb2IgaXMgcGF1c2VkIGJ5
IHRoZSB1c2VyLiBJdCB3aWxsIG5vdCBleGVjdXRlLiBBIHVzZXIgY2FuCiBpbnRlbnRpb25h
bGx5IHBhdXNlIHRoZSBqb2IgdXNpbmcKIFtQYXVzZUpvYlJlcXVlc3RdW2dvb2dsZS5jbG91
ZC5zY2hlZHVsZXIudjFiZXRhMS5QYXVzZUpvYlJlcXVlc3RdLgoKDgoHBAAEAAICARIDMQQK
Cg4KBwQABAACAgISAzENDgp0CgYEAAQAAgMSAzUEERplIFRoZSBqb2IgaXMgZGlzYWJsZWQg
YnkgdGhlIHN5c3RlbSBkdWUgdG8gZXJyb3IuIFRoZSB1c2VyCiBjYW5ub3QgZGlyZWN0bHkg
c2V0IGEgam9iIHRvIGJlIGRpc2FibGVkLgoKDgoHBAAEAAIDARIDNQQMCg4KBwQABAACAwIS
AzUPEAq/AgoGBAAEAAIEEgM8BBYarwIgVGhlIGpvYiBzdGF0ZSByZXN1bHRpbmcgZnJvbSBh
IGZhaWxlZAogW0Nsb3VkU2NoZWR1bGVyLlVwZGF0ZUpvYl1bZ29vZ2xlLmNsb3VkLnNjaGVk
dWxlci52MWJldGExLkNsb3VkU2NoZWR1bGVyLlVwZGF0ZUpvYl0KIG9wZXJhdGlvbi4gVG8g
cmVjb3ZlciBhIGpvYiBmcm9tIHRoaXMgc3RhdGUsIHJldHJ5CiBbQ2xvdWRTY2hlZHVsZXIu
VXBkYXRlSm9iXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hlZHVs
ZXIuVXBkYXRlSm9iXQogdW50aWwgYSBzdWNjZXNzZnVsIHJlc3BvbnNlIGlzIHJlY2VpdmVk
LgoKDgoHBAAEAAIEARIDPAQRCg4KBwQABAACBAISAzwUFQqTBwoEBAACABIDUQISGoUHIE9w
dGlvbmFsbHkgY2FsbGVyLXNwZWNpZmllZCBpbgogW0NyZWF0ZUpvYl1bZ29vZ2xlLmNsb3Vk
LnNjaGVkdWxlci52MWJldGExLkNsb3VkU2NoZWR1bGVyLkNyZWF0ZUpvYl0sIGFmdGVyCiB3
aGljaCBpdCBiZWNvbWVzIG91dHB1dCBvbmx5LgoKIFRoZSBqb2IgbmFtZS4gRm9yIGV4YW1w
bGU6CiBgcHJvamVjdHMvUFJPSkVDVF9JRC9sb2NhdGlvbnMvTE9DQVRJT05fSUQvam9icy9K
T0JfSURgLgoKICogYFBST0pFQ1RfSURgIGNhbiBjb250YWluIGxldHRlcnMgKFtBLVphLXpd
KSwgbnVtYmVycyAoWzAtOV0pLAogICAgaHlwaGVucyAoLSksIGNvbG9ucyAoOiksIG9yIHBl
cmlvZHMgKC4pLgogICAgRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQogICAgW0lkZW50aWZ5
aW5nCiAgICBwcm9qZWN0c10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1h
bmFnZXIvZG9jcy9jcmVhdGluZy1tYW5hZ2luZy1wcm9qZWN0cyNpZGVudGlmeWluZ19wcm9q
ZWN0cykKICogYExPQ0FUSU9OX0lEYCBpcyB0aGUgY2Fub25pY2FsIElEIGZvciB0aGUgam9i
J3MgbG9jYXRpb24uCiAgICBUaGUgbGlzdCBvZiBhdmFpbGFibGUgbG9jYXRpb25zIGNhbiBi
ZSBvYnRhaW5lZCBieSBjYWxsaW5nCiAgICBbTGlzdExvY2F0aW9uc11bZ29vZ2xlLmNsb3Vk
LmxvY2F0aW9uLkxvY2F0aW9ucy5MaXN0TG9jYXRpb25zXS4KICAgIEZvciBtb3JlIGluZm9y
bWF0aW9uLCBzZWUgaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2Fib3V0L2xvY2F0aW9ucy8u
CiAqIGBKT0JfSURgIGNhbiBjb250YWluIG9ubHkgbGV0dGVycyAoW0EtWmEtel0pLCBudW1i
ZXJzIChbMC05XSksCiAgICBoeXBoZW5zICgtKSwgb3IgdW5kZXJzY29yZXMgKF8pLiBUaGUg
bWF4aW11bSBsZW5ndGggaXMgNTAwIGNoYXJhY3RlcnMuCgoMCgUEAAIABRIDUQIICgwKBQQA
AgABEgNRCQ0KDAoFBAACAAMSA1EQEQqiAgoEBAACARIDWQIZGpQCIE9wdGlvbmFsbHkgY2Fs
bGVyLXNwZWNpZmllZCBpbgogW0NyZWF0ZUpvYl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52
MWJldGExLkNsb3VkU2NoZWR1bGVyLkNyZWF0ZUpvYl0gb3IKIFtVcGRhdGVKb2JdW2dvb2ds
ZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5DbG91ZFNjaGVkdWxlci5VcGRhdGVKb2JdLgoK
IEEgaHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24gZm9yIHRoZSBqb2IuIFRoaXMgc3RyaW5n
IG11c3Qgbm90IGNvbnRhaW4KIG1vcmUgdGhhbiA1MDAgY2hhcmFjdGVycy4KCgwKBQQAAgEF
EgNZAggKDAoFBAACAQESA1kJFAoMCgUEAAIBAxIDWRcYClQKBAQACAASBF4CZwMaRiBSZXF1
aXJlZC4KCiBEZWxpdmVyeSBzZXR0aW5ncyBjb250YWluaW5nIGRlc3RpbmF0aW9uIGFuZCBw
YXJhbWV0ZXJzLgoKDAoFBAAIAAESA14IDgoeCgQEAAICEgNgBCMaESBQdWIvU3ViIHRhcmdl
dC4KCgwKBQQAAgIGEgNgBBAKDAoFBAACAgESA2ARHgoMCgUEAAICAxIDYCEiCiYKBAQAAgMS
A2MEMxoZIEFwcCBFbmdpbmUgSFRUUCB0YXJnZXQuCgoMCgUEAAIDBhIDYwQXCgwKBQQAAgMB
EgNjGC4KDAoFBAACAwMSA2MxMgobCgQEAAIEEgNmBB8aDiBIVFRQIHRhcmdldC4KCgwKBQQA
AgQGEgNmBA4KDAoFBAACBAESA2YPGgoMCgUEAAIEAxIDZh0eCvcICgQEAAIFEgSCAQIXGugI
IFJlcXVpcmVkLCBleGNlcHQgd2hlbiB1c2VkIHdpdGgKIFtVcGRhdGVKb2JdW2dvb2dsZS5j
bG91ZC5zY2hlZHVsZXIudjFiZXRhMS5DbG91ZFNjaGVkdWxlci5VcGRhdGVKb2JdLgoKIERl
c2NyaWJlcyB0aGUgc2NoZWR1bGUgb24gd2hpY2ggdGhlIGpvYiB3aWxsIGJlIGV4ZWN1dGVk
LgoKIFRoZSBzY2hlZHVsZSBjYW4gYmUgZWl0aGVyIG9mIHRoZSBmb2xsb3dpbmcgdHlwZXM6
CgogKiBbQ3JvbnRhYl0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvQ3JvbiNPdmVy
dmlldykKICogRW5nbGlzaC1saWtlCiBbc2NoZWR1bGVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9zY2hlZHVsZXIvZG9jcy9jb25maWd1cmluZy9jcm9uLWpvYi1zY2hlZHVsZXMpCgog
QXMgYSBnZW5lcmFsIHJ1bGUsIGV4ZWN1dGlvbiBgbiArIDFgIG9mIGEgam9iIHdpbGwgbm90
IGJlZ2luCiB1bnRpbCBleGVjdXRpb24gYG5gIGhhcyBmaW5pc2hlZC4gQ2xvdWQgU2NoZWR1
bGVyIHdpbGwgbmV2ZXIKIGFsbG93IHR3byBzaW11bHRhbmVvdXNseSBvdXRzdGFuZGluZyBl
eGVjdXRpb25zLiBGb3IgZXhhbXBsZSwKIHRoaXMgaW1wbGllcyB0aGF0IGlmIHRoZSBgbisx
YHRoIGV4ZWN1dGlvbiBpcyBzY2hlZHVsZWQgdG8gcnVuIGF0CiAxNjowMCBidXQgdGhlIGBu
YHRoIGV4ZWN1dGlvbiB0YWtlcyB1bnRpbCAxNjoxNSwgdGhlIGBuKzFgdGgKIGV4ZWN1dGlv
biB3aWxsIG5vdCBzdGFydCB1bnRpbCBgMTY6MTVgLgogQSBzY2hlZHVsZWQgc3RhcnQgdGlt
ZSB3aWxsIGJlIGRlbGF5ZWQgaWYgdGhlIHByZXZpb3VzCiBleGVjdXRpb24gaGFzIG5vdCBl
bmRlZCB3aGVuIGl0cyBzY2hlZHVsZWQgdGltZSBvY2N1cnMuCgogSWYgW3JldHJ5X2NvdW50
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUmV0cnlDb25maWcucmV0cnlfY291
bnRdID4KIDAgYW5kIGEgam9iIGF0dGVtcHQgZmFpbHMsIHRoZSBqb2Igd2lsbCBiZSB0cmll
ZCBhIHRvdGFsIG9mCiBbcmV0cnlfY291bnRdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFi
ZXRhMS5SZXRyeUNvbmZpZy5yZXRyeV9jb3VudF0KIHRpbWVzLCB3aXRoIGV4cG9uZW50aWFs
IGJhY2tvZmYsIHVudGlsIHRoZSBuZXh0IHNjaGVkdWxlZCBzdGFydAogdGltZS4KCg0KBQQA
AgUFEgSCAQIICg0KBQQAAgUBEgSCAQkRCg0KBQQAAgUDEgSCARQWCvQDCgQEAAIGEgSOAQIY
GuUDIFNwZWNpZmllcyB0aGUgdGltZSB6b25lIHRvIGJlIHVzZWQgaW4gaW50ZXJwcmV0aW5n
CiBbc2NoZWR1bGVdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5Kb2Iuc2NoZWR1
bGVdLiBUaGUgdmFsdWUgb2YgdGhpcwogZmllbGQgbXVzdCBiZSBhIHRpbWUgem9uZSBuYW1l
IGZyb20gdGhlIFt0egogZGF0YWJhc2VdKGh0dHA6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kv
VHpfZGF0YWJhc2UpLgoKIE5vdGUgdGhhdCBzb21lIHRpbWUgem9uZXMgaW5jbHVkZSBhIHBy
b3Zpc2lvbiBmb3IKIGRheWxpZ2h0IHNhdmluZ3MgdGltZS4gVGhlIHJ1bGVzIGZvciBkYXls
aWdodCBzYXZpbmcgdGltZSBhcmUKIGRldGVybWluZWQgYnkgdGhlIGNob3NlbiB0ei4gRm9y
IFVUQyB1c2UgdGhlIHN0cmluZyAidXRjIi4gSWYgYQogdGltZSB6b25lIGlzIG5vdCBzcGVj
aWZpZWQsIHRoZSBkZWZhdWx0IHdpbGwgYmUgaW4gVVRDIChhbHNvIGtub3duCiBhcyBHTVQp
LgoKDQoFBAACBgUSBI4BAggKDQoFBAACBgESBI4BCRIKDQoFBAACBgMSBI4BFRcKOgoEBAAC
BxIEkQECMRosIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRpb24gdGltZSBvZiB0aGUgam9iLgoK
DQoFBAACBwYSBJEBAhsKDQoFBAACBwESBJEBHCwKDQoFBAACBwMSBJEBLzAKLgoEBAACCBIE
lAECExogIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgam9iLgoKDQoFBAACCAYSBJQBAgcK
DQoFBAACCAESBJQBCA0KDQoFBAACCAMSBJQBEBIKWwoEBAACCRIElwECIBpNIE91dHB1dCBv
bmx5LiBUaGUgcmVzcG9uc2UgZnJvbSB0aGUgdGFyZ2V0IGZvciB0aGUgbGFzdCBhdHRlbXB0
ZWQgZXhlY3V0aW9uLgoKDQoFBAACCQYSBJcBAhMKDQoFBAACCQESBJcBFBoKDQoFBAACCQMS
BJcBHR8KtgEKBAQAAgoSBJwBAi8apwEgT3V0cHV0IG9ubHkuIFRoZSBuZXh0IHRpbWUgdGhl
IGpvYiBpcyBzY2hlZHVsZWQuIE5vdGUgdGhhdCB0aGlzIG1heSBiZSBhCiByZXRyeSBvZiBh
IHByZXZpb3VzbHkgZmFpbGVkIGF0dGVtcHQgb3IgdGhlIG5leHQgZXhlY3V0aW9uIHRpbWUK
IGFjY29yZGluZyB0byB0aGUgc2NoZWR1bGUuCgoNCgUEAAIKBhIEnAECGwoNCgUEAAIKARIE
nAEcKQoNCgUEAAIKAxIEnAEsLgpDCgQEAAILEgSfAQIzGjUgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHRoZSBsYXN0IGpvYiBhdHRlbXB0IHN0YXJ0ZWQuCgoNCgUEAAILBhIEnwECGwoNCgUE
AAILARIEnwEcLQoNCgUEAAILAxIEnwEwMgo7CgQEAAIMEgSiAQIgGi0gU2V0dGluZ3MgdGhh
dCBkZXRlcm1pbmUgdGhlIHJldHJ5IGJlaGF2aW9yLgoKDQoFBAACDAYSBKIBAg0KDQoFBAAC
DAESBKIBDhoKDQoFBAACDAMSBKIBHR8K+wgKBAQAAg0SBLoBAjEa7AggVGhlIGRlYWRsaW5l
IGZvciBqb2IgYXR0ZW1wdHMuIElmIHRoZSByZXF1ZXN0IGhhbmRsZXIgZG9lcyBub3QgcmVz
cG9uZCBieQogdGhpcyBkZWFkbGluZSB0aGVuIHRoZSByZXF1ZXN0IGlzIGNhbmNlbGxlZCBh
bmQgdGhlIGF0dGVtcHQgaXMgbWFya2VkIGFzIGEKIGBERUFETElORV9FWENFRURFRGAgZmFp
bHVyZS4gVGhlIGZhaWxlZCBhdHRlbXB0IGNhbiBiZSB2aWV3ZWQgaW4KIGV4ZWN1dGlvbiBs
b2dzLiBDbG91ZCBTY2hlZHVsZXIgd2lsbCByZXRyeSB0aGUgam9iIGFjY29yZGluZwogdG8g
dGhlIFtSZXRyeUNvbmZpZ11bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLlJldHJ5
Q29uZmlnXS4KCiBUaGUgZGVmYXVsdCBhbmQgdGhlIGFsbG93ZWQgdmFsdWVzIGRlcGVuZCBv
biB0aGUgdHlwZSBvZiB0YXJnZXQ6CgogKiBGb3IgW0hUVFAgdGFyZ2V0c11bZ29vZ2xlLmNs
b3VkLnNjaGVkdWxlci52MWJldGExLkpvYi5odHRwX3RhcmdldF0sIHRoZQogZGVmYXVsdCBp
cyAzIG1pbnV0ZXMuIFRoZSBkZWFkbGluZSBtdXN0IGJlIGluIHRoZSBpbnRlcnZhbCBbMTUg
c2Vjb25kcywgMzAKIG1pbnV0ZXNdLgoKICogRm9yIFtBcHAgRW5naW5lIEhUVFAKIHRhcmdl
dHNdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5Kb2IuYXBwX2VuZ2luZV9odHRw
X3RhcmdldF0sIDAKIGluZGljYXRlcyB0aGF0IHRoZSByZXF1ZXN0IGhhcyB0aGUgZGVmYXVs
dCBkZWFkbGluZS4gVGhlIGRlZmF1bHQgZGVhZGxpbmUKIGRlcGVuZHMgb24gdGhlIHNjYWxp
bmcgdHlwZSBvZiB0aGUgc2VydmljZTogMTAgbWludXRlcyBmb3Igc3RhbmRhcmQgYXBwcwog
d2l0aCBhdXRvbWF0aWMgc2NhbGluZywgMjQgaG91cnMgZm9yIHN0YW5kYXJkIGFwcHMgd2l0
aCBtYW51YWwgYW5kIGJhc2ljCiBzY2FsaW5nLCBhbmQgNjAgbWludXRlcyBmb3IgZmxleCBh
cHBzLiBJZiB0aGUgcmVxdWVzdCBkZWFkbGluZSBpcyBzZXQsIGl0CiBtdXN0IGJlIGluIHRo
ZSBpbnRlcnZhbCBbMTUgc2Vjb25kcywgMjQgaG91cnMgMTUgc2Vjb25kc10uCgogKiBGb3Ig
W1B1Yi9TdWIgdGFyZ2V0c11bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkpvYi5w
dWJzdWJfdGFyZ2V0XSwKIHRoaXMgZmllbGQgaXMgaWdub3JlZC4KCg0KBQQAAg0GEgS6AQIa
Cg0KBQQAAg0BEgS6ARsrCg0KBQQAAg0DEgS6AS4wCr0CCgQEAAIOEgTBAQJNGq4CIEltbXV0
YWJsZS4gVGhpcyBmaWVsZCBpcyB1c2VkIHRvIG1hbmFnZSB0aGUgbGVnYWN5IEFwcCBFbmdp
bmUgQ3JvbiBqb2JzCiB1c2luZyB0aGUgQ2xvdWQgU2NoZWR1bGVyIEFQSS4gSWYgdGhlIGZp
ZWxkIGlzIHNldCB0byB0cnVlLCB0aGUgam9iIHdpbGwgYmUKIGNvbnNpZGVyZWQgYSBsZWdh
Y3kgam9iLiBOb3RlIHRoYXQgQXBwIEVuZ2luZSBDcm9uIGpvYnMgaGF2ZSBmZXdlcgogZmVh
dHVyZXMgdGhhbiBDbG91ZCBTY2hlZHVsZXIgam9icywgZS5nLiwgYXJlIG9ubHkgbGltaXRl
ZCB0byBBcHAgRW5naW5lCiB0YXJnZXRzLgoKDQoFBAACDgUSBMEBAgYKDQoFBAACDgESBMEB
Bx0KDQoFBAACDgMSBMEBICIKDQoFBAACDggSBMEBI0wKEAoIBAACDgicCAASBMEBJEsKwQIK
AgQBEgbKAQCLAgEasgIgU2V0dGluZ3MgdGhhdCBkZXRlcm1pbmUgdGhlIHJldHJ5IGJlaGF2
aW9yLgoKIEJ5IGRlZmF1bHQsIGlmIGEgam9iIGRvZXMgbm90IGNvbXBsZXRlIHN1Y2Nlc3Nm
dWxseSAobWVhbmluZyB0aGF0CiBhbiBhY2tub3dsZWRnZW1lbnQgaXMgbm90IHJlY2VpdmVk
IGZyb20gdGhlIGhhbmRsZXIsIHRoZW4gaXQgd2lsbCBiZSByZXRyaWVkCiB3aXRoIGV4cG9u
ZW50aWFsIGJhY2tvZmYgYWNjb3JkaW5nIHRvIHRoZSBzZXR0aW5ncyBpbgogW1JldHJ5Q29u
ZmlnXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUmV0cnlDb25maWddLgoKCwoD
BAEBEgTKAQgTCqwFCgQEAQIAEgTbAQIYGp0FIFRoZSBudW1iZXIgb2YgYXR0ZW1wdHMgdGhh
dCB0aGUgc3lzdGVtIHdpbGwgbWFrZSB0byBydW4gYSBqb2IgdXNpbmcgdGhlCiBleHBvbmVu
dGlhbCBiYWNrb2ZmIHByb2NlZHVyZSBkZXNjcmliZWQgYnkKIFttYXhfZG91YmxpbmdzXVtn
b29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUmV0cnlDb25maWcubWF4X2RvdWJsaW5n
c10uCgogVGhlIGRlZmF1bHQgdmFsdWUgb2YgcmV0cnlfY291bnQgaXMgemVyby4KCiBJZiBy
ZXRyeV9jb3VudCBpcyB6ZXJvLCBhIGpvYiBhdHRlbXB0IHdpbGwgKm5vdCogYmUgcmV0cmll
ZCBpZgogaXQgZmFpbHMuIEluc3RlYWQgdGhlIENsb3VkIFNjaGVkdWxlciBzeXN0ZW0gd2ls
bCB3YWl0IGZvciB0aGUKIG5leHQgc2NoZWR1bGVkIGV4ZWN1dGlvbiB0aW1lLgoKIElmIHJl
dHJ5X2NvdW50IGlzIHNldCB0byBhIG5vbi16ZXJvIG51bWJlciB0aGVuIENsb3VkIFNjaGVk
dWxlcgogd2lsbCByZXRyeSBmYWlsZWQgYXR0ZW1wdHMsIHVzaW5nIGV4cG9uZW50aWFsIGJh
Y2tvZmYsCiByZXRyeV9jb3VudCB0aW1lcywgb3IgdW50aWwgdGhlIG5leHQgc2NoZWR1bGVk
IGV4ZWN1dGlvbiB0aW1lLAogd2hpY2hldmVyIGNvbWVzIGZpcnN0LgoKIFZhbHVlcyBncmVh
dGVyIHRoYW4gNSBhbmQgbmVnYXRpdmUgdmFsdWVzIGFyZSBub3QgYWxsb3dlZC4KCg0KBQQB
AgAFEgTbAQIHCg0KBQQBAgABEgTbAQgTCg0KBQQBAgADEgTbARYXCuUCCgQEAQIBEgTkAQIy
GtYCIFRoZSB0aW1lIGxpbWl0IGZvciByZXRyeWluZyBhIGZhaWxlZCBqb2IsIG1lYXN1cmVk
IGZyb20gdGltZSB3aGVuIGFuCiBleGVjdXRpb24gd2FzIGZpcnN0IGF0dGVtcHRlZC4gSWYg
c3BlY2lmaWVkIHdpdGgKIFtyZXRyeV9jb3VudF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52
MWJldGExLlJldHJ5Q29uZmlnLnJldHJ5X2NvdW50XSwgdGhlCiBqb2Igd2lsbCBiZSByZXRy
aWVkIHVudGlsIGJvdGggbGltaXRzIGFyZSByZWFjaGVkLgoKIFRoZSBkZWZhdWx0IHZhbHVl
IGZvciBtYXhfcmV0cnlfZHVyYXRpb24gaXMgemVybywgd2hpY2ggbWVhbnMgcmV0cnkKIGR1
cmF0aW9uIGlzIHVubGltaXRlZC4KCg0KBQQBAgEGEgTkAQIaCg0KBQQBAgEBEgTkARstCg0K
BQQBAgEDEgTkATAxCokBCgQEAQICEgTqAQI0GnsgVGhlIG1pbmltdW0gYW1vdW50IG9mIHRp
bWUgdG8gd2FpdCBiZWZvcmUgcmV0cnlpbmcgYSBqb2IgYWZ0ZXIKIGl0IGZhaWxzLgoKIFRo
ZSBkZWZhdWx0IHZhbHVlIG9mIHRoaXMgZmllbGQgaXMgNSBzZWNvbmRzLgoKDQoFBAECAgYS
BOoBAhoKDQoFBAECAgESBOoBGy8KDQoFBAECAgMSBOoBMjMKhgEKBAQBAgMSBPABAjQaeCBU
aGUgbWF4aW11bSBhbW91bnQgb2YgdGltZSB0byB3YWl0IGJlZm9yZSByZXRyeWluZyBhIGpv
YiBhZnRlcgogaXQgZmFpbHMuCgogVGhlIGRlZmF1bHQgdmFsdWUgb2YgdGhpcyBmaWVsZCBp
cyAxIGhvdXIuCgoNCgUEAQIDBhIE8AECGgoNCgUEAQIDARIE8AEbLwoNCgUEAQIDAxIE8AEy
MwrBCQoEBAECBBIEigICGhqyCSBUaGUgdGltZSBiZXR3ZWVuIHJldHJpZXMgd2lsbCBkb3Vi
bGUgYG1heF9kb3VibGluZ3NgIHRpbWVzLgoKIEEgam9iJ3MgcmV0cnkgaW50ZXJ2YWwgc3Rh
cnRzIGF0CiBbbWluX2JhY2tvZmZfZHVyYXRpb25dW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIu
djFiZXRhMS5SZXRyeUNvbmZpZy5taW5fYmFja29mZl9kdXJhdGlvbl0sCiB0aGVuIGRvdWJs
ZXMgYG1heF9kb3VibGluZ3NgIHRpbWVzLCB0aGVuIGluY3JlYXNlcyBsaW5lYXJseSwgYW5k
IGZpbmFsbHkKIHJldHJpZXMgYXQgaW50ZXJ2YWxzIG9mCiBbbWF4X2JhY2tvZmZfZHVyYXRp
b25dW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5SZXRyeUNvbmZpZy5tYXhfYmFj
a29mZl9kdXJhdGlvbl0KIHVwIHRvIFtyZXRyeV9jb3VudF1bZ29vZ2xlLmNsb3VkLnNjaGVk
dWxlci52MWJldGExLlJldHJ5Q29uZmlnLnJldHJ5X2NvdW50XQogdGltZXMuCgogRm9yIGV4
YW1wbGUsIGlmCiBbbWluX2JhY2tvZmZfZHVyYXRpb25dW2dvb2dsZS5jbG91ZC5zY2hlZHVs
ZXIudjFiZXRhMS5SZXRyeUNvbmZpZy5taW5fYmFja29mZl9kdXJhdGlvbl0KIGlzIDEwcywK
IFttYXhfYmFja29mZl9kdXJhdGlvbl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGEx
LlJldHJ5Q29uZmlnLm1heF9iYWNrb2ZmX2R1cmF0aW9uXQogaXMgMzAwcywgYW5kIGBtYXhf
ZG91YmxpbmdzYCBpcyAzLCB0aGVuIHRoZSBhIGpvYiB3aWxsIGZpcnN0IGJlIHJldHJpZWQg
aW4KIDEwcy4gVGhlIHJldHJ5IGludGVydmFsIHdpbGwgZG91YmxlIHRocmVlIHRpbWVzLCBh
bmQgdGhlbiBpbmNyZWFzZSBsaW5lYXJseQogYnkgMl4zICogMTBzLiAgRmluYWxseSwgdGhl
IGpvYiB3aWxsIHJldHJ5IGF0IGludGVydmFscyBvZgogW21heF9iYWNrb2ZmX2R1cmF0aW9u
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUmV0cnlDb25maWcubWF4X2JhY2tv
ZmZfZHVyYXRpb25dCiB1bnRpbCB0aGUgam9iIGhhcyBiZWVuIGF0dGVtcHRlZAogW3JldHJ5
X2NvdW50XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUmV0cnlDb25maWcucmV0
cnlfY291bnRdCiB0aW1lcy4gVGh1cywgdGhlIHJlcXVlc3RzIHdpbGwgcmV0cnkgYXQgMTBz
LCAyMHMsIDQwcywgODBzLCAxNjBzLCAyNDBzLAogMzAwcywgMzAwcywgLi4uLgoKIFRoZSBk
ZWZhdWx0IHZhbHVlIG9mIHRoaXMgZmllbGQgaXMgNS4KCg0KBQQBAgQFEgSKAgIHCg0KBQQB
AgQBEgSKAggVCg0KBQQBAgQDEgSKAhgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Scheduler::V1beta1::Job::Job ===
    # Fields for Job
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: pubsub_target Type: 11 (.google.cloud.scheduler.v1beta1.PubsubTarget)
    # Field: app_engine_http_target Type: 11 (.google.cloud.scheduler.v1beta1.AppEngineHttpTarget)
    # Field: http_target Type: 11 (.google.cloud.scheduler.v1beta1.HttpTarget)
    # Field: schedule Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: user_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.scheduler.v1beta1.Job.State)
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_attempt_time Type: 11 (.google.protobuf.Timestamp)
    # Field: retry_config Type: 11 (.google.cloud.scheduler.v1beta1.RetryConfig)
    # Field: attempt_deadline Type: 11 (.google.protobuf.Duration)
    # Field: legacy_app_engine_cron Type: 8 ()

# Enum: Job::State
our $Job_STATE_UNSPECIFIED = 0;
our $Job_ENABLED = 1;
our $Job_PAUSED = 2;
our $Job_DISABLED = 3;
our $Job_UPDATE_FAILED = 4;

# === Message: Google::Cloud::Scheduler::V1beta1::Job::RetryConfig ===
    # Fields for RetryConfig
    # Field: retry_count Type: 5 ()
    # Field: max_retry_duration Type: 11 (.google.protobuf.Duration)
    # Field: min_backoff_duration Type: 11 (.google.protobuf.Duration)
    # Field: max_backoff_duration Type: 11 (.google.protobuf.Duration)
    # Field: max_doublings Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Scheduler::V1beta1::Job - Compiled Protocol Buffers messages for google/cloud/scheduler/v1beta1/job.proto

=head1 SYNOPSIS

    use Google::Cloud::Scheduler::V1beta1::Job;

    my $msg = Google::Cloud::Scheduler::V1beta1::Job::Job->new({
        name => $name,
        description => $description,
        pubsub_target => $pubsub_target,
        app_engine_http_target => $app_engine_http_target,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Scheduler::V1beta1::Job::Job->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/scheduler/v1beta1/job.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Scheduler::V1beta1::Job::Job

Configuration for a job.
The maximum allowed size for a job is 1MB.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optionally caller-specified in
[CreateJob][google.cloud.scheduler.v1beta1.CloudScheduler.CreateJob], after
which it becomes output only.

The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

* `PROJECT_ID` can contain letters ([A-Za-z]), numbers ([0-9]),
   hyphens (-), colons (:), or periods (.).
   For more information, see
   [Identifying
   projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)
* `LOCATION_ID` is the canonical ID for the job's location.
   The list of available locations can be obtained by calling
   [ListLocations][google.cloud.location.Locations.ListLocations].
   For more information, see https://cloud.google.com/about/locations/.
* `JOB_ID` can contain only letters ([A-Za-z]), numbers ([0-9]),
   hyphens (-), or underscores (_). The maximum length is 500 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optionally caller-specified in
[CreateJob][google.cloud.scheduler.v1beta1.CloudScheduler.CreateJob] or
[UpdateJob][google.cloud.scheduler.v1beta1.CloudScheduler.UpdateJob].

A human-readable description for the job. This string must not contain
more than 500 characters.

=item * C<< $msg->pubsub_target() >> / C<< $msg->pubsub_target($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget>)

Pub/Sub target.

=item * C<< $msg->app_engine_http_target() >> / C<< $msg->app_engine_http_target($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget>)

App Engine HTTP target.

=item * C<< $msg->http_target() >> / C<< $msg->http_target($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Target::HttpTarget>)

HTTP target.

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<String>

Required, except when used with
[UpdateJob][google.cloud.scheduler.v1beta1.CloudScheduler.UpdateJob].

Describes the schedule on which the job will be executed.

The schedule can be either of the following types:

* [Crontab](https://en.wikipedia.org/wiki/Cron#Overview)
* English-like
[schedule](https://cloud.google.com/scheduler/docs/configuring/cron-job-schedules)

As a general rule, execution `n + 1` of a job will not begin
until execution `n` has finished. Cloud Scheduler will never
allow two simultaneously outstanding executions. For example,
this implies that if the `n+1`th execution is scheduled to run at
16:00 but the `n`th execution takes until 16:15, the `n+1`th
execution will not start until `16:15`.
A scheduled start time will be delayed if the previous
execution has not ended when its scheduled time occurs.

If [retry_count][google.cloud.scheduler.v1beta1.RetryConfig.retry_count] >
0 and a job attempt fails, the job will be tried a total of
[retry_count][google.cloud.scheduler.v1beta1.RetryConfig.retry_count]
times, with exponential backoff, until the next scheduled start
time.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Specifies the time zone to be used in interpreting
[schedule][google.cloud.scheduler.v1beta1.Job.schedule]. The value of this
field must be a time zone name from the [tz
database](http://en.wikipedia.org/wiki/Tz_database).

Note that some time zones include a provision for
daylight savings time. The rules for daylight saving time are
determined by the chosen tz. For UTC use the string "utc". If a
time zone is not specified, the default will be in UTC (also known
as GMT).

=item * C<< $msg->user_update_time() >> / C<< $msg->user_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time of the job.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Scheduler::V1beta1::Job::State>)

Output only. State of the job.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The response from the target for the last attempted execution.

=item * C<< $msg->schedule_time() >> / C<< $msg->schedule_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The next time the job is scheduled. Note that this may be a
retry of a previously failed attempt or the next execution time
according to the schedule.

=item * C<< $msg->last_attempt_time() >> / C<< $msg->last_attempt_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the last job attempt started.

=item * C<< $msg->retry_config() >> / C<< $msg->retry_config($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Job::RetryConfig>)

Settings that determine the retry behavior.

=item * C<< $msg->attempt_deadline() >> / C<< $msg->attempt_deadline($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The deadline for job attempts. If the request handler does not respond by
this deadline then the request is cancelled and the attempt is marked as a
`DEADLINE_EXCEEDED` failure. The failed attempt can be viewed in
execution logs. Cloud Scheduler will retry the job according
to the [RetryConfig][google.cloud.scheduler.v1beta1.RetryConfig].

The default and the allowed values depend on the type of target:

* For [HTTP targets][google.cloud.scheduler.v1beta1.Job.http_target], the
default is 3 minutes. The deadline must be in the interval [15 seconds, 30
minutes].

* For [App Engine HTTP
targets][google.cloud.scheduler.v1beta1.Job.app_engine_http_target], 0
indicates that the request has the default deadline. The default deadline
depends on the scaling type of the service: 10 minutes for standard apps
with automatic scaling, 24 hours for standard apps with manual and basic
scaling, and 60 minutes for flex apps. If the request deadline is set, it
must be in the interval [15 seconds, 24 hours 15 seconds].

* For [Pub/Sub targets][google.cloud.scheduler.v1beta1.Job.pubsub_target],
this field is ignored.

=item * C<< $msg->legacy_app_engine_cron() >> / C<< $msg->legacy_app_engine_cron($value) >>

Type: C<Bool>

Immutable. This field is used to manage the legacy App Engine Cron jobs
using the Cloud Scheduler API. If the field is set to true, the job will be
considered a legacy job. Note that App Engine Cron jobs have fewer
features than Cloud Scheduler jobs, e.g., are only limited to App Engine
targets.

=back

=head3 Enum: Job::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<PAUSED> => C<2>

=item * C<DISABLED> => C<3>

=item * C<UPDATE_FAILED> => C<4>

=back

=head2 Google::Cloud::Scheduler::V1beta1::Job::RetryConfig

Settings that determine the retry behavior.

By default, if a job does not complete successfully (meaning that
an acknowledgement is not received from the handler, then it will be retried
with exponential backoff according to the settings in
[RetryConfig][google.cloud.scheduler.v1beta1.RetryConfig].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->retry_count() >> / C<< $msg->retry_count($value) >>

Type: C<Int32>

The number of attempts that the system will make to run a job using the
exponential backoff procedure described by
[max_doublings][google.cloud.scheduler.v1beta1.RetryConfig.max_doublings].

The default value of retry_count is zero.

If retry_count is zero, a job attempt will *not* be retried if
it fails. Instead the Cloud Scheduler system will wait for the
next scheduled execution time.

If retry_count is set to a non-zero number then Cloud Scheduler
will retry failed attempts, using exponential backoff,
retry_count times, or until the next scheduled execution time,
whichever comes first.

Values greater than 5 and negative values are not allowed.

=item * C<< $msg->max_retry_duration() >> / C<< $msg->max_retry_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The time limit for retrying a failed job, measured from time when an
execution was first attempted. If specified with
[retry_count][google.cloud.scheduler.v1beta1.RetryConfig.retry_count], the
job will be retried until both limits are reached.

The default value for max_retry_duration is zero, which means retry
duration is unlimited.

=item * C<< $msg->min_backoff_duration() >> / C<< $msg->min_backoff_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The minimum amount of time to wait before retrying a job after
it fails.

The default value of this field is 5 seconds.

=item * C<< $msg->max_backoff_duration() >> / C<< $msg->max_backoff_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The maximum amount of time to wait before retrying a job after
it fails.

The default value of this field is 1 hour.

=item * C<< $msg->max_doublings() >> / C<< $msg->max_doublings($value) >>

Type: C<Int32>

The time between retries will double `max_doublings` times.

A job's retry interval starts at
[min_backoff_duration][google.cloud.scheduler.v1beta1.RetryConfig.min_backoff_duration],
then doubles `max_doublings` times, then increases linearly, and finally
retries at intervals of
[max_backoff_duration][google.cloud.scheduler.v1beta1.RetryConfig.max_backoff_duration]
up to [retry_count][google.cloud.scheduler.v1beta1.RetryConfig.retry_count]
times.

For example, if
[min_backoff_duration][google.cloud.scheduler.v1beta1.RetryConfig.min_backoff_duration]
is 10s,
[max_backoff_duration][google.cloud.scheduler.v1beta1.RetryConfig.max_backoff_duration]
is 300s, and `max_doublings` is 3, then the a job will first be retried in
10s. The retry interval will double three times, and then increase linearly
by 2^3 * 10s.  Finally, the job will retry at intervals of
[max_backoff_duration][google.cloud.scheduler.v1beta1.RetryConfig.max_backoff_duration]
until the job has been attempted
[retry_count][google.cloud.scheduler.v1beta1.RetryConfig.retry_count]
times. Thus, the requests will retry at 10s, 20s, 40s, 80s, 160s, 240s,
300s, 300s, ....

The default value of this field is 5.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Scheduler::V1beta1::Job::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
