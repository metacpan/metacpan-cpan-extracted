package Google::Cloud::Retail::V2beta::ImportConfig;

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
    eval { require Google::Cloud::Retail::V2beta::Product };
    eval { require Google::Cloud::Retail::V2beta::UserEvent };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9pbXBvcnRfY29uZmlnLnByb3RvEhpnb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmJl
dGEvcHJvZHVjdC5wcm90bxorZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmJldGEvdXNlcl9ldmVu
dC5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvGhZnb29nbGUv
dHlwZS9kYXRlLnByb3RvIlAKCUdjc1NvdXJjZRIiCgppbnB1dF91cmlzGAEgAygJQgPgQQJS
CWlucHV0VXJpcxIfCgtkYXRhX3NjaGVtYRgCIAEoCVIKZGF0YVNjaGVtYSKFAgoOQmlnUXVl
cnlTb3VyY2USOgoOcGFydGl0aW9uX2RhdGUYBiABKAsyES5nb29nbGUudHlwZS5EYXRlSABS
DXBhcnRpdGlvbkRhdGUSHQoKcHJvamVjdF9pZBgFIAEoCVIJcHJvamVjdElkEiIKCmRhdGFz
ZXRfaWQYASABKAlCA+BBAlIJZGF0YXNldElkEh4KCHRhYmxlX2lkGAIgASgJQgPgQQJSB3Rh
YmxlSWQSJgoPZ2NzX3N0YWdpbmdfZGlyGAMgASgJUg1nY3NTdGFnaW5nRGlyEh8KC2RhdGFf
c2NoZW1hGAQgASgJUgpkYXRhU2NoZW1hQgsKCXBhcnRpdGlvbiJbChNQcm9kdWN0SW5saW5l
U291cmNlEkQKCHByb2R1Y3RzGAEgAygLMiMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEu
UHJvZHVjdEID4EECUghwcm9kdWN0cyJkChVVc2VyRXZlbnRJbmxpbmVTb3VyY2USSwoLdXNl
cl9ldmVudHMYASADKAsyJS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Vc2VyRXZlbnRC
A+BBAlIKdXNlckV2ZW50cyJEChJJbXBvcnRFcnJvcnNDb25maWcSHwoKZ2NzX3ByZWZpeBgB
IAEoCUgAUglnY3NQcmVmaXhCDQoLZGVzdGluYXRpb24i6wQKFUltcG9ydFByb2R1Y3RzUmVx
dWVzdBI8CgZwYXJlbnQYASABKAlCJOBBAvpBHgoccmV0YWlsLmdvb2dsZWFwaXMuY29tL0Jy
YW5jaFIGcGFyZW50EiEKCnJlcXVlc3RfaWQYBiABKAlCAhgBUglyZXF1ZXN0SWQSVgoMaW5w
dXRfY29uZmlnGAIgASgLMi4uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHJvZHVjdElu
cHV0Q29uZmlnQgPgQQJSC2lucHV0Q29uZmlnElMKDWVycm9yc19jb25maWcYAyABKAsyLi5n
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5JbXBvcnRFcnJvcnNDb25maWdSDGVycm9yc0Nv
bmZpZxI7Cgt1cGRhdGVfbWFzaxgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tS
CnVwZGF0ZU1hc2sSdQoTcmVjb25jaWxpYXRpb25fbW9kZRgFIAEoDjJELmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJiZXRhLkltcG9ydFByb2R1Y3RzUmVxdWVzdC5SZWNvbmNpbGlhdGlvbk1v
ZGVSEnJlY29uY2lsaWF0aW9uTW9kZRI6Chlub3RpZmljYXRpb25fcHVic3ViX3RvcGljGAcg
ASgJUhdub3RpZmljYXRpb25QdWJzdWJUb3BpYyJUChJSZWNvbmNpbGlhdGlvbk1vZGUSIwof
UkVDT05DSUxJQVRJT05fTU9ERV9VTlNQRUNJRklFRBAAEg8KC0lOQ1JFTUVOVEFMEAESCAoE
RlVMTBACIocCChdJbXBvcnRVc2VyRXZlbnRzUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBB
AvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJYCgxpbnB1dF9j
b25maWcYAiABKAsyMC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Vc2VyRXZlbnRJbnB1
dENvbmZpZ0ID4EECUgtpbnB1dENvbmZpZxJTCg1lcnJvcnNfY29uZmlnGAMgASgLMi4uZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEuSW1wb3J0RXJyb3JzQ29uZmlnUgxlcnJvcnNDb25m
aWci9wEKG0ltcG9ydENvbXBsZXRpb25EYXRhUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBB
AvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJdCgxpbnB1dF9j
b25maWcYAiABKAsyNS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Db21wbGV0aW9uRGF0
YUlucHV0Q29uZmlnQgPgQQJSC2lucHV0Q29uZmlnEjoKGW5vdGlmaWNhdGlvbl9wdWJzdWJf
dG9waWMYAyABKAlSF25vdGlmaWNhdGlvblB1YnN1YlRvcGljIqUCChJQcm9kdWN0SW5wdXRD
b25maWcSZQoVcHJvZHVjdF9pbmxpbmVfc291cmNlGAEgASgLMi8uZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuUHJvZHVjdElubGluZVNvdXJjZUgAUhNwcm9kdWN0SW5saW5lU291cmNl
EkYKCmdjc19zb3VyY2UYAiABKAsyJS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5HY3NT
b3VyY2VIAFIJZ2NzU291cmNlElYKEGJpZ19xdWVyeV9zb3VyY2UYAyABKAsyKi5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YS5CaWdRdWVyeVNvdXJjZUgAUg5iaWdRdWVyeVNvdXJjZUII
CgZzb3VyY2UivQIKFFVzZXJFdmVudElucHV0Q29uZmlnEnEKGHVzZXJfZXZlbnRfaW5saW5l
X3NvdXJjZRgBIAEoCzIxLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVzZXJFdmVudElu
bGluZVNvdXJjZUID4EECSABSFXVzZXJFdmVudElubGluZVNvdXJjZRJLCgpnY3Nfc291cmNl
GAIgASgLMiUuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuR2NzU291cmNlQgPgQQJIAFIJ
Z2NzU291cmNlElsKEGJpZ19xdWVyeV9zb3VyY2UYAyABKAsyKi5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYmV0YS5CaWdRdWVyeVNvdXJjZUID4EECSABSDmJpZ1F1ZXJ5U291cmNlQggKBnNv
dXJjZSKCAQoZQ29tcGxldGlvbkRhdGFJbnB1dENvbmZpZxJbChBiaWdfcXVlcnlfc291cmNl
GAEgASgLMiouZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQmlnUXVlcnlTb3VyY2VCA+BB
AkgAUg5iaWdRdWVyeVNvdXJjZUIICgZzb3VyY2UiswIKDkltcG9ydE1ldGFkYXRhEjsKC2Ny
ZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGlt
ZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVw
ZGF0ZVRpbWUSIwoNc3VjY2Vzc19jb3VudBgDIAEoA1IMc3VjY2Vzc0NvdW50EiMKDWZhaWx1
cmVfY291bnQYBCABKANSDGZhaWx1cmVDb3VudBIhCgpyZXF1ZXN0X2lkGAUgASgJQgIYAVIJ
cmVxdWVzdElkEjoKGW5vdGlmaWNhdGlvbl9wdWJzdWJfdG9waWMYBiABKAlSF25vdGlmaWNh
dGlvblB1YnN1YlRvcGljIqYBChZJbXBvcnRQcm9kdWN0c1Jlc3BvbnNlEjcKDWVycm9yX3Nh
bXBsZXMYASADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVzElMKDWVycm9y
c19jb25maWcYAiABKAsyLi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5JbXBvcnRFcnJv
cnNDb25maWdSDGVycm9yc0NvbmZpZyKDAgoYSW1wb3J0VXNlckV2ZW50c1Jlc3BvbnNlEjcK
DWVycm9yX3NhbXBsZXMYASADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVz
ElMKDWVycm9yc19jb25maWcYAiABKAsyLi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5J
bXBvcnRFcnJvcnNDb25maWdSDGVycm9yc0NvbmZpZxJZCg5pbXBvcnRfc3VtbWFyeRgDIAEo
CzIyLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVzZXJFdmVudEltcG9ydFN1bW1hcnlS
DWltcG9ydFN1bW1hcnkifAoWVXNlckV2ZW50SW1wb3J0U3VtbWFyeRIuChNqb2luZWRfZXZl
bnRzX2NvdW50GAEgASgDUhFqb2luZWRFdmVudHNDb3VudBIyChV1bmpvaW5lZF9ldmVudHNf
Y291bnQYAiABKANSE3Vuam9pbmVkRXZlbnRzQ291bnQiVwocSW1wb3J0Q29tcGxldGlvbkRh
dGFSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNS
DGVycm9yU2FtcGxlc0LQAQoeY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhQhFJbXBv
cnRDb25maWdQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2MmJldGEv
cmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhpHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQmV0
YcoCGkdvb2dsZVxDbG91ZFxSZXRhaWxcVjJiZXRh6gIdR29vZ2xlOjpDbG91ZDo6UmV0YWls
OjpWMmJldGFKlHUKBxIFDgCEAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADIKCQoCAwMSAxUA
NQoJCgIDBBIDFgAqCgkKAgMFEgMXACkKCQoCAwYSAxgAIQoJCgIDBxIDGQAgCggKAQgSAxsA
NwoJCgIIJRIDGwA3CggKAQgSAxwATQoJCgIICxIDHABNCggKAQgSAx0AIgoJCgIIChIDHQAi
CggKAQgSAx4AMgoJCgIICBIDHgAyCggKAQgSAx8ANwoJCgIIARIDHwA3CggKAQgSAyAAJAoJ
CgIIJBIDIAAkCggKAQgSAyEANwoJCgIIKRIDIQA3CggKAQgSAyIANgoJCgIILRIDIgA2Cj4K
AgQAEgQlAEsBGjIgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gZm9yIGlucHV0IGNv
bnRlbnQuCgoKCgMEAAESAyUIEQqEBAoEBAACABIDLgJKGvYDIFJlcXVpcmVkLiBHb29nbGUg
Q2xvdWQgU3RvcmFnZSBVUklzIHRvIGlucHV0IGZpbGVzLiBVUkkgY2FuIGJlIHVwIHRvCiAy
MDAwIGNoYXJhY3RlcnMgbG9uZy4gVVJJcyBjYW4gbWF0Y2ggdGhlIGZ1bGwgb2JqZWN0IHBh
dGggKGZvciBleGFtcGxlLAogYGdzOi8vYnVja2V0L2RpcmVjdG9yeS9vYmplY3QuanNvbmAp
IG9yIGEgcGF0dGVybiBtYXRjaGluZyBvbmUgb3IgbW9yZQogZmlsZXMsIHN1Y2ggYXMgYGdz
Oi8vYnVja2V0L2RpcmVjdG9yeS8qLmpzb25gLiBBIHJlcXVlc3QgY2FuCiBjb250YWluIGF0
IG1vc3QgMTAwIGZpbGVzLCBhbmQgZWFjaCBmaWxlIGNhbiBiZSB1cCB0byAyIEdCLiBTZWUK
IFtJbXBvcnRpbmcgcHJvZHVjdAogaW5mb3JtYXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9yZXRhaWwvcmVjb21tZW5kYXRpb25zLWFpL2RvY3MvdXBsb2FkLWNhdGFsb2cpCiBm
b3IgdGhlIGV4cGVjdGVkIGZpbGUgZm9ybWF0IGFuZCBzZXR1cCBpbnN0cnVjdGlvbnMuCgoM
CgUEAAIABBIDLgIKCgwKBQQAAgAFEgMuCxEKDAoFBAACAAESAy4SHAoMCgUEAAIAAxIDLh8g
CgwKBQQAAgAIEgMuIUkKDwoIBAACAAicCAASAy4iSArPBwoEBAACARIDSgIZGsEHIFRoZSBz
Y2hlbWEgdG8gdXNlIHdoZW4gcGFyc2luZyB0aGUgZGF0YSBmcm9tIHRoZSBzb3VyY2UuCgog
U3VwcG9ydGVkIHZhbHVlcyBmb3IgcHJvZHVjdCBpbXBvcnRzOgoKICogYHByb2R1Y3RgIChk
ZWZhdWx0KTogT25lIEpTT04KIFtQcm9kdWN0XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5Qcm9kdWN0XSBwZXIgbGluZS4gRWFjaCBwcm9kdWN0IG11c3QKICAgaGF2ZSBhIHZhbGlk
IFtQcm9kdWN0LmlkXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Qcm9kdWN0LmlkXS4K
ICogYHByb2R1Y3RfbWVyY2hhbnRfY2VudGVyYDogU2VlIFtJbXBvcnRpbmcgY2F0YWxvZyBk
YXRhIGZyb20gTWVyY2hhbnQKICAgQ2VudGVyXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
cmV0YWlsL3JlY29tbWVuZGF0aW9ucy1haS9kb2NzL3VwbG9hZC1jYXRhbG9nI21jKS4KCiBT
dXBwb3J0ZWQgdmFsdWVzIGZvciB1c2VyIGV2ZW50cyBpbXBvcnRzOgoKICogYHVzZXJfZXZl
bnRgIChkZWZhdWx0KTogT25lIEpTT04KIFtVc2VyRXZlbnRdW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLlVzZXJFdmVudF0gcGVyIGxpbmUuCiAqIGB1c2VyX2V2ZW50X2dhMzYwYDog
VXNpbmcKICAgaHR0cHM6Ly9zdXBwb3J0Lmdvb2dsZS5jb20vYW5hbHl0aWNzL2Fuc3dlci8z
NDM3NzE5LgoKIFN1cHBvcnRlZCB2YWx1ZXMgZm9yIGNvbnRyb2wgaW1wb3J0czoKCiAqIGBj
b250cm9sYCAoZGVmYXVsdCk6IE9uZSBKU09OCiBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuQ29udHJvbF0gcGVyIGxpbmUuCgogU3VwcG9ydGVkIHZhbHVlcyBmb3Ig
Y2F0YWxvZyBhdHRyaWJ1dGUgaW1wb3J0czoKCiAqIGBjYXRhbG9nX2F0dHJpYnV0ZWAgKGRl
ZmF1bHQpOiBPbmUgQ1NWCiBbQ2F0YWxvZ0F0dHJpYnV0ZV1bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmJldGEuQ2F0YWxvZ0F0dHJpYnV0ZV0gcGVyIGxpbmUuCgoMCgUEAAIBBRIDSgIICgwK
BQQAAgEBEgNKCRQKDAoFBAACAQMSA0oXGAowCgIEARIFTgCDAQEaIyBCaWdRdWVyeSBzb3Vy
Y2UgaW1wb3J0IGRhdGEgZnJvbS4KCgoKAwQBARIDTggWCmoKBAQBCAASBFECVAMaXCBCaWdR
dWVyeSB0YWJsZSBwYXJ0aXRpb24gaW5mby4gTGVhdmUgdGhpcyBlbXB0eSBpZiB0aGUgQmln
UXVlcnkgdGFibGUKIGlzIG5vdCBwYXJ0aXRpb25lZC4KCgwKBQQBCAABEgNRCBEKVQoEBAEC
ABIDUwQoGkggQmlnUXVlcnkgdGltZSBwYXJ0aXRpb25lZCB0YWJsZSdzIF9QQVJUSVRJT05E
QVRFIGluIFlZWVktTU0tREQgZm9ybWF0LgoKDAoFBAECAAYSA1MEFAoMCgUEAQIAARIDUxUj
CgwKBQQBAgADEgNTJicKwgEKBAQBAgESA1kCGBq0ASBUaGUgcHJvamVjdCBJRCAoY2FuIGJl
IHByb2plY3QgIyBvciBJRCkgdGhhdCB0aGUgQmlnUXVlcnkgc291cmNlIGlzIGluIHdpdGgK
IGEgbGVuZ3RoIGxpbWl0IG9mIDEyOCBjaGFyYWN0ZXJzLiBJZiBub3Qgc3BlY2lmaWVkLCBp
bmhlcml0cyB0aGUgcHJvamVjdAogSUQgZnJvbSB0aGUgcGFyZW50IHJlcXVlc3QuCgoMCgUE
AQIBBRIDWQIICgwKBQQBAgEBEgNZCRMKDAoFBAECAQMSA1kWFwpuCgQEAQICEgNdAkEaYSBS
ZXF1aXJlZC4gVGhlIEJpZ1F1ZXJ5IGRhdGEgc2V0IHRvIGNvcHkgdGhlIGRhdGEgZnJvbSB3
aXRoIGEgbGVuZ3RoIGxpbWl0CiBvZiAxLDAyNCBjaGFyYWN0ZXJzLgoKDAoFBAECAgUSA10C
CAoMCgUEAQICARIDXQkTCgwKBQQBAgIDEgNdFhcKDAoFBAECAggSA10YQAoPCggEAQICCJwI
ABIDXRk/CmsKBAQBAgMSA2ECPxpeIFJlcXVpcmVkLiBUaGUgQmlnUXVlcnkgdGFibGUgdG8g
Y29weSB0aGUgZGF0YSBmcm9tIHdpdGggYSBsZW5ndGggbGltaXQgb2YKIDEsMDI0IGNoYXJh
Y3RlcnMuCgoMCgUEAQIDBRIDYQIICgwKBQQBAgMBEgNhCREKDAoFBAECAwMSA2EUFQoMCgUE
AQIDCBIDYRY+Cg8KCAQBAgMInAgAEgNhFz0K1AEKBAQBAgQSA2YCHRrGASBJbnRlcm1lZGlh
dGUgQ2xvdWQgU3RvcmFnZSBkaXJlY3RvcnkgdXNlZCBmb3IgdGhlIGltcG9ydCB3aXRoIGEg
bGVuZ3RoCiBsaW1pdCBvZiAyLDAwMCBjaGFyYWN0ZXJzLiBDYW4gYmUgc3BlY2lmaWVkIGlm
IG9uZSB3YW50cyB0byBoYXZlIHRoZQogQmlnUXVlcnkgZXhwb3J0IHRvIGEgc3BlY2lmaWMg
Q2xvdWQgU3RvcmFnZSBkaXJlY3RvcnkuCgoMCgUEAQIEBRIDZgIICgwKBQQBAgQBEgNmCRgK
DAoFBAECBAMSA2YbHAqJCAoEBAECBRIEggECGRr6ByBUaGUgc2NoZW1hIHRvIHVzZSB3aGVu
IHBhcnNpbmcgdGhlIGRhdGEgZnJvbSB0aGUgc291cmNlLgoKIFN1cHBvcnRlZCB2YWx1ZXMg
Zm9yIHByb2R1Y3QgaW1wb3J0czoKCiAqIGBwcm9kdWN0YCAoZGVmYXVsdCk6IE9uZSBKU09O
CiBbUHJvZHVjdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHJvZHVjdF0gcGVyIGxp
bmUuIEVhY2ggcHJvZHVjdCBtdXN0CiAgIGhhdmUgYSB2YWxpZCBbUHJvZHVjdC5pZF1bZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHJvZHVjdC5pZF0uCiAqIGBwcm9kdWN0X21lcmNo
YW50X2NlbnRlcmA6IFNlZSBbSW1wb3J0aW5nIGNhdGFsb2cgZGF0YSBmcm9tIE1lcmNoYW50
CiAgIENlbnRlcl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9yZWNvbW1lbmRh
dGlvbnMtYWkvZG9jcy91cGxvYWQtY2F0YWxvZyNtYykuCgogU3VwcG9ydGVkIHZhbHVlcyBm
b3IgdXNlciBldmVudHMgaW1wb3J0czoKCiAqIGB1c2VyX2V2ZW50YCAoZGVmYXVsdCk6IE9u
ZSBKU09OCiBbVXNlckV2ZW50XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Vc2VyRXZl
bnRdIHBlciBsaW5lLgogKiBgdXNlcl9ldmVudF9nYTM2MGA6CiAgIFRoZSBzY2hlbWEgaXMg
YXZhaWxhYmxlIGhlcmU6CiAgIGh0dHBzOi8vc3VwcG9ydC5nb29nbGUuY29tL2FuYWx5dGlj
cy9hbnN3ZXIvMzQzNzcxOS4KICogYHVzZXJfZXZlbnRfZ2E0YDoKICAgVGhlIHNjaGVtYSBp
cyBhdmFpbGFibGUgaGVyZToKICAgaHR0cHM6Ly9zdXBwb3J0Lmdvb2dsZS5jb20vYW5hbHl0
aWNzL2Fuc3dlci83MDI5ODQ2LgoKIFN1cHBvcnRlZCB2YWx1ZXMgZm9yIGF1dG9jb21wbGV0
ZSBpbXBvcnRzOgoKICogYHN1Z2dlc3Rpb25zYCAoZGVmYXVsdCk6IE9uZSBKU09OIGNvbXBs
ZXRpb24gc3VnZ2VzdGlvbiBwZXIgbGluZS4KICogYGRlbnlsaXN0YDogIE9uZSBKU09OIGRl
bnkgc3VnZ2VzdGlvbiBwZXIgbGluZS4KICogYGFsbG93bGlzdGA6ICBPbmUgSlNPTiBhbGxv
dyBzdWdnZXN0aW9uIHBlciBsaW5lLgoKDQoFBAECBQUSBIIBAggKDQoFBAECBQESBIIBCRQK
DQoFBAECBQMSBIIBFxgKUQoCBAISBoYBAIsBARpDIFRoZSBpbmxpbmUgc291cmNlIGZvciB0
aGUgaW5wdXQgY29uZmlnIGZvciBJbXBvcnRQcm9kdWN0cyBtZXRob2QuCgoLCgMEAgESBIYB
CBsKswEKBAQCAgASBIoBAkkapAEgUmVxdWlyZWQuIEEgbGlzdCBvZiBwcm9kdWN0cyB0byB1
cGRhdGUvY3JlYXRlLiBFYWNoIHByb2R1Y3QgbXVzdCBoYXZlIGEKIHZhbGlkIFtQcm9kdWN0
LmlkXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Qcm9kdWN0LmlkXS4gUmVjb21tZW5k
ZWQgbWF4CiBvZiAxMDAgaXRlbXMuCgoNCgUEAgIABBIEigECCgoNCgUEAgIABhIEigELEgoN
CgUEAgIAARIEigETGwoNCgUEAgIAAxIEigEeHwoNCgUEAgIACBIEigEgSAoQCggEAgIACJwI
ABIEigEhRwpTCgIEAxIGjgEAkQEBGkUgVGhlIGlubGluZSBzb3VyY2UgZm9yIHRoZSBpbnB1
dCBjb25maWcgZm9yIEltcG9ydFVzZXJFdmVudHMgbWV0aG9kLgoKCwoDBAMBEgSOAQgdClgK
BAQDAgASBJABAk4aSiBSZXF1aXJlZC4gQSBsaXN0IG9mIHVzZXIgZXZlbnRzIHRvIGltcG9y
dC4gUmVjb21tZW5kZWQgbWF4IG9mIDEwayBpdGVtcy4KCg0KBQQDAgAEEgSQAQIKCg0KBQQD
AgAGEgSQAQsUCg0KBQQDAgABEgSQARUgCg0KBQQDAgADEgSQASMkCg0KBQQDAgAIEgSQASVN
ChAKCAQDAgAInAgAEgSQASZMCkcKAgQEEgaUAQCdAQEaOSBDb25maWd1cmF0aW9uIG9mIGRl
c3RpbmF0aW9uIGZvciBJbXBvcnQgcmVsYXRlZCBlcnJvcnMuCgoLCgMEBAESBJQBCBoKLwoE
BAQIABIGlgECnAEDGh8gUmVxdWlyZWQuIEVycm9ycyBkZXN0aW5hdGlvbi4KCg0KBQQECAAB
EgSWAQgTCvYBCgQEBAIAEgSbAQQaGucBIEdvb2dsZSBDbG91ZCBTdG9yYWdlIHByZWZpeCBm
b3IgaW1wb3J0IGVycm9ycy4gVGhpcyBtdXN0IGJlIGFuIGVtcHR5LAogZXhpc3RpbmcgQ2xv
dWQgU3RvcmFnZSBkaXJlY3RvcnkuIEltcG9ydCBlcnJvcnMgYXJlIHdyaXR0ZW4gdG8KIHNo
YXJkZWQgZmlsZXMgaW4gdGhpcyBkaXJlY3RvcnksIG9uZSBwZXIgbGluZSwgYXMgYSBKU09O
LWVuY29kZWQKIGBnb29nbGUucnBjLlN0YXR1c2AgbWVzc2FnZS4KCg0KBQQEAgAFEgSbAQQK
Cg0KBQQEAgABEgSbAQsVCg0KBQQEAgADEgSbARgZCjMKAgQFEgagAQDdAQEaJSBSZXF1ZXN0
IG1lc3NhZ2UgZm9yIEltcG9ydCBtZXRob2RzLgoKCwoDBAUBEgSgAQgdCngKBAQFBAASBqMB
Aq0BAxpoIEluZGljYXRlcyBob3cgaW1wb3J0ZWQgcHJvZHVjdHMgYXJlIHJlY29uY2lsZWQg
d2l0aCB0aGUgZXhpc3RpbmcgcHJvZHVjdHMKIGNyZWF0ZWQgb3IgaW1wb3J0ZWQgYmVmb3Jl
LgoKDQoFBAUEAAESBKMBBxkKKgoGBAUEAAIAEgSlAQQoGhogRGVmYXVsdHMgdG8gSU5DUkVN
RU5UQUwuCgoPCgcEBQQAAgABEgSlAQQjCg8KBwQFBAACAAISBKUBJicKRAoGBAUEAAIBEgSo
AQQUGjQgSW5zZXJ0cyBuZXcgcHJvZHVjdHMgb3IgdXBkYXRlcyBleGlzdGluZyBwcm9kdWN0
cy4KCg8KBwQFBAACAQESBKgBBA8KDwoHBAUEAAIBAhIEqAESEwqdAQoGBAUEAAICEgSsAQQN
GowBIENhbGN1bGF0ZXMgZGlmZiBhbmQgcmVwbGFjZXMgdGhlIGVudGlyZSBwcm9kdWN0IGRh
dGFzZXQuIEV4aXN0aW5nCiBwcm9kdWN0cyBtYXkgYmUgZGVsZXRlZCBpZiB0aGV5IGFyZSBu
b3QgcHJlc2VudCBpbiB0aGUgc291cmNlIGxvY2F0aW9uLgoKDwoHBAUEAAICARIErAEECAoP
CgcEBQQAAgICEgSsAQsMCvcBCgQEBQIAEga0AQK3AQQa5gEgUmVxdWlyZWQuCiBgcHJvamVj
dHMvMTIzNC9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxvZy9icmFu
Y2hlcy9kZWZhdWx0X2JyYW5jaGAKCiBJZiBubyB1cGRhdGVNYXNrIGlzIHNwZWNpZmllZCwg
cmVxdWlyZXMgcHJvZHVjdHMuY3JlYXRlIHBlcm1pc3Npb24uCiBJZiB1cGRhdGVNYXNrIGlz
IHNwZWNpZmllZCwgcmVxdWlyZXMgcHJvZHVjdHMudXBkYXRlIHBlcm1pc3Npb24uCgoNCgUE
BQIABRIEtAECCAoNCgUEBQIAARIEtAEJDwoNCgUEBQIAAxIEtAESEwoPCgUEBQIACBIGtAEU
twEDChAKCAQFAgAInAgAEgS1AQQqCg8KBwQFAgAInwgSBLYBBE4KNQoEBAUCARIEugECLBon
IERlcHJlY2F0ZWQuIFRoaXMgZmllbGQgaGFzIG5vIGVmZmVjdC4KCg0KBQQFAgEFEgS6AQII
Cg0KBQQFAgEBEgS6AQkTCg0KBQQFAgEDEgS6ARYXCg0KBQQFAgEIEgS6ARgrCg4KBgQFAgEI
AxIEugEZKgpBCgQEBQICEgS9AQJPGjMgUmVxdWlyZWQuIFRoZSBkZXNpcmVkIGlucHV0IGxv
Y2F0aW9uIG9mIHRoZSBkYXRhLgoKDQoFBAUCAgYSBL0BAhQKDQoFBAUCAgESBL0BFSEKDQoF
BAUCAgMSBL0BJCUKDQoFBAUCAggSBL0BJk4KEAoIBAUCAgicCAASBL0BJ00KSgoEBAUCAxIE
wAECJxo8IFRoZSBkZXNpcmVkIGxvY2F0aW9uIG9mIGVycm9ycyBpbmN1cnJlZCBkdXJpbmcg
dGhlIEltcG9ydC4KCg0KBQQFAgMGEgTAAQIUCg0KBQQFAgMBEgTAARUiCg0KBQQFAgMDEgTA
ASUmCt0BCgQEBQIEEgTFAQIsGs4BIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHBy
b3ZpZGVkIGltcG9ydGVkIGBwcm9kdWN0c2AgdG8gdXBkYXRlLiBJZgogbm90IHNldCwgYWxs
IGZpZWxkcyBhcmUgdXBkYXRlZC4gSWYgcHJvdmlkZWQsIG9ubHkgdGhlIGV4aXN0aW5nIHBy
b2R1Y3QKIGZpZWxkcyBhcmUgdXBkYXRlZC4gTWlzc2luZyBwcm9kdWN0cyB3aWxsIG5vdCBi
ZSBjcmVhdGVkLgoKDQoFBAUCBAYSBMUBAhsKDQoFBAUCBAESBMUBHCcKDQoFBAUCBAMSBMUB
KisK5wEKBAQFAgUSBMoBAi0a2AEgVGhlIG1vZGUgb2YgcmVjb25jaWxpYXRpb24gYmV0d2Vl
biBleGlzdGluZyBwcm9kdWN0cyBhbmQgdGhlIHByb2R1Y3RzIHRvIGJlCiBpbXBvcnRlZC4g
RGVmYXVsdHMgdG8KIFtSZWNvbmNpbGlhdGlvbk1vZGUuSU5DUkVNRU5UQUxdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLkltcG9ydFByb2R1Y3RzUmVxdWVzdC5SZWNvbmNpbGlhdGlv
bk1vZGUuSU5DUkVNRU5UQUxdLgoKDQoFBAUCBQYSBMoBAhQKDQoFBAUCBQESBMoBFSgKDQoF
BAUCBQMSBMoBKywKvAYKBAQFAgYSBNwBAicarQYgRnVsbCBQdWIvU3ViIHRvcGljIG5hbWUg
Zm9yIHJlY2VpdmluZyBub3RpZmljYXRpb24uIElmIHRoaXMgZmllbGQgaXMgc2V0LAogd2hl
biB0aGUgaW1wb3J0IGlzIGZpbmlzaGVkLCBhIG5vdGlmaWNhdGlvbiBpcyBzZW50IHRvCiBz
cGVjaWZpZWQgUHViL1N1YiB0b3BpYy4gVGhlIG1lc3NhZ2UgZGF0YSBpcyBKU09OIHN0cmlu
ZyBvZiBhCiBbT3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXS4KCiBG
b3JtYXQgb2YgdGhlIFB1Yi9TdWIgdG9waWMgaXMgYHByb2plY3RzL3twcm9qZWN0fS90b3Bp
Y3Mve3RvcGljfWAuIEl0IGhhcwogdG8gYmUgd2l0aGluIHRoZSBzYW1lIHByb2plY3QgYXMK
IFtJbXBvcnRQcm9kdWN0c1JlcXVlc3QucGFyZW50XVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YmV0YS5JbXBvcnRQcm9kdWN0c1JlcXVlc3QucGFyZW50XS4KIE1ha2Ugc3VyZSB0aGF0IGJv
dGgKIGBjbG91ZC1yZXRhaWwtY3VzdG9tZXItZGF0YS1hY2Nlc3NAc3lzdGVtLmdzZXJ2aWNl
YWNjb3VudC5jb21gIGFuZAogYHNlcnZpY2UtPHByb2plY3QgbnVtYmVyPkBnY3Atc2EtcmV0
YWlsLmlhbS5nc2VydmljZWFjY291bnQuY29tYAogaGF2ZSB0aGUgYHB1YnN1Yi50b3BpY3Mu
cHVibGlzaGAgSUFNIHBlcm1pc3Npb24gb24gdGhlIHRvcGljLgoKIE9ubHkgc3VwcG9ydGVk
IHdoZW4KIFtJbXBvcnRQcm9kdWN0c1JlcXVlc3QucmVjb25jaWxpYXRpb25fbW9kZV1bZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEuSW1wb3J0UHJvZHVjdHNSZXF1ZXN0LnJlY29uY2ls
aWF0aW9uX21vZGVdCiBpcyBzZXQgdG8gYEZVTExgLgoKDQoFBAUCBgUSBNwBAggKDQoFBAUC
BgESBNwBCSIKDQoFBAUCBgMSBNwBJSYKQQoCBAYSBuABAO4BARozIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgdGhlIEltcG9ydFVzZXJFdmVudHMgcmVxdWVzdC4KCgsKAwQGARIE4AEIHwpVCgQE
BgIAEgbiAQLlAQQaRSBSZXF1aXJlZC4gYHByb2plY3RzLzEyMzQvbG9jYXRpb25zL2dsb2Jh
bC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFsb2dgCgoNCgUEBgIABRIE4gECCAoNCgUEBgIAARIE
4gEJDwoNCgUEBgIAAxIE4gESEwoPCgUEBgIACBIG4gEU5QEDChAKCAQGAgAInAgAEgTjAQQq
Cg8KBwQGAgAInwgSBOQBBE8KQwoEBAYCARIG6AEC6QEvGjMgUmVxdWlyZWQuIFRoZSBkZXNp
cmVkIGlucHV0IGxvY2F0aW9uIG9mIHRoZSBkYXRhLgoKDQoFBAYCAQYSBOgBAhYKDQoFBAYC
AQESBOgBFyMKDQoFBAYCAQMSBOgBJicKDQoFBAYCAQgSBOkBBi4KEAoIBAYCAQicCAASBOkB
By0KeAoEBAYCAhIE7QECJxpqIFRoZSBkZXNpcmVkIGxvY2F0aW9uIG9mIGVycm9ycyBpbmN1
cnJlZCBkdXJpbmcgdGhlIEltcG9ydC4gQ2Fubm90IGJlIHNldAogZm9yIGlubGluZSB1c2Vy
IGV2ZW50IGltcG9ydHMuCgoNCgUEBgICBhIE7QECFAoNCgUEBgICARIE7QEVIgoNCgUEBgIC
AxIE7QElJgpBCgIEBxIG8QEAhAIBGjMgUmVxdWVzdCBtZXNzYWdlIGZvciBJbXBvcnRDb21w
bGV0aW9uRGF0YSBtZXRob2RzLgoKCwoDBAcBEgTxAQgjCpcBCgQEBwIAEgb1AQL4AQQahgEg
UmVxdWlyZWQuIFRoZSBjYXRhbG9nIHdoaWNoIHRoZSBzdWdnZXN0aW9ucyBkYXRhc2V0IGJl
bG9uZ3MgdG8uCgogRm9ybWF0OiBgcHJvamVjdHMvMTIzNC9sb2NhdGlvbnMvZ2xvYmFsL2Nh
dGFsb2dzL2RlZmF1bHRfY2F0YWxvZ2AuCgoNCgUEBwIABRIE9QECCAoNCgUEBwIAARIE9QEJ
DwoNCgUEBwIAAxIE9QESEwoPCgUEBwIACBIG9QEU+AEDChAKCAQHAgAInAgAEgT2AQQqCg8K
BwQHAgAInwgSBPcBBE8KQwoEBAcCARIG+wEC/AEvGjMgUmVxdWlyZWQuIFRoZSBkZXNpcmVk
IGlucHV0IGxvY2F0aW9uIG9mIHRoZSBkYXRhLgoKDQoFBAcCAQYSBPsBAhsKDQoFBAcCAQES
BPsBHCgKDQoFBAcCAQMSBPsBKywKDQoFBAcCAQgSBPwBBi4KEAoIBAcCAQicCAASBPwBBy0K
uAIKBAQHAgISBIMCAicaqQIgUHViL1N1YiB0b3BpYyBmb3IgcmVjZWl2aW5nIG5vdGlmaWNh
dGlvbi4gSWYgdGhpcyBmaWVsZCBpcyBzZXQsCiB3aGVuIHRoZSBpbXBvcnQgaXMgZmluaXNo
ZWQsIGEgbm90aWZpY2F0aW9uIGlzIHNlbnQgdG8KIHNwZWNpZmllZCBQdWIvU3ViIHRvcGlj
LiBUaGUgbWVzc2FnZSBkYXRhIGlzIEpTT04gc3RyaW5nIG9mIGEKIFtPcGVyYXRpb25dW2dv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dLgogRm9ybWF0IG9mIHRoZSBQdWIvU3ViIHRv
cGljIGlzIGBwcm9qZWN0cy97cHJvamVjdH0vdG9waWNzL3t0b3BpY31gLgoKDQoFBAcCAgUS
BIMCAggKDQoFBAcCAgESBIMCCSIKDQoFBAcCAgMSBIMCJSYKNQoCBAgSBocCAJMCARonIFRo
ZSBpbnB1dCBjb25maWcgc291cmNlIGZvciBwcm9kdWN0cy4KCgsKAwQIARIEhwIIGgo0CgQE
CAgAEgaJAgKSAgMaJCBSZXF1aXJlZC4gVGhlIHNvdXJjZSBvZiB0aGUgaW5wdXQuCgoNCgUE
CAgAARIEiQIIDgpFCgQECAIAEgSLAgQyGjcgVGhlIElubGluZSBzb3VyY2UgZm9yIHRoZSBp
bnB1dCBjb250ZW50IGZvciBwcm9kdWN0cy4KCg0KBQQIAgAGEgSLAgQXCg0KBQQIAgABEgSL
AhgtCg0KBQQIAgADEgSLAjAxCkQKBAQIAgESBI4CBB0aNiBHb29nbGUgQ2xvdWQgU3RvcmFn
ZSBsb2NhdGlvbiBmb3IgdGhlIGlucHV0IGNvbnRlbnQuCgoNCgUECAIBBhIEjgIEDQoNCgUE
CAIBARIEjgIOGAoNCgUECAIBAxIEjgIbHAomCgQECAICEgSRAgQoGhggQmlnUXVlcnkgaW5w
dXQgc291cmNlLgoKDQoFBAgCAgYSBJECBBIKDQoFBAgCAgESBJECEyMKDQoFBAgCAgMSBJEC
JicKOAoCBAkSBpYCAKQCARoqIFRoZSBpbnB1dCBjb25maWcgc291cmNlIGZvciB1c2VyIGV2
ZW50cy4KCgsKAwQJARIElgIIHAoqCgQECQgAEgaYAgKjAgMaGiBUaGUgc291cmNlIG9mIHRo
ZSBpbnB1dC4KCg0KBQQJCAABEgSYAggOClMKBAQJAgASBpoCBJsCMRpDIFJlcXVpcmVkLiBU
aGUgSW5saW5lIHNvdXJjZSBmb3IgdGhlIGlucHV0IGNvbnRlbnQgZm9yIFVzZXJFdmVudHMu
CgoNCgUECQIABhIEmgIEGQoNCgUECQIAARIEmgIaMgoNCgUECQIAAxIEmgI1NgoNCgUECQIA
CBIEmwIIMAoQCggECQIACJwIABIEmwIJLwpOCgQECQIBEgSeAgRGGkAgUmVxdWlyZWQuIEdv
b2dsZSBDbG91ZCBTdG9yYWdlIGxvY2F0aW9uIGZvciB0aGUgaW5wdXQgY29udGVudC4KCg0K
BQQJAgEGEgSeAgQNCg0KBQQJAgEBEgSeAg4YCg0KBQQJAgEDEgSeAhscCg0KBQQJAgEIEgSe
Ah1FChAKCAQJAgEInAgAEgSeAh5ECjIKBAQJAgISBqECBKICMRoiIFJlcXVpcmVkLiBCaWdR
dWVyeSBpbnB1dCBzb3VyY2UuCgoNCgUECQICBhIEoQIEEgoNCgUECQICARIEoQITIwoNCgUE
CQICAxIEoQImJwoNCgUECQICCBIEogIIMAoQCggECQICCJwIABIEogIJLwo8CgIEChIGpwIA
ugIBGi4gVGhlIGlucHV0IGNvbmZpZyBzb3VyY2UgZm9yIGNvbXBsZXRpb24gZGF0YS4KCgsK
AwQKARIEpwIIIQrbAgoEBAoIABIGsQICuQIDGsoCIFRoZSBzb3VyY2Ugb2YgdGhlIGlucHV0
LgoKIFN1cHBvcnRlZAogW0JpZ1F1ZXJ5U291cmNlLmRhdGFfc2NoZW1hXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYmV0YS5CaWdRdWVyeVNvdXJjZS5kYXRhX3NjaGVtYV0KIHZhbHVlcyBm
b3Igc3VnZ2VzdGlvbnMgaW1wb3J0czoKCiAqIGBzdWdnZXN0aW9uc2AgKGRlZmF1bHQpOiBP
bmUgSlNPTiBjb21wbGV0aW9uIHN1Z2dlc3Rpb24gcGVyIGxpbmUuCiAqIGBkZW55bGlzdGA6
ICBPbmUgSlNPTiBkZW55IHN1Z2dlc3Rpb24gcGVyIGxpbmUuCiAqIGBhbGxvd2xpc3RgOiAg
T25lIEpTT04gYWxsb3cgc3VnZ2VzdGlvbiBwZXIgbGluZS4KCg0KBQQKCAABEgSxAggOCt4B
CgQECgIAEga3AgS4AjEazQEgUmVxdWlyZWQuIEJpZ1F1ZXJ5IGlucHV0IHNvdXJjZS4KCiBB
ZGQgdGhlIElBTSBwZXJtaXNzaW9uICJCaWdRdWVyeSBEYXRhIFZpZXdlciIgZm9yCiBjbG91
ZC1yZXRhaWwtY3VzdG9tZXItZGF0YS1hY2Nlc3NAc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5j
b20gYmVmb3JlCiB1c2luZyB0aGlzIGZlYXR1cmUgb3RoZXJ3aXNlIGFuIGVycm9yIGlzIHRo
cm93bi4KCg0KBQQKAgAGEgS3AgQSCg0KBQQKAgABEgS3AhMjCg0KBQQKAgADEgS3AiYnCg0K
BQQKAgAIEgS4AggwChAKCAQKAgAInAgAEgS4AgkvCpABCgIECxIGvgIA1QIBGoEBIE1ldGFk
YXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZSBJbXBvcnQgb3BlcmF0aW9uLiBU
aGlzIGlzCiByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5t
ZXRhZGF0YSBmaWVsZC4KCgsKAwQLARIEvgIIFgomCgQECwIAEgTAAgIsGhggT3BlcmF0aW9u
IGNyZWF0ZSB0aW1lLgoKDQoFBAsCAAYSBMACAhsKDQoFBAsCAAESBMACHCcKDQoFBAsCAAMS
BMACKisKZAoEBAsCARIExAICLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0
aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoK
DQoFBAsCAQYSBMQCAhsKDQoFBAsCAQESBMQCHCcKDQoFBAsCAQMSBMQCKisKQgoEBAsCAhIE
xwICGho0IENvdW50IG9mIGVudHJpZXMgdGhhdCB3ZXJlIHByb2Nlc3NlZCBzdWNjZXNzZnVs
bHkuCgoNCgUECwICBRIExwICBwoNCgUECwICARIExwIIFQoNCgUECwICAxIExwIYGQpKCgQE
CwIDEgTKAgIaGjwgQ291bnQgb2YgZW50cmllcyB0aGF0IGVuY291bnRlcmVkIGVycm9ycyB3
aGlsZSBwcm9jZXNzaW5nLgoKDQoFBAsCAwUSBMoCAgcKDQoFBAsCAwESBMoCCBUKDQoFBAsC
AwMSBMoCGBkKNAoEBAsCBBIEzQICLBomIERlcHJlY2F0ZWQuIFRoaXMgZmllbGQgaXMgbmV2
ZXIgc2V0LgoKDQoFBAsCBAUSBM0CAggKDQoFBAsCBAESBM0CCRMKDQoFBAsCBAMSBM0CFhcK
DQoFBAsCBAgSBM0CGCsKDgoGBAsCBAgDEgTNAhkqCrgCCgQECwIFEgTUAgInGqkCIFB1Yi9T
dWIgdG9waWMgZm9yIHJlY2VpdmluZyBub3RpZmljYXRpb24uIElmIHRoaXMgZmllbGQgaXMg
c2V0LAogd2hlbiB0aGUgaW1wb3J0IGlzIGZpbmlzaGVkLCBhIG5vdGlmaWNhdGlvbiBpcyBz
ZW50IHRvCiBzcGVjaWZpZWQgUHViL1N1YiB0b3BpYy4gVGhlIG1lc3NhZ2UgZGF0YSBpcyBK
U09OIHN0cmluZyBvZiBhCiBbT3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uXS4KIEZvcm1hdCBvZiB0aGUgUHViL1N1YiB0b3BpYyBpcyBgcHJvamVjdHMve3Byb2pl
Y3R9L3RvcGljcy97dG9waWN9YC4KCg0KBQQLAgUFEgTUAgIICg0KBQQLAgUBEgTUAgkiCg0K
BQQLAgUDEgTUAiUmCogCCgIEDBIG2wIA4QIBGvkBIFJlc3BvbnNlIG9mIHRoZQogW0ltcG9y
dFByb2R1Y3RzUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuSW1wb3J0UHJv
ZHVjdHNSZXF1ZXN0XS4gSWYKIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIGlzIGRvbmUs
IHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQgaWYgdGhlIG9wZXJhdGlvbiB3YXMgc3Vj
Y2Vzc2Z1bC4KCgsKAwQMARIE2wIIHgpMCgQEDAIAEgTdAgIvGj4gQSBzYW1wbGUgb2YgZXJy
b3JzIGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3NpbmcgdGhlIHJlcXVlc3QuCgoNCgUEDAIA
BBIE3QICCgoNCgUEDAIABhIE3QILHAoNCgUEDAIAARIE3QIdKgoNCgUEDAIAAxIE3QItLgpV
CgQEDAIBEgTgAgInGkcgRWNob2VzIHRoZSBkZXN0aW5hdGlvbiBmb3IgdGhlIGNvbXBsZXRl
IGVycm9ycyBpbiB0aGUgcmVxdWVzdCBpZiBzZXQuCgoNCgUEDAIBBhIE4AICFAoNCgUEDAIB
ARIE4AIVIgoNCgUEDAIBAxIE4AIlJgrcAQoCBA0SBuYCAPACARrNASBSZXNwb25zZSBvZiB0
aGUgSW1wb3J0VXNlckV2ZW50c1JlcXVlc3QuIElmIHRoZSBsb25nIHJ1bm5pbmcKIG9wZXJh
dGlvbiB3YXMgc3VjY2Vzc2Z1bCwgdGhlbiB0aGlzIG1lc3NhZ2UgaXMgcmV0dXJuZWQgYnkg
dGhlCiBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVsZCBpZiB0
aGUgb3BlcmF0aW9uIHdhcyBzdWNjZXNzZnVsLgoKCwoDBA0BEgTmAgggCkwKBAQNAgASBOgC
Ai8aPiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0
aGUgcmVxdWVzdC4KCg0KBQQNAgAEEgToAgIKCg0KBQQNAgAGEgToAgscCg0KBQQNAgABEgTo
Ah0qCg0KBQQNAgADEgToAi0uCmUKBAQNAgESBOwCAicaVyBFY2hvZXMgdGhlIGRlc3RpbmF0
aW9uIGZvciB0aGUgY29tcGxldGUgZXJyb3JzIGlmIHRoaXMgZmllbGQgd2FzIHNldCBpbgog
dGhlIHJlcXVlc3QuCgoNCgUEDQIBBhIE7AICFAoNCgUEDQIBARIE7AIVIgoNCgUEDQIBAxIE
7AIlJgpCCgQEDQICEgTvAgIsGjQgQWdncmVnYXRlZCBzdGF0aXN0aWNzIG9mIHVzZXIgZXZl
bnQgaW1wb3J0IHN0YXR1cy4KCg0KBQQNAgIGEgTvAgIYCg0KBQQNAgIBEgTvAhknCg0KBQQN
AgIDEgTvAiorCnUKAgQOEgb0AgD7AgEaZyBBIHN1bW1hcnkgb2YgaW1wb3J0IHJlc3VsdC4g
VGhlIFVzZXJFdmVudEltcG9ydFN1bW1hcnkgc3VtbWFyaXplcwogdGhlIGltcG9ydCBzdGF0
dXMgZm9yIHVzZXIgZXZlbnRzLgoKCwoDBA4BEgT0AggeClkKBAQOAgASBPYCAiAaSyBDb3Vu
dCBvZiB1c2VyIGV2ZW50cyBpbXBvcnRlZCB3aXRoIGNvbXBsZXRlIGV4aXN0aW5nIGNhdGFs
b2cgaW5mb3JtYXRpb24uCgoNCgUEDgIABRIE9gICBwoNCgUEDgIAARIE9gIIGwoNCgUEDgIA
AxIE9gIeHwpvCgQEDgIBEgT6AgIiGmEgQ291bnQgb2YgdXNlciBldmVudHMgaW1wb3J0ZWQs
IGJ1dCB3aXRoIGNhdGFsb2cgaW5mb3JtYXRpb24gbm90IGZvdW5kCiBpbiB0aGUgaW1wb3J0
ZWQgY2F0YWxvZy4KCg0KBQQOAgEFEgT6AgIHCg0KBQQOAgEBEgT6AggdCg0KBQQOAgEDEgT6
AiAhCo4CCgIEDxIGgQMAhAMBGv8BIFJlc3BvbnNlIG9mIHRoZQogW0ltcG9ydENvbXBsZXRp
b25EYXRhUmVxdWVzdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuSW1wb3J0Q29tcGxl
dGlvbkRhdGFSZXF1ZXN0XS4KIElmIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIGlzIGRv
bmUsIHRoaXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0aGUKIGdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkIGlmIHRoZSBvcGVyYXRpb24gaXMgc3VjY2Vz
c2Z1bC4KCgsKAwQPARIEgQMIJApMCgQEDwIAEgSDAwIvGj4gQSBzYW1wbGUgb2YgZXJyb3Jz
IGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3NpbmcgdGhlIHJlcXVlc3QuCgoNCgUEDwIABBIE
gwMCCgoNCgUEDwIABhIEgwMLHAoNCgUEDwIAARIEgwMdKgoNCgUEDwIAAxIEgwMtLmIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::GcsSource ===
    # Fields for GcsSource
    # Field: input_uris Type: 9 ()
    # Field: data_schema Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::BigQuerySource ===
    # Fields for BigQuerySource
    # Field: partition_date Type: 11 (.google.type.Date)
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: gcs_staging_dir Type: 9 ()
    # Field: data_schema Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ProductInlineSource ===
    # Fields for ProductInlineSource
    # Field: products Type: 11 (.google.cloud.retail.v2beta.Product)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::UserEventInlineSource ===
    # Fields for UserEventInlineSource
    # Field: user_events Type: 11 (.google.cloud.retail.v2beta.UserEvent)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportErrorsConfig ===
    # Fields for ImportErrorsConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportProductsRequest ===
    # Fields for ImportProductsRequest
    # Field: parent Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.retail.v2beta.ProductInputConfig)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ImportErrorsConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: reconciliation_mode Type: 14 (.google.cloud.retail.v2beta.ImportProductsRequest.ReconciliationMode)
    # Field: notification_pubsub_topic Type: 9 ()

