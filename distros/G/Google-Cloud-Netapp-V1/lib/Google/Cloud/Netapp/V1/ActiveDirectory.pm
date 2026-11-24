package Google::Cloud::Netapp::V1::ActiveDirectory;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvbmV0YXBwL3YxL2FjdGl2ZV9kaXJlY3RvcnkucHJvdG8SFmdvb2ds
ZS5jbG91ZC5uZXRhcHAudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItQBChxMaXN0QWN0aXZlRGly
ZWN0b3JpZXNSZXF1ZXN0EkUKBnBhcmVudBgBIAEoCUIt4EEC+kEnEiVuZXRhcHAuZ29vZ2xl
YXBpcy5jb20vQWN0aXZlRGlyZWN0b3J5UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghw
YWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJ
UgZmaWx0ZXISGQoIb3JkZXJfYnkYBSABKAlSB29yZGVyQnkiwQEKHUxpc3RBY3RpdmVEaXJl
Y3Rvcmllc1Jlc3BvbnNlElYKEmFjdGl2ZV9kaXJlY3RvcmllcxgBIAMoCzInLmdvb2dsZS5j
bG91ZC5uZXRhcHAudjEuQWN0aXZlRGlyZWN0b3J5UhFhY3RpdmVEaXJlY3RvcmllcxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyAD
KAlSC3VucmVhY2hhYmxlIl4KGUdldEFjdGl2ZURpcmVjdG9yeVJlcXVlc3QSQQoEbmFtZRgB
IAEoCUIt4EEC+kEnCiVuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQWN0aXZlRGlyZWN0b3J5UgRu
YW1lIvMBChxDcmVhdGVBY3RpdmVEaXJlY3RvcnlSZXF1ZXN0EkUKBnBhcmVudBgBIAEoCUIt
4EEC+kEnEiVuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQWN0aXZlRGlyZWN0b3J5UgZwYXJlbnQS
VwoQYWN0aXZlX2RpcmVjdG9yeRgCIAEoCzInLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuQWN0
aXZlRGlyZWN0b3J5QgPgQQJSD2FjdGl2ZURpcmVjdG9yeRIzChNhY3RpdmVfZGlyZWN0b3J5
X2lkGAMgASgJQgPgQQJSEWFjdGl2ZURpcmVjdG9yeUlkIrkBChxVcGRhdGVBY3RpdmVEaXJl
Y3RvcnlSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrElcKEGFjdGl2ZV9kaXJlY3RvcnkYAiABKAsyJy5n
b29nbGUuY2xvdWQubmV0YXBwLnYxLkFjdGl2ZURpcmVjdG9yeUID4EECUg9hY3RpdmVEaXJl
Y3RvcnkiYQocRGVsZXRlQWN0aXZlRGlyZWN0b3J5UmVxdWVzdBJBCgRuYW1lGAEgASgJQi3g
QQL6QScKJW5ldGFwcC5nb29nbGVhcGlzLmNvbS9BY3RpdmVEaXJlY3RvcnlSBG5hbWUiiAoK
D0FjdGl2ZURpcmVjdG9yeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSQAoLY3JlYXRlX3Rp
bWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUS
SAoFc3RhdGUYAyABKA4yLS5nb29nbGUuY2xvdWQubmV0YXBwLnYxLkFjdGl2ZURpcmVjdG9y
eS5TdGF0ZUID4EEDUgVzdGF0ZRIbCgZkb21haW4YBCABKAlCA+BBAlIGZG9tYWluEhIKBHNp
dGUYBSABKAlSBHNpdGUSFQoDZG5zGAYgASgJQgPgQQJSA2RucxIrCg9uZXRfYmlvc19wcmVm
aXgYByABKAlCA+BBAlINbmV0Qmlvc1ByZWZpeBIvChNvcmdhbml6YXRpb25hbF91bml0GAgg
ASgJUhJvcmdhbml6YXRpb25hbFVuaXQSJQoOYWVzX2VuY3J5cHRpb24YCSABKAhSDWFlc0Vu
Y3J5cHRpb24SHwoIdXNlcm5hbWUYCiABKAlCA+BBAlIIdXNlcm5hbWUSHwoIcGFzc3dvcmQY
CyABKAlCA+BBAlIIcGFzc3dvcmQSLgoQYmFja3VwX29wZXJhdG9ycxgMIAMoCUID4EEBUg9i
YWNrdXBPcGVyYXRvcnMSKwoOYWRtaW5pc3RyYXRvcnMYFiADKAlCA+BBAVIOYWRtaW5pc3Ry
YXRvcnMSMgoSc2VjdXJpdHlfb3BlcmF0b3JzGA0gAygJQgPgQQFSEXNlY3VyaXR5T3BlcmF0
b3JzEiEKDGtkY19ob3N0bmFtZRgOIAEoCVILa2RjSG9zdG5hbWUSFQoGa2RjX2lwGA8gASgJ
UgVrZGNJcBItChNuZnNfdXNlcnNfd2l0aF9sZGFwGBAgASgIUhBuZnNVc2Vyc1dpdGhMZGFw
EiAKC2Rlc2NyaXB0aW9uGBEgASgJUgtkZXNjcmlwdGlvbhIhCgxsZGFwX3NpZ25pbmcYEiAB
KAhSC2xkYXBTaWduaW5nEjQKFmVuY3J5cHRfZGNfY29ubmVjdGlvbnMYEyABKAhSFGVuY3J5
cHREY0Nvbm5lY3Rpb25zEksKBmxhYmVscxgUIAMoCzIzLmdvb2dsZS5jbG91ZC5uZXRhcHAu
djEuQWN0aXZlRGlyZWN0b3J5LkxhYmVsc0VudHJ5UgZsYWJlbHMSKAoNc3RhdGVfZGV0YWls
cxgVIAEoCUID4EEDUgxzdGF0ZURldGFpbHMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJ6CgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEgwKCENSRUFUSU5HEAESCQoFUkVBRFkQAhIMCghVUERBVElORxADEgoKBklO
X1VTRRAEEgwKCERFTEVUSU5HEAUSCQoFRVJST1IQBhIOCgpESUFHTk9TSU5HEAc6nQHqQZkB
CiVuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQWN0aXZlRGlyZWN0b3J5Ekxwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWN0aXZlRGlyZWN0b3JpZXMve2FjdGl2ZV9k
aXJlY3Rvcnl9KhFhY3RpdmVEaXJlY3RvcmllczIPYWN0aXZlRGlyZWN0b3J5QrYBChpjb20u
Z29vZ2xlLmNsb3VkLm5ldGFwcC52MUIUQWN0aXZlRGlyZWN0b3J5UHJvdG9QAVoyY2xvdWQu
Z29vZ2xlLmNvbS9nby9uZXRhcHAvYXBpdjEvbmV0YXBwcGI7bmV0YXBwcGKqAhZHb29nbGUu
Q2xvdWQuTmV0QXBwLlYxygIWR29vZ2xlXENsb3VkXE5ldEFwcFxWMeoCGUdvb2dsZTo6Q2xv
dWQ6Ok5ldEFwcDo6VjFKkz8KBxIFDgDsAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoC
AwMSAxUAKQoICgEIEgMXADMKCQoCCCUSAxcAMwoICgEIEgMYAEkKCQoCCAsSAxgASQoICgEI
EgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADUKCQoCCAgSAxoANQoICgEIEgMbADMKCQoCCAES
AxsAMwoICgEIEgMcADMKCQoCCCkSAxwAMwoICgEIEgMdADIKCQoCCC0SAx0AMgpWCgIEABIE
IAA1ARpKIExpc3RBY3RpdmVEaXJlY3Rvcmllc1JlcXVlc3QgZm9yIHJlcXVlc3RpbmcgbXVs
dGlwbGUgYWN0aXZlIGRpcmVjdG9yaWVzLgoKCgoDBAABEgMgCCQKRwoEBAACABIEIgInBBo5
IFJlcXVpcmVkLiBQYXJlbnQgdmFsdWUgZm9yIExpc3RBY3RpdmVEaXJlY3Rvcmllc1JlcXVl
c3QKCgwKBQQAAgAFEgMiAggKDAoFBAACAAESAyIJDwoMCgUEAAIAAxIDIhITCg0KBQQAAgAI
EgQiFCcDCg8KCAQAAgAInAgAEgMjBCoKDwoHBAACAAifCBIEJAQmBQqQAQoEBAACARIDKwIW
GoIBIFJlcXVlc3RlZCBwYWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJuIGZld2VyIGl0ZW1z
IHRoYW4gcmVxdWVzdGVkLgogSWYgdW5zcGVjaWZpZWQsIHRoZSBzZXJ2ZXIgd2lsbCBwaWNr
IGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoMCgUEAAIBBRIDKwIHCgwKBQQAAgEBEgMrCBEK
DAoFBAACAQMSAysUFQpOCgQEAAICEgMuAhgaQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFn
ZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCgwKBQQAAgIFEgMuAggK
DAoFBAACAgESAy4JEwoMCgUEAAICAxIDLhYXCiAKBAQAAgMSAzECFBoTIEZpbHRlcmluZyBy
ZXN1bHRzCgoMCgUEAAIDBRIDMQIICgwKBQQAAgMBEgMxCQ8KDAoFBAACAwMSAzESEwowCgQE
AAIEEgM0AhYaIyBIaW50IGZvciBob3cgdG8gb3JkZXIgdGhlIHJlc3VsdHMKCgwKBQQAAgQF
EgM0AggKDAoFBAACBAESAzQJEQoMCgUEAAIEAxIDNBQVCloKAgQBEgQ4AEEBGk4gTGlzdEFj
dGl2ZURpcmVjdG9yaWVzUmVzcG9uc2UgY29udGFpbnMgYWxsIHRoZSBhY3RpdmUgZGlyZWN0
b3JpZXMgcmVxdWVzdGVkLgoKCgoDBAEBEgM4CCUKLgoEBAECABIDOgIyGiEgVGhlIGxpc3Qg
b2YgYWN0aXZlIGRpcmVjdG9yaWVzLgoKDAoFBAECAAQSAzoCCgoMCgUEAQIABhIDOgsaCgwK
BQQBAgABEgM6Gy0KDAoFBAECAAMSAzowMQpOCgQEAQIBEgM9Ah0aQSBBIHRva2VuIGlkZW50
aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCgwK
BQQBAgEFEgM9AggKDAoFBAECAQESAz0JGAoMCgUEAQIBAxIDPRscCjMKBAQBAgISA0ACIhom
IExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDAoFBAECAgQSA0ACCgoM
CgUEAQICBRIDQAsRCgwKBQQBAgIBEgNAEh0KDAoFBAECAgMSA0AgIQpHCgIEAhIERABMARo7
IEdldEFjdGl2ZURpcmVjdG9yeSBmb3IgZ2V0dGluZyBhIHNpbmdsZSBhY3RpdmUgZGlyZWN0
b3J5LgoKCgoDBAIBEgNECCEKNwoEBAICABIERgJLBBopIFJlcXVpcmVkLiBOYW1lIG9mIHRo
ZSBhY3RpdmUgZGlyZWN0b3J5LgoKDAoFBAICAAUSA0YCCAoMCgUEAgIAARIDRgkNCgwKBQQC
AgADEgNGEBEKDQoFBAICAAgSBEYSSwMKDwoIBAICAAicCAASA0cEKgoPCgcEAgIACJ8IEgRI
BEoFCkwKAgQDEgRPAGABGkAgQ3JlYXRlQWN0aXZlRGlyZWN0b3J5UmVxdWVzdCBmb3IgY3Jl
YXRpbmcgYW4gYWN0aXZlIGRpcmVjdG9yeS4KCgoKAwQDARIDTwgkCisKBAQDAgASBFECVgQa
HSBSZXF1aXJlZC4gVmFsdWUgZm9yIHBhcmVudC4KCgwKBQQDAgAFEgNRAggKDAoFBAMCAAES
A1EJDwoMCgUEAwIAAxIDURITCg0KBQQDAgAIEgRRFFYDCg8KCAQDAgAInAgAEgNSBCoKDwoH
BAMCAAifCBIEUwRVBQpGCgQEAwIBEgNZAlAaOSBSZXF1aXJlZC4gRmllbGRzIG9mIHRoZSB0
byBiZSBjcmVhdGVkIGFjdGl2ZSBkaXJlY3RvcnkuCgoMCgUEAwIBBhIDWQIRCgwKBQQDAgEB
EgNZEiIKDAoFBAMCAQMSA1klJgoMCgUEAwIBCBIDWSdPCg8KCAQDAgEInAgAEgNZKE4K+wEK
BAQDAgISA18CShrtASBSZXF1aXJlZC4gSUQgb2YgdGhlIGFjdGl2ZSBkaXJlY3RvcnkgdG8g
Y3JlYXRlLiBNdXN0IGJlIHVuaXF1ZSB3aXRoaW4gdGhlCiBwYXJlbnQgcmVzb3VyY2UuIE11
c3QgY29udGFpbiBvbmx5IGxldHRlcnMsIG51bWJlcnMgYW5kIGh5cGhlbiwgd2l0aCB0aGUK
IGZpcnN0IGNoYXJhY3RlciBhIGxldHRlciAsIHRoZSBsYXN0IGEgbGV0dGVyIG9yIGEgbnVt
YmVyLCBhbmQgYSA2MwogY2hhcmFjdGVyIG1heGltdW0uCgoMCgUEAwICBRIDXwIICgwKBQQD
AgIBEgNfCRwKDAoFBAMCAgMSA18fIAoMCgUEAwICCBIDXyFJCg8KCAQDAgIInAgAEgNfIkgK
TAoCBAQSBGMAbgEaQCBVcGRhdGVBY3RpdmVEaXJlY3RvcnlSZXF1ZXN0IGZvciB1cGRhdGlu
ZyBhbiBhY3RpdmUgZGlyZWN0b3J5LgoKCgoDBAQBEgNjCCQK4AIKBAQEAgASBGkCai8a0QIg
UmVxdWlyZWQuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8g
YmUgb3ZlcndyaXR0ZW4gaW4gdGhlCiBBY3RpdmUgRGlyZWN0b3J5IHJlc291cmNlIGJ5IHRo
ZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJl
IHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZp
ZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQog
dXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgd2lsbCBiZSBv
dmVyd3JpdHRlbi4KCgwKBQQEAgAGEgNpAhsKDAoFBAQCAAESA2kcJwoMCgUEBAIAAxIDaSor
CgwKBQQEAgAIEgNqBi4KDwoIBAQCAAicCAASA2oHLQoxCgQEBAIBEgNtAlAaJCBSZXF1aXJl
ZC4gVGhlIHZvbHVtZSBiZWluZyB1cGRhdGVkCgoMCgUEBAIBBhIDbQIRCgwKBQQEAgEBEgNt
EiIKDAoFBAQCAQMSA20lJgoMCgUEBAIBCBIDbSdPCg8KCAQEAgEInAgAEgNtKE4KUgoCBAUS
BHEAeQEaRiBEZWxldGVBY3RpdmVEaXJlY3RvcnlSZXF1ZXN0IGZvciBkZWxldGluZyBhIHNp
bmdsZSBhY3RpdmUgZGlyZWN0b3J5LgoKCgoDBAUBEgNxCCQKNwoEBAUCABIEcwJ4BBopIFJl
cXVpcmVkLiBOYW1lIG9mIHRoZSBhY3RpdmUgZGlyZWN0b3J5LgoKDAoFBAUCAAUSA3MCCAoM
CgUEBQIAARIDcwkNCgwKBQQFAgADEgNzEBEKDQoFBAUCAAgSBHMSeAMKDwoIBAUCAAicCAAS
A3QEKgoPCgcEBQIACJ8IEgR1BHcFClsKAgQGEgV8AOwBARpOIEFjdGl2ZURpcmVjdG9yeSBp
cyB0aGUgcHVibGljIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBhY3RpdmUgZGlyZWN0b3J5IGNv
bmZpZy4KCgoKAwQGARIDfAgXCgwKAwQGBxIFfQKCAQQKDgoFBAYHnQgSBX0CggEECi0KBAQG
BAASBoUBAp0BAxodIFRoZSBBY3RpdmUgRGlyZWN0b3J5IFN0YXRlcwoKDQoFBAYEAAESBIUB
BwwKNAoGBAYEAAIAEgSHAQQaGiQgVW5zcGVjaWZpZWQgQWN0aXZlIERpcmVjdG9yeSBTdGF0
ZQoKDwoHBAYEAAIAARIEhwEEFQoPCgcEBgQAAgACEgSHARgZCjQKBgQGBAACARIEigEEERok
IEFjdGl2ZSBEaXJlY3RvcnkgU3RhdGUgaXMgQ3JlYXRpbmcKCg8KBwQGBAACAQESBIoBBAwK
DwoHBAYEAAIBAhIEigEPEAoxCgYEBgQAAgISBI0BBA4aISBBY3RpdmUgRGlyZWN0b3J5IFN0
YXRlIGlzIFJlYWR5CgoPCgcEBgQAAgIBEgSNAQQJCg8KBwQGBAACAgISBI0BDA0KNAoGBAYE
AAIDEgSQAQQRGiQgQWN0aXZlIERpcmVjdG9yeSBTdGF0ZSBpcyBVcGRhdGluZwoKDwoHBAYE
AAIDARIEkAEEDAoPCgcEBgQAAgMCEgSQAQ8QCjIKBgQGBAACBBIEkwEEDxoiIEFjdGl2ZSBE
aXJlY3RvcnkgU3RhdGUgaXMgSW4gdXNlCgoPCgcEBgQAAgQBEgSTAQQKCg8KBwQGBAACBAIS
BJMBDQ4KNAoGBAYEAAIFEgSWAQQRGiQgQWN0aXZlIERpcmVjdG9yeSBTdGF0ZSBpcyBEZWxl
dGluZwoKDwoHBAYEAAIFARIElgEEDAoPCgcEBgQAAgUCEgSWAQ8QCjEKBgQGBAACBhIEmQEE
DhohIEFjdGl2ZSBEaXJlY3RvcnkgU3RhdGUgaXMgRXJyb3IKCg8KBwQGBAACBgESBJkBBAkK
DwoHBAYEAAIGAhIEmQEMDQo3CgYEBgQAAgcSBJwBBBMaJyBBY3RpdmUgRGlyZWN0b3J5IFN0
YXRlIGlzIERpYWdub3NpbmcuCgoPCgcEBgQAAgcBEgScAQQOCg8KBwQGBAACBwISBJwBERIK
rgEKBAQGAgASBKIBAj0anwEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IGFjdGl2ZSBkaXJlY3RvcnkuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVy
fS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9hY3RpdmVEaXJlY3Rvcmllcy97YWN0aXZlX2Rp
cmVjdG9yeV9pZH1gLgoKDQoFBAYCAAUSBKIBAggKDQoFBAYCAAESBKIBCQ0KDQoFBAYCAAMS
BKIBEBEKDQoFBAYCAAgSBKIBEjwKEAoIBAYCAAicCAASBKIBEzsKQwoEBAYCARIGpQECpgEy
GjMgT3V0cHV0IG9ubHkuIENyZWF0ZSB0aW1lIG9mIHRoZSBhY3RpdmUgZGlyZWN0b3J5LgoK
DQoFBAYCAQYSBKUBAhsKDQoFBAYCAQESBKUBHCcKDQoFBAYCAQMSBKUBKisKDQoFBAYCAQgS
BKYBBjEKEAoIBAYCAQicCAASBKYBBzAKMQoEBAYCAhIEqQECPhojIE91dHB1dCBvbmx5LiBU
aGUgc3RhdGUgb2YgdGhlIEFELgoKDQoFBAYCAgYSBKkBAgcKDQoFBAYCAgESBKkBCA0KDQoF
BAYCAgMSBKkBEBEKDQoFBAYCAggSBKkBEj0KEAoIBAYCAgicCAASBKkBEzwKPQoEBAYCAxIE
rAECPRovIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBBY3RpdmUgRGlyZWN0b3J5IGRvbWFpbgoK
DQoFBAYCAwUSBKwBAggKDQoFBAYCAwESBKwBCQ8KDQoFBAYCAwMSBKwBEhMKDQoFBAYCAwgS
BKwBFDwKEAoIBAYCAwicCAASBKwBFTsKYgoEBAYCBBIEsAECEhpUIFRoZSBBY3RpdmUgRGly
ZWN0b3J5IHNpdGUgdGhlIHNlcnZpY2Ugd2lsbCBsaW1pdCBEb21haW4gQ29udHJvbGxlcgog
ZGlzY292ZXJ5IHRvby4KCg0KBQQGAgQFEgSwAQIICg0KBQQGAgQBEgSwAQkNCg0KBQQGAgQD
EgSwARARCmsKBAQGAgUSBLQBAjoaXSBSZXF1aXJlZC4gQ29tbWEgc2VwYXJhdGVkIGxpc3Qg
b2YgRE5TIHNlcnZlciBJUCBhZGRyZXNzZXMgZm9yIHRoZSBBY3RpdmUKIERpcmVjdG9yeSBk
b21haW4uCgoNCgUEBgIFBRIEtAECCAoNCgUEBgIFARIEtAEJDAoNCgUEBgIFAxIEtAEPEAoN
CgUEBgIFCBIEtAEROQoQCggEBgIFCJwIABIEtAESOApQCgQEBgIGEgS3AQJGGkIgUmVxdWly
ZWQuIE5ldEJJT1NQcmVmaXggaXMgdXNlZCBhcyBhIHByZWZpeCBmb3IgU01CIHNlcnZlciBu
YW1lLgoKDQoFBAYCBgUSBLcBAggKDQoFBAYCBgESBLcBCRgKDQoFBAYCBgMSBLcBGxwKDQoF
BAYCBggSBLcBHUUKEAoIBAYCBgicCAASBLcBHkQKZgoEBAYCBxIEuwECIRpYIFRoZSBPcmdh
bml6YXRpb25hbCBVbml0IChPVSkgd2l0aGluIHRoZSBXaW5kb3dzIEFjdGl2ZSBEaXJlY3Rv
cnkgdGhlIHVzZXIKIGJlbG9uZ3MgdG8uCgoNCgUEBgIHBRIEuwECCAoNCgUEBgIHARIEuwEJ
HAoNCgUEBgIHAxIEuwEfIApRCgQEBgIIEgS+AQIaGkMgSWYgZW5hYmxlZCwgQUVTIGVuY3J5
cHRpb24gd2lsbCBiZSBlbmFibGVkIGZvciBTTUIgY29tbXVuaWNhdGlvbi4KCg0KBQQGAggF
EgS+AQIGCg0KBQQGAggBEgS+AQcVCg0KBQQGAggDEgS+ARgZClAKBAQGAgkSBMEBAkAaQiBS
ZXF1aXJlZC4gVXNlcm5hbWUgb2YgdGhlIEFjdGl2ZSBEaXJlY3RvcnkgZG9tYWluIGFkbWlu
aXN0cmF0b3IuCgoNCgUEBgIJBRIEwQECCAoNCgUEBgIJARIEwQEJEQoNCgUEBgIJAxIEwQEU
FgoNCgUEBgIJCBIEwQEXPwoQCggEBgIJCJwIABIEwQEYPgpQCgQEBgIKEgTEAQJAGkIgUmVx
dWlyZWQuIFBhc3N3b3JkIG9mIHRoZSBBY3RpdmUgRGlyZWN0b3J5IGRvbWFpbiBhZG1pbmlz
dHJhdG9yLgoKDQoFBAYCCgUSBMQBAggKDQoFBAYCCgESBMQBCREKDQoFBAYCCgMSBMQBFBYK
DQoFBAYCCggSBMQBFz8KEAoIBAYCCgicCAASBMQBGD4KZgoEBAYCCxIGyAECyQEvGlYgT3B0
aW9uYWwuIFVzZXJzIHRvIGJlIGFkZGVkIHRvIHRoZSBCdWlsdC1pbiBCYWNrdXAgT3BlcmF0
b3IgYWN0aXZlCiBkaXJlY3RvcnkgZ3JvdXAuCgoNCgUEBgILBBIEyAECCgoNCgUEBgILBRIE
yAELEQoNCgUEBgILARIEyAESIgoNCgUEBgILAxIEyAElJwoNCgUEBgILCBIEyQEGLgoQCggE
BgILCJwIABIEyQEHLQpSCgQEBgIMEgTMAQJPGkQgT3B0aW9uYWwuIFVzZXJzIHRvIGJlIGFk
ZGVkIHRvIHRoZSBCdWlsdC1pbiBBZG1pbmluc3RyYXRvcnMgZ3JvdXAuCgoNCgUEBgIMBBIE
zAECCgoNCgUEBgIMBRIEzAELEQoNCgUEBgIMARIEzAESIAoNCgUEBgIMAxIEzAEjJQoNCgUE
BgIMCBIEzAEmTgoQCggEBgIMCJwIABIEzAEnTQpNCgQEBgINEgbPAQLQAS8aPSBPcHRpb25h
bC4gRG9tYWluIHVzZXJzIHRvIGJlIGdpdmVuIHRoZSBTZVNlY3VyaXR5UHJpdmlsZWdlLgoK
DQoFBAYCDQQSBM8BAgoKDQoFBAYCDQUSBM8BCxEKDQoFBAYCDQESBM8BEiQKDQoFBAYCDQMS
BM8BJykKDQoFBAYCDQgSBNABBi4KEAoIBAYCDQicCAASBNABBy0KegoEBAYCDhIE1AECGxps
IE5hbWUgb2YgdGhlIGFjdGl2ZSBkaXJlY3RvcnkgbWFjaGluZS4gVGhpcyBvcHRpb25hbCBw
YXJhbWV0ZXIgaXMgdXNlZCBvbmx5CiB3aGlsZSBjcmVhdGluZyBrZXJiZXJvcyB2b2x1bWUK
Cg0KBQQGAg4FEgTUAQIICg0KBQQGAg4BEgTUAQkVCg0KBQQGAg4DEgTUARgaCkcKBAQGAg8S
BNcBAhUaOSBLREMgc2VydmVyIElQIGFkZHJlc3MgZm9yIHRoZSBhY3RpdmUgZGlyZWN0b3J5
IG1hY2hpbmUuCgoNCgUEBgIPBRIE1wECCAoNCgUEBgIPARIE1wEJDwoNCgUEBgIPAxIE1wES
FAqNAQoEBAYCEBIE2wECIBp/IElmIGVuYWJsZWQsIHdpbGwgYWxsb3cgYWNjZXNzIHRvIGxv
Y2FsIHVzZXJzIGFuZCBMREFQIHVzZXJzLiBJZiBhY2Nlc3MgaXMKIG5lZWRlZCBmb3Igb25s
eSBMREFQIHVzZXJzLCBpdCBoYXMgdG8gYmUgZGlzYWJsZWQuCgoNCgUEBgIQBRIE2wECBgoN
CgUEBgIQARIE2wEHGgoNCgUEBgIQAxIE2wEdHwo0CgQEBgIREgTeAQIaGiYgRGVzY3JpcHRp
b24gb2YgdGhlIGFjdGl2ZSBkaXJlY3RvcnkuCgoNCgUEBgIRBRIE3gECCAoNCgUEBgIRARIE
3gEJFAoNCgUEBgIRAxIE3gEXGQpNCgQEBgISEgThAQIZGj8gU3BlY2lmaWVzIHdoZXRoZXIg
b3Igbm90IHRoZSBMREFQIHRyYWZmaWMgbmVlZHMgdG8gYmUgc2lnbmVkLgoKDQoFBAYCEgUS
BOEBAgYKDQoFBAYCEgESBOEBBxMKDQoFBAYCEgMSBOEBFhgKaAoEBAYCExIE5QECIxpaIElm
IGVuYWJsZWQsIHRyYWZmaWMgYmV0d2VlbiB0aGUgU01CIHNlcnZlciB0byBEb21haW4gQ29u
dHJvbGxlciAoREMpIHdpbGwKIGJlIGVuY3J5cHRlZC4KCg0KBQQGAhMFEgTlAQIGCg0KBQQG
AhMBEgTlAQcdCg0KBQQGAhMDEgTlASAiCjAKBAQGAhQSBOgBAiIaIiBMYWJlbHMgZm9yIHRo
ZSBhY3RpdmUgZGlyZWN0b3J5LgoKDQoFBAYCFAYSBOgBAhUKDQoFBAYCFAESBOgBFhwKDQoF
BAYCFAMSBOgBHyEKRwoEBAYCFRIE6wECSBo5IE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgZGV0
YWlscyBvZiB0aGUgQWN0aXZlIERpcmVjdG9yeS4KCg0KBQQGAhUFEgTrAQIICg0KBQQGAhUB
EgTrAQkWCg0KBQQGAhUDEgTrARkbCg0KBQQGAhUIEgTrARxHChAKCAQGAhUInAgAEgTrAR1G
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest ===
    # Fields for ListActiveDirectoriesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesResponse ===
    # Fields for ListActiveDirectoriesResponse
    # Field: active_directories Type: 11 (.google.cloud.netapp.v1.ActiveDirectory)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::GetActiveDirectoryRequest ===
    # Fields for GetActiveDirectoryRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::CreateActiveDirectoryRequest ===
    # Fields for CreateActiveDirectoryRequest
    # Field: parent Type: 9 ()
    # Field: active_directory Type: 11 (.google.cloud.netapp.v1.ActiveDirectory)
    # Field: active_directory_id Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::UpdateActiveDirectoryRequest ===
    # Fields for UpdateActiveDirectoryRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: active_directory Type: 11 (.google.cloud.netapp.v1.ActiveDirectory)

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::DeleteActiveDirectoryRequest ===
    # Fields for DeleteActiveDirectoryRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory ===
    # Fields for ActiveDirectory
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.netapp.v1.ActiveDirectory.State)
    # Field: domain Type: 9 ()
    # Field: site Type: 9 ()
    # Field: dns Type: 9 ()
    # Field: net_bios_prefix Type: 9 ()
    # Field: organizational_unit Type: 9 ()
    # Field: aes_encryption Type: 8 ()
    # Field: username Type: 9 ()
    # Field: password Type: 9 ()
    # Field: backup_operators Type: 9 ()
    # Field: administrators Type: 9 ()
    # Field: security_operators Type: 9 ()
    # Field: kdc_hostname Type: 9 ()
    # Field: kdc_ip Type: 9 ()
    # Field: nfs_users_with_ldap Type: 8 ()
    # Field: description Type: 9 ()
    # Field: ldap_signing Type: 8 ()
    # Field: encrypt_dc_connections Type: 8 ()
    # Field: labels Type: 11 (.google.cloud.netapp.v1.ActiveDirectory.LabelsEntry)
    # Field: state_details Type: 9 ()

