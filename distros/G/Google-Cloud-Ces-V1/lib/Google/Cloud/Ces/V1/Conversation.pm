package Google::Cloud::Ces::V1::Conversation;

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
    eval { require Google::Cloud::Ces::V1::Common };
    eval { require Google::Cloud::Ces::V1::Example };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvY2VzL3YxL2NvbnZlcnNhdGlvbi5wcm90bxITZ29vZ2xlLmNsb3Vk
LmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxogZ29vZ2xlL2Nsb3VkL2Nlcy92MS9jb21tb24ucHJvdG8aIWdvb2ds
ZS9jbG91ZC9jZXMvdjEvZXhhbXBsZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90byLECwoMQ29udmVyc2F0aW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRI+Cgpz
dGFydF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUglzdGFy
dFRpbWUSOgoIZW5kX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSB2VuZFRpbWUSQQoFdHVybnMYBiADKAsyJi5nb29nbGUuY2xvdWQuY2VzLnYxLkNvbnZl
cnNhdGlvbi5UdXJuQgPgQQJSBXR1cm5zEiIKCnR1cm5fY291bnQYByABKAVCA+BBA1IJdHVy
bkNvdW50ElQKDGNoYW5uZWxfdHlwZRgIIAEoDjItLmdvb2dsZS5jbG91ZC5jZXMudjEuQ29u
dmVyc2F0aW9uLkNoYW5uZWxUeXBlQgIYAVILY2hhbm5lbFR5cGUSRQoGc291cmNlGAkgASgO
MiguZ29vZ2xlLmNsb3VkLmNlcy52MS5Db252ZXJzYXRpb24uU291cmNlQgPgQQNSBnNvdXJj
ZRJRCgtpbnB1dF90eXBlcxgKIAMoDjIrLmdvb2dsZS5jbG91ZC5jZXMudjEuQ29udmVyc2F0
aW9uLklucHV0VHlwZUID4EEDUgppbnB1dFR5cGVzEkEKC2VudHJ5X2FnZW50GAsgASgJQiDg
QQP6QRoKGGNlcy5nb29nbGVhcGlzLmNvbS9BZ2VudFIKZW50cnlBZ2VudBJFCgpkZXBsb3lt
ZW50GAwgASgJQiXgQQP6QR8KHWNlcy5nb29nbGVhcGlzLmNvbS9EZXBsb3ltZW50UgpkZXBs
b3ltZW50EkYKC2FwcF92ZXJzaW9uGA0gASgJQiXgQQP6QR8KHWNlcy5nb29nbGVhcGlzLmNv
bS9BcHBWZXJzaW9uUgphcHBWZXJzaW9uEigKDWxhbmd1YWdlX2NvZGUYDiABKAlCA+BBA1IM
bGFuZ3VhZ2VDb2RlEjwKCG1lc3NhZ2VzGAIgAygLMhwuZ29vZ2xlLmNsb3VkLmNlcy52MS5N
ZXNzYWdlQgIYAVIIbWVzc2FnZXMaggEKBFR1cm4SPQoIbWVzc2FnZXMYASADKAsyHC5nb29n
bGUuY2xvdWQuY2VzLnYxLk1lc3NhZ2VCA+BBAVIIbWVzc2FnZXMSOwoJcm9vdF9zcGFuGAIg
ASgLMhkuZ29vZ2xlLmNsb3VkLmNlcy52MS5TcGFuQgPgQQFSCHJvb3RTcGFuIlAKC0NoYW5u
ZWxUeXBlEhwKGENIQU5ORUxfVFlQRV9VTlNQRUNJRklFRBAAEggKBFRFWFQQARIJCgVBVURJ
TxACEg4KCk1VTFRJTU9EQUwQAyJTCgZTb3VyY2USFgoSU09VUkNFX1VOU1BFQ0lGSUVEEAAS
CAoETElWRRABEg0KCVNJTVVMQVRPUhACEggKBEVWQUwQAxIOCgpBR0VOVF9UT09MEAQiywEK
CUlucHV0VHlwZRIaChZJTlBVVF9UWVBFX1VOU1BFQ0lGSUVEEAASEwoPSU5QVVRfVFlQRV9U
RVhUEAESFAoQSU5QVVRfVFlQRV9FVkVOVBAHEhQKEElOUFVUX1RZUEVfQVVESU8QAhIUChBJ
TlBVVF9UWVBFX0lNQUdFEAMSEwoPSU5QVVRfVFlQRV9CTE9CEAQSHAoYSU5QVVRfVFlQRV9U
T09MX1JFU1BPTlNFEAUSGAoUSU5QVVRfVFlQRV9WQVJJQUJMRVMQBjqTAepBjwEKH2Nlcy5n
b29nbGVhcGlzLmNvbS9Db252ZXJzYXRpb24ST3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2NvbnZlcnNhdGlvbnMve2NvbnZlcnNhdGlvbn0q
DWNvbnZlcnNhdGlvbnMyDGNvbnZlcnNhdGlvbkJZChdjb20uZ29vZ2xlLmNsb3VkLmNlcy52
MUIRQ29udmVyc2F0aW9uUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjEv
Y2VzcGI7Y2VzcGJK5SsKBxIFDgCrAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoCAwMS
AxUAKwoJCgIDBBIDFgApCggKAQgSAxgAQAoJCgIICxIDGABACggKAQgSAxkAIgoJCgIIChID
GQAiCggKAQgSAxoAMgoJCgIICBIDGgAyCggKAQgSAxsAMAoJCgIIARIDGwAwClwKAgQAEgUe
AKsBARpPIEEgY29udmVyc2F0aW9uIHJlcHJlc2VudHMgYW4gaW50ZXJhY3Rpb24gYmV0d2Vl
biBhbiBlbmQgdXNlciBhbmQgdGhlIENFUyBhcHAuCgoKCgMEAAESAx4IFAoLCgMEAAcSBB8C
JAQKDQoFBAAHnQgSBB8CJAQKSAoEBAADABIEJwIuAxo6IEFsbCBpbmZvcm1hdGlvbiBhYm91
dCBhIHNpbmdsZSB0dXJuIGluIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAMAARIDJwoOCpwB
CgYEAAMAAgASAyoESxqMASBPcHRpb25hbC4gTGlzdCBvZiBtZXNzYWdlcyBpbiB0aGUgY29u
dmVyc2F0aW9uIHR1cm4sIGluY2x1ZGluZyB1c2VyCiBpbnB1dCwgYWdlbnQgcmVzcG9uc2Vz
IGFuZCBpbnRlcm1lZGlhdGUgZXZlbnRzIGR1cmluZyB0aGUgcHJvY2Vzc2luZy4KCg4KBwQA
AwACAAQSAyoEDAoOCgcEAAMAAgAGEgMqDRQKDgoHBAADAAIAARIDKhUdCg4KBwQAAwACAAMS
AyogIQoOCgcEAAMAAgAIEgMqIkoKEQoKBAADAAIACJwIABIDKiNJCkIKBgQAAwACARIDLQRA
GjMgT3B0aW9uYWwuIFRoZSByb290IHNwYW4gb2YgdGhlIGFjdGlvbiBwcm9jZXNzaW5nLgoK
DgoHBAADAAIBBhIDLQQICg4KBwQAAwACAQESAy0JEgoOCgcEAAMAAgEDEgMtFRYKDgoHBAAD
AAIBCBIDLRc/ChEKCgQAAwACAQicCAASAy0YPgo1CgQEAAQAEgQxAkADGicgVGhlIGNoYW5u
ZWwgdHlwZSBvZiB0aGUgY29udmVyc2F0aW9uLgoKDAoFBAAEAAESAzEHEgoqCgYEAAQAAgAS
AzMEIRobIFVuc3BlY2lmaWVkIGNoYW5uZWwgdHlwZS4KCg4KBwQABAACAAESAzMEHAoOCgcE
AAQAAgACEgMzHyAKYgoGBAAEAAIBEgM3BA0aUyBUaGUgY29udmVyc2F0aW9uIG9ubHkgY29u
dGFpbnMgdGV4dCBtZXNzYWdlcyBiZXR3ZWVuIHRoZSBlbmQgdXNlciBhbmQgdGhlCiBhZ2Vu
dC4KCg4KBwQABAACAQESAzcECAoOCgcEAAQAAgECEgM3CwwKXgoGBAAEAAICEgM7BA4aTyBU
aGUgY29udmVyc2F0aW9uIGNvbnRhaW5zIGF1ZGlvIG1lc3NhZ2VzIGJldHdlZW4gdGhlIGVu
ZCB1c2VyIGFuZCB0aGUKIGFnZW50LgoKDgoHBAAEAAICARIDOwQJCg4KBwQABAACAgISAzsM
DQpoCgYEAAQAAgMSAz8EExpZIFRoZSBjb252ZXJzYXRpb24gbXVsdGktbW9kYWwgbWVzc2Fn
ZXMgKGUuZy4gaW1hZ2UpIGJldHdlZW4gdGhlIGVuZCB1c2VyCiBhbmQgdGhlIGFnZW50LgoK
DgoHBAAEAAIDARIDPwQOCg4KBwQABAACAwISAz8REgovCgQEAAQBEgRDAlMDGiEgVGhlIHNv
dXJjZSBvZiB0aGUgY29udmVyc2F0aW9uLgoKDAoFBAAEAQESA0MHDQokCgYEAAQBAgASA0UE
GxoVIFVuc3BlY2lmaWVkIHNvdXJjZS4KCg4KBwQABAECAAESA0UEFgoOCgcEAAQBAgACEgNF
GRoKPAoGBAAEAQIBEgNIBA0aLSBUaGUgY29udmVyc2F0aW9uIGlzIGZyb20gdGhlIGxpdmUg
ZW5kIHVzZXIuCgoOCgcEAAQBAgEBEgNIBAgKDgoHBAAEAQIBAhIDSAsMCjgKBgQABAECAhID
SwQSGikgVGhlIGNvbnZlcnNhdGlvbiBpcyBmcm9tIHRoZSBzaW11bGF0b3IuCgoOCgcEAAQB
AgIBEgNLBA0KDgoHBAAEAQICAhIDSxARCjkKBgQABAECAxIDTgQNGiogVGhlIGNvbnZlcnNh
dGlvbiBpcyBmcm9tIHRoZSBldmFsdWF0aW9uLgoKDgoHBAAEAQIDARIDTgQICg4KBwQABAEC
AwISA04LDAqiAQoGBAAEAQIEEgNSBBMakgEgVGhlIGNvbnZlcnNhdGlvbiBpcyBmcm9tIGFu
IGFnZW50IHRvb2wuIEFnZW50IHRvb2wgcnVucyB0aGUgYWdlbnQgaW4gYQogc2VwYXJhdGUg
c2Vzc2lvbiwgd2hpY2ggaXMgcGVyc2lzdGVkIGZvciB0ZXN0aW5nIGFuZCBkZWJ1Z2dpbmcg
cHVycG9zZXMuCgoOCgcEAAQBAgQBEgNSBA4KDgoHBAAEAQIEAhIDUhESCioKBAQABAISBFYC
bgMaHCBUeXBlIG9mIHRoZSBpbnB1dCBtZXNzYWdlLgoKDAoFBAAEAgESA1YHEAooCgYEAAQC
AgASA1gEHxoZIFVuc3BlY2lmaWVkIGlucHV0IHR5cGUuCgoOCgcEAAQCAgABEgNYBBoKDgoH
BAAEAgIAAhIDWB0eChwKBgQABAICARIDWwQYGg0gVGV4dCBpbnB1dC4KCg4KBwQABAICAQES
A1sEEwoOCgcEAAQCAgECEgNbFhcKHQoGBAAEAgICEgNeBBkaDiBFdmVudCBpbnB1dC4KCg4K
BwQABAICAgESA14EFAoOCgcEAAQCAgICEgNeFxgKHQoGBAAEAgIDEgNhBBkaDiBBdWRpbyBp
bnB1dC4KCg4KBwQABAICAwESA2EEFAoOCgcEAAQCAgMCEgNhFxgKHQoGBAAEAgIEEgNkBBka
DiBJbWFnZSBpbnB1dC4KCg4KBwQABAICBAESA2QEFAoOCgcEAAQCAgQCEgNkFxgKHAoGBAAE
AgIFEgNnBBgaDSBCbG9iIGlucHV0LgoKDgoHBAAEAgIFARIDZwQTCg4KBwQABAICBQISA2cW
Fwo1CgYEAAQCAgYSA2oEIRomIENsaWVudCBmdW5jdGlvbiB0b29sIHJlc3BvbnNlIGlucHV0
LgoKDgoHBAAEAgIGARIDagQcCg4KBwQABAICBgISA2ofIAohCgYEAAQCAgcSA20EHRoSIFZh
cmlhYmxlcyBpbnB1dC4KCg4KBwQABAICBwESA20EGAoOCgcEAAQCAgcCEgNtGxwKogEKBAQA
AgASA3MCPRqUASBJZGVudGlmaWVyLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGNv
bnZlcnNhdGlvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vYXBwcy97YXBwfS9jb252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259YAoKDAoF
BAACAAUSA3MCCAoMCgUEAAIAARIDcwkNCgwKBQQAAgADEgNzEBEKDAoFBAACAAgSA3MSPAoP
CggEAAIACJwIABIDcxM7CkkKBAQAAgESBHYCdzIaOyBPdXRwdXQgb25seS4gVGltZXN0YW1w
IHdoZW4gdGhlIGNvbnZlcnNhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgEGEgN2AhsKDAoF
BAACAQESA3YcJgoMCgUEAAIBAxIDdikqCgwKBQQAAgEIEgN3BjEKDwoIBAACAQicCAASA3cH
MApLCgQEAAICEgR6AnsyGj0gT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoZSBjb252
ZXJzYXRpb24gd2FzIGNvbXBsZXRlZC4KCgwKBQQAAgIGEgN6AhsKDAoFBAACAgESA3ocJAoM
CgUEAAICAxIDeicoCgwKBQQAAgIIEgN7BjEKDwoIBAACAgicCAASA3sHMAo3CgQEAAIDEgN+
AkMaKiBSZXF1aXJlZC4gVGhlIHR1cm5zIGluIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAID
BBIDfgIKCgwKBQQAAgMGEgN+Cw8KDAoFBAACAwESA34QFQoMCgUEAAIDAxIDfhgZCgwKBQQA
AgMIEgN+GkIKDwoIBAACAwicCAASA34bQQpFCgQEAAIEEgSBAQJDGjcgT3V0cHV0IG9ubHku
IFRoZSBudW1iZXIgb2YgdHVybnMgaW4gdGhlIGNvbnZlcnNhdGlvbi4KCg0KBQQAAgQFEgSB
AQIHCg0KBQQAAgQBEgSBAQgSCg0KBQQAAgQDEgSBARUWCg0KBQQAAgQIEgSBARdCChAKCAQA
AgQInAgAEgSBARhBCmwKBAQAAgUSBIUBAjMaXiBERVBSRUNBVEVELiBQbGVhc2UgdXNlCiBb
aW5wdXRfdHlwZXNdW2dvb2dsZS5jbG91ZC5jZXMudjEuQ29udmVyc2F0aW9uLmlucHV0X3R5
cGVzXSBpbnN0ZWFkLgoKDQoFBAACBQYSBIUBAg0KDQoFBAACBQESBIUBDhoKDQoFBAACBQMS
BIUBHR4KDQoFBAACBQgSBIUBHzIKDgoGBAACBQgDEgSFASAxCkUKBAQAAgYSBIgBAkAaNyBP
dXRwdXQgb25seS4gSW5kaWNhdGUgdGhlIHNvdXJjZSBvZiB0aGUgY29udmVyc2F0aW9uLgoK
DQoFBAACBgYSBIgBAggKDQoFBAACBgESBIgBCQ8KDQoFBAACBgMSBIgBEhMKDQoFBAACBggS
BIgBFD8KEAoIBAACBgicCAASBIgBFT4KQwoEBAACBxIGiwECjAEyGjMgT3V0cHV0IG9ubHku
IFRoZSBpbnB1dCB0eXBlcyBvZiB0aGUgY29udmVyc2F0aW9uLgoKDQoFBAACBwQSBIsBAgoK
DQoFBAACBwYSBIsBCxQKDQoFBAACBwESBIsBFSAKDQoFBAACBwMSBIsBIyUKDQoFBAACBwgS
BIwBBjEKEAoIBAACBwicCAASBIwBBzAK4QEKBAQAAggSBpEBApQBBBrQASBPdXRwdXQgb25s
eS4gVGhlIGFnZW50IHRoYXQgaW5pdGlhbGx5IGhhbmRsZXMgdGhlIGNvbnZlcnNhdGlvbi4g
SWYgbm90CiBzcGVjaWZpZWQsIHRoZSBjb252ZXJzYXRpb24gaXMgaGFuZGxlZCBieSB0aGUg
cm9vdCBhZ2VudC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hcHBzL3thcHB9L2FnZW50cy97YWdlbnR9YAoKDQoFBAACCAUSBJEBAggKDQoF
BAACCAESBJEBCRQKDQoFBAACCAMSBJEBFxkKDwoFBAACCAgSBpEBGpQBAwoQCggEAAIICJwI
ABIEkgEELQoPCgcEAAIICJ8IEgSTAQRKCrcBCgQEAAIJEgaZAQKcAQQapgEgT3V0cHV0IG9u
bHkuIFRoZSBkZXBsb3ltZW50IG9mIHRoZSBhcHAgdXNlZCBmb3IgcHJvY2Vzc2luZyB0aGUK
IGNvbnZlcnNhdGlvbi4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9hcHBzL3thcHB9L2RlcGxveW1lbnRzL3tkZXBsb3ltZW50fWAKCg0KBQQA
AgkFEgSZAQIICg0KBQQAAgkBEgSZAQkTCg0KBQQAAgkDEgSZARYYCg8KBQQAAgkIEgaZARmc
AQMKEAoIBAACCQicCAASBJoBBC0KDwoHBAACCQifCBIEmwEETwquAQoEBAACChIGoQECpAEE
Gp0BIE91dHB1dCBvbmx5LiBUaGUgdmVyc2lvbiBvZiB0aGUgYXBwIHVzZWQgZm9yIHByb2Nl
c3NpbmcgdGhlIGNvbnZlcnNhdGlvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS92ZXJzaW9ucy97dmVyc2lvbn1gCgoN
CgUEAAIKBRIEoQECCAoNCgUEAAIKARIEoQEJFAoNCgUEAAIKAxIEoQEXGQoPCgUEAAIKCBIG
oQEapAEDChAKCAQAAgoInAgAEgSiAQQtCg8KBwQAAgoInwgSBKMBBE8KQwoEBAACCxIEpwEC
SBo1IE91dHB1dCBvbmx5LiBUaGUgbGFuZ3VhZ2UgY29kZSBvZiB0aGUgY29udmVyc2F0aW9u
LgoKDQoFBAACCwUSBKcBAggKDQoFBAACCwESBKcBCRYKDQoFBAACCwMSBKcBGRsKDQoFBAAC
CwgSBKcBHEcKEAoIBAACCwicCAASBKcBHUYKLgoEBAACDBIEqgECNBogIERlcHJlY2F0ZWQu
IFVzZSB0dXJucyBpbnN0ZWFkLgoKDQoFBAACDAQSBKoBAgoKDQoFBAACDAYSBKoBCxIKDQoF
BAACDAESBKoBExsKDQoFBAACDAMSBKoBHh8KDQoFBAACDAgSBKoBIDMKDgoGBAACDAgDEgSq
ASEyYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: turns Type: 11 (.google.cloud.ces.v1.Conversation.Turn)
    # Field: turn_count Type: 5 ()
    # Field: channel_type Type: 14 (.google.cloud.ces.v1.Conversation.ChannelType)
    # Field: source Type: 14 (.google.cloud.ces.v1.Conversation.Source)
    # Field: input_types Type: 14 (.google.cloud.ces.v1.Conversation.InputType)
    # Field: entry_agent Type: 9 ()
    # Field: deployment Type: 9 ()
    # Field: app_version Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.ces.v1.Message)

