package Google::Cloud::Discoveryengine::V1alpha::ControlService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Control };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29udHJvbF9zZXJ2aWNl
LnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjJn
b29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29udHJvbC5wcm90bxobZ29v
Z2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5w
cm90byLQAQoUQ3JlYXRlQ29udHJvbFJlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgS
JmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db250cm9sUgZwYXJlbnQSTAoHY29u
dHJvbBgCIAEoCzItLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db250
cm9sQgPgQQJSB2NvbnRyb2wSIgoKY29udHJvbF9pZBgDIAEoCUID4EECUgljb250cm9sSWQi
pgEKFFVwZGF0ZUNvbnRyb2xSZXF1ZXN0EkwKB2NvbnRyb2wYASABKAsyLS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29udHJvbEID4EECUgdjb250cm9sEkAKC3Vw
ZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRh
dGVNYXNrIloKFERlbGV0ZUNvbnRyb2xSZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpBKAom
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NvbnRyb2xSBG5hbWUiVwoRR2V0Q29u
dHJvbFJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZkaXNjb3ZlcnllbmdpbmUuZ29v
Z2xlYXBpcy5jb20vQ29udHJvbFIEbmFtZSLAAQoTTGlzdENvbnRyb2xzUmVxdWVzdBJGCgZw
YXJlbnQYASABKAlCLuBBAvpBKBImZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0Nv
bnRyb2xSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFn
ZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZp
bHRlciKJAQoUTGlzdENvbnRyb2xzUmVzcG9uc2USSQoIY29udHJvbHMYASADKAsyLS5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29udHJvbFIIY29udHJvbHMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMt0PCg5Db250cm9sU2Vydmlj
ZRKYAwoNQ3JlYXRlQ29udHJvbBI6Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5DcmVhdGVDb250cm9sUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5Db250cm9sIpsCgtPkkwL4ASI+L3YxYWxwaGEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vY29udHJvbHM6B2NvbnRyb2xaVyJML3Yx
YWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0
YVN0b3Jlcy8qfS9jb250cm9sczoHY29udHJvbFpUIkkvdjFhbHBoYS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyp9L2NvbnRyb2xzOgdj
b250cm9s2kEZcGFyZW50LGNvbnRyb2wsY29udHJvbF9pZBLRAgoNRGVsZXRlQ29udHJvbBI6
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EZWxldGVDb250cm9sUmVx
dWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSLrAYLT5JMC3QEqPi92MWFscGhhL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL2NvbnRyb2xzLyp9Wk4qTC92
MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyovY29udHJvbHMvKn1aSypJL3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9jb250cm9scy8qfdpBBG5hbWUSqgMK
DVVwZGF0ZUNvbnRyb2wSOi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
VXBkYXRlQ29udHJvbFJlcXVlc3QaLS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuQ29udHJvbCKtAoLT5JMCkAIyRi92MWFscGhhL3tjb250cm9sLm5hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovY29udHJvbHMvKn06B2NvbnRyb2xaXzJU
L3YxYWxwaGEve2NvbnRyb2wubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rp
b25zLyovZGF0YVN0b3Jlcy8qL2NvbnRyb2xzLyp9Ogdjb250cm9sWlwyUS92MWFscGhhL3tj
b250cm9sLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2lu
ZXMvKi9jb250cm9scy8qfToHY29udHJvbNpBE2NvbnRyb2wsdXBkYXRlX21hc2sS4gIKCkdl
dENvbnRyb2wSNy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuR2V0Q29u
dHJvbFJlcXVlc3QaLS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29u
dHJvbCLrAYLT5JMC3QESPi92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGF0YVN0b3Jlcy8qL2NvbnRyb2xzLyp9Wk4STC92MWFscGhhL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovY29udHJvbHMvKn1aSxJJ
L3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2Vu
Z2luZXMvKi9jb250cm9scy8qfdpBBG5hbWUS9QIKDExpc3RDb250cm9scxI5Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0Q29udHJvbHNSZXF1ZXN0GjouZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RDb250cm9sc1Jlc3BvbnNl
Iu0BgtPkkwLdARI+L3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rh
dGFTdG9yZXMvKn0vY29udHJvbHNaThJML3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfS9jb250cm9sc1pLEkkvdjFh
bHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdp
bmVzLyp9L2NvbnRyb2xz2kEGcGFyZW50GlLKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3Jt
Qp8CCihjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhQhNDb250cm9s
U2VydmljZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2Fw
aXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZF
UllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29n
bGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNj
b3ZlcnlFbmdpbmU6OlYxYWxwaGFKjzEKBxIFDgDrAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMU
ACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA8CgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMa
AEEKCQoCCCUSAxoAQQoICgEIEgMbAGkKCQoCCAsSAxsAaQoICgEIEgMcACIKCQoCCAoSAxwA
IgoICgEIEgMdADQKCQoCCAgSAx0ANAoICgEIEgMeAEEKCQoCCAESAx4AQQoICgEIEgMfAC0K
CQoCCCQSAx8ALQoICgEIEgMgAEEKCQoCCCkSAyAAQQoICgEIEgMhAEAKCQoCCC0SAyEAQArh
AQoCBgASBScAhAEBGtMBIFNlcnZpY2UgZm9yIHBlcmZvcm1pbmcgQ1JVRCBvcGVyYXRpb25z
IG9uIENvbnRyb2xzLgogQ29udHJvbHMgYWxsb3cgZm9yIGN1c3RvbSBsb2dpYyB0byBiZSBp
bXBsZW1lbnRlZCBpbiB0aGUgc2VydmluZyBwYXRoLgogQ29udHJvbHMgbmVlZCB0byBiZSBh
dHRhY2hlZCB0byBhIFNlcnZpbmcgQ29uZmlnIHRvIGJlIGNvbnNpZGVyZWQgZHVyaW5nIGEK
IHJlcXVlc3QuCgoKCgMGAAESAycIFgoKCgMGAAMSAygCRgoMCgUGAAOZCBIDKAJGCgsKAwYA
AxIEKQIqNwoNCgUGAAOaCBIEKQIqNwqOAgoEBgACABIEMgJAAxr/ASBDcmVhdGVzIGEgQ29u
dHJvbC4KCiBCeSBkZWZhdWx0IDEwMDAgY29udHJvbHMgYXJlIGFsbG93ZWQgZm9yIGEgZGF0
YSBzdG9yZS4KIEEgcmVxdWVzdCBjYW4gYmUgc3VibWl0dGVkIHRvIGFkanVzdCB0aGlzIGxp
bWl0LgogSWYgdGhlIFtDb250cm9sXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuQ29udHJvbF0gdG8gY3JlYXRlCiBhbHJlYWR5IGV4aXN0cywgYW4gQUxSRUFEWV9F
WElTVFMgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAIAARIDMgYTCgwKBQYAAgACEgMyFCgK
DAoFBgACAAMSAzIzOgoNCgUGAAIABBIEMwQ+BgoRCgkGAAIABLDKvCISBDMEPgYKDAoFBgAC
AAQSAz8ERwoPCggGAAIABJsIABIDPwRHCp4BCgQGAAIBEgRGAlEDGo8BIERlbGV0ZXMgYSBD
b250cm9sLgoKIElmIHRoZSBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLkNvbnRyb2xdIHRvIGRlbGV0ZQogZG9lcyBub3QgZXhpc3QsIGEgTk9UX0ZP
VU5EIGVycm9yIGlzIHJldHVybmVkLgoKDAoFBgACAQESA0YGEwoMCgUGAAIBAhIDRhQoCgwK
BQYAAgEDEgNGM0gKDQoFBgACAQQSBEcETwYKEQoJBgACAQSwyrwiEgRHBE8GCgwKBQYAAgEE
EgNQBDIKDwoIBgACAQSbCAASA1AEMgr2AQoEBgACAhIEWAJmAxrnASBVcGRhdGVzIGEgQ29u
dHJvbC4KCiBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkNvbnRyb2xdIGFjdGlvbiB0eXBlIGNhbm5vdAogYmUgY2hhbmdlZC4gSWYgdGhlIFtDb250
cm9sXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29udHJvbF0KIHRv
IHVwZGF0ZSBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQu
CgoMCgUGAAICARIDWAYTCgwKBQYAAgICEgNYFCgKDAoFBgACAgMSA1gzOgoNCgUGAAICBBIE
WQRkBgoRCgkGAAICBLDKvCISBFkEZAYKDAoFBgACAgQSA2UEQQoPCggGAAICBJsIABIDZQRB
Ch8KBAYAAgMSBGkCdAMaESBHZXRzIGEgQ29udHJvbC4KCgwKBQYAAgMBEgNpBhAKDAoFBgAC
AwISA2kRIgoMCgUGAAIDAxIDaS00Cg0KBQYAAgMEEgRqBHIGChEKCQYAAgMEsMq8IhIEagRy
BgoMCgUGAAIDBBIDcwQyCg8KCAYAAgMEmwgAEgNzBDIKcQoEBgACBBIFeAKDAQMaYiBMaXN0
cyBhbGwgQ29udHJvbHMgYnkgdGhlaXIgcGFyZW50CiBbRGF0YVN0b3JlXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlXS4KCgwKBQYAAgQBEgN4BhIK
DAoFBgACBAISA3gTJgoMCgUGAAIEAxIDeDFFCg4KBQYAAgQEEgV5BIEBBgoSCgkGAAIEBLDK
vCISBXkEgQEGCg0KBQYAAgQEEgSCAQQ0ChAKCAYAAgQEmwgAEgSCAQQ0CjEKAgQAEgaHAQCc
AQEaIyBSZXF1ZXN0IGZvciBDcmVhdGVDb250cm9sIG1ldGhvZC4KCgsKAwQAARIEhwEIHAqj
AgoEBAACABIGjAECkQEEGpICIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgcGFy
ZW50IGRhdGEgc3RvcmUuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xv
Y2F0aW9ucy97bG9jYXRpb25faWR9L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9kYXRh
U3RvcmVzL3tkYXRhX3N0b3JlX2lkfWAKIG9yCiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVy
fS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0v
ZW5naW5lcy97ZW5naW5lX2lkfWAuCgoNCgUEAAIABRIEjAECCAoNCgUEAAIAARIEjAEJDwoN
CgUEAAIAAxIEjAESEwoPCgUEAAIACBIGjAEUkQEDChAKCAQAAgAInAgAEgSNAQQqChEKBwQA
AgAInwgSBo4BBJABBQowCgQEAAIBEgSUAQI/GiIgUmVxdWlyZWQuIFRoZSBDb250cm9sIHRv
IGNyZWF0ZS4KCg0KBQQAAgEGEgSUAQIJCg0KBQQAAgEBEgSUAQoRCg0KBQQAAgEDEgSUARQV
Cg0KBQQAAgEIEgSUARY+ChAKCAQAAgEInAgAEgSUARc9CtMBCgQEAAICEgSbAQJBGsQBIFJl
cXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgQ29udHJvbCwgd2hpY2ggd2lsbCBiZWNv
bWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIENvbnRyb2wncyByZXNvdXJjZSBuYW1l
LgoKIFRoaXMgdmFsdWUgbXVzdCBiZSB3aXRoaW4gMS02MyBjaGFyYWN0ZXJzLgogVmFsaWQg
Y2hhcmFjdGVycyBhcmUgL1thLXpdWzAtOV0tXy8uCgoNCgUEAAICBRIEmwECCAoNCgUEAAIC
ARIEmwEJEwoNCgUEAAICAxIEmwEWFwoNCgUEAAICCBIEmwEYQAoQCggEAAICCJwIABIEmwEZ
PwoxCgIEARIGnwEArQEBGiMgUmVxdWVzdCBmb3IgVXBkYXRlQ29udHJvbCBtZXRob2QuCgoL
CgMEAQESBJ8BCBwKMAoEBAECABIEoQECPxoiIFJlcXVpcmVkLiBUaGUgQ29udHJvbCB0byB1
cGRhdGUuCgoNCgUEAQIABhIEoQECCQoNCgUEAQIAARIEoQEKEQoNCgUEAQIAAxIEoQEUFQoN
CgUEAQIACBIEoQEWPgoQCggEAQIACJwIABIEoQEXPQr/AgoEBAECARIGqwECrAEvGu4CIE9w
dGlvbmFsLiBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0NvbnRy
b2xdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db250cm9sXSB0byB1
cGRhdGUuIFRoZQogZm9sbG93aW5nIGFyZSBOT1Qgc3VwcG9ydGVkOgoKICogW0NvbnRyb2wu
bmFtZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNvbnRyb2wubmFt
ZV0KICogW0NvbnRyb2wuc29sdXRpb25fdHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLkNvbnRyb2wuc29sdXRpb25fdHlwZV0KCiBJZiBub3Qgc2V0IG9yIGVt
cHR5LCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBhcmUgdXBkYXRlZC4KCg0KBQQBAgEGEgSrAQIb
Cg0KBQQBAgEBEgSrARwnCg0KBQQBAgEDEgSrASorCg0KBQQBAgEIEgSsAQYuChAKCAQBAgEI
nAgAEgSsAQctCjEKAgQCEgawAQC5AQEaIyBSZXF1ZXN0IGZvciBEZWxldGVDb250cm9sIG1l
dGhvZC4KCgsKAwQCARIEsAEIHArSAQoEBAICABIGswECuAEEGsEBIFJlcXVpcmVkLiBUaGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgQ29udHJvbCB0byBkZWxldGUuIEZvcm1hdDoKIGBwcm9q
ZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NvbGxlY3Rp
b25zL3tjb2xsZWN0aW9uX2lkfS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlX2lkfS9jb250cm9s
cy97Y29udHJvbF9pZH1gCgoNCgUEAgIABRIEswECCAoNCgUEAgIAARIEswEJDQoNCgUEAgIA
AxIEswEQEQoPCgUEAgIACBIGswESuAEDChAKCAQCAgAInAgAEgS0AQQqChEKBwQCAgAInwgS
BrUBBLcBBQouCgIEAxIGvAEAxQEBGiAgUmVxdWVzdCBmb3IgR2V0Q29udHJvbCBtZXRob2Qu
CgoLCgMEAwESBLwBCBkKzwEKBAQDAgASBr8BAsQBBBq+ASBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIENvbnRyb2wgdG8gZ2V0LiBGb3JtYXQ6CiBgcHJvamVjdHMve3By
b2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jb2xsZWN0aW9ucy97Y29s
bGVjdGlvbl9pZH0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZV9pZH0vY29udHJvbHMve2NvbnRy
b2xfaWR9YAoKDQoFBAMCAAUSBL8BAggKDQoFBAMCAAESBL8BCQ0KDQoFBAMCAAMSBL8BEBEK
DwoFBAMCAAgSBr8BEsQBAwoQCggEAwIACJwIABIEwAEEKgoRCgcEAwIACJ8IEgbBAQTDAQUK
MAoCBAQSBsgBAOIBARoiIFJlcXVlc3QgZm9yIExpc3RDb250cm9scyBtZXRob2QuCgoLCgME
BAESBMgBCBsKmAIKBAQEAgASBs0BAtIBBBqHAiBSZXF1aXJlZC4gVGhlIGRhdGEgc3RvcmUg
cmVzb3VyY2UgbmFtZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9j
YXRpb25zL3tsb2NhdGlvbl9pZH0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9L2RhdGFT
dG9yZXMve2RhdGFfc3RvcmVfaWR9YAogb3IKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9
L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9l
bmdpbmVzL3tlbmdpbmVfaWR9YC4KCg0KBQQEAgAFEgTNAQIICg0KBQQEAgABEgTNAQkPCg0K
BQQEAgADEgTNARITCg8KBQQEAgAIEgbNARTSAQMKEAoIBAQCAAicCAASBM4BBCoKEQoHBAQC
AAifCBIGzwEE0QEFCnoKBAQEAgESBNYBAj8abCBPcHRpb25hbC4gTWF4aW11bSBudW1iZXIg
b2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8gNTAu
IE1heCBhbGxvd2VkIHZhbHVlIGlzIDEwMDAuCgoNCgUEBAIBBRIE1gECBwoNCgUEBAIBARIE
1gEIEQoNCgUEBAIBAxIE1gEUFQoNCgUEBAIBCBIE1gEWPgoQCggEBAIBCJwIABIE1gEXPQqE
AQoEBAQCAhIE2gECQRp2IE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20g
YSBwcmV2aW91cyBgTGlzdENvbnRyb2xzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJp
ZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoNCgUEBAICBRIE2gECCAoNCgUEBAICARIE2gEJ
EwoNCgUEBAICAxIE2gEWFwoNCgUEBAICCBIE2gEYQAoQCggEBAICCJwIABIE2gEZPwqFAgoE
BAQCAxIE4QECPRr2ASBPcHRpb25hbC4gQSBmaWx0ZXIgdG8gYXBwbHkgb24gdGhlIGxpc3Qg
cmVzdWx0cy4gU3VwcG9ydGVkIGZlYXR1cmVzOgoKICogTGlzdCBhbGwgdGhlIHByb2R1Y3Rz
IHVuZGVyIHRoZSBwYXJlbnQgYnJhbmNoIGlmCiBbZmlsdGVyXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdENvbnRyb2xzUmVxdWVzdC5maWx0ZXJdCiBpcyB1
bnNldC4gQ3VycmVudGx5IHRoaXMgZmllbGQgaXMgdW5zdXBwb3J0ZWQuCgoNCgUEBAIDBRIE
4QECCAoNCgUEBAIDARIE4QEJDwoNCgUEBAIDAxIE4QESEwoNCgUEBAIDCBIE4QEUPAoQCggE
BAIDCJwIABIE4QEVOwoxCgIEBRIG5QEA6wEBGiMgUmVzcG9uc2UgZm9yIExpc3RDb250cm9s
cyBtZXRob2QuCgoLCgMEBQESBOUBCBwKOAoEBAUCABIE5wECIBoqIEFsbCB0aGUgQ29udHJv
bHMgZm9yIGEgZ2l2ZW4gZGF0YSBzdG9yZS4KCg0KBQQFAgAEEgTnAQIKCg0KBQQFAgAGEgTn
AQsSCg0KBQQFAgABEgTnARMbCg0KBQQFAgADEgTnAR4fCkoKBAQFAgESBOoBAh0aPCBQYWdp
bmF0aW9uIHRva2VuLCBpZiBub3QgcmV0dXJuZWQgaW5kaWNhdGVzIHRoZSBsYXN0IHBhZ2Uu
CgoNCgUEBQIBBRIE6gECCAoNCgUEBQIBARIE6gEJGAoNCgUEBQIBAxIE6gEbHGIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest ===
    # Fields for CreateControlRequest
    # Field: parent Type: 9 ()
    # Field: control Type: 11 (.google.cloud.discoveryengine.v1alpha.Control)
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ControlService::UpdateControlRequest ===
    # Fields for UpdateControlRequest
    # Field: control Type: 11 (.google.cloud.discoveryengine.v1alpha.Control)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1alpha::ControlService::DeleteControlRequest ===
    # Fields for DeleteControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ControlService::GetControlRequest ===
    # Fields for GetControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ControlService::ListControlsRequest ===
    # Fields for ListControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::ControlService::ListControlsResponse ===
    # Fields for ListControlsResponse
    # Field: controls Type: 11 (.google.cloud.discoveryengine.v1alpha.Control)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::ControlService::ControlServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::ControlService::ControlServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::ControlService::ControlServiceClient

