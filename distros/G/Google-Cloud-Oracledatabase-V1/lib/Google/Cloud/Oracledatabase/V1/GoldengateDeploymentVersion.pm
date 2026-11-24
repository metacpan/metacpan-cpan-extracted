package Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion;

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
CkJnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZ29sZGVuZ2F0ZV9kZXBsb3ltZW50
X3ZlcnNpb24ucHJvdG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKeAwobR29sZGVuZ2F0ZURlcGxveW1l
bnRWZXJzaW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIXCgRvY2lkGAIgASgJQgPgQQNS
BG9jaWQSagoKcHJvcGVydGllcxgDIAEoCzJFLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFz
ZS52MS5Hb2xkZW5nYXRlRGVwbG95bWVudFZlcnNpb25Qcm9wZXJ0aWVzQgPgQQNSCnByb3Bl
cnRpZXM64AHqQdwBCjlvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9Hb2xkZW5nYXRl
RGVwbG95bWVudFZlcnNpb24SZHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9nb2xkZW5nYXRlRGVwbG95bWVudFZlcnNpb25zL3tnb2xkZW5nYXRlX2RlcGxveW1l
bnRfdmVyc2lvbn0qHGdvbGRlbmdhdGVEZXBsb3ltZW50VmVyc2lvbnMyG2dvbGRlbmdhdGVE
ZXBsb3ltZW50VmVyc2lvbiLoBgolR29sZGVuZ2F0ZURlcGxveW1lbnRWZXJzaW9uUHJvcGVy
dGllcxKCAQoPZGVwbG95bWVudF90eXBlGAEgASgOMlQuZ29vZ2xlLmNsb3VkLm9yYWNsZWRh
dGFiYXNlLnYxLkdvbGRlbmdhdGVEZXBsb3ltZW50VmVyc2lvblByb3BlcnRpZXMuRGVwbG95
bWVudFR5cGVCA+BBA1IOZGVwbG95bWVudFR5cGUSJgoMc2VjdXJpdHlfZml4GAIgASgIQgPg
QQFSC3NlY3VyaXR5Rml4EiQKC29nZ192ZXJzaW9uGAMgASgJQgPgQQNSCm9nZ1ZlcnNpb24S
gwEKDHJlbGVhc2VfdHlwZRgEIAEoDjJbLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52
MS5Hb2xkZW5nYXRlRGVwbG95bWVudFZlcnNpb25Qcm9wZXJ0aWVzLkRlcGxveW1lbnRSZWxl
YXNlVHlwZUID4EEDUgtyZWxlYXNlVHlwZRJCCgxyZWxlYXNlX3RpbWUYBSABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSC3JlbGVhc2VUaW1lEkkKEHN1cHBvcnRfZW5k
X3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDnN1cHBvcnRF
bmRUaW1lIvIBCg5EZXBsb3ltZW50VHlwZRIfChtERVBMT1lNRU5UX1RZUEVfVU5TUEVDSUZJ
RUQQABIHCgNPR0cQARITCg9EQVRBQkFTRV9PUkFDTEUQAhILCgdCSUdEQVRBEAMSIAocREFU
QUJBU0VfTUlDUk9TT0ZUX1NRTFNFUlZFUhAEEhIKDkRBVEFCQVNFX01ZU1FMEAUSFwoTREFU
QUJBU0VfUE9TVEdSRVNRTBAGEhMKD0RBVEFCQVNFX0RCMlpPUxAHEhEKDURBVEFCQVNFX0RC
MkkQCBIICgRHR1NBEAkSEwoPREFUQV9UUkFOU0ZPUk1TEAoiYgoVRGVwbG95bWVudFJlbGVh
c2VUeXBlEicKI0RFUExPWU1FTlRfUkVMRUFTRV9UWVBFX1VOU1BFQ0lGSUVEEAASCQoFTUFK
T1IQARIKCgZCVU5ETEUQAhIJCgVNSU5PUhADIucBCidMaXN0R29sZGVuZ2F0ZURlcGxveW1l
bnRWZXJzaW9uc1JlcXVlc3QSWQoGcGFyZW50GAEgASgJQkHgQQL6QTsSOW9yYWNsZWRhdGFi
YXNlLmdvb2dsZWFwaXMuY29tL0dvbGRlbmdhdGVEZXBsb3ltZW50VmVyc2lvblIGcGFyZW50
EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJ
QgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIv0BCihMaXN0
R29sZGVuZ2F0ZURlcGxveW1lbnRWZXJzaW9uc1Jlc3BvbnNlEoEBCh5nb2xkZW5nYXRlX2Rl
cGxveW1lbnRfdmVyc2lvbnMYASADKAsyOy5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2Uu
djEuR29sZGVuZ2F0ZURlcGxveW1lbnRWZXJzaW9uUhxnb2xkZW5nYXRlRGVwbG95bWVudFZl
cnNpb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIlCgt1bnJl
YWNoYWJsZRgDIAMoCUID4EEGUgt1bnJlYWNoYWJsZUL6AQoiY29tLmdvb2dsZS5jbG91ZC5v
cmFjbGVkYXRhYmFzZS52MUIgR29sZGVuZ2F0ZURlcGxveW1lbnRWZXJzaW9uUHJvdG9QAVpK
Y2xvdWQuZ29vZ2xlLmNvbS9nby9vcmFjbGVkYXRhYmFzZS9hcGl2MS9vcmFjbGVkYXRhYmFz
ZXBiO29yYWNsZWRhdGFiYXNlcGKqAh5Hb29nbGUuQ2xvdWQuT3JhY2xlRGF0YWJhc2UuVjHK
Ah5Hb29nbGVcQ2xvdWRcT3JhY2xlRGF0YWJhc2VcVjHqAiFHb29nbGU6OkNsb3VkOjpPcmFj
bGVEYXRhYmFzZTo6VjFKzi4KBxIFDgCsAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
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
Y2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoB
CBIDFgA7CgkKAgglEgMWADsKCAoBCBIDFwBhCgkKAggLEgMXAGEKCAoBCBIDGAAiCgkKAggK
EgMYACIKCAoBCBIDGQBBCgkKAggIEgMZAEEKCAoBCBIDGgA7CgkKAggBEgMaADsKCAoBCBID
GwA7CgkKAggpEgMbADsKCAoBCBIDHAA6CgkKAggtEgMcADoKRAoCBAASBB8ANAEaOCBEZXRh
aWxzIG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVmVyc2lvbiByZXNvdXJjZS4KCgoK
AwQAARIDHwgjCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBArKAQoEBAACABIDKgI9GrwB
IElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVmVy
c2lvbiByZXNvdXJjZSB3aXRoIHRoZQogZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2dvbGRlbmdhdGVEZXBsb3ltZW50VmVyc2lvbnMve2dvbGRl
bmdhdGVfZGVwbG95bWVudF92ZXJzaW9ufQoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkN
CgwKBQQAAgADEgMqEBEKDAoFBAACAAgSAyoSPAoPCggEAAIACJwIABIDKhM7CmcKBAQAAgES
Ay4CPhpaIE91dHB1dCBvbmx5LiBUaGUgZGVwbG95bWVudCB2ZXJzaW9uIG9jaWQgb2YgdGhl
IEdvbGRlbmdhdGUgRGVwbG95bWVudAogVmVyc2lvbiByZXNvdXJjZS4KCgwKBQQAAgEFEgMu
AggKDAoFBAACAQESAy4JDQoMCgUEAAIBAxIDLhARCgwKBQQAAgEIEgMuEj0KDwoIBAACAQic
CAASAy4TPApgCgQEAAICEgQyAjMyGlIgT3V0cHV0IG9ubHkuIFRoZSB0ZWNobm9sb2d5IHR5
cGUgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBWZXJzaW9uCiByZXNvdXJjZS4KCgwK
BQQAAgIGEgMyAicKDAoFBAACAgESAzIoMgoMCgUEAAICAxIDMjU2CgwKBQQAAgIIEgMzBjEK
DwoIBAACAgicCAASAzMHMAo5CgIEARIFNwCFAQEaLCBQcm9wZXJ0aWVzIG9mIEdvbGRlbmdh
dGVEZXBsb3ltZW50VmVyc2lvbi4KCgoKAwQBARIDNwgtClIKBAQBBAASBDkCWgMaRCBUaGUg
ZGVwbG95bWVudCB0eXBlIG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVmVyc2lvbiBy
ZXNvdXJjZS4KCgwKBQQBBAABEgM5BxUKKwoGBAEEAAIAEgM7BCQaHCBEZWZhdWx0IHVuc3Bl
Y2lmaWVkIHZhbHVlLgoKDgoHBAEEAAIAARIDOwQfCg4KBwQBBAACAAISAzsiIwo8CgYEAQQA
AgESAz4EDBotIEdvbGRlbmdhdGUgRGVwbG95bWVudCBUeXBlIGNhdGVnb3J5IGlzIE9HRy4K
Cg4KBwQBBAACAQESAz4EBwoOCgcEAQQAAgECEgM+CgsKSAoGBAEEAAICEgNBBBgaOSBHb2xk
ZW5nYXRlIERlcGxveW1lbnQgVHlwZSBjYXRlZ29yeSBpcyBEQVRBQkFTRV9PUkFDTEUuCgoO
CgcEAQQAAgIBEgNBBBMKDgoHBAEEAAICAhIDQRYXCkAKBgQBBAACAxIDRAQQGjEgR29sZGVu
Z2F0ZSBEZXBsb3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgQklHREFUQS4KCg4KBwQBBAACAwES
A0QECwoOCgcEAQQAAgMCEgNEDg8KVQoGBAEEAAIEEgNHBCUaRiBHb2xkZW5nYXRlIERlcGxv
eW1lbnQgVHlwZSBjYXRlZ29yeSBpcyBEQVRBQkFTRV9NSUNST1NPRlRfU1FMU0VSVkVSLgoK
DgoHBAEEAAIEARIDRwQgCg4KBwQBBAACBAISA0cjJApHCgYEAQQAAgUSA0oEFxo4IEdvbGRl
bmdhdGUgRGVwbG95bWVudCBUeXBlIGNhdGVnb3J5IGlzIERBVEFCQVNFX01ZU1FMLgoKDgoH
BAEEAAIFARIDSgQSCg4KBwQBBAACBQISA0oVFgpMCgYEAQQAAgYSA00EHBo9IEdvbGRlbmdh
dGUgRGVwbG95bWVudCBUeXBlIGNhdGVnb3J5IGlzIERBVEFCQVNFX1BPU1RHUkVTUUwuCgoO
CgcEAQQAAgYBEgNNBBcKDgoHBAEEAAIGAhIDTRobCkgKBgQBBAACBxIDUAQYGjkgR29sZGVu
Z2F0ZSBEZXBsb3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgREFUQUJBU0VfREIyWk9TLgoKDgoH
BAEEAAIHARIDUAQTCg4KBwQBBAACBwISA1AWFwpGCgYEAQQAAggSA1MEFho3IEdvbGRlbmdh
dGUgRGVwbG95bWVudCBUeXBlIGNhdGVnb3J5IGlzIERBVEFCQVNFX0RCMkkuCgoOCgcEAQQA
AggBEgNTBBEKDgoHBAEEAAIIAhIDUxQVCj0KBgQBBAACCRIDVgQNGi4gR29sZGVuZ2F0ZSBE
ZXBsb3ltZW50IFR5cGUgY2F0ZWdvcnkgaXMgR0dTQS4KCg4KBwQBBAACCQESA1YECAoOCgcE
AQQAAgkCEgNWCwwKSAoGBAEEAAIKEgNZBBkaOSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVHlw
ZSBjYXRlZ29yeSBpcyBEQVRBX1RSQU5TRk9STVMuCgoOCgcEAQQAAgoBEgNZBBMKDgoHBAEE
AAIKAhIDWRYYCk8KBAQBBAESBF0CaQMaQSBUaGUgcmVsZWFzZSB0eXBlIG9mIHRoZSBHb2xk
ZW5nYXRlIERlcGxveW1lbnQgVmVyc2lvbiByZXNvdXJjZS4KCgwKBQQBBAEBEgNdBxwKKwoG
BAEEAQIAEgNfBCwaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAEEAQIAARID
XwQnCg4KBwQBBAECAAISA18qKwpFCgYEAQQBAgESA2IEDho2IEdvbGRlbmdhdGUgRGVwbG95
bWVudCBWZXJzaW9uIHJlbGVhc2UgdHlwZSBpcyBNQUpPUi4KCg4KBwQBBAECAQESA2IECQoO
CgcEAQQBAgECEgNiDA0KRgoGBAEEAQICEgNlBA8aNyBHb2xkZW5nYXRlIERlcGxveW1lbnQg
VmVyc2lvbiByZWxlYXNlIHR5cGUgaXMgQlVORExFLgoKDgoHBAEEAQICARIDZQQKCg4KBwQB
BAECAgISA2UNDgpFCgYEAQQBAgMSA2gEDho2IEdvbGRlbmdhdGUgRGVwbG95bWVudCBWZXJz
aW9uIHJlbGVhc2UgdHlwZSBpcyBNSU5PUi4KCg4KBwQBBAECAwESA2gECQoOCgcEAQQBAgMC
EgNoDA0KYAoEBAECABIEbQJuMhpSIE91dHB1dCBvbmx5LiBUaGUgZGVwbG95bWVudCB0eXBl
IG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVmVyc2lvbgogcmVzb3VyY2UuCgoMCgUE
AQIABhIDbQIQCgwKBQQBAgABEgNtESAKDAoFBAECAAMSA20jJAoMCgUEAQIACBIDbgYxCg8K
CAQBAgAInAgAEgNuBzAKXwoEBAECARIDcgJBGlIgT3B0aW9uYWwuIFdoZXRoZXIgdGhlIEdv
bGRlbmdhdGUgRGVwbG95bWVudCBWZXJzaW9uIHJlc291cmNlIGlzIGEgc2VjdXJpdHkKIGZp
eC4KCgwKBQQBAgEFEgNyAgYKDAoFBAECAQESA3IHEwoMCgUEAQIBAxIDchYXCgwKBQQBAgEI
EgNyGEAKDwoIBAECAQicCAASA3IZPwpaCgQEAQICEgN1AkUaTSBPdXRwdXQgb25seS4gVGhl
IE9HRyB2ZXJzaW9uIG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgVmVyc2lvbiByZXNv
dXJjZS4KCgwKBQQBAgIFEgN1AggKDAoFBAECAgESA3UJFAoMCgUEAQICAxIDdRcYCgwKBQQB
AgIIEgN1GUQKDwoIBAECAgicCAASA3UaQwpdCgQEAQIDEgR5AnoyGk8gT3V0cHV0IG9ubHku
IFRoZSByZWxlYXNlIHR5cGUgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBWZXJzaW9u
CiByZXNvdXJjZS4KCgwKBQQBAgMGEgN5AhcKDAoFBAECAwESA3kYJAoMCgUEAQIDAxIDeSco
CgwKBQQBAgMIEgN6BjEKDwoIBAECAwicCAASA3oHMApdCgQEAQIEEgR+An8yGk8gT3V0cHV0
IG9ubHkuIFRoZSByZWxlYXNlIHRpbWUgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBW
ZXJzaW9uCiByZXNvdXJjZS4KCgwKBQQBAgQGEgN+AhsKDAoFBAECBAESA34cKAoMCgUEAQIE
AxIDfissCgwKBQQBAgQIEgN/BjEKDwoIBAECBAicCAASA38HMApjCgQEAQIFEgaDAQKEATIa
UyBPdXRwdXQgb25seS4gVGhlIHN1cHBvcnQgZW5kIHRpbWUgb2YgdGhlIEdvbGRlbmdhdGUg
RGVwbG95bWVudCBWZXJzaW9uCiByZXNvdXJjZS4KCg0KBQQBAgUGEgSDAQIbCg0KBQQBAgUB
EgSDARwsCg0KBQQBAgUDEgSDAS8wCg0KBQQBAgUIEgSEAQYxChAKCAQBAgUInAgAEgSEAQcw
CkEKAgQCEgaIAQCeAQEaMyBNZXNzYWdlIGZvciBsaXN0aW5nIEdvbGRlbmdhdGVEZXBsb3lt
ZW50VmVyc2lvbnMuCgoLCgMEAgESBIgBCC8KhQEKBAQCAgASBosBApABBBp1IFJlcXVpcmVk
LiBQYXJlbnQgdmFsdWUgZm9yIExpc3RHb2xkZW5nYXRlRGVwbG95bWVudFZlcnNpb25zUmVx
dWVzdAogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0K
Cg0KBQQCAgAFEgSLAQIICg0KBQQCAgABEgSLAQkPCg0KBQQCAgADEgSLARITCg8KBQQCAgAI
EgaLARSQAQMKEAoIBAICAAicCAASBIwBBCoKEQoHBAICAAifCBIGjQEEjwEFCt4BCgQEAgIB
EgSVAQI/Gs8BIE9wdGlvbmFsLiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJl
dHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lmaWVkLCBzZXJ2
ZXIgd2lsbCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuIFRoZQogbWF4aW11bSB2YWx1
ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4K
Cg0KBQQCAgEFEgSVAQIHCg0KBQQCAgEBEgSVAQgRCg0KBQQCAgEDEgSVARQVCg0KBQQCAgEI
EgSVARY+ChAKCAQCAgEInAgAEgSVARc9ClkKBAQCAgISBJgBAkEaSyBPcHRpb25hbC4gQSB0
b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCBy
ZXR1cm4uCgoNCgUEAgICBRIEmAECCAoNCgUEAgICARIEmAEJEwoNCgUEAgICAxIEmAEWFwoN
CgUEAgICCBIEmAEYQAoQCggEAgICCJwIABIEmAEZPwrmAQoEBAICAxIEnQECPRrXASBPcHRp
b25hbC4gQW4gZXhwcmVzc2lvbiBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSBy
ZXF1ZXN0LiBFaXRoZXIKIHRoZSBkZXBsb3ltZW50X2lkIGFuZCBkZXBsb3ltZW50X3R5cGUg
ZmllbGRzIG11c3QgYmUgc3BlY2lmaWVkIGluIHRoZQogZm9ybWF0OiBgZGVwbG95bWVudF9p
ZD0iaWQiYCBvciBgZGVwbG95bWVudF90eXBlPSJEQVRBQkFTRV9PUkFDTEUiYC4KCg0KBQQC
AgMFEgSdAQIICg0KBQQCAgMBEgSdAQkPCg0KBQQCAgMDEgSdARITCg0KBQQCAgMIEgSdARQ8
ChAKCAQCAgMInAgAEgSdARU7CkwKAgQDEgahAQCsAQEaPiBNZXNzYWdlIGZvciByZXNwb25z
ZSB0byBsaXN0aW5nIEdvbGRlbmdhdGVEZXBsb3ltZW50VmVyc2lvbnMKCgsKAwQDARIEoQEI
MAo3CgQEAwIAEgSjAQJKGikgVGhlIGxpc3Qgb2YgR29sZGVuZ2F0ZURlcGxveW1lbnRWZXJz
aW9uCgoNCgUEAwIABBIEowECCgoNCgUEAwIABhIEowELJgoNCgUEAwIAARIEowEnRQoNCgUE
AwIAAxIEowFISQqQAQoEBAMCARIEpwECHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2Vu
dCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMg
ZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUE
AwIBBRIEpwECCAoNCgUEAwIBARIEpwEJGAoNCgUEAwIBAxIEpwEbHApGCgQEAwICEgaqAQKr
ATUaNiBVbm9yZGVyZWQgbGlzdC4gTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNo
ZWQuCgoNCgUEAwICBBIEqgECCgoNCgUEAwICBRIEqgELEQoNCgUEAwICARIEqgESHQoNCgUE
AwICAxIEqgEgIQoNCgUEAwICCBIEqwEGNAoQCggEAwICCJwIABIEqwEHM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion ===
    # Fields for GoldengateDeploymentVersion
    # Field: name Type: 9 ()
    # Field: ocid Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.GoldengateDeploymentVersionProperties)

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersionProperties ===
    # Fields for GoldengateDeploymentVersionProperties
    # Field: deployment_type Type: 14 (.google.cloud.oracledatabase.v1.GoldengateDeploymentVersionProperties.DeploymentType)
    # Field: security_fix Type: 8 ()
    # Field: ogg_version Type: 9 ()
    # Field: release_type Type: 14 (.google.cloud.oracledatabase.v1.GoldengateDeploymentVersionProperties.DeploymentReleaseType)
    # Field: release_time Type: 11 (.google.protobuf.Timestamp)
    # Field: support_end_time Type: 11 (.google.protobuf.Timestamp)

