package Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment;

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
    my $descriptor_b64 = <<'EOF';
CkZnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZ29sZGVuZ2F0ZV9kZXBsb3ltZW50
X2Vudmlyb25tZW50LnByb3RvEh5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8i9AkKH0dvbGRlbmdhdGVEZXBsb3ltZW50RW52aXJvbm1lbnQSFwoEbmFtZRgBIAEoCUID
4EEIUgRuYW1lEnMKCGNhdGVnb3J5GAIgASgOMlIuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFi
YXNlLnYxLkdvbGRlbmdhdGVEZXBsb3ltZW50RW52aXJvbm1lbnQuRGVwbG95bWVudENhdGVn
b3J5QgPgQQNSCGNhdGVnb3J5EiEKDGRpc3BsYXlfbmFtZRgDIAEoCVILZGlzcGxheU5hbWUS
OAoWZGVmYXVsdF9jcHVfY29yZV9jb3VudBgEIAEoBUID4EEDUhNkZWZhdWx0Q3B1Q29yZUNv
dW50EokBChBlbnZpcm9ubWVudF90eXBlGAUgASgOMlkuZ29vZ2xlLmNsb3VkLm9yYWNsZWRh
dGFiYXNlLnYxLkdvbGRlbmdhdGVEZXBsb3ltZW50RW52aXJvbm1lbnQuRGVwbG95bWVudEVu
dmlyb25tZW50VHlwZUID4EEDUg9lbnZpcm9ubWVudFR5cGUSNQoUYXV0b19zY2FsaW5nX2Vu
YWJsZWQYBiABKAhCA+BBA1ISYXV0b1NjYWxpbmdFbmFibGVkEjAKEm1heF9jcHVfY29yZV9j
b3VudBgHIAEoBUID4EEDUg9tYXhDcHVDb3JlQ291bnQSNwoWbWVtb3J5X2diX3Blcl9jcHVf
Y29yZRgIIAEoBUID4EEDUhJtZW1vcnlHYlBlckNwdUNvcmUSMAoSbWluX2NwdV9jb3JlX2Nv
dW50GAkgASgFQgPgQQNSD21pbkNwdUNvcmVDb3VudBJQCiNuZXR3b3JrX2JhbmR3aWR0aF9n
YnBzX3Blcl9jcHVfY29yZRgKIAEoBUID4EEDUh5uZXR3b3JrQmFuZHdpZHRoR2Jwc1BlckNw
dUNvcmUSTwojc3RvcmFnZV91c2FnZV9saW1pdF9nYl9wZXJfY3B1X2NvcmUYCyABKAVCA+BB
A1Idc3RvcmFnZVVzYWdlTGltaXRHYlBlckNwdUNvcmUidgoSRGVwbG95bWVudENhdGVnb3J5
EiMKH0RFUExPWU1FTlRfQ0FURUdPUllfVU5TUEVDSUZJRUQQABIdChlEQVRBX1JFUExJQ0FU
SU9OX0NBVEVHT1JZEAESHAoYREFUQV9UUkFOU0ZPUk1TX0NBVEVHT1JZEAIidAoZRGVwbG95
bWVudEVudmlyb25tZW50VHlwZRIrCidERVBMT1lNRU5UX0VOVklST05NRU5UX1RZUEVfVU5T
UEVDSUZJRUQQABIOCgpQUk9EVUNUSU9OEAESGgoWREVWRUxPUE1FTlRfT1JfVEVTVElORxAC
OvQB6kHwAQo9b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vR29sZGVuZ2F0ZURlcGxv
eW1lbnRFbnZpcm9ubWVudBJscHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2dvbGRlbmdhdGVEZXBsb3ltZW50RW52aXJvbm1lbnRzL3tnb2xkZW5nYXRlX2RlcGxv
eW1lbnRfZW52aXJvbm1lbnR9KiBnb2xkZW5nYXRlRGVwbG95bWVudEVudmlyb25tZW50czIf
Z29sZGVuZ2F0ZURlcGxveW1lbnRFbnZpcm9ubWVudCLSAQorTGlzdEdvbGRlbmdhdGVEZXBs
b3ltZW50RW52aXJvbm1lbnRzUmVxdWVzdBJdCgZwYXJlbnQYASABKAlCReBBAvpBPxI9b3Jh
Y2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vR29sZGVuZ2F0ZURlcGxveW1lbnRFbnZpcm9u
bWVudFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdl
X3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKNAgosTGlzdEdvbGRlbmdhdGVEZXBsb3lt
ZW50RW52aXJvbm1lbnRzUmVzcG9uc2USjQEKImdvbGRlbmdhdGVfZGVwbG95bWVudF9lbnZp
cm9ubWVudHMYASADKAsyPy5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuR29sZGVu
Z2F0ZURlcGxveW1lbnRFbnZpcm9ubWVudFIgZ29sZGVuZ2F0ZURlcGxveW1lbnRFbnZpcm9u
bWVudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiUKC3VucmVh
Y2hhYmxlGAMgAygJQgPgQQZSC3VucmVhY2hhYmxlQv4BCiJjb20uZ29vZ2xlLmNsb3VkLm9y
YWNsZWRhdGFiYXNlLnYxQiRHb2xkZW5nYXRlRGVwbG95bWVudEVudmlyb25tZW50UHJvdG9Q
AVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9vcmFjbGVkYXRhYmFzZS9hcGl2MS9vcmFjbGVkYXRh
YmFzZXBiO29yYWNsZWRhdGFiYXNlcGKqAh5Hb29nbGUuQ2xvdWQuT3JhY2xlRGF0YWJhc2Uu
VjHKAh5Hb29nbGVcQ2xvdWRcT3JhY2xlRGF0YWJhc2VcVjHqAiFHb29nbGU6OkNsb3VkOjpP
cmFjbGVEYXRhYmFzZTo6VjFK8ycKBxIFDgCQAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAOwoJ
CgIIJRIDFQA7CggKAQgSAxYAYQoJCgIICxIDFgBhCggKAQgSAxcAIgoJCgIIChIDFwAiCggK
AQgSAxgARQoJCgIICBIDGABFCggKAQgSAxkAOwoJCgIIARIDGQA7CggKAQgSAxoAOwoJCgII
KRIDGgA7CggKAQgSAxsAOgoJCgIILRIDGwA6CkgKAgQAEgQeAGwBGjwgRGV0YWlscyBvZiB0
aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50IEVudmlyb25tZW50IHJlc291cmNlLgoKCgoDBAAB
EgMeCCcKCwoDBAAHEgQfAiQECg0KBQQAB50IEgQfAiQECkoKBAQABAASBCcCMAMaPCBEZXBs
b3ltZW50IGNhdGVnb3J5IG9mIHRoZSBHb2xkZW5nYXRlIERlcGxveW1lbnQgcmVzb3VyY2Uu
CgoMCgUEAAQAARIDJwcZCisKBgQABAACABIDKQQoGhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2
YWx1ZS4KCg4KBwQABAACAAESAykEIwoOCgcEAAQAAgACEgMpJicKWQoGBAAEAAIBEgMsBCIa
SiBHb2xkZW5nYXRlIERlcGxveW1lbnQgRW52aXJvbm1lbnQgY2F0ZWdvcnkgaXMgREFUQV9S
RVBMSUNBVElPTl9DQVRFR09SWS4KCg4KBwQABAACAQESAywEHQoOCgcEAAQAAgECEgMsICEK
WAoGBAAEAAICEgMvBCEaSSBHb2xkZW5nYXRlIERlcGxveW1lbnQgRW52aXJvbm1lbnQgY2F0
ZWdvcnkgaXMgREFUQV9UUkFOU0ZPUk1TX0NBVEVHT1JZLgoKDgoHBAAEAAICARIDLwQcCg4K
BwQABAACAgISAy8fIApXCgQEAAQBEgQzAjwDGkkgVGhlIGVudmlyb25tZW50IHR5cGUgb2Yg
dGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudCBFbnZpcm9ubWVudCByZXNvdXJjZS4KCgwKBQQA
BAEBEgMzByAKKwoGBAAEAQIAEgM1BDAaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoK
DgoHBAAEAQIAARIDNQQrCg4KBwQABAECAAISAzUuLwpGCgYEAAQBAgESAzgEExo3IEdvbGRl
bmdhdGUgRGVwbG95bWVudCBFbnZpcm9ubWVudCB0eXBlIGlzIFBST0RVQ1RJT04uCgoOCgcE
AAQBAgEBEgM4BA4KDgoHBAAEAQIBAhIDOBESClIKBgQABAECAhIDOwQfGkMgR29sZGVuZ2F0
ZSBEZXBsb3ltZW50IEVudmlyb25tZW50IHR5cGUgaXMgREVWRUxPUE1FTlRfT1JfVEVTVElO
Ry4KCg4KBwQABAECAgESAzsEGgoOCgcEAAQBAgICEgM7HR4K1gEKBAQAAgASA0ECPRrIASBJ
ZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50IEVudmly
b25tZW50IHJlc291cmNlIHdpdGgKIHRoZSBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vZ29sZGVuZ2F0ZURlcGxveW1lbnRFbnZpcm9ubWVudHMv
e2dvbGRlbmdhdGVfZGVwbG95bWVudF9lbnZpcm9ubWVudH0KCgwKBQQAAgAFEgNBAggKDAoF
BAACAAESA0EJDQoMCgUEAAIAAxIDQRARCgwKBQQAAgAIEgNBEjwKDwoIBAACAAicCAASA0ET
OwpcCgQEAAIBEgNFAk4aTyBPdXRwdXQgb25seS4gVGhlIGNhdGVnb3J5IG9mIHRoZSBHb2xk
ZW5nYXRlIERlcGxveW1lbnQgRW52aXJvbm1lbnQKIHJlc291cmNlLgoKDAoFBAACAQYSA0UC
FAoMCgUEAAIBARIDRRUdCgwKBQQAAgEDEgNFICEKDAoFBAACAQgSA0UiTQoPCggEAAIBCJwI
ABIDRSNMClIKBAQAAgISA0gCGhpFIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIEdvbGRlbmdh
dGUgRGVwbG95bWVudCBFbnZpcm9ubWVudCByZXNvdXJjZS4KCgwKBQQAAgIFEgNIAggKDAoF
BAACAgESA0gJFQoMCgUEAAICAxIDSBgZCmoKBAQAAgMSA0wCTxpdIE91dHB1dCBvbmx5LiBU
aGUgZGVmYXVsdCBDUFUgY29yZSBjb3VudCBvZiB0aGUgR29sZGVuZ2F0ZSBEZXBsb3ltZW50
CiBFbnZpcm9ubWVudCByZXNvdXJjZS4KCgwKBQQAAgMFEgNMAgcKDAoFBAACAwESA0wIHgoM
CgUEAAIDAxIDTCEiCgwKBQQAAgMIEgNMI04KDwoIBAACAwicCAASA0wkTQplCgQEAAIEEgRQ
AlEyGlcgT3V0cHV0IG9ubHkuIFRoZSBlbnZpcm9ubWVudCB0eXBlIG9mIHRoZSBHb2xkZW5n
YXRlIERlcGxveW1lbnQgRW52aXJvbm1lbnQKIHJlc291cmNlLgoKDAoFBAACBAYSA1ACGwoM
CgUEAAIEARIDUBwsCgwKBQQAAgQDEgNQLzAKDAoFBAACBAgSA1EGMQoPCggEAAIECJwIABID
UQcwCnsKBAQAAgUSA1UCTBpuIE91dHB1dCBvbmx5LiBXaGV0aGVyIGF1dG8gc2NhbGluZyBp
cyBlbmFibGVkIGJ5IGRlZmF1bHQgZm9yIHRoZSBHb2xkZW5nYXRlCiBEZXBsb3ltZW50IEVu
dmlyb25tZW50IHJlc291cmNlLgoKDAoFBAACBQUSA1UCBgoMCgUEAAIFARIDVQcbCgwKBQQA
AgUDEgNVHh8KDAoFBAACBQgSA1UgSwoPCggEAAIFCJwIABIDVSFKCmYKBAQAAgYSA1kCSxpZ
IE91dHB1dCBvbmx5LiBUaGUgbWF4IENQVSBjb3JlIGNvdW50IG9mIHRoZSBHb2xkZW5nYXRl
IERlcGxveW1lbnQKIEVudmlyb25tZW50IHJlc291cmNlLgoKDAoFBAACBgUSA1kCBwoMCgUE
AAIGARIDWQgaCgwKBQQAAgYDEgNZHR4KDAoFBAACBggSA1kfSgoPCggEAAIGCJwIABIDWSBJ
Cm4KBAQAAgcSA10CTxphIE91dHB1dCBvbmx5LiBUaGUgbWVtb3J5IHBlciBDUFUgY29yZSBp
biBHQnMgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudAogRW52aXJvbm1lbnQgcmVzb3Vy
Y2UuCgoMCgUEAAIHBRIDXQIHCgwKBQQAAgcBEgNdCB4KDAoFBAACBwMSA10hIgoMCgUEAAIH
CBIDXSNOCg8KCAQAAgcInAgAEgNdJE0KZgoEBAACCBIDYQJLGlkgT3V0cHV0IG9ubHkuIFRo
ZSBtaW4gQ1BVIGNvcmUgY291bnQgb2YgdGhlIEdvbGRlbmdhdGUgRGVwbG95bWVudAogRW52
aXJvbm1lbnQgcmVzb3VyY2UuCgoMCgUEAAIIBRIDYQIHCgwKBQQAAggBEgNhCBoKDAoFBAAC
CAMSA2EdHgoMCgUEAAIICBIDYR9KCg8KCAQAAggInAgAEgNhIEkKewoEBAACCRIEZQJmMhpt
IE91dHB1dCBvbmx5LiBUaGUgbmV0d29yayBiYW5kd2lkdGggcGVyIENQVSBjb3JlIGluIEdi
cHMgb2YgdGhlIEdvbGRlbmdhdGUKIERlcGxveW1lbnQgRW52aXJvbm1lbnQgcmVzb3VyY2Uu
CgoMCgUEAAIJBRIDZQIHCgwKBQQAAgkBEgNlCCsKDAoFBAACCQMSA2UuMAoMCgUEAAIJCBID
ZgYxCg8KCAQAAgkInAgAEgNmBzAKfAoEBAACChIEagJrMhpuIE91dHB1dCBvbmx5LiBUaGUg
c3RvcmFnZSB1c2FnZSBsaW1pdCBwZXIgQ1BVIGNvcmUgaW4gR0JzIG9mIHRoZSBHb2xkZW5n
YXRlCiBEZXBsb3ltZW50IEVudmlyb25tZW50IHJlc291cmNlLgoKDAoFBAACCgUSA2oCBwoM
CgUEAAIKARIDaggrCgwKBQQAAgoDEgNqLjAKDAoFBAACCggSA2sGMQoPCggEAAIKCJwIABID
awcwCkQKAgQBEgVvAIEBARo3IE1lc3NhZ2UgZm9yIGxpc3RpbmcgR29sZGVuZ2F0ZURlcGxv
eW1lbnRFbnZpcm9ubWVudHMuCgoKCgMEAQESA28IMwqYAQoEBAECABIEcwJ4BBqJASBSZXF1
aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YKIEdvbGRl
bmdhdGVEZXBsb3ltZW50RW52aXJvbm1lbnRzLiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQBAgAFEgNzAggKDAoFBAECAAESA3MJDwoM
CgUEAQIAAxIDcxITCg0KBQQBAgAIEgRzFHgDCg8KCAQBAgAInAgAEgN0BCoKDwoHBAECAAif
CBIEdQR3BQrNAQoEBAECARIDfQI/Gr8BIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIg
b2YgaXRlbXMgdG8gcmV0dXJuLgogSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgNTAgZGVwbG95
bWVudCBlbnZpcm9ubWVudHMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVl
IGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoK
DAoFBAECAQUSA30CBwoMCgUEAQIBARIDfQgRCgwKBQQBAgEDEgN9FBUKDAoFBAECAQgSA30W
PgoPCggEAQIBCJwIABIDfRc9ClkKBAQBAgISBIABAkEaSyBPcHRpb25hbC4gQSB0b2tlbiBp
ZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4u
CgoNCgUEAQICBRIEgAECCAoNCgUEAQICARIEgAEJEwoNCgUEAQICAxIEgAEWFwoNCgUEAQIC
CBIEgAEYQAoQCggEAQICCJwIABIEgAEZPwpQCgIEAhIGhAEAkAEBGkIgTWVzc2FnZSBmb3Ig
cmVzcG9uc2UgdG8gbGlzdGluZyBHb2xkZW5nYXRlRGVwbG95bWVudEVudmlyb25tZW50cwoK
CwoDBAIBEgSEAQg0Cj0KBAQCAgASBoYBAocBCBotIFRoZSBsaXN0IG9mIEdvbGRlbmdhdGVE
ZXBsb3ltZW50RW52aXJvbm1lbnQKCg0KBQQCAgAEEgSGAQIKCg0KBQQCAgAGEgSGAQsqCg0K
BQQCAgABEgSGAStNCg0KBQQCAgADEgSHAQYHCocBCgQEAgIBEgSLAQIdGnkgQSB0b2tlbiBp
ZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4u
CiBJZiB0aGlzIGZpZWxkIGlzIGVtcHR5LCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdl
cy4KCg0KBQQCAgEFEgSLAQIICg0KBQQCAgEBEgSLAQkYCg0KBQQCAgEDEgSLARscCkYKBAQC
AgISBo4BAo8BNRo2IFVub3JkZXJlZCBsaXN0LiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3Qg
YmUgcmVhY2hlZC4KCg0KBQQCAgIEEgSOAQIKCg0KBQQCAgIFEgSOAQsRCg0KBQQCAgIBEgSO
ARIdCg0KBQQCAgIDEgSOASAhCg0KBQQCAgIIEgSPAQY0ChAKCAQCAgIInAgAEgSPAQczYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment ===
    # Fields for GoldengateDeploymentEnvironment
    # Field: name Type: 9 ()
    # Field: category Type: 14 (.google.cloud.oracledatabase.v1.GoldengateDeploymentEnvironment.DeploymentCategory)
    # Field: display_name Type: 9 ()
    # Field: default_cpu_core_count Type: 5 ()
    # Field: environment_type Type: 14 (.google.cloud.oracledatabase.v1.GoldengateDeploymentEnvironment.DeploymentEnvironmentType)
    # Field: auto_scaling_enabled Type: 8 ()
    # Field: max_cpu_core_count Type: 5 ()
    # Field: memory_gb_per_cpu_core Type: 5 ()
    # Field: min_cpu_core_count Type: 5 ()
    # Field: network_bandwidth_gbps_per_cpu_core Type: 5 ()
    # Field: storage_usage_limit_gb_per_cpu_core Type: 5 ()

