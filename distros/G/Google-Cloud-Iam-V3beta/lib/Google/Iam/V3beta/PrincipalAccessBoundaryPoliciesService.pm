package Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService;

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
    eval { require Google::Iam::V3beta::OperationMetadata };
    eval { require Google::Iam::V3beta::PolicyBindingResources };
    eval { require Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvaWFtL3YzYmV0YS9wcmluY2lwYWxfYWNjZXNzX2JvdW5kYXJ5X3BvbGljaWVz
X3NlcnZpY2UucHJvdG8SEWdvb2dsZS5pYW0udjNiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoqZ29vZ2xlL2lhbS92
M2JldGEvb3BlcmF0aW9uX21ldGFkYXRhLnByb3RvGjBnb29nbGUvaWFtL3YzYmV0YS9wb2xp
Y3lfYmluZGluZ19yZXNvdXJjZXMucHJvdG8aQmdvb2dsZS9pYW0vdjNiZXRhL3ByaW5jaXBh
bF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5X3Jlc291cmNlcy5wcm90bxojZ29vZ2xlL2xvbmdy
dW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxog
Z29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i+wIKKkNyZWF0ZVByaW5jaXBhbEFj
Y2Vzc0JvdW5kYXJ5UG9saWN5UmVxdWVzdBJQCgZwYXJlbnQYASABKAlCOOBBAvpBMhIwaWFt
Lmdvb2dsZWFwaXMuY29tL1ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UgZwYXJlbnQS
UQojcHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFyeV9wb2xpY3lfaWQYAiABKAlCA+BBAlIfcHJp
bmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lJZBJ+CiBwcmluY2lwYWxfYWNjZXNzX2JvdW5k
YXJ5X3BvbGljeRgDIAEoCzIwLmdvb2dsZS5pYW0udjNiZXRhLlByaW5jaXBhbEFjY2Vzc0Jv
dW5kYXJ5UG9saWN5QgPgQQJSHXByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EigKDXZh
bGlkYXRlX29ubHkYBCABKAhCA+BBAVIMdmFsaWRhdGVPbmx5IncKJ0dldFByaW5jaXBhbEFj
Y2Vzc0JvdW5kYXJ5UG9saWN5UmVxdWVzdBJMCgRuYW1lGAEgASgJQjjgQQL6QTIKMGlhbS5n
b29nbGVhcGlzLmNvbS9QcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVIEbmFtZSKYAgoq
VXBkYXRlUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lSZXF1ZXN0En4KIHByaW5jaXBh
bF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5GAEgASgLMjAuZ29vZ2xlLmlhbS52M2JldGEuUHJp
bmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCA+BBAlIdcHJpbmNpcGFsQWNjZXNzQm91bmRh
cnlQb2xpY3kSKAoNdmFsaWRhdGVfb25seRgCIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHkSQAoL
dXBkYXRlX21hc2sYAyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVw
ZGF0ZU1hc2si2AEKKkRlbGV0ZVByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UmVxdWVz
dBJMCgRuYW1lGAEgASgJQjjgQQL6QTIKMGlhbS5nb29nbGVhcGlzLmNvbS9QcmluY2lwYWxB
Y2Nlc3NCb3VuZGFyeVBvbGljeVIEbmFtZRIXCgRldGFnGAIgASgJQgPgQQFSBGV0YWcSKAoN
dmFsaWRhdGVfb25seRgDIAEoCEID4EEBUgx2YWxpZGF0ZU9ubHkSGQoFZm9yY2UYBCABKAhC
A+BBAVIFZm9yY2UixAEKKkxpc3RQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzUmVx
dWVzdBJQCgZwYXJlbnQYASABKAlCOOBBAvpBMhIwaWFtLmdvb2dsZWFwaXMuY29tL1ByaW5j
aXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuItkBCitM
aXN0UHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llc1Jlc3BvbnNlEn0KInByaW5jaXBh
bF9hY2Nlc3NfYm91bmRhcnlfcG9saWNpZXMYASADKAsyMC5nb29nbGUuaWFtLnYzYmV0YS5Q
cmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVIfcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQ
b2xpY2llcxIrCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlCA+BBAVINbmV4dFBhZ2VUb2tlbiLI
AQoyU2VhcmNoUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5nc1JlcXVlc3QS
TAoEbmFtZRgBIAEoCUI44EEC+kEyCjBpYW0uZ29vZ2xlYXBpcy5jb20vUHJpbmNpcGFsQWNj
ZXNzQm91bmRhcnlQb2xpY3lSBG5hbWUSIAoJcGFnZV9zaXplGAMgASgFQgPgQQFSCHBhZ2VT
aXplEiIKCnBhZ2VfdG9rZW4YBCABKAlCA+BBAVIJcGFnZVRva2VuIq0BCjNTZWFyY2hQcmlu
Y2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeUJpbmRpbmdzUmVzcG9uc2USSQoPcG9saWN5X2Jp
bmRpbmdzGAEgAygLMiAuZ29vZ2xlLmlhbS52M2JldGEuUG9saWN5QmluZGluZ1IOcG9saWN5
QmluZGluZ3MSKwoPbmV4dF9wYWdlX3Rva2VuGAIgASgJQgPgQQFSDW5leHRQYWdlVG9rZW4y
qA8KH1ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMS/wIKI0NyZWF0ZVByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWN5Ej0uZ29vZ2xlLmlhbS52M2JldGEuQ3JlYXRlUHJpbmNp
cGFsQWNjZXNzQm91bmRhcnlQb2xpY3lSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiL5AYLT5JMCcCJML3YzYmV0YS97cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9sb2Nh
dGlvbnMvKn0vcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llczogcHJpbmNpcGFsX2Fj
Y2Vzc19ib3VuZGFyeV9wb2xpY3naQUtwYXJlbnQscHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFy
eV9wb2xpY3kscHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFyeV9wb2xpY3lfaWTKQTIKHVByaW5j
aXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EhFPcGVyYXRpb25NZXRhZGF0YRLtAQogR2V0UHJp
bmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3kSOi5nb29nbGUuaWFtLnYzYmV0YS5HZXRQcmlu
Y2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJlcXVlc3QaMC5nb29nbGUuaWFtLnYzYmV0YS5Q
cmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeSJbgtPkkwJOEkwvdjNiZXRhL3tuYW1lPW9y
Z2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9wcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGlj
aWVzLyp92kEEbmFtZRKCAwojVXBkYXRlUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3kS
PS5nb29nbGUuaWFtLnYzYmV0YS5VcGRhdGVQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGlj
eVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIvwBgtPkkwKRATJtL3Yz
YmV0YS97cHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFyeV9wb2xpY3kubmFtZT1vcmdhbml6YXRp
b25zLyovbG9jYXRpb25zLyovcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llcy8qfTog
cHJpbmNpcGFsX2FjY2Vzc19ib3VuZGFyeV9wb2xpY3naQSxwcmluY2lwYWxfYWNjZXNzX2Jv
dW5kYXJ5X3BvbGljeSx1cGRhdGVfbWFza8pBMgodUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQ
b2xpY3kSEU9wZXJhdGlvbk1ldGFkYXRhEo4CCiNEZWxldGVQcmluY2lwYWxBY2Nlc3NCb3Vu
ZGFyeVBvbGljeRI9Lmdvb2dsZS5pYW0udjNiZXRhLkRlbGV0ZVByaW5jaXBhbEFjY2Vzc0Jv
dW5kYXJ5UG9saWN5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iiAGC
0+STAk4qTC92M2JldGEve25hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL3ByaW5j
aXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9i
dWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEoMCCiNMaXN0UHJpbmNpcGFsQWNjZXNzQm91
bmRhcnlQb2xpY2llcxI9Lmdvb2dsZS5pYW0udjNiZXRhLkxpc3RQcmluY2lwYWxBY2Nlc3NC
b3VuZGFyeVBvbGljaWVzUmVxdWVzdBo+Lmdvb2dsZS5pYW0udjNiZXRhLkxpc3RQcmluY2lw
YWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzUmVzcG9uc2UiXYLT5JMCThJML3YzYmV0YS97cGFy
ZW50PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKn0vcHJpbmNpcGFsQWNjZXNzQm91bmRh
cnlQb2xpY2llc9pBBnBhcmVudBKuAgorU2VhcmNoUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQ
b2xpY3lCaW5kaW5ncxJFLmdvb2dsZS5pYW0udjNiZXRhLlNlYXJjaFByaW5jaXBhbEFjY2Vz
c0JvdW5kYXJ5UG9saWN5QmluZGluZ3NSZXF1ZXN0GkYuZ29vZ2xlLmlhbS52M2JldGEuU2Vh
cmNoUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lCaW5kaW5nc1Jlc3BvbnNlInCC0+ST
AmMSYS92M2JldGEve25hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL3ByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMvKn06c2VhcmNoUG9saWN5QmluZGluZ3PaQQRuYW1l
GkbKQRJpYW0uZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Nsb3VkLXBsYXRmb3JtQqkBChVjb20uZ29vZ2xlLmlhbS52M2JldGFCK1ByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXNTZXJ2aWNlUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNv
bS9nby9pYW0vYXBpdjNiZXRhL2lhbXBiO2lhbXBiqgIXR29vZ2xlLkNsb3VkLklhbS5WM0Jl
dGHKAhdHb29nbGVcQ2xvdWRcSWFtXFYzYmV0YUq9RAoHEgUOAKMCAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAGgoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADQKCQoCAwUSAxcAOgoJCgIDBhIDGABM
CgkKAgMHEgMZAC0KCQoCAwgSAxoAJQoJCgIDCRIDGwAqCggKAQgSAx0ANAoJCgIIJRIDHQA0
CggKAQgSAx4ARAoJCgIICxIDHgBECggKAQgSAx8AIgoJCgIIChIDHwAiCggKAQgSAyAATAoJ
CgIICBIDIABMCggKAQgSAyEALgoJCgIIARIDIQAuCggKAQgSAyIANAoJCgIIKRIDIgA0Cl8K
AgYAEgQmAHcBGlMgTWFuYWdlcyBJZGVudGl0eSBhbmQgQWNjZXNzIE1hbmFnZW1lbnQgKElB
TSkgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeQogcG9saWNpZXMuCgoKCgMGAAESAyYIJwoK
CgMGAAMSAycCOgoMCgUGAAOZCBIDJwI6CgsKAwYAAxIEKAIpNwoNCgUGAAOaCBIEKAIpNwpi
CgQGAAIAEgQtAjoDGlQgQ3JlYXRlcyBhIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9s
aWN5LCBhbmQgcmV0dXJucyBhIGxvbmcgcnVubmluZwogb3BlcmF0aW9uLgoKDAoFBgACAAES
Ay0GKQoMCgUGAAIAAhIDLgYwCgwKBQYAAgADEgMvDysKDQoFBgACAAQSBDAEMwYKEQoJBgAC
AASwyrwiEgQwBDMGCg0KBQYAAgAEEgQ0BDVWChAKCAYAAgAEmwgAEgQ0BDVWCg0KBQYAAgAE
EgQ2BDkGCg8KBwYAAgAEmQgSBDYEOQYKOAoEBgACARIEPQJDAxoqIEdldHMgYSBwcmluY2lw
YWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeS4KCgwKBQYAAgEBEgM9BiYKDAoFBgACAQISAz0n
TgoMCgUGAAIBAxIDPg8sCg0KBQYAAgEEEgQ/BEEGChEKCQYAAgEEsMq8IhIEPwRBBgoMCgUG
AAIBBBIDQgQyCg8KCAYAAgEEmwgAEgNCBDIKOwoEBgACAhIERgJTAxotIFVwZGF0ZXMgYSBw
cmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeS4KCgwKBQYAAgIBEgNGBikKDAoFBgAC
AgISA0cGMAoMCgUGAAICAxIDSA8rCg0KBQYAAgIEEgRJBEwGChEKCQYAAgIEsMq8IhIESQRM
BgoNCgUGAAICBBIETQRONwoQCggGAAICBJsIABIETQRONwoNCgUGAAICBBIETwRSBgoPCgcG
AAICBJkIEgRPBFIGCjsKBAYAAgMSBFYCYQMaLSBEZWxldGVzIGEgcHJpbmNpcGFsIGFjY2Vz
cyBib3VuZGFyeSBwb2xpY3kuCgoMCgUGAAIDARIDVgYpCgwKBQYAAgMCEgNXBjAKDAoFBgAC
AwMSA1gPKwoNCgUGAAIDBBIEWQRbBgoRCgkGAAIDBLDKvCISBFkEWwYKDAoFBgACAwQSA1wE
MgoPCggGAAIDBJsIABIDXAQyCg0KBQYAAgMEEgRdBGAGCg8KBwYAAgMEmQgSBF0EYAYKOQoE
BgACBBIEZAJrAxorIExpc3RzIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWNpZXMu
CgoMCgUGAAIEARIDZAYpCgwKBQYAAgQCEgNlBjAKDAoFBgACBAMSA2YPOgoNCgUGAAIEBBIE
ZwRpBgoRCgkGAAIEBLDKvCISBGcEaQYKDAoFBgACBAQSA2oENAoPCggGAAIEBJsIABIDagQ0
CoYBCgQGAAIFEgRvAnYDGnggUmV0dXJucyBhbGwgcG9saWN5IGJpbmRpbmdzIHRoYXQgYmlu
ZCBhIHNwZWNpZmljIHBvbGljeSBpZiBhIHVzZXIgaGFzCiBzZWFyY2hQb2xpY3lCaW5kaW5n
cyBwZXJtaXNzaW9uIG9uIHRoYXQgcG9saWN5LgoKDAoFBgACBQESA28GMQoMCgUGAAIFAhID
cAY4CgwKBQYAAgUDEgNxD0IKDQoFBgACBQQSBHIEdAYKEQoJBgACBQSwyrwiEgRyBHQGCgwK
BQYAAgUEEgN1BDIKDwoIBgACBQSbCAASA3UEMgpVCgIEABIFegCYAQEaSCBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIENyZWF0ZVByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UmVxdWVzdCBt
ZXRob2QuCgoKCgMEAAESA3oIMgrUAQoEBAACABIGgAEChQEEGsMBIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIHdoZXJlIHRoaXMgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBw
b2xpY3kKIHdpbGwgYmUgY3JlYXRlZC4gT25seSBvcmdhbml6YXRpb25zIGFyZSBzdXBwb3J0
ZWQuCgogRm9ybWF0OgogICBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufWAKCg0KBQQAAgAFEgSAAQIICg0KBQQAAgABEgSAAQkPCg0KBQQA
AgADEgSAARITCg8KBQQAAgAIEgaAARSFAQMKEAoIBAACAAicCAASBIEBBCoKEQoHBAACAAif
CBIGggEEhAEFCs0CCgQEAAIBEgaOAQKPAS8avAIgUmVxdWlyZWQuIFRoZSBJRCB0byB1c2Ug
Zm9yIHRoZSBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeSwgd2hpY2gKIHdpbGwg
YmVjb21lIHRoZSBmaW5hbCBjb21wb25lbnQgb2YgdGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91
bmRhcnkgcG9saWN5J3MKIHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBtdXN0IHN0YXJ0
IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIGZvbGxvd2VkIGJ5IHVwIHRvIDYyCiBsb3dlcmNh
c2UgbGV0dGVycywgbnVtYmVycywgaHlwaGVucywgb3IgZG90cy4gUGF0dGVybiwKIC9bYS16
XVthLXowLTktXC5dezIsNjJ9Ly4KCg0KBQQAAgEFEgSOAQIICg0KBQQAAgEBEgSOAQksCg0K
BQQAAgEDEgSOAS8wCg0KBQQAAgEIEgSPAQYuChAKCAQAAgEInAgAEgSPAQctCksKBAQAAgIS
BpIBApMBLxo7IFJlcXVpcmVkLiBUaGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xp
Y3kgdG8gY3JlYXRlLgoKDQoFBAACAgYSBJIBAh8KDQoFBAACAgESBJIBIEAKDQoFBAACAgMS
BJIBQ0QKDQoFBAACAggSBJMBBi4KEAoIBAACAgicCAASBJMBBy0KbgoEBAACAxIElwECQhpg
IE9wdGlvbmFsLiBJZiBzZXQsIHZhbGlkYXRlIHRoZSByZXF1ZXN0IGFuZCBwcmV2aWV3IHRo
ZSBjcmVhdGlvbiwgYnV0IGRvIG5vdAogYWN0dWFsbHkgcG9zdCBpdC4KCg0KBQQAAgMFEgSX
AQIGCg0KBQQAAgMBEgSXAQcUCg0KBQQAAgMDEgSXARcYCg0KBQQAAgMIEgSXARlBChAKCAQA
AgMInAgAEgSXARpACkwKAgQBEgabAQCmAQEaPiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEdldFBy
aW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5IG1ldGhvZC4KCgsKAwQBARIEmwEILwrkAQoE
BAECABIGoAECpQEEGtMBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcHJpbmNpcGFsIGFj
Y2VzcyBib3VuZGFyeSBwb2xpY3kgdG8gcmV0cmlldmUuCgogRm9ybWF0OgogICBgb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wcmluY2lw
YWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzL3twcmluY2lwYWxfYWNjZXNzX2JvdW5kYXJ5X3Bv
bGljeV9pZH1gCgoNCgUEAQIABRIEoAECCAoNCgUEAQIAARIEoAEJDQoNCgUEAQIAAxIEoAEQ
EQoPCgUEAQIACBIGoAESpQEDChAKCAQBAgAInAgAEgShAQQqChEKBwQBAgAInwgSBqIBBKQB
BQpPCgIEAhIGqQEAuAEBGkEgUmVxdWVzdCBtZXNzYWdlIGZvciBVcGRhdGVQcmluY2lwYWxB
Y2Nlc3NCb3VuZGFyeVBvbGljeSBtZXRob2QuCgoLCgMEAgESBKkBCDIKrQEKBAQCAgASBq4B
Aq8BLxqcASBSZXF1aXJlZC4gVGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5
IHRvIHVwZGF0ZS4KCiBUaGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3kncyBg
bmFtZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUKIHBvbGljeSB0byB1cGRhdGUu
CgoNCgUEAgIABhIErgECHwoNCgUEAgIAARIErgEgQAoNCgUEAgIAAxIErgFDRAoNCgUEAgIA
CBIErwEGLgoQCggEAgIACJwIABIErwEHLQpsCgQEAgIBEgSzAQJCGl4gT3B0aW9uYWwuIElm
IHNldCwgdmFsaWRhdGUgdGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIHVwZGF0ZSwgYnV0
IGRvIG5vdAogYWN0dWFsbHkgcG9zdCBpdC4KCg0KBQQCAgEFEgSzAQIGCg0KBQQCAgEBEgSz
AQcUCg0KBQQCAgEDEgSzARcYCg0KBQQCAgEIEgSzARlBChAKCAQCAgEInAgAEgSzARpACjgK
BAQCAgISBrYBArcBLxooIE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRl
CgoNCgUEAgICBhIEtgECGwoNCgUEAgICARIEtgEcJwoNCgUEAgICAxIEtgEqKwoNCgUEAgIC
CBIEtwEGLgoQCggEAgICCJwIABIEtwEHLQpPCgIEAxIGuwEA0gEBGkEgUmVxdWVzdCBtZXNz
YWdlIGZvciBEZWxldGVQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeSBtZXRob2QuCgoL
CgMEAwESBLsBCDIK4gEKBAQDAgASBsABAsUBBBrRASBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5IHRvIGRlbGV0ZS4KCiBGb3Jt
YXQ6CiAgIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9j
YXRpb259L3ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMve3ByaW5jaXBhbF9hY2Nl
c3NfYm91bmRhcnlfcG9saWN5X2lkfWAKCg0KBQQDAgAFEgTAAQIICg0KBQQDAgABEgTAAQkN
Cg0KBQQDAgADEgTAARARCg8KBQQDAgAIEgbAARLFAQMKEAoIBAMCAAicCAASBMEBBCoKEQoH
BAMCAAifCBIGwgEExAEFCoIBCgQEAwIBEgTJAQI7GnQgT3B0aW9uYWwuIFRoZSBldGFnIG9m
IHRoZSBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeS4KIElmIHRoaXMgaXMgcHJv
dmlkZWQsIGl0IG11c3QgbWF0Y2ggdGhlIHNlcnZlcidzIGV0YWcuCgoNCgUEAwIBBRIEyQEC
CAoNCgUEAwIBARIEyQEJDQoNCgUEAwIBAxIEyQEQEQoNCgUEAwIBCBIEyQESOgoQCggEAwIB
CJwIABIEyQETOQpuCgQEAwICEgTNAQJCGmAgT3B0aW9uYWwuIElmIHNldCwgdmFsaWRhdGUg
dGhlIHJlcXVlc3QgYW5kIHByZXZpZXcgdGhlIGRlbGV0aW9uLCBidXQgZG8gbm90CiBhY3R1
YWxseSBwb3N0IGl0LgoKDQoFBAMCAgUSBM0BAgYKDQoFBAMCAgESBM0BBxQKDQoFBAMCAgMS
BM0BFxgKDQoFBAMCAggSBM0BGUEKEAoIBAMCAgicCAASBM0BGkAKkgEKBAQDAgMSBNEBAjoa
gwEgT3B0aW9uYWwuIElmIHNldCB0byB0cnVlLCB0aGUgcmVxdWVzdCB3aWxsIGZvcmNlIHRo
ZSBkZWxldGlvbiBvZiB0aGUgcG9saWN5CiBldmVuIGlmIHRoZSBwb2xpY3kgaXMgcmVmZXJl
bmNlZCBpbiBwb2xpY3kgYmluZGluZ3MuCgoNCgUEAwIDBRIE0QECBgoNCgUEAwIDARIE0QEH
DAoNCgUEAwIDAxIE0QEPEAoNCgUEAwIDCBIE0QEROQoQCggEAwIDCJwIABIE0QESOApPCgIE
BBIG1QEA8gEBGkEgUmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0UHJpbmNpcGFsQWNjZXNzQm91
bmRhcnlQb2xpY2llcyBtZXRob2QuCgoLCgMEBAESBNUBCDIKtwEKBAQEAgASBtsBAuABBBqm
ASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSwgd2hpY2ggb3ducyB0aGUgY29sbGVj
dGlvbiBvZiBwcmluY2lwYWwKIGFjY2VzcyBib3VuZGFyeSBwb2xpY2llcy4KCiBGb3JtYXQ6
CiAgIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9jYXRp
b259YAoKDQoFBAQCAAUSBNsBAggKDQoFBAQCAAESBNsBCQ8KDQoFBAQCAAMSBNsBEhMKDwoF
BAQCAAgSBtsBFOABAwoQCggEBAIACJwIABIE3AEEKgoRCgcEBAIACJ8IEgbdAQTfAQUKpwIK
BAQEAgESBOgBAj8amAIgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBwcmluY2lw
YWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljaWVzIHRvCiByZXR1cm4uIFRoZSBzZXJ2aWNlIG1h
eSByZXR1cm4gZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLgoKIElmIHVuc3BlY2lmaWVkLCBhdCBt
b3N0IDUwIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWNpZXMgd2lsbCBiZQogcmV0
dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdp
bGwgYmUgY29lcmNlZCB0bwogMTAwMC4KCg0KBQQEAgEFEgToAQIHCg0KBQQEAgEBEgToAQgR
Cg0KBQQEAgEDEgToARQVCg0KBQQEAgEIEgToARY+ChAKCAQEAgEInAgAEgToARc9CqsCCgQE
BAICEgTxAQJBGpwCIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBw
cmV2aW91cwogYExpc3RQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzYCBjYWxsLiBQ
cm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlCiBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBw
YWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogYExpc3RQcmlu
Y2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQg
cHJvdmlkZWQgdGhlCiBwYWdlIHRva2VuLgoKDQoFBAQCAgUSBPEBAggKDQoFBAQCAgESBPEB
CRMKDQoFBAQCAgMSBPEBFhcKDQoFBAQCAggSBPEBGEAKEAoIBAQCAgicCAASBPEBGT8KUAoC
BAUSBvUBAPwBARpCIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExpc3RQcmluY2lwYWxBY2Nlc3NC
b3VuZGFyeVBvbGljaWVzIG1ldGhvZC4KCgsKAwQFARIE9QEIMwpRCgQEBQIAEgT3AQJQGkMg
VGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWNpZXMgZnJvbSB0aGUgc3BlY2lm
aWVkIHBhcmVudC4KCg0KBQQFAgAEEgT3AQIKCg0KBQQFAgAGEgT3AQsoCg0KBQQFAgABEgT3
ASlLCg0KBQQFAgADEgT3AU5PCpoBCgQEBQIBEgT7AQJGGosBIE9wdGlvbmFsLiBBIHRva2Vu
LCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5l
eHQKIHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNl
cXVlbnQgcGFnZXMuCgoNCgUEBQIBBRIE+wECCAoNCgUEBQIBARIE+wEJGAoNCgUEBQIBAxIE
+wEbHAoNCgUEBQIBCBIE+wEdRQoQCggEBQIBCJwIABIE+wEeRApUCgIEBhIG/wEAmQIBGkYg
UmVxdWVzdCBtZXNzYWdlIGZvciBTZWFyY2hQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGlj
eUJpbmRpbmdzIHJwYy4KCgsKAwQGARIE/wEIOgrWAQoEBAYCABIGgwICiAIEGsUBIFJlcXVp
cmVkLiBUaGUgbmFtZSBvZiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3ku
CiBGb3JtYXQ6CiAgYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llcy97cHJpbmNpcGFs
X2FjY2Vzc19ib3VuZGFyeV9wb2xpY3lfaWR9YAoKDQoFBAYCAAUSBIMCAggKDQoFBAYCAAES
BIMCCQ0KDQoFBAYCAAMSBIMCEBEKDwoFBAYCAAgSBoMCEogCAwoQCggEBgIACJwIABIEhAIE
KgoRCgcEBgIACJ8IEgaFAgSHAgUKgAIKBAQGAgESBI8CAj8a8QEgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBwb2xpY3kgYmluZGluZ3MgdG8gcmV0dXJuLiBUaGUgc2Vydmlj
ZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCgogSWYgdW5zcGVjaWZpZWQs
IGF0IG1vc3QgNTAgcG9saWN5IGJpbmRpbmdzIHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUgbWF4
aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQg
dG8gMTAwMC4KCg0KBQQGAgEFEgSPAgIHCg0KBQQGAgEBEgSPAggRCg0KBQQGAgEDEgSPAhQV
Cg0KBQQGAgEIEgSPAhY+ChAKCAQGAgEInAgAEgSPAhc9CskCCgQEBgICEgSYAgJBGroCIE9w
dGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogYFNlYXJj
aFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5QmluZGluZ3NSZXF1ZXN0YCBjYWxsLiBQ
cm92aWRlIHRoaXMgdG8KIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBw
YWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogYFNlYXJjaFBy
aW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5QmluZGluZ3NSZXF1ZXN0YCBtdXN0IG1hdGNo
IHRoZSBjYWxsCiB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAYCAgUSBJgC
AggKDQoFBAYCAgESBJgCCRMKDQoFBAYCAgMSBJgCFhcKDQoFBAYCAggSBJgCGEAKEAoIBAYC
AgicCAASBJgCGT8KVQoCBAcSBpwCAKMCARpHIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFNlYXJj
aFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5QmluZGluZ3MgcnBjLgoKCwoDBAcBEgSc
Agg7CkgKBAQHAgASBJ4CAi0aOiBUaGUgcG9saWN5IGJpbmRpbmdzIHRoYXQgcmVmZXJlbmNl
IHRoZSBzcGVjaWZpZWQgcG9saWN5LgoKDQoFBAcCAAQSBJ4CAgoKDQoFBAcCAAYSBJ4CCxgK
DQoFBAcCAAESBJ4CGSgKDQoFBAcCAAMSBJ4CKywKmgEKBAQHAgESBKICAkYaiwEgT3B0aW9u
YWwuIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRy
aWV2ZSB0aGUgbmV4dAogcGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBh
cmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQHAgEFEgSiAgIICg0KBQQHAgEBEgSiAgkY
Cg0KBQQHAgEDEgSiAhscCg0KBQQHAgEIEgSiAh1FChAKCAQHAgEInAgAEgSiAh5EYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest ===
    # Fields for CreatePrincipalAccessBoundaryPolicyRequest
    # Field: parent Type: 9 ()
    # Field: principal_access_boundary_policy_id Type: 9 ()
    # Field: principal_access_boundary_policy Type: 11 (.google.iam.v3beta.PrincipalAccessBoundaryPolicy)
    # Field: validate_only Type: 8 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest ===
    # Fields for GetPrincipalAccessBoundaryPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest ===
    # Fields for UpdatePrincipalAccessBoundaryPolicyRequest
    # Field: principal_access_boundary_policy Type: 11 (.google.iam.v3beta.PrincipalAccessBoundaryPolicy)
    # Field: validate_only Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest ===
    # Fields for DeletePrincipalAccessBoundaryPolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: force Type: 8 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest ===
    # Fields for ListPrincipalAccessBoundaryPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse ===
    # Fields for ListPrincipalAccessBoundaryPoliciesResponse
    # Field: principal_access_boundary_policies Type: 11 (.google.iam.v3beta.PrincipalAccessBoundaryPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest ===
    # Fields for SearchPrincipalAccessBoundaryPolicyBindingsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse ===
    # Fields for SearchPrincipalAccessBoundaryPolicyBindingsResponse
    # Field: policy_bindings Type: 11 (.google.iam.v3beta.PolicyBinding)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::PrincipalAccessBoundaryPoliciesClient ===
package Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::PrincipalAccessBoundaryPoliciesClient;

=pod

=head2 Service Client: Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::PrincipalAccessBoundaryPoliciesClient

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
        ? Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PrincipalAccessBoundaryPolicies',
        method         => 'CreatePrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PrincipalAccessBoundaryPolicies',
        method         => 'GetPrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy',
    });
}

