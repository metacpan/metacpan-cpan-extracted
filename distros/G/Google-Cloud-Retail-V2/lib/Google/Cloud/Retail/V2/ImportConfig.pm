package Google::Cloud::Retail::V2::ImportConfig;

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
    eval { require Google::Cloud::Retail::V2::Product };
    eval { require Google::Cloud::Retail::V2::UserEvent };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2ltcG9ydF9jb25maWcucHJvdG8SFmdvb2dsZS5j
bG91ZC5yZXRhaWwudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aJGdvb2dsZS9jbG91ZC9yZXRhaWwvdjIvcHJvZHVjdC5w
cm90bxonZ29vZ2xlL2Nsb3VkL3JldGFpbC92Mi91c2VyX2V2ZW50LnByb3RvGiBnb29nbGUv
cHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8aFmdvb2dsZS90eXBlL2RhdGUucHJvdG8i
UAoJR2NzU291cmNlEiIKCmlucHV0X3VyaXMYASADKAlCA+BBAlIJaW5wdXRVcmlzEh8KC2Rh
dGFfc2NoZW1hGAIgASgJUgpkYXRhU2NoZW1hIoUCCg5CaWdRdWVyeVNvdXJjZRI6Cg5wYXJ0
aXRpb25fZGF0ZRgGIAEoCzIRLmdvb2dsZS50eXBlLkRhdGVIAFINcGFydGl0aW9uRGF0ZRId
Cgpwcm9qZWN0X2lkGAUgASgJUglwcm9qZWN0SWQSIgoKZGF0YXNldF9pZBgBIAEoCUID4EEC
UglkYXRhc2V0SWQSHgoIdGFibGVfaWQYAiABKAlCA+BBAlIHdGFibGVJZBImCg9nY3Nfc3Rh
Z2luZ19kaXIYAyABKAlSDWdjc1N0YWdpbmdEaXISHwoLZGF0YV9zY2hlbWEYBCABKAlSCmRh
dGFTY2hlbWFCCwoJcGFydGl0aW9uIlcKE1Byb2R1Y3RJbmxpbmVTb3VyY2USQAoIcHJvZHVj
dHMYASADKAsyHy5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlByb2R1Y3RCA+BBAlIIcHJvZHVj
dHMiYAoVVXNlckV2ZW50SW5saW5lU291cmNlEkcKC3VzZXJfZXZlbnRzGAEgAygLMiEuZ29v
Z2xlLmNsb3VkLnJldGFpbC52Mi5Vc2VyRXZlbnRCA+BBAlIKdXNlckV2ZW50cyJEChJJbXBv
cnRFcnJvcnNDb25maWcSHwoKZ2NzX3ByZWZpeBgBIAEoCUgAUglnY3NQcmVmaXhCDQoLZGVz
dGluYXRpb24i3wQKFUltcG9ydFByb2R1Y3RzUmVxdWVzdBI8CgZwYXJlbnQYASABKAlCJOBB
AvpBHgoccmV0YWlsLmdvb2dsZWFwaXMuY29tL0JyYW5jaFIGcGFyZW50EiEKCnJlcXVlc3Rf
aWQYBiABKAlCAhgBUglyZXF1ZXN0SWQSUgoMaW5wdXRfY29uZmlnGAIgASgLMiouZ29vZ2xl
LmNsb3VkLnJldGFpbC52Mi5Qcm9kdWN0SW5wdXRDb25maWdCA+BBAlILaW5wdXRDb25maWcS
TwoNZXJyb3JzX2NvbmZpZxgDIAEoCzIqLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuSW1wb3J0
RXJyb3JzQ29uZmlnUgxlcnJvcnNDb25maWcSOwoLdXBkYXRlX21hc2sYBCABKAsyGi5nb29n
bGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrEnEKE3JlY29uY2lsaWF0aW9uX21v
ZGUYBSABKA4yQC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkltcG9ydFByb2R1Y3RzUmVxdWVz
dC5SZWNvbmNpbGlhdGlvbk1vZGVSEnJlY29uY2lsaWF0aW9uTW9kZRI6Chlub3RpZmljYXRp
b25fcHVic3ViX3RvcGljGAcgASgJUhdub3RpZmljYXRpb25QdWJzdWJUb3BpYyJUChJSZWNv
bmNpbGlhdGlvbk1vZGUSIwofUkVDT05DSUxJQVRJT05fTU9ERV9VTlNQRUNJRklFRBAAEg8K
C0lOQ1JFTUVOVEFMEAESCAoERlVMTBACIv8BChdJbXBvcnRVc2VyRXZlbnRzUmVxdWVzdBI9
CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dS
BnBhcmVudBJUCgxpbnB1dF9jb25maWcYAiABKAsyLC5nb29nbGUuY2xvdWQucmV0YWlsLnYy
LlVzZXJFdmVudElucHV0Q29uZmlnQgPgQQJSC2lucHV0Q29uZmlnEk8KDWVycm9yc19jb25m
aWcYAyABKAsyKi5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkltcG9ydEVycm9yc0NvbmZpZ1IM
ZXJyb3JzQ29uZmlnIvMBChtJbXBvcnRDb21wbGV0aW9uRGF0YVJlcXVlc3QSPQoGcGFyZW50
GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9nUgZwYXJlbnQS
WQoMaW5wdXRfY29uZmlnGAIgASgLMjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0
aW9uRGF0YUlucHV0Q29uZmlnQgPgQQJSC2lucHV0Q29uZmlnEjoKGW5vdGlmaWNhdGlvbl9w
dWJzdWJfdG9waWMYAyABKAlSF25vdGlmaWNhdGlvblB1YnN1YlRvcGljIpkCChJQcm9kdWN0
SW5wdXRDb25maWcSYQoVcHJvZHVjdF9pbmxpbmVfc291cmNlGAEgASgLMisuZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Qcm9kdWN0SW5saW5lU291cmNlSABSE3Byb2R1Y3RJbmxpbmVTb3Vy
Y2USQgoKZ2NzX3NvdXJjZRgCIAEoCzIhLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2NzU291
cmNlSABSCWdjc1NvdXJjZRJSChBiaWdfcXVlcnlfc291cmNlGAMgASgLMiYuZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5CaWdRdWVyeVNvdXJjZUgAUg5iaWdRdWVyeVNvdXJjZUIICgZzb3Vy
Y2UisQIKFFVzZXJFdmVudElucHV0Q29uZmlnEm0KGHVzZXJfZXZlbnRfaW5saW5lX3NvdXJj
ZRgBIAEoCzItLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckV2ZW50SW5saW5lU291cmNl
QgPgQQJIAFIVdXNlckV2ZW50SW5saW5lU291cmNlEkcKCmdjc19zb3VyY2UYAiABKAsyIS5n
b29nbGUuY2xvdWQucmV0YWlsLnYyLkdjc1NvdXJjZUID4EECSABSCWdjc1NvdXJjZRJXChBi
aWdfcXVlcnlfc291cmNlGAMgASgLMiYuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5CaWdRdWVy
eVNvdXJjZUID4EECSABSDmJpZ1F1ZXJ5U291cmNlQggKBnNvdXJjZSJ+ChlDb21wbGV0aW9u
RGF0YUlucHV0Q29uZmlnElcKEGJpZ19xdWVyeV9zb3VyY2UYASABKAsyJi5nb29nbGUuY2xv
dWQucmV0YWlsLnYyLkJpZ1F1ZXJ5U291cmNlQgPgQQJIAFIOYmlnUXVlcnlTb3VyY2VCCAoG
c291cmNlIrMCCg5JbXBvcnRNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEiMKDXN1Y2Nlc3NfY291
bnQYAyABKANSDHN1Y2Nlc3NDb3VudBIjCg1mYWlsdXJlX2NvdW50GAQgASgDUgxmYWlsdXJl
Q291bnQSIQoKcmVxdWVzdF9pZBgFIAEoCUICGAFSCXJlcXVlc3RJZBI6Chlub3RpZmljYXRp
b25fcHVic3ViX3RvcGljGAYgASgJUhdub3RpZmljYXRpb25QdWJzdWJUb3BpYyKiAQoWSW1w
b3J0UHJvZHVjdHNSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIuZ29vZ2xlLnJw
Yy5TdGF0dXNSDGVycm9yU2FtcGxlcxJPCg1lcnJvcnNfY29uZmlnGAIgASgLMiouZ29vZ2xl
LmNsb3VkLnJldGFpbC52Mi5JbXBvcnRFcnJvcnNDb25maWdSDGVycm9yc0NvbmZpZyL7AQoY
SW1wb3J0VXNlckV2ZW50c1Jlc3BvbnNlEjcKDWVycm9yX3NhbXBsZXMYASADKAsyEi5nb29n
bGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVzEk8KDWVycm9yc19jb25maWcYAiABKAsyKi5n
b29nbGUuY2xvdWQucmV0YWlsLnYyLkltcG9ydEVycm9yc0NvbmZpZ1IMZXJyb3JzQ29uZmln
ElUKDmltcG9ydF9zdW1tYXJ5GAMgASgLMi4uZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Vc2Vy
RXZlbnRJbXBvcnRTdW1tYXJ5Ug1pbXBvcnRTdW1tYXJ5InwKFlVzZXJFdmVudEltcG9ydFN1
bW1hcnkSLgoTam9pbmVkX2V2ZW50c19jb3VudBgBIAEoA1IRam9pbmVkRXZlbnRzQ291bnQS
MgoVdW5qb2luZWRfZXZlbnRzX2NvdW50GAIgASgDUhN1bmpvaW5lZEV2ZW50c0NvdW50IlcK
HEltcG9ydENvbXBsZXRpb25EYXRhUmVzcG9uc2USNwoNZXJyb3Jfc2FtcGxlcxgBIAMoCzIS
Lmdvb2dsZS5ycGMuU3RhdHVzUgxlcnJvclNhbXBsZXNCvAEKGmNvbS5nb29nbGUuY2xvdWQu
cmV0YWlsLnYyQhFJbXBvcnRDb25maWdQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3Jl
dGFpbC9hcGl2Mi9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCFkdvb2dsZS5DbG91ZC5S
ZXRhaWwuVjLKAhZHb29nbGVcQ2xvdWRcUmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91ZDo6UmV0
YWlsOjpWMkrYdAoHEgUOAIQDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQALgoJCgIDAxIDFQAx
CgkKAgMEEgMWACoKCQoCAwUSAxcAKQoJCgIDBhIDGAAhCgkKAgMHEgMZACAKCAoBCBIDGwAz
CgkKAgglEgMbADMKCAoBCBIDHABJCgkKAggLEgMcAEkKCAoBCBIDHQAiCgkKAggKEgMdACIK
CAoBCBIDHgAyCgkKAggIEgMeADIKCAoBCBIDHwAzCgkKAggBEgMfADMKCAoBCBIDIAAkCgkK
AggkEgMgACQKCAoBCBIDIQAzCgkKAggpEgMhADMKCAoBCBIDIgAyCgkKAggtEgMiADIKPgoC
BAASBCUASwEaMiBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiBmb3IgaW5wdXQgY29u
dGVudC4KCgoKAwQAARIDJQgRCoQECgQEAAIAEgMuAkoa9gMgUmVxdWlyZWQuIEdvb2dsZSBD
bG91ZCBTdG9yYWdlIFVSSXMgdG8gaW5wdXQgZmlsZXMuIFVSSSBjYW4gYmUgdXAgdG8KIDIw
MDAgY2hhcmFjdGVycyBsb25nLiBVUklzIGNhbiBtYXRjaCB0aGUgZnVsbCBvYmplY3QgcGF0
aCAoZm9yIGV4YW1wbGUsCiBgZ3M6Ly9idWNrZXQvZGlyZWN0b3J5L29iamVjdC5qc29uYCkg
b3IgYSBwYXR0ZXJuIG1hdGNoaW5nIG9uZSBvciBtb3JlCiBmaWxlcywgc3VjaCBhcyBgZ3M6
Ly9idWNrZXQvZGlyZWN0b3J5LyouanNvbmAuIEEgcmVxdWVzdCBjYW4KIGNvbnRhaW4gYXQg
bW9zdCAxMDAgZmlsZXMsIGFuZCBlYWNoIGZpbGUgY2FuIGJlIHVwIHRvIDIgR0IuIFNlZQog
W0ltcG9ydGluZyBwcm9kdWN0CiBpbmZvcm1hdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL3JldGFpbC9yZWNvbW1lbmRhdGlvbnMtYWkvZG9jcy91cGxvYWQtY2F0YWxvZykKIGZv
ciB0aGUgZXhwZWN0ZWQgZmlsZSBmb3JtYXQgYW5kIHNldHVwIGluc3RydWN0aW9ucy4KCgwK
BQQAAgAEEgMuAgoKDAoFBAACAAUSAy4LEQoMCgUEAAIAARIDLhIcCgwKBQQAAgADEgMuHyAK
DAoFBAACAAgSAy4hSQoPCggEAAIACJwIABIDLiJICrsHCgQEAAIBEgNKAhkarQcgVGhlIHNj
aGVtYSB0byB1c2Ugd2hlbiBwYXJzaW5nIHRoZSBkYXRhIGZyb20gdGhlIHNvdXJjZS4KCiBT
dXBwb3J0ZWQgdmFsdWVzIGZvciBwcm9kdWN0IGltcG9ydHM6CgogKiBgcHJvZHVjdGAgKGRl
ZmF1bHQpOiBPbmUgSlNPTiBbUHJvZHVjdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Qcm9k
dWN0XQogcGVyIGxpbmUuIEVhY2ggcHJvZHVjdCBtdXN0CiAgIGhhdmUgYSB2YWxpZCBbUHJv
ZHVjdC5pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Qcm9kdWN0LmlkXS4KICogYHByb2R1
Y3RfbWVyY2hhbnRfY2VudGVyYDogU2VlIFtJbXBvcnRpbmcgY2F0YWxvZyBkYXRhIGZyb20g
TWVyY2hhbnQKICAgQ2VudGVyXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL3Jl
Y29tbWVuZGF0aW9ucy1haS9kb2NzL3VwbG9hZC1jYXRhbG9nI21jKS4KCiBTdXBwb3J0ZWQg
dmFsdWVzIGZvciB1c2VyIGV2ZW50cyBpbXBvcnRzOgoKICogYHVzZXJfZXZlbnRgIChkZWZh
dWx0KTogT25lIEpTT04KIFtVc2VyRXZlbnRdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNl
ckV2ZW50XSBwZXIgbGluZS4KICogYHVzZXJfZXZlbnRfZ2EzNjBgOiBVc2luZwogICBodHRw
czovL3N1cHBvcnQuZ29vZ2xlLmNvbS9hbmFseXRpY3MvYW5zd2VyLzM0Mzc3MTkuCgogU3Vw
cG9ydGVkIHZhbHVlcyBmb3IgY29udHJvbCBpbXBvcnRzOgoKICogYGNvbnRyb2xgIChkZWZh
dWx0KTogT25lIEpTT04gW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29udHJv
bF0KIHBlciBsaW5lLgoKIFN1cHBvcnRlZCB2YWx1ZXMgZm9yIGNhdGFsb2cgYXR0cmlidXRl
IGltcG9ydHM6CgogKiBgY2F0YWxvZ19hdHRyaWJ1dGVgIChkZWZhdWx0KTogT25lIENTVgog
W0NhdGFsb2dBdHRyaWJ1dGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ2F0YWxvZ0F0dHJp
YnV0ZV0gcGVyIGxpbmUuCgoMCgUEAAIBBRIDSgIICgwKBQQAAgEBEgNKCRQKDAoFBAACAQMS
A0oXGAowCgIEARIFTgCDAQEaIyBCaWdRdWVyeSBzb3VyY2UgaW1wb3J0IGRhdGEgZnJvbS4K
CgoKAwQBARIDTggWCmoKBAQBCAASBFECVAMaXCBCaWdRdWVyeSB0YWJsZSBwYXJ0aXRpb24g
aW5mby4gTGVhdmUgdGhpcyBlbXB0eSBpZiB0aGUgQmlnUXVlcnkgdGFibGUKIGlzIG5vdCBw
YXJ0aXRpb25lZC4KCgwKBQQBCAABEgNRCBEKVQoEBAECABIDUwQoGkggQmlnUXVlcnkgdGlt
ZSBwYXJ0aXRpb25lZCB0YWJsZSdzIF9QQVJUSVRJT05EQVRFIGluIFlZWVktTU0tREQgZm9y
bWF0LgoKDAoFBAECAAYSA1MEFAoMCgUEAQIAARIDUxUjCgwKBQQBAgADEgNTJicKwgEKBAQB
AgESA1kCGBq0ASBUaGUgcHJvamVjdCBJRCAoY2FuIGJlIHByb2plY3QgIyBvciBJRCkgdGhh
dCB0aGUgQmlnUXVlcnkgc291cmNlIGlzIGluIHdpdGgKIGEgbGVuZ3RoIGxpbWl0IG9mIDEy
OCBjaGFyYWN0ZXJzLiBJZiBub3Qgc3BlY2lmaWVkLCBpbmhlcml0cyB0aGUgcHJvamVjdAog
SUQgZnJvbSB0aGUgcGFyZW50IHJlcXVlc3QuCgoMCgUEAQIBBRIDWQIICgwKBQQBAgEBEgNZ
CRMKDAoFBAECAQMSA1kWFwpuCgQEAQICEgNdAkEaYSBSZXF1aXJlZC4gVGhlIEJpZ1F1ZXJ5
IGRhdGEgc2V0IHRvIGNvcHkgdGhlIGRhdGEgZnJvbSB3aXRoIGEgbGVuZ3RoIGxpbWl0CiBv
ZiAxLDAyNCBjaGFyYWN0ZXJzLgoKDAoFBAECAgUSA10CCAoMCgUEAQICARIDXQkTCgwKBQQB
AgIDEgNdFhcKDAoFBAECAggSA10YQAoPCggEAQICCJwIABIDXRk/CmsKBAQBAgMSA2ECPxpe
IFJlcXVpcmVkLiBUaGUgQmlnUXVlcnkgdGFibGUgdG8gY29weSB0aGUgZGF0YSBmcm9tIHdp
dGggYSBsZW5ndGggbGltaXQgb2YKIDEsMDI0IGNoYXJhY3RlcnMuCgoMCgUEAQIDBRIDYQII
CgwKBQQBAgMBEgNhCREKDAoFBAECAwMSA2EUFQoMCgUEAQIDCBIDYRY+Cg8KCAQBAgMInAgA
EgNhFz0K1AEKBAQBAgQSA2YCHRrGASBJbnRlcm1lZGlhdGUgQ2xvdWQgU3RvcmFnZSBkaXJl
Y3RvcnkgdXNlZCBmb3IgdGhlIGltcG9ydCB3aXRoIGEgbGVuZ3RoCiBsaW1pdCBvZiAyLDAw
MCBjaGFyYWN0ZXJzLiBDYW4gYmUgc3BlY2lmaWVkIGlmIG9uZSB3YW50cyB0byBoYXZlIHRo
ZQogQmlnUXVlcnkgZXhwb3J0IHRvIGEgc3BlY2lmaWMgQ2xvdWQgU3RvcmFnZSBkaXJlY3Rv
cnkuCgoMCgUEAQIEBRIDZgIICgwKBQQBAgQBEgNmCRgKDAoFBAECBAMSA2YbHAr9BwoEBAEC
BRIEggECGRruByBUaGUgc2NoZW1hIHRvIHVzZSB3aGVuIHBhcnNpbmcgdGhlIGRhdGEgZnJv
bSB0aGUgc291cmNlLgoKIFN1cHBvcnRlZCB2YWx1ZXMgZm9yIHByb2R1Y3QgaW1wb3J0czoK
CiAqIGBwcm9kdWN0YCAoZGVmYXVsdCk6IE9uZSBKU09OIFtQcm9kdWN0XVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyLlByb2R1Y3RdCiBwZXIgbGluZS4gRWFjaCBwcm9kdWN0IG11c3QKICAg
aGF2ZSBhIHZhbGlkIFtQcm9kdWN0LmlkXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlByb2R1
Y3QuaWRdLgogKiBgcHJvZHVjdF9tZXJjaGFudF9jZW50ZXJgOiBTZWUgW0ltcG9ydGluZyBj
YXRhbG9nIGRhdGEgZnJvbSBNZXJjaGFudAogICBDZW50ZXJdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9yZXRhaWwvcmVjb21tZW5kYXRpb25zLWFpL2RvY3MvdXBsb2FkLWNhdGFsb2cj
bWMpLgoKIFN1cHBvcnRlZCB2YWx1ZXMgZm9yIHVzZXIgZXZlbnRzIGltcG9ydHM6CgogKiBg
dXNlcl9ldmVudGAgKGRlZmF1bHQpOiBPbmUgSlNPTgogW1VzZXJFdmVudF1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Vc2VyRXZlbnRdIHBlciBsaW5lLgogKiBgdXNlcl9ldmVudF9nYTM2
MGA6CiAgIFRoZSBzY2hlbWEgaXMgYXZhaWxhYmxlIGhlcmU6CiAgIGh0dHBzOi8vc3VwcG9y
dC5nb29nbGUuY29tL2FuYWx5dGljcy9hbnN3ZXIvMzQzNzcxOS4KICogYHVzZXJfZXZlbnRf
Z2E0YDoKICAgVGhlIHNjaGVtYSBpcyBhdmFpbGFibGUgaGVyZToKICAgaHR0cHM6Ly9zdXBw
b3J0Lmdvb2dsZS5jb20vYW5hbHl0aWNzL2Fuc3dlci83MDI5ODQ2LgoKIFN1cHBvcnRlZCB2
YWx1ZXMgZm9yIGF1dG9jb21wbGV0ZSBpbXBvcnRzOgoKICogYHN1Z2dlc3Rpb25zYCAoZGVm
YXVsdCk6IE9uZSBKU09OIGNvbXBsZXRpb24gc3VnZ2VzdGlvbiBwZXIgbGluZS4KICogYGRl
bnlsaXN0YDogIE9uZSBKU09OIGRlbnkgc3VnZ2VzdGlvbiBwZXIgbGluZS4KICogYGFsbG93
bGlzdGA6ICBPbmUgSlNPTiBhbGxvdyBzdWdnZXN0aW9uIHBlciBsaW5lLgoKDQoFBAECBQUS
BIIBAggKDQoFBAECBQESBIIBCRQKDQoFBAECBQMSBIIBFxgKUQoCBAISBoYBAIsBARpDIFRo
ZSBpbmxpbmUgc291cmNlIGZvciB0aGUgaW5wdXQgY29uZmlnIGZvciBJbXBvcnRQcm9kdWN0
cyBtZXRob2QuCgoLCgMEAgESBIYBCBsKrwEKBAQCAgASBIoBAkkaoAEgUmVxdWlyZWQuIEEg
bGlzdCBvZiBwcm9kdWN0cyB0byB1cGRhdGUvY3JlYXRlLiBFYWNoIHByb2R1Y3QgbXVzdCBo
YXZlIGEKIHZhbGlkIFtQcm9kdWN0LmlkXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlByb2R1
Y3QuaWRdLiBSZWNvbW1lbmRlZCBtYXggb2YKIDEwMCBpdGVtcy4KCg0KBQQCAgAEEgSKAQIK
Cg0KBQQCAgAGEgSKAQsSCg0KBQQCAgABEgSKARMbCg0KBQQCAgADEgSKAR4fCg0KBQQCAgAI
EgSKASBIChAKCAQCAgAInAgAEgSKASFHClMKAgQDEgaOAQCRAQEaRSBUaGUgaW5saW5lIHNv
dXJjZSBmb3IgdGhlIGlucHV0IGNvbmZpZyBmb3IgSW1wb3J0VXNlckV2ZW50cyBtZXRob2Qu
CgoLCgMEAwESBI4BCB0KWAoEBAMCABIEkAECThpKIFJlcXVpcmVkLiBBIGxpc3Qgb2YgdXNl
ciBldmVudHMgdG8gaW1wb3J0LiBSZWNvbW1lbmRlZCBtYXggb2YgMTBrIGl0ZW1zLgoKDQoF
BAMCAAQSBJABAgoKDQoFBAMCAAYSBJABCxQKDQoFBAMCAAESBJABFSAKDQoFBAMCAAMSBJAB
IyQKDQoFBAMCAAgSBJABJU0KEAoIBAMCAAicCAASBJABJkwKRwoCBAQSBpQBAJ0BARo5IENv
bmZpZ3VyYXRpb24gb2YgZGVzdGluYXRpb24gZm9yIEltcG9ydCByZWxhdGVkIGVycm9ycy4K
CgsKAwQEARIElAEIGgovCgQEBAgAEgaWAQKcAQMaHyBSZXF1aXJlZC4gRXJyb3JzIGRlc3Rp
bmF0aW9uLgoKDQoFBAQIAAESBJYBCBMK9gEKBAQEAgASBJsBBBoa5wEgR29vZ2xlIENsb3Vk
IFN0b3JhZ2UgcHJlZml4IGZvciBpbXBvcnQgZXJyb3JzLiBUaGlzIG11c3QgYmUgYW4gZW1w
dHksCiBleGlzdGluZyBDbG91ZCBTdG9yYWdlIGRpcmVjdG9yeS4gSW1wb3J0IGVycm9ycyBh
cmUgd3JpdHRlbiB0bwogc2hhcmRlZCBmaWxlcyBpbiB0aGlzIGRpcmVjdG9yeSwgb25lIHBl
ciBsaW5lLCBhcyBhIEpTT04tZW5jb2RlZAogYGdvb2dsZS5ycGMuU3RhdHVzYCBtZXNzYWdl
LgoKDQoFBAQCAAUSBJsBBAoKDQoFBAQCAAESBJsBCxUKDQoFBAQCAAMSBJsBGBkKMwoCBAUS
BqABAN0BARolIFJlcXVlc3QgbWVzc2FnZSBmb3IgSW1wb3J0IG1ldGhvZHMuCgoLCgMEBQES
BKABCB0KeAoEBAUEABIGowECrQEDGmggSW5kaWNhdGVzIGhvdyBpbXBvcnRlZCBwcm9kdWN0
cyBhcmUgcmVjb25jaWxlZCB3aXRoIHRoZSBleGlzdGluZyBwcm9kdWN0cwogY3JlYXRlZCBv
ciBpbXBvcnRlZCBiZWZvcmUuCgoNCgUEBQQAARIEowEHGQoqCgYEBQQAAgASBKUBBCgaGiBE
ZWZhdWx0cyB0byBJTkNSRU1FTlRBTC4KCg8KBwQFBAACAAESBKUBBCMKDwoHBAUEAAIAAhIE
pQEmJwpECgYEBQQAAgESBKgBBBQaNCBJbnNlcnRzIG5ldyBwcm9kdWN0cyBvciB1cGRhdGVz
IGV4aXN0aW5nIHByb2R1Y3RzLgoKDwoHBAUEAAIBARIEqAEEDwoPCgcEBQQAAgECEgSoARIT
Cp0BCgYEBQQAAgISBKwBBA0ajAEgQ2FsY3VsYXRlcyBkaWZmIGFuZCByZXBsYWNlcyB0aGUg
ZW50aXJlIHByb2R1Y3QgZGF0YXNldC4gRXhpc3RpbmcKIHByb2R1Y3RzIG1heSBiZSBkZWxl
dGVkIGlmIHRoZXkgYXJlIG5vdCBwcmVzZW50IGluIHRoZSBzb3VyY2UgbG9jYXRpb24uCgoP
CgcEBQQAAgIBEgSsAQQICg8KBwQFBAACAgISBKwBCwwK9wEKBAQFAgASBrQBArcBBBrmASBS
ZXF1aXJlZC4KIGBwcm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVm
YXVsdF9jYXRhbG9nL2JyYW5jaGVzL2RlZmF1bHRfYnJhbmNoYAoKIElmIG5vIHVwZGF0ZU1h
c2sgaXMgc3BlY2lmaWVkLCByZXF1aXJlcyBwcm9kdWN0cy5jcmVhdGUgcGVybWlzc2lvbi4K
IElmIHVwZGF0ZU1hc2sgaXMgc3BlY2lmaWVkLCByZXF1aXJlcyBwcm9kdWN0cy51cGRhdGUg
cGVybWlzc2lvbi4KCg0KBQQFAgAFEgS0AQIICg0KBQQFAgABEgS0AQkPCg0KBQQFAgADEgS0
ARITCg8KBQQFAgAIEga0ARS3AQMKEAoIBAUCAAicCAASBLUBBCoKDwoHBAUCAAifCBIEtgEE
Tgo1CgQEBQIBEgS6AQIsGicgRGVwcmVjYXRlZC4gVGhpcyBmaWVsZCBoYXMgbm8gZWZmZWN0
LgoKDQoFBAUCAQUSBLoBAggKDQoFBAUCAQESBLoBCRMKDQoFBAUCAQMSBLoBFhcKDQoFBAUC
AQgSBLoBGCsKDgoGBAUCAQgDEgS6ARkqCkEKBAQFAgISBL0BAk8aMyBSZXF1aXJlZC4gVGhl
IGRlc2lyZWQgaW5wdXQgbG9jYXRpb24gb2YgdGhlIGRhdGEuCgoNCgUEBQICBhIEvQECFAoN
CgUEBQICARIEvQEVIQoNCgUEBQICAxIEvQEkJQoNCgUEBQICCBIEvQEmTgoQCggEBQICCJwI
ABIEvQEnTQpKCgQEBQIDEgTAAQInGjwgVGhlIGRlc2lyZWQgbG9jYXRpb24gb2YgZXJyb3Jz
IGluY3VycmVkIGR1cmluZyB0aGUgSW1wb3J0LgoKDQoFBAUCAwYSBMABAhQKDQoFBAUCAwES
BMABFSIKDQoFBAUCAwMSBMABJSYK3QEKBAQFAgQSBMUBAiwazgEgSW5kaWNhdGVzIHdoaWNo
IGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQgaW1wb3J0ZWQgYHByb2R1Y3RzYCB0byB1cGRhdGUu
IElmCiBub3Qgc2V0LCBhbGwgZmllbGRzIGFyZSB1cGRhdGVkLiBJZiBwcm92aWRlZCwgb25s
eSB0aGUgZXhpc3RpbmcgcHJvZHVjdAogZmllbGRzIGFyZSB1cGRhdGVkLiBNaXNzaW5nIHBy
b2R1Y3RzIHdpbGwgbm90IGJlIGNyZWF0ZWQuCgoNCgUEBQIEBhIExQECGwoNCgUEBQIEARIE
xQEcJwoNCgUEBQIEAxIExQEqKwrjAQoEBAUCBRIEygECLRrUASBUaGUgbW9kZSBvZiByZWNv
bmNpbGlhdGlvbiBiZXR3ZWVuIGV4aXN0aW5nIHByb2R1Y3RzIGFuZCB0aGUgcHJvZHVjdHMg
dG8gYmUKIGltcG9ydGVkLiBEZWZhdWx0cyB0bwogW1JlY29uY2lsaWF0aW9uTW9kZS5JTkNS
RU1FTlRBTF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5JbXBvcnRQcm9kdWN0c1JlcXVlc3Qu
UmVjb25jaWxpYXRpb25Nb2RlLklOQ1JFTUVOVEFMXS4KCg0KBQQFAgUGEgTKAQIUCg0KBQQF
AgUBEgTKARUoCg0KBQQFAgUDEgTKASssCrQGCgQEBQIGEgTcAQInGqUGIEZ1bGwgUHViL1N1
YiB0b3BpYyBuYW1lIGZvciByZWNlaXZpbmcgbm90aWZpY2F0aW9uLiBJZiB0aGlzIGZpZWxk
IGlzIHNldCwKIHdoZW4gdGhlIGltcG9ydCBpcyBmaW5pc2hlZCwgYSBub3RpZmljYXRpb24g
aXMgc2VudCB0bwogc3BlY2lmaWVkIFB1Yi9TdWIgdG9waWMuIFRoZSBtZXNzYWdlIGRhdGEg
aXMgSlNPTiBzdHJpbmcgb2YgYQogW09wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbl0uCgogRm9ybWF0IG9mIHRoZSBQdWIvU3ViIHRvcGljIGlzIGBwcm9qZWN0cy97
cHJvamVjdH0vdG9waWNzL3t0b3BpY31gLiBJdCBoYXMKIHRvIGJlIHdpdGhpbiB0aGUgc2Ft
ZSBwcm9qZWN0IGFzCiBbSW1wb3J0UHJvZHVjdHNSZXF1ZXN0LnBhcmVudF1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5JbXBvcnRQcm9kdWN0c1JlcXVlc3QucGFyZW50XS4KIE1ha2Ugc3Vy
ZSB0aGF0IGJvdGgKIGBjbG91ZC1yZXRhaWwtY3VzdG9tZXItZGF0YS1hY2Nlc3NAc3lzdGVt
LmdzZXJ2aWNlYWNjb3VudC5jb21gIGFuZAogYHNlcnZpY2UtPHByb2plY3QgbnVtYmVyPkBn
Y3Atc2EtcmV0YWlsLmlhbS5nc2VydmljZWFjY291bnQuY29tYAogaGF2ZSB0aGUgYHB1YnN1
Yi50b3BpY3MucHVibGlzaGAgSUFNIHBlcm1pc3Npb24gb24gdGhlIHRvcGljLgoKIE9ubHkg
c3VwcG9ydGVkIHdoZW4KIFtJbXBvcnRQcm9kdWN0c1JlcXVlc3QucmVjb25jaWxpYXRpb25f
bW9kZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5JbXBvcnRQcm9kdWN0c1JlcXVlc3QucmVj
b25jaWxpYXRpb25fbW9kZV0KIGlzIHNldCB0byBgRlVMTGAuCgoNCgUEBQIGBRIE3AECCAoN
CgUEBQIGARIE3AEJIgoNCgUEBQIGAxIE3AElJgpBCgIEBhIG4AEA7gEBGjMgUmVxdWVzdCBt
ZXNzYWdlIGZvciB0aGUgSW1wb3J0VXNlckV2ZW50cyByZXF1ZXN0LgoKCwoDBAYBEgTgAQgf
ClUKBAQGAgASBuIBAuUBBBpFIFJlcXVpcmVkLiBgcHJvamVjdHMvMTIzNC9sb2NhdGlvbnMv
Z2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxvZ2AKCg0KBQQGAgAFEgTiAQIICg0KBQQG
AgABEgTiAQkPCg0KBQQGAgADEgTiARITCg8KBQQGAgAIEgbiARTlAQMKEAoIBAYCAAicCAAS
BOMBBCoKDwoHBAYCAAifCBIE5AEETwpDCgQEBgIBEgboAQLpAS8aMyBSZXF1aXJlZC4gVGhl
IGRlc2lyZWQgaW5wdXQgbG9jYXRpb24gb2YgdGhlIGRhdGEuCgoNCgUEBgIBBhIE6AECFgoN
CgUEBgIBARIE6AEXIwoNCgUEBgIBAxIE6AEmJwoNCgUEBgIBCBIE6QEGLgoQCggEBgIBCJwI
ABIE6QEHLQp4CgQEBgICEgTtAQInGmogVGhlIGRlc2lyZWQgbG9jYXRpb24gb2YgZXJyb3Jz
IGluY3VycmVkIGR1cmluZyB0aGUgSW1wb3J0LiBDYW5ub3QgYmUgc2V0CiBmb3IgaW5saW5l
IHVzZXIgZXZlbnQgaW1wb3J0cy4KCg0KBQQGAgIGEgTtAQIUCg0KBQQGAgIBEgTtARUiCg0K
BQQGAgIDEgTtASUmCkEKAgQHEgbxAQCEAgEaMyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEltcG9y
dENvbXBsZXRpb25EYXRhIG1ldGhvZHMuCgoLCgMEBwESBPEBCCMKlwEKBAQHAgASBvUBAvgB
BBqGASBSZXF1aXJlZC4gVGhlIGNhdGFsb2cgd2hpY2ggdGhlIHN1Z2dlc3Rpb25zIGRhdGFz
ZXQgYmVsb25ncyB0by4KCiBGb3JtYXQ6IGBwcm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9nbG9i
YWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9nYC4KCg0KBQQHAgAFEgT1AQIICg0KBQQHAgAB
EgT1AQkPCg0KBQQHAgADEgT1ARITCg8KBQQHAgAIEgb1ART4AQMKEAoIBAcCAAicCAASBPYB
BCoKDwoHBAcCAAifCBIE9wEETwpDCgQEBwIBEgb7AQL8AS8aMyBSZXF1aXJlZC4gVGhlIGRl
c2lyZWQgaW5wdXQgbG9jYXRpb24gb2YgdGhlIGRhdGEuCgoNCgUEBwIBBhIE+wECGwoNCgUE
BwIBARIE+wEcKAoNCgUEBwIBAxIE+wErLAoNCgUEBwIBCBIE/AEGLgoQCggEBwIBCJwIABIE
/AEHLQq4AgoEBAcCAhIEgwICJxqpAiBQdWIvU3ViIHRvcGljIGZvciByZWNlaXZpbmcgbm90
aWZpY2F0aW9uLiBJZiB0aGlzIGZpZWxkIGlzIHNldCwKIHdoZW4gdGhlIGltcG9ydCBpcyBm
aW5pc2hlZCwgYSBub3RpZmljYXRpb24gaXMgc2VudCB0bwogc3BlY2lmaWVkIFB1Yi9TdWIg
dG9waWMuIFRoZSBtZXNzYWdlIGRhdGEgaXMgSlNPTiBzdHJpbmcgb2YgYQogW09wZXJhdGlv
bl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0uCiBGb3JtYXQgb2YgdGhlIFB1Yi9T
dWIgdG9waWMgaXMgYHByb2plY3RzL3twcm9qZWN0fS90b3BpY3Mve3RvcGljfWAuCgoNCgUE
BwICBRIEgwICCAoNCgUEBwICARIEgwIJIgoNCgUEBwICAxIEgwIlJgo1CgIECBIGhwIAkwIB
GicgVGhlIGlucHV0IGNvbmZpZyBzb3VyY2UgZm9yIHByb2R1Y3RzLgoKCwoDBAgBEgSHAgga
CjQKBAQICAASBokCApICAxokIFJlcXVpcmVkLiBUaGUgc291cmNlIG9mIHRoZSBpbnB1dC4K
Cg0KBQQICAABEgSJAggOCkUKBAQIAgASBIsCBDIaNyBUaGUgSW5saW5lIHNvdXJjZSBmb3Ig
dGhlIGlucHV0IGNvbnRlbnQgZm9yIHByb2R1Y3RzLgoKDQoFBAgCAAYSBIsCBBcKDQoFBAgC
AAESBIsCGC0KDQoFBAgCAAMSBIsCMDEKRAoEBAgCARIEjgIEHRo2IEdvb2dsZSBDbG91ZCBT
dG9yYWdlIGxvY2F0aW9uIGZvciB0aGUgaW5wdXQgY29udGVudC4KCg0KBQQIAgEGEgSOAgQN
Cg0KBQQIAgEBEgSOAg4YCg0KBQQIAgEDEgSOAhscCiYKBAQIAgISBJECBCgaGCBCaWdRdWVy
eSBpbnB1dCBzb3VyY2UuCgoNCgUECAICBhIEkQIEEgoNCgUECAICARIEkQITIwoNCgUECAIC
AxIEkQImJwo4CgIECRIGlgIApAIBGiogVGhlIGlucHV0IGNvbmZpZyBzb3VyY2UgZm9yIHVz
ZXIgZXZlbnRzLgoKCwoDBAkBEgSWAggcCioKBAQJCAASBpgCAqMCAxoaIFRoZSBzb3VyY2Ug
b2YgdGhlIGlucHV0LgoKDQoFBAkIAAESBJgCCA4KUwoEBAkCABIGmgIEmwIxGkMgUmVxdWly
ZWQuIFRoZSBJbmxpbmUgc291cmNlIGZvciB0aGUgaW5wdXQgY29udGVudCBmb3IgVXNlckV2
ZW50cy4KCg0KBQQJAgAGEgSaAgQZCg0KBQQJAgABEgSaAhoyCg0KBQQJAgADEgSaAjU2Cg0K
BQQJAgAIEgSbAggwChAKCAQJAgAInAgAEgSbAgkvCk4KBAQJAgESBJ4CBEYaQCBSZXF1aXJl
ZC4gR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gZm9yIHRoZSBpbnB1dCBjb250ZW50
LgoKDQoFBAkCAQYSBJ4CBA0KDQoFBAkCAQESBJ4CDhgKDQoFBAkCAQMSBJ4CGxwKDQoFBAkC
AQgSBJ4CHUUKEAoIBAkCAQicCAASBJ4CHkQKMgoEBAkCAhIGoQIEogIxGiIgUmVxdWlyZWQu
IEJpZ1F1ZXJ5IGlucHV0IHNvdXJjZS4KCg0KBQQJAgIGEgShAgQSCg0KBQQJAgIBEgShAhMj
Cg0KBQQJAgIDEgShAiYnCg0KBQQJAgIIEgSiAggwChAKCAQJAgIInAgAEgSiAgkvCjwKAgQK
EganAgC6AgEaLiBUaGUgaW5wdXQgY29uZmlnIHNvdXJjZSBmb3IgY29tcGxldGlvbiBkYXRh
LgoKCwoDBAoBEgSnAgghCtcCCgQECggAEgaxAgK5AgMaxgIgVGhlIHNvdXJjZSBvZiB0aGUg
aW5wdXQuCgogU3VwcG9ydGVkCiBbQmlnUXVlcnlTb3VyY2UuZGF0YV9zY2hlbWFdW2dvb2ds
ZS5jbG91ZC5yZXRhaWwudjIuQmlnUXVlcnlTb3VyY2UuZGF0YV9zY2hlbWFdCiB2YWx1ZXMg
Zm9yIHN1Z2dlc3Rpb25zIGltcG9ydHM6CgogKiBgc3VnZ2VzdGlvbnNgIChkZWZhdWx0KTog
T25lIEpTT04gY29tcGxldGlvbiBzdWdnZXN0aW9uIHBlciBsaW5lLgogKiBgZGVueWxpc3Rg
OiAgT25lIEpTT04gZGVueSBzdWdnZXN0aW9uIHBlciBsaW5lLgogKiBgYWxsb3dsaXN0YDog
IE9uZSBKU09OIGFsbG93IHN1Z2dlc3Rpb24gcGVyIGxpbmUuCgoNCgUECggAARIEsQIIDgre
AQoEBAoCABIGtwIEuAIxGs0BIFJlcXVpcmVkLiBCaWdRdWVyeSBpbnB1dCBzb3VyY2UuCgog
QWRkIHRoZSBJQU0gcGVybWlzc2lvbiAiQmlnUXVlcnkgRGF0YSBWaWV3ZXIiIGZvcgogY2xv
dWQtcmV0YWlsLWN1c3RvbWVyLWRhdGEtYWNjZXNzQHN5c3RlbS5nc2VydmljZWFjY291bnQu
Y29tIGJlZm9yZQogdXNpbmcgdGhpcyBmZWF0dXJlIG90aGVyd2lzZSBhbiBlcnJvciBpcyB0
aHJvd24uCgoNCgUECgIABhIEtwIEEgoNCgUECgIAARIEtwITIwoNCgUECgIAAxIEtwImJwoN
CgUECgIACBIEuAIIMAoQCggECgIACJwIABIEuAIJLwqQAQoCBAsSBr4CANUCARqBASBNZXRh
ZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUgSW1wb3J0IG9wZXJhdGlvbi4g
VGhpcyBpcwogcmV0dXJuZWQgYnkgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24u
bWV0YWRhdGEgZmllbGQuCgoLCgMECwESBL4CCBYKJgoEBAsCABIEwAICLBoYIE9wZXJhdGlv
biBjcmVhdGUgdGltZS4KCg0KBQQLAgAGEgTAAgIbCg0KBQQLAgABEgTAAhwnCg0KBQQLAgAD
EgTAAiorCmQKBAQLAgESBMQCAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYg
dGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4K
Cg0KBQQLAgEGEgTEAgIbCg0KBQQLAgEBEgTEAhwnCg0KBQQLAgEDEgTEAiorCkIKBAQLAgIS
BMcCAhoaNCBDb3VudCBvZiBlbnRyaWVzIHRoYXQgd2VyZSBwcm9jZXNzZWQgc3VjY2Vzc2Z1
bGx5LgoKDQoFBAsCAgUSBMcCAgcKDQoFBAsCAgESBMcCCBUKDQoFBAsCAgMSBMcCGBkKSgoE
BAsCAxIEygICGho8IENvdW50IG9mIGVudHJpZXMgdGhhdCBlbmNvdW50ZXJlZCBlcnJvcnMg
d2hpbGUgcHJvY2Vzc2luZy4KCg0KBQQLAgMFEgTKAgIHCg0KBQQLAgMBEgTKAggVCg0KBQQL
AgMDEgTKAhgZCjQKBAQLAgQSBM0CAiwaJiBEZXByZWNhdGVkLiBUaGlzIGZpZWxkIGlzIG5l
dmVyIHNldC4KCg0KBQQLAgQFEgTNAgIICg0KBQQLAgQBEgTNAgkTCg0KBQQLAgQDEgTNAhYX
Cg0KBQQLAgQIEgTNAhgrCg4KBgQLAgQIAxIEzQIZKgq4AgoEBAsCBRIE1AICJxqpAiBQdWIv
U3ViIHRvcGljIGZvciByZWNlaXZpbmcgbm90aWZpY2F0aW9uLiBJZiB0aGlzIGZpZWxkIGlz
IHNldCwKIHdoZW4gdGhlIGltcG9ydCBpcyBmaW5pc2hlZCwgYSBub3RpZmljYXRpb24gaXMg
c2VudCB0bwogc3BlY2lmaWVkIFB1Yi9TdWIgdG9waWMuIFRoZSBtZXNzYWdlIGRhdGEgaXMg
SlNPTiBzdHJpbmcgb2YgYQogW09wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbl0uCiBGb3JtYXQgb2YgdGhlIFB1Yi9TdWIgdG9waWMgaXMgYHByb2plY3RzL3twcm9q
ZWN0fS90b3BpY3Mve3RvcGljfWAuCgoNCgUECwIFBRIE1AICCAoNCgUECwIFARIE1AIJIgoN
CgUECwIFAxIE1AIlJgqEAgoCBAwSBtsCAOECARr1ASBSZXNwb25zZSBvZiB0aGUKIFtJbXBv
cnRQcm9kdWN0c1JlcXVlc3RdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuSW1wb3J0UHJvZHVj
dHNSZXF1ZXN0XS4gSWYgdGhlCiBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIGlzIGRvbmUsIHRo
ZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQgaWYgdGhlIG9wZXJhdGlvbiB3YXMgc3VjY2Vz
c2Z1bC4KCgsKAwQMARIE2wIIHgpMCgQEDAIAEgTdAgIvGj4gQSBzYW1wbGUgb2YgZXJyb3Jz
IGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3NpbmcgdGhlIHJlcXVlc3QuCgoNCgUEDAIABBIE
3QICCgoNCgUEDAIABhIE3QILHAoNCgUEDAIAARIE3QIdKgoNCgUEDAIAAxIE3QItLgpVCgQE
DAIBEgTgAgInGkcgRWNob2VzIHRoZSBkZXN0aW5hdGlvbiBmb3IgdGhlIGNvbXBsZXRlIGVy
cm9ycyBpbiB0aGUgcmVxdWVzdCBpZiBzZXQuCgoNCgUEDAIBBhIE4AICFAoNCgUEDAIBARIE
4AIVIgoNCgUEDAIBAxIE4AIlJgrcAQoCBA0SBuYCAPACARrNASBSZXNwb25zZSBvZiB0aGUg
SW1wb3J0VXNlckV2ZW50c1JlcXVlc3QuIElmIHRoZSBsb25nIHJ1bm5pbmcKIG9wZXJhdGlv
biB3YXMgc3VjY2Vzc2Z1bCwgdGhlbiB0aGlzIG1lc3NhZ2UgaXMgcmV0dXJuZWQgYnkgdGhl
CiBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVsZCBpZiB0aGUg
b3BlcmF0aW9uIHdhcyBzdWNjZXNzZnVsLgoKCwoDBA0BEgTmAgggCkwKBAQNAgASBOgCAi8a
PiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUg
cmVxdWVzdC4KCg0KBQQNAgAEEgToAgIKCg0KBQQNAgAGEgToAgscCg0KBQQNAgABEgToAh0q
Cg0KBQQNAgADEgToAi0uCmUKBAQNAgESBOwCAicaVyBFY2hvZXMgdGhlIGRlc3RpbmF0aW9u
IGZvciB0aGUgY29tcGxldGUgZXJyb3JzIGlmIHRoaXMgZmllbGQgd2FzIHNldCBpbgogdGhl
IHJlcXVlc3QuCgoNCgUEDQIBBhIE7AICFAoNCgUEDQIBARIE7AIVIgoNCgUEDQIBAxIE7AIl
JgpCCgQEDQICEgTvAgIsGjQgQWdncmVnYXRlZCBzdGF0aXN0aWNzIG9mIHVzZXIgZXZlbnQg
aW1wb3J0IHN0YXR1cy4KCg0KBQQNAgIGEgTvAgIYCg0KBQQNAgIBEgTvAhknCg0KBQQNAgID
EgTvAiorCnUKAgQOEgb0AgD7AgEaZyBBIHN1bW1hcnkgb2YgaW1wb3J0IHJlc3VsdC4gVGhl
IFVzZXJFdmVudEltcG9ydFN1bW1hcnkgc3VtbWFyaXplcwogdGhlIGltcG9ydCBzdGF0dXMg
Zm9yIHVzZXIgZXZlbnRzLgoKCwoDBA4BEgT0AggeClkKBAQOAgASBPYCAiAaSyBDb3VudCBv
ZiB1c2VyIGV2ZW50cyBpbXBvcnRlZCB3aXRoIGNvbXBsZXRlIGV4aXN0aW5nIGNhdGFsb2cg
aW5mb3JtYXRpb24uCgoNCgUEDgIABRIE9gICBwoNCgUEDgIAARIE9gIIGwoNCgUEDgIAAxIE
9gIeHwpvCgQEDgIBEgT6AgIiGmEgQ291bnQgb2YgdXNlciBldmVudHMgaW1wb3J0ZWQsIGJ1
dCB3aXRoIGNhdGFsb2cgaW5mb3JtYXRpb24gbm90IGZvdW5kCiBpbiB0aGUgaW1wb3J0ZWQg
Y2F0YWxvZy4KCg0KBQQOAgEFEgT6AgIHCg0KBQQOAgEBEgT6AggdCg0KBQQOAgEDEgT6AiAh
CooCCgIEDxIGgQMAhAMBGvsBIFJlc3BvbnNlIG9mIHRoZQogW0ltcG9ydENvbXBsZXRpb25E
YXRhUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5JbXBvcnRDb21wbGV0aW9uRGF0
YVJlcXVlc3RdLgogSWYgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24gaXMgZG9uZSwgdGhp
cyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbnMucmVzcG9uc2UgZmllbGQgaWYgdGhlIG9wZXJhdGlvbiBpcyBzdWNjZXNzZnVsLgoK
CwoDBA8BEgSBAwgkCkwKBAQPAgASBIMDAi8aPiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3Vu
dGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVzdC4KCg0KBQQPAgAEEgSDAwIKCg0K
BQQPAgAGEgSDAwscCg0KBQQPAgABEgSDAx0qCg0KBQQPAgADEgSDAy0uYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::ImportConfig::GcsSource ===
    # Fields for GcsSource
    # Field: input_uris Type: 9 ()
    # Field: data_schema Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ImportConfig::BigQuerySource ===
    # Fields for BigQuerySource
    # Field: partition_date Type: 11 (.google.type.Date)
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: gcs_staging_dir Type: 9 ()
    # Field: data_schema Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ImportConfig::ProductInlineSource ===
    # Fields for ProductInlineSource
    # Field: products Type: 11 (.google.cloud.retail.v2.Product)

