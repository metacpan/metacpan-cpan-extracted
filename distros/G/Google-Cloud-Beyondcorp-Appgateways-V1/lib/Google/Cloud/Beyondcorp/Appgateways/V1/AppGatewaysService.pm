package Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService;

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
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvYmV5b25kY29ycC9hcHBnYXRld2F5cy92MS9hcHBfZ2F0ZXdheXNf
c2VydmljZS5wcm90bxImZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwZ2F0ZXdheXMudjEa
HGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3Rv
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3By
b3RvYnVmL2VtcHR5LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIuEB
ChZMaXN0QXBwR2F0ZXdheXNSZXF1ZXN0EkQKBnBhcmVudBgBIAEoCUIs4EEC+kEmEiRiZXlv
bmRjb3JwLmdvb2dsZWFwaXMuY29tL0FwcEdhdGV3YXlSBnBhcmVudBIgCglwYWdlX3NpemUY
AiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9r
ZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEB
UgdvcmRlckJ5IroBChdMaXN0QXBwR2F0ZXdheXNSZXNwb25zZRJVCgxhcHBfZ2F0ZXdheXMY
ASADKAsyMi5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5hcHBnYXRld2F5cy52MS5BcHBHYXRl
d2F5UgthcHBHYXRld2F5cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIlgKFEdldEFwcEdhdGV3YXlS
ZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpBJgokYmV5b25kY29ycC5nb29nbGVhcGlzLmNv
bS9BcHBHYXRld2F5UgRuYW1lIrICChdDcmVhdGVBcHBHYXRld2F5UmVxdWVzdBJECgZwYXJl
bnQYASABKAlCLOBBAvpBJhIkYmV5b25kY29ycC5nb29nbGVhcGlzLmNvbS9BcHBHYXRld2F5
UgZwYXJlbnQSKQoOYXBwX2dhdGV3YXlfaWQYAiABKAlCA+BBAVIMYXBwR2F0ZXdheUlkElgK
C2FwcF9nYXRld2F5GAMgASgLMjIuZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwZ2F0ZXdh
eXMudjEuQXBwR2F0ZXdheUID4EECUgphcHBHYXRld2F5EiIKCnJlcXVlc3RfaWQYBCABKAlC
A+BBAVIJcmVxdWVzdElkEigKDXZhbGlkYXRlX29ubHkYBSABKAhCA+BBAVIMdmFsaWRhdGVP
bmx5IqkBChdEZWxldGVBcHBHYXRld2F5UmVxdWVzdBJACgRuYW1lGAEgASgJQizgQQL6QSYK
JGJleW9uZGNvcnAuZ29vZ2xlYXBpcy5jb20vQXBwR2F0ZXdheVIEbmFtZRIiCgpyZXF1ZXN0
X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZBIoCg12YWxpZGF0ZV9vbmx5GAMgASgIQgPgQQFS
DHZhbGlkYXRlT25seSK4CgoKQXBwR2F0ZXdheRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUS
QAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSWwoGbGFiZWxzGAQgAygLMj4uZ29vZ2xlLmNsb3Vk
LmJleW9uZGNvcnAuYXBwZ2F0ZXdheXMudjEuQXBwR2F0ZXdheS5MYWJlbHNFbnRyeUID4EEB
UgZsYWJlbHMSJgoMZGlzcGxheV9uYW1lGAUgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEhUKA3Vp
ZBgGIAEoCUID4EEDUgN1aWQSUAoEdHlwZRgHIAEoDjI3Lmdvb2dsZS5jbG91ZC5iZXlvbmRj
b3JwLmFwcGdhdGV3YXlzLnYxLkFwcEdhdGV3YXkuVHlwZUID4EECUgR0eXBlElMKBXN0YXRl
GAggASgOMjguZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwZ2F0ZXdheXMudjEuQXBwR2F0
ZXdheS5TdGF0ZUID4EEDUgVzdGF0ZRIVCgN1cmkYCSABKAlCA+BBA1IDdXJpEoABChVhbGxv
Y2F0ZWRfY29ubmVjdGlvbnMYCiADKAsyRi5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5hcHBn
YXRld2F5cy52MS5BcHBHYXRld2F5LkFsbG9jYXRlZENvbm5lY3Rpb25CA+BBA1IUYWxsb2Nh
dGVkQ29ubmVjdGlvbnMSXQoJaG9zdF90eXBlGAsgASgOMjsuZ29vZ2xlLmNsb3VkLmJleW9u
ZGNvcnAuYXBwZ2F0ZXdheXMudjEuQXBwR2F0ZXdheS5Ib3N0VHlwZUID4EECUghob3N0VHlw
ZRItCg1zYXRpc2ZpZXNfcHpzGAwgASgIQgPgQQNIAFIMc2F0aXNmaWVzUHpziAEBEi0KDXNh
dGlzZmllc19wemkYDSABKAhCA+BBA0gBUgxzYXRpc2ZpZXNQemmIAQEaWwoTQWxsb2NhdGVk
Q29ubmVjdGlvbhIcCgdwc2NfdXJpGAEgASgJQgPgQQJSBnBzY1VyaRImCgxpbmdyZXNzX3Bv
cnQYAiABKAVCA+BBAlILaW5ncmVzc1BvcnQaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASIrCgRUeXBlEhQKEFRZUEVfVU5TUEVD
SUZJRUQQABINCglUQ1BfUFJPWFkQASJfCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EgwKCENSRUFUSU5HEAESCwoHQ1JFQVRFRBACEgwKCFVQREFUSU5HEAMSDAoIREVMRVRJTkcQ
BBIICgRET1dOEAUiOwoISG9zdFR5cGUSGQoVSE9TVF9UWVBFX1VOU1BFQ0lGSUVEEAASFAoQ
R0NQX1JFR0lPTkFMX01JRxABOmzqQWkKJGJleW9uZGNvcnAuZ29vZ2xlYXBpcy5jb20vQXBw
R2F0ZXdheRJBcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcEdh
dGV3YXlzL3thcHBfZ2F0ZXdheX1CEAoOX3NhdGlzZmllc19wenNCEAoOX3NhdGlzZmllc19w
emki3wIKG0FwcEdhdGV3YXlPcGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVfdGltZRgBIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6CghlbmRf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGltZRIb
CgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZlcmIYBCABKAlCA+BBA1IEdmVyYhIq
Cg5zdGF0dXNfbWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0dXNNZXNzYWdlEjoKFnJlcXVlc3Rl
ZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uEiQKC2Fw
aV92ZXJzaW9uGAcgASgJQgPgQQNSCmFwaVZlcnNpb24yhQgKEkFwcEdhdGV3YXlzU2Vydmlj
ZRLXAQoPTGlzdEFwcEdhdGV3YXlzEj4uZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwZ2F0
ZXdheXMudjEuTGlzdEFwcEdhdGV3YXlzUmVxdWVzdBo/Lmdvb2dsZS5jbG91ZC5iZXlvbmRj
b3JwLmFwcGdhdGV3YXlzLnYxLkxpc3RBcHBHYXRld2F5c1Jlc3BvbnNlIkOIAgGC0+STAjES
Ly92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2FwcEdhdGV3YXlz2kEGcGFy
ZW50EsQBCg1HZXRBcHBHYXRld2F5EjwuZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwZ2F0
ZXdheXMudjEuR2V0QXBwR2F0ZXdheVJlcXVlc3QaMi5nb29nbGUuY2xvdWQuYmV5b25kY29y
cC5hcHBnYXRld2F5cy52MS5BcHBHYXRld2F5IkGIAgGC0+STAjESLy92MS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2FwcEdhdGV3YXlzLyp92kEEbmFtZRKMAgoQQ3JlYXRlQXBw
R2F0ZXdheRI/Lmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmFwcGdhdGV3YXlzLnYxLkNyZWF0
ZUFwcEdhdGV3YXlSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKXAYgC
AYLT5JMCPiIvL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vYXBwR2F0ZXdh
eXM6C2FwcF9nYXRld2F52kEhcGFyZW50LGFwcF9nYXRld2F5LGFwcF9nYXRld2F5X2lkykEp
CgpBcHBHYXRld2F5EhtBcHBHYXRld2F5T3BlcmF0aW9uTWV0YWRhdGES7AEKEERlbGV0ZUFw
cEdhdGV3YXkSPy5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5hcHBnYXRld2F5cy52MS5EZWxl
dGVBcHBHYXRld2F5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ieIgC
AYLT5JMCMSovL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYXBwR2F0ZXdheXMv
Kn3aQQRuYW1lykE0ChVnb29nbGUucHJvdG9idWYuRW1wdHkSG0FwcEdhdGV3YXlPcGVyYXRp
b25NZXRhZGF0YRpQiAIBykEZYmV5b25kY29ycC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1ClAIKKmNvbS5nb29nbGUu
Y2xvdWQuYmV5b25kY29ycC5hcHBnYXRld2F5cy52MUIXQXBwR2F0ZXdheXNTZXJ2aWNlUHJv
dG9QAVpMY2xvdWQuZ29vZ2xlLmNvbS9nby9iZXlvbmRjb3JwL2FwcGdhdGV3YXlzL2FwaXYx
L2FwcGdhdGV3YXlzcGI7YXBwZ2F0ZXdheXNwYqoCJkdvb2dsZS5DbG91ZC5CZXlvbmRDb3Jw
LkFwcEdhdGV3YXlzLlYxygImR29vZ2xlXENsb3VkXEJleW9uZENvcnBcQXBwR2F0ZXdheXNc
VjHqAipHb29nbGU6OkNsb3VkOjpCZXlvbmRDb3JwOjpBcHBHYXRld2F5czo6VjFKl2gKBxIF
DgD0AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC8KCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAtCgkK
AgMFEgMXACUKCQoCAwYSAxgAKQoICgEIEgMaAEMKCQoCCCUSAxoAQwoICgEIEgMbAGMKCQoC
CAsSAxsAYwoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADgKCQoCCAgSAx0AOAoICgEI
EgMeAEMKCQoCCAESAx4AQwoICgEIEgMfAEQKCQoCCCkSAx8ARAoICgEIEgMgAEMKCQoCCC0S
AyAAQwquBAoCBgASBDQAaQEaoQQgQVBJIE92ZXJ2aWV3OgoKIFRoZSBgYmV5b25kY29ycC5n
b29nbGVhcGlzLmNvbWAgc2VydmljZSBpbXBsZW1lbnRzIHRoZSBHb29nbGUgQ2xvdWQKIEJl
eW9uZENvcnAgQVBJLgoKIERhdGEgTW9kZWw6CgogVGhlIEFwcEdhdGV3YXlzU2VydmljZSBl
eHBvc2VzIHRoZSBmb2xsb3dpbmcgcmVzb3VyY2VzOgoKICogQXBwR2F0ZXdheXMsIG5hbWVk
IGFzIGZvbGxvd3M6CiAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbl9pZH0vYXBwR2F0ZXdheXMve2FwcF9nYXRld2F5X2lkfWAuCgogVGhlIEFwcEdhdGV3
YXlzU2VydmljZSBzZXJ2aWNlIHByb3ZpZGVzIG1ldGhvZHMgdG8gbWFuYWdlCiAoY3JlYXRl
L3JlYWQvdXBkYXRlL2RlbGV0ZSkgQmV5b25kQ29ycCBBcHBHYXRld2F5cy4KCgogRGVwcmVj
YXRlZDogQXBwIENvbm5lY3RvciBpcyBkZXByZWNhdGVkIGFuZCBjcmVhdGlvbiBvZiBuZXcg
QXBwIENvbm5lY3RvcgogcmVzb3VyY2VzIGlzIG5vIGxvbmdlciBwZXJtaXR0ZWQuIFVzZSBT
ZWN1cml0eSBHYXRld2F5IGluc3RlYWQuCgoKCgMGAAESAzQIGgoKCgMGAAMSAzUCGwoLCgQG
AAMhEgM1AhsKCgoDBgADEgM2AkEKDAoFBgADmQgSAzYCQQoLCgMGAAMSBDcCODcKDQoFBgAD
mggSBDcCODcKQgoEBgACABIEOwJCAxo0IExpc3RzIEFwcEdhdGV3YXlzIGluIGEgZ2l2ZW4g
cHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIAARIDOwYVCgwKBQYAAgACEgM7FiwKDAoF
BgACAAMSAzwPJgoMCgUGAAIABBIDPQQdCg0KBgYAAgAEIRIDPQQdCg0KBQYAAgAEEgQ+BEAG
ChEKCQYAAgAEsMq8IhIEPgRABgoMCgUGAAIABBIDQQQ0Cg8KCAYAAgAEmwgAEgNBBDQKNAoE
BgACARIERQJLAxomIEdldHMgZGV0YWlscyBvZiBhIHNpbmdsZSBBcHBHYXRld2F5LgoKDAoF
BgACAQESA0UGEwoMCgUGAAIBAhIDRRQoCgwKBQYAAgEDEgNFMz0KDAoFBgACAQQSA0YEHQoN
CgYGAAIBBCESA0YEHQoNCgUGAAIBBBIERwRJBgoRCgkGAAIBBLDKvCISBEcESQYKDAoFBgAC
AQQSA0oEMgoPCggGAAIBBJsIABIDSgQyCkkKBAYAAgISBE4CWgMaOyBDcmVhdGVzIGEgbmV3
IEFwcEdhdGV3YXkgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgIB
EgNOBhYKDAoFBgACAgISA04XLgoMCgUGAAICAxIDTw8rCgwKBQYAAgIEEgNQBB0KDQoGBgAC
AgQhEgNQBB0KDQoFBgACAgQSBFEEVAYKEQoJBgACAgSwyrwiEgRRBFQGCgwKBQYAAgIEEgNV
BE8KDwoIBgACAgSbCAASA1UETwoNCgUGAAICBBIEVgRZBgoPCgcGAAICBJkIEgRWBFkGCiwK
BAYAAgMSBF0CaAMaHiBEZWxldGVzIGEgc2luZ2xlIEFwcEdhdGV3YXkuCgoMCgUGAAIDARID
XQYWCgwKBQYAAgMCEgNdFy4KDAoFBgACAwMSA14PKwoMCgUGAAIDBBIDXwQdCg0KBgYAAgME
IRIDXwQdCg0KBQYAAgMEEgRgBGIGChEKCQYAAgMEsMq8IhIEYARiBgoMCgUGAAIDBBIDYwQy
Cg8KCAYAAgMEmwgAEgNjBDIKDQoFBgACAwQSBGQEZwYKDwoHBgACAwSZCBIEZARnBgo+CgIE
ABIFbACKAQEaMSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEJleW9uZENvcnAuTGlzdEFwcEdhdGV3
YXlzLgoKCgoDBAABEgNsCB4KhwEKBAQAAgASBG8CdAQaeSBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIEFwcEdhdGV3YXkgbG9jYXRpb24gdXNpbmcgdGhlIGZvcm06CiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9YAoKDAoFBAAC
AAUSA28CCAoMCgUEAAIAARIDbwkPCgwKBQQAAgADEgNvEhMKDQoFBAACAAgSBG8UdAMKDwoI
BAACAAicCAASA3AEKgoPCgcEAAIACJ8IEgRxBHMFCqADCgQEAAIBEgN8Aj8akgMgT3B0aW9u
YWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4uCiBJZiBub3Qgc3Bl
Y2lmaWVkLCBhIGRlZmF1bHQgdmFsdWUgb2YgNTAgd2lsbCBiZSB1c2VkIGJ5IHRoZSBzZXJ2
aWNlLgogUmVnYXJkbGVzcyBvZiB0aGUgcGFnZV9zaXplIHZhbHVlLCB0aGUgcmVzcG9uc2Ug
bWF5IGluY2x1ZGUgYSBwYXJ0aWFsIGxpc3QKIGFuZCBhIGNhbGxlciBzaG91bGQgb25seSBy
ZWx5IG9uIHJlc3BvbnNlJ3MKIFtuZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5iZXlv
bmRjb3JwLmFwcGdhdGV3YXlzLnYxLkxpc3RBcHBHYXRld2F5c1Jlc3BvbnNlLm5leHRfcGFn
ZV90b2tlbl0KIHRvIGRldGVybWluZSBpZiB0aGVyZSBhcmUgbW9yZSBpbnN0YW5jZXMgbGVm
dCB0byBiZSBxdWVyaWVkLgoKDAoFBAACAQUSA3wCBwoMCgUEAAIBARIDfAgRCgwKBQQAAgED
EgN8FBUKDAoFBAACAQgSA3wWPgoPCggEAAIBCJwIABIDfBc9Cm0KBAQAAgISBIABAkEaXyBP
cHRpb25hbC4gVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJl
dmlvdXMKIExpc3RBcHBHYXRld2F5c1JlcXVlc3QsIGlmIGFueS4KCg0KBQQAAgIFEgSAAQII
Cg0KBQQAAgIBEgSAAQkTCg0KBQQAAgIDEgSAARYXCg0KBQQAAgIIEgSAARhAChAKCAQAAgII
nAgAEgSAARk/Ck4KBAQAAgMSBIMBAj0aQCBPcHRpb25hbC4gQSBmaWx0ZXIgc3BlY2lmeWlu
ZyBjb25zdHJhaW50cyBvZiBhIGxpc3Qgb3BlcmF0aW9uLgoKDQoFBAACAwUSBIMBAggKDQoF
BAACAwESBIMBCQ8KDQoFBAACAwMSBIMBEhMKDQoFBAACAwgSBIMBFDwKEAoIBAACAwicCAAS
BIMBFTsKrgEKBAQAAgQSBIkBAj8anwEgT3B0aW9uYWwuIFNwZWNpZmllcyB0aGUgb3JkZXJp
bmcgb2YgcmVzdWx0cy4gU2VlCiBbU29ydGluZwogb3JkZXJdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9hcGlzL2Rlc2lnbi9kZXNpZ25fcGF0dGVybnMjc29ydGluZ19vcmRlcikKIGZv
ciBtb3JlIGluZm9ybWF0aW9uLgoKDQoFBAACBAUSBIkBAggKDQoFBAACBAESBIkBCREKDQoF
BAACBAMSBIkBFBUKDQoFBAACBAgSBIkBFj4KEAoIBAACBAicCAASBIkBFz0KQAoCBAESBo0B
AJcBARoyIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIEJleW9uZENvcnAuTGlzdEFwcEdhdGV3YXlz
LgoKCwoDBAEBEgSNAQgfCkAKBAQBAgASBI8BAicaMiBBIGxpc3Qgb2YgQmV5b25kQ29ycCBB
cHBHYXRld2F5cyBpbiB0aGUgcHJvamVjdC4KCg0KBQQBAgAEEgSPAQIKCg0KBQQBAgAGEgSP
AQsVCg0KBQQBAgABEgSPARYiCg0KBQQBAgADEgSPASUmCnEKBAQBAgESBJMBAh0aYyBBIHRv
a2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYg
dGhlcmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAQIBBRIEkwEC
CAoNCgUEAQIBARIEkwEJGAoNCgUEAQIBAxIEkwEbHAo+CgQEAQICEgSWAQIiGjAgQSBsaXN0
IG9mIGxvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoFBAECAgQSBJYB
AgoKDQoFBAECAgUSBJYBCxEKDQoFBAECAgESBJYBEh0KDQoFBAECAgMSBJYBICEKPQoCBAIS
BpoBAKMBARovIFJlcXVlc3QgbWVzc2FnZSBmb3IgQmV5b25kQ29ycC5HZXRBcHBHYXRld2F5
LgoKCwoDBAIBEgSaAQgcCpUBCgQEAgIAEgadAQKiAQQahAEgUmVxdWlyZWQuIEJleW9uZENv
cnAgQXBwR2F0ZXdheSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0
X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9hcHBHYXRld2F5cy97YXBwX2dhdGV3YXlf
aWR9YAoKDQoFBAICAAUSBJ0BAggKDQoFBAICAAESBJ0BCQ0KDQoFBAICAAMSBJ0BEBEKDwoF
BAICAAgSBp0BEqIBAwoQCggEAgIACJwIABIEngEEKgoRCgcEAgIACJ8IEgafAQShAQUKQAoC
BAMSBqYBAMsBARoyIFJlcXVlc3QgbWVzc2FnZSBmb3IgQmV5b25kQ29ycC5DcmVhdGVBcHBH
YXRld2F5LgoKCwoDBAMBEgSmAQgfCpIBCgQEAwIAEgapAQKuAQQagQEgUmVxdWlyZWQuIFRo
ZSByZXNvdXJjZSBwcm9qZWN0IG5hbWUgb2YgdGhlIEFwcEdhdGV3YXkgbG9jYXRpb24gdXNp
bmcgdGhlCiBmb3JtOiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRp
b25faWR9YAoKDQoFBAMCAAUSBKkBAggKDQoFBAMCAAESBKkBCQ8KDQoFBAMCAAMSBKkBEhMK
DwoFBAMCAAgSBqkBFK4BAwoQCggEAwIACJwIABIEqgEEKgoRCgcEAwIACJ8IEgarAQStAQUK
xQEKBAQDAgESBLQBAkUatgEgT3B0aW9uYWwuIFVzZXItc2V0dGFibGUgQXBwR2F0ZXdheSBy
ZXNvdXJjZSBJRC4KICAqIE11c3Qgc3RhcnQgd2l0aCBhIGxldHRlci4KICAqIE11c3QgY29u
dGFpbiBiZXR3ZWVuIDQtNjMgY2hhcmFjdGVycyBmcm9tIGAvW2Etel1bMC05XS0vYC4KICAq
IE11c3QgZW5kIHdpdGggYSBudW1iZXIgb3IgYSBsZXR0ZXIuCgoNCgUEAwIBBRIEtAECCAoN
CgUEAwIBARIEtAEJFwoNCgUEAwIBAxIEtAEaGwoNCgUEAwIBCBIEtAEcRAoQCggEAwIBCJwI
ABIEtAEdQwo7CgQEAwICEgS3AQJGGi0gUmVxdWlyZWQuIEEgQmV5b25kQ29ycCBBcHBHYXRl
d2F5IHJlc291cmNlLgoKDQoFBAMCAgYSBLcBAgwKDQoFBAMCAgESBLcBDRgKDQoFBAMCAgMS
BLcBGxwKDQoFBAMCAggSBLcBHUUKEAoIBAMCAgicCAASBLcBHkQKjwYKBAQDAgMSBMYBAkEa
gAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVz
dHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCBy
ZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhl
IHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIg
d2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhl
IGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdo
ZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRoZSByZXF1ZXN0IHRpbWVz
IG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1
ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdp
dGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwg
aWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9t
IGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJl
cXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQg
emVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0w
MDAwMDAwMDAwMDApLgoKDQoFBAMCAwUSBMYBAggKDQoFBAMCAwESBMYBCRMKDQoFBAMCAwMS
BMYBFhcKDQoFBAMCAwgSBMYBGEAKEAoIBAMCAwicCAASBMYBGT8KegoEBAMCBBIEygECQhps
IE9wdGlvbmFsLiBJZiBzZXQsIHZhbGlkYXRlcyByZXF1ZXN0IGJ5IGV4ZWN1dGluZyBhIGRy
eS1ydW4gd2hpY2ggd291bGQgbm90CiBhbHRlciB0aGUgcmVzb3VyY2UgaW4gYW55IHdheS4K
Cg0KBQQDAgQFEgTKAQIGCg0KBQQDAgQBEgTKAQcUCg0KBQQDAgQDEgTKARcYCg0KBQQDAgQI
EgTKARlBChAKCAQDAgQInAgAEgTKARpACkAKAgQEEgbOAQDqAQEaMiBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIEJleW9uZENvcnAuRGVsZXRlQXBwR2F0ZXdheS4KCgsKAwQEARIEzgEIHwqVAQoE
BAQCABIG0QEC1gEEGoQBIFJlcXVpcmVkLiBCZXlvbmRDb3JwIEFwcEdhdGV3YXkgbmFtZSB1
c2luZyB0aGUgZm9ybToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbl9pZH0vYXBwR2F0ZXdheXMve2FwcF9nYXRld2F5X2lkfWAKCg0KBQQEAgAFEgTRAQII
Cg0KBQQEAgABEgTRAQkNCg0KBQQEAgADEgTRARARCg8KBQQEAgAIEgbRARLWAQMKEAoIBAQC
AAicCAASBNIBBCoKEQoHBAQCAAifCBIG0wEE1QEFCo8GCgQEBAIBEgTlAQJBGoAGIE9wdGlv
bmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVj
aWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91
ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0
IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1
YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIGFmdGVyIHRoZSBmaXJzdCBy
ZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3Ug
bWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUgcmVxdWVzdCB0aW1lcyBvdXQuIElm
IHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQs
IHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBz
YW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0
aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVu
dGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElE
IG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJ
RCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAw
MDAwKS4KCg0KBQQEAgEFEgTlAQIICg0KBQQEAgEBEgTlAQkTCg0KBQQEAgEDEgTlARYXCg0K
BQQEAgEIEgTlARhAChAKCAQEAgEInAgAEgTlARk/CnoKBAQEAgISBOkBAkIabCBPcHRpb25h
bC4gSWYgc2V0LCB2YWxpZGF0ZXMgcmVxdWVzdCBieSBleGVjdXRpbmcgYSBkcnktcnVuIHdo
aWNoIHdvdWxkIG5vdAogYWx0ZXIgdGhlIHJlc291cmNlIGluIGFueSB3YXkuCgoNCgUEBAIC
BRIE6QECBgoNCgUEBAICARIE6QEHFAoNCgUEBAICAxIE6QEXGAoNCgUEBAICCBIE6QEZQQoQ
CggEBAICCJwIABIE6QEaQAqcAgoCBAUSBvABANUCARqNAiBBIEJleW9uZENvcnAgQXBwR2F0
ZXdheSByZXNvdXJjZSByZXByZXNlbnRzIGEgQmV5b25kQ29ycCBwcm90ZWN0ZWQgQXBwR2F0
ZXdheQogdG8gYSByZW1vdGUgYXBwbGljYXRpb24uIEl0IGNyZWF0ZXMgYWxsIHRoZSBuZWNl
c3NhcnkgR0NQIGNvbXBvbmVudHMgbmVlZGVkCiBmb3IgY3JlYXRpbmcgYSBCZXlvbmRDb3Jw
IHByb3RlY3RlZCBBcHBHYXRld2F5LiBNdWx0aXBsZSBjb25uZWN0b3JzIGNhbiBiZQogYXV0
aG9yaXNlZCBmb3IgYSBzaW5nbGUgQXBwR2F0ZXdheS4KCgsKAwQFARIE8AEIEgoNCgMEBQcS
BvEBAvQBBAoPCgUEBQedCBIG8QEC9AEECjkKBAQFAwASBvcBAv0BAxopIEFsbG9jYXRlZCBj
b25uZWN0aW9uIG9mIHRoZSBBcHBHYXRld2F5LgoKDQoFBAUDAAESBPcBCh0KQgoGBAUDAAIA
EgT5AQRAGjIgUmVxdWlyZWQuIFRoZSBQU0MgdXJpIG9mIGFuIGFsbG9jYXRlZCBjb25uZWN0
aW9uCgoPCgcEBQMAAgAFEgT5AQQKCg8KBwQFAwACAAESBPkBCxIKDwoHBAUDAAIAAxIE+QEV
FgoPCgcEBQMAAgAIEgT5ARc/ChIKCgQFAwACAAicCAASBPkBGD4KRwoGBAUDAAIBEgT8AQRE
GjcgUmVxdWlyZWQuIFRoZSBpbmdyZXNzIHBvcnQgb2YgYW4gYWxsb2NhdGVkIGNvbm5lY3Rp
b24KCg8KBwQFAwACAQUSBPwBBAkKDwoHBAUDAAIBARIE/AEKFgoPCgcEBQMAAgEDEgT8ARka
Cg8KBwQFAwACAQgSBPwBG0MKEgoKBAUDAAIBCJwIABIE/AEcQgp4CgQEBQQAEgaBAgKHAgMa
aCBFbnVtIGNvbnRhaW5pbmcgbGlzdCBvZiBhbGwgcG9zc2libGUgbmV0d29yayBjb25uZWN0
aXZpdHkgb3B0aW9ucwogc3VwcG9ydGVkIGJ5IEJleW9uZENvcnAgQXBwR2F0ZXdheS4KCg0K
BQQFBAABEgSBAgcLCjYKBgQFBAACABIEgwIEGRomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFs
dWUgaXMgdW51c2VkLgoKDwoHBAUEAAIAARIEgwIEFAoPCgcEBQQAAgACEgSDAhcYClsKBgQF
BAACARIEhgIEEhpLIFRDUCBQcm94eSBiYXNlZCBCZXlvbmRDb3JwIENvbm5lY3Rpb24uIEFQ
SSB3aWxsIGRlZmF1bHQgdG8gdGhpcyBpZiB1bnNldC4KCg8KBwQFBAACAQESBIYCBA0KDwoH
BAUEAAIBAhIEhgIQEQpDCgQEBQQBEgaKAgKdAgMaMyBSZXByZXNlbnRzIHRoZSBkaWZmZXJl
bnQgc3RhdGVzIG9mIGFuIEFwcEdhdGV3YXkuCgoNCgUEBQQBARIEigIHDAo2CgYEBQQBAgAS
BIwCBBoaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg8KBwQFBAEC
AAESBIwCBBUKDwoHBAUEAQIAAhIEjAIYGQouCgYEBQQBAgESBI8CBBEaHiBBcHBHYXRld2F5
IGlzIGJlaW5nIGNyZWF0ZWQuCgoPCgcEBQQBAgEBEgSPAgQMCg8KBwQFBAECAQISBI8CDxAK
LgoGBAUEAQICEgSSAgQQGh4gQXBwR2F0ZXdheSBoYXMgYmVlbiBjcmVhdGVkLgoKDwoHBAUE
AQICARIEkgIECwoPCgcEBQQBAgICEgSSAg4PCj4KBgQFBAECAxIElQIEERouIEFwcEdhdGV3
YXkncyBjb25maWd1cmF0aW9uIGlzIGJlaW5nIHVwZGF0ZWQuCgoPCgcEBQQBAgMBEgSVAgQM
Cg8KBwQFBAECAwISBJUCDxAKLgoGBAUEAQIEEgSYAgQRGh4gQXBwR2F0ZXdheSBpcyBiZWlu
ZyBkZWxldGVkLgoKDwoHBAUEAQIEARIEmAIEDAoPCgcEBQQBAgQCEgSYAg8QCnkKBgQFBAEC
BRIEnAIEDRppIEFwcEdhdGV3YXkgaXMgZG93biBhbmQgbWF5IGJlIHJlc3RvcmVkIGluIHRo
ZSBmdXR1cmUuCiBUaGlzIGhhcHBlbnMgd2hlbiBDQ0ZFIHNlbmRzIFByb2plY3RTdGF0ZSA9
IE9GRi4KCg8KBwQFBAECBQESBJwCBAgKDwoHBAUEAQIFAhIEnAILDApmCgQEBQQCEgahAgKn
AgMaViBFbnVtIGNvbnRhaW5pbmcgbGlzdCBvZiBhbGwgcG9zc2libGUgaG9zdCB0eXBlcyBz
dXBwb3J0ZWQgYnkgQmV5b25kQ29ycAogQ29ubmVjdGlvbi4KCg0KBQQFBAIBEgShAgcPCjYK
BgQFBAICABIEowIEHhomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoK
DwoHBAUEAgIAARIEowIEGQoPCgcEBQQCAgACEgSjAhwdCk0KBgQFBAICARIEpgIEGRo9IEFw
cEdhdGV3YXkgaG9zdGVkIGluIGEgR0NQIHJlZ2lvbmFsIG1hbmFnZWQgaW5zdGFuY2UgZ3Jv
dXAuCgoPCgcEBQQCAgEBEgSmAgQUCg8KBwQFBAICAQISBKYCFxgKcwoEBAUCABIEqwICOxpl
IFJlcXVpcmVkLiBVbmlxdWUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQXBwR2F0ZXdheS4KIFRo
ZSBuYW1lIGlzIGlnbm9yZWQgd2hlbiBjcmVhdGluZyBhbiBBcHBHYXRld2F5LgoKDQoFBAUC
AAUSBKsCAggKDQoFBAUCAAESBKsCCQ0KDQoFBAUCAAMSBKsCEBEKDQoFBAUCAAgSBKsCEjoK
EAoIBAUCAAicCAASBKsCEzkKRwoEBAUCARIGrgICrwIyGjcgT3V0cHV0IG9ubHkuIFRpbWVz
dGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgY3JlYXRlZC4KCg0KBQQFAgEGEgSuAgIbCg0K
BQQFAgEBEgSuAhwnCg0KBQQFAgEDEgSuAiorCg0KBQQFAgEIEgSvAgYxChAKCAQFAgEInAgA
EgSvAgcwCk0KBAQFAgISBrICArMCMho9IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0
aGUgcmVzb3VyY2Ugd2FzIGxhc3QgbW9kaWZpZWQuCgoNCgUEBQICBhIEsgICGwoNCgUEBQIC
ARIEsgIcJwoNCgUEBQICAxIEsgIqKwoNCgUEBQICCBIEswIGMQoQCggEBQICCJwIABIEswIH
MApOCgQEBQIDEgS2AgJKGkAgT3B0aW9uYWwuIFJlc291cmNlIGxhYmVscyB0byByZXByZXNl
bnQgdXNlciBwcm92aWRlZCBtZXRhZGF0YS4KCg0KBQQFAgMGEgS2AgIVCg0KBQQFAgMBEgS2
AhYcCg0KBQQFAgMDEgS2Ah8gCg0KBQQFAgMIEgS2AiFJChAKCAQFAgMInAgAEgS2AiJICmsK
BAQFAgQSBLoCAkMaXSBPcHRpb25hbC4gQW4gYXJiaXRyYXJ5IHVzZXItcHJvdmlkZWQgbmFt
ZSBmb3IgdGhlIEFwcEdhdGV3YXkuIENhbm5vdCBleGNlZWQKIDY0IGNoYXJhY3RlcnMuCgoN
CgUEBQIEBRIEugICCAoNCgUEBQIEARIEugIJFQoNCgUEBQIEAxIEugIYGQoNCgUEBQIECBIE
ugIaQgoQCggEBQIECJwIABIEugIbQQpbCgQEBQIFEgS+AgI9Gk0gT3V0cHV0IG9ubHkuIEEg
dW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBpbnN0YW5jZSBnZW5lcmF0ZWQgYnkgdGhlCiBz
eXN0ZW0uCgoNCgUEBQIFBRIEvgICCAoNCgUEBQIFARIEvgIJDAoNCgUEBQIFAxIEvgIPEAoN
CgUEBQIFCBIEvgIRPAoQCggEBQIFCJwIABIEvgISOwpSCgQEBQIGEgTBAgI5GkQgUmVxdWly
ZWQuIFRoZSB0eXBlIG9mIG5ldHdvcmsgY29ubmVjdGl2aXR5IHVzZWQgYnkgdGhlIEFwcEdh
dGV3YXkuCgoNCgUEBQIGBhIEwQICBgoNCgUEBQIGARIEwQIHCwoNCgUEBQIGAxIEwQIODwoN
CgUEBQIGCBIEwQIQOAoQCggEBQIGCJwIABIEwQIRNwpBCgQEBQIHEgTEAgI+GjMgT3V0cHV0
IG9ubHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBBcHBHYXRld2F5LgoKDQoFBAUCBwYS
BMQCAgcKDQoFBAUCBwESBMQCCA0KDQoFBAUCBwMSBMQCEBEKDQoFBAUCBwgSBMQCEj0KEAoI
BAUCBwicCAASBMQCEzwKQgoEBAUCCBIExwICPRo0IE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVm
aW5lZCBVUkkgZm9yIHRoaXMgcmVzb3VyY2UuCgoNCgUEBQIIBRIExwICCAoNCgUEBQIIARIE
xwIJDAoNCgUEBQIIAxIExwIPEAoNCgUEBQIICBIExwIRPAoQCggEBQIICJwIABIExwISOwpO
CgQEBQIJEgbKAgLLAjIaPiBPdXRwdXQgb25seS4gQSBsaXN0IG9mIGNvbm5lY3Rpb25zIGFs
bG9jYXRlZCBmb3IgdGhlIEdhdGV3YXkKCg0KBQQFAgkEEgTKAgIKCg0KBQQFAgkGEgTKAgse
Cg0KBQQFAgkBEgTKAh80Cg0KBQQFAgkDEgTKAjc5Cg0KBQQFAgkIEgTLAgYxChAKCAQFAgkI
nAgAEgTLAgcwCkUKBAQFAgoSBM4CAkMaNyBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgaG9zdGlu
ZyB1c2VkIGJ5IHRoZSBBcHBHYXRld2F5LgoKDQoFBAUCCgYSBM4CAgoKDQoFBAUCCgESBM4C
CxQKDQoFBAUCCgMSBM4CFxkKDQoFBAUCCggSBM4CGkIKEAoIBAUCCgicCAASBM4CG0EKNQoE
BAUCCxIE0QICTxonIE91dHB1dCBvbmx5LiBSZXNlcnZlZCBmb3IgZnV0dXJlIHVzZS4KCg0K
BQQFAgsEEgTRAgIKCg0KBQQFAgsFEgTRAgsPCg0KBQQFAgsBEgTRAhAdCg0KBQQFAgsDEgTR
AiAiCg0KBQQFAgsIEgTRAiNOChAKCAQFAgsInAgAEgTRAiRNCjUKBAQFAgwSBNQCAk8aJyBP
dXRwdXQgb25seS4gUmVzZXJ2ZWQgZm9yIGZ1dHVyZSB1c2UuCgoNCgUEBQIMBBIE1AICCgoN
CgUEBQIMBRIE1AILDwoNCgUEBQIMARIE1AIQHQoNCgUEBQIMAxIE1AIgIgoNCgUEBQIMCBIE
1AIjTgoQCggEBQIMCJwIABIE1AIkTQpGCgIEBhIG2AIA9AIBGjggUmVwcmVzZW50cyB0aGUg
bWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoLCgMEBgESBNgCCCMK
QgoEBAYCABIG2gIC2wIyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24g
d2FzIGNyZWF0ZWQuCgoNCgUEBgIABhIE2gICGwoNCgUEBgIAARIE2gIcJwoNCgUEBgIAAxIE
2gIqKwoNCgUEBgIACBIE2wIGMQoQCggEBgIACJwIABIE2wIHMApHCgQEBgIBEgbeAgLfAjIa
NyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5n
LgoKDQoFBAYCAQYSBN4CAhsKDQoFBAYCAQESBN4CHCQKDQoFBAYCAQMSBN4CJygKDQoFBAYC
AQgSBN8CBjEKEAoIBAYCAQicCAASBN8CBzAKWgoEBAYCAhIE4gICQBpMIE91dHB1dCBvbmx5
LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBv
cGVyYXRpb24uCgoNCgUEBgICBRIE4gICCAoNCgUEBgICARIE4gIJDwoNCgUEBgICAxIE4gIS
EwoNCgUEBgICCBIE4gIUPwoQCggEBgICCJwIABIE4gIVPgpICgQEBgIDEgTlAgI+GjogT3V0
cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4K
Cg0KBQQGAgMFEgTlAgIICg0KBQQGAgMBEgTlAgkNCg0KBQQGAgMDEgTlAhARCg0KBQQGAgMI
EgTlAhI9ChAKCAQGAgMInAgAEgTlAhM8CkwKBAQGAgQSBOgCAkgaPiBPdXRwdXQgb25seS4g
SHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCg0KBQQG
AgQFEgToAgIICg0KBQQGAgQBEgToAgkXCg0KBQQGAgQDEgToAhobCg0KBQQGAgQIEgToAhxH
ChAKCAQGAgQInAgAEgToAh1GCtMCCgQEBgIFEgTwAgJOGsQCIE91dHB1dCBvbmx5LiBJZGVu
dGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9m
IHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVu
IGNhbmNlbGxlZAogaGF2ZQogW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24uZXJyb3Jd
W2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24uZXJyb3JdCiB2YWx1ZSB3aXRoIGEgW2dv
b2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIGAxYCwK
IGNvcnJlc3BvbmRpbmcgdG8gYENvZGUuQ0FOQ0VMTEVEYC4KCg0KBQQGAgUFEgTwAgIGCg0K
BQQGAgUBEgTwAgcdCg0KBQQGAgUDEgTwAiAhCg0KBQQGAgUIEgTwAiJNChAKCAQGAgUInAgA
EgTwAiNMCkUKBAQGAgYSBPMCAkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNpb24gdXNlZCB0
byBzdGFydCB0aGUgb3BlcmF0aW9uLgoKDQoFBAYCBgUSBPMCAggKDQoFBAYCBgESBPMCCRQK
DQoFBAYCBgMSBPMCFxgKDQoFBAYCBggSBPMCGUQKEAoIBAYCBgicCAASBPMCGkNiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest ===
    # Fields for ListAppGatewaysRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysResponse ===
    # Fields for ListAppGatewaysResponse
    # Field: app_gateways Type: 11 (.google.cloud.beyondcorp.appgateways.v1.AppGateway)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::GetAppGatewayRequest ===
    # Fields for GetAppGatewayRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::CreateAppGatewayRequest ===
    # Fields for CreateAppGatewayRequest
    # Field: parent Type: 9 ()
    # Field: app_gateway_id Type: 9 ()
    # Field: app_gateway Type: 11 (.google.cloud.beyondcorp.appgateways.v1.AppGateway)
    # Field: request_id Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::DeleteAppGatewayRequest ===
    # Fields for DeleteAppGatewayRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway ===
    # Fields for AppGateway
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.beyondcorp.appgateways.v1.AppGateway.LabelsEntry)
    # Field: display_name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: type Type: 14 (.google.cloud.beyondcorp.appgateways.v1.AppGateway.Type)
    # Field: state Type: 14 (.google.cloud.beyondcorp.appgateways.v1.AppGateway.State)
    # Field: uri Type: 9 ()
    # Field: allocated_connections Type: 11 (.google.cloud.beyondcorp.appgateways.v1.AppGateway.AllocatedConnection)
    # Field: host_type Type: 14 (.google.cloud.beyondcorp.appgateways.v1.AppGateway.HostType)
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()