sub update_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PrincipalAccessBoundaryPolicies',
        method         => 'UpdatePrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_principal_access_boundary_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PrincipalAccessBoundaryPolicies',
        method         => 'DeletePrincipalAccessBoundaryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_principal_access_boundary_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PrincipalAccessBoundaryPolicies',
        method         => 'ListPrincipalAccessBoundaryPolicies',
        request        => $req,
        response_class => 'Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse',
    });
}

sub search_principal_access_boundary_policy_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v3beta.PrincipalAccessBoundaryPolicies',
        method         => 'SearchPrincipalAccessBoundaryPolicyBindings',
        request        => $req,
        response_class => 'Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService - Compiled Protocol Buffers messages for google/iam/v3beta/principal_access_boundary_policies_service.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService;

    my $msg = Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest->new({
        parent => $parent,
        principal_access_boundary_policy_id => $principal_access_boundary_policy_id,
        principal_access_boundary_policy => $principal_access_boundary_policy,
        validate_only => $validate_only,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/principal_access_boundary_policies_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest

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

Type: C<Message> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy>)

Required. The principal access boundary policy to create.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validate the request and preview the creation, but do not
actually post it.

=back

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest

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

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest

Request message for UpdatePrincipalAccessBoundaryPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal_access_boundary_policy() >> / C<< $msg->principal_access_boundary_policy($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy>)

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

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest

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

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest

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

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse

Response message for ListPrincipalAccessBoundaryPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal_access_boundary_policies() >> / C<< $msg->principal_access_boundary_policies($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy>)

The principal access boundary policies from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest

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

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse

Response message for SearchPrincipalAccessBoundaryPolicyBindings rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_bindings() >> / C<< $msg->policy_bindings($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PolicyBindingResources::PolicyBinding>)

The policy bindings that reference the specified policy.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::PrincipalAccessBoundaryPoliciesService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