# === Message: Google::Cloud::Retail::V2::ImportConfig::UserEventInlineSource ===
    # Fields for UserEventInlineSource
    # Field: user_events Type: 11 (.google.cloud.retail.v2.UserEvent)

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig ===
    # Fields for ImportErrorsConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportProductsRequest ===
    # Fields for ImportProductsRequest
    # Field: parent Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.retail.v2.ProductInputConfig)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2.ImportErrorsConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: reconciliation_mode Type: 14 (.google.cloud.retail.v2.ImportProductsRequest.ReconciliationMode)
    # Field: notification_pubsub_topic Type: 9 ()

# Enum: ImportProductsRequest::ReconciliationMode
our $ImportProductsRequest_RECONCILIATION_MODE_UNSPECIFIED = 0;
our $ImportProductsRequest_INCREMENTAL = 1;
our $ImportProductsRequest_FULL = 2;

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsRequest ===
    # Fields for ImportUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.retail.v2.UserEventInputConfig)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2.ImportErrorsConfig)

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataRequest ===
    # Fields for ImportCompletionDataRequest
    # Field: parent Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.retail.v2.CompletionDataInputConfig)
    # Field: notification_pubsub_topic Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ImportConfig::ProductInputConfig ===
    # Fields for ProductInputConfig
    # Field: product_inline_source Type: 11 (.google.cloud.retail.v2.ProductInlineSource)
    # Field: gcs_source Type: 11 (.google.cloud.retail.v2.GcsSource)
    # Field: big_query_source Type: 11 (.google.cloud.retail.v2.BigQuerySource)

