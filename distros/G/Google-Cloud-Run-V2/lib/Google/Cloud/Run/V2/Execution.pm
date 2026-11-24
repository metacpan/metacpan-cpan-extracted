package Google::Cloud::Run::V2::Execution;

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
    eval { require Google::Cloud::Run::V2::Condition };
    eval { require Google::Cloud::Run::V2::TaskTemplate };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvcnVuL3YyL2V4ZWN1dGlvbi5wcm90bxITZ29vZ2xlLmNsb3VkLnJ1
bi52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQu
cHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHWdvb2dsZS9hcGkvbGF1
bmNoX3N0YWdlLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiNnb29nbGUvY2xv
dWQvcnVuL3YyL2NvbmRpdGlvbi5wcm90bxonZ29vZ2xlL2Nsb3VkL3J1bi92Mi90YXNrX3Rl
bXBsYXRlLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byJPChNHZXRFeGVjdXRpb25SZXF1ZXN0EjgK
BG5hbWUYASABKAlCJOBBAvpBHgoccnVuLmdvb2dsZWFwaXMuY29tL0V4ZWN1dGlvblIEbmFt
ZSK0AQoVTGlzdEV4ZWN1dGlvbnNSZXF1ZXN0EjwKBnBhcmVudBgBIAEoCUIk4EEC+kEeEhxy
dW4uZ29vZ2xlYXBpcy5jb20vRXhlY3V0aW9uUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgF
UghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SIQoMc2hvd19kZWxl
dGVkGAQgASgIUgtzaG93RGVsZXRlZCKAAQoWTGlzdEV4ZWN1dGlvbnNSZXNwb25zZRI+Cgpl
eGVjdXRpb25zGAEgAygLMh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5FeGVjdXRpb25SCmV4ZWN1
dGlvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIosBChZEZWxl
dGVFeGVjdXRpb25SZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccnVuLmdvb2dsZWFw
aXMuY29tL0V4ZWN1dGlvblIEbmFtZRIjCg12YWxpZGF0ZV9vbmx5GAIgASgIUgx2YWxpZGF0
ZU9ubHkSEgoEZXRhZxgDIAEoCVIEZXRhZyKLAQoWQ2FuY2VsRXhlY3V0aW9uUmVxdWVzdBI4
CgRuYW1lGAEgASgJQiTgQQL6QR4KHHJ1bi5nb29nbGVhcGlzLmNvbS9FeGVjdXRpb25SBG5h
bWUSIwoNdmFsaWRhdGVfb25seRgCIAEoCFIMdmFsaWRhdGVPbmx5EhIKBGV0YWcYAyABKAlS
BGV0YWcivw0KCUV4ZWN1dGlvbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSFQoDdWlkGAIg
ASgJQgPgQQNSA3VpZBIdCgdjcmVhdG9yGCAgASgJQgPgQQNSB2NyZWF0b3ISIwoKZ2VuZXJh
dGlvbhgDIAEoA0ID4EEDUgpnZW5lcmF0aW9uEkcKBmxhYmVscxgEIAMoCzIqLmdvb2dsZS5j
bG91ZC5ydW4udjIuRXhlY3V0aW9uLkxhYmVsc0VudHJ5QgPgQQNSBmxhYmVscxJWCgthbm5v
dGF0aW9ucxgFIAMoCzIvLmdvb2dsZS5jbG91ZC5ydW4udjIuRXhlY3V0aW9uLkFubm90YXRp
b25zRW50cnlCA+BBA1ILYW5ub3RhdGlvbnMSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSPgoKc3RhcnRfdGltZRgW
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEkgKD2Nv
bXBsZXRpb25fdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IO
Y29tcGxldGlvblRpbWUSQAoLdXBkYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLZGVsZXRlX3RpbWUYCSABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmRlbGV0ZVRpbWUSQAoLZXhwaXJlX3RpbWUY
CiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmV4cGlyZVRpbWUSOgoM
bGF1bmNoX3N0YWdlGAsgASgOMhcuZ29vZ2xlLmFwaS5MYXVuY2hTdGFnZVILbGF1bmNoU3Rh
Z2USMAoDam9iGAwgASgJQh7gQQP6QRgKFnJ1bi5nb29nbGVhcGlzLmNvbS9Kb2JSA2pvYhIl
CgtwYXJhbGxlbGlzbRgNIAEoBUID4EEDUgtwYXJhbGxlbGlzbRIiCgp0YXNrX2NvdW50GA4g
ASgFQgPgQQNSCXRhc2tDb3VudBJCCgh0ZW1wbGF0ZRgPIAEoCzIhLmdvb2dsZS5jbG91ZC5y
dW4udjIuVGFza1RlbXBsYXRlQgPgQQNSCHRlbXBsYXRlEiUKC3JlY29uY2lsaW5nGBAgASgI
QgPgQQNSC3JlY29uY2lsaW5nEkMKCmNvbmRpdGlvbnMYESADKAsyHi5nb29nbGUuY2xvdWQu
cnVuLnYyLkNvbmRpdGlvbkID4EEDUgpjb25kaXRpb25zEjQKE29ic2VydmVkX2dlbmVyYXRp
b24YEiABKANCA+BBA1ISb2JzZXJ2ZWRHZW5lcmF0aW9uEigKDXJ1bm5pbmdfY291bnQYEyAB
KAVCA+BBA1IMcnVubmluZ0NvdW50EiwKD3N1Y2NlZWRlZF9jb3VudBgUIAEoBUID4EEDUg5z
dWNjZWVkZWRDb3VudBImCgxmYWlsZWRfY291bnQYFSABKAVCA+BBA1ILZmFpbGVkQ291bnQS
LAoPY2FuY2VsbGVkX2NvdW50GBggASgFQgPgQQNSDmNhbmNlbGxlZENvdW50EigKDXJldHJp
ZWRfY291bnQYGSABKAVCA+BBA1IMcmV0cmllZENvdW50EhwKB2xvZ191cmkYGiABKAlCA+BB
A1IGbG9nVXJpEigKDXNhdGlzZmllc19wenMYGyABKAhCA+BBA1IMc2F0aXNmaWVzUHpzEhsK
BmNsaWVudBghIAEoCUID4EEDUgZjbGllbnQSKgoOY2xpZW50X3ZlcnNpb24YIiABKAlCA+BB
A1INY2xpZW50VmVyc2lvbhIXCgRldGFnGGMgASgJQgPgQQNSBGV0YWcaOQoLTGFiZWxzRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARo+ChBBbm5v
dGF0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToC
OAE6b+pBbAoccnVuLmdvb2dsZWFwaXMuY29tL0V4ZWN1dGlvbhJJcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2pvYnMve2pvYn0vZXhlY3V0aW9ucy97ZXhlY3V0
aW9ufVIBATKDBwoKRXhlY3V0aW9ucxKeAQoMR2V0RXhlY3V0aW9uEiguZ29vZ2xlLmNsb3Vk
LnJ1bi52Mi5HZXRFeGVjdXRpb25SZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5FeGVj
dXRpb24iRILT5JMCNxI1L3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovam9icy8q
L2V4ZWN1dGlvbnMvKn3aQQRuYW1lErEBCg5MaXN0RXhlY3V0aW9ucxIqLmdvb2dsZS5jbG91
ZC5ydW4udjIuTGlzdEV4ZWN1dGlvbnNSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLnJ1bi52Mi5M
aXN0RXhlY3V0aW9uc1Jlc3BvbnNlIkaC0+STAjcSNS92Mi97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyovam9icy8qfS9leGVjdXRpb25z2kEGcGFyZW50ErwBCg9EZWxldGVFeGVj
dXRpb24SKy5nb29nbGUuY2xvdWQucnVuLnYyLkRlbGV0ZUV4ZWN1dGlvblJlcXVlc3QaHS5n
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIl2C0+STAjcqNS92Mi97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2pvYnMvKi9leGVjdXRpb25zLyp92kEEbmFtZcpBFgoJRXhlY3V0
aW9uEglFeGVjdXRpb24SxgEKD0NhbmNlbEV4ZWN1dGlvbhIrLmdvb2dsZS5jbG91ZC5ydW4u
djIuQ2FuY2VsRXhlY3V0aW9uUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24iZ4LT5JMCQSI8L3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovam9icy8qL2V4
ZWN1dGlvbnMvKn06Y2FuY2VsOgEq2kEEbmFtZcpBFgoJRXhlY3V0aW9uEglFeGVjdXRpb24a
lwHKQRJydW4uZ29vZ2xlYXBpcy5jb23SQX9odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvcnVu
LGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvcnVuLnJlYWRvbmx5QlYKF2NvbS5n
b29nbGUuY2xvdWQucnVuLnYyQg5FeGVjdXRpb25Qcm90b1ABWiljbG91ZC5nb29nbGUuY29t
L2dvL3J1bi9hcGl2Mi9ydW5wYjtydW5wYkq+WwoHEgUOAMMCAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQAnCgkKAgMEEgMWACMKCQoCAwUSAxcALQoJCgIDBhIDGAAxCgkK
AgMHEgMZAC0KCQoCAwgSAxoAKQoICgEIEgMcAEAKCQoCCAsSAxwAQAoICgEIEgMdACIKCQoC
CAoSAx0AIgoICgEIEgMeAC8KCQoCCAgSAx4ALwoICgEIEgMfADAKCQoCCAESAx8AMAo0CgIG
ABIEIgBUARooIENsb3VkIFJ1biBFeGVjdXRpb24gQ29udHJvbCBQbGFuZSBBUEkuCgoKCgMG
AAESAyIIEgoKCgMGAAMSAyMCOgoMCgUGAAOZCBIDIwI6CgsKAwYAAxIEJAInNQoNCgUGAAOa
CBIEJAInNQo0CgQGAAIAEgQqAi8DGiYgR2V0cyBpbmZvcm1hdGlvbiBhYm91dCBhbiBFeGVj
dXRpb24uCgoMCgUGAAIAARIDKgYSCgwKBQYAAgACEgMqEyYKDAoFBgACAAMSAyoxOgoNCgUG
AAIABBIEKwQtBgoRCgkGAAIABLDKvCISBCsELQYKDAoFBgACAAQSAy4EMgoPCggGAAIABJsI
ABIDLgQyCl4KBAYAAgESBDMCOAMaUCBMaXN0cyBFeGVjdXRpb25zIGZyb20gYSBKb2IuIFJl
c3VsdHMgYXJlIHNvcnRlZCBieSBjcmVhdGlvbiB0aW1lLAogZGVzY2VuZGluZy4KCgwKBQYA
AgEBEgMzBhQKDAoFBgACAQISAzMVKgoMCgUGAAIBAxIDMzVLCg0KBQYAAgEEEgQ0BDYGChEK
CQYAAgEEsMq8IhIENAQ2BgoMCgUGAAIBBBIDNwQ0Cg8KCAYAAgEEmwgAEgM3BDQKJQoEBgAC
AhIEOwJFAxoXIERlbGV0ZXMgYW4gRXhlY3V0aW9uLgoKDAoFBgACAgESAzsGFQoMCgUGAAIC
AhIDOxYsCgwKBQYAAgIDEgM8DysKDQoFBgACAgQSBD0EPwYKEQoJBgACAgSwyrwiEgQ9BD8G
CgwKBQYAAgIEEgNABDIKDwoIBgACAgSbCAASA0AEMgoNCgUGAAICBBIEQQREBgoPCgcGAAIC
BJkIEgRBBEQGCiUKBAYAAgMSBEgCUwMaFyBDYW5jZWxzIGFuIEV4ZWN1dGlvbi4KCgwKBQYA
AgMBEgNIBhUKDAoFBgACAwISA0gWLAoMCgUGAAIDAxIDSQ8rCg0KBQYAAgMEEgRKBE0GChEK
CQYAAgMEsMq8IhIESgRNBgoMCgUGAAIDBBIDTgQyCg8KCAYAAgMEmwgAEgNOBDIKDQoFBgAC
AwQSBE8EUgYKDwoHBgACAwSZCBIETwRSBgpJCgIEABIEVwBgARo9IFJlcXVlc3QgbWVzc2Fn
ZSBmb3Igb2J0YWluaW5nIGEgRXhlY3V0aW9uIGJ5IGl0cyBmdWxsIG5hbWUuCgoKCgMEAAES
A1cIGwrBAQoEBAACABIEXAJfBBqyASBSZXF1aXJlZC4gVGhlIGZ1bGwgbmFtZSBvZiB0aGUg
RXhlY3V0aW9uLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9qb2JzL3tqb2J9L2V4ZWN1dGlvbnMve2V4ZWN1dGlvbn1gLAogd2hlcmUgYHtw
cm9qZWN0fWAgY2FuIGJlIHByb2plY3QgaWQgb3IgbnVtYmVyLgoKDAoFBAACAAUSA1wCCAoM
CgUEAAIAARIDXAkNCgwKBQQAAgADEgNcEBEKDQoFBAACAAgSBFwSXwMKDwoIBAACAAicCAAS
A10EKgoOCgcEAAIACJ8IEgNeBE4KQgoCBAESBGMAeAEaNiBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IHJldHJpZXZpbmcgYSBsaXN0IG9mIEV4ZWN1dGlvbnMuCgoKCgMEAQESA2MIHQqFAgoEBAEC
ABIEaAJtBBr2ASBSZXF1aXJlZC4gVGhlIEV4ZWN1dGlvbiBmcm9tIHdoaWNoIHRoZSBFeGVj
dXRpb25zIHNob3VsZCBiZSBsaXN0ZWQuCiBUbyBsaXN0IGFsbCBFeGVjdXRpb25zIGFjcm9z
cyBKb2JzLCB1c2UgIi0iIGluc3RlYWQgb2YgSm9iIG5hbWUuCiBGb3JtYXQ6IGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vam9icy97am9ifWAsIHdoZXJlCiBg
e3Byb2plY3R9YCBjYW4gYmUgcHJvamVjdCBpZCBvciBudW1iZXIuCgoMCgUEAQIABRIDaAII
CgwKBQQBAgABEgNoCQ8KDAoFBAECAAMSA2gSEwoNCgUEAQIACBIEaBRtAwoPCggEAQIACJwI
ABIDaQQqCg8KBwQBAgAInwgSBGoEbAUKQwoEBAECARIDcAIWGjYgTWF4aW11bSBudW1iZXIg
b2YgRXhlY3V0aW9ucyB0byByZXR1cm4gaW4gdGhpcyBjYWxsLgoKDAoFBAECAQUSA3ACBwoM
CgUEAQIBARIDcAgRCgwKBQQBAgEDEgNwFBUKbgoEBAECAhIDdAIYGmEgQSBwYWdlIHRva2Vu
IHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIHRvIExpc3RFeGVjdXRpb25zLgogQWxs
IG90aGVyIHBhcmFtZXRlcnMgbXVzdCBtYXRjaC4KCgwKBQQBAgIFEgN0AggKDAoFBAECAgES
A3QJEwoMCgUEAQICAxIDdBYXClkKBAQBAgMSA3cCGBpMIElmIHRydWUsIHJldHVybnMgZGVs
ZXRlZCAoYnV0IHVuZXhwaXJlZCkgcmVzb3VyY2VzIGFsb25nIHdpdGggYWN0aXZlIG9uZXMu
CgoMCgUEAQIDBRIDdwIGCgwKBQQBAgMBEgN3BxMKDAoFBAECAwMSA3cWFwpACgIEAhIFewCC
AQEaMyBSZXNwb25zZSBtZXNzYWdlIGNvbnRhaW5pbmcgYSBsaXN0IG9mIEV4ZWN1dGlvbnMu
CgoKCgMEAgESA3sIHgowCgQEAgIAEgN9AiQaIyBUaGUgcmVzdWx0aW5nIGxpc3Qgb2YgRXhl
Y3V0aW9ucy4KCgwKBQQCAgAEEgN9AgoKDAoFBAICAAYSA30LFAoMCgUEAgIAARIDfRUfCgwK
BQQCAgADEgN9IiMKfwoEBAICARIEgQECHRpxIEEgdG9rZW4gaW5kaWNhdGluZyB0aGVyZSBh
cmUgbW9yZSBpdGVtcyB0aGFuIHBhZ2Vfc2l6ZS4gVXNlIGl0IGluIHRoZSBuZXh0CiBMaXN0
RXhlY3V0aW9ucyByZXF1ZXN0IHRvIGNvbnRpbnVlLgoKDQoFBAICAQUSBIEBAggKDQoFBAIC
AQESBIEBCRgKDQoFBAICAQMSBIEBGxwKOgoCBAMSBoUBAJYBARosIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgZGVsZXRpbmcgYW4gRXhlY3V0aW9uLgoKCwoDBAMBEgSFAQgeCsgBCgQEAwIAEgaK
AQKNAQQatwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBFeGVjdXRpb24gdG8gZGVsZXRl
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9q
b2JzL3tqb2J9L2V4ZWN1dGlvbnMve2V4ZWN1dGlvbn1gLAogd2hlcmUgYHtwcm9qZWN0fWAg
Y2FuIGJlIHByb2plY3QgaWQgb3IgbnVtYmVyLgoKDQoFBAMCAAUSBIoBAggKDQoFBAMCAAES
BIoBCQ0KDQoFBAMCAAMSBIoBEBEKDwoFBAMCAAgSBooBEo0BAwoQCggEAwIACJwIABIEiwEE
KgoPCgcEAwIACJ8IEgSMAQROCmgKBAQDAgESBJEBAhkaWiBJbmRpY2F0ZXMgdGhhdCB0aGUg
cmVxdWVzdCBzaG91bGQgYmUgdmFsaWRhdGVkIHdpdGhvdXQgYWN0dWFsbHkKIGRlbGV0aW5n
IGFueSByZXNvdXJjZXMuCgoNCgUEAwIBBRIEkQECBgoNCgUEAwIBARIEkQEHFAoNCgUEAwIB
AxIEkQEXGAqTAQoEBAMCAhIElQECEhqEASBBIHN5c3RlbS1nZW5lcmF0ZWQgZmluZ2VycHJp
bnQgZm9yIHRoaXMgdmVyc2lvbiBvZiB0aGUgcmVzb3VyY2UuCiBUaGlzIG1heSBiZSB1c2Vk
IHRvIGRldGVjdCBtb2RpZmljYXRpb24gY29uZmxpY3QgZHVyaW5nIHVwZGF0ZXMuCgoNCgUE
AwICBRIElQECCAoNCgUEAwICARIElQEJDQoNCgUEAwICAxIElQEQEQo6CgIEBBIGmQEAqgEB
GiwgUmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhbiBFeGVjdXRpb24uCgoLCgMEBAES
BJkBCB4KyAEKBAQEAgASBp4BAqEBBBq3ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIEV4
ZWN1dGlvbiB0byBjYW5jZWwuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2pvYnMve2pvYn0vZXhlY3V0aW9ucy97ZXhlY3V0aW9ufWAsCiB3
aGVyZSBge3Byb2plY3R9YCBjYW4gYmUgcHJvamVjdCBpZCBvciBudW1iZXIuCgoNCgUEBAIA
BRIEngECCAoNCgUEBAIAARIEngEJDQoNCgUEBAIAAxIEngEQEQoPCgUEBAIACBIGngESoQED
ChAKCAQEAgAInAgAEgSfAQQqCg8KBwQEAgAInwgSBKABBE4KagoEBAQCARIEpQECGRpcIElu
ZGljYXRlcyB0aGF0IHRoZSByZXF1ZXN0IHNob3VsZCBiZSB2YWxpZGF0ZWQgd2l0aG91dCBh
Y3R1YWxseQogY2FuY2VsbGluZyBhbnkgcmVzb3VyY2VzLgoKDQoFBAQCAQUSBKUBAgYKDQoF
BAQCAQESBKUBBxQKDQoFBAQCAQMSBKUBFxgKkwEKBAQEAgISBKkBAhIahAEgQSBzeXN0ZW0t
Z2VuZXJhdGVkIGZpbmdlcnByaW50IGZvciB0aGlzIHZlcnNpb24gb2YgdGhlIHJlc291cmNl
LgogVGhpcyBtYXkgYmUgdXNlZCB0byBkZXRlY3QgbW9kaWZpY2F0aW9uIGNvbmZsaWN0IGR1
cmluZyB1cGRhdGVzLgoKDQoFBAQCAgUSBKkBAggKDQoFBAQCAgESBKkBCQ0KDQoFBAQCAgMS
BKkBEBEKsAEKAgQFEgavAQDDAgEaoQEgRXhlY3V0aW9uIHJlcHJlc2VudHMgdGhlIGNvbmZp
Z3VyYXRpb24gb2YgYSBzaW5nbGUgZXhlY3V0aW9uLiBBIGV4ZWN1dGlvbiBhbgogaW1tdXRh
YmxlIHJlc291cmNlIHRoYXQgcmVmZXJlbmNlcyBhIGNvbnRhaW5lciBpbWFnZSB3aGljaCBp
cyBydW4gdG8KIGNvbXBsZXRpb24uCgoLCgMEBQESBK8BCBEKDQoDBAUHEgawAQK0AQQKDwoF
BAUHnQgSBrABArQBBAo/CgQEBQIAEgS3AQI+GjEgT3V0cHV0IG9ubHkuIFRoZSB1bmlxdWUg
bmFtZSBvZiB0aGlzIEV4ZWN1dGlvbi4KCg0KBQQFAgAFEgS3AQIICg0KBQQFAgABEgS3AQkN
Cg0KBQQFAgADEgS3ARARCg0KBQQFAgAIEgS3ARI9ChAKCAQFAgAInAgAEgS3ARM8CrIBCgQE
BQIBEgS8AQI9GqMBIE91dHB1dCBvbmx5LiBTZXJ2ZXIgYXNzaWduZWQgdW5pcXVlIGlkZW50
aWZpZXIgZm9yIHRoZSBFeGVjdXRpb24uIFRoZSB2YWx1ZQogaXMgYSBVVUlENCBzdHJpbmcg
YW5kIGd1YXJhbnRlZWQgdG8gcmVtYWluIHVuY2hhbmdlZCB1bnRpbCB0aGUgcmVzb3VyY2Ug
aXMKIGRlbGV0ZWQuCgoNCgUEBQIBBRIEvAECCAoNCgUEBQIBARIEvAEJDAoNCgUEBQIBAxIE
vAEPEAoNCgUEBQIBCBIEvAERPAoQCggEBQIBCJwIABIEvAESOwpICgQEBQICEgS/AQJCGjog
T3V0cHV0IG9ubHkuIEVtYWlsIGFkZHJlc3Mgb2YgdGhlIGF1dGhlbnRpY2F0ZWQgY3JlYXRv
ci4KCg0KBQQFAgIFEgS/AQIICg0KBQQFAgIBEgS/AQkQCg0KBQQFAgIDEgS/ARMVCg0KBQQF
AgIIEgS/ARZBChAKCAQFAgIInAgAEgS/ARdACnMKBAQFAgMSBMMBAkMaZSBPdXRwdXQgb25s
eS4gQSBudW1iZXIgdGhhdCBtb25vdG9uaWNhbGx5IGluY3JlYXNlcyBldmVyeSB0aW1lIHRo
ZSB1c2VyCiBtb2RpZmllcyB0aGUgZGVzaXJlZCBzdGF0ZS4KCg0KBQQFAgMFEgTDAQIHCg0K
BQQFAgMBEgTDAQgSCg0KBQQFAgMDEgTDARUWCg0KBQQFAgMIEgTDARdCChAKCAQFAgMInAgA
EgTDARhBCrYDCgQEBQIEEgTLAQJNGqcDIE91dHB1dCBvbmx5LiBVbnN0cnVjdHVyZWQga2V5
IHZhbHVlIG1hcCB0aGF0IGNhbiBiZSB1c2VkIHRvIG9yZ2FuaXplIGFuZAogY2F0ZWdvcml6
ZSBvYmplY3RzLiBVc2VyLXByb3ZpZGVkIGxhYmVscyBhcmUgc2hhcmVkIHdpdGggR29vZ2xl
J3MgYmlsbGluZwogc3lzdGVtLCBzbyB0aGV5IGNhbiBiZSB1c2VkIHRvIGZpbHRlciwgb3Ig
YnJlYWsgZG93biBiaWxsaW5nIGNoYXJnZXMgYnkKIHRlYW0sIGNvbXBvbmVudCwgZW52aXJv
bm1lbnQsIHN0YXRlLCBldGMuIEZvciBtb3JlIGluZm9ybWF0aW9uLCB2aXNpdAogaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGluZy1tYW5h
Z2luZy1sYWJlbHMgb3IKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9ydW4vZG9jcy9jb25m
aWd1cmluZy9sYWJlbHMKCg0KBQQFAgQGEgTLAQIVCg0KBQQFAgQBEgTLARYcCg0KBQQFAgQD
EgTLAR8gCg0KBQQFAgQIEgTLASFMChAKCAQFAgQInAgAEgTLASJLCscBCgQEBQIFEgbRAQLS
ATIatgEgT3V0cHV0IG9ubHkuIFVuc3RydWN0dXJlZCBrZXkgdmFsdWUgbWFwIHRoYXQgbWF5
CiBiZSBzZXQgYnkgZXh0ZXJuYWwgdG9vbHMgdG8gc3RvcmUgYW5kIGFyYml0cmFyeSBtZXRh
ZGF0YS4KIFRoZXkgYXJlIG5vdCBxdWVyeWFibGUgYW5kIHNob3VsZCBiZSBwcmVzZXJ2ZWQK
IHdoZW4gbW9kaWZ5aW5nIG9iamVjdHMuCgoNCgUEBQIFBhIE0QECFQoNCgUEBQIFARIE0QEW
IQoNCgUEBQIFAxIE0QEkJQoNCgUEBQIFCBIE0gEGMQoQCggEBQIFCJwIABIE0gEHMArFAQoE
BAUCBhIG1wEC2AEyGrQBIE91dHB1dCBvbmx5LiBSZXByZXNlbnRzIHRpbWUgd2hlbiB0aGUg
ZXhlY3V0aW9uIHdhcyBhY2tub3dsZWRnZWQgYnkgdGhlCiBleGVjdXRpb24gY29udHJvbGxl
ci4gSXQgaXMgbm90IGd1YXJhbnRlZWQgdG8gYmUgc2V0IGluIGhhcHBlbnMtYmVmb3JlCiBv
cmRlciBhY3Jvc3Mgc2VwYXJhdGUgb3BlcmF0aW9ucy4KCg0KBQQFAgYGEgTXAQIbCg0KBQQF
AgYBEgTXARwnCg0KBQQFAgYDEgTXASorCg0KBQQFAgYIEgTYAQYxChAKCAQFAgYInAgAEgTY
AQcwCqcBCgQEBQIHEgbdAQLeATIalgEgT3V0cHV0IG9ubHkuIFJlcHJlc2VudHMgdGltZSB3
aGVuIHRoZSBleGVjdXRpb24gc3RhcnRlZCB0byBydW4uCiBJdCBpcyBub3QgZ3VhcmFudGVl
ZCB0byBiZSBzZXQgaW4gaGFwcGVucy1iZWZvcmUgb3JkZXIgYWNyb3NzIHNlcGFyYXRlCiBv
cGVyYXRpb25zLgoKDQoFBAUCBwYSBN0BAhsKDQoFBAUCBwESBN0BHCYKDQoFBAUCBwMSBN0B
KSsKDQoFBAUCBwgSBN4BBjEKEAoIBAUCBwicCAASBN4BBzAKpQEKBAQFAggSBuIBAuMBMhqU
ASBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0aW1lIHdoZW4gdGhlIGV4ZWN1dGlvbiB3YXMg
Y29tcGxldGVkLiBJdCBpcyBub3QKIGd1YXJhbnRlZWQgdG8gYmUgc2V0IGluIGhhcHBlbnMt
YmVmb3JlIG9yZGVyIGFjcm9zcyBzZXBhcmF0ZSBvcGVyYXRpb25zLgoKDQoFBAUCCAYSBOIB
AhsKDQoFBAUCCAESBOIBHCsKDQoFBAUCCAMSBOIBLi8KDQoFBAUCCAgSBOMBBjEKEAoIBAUC
CAicCAASBOMBBzAKNgoEBAUCCRIG5gEC5wEyGiYgT3V0cHV0IG9ubHkuIFRoZSBsYXN0LW1v
ZGlmaWVkIHRpbWUuCgoNCgUEBQIJBhIE5gECGwoNCgUEBQIJARIE5gEcJwoNCgUEBQIJAxIE
5gEqKwoNCgUEBQIJCBIE5wEGMQoQCggEBQIJCJwIABIE5wEHMAqCAQoEBAUCChIG6wEC7AEy
GnIgT3V0cHV0IG9ubHkuIEZvciBhIGRlbGV0ZWQgcmVzb3VyY2UsIHRoZSBkZWxldGlvbiB0
aW1lLiBJdCBpcyBvbmx5CiBwb3B1bGF0ZWQgYXMgYSByZXNwb25zZSB0byBhIERlbGV0ZSBy
ZXF1ZXN0LgoKDQoFBAUCCgYSBOsBAhsKDQoFBAUCCgESBOsBHCcKDQoFBAUCCgMSBOsBKisK
DQoFBAUCCggSBOwBBjEKEAoIBAUCCgicCAASBOwBBzAKpgEKBAQFAgsSBvEBAvIBMhqVASBP
dXRwdXQgb25seS4gRm9yIGEgZGVsZXRlZCByZXNvdXJjZSwgdGhlIHRpbWUgYWZ0ZXIgd2hp
Y2ggaXQgd2lsbCBiZQogcGVybWFtZW50bHkgZGVsZXRlZC4gSXQgaXMgb25seSBwb3B1bGF0
ZWQgYXMgYSByZXNwb25zZSB0byBhIERlbGV0ZQogcmVxdWVzdC4KCg0KBQQFAgsGEgTxAQIb
Cg0KBQQFAgsBEgTxARwnCg0KBQQFAgsDEgTxASosCg0KBQQFAgsIEgTyAQYxChAKCAQFAgsI
nAgAEgTyAQcwCqwDCgQEBQIMEgT9AQIrGp0DIFRoZSBsZWFzdCBzdGFibGUgbGF1bmNoIHN0
YWdlIG5lZWRlZCB0byBjcmVhdGUgdGhpcyByZXNvdXJjZSwgYXMgZGVmaW5lZCBieQogW0dv
b2dsZSBDbG91ZCBQbGF0Zm9ybSBMYXVuY2gKIFN0YWdlc10oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL3Rlcm1zL2xhdW5jaC1zdGFnZXMpLiBDbG91ZCBSdW4gc3VwcG9ydHMKIGBBTFBI
QWAsIGBCRVRBYCwgYW5kIGBHQWAuCgogTm90ZSB0aGF0IHRoaXMgdmFsdWUgbWlnaHQgbm90
IGJlIHdoYXQgd2FzIHVzZWQKIGFzIGlucHV0LiBGb3IgZXhhbXBsZSwgaWYgQUxQSEEgd2Fz
IHByb3ZpZGVkIGFzIGlucHV0IGluIHRoZSBwYXJlbnQKIHJlc291cmNlLCBidXQgb25seSBC
RVRBIGFuZCBHQS1sZXZlbCBmZWF0dXJlcyBhcmUgdXNlZCwgdGhpcyBmaWVsZCB3aWxsIGJl
CiBCRVRBLgoKDQoFBAUCDAYSBP0BAhgKDQoFBAUCDAESBP0BGSUKDQoFBAUCDAMSBP0BKCoK
OgoEBAUCDRIGgAICgwIEGiogT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQg
Sm9iLgoKDQoFBAUCDQUSBIACAggKDQoFBAUCDQESBIACCQwKDQoFBAUCDQMSBIACDxEKDwoF
BAUCDQgSBoACEoMCAwoQCggEBQINCJwIABIEgQIELQoPCgcEBQINCJ8IEgSCAgRICuMCCgQE
BQIOEgSKAgJFGtQCIE91dHB1dCBvbmx5LiBTcGVjaWZpZXMgdGhlIG1heGltdW0gZGVzaXJl
ZCBudW1iZXIgb2YgdGFza3MgdGhlIGV4ZWN1dGlvbgogc2hvdWxkIHJ1biBhdCBhbnkgZ2l2
ZW4gdGltZS4gTXVzdCBiZSA8PSB0YXNrX2NvdW50LiBUaGUgYWN0dWFsIG51bWJlciBvZgog
dGFza3MgcnVubmluZyBpbiBzdGVhZHkgc3RhdGUgd2lsbCBiZSBsZXNzIHRoYW4gdGhpcyBu
dW1iZXIgd2hlbgogKCguc3BlYy50YXNrX2NvdW50IC0gLnN0YXR1cy5zdWNjZXNzZnVsKSA8
IC5zcGVjLnBhcmFsbGVsaXNtKSwgaS5lLiB3aGVuCiB0aGUgd29yayBsZWZ0IHRvIGRvIGlz
IGxlc3MgdGhhbiBtYXggcGFyYWxsZWxpc20uCgoNCgUEBQIOBRIEigICBwoNCgUEBQIOARIE
igIIEwoNCgUEBQIOAxIEigIWGAoNCgUEBQIOCBIEigIZRAoQCggEBQIOCJwIABIEigIaQwrW
AQoEBAUCDxIEjwICRBrHASBPdXRwdXQgb25seS4gU3BlY2lmaWVzIHRoZSBkZXNpcmVkIG51
bWJlciBvZiB0YXNrcyB0aGUgZXhlY3V0aW9uIHNob3VsZAogcnVuLiBTZXR0aW5nIHRvIDEg
bWVhbnMgdGhhdCBwYXJhbGxlbGlzbSBpcyBsaW1pdGVkIHRvIDEgYW5kIHRoZSBzdWNjZXNz
IG9mCiB0aGF0IHRhc2sgc2lnbmFscyB0aGUgc3VjY2VzcyBvZiB0aGUgZXhlY3V0aW9uLgoK
DQoFBAUCDwUSBI8CAgcKDQoFBAUCDwESBI8CCBIKDQoFBAUCDwMSBI8CFRcKDQoFBAUCDwgS
BI8CGEMKEAoIBAUCDwicCAASBI8CGUIKUgoEBAUCEBIEkgICSRpEIE91dHB1dCBvbmx5LiBU
aGUgdGVtcGxhdGUgdXNlZCB0byBjcmVhdGUgdGFza3MgZm9yIHRoaXMgZXhlY3V0aW9uLgoK
DQoFBAUCEAYSBJICAg4KDQoFBAUCEAESBJICDxcKDQoFBAUCEAMSBJICGhwKDQoFBAUCEAgS
BJICHUgKEAoIBAUCEAicCAASBJICHkcKygEKBAQFAhESBJcCAkQauwEgT3V0cHV0IG9ubHku
IEluZGljYXRlcyB3aGV0aGVyIHRoZSByZXNvdXJjZSdzIHJlY29uY2lsaWF0aW9uIGlzIHN0
aWxsIGluCiBwcm9ncmVzcy4gU2VlIGNvbW1lbnRzIGluIGBKb2IucmVjb25jaWxpbmdgIGZv
ciBhZGRpdGlvbmFsIGluZm9ybWF0aW9uIG9uCiByZWNvbmNpbGlhdGlvbiBwcm9jZXNzIGlu
IENsb3VkIFJ1bi4KCg0KBQQFAhEFEgSXAgIGCg0KBQQFAhEBEgSXAgcSCg0KBQQFAhEDEgSX
AhUXCg0KBQQFAhEIEgSXAhhDChAKCAQFAhEInAgAEgSXAhlCCq4BCgQEBQISEgacAgKdAjIa
nQEgT3V0cHV0IG9ubHkuIFRoZSBDb25kaXRpb24gb2YgdGhpcyBFeGVjdXRpb24sIGNvbnRh
aW5pbmcgaXRzIHJlYWRpbmVzcwogc3RhdHVzLCBhbmQgZGV0YWlsZWQgZXJyb3IgaW5mb3Jt
YXRpb24gaW4gY2FzZSBpdCBkaWQgbm90IHJlYWNoIHRoZSBkZXNpcmVkCiBzdGF0ZS4KCg0K
BQQFAhIEEgScAgIKCg0KBQQFAhIGEgScAgsUCg0KBQQFAhIBEgScAhUfCg0KBQQFAhIDEgSc
AiIkCg0KBQQFAhIIEgSdAgYxChAKCAQFAhIInAgAEgSdAgcwCqIBCgQEBQITEgSiAgJNGpMB
IE91dHB1dCBvbmx5LiBUaGUgZ2VuZXJhdGlvbiBvZiB0aGlzIEV4ZWN1dGlvbi4gU2VlIGNv
bW1lbnRzIGluCiBgcmVjb25jaWxpbmdgIGZvciBhZGRpdGlvbmFsIGluZm9ybWF0aW9uIG9u
IHJlY29uY2lsaWF0aW9uIHByb2Nlc3MgaW4gQ2xvdWQKIFJ1bi4KCg0KBQQFAhMFEgSiAgIH
Cg0KBQQFAhMBEgSiAggbCg0KBQQFAhMDEgSiAh4gCg0KBQQFAhMIEgSiAiFMChAKCAQFAhMI
nAgAEgSiAiJLCkIKBAQFAhQSBKUCAkcaNCBPdXRwdXQgb25seS4gVGhlIG51bWJlciBvZiBh
Y3RpdmVseSBydW5uaW5nIHRhc2tzLgoKDQoFBAUCFAUSBKUCAgcKDQoFBAUCFAESBKUCCBUK
DQoFBAUCFAMSBKUCGBoKDQoFBAUCFAgSBKUCG0YKEAoIBAUCFAicCAASBKUCHEUKTwoEBAUC
FRIEqAICSRpBIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIHRhc2tzIHdoaWNoIHJlYWNo
ZWQgcGhhc2UgU3VjY2VlZGVkLgoKDQoFBAUCFQUSBKgCAgcKDQoFBAUCFQESBKgCCBcKDQoF
BAUCFQMSBKgCGhwKDQoFBAUCFQgSBKgCHUgKEAoIBAUCFQicCAASBKgCHkcKTAoEBAUCFhIE
qwICRho+IE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIHRhc2tzIHdoaWNoIHJlYWNoZWQg
cGhhc2UgRmFpbGVkLgoKDQoFBAUCFgUSBKsCAgcKDQoFBAUCFgESBKsCCBQKDQoFBAUCFgMS
BKsCFxkKDQoFBAUCFggSBKsCGkUKEAoIBAUCFgicCAASBKsCG0QKTwoEBAUCFxIErgICSRpB
IE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIHRhc2tzIHdoaWNoIHJlYWNoZWQgcGhhc2Ug
Q2FuY2VsbGVkLgoKDQoFBAUCFwUSBK4CAgcKDQoFBAUCFwESBK4CCBcKDQoFBAUCFwMSBK4C
GhwKDQoFBAUCFwgSBK4CHUgKEAoIBAUCFwicCAASBK4CHkcKUgoEBAUCGBIEsQICRxpEIE91
dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIHRhc2tzIHdoaWNoIGhhdmUgcmV0cmllZCBhdCBs
ZWFzdCBvbmNlLgoKDQoFBAUCGAUSBLECAgcKDQoFBAUCGAESBLECCBUKDQoFBAUCGAMSBLEC
GBoKDQoFBAUCGAgSBLECG0YKEAoIBAUCGAicCAASBLECHEUKXgoEBAUCGRIEtQICQhpQIE91
dHB1dCBvbmx5LiBVUkkgd2hlcmUgbG9ncyBmb3IgdGhpcyBleGVjdXRpb24gY2FuIGJlIGZv
dW5kIGluIENsb3VkCiBDb25zb2xlLgoKDQoFBAUCGQUSBLUCAggKDQoFBAUCGQESBLUCCRAK
DQoFBAUCGQMSBLUCExUKDQoFBAUCGQgSBLUCFkEKEAoIBAUCGQicCAASBLUCF0AKNQoEBAUC
GhIEuAICRhonIE91dHB1dCBvbmx5LiBSZXNlcnZlZCBmb3IgZnV0dXJlIHVzZS4KCg0KBQQF
AhoFEgS4AgIGCg0KBQQFAhoBEgS4AgcUCg0KBQQFAhoDEgS4AhcZCg0KBQQFAhoIEgS4AhpF
ChAKCAQFAhoInAgAEgS4AhtECkUKBAQFAhsSBLsCAkEaNyBPdXRwdXQgb25seS4gQXJiaXRy
YXJ5IGlkZW50aWZpZXIgZm9yIHRoZSBBUEkgY2xpZW50LgoKDQoFBAUCGwUSBLsCAggKDQoF
BAUCGwESBLsCCQ8KDQoFBAUCGwMSBLsCEhQKDQoFBAUCGwgSBLsCFUAKEAoIBAUCGwicCAAS
BLsCFj8KTQoEBAUCHBIEvgICSRo/IE91dHB1dCBvbmx5LiBBcmJpdHJhcnkgdmVyc2lvbiBp
ZGVudGlmaWVyIGZvciB0aGUgQVBJIGNsaWVudC4KCg0KBQQFAhwFEgS+AgIICg0KBQQFAhwB
EgS+AgkXCg0KBQQFAhwDEgS+AhocCg0KBQQFAhwIEgS+Ah1IChAKCAQFAhwInAgAEgS+Ah5H
CpsBCgQEBQIdEgTCAgI/GowBIE91dHB1dCBvbmx5LiBBIHN5c3RlbS1nZW5lcmF0ZWQgZmlu
Z2VycHJpbnQgZm9yIHRoaXMgdmVyc2lvbiBvZiB0aGUKIHJlc291cmNlLiBNYXkgYmUgdXNl
ZCB0byBkZXRlY3QgbW9kaWZpY2F0aW9uIGNvbmZsaWN0IGR1cmluZyB1cGRhdGVzLgoKDQoF
BAUCHQUSBMICAggKDQoFBAUCHQESBMICCQ0KDQoFBAUCHQMSBMICEBIKDQoFBAUCHQgSBMIC
Ez4KEAoIBAUCHQicCAASBMICFD1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::Execution::GetExecutionRequest ===
    # Fields for GetExecutionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Run::V2::Execution::ListExecutionsRequest ===
    # Fields for ListExecutionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: show_deleted Type: 8 ()

