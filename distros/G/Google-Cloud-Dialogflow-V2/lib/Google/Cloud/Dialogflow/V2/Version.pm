package Google::Cloud::Dialogflow::V2::Version;

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
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi92ZXJzaW9uLnByb3RvEhpnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxog
Z29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8i+QMKB1ZlcnNpb24SFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEiUKC2Rl
c2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEioKDnZlcnNpb25fbnVtYmVyGAMg
ASgFQgPgQQNSDXZlcnNpb25OdW1iZXISQAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSTgoGc3RhdHVzGAYgASgOMjEu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVmVyc2lvbi5WZXJzaW9uU3RhdHVzQgPgQQNS
BnN0YXR1cyJXCg1WZXJzaW9uU3RhdHVzEh4KGlZFUlNJT05fU1RBVFVTX1VOU1BFQ0lGSUVE
EAASDwoLSU5fUFJPR1JFU1MQARIJCgVSRUFEWRACEgoKBkZBSUxFRBADOpYB6kGSAQohZGlh
bG9nZmxvdy5nb29nbGVhcGlzLmNvbS9WZXJzaW9uEitwcm9qZWN0cy97cHJvamVjdH0vYWdl
bnQvdmVyc2lvbnMve3ZlcnNpb259EkBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vYWdlbnQvdmVyc2lvbnMve3ZlcnNpb259Ip4BChNMaXN0VmVyc2lvbnNSZXF1
ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t
L1ZlcnNpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoK
cGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4ifwoUTGlzdFZlcnNpb25zUmVzcG9u
c2USPwoIdmVyc2lvbnMYASADKAsyIy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5WZXJz
aW9uUgh2ZXJzaW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i
UgoRR2V0VmVyc2lvblJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFkaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SBG5hbWUinQEKFENyZWF0ZVZlcnNpb25SZXF1ZXN0
EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Zl
cnNpb25SBnBhcmVudBJCCgd2ZXJzaW9uGAIgASgLMiMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjIuVmVyc2lvbkID4EECUgd2ZXJzaW9uIpwBChRVcGRhdGVWZXJzaW9uUmVxdWVzdBJC
Cgd2ZXJzaW9uGAEgASgLMiMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVmVyc2lvbkID
4EECUgd2ZXJzaW9uEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrIlUKFERlbGV0ZVZlcnNpb25SZXF1ZXN0Ej0KBG5h
bWUYASABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9WZXJzaW9uUgRu
YW1lMvwJCghWZXJzaW9ucxLgAQoMTGlzdFZlcnNpb25zEi8uZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjIuTGlzdFZlcnNpb25zUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyLkxpc3RWZXJzaW9uc1Jlc3BvbnNlIm2C0+STAl4SJi92Mi97cGFyZW50PXByb2plY3Rz
LyovYWdlbnR9L3ZlcnNpb25zWjQSMi92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
LyovYWdlbnR9L3ZlcnNpb25z2kEGcGFyZW50Es0BCgpHZXRWZXJzaW9uEi0uZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjIuR2V0VmVyc2lvblJlcXVlc3QaIy5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52Mi5WZXJzaW9uImuC0+STAl4SJi92Mi97bmFtZT1wcm9qZWN0cy8qL2FnZW50
L3ZlcnNpb25zLyp9WjQSMi92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50
L3ZlcnNpb25zLyp92kEEbmFtZRLwAQoNQ3JlYXRlVmVyc2lvbhIwLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLkNyZWF0ZVZlcnNpb25SZXF1ZXN0GiMuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjIuVmVyc2lvbiKHAYLT5JMCcCImL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9hZ2Vu
dH0vdmVyc2lvbnM6B3ZlcnNpb25aPSIyL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hZ2VudH0vdmVyc2lvbnM6B3ZlcnNpb27aQQ5wYXJlbnQsdmVyc2lvbhKGAgoNVXBk
YXRlVmVyc2lvbhIwLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlVwZGF0ZVZlcnNpb25S
ZXF1ZXN0GiMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVmVyc2lvbiKdAYLT5JMCgAEy
Li92Mi97dmVyc2lvbi5uYW1lPXByb2plY3RzLyovYWdlbnQvdmVyc2lvbnMvKn06B3ZlcnNp
b25aRTI6L3YyL3t2ZXJzaW9uLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC92
ZXJzaW9ucy8qfToHdmVyc2lvbtpBE3ZlcnNpb24sdXBkYXRlX21hc2sSxgEKDURlbGV0ZVZl
cnNpb24SMC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5EZWxldGVWZXJzaW9uUmVxdWVz
dBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJrgtPkkwJeKiYvdjIve25hbWU9cHJvamVjdHMv
Ki9hZ2VudC92ZXJzaW9ucy8qfVo0KjIvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9hZ2VudC92ZXJzaW9ucy8qfdpBBG5hbWUaeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5j
b23SQVlodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KSAQoeY29tLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyQgxWZXJzaW9uUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNv
bS9nby9kaWFsb2dmbG93L2FwaXYyL2RpYWxvZ2Zsb3dwYjtkaWFsb2dmbG93cGKiAgJERqoC
Gkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYySoQ7CgcSBQ4AkQIBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJ
CgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAJQoJCgIDBRIDFwAqCgkKAgMGEgMYACkK
CAoBCBIDGgA3CgkKAgglEgMaADcKCAoBCBIDGwBVCgkKAggLEgMbAFUKCAoBCBIDHAAiCgkK
AggKEgMcACIKCAoBCBIDHQAtCgkKAggIEgMdAC0KCAoBCBIDHgA3CgkKAggBEgMeADcKCAoB
CBIDHwAgCgkKAggkEgMfACAKUgoCBgASBCIAaAEaRiBTZXJ2aWNlIGZvciBtYW5hZ2luZyBb
VmVyc2lvbnNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlZlcnNpb25dLgoKCgoDBgAB
EgMiCBAKCgoDBgADEgMjAkEKDAoFBgADmQgSAyMCQQoLCgMGAAMSBCQCJjMKDQoFBgADmggS
BCQCJjMKSAoEBgACABIEKQIxAxo6IFJldHVybnMgdGhlIGxpc3Qgb2YgYWxsIHZlcnNpb25z
IG9mIHRoZSBzcGVjaWZpZWQgYWdlbnQuCgoMCgUGAAIAARIDKQYSCgwKBQYAAgACEgMpEyYK
DAoFBgACAAMSAykxRQoNCgUGAAIABBIEKgQvBgoRCgkGAAIABLDKvCISBCoELwYKDAoFBgAC
AAQSAzAENAoPCggGAAIABJsIABIDMAQ0CjYKBAYAAgESBDQCPAMaKCBSZXRyaWV2ZXMgdGhl
IHNwZWNpZmllZCBhZ2VudCB2ZXJzaW9uLgoKDAoFBgACAQESAzQGEAoMCgUGAAIBAhIDNBEi
CgwKBQYAAgEDEgM0LTQKDQoFBgACAQQSBDUEOgYKEQoJBgACAQSwyrwiEgQ1BDoGCgwKBQYA
AgEEEgM7BDIKDwoIBgACAQSbCAASAzsEMgp2CgQGAAICEgRBAksDGmggQ3JlYXRlcyBhbiBh
Z2VudCB2ZXJzaW9uLgoKIFRoZSBuZXcgdmVyc2lvbiBwb2ludHMgdG8gdGhlIGFnZW50IGlu
c3RhbmNlIGluIHRoZSAiZGVmYXVsdCIgZW52aXJvbm1lbnQuCgoMCgUGAAICARIDQQYTCgwK
BQYAAgICEgNBFCgKDAoFBgACAgMSA0EzOgoNCgUGAAICBBIEQgRJBgoRCgkGAAICBLDKvCIS
BEIESQYKDAoFBgACAgQSA0oEPAoPCggGAAICBJsIABIDSgQ8CukBCgQGAAIDEgRSAlwDGtoB
IFVwZGF0ZXMgdGhlIHNwZWNpZmllZCBhZ2VudCB2ZXJzaW9uLgoKIE5vdGUgdGhhdCB0aGlz
IG1ldGhvZCBkb2VzIG5vdCBhbGxvdyB5b3UgdG8gdXBkYXRlIHRoZSBzdGF0ZSBvZiB0aGUg
YWdlbnQKIHRoZSBnaXZlbiB2ZXJzaW9uIHBvaW50cyB0by4gSXQgYWxsb3dzIHlvdSB0byB1
cGRhdGUgb25seSBtdXRhYmxlCiBwcm9wZXJ0aWVzIG9mIHRoZSB2ZXJzaW9uIHJlc291cmNl
LgoKDAoFBgACAwESA1IGEwoMCgUGAAIDAhIDUhQoCgwKBQYAAgMDEgNSMzoKDQoFBgACAwQS
BFMEWgYKEQoJBgACAwSwyrwiEgRTBFoGCgwKBQYAAgMEEgNbBEEKDwoIBgACAwSbCAASA1sE
QQozCgQGAAIEEgRfAmcDGiUgRGVsZXRlIHRoZSBzcGVjaWZpZWQgYWdlbnQgdmVyc2lvbi4K
CgwKBQYAAgQBEgNfBhMKDAoFBgACBAISA18UKAoMCgUGAAIEAxIDXzNICg0KBQYAAgQEEgRg
BGUGChEKCQYAAgQEsMq8IhIEYARlBgoMCgUGAAIEBBIDZgQyCg8KCAYAAgQEmwgAEgNmBDIK
lQUKAgQAEgV8AKkBARqHBSBZb3UgY2FuIGNyZWF0ZSBtdWx0aXBsZSB2ZXJzaW9ucyBvZiB5
b3VyIGFnZW50IGFuZCBwdWJsaXNoIHRoZW0gdG8gc2VwYXJhdGUKIGVudmlyb25tZW50cy4K
CiBXaGVuIHlvdSBlZGl0IGFuIGFnZW50LCB5b3UgYXJlIGVkaXRpbmcgdGhlIGRyYWZ0IGFn
ZW50LiBBdCBhbnkgcG9pbnQsIHlvdQogY2FuIHNhdmUgdGhlIGRyYWZ0IGFnZW50IGFzIGFu
IGFnZW50IHZlcnNpb24sIHdoaWNoIGlzIGFuIGltbXV0YWJsZSBzbmFwc2hvdAogb2YgeW91
ciBhZ2VudC4KCiBXaGVuIHlvdSBzYXZlIHRoZSBkcmFmdCBhZ2VudCwgaXQgaXMgcHVibGlz
aGVkIHRvIHRoZSBkZWZhdWx0IGVudmlyb25tZW50LgogV2hlbiB5b3UgY3JlYXRlIGFnZW50
IHZlcnNpb25zLCB5b3UgY2FuIHB1Ymxpc2ggdGhlbSB0byBjdXN0b20gZW52aXJvbm1lbnRz
LgogWW91IGNhbiBjcmVhdGUgYSB2YXJpZXR5IG9mIGN1c3RvbSBlbnZpcm9ubWVudHMgZm9y
OgoKIC0gdGVzdGluZwogLSBkZXZlbG9wbWVudAogLSBwcm9kdWN0aW9uCiAtIGV0Yy4KCiBG
b3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlIHRoZSBbdmVyc2lvbnMgYW5kIGVudmlyb25tZW50
cwogZ3VpZGVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2RvY3MvYWdl
bnRzLXZlcnNpb25zKS4KCgoKAwQAARIDfAgPCgwKAwQABxIFfQKBAQQKDgoFBAAHnQgSBX0C
gQEECioKBAQABAASBoQBApABAxoaIFRoZSBzdGF0dXMgb2YgYSB2ZXJzaW9uLgoKDQoFBAAE
AAESBIQBBxQKOAoGBAAEAAIAEgSGAQQjGiggTm90IHNwZWNpZmllZC4gVGhpcyB2YWx1ZSBp
cyBub3QgdXNlZC4KCg8KBwQABAACAAESBIYBBB4KDwoHBAAEAAIAAhIEhgEhIgpPCgYEAAQA
AgESBIkBBBQaPyBWZXJzaW9uIGlzIG5vdCByZWFkeSB0byBzZXJ2ZSAoZS5nLiB0cmFpbmlu
ZyBpcyBpbiBwcm9ncmVzcykuCgoPCgcEAAQAAgEBEgSJAQQPCg8KBwQABAACAQISBIkBEhMK
LAoGBAAEAAICEgSMAQQOGhwgVmVyc2lvbiBpcyByZWFkeSB0byBzZXJ2ZS4KCg8KBwQABAAC
AgESBIwBBAkKDwoHBAAEAAICAhIEjAEMDQoqCgYEAAQAAgMSBI8BBA8aGiBWZXJzaW9uIHRy
YWluaW5nIGZhaWxlZC4KCg8KBwQABAACAwESBI8BBAoKDwoHBAAEAAIDAhIEjwENDgroAQoE
BAACABIEmAECPhrZASBPdXRwdXQgb25seS4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRo
aXMgYWdlbnQgdmVyc2lvbi4KIFN1cHBvcnRlZCBmb3JtYXRzOgoKIC0gYHByb2plY3RzLzxQ
cm9qZWN0IElEPi9hZ2VudC92ZXJzaW9ucy88VmVyc2lvbiBJRD5gCiAtIGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vYWdlbnQvdmVyc2lvbnMvPFZl
cnNpb24KICAgSUQ+YAoKDQoFBAACAAUSBJgBAggKDQoFBAACAAESBJgBCQ0KDQoFBAACAAMS
BJgBEBEKDQoFBAACAAgSBJgBEj0KEAoIBAACAAicCAASBJgBEzwKTQoEBAACARIEmwECQho/
IE9wdGlvbmFsLiBUaGUgZGV2ZWxvcGVyLXByb3ZpZGVkIGRlc2NyaXB0aW9uIG9mIHRoaXMg
dmVyc2lvbi4KCg0KBQQAAgEFEgSbAQIICg0KBQQAAgEBEgSbAQkUCg0KBQQAAgEDEgSbARcY
Cg0KBQQAAgEIEgSbARlBChAKCAQAAgEInAgAEgSbARpACpgBCgQEAAICEgSfAQJHGokBIE91
dHB1dCBvbmx5LiBUaGUgc2VxdWVudGlhbCBudW1iZXIgb2YgdGhpcyB2ZXJzaW9uLiBUaGlz
IGZpZWxkIGlzIHJlYWQtb25seQogd2hpY2ggbWVhbnMgaXQgY2Fubm90IGJlIHNldCBieSBj
cmVhdGUgYW5kIHVwZGF0ZSBtZXRob2RzLgoKDQoFBAACAgUSBJ8BAgcKDQoFBAACAgESBJ8B
CBYKDQoFBAACAgMSBJ8BGRoKDQoFBAACAggSBJ8BG0YKEAoIBAACAgicCAASBJ8BHEUKkQEK
BAQAAgMSBqMBAqQBMhqAASBPdXRwdXQgb25seS4gVGhlIGNyZWF0aW9uIHRpbWUgb2YgdGhp
cyB2ZXJzaW9uLiBUaGlzIGZpZWxkIGlzIHJlYWQtb25seSwKIGkuZS4sIGl0IGNhbm5vdCBi
ZSBzZXQgYnkgY3JlYXRlIGFuZCB1cGRhdGUgbWV0aG9kcy4KCg0KBQQAAgMGEgSjAQIbCg0K
BQQAAgMBEgSjARwnCg0KBQQAAgMDEgSjASorCg0KBQQAAgMIEgSkAQYxChAKCAQAAgMInAgA
EgSkAQcwCoEBCgQEAAIEEgSoAQJHGnMgT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhp
cyB2ZXJzaW9uLiBUaGlzIGZpZWxkIGlzIHJlYWQtb25seSBhbmQgY2Fubm90CiBiZSBzZXQg
YnkgY3JlYXRlIGFuZCB1cGRhdGUgbWV0aG9kcy4KCg0KBQQAAgQGEgSoAQIPCg0KBQQAAgQB
EgSoARAWCg0KBQQAAgQDEgSoARkaCg0KBQQAAgQIEgSoARtGChAKCAQAAgQInAgAEgSoARxF
CnMKAgQBEgatAQDAAQEaZSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1ZlcnNpb25zLkxp
c3RWZXJzaW9uc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVmVyc2lvbnMuTGlzdFZl
cnNpb25zXS4KCgsKAwQBARIErQEIGwqwAQoEBAECABIGswECuAEEGp8BIFJlcXVpcmVkLiBU
aGUgYWdlbnQgdG8gbGlzdCBhbGwgdmVyc2lvbnMgZnJvbS4KIFN1cHBvcnRlZCBmb3JtYXRz
OgoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudGAKIC0gYHByb2plY3RzLzxQcm9q
ZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2VudGAKCg0KBQQBAgAFEgSzAQII
Cg0KBQQBAgABEgSzAQkPCg0KBQQBAgADEgSzARITCg8KBQQBAgAIEgazARS4AQMKEAoIBAEC
AAicCAASBLQBBCoKEQoHBAECAAifCBIGtQEEtwEFCnMKBAQBAgESBLwBAj8aZSBPcHRpb25h
bC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBw
YWdlLiBCeQogZGVmYXVsdCAxMDAgYW5kIGF0IG1vc3QgMTAwMC4KCg0KBQQBAgEFEgS8AQIH
Cg0KBQQBAgEBEgS8AQgRCg0KBQQBAgEDEgS8ARQVCg0KBQQBAgEIEgS8ARY+ChAKCAQBAgEI
nAgAEgS8ARc9CloKBAQBAgISBL8BAkEaTCBPcHRpb25hbC4gVGhlIG5leHRfcGFnZV90b2tl
biB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAEC
AgUSBL8BAggKDQoFBAECAgESBL8BCRMKDQoFBAECAgMSBL8BFhcKDQoFBAECAggSBL8BGEAK
EAoIBAECAgicCAASBL8BGT8KdAoCBAISBsQBAMwBARpmIFRoZSByZXNwb25zZSBtZXNzYWdl
IGZvcgogW1ZlcnNpb25zLkxpc3RWZXJzaW9uc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djIuVmVyc2lvbnMuTGlzdFZlcnNpb25zXS4KCgsKAwQCARIExAEIHAqKAQoEBAICABIExwEC
IBp8IFRoZSBsaXN0IG9mIGFnZW50IHZlcnNpb25zLiBUaGVyZSB3aWxsIGJlIGEgbWF4aW11
bSBudW1iZXIgb2YgaXRlbXMKIHJldHVybmVkIGJhc2VkIG9uIHRoZSBwYWdlX3NpemUgZmll
bGQgaW4gdGhlIHJlcXVlc3QuCgoNCgUEAgIABBIExwECCgoNCgUEAgIABhIExwELEgoNCgUE
AgIAARIExwETGwoNCgUEAgIAAxIExwEeHwpvCgQEAgIBEgTLAQIdGmEgVG9rZW4gdG8gcmV0
cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUg
bm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQCAgEFEgTLAQIICg0KBQQCAgEB
EgTLAQkYCg0KBQQCAgEDEgTLARscCm8KAgQDEgbQAQDdAQEaYSBUaGUgcmVxdWVzdCBtZXNz
YWdlIGZvcgogW1ZlcnNpb25zLkdldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyLlZlcnNpb25zLkdldFZlcnNpb25dLgoKCwoDBAMBEgTQAQgZCtMBCgQEAwIAEgbXAQLc
AQQawgEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uLgogU3VwcG9ydGVkIGZv
cm1hdHM6CgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3ZlcnNpb25zLzxWZXJz
aW9uIElEPmAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9u
IElEPi9hZ2VudC92ZXJzaW9ucy88VmVyc2lvbgogICBJRD5gCgoNCgUEAwIABRIE1wECCAoN
CgUEAwIAARIE1wEJDQoNCgUEAwIAAxIE1wEQEQoPCgUEAwIACBIG1wES3AEDChAKCAQDAgAI
nAgAEgTYAQQqChEKBwQDAgAInwgSBtkBBNsBBQp1CgIEBBIG4QEA8AEBGmcgVGhlIHJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5DcmVhdGVWZXJzaW9uXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5WZXJzaW9ucy5DcmVhdGVWZXJzaW9uXS4KCgsKAwQEARIE4QEIHAqu
AQoEBAQCABIG5wEC7AEEGp0BIFJlcXVpcmVkLiBUaGUgYWdlbnQgdG8gY3JlYXRlIGEgdmVy
c2lvbiBmb3IuCiBTdXBwb3J0ZWQgZm9ybWF0czoKCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vYWdlbnRgCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlv
biBJRD4vYWdlbnRgCgoNCgUEBAIABRIE5wECCAoNCgUEBAIAARIE5wEJDwoNCgUEBAIAAxIE
5wESEwoPCgUEBAIACBIG5wEU7AEDChAKCAQEAgAInAgAEgToAQQqChEKBwQEAgAInwgSBukB
BOsBBQowCgQEBAIBEgTvAQI/GiIgUmVxdWlyZWQuIFRoZSB2ZXJzaW9uIHRvIGNyZWF0ZS4K
Cg0KBQQEAgEGEgTvAQIJCg0KBQQEAgEBEgTvAQoRCg0KBQQEAgEDEgTvARQVCg0KBQQEAgEI
EgTvARY+ChAKCAQEAgEInAgAEgTvARc9CnUKAgQFEgb0AQCAAgEaZyBUaGUgcmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1ZlcnNpb25zLlVwZGF0ZVZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLlZlcnNpb25zLlVwZGF0ZVZlcnNpb25dLgoKCwoDBAUBEgT0AQgcCs8BCgQE
BQIAEgT7AQI/GsABIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiB0byB1cGRhdGUuCiBTdXBwb3J0
ZWQgZm9ybWF0czoKCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvdmVyc2lvbnMv
PFZlcnNpb24gSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9j
YXRpb24gSUQ+L2FnZW50L3ZlcnNpb25zLzxWZXJzaW9uCiAgIElEPmAKCg0KBQQFAgAGEgT7
AQIJCg0KBQQFAgABEgT7AQoRCg0KBQQFAgADEgT7ARQVCg0KBQQFAgAIEgT7ARY+ChAKCAQF
AgAInAgAEgT7ARc9CkkKBAQFAgESBv4BAv8BLxo5IFJlcXVpcmVkLiBUaGUgbWFzayB0byBj
b250cm9sIHdoaWNoIGZpZWxkcyBnZXQgdXBkYXRlZC4KCg0KBQQFAgEGEgT+AQIbCg0KBQQF
AgEBEgT+ARwnCg0KBQQFAgEDEgT+ASorCg0KBQQFAgEIEgT/AQYuChAKCAQFAgEInAgAEgT/
AQctCnUKAgQGEgaEAgCRAgEaZyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1ZlcnNpb25z
LkRlbGV0ZVZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlZlcnNpb25zLkRl
bGV0ZVZlcnNpb25dLgoKCwoDBAYBEgSEAggcCt0BCgQEBgIAEgaLAgKQAgQazAEgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uIHRvIGRlbGV0ZS4KIFN1cHBvcnRlZCBmb3Jt
YXRzOgoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC92ZXJzaW9ucy88VmVyc2lv
biBJRD5gCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJ
RD4vYWdlbnQvdmVyc2lvbnMvPFZlcnNpb24KICAgSUQ+YAoKDQoFBAYCAAUSBIsCAggKDQoF
BAYCAAESBIsCCQ0KDQoFBAYCAAMSBIsCEBEKDwoFBAYCAAgSBosCEpACAwoQCggEBgIACJwI
ABIEjAIEKgoRCgcEBgIACJ8IEgaNAgSPAgViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: version_number Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status Type: 14 (.google.cloud.dialogflow.v2.Version.VersionStatus)

