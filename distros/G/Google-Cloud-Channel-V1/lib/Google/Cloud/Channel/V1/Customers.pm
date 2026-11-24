package Google::Cloud::Channel::V1::Customers;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::PostalAddress };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9jdXN0b21lcnMucHJvdG8SF2dvb2dsZS5jbG91
ZC5jaGFubmVsLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGiRnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9jb21tb24ucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aIGdvb2dsZS90eXBlL3Bvc3Rh
bF9hZGRyZXNzLnByb3RvIqIICghDdXN0b21lchIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUS
LQoQb3JnX2Rpc3BsYXlfbmFtZRgCIAEoCUID4EECUg5vcmdEaXNwbGF5TmFtZRJNChJvcmdf
cG9zdGFsX2FkZHJlc3MYAyABKAsyGi5nb29nbGUudHlwZS5Qb3N0YWxBZGRyZXNzQgPgQQJS
EG9yZ1Bvc3RhbEFkZHJlc3MSVgoUcHJpbWFyeV9jb250YWN0X2luZm8YBCABKAsyJC5nb29n
bGUuY2xvdWQuY2hhbm5lbC52MS5Db250YWN0SW5mb1IScHJpbWFyeUNvbnRhY3RJbmZvEicK
D2FsdGVybmF0ZV9lbWFpbBgFIAEoCVIOYWx0ZXJuYXRlRW1haWwSGwoGZG9tYWluGAYgASgJ
QgPgQQJSBmRvbWFpbhJACgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgIIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIvChFjbG91ZF9pZGVudGl0
eV9pZBgJIAEoCUID4EEDUg9jbG91ZElkZW50aXR5SWQSKAoNbGFuZ3VhZ2VfY29kZRgKIAEo
CUID4EEBUgxsYW5ndWFnZUNvZGUSXwoTY2xvdWRfaWRlbnRpdHlfaW5mbxgMIAEoCzIqLmdv
b2dsZS5jbG91ZC5jaGFubmVsLnYxLkNsb3VkSWRlbnRpdHlJbmZvQgPgQQNSEWNsb3VkSWRl
bnRpdHlJbmZvEiwKEmNoYW5uZWxfcGFydG5lcl9pZBgNIAEoCVIQY2hhbm5lbFBhcnRuZXJJ
ZBIqCg5jb3JyZWxhdGlvbl9pZBgOIAEoCUID4EEBUg1jb3JyZWxhdGlvbklkEn0KGmN1c3Rv
bWVyX2F0dGVzdGF0aW9uX3N0YXRlGBAgASgOMjouZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEu
Q3VzdG9tZXIuQ3VzdG9tZXJBdHRlc3RhdGlvblN0YXRlQgPgQQFSGGN1c3RvbWVyQXR0ZXN0
YXRpb25TdGF0ZSJ0ChhDdXN0b21lckF0dGVzdGF0aW9uU3RhdGUSKgomQ1VTVE9NRVJfQVRU
RVNUQVRJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZFWEVNUFQQARIgChxOT05fRVhFTVBU
X0FORF9JTkZPX1ZFUklGSUVEEAI6UupBTwokY2xvdWRjaGFubmVsLmdvb2dsZWFwaXMuY29t
L0N1c3RvbWVyEidhY2NvdW50cy97YWNjb3VudH0vY3VzdG9tZXJzL3tjdXN0b21lcn0iuAEK
C0NvbnRhY3RJbmZvEh0KCmZpcnN0X25hbWUYASABKAlSCWZpcnN0TmFtZRIbCglsYXN0X25h
bWUYAiABKAlSCGxhc3ROYW1lEiYKDGRpc3BsYXlfbmFtZRgEIAEoCUID4EEDUgtkaXNwbGF5
TmFtZRIUCgVlbWFpbBgFIAEoCVIFZW1haWwSGQoFdGl0bGUYBiABKAlCA+BBAVIFdGl0bGUS
FAoFcGhvbmUYByABKAlSBXBob25lQmYKG2NvbS5nb29nbGUuY2xvdWQuY2hhbm5lbC52MUIO
Q3VzdG9tZXJzUHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9jaGFubmVsL2FwaXYxL2No
YW5uZWxwYjtjaGFubmVscGJKiSoKBxIFDgCJAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAC4K
CQoCAwMSAxUAKQoJCgIDBBIDFgAqCggKAQgSAxgATAoJCgIICxIDGABMCggKAQgSAxkAIgoJ
CgIIChIDGQAiCggKAQgSAxoALwoJCgIICBIDGgAvCggKAQgSAxsANAoJCgIIARIDGwA0CkoK
AgQAEgQeAHEBGj4gRW50aXR5IHJlcHJlc2VudGluZyBhIGN1c3RvbWVyIG9mIGEgcmVzZWxs
ZXIgb3IgZGlzdHJpYnV0b3IuCgoKCgMEAAESAx4IEAoLCgMEAAcSBB8CIgQKDQoFBAAHnQgS
BB8CIgQKSgoEBAAEABIEJQIxAxo8IFRoZSBlbnVtIHJlcHJlc2VudHMgaWYgYSBjdXN0b21l
ciBiZWxvbmdzIHRvIHB1YmxpYyBzZWN0b3IKCgwKBQQABAABEgMlBx8KLQoGBAAEAAIAEgMn
BC8aHiBEZWZhdWx0IHZhbHVlIGlmIG5vdCBzZXQgeWV0CgoOCgcEAAQAAgABEgMnBCoKDgoH
BAAEAAIAAhIDJy0uCrkBCgYEAAQAAgESAywEDxqpASBDdXN0b21lciBpcyBleGVtcHQgZnJv
bSBhdHRlc3RpbmcgYmFzZWQgb24gZXhlbXB0aW9uIGxpc3QgYXQKIGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS90ZXJtcy9kaXJlY3QtdG9zLWV4ZW1wdGlvbnMuIENvbnRhY3QgaW5mb3Jt
YXRpb24KIG9mIGN1c3RvbWVyIHdpbGwgYmUgbWFuZGF0b3J5LgoKDgoHBAAEAAIBARIDLAQK
Cg4KBwQABAACAQISAywNDgqSAQoGBAAEAAICEgMwBCUaggEgQ3VzdG9tZXIgaXMgbm90IGV4
ZW1wdCBhbmQgaGFzIHZlcmlmaWVkIHRoZSBpbmZvcm1hdGlvbiBwcm92aWRlZCBpcwogY29y
cmVjdC4gQ29udGFjdCBpbmZvcm1hdGlvbiBvZiBjdXN0b21lciB3aWxsIGJlIG1hbmRhdG9y
eS4KCg4KBwQABAACAgESAzAEIAoOCgcEAAQAAgICEgMwIyQKcQoEBAACABIDNQI+GmQgT3V0
cHV0IG9ubHkuIFJlc291cmNlIG5hbWUgb2YgdGhlIGN1c3RvbWVyLgogRm9ybWF0OiBhY2Nv
dW50cy97YWNjb3VudF9pZH0vY3VzdG9tZXJzL3tjdXN0b21lcl9pZH0KCgwKBQQAAgAFEgM1
AggKDAoFBAACAAESAzUJDQoMCgUEAAIAAxIDNRARCgwKBQQAAgAIEgM1Ej0KDwoIBAACAAic
CAASAzUTPApWCgQEAAIBEgM4AkcaSSBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgb3JnYW5pemF0
aW9uIHRoYXQgdGhlIGN1c3RvbWVyIGVudGl0eSByZXByZXNlbnRzLgoKDAoFBAACAQUSAzgC
CAoMCgUEAAIBARIDOAkZCgwKBQQAAgEDEgM4HB0KDAoFBAACAQgSAzgeRgoPCggEAAIBCJwI
ABIDOB9FCpoCCgQEAAICEgQ+Aj8vGosCIFJlcXVpcmVkLiBUaGUgb3JnYW5pemF0aW9uIGFk
ZHJlc3MgZm9yIHRoZSBjdXN0b21lci4gVG8gZW5mb3JjZSBVUyBsYXdzIGFuZAogZW1iYXJn
b2VzLCB3ZSByZXF1aXJlIGEgcmVnaW9uLCBwb3N0YWwgY29kZSwgYW5kIGFkZHJlc3MgbGlu
ZXMuIFlvdSBtdXN0CiBwcm92aWRlIHZhbGlkIGFkZHJlc3NlcyBmb3IgZXZlcnkgY3VzdG9t
ZXIuIFRvIHNldCB0aGUgY3VzdG9tZXIncwogbGFuZ3VhZ2UsIHVzZSB0aGUgQ3VzdG9tZXIt
bGV2ZWwgbGFuZ3VhZ2UgY29kZS4KCgwKBQQAAgIGEgM+AhsKDAoFBAACAgESAz4cLgoMCgUE
AAICAxIDPjEyCgwKBQQAAgIIEgM/Bi4KDwoIBAACAgicCAASAz8HLQokCgQEAAIDEgNCAica
FyBQcmltYXJ5IGNvbnRhY3QgaW5mby4KCgwKBQQAAgMGEgNCAg0KDAoFBAACAwESA0IOIgoM
CgUEAAIDAxIDQiUmCuwCCgQEAAIEEgNJAh0a3gIgU2Vjb25kYXJ5IGNvbnRhY3QgZW1haWwu
IFlvdSBuZWVkIHRvIHByb3ZpZGUgYW4gYWx0ZXJuYXRlIGVtYWlsIHRvIGNyZWF0ZQogZGlm
ZmVyZW50IGRvbWFpbnMgaWYgYSBwcmltYXJ5IGNvbnRhY3QgZW1haWwgYWxyZWFkeSBleGlz
dHMuIFVzZXJzIHdpbGwKIHJlY2VpdmUgYSBub3RpZmljYXRpb24gd2l0aCBjcmVkZW50aWFs
cyB3aGVuIHlvdSBjcmVhdGUgYW4gYWRtaW4uZ29vZ2xlLmNvbQogYWNjb3VudC4gU2Vjb25k
YXJ5IGVtYWlscyBhcmUgYWxzbyByZWNvdmVyeSBlbWFpbCBhZGRyZXNzZXMuIEFsdGVybmF0
ZQogZW1haWxzIGFyZSBvcHRpb25hbCB3aGVuIHlvdSBjcmVhdGUgVGVhbSBjdXN0b21lcnMu
CgoMCgUEAAIEBRIDSQIICgwKBQQAAgQBEgNJCRgKDAoFBAACBAMSA0kbHApnCgQEAAIFEgNN
Aj0aWiBSZXF1aXJlZC4gVGhlIGN1c3RvbWVyJ3MgcHJpbWFyeSBkb21haW4uIE11c3QgbWF0
Y2ggdGhlIHByaW1hcnkgY29udGFjdAogZW1haWwncyBkb21haW4uCgoMCgUEAAIFBRIDTQII
CgwKBQQAAgUBEgNNCQ8KDAoFBAACBQMSA00SEwoMCgUEAAIFCBIDTRQ8Cg8KCAQAAgUInAgA
EgNNFTsKQAoEBAACBhIEUAJRMhoyIE91dHB1dCBvbmx5LiBUaW1lIHdoZW4gdGhlIGN1c3Rv
bWVyIHdhcyBjcmVhdGVkLgoKDAoFBAACBgYSA1ACGwoMCgUEAAIGARIDUBwnCgwKBQQAAgYD
EgNQKisKDAoFBAACBggSA1EGMQoPCggEAAIGCJwIABIDUQcwCkAKBAQAAgcSBFQCVTIaMiBP
dXRwdXQgb25seS4gVGltZSB3aGVuIHRoZSBjdXN0b21lciB3YXMgdXBkYXRlZC4KCgwKBQQA
AgcGEgNUAhsKDAoFBAACBwESA1QcJwoMCgUEAAIHAxIDVCorCgwKBQQAAgcIEgNVBjEKDwoI
BAACBwicCAASA1UHMApsCgQEAAIIEgNZAksaXyBPdXRwdXQgb25seS4gVGhlIGN1c3RvbWVy
J3MgQ2xvdWQgSWRlbnRpdHkgSUQgaWYgdGhlIGN1c3RvbWVyIGhhcyBhIENsb3VkCiBJZGVu
dGl0eSByZXNvdXJjZS4KCgwKBQQAAggFEgNZAggKDAoFBAACCAESA1kJGgoMCgUEAAIIAxID
WR0eCgwKBQQAAggIEgNZH0oKDwoIBAACCAicCAASA1kgSQquAQoEBAACCRIDXgJFGqABIE9w
dGlvbmFsLiBUaGUgQkNQLTQ3IGxhbmd1YWdlIGNvZGUsIHN1Y2ggYXMgImVuLVVTIiBvciAi
c3ItTGF0biIuIEZvciBtb3JlCiBpbmZvcm1hdGlvbiwgc2VlCiBodHRwczovL3d3dy51bmlj
b2RlLm9yZy9yZXBvcnRzL3RyMzUvI1VuaWNvZGVfbG9jYWxlX2lkZW50aWZpZXIuCgoMCgUE
AAIJBRIDXgIICgwKBQQAAgkBEgNeCRYKDAoFBAACCQMSA14ZGwoMCgUEAAIJCBIDXhxECg8K
CAQAAgkInAgAEgNeHUMKkAEKBAQAAgoSBGICYzIagQEgT3V0cHV0IG9ubHkuIENsb3VkIElk
ZW50aXR5IGluZm9ybWF0aW9uIGZvciB0aGUgY3VzdG9tZXIuCiBQb3B1bGF0ZWQgb25seSBp
ZiBhIENsb3VkIElkZW50aXR5IGFjY291bnQgZXhpc3RzIGZvciB0aGlzIGN1c3RvbWVyLgoK
DAoFBAACCgYSA2ICEwoMCgUEAAIKARIDYhQnCgwKBQQAAgoDEgNiKiwKDAoFBAACCggSA2MG
MQoPCggEAAIKCJwIABIDYwcwCoIBCgQEAAILEgNnAiEadSBDbG91ZCBJZGVudGl0eSBJRCBv
ZiB0aGUgY3VzdG9tZXIncyBjaGFubmVsIHBhcnRuZXIuCiBQb3B1bGF0ZWQgb25seSBpZiBh
IGNoYW5uZWwgcGFydG5lciBleGlzdHMgZm9yIHRoaXMgY3VzdG9tZXIuCgoMCgUEAAILBRID
ZwIICgwKBQQAAgsBEgNnCRsKDAoFBAACCwMSA2ceIApwCgQEAAIMEgNrAkYaYyBPcHRpb25h
bC4gRXh0ZXJuYWwgQ1JNIElEIGZvciB0aGUgY3VzdG9tZXIuCiBQb3B1bGF0ZWQgb25seSBp
ZiBhIENSTSBJRCBleGlzdHMgZm9yIHRoaXMgY3VzdG9tZXIuCgoMCgUEAAIMBRIDawIICgwK
BQQAAgwBEgNrCRcKDAoFBAACDAMSA2saHAoMCgUEAAIMCBIDax1FCg8KCAQAAgwInAgAEgNr
HkQKmwEKBAQAAg0SBG8CcC8ajAEgT3B0aW9uYWwuIEluZGljYXRlIGlmIGEgY3VzdG9tZXIg
aXMgYXR0ZXN0aW5nIGFib3V0IHRoZSBjb3JyZWN0bmVzcyBvZgogcHJvdmlkZWQgaW5mb3Jt
YXRpb24uIE9ubHkgcmVxdWlyZWQgaWYgY3JlYXRpbmcgYSBHQ1AgRW50aXRsZW1lbnQuCgoM
CgUEAAINBhIDbwIaCgwKBQQAAg0BEgNvGzUKDAoFBAACDQMSA284OgoMCgUEAAINCBIDcAYu
Cg8KCAQAAg0InAgAEgNwBy0KOgoCBAESBXQAiQEBGi0gQ29udGFjdCBpbmZvcm1hdGlvbiBm
b3IgYSBjdXN0b21lciBhY2NvdW50LgoKCgoDBAEBEgN0CBMKVgoEBAECABIDdgIYGkkgVGhl
IGN1c3RvbWVyIGFjY291bnQgY29udGFjdCdzIGZpcnN0IG5hbWUuIE9wdGlvbmFsIGZvciBU
ZWFtIGN1c3RvbWVycy4KCgwKBQQBAgAFEgN2AggKDAoFBAECAAESA3YJEwoMCgUEAQIAAxID
dhYXClUKBAQBAgESA3kCFxpIIFRoZSBjdXN0b21lciBhY2NvdW50IGNvbnRhY3QncyBsYXN0
IG5hbWUuIE9wdGlvbmFsIGZvciBUZWFtIGN1c3RvbWVycy4KCgwKBQQBAgEFEgN5AggKDAoF
BAECAQESA3kJEgoMCgUEAQIBAxIDeRUWCosBCgQEAQICEgN9AkYafiBPdXRwdXQgb25seS4g
VGhlIGN1c3RvbWVyIGFjY291bnQgY29udGFjdCdzIGRpc3BsYXkgbmFtZSwgZm9ybWF0dGVk
IGFzIGEKIGNvbWJpbmF0aW9uIG9mIHRoZSBjdXN0b21lcidzIGZpcnN0IGFuZCBsYXN0IG5h
bWUuCgoMCgUEAQICBRIDfQIICgwKBQQBAgIBEgN9CRUKDAoFBAECAgMSA30YGQoMCgUEAQIC
CBIDfRpFCg8KCAQBAgIInAgAEgN9G0QK3AEKBAQBAgMSBIIBAhMazQEgVGhlIGN1c3RvbWVy
IGFjY291bnQncyBjb250YWN0IGVtYWlsLiBSZXF1aXJlZCBmb3IgZW50aXRsZW1lbnRzIHRo
YXQgY3JlYXRlCiBhZG1pbi5nb29nbGUuY29tIGFjY291bnRzLCBhbmQgc2VydmVzIGFzIHRo
ZSBjdXN0b21lcidzIHVzZXJuYW1lIGZvciB0aG9zZQogYWNjb3VudHMuIFVzZSB0aGlzIGVt
YWlsIHRvIGludml0ZSBUZWFtIGN1c3RvbWVycy4KCg0KBQQBAgMFEgSCAQIICg0KBQQBAgMB
EgSCAQkOCg0KBQQBAgMDEgSCARESCkMKBAQBAgQSBIUBAjwaNSBPcHRpb25hbC4gVGhlIGN1
c3RvbWVyIGFjY291bnQgY29udGFjdCdzIGpvYiB0aXRsZS4KCg0KBQQBAgQFEgSFAQIICg0K
BQQBAgQBEgSFAQkOCg0KBQQBAgQDEgSFARESCg0KBQQBAgQIEgSFARM7ChAKCAQBAgQInAgA
EgSFARQ6CjwKBAQBAgUSBIgBAhMaLiBUaGUgY3VzdG9tZXIgYWNjb3VudCdzIGNvbnRhY3Qg
cGhvbmUgbnVtYmVyLgoKDQoFBAECBQUSBIgBAggKDQoFBAECBQESBIgBCQ4KDQoFBAECBQMS
BIgBERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Customers::Customer ===
    # Fields for Customer
    # Field: name Type: 9 ()
    # Field: org_display_name Type: 9 ()
    # Field: org_postal_address Type: 11 (.google.type.PostalAddress)
    # Field: primary_contact_info Type: 11 (.google.cloud.channel.v1.ContactInfo)
    # Field: alternate_email Type: 9 ()
    # Field: domain Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: cloud_identity_id Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: cloud_identity_info Type: 11 (.google.cloud.channel.v1.CloudIdentityInfo)
    # Field: channel_partner_id Type: 9 ()
    # Field: correlation_id Type: 9 ()
    # Field: customer_attestation_state Type: 14 (.google.cloud.channel.v1.Customer.CustomerAttestationState)