# === Message: Google::Cloud::Run::V2::Execution::ListExecutionsResponse ===
    # Fields for ListExecutionsResponse
    # Field: executions Type: 11 (.google.cloud.run.v2.Execution)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Run::V2::Execution::DeleteExecutionRequest ===
    # Fields for DeleteExecutionRequest
    # Field: name Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Run::V2::Execution::CancelExecutionRequest ===
    # Fields for CancelExecutionRequest
    # Field: name Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Run::V2::Execution::Execution ===
    # Fields for Execution
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: creator Type: 9 ()
    # Field: generation Type: 3 ()
    # Field: labels Type: 11 (.google.cloud.run.v2.Execution.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.run.v2.Execution.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: completion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: launch_stage Type: 14 (.google.api.LaunchStage)
    # Field: job Type: 9 ()
    # Field: parallelism Type: 5 ()
    # Field: task_count Type: 5 ()
    # Field: template Type: 11 (.google.cloud.run.v2.TaskTemplate)
    # Field: reconciling Type: 8 ()
    # Field: conditions Type: 11 (.google.cloud.run.v2.Condition)
    # Field: observed_generation Type: 3 ()
    # Field: running_count Type: 5 ()
    # Field: succeeded_count Type: 5 ()
    # Field: failed_count Type: 5 ()
    # Field: cancelled_count Type: 5 ()
    # Field: retried_count Type: 5 ()
    # Field: log_uri Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: client Type: 9 ()
    # Field: client_version Type: 9 ()
    # Field: etag Type: 9 ()

