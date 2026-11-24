package Google::Cloud::Channel::V1::Entitlements;

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
    eval { require Google::Cloud::Channel::V1::Common };
    eval { require Google::Cloud::Channel::V1::Offers };
    eval { require Google::Cloud::Channel::V1::Products };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9lbnRpdGxlbWVudHMucHJvdG8SF2dvb2dsZS5j
bG91ZC5jaGFubmVsLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGiRnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9jb21tb24u
cHJvdG8aJGdvb2dsZS9jbG91ZC9jaGFubmVsL3YxL29mZmVycy5wcm90bxomZ29vZ2xlL2Ns
b3VkL2NoYW5uZWwvdjEvcHJvZHVjdHMucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8i7goKC0VudGl0bGVtZW50EhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJACgtj
cmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3Jl
YXRlVGltZRJACgt1cGRhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKdXBkYXRlVGltZRI/CgVvZmZlchgIIAEoCUIp4EEC+kEjCiFjbG91ZGNoYW5u
ZWwuZ29vZ2xlYXBpcy5jb20vT2ZmZXJSBW9mZmVyElwKE2NvbW1pdG1lbnRfc2V0dGluZ3MY
DCABKAsyKy5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5Db21taXRtZW50U2V0dGluZ3NSEmNv
bW1pdG1lbnRTZXR0aW5ncxJqChJwcm92aXNpb25pbmdfc3RhdGUYDSABKA4yNi5nb29nbGUu
Y2xvdWQuY2hhbm5lbC52MS5FbnRpdGxlbWVudC5Qcm92aXNpb25pbmdTdGF0ZUID4EEDUhFw
cm92aXNpb25pbmdTdGF0ZRJhChNwcm92aXNpb25lZF9zZXJ2aWNlGBAgASgLMisuZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjEuUHJvdmlzaW9uZWRTZXJ2aWNlQgPgQQNSEnByb3Zpc2lvbmVk
U2VydmljZRJpChJzdXNwZW5zaW9uX3JlYXNvbnMYEiADKA4yNS5nb29nbGUuY2xvdWQuY2hh
bm5lbC52MS5FbnRpdGxlbWVudC5TdXNwZW5zaW9uUmVhc29uQgPgQQNSEXN1c3BlbnNpb25S
ZWFzb25zEi8KEXB1cmNoYXNlX29yZGVyX2lkGBMgASgJQgPgQQFSD3B1cmNoYXNlT3JkZXJJ
ZBJSCg50cmlhbF9zZXR0aW5ncxgVIAEoCzImLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlRy
aWFsU2V0dGluZ3NCA+BBA1INdHJpYWxTZXR0aW5ncxJTChBhc3NvY2lhdGlvbl9pbmZvGBcg
ASgLMiguZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuQXNzb2NpYXRpb25JbmZvUg9hc3NvY2lh
dGlvbkluZm8SQgoKcGFyYW1ldGVycxgaIAMoCzIiLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYx
LlBhcmFtZXRlclIKcGFyYW1ldGVycxIsCg9iaWxsaW5nX2FjY291bnQYHCABKAlCA+BBAVIO
YmlsbGluZ0FjY291bnQSMQoScHJpY2VfcmVmZXJlbmNlX2lkGB0gASgJQgPgQQFSEHByaWNl
UmVmZXJlbmNlSWQiUgoRUHJvdmlzaW9uaW5nU3RhdGUSIgoeUFJPVklTSU9OSU5HX1NUQVRF
X1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESDQoJU1VTUEVOREVEEAUiowEKEFN1c3BlbnNp
b25SZWFzb24SIQodU1VTUEVOU0lPTl9SRUFTT05fVU5TUEVDSUZJRUQQABIWChJSRVNFTExF
Ul9JTklUSUFURUQQARIPCgtUUklBTF9FTkRFRBACEhwKGFJFTkVXQUxfV0lUSF9UWVBFX0NB
TkNFTBADEhoKFlBFTkRJTkdfVE9TX0FDQ0VQVEFOQ0UQBBIJCgVPVEhFUhBkOnDqQW0KJ2Ns
b3VkY2hhbm5lbC5nb29nbGVhcGlzLmNvbS9FbnRpdGxlbWVudBJCYWNjb3VudHMve2FjY291
bnR9L2N1c3RvbWVycy97Y3VzdG9tZXJ9L2VudGl0bGVtZW50cy97ZW50aXRsZW1lbnR9InYK
CVBhcmFtZXRlchISCgRuYW1lGAEgASgJUgRuYW1lEjQKBXZhbHVlGAIgASgLMh4uZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjEuVmFsdWVSBXZhbHVlEh8KCGVkaXRhYmxlGAMgASgIQgPgQQNS
CGVkaXRhYmxlImoKD0Fzc29jaWF0aW9uSW5mbxJXChBiYXNlX2VudGl0bGVtZW50GAEgASgJ
Qiz6QSkKJ2Nsb3VkY2hhbm5lbC5nb29nbGVhcGlzLmNvbS9FbnRpdGxlbWVudFIPYmFzZUVu
dGl0bGVtZW50IoIBChJQcm92aXNpb25lZFNlcnZpY2USLAoPcHJvdmlzaW9uaW5nX2lkGAEg
ASgJQgPgQQNSDnByb3Zpc2lvbmluZ0lkEiIKCnByb2R1Y3RfaWQYAiABKAlCA+BBA1IJcHJv
ZHVjdElkEhoKBnNrdV9pZBgDIAEoCUID4EEDUgVza3VJZCLqAQoSQ29tbWl0bWVudFNldHRp
bmdzEj4KCnN0YXJ0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCXN0YXJ0VGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IHZW5kVGltZRJYChByZW5ld2FsX3NldHRpbmdzGAQgASgLMiguZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjEuUmVuZXdhbFNldHRpbmdzQgPgQQFSD3JlbmV3YWxTZXR0aW5n
cyLzAQoPUmVuZXdhbFNldHRpbmdzEiUKDmVuYWJsZV9yZW5ld2FsGAEgASgIUg1lbmFibGVS
ZW5ld2FsEioKEXJlc2l6ZV91bml0X2NvdW50GAIgASgIUg9yZXNpemVVbml0Q291bnQSRwoM
cGF5bWVudF9wbGFuGAUgASgOMiQuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuUGF5bWVudFBs
YW5SC3BheW1lbnRQbGFuEkQKDXBheW1lbnRfY3ljbGUYBiABKAsyHy5nb29nbGUuY2xvdWQu
Y2hhbm5lbC52MS5QZXJpb2RSDHBheW1lbnRDeWNsZSJcCg1UcmlhbFNldHRpbmdzEhQKBXRy
aWFsGAEgASgIUgV0cmlhbBI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSB2VuZFRpbWUi5AEKD1RyYW5zZmVyYWJsZVNrdRJfChR0cmFuc2Zlcl9lbGln
aWJpbGl0eRgJIAEoCzIsLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLlRyYW5zZmVyRWxpZ2li
aWxpdHlSE3RyYW5zZmVyRWxpZ2liaWxpdHkSLgoDc2t1GAsgASgLMhwuZ29vZ2xlLmNsb3Vk
LmNoYW5uZWwudjEuU2t1UgNza3USQAoKbGVnYWN5X3NrdRgMIAEoCzIcLmdvb2dsZS5jbG91
ZC5jaGFubmVsLnYxLlNrdUID4EEBUglsZWdhY3lTa3Ui1AIKE1RyYW5zZmVyRWxpZ2liaWxp
dHkSHwoLaXNfZWxpZ2libGUYASABKAhSCmlzRWxpZ2libGUSIAoLZGVzY3JpcHRpb24YAiAB
KAlSC2Rlc2NyaXB0aW9uEmYKFGluZWxpZ2liaWxpdHlfcmVhc29uGAMgASgOMjMuZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjEuVHJhbnNmZXJFbGlnaWJpbGl0eS5SZWFzb25SE2luZWxpZ2li
aWxpdHlSZWFzb24ikQEKBlJlYXNvbhIWChJSRUFTT05fVU5TUEVDSUZJRUQQABIaChZQRU5E
SU5HX1RPU19BQ0NFUFRBTkNFEAESFAoQU0tVX05PVF9FTElHSUJMRRACEhEKDVNLVV9TVVNQ
RU5ERUQQAxIqCiZDSEFOTkVMX1BBUlRORVJfTk9UX0FVVEhPUklaRURfRk9SX1NLVRAEQmkK
G2NvbS5nb29nbGUuY2xvdWQuY2hhbm5lbC52MUIRRW50aXRsZW1lbnRzUHJvdG9QAVo1Y2xv
dWQuZ29vZ2xlLmNvbS9nby9jaGFubmVsL2FwaXYxL2NoYW5uZWxwYjtjaGFubmVscGJKmk4K
BxIFDgCbAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAC4KCQoCAwMSAxUALgoJCgIDBBIDFgAw
CgkKAgMFEgMXACkKCAoBCBIDGQBMCgkKAggLEgMZAEwKCAoBCBIDGgAiCgkKAggKEgMaACIK
CAoBCBIDGwAyCgkKAggIEgMbADIKCAoBCBIDHAA0CgkKAggBEgMcADQKWwoCBAASBR8AmgEB
Gk4gQW4gZW50aXRsZW1lbnQgaXMgYSByZXByZXNlbnRhdGlvbiBvZiBhIGN1c3RvbWVyJ3Mg
YWJpbGl0eSB0byB1c2UgYSBzZXJ2aWNlLgoKCgoDBAABEgMfCBMKCwoDBAAHEgQgAiMECg0K
BQQAB50IEgQgAiMECkwKBAQABAASBCYCLwMaPiBJbmRpY2F0ZXMgdGhlIGN1cnJlbnQgcHJv
dmlzaW9uaW5nIHN0YXRlIG9mIHRoZSBlbnRpdGxlbWVudC4KCgwKBQQABAABEgMmBxgKGgoG
BAAEAAIAEgMoBCcaCyBOb3QgdXNlZC4KCg4KBwQABAACAAESAygEIgoOCgcEAAQAAgACEgMo
JSYKNQoGBAAEAAIBEgMrBA8aJiBUaGUgZW50aXRsZW1lbnQgaXMgY3VycmVudGx5IGFjdGl2
ZS4KCg4KBwQABAACAQESAysECgoOCgcEAAQAAgECEgMrDQ4KOAoGBAAEAAICEgMuBBIaKSBU
aGUgZW50aXRsZW1lbnQgaXMgY3VycmVudGx5IHN1c3BlbmRlZC4KCg4KBwQABAACAgESAy4E
DQoOCgcEAAQAAgICEgMuEBEKlAEKBAQABAESBDQCRwMahQEgU3VzcGVuc2lvbiByZWFzb24g
Zm9yIGFuIGVudGl0bGVtZW50IGlmCiBbcHJvdmlzaW9uaW5nX3N0YXRlXVtnb29nbGUuY2xv
dWQuY2hhbm5lbC52MS5FbnRpdGxlbWVudC5wcm92aXNpb25pbmdfc3RhdGVdCiA9IFNVU1BF
TkRFRC4KCgwKBQQABAEBEgM0BxcKGgoGBAAEAQIAEgM2BCYaCyBOb3QgdXNlZC4KCg4KBwQA
BAECAAESAzYEIQoOCgcEAAQBAgACEgM2JCUKRAoGBAAEAQIBEgM5BBsaNSBFbnRpdGxlbWVu
dCB3YXMgbWFudWFsbHkgc3VzcGVuZGVkIGJ5IHRoZSBSZXNlbGxlci4KCg4KBwQABAECAQES
AzkEFgoOCgcEAAQBAgECEgM5GRoKHQoGBAAEAQICEgM8BBQaDiBUcmlhbCBlbmRlZC4KCg4K
BwQABAECAgESAzwEDwoOCgcEAAQBAgICEgM8EhMKMgoGBAAEAQIDEgM/BCEaIyBFbnRpdGxl
bWVudCByZW5ld2FsIHdhcyBjYW5jZWxlZC4KCg4KBwQABAECAwESAz8EHAoOCgcEAAQBAgMC
EgM/HyAKbQoGBAAEAQIEEgNDBB8aXiBFbnRpdGxlbWVudCB3YXMgYXV0b21hdGljYWxseSBz
dXNwZW5kZWQgb24gY3JlYXRpb24gZm9yIHBlbmRpbmcgVG9TCiBhY2NlcHRhbmNlIG9uIGN1
c3RvbWVyLgoKDgoHBAAEAQIEARIDQwQaCg4KBwQABAECBAISA0MdHgo/CgYEAAQBAgUSA0YE
EBowIE90aGVyIHJlYXNvbnMgKGludGVybmFsIHJlYXNvbnMsIGFidXNlLCBldGMuKS4KCg4K
BwQABAECBQESA0YECQoOCgcEAAQBAgUCEgNGDA8KlwEKBAQAAgASA0sCPhqJASBPdXRwdXQg
b25seS4gUmVzb3VyY2UgbmFtZSBvZiBhbiBlbnRpdGxlbWVudCBpbiB0aGUgZm9ybToKIGFj
Y291bnRzL3thY2NvdW50X2lkfS9jdXN0b21lcnMve2N1c3RvbWVyX2lkfS9lbnRpdGxlbWVu
dHMve2VudGl0bGVtZW50X2lkfS4KCgwKBQQAAgAFEgNLAggKDAoFBAACAAESA0sJDQoMCgUE
AAIAAxIDSxARCgwKBQQAAgAIEgNLEj0KDwoIBAACAAicCAASA0sTPApKCgQEAAIBEgROAk8y
GjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBlbnRpdGxlbWVudCBpcyBj
cmVhdGVkLgoKDAoFBAACAQYSA04CGwoMCgUEAAIBARIDThwnCgwKBQQAAgEDEgNOKisKDAoF
BAACAQgSA08GMQoPCggEAAIBCJwIABIDTwcwCkoKBAQAAgISBFICUzIaPCBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhlIGVudGl0bGVtZW50IGlzIHVwZGF0ZWQuCgoMCgUE
AAICBhIDUgIbCgwKBQQAAgIBEgNSHCcKDAoFBAACAgMSA1IqKwoMCgUEAAICCBIDUwYxCg8K
CAQAAgIInAgAEgNTBzAKmAEKBAQAAgMSBFcCXAQaiQEgUmVxdWlyZWQuIFRoZSBvZmZlciBy
ZXNvdXJjZSBuYW1lIGZvciB3aGljaCB0aGUgZW50aXRsZW1lbnQgaXMgdG8gYmUKIGNyZWF0
ZWQuIFRha2VzIHRoZSBmb3JtOiBhY2NvdW50cy97YWNjb3VudF9pZH0vb2ZmZXJzL3tvZmZl
cl9pZH0uCgoMCgUEAAIDBRIDVwIICgwKBQQAAgMBEgNXCQ4KDAoFBAACAwMSA1cREgoNCgUE
AAIDCBIEVxNcAwoPCggEAAIDCJwIABIDWAQqCg8KBwQAAgMInwgSBFkEWwUKZwoEBAACBBID
YAIuGlogQ29tbWl0bWVudCBzZXR0aW5ncyBmb3IgYSBjb21taXRtZW50LWJhc2VkIE9mZmVy
LgogUmVxdWlyZWQgZm9yIGNvbW1pdG1lbnQgYmFzZWQgb2ZmZXJzLgoKDAoFBAACBAYSA2AC
FAoMCgUEAAIEARIDYBUoCgwKBQQAAgQDEgNgKy0KSwoEBAACBRIEYwJkMho9IE91dHB1dCBv
bmx5LiBDdXJyZW50IHByb3Zpc2lvbmluZyBzdGF0ZSBvZiB0aGUgZW50aXRsZW1lbnQuCgoM
CgUEAAIFBhIDYwITCgwKBQQAAgUBEgNjFCYKDAoFBAACBQMSA2MpKwoMCgUEAAIFCBIDZAYx
Cg8KCAQAAgUInAgAEgNkBzAKTgoEBAACBhIEZwJoMhpAIE91dHB1dCBvbmx5LiBTZXJ2aWNl
IHByb3Zpc2lvbmluZyBkZXRhaWxzIGZvciB0aGUgZW50aXRsZW1lbnQuCgoMCgUEAAIGBhID
ZwIUCgwKBQQAAgYBEgNnFSgKDAoFBAACBgMSA2crLQoMCgUEAAIGCBIDaAYxCg8KCAQAAgYI
nAgAEgNoBzAKXgoEBAACBxIEbAJtMhpQIE91dHB1dCBvbmx5LiBFbnVtZXJhYmxlIG9mIGFs
bCBjdXJyZW50IHN1c3BlbnNpb24gcmVhc29ucyBmb3IgYW4KIGVudGl0bGVtZW50LgoKDAoF
BAACBwQSA2wCCgoMCgUEAAIHBhIDbAsbCgwKBQQAAgcBEgNsHC4KDAoFBAACBwMSA2wxMwoM
CgUEAAIHCBIDbQYxCg8KCAQAAgcInAgAEgNtBzAKzQIKBAQAAggSA3QCSRq/AiBPcHRpb25h
bC4gVGhpcyBwdXJjaGFzZSBvcmRlciAoUE8pIGluZm9ybWF0aW9uIGlzIGZvciByZXNlbGxl
cnMgdG8gdXNlIGZvcgogdGhlaXIgY29tcGFueSB0cmFja2luZyB1c2FnZS4gSWYgYSBwdXJj
aGFzZU9yZGVySWQgdmFsdWUgaXMgZ2l2ZW4sIGl0CiBhcHBlYXJzIGluIHRoZSBBUEkgcmVz
cG9uc2VzIGFuZCBzaG93cyB1cCBpbiB0aGUgaW52b2ljZS4gVGhlIHByb3BlcnR5CiBhY2Nl
cHRzIHVwIHRvIDgwIHBsYWluIHRleHQgY2hhcmFjdGVycy4gVGhpcyBpcyBvbmx5IHN1cHBv
cnRlZCBmb3IgR29vZ2xlCiBXb3Jrc3BhY2UgZW50aXRsZW1lbnRzLgoKDAoFBAACCAUSA3QC
CAoMCgUEAAIIARIDdAkaCgwKBQQAAggDEgN0HR8KDAoFBAACCAgSA3QgSAoPCggEAAIICJwI
ABIDdCFHCjYKBAQAAgkSA3cCUBopIE91dHB1dCBvbmx5LiBTZXR0aW5ncyBmb3IgdHJpYWwg
b2ZmZXJzLgoKDAoFBAACCQYSA3cCDwoMCgUEAAIJARIDdxAeCgwKBQQAAgkDEgN3ISMKDAoF
BAACCQgSA3ckTwoPCggEAAIJCJwIABIDdyVOCj0KBAQAAgoSA3oCKBowIEFzc29jaWF0aW9u
IGluZm9ybWF0aW9uIHRvIG90aGVyIGVudGl0bGVtZW50cy4KCgwKBQQAAgoGEgN6AhEKDAoF
BAACCgESA3oSIgoMCgUEAAIKAxIDeiUnCs8FCgQEAAILEgSQAQIlGsAFIEV4dGVuZGVkIGVu
dGl0bGVtZW50IHBhcmFtZXRlcnMuIFdoZW4gY3JlYXRpbmcgYW4gZW50aXRsZW1lbnQsIHZh
bGlkCiBwYXJhbWV0ZXIgbmFtZXMgYW5kIHZhbHVlcyBhcmUgZGVmaW5lZCBpbiB0aGUKIFtP
ZmZlci5wYXJhbWV0ZXJfZGVmaW5pdGlvbnNdW2dvb2dsZS5jbG91ZC5jaGFubmVsLnYxLk9m
ZmVyLnBhcmFtZXRlcl9kZWZpbml0aW9uc10uCgogRm9yIEdvb2dsZSBXb3Jrc3BhY2UsIHRo
ZSBmb2xsb3dpbmcgUGFyYW1ldGVycyBtYXkgYmUgYWNjZXB0ZWQgYXMgaW5wdXQ6CgogLSBt
YXhfdW5pdHM6IFRoZSBtYXhpbXVtIGFzc2lnbmFibGUgdW5pdHMgZm9yIGEgZmxleGlibGUg
b2ZmZXIKCiBPUgoKIC0gbnVtX3VuaXRzOiBUaGUgdG90YWwgY29tbWl0bWVudCBmb3IgY29t
bWl0bWVudC1iYXNlZCBvZmZlcnMKCiBUaGUgcmVzcG9uc2UgbWF5IGFkZGl0aW9uYWxseSBp
bmNsdWRlIHRoZSBmb2xsb3dpbmcgb3V0cHV0LW9ubHkgUGFyYW1ldGVyczoKCiAtIGFzc2ln
bmVkX3VuaXRzOiBUaGUgbnVtYmVyIG9mIGxpY2Vuc2VzIGFzc2lnbmVkIHRvIHVzZXJzLgoK
IEZvciBHb29nbGUgQ2xvdWQgYmlsbGluZyBzdWJhY2NvdW50cywgdGhlIGZvbGxvd2luZyBQ
YXJhbWV0ZXIgbWF5IGJlCiBhY2NlcHRlZCBhcyBpbnB1dDoKCiAtIGRpc3BsYXlfbmFtZTog
VGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgYmlsbGluZyBzdWJhY2NvdW50LgoKDQoFBAACCwQS
BJABAgoKDQoFBAACCwYSBJABCxQKDQoFBAACCwESBJABFR8KDQoFBAACCwMSBJABIiQKZgoE
BAACDBIElAECRxpYIE9wdGlvbmFsLiBUaGUgYmlsbGluZyBhY2NvdW50IHJlc291cmNlIG5h
bWUgdGhhdCBpcyB1c2VkIHRvIHBheSBmb3IgdGhpcwogZW50aXRsZW1lbnQuCgoNCgUEAAIM
BRIElAECCAoNCgUEAAIMARIElAEJGAoNCgUEAAIMAxIElAEbHQoNCgUEAAIMCBIElAEeRgoQ
CggEAAIMCJwIABIElAEfRQrbAQoEBAACDRIEmQECShrMASBPcHRpb25hbC4gUHJpY2UgcmVm
ZXJlbmNlIElEIGZvciB0aGUgb2ZmZXIuIE9ubHkgZm9yIG9mZmVycyB0aGF0IHJlcXVpcmUK
IGFkZGl0aW9uYWwgcHJpY2UgaW5mb3JtYXRpb24uIFVzZWQgdG8gZ3VhcmFudGVlIHRoYXQg
dGhlIHByaWNpbmcgaXMKIGNvbnNpc3RlbnQgYmV0d2VlbiBxdW90aW5nIHRoZSBvZmZlciBh
bmQgcGxhY2luZyB0aGUgb3JkZXIuCgoNCgUEAAINBRIEmQECCAoNCgUEAAINARIEmQEJGwoN
CgUEAAINAxIEmQEeIAoNCgUEAAINCBIEmQEhSQoQCggEAAINCJwIABIEmQEiSAo/CgIEARIG
nQEAqAEBGjEgRGVmaW5pdGlvbiBmb3IgZXh0ZW5kZWQgZW50aXRsZW1lbnQgcGFyYW1ldGVy
cy4KCgsKAwQBARIEnQEIEQomCgQEAQIAEgSfAQISGhggTmFtZSBvZiB0aGUgcGFyYW1ldGVy
LgoKDQoFBAECAAUSBJ8BAggKDQoFBAECAAESBJ8BCQ0KDQoFBAECAAMSBJ8BEBEKJwoEBAEC
ARIEogECEhoZIFZhbHVlIG9mIHRoZSBwYXJhbWV0ZXIuCgoNCgUEAQIBBhIEogECBwoNCgUE
AQIBARIEogEIDQoNCgUEAQIBAxIEogEQEQrhAQoEBAECAhIEpwECQBrSASBPdXRwdXQgb25s
eS4gU3BlY2lmaWVzIHdoZXRoZXIgdGhpcyBwYXJhbWV0ZXIgaXMgYWxsb3dlZCB0byBiZSBj
aGFuZ2VkLiBGb3IKIGV4YW1wbGUsIGZvciBhIEdvb2dsZSBXb3Jrc3BhY2UgQnVzaW5lc3Mg
U3RhcnRlciBlbnRpdGxlbWVudCBpbiBjb21taXRtZW50CiBwbGFuLCBudW1fdW5pdHMgaXMg
ZWRpdGFibGUgd2hlbiBlbnRpdGxlbWVudCBpcyBhY3RpdmUuCgoNCgUEAQICBRIEpwECBgoN
CgUEAQICARIEpwEHDwoNCgUEAQICAxIEpwESEwoNCgUEAQICCBIEpwEUPwoQCggEAQICCJwI
ABIEpwEVPgpQCgIEAhIGqwEAsAEBGkIgQXNzb2NpYXRpb24gbGlua3MgdGhhdCBhbiBlbnRp
dGxlbWVudCBoYXMgdG8gb3RoZXIgZW50aXRsZW1lbnRzLgoKCwoDBAIBEgSrAQgXClwKBAQC
AgASBq0BAq8BBRpMIFRoZSBuYW1lIG9mIHRoZSBiYXNlIGVudGl0bGVtZW50LCBmb3Igd2hp
Y2ggdGhpcyBlbnRpdGxlbWVudCBpcyBhbiBhZGQtb24uCgoNCgUEAgIABRIErQECCAoNCgUE
AgIAARIErQEJGQoNCgUEAgIAAxIErQEcHQoPCgUEAgIACBIGrQEerwEEChEKBwQCAgAInwgS
Bq0BH68BAwo3CgIEAxIGswEAwAEBGikgU2VydmljZSBwcm92aXNpb25lZCBmb3IgYW4gZW50
aXRsZW1lbnQuCgoLCgMEAwESBLMBCBoKzQEKBAQDAgASBLcBAkkavgEgT3V0cHV0IG9ubHku
IFByb3Zpc2lvbmluZyBJRCBvZiB0aGUgZW50aXRsZW1lbnQuIEZvciBHb29nbGUgV29ya3Nw
YWNlLCB0aGlzCiBpcyB0aGUgdW5kZXJseWluZyBTdWJzY3JpcHRpb24gSUQuIEZvciBHb29n
bGUgQ2xvdWQsIHRoaXMgaXMgdGhlIEJpbGxpbmcKIEFjY291bnQgSUQgb2YgdGhlIGJpbGxp
bmcgc3ViYWNjb3VudC4KCg0KBQQDAgAFEgS3AQIICg0KBQQDAgABEgS3AQkYCg0KBQQDAgAD
EgS3ARscCg0KBQQDAgAIEgS3AR1IChAKCAQDAgAInAgAEgS3AR5HCmwKBAQDAgESBLsBAkQa
XiBPdXRwdXQgb25seS4gVGhlIHByb2R1Y3QgcGVydGFpbmluZyB0byB0aGUgcHJvdmlzaW9u
aW5nIHJlc291cmNlIGFzCiBzcGVjaWZpZWQgaW4gdGhlIE9mZmVyLgoKDQoFBAMCAQUSBLsB
AggKDQoFBAMCAQESBLsBCRMKDQoFBAMCAQMSBLsBFhcKDQoFBAMCAQgSBLsBGEMKEAoIBAMC
AQicCAASBLsBGUIKaAoEBAMCAhIEvwECQBpaIE91dHB1dCBvbmx5LiBUaGUgU0tVIHBlcnRh
aW5pbmcgdG8gdGhlIHByb3Zpc2lvbmluZyByZXNvdXJjZSBhcyBzcGVjaWZpZWQKIGluIHRo
ZSBPZmZlci4KCg0KBQQDAgIFEgS/AQIICg0KBQQDAgIBEgS/AQkPCg0KBQQDAgIDEgS/ARIT
Cg0KBQQDAgIIEgS/ARQ/ChAKCAQDAgIInAgAEgS/ARU+CkAKAgQEEgbDAQDOAQEaMiBDb21t
aXRtZW50IHNldHRpbmdzIGZvciBjb21taXRtZW50LWJhc2VkIG9mZmVycy4KCgsKAwQEARIE
wwEIGgo6CgQEBAIAEgbFAQLGATIaKiBPdXRwdXQgb25seS4gQ29tbWl0bWVudCBzdGFydCB0
aW1lc3RhbXAuCgoNCgUEBAIABhIExQECGwoNCgUEBAIAARIExQEcJgoNCgUEBAIAAxIExQEp
KgoNCgUEBAIACBIExgEGMQoQCggEBAIACJwIABIExgEHMAo4CgQEBAIBEgbJAQLKATIaKCBP
dXRwdXQgb25seS4gQ29tbWl0bWVudCBlbmQgdGltZXN0YW1wLgoKDQoFBAQCAQYSBMkBAhsK
DQoFBAQCAQESBMkBHCQKDQoFBAQCAQMSBMkBJygKDQoFBAQCAQgSBMoBBjEKEAoIBAQCAQic
CAASBMoBBzAKUwoEBAQCAhIEzQECUBpFIE9wdGlvbmFsLiBSZW5ld2FsIHNldHRpbmdzIGFw
cGxpY2FibGUgZm9yIGEgY29tbWl0bWVudC1iYXNlZCBPZmZlci4KCg0KBQQEAgIGEgTNAQIR
Cg0KBQQEAgIBEgTNARIiCg0KBQQEAgIDEgTNASUmCg0KBQQEAgIIEgTNASdPChAKCAQEAgII
nAgAEgTNAShOCjYKAgQFEgbRAQDfAQEaKCBSZW5ld2FsIHNldHRpbmdzIGZvciByZW5ld2Fi
bGUgT2ZmZXJzLgoKCwoDBAUBEgTRAQgXCkUKBAQFAgASBNMBAhoaNyBJZiBmYWxzZSwgdGhl
IHBsYW4gd2lsbCBiZSBjb21wbGV0ZWQgYXQgdGhlIGVuZCBkYXRlLgoKDQoFBAUCAAUSBNMB
AgYKDQoFBAUCAAESBNMBBxUKDQoFBAUCAAMSBNMBGBkKmAEKBAQFAgESBNcBAh0aiQEgSWYg
dHJ1ZSBhbmQgZW5hYmxlX3JlbmV3YWwgPSB0cnVlLCB0aGUgdW5pdCAoZm9yIGV4YW1wbGUg
c2VhdHMgb3IgbGljZW5zZXMpCiB3aWxsIGJlIHNldCB0byB0aGUgbnVtYmVyIG9mIGFjdGl2
ZSB1bml0cyBhdCByZW5ld2FsIHRpbWUuCgoNCgUEBQIBBRIE1wECBgoNCgUEBQIBARIE1wEH
GAoNCgUEBQIBAxIE1wEbHAo4CgQEBQICEgTaAQIfGiogRGVzY3JpYmVzIGhvdyBhIHJlc2Vs
bGVyIHdpbGwgYmUgYmlsbGVkLgoKDQoFBAUCAgYSBNoBAg0KDQoFBAUCAgESBNoBDhoKDQoF
BAUCAgMSBNoBHR4KXgoEBAUCAxIE3gECGxpQIERlc2NyaWJlcyBob3cgZnJlcXVlbnRseSB0
aGUgcmVzZWxsZXIgd2lsbCBiZSBiaWxsZWQsIHN1Y2ggYXMKIG9uY2UgcGVyIG1vbnRoLgoK
DQoFBAUCAwYSBN4BAggKDQoFBAUCAwESBN4BCRYKDQoFBAUCAwMSBN4BGRoKKgoCBAYSBuIB
AO0BARocIFNldHRpbmdzIGZvciB0cmlhbCBvZmZlcnMuCgoLCgMEBgESBOIBCBUKnAEKBAQG
AgASBOcBAhEajQEgRGV0ZXJtaW5lcyBpZiB0aGUgZW50aXRsZW1lbnQgaXMgaW4gYSB0cmlh
bCBvciBub3Q6CgogKiBgdHJ1ZWAgLSBUaGUgZW50aXRsZW1lbnQgaXMgaW4gdHJpYWwuCiAq
IGBmYWxzZWAgLSBUaGUgZW50aXRsZW1lbnQgaXMgbm90IGluIHRyaWFsLgoKDQoFBAYCAAUS
BOcBAgYKDQoFBAYCAAESBOcBBwwKDQoFBAYCAAMSBOcBDxAKqAEKBAQGAgESBOwBAikamQEg
RGF0ZSB3aGVuIHRoZSB0cmlhbCBlbmRzLiBUaGUgdmFsdWUgaXMgaW4gbWlsbGlzZWNvbmRz
CiB1c2luZyB0aGUgVU5JWCBFcG9jaCBmb3JtYXQuIFNlZSBhbiBleGFtcGxlIFtFcG9jaAog
Y29udmVydGVyXShodHRwczovL3d3dy5lcG9jaGNvbnZlcnRlci5jb20pLgoKDQoFBAYCAQYS
BOwBAhsKDQoFBAYCAQESBOwBHCQKDQoFBAYCAQMSBOwBJygKoAEKAgQHEgbyAQD8AQEakQEg
VHJhbnNmZXJhYmxlU2t1IHJlcHJlc2VudHMgaW5mb3JtYXRpb24gYSByZXNlbGxlciBuZWVk
cyB0byB2aWV3IGV4aXN0aW5nCiBwcm92aXNpb25lZCBzZXJ2aWNlcyBmb3IgYSBjdXN0b21l
ciB0aGF0IHRoZXkgZG8gbm90IG93bi4KIFJlYWQtb25seS4KCgsKAwQHARIE8gEIFwo8CgQE
BwIAEgT0AQIvGi4gRGVzY3JpYmVzIHRoZSB0cmFuc2ZlciBlbGlnaWJpbGl0eSBvZiBhIFNL
VS4KCg0KBQQHAgAGEgT0AQIVCg0KBQQHAgABEgT0ARYqCg0KBQQHAgADEgT0AS0uCloKBAQH
AgESBPcBAg8aTCBUaGUgU0tVIHBlcnRhaW5pbmcgdG8gdGhlIHByb3Zpc2lvbmluZyByZXNv
dXJjZSBhcyBzcGVjaWZpZWQgaW4gdGhlIE9mZmVyLgoKDQoFBAcCAQYSBPcBAgUKDQoFBAcC
AQESBPcBBgkKDQoFBAcCAQMSBPcBDA4KZQoEBAcCAhIE+wECPxpXIE9wdGlvbmFsLiBUaGUg
Y3VzdG9tZXIgdG8gdHJhbnNmZXIgaGFzIGFuIGVudGl0bGVtZW50IHdpdGggdGhlIHBvcHVs
YXRlZAogbGVnYWN5IFNLVS4KCg0KBQQHAgIGEgT7AQIFCg0KBQQHAgIBEgT7AQYQCg0KBQQH
AgIDEgT7ARMVCg0KBQQHAgIIEgT7ARY+ChAKCAQHAgIInAgAEgT7ARc9CjgKAgQIEgb/AQCb
AgEaKiBTcGVjaWZpZXMgdHJhbnNmZXIgZWxpZ2liaWxpdHkgb2YgYSBTS1UuCgoLCgMECAES
BP8BCBsKKgoEBAgEABIGgQICkQIDGhogUmVhc29uIG9mIGluZWxpZ2liaWxpdHkuCgoNCgUE
CAQAARIEgQIHDQobCgYECAQAAgASBIMCBBsaCyBOb3QgdXNlZC4KCg8KBwQIBAACAAESBIMC
BBYKDwoHBAgEAAIAAhIEgwIZGgpLCgYECAQAAgESBIYCBB8aOyBSZXNlbGxlciBuZWVkcyB0
byBhY2NlcHQgVE9TIGJlZm9yZSB0cmFuc2ZlcnJpbmcgdGhlIFNLVS4KCg8KBwQIBAACAQES
BIYCBBoKDwoHBAgEAAIBAhIEhgIdHgo4CgYECAQAAgISBIkCBBkaKCBSZXNlbGxlciBub3Qg
ZWxpZ2libGUgdG8gc2VsbCB0aGUgU0tVLgoKDwoHBAgEAAICARIEiQIEFAoPCgcECAQAAgIC
EgSJAhcYCi8KBgQIBAACAxIEjAIEFhofIFNLVSBzdWJzY3JpcHRpb24gaXMgc3VzcGVuZGVk
CgoPCgcECAQAAgMBEgSMAgQRCg8KBwQIBAACAwISBIwCFBUKjAEKBgQIBAACBBIEkAIELxp8
IFRoZSByZXNlbGxlciBpcyBub3QgYXV0aG9yaXplZCB0byB0cmFuc2FjdCBvbiB0aGlzIFBy
b2R1Y3QuIFNlZQogaHR0cHM6Ly9zdXBwb3J0Lmdvb2dsZS5jb20vY2hhbm5lbHNlcnZpY2Vz
L2Fuc3dlci85NzU5MjY1CgoPCgcECAQAAgQBEgSQAgQqCg8KBwQIBAACBAISBJACLS4KQQoE
BAgCABIElAICFxozIFdoZXRoZXIgcmVzZWxsZXIgaXMgZWxpZ2libGUgdG8gdHJhbnNmZXIg
dGhlIFNLVS4KCg0KBQQIAgAFEgSUAgIGCg0KBQQIAgABEgSUAgcSCg0KBQQIAgADEgSUAhUW
ClYKBAQIAgESBJcCAhkaSCBMb2NhbGl6ZWQgZGVzY3JpcHRpb24gaWYgcmVzZWxsZXIgaXMg
bm90IGVsaWdpYmxlIHRvIHRyYW5zZmVyIHRoZSBTS1UuCgoNCgUECAIBBRIElwICCAoNCgUE
CAIBARIElwIJFAoNCgUECAIBAxIElwIXGAo3CgQECAICEgSaAgIiGikgU3BlY2lmaWVkIHRo
ZSByZWFzb24gZm9yIGluZWxpZ2liaWxpdHkuCgoNCgUECAICBhIEmgICCAoNCgUECAICARIE
mgIJHQoNCgUECAICAxIEmgIgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Entitlements::Entitlement ===
    # Fields for Entitlement
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: offer Type: 9 ()
    # Field: commitment_settings Type: 11 (.google.cloud.channel.v1.CommitmentSettings)
    # Field: provisioning_state Type: 14 (.google.cloud.channel.v1.Entitlement.ProvisioningState)
    # Field: provisioned_service Type: 11 (.google.cloud.channel.v1.ProvisionedService)
    # Field: suspension_reasons Type: 14 (.google.cloud.channel.v1.Entitlement.SuspensionReason)
    # Field: purchase_order_id Type: 9 ()
    # Field: trial_settings Type: 11 (.google.cloud.channel.v1.TrialSettings)
    # Field: association_info Type: 11 (.google.cloud.channel.v1.AssociationInfo)
    # Field: parameters Type: 11 (.google.cloud.channel.v1.Parameter)
    # Field: billing_account Type: 9 ()
    # Field: price_reference_id Type: 9 ()

