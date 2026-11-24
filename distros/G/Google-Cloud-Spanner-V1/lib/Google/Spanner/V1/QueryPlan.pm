package Google::Spanner::V1::QueryPlan;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvc3Bhbm5lci92MS9xdWVyeV9wbGFuLnByb3RvEhFnb29nbGUuc3Bhbm5lci52
MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0
cnVjdC5wcm90byKOBgoIUGxhbk5vZGUSFAoFaW5kZXgYASABKAVSBWluZGV4EjQKBGtpbmQY
AiABKA4yIC5nb29nbGUuc3Bhbm5lci52MS5QbGFuTm9kZS5LaW5kUgRraW5kEiEKDGRpc3Bs
YXlfbmFtZRgDIAEoCVILZGlzcGxheU5hbWUSRgoLY2hpbGRfbGlua3MYBCADKAsyJS5nb29n
bGUuc3Bhbm5lci52MS5QbGFuTm9kZS5DaGlsZExpbmtSCmNoaWxkTGlua3MSYgoUc2hvcnRf
cmVwcmVzZW50YXRpb24YBSABKAsyLy5nb29nbGUuc3Bhbm5lci52MS5QbGFuTm9kZS5TaG9y
dFJlcHJlc2VudGF0aW9uUhNzaG9ydFJlcHJlc2VudGF0aW9uEjMKCG1ldGFkYXRhGAYgASgL
MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIIbWV0YWRhdGESQAoPZXhlY3V0aW9uX3N0YXRz
GAcgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIOZXhlY3V0aW9uU3RhdHMaXAoJQ2hp
bGRMaW5rEh8KC2NoaWxkX2luZGV4GAEgASgFUgpjaGlsZEluZGV4EhIKBHR5cGUYAiABKAlS
BHR5cGUSGgoIdmFyaWFibGUYAyABKAlSCHZhcmlhYmxlGtcBChNTaG9ydFJlcHJlc2VudGF0
aW9uEiAKC2Rlc2NyaXB0aW9uGAEgASgJUgtkZXNjcmlwdGlvbhJfCgpzdWJxdWVyaWVzGAIg
AygLMj8uZ29vZ2xlLnNwYW5uZXIudjEuUGxhbk5vZGUuU2hvcnRSZXByZXNlbnRhdGlvbi5T
dWJxdWVyaWVzRW50cnlSCnN1YnF1ZXJpZXMaPQoPU3VicXVlcmllc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgFUgV2YWx1ZToCOAEiOAoES2luZBIUChBLSU5EX1VO
U1BFQ0lGSUVEEAASDgoKUkVMQVRJT05BTBABEgoKBlNDQUxBUhACIskBChJRdWVyeUFkdmlz
b3JSZXN1bHQSWQoMaW5kZXhfYWR2aWNlGAEgAygLMjEuZ29vZ2xlLnNwYW5uZXIudjEuUXVl
cnlBZHZpc29yUmVzdWx0LkluZGV4QWR2aWNlQgPgQQFSC2luZGV4QWR2aWNlGlgKC0luZGV4
QWR2aWNlEhUKA2RkbBgBIAMoCUID4EEBUgNkZGwSMgoSaW1wcm92ZW1lbnRfZmFjdG9yGAIg
ASgBQgPgQQFSEWltcHJvdmVtZW50RmFjdG9yIpYBCglRdWVyeVBsYW4SOgoKcGxhbl9ub2Rl
cxgBIAMoCzIbLmdvb2dsZS5zcGFubmVyLnYxLlBsYW5Ob2RlUglwbGFuTm9kZXMSTQoMcXVl
cnlfYWR2aWNlGAIgASgLMiUuZ29vZ2xlLnNwYW5uZXIudjEuUXVlcnlBZHZpc29yUmVzdWx0
QgPgQQFSC3F1ZXJ5QWR2aWNlQrEBChVjb20uZ29vZ2xlLnNwYW5uZXIudjFCDlF1ZXJ5UGxh
blByb3RvUAFaNWNsb3VkLmdvb2dsZS5jb20vZ28vc3Bhbm5lci9hcGl2MS9zcGFubmVycGI7
c3Bhbm5lcnBiqgIXR29vZ2xlLkNsb3VkLlNwYW5uZXIuVjHKAhdHb29nbGVcQ2xvdWRcU3Bh
bm5lclxWMeoCGkdvb2dsZTo6Q2xvdWQ6OlNwYW5uZXI6OlYxStMyCgcSBQ4AmwEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAaCgkKAgMAEgMSACkKCQoC
AwESAxMAJgoICgEIEgMVADQKCQoCCCUSAxUANAoICgEIEgMWAEwKCQoCCAsSAxYATAoICgEI
EgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC8KCQoCCAgSAxgALwoICgEIEgMZAC4KCQoCCAES
AxkALgoICgEIEgMaADQKCQoCCCkSAxoANAoICgEIEgMbADMKCQoCCC0SAxsAMwp4CgIEABIE
HwB7ARpsIE5vZGUgaW5mb3JtYXRpb24gZm9yIG5vZGVzIGFwcGVhcmluZyBpbiBhCiBbUXVl
cnlQbGFuLnBsYW5fbm9kZXNdW2dvb2dsZS5zcGFubmVyLnYxLlF1ZXJ5UGxhbi5wbGFuX25v
ZGVzXS4KCgoKAwQAARIDHwgQCp0BCgQEAAQAEgQiAjADGo4BIFRoZSBraW5kIG9mIFtQbGFu
Tm9kZV1bZ29vZ2xlLnNwYW5uZXIudjEuUGxhbk5vZGVdLiBEaXN0aW5ndWlzaGVzIGJldHdl
ZW4KIHRoZSB0d28gZGlmZmVyZW50IGtpbmRzIG9mIG5vZGVzIHRoYXQgY2FuIGFwcGVhciBp
biBhIHF1ZXJ5IHBsYW4uCgoMCgUEAAQAARIDIgcLCh8KBgQABAACABIDJAQZGhAgTm90IHNw
ZWNpZmllZC4KCg4KBwQABAACAAESAyQEFAoOCgcEAAQAAgACEgMkFxgK5QEKBgQABAACARID
KQQTGtUBIERlbm90ZXMgYSBSZWxhdGlvbmFsIG9wZXJhdG9yIG5vZGUgaW4gdGhlIGV4cHJl
c3Npb24gdHJlZS4gUmVsYXRpb25hbAogb3BlcmF0b3JzIHJlcHJlc2VudCBpdGVyYXRpdmUg
cHJvY2Vzc2luZyBvZiByb3dzIGR1cmluZyBxdWVyeSBleGVjdXRpb24uCiBGb3IgZXhhbXBs
ZSwgYSBgVGFibGVTY2FuYCBvcGVyYXRpb24gdGhhdCByZWFkcyByb3dzIGZyb20gYSB0YWJs
ZS4KCg4KBwQABAACAQESAykEDgoOCgcEAAQAAgECEgMpERIK9wEKBgQABAACAhIDLwQPGucB
IERlbm90ZXMgYSBTY2FsYXIgbm9kZSBpbiB0aGUgZXhwcmVzc2lvbiB0cmVlLiBTY2FsYXIg
bm9kZXMgcmVwcmVzZW50CiBub24taXRlcmFibGUgZW50aXRpZXMgaW4gdGhlIHF1ZXJ5IHBs
YW4uIEZvciBleGFtcGxlLCBjb25zdGFudHMgb3IKIGFyaXRobWV0aWMgb3BlcmF0b3JzIGFw
cGVhcmluZyBpbnNpZGUgcHJlZGljYXRlIGV4cHJlc3Npb25zIG9yIHJlZmVyZW5jZXMKIHRv
IGNvbHVtbiBuYW1lcy4KCg4KBwQABAACAgESAy8ECgoOCgcEAAQAAgICEgMvDQ4KfAoEBAAD
ABIENAJHAxpuIE1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBhIHBhcmVudC1jaGlsZCByZWxh
dGlvbnNoaXAgYXBwZWFyaW5nIGluIGEKIFtQbGFuTm9kZV1bZ29vZ2xlLnNwYW5uZXIudjEu
UGxhbk5vZGVdLgoKDAoFBAADAAESAzQKEwozCgYEAAMAAgASAzYEGhokIFRoZSBub2RlIHRv
IHdoaWNoIHRoZSBsaW5rIHBvaW50cy4KCg4KBwQAAwACAAUSAzYECQoOCgcEAAMAAgABEgM2
ChUKDgoHBAADAAIAAxIDNhgZCoQCCgYEAAMAAgESAzwEFBr0ASBUaGUgdHlwZSBvZiB0aGUg
bGluay4gRm9yIGV4YW1wbGUsIGluIEhhc2ggSm9pbnMgdGhpcyBjb3VsZCBiZSB1c2VkIHRv
CiBkaXN0aW5ndWlzaCBiZXR3ZWVuIHRoZSBidWlsZCBjaGlsZCBhbmQgdGhlIHByb2JlIGNo
aWxkLCBvciBpbiB0aGUgY2FzZQogb2YgdGhlIGNoaWxkIGJlaW5nIGFuIG91dHB1dCB2YXJp
YWJsZSwgdG8gcmVwcmVzZW50IHRoZSB0YWcgYXNzb2NpYXRlZAogd2l0aCB0aGUgb3V0cHV0
IHZhcmlhYmxlLgoKDgoHBAADAAIBBRIDPAQKCg4KBwQAAwACAQESAzwLDwoOCgcEAAMAAgED
EgM8EhMK/AMKBgQAAwACAhIDRgQYGuwDIE9ubHkgcHJlc2VudCBpZiB0aGUgY2hpbGQgbm9k
ZSBpcwogW1NDQUxBUl1bZ29vZ2xlLnNwYW5uZXIudjEuUGxhbk5vZGUuS2luZC5TQ0FMQVJd
IGFuZCBjb3JyZXNwb25kcyB0byBhbgogb3V0cHV0IHZhcmlhYmxlIG9mIHRoZSBwYXJlbnQg
bm9kZS4gVGhlIGZpZWxkIGNhcnJpZXMgdGhlIG5hbWUgb2YgdGhlCiBvdXRwdXQgdmFyaWFi
bGUuIEZvciBleGFtcGxlLCBhIGBUYWJsZVNjYW5gIG9wZXJhdG9yIHRoYXQgcmVhZHMgcm93
cyBmcm9tCiBhIHRhYmxlIHdpbGwgaGF2ZSBjaGlsZCBsaW5rcyB0byB0aGUgYFNDQUxBUmAg
bm9kZXMgcmVwcmVzZW50aW5nIHRoZQogb3V0cHV0IHZhcmlhYmxlcyBjcmVhdGVkIGZvciBl
YWNoIGNvbHVtbiB0aGF0IGlzIHJlYWQgYnkgdGhlIG9wZXJhdG9yLgogVGhlIGNvcnJlc3Bv
bmRpbmcgYHZhcmlhYmxlYCBmaWVsZHMgd2lsbCBiZSBzZXQgdG8gdGhlIHZhcmlhYmxlIG5h
bWVzCiBhc3NpZ25lZCB0byB0aGUgY29sdW1ucy4KCg4KBwQAAwACAgUSA0YECgoOCgcEAAMA
AgIBEgNGCxMKDgoHBAADAAICAxIDRhYXCokBCgQEAAMBEgRLAlUDGnsgQ29uZGVuc2VkIHJl
cHJlc2VudGF0aW9uIG9mIGEgbm9kZSBhbmQgaXRzIHN1YnRyZWUuIE9ubHkgcHJlc2VudCBm
b3IKIGBTQ0FMQVJgIFtQbGFuTm9kZShzKV1bZ29vZ2xlLnNwYW5uZXIudjEuUGxhbk5vZGVd
LgoKDAoFBAADAQESA0sKHQpXCgYEAAMBAgASA00EGxpIIEEgc3RyaW5nIHJlcHJlc2VudGF0
aW9uIG9mIHRoZSBleHByZXNzaW9uIHN1YnRyZWUgcm9vdGVkIGF0IHRoaXMgbm9kZS4KCg4K
BwQAAwECAAUSA00ECgoOCgcEAAMBAgABEgNNCxYKDgoHBAADAQIAAxIDTRkaCrQCCgYEAAMB
AgESA1QEJhqkAiBBIG1hcHBpbmcgb2YgKHN1YnF1ZXJ5IHZhcmlhYmxlIG5hbWUpIC0+IChz
dWJxdWVyeSBub2RlIGlkKSBmb3IgY2FzZXMKIHdoZXJlIHRoZSBgZGVzY3JpcHRpb25gIHN0
cmluZyBvZiB0aGlzIG5vZGUgcmVmZXJlbmNlcyBhIGBTQ0FMQVJgCiBzdWJxdWVyeSBjb250
YWluZWQgaW4gdGhlIGV4cHJlc3Npb24gc3VidHJlZSByb290ZWQgYXQgdGhpcyBub2RlLiBU
aGUKIHJlZmVyZW5jZWQgYFNDQUxBUmAgc3VicXVlcnkgbWF5IG5vdCBuZWNlc3NhcmlseSBi
ZSBhIGRpcmVjdCBjaGlsZCBvZgogdGhpcyBub2RlLgoKDgoHBAADAQIBBhIDVAQWCg4KBwQA
AwECAQESA1QXIQoOCgcEAAMBAgEDEgNUJCUKXgoEBAACABIDWQISGlEgVGhlIGBQbGFuTm9k
ZWAncyBpbmRleCBpbiBbbm9kZQogbGlzdF1bZ29vZ2xlLnNwYW5uZXIudjEuUXVlcnlQbGFu
LnBsYW5fbm9kZXNdLgoKDAoFBAACAAUSA1kCBwoMCgUEAAIAARIDWQgNCgwKBQQAAgADEgNZ
EBEKxQIKBAQAAgESA2ACEBq3AiBVc2VkIHRvIGRldGVybWluZSB0aGUgdHlwZSBvZiBub2Rl
LiBNYXkgYmUgbmVlZGVkIGZvciB2aXN1YWxpemluZwogZGlmZmVyZW50IGtpbmRzIG9mIG5v
ZGVzIGRpZmZlcmVudGx5LiBGb3IgZXhhbXBsZSwgSWYgdGhlIG5vZGUgaXMgYQogW1NDQUxB
Ul1bZ29vZ2xlLnNwYW5uZXIudjEuUGxhbk5vZGUuS2luZC5TQ0FMQVJdIG5vZGUsIGl0IHdp
bGwgaGF2ZSBhCiBjb25kZW5zZWQgcmVwcmVzZW50YXRpb24gd2hpY2ggY2FuIGJlIHVzZWQg
dG8gZGlyZWN0bHkgZW1iZWQgYSBkZXNjcmlwdGlvbgogb2YgdGhlIG5vZGUgaW4gaXRzIHBh
cmVudC4KCgwKBQQAAgEGEgNgAgYKDAoFBAACAQESA2AHCwoMCgUEAAIBAxIDYA4PCi0KBAQA
AgISA2MCGhogIFRoZSBkaXNwbGF5IG5hbWUgZm9yIHRoZSBub2RlLgoKDAoFBAACAgUSA2MC
CAoMCgUEAAICARIDYwkVCgwKBQQAAgIDEgNjGBkKUgoEBAACAxIDZgIlGkUgTGlzdCBvZiBj
aGlsZCBub2RlIGBpbmRleGBlcyBhbmQgdGhlaXIgcmVsYXRpb25zaGlwIHRvIHRoaXMgcGFy
ZW50LgoKDAoFBAACAwQSA2YCCgoMCgUEAAIDBhIDZgsUCgwKBQQAAgMBEgNmFSAKDAoFBAAC
AwMSA2YjJApkCgQEAAIEEgNqAi8aVyBDb25kZW5zZWQgcmVwcmVzZW50YXRpb24gZm9yCiBb
U0NBTEFSXVtnb29nbGUuc3Bhbm5lci52MS5QbGFuTm9kZS5LaW5kLlNDQUxBUl0gbm9kZXMu
CgoMCgUEAAIEBhIDagIVCgwKBQQAAgQBEgNqFioKDAoFBAACBAMSA2otLgqQAgoEBAACBRID
dAImGoICIEF0dHJpYnV0ZXMgcmVsZXZhbnQgdG8gdGhlIG5vZGUgY29udGFpbmVkIGluIGEg
Z3JvdXAgb2Yga2V5LXZhbHVlIHBhaXJzLgogRm9yIGV4YW1wbGUsIGEgUGFyYW1ldGVyIFJl
ZmVyZW5jZSBub2RlIGNvdWxkIGhhdmUgdGhlIGZvbGxvd2luZwogaW5mb3JtYXRpb24gaW4g
aXRzIG1ldGFkYXRhOgoKICAgICB7CiAgICAgICAicGFyYW1ldGVyX3JlZmVyZW5jZSI6ICJw
YXJhbTEiLAogICAgICAgInBhcmFtZXRlcl90eXBlIjogImFycmF5IgogICAgIH0KCgwKBQQA
AgUGEgN0AhgKDAoFBAACBQESA3QZIQoMCgUEAAIFAxIDdCQlCv4BCgQEAAIGEgN6Ai0a8AEg
VGhlIGV4ZWN1dGlvbiBzdGF0aXN0aWNzIGFzc29jaWF0ZWQgd2l0aCB0aGUgbm9kZSwgY29u
dGFpbmVkIGluIGEgZ3JvdXAgb2YKIGtleS12YWx1ZSBwYWlycy4gT25seSBwcmVzZW50IGlm
IHRoZSBwbGFuIHdhcyByZXR1cm5lZCBhcyBhIHJlc3VsdCBvZiBhCiBwcm9maWxlIHF1ZXJ5
LiBGb3IgZXhhbXBsZSwgbnVtYmVyIG9mIGV4ZWN1dGlvbnMsIG51bWJlciBvZiByb3dzL3Rp
bWUgcGVyCiBleGVjdXRpb24gZXRjLgoKDAoFBAACBgYSA3oCGAoMCgUEAAIGARIDehkoCgwK
BQQAAgYDEgN6KywKMAoCBAESBX4AjwEBGiMgT3V0cHV0IG9mIHF1ZXJ5IGFkdmlzb3IgYW5h
bHlzaXMuCgoKCgMEAQESA34IGgpUCgQEAQMAEgaAAQKIAQMaRCBSZWNvbW1lbmRhdGlvbiB0
byBhZGQgbmV3IGluZGV4ZXMgdG8gcnVuIHF1ZXJpZXMgbW9yZSBlZmZpY2llbnRseS4KCg0K
BQQBAwABEgSAAQoVCloKBgQBAwACABIEggEERRpKIE9wdGlvbmFsLiBEREwgc3RhdGVtZW50
cyB0byBhZGQgbmV3IGluZGV4ZXMgdGhhdCB3aWxsIGltcHJvdmUgdGhlIHF1ZXJ5LgoKDwoH
BAEDAAIABBIEggEEDAoPCgcEAQMAAgAFEgSCAQ0TCg8KBwQBAwACAAESBIIBFBcKDwoHBAED
AAIAAxIEggEaGwoPCgcEAQMAAgAIEgSCARxEChIKCgQBAwACAAicCAASBIIBHUMKxgEKBgQB
AwACARIEhwEESxq1ASBPcHRpb25hbC4gRXN0aW1hdGVkIGxhdGVuY3kgaW1wcm92ZW1lbnQg
ZmFjdG9yLiBGb3IgZXhhbXBsZSBpZiB0aGUgcXVlcnkKIGN1cnJlbnRseSB0YWtlcyA1MDAg
bXMgdG8gcnVuIGFuZCB0aGUgZXN0aW1hdGVkIGxhdGVuY3kgd2l0aCBuZXcgaW5kZXhlcwog
aXMgMTAwIG1zIHRoaXMgZmllbGQgd2lsbCBiZSA1LgoKDwoHBAEDAAIBBRIEhwEECgoPCgcE
AQMAAgEBEgSHAQsdCg8KBwQBAwACAQMSBIcBICEKDwoHBAEDAAIBCBIEhwEiSgoSCgoEAQMA
AgEInAgAEgSHASNJCtkBCgQEAQIAEgaNAQKOAS8ayAEgT3B0aW9uYWwuIEluZGV4IFJlY29t
bWVuZGF0aW9uIGZvciBhIHF1ZXJ5LiBUaGlzIGlzIGFuIG9wdGlvbmFsIGZpZWxkIGFuZAog
dGhlIHJlY29tbWVuZGF0aW9uIHdpbGwgb25seSBiZSBhdmFpbGFibGUgd2hlbiB0aGUgcmVj
b21tZW5kYXRpb24KIGd1YXJhbnRlZXMgc2lnbmlmaWNhbnQgaW1wcm92ZW1lbnQgaW4gcXVl
cnkgcGVyZm9ybWFuY2UuCgoNCgUEAQIABBIEjQECCgoNCgUEAQIABhIEjQELFgoNCgUEAQIA
ARIEjQEXIwoNCgUEAQIAAxIEjQEmJwoNCgUEAQIACBIEjgEGLgoQCggEAQIACJwIABIEjgEH
LQpOCgIEAhIGkgEAmwEBGkAgQ29udGFpbnMgYW4gb3JkZXJlZCBsaXN0IG9mIG5vZGVzIGFw
cGVhcmluZyBpbiB0aGUgcXVlcnkgcGxhbi4KCgsKAwQCARIEkgEIEQrOAQoEBAICABIElgEC
Ixq/ASBUaGUgbm9kZXMgaW4gdGhlIHF1ZXJ5IHBsYW4uIFBsYW4gbm9kZXMgYXJlIHJldHVy
bmVkIGluIHByZS1vcmRlciBzdGFydGluZwogd2l0aCB0aGUgcGxhbiByb290LiBFYWNoIFtQ
bGFuTm9kZV1bZ29vZ2xlLnNwYW5uZXIudjEuUGxhbk5vZGVdJ3MgYGlkYAogY29ycmVzcG9u
ZHMgdG8gaXRzIGluZGV4IGluIGBwbGFuX25vZGVzYC4KCg0KBQQCAgAEEgSWAQIKCg0KBQQC
AgAGEgSWAQsTCg0KBQQCAgABEgSWARQeCg0KBQQCAgADEgSWASEiCooBCgQEAgIBEgSaAQJP
GnwgT3B0aW9uYWwuIFRoZSBhZHZpc2UvcmVjb21tZW5kYXRpb25zIGZvciBhIHF1ZXJ5LiBD
dXJyZW50bHkgdGhpcyBmaWVsZCB3aWxsCiBiZSBzZXJ2aW5nIGluZGV4IHJlY29tbWVuZGF0
aW9ucyBmb3IgYSBxdWVyeS4KCg0KBQQCAgEGEgSaAQIUCg0KBQQCAgEBEgSaARUhCg0KBQQC
AgEDEgSaASQlCg0KBQQCAgEIEgSaASZOChAKCAQCAgEInAgAEgSaASdNYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::V1::QueryPlan::PlanNode ===
    # Fields for PlanNode
    # Field: index Type: 5 ()
    # Field: kind Type: 14 (.google.spanner.v1.PlanNode.Kind)
    # Field: display_name Type: 9 ()
    # Field: child_links Type: 11 (.google.spanner.v1.PlanNode.ChildLink)
    # Field: short_representation Type: 11 (.google.spanner.v1.PlanNode.ShortRepresentation)
    # Field: metadata Type: 11 (.google.protobuf.Struct)
    # Field: execution_stats Type: 11 (.google.protobuf.Struct)