# Enum: Conversation::ChannelType
our $Conversation_CHANNEL_TYPE_UNSPECIFIED = 0;
our $Conversation_TEXT = 1;
our $Conversation_AUDIO = 2;
our $Conversation_MULTIMODAL = 3;

# Enum: Conversation::Source
our $Conversation_SOURCE_UNSPECIFIED = 0;
our $Conversation_LIVE = 1;
our $Conversation_SIMULATOR = 2;
our $Conversation_EVAL = 3;
our $Conversation_AGENT_TOOL = 4;

# Enum: Conversation::InputType
our $Conversation_INPUT_TYPE_UNSPECIFIED = 0;
our $Conversation_INPUT_TYPE_TEXT = 1;
our $Conversation_INPUT_TYPE_EVENT = 7;
our $Conversation_INPUT_TYPE_AUDIO = 2;
our $Conversation_INPUT_TYPE_IMAGE = 3;
our $Conversation_INPUT_TYPE_BLOB = 4;
our $Conversation_INPUT_TYPE_TOOL_RESPONSE = 5;
our $Conversation_INPUT_TYPE_VARIABLES = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Conversation - Compiled Protocol Buffers messages for google/cloud/ces/v1/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Conversation;

    my $msg = Google::Cloud::Ces::V1::Conversation::Conversation->new({
        name => $name,
        start_time => $start_time,
        end_time => $end_time,
        turns => $turns,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Conversation::Conversation

A conversation represents an interaction between an end user and the CES app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the conversation.
Format:
`projects/{project}/locations/{location}/apps/{app}/conversations/{conversation}`

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the conversation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the conversation was completed.

=item * C<< $msg->turns() >> / C<< $msg->turns($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Conversation::Conversation::Turn>)

Required. The turns in the conversation.

=item * C<< $msg->turn_count() >> / C<< $msg->turn_count($value) >>

Type: C<Int32>

Output only. The number of turns in the conversation.

=item * C<< $msg->channel_type() >> / C<< $msg->channel_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::Conversation::ChannelType>)

DEPRECATED. Please use
[input_types][google.cloud.ces.v1.Conversation.input_types] instead.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::Conversation::Source>)

