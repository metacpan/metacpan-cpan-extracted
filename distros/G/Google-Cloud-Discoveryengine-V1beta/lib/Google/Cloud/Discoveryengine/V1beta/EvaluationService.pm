package Google::Cloud::Discoveryengine::V1beta::EvaluationService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Evaluation };
    eval { require Google::Cloud::Discoveryengine::V1beta::SampleQuery };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9ldmFsdWF0aW9uX3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0
Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvZXZhbHVhdGlvbi5wcm90bxo2
Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvc2FtcGxlX3F1ZXJ5LnByb3Rv
GiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90byJdChRHZXRFdmFsdWF0aW9u
UmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6QSsKKWRpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9FdmFsdWF0aW9uUgRuYW1lIqcBChZMaXN0RXZhbHVhdGlvbnNSZXF1ZXN0EkcK
BnBhcmVudBgBIAEoCUIv4EEC+kEpCidkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
TG9jYXRpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoK
cGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4ilAEKF0xpc3RFdmFsdWF0aW9uc1Jl
c3BvbnNlElEKC2V2YWx1YXRpb25zGAEgAygLMi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuRXZhbHVhdGlvblILZXZhbHVhdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuIrgBChdDcmVhdGVFdmFsdWF0aW9uUmVxdWVzdBJHCgZw
YXJlbnQYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xv
Y2F0aW9uUgZwYXJlbnQSVAoKZXZhbHVhdGlvbhgCIAEoCzIvLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkV2YWx1YXRpb25CA+BBAlIKZXZhbHVhdGlvbiIaChhDcmVh
dGVFdmFsdWF0aW9uTWV0YWRhdGEitwEKHExpc3RFdmFsdWF0aW9uUmVzdWx0c1JlcXVlc3QS
UQoKZXZhbHVhdGlvbhgBIAEoCUIx4EEC+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb20vRXZhbHVhdGlvblIKZXZhbHVhdGlvbhIgCglwYWdlX3NpemUYAiABKAVCA+BBAVII
cGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4ingMKHUxpc3RF
dmFsdWF0aW9uUmVzdWx0c1Jlc3BvbnNlEoIBChJldmFsdWF0aW9uX3Jlc3VsdHMYASADKAsy
Uy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0RXZhbHVhdGlvblJl
c3VsdHNSZXNwb25zZS5FdmFsdWF0aW9uUmVzdWx0UhFldmFsdWF0aW9uUmVzdWx0cxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4azwEKEEV2YWx1YXRpb25SZXN1
bHQSWAoMc2FtcGxlX3F1ZXJ5GAEgASgLMjAuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuU2FtcGxlUXVlcnlCA+BBA1ILc2FtcGxlUXVlcnkSYQoPcXVhbGl0eV9tZXRy
aWNzGAIgASgLMjMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUXVhbGl0
eU1ldHJpY3NCA+BBA1IOcXVhbGl0eU1ldHJpY3My+wkKEUV2YWx1YXRpb25TZXJ2aWNlEr8B
Cg1HZXRFdmFsdWF0aW9uEjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
R2V0RXZhbHVhdGlvblJlcXVlc3QaLy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5FdmFsdWF0aW9uIkKC0+STAjUSMy92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9ldmFsdWF0aW9ucy8qfdpBBG5hbWUS0gEKD0xpc3RFdmFsdWF0aW9ucxI7Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RFdmFsdWF0aW9uc1JlcXVl
c3QaPC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0RXZhbHVhdGlv
bnNSZXNwb25zZSJEgtPkkwI1EjMvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKn0vZXZhbHVhdGlvbnPaQQZwYXJlbnQSvgIKEENyZWF0ZUV2YWx1YXRpb24SPC5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DcmVhdGVFdmFsdWF0aW9uUmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24izAGC0+STAkEiMy92MWJldGEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9ldmFsdWF0aW9uczoKZXZhbHVhdGlvbtpB
EXBhcmVudCxldmFsdWF0aW9uykFuCi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5FdmFsdWF0aW9uEjxnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5D
cmVhdGVFdmFsdWF0aW9uTWV0YWRhdGES+gEKFUxpc3RFdmFsdWF0aW9uUmVzdWx0cxJBLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RFdmFsdWF0aW9uUmVzdWx0
c1JlcXVlc3QaQi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0RXZh
bHVhdGlvblJlc3VsdHNSZXNwb25zZSJagtPkkwJHEkUvdjFiZXRhL3tldmFsdWF0aW9uPXBy
b2plY3RzLyovbG9jYXRpb25zLyovZXZhbHVhdGlvbnMvKn06bGlzdFJlc3VsdHPaQQpldmFs
dWF0aW9uGpACykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kHrAWh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuYXNzaXN0LnJlYWR3cml0ZSxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUs
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2Vydmlu
Zy5yZWFkd3JpdGVCnQIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YUIWRXZhbHVhdGlvblNlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2Nv
dmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5l
cGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYx
QmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpD
bG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKqUUKBxIFDgCAAgEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA+CgkKAgMFEgMXAEAKCQoCAwYSAxgA
LQoICgEIEgMaAEAKCQoCCCUSAxoAQAoICgEIEgMbAGgKCQoCCAsSAxsAaAoICgEIEgMcACIK
CQoCCAoSAxwAIgoICgEIEgMdADcKCQoCCAgSAx0ANwoICgEIEgMeAEAKCQoCCAESAx4AQAoI
CgEIEgMfAC0KCQoCCCQSAx8ALQoICgEIEgMgAEAKCQoCCCkSAyAAQAoICgEIEgMhAD8KCQoC
CC0SAyEAPwpiCgIGABIEJQBZARpWIFNlcnZpY2UgZm9yIG1hbmFnaW5nCiBbRXZhbHVhdGlv
bl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlvbl1zLAoK
CgoDBgABEgMlCBkKCgoDBgADEgMmAkYKDAoFBgADmQgSAyYCRgoLCgMGAAMSBCcCK0oKDQoF
BgADmggSBCcCK0oKVAoEBgACABIELgIzAxpGIEdldHMgYSBbRXZhbHVhdGlvbl1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlvbl0uCgoMCgUGAAIAARID
LgYTCgwKBQYAAgACEgMuFCgKDAoFBgACAAMSAy4zPQoNCgUGAAIABBIELwQxBgoRCgkGAAIA
BLDKvCISBC8EMQYKDAoFBgACAAQSAzIEMgoPCggGAAIABJsIABIDMgQyCl4KBAYAAgESBDcC
PQMaUCBHZXRzIGEgbGlzdCBvZgogW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkV2YWx1YXRpb25dcy4KCgwKBQYAAgEBEgM3BhUKDAoFBgACAQIS
AzcWLAoMCgUGAAIBAxIDOA8mCg0KBQYAAgEEEgQ5BDsGChEKCQYAAgEEsMq8IhIEOQQ7BgoM
CgUGAAIBBBIDPAQ0Cg8KCAYAAgEEmwgAEgM8BDQKrgEKBAYAAgISBEMCTgManwEgQ3JlYXRl
cyBhIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5F
dmFsdWF0aW9uXS4KCiBVcG9uIGNyZWF0aW9uLCB0aGUgZXZhbHVhdGlvbiB3aWxsIGJlIGF1
dG9tYXRpY2FsbHkgdHJpZ2dlcmVkIGFuZCBiZWdpbgogZXhlY3V0aW9uLgoKDAoFBgACAgES
A0MGFgoMCgUGAAICAhIDQxcuCgwKBQYAAgIDEgNEDysKDQoFBgACAgQSBEUESAYKEQoJBgAC
AgSwyrwiEgRFBEgGCgwKBQYAAgIEEgNJBD8KDwoIBgACAgSbCAASA0kEPwoNCgUGAAICBBIE
SgRNBgoPCgcGAAICBJkIEgRKBE0GCnMKBAYAAgMSBFICWAMaZSBHZXRzIGEgbGlzdCBvZiBy
ZXN1bHRzIGZvciBhIGdpdmVuIGEKIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0aW9uXS4KCgwKBQYAAgMBEgNSBhsKDAoFBgACAwIS
A1IcOAoMCgUGAAIDAxIDUw8sCg0KBQYAAgMEEgRUBFYGChEKCQYAAgMEsMq8IhIEVARWBgoM
CgUGAAIDBBIDVwQ4Cg8KCAYAAgMEmwgAEgNXBDgKkwEKAgQAEgReAHABGoYBIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtFdmFsdWF0aW9uU2VydmljZS5HZXRFdmFsdWF0aW9uXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0aW9uU2VydmljZS5HZXRFdmFs
dWF0aW9uXQogbWV0aG9kLgoKCgoDBAABEgNeCBwKgwQKBAQAAgASBGoCbwQa9AMgUmVxdWly
ZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkV2YWx1YXRpb25dLCBzdWNoIGFzCiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2V2YWx1YXRpb25zL3tldmFsdWF0aW9u
fWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gYWNjZXNz
IHRoZQogW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkV2YWx1YXRpb25dLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMs
IGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIHJlcXVl
c3RlZAogW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkV2YWx1YXRpb25dIGRvZXMgbm90CiBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0
dXJuZWQuCgoMCgUEAAIABRIDagIICgwKBQQAAgABEgNqCQ0KDAoFBAACAAMSA2oQEQoNCgUE
AAIACBIEahJvAwoPCggEAAIACJwIABIDawQqCg8KBwQAAgAInwgSBGwEbgUKmAEKAgQBEgV1
AJcBARqKASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2
YWx1YXRpb25zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0
aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvbnNdCiBtZXRob2QuCgoKCgMEAQESA3UIHgrVAgoE
BAECABIFfQKCAQQaxQIgUmVxdWlyZWQuIFRoZSBwYXJlbnQgbG9jYXRpb24gcmVzb3VyY2Ug
bmFtZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gbGlzdAog
W0V2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkV2YWx1
YXRpb25dcyB1bmRlciB0aGlzCiBsb2NhdGlvbiwgcmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9y
IG5vdCB0aGlzIGxvY2F0aW9uIGV4aXN0cywgYQogYFBFUk1JU1NJT05fREVOSUVEYCBlcnJv
ciBpcyByZXR1cm5lZC4KCgwKBQQBAgAFEgN9AggKDAoFBAECAAESA30JDwoMCgUEAQIAAxID
fRITCg4KBQQBAgAIEgV9FIIBAwoPCggEAQIACJwIABIDfgQqChAKBwQBAgAInwgSBX8EgQEF
Cq0CCgQEAQIBEgSKAQI/Gp4CIE9wdGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZgogW0V2YWx1
YXRpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkV2YWx1YXRpb25d
cyB0byByZXR1cm4uIElmCiB1bnNwZWNpZmllZCwgZGVmYXVsdHMgdG8gMTAwLiBUaGUgbWF4
aW11bSBhbGxvd2VkIHZhbHVlIGlzIDEwMDAuIFZhbHVlcwogYWJvdmUgMTAwMCB3aWxsIGJl
IGNvZXJjZWQgdG8gMTAwMC4KCiBJZiB0aGlzIGZpZWxkIGlzIG5lZ2F0aXZlLCBhbiBgSU5W
QUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAQIBBRIEigECBwoNCgUE
AQIBARIEigEIEQoNCgUEAQIBAxIEigEUFQoNCgUEAQIBCBIEigEWPgoQCggEAQIBCJwIABIE
igEXPQrjBAoEBAECAhIElgECQRrUBCBPcHRpb25hbC4gQSBwYWdlIHRva2VuCiBbTGlzdEV2
YWx1YXRpb25zUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0RXZhbHVhdGlvbnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9r
ZW5dLAogcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBbRXZhbHVhdGlvblNlcnZpY2UuTGlz
dEV2YWx1YXRpb25zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFs
dWF0aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvbnNdCiBjYWxsLiBQcm92aWRlIHRoaXMgdG8g
cmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBv
dGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBbRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2
YWx1YXRpb25zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0
aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvbnNdCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQg
cHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uIE90aGVyd2lzZSwgYW4KIGBJTlZBTElEX0FSR1VN
RU5UYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgIFEgSWAQIICg0KBQQBAgIBEgSWAQkT
Cg0KBQQBAgIDEgSWARYXCg0KBQQBAgIIEgSWARhAChAKCAQBAgIInAgAEgSWARk/CpoBCgIE
AhIGnAEApQEBGosBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbRXZhbHVhdGlvblNlcnZpY2Uu
TGlzdEV2YWx1YXRpb25zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5F
dmFsdWF0aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvbnNdCiBtZXRob2QuCgoLCgMEAgESBJwB
CB8KUgoEBAICABIEngECJhpEIFRoZSBbRXZhbHVhdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlvbl1zLgoKDQoFBAICAAQSBJ4BAgoKDQoFBAIC
AAYSBJ4BCxUKDQoFBAICAAESBJ4BFiEKDQoFBAICAAMSBJ4BJCUK7gEKBAQCAgESBKQBAh0a
3wEgQSB0b2tlbiB0aGF0IGNhbiBiZSBzZW50IGFzCiBbTGlzdEV2YWx1YXRpb25zUmVxdWVz
dC5wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0
RXZhbHVhdGlvbnNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRyaWV2ZSB0aGUgbmV4dCBw
YWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubwogc3Vic2VxdWVu
dCBwYWdlcy4KCg0KBQQCAgEFEgSkAQIICg0KBQQCAgEBEgSkAQkYCg0KBQQCAgEDEgSkARsc
CpsBCgIEAxIGqgEAtwEBGowBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtFdmFsdWF0aW9uU2Vy
dmljZS5DcmVhdGVFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5FdmFsdWF0aW9uU2VydmljZS5DcmVhdGVFdmFsdWF0aW9uXQogbWV0aG9kLgoKCwoD
BAMBEgSqAQgfCmkKBAQDAgASBq0BArIBBBpZIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291
cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn1gLgoKDQoFBAMCAAUSBK0BAggKDQoFBAMCAAESBK0BCQ8KDQoFBAMCAAMSBK0BEhMK
DwoFBAMCAAgSBq0BFLIBAwoQCggEAwIACJwIABIErgEEKgoRCgcEAwIACJ8IEgavAQSxAQUK
ZgoEBAMCARIEtgECRRpYIFJlcXVpcmVkLiBUaGUgW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkV2YWx1YXRpb25dCiB0byBjcmVhdGUuCgoNCgUE
AwIBBhIEtgECDAoNCgUEAwIBARIEtgENFwoNCgUEAwIBAxIEtgEaGwoNCgUEAwIBCBIEtgEc
RAoQCggEAwIBCJwIABIEtgEdQwqSAQoCBAQSBLwBACMahQEgTWV0YWRhdGEgZm9yCiBbRXZh
bHVhdGlvblNlcnZpY2UuQ3JlYXRlRXZhbHVhdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuRXZhbHVhdGlvblNlcnZpY2UuQ3JlYXRlRXZhbHVhdGlvbl0KIG1l
dGhvZC4KCgsKAwQEARIEvAEIIAqlAQoCBAUSBsEBAOMBARqWASBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2YWx1YXRpb25SZXN1bHRzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0aW9uU2VydmljZS5MaXN0RXZh
bHVhdGlvblJlc3VsdHNdCiBtZXRob2QuCgoLCgMEBQESBMEBCCQKuQMKBAQFAgASBskBAs4B
BBqoAyBSZXF1aXJlZC4gVGhlIGV2YWx1YXRpb24gcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ldmFsdWF0aW9ucy97
ZXZhbHVhdGlvbn1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9u
IHRvIGxpc3QKIFtMaXN0RXZhbHVhdGlvblJlc3VsdHNSZXNwb25zZS5FdmFsdWF0aW9uUmVz
dWx0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0RXZhbHVhdGlv
blJlc3VsdHNSZXNwb25zZS5FdmFsdWF0aW9uUmVzdWx0XQogdW5kZXIgdGhpcyBldmFsdWF0
aW9uLCByZWdhcmRsZXNzIG9mIHdoZXRoZXIgb3Igbm90IHRoaXMgZXZhbHVhdGlvbiBzZXQK
IGV4aXN0cywgYSBgUEVSTUlTU0lPTl9ERU5JRURgIGVycm9yIGlzIHJldHVybmVkLgoKDQoF
BAUCAAUSBMkBAggKDQoFBAUCAAESBMkBCRMKDQoFBAUCAAMSBMkBFhcKDwoFBAUCAAgSBskB
GM4BAwoQCggEBQIACJwIABIEygEEKgoRCgcEBQIACJ8IEgbLAQTNAQUK9AIKBAQFAgESBNYB
Aj8a5QIgT3B0aW9uYWwuIE1heGltdW0gbnVtYmVyIG9mCiBbTGlzdEV2YWx1YXRpb25SZXN1
bHRzUmVzcG9uc2UuRXZhbHVhdGlvblJlc3VsdF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuTGlzdEV2YWx1YXRpb25SZXN1bHRzUmVzcG9uc2UuRXZhbHVhdGlvblJl
c3VsdF0KIHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1bHRzIHRvIDEwMC4gVGhl
IG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcwogMTAwMC4gVmFsdWVzIGFib3ZlIDEwMDAgd2ls
bCBiZSBjb2VyY2VkIHRvIDEwMDAuCgogSWYgdGhpcyBmaWVsZCBpcyBuZWdhdGl2ZSwgYW4g
YElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAUCAQUSBNYBAgcK
DQoFBAUCAQESBNYBCBEKDQoFBAUCAQMSBNYBFBUKDQoFBAUCAQgSBNYBFj4KEAoIBAUCAQic
CAASBNYBFz0KhwUKBAQFAgISBOIBAkEa+AQgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbgogW0xp
c3RFdmFsdWF0aW9uUmVzdWx0c1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdEV2YWx1YXRpb25SZXN1bHRzUmVzcG9u
c2UubmV4dF9wYWdlX3Rva2VuXSwKIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogW0V2YWx1
YXRpb25TZXJ2aWNlLkxpc3RFdmFsdWF0aW9uUmVzdWx0c11bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2YWx1YXRpb25SZXN1
bHRzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBh
Z2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0
bwogW0V2YWx1YXRpb25TZXJ2aWNlLkxpc3RFdmFsdWF0aW9uUmVzdWx0c11bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2YWx1
YXRpb25SZXN1bHRzXQogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBw
YWdlIHRva2VuLiBPdGhlcndpc2UsIGFuCiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMg
cmV0dXJuZWQuCgoNCgUEBQICBRIE4gECCAoNCgUEBQICARIE4gEJEwoNCgUEBQICAxIE4gEW
FwoNCgUEBQICCBIE4gEYQAoQCggEBQICCJwIABIE4gEZPwqmAQoCBAYSBugBAIACARqXASBS
ZXNwb25zZSBtZXNzYWdlIGZvcgogW0V2YWx1YXRpb25TZXJ2aWNlLkxpc3RFdmFsdWF0aW9u
UmVzdWx0c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlv
blNlcnZpY2UuTGlzdEV2YWx1YXRpb25SZXN1bHRzXQogbWV0aG9kLgoKCwoDBAYBEgToAQgl
CocBCgQEBgMAEgbrAQL1AQMadyBSZXByZXNlbnRzIHRoZSByZXN1bHRzIG9mIGFuIGV2YWx1
YXRpb24gZm9yIGEgc2luZ2xlCiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5XS4KCg0KBQQGAwABEgTrAQoaCncKBgQGAwAC
ABIE7wEETRpnIE91dHB1dCBvbmx5LiBUaGUKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldIHRoYXQgd2FzCiBldmFsdWF0
ZWQuCgoPCgcEBgMAAgAGEgTvAQQPCg8KBwQGAwACAAESBO8BEBwKDwoHBAYDAAIAAxIE7wEf
IAoPCgcEBgMAAgAIEgTvASFMChIKCgQGAwACAAicCAASBO8BIksKlgEKBgQGAwACARIG8wEE
9AE0GoMBIE91dHB1dCBvbmx5LiBUaGUgbWV0cmljcyBwcm9kdWNlZCBieSB0aGUgZXZhbHVh
dGlvbiwgZm9yIGEgZ2l2ZW4KIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldLgoKDwoHBAYDAAIBBhIE8wEEEgoPCgcEBgMA
AgEBEgTzARMiCg8KBwQGAwACAQMSBPMBJSYKDwoHBAYDAAIBCBIE9AEIMwoSCgoEBgMAAgEI
nAgAEgT0AQkyCnAKBAQGAgASBPkBAjMaYiBUaGUgZXZhbHVhdGlvbiByZXN1bHRzIGZvciB0
aGUKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
U2FtcGxlUXVlcnldcy4KCg0KBQQGAgAEEgT5AQIKCg0KBQQGAgAGEgT5AQsbCg0KBQQGAgAB
EgT5ARwuCg0KBQQGAgADEgT5ATEyCvoBCgQEBgIBEgT/AQIdGusBIEEgdG9rZW4gdGhhdCBj
YW4gYmUgc2VudCBhcwogW0xpc3RFdmFsdWF0aW9uUmVzdWx0c1JlcXVlc3QucGFnZV90b2tl
bl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdEV2YWx1YXRpb25S
ZXN1bHRzUmVxdWVzdC5wYWdlX3Rva2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4g
SWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFn
ZXMuCgoNCgUEBgIBBRIE/wECCAoNCgUEBgIBARIE/wEJGAoNCgUEBgIBAxIE/wEbHGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest ===
    # Fields for GetEvaluationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationsRequest ===
    # Fields for ListEvaluationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationsResponse ===
    # Fields for ListEvaluationsResponse
    # Field: evaluations Type: 11 (.google.cloud.discoveryengine.v1beta.Evaluation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::CreateEvaluationRequest ===
    # Fields for CreateEvaluationRequest
    # Field: parent Type: 9 ()
    # Field: evaluation Type: 11 (.google.cloud.discoveryengine.v1beta.Evaluation)

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::CreateEvaluationMetadata ===
    # Fields for CreateEvaluationMetadata

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsRequest ===
    # Fields for ListEvaluationResultsRequest
    # Field: evaluation Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsResponse ===
    # Fields for ListEvaluationResultsResponse
    # Field: evaluation_results Type: 11 (.google.cloud.discoveryengine.v1beta.ListEvaluationResultsResponse.EvaluationResult)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::EvaluationService::EvaluationServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::EvaluationService::EvaluationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::EvaluationService::EvaluationServiceClient