# Enum: GoldengateDeploymentVersionProperties::DeploymentType
our $GoldengateDeploymentVersionProperties_DEPLOYMENT_TYPE_UNSPECIFIED = 0;
our $GoldengateDeploymentVersionProperties_OGG = 1;
our $GoldengateDeploymentVersionProperties_DATABASE_ORACLE = 2;
our $GoldengateDeploymentVersionProperties_BIGDATA = 3;
our $GoldengateDeploymentVersionProperties_DATABASE_MICROSOFT_SQLSERVER = 4;
our $GoldengateDeploymentVersionProperties_DATABASE_MYSQL = 5;
our $GoldengateDeploymentVersionProperties_DATABASE_POSTGRESQL = 6;
our $GoldengateDeploymentVersionProperties_DATABASE_DB2ZOS = 7;
our $GoldengateDeploymentVersionProperties_DATABASE_DB2I = 8;
our $GoldengateDeploymentVersionProperties_GGSA = 9;
our $GoldengateDeploymentVersionProperties_DATA_TRANSFORMS = 10;

# Enum: GoldengateDeploymentVersionProperties::DeploymentReleaseType
our $GoldengateDeploymentVersionProperties_DEPLOYMENT_RELEASE_TYPE_UNSPECIFIED = 0;
our $GoldengateDeploymentVersionProperties_MAJOR = 1;
our $GoldengateDeploymentVersionProperties_BUNDLE = 2;
our $GoldengateDeploymentVersionProperties_MINOR = 3;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsRequest ===
    # Fields for ListGoldengateDeploymentVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsResponse ===
    # Fields for ListGoldengateDeploymentVersionsResponse
    # Field: goldengate_deployment_versions Type: 11 (.google.cloud.oracledatabase.v1.GoldengateDeploymentVersion)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/goldengate_deployment_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion;

    my $msg = Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion->new({
        name => $name,
        ocid => $ocid,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/goldengate_deployment_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion

Details of the Goldengate Deployment Version resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Goldengate Deployment Version resource with the
format:
projects/{project}/locations/{location}/goldengateDeploymentVersions/{goldengate_deployment_version}

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. The deployment version ocid of the Goldengate Deployment
Version resource.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersionProperties>)

Output only. The technology type of the Goldengate Deployment Version
resource.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersionProperties

Properties of GoldengateDeploymentVersion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployment_type() >> / C<< $msg->deployment_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersionProperties::DeploymentType>)

