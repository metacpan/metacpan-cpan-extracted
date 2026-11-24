package Google::Cloud::Gkebackup::V1::Backup;

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
CiZnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL2JhY2t1cC5wcm90bxIZZ29vZ2xlLmNsb3Vk
LmdrZWJhY2t1cC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxomZ29vZ2xlL2Nsb3VkL2drZWJhY2t1cC92MS9jb21tb24u
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8itxIKBkJhY2t1cBIXCgRu
YW1lGAEgASgJQgPgQQNSBG5hbWUSFQoDdWlkGAIgASgJQgPgQQNSA3VpZBJACgtjcmVhdGVf
dGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGlt
ZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKdXBkYXRlVGltZRIbCgZtYW51YWwYBSABKAhCA+BBA1IGbWFudWFsEkoKBmxhYmVscxgG
IAMoCzItLmdvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuQmFja3VwLkxhYmVsc0VudHJ5QgPg
QQFSBmxhYmVscxItChBkZWxldGVfbG9ja19kYXlzGAcgASgFQgPgQQFSDmRlbGV0ZUxvY2tE
YXlzElYKF2RlbGV0ZV9sb2NrX2V4cGlyZV90aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUhRkZWxldGVMb2NrRXhwaXJlVGltZRIkCgtyZXRhaW5fZGF5cxgJ
IAEoBUID4EEBUgpyZXRhaW5EYXlzEk0KEnJldGFpbl9leHBpcmVfdGltZRgKIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IQcmV0YWluRXhwaXJlVGltZRJUCg5lbmNy
eXB0aW9uX2tleRgLIAEoCzIoLmdvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuRW5jcnlwdGlv
bktleUID4EEDUg1lbmNyeXB0aW9uS2V5EiwKDmFsbF9uYW1lc3BhY2VzGAwgASgIQgPgQQNI
AFINYWxsTmFtZXNwYWNlcxJdChNzZWxlY3RlZF9uYW1lc3BhY2VzGA0gASgLMiUuZ29vZ2xl
LmNsb3VkLmdrZWJhY2t1cC52MS5OYW1lc3BhY2VzQgPgQQNIAFISc2VsZWN0ZWROYW1lc3Bh
Y2VzEmYKFXNlbGVjdGVkX2FwcGxpY2F0aW9ucxgOIAEoCzIqLmdvb2dsZS5jbG91ZC5na2Vi
YWNrdXAudjEuTmFtZXNwYWNlZE5hbWVzQgPgQQNIAFIUc2VsZWN0ZWRBcHBsaWNhdGlvbnMS
NQoUY29udGFpbnNfdm9sdW1lX2RhdGEYDyABKAhCA+BBA1ISY29udGFpbnNWb2x1bWVEYXRh
Ei4KEGNvbnRhaW5zX3NlY3JldHMYECABKAhCA+BBA1IPY29udGFpbnNTZWNyZXRzEmEKEGNs
dXN0ZXJfbWV0YWRhdGEYESABKAsyMS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1
cC5DbHVzdGVyTWV0YWRhdGFCA+BBA1IPY2x1c3Rlck1ldGFkYXRhEkIKBXN0YXRlGBIgASgO
MicuZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5CYWNrdXAuU3RhdGVCA+BBA1IFc3RhdGUS
JgoMc3RhdGVfcmVhc29uGBMgASgJQgPgQQNSC3N0YXRlUmVhc29uEkQKDWNvbXBsZXRlX3Rp
bWUYFCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDGNvbXBsZXRlVGlt
ZRIqCg5yZXNvdXJjZV9jb3VudBgVIAEoBUID4EEDUg1yZXNvdXJjZUNvdW50EiYKDHZvbHVt
ZV9jb3VudBgWIAEoBUID4EEDUgt2b2x1bWVDb3VudBIiCgpzaXplX2J5dGVzGBcgASgDQgPg
QQNSCXNpemVCeXRlcxIXCgRldGFnGBggASgJQgPgQQNSBGV0YWcSJQoLZGVzY3JpcHRpb24Y
GSABKAlCA+BBAVILZGVzY3JpcHRpb24SIAoJcG9kX2NvdW50GBogASgFQgPgQQNSCHBvZENv
dW50EjwKGGNvbmZpZ19iYWNrdXBfc2l6ZV9ieXRlcxgbIAEoA0ID4EEDUhVjb25maWdCYWNr
dXBTaXplQnl0ZXMSLAoPcGVybWlzc2l2ZV9tb2RlGBwgASgIQgPgQQNSDnBlcm1pc3NpdmVN
b2RlEigKDXNhdGlzZmllc19wenMYHSABKAhCA+BBA1IMc2F0aXNmaWVzUHpzEigKDXNhdGlz
Zmllc19wemkYHiABKAhCA+BBA1IMc2F0aXNmaWVzUHppGoUDCg9DbHVzdGVyTWV0YWRhdGES
HQoHY2x1c3RlchgBIAEoCUID4EEDUgdjbHVzdGVyEiQKC2s4c192ZXJzaW9uGAIgASgJQgPg
QQNSCms4c1ZlcnNpb24SfQoTYmFja3VwX2NyZF92ZXJzaW9ucxgDIAMoCzJILmdvb2dsZS5j
bG91ZC5na2ViYWNrdXAudjEuQmFja3VwLkNsdXN0ZXJNZXRhZGF0YS5CYWNrdXBDcmRWZXJz
aW9uc0VudHJ5QgPgQQNSEWJhY2t1cENyZFZlcnNpb25zEiYKC2drZV92ZXJzaW9uGAQgASgJ
QgPgQQNIAFIKZ2tlVmVyc2lvbhIsCg5hbnRob3NfdmVyc2lvbhgFIAEoCUID4EEDSABSDWFu
dGhvc1ZlcnNpb24aRAoWQmFja3VwQ3JkVmVyc2lvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQhIKEHBsYXRmb3JtX3ZlcnNpb24aOQoLTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJm
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESDwoLSU5fUFJP
R1JFU1MQAhINCglTVUNDRUVERUQQAxIKCgZGQUlMRUQQBBIMCghERUxFVElORxAFOnjqQXUK
H2drZWJhY2t1cC5nb29nbGVhcGlzLmNvbS9CYWNrdXASUnByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBQbGFucy97YmFja3VwX3BsYW59L2JhY2t1cHMv
e2JhY2t1cH1CDgoMYmFja3VwX3Njb3BlQsIBCh1jb20uZ29vZ2xlLmNsb3VkLmdrZWJhY2t1
cC52MUILQmFja3VwUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9na2ViYWNrdXAvYXBp
djEvZ2tlYmFja3VwcGI7Z2tlYmFja3VwcGKqAhlHb29nbGUuQ2xvdWQuR2tlQmFja3VwLlYx
ygIZR29vZ2xlXENsb3VkXEdrZUJhY2t1cFxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkdrZUJhY2t1
cDo6VjFKqlQKBxIFDgCCAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
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
CgECEgMQACIKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADAKCQoCAwMSAxUAKQoI
CgEIEgMXADYKCQoCCCUSAxcANgoICgEIEgMYAFIKCQoCCAsSAxgAUgoICgEIEgMZACIKCQoC
CAoSAxkAIgoICgEIEgMaACwKCQoCCAgSAxoALAoICgEIEgMbADYKCQoCCAESAxsANgoICgEI
EgMcADYKCQoCCCkSAxwANgoICgEIEgMdADUKCQoCCC0SAx0ANQqWAgoCBAASBSMAggIBGogC
IFJlcHJlc2VudHMgYSByZXF1ZXN0IHRvIHBlcmZvcm0gYSBzaW5nbGUgcG9pbnQtaW4tdGlt
ZSBjYXB0dXJlIG9mCiBzb21lIHBvcnRpb24gb2YgdGhlIHN0YXRlIG9mIGEgR0tFIGNsdXN0
ZXIsIHRoZSByZWNvcmQgb2YgdGhlIGJhY2t1cAogb3BlcmF0aW9uIGl0c2VsZiwgYW5kIGFu
IGFuY2hvciBmb3IgdGhlIHVuZGVybHlpbmcgYXJ0aWZhY3RzIHRoYXQKIGNvbXByaXNlIHRo
ZSBCYWNrdXAgKHRoZSBjb25maWcgYmFja3VwIGFuZCBWb2x1bWVCYWNrdXBzKS4KCgoKAwQA
ARIDIwgOCgsKAwQABxIEJAInBAoNCgUEAAedCBIEJAInBApVCgQEAAMAEgQqAkUDGkcgSW5m
b3JtYXRpb24gYWJvdXQgdGhlIEdLRSBjbHVzdGVyIGZyb20gd2hpY2ggdGhpcyBCYWNrdXAg
d2FzIGNyZWF0ZWQuCgoMCgUEAAMAARIDKgoZCqUCCgYEAAMAAgASAzMEQxqVAiBPdXRwdXQg
b25seS4gVGhlIHNvdXJjZSBjbHVzdGVyIGZyb20gd2hpY2ggdGhpcyBCYWNrdXAgd2FzIGNy
ZWF0ZWQuCiBWYWxpZCBmb3JtYXRzOgoKICAgLSBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
bHVzdGVycy8qYAogICAtIGBwcm9qZWN0cy8qL3pvbmVzLyovY2x1c3RlcnMvKmAKCiBUaGlz
IGlzIGluaGVyaXRlZCBmcm9tIHRoZSBwYXJlbnQgQmFja3VwUGxhbidzCiBbY2x1c3Rlcl1b
Z29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5CYWNrdXBQbGFuLmNsdXN0ZXJdIGZpZWxkLgoK
DgoHBAADAAIABRIDMwQKCg4KBwQAAwACAAESAzMLEgoOCgcEAAMAAgADEgMzFRYKDgoHBAAD
AAIACBIDMxdCChEKCgQAAwACAAicCAASAzMYQQpSCgYEAAMAAgESAzYERxpDIE91dHB1dCBv
bmx5LiBUaGUgS3ViZXJuZXRlcyBzZXJ2ZXIgdmVyc2lvbiBvZiB0aGUgc291cmNlIGNsdXN0
ZXIuCgoOCgcEAAMAAgEFEgM2BAoKDgoHBAADAAIBARIDNgsWCg4KBwQAAwACAQMSAzYZGgoO
CgcEAAMAAgEIEgM2G0YKEQoKBAADAAIBCJwIABIDNhxFCl8KBgQAAwACAhIEOgQ7NBpPIE91
dHB1dCBvbmx5LiBBIGxpc3Qgb2YgdGhlIEJhY2t1cCBmb3IgR0tFIENSRCB2ZXJzaW9ucyBm
b3VuZCBpbiB0aGUKIGNsdXN0ZXIuCgoOCgcEAAMAAgIGEgM6BBcKDgoHBAADAAICARIDOhgr
Cg4KBwQAAwACAgMSAzouLwoOCgcEAAMAAgIIEgM7CDMKEQoKBAADAAICCJwIABIDOwkyCisK
BgQAAwAIABIEPgREBRobIFBsYXRmb3JtLXNwZWNpZmljIHZlcnNpb24KCg4KBwQAAwAIAAES
Az4KGgopCgYEAAMAAgMSA0AGSRoaIE91dHB1dCBvbmx5LiBHS0UgdmVyc2lvbgoKDgoHBAAD
AAIDBRIDQAYMCg4KBwQAAwACAwESA0ANGAoOCgcEAAMAAgMDEgNAGxwKDgoHBAADAAIDCBID
QB1IChEKCgQAAwACAwicCAASA0AeRwosCgYEAAMAAgQSA0MGTBodIE91dHB1dCBvbmx5LiBB
bnRob3MgdmVyc2lvbgoKDgoHBAADAAIEBRIDQwYMCg4KBwQAAwACBAESA0MNGwoOCgcEAAMA
AgQDEgNDHh8KDgoHBAADAAIECBIDQyBLChEKCgQAAwACBAicCAASA0MhSgoVCgQEAAQAEgRI
Al0DGgcgU3RhdGUKCgwKBQQABAABEgNIBwwKSAoGBAAEAAIAEgNKBBoaOSBUaGUgQmFja3Vw
IHJlc291cmNlIGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQA
AgABEgNKBBUKDgoHBAAEAAIAAhIDShgZCpMBCgYEAAQAAgESA04EERqDASBUaGUgQmFja3Vw
IHJlc291cmNlIGhhcyBiZWVuIGNyZWF0ZWQgYW5kIHRoZSBhc3NvY2lhdGVkIEJhY2t1cEpv
YgogS3ViZXJuZXRlcyByZXNvdXJjZSBoYXMgYmVlbiBpbmplY3RlZCBpbnRvIHRoZSBzb3Vy
Y2UgY2x1c3Rlci4KCg4KBwQABAACAQESA04EDAoOCgcEAAQAAgECEgNODxAKXgoGBAAEAAIC
EgNSBBQaTyBUaGUgZ2tlYmFja3VwIGFnZW50IGluIHRoZSBjbHVzdGVyIGhhcyBiZWd1biBl
eGVjdXRpbmcgdGhlIGJhY2t1cAogb3BlcmF0aW9uLgoKDgoHBAAEAAICARIDUgQPCg4KBwQA
BAACAgISA1ISEwpBCgYEAAQAAgMSA1UEEhoyIFRoZSBiYWNrdXAgb3BlcmF0aW9uIGhhcyBj
b21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDgoHBAAEAAIDARIDVQQNCg4KBwQABAACAwISA1UQ
EQoxCgYEAAQAAgQSA1gEDxoiIFRoZSBiYWNrdXAgb3BlcmF0aW9uIGhhcyBmYWlsZWQuCgoO
CgcEAAQAAgQBEgNYBAoKDgoHBAAEAAIEAhIDWA0OCmkKBgQABAACBRIDXAQRGlogVGhpcyBC
YWNrdXAgcmVzb3VyY2UgKGFuZCBpdHMgYXNzb2NpYXRlZCBhcnRpZmFjdHMpIGlzIGluIHRo
ZSBwcm9jZXNzCiBvZiBiZWluZyBkZWxldGVkLgoKDgoHBAAEAAIFARIDXAQMCg4KBwQABAAC
BQISA1wPEAp1CgQEAAIAEgNhAj4aaCBPdXRwdXQgb25seS4gVGhlIGZ1bGx5IHF1YWxpZmll
ZCBuYW1lIG9mIHRoZSBCYWNrdXAuCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9iYWNrdXBQ
bGFucy8qL2JhY2t1cHMvKmAKCgwKBQQAAgAFEgNhAggKDAoFBAACAAESA2EJDQoMCgUEAAIA
AxIDYRARCgwKBQQAAgAIEgNhEj0KDwoIBAACAAicCAASA2ETPAqPAQoEBAACARIDZQI9GoEB
IE91dHB1dCBvbmx5LiBTZXJ2ZXIgZ2VuZXJhdGVkIGdsb2JhbCB1bmlxdWUgaWRlbnRpZmll
ciBvZgogW1VVSUQ0XShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxs
eV91bmlxdWVfaWRlbnRpZmllcikKCgwKBQQAAgEFEgNlAggKDAoFBAACAQESA2UJDAoMCgUE
AAIBAxIDZQ8QCgwKBQQAAgEIEgNlETwKDwoIBAACAQicCAASA2USOwpRCgQEAAICEgRoAmky
GkMgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIEJhY2t1cCByZXNvdXJj
ZSB3YXMgY3JlYXRlZC4KCgwKBQQAAgIGEgNoAhsKDAoFBAACAgESA2gcJwoMCgUEAAICAxID
aCorCgwKBQQAAgIIEgNpBjEKDwoIBAACAgicCAASA2kHMApWCgQEAAIDEgRsAm0yGkggT3V0
cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIEJhY2t1cCByZXNvdXJjZSB3YXMg
bGFzdCB1cGRhdGVkLgoKDAoFBAACAwYSA2wCGwoMCgUEAAIDARIDbBwnCgwKBQQAAgMDEgNs
KisKDAoFBAACAwgSA20GMQoPCggEAAIDCJwIABIDbQcwCs8BCgQEAAIEEgNyAj4awQEgT3V0
cHV0IG9ubHkuIFRoaXMgZmxhZyBpbmRpY2F0ZXMgd2hldGhlciB0aGlzIEJhY2t1cCByZXNv
dXJjZSB3YXMgY3JlYXRlZAogbWFudWFsbHkgYnkgYSB1c2VyIG9yIHZpYSBhIHNjaGVkdWxl
IGluIHRoZSBCYWNrdXBQbGFuLiBBIHZhbHVlIG9mIFRydWUKIG1lYW5zIHRoYXQgdGhlIEJh
Y2t1cCB3YXMgY3JlYXRlZCBtYW51YWxseS4KCgwKBQQAAgQFEgNyAgYKDAoFBAACBAESA3IH
DQoMCgUEAAIEAxIDchARCgwKBQQAAgQIEgNyEj0KDwoIBAACBAicCAASA3ITPApBCgQEAAIF
EgN1AkoaNCBPcHRpb25hbC4gQSBzZXQgb2YgY3VzdG9tIGxhYmVscyBzdXBwbGllZCBieSB1
c2VyLgoKDAoFBAACBQYSA3UCFQoMCgUEAAIFARIDdRYcCgwKBQQAAgUDEgN1HyAKDAoFBAAC
BQgSA3UhSQoPCggEAAIFCJwIABIDdSJICqsECgQEAAIGEgSBAQJGGpwEIE9wdGlvbmFsLiBN
aW5pbXVtIGFnZSBmb3IgdGhpcyBCYWNrdXAgKGluIGRheXMpLiBJZiB0aGlzIGZpZWxkIGlz
IHNldCB0byBhCiBub24temVybyB2YWx1ZSwgdGhlIEJhY2t1cCB3aWxsIGJlICJsb2NrZWQi
IGFnYWluc3QgZGVsZXRpb24gKGVpdGhlciBtYW51YWwKIG9yIGF1dG9tYXRpYyBkZWxldGlv
bikgZm9yIHRoZSBudW1iZXIgb2YgZGF5cyBwcm92aWRlZCAobWVhc3VyZWQgZnJvbSB0aGUK
IGNyZWF0aW9uIHRpbWUgb2YgdGhlIEJhY2t1cCkuICBNVVNUIGJlIGFuIGludGVnZXIgdmFs
dWUgYmV0d2VlbiAwLTkwCiAoaW5jbHVzaXZlKS4KCiBEZWZhdWx0cyB0byBwYXJlbnQgQmFj
a3VwUGxhbidzCiBbYmFja3VwX2RlbGV0ZV9sb2NrX2RheXNdW2dvb2dsZS5jbG91ZC5na2Vi
YWNrdXAudjEuQmFja3VwUGxhbi5SZXRlbnRpb25Qb2xpY3kuYmFja3VwX2RlbGV0ZV9sb2Nr
X2RheXNdCiBzZXR0aW5nIGFuZCBtYXkgb25seSBiZSBpbmNyZWFzZWQKIChlaXRoZXIgYXQg
Y3JlYXRpb24gdGltZSBvciBpbiBhIHN1YnNlcXVlbnQgdXBkYXRlKS4KCg0KBQQAAgYFEgSB
AQIHCg0KBQQAAgYBEgSBAQgYCg0KBQQAAgYDEgSBARscCg0KBQQAAgYIEgSBAR1FChAKCAQA
AgYInAgAEgSBAR5ECs4BCgQEAAIHEgaGAQKHATIavQEgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
IGF0IHdoaWNoIGFuIGV4aXN0aW5nIGRlbGV0ZSBsb2NrIHdpbGwgZXhwaXJlIGZvciB0aGlz
CiBiYWNrdXAgKGNhbGN1bGF0ZWQgZnJvbSBjcmVhdGVfdGltZSArCiBbZGVsZXRlX2xvY2tf
ZGF5c11bZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5CYWNrdXAuZGVsZXRlX2xvY2tfZGF5
c10pLgoKDQoFBAACBwYSBIYBAhsKDQoFBAACBwESBIYBHDMKDQoFBAACBwMSBIYBNjcKDQoF
BAACBwgSBIcBBjEKEAoIBAACBwicCAASBIcBBzAK+wMKBAQAAggSBJYBAkEa7AMgT3B0aW9u
YWwuIFRoZSBhZ2UgKGluIGRheXMpIGFmdGVyIHdoaWNoIHRoaXMgQmFja3VwIHdpbGwgYmUg
YXV0b21hdGljYWxseQogZGVsZXRlZC4gTXVzdCBiZSBhbiBpbnRlZ2VyIHZhbHVlID49IDA6
CgogLSBJZiAwLCBubyBhdXRvbWF0aWMgZGVsZXRpb24gd2lsbCBvY2N1ciBmb3IgdGhpcyBC
YWNrdXAuCiAtIElmIG5vdCAwLCB0aGlzIG11c3QgYmUgPj0KIFtkZWxldGVfbG9ja19kYXlz
XVtnb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1cC5kZWxldGVfbG9ja19kYXlzXSBh
bmQKIDw9IDM2NS4KCiBPbmNlIGEgQmFja3VwIGlzIGNyZWF0ZWQsIHRoaXMgdmFsdWUgbWF5
IG9ubHkgYmUgaW5jcmVhc2VkLgoKIERlZmF1bHRzIHRvIHRoZSBwYXJlbnQgQmFja3VwUGxh
bidzCiBbYmFja3VwX3JldGFpbl9kYXlzXVtnb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJh
Y2t1cFBsYW4uUmV0ZW50aW9uUG9saWN5LmJhY2t1cF9yZXRhaW5fZGF5c10KIHZhbHVlLgoK
DQoFBAACCAUSBJYBAgcKDQoFBAACCAESBJYBCBMKDQoFBAACCAMSBJYBFhcKDQoFBAACCAgS
BJYBGEAKEAoIBAACCAicCAASBJYBGT8KugEKBAQAAgkSBpsBApwBMhqpASBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhpcyBCYWNrdXAgd2lsbCBiZSBhdXRvbWF0aWNhbGx5
IGRlbGV0ZWQKIChjYWxjdWxhdGVkIGZyb20gY3JlYXRlX3RpbWUgKwogW3JldGFpbl9kYXlz
XVtnb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1cC5yZXRhaW5fZGF5c10pLgoKDQoF
BAACCQYSBJsBAhsKDQoFBAACCQESBJsBHC4KDQoFBAACCQMSBJsBMTMKDQoFBAACCQgSBJwB
BjEKEAoIBAACCQicCAASBJwBBzAK9wEKBAQAAgoSBKIBAlAa6AEgT3V0cHV0IG9ubHkuIFRo
ZSBjdXN0b21lciBtYW5hZ2VkIGVuY3J5cHRpb24ga2V5IHRoYXQgd2FzIHVzZWQgdG8gZW5j
cnlwdAogdGhlIEJhY2t1cCdzIGFydGlmYWN0cy4gIEluaGVyaXRlZCBmcm9tIHRoZSBwYXJl
bnQgQmFja3VwUGxhbidzCiBbZW5jcnlwdGlvbl9rZXldW2dvb2dsZS5jbG91ZC5na2ViYWNr
dXAudjEuQmFja3VwUGxhbi5CYWNrdXBDb25maWcuZW5jcnlwdGlvbl9rZXldCiB2YWx1ZS4K
Cg0KBQQAAgoGEgSiAQIPCg0KBQQAAgoBEgSiARAeCg0KBQQAAgoDEgSiASEjCg0KBQQAAgoI
EgSiASRPChAKCAQAAgoInAgAEgSiASVOCv8BCgQEAAgAEgapAQK2AQMa7gEgRGVmaW5lcyB0
aGUgInNjb3BlIiBvZiB0aGUgQmFja3VwIC0gd2hpY2ggbmFtZXNwYWNlZCByZXNvdXJjZXMg
aW4gdGhlCiBjbHVzdGVyIHdlcmUgaW5jbHVkZWQgaW4gdGhlIEJhY2t1cC4gIEluaGVyaXRl
ZCBmcm9tIHRoZSBwYXJlbnQKIEJhY2t1cFBsYW4ncwogW2JhY2t1cF9zY29wZV1bZ29vZ2xl
LmNsb3VkLmdrZWJhY2t1cC52MS5CYWNrdXBQbGFuLkJhY2t1cENvbmZpZy5iYWNrdXBfc2Nv
cGVdCiB2YWx1ZS4KCg0KBQQACAABEgSpAQgUClEKBAQAAgsSBKsBBEkaQyBPdXRwdXQgb25s
eS4gSWYgVHJ1ZSwgYWxsIG5hbWVzcGFjZXMgd2VyZSBpbmNsdWRlZCBpbiB0aGUgQmFja3Vw
LgoKDQoFBAACCwUSBKsBBAgKDQoFBAACCwESBKsBCRcKDQoFBAACCwMSBKsBGhwKDQoFBAAC
CwgSBKsBHUgKEAoIBAACCwicCAASBKsBHkcKYAoEBAACDBIGrwEEsAE0GlAgT3V0cHV0IG9u
bHkuIElmIHNldCwgdGhlIGxpc3Qgb2YgbmFtZXNwYWNlcyB0aGF0IHdlcmUgaW5jbHVkZWQg
aW4gdGhlCiBCYWNrdXAuCgoNCgUEAAIMBhIErwEEDgoNCgUEAAIMARIErwEPIgoNCgUEAAIM
AxIErwElJwoNCgUEAAIMCBIEsAEIMwoQCggEAAIMCJwIABIEsAEJMgp2CgQEAAINEga0AQS1
ATQaZiBPdXRwdXQgb25seS4gSWYgc2V0LCB0aGUgbGlzdCBvZiBQcm90ZWN0ZWRBcHBsaWNh
dGlvbnMgd2hvc2UgcmVzb3VyY2VzCiB3ZXJlIGluY2x1ZGVkIGluIHRoZSBCYWNrdXAuCgoN
CgUEAAINBhIEtAEEEwoNCgUEAAINARIEtAEUKQoNCgUEAAINAxIEtAEsLgoNCgUEAAINCBIE
tQEIMwoQCggEAAINCJwIABIEtQEJMgrbAQoEBAACDhIEvAECTRrMASBPdXRwdXQgb25seS4g
V2hldGhlciBvciBub3QgdGhlIEJhY2t1cCBjb250YWlucyB2b2x1bWUgZGF0YS4gIENvbnRy
b2xsZWQgYnkKIHRoZSBwYXJlbnQgQmFja3VwUGxhbidzCiBbaW5jbHVkZV92b2x1bWVfZGF0
YV1bZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5CYWNrdXBQbGFuLkJhY2t1cENvbmZpZy5p
bmNsdWRlX3ZvbHVtZV9kYXRhXQogdmFsdWUuCgoNCgUEAAIOBRIEvAECBgoNCgUEAAIOARIE
vAEHGwoNCgUEAAIOAxIEvAEeIAoNCgUEAAIOCBIEvAEhTAoQCggEAAIOCJwIABIEvAEiSwrZ
AQoEBAACDxIEwgECSRrKASBPdXRwdXQgb25seS4gV2hldGhlciBvciBub3QgdGhlIEJhY2t1
cCBjb250YWlucyBLdWJlcm5ldGVzIFNlY3JldHMuCiBDb250cm9sbGVkIGJ5IHRoZSBwYXJl
bnQgQmFja3VwUGxhbidzCiBbaW5jbHVkZV9zZWNyZXRzXVtnb29nbGUuY2xvdWQuZ2tlYmFj
a3VwLnYxLkJhY2t1cFBsYW4uQmFja3VwQ29uZmlnLmluY2x1ZGVfc2VjcmV0c10KIHZhbHVl
LgoKDQoFBAACDwUSBMIBAgYKDQoFBAACDwESBMIBBxcKDQoFBAACDwMSBMIBGhwKDQoFBAAC
DwgSBMIBHUgKEAoIBAACDwicCAASBMIBHkcKZQoEBAACEBIGxgECxwEyGlUgT3V0cHV0IG9u
bHkuIEluZm9ybWF0aW9uIGFib3V0IHRoZSBHS0UgY2x1c3RlciBmcm9tIHdoaWNoIHRoaXMg
QmFja3VwIHdhcwogY3JlYXRlZC4KCg0KBQQAAhAGEgTGAQIRCg0KBQQAAhABEgTGARIiCg0K
BQQAAhADEgTGASUnCg0KBQQAAhAIEgTHAQYxChAKCAQAAhAInAgAEgTHAQcwCjgKBAQAAhES
BMoBAj8aKiBPdXRwdXQgb25seS4gQ3VycmVudCBzdGF0ZSBvZiB0aGUgQmFja3VwCgoNCgUE
AAIRBhIEygECBwoNCgUEAAIRARIEygEIDQoNCgUEAAIRAxIEygEQEgoNCgUEAAIRCBIEygET
PgoQCggEAAIRCJwIABIEygEUPQrwAQoEBAACEhIEzwECRxrhASBPdXRwdXQgb25seS4gSHVt
YW4tcmVhZGFibGUgZGVzY3JpcHRpb24gb2Ygd2h5IHRoZSBiYWNrdXAgaXMgaW4gdGhlIGN1
cnJlbnQKIGBzdGF0ZWAuIFRoaXMgZmllbGQgaXMgb25seSBtZWFudCBmb3IgaHVtYW4gcmVh
ZGFiaWxpdHkgYW5kIHNob3VsZCBub3QgYmUKIHVzZWQgcHJvZ3JhbW1hdGljYWxseSBhcyB0
aGlzIGZpZWxkIGlzIG5vdCBndWFyYW50ZWVkIHRvIGJlIGNvbnNpc3RlbnQuCgoNCgUEAAIS
BRIEzwECCAoNCgUEAAISARIEzwEJFQoNCgUEAAISAxIEzwEYGgoNCgUEAAISCBIEzwEbRgoQ
CggEAAISCJwIABIEzwEcRQo8CgQEAAITEgbSAQLTATIaLCBPdXRwdXQgb25seS4gQ29tcGxl
dGlvbiB0aW1lIG9mIHRoZSBCYWNrdXAKCg0KBQQAAhMGEgTSAQIbCg0KBQQAAhMBEgTSARwp
Cg0KBQQAAhMDEgTSASwuCg0KBQQAAhMIEgTTAQYxChAKCAQAAhMInAgAEgTTAQcwCl4KBAQA
AhQSBNcBAkgaUCBPdXRwdXQgb25seS4gVGhlIHRvdGFsIG51bWJlciBvZiBLdWJlcm5ldGVz
IHJlc291cmNlcyBpbmNsdWRlZCBpbiB0aGUKIEJhY2t1cC4KCg0KBQQAAhQFEgTXAQIHCg0K
BQQAAhQBEgTXAQgWCg0KBQQAAhQDEgTXARkbCg0KBQQAAhQIEgTXARxHChAKCAQAAhQInAgA
EgTXAR1GClgKBAQAAhUSBNoBAkYaSiBPdXRwdXQgb25seS4gVGhlIHRvdGFsIG51bWJlciBv
ZiB2b2x1bWUgYmFja3VwcyBjb250YWluZWQgaW4gdGhlIEJhY2t1cC4KCg0KBQQAAhUFEgTa
AQIHCg0KBQQAAhUBEgTaAQgUCg0KBQQAAhUDEgTaARcZCg0KBQQAAhUIEgTaARpFChAKCAQA
AhUInAgAEgTaARtECnMKBAQAAhYSBN4BAkQaZSBPdXRwdXQgb25seS4gVGhlIHRvdGFsIHNp
emUgb2YgdGhlIEJhY2t1cCBpbiBieXRlcyA9IGNvbmZpZyBiYWNrdXAgc2l6ZSArCiBzdW0o
dm9sdW1lIGJhY2t1cCBzaXplcykKCg0KBQQAAhYFEgTeAQIHCg0KBQQAAhYBEgTeAQgSCg0K
BQQAAhYDEgTeARUXCg0KBQQAAhYIEgTeARhDChAKCAQAAhYInAgAEgTeARlCCqoECgQEAAIX
EgToAQI/GpsEIE91dHB1dCBvbmx5LiBgZXRhZ2AgaXMgdXNlZCBmb3Igb3B0aW1pc3RpYyBj
b25jdXJyZW5jeSBjb250cm9sIGFzIGEgd2F5IHRvCiBoZWxwIHByZXZlbnQgc2ltdWx0YW5l
b3VzIHVwZGF0ZXMgb2YgYSBiYWNrdXAgZnJvbSBvdmVyd3JpdGluZyBlYWNoIG90aGVyLgog
SXQgaXMgc3Ryb25nbHkgc3VnZ2VzdGVkIHRoYXQgc3lzdGVtcyBtYWtlIHVzZSBvZiB0aGUg
YGV0YWdgIGluIHRoZQogcmVhZC1tb2RpZnktd3JpdGUgY3ljbGUgdG8gcGVyZm9ybSBiYWNr
dXAgdXBkYXRlcyBpbiBvcmRlciB0byBhdm9pZAogcmFjZSBjb25kaXRpb25zOiBBbiBgZXRh
Z2AgaXMgcmV0dXJuZWQgaW4gdGhlIHJlc3BvbnNlIHRvIGBHZXRCYWNrdXBgLAogYW5kIHN5
c3RlbXMgYXJlIGV4cGVjdGVkIHRvIHB1dCB0aGF0IGV0YWcgaW4gdGhlIHJlcXVlc3QgdG8K
IGBVcGRhdGVCYWNrdXBgIG9yIGBEZWxldGVCYWNrdXBgIHRvIGVuc3VyZSB0aGF0IHRoZWly
IGNoYW5nZSB3aWxsIGJlCiBhcHBsaWVkIHRvIHRoZSBzYW1lIHZlcnNpb24gb2YgdGhlIHJl
c291cmNlLgoKDQoFBAACFwUSBOgBAggKDQoFBAACFwESBOgBCQ0KDQoFBAACFwMSBOgBEBIK
DQoFBAACFwgSBOgBEz4KEAoIBAACFwicCAASBOgBFD0KTAoEBAACGBIE6wECQxo+IE9wdGlv
bmFsLiBVc2VyIHNwZWNpZmllZCBkZXNjcmlwdGl2ZSBzdHJpbmcgZm9yIHRoaXMgQmFja3Vw
LgoKDQoFBAACGAUSBOsBAggKDQoFBAACGAESBOsBCRQKDQoFBAACGAMSBOsBFxkKDQoFBAAC
GAgSBOsBGkIKEAoIBAACGAicCAASBOsBG0EKWQoEBAACGRIE7gECQxpLIE91dHB1dCBvbmx5
LiBUaGUgdG90YWwgbnVtYmVyIG9mIEt1YmVybmV0ZXMgUG9kcyBjb250YWluZWQgaW4gdGhl
IEJhY2t1cC4KCg0KBQQAAhkFEgTuAQIHCg0KBQQAAhkBEgTuAQgRCg0KBQQAAhkDEgTuARQW
Cg0KBQQAAhkIEgTuARdCChAKCAQAAhkInAgAEgTuARhBCkYKBAQAAhoSBvEBAvIBMho2IE91
dHB1dCBvbmx5LiBUaGUgc2l6ZSBvZiB0aGUgY29uZmlnIGJhY2t1cCBpbiBieXRlcy4KCg0K
BQQAAhoFEgTxAQIHCg0KBQQAAhoBEgTxAQggCg0KBQQAAhoDEgTxASMlCg0KBQQAAhoIEgTy
AQYxChAKCAQAAhoInAgAEgTyAQcwCrQCCgQEAAIbEgT7AQJIGqUCIE91dHB1dCBvbmx5LiBJ
ZiBmYWxzZSwgQmFja3VwIHdpbGwgZmFpbCB3aGVuIEJhY2t1cCBmb3IgR0tFIGRldGVjdHMK
IEt1YmVybmV0ZXMgY29uZmlndXJhdGlvbiB0aGF0IGlzIG5vbi1zdGFuZGFyZCBvcgogcmVx
dWlyZXMgYWRkaXRpb25hbCBzZXR1cCB0byByZXN0b3JlLgoKIEluaGVyaXRlZCBmcm9tIHRo
ZSBwYXJlbnQgQmFja3VwUGxhbidzCiBbcGVybWlzc2l2ZV9tb2RlXVtnb29nbGUuY2xvdWQu
Z2tlYmFja3VwLnYxLkJhY2t1cFBsYW4uQmFja3VwQ29uZmlnLnBlcm1pc3NpdmVfbW9kZV0K
IHZhbHVlLgoKDQoFBAACGwUSBPsBAgYKDQoFBAACGwESBPsBBxYKDQoFBAACGwMSBPsBGRsK
DQoFBAACGwgSBPsBHEcKEAoIBAACGwicCAASBPsBHUYKQwoEBAACHBIE/gECRho1IE91dHB1
dCBvbmx5LiBbT3V0cHV0IE9ubHldIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlLgoKDQoFBAAC
HAUSBP4BAgYKDQoFBAACHAESBP4BBxQKDQoFBAACHAMSBP4BFxkKDQoFBAACHAgSBP4BGkUK
EAoIBAACHAicCAASBP4BG0QKQwoEBAACHRIEgQICRho1IE91dHB1dCBvbmx5LiBbT3V0cHV0
IE9ubHldIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlLgoKDQoFBAACHQUSBIECAgYKDQoFBAAC
HQESBIECBxQKDQoFBAACHQMSBIECFxkKDQoFBAACHQgSBIECGkUKEAoIBAACHQicCAASBIEC
G0RiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::Backup::Backup ===
    # Fields for Backup
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: manual Type: 8 ()
    # Field: labels Type: 11 (.google.cloud.gkebackup.v1.Backup.LabelsEntry)
    # Field: delete_lock_days Type: 5 ()
    # Field: delete_lock_expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: retain_days Type: 5 ()
    # Field: retain_expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: encryption_key Type: 11 (.google.cloud.gkebackup.v1.EncryptionKey)
    # Field: all_namespaces Type: 8 ()
    # Field: selected_namespaces Type: 11 (.google.cloud.gkebackup.v1.Namespaces)
    # Field: selected_applications Type: 11 (.google.cloud.gkebackup.v1.NamespacedNames)
    # Field: contains_volume_data Type: 8 ()
    # Field: contains_secrets Type: 8 ()
    # Field: cluster_metadata Type: 11 (.google.cloud.gkebackup.v1.Backup.ClusterMetadata)
    # Field: state Type: 14 (.google.cloud.gkebackup.v1.Backup.State)
    # Field: state_reason Type: 9 ()
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: resource_count Type: 5 ()
    # Field: volume_count Type: 5 ()
    # Field: size_bytes Type: 3 ()
    # Field: etag Type: 9 ()
    # Field: description Type: 9 ()
    # Field: pod_count Type: 5 ()
    # Field: config_backup_size_bytes Type: 3 ()
    # Field: permissive_mode Type: 8 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()