# === Message: Google::Cloud::Retail::V2::ImportConfig::UserEventInputConfig ===
    # Fields for UserEventInputConfig
    # Field: user_event_inline_source Type: 11 (.google.cloud.retail.v2.UserEventInlineSource)
    # Field: gcs_source Type: 11 (.google.cloud.retail.v2.GcsSource)
    # Field: big_query_source Type: 11 (.google.cloud.retail.v2.BigQuerySource)

# === Message: Google::Cloud::Retail::V2::ImportConfig::CompletionDataInputConfig ===
    # Fields for CompletionDataInputConfig
    # Field: big_query_source Type: 11 (.google.cloud.retail.v2.BigQuerySource)

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportMetadata ===
    # Fields for ImportMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: request_id Type: 9 ()
    # Field: notification_pubsub_topic Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportProductsResponse ===
    # Fields for ImportProductsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2.ImportErrorsConfig)

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsResponse ===
    # Fields for ImportUserEventsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2.ImportErrorsConfig)
    # Field: import_summary Type: 11 (.google.cloud.retail.v2.UserEventImportSummary)

# === Message: Google::Cloud::Retail::V2::ImportConfig::UserEventImportSummary ===
    # Fields for UserEventImportSummary
    # Field: joined_events_count Type: 3 ()
    # Field: unjoined_events_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataResponse ===
    # Fields for ImportCompletionDataResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::ImportConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2/import_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ImportConfig;

    my $msg = Google::Cloud::Retail::V2::ImportConfig::GcsSource->new({
        input_uris => $input_uris,
        data_schema => $data_schema,
    });

    # Read or update a field
    my $val = $msg->input_uris();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::ImportConfig::GcsSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/import_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::ImportConfig::GcsSource