# Enum: ActiveDirectory::State
our $ActiveDirectory_STATE_UNSPECIFIED = 0;
our $ActiveDirectory_CREATING = 1;
our $ActiveDirectory_READY = 2;
our $ActiveDirectory_UPDATING = 3;
our $ActiveDirectory_IN_USE = 4;
our $ActiveDirectory_DELETING = 5;
our $ActiveDirectory_ERROR = 6;
our $ActiveDirectory_DIAGNOSING = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::ActiveDirectory - Compiled Protocol Buffers messages for google/cloud/netapp/v1/active_directory.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::ActiveDirectory;

    my $msg = Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/active_directory.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesRequest

ListActiveDirectoriesRequest for requesting multiple active directories.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListActiveDirectoriesRequest

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Server may return fewer items than requested.
If unspecified, the server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filtering results

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Hint for how to order the results

=back

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::ListActiveDirectoriesResponse

ListActiveDirectoriesResponse contains all the active directories requested.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->active_directories() >> / C<< $msg->active_directories($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory>)

The list of active directories.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::GetActiveDirectoryRequest

GetActiveDirectory for getting a single active directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the active directory.

=back

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::CreateActiveDirectoryRequest

CreateActiveDirectoryRequest for creating an active directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Value for parent.

=item * C<< $msg->active_directory() >> / C<< $msg->active_directory($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory>)

