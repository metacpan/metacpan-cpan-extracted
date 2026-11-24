package Google::Devtools::Artifactregistry::V1::Artifact;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9hcnRpZmFjdC5wcm90bxIj
Z29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8i7gQKC0RvY2tlckltYWdlEhcKBG5hbWUYASABKAlCA+BB
AlIEbmFtZRIVCgN1cmkYAiABKAlCA+BBAlIDdXJpEhIKBHRhZ3MYAyADKAlSBHRhZ3MSKAoQ
aW1hZ2Vfc2l6ZV9ieXRlcxgEIAEoA1IOaW1hZ2VTaXplQnl0ZXMSOwoLdXBsb2FkX3RpbWUY
BSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGxvYWRUaW1lEh0KCm1lZGlh
X3R5cGUYBiABKAlSCW1lZGlhVHlwZRI5CgpidWlsZF90aW1lGAcgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIJYnVpbGRUaW1lEkAKC3VwZGF0ZV90aW1lGAggASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEiMKDWFydGlmYWN0X3R5
cGUYCSABKAlSDGFydGlmYWN0VHlwZRJgCg9pbWFnZV9tYW5pZmVzdHMYCyADKAsyMi5nb29n
bGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5JbWFnZU1hbmlmZXN0QgPgQQFSDmlt
YWdlTWFuaWZlc3RzOpAB6kGMAQorYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9E
b2NrZXJJbWFnZRJdcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
cG9zaXRvcmllcy97cmVwb3NpdG9yeX0vZG9ja2VySW1hZ2VzL3tkb2NrZXJfaW1hZ2V9IvcB
Cg1JbWFnZU1hbmlmZXN0EicKDGFyY2hpdGVjdHVyZRgBIAEoCUID4EEBUgxhcmNoaXRlY3R1
cmUSEwoCb3MYAiABKAlCA+BBAVICb3MSGwoGZGlnZXN0GAMgASgJQgPgQQFSBmRpZ2VzdBIi
CgptZWRpYV90eXBlGAQgASgJQgPgQQFSCW1lZGlhVHlwZRIiCgpvc192ZXJzaW9uGAUgASgJ
QgPgQQFSCW9zVmVyc2lvbhIkCgtvc19mZWF0dXJlcxgGIAMoCUID4EEBUgpvc0ZlYXR1cmVz
Eh0KB3ZhcmlhbnQYByABKAlCA+BBAVIHdmFyaWFudCKNAQoXTGlzdERvY2tlckltYWdlc1Jl
cXVlc3QSGwoGcGFyZW50GAEgASgJQgPgQQJSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVS
CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIZCghvcmRlcl9ieRgE
IAEoCVIHb3JkZXJCeSKZAQoYTGlzdERvY2tlckltYWdlc1Jlc3BvbnNlElUKDWRvY2tlcl9p
bWFnZXMYASADKAsyMC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5Eb2Nr
ZXJJbWFnZVIMZG9ja2VySW1hZ2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbiJgChVHZXREb2NrZXJJbWFnZVJlcXVlc3QSRwoEbmFtZRgBIAEoCUIz4EEC+kEt
CithcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL0RvY2tlckltYWdlUgRuYW1lIrkD
Cg1NYXZlbkFydGlmYWN0EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIcCgdwb21fdXJpGAIg
ASgJQgPgQQJSBnBvbVVyaRIZCghncm91cF9pZBgDIAEoCVIHZ3JvdXBJZBIfCgthcnRpZmFj
dF9pZBgEIAEoCVIKYXJ0aWZhY3RJZBIYCgd2ZXJzaW9uGAUgASgJUgd2ZXJzaW9uEkAKC2Ny
ZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEkAKC3VwZGF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lOpYB6kGSAQotYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlz
LmNvbS9NYXZlbkFydGlmYWN0EmFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBvc2l0b3J5fS9tYXZlbkFydGlmYWN0cy97bWF2ZW5f
YXJ0aWZhY3R9IqYBChlMaXN0TWF2ZW5BcnRpZmFjdHNSZXF1ZXN0Ek0KBnBhcmVudBgBIAEo
CUI14EEC+kEvEi1hcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL01hdmVuQXJ0aWZh
Y3RSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
AyABKAlSCXBhZ2VUb2tlbiKhAQoaTGlzdE1hdmVuQXJ0aWZhY3RzUmVzcG9uc2USWwoPbWF2
ZW5fYXJ0aWZhY3RzGAEgAygLMjIuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnku
djEuTWF2ZW5BcnRpZmFjdFIObWF2ZW5BcnRpZmFjdHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJUg1uZXh0UGFnZVRva2VuImQKF0dldE1hdmVuQXJ0aWZhY3RSZXF1ZXN0EkkKBG5hbWUY
ASABKAlCNeBBAvpBLwotYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9NYXZlbkFy
dGlmYWN0UgRuYW1lIooDCgpOcG1QYWNrYWdlEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIh
CgxwYWNrYWdlX25hbWUYAyABKAlSC3BhY2thZ2VOYW1lEhgKB3ZlcnNpb24YBCABKAlSB3Zl
cnNpb24SEgoEdGFncxgFIAMoCVIEdGFncxJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgH
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZTqNAepB
iQEKKmFydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vTnBtUGFja2FnZRJbcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmllcy97cmVwb3Np
dG9yeX0vbnBtUGFja2FnZXMve25wbV9wYWNrYWdlfSKgAQoWTGlzdE5wbVBhY2thZ2VzUmVx
dWVzdBJKCgZwYXJlbnQYASABKAlCMuBBAvpBLBIqYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVh
cGlzLmNvbS9OcG1QYWNrYWdlUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6
ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4ilQEKF0xpc3ROcG1QYWNrYWdlc1Jl
c3BvbnNlElIKDG5wbV9wYWNrYWdlcxgBIAMoCzIvLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFj
dHJlZ2lzdHJ5LnYxLk5wbVBhY2thZ2VSC25wbVBhY2thZ2VzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJeChRHZXROcG1QYWNrYWdlUmVxdWVzdBJGCgRuYW1l
GAEgASgJQjLgQQL6QSwKKmFydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vTnBtUGFj
a2FnZVIEbmFtZSKZAwoNUHl0aG9uUGFja2FnZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUS
FQoDdXJpGAIgASgJQgPgQQJSA3VyaRIhCgxwYWNrYWdlX25hbWUYAyABKAlSC3BhY2thZ2VO
YW1lEhgKB3ZlcnNpb24YBCABKAlSB3ZlcnNpb24SQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWU6
lgHqQZIBCi1hcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1B5dGhvblBhY2thZ2US
YXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXBvc2l0b3JpZXMv
e3JlcG9zaXRvcnl9L3B5dGhvblBhY2thZ2VzL3tweXRob25fcGFja2FnZX0ipgEKGUxpc3RQ
eXRob25QYWNrYWdlc1JlcXVlc3QSTQoGcGFyZW50GAEgASgJQjXgQQL6QS8SLWFydGlmYWN0
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vUHl0aG9uUGFja2FnZVIGcGFyZW50EhsKCXBhZ2Vf
c2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIqEB
ChpMaXN0UHl0aG9uUGFja2FnZXNSZXNwb25zZRJbCg9weXRob25fcGFja2FnZXMYASADKAsy
Mi5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5QeXRob25QYWNrYWdlUg5w
eXRob25QYWNrYWdlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i
ZAoXR2V0UHl0aG9uUGFja2FnZVJlcXVlc3QSSQoEbmFtZRgBIAEoCUI14EEC+kEvCi1hcnRp
ZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1B5dGhvblBhY2thZ2VSBG5hbWVC+AEKJ2Nv
bS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MUINQXJ0aWZhY3RQcm90b1AB
WlBjbG91ZC5nb29nbGUuY29tL2dvL2FydGlmYWN0cmVnaXN0cnkvYXBpdjEvYXJ0aWZhY3Ry
ZWdpc3RyeXBiO2FydGlmYWN0cmVnaXN0cnlwYqoCIEdvb2dsZS5DbG91ZC5BcnRpZmFjdFJl
Z2lzdHJ5LlYxygIgR29vZ2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlcVjHqAiNHb29nbGU6
OkNsb3VkOjpBcnRpZmFjdFJlZ2lzdHJ5OjpWMUq0agoHEgUOAI4DAQq8BAoBDBIDDgASMrEE
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
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQAKQoICgEIEgMWAD0KCQoCCCUSAxYAPQoICgEIEgMXAGcKCQoCCAsSAxcAZwoI
CgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC4KCQoCCAgSAxkALgoICgEIEgMaAEAKCQoC
CAESAxoAQAoICgEIEgMbAD0KCQoCCCkSAxsAPQoICgEIEgMcADwKCQoCCC0SAxwAPArqAQoC
BAASBCQAYQEa3QEgRG9ja2VySW1hZ2UgcmVwcmVzZW50cyBhIGRvY2tlciBhcnRpZmFjdC4K
IFRoZSBmb2xsb3dpbmcgZmllbGRzIGFyZSByZXR1cm5lZCBhcyB1bnR5cGVkIG1ldGFkYXRh
IGluIHRoZSBWZXJzaW9uCiByZXNvdXJjZSwgdXNpbmcgY2FtZWxjYXNlIGtleXMgKGkuZS4g
bWV0YWRhdGEuaW1hZ2VTaXplQnl0ZXMpOgogKiBpbWFnZVNpemVCeXRlcwogKiBtZWRpYVR5
cGUKICogYnVpbGRUaW1lCgoKCgMEAAESAyQIEwoLCgMEAAcSBCUCKAQKDQoFBAAHnQgSBCUC
KAQK6AQKBAQAAgASAzQCOxraBCBSZXF1aXJlZC4gcmVnaXN0cnlfbG9jYXRpb24sIHByb2pl
Y3RfaWQsIHJlcG9zaXRvcnlfbmFtZSBhbmQgaW1hZ2UgaWQgZm9ybXMKIGEgdW5pcXVlIGlt
YWdlCiBuYW1lOmBwcm9qZWN0cy88cHJvamVjdF9pZD4vbG9jYXRpb25zLzxsb2NhdGlvbj4v
cmVwb3NpdG9yaWVzLzxyZXBvc2l0b3J5X25hbWU+L2RvY2tlckltYWdlcy88ZG9ja2VyX2lt
YWdlPmAuCiBGb3IgZXhhbXBsZSwKICJwcm9qZWN0cy90ZXN0LXByb2plY3QvbG9jYXRpb25z
L3VzLXdlc3Q0L3JlcG9zaXRvcmllcy90ZXN0LXJlcG8vZG9ja2VySW1hZ2VzLwogbmdpbnhA
c2hhMjU2OmU5OTU0YzFmYzg3NTAxN2JlMWMzZTM2ZWNhMTZiZTJkOWU5YmNjYzRiZjA3MjE2
MzUxNTQ2N2Q2YTgyM2M3Y2YiLAogd2hlcmUgInVzLXdlc3Q0IiBpcyB0aGUgcmVnaXN0cnlf
bG9jYXRpb24sICJ0ZXN0LXByb2plY3QiIGlzIHRoZQogcHJvamVjdF9pZCwgInRlc3QtcmVw
byIgaXMgdGhlIHJlcG9zaXRvcnlfbmFtZSBhbmQKICJuZ2lueEBzaGEyNTY6ZTk5NTRjMWZj
ODc1MDE3YmUxYzNlMzZlY2ExNmJlMmQ5ZTliY2NjNGJmMDcyMTYzNTE1NDY3ZDZhODIzYzdj
ZiIKIGlzIHRoZSBpbWFnZSdzIGRpZ2VzdC4KCgwKBQQAAgAFEgM0AggKDAoFBAACAAESAzQJ
DQoMCgUEAAIAAxIDNBARCgwKBQQAAgAIEgM0EjoKDwoIBAACAAicCAASAzQTOQq6AQoEBAAC
ARIDOQI6GqwBIFJlcXVpcmVkLiBVUkwgdG8gYWNjZXNzIHRoZSBpbWFnZS4KIEV4YW1wbGU6
CiB1cy13ZXN0NC1kb2NrZXIucGtnLmRldi90ZXN0LXByb2plY3QvdGVzdC1yZXBvL25naW54
QHNoYTI1NjplOTk1NGMxZmM4NzUwMTdiZTFjM2UzNmVjYTE2YmUyZDllOWJjY2M0YmYwNzIx
NjM1MTU0NjdkNmE4MjNjN2NmCgoMCgUEAAIBBRIDOQIICgwKBQQAAgEBEgM5CQwKDAoFBAAC
AQMSAzkPEAoMCgUEAAIBCBIDORE5Cg8KCAQAAgEInAgAEgM5EjgKKwoEBAACAhIDPAIbGh4g
VGFncyBhdHRhY2hlZCB0byB0aGlzIGltYWdlLgoKDAoFBAACAgQSAzwCCgoMCgUEAAICBRID
PAsRCgwKBQQAAgIBEgM8EhYKDAoFBAACAgMSAzwZGgqFAQoEBAACAxIDQQIdGnggQ2FsY3Vs
YXRlZCBzaXplIG9mIHRoZSBpbWFnZS4KIFRoaXMgZmllbGQgaXMgcmV0dXJuZWQgYXMgdGhl
ICdtZXRhZGF0YS5pbWFnZVNpemVCeXRlcycgZmllbGQgaW4gdGhlCiBWZXJzaW9uIHJlc291
cmNlLgoKDAoFBAACAwUSA0ECBwoMCgUEAAIDARIDQQgYCgwKBQQAAgMDEgNBGxwKKwoEBAAC
BBIDRAIsGh4gVGltZSB0aGUgaW1hZ2Ugd2FzIHVwbG9hZGVkLgoKDAoFBAACBAYSA0QCGwoM
CgUEAAIEARIDRBwnCgwKBQQAAgQDEgNEKisKuwEKBAQAAgUSA0oCGBqtASBNZWRpYSB0eXBl
IG9mIHRoaXMgaW1hZ2UsIGUuZy4KICJhcHBsaWNhdGlvbi92bmQuZG9ja2VyLmRpc3RyaWJ1
dGlvbi5tYW5pZmVzdC52Mitqc29uIi4KIFRoaXMgZmllbGQgaXMgcmV0dXJuZWQgYXMgdGhl
ICdtZXRhZGF0YS5tZWRpYVR5cGUnIGZpZWxkIGluIHRoZQogVmVyc2lvbiByZXNvdXJjZS4K
CgwKBQQAAgUFEgNKAggKDAoFBAACBQESA0oJEwoMCgUEAAIFAxIDShYXCoMCCgQEAAIGEgNR
Aisa9QEgVGhlIHRpbWUgdGhpcyBpbWFnZSB3YXMgYnVpbHQuCiBUaGlzIGZpZWxkIGlzIHJl
dHVybmVkIGFzIHRoZSAnbWV0YWRhdGEuYnVpbGRUaW1lJyBmaWVsZCBpbiB0aGUKIFZlcnNp
b24gcmVzb3VyY2UuCiBUaGUgYnVpbGQgdGltZSBpcyByZXR1cm5lZCB0byB0aGUgY2xpZW50
IGFzIGFuIFJGQyAzMzM5IHN0cmluZywgd2hpY2ggY2FuCiBiZSBlYXNpbHkgdXNlZCB3aXRo
IHRoZSBKYXZhU2NyaXB0IERhdGUgY29uc3RydWN0b3IuCgoMCgUEAAIGBhIDUQIbCgwKBQQA
AgYBEgNRHCYKDAoFBAACBgMSA1EpKgpNCgQEAAIHEgRUAlUyGj8gT3V0cHV0IG9ubHkuIFRo
ZSB0aW1lIHdoZW4gdGhlIGRvY2tlciBpbWFnZSB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAAC
BwYSA1QCGwoMCgUEAAIHARIDVBwnCgwKBQQAAgcDEgNUKisKDAoFBAACBwgSA1UGMQoPCggE
AAIHCJwIABIDVQcwCqQCCgQEAAIIEgNbAhsalgIgQXJ0aWZhY3RUeXBlIG9mIHRoaXMgaW1h
Z2UsIGUuZy4gImFwcGxpY2F0aW9uL3ZuZC5leGFtcGxlK3R5cGUiLgogSWYgdGhlIGBzdWJq
ZWN0X2RpZ2VzdGAgaXMgc2V0IGFuZCBubyBgYXJ0aWZhY3RfdHlwZWAgaXMgZ2l2ZW4sIHRo
ZQogYG1lZGlhX3R5cGVgIHdpbGwgYmUgY29uc2lkZXJlZCBhcyB0aGUgYGFydGlmYWN0X3R5
cGVgLiBUaGlzIGZpZWxkIGlzCiByZXR1cm5lZCBhcyB0aGUgYG1ldGFkYXRhLmFydGlmYWN0
VHlwZWAgZmllbGQgaW4gdGhlIFZlcnNpb24gcmVzb3VyY2UuCgoMCgUEAAIIBRIDWwIICgwK
BQQAAggBEgNbCRYKDAoFBAACCAMSA1sZGgpzCgQEAAIJEgRfAmAvGmUgT3B0aW9uYWwuIEZv
ciBtdWx0aS1hcmNoIGltYWdlcyAobWFuaWZlc3QgbGlzdHMpLCB0aGlzIGZpZWxkIGNvbnRh
aW5zIHRoZQogbGlzdCBvZiBpbWFnZSBtYW5pZmVzdHMuCgoMCgUEAAIJBBIDXwIKCgwKBQQA
AgkGEgNfCxgKDAoFBAACCQESA18ZKAoMCgUEAAIJAxIDXystCgwKBQQAAgkIEgNgBi4KDwoI
BAACCQicCAASA2AHLQpMCgIEARIFZACCAQEaPyBEZXRhaWxzIG9mIGEgc2luZ2xlIGltYWdl
IG1hbmlmZXN0IHdpdGhpbiBhIG11bHRpLWFyY2ggaW1hZ2UuCgoKCgMEAQESA2QIFQrtAQoE
BAECABIDaQJDGt8BIE9wdGlvbmFsLiBUaGUgQ1BVIGFyY2hpdGVjdHVyZSBvZiB0aGUgaW1h
Z2UuCiBWYWx1ZXMgYXJlIHByb3ZpZGVkIGJ5IHRoZSBEb2NrZXIgY2xpZW50IGFuZCBhcmUg
bm90IHZhbGlkYXRlZCBieSBBcnRpZmFjdAogUmVnaXN0cnkuIEV4YW1wbGUgdmFsdWVzIGlu
Y2x1ZGUgImFtZDY0IiwgImFybTY0IiwgInBwYzY0bGUiLCAiczM5MHgiLAogInJpc2N2NjQi
LCAibWlwczY0bGUiLCBldGMuCgoMCgUEAQIABRIDaQIICgwKBQQBAgABEgNpCRUKDAoFBAEC
AAMSA2kYGQoMCgUEAQIACBIDaRpCCg8KCAQBAgAInAgAEgNpG0EK1AEKBAQBAgESA24CORrG
ASBPcHRpb25hbC4gVGhlIG9wZXJhdGluZyBzeXN0ZW0gb2YgdGhlIGltYWdlLgogVmFsdWVz
IGFyZSBwcm92aWRlZCBieSB0aGUgRG9ja2VyIGNsaWVudCBhbmQgYXJlIG5vdCB2YWxpZGF0
ZWQgYnkgQXJ0aWZhY3QKIFJlZ2lzdHJ5LiBFeGFtcGxlIHZhbHVlcyBpbmNsdWRlICJsaW51
eCIsICJ3aW5kb3dzIiwgImRhcndpbiIsICJhaXgiLCBldGMuCgoMCgUEAQIBBRIDbgIICgwK
BQQBAgEBEgNuCQsKDAoFBAECAQMSA24ODwoMCgUEAQIBCBIDbhA4Cg8KCAQBAgEInAgAEgNu
ETcKWQoEBAECAhIDcQI9GkwgT3B0aW9uYWwuIFRoZSBtYW5pZmVzdCBkaWdlc3QsIGluIHRo
ZSBmb3JtYXQgInNoYTI1Njo8c2hhMjU2X2hleF9kaWdlc3Q+Ii4KCgwKBQQBAgIFEgNxAggK
DAoFBAECAgESA3EJDwoMCgUEAQICAxIDcRITCgwKBQQBAgIIEgNxFDwKDwoIBAECAgicCAAS
A3EVOwp2CgQEAQIDEgN1AkEaaSBPcHRpb25hbC4gVGhlIG1lZGlhIHR5cGUgb2YgdGhlIG1h
bmlmZXN0LCBlLmcuLAogImFwcGxpY2F0aW9uL3ZuZC5kb2NrZXIuZGlzdHJpYnV0aW9uLm1h
bmlmZXN0LnYyK2pzb24iCgoMCgUEAQIDBRIDdQIICgwKBQQBAgMBEgN1CRMKDAoFBAECAwMS
A3UWFwoMCgUEAQIDCBIDdRhACg8KCAQBAgMInAgAEgN1GT8KYAoEBAECBBIDeQJBGlMgT3B0
aW9uYWwuIFRoZSBPUyB2ZXJzaW9uIG9mIHRoZSBpbWFnZSwgZm9yIGV4YW1wbGUgb24gV2lu
ZG93cwogYDEwLjAuMTQzOTMuMTA2NmAuCgoMCgUEAQIEBRIDeQIICgwKBQQBAgQBEgN5CRMK
DAoFBAECBAMSA3kWFwoMCgUEAQIECBIDeRhACg8KCAQBAgQInAgAEgN5GT8KYgoEBAECBRID
fQJLGlUgT3B0aW9uYWwuIFRoZSByZXF1aXJlZCBPUyBmZWF0dXJlcyBmb3IgdGhlIGltYWdl
LCBmb3IgZXhhbXBsZSBvbiBXaW5kb3dzCiBgd2luMzJrYC4KCgwKBQQBAgUEEgN9AgoKDAoF
BAECBQUSA30LEQoMCgUEAQIFARIDfRIdCgwKBQQBAgUDEgN9ICEKDAoFBAECBQgSA30iSgoP
CggEAQIFCJwIABIDfSNJCn0KBAQBAgYSBIEBAj4abyBPcHRpb25hbC4gVGhlIHZhcmlhbnQg
b2YgdGhlIENQVSBpbiB0aGUgaW1hZ2UsIGZvciBleGFtcGxlIGB2N2AgdG8gc3BlY2lmeQog
QVJNdjcgd2hlbiBhcmNoaXRlY3R1cmUgaXMgYGFybWAuCgoNCgUEAQIGBRIEgQECCAoNCgUE
AQIGARIEgQEJEAoNCgUEAQIGAxIEgQETFAoNCgUEAQIGCBIEgQEVPQoQCggEAQIGCJwIABIE
gQEWPAoyCgIEAhIGhQEAkgEBGiQgVGhlIHJlcXVlc3QgdG8gbGlzdCBkb2NrZXIgaW1hZ2Vz
LgoKCwoDBAIBEgSFAQgfCl4KBAQCAgASBIgBAj0aUCBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIHBhcmVudCByZXNvdXJjZSB3aG9zZSBkb2NrZXIgaW1hZ2VzIHdpbGwgYmUKIGxpc3Rl
ZC4KCg0KBQQCAgAFEgSIAQIICg0KBQQCAgABEgSIAQkPCg0KBQQCAgADEgSIARITCg0KBQQC
AgAIEgSIARQ8ChAKCAQCAgAInAgAEgSIARU7ClYKBAQCAgESBIsBAhYaSCBUaGUgbWF4aW11
bSBudW1iZXIgb2YgYXJ0aWZhY3RzIHRvIHJldHVybi4gTWF4aW11bSBwYWdlIHNpemUgaXMg
MSwwMDAuCgoNCgUEAgIBBRIEiwECBwoNCgUEAgIBARIEiwEIEQoNCgUEAgIBAxIEiwEUFQpY
CgQEAgICEgSOAQIYGkogVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9t
IGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBhbnkuCgoNCgUEAgICBRIEjgECCAoNCgUE
AgICARIEjgEJEwoNCgUEAgICAxIEjgEWFwoyCgQEAgIDEgSRAQIWGiQgVGhlIGZpZWxkIHRv
IG9yZGVyIHRoZSByZXN1bHRzIGJ5LgoKDQoFBAICAwUSBJEBAggKDQoFBAICAwESBJEBCREK
DQoFBAICAwMSBJEBFBUKOAoCBAMSBpUBAJwBARoqIFRoZSByZXNwb25zZSBmcm9tIGxpc3Rp
bmcgZG9ja2VyIGltYWdlcy4KCgsKAwQDARIElQEIIAorCgQEAwIAEgSXAQIpGh0gVGhlIGRv
Y2tlciBpbWFnZXMgcmV0dXJuZWQuCgoNCgUEAwIABBIElwECCgoNCgUEAwIABhIElwELFgoN
CgUEAwIAARIElwEXJAoNCgUEAwIAAxIElwEnKAp1CgQEAwIBEgSbAQIdGmcgVGhlIHRva2Vu
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgYXJ0aWZhY3RzLCBvciBlbXB0eSBpZiB0
aGVyZSBhcmUgbm8KIG1vcmUgYXJ0aWZhY3RzIHRvIHJldHVybi4KCg0KBQQDAgEFEgSbAQII
Cg0KBQQDAgEBEgSbAQkYCg0KBQQDAgEDEgSbARscCjEKAgQEEgafAQCnAQEaIyBUaGUgcmVx
dWVzdCB0byBnZXQgZG9ja2VyIGltYWdlcy4KCgsKAwQEARIEnwEIHQo6CgQEBAIAEgahAQKm
AQQaKiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGRvY2tlciBpbWFnZXMuCgoNCgUEBAIA
BRIEoQECCAoNCgUEBAIAARIEoQEJDQoNCgUEBAIAAxIEoQEQEQoPCgUEBAIACBIGoQESpgED
ChAKCAQEAgAInAgAEgSiAQQqChEKBwQEAgAInwgSBqMBBKUBBQo6CgIEBRIGqgEA0QEBGiwg
TWF2ZW5BcnRpZmFjdCByZXByZXNlbnRzIGEgbWF2ZW4gYXJ0aWZhY3QuCgoLCgMEBQESBKoB
CBUKDQoDBAUHEgarAQKuAQQKDwoFBAUHnQgSBqsBAq4BBAqoAwoEBAUCABIEuAECOxqZAyBS
ZXF1aXJlZC4gcmVnaXN0cnlfbG9jYXRpb24sIHByb2plY3RfaWQsIHJlcG9zaXRvcnlfbmFt
ZSBhbmQgbWF2ZW5fYXJ0aWZhY3QKIGZvcm1zIGEgdW5pcXVlIGFydGlmYWN0IEZvciBleGFt
cGxlLAogInByb2plY3RzL3Rlc3QtcHJvamVjdC9sb2NhdGlvbnMvdXMtd2VzdDQvcmVwb3Np
dG9yaWVzL3Rlc3QtcmVwby9tYXZlbkFydGlmYWN0cy8KIGNvbS5nb29nbGUuZ3VhdmE6Z3Vh
dmE6MzEuMC1qcmUiLAogd2hlcmUgInVzLXdlc3Q0IiBpcyB0aGUgcmVnaXN0cnlfbG9jYXRp
b24sICJ0ZXN0LXByb2plY3QiIGlzIHRoZQogcHJvamVjdF9pZCwgInRlc3QtcmVwbyIgaXMg
dGhlIHJlcG9zaXRvcnlfbmFtZSBhbmQKICJjb20uZ29vZ2xlLmd1YXZhOmd1YXZhOjMxLjAt
anJlIgogaXMgdGhlIG1hdmVuIGFydGlmYWN0LgoKDQoFBAUCAAUSBLgBAggKDQoFBAUCAAES
BLgBCQ0KDQoFBAUCAAMSBLgBEBEKDQoFBAUCAAgSBLgBEjoKEAoIBAUCAAicCAASBLgBEzkK
qgEKBAQFAgESBL0BAj4amwEgUmVxdWlyZWQuIFVSTCB0byBhY2Nlc3MgdGhlIHBvbSBmaWxl
IG9mIHRoZSBhcnRpZmFjdC4KIEV4YW1wbGU6CiB1cy13ZXN0NC1tYXZlbi5wa2cuZGV2L3Rl
c3QtcHJvamVjdC90ZXN0LXJlcG8vY29tL2dvb2dsZS9ndWF2YS9ndWF2YS8zMS4wL2d1YXZh
LTMxLjAucG9tCgoNCgUEBQIBBRIEvQECCAoNCgUEBQIBARIEvQEJEAoNCgUEBQIBAxIEvQET
FAoNCgUEBQIBCBIEvQEVPQoQCggEBQIBCJwIABIEvQEWPApGCgQEBQICEgTCAQIWGjggR3Jv
dXAgSUQgZm9yIHRoZSBhcnRpZmFjdC4KIEV4YW1wbGU6CiBjb20uZ29vZ2xlLmd1YXZhCgoN
CgUEBQICBRIEwgECCAoNCgUEBQICARIEwgEJEQoNCgUEBQICAxIEwgEUFQotCgQEBQIDEgTF
AQIZGh8gQXJ0aWZhY3QgSUQgZm9yIHRoZSBhcnRpZmFjdC4KCg0KBQQFAgMFEgTFAQIICg0K
BQQFAgMBEgTFAQkUCg0KBQQFAgMDEgTFARcYCikKBAQFAgQSBMgBAhUaGyBWZXJzaW9uIG9m
IHRoaXMgYXJ0aWZhY3QuCgoNCgUEBQIEBRIEyAECCAoNCgUEBQIEARIEyAEJEAoNCgUEBQIE
AxIEyAETFAo9CgQEBQIFEgbLAQLMATIaLSBPdXRwdXQgb25seS4gVGltZSB0aGUgYXJ0aWZh
Y3Qgd2FzIGNyZWF0ZWQuCgoNCgUEBQIFBhIEywECGwoNCgUEBQIFARIEywEcJwoNCgUEBQIF
AxIEywEqKwoNCgUEBQIFCBIEzAEGMQoQCggEBQIFCJwIABIEzAEHMAo9CgQEBQIGEgbPAQLQ
ATIaLSBPdXRwdXQgb25seS4gVGltZSB0aGUgYXJ0aWZhY3Qgd2FzIHVwZGF0ZWQuCgoNCgUE
BQIGBhIEzwECGwoNCgUEBQIGARIEzwEcJwoNCgUEBQIGAxIEzwEqKwoNCgUEBQIGCBIE0AEG
MQoQCggEBQIGCJwIABIE0AEHMAo0CgIEBhIG1AEA4wEBGiYgVGhlIHJlcXVlc3QgdG8gbGlz
dCBtYXZlbiBhcnRpZmFjdHMuCgoLCgMEBgESBNQBCCEKYgoEBAYCABIG1wEC3AEEGlIgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hvc2UgbWF2ZW4gYXJ0
aWZhY3RzIHdpbGwgYmUKIGxpc3RlZC4KCg0KBQQGAgAFEgTXAQIICg0KBQQGAgABEgTXAQkP
Cg0KBQQGAgADEgTXARITCg8KBQQGAgAIEgbXARTcAQMKEAoIBAYCAAicCAASBNgBBCoKEQoH
BAYCAAifCBIG2QEE2wEFClYKBAQGAgESBN8BAhYaSCBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
YXJ0aWZhY3RzIHRvIHJldHVybi4gTWF4aW11bSBwYWdlIHNpemUgaXMgMSwwMDAuCgoNCgUE
BgIBBRIE3wECBwoNCgUEBgIBARIE3wEIEQoNCgUEBgIBAxIE3wEUFQpYCgQEBgICEgTiAQIY
GkogVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMg
bGlzdCByZXF1ZXN0LCBpZiBhbnkuCgoNCgUEBgICBRIE4gECCAoNCgUEBgICARIE4gEJEwoN
CgUEBgICAxIE4gEWFwo6CgIEBxIG5gEA7QEBGiwgVGhlIHJlc3BvbnNlIGZyb20gbGlzdGlu
ZyBtYXZlbiBhcnRpZmFjdHMuCgoLCgMEBwESBOYBCCIKLQoEBAcCABIE6AECLRofIFRoZSBt
YXZlbiBhcnRpZmFjdHMgcmV0dXJuZWQuCgoNCgUEBwIABBIE6AECCgoNCgUEBwIABhIE6AEL
GAoNCgUEBwIAARIE6AEZKAoNCgUEBwIAAxIE6AErLAp1CgQEBwIBEgTsAQIdGmcgVGhlIHRv
a2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgYXJ0aWZhY3RzLCBvciBlbXB0eSBp
ZiB0aGVyZSBhcmUgbm8KIG1vcmUgYXJ0aWZhY3RzIHRvIHJldHVybi4KCg0KBQQHAgEFEgTs
AQIICg0KBQQHAgEBEgTsAQkYCg0KBQQHAgEDEgTsARscCjMKAgQIEgbwAQD4AQEaJSBUaGUg
cmVxdWVzdCB0byBnZXQgbWF2ZW4gYXJ0aWZhY3RzLgoKCwoDBAgBEgTwAQgfCjsKBAQIAgAS
BvIBAvcBBBorIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgbWF2ZW4gYXJ0aWZhY3QuCgoN
CgUECAIABRIE8gECCAoNCgUECAIAARIE8gEJDQoNCgUECAIAAxIE8gEQEQoPCgUECAIACBIG
8gES9wEDChAKCAQIAgAInAgAEgTzAQQqChEKBwQIAgAInwgSBvQBBPYBBQo2CgIECRIG+wEA
mgIBGiggTnBtUGFja2FnZSByZXByZXNlbnRzIGFuIG5wbSBhcnRpZmFjdC4KCgsKAwQJARIE
+wEIEgoNCgMECQcSBvwBAv8BBAoPCgUECQedCBIG/AEC/wEECvoCCgQECQIAEgSIAgI7GusC
IFJlcXVpcmVkLiByZWdpc3RyeV9sb2NhdGlvbiwgcHJvamVjdF9pZCwgcmVwb3NpdG9yeV9u
YW1lIGFuZCBucG1fcGFja2FnZQogZm9ybXMgYSB1bmlxdWUgcGFja2FnZSBGb3IgZXhhbXBs
ZSwKICJwcm9qZWN0cy90ZXN0LXByb2plY3QvbG9jYXRpb25zL3VzLXdlc3Q0L3JlcG9zaXRv
cmllcy90ZXN0LXJlcG8vbnBtUGFja2FnZXMvCiBucG1fdGVzdDoxLjAuMCIsCiB3aGVyZSAi
dXMtd2VzdDQiIGlzIHRoZSByZWdpc3RyeV9sb2NhdGlvbiwgInRlc3QtcHJvamVjdCIgaXMg
dGhlCiBwcm9qZWN0X2lkLCAidGVzdC1yZXBvIiBpcyB0aGUgcmVwb3NpdG9yeV9uYW1lIGFu
ZAogbnBtX3Rlc3Q6MS4wLjAiIGlzIHRoZSBucG0gcGFja2FnZS4KCg0KBQQJAgAFEgSIAgII
Cg0KBQQJAgABEgSIAgkNCg0KBQQJAgADEgSIAhARCg0KBQQJAgAIEgSIAhI6ChAKCAQJAgAI
nAgAEgSIAhM5CikKBAQJAgESBIsCAhoaGyBQYWNrYWdlIGZvciB0aGUgYXJ0aWZhY3QuCgoN
CgUECQIBBRIEiwICCAoNCgUECQIBARIEiwIJFQoNCgUECQIBAxIEiwIYGQooCgQECQICEgSO
AgIVGhogVmVyc2lvbiBvZiB0aGlzIHBhY2thZ2UuCgoNCgUECQICBRIEjgICCAoNCgUECQIC
ARIEjgIJEAoNCgUECQICAxIEjgITFAouCgQECQIDEgSRAgIbGiAgVGFncyBhdHRhY2hlZCB0
byB0aGlzIHBhY2thZ2UuCgoNCgUECQIDBBIEkQICCgoNCgUECQIDBRIEkQILEQoNCgUECQID
ARIEkQISFgoNCgUECQIDAxIEkQIZGgo8CgQECQIEEgaUAgKVAjIaLCBPdXRwdXQgb25seS4g
VGltZSB0aGUgcGFja2FnZSB3YXMgY3JlYXRlZC4KCg0KBQQJAgQGEgSUAgIbCg0KBQQJAgQB
EgSUAhwnCg0KBQQJAgQDEgSUAiorCg0KBQQJAgQIEgSVAgYxChAKCAQJAgQInAgAEgSVAgcw
CjwKBAQJAgUSBpgCApkCMhosIE91dHB1dCBvbmx5LiBUaW1lIHRoZSBwYWNrYWdlIHdhcyB1
cGRhdGVkLgoKDQoFBAkCBQYSBJgCAhsKDQoFBAkCBQESBJgCHCcKDQoFBAkCBQMSBJgCKisK
DQoFBAkCBQgSBJkCBjEKEAoIBAkCBQicCAASBJkCBzAKMQoCBAoSBp0CAKwCARojIFRoZSBy
ZXF1ZXN0IHRvIGxpc3QgbnBtIHBhY2thZ2VzLgoKCwoDBAoBEgSdAggeCl8KBAQKAgASBqAC
AqUCBBpPIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcGFyZW50IHJlc291cmNlIHdob3Nl
IG5wbSBwYWNrYWdlcyB3aWxsIGJlCiBsaXN0ZWQuCgoNCgUECgIABRIEoAICCAoNCgUECgIA
ARIEoAIJDwoNCgUECgIAAxIEoAISEwoPCgUECgIACBIGoAIUpQIDChAKCAQKAgAInAgAEgSh
AgQqChEKBwQKAgAInwgSBqICBKQCBQpWCgQECgIBEgSoAgIWGkggVGhlIG1heGltdW0gbnVt
YmVyIG9mIGFydGlmYWN0cyB0byByZXR1cm4uIE1heGltdW0gcGFnZSBzaXplIGlzIDEsMDAw
LgoKDQoFBAoCAQUSBKgCAgcKDQoFBAoCAQESBKgCCBEKDQoFBAoCAQMSBKgCFBUKWAoEBAoC
AhIEqwICGBpKIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHBy
ZXZpb3VzIGxpc3QgcmVxdWVzdCwgaWYgYW55LgoKDQoFBAoCAgUSBKsCAggKDQoFBAoCAgES
BKsCCRMKDQoFBAoCAgMSBKsCFhcKNwoCBAsSBq8CALYCARopIFRoZSByZXNwb25zZSBmcm9t
IGxpc3RpbmcgbnBtIHBhY2thZ2VzLgoKCwoDBAsBEgSvAggfCioKBAQLAgASBLECAicaHCBU
aGUgbnBtIHBhY2thZ2VzIHJldHVybmVkLgoKDQoFBAsCAAQSBLECAgoKDQoFBAsCAAYSBLEC
CxUKDQoFBAsCAAESBLECFiIKDQoFBAsCAAMSBLECJSYKdQoEBAsCARIEtQICHRpnIFRoZSB0
b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIGFydGlmYWN0cywgb3IgZW1wdHkg
aWYgdGhlcmUgYXJlIG5vCiBtb3JlIGFydGlmYWN0cyB0byByZXR1cm4uCgoNCgUECwIBBRIE
tQICCAoNCgUECwIBARIEtQIJGAoNCgUECwIBAxIEtQIbHAowCgIEDBIGuQIAwQIBGiIgVGhl
IHJlcXVlc3QgdG8gZ2V0IG5wbSBwYWNrYWdlcy4KCgsKAwQMARIEuQIIHAo4CgQEDAIAEga7
AgLAAgQaKCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG5wbSBwYWNrYWdlLgoKDQoFBAwC
AAUSBLsCAggKDQoFBAwCAAESBLsCCQ0KDQoFBAwCAAMSBLsCEBEKDwoFBAwCAAgSBrsCEsAC
AwoQCggEDAIACJwIABIEvAIEKgoRCgcEDAIACJ8IEga9AgS/AgUKOwoCBA0SBsQCAOcCARot
IFB5dGhvblBhY2thZ2UgcmVwcmVzZW50cyBhIHB5dGhvbiBhcnRpZmFjdC4KCgsKAwQNARIE
xAIIFQoNCgMEDQcSBsUCAsgCBAoPCgUEDQedCBIGxQICyAIECoEECgQEDQIAEgTTAgI7GvID
IFJlcXVpcmVkLiByZWdpc3RyeV9sb2NhdGlvbiwgcHJvamVjdF9pZCwgcmVwb3NpdG9yeV9u
YW1lIGFuZCBweXRob25fcGFja2FnZQogZm9ybXMgYSB1bmlxdWUgcGFja2FnZQogbmFtZTpg
cHJvamVjdHMvPHByb2plY3RfaWQ+L2xvY2F0aW9ucy88bG9jYXRpb24+L3JlcG9zaXRvcnkv
PHJlcG9zaXRvcnlfbmFtZT4vcHl0aG9uUGFja2FnZXMvPHB5dGhvbl9wYWNrYWdlPmAuCiBG
b3IgZXhhbXBsZSwKICJwcm9qZWN0cy90ZXN0LXByb2plY3QvbG9jYXRpb25zL3VzLXdlc3Q0
L3JlcG9zaXRvcmllcy90ZXN0LXJlcG8vcHl0aG9uUGFja2FnZXMvCiBweXRob25fcGFja2Fn
ZToxLjAuMCIsCiB3aGVyZSAidXMtd2VzdDQiIGlzIHRoZSByZWdpc3RyeV9sb2NhdGlvbiwg
InRlc3QtcHJvamVjdCIgaXMgdGhlCiBwcm9qZWN0X2lkLCAidGVzdC1yZXBvIiBpcyB0aGUg
cmVwb3NpdG9yeV9uYW1lIGFuZAogcHl0aG9uX3BhY2thZ2U6MS4wLjAiIGlzIHRoZSBweXRo
b24gcGFja2FnZS4KCg0KBQQNAgAFEgTTAgIICg0KBQQNAgABEgTTAgkNCg0KBQQNAgADEgTT
AhARCg0KBQQNAgAIEgTTAhI6ChAKCAQNAgAInAgAEgTTAhM5CpUBCgQEDQIBEgTYAgI6GoYB
IFJlcXVpcmVkLiBVUkwgdG8gYWNjZXNzIHRoZSBwYWNrYWdlLgogRXhhbXBsZToKIHVzLXdl
c3Q0LXB5dGhvbi5wa2cuZGV2L3Rlc3QtcHJvamVjdC90ZXN0LXJlcG8vcHl0aG9uX3BhY2th
Z2UvZmlsZS1uYW1lLTEuMC4wLnRhci5negoKDQoFBA0CAQUSBNgCAggKDQoFBA0CAQESBNgC
CQwKDQoFBA0CAQMSBNgCDxAKDQoFBA0CAQgSBNgCETkKEAoIBA0CAQicCAASBNgCEjgKKQoE
BA0CAhIE2wICGhobIFBhY2thZ2UgZm9yIHRoZSBhcnRpZmFjdC4KCg0KBQQNAgIFEgTbAgII
Cg0KBQQNAgIBEgTbAgkVCg0KBQQNAgIDEgTbAhgZCigKBAQNAgMSBN4CAhUaGiBWZXJzaW9u
IG9mIHRoaXMgcGFja2FnZS4KCg0KBQQNAgMFEgTeAgIICg0KBQQNAgMBEgTeAgkQCg0KBQQN
AgMDEgTeAhMUCjwKBAQNAgQSBuECAuICMhosIE91dHB1dCBvbmx5LiBUaW1lIHRoZSBwYWNr
YWdlIHdhcyBjcmVhdGVkLgoKDQoFBA0CBAYSBOECAhsKDQoFBA0CBAESBOECHCcKDQoFBA0C
BAMSBOECKisKDQoFBA0CBAgSBOICBjEKEAoIBA0CBAicCAASBOICBzAKPAoEBA0CBRIG5QIC
5gIyGiwgT3V0cHV0IG9ubHkuIFRpbWUgdGhlIHBhY2thZ2Ugd2FzIHVwZGF0ZWQuCgoNCgUE
DQIFBhIE5QICGwoNCgUEDQIFARIE5QIcJwoNCgUEDQIFAxIE5QIqKwoNCgUEDQIFCBIE5gIG
MQoQCggEDQIFCJwIABIE5gIHMAo0CgIEDhIG6gIA+QIBGiYgVGhlIHJlcXVlc3QgdG8gbGlz
dCBweXRob24gcGFja2FnZXMuCgoLCgMEDgESBOoCCCEKYgoEBA4CABIG7QIC8gIEGlIgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hvc2UgcHl0aG9uIHBh
Y2thZ2VzIHdpbGwgYmUKIGxpc3RlZC4KCg0KBQQOAgAFEgTtAgIICg0KBQQOAgABEgTtAgkP
Cg0KBQQOAgADEgTtAhITCg8KBQQOAgAIEgbtAhTyAgMKEAoIBA4CAAicCAASBO4CBCoKEQoH
BA4CAAifCBIG7wIE8QIFClYKBAQOAgESBPUCAhYaSCBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
YXJ0aWZhY3RzIHRvIHJldHVybi4gTWF4aW11bSBwYWdlIHNpemUgaXMgMSwwMDAuCgoNCgUE
DgIBBRIE9QICBwoNCgUEDgIBARIE9QIIEQoNCgUEDgIBAxIE9QIUFQpYCgQEDgICEgT4AgIY
GkogVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMg
bGlzdCByZXF1ZXN0LCBpZiBhbnkuCgoNCgUEDgICBRIE+AICCAoNCgUEDgICARIE+AIJEwoN
CgUEDgICAxIE+AIWFwo6CgIEDxIG/AIAgwMBGiwgVGhlIHJlc3BvbnNlIGZyb20gbGlzdGlu
ZyBweXRob24gcGFja2FnZXMuCgoLCgMEDwESBPwCCCIKLQoEBA8CABIE/gICLRofIFRoZSBw
eXRob24gcGFja2FnZXMgcmV0dXJuZWQuCgoNCgUEDwIABBIE/gICCgoNCgUEDwIABhIE/gIL
GAoNCgUEDwIAARIE/gIZKAoNCgUEDwIAAxIE/gIrLAp1CgQEDwIBEgSCAwIdGmcgVGhlIHRv
a2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgYXJ0aWZhY3RzLCBvciBlbXB0eSBp
ZiB0aGVyZSBhcmUgbm8KIG1vcmUgYXJ0aWZhY3RzIHRvIHJldHVybi4KCg0KBQQPAgEFEgSC
AwIICg0KBQQPAgEBEgSCAwkYCg0KBQQPAgEDEgSCAxscCjMKAgQQEgaGAwCOAwEaJSBUaGUg
cmVxdWVzdCB0byBnZXQgcHl0aG9uIHBhY2thZ2VzLgoKCwoDBBABEgSGAwgfCjsKBAQQAgAS
BogDAo0DBBorIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcHl0aG9uIHBhY2thZ2UuCgoN
CgUEEAIABRIEiAMCCAoNCgUEEAIAARIEiAMJDQoNCgUEEAIAAxIEiAMQEQoPCgUEEAIACBIG
iAMSjQMDChAKCAQQAgAInAgAEgSJAwQqChEKBwQQAgAInwgSBooDBIwDBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::DockerImage ===
    # Fields for DockerImage
    # Field: name Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: image_size_bytes Type: 3 ()
    # Field: upload_time Type: 11 (.google.protobuf.Timestamp)
    # Field: media_type Type: 9 ()
    # Field: build_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: artifact_type Type: 9 ()
    # Field: image_manifests Type: 11 (.google.devtools.artifactregistry.v1.ImageManifest)

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ImageManifest ===
    # Fields for ImageManifest
    # Field: architecture Type: 9 ()
    # Field: os Type: 9 ()
    # Field: digest Type: 9 ()
    # Field: media_type Type: 9 ()
    # Field: os_version Type: 9 ()
    # Field: os_features Type: 9 ()
    # Field: variant Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest ===
    # Fields for ListDockerImagesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse ===
    # Fields for ListDockerImagesResponse
    # Field: docker_images Type: 11 (.google.devtools.artifactregistry.v1.DockerImage)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::GetDockerImageRequest ===
    # Fields for GetDockerImageRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::MavenArtifact ===
    # Fields for MavenArtifact
    # Field: name Type: 9 ()
    # Field: pom_uri Type: 9 ()
    # Field: group_id Type: 9 ()
    # Field: artifact_id Type: 9 ()
    # Field: version Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsRequest ===
    # Fields for ListMavenArtifactsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsResponse ===
    # Fields for ListMavenArtifactsResponse
    # Field: maven_artifacts Type: 11 (.google.devtools.artifactregistry.v1.MavenArtifact)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::GetMavenArtifactRequest ===
    # Fields for GetMavenArtifactRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::NpmPackage ===
    # Fields for NpmPackage
    # Field: name Type: 9 ()
    # Field: package_name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: tags Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesRequest ===
    # Fields for ListNpmPackagesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesResponse ===
    # Fields for ListNpmPackagesResponse
    # Field: npm_packages Type: 11 (.google.devtools.artifactregistry.v1.NpmPackage)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::GetNpmPackageRequest ===
    # Fields for GetNpmPackageRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::PythonPackage ===
    # Fields for PythonPackage
    # Field: name Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: package_name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesRequest ===
    # Fields for ListPythonPackagesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesResponse ===
    # Fields for ListPythonPackagesResponse
    # Field: python_packages Type: 11 (.google.devtools.artifactregistry.v1.PythonPackage)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Artifact::GetPythonPackageRequest ===
    # Fields for GetPythonPackageRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Artifact - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/artifact.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Artifact;

    my $msg = Google::Devtools::Artifactregistry::V1::Artifact::DockerImage->new({
        name => $name,
        uri => $uri,
        tags => $tags,
        image_size_bytes => $image_size_bytes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Artifact::DockerImage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/artifact.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Artifact::DockerImage

DockerImage represents a docker artifact.
The following fields are returned as untyped metadata in the Version
resource, using camelcase keys (i.e. metadata.imageSizeBytes):
* imageSizeBytes
* mediaType
* buildTime

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. registry_location, project_id, repository_name and image id forms
a unique image
name:`projects/<project_id>/locations/<location>/repositories/<repository_name>/dockerImages/<docker_image>`.
For example,
"projects/test-project/locations/us-west4/repositories/test-repo/dockerImages/
nginx@sha256:e9954c1fc875017be1c3e36eca16be2d9e9bccc4bf072163515467d6a823c7cf",
where "us-west4" is the registry_location, "test-project" is the
project_id, "test-repo" is the repository_name and
"nginx@sha256:e9954c1fc875017be1c3e36eca16be2d9e9bccc4bf072163515467d6a823c7cf"
is the image's digest.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. URL to access the image.
Example:
us-west4-docker.pkg.dev/test-project/test-repo/nginx@sha256:e9954c1fc875017be1c3e36eca16be2d9e9bccc4bf072163515467d6a823c7cf

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Tags attached to this image.

=item * C<< $msg->image_size_bytes() >> / C<< $msg->image_size_bytes($value) >>

Type: C<Int64>

Calculated size of the image.
This field is returned as the 'metadata.imageSizeBytes' field in the
Version resource.

=item * C<< $msg->upload_time() >> / C<< $msg->upload_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the image was uploaded.

=item * C<< $msg->media_type() >> / C<< $msg->media_type($value) >>

Type: C<String>

Media type of this image, e.g.
"application/vnd.docker.distribution.manifest.v2+json".
This field is returned as the 'metadata.mediaType' field in the
Version resource.

=item * C<< $msg->build_time() >> / C<< $msg->build_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this image was built.
This field is returned as the 'metadata.buildTime' field in the
Version resource.
The build time is returned to the client as an RFC 3339 string, which can
be easily used with the JavaScript Date constructor.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the docker image was last updated.

=item * C<< $msg->artifact_type() >> / C<< $msg->artifact_type($value) >>

Type: C<String>

ArtifactType of this image, e.g. "application/vnd.example+type".
If the `subject_digest` is set and no `artifact_type` is given, the
`media_type` will be considered as the `artifact_type`. This field is
returned as the `metadata.artifactType` field in the Version resource.

=item * C<< $msg->image_manifests() >> / C<< $msg->image_manifests($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Artifact::ImageManifest>)

Optional. For multi-arch images (manifest lists), this field contains the
list of image manifests.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ImageManifest

Details of a single image manifest within a multi-arch image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<String>

Optional. The CPU architecture of the image.
Values are provided by the Docker client and are not validated by Artifact
Registry. Example values include "amd64", "arm64", "ppc64le", "s390x",
"riscv64", "mips64le", etc.

=item * C<< $msg->os() >> / C<< $msg->os($value) >>

Type: C<String>

Optional. The operating system of the image.
Values are provided by the Docker client and are not validated by Artifact
Registry. Example values include "linux", "windows", "darwin", "aix", etc.

=item * C<< $msg->digest() >> / C<< $msg->digest($value) >>

Type: C<String>

Optional. The manifest digest, in the format "sha256:<sha256_hex_digest>".

=item * C<< $msg->media_type() >> / C<< $msg->media_type($value) >>

Type: C<String>

Optional. The media type of the manifest, e.g.,
"application/vnd.docker.distribution.manifest.v2+json"

=item * C<< $msg->os_version() >> / C<< $msg->os_version($value) >>

Type: C<String>

Optional. The OS version of the image, for example on Windows
`10.0.14393.1066`.

=item * C<< $msg->os_features() >> / C<< $msg->os_features($value) >>

Type: C<String>

Optional. The required OS features for the image, for example on Windows
`win32k`.

=item * C<< $msg->variant() >> / C<< $msg->variant($value) >>

Type: C<String>

Optional. The variant of the CPU in the image, for example `v7` to specify
ARMv7 when architecture is `arm`.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest

The request to list docker images.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose docker images will be
listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of artifacts to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

The field to order the results by.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse

The response from listing docker images.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->docker_images() >> / C<< $msg->docker_images($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Artifact::DockerImage>)

The docker images returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of artifacts, or empty if there are no
more artifacts to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::GetDockerImageRequest

The request to get docker images.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the docker images.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::MavenArtifact

MavenArtifact represents a maven artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. registry_location, project_id, repository_name and maven_artifact
forms a unique artifact For example,
"projects/test-project/locations/us-west4/repositories/test-repo/mavenArtifacts/
com.google.guava:guava:31.0-jre",
where "us-west4" is the registry_location, "test-project" is the
project_id, "test-repo" is the repository_name and
"com.google.guava:guava:31.0-jre"
is the maven artifact.

=item * C<< $msg->pom_uri() >> / C<< $msg->pom_uri($value) >>

Type: C<String>

Required. URL to access the pom file of the artifact.
Example:
us-west4-maven.pkg.dev/test-project/test-repo/com/google/guava/guava/31.0/guava-31.0.pom

=item * C<< $msg->group_id() >> / C<< $msg->group_id($value) >>

Type: C<String>

Group ID for the artifact.
Example:
com.google.guava

=item * C<< $msg->artifact_id() >> / C<< $msg->artifact_id($value) >>

Type: C<String>

Artifact ID for the artifact.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of this artifact.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the artifact was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the artifact was updated.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsRequest

The request to list maven artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose maven artifacts will be
listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of artifacts to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsResponse

The response from listing maven artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->maven_artifacts() >> / C<< $msg->maven_artifacts($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Artifact::MavenArtifact>)

The maven artifacts returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of artifacts, or empty if there are no
more artifacts to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::GetMavenArtifactRequest

The request to get maven artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the maven artifact.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::NpmPackage

NpmPackage represents an npm artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. registry_location, project_id, repository_name and npm_package
forms a unique package For example,
"projects/test-project/locations/us-west4/repositories/test-repo/npmPackages/
npm_test:1.0.0",
where "us-west4" is the registry_location, "test-project" is the
project_id, "test-repo" is the repository_name and
npm_test:1.0.0" is the npm package.

=item * C<< $msg->package_name() >> / C<< $msg->package_name($value) >>

Type: C<String>

Package for the artifact.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of this package.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Tags attached to this package.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the package was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the package was updated.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesRequest

The request to list npm packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose npm packages will be
listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of artifacts to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesResponse

The response from listing npm packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->npm_packages() >> / C<< $msg->npm_packages($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Artifact::NpmPackage>)

The npm packages returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of artifacts, or empty if there are no
more artifacts to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::GetNpmPackageRequest

The request to get npm packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the npm package.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::PythonPackage

PythonPackage represents a python artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. registry_location, project_id, repository_name and python_package
forms a unique package
name:`projects/<project_id>/locations/<location>/repository/<repository_name>/pythonPackages/<python_package>`.
For example,
"projects/test-project/locations/us-west4/repositories/test-repo/pythonPackages/
python_package:1.0.0",
where "us-west4" is the registry_location, "test-project" is the
project_id, "test-repo" is the repository_name and
python_package:1.0.0" is the python package.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. URL to access the package.
Example:
us-west4-python.pkg.dev/test-project/test-repo/python_package/file-name-1.0.0.tar.gz

=item * C<< $msg->package_name() >> / C<< $msg->package_name($value) >>

Type: C<String>

Package for the artifact.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of this package.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the package was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the package was updated.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesRequest

The request to list python packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose python packages will be
listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of artifacts to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesResponse

The response from listing python packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->python_packages() >> / C<< $msg->python_packages($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Artifact::PythonPackage>)

The python packages returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of artifacts, or empty if there are no
more artifacts to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Artifact::GetPythonPackageRequest

The request to get python packages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the python package.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Artifact::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
