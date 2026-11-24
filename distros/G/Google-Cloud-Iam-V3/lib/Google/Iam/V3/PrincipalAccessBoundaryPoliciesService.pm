package Google::Iam::V3::PrincipalAccessBoundaryPoliciesService;

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
    eval { require Google::Iam::V3::OperationMetadata };
    eval { require Google::Iam::V3::PolicyBindingResources };
    eval { require Google::Iam::V3::PrincipalAccessBoundaryPolicyResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvaWFtL3YzL3ByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWNpZXNfc2Vy
dmljZS5wcm90bxINZ29vZ2xlLmlhbS52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJmdvb2dsZS9pYW0vdjMvb3BlcmF0
aW9uX21ldGFkYXRhLnByb3RvGixnb29nbGUvaWFtL3YzL3BvbGljeV9iaW5kaW5nX3Jlc291
cmNlcy5wcm90bxo+Z29vZ2xlL2lhbS92My9wcmluY2lwYWxfYWNjZXNzX2JvdW5kYXJ5X3Bv
bGljeV9yZXNvdXJjZXMucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnBy
b3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVs
ZF9tYXNrLnByb3RvIvcCCipDcmVhdGVQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJl
cXVlc3QSUAoGcGFyZW50GAEgASgJQjjgQQL6QTISMGlhbS5nb29nbGVhcGlzLmNvbS9Qcmlu
Y2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVIGcGFyZW50ElEKI3ByaW5jaXBhbF9hY2Nlc3Nf
Ym91bmRhcnlfcG9saWN5X2lkGAIgASgJQgPgQQJSH3ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5
UG9saWN5SWQSegogcHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFyeV9wb2xpY3kYAyABKAsyLC5n
b29nbGUuaWFtLnYzLlByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5QgPgQQJSHXByaW5j
aXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EigKDXZhbGlkYXRlX29ubHkYBCABKAhCA+BBAVIM
dmFsaWRhdGVPbmx5IncKJ0dldFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UmVxdWVz
dBJMCgRuYW1lGAEgASgJQjjgQQL6QTIKMGlhbS5nb29nbGVhcGlzLmNvbS9QcmluY2lwYWxB
Y2Nlc3NCb3VuZGFyeVBvbGljeVIEbmFtZSKUAgoqVXBkYXRlUHJpbmNpcGFsQWNjZXNzQm91
bmRhcnlQb2xpY3lSZXF1ZXN0EnoKIHByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5
GAEgASgLMiwuZ29vZ2xlLmlhbS52My5QcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeUID
4EECUh1wcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeRIoCg12YWxpZGF0ZV9vbmx5GAIg
ASgIQgPgQQFSDHZhbGlkYXRlT25seRJACgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayLYAQoqRGVsZXRlUHJpbmNpcGFs
QWNjZXNzQm91bmRhcnlQb2xpY3lSZXF1ZXN0EkwKBG5hbWUYASABKAlCOOBBAvpBMgowaWFt
Lmdvb2dsZWFwaXMuY29tL1ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UgRuYW1lEhcK
BGV0YWcYAiABKAlCA+BBAVIEZXRhZxIoCg12YWxpZGF0ZV9vbmx5GAMgASgIQgPgQQFSDHZh
bGlkYXRlT25seRIZCgVmb3JjZRgEIAEoCEID4EEBUgVmb3JjZSLEAQoqTGlzdFByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXNSZXF1ZXN0ElAKBnBhcmVudBgBIAEoCUI44EEC+kEy
EjBpYW0uZ29vZ2xlYXBpcy5jb20vUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lSBnBh
cmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4i1QEKK0xpc3RQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBv
bGljaWVzUmVzcG9uc2USeQoicHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFyeV9wb2xpY2llcxgB
IAMoCzIsLmdvb2dsZS5pYW0udjMuUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lSH3By
aW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMSKwoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
QgPgQQFSDW5leHRQYWdlVG9rZW4iyAEKMlNlYXJjaFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5
UG9saWN5QmluZGluZ3NSZXF1ZXN0EkwKBG5hbWUYASABKAlCOOBBAvpBMgowaWFtLmdvb2ds
ZWFwaXMuY29tL1ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UgRuYW1lEiAKCXBhZ2Vf
c2l6ZRgDIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAQgASgJQgPgQQFSCXBh
Z2VUb2tlbiKpAQozU2VhcmNoUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5n
c1Jlc3BvbnNlEkUKD3BvbGljeV9iaW5kaW5ncxgBIAMoCzIcLmdvb2dsZS5pYW0udjMuUG9s
aWN5QmluZGluZ1IOcG9saWN5QmluZGluZ3MSKwoPbmV4dF9wYWdlX3Rva2VuGAIgASgJQgPg
QQFSDW5leHRQYWdlVG9rZW4y7A4KH1ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMS
9wIKI0NyZWF0ZVByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EjkuZ29vZ2xlLmlhbS52
My5DcmVhdGVQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIvUBgtPkkwJsIkgvdjMve3BhcmVudD1vcmdhbml6YXRp
b25zLyovbG9jYXRpb25zLyp9L3ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXM6IHBy
aW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWN52kFLcGFyZW50LHByaW5jaXBhbF9hY2Nl
c3NfYm91bmRhcnlfcG9saWN5LHByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5X2lk
ykEyCh1QcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeRIRT3BlcmF0aW9uTWV0YWRhdGES
4QEKIEdldFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EjYuZ29vZ2xlLmlhbS52My5H
ZXRQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJlcXVlc3QaLC5nb29nbGUuaWFtLnYz
LlByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5IleC0+STAkoSSC92My97bmFtZT1vcmdh
bml6YXRpb25zLyovbG9jYXRpb25zLyovcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2ll
cy8qfdpBBG5hbWUS+gIKI1VwZGF0ZVByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5Ejku
Z29vZ2xlLmlhbS52My5VcGRhdGVQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIvgBgtPkkwKNATJpL3YzL3twcmlu
Y2lwYWxfYWNjZXNzX2JvdW5kYXJ5X3BvbGljeS5uYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2Nh
dGlvbnMvKi9wcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzLyp9OiBwcmluY2lwYWxf
YWNjZXNzX2JvdW5kYXJ5X3BvbGljedpBLHByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9s
aWN5LHVwZGF0ZV9tYXNrykEyCh1QcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeRIRT3Bl
cmF0aW9uTWV0YWRhdGEShgIKI0RlbGV0ZVByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5
EjkuZ29vZ2xlLmlhbS52My5EZWxldGVQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIoQBgtPkkwJKKkgvdjMve25h
bWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL3ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5
UG9saWNpZXMvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlv
bk1ldGFkYXRhEvcBCiNMaXN0UHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llcxI5Lmdv
b2dsZS5pYW0udjMuTGlzdFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXNSZXF1ZXN0
GjouZ29vZ2xlLmlhbS52My5MaXN0UHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llc1Jl
c3BvbnNlIlmC0+STAkoSSC92My97cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMv
Kn0vcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llc9pBBnBhcmVudBKiAgorU2VhcmNo
UHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5ncxJBLmdvb2dsZS5pYW0udjMu
U2VhcmNoUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5nc1JlcXVlc3QaQi5n
b29nbGUuaWFtLnYzLlNlYXJjaFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5QmluZGlu
Z3NSZXNwb25zZSJsgtPkkwJfEl0vdjMve25hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9u
cy8qL3ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMvKn06c2VhcmNoUG9saWN5Qmlu
ZGluZ3PaQQRuYW1lGkbKQRJpYW0uZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQpkBChFjb20uZ29vZ2xlLmlhbS52M0Ir
UHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llc1NlcnZpY2VQcm90b1ABWiljbG91ZC5n
b29nbGUuY29tL2dvL2lhbS9hcGl2My9pYW1wYjtpYW1wYqoCE0dvb2dsZS5DbG91ZC5JYW0u
VjPKAhNHb29nbGVcQ2xvdWRcSWFtXFYzSr1ECgcSBQ4AowIBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAWCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgID
AhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAMAoJCgIDBRIDFwA2CgkKAgMGEgMYAEgKCQoC
AwcSAxkALQoJCgIDCBIDGgAlCgkKAgMJEgMbACoKCAoBCBIDHQAwCgkKAgglEgMdADAKCAoB
CBIDHgBACgkKAggLEgMeAEAKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIABMCgkKAggI
EgMgAEwKCAoBCBIDIQAqCgkKAggBEgMhACoKCAoBCBIDIgAwCgkKAggpEgMiADAKXwoCBgAS
BCYAdwEaUyBNYW5hZ2VzIElkZW50aXR5IGFuZCBBY2Nlc3MgTWFuYWdlbWVudCAoSUFNKSBw
cmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5CiBwb2xpY2llcy4KCgoKAwYAARIDJggnCgoKAwYA
AxIDJwI6CgwKBQYAA5kIEgMnAjoKCwoDBgADEgQoAik3Cg0KBQYAA5oIEgQoAik3CmIKBAYA
AgASBC0COgMaVCBDcmVhdGVzIGEgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3ks
IGFuZCByZXR1cm5zIGEgbG9uZyBydW5uaW5nCiBvcGVyYXRpb24uCgoMCgUGAAIAARIDLQYp
CgwKBQYAAgACEgMuBjAKDAoFBgACAAMSAy8PKwoNCgUGAAIABBIEMAQzBgoRCgkGAAIABLDK
vCISBDAEMwYKDQoFBgACAAQSBDQENVYKEAoIBgACAASbCAASBDQENVYKDQoFBgACAAQSBDYE
OQYKDwoHBgACAASZCBIENgQ5Bgo4CgQGAAIBEgQ9AkMDGiogR2V0cyBhIHByaW5jaXBhbCBh
Y2Nlc3MgYm91bmRhcnkgcG9saWN5LgoKDAoFBgACAQESAz0GJgoMCgUGAAIBAhIDPSdOCgwK
BQYAAgEDEgM+DywKDQoFBgACAQQSBD8EQQYKEQoJBgACAQSwyrwiEgQ/BEEGCgwKBQYAAgEE
EgNCBDIKDwoIBgACAQSbCAASA0IEMgo7CgQGAAICEgRGAlMDGi0gVXBkYXRlcyBhIHByaW5j
aXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5LgoKDAoFBgACAgESA0YGKQoMCgUGAAICAhID
RwYwCgwKBQYAAgIDEgNIDysKDQoFBgACAgQSBEkETAYKEQoJBgACAgSwyrwiEgRJBEwGCg0K
BQYAAgIEEgRNBE43ChAKCAYAAgIEmwgAEgRNBE43Cg0KBQYAAgIEEgRPBFIGCg8KBwYAAgIE
mQgSBE8EUgYKOwoEBgACAxIEVgJhAxotIERlbGV0ZXMgYSBwcmluY2lwYWwgYWNjZXNzIGJv
dW5kYXJ5IHBvbGljeS4KCgwKBQYAAgMBEgNWBikKDAoFBgACAwISA1cGMAoMCgUGAAIDAxID
WA8rCg0KBQYAAgMEEgRZBFsGChEKCQYAAgMEsMq8IhIEWQRbBgoMCgUGAAIDBBIDXAQyCg8K
CAYAAgMEmwgAEgNcBDIKDQoFBgACAwQSBF0EYAYKDwoHBgACAwSZCBIEXQRgBgo5CgQGAAIE
EgRkAmsDGisgTGlzdHMgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY2llcy4KCgwK
BQYAAgQBEgNkBikKDAoFBgACBAISA2UGMAoMCgUGAAIEAxIDZg86Cg0KBQYAAgQEEgRnBGkG
ChEKCQYAAgQEsMq8IhIEZwRpBgoMCgUGAAIEBBIDagQ0Cg8KCAYAAgQEmwgAEgNqBDQKhgEK
BAYAAgUSBG8CdgMaeCBSZXR1cm5zIGFsbCBwb2xpY3kgYmluZGluZ3MgdGhhdCBiaW5kIGEg
c3BlY2lmaWMgcG9saWN5IGlmIGEgdXNlciBoYXMKIHNlYXJjaFBvbGljeUJpbmRpbmdzIHBl
cm1pc3Npb24gb24gdGhhdCBwb2xpY3kuCgoMCgUGAAIFARIDbwYxCgwKBQYAAgUCEgNwBjgK
DAoFBgACBQMSA3EPQgoNCgUGAAIFBBIEcgR0BgoRCgkGAAIFBLDKvCISBHIEdAYKDAoFBgAC
BQQSA3UEMgoPCggGAAIFBJsIABIDdQQyClUKAgQAEgV6AJgBARpIIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgQ3JlYXRlUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lSZXF1ZXN0IG1ldGhv
ZC4KCgoKAwQAARIDeggyCtQBCgQEAAIAEgaAAQKFAQQawwEgUmVxdWlyZWQuIFRoZSBwYXJl
bnQgcmVzb3VyY2Ugd2hlcmUgdGhpcyBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGlj
eQogd2lsbCBiZSBjcmVhdGVkLiBPbmx5IG9yZ2FuaXphdGlvbnMgYXJlIHN1cHBvcnRlZC4K
CiBGb3JtYXQ6CiAgIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9u
cy97bG9jYXRpb259YAoKDQoFBAACAAUSBIABAggKDQoFBAACAAESBIABCQ8KDQoFBAACAAMS
BIABEhMKDwoFBAACAAgSBoABFIUBAwoQCggEAAIACJwIABIEgQEEKgoRCgcEAAIACJ8IEgaC
AQSEAQUKzQIKBAQAAgESBo4BAo8BLxq8AiBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3Ig
dGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5LCB3aGljaAogd2lsbCBiZWNv
bWUgdGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFy
eSBwb2xpY3kncwogcmVzb3VyY2UgbmFtZS4KCiBUaGlzIHZhbHVlIG11c3Qgc3RhcnQgd2l0
aCBhIGxvd2VyY2FzZSBsZXR0ZXIgZm9sbG93ZWQgYnkgdXAgdG8gNjIKIGxvd2VyY2FzZSBs
ZXR0ZXJzLCBudW1iZXJzLCBoeXBoZW5zLCBvciBkb3RzLiBQYXR0ZXJuLAogL1thLXpdW2Et
ejAtOS1cLl17Miw2Mn0vLgoKDQoFBAACAQUSBI4BAggKDQoFBAACAQESBI4BCSwKDQoFBAAC
AQMSBI4BLzAKDQoFBAACAQgSBI8BBi4KEAoIBAACAQicCAASBI8BBy0KSwoEBAACAhIGkgEC
kwEvGjsgUmVxdWlyZWQuIFRoZSBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeSB0
byBjcmVhdGUuCgoNCgUEAAICBhIEkgECHwoNCgUEAAICARIEkgEgQAoNCgUEAAICAxIEkgFD
RAoNCgUEAAICCBIEkwEGLgoQCggEAAICCJwIABIEkwEHLQpuCgQEAAIDEgSXAQJCGmAgT3B0
aW9uYWwuIElmIHNldCwgdmFsaWRhdGUgdGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIGNy
ZWF0aW9uLCBidXQgZG8gbm90CiBhY3R1YWxseSBwb3N0IGl0LgoKDQoFBAACAwUSBJcBAgYK
DQoFBAACAwESBJcBBxQKDQoFBAACAwMSBJcBFxgKDQoFBAACAwgSBJcBGUEKEAoIBAACAwic
CAASBJcBGkAKTAoCBAESBpsBAKYBARo+IFJlcXVlc3QgbWVzc2FnZSBmb3IgR2V0UHJpbmNp
cGFsQWNjZXNzQm91bmRhcnlQb2xpY3kgbWV0aG9kLgoKCwoDBAEBEgSbAQgvCuQBCgQEAQIA
EgagAQKlAQQa0wEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwcmluY2lwYWwgYWNjZXNz
IGJvdW5kYXJ5IHBvbGljeSB0byByZXRyaWV2ZS4KCiBGb3JtYXQ6CiAgIGBvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3ByaW5jaXBhbEFj
Y2Vzc0JvdW5kYXJ5UG9saWNpZXMve3ByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5
X2lkfWAKCg0KBQQBAgAFEgSgAQIICg0KBQQBAgABEgSgAQkNCg0KBQQBAgADEgSgARARCg8K
BQQBAgAIEgagARKlAQMKEAoIBAECAAicCAASBKEBBCoKEQoHBAECAAifCBIGogEEpAEFCk8K
AgQCEgapAQC4AQEaQSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZVByaW5jaXBhbEFjY2Vz
c0JvdW5kYXJ5UG9saWN5IG1ldGhvZC4KCgsKAwQCARIEqQEIMgqtAQoEBAICABIGrgECrwEv
GpwBIFJlcXVpcmVkLiBUaGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3kgdG8g
dXBkYXRlLgoKIFRoZSBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeSdzIGBuYW1l
YCBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRoZQogcG9saWN5IHRvIHVwZGF0ZS4KCg0K
BQQCAgAGEgSuAQIfCg0KBQQCAgABEgSuASBACg0KBQQCAgADEgSuAUNECg0KBQQCAgAIEgSv
AQYuChAKCAQCAgAInAgAEgSvAQctCmwKBAQCAgESBLMBAkIaXiBPcHRpb25hbC4gSWYgc2V0
LCB2YWxpZGF0ZSB0aGUgcmVxdWVzdCBhbmQgcHJldmlldyB0aGUgdXBkYXRlLCBidXQgZG8g
bm90CiBhY3R1YWxseSBwb3N0IGl0LgoKDQoFBAICAQUSBLMBAgYKDQoFBAICAQESBLMBBxQK
DQoFBAICAQMSBLMBFxgKDQoFBAICAQgSBLMBGUEKEAoIBAICAQicCAASBLMBGkAKOAoEBAIC
AhIGtgECtwEvGiggT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUKCg0K
BQQCAgIGEgS2AQIbCg0KBQQCAgIBEgS2ARwnCg0KBQQCAgIDEgS2ASorCg0KBQQCAgIIEgS3
AQYuChAKCAQCAgIInAgAEgS3AQctCk8KAgQDEga7AQDSAQEaQSBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIERlbGV0ZVByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5IG1ldGhvZC4KCgsKAwQD
ARIEuwEIMgriAQoEBAMCABIGwAECxQEEGtEBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
cHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3kgdG8gZGVsZXRlLgoKIEZvcm1hdDoK
ICAgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llcy97cHJpbmNpcGFsX2FjY2Vzc19i
b3VuZGFyeV9wb2xpY3lfaWR9YAoKDQoFBAMCAAUSBMABAggKDQoFBAMCAAESBMABCQ0KDQoF
BAMCAAMSBMABEBEKDwoFBAMCAAgSBsABEsUBAwoQCggEAwIACJwIABIEwQEEKgoRCgcEAwIA
CJ8IEgbCAQTEAQUKggEKBAQDAgESBMkBAjsadCBPcHRpb25hbC4gVGhlIGV0YWcgb2YgdGhl
IHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5LgogSWYgdGhpcyBpcyBwcm92aWRl
ZCwgaXQgbXVzdCBtYXRjaCB0aGUgc2VydmVyJ3MgZXRhZy4KCg0KBQQDAgEFEgTJAQIICg0K
BQQDAgEBEgTJAQkNCg0KBQQDAgEDEgTJARARCg0KBQQDAgEIEgTJARI6ChAKCAQDAgEInAgA
EgTJARM5Cm4KBAQDAgISBM0BAkIaYCBPcHRpb25hbC4gSWYgc2V0LCB2YWxpZGF0ZSB0aGUg
cmVxdWVzdCBhbmQgcHJldmlldyB0aGUgZGVsZXRpb24sIGJ1dCBkbyBub3QKIGFjdHVhbGx5
IHBvc3QgaXQuCgoNCgUEAwICBRIEzQECBgoNCgUEAwICARIEzQEHFAoNCgUEAwICAxIEzQEX
GAoNCgUEAwICCBIEzQEZQQoQCggEAwICCJwIABIEzQEaQAqSAQoEBAMCAxIE0QECOhqDASBP
cHRpb25hbC4gSWYgc2V0IHRvIHRydWUsIHRoZSByZXF1ZXN0IHdpbGwgZm9yY2UgdGhlIGRl
bGV0aW9uIG9mIHRoZSBwb2xpY3kKIGV2ZW4gaWYgdGhlIHBvbGljeSBpcyByZWZlcmVuY2Vk
IGluIHBvbGljeSBiaW5kaW5ncy4KCg0KBQQDAgMFEgTRAQIGCg0KBQQDAgMBEgTRAQcMCg0K
BQQDAgMDEgTRAQ8QCg0KBQQDAgMIEgTRARE5ChAKCAQDAgMInAgAEgTRARI4Ck8KAgQEEgbV
AQDyAQEaQSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIExpc3RQcmluY2lwYWxBY2Nlc3NCb3VuZGFy
eVBvbGljaWVzIG1ldGhvZC4KCgsKAwQEARIE1QEIMgq3AQoEBAQCABIG2wEC4AEEGqYBIFJl
cXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlLCB3aGljaCBvd25zIHRoZSBjb2xsZWN0aW9u
IG9mIHByaW5jaXBhbAogYWNjZXNzIGJvdW5kYXJ5IHBvbGljaWVzLgoKIEZvcm1hdDoKICAg
YG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn1g
CgoNCgUEBAIABRIE2wECCAoNCgUEBAIAARIE2wEJDwoNCgUEBAIAAxIE2wESEwoPCgUEBAIA
CBIG2wEU4AEDChAKCAQEAgAInAgAEgTcAQQqChEKBwQEAgAInwgSBt0BBN8BBQqnAgoEBAQC
ARIE6AECPxqYAiBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHByaW5jaXBhbCBh
Y2Nlc3MgYm91bmRhcnkgcG9saWNpZXMgdG8KIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJl
dHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCgogSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3Qg
NTAgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY2llcyB3aWxsIGJlCiByZXR1cm5l
ZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBi
ZSBjb2VyY2VkIHRvCiAxMDAwLgoKDQoFBAQCAQUSBOgBAgcKDQoFBAQCAQESBOgBCBEKDQoF
BAQCAQMSBOgBFBUKDQoFBAQCAQgSBOgBFj4KEAoIBAQCAQicCAASBOgBFz0KqwIKBAQEAgIS
BPEBAkEanAIgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZp
b3VzCiBgTGlzdFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXNgIGNhbGwuIFByb3Zp
ZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUKIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2lu
YXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgTGlzdFByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXNgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92
aWRlZCB0aGUKIHBhZ2UgdG9rZW4uCgoNCgUEBAICBRIE8QECCAoNCgUEBAICARIE8QEJEwoN
CgUEBAICAxIE8QEWFwoNCgUEBAICCBIE8QEYQAoQCggEBAICCJwIABIE8QEZPwpQCgIEBRIG
9QEA/AEBGkIgUmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdFByaW5jaXBhbEFjY2Vzc0JvdW5k
YXJ5UG9saWNpZXMgbWV0aG9kLgoKCwoDBAUBEgT1AQgzClEKBAQFAgASBPcBAlAaQyBUaGUg
cHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY2llcyBmcm9tIHRoZSBzcGVjaWZpZWQg
cGFyZW50LgoKDQoFBAUCAAQSBPcBAgoKDQoFBAUCAAYSBPcBCygKDQoFBAUCAAESBPcBKUsK
DQoFBAUCAAMSBPcBTk8KmgEKBAQFAgESBPsBAkYaiwEgT3B0aW9uYWwuIEEgdG9rZW4sIHdo
aWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dAog
cGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVu
dCBwYWdlcy4KCg0KBQQFAgEFEgT7AQIICg0KBQQFAgEBEgT7AQkYCg0KBQQFAgEDEgT7ARsc
Cg0KBQQFAgEIEgT7AR1FChAKCAQFAgEInAgAEgT7AR5EClQKAgQGEgb/AQCZAgEaRiBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIFNlYXJjaFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5Qmlu
ZGluZ3MgcnBjLgoKCwoDBAYBEgT/AQg6CtYBCgQEBgIAEgaDAgKIAgQaxQEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeS4KIEZv
cm1hdDoKICBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9wcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzL3twcmluY2lwYWxfYWNj
ZXNzX2JvdW5kYXJ5X3BvbGljeV9pZH1gCgoNCgUEBgIABRIEgwICCAoNCgUEBgIAARIEgwIJ
DQoNCgUEBgIAAxIEgwIQEQoPCgUEBgIACBIGgwISiAIDChAKCAQGAgAInAgAEgSEAgQqChEK
BwQGAgAInwgSBoUCBIcCBQqAAgoEBAYCARIEjwICPxrxASBPcHRpb25hbC4gVGhlIG1heGlt
dW0gbnVtYmVyIG9mIHBvbGljeSBiaW5kaW5ncyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1h
eQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4KCiBJZiB1bnNwZWNpZmllZCwgYXQg
bW9zdCA1MCBwb2xpY3kgYmluZGluZ3Mgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVt
IHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAx
MDAwLgoKDQoFBAYCAQUSBI8CAgcKDQoFBAYCAQESBI8CCBEKDQoFBAYCAQMSBI8CFBUKDQoF
BAYCAQgSBI8CFj4KEAoIBAYCAQicCAASBI8CFz0KyQIKBAQGAgISBJgCAkEaugIgT3B0aW9u
YWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgU2VhcmNoUHJp
bmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5nc1JlcXVlc3RgIGNhbGwuIFByb3Zp
ZGUgdGhpcyB0bwogcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2lu
YXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgU2VhcmNoUHJpbmNp
cGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5nc1JlcXVlc3RgIG11c3QgbWF0Y2ggdGhl
IGNhbGwKIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEBgICBRIEmAICCAoN
CgUEBgICARIEmAIJEwoNCgUEBgICAxIEmAIWFwoNCgUEBgICCBIEmAIYQAoQCggEBgICCJwI
ABIEmAIZPwpVCgIEBxIGnAIAowIBGkcgUmVzcG9uc2UgbWVzc2FnZSBmb3IgU2VhcmNoUHJp
bmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5ncyBycGMuCgoLCgMEBwESBJwCCDsK
SAoEBAcCABIEngICLRo6IFRoZSBwb2xpY3kgYmluZGluZ3MgdGhhdCByZWZlcmVuY2UgdGhl
IHNwZWNpZmllZCBwb2xpY3kuCgoNCgUEBwIABBIEngICCgoNCgUEBwIABhIEngILGAoNCgUE
BwIAARIEngIZKAoNCgUEBwIAAxIEngIrLAqaAQoEBAcCARIEogICRhqLASBPcHRpb25hbC4g
QSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZl
IHRoZSBuZXh0CiBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBu
byBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAcCAQUSBKICAggKDQoFBAcCAQESBKICCRgKDQoF
BAcCAQMSBKICGxwKDQoFBAcCAQgSBKICHUUKEAoIBAcCAQicCAASBKICHkRiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest ===
    # Fields for CreatePrincipalAccessBoundaryPolicyRequest
    # Field: parent Type: 9 ()
    # Field: principal_access_boundary_policy_id Type: 9 ()
    # Field: principal_access_boundary_policy Type: 11 (.google.iam.v3.PrincipalAccessBoundaryPolicy)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest ===
    # Fields for GetPrincipalAccessBoundaryPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest ===
    # Fields for UpdatePrincipalAccessBoundaryPolicyRequest
    # Field: principal_access_boundary_policy Type: 11 (.google.iam.v3.PrincipalAccessBoundaryPolicy)
    # Field: validate_only Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest ===
    # Fields for DeletePrincipalAccessBoundaryPolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: force Type: 8 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest ===
    # Fields for ListPrincipalAccessBoundaryPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse ===
    # Fields for ListPrincipalAccessBoundaryPoliciesResponse
    # Field: principal_access_boundary_policies Type: 11 (.google.iam.v3.PrincipalAccessBoundaryPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest ===
    # Fields for SearchPrincipalAccessBoundaryPolicyBindingsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse ===
    # Fields for SearchPrincipalAccessBoundaryPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::PrincipalAccessBoundaryPoliciesClient ===
package Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::PrincipalAccessBoundaryPoliciesClient;

=pod

=head2 Service Client: Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::PrincipalAccessBoundaryPoliciesClient

Client stub representing the remote C<PrincipalAccessBoundaryPolicies> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PrincipalAccessBoundaryPolicies',
        method         => 'CreatePrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PrincipalAccessBoundaryPolicies',
        method         => 'GetPrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy',
    });
}