Output only. The deployment type of the Goldengate Deployment Version
resource.

=item * C<< $msg->security_fix() >> / C<< $msg->security_fix($value) >>

Type: C<Bool>

Optional. Whether the Goldengate Deployment Version resource is a security
fix.

=item * C<< $msg->ogg_version() >> / C<< $msg->ogg_version($value) >>

Type: C<String>

Output only. The OGG version of the Goldengate Deployment Version resource.

=item * C<< $msg->release_type() >> / C<< $msg->release_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersionProperties::DeploymentReleaseType>)

Output only. The release type of the Goldengate Deployment Version
resource.

=item * C<< $msg->release_time() >> / C<< $msg->release_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The release time of the Goldengate Deployment Version
resource.

=item * C<< $msg->support_end_time() >> / C<< $msg->support_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The support end time of the Goldengate Deployment Version
resource.

=back

=head3 Enum: GoldengateDeploymentVersionProperties::DeploymentType

=over 4

=item * C<DEPLOYMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<OGG> => C<1>

=item * C<DATABASE_ORACLE> => C<2>

=item * C<BIGDATA> => C<3>

=item * C<DATABASE_MICROSOFT_SQLSERVER> => C<4>

=item * C<DATABASE_MYSQL> => C<5>

=item * C<DATABASE_POSTGRESQL> => C<6>

=item * C<DATABASE_DB2ZOS> => C<7>

=item * C<DATABASE_DB2I> => C<8>

=item * C<GGSA> => C<9>

=item * C<DATA_TRANSFORMS> => C<10>

=back

=head3 Enum: GoldengateDeploymentVersionProperties::DeploymentReleaseType

=over 4

=item * C<DEPLOYMENT_RELEASE_TYPE_UNSPECIFIED> => C<0>

=item * C<MAJOR> => C<1>

=item * C<BUNDLE> => C<2>

=item * C<MINOR> => C<3>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsRequest

Message for listing GoldengateDeploymentVersions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListGoldengateDeploymentVersionsRequest
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default. The
maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Either
the deployment_id and deployment_type fields must be specified in the
format: `deployment_id="id"` or `deployment_type="DATABASE_ORACLE"`.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::ListGoldengateDeploymentVersionsResponse

Message for response to listing GoldengateDeploymentVersions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->goldengate_deployment_versions() >> / C<< $msg->goldengate_deployment_versions($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::GoldengateDeploymentVersion>)

The list of GoldengateDeploymentVersion

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