# Enum: Customer::CustomerAttestationState
our $Customer_CUSTOMER_ATTESTATION_STATE_UNSPECIFIED = 0;
our $Customer_EXEMPT = 1;
our $Customer_NON_EXEMPT_AND_INFO_VERIFIED = 2;

# === Message: Google::Cloud::Channel::V1::Customers::ContactInfo ===
    # Fields for ContactInfo
    # Field: first_name Type: 9 ()
    # Field: last_name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: email Type: 9 ()
    # Field: title Type: 9 ()
    # Field: phone Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Customers - Compiled Protocol Buffers messages for google/cloud/channel/v1/customers.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Customers;

    my $msg = Google::Cloud::Channel::V1::Customers::Customer->new({
        name => $name,
        org_display_name => $org_display_name,
        org_postal_address => $org_postal_address,
        primary_contact_info => $primary_contact_info,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Customers::Customer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/customers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Customers::Customer

Entity representing a customer of a reseller or distributor.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the customer.
Format: accounts/{account_id}/customers/{customer_id}

=item * C<< $msg->org_display_name() >> / C<< $msg->org_display_name($value) >>

Type: C<String>

Required. Name of the organization that the customer entity represents.

=item * C<< $msg->org_postal_address() >> / C<< $msg->org_postal_address($value) >>

Type: C<Message> (L<Google::Type::PostalAddress::PostalAddress>)

Required. The organization address for the customer. To enforce US laws and
embargoes, we require a region, postal code, and address lines. You must
provide valid addresses for every customer. To set the customer's
language, use the Customer-level language code.

=item * C<< $msg->primary_contact_info() >> / C<< $msg->primary_contact_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Customers::ContactInfo>)

Primary contact info.

=item * C<< $msg->alternate_email() >> / C<< $msg->alternate_email($value) >>

Type: C<String>

Secondary contact email. You need to provide an alternate email to create
different domains if a primary contact email already exists. Users will
receive a notification with credentials when you create an admin.google.com
account. Secondary emails are also recovery email addresses. Alternate
emails are optional when you create Team customers.

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

Required. The customer's primary domain. Must match the primary contact
email's domain.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the customer was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the customer was updated.

=item * C<< $msg->cloud_identity_id() >> / C<< $msg->cloud_identity_id($value) >>

Type: C<String>

Output only. The customer's Cloud Identity ID if the customer has a Cloud
Identity resource.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. The BCP-47 language code, such as "en-US" or "sr-Latn". For more
information, see
https://www.unicode.org/reports/tr35/#Unicode_locale_identifier.

=item * C<< $msg->cloud_identity_info() >> / C<< $msg->cloud_identity_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::CloudIdentityInfo>)

