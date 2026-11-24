package Google::Cloud::Ces::V1beta::ToolService;

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
    eval { require Google::Cloud::Ces::V1beta::Schema };
    eval { require Google::Cloud::Ces::V1beta::SearchSuggestions };
    eval { require Google::Cloud::Ces::V1beta::SessionService };
    eval { require Google::Cloud::Ces::V1beta::Tool };
    eval { require Google::Cloud::Ces::V1beta::ToolsetTool };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS90b29sX3NlcnZpY2UucHJvdG8SF2dvb2dsZS5j
bG91ZC5jZXMudjFiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvc2NoZW1h
LnByb3RvGjBnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9zZWFyY2hfc3VnZ2VzdGlvbnMucHJv
dG8aLWdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL3Nlc3Npb25fc2VydmljZS5wcm90bxoiZ29v
Z2xlL2Nsb3VkL2Nlcy92MWJldGEvdG9vbC5wcm90bxoqZ29vZ2xlL2Nsb3VkL2Nlcy92MWJl
dGEvdG9vbHNldF90b29sLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIvUD
ChJFeGVjdXRlVG9vbFJlcXVlc3QSNQoEdG9vbBgBIAEoCUIf4EEB+kEZChdjZXMuZ29vZ2xl
YXBpcy5jb20vVG9vbEgAUgR0b29sEk4KDHRvb2xzZXRfdG9vbBgDIAEoCzIkLmdvb2dsZS5j
bG91ZC5jZXMudjFiZXRhLlRvb2xzZXRUb29sQgPgQQFIAFILdG9vbHNldFRvb2wSPAoJdmFy
aWFibGVzGAUgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBSAFSCXZhcmlhYmxl
cxI4Cgdjb250ZXh0GAYgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBSAFSB2Nv
bnRleHQSNgoGcGFyZW50GAQgASgJQh7gQQL6QRgKFmNlcy5nb29nbGVhcGlzLmNvbS9BcHBS
BnBhcmVudBIwCgRhcmdzGAIgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBUgRh
cmdzEkkKC21vY2tfY29uZmlnGAcgASgLMiMuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuTW9j
a0NvbmZpZ0ID4EEBUgptb2NrQ29uZmlnQhEKD3Rvb2xfaWRlbnRpZmllckIYChZ0b29sX2V4
ZWN1dGlvbl9jb250ZXh0IsMDChNFeGVjdXRlVG9vbFJlc3BvbnNlEjIKBHRvb2wYASABKAlC
HPpBGQoXY2VzLmdvb2dsZWFwaXMuY29tL1Rvb2xIAFIEdG9vbBJJCgx0b29sc2V0X3Rvb2wY
AyABKAsyJC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Ub29sc2V0VG9vbEgAUgt0b29sc2V0
VG9vbBIzCghyZXNwb25zZRgCIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCHJlc3Bv
bnNlEjUKCXZhcmlhYmxlcxgEIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCXZhcmlh
YmxlcxJACgljaXRhdGlvbnMYBSABKAsyIi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5DaXRh
dGlvbnNSCWNpdGF0aW9ucxJsChlnb29nbGVfc2VhcmNoX3N1Z2dlc3Rpb25zGAYgASgLMjAu
Z29vZ2xlLmNsb3VkLmNlcy52MWJldGEuR29vZ2xlU2VhcmNoU3VnZ2VzdGlvbnNSF2dvb2ds
ZVNlYXJjaFN1Z2dlc3Rpb25zQhEKD3Rvb2xfaWRlbnRpZmllciLtAQoZUmV0cmlldmVUb29s
U2NoZW1hUmVxdWVzdBI1CgR0b29sGAEgASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVhcGlzLmNv
bS9Ub29sSABSBHRvb2wSTgoMdG9vbHNldF90b29sGAIgASgLMiQuZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEuVG9vbHNldFRvb2xCA+BBAUgAUgt0b29sc2V0VG9vbBI2CgZwYXJlbnQYAyAB
KAlCHuBBAvpBGAoWY2VzLmdvb2dsZWFwaXMuY29tL0FwcFIGcGFyZW50QhEKD3Rvb2xfaWRl
bnRpZmllciK4AgoaUmV0cmlldmVUb29sU2NoZW1hUmVzcG9uc2USMgoEdG9vbBgBIAEoCUIc
+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbEgAUgR0b29sEkkKDHRvb2xzZXRfdG9vbBgC
IAEoCzIkLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlRvb2xzZXRUb29sSABSC3Rvb2xzZXRU
b29sEkIKDGlucHV0X3NjaGVtYRgDIAEoCzIfLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlNj
aGVtYVILaW5wdXRTY2hlbWESRAoNb3V0cHV0X3NjaGVtYRgEIAEoCzIfLmdvb2dsZS5jbG91
ZC5jZXMudjFiZXRhLlNjaGVtYVIMb3V0cHV0U2NoZW1hQhEKD3Rvb2xfaWRlbnRpZmllciK1
AQoUUmV0cmlldmVUb29sc1JlcXVlc3QSPAoHdG9vbHNldBgBIAEoCUIi4EEC+kEcChpjZXMu
Z29vZ2xlYXBpcy5jb20vVG9vbHNldFIHdG9vbHNldBIeCgh0b29sX2lkcxgDIAMoCUID4EEB
Ugd0b29sSWRzEj8KGWJ5cGFzc19wZXJzaXN0ZW5jZV9jb25maWcYBCABKAhCA+BBAVIXYnlw
YXNzUGVyc2lzdGVuY2VDb25maWciTAoVUmV0cmlldmVUb29sc1Jlc3BvbnNlEjMKBXRvb2xz
GAEgAygLMh0uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuVG9vbFIFdG9vbHMyvwUKC1Rvb2xT
ZXJ2aWNlEq8BCgtFeGVjdXRlVG9vbBIrLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkV4ZWN1
dGVUb29sUmVxdWVzdBosLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkV4ZWN1dGVUb29sUmVz
cG9uc2UiRYLT5JMCPyI6L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
YXBwcy8qfTpleGVjdXRlVG9vbDoBKhLLAQoSUmV0cmlldmVUb29sU2NoZW1hEjIuZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEuUmV0cmlldmVUb29sU2NoZW1hUmVxdWVzdBozLmdvb2dsZS5j
bG91ZC5jZXMudjFiZXRhLlJldHJpZXZlVG9vbFNjaGVtYVJlc3BvbnNlIkyC0+STAkYiQS92
MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FwcHMvKn06cmV0cmlldmVU
b29sU2NoZW1hOgEqEsMBCg1SZXRyaWV2ZVRvb2xzEi0uZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuUmV0cmlldmVUb29sc1JlcXVlc3QaLi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5SZXRy
aWV2ZVRvb2xzUmVzcG9uc2UiU4LT5JMCTSJIL3YxYmV0YS97dG9vbHNldD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2FwcHMvKi90b29sc2V0cy8qfTpyZXRyaWV2ZVRvb2xzOgEqGmrKQRJj
ZXMuZ29vZ2xlYXBpcy5jb23SQVJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nl
cyxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQmAKG2Nv
bS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YUIQVG9vbFNlcnZpY2VQcm90b1ABWi1jbG91ZC5n
b29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJKgzsKBxIFDgDeAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAJgoJ
CgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAuCgkKAgMFEgMXADoK
CQoCAwYSAxgANwoJCgIDBxIDGQAsCgkKAgMIEgMaADQKCQoCAwkSAxsAJgoICgEIEgMdAEQK
CQoCCAsSAx0ARAoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADEKCQoCCAgSAx8AMQoI
CgEIEgMgADQKCQoCCAESAyAANApICgIGABIEIwBCARo8IFRvb2wgc2VydmljZSBwcm92aWRl
cyBBUElzIGZvciBpbnRlcmFjdGluZyB3aXRoIENFUyB0b29scy4KCgoKAwYAARIDIwgTCgoK
AwYAAxIDJAI6CgwKBQYAA5kIEgMkAjoKCwoDBgADEgQlAic3Cg0KBQYAA5oIEgQlAic3CkEK
BAYAAgASBCoCLwMaMyBFeGVjdXRlcyB0aGUgZ2l2ZW4gdG9vbCB3aXRoIHRoZSBnaXZlbiBh
cmd1bWVudHMuCgoMCgUGAAIAARIDKgYRCgwKBQYAAgACEgMqEiQKDAoFBgACAAMSAyovQgoN
CgUGAAIABBIEKwQuBgoRCgkGAAIABLDKvCISBCsELgYKfQoEBgACARIEMwI5AxpvIFJldHJp
ZXZlIHRoZSBzY2hlbWEgb2YgdGhlIGdpdmVuIHRvb2wuIFRoZSBzY2hlbWEgaXMgY29tcHV0
ZWQgb24gdGhlIGZseQogZm9yIHRoZSBnaXZlbiBpbnN0YW5jZSBvZiB0aGUgdG9vbC4KCgwK
BQYAAgEBEgMzBhgKDAoFBgACAQISAzMZMgoMCgUGAAIBAxIDNA8pCg0KBQYAAgEEEgQ1BDgG
ChEKCQYAAgEEsMq8IhIENQQ4BgpNCgQGAAICEgQ8AkEDGj8gUmV0cmlldmUgdGhlIGxpc3Qg
b2YgdG9vbHMgaW5jbHVkZWQgaW4gdGhlIHNwZWNpZmllZCB0b29sc2V0LgoKDAoFBgACAgES
AzwGEwoMCgUGAAICAhIDPBQoCgwKBQYAAgIDEgM8M0gKDQoFBgACAgQSBD0EQAYKEQoJBgAC
AgSwyrwiEgQ9BEAGCm4KAgQAEgRGAHIBGmIgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1Rvb2xT
ZXJ2aWNlLkV4ZWN1dGVUb29sXVtnb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Ub29sU2Vydmlj
ZS5FeGVjdXRlVG9vbF0uCgoKCgMEAAESA0YIGgp1CgQEAAgAEgRJAlUDGmcgVGhlIGlkZW50
aWZpZXIgb2YgdGhlIHRvb2wgdG8gZXhlY3V0ZS4gSXQgY291bGQgYmUgZWl0aGVyIGEgcGVy
c2lzdGVkIHRvb2wKIG9yIGEgdG9vbCBmcm9tIGEgdG9vbHNldC4KCgwKBQQACAABEgNJCBcK
hAEKBAQAAgASBE0EUAYadiBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wgdG8gZXhl
Y3V0ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfQoKDAoFBAACAAUSA00ECgoMCgUEAAIAARIDTQsP
CgwKBQQAAgADEgNNEhMKDQoFBAACAAgSBE0UUAUKDwoIBAACAAicCAASA04GLAoOCgcEAAIA
CJ8IEgNPBksKmAEKBAQAAgESA1QEShqKASBPcHRpb25hbC4gVGhlIHRvb2xzZXQgdG9vbCB0
byBleGVjdXRlLiBPbmx5IG9uZSB0b29sIHNob3VsZCBtYXRjaCB0aGUKIHByZWRpY2F0ZSBm
cm9tIHRoZSB0b29sc2V0LiBPdGhlcndpc2UsIGFuIGVycm9yIHdpbGwgYmUgcmV0dXJuZWQu
CgoMCgUEAAIBBhIDVAQPCgwKBQQAAgEBEgNUEBwKDAoFBAACAQMSA1QfIAoMCgUEAAIBCBID
VCFJCg8KCAQAAgEInAgAEgNUIkgKSAoEBAAIARIEWAJhAxo6IEFkZGl0aW9uYWwgY29udGV4
dCB0byBiZSBwcm92aWRlZCBmb3IgdGhlIHRvb2wgZXhlY3V0aW9uCgoMCgUEAAgBARIDWAge
ClIKBAQAAgISBFoEWzEaRCBPcHRpb25hbC4gVGhlIHZhcmlhYmxlcyB0aGF0IGFyZSBhdmFp
bGFibGUgZm9yIHRoZSB0b29sIGV4ZWN1dGlvbi4KCgwKBQQAAgIGEgNaBBoKDAoFBAACAgES
A1obJAoMCgUEAAICAxIDWicoCgwKBQQAAgIIEgNbCDAKDwoIBAACAgicCAASA1sJLwrFAQoE
BAACAxIDYARQGrcBIE9wdGlvbmFsLiBUaGUKIFtUb29sQ2FsbENvbnRleHRdKGh0dHBzOi8v
ZG9jcy5jbG91ZC5nb29nbGUuY29tL2N1c3RvbWVyLWVuZ2FnZW1lbnQtYWkvY29udmVyc2F0
aW9uYWwtYWdlbnRzL3BzL3Rvb2wvcHl0aG9uI2Vudmlyb25tZW50CiBmb3IgZGV0YWlscykg
dG8gYmUgcGFzc2VkIHRvIHRoZSBQeXRob24gdG9vbC4KCgwKBQQAAgMGEgNgBBoKDAoFBAAC
AwESA2AbIgoMCgUEAAIDAxIDYCUmCgwKBQQAAgMIEgNgJ08KDwoIBAACAwicCAASA2AoTgqY
AQoEBAACBBIEZQJoBBqJASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGFw
cCB3aGljaCB0aGUgdG9vbC90b29sc2V0IGJlbG9uZ3MgdG8uCiBGb3JtYXQ6IGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfWAKCgwKBQQAAgQF
EgNlAggKDAoFBAACBAESA2UJDwoMCgUEAAIEAxIDZRITCg0KBQQAAgQIEgRlFGgDCg8KCAQA
AgQInAgAEgNmBCoKDgoHBAACBAifCBIDZwRICl0KBAQAAgUSA2wCSxpQIE9wdGlvbmFsLiBU
aGUgaW5wdXQgcGFyYW1ldGVycyBhbmQgdmFsdWVzIGZvciB0aGUgdG9vbCBpbiBKU09OIG9i
amVjdAogZm9ybWF0LgoKDAoFBAACBQYSA2wCGAoMCgUEAAIFARIDbBkdCgwKBQQAAgUDEgNs
ICEKDAoFBAACBQgSA2wiSgoPCggEAAIFCJwIABIDbCNJCrUBCgQEAAIGEgNxAkYapwEgT3B0
aW9uYWwuIE1vY2sgY29uZmlndXJhdGlvbiBmb3IgdGhlIHRvb2wgZXhlY3V0aW9uLgogSWYg
dGhpcyBmaWVsZCBpcyBzZXQsIHRvb2xzIHRoYXQgY2FsbCBvdGhlciB0b29scyB3aWxsIGJl
CiBtb2NrZWQgYmFzZWQgb24gdGhlIHByb3ZpZGVkIHBhdHRlcm5zIGFuZCByZXNwb25zZXMu
CgoMCgUEAAIGBhIDcQIMCgwKBQQAAgYBEgNxDRgKDAoFBAACBgMSA3EbHAoMCgUEAAIGCBID
cR1FCg8KCAQAAgYInAgAEgNxHkQKcAoCBAESBXYAkQEBGmMgUmVzcG9uc2UgbWVzc2FnZSBm
b3IKIFtUb29sU2VydmljZS5FeGVjdXRlVG9vbF1bZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEu
VG9vbFNlcnZpY2UuRXhlY3V0ZVRvb2xdLgoKCgoDBAEBEgN2CBsKPgoEBAEIABIFeAKAAQMa
LyBUaGUgaWRlbnRpZmllciBvZiB0aGUgdG9vbCB0aGF0IGdvdCBleGVjdXRlZC4KCgwKBQQB
CAABEgN4CBcKggEKBAQBAgASBHsEfFAadCBUaGUgbmFtZSBvZiB0aGUgdG9vbCB0aGF0IGdv
dCBleGVjdXRlZC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfWAKCgwKBQQBAgAFEgN7BAoKDAoFBAEC
AAESA3sLDwoMCgUEAQIAAxIDexITCgwKBQQBAgAIEgN8CE8KDgoHBAECAAifCBIDfAlOCjIK
BAQBAgESA38EIRolIFRoZSB0b29sc2V0IHRvb2wgdGhhdCBnb3QgZXhlY3V0ZWQuCgoMCgUE
AQIBBhIDfwQPCgwKBQQBAgEBEgN/EBwKDAoFBAECAQMSA38fIAqMAgoEBAECAhIEhgECJhr9
ASBUaGUgdG9vbCBleGVjdXRpb24gcmVzdWx0IGluIEpTT04gb2JqZWN0IGZvcm1hdC4KIFVz
ZSAib3V0cHV0IiBrZXkgdG8gc3BlY2lmeSB0b29sIHJlc3BvbnNlIGFuZCAiZXJyb3IiIGtl
eSB0byBzcGVjaWZ5CiBlcnJvciBkZXRhaWxzIChpZiBhbnkpLiBJZiAib3V0cHV0IiBhbmQg
ImVycm9yIiBrZXlzIGFyZSBub3Qgc3BlY2lmaWVkLAogdGhlbiB3aG9sZSAicmVzcG9uc2Ui
IGlzIHRyZWF0ZWQgYXMgdG9vbCBleGVjdXRpb24gcmVzdWx0LgoKDQoFBAECAgYSBIYBAhgK
DQoFBAECAgESBIYBGSEKDQoFBAECAgMSBIYBJCUKRQoEBAECAxIEiQECJxo3IFRoZSB2YXJp
YWJsZSB2YWx1ZXMgYXQgdGhlIGVuZCBvZiB0aGUgdG9vbCBleGVjdXRpb24uCgoNCgUEAQID
BhIEiQECGAoNCgUEAQIDARIEiQEZIgoNCgUEAQIDAxIEiQElJgpXCgQEAQIEEgSMAQIaGkkg
Q2l0YXRpb25zIHRoYXQgcHJvdmlkZSB0aGUgc291cmNlIGluZm9ybWF0aW9uIGZvciB0aGUg
dG9vbCdzIGV4ZWN1dGlvbi4KCg0KBQQBAgQGEgSMAQILCg0KBQQBAgQBEgSMAQwVCg0KBQQB
AgQDEgSMARgZCoYBCgQEAQIFEgSQAQI4GnggVGhlIHN1Z2dlc3Rpb25zIHJldHVybmVkIGZy
b20gR29vZ2xlIFNlYXJjaCBhcyBhIHJlc3VsdCBvZiBpbnZva2luZyB0aGUKIEdvb2dsZSBT
ZWFyY2ggVG9vbCBkdXJpbmcgdGhlIHRvb2wgZXhlY3V0aW9uLgoKDQoFBAECBQYSBJABAhkK
DQoFBAECBQESBJABGjMKDQoFBAECBQMSBJABNjcKfgoCBAISBpUBAK0BARpwIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtUb29sU2VydmljZS5SZXRyaWV2ZVRvb2xTY2hlbWFdW2dvb2dsZS5j
bG91ZC5jZXMudjFiZXRhLlRvb2xTZXJ2aWNlLlJldHJpZXZlVG9vbFNjaGVtYV0uCgoLCgME
AgESBJUBCCEKhwEKBAQCCAASBpgBAqUBAxp3IFRoZSBpZGVudGlmaWVyIG9mIHRoZSB0b29s
IHRvIHJldHJpZXZlIHRoZSBzY2hlbWEgZm9yLiBJdCBjb3VsZCBiZSBlaXRoZXIgYQogcGVy
c2lzdGVkIHRvb2wgb3IgYSB0b29sIGZyb20gYSB0b29sc2V0LgoKDQoFBAIIAAESBJgBCBcK
lwEKBAQCAgASBpwBBJ8BBhqGASBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wgdG8g
cmV0cmlldmUgdGhlIHNjaGVtYSBmb3IuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS90b29scy97dG9vbH0KCg0KBQQCAgAF
EgScAQQKCg0KBQQCAgABEgScAQsPCg0KBQQCAgADEgScARITCg8KBQQCAgAIEgacARSfAQUK
EAoIBAICAAicCAASBJ0BBiwKDwoHBAICAAifCBIEngEGSwqqAQoEBAICARIEpAEEShqbASBP
cHRpb25hbC4gVGhlIHRvb2xzZXQgdG9vbCB0byByZXRyaWV2ZSB0aGUgc2NoZW1hIGZvci4g
T25seSBvbmUgdG9vbAogc2hvdWxkIG1hdGNoIHRoZSBwcmVkaWNhdGUgZnJvbSB0aGUgdG9v
bHNldC4gT3RoZXJ3aXNlLCBhbiBlcnJvciB3aWxsIGJlCiByZXR1cm5lZC4KCg0KBQQCAgEG
EgSkAQQPCg0KBQQCAgEBEgSkARAcCg0KBQQCAgEDEgSkAR8gCg0KBQQCAgEIEgSkASFJChAK
CAQCAgEInAgAEgSkASJICpoBCgQEAgICEgapAQKsAQQaiQEgUmVxdWlyZWQuIFRoZSByZXNv
dXJjZSBuYW1lIG9mIHRoZSBhcHAgd2hpY2ggdGhlIHRvb2wvdG9vbHNldCBiZWxvbmdzIHRv
LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fw
cHMve2FwcH1gCgoNCgUEAgICBRIEqQECCAoNCgUEAgICARIEqQEJDwoNCgUEAgICAxIEqQES
EwoPCgUEAgICCBIGqQEUrAEDChAKCAQCAgIInAgAEgSqAQQqCg8KBwQCAgIInwgSBKsBBEgK
fwoCBAMSBrEBAMIBARpxIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbVG9vbFNlcnZpY2UuUmV0
cmlldmVUb29sU2NoZW1hXVtnb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Ub29sU2VydmljZS5S
ZXRyaWV2ZVRvb2xTY2hlbWFdLgoKCwoDBAMBEgSxAQgiCkQKBAQDCAASBrMBArsBAxo0IFRo
ZSBpZGVudGlmaWVyIG9mIHRoZSB0b29sIHRoYXQgdGhlIHNjaGVtYSBpcyBmb3IuCgoNCgUE
AwgAARIEswEIFwqJAQoEBAMCABIGtgEEtwFQGnkgVGhlIG5hbWUgb2YgdGhlIHRvb2wgdGhh
dCB0aGUgc2NoZW1hIGlzIGZvci4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfWAKCg0KBQQDAgAFEgS2
AQQKCg0KBQQDAgABEgS2AQsPCg0KBQQDAgADEgS2ARITCg0KBQQDAgAIEgS3AQhPCg8KBwQD
AgAInwgSBLcBCU4KOAoEBAMCARIEugEEIRoqIFRoZSB0b29sc2V0IHRvb2wgdGhhdCB0aGUg
c2NoZW1hIGlzIGZvci4KCg0KBQQDAgEGEgS6AQQPCg0KBQQDAgEBEgS6ARAcCg0KBQQDAgED
EgS6AR8gCjgKBAQDAgISBL4BAhoaKiBUaGUgc2NoZW1hIG9mIHRoZSB0b29sIGlucHV0IHBh
cmFtZXRlcnMuCgoNCgUEAwICBhIEvgECCAoNCgUEAwICARIEvgEJFQoNCgUEAwICAxIEvgEY
GQo5CgQEAwIDEgTBAQIbGisgVGhlIHNjaGVtYSBvZiB0aGUgdG9vbCBvdXRwdXQgcGFyYW1l
dGVycy4KCg0KBQQDAgMGEgTBAQIICg0KBQQDAgMBEgTBAQkWCg0KBQQDAgMDEgTBARkaCnQK
AgQEEgbGAQDXAQEaZiBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVG9vbFNlcnZpY2UuUmV0cmll
dmVUb29sc11bZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuVG9vbFNlcnZpY2UuUmV0cmlldmVU
b29sc10uCgoLCgMEBAESBMYBCBwKoQEKBAQEAgASBsoBAs0BBBqQASBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIHRvb2xzZXQgdG8gcmV0cmlldmUgdGhlIHRvb2xzIGZvci4KIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBw
fS90b29sc2V0cy97dG9vbHNldH1gCgoNCgUEBAIABRIEygECCAoNCgUEBAIAARIEygEJEAoN
CgUEBAIAAxIEygETFAoPCgUEBAIACBIGygEVzQEDChAKCAQEAgAInAgAEgTLAQQqCg8KBwQE
AgAInwgSBMwBBEwKigEKBAQEAgESBNEBAkgafCBPcHRpb25hbC4gVGhlIGlkZW50aWZpZXJz
IG9mIHRoZSB0b29scyB0byByZXRyaWV2ZSBmcm9tIHRoZSB0b29sc2V0LgogSWYgZW1wdHks
IGFsbCB0b29scyBpbiB0aGUgdG9vbHNldCB3aWxsIGJlIHJldHVybmVkLgoKDQoFBAQCAQQS
BNEBAgoKDQoFBAQCAQUSBNEBCxEKDQoFBAQCAQESBNEBEhoKDQoFBAQCAQMSBNEBHR4KDQoF
BAQCAQgSBNEBH0cKEAoIBAQCAQicCAASBNEBIEYKwwEKBAQEAgISBNYBAk4atAEgT3B0aW9u
YWwuIElmIHRydWUsIHRoZSByZXR1cm5lZCB0b29scyB3aWxsIGNvbnRhaW4gcmF3IGRlc2Ny
aXB0aW9ucyBhbmQKIHNjaGVtYXMgZGlyZWN0bHkgZnJvbSB0aGUgc2VydmVyLCBieXBhc3Np
bmcgYW55IHN0b3JlZCBwZXJzaXN0ZW5jZQogY29uZmlndXJhdGlvbnMgKG92ZXJyaWRlcy9z
bmFwc2hvdHMpLgoKDQoFBAQCAgUSBNYBAgYKDQoFBAQCAgESBNYBByAKDQoFBAQCAgMSBNYB
IyQKDQoFBAQCAggSBNYBJU0KEAoIBAQCAgicCAASBNYBJkwKdQoCBAUSBtsBAN4BARpnIFJl
c3BvbnNlIG1lc3NhZ2UgZm9yCiBbVG9vbFNlcnZpY2UuUmV0cmlldmVUb29sc11bZ29vZ2xl
LmNsb3VkLmNlcy52MWJldGEuVG9vbFNlcnZpY2UuUmV0cmlldmVUb29sc10uCgoLCgMEBQES
BNsBCB0KTQoEBAUCABIE3QECGho/IFRoZSBsaXN0IG9mIHRvb2xzIHRoYXQgYXJlIGluY2x1
ZGVkIGluIHRoZSBzcGVjaWZpZWQgdG9vbHNldC4KCg0KBQQFAgAEEgTdAQIKCg0KBQQFAgAG
EgTdAQsPCg0KBQQFAgABEgTdARAVCg0KBQQFAgADEgTdARgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest ===
    # Fields for ExecuteToolRequest
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: variables Type: 11 (.google.protobuf.Struct)
    # Field: context Type: 11 (.google.protobuf.Struct)
    # Field: parent Type: 9 ()
    # Field: args Type: 11 (.google.protobuf.Struct)
    # Field: mock_config Type: 11 (.google.cloud.ces.v1beta.MockConfig)