# Enum: Entitlement::ProvisioningState
our $Entitlement_PROVISIONING_STATE_UNSPECIFIED = 0;
our $Entitlement_ACTIVE = 1;
our $Entitlement_SUSPENDED = 5;

# Enum: Entitlement::SuspensionReason
our $Entitlement_SUSPENSION_REASON_UNSPECIFIED = 0;
our $Entitlement_RESELLER_INITIATED = 1;
our $Entitlement_TRIAL_ENDED = 2;
our $Entitlement_RENEWAL_WITH_TYPE_CANCEL = 3;
our $Entitlement_PENDING_TOS_ACCEPTANCE = 4;
our $Entitlement_OTHER = 100;

# === Message: Google::Cloud::Channel::V1::Entitlements::Parameter ===
    # Fields for Parameter
    # Field: name Type: 9 ()
    # Field: value Type: 11 (.google.cloud.channel.v1.Value)
    # Field: editable Type: 8 ()

# === Message: Google::Cloud::Channel::V1::Entitlements::AssociationInfo ===
    # Fields for AssociationInfo
    # Field: base_entitlement Type: 9 ()

# === Message: Google::Cloud::Channel::V1::Entitlements::ProvisionedService ===
    # Fields for ProvisionedService
    # Field: provisioning_id Type: 9 ()
    # Field: product_id Type: 9 ()
    # Field: sku_id Type: 9 ()

