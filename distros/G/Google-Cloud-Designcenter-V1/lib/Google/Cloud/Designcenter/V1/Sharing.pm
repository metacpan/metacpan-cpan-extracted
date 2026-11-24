package Google::Cloud::Designcenter::V1::Sharing;

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
    eval { require Google::Cloud::Designcenter::V1::Authoring };
    eval { require Google::Cloud::Designcenter::V1::Enums };
    eval { require Google::Cloud::Designcenter::V1::Ingestion };
    eval { require Google::Cloud::Designcenter::V1::Metadata };
    eval { require Google::Cloud::Designcenter::V1::Parameters };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL3NoYXJpbmcucHJvdG8SHGdvb2dsZS5j
bG91ZC5kZXNpZ25jZW50ZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91ZC9kZXNpZ25jZW50ZXIv
djEvYXV0aG9yaW5nLnByb3RvGihnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2VudW1z
LnByb3RvGixnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2luZ2VzdGlvbi5wcm90bxor
Z29vZ2xlL2Nsb3VkL2Rlc2lnbmNlbnRlci92MS9tZXRhZGF0YS5wcm90bxotZ29vZ2xlL2Ns
b3VkL2Rlc2lnbmNlbnRlci92MS9wYXJhbWV0ZXJzLnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvItEDCgVTaGFyZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSVgoR
ZGVzdGluYXRpb25fc3BhY2UYAiABKAlCKeBBAvpBIwohZGVzaWduY2VudGVyLmdvb2dsZWFw
aXMuY29tL1NwYWNlUhBkZXN0aW5hdGlvblNwYWNlEkAKC2NyZWF0ZV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkQKBXN0YXRlGAQg
ASgOMikuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5TaGFyZS5TdGF0ZUID4EEDUgVz
dGF0ZSI8CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB0lOX1NZTkMQARIPCgtP
VVRfT0ZfU1lOQxACOpAB6kGMAQohZGVzaWduY2VudGVyLmdvb2dsZWFwaXMuY29tL1NoYXJl
Elhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc3BhY2VzL3tzcGFj
ZX0vY2F0YWxvZ3Mve2NhdGFsb2d9L3NoYXJlcy97c2hhcmV9KgZzaGFyZXMyBXNoYXJlIuIF
Cg5TaGFyZWRUZW1wbGF0ZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9u
YW1lGAcgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFS
C2Rlc2NyaXB0aW9uElwKD29yaWdpbl90ZW1wbGF0ZRgDIAEoCUIz4EED+kEtCitkZXNpZ25j
ZW50ZXIuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1RlbXBsYXRlUg5vcmlnaW5UZW1wbGF0ZRJA
CgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKdXBkYXRlVGltZRIxChJsYXRlc3RfcmV2aXNpb25faWQYBiABKAlCA+BB
A1IQbGF0ZXN0UmV2aXNpb25JZBJgChF0ZW1wbGF0ZV9jYXRlZ29yeRgIIAEoDjIuLmdvb2ds
ZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuVGVtcGxhdGVDYXRlZ29yeUID4EECUhB0ZW1wbGF0
ZUNhdGVnb3J5EkMKBHR5cGUYCSABKA4yKi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYx
LlRlbXBsYXRlVHlwZUID4EEBUgR0eXBlOqsB6kGnAQoqZGVzaWduY2VudGVyLmdvb2dsZWFw
aXMuY29tL1NoYXJlZFRlbXBsYXRlElhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vc3BhY2VzL3tzcGFjZX0vc2hhcmVkVGVtcGxhdGVzL3tzaGFyZWRfdGVtcGxh
dGV9Kg9zaGFyZWRUZW1wbGF0ZXMyDnNoYXJlZFRlbXBsYXRlIuYQChZTaGFyZWRUZW1wbGF0
ZVJldmlzaW9uEk0KCmdpdF9zb3VyY2UYBSABKAsyJy5nb29nbGUuY2xvdWQuZGVzaWduY2Vu
dGVyLnYxLkdpdFNvdXJjZUID4EEBSABSCWdpdFNvdXJjZRItCg5nY3Nfc291cmNlX3VyaRgU
IAEoCUIFGAHgQQFIAFIMZ2NzU291cmNlVXJpEpIBCiRhcHBsaWNhdGlvbl90ZW1wbGF0ZV9y
ZXZpc2lvbl9zb3VyY2UYCiABKAlCP+BBAfpBOQo3ZGVzaWduY2VudGVyLmdvb2dsZWFwaXMu
Y29tL0FwcGxpY2F0aW9uVGVtcGxhdGVSZXZpc2lvbkgAUiFhcHBsaWNhdGlvblRlbXBsYXRl
UmV2aXNpb25Tb3VyY2USiAEKH2RldmVsb3Blcl9jb25uZWN0X3NvdXJjZV9jb25maWcYDSAB
KAsyOi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkRldmVsb3BlckNvbm5lY3RTb3Vy
Y2VDb25maWdCA+BBAUgAUhxkZXZlbG9wZXJDb25uZWN0U291cmNlQ29uZmlnEkcKCG9jaV9y
ZXBvGA8gASgLMiUuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5PY2lSZXBvQgPgQQFI
AFIHb2NpUmVwbxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJQoLZGVzY3JpcHRpb24YDCAB
KAlCA+BBAVILZGVzY3JpcHRpb24SQwoEdHlwZRgCIAEoDjIqLmdvb2dsZS5jbG91ZC5kZXNp
Z25jZW50ZXIudjEuVGVtcGxhdGVUeXBlQgPgQQFSBHR5cGUScAoYc2hhcmVkX3RlbXBsYXRl
X21ldGFkYXRhGAYgASgLMjEuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5URkJsdWVw
cmludE1ldGFkYXRhQgPgQQNSFnNoYXJlZFRlbXBsYXRlTWV0YWRhdGESdQoYb3JpZ2luX3Rl
bXBsYXRlX3JldmlzaW9uGAcgASgJQjvgQQP6QTUKM2Rlc2lnbmNlbnRlci5nb29nbGVhcGlz
LmNvbS9DYXRhbG9nVGVtcGxhdGVSZXZpc2lvblIWb3JpZ2luVGVtcGxhdGVSZXZpc2lvbhJA
CgtjcmVhdGVfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRKEAQodYXBwbGljYXRpb25fdGVtcGxhdGVfcmV2aXNpb24YCyABKAsyOy5n
b29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlNlcmlhbGl6ZWRBcHBsaWNhdGlvblRlbXBs
YXRlQgPgQQNSG2FwcGxpY2F0aW9uVGVtcGxhdGVSZXZpc2lvbhJkChNoZWxtX2NoYXJ0X21l
dGFkYXRhGA4gASgLMi8uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5IZWxtQ2hhcnRN
ZXRhZGF0YUID4EEDUhFoZWxtQ2hhcnRNZXRhZGF0YRJgChF0ZW1wbGF0ZV9jYXRlZ29yeRgQ
IAEoDjIuLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuVGVtcGxhdGVDYXRlZ29yeUID
4EEDUhB0ZW1wbGF0ZUNhdGVnb3J5ElwKEGxvZ2ljYWxfcHJvZHVjdHMYESADKAsyLC5nb29n
bGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkxvZ2ljYWxQcm9kdWN0QgPgQQNSD2xvZ2ljYWxQ
cm9kdWN0cxJsCgthbm5vdGF0aW9ucxgSIAMoCzJFLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50
ZXIudjEuU2hhcmVkVGVtcGxhdGVSZXZpc2lvbi5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fu
bm90YXRpb25zEmAKEWluZmVycmVkX21ldGFkYXRhGBMgASgLMi4uZ29vZ2xlLmNsb3VkLmRl
c2lnbmNlbnRlci52MS5JbmZlcnJlZE1ldGFkYXRhQgPgQQNSEGluZmVycmVkTWV0YWRhdGES
VgoOcmVzb3VyY2VfdHlwZXMYFSADKAsyKi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYx
LlJlc291cmNlVHlwZUID4EEDUg1yZXNvdXJjZVR5cGVzEksKCmlhY19zb3VyY2UYGCABKA4y
Jy5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLklBQ1NvdXJjZUID4EEDUglpYWNTb3Vy
Y2USYwoWYXBwbGljYXRpb25fcGFyYW1ldGVycxgZIAMoCzInLmdvb2dsZS5jbG91ZC5kZXNp
Z25jZW50ZXIudjEuUGFyYW1ldGVyQgPgQQFSFWFwcGxpY2F0aW9uUGFyYW1ldGVycxo+ChBB
bm5vdGF0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1
ZToCOAE62AHqQdQBCjJkZXNpZ25jZW50ZXIuZ29vZ2xlYXBpcy5jb20vU2hhcmVkVGVtcGxh
dGVSZXZpc2lvbhJtcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nw
YWNlcy97c3BhY2V9L3NoYXJlZFRlbXBsYXRlcy97c2hhcmVkX3RlbXBsYXRlfS9yZXZpc2lv
bnMve3JldmlzaW9ufSoXc2hhcmVkVGVtcGxhdGVSZXZpc2lvbnMyFnNoYXJlZFRlbXBsYXRl
UmV2aXNpb25CEwoRYXJ0aWZhY3RfbG9jYXRpb25C4QEKIGNvbS5nb29nbGUuY2xvdWQuZGVz
aWduY2VudGVyLnYxQhVTaGFyaW5nUmVzb3VyY2VzUHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNv
bS9nby9kZXNpZ25jZW50ZXIvYXBpdjEvZGVzaWduY2VudGVycGI7ZGVzaWduY2VudGVycGKq
AhxHb29nbGUuQ2xvdWQuRGVzaWduQ2VudGVyLlYxygIcR29vZ2xlXENsb3VkXERlc2lnbkNl
bnRlclxWMeoCH0dvb2dsZTo6Q2xvdWQ6OkRlc2lnbkNlbnRlcjo6VjFKjDkKBxIFDgDhAQEK
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
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIA
KQoJCgIDARIDEwAjCgkKAgMCEgMUADYKCQoCAwMSAxUAMgoJCgIDBBIDFgA2CgkKAgMFEgMX
ADUKCQoCAwYSAxgANwoJCgIDBxIDGQApCggKAQgSAxsAOQoJCgIIJRIDGwA5CggKAQgSAxwA
WwoJCgIICxIDHABbCggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4ANgoJCgIICBIDHgA2
CggKAQgSAx8AOQoJCgIIARIDHwA5CggKAQgSAyAAOQoJCgIIKRIDIAA5CggKAQgSAyEAOAoJ
CgIILRIDIQA4Ci0KAgQAEgQkAEsBGiEgQSBjYXRhbG9nIHNoYXJlIGJldHdlZW4gc3BhY2Vz
LgoKCgoDBAABEgMkCA0KCwoDBAAHEgQlAioECg0KBQQAB50IEgQlAioEClEKBAQABAASBC0C
NgMaQyBUaGUgc2hhcmUgc3RhdHVzLCB3aGljaCBpbmRpY2F0ZXMgd2hldGhlciB0aGUgY2F0
YWxvZyBpcyBpbiBzeW5jLgoKDAoFBAAEAAESAy0HDAozCgYEAAQAAgASAy8EGhokIFRoZSBz
dGF0ZSBvZiB0aGUgc2hhcmUgaXMgdW5rbm93bi4KCg4KBwQABAACAAESAy8EFQoOCgcEAAQA
AgACEgMvGBkKRwoGBAAEAAIBEgMyBBAaOCBUaGUgc2hhcmUgaXMgaW4gc3luYyB3aXRoIHRo
ZSBzaGFyZWQgdGVtcGxhdGUgY2F0YWxvZy4KCg4KBwQABAACAQESAzIECwoOCgcEAAQAAgEC
EgMyDg8KSwoGBAAEAAICEgM1BBQaPCBUaGUgc2hhcmUgaXMgb3V0IG9mIHN5bmMgd2l0aCB0
aGUgc2hhcmVkIHRlbXBsYXRlIGNhdGFsb2cuCgoOCgcEAAQAAgIBEgM1BA8KDgoHBAAEAAIC
AhIDNRITCpoBCgQEAAIAEgM6Aj0ajAEgSWRlbnRpZmllci4gVGhlIHNoYXJlIG5hbWUgaW4g
dGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRs
b2NhdGlvbi9zcGFjZXMvJHNwYWNlL2NhdGFsb2dzLyRjYXRhbG9nL3NoYXJlcy8kc2hhcmVg
CgoMCgUEAAIABRIDOgIICgwKBQQAAgABEgM6CQ0KDAoFBAACAAMSAzoQEQoMCgUEAAIACBID
OhI8Cg8KCAQAAgAInAgAEgM6EzsKkwEKBAQAAgESBD4CQwQahAEgUmVxdWlyZWQuIFRoZSBz
cGFjZSByZXNvdXJjZSBwYXRoIHRvIHdoaWNoIHRoZSBjYXRhbG9nIGlzIHNoYXJlZC4KIEZv
cm1hdCBpcyBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMv
JHNwYWNlYAoKDAoFBAACAQUSAz4CCAoMCgUEAAIBARIDPgkaCgwKBQQAAgEDEgM+HR4KDQoF
BAACAQgSBD4fQwMKDwoIBAACAQicCAASAz8EKgoPCgcEAAIBCJ8IEgRABEIFCjoKBAQAAgIS
BEYCRzIaLCBPdXRwdXQgb25seS4gVGhlIHNoYXJlIGNyZWF0aW9uIHRpbWVzdGFtcC4KCgwK
BQQAAgIGEgNGAhsKDAoFBAACAgESA0YcJwoMCgUEAAICAxIDRiorCgwKBQQAAgIIEgNHBjEK
DwoIBAACAgicCAASA0cHMAozCgQEAAIDEgNKAj4aJiBPdXRwdXQgb25seS4gVGhlIHN0YXRl
IG9mIHRoZSBzaGFyZS4KCgwKBQQAAgMGEgNKAgcKDAoFBAACAwESA0oIDQoMCgUEAAIDAxID
ShARCgwKBQQAAgMIEgNKEj0KDwoIBAACAwicCAASA0oTPAo/CgIEARIETgB5ARozIEEgcmVh
ZC1vbmx5IHRlbXBsYXRlIHRoYXQgaXMgc2hhcmVkIHdpdGggYSBzcGFjZS4KCgoKAwQBARID
TggWCgsKAwQBBxIETwJUBAoNCgUEAQedCBIETwJUBAqLAQoEBAECABIDWAI9Gn4gSWRlbnRp
Zmllci4gVGhlIHNoYXJlZCB0ZW1wbGF0ZSBuYW1lLgogYHByb2plY3RzLyRwcm9qZWN0L2xv
Y2F0aW9ucy8kbG9jYXRpb24vc3BhY2VzLyRzcGFjZS9zaGFyZWRUZW1wbGF0ZXMvJHNoYXJl
ZFRlbXBsYXRlYAoKDAoFBAECAAUSA1gCCAoMCgUEAQIAARIDWAkNCgwKBQQBAgADEgNYEBEK
DAoFBAECAAgSA1gSPAoPCggEAQIACJwIABIDWBM7CjoKBAQBAgESA1sCQxotIE9wdGlvbmFs
LiBUaGUgc2hhcmVkIHRlbXBsYXRlIGRpc3BsYXkgbmFtZS4KCgwKBQQBAgEFEgNbAggKDAoF
BAECAQESA1sJFQoMCgUEAQIBAxIDWxgZCgwKBQQBAgEIEgNbGkIKDwoIBAECAQicCAASA1sb
QQo5CgQEAQICEgNeAkIaLCBPcHRpb25hbC4gVGhlIHNoYXJlZCB0ZW1wbGF0ZSBkZXNjcmlw
dGlvbi4KCgwKBQQBAgIFEgNeAggKDAoFBAECAgESA14JFAoMCgUEAQICAxIDXhcYCgwKBQQB
AgIIEgNeGUEKDwoIBAECAgicCAASA14aQApICgQEAQIDEgRhAmYEGjogT3V0cHV0IG9ubHku
IFRoZSBvcmlnaW4gdGVtcGxhdGUgb2YgdGhlIHNoYXJlZCB0ZW1wbGF0ZS4KCgwKBQQBAgMF
EgNhAggKDAoFBAECAwESA2EJGAoMCgUEAQIDAxIDYRscCg0KBQQBAgMIEgRhHWYDCg8KCAQB
AgMInAgAEgNiBC0KDwoHBAECAwifCBIEYwRlBQpECgQEAQIEEgRpAmoyGjYgT3V0cHV0IG9u
bHkuIFRoZSBzaGFyZWQgdGVtcGxhdGUgY3JlYXRpb24gdGltZXN0YW1wLgoKDAoFBAECBAYS
A2kCGwoMCgUEAQIEARIDaRwnCgwKBQQBAgQDEgNpKisKDAoFBAECBAgSA2oGMQoPCggEAQIE
CJwIABIDagcwCkIKBAQBAgUSBG0CbjIaNCBPdXRwdXQgb25seS4gVGhlIHNoYXJlZCB0ZW1w
bGF0ZSB1cGRhdGUgdGltZXN0YW1wLgoKDAoFBAECBQYSA20CGwoMCgUEAQIFARIDbRwnCgwK
BQQBAgUDEgNtKisKDAoFBAECBQgSA24GMQoPCggEAQIFCJwIABIDbgcwCkMKBAQBAgYSA3EC
TBo2IE91dHB1dCBvbmx5LiBMYXRlc3QgcmV2aXNpb24gb2YgdGhlIHNoYXJlZCB0ZW1wbGF0
ZS4KCgwKBQQBAgYFEgNxAggKDAoFBAECBgESA3EJGwoMCgUEAQIGAxIDcR4fCgwKBQQBAgYI
EgNxIEsKDwoIBAECBgicCAASA3EhSgo3CgQEAQIHEgR0AnUvGikgUmVxdWlyZWQuIFRoZSBj
YXRlZ29yeSBvZiB0aGUgdGVtcGxhdGUuCgoMCgUEAQIHBhIDdAISCgwKBQQBAgcBEgN0EyQK
DAoFBAECBwMSA3QnKAoMCgUEAQIHCBIDdQYuCg8KCAQBAgcInAgAEgN1By0KTgoEBAECCBID
eAJBGkEgT3B0aW9uYWwuIFRoZSBBcHBsaWNhdGlvbiBEZXNpZ24gQ2VudGVyIGFzc2VtYmx5
IHRlbXBsYXRlIHR5cGUuCgoMCgUEAQIIBhIDeAIOCgwKBQQBAggBEgN4DxMKDAoFBAECCAMS
A3gWFwoMCgUEAQIICBIDeBhACg8KCAQBAggInAgAEgN4GT8KSQoCBAISBXwA4QEBGjwgQSBy
ZWFkLW9ubHkgdGVtcGxhdGUgcmV2aXNpb24gdGhhdCBpcyBzaGFyZWQgd2l0aCBhIHNwYWNl
LgoKCgoDBAIBEgN8CB4KDAoDBAIHEgV9AoIBBAoOCgUEAgedCBIFfQKCAQQKSQoEBAIIABIG
hQECnwEDGjkgVGhlIGFydGlmYWN0IGxvY2F0aW9uIG9mIHRoZSBUZXJyYWZvcm0gaW4gdGhl
IHRlbXBsYXRlLgoKDQoFBAIIAAESBIUBCBkKKQoEBAICABIEhwEERhobIE9wdGlvbmFsLiBU
aGUgZ2l0IHNvdXJjZS4KCg0KBQQCAgAGEgSHAQQNCg0KBQQCAgABEgSHAQ4YCg0KBQQCAgAD
EgSHARscCg0KBQQCAgAIEgSHAR1FChAKCAQCAgAInAgAEgSHAR5ECqkBCgQEAgIBEgaMAQSN
AUQamAEgT3B0aW9uYWwuIERlcHJlY2F0ZWQ6IEFkZGVkIG5ldyBmaWVsZCB0Zl9tb2R1bGVf
Z2NzX3VyaS4KIFRoZSBDbG91ZCBTdG9yYWdlIFVSSSwgd2hpY2ggbXVzdCBiZSBpbiB0aGUg
Zm9ybWF0IGdzOi8vW2J1Y2tldF0gb3IKIGdzOi8vW2J1Y2tldF0vW29iamVjdF0uCgoNCgUE
AgIBBRIEjAEECgoNCgUEAgIBARIEjAELGQoNCgUEAgIBAxIEjAEcHgoNCgUEAgIBCBIEjQEI
QwoOCgYEAgIBCAMSBI0BCRoKEAoIBAICAQicCAASBI0BHEIKRQoEBAICAhIGkAEElQEGGjUg
T3B0aW9uYWwuIFRoZSBhcHBsaWNhdGlvbiB0ZW1wbGF0ZSByZXZpc2lvbiBzb3VyY2UuCgoN
CgUEAgICBRIEkAEECgoNCgUEAgICARIEkAELLwoNCgUEAgICAxIEkAEyNAoPCgUEAgICCBIG
kAE1lQEFChAKCAQCAgIInAgAEgSRAQYsChEKBwQCAgIInwgSBpIBBpQBBwqTAQoEBAICAxIG
mQEEmgExGoIBIE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIGZvciBmZXRjaGluZyBjb250ZW50
IGZyb20gc291cmNlIGNvZGUgcmVwb3NpdG9yeQogc3VjaCBhcyBHaXRIdWIgb3IgQml0YnVj
a2V0IHRocm91Z2ggRGV2ZWxvcGVyIENvbm5lY3QuCgoNCgUEAgIDBhIEmQEEIAoNCgUEAgID
ARIEmQEhQAoNCgUEAgIDAxIEmQFDRQoNCgUEAgIDCBIEmgEIMAoQCggEAgIDCJwIABIEmgEJ
LwplCgQEAgIEEgSeAQRDGlcgT3B0aW9uYWwuIFRoZSBPcGVuIENvbnRhaW5lciBJbml0aWF0
aXZlIChPQ0kpIHJlcG8gc291cmNlIHRoYXQgY29udGFpbnMKIGhlbG0gY2hhcnRzLgoKDQoF
BAICBAYSBJ4BBAsKDQoFBAICBAESBJ4BDBQKDQoFBAICBAMSBJ4BFxkKDQoFBAICBAgSBJ4B
GkIKEAoIBAICBAicCAASBJ4BG0EK1wEKBAQCAgUSBKQBAj0ayAEgSWRlbnRpZmllci4gVGhl
IHNoYXJlZCB0ZW1wbGF0ZSByZXZpc2lvbiBuYW1lLgogJHNoYXJlZFRlbXBsYXRlIGlzIGEg
c2VydmVyLWdlbmVyYXRlZCBVVUlELgogYHByb2plY3RzLyRwcm9qZWN0L2xvY2F0aW9ucy8k
bG9jYXRpb24vc3BhY2VzLyRzcGFjZS9zaGFyZWRUZW1wbGF0ZXMvJHNoYXJlZFRlbXBsYXRl
L3JldmlzaW9ucy8kcmV2aXNpb25gCgoNCgUEAgIFBRIEpAECCAoNCgUEAgIFARIEpAEJDQoN
CgUEAgIFAxIEpAEQEQoNCgUEAgIFCBIEpAESPAoQCggEAgIFCJwIABIEpAETOwpDCgQEAgIG
EgSnAQJDGjUgT3B0aW9uYWwuIFRoZSBzaGFyZWQgdGVtcGxhdGUgcmV2aXNpb24gZGVzY3Jp
cHRpb24uCgoNCgUEAgIGBRIEpwECCAoNCgUEAgIGARIEpwEJFAoNCgUEAgIGAxIEpwEXGQoN
CgUEAgIGCBIEpwEaQgoQCggEAgIGCJwIABIEpwEbQQpPCgQEAgIHEgSqAQJBGkEgT3B0aW9u
YWwuIFRoZSBBcHBsaWNhdGlvbiBEZXNpZ24gQ2VudGVyIGFzc2VtYmx5IHRlbXBsYXRlIHR5
cGUuCgoNCgUEAgIHBhIEqgECDgoNCgUEAgIHARIEqgEPEwoNCgUEAgIHAxIEqgEWFwoNCgUE
AgIHCBIEqgEYQAoQCggEAgIHCJwIABIEqgEZPwo8CgQEAgIIEgatAQKuATIaLCBPdXRwdXQg
b25seS4gVGhlIHNoYXJlZCB0ZW1wbGF0ZSBtZXRhZGF0YS4KCg0KBQQCAggGEgStAQIVCg0K
BQQCAggBEgStARYuCg0KBQQCAggDEgStATEyCg0KBQQCAggIEgSuAQYxChAKCAQCAggInAgA
EgSuAQcwCm8KBAQCAgkSBrIBArcBBBpfIE91dHB1dCBvbmx5LiBUaGUgc2hhcmVkIHRlbXBs
YXRlIHJldmlzaW9uIHJlZmVycyB0byB0aGUgZm9sbG93aW5nIGNhdGFsb2cKIHRlbXBsYXRl
IHJldmlzaW9uLgoKDQoFBAICCQUSBLIBAggKDQoFBAICCQESBLIBCSEKDQoFBAICCQMSBLIB
JCUKDwoFBAICCQgSBrIBJrcBAwoQCggEAgIJCJwIABIEswEELQoRCgcEAgIJCJ8IEga0AQS2
AQUKTwoEBAICChIGugECuwEyGj8gT3V0cHV0IG9ubHkuIFRoZSBzaGFyZWQgdGVtcGxhdGUg
cmV2aXNpb24gY3JlYXRpb24gdGltZXN0YW1wLgoKDQoFBAICCgYSBLoBAhsKDQoFBAICCgES
BLoBHCcKDQoFBAICCgMSBLoBKisKDQoFBAICCggSBLsBBjEKEAoIBAICCgicCAASBLsBBzAK
TAoEBAICCxIGvgECvwEyGjwgT3V0cHV0IG9ubHkuIFRoZSBzZXJpYWxpemVkIGFwcGxpY2F0
aW9uIHRlbXBsYXRlIHJldmlzaW9uLgoKDQoFBAICCwYSBL4BAh8KDQoFBAICCwESBL4BID0K
DQoFBAICCwMSBL4BQEIKDQoFBAICCwgSBL8BBjEKEAoIBAICCwicCAASBL8BBzAKNwoEBAIC
DBIGwgECwwEyGicgT3V0cHV0IG9ubHkuIFRoZSBoZWxtIGNoYXJ0IG1ldGFkYXRhLgoKDQoF
BAICDAYSBMIBAhMKDQoFBAICDAESBMIBFCcKDQoFBAICDAMSBMIBKiwKDQoFBAICDAgSBMMB
BjEKEAoIBAICDAicCAASBMMBBzAKPAoEBAICDRIGxgECxwEyGiwgT3V0cHV0IG9ubHkuIFRo
ZSBjYXRlZ29yeSBvZiB0aGUgdGVtcGxhdGUuCgoNCgUEAgINBhIExgECEgoNCgUEAgINARIE
xgETJAoNCgUEAgINAxIExgEnKQoNCgUEAgINCBIExwEGMQoQCggEAgINCJwIABIExwEHMApR
CgQEAgIOEgbKAQLLATIaQSBPdXRwdXQgb25seS4gVGhlIFByb2R1Y3QgTWFpbiBsb2dpY2Fs
IHByb2R1Y3QgdHlwZSBpbmZvcm1hdGlvbi4KCg0KBQQCAg4EEgTKAQIKCg0KBQQCAg4GEgTK
AQsZCg0KBQQCAg4BEgTKARoqCg0KBQQCAg4DEgTKAS0vCg0KBQQCAg4IEgTLAQYxChAKCAQC
Ag4InAgAEgTLAQcwCoYBCgQEAgIPEgTPAQJQGnggT3B0aW9uYWwuIFRoZSBhbm5vdGF0aW9u
cyBvZiB0aGUgc2hhcmVkIHRlbXBsYXRlIHJldmlzaW9uLgogS2V5IGlzIHRoZSBhbm5vdGF0
aW9uIG5hbWUuIFZhbHVlIGlzIHRoZSBhbm5vdGF0aW9uIHZhbHVlLgoKDQoFBAICDwYSBM8B
AhUKDQoFBAICDwESBM8BFiEKDQoFBAICDwMSBM8BJCYKDQoFBAICDwgSBM8BJ08KEAoIBAIC
DwicCAASBM8BKE4KYwoEBAICEBIG0wEC1AEyGlMgT3V0cHV0IG9ubHkuIE1ldGFkYXRhIHRo
YXQgd2FzIGF1dG9tYXRpY2FsbHkgaW5mZXJyZWQgZnJvbSB0aGUgdGVtcGxhdGUKIGNvbnRl
bnQuCgoNCgUEAgIQBhIE0wECEgoNCgUEAgIQARIE0wETJAoNCgUEAgIQAxIE0wEnKQoNCgUE
AgIQCBIE1AEGMQoQCggEAgIQCJwIABIE1AEHMApTCgQEAgIREgbXAQLYATIaQyBPdXRwdXQg
b25seS4gVGhlIHJlc291cmNlIHR5cGVzIHByZXNlbnQgaW4gdGhlIHRlbXBsYXRlIHJldmlz
aW9uLgoKDQoFBAICEQQSBNcBAgoKDQoFBAICEQYSBNcBCxcKDQoFBAICEQESBNcBGCYKDQoF
BAICEQMSBNcBKSsKDQoFBAICEQgSBNgBBjEKEAoIBAICEQicCAASBNgBBzAKXwoEBAICEhIE
3AECSBpRIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgdGhlIElhQyBzb3VyY2UgZm9ybWF0IG9m
IHRoaXMgc2hhcmVkIHRlbXBsYXRlCiByZXZpc2lvbi4KCg0KBQQCAhIGEgTcAQILCg0KBQQC
AhIBEgTcAQwWCg0KBQQCAhIDEgTcARkbCg0KBQQCAhIIEgTcARxHChAKCAQCAhIInAgAEgTc
AR1GCkgKBAQCAhMSBt8BAuABLxo4IE9wdGlvbmFsLiBUaGUgdmFsdWVzIHByb3ZpZGVkIGZv
ciB0aGUgaW5wdXQgdmFyaWFibGVzLgoKDQoFBAICEwQSBN8BAgoKDQoFBAICEwYSBN8BCxQK
DQoFBAICEwESBN8BFSsKDQoFBAICEwMSBN8BLjAKDQoFBAICEwgSBOABBi4KEAoIBAICEwic
CAASBOABBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::Sharing::Share ===
    # Fields for Share
    # Field: name Type: 9 ()
    # Field: destination_space Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.designcenter.v1.Share.State)