# === Message: Google::Cloud::Ces::V1beta::ToolService::ExecuteToolResponse ===
    # Fields for ExecuteToolResponse
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: response Type: 11 (.google.protobuf.Struct)
    # Field: variables Type: 11 (.google.protobuf.Struct)
    # Field: citations Type: 11 (.google.cloud.ces.v1beta.Citations)
    # Field: google_search_suggestions Type: 11 (.google.cloud.ces.v1beta.GoogleSearchSuggestions)

# === Message: Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaRequest ===
    # Fields for RetrieveToolSchemaRequest
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaResponse ===
    # Fields for RetrieveToolSchemaResponse
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: input_schema Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: output_schema Type: 11 (.google.cloud.ces.v1beta.Schema)

# === Message: Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsRequest ===
    # Fields for RetrieveToolsRequest
    # Field: toolset Type: 9 ()
    # Field: tool_ids Type: 9 ()
    # Field: bypass_persistence_config Type: 8 ()

# === Message: Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsResponse ===
    # Fields for RetrieveToolsResponse
    # Field: tools Type: 11 (.google.cloud.ces.v1beta.Tool)

# === Service Client: Google::Cloud::Ces::V1beta::ToolService::ToolServiceClient ===
package Google::Cloud::Ces::V1beta::ToolService::ToolServiceClient;