# Enum: PlanNode::Kind
our $PlanNode_KIND_UNSPECIFIED = 0;
our $PlanNode_RELATIONAL = 1;
our $PlanNode_SCALAR = 2;

# === Message: Google::Spanner::V1::QueryPlan::QueryAdvisorResult ===
    # Fields for QueryAdvisorResult
    # Field: index_advice Type: 11 (.google.spanner.v1.QueryAdvisorResult.IndexAdvice)

# === Message: Google::Spanner::V1::QueryPlan::QueryPlan ===
    # Fields for QueryPlan
    # Field: plan_nodes Type: 11 (.google.spanner.v1.PlanNode)
    # Field: query_advice Type: 11 (.google.spanner.v1.QueryAdvisorResult)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::V1::QueryPlan - Compiled Protocol Buffers messages for google/spanner/v1/query_plan.proto

=head1 SYNOPSIS

    use Google::Spanner::V1::QueryPlan;

    my $msg = Google::Spanner::V1::QueryPlan::PlanNode->new({
        index => $index,
        kind => $kind,
        display_name => $display_name,
        child_links => $child_links,
    });

    # Read or update a field
    my $val = $msg->index();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::V1::QueryPlan::PlanNode->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/v1/query_plan.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::V1::QueryPlan::PlanNode

