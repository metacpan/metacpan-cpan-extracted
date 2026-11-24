package Google::Cloud::Discoveryengine::V1beta::ProjectService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Common };
    eval { require Google::Cloud::Discoveryengine::V1beta::Project };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9wcm9qZWN0X3NlcnZpY2Uu
cHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxowZ29v
Z2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvY29tbW9uLnByb3RvGjFnb29nbGUv
Y2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9wcm9qZWN0LnByb3RvGiNnb29nbGUvbG9u
Z3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90byKFBgoXUHJvdmlzaW9uUHJvamVjdFJlcXVlc3QS
QgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
UHJvamVjdFIEbmFtZRI2ChVhY2NlcHRfZGF0YV91c2VfdGVybXMYAiABKAhCA+BBAlISYWNj
ZXB0RGF0YVVzZVRlcm1zEjgKFmRhdGFfdXNlX3Rlcm1zX3ZlcnNpb24YAyABKAlCA+BBAlIT
ZGF0YVVzZVRlcm1zVmVyc2lvbhJtCgtzYWFzX3BhcmFtcxgEIAEoCzJHLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlByb3Zpc2lvblByb2plY3RSZXF1ZXN0LlNhYXNQ
YXJhbXNCA+BBAVIKc2Fhc1BhcmFtcxJ8ChBwcm92aXNpb25faW50ZW50GAUgASgOMkwuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUHJvdmlzaW9uUHJvamVjdFJlcXVl
c3QuUHJvdmlzaW9uSW50ZW50QgPgQQFSD3Byb3Zpc2lvbkludGVudBJSCgppZHBfY29uZmln
GAYgASgLMi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRwQ29uZmln
QgPgQQFSCWlkcENvbmZpZxIxChJwcmVfcHJvdmlzaW9uX21vZGUYCCABKAhCA+BBAVIQcHJl
UHJvdmlzaW9uTW9kZRpTCgpTYWFzUGFyYW1zEikKDmFjY2VwdF9iaXpfcW9zGAEgASgIQgPg
QQFSDGFjY2VwdEJpelFvcxIaCgZpc19iaXoYAiABKAhCA+BBAVIFaXNCaXoiawoPUHJvdmlz
aW9uSW50ZW50EiAKHFBST1ZJU0lPTl9JTlRFTlRfVU5TUEVDSUZJRUQQABIZChVQUk9WSVNJ
T05fSU5URU5UX1NPQkkQARIbChdQUk9WSVNJT05fSU5URU5UX0xFR0FDWRACIhoKGFByb3Zp
c2lvblByb2plY3RNZXRhZGF0YTKwBAoOUHJvamVjdFNlcnZpY2USywIKEFByb3Zpc2lvblBy
b2plY3QSPC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Qcm92aXNpb25Q
cm9qZWN0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i2QGC0+STAl4i
Iy92MWJldGEve25hbWU9cHJvamVjdHMvKn06cHJvdmlzaW9uOgEqWjQiLy92MWJldGEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn06cHJvdmlzaW9uOgEq2kEEbmFtZcpBaworZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUHJvamVjdBI8Z29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUHJvdmlzaW9uUHJvamVjdE1ldGFkYXRhGs8BykEe
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQpoCCidjb20uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCE1Byb2plY3RTZXJ2aWNlUHJvdG9Q
AVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2Nv
dmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29v
Z2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292
ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFi
ZXRhSo0lCgcSBQ4AkwEjCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoC
AwQSAxYAOgoJCgIDBRIDFwA7CgkKAgMGEgMYAC0KCAoBCBIDGgBACgkKAgglEgMaAEAKCAoB
CBIDGwBoCgkKAggLEgMbAGgKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA0CgkKAggI
EgMdADQKCAoBCBIDHgBACgkKAggBEgMeAEAKCAoBCBIDHwAtCgkKAggkEgMfAC0KCAoBCBID
IABACgkKAggpEgMgAEAKCAoBCBIDIQA/CgkKAggtEgMhAD8KZAoCBgASBCUAQgEaWCBTZXJ2
aWNlIGZvciBvcGVyYXRpb25zIG9uIHRoZQogW1Byb2plY3RdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLlByb2plY3RdLgoKCgoDBgABEgMlCBYKCgoDBgADEgMmAkYK
DAoFBgADmQgSAyYCRgoLCgMGAAMSBCcCKkoKDQoFBgADmggSBCcCKkoKpAIKBAYAAgASBDIC
QQMalQIgUHJvdmlzaW9ucyB0aGUgcHJvamVjdCByZXNvdXJjZS4gRHVyaW5nIHRoZQogcHJv
Y2VzcywgcmVsYXRlZCBzeXN0ZW1zIHdpbGwgZ2V0IHByZXBhcmVkIGFuZCBpbml0aWFsaXpl
ZC4KCiBDYWxsZXIgbXVzdCByZWFkIHRoZSBbVGVybXMgZm9yIGRhdGEKIHVzZV0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9kYXRhLXVzZS10ZXJtcyksIGFuZCBvcHRpb25h
bGx5CiBzcGVjaWZ5IGluIHJlcXVlc3QgdG8gcHJvdmlkZSBjb25zZW50IHRvIHRoYXQgc2Vy
dmljZSB0ZXJtcy4KCgwKBQYAAgABEgMyBhYKDAoFBgACAAISAzIXLgoMCgUGAAIAAxIDMw8r
Cg0KBQYAAgAEEgQ0BDsGChEKCQYAAgAEsMq8IhIENAQ7BgoMCgUGAAIABBIDPAQyCg8KCAYA
AgAEmwgAEgM8BDIKDQoFBgACAAQSBD0EQAYKDwoHBgACAASZCBIEPQRABgqLAQoCBAASBUcA
kAEBGn4gUmVxdWVzdCBmb3IKIFtQcm9qZWN0U2VydmljZS5Qcm92aXNpb25Qcm9qZWN0XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Qcm9qZWN0U2VydmljZS5Qcm92
aXNpb25Qcm9qZWN0XQogbWV0aG9kLgoKCgoDBAABEgNHCB8KKgoEBAADABIESQJSAxocIFBh
cmFtZXRlcnMgZm9yIEFnZW50c3BhY2UuCgoMCgUEAAMAARIDSQoUCpwBCgYEAAMAAgASA0wE
RRqMASBPcHRpb25hbC4gU2V0IHRvIGB0cnVlYCB0byBzcGVjaWZ5IHRoYXQgY2FsbGVyIGhh
cyByZWFkIGFuZCB3b3VsZCBsaWtlIHRvCiBnaXZlIGNvbnNlbnQgdG8gdGhlIFtUZXJtcyBm
b3IgQWdlbnQgU3BhY2UgcXVhbGl0eSBvZiBzZXJ2aWNlXS4KCg4KBwQAAwACAAUSA0wECAoO
CgcEAAMAAgABEgNMCRcKDgoHBAADAAIAAxIDTBobCg4KBwQAAwACAAgSA0wcRAoRCgoEAAMA
AgAInAgAEgNMHUMKawoGBAADAAIBEgNRBD0aXCBPcHRpb25hbC4gSW5kaWNhdGVzIGlmIHRo
ZSBjdXJyZW50IHJlcXVlc3QgaXMgZm9yIEJpeiBlZGl0aW9uICg9IHRydWUpIG9yCiBub3QK
ICg9IGZhbHNlKS4KCg4KBwQAAwACAQUSA1EECAoOCgcEAAMAAgEBEgNRCQ8KDgoHBAADAAIB
AxIDURITCg4KBwQAAwACAQgSA1EUPAoRCgoEAAMAAgEInAgAEgNRFTsKPAoEBAAEABIEVQJf
AxouIFdoaWNoIGV4cGVyaWVuY2UgdGhlIGNhbGxlciBpcyBwcm92aXNpb25pbmcuCgoMCgUE
AAQAARIDVQcWCh0KBgQABAACABIDVwQlGg4gVW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgNX
BCAKDgoHBAAEAAIAAhIDVyMkClUKBgQABAACARIDWgQeGkYgVGhlIGNhbGxlciBpcyBwcm92
aXNpb25pbmcgZm9yIHRoZSBuZXcgR2VtaW5pIEVudGVycHJpc2UgZXhwZXJpZW5jZS4KCg4K
BwQABAACAQESA1oEGQoOCgcEAAQAAgECEgNaHB0KWgoGBAAEAAICEgNeBCAaSyBUaGUgY2Fs
bGVyIGlzIHByb3Zpc2lvbmluZyBmb3IgdGhlIGNsYXNzaWMgR2VtaW5pIEVudGVycHJpc2UK
IGV4cGVyaWVuY2UuCgoOCgcEAAQAAgIBEgNeBBsKDgoHBAAEAAICAhIDXh4fCpcBCgQEAAIA
EgRkAmkEGogBIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgYQogW1Byb2plY3Rd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlByb2plY3RdLCBzdWNoIGFz
CiBgcHJvamVjdHMve3Byb2plY3RfaWRfb3JfbnVtYmVyfWAuCgoMCgUEAAIABRIDZAIICgwK
BQQAAgABEgNkCQ0KDAoFBAACAAMSA2QQEQoNCgUEAAIACBIEZBJpAwoPCggEAAIACJwIABID
ZQQqCg8KBwQAAgAInwgSBGYEaAUKtQEKBAQAAgESA24CShqnASBSZXF1aXJlZC4gU2V0IHRv
IGB0cnVlYCB0byBzcGVjaWZ5IHRoYXQgY2FsbGVyIGhhcyByZWFkIGFuZCB3b3VsZCBsaWtl
IHRvCiBnaXZlIGNvbnNlbnQgdG8gdGhlIFtUZXJtcyBmb3IgZGF0YQogdXNlXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RhdGEtdXNlLXRlcm1zKS4KCgwKBQQAAgEFEgNu
AgYKDAoFBAACAQESA24HHAoMCgUEAAIBAxIDbh8gCgwKBQQAAgEIEgNuIUkKDwoIBAACAQic
CAASA24iSArwAQoEBAACAhIDdQJNGuIBIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiBvZiB0aGUg
W1Rlcm1zIGZvciBkYXRhCiB1c2VdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXRhaWwv
ZGF0YS11c2UtdGVybXMpIHRoYXQgY2FsbGVyIGhhcyByZWFkCiBhbmQgd291bGQgbGlrZSB0
byBnaXZlIGNvbnNlbnQgdG8uCgogQWNjZXB0YWJsZSB2ZXJzaW9uIGlzIGAyMDIyLTExLTIz
YCwgYW5kIHRoaXMgbWF5IGNoYW5nZSBvdmVyIHRpbWUuCgoMCgUEAAICBRIDdQIICgwKBQQA
AgIBEgN1CR8KDAoFBAACAgMSA3UiIwoMCgUEAAICCBIDdSRMCg8KCAQAAgIInAgAEgN1JUsK
MwoEBAACAxIDeAJGGiYgT3B0aW9uYWwuIFBhcmFtZXRlcnMgZm9yIEFnZW50c3BhY2UuCgoM
CgUEAAIDBhIDeAIMCgwKBQQAAgMBEgN4DRgKDAoFBAACAwMSA3gbHAoMCgUEAAIDCBIDeB1F
Cg8KCAQAAgMInAgAEgN4HkQKgAEKBAQAAgQSA3wCUBpzIE9wdGlvbmFsLiBUaGUgY2FsbGVy
IHN0YXRlcyB3aGV0aGVyIHRoZSBwcm92aXNpb25pbmcgaXMgZm9yIHRoZSBuZXcgb3IgdGhl
CiBjbGFzc2ljIEdlbWluaSBFbnRlcnByaXNlIGV4cGVyaWVuY2UuCgoMCgUEAAIEBhIDfAIR
CgwKBQQAAgQBEgN8EiIKDAoFBAACBAMSA3wlJgoMCgUEAAIECBIDfCdPCg8KCAQAAgQInAgA
EgN8KE4KxgEKBAQAAgUSBIEBAkQatwEgT3B0aW9uYWwuIFRoZSBpZGVudGl0eSBwcm92aWRl
ciBmb3IgdGhpcyBsb2NhdGlvbi4gV2hlbiBwcm92aWRlZCwgdGhlCiBsb2NhdGlvbidzIFtB
Y2xDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkFjbENvbmZp
Z10gaXMKIHNldCBmcm9tIGl0IGFzIHBhcnQgb2YgcHJvdmlzaW9uaW5nLgoKDQoFBAACBQYS
BIEBAgsKDQoFBAACBQESBIEBDBYKDQoFBAACBQMSBIEBGRoKDQoFBAACBQgSBIEBG0MKEAoI
BAACBQicCAASBIEBHEIKsAUKBAQAAgYSBI8BAkcaoQUgT3B0aW9uYWwuIFJ1bnMgb25seSB0
aGUgY29tbW9uIHByb2plY3QtbGV2ZWwgcHJlLXByb3Zpc2lvbmluZyBzdGVwcwogKHNlcnZp
Y2UgYWdlbnRzLCBhZ2VudCBpZGVudGl0eSBwb29scywgcHJvamVjdC1zY29wZWQgZXh0ZW5z
aW9uIGJpbmRpbmdzLAogQXBwIEh1YiByZWdpc3RyeSwgU29iaSBhZ2VudCBkZWZhdWx0IGlk
ZW50aXR5LCBhbmQgU29iaSBkZWZhdWx0IE1vZGVsIEFybW9yCiB0ZW1wbGF0ZSkgd2l0aG91
dCByZWFkaW5nIG9yIHdyaXRpbmcgdGhlIEN1c3RvbWVyLCBDb2xsZWN0aW9uLCBvciBVc2Vy
U3RvcmUKIHRhYmxlcywgQ2FwYWJpbGl0eUNvbmZpZywgdGVuYW50IHByb2plY3QsIGRlZmF1
bHQgZW5naW5lLCBvciB0cmlhbCBsaWNlbnNlcwogd2hlbiBgdHJ1ZWAuCgogQXNzdW1lcyBu
byBjdXN0b21lciBleGlzdHMgeWV0LiBDdXN0b21lci1sZXZlbCBvciBub24tU09CSSBmaWVs
ZHMKIChgYWNjZXB0X2RhdGFfdXNlX3Rlcm1zYCwgYGRhdGFfdXNlX3Rlcm1zX3ZlcnNpb25g
LCBgc2Fhc19wYXJhbXNgLAogYGlkcF9jb25maWdgLCBhbmQgYFBST1ZJU0lPTl9JTlRFTlRf
TEVHQUNZYCkgYXJlIHJlamVjdGVkIHdpdGgKIGBJTlZBTElEX0FSR1VNRU5UYCwgYW5kIHRo
ZSByZXR1cm5lZCBjb21wbGV0ZWQgYE9wZXJhdGlvbmAgaGFzIGFuIGVtcHR5CiByZXNwb25z
ZS4KCg0KBQQAAgYFEgSPAQIGCg0KBQQAAgYBEgSPAQcZCg0KBQQAAgYDEgSPARwdCg0KBQQA
AgYIEgSPAR5GChAKCAQAAgYInAgAEgSPAR9FCkUKAgQBEgSTAQAjGjkgTWV0YWRhdGEgYXNz
b2NpYXRlZCB3aXRoIGEgcHJvamVjdCBwcm92aXNpb24gb3BlcmF0aW9uLgoKCwoDBAEBEgST
AQggYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest ===
    # Fields for ProvisionProjectRequest
    # Field: name Type: 9 ()
    # Field: accept_data_use_terms Type: 8 ()
    # Field: data_use_terms_version Type: 9 ()
    # Field: saas_params Type: 11 (.google.cloud.discoveryengine.v1beta.ProvisionProjectRequest.SaasParams)
    # Field: provision_intent Type: 14 (.google.cloud.discoveryengine.v1beta.ProvisionProjectRequest.ProvisionIntent)
    # Field: idp_config Type: 11 (.google.cloud.discoveryengine.v1beta.IdpConfig)
    # Field: pre_provision_mode Type: 8 ()