# === Service Client: Google::Cloud::Run::V2::Execution::ExecutionsClient ===
package Google::Cloud::Run::V2::Execution::ExecutionsClient;

=pod

=head2 Service Client: Google::Cloud::Run::V2::Execution::ExecutionsClient

Client stub representing the remote C<Executions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Execution::GetExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Executions',
        method         => 'GetExecution',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Execution::Execution',
    });
}

sub list_executions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Execution::ListExecutionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Executions',
        method         => 'ListExecutions',
        request        => $req,
        response_class => 'Google::Cloud::Run::V2::Execution::ListExecutionsResponse',
    });
}

sub delete_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Execution::DeleteExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Executions',
        method         => 'DeleteExecution',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub cancel_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Run::V2::Execution::CancelExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.run.v2.Executions',
        method         => 'CancelExecution',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::Execution - Compiled Protocol Buffers messages for google/cloud/run/v2/execution.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::Execution;

    my $msg = Google::Cloud::Run::V2::Execution::GetExecutionRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::Execution::GetExecutionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/execution.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::Execution::GetExecutionRequest

Request message for obtaining a Execution by its full name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full name of the Execution.
Format:
`projects/{project}/locations/{location}/jobs/{job}/executions/{execution}`,
where `{project}` can be project id or number.