# Enum: GoldengateDeploymentEnvironment::DeploymentCategory
our $GoldengateDeploymentEnvironment_DEPLOYMENT_CATEGORY_UNSPECIFIED = 0;
our $GoldengateDeploymentEnvironment_DATA_REPLICATION_CATEGORY = 1;
our $GoldengateDeploymentEnvironment_DATA_TRANSFORMS_CATEGORY = 2;

# Enum: GoldengateDeploymentEnvironment::DeploymentEnvironmentType
our $GoldengateDeploymentEnvironment_DEPLOYMENT_ENVIRONMENT_TYPE_UNSPECIFIED = 0;
our $GoldengateDeploymentEnvironment_PRODUCTION = 1;
our $GoldengateDeploymentEnvironment_DEVELOPMENT_OR_TESTING = 2;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsRequest ===
    # Fields for ListGoldengateDeploymentEnvironmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsResponse ===
    # Fields for ListGoldengateDeploymentEnvironmentsResponse
    # Field: goldengate_deployment_environments Type: 11 (.google.cloud.oracledatabase.v1.GoldengateDeploymentEnvironment)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/goldengate_deployment_environment.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment;

    my $msg = Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment->new({
        name => $name,
        category => $category,
        display_name => $display_name,
        default_cpu_core_count => $default_cpu_core_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/goldengate_deployment_environment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment

Details of the Goldengate Deployment Environment resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Goldengate Deployment Environment resource with
the format:
projects/{project}/locations/{location}/goldengateDeploymentEnvironments/{goldengate_deployment_environment}

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::DeploymentCategory>)

Output only. The category of the Goldengate Deployment Environment
resource.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the Goldengate Deployment Environment resource.

=item * C<< $msg->default_cpu_core_count() >> / C<< $msg->default_cpu_core_count($value) >>

Type: C<Int32>

Output only. The default CPU core count of the Goldengate Deployment
Environment resource.

=item * C<< $msg->environment_type() >> / C<< $msg->environment_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::DeploymentEnvironmentType>)