# === Message: Google::Cloud::Channel::V1::Entitlements::CommitmentSettings ===
    # Fields for CommitmentSettings
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: renewal_settings Type: 11 (.google.cloud.channel.v1.RenewalSettings)

# === Message: Google::Cloud::Channel::V1::Entitlements::RenewalSettings ===
    # Fields for RenewalSettings
    # Field: enable_renewal Type: 8 ()
    # Field: resize_unit_count Type: 8 ()
    # Field: payment_plan Type: 14 (.google.cloud.channel.v1.PaymentPlan)
    # Field: payment_cycle Type: 11 (.google.cloud.channel.v1.Period)

# === Message: Google::Cloud::Channel::V1::Entitlements::TrialSettings ===
    # Fields for TrialSettings
    # Field: trial Type: 8 ()
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Channel::V1::Entitlements::TransferableSku ===
    # Fields for TransferableSku
    # Field: transfer_eligibility Type: 11 (.google.cloud.channel.v1.TransferEligibility)
    # Field: sku Type: 11 (.google.cloud.channel.v1.Sku)
    # Field: legacy_sku Type: 11 (.google.cloud.channel.v1.Sku)

# === Message: Google::Cloud::Channel::V1::Entitlements::TransferEligibility ===
    # Fields for TransferEligibility
    # Field: is_eligible Type: 8 ()
    # Field: description Type: 9 ()
    # Field: ineligibility_reason Type: 14 (.google.cloud.channel.v1.TransferEligibility.Reason)