# Enum: Backup::State
our $Backup_STATE_UNSPECIFIED = 0;
our $Backup_CREATING = 1;
our $Backup_IN_PROGRESS = 2;
our $Backup_SUCCEEDED = 3;
our $Backup_FAILED = 4;
our $Backup_DELETING = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::Backup - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/backup.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::Backup;

    my $msg = Google::Cloud::Gkebackup::V1::Backup::Backup->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::Backup::Backup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/backup.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::Backup::Backup

Represents a request to perform a single point-in-time capture of
some portion of the state of a GKE cluster, the record of the backup
operation itself, and an anchor for the underlying artifacts that
comprise the Backup (the config backup and VolumeBackups).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The fully qualified name of the Backup.
`projects/*/locations/*/backupPlans/*/backups/*`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID4](https://en.wikipedia.org/wiki/Universally_unique_identifier)

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this Backup resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this Backup resource was last updated.

=item * C<< $msg->manual() >> / C<< $msg->manual($value) >>

Type: C<Bool>

Output only. This flag indicates whether this Backup resource was created
manually by a user or via a schedule in the BackupPlan. A value of True
means that the Backup was created manually.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Backup::Backup::LabelsEntry>)

Optional. A set of custom labels supplied by user.

=item * C<< $msg->delete_lock_days() >> / C<< $msg->delete_lock_days($value) >>

