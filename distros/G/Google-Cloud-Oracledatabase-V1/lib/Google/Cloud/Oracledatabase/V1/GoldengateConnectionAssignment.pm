package Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkVnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZ29sZGVuZ2F0ZV9jb25uZWN0aW9u
X2Fzc2lnbm1lbnQucHJvdG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLaBQoeR29sZGVu
Z2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJwCgpw
cm9wZXJ0aWVzGAIgASgLMkguZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkdvbGRl
bmdhdGVDb25uZWN0aW9uQXNzaWdubWVudFByb3BlcnRpZXNCBuBBAuBBBVIKcHJvcGVydGll
cxJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKY3JlYXRlVGltZRJnCgZsYWJlbHMYBCADKAsySi5nb29nbGUuY2xvdWQub3JhY2xlZGF0
YWJhc2UudjEuR29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50LkxhYmVsc0VudHJ5QgPg
QQFSBmxhYmVscxIpCgxkaXNwbGF5X25hbWUYBSABKAlCBuBBAeBBBVILZGlzcGxheU5hbWUS
KgoOZW50aXRsZW1lbnRfaWQYBiABKAlCA+BBA1INZW50aXRsZW1lbnRJZBo5CgtMYWJlbHNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOu8B6kHr
AQo8b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vR29sZGVuZ2F0ZUNvbm5lY3Rpb25B
c3NpZ25tZW50Empwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZ29s
ZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50cy97Z29sZGVuZ2F0ZV9jb25uZWN0aW9uX2Fz
c2lnbm1lbnR9Kh9nb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRzMh5nb2xkZW5nYXRl
Q29ubmVjdGlvbkFzc2lnbm1lbnQijQQKKEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVu
dFByb3BlcnRpZXMSFwoEb2NpZBgBIAEoCUID4EEDUgRvY2lkEm8KFWdvbGRlbmdhdGVfY29u
bmVjdGlvbhgCIAEoCUI64EEC+kE0CjJvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9H
b2xkZW5nYXRlQ29ubmVjdGlvblIUZ29sZGVuZ2F0ZUNvbm5lY3Rpb24SbwoVZ29sZGVuZ2F0
ZV9kZXBsb3ltZW50GAMgASgJQjrgQQL6QTQKMm9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMu
Y29tL0dvbGRlbmdhdGVEZXBsb3ltZW50UhRnb2xkZW5nYXRlRGVwbG95bWVudBIZCgVhbGlh
cxgEIAEoCUID4EEDUgVhbGlhcxJpCgVzdGF0ZRgFIAEoDjJOLmdvb2dsZS5jbG91ZC5vcmFj
bGVkYXRhYmFzZS52MS5Hb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRQcm9wZXJ0aWVz
LlN0YXRlQgPgQQNSBXN0YXRlImAKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoI
Q1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIKCgZGQUlMRUQQAxIMCghVUERBVElORxAEEgwKCERF
TEVUSU5HEAUijQIKKkxpc3RHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRzUmVxdWVz
dBJcCgZwYXJlbnQYASABKAlCROBBAvpBPhI8b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5j
b20vR29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50UgZwYXJlbnQSIAoJcGFnZV9zaXpl
GAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRv
a2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BB
AVIHb3JkZXJCeSKEAgorTGlzdEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudHNSZXNw
b25zZRKKAQohZ29sZGVuZ2F0ZV9jb25uZWN0aW9uX2Fzc2lnbm1lbnRzGAEgAygLMj4uZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdu
bWVudFIfZ29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50cxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hh
YmxlIoQBCihHZXRHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRSZXF1ZXN0ElgKBG5h
bWUYASABKAlCROBBAvpBPgo8b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vR29sZGVu
Z2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50UgRuYW1lIpsDCitDcmVhdGVHb2xkZW5nYXRlQ29u
bmVjdGlvbkFzc2lnbm1lbnRSZXF1ZXN0ElwKBnBhcmVudBgBIAEoCUJE4EEC+kE+EjxvcmFj
bGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9Hb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1l
bnRSBnBhcmVudBJSCiNnb2xkZW5nYXRlX2Nvbm5lY3Rpb25fYXNzaWdubWVudF9pZBgCIAEo
CUID4EECUiBnb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRJZBKNAQogZ29sZGVuZ2F0
ZV9jb25uZWN0aW9uX2Fzc2lnbm1lbnQYAyABKAsyPi5nb29nbGUuY2xvdWQub3JhY2xlZGF0
YWJhc2UudjEuR29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50QgPgQQJSHmdvbGRlbmdh
dGVDb25uZWN0aW9uQXNzaWdubWVudBIqCgpyZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBB
AVIJcmVxdWVzdElkIqYCCilUZXN0R29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50UmVx
dWVzdBJYCgRuYW1lGAEgASgJQkTgQQL6QT4KPG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMu
Y29tL0dvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudFIEbmFtZRJrCgR0eXBlGAIgASgO
MlIuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLlRlc3RHb2xkZW5nYXRlQ29ubmVj
dGlvbkFzc2lnbm1lbnRSZXF1ZXN0LlRlc3RUeXBlQgPgQQFSBHR5cGUiMgoIVGVzdFR5cGUS
GQoVVEVTVF9UWVBFX1VOU1BFQ0lGSUVEEAASCwoHREVGQVVMVBABInsKHVRlc3RDb25uZWN0
aW9uQXNzaWdubWVudEVycm9yEhIKBGNvZGUYASABKAlSBGNvZGUSGAoHbWVzc2FnZRgCIAEo
CVIHbWVzc2FnZRIWCgZhY3Rpb24YAyABKAlSBmFjdGlvbhIUCgVpc3N1ZRgEIAEoCVIFaXNz
dWUipQMKKlRlc3RHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRSZXNwb25zZRJ2Cgty
ZXN1bHRfdHlwZRgBIAEoDjJVLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5UZXN0
R29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50UmVzcG9uc2UuUmVzdWx0VHlwZVIKcmVz
dWx0VHlwZRJTCgVlcnJvchgCIAEoCzI9Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52
MS5UZXN0Q29ubmVjdGlvbkFzc2lnbm1lbnRFcnJvclIFZXJyb3ISVQoGZXJyb3JzGAMgAygL
Mj0uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLlRlc3RDb25uZWN0aW9uQXNzaWdu
bWVudEVycm9yUgZlcnJvcnMiUwoKUmVzdWx0VHlwZRIbChdSRVNVTFRfVFlQRV9VTlNQRUNJ
RklFRBAAEg0KCVNVQ0NFRURFRBABEgoKBkZBSUxFRBACEg0KCVRJTUVEX09VVBADIqsCCitV
cGRhdGVHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRSZXF1ZXN0EkAKC3VwZGF0ZV9t
YXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNr
Eo0BCiBnb2xkZW5nYXRlX2Nvbm5lY3Rpb25fYXNzaWdubWVudBgCIAEoCzI+Lmdvb2dsZS5j
bG91ZC5vcmFjbGVkYXRhYmFzZS52MS5Hb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRC
A+BBAlIeZ29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50EioKCnJlcXVlc3RfaWQYAyAB
KAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQiswEKK0RlbGV0ZUdvbGRlbmdhdGVDb25uZWN0
aW9uQXNzaWdubWVudFJlcXVlc3QSWAoEbmFtZRgBIAEoCUJE4EEC+kE+CjxvcmFjbGVkYXRh
YmFzZS5nb29nbGVhcGlzLmNvbS9Hb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRSBG5h
bWUSKgoKcmVxdWVzdF9pZBgCIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZEL9AQoiY29t
Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MUIjR29sZGVuZ2F0ZUNvbm5lY3Rpb25B
c3NpZ25tZW50UHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9vcmFjbGVkYXRhYmFzZS9h
cGl2MS9vcmFjbGVkYXRhYmFzZXBiO29yYWNsZWRhdGFiYXNlcGKqAh5Hb29nbGUuQ2xvdWQu
T3JhY2xlRGF0YWJhc2UuVjHKAh5Hb29nbGVcQ2xvdWRcT3JhY2xlRGF0YWJhc2VcVjHqAiFH
b29nbGU6OkNsb3VkOjpPcmFjbGVEYXRhYmFzZTo6VjFK0mUKBxIFDgDlAgEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARID
EwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKgoJCgIDBBIDFgApCggKAQgSAxgAOwoJCgIIJRID
GAA7CggKAQgSAxkAYQoJCgIICxIDGQBhCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsA
RAoJCgIICBIDGwBECggKAQgSAxwAOwoJCgIIARIDHAA7CggKAQgSAx0AOwoJCgIIKRIDHQA7
CggKAQgSAx4AOgoJCgIILRIDHgA6CkwKAgQAEgQhAEUBGkAgUmVwcmVzZW50cyB0aGUgbWV0
YWRhdGEgb2YgYSBHb2xkZW5nYXRlIENvbm5lY3Rpb24gQXNzaWdubWVudC4KCgoKAwQAARID
IQgmCgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBArXAQoEBAACABIDLAI9GskBIElkZW50
aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnQg
cmVzb3VyY2UgaW4gdGhlCiBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97cmVnaW9ufS9nb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRzL3tn
b2xkZW5nYXRlX2Nvbm5lY3Rpb25fYXNzaWdubWVudH0KCgwKBQQAAgAFEgMsAggKDAoFBAAC
AAESAywJDQoMCgUEAAIAAxIDLBARCgwKBQQAAgAIEgMsEjwKDwoIBAACAAicCAASAywTOwpa
CgQEAAIBEgQvAjIEGkwgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHByb3BlcnRpZXMgb2Yg
dGhlIEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudC4KCgwKBQQAAgEGEgMvAioKDAoF
BAACAQESAy8rNQoMCgUEAAIBAxIDLzg5Cg0KBQQAAgEIEgQvOjIDCg8KCAQAAgEInAgAEgMw
BCoKDwoIBAACAQicCAESAzEEKwpRCgQEAAICEgQ1AjYyGkMgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHdoZW4gdGhlIGNvbm5lY3Rpb24gYXNzaWdubWVudCB3YXMgY3JlYXRlZC4KCgwKBQQA
AgIGEgM1AhsKDAoFBAACAgESAzUcJwoMCgUEAAICAxIDNSorCgwKBQQAAgIIEgM2BjEKDwoI
BAACAgicCAASAzYHMApgCgQEAAIDEgM6AkoaUyBPcHRpb25hbC4gVGhlIGxhYmVscyBvciB0
YWdzIGFzc29jaWF0ZWQgd2l0aCB0aGUKIEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVu
dC4KCgwKBQQAAgMGEgM6AhUKDAoFBAACAwESAzoWHAoMCgUEAAIDAxIDOh8gCgwKBQQAAgMI
EgM6IUkKDwoIBAACAwicCAASAzoiSApeCgQEAAIEEgQ+AkEEGlAgT3B0aW9uYWwuIEltbXV0
YWJsZS4gVGhlIGRpc3BsYXkgbmFtZSBmb3IgdGhlCiBHb2xkZW5nYXRlQ29ubmVjdGlvbkFz
c2lnbm1lbnQuCgoMCgUEAAIEBRIDPgIICgwKBQQAAgQBEgM+CRUKDAoFBAACBAMSAz4YGQoN
CgUEAAIECBIEPhpBAwoPCggEAAIECJwIABIDPwQqCg8KCAQAAgQInAgBEgNABCsKUAoEBAAC
BRIDRAJIGkMgT3V0cHV0IG9ubHkuIFRoZSBPQ0lEIG9mIHRoZSBlbnRpdGxlbWVudCBsaW5r
ZWQgdG8gdGhpcyByZXNvdXJjZS4KCgwKBQQAAgUFEgNEAggKDAoFBAACBQESA0QJFwoMCgUE
AAIFAxIDRBobCgwKBQQAAgUIEgNEHEcKDwoIBAACBQicCAASA0QdRgpBCgIEARIESAB8ARo1
IFRoZSBwcm9wZXJ0aWVzIG9mIGEgR29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50LgoK
CgoDBAEBEgNICDAKRQoEBAEEABIESgJcAxo3IFBvc3NpYmxlIGxpZmVjeWNsZSBzdGF0ZXMg
Zm9yIGNvbm5lY3Rpb24gYXNzaWdubWVudHMuCgoMCgUEAQQAARIDSgcMCjAKBgQBBAACABID
TAQaGiEgTGlmZWN5Y2xlIHN0YXRlIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDTAQV
Cg4KBwQBBAACAAISA0wYGQo4CgYEAQQAAgESA08EERopIENvbm5lY3Rpb24gYXNzaWdubWVu
dCBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAEEAAIBARIDTwQMCg4KBwQBBAACAQISA08PEAox
CgYEAQQAAgISA1IEDxoiIENvbm5lY3Rpb24gYXNzaWdubWVudCBpcyBhY3RpdmUuCgoOCgcE
AQQAAgIBEgNSBAoKDgoHBAEEAAICAhIDUg0OCi4KBgQBBAACAxIDVQQPGh8gQ29ubmVjdGlv
biBhc3NpZ25tZW50IGZhaWxlZC4KCg4KBwQBBAACAwESA1UECgoOCgcEAQQAAgMCEgNVDQ4K
OAoGBAEEAAIEEgNYBBEaKSBDb25uZWN0aW9uIGFzc2lnbm1lbnQgaXMgYmVpbmcgdXBkYXRl
ZC4KCg4KBwQBBAACBAESA1gEDAoOCgcEAQQAAgQCEgNYDxAKOAoGBAEEAAIFEgNbBBEaKSBD
b25uZWN0aW9uIGFzc2lnbm1lbnQgaXMgYmVpbmcgZGVsZXRlZC4KCg4KBwQBBAACBQESA1sE
DAoOCgcEAQQAAgUCEgNbDxAKoAEKBAQBAgASA2ECPhqSASBPdXRwdXQgb25seS4gVGhlCiBb
T0NJRF0oaHR0cHM6Ly9kb2NzLmNsb3VkLm9yYWNsZS5jb20vQ29udGVudC9HZW5lcmFsL0Nv
bmNlcHRzL2lkZW50aWZpZXJzLmh0bSkKIG9mIHRoZSBjb25uZWN0aW9uIGFzc2lnbm1lbnQg
YmVpbmcgcmVmZXJlbmNlZC4KCgwKBQQBAgAFEgNhAggKDAoFBAECAAESA2EJDQoMCgUEAQIA
AxIDYRARCgwKBQQBAgAIEgNhEj0KDwoIBAECAAicCAASA2ETPAqsAQoEBAECARIEZgJrBBqd
ASBSZXF1aXJlZC4gVGhlIEdvbGRlbmdhdGVDb25uZWN0aW9uIHJlc291cmNlIHRvIGJlIGFz
c2lnbmVkLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2dvbGRlbmdhdGVDb25uZWN0aW9ucy97Z29sZGVuZ2F0ZV9jb25uZWN0aW9ufQoKDAoF
BAECAQUSA2YCCAoMCgUEAQIBARIDZgkeCgwKBQQBAgEDEgNmISIKDQoFBAECAQgSBGYjawMK
DwoIBAECAQicCAASA2cEKgoPCgcEAQIBCJ8IEgRoBGoFCrABCgQEAQICEgRwAnUEGqEBIFJl
cXVpcmVkLiBUaGUgR29sZGVuR2F0ZURlcGxveW1lbnQgdG8gYXNzaWduIHRoZSBjb25uZWN0
aW9uIHRvLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2dvbGRlbmdhdGVEZXBsb3ltZW50cy97Z29sZGVuZ2F0ZV9kZXBsb3ltZW50fQoKDAoF
BAECAgUSA3ACCAoMCgUEAQICARIDcAkeCgwKBQQBAgIDEgNwISIKDQoFBAECAggSBHAjdQMK
DwoIBAECAgicCAASA3EEKgoPCgcEAQICCJ8IEgRyBHQFCjMKBAQBAgMSA3gCPxomIE91dHB1
dCBvbmx5LiBDcmVkZW50aWFsIHN0b3JlIGFsaWFzLgoKDAoFBAECAwUSA3gCCAoMCgUEAQID
ARIDeAkOCgwKBQQBAgMDEgN4ERIKDAoFBAECAwgSA3gTPgoPCggEAQIDCJwIABIDeBQ9Ck0K
BAQBAgQSA3sCPhpAIE91dHB1dCBvbmx5LiBUaGUgbGlmZWN5Y2xlIHN0YXRlIG9mIHRoZSBj
b25uZWN0aW9uIGFzc2lnbm1lbnQuCgoMCgUEAQIEBhIDewIHCgwKBQQBAgQBEgN7CA0KDAoF
BAECBAMSA3sQEQoMCgUEAQIECBIDexI9Cg8KCAQBAgQInAgAEgN7EzwKSwoCBAISBX8AnwEB
Gj4gUmVxdWVzdCBtZXNzYWdlIGZvciBsaXN0aW5nIEdvbGRlbmdhdGVDb25uZWN0aW9uQXNz
aWdubWVudHMuCgoKCgMEAgESA38IMgqGAQoEBAICABIGggEChwEEGnYgUmVxdWlyZWQuIFRo
ZSBwYXJlbnQgdmFsdWUgZm9yIHRoZSBHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRz
LgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCg0K
BQQCAgAFEgSCAQIICg0KBQQCAgABEgSCAQkPCg0KBQQCAgADEgSCARITCg8KBQQCAgAIEgaC
ARSHAQMKEAoIBAICAAicCAASBIMBBCoKEQoHBAICAAifCBIGhAEEhgEFCp8CCgQEAgIBEgSN
AQI/GpACIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgR29sZGVuZ2F0ZUNvbm5l
Y3Rpb25Bc3NpZ25tZW50cyB0byByZXR1cm4uCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZl
d2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgNTAKIEdvbGRl
bmdhdGVDb25uZWN0aW9uQXNzaWdubWVudHMgd2lsbCBiZSByZXR1cm5lZC4gVGhlIG1heGlt
dW0gdmFsdWUgaXMKIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0
byAxMDAwLgoKDQoFBAICAQUSBI0BAgcKDQoFBAICAQESBI0BCBEKDQoFBAICAQMSBI0BFBUK
DQoFBAICAQgSBI0BFj4KEAoIBAICAQicCAASBI0BFz0KqwIKBAQCAgISBJYBAkEanAIgT3B0
aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdEdv
bGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudHNgIGNhbGwuIFByb3ZpZGUgdGhpcyB0byBy
ZXRyaWV2ZSB0aGUKIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBv
dGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgTGlzdEdvbGRlbmdhdGVDb25uZWN0aW9u
QXNzaWdubWVudHNgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZAogdGhlIHBh
Z2UgdG9rZW4uCgoNCgUEAgICBRIElgECCAoNCgUEAgICARIElgEJEwoNCgUEAgICAxIElgEW
FwoNCgUEAgICCBIElgEYQAoQCggEAgICCJwIABIElgEZPwpzCgQEAgIDEgSaAQI9GmUgT3B0
aW9uYWwuIEEgZmlsdGVyIGV4cHJlc3Npb24gdGhhdCBmaWx0ZXJzIEdvbGRlbmdhdGVDb25u
ZWN0aW9uQXNzaWdubWVudHMKIGxpc3RlZCBpbiB0aGUgcmVzcG9uc2UuCgoNCgUEAgIDBRIE
mgECCAoNCgUEAgIDARIEmgEJDwoNCgUEAgIDAxIEmgESEwoNCgUEAgIDCBIEmgEUPAoQCggE
AgIDCJwIABIEmgEVOwqSAQoEBAICBBIEngECPxqDASBPcHRpb25hbC4gQSBjb21tYS1zZXBh
cmF0ZWQgbGlzdCBvZiBmaWVsZHMgdG8gb3JkZXIgYnksIHNvcnRlZCBpbiBhc2NlbmRpbmcK
IG9yZGVyLiBVc2UgIkRFU0MiIGFmdGVyIGEgZmllbGQgbmFtZSBmb3IgZGVzY2VuZGluZy4K
Cg0KBQQCAgQFEgSeAQIICg0KBQQCAgQBEgSeAQkRCg0KBQQCAgQDEgSeARQVCg0KBQQCAgQI
EgSeARY+ChAKCAQCAgQInAgAEgSeARc9Ck0KAgQDEgaiAQCtAQEaPyBSZXNwb25zZSBtZXNz
YWdlIGZvciBsaXN0aW5nIEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudHMuCgoLCgME
AwESBKIBCDMKPAoEBAMCABIEpAECUBouIFRoZSBsaXN0IG9mIEdvbGRlbmdhdGVDb25uZWN0
aW9uQXNzaWdubWVudHMuCgoNCgUEAwIABBIEpAECCgoNCgUEAwIABhIEpAELKQoNCgUEAwIA
ARIEpAEqSwoNCgUEAwIAAxIEpAFOTwqQAQoEBAMCARIEqAECHRqBASBBIHRva2VuLCB3aGlj
aCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQg
cGFnZXMuCgoNCgUEAwIBBRIEqAECCAoNCgUEAwIBARIEqAEJGAoNCgUEAwIBAxIEqAEbHApv
CgQEAwICEgSsAQIiGmEgVW5yZWFjaGFibGUgbG9jYXRpb25zIHdoZW4gbGlzdGluZyByZXNv
dXJjZXMgYWNyb3NzIGFsbCBsb2NhdGlvbnMgdXNpbmcKIHdpbGRjYXJkIGxvY2F0aW9uICct
Jy4KCg0KBQQDAgIEEgSsAQIKCg0KBQQDAgIFEgSsAQsRCg0KBQQDAgIBEgSsARIdCg0KBQQD
AgIDEgSsASAhCk0KAgQEEgawAQC6AQEaPyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGdldHRpbmcg
YSBHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnQuCgoLCgMEBAESBLABCDAKzQEKBAQE
AgASBrQBArkBBBq8ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIEdvbGRlbmdhdGVDb25u
ZWN0aW9uQXNzaWdubWVudCB0byByZXRyaWV2ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9nb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1l
bnRzL3tnb2xkZW5nYXRlX2Nvbm5lY3Rpb25fYXNzaWdubWVudH0KCg0KBQQEAgAFEgS0AQII
Cg0KBQQEAgABEgS0AQkNCg0KBQQEAgADEgS0ARARCg8KBQQEAgAIEga0ARK5AQMKEAoIBAQC
AAicCAASBLUBBCoKEQoHBAQCAAifCBIGtgEEuAEFCk4KAgQFEga9AQDgAQEaQCBSZXF1ZXN0
IG1lc3NhZ2UgZm9yIGNyZWF0aW5nIGEgR29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50
LgoKCwoDBAUBEgS9AQgzCpwBCgQEBQIAEgbAAQLFAQQaiwEgUmVxdWlyZWQuIFRoZSBwYXJl
bnQgcmVzb3VyY2Ugd2hlcmUgdGhpcyBHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnQK
IHdpbGwgYmUgY3JlYXRlZC4gRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0KCg0KBQQFAgAFEgTAAQIICg0KBQQFAgABEgTAAQkPCg0KBQQFAgADEgTA
ARITCg8KBQQFAgAIEgbAARTFAQMKEAoIBAUCAAicCAASBMEBBCoKEQoHBAUCAAifCBIGwgEE
xAEFClMKBAQFAgESBsgBAskBLxpDIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIEdvbGRlbmdh
dGVDb25uZWN0aW9uQXNzaWdubWVudCB0byBjcmVhdGUuCgoNCgUEBQIBBRIEyAECCAoNCgUE
BQIBARIEyAEJLAoNCgUEBQIBAxIEyAEvMAoNCgUEBQIBCBIEyQEGLgoQCggEBQIBCJwIABIE
yQEHLQpJCgQEBQICEgbMAQLNAS8aOSBSZXF1aXJlZC4gVGhlIEdvbGRlbmdhdGVDb25uZWN0
aW9uQXNzaWdubWVudCB0byBjcmVhdGUuCgoNCgUEBQICBhIEzAECIAoNCgUEBQICARIEzAEh
QQoNCgUEBQICAxIEzAFERQoNCgUEBQICCBIEzQEGLgoQCggEBQICCJwIABIEzQEHLQqRBgoE
BAUCAxIG3AEC3wEEGoAGIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlk
ZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQg
aWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0
bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVk
LiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51
dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBh
IHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kIHRoZQog
cmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGgg
dGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFs
IG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5k
IGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMK
IGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1l
bnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4
Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAw
MC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQFAgMFEgTcAQIICg0KBQQFAgMBEgTc
AQkTCg0KBQQFAgMDEgTcARYXCg8KBQQFAgMIEgbcARjfAQMKEwoLBAUCAwjM8fmKAQESBN0B
BCoKEAoIBAUCAwicCAASBN4BBCoKRwoCBAYSBuMBAPkBARo5IFJlcXVlc3QgbWVzc2FnZSBm
b3IgVGVzdEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudC4KCgsKAwQGARIE4wEIMQou
CgQEBgQAEgblAQLrAQMaHiBUaGUgdHlwZSBvZiB0ZXN0IHRvIHBlcmZvcm0uCgoNCgUEBgQA
ARIE5QEHDwo6CgYEBgQAAgASBOcBBB4aKiBUaGUgZGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1
ZSBpcyB1bnVzZWQuCgoPCgcEBgQAAgABEgTnAQQZCg8KBwQGBAACAAISBOcBHB0KLgoGBAYE
AAIBEgTqAQQQGh4gVGhlIGRlZmF1bHQgY29ubmVjdGlvbiB0ZXN0LgoKDwoHBAYEAAIBARIE
6gEECwoPCgcEBgQAAgECEgTqAQ4PCsYBCgQEBgIAEgbvAQL0AQQatQEgUmVxdWlyZWQuIE5h
bWUgb2YgdGhlIGNvbm5lY3Rpb24gYXNzaWdubWVudCBmb3Igd2hpY2ggdG8gdGVzdCBjb25u
ZWN0aW9uLgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97cmVnaW9ufS9nb2xkZW5n
YXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRzL3tnb2xkZW5nYXRlX2Nvbm5lY3Rpb25fYXNzaWdu
bWVudH0KCg0KBQQGAgAFEgTvAQIICg0KBQQGAgABEgTvAQkNCg0KBQQGAgADEgTvARARCg8K
BQQGAgAIEgbvARL0AQMKEAoIBAYCAAicCAASBPABBCoKEQoHBAYCAAifCBIG8QEE8wEFCngK
BAQGAgESBPgBAj0aaiBPcHRpb25hbC4gVGhlIHR5cGUgb2YgdGhlIHRlc3Qgb2YgdGhlIGFz
c2lnbmVkIGNvbm5lY3Rpb24uCiBUaGUgb25seSB0eXBlIGFjdHVhbGx5IHN1cHBvcnRlZCBp
cyBERUZBVUxULgoKDQoFBAYCAQYSBPgBAgoKDQoFBAYCAQESBPgBCw8KDQoFBAYCAQMSBPgB
EhMKDQoFBAYCAQgSBPgBFDwKEAoIBAYCAQicCAASBPgBFTsKRQoCBAcSBvwBAIgCARo3IEVy
cm9yIGRldGFpbHMgZm9yIFRlc3RHb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnQuCgoL
CgMEBwESBPwBCCUKWgoEBAcCABIE/gECEhpMIEEgc2hvcnQgZXJyb3IgY29kZSB0aGF0IGRl
ZmluZXMgdGhlIGVycm9yLCBtZWFudCBmb3IgcHJvZ3JhbW1hdGljIHBhcnNpbmcuCgoNCgUE
BwIABRIE/gECCAoNCgUEBwIAARIE/gEJDQoNCgUEBwIAAxIE/gEQEQovCgQEBwIBEgSBAgIV
GiEgQSBodW1hbi1yZWFkYWJsZSBlcnJvciBtZXNzYWdlLgoKDQoFBAcCAQUSBIECAggKDQoF
BAcCAQESBIECCRAKDQoFBAcCAQMSBIECExQKSQoEBAcCAhIEhAICFBo7IFRoZSB0ZXh0IGRl
c2NyaWJpbmcgdGhlIGFjdGlvbiByZXF1aXJlZCB0byBmaXggdGhlIGlzc3VlLgoKDQoFBAcC
AgUSBIQCAggKDQoFBAcCAgESBIQCCQ8KDQoFBAcCAgMSBIQCEhMKSQoEBAcCAxIEhwICExo7
IFRoZSB0ZXh0IGRlc2NyaWJpbmcgdGhlIHJvb3QgY2F1c2Ugb2YgdGhlIHJlcG9ydGVkIGlz
c3VlLgoKDQoFBAcCAwUSBIcCAggKDQoFBAcCAwESBIcCCQ4KDQoFBAcCAwMSBIcCERIKhwEK
AgQIEgaMAgCkAgEaeSBUaGUgcmVzdWx0IG9mIHRoZSBjb25uZWN0aXZpdHkgdGVzdCBwZXJm
b3JtZWQgYmV0d2VlbiB0aGUgR29sZGVuZ2F0ZQogZGVwbG95bWVudCBhbmQgdGhlIGFzc29j
aWF0ZWQgZGF0YWJhc2UgLyBzZXJ2aWNlLgoKCwoDBAgBEgSMAggyCiUKBAQIBAASBo4CApoC
AxoVIFR5cGUgb2YgdGhlIHJlc3VsdC4KCg0KBQQIBAABEgSOAgcRCi0KBgQIBAACABIEkAIE
IBodIFJlc3VsdCB0eXBlIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAgEAAIAARIEkAIEGwoPCgcE
CAQAAgACEgSQAh4fCiwKBgQIBAACARIEkwIEEhocIFRlc3QgY29ubmVjdGlvbiBzdWNjZWVk
ZWQuCgoPCgcECAQAAgEBEgSTAgQNCg8KBwQIBAACAQISBJMCEBEKKQoGBAgEAAICEgSWAgQP
GhkgVGVzdCBjb25uZWN0aW9uIGZhaWxlZC4KCg8KBwQIBAACAgESBJYCBAoKDwoHBAgEAAIC
AhIElgINDgosCgYECAQAAgMSBJkCBBIaHCBUZXN0IGNvbm5lY3Rpb24gdGltZWQgb3V0LgoK
DwoHBAgEAAIDARIEmQIEDQoPCgcECAQAAgMCEgSZAhARCkQKBAQIAgASBJ0CAh0aNiBUeXBl
IG9mIHRoZSByZXN1bHQgaS5lLiBTdWNjZXNzLCBGYWlsdXJlIG9yIFRpbWVvdXQuCgoNCgUE
CAIABhIEnQICDAoNCgUECAIAARIEnQINGAoNCgUECAIAAxIEnQIbHAo4CgQECAIBEgSgAgIq
GiogRXJyb3IgZGV0YWlscyBpZiB0ZXN0IGNvbm5lY3Rpb24gZmFpbGVkLgoKDQoFBAgCAQYS
BKACAh8KDQoFBAgCAQESBKACICUKDQoFBAgCAQMSBKACKCkKQQoEBAgCAhIEowICNBozIExp
c3Qgb2YgdGVzdCBjb25uZWN0aW9uIGFzc2lnbm1lbnQgZXJyb3Igb2JqZWN0cy4KCg0KBQQI
AgIEEgSjAgIKCg0KBQQIAgIGEgSjAgsoCg0KBQQIAgIBEgSjAikvCg0KBQQIAgIDEgSjAjIz
Ck4KAgQJEganAgDGAgEaQCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHVwZGF0aW5nIGEgR29sZGVu
Z2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50LgoKCwoDBAkBEgSnAggzCowDCgQECQIAEgauAgKv
Ai8a+wIgT3B0aW9uYWwuIEEgbWFzayBzcGVjaWZ5aW5nIHdoaWNoIGZpZWxkcyBpbiB0aGUK
IEdvbGRlbmdhdGVDb25uZWN0aW9uQXNzaWdubWVudCBzaG91bGQgYmUgdXBkYXRlZC4gQSBm
aWVsZCBzcGVjaWZpZWQgaW4gdGhlCiBtYXNrIGlzIHVwZGF0ZWQuIElmIGEgbWFzayBpc24n
dCBwcm92aWRlZCwgdGhlIHNlcnZpY2UgdHJlYXRzIHRoaXMgYXMgYW4KIGltcGxpZWQgZmll
bGQgbWFzayBlcXVpdmFsZW50IHRvIGFsbCBmaWVsZHMgdGhhdCBhcmUgcG9wdWxhdGVkICho
YXZlIGEKIG5vbi1lbXB0eSB2YWx1ZSkuIFRvIGNsZWFyIG9yIHVuc2V0IGEgZmllbGQsIHRo
ZSBmaWVsZCBtdXN0IGJlIGV4cGxpY2l0bHkKIHNwZWNpZmllZCBpbiB0aGUgYHVwZGF0ZV9t
YXNrYC4KCg0KBQQJAgAGEgSuAgIbCg0KBQQJAgABEgSuAhwnCg0KBQQJAgADEgSuAiorCg0K
BQQJAgAIEgSvAgYuChAKCAQJAgAInAgAEgSvAgctCrIDCgQECQIBEga3AgK4Ai8aoQMgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBiZWluZyB1cGRhdGVkLiBOb3RlIG9ubHkgbGFiZWxzIGNh
biBiZSB1cGRhdGVkLgogVGhlIHByb3ZpZGVkIGxhYmVscyB3aWxsIGNvbXBsZXRlbHkgcmVw
bGFjZSB0aGUgZXhpc3RpbmcgbGFiZWxzLgogQW55IGV4aXN0aW5nIGxhYmVsIGtleXMgdGhh
dCBhcmUgbm90IGluY2x1ZGVkIGluIHRoZSB1cGRhdGUgcmVxdWVzdCB3aWxsIGJlCiBkZWxl
dGVkLiBOb3QgcHJvdmlkaW5nIGxhYmVscyBhbmQgdXBkYXRlX21hc2sgd2lsbCBub3QgdXBk
YXRlIHRoZSBsYWJlbHMuCiBUbyBjbGVhciBhbGwgbGFiZWxzLCBzcGVjaWZ5IGBsYWJlbHNg
IGluIHRoZSBgdXBkYXRlX21hc2tgIGFuZCBvbWl0IG9yCiBsZWF2ZSB0aGUgYGxhYmVsc2Ag
ZmllbGQgZW1wdHkgaW4gdGhlIHVwZGF0ZSByZXF1ZXN0LgoKDQoFBAkCAQYSBLcCAiAKDQoF
BAkCAQESBLcCIUEKDQoFBAkCAQMSBLcCREUKDQoFBAkCAQgSBLgCBi4KEAoIBAkCAQicCAAS
BLgCBy0K1wMKBAQJAgISBsICAsUCBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8g
aWRlbnRpZnkgdGhlIHJlcXVlc3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkg
ZHVwbGljYXRlIHJlcXVlc3RzLiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2Ft
ZSByZXF1ZXN0IElECiBhbmQgdGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJv
Z3Jlc3Mgb3IgY29tcGxldGVkLCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVx
dWVzdC4gVGhpcyBwcmV2ZW50cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGlu
ZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZh
bGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3Vw
cG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAkC
AgUSBMICAggKDQoFBAkCAgESBMICCRMKDQoFBAkCAgMSBMICFhcKDwoFBAkCAggSBsICGMUC
AwoTCgsECQICCMzx+YoBARIEwwIEKgoQCggECQICCJwIABIExAIEKgpOCgIEChIGyQIA5QIB
GkAgUmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIEdvbGRlbmdhdGVDb25uZWN0aW9u
QXNzaWdubWVudC4KCgsKAwQKARIEyQIIMwrLAQoEBAoCABIGzQIC0gIEGroBIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgR29sZGVuZ2F0ZUNvbm5lY3Rpb25Bc3NpZ25tZW50IHRvIGRl
bGV0ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9nb2xkZW5nYXRlQ29ubmVjdGlvbkFzc2lnbm1lbnRzL3tnb2xkZW5nYXRlX2Nvbm5lY3Rp
b25fYXNzaWdubWVudH0KCg0KBQQKAgAFEgTNAgIICg0KBQQKAgABEgTNAgkNCg0KBQQKAgAD
EgTNAhARCg8KBQQKAgAIEgbNAhLSAgMKEAoIBAoCAAicCAASBM4CBCoKEQoHBAoCAAifCBIG
zwIE0QIFCpEGCgQECgIBEgbhAgLkAgQagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVl
c3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3Qg
SUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIg
d2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVl
biBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxl
YXN0IDYwIG1pbnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUs
IGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVz
dCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3Qg
YWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sg
aWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJl
Y2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhp
cyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNh
dGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQg
d2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgw
MDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAoCAQUSBOECAggK
DQoFBAoCAQESBOECCRMKDQoFBAoCAQMSBOECFhcKDwoFBAoCAQgSBuECGOQCAwoTCgsECgIB
CMzx+YoBARIE4gIEKgoQCggECgIBCJwIABIE4wIEKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment ===
    # Fields for GoldengateConnectionAssignment
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.GoldengateConnectionAssignmentProperties)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.GoldengateConnectionAssignment.LabelsEntry)
    # Field: display_name Type: 9 ()
    # Field: entitlement_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignmentProperties ===
    # Fields for GoldengateConnectionAssignmentProperties
    # Field: ocid Type: 9 ()
    # Field: goldengate_connection Type: 9 ()
    # Field: goldengate_deployment Type: 9 ()
    # Field: alias Type: 9 ()
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.GoldengateConnectionAssignmentProperties.State)

