package Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvYXV0aG9yaXphdGlvbl9w
b2xpY3kucHJvdG8SJGdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMRofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8iiwsKE0F1dGhvcml6YXRpb25Qb2xpY3kSFwoEbmFtZRgBIAEoCUID
4EECUgRuYW1lEiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEkAKC2Ny
ZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lEmIKBmxhYmVscxgFIAMoCzJFLmdvb2dsZS5jbG91ZC5uZXR3
b3Jrc2VjdXJpdHkudjFiZXRhMS5BdXRob3JpemF0aW9uUG9saWN5LkxhYmVsc0VudHJ5QgPg
QQFSBmxhYmVscxJdCgZhY3Rpb24YBiABKA4yQC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3Vy
aXR5LnYxYmV0YTEuQXV0aG9yaXphdGlvblBvbGljeS5BY3Rpb25CA+BBAlIGYWN0aW9uElkK
BXJ1bGVzGAcgAygLMj4uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkF1
dGhvcml6YXRpb25Qb2xpY3kuUnVsZUID4EEBUgVydWxlcxqOBQoEUnVsZRJkCgdzb3VyY2Vz
GAEgAygLMkUuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkF1dGhvcml6
YXRpb25Qb2xpY3kuUnVsZS5Tb3VyY2VCA+BBAVIHc291cmNlcxJzCgxkZXN0aW5hdGlvbnMY
AiADKAsySi5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQXV0aG9yaXph
dGlvblBvbGljeS5SdWxlLkRlc3RpbmF0aW9uQgPgQQFSDGRlc3RpbmF0aW9ucxpPCgZTb3Vy
Y2USIwoKcHJpbmNpcGFscxgBIAMoCUID4EEBUgpwcmluY2lwYWxzEiAKCWlwX2Jsb2NrcxgC
IAMoCUID4EEBUghpcEJsb2NrcxrZAgoLRGVzdGluYXRpb24SGQoFaG9zdHMYASADKAlCA+BB
AlIFaG9zdHMSGQoFcG9ydHMYAiADKA1CA+BBAlIFcG9ydHMSHQoHbWV0aG9kcxgEIAMoCUID
4EEBUgdtZXRob2RzEosBChFodHRwX2hlYWRlcl9tYXRjaBgFIAEoCzJaLmdvb2dsZS5jbG91
ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5BdXRob3JpemF0aW9uUG9saWN5LlJ1bGUuRGVz
dGluYXRpb24uSHR0cEhlYWRlck1hdGNoQgPgQQFSD2h0dHBIZWFkZXJNYXRjaBpnCg9IdHRw
SGVhZGVyTWF0Y2gSJgoLcmVnZXhfbWF0Y2gYAiABKAlCA+BBAkgAUgpyZWdleE1hdGNoEiQK
C2hlYWRlcl9uYW1lGAEgASgJQgPgQQJSCmhlYWRlck5hbWVCBgoEdHlwZRo5CgtMYWJlbHNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIjUKBkFj
dGlvbhIWChJBQ1RJT05fVU5TUEVDSUZJRUQQABIJCgVBTExPVxABEggKBERFTlkQAjqOAepB
igEKMm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9BdXRob3JpemF0aW9uUG9saWN5
ElRwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0aG9yaXphdGlv
blBvbGljaWVzL3thdXRob3JpemF0aW9uX3BvbGljeX0ioQEKIExpc3RBdXRob3JpemF0aW9u
UG9saWNpZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29v
Z2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VT
aXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiK9AQohTGlzdEF1dGhvcml6YXRp
b25Qb2xpY2llc1Jlc3BvbnNlEnAKFmF1dGhvcml6YXRpb25fcG9saWNpZXMYASADKAsyOS5n
b29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQXV0aG9yaXphdGlvblBvbGlj
eVIVYXV0aG9yaXphdGlvblBvbGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiJvCh1HZXRBdXRob3JpemF0aW9uUG9saWN5UmVxdWVzdBJOCgRuYW1lGAEg
ASgJQjrgQQL6QTQKMm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9BdXRob3JpemF0
aW9uUG9saWN5UgRuYW1lIqYCCiBDcmVhdGVBdXRob3JpemF0aW9uUG9saWN5UmVxdWVzdBJS
CgZwYXJlbnQYASABKAlCOuBBAvpBNBIybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29t
L0F1dGhvcml6YXRpb25Qb2xpY3lSBnBhcmVudBI7ChdhdXRob3JpemF0aW9uX3BvbGljeV9p
ZBgCIAEoCUID4EECUhVhdXRob3JpemF0aW9uUG9saWN5SWQScQoUYXV0aG9yaXphdGlvbl9w
b2xpY3kYAyABKAsyOS5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQXV0
aG9yaXphdGlvblBvbGljeUID4EECUhNhdXRob3JpemF0aW9uUG9saWN5ItcBCiBVcGRhdGVB
dXRob3JpemF0aW9uUG9saWN5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJxChRhdXRob3JpemF0aW9u
X3BvbGljeRgCIAEoCzI5Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5B
dXRob3JpemF0aW9uUG9saWN5QgPgQQJSE2F1dGhvcml6YXRpb25Qb2xpY3kicgogRGVsZXRl
QXV0aG9yaXphdGlvblBvbGljeVJlcXVlc3QSTgoEbmFtZRgBIAEoCUI64EEC+kE0CjJuZXR3
b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vQXV0aG9yaXphdGlvblBvbGljeVIEbmFtZUKS
AgooY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMUIYQXV0aG9yaXph
dGlvblBvbGljeVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya3NlY3VyaXR5
L2FwaXYxYmV0YTEvbmV0d29ya3NlY3VyaXR5cGI7bmV0d29ya3NlY3VyaXR5cGKqAiRHb29n
bGUuQ2xvdWQuTmV0d29ya1NlY3VyaXR5LlYxQmV0YTHKAiRHb29nbGVcQ2xvdWRcTmV0d29y
a1NlY3VyaXR5XFYxYmV0YTHqAidHb29nbGU6OkNsb3VkOjpOZXR3b3JrU2VjdXJpdHk6OlYx
YmV0YTFKqlMKBxIFDgCCAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQAC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoCAwMSAxUAKQoI
CgEIEgMXAEEKCQoCCCUSAxcAQQoICgEIEgMYAGkKCQoCCAsSAxgAaQoICgEIEgMZACIKCQoC
CAoSAxkAIgoICgEIEgMaADkKCQoCCAgSAxoAOQoICgEIEgMbAEEKCQoCCAESAxsAQQoICgEI
EgMcAEEKCQoCCCkSAxwAQQoICgEIEgMdAEAKCQoCCC0SAx0AQAqEAgoCBAASBSMApAEBGvYB
IEF1dGhvcml6YXRpb25Qb2xpY3kgaXMgYSByZXNvdXJjZSB0aGF0IHNwZWNpZmllcyBob3cg
YSBzZXJ2ZXIKIHNob3VsZCBhdXRob3JpemUgaW5jb21pbmcgY29ubmVjdGlvbnMuIFRoaXMg
cmVzb3VyY2UgaW4gaXRzZWxmIGRvZXMKIG5vdCBjaGFuZ2UgdGhlIGNvbmZpZ3VyYXRpb24g
dW5sZXNzIGl0J3MgYXR0YWNoZWQgdG8gYSB0YXJnZXQgaHR0cHMKIHByb3h5IG9yIGVuZHBv
aW50IGNvbmZpZyBzZWxlY3RvciByZXNvdXJjZS4KCgoKAwQAARIDIwgbCgsKAwQABxIEJAIn
BAoNCgUEAAedCBIEJAInBAonCgQEAAMAEgQqAncDGhkgU3BlY2lmaWNhdGlvbiBvZiBydWxl
cy4KCgwKBQQAAwABEgMqCg4KPQoGBAADAAMAEgQsBDsFGi0gU3BlY2lmaWNhdGlvbiBvZiB0
cmFmZmljIHNvdXJjZSBhdHRyaWJ1dGVzLgoKDgoHBAADAAMAARIDLAwSCpsDCggEAAMAAwAC
ABIDMwZOGokDIE9wdGlvbmFsLiBMaXN0IG9mIHBlZXIgaWRlbnRpdGllcyB0byBtYXRjaCBm
b3IgYXV0aG9yaXphdGlvbi4gQXQgbGVhc3QKIG9uZSBwcmluY2lwYWwgc2hvdWxkIG1hdGNo
LiBFYWNoIHBlZXIgY2FuIGJlIGFuIGV4YWN0IG1hdGNoLCBvciBhCiBwcmVmaXggbWF0Y2gg
KGV4YW1wbGUsICJuYW1lc3BhY2UvKiIpIG9yIGEgc3VmZml4IG1hdGNoIChleGFtcGxlLAog
Iiovc2VydmljZS1hY2NvdW50Iikgb3IgYSBwcmVzZW5jZSBtYXRjaCAiKiIuIEF1dGhvcml6
YXRpb24gYmFzZWQgb24KIHRoZSBwcmluY2lwYWwgbmFtZSB3aXRob3V0IGNlcnRpZmljYXRl
IHZhbGlkYXRpb24gKGNvbmZpZ3VyZWQgYnkKIFNlcnZlclRsc1BvbGljeSByZXNvdXJjZSkg
aXMgY29uc2lkZXJlZCBpbnNlY3VyZS4KChAKCQQAAwADAAIABBIDMwYOChAKCQQAAwADAAIA
BRIDMw8VChAKCQQAAwADAAIAARIDMxYgChAKCQQAAwADAAIAAxIDMyMkChAKCQQAAwADAAIA
CBIDMyVNChMKDAQAAwADAAIACJwIABIDMyZMCtMCCggEAAMAAwACARIDOgZNGsECIE9wdGlv
bmFsLiBMaXN0IG9mIENJRFIgcmFuZ2VzIHRvIG1hdGNoIGJhc2VkIG9uIHNvdXJjZSBJUCBh
ZGRyZXNzLiBBdAogbGVhc3Qgb25lIElQIGJsb2NrIHNob3VsZCBtYXRjaC4gU2luZ2xlIElQ
IChlLmcuLCAiMS4yLjMuNCIpIGFuZCBDSURSCiAoZS5nLiwgIjEuMi4zLjAvMjQiKSBhcmUg
c3VwcG9ydGVkLiBBdXRob3JpemF0aW9uIGJhc2VkIG9uIHNvdXJjZSBJUAogYWxvbmUgc2hv
dWxkIGJlIGF2b2lkZWQuIFRoZSBJUCBhZGRyZXNzZXMgb2YgYW55IGxvYWQgYmFsYW5jZXJz
IG9yCiBwcm94aWVzIHNob3VsZCBiZSBjb25zaWRlcmVkIHVudHJ1c3RlZC4KChAKCQQAAwAD
AAIBBBIDOgYOChAKCQQAAwADAAIBBRIDOg8VChAKCQQAAwADAAIBARIDOhYfChAKCQQAAwAD
AAIBAxIDOiIjChAKCQQAAwADAAIBCBIDOiRMChMKDAQAAwADAAIBCJwIABIDOiVLCkIKBgQA
AwADARIEPgRoBRoyIFNwZWNpZmljYXRpb24gb2YgdHJhZmZpYyBkZXN0aW5hdGlvbiBhdHRy
aWJ1dGVzLgoKDgoHBAADAAMBARIDPgwXCkIKCAQAAwADAQMAEgRABlEHGjAgU3BlY2lmaWNh
dGlvbiBvZiBIVFRQIGhlYWRlciBtYXRjaCBhdHRyaWJ1dGVzLgoKEAoJBAADAAMBAwABEgNA
Dh0KEgoKBAADAAMBAwAIABIEQQhKCQoSCgsEAAMAAwEDAAgAARIDQQ4SCooDCgoEAAMAAwED
AAIAEgNJCkoa9gIgUmVxdWlyZWQuIFRoZSB2YWx1ZSBvZiB0aGUgaGVhZGVyIG11c3QgbWF0
Y2ggdGhlIHJlZ3VsYXIgZXhwcmVzc2lvbgogc3BlY2lmaWVkIGluIHJlZ2V4TWF0Y2guIEZv
ciByZWd1bGFyIGV4cHJlc3Npb24gZ3JhbW1hciwKIHBsZWFzZSBzZWU6IGVuLmNwcHJlZmVy
ZW5jZS5jb20vdy9jcHAvcmVnZXgvZWNtYXNjcmlwdAogRm9yIG1hdGNoaW5nIGFnYWluc3Qg
YSBwb3J0IHNwZWNpZmllZCBpbiB0aGUgSFRUUAogcmVxdWVzdCwgdXNlIGEgaGVhZGVyTWF0
Y2ggd2l0aCBoZWFkZXJOYW1lIHNldCB0byBIb3N0CiBhbmQgYSByZWd1bGFyIGV4cHJlc3Np
b24gdGhhdCBzYXRpc2ZpZXMgdGhlIFJGQzI2MTYgSG9zdAogaGVhZGVyJ3MgcG9ydCBzcGVj
aWZpZXIuCgoSCgsEAAMAAwEDAAIABRIDSQoQChIKCwQAAwADAQMAAgABEgNJERwKEgoLBAAD
AAMBAwACAAMSA0kfIAoSCgsEAAMAAwEDAAIACBIDSSFJChUKDgQAAwADAQMAAgAInAgAEgNJ
IkgK7wEKCgQAAwADAQMAAgESA1AISBrbASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIEhU
VFAgaGVhZGVyIHRvIG1hdGNoLiBGb3IgbWF0Y2hpbmcKIGFnYWluc3QgdGhlIEhUVFAgcmVx
dWVzdCdzIGF1dGhvcml0eSwgdXNlIGEgaGVhZGVyTWF0Y2gKIHdpdGggdGhlIGhlYWRlciBu
YW1lICI6YXV0aG9yaXR5Ii4gRm9yIG1hdGNoaW5nIGEKIHJlcXVlc3QncyBtZXRob2QsIHVz
ZSB0aGUgaGVhZGVyTmFtZSAiOm1ldGhvZCIuCgoSCgsEAAMAAwEDAAIBBRIDUAgOChIKCwQA
AwADAQMAAgEBEgNQDxoKEgoLBAADAAMBAwACAQMSA1AdHgoSCgsEAAMAAwEDAAIBCBIDUB9H
ChUKDgQAAwADAQMAAgEInAgAEgNQIEYKqgIKCAQAAwADAQIAEgNXBkkamAIgUmVxdWlyZWQu
IExpc3Qgb2YgaG9zdCBuYW1lcyB0byBtYXRjaC4gTWF0Y2hlZCBhZ2FpbnN0IHRoZSAiOmF1
dGhvcml0eSIKIGhlYWRlciBpbiBodHRwIHJlcXVlc3RzLiBBdCBsZWFzdCBvbmUgaG9zdCBz
aG91bGQgbWF0Y2guIEVhY2ggaG9zdCBjYW4KIGJlIGFuIGV4YWN0IG1hdGNoLCBvciBhIHBy
ZWZpeCBtYXRjaCAoZXhhbXBsZSAibXlkb21haW4uKiIpIG9yIGEgc3VmZml4CiBtYXRjaCAo
ZXhhbXBsZSAiKi5teW9yZy5jb20iKSBvciBhIHByZXNlbmNlIChhbnkpIG1hdGNoICIqIi4K
ChAKCQQAAwADAQIABBIDVwYOChAKCQQAAwADAQIABRIDVw8VChAKCQQAAwADAQIAARIDVxYb
ChAKCQQAAwADAQIAAxIDVx4fChAKCQQAAwADAQIACBIDVyBIChMKDAQAAwADAQIACJwIABID
VyFHCmEKCAQAAwADAQIBEgNbBkkaUCBSZXF1aXJlZC4gTGlzdCBvZiBkZXN0aW5hdGlvbiBw
b3J0cyB0byBtYXRjaC4gQXQgbGVhc3Qgb25lIHBvcnQgc2hvdWxkCiBtYXRjaC4KChAKCQQA
AwADAQIBBBIDWwYOChAKCQQAAwADAQIBBRIDWw8VChAKCQQAAwADAQIBARIDWxYbChAKCQQA
AwADAQIBAxIDWx4fChAKCQQAAwADAQIBCBIDWyBIChMKDAQAAwADAQIBCJwIABIDWyFHCoUB
CggEAAMAAwECAhIDXwZLGnQgT3B0aW9uYWwuIEEgbGlzdCBvZiBIVFRQIG1ldGhvZHMgdG8g
bWF0Y2guIEF0IGxlYXN0IG9uZSBtZXRob2Qgc2hvdWxkCiBtYXRjaC4gU2hvdWxkIG5vdCBi
ZSBzZXQgZm9yIGdSUEMgc2VydmljZXMuCgoQCgkEAAMAAwECAgQSA18GDgoQCgkEAAMAAwEC
AgUSA18PFQoQCgkEAAMAAwECAgESA18WHQoQCgkEAAMAAwECAgMSA18gIQoQCgkEAAMAAwEC
AggSA18iSgoTCgwEAAMAAwECAgicCAASA18jSQrcAgoIBAADAAMBAgMSBGYGZzMayQIgT3B0
aW9uYWwuIE1hdGNoIGFnYWluc3Qga2V5OnZhbHVlIHBhaXIgaW4gaHR0cCBoZWFkZXIuIFBy
b3ZpZGVzIGEKIGZsZXhpYmxlIG1hdGNoIGJhc2VkIG9uIEhUVFAgaGVhZGVycywgZm9yIHBv
dGVudGlhbGx5IGFkdmFuY2VkIHVzZQogY2FzZXMuIEF0IGxlYXN0IG9uZSBoZWFkZXIgc2hv
dWxkIG1hdGNoLiBBdm9pZCB1c2luZyBoZWFkZXIgbWF0Y2hlcyB0bwogbWFrZSBhdXRob3Jp
emF0aW9uIGRlY2lzaW9ucyB1bmxlc3MgdGhlcmUgaXMgYSBzdHJvbmcgZ3VhcmFudGVlIHRo
YXQKIHJlcXVlc3RzIGFycml2ZSB0aHJvdWdoIGEgdHJ1c3RlZCBjbGllbnQgb3IgcHJveHku
CgoQCgkEAAMAAwECAwYSA2YGFQoQCgkEAAMAAwECAwESA2YWJwoQCgkEAAMAAwECAwMSA2Yq
KwoQCgkEAAMAAwECAwgSA2cKMgoTCgwEAAMAAwECAwicCAASA2cLMQqTAgoGBAADAAIAEgNu
BEkagwIgT3B0aW9uYWwuIExpc3Qgb2YgYXR0cmlidXRlcyBmb3IgdGhlIHRyYWZmaWMgc291
cmNlLiBBbGwgb2YgdGhlIHNvdXJjZXMKIG11c3QgbWF0Y2guIEEgc291cmNlIGlzIGEgbWF0
Y2ggaWYgYm90aCBwcmluY2lwYWxzIGFuZCBpcF9ibG9ja3MgbWF0Y2guCiBJZiBub3Qgc2V0
LCB0aGUgYWN0aW9uIHNwZWNpZmllZCBpbiB0aGUgJ2FjdGlvbicgZmllbGQgd2lsbCBiZSBh
cHBsaWVkCiB3aXRob3V0IGFueSBydWxlIGNoZWNrcyBmb3IgdGhlIHNvdXJjZS4KCg4KBwQA
AwACAAQSA24EDAoOCgcEAAMAAgAGEgNuDRMKDgoHBAADAAIAARIDbhQbCg4KBwQAAwACAAMS
A24eHwoOCgcEAAMAAgAIEgNuIEgKEQoKBAADAAIACJwIABIDbiFHCssCCgYEAAMAAgESBHUE
djEaugIgT3B0aW9uYWwuIExpc3Qgb2YgYXR0cmlidXRlcyBmb3IgdGhlIHRyYWZmaWMgZGVz
dGluYXRpb24uIEFsbCBvZiB0aGUKIGRlc3RpbmF0aW9ucyBtdXN0IG1hdGNoLiBBIGRlc3Rp
bmF0aW9uIGlzIGEgbWF0Y2ggaWYgYSByZXF1ZXN0IG1hdGNoZXMKIGFsbCB0aGUgc3BlY2lm
aWVkIGhvc3RzLCBwb3J0cywgbWV0aG9kcyBhbmQgaGVhZGVycy4gSWYgbm90IHNldCwgdGhl
CiBhY3Rpb24gc3BlY2lmaWVkIGluIHRoZSAnYWN0aW9uJyBmaWVsZCB3aWxsIGJlIGFwcGxp
ZWQgd2l0aG91dCBhbnkgcnVsZQogY2hlY2tzIGZvciB0aGUgZGVzdGluYXRpb24uCgoOCgcE
AAMAAgEEEgN1BAwKDgoHBAADAAIBBhIDdQ0YCg4KBwQAAwACAQESA3UZJQoOCgcEAAMAAgED
EgN1KCkKDgoHBAADAAIBCBIDdggwChEKCgQAAwACAQicCAASA3YJLwpBCgQEAAQAEgV6AoUB
AxoyIFBvc3NpYmxlIHZhbHVlcyB0aGF0IGRlZmluZSB3aGF0IGFjdGlvbiB0byB0YWtlLgoK
DAoFBAAEAAESA3oHDQofCgYEAAQAAgASA3wEGxoQIERlZmF1bHQgdmFsdWUuCgoOCgcEAAQA
AgABEgN8BBYKDgoHBAAEAAIAAhIDfBkaCh4KBgQABAACARIDfwQOGg8gR3JhbnQgYWNjZXNz
LgoKDgoHBAAEAAIBARIDfwQJCg4KBwQABAACAQISA38MDQp8CgYEAAQAAgISBIQBBA0abCBE
ZW55IGFjY2Vzcy4KIERlbnkgcnVsZXMgc2hvdWxkIGJlIGF2b2lkZWQgdW5sZXNzIHRoZXkg
YXJlIHVzZWQgdG8gcHJvdmlkZSBhIGRlZmF1bHQKICJkZW55IGFsbCIgZmFsbGJhY2suCgoP
CgcEAAQAAgIBEgSEAQQICg8KBwQABAACAgISBIQBCwwKsAEKBAQAAgASBIkBAjsaoQEgUmVx
dWlyZWQuIE5hbWUgb2YgdGhlIEF1dGhvcml6YXRpb25Qb2xpY3kgcmVzb3VyY2UuIEl0IG1h
dGNoZXMgcGF0dGVybgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hdXRob3JpemF0aW9uUG9saWNpZXMvPGF1dGhvcml6YXRpb25fcG9saWN5PmAuCgoNCgUE
AAIABRIEiQECCAoNCgUEAAIAARIEiQEJDQoNCgUEAAIAAxIEiQEQEQoNCgUEAAIACBIEiQES
OgoQCggEAAIACJwIABIEiQETOQpACgQEAAIBEgSMAQJCGjIgT3B0aW9uYWwuIEZyZWUtdGV4
dCBkZXNjcmlwdGlvbiBvZiB0aGUgcmVzb3VyY2UuCgoNCgUEAAIBBRIEjAECCAoNCgUEAAIB
ARIEjAEJFAoNCgUEAAIBAxIEjAEXGAoNCgUEAAIBCBIEjAEZQQoQCggEAAIBCJwIABIEjAEa
QApLCgQEAAICEgaPAQKQATIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRo
ZSByZXNvdXJjZSB3YXMgY3JlYXRlZC4KCg0KBQQAAgIGEgSPAQIbCg0KBQQAAgIBEgSPARwn
Cg0KBQQAAgIDEgSPASorCg0KBQQAAgIIEgSQAQYxChAKCAQAAgIInAgAEgSQAQcwCksKBAQA
AgMSBpMBApQBMho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291
cmNlIHdhcyB1cGRhdGVkLgoKDQoFBAACAwYSBJMBAhsKDQoFBAACAwESBJMBHCcKDQoFBAAC
AwMSBJMBKisKDQoFBAACAwgSBJQBBjEKEAoIBAACAwicCAASBJQBBzAKXgoEBAACBBIEmAEC
ShpQIE9wdGlvbmFsLiBTZXQgb2YgbGFiZWwgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIEF1
dGhvcml6YXRpb25Qb2xpY3kKIHJlc291cmNlLgoKDQoFBAACBAYSBJgBAhUKDQoFBAACBAES
BJgBFhwKDQoFBAACBAMSBJgBHyAKDQoFBAACBAgSBJgBIUkKEAoIBAACBAicCAASBJgBIkgK
cAoEBAACBRIEnAECPRpiIFJlcXVpcmVkLiBUaGUgYWN0aW9uIHRvIHRha2Ugd2hlbiBhIHJ1
bGUgbWF0Y2ggaXMgZm91bmQuIFBvc3NpYmxlIHZhbHVlcwogYXJlICJBTExPVyIgb3IgIkRF
TlkiLgoKDQoFBAACBQYSBJwBAggKDQoFBAACBQESBJwBCQ8KDQoFBAACBQMSBJwBEhMKDQoF
BAACBQgSBJwBFDwKEAoIBAACBQicCAASBJwBFTsKxwIKBAQAAgYSBKMBAkMauAIgT3B0aW9u
YWwuIExpc3Qgb2YgcnVsZXMgdG8gbWF0Y2guIE5vdGUgdGhhdCBhdCBsZWFzdCBvbmUgb2Yg
dGhlIHJ1bGVzIG11c3QKIG1hdGNoIGluIG9yZGVyIGZvciB0aGUgYWN0aW9uIHNwZWNpZmll
ZCBpbiB0aGUgJ2FjdGlvbicgZmllbGQgdG8gYmUgdGFrZW4uCiBBIHJ1bGUgaXMgYSBtYXRj
aCBpZiB0aGVyZSBpcyBhIG1hdGNoaW5nIHNvdXJjZSBhbmQgZGVzdGluYXRpb24uIElmIGxl
ZnQKIGJsYW5rLCB0aGUgYWN0aW9uIHNwZWNpZmllZCBpbiB0aGUgYGFjdGlvbmAgZmllbGQg
d2lsbCBiZSBhcHBsaWVkIG9uIGV2ZXJ5CiByZXF1ZXN0LgoKDQoFBAACBgQSBKMBAgoKDQoF
BAACBgYSBKMBCw8KDQoFBAACBgESBKMBEBUKDQoFBAACBgMSBKMBGBkKDQoFBAACBggSBKMB
GkIKEAoIBAACBgicCAASBKMBG0EKRwoCBAESBqcBALoBARo5IFJlcXVlc3QgdXNlZCB3aXRo
IHRoZSBMaXN0QXV0aG9yaXphdGlvblBvbGljaWVzIG1ldGhvZC4KCgsKAwQBARIEpwEIKAqx
AQoEBAECABIGqwECsAEEGqABIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24g
ZnJvbSB3aGljaCB0aGUgQXV0aG9yaXphdGlvblBvbGljaWVzCiBzaG91bGQgYmUgbGlzdGVk
LCBzcGVjaWZpZWQgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufWAuCgoNCgUEAQIABRIEqwECCAoNCgUEAQIAARIEqwEJDwoNCgUEAQIA
AxIEqwESEwoPCgUEAQIACBIGqwEUsAEDChAKCAQBAgAInAgAEgSsAQQqChEKBwQBAgAInwgS
Bq0BBK8BBQpLCgQEAQIBEgSzAQIWGj0gTWF4aW11bSBudW1iZXIgb2YgQXV0aG9yaXphdGlv
blBvbGljaWVzIHRvIHJldHVybiBwZXIgY2FsbC4KCg0KBQQBAgEFEgSzAQIHCg0KBQQBAgEB
EgSzAQgRCg0KBQQBAgEDEgSzARQVCuIBCgQEAQICEgS5AQIYGtMBIFRoZSB2YWx1ZSByZXR1
cm5lZCBieSB0aGUgbGFzdAogYExpc3RBdXRob3JpemF0aW9uUG9saWNpZXNSZXNwb25zZWAg
SW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBhCiBjb250aW51YXRpb24gb2YgYSBwcmlvciBgTGlz
dEF1dGhvcml6YXRpb25Qb2xpY2llc2AgY2FsbCwgYW5kCiB0aGF0IHRoZSBzeXN0ZW0gc2hv
dWxkIHJldHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoNCgUEAQICBRIEuQECCAoNCgUE
AQICARIEuQEJEwoNCgUEAQICAxIEuQEWFwpKCgIEAhIGvQEAxQEBGjwgUmVzcG9uc2UgcmV0
dXJuZWQgYnkgdGhlIExpc3RBdXRob3JpemF0aW9uUG9saWNpZXMgbWV0aG9kLgoKCwoDBAIB
EgS9AQgpCjgKBAQCAgASBL8BAjoaKiBMaXN0IG9mIEF1dGhvcml6YXRpb25Qb2xpY2llcyBy
ZXNvdXJjZXMuCgoNCgUEAgIABBIEvwECCgoNCgUEAgIABhIEvwELHgoNCgUEAgIAARIEvwEf
NQoNCgUEAgIAAxIEvwE4OQrpAQoEBAICARIExAECHRraASBJZiB0aGVyZSBtaWdodCBiZSBt
b3JlIHJlc3VsdHMgdGhhbiB0aG9zZSBhcHBlYXJpbmcgaW4gdGhpcyByZXNwb25zZSwgdGhl
bgogYG5leHRfcGFnZV90b2tlbmAgaXMgaW5jbHVkZWQuIFRvIGdldCB0aGUgbmV4dCBzZXQg
b2YgcmVzdWx0cywgY2FsbCB0aGlzCiBtZXRob2QgYWdhaW4gdXNpbmcgdGhlIHZhbHVlIG9m
IGBuZXh0X3BhZ2VfdG9rZW5gIGFzIGBwYWdlX3Rva2VuYC4KCg0KBQQCAgEFEgTEAQIICg0K
BQQCAgEBEgTEAQkYCg0KBQQCAgEDEgTEARscCkIKAgQDEgbIAQDRAQEaNCBSZXF1ZXN0IHVz
ZWQgYnkgdGhlIEdldEF1dGhvcml6YXRpb25Qb2xpY3kgbWV0aG9kLgoKCwoDBAMBEgTIAQgl
CqABCgQEAwIAEgbLAQLQAQQajwEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgQXV0aG9yaXph
dGlvblBvbGljeSB0byBnZXQuIE11c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRob3JpemF0aW9uUG9saWNpZXMvKmAu
CgoNCgUEAwIABRIEywECCAoNCgUEAwIAARIEywEJDQoNCgUEAwIAAxIEywEQEQoPCgUEAwIA
CBIGywES0AEDChAKCAQDAgAInAgAEgTMAQQqChEKBwQDAgAInwgSBs0BBM8BBQpFCgIEBBIG
1AEA5wEBGjcgUmVxdWVzdCB1c2VkIGJ5IHRoZSBDcmVhdGVBdXRob3JpemF0aW9uUG9saWN5
IG1ldGhvZC4KCgsKAwQEARIE1AEIKAqNAQoEBAQCABIG1wEC3AEEGn0gUmVxdWlyZWQuIFRo
ZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIEF1dGhvcml6YXRpb25Qb2xpY3kuIE11c3QgYmUg
aW4gdGhlCiBmb3JtYXQgYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fWAuCgoNCgUEBAIABRIE1wECCAoNCgUEBAIAARIE1wEJDwoNCgUEBAIAAxIE1wESEwoPCgUE
BAIACBIG1wEU3AEDChAKCAQEAgAInAgAEgTYAQQqChEKBwQEAgAInwgSBtkBBNsBBQr7AQoE
BAQCARIE4gECThrsASBSZXF1aXJlZC4gU2hvcnQgbmFtZSBvZiB0aGUgQXV0aG9yaXphdGlv
blBvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLgogVGhpcyB2YWx1ZSBzaG91bGQgYmUg
MS02MyBjaGFyYWN0ZXJzIGxvbmcsIGNvbnRhaW5pbmcgb25seQogbGV0dGVycywgbnVtYmVy
cywgaHlwaGVucywgYW5kIHVuZGVyc2NvcmVzLCBhbmQgc2hvdWxkIG5vdCBzdGFydAogd2l0
aCBhIG51bWJlci4gRS5nLiAiYXV0aHpfcG9saWN5Ii4KCg0KBQQEAgEFEgTiAQIICg0KBQQE
AgEBEgTiAQkgCg0KBQQEAgEDEgTiASMkCg0KBQQEAgEIEgTiASVNChAKCAQEAgEInAgAEgTi
ASZMCkcKBAQEAgISBuUBAuYBLxo3IFJlcXVpcmVkLiBBdXRob3JpemF0aW9uUG9saWN5IHJl
c291cmNlIHRvIGJlIGNyZWF0ZWQuCgoNCgUEBAICBhIE5QECFQoNCgUEBAICARIE5QEWKgoN
CgUEBAICAxIE5QEtLgoNCgUEBAICCBIE5gEGLgoQCggEBAICCJwIABIE5gEHLQpFCgIEBRIG
6gEA9gEBGjcgUmVxdWVzdCB1c2VkIGJ5IHRoZSBVcGRhdGVBdXRob3JpemF0aW9uUG9saWN5
IG1ldGhvZC4KCgsKAwQFARIE6gEIKArlAgoEBAUCABIG8AEC8QEvGtQCIE9wdGlvbmFsLiBG
aWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0
dGVuIGluIHRoZQogQXV0aG9yaXphdGlvblBvbGljeSByZXNvdXJjZSBieSB0aGUgdXBkYXRl
LgogVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2
ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxs
IGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9l
cyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0
ZW4uCgoNCgUEBQIABhIE8AECGwoNCgUEBQIAARIE8AEcJwoNCgUEBQIAAxIE8AEqKwoNCgUE
BQIACBIE8QEGLgoQCggEBQIACJwIABIE8QEHLQpBCgQEBQIBEgb0AQL1AS8aMSBSZXF1aXJl
ZC4gVXBkYXRlZCBBdXRob3JpemF0aW9uUG9saWN5IHJlc291cmNlLgoKDQoFBAUCAQYSBPQB
AhUKDQoFBAUCAQESBPQBFioKDQoFBAUCAQMSBPQBLS4KDQoFBAUCAQgSBPUBBi4KEAoIBAUC
AQicCAASBPUBBy0KRQoCBAYSBvkBAIICARo3IFJlcXVlc3QgdXNlZCBieSB0aGUgRGVsZXRl
QXV0aG9yaXphdGlvblBvbGljeSBtZXRob2QuCgoLCgMEBgESBPkBCCgKowEKBAQGAgASBvwB
AoECBBqSASBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBBdXRob3JpemF0aW9uUG9saWN5IHRv
IGRlbGV0ZS4gTXVzdCBiZSBpbiB0aGUKIGZvcm1hdCBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2F1dGhvcml6YXRpb25Qb2xpY2llcy8qYC4KCg0KBQQGAgAF
EgT8AQIICg0KBQQGAgABEgT8AQkNCg0KBQQGAgADEgT8ARARCg8KBQQGAgAIEgb8ARKBAgMK
EAoIBAYCAAicCAASBP0BBCoKEQoHBAYCAAifCBIG/gEEgAIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy ===
    # Fields for AuthorizationPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1beta1.AuthorizationPolicy.LabelsEntry)
    # Field: action Type: 14 (.google.cloud.networksecurity.v1beta1.AuthorizationPolicy.Action)
    # Field: rules Type: 11 (.google.cloud.networksecurity.v1beta1.AuthorizationPolicy.Rule)