# Enum: ImportProductsRequest::ReconciliationMode
our $ImportProductsRequest_RECONCILIATION_MODE_UNSPECIFIED = 0;
our $ImportProductsRequest_INCREMENTAL = 1;
our $ImportProductsRequest_FULL = 2;

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportUserEventsRequest ===
    # Fields for ImportUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.retail.v2beta.UserEventInputConfig)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ImportErrorsConfig)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportCompletionDataRequest ===
    # Fields for ImportCompletionDataRequest
    # Field: parent Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.retail.v2beta.CompletionDataInputConfig)
    # Field: notification_pubsub_topic Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ProductInputConfig ===
    # Fields for ProductInputConfig
    # Field: product_inline_source Type: 11 (.google.cloud.retail.v2beta.ProductInlineSource)
    # Field: gcs_source Type: 11 (.google.cloud.retail.v2beta.GcsSource)
    # Field: big_query_source Type: 11 (.google.cloud.retail.v2beta.BigQuerySource)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::UserEventInputConfig ===
    # Fields for UserEventInputConfig
    # Field: user_event_inline_source Type: 11 (.google.cloud.retail.v2beta.UserEventInlineSource)
    # Field: gcs_source Type: 11 (.google.cloud.retail.v2beta.GcsSource)
    # Field: big_query_source Type: 11 (.google.cloud.retail.v2beta.BigQuerySource)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::CompletionDataInputConfig ===
    # Fields for CompletionDataInputConfig
    # Field: big_query_source Type: 11 (.google.cloud.retail.v2beta.BigQuerySource)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportMetadata ===
    # Fields for ImportMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: request_id Type: 9 ()
    # Field: notification_pubsub_topic Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportProductsResponse ===
    # Fields for ImportProductsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ImportErrorsConfig)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportUserEventsResponse ===
    # Fields for ImportUserEventsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ImportErrorsConfig)
    # Field: import_summary Type: 11 (.google.cloud.retail.v2beta.UserEventImportSummary)

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::UserEventImportSummary ===
    # Fields for UserEventImportSummary
    # Field: joined_events_count Type: 3 ()
    # Field: unjoined_events_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2beta::ImportConfig::ImportCompletionDataResponse ===
    # Fields for ImportCompletionDataResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ImportConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/import_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ImportConfig;

    my $msg = Google::Cloud::Retail::V2beta::ImportConfig::GcsSource->new({
        input_uris => $input_uris,
        data_schema => $data_schema,
    });

    # Read or update a field
    my $val = $msg->input_uris();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ImportConfig::GcsSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/import_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ImportConfig::GcsSource

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