# Enum: ProvisionProjectRequest::ProvisionIntent
our $ProvisionProjectRequest_PROVISION_INTENT_UNSPECIFIED = 0;
our $ProvisionProjectRequest_PROVISION_INTENT_SOBI = 1;
our $ProvisionProjectRequest_PROVISION_INTENT_LEGACY = 2;

# === Message: Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectMetadata ===
    # Fields for ProvisionProjectMetadata

# === Service Client: Google::Cloud::Discoveryengine::V1beta::ProjectService::ProjectServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::ProjectService::ProjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::ProjectService::ProjectServiceClient

Client stub representing the remote C<ProjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub provision_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ProjectService',
        method         => 'ProvisionProject',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::ProjectService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/project_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::ProjectService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest->new({
        name => $name,
        accept_data_use_terms => $accept_data_use_terms,
        data_use_terms_version => $data_use_terms_version,
        saas_params => $saas_params,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/project_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest

Request for
[ProjectService.ProvisionProject][google.cloud.discoveryengine.v1beta.ProjectService.ProvisionProject]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of a
[Project][google.cloud.discoveryengine.v1beta.Project], such as
`projects/{project_id_or_number}`.

=item * C<< $msg->accept_data_use_terms() >> / C<< $msg->accept_data_use_terms($value) >>

Type: C<Bool>

Required. Set to `true` to specify that caller has read and would like to
give consent to the [Terms for data
use](https://cloud.google.com/retail/data-use-terms).

=item * C<< $msg->data_use_terms_version() >> / C<< $msg->data_use_terms_version($value) >>

Type: C<String>

Required. The version of the [Terms for data
use](https://cloud.google.com/retail/data-use-terms) that caller has read
and would like to give consent to.

Acceptable version is `2022-11-23`, and this may change over time.

=item * C<< $msg->saas_params() >> / C<< $msg->saas_params($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest::SaasParams>)

Optional. Parameters for Agentspace.

=item * C<< $msg->provision_intent() >> / C<< $msg->provision_intent($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::ProvisionProjectRequest::ProvisionIntent>)

Optional. The caller states whether the provisioning is for the new or the
classic Gemini Enterprise experience.

=item * C<< $msg->idp_config() >> / C<< $msg->idp_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig>)

Optional. The identity provider for this location. When provided, the
location's [AclConfig][google.cloud.discoveryengine.v1beta.AclConfig] is
set from it as part of provisioning.

=item * C<< $msg->pre_provision_mode() >> / C<< $msg->pre_provision_mode($value) >>

Type: C<Bool>

Optional. Runs only the common project-level pre-provisioning steps
(service agents, agent identity pools, project-scoped extension bindings,
App Hub registry, Sobi agent default identity, and Sobi default Model Armor
template) without reading or writing the Customer, Collection, or UserStore
tables, CapabilityConfig, tenant project, default engine, or trial licenses
when `true`.

Assumes no customer exists yet. Customer-level or non-SOBI fields
(`accept_data_use_terms`, `data_use_terms_version`, `saas_params`,
`idp_config`, and `PROVISION_INTENT_LEGACY`) are rejected with
`INVALID_ARGUMENT`, and the returned completed `Operation` has an empty
response.

=back

=head3 Enum: ProvisionProjectRequest::ProvisionIntent

=over 4

=item * C<PROVISION_INTENT_UNSPECIFIED> => C<0>

=item * C<PROVISION_INTENT_SOBI> => C<1>

=item * C<PROVISION_INTENT_LEGACY> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectMetadata

Metadata associated with a project provision operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::ProjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