Type: C<Int32>

Optional. Minimum age for this Backup (in days). If this field is set to a
non-zero value, the Backup will be "locked" against deletion (either manual
or automatic deletion) for the number of days provided (measured from the
creation time of the Backup).  MUST be an integer value between 0-90
(inclusive).

Defaults to parent BackupPlan's
[backup_delete_lock_days][google.cloud.gkebackup.v1.BackupPlan.RetentionPolicy.backup_delete_lock_days]
setting and may only be increased
(either at creation time or in a subsequent update).

=item * C<< $msg->delete_lock_expire_time() >> / C<< $msg->delete_lock_expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which an existing delete lock will expire for this
backup (calculated from create_time +
[delete_lock_days][google.cloud.gkebackup.v1.Backup.delete_lock_days]).

=item * C<< $msg->retain_days() >> / C<< $msg->retain_days($value) >>

Type: C<Int32>

Optional. The age (in days) after which this Backup will be automatically
deleted. Must be an integer value >= 0:

- If 0, no automatic deletion will occur for this Backup.
- If not 0, this must be >=
[delete_lock_days][google.cloud.gkebackup.v1.Backup.delete_lock_days] and
<= 365.

Once a Backup is created, this value may only be increased.

Defaults to the parent BackupPlan's
[backup_retain_days][google.cloud.gkebackup.v1.BackupPlan.RetentionPolicy.backup_retain_days]
value.