# Enum: GoldengateConnectionAssignmentProperties::State
our $GoldengateConnectionAssignmentProperties_STATE_UNSPECIFIED = 0;
our $GoldengateConnectionAssignmentProperties_CREATING = 1;
our $GoldengateConnectionAssignmentProperties_ACTIVE = 2;
our $GoldengateConnectionAssignmentProperties_FAILED = 3;
our $GoldengateConnectionAssignmentProperties_UPDATING = 4;
our $GoldengateConnectionAssignmentProperties_DELETING = 5;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsRequest ===
    # Fields for ListGoldengateConnectionAssignmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsResponse ===
    # Fields for ListGoldengateConnectionAssignmentsResponse
    # Field: goldengate_connection_assignments Type: 11 (.google.cloud.oracledatabase.v1.GoldengateConnectionAssignment)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GetGoldengateConnectionAssignmentRequest ===
    # Fields for GetGoldengateConnectionAssignmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::CreateGoldengateConnectionAssignmentRequest ===
    # Fields for CreateGoldengateConnectionAssignmentRequest
    # Field: parent Type: 9 ()
    # Field: goldengate_connection_assignment_id Type: 9 ()
    # Field: goldengate_connection_assignment Type: 11 (.google.cloud.oracledatabase.v1.GoldengateConnectionAssignment)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentRequest ===
    # Fields for TestGoldengateConnectionAssignmentRequest
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.oracledatabase.v1.TestGoldengateConnectionAssignmentRequest.TestType)

