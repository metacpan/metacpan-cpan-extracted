package Google::Cloud::Chronicle::V1::ReferenceList;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL3JlZmVyZW5jZV9saXN0LnByb3RvEhlnb29n
bGUuY2xvdWQuY2hyb25pY2xlLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdn
b29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21h
c2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8icQoJU2NvcGVJbmZv
EmQKFHJlZmVyZW5jZV9saXN0X3Njb3BlGAIgASgLMi0uZ29vZ2xlLmNsb3VkLmNocm9uaWNs
ZS52MS5SZWZlcmVuY2VMaXN0U2NvcGVCA+BBAlIScmVmZXJlbmNlTGlzdFNjb3BlIjoKElJl
ZmVyZW5jZUxpc3RTY29wZRIkCgtzY29wZV9uYW1lcxgBIAMoCUID4EEBUgpzY29wZU5hbWVz
Ip8BChdHZXRSZWZlcmVuY2VMaXN0UmVxdWVzdBJCCgRuYW1lGAEgASgJQi7gQQL6QSgKJmNo
cm9uaWNsZS5nb29nbGVhcGlzLmNvbS9SZWZlcmVuY2VMaXN0UgRuYW1lEkAKBHZpZXcYAiAB
KA4yLC5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLlJlZmVyZW5jZUxpc3RWaWV3UgR2aWV3
IuEBChlMaXN0UmVmZXJlbmNlTGlzdHNSZXF1ZXN0EkYKBnBhcmVudBgBIAEoCUIu4EEC+kEo
EiZjaHJvbmljbGUuZ29vZ2xlYXBpcy5jb20vUmVmZXJlbmNlTGlzdFIGcGFyZW50EhsKCXBh
Z2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu
EkAKBHZpZXcYBCABKA4yLC5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLlJlZmVyZW5jZUxp
c3RWaWV3UgR2aWV3IpcBChpMaXN0UmVmZXJlbmNlTGlzdHNSZXNwb25zZRJRCg9yZWZlcmVu
Y2VfbGlzdHMYASADKAsyKC5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLlJlZmVyZW5jZUxp
c3RSDnJlZmVyZW5jZUxpc3RzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiLrAQoaQ3JlYXRlUmVmZXJlbmNlTGlzdFJlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7g
QQL6QSgSJmNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9SZWZlcmVuY2VMaXN0UgZwYXJlbnQS
VAoOcmVmZXJlbmNlX2xpc3QYAiABKAsyKC5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLlJl
ZmVyZW5jZUxpc3RCA+BBAlINcmVmZXJlbmNlTGlzdBIvChFyZWZlcmVuY2VfbGlzdF9pZBgD
IAEoCUID4EECUg9yZWZlcmVuY2VMaXN0SWQirwEKGlVwZGF0ZVJlZmVyZW5jZUxpc3RSZXF1
ZXN0ElQKDnJlZmVyZW5jZV9saXN0GAEgASgLMiguZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52
MS5SZWZlcmVuY2VMaXN0QgPgQQJSDXJlZmVyZW5jZUxpc3QSOwoLdXBkYXRlX21hc2sYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIosCChpWZXJpZnlS
ZWZlcmVuY2VMaXN0UmVxdWVzdBJFCghpbnN0YW5jZRgBIAEoCUIp4EEC+kEjCiFjaHJvbmlj
bGUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSCGluc3RhbmNlElgKC3N5bnRheF90eXBlGAIg
ASgOMjIuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5SZWZlcmVuY2VMaXN0U3ludGF4VHlw
ZUID4EECUgpzeW50YXhUeXBlEkwKB2VudHJpZXMYAyADKAsyLS5nb29nbGUuY2xvdWQuY2hy
b25pY2xlLnYxLlJlZmVyZW5jZUxpc3RFbnRyeUID4EECUgdlbnRyaWVzIn4KG1ZlcmlmeVJl
ZmVyZW5jZUxpc3RSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEkUKBmVycm9y
cxgCIAMoCzItLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuUmVmZXJlbmNlTGlzdEVycm9y
UgZlcnJvcnMinAUKDVJlZmVyZW5jZUxpc3QSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYK
DGRpc3BsYXlfbmFtZRgCIAEoCUID4EEDUgtkaXNwbGF5TmFtZRJRChRyZXZpc2lvbl9jcmVh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IScmV2aXNp
b25DcmVhdGVUaW1lEiUKC2Rlc2NyaXB0aW9uGAQgASgJQgPgQQJSC2Rlc2NyaXB0aW9uEkwK
B2VudHJpZXMYBSADKAsyLS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLlJlZmVyZW5jZUxp
c3RFbnRyeUID4EECUgdlbnRyaWVzEhkKBXJ1bGVzGAYgAygJQgPgQQNSBXJ1bGVzElgKC3N5
bnRheF90eXBlGAggASgOMjIuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5SZWZlcmVuY2VM
aXN0U3ludGF4VHlwZUID4EECUgpzeW50YXhUeXBlEjsKF3J1bGVfYXNzb2NpYXRpb25zX2Nv
dW50GAkgASgFQgPgQQNSFXJ1bGVBc3NvY2lhdGlvbnNDb3VudBJDCgpzY29wZV9pbmZvGAsg
ASgLMiQuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5TY29wZUluZm9SCXNjb3BlSW5mbzqK
AepBhgEKJmNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9SZWZlcmVuY2VMaXN0Elxwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0v
cmVmZXJlbmNlTGlzdHMve3JlZmVyZW5jZV9saXN0fSIvChJSZWZlcmVuY2VMaXN0RW50cnkS
GQoFdmFsdWUYASABKAlCA+BBAlIFdmFsdWUiWgoSUmVmZXJlbmNlTGlzdEVycm9yEh8KC2xp
bmVfbnVtYmVyGAEgASgFUgpsaW5lTnVtYmVyEiMKDWVycm9yX21lc3NhZ2UYAiABKAlSDGVy
cm9yTWVzc2FnZSrCAQoXUmVmZXJlbmNlTGlzdFN5bnRheFR5cGUSKgomUkVGRVJFTkNFX0xJ
U1RfU1lOVEFYX1RZUEVfVU5TUEVDSUZJRUQQABIwCixSRUZFUkVOQ0VfTElTVF9TWU5UQVhf
VFlQRV9QTEFJTl9URVhUX1NUUklORxABEiQKIFJFRkVSRU5DRV9MSVNUX1NZTlRBWF9UWVBF
X1JFR0VYEAISIwofUkVGRVJFTkNFX0xJU1RfU1lOVEFYX1RZUEVfQ0lEUhADKnUKEVJlZmVy
ZW5jZUxpc3RWaWV3EiMKH1JFRkVSRU5DRV9MSVNUX1ZJRVdfVU5TUEVDSUZJRUQQABIdChlS
RUZFUkVOQ0VfTElTVF9WSUVXX0JBU0lDEAESHAoYUkVGRVJFTkNFX0xJU1RfVklFV19GVUxM
EAIyrQoKFFJlZmVyZW5jZUxpc3RTZXJ2aWNlEr8BChBHZXRSZWZlcmVuY2VMaXN0EjIuZ29v
Z2xlLmNsb3VkLmNocm9uaWNsZS52MS5HZXRSZWZlcmVuY2VMaXN0UmVxdWVzdBooLmdvb2ds
ZS5jbG91ZC5jaHJvbmljbGUudjEuUmVmZXJlbmNlTGlzdCJNgtPkkwJAEj4vdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9yZWZlcmVuY2VMaXN0cy8qfdpB
BG5hbWUS0gEKEkxpc3RSZWZlcmVuY2VMaXN0cxI0Lmdvb2dsZS5jbG91ZC5jaHJvbmljbGUu
djEuTGlzdFJlZmVyZW5jZUxpc3RzUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5jaHJvbmljbGUu
djEuTGlzdFJlZmVyZW5jZUxpc3RzUmVzcG9uc2UiT4LT5JMCQBI+L3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0vcmVmZXJlbmNlTGlzdHPaQQZwYXJl
bnQS+QEKE0NyZWF0ZVJlZmVyZW5jZUxpc3QSNS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYx
LkNyZWF0ZVJlZmVyZW5jZUxpc3RSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52
MS5SZWZlcmVuY2VMaXN0IoABgtPkkwJQIj4vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2luc3RhbmNlcy8qfS9yZWZlcmVuY2VMaXN0czoOcmVmZXJlbmNlX2xpc3TaQSdw
YXJlbnQscmVmZXJlbmNlX2xpc3QscmVmZXJlbmNlX2xpc3RfaWQS+wEKE1VwZGF0ZVJlZmVy
ZW5jZUxpc3QSNS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLlVwZGF0ZVJlZmVyZW5jZUxp
c3RSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5SZWZlcmVuY2VMaXN0IoIB
gtPkkwJfMk0vdjEve3JlZmVyZW5jZV9saXN0Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9pbnN0YW5jZXMvKi9yZWZlcmVuY2VMaXN0cy8qfToOcmVmZXJlbmNlX2xpc3TaQRpyZWZl
cmVuY2VfbGlzdCx1cGRhdGVfbWFzaxLWAQoTVmVyaWZ5UmVmZXJlbmNlTGlzdBI1Lmdvb2ds
ZS5jbG91ZC5jaHJvbmljbGUudjEuVmVyaWZ5UmVmZXJlbmNlTGlzdFJlcXVlc3QaNi5nb29n
bGUuY2xvdWQuY2hyb25pY2xlLnYxLlZlcmlmeVJlZmVyZW5jZUxpc3RSZXNwb25zZSJQgtPk
kwJKIkUvdjEve2luc3RhbmNlPXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyp9
OnZlcmlmeVJlZmVyZW5jZUxpc3Q6ASoaqgHKQRhjaHJvbmljbGUuZ29vZ2xlYXBpcy5jb23S
QYsBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jaHJvbmljbGUsaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jaHJvbmljbGUucmVhZG9ubHksaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULJAQodY29tLmdvb2dsZS5jbG91
ZC5jaHJvbmljbGUudjFCElJlZmVyZW5jZUxpc3RQcm90b1ABWjtjbG91ZC5nb29nbGUuY29t
L2dvL2Nocm9uaWNsZS9hcGl2MS9jaHJvbmljbGVwYjtjaHJvbmljbGVwYqoCGUdvb2dsZS5D
bG91ZC5DaHJvbmljbGUuVjHKAhlHb29nbGVcQ2xvdWRcQ2hyb25pY2xlXFYx6gIcR29vZ2xl
OjpDbG91ZDo6Q2hyb25pY2xlOjpWMUrdVQoHEgUOAMkCAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoICgEIEgMZADYKCQoCCCUS
AxkANgoICgEIEgMaAFIKCQoCCAsSAxoAUgoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMc
ADMKCQoCCAgSAxwAMwoICgEIEgMdADYKCQoCCAESAx0ANgoICgEIEgMeADYKCQoCCCkSAx4A
NgoICgEIEgMfADUKCQoCCC0SAx8ANQpWCgIGABIEIgBVARpKIFJlZmVyZW5jZUxpc3RTZXJ2
aWNlIHByb3ZpZGVzIGFuIGludGVyZmFjZSBmb3IgbWFuYWdpbmcgcmVmZXJlbmNlIGxpc3Rz
LgoKCgoDBgABEgMiCBwKCgoDBgADEgMjAkAKDAoFBgADmQgSAyMCQAoLCgMGAAMSBCQCJzcK
DQoFBgADmggSBCQCJzcKLQoEBgACABIEKgIvAxofIEdldHMgYSBzaW5nbGUgcmVmZXJlbmNl
IGxpc3QuCgoMCgUGAAIAARIDKgYWCgwKBQYAAgACEgMqFy4KDAoFBgACAAMSAyo5RgoNCgUG
AAIABBIEKwQtBgoRCgkGAAIABLDKvCISBCsELQYKDAoFBgACAAQSAy4EMgoPCggGAAIABJsI
ABIDLgQyCjYKBAYAAgESBDICOAMaKCBMaXN0cyBhIGNvbGxlY3Rpb24gb2YgcmVmZXJlbmNl
IGxpc3RzLgoKDAoFBgACAQESAzIGGAoMCgUGAAIBAhIDMhkyCgwKBQYAAgEDEgMzDykKDQoF
BgACAQQSBDQENgYKEQoJBgACAQSwyrwiEgQ0BDYGCgwKBQYAAgEEEgM3BDQKDwoIBgACAQSb
CAASAzcENAotCgQGAAICEgQ7AkIDGh8gQ3JlYXRlcyBhIG5ldyByZWZlcmVuY2UgbGlzdC4K
CgwKBQYAAgIBEgM7BhkKDAoFBgACAgISAzsaNAoMCgUGAAICAxIDOz9MCg0KBQYAAgIEEgQ8
BD8GChEKCQYAAgIEsMq8IhIEPAQ/BgoNCgUGAAICBBIEQARBMgoQCggGAAICBJsIABIEQARB
MgozCgQGAAIDEgRFAksDGiUgVXBkYXRlcyBhbiBleGlzdGluZyByZWZlcmVuY2UgbGlzdC4K
CgwKBQYAAgMBEgNFBhkKDAoFBgACAwISA0UaNAoMCgUGAAIDAxIDRT9MCg0KBQYAAgMEEgRG
BEkGChEKCQYAAgMEsMq8IhIERgRJBgoMCgUGAAIDBBIDSgRICg8KCAYAAgMEmwgAEgNKBEgK
WwoEBgACBBIETgJUAxpNIFZlcmlmeVJlZmVyZW5jZUxpc3QgdmFsaWRhdGVzIGxpc3QgY29u
dGVudCBhbmQgcmV0dXJucyBsaW5lIGVycm9ycywgaWYgYW55LgoKDAoFBgACBAESA04GGQoM
CgUGAAIEAhIDTho0CgwKBQYAAgQDEgNPDyoKDQoFBgACBAQSBFAEUwYKEQoJBgACBASwyrwi
EgRQBFMGCk4KAgUAEgRYAGQBGkIgVGhlIHN5bnRheCB0eXBlIGluZGljYXRpbmcgaG93IGxp
c3QgZW50cmllcyBzaG91bGQgYmUgdmFsaWRhdGVkLgoKCgoDBQABEgNYBRwKSAoEBQACABID
WgItGjsgRGVmYXVsdHMgdG8gUkVGRVJFTkNFX0xJU1RfU1lOVEFYX1RZUEVfUExBSU5fVEVY
VF9TVFJJTkcuCgoMCgUFAAIAARIDWgIoCgwKBQUAAgACEgNaKywKMQoEBQACARIDXQIzGiQg
TGlzdCBjb250YWlucyBwbGFpbiB0ZXh0IHBhdHRlcm5zLgoKDAoFBQACAQESA10CLgoMCgUF
AAIBAhIDXTEyCj4KBAUAAgISA2ACJxoxIExpc3QgY29udGFpbnMgb25seSBSZWd1bGFyIEV4
cHJlc3Npb24gcGF0dGVybnMuCgoMCgUFAAICARIDYAIiCgwKBQUAAgICEgNgJSYKMAoEBQAC
AxIDYwImGiMgTGlzdCBjb250YWlucyBvbmx5IENJRFIgcGF0dGVybnMuCgoMCgUFAAIDARID
YwIhCgwKBQUAAgMCEgNjJCUKbAoCBQESBGgAdgEaYCBSZWZlcmVuY2VMaXN0VmlldyBpcyBh
IG1lY2hhbmlzbSBmb3Igdmlld2luZyBwYXJ0aWFsIHJlc3BvbnNlcyBvZiB0aGUKIFJlZmVy
ZW5jZUxpc3QgcmVzb3VyY2UuCgoKCgMFAQESA2gFFgrLAQoEBQECABIDbQImGr0BIFRoZSBk
ZWZhdWx0IC8gdW5zZXQgdmFsdWUuCiBUaGUgQVBJIHdpbGwgZGVmYXVsdCB0byB0aGUgQkFT
SUMgdmlldyBmb3IgTGlzdFJlZmVyZW5jZUxpc3RzLgogVGhlIEFQSSB3aWxsIGRlZmF1bHQg
dG8gdGhlIEZVTEwgdmlldyBmb3IgbWV0aG9kcyB0aGF0IHJldHVybiBhIHNpbmdsZQogUmVm
ZXJlbmNlTGlzdCByZXNvdXJjZS4KCgwKBQUBAgABEgNtAiEKDAoFBQECAAISA20kJQpqCgQF
AQIBEgNxAiAaXSBJbmNsdWRlIG1ldGFkYXRhIGFib3V0IHRoZSBSZWZlcmVuY2VMaXN0Lgog
VGhpcyBpcyB0aGUgZGVmYXVsdCB2aWV3IGZvciBMaXN0UmVmZXJlbmNlTGlzdHMuCgoMCgUF
AQIBARIDcQIbCgwKBQUBAgECEgNxHh8KnQEKBAUBAgISA3UCHxqPASBJbmNsdWRlIGFsbCBk
ZXRhaWxzIGFib3V0IHRoZSBSZWZlcmVuY2VMaXN0OiBtZXRhZGF0YSwgY29udGVudCBsaW5l
cywKIGFzc29jaWF0ZWQgcnVsZSBjb3VudHMuIFRoaXMgaXMgdGhlIGRlZmF1bHQgdmlldyBm
b3IgR2V0UmVmZXJlbmNlTGlzdC4KCgwKBQUBAgIBEgN1AhoKDAoFBQECAgISA3UdHgpHCgIE
ABIEeQB+ARo7IFNjb3BlSW5mbyBzcGVjaWZpZXMgdGhlIHNjb3BlIGluZm8gb2YgdGhlIHJl
ZmVyZW5jZSBsaXN0LgoKCgoDBAABEgN5CBEKiQEKBAQAAgASBHwCfS8aeyBSZXF1aXJlZC4g
VGhlIGxpc3Qgb2Ygc2NvcGUgbmFtZXMgb2YgdGhlIHJlZmVyZW5jZSBsaXN0LCBpZiB0aGUg
bGlzdCBpcwogZW1wdHkgdGhlIHJlZmVyZW5jZSBsaXN0IGlzIHRyZWF0ZWQgYXMgdW5zY29w
ZWQuCgoMCgUEAAIABhIDfAIUCgwKBQQAAgABEgN8FSkKDAoFBAACAAMSA3wsLQoMCgUEAAIA
CBIDfQYuCg8KCAQAAgAInAgAEgN9By0KWwoCBAESBoEBAIYBARpNIFJlZmVyZW5jZUxpc3RT
Y29wZSBzcGVjaWZpZXMgdGhlIGxpc3Qgb2Ygc2NvcGUgbmFtZXMgb2YgdGhlIHJlZmVyZW5j
ZSBsaXN0LgoKCwoDBAEBEgSBAQgaCvQBCgQEAQIAEgSFAQJLGuUBIE9wdGlvbmFsLiBUaGUg
bGlzdCBvZiBzY29wZSBuYW1lcyBvZiB0aGUgcmVmZXJlbmNlIGxpc3QuIFRoZSBzY29wZSBu
YW1lcwogc2hvdWxkIGJlIGZ1bGwgcmVzb3VyY2UgbmFtZXMgYW5kIHNob3VsZCBiZSBvZiB0
aGUgZm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9p
bnN0YW5jZXMve2luc3RhbmNlfS9kYXRhQWNjZXNzU2NvcGVzL3tzY29wZV9uYW1lfWAuCgoN
CgUEAQIABBIEhQECCgoNCgUEAQIABRIEhQELEQoNCgUEAQIAARIEhQESHQoNCgUEAQIAAxIE
hQEgIQoNCgUEAQIACBIEhQEiSgoQCggEAQIACJwIABIEhQEjSQpACgIEAhIGiQEAlwEBGjIg
QSByZXF1ZXN0IHRvIGdldCBkZXRhaWxzIGFib3V0IGEgcmVmZXJlbmNlIGxpc3QuCgoLCgME
AgESBIkBCB8KuwEKBAQCAgASBo0BApIBBBqqASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIHJlZmVyZW5jZSBsaXN0IHRvIHJldHJpZXZlLgogRm9ybWF0OgogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9uc30vaW5zdGFuY2VzL3tpbnN0YW5j
ZX0vcmVmZXJlbmNlTGlzdHMve3JlZmVyZW5jZV9saXN0fWAKCg0KBQQCAgAFEgSNAQIICg0K
BQQCAgABEgSNAQkNCg0KBQQCAgADEgSNARARCg8KBQQCAgAIEgaNARKSAQMKEAoIBAICAAic
CAASBI4BBCoKEQoHBAICAAifCBIGjwEEkQEFCl0KBAQCAgESBJYBAh0aTyBIb3cgbXVjaCBv
ZiB0aGUgUmVmZXJlbmNlTGlzdCB0byB2aWV3LiBEZWZhdWx0cyB0bwogUkVGRVJFTkNFX0xJ
U1RfVklFV19GVUxMLgoKDQoFBAICAQYSBJYBAhMKDQoFBAICAQESBJYBFBgKDQoFBAICAQMS
BJYBGxwKOAoCBAMSBpoBALQBARoqIEEgcmVxdWVzdCBmb3IgYSBsaXN0IG9mIHJlZmVyZW5j
ZSBsaXN0cy4KCgsKAwQDARIEmgEIIQqgAQoEBAMCABIGngECowEEGo8BIFJlcXVpcmVkLiBU
aGUgcGFyZW50LCB3aGljaCBvd25zIHRoaXMgY29sbGVjdGlvbiBvZiByZWZlcmVuY2UgbGlz
dHMuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBAMCAAUSBJ4BAggKDQoFBAMCAAESBJ4BCQ8K
DQoFBAMCAAMSBJ4BEhMKDwoFBAMCAAgSBp4BFKMBAwoQCggEAwIACJwIABIEnwEEKgoRCgcE
AwIACJ8IEgagAQSiAQUK9gEKBAQDAgESBKkBAhYa5wEgVGhlIG1heGltdW0gbnVtYmVyIG9m
IHJlZmVyZW5jZSBsaXN0cyB0byByZXR1cm4uCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZl
d2VyIHRoYW4gdGhpcyB2YWx1ZS4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDEwMCByZWZl
cmVuY2UgbGlzdHMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEw
MDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBAMC
AQUSBKkBAgcKDQoFBAMCAQESBKkBCBEKDQoFBAMCAQMSBKkBFBUK/AEKBAQDAgISBK8BAhga
7QEgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RSZWZlcmVu
Y2VMaXN0c2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVu
dCBwYWdlLgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRl
ZCB0byBgTGlzdFJlZmVyZW5jZUxpc3RzYCBtdXN0CiBtYXRjaCB0aGUgY2FsbCB0aGF0IHBy
b3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAMCAgUSBK8BAggKDQoFBAMCAgESBK8BCRMK
DQoFBAMCAgMSBK8BFhcKXwoEBAMCAxIEswECHRpRIEhvdyBtdWNoIG9mIGVhY2ggUmVmZXJl
bmNlTGlzdCB0byB2aWV3LiBEZWZhdWx0cyB0bwogUkVGRVJFTkNFX0xJU1RfVklFV19CQVNJ
Qy4KCg0KBQQDAgMGEgSzAQITCg0KBQQDAgMBEgSzARQYCg0KBQQDAgMDEgSzARscCkYKAgQE
Ega3AQC/AQEaOCBBIHJlc3BvbnNlIHRvIGEgcmVxdWVzdCBmb3IgYSBsaXN0IG9mIHJlZmVy
ZW5jZSBsaXN0cy4KCgsKAwQEARIEtwEIIgpWCgQEBAIAEgS6AQItGkggVGhlIHJlZmVyZW5j
ZSBsaXN0cy4KIE9yZGVyZWQgaW4gYXNjZW5kaW5nIGFscGhhYmV0aWNhbCBvcmRlciBieSBu
YW1lLgoKDQoFBAQCAAQSBLoBAgoKDQoFBAQCAAYSBLoBCxgKDQoFBAQCAAESBLoBGSgKDQoF
BAQCAAMSBLoBKywKkAEKBAQEAgESBL4BAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNl
bnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlz
IGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoF
BAQCAQUSBL4BAggKDQoFBAQCAQESBL4BCRgKDQoFBAQCAQMSBL4BGxwKNQoCBAUSBsIBANYB
ARonIEEgcmVxdWVzdCB0byBjcmVhdGUgYSByZWZlcmVuY2UgbGlzdC4KCgsKAwQFARIEwgEI
IgqjAQoEBAUCABIGxQECygEEGpIBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIHdo
ZXJlIHRoaXMgcmVmZXJlbmNlIGxpc3Qgd2lsbCBiZSBjcmVhdGVkLgogRm9ybWF0OiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFu
Y2V9YAoKDQoFBAUCAAUSBMUBAggKDQoFBAUCAAESBMUBCQ8KDQoFBAUCAAMSBMUBEhMKDwoF
BAUCAAgSBsUBFMoBAwoQCggEBQIACJwIABIExgEEKgoRCgcEBQIACJ8IEgbHAQTJAQUKNwoE
BAUCARIEzQECTBopIFJlcXVpcmVkLiBUaGUgcmVmZXJlbmNlIGxpc3QgdG8gY3JlYXRlLgoK
DQoFBAUCAQYSBM0BAg8KDQoFBAUCAQESBM0BEB4KDQoFBAUCAQMSBM0BISIKDQoFBAUCAQgS
BM0BI0sKEAoIBAUCAQicCAASBM0BJEoKnAIKBAQFAgISBNUBAkgajQIgUmVxdWlyZWQuIFRo
ZSBJRCB0byB1c2UgZm9yIHRoZSByZWZlcmVuY2UgbGlzdC4gVGhpcyBpcyBhbHNvIHRoZSBk
aXNwbGF5CiBuYW1lIGZvciB0aGUgcmVmZXJlbmNlIGxpc3QuIEl0IG11c3Qgc2F0aXNmeSB0
aGUgZm9sbG93aW5nIHJlcXVpcmVtZW50czoKIC0gU3RhcnRzIHdpdGggbGV0dGVyLgogLSBD
b250YWlucyBvbmx5IGxldHRlcnMsIG51bWJlcnMgYW5kIHVuZGVyc2NvcmUuCiAtIEhhcyBs
ZW5ndGggbGVzcyB0aGFuIDI1Ni4KIC0gTXVzdCBiZSB1bmlxdWUuCgoNCgUEBQICBRIE1QEC
CAoNCgUEBQICARIE1QEJGgoNCgUEBQICAxIE1QEdHgoNCgUEBQICCBIE1QEfRwoQCggEBQIC
CJwIABIE1QEgRgo1CgIEBhIG2QEA5gEBGicgQSByZXF1ZXN0IHRvIHVwZGF0ZSBhIHJlZmVy
ZW5jZSBsaXN0LgoKCwoDBAYBEgTZAQgiCvkBCgQEBgIAEgTgAQJMGuoBIFJlcXVpcmVkLiBU
aGUgcmVmZXJlbmNlIGxpc3QgdG8gdXBkYXRlLgoKIFRoZSByZWZlcmVuY2UgbGlzdCdzIGBu
YW1lYCBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRoZSByZWZlcmVuY2UgbGlzdCB0bwog
dXBkYXRlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9uc30vaW5zdGFuY2VzL3tpbnN0YW5jZX0vcmVmZXJlbmNlTGlzdHMve3JlZmVyZW5jZV9s
aXN0fWAKCg0KBQQGAgAGEgTgAQIPCg0KBQQGAgABEgTgARAeCg0KBQQGAgADEgTgASEiCg0K
BQQGAgAIEgTgASNLChAKCAQGAgAInAgAEgTgASRKCrgBCgQEBgIBEgTlAQIsGqkBIFRoZSBs
aXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCiBXaGVuIG5vIGZpZWxkIG1hc2sgaXMgc3VwcGxp
ZWQsIGFsbCBub24tZW1wdHkgZmllbGRzIHdpbGwgYmUgdXBkYXRlZC4KIEEgZmllbGQgbWFz
ayBvZiAiKiIgd2lsbCB1cGRhdGUgYWxsIGZpZWxkcywgd2hldGhlciBlbXB0eSBvciBub3Qu
CgoNCgUEBgIBBhIE5QECGwoNCgUEBgIBARIE5QEcJwoNCgUEBgIBAxIE5QEqKwo0CgIEBxIG
6QEA/AEBGiYgVmVyaWZ5UmVmZXJlbmNlTGlzdCByZXF1ZXN0IG1lc3NhZ2UuCgoLCgMEBwES
BOkBCCIKwAEKBAQHAgASBu0BAvIBBBqvASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHBh
cmVudCByZXNvdXJjZSwgd2hpY2ggaXMgdGhlIFNlY09wcyBpbnN0YW5jZQogYXNzb2NpYXRl
ZCB3aXRoIHRoZSByZXF1ZXN0LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBAcCAAUSBO0BAggK
DQoFBAcCAAESBO0BCREKDQoFBAcCAAMSBO0BFBUKDwoFBAcCAAgSBu0BFvIBAwoQCggEBwIA
CJwIABIE7gEEKgoRCgcEBwIACJ8IEgbvAQTxAQUKOAoEBAcCARIG9QEC9gEvGiggUmVxdWly
ZWQuIFR5cGUgKGZvcm1hdCkgb2YgbGlzdCBsaW5lcy4KCg0KBQQHAgEGEgT1AQIZCg0KBQQH
AgEBEgT1ARolCg0KBQQHAgEDEgT1ASgpCg0KBQQHAgEIEgT2AQYuChAKCAQHAgEInAgAEgT2
AQctCnkKBAQHAgISBvoBAvsBLxppIFJlcXVpcmVkLiBUaGUgZW50cmllcyBvZiB0aGUgcmVm
ZXJlbmNlIGxpc3QuCiBFYWNoIGxpbmUgbWF5IGJlIGVpdGhlciBhbiBpdGVtIGluIHRoZSBs
aXN0IG9yIGEgY29tbWVudC4KCg0KBQQHAgIEEgT6AQIKCg0KBQQHAgIGEgT6AQsdCg0KBQQH
AgIBEgT6AR4lCg0KBQQHAgIDEgT6ASgpCg0KBQQHAgIIEgT7AQYuChAKCAQHAgIInAgAEgT7
AQctCjQKAgQIEgb/AQCFAgEaJiBWZXJpZnlMaXN0UmVzcG9uc2UgcmVzcG9uc2UgbWVzc2Fn
ZS4KCgsKAwQIARIE/wEIIwo7CgQECAIAEgSBAgITGi0gVmFsaWRpdHkgb2YgbGlzdCAtIHRy
dWUgaWYgbm8gZXJyb3JzIGZvdW5kLgoKDQoFBAgCAAUSBIECAgYKDQoFBAgCAAESBIECBw4K
DQoFBAgCAAMSBIECERIKQQoEBAgCARIEhAICKRozIExpbmUtbGV2ZWwgZXJyb3JzIGNhdXNp
bmcgdGhlIGxpc3QgdG8gYmUgaW52YWxpZC4KCg0KBQQIAgEEEgSEAgIKCg0KBQQIAgEGEgSE
AgsdCg0KBQQIAgEBEgSEAh4kCg0KBQQIAgEDEgSEAicoCnsKAgQJEgaKAgC5AgEabSBBIHJl
ZmVyZW5jZSBsaXN0LgogUmVmZXJlbmNlIGxpc3RzIGFyZSB1c2VyLWRlZmluZWQgbGlzdHMg
b2YgdmFsdWVzIHdoaWNoIHVzZXJzIGNhbgogdXNlIGluIG11bHRpcGxlIFJ1bGVzLgoKCwoD
BAkBEgSKAggVCg0KAwQJBxIGiwICjgIECg8KBQQJB50IEgaLAgKOAgQKrgEKBAQJAgASBJMC
Aj0anwEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHJlZmVyZW5jZSBs
aXN0LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9pbnN0YW5jZXMve2luc3RhbmNlfS9yZWZlcmVuY2VMaXN0cy97cmVmZXJlbmNlX2xpc3R9
YAoKDQoFBAkCAAUSBJMCAggKDQoFBAkCAAESBJMCCQ0KDQoFBAkCAAMSBJMCEBEKDQoFBAkC
AAgSBJMCEjwKEAoIBAkCAAicCAASBJMCEzsKSwoEBAkCARIElgICRho9IE91dHB1dCBvbmx5
LiBUaGUgdW5pcXVlIGRpc3BsYXkgbmFtZSBvZiB0aGUgcmVmZXJlbmNlIGxpc3QuCgoNCgUE
CQIBBRIElgICCAoNCgUECQIBARIElgIJFQoNCgUECQIBAxIElgIYGQoNCgUECQIBCBIElgIa
RQoQCggECQIBCJwIABIElgIbRApWCgQECQICEgaZAgKaAjIaRiBPdXRwdXQgb25seS4gVGhl
IHRpbWVzdGFtcCB3aGVuIHRoZSByZWZlcmVuY2UgbGlzdCB3YXMgbGFzdCB1cGRhdGVkLgoK
DQoFBAkCAgYSBJkCAhsKDQoFBAkCAgESBJkCHDAKDQoFBAkCAgMSBJkCMzQKDQoFBAkCAggS
BJoCBjEKEAoIBAkCAgicCAASBJoCBzAKTAoEBAkCAxIEnQICQho+IFJlcXVpcmVkLiBBIHVz
ZXItcHJvdmlkZWQgZGVzY3JpcHRpb24gb2YgdGhlIHJlZmVyZW5jZSBsaXN0LgoKDQoFBAkC
AwUSBJ0CAggKDQoFBAkCAwESBJ0CCRQKDQoFBAkCAwMSBJ0CFxgKDQoFBAkCAwgSBJ0CGUEK
EAoIBAkCAwicCAASBJ0CGkAKpAIKBAQJAgQSBqQCAqUCLxqTAiBSZXF1aXJlZC4gVGhlIGVu
dHJpZXMgb2YgdGhlIHJlZmVyZW5jZSBsaXN0LgogV2hlbiBsaXN0ZWQsIHRoZXkgYXJlIHJl
dHVybmVkIGluIHRoZSBvcmRlciB0aGF0IHdhcyBzcGVjaWZpZWQgYXQgY3JlYXRpb24KIG9y
IHVwZGF0ZS4gVGhlIGNvbWJpbmVkIHNpemUgb2YgdGhlIHZhbHVlcyBvZiB0aGUgcmVmZXJl
bmNlIGxpc3QgbWF5IG5vdAogZXhjZWVkIDZNQi4KIFRoaXMgaXMgcmV0dXJuZWQgb25seSB3
aGVuIHRoZSB2aWV3IGlzIFJFRkVSRU5DRV9MSVNUX1ZJRVdfRlVMTC4KCg0KBQQJAgQEEgSk
AgIKCg0KBQQJAgQGEgSkAgsdCg0KBQQJAgQBEgSkAh4lCg0KBQQJAgQDEgSkAigpCg0KBQQJ
AgQIEgSlAgYuChAKCAQJAgQInAgAEgSlAgctCrgBCgQECQIFEgSqAgJIGqkBIE91dHB1dCBv
bmx5LiBUaGUgcmVzb3VyY2UgbmFtZXMgZm9yIHRoZSBhc3NvY2lhdGVkIHNlbGYtYXV0aG9y
ZWQgUnVsZXMgdGhhdAogdXNlIHRoaXMgcmVmZXJlbmNlIGxpc3QuIFRoaXMgaXMgcmV0dXJu
ZWQgb25seSB3aGVuIHRoZSB2aWV3IGlzCiBSRUZFUkVOQ0VfTElTVF9WSUVXX0ZVTEwuCgoN
CgUECQIFBBIEqgICCgoNCgUECQIFBRIEqgILEQoNCgUECQIFARIEqgISFwoNCgUECQIFAxIE
qgIaGwoNCgUECQIFCBIEqgIcRwoQCggECQIFCJwIABIEqgIdRgpcCgQECQIGEgatAgKuAi8a
TCBSZXF1aXJlZC4gVGhlIHN5bnRheCB0eXBlIGluZGljYXRpbmcgaG93IGxpc3QgZW50cmll
cyBzaG91bGQgYmUgdmFsaWRhdGVkLgoKDQoFBAkCBgYSBK0CAhkKDQoFBAkCBgESBK0CGiUK
DQoFBAkCBgMSBK0CKCkKDQoFBAkCBggSBK4CBi4KEAoIBAkCBgicCAASBK4CBy0KVwoEBAkC
BxIEsQICUBpJIE91dHB1dCBvbmx5LiBUaGUgY291bnQgb2Ygc2VsZi1hdXRob3JlZCBydWxl
cyB1c2luZyB0aGUgcmVmZXJlbmNlIGxpc3QuCgoNCgUECQIHBRIEsQICBwoNCgUECQIHARIE
sQIIHwoNCgUECQIHAxIEsQIiIwoNCgUECQIHCBIEsQIkTwoQCggECQIHCJwIABIEsQIlTgra
AgoEBAkCCBIEuAICHBrLAiBUaGUgc2NvcGUgaW5mbyBvZiB0aGUgcmVmZXJlbmNlIGxpc3Qu
CiBEdXJpbmcgcmVmZXJlbmNlIGxpc3QgY3JlYXRpb24sIGlmIHRoaXMgZmllbGQgaXMgbm90
IHNldCwgdGhlIHJlZmVyZW5jZQogbGlzdCB3aXRob3V0IHNjb3BlcyAoYW4gdW5zY29wZWQg
bGlzdCkgd2lsbCBiZSBjcmVhdGVkIGZvciBhbiB1bnNjb3BlZAogdXNlci4gRm9yIGEgc2Nv
cGVkIHVzZXIsIHRoaXMgZmllbGQgbXVzdCBiZSBzZXQuIER1cmluZyByZWZlcmVuY2UgbGlz
dAogdXBkYXRlLCBpZiBzY29wZV9pbmZvIGlzIHJlcXVlc3RlZCB0byBiZSB1cGRhdGVkLCB0
aGlzIGZpZWxkIG11c3QgYmUgc2V0LgoKDQoFBAkCCAYSBLgCAgsKDQoFBAkCCAESBLgCDBYK
DQoFBAkCCAMSBLgCGRsKLQoCBAoSBrwCAL8CARofIEFuIGVudHJ5IGluIGEgcmVmZXJlbmNl
IGxpc3QuCgoLCgMECgESBLwCCBoKUwoEBAoCABIEvgICPBpFIFJlcXVpcmVkLiBUaGUgdmFs
dWUgb2YgdGhlIGVudHJ5LiBNYXhpbXVtIGxlbmd0aCBpcyA1MTIgY2hhcmFjdGVycy4KCg0K
BQQKAgAFEgS+AgIICg0KBQQKAgABEgS+AgkOCg0KBQQKAgADEgS+AhESCg0KBQQKAgAIEgS+
AhM7ChAKCAQKAgAInAgAEgS+AhQ6CkYKAgQLEgbCAgDJAgEaOCBUaGUgZXJyb3IgZ2VuZXJh
dGVkIHdoZW4gdmVyaWZ5aW5nIHRoZSByZWZlcmVuY2UgbGlzdC4KCgsKAwQLARIEwgIIGgpl
CgQECwIAEgTFAgIYGlcgMS1pbmRleGVkIGxpbmUgbnVtYmVyIHdoZXJlIHRoZSBlcnJvciBv
Y2N1cnMuCiBHZW5lcmFsIGxpc3QgZXJyb3JzIGFyZSBpbmRleGVkIGF0IC0xLgoKDQoFBAsC
AAUSBMUCAgcKDQoFBAsCAAESBMUCCBMKDQoFBAsCAAMSBMUCFhcKOwoEBAsCARIEyAICGxot
IE1lc3NhZ2UgZXhwbGFpbmluZyB3aHkgdGhlIGxpbmUgaXMgaW52YWxpZC4KCg0KBQQLAgEF
EgTIAgIICg0KBQQLAgEBEgTIAgkWCg0KBQQLAgEDEgTIAhkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo ===
    # Fields for ScopeInfo
    # Field: reference_list_scope Type: 11 (.google.cloud.chronicle.v1.ReferenceListScope)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListScope ===
    # Fields for ReferenceListScope
    # Field: scope_names Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest ===
    # Fields for GetReferenceListRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.cloud.chronicle.v1.ReferenceListView)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsRequest ===
    # Fields for ListReferenceListsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.cloud.chronicle.v1.ReferenceListView)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsResponse ===
    # Fields for ListReferenceListsResponse
    # Field: reference_lists Type: 11 (.google.cloud.chronicle.v1.ReferenceList)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::CreateReferenceListRequest ===
    # Fields for CreateReferenceListRequest
    # Field: parent Type: 9 ()
    # Field: reference_list Type: 11 (.google.cloud.chronicle.v1.ReferenceList)
    # Field: reference_list_id Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::UpdateReferenceListRequest ===
    # Fields for UpdateReferenceListRequest
    # Field: reference_list Type: 11 (.google.cloud.chronicle.v1.ReferenceList)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListRequest ===
    # Fields for VerifyReferenceListRequest
    # Field: instance Type: 9 ()
    # Field: syntax_type Type: 14 (.google.cloud.chronicle.v1.ReferenceListSyntaxType)
    # Field: entries Type: 11 (.google.cloud.chronicle.v1.ReferenceListEntry)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListResponse ===
    # Fields for VerifyReferenceListResponse
    # Field: success Type: 8 ()
    # Field: errors Type: 11 (.google.cloud.chronicle.v1.ReferenceListError)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList ===
    # Fields for ReferenceList
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: revision_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: entries Type: 11 (.google.cloud.chronicle.v1.ReferenceListEntry)
    # Field: rules Type: 9 ()
    # Field: syntax_type Type: 14 (.google.cloud.chronicle.v1.ReferenceListSyntaxType)
    # Field: rule_associations_count Type: 5 ()
    # Field: scope_info Type: 11 (.google.cloud.chronicle.v1.ScopeInfo)

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry ===
    # Fields for ReferenceListEntry
    # Field: value Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListError ===
    # Fields for ReferenceListError
    # Field: line_number Type: 5 ()
    # Field: error_message Type: 9 ()

