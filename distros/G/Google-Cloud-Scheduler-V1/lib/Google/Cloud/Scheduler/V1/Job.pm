package Google::Cloud::Scheduler::V1::Job;

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
    eval { require Google::Cloud::Scheduler::V1::Target };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvc2NoZWR1bGVyL3YxL2pvYi5wcm90bxIZZ29vZ2xlLmNsb3VkLnNj
aGVkdWxlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxomZ29vZ2xlL2Nsb3VkL3NjaGVkdWxlci92MS90YXJnZXQucHJv
dG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8ioQgKA0pvYhISCgRuYW1l
GAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhJOCg1wdWJz
dWJfdGFyZ2V0GAQgASgLMicuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5QdWJzdWJUYXJn
ZXRIAFIMcHVic3ViVGFyZ2V0EmUKFmFwcF9lbmdpbmVfaHR0cF90YXJnZXQYBSABKAsyLi5n
b29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLkFwcEVuZ2luZUh0dHBUYXJnZXRIAFITYXBwRW5n
aW5lSHR0cFRhcmdldBJICgtodHRwX3RhcmdldBgGIAEoCzIlLmdvb2dsZS5jbG91ZC5zY2hl
ZHVsZXIudjEuSHR0cFRhcmdldEgAUgpodHRwVGFyZ2V0EhoKCHNjaGVkdWxlGBQgASgJUghz
Y2hlZHVsZRIbCgl0aW1lX3pvbmUYFSABKAlSCHRpbWVab25lEkkKEHVzZXJfdXBkYXRlX3Rp
bWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDnVzZXJVcGRhdGVU
aW1lEj8KBXN0YXRlGAogASgOMiQuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5Kb2IuU3Rh
dGVCA+BBA1IFc3RhdGUSLwoGc3RhdHVzGAsgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNCA+BB
A1IGc3RhdHVzEkQKDXNjaGVkdWxlX3RpbWUYESABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSDHNjaGVkdWxlVGltZRJLChFsYXN0X2F0dGVtcHRfdGltZRgSIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IPbGFzdEF0dGVtcHRUaW1lEkkKDHJl
dHJ5X2NvbmZpZxgTIAEoCzImLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuUmV0cnlDb25m
aWdSC3JldHJ5Q29uZmlnEkQKEGF0dGVtcHRfZGVhZGxpbmUYFiABKAsyGS5nb29nbGUucHJv
dG9idWYuRHVyYXRpb25SD2F0dGVtcHREZWFkbGluZSJYCgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEgsKB0VOQUJMRUQQARIKCgZQQVVTRUQQAhIMCghESVNBQkxFRBADEhEKDVVQ
REFURV9GQUlMRUQQBDpl6kFiCiFjbG91ZHNjaGVkdWxlci5nb29nbGVhcGlzLmNvbS9Kb2IS
MnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9qb2JzL3tqb2J9KgRq
b2JzMgNqb2JCCAoGdGFyZ2V0IrYCCgtSZXRyeUNvbmZpZxIfCgtyZXRyeV9jb3VudBgBIAEo
BVIKcmV0cnlDb3VudBJHChJtYXhfcmV0cnlfZHVyYXRpb24YAiABKAsyGS5nb29nbGUucHJv
dG9idWYuRHVyYXRpb25SEG1heFJldHJ5RHVyYXRpb24SSwoUbWluX2JhY2tvZmZfZHVyYXRp
b24YAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SEm1pbkJhY2tvZmZEdXJhdGlv
bhJLChRtYXhfYmFja29mZl9kdXJhdGlvbhgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJh
dGlvblISbWF4QmFja29mZkR1cmF0aW9uEiMKDW1heF9kb3VibGluZ3MYBSABKAVSDG1heERv
dWJsaW5nc0JoCh1jb20uZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MUIISm9iUHJvdG9QAVo7
Y2xvdWQuZ29vZ2xlLmNvbS9nby9zY2hlZHVsZXIvYXBpdjEvc2NoZWR1bGVycGI7c2NoZWR1
bGVycGJKnlMKBxIFDgCNAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
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
CgECEgMQACIKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADAKCQoCAwMSAxUAKAoJ
CgIDBBIDFgApCgkKAgMFEgMXACEKCAoBCBIDGQBSCgkKAggLEgMZAFIKCAoBCBIDGgAiCgkK
AggKEgMaACIKCAoBCBIDGwApCgkKAggIEgMbACkKCAoBCBIDHAA2CgkKAggBEgMcADYKUwoC
BAASBSAAwwEBGkYgQ29uZmlndXJhdGlvbiBmb3IgYSBqb2IuCiBUaGUgbWF4aW11bSBhbGxv
d2VkIHNpemUgZm9yIGEgam9iIGlzIDFNQi4KCgoKAwQAARIDIAgLCgsKAwQABxIEIQImBAoN
CgUEAAedCBIEIQImBAohCgQEAAQAEgQpAj8DGhMgU3RhdGUgb2YgdGhlIGpvYi4KCgwKBQQA
BAABEgMpBwwKIwoGBAAEAAIAEgMrBBoaFCBVbnNwZWNpZmllZCBzdGF0ZS4KCg4KBwQABAAC
AAESAysEFQoOCgcEAAQAAgACEgMrGBkKLwoGBAAEAAIBEgMuBBAaICBUaGUgam9iIGlzIGV4
ZWN1dGluZyBub3JtYWxseS4KCg4KBwQABAACAQESAy4ECwoOCgcEAAQAAgECEgMuDg8KsgEK
BgQABAACAhIDMwQPGqIBIFRoZSBqb2IgaXMgcGF1c2VkIGJ5IHRoZSB1c2VyLiBJdCB3aWxs
IG5vdCBleGVjdXRlLiBBIHVzZXIgY2FuCiBpbnRlbnRpb25hbGx5IHBhdXNlIHRoZSBqb2Ig
dXNpbmcKIFtQYXVzZUpvYlJlcXVlc3RdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuUGF1
c2VKb2JSZXF1ZXN0XS4KCg4KBwQABAACAgESAzMECgoOCgcEAAQAAgICEgMzDQ4KdAoGBAAE
AAIDEgM3BBEaZSBUaGUgam9iIGlzIGRpc2FibGVkIGJ5IHRoZSBzeXN0ZW0gZHVlIHRvIGVy
cm9yLiBUaGUgdXNlcgogY2Fubm90IGRpcmVjdGx5IHNldCBhIGpvYiB0byBiZSBkaXNhYmxl
ZC4KCg4KBwQABAACAwESAzcEDAoOCgcEAAQAAgMCEgM3DxAKtQIKBgQABAACBBIDPgQWGqUC
IFRoZSBqb2Igc3RhdGUgcmVzdWx0aW5nIGZyb20gYSBmYWlsZWQKIFtDbG91ZFNjaGVkdWxl
ci5VcGRhdGVKb2JdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIu
VXBkYXRlSm9iXQogb3BlcmF0aW9uLiBUbyByZWNvdmVyIGEgam9iIGZyb20gdGhpcyBzdGF0
ZSwgcmV0cnkKIFtDbG91ZFNjaGVkdWxlci5VcGRhdGVKb2JdW2dvb2dsZS5jbG91ZC5zY2hl
ZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuVXBkYXRlSm9iXQogdW50aWwgYSBzdWNjZXNzZnVs
IHJlc3BvbnNlIGlzIHJlY2VpdmVkLgoKDgoHBAAEAAIEARIDPgQRCg4KBwQABAACBAISAz4U
FQqOBwoEBAACABIDUwISGoAHIE9wdGlvbmFsbHkgY2FsbGVyLXNwZWNpZmllZCBpbgogW0Ny
ZWF0ZUpvYl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5DbG91ZFNjaGVkdWxlci5DcmVh
dGVKb2JdLCBhZnRlcgogd2hpY2ggaXQgYmVjb21lcyBvdXRwdXQgb25seS4KCiBUaGUgam9i
IG5hbWUuIEZvciBleGFtcGxlOgogYHByb2plY3RzL1BST0pFQ1RfSUQvbG9jYXRpb25zL0xP
Q0FUSU9OX0lEL2pvYnMvSk9CX0lEYC4KCiAqIGBQUk9KRUNUX0lEYCBjYW4gY29udGFpbiBs
ZXR0ZXJzIChbQS1aYS16XSksIG51bWJlcnMgKFswLTldKSwKICAgIGh5cGhlbnMgKC0pLCBj
b2xvbnMgKDopLCBvciBwZXJpb2RzICguKS4KICAgIEZvciBtb3JlIGluZm9ybWF0aW9uLCBz
ZWUKICAgIFtJZGVudGlmeWluZwogICAgcHJvamVjdHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctcHJvamVjdHMj
aWRlbnRpZnlpbmdfcHJvamVjdHMpCiAqIGBMT0NBVElPTl9JRGAgaXMgdGhlIGNhbm9uaWNh
bCBJRCBmb3IgdGhlIGpvYidzIGxvY2F0aW9uLgogICAgVGhlIGxpc3Qgb2YgYXZhaWxhYmxl
IGxvY2F0aW9ucyBjYW4gYmUgb2J0YWluZWQgYnkgY2FsbGluZwogICAgW0xpc3RMb2NhdGlv
bnNdW2dvb2dsZS5jbG91ZC5sb2NhdGlvbi5Mb2NhdGlvbnMuTGlzdExvY2F0aW9uc10uCiAg
ICBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9h
Ym91dC9sb2NhdGlvbnMvLgogKiBgSk9CX0lEYCBjYW4gY29udGFpbiBvbmx5IGxldHRlcnMg
KFtBLVphLXpdKSwgbnVtYmVycyAoWzAtOV0pLAogICAgaHlwaGVucyAoLSksIG9yIHVuZGVy
c2NvcmVzIChfKS4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDUwMCBjaGFyYWN0ZXJzLgoKDAoF
BAACAAUSA1MCCAoMCgUEAAIAARIDUwkNCgwKBQQAAgADEgNTEBEKmAIKBAQAAgESA1sCGRqK
AiBPcHRpb25hbGx5IGNhbGxlci1zcGVjaWZpZWQgaW4KIFtDcmVhdGVKb2JdW2dvb2dsZS5j
bG91ZC5zY2hlZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuQ3JlYXRlSm9iXSBvcgogW1VwZGF0
ZUpvYl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5DbG91ZFNjaGVkdWxlci5VcGRhdGVK
b2JdLgoKIEEgaHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24gZm9yIHRoZSBqb2IuIFRoaXMg
c3RyaW5nIG11c3Qgbm90IGNvbnRhaW4KIG1vcmUgdGhhbiA1MDAgY2hhcmFjdGVycy4KCgwK
BQQAAgEFEgNbAggKDAoFBAACAQESA1sJFAoMCgUEAAIBAxIDWxcYClQKBAQACAASBGACaQMa
RiBSZXF1aXJlZC4KCiBEZWxpdmVyeSBzZXR0aW5ncyBjb250YWluaW5nIGRlc3RpbmF0aW9u
IGFuZCBwYXJhbWV0ZXJzLgoKDAoFBAAIAAESA2AIDgoeCgQEAAICEgNiBCMaESBQdWIvU3Vi
IHRhcmdldC4KCgwKBQQAAgIGEgNiBBAKDAoFBAACAgESA2IRHgoMCgUEAAICAxIDYiEiCiYK
BAQAAgMSA2UEMxoZIEFwcCBFbmdpbmUgSFRUUCB0YXJnZXQuCgoMCgUEAAIDBhIDZQQXCgwK
BQQAAgMBEgNlGC4KDAoFBAACAwMSA2UxMgobCgQEAAIEEgNoBB8aDiBIVFRQIHRhcmdldC4K
CgwKBQQAAgQGEgNoBA4KDAoFBAACBAESA2gPGgoMCgUEAAIEAxIDaB0eCu8KCgQEAAIFEgSH
AQIXGuAKIFJlcXVpcmVkLCBleGNlcHQgd2hlbiB1c2VkIHdpdGgKIFtVcGRhdGVKb2JdW2dv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuQ2xvdWRTY2hlZHVsZXIuVXBkYXRlSm9iXS4KCiBE
ZXNjcmliZXMgdGhlIHNjaGVkdWxlIG9uIHdoaWNoIHRoZSBqb2Igd2lsbCBiZSBleGVjdXRl
ZC4KCiBUaGUgc2NoZWR1bGUgY2FuIGJlIGVpdGhlciBvZiB0aGUgZm9sbG93aW5nIHR5cGVz
OgoKICogW0Nyb250YWJdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL0Nyb24jT3Zl
cnZpZXcpCiAqIEVuZ2xpc2gtbGlrZQogW3NjaGVkdWxlXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vc2NoZWR1bGVyL2RvY3MvY29uZmlndXJpbmcvY3Jvbi1qb2Itc2NoZWR1bGVzKQoK
IEFzIGEgZ2VuZXJhbCBydWxlLCBleGVjdXRpb24gYG4gKyAxYCBvZiBhIGpvYiB3aWxsIG5v
dCBiZWdpbgogdW50aWwgZXhlY3V0aW9uIGBuYCBoYXMgZmluaXNoZWQuIENsb3VkIFNjaGVk
dWxlciB3aWxsIG5ldmVyCiBhbGxvdyB0d28gc2ltdWx0YW5lb3VzbHkgb3V0c3RhbmRpbmcg
ZXhlY3V0aW9ucy4gRm9yIGV4YW1wbGUsCiB0aGlzIGltcGxpZXMgdGhhdCBpZiB0aGUgYG4r
MWB0aCBleGVjdXRpb24gaXMgc2NoZWR1bGVkIHRvIHJ1biBhdAogMTY6MDAgYnV0IHRoZSBg
bmB0aCBleGVjdXRpb24gdGFrZXMgdW50aWwgMTY6MTUsIHRoZSBgbisxYHRoCiBleGVjdXRp
b24gd2lsbCBub3Qgc3RhcnQgdW50aWwgYDE2OjE1YC4KIEEgc2NoZWR1bGVkIHN0YXJ0IHRp
bWUgd2lsbCBiZSBkZWxheWVkIGlmIHRoZSBwcmV2aW91cwogZXhlY3V0aW9uIGhhcyBub3Qg
ZW5kZWQgd2hlbiBpdHMgc2NoZWR1bGVkIHRpbWUgb2NjdXJzLgoKIElmIFtyZXRyeV9jb3Vu
dF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5SZXRyeUNvbmZpZy5yZXRyeV9jb3VudF0g
PiAwIGFuZAogYSBqb2IgYXR0ZW1wdCBmYWlscywgdGhlIGpvYiB3aWxsIGJlIHRyaWVkIGEg
dG90YWwgb2YKIFtyZXRyeV9jb3VudF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5SZXRy
eUNvbmZpZy5yZXRyeV9jb3VudF0gdGltZXMsCiB3aXRoIGV4cG9uZW50aWFsIGJhY2tvZmYs
IHVudGlsIHRoZSBuZXh0IHNjaGVkdWxlZCBzdGFydCB0aW1lLiBJZgogcmV0cnlfY291bnQg
aXMgMCwgYSBqb2IgYXR0ZW1wdCB3aWxsIG5vdCBiZSByZXRyaWVkIGlmIGl0IGZhaWxzLiBJ
bnN0ZWFkCiB0aGUgQ2xvdWQgU2NoZWR1bGVyIHN5c3RlbSB3aWxsIHdhaXQgZm9yIHRoZSBu
ZXh0IHNjaGVkdWxlZCBleGVjdXRpb24gdGltZS4KIFNldHRpbmcgcmV0cnlfY291bnQgdG8g
MCBkb2VzIG5vdCBwcmV2ZW50IGZhaWxlZCBqb2JzIGZyb20gcnVubmluZwogYWNjb3JkaW5n
IHRvIHNjaGVkdWxlIGFmdGVyIHRoZSBmYWlsdXJlLgoKDQoFBAACBQUSBIcBAggKDQoFBAAC
BQESBIcBCREKDQoFBAACBQMSBIcBFBYK7wMKBAQAAgYSBJMBAhga4AMgU3BlY2lmaWVzIHRo
ZSB0aW1lIHpvbmUgdG8gYmUgdXNlZCBpbiBpbnRlcnByZXRpbmcKIFtzY2hlZHVsZV1bZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MS5Kb2Iuc2NoZWR1bGVdLiBUaGUgdmFsdWUgb2YgdGhp
cyBmaWVsZAogbXVzdCBiZSBhIHRpbWUgem9uZSBuYW1lIGZyb20gdGhlIFt0egogZGF0YWJh
c2VdKGh0dHA6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvVHpfZGF0YWJhc2UpLgoKIE5vdGUg
dGhhdCBzb21lIHRpbWUgem9uZXMgaW5jbHVkZSBhIHByb3Zpc2lvbiBmb3IKIGRheWxpZ2h0
IHNhdmluZ3MgdGltZS4gVGhlIHJ1bGVzIGZvciBkYXlsaWdodCBzYXZpbmcgdGltZSBhcmUK
IGRldGVybWluZWQgYnkgdGhlIGNob3NlbiB0ei4gRm9yIFVUQyB1c2UgdGhlIHN0cmluZyAi
dXRjIi4gSWYgYQogdGltZSB6b25lIGlzIG5vdCBzcGVjaWZpZWQsIHRoZSBkZWZhdWx0IHdp
bGwgYmUgaW4gVVRDIChhbHNvIGtub3duCiBhcyBHTVQpLgoKDQoFBAACBgUSBJMBAggKDQoF
BAACBgESBJMBCRIKDQoFBAACBgMSBJMBFRcKPAoEBAACBxIGlgEClwEyGiwgT3V0cHV0IG9u
bHkuIFRoZSBjcmVhdGlvbiB0aW1lIG9mIHRoZSBqb2IuCgoNCgUEAAIHBhIElgECGwoNCgUE
AAIHARIElgEcLAoNCgUEAAIHAxIElgEvMAoNCgUEAAIHCBIElwEGMQoQCggEAAIHCJwIABIE
lwEHMAouCgQEAAIIEgSaAQI/GiAgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBqb2IuCgoN
CgUEAAIIBhIEmgECBwoNCgUEAAIIARIEmgEIDQoNCgUEAAIIAxIEmgEQEgoNCgUEAAIICBIE
mgETPgoQCggEAAIICJwIABIEmgEUPQpbCgQEAAIJEgSdAQJMGk0gT3V0cHV0IG9ubHkuIFRo
ZSByZXNwb25zZSBmcm9tIHRoZSB0YXJnZXQgZm9yIHRoZSBsYXN0IGF0dGVtcHRlZCBleGVj
dXRpb24uCgoNCgUEAAIJBhIEnQECEwoNCgUEAAIJARIEnQEUGgoNCgUEAAIJAxIEnQEdHwoN
CgUEAAIJCBIEnQEgSwoQCggEAAIJCJwIABIEnQEhSgq4AQoEBAACChIGogECowEyGqcBIE91
dHB1dCBvbmx5LiBUaGUgbmV4dCB0aW1lIHRoZSBqb2IgaXMgc2NoZWR1bGVkLiBOb3RlIHRo
YXQgdGhpcyBtYXkgYmUgYQogcmV0cnkgb2YgYSBwcmV2aW91c2x5IGZhaWxlZCBhdHRlbXB0
IG9yIHRoZSBuZXh0IGV4ZWN1dGlvbiB0aW1lCiBhY2NvcmRpbmcgdG8gdGhlIHNjaGVkdWxl
LgoKDQoFBAACCgYSBKIBAhsKDQoFBAACCgESBKIBHCkKDQoFBAACCgMSBKIBLC4KDQoFBAAC
CggSBKMBBjEKEAoIBAACCgicCAASBKMBBzAKRQoEBAACCxIGpgECpwEyGjUgT3V0cHV0IG9u
bHkuIFRoZSB0aW1lIHRoZSBsYXN0IGpvYiBhdHRlbXB0IHN0YXJ0ZWQuCgoNCgUEAAILBhIE
pgECGwoNCgUEAAILARIEpgEcLQoNCgUEAAILAxIEpgEwMgoNCgUEAAILCBIEpwEGMQoQCggE
AAILCJwIABIEpwEHMAo7CgQEAAIMEgSqAQIgGi0gU2V0dGluZ3MgdGhhdCBkZXRlcm1pbmUg
dGhlIHJldHJ5IGJlaGF2aW9yLgoKDQoFBAACDAYSBKoBAg0KDQoFBAACDAESBKoBDhoKDQoF
BAACDAMSBKoBHR8K5wgKBAQAAg0SBMIBAjEa2AggVGhlIGRlYWRsaW5lIGZvciBqb2IgYXR0
ZW1wdHMuIElmIHRoZSByZXF1ZXN0IGhhbmRsZXIgZG9lcyBub3QgcmVzcG9uZCBieQogdGhp
cyBkZWFkbGluZSB0aGVuIHRoZSByZXF1ZXN0IGlzIGNhbmNlbGxlZCBhbmQgdGhlIGF0dGVt
cHQgaXMgbWFya2VkIGFzIGEKIGBERUFETElORV9FWENFRURFRGAgZmFpbHVyZS4gVGhlIGZh
aWxlZCBhdHRlbXB0IGNhbiBiZSB2aWV3ZWQgaW4KIGV4ZWN1dGlvbiBsb2dzLiBDbG91ZCBT
Y2hlZHVsZXIgd2lsbCByZXRyeSB0aGUgam9iIGFjY29yZGluZwogdG8gdGhlIFtSZXRyeUNv
bmZpZ11bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5SZXRyeUNvbmZpZ10uCgogVGhlIGRl
ZmF1bHQgYW5kIHRoZSBhbGxvd2VkIHZhbHVlcyBkZXBlbmQgb24gdGhlIHR5cGUgb2YgdGFy
Z2V0OgoKICogRm9yIFtIVFRQIHRhcmdldHNdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEu
Sm9iLmh0dHBfdGFyZ2V0XSwgdGhlCiBkZWZhdWx0IGlzIDMgbWludXRlcy4gVGhlIGRlYWRs
aW5lIG11c3QgYmUgaW4gdGhlIGludGVydmFsIFsxNSBzZWNvbmRzLCAzMAogbWludXRlc10u
CgogKiBGb3IgW0FwcCBFbmdpbmUgSFRUUAogdGFyZ2V0c11bZ29vZ2xlLmNsb3VkLnNjaGVk
dWxlci52MS5Kb2IuYXBwX2VuZ2luZV9odHRwX3RhcmdldF0sIDAgaW5kaWNhdGVzCiB0aGF0
IHRoZSByZXF1ZXN0IGhhcyB0aGUgZGVmYXVsdCBkZWFkbGluZS4gVGhlIGRlZmF1bHQgZGVh
ZGxpbmUgZGVwZW5kcyBvbgogdGhlIHNjYWxpbmcgdHlwZSBvZiB0aGUgc2VydmljZTogMTAg
bWludXRlcyBmb3Igc3RhbmRhcmQgYXBwcyB3aXRoCiBhdXRvbWF0aWMgc2NhbGluZywgMjQg
aG91cnMgZm9yIHN0YW5kYXJkIGFwcHMgd2l0aCBtYW51YWwgYW5kIGJhc2ljCiBzY2FsaW5n
LCBhbmQgNjAgbWludXRlcyBmb3IgZmxleCBhcHBzLiBJZiB0aGUgcmVxdWVzdCBkZWFkbGlu
ZSBpcyBzZXQsIGl0CiBtdXN0IGJlIGluIHRoZSBpbnRlcnZhbCBbMTUgc2Vjb25kcywgMjQg
aG91cnMgMTUgc2Vjb25kc10uCgogKiBGb3IgW1B1Yi9TdWIgdGFyZ2V0c11bZ29vZ2xlLmNs
b3VkLnNjaGVkdWxlci52MS5Kb2IucHVic3ViX3RhcmdldF0sIHRoaXMKIGZpZWxkIGlzIGln
bm9yZWQuCgoNCgUEAAINBhIEwgECGgoNCgUEAAINARIEwgEbKwoNCgUEAAINAxIEwgEuMAq8
AgoCBAESBssBAI0CARqtAiBTZXR0aW5ncyB0aGF0IGRldGVybWluZSB0aGUgcmV0cnkgYmVo
YXZpb3IuCgogQnkgZGVmYXVsdCwgaWYgYSBqb2IgZG9lcyBub3QgY29tcGxldGUgc3VjY2Vz
c2Z1bGx5IChtZWFuaW5nIHRoYXQKIGFuIGFja25vd2xlZGdlbWVudCBpcyBub3QgcmVjZWl2
ZWQgZnJvbSB0aGUgaGFuZGxlciwgdGhlbiBpdCB3aWxsIGJlIHJldHJpZWQKIHdpdGggZXhw
b25lbnRpYWwgYmFja29mZiBhY2NvcmRpbmcgdG8gdGhlIHNldHRpbmdzIGluCiBbUmV0cnlD
b25maWddW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuUmV0cnlDb25maWddLgoKCwoDBAEB
EgTLAQgTCo8GCgQEAQIAEgTdAQIYGoAGIFRoZSBudW1iZXIgb2YgYXR0ZW1wdHMgdGhhdCB0
aGUgc3lzdGVtIHdpbGwgbWFrZSB0byBydW4gYSBqb2IgdXNpbmcgdGhlCiBleHBvbmVudGlh
bCBiYWNrb2ZmIHByb2NlZHVyZSBkZXNjcmliZWQgYnkKIFttYXhfZG91YmxpbmdzXVtnb29n
bGUuY2xvdWQuc2NoZWR1bGVyLnYxLlJldHJ5Q29uZmlnLm1heF9kb3VibGluZ3NdLgoKIFRo
ZSBkZWZhdWx0IHZhbHVlIG9mIHJldHJ5X2NvdW50IGlzIHplcm8uCgogSWYgcmV0cnlfY291
bnQgaXMgMCwgYSBqb2IgYXR0ZW1wdCB3aWxsIG5vdCBiZSByZXRyaWVkIGlmCiBpdCBmYWls
cy4gSW5zdGVhZCB0aGUgQ2xvdWQgU2NoZWR1bGVyIHN5c3RlbSB3aWxsIHdhaXQgZm9yIHRo
ZQogbmV4dCBzY2hlZHVsZWQgZXhlY3V0aW9uIHRpbWUuIFNldHRpbmcgcmV0cnlfY291bnQg
dG8gMCBkb2VzIG5vdCBwcmV2ZW50CiBmYWlsZWQgam9icyBmcm9tIHJ1bm5pbmcgYWNjb3Jk
aW5nIHRvIHNjaGVkdWxlIGFmdGVyIHRoZSBmYWlsdXJlLgoKIElmIHJldHJ5X2NvdW50IGlz
IHNldCB0byBhIG5vbi16ZXJvIG51bWJlciB0aGVuIENsb3VkIFNjaGVkdWxlcgogd2lsbCBy
ZXRyeSBmYWlsZWQgYXR0ZW1wdHMsIHVzaW5nIGV4cG9uZW50aWFsIGJhY2tvZmYsCiByZXRy
eV9jb3VudCB0aW1lcywgb3IgdW50aWwgdGhlIG5leHQgc2NoZWR1bGVkIGV4ZWN1dGlvbiB0
aW1lLAogd2hpY2hldmVyIGNvbWVzIGZpcnN0LgoKIFZhbHVlcyBncmVhdGVyIHRoYW4gNSBh
bmQgbmVnYXRpdmUgdmFsdWVzIGFyZSBub3QgYWxsb3dlZC4KCg0KBQQBAgAFEgTdAQIHCg0K
BQQBAgABEgTdAQgTCg0KBQQBAgADEgTdARYXCuACCgQEAQIBEgTmAQIyGtECIFRoZSB0aW1l
IGxpbWl0IGZvciByZXRyeWluZyBhIGZhaWxlZCBqb2IsIG1lYXN1cmVkIGZyb20gdGltZSB3
aGVuIGFuCiBleGVjdXRpb24gd2FzIGZpcnN0IGF0dGVtcHRlZC4gSWYgc3BlY2lmaWVkIHdp
dGgKIFtyZXRyeV9jb3VudF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5SZXRyeUNvbmZp
Zy5yZXRyeV9jb3VudF0sIHRoZSBqb2IKIHdpbGwgYmUgcmV0cmllZCB1bnRpbCBib3RoIGxp
bWl0cyBhcmUgcmVhY2hlZC4KCiBUaGUgZGVmYXVsdCB2YWx1ZSBmb3IgbWF4X3JldHJ5X2R1
cmF0aW9uIGlzIHplcm8sIHdoaWNoIG1lYW5zIHJldHJ5CiBkdXJhdGlvbiBpcyB1bmxpbWl0
ZWQuCgoNCgUEAQIBBhIE5gECGgoNCgUEAQIBARIE5gEbLQoNCgUEAQIBAxIE5gEwMQqJAQoE
BAECAhIE7AECNBp7IFRoZSBtaW5pbXVtIGFtb3VudCBvZiB0aW1lIHRvIHdhaXQgYmVmb3Jl
IHJldHJ5aW5nIGEgam9iIGFmdGVyCiBpdCBmYWlscy4KCiBUaGUgZGVmYXVsdCB2YWx1ZSBv
ZiB0aGlzIGZpZWxkIGlzIDUgc2Vjb25kcy4KCg0KBQQBAgIGEgTsAQIaCg0KBQQBAgIBEgTs
ARsvCg0KBQQBAgIDEgTsATIzCoYBCgQEAQIDEgTyAQI0GnggVGhlIG1heGltdW0gYW1vdW50
IG9mIHRpbWUgdG8gd2FpdCBiZWZvcmUgcmV0cnlpbmcgYSBqb2IgYWZ0ZXIKIGl0IGZhaWxz
LgoKIFRoZSBkZWZhdWx0IHZhbHVlIG9mIHRoaXMgZmllbGQgaXMgMSBob3VyLgoKDQoFBAEC
AwYSBPIBAhoKDQoFBAECAwESBPIBGy8KDQoFBAECAwMSBPIBMjMKnAkKBAQBAgQSBIwCAhoa
jQkgVGhlIHRpbWUgYmV0d2VlbiByZXRyaWVzIHdpbGwgZG91YmxlIGBtYXhfZG91Ymxpbmdz
YCB0aW1lcy4KCiBBIGpvYidzIHJldHJ5IGludGVydmFsIHN0YXJ0cyBhdAogW21pbl9iYWNr
b2ZmX2R1cmF0aW9uXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLlJldHJ5Q29uZmlnLm1p
bl9iYWNrb2ZmX2R1cmF0aW9uXSwKIHRoZW4gZG91YmxlcyBgbWF4X2RvdWJsaW5nc2AgdGlt
ZXMsIHRoZW4gaW5jcmVhc2VzIGxpbmVhcmx5LCBhbmQgZmluYWxseQogcmV0cmllcyBhdCBp
bnRlcnZhbHMgb2YKIFttYXhfYmFja29mZl9kdXJhdGlvbl1bZ29vZ2xlLmNsb3VkLnNjaGVk
dWxlci52MS5SZXRyeUNvbmZpZy5tYXhfYmFja29mZl9kdXJhdGlvbl0KIHVwIHRvIFtyZXRy
eV9jb3VudF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5SZXRyeUNvbmZpZy5yZXRyeV9j
b3VudF0KIHRpbWVzLgoKIEZvciBleGFtcGxlLCBpZgogW21pbl9iYWNrb2ZmX2R1cmF0aW9u
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxLlJldHJ5Q29uZmlnLm1pbl9iYWNrb2ZmX2R1
cmF0aW9uXQogaXMgMTBzLAogW21heF9iYWNrb2ZmX2R1cmF0aW9uXVtnb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxLlJldHJ5Q29uZmlnLm1heF9iYWNrb2ZmX2R1cmF0aW9uXQogaXMgMzAw
cywgYW5kIGBtYXhfZG91YmxpbmdzYCBpcyAzLCB0aGVuIHRoZSBqb2Igd2lsbCBmaXJzdCBi
ZSByZXRyaWVkIGluCiAxMHMuIFRoZSByZXRyeSBpbnRlcnZhbCB3aWxsIGRvdWJsZSB0aHJl
ZSB0aW1lcywgYW5kIHRoZW4gaW5jcmVhc2UgbGluZWFybHkKIGJ5IDJeMyAqIDEwcy4gIEZp
bmFsbHksIHRoZSBqb2Igd2lsbCByZXRyeSBhdCBpbnRlcnZhbHMgb2YKIFttYXhfYmFja29m
Zl9kdXJhdGlvbl1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MS5SZXRyeUNvbmZpZy5tYXhf
YmFja29mZl9kdXJhdGlvbl0KIHVudGlsIHRoZSBqb2IgaGFzIGJlZW4gYXR0ZW1wdGVkCiBb
cmV0cnlfY291bnRdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjEuUmV0cnlDb25maWcucmV0
cnlfY291bnRdIHRpbWVzLgogVGh1cywgdGhlIHJlcXVlc3RzIHdpbGwgcmV0cnkgYXQgMTBz
LCAyMHMsIDQwcywgODBzLCAxNjBzLCAyNDBzLCAzMDBzLAogMzAwcywgLi4uLgoKIFRoZSBk
ZWZhdWx0IHZhbHVlIG9mIHRoaXMgZmllbGQgaXMgNS4KCg0KBQQBAgQFEgSMAgIHCg0KBQQB
AgQBEgSMAggVCg0KBQQBAgQDEgSMAhgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Scheduler::V1::Job::Job ===
    # Fields for Job
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: pubsub_target Type: 11 (.google.cloud.scheduler.v1.PubsubTarget)
    # Field: app_engine_http_target Type: 11 (.google.cloud.scheduler.v1.AppEngineHttpTarget)
    # Field: http_target Type: 11 (.google.cloud.scheduler.v1.HttpTarget)
    # Field: schedule Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: user_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.scheduler.v1.Job.State)
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: schedule_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_attempt_time Type: 11 (.google.protobuf.Timestamp)
    # Field: retry_config Type: 11 (.google.cloud.scheduler.v1.RetryConfig)
    # Field: attempt_deadline Type: 11 (.google.protobuf.Duration)