* `product` (default): One JSON
[Product][google.cloud.retail.v2beta.Product] per line. Each product must
  have a valid [Product.id][google.cloud.retail.v2beta.Product.id].
* `product_merchant_center`: See [Importing catalog data from Merchant
  Center](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog#mc).

Supported values for user events imports:

* `user_event` (default): One JSON
[UserEvent][google.cloud.retail.v2beta.UserEvent] per line.
* `user_event_ga360`: Using
  https://support.google.com/analytics/answer/3437719.

Supported values for control imports:

* `control` (default): One JSON
[Control][google.cloud.retail.v2beta.Control] per line.

Supported values for catalog attribute imports:

* `catalog_attribute` (default): One CSV
[CatalogAttribute][google.cloud.retail.v2beta.CatalogAttribute] per line.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::BigQuerySource

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

* `product` (default): One JSON
[Product][google.cloud.retail.v2beta.Product] per line. Each product must
  have a valid [Product.id][google.cloud.retail.v2beta.Product.id].
* `product_merchant_center`: See [Importing catalog data from Merchant
  Center](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog#mc).

Supported values for user events imports:

* `user_event` (default): One JSON
[UserEvent][google.cloud.retail.v2beta.UserEvent] per line.
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

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ProductInlineSource

The inline source for the input config for ImportProducts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->products() >> / C<< $msg->products($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Product::Product>)

Required. A list of products to update/create. Each product must have a
valid [Product.id][google.cloud.retail.v2beta.Product.id]. Recommended max
of 100 items.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::UserEventInlineSource

The inline source for the input config for ImportUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_events() >> / C<< $msg->user_events($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent>)

Required. A list of user events to import. Recommended max of 10k items.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportErrorsConfig

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

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportProductsRequest

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

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::ProductInputConfig>)

Required. The desired input location of the data.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::ImportErrorsConfig>)