Required. Fields of the to be created active directory.

=item * C<< $msg->active_directory_id() >> / C<< $msg->active_directory_id($value) >>

Type: C<String>

Required. ID of the active directory to create. Must be unique within the
parent resource. Must contain only letters, numbers and hyphen, with the
first character a letter , the last a letter or a number, and a 63
character maximum.

=back

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::UpdateActiveDirectoryRequest

UpdateActiveDirectoryRequest for updating an active directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
Active Directory resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->active_directory() >> / C<< $msg->active_directory($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory>)

Required. The volume being updated

=back

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::DeleteActiveDirectoryRequest

DeleteActiveDirectoryRequest for deleting a single active directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the active directory.

=back

=head2 Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory

ActiveDirectory is the public representation of the active directory config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the active directory.
Format:
`projects/{project_number}/locations/{location_id}/activeDirectories/{active_directory_id}`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the active directory.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::ActiveDirectory::State>)

Output only. The state of the AD.

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

Required. Name of the Active Directory domain

=item * C<< $msg->site() >> / C<< $msg->site($value) >>

Type: C<String>

The Active Directory site the service will limit Domain Controller
discovery too.

=item * C<< $msg->dns() >> / C<< $msg->dns($value) >>

Type: C<String>

Required. Comma separated list of DNS server IP addresses for the Active
Directory domain.