Output only. The environment type of the Goldengate Deployment Environment
resource.

=item * C<< $msg->auto_scaling_enabled() >> / C<< $msg->auto_scaling_enabled($value) >>

Type: C<Bool>

Output only. Whether auto scaling is enabled by default for the Goldengate
Deployment Environment resource.

=item * C<< $msg->max_cpu_core_count() >> / C<< $msg->max_cpu_core_count($value) >>

Type: C<Int32>

Output only. The max CPU core count of the Goldengate Deployment
Environment resource.

=item * C<< $msg->memory_gb_per_cpu_core() >> / C<< $msg->memory_gb_per_cpu_core($value) >>

Type: C<Int32>

Output only. The memory per CPU core in GBs of the Goldengate Deployment
Environment resource.

=item * C<< $msg->min_cpu_core_count() >> / C<< $msg->min_cpu_core_count($value) >>

Type: C<Int32>

Output only. The min CPU core count of the Goldengate Deployment
Environment resource.

=item * C<< $msg->network_bandwidth_gbps_per_cpu_core() >> / C<< $msg->network_bandwidth_gbps_per_cpu_core($value) >>

Type: C<Int32>

Output only. The network bandwidth per CPU core in Gbps of the Goldengate
Deployment Environment resource.

=item * C<< $msg->storage_usage_limit_gb_per_cpu_core() >> / C<< $msg->storage_usage_limit_gb_per_cpu_core($value) >>

Type: C<Int32>

Output only. The storage usage limit per CPU core in GBs of the Goldengate
Deployment Environment resource.

=back

=head3 Enum: GoldengateDeploymentEnvironment::DeploymentCategory

=over 4

=item * C<DEPLOYMENT_CATEGORY_UNSPECIFIED> => C<0>

=item * C<DATA_REPLICATION_CATEGORY> => C<1>

=item * C<DATA_TRANSFORMS_CATEGORY> => C<2>

=back

=head3 Enum: GoldengateDeploymentEnvironment::DeploymentEnvironmentType

=over 4

=item * C<DEPLOYMENT_ENVIRONMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<PRODUCTION> => C<1>

=item * C<DEVELOPMENT_OR_TESTING> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsRequest

Message for listing GoldengateDeploymentEnvironments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of
GoldengateDeploymentEnvironments. Format:
projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, at most 50 deployment environments will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::ListGoldengateDeploymentEnvironmentsResponse

Message for response to listing GoldengateDeploymentEnvironments

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->goldengate_deployment_environments() >> / C<< $msg->goldengate_deployment_environments($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::GoldengateDeploymentEnvironment>)

The list of GoldengateDeploymentEnvironment

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.
If this field is empty, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
