package Google::Cloud::Run::V2::Revision;

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
    eval { require Google::Api::LaunchStage };
    eval { require Google::Api::Resource };
    eval { require Google::Api::Routing };
    eval { require Google::Cloud::Run::V2::Condition };
    eval { require Google::Cloud::Run::V2::K8sMin };
    eval { require Google::Cloud::Run::V2::Sandbox };
    eval { require Google::Cloud::Run::V2::Status };
    eval { require Google::Cloud::Run::V2::VendorSettings };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvcnVuL3YyL3JldmlzaW9uLnByb3RvEhNnb29nbGUuY2xvdWQucnVu
LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5w
cm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxodZ29vZ2xlL2FwaS9sYXVu
Y2hfc3RhZ2UucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aGGdvb2dsZS9hcGkv
cm91dGluZy5wcm90bxojZ29vZ2xlL2Nsb3VkL3J1bi92Mi9jb25kaXRpb24ucHJvdG8aIWdv
b2dsZS9jbG91ZC9ydW4vdjIvazhzLm1pbi5wcm90bxohZ29vZ2xlL2Nsb3VkL3J1bi92Mi9z
YW5kYm94LnByb3RvGiBnb29nbGUvY2xvdWQvcnVuL3YyL3N0YXR1cy5wcm90bxopZ29vZ2xl
L2Nsb3VkL3J1bi92Mi92ZW5kb3Jfc2V0dGluZ3MucHJvdG8aI2dvb2dsZS9sb25ncnVubmlu
Zy9vcGVyYXRpb25zLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iTQoSR2V0UmV2aXNpb25SZXF1ZXN0EjcK
BG5hbWUYASABKAlCI+BBAvpBHQobcnVuLmdvb2dsZWFwaXMuY29tL1JldmlzaW9uUgRuYW1l
IrIBChRMaXN0UmV2aXNpb25zUmVxdWVzdBI7CgZwYXJlbnQYASABKAlCI+BBAvpBHRIbcnVu
Lmdvb2dsZWFwaXMuY29tL1JldmlzaW9uUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghw
YWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SIQoMc2hvd19kZWxldGVk
GAQgASgIUgtzaG93RGVsZXRlZCJ8ChVMaXN0UmV2aXNpb25zUmVzcG9uc2USOwoJcmV2aXNp
b25zGAEgAygLMh0uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5SZXZpc2lvblIJcmV2aXNpb25zEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKJAQoVRGVsZXRlUmV2aXNp
b25SZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobcnVuLmdvb2dsZWFwaXMuY29tL1Jl
dmlzaW9uUgRuYW1lEiMKDXZhbGlkYXRlX29ubHkYAiABKAhSDHZhbGlkYXRlT25seRISCgRl
dGFnGAMgASgJUgRldGFnIqEVCghSZXZpc2lvbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUS
FQoDdWlkGAIgASgJQgPgQQNSA3VpZBIjCgpnZW5lcmF0aW9uGAMgASgDQgPgQQNSCmdlbmVy
YXRpb24SRgoGbGFiZWxzGAQgAygLMikuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5SZXZpc2lvbi5M
YWJlbHNFbnRyeUID4EEDUgZsYWJlbHMSVQoLYW5ub3RhdGlvbnMYBSADKAsyLi5nb29nbGUu
Y2xvdWQucnVuLnYyLlJldmlzaW9uLkFubm90YXRpb25zRW50cnlCA+BBA1ILYW5ub3RhdGlv
bnMSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLZGVsZXRlX3RpbWUYCCABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmRlbGV0ZVRpbWUSQAoLZXhwaXJlX3RpbWUY
CSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmV4cGlyZVRpbWUSOgoM
bGF1bmNoX3N0YWdlGAogASgOMhcuZ29vZ2xlLmFwaS5MYXVuY2hTdGFnZVILbGF1bmNoU3Rh
Z2USPAoHc2VydmljZRgLIAEoCUIi4EED+kEcChpydW4uZ29vZ2xlYXBpcy5jb20vU2Vydmlj
ZVIHc2VydmljZRI+CgdzY2FsaW5nGAwgASgLMiQuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5SZXZp
c2lvblNjYWxpbmdSB3NjYWxpbmcSPQoKdnBjX2FjY2VzcxgNIAEoCzIeLmdvb2dsZS5jbG91
ZC5ydW4udjIuVnBjQWNjZXNzUgl2cGNBY2Nlc3MSRwogbWF4X2luc3RhbmNlX3JlcXVlc3Rf
Y29uY3VycmVuY3kYIiABKAVSHW1heEluc3RhbmNlUmVxdWVzdENvbmN1cnJlbmN5EjMKB3Rp
bWVvdXQYDyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SB3RpbWVvdXQSJwoPc2Vy
dmljZV9hY2NvdW50GBAgASgJUg5zZXJ2aWNlQWNjb3VudBI+Cgpjb250YWluZXJzGBEgAygL
Mh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5Db250YWluZXJSCmNvbnRhaW5lcnMSTAoJc2FuZGJv
eGVzGDggASgLMikuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5TYW5kYm94Q29uZmlndXJhdGlvbkID
4EEDUglzYW5kYm94ZXMSNQoHdm9sdW1lcxgSIAMoCzIbLmdvb2dsZS5jbG91ZC5ydW4udjIu
Vm9sdW1lUgd2b2x1bWVzEl4KFWV4ZWN1dGlvbl9lbnZpcm9ubWVudBgUIAEoDjIpLmdvb2ds
ZS5jbG91ZC5ydW4udjIuRXhlY3V0aW9uRW52aXJvbm1lbnRSFGV4ZWN1dGlvbkVudmlyb25t
ZW50Ek0KDmVuY3J5cHRpb25fa2V5GBUgASgJQib6QSMKIWNsb3Vka21zLmdvb2dsZWFwaXMu
Y29tL0NyeXB0b0tleVINZW5jcnlwdGlvbktleRJDCgxzZXJ2aWNlX21lc2gYFiABKAsyIC5n
b29nbGUuY2xvdWQucnVuLnYyLlNlcnZpY2VNZXNoUgtzZXJ2aWNlTWVzaBJ7CiBlbmNyeXB0
aW9uX2tleV9yZXZvY2F0aW9uX2FjdGlvbhgXIAEoDjIyLmdvb2dsZS5jbG91ZC5ydW4udjIu
RW5jcnlwdGlvbktleVJldm9jYXRpb25BY3Rpb25SHWVuY3J5cHRpb25LZXlSZXZvY2F0aW9u
QWN0aW9uEmIKIGVuY3J5cHRpb25fa2V5X3NodXRkb3duX2R1cmF0aW9uGBggASgLMhkuZ29v
Z2xlLnByb3RvYnVmLkR1cmF0aW9uUh1lbmNyeXB0aW9uS2V5U2h1dGRvd25EdXJhdGlvbhIl
CgtyZWNvbmNpbGluZxgeIAEoCEID4EEDUgtyZWNvbmNpbGluZxJDCgpjb25kaXRpb25zGB8g
AygLMh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5Db25kaXRpb25CA+BBA1IKY29uZGl0aW9ucxI0
ChNvYnNlcnZlZF9nZW5lcmF0aW9uGCAgASgDQgPgQQNSEm9ic2VydmVkR2VuZXJhdGlvbhIc
Cgdsb2dfdXJpGCEgASgJQgPgQQNSBmxvZ1VyaRIoCg1zYXRpc2ZpZXNfcHpzGCUgASgIQgPg
QQNSDHNhdGlzZmllc1B6cxIpChBzZXNzaW9uX2FmZmluaXR5GCYgASgIUg9zZXNzaW9uQWZm
aW5pdHkSVgoOc2NhbGluZ19zdGF0dXMYJyABKAsyKi5nb29nbGUuY2xvdWQucnVuLnYyLlJl
dmlzaW9uU2NhbGluZ1N0YXR1c0ID4EEDUg1zY2FsaW5nU3RhdHVzEkYKDW5vZGVfc2VsZWN0
b3IYKCABKAsyIS5nb29nbGUuY2xvdWQucnVuLnYyLk5vZGVTZWxlY3RvclIMbm9kZVNlbGVj
dG9yEmoKGHdvcmtsb2FkX2lkZW50aXR5X2NvbmZpZxg0IAEoCzIrLmdvb2dsZS5jbG91ZC5y
dW4udjIuV29ya2xvYWRJZGVudGl0eUNvbmZpZ0ID4EEBUhZ3b3JrbG9hZElkZW50aXR5Q29u
ZmlnEk4KHWdwdV96b25hbF9yZWR1bmRhbmN5X2Rpc2FibGVkGDAgASgIQgbgQQHgQQNIAFIa
Z3B1Wm9uYWxSZWR1bmRhbmN5RGlzYWJsZWSIAQESHQoHY3JlYXRvchgxIAEoCUID4EEDUgdj
cmVhdG9yEhsKBmNsaWVudBg1IAEoCUID4EEDUgZjbGllbnQSKgoOY2xpZW50X3ZlcnNpb24Y
NiABKAlCA+BBA1INY2xpZW50VmVyc2lvbhJaChJhbWJpZW50X25ldHdvcmtpbmcYOyABKAsy
Ji5nb29nbGUuY2xvdWQucnVuLnYyLkFtYmllbnROZXR3b3JraW5nQgPgQQNSEWFtYmllbnRO
ZXR3b3JraW5nEhcKBGV0YWcYYyABKAlCA+BBA1IEZXRhZxo5CgtMYWJlbHNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj4KEEFubm90YXRpb25z
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATp06kFx
ChtydW4uZ29vZ2xlYXBpcy5jb20vUmV2aXNpb24ST3Byb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlcy97c2VydmljZX0vcmV2aXNpb25zL3tyZXZpc2lv
bn1SAQFCIAoeX2dwdV96b25hbF9yZWR1bmRhbmN5X2Rpc2FibGVkMpYICglSZXZpc2lvbnMS
kgIKC0dldFJldmlzaW9uEicuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5HZXRSZXZpc2lvblJlcXVl
c3QaHS5nb29nbGUuY2xvdWQucnVuLnYyLlJldmlzaW9uIroBgtPkkwJ5EjgvdjIve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZXJ2aWNlcy8qL3JldmlzaW9ucy8qfVo9EjsvdjIv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi93b3JrZXJQb29scy8qL3JldmlzaW9ucy8q
fYrT5JMCLhIsCgRuYW1lEiRwcm9qZWN0cy8qL2xvY2F0aW9ucy97bG9jYXRpb249Kn0vKira
QQRuYW1lEqcCCg1MaXN0UmV2aXNpb25zEikuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5MaXN0UmV2
aXNpb25zUmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5ydW4udjIuTGlzdFJldmlzaW9uc1Jlc3Bv
bnNlIr4BgtPkkwJ5EjgvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3NlcnZp
Y2VzLyp9L3JldmlzaW9uc1o9EjsvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3dvcmtlclBvb2xzLyp9L3JldmlzaW9uc4rT5JMCMBIuCgZwYXJlbnQSJHByb2plY3RzLyov
bG9jYXRpb25zL3tsb2NhdGlvbj0qfS8qKtpBBnBhcmVudBKvAgoORGVsZXRlUmV2aXNpb24S
Ki5nb29nbGUuY2xvdWQucnVuLnYyLkRlbGV0ZVJldmlzaW9uUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24i0QGC0+STAnkqOC92Mi97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL3NlcnZpY2VzLyovcmV2aXNpb25zLyp9Wj0qOy92Mi97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3dvcmtlclBvb2xzLyovcmV2aXNpb25zLyp9itPkkwIuEiwKBG5h
bWUSJHByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlvbj0qfS8qKtpBBG5hbWXKQRQKCFJl
dmlzaW9uEghSZXZpc2lvbhqXAcpBEnJ1bi5nb29nbGVhcGlzLmNvbdJBf2h0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9ydW4saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9ydW4u
cmVhZG9ubHlCVQoXY29tLmdvb2dsZS5jbG91ZC5ydW4udjJCDVJldmlzaW9uUHJvdG9QAVop
Y2xvdWQuZ29vZ2xlLmNvbS9nby9ydW4vYXBpdjIvcnVucGI7cnVucGJKllsKBxIFDgDfAgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIA
JgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAJwoJCgIDBBIDFgAjCgkKAgMFEgMX
ACIKCQoCAwYSAxgALQoJCgIDBxIDGQArCgkKAgMIEgMaACsKCQoCAwkSAxsAKgoJCgIDChID
HAAzCgkKAgMLEgMdAC0KCQoCAwwSAx4AKAoJCgIDDRIDHwApCggKAQgSAyEAQAoJCgIICxID
IQBACggKAQgSAyIAIgoJCgIIChIDIgAiCggKAQgSAyMALgoJCgIICBIDIwAuCggKAQgSAyQA
MAoJCgIIARIDJAAwCjMKAgYAEgQnAGYBGicgQ2xvdWQgUnVuIFJldmlzaW9uIENvbnRyb2wg
UGxhbmUgQVBJLgoKCgoDBgABEgMnCBEKCgoDBgADEgMoAjoKDAoFBgADmQgSAygCOgoLCgMG
AAMSBCkCLDUKDQoFBgADmggSBCkCLDUKMgoEBgACABIELwI9AxokIEdldHMgaW5mb3JtYXRp
b24gYWJvdXQgYSBSZXZpc2lvbi4KCgwKBQYAAgABEgMvBhEKDAoFBgACAAISAy8SJAoMCgUG
AAIAAxIDLy83Cg0KBQYAAgAEEgQwBDUGChEKCQYAAgAEsMq8IhIEMAQ1BgoNCgUGAAIABBIE
NgQ7BgoRCgkGAAIABLHKvCISBDYEOwYKDAoFBgACAAQSAzwEMgoPCggGAAIABJsIABIDPAQy
CoIBCgQGAAIBEgRBAk8DGnQgTGlzdHMgUmV2aXNpb25zIGZyb20gYSBnaXZlbiBTZXJ2aWNl
LCBvciBmcm9tIGEgZ2l2ZW4gbG9jYXRpb24uICBSZXN1bHRzCiBhcmUgc29ydGVkIGJ5IGNy
ZWF0aW9uIHRpbWUsIGRlc2NlbmRpbmcuCgoMCgUGAAIBARIDQQYTCgwKBQYAAgECEgNBFCgK
DAoFBgACAQMSA0EzSAoNCgUGAAIBBBIEQgRHBgoRCgkGAAIBBLDKvCISBEIERwYKDQoFBgAC
AQQSBEgETQYKEQoJBgACAQSxyrwiEgRIBE0GCgwKBQYAAgEEEgNOBDQKDwoIBgACAQSbCAAS
A04ENAojCgQGAAICEgRSAmUDGhUgRGVsZXRlcyBhIFJldmlzaW9uLgoKDAoFBgACAgESA1IG
FAoMCgUGAAICAhIDUhUqCgwKBQYAAgIDEgNTDysKDQoFBgACAgQSBFQEWQYKEQoJBgACAgSw
yrwiEgRUBFkGCg0KBQYAAgIEEgRaBF8GChEKCQYAAgIEscq8IhIEWgRfBgoMCgUGAAICBBID
YAQyCg8KCAYAAgIEmwgAEgNgBDIKDQoFBgACAgQSBGEEZAYKDwoHBgACAgSZCBIEYQRkBgpI
CgIEABIEaQBxARo8IFJlcXVlc3QgbWVzc2FnZSBmb3Igb2J0YWluaW5nIGEgUmV2aXNpb24g
YnkgaXRzIGZ1bGwgbmFtZS4KCgoKAwQAARIDaQgaCpMBCgQEAAIAEgRtAnAEGoQBIFJlcXVp
cmVkLiBUaGUgZnVsbCBuYW1lIG9mIHRoZSBSZXZpc2lvbi4KIEZvcm1hdDoKIHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlcy97c2VydmljZX0vcmV2
aXNpb25zL3tyZXZpc2lvbn0KCgwKBQQAAgAFEgNtAggKDAoFBAACAAESA20JDQoMCgUEAAIA
AxIDbRARCg0KBQQAAgAIEgRtEnADCg8KCAQAAgAInAgAEgNuBCoKDgoHBAACAAifCBIDbwRN
CkIKAgQBEgV0AIkBARo1IFJlcXVlc3QgbWVzc2FnZSBmb3IgcmV0cmlldmluZyBhIGxpc3Qg
b2YgUmV2aXNpb25zLgoKCgoDBAEBEgN0CBwK3wEKBAQBAgASBHkCfgQa0AEgUmVxdWlyZWQu
IFRoZSBTZXJ2aWNlIGZyb20gd2hpY2ggdGhlIFJldmlzaW9ucyBzaG91bGQgYmUgbGlzdGVk
LgogVG8gbGlzdCBhbGwgUmV2aXNpb25zIGFjcm9zcyBTZXJ2aWNlcywgdXNlICItIiBpbnN0
ZWFkIG9mIFNlcnZpY2UgbmFtZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlcy97c2VydmljZX0KCgwKBQQBAgAFEgN5AggKDAoF
BAECAAESA3kJDwoMCgUEAQIAAxIDeRITCg0KBQQBAgAIEgR5FH4DCg8KCAQBAgAInAgAEgN6
BCoKDwoHBAECAAifCBIEewR9BQpDCgQEAQIBEgSBAQIWGjUgTWF4aW11bSBudW1iZXIgb2Yg
cmV2aXNpb25zIHRvIHJldHVybiBpbiB0aGlzIGNhbGwuCgoNCgUEAQIBBRIEgQECBwoNCgUE
AQIBARIEgQEIEQoNCgUEAQIBAxIEgQEUFQpuCgQEAQICEgSFAQIYGmAgQSBwYWdlIHRva2Vu
IHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIHRvIExpc3RSZXZpc2lvbnMuCiBBbGwg
b3RoZXIgcGFyYW1ldGVycyBtdXN0IG1hdGNoLgoKDQoFBAECAgUSBIUBAggKDQoFBAECAgES
BIUBCRMKDQoFBAECAgMSBIUBFhcKWgoEBAECAxIEiAECGBpMIElmIHRydWUsIHJldHVybnMg
ZGVsZXRlZCAoYnV0IHVuZXhwaXJlZCkgcmVzb3VyY2VzIGFsb25nIHdpdGggYWN0aXZlIG9u
ZXMuCgoNCgUEAQIDBRIEiAECBgoNCgUEAQIDARIEiAEHEwoNCgUEAQIDAxIEiAEWFwpACgIE
AhIGjAEAkwEBGjIgUmVzcG9uc2UgbWVzc2FnZSBjb250YWluaW5nIGEgbGlzdCBvZiBSZXZp
c2lvbnMuCgoLCgMEAgESBIwBCB0KMAoEBAICABIEjgECIhoiIFRoZSByZXN1bHRpbmcgbGlz
dCBvZiBSZXZpc2lvbnMuCgoNCgUEAgIABBIEjgECCgoNCgUEAgIABhIEjgELEwoNCgUEAgIA
ARIEjgEUHQoNCgUEAgIAAxIEjgEgIQp+CgQEAgIBEgSSAQIdGnAgQSB0b2tlbiBpbmRpY2F0
aW5nIHRoZXJlIGFyZSBtb3JlIGl0ZW1zIHRoYW4gcGFnZV9zaXplLiBVc2UgaXQgaW4gdGhl
IG5leHQKIExpc3RSZXZpc2lvbnMgcmVxdWVzdCB0byBjb250aW51ZS4KCg0KBQQCAgEFEgSS
AQIICg0KBQQCAgEBEgSSAQkYCg0KBQQCAgEDEgSSARscCscBCgIEAxIGmAEAqAEBGrgBIFJl
cXVlc3QgbWVzc2FnZSBmb3IgZGVsZXRpbmcgYSByZXRpcmVkIFJldmlzaW9uLgogUmV2aXNp
b24gbGlmZWN5Y2xlIGlzIHVzdWFsbHkgbWFuYWdlZCBieSBtYWtpbmcgY2hhbmdlcyB0byB0
aGUgcGFyZW50CiBTZXJ2aWNlLiBPbmx5IHJldGlyZWQgcmV2aXNpb25zIGNhbiBiZSBkZWxl
dGVkIHdpdGggdGhpcyBBUEkuCgoLCgMEAwESBJgBCB0KmgEKBAQDAgASBpwBAp8BBBqJASBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFJldmlzaW9uIHRvIGRlbGV0ZS4KIEZvcm1hdDoK
IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXJ2aWNlcy97c2Vy
dmljZX0vcmV2aXNpb25zL3tyZXZpc2lvbn0KCg0KBQQDAgAFEgScAQIICg0KBQQDAgABEgSc
AQkNCg0KBQQDAgADEgScARARCg8KBQQDAgAIEgacARKfAQMKEAoIBAMCAAicCAASBJ0BBCoK
DwoHBAMCAAifCBIEngEETQpoCgQEAwIBEgSjAQIZGlogSW5kaWNhdGVzIHRoYXQgdGhlIHJl
cXVlc3Qgc2hvdWxkIGJlIHZhbGlkYXRlZCB3aXRob3V0IGFjdHVhbGx5CiBkZWxldGluZyBh
bnkgcmVzb3VyY2VzLgoKDQoFBAMCAQUSBKMBAgYKDQoFBAMCAQESBKMBBxQKDQoFBAMCAQMS
BKMBFxgKkwEKBAQDAgISBKcBAhIahAEgQSBzeXN0ZW0tZ2VuZXJhdGVkIGZpbmdlcnByaW50
IGZvciB0aGlzIHZlcnNpb24gb2YgdGhlCiByZXNvdXJjZS4gVGhpcyBtYXkgYmUgdXNlZCB0
byBkZXRlY3QgbW9kaWZpY2F0aW9uIGNvbmZsaWN0IGR1cmluZyB1cGRhdGVzLgoKDQoFBAMC
AgUSBKcBAggKDQoFBAMCAgESBKcBCQ0KDQoFBAMCAgMSBKcBEBEKuAEKAgQEEgatAQDfAgEa
qQEgQSBSZXZpc2lvbiBpcyBhbiBpbW11dGFibGUgc25hcHNob3Qgb2YgY29kZSBhbmQgY29u
ZmlndXJhdGlvbi4gIEEgUmV2aXNpb24KIHJlZmVyZW5jZXMgYSBjb250YWluZXIgaW1hZ2Uu
IFJldmlzaW9ucyBhcmUgb25seSBjcmVhdGVkIGJ5IHVwZGF0ZXMgdG8gaXRzCiBwYXJlbnQg
U2VydmljZS4KCgsKAwQEARIErQEIEAoNCgMEBAcSBq4BArIBBAoPCgUEBAedCBIGrgECsgEE
Cj4KBAQEAgASBLUBAj4aMCBPdXRwdXQgb25seS4gVGhlIHVuaXF1ZSBuYW1lIG9mIHRoaXMg
UmV2aXNpb24uCgoNCgUEBAIABRIEtQECCAoNCgUEBAIAARIEtQEJDQoNCgUEBAIAAxIEtQEQ
EQoNCgUEBAIACBIEtQESPQoQCggEBAIACJwIABIEtQETPAqxAQoEBAQCARIEugECPRqiASBP
dXRwdXQgb25seS4gU2VydmVyIGFzc2lnbmVkIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUg
UmV2aXNpb24uIFRoZSB2YWx1ZQogaXMgYSBVVUlENCBzdHJpbmcgYW5kIGd1YXJhbnRlZWQg
dG8gcmVtYWluIHVuY2hhbmdlZCB1bnRpbCB0aGUgcmVzb3VyY2UgaXMKIGRlbGV0ZWQuCgoN
CgUEBAIBBRIEugECCAoNCgUEBAIBARIEugEJDAoNCgUEBAIBAxIEugEPEAoNCgUEBAIBCBIE
ugERPAoQCggEBAIBCJwIABIEugESOwpzCgQEBAICEgS+AQJDGmUgT3V0cHV0IG9ubHkuIEEg
bnVtYmVyIHRoYXQgbW9ub3RvbmljYWxseSBpbmNyZWFzZXMgZXZlcnkgdGltZSB0aGUgdXNl
cgogbW9kaWZpZXMgdGhlIGRlc2lyZWQgc3RhdGUuCgoNCgUEBAICBRIEvgECBwoNCgUEBAIC
ARIEvgEIEgoNCgUEBAICAxIEvgEVFgoNCgUEBAICCBIEvgEXQgoQCggEBAICCJwIABIEvgEY
QQq3AwoEBAQCAxIExgECTRqoAyBPdXRwdXQgb25seS4gVW5zdHJ1Y3R1cmVkIGtleSB2YWx1
ZSBtYXAgdGhhdCBjYW4gYmUgdXNlZCB0byBvcmdhbml6ZSBhbmQKIGNhdGVnb3JpemUgb2Jq
ZWN0cy4gVXNlci1wcm92aWRlZCBsYWJlbHMgYXJlIHNoYXJlZCB3aXRoIEdvb2dsZSdzIGJp
bGxpbmcKIHN5c3RlbSwgc28gdGhleSBjYW4gYmUgdXNlZCB0byBmaWx0ZXIsIG9yIGJyZWFr
IGRvd24gYmlsbGluZyBjaGFyZ2VzIGJ5CiB0ZWFtLCBjb21wb25lbnQsIGVudmlyb25tZW50
LCBzdGF0ZSwgZXRjLiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgdmlzaXQKIGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmct
bGFiZWxzIG9yCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcnVuL2RvY3MvY29uZmlndXJp
bmcvbGFiZWxzLgoKDQoFBAQCAwYSBMYBAhUKDQoFBAQCAwESBMYBFhwKDQoFBAQCAwMSBMYB
HyAKDQoFBAQCAwgSBMYBIUwKEAoIBAQCAwicCAASBMYBIksKxwEKBAQEAgQSBswBAs0BMhq2
ASBPdXRwdXQgb25seS4gVW5zdHJ1Y3R1cmVkIGtleSB2YWx1ZSBtYXAgdGhhdCBtYXkKIGJl
IHNldCBieSBleHRlcm5hbCB0b29scyB0byBzdG9yZSBhbmQgYXJiaXRyYXJ5IG1ldGFkYXRh
LgogVGhleSBhcmUgbm90IHF1ZXJ5YWJsZSBhbmQgc2hvdWxkIGJlIHByZXNlcnZlZAogd2hl
biBtb2RpZnlpbmcgb2JqZWN0cy4KCg0KBQQEAgQGEgTMAQIVCg0KBQQEAgQBEgTMARYhCg0K
BQQEAgQDEgTMASQlCg0KBQQEAgQIEgTNAQYxChAKCAQEAgQInAgAEgTNAQcwCjEKBAQEAgUS
BtABAtEBMhohIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRpb24gdGltZS4KCg0KBQQEAgUGEgTQ
AQIbCg0KBQQEAgUBEgTQARwnCg0KBQQEAgUDEgTQASorCg0KBQQEAgUIEgTRAQYxChAKCAQE
AgUInAgAEgTRAQcwCjYKBAQEAgYSBtQBAtUBMhomIE91dHB1dCBvbmx5LiBUaGUgbGFzdC1t
b2RpZmllZCB0aW1lLgoKDQoFBAQCBgYSBNQBAhsKDQoFBAQCBgESBNQBHCcKDQoFBAQCBgMS
BNQBKisKDQoFBAQCBggSBNUBBjEKEAoIBAQCBgicCAASBNUBBzAKggEKBAQEAgcSBtkBAtoB
MhpyIE91dHB1dCBvbmx5LiBGb3IgYSBkZWxldGVkIHJlc291cmNlLCB0aGUgZGVsZXRpb24g
dGltZS4gSXQgaXMgb25seQogcG9wdWxhdGVkIGFzIGEgcmVzcG9uc2UgdG8gYSBEZWxldGUg
cmVxdWVzdC4KCg0KBQQEAgcGEgTZAQIbCg0KBQQEAgcBEgTZARwnCg0KBQQEAgcDEgTZASor
Cg0KBQQEAgcIEgTaAQYxChAKCAQEAgcInAgAEgTaAQcwCqYBCgQEBAIIEgbfAQLgATIalQEg
T3V0cHV0IG9ubHkuIEZvciBhIGRlbGV0ZWQgcmVzb3VyY2UsIHRoZSB0aW1lIGFmdGVyIHdo
aWNoIGl0IHdpbGwgYmUKIHBlcm1hbWVudGx5IGRlbGV0ZWQuIEl0IGlzIG9ubHkgcG9wdWxh
dGVkIGFzIGEgcmVzcG9uc2UgdG8gYSBEZWxldGUKIHJlcXVlc3QuCgoNCgUEBAIIBhIE3wEC
GwoNCgUEBAIIARIE3wEcJwoNCgUEBAIIAxIE3wEqKwoNCgUEBAIICBIE4AEGMQoQCggEBAII
CJwIABIE4AEHMAqsAwoEBAQCCRIE6wECKxqdAyBUaGUgbGVhc3Qgc3RhYmxlIGxhdW5jaCBz
dGFnZSBuZWVkZWQgdG8gY3JlYXRlIHRoaXMgcmVzb3VyY2UsIGFzIGRlZmluZWQgYnkKIFtH
b29nbGUgQ2xvdWQgUGxhdGZvcm0gTGF1bmNoCiBTdGFnZXNdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS90ZXJtcy9sYXVuY2gtc3RhZ2VzKS4gQ2xvdWQgUnVuIHN1cHBvcnRzCiBgQUxQ
SEFgLCBgQkVUQWAsIGFuZCBgR0FgLgoKIE5vdGUgdGhhdCB0aGlzIHZhbHVlIG1pZ2h0IG5v
dCBiZSB3aGF0IHdhcyB1c2VkCiBhcyBpbnB1dC4gRm9yIGV4YW1wbGUsIGlmIEFMUEhBIHdh
cyBwcm92aWRlZCBhcyBpbnB1dCBpbiB0aGUgcGFyZW50CiByZXNvdXJjZSwgYnV0IG9ubHkg
QkVUQSBhbmQgR0EtbGV2ZWwgZmVhdHVyZXMgYXJlIHVzZWQsIHRoaXMgZmllbGQgd2lsbCBi
ZQogQkVUQS4KCg0KBQQEAgkGEgTrAQIYCg0KBQQEAgkBEgTrARklCg0KBQQEAgkDEgTrASgq
Cj4KBAQEAgoSBu4BAvEBBBouIE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUgcGFyZW50
IHNlcnZpY2UuCgoNCgUEBAIKBRIE7gECCAoNCgUEBAIKARIE7gEJEAoNCgUEBAIKAxIE7gET
FQoPCgUEBAIKCBIG7gEW8QEDChAKCAQEAgoInAgAEgTvAQQtCg8KBwQEAgoInwgSBPABBEwK
MwoEBAQCCxIE9AECHxolIFNjYWxpbmcgc2V0dGluZ3MgZm9yIHRoaXMgcmV2aXNpb24uCgoN
CgUEBAILBhIE9AECEQoNCgUEBAILARIE9AESGQoNCgUEBAILAxIE9AEcHgqXAQoEBAQCDBIE
+AECHBqIASBWUEMgQWNjZXNzIGNvbmZpZ3VyYXRpb24gZm9yIHRoaXMgUmV2aXNpb24uIEZv
ciBtb3JlIGluZm9ybWF0aW9uLCB2aXNpdAogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3J1
bi9kb2NzL2NvbmZpZ3VyaW5nL2Nvbm5lY3RpbmctdnBjLgoKDQoFBAQCDAYSBPgBAgsKDQoF
BAQCDAESBPgBDBYKDQoFBAQCDAMSBPgBGRsKWwoEBAQCDRIE+wECLhpNIFNldHMgdGhlIG1h
eGltdW0gbnVtYmVyIG9mIHJlcXVlc3RzIHRoYXQgZWFjaCBzZXJ2aW5nIGluc3RhbmNlIGNh
biByZWNlaXZlLgoKDQoFBAQCDQUSBPsBAgcKDQoFBAQCDQESBPsBCCgKDQoFBAQCDQMSBPsB
Ky0KSQoEBAQCDhIE/gECKBo7IE1heCBhbGxvd2VkIHRpbWUgZm9yIGFuIGluc3RhbmNlIHRv
IHJlc3BvbmQgdG8gYSByZXF1ZXN0LgoKDQoFBAQCDgYSBP4BAhoKDQoFBAQCDgESBP4BGyIK
DQoFBAQCDgMSBP4BJScK3wEKBAQEAg8SBIMCAh4a0AEgRW1haWwgYWRkcmVzcyBvZiB0aGUg
SUFNIHNlcnZpY2UgYWNjb3VudCBhc3NvY2lhdGVkIHdpdGggdGhlIHJldmlzaW9uIG9mCiB0
aGUgc2VydmljZS4gVGhlIHNlcnZpY2UgYWNjb3VudCByZXByZXNlbnRzIHRoZSBpZGVudGl0
eSBvZiB0aGUgcnVubmluZwogcmV2aXNpb24sIGFuZCBkZXRlcm1pbmVzIHdoYXQgcGVybWlz
c2lvbnMgdGhlIHJldmlzaW9uIGhhcy4KCg0KBQQEAg8FEgSDAgIICg0KBQQEAg8BEgSDAgkY
Cg0KBQQEAg8DEgSDAhsdClYKBAQEAhASBIcCAiUaSCBIb2xkcyB0aGUgbGlzdCB3aGljaCBk
ZWZpbmUgdGhlIHVuaXRzIG9mIGV4ZWN1dGlvbiBmb3IgdGhpcwogUmV2aXNpb24uCgoNCgUE
BAIQBBIEhwICCgoNCgUEBAIQBhIEhwILFAoNCgUEBAIQARIEhwIVHwoNCgUEBAIQAxIEhwIi
JAo7CgQEBAIREgaKAgKLAjIaKyBPdXRwdXQgb25seS4gQ29uZmlndXJhdGlvbiBmb3Igc2Fu
ZGJveGVzLgoKDQoFBAQCEQYSBIoCAhYKDQoFBAQCEQESBIoCFyAKDQoFBAQCEQMSBIoCIyUK
DQoFBAQCEQgSBIsCBjEKEAoIBAQCEQicCAASBIsCBzAKQgoEBAQCEhIEjgICHxo0IEEgbGlz
dCBvZiBWb2x1bWVzIHRvIG1ha2UgYXZhaWxhYmxlIHRvIGNvbnRhaW5lcnMuCgoNCgUEBAIS
BBIEjgICCgoNCgUEBAISBhIEjgILEQoNCgUEBAISARIEjgISGQoNCgUEBAISAxIEjgIcHgpL
CgQEBAITEgSRAgIyGj0gVGhlIGV4ZWN1dGlvbiBlbnZpcm9ubWVudCBiZWluZyB1c2VkIHRv
IGhvc3QgdGhpcyBSZXZpc2lvbi4KCg0KBQQEAhMGEgSRAgIWCg0KBQQEAhMBEgSRAhcsCg0K
BQQEAhMDEgSRAi8xCsYBCgQEBAIUEgaWAgKYAgUatQEgQSByZWZlcmVuY2UgdG8gYSBjdXN0
b21lciBtYW5hZ2VkIGVuY3J5cHRpb24ga2V5IChDTUVLKSB0byB1c2UgdG8gZW5jcnlwdAog
dGhpcyBjb250YWluZXIgaW1hZ2UuIEZvciBtb3JlIGluZm9ybWF0aW9uLCBnbyB0bwogaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL3J1bi9kb2NzL3NlY3VyaW5nL3VzaW5nLWNtZWsKCg0K
BQQEAhQFEgSWAgIICg0KBQQEAhQBEgSWAgkXCg0KBQQEAhQDEgSWAhocCg8KBQQEAhQIEgaW
Ah2YAgQKEQoHBAQCFAifCBIGlgIemAIDCjIKBAQEAhUSBJsCAiAaJCBFbmFibGVzIHNlcnZp
Y2UgbWVzaCBjb25uZWN0aXZpdHkuCgoNCgUEBAIVBhIEmwICDQoNCgUEBAIVARIEmwIOGgoN
CgUEBAIVAxIEmwIdHwpECgQEBAIWEgSeAgJGGjYgVGhlIGFjdGlvbiB0byB0YWtlIGlmIHRo
ZSBlbmNyeXB0aW9uIGtleSBpcyByZXZva2VkLgoKDQoFBAQCFgYSBJ4CAh8KDQoFBAQCFgES
BJ4CIEAKDQoFBAQCFgMSBJ4CQ0UKlAEKBAQEAhcSBKICAkEahQEgSWYgZW5jcnlwdGlvbl9r
ZXlfcmV2b2NhdGlvbl9hY3Rpb24gaXMgU0hVVERPV04sIHRoZSBkdXJhdGlvbiBiZWZvcmUK
IHNodXR0aW5nIGRvd24gYWxsIGluc3RhbmNlcy4gVGhlIG1pbmltdW0gaW5jcmVtZW50IGlz
IDEgaG91ci4KCg0KBQQEAhcGEgSiAgIaCg0KBQQEAhcBEgSiAhs7Cg0KBQQEAhcDEgSiAj5A
Cs4BCgQEBAIYEgSnAgJEGr8BIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgd2hldGhlciB0aGUg
cmVzb3VyY2UncyByZWNvbmNpbGlhdGlvbiBpcyBzdGlsbCBpbgogcHJvZ3Jlc3MuIFNlZSBj
b21tZW50cyBpbiBgU2VydmljZS5yZWNvbmNpbGluZ2AgZm9yIGFkZGl0aW9uYWwgaW5mb3Jt
YXRpb24KIG9uIHJlY29uY2lsaWF0aW9uIHByb2Nlc3MgaW4gQ2xvdWQgUnVuLgoKDQoFBAQC
GAUSBKcCAgYKDQoFBAQCGAESBKcCBxIKDQoFBAQCGAMSBKcCFRcKDQoFBAQCGAgSBKcCGEMK
EAoIBAQCGAicCAASBKcCGUIKqwEKBAQEAhkSBqwCAq0CMhqaASBPdXRwdXQgb25seS4gVGhl
IENvbmRpdGlvbiBvZiB0aGlzIFJldmlzaW9uLCBjb250YWluaW5nIGl0cyByZWFkaW5lc3MK
IHN0YXR1cywgYW5kIGRldGFpbGVkIGVycm9yIGluZm9ybWF0aW9uIGluIGNhc2UgaXQgZGlk
IG5vdCByZWFjaCBhIHNlcnZpbmcKIHN0YXRlLgoKDQoFBAQCGQQSBKwCAgoKDQoFBAQCGQYS
BKwCCxQKDQoFBAQCGQESBKwCFR8KDQoFBAQCGQMSBKwCIiQKDQoFBAQCGQgSBK0CBjEKEAoI
BAQCGQicCAASBK0CBzAKuwEKBAQEAhoSBLICAk0arAEgT3V0cHV0IG9ubHkuIFRoZSBnZW5l
cmF0aW9uIG9mIHRoaXMgUmV2aXNpb24gY3VycmVudGx5IHNlcnZpbmcgdHJhZmZpYy4gU2Vl
CiBjb21tZW50cyBpbiBgcmVjb25jaWxpbmdgIGZvciBhZGRpdGlvbmFsIGluZm9ybWF0aW9u
IG9uIHJlY29uY2lsaWF0aW9uCiBwcm9jZXNzIGluIENsb3VkIFJ1bi4KCg0KBQQEAhoFEgSy
AgIHCg0KBQQEAhoBEgSyAggbCg0KBQQEAhoDEgSyAh4gCg0KBQQEAhoIEgSyAiFMChAKCAQE
AhoInAgAEgSyAiJLClQKBAQEAhsSBLUCAkIaRiBPdXRwdXQgb25seS4gVGhlIEdvb2dsZSBD
b25zb2xlIFVSSSB0byBvYnRhaW4gbG9ncyBmb3IgdGhlIFJldmlzaW9uLgoKDQoFBAQCGwUS
BLUCAggKDQoFBAQCGwESBLUCCRAKDQoFBAQCGwMSBLUCExUKDQoFBAQCGwgSBLUCFkEKEAoI
BAQCGwicCAASBLUCF0AKNQoEBAQCHBIEuAICRhonIE91dHB1dCBvbmx5LiBSZXNlcnZlZCBm
b3IgZnV0dXJlIHVzZS4KCg0KBQQEAhwFEgS4AgIGCg0KBQQEAhwBEgS4AgcUCg0KBQQEAhwD
EgS4AhcZCg0KBQQEAhwIEgS4AhpFChAKCAQEAhwInAgAEgS4AhtECigKBAQEAh0SBLsCAh0a
GiBFbmFibGUgc2Vzc2lvbiBhZmZpbml0eS4KCg0KBQQEAh0FEgS7AgIGCg0KBQQEAh0BEgS7
AgcXCg0KBQQEAh0DEgS7AhocClcKBAQEAh4SBr4CAr8CMhpHIE91dHB1dCBvbmx5LiBUaGUg
Y3VycmVudCBlZmZlY3RpdmUgc2NhbGluZyBzZXR0aW5ncyBmb3IgdGhlIHJldmlzaW9uLgoK
DQoFBAQCHgYSBL4CAhcKDQoFBAQCHgESBL4CGCYKDQoFBAQCHgMSBL4CKSsKDQoFBAQCHggS
BL8CBjEKEAoIBAQCHgicCAASBL8CBzAKMwoEBAQCHxIEwgICIholIFRoZSBub2RlIHNlbGVj
dG9yIGZvciB0aGUgcmV2aXNpb24uCgoNCgUEBAIfBhIEwgICDgoNCgUEBAIfARIEwgIPHAoN
CgUEBAIfAxIEwgIfIQpGCgQEBAIgEgbFAgLGAi8aNiBPcHRpb25hbC4gVGhlIFJldmlzaW9u
J3Mgd29ya2xvYWQgaWRlbnRpdHkgc2V0dGluZ3MuCgoNCgUEBAIgBhIExQICGAoNCgUEBAIg
ARIExQIZMQoNCgUEBAIgAxIExQI0NgoNCgUEBAIgCBIExgIGLgoQCggEBAIgCJwIABIExgIH
LQpkCgQEBAIhEgbKAgLNAgQaVCBPcHRpb25hbC4gT3V0cHV0IG9ubHkuIFRydWUgaWYgR1BV
IHpvbmFsIHJlZHVuZGFuY3kgaXMgZGlzYWJsZWQgb24gdGhpcwogcmV2aXNpb24uCgoNCgUE
BAIhBBIEygICCgoNCgUEBAIhBRIEygILDwoNCgUEBAIhARIEygIQLQoNCgUEBAIhAxIEygIw
MgoPCgUEBAIhCBIGygIzzQIDChAKCAQEAiEInAgAEgTLAgQqChAKCAQEAiEInAgBEgTMAgQt
CkgKBAQEAiISBNACAkIaOiBPdXRwdXQgb25seS4gRW1haWwgYWRkcmVzcyBvZiB0aGUgYXV0
aGVudGljYXRlZCBjcmVhdG9yLgoKDQoFBAQCIgUSBNACAggKDQoFBAQCIgESBNACCRAKDQoF
BAQCIgMSBNACExUKDQoFBAQCIggSBNACFkEKEAoIBAQCIgicCAASBNACF0AKRQoEBAQCIxIE
0wICQRo3IE91dHB1dCBvbmx5LiBBcmJpdHJhcnkgaWRlbnRpZmllciBmb3IgdGhlIEFQSSBj
bGllbnQuCgoNCgUEBAIjBRIE0wICCAoNCgUEBAIjARIE0wIJDwoNCgUEBAIjAxIE0wISFAoN
CgUEBAIjCBIE0wIVQAoQCggEBAIjCJwIABIE0wIWPwpNCgQEBAIkEgTWAgJJGj8gT3V0cHV0
IG9ubHkuIEFyYml0cmFyeSB2ZXJzaW9uIGlkZW50aWZpZXIgZm9yIHRoZSBBUEkgY2xpZW50
LgoKDQoFBAQCJAUSBNYCAggKDQoFBAQCJAESBNYCCRcKDQoFBAQCJAMSBNYCGhwKDQoFBAQC
JAgSBNYCHUgKEAoIBAQCJAicCAASBNYCHkcKVgoEBAQCJRIG2QIC2gIyGkYgT3V0cHV0IG9u
bHkuIFRoZSBhbWJpZW50IG5ldHdvcmtpbmcgY29uZmlndXJhdGlvbiBmb3IgdGhpcyByZXZp
c2lvbi4KCg0KBQQEAiUGEgTZAgITCg0KBQQEAiUBEgTZAhQmCg0KBQQEAiUDEgTZAikrCg0K
BQQEAiUIEgTaAgYxChAKCAQEAiUInAgAEgTaAgcwCpsBCgQEBAImEgTeAgI/GowBIE91dHB1
dCBvbmx5LiBBIHN5c3RlbS1nZW5lcmF0ZWQgZmluZ2VycHJpbnQgZm9yIHRoaXMgdmVyc2lv
biBvZiB0aGUKIHJlc291cmNlLiBNYXkgYmUgdXNlZCB0byBkZXRlY3QgbW9kaWZpY2F0aW9u
IGNvbmZsaWN0IGR1cmluZyB1cGRhdGVzLgoKDQoFBAQCJgUSBN4CAggKDQoFBAQCJgESBN4C
CQ0KDQoFBAQCJgMSBN4CEBIKDQoFBAQCJggSBN4CEz4KEAoIBAQCJgicCAASBN4CFD1iBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::Revision::GetRevisionRequest ===
    # Fields for GetRevisionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Run::V2::Revision::ListRevisionsRequest ===
    # Fields for ListRevisionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: show_deleted Type: 8 ()