# Enum: Share::State
our $Share_STATE_UNSPECIFIED = 0;
our $Share_IN_SYNC = 1;
our $Share_OUT_OF_SYNC = 2;

# === Message: Google::Cloud::Designcenter::V1::Sharing::SharedTemplate ===
    # Fields for SharedTemplate
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: origin_template Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: latest_revision_id Type: 9 ()
    # Field: template_category Type: 14 (.google.cloud.designcenter.v1.TemplateCategory)
    # Field: type Type: 14 (.google.cloud.designcenter.v1.TemplateType)

# === Message: Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision ===
    # Fields for SharedTemplateRevision
    # Field: git_source Type: 11 (.google.cloud.designcenter.v1.GitSource)
    # Field: gcs_source_uri Type: 9 ()
    # Field: application_template_revision_source Type: 9 ()
    # Field: developer_connect_source_config Type: 11 (.google.cloud.designcenter.v1.DeveloperConnectSourceConfig)
    # Field: oci_repo Type: 11 (.google.cloud.designcenter.v1.OciRepo)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: type Type: 14 (.google.cloud.designcenter.v1.TemplateType)
    # Field: shared_template_metadata Type: 11 (.google.cloud.designcenter.v1.TFBlueprintMetadata)
    # Field: origin_template_revision Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: application_template_revision Type: 11 (.google.cloud.designcenter.v1.SerializedApplicationTemplate)
    # Field: helm_chart_metadata Type: 11 (.google.cloud.designcenter.v1.HelmChartMetadata)
    # Field: template_category Type: 14 (.google.cloud.designcenter.v1.TemplateCategory)
    # Field: logical_products Type: 11 (.google.cloud.designcenter.v1.LogicalProduct)
    # Field: annotations Type: 11 (.google.cloud.designcenter.v1.SharedTemplateRevision.AnnotationsEntry)
    # Field: inferred_metadata Type: 11 (.google.cloud.designcenter.v1.InferredMetadata)
    # Field: resource_types Type: 11 (.google.cloud.designcenter.v1.ResourceType)
    # Field: iac_source Type: 14 (.google.cloud.designcenter.v1.IACSource)
    # Field: application_parameters Type: 11 (.google.cloud.designcenter.v1.Parameter)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::Sharing - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/sharing.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::Sharing;

    my $msg = Google::Cloud::Designcenter::V1::Sharing::Share->new({
        name => $name,
        destination_space => $destination_space,
        create_time => $create_time,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::Sharing::Share->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/sharing.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::Sharing::Share

A catalog share between spaces.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The share name in the following format:
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog/shares/$share`

=item * C<< $msg->destination_space() >> / C<< $msg->destination_space($value) >>

Type: C<String>

Required. The space resource path to which the catalog is shared.
Format is `projects/$project/locations/$location/spaces/$space`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The share creation timestamp.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::Share::State>)

Output only. The state of the share.

=back

=head3 Enum: Share::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<IN_SYNC> => C<1>

=item * C<OUT_OF_SYNC> => C<2>

=back

=head2 Google::Cloud::Designcenter::V1::Sharing::SharedTemplate

A read-only template that is shared with a space.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The shared template name.
`projects/$project/locations/$location/spaces/$space/sharedTemplates/$sharedTemplate`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The shared template display name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The shared template description.

=item * C<< $msg->origin_template() >> / C<< $msg->origin_template($value) >>

Type: C<String>

Output only. The origin template of the shared template.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The shared template creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The shared template update timestamp.

=item * C<< $msg->latest_revision_id() >> / C<< $msg->latest_revision_id($value) >>

Type: C<String>

Output only. Latest revision of the shared template.

=item * C<< $msg->template_category() >> / C<< $msg->template_category($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateCategory>)

Required. The category of the template.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateType>)

Optional. The Application Design Center assembly template type.

=back

=head2 Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision

A read-only template revision that is shared with a space.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->git_source() >> / C<< $msg->git_source($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::GitSource>)

Optional. The git source.

=item * C<< $msg->gcs_source_uri() >> / C<< $msg->gcs_source_uri($value) >>

Type: C<String>

Optional. Deprecated: Added new field tf_module_gcs_uri.
The Cloud Storage URI, which must be in the format gs://[bucket] or
gs://[bucket]/[object].

=item * C<< $msg->application_template_revision_source() >> / C<< $msg->application_template_revision_source($value) >>

Type: C<String>

Optional. The application template revision source.

=item * C<< $msg->developer_connect_source_config() >> / C<< $msg->developer_connect_source_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig>)

Optional. Configuration for fetching content from source code repository
such as GitHub or Bitbucket through Developer Connect.

=item * C<< $msg->oci_repo() >> / C<< $msg->oci_repo($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::OciRepo>)

Optional. The Open Container Initiative (OCI) repo source that contains
helm charts.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The shared template revision name.
$sharedTemplate is a server-generated UUID.
`projects/$project/locations/$location/spaces/$space/sharedTemplates/$sharedTemplate/revisions/$revision`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The shared template revision description.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateType>)

Optional. The Application Design Center assembly template type.

=item * C<< $msg->shared_template_metadata() >> / C<< $msg->shared_template_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::TFBlueprintMetadata>)

Output only. The shared template metadata.

=item * C<< $msg->origin_template_revision() >> / C<< $msg->origin_template_revision($value) >>

Type: C<String>

Output only. The shared template revision refers to the following catalog
template revision.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The shared template revision creation timestamp.

=item * C<< $msg->application_template_revision() >> / C<< $msg->application_template_revision($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Authoring::SerializedApplicationTemplate>)

Output only. The serialized application template revision.

=item * C<< $msg->helm_chart_metadata() >> / C<< $msg->helm_chart_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::HelmChartMetadata>)

Output only. The helm chart metadata.

=item * C<< $msg->template_category() >> / C<< $msg->template_category($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateCategory>)

Output only. The category of the template.

=item * C<< $msg->logical_products() >> / C<< $msg->logical_products($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::LogicalProduct>)

Output only. The Product Main logical product type information.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision::AnnotationsEntry>)

Optional. The annotations of the shared template revision.
Key is the annotation name. Value is the annotation value.

=item * C<< $msg->inferred_metadata() >> / C<< $msg->inferred_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::InferredMetadata>)

Output only. Metadata that was automatically inferred from the template
content.

=item * C<< $msg->resource_types() >> / C<< $msg->resource_types($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::ResourceType>)

Output only. The resource types present in the template revision.

=item * C<< $msg->iac_source() >> / C<< $msg->iac_source($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::IACSource>)

Output only. Indicates the IaC source format of this shared template
revision.

=item * C<< $msg->application_parameters() >> / C<< $msg->application_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::Parameter>)

Optional. The values provided for the input variables.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::Sharing::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
