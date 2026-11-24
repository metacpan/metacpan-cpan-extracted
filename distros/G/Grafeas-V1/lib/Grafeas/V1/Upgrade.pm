package Grafeas::V1::Upgrade;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    eval { require Grafeas::V1::Package };
    my $descriptor_b64 = <<'EOF';
ChhncmFmZWFzL3YxL3VwZ3JhZGUucHJvdG8SCmdyYWZlYXMudjEaH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8aGGdyYWZlYXMvdjEvcGFja2FnZS5wcm90byLfAQoLVXBncmFk
ZU5vdGUSGAoHcGFja2FnZRgBIAEoCVIHcGFja2FnZRItCgd2ZXJzaW9uGAIgASgLMhMuZ3Jh
ZmVhcy52MS5WZXJzaW9uUgd2ZXJzaW9uEkUKDWRpc3RyaWJ1dGlvbnMYAyADKAsyHy5ncmFm
ZWFzLnYxLlVwZ3JhZGVEaXN0cmlidXRpb25SDWRpc3RyaWJ1dGlvbnMSQAoOd2luZG93c191
cGRhdGUYBCABKAsyGS5ncmFmZWFzLnYxLldpbmRvd3NVcGRhdGVSDXdpbmRvd3NVcGRhdGUi
hAEKE1VwZ3JhZGVEaXN0cmlidXRpb24SFwoHY3BlX3VyaRgBIAEoCVIGY3BlVXJpEiYKDmNs
YXNzaWZpY2F0aW9uGAIgASgJUg5jbGFzc2lmaWNhdGlvbhIaCghzZXZlcml0eRgDIAEoCVII
c2V2ZXJpdHkSEAoDY3ZlGAQgAygJUgNjdmUi7gMKDVdpbmRvd3NVcGRhdGUSPgoIaWRlbnRp
dHkYASABKAsyIi5ncmFmZWFzLnYxLldpbmRvd3NVcGRhdGUuSWRlbnRpdHlSCGlkZW50aXR5
EhQKBXRpdGxlGAIgASgJUgV0aXRsZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRp
b24SQgoKY2F0ZWdvcmllcxgEIAMoCzIiLmdyYWZlYXMudjEuV2luZG93c1VwZGF0ZS5DYXRl
Z29yeVIKY2F0ZWdvcmllcxIkCg5rYl9hcnRpY2xlX2lkcxgFIAMoCVIMa2JBcnRpY2xlSWRz
Eh8KC3N1cHBvcnRfdXJsGAYgASgJUgpzdXBwb3J0VXJsElQKGGxhc3RfcHVibGlzaGVkX3Rp
bWVzdGFtcBgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFmxhc3RQdWJsaXNo
ZWRUaW1lc3RhbXAaQwoISWRlbnRpdHkSGwoJdXBkYXRlX2lkGAEgASgJUgh1cGRhdGVJZBIa
CghyZXZpc2lvbhgCIAEoBVIIcmV2aXNpb24aPwoIQ2F0ZWdvcnkSHwoLY2F0ZWdvcnlfaWQY
ASABKAlSCmNhdGVnb3J5SWQSEgoEbmFtZRgCIAEoCVIEbmFtZSLwAQoRVXBncmFkZU9jY3Vy
cmVuY2USGAoHcGFja2FnZRgBIAEoCVIHcGFja2FnZRI6Cg5wYXJzZWRfdmVyc2lvbhgDIAEo
CzITLmdyYWZlYXMudjEuVmVyc2lvblINcGFyc2VkVmVyc2lvbhJDCgxkaXN0cmlidXRpb24Y
BCABKAsyHy5ncmFmZWFzLnYxLlVwZ3JhZGVEaXN0cmlidXRpb25SDGRpc3RyaWJ1dGlvbhJA
Cg53aW5kb3dzX3VwZGF0ZRgFIAEoCzIZLmdyYWZlYXMudjEuV2luZG93c1VwZGF0ZVINd2lu
ZG93c1VwZGF0ZUJRCg1pby5ncmFmZWFzLnYxUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnBy
b3RvL2dvb2dsZWFwaXMvZ3JhZmVhcy92MTtncmFmZWFzogIDR1JBSqEoCgYSBA4AcQEK2gQK
AQwSAw4AEjLPBCBDb3B5cmlnaHQgMjAxOSBUaGUgR3JhZmVhcyBBdXRob3JzLiBBbGwgcmln
aHRzIHJlc2VydmVkLgoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQABMKCQoCAwASAxIAKQoJCgIDARIDEwAiCggKAQgSAxUATwoJCgII
CxIDFQBPCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAJgoJCgIIARIDFwAmCggKAQgS
AxgAIQoJCgIIJBIDGAAhCqACCgIEABIEHgAoARqTAiBBbiBVcGdyYWRlIE5vdGUgcmVwcmVz
ZW50cyBhIHBvdGVudGlhbCB1cGdyYWRlIG9mIGEgcGFja2FnZSB0byBhIGdpdmVuCiB2ZXJz
aW9uLiBGb3IgZWFjaCBwYWNrYWdlIHZlcnNpb24gY29tYmluYXRpb24gKGkuZS4gYmFzaCA0
LjAsIGJhc2ggNC4xLAogYmFzaCA0LjEuMiksIHRoZXJlIHdpbGwgYmUgYW4gVXBncmFkZSBO
b3RlLiBGb3IgV2luZG93cywgd2luZG93c191cGRhdGUgZmllbGQKIHJlcHJlc2VudHMgdGhl
IGluZm9ybWF0aW9uIHJlbGF0ZWQgdG8gdGhlIHVwZGF0ZS4KCgoKAwQAARIDHggTCkwKBAQA
AgASAyACFRo/IFJlcXVpcmVkIGZvciBub24tV2luZG93cyBPUy4gVGhlIHBhY2thZ2UgdGhp
cyBVcGdyYWRlIGlzIGZvci4KCgwKBQQAAgAFEgMgAggKDAoFBAACAAESAyAJEAoMCgUEAAIA
AxIDIBMUCmkKBAQAAgESAyMCIRpcIFJlcXVpcmVkIGZvciBub24tV2luZG93cyBPUy4gVGhl
IHZlcnNpb24gb2YgdGhlIHBhY2thZ2UgaW4gbWFjaGluZSArIGh1bWFuCiByZWFkYWJsZSBm
b3JtLgoKDAoFBAACAQYSAyMCFAoMCgUEAAIBARIDIxUcCgwKBQQAAgEDEgMjHyAKTQoEBAAC
AhIDJQIxGkAgTWV0YWRhdGEgYWJvdXQgdGhlIHVwZ3JhZGUgZm9yIGVhY2ggc3BlY2lmaWMg
b3BlcmF0aW5nIHN5c3RlbS4KCgwKBQQAAgIEEgMlAgoKDAoFBAACAgYSAyULHgoMCgUEAAIC
ARIDJR8sCgwKBQQAAgIDEgMlLzAKWQoEBAACAxIDJwIjGkwgUmVxdWlyZWQgZm9yIFdpbmRv
d3MgT1MuIFJlcHJlc2VudHMgdGhlIG1ldGFkYXRhIGFib3V0IHRoZSBXaW5kb3dzIHVwZGF0
ZS4KCgwKBQQAAgMGEgMnAg8KDAoFBAACAwESAycQHgoMCgUEAAIDAxIDJyEiCuUBCgIEARIE
LQA6ARrYASBUaGUgVXBncmFkZSBEaXN0cmlidXRpb24gcmVwcmVzZW50cyBtZXRhZGF0YSBh
Ym91dCB0aGUgVXBncmFkZSBmb3IgZWFjaAogb3BlcmF0aW5nIHN5c3RlbSAoQ1BFKS4gU29t
ZSBkaXN0cmlidXRpb25zIGhhdmUgYWRkaXRpb25hbCBtZXRhZGF0YSBhcm91bmQKIHVwZGF0
ZXMsIGNsYXNzaWZ5aW5nIHRoZW0gaW50byB2YXJpb3VzIGNhdGVnb3JpZXMgYW5kIHNldmVy
aXRpZXMuCgoKCgMEAQESAy0IGwp8CgQEAQIAEgMwAhUabyBSZXF1aXJlZCAtIFRoZSBzcGVj
aWZpYyBvcGVyYXRpbmcgc3lzdGVtIHRoaXMgbWV0YWRhdGEgYXBwbGllcyB0by4gU2VlCiBo
dHRwczovL2NwZS5taXRyZS5vcmcvc3BlY2lmaWNhdGlvbi8uCgoMCgUEAQIABRIDMAIICgwK
BQQBAgABEgMwCRAKDAoFBAECAAMSAzATFAqcAgoEBAECARIDNQIcGo4CIFRoZSBvcGVyYXRp
bmcgc3lzdGVtIGNsYXNzaWZpY2F0aW9uIG9mIHRoaXMgVXBncmFkZSwgYXMgc3BlY2lmaWVk
IGJ5IHRoZQogdXBzdHJlYW0gb3BlcmF0aW5nIHN5c3RlbSB1cGdyYWRlIGZlZWQuIEZvciBX
aW5kb3dzIHRoZSBjbGFzc2lmaWNhdGlvbiBpcwogb25lIG9mIHRoZSBjYXRlZ29yeV9pZHMg
bGlzdGVkIGF0CiBodHRwczovL2RvY3MubWljcm9zb2Z0LmNvbS9lbi11cy9wcmV2aW91cy12
ZXJzaW9ucy93aW5kb3dzL2Rlc2t0b3AvZmYzNTc4MDModj12cy44NSkKCgwKBQQBAgEFEgM1
AggKDAoFBAECAQESAzUJFwoMCgUEAQIBAxIDNRobCkoKBAQBAgISAzcCFho9IFRoZSBzZXZl
cml0eSBhcyBzcGVjaWZpZWQgYnkgdGhlIHVwc3RyZWFtIG9wZXJhdGluZyBzeXN0ZW0uCgoM
CgUEAQICBRIDNwIICgwKBQQBAgIBEgM3CREKDAoFBAECAgMSAzcUFQosCgQEAQIDEgM5Ahoa
HyBUaGUgY3ZlIHRpZWQgdG8gdGhpcyBVcGdyYWRlLgoKDAoFBAECAwQSAzkCCgoMCgUEAQID
BRIDOQsRCgwKBQQBAgMBEgM5EhUKDAoFBAECAwMSAzkYGQqAAgoCBAISBEAAXgEa8wEgV2lu
ZG93cyBVcGRhdGUgcmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgYWJvdXQgdGhlIHVwZGF0ZSBm
b3IgdGhlIFdpbmRvd3MKIG9wZXJhdGluZyBzeXN0ZW0uIFRoZSBmaWVsZHMgaW4gdGhpcyBt
ZXNzYWdlIGNvbWUgZnJvbSB0aGUgV2luZG93cyBVcGRhdGUgQVBJCiBkb2N1bWVudGVkIGF0
CiBodHRwczovL2RvY3MubWljcm9zb2Z0LmNvbS9lbi11cy93aW5kb3dzL3dpbjMyL2FwaS93
dWFwaS9ubi13dWFwaS1pdXBkYXRlLgoKCgoDBAIBEgNACBUKNAoEBAIDABIEQgJHAxomIFRo
ZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgdXBkYXRlLgoKDAoFBAIDAAESA0IKEgpDCgYE
AgMAAgASA0QEGRo0IFRoZSByZXZpc2lvbiBpbmRlcGVuZGVudCBpZGVudGlmaWVyIG9mIHRo
ZSB1cGRhdGUuCgoOCgcEAgMAAgAFEgNEBAoKDgoHBAIDAAIAARIDRAsUCg4KBwQCAwACAAMS
A0QXGAozCgYEAgMAAgESA0YEFxokIFRoZSByZXZpc2lvbiBudW1iZXIgb2YgdGhlIHVwZGF0
ZS4KCg4KBwQCAwACAQUSA0YECQoOCgcEAgMAAgEBEgNGChIKDgoHBAIDAAIBAxIDRhUWCj8K
BAQCAgASA0kCGBoyIFJlcXVpcmVkIC0gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUg
dXBkYXRlLgoKDAoFBAICAAYSA0kCCgoMCgUEAgIAARIDSQsTCgwKBQQCAgADEgNJFhcKMQoE
BAICARIDSwITGiQgVGhlIGxvY2FsaXplZCB0aXRsZSBvZiB0aGUgdXBkYXRlLgoKDAoFBAIC
AQUSA0sCCAoMCgUEAgIBARIDSwkOCgwKBQQCAgEDEgNLERIKNwoEBAICAhIDTQIZGiogVGhl
IGxvY2FsaXplZCBkZXNjcmlwdGlvbiBvZiB0aGUgdXBkYXRlLgoKDAoFBAICAgUSA00CCAoM
CgUEAgICARIDTQkUCgwKBQQCAgIDEgNNFxgKOQoEBAIDARIETwJUAxorIFRoZSBjYXRlZ29y
eSB0byB3aGljaCB0aGUgdXBkYXRlIGJlbG9uZ3MuCgoMCgUEAgMBARIDTwoSCjAKBgQCAwEC
ABIDUQQbGiEgVGhlIGlkZW50aWZpZXIgb2YgdGhlIGNhdGVnb3J5LgoKDgoHBAIDAQIABRID
UQQKCg4KBwQCAwECAAESA1ELFgoOCgcEAgMBAgADEgNRGRoKNAoGBAIDAQIBEgNTBBQaJSBU
aGUgbG9jYWxpemVkIG5hbWUgb2YgdGhlIGNhdGVnb3J5LgoKDgoHBAIDAQIBBRIDUwQKCg4K
BwQCAwECAQESA1MLDwoOCgcEAgMBAgEDEgNTEhMKQgoEBAICAxIDVgIjGjUgVGhlIGxpc3Qg
b2YgY2F0ZWdvcmllcyB0byB3aGljaCB0aGUgdXBkYXRlIGJlbG9uZ3MuCgoMCgUEAgIDBBID
VgIKCgwKBQQCAgMGEgNWCxMKDAoFBAICAwESA1YUHgoMCgUEAgIDAxIDViEiCl0KBAQCAgQS
A1kCJRpQIFRoZSBNaWNyb3NvZnQgS25vd2xlZGdlIEJhc2UgYXJ0aWNsZSBJRHMgdGhhdCBh
cmUgYXNzb2NpYXRlZCB3aXRoIHRoZQogdXBkYXRlLgoKDAoFBAICBAQSA1kCCgoMCgUEAgIE
BRIDWQsRCgwKBQQCAgQBEgNZEiAKDAoFBAICBAMSA1kjJApHCgQEAgIFEgNbAhkaOiBUaGUg
aHlwZXJsaW5rIHRvIHRoZSBzdXBwb3J0IGluZm9ybWF0aW9uIGZvciB0aGUgdXBkYXRlLgoK
DAoFBAICBQUSA1sCCAoMCgUEAgIFARIDWwkUCgwKBQQCAgUDEgNbFxgKOgoEBAICBhIDXQI5
Gi0gVGhlIGxhc3QgcHVibGlzaGVkIHRpbWVzdGFtcCBvZiB0aGUgdXBkYXRlLgoKDAoFBAIC
BgYSA10CGwoMCgUEAgIGARIDXRw0CgwKBQQCAgYDEgNdNzgK1AIKAgQDEgRlAHEBGscCIEFu
IFVwZ3JhZGUgT2NjdXJyZW5jZSByZXByZXNlbnRzIHRoYXQgYSBzcGVjaWZpYyByZXNvdXJj
ZV91cmwgY291bGQgaW5zdGFsbCBhCiBzcGVjaWZpYyB1cGdyYWRlLiBUaGlzIHByZXNlbmNl
IGlzIHN1cHBsaWVkIHZpYSBsb2NhbCBzb3VyY2VzIChpLmUuIGl0IGlzCiBwcmVzZW50IGlu
IHRoZSBtaXJyb3IgYW5kIHRoZSBydW5uaW5nIHN5c3RlbSBoYXMgbm90aWNlZCBpdHMgYXZh
aWxhYmlsaXR5KS4KIEZvciBXaW5kb3dzLCBib3RoIGRpc3RyaWJ1dGlvbiBhbmQgd2luZG93
c191cGRhdGUgY29udGFpbiBpbmZvcm1hdGlvbiBmb3IgdGhlCiBXaW5kb3dzIHVwZGF0ZS4K
CgoKAwQDARIDZQgZCkwKBAQDAgASA2cCFRo/IFJlcXVpcmVkIGZvciBub24tV2luZG93cyBP
Uy4gVGhlIHBhY2thZ2UgdGhpcyBVcGdyYWRlIGlzIGZvci4KCgwKBQQDAgAFEgNnAggKDAoF
BAMCAAESA2cJEAoMCgUEAwIAAxIDZxMUCmsKBAQDAgESA2oCKBpeIFJlcXVpcmVkIGZvciBu
b24tV2luZG93cyBPUy4gVGhlIHZlcnNpb24gb2YgdGhlIHBhY2thZ2UgaW4gYSBtYWNoaW5l
ICsKIGh1bWFuIHJlYWRhYmxlIGZvcm0uCgoMCgUEAwIBBhIDagIUCgwKBQQDAgEBEgNqFSMK
DAoFBAMCAQMSA2omJwrGAQoEBAMCAhIDbgInGrgBIE1ldGFkYXRhIGFib3V0IHRoZSB1cGdy
YWRlIGZvciBhdmFpbGFibGUgZm9yIHRoZSBzcGVjaWZpYyBvcGVyYXRpbmcgc3lzdGVtCiBm
b3IgdGhlIHJlc291cmNlX3VybC4gVGhpcyBhbGxvd3MgZWZmaWNpZW50IGZpbHRlcmluZywg
YXMgd2VsbCBhcwogbWFraW5nIGl0IGVhc2llciB0byB1c2UgdGhlIG9jY3VycmVuY2UuCgoM
CgUEAwICBhIDbgIVCgwKBQQDAgIBEgNuFiIKDAoFBAMCAgMSA24lJgpZCgQEAwIDEgNwAiMa
TCBSZXF1aXJlZCBmb3IgV2luZG93cyBPUy4gUmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgYWJv
dXQgdGhlIFdpbmRvd3MgdXBkYXRlLgoKDAoFBAMCAwYSA3ACDwoMCgUEAwIDARIDcBAeCgwK
BQQDAgMDEgNwISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Upgrade::UpgradeNote ===
    # Fields for UpgradeNote
    # Field: package Type: 9 ()
    # Field: version Type: 11 (.grafeas.v1.Version)
    # Field: distributions Type: 11 (.grafeas.v1.UpgradeDistribution)
    # Field: windows_update Type: 11 (.grafeas.v1.WindowsUpdate)