=item * C<< $msg->retain_expire_time() >> / C<< $msg->retain_expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this Backup will be automatically deleted
(calculated from create_time +
[retain_days][google.cloud.gkebackup.v1.Backup.retain_days]).

=item * C<< $msg->encryption_key() >> / C<< $msg->encryption_key($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Common::EncryptionKey>)

Output only. The customer managed encryption key that was used to encrypt
the Backup's artifacts.  Inherited from the parent BackupPlan's
[encryption_key][google.cloud.gkebackup.v1.BackupPlan.BackupConfig.encryption_key]
value.

=item * C<< $msg->all_namespaces() >> / C<< $msg->all_namespaces($value) >>

Type: C<Bool>

Output only. If True, all namespaces were included in the Backup.

=item * C<< $msg->selected_namespaces() >> / C<< $msg->selected_namespaces($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Common::Namespaces>)

Output only. If set, the list of namespaces that were included in the
Backup.

=item * C<< $msg->selected_applications() >> / C<< $msg->selected_applications($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Common::NamespacedNames>)

Output only. If set, the list of ProtectedApplications whose resources
were included in the Backup.

=item * C<< $msg->contains_volume_data() >> / C<< $msg->contains_volume_data($value) >>

Type: C<Bool>

Output only. Whether or not the Backup contains volume data.  Controlled by
the parent BackupPlan's
[include_volume_data][google.cloud.gkebackup.v1.BackupPlan.BackupConfig.include_volume_data]
value.