Client stub representing the remote C<EvaluationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub get_evaluation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EvaluationService',
        method         => 'GetEvaluation',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation',
    });
}

sub list_evaluations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EvaluationService',
        method         => 'ListEvaluations',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationsResponse',
    });
}

sub create_evaluation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EvaluationService::CreateEvaluationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EvaluationService',
        method         => 'CreateEvaluation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_evaluation_results {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.EvaluationService',
        method         => 'ListEvaluationResults',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::EvaluationService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/evaluation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::EvaluationService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/evaluation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest

Request message for
[EvaluationService.GetEvaluation][google.cloud.discoveryengine.v1beta.EvaluationService.GetEvaluation]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation], such as
`projects/{project}/locations/{location}/evaluations/{evaluation}`.

If the caller does not have permission to access the
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation] does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationsRequest

Request message for
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluations]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location resource name, such as
`projects/{project}/locations/{location}`.

If the caller does not have permission to list
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation]s under this
location, regardless of whether or not this location exists, a
`PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation]s to return. If
unspecified, defaults to 100. The maximum allowed value is 1000. Values
above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token
[ListEvaluationsResponse.next_page_token][google.cloud.discoveryengine.v1beta.ListEvaluationsResponse.next_page_token],
received from a previous
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluations]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluations]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationsResponse

Response message for
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluations]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluations() >> / C<< $msg->evaluations($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation>)

The [Evaluation][google.cloud.discoveryengine.v1beta.Evaluation]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListEvaluationsRequest.page_token][google.cloud.discoveryengine.v1beta.ListEvaluationsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::CreateEvaluationRequest

Request message for
[EvaluationService.CreateEvaluation][google.cloud.discoveryengine.v1beta.EvaluationService.CreateEvaluation]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->evaluation() >> / C<< $msg->evaluation($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation>)

Required. The [Evaluation][google.cloud.discoveryengine.v1beta.Evaluation]
to create.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::CreateEvaluationMetadata

Metadata for
[EvaluationService.CreateEvaluation][google.cloud.discoveryengine.v1beta.EvaluationService.CreateEvaluation]
method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsRequest

Request message for
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluationResults]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluation() >> / C<< $msg->evaluation($value) >>

Type: C<String>

Required. The evaluation resource name, such as
`projects/{project}/locations/{location}/evaluations/{evaluation}`.

If the caller does not have permission to list
[ListEvaluationResultsResponse.EvaluationResult][google.cloud.discoveryengine.v1beta.ListEvaluationResultsResponse.EvaluationResult]
under this evaluation, regardless of whether or not this evaluation set
exists, a `PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of
[ListEvaluationResultsResponse.EvaluationResult][google.cloud.discoveryengine.v1beta.ListEvaluationResultsResponse.EvaluationResult]
to return. If unspecified, defaults to 100. The maximum allowed value is
1000. Values above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token
[ListEvaluationResultsResponse.next_page_token][google.cloud.discoveryengine.v1beta.ListEvaluationResultsResponse.next_page_token],
received from a previous
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluationResults]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluationResults]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsResponse

Response message for
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1beta.EvaluationService.ListEvaluationResults]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluation_results() >> / C<< $msg->evaluation_results($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::EvaluationService::ListEvaluationResultsResponse::EvaluationResult>)

The evaluation results for the
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListEvaluationResultsRequest.page_token][google.cloud.discoveryengine.v1beta.ListEvaluationResultsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::EvaluationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