=back

=head2 Google::Cloud::Run::V2::Execution::ListExecutionsRequest

Request message for retrieving a list of Executions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Execution from which the Executions should be listed.
To list all Executions across Jobs, use "-" instead of Job name.
Format: `projects/{project}/locations/{location}/jobs/{job}`, where
`{project}` can be project id or number.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of Executions to return in this call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token received from a previous call to ListExecutions.
All other parameters must match.

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

If true, returns deleted (but unexpired) resources along with active ones.

=back

=head2 Google::Cloud::Run::V2::Execution::ListExecutionsResponse

Response message containing a list of Executions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->executions() >> / C<< $msg->executions($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Execution::Execution>)

The resulting list of Executions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token indicating there are more items than page_size. Use it in the next
ListExecutions request to continue.

=back

=head2 Google::Cloud::Run::V2::Execution::DeleteExecutionRequest

Request message for deleting an Execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Execution to delete.
Format:
`projects/{project}/locations/{location}/jobs/{job}/executions/{execution}`,
where `{project}` can be project id or number.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Indicates that the request should be validated without actually
deleting any resources.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

A system-generated fingerprint for this version of the resource.
This may be used to detect modification conflict during updates.

=back

=head2 Google::Cloud::Run::V2::Execution::CancelExecutionRequest

