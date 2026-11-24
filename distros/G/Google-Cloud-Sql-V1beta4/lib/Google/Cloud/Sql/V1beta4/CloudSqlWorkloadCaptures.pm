package Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures;

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
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Sql::V1beta4::CloudSqlResources };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX3dvcmtsb2FkX2NhcHR1cmVz
LnByb3RvEhhnb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjJnb29nbGUvY2xvdWQv
c3FsL3YxYmV0YTQvY2xvdWRfc3FsX3Jlc291cmNlcy5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byLfAQocV29ya2xvYWRDYXB0dXJlc1N0YXJ0UmVxdWVzdBIdCgdw
cm9qZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHwoIaW5zdGFuY2UYAiABKAlCA+BBAlIIaW5z
dGFuY2USfwoec3RhcnRfd29ya2xvYWRfY2FwdHVyZV9jb250ZXh0GGQgASgLMjUuZ29vZ2xl
LmNsb3VkLnNxbC52MWJldGE0LlN0YXJ0V29ya2xvYWRDYXB0dXJlQ29udGV4dEID4EEBUhtz
dGFydFdvcmtsb2FkQ2FwdHVyZUNvbnRleHQi2wEKG1dvcmtsb2FkQ2FwdHVyZXNTdG9wUmVx
dWVzdBIdCgdwcm9qZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHwoIaW5zdGFuY2UYAiABKAlC
A+BBAlIIaW5zdGFuY2USfAodc3RvcF93b3JrbG9hZF9jYXB0dXJlX2NvbnRleHQYZCABKAsy
NC5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuU3RvcFdvcmtsb2FkQ2FwdHVyZUNvbnRleHRC
A+BBAVIac3RvcFdvcmtsb2FkQ2FwdHVyZUNvbnRleHQiiAIKIldvcmtsb2FkQ2FwdHVyZXNT
dGFydFJlcGxheVJlcXVlc3QSHQoHcHJvamVjdBgBIAEoCUID4EECUgdwcm9qZWN0Eh8KCGlu
c3RhbmNlGAIgASgJQgPgQQJSCGluc3RhbmNlEnwKHXN0YXJ0X3dvcmtsb2FkX3JlcGxheV9j
b250ZXh0GGQgASgLMjQuZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlN0YXJ0V29ya2xvYWRS
ZXBsYXlDb250ZXh0QgPgQQJSGnN0YXJ0V29ya2xvYWRSZXBsYXlDb250ZXh0EiQKC3dvcmts
b2FkX2lkGAQgASgJQgPgQQJSCndvcmtsb2FkSWQi3gEKIVdvcmtsb2FkQ2FwdHVyZXNTdG9w
UmVwbGF5UmVxdWVzdBIdCgdwcm9qZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHwoIaW5zdGFu
Y2UYAiABKAlCA+BBAlIIaW5zdGFuY2USeQocc3RvcF93b3JrbG9hZF9yZXBsYXlfY29udGV4
dBhkIAEoCzIzLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5TdG9wV29ya2xvYWRSZXBsYXlD
b250ZXh0QgPgQQFSGXN0b3BXb3JrbG9hZFJlcGxheUNvbnRleHQiYAoeU3FsV29ya2xvYWRD
YXB0dXJlc0xpc3RSZXF1ZXN0Eh0KB3Byb2plY3QYASABKAlCA+BBAlIHcHJvamVjdBIfCghp
bnN0YW5jZRgCIAEoCUID4EECUghpbnN0YW5jZSKKAQocV29ya2xvYWRDYXB0dXJlc0xpc3RS
ZXNwb25zZRJWChF3b3JrbG9hZF9jYXB0dXJlcxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5zcWwu
djFiZXRhNC5Xb3JrbG9hZENhcHR1cmVSEHdvcmtsb2FkQ2FwdHVyZXMSEgoEa2luZBgCIAEo
CVIEa2luZCKDBwoPV29ya2xvYWRDYXB0dXJlEiQKC3dvcmtsb2FkX2lkGAEgASgJQgPgQQNS
Cndvcmtsb2FkSWQSUQoPc291cmNlX2luc3RhbmNlGAIgASgJQijgQQP6QSIKIGNsb3Vkc3Fs
Lmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUg5zb3VyY2VJbnN0YW5jZRJqChZ3b3JrbG9hZF9j
YXB0dXJlX3N0YXRlGAMgASgOMi8uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0Lldvcmtsb2Fk
Q2FwdHVyZS5TdGF0ZUID4EEDUhR3b3JrbG9hZENhcHR1cmVTdGF0ZRI+CgpzdGFydF90aW1l
GAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUglzdGFydFRpbWUSOgoI
ZW5kX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRp
bWUSVgoPcmVwbGF5X2luc3RhbmNlGAYgASgJQijgQQP6QSIKIGNsb3Vkc3FsLmdvb2dsZWFw
aXMuY29tL0luc3RhbmNlSABSDnJlcGxheUluc3RhbmNliAEBEi8KDnJldGVudGlvbl9kYXlz
GAcgASgFQgPgQQNIAVINcmV0ZW50aW9uRGF5c4gBARIlCgliYWNrdXBfaWQYCCABKAlCA+BB
A0gCUghiYWNrdXBJZIgBARJlCgxjYXB0dXJlX21vZGUYDSABKA4yPS5nb29nbGUuY2xvdWQu
c3FsLnYxYmV0YTQuV29ya2xvYWRDYXB0dXJlLldvcmtsb2FkQ2FwdHVyZU1vZGVCA+BBA1IL
Y2FwdHVyZU1vZGUiVgoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdSVU5OSU5H
EAESDQoJQ09NUExFVEVEEAISCgoGRkFJTEVEEAMSDgoKVEVSTUlOQVRFRBAEImsKE1dvcmts
b2FkQ2FwdHVyZU1vZGUSJQohV09SS0xPQURfQ0FQVFVSRV9NT0RFX1VOU1BFQ0lGSUVEEAAS
EAoMQ0FQVFVSRV9PTkxZEAESGwoXQ0FQVFVSRV9BTkRfTElWRV9SRVBMQVkQAkISChBfcmVw
bGF5X2luc3RhbmNlQhEKD19yZXRlbnRpb25fZGF5c0IMCgpfYmFja3VwX2lkMowJChpTcWxX
b3JrbG9hZENhcHR1cmVzU2VydmljZRK8AQoFU3RhcnQSNi5nb29nbGUuY2xvdWQuc3FsLnYx
YmV0YTQuV29ya2xvYWRDYXB0dXJlc1N0YXJ0UmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zcWwu
djFiZXRhNC5PcGVyYXRpb24iVoLT5JMCUCJLL3NxbC92MWJldGE0L3Byb2plY3RzL3twcm9q
ZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS93b3JrbG9hZENhcHR1cmVzOnN0YXJ0OgEqErkB
CgRTdG9wEjUuZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0Lldvcmtsb2FkQ2FwdHVyZXNTdG9w
UmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5PcGVyYXRpb24iVYLT5JMCTyJK
L3NxbC92MWJldGE0L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS93
b3JrbG9hZENhcHR1cmVzOnN0b3A6ASoS3AEKC1N0YXJ0UmVwbGF5EjwuZ29vZ2xlLmNsb3Vk
LnNxbC52MWJldGE0Lldvcmtsb2FkQ2FwdHVyZXNTdGFydFJlcGxheVJlcXVlc3QaIy5nb29n
bGUuY2xvdWQuc3FsLnYxYmV0YTQuT3BlcmF0aW9uImqC0+STAmQiXy9zcWwvdjFiZXRhNC9w
cm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vd29ya2xvYWRDYXB0dXJl
cy97d29ya2xvYWRfaWR9OnN0YXJ0UmVwbGF5OgEqEssBCgpTdG9wUmVwbGF5EjsuZ29vZ2xl
LmNsb3VkLnNxbC52MWJldGE0Lldvcmtsb2FkQ2FwdHVyZXNTdG9wUmVwbGF5UmVxdWVzdBoj
Lmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5PcGVyYXRpb24iW4LT5JMCVSJQL3NxbC92MWJl
dGE0L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS93b3JrbG9hZENh
cHR1cmVzOnN0b3BSZXBsYXk6ASoSxwEKBExpc3QSOC5nb29nbGUuY2xvdWQuc3FsLnYxYmV0
YTQuU3FsV29ya2xvYWRDYXB0dXJlc0xpc3RSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLnNxbC52
MWJldGE0Lldvcmtsb2FkQ2FwdHVyZXNMaXN0UmVzcG9uc2UiTYLT5JMCRxJFL3NxbC92MWJl
dGE0L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS93b3JrbG9hZENh
cHR1cmVzGnzKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbdJBX2h0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9zcWxzZXJ2aWNlLmFkbWluQm8KHGNvbS5nb29nbGUuY2xvdWQuc3FsLnYxYmV0
YTRCHUNsb3VkU3FsV29ya2xvYWRDYXB0dXJlc1Byb3RvUAFaLmNsb3VkLmdvb2dsZS5jb20v
Z28vc3FsL2FwaXYxYmV0YTQvc3FscGI7c3FscGJK3z4KBxIFDgDuAQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA8CgkKAgMFEgMXACkKCAoBCBIDGQBF
CgkKAggLEgMZAEUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA+CgkKAggIEgMbAD4K
CAoBCBIDHAA1CgkKAggBEgMcADUKMgoCBgASBB8AUwEaJiBDbG91ZCBTUUwgV29ya2xvYWQg
Q2FwdHVyZXMgc2VydmljZS4KCgoKAwYAARIDHwgiCgoKAwYAAxIDIAI/CgwKBQYAA5kIEgMg
Aj8KCwoDBgADEgQhAiM5Cg0KBQYAA5oIEgQhAiM5Cu4CCgQGAAIAEgQqAi8DGt8CIFN0YXJ0
cyBjYXB0dXJpbmcgdGhlIFNRTCBxdWVyaWVzLCB0cmFuc2FjdGlvbnMsIGFuZCBvdGhlciBv
cGVyYXRpb25zCiBleGVjdXRlZCBvbiB0aGUgcHJpbWFyeSBpbnN0YW5jZS4gVGhpcyB0cmFm
ZmljIGlzIHNlY3VyZWx5IHN0b3JlZCBhbmQgZm9ybXMKIGEgImNhcHR1cmVkIHdvcmtsb2Fk
Ii4gVGhpcyB3b3JrbG9hZCBjYW4gYmUgcmVwbGF5ZWQgbGF0ZXIgb24gYSBkaWZmZXJlbnQK
IGluc3RhbmNlIHRvIHNhZmVseSB0ZXN0IHBlcmZvcm1hbmNlIGltcGFjdHMsIGRhdGFiYXNl
IHVwZ3JhZGVzLAogY29uZmlndXJhdGlvbiBjaGFuZ2VzIGV0Yy4gYmVmb3JlIGFwcGx5aW5n
IHRoZW0gdG8gcHJvZHVjdGlvbi4KCgwKBQYAAgABEgMqBgsKDAoFBgACAAISAyoMKAoMCgUG
AAIAAxIDKjM8Cg0KBQYAAgAEEgQrBC4GChEKCQYAAgAEsMq8IhIEKwQuBgprCgQGAAIBEgQz
AjgDGl0gU3RvcHMgY2FwdHVyaW5nIHRoZSBxdWVyeSB0cmFmZmljIGFuZCByZWxhdGVkIG9w
ZXJhdGlvbnMgZXhlY3V0ZWQgb24gdGhlCiBwcmltYXJ5IGluc3RhbmNlLgoKDAoFBgACAQES
AzMGCgoMCgUGAAIBAhIDMwsmCgwKBQYAAgEDEgMzMToKDQoFBgACAQQSBDQENwYKEQoJBgAC
AQSwyrwiEgQ0BDcGCtsBCgQGAAICEgQ9AkIDGswBIFN0YXJ0cyBleGVjdXRpbmcgYSBjYXB0
dXJlZCB3b3JrbG9hZCBvbiBhIHNlcGFyYXRlIENsb3VkIFNRTCBpbnN0YW5jZQogcHJvdmlz
aW9uZWQgZm9yIHdvcmtsb2FkIHJlcGxheS4gVGhpcyB0YXJnZXQgaW5zdGFuY2Ugc2ltdWxh
dGVzIHRoZQogcHJvZHVjdGlvbiBlbnZpcm9ubWVudCB3aXRob3V0IGFmZmVjdGluZyB0aGUg
cHJpbWFyeSBpbnN0YW5jZS4KCgwKBQYAAgIBEgM9BhEKDAoFBgACAgISAz0SNAoMCgUGAAIC
AxIDPT9ICg0KBQYAAgIEEgQ+BEEGChEKCQYAAgIEsMq8IhIEPgRBBgpYCgQGAAIDEgRFAkoD
GkogU3RvcHMgYW4gYWN0aXZlIHdvcmtsb2FkIHJlcGxheSBvbiB0aGUgdGFyZ2V0IENsb3Vk
IFNRTCByZXBsYXkgaW5zdGFuY2UuCgoMCgUGAAIDARIDRQYQCgwKBQYAAgMCEgNFETIKDAoF
BgACAwMSA0U9RgoNCgUGAAIDBBIERgRJBgoRCgkGAAIDBLDKvCISBEYESQYKSgoEBgACBBIE
TQJSAxo8IExpc3RzIGFsbCBjYXB0dXJlZCB3b3JrbG9hZHMgYXNzb2NpYXRlZCB3aXRoIHRo
ZSBpbnN0YW5jZS4KCgwKBQYAAgQBEgNNBgoKDAoFBgACBAISA00LKQoMCgUGAAIEAxIDTg8r
Cg0KBQYAAgQEEgRPBFEGChEKCQYAAgQEsMq8IhIETwRRBgpgCgIEABIEVwBhARpUIFJlcXVl
c3QgdG8gc3RhcnQgcmVjb3JkaW5nIHRyYWZmaWMgZnJvbSB0aGUgcHJpbWFyeSBpbnN0YW5j
ZSAoY2FwdHVyZWQKIHdvcmtsb2FkKS4KCgoKAwQAARIDVwgkCk4KBAQAAgASA1kCPhpBIFJl
cXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGlu
c3RhbmNlLgoKDAoFBAACAAUSA1kCCAoMCgUEAAIAARIDWQkQCgwKBQQAAgADEgNZExQKDAoF
BAACAAgSA1kVPQoPCggEAAIACJwIABIDWRY8ClUKBAQAAgESA1wCPxpIIFJlcXVpcmVkLiBD
bG91ZCBTUUwgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVj
dCBJRC4KCgwKBQQAAgEFEgNcAggKDAoFBAACAQESA1wJEQoMCgUEAAIBAxIDXBQVCgwKBQQA
AgEIEgNcFj4KDwoIBAACAQicCAASA1wXPQpWCgQEAAICEgRfAmAvGkggT3B0aW9uYWwuIENv
bnRhaW5zIGRldGFpbHMgYWJvdXQgdGhlIHN0YXJ0IHdvcmtsb2FkIGNhcHR1cmUgb3BlcmF0
aW9uLgoKDAoFBAACAgYSA18CHQoMCgUEAAICARIDXx48CgwKBQQAAgIDEgNfP0IKDAoFBAAC
AggSA2AGLgoPCggEAAICCJwIABIDYActCkoKAgQBEgRkAG4BGj4gUmVxdWVzdCB0byBzdG9w
IHJlY29yZGluZyB0cmFmZmljIGZyb20gdGhlIHByaW1hcnkgaW5zdGFuY2UuCgoKCgMEAQES
A2QIIwpOCgQEAQIAEgNmAj4aQSBSZXF1aXJlZC4gUHJvamVjdCBJRCBvZiB0aGUgcHJvamVj
dCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQBAgAFEgNmAggKDAoFBAECAAES
A2YJEAoMCgUEAQIAAxIDZhMUCgwKBQQBAgAIEgNmFT0KDwoIBAECAAicCAASA2YWPApVCgQE
AQIBEgNpAj8aSCBSZXF1aXJlZC4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMg
bm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAQIBBRIDaQIICgwKBQQBAgEBEgNp
CREKDAoFBAECAQMSA2kUFQoMCgUEAQIBCBIDaRY+Cg8KCAQBAgEInAgAEgNpFz0KVQoEBAEC
AhIEbAJtLxpHIE9wdGlvbmFsLiBDb250YWlucyBkZXRhaWxzIGFib3V0IHRoZSBzdG9wIHdv
cmtsb2FkIGNhcHR1cmUgb3BlcmF0aW9uLgoKDAoFBAECAgYSA2wCHAoMCgUEAQICARIDbB06
CgwKBQQBAgIDEgNsPUAKDAoFBAECAggSA20GLgoPCggEAQICCJwIABIDbQctCpkBCgIEAhIE
cgB/ARqMASBSZXF1ZXN0IHRvIHN0YXJ0IGV4ZWN1dGluZyBhIGNhcHR1cmVkIHdvcmtsb2Fk
IG9uIGEgcmVwbGF5IGluc3RhbmNlICh0aGUKIENsb3VkIFNRTCBpbnN0YW5jZSB3aGVyZSB0
aGUgcmVjb3JkZWQgU1FMIHF1ZXJpZXMgYXJlIGV4ZWN1dGVkKS4KCgoKAwQCARIDcggqCk4K
BAQCAgASA3QCPhpBIFJlcXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQg
Y29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAICAAUSA3QCCAoMCgUEAgIAARIDdAkQCgwK
BQQCAgADEgN0ExQKDAoFBAICAAgSA3QVPQoPCggEAgIACJwIABIDdBY8ClUKBAQCAgESA3cC
PxpIIFJlcXVpcmVkLiBDbG91ZCBTUUwgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5j
bHVkZSB0aGUgcHJvamVjdCBJRC4KCgwKBQQCAgEFEgN3AggKDAoFBAICAQESA3cJEQoMCgUE
AgIBAxIDdxQVCgwKBQQCAgEIEgN3Fj4KDwoIBAICAQicCAASA3cXPQpVCgQEAgICEgR6Ansv
GkcgUmVxdWlyZWQuIENvbnRhaW5zIGRldGFpbHMgYWJvdXQgdGhlIHN0YXJ0IHdvcmtsb2Fk
IHJlcGxheSBvcGVyYXRpb24uCgoMCgUEAgICBhIDegIcCgwKBQQCAgIBEgN6HToKDAoFBAIC
AgMSA3o9QAoMCgUEAgICCBIDewYuCg8KCAQCAgIInAgAEgN7By0KOgoEBAICAxIDfgJCGi0g
UmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgd29ya2xvYWQgdG8gcmVwbGF5LgoKDAoFBAICAwUS
A34CCAoMCgUEAgIDARIDfgkUCgwKBQQCAgMDEgN+FxgKDAoFBAICAwgSA34ZQQoPCggEAgID
CJwIABIDfhpACmEKAgQDEgaDAQCPAQEaUyBSZXF1ZXN0IHRvIHN0b3AgYW4gYWN0aXZlIHdv
cmtsb2FkIHJlcGxheSBvbiBhIHRhcmdldCBDbG91ZCBTUUwgcmVwbGF5CiBpbnN0YW5jZS4K
CgsKAwQDARIEgwEIKQpeCgQEAwIAEgSGAQI+GlAgUmVxdWlyZWQuIFByb2plY3QgSUQgb2Yg
dGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgdGFyZ2V0IHJlcGxheQogaW5zdGFuY2Uu
CgoNCgUEAwIABRIEhgECCAoNCgUEAwIAARIEhgEJEAoNCgUEAwIAAxIEhgETFAoNCgUEAwIA
CBIEhgEVPQoQCggEAwIACJwIABIEhgEWPAp1CgQEAwIBEgSKAQI/GmcgUmVxdWlyZWQuIENs
b3VkIFNRTCBpbnN0YW5jZSBJRCBvZiB0aGUgdGFyZ2V0IHJlcGxheSBpbnN0YW5jZS4gVGhp
cyBkb2VzCiBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCg0KBQQDAgEFEgSKAQIICg0K
BQQDAgEBEgSKAQkRCg0KBQQDAgEDEgSKARQVCg0KBQQDAgEIEgSKARY+ChAKCAQDAgEInAgA
EgSKARc9ClYKBAQDAgISBo0BAo4BLxpGIE9wdGlvbmFsLiBDb250YWlucyBkZXRhaWxzIGFi
b3V0IHRoZSBzdG9wIHdvcmtsb2FkIHJlcGxheSBvcGVyYXRpb24uCgoNCgUEAwICBhIEjQEC
GwoNCgUEAwICARIEjQEcOAoNCgUEAwICAxIEjQE7PgoNCgUEAwICCBIEjgEGLgoQCggEAwIC
CJwIABIEjgEHLQo5CgIEBBIGkgEAmAEBGisgSW5zdGFuY2UgbGlzdCBjYXB0dXJlZCB3b3Jr
bG9hZHMgcmVxdWVzdC4KCgsKAwQEARIEkgEIJgpPCgQEBAIAEgSUAQI+GkEgUmVxdWlyZWQu
IFByb2plY3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2Uu
CgoNCgUEBAIABRIElAECCAoNCgUEBAIAARIElAEJEAoNCgUEBAIAAxIElAETFAoNCgUEBAIA
CBIElAEVPQoQCggEBAIACJwIABIElAEWPApWCgQEBAIBEgSXAQI/GkggUmVxdWlyZWQuIENs
b3VkIFNRTCBpbnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0
IElELgoKDQoFBAQCAQUSBJcBAggKDQoFBAQCAQESBJcBCREKDQoFBAQCAQMSBJcBFBUKDQoF
BAQCAQgSBJcBFj4KEAoIBAQCAQicCAASBJcBFz0KOgoCBAUSBpsBAKEBARosIEluc3RhbmNl
IGxpc3QgY2FwdHVyZWQgd29ya2xvYWRzIHJlc3BvbnNlLgoKCwoDBAUBEgSbAQgkCjwKBAQF
AgASBJ0BAjEaLiBMaXN0IG9mIGNhcHR1cmVkIHdvcmtsb2FkcyBmb3IgdGhlIGluc3RhbmNl
LgoKDQoFBAUCAAQSBJ0BAgoKDQoFBAUCAAYSBJ0BCxoKDQoFBAUCAAESBJ0BGywKDQoFBAUC
AAMSBJ0BLzAKOgoEBAUCARIEoAECEhosIFRoaXMgaXMgYWx3YXlzIGBzcWwjd29ya2xvYWRD
YXB0dXJlc0xpc3RgLgoKDQoFBAUCAQUSBKABAggKDQoFBAUCAQESBKABCQ0KDQoFBAUCAQMS
BKABEBEKMgoCBAYSBqQBAO4BARokIENhcHR1cmVkIHdvcmtsb2FkIGZvciBhbiBpbnN0YW5j
ZS4KCgsKAwQGARIEpAEIFwowCgQEBgQAEgamAQK4AQMaICBTdGF0ZSBvZiB0aGUgd29ya2xv
YWQgY2FwdHVyZS4KCg0KBQQGBAABEgSmAQcMCjYKBgQGBAACABIEqAEEGhomIERlZmF1bHQg
dmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDwoHBAYEAAIAARIEqAEEFQoPCgcEBgQA
AgACEgSoARgZCjgKBgQGBAACARIEqwEEEBooIFdvcmtsb2FkIGNhcHR1cmUgaXMgY3VycmVu
dGx5IHJ1bm5pbmcuCgoPCgcEBgQAAgEBEgSrAQQLCg8KBwQGBAACAQISBKsBDg8KeQoGBAYE
AAICEgSvAQQSGmkgV29ya2xvYWQgY2FwdHVyZSBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LiBU
aGlzIHN0YXRlIGlzIHNldCB3aGVuIHRoZSB1c2VyCiBleHBsaWNpdGx5IHN0b3BzIHRoZSBj
YXB0dXJlLgoKDwoHBAYEAAICARIErwEEDQoPCgcEBgQAAgICEgSvARARCioKBgQGBAACAxIE
sgEEDxoaIFdvcmtsb2FkIGNhcHR1cmUgZmFpbGVkLgoKDwoHBAYEAAIDARIEsgEECgoPCgcE
BgQAAgMCEgSyAQ0OCswBCgYEBgQAAgQSBLcBBBMauwEgV29ya2xvYWQgY2FwdHVyZSB3YXMg
dGVybWluYXRlZCBhdXRvbWF0aWNhbGx5LiBUaGlzIHN0YXRlIGlzIHNldCB3aGVuCiBDbG91
ZCBTUUwgYXV0b21hdGljYWxseSBzdG9wcyB0aGUgY2FwdHVyZSBkdWUgdG8gYSBjb25mbGlj
dGluZyBvcGVyYXRpb24KIG9yIHdoZW4gdGhlIG1heGltdW0gZHVyYXRpb24gaXMgcmVhY2hl
ZC4KCg8KBwQGBAACBAESBLcBBA4KDwoHBAYEAAIEAhIEtwEREgo9CgQEBgQBEga7AQLFAQMa
LSBTcGVjaWZpZXMgdGhlIG1vZGUgb2YgdGhlIHdvcmtsb2FkIGNhcHR1cmUuCgoNCgUEBgQB
ARIEuwEHGgo2CgYEBgQBAgASBL0BBCoaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlz
IHVudXNlZC4KCg8KBwQGBAECAAESBL0BBCUKDwoHBAYEAQIAAhIEvQEoKQpGCgYEBgQBAgES
BMABBBUaNiBSZWNvcmRzIGFuZCBzdG9yZXMgdGhlIHdvcmtsb2FkIHdpdGhvdXQgbGl2ZSBy
ZXBsYXkuCgoPCgcEBgQBAgEBEgTAAQQQCg8KBwQGBAECAQISBMABExQKYAoGBAYEAQICEgTE
AQQgGlAgUmVjb3JkcyB0aGUgd29ya2xvYWQgYW5kIHNpbXVsdGFuZW91c2x5IHJlcGxheXMg
aXQgb24gYSBsaXZlIHJlcGxheQogaW5zdGFuY2UuCgoPCgcEBgQBAgIBEgTEAQQbCg8KBwQG
BAECAgISBMQBHh8KPQoEBAYCABIEyAECRRovIE91dHB1dCBvbmx5LiBUaGUgSUQgb2YgdGhl
IGNhcHR1cmVkIHdvcmtsb2FkLgoKDQoFBAYCAAUSBMgBAggKDQoFBAYCAAESBMgBCRQKDQoF
BAYCAAMSBMgBFxgKDQoFBAYCAAgSBMgBGUQKEAoIBAYCAAicCAASBMgBGkMKPwoEBAYCARIG
ywEC0AEEGi8gT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBzb3VyY2UgaW5zdGFuY2Uu
CgoNCgUEBgIBBRIEywECCAoNCgUEBgIBARIEywEJGAoNCgUEBgIBAxIEywEbHAoPCgUEBgIB
CBIGywEd0AEDChAKCAQGAgEInAgAEgTMAQQtChEKBwQGAgEInwgSBs0BBM8BBQo/CgQEBgIC
EgTTAQJPGjEgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgd29ya2xvYWQgY2FwdHVy
ZS4KCg0KBQQGAgIGEgTTAQIHCg0KBQQGAgIBEgTTAQgeCg0KBQQGAgIDEgTTASEiCg0KBQQG
AgIIEgTTASNOChAKCAQGAgIInAgAEgTTASRNCkYKBAQGAgMSBtYBAtcBMho2IE91dHB1dCBv
bmx5LiBUaGUgc3RhcnQgdGltZSBvZiB0aGUgd29ya2xvYWQgY2FwdHVyZS4KCg0KBQQGAgMG
EgTWAQIbCg0KBQQGAgMBEgTWARwmCg0KBQQGAgMDEgTWASkqCg0KBQQGAgMIEgTXAQYxChAK
CAQGAgMInAgAEgTXAQcwCkQKBAQGAgQSBtoBAtsBMho0IE91dHB1dCBvbmx5LiBUaGUgZW5k
IHRpbWUgb2YgdGhlIHdvcmtsb2FkIGNhcHR1cmUuCgoNCgUEBgIEBhIE2gECGwoNCgUEBgIE
ARIE2gEcJAoNCgUEBgIEAxIE2gEnKAoNCgUEBgIECBIE2wEGMQoQCggEBgIECJwIABIE2wEH
MApbCgQEBgIFEgbeAQLjAQQaSyBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIHJlcGxh
eSBpbnN0YW5jZSwgaWYgbGl2ZSByZXBsYXkgd2FzIGVuYWJsZWQuCgoNCgUEBgIFBBIE3gEC
CgoNCgUEBgIFBRIE3gELEQoNCgUEBgIFARIE3gESIQoNCgUEBgIFAxIE3gEkJQoPCgUEBgIF
CBIG3gEm4wEDChAKCAQGAgUInAgAEgTfAQQtChEKBwQGAgUInwgSBuABBOIBBQpUCgQEBgIG
EgTmAQJQGkYgT3V0cHV0IG9ubHkuIFRoZSByZXRlbnRpb24gcGVyaW9kIGluIGRheXMgZm9y
IHRoZSBjYXB0dXJlZCB3b3JrbG9hZC4KCg0KBQQGAgYEEgTmAQIKCg0KBQQGAgYFEgTmAQsQ
Cg0KBQQGAgYBEgTmAREfCg0KBQQGAgYDEgTmASIjCg0KBQQGAgYIEgTmASRPChAKCAQGAgYI
nAgAEgTmASVOClUKBAQGAgcSBOkBAkwaRyBPdXRwdXQgb25seS4gVGhlIGJhc2UgYmFja3Vw
IElEIGFzc29jaWF0ZWQgd2l0aCB0aGUgd29ya2xvYWQgY2FwdHVyZS4KCg0KBQQGAgcEEgTp
AQIKCg0KBQQGAgcFEgTpAQsRCg0KBQQGAgcBEgTpARIbCg0KBQQGAgcDEgTpAR4fCg0KBQQG
AgcIEgTpASBLChAKCAQGAgcInAgAEgTpASFKCkgKBAQGAggSBuwBAu0BMho4IE91dHB1dCBv
bmx5LiBUaGUgY2FwdHVyZSBtb2RlIG9mIHRoZSB3b3JrbG9hZCBjYXB0dXJlLgoKDQoFBAYC
CAYSBOwBAhUKDQoFBAYCCAESBOwBFiIKDQoFBAYCCAMSBOwBJScKDQoFBAYCCAgSBO0BBjEK
EAoIBAYCCAicCAASBO0BBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest ===
    # Fields for WorkloadCapturesStartRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: start_workload_capture_context Type: 11 (.google.cloud.sql.v1beta4.StartWorkloadCaptureContext)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest ===
    # Fields for WorkloadCapturesStopRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: stop_workload_capture_context Type: 11 (.google.cloud.sql.v1beta4.StopWorkloadCaptureContext)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest ===
    # Fields for WorkloadCapturesStartReplayRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: start_workload_replay_context Type: 11 (.google.cloud.sql.v1beta4.StartWorkloadReplayContext)
    # Field: workload_id Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest ===
    # Fields for WorkloadCapturesStopReplayRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: stop_workload_replay_context Type: 11 (.google.cloud.sql.v1beta4.StopWorkloadReplayContext)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest ===
    # Fields for SqlWorkloadCapturesListRequest
    # Field: project Type: 9 ()
    # Field: instance Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse ===
    # Fields for WorkloadCapturesListResponse
    # Field: workload_captures Type: 11 (.google.cloud.sql.v1beta4.WorkloadCapture)
    # Field: kind Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapture ===
    # Fields for WorkloadCapture
    # Field: workload_id Type: 9 ()
    # Field: source_instance Type: 9 ()
    # Field: workload_capture_state Type: 14 (.google.cloud.sql.v1beta4.WorkloadCapture.State)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: replay_instance Type: 9 ()
    # Field: retention_days Type: 5 ()
    # Field: backup_id Type: 9 ()
    # Field: capture_mode Type: 14 (.google.cloud.sql.v1beta4.WorkloadCapture.WorkloadCaptureMode)