# === Message: Google::Cloud::Run::V2::Revision::ListRevisionsResponse ===
    # Fields for ListRevisionsResponse
    # Field: revisions Type: 11 (.google.cloud.run.v2.Revision)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Run::V2::Revision::DeleteRevisionRequest ===
    # Fields for DeleteRevisionRequest
    # Field: name Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Run::V2::Revision::Revision ===
    # Fields for Revision
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: generation Type: 3 ()
    # Field: labels Type: 11 (.google.cloud.run.v2.Revision.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.run.v2.Revision.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: launch_stage Type: 14 (.google.api.LaunchStage)
    # Field: service Type: 9 ()
    # Field: scaling Type: 11 (.google.cloud.run.v2.RevisionScaling)
    # Field: vpc_access Type: 11 (.google.cloud.run.v2.VpcAccess)
    # Field: max_instance_request_concurrency Type: 5 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: service_account Type: 9 ()
    # Field: containers Type: 11 (.google.cloud.run.v2.Container)
    # Field: sandboxes Type: 11 (.google.cloud.run.v2.SandboxConfiguration)
    # Field: volumes Type: 11 (.google.cloud.run.v2.Volume)
    # Field: execution_environment Type: 14 (.google.cloud.run.v2.ExecutionEnvironment)
    # Field: encryption_key Type: 9 ()
    # Field: service_mesh Type: 11 (.google.cloud.run.v2.ServiceMesh)
    # Field: encryption_key_revocation_action Type: 14 (.google.cloud.run.v2.EncryptionKeyRevocationAction)
    # Field: encryption_key_shutdown_duration Type: 11 (.google.protobuf.Duration)
    # Field: reconciling Type: 8 ()
    # Field: conditions Type: 11 (.google.cloud.run.v2.Condition)
    # Field: observed_generation Type: 3 ()
    # Field: log_uri Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: session_affinity Type: 8 ()
    # Field: scaling_status Type: 11 (.google.cloud.run.v2.RevisionScalingStatus)
    # Field: node_selector Type: 11 (.google.cloud.run.v2.NodeSelector)
    # Field: workload_identity_config Type: 11 (.google.cloud.run.v2.WorkloadIdentityConfig)
    # Field: gpu_zonal_redundancy_disabled Type: 8 ()
    # Field: creator Type: 9 ()
    # Field: client Type: 9 ()
    # Field: client_version Type: 9 ()
    # Field: ambient_networking Type: 11 (.google.cloud.run.v2.AmbientNetworking)
    # Field: etag Type: 9 ()