# Enum: AppGateway::Type
our $AppGateway_TYPE_UNSPECIFIED = 0;
our $AppGateway_TCP_PROXY = 1;

# Enum: AppGateway::State
our $AppGateway_STATE_UNSPECIFIED = 0;
our $AppGateway_CREATING = 1;
our $AppGateway_CREATED = 2;
our $AppGateway_UPDATING = 3;
our $AppGateway_DELETING = 4;
our $AppGateway_DOWN = 5;

# Enum: AppGateway::HostType
our $AppGateway_HOST_TYPE_UNSPECIFIED = 0;
our $AppGateway_GCP_REGIONAL_MIG = 1;

# === Message: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewayOperationMetadata ===
    # Fields for AppGatewayOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewaysServiceClient ===
package Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewaysServiceClient;

=pod

=head2 Service Client: Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewaysServiceClient

Client stub representing the remote C<AppGatewaysService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<beyondcorp.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'beyondcorp.googleapis.com:443' );

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

sub list_app_gateways {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.appgateways.v1.AppGatewaysService',
        method         => 'ListAppGateways',
        request        => $req,
        response_class => 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysResponse',
    });
}

sub get_app_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::GetAppGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.appgateways.v1.AppGatewaysService',
        method         => 'GetAppGateway',
        request        => $req,
        response_class => 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway',
    });
}