=item * C<< $msg->net_bios_prefix() >> / C<< $msg->net_bios_prefix($value) >>

Type: C<String>

Required. NetBIOSPrefix is used as a prefix for SMB server name.

=item * C<< $msg->organizational_unit() >> / C<< $msg->organizational_unit($value) >>

Type: C<String>

The Organizational Unit (OU) within the Windows Active Directory the user
belongs to.

=item * C<< $msg->aes_encryption() >> / C<< $msg->aes_encryption($value) >>

Type: C<Bool>

If enabled, AES encryption will be enabled for SMB communication.

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

Required. Username of the Active Directory domain administrator.

=item * C<< $msg->password() >> / C<< $msg->password($value) >>

Type: C<String>

Required. Password of the Active Directory domain administrator.

=item * C<< $msg->backup_operators() >> / C<< $msg->backup_operators($value) >>

Type: C<String>

Optional. Users to be added to the Built-in Backup Operator active
directory group.

=item * C<< $msg->administrators() >> / C<< $msg->administrators($value) >>

Type: C<String>

Optional. Users to be added to the Built-in Admininstrators group.

=item * C<< $msg->security_operators() >> / C<< $msg->security_operators($value) >>

Type: C<String>

Optional. Domain users to be given the SeSecurityPrivilege.