Node information for nodes appearing in a
[QueryPlan.plan_nodes][google.spanner.v1.QueryPlan.plan_nodes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

The `PlanNode`'s index in [node
list][google.spanner.v1.QueryPlan.plan_nodes].

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Google::Spanner::V1::PlanNode::Kind>)

Used to determine the type of node. May be needed for visualizing
different kinds of nodes differently. For example, If the node is a
[SCALAR][google.spanner.v1.PlanNode.Kind.SCALAR] node, it will have a
condensed representation which can be used to directly embed a description
of the node in its parent.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name for the node.

=item * C<< $msg->child_links() >> / C<< $msg->child_links($value) >>

Type: C<Message> (L<Google::Spanner::V1::QueryPlan::PlanNode::ChildLink>)

List of child node `index`es and their relationship to this parent.

=item * C<< $msg->short_representation() >> / C<< $msg->short_representation($value) >>

Type: C<Message> (L<Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation>)

Condensed representation for
[SCALAR][google.spanner.v1.PlanNode.Kind.SCALAR] nodes.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Attributes relevant to the node contained in a group of key-value pairs.
For example, a Parameter Reference node could have the following
information in its metadata:

    {
      "parameter_reference": "param1",
      "parameter_type": "array"
    }

=item * C<< $msg->execution_stats() >> / C<< $msg->execution_stats($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The execution statistics associated with the node, contained in a group of
key-value pairs. Only present if the plan was returned as a result of a
profile query. For example, number of executions, number of rows/time per
execution etc.

=back

=head3 Enum: PlanNode::Kind

=over 4

=item * C<KIND_UNSPECIFIED> => C<0>

=item * C<RELATIONAL> => C<1>

=item * C<SCALAR> => C<2>

=back

=head2 Google::Spanner::V1::QueryPlan::QueryAdvisorResult

Output of query advisor analysis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->index_advice() >> / C<< $msg->index_advice($value) >>

Type: C<Message> (L<Google::Spanner::V1::QueryPlan::QueryAdvisorResult::IndexAdvice>)

Optional. Index Recommendation for a query. This is an optional field and
the recommendation will only be available when the recommendation
guarantees significant improvement in query performance.

=back

=head2 Google::Spanner::V1::QueryPlan::QueryPlan

Contains an ordered list of nodes appearing in the query plan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->plan_nodes() >> / C<< $msg->plan_nodes($value) >>

Type: C<Message> (L<Google::Spanner::V1::QueryPlan::PlanNode>)

The nodes in the query plan. Plan nodes are returned in pre-order starting
with the plan root. Each [PlanNode][google.spanner.v1.PlanNode]'s `id`
corresponds to its index in `plan_nodes`.

=item * C<< $msg->query_advice() >> / C<< $msg->query_advice($value) >>

Type: C<Message> (L<Google::Spanner::V1::QueryPlan::QueryAdvisorResult>)

Optional. The advise/recommendations for a query. Currently this field will
be serving index recommendations for a query.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::V1::QueryPlan::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