# Enum: TransferEligibility::Reason
our $TransferEligibility_REASON_UNSPECIFIED = 0;
our $TransferEligibility_PENDING_TOS_ACCEPTANCE = 1;
our $TransferEligibility_SKU_NOT_ELIGIBLE = 2;
our $TransferEligibility_SKU_SUSPENDED = 3;
our $TransferEligibility_CHANNEL_PARTNER_NOT_AUTHORIZED_FOR_SKU = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Entitlements - Compiled Protocol Buffers messages for google/cloud/channel/v1/entitlements.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Entitlements;

    my $msg = Google::Cloud::Channel::V1::Entitlements::Entitlement->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        offer => $offer,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Entitlements::Entitlement->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/entitlements.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Entitlements::Entitlement

An entitlement is a representation of a customer's ability to use a service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of an entitlement in the form:
accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the entitlement is created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the entitlement is updated.

=item * C<< $msg->offer() >> / C<< $msg->offer($value) >>

Type: C<String>

Required. The offer resource name for which the entitlement is to be
created. Takes the form: accounts/{account_id}/offers/{offer_id}.

=item * C<< $msg->commitment_settings() >> / C<< $msg->commitment_settings($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::CommitmentSettings>)

Commitment settings for a commitment-based Offer.
Required for commitment based offers.