Request message for deleting an Execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Execution to cancel.
Format:
`projects/{project}/locations/{location}/jobs/{job}/executions/{execution}`,
where `{project}` can be project id or number.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Indicates that the request should be validated without actually
cancelling any resources.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

A system-generated fingerprint for this version of the resource.
This may be used to detect modification conflict during updates.

=back

=head2 Google::Cloud::Run::V2::Execution::Execution

Execution represents the configuration of a single execution. A execution an
immutable resource that references a container image which is run to
completion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique name of this Execution.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the Execution. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

Output only. Email address of the authenticated creator.

=item * C<< $msg->generation() >> / C<< $msg->generation($value) >>

Type: C<Int64>

Output only. A number that monotonically increases every time the user
modifies the desired state.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Execution::Execution::LabelsEntry>)

Output only. Unstructured key value map that can be used to organize and
categorize objects. User-provided labels are shared with Google's billing
system, so they can be used to filter, or break down billing charges by
team, component, environment, state, etc. For more information, visit
https://cloud.google.com/resource-manager/docs/creating-managing-labels or
https://cloud.google.com/run/docs/configuring/labels

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Execution::Execution::AnnotationsEntry>)

Output only. Unstructured key value map that may
be set by external tools to store and arbitrary metadata.
They are not queryable and should be preserved
when modifying objects.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the execution was acknowledged by the
execution controller. It is not guaranteed to be set in happens-before
order across separate operations.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the execution started to run.
It is not guaranteed to be set in happens-before order across separate
operations.