# === Service Client: Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListServiceClient ===
package Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListServiceClient;

=pod

=head2 Service Client: Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListServiceClient

Client stub representing the remote C<ReferenceListService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chronicle.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chronicle.googleapis.com:443' );

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

sub get_reference_list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.ReferenceListService',
        method         => 'GetReferenceList',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList',
    });
}

sub list_reference_lists {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.ReferenceListService',
        method         => 'ListReferenceLists',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsResponse',
    });
}

sub create_reference_list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::ReferenceList::CreateReferenceListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.ReferenceListService',
        method         => 'CreateReferenceList',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList',
    });
}

sub update_reference_list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::ReferenceList::UpdateReferenceListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.ReferenceListService',
        method         => 'UpdateReferenceList',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList',
    });
}

sub verify_reference_list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.ReferenceListService',
        method         => 'VerifyReferenceList',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::ReferenceList - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/reference_list.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::ReferenceList;

    my $msg = Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo->new({
        reference_list_scope => $reference_list_scope,
    });

    # Read or update a field
    my $val = $msg->reference_list_scope();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/reference_list.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo

ScopeInfo specifies the scope info of the reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reference_list_scope() >> / C<< $msg->reference_list_scope($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListScope>)

Required. The list of scope names of the reference list, if the list is
empty the reference list is treated as unscoped.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListScope

ReferenceListScope specifies the list of scope names of the reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scope_names() >> / C<< $msg->scope_names($value) >>

Type: C<String>

Optional. The list of scope names of the reference list. The scope names
should be full resource names and should be of the format:
`projects/{project}/locations/{location}/instances/{instance}/dataAccessScopes/{scope_name}`.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest

A request to get details about a reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the reference list to retrieve.
Format:
`projects/{project}/locations/{locations}/instances/{instance}/referenceLists/{reference_list}`

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::ReferenceListView>)

How much of the ReferenceList to view. Defaults to
REFERENCE_LIST_VIEW_FULL.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsRequest

A request for a list of reference lists.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of reference lists.
Format:
`projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of reference lists to return.
The service may return fewer than this value.
If unspecified, at most 100 reference lists will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListReferenceLists` call.
Provide this to retrieve the subsequent page.
When paginating, all other parameters provided to `ListReferenceLists` must
match the call that provided the page token.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::ReferenceListView>)

How much of each ReferenceList to view. Defaults to
REFERENCE_LIST_VIEW_BASIC.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsResponse

A response to a request for a list of reference lists.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reference_lists() >> / C<< $msg->reference_lists($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList>)

The reference lists.
Ordered in ascending alphabetical order by name.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::CreateReferenceListRequest

