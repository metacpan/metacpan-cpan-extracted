package Google::Iam::V3::AccessPoliciesService;

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
    eval { require Google::Iam::V3::AccessPolicyResources };
    eval { require Google::Iam::V3::OperationMetadata };
    eval { require Google::Iam::V3::PolicyBindingResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvaWFtL3YzL2FjY2Vzc19wb2xpY2llc19zZXJ2aWNlLnByb3RvEg1nb29nbGUu
aWFtLnYzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVu
dC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxorZ29vZ2xlL2lhbS92My9hY2Nlc3NfcG9saWN5X3Jlc291cmNlcy5w
cm90bxomZ29vZ2xlL2lhbS92My9vcGVyYXRpb25fbWV0YWRhdGEucHJvdG8aLGdvb2dsZS9p
YW0vdjMvcG9saWN5X2JpbmRpbmdfcmVzb3VyY2VzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5p
bmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvIvwBChlD
cmVhdGVBY2Nlc3NQb2xpY3lSZXF1ZXN0Ej8KBnBhcmVudBgBIAEoCUIn4EEC+kEhEh9pYW0u
Z29vZ2xlYXBpcy5jb20vQWNjZXNzUG9saWN5UgZwYXJlbnQSLQoQYWNjZXNzX3BvbGljeV9p
ZBgCIAEoCUID4EECUg5hY2Nlc3NQb2xpY3lJZBJFCg1hY2Nlc3NfcG9saWN5GAMgASgLMhsu
Z29vZ2xlLmlhbS52My5BY2Nlc3NQb2xpY3lCA+BBAlIMYWNjZXNzUG9saWN5EigKDXZhbGlk
YXRlX29ubHkYBCABKAhCA+BBAVIMdmFsaWRhdGVPbmx5IlUKFkdldEFjY2Vzc1BvbGljeVJl
cXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC+kEhCh9pYW0uZ29vZ2xlYXBpcy5jb20vQWNjZXNz
UG9saWN5UgRuYW1lIowBChlVcGRhdGVBY2Nlc3NQb2xpY3lSZXF1ZXN0EkUKDWFjY2Vzc19w
b2xpY3kYASABKAsyGy5nb29nbGUuaWFtLnYzLkFjY2Vzc1BvbGljeUID4EECUgxhY2Nlc3NQ
b2xpY3kSKAoNdmFsaWRhdGVfb25seRgCIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHkitgEKGURl
bGV0ZUFjY2Vzc1BvbGljeVJlcXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC+kEhCh9pYW0uZ29v
Z2xlYXBpcy5jb20vQWNjZXNzUG9saWN5UgRuYW1lEhcKBGV0YWcYAiABKAlCA+BBAVIEZXRh
ZxIoCg12YWxpZGF0ZV9vbmx5GAMgASgIQgPgQQFSDHZhbGlkYXRlT25seRIZCgVmb3JjZRgE
IAEoCEID4EEBUgVmb3JjZSKiAQoZTGlzdEFjY2Vzc1BvbGljaWVzUmVxdWVzdBI/CgZwYXJl
bnQYASABKAlCJ+BBAvpBIRIfaWFtLmdvb2dsZWFwaXMuY29tL0FjY2Vzc1BvbGljeVIGcGFy
ZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMg
ASgJQgPgQQFSCXBhZ2VUb2tlbiKPAQoaTGlzdEFjY2Vzc1BvbGljaWVzUmVzcG9uc2USRAoP
YWNjZXNzX3BvbGljaWVzGAEgAygLMhsuZ29vZ2xlLmlhbS52My5BY2Nlc3NQb2xpY3lSDmFj
Y2Vzc1BvbGljaWVzEisKD25leHRfcGFnZV90b2tlbhgCIAEoCUID4EEBUg1uZXh0UGFnZVRv
a2VuIqYBCiFTZWFyY2hBY2Nlc3NQb2xpY3lCaW5kaW5nc1JlcXVlc3QSOwoEbmFtZRgBIAEo
CUIn4EEC+kEhCh9pYW0uZ29vZ2xlYXBpcy5jb20vQWNjZXNzUG9saWN5UgRuYW1lEiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbiKYAQoiU2VhcmNoQWNjZXNzUG9saWN5QmluZGluZ3NSZXNwb25zZRJFCg9w
b2xpY3lfYmluZGluZ3MYASADKAsyHC5nb29nbGUuaWFtLnYzLlBvbGljeUJpbmRpbmdSDnBv
bGljeUJpbmRpbmdzEisKD25leHRfcGFnZV90b2tlbhgCIAEoCUID4EEBUg1uZXh0UGFnZVRv
a2VuMtIQCg5BY2Nlc3NQb2xpY2llcxKEAwoSQ3JlYXRlQWNjZXNzUG9saWN5EiguZ29vZ2xl
LmlhbS52My5DcmVhdGVBY2Nlc3NQb2xpY3lSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbiKkAoLT5JMC0QEiMi92My97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
Lyp9L2FjY2Vzc1BvbGljaWVzOg1hY2Nlc3NfcG9saWN5WkIiMS92My97cGFyZW50PWZvbGRl
cnMvKi9sb2NhdGlvbnMvKn0vYWNjZXNzUG9saWNpZXM6DWFjY2Vzc19wb2xpY3laSCI3L3Yz
L3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS9hY2Nlc3NQb2xpY2llczoN
YWNjZXNzX3BvbGljedpBJXBhcmVudCxhY2Nlc3NfcG9saWN5LGFjY2Vzc19wb2xpY3lfaWTK
QSEKDEFjY2Vzc1BvbGljeRIRT3BlcmF0aW9uTWV0YWRhdGESigIKD0dldEFjY2Vzc1BvbGlj
eRIlLmdvb2dsZS5pYW0udjMuR2V0QWNjZXNzUG9saWN5UmVxdWVzdBobLmdvb2dsZS5pYW0u
djMuQWNjZXNzUG9saWN5IrIBgtPkkwKkARIyL3YzL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovYWNjZXNzUG9saWNpZXMvKn1aMxIxL3YzL3tuYW1lPWZvbGRlcnMvKi9sb2NhdGlv
bnMvKi9hY2Nlc3NQb2xpY2llcy8qfVo5EjcvdjMve25hbWU9b3JnYW5pemF0aW9ucy8qL2xv
Y2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp92kEEbmFtZRKGAwoSVXBkYXRlQWNjZXNzUG9s
aWN5EiguZ29vZ2xlLmlhbS52My5VcGRhdGVBY2Nlc3NQb2xpY3lSZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiKmAoLT5JMC+wEyQC92My97YWNjZXNzX3BvbGljeS5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWNjZXNzUG9saWNpZXMvKn06DWFjY2Vzc19w
b2xpY3laUDI/L3YzL3thY2Nlc3NfcG9saWN5Lm5hbWU9Zm9sZGVycy8qL2xvY2F0aW9ucy8q
L2FjY2Vzc1BvbGljaWVzLyp9Og1hY2Nlc3NfcG9saWN5WlYyRS92My97YWNjZXNzX3BvbGlj
eS5uYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9hY2Nlc3NQb2xpY2llcy8qfToN
YWNjZXNzX3BvbGljecpBIQoMQWNjZXNzUG9saWN5EhFPcGVyYXRpb25NZXRhZGF0YRK/AgoS
RGVsZXRlQWNjZXNzUG9saWN5EiguZ29vZ2xlLmlhbS52My5EZWxldGVBY2Nlc3NQb2xpY3lS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLfAYLT5JMCpAEqMi92My97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9WjMqMS92My97
bmFtZT1mb2xkZXJzLyovbG9jYXRpb25zLyovYWNjZXNzUG9saWNpZXMvKn1aOSo3L3YzL3tu
YW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9hY2Nlc3NQb2xpY2llcy8qfdpBBG5h
bWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIRT3BlcmF0aW9uTWV0YWRhdGESoAIKEkxp
c3RBY2Nlc3NQb2xpY2llcxIoLmdvb2dsZS5pYW0udjMuTGlzdEFjY2Vzc1BvbGljaWVzUmVx
dWVzdBopLmdvb2dsZS5pYW0udjMuTGlzdEFjY2Vzc1BvbGljaWVzUmVzcG9uc2UitAGC0+ST
AqQBEjIvdjMve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9hY2Nlc3NQb2xpY2ll
c1ozEjEvdjMve3BhcmVudD1mb2xkZXJzLyovbG9jYXRpb25zLyp9L2FjY2Vzc1BvbGljaWVz
WjkSNy92My97cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKn0vYWNjZXNzUG9s
aWNpZXPaQQZwYXJlbnQS9QIKGlNlYXJjaEFjY2Vzc1BvbGljeUJpbmRpbmdzEjAuZ29vZ2xl
LmlhbS52My5TZWFyY2hBY2Nlc3NQb2xpY3lCaW5kaW5nc1JlcXVlc3QaMS5nb29nbGUuaWFt
LnYzLlNlYXJjaEFjY2Vzc1BvbGljeUJpbmRpbmdzUmVzcG9uc2Ui8QGC0+STAuMBEkwvdjMv
e25hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2FjY2Vzc1BvbGljaWVzLyp9OnNl
YXJjaFBvbGljeUJpbmRpbmdzWkgSRi92My97bmFtZT1mb2xkZXJzLyovbG9jYXRpb25zLyov
YWNjZXNzUG9saWNpZXMvKn06c2VhcmNoUG9saWN5QmluZGluZ3NaSRJHL3YzL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovYWNjZXNzUG9saWNpZXMvKn06c2VhcmNoUG9saWN5Qmlu
ZGluZ3PaQQRuYW1lGkbKQRJpYW0uZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQoEBChFjb20uZ29vZ2xlLmlhbS52M0IT
QWNjZXNzUG9saWNpZXNQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2My9p
YW1wYjtpYW1wYqoCE0dvb2dsZS5DbG91ZC5JYW0uVjPKAhNHb29nbGVcQ2xvdWRcSWFtXFYz
SpRGCgcSBQ4AyAIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAWCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYANQoJCgIDBRIDFwAwCgkKAgMGEgMYADYKCQoCAwcSAxkALQoJCgIDCBIDGgAlCggKAQgS
AxwAMAoJCgIIJRIDHAAwCggKAQgSAx0AQAoJCgIICxIDHQBACggKAQgSAx4AIgoJCgIIChID
HgAiCggKAQgSAx8ANAoJCgIICBIDHwA0CggKAQgSAyAAKgoJCgIIARIDIAAqCggKAQgSAyEA
MAoJCgIIKRIDIQAwCkwKAgYAEgUkAJQBARo/IE1hbmFnZXMgSWRlbnRpdHkgYW5kIEFjY2Vz
cyBNYW5hZ2VtZW50IChJQU0pIGFjY2VzcyBwb2xpY2llcy4KCgoKAwYAARIDJAgWCgoKAwYA
AxIDJQI6CgwKBQYAA5kIEgMlAjoKCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3Ck8KBAYA
AgASBCoCPgMaQSBDcmVhdGVzIGFuIGFjY2VzcyBwb2xpY3ksIGFuZCByZXR1cm5zIGEgbG9u
ZyBydW5uaW5nIG9wZXJhdGlvbi4KCgwKBQYAAgABEgMqBhgKDAoFBgACAAISAyoZMgoMCgUG
AAIAAxIDKw8rCg0KBQYAAgAEEgQsBDcGChEKCQYAAgAEsMq8IhIELAQ3BgoNCgUGAAIABBIE
OAQ5MAoQCggGAAIABJsIABIEOAQ5MAoNCgUGAAIABBIEOgQ9BgoPCgcGAAIABJkIEgQ6BD0G
CiYKBAYAAgESBEECTAMaGCBHZXRzIGFuIGFjY2VzcyBwb2xpY3kuCgoMCgUGAAIBARIDQQYV
CgwKBQYAAgECEgNBFiwKDAoFBgACAQMSA0E3QwoNCgUGAAIBBBIEQgRKBgoRCgkGAAIBBLDK
vCISBEIESgYKDAoFBgACAQQSA0sEMgoPCggGAAIBBJsIABIDSwQyCikKBAYAAgISBE8CYQMa
GyBVcGRhdGVzIGFuIGFjY2VzcyBwb2xpY3kuCgoMCgUGAAICARIDTwYYCgwKBQYAAgICEgNP
GTIKDAoFBgACAgMSA1APKwoNCgUGAAICBBIEUQRcBgoRCgkGAAICBLDKvCISBFEEXAYKDQoF
BgACAgQSBF0EYAYKDwoHBgACAgSZCBIEXQRgBgopCgQGAAIDEgRkAnQDGhsgRGVsZXRlcyBh
biBhY2Nlc3MgcG9saWN5LgoKDAoFBgACAwESA2QGGAoMCgUGAAIDAhIDZBkyCgwKBQYAAgMD
EgNlDysKDQoFBgACAwQSBGYEbgYKEQoJBgACAwSwyrwiEgRmBG4GCgwKBQYAAgMEEgNvBDIK
DwoIBgACAwSbCAASA28EMgoNCgUGAAIDBBIEcARzBgoPCgcGAAIDBJkIEgRwBHMGCicKBAYA
AgQSBXcCgwEDGhggTGlzdHMgYWNjZXNzIHBvbGljaWVzLgoKDAoFBgACBAESA3cGGAoMCgUG
AAIEAhIDdxkyCgwKBQYAAgQDEgN4DykKDgoFBgACBAQSBXkEgQEGChIKCQYAAgQEsMq8IhIF
eQSBAQYKDQoFBgACBAQSBIIBBDQKEAoIBgACBASbCAASBIIBBDQKiAEKBAYAAgUSBocBApMB
Axp4IFJldHVybnMgYWxsIHBvbGljeSBiaW5kaW5ncyB0aGF0IGJpbmQgYSBzcGVjaWZpYyBw
b2xpY3kgaWYgYSB1c2VyIGhhcwogc2VhcmNoUG9saWN5QmluZGluZ3MgcGVybWlzc2lvbiBv
biB0aGF0IHBvbGljeS4KCg0KBQYAAgUBEgSHAQYgCg0KBQYAAgUCEgSHASFCCg0KBQYAAgUD
EgSIAQ8xCg8KBQYAAgUEEgaJAQSRAQYKEwoJBgACBQSwyrwiEgaJAQSRAQYKDQoFBgACBQQS
BJIBBDIKEAoIBgACBQSbCAASBJIBBDIKPgoCBAASBpcBALcBARowIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgQ3JlYXRlQWNjZXNzUG9saWN5IG1ldGhvZC4KCgsKAwQAARIElwEIIQqwAgoEBAAC
ABIGnwECpAEEGp8CIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIHdoZXJlIHRoaXMg
YWNjZXNzIHBvbGljeSB3aWxsIGJlIGNyZWF0ZWQuCgogRm9ybWF0OgogICBgcHJvamVjdHMv
e3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAogICBgcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKICAgYGZvbGRlcnMve2ZvbGRlcl9p
ZH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCiAgIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRp
b25faWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAACAAUSBJ8BAggKDQoFBAACAAES
BJ8BCQ8KDQoFBAACAAMSBJ8BEhMKDwoFBAACAAgSBp8BFKQBAwoQCggEAAIACJwIABIEoAEE
KgoRCgcEAAIACJ8IEgahAQSjAQUK8QIKBAQAAgESBK8BAkca4gIgUmVxdWlyZWQuIFRoZSBJ
RCB0byB1c2UgZm9yIHRoZSBhY2Nlc3MgcG9saWN5LCB3aGljaAogd2lsbCBiZWNvbWUgdGhl
IGZpbmFsIGNvbXBvbmVudCBvZiB0aGUgYWNjZXNzIHBvbGljeSdzCiByZXNvdXJjZSBuYW1l
LgoKIFRoaXMgdmFsdWUgbXVzdCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciBmb2xs
b3dlZCBieSB1cCB0byA2MgogbG93ZXJjYXNlIGxldHRlcnMsIG51bWJlcnMsIGh5cGhlbnMs
IG9yIGRvdHMuIFBhdHRlcm4sCiAvW2Etel1bYS16MC05LVwuXXsyLDYyfS8uCgogVGhpcyB2
YWx1ZSBtdXN0IGJlIHVuaXF1ZSBhbW9uZyBhbGwgYWNjZXNzIHBvbGljaWVzIHdpdGggdGhl
IHNhbWUgcGFyZW50LgoKDQoFBAACAQUSBK8BAggKDQoFBAACAQESBK8BCRkKDQoFBAACAQMS
BK8BHB0KDQoFBAACAQgSBK8BHkYKEAoIBAACAQicCAASBK8BH0UKNgoEBAACAhIEsgECShoo
IFJlcXVpcmVkLiBUaGUgYWNjZXNzIHBvbGljeSB0byBjcmVhdGUuCgoNCgUEAAICBhIEsgEC
DgoNCgUEAAICARIEsgEPHAoNCgUEAAICAxIEsgEfIAoNCgUEAAICCBIEsgEhSQoQCggEAAIC
CJwIABIEsgEiSApuCgQEAAIDEgS2AQJCGmAgT3B0aW9uYWwuIElmIHNldCwgdmFsaWRhdGUg
dGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIGNyZWF0aW9uLCBidXQgZG8gbm90CiBhY3R1
YWxseSBwb3N0IGl0LgoKDQoFBAACAwUSBLYBAgYKDQoFBAACAwESBLYBBxQKDQoFBAACAwMS
BLYBFxgKDQoFBAACAwgSBLYBGUEKEAoIBAACAwicCAASBLYBGkAKOwoCBAESBroBAMgBARot
IFJlcXVlc3QgbWVzc2FnZSBmb3IgR2V0QWNjZXNzUG9saWN5IG1ldGhvZC4KCgsKAwQBARIE
ugEIHgqlAwoEBAECABIGwgECxwEEGpQDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYWNj
ZXNzIHBvbGljeSB0byByZXRyaWV2ZS4KCiBGb3JtYXQ6CiAgIGBwcm9qZWN0cy97cHJvamVj
dF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xp
Y3lfaWR9YAogICBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9hY2Nlc3NQb2xpY2llcy97YWNjZXNzX3BvbGljeV9pZH1gCiAgIGBmb2xkZXJzL3tm
b2xkZXJfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3Nf
cG9saWN5X2lkfWAKICAgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3lfaWR9YAoKDQoF
BAECAAUSBMIBAggKDQoFBAECAAESBMIBCQ0KDQoFBAECAAMSBMIBEBEKDwoFBAECAAgSBsIB
EscBAwoQCggEAQIACJwIABIEwwEEKgoRCgcEAQIACJ8IEgbEAQTGAQUKPgoCBAISBssBANUB
ARowIFJlcXVlc3QgbWVzc2FnZSBmb3IgVXBkYXRlQWNjZXNzUG9saWN5IG1ldGhvZC4KCgsK
AwQCARIEywEIIQqEAQoEBAICABIE0AECShp2IFJlcXVpcmVkLiBUaGUgYWNjZXNzIHBvbGlj
eSB0byB1cGRhdGUuCgogVGhlIGFjY2VzcyBwb2xpY3kncyBgbmFtZWAgZmllbGQgaXMgdXNl
ZCB0byBpZGVudGlmeSB0aGUKIHBvbGljeSB0byB1cGRhdGUuCgoNCgUEAgIABhIE0AECDgoN
CgUEAgIAARIE0AEPHAoNCgUEAgIAAxIE0AEfIAoNCgUEAgIACBIE0AEhSQoQCggEAgIACJwI
ABIE0AEiSApsCgQEAgIBEgTUAQJCGl4gT3B0aW9uYWwuIElmIHNldCwgdmFsaWRhdGUgdGhl
IHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIHVwZGF0ZSwgYnV0IGRvIG5vdAogYWN0dWFsbHkg
cG9zdCBpdC4KCg0KBQQCAgEFEgTUAQIGCg0KBQQCAgEBEgTUAQcUCg0KBQQCAgEDEgTUARcY
Cg0KBQQCAgEIEgTUARlBChAKCAQCAgEInAgAEgTUARpACj4KAgQDEgbYAQDyAQEaMCBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIERlbGV0ZUFjY2Vzc1BvbGljeSBtZXRob2QuCgoLCgMEAwESBNgB
CCEKowMKBAQDAgASBuABAuUBBBqSAyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGFjY2Vz
cyBwb2xpY3kgdG8gZGVsZXRlLgoKIEZvcm1hdDoKICAgYHByb2plY3RzL3twcm9qZWN0X2lk
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97YWNjZXNzX3BvbGljeV9p
ZH1gCiAgIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259
L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9saWN5X2lkfWAKICAgYGZvbGRlcnMve2ZvbGRl
cl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xp
Y3lfaWR9YAogICBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97YWNjZXNzX3BvbGljeV9pZH1gCgoNCgUEAwIA
BRIE4AECCAoNCgUEAwIAARIE4AEJDQoNCgUEAwIAAxIE4AEQEQoPCgUEAwIACBIG4AES5QED
ChAKCAQDAgAInAgAEgThAQQqChEKBwQDAgAInwgSBuIBBOQBBQpvCgQEAwIBEgTpAQI7GmEg
T3B0aW9uYWwuIFRoZSBldGFnIG9mIHRoZSBhY2Nlc3MgcG9saWN5LiBJZiB0aGlzIGlzIHBy
b3ZpZGVkLCBpdCBtdXN0IG1hdGNoCiB0aGUgc2VydmVyJ3MgZXRhZy4KCg0KBQQDAgEFEgTp
AQIICg0KBQQDAgEBEgTpAQkNCg0KBQQDAgEDEgTpARARCg0KBQQDAgEIEgTpARI6ChAKCAQD
AgEInAgAEgTpARM5Cm4KBAQDAgISBO0BAkIaYCBPcHRpb25hbC4gSWYgc2V0LCB2YWxpZGF0
ZSB0aGUgcmVxdWVzdCBhbmQgcHJldmlldyB0aGUgZGVsZXRpb24sIGJ1dCBkbyBub3QKIGFj
dHVhbGx5IHBvc3QgaXQuCgoNCgUEAwICBRIE7QECBgoNCgUEAwICARIE7QEHFAoNCgUEAwIC
AxIE7QEXGAoNCgUEAwICCBIE7QEZQQoQCggEAwICCJwIABIE7QEaQAqKAQoEBAMCAxIE8QEC
Ohp8IE9wdGlvbmFsLiBJZiBzZXQgdG8gdHJ1ZSwgdGhlIHJlcXVlc3Qgd2lsbCBmb3JjZSB0
aGUgZGVsZXRpb24gb2YgdGhlIFBvbGljeQogZXZlbiBpZiB0aGUgUG9saWN5IHJlZmVyZW5j
ZXMgUG9saWN5QmluZGluZ3MuCgoNCgUEAwIDBRIE8QECBgoNCgUEAwIDARIE8QEHDAoNCgUE
AwIDAxIE8QEPEAoNCgUEAwIDCBIE8QEROQoQCggEAwIDCJwIABIE8QESOAo+CgIEBBIG9QEA
lAIBGjAgUmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0QWNjZXNzUG9saWNpZXMgbWV0aG9kLgoK
CwoDBAQBEgT1AQghCr4CCgQEBAIAEgb+AQKDAgQarQIgUmVxdWlyZWQuIFRoZSBwYXJlbnQg
cmVzb3VyY2UsIHdoaWNoIG93bnMgdGhlIGNvbGxlY3Rpb24gb2YgYWNjZXNzIHBvbGljeQog
cmVzb3VyY2VzLgoKIEZvcm1hdDoKICAgYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlv
bnMve2xvY2F0aW9ufWAKICAgYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbn1gCiAgIGBmb2xkZXJzL3tmb2xkZXJfaWR9L2xvY2F0aW9ucy97bG9jYXRp
b259YAogICBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufWAKCg0KBQQEAgAFEgT+AQIICg0KBQQEAgABEgT+AQkPCg0KBQQEAgADEgT+ARIT
Cg8KBQQEAgAIEgb+ARSDAgMKEAoIBAQCAAicCAASBP8BBCoKEQoHBAQCAAifCBIGgAIEggIF
CogCCgQEBAIBEgSKAgI/GvkBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYWNj
ZXNzIHBvbGljaWVzIHRvIHJldHVybi4gVGhlCiBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIg
dGhhbiB0aGlzIHZhbHVlLgoKIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIGFjY2VzcyBw
b2xpY2llcyB3aWxsIGJlIHJldHVybmVkLiBWYWxpZCB2YWx1ZQogcmFuZ2VzIGZyb20gMSB0
byAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCg0K
BQQEAgEFEgSKAgIHCg0KBQQEAgEBEgSKAggRCg0KBQQEAgEDEgSKAhQVCg0KBQQEAgEIEgSK
AhY+ChAKCAQEAgEInAgAEgSKAhc9CokCCgQEBAICEgSTAgJBGvoBIE9wdGlvbmFsLiBBIHBh
Z2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogYExpc3RBY2Nlc3NQb2xpY2ll
c2AgY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZQogc3Vic2VxdWVudCBwYWdl
LgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8K
IGBMaXN0QWNjZXNzUG9saWNpZXNgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRl
ZCB0aGUKIHBhZ2UgdG9rZW4uCgoNCgUEBAICBRIEkwICCAoNCgUEBAICARIEkwIJEwoNCgUE
BAICAxIEkwIWFwoNCgUEBAICCBIEkwIYQAoQCggEBAICCJwIABIEkwIZPwo/CgIEBRIGlwIA
ngIBGjEgUmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdEFjY2Vzc1BvbGljaWVzIG1ldGhvZC4K
CgsKAwQFARIElwIIIgo+CgQEBQIAEgSZAgIsGjAgVGhlIGFjY2VzcyBwb2xpY2llcyBmcm9t
IHRoZSBzcGVjaWZpZWQgcGFyZW50LgoKDQoFBAUCAAQSBJkCAgoKDQoFBAUCAAYSBJkCCxcK
DQoFBAUCAAESBJkCGCcKDQoFBAUCAAMSBJkCKisKmgEKBAQFAgESBJ0CAkYaiwEgT3B0aW9u
YWwuIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRy
aWV2ZSB0aGUgbmV4dAogcGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBh
cmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQFAgEFEgSdAgIICg0KBQQFAgEBEgSdAgkY
Cg0KBQQFAgEDEgSdAhscCg0KBQQFAgEIEgSdAh1FChAKCAQFAgEInAgAEgSdAh5ECkMKAgQG
EgahAgC+AgEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFNlYXJjaEFjY2Vzc1BvbGljeUJpbmRp
bmdzIHJwYy4KCgsKAwQGARIEoQIIKQqUAwoEBAYCABIGqAICrQIEGoMDIFJlcXVpcmVkLiBU
aGUgbmFtZSBvZiB0aGUgYWNjZXNzIHBvbGljeS4KIEZvcm1hdDoKICBgb3JnYW5pemF0aW9u
cy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2ll
cy97YWNjZXNzX3BvbGljeV9pZH1gCiAgYGZvbGRlcnMve2ZvbGRlcl9pZH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3lfaWR9YAogIGBwcm9q
ZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMv
e2FjY2Vzc19wb2xpY3lfaWR9YAogIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0
aW9ucy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9saWN5X2lkfWAKCg0K
BQQGAgAFEgSoAgIICg0KBQQGAgABEgSoAgkNCg0KBQQGAgADEgSoAhARCg8KBQQGAgAIEgao
AhKtAgMKEAoIBAYCAAicCAASBKkCBCoKEQoHBAYCAAifCBIGqgIErAIFCoACCgQEBgIBEgS0
AgI/GvEBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgcG9saWN5IGJpbmRpbmdz
IHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5CiByZXR1cm4gZmV3ZXIgdGhhbiB0aGlzIHZh
bHVlLgoKIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIHBvbGljeSBiaW5kaW5ncyB3aWxs
IGJlIHJldHVybmVkLgogVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3Zl
IDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgoNCgUEBgIBBRIEtAICBwoNCgUEBgIB
ARIEtAIIEQoNCgUEBgIBAxIEtAIUFQoNCgUEBgIBCBIEtAIWPgoQCggEBgIBCJwIABIEtAIX
PQqnAgoEBAYCAhIEvQICQRqYAiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBm
cm9tIGEgcHJldmlvdXMKIGBTZWFyY2hBY2Nlc3NQb2xpY3lCaW5kaW5nc1JlcXVlc3RgIGNh
bGwuIFByb3ZpZGUgdGhpcyB0bwogcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBX
aGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgU2Vh
cmNoQWNjZXNzUG9saWN5QmluZGluZ3NSZXF1ZXN0YCBtdXN0IG1hdGNoIHRoZSBjYWxsCiB0
aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAYCAgUSBL0CAggKDQoFBAYCAgES
BL0CCRMKDQoFBAYCAgMSBL0CFhcKDQoFBAYCAggSBL0CGEAKEAoIBAYCAgicCAASBL0CGT8K
RAoCBAcSBsECAMgCARo2IFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFNlYXJjaEFjY2Vzc1BvbGlj
eUJpbmRpbmdzIHJwYy4KCgsKAwQHARIEwQIIKgpICgQEBwIAEgTDAgItGjogVGhlIHBvbGlj
eSBiaW5kaW5ncyB0aGF0IHJlZmVyZW5jZSB0aGUgc3BlY2lmaWVkIHBvbGljeS4KCg0KBQQH
AgAEEgTDAgIKCg0KBQQHAgAGEgTDAgsYCg0KBQQHAgABEgTDAhkoCg0KBQQHAgADEgTDAiss
CpoBCgQEBwIBEgTHAgJGGosBIE9wdGlvbmFsLiBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2Vu
dCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQKIHBhZ2UuIElmIHRoaXMg
ZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUE
BwIBBRIExwICCAoNCgUEBwIBARIExwIJGAoNCgUEBwIBAxIExwIbHAoNCgUEBwIBCBIExwId
RQoQCggEBwIBCJwIABIExwIeRGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest ===
    # Fields for CreateAccessPolicyRequest
    # Field: parent Type: 9 ()
    # Field: access_policy_id Type: 9 ()
    # Field: access_policy Type: 11 (.google.iam.v3.AccessPolicy)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3::AccessPoliciesService::GetAccessPolicyRequest ===
    # Fields for GetAccessPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V3::AccessPoliciesService::UpdateAccessPolicyRequest ===
    # Fields for UpdateAccessPolicyRequest
    # Field: access_policy Type: 11 (.google.iam.v3.AccessPolicy)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3::AccessPoliciesService::DeleteAccessPolicyRequest ===
    # Fields for DeleteAccessPolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: force Type: 8 ()

# === Message: Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesRequest ===
    # Fields for ListAccessPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesResponse ===
    # Fields for ListAccessPoliciesResponse
    # Field: access_policies Type: 11 (.google.iam.v3.AccessPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsRequest ===
    # Fields for SearchAccessPolicyBindingsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsResponse ===
    # Fields for SearchAccessPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Iam::V3::AccessPoliciesService::AccessPoliciesClient ===
package Google::Iam::V3::AccessPoliciesService::AccessPoliciesClient;

=pod

=head2 Service Client: Google::Iam::V3::AccessPoliciesService::AccessPoliciesClient

Client stub representing the remote C<AccessPolicies> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<iam.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iam.googleapis.com:443' );

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

sub create_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'CreateAccessPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::AccessPoliciesService::GetAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'GetAccessPolicy',
        request        => $req,
        response_class => 'Google::Iam::V3::AccessPolicyResources::AccessPolicy',
    });
}