=item * C<< $msg->contains_secrets() >> / C<< $msg->contains_secrets($value) >>

Type: C<Bool>

Output only. Whether or not the Backup contains Kubernetes Secrets.
Controlled by the parent BackupPlan's
[include_secrets][google.cloud.gkebackup.v1.BackupPlan.BackupConfig.include_secrets]
value.

=item * C<< $msg->cluster_metadata() >> / C<< $msg->cluster_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata>)

Output only. Information about the GKE cluster from which this Backup was
created.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::Backup::State>)

Output only. Current state of the Backup

=item * C<< $msg->state_reason() >> / C<< $msg->state_reason($value) >>

Type: C<String>

Output only. Human-readable description of why the backup is in the current
`state`. This field is only meant for human readability and should not be
used programmatically as this field is not guaranteed to be consistent.

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Completion time of the Backup

=item * C<< $msg->resource_count() >> / C<< $msg->resource_count($value) >>

Type: C<Int32>

Output only. The total number of Kubernetes resources included in the
Backup.

=item * C<< $msg->volume_count() >> / C<< $msg->volume_count($value) >>

Type: C<Int32>

Output only. The total number of volume backups contained in the Backup.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

Output only. The total size of the Backup in bytes = config backup size +
sum(volume backup sizes)

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a backup from overwriting each other.
It is strongly suggested that systems make use of the `etag` in the
read-modify-write cycle to perform backup updates in order to avoid
race conditions: An `etag` is returned in the response to `GetBackup`,
and systems are expected to put that etag in the request to
`UpdateBackup` or `DeleteBackup` to ensure that their change will be
applied to the same version of the resource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User specified descriptive string for this Backup.

=item * C<< $msg->pod_count() >> / C<< $msg->pod_count($value) >>

Type: C<Int32>

Output only. The total number of Kubernetes Pods contained in the Backup.

=item * C<< $msg->config_backup_size_bytes() >> / C<< $msg->config_backup_size_bytes($value) >>

Type: C<Int64>

Output only. The size of the config backup in bytes.

=item * C<< $msg->permissive_mode() >> / C<< $msg->permissive_mode($value) >>

Type: C<Bool>

Output only. If false, Backup will fail when Backup for GKE detects
Kubernetes configuration that is non-standard or
requires additional setup to restore.

Inherited from the parent BackupPlan's
[permissive_mode][google.cloud.gkebackup.v1.BackupPlan.BackupConfig.permissive_mode]
value.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. [Output Only] Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. [Output Only] Reserved for future use.

=back

=head3 Enum: Backup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<IN_PROGRESS> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<DELETING> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::Backup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