=item * C<< $msg->provisioning_state() >> / C<< $msg->provisioning_state($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::Entitlement::ProvisioningState>)

Output only. Current provisioning state of the entitlement.

=item * C<< $msg->provisioned_service() >> / C<< $msg->provisioned_service($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::ProvisionedService>)

Output only. Service provisioning details for the entitlement.

=item * C<< $msg->suspension_reasons() >> / C<< $msg->suspension_reasons($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::Entitlement::SuspensionReason>)

Output only. Enumerable of all current suspension reasons for an
entitlement.

=item * C<< $msg->purchase_order_id() >> / C<< $msg->purchase_order_id($value) >>

Type: C<String>

Optional. This purchase order (PO) information is for resellers to use for
their company tracking usage. If a purchaseOrderId value is given, it
appears in the API responses and shows up in the invoice. The property
accepts up to 80 plain text characters. This is only supported for Google
Workspace entitlements.

=item * C<< $msg->trial_settings() >> / C<< $msg->trial_settings($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::TrialSettings>)

Output only. Settings for trial offers.

=item * C<< $msg->association_info() >> / C<< $msg->association_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::AssociationInfo>)

Association information to other entitlements.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::Parameter>)

Extended entitlement parameters. When creating an entitlement, valid
parameter names and values are defined in the
[Offer.parameter_definitions][google.cloud.channel.v1.Offer.parameter_definitions].