A request to create a reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this reference list will be created.
Format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->reference_list() >> / C<< $msg->reference_list($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList>)

Required. The reference list to create.

=item * C<< $msg->reference_list_id() >> / C<< $msg->reference_list_id($value) >>

Type: C<String>

Required. The ID to use for the reference list. This is also the display
name for the reference list. It must satisfy the following requirements:
- Starts with letter.
- Contains only letters, numbers and underscore.
- Has length less than 256.
- Must be unique.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::UpdateReferenceListRequest

A request to update a reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reference_list() >> / C<< $msg->reference_list($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList>)

Required. The reference list to update.

The reference list's `name` field is used to identify the reference list to
update.
Format:
`projects/{project}/locations/{locations}/instances/{instance}/referenceLists/{reference_list}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to update.
When no field mask is supplied, all non-empty fields will be updated.
A field mask of "*" will update all fields, whether empty or not.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListRequest

VerifyReferenceList request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. The name of the parent resource, which is the SecOps instance
associated with the request. Format:
`projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->syntax_type() >> / C<< $msg->syntax_type($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::ReferenceListSyntaxType>)

Required. Type (format) of list lines.

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry>)

Required. The entries of the reference list.
Each line may be either an item in the list or a comment.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListResponse

VerifyListResponse response message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->success() >> / C<< $msg->success($value) >>