# Enum: TestGoldengateConnectionAssignmentRequest::TestType
our $TestGoldengateConnectionAssignmentRequest_TEST_TYPE_UNSPECIFIED = 0;
our $TestGoldengateConnectionAssignmentRequest_DEFAULT = 1;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError ===
    # Fields for TestConnectionAssignmentError
    # Field: code Type: 9 ()
    # Field: message Type: 9 ()
    # Field: action Type: 9 ()
    # Field: issue Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentResponse ===
    # Fields for TestGoldengateConnectionAssignmentResponse
    # Field: result_type Type: 14 (.google.cloud.oracledatabase.v1.TestGoldengateConnectionAssignmentResponse.ResultType)
    # Field: error Type: 11 (.google.cloud.oracledatabase.v1.TestConnectionAssignmentError)
    # Field: errors Type: 11 (.google.cloud.oracledatabase.v1.TestConnectionAssignmentError)

# Enum: TestGoldengateConnectionAssignmentResponse::ResultType
our $TestGoldengateConnectionAssignmentResponse_RESULT_TYPE_UNSPECIFIED = 0;
our $TestGoldengateConnectionAssignmentResponse_SUCCEEDED = 1;
our $TestGoldengateConnectionAssignmentResponse_FAILED = 2;
our $TestGoldengateConnectionAssignmentResponse_TIMED_OUT = 3;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::UpdateGoldengateConnectionAssignmentRequest ===
    # Fields for UpdateGoldengateConnectionAssignmentRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: goldengate_connection_assignment Type: 11 (.google.cloud.oracledatabase.v1.GoldengateConnectionAssignment)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::DeleteGoldengateConnectionAssignmentRequest ===
    # Fields for DeleteGoldengateConnectionAssignmentRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/goldengate_connection_assignment.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment;

    my $msg = Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment->new({
        name => $name,
        properties => $properties,
        create_time => $create_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/goldengate_connection_assignment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment

Represents the metadata of a Goldengate Connection Assignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the GoldengateConnectionAssignment resource in the
following format:
projects/{project}/locations/{region}/goldengateConnectionAssignments/{goldengate_connection_assignment}

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignmentProperties>)

Required. Immutable. The properties of the GoldengateConnectionAssignment.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the connection assignment was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment::LabelsEntry>)