For Google Workspace, the following Parameters may be accepted as input:

- max_units: The maximum assignable units for a flexible offer

OR

- num_units: The total commitment for commitment-based offers

The response may additionally include the following output-only Parameters:

- assigned_units: The number of licenses assigned to users.

For Google Cloud billing subaccounts, the following Parameter may be
accepted as input:

- display_name: The display name of the billing subaccount.

=item * C<< $msg->billing_account() >> / C<< $msg->billing_account($value) >>

Type: C<String>

Optional. The billing account resource name that is used to pay for this
entitlement.

=item * C<< $msg->price_reference_id() >> / C<< $msg->price_reference_id($value) >>

Type: C<String>

Optional. Price reference ID for the offer. Only for offers that require
additional price information. Used to guarantee that the pricing is
consistent between quoting the offer and placing the order.

=back

=head3 Enum: Entitlement::ProvisioningState

=over 4

=item * C<PROVISIONING_STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<SUSPENDED> => C<5>

=back

=head3 Enum: Entitlement::SuspensionReason

=over 4

=item * C<SUSPENSION_REASON_UNSPECIFIED> => C<0>

=item * C<RESELLER_INITIATED> => C<1>

=item * C<TRIAL_ENDED> => C<2>

=item * C<RENEWAL_WITH_TYPE_CANCEL> => C<3>