sub update_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::AccessPoliciesService::UpdateAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'UpdateAccessPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_access_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::AccessPoliciesService::DeleteAccessPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'DeleteAccessPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_access_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'ListAccessPolicies',
        request        => $req,
        response_class => 'Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesResponse',
    });
}

sub search_access_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'SearchAccessPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3::AccessPoliciesService - Compiled Protocol Buffers messages for google/iam/v3/access_policies_service.proto

=head1 SYNOPSIS

    use Google::Iam::V3::AccessPoliciesService;

    my $msg = Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest->new({
        parent => $parent,
        access_policy_id => $access_policy_id,
        access_policy => $access_policy,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/access_policies_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest

Request message for CreateAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this access policy will be created.

Format:
  `projects/{project_id}/locations/{location}`
  `projects/{project_number}/locations/{location}`
  `folders/{folder_id}/locations/{location}`
  `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->access_policy_id() >> / C<< $msg->access_policy_id($value) >>

Type: C<String>

Required. The ID to use for the access policy, which
will become the final component of the access policy's
resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, hyphens, or dots. Pattern,
/[a-z][a-z0-9-\.]{2,62}/.

This value must be unique among all access policies with the same parent.

=item * C<< $msg->access_policy() >> / C<< $msg->access_policy($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicy>)

Required. The access policy to create.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the creation, but do not
actually post it.

=back

=head2 Google::Iam::V3::AccessPoliciesService::GetAccessPolicyRequest

Request message for GetAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the access policy to retrieve.

Format:
  `projects/{project_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `projects/{project_number}/locations/{location}/accessPolicies/{access_policy_id}`
  `folders/{folder_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `organizations/{organization_id}/locations/{location}/accessPolicies/{access_policy_id}`

=back

=head2 Google::Iam::V3::AccessPoliciesService::UpdateAccessPolicyRequest

Request message for UpdateAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_policy() >> / C<< $msg->access_policy($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicy>)

Required. The access policy to update.

The access policy's `name` field is used to identify the
policy to update.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the update, but do not
actually post it.

=back

=head2 Google::Iam::V3::AccessPoliciesService::DeleteAccessPolicyRequest

Request message for DeleteAccessPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the access policy to delete.

Format:
  `projects/{project_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `projects/{project_number}/locations/{location}/accessPolicies/{access_policy_id}`
  `folders/{folder_id}/locations/{location}/accessPolicies/{access_policy_id}`
  `organizations/{organization_id}/locations/{location}/accessPolicies/{access_policy_id}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag of the access policy. If this is provided, it must match
the server's etag.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the deletion, but do not
actually post it.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, the request will force the deletion of the Policy
even if the Policy references PolicyBindings.

=back

=head2 Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesRequest

Request message for ListAccessPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource, which owns the collection of access policy
resources.

Format:
  `projects/{project_id}/locations/{location}`
  `projects/{project_number}/locations/{location}`
  `folders/{folder_id}/locations/{location}`
  `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of access policies to return. The
service may return fewer than this value.

If unspecified, at most 50 access policies will be returned. Valid value
ranges from 1 to 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAccessPolicies` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`ListAccessPolicies` must match the call that provided the
page token.

=back

=head2 Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesResponse

Response message for ListAccessPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_policies() >> / C<< $msg->access_policies($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicy>)

The access policies from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsRequest

Request message for SearchAccessPolicyBindings rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the access policy.
Format:
 `organizations/{organization_id}/locations/{location}/accessPolicies/{access_policy_id}`
 `folders/{folder_id}/locations/{location}/accessPolicies/{access_policy_id}`
 `projects/{project_id}/locations/{location}/accessPolicies/{access_policy_id}`
 `projects/{project_number}/locations/{location}/accessPolicies/{access_policy_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policy bindings to return. The service may
return fewer than this value.

If unspecified, at most 50 policy bindings will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`SearchAccessPolicyBindingsRequest` call. Provide this to
retrieve the subsequent page.

When paginating, all other parameters provided to
`SearchAccessPolicyBindingsRequest` must match the call
that provided the page token.

=back

=head2 Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsResponse

Response message for SearchAccessPolicyBindings rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3::PolicyBindingResources::PolicyBinding>)

The policy bindings that reference the specified policy.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::AccessPoliciesService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