Optional. The labels or tags associated with the
GoldengateConnectionAssignment.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Immutable. The display name for the
GoldengateConnectionAssignment.

=item * C<< $msg->entitlement_id() >> / C<< $msg->entitlement_id($value) >>

Type: C<String>

Output only. The OCID of the entitlement linked to this resource.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignmentProperties

The properties of a GoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. The
[OCID](https://docs.cloud.oracle.com/Content/General/Concepts/identifiers.htm)
of the connection assignment being referenced.

=item * C<< $msg->goldengate_connection() >> / C<< $msg->goldengate_connection($value) >>

Type: C<String>

Required. The GoldengateConnection resource to be assigned.
Format:
projects/{project}/locations/{location}/goldengateConnections/{goldengate_connection}

=item * C<< $msg->goldengate_deployment() >> / C<< $msg->goldengate_deployment($value) >>

Type: C<String>

Required. The GoldenGateDeployment to assign the connection to.
Format:
projects/{project}/locations/{location}/goldengateDeployments/{goldengate_deployment}

=item * C<< $msg->alias() >> / C<< $msg->alias($value) >>

Type: C<String>

Output only. Credential store alias.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignmentProperties::State>)

Output only. The lifecycle state of the connection assignment.

=back

=head3 Enum: GoldengateConnectionAssignmentProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=item * C<UPDATING> => C<4>