# Enum: WorkloadCapture::State
our $WorkloadCapture_STATE_UNSPECIFIED = 0;
our $WorkloadCapture_RUNNING = 1;
our $WorkloadCapture_COMPLETED = 2;
our $WorkloadCapture_FAILED = 3;
our $WorkloadCapture_TERMINATED = 4;

# Enum: WorkloadCapture::WorkloadCaptureMode
our $WorkloadCapture_WORKLOAD_CAPTURE_MODE_UNSPECIFIED = 0;
our $WorkloadCapture_CAPTURE_ONLY = 1;
our $WorkloadCapture_CAPTURE_AND_LIVE_REPLAY = 2;

# === Service Client: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesServiceClient ===
package Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesServiceClient

Client stub representing the remote C<SqlWorkloadCapturesService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

sub start {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'Start',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

sub stop {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'Stop',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

sub start_replay {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'StartReplay',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

sub stop_replay {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'StopReplay',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures - Compiled Protocol Buffers messages for google/cloud/sql/v1beta4/cloud_sql_workload_captures.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures;

    my $msg = Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest->new({
        project => $project,
        instance => $instance,
        start_workload_capture_context => $start_workload_capture_context,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1beta4/cloud_sql_workload_captures.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest

Request to start recording traffic from the primary instance (captured
workload).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->start_workload_capture_context() >> / C<< $msg->start_workload_capture_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadCaptureContext>)

Optional. Contains details about the start workload capture operation.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest

Request to stop recording traffic from the primary instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->stop_workload_capture_context() >> / C<< $msg->stop_workload_capture_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadCaptureContext>)

Optional. Contains details about the stop workload capture operation.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest

Request to start executing a captured workload on a replay instance (the
Cloud SQL instance where the recorded SQL queries are executed).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->start_workload_replay_context() >> / C<< $msg->start_workload_replay_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadReplayContext>)

Required. Contains details about the start workload replay operation.

=item * C<< $msg->workload_id() >> / C<< $msg->workload_id($value) >>

Type: C<String>

Required. The ID of the workload to replay.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest

Request to stop an active workload replay on a target Cloud SQL replay
instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the target replay
instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID of the target replay instance. This does
not include the project ID.

=item * C<< $msg->stop_workload_replay_context() >> / C<< $msg->stop_workload_replay_context($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadReplayContext>)

Optional. Contains details about the stop workload replay operation.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest

Instance list captured workloads request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Project ID of the project that contains the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse

Instance list captured workloads response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workload_captures() >> / C<< $msg->workload_captures($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapture>)

List of captured workloads for the instance.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#workloadCapturesList`.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapture

Captured workload for an instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workload_id() >> / C<< $msg->workload_id($value) >>

Type: C<String>

Output only. The ID of the captured workload.

=item * C<< $msg->source_instance() >> / C<< $msg->source_instance($value) >>

Type: C<String>

Output only. The name of the source instance.

=item * C<< $msg->workload_capture_state() >> / C<< $msg->workload_capture_state($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::WorkloadCapture::State>)

Output only. The state of the workload capture.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The start time of the workload capture.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The end time of the workload capture.

=item * C<< $msg->replay_instance() >> / C<< $msg->replay_instance($value) >>

Type: C<String>

Output only. The name of the replay instance, if live replay was enabled.

=item * C<< $msg->retention_days() >> / C<< $msg->retention_days($value) >>

Type: C<Int32>

Output only. The retention period in days for the captured workload.

=item * C<< $msg->backup_id() >> / C<< $msg->backup_id($value) >>

Type: C<String>

Output only. The base backup ID associated with the workload capture.

=item * C<< $msg->capture_mode() >> / C<< $msg->capture_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::WorkloadCapture::WorkloadCaptureMode>)

Output only. The capture mode of the workload capture.

=back

=head3 Enum: WorkloadCapture::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<COMPLETED> => C<2>

=item * C<FAILED> => C<3>

=item * C<TERMINATED> => C<4>

=back

=head3 Enum: WorkloadCapture::WorkloadCaptureMode

=over 4

=item * C<WORKLOAD_CAPTURE_MODE_UNSPECIFIED> => C<0>

=item * C<CAPTURE_ONLY> => C<1>

=item * C<CAPTURE_AND_LIVE_REPLAY> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