Type: C<Bool>

Validity of list - true if no errors found.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListError>)

Line-level errors causing the list to be invalid.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList

A reference list.
Reference lists are user-defined lists of values which users can
use in multiple Rules.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the reference list.
Format:
`projects/{project}/locations/{location}/instances/{instance}/referenceLists/{reference_list}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The unique display name of the reference list.

=item * C<< $msg->revision_create_time() >> / C<< $msg->revision_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the reference list was last updated.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. A user-provided description of the reference list.

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry>)

Required. The entries of the reference list.
When listed, they are returned in the order that was specified at creation
or update. The combined size of the values of the reference list may not
exceed 6MB.
This is returned only when the view is REFERENCE_LIST_VIEW_FULL.

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<String>

Output only. The resource names for the associated self-authored Rules that
use this reference list. This is returned only when the view is
REFERENCE_LIST_VIEW_FULL.

=item * C<< $msg->syntax_type() >> / C<< $msg->syntax_type($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::ReferenceListSyntaxType>)

Required. The syntax type indicating how list entries should be validated.

=item * C<< $msg->rule_associations_count() >> / C<< $msg->rule_associations_count($value) >>

Type: C<Int32>

Output only. The count of self-authored rules using the reference list.

=item * C<< $msg->scope_info() >> / C<< $msg->scope_info($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo>)

The scope info of the reference list.
During reference list creation, if this field is not set, the reference
list without scopes (an unscoped list) will be created for an unscoped
user. For a scoped user, this field must be set. During reference list
update, if scope_info is requested to be updated, this field must be set.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry

An entry in a reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Required. The value of the entry. Maximum length is 512 characters.

=back

=head2 Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListError

The error generated when verifying the reference list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->line_number() >> / C<< $msg->line_number($value) >>

Type: C<Int32>

1-indexed line number where the error occurs.
General list errors are indexed at -1.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Message explaining why the line is invalid.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::ReferenceList::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