# === Service Client: Google::Cloud::Run::V2::Revision::RevisionsClient ===
package Google::Cloud::Run::V2::Revision::RevisionsClient;

=pod

=head2 Service Client: Google::Cloud::Run::V2::Revision::RevisionsClient

Client stub representing the remote C<Revisions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<run.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'run.googleapis.com:443' );

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

sub get_revision {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Revision::GetRevisionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Revisions',
        method         => 'GetRevision',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Revision::Revision',
    });
}

sub list_revisions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Revision::ListRevisionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Revisions',
        method         => 'ListRevisions',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Revision::ListRevisionsResponse',
    });
}

sub delete_revision {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Revision::DeleteRevisionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Revisions',
        method         => 'DeleteRevision',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::Revision - Compiled Protocol Buffers messages for google/cloud/run/v2/revision.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::Revision;

    my $msg = Google::Cloud::Run::V2::Revision::GetRevisionRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::Revision::GetRevisionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/revision.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::Revision::GetRevisionRequest

Request message for obtaining a Revision by its full name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full name of the Revision.
Format:
projects/{project}/locations/{location}/services/{service}/revisions/{revision}

=back

=head2 Google::Cloud::Run::V2::Revision::ListRevisionsRequest

Request message for retrieving a list of Revisions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Service from which the Revisions should be listed.
To list all Revisions across Services, use "-" instead of Service name.
Format:
projects/{project}/locations/{location}/services/{service}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of revisions to return in this call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token received from a previous call to ListRevisions.
All other parameters must match.

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

If true, returns deleted (but unexpired) resources along with active ones.

=back

=head2 Google::Cloud::Run::V2::Revision::ListRevisionsResponse

Response message containing a list of Revisions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->revisions() >> / C<< $msg->revisions($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Revision::Revision>)

The resulting list of Revisions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token indicating there are more items than page_size. Use it in the next
ListRevisions request to continue.

=back

=head2 Google::Cloud::Run::V2::Revision::DeleteRevisionRequest

Request message for deleting a retired Revision.
Revision lifecycle is usually managed by making changes to the parent
Service. Only retired revisions can be deleted with this API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Revision to delete.
Format:
projects/{project}/locations/{location}/services/{service}/revisions/{revision}

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Indicates that the request should be validated without actually
deleting any resources.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

A system-generated fingerprint for this version of the
resource. This may be used to detect modification conflict during updates.

=back

=head2 Google::Cloud::Run::V2::Revision::Revision

A Revision is an immutable snapshot of code and configuration.  A Revision
references a container image. Revisions are only created by updates to its
parent Service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique name of this Revision.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the Revision. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->generation() >> / C<< $msg->generation($value) >>

Type: C<Int64>

Output only. A number that monotonically increases every time the user
modifies the desired state.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Revision::Revision::LabelsEntry>)

