package Google::Cloud::Agentregistry::V1::Agent;

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
    eval { require Google::Cloud::Agentregistry::V1::Properties };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9hZ2VudC5wcm90bxIdZ29vZ2xlLmNs
b3VkLmFnZW50cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
G2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxouZ29vZ2xlL2Nsb3VkL2FnZW50cmVnaXN0cnkvdjEvcHJvcGVydGllcy5wcm90bxocZ29v
Z2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byK1DAoFQWdlbnQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEh4KCGFnZW50X2lkGAIg
ASgJQgPgQQNSB2FnZW50SWQSHwoIbG9jYXRpb24YBCABKAlCA+BBA1IIbG9jYXRpb24SJgoM
ZGlzcGxheV9uYW1lGAUgASgJQgPgQQNSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAYg
ASgJQgPgQQNSC2Rlc2NyaXB0aW9uEh0KB3ZlcnNpb24YByABKAlCA+BBA1IHdmVyc2lvbhJQ
Cglwcm90b2NvbHMYCCADKAsyLS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5BZ2Vu
dC5Qcm90b2NvbEID4EEDUglwcm90b2NvbHMSRwoGc2tpbGxzGAkgAygLMiouZ29vZ2xlLmNs
b3VkLmFnZW50cmVnaXN0cnkudjEuQWdlbnQuU2tpbGxCA+BBA1IGc2tpbGxzEh0KA3VpZBgK
IAEoCUIL4ozP1wgCCAHgQQNSA3VpZBJACgtjcmVhdGVfdGltZRgLIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgMIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJZCgphdHRy
aWJ1dGVzGA0gAygLMjQuZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuQWdlbnQuQXR0
cmlidXRlc0VudHJ5QgPgQQNSCmF0dHJpYnV0ZXMSQgoEY2FyZBgOIAEoCzIpLmdvb2dsZS5j
bG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLkFnZW50LkNhcmRCA+BBA1IEY2FyZBqPAgoIUHJvdG9j
b2wSSwoEdHlwZRgBIAEoDjIyLmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLkFnZW50
LlByb3RvY29sLlR5cGVCA+BBA1IEdHlwZRIuChBwcm90b2NvbF92ZXJzaW9uGAIgASgJQgPg
QQNSD3Byb3RvY29sVmVyc2lvbhJNCgppbnRlcmZhY2VzGAMgAygLMiguZ29vZ2xlLmNsb3Vk
LmFnZW50cmVnaXN0cnkudjEuSW50ZXJmYWNlQgPgQQNSCmludGVyZmFjZXMiNwoEVHlwZRIU
ChBUWVBFX1VOU1BFQ0lGSUVEEAASDQoJQTJBX0FHRU5UEAESCgoGQ1VTVE9NEAIalgEKBVNr
aWxsEhMKAmlkGAEgASgJQgPgQQNSAmlkEhcKBG5hbWUYAiABKAlCA+BBA1IEbmFtZRIlCgtk
ZXNjcmlwdGlvbhgDIAEoCUID4EEDUgtkZXNjcmlwdGlvbhIXCgR0YWdzGAQgAygJQgPgQQNS
BHRhZ3MSHwoIZXhhbXBsZXMYBSADKAlCA+BBA1IIZXhhbXBsZXMauQEKBENhcmQSRwoEdHlw
ZRgBIAEoDjIuLmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLkFnZW50LkNhcmQuVHlw
ZUID4EEDUgR0eXBlEjYKB2NvbnRlbnQYAiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0
QgPgQQNSB2NvbnRlbnQiMAoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASEgoOQTJBX0FH
RU5UX0NBUkQQARpWCg9BdHRyaWJ1dGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLQoFdmFs
dWUYAiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgV2YWx1ZToCOAE6xwHqQcMBCiJh
Z2VudHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL0FnZW50EjZwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0SVnByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9haUFwcGxpY2F0aW9ucy97YWlfYXBwbGljYXRpb259
L2FnZW50cy97YWdlbnR9KgZhZ2VudHMyBWFnZW50Qt0BCiFjb20uZ29vZ2xlLmNsb3VkLmFn
ZW50cmVnaXN0cnkudjFCCkFnZW50UHJvdG9QAVpHY2xvdWQuZ29vZ2xlLmNvbS9nby9hZ2Vu
dHJlZ2lzdHJ5L2FwaXYxL2FnZW50cmVnaXN0cnlwYjthZ2VudHJlZ2lzdHJ5cGKqAh1Hb29n
bGUuQ2xvdWQuQWdlbnRSZWdpc3RyeS5WMcoCHUdvb2dsZVxDbG91ZFxBZ2VudFJlZ2lzdHJ5
XFYx6gIgR29vZ2xlOjpDbG91ZDo6QWdlbnRSZWdpc3RyeTo6VjFKhzAKBxIFDgCoAQEKvAQK
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
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAKQoJ
CgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAOAoJCgIDBBIDFgAmCgkKAgMFEgMXACkK
CAoBCBIDGQA6CgkKAgglEgMZADoKCAoBCBIDGgBeCgkKAggLEgMaAF4KCAoBCBIDGwAiCgkK
AggKEgMbACIKCAoBCBIDHAArCgkKAggIEgMcACsKCAoBCBIDHQA6CgkKAggBEgMdADoKCAoB
CBIDHgA6CgkKAggpEgMeADoKCAoBCBIDHwA5CgkKAggtEgMfADkKVwoCBAASBSMAqAEBGkog
UmVwcmVzZW50cyBhbiBBZ2VudC4KICJBMkEiIGJlbG93IHJlZmVycyB0byB0aGUgQWdlbnQt
dG8tQWdlbnQgcHJvdG9jb2wuCgoKCgMEAAESAyMIDQoLCgMEAAcSBCQCKgQKDQoFBAAHnQgS
BCQCKgQKNAoEBAADABIELQJFAxomIFJlcHJlc2VudHMgdGhlIHByb3RvY29sIG9mIGFuIEFn
ZW50LgoKDAoFBAADAAESAy0KEgorCgYEAAMABAASBC8EOQUaGyBUaGUgdHlwZSBvZiB0aGUg
cHJvdG9jb2wuCgoOCgcEAAMABAABEgMvCQ0KJAoIBAADAAQAAgASAzEGGxoTIFVuc3BlY2lm
aWVkIHR5cGUuCgoQCgkEAAMABAACAAESAzEGFgoQCgkEAAMABAACAAISAzEZGgpZCggEAAMA
BAACARIDNQYUGkggVGhlIGludGVyZmFjZXMgcG9pbnQgdG8gYW4gQTJBIEFnZW50IGZvbGxv
d2luZyB0aGUgQTJBCiBzcGVjaWZpY2F0aW9uLgoKEAoJBAADAAQAAgEBEgM1Bg8KEAoJBAAD
AAQAAgECEgM1EhMKPwoIBAADAAQAAgISAzgGERouIEFnZW50IGRvZXMgbm90IGZvbGxvdyBh
bnkgc3RhbmRhcmQgcHJvdG9jb2wuCgoQCgkEAAMABAACAgESAzgGDAoQCgkEAAMABAACAgIS
AzgPEAo3CgYEAAMAAgASAzwEPhooIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0aGUgcHJv
dG9jb2wuCgoOCgcEAAMAAgAGEgM8BAgKDgoHBAADAAIAARIDPAkNCg4KBwQAAwACAAMSAzwQ
EQoOCgcEAAMAAgAIEgM8Ej0KEQoKBAADAAIACJwIABIDPBM8CmQKBgQAAwACARIDQARMGlUg
T3V0cHV0IG9ubHkuIFRoZSB2ZXJzaW9uIG9mIHRoZSBwcm90b2NvbCwgZm9yIGV4YW1wbGUs
IHRoZSBBMkEgQWdlbnQgQ2FyZAogdmVyc2lvbi4KCg4KBwQAAwACAQUSA0AECgoOCgcEAAMA
AgEBEgNACxsKDgoHBAADAAIBAxIDQB4fCg4KBwQAAwACAQgSA0AgSwoRCgoEAAMAAgEInAgA
EgNAIUoKRAoGBAADAAICEgRDBEQ0GjQgT3V0cHV0IG9ubHkuIFRoZSBjb25uZWN0aW9uIGRl
dGFpbHMgZm9yIHRoZSBBZ2VudC4KCg4KBwQAAwACAgQSA0MEDAoOCgcEAAMAAgIGEgNDDRYK
DgoHBAADAAICARIDQxchCg4KBwQAAwACAgMSA0MkJQoOCgcEAAMAAgIIEgNECDMKEQoKBAAD
AAICCJwIABIDRAkyCjIKBAQAAwESBEgCVwMaJCBSZXByZXNlbnRzIHRoZSBza2lsbHMgb2Yg
YW4gQWdlbnQuCgoMCgUEAAMBARIDSAoPCkgKBgQAAwECABIDSgQ+GjkgT3V0cHV0IG9ubHku
IEEgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBhZ2VudCdzIHNraWxsLgoKDgoHBAADAQIA
BRIDSgQKCg4KBwQAAwECAAESA0oLDQoOCgcEAAMBAgADEgNKEBEKDgoHBAADAQIACBIDShI9
ChEKCgQAAwECAAicCAASA0oTPApKCgYEAAMBAgESA00EQBo7IE91dHB1dCBvbmx5LiBBIGh1
bWFuLXJlYWRhYmxlIG5hbWUgZm9yIHRoZSBhZ2VudCdzIHNraWxsLgoKDgoHBAADAQIBBRID
TQQKCg4KBwQAAwECAQESA00LDwoOCgcEAAMBAgEDEgNNEhMKDgoHBAADAQIBCBIDTRQ/ChEK
CgQAAwECAQicCAASA00VPgpHCgYEAAMBAgISA1AERxo4IE91dHB1dCBvbmx5LiBBIG1vcmUg
ZGV0YWlsZWQgZGVzY3JpcHRpb24gb2YgdGhlIHNraWxsLgoKDgoHBAADAQICBRIDUAQKCg4K
BwQAAwECAgESA1ALFgoOCgcEAAMBAgIDEgNQGRoKDgoHBAADAQICCBIDUBtGChEKCgQAAwEC
AgicCAASA1AcRQo8CgYEAAMBAgMSA1MESRotIE91dHB1dCBvbmx5LiBLZXl3b3JkcyBkZXNj
cmliaW5nIHRoZSBza2lsbC4KCg4KBwQAAwECAwQSA1MEDAoOCgcEAAMBAgMFEgNTDRMKDgoH
BAADAQIDARIDUxQYCg4KBwQAAwECAwMSA1MbHAoOCgcEAAMBAgMIEgNTHUgKEQoKBAADAQID
CJwIABIDUx5HClEKBgQAAwECBBIDVgRNGkIgT3V0cHV0IG9ubHkuIEV4YW1wbGUgcHJvbXB0
cyBvciBzY2VuYXJpb3MgdGhpcyBza2lsbCBjYW4gaGFuZGxlLgoKDgoHBAADAQIEBBIDVgQM
Cg4KBwQAAwECBAUSA1YNEwoOCgcEAAMBAgQBEgNWFBwKDgoHBAADAQIEAxIDVh8gCg4KBwQA
AwECBAgSA1YhTAoRCgoEAAMBAgQInAgAEgNWIksKUAoEBAADAhIEWgJqAxpCIEZ1bGwgQWdl
bnQgQ2FyZCBwYXlsb2FkLCBvZnRlbiBvYnRhaW5lZCBmcm9tIHRoZSBBMkEgQWdlbnQgQ2Fy
ZC4KCgwKBQQAAwIBEgNaCg4KOAoGBAADAgQAEgRcBGIFGiggUmVwcmVzZW50cyB0aGUgdHlw
ZSBvZiB0aGUgYWdlbnQgY2FyZC4KCg4KBwQAAwIEAAESA1wJDQokCggEAAMCBAACABIDXgYb
GhMgVW5zcGVjaWZpZWQgdHlwZS4KChAKCQQAAwIEAAIAARIDXgYWChAKCQQAAwIEAAIAAhID
XhkaCkAKCAQAAwIEAAIBEgNhBhkaLyBJbmRpY2F0ZXMgdGhhdCB0aGUgY2FyZCBpcyBhbiBB
MkEgQWdlbnQgQ2FyZC4KChAKCQQAAwIEAAIBARIDYQYUChAKCQQAAwIEAAIBAhIDYRcYCjUK
BgQAAwICABIDZQQ+GiYgT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIGFnZW50IGNhcmQuCgoO
CgcEAAMCAgAGEgNlBAgKDgoHBAADAgIAARIDZQkNCg4KBwQAAwICAAMSA2UQEQoOCgcEAAMC
AgAIEgNlEj0KEQoKBAADAgIACJwIABIDZRM8Cj0KBgQAAwICARIEaARpNBotIE91dHB1dCBv
bmx5LiBUaGUgY29udGVudCBvZiB0aGUgYWdlbnQgY2FyZC4KCg4KBwQAAwICAQYSA2gEGgoO
CgcEAAMCAgEBEgNoGyIKDgoHBAADAgIBAxIDaCUmCg4KBwQAAwICAQgSA2kIMwoRCgoEAAMC
AgEInAgAEgNpCTIKfAoEBAACABIDbgI9Gm8gSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5h
bWUgb2YgYW4gQWdlbnQuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH1gLgoKDAoFBAACAAUSA24CCAoMCgUEAAIAARID
bgkNCgwKBQQAAgADEgNuEBEKDAoFBAACAAgSA24SPAoPCggEAAIACJwIABIDbhM7CkwKBAQA
AgESA3ECQho/IE91dHB1dCBvbmx5LiBBIHN0YWJsZSwgZ2xvYmFsbHkgdW5pcXVlIGlkZW50
aWZpZXIgZm9yIGFnZW50cy4KCgwKBQQAAgEFEgNxAggKDAoFBAACAQESA3EJEQoMCgUEAAIB
AxIDcRQVCgwKBQQAAgEIEgNxFkEKDwoIBAACAQicCAASA3EXQAqHAQoEBAACAhIDdQJCGnog
T3V0cHV0IG9ubHkuIFRoZSBsb2NhdGlvbiB3aGVyZSBhZ2VudCBpcyBob3N0ZWQuIFRoZSB2
YWx1ZSBpcyBkZWZpbmVkIGJ5CiB0aGUgaG9zdGluZyBlbnZpcm9ubWVudCAoaS5lLiBjbG91
ZCBwcm92aWRlcikuCgoMCgUEAAICBRIDdQIICgwKBQQAAgIBEgN1CREKDAoFBAACAgMSA3UU
FQoMCgUEAAICCBIDdRZBCg8KCAQAAgIInAgAEgN1F0AKYwoEBAACAxIDeQJGGlYgT3V0cHV0
IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGFnZW50LCBvZnRlbiBvYnRhaW5lZCBm
cm9tIHRoZSBBMkEKIEFnZW50IENhcmQuCgoMCgUEAAIDBRIDeQIICgwKBQQAAgMBEgN5CRUK
DAoFBAACAwMSA3kYGQoMCgUEAAIDCBIDeRpFCg8KCAQAAgMInAgAEgN5G0QKigEKBAQAAgQS
A30CRRp9IE91dHB1dCBvbmx5LiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIEFnZW50LCBvZnRl
biBvYnRhaW5lZCBmcm9tIHRoZSBBMkEKIEFnZW50IENhcmQuIEVtcHR5IGlmIEFnZW50IENh
cmQgaGFzIG5vIGRlc2NyaXB0aW9uLgoKDAoFBAACBAUSA30CCAoMCgUEAAIEARIDfQkUCgwK
BQQAAgQDEgN9FxgKDAoFBAACBAgSA30ZRAoPCggEAAIECJwIABIDfRpDCqEBCgQEAAIFEgSB
AQJBGpIBIE91dHB1dCBvbmx5LiBUaGUgdmVyc2lvbiBvZiB0aGUgQWdlbnQsIG9mdGVuIG9i
dGFpbmVkIGZyb20gdGhlIEEyQSBBZ2VudAogQ2FyZC4gRW1wdHkgaWYgQWdlbnQgQ2FyZCBo
YXMgbm8gdmVyc2lvbiBvciBhZ2VudCBpcyBub3QgYW4gQTJBIEFnZW50LgoKDQoFBAACBQUS
BIEBAggKDQoFBAACBQESBIEBCRAKDQoFBAACBQMSBIEBExQKDQoFBAACBQgSBIEBFUAKEAoI
BAACBQicCAASBIEBFj8KQgoEBAACBhIEhAECTho0IE91dHB1dCBvbmx5LiBUaGUgY29ubmVj
dGlvbiBkZXRhaWxzIGZvciB0aGUgQWdlbnQuCgoNCgUEAAIGBBIEhAECCgoNCgUEAAIGBhIE
hAELEwoNCgUEAAIGARIEhAEUHQoNCgUEAAIGAxIEhAEgIQoNCgUEAAIGCBIEhAEiTQoQCggE
AAIGCJwIABIEhAEjTAphCgQEAAIHEgSIAQJIGlMgT3V0cHV0IG9ubHkuIFNraWxscyB0aGUg
YWdlbnQgcG9zc2Vzc2VzLCBvZnRlbiBvYnRhaW5lZCBmcm9tIHRoZSBBMkEgQWdlbnQKIENh
cmQuCgoNCgUEAAIHBBIEiAECCgoNCgUEAAIHBhIEiAELEAoNCgUEAAIHARIEiAERFwoNCgUE
AAIHAxIEiAEaGwoNCgUEAAIHCBIEiAEcRwoQCggEAAIHCJwIABIEiAEdRgpNCgQEAAIIEgaL
AQKOAQQaPSBPdXRwdXQgb25seS4gQSB1bml2ZXJzYWxseSB1bmlxdWUgaWRlbnRpZmllciBm
b3IgdGhlIEFnZW50LgoKDQoFBAACCAUSBIsBAggKDQoFBAACCAESBIsBCQwKDQoFBAACCAMS
BIsBDxEKDwoFBAACCAgSBosBEo4BAwoTCgsEAAIICMzx+YoBARIEjAEEKgoQCggEAAIICJwI
ABIEjQEELQorCgQEAAIJEgaRAQKSATIaGyBPdXRwdXQgb25seS4gQ3JlYXRlIHRpbWUuCgoN
CgUEAAIJBhIEkQECGwoNCgUEAAIJARIEkQEcJwoNCgUEAAIJAxIEkQEqLAoNCgUEAAIJCBIE
kgEGMQoQCggEAAIJCJwIABIEkgEHMAorCgQEAAIKEgaVAQKWATIaGyBPdXRwdXQgb25seS4g
VXBkYXRlIHRpbWUuCgoNCgUEAAIKBhIElQECGwoNCgUEAAIKARIElQEcJwoNCgUEAAIKAxIE
lQEqLAoNCgUEAAIKCBIElgEGMQoQCggEAAIKCJwIABIElgEHMArDBAoEBAACCxIGowECpAEy
GrIEIE91dHB1dCBvbmx5LiBBdHRyaWJ1dGVzIG9mIHRoZSBBZ2VudC4KIFZhbGlkIHZhbHVl
czoKCiAgKiBgYWdlbnRyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9zeXN0ZW0vRnJhbWV3b3Jr
YDogeyJmcmFtZXdvcmsiOgogICJnb29nbGUtYWRrIn0gLSB0aGUgYWdlbnQgZnJhbWV3b3Jr
IHVzZWQgdG8gZGV2ZWxvcCB0aGUgQWdlbnQuIEV4YW1wbGUKICB2YWx1ZXM6ICJnb29nbGUt
YWRrIiwgImxhbmdjaGFpbiIsICJjdXN0b20iLgogICogYGFnZW50cmVnaXN0cnkuZ29vZ2xl
YXBpcy5jb20vc3lzdGVtL1J1bnRpbWVJZGVudGl0eWA6IHsicHJpbmNpcGFsIjoKICAicHJp
bmNpcGFsOi8vLi4uIn0gLSB0aGUgcnVudGltZSBpZGVudGl0eSBhc3NvY2lhdGVkIHdpdGgg
dGhlIEFnZW50LgogICogYGFnZW50cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vc3lzdGVtL1J1
bnRpbWVSZWZlcmVuY2VgOiB7InVyaSI6ICIvLy4uLiJ9CiAgLSB0aGUgVVJJIG9mIHRoZSB1
bmRlcmx5aW5nIHJlc291cmNlIGhvc3RpbmcgdGhlIEFnZW50LCBmb3IKICBleGFtcGxlLCB0
aGUgUmVhc29uaW5nIEVuZ2luZSBVUkkuCgoNCgUEAAILBhIEowECJQoNCgUEAAILARIEowEm
MAoNCgUEAAILAxIEowEzNQoNCgUEAAILCBIEpAEGMQoQCggEAAILCJwIABIEpAEHMApFCgQE
AAIMEgSnAQI9GjcgT3V0cHV0IG9ubHkuIEZ1bGwgQWdlbnQgQ2FyZCBwYXlsb2FkLCB3aGVu
IGF2YWlsYWJsZS4KCg0KBQQAAgwGEgSnAQIGCg0KBQQAAgwBEgSnAQcLCg0KBQQAAgwDEgSn
AQ4QCg0KBQQAAgwIEgSnARE8ChAKCAQAAgwInAgAEgSnARI7YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Agent::Agent ===
    # Fields for Agent
    # Field: name Type: 9 ()
    # Field: agent_id Type: 9 ()
    # Field: location Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: version Type: 9 ()
    # Field: protocols Type: 11 (.google.cloud.agentregistry.v1.Agent.Protocol)
    # Field: skills Type: 11 (.google.cloud.agentregistry.v1.Agent.Skill)
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: attributes Type: 11 (.google.cloud.agentregistry.v1.Agent.AttributesEntry)
    # Field: card Type: 11 (.google.cloud.agentregistry.v1.Agent.Card)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Agent - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Agent;

    my $msg = Google::Cloud::Agentregistry::V1::Agent::Agent->new({
        name => $name,
        agent_id => $agent_id,
        location => $location,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Agent::Agent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Agent::Agent

Represents an Agent.
"A2A" below refers to the Agent-to-Agent protocol.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of an Agent.
Format: `projects/{project}/locations/{location}/agents/{agent}`.

=item * C<< $msg->agent_id() >> / C<< $msg->agent_id($value) >>

Type: C<String>

Output only. A stable, globally unique identifier for agents.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Output only. The location where agent is hosted. The value is defined by
the hosting environment (i.e. cloud provider).

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the agent, often obtained from the A2A
Agent Card.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the Agent, often obtained from the A2A
Agent Card. Empty if Agent Card has no description.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Output only. The version of the Agent, often obtained from the A2A Agent
Card. Empty if Agent Card has no version or agent is not an A2A Agent.

=item * C<< $msg->protocols() >> / C<< $msg->protocols($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Agent::Agent::Protocol>)

Output only. The connection details for the Agent.

=item * C<< $msg->skills() >> / C<< $msg->skills($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Agent::Agent::Skill>)

Output only. Skills the agent possesses, often obtained from the A2A Agent
Card.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A universally unique identifier for the Agent.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Agent::Agent::AttributesEntry>)

Output only. Attributes of the Agent.
Valid values:

 * `agentregistry.googleapis.com/system/Framework`: {"framework":
 "google-adk"} - the agent framework used to develop the Agent. Example
 values: "google-adk", "langchain", "custom".
 * `agentregistry.googleapis.com/system/RuntimeIdentity`: {"principal":
 "principal://..."} - the runtime identity associated with the Agent.
 * `agentregistry.googleapis.com/system/RuntimeReference`: {"uri": "//..."}
 - the URI of the underlying resource hosting the Agent, for
 example, the Reasoning Engine URI.

=item * C<< $msg->card() >> / C<< $msg->card($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Agent::Agent::Card>)

Output only. Full Agent Card payload, when available.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Agent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