# Enum: Job::State
our $Job_STATE_UNSPECIFIED = 0;
our $Job_ENABLED = 1;
our $Job_PAUSED = 2;
our $Job_DISABLED = 3;
our $Job_UPDATE_FAILED = 4;

# === Message: Google::Cloud::Scheduler::V1::Job::RetryConfig ===
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

Google::Cloud::Scheduler::V1::Job - Compiled Protocol Buffers messages for google/cloud/scheduler/v1/job.proto

=head1 SYNOPSIS

    use Google::Cloud::Scheduler::V1::Job;

    my $msg = Google::Cloud::Scheduler::V1::Job::Job->new({
        name => $name,
        description => $description,
        pubsub_target => $pubsub_target,
        app_engine_http_target => $app_engine_http_target,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Scheduler::V1::Job::Job->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/scheduler/v1/job.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Scheduler::V1::Job::Job

Configuration for a job.
The maximum allowed size for a job is 1MB.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optionally caller-specified in
[CreateJob][google.cloud.scheduler.v1.CloudScheduler.CreateJob], after
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
[CreateJob][google.cloud.scheduler.v1.CloudScheduler.CreateJob] or
[UpdateJob][google.cloud.scheduler.v1.CloudScheduler.UpdateJob].

A human-readable description for the job. This string must not contain
more than 500 characters.

=item * C<< $msg->pubsub_target() >> / C<< $msg->pubsub_target($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::PubsubTarget>)

Pub/Sub target.

=item * C<< $msg->app_engine_http_target() >> / C<< $msg->app_engine_http_target($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::AppEngineHttpTarget>)

App Engine HTTP target.

=item * C<< $msg->http_target() >> / C<< $msg->http_target($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Target::HttpTarget>)

HTTP target.

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<String>

Required, except when used with
[UpdateJob][google.cloud.scheduler.v1.CloudScheduler.UpdateJob].

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

If [retry_count][google.cloud.scheduler.v1.RetryConfig.retry_count] > 0 and
a job attempt fails, the job will be tried a total of
[retry_count][google.cloud.scheduler.v1.RetryConfig.retry_count] times,
with exponential backoff, until the next scheduled start time. If
retry_count is 0, a job attempt will not be retried if it fails. Instead
the Cloud Scheduler system will wait for the next scheduled execution time.
Setting retry_count to 0 does not prevent failed jobs from running
according to schedule after the failure.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Specifies the time zone to be used in interpreting
[schedule][google.cloud.scheduler.v1.Job.schedule]. The value of this field
must be a time zone name from the [tz
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

Type: C<Enum> (L<Google::Cloud::Scheduler::V1::Job::State>)

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

Type: C<Message> (L<Google::Cloud::Scheduler::V1::Job::RetryConfig>)

Settings that determine the retry behavior.

=item * C<< $msg->attempt_deadline() >> / C<< $msg->attempt_deadline($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The deadline for job attempts. If the request handler does not respond by
this deadline then the request is cancelled and the attempt is marked as a
`DEADLINE_EXCEEDED` failure. The failed attempt can be viewed in
execution logs. Cloud Scheduler will retry the job according
to the [RetryConfig][google.cloud.scheduler.v1.RetryConfig].

The default and the allowed values depend on the type of target:

* For [HTTP targets][google.cloud.scheduler.v1.Job.http_target], the
default is 3 minutes. The deadline must be in the interval [15 seconds, 30
minutes].

* For [App Engine HTTP
targets][google.cloud.scheduler.v1.Job.app_engine_http_target], 0 indicates
that the request has the default deadline. The default deadline depends on
the scaling type of the service: 10 minutes for standard apps with
automatic scaling, 24 hours for standard apps with manual and basic
scaling, and 60 minutes for flex apps. If the request deadline is set, it
must be in the interval [15 seconds, 24 hours 15 seconds].

* For [Pub/Sub targets][google.cloud.scheduler.v1.Job.pubsub_target], this
field is ignored.

=back

=head3 Enum: Job::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<PAUSED> => C<2>

=item * C<DISABLED> => C<3>

=item * C<UPDATE_FAILED> => C<4>

=back

=head2 Google::Cloud::Scheduler::V1::Job::RetryConfig

Settings that determine the retry behavior.

By default, if a job does not complete successfully (meaning that
an acknowledgement is not received from the handler, then it will be retried
with exponential backoff according to the settings in
[RetryConfig][google.cloud.scheduler.v1.RetryConfig].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->retry_count() >> / C<< $msg->retry_count($value) >>

Type: C<Int32>

The number of attempts that the system will make to run a job using the
exponential backoff procedure described by
[max_doublings][google.cloud.scheduler.v1.RetryConfig.max_doublings].

The default value of retry_count is zero.

If retry_count is 0, a job attempt will not be retried if
it fails. Instead the Cloud Scheduler system will wait for the
next scheduled execution time. Setting retry_count to 0 does not prevent
failed jobs from running according to schedule after the failure.

If retry_count is set to a non-zero number then Cloud Scheduler
will retry failed attempts, using exponential backoff,
retry_count times, or until the next scheduled execution time,
whichever comes first.

Values greater than 5 and negative values are not allowed.

=item * C<< $msg->max_retry_duration() >> / C<< $msg->max_retry_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The time limit for retrying a failed job, measured from time when an
execution was first attempted. If specified with
[retry_count][google.cloud.scheduler.v1.RetryConfig.retry_count], the job
will be retried until both limits are reached.

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
[min_backoff_duration][google.cloud.scheduler.v1.RetryConfig.min_backoff_duration],
then doubles `max_doublings` times, then increases linearly, and finally
retries at intervals of
[max_backoff_duration][google.cloud.scheduler.v1.RetryConfig.max_backoff_duration]
up to [retry_count][google.cloud.scheduler.v1.RetryConfig.retry_count]
times.

For example, if
[min_backoff_duration][google.cloud.scheduler.v1.RetryConfig.min_backoff_duration]
is 10s,
[max_backoff_duration][google.cloud.scheduler.v1.RetryConfig.max_backoff_duration]
is 300s, and `max_doublings` is 3, then the job will first be retried in
10s. The retry interval will double three times, and then increase linearly
by 2^3 * 10s.  Finally, the job will retry at intervals of
[max_backoff_duration][google.cloud.scheduler.v1.RetryConfig.max_backoff_duration]
until the job has been attempted
[retry_count][google.cloud.scheduler.v1.RetryConfig.retry_count] times.
Thus, the requests will retry at 10s, 20s, 40s, 80s, 160s, 240s, 300s,
300s, ....

The default value of this field is 5.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Scheduler::V1::Job::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