=item * C<PENDING_TOS_ACCEPTANCE> => C<4>

=item * C<OTHER> => C<100>

=back

=head2 Google::Cloud::Channel::V1::Entitlements::Parameter

Definition for extended entitlement parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the parameter.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::Value>)

Value of the parameter.

=item * C<< $msg->editable() >> / C<< $msg->editable($value) >>

Type: C<Bool>

Output only. Specifies whether this parameter is allowed to be changed. For
example, for a Google Workspace Business Starter entitlement in commitment
plan, num_units is editable when entitlement is active.

=back

=head2 Google::Cloud::Channel::V1::Entitlements::AssociationInfo

Association links that an entitlement has to other entitlements.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_entitlement() >> / C<< $msg->base_entitlement($value) >>

Type: C<String>

The name of the base entitlement, for which this entitlement is an add-on.

=back

=head2 Google::Cloud::Channel::V1::Entitlements::ProvisionedService

Service provisioned for an entitlement.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->provisioning_id() >> / C<< $msg->provisioning_id($value) >>

Type: C<String>

Output only. Provisioning ID of the entitlement. For Google Workspace, this
is the underlying Subscription ID. For Google Cloud, this is the Billing
Account ID of the billing subaccount.

=item * C<< $msg->product_id() >> / C<< $msg->product_id($value) >>