Output only. Indicate the source of the conversation.

=item * C<< $msg->input_types() >> / C<< $msg->input_types($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::Conversation::InputType>)

Output only. The input types of the conversation.

=item * C<< $msg->entry_agent() >> / C<< $msg->entry_agent($value) >>

Type: C<String>

Output only. The agent that initially handles the conversation. If not
specified, the conversation is handled by the root agent. Format:
`projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<String>

Output only. The deployment of the app used for processing the
conversation. Format:
`projects/{project}/locations/{location}/apps/{app}/deployments/{deployment}`

=item * C<< $msg->app_version() >> / C<< $msg->app_version($value) >>

Type: C<String>

Output only. The version of the app used for processing the conversation.
Format:
`projects/{project}/locations/{location}/apps/{app}/versions/{version}`

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Output only. The language code of the conversation.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::Message>)

Deprecated. Use turns instead.

=back

=head3 Enum: Conversation::ChannelType

=over 4

=item * C<CHANNEL_TYPE_UNSPECIFIED> => C<0>

=item * C<TEXT> => C<1>

=item * C<AUDIO> => C<2>

=item * C<MULTIMODAL> => C<3>

=back

=head3 Enum: Conversation::Source

=over 4

=item * C<SOURCE_UNSPECIFIED> => C<0>

=item * C<LIVE> => C<1>

=item * C<SIMULATOR> => C<2>

=item * C<EVAL> => C<3>

=item * C<AGENT_TOOL> => C<4>

=back

=head3 Enum: Conversation::InputType

=over 4

=item * C<INPUT_TYPE_UNSPECIFIED> => C<0>

=item * C<INPUT_TYPE_TEXT> => C<1>

=item * C<INPUT_TYPE_EVENT> => C<7>

=item * C<INPUT_TYPE_AUDIO> => C<2>

=item * C<INPUT_TYPE_IMAGE> => C<3>

=item * C<INPUT_TYPE_BLOB> => C<4>

=item * C<INPUT_TYPE_TOOL_RESPONSE> => C<5>

=item * C<INPUT_TYPE_VARIABLES> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