Output only. Unstructured key value map that can be used to organize and
categorize objects. User-provided labels are shared with Google's billing
system, so they can be used to filter, or break down billing charges by
team, component, environment, state, etc. For more information, visit
https://cloud.google.com/resource-manager/docs/creating-managing-labels or
https://cloud.google.com/run/docs/configuring/labels.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Revision::Revision::AnnotationsEntry>)

Output only. Unstructured key value map that may
be set by external tools to store and arbitrary metadata.
They are not queryable and should be preserved
when modifying objects.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. For a deleted resource, the deletion time. It is only
populated as a response to a Delete request.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. For a deleted resource, the time after which it will be
permamently deleted. It is only populated as a response to a Delete
request.

=item * C<< $msg->launch_stage() >> / C<< $msg->launch_stage($value) >>

Type: C<Enum> (L<Google::Api::LaunchStage>)

The least stable launch stage needed to create this resource, as defined by
[Google Cloud Platform Launch
Stages](https://cloud.google.com/terms/launch-stages). Cloud Run supports
`ALPHA`, `BETA`, and `GA`.

Note that this value might not be what was used
as input. For example, if ALPHA was provided as input in the parent
resource, but only BETA and GA-level features are used, this field will be
BETA.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Output only. The name of the parent service.

=item * C<< $msg->scaling() >> / C<< $msg->scaling($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::RevisionScaling>)

Scaling settings for this revision.

=item * C<< $msg->vpc_access() >> / C<< $msg->vpc_access($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::VpcAccess>)

VPC Access configuration for this Revision. For more information, visit
https://cloud.google.com/run/docs/configuring/connecting-vpc.

=item * C<< $msg->max_instance_request_concurrency() >> / C<< $msg->max_instance_request_concurrency($value) >>

Type: C<Int32>

Sets the maximum number of requests that each serving instance can receive.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Max allowed time for an instance to respond to a request.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Email address of the IAM service account associated with the revision of
the service. The service account represents the identity of the running
revision, and determines what permissions the revision has.

=item * C<< $msg->containers() >> / C<< $msg->containers($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Container>)

Holds the list which define the units of execution for this
Revision.

=item * C<< $msg->sandboxes() >> / C<< $msg->sandboxes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Sandbox::SandboxConfiguration>)