Google Cloud Storage location for input content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_uris() >> / C<< $msg->input_uris($value) >>

Type: C<String>

Required. Google Cloud Storage URIs to input files. URI can be up to
2000 characters long. URIs can match the full object path (for example,
`gs://bucket/directory/object.json`) or a pattern matching one or more
files, such as `gs://bucket/directory/*.json`. A request can
contain at most 100 files, and each file can be up to 2 GB. See
[Importing product
information](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog)
for the expected file format and setup instructions.

=item * C<< $msg->data_schema() >> / C<< $msg->data_schema($value) >>

Type: C<String>

The schema to use when parsing the data from the source.

Supported values for product imports:

* `product` (default): One JSON [Product][google.cloud.retail.v2.Product]
per line. Each product must
  have a valid [Product.id][google.cloud.retail.v2.Product.id].
* `product_merchant_center`: See [Importing catalog data from Merchant
  Center](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog#mc).

Supported values for user events imports:

* `user_event` (default): One JSON
[UserEvent][google.cloud.retail.v2.UserEvent] per line.
* `user_event_ga360`: Using
  https://support.google.com/analytics/answer/3437719.

Supported values for control imports:

* `control` (default): One JSON [Control][google.cloud.retail.v2.Control]
per line.

Supported values for catalog attribute imports:

* `catalog_attribute` (default): One CSV
[CatalogAttribute][google.cloud.retail.v2.CatalogAttribute] per line.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::BigQuerySource

BigQuery source import data from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partition_date() >> / C<< $msg->partition_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

BigQuery time partitioned table's _PARTITIONDATE in YYYY-MM-DD format.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID (can be project # or ID) that the BigQuery source is in with
a length limit of 128 characters. If not specified, inherits the project
ID from the parent request.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The BigQuery data set to copy the data from with a length limit
of 1,024 characters.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. The BigQuery table to copy the data from with a length limit of
1,024 characters.

=item * C<< $msg->gcs_staging_dir() >> / C<< $msg->gcs_staging_dir($value) >>

Type: C<String>

Intermediate Cloud Storage directory used for the import with a length
limit of 2,000 characters. Can be specified if one wants to have the
BigQuery export to a specific Cloud Storage directory.

=item * C<< $msg->data_schema() >> / C<< $msg->data_schema($value) >>

Type: C<String>

The schema to use when parsing the data from the source.

Supported values for product imports:

* `product` (default): One JSON [Product][google.cloud.retail.v2.Product]
per line. Each product must
  have a valid [Product.id][google.cloud.retail.v2.Product.id].
* `product_merchant_center`: See [Importing catalog data from Merchant
  Center](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog#mc).

Supported values for user events imports:

* `user_event` (default): One JSON
[UserEvent][google.cloud.retail.v2.UserEvent] per line.
* `user_event_ga360`:
  The schema is available here:
  https://support.google.com/analytics/answer/3437719.
* `user_event_ga4`:
  The schema is available here:
  https://support.google.com/analytics/answer/7029846.

Supported values for autocomplete imports:

* `suggestions` (default): One JSON completion suggestion per line.
* `denylist`:  One JSON deny suggestion per line.
* `allowlist`:  One JSON allow suggestion per line.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ProductInlineSource

The inline source for the input config for ImportProducts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->products() >> / C<< $msg->products($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Product::Product>)

Required. A list of products to update/create. Each product must have a
valid [Product.id][google.cloud.retail.v2.Product.id]. Recommended max of
100 items.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::UserEventInlineSource

The inline source for the input config for ImportUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_events() >> / C<< $msg->user_events($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::UserEvent>)

Required. A list of user events to import. Recommended max of 10k items.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig

Configuration of destination for Import related errors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<String>

Google Cloud Storage prefix for import errors. This must be an empty,
existing Cloud Storage directory. Import errors are written to
sharded files in this directory, one per line, as a JSON-encoded
`google.rpc.Status` message.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportProductsRequest

Request message for Import methods.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required.
`projects/1234/locations/global/catalogs/default_catalog/branches/default_branch`

If no updateMask is specified, requires products.create permission.
If updateMask is specified, requires products.update permission.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Deprecated. This field has no effect.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::ProductInputConfig>)

Required. The desired input location of the data.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig>)