=item * C<< $msg->completion_time() >> / C<< $msg->completion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Represents time when the execution was completed. It is not
guaranteed to be set in happens-before order across separate operations.

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

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<String>

Output only. The name of the parent Job.

=item * C<< $msg->parallelism() >> / C<< $msg->parallelism($value) >>

Type: C<Int32>

Output only. Specifies the maximum desired number of tasks the execution
should run at any given time. Must be <= task_count. The actual number of
tasks running in steady state will be less than this number when
((.spec.task_count - .status.successful) < .spec.parallelism), i.e. when
the work left to do is less than max parallelism.

=item * C<< $msg->task_count() >> / C<< $msg->task_count($value) >>

Type: C<Int32>

Output only. Specifies the desired number of tasks the execution should
run. Setting to 1 means that parallelism is limited to 1 and the success of
that task signals the success of the execution.

=item * C<< $msg->template() >> / C<< $msg->template($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::TaskTemplate::TaskTemplate>)

Output only. The template used to create tasks for this execution.

=item * C<< $msg->reconciling() >> / C<< $msg->reconciling($value) >>

Type: C<Bool>

Output only. Indicates whether the resource's reconciliation is still in
progress. See comments in `Job.reconciling` for additional information on
reconciliation process in Cloud Run.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Condition::Condition>)