# === Message: Grafeas::V1::Upgrade::UpgradeDistribution ===
    # Fields for UpgradeDistribution
    # Field: cpe_uri Type: 9 ()
    # Field: classification Type: 9 ()
    # Field: severity Type: 9 ()
    # Field: cve Type: 9 ()

# === Message: Grafeas::V1::Upgrade::WindowsUpdate ===
    # Fields for WindowsUpdate
    # Field: identity Type: 11 (.grafeas.v1.WindowsUpdate.Identity)
    # Field: title Type: 9 ()
    # Field: description Type: 9 ()
    # Field: categories Type: 11 (.grafeas.v1.WindowsUpdate.Category)
    # Field: kb_article_ids Type: 9 ()
    # Field: support_url Type: 9 ()
    # Field: last_published_timestamp Type: 11 (.google.protobuf.Timestamp)

# === Message: Grafeas::V1::Upgrade::UpgradeOccurrence ===
    # Fields for UpgradeOccurrence
    # Field: package Type: 9 ()
    # Field: parsed_version Type: 11 (.grafeas.v1.Version)
    # Field: distribution Type: 11 (.grafeas.v1.UpgradeDistribution)
    # Field: windows_update Type: 11 (.grafeas.v1.WindowsUpdate)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Upgrade - Compiled Protocol Buffers messages for grafeas/v1/upgrade.proto