The desired location of errors incurred during the Import.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported `products` to update. If
not set, all fields are updated. If provided, only the existing product
fields are updated. Missing products will not be created.

=item * C<< $msg->reconciliation_mode() >> / C<< $msg->reconciliation_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::ImportProductsRequest::ReconciliationMode>)

The mode of reconciliation between existing products and the products to be
imported. Defaults to
[ReconciliationMode.INCREMENTAL][google.cloud.retail.v2.ImportProductsRequest.ReconciliationMode.INCREMENTAL].

=item * C<< $msg->notification_pubsub_topic() >> / C<< $msg->notification_pubsub_topic($value) >>

Type: C<String>

Full Pub/Sub topic name for receiving notification. If this field is set,
when the import is finished, a notification is sent to
specified Pub/Sub topic. The message data is JSON string of a
[Operation][google.longrunning.Operation].

Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`. It has
to be within the same project as
[ImportProductsRequest.parent][google.cloud.retail.v2.ImportProductsRequest.parent].
Make sure that both
`cloud-retail-customer-data-access@system.gserviceaccount.com` and
`service-<project number>@gcp-sa-retail.iam.gserviceaccount.com`
have the `pubsub.topics.publish` IAM permission on the topic.

Only supported when
[ImportProductsRequest.reconciliation_mode][google.cloud.retail.v2.ImportProductsRequest.reconciliation_mode]
is set to `FULL`.

=back

=head3 Enum: ImportProductsRequest::ReconciliationMode

=over 4

=item * C<RECONCILIATION_MODE_UNSPECIFIED> => C<0>

=item * C<INCREMENTAL> => C<1>

=item * C<FULL> => C<2>

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsRequest

Request message for the ImportUserEvents request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. `projects/1234/locations/global/catalogs/default_catalog`

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::UserEventInputConfig>)

Required. The desired input location of the data.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig>)

The desired location of errors incurred during the Import. Cannot be set
for inline user event imports.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataRequest

Request message for ImportCompletionData methods.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The catalog which the suggestions dataset belongs to.

Format: `projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::CompletionDataInputConfig>)