Output only. The Condition of this Execution, containing its readiness
status, and detailed error information in case it did not reach the desired
state.

=item * C<< $msg->observed_generation() >> / C<< $msg->observed_generation($value) >>

Type: C<Int64>

Output only. The generation of this Execution. See comments in
`reconciling` for additional information on reconciliation process in Cloud
Run.

=item * C<< $msg->running_count() >> / C<< $msg->running_count($value) >>

Type: C<Int32>

Output only. The number of actively running tasks.

=item * C<< $msg->succeeded_count() >> / C<< $msg->succeeded_count($value) >>

Type: C<Int32>

Output only. The number of tasks which reached phase Succeeded.

=item * C<< $msg->failed_count() >> / C<< $msg->failed_count($value) >>

Type: C<Int32>

Output only. The number of tasks which reached phase Failed.

=item * C<< $msg->cancelled_count() >> / C<< $msg->cancelled_count($value) >>

Type: C<Int32>

Output only. The number of tasks which reached phase Cancelled.

=item * C<< $msg->retried_count() >> / C<< $msg->retried_count($value) >>

Type: C<Int32>

Output only. The number of tasks which have retried at least once.

=item * C<< $msg->log_uri() >> / C<< $msg->log_uri($value) >>

Type: C<String>

Output only. URI where logs for this execution can be found in Cloud
Console.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Output only. Arbitrary identifier for the API client.

=item * C<< $msg->client_version() >> / C<< $msg->client_version($value) >>

Type: C<String>

Output only. Arbitrary version identifier for the API client.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. A system-generated fingerprint for this version of the
resource. May be used to detect modification conflict during updates.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::Execution::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
