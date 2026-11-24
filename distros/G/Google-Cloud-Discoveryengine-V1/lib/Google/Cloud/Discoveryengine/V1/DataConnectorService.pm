package Google::Cloud::Discoveryengine::V1::DataConnectorService;

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
    eval { require Google::Cloud::Discoveryengine::V1::DataConnector };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2RhdGFfY29ubmVjdG9yX3NlcnZp
Y2UucHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRnb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2RhdGFfY29ubmVjdG9yLnByb3RvGiNnb29n
bGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxk
X21hc2sucHJvdG8ipwIKGVNldFVwRGF0YUNvbm5lY3RvclJlcXVlc3QSRwoGcGFyZW50GAEg
ASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIG
cGFyZW50EigKDWNvbGxlY3Rpb25faWQYAiABKAlCA+BBAlIMY29sbGVjdGlvbklkEjsKF2Nv
bGxlY3Rpb25fZGlzcGxheV9uYW1lGAMgASgJQgPgQQJSFWNvbGxlY3Rpb25EaXNwbGF5TmFt
ZRJaCg5kYXRhX2Nvbm5lY3RvchgEIAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuRGF0YUNvbm5lY3RvckID4EECUg1kYXRhQ29ubmVjdG9yIhwKGlNldFVwRGF0YUNv
bm5lY3Rvck1ldGFkYXRhImMKF0dldERhdGFDb25uZWN0b3JSZXF1ZXN0EkgKBG5hbWUYASAB
KAlCNOBBAvpBLgosZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFDb25uZWN0
b3JSBG5hbWUitQEKGlVwZGF0ZURhdGFDb25uZWN0b3JSZXF1ZXN0EloKDmRhdGFfY29ubmVj
dG9yGAEgASgLMi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVj
dG9yQgPgQQJSDWRhdGFDb25uZWN0b3ISOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrMq4JChREYXRhQ29ubmVjdG9yU2Vydmlj
ZRKsAwoSU2V0VXBEYXRhQ29ubmVjdG9yEjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5TZXRVcERhdGFDb25uZWN0b3JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiK6AoLT5JMChwEiNi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
OnNldFVwRGF0YUNvbm5lY3RvcjoBKlpKIjgvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qfTpzZXRVcERhdGFDb25uZWN0b3JWMjoOZGF0YV9jb25uZWN0b3LaQTtwYXJlbnQs
Y29sbGVjdGlvbl9pZCxjb2xsZWN0aW9uX2Rpc3BsYXlfbmFtZSxkYXRhX2Nvbm5lY3RvcspB
awotZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yEjpnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNldFVwRGF0YUNvbm5lY3Rvck1ldGFkYXRh
EsoBChBHZXREYXRhQ29ubmVjdG9yEjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5HZXREYXRhQ29ubmVjdG9yUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuRGF0YUNvbm5lY3RvciJMgtPkkwI/Ej0vdjEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFDb25uZWN0b3J92kEEbmFtZRKGAgoTVXBkYXRl
RGF0YUNvbm5lY3RvchI7Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXBkYXRl
RGF0YUNvbm5lY3RvclJlcXVlc3QaLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LkRhdGFDb25uZWN0b3IigQGC0+STAl4yTC92MS97ZGF0YV9jb25uZWN0b3IubmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YUNvbm5lY3Rvcn06DmRhdGFf
Y29ubmVjdG9y2kEaZGF0YV9jb25uZWN0b3IsdXBkYXRlX21hc2sakALKQR5kaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb23SQesBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2Nv
dmVyeWVuZ2luZS5hc3Npc3QucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29t
L2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0ZUKMAgojY29tLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCGURhdGFDb25uZWN0b3JTZXJ2aWNlUHJv
dG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlzY292
ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9Hb29n
bGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2NvdmVyeUVu
Z2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFKkTIKBxIFDgDK
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA+CgkKAgMF
EgMXAC0KCQoCAwYSAxgAKgoICgEIEgMaADwKCQoCCCUSAxoAPAoICgEIEgMbAGQKCQoCCAsS
AxsAZAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADoKCQoCCAgSAx0AOgoICgEIEgMe
ADwKCQoCCAESAx4APAoICgEIEgMfAC0KCQoCCCQSAx8ALQoICgEIEgMgADwKCQoCCCkSAyAA
PAoICgEIEgMhADsKCQoCCC0SAyEAOwo0CgIGABIEJABYARooIFNlcnZpY2UgZm9yIGRhdGEg
Y29ubmVjdG9yIG1hbmFnZW1lbnQuCgoKCgMGAAESAyQIHAoKCgMGAAMSAyUCRgoMCgUGAAOZ
CBIDJQJGCgsKAwYAAxIEJgIqSgoNCgUGAAOaCBIEJgIqSgr/AgoEBgACABIEMwJDAxrwAiBD
cmVhdGVzIGEgW0NvbGxlY3Rpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
Q29sbGVjdGlvbl0gYW5kIHNldHMKIHVwIHRoZSBbRGF0YUNvbm5lY3Rvcl1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yXSBmb3IKIGl0LiBUbyBzdG9w
IGEKIFtEYXRhQ29ubmVjdG9yXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRh
dGFDb25uZWN0b3JdIGFmdGVyIHNldHVwLAogdXNlIHRoZQogW0NvbGxlY3Rpb25TZXJ2aWNl
LkRlbGV0ZUNvbGxlY3Rpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29s
bGVjdGlvblNlcnZpY2UuRGVsZXRlQ29sbGVjdGlvbl0KIG1ldGhvZC4KCgwKBQYAAgABEgMz
BhgKDAoFBgACAAISAzMZMgoMCgUGAAIAAxIDNA8rCg0KBQYAAgAEEgQ1BDwGChEKCQYAAgAE
sMq8IhIENQQ8BgoNCgUGAAIABBIEPQQ+RgoQCggGAAIABJsIABIEPQQ+RgoNCgUGAAIABBIE
PwRCBgoPCgcGAAIABJkIEgQ/BEIGCvYBCgQGAAIBEgRJAk4DGucBIEdldHMgdGhlIFtEYXRh
Q29ubmVjdG9yXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFDb25uZWN0
b3JdLgogW0RhdGFDb25uZWN0b3JdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RGF0YUNvbm5lY3Rvcl0gaXMgYQogc2luZ2xldG9uIHJlc291cmNlIGZvciBlYWNoCiBbQ29s
bGVjdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db2xsZWN0aW9uXS4K
CgwKBQYAAgEBEgNJBhYKDAoFBgACAQISA0kXLgoMCgUGAAIBAxIDSTlGCg0KBQYAAgEEEgRK
BEwGChEKCQYAAgEEsMq8IhIESgRMBgoMCgUGAAIBBBIDTQQyCg8KCAYAAgEEmwgAEgNNBDIK
WQoEBgACAhIEUQJXAxpLIFVwZGF0ZXMgYSBbRGF0YUNvbm5lY3Rvcl1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yXS4KCgwKBQYAAgIBEgNRBhkKDAoF
BgACAgISA1EaNAoMCgUGAAICAxIDUT9MCg0KBQYAAgIEEgRSBFUGChEKCQYAAgIEsMq8IhIE
UgRVBgoMCgUGAAICBBIDVgRICg8KCAYAAgIEmwgAEgNWBEgKmAEKAgQAEgVdAIUBARqKASBS
ZXF1ZXN0IGZvcgogW0RhdGFDb25uZWN0b3JTZXJ2aWNlLlNldFVwRGF0YUNvbm5lY3Rvcl1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yU2VydmljZS5T
ZXRVcERhdGFDb25uZWN0b3JdCiBtZXRob2QuCgoKCgMEAAESA10IIQqgAQoEBAACABIEYQJm
BBqRASBSZXF1aXJlZC4gVGhlIHBhcmVudCBvZgogW0NvbGxlY3Rpb25dW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29sbGVjdGlvbl0sIGluIHRoZSBmb3JtYXQgb2YKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDAoFBAACAAUSA2EC
CAoMCgUEAAIAARIDYQkPCgwKBQQAAgADEgNhEhMKDQoFBAACAAgSBGEUZgMKDwoIBAACAAic
CAASA2IEKgoPCgcEAAIACJ8IEgRjBGUFCs8GCgQEAAIBEgN3AkQawQYgUmVxdWlyZWQuIFRo
ZSBJRCB0byB1c2UgZm9yIHRoZQogW0NvbGxlY3Rpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuQ29sbGVjdGlvbl0sIHdoaWNoIHdpbGwgYmVjb21lCiB0aGUgZmluYWwg
Y29tcG9uZW50IG9mIHRoZQogW0NvbGxlY3Rpb25dW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuQ29sbGVjdGlvbl0ncyByZXNvdXJjZSBuYW1lLiBBCiBuZXcgW0NvbGxlY3Rp
b25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29sbGVjdGlvbl0gaXMgY3Jl
YXRlZCBhcwogcGFydCBvZiB0aGUgW0RhdGFDb25uZWN0b3JdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuRGF0YUNvbm5lY3Rvcl0KIHNldHVwLiBbRGF0YUNvbm5lY3Rvcl1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yXSBpcyBhCiBz
aW5nbGV0b24gcmVzb3VyY2UgdW5kZXIKIFtDb2xsZWN0aW9uXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkNvbGxlY3Rpb25dLCBtYW5hZ2luZyBhbGwKIFtEYXRhU3RvcmVd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlXXMgb2YgdGhlCiBb
Q29sbGVjdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db2xsZWN0aW9u
XS4KCiBTaG91bGQgY29uZm9ybSB0bwogW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYu
b3JnL2h0bWwvcmZjMTAzNCkgc3RhbmRhcmQgd2l0aCBhIGxlbmd0aAogbGltaXQgb2YgNjMg
Y2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMg
cmV0dXJuZWQuCgoMCgUEAAIBBRIDdwIICgwKBQQAAgEBEgN3CRYKDAoFBAACAQMSA3cZGgoM
CgUEAAIBCBIDdxtDCg8KCAQAAgEInAgAEgN3HEIK8wEKBAQAAgISA34CThrlASBSZXF1aXJl
ZC4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUKIFtDb2xsZWN0aW9uXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkNvbGxlY3Rpb25dLgoKIFNob3VsZCBiZSBodW1hbiByZWFk
YWJsZSwgdXNlZCB0byBkaXNwbGF5IGNvbGxlY3Rpb25zIGluIHRoZSBDb25zb2xlCiBEYXNo
Ym9hcmQuIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggbGltaXQgb2YgMTAyNCBjaGFyYWN0
ZXJzLgoKDAoFBAACAgUSA34CCAoMCgUEAAICARIDfgkgCgwKBQQAAgIDEgN+IyQKDAoFBAAC
AggSA34lTQoPCggEAAICCJwIABIDfiZMCr0BCgQEAAIDEgSEAQJMGq4BIFJlcXVpcmVkLiBU
aGUKIFtEYXRhQ29ubmVjdG9yXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRh
dGFDb25uZWN0b3JdIHRvCiBpbml0aWFsaXplIGluIHRoZSBuZXdseSBjcmVhdGVkCiBbQ29s
bGVjdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db2xsZWN0aW9uXS4K
Cg0KBQQAAgMGEgSEAQIPCg0KBQQAAgMBEgSEARAeCg0KBQQAAgMDEgSEASEiCg0KBQQAAgMI
EgSEASNLChAKCAQAAgMInAgAEgSEASRKCpgBCgIEARIEigEAJRqLASBNZXRhZGF0YSBmb3IK
IFtEYXRhQ29ubmVjdG9yU2VydmljZS5TZXRVcERhdGFDb25uZWN0b3JdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YUNvbm5lY3RvclNlcnZpY2UuU2V0VXBEYXRhQ29u
bmVjdG9yXQogbWV0aG9kLgoKCwoDBAEBEgSKAQgiCpUBCgIEAhIGjwEAoQEBGoYBIFJlcXVl
c3QgZm9yCiBbRGF0YUNvbm5lY3RvclNlcnZpY2UuR2V0RGF0YUNvbm5lY3Rvcl1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yU2VydmljZS5HZXREYXRh
Q29ubmVjdG9yXQogbWV0aG9kLgoKCwoDBAIBEgSPAQgfCqAECgQEAgIAEgabAQKgAQQajwQg
UmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0RhdGFDb25uZWN0b3JdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YUNvbm5lY3Rvcl0sIHN1Y2ggYXMKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2Nv
bGxlY3Rpb25faWR9L2RhdGFDb25uZWN0b3JgLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3Qg
aGF2ZSBwZXJtaXNzaW9uIHRvIGFjY2VzcyB0aGUKIFtEYXRhQ29ubmVjdG9yXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFDb25uZWN0b3JdLCByZWdhcmRsZXNzCiBv
ZiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYCBlcnJv
ciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgcmVxdWVzdGVkCiBbRGF0YUNvbm5lY3Rvcl1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yXSBkb2VzIG5vdAog
ZXhpc3QsIGEgYE5PVF9GT1VORGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAgIABRIEmwEC
CAoNCgUEAgIAARIEmwEJDQoNCgUEAgIAAxIEmwEQEQoPCgUEAgIACBIGmwESoAEDChAKCAQC
AgAInAgAEgScAQQqChEKBwQCAgAInwgSBp0BBJ8BBQqjAQoCBAMSBqYBAMoBARqUASBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YUNvbm5lY3RvclNlcnZpY2UuVXBkYXRlRGF0YUNvbm5l
Y3Rvcl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yU2Vy
dmljZS5VcGRhdGVEYXRhQ29ubmVjdG9yXQogbWV0aG9kLgoKCwoDBAMBEgSmAQgiCq0DCgQE
AwIAEgSwAQJMGp4DIFJlcXVpcmVkLiBUaGUKIFtEYXRhQ29ubmVjdG9yXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFDb25uZWN0b3JdIHRvIHVwZGF0ZS4KCiBJZiB0
aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBbRGF0
YUNvbm5lY3Rvcl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVj
dG9yXSwgcmVnYXJkbGVzcwogb2Ygd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBhIGBQRVJN
SVNTSU9OX0RFTklFRGAgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIFtEYXRhQ29ubmVj
dG9yXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFDb25uZWN0b3JdIGRv
ZXMKIG5vdCBleGlzdCwgYSBgTk9UX0ZPVU5EYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQD
AgAGEgSwAQIPCg0KBQQDAgABEgSwARAeCg0KBQQDAgADEgSwASEiCg0KBQQDAgAIEgSwASNL
ChAKCAQDAgAInAgAEgSwASRKCtgFCgQEAwIBEgTJAQIsGskFIEluZGljYXRlcyB3aGljaCBm
aWVsZHMgaW4gdGhlIHByb3ZpZGVkCiBbRGF0YUNvbm5lY3Rvcl1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5EYXRhQ29ubmVjdG9yXSB0byB1cGRhdGUuCgogU3VwcG9ydGVk
IGZpZWxkIHBhdGhzIGluY2x1ZGU6CgogIC0gYHJlZnJlc2hfaW50ZXJ2YWxgCiAgLSBgcGFy
YW1zYAogIC0gYGF1dG9fcnVuX2Rpc2FibGVkYAogIC0gYGFjdGlvbl9jb25maWdgCiAgLSBg
YWN0aW9uX2NvbmZpZy5hY3Rpb25fcGFyYW1zYAogIC0gYGFjdGlvbl9jb25maWcuc2Vydmlj
ZV9uYW1lYAogIC0gYGRlc3RpbmF0aW9uX2NvbmZpZ3NgCiAgLSBgYmxvY2tpbmdfcmVhc29u
c2AKICAtIGBzeW5jX21vZGVgCiAgLSBgaW5jcmVtZW50YWxfc3luY19kaXNhYmxlZGAKICAt
IGBpbmNyZW1lbnRhbF9yZWZyZXNoX2ludGVydmFsYAogIC0gYGRhdGFfcHJvdGVjdGlvbl9w
b2xpY3lgCgogTm90ZTogIFN1cHBvcnQgZm9yIHRoZXNlIGZpZWxkcyBtYXkgdmFyeSBkZXBl
bmRpbmcgb24gdGhlIGNvbm5lY3RvciB0eXBlLgogICAgICAgIEZvciBleGFtcGxlLCBub3Qg
YWxsIGNvbm5lY3RvcnMgc3VwcG9ydCBgZGVzdGluYXRpb25fY29uZmlnc2AuCgogSWYgYW4g
dW5zdXBwb3J0ZWQgb3IgdW5rbm93biBmaWVsZCBwYXRoIGlzIHByb3ZpZGVkLCB0aGUgcmVx
dWVzdCB3aWxsCiByZXR1cm4gYW4gYElOVkFMSURfQVJHVU1FTlRgIGVycm9yLgoKDQoFBAMC
AQYSBMkBAhsKDQoFBAMCAQESBMkBHCcKDQoFBAMCAQMSBMkBKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest ===
    # Fields for SetUpDataConnectorRequest
    # Field: parent Type: 9 ()
    # Field: collection_id Type: 9 ()
    # Field: collection_display_name Type: 9 ()
    # Field: data_connector Type: 11 (.google.cloud.discoveryengine.v1.DataConnector)