Required. The desired input location of the data.

=item * C<< $msg->notification_pubsub_topic() >> / C<< $msg->notification_pubsub_topic($value) >>

Type: C<String>

Pub/Sub topic for receiving notification. If this field is set,
when the import is finished, a notification is sent to
specified Pub/Sub topic. The message data is JSON string of a
[Operation][google.longrunning.Operation].
Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ProductInputConfig

The input config source for products.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product_inline_source() >> / C<< $msg->product_inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::ProductInlineSource>)

The Inline source for the input content for products.

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::GcsSource>)

Google Cloud Storage location for the input content.

=item * C<< $msg->big_query_source() >> / C<< $msg->big_query_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::BigQuerySource>)

BigQuery input source.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::UserEventInputConfig

The input config source for user events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_event_inline_source() >> / C<< $msg->user_event_inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::UserEventInlineSource>)

Required. The Inline source for the input content for UserEvents.

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::GcsSource>)

Required. Google Cloud Storage location for the input content.

=item * C<< $msg->big_query_source() >> / C<< $msg->big_query_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::BigQuerySource>)

Required. BigQuery input source.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::CompletionDataInputConfig

The input config source for completion data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->big_query_source() >> / C<< $msg->big_query_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::BigQuerySource>)

Required. BigQuery input source.