=head1 SYNOPSIS

    use Grafeas::V1::Upgrade;

    my $msg = Grafeas::V1::Upgrade::UpgradeNote->new({
        package => $package,
        version => $version,
        distributions => $distributions,
        windows_update => $windows_update,
    });

    # Read or update a field
    my $val = $msg->package();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Upgrade::UpgradeNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/upgrade.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Upgrade::UpgradeNote

An Upgrade Note represents a potential upgrade of a package to a given
version. For each package version combination (i.e. bash 4.0, bash 4.1,
bash 4.1.2), there will be an Upgrade Note. For Windows, windows_update field
represents the information related to the update.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->package() >> / C<< $msg->package($value) >>

Type: C<String>

Required for non-Windows OS. The package this Upgrade is for.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Version>)

Required for non-Windows OS. The version of the package in machine + human
readable form.

=item * C<< $msg->distributions() >> / C<< $msg->distributions($value) >>

Type: C<Message> (L<Grafeas::V1::Upgrade::UpgradeDistribution>)

Metadata about the upgrade for each specific operating system.

=item * C<< $msg->windows_update() >> / C<< $msg->windows_update($value) >>

Type: C<Message> (L<Grafeas::V1::Upgrade::WindowsUpdate>)

Required for Windows OS. Represents the metadata about the Windows update.