=item * C<DELETING> => C<5>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsRequest

Request message for listing GoldengateConnectionAssignments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the GoldengateConnectionAssignments.
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of GoldengateConnectionAssignments to return.
The service may return fewer than this value. If unspecified, at most 50
GoldengateConnectionAssignments will be returned. The maximum value is
1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListGoldengateConnectionAssignments` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`ListGoldengateConnectionAssignments` must match the call that provided
the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters GoldengateConnectionAssignments
listed in the response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields to order by, sorted in ascending
order. Use "DESC" after a field name for descending.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsResponse

Response message for listing GoldengateConnectionAssignments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->goldengate_connection_assignments() >> / C<< $msg->goldengate_connection_assignments($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment>)

The list of GoldengateConnectionAssignments.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable locations when listing resources across all locations using
wildcard location '-'.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GetGoldengateConnectionAssignmentRequest

Request message for getting a GoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the GoldengateConnectionAssignment to retrieve.
Format:
projects/{project}/locations/{location}/goldengateConnectionAssignments/{goldengate_connection_assignment}

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::CreateGoldengateConnectionAssignmentRequest

Request message for creating a GoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this GoldengateConnectionAssignment
will be created. Format: projects/{project}/locations/{location}

=item * C<< $msg->goldengate_connection_assignment_id() >> / C<< $msg->goldengate_connection_assignment_id($value) >>

Type: C<String>

Required. The ID of the GoldengateConnectionAssignment to create.

=item * C<< $msg->goldengate_connection_assignment() >> / C<< $msg->goldengate_connection_assignment($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment>)

Required. The GoldengateConnectionAssignment to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentRequest

Request message for TestGoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the connection assignment for which to test connection.
projects/{project}/locations/{region}/goldengateConnectionAssignments/{goldengate_connection_assignment}

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::TestGoldengateConnectionAssignmentRequest::TestType>)

Optional. The type of the test of the assigned connection.
The only type actually supported is DEFAULT.

=back

=head3 Enum: TestGoldengateConnectionAssignmentRequest::TestType

=over 4

=item * C<TEST_TYPE_UNSPECIFIED> => C<0>

=item * C<DEFAULT> => C<1>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError

Error details for TestGoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

A short error code that defines the error, meant for programmatic parsing.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

A human-readable error message.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

The text describing the action required to fix the issue.

=item * C<< $msg->issue() >> / C<< $msg->issue($value) >>

Type: C<String>

The text describing the root cause of the reported issue.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentResponse

The result of the connectivity test performed between the Goldengate
deployment and the associated database / service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->result_type() >> / C<< $msg->result_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::TestGoldengateConnectionAssignmentResponse::ResultType>)

Type of the result i.e. Success, Failure or Timeout.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError>)

Error details if test connection failed.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError>)

List of test connection assignment error objects.

=back

=head3 Enum: TestGoldengateConnectionAssignmentResponse::ResultType

=over 4

=item * C<RESULT_TYPE_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<FAILED> => C<2>

=item * C<TIMED_OUT> => C<3>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::UpdateGoldengateConnectionAssignmentRequest

Request message for updating a GoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A mask specifying which fields in the
GoldengateConnectionAssignment should be updated. A field specified in the
mask is updated. If a mask isn't provided, the service treats this as an
implied field mask equivalent to all fields that are populated (have a
non-empty value). To clear or unset a field, the field must be explicitly
specified in the `update_mask`.

=item * C<< $msg->goldengate_connection_assignment() >> / C<< $msg->goldengate_connection_assignment($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment>)

Required. The resource being updated. Note only labels can be updated.
The provided labels will completely replace the existing labels.
Any existing label keys that are not included in the update request will be
deleted. Not providing labels and update_mask will not update the labels.
To clear all labels, specify `labels` in the `update_mask` and omit or
leave the `labels` field empty in the update request.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::DeleteGoldengateConnectionAssignmentRequest

Request message for deleting a GoldengateConnectionAssignment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the GoldengateConnectionAssignment to delete.
Format:
projects/{project}/locations/{location}/goldengateConnectionAssignments/{goldengate_connection_assignment}

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
