package Google::Cloud::Workloadidentity::V1::Service;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvd29ya2xvYWRpZGVudGl0eS92MS9zZXJ2aWNlLnByb3RvEiBnb29n
bGUuY2xvdWQud29ya2xvYWRpZGVudGl0eS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9sb25ncnVubmlu
Zy9vcGVyYXRpb25zLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIuAF
CgxTZXJ2aWNlQWdlbnQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEicKCWNvbnRhaW5lchgF
IAEoCUIJ4EEB+kEDCgEqUgljb250YWluZXISLgoQc2VydmljZV9wcm9kdWNlchgGIAEoCUID
4EEBUg9zZXJ2aWNlUHJvZHVjZXISIQoJcHJpbmNpcGFsGAcgASgJQgPgQQFSCXByaW5jaXBh
bBIXCgRyb2xlGAkgASgJQgPgQQFSBHJvbGUSTwoFc3RhdGUYCiABKA4yNC5nb29nbGUuY2xv
dWQud29ya2xvYWRpZGVudGl0eS52MS5TZXJ2aWNlQWdlbnQuU3RhdGVCA+BBA1IFc3RhdGUi
NgoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZBQ1RJVkUQARIKCgZGQUlMRUQQ
AjqYA+pBlAMKLHdvcmtsb2FkaWRlbnRpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmljZUFnZW50
Emlwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZVByb2R1
Y2Vycy97c2VydmljZV9wcm9kdWNlcn0vc2VydmljZUFnZW50cy97c2VydmljZV9hZ2VudH0S
Z2ZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZVByb2R1Y2Vy
cy97c2VydmljZV9wcm9kdWNlcn0vc2VydmljZUFnZW50cy97c2VydmljZV9hZ2VudH0Sc29y
Z2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2Vydmlj
ZVByb2R1Y2Vycy97c2VydmljZV9wcm9kdWNlcn0vc2VydmljZUFnZW50cy97c2VydmljZV9h
Z2VudH0qDXNlcnZpY2VBZ2VudHMyDHNlcnZpY2VBZ2VudCJvChxHZW5lcmF0ZVNlcnZpY2VB
Z2VudHNSZXF1ZXN0Ek8KBnBhcmVudBgBIAEoCUI34EEC+kExCi93b3JrbG9hZGlkZW50aXR5
Lmdvb2dsZWFwaXMuY29tL1NlcnZpY2VQcm9kdWNlclIGcGFyZW50InYKHUdlbmVyYXRlU2Vy
dmljZUFnZW50c1Jlc3BvbnNlElUKDnNlcnZpY2VfYWdlbnRzGAEgAygLMi4uZ29vZ2xlLmNs
b3VkLndvcmtsb2FkaWRlbnRpdHkudjEuU2VydmljZUFnZW50Ug1zZXJ2aWNlQWdlbnRzItUC
ChFPcGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGltZRIbCgZ0YXJnZXQYAyABKAlC
A+BBA1IGdGFyZ2V0EhcKBHZlcmIYBCABKAlCA+BBA1IEdmVyYhIqCg5zdGF0dXNfbWVzc2Fn
ZRgFIAEoCUID4EEDUg1zdGF0dXNNZXNzYWdlEjoKFnJlcXVlc3RlZF9jYW5jZWxsYXRpb24Y
BiABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9uGAcgASgJ
QgPgQQNSCmFwaVZlcnNpb24yowQKEFdvcmtsb2FkSWRlbnRpdHkSuQMKFUdlbmVyYXRlU2Vy
dmljZUFnZW50cxI+Lmdvb2dsZS5jbG91ZC53b3JrbG9hZGlkZW50aXR5LnYxLkdlbmVyYXRl
U2VydmljZUFnZW50c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIsAC
gtPkkwL7ASJML3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZXJ2aWNlUHJv
ZHVjZXJzLyp9OmdlbmVyYXRlU2VydmljZUFnZW50czoBKlpQIksvdjEve3BhcmVudD1mb2xk
ZXJzLyovbG9jYXRpb25zLyovc2VydmljZVByb2R1Y2Vycy8qfTpnZW5lcmF0ZVNlcnZpY2VB
Z2VudHM6ASpaViJRL3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL3Nl
cnZpY2VQcm9kdWNlcnMvKn06Z2VuZXJhdGVTZXJ2aWNlQWdlbnRzOgEq2kEGcGFyZW50ykEy
Ch1HZW5lcmF0ZVNlcnZpY2VBZ2VudHNSZXNwb25zZRIRT3BlcmF0aW9uTWV0YWRhdGEaU8pB
H3dvcmtsb2FkaWRlbnRpdHkuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQpgECiRjb20uZ29vZ2xlLmNsb3VkLndvcmts
b2FkaWRlbnRpdHkudjFCDFNlcnZpY2VQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL3dv
cmtsb2FkaWRlbnRpdHkvYXBpdjEvd29ya2xvYWRpZGVudGl0eXBiO3dvcmtsb2FkaWRlbnRp
dHlwYqoCIEdvb2dsZS5DbG91ZC5Xb3JrbG9hZElkZW50aXR5LlYxygIgR29vZ2xlXENsb3Vk
XFdvcmtsb2FkSWRlbnRpdHlcVjHqAiNHb29nbGU6OkNsb3VkOjpXb3JrbG9hZElkZW50aXR5
OjpWMepBoAIKL3dvcmtsb2FkaWRlbnRpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmljZVByb2R1
Y2VyEktwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZVBy
b2R1Y2Vycy97c2VydmljZV9wcm9kdWNlcn0SSWZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vc2VydmljZVByb2R1Y2Vycy97c2VydmljZV9wcm9kdWNlcn0SVW9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZVBy
b2R1Y2Vycy97c2VydmljZV9wcm9kdWNlcn1KuicKBxIFDgCxAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAtCgkKAgMFEgMXACkKCAoBCBIDGQA9CgkK
AgglEgMZAD0KCAoBCBIDGgBnCgkKAggLEgMaAGcKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoB
CBIDHAAtCgkKAggIEgMcAC0KCAoBCBIDHQA9CgkKAggBEgMdAD0KCAoBCBIDHgA9CgkKAggp
EgMeAD0KCAoBCBIDHwA8CgkKAggtEgMfADwKCQoBCBIEIAAlAgoMCgQInQgAEgQgACUCCjcK
AgYAEgQoAEMBGisgU2VydmljZSBkZXNjcmliaW5nIGhhbmRsZXJzIGZvciByZXNvdXJjZXMK
CgoKAwYAARIDKAgYCgoKAwYAAxIDKQJHCgwKBQYAA5kIEgMpAkcKCwoDBgADEgQqAis3Cg0K
BQYAA5oIEgQqAis3CmAKBAYAAgASBC8CQgMaUiBDcmVhdGVzIGFsbCBzZXJ2aWNlIGFnZW50
cyBmb3IgYSBnaXZlbiByZXNvdXJjZSwgbG9jYXRpb24gYW5kIHNlcnZpY2UKIHByb2R1Y2Vy
LgoKDAoFBgACAAESAy8GGwoMCgUGAAIAAhIDLxw4CgwKBQYAAgADEgMwDysKDQoFBgACAAQS
BDEEPAYKEQoJBgACAASwyrwiEgQxBDwGCgwKBQYAAgAEEgM9BDQKDwoIBgACAASbCAASAz0E
NAoNCgUGAAIABBIEPgRBBgoPCgcGAAIABJkIEgQ+BEEGCjQKAgQAEgRGAHgBGiggTWVzc2Fn
ZSBkZXNjcmliaW5nIFNlcnZpY2VBZ2VudCBvYmplY3QKCgoKAwQAARIDRggUCgsKAwQABxIE
RwJOBAoNCgUEAAedCBIERwJOBAovCgQEAAQAEgRRAlsDGiEgRW51bSBmb3Igc2VydmljZSBh
Z2VudCBgc3RhdGVgLgoKDAoFBAAEAAESA1EHDApcCgYEAAQAAgASA1QEGhpNIERlZmF1bHQg
c2VydmljZSBhZ2VudCBgc3RhdGVgLiBUaGlzIHZhbHVlIGlzIHVzZWQgaWYgdGhlCiBzdGF0
ZSBpcyBvbWl0dGVkLgoKDgoHBAAEAAIAARIDVAQVCg4KBwQABAACAAISA1QYGQpTCgYEAAQA
AgESA1cEDxpEIEluZGljYXRlcyB0aGF0IHRoZSBzZXJ2aWNlIGFnZW50IGhhcyBiZWVuIGNy
ZWF0ZWQgYW5kIGNhbiBiZSB1c2VkLgoKDgoHBAAEAAIBARIDVwQKCg4KBwQABAACAQISA1cN
DgpCCgYEAAQAAgISA1oEDxozIEluZGljYXRlcyB0aGF0IHRoZSBzZXJ2aWNlIGFnZW50IHdh
cyBub3QgY3JlYXRlZC4KCg4KBwQABAACAgESA1oECgoOCgcEAAQAAgICEgNaDQ4KQQoEBAAC
ABIDXgI9GjQgSWRlbnRpZmllci4gVGhlIG5hbWUgb2YgdGhlIHNlcnZpY2UgYWdlbnQgcmVz
b3VyY2UKCgwKBQQAAgAFEgNeAggKDAoFBAACAAESA14JDQoMCgUEAAIAAxIDXhARCgwKBQQA
AgAIEgNeEjwKDwoIBAACAAicCAASA14TOwqgAQoEBAACARIEZQJoBBqRASBPcHRpb25hbC4g
TmFtZSBvZiB0aGUgY29udGFpbmVyIHRoYXQgdGhlIHNlcnZpY2UgYWdlbnQgaXMgYXNzb2Np
YXRlZCB3aXRoLgogRm9yIGV4YW1wbGU6CiAqIHByb2plY3RzLzEyMzQKICogZm9sZGVycy8x
MjM0CiAqIG9yZ2FuaXphdGlvbnMvMjM0NAoKDAoFBAACAQUSA2UCCAoMCgUEAAIBARIDZQkS
CgwKBQQAAgEDEgNlFRYKDQoFBAACAQgSBGUXaAMKDwoIBAACAQicCAASA2YEKgoOCgcEAAIB
CJ8IEgNnBDMKYAoEBAACAhIDbAJHGlMgT3B0aW9uYWwuIFRoZSBzZXJ2aWNlIHRoZSBhZ2Vu
dCBiZWxvbmdzIHRvLgogRm9yIGV4YW1wbGUsIGJpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29tCgoM
CgUEAAICBRIDbAIICgwKBQQAAgIBEgNsCRkKDAoFBAACAgMSA2wcHQoMCgUEAAICCBIDbB5G
Cg8KCAQAAgIInAgAEgNsH0UKmgEKBAQAAgMSA3ACQBqMASBPcHRpb25hbC4gVGhlIHByaW5j
aXBhbCBpZGVudGlmaWVyIGZvciB0aGUgc2VydmljZSBhZ2VudC4gVGhpcyBpZGVudGlmaWVy
CiBpcyB1c2VkIGluIGFsbG93IHBvbGljaWVzIHRvIGdyYW50IGFjY2VzcyB0byB0aGUgc2Vy
dmljZSBhZ2VudC4KCgwKBQQAAgMFEgNwAggKDAoFBAACAwESA3AJEgoMCgUEAAIDAxIDcBUW
CgwKBQQAAgMIEgNwFz8KDwoIBAACAwicCAASA3AYPgqWAQoEBAACBBIDdAI7GogBIE9wdGlv
bmFsLiBUaGUgcm9sZSB0aGF0IHNob3VsZCBiZSBncmFudGVkIHRvIHNlcnZpY2UgYWdlbnQg
b24gY29uc3VtZXIKIHByb2plY3QsIGlmIGFueS4gRm9yIGV4YW1wbGUsICJyb2xlcy9haXBs
YXRmb3JtLnNlcnZpY2VBZ2VudCIuCgoMCgUEAAIEBRIDdAIICgwKBQQAAgQBEgN0CQ0KDAoF
BAACBAMSA3QQEQoMCgUEAAIECBIDdBI6Cg8KCAQAAgQInAgAEgN0EzkKMAoEBAACBRIDdwI/
GiMgT3V0cHV0IG9ubHkuIFNlcnZpY2UgYWdlbnQgc3RhdGUuCgoMCgUEAAIFBhIDdwIHCgwK
BQQAAgUBEgN3CA0KDAoFBAACBQMSA3cQEgoMCgUEAAIFCBIDdxM+Cg8KCAQAAgUInAgAEgN3
FD0KZwoCBAESBXwAiwEBGlogTWVzc2FnZSBmb3IgY3JlYXRpbmcgYWxsIFNlcnZpY2VBZ2Vu
dHMgZm9yIGEgU2VydmljZVByb2R1Y2VyIGluIGEgcHJvamVjdCBhbmQKIGxvY2F0aW9uLgoK
CgoDBAEBEgN8CCQK2AIKBAQBAgASBoUBAooBBBrHAiBSZXF1aXJlZC4gVGhlIHBhcmVudCBy
ZXNvdXJjZS4gVGhlIGBsb2NhdGlvbmAgZm9yIHRoZSBwYXJlbnQgcmVzb3VyY2UgbXVzdAog
YmUgYGdsb2JhbGAuCgogRXhhbXBsZXM6CgogLSBwcm9qZWN0cy8xMjM0L2xvY2F0aW9ucy9n
bG9iYWwvc2VydmljZVByb2R1Y2Vycy9iaWdxdWVyeS5nb29nbGVhcGlzLmNvbQogLSBmb2xk
ZXJzLzIzNDQvbG9jYXRpb25zL2dsb2JhbC9zZXJ2aWNlUHJvZHVjZXJzL3ZlcnRleGFpLmdv
b2dsZWFwaXMuY29tCiAtIG9yZ2FuaXphdGlvbnMvMzM0NC9sb2NhdGlvbnMvZ2xvYmFsL3Nl
cnZpY2VQcm9kdWNlcnMvaWFtLmdvb2dsZWFwaXMuY29tCgoNCgUEAQIABRIEhQECCAoNCgUE
AQIAARIEhQEJDwoNCgUEAQIAAxIEhQESEwoPCgUEAQIACBIGhQEUigEDChAKCAQBAgAInAgA
EgSGAQQqChEKBwQBAgAInwgSBocBBIkBBQpoCgIEAhIGjwEAkgEBGlogTWVzc2FnZSBmb3Ig
Y3JlYXRpbmcgYWxsIFNlcnZpY2VBZ2VudHMgZm9yIGEgU2VydmljZVByb2R1Y2VyIGluIGEg
cHJvamVjdCBhbmQKIGxvY2F0aW9uLgoKCwoDBAIBEgSPAQglCioKBAQCAgASBJEBAisaHCBU
aGUgbGlzdCBvZiBzZXJ2aWNlIGFnZW50cwoKDQoFBAICAAQSBJEBAgoKDQoFBAICAAYSBJEB
CxcKDQoFBAICAAESBJEBGCYKDQoFBAICAAMSBJEBKSoKRgoCBAMSBpUBALEBARo4IFJlcHJl
c2VudHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgoKCwoD
BAMBEgSVAQgZCkIKBAQDAgASBpcBApgBMhoyIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUg
b3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDQoFBAMCAAYSBJcBAhsKDQoFBAMCAAESBJcBHCcK
DQoFBAMCAAMSBJcBKisKDQoFBAMCAAgSBJgBBjEKEAoIBAMCAAicCAASBJgBBzAKRwoEBAMC
ARIGmwECnAEyGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNo
ZWQgcnVubmluZy4KCg0KBQQDAgEGEgSbAQIbCg0KBQQDAgEBEgSbARwkCg0KBQQDAgEDEgSb
AScoCg0KBQQDAgEIEgScAQYxChAKCAQDAgEInAgAEgScAQcwCloKBAQDAgISBJ8BAkAaTCBP
dXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdl
dCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAMCAgUSBJ8BAggKDQoFBAMCAgESBJ8BCQ8KDQoF
BAMCAgMSBJ8BEhMKDQoFBAMCAggSBJ8BFD8KEAoIBAMCAgicCAASBJ8BFT4KSAoEBAMCAxIE
ogECPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBv
cGVyYXRpb24uCgoNCgUEAwIDBRIEogECCAoNCgUEAwIDARIEogEJDQoNCgUEAwIDAxIEogEQ
EQoNCgUEAwIDCBIEogESPQoQCggEAwIDCJwIABIEogETPApMCgQEAwIEEgSlAQJIGj4gT3V0
cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBh
bnkuCgoNCgUEAwIEBRIEpQECCAoNCgUEAwIEARIEpQEJFwoNCgUEAwIEAxIEpQEaGwoNCgUE
AwIECBIEpQEcRwoQCggEAwIECJwIABIEpQEdRgrTAgoEBAMCBRIErQECThrEAiBPdXRwdXQg
b25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2Vs
bGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBiZWVuIGNh
bmNlbGxlZCBzdWNjZXNzZnVsbHkKIGhhdmUKIFtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uLmVycm9yXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXQogdmFsdWUg
d2l0aCBhIFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2Rl
XSBvZiBgMWAsCiBjb3JyZXNwb25kaW5nIHRvIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUEAwIF
BRIErQECBgoNCgUEAwIFARIErQEHHQoNCgUEAwIFAxIErQEgIQoNCgUEAwIFCBIErQEiTQoQ
CggEAwIFCJwIABIErQEjTApFCgQEAwIGEgSwAQJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJz
aW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQDAgYFEgSwAQIICg0KBQQD
AgYBEgSwAQkUCg0KBQQDAgYDEgSwARcYCg0KBQQDAgYIEgSwARlEChAKCAQDAgYInAgAEgSw
ARpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Workloadidentity::V1::Service::ServiceAgent ===
    # Fields for ServiceAgent
    # Field: name Type: 9 ()
    # Field: container Type: 9 ()
    # Field: service_producer Type: 9 ()
    # Field: principal Type: 9 ()
    # Field: role Type: 9 ()
    # Field: state Type: 14 (.google.cloud.workloadidentity.v1.ServiceAgent.State)

