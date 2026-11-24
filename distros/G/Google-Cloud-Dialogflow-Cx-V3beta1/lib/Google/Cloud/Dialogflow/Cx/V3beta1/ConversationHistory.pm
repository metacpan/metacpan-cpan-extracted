package Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Environment };
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Flow };
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Intent };
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Page };
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Session };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2NvbnZlcnNhdGlvbl9oaXN0
b3J5LnByb3RvEiJnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0
Z29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvY3gvdjNiZXRhMS9lbnZpcm9ubWVudC5wcm90bxot
Z29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvY3gvdjNiZXRhMS9mbG93LnByb3RvGi9nb29nbGUv
Y2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2ludGVudC5wcm90bxotZ29vZ2xlL2Nsb3Vk
L2RpYWxvZ2Zsb3cvY3gvdjNiZXRhMS9wYWdlLnByb3RvGjBnb29nbGUvY2xvdWQvZGlhbG9n
Zmxvdy9jeC92M2JldGExL3Nlc3Npb24ucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlv
bi5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvIlwKFkdldENvbnZlcnNhdGlvblJlcXVlc3QSQgoEbmFtZRgBIAEo
CUIu4EEC+kEoCiZkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbnZlcnNhdGlvblIEbmFt
ZSJfChlEZWxldGVDb252ZXJzYXRpb25SZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpBKAom
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Db252ZXJzYXRpb25SBG5hbWUixQEKGExpc3RD
b252ZXJzYXRpb25zUmVxdWVzdBJGCgZwYXJlbnQYASABKAlCLuBBAvpBKBImZGlhbG9nZmxv
dy5nb29nbGVhcGlzLmNvbS9Db252ZXJzYXRpb25SBnBhcmVudBIbCgZmaWx0ZXIYAiABKAlC
A+BBAVIGZmlsdGVyEiAKCXBhZ2Vfc2l6ZRgDIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdl
X3Rva2VuGAQgASgJQgPgQQFSCXBhZ2VUb2tlbiKbAQoZTGlzdENvbnZlcnNhdGlvbnNSZXNw
b25zZRJWCg1jb252ZXJzYXRpb25zGAEgAygLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5Db252ZXJzYXRpb25SDWNvbnZlcnNhdGlvbnMSJgoPbmV4dF9wYWdlX3Rv
a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrgZCgxDb252ZXJzYXRpb24SFwoEbmFtZRgBIAEo
CUID4EEIUgRuYW1lEkkKBHR5cGUYAiABKA4yNS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLkNvbnZlcnNhdGlvbi5UeXBlUgR0eXBlEiMKDWxhbmd1YWdlX2NvZGUYAyAB
KAlSDGxhbmd1YWdlQ29kZRI5CgpzdGFydF90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGR1cmF0aW9uGAUgASgLMhkuZ29vZ2xlLnByb3Rv
YnVmLkR1cmF0aW9uUghkdXJhdGlvbhJSCgdtZXRyaWNzGAYgASgLMjguZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5Db252ZXJzYXRpb24uTWV0cmljc1IHbWV0cmljcxJE
CgdpbnRlbnRzGAcgAygLMiouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5J
bnRlbnRSB2ludGVudHMSPgoFZmxvd3MYCCADKAsyKC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52M2JldGExLkZsb3dSBWZsb3dzEj4KBXBhZ2VzGAkgAygLMiguZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5QYWdlUgVwYWdlcxJgCgxpbnRlcmFjdGlvbnMYCiAD
KAsyPC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkNvbnZlcnNhdGlvbi5J
bnRlcmFjdGlvblIMaW50ZXJhY3Rpb25zElEKC2Vudmlyb25tZW50GAsgASgLMi8uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5FbnZpcm9ubWVudFILZW52aXJvbm1lbnQS
ZwoNZmxvd192ZXJzaW9ucxgMIAMoCzJCLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuQ29udmVyc2F0aW9uLkZsb3dWZXJzaW9uc0VudHJ5UgxmbG93VmVyc2lvbnMalAkK
B01ldHJpY3MSKwoRaW50ZXJhY3Rpb25fY291bnQYASABKAVSEGludGVyYWN0aW9uQ291bnQS
SwoUaW5wdXRfYXVkaW9fZHVyYXRpb24YAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRp
b25SEmlucHV0QXVkaW9EdXJhdGlvbhJNChVvdXRwdXRfYXVkaW9fZHVyYXRpb24YAyABKAsy
GS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SE291dHB1dEF1ZGlvRHVyYXRpb24SSQoTbWF4
X3dlYmhvb2tfbGF0ZW5jeRgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIRbWF4
V2ViaG9va0xhdGVuY3kSLgoTaGFzX2VuZF9pbnRlcmFjdGlvbhgFIAEoCFIRaGFzRW5kSW50
ZXJhY3Rpb24SMwoWaGFzX2xpdmVfYWdlbnRfaGFuZG9mZhgGIAEoCFITaGFzTGl2ZUFnZW50
SGFuZG9mZhI4ChhhdmVyYWdlX21hdGNoX2NvbmZpZGVuY2UYByABKAJSFmF2ZXJhZ2VNYXRj
aENvbmZpZGVuY2USdAoRcXVlcnlfaW5wdXRfY291bnQYCCABKAsySC5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLkNvbnZlcnNhdGlvbi5NZXRyaWNzLlF1ZXJ5SW5wdXRD
b3VudFIPcXVlcnlJbnB1dENvdW50EnEKEG1hdGNoX3R5cGVfY291bnQYCSABKAsyRy5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkNvbnZlcnNhdGlvbi5NZXRyaWNzLk1h
dGNoVHlwZUNvdW50Ug5tYXRjaFR5cGVDb3VudBq0AQoPUXVlcnlJbnB1dENvdW50Eh0KCnRl
eHRfY291bnQYASABKAVSCXRleHRDb3VudBIhCgxpbnRlbnRfY291bnQYAiABKAVSC2ludGVu
dENvdW50Eh8KC2F1ZGlvX2NvdW50GAMgASgFUgphdWRpb0NvdW50Eh8KC2V2ZW50X2NvdW50
GAQgASgFUgpldmVudENvdW50Eh0KCmR0bWZfY291bnQYBSABKAVSCWR0bWZDb3VudBq1AgoO
TWF0Y2hUeXBlQ291bnQSKwoRdW5zcGVjaWZpZWRfY291bnQYASABKAVSEHVuc3BlY2lmaWVk
Q291bnQSIQoMaW50ZW50X2NvdW50GAIgASgFUgtpbnRlbnRDb3VudBIuChNkaXJlY3RfaW50
ZW50X2NvdW50GAMgASgFUhFkaXJlY3RJbnRlbnRDb3VudBI2ChdwYXJhbWV0ZXJfZmlsbGlu
Z19jb3VudBgEIAEoBVIVcGFyYW1ldGVyRmlsbGluZ0NvdW50EiQKDm5vX21hdGNoX2NvdW50
GAUgASgFUgxub01hdGNoQ291bnQSJAoObm9faW5wdXRfY291bnQYBiABKAVSDG5vSW5wdXRD
b3VudBIfCgtldmVudF9jb3VudBgHIAEoBVIKZXZlbnRDb3VudBq2BwoLSW50ZXJhY3Rpb24S
UQoHcmVxdWVzdBgBIAEoCzI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEu
RGV0ZWN0SW50ZW50UmVxdWVzdFIHcmVxdWVzdBJUCghyZXNwb25zZRgCIAEoCzI4Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRGV0ZWN0SW50ZW50UmVzcG9uc2VSCHJl
c3BvbnNlEmUKEXBhcnRpYWxfcmVzcG9uc2VzGAMgAygLMjguZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjNiZXRhMS5EZXRlY3RJbnRlbnRSZXNwb25zZVIQcGFydGlhbFJlc3BvbnNl
cxItChJyZXF1ZXN0X3V0dGVyYW5jZXMYBCABKAlSEXJlcXVlc3RVdHRlcmFuY2VzEi8KE3Jl
c3BvbnNlX3V0dGVyYW5jZXMYBSABKAlSEnJlc3BvbnNlVXR0ZXJhbmNlcxI7CgtjcmVhdGVf
dGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSWwoP
YW5zd2VyX2ZlZWRiYWNrGAcgASgLMjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5BbnN3ZXJGZWVkYmFja1IOYW5zd2VyRmVlZGJhY2sSfQoSbWlzc2luZ190cmFuc2l0
aW9uGAggASgLMk4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5Db252ZXJz
YXRpb24uSW50ZXJhY3Rpb24uTWlzc2luZ1RyYW5zaXRpb25SEW1pc3NpbmdUcmFuc2l0aW9u
EmsKDHN0ZXBfbWV0cmljcxgJIAMoCzJILmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuQ29udmVyc2F0aW9uLkludGVyYWN0aW9uLlN0ZXBNZXRyaWNzUgtzdGVwTWV0cmlj
cxpZChFNaXNzaW5nVHJhbnNpdGlvbhIuChNpbnRlbnRfZGlzcGxheV9uYW1lGAEgASgJUhFp
bnRlbnREaXNwbGF5TmFtZRIUCgVzY29yZRgCIAEoAlIFc2NvcmUaVgoLU3RlcE1ldHJpY3MS
EgoEbmFtZRgBIAEoCVIEbmFtZRIzCgdsYXRlbmN5GAIgASgLMhkuZ29vZ2xlLnByb3RvYnVm
LkR1cmF0aW9uUgdsYXRlbmN5Gj8KEUZsb3dWZXJzaW9uc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EhQKBXZhbHVlGAIgASgDUgV2YWx1ZToCOAEiQwoEVHlwZRIUChBUWVBFX1VOU1BFQ0lG
SUVEEAASCQoFQVVESU8QARIICgRURVhUEAISEAoMVU5ERVRFUk1JTkVEEAM6ngHqQZoBCiZk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbnZlcnNhdGlvbhJTcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdlbnR9L2NvbnZlcnNhdGlvbnMv
e2NvbnZlcnNhdGlvbn0qDWNvbnZlcnNhdGlvbnMyDGNvbnZlcnNhdGlvbjKEBgoTQ29udmVy
c2F0aW9uSGlzdG9yeRLiAQoRTGlzdENvbnZlcnNhdGlvbnMSPC5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52M2JldGExLkxpc3RDb252ZXJzYXRpb25zUmVxdWVzdBo9Lmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuTGlzdENvbnZlcnNhdGlvbnNSZXNwb25zZSJQ
gtPkkwJBEj8vdjNiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRz
Lyp9L2NvbnZlcnNhdGlvbnPaQQZwYXJlbnQSzwEKD0dldENvbnZlcnNhdGlvbhI6Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2V0Q29udmVyc2F0aW9uUmVxdWVzdBow
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuQ29udmVyc2F0aW9uIk6C0+ST
AkESPy92M2JldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovY29u
dmVyc2F0aW9ucy8qfdpBBG5hbWUSuwEKEkRlbGV0ZUNvbnZlcnNhdGlvbhI9Lmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRGVsZXRlQ29udmVyc2F0aW9uUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJOgtPkkwJBKj8vdjNiZXRhMS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2NvbnZlcnNhdGlvbnMvKn3aQQRuYW1lGnjKQRlk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rp
YWxvZ2Zsb3dCzwEKJmNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExQhhD
b252ZXJzYXRpb25IaXN0b3J5UHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dm
bG93L2N4L2FwaXYzYmV0YTEvY3hwYjtjeHBiogICREaqAiJHb29nbGUuQ2xvdWQuRGlhbG9n
Zmxvdy5DeC5WM0JldGEx6gImR29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6Q1g6OlYzYmV0
YTFKwG0KBxIFDgCBAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgID
BBIDFgA+CgkKAgMFEgMXADcKCQoCAwYSAxgAOQoJCgIDBxIDGQA3CgkKAgMIEgMaADoKCQoC
AwkSAxsAKAoJCgIDChIDHAAlCgkKAgMLEgMdACkKCAoBCBIDHwA/CgkKAgglEgMfAD8KCAoB
CBIDIABNCgkKAggLEgMgAE0KCAoBCBIDIQAiCgkKAggKEgMhACIKCAoBCBIDIgA5CgkKAggI
EgMiADkKCAoBCBIDIwA/CgkKAggBEgMjAD8KCAoBCBIDJAAgCgkKAggkEgMkACAKCAoBCBID
JQA/CgkKAggtEgMlAD8KOAoCBgASBCgARwEaLCBTZXJ2aWNlIGZvciBtYW5hZ2luZyBjb252
ZXJzYXRpb24gaGlzdG9yeS4KCgoKAwYAARIDKAgbCgoKAwYAAxIDKQJBCgwKBQYAA5kIEgMp
AkEKCwoDBgADEgQqAiwzCg0KBQYAA5oIEgQqAiwzCjYKBAYAAgASBC8CNQMaKCBSZXR1cm5z
IHRoZSBsaXN0IG9mIGFsbCBjb252ZXJzYXRpb25zLgoKDAoFBgACAAESAy8GFwoMCgUGAAIA
AhIDLxgwCgwKBQYAAgADEgMwDygKDQoFBgACAAQSBDEEMwYKEQoJBgACAASwyrwiEgQxBDMG
CgwKBQYAAgAEEgM0BDQKDwoIBgACAASbCAASAzQENAo1CgQGAAIBEgQ4Aj0DGicgUmV0cmll
dmVzIHRoZSBzcGVjaWZpZWQgY29udmVyc2F0aW9uLgoKDAoFBgACAQESAzgGFQoMCgUGAAIB
AhIDOBYsCgwKBQYAAgEDEgM4N0MKDQoFBgACAQQSBDkEOwYKEQoJBgACAQSwyrwiEgQ5BDsG
CgwKBQYAAgEEEgM8BDIKDwoIBgACAQSbCAASAzwEMgozCgQGAAICEgRAAkYDGiUgRGVsZXRl
cyB0aGUgc3BlY2lmaWVkIGNvbnZlcnNhdGlvbi4KCgwKBQYAAgIBEgNABhgKDAoFBgACAgIS
A0AZMgoMCgUGAAICAxIDQQ8kCg0KBQYAAgIEEgRCBEQGChEKCQYAAgIEsMq8IhIEQgREBgoM
CgUGAAICBBIDRQQyCg8KCAYAAgIEmwgAEgNFBDIKSAoCBAASBEoAVAEaPCBUaGUgcmVxdWVz
dCBtZXNzYWdlIGZvciBbQ29udmVyc2F0aW9ucy5HZXRDb252ZXJzYXRpb25dW10uCgoKCgME
AAESA0oIHgqhAQoEBAACABIETgJTBBqSASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGNv
bnZlcnNhdGlvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMv
PExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vY29udmVyc2F0aW9ucy88Q29udmVyc2F0
aW9uSUQ+YC4KCgwKBQQAAgAFEgNOAggKDAoFBAACAAESA04JDQoMCgUEAAIAAxIDThARCg0K
BQQAAgAIEgROElMDCg8KCAQAAgAInAgAEgNPBCoKDwoHBAACAAifCBIEUARSBQpLCgIEARIE
VwBhARo/IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIFtDb252ZXJzYXRpb25zLkRlbGV0ZUNv
bnZlcnNhdGlvbl1bXS4KCgoKAwQBARIDVwghCqEBCgQEAQIAEgRbAmAEGpIBIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgY29udmVyc2F0aW9uLgogRm9ybWF0OgogYHByb2plY3RzLzxQ
cm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9jb252
ZXJzYXRpb25zLzxDb252ZXJzYXRpb25JRD5gLgoKDAoFBAECAAUSA1sCCAoMCgUEAQIAARID
WwkNCgwKBQQBAgADEgNbEBEKDQoFBAECAAgSBFsSYAMKDwoIBAECAAicCAASA1wEKgoPCgcE
AQIACJ8IEgRdBF8FCksKAgQCEgVkAIIBARo+IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIFtD
b252ZXJzYXRpb25zLkxpc3RDb252ZXJzYXRpb25zXVtdLgoKCgoDBAIBEgNkCCAKiwEKBAQC
AgASBGcCbAQafSBSZXF1aXJlZC4gVGhlIGFnZW50IHRvIGxpc3QgYWxsIGNvbnZlcnNhdGlv
bnMgZm9yLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2Nh
dGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+YC4KCgwKBQQCAgAFEgNnAggKDAoFBAICAAESA2cJ
DwoMCgUEAgIAAxIDZxITCg0KBQQCAgAIEgRnFGwDCg8KCAQCAgAInAgAEgNoBCoKDwoHBAIC
AAifCBIEaQRrBQrWBAoEBAICARIDegI9GsgEIE9wdGlvbmFsLiBUaGUgZmlsdGVyIHN0cmlu
Zy4gU3VwcG9ydHMgZmlsdGVyIGJ5IGNyZWF0ZV90aW1lLAogbWV0cmljcy5oYXNfZW5kX2lu
dGVyYWN0aW9uLCBtZXRyaWNzLmhhc19saXZlX2FnZW50X2hhbmRvZmYsCiBpbnRlbnRzLmRp
c3BsYXlfbmFtZSwgcGFnZXMuZGlzcGxheV9uYW1lIGFuZCBmbG93cy5kaXNwbGF5X25hbWUu
IFRpbWVzdGFtcHMKIGV4cGVjdCBhbiBbUkZDLTMzMzldW2h0dHBzOi8vZGF0YXRyYWNrZXIu
aWV0Zi5vcmcvZG9jL2h0bWwvcmZjMzMzOV0KIGZvcm1hdHRlZCBzdHJpbmcgKGUuZy4gMjAx
Mi0wNC0yMVQxMTozMDowMC0wNDowMCkuIFVUQyBvZmZzZXRzIGFyZQogc3VwcG9ydGVkLiBT
b21lIGV4YW1wbGVzOgogICAxLiBCeSBjcmVhdGUgdGltZToKICAgICAgICBjcmVhdGVfdGlt
ZSA+ICIyMDIyLTA0LTIxVDExOjMwOjAwLTA0OjAwIgogICAyLiBCeSBpbnRlbnQgZGlzcGxh
eSBuYW1lOgogICAgICAgIGludGVudHMuZGlzcGxheV9uYW1lIDogImJpbGxpbmciCiAgIDMu
IEJ5IGVuZCBpbnRlcmFjdGlvbiBzaWduYWw6CiAgICAgICAgbWV0cmljcy5oYXNfZW5kX2lu
dGVyYWN0aW9uID0gdHJ1ZQoKDAoFBAICAQUSA3oCCAoMCgUEAgIBARIDegkPCgwKBQQCAgED
EgN6EhMKDAoFBAICAQgSA3oUPAoPCggEAgIBCJwIABIDehU7CnIKBAQCAgISA34CPxplIE9w
dGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2lu
Z2xlIHBhZ2UuIEJ5CiBkZWZhdWx0IDEwMCBhbmQgYXQgbW9zdCAxMDAwLgoKDAoFBAICAgUS
A34CBwoMCgUEAgICARIDfggRCgwKBQQCAgIDEgN+FBUKDAoFBAICAggSA34WPgoPCggEAgIC
CJwIABIDfhc9CloKBAQCAgMSBIEBAkEaTCBPcHRpb25hbC4gVGhlIG5leHRfcGFnZV90b2tl
biB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAIC
AwUSBIEBAggKDQoFBAICAwESBIEBCRMKDQoFBAICAwMSBIEBFhcKDQoFBAICAwgSBIEBGEAK
EAoIBAICAwicCAASBIEBGT8KTQoCBAMSBoUBAJABARo/IFRoZSByZXNwb25zZSBtZXNzYWdl
IGZvciBbQ29udmVyc2F0aW9ucy5MaXN0Q29udmVyc2F0aW9uc11bXS4KCgsKAwQDARIEhQEI
IQqwAgoEBAMCABIEiwECKhqhAiBUaGUgbGlzdCBvZiBjb252ZXJzYXRpb25zLiBUaGVyZSB3
aWxsIGJlIGEgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgcmV0dXJuZWQKIGJhc2VkIG9uIHRo
ZQogW3BhZ2Vfc2l6ZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5MaXN0
Q29udmVyc2F0aW9uc1JlcXVlc3QucGFnZV9zaXplXQogZmllbGQuIFRoZSByZXR1cm5lZCBj
b252ZXJzYXRpb25zIHdpbGwgYmUgc29ydGVkIGJ5IHN0YXJ0X3RpbWUgaW4KIGRlc2NlbmRp
bmcgb3JkZXIgKG5ld2VzdCBjb252ZXJzYXRpb24gZmlyc3QpLgoKDQoFBAMCAAQSBIsBAgoK
DQoFBAMCAAYSBIsBCxcKDQoFBAMCAAESBIsBGCUKDQoFBAMCAAMSBIsBKCkKbwoEBAMCARIE
jwECHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3Ig
ZW1wdHkgaWYgdGhlcmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUE
AwIBBRIEjwECCAoNCgUEAwIBARIEjwEJGAoNCgUEAwIBAxIEjwEbHAoqCgIEBBIGkwEAgQMB
GhwgUmVwcmVzZW50cyBhIGNvbnZlcnNhdGlvbi4KCgsKAwQEARIEkwEIFAoNCgMEBAcSBpQB
ApkBBAoPCgUEBAedCBIGlAECmQEECjgKBAQEBAASBpwBAq0BAxooIFJlcHJlc2VudHMgdGhl
IHR5cGUgb2YgYSBjb252ZXJzYXRpb24uCgoNCgUEBAQAARIEnAEHCwpBCgYEBAQAAgASBJ4B
BBkaMSBOb3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIHNob3VsZCBuZXZlciBiZSB1c2VkLgoK
DwoHBAQEAAIAARIEngEEFAoPCgcEBAQAAgACEgSeARcYCqYBCgYEBAQAAgESBKIBBA4alQEg
QXVkaW8gY29udmVyc2F0aW9uLiBBIGNvbnZlcnNhdGlvbiBpcyBjbGFzc2lmaWVkIGFzIGFu
IGF1ZGlvIGNvbnZlcnNhdGlvbgogaWYgYW55IHJlcXVlc3QgaGFzIFNUVCBpbnB1dCBhdWRp
byBvciBhbnkgcmVzcG9uc2UgaGFzIFRUUyBvdXRwdXQgYXVkaW8uCgoPCgcEBAQAAgEBEgSi
AQQJCg8KBwQEBAACAQISBKIBDA0KwgEKBgQEBAACAhIEpwEEDRqxASBUZXh0IGNvbnZlcnNh
dGlvbi4gQSBjb252ZXJzYXRpb24gaXMgY2xhc3NpZmllZCBhcyBhIHRleHQgY29udmVyc2F0
aW9uCiBpZiBhbnkgcmVxdWVzdCBoYXMgdGV4dCBpbnB1dCBhbmQgbm8gcmVxdWVzdCBoYXMg
U1RUIGlucHV0IGF1ZGlvIGFuZCBubwogcmVzcG9uc2UgaGFzIFRUUyBvdXRwdXQgYXVkaW8u
CgoPCgcEBAQAAgIBEgSnAQQICg8KBwQEBAACAgISBKcBCwwKwAEKBgQEBAACAxIErAEEFRqv
ASBEZWZhdWx0IGNvbnZlcnNhdGlvbiB0eXBlIGZvciBhIGNvbnZlcnNhdGlvbi4gQSBjb252
ZXJzYXRpb24gaXMKIGNsYXNzaWZpZWQgYXMgdW5kZXRlcm1pbmVkIGlmIG5vbmUgb2YgdGhl
IHJlcXVlc3RzIGNvbnRhaW4gdGV4dCBvciBhdWRpbwogaW5wdXQgKGVnLiBldmVudCBvciBp
bnRlbnQgaW5wdXQpLgoKDwoHBAQEAAIDARIErAEEEAoPCgcEBAQAAgMCEgSsARMUCjoKBAQE
AwASBrABApMCAxoqIFJlcHJlc2VudHMgbWV0cmljcyBmb3IgdGhlIGNvbnZlcnNhdGlvbi4K
Cg0KBQQEAwABEgSwAQoRCogBCgYEBAMAAwASBrQBBMsBBRp2IENvdW50IGJ5IHR5cGVzIG9m
CiBbUXVlcnlJbnB1dF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5RdWVy
eUlucHV0XSBvZiB0aGUKIHJlcXVlc3RzIGluIHRoZSBjb252ZXJzYXRpb24uCgoPCgcEBAMA
AwABEgS0AQwbCnEKCAQEAwADAAIAEgS3AQYbGl8gVGhlIG51bWJlciBvZiBbVGV4dElucHV0
XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlRleHRJbnB1dF0KIGluIHRo
ZSBjb252ZXJzYXRpb24uCgoRCgkEBAMAAwACAAUSBLcBBgsKEQoJBAQDAAMAAgABEgS3AQwW
ChEKCQQEAwADAAIAAxIEtwEZGgp2CggEBAMAAwACARIEvAEGHRpkIFRoZSBudW1iZXIgb2YK
IFtJbnRlbnRJbnB1dF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5JbnRl
bnRJbnB1dF0gaW4gdGhlCiBjb252ZXJzYXRpb24uCgoRCgkEBAMAAwACAQUSBLwBBgsKEQoJ
BAQDAAMAAgEBEgS8AQwYChEKCQQEAwADAAIBAxIEvAEbHAp0CggEBAMAAwACAhIEwQEGHBpi
IFRoZSBudW1iZXIgb2YKIFtBdWRpb0lucHV0XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLkF1ZGlvSW5wdXRdIGluIHRoZQogY29udmVyc2F0aW9uLgoKEQoJBAQDAAMA
AgIFEgTBAQYLChEKCQQEAwADAAICARIEwQEMFwoRCgkEBAMAAwACAgMSBMEBGhsKdAoIBAQD
AAMAAgMSBMYBBhwaYiBUaGUgbnVtYmVyIG9mCiBbRXZlbnRJbnB1dF1bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5FdmVudElucHV0XSBpbiB0aGUKIGNvbnZlcnNhdGlv
bi4KChEKCQQEAwADAAIDBRIExgEGCwoRCgkEBAMAAwACAwESBMYBDBcKEQoJBAQDAAMAAgMD
EgTGARobCnEKCAQEAwADAAIEEgTKAQYbGl8gVGhlIG51bWJlciBvZiBbRHRtZklucHV0XVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkR0bWZJbnB1dF0KIGluIHRoZSBj
b252ZXJzYXRpb24uCgoRCgkEBAMAAwACBAUSBMoBBgsKEQoJBAQDAAMAAgQBEgTKAQwWChEK
CQQEAwADAAIEAxIEygEZGgqIAQoGBAQDAAMBEgbQAQTsAQUadiBDb3VudCBieQogW01hdGNo
Lk1hdGNoVHlwZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5NYXRjaC5N
YXRjaFR5cGVdIG9mCiB0aGUgbWF0Y2hlcyBpbiB0aGUgY29udmVyc2F0aW9uLgoKDwoHBAQD
AAMBARIE0AEMGgqqAQoIBAQDAAMBAgASBNMBBiIalwEgVGhlIG51bWJlciBvZiBtYXRjaGVz
IHdpdGggdHlwZQogW01hdGNoLk1hdGNoVHlwZS5NQVRDSF9UWVBFX1VOU1BFQ0lGSUVEXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLk1hdGNoLk1hdGNoVHlwZS5NQVRD
SF9UWVBFX1VOU1BFQ0lGSUVEXS4KChEKCQQEAwADAQIABRIE0wEGCwoRCgkEBAMAAwECAAES
BNMBDB0KEQoJBAQDAAMBAgADEgTTASAhCokBCggEBAMAAwECARIE1wEGHRp3IFRoZSBudW1i
ZXIgb2YgbWF0Y2hlcyB3aXRoIHR5cGUKIFtNYXRjaC5NYXRjaFR5cGUuSU5URU5UXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLk1hdGNoLk1hdGNoVHlwZS5JTlRFTlRd
LgoKEQoJBAQDAAMBAgEFEgTXAQYLChEKCQQEAwADAQIBARIE1wEMGAoRCgkEBAMAAwECAQMS
BNcBGxwKmAEKCAQEAwADAQICEgTbAQYkGoUBIFRoZSBudW1iZXIgb2YgbWF0Y2hlcyB3aXRo
IHR5cGUKIFtNYXRjaC5NYXRjaFR5cGUuRElSRUNUX0lOVEVOVF1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5NYXRjaC5NYXRjaFR5cGUuRElSRUNUX0lOVEVOVF0uCgoR
CgkEBAMAAwECAgUSBNsBBgsKEQoJBAQDAAMBAgIBEgTbAQwfChEKCQQEAwADAQICAxIE2wEi
IwqgAQoIBAQDAAMBAgMSBN8BBigajQEgVGhlIG51bWJlciBvZiBtYXRjaGVzIHdpdGggdHlw
ZQogW01hdGNoLk1hdGNoVHlwZS5QQVJBTUVURVJfRklMTElOR11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5NYXRjaC5NYXRjaFR5cGUuUEFSQU1FVEVSX0ZJTExJTkdd
LgoKEQoJBAQDAAMBAgMFEgTfAQYLChEKCQQEAwADAQIDARIE3wEMIwoRCgkEBAMAAwECAwMS
BN8BJicKjQEKCAQEAwADAQIEEgTjAQYfGnsgVGhlIG51bWJlciBvZiBtYXRjaGVzIHdpdGgg
dHlwZQogW01hdGNoLk1hdGNoVHlwZS5OT19NQVRDSF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjNiZXRhMS5NYXRjaC5NYXRjaFR5cGUuTk9fTUFUQ0hdLgoKEQoJBAQDAAMBAgQF
EgTjAQYLChEKCQQEAwADAQIEARIE4wEMGgoRCgkEBAMAAwECBAMSBOMBHR4KjQEKCAQEAwAD
AQIFEgTnAQYfGnsgVGhlIG51bWJlciBvZiBtYXRjaGVzIHdpdGggdHlwZQogW01hdGNoLk1h
dGNoVHlwZS5OT19JTlBVVF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5N
YXRjaC5NYXRjaFR5cGUuTk9fSU5QVVRdLgoKEQoJBAQDAAMBAgUFEgTnAQYLChEKCQQEAwAD
AQIFARIE5wEMGgoRCgkEBAMAAwECBQMSBOcBHR4KhwEKCAQEAwADAQIGEgTrAQYcGnUgVGhl
IG51bWJlciBvZiBtYXRjaGVzIHdpdGggdHlwZQogW01hdGNoLk1hdGNoVHlwZS5FVkVOVF1b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5NYXRjaC5NYXRjaFR5cGUuRVZF
TlRdLgoKEQoJBAQDAAMBAgYFEgTrAQYLChEKCQQEAwADAQIGARIE6wEMFwoRCgkEBAMAAwEC
BgMSBOsBGhsKQQoGBAQDAAIAEgTvAQQgGjEgVGhlIG51bWJlciBvZiBpbnRlcmFjdGlvbnMg
aW4gdGhlIGNvbnZlcnNhdGlvbi4KCg8KBwQEAwACAAUSBO8BBAkKDwoHBAQDAAIAARIE7wEK
GwoPCgcEBAMAAgADEgTvAR4fCkgKBgQEAwACARIE8gEENho4IER1cmF0aW9uIG9mIGFsbCB0
aGUgaW5wdXQncyBhdWRpbyBpbiB0aGUgY29udmVyc2F0aW9uLgoKDwoHBAQDAAIBBhIE8gEE
HAoPCgcEBAMAAgEBEgTyAR0xCg8KBwQEAwACAQMSBPIBNDUKSQoGBAQDAAICEgT1AQQ3Gjkg
RHVyYXRpb24gb2YgYWxsIHRoZSBvdXRwdXQncyBhdWRpbyBpbiB0aGUgY29udmVyc2F0aW9u
LgoKDwoHBAQDAAICBhIE9QEEHAoPCgcEBAMAAgIBEgT1AR0yCg8KBwQEAwACAgMSBPUBNTYK
ewoGBAQDAAIDEgT6AQQ1GmsgTWF4aW11bSBsYXRlbmN5IG9mIHRoZQogW1dlYmhvb2tdW2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuV2ViaG9va10gY2FsbHMgaW4gdGhl
CiBjb252ZXJzYXRpb24uCgoPCgcEBAMAAgMGEgT6AQQcCg8KBwQEAwACAwESBPoBHTAKDwoH
BAQDAAIDAxIE+gEzNAr+AQoGBAQDAAIEEgSBAgQhGu0BIEEgc2lnbmFsIHRoYXQgaW5kaWNh
dGVzIHRoZSBpbnRlcmFjdGlvbiB3aXRoIHRoZSBEaWFsb2dmbG93IGFnZW50IGhhcwogZW5k
ZWQuCiBJZiBhbnkgcmVzcG9uc2UgaGFzIHRoZQogW1Jlc3BvbnNlTWVzc2FnZS5lbmRfaW50
ZXJhY3Rpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuUmVzcG9uc2VN
ZXNzYWdlLmVuZF9pbnRlcmFjdGlvbl0KIHNpZ25hbCwgdGhpcyBpcyBzZXQgdG8gdHJ1ZS4K
Cg8KBwQEAwACBAUSBIECBAgKDwoHBAQDAAIEARIEgQIJHAoPCgcEBAMAAgQDEgSBAh8gCt4B
CgYEBAMAAgUSBIcCBCQazQEgSGFuZHMgb2ZmIGNvbnZlcnNhdGlvbiB0byBhIGh1bWFuIGFn
ZW50LgogSWYgYW55IHJlc3BvbnNlIGhhcyB0aGUKIFtSZXNwb25zZU1lc3NhZ2UubGl2ZV9h
Z2VudF9oYW5kb2ZmXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlJlc3Bv
bnNlTWVzc2FnZS5saXZlX2FnZW50X2hhbmRvZmZdc2lnbmFsLAogdGhpcyBpcyBzZXQgdG8g
dHJ1ZS4KCg8KBwQEAwACBQUSBIcCBAgKDwoHBAQDAAIFARIEhwIJHwoPCgcEBAMAAgUDEgSH
AiIjCscBCgYEBAMAAgYSBIwCBCcatgEgVGhlIGF2ZXJhZ2UgY29uZmlkZW5jZSBhbGwgb2Yg
dGhlCiBbTWF0Y2hdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuTWF0Y2hd
IGluIHRoZSBjb252ZXJzYXRpb24uCiBWYWx1ZXMgcmFuZ2UgZnJvbSAwLjAgKGNvbXBsZXRl
bHkgdW5jZXJ0YWluKSB0byAxLjAgKGNvbXBsZXRlbHkgY2VydGFpbikuCgoPCgcEBAMAAgYF
EgSMAgQJCg8KBwQEAwACBgESBIwCCiIKDwoHBAQDAAIGAxIEjAIlJgolCgYEBAMAAgcSBI8C
BCoaFSBRdWVyeSBpbnB1dCBjb3VudHMuCgoPCgcEBAMAAgcGEgSPAgQTCg8KBwQEAwACBwES
BI8CFCUKDwoHBAQDAAIHAxIEjwIoKQokCgYEBAMAAggSBJICBCgaFCBNYXRjaCB0eXBlIGNv
dW50cy4KCg8KBwQEAwACCAYSBJICBBIKDwoHBAQDAAIIARIEkgITIwoPCgcEBAMAAggDEgSS
AiYnCuoBCgQEBAMBEgaYAgLQAgMa2QEgUmVwcmVzZW50cyBhbiBpbnRlcmFjdGlvbiBiZXR3
ZWVuIGFuIGVuZCB1c2VyIGFuZCBhIERpYWxvZ2Zsb3cgQ1ggYWdlbnQKIHVzaW5nIFYzIChT
dHJlYW1pbmcpRGV0ZWN0SW50ZW50IEFQSSwgb3IgYW4gaW50ZXJhY3Rpb24gYmV0d2VlbiBh
biBlbmQgdXNlcgogYW5kIGEgRGlhbG9nZmxvdyBDWCBhZ2VudCB1c2luZyBWMiAoU3RyZWFt
aW5nKUFuYWx5emVDb250ZW50IEFQSS4KCg0KBQQEAwEBEgSYAgoVCsoBCgYEBAMBAwASBpwC
BKMCBRq3ASBJbmZvcm1hdGlvbiBjb2xsZWN0ZWQgZm9yIERGIENYIGFnZW50cyBpbiBjYXNl
IE5MVSBwcmVkaWN0ZWQgYW4gaW50ZW50CiB0aGF0IHdhcyBmaWx0ZXJlZCBvdXQgYXMgYmVp
bmcgaW5hY3RpdmUgd2hpY2ggbWF5IGluZGljYXRlIGEgbWlzc2luZwogdHJhbnNpdGlvbiBh
bmQvb3IgYWJzZW50IGZ1bmN0aW9uYWxpdHkuCgoPCgcEBAMBAwABEgScAgwdCkEKCAQEAwED
AAIAEgSeAgYlGi8gTmFtZSBvZiB0aGUgaW50ZW50IHRoYXQgY291bGQgaGF2ZSB0cmlnZ2Vy
ZWQuCgoRCgkEBAMBAwACAAUSBJ4CBgwKEQoJBAQDAQMAAgABEgSeAg0gChEKCQQEAwEDAAIA
AxIEngIjJAp5CggEBAMBAwACARIEogIGFhpnIFNjb3JlIG9mIHRoZSBhYm92ZSBpbnRlbnQu
IFRoZSBoaWdoZXIgaXQgaXMgdGhlIG1vcmUgbGlrZWx5IGEKIHRyYW5zaXRpb24gd2FzIG1p
c3NlZCBvbiBhIGdpdmVuIHBhZ2UuCgoRCgkEBAMBAwACAQUSBKICBgsKEQoJBAQDAQMAAgEB
EgSiAgwRChEKCQQEAwEDAAIBAxIEogIUFQo0CgYEBAMBAwESBqYCBKwCBRoiIE1ldHJpY3Mg
b2YgZWFjaCBwcm9jZXNzaW5nIHN0ZXAuCgoPCgcEBAMBAwEBEgSmAgwXCjgKCAQEAwEDAQIA
EgSoAgYWGiYgTmFtZSBvZiB0aGUgcmVxdWVzdCBwcm9jZXNzaW5nIHN0ZXAuCgoRCgkEBAMB
AwECAAUSBKgCBgwKEQoJBAQDAQMBAgABEgSoAg0RChEKCQQEAwEDAQIAAxIEqAIUFQozCggE
BAMBAwECARIEqwIGKxohIFByb2Nlc3NpbmcgbGF0ZW5jeSBvZiB0aGUgc3RlcC4KChEKCQQE
AwEDAQIBBhIEqwIGHgoRCgkEBAMBAwECAQESBKsCHyYKEQoJBAQDAQMBAgEDEgSrAikqCjEK
BgQEAwECABIErwIEJBohIFRoZSByZXF1ZXN0IG9mIHRoZSBpbnRlcmFjdGlvbi4KCg8KBwQE
AwECAAYSBK8CBBcKDwoHBAQDAQIAARIErwIYHwoPCgcEBAMBAgADEgSvAiIjCjgKBgQEAwEC
ARIEsgIEJhooIFRoZSBmaW5hbCByZXNwb25zZSBvZiB0aGUgaW50ZXJhY3Rpb24uCgoPCgcE
BAMBAgEGEgSyAgQYCg8KBwQEAwECAQESBLICGSEKDwoHBAQDAQIBAxIEsgIkJQrrAQoGBAQD
AQICEgS5AgQ4GtoBIFRoZSBwYXJ0aWFsIHJlc3BvbnNlcyBvZiB0aGUgaW50ZXJhY3Rpb24u
IEVtcHR5IGlmIHRoZXJlIGlzIG5vIHBhcnRpYWwKIHJlc3BvbnNlIGluIHRoZSBpbnRlcmFj
dGlvbi4KIFNlZSB0aGUKIFtwYXJ0aWFsIHJlc3BvbnNlCiBkb2N1bWVudGF0aW9uXVtodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvZnVsZmls
bG1lbnQjcXVldWVdLgoKDwoHBAQDAQICBBIEuQIEDAoPCgcEBAMBAgIGEgS5Ag0hCg8KBwQE
AwECAgESBLkCIjMKDwoHBAQDAQICAxIEuQI2NwpVCgYEBAMBAgMSBLwCBCIaRSBUaGUgaW5w
dXQgdGV4dCBvciB0aGUgdHJhbnNjcmlwdCBvZiB0aGUgaW5wdXQgYXVkaW8gaW4gdGhlIHJl
cXVlc3QuCgoPCgcEBAMBAgMFEgS8AgQKCg8KBwQEAwECAwESBLwCCx0KDwoHBAQDAQIDAxIE
vAIgIQqqAQoGBAQDAQIEEgTBAgQjGpkBIFRoZSBvdXRwdXQgdGV4dCBvciB0aGUgdHJhbnNj
cmlwdCBvZiB0aGUgb3V0cHV0IGF1ZGlvIGluIHRoZSByZXNwb25zZXMuCiBJZiBtdWx0aXBs
ZSBvdXRwdXQgbWVzc2FnZXMgYXJlIHJldHVybmVkLCB0aGV5IHdpbGwgYmUgY29uY2F0ZW5h
dGVkIGludG8KIG9uZS4KCg8KBwQEAwECBAUSBMECBAoKDwoHBAQDAQIEARIEwQILHgoPCgcE
BAMBAgQDEgTBAiEiCjwKBgQEAwECBRIExAIELhosIFRoZSB0aW1lIHRoYXQgdGhlIGludGVy
YWN0aW9uIHdhcyBjcmVhdGVkLgoKDwoHBAQDAQIFBhIExAIEHQoPCgcEBAMBAgUBEgTEAh4p
Cg8KBwQEAwECBQMSBMQCLC0KOQoGBAQDAQIGEgTHAgQnGikgQW5zd2VyIGZlZWRiYWNrIGZv
ciB0aGUgZmluYWwgcmVzcG9uc2UuCgoPCgcEBAMBAgYGEgTHAgQSCg8KBwQEAwECBgESBMcC
EyIKDwoHBAQDAQIGAxIExwIlJgqHAQoGBAQDAQIHEgTLAgQtGncgTWlzc2luZyB0cmFuc2l0
aW9uIHByZWRpY3RlZCBmb3IgdGhlIGludGVyYWN0aW9uLiBUaGlzIGZpZWxkIGlzIHNldCBv
bmx5CiBpZiB0aGUgaW50ZXJhY3Rpb24gbWF0Y2ggdHlwZSB3YXMgbm8tbWF0Y2guCgoPCgcE
BAMBAgcGEgTLAgQVCg8KBwQEAwECBwESBMsCFigKDwoHBAQDAQIHAxIEywIrLAqYAQoGBAQD
AQIIEgTPAgQqGocBIE1ldHJpY3MgYXNzb2NpYXRlZCB3aXRoIGRpZmZlcmVudCBwcm9jZXNz
aW5nIHN0ZXBzLiBOYW1lcyBhbmQgbnVtYmVyIG9mCiBzdGVwcyBkZXBlbmQgb24gdGhlIHJl
cXVlc3QgYW5kIGNhbiBjaGFuZ2Ugd2l0aG91dCBhIG5vdGljZS4KCg8KBwQEAwECCAQSBM8C
BAwKDwoHBAQDAQIIBhIEzwINGAoPCgcEBAMBAggBEgTPAhklCg8KBwQEAwECCAMSBM8CKCkK
pAIKBAQEAgASBNYCAj0alQIgSWRlbnRpZmllci4gVGhlIGlkZW50aWZpZXIgb2YgdGhlIGNv
bnZlcnNhdGlvbi4KIElmIGNvbnZlcnNhdGlvbiBJRCBpcyByZXVzZWQsIGludGVyYWN0aW9u
cyBoYXBwZW5lZCBsYXRlciB0aGFuIDQ4IGhvdXJzIG9mCiB0aGUgY29udmVyc2F0aW9uJ3Mg
Y3JlYXRlIHRpbWUgd2lsbCBiZSBpZ25vcmVkLiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2pl
Y3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2NvbnZlcnNh
dGlvbnMvPENvbnZlcnNhdGlvbklEPmAKCg0KBQQEAgAFEgTWAgIICg0KBQQEAgABEgTWAgkN
Cg0KBQQEAgADEgTWAhARCg0KBQQEAgAIEgTWAhI8ChAKCAQEAgAInAgAEgTWAhM7Ci0KBAQE
AgESBNkCAhAaHyBUaGUgdHlwZSBvZiB0aGUgY29udmVyc2F0aW9uLgoKDQoFBAQCAQYSBNkC
AgYKDQoFBAQCAQESBNkCBwsKDQoFBAQCAQMSBNkCDg8KcgoEBAQCAhIE3QICGxpkIFRoZSBs
YW5ndWFnZSBvZiB0aGUgY29udmVyc2F0aW9uLCB3aGljaCBpcyB0aGUgbGFuZ3VhZ2Ugb2Yg
dGhlIGZpcnN0CiByZXF1ZXN0IGluIHRoZSBjb252ZXJzYXRpb24uCgoNCgUEBAICBRIE3QIC
CAoNCgUEBAICARIE3QIJFgoNCgUEBAICAxIE3QIZGgpsCgQEBAIDEgThAgIrGl4gU3RhcnQg
dGltZSBvZiB0aGUgY29udmVyc2F0aW9uLCB3aGljaCBpcyB0aGUgdGltZSBvZiB0aGUgZmly
c3QgcmVxdWVzdCBvZgogdGhlIGNvbnZlcnNhdGlvbi4KCg0KBQQEAgMGEgThAgIbCg0KBQQE
AgMBEgThAhwmCg0KBQQEAgMDEgThAikqCi0KBAQEAgQSBOQCAigaHyBEdXJhdGlvbiBvZiB0
aGUgY29udmVyc2F0aW9uLgoKDQoFBAQCBAYSBOQCAhoKDQoFBAQCBAESBOQCGyMKDQoFBAQC
BAMSBOQCJicKJQoEBAQCBRIE5wICFhoXIENvbnZlcnNhdGlvbiBtZXRyaWNzLgoKDQoFBAQC
BQYSBOcCAgkKDQoFBAQCBQESBOcCChEKDQoFBAQCBQMSBOcCFBUKpQEKBAQEAgYSBOsCAh4a
lgEgQWxsIHRoZSBtYXRjaGVkIFtJbnRlbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuSW50ZW50XSBpbiB0aGUKIGNvbnZlcnNhdGlvbi4gT25seSBgbmFtZWAgYW5k
IGBkaXNwbGF5X25hbWVgIGFyZSBmaWxsZWQgaW4gdGhpcyBtZXNzYWdlLgoKDQoFBAQCBgQS
BOsCAgoKDQoFBAQCBgYSBOsCCxEKDQoFBAQCBgESBOsCEhkKDQoFBAQCBgMSBOsCHB0KqAEK
BAQEAgcSBPACAhoamQEgQWxsIHRoZSBbRmxvd11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5GbG93XSB0aGUgY29udmVyc2F0aW9uCiBoYXMgd2VudCB0aHJvdWdoLiBP
bmx5IGBuYW1lYCBhbmQgYGRpc3BsYXlfbmFtZWAgYXJlIGZpbGxlZCBpbiB0aGlzCiBtZXNz
YWdlLgoKDQoFBAQCBwQSBPACAgoKDQoFBAQCBwYSBPACCw8KDQoFBAQCBwESBPACEBUKDQoF
BAQCBwMSBPACGBkKqAEKBAQEAggSBPUCAhoamQEgQWxsIHRoZSBbUGFnZV1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5QYWdlXSB0aGUgY29udmVyc2F0aW9uCiBoYXMg
d2VudCB0aHJvdWdoLiBPbmx5IGBuYW1lYCBhbmQgYGRpc3BsYXlfbmFtZWAgYXJlIGZpbGxl
ZCBpbiB0aGlzCiBtZXNzYWdlLgoKDQoFBAQCCAQSBPUCAgoKDQoFBAQCCAYSBPUCCw8KDQoF
BAQCCAESBPUCEBUKDQoFBAQCCAMSBPUCGBkKegoEBAQCCRIE+QICKRpsIEludGVyYWN0aW9u
cyBvZiB0aGUgY29udmVyc2F0aW9uLgogT25seSBwb3B1bGF0ZWQgZm9yIGBHZXRDb252ZXJz
YXRpb25gIGFuZCBlbXB0eSBmb3IgYExpc3RDb252ZXJzYXRpb25zYC4KCg0KBQQEAgkEEgT5
AgIKCg0KBQQEAgkGEgT5AgsWCg0KBQQEAgkBEgT5AhcjCg0KBQQEAgkDEgT5AiYoCmwKBAQE
AgoSBP0CAh8aXiBFbnZpcm9ubWVudCBvZiB0aGUgY29udmVyc2F0aW9uLgogT25seSBgbmFt
ZWAgYW5kIGBkaXNwbGF5X25hbWVgIGFyZSBmaWxsZWQgaW4gdGhpcyBtZXNzYWdlLgoKDQoF
BAQCCgYSBP0CAg0KDQoFBAQCCgESBP0CDhkKDQoFBAQCCgMSBP0CHB4KNwoEBAQCCxIEgAMC
KBopIEZsb3cgdmVyc2lvbnMgdXNlZCBpbiB0aGUgY29udmVyc2F0aW9uLgoKDQoFBAQCCwYS
BIADAhQKDQoFBAQCCwESBIADFSIKDQoFBAQCCwMSBIADJSdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest ===
    # Fields for GetConversationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::DeleteConversationRequest ===
    # Fields for DeleteConversationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest ===
    # Fields for ListConversationsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse ===
    # Fields for ListConversationsResponse
    # Field: conversations Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Conversation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.dialogflow.cx.v3beta1.Conversation.Type)
    # Field: language_code Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: metrics Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Conversation.Metrics)
    # Field: intents Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Intent)
    # Field: flows Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Flow)
    # Field: pages Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Page)
    # Field: interactions Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Conversation.Interaction)
    # Field: environment Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Environment)
    # Field: flow_versions Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Conversation.FlowVersionsEntry)