Type: C<String>

Output only. The product pertaining to the provisioning resource as
specified in the Offer.

=item * C<< $msg->sku_id() >> / C<< $msg->sku_id($value) >>

Type: C<String>

Output only. The SKU pertaining to the provisioning resource as specified
in the Offer.

=back

=head2 Google::Cloud::Channel::V1::Entitlements::CommitmentSettings

Commitment settings for commitment-based offers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Commitment start timestamp.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Commitment end timestamp.

=item * C<< $msg->renewal_settings() >> / C<< $msg->renewal_settings($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::RenewalSettings>)

Optional. Renewal settings applicable for a commitment-based Offer.

=back

=head2 Google::Cloud::Channel::V1::Entitlements::RenewalSettings

Renewal settings for renewable Offers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_renewal() >> / C<< $msg->enable_renewal($value) >>

Type: C<Bool>

If false, the plan will be completed at the end date.

=item * C<< $msg->resize_unit_count() >> / C<< $msg->resize_unit_count($value) >>

Type: C<Bool>

If true and enable_renewal = true, the unit (for example seats or licenses)
will be set to the number of active units at renewal time.

=item * C<< $msg->payment_plan() >> / C<< $msg->payment_plan($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::PaymentPlan>)

Describes how a reseller will be billed.

=item * C<< $msg->payment_cycle() >> / C<< $msg->payment_cycle($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Offers::Period>)

Describes how frequently the reseller will be billed, such as
once per month.

=back

=head2 Google::Cloud::Channel::V1::Entitlements::TrialSettings

Settings for trial offers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->trial() >> / C<< $msg->trial($value) >>

Type: C<Bool>

Determines if the entitlement is in a trial or not:

* `true` - The entitlement is in trial.
* `false` - The entitlement is not in trial.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Date when the trial ends. The value is in milliseconds
using the UNIX Epoch format. See an example [Epoch
converter](https://www.epochconverter.com).

=back

=head2 Google::Cloud::Channel::V1::Entitlements::TransferableSku

TransferableSku represents information a reseller needs to view existing
provisioned services for a customer that they do not own.
Read-only.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transfer_eligibility() >> / C<< $msg->transfer_eligibility($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Entitlements::TransferEligibility>)

Describes the transfer eligibility of a SKU.

=item * C<< $msg->sku() >> / C<< $msg->sku($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::Sku>)

The SKU pertaining to the provisioning resource as specified in the Offer.

=item * C<< $msg->legacy_sku() >> / C<< $msg->legacy_sku($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::Sku>)

Optional. The customer to transfer has an entitlement with the populated
legacy SKU.

=back

=head2 Google::Cloud::Channel::V1::Entitlements::TransferEligibility

Specifies transfer eligibility of a SKU.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->is_eligible() >> / C<< $msg->is_eligible($value) >>

Type: C<Bool>

Whether reseller is eligible to transfer the SKU.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Localized description if reseller is not eligible to transfer the SKU.

=item * C<< $msg->ineligibility_reason() >> / C<< $msg->ineligibility_reason($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::TransferEligibility::Reason>)

Specified the reason for ineligibility.

=back

=head3 Enum: TransferEligibility::Reason

=over 4

=item * C<REASON_UNSPECIFIED> => C<0>

=item * C<PENDING_TOS_ACCEPTANCE> => C<1>

=item * C<SKU_NOT_ELIGIBLE> => C<2>

=item * C<SKU_SUSPENDED> => C<3>

=item * C<CHANNEL_PARTNER_NOT_AUTHORIZED_FOR_SKU> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Entitlements::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