# Enum: AuthorizationPolicy::Action
our $AuthorizationPolicy_ACTION_UNSPECIFIED = 0;
our $AuthorizationPolicy_ALLOW = 1;
our $AuthorizationPolicy_DENY = 2;

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::ListAuthorizationPoliciesRequest ===
    # Fields for ListAuthorizationPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::ListAuthorizationPoliciesResponse ===
    # Fields for ListAuthorizationPoliciesResponse
    # Field: authorization_policies Type: 11 (.google.cloud.networksecurity.v1beta1.AuthorizationPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::GetAuthorizationPolicyRequest ===
    # Fields for GetAuthorizationPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::CreateAuthorizationPolicyRequest ===
    # Fields for CreateAuthorizationPolicyRequest
    # Field: parent Type: 9 ()
    # Field: authorization_policy_id Type: 9 ()
    # Field: authorization_policy Type: 11 (.google.cloud.networksecurity.v1beta1.AuthorizationPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest ===
    # Fields for UpdateAuthorizationPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: authorization_policy Type: 11 (.google.cloud.networksecurity.v1beta1.AuthorizationPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest ===
    # Fields for DeleteAuthorizationPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/authorization_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy;

    my $msg = Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/authorization_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy

AuthorizationPolicy is a resource that specifies how a server
should authorize incoming connections. This resource in itself does
not change the configuration unless it's attached to a target https
proxy or endpoint config selector resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the AuthorizationPolicy resource. It matches pattern
`projects/{project}/locations/{location}/authorizationPolicies/<authorization_policy>`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy::LabelsEntry>)