# Enum: Version::VersionStatus
our $Version_VERSION_STATUS_UNSPECIFIED = 0;
our $Version_IN_PROGRESS = 1;
our $Version_READY = 2;
our $Version_FAILED = 3;

# === Message: Google::Cloud::Dialogflow::V2::Version::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Version::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.cloud.dialogflow.v2.Version)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Version::GetVersionRequest ===
    # Fields for GetVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Version::CreateVersionRequest ===
    # Fields for CreateVersionRequest
    # Field: parent Type: 9 ()
    # Field: version Type: 11 (.google.cloud.dialogflow.v2.Version)

# === Message: Google::Cloud::Dialogflow::V2::Version::UpdateVersionRequest ===
    # Fields for UpdateVersionRequest
    # Field: version Type: 11 (.google.cloud.dialogflow.v2.Version)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2::Version::DeleteVersionRequest ===
    # Fields for DeleteVersionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2::Version::VersionsClient ===
package Google::Cloud::Dialogflow::V2::Version::VersionsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::Version::VersionsClient

Client stub representing the remote C<Versions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub list_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Version::ListVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Versions',
        method         => 'ListVersions',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Version::ListVersionsResponse',
    });
}

sub get_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Version::GetVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Versions',
        method         => 'GetVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Version::Version',
    });
}