sub update_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PrincipalAccessBoundaryPolicies',
        method         => 'UpdatePrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PrincipalAccessBoundaryPolicies',
        method         => 'DeletePrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_principal_access_boundary_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PrincipalAccessBoundaryPolicies',
        method         => 'ListPrincipalAccessBoundaryPolicies',
        request        => $req,
        response_class => 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse',
    });
}

sub search_principal_access_boundary_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3.PrincipalAccessBoundaryPolicies',
        method         => 'SearchPrincipalAccessBoundaryPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3::PrincipalAccessBoundaryPoliciesService - Compiled Protocol Buffers messages for google/iam/v3/principal_access_boundary_policies_service.proto

=head1 SYNOPSIS

    use Google::Iam::V3::PrincipalAccessBoundaryPoliciesService;

    my $msg = Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest->new({
        parent => $parent,
        principal_access_boundary_policy_id => $principal_access_boundary_policy_id,
        principal_access_boundary_policy => $principal_access_boundary_policy,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/principal_access_boundary_policies_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest

Request message for CreatePrincipalAccessBoundaryPolicyRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this principal access boundary policy
will be created. Only organizations are supported.

Format:
  `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->principal_access_boundary_policy_id() >> / C<< $msg->principal_access_boundary_policy_id($value) >>

Type: C<String>

Required. The ID to use for the principal access boundary policy, which
will become the final component of the principal access boundary policy's
resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, hyphens, or dots. Pattern,
/[a-z][a-z0-9-\.]{2,62}/.

=item * C<< $msg->principal_access_boundary_policy() >> / C<< $msg->principal_access_boundary_policy($value) >>

Type: C<Message> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy>)

Required. The principal access boundary policy to create.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the creation, but do not
actually post it.

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest

Request message for GetPrincipalAccessBoundaryPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the principal access boundary policy to retrieve.

Format:
  `organizations/{organization_id}/locations/{location}/principalAccessBoundaryPolicies/{principal_access_boundary_policy_id}`

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest

Request message for UpdatePrincipalAccessBoundaryPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal_access_boundary_policy() >> / C<< $msg->principal_access_boundary_policy($value) >>

Type: C<Message> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy>)

Required. The principal access boundary policy to update.

The principal access boundary policy's `name` field is used to identify the
policy to update.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the update, but do not
actually post it.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest

Request message for DeletePrincipalAccessBoundaryPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the principal access boundary policy to delete.

Format:
  `organizations/{organization_id}/locations/{location}/principalAccessBoundaryPolicies/{principal_access_boundary_policy_id}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag of the principal access boundary policy.
If this is provided, it must match the server's etag.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the deletion, but do not
actually post it.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, the request will force the deletion of the policy
even if the policy is referenced in policy bindings.

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest

Request message for ListPrincipalAccessBoundaryPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource, which owns the collection of principal
access boundary policies.

Format:
  `organizations/{organization_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of principal access boundary policies to
return. The service may return fewer than this value.

If unspecified, at most 50 principal access boundary policies will be
returned. The maximum value is 1000; values above 1000 will be coerced to
1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListPrincipalAccessBoundaryPolicies` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`ListPrincipalAccessBoundaryPolicies` must match the call that provided the
page token.

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse

Response message for ListPrincipalAccessBoundaryPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal_access_boundary_policies() >> / C<< $msg->principal_access_boundary_policies($value) >>

Type: C<Message> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy>)

The principal access boundary policies from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest

Request message for SearchPrincipalAccessBoundaryPolicyBindings rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the principal access boundary policy.
Format:
 `organizations/{organization_id}/locations/{location}/principalAccessBoundaryPolicies/{principal_access_boundary_policy_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policy bindings to return. The service may
return fewer than this value.

If unspecified, at most 50 policy bindings will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`SearchPrincipalAccessBoundaryPolicyBindingsRequest` call. Provide this to
retrieve the subsequent page.

When paginating, all other parameters provided to
`SearchPrincipalAccessBoundaryPolicyBindingsRequest` must match the call
that provided the page token.

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse

Response message for SearchPrincipalAccessBoundaryPolicyBindings rpc.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