=pod

=head2 Service Client: Google::Cloud::Ces::V1beta::ToolService::ToolServiceClient

Client stub representing the remote C<ToolService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ces.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ces.googleapis.com:443' );

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

sub execute_tool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1beta.ToolService',
        method         => 'ExecuteTool',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1beta::ToolService::ExecuteToolResponse',
    });
}

sub retrieve_tool_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1beta.ToolService',
        method         => 'RetrieveToolSchema',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaResponse',
    });
}

sub retrieve_tools {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1beta.ToolService',
        method         => 'RetrieveTools',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::ToolService - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/tool_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::ToolService;

    my $msg = Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest->new({
        tool => $tool,
        toolset_tool => $toolset_tool,
        variables => $variables,
        context => $context,
    });

    # Read or update a field
    my $val = $msg->tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/tool_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest

Request message for
[ToolService.ExecuteTool][google.cloud.ces.v1beta.ToolService.ExecuteTool].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to execute.
Format:
projects/{project}/locations/{location}/apps/{app}/tools/{tool}

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

Optional. The toolset tool to execute. Only one tool should match the
predicate from the toolset. Otherwise, an error will be returned.

=item * C<< $msg->variables() >> / C<< $msg->variables($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The variables that are available for the tool execution.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The
[ToolCallContext](https://docs.cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool/python#environment
for details) to be passed to the Python tool.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the app which the tool/toolset belongs to.
Format: `projects/{project}/locations/{location}/apps/{app}`

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The input parameters and values for the tool in JSON object
format.

=item * C<< $msg->mock_config() >> / C<< $msg->mock_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::SessionService::MockConfig>)

Optional. Mock configuration for the tool execution.
If this field is set, tools that call other tools will be
mocked based on the provided patterns and responses.

=back

=head2 Google::Cloud::Ces::V1beta::ToolService::ExecuteToolResponse

Response message for
[ToolService.ExecuteTool][google.cloud.ces.v1beta.ToolService.ExecuteTool].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The name of the tool that got executed.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

The toolset tool that got executed.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The tool execution result in JSON object format.
Use "output" key to specify tool response and "error" key to specify
error details (if any). If "output" and "error" keys are not specified,
then whole "response" is treated as tool execution result.

=item * C<< $msg->variables() >> / C<< $msg->variables($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The variable values at the end of the tool execution.

=item * C<< $msg->citations() >> / C<< $msg->citations($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::SessionService::Citations>)

Citations that provide the source information for the tool's execution.

=item * C<< $msg->google_search_suggestions() >> / C<< $msg->google_search_suggestions($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::SearchSuggestions::GoogleSearchSuggestions>)

The suggestions returned from Google Search as a result of invoking the
Google Search Tool during the tool execution.

=back

=head2 Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaRequest

Request message for
[ToolService.RetrieveToolSchema][google.cloud.ces.v1beta.ToolService.RetrieveToolSchema].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to retrieve the schema for.
Format:
projects/{project}/locations/{location}/apps/{app}/tools/{tool}

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

Optional. The toolset tool to retrieve the schema for. Only one tool
should match the predicate from the toolset. Otherwise, an error will be
returned.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the app which the tool/toolset belongs to.
Format: `projects/{project}/locations/{location}/apps/{app}`

=back

=head2 Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaResponse

Response message for
[ToolService.RetrieveToolSchema][google.cloud.ces.v1beta.ToolService.RetrieveToolSchema].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The name of the tool that the schema is for.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

The toolset tool that the schema is for.

=item * C<< $msg->input_schema() >> / C<< $msg->input_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

The schema of the tool input parameters.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

The schema of the tool output parameters.

=back

=head2 Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsRequest

Request message for
[ToolService.RetrieveTools][google.cloud.ces.v1beta.ToolService.RetrieveTools].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->toolset() >> / C<< $msg->toolset($value) >>

Type: C<String>

Required. The name of the toolset to retrieve the tools for.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->tool_ids() >> / C<< $msg->tool_ids($value) >>

Type: C<String>

Optional. The identifiers of the tools to retrieve from the toolset.
If empty, all tools in the toolset will be returned.

=item * C<< $msg->bypass_persistence_config() >> / C<< $msg->bypass_persistence_config($value) >>

Type: C<Bool>

Optional. If true, the returned tools will contain raw descriptions and
schemas directly from the server, bypassing any stored persistence
configurations (overrides/snapshots).

=back

=head2 Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsResponse

Response message for
[ToolService.RetrieveTools][google.cloud.ces.v1beta.ToolService.RetrieveTools].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Tool::Tool>)

The list of tools that are included in the specified toolset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::ToolService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