=back

=head2 Grafeas::V1::Upgrade::UpgradeDistribution

The Upgrade Distribution represents metadata about the Upgrade for each
operating system (CPE). Some distributions have additional metadata around
updates, classifying them into various categories and severities.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpe_uri() >> / C<< $msg->cpe_uri($value) >>

Type: C<String>

Required - The specific operating system this metadata applies to. See
https://cpe.mitre.org/specification/.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<String>

The operating system classification of this Upgrade, as specified by the
upstream operating system upgrade feed. For Windows the classification is
one of the category_ids listed at
https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ff357803(v=vs.85)

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<String>

The severity as specified by the upstream operating system.

=item * C<< $msg->cve() >> / C<< $msg->cve($value) >>

Type: C<String>

The cve tied to this Upgrade.

=back

=head2 Grafeas::V1::Upgrade::WindowsUpdate

Windows Update represents the metadata about the update for the Windows
operating system. The fields in this message come from the Windows Update API
documented at
https://docs.microsoft.com/en-us/windows/win32/api/wuapi/nn-wuapi-iupdate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->identity() >> / C<< $msg->identity($value) >>

Type: C<Message> (L<Grafeas::V1::Upgrade::WindowsUpdate::Identity>)

Required - The unique identifier for the update.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

The localized title of the update.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The localized description of the update.