Optional. Set of label tags associated with the AuthorizationPolicy
resource.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::Action>)

Required. The action to take when a rule match is found. Possible values
are "ALLOW" or "DENY".

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy::Rule>)

Optional. List of rules to match. Note that at least one of the rules must
match in order for the action specified in the 'action' field to be taken.
A rule is a match if there is a matching source and destination. If left
blank, the action specified in the `action` field will be applied on every
request.

=back

=head3 Enum: AuthorizationPolicy::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<ALLOW> => C<1>

=item * C<DENY> => C<2>

=back

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::ListAuthorizationPoliciesRequest

Request used with the ListAuthorizationPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the AuthorizationPolicies
should be listed, specified in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of AuthorizationPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last
`ListAuthorizationPoliciesResponse` Indicates that this is a
continuation of a prior `ListAuthorizationPolicies` call, and
that the system should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::ListAuthorizationPoliciesResponse

Response returned by the ListAuthorizationPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->authorization_policies() >> / C<< $msg->authorization_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy>)

List of AuthorizationPolicies resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::GetAuthorizationPolicyRequest

Request used by the GetAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the AuthorizationPolicy to get. Must be in the format
`projects/{project}/locations/{location}/authorizationPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::CreateAuthorizationPolicyRequest

Request used by the CreateAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the AuthorizationPolicy. Must be in the
format `projects/{project}/locations/{location}`.

=item * C<< $msg->authorization_policy_id() >> / C<< $msg->authorization_policy_id($value) >>

Type: C<String>

Required. Short name of the AuthorizationPolicy resource to be created.
This value should be 1-63 characters long, containing only
letters, numbers, hyphens, and underscores, and should not start
with a number. E.g. "authz_policy".

=item * C<< $msg->authorization_policy() >> / C<< $msg->authorization_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy>)

Required. AuthorizationPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest

Request used by the UpdateAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
AuthorizationPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->authorization_policy() >> / C<< $msg->authorization_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy>)

Required. Updated AuthorizationPolicy resource.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest

Request used by the DeleteAuthorizationPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the AuthorizationPolicy to delete. Must be in the
format `projects/{project}/locations/{location}/authorizationPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