The desired location of errors incurred during the Import.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported `products` to update. If
not set, all fields are updated. If provided, only the existing product
fields are updated. Missing products will not be created.

=item * C<< $msg->reconciliation_mode() >> / C<< $msg->reconciliation_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::ImportProductsRequest::ReconciliationMode>)

The mode of reconciliation between existing products and the products to be
imported. Defaults to
[ReconciliationMode.INCREMENTAL][google.cloud.retail.v2beta.ImportProductsRequest.ReconciliationMode.INCREMENTAL].

=item * C<< $msg->notification_pubsub_topic() >> / C<< $msg->notification_pubsub_topic($value) >>

Type: C<String>

Full Pub/Sub topic name for receiving notification. If this field is set,
when the import is finished, a notification is sent to
specified Pub/Sub topic. The message data is JSON string of a
[Operation][google.longrunning.Operation].

Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`. It has
to be within the same project as
[ImportProductsRequest.parent][google.cloud.retail.v2beta.ImportProductsRequest.parent].
Make sure that both
`cloud-retail-customer-data-access@system.gserviceaccount.com` and
`service-<project number>@gcp-sa-retail.iam.gserviceaccount.com`
have the `pubsub.topics.publish` IAM permission on the topic.

Only supported when
[ImportProductsRequest.reconciliation_mode][google.cloud.retail.v2beta.ImportProductsRequest.reconciliation_mode]
is set to `FULL`.

=back

=head3 Enum: ImportProductsRequest::ReconciliationMode

=over 4

=item * C<RECONCILIATION_MODE_UNSPECIFIED> => C<0>

=item * C<INCREMENTAL> => C<1>

=item * C<FULL> => C<2>

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportUserEventsRequest

Request message for the ImportUserEvents request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. `projects/1234/locations/global/catalogs/default_catalog`

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::UserEventInputConfig>)

Required. The desired input location of the data.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::ImportErrorsConfig>)

The desired location of errors incurred during the Import. Cannot be set
for inline user event imports.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportCompletionDataRequest

Request message for ImportCompletionData methods.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The catalog which the suggestions dataset belongs to.

Format: `projects/1234/locations/global/catalogs/default_catalog`.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::CompletionDataInputConfig>)

Required. The desired input location of the data.

=item * C<< $msg->notification_pubsub_topic() >> / C<< $msg->notification_pubsub_topic($value) >>

Type: C<String>

Pub/Sub topic for receiving notification. If this field is set,
when the import is finished, a notification is sent to
specified Pub/Sub topic. The message data is JSON string of a
[Operation][google.longrunning.Operation].
Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ProductInputConfig

The input config source for products.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product_inline_source() >> / C<< $msg->product_inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::ProductInlineSource>)

The Inline source for the input content for products.

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::GcsSource>)

Google Cloud Storage location for the input content.

=item * C<< $msg->big_query_source() >> / C<< $msg->big_query_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::BigQuerySource>)

BigQuery input source.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::UserEventInputConfig

The input config source for user events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_event_inline_source() >> / C<< $msg->user_event_inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::UserEventInlineSource>)

Required. The Inline source for the input content for UserEvents.

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::GcsSource>)

Required. Google Cloud Storage location for the input content.

=item * C<< $msg->big_query_source() >> / C<< $msg->big_query_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::BigQuerySource>)

Required. BigQuery input source.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::CompletionDataInputConfig

The input config source for completion data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->big_query_source() >> / C<< $msg->big_query_source($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::BigQuerySource>)

Required. BigQuery input source.

Add the IAM permission "BigQuery Data Viewer" for
cloud-retail-customer-data-access@system.gserviceaccount.com before
using this feature otherwise an error is thrown.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportMetadata

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

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportProductsResponse

Response of the
[ImportProductsRequest][google.cloud.retail.v2beta.ImportProductsRequest]. If
the long running operation is done, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::ImportErrorsConfig>)

Echoes the destination for the complete errors in the request if set.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportUserEventsResponse

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

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::ImportErrorsConfig>)

Echoes the destination for the complete errors if this field was set in
the request.

=item * C<< $msg->import_summary() >> / C<< $msg->import_summary($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ImportConfig::UserEventImportSummary>)

Aggregated statistics of user event import status.

=back

=head2 Google::Cloud::Retail::V2beta::ImportConfig::UserEventImportSummary

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

=head2 Google::Cloud::Retail::V2beta::ImportConfig::ImportCompletionDataResponse

Response of the
[ImportCompletionDataRequest][google.cloud.retail.v2beta.ImportCompletionDataRequest].
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ImportConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