=item * C<< $msg->categories() >> / C<< $msg->categories($value) >>

Type: C<Message> (L<Grafeas::V1::Upgrade::WindowsUpdate::Category>)

The list of categories to which the update belongs.

=item * C<< $msg->kb_article_ids() >> / C<< $msg->kb_article_ids($value) >>

Type: C<String>

The Microsoft Knowledge Base article IDs that are associated with the
update.

=item * C<< $msg->support_url() >> / C<< $msg->support_url($value) >>

Type: C<String>

The hyperlink to the support information for the update.

=item * C<< $msg->last_published_timestamp() >> / C<< $msg->last_published_timestamp($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last published timestamp of the update.

=back

=head2 Grafeas::V1::Upgrade::UpgradeOccurrence

An Upgrade Occurrence represents that a specific resource_url could install a
specific upgrade. This presence is supplied via local sources (i.e. it is
present in the mirror and the running system has noticed its availability).
For Windows, both distribution and windows_update contain information for the
Windows update.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->package() >> / C<< $msg->package($value) >>

Type: C<String>

Required for non-Windows OS. The package this Upgrade is for.

=item * C<< $msg->parsed_version() >> / C<< $msg->parsed_version($value) >>

Type: C<Message> (L<Grafeas::V1::Package::Version>)

Required for non-Windows OS. The version of the package in a machine +
human readable form.

=item * C<< $msg->distribution() >> / C<< $msg->distribution($value) >>

Type: C<Message> (L<Grafeas::V1::Upgrade::UpgradeDistribution>)

Metadata about the upgrade for available for the specific operating system
for the resource_url. This allows efficient filtering, as well as
making it easier to use the occurrence.

=item * C<< $msg->windows_update() >> / C<< $msg->windows_update($value) >>

Type: C<Message> (L<Grafeas::V1::Upgrade::WindowsUpdate>)

Required for Windows OS. Represents the metadata about the Windows update.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Upgrade::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