Output only. Configuration for sandboxes.

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Volume>)

A list of Volumes to make available to containers.

=item * C<< $msg->execution_environment() >> / C<< $msg->execution_environment($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::ExecutionEnvironment>)

The execution environment being used to host this Revision.

=item * C<< $msg->encryption_key() >> / C<< $msg->encryption_key($value) >>

Type: C<String>

A reference to a customer managed encryption key (CMEK) to use to encrypt
this container image. For more information, go to
https://cloud.google.com/run/docs/securing/using-cmek

=item * C<< $msg->service_mesh() >> / C<< $msg->service_mesh($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::ServiceMesh>)

Enables service mesh connectivity.

=item * C<< $msg->encryption_key_revocation_action() >> / C<< $msg->encryption_key_revocation_action($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::EncryptionKeyRevocationAction>)

The action to take if the encryption key is revoked.

=item * C<< $msg->encryption_key_shutdown_duration() >> / C<< $msg->encryption_key_shutdown_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

If encryption_key_revocation_action is SHUTDOWN, the duration before
shutting down all instances. The minimum increment is 1 hour.

=item * C<< $msg->reconciling() >> / C<< $msg->reconciling($value) >>

Type: C<Bool>

Output only. Indicates whether the resource's reconciliation is still in
progress. See comments in `Service.reconciling` for additional information
on reconciliation process in Cloud Run.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Condition::Condition>)