sub create_app_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::CreateAppGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.appgateways.v1.AppGatewaysService',
        method         => 'CreateAppGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_app_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::DeleteAppGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.appgateways.v1.AppGatewaysService',
        method         => 'DeleteAppGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService - Compiled Protocol Buffers messages for google/cloud/beyondcorp/appgateways/v1/app_gateways_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService;

    my $msg = Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/beyondcorp/appgateways/v1/app_gateways_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest

Request message for BeyondCorp.ListAppGateways.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the AppGateway location using the form:
`projects/{project_id}/locations/{location_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If not specified, a default value of 50 will be used by the service.
Regardless of the page_size value, the response may include a partial list
and a caller should only rely on response's
[next_page_token][google.cloud.beyondcorp.appgateways.v1.ListAppGatewaysResponse.next_page_token]
to determine if there are more instances left to be queried.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous
ListAppGatewaysRequest, if any.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter specifying constraints of a list operation.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Specifies the ordering of results. See
[Sorting
order](https://cloud.google.com/apis/design/design_patterns#sorting_order)
for more information.

=back

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysResponse

Response message for BeyondCorp.ListAppGateways.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app_gateways() >> / C<< $msg->app_gateways($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway>)

A list of BeyondCorp AppGateways in the project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results, or empty if there are no more
results in the list.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

A list of locations that could not be reached.

=back

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::GetAppGatewayRequest

Request message for BeyondCorp.GetAppGateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. BeyondCorp AppGateway name using the form:
`projects/{project_id}/locations/{location_id}/appGateways/{app_gateway_id}`

=back

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::CreateAppGatewayRequest

Request message for BeyondCorp.CreateAppGateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource project name of the AppGateway location using the
form: `projects/{project_id}/locations/{location_id}`

=item * C<< $msg->app_gateway_id() >> / C<< $msg->app_gateway_id($value) >>

Type: C<String>

Optional. User-settable AppGateway resource ID.
 * Must start with a letter.
 * Must contain between 4-63 characters from `/[a-z][0-9]-/`.
 * Must end with a number or a letter.

=item * C<< $msg->app_gateway() >> / C<< $msg->app_gateway($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway>)

Required. A BeyondCorp AppGateway resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validates request by executing a dry-run which would not
alter the resource in any way.

=back

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::DeleteAppGatewayRequest

Request message for BeyondCorp.DeleteAppGateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. BeyondCorp AppGateway name using the form:
`projects/{project_id}/locations/{location_id}/appGateways/{app_gateway_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validates request by executing a dry-run which would not
alter the resource in any way.

=back

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway

A BeyondCorp AppGateway resource represents a BeyondCorp protected AppGateway
to a remote application. It creates all the necessary GCP components needed
for creating a BeyondCorp protected AppGateway. Multiple connectors can be
authorised for a single AppGateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Unique resource name of the AppGateway.
The name is ignored when creating an AppGateway.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the resource was last modified.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::LabelsEntry>)

Optional. Resource labels to represent user provided metadata.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. An arbitrary user-provided name for the AppGateway. Cannot exceed
64 characters.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A unique identifier for the instance generated by the
system.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGateway::Type>)

Required. The type of network connectivity used by the AppGateway.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGateway::State>)

Output only. The current state of the AppGateway.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Output only. Server-defined URI for this resource.

=item * C<< $msg->allocated_connections() >> / C<< $msg->allocated_connections($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::AllocatedConnection>)

Output only. A list of connections allocated for the Gateway

=item * C<< $msg->host_type() >> / C<< $msg->host_type($value) >>

Type: C<Enum> (L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGateway::HostType>)

Required. The type of hosting used by the AppGateway.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=back

=head3 Enum: AppGateway::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<TCP_PROXY> => C<1>

=back

=head3 Enum: AppGateway::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<CREATED> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=item * C<DOWN> => C<5>

=back

=head3 Enum: AppGateway::HostType

=over 4

=item * C<HOST_TYPE_UNSPECIFIED> => C<0>

=item * C<GCP_REGIONAL_MIG> => C<1>

=back

=head2 Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewayOperationMetadata

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
of the operation. Operations that have successfully been cancelled
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of `1`,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