Add the IAM permission "BigQuery Data Viewer" for
cloud-retail-customer-data-access@system.gserviceaccount.com before
using this feature otherwise an error is thrown.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportMetadata

Metadata related to the progress of the Import operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were processed successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Deprecated. This field is never set.

=item * C<< $msg->notification_pubsub_topic() >> / C<< $msg->notification_pubsub_topic($value) >>

Type: C<String>

Pub/Sub topic for receiving notification. If this field is set,
when the import is finished, a notification is sent to
specified Pub/Sub topic. The message data is JSON string of a
[Operation][google.longrunning.Operation].
Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportProductsResponse

Response of the
[ImportProductsRequest][google.cloud.retail.v2.ImportProductsRequest]. If the
long running operation is done, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig>)

Echoes the destination for the complete errors in the request if set.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsResponse

Response of the ImportUserEventsRequest. If the long running
operation was successful, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig>)

Echoes the destination for the complete errors if this field was set in
the request.

=item * C<< $msg->import_summary() >> / C<< $msg->import_summary($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ImportConfig::UserEventImportSummary>)

Aggregated statistics of user event import status.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::UserEventImportSummary

A summary of import result. The UserEventImportSummary summarizes
the import status for user events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->joined_events_count() >> / C<< $msg->joined_events_count($value) >>

Type: C<Int64>

Count of user events imported with complete existing catalog information.

=item * C<< $msg->unjoined_events_count() >> / C<< $msg->unjoined_events_count($value) >>

Type: C<Int64>

Count of user events imported, but with catalog information not found
in the imported catalog.

=back

=head2 Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataResponse

Response of the
[ImportCompletionDataRequest][google.cloud.retail.v2.ImportCompletionDataRequest].
If the long running operation is done, this message is returned by the
google.longrunning.Operations.response field if the operation is successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::ImportConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