Client stub representing the remote C<ControlService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ControlService',
        method         => 'CreateControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Control::Control',
    });
}

sub delete_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ControlService::DeleteControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ControlService',
        method         => 'DeleteControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ControlService::UpdateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ControlService',
        method         => 'UpdateControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Control::Control',
    });
}

sub get_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ControlService::GetControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ControlService',
        method         => 'GetControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Control::Control',
    });
}

sub list_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ControlService::ListControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ControlService',
        method         => 'ListControls',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::ControlService::ListControlsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ControlService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/control_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::ControlService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest->new({
        parent => $parent,
        control => $control,
        control_id => $control_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/control_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest

Request for CreateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent data store. Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/dataStores/{data_store_id}`
or
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/engines/{engine_id}`.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control>)

Required. The Control to create.

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The ID to use for the Control, which will become the final
component of the Control's resource name.

This value must be within 1-63 characters.
Valid characters are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ControlService::UpdateControlRequest

Request for UpdateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control>)

Required. The Control to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[Control][google.cloud.discoveryengine.v1alpha.Control] to update. The
following are NOT supported:

* [Control.name][google.cloud.discoveryengine.v1alpha.Control.name]
* [Control.solution_type][google.cloud.discoveryengine.v1alpha.Control.solution_type]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ControlService::DeleteControlRequest

Request for DeleteControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to delete. Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/dataStores/{data_store_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ControlService::GetControlRequest

Request for GetControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to get. Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/dataStores/{data_store_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ControlService::ListControlsRequest

Request for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The data store resource name. Format:
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/dataStores/{data_store_id}`
or
`projects/{project_number}/locations/{location_id}/collections/{collection_id}/engines/{engine_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 50. Max allowed value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListControls` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter to apply on the list results. Supported features:

* List all the products under the parent branch if
[filter][google.cloud.discoveryengine.v1alpha.ListControlsRequest.filter]
is unset. Currently this field is unsupported.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::ControlService::ListControlsResponse

Response for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->controls() >> / C<< $msg->controls($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control>)

All the Controls for a given data store.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::ControlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