Output only. Cloud Identity information for the customer.
Populated only if a Cloud Identity account exists for this customer.

=item * C<< $msg->channel_partner_id() >> / C<< $msg->channel_partner_id($value) >>

Type: C<String>

Cloud Identity ID of the customer's channel partner.
Populated only if a channel partner exists for this customer.

=item * C<< $msg->correlation_id() >> / C<< $msg->correlation_id($value) >>

Type: C<String>

Optional. External CRM ID for the customer.
Populated only if a CRM ID exists for this customer.

=item * C<< $msg->customer_attestation_state() >> / C<< $msg->customer_attestation_state($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::Customer::CustomerAttestationState>)

Optional. Indicate if a customer is attesting about the correctness of
provided information. Only required if creating a GCP Entitlement.

=back

=head3 Enum: Customer::CustomerAttestationState

=over 4

=item * C<CUSTOMER_ATTESTATION_STATE_UNSPECIFIED> => C<0>

=item * C<EXEMPT> => C<1>

=item * C<NON_EXEMPT_AND_INFO_VERIFIED> => C<2>

=back

=head2 Google::Cloud::Channel::V1::Customers::ContactInfo

Contact information for a customer account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->first_name() >> / C<< $msg->first_name($value) >>

Type: C<String>

The customer account contact's first name. Optional for Team customers.

=item * C<< $msg->last_name() >> / C<< $msg->last_name($value) >>

Type: C<String>

The customer account contact's last name. Optional for Team customers.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The customer account contact's display name, formatted as a
combination of the customer's first and last name.

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

The customer account's contact email. Required for entitlements that create
admin.google.com accounts, and serves as the customer's username for those
accounts. Use this email to invite Team customers.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The customer account contact's job title.

=item * C<< $msg->phone() >> / C<< $msg->phone($value) >>

Type: C<String>

The customer account's contact phone number.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Customers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