# === Message: Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorMetadata ===
    # Fields for SetUpDataConnectorMetadata

# === Message: Google::Cloud::Discoveryengine::V1::DataConnectorService::GetDataConnectorRequest ===
    # Fields for GetDataConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest ===
    # Fields for UpdateDataConnectorRequest
    # Field: data_connector Type: 11 (.google.cloud.discoveryengine.v1.DataConnector)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Discoveryengine::V1::DataConnectorService::DataConnectorServiceClient ===
package Google::Cloud::Discoveryengine::V1::DataConnectorService::DataConnectorServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::DataConnectorService::DataConnectorServiceClient

Client stub representing the remote C<DataConnectorService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub set_up_data_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataConnectorService',
        method         => 'SetUpDataConnector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_data_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataConnectorService::GetDataConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataConnectorService',
        method         => 'GetDataConnector',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector',
    });
}

sub update_data_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataConnectorService',
        method         => 'UpdateDataConnector',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::DataConnectorService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/data_connector_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::DataConnectorService;

    my $msg = Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest->new({
        parent => $parent,
        collection_id => $collection_id,
        collection_display_name => $collection_display_name,
        data_connector => $data_connector,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/data_connector_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest

Request for
[DataConnectorService.SetUpDataConnector][google.cloud.discoveryengine.v1.DataConnectorService.SetUpDataConnector]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of
[Collection][google.cloud.discoveryengine.v1.Collection], in the format of
`projects/{project}/locations/{location}`.

=item * C<< $msg->collection_id() >> / C<< $msg->collection_id($value) >>

Type: C<String>

Required. The ID to use for the
[Collection][google.cloud.discoveryengine.v1.Collection], which will become
the final component of the
[Collection][google.cloud.discoveryengine.v1.Collection]'s resource name. A
new [Collection][google.cloud.discoveryengine.v1.Collection] is created as
part of the [DataConnector][google.cloud.discoveryengine.v1.DataConnector]
setup. [DataConnector][google.cloud.discoveryengine.v1.DataConnector] is a
singleton resource under
[Collection][google.cloud.discoveryengine.v1.Collection], managing all
[DataStore][google.cloud.discoveryengine.v1.DataStore]s of the
[Collection][google.cloud.discoveryengine.v1.Collection].

Should conform to
[RFC-1034](https://tools.ietf.org/html/rfc1034) standard with a length
limit of 63 characters. Otherwise, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->collection_display_name() >> / C<< $msg->collection_display_name($value) >>

Type: C<String>

Required. The display name of the
[Collection][google.cloud.discoveryengine.v1.Collection].

Should be human readable, used to display collections in the Console
Dashboard. UTF-8 encoded string with limit of 1024 characters.

=item * C<< $msg->data_connector() >> / C<< $msg->data_connector($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector>)

Required. The
[DataConnector][google.cloud.discoveryengine.v1.DataConnector] to
initialize in the newly created
[Collection][google.cloud.discoveryengine.v1.Collection].

=back

=head2 Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorMetadata

Metadata for
[DataConnectorService.SetUpDataConnector][google.cloud.discoveryengine.v1.DataConnectorService.SetUpDataConnector]
method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Discoveryengine::V1::DataConnectorService::GetDataConnectorRequest

Request for
[DataConnectorService.GetDataConnector][google.cloud.discoveryengine.v1.DataConnectorService.GetDataConnector]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataConnector][google.cloud.discoveryengine.v1.DataConnector], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataConnector`.

If the caller does not have permission to access the
[DataConnector][google.cloud.discoveryengine.v1.DataConnector], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the requested
[DataConnector][google.cloud.discoveryengine.v1.DataConnector] does not
exist, a `NOT_FOUND` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest

Request message for
[DataConnectorService.UpdateDataConnector][google.cloud.discoveryengine.v1.DataConnectorService.UpdateDataConnector]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_connector() >> / C<< $msg->data_connector($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector>)

Required. The
[DataConnector][google.cloud.discoveryengine.v1.DataConnector] to update.

If the caller does not have permission to update the
[DataConnector][google.cloud.discoveryengine.v1.DataConnector], regardless
of whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [DataConnector][google.cloud.discoveryengine.v1.DataConnector] does
not exist, a `NOT_FOUND` error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[DataConnector][google.cloud.discoveryengine.v1.DataConnector] to update.

Supported field paths include:

 - `refresh_interval`
 - `params`
 - `auto_run_disabled`
 - `action_config`
 - `action_config.action_params`
 - `action_config.service_name`
 - `destination_configs`
 - `blocking_reasons`
 - `sync_mode`
 - `incremental_sync_disabled`
 - `incremental_refresh_interval`
 - `data_protection_policy`

Note:  Support for these fields may vary depending on the connector type.
       For example, not all connectors support `destination_configs`.

If an unsupported or unknown field path is provided, the request will
return an `INVALID_ARGUMENT` error.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::DataConnectorService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