# Enum: Conversation::Type
our $Conversation_TYPE_UNSPECIFIED = 0;
our $Conversation_AUDIO = 1;
our $Conversation_TEXT = 2;
our $Conversation_UNDETERMINED = 3;

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ConversationHistoryClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ConversationHistoryClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ConversationHistoryClient

Client stub representing the remote C<ConversationHistory> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_conversations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.ConversationHistory',
        method         => 'ListConversations',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse',
    });
}

sub get_conversation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.ConversationHistory',
        method         => 'GetConversation',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation',
    });
}

sub delete_conversation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::DeleteConversationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.ConversationHistory',
        method         => 'DeleteConversation',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/conversation_history.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/conversation_history.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest

The request message for [Conversations.GetConversation][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the conversation.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/conversations/<ConversationID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::DeleteConversationRequest

The request message for [Conversations.DeleteConversation][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the conversation.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/conversations/<ConversationID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest

The request message for [Conversations.ListConversations][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all conversations for.
Format: `projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter string. Supports filter by create_time,
metrics.has_end_interaction, metrics.has_live_agent_handoff,
intents.display_name, pages.display_name and flows.display_name. Timestamps
expect an [RFC-3339][https://datatracker.ietf.org/doc/html/rfc3339]
formatted string (e.g. 2012-04-21T11:30:00-04:00). UTC offsets are
supported. Some examples:
  1. By create time:
       create_time > "2022-04-21T11:30:00-04:00"
  2. By intent display name:
       intents.display_name : "billing"
  3. By end interaction signal:
       metrics.has_end_interaction = true

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse

The response message for [Conversations.ListConversations][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversations() >> / C<< $msg->conversations($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation>)

The list of conversations. There will be a maximum number of items returned
based on the
[page_size][google.cloud.dialogflow.cx.v3beta1.ListConversationsRequest.page_size]
field. The returned conversations will be sorted by start_time in
descending order (newest conversation first).

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation

Represents a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The identifier of the conversation.
If conversation ID is reused, interactions happened later than 48 hours of
the conversation's create time will be ignored. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/conversations/<ConversationID>`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Conversation::Type>)

The type of the conversation.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language of the conversation, which is the language of the first
request in the conversation.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start time of the conversation, which is the time of the first request of
the conversation.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration of the conversation.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics>)

Conversation metrics.

=item * C<< $msg->intents() >> / C<< $msg->intents($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Intent::Intent>)

All the matched [Intent][google.cloud.dialogflow.cx.v3beta1.Intent] in the
conversation. Only `name` and `display_name` are filled in this message.

=item * C<< $msg->flows() >> / C<< $msg->flows($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow>)

All the [Flow][google.cloud.dialogflow.cx.v3beta1.Flow] the conversation
has went through. Only `name` and `display_name` are filled in this
message.

=item * C<< $msg->pages() >> / C<< $msg->pages($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Page::Page>)

All the [Page][google.cloud.dialogflow.cx.v3beta1.Page] the conversation
has went through. Only `name` and `display_name` are filled in this
message.

=item * C<< $msg->interactions() >> / C<< $msg->interactions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction>)

Interactions of the conversation.
Only populated for `GetConversation` and empty for `ListConversations`.

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment>)

Environment of the conversation.
Only `name` and `display_name` are filled in this message.

=item * C<< $msg->flow_versions() >> / C<< $msg->flow_versions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::FlowVersionsEntry>)

Flow versions used in the conversation.

=back

=head3 Enum: Conversation::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<AUDIO> => C<1>

=item * C<TEXT> => C<2>

=item * C<UNDETERMINED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
