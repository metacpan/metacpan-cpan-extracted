package Google::Cloud::Geminidataanalytics::V1beta::Conversation;

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
Cjpnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvY29udmVyc2F0aW9u
LnByb3RvEidnb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWJldGEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21h
c2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i9gQKDENvbnZlcnNh
dGlvbhIaCgRuYW1lGAEgASgJQgbgQQHgQQhSBG5hbWUSGwoGYWdlbnRzGAIgAygJQgPgQQJS
BmFnZW50cxJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKY3JlYXRlVGltZRJFCg5sYXN0X3VzZWRfdGltZRgEIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IMbGFzdFVzZWRUaW1lEl4KBmxhYmVscxgJIAMoCzJB
Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYmV0YS5Db252ZXJzYXRpb24u
TGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEhkKBXRpdGxlGAYgASgJQgPgQQFSBXRpdGxlEkcK
B2ttc19rZXkYCiABKAlCKeBBAfpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRv
S2V5SABSBmttc0tleYgBARo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2
YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOpgB6kGUAQovZ2VtaW5pZGF0YWFuYWx5dGljcy5nb29n
bGVhcGlzLmNvbS9Db252ZXJzYXRpb24SRHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9jb252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259Kg1jb252ZXJzYXRpb25z
Mgxjb252ZXJzYXRpb25CCgoIX2ttc19rZXkipgIKGUNyZWF0ZUNvbnZlcnNhdGlvblJlcXVl
c3QSTwoGcGFyZW50GAEgASgJQjfgQQL6QTESL2dlbWluaWRhdGFhbmFseXRpY3MuZ29vZ2xl
YXBpcy5jb20vQ29udmVyc2F0aW9uUgZwYXJlbnQSLAoPY29udmVyc2F0aW9uX2lkGAIgASgJ
QgPgQQFSDmNvbnZlcnNhdGlvbklkEl4KDGNvbnZlcnNhdGlvbhgDIAEoCzI1Lmdvb2dsZS5j
bG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYmV0YS5Db252ZXJzYXRpb25CA+BBAlIMY29u
dmVyc2F0aW9uEioKCnJlcXVlc3RfaWQYBCABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQi
6QEKGVVwZGF0ZUNvbnZlcnNhdGlvblJlcXVlc3QSXgoMY29udmVyc2F0aW9uGAEgASgLMjUu
Z29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhLkNvbnZlcnNhdGlvbkID
4EECUgxjb252ZXJzYXRpb24SQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSKgoKcmVxdWVzdF9pZBgDIAEoCUIL4ozP
1wgCCAHgQQFSCXJlcXVlc3RJZCJlChZHZXRDb252ZXJzYXRpb25SZXF1ZXN0EksKBG5hbWUY
ASABKAlCN+BBAvpBMQovZ2VtaW5pZGF0YWFuYWx5dGljcy5nb29nbGVhcGlzLmNvbS9Db252
ZXJzYXRpb25SBG5hbWUizgEKGExpc3RDb252ZXJzYXRpb25zUmVxdWVzdBJPCgZwYXJlbnQY
ASABKAlCN+BBAvpBMRIvZ2VtaW5pZGF0YWFuYWx5dGljcy5nb29nbGVhcGlzLmNvbS9Db252
ZXJzYXRpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoK
cGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFS
BmZpbHRlciKgAQoZTGlzdENvbnZlcnNhdGlvbnNSZXNwb25zZRJbCg1jb252ZXJzYXRpb25z
GAEgAygLMjUuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhLkNvbnZl
cnNhdGlvblINY29udmVyc2F0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4iaAoZRGVsZXRlQ29udmVyc2F0aW9uUmVxdWVzdBJLCgRuYW1lGAEgASgJQjfg
QQL6QTEKL2dlbWluaWRhdGFhbmFseXRpY3MuZ29vZ2xlYXBpcy5jb20vQ29udmVyc2F0aW9u
UgRuYW1lQrUDCitjb20uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRh
QhFDb252ZXJzYXRpb25Qcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2dlbWluaWRhdGFh
bmFseXRpY3MvYXBpdjFiZXRhL2dlbWluaWRhdGFhbmFseXRpY3NwYjtnZW1pbmlkYXRhYW5h
bHl0aWNzcGKqAidHb29nbGUuQ2xvdWQuR2VtaW5pRGF0YUFuYWx5dGljcy5WMUJldGHKAidH
b29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMWJldGHqAipHb29nbGU6OkNsb3Vk
OjpHZW1pbmlEYXRhQW5hbHl0aWNzOjpWMWJldGHqQY8BCiFjbG91ZGttcy5nb29nbGVhcGlz
LmNvbS9DcnlwdG9LZXkSU3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9rZXlSaW5ncy97a2V5X3Jpbmd9L2NyeXB0b0tleXMve2NyeXB0b19rZXl9KgpjcnlwdG9L
ZXlzMgljcnlwdG9LZXlK9TgKBxIFDgDXAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
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
Y2Vuc2UuCgoICgECEgMQADAKCQoCAwASAxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCQoC
AwMSAxUAKgoJCgIDBBIDFgApCggKAQgSAxgARAoJCgIIJRIDGABECggKAQgSAxkAdAoJCgII
CxIDGQB0CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMgoJCgIICBIDGwAyCggKAQgS
AxwARAoJCgIIARIDHABECggKAQgSAx0ARAoJCgIIKRIDHQBECggKAQgSAx4AQwoJCgIILRID
HgBDCgkKAQgSBB8AJAIKDAoECJ0IABIEHwAkAgopCgIEABIEJwBiARodIE1lc3NhZ2UgZm9y
IGEgY29udmVyc2F0aW9uLgoKCgoDBAABEgMnCBQKCwoDBAAHEgQoAi0ECg0KBQQAB50IEgQo
Ai0ECtIECgQEAAIAEgQ7Aj4EGsMEIE9wdGlvbmFsLiBJZGVudGlmaWVyLiBUaGUgdW5pcXVl
IHJlc291cmNlIG5hbWUgb2YgYSBjb252ZXJzYXRpb24uIEZvcm1hdDoKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29udmVyc2F0aW9ucy97Y29udmVyc2F0
aW9uX2lkfWAKIGB7Y29udmVyc2F0aW9uX2lkfWAgaXMgdGhlIHJlc291cmNlIGlkIGFuZCBz
aG91bGQgYmUgNjMgY2hhcmFjdGVycyBvciBsZXNzCiBhbmQgbXVzdCBtYXRjaCB0aGUgZm9y
bWF0IGRlc2NyaWJlZCBpbgogaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xMjIjcmVzb3VyY2Ut
aWQtc2VnbWVudHMKCiBFeGFtcGxlOgogYHByb2plY3RzLzEyMzQ1Njc4OTAvbG9jYXRpb25z
L2dsb2JhbC9jb252ZXJzYXRpb25zL215LWNvbnZlcnNhdGlvbmAuCgogSXQgaXMgcmVjb21t
ZW5kZWQgdG8gc2tpcCBzZXR0aW5nIHRoaXMgZmllbGQgZHVyaW5nIGNvbnZlcnNhdGlvbiBj
cmVhdGlvbgogYXMgaXQgd2lsbCBiZSBpbmZlcnJlZCBhdXRvbWF0aWNhbGx5IGFuZCBvdmVy
d3JpdHRlbiB3aXRoIHRoZQoge3BhcmVudH0vY29udmVyc2F0aW9ucy97Y29udmVyc2F0aW9u
X2lkfS4KCgwKBQQAAgAFEgM7AggKDAoFBAACAAESAzsJDQoMCgUEAAIAAxIDOxARCg0KBQQA
AgAIEgQ7Ej4DCg8KCAQAAgAInAgAEgM8BCoKDwoIBAACAAicCAESAz0ELAqAAgoEBAACARID
RAJGGvIBIFJlcXVpcmVkLiBBZ2VudChzKSBpbiB0aGUgY29udmVyc2F0aW9uLgogQ3VycmVu
dGx5LCBvbmx5IG9uZSBhZ2VudCBpcyBzdXBwb3J0ZWQuIFRoaXMgZmllbGQgaXMgcmVwZWF0
ZWQgdG8gYWxsb3cKIGZvciBmdXR1cmUgc3VwcG9ydCBvZiBtdWx0aXBsZSBhZ2VudHMgaW4g
YSBjb252ZXJzYXRpb24uCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGF0YUFnZW50cy97YWdlbnR9YAoKDAoFBAACAQQSA0QCCgoMCgUEAAIB
BRIDRAsRCgwKBQQAAgEBEgNEEhgKDAoFBAACAQMSA0QbHAoMCgUEAAIBCBIDRB1FCg8KCAQA
AgEInAgAEgNEHkQKMAoEBAACAhIERwJIMhoiIE91dHB1dCBvbmx5LiBDcmVhdGlvbiB0aW1l
c3RhbXAuCgoMCgUEAAICBhIDRwIbCgwKBQQAAgIBEgNHHCcKDAoFBAACAgMSA0cqKwoMCgUE
AAICCBIDSAYxCg8KCAQAAgIInAgAEgNIBzAKRQoEBAACAxIESwJMMho3IE91dHB1dCBvbmx5
LiBUaW1lc3RhbXAgb2YgdGhlIGxhc3QgdXNlZCBjb252ZXJzYXRpb24uCgoMCgUEAAIDBhID
SwIbCgwKBQQAAgMBEgNLHCoKDAoFBAACAwMSA0stLgoMCgUEAAIDCBIDTAYxCg8KCAQAAgMI
nAgAEgNMBzAKsQEKBAQAAgQSA1ECShqjASBPcHRpb25hbC4gT3Blbi1lbmRlZCBhbmQgdXNl
ci1kZWZpbmVkIGxhYmVscyB0aGF0IGNhbiBiZSBzZXQgYnkgdGhlIGNsaWVudAogdG8gdGFn
IGEgY29udmVyc2F0aW9uIChlLmcuIHRvIGZpbHRlciBjb252ZXJzYXRpb25zIGZvciBzcGVj
aWZpYwogc3VyZmFjZXMvcHJvZHVjdHMpLgoKDAoFBAACBAYSA1ECFQoMCgUEAAIEARIDURYc
CgwKBQQAAgQDEgNRHyAKDAoFBAACBAgSA1EhSQoPCggEAAIECJwIABIDUSJICk4KBAQAAgUS
A1QCPBpBIE9wdGlvbmFsLiBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGUgY29udmVyc2F0aW9u
IChtYXggNjMgY2hhcnMpLgoKDAoFBAACBQUSA1QCCAoMCgUEAAIFARIDVAkOCgwKBQQAAgUD
EgNUERIKDAoFBAACBQgSA1QTOwoPCggEAAIFCJwIABIDVBQ6CqUCCgQEAAIGEgRcAmEEGpYC
IE9wdGlvbmFsLiBDdXN0b21lciBtYW5hZ2VkIGVuY3J5cHRpb24ga2V5IChDTUVLKSB0byB1
c2UgZm9yIGVuY3J5cHRpbmcgdGhlCiBDb252ZXJzYXRpb24gcmVzb3VyY2VzLiBFbmNyeXB0
aW9uIHdpbGwgaGFwcGVuIGF0IFRpdGFuIGxheWVyLCB3ZSB3aWxsIHBhc3MKIHRoZSBLTVMg
a2V5IHRvIFRpdGFuLgoKIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3JpbmdfbmFtZX0vY3J5cHRvS2V5cy97a2V5
X25hbWV9LgoKDAoFBAACBgQSA1wCCgoMCgUEAAIGBRIDXAsRCgwKBQQAAgYBEgNcEhkKDAoF
BAACBgMSA1wcHgoNCgUEAAIGCBIEXB9hAwoPCggEAAIGCJwIABIDXQQqCg8KBwQAAgYInwgS
BF4EYAUKMwoCBAESBWUAgAEBGiYgUmVxdWVzdCBmb3IgY3JlYXRpbmcgYSBjb252ZXJzYXRp
b24uCgoKCgMEAQESA2UIIQp4CgQEAQIAEgRoAm0EGmogUmVxdWlyZWQuIFBhcmVudCB2YWx1
ZSBmb3IgQ3JlYXRlQ29udmVyc2F0aW9uUmVxdWVzdC4KIEZvcm1hdDogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCgwKBQQBAgAFEgNoAggKDAoFBAECAAES
A2gJDwoMCgUEAQIAAxIDaBITCg0KBQQBAgAIEgRoFG0DCg8KCAQBAgAInAgAEgNpBCoKDwoH
BAECAAifCBIEagRsBQrwAQoEBAECARIDcwJGGuIBIE9wdGlvbmFsLiBUaGUgY29udmVyc2F0
aW9uIGlkIG9mIHRoZSBjb252ZXJzYXRpb24gdG8gY3JlYXRlLgogTXVzdCBiZSB1bmlxdWUg
d2l0aGluIHRoZSBwYXJlbnQuCiBUaGUgYWxsb3dlZCBmb3JtYXQgaXM6IGBeW2Etel0oW2Et
ejAtOS1dezAsNjF9W2EtejAtOV0pPyRgLgogSWYgbm90IHByb3ZpZGVkLCB0aGUgc2VydmVy
IHdpbGwgYXV0by1nZW5lcmF0ZSBhIHZhbHVlIGZvciB0aGUgaWQuCgoMCgUEAQIBBRIDcwII
CgwKBQQBAgEBEgNzCRgKDAoFBAECAQMSA3MbHAoMCgUEAQIBCBIDcx1FCg8KCAQBAgEInAgA
EgNzHkQKNAoEBAECAhIDdgJJGicgUmVxdWlyZWQuIFRoZSBjb252ZXJzYXRpb24gdG8gY3Jl
YXRlLgoKDAoFBAECAgYSA3YCDgoMCgUEAQICARIDdg8bCgwKBQQBAgIDEgN2Hh8KDAoFBAEC
AggSA3YgSAoPCggEAQICCJwIABIDdiFHCqsCCgQEAQIDEgR8An8EGpwCIE9wdGlvbmFsLiBB
biBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEg
dW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1
ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0
IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRl
ZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0
LgoKDAoFBAECAwUSA3wCCAoMCgUEAQIDARIDfAkTCgwKBQQBAgMDEgN8FhcKDQoFBAECAwgS
BHwYfwMKEgoLBAECAwjM8fmKAQESA30EKgoPCggEAQIDCJwIABIDfgQqCjQKAgQCEgaDAQCZ
AQEaJiBSZXF1ZXN0IGZvciB1cGRhdGluZyBhIGNvbnZlcnNhdGlvbi4KCgsKAwQCARIEgwEI
IQo1CgQEAgIAEgSFAQJJGicgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBiZWluZyB1cGRhdGVk
LgoKDQoFBAICAAYSBIUBAg4KDQoFBAICAAESBIUBDxsKDQoFBAICAAMSBIUBHh8KDQoFBAIC
AAgSBIUBIEgKEAoIBAICAAicCAASBIUBIUcKzwMKBAQCAgESBo4BAo8BLxq+AyBPcHRpb25h
bC4gRmllbGQgbWFzayBpcyB1c2VkIHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVy
d3JpdHRlbiBpbiB0aGUKIENvbnZlcnNhdGlvbiByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgog
VGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0
byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJl
IG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBu
b3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpdGggbm9uLWRlZmF1bHQgdmFs
dWVzCiBwcmVzZW50IGluIHRoZSByZXF1ZXN0IHdpbGwgYmUgb3ZlcndyaXR0ZW4uIElmIGEg
d2lsZGNhcmQgbWFzayBpcyBwcm92aWRlZCwKIGFsbCBmaWVsZHMgd2lsbCBiZSBvdmVyd3Jp
dHRlbi4KCg0KBQQCAgEGEgSOAQIbCg0KBQQCAgEBEgSOARwnCg0KBQQCAgEDEgSOASorCg0K
BQQCAgEIEgSPAQYuChAKCAQCAgEInAgAEgSPAQctCq0CCgQEAgICEgaVAQKYAQQanAIgT3B0
aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNw
ZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5
b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVl
c3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAog
Z3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0
IHJlcXVlc3QuCgoNCgUEAgICBRIElQECCAoNCgUEAgICARIElQEJEwoNCgUEAgICAxIElQEW
FwoPCgUEAgICCBIGlQEYmAEDChMKCwQCAgIIzPH5igEBEgSWAQQqChAKCAQCAgIInAgAEgSX
AQQqClcKAgQDEgacAQCmAQEaSSBSZXF1ZXN0IGZvciBnZXR0aW5nIGEgY29udmVyc2F0aW9u
IGJhc2VkIG9uIHBhcmVudCBhbmQgY29udmVyc2F0aW9uIGlkLgoKCwoDBAMBEgScAQgeCoIB
CgQEAwIAEgagAQKlAQQaciBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCiBGb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbnZlcnNh
dGlvbnMve2NvbnZlcnNhdGlvbn1gCgoNCgUEAwIABRIEoAECCAoNCgUEAwIAARIEoAEJDQoN
CgUEAwIAAxIEoAEQEQoPCgUEAwIACBIGoAESpQEDChAKCAQDAgAInAgAEgShAQQqChEKBwQD
AgAInwgSBqIBBKQBBQpCCgIEBBIGqQEAwQEBGjQgUmVxdWVzdCBmb3IgbGlzdGluZyBjb252
ZXJzYXRpb25zIGJhc2VkIG9uIHBhcmVudC4KCgsKAwQEARIEqQEIIAp5CgQEBAIAEgasAQKx
AQQaaSBSZXF1aXJlZC4gUGFyZW50IHZhbHVlIGZvciBMaXN0Q29udmVyc2F0aW9uc1JlcXVl
c3QuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1g
CgoNCgUEBAIABRIErAECCAoNCgUEBAIAARIErAEJDwoNCgUEBAIAAxIErAESEwoPCgUEBAIA
CBIGrAEUsQEDChAKCAQEAgAInAgAEgStAQQqChEKBwQEAgAInwgSBq4BBLABBQrtAQoEBAQC
ARIEtwECPxreASBPcHRpb25hbC4gUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gU2VydmVyIG1heSBy
ZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbgogcmVxdWVzdGVkLiBUaGUgbWF4IHBhZ2Ugc2l6ZSBp
cyBgMTAwYC4gQWxsIGxhcmdlciBwYWdlIHNpemVzIHdpbGwgYmUKIGNvZXJjZWQgdG8gYDEw
MGAuIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCBwaWNrIGA1MGAgYXMgYW4gYXBwcm9w
cmlhdGUKIGRlZmF1bHQuCgoNCgUEBAIBBRIEtwECBwoNCgUEBAIBARIEtwEIEQoNCgUEBAIB
AxIEtwEUFQoNCgUEBAIBCBIEtwEWPgoQCggEBAIBCJwIABIEtwEXPQpZCgQEBAICEgS6AQJB
GksgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhl
IHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDQoFBAQCAgUSBLoBAggKDQoFBAQCAgESBLoBCRMK
DQoFBAQCAgMSBLoBFhcKDQoFBAQCAggSBLoBGEAKEAoIBAQCAgicCAASBLoBGT8KoAEKBAQE
AgMSBMABAj0akQEgT3B0aW9uYWwuIFJldHVybmVkIGNvbnZlcnNhdGlvbnMgd2lsbCBtYXRj
aCBjcml0ZXJpYSBzcGVjaWZpZWQgd2l0aGluIHRoZQogZmlsdGVyLiBMaXN0Q29udmVyc2F0
aW9ucyBhbGxvd3MgZmlsdGVyaW5nIGJ5OgogICogYWdlbnRzCiAgKiBsYWJlbHMKCg0KBQQE
AgMFEgTAAQIICg0KBQQEAgMBEgTAAQkPCg0KBQQEAgMDEgTAARITCg0KBQQEAgMIEgTAARQ8
ChAKCAQEAgMInAgAEgTAARU7Cj4KAgQFEgbEAQDKAQEaMCBNZXNzYWdlIGZvciByZXNwb25z
ZSB0byBsaXN0aW5nIGNvbnZlcnNhdGlvbnMuCgoLCgMEBQESBMQBCCEKKgoEBAUCABIExgEC
KhocIFRoZSBsaXN0IG9mIGNvbnZlcnNhdGlvbnMuCgoNCgUEBQIABBIExgECCgoNCgUEBQIA
BhIExgELFwoNCgUEBQIAARIExgEYJQoNCgUEBQIAAxIExgEoKQpPCgQEBQIBEgTJAQIdGkEg
QSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3Vs
ZCByZXR1cm4uCgoNCgUEBQIBBRIEyQECCAoNCgUEBQIBARIEyQEJGAoNCgUEBQIBAxIEyQEb
HApYCgIEBhIGzQEA1wEBGkogUmVxdWVzdCBmb3IgZGVsZXRpbmcgYSBjb252ZXJzYXRpb24g
YmFzZWQgb24gcGFyZW50IGFuZCBjb252ZXJzYXRpb24gaWQuCgoLCgMEBgESBM0BCCEKggEK
BAQGAgASBtEBAtYBBBpyIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZS4KIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29udmVyc2F0
aW9ucy97Y29udmVyc2F0aW9ufWAKCg0KBQQGAgAFEgTRAQIICg0KBQQGAgABEgTRAQkNCg0K
BQQGAgADEgTRARARCg8KBQQGAgAIEgbRARLWAQMKEAoIBAYCAAicCAASBNIBBCoKEQoHBAYC
AAifCBIG0wEE1QEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: agents Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_used_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.geminidataanalytics.v1beta.Conversation.LabelsEntry)
    # Field: title Type: 9 ()
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::CreateConversationRequest ===
    # Fields for CreateConversationRequest
    # Field: parent Type: 9 ()
    # Field: conversation_id Type: 9 ()
    # Field: conversation Type: 11 (.google.cloud.geminidataanalytics.v1beta.Conversation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::UpdateConversationRequest ===
    # Fields for UpdateConversationRequest
    # Field: conversation Type: 11 (.google.cloud.geminidataanalytics.v1beta.Conversation)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::GetConversationRequest ===
    # Fields for GetConversationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsRequest ===
    # Fields for ListConversationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsResponse ===
    # Fields for ListConversationsResponse
    # Field: conversations Type: 11 (.google.cloud.geminidataanalytics.v1beta.Conversation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Conversation::DeleteConversationRequest ===
    # Fields for DeleteConversationRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::Conversation - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1beta/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1beta::Conversation;

    my $msg = Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation->new({
        name => $name,
        agents => $agents,
        create_time => $create_time,
        last_used_time => $last_used_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1beta/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation

Message for a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Identifier. The unique resource name of a conversation. Format:
`projects/{project}/locations/{location}/conversations/{conversation_id}`
`{conversation_id}` is the resource id and should be 63 characters or less
and must match the format described in
https://google.aip.dev/122#resource-id-segments

Example:
`projects/1234567890/locations/global/conversations/my-conversation`.

It is recommended to skip setting this field during conversation creation
as it will be inferred automatically and overwritten with the
{parent}/conversations/{conversation_id}.

=item * C<< $msg->agents() >> / C<< $msg->agents($value) >>

Type: C<String>

Required. Agent(s) in the conversation.
Currently, only one agent is supported. This field is repeated to allow
for future support of multiple agents in a conversation.
Format: `projects/{project}/locations/{location}/dataAgents/{agent}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation timestamp.

=item * C<< $msg->last_used_time() >> / C<< $msg->last_used_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the last used conversation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation::LabelsEntry>)

Optional. Open-ended and user-defined labels that can be set by the client
to tag a conversation (e.g. to filter conversations for specific
surfaces/products).

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The display name for the conversation (max 63 chars).

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Optional. Customer managed encryption key (CMEK) to use for encrypting the
Conversation resources. Encryption will happen at Titan layer, we will pass
the KMS key to Titan.

Format:
projects/{project_id}/locations/{location}/keyRings/{key_ring_name}/cryptoKeys/{key_name}.

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::CreateConversationRequest

Request for creating a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for CreateConversationRequest.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->conversation_id() >> / C<< $msg->conversation_id($value) >>

Type: C<String>

Optional. The conversation id of the conversation to create.
Must be unique within the parent.
The allowed format is: `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$`.
If not provided, the server will auto-generate a value for the id.

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation>)

Required. The conversation to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::UpdateConversationRequest

Request for updating a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation>)

Required. The resource being updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Conversation resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields with non-default values
present in the request will be overwritten. If a wildcard mask is provided,
all fields will be overwritten.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::GetConversationRequest

Request for getting a conversation based on parent and conversation id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.
Format:
`projects/{project}/locations/{location}/conversations/{conversation}`

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsRequest

Request for listing conversations based on parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListConversationsRequest.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. The max page size is `100`. All larger page sizes will be
coerced to `100`. If unspecified, server will pick `50` as an appropriate
default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Returned conversations will match criteria specified within the
filter. ListConversations allows filtering by:
 * agents
 * labels

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsResponse

Message for response to listing conversations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversations() >> / C<< $msg->conversations($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation>)

The list of conversations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Conversation::DeleteConversationRequest

Request for deleting a conversation based on parent and conversation id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.
Format:
`projects/{project}/locations/{location}/conversations/{conversation}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1beta::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