Output only. The Condition of this Revision, containing its readiness
status, and detailed error information in case it did not reach a serving
state.

=item * C<< $msg->observed_generation() >> / C<< $msg->observed_generation($value) >>

Type: C<Int64>

Output only. The generation of this Revision currently serving traffic. See
comments in `reconciling` for additional information on reconciliation
process in Cloud Run.

=item * C<< $msg->log_uri() >> / C<< $msg->log_uri($value) >>

Type: C<String>

Output only. The Google Console URI to obtain logs for the Revision.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->session_affinity() >> / C<< $msg->session_affinity($value) >>

Type: C<Bool>

Enable session affinity.

=item * C<< $msg->scaling_status() >> / C<< $msg->scaling_status($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Status::RevisionScalingStatus>)

Output only. The current effective scaling settings for the revision.

=item * C<< $msg->node_selector() >> / C<< $msg->node_selector($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::NodeSelector>)

The node selector for the revision.

=item * C<< $msg->workload_identity_config() >> / C<< $msg->workload_identity_config($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig>)

Optional. The Revision's workload identity settings.

=item * C<< $msg->gpu_zonal_redundancy_disabled() >> / C<< $msg->gpu_zonal_redundancy_disabled($value) >>

Type: C<Bool>

Optional. Output only. True if GPU zonal redundancy is disabled on this
revision.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

Output only. Email address of the authenticated creator.

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Output only. Arbitrary identifier for the API client.

=item * C<< $msg->client_version() >> / C<< $msg->client_version($value) >>

Type: C<String>

Output only. Arbitrary version identifier for the API client.

=item * C<< $msg->ambient_networking() >> / C<< $msg->ambient_networking($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::AmbientNetworking>)

Output only. The ambient networking configuration for this revision.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. A system-generated fingerprint for this version of the
resource. May be used to detect modification conflict during updates.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::Revision::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