=item * C<< $msg->kdc_hostname() >> / C<< $msg->kdc_hostname($value) >>

Type: C<String>

Name of the active directory machine. This optional parameter is used only
while creating kerberos volume

=item * C<< $msg->kdc_ip() >> / C<< $msg->kdc_ip($value) >>

Type: C<String>

KDC server IP address for the active directory machine.

=item * C<< $msg->nfs_users_with_ldap() >> / C<< $msg->nfs_users_with_ldap($value) >>

Type: C<Bool>

If enabled, will allow access to local users and LDAP users. If access is
needed for only LDAP users, it has to be disabled.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the active directory.

=item * C<< $msg->ldap_signing() >> / C<< $msg->ldap_signing($value) >>

Type: C<Bool>

Specifies whether or not the LDAP traffic needs to be signed.

=item * C<< $msg->encrypt_dc_connections() >> / C<< $msg->encrypt_dc_connections($value) >>

Type: C<Bool>

If enabled, traffic between the SMB server to Domain Controller (DC) will
be encrypted.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::ActiveDirectory::ActiveDirectory::LabelsEntry>)

Labels for the active directory.

=item * C<< $msg->state_details() >> / C<< $msg->state_details($value) >>

Type: C<String>

Output only. The state details of the Active Directory.

=back

=head3 Enum: ActiveDirectory::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<UPDATING> => C<3>

=item * C<IN_USE> => C<4>

=item * C<DELETING> => C<5>

=item * C<ERROR> => C<6>

=item * C<DIAGNOSING> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::ActiveDirectory::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