sub create_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Version::CreateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Versions',
        method         => 'CreateVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Version::Version',
    });
}

sub update_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Version::UpdateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Versions',
        method         => 'UpdateVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Version::Version',
    });
}

sub delete_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Version::DeleteVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Versions',
        method         => 'DeleteVersion',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Version - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/version.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Version;

    my $msg = Google::Cloud::Dialogflow::V2::Version::Version->new({
        name => $name,
        description => $description,
        version_number => $version_number,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Version::Version->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Version::Version

You can create multiple versions of your agent and publish them to separate
environments.

When you edit an agent, you are editing the draft agent. At any point, you
can save the draft agent as an agent version, which is an immutable snapshot
of your agent.

When you save the draft agent, it is published to the default environment.
When you create agent versions, you can publish them to custom environments.
You can create a variety of custom environments for:

- testing
- development
- production
- etc.

For more information, see the [versions and environments
guide](https://cloud.google.com/dialogflow/docs/agents-versions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique identifier of this agent version.
Supported formats:

- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The developer-provided description of this version.

=item * C<< $msg->version_number() >> / C<< $msg->version_number($value) >>

Type: C<Int32>

Output only. The sequential number of this version. This field is read-only
which means it cannot be set by create and update methods.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time of this version. This field is read-only,
i.e., it cannot be set by create and update methods.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::Version::VersionStatus>)

Output only. The status of this version. This field is read-only and cannot
be set by create and update methods.

=back

=head3 Enum: Version::VersionStatus

=over 4

=item * C<VERSION_STATUS_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<READY> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Dialogflow::V2::Version::ListVersionsRequest

The request message for
[Versions.ListVersions][google.cloud.dialogflow.v2.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all versions from.
Supported formats:

- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2::Version::ListVersionsResponse

The response message for
[Versions.ListVersions][google.cloud.dialogflow.v2.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Version::Version>)

The list of agent versions. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::Version::GetVersionRequest

The request message for
[Versions.GetVersion][google.cloud.dialogflow.v2.Versions.GetVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the version.
Supported formats:

- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=back

=head2 Google::Cloud::Dialogflow::V2::Version::CreateVersionRequest

The request message for
[Versions.CreateVersion][google.cloud.dialogflow.v2.Versions.CreateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to create a version for.
Supported formats:

- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Version::Version>)

Required. The version to create.

=back

=head2 Google::Cloud::Dialogflow::V2::Version::UpdateVersionRequest

The request message for
[Versions.UpdateVersion][google.cloud.dialogflow.v2.Versions.UpdateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Version::Version>)

Required. The version to update.
Supported formats:

- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2::Version::DeleteVersionRequest

The request message for
[Versions.DeleteVersion][google.cloud.dialogflow.v2.Versions.DeleteVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the version to delete.
Supported formats:

- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