# Enum: ServiceAgent::State
our $ServiceAgent_STATE_UNSPECIFIED = 0;
our $ServiceAgent_ACTIVE = 1;
our $ServiceAgent_FAILED = 2;

# === Message: Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsRequest ===
    # Fields for GenerateServiceAgentsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsResponse ===
    # Fields for GenerateServiceAgentsResponse
    # Field: service_agents Type: 11 (.google.cloud.workloadidentity.v1.ServiceAgent)

# === Message: Google::Cloud::Workloadidentity::V1::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Workloadidentity::V1::Service::WorkloadIdentityClient ===
package Google::Cloud::Workloadidentity::V1::Service::WorkloadIdentityClient;

=pod

=head2 Service Client: Google::Cloud::Workloadidentity::V1::Service::WorkloadIdentityClient

Client stub representing the remote C<WorkloadIdentity> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<workloadidentity.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'workloadidentity.googleapis.com:443' );

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

sub generate_service_agents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workloadidentity.v1.WorkloadIdentity',
        method         => 'GenerateServiceAgents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Workloadidentity::V1::Service - Compiled Protocol Buffers messages for google/cloud/workloadidentity/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Workloadidentity::V1::Service;

    my $msg = Google::Cloud::Workloadidentity::V1::Service::ServiceAgent->new({
        name => $name,
        container => $container,
        service_producer => $service_producer,
        principal => $principal,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Workloadidentity::V1::Service::ServiceAgent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/workloadidentity/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Workloadidentity::V1::Service::ServiceAgent

Message describing ServiceAgent object

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the service agent resource

=item * C<< $msg->container() >> / C<< $msg->container($value) >>

Type: C<String>

Optional. Name of the container that the service agent is associated with.
For example:
* projects/1234
* folders/1234
* organizations/2344

=item * C<< $msg->service_producer() >> / C<< $msg->service_producer($value) >>

Type: C<String>

Optional. The service the agent belongs to.
For example, bigquery.googleapis.com

=item * C<< $msg->principal() >> / C<< $msg->principal($value) >>

Type: C<String>

Optional. The principal identifier for the service agent. This identifier
is used in allow policies to grant access to the service agent.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Optional. The role that should be granted to service agent on consumer
project, if any. For example, "roles/aiplatform.serviceAgent".

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Workloadidentity::V1::ServiceAgent::State>)

Output only. Service agent state.

=back

=head3 Enum: ServiceAgent::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<FAILED> => C<2>

=back

=head2 Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsRequest

Message for creating all ServiceAgents for a ServiceProducer in a project and
location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource. The `location` for the parent resource must
be `global`.

Examples:

- projects/1234/locations/global/serviceProducers/bigquery.googleapis.com
- folders/2344/locations/global/serviceProducers/vertexai.googleapis.com
- organizations/3344/locations/global/serviceProducers/iam.googleapis.com

=back

=head2 Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsResponse

Message for creating all ServiceAgents for a ServiceProducer in a project and
location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_agents() >> / C<< $msg->service_agents($value) >>

Type: C<Message> (L<Google::Cloud::Workloadidentity::V1::Service::ServiceAgent>)

The list of service agents

=back

=head2 Google::Cloud::Workloadidentity::V1::Service::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of `1`,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Workloadidentity::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
