package Google::Cloud::Retail::V2alpha::PurgeConfig;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvcHVyZ2VfY29uZmlnLnByb3RvEhtnb29n
bGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8iDwoNUHVyZ2VNZXRhZGF0YSLbAQoVUHVyZ2VQcm9kdWN0c01ldGFkYXRhEjsK
C2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRl
VGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
CnVwZGF0ZVRpbWUSIwoNc3VjY2Vzc19jb3VudBgDIAEoA1IMc3VjY2Vzc0NvdW50EiMKDWZh
aWx1cmVfY291bnQYBCABKANSDGZhaWx1cmVDb3VudCKHAQoUUHVyZ2VQcm9kdWN0c1JlcXVl
c3QSPAoGcGFyZW50GAEgASgJQiTgQQL6QR4KHHJldGFpbC5nb29nbGVhcGlzLmNvbS9CcmFu
Y2hSBnBhcmVudBIbCgZmaWx0ZXIYAiABKAlCA+BBAlIGZmlsdGVyEhQKBWZvcmNlGAMgASgI
UgVmb3JjZSJ/ChVQdXJnZVByb2R1Y3RzUmVzcG9uc2USHwoLcHVyZ2VfY291bnQYASABKANS
CnB1cmdlQ291bnQSRQoMcHVyZ2Vfc2FtcGxlGAIgAygJQiL6QR8KHXJldGFpbC5nb29nbGVh
cGlzLmNvbS9Qcm9kdWN0UgtwdXJnZVNhbXBsZSKKAQoWUHVyZ2VVc2VyRXZlbnRzUmVxdWVz
dBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFs
b2dSBnBhcmVudBIbCgZmaWx0ZXIYAiABKAlCA+BBAlIGZmlsdGVyEhQKBWZvcmNlGAMgASgI
UgVmb3JjZSJJChdQdXJnZVVzZXJFdmVudHNSZXNwb25zZRIuChNwdXJnZWRfZXZlbnRzX2Nv
dW50GAEgASgDUhFwdXJnZWRFdmVudHNDb3VudELUAQofY29tLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJhbHBoYUIQUHVyZ2VDb25maWdQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL3Jl
dGFpbC9hcGl2MmFscGhhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIbR29vZ2xlLkNs
b3VkLlJldGFpbC5WMkFscGhhygIbR29vZ2xlXENsb3VkXFJldGFpbFxWMmFscGhh6gIeR29v
Z2xlOjpDbG91ZDo6UmV0YWlsOjpWMmFscGhhSt8uCgcSBQ4ArQEBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJ
CgIDAhIDFAApCggKAQgSAxYAOAoJCgIIJRIDFgA4CggKAQgSAxcATgoJCgIICxIDFwBOCggK
AQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMQoJCgIICBIDGQAxCggKAQgSAxoAOAoJCgII
ARIDGgA4CggKAQgSAxsAJAoJCgIIJBIDGwAkCggKAQgSAxwAOAoJCgIIKRIDHAA4CggKAQgS
Ax0ANwoJCgIILRIDHQA3CpEBCgIEABIDIQAYGoUBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhl
IHByb2dyZXNzIG9mIHRoZSBQdXJnZSBvcGVyYXRpb24uCiBUaGlzIHdpbGwgYmUgcmV0dXJu
ZWQgYnkgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEgZmllbGQu
CgoKCgMEAAESAyEIFQqaAQoCBAESBCUAMgEajQEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUg
cHJvZ3Jlc3Mgb2YgdGhlIFB1cmdlUHJvZHVjdHMgb3BlcmF0aW9uLgogVGhpcyB3aWxsIGJl
IHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRh
IGZpZWxkLgoKCgoDBAEBEgMlCB0KJQoEBAECABIDJwIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0
aW1lLgoKDAoFBAECAAYSAycCGwoMCgUEAQIAARIDJxwnCgwKBQQBAgADEgMnKisKYwoEBAEC
ARIDKwIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24g
aXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoMCgUEAQIBBhIDKwIb
CgwKBQQBAgEBEgMrHCcKDAoFBAECAQMSAysqKwo/CgQEAQICEgMuAhoaMiBDb3VudCBvZiBl
bnRyaWVzIHRoYXQgd2VyZSBkZWxldGVkIHN1Y2Nlc3NmdWxseS4KCgwKBQQBAgIFEgMuAgcK
DAoFBAECAgESAy4IFQoMCgUEAQICAxIDLhgZCkkKBAQBAgMSAzECGho8IENvdW50IG9mIGVu
dHJpZXMgdGhhdCBlbmNvdW50ZXJlZCBlcnJvcnMgd2hpbGUgcHJvY2Vzc2luZy4KCgwKBQQB
AgMFEgMxAgcKDAoFBAECAwESAzEIFQoMCgUEAQIDAxIDMRgZCjcKAgQCEgQ1AGwBGisgUmVx
dWVzdCBtZXNzYWdlIGZvciBQdXJnZVByb2R1Y3RzIG1ldGhvZC4KCgoKAwQCARIDNQgcCsQB
CgQEAgIAEgQ5AjwEGrUBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYnJh
bmNoIHVuZGVyIHdoaWNoIHRoZSBwcm9kdWN0cyBhcmUKIGNyZWF0ZWQuIFRoZSBmb3JtYXQg
aXMKIGBwcm9qZWN0cy8ke3Byb2plY3RJZH0vbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy8k
e2NhdGFsb2dJZH0vYnJhbmNoZXMvJHticmFuY2hJZH1gCgoMCgUEAgIABRIDOQIICgwKBQQC
AgABEgM5CQ8KDAoFBAICAAMSAzkSEwoNCgUEAgIACBIEORQ8AwoPCggEAgIACJwIABIDOgQq
Cg4KBwQCAgAInwgSAzsETgriCQoEBAICARIDZgI9GtQJIFJlcXVpcmVkLiBUaGUgZmlsdGVy
IHN0cmluZyB0byBzcGVjaWZ5IHRoZSBwcm9kdWN0cyB0byBiZSBkZWxldGVkIHdpdGggYQog
bGVuZ3RoIGxpbWl0IG9mIDUsMDAwIGNoYXJhY3RlcnMuCgogRW1wdHkgc3RyaW5nIGZpbHRl
ciBpcyBub3QgYWxsb3dlZC4gIioiIGltcGxpZXMgZGVsZXRlIGFsbCBpdGVtcyBpbiBhCiBi
cmFuY2guCgogVGhlIGVsaWdpYmxlIGZpZWxkcyBmb3IgZmlsdGVyaW5nIGFyZToKCiAqIGBh
dmFpbGFiaWxpdHlgOiBEb3VibGUgcXVvdGVkCiBbUHJvZHVjdC5hdmFpbGFiaWxpdHldW2dv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Qcm9kdWN0LmF2YWlsYWJpbGl0eV0KIHN0cmlu
Zy4KICogYGNyZWF0ZV90aW1lYCA6IGluIElTTyA4NjAxICJ6dWx1IiBmb3JtYXQuCgogU3Vw
cG9ydGVkIHN5bnRheDoKCiAqIENvbXBhcmF0b3JzICgiPiIsICI8IiwgIj49IiwgIjw9Iiwg
Ij0iKS4KICAgRXhhbXBsZXM6CiAgICogY3JlYXRlX3RpbWUgPD0gIjIwMTUtMDItMTNUMTc6
MDU6NDZaIgogICAqIGF2YWlsYWJpbGl0eSA9ICJJTl9TVE9DSyIKCiAqIENvbmp1bmN0aW9u
cyAoIkFORCIpCiAgIEV4YW1wbGVzOgogICAqIGNyZWF0ZV90aW1lIDw9ICIyMDE1LTAyLTEz
VDE3OjA1OjQ2WiIgQU5EIGF2YWlsYWJpbGl0eSA9ICJQUkVPUkRFUiIKCiAqIERpc2p1bmN0
aW9ucyAoIk9SIikKICAgRXhhbXBsZXM6CiAgICogY3JlYXRlX3RpbWUgPD0gIjIwMTUtMDIt
MTNUMTc6MDU6NDZaIiBPUiBhdmFpbGFiaWxpdHkgPSAiSU5fU1RPQ0siCgogKiBDYW4gc3Vw
cG9ydCBuZXN0ZWQgcXVlcmllcy4KICAgRXhhbXBsZXM6CiAgICogKGNyZWF0ZV90aW1lIDw9
ICIyMDE1LTAyLTEzVDE3OjA1OjQ2WiIgQU5EIGF2YWlsYWJpbGl0eSA9ICJQUkVPUkRFUiIp
CiAgIE9SIChjcmVhdGVfdGltZSA+PSAiMjAxNS0wMi0xNFQxMzowMzozMloiIEFORCBhdmFp
bGFiaWxpdHkgPSAiSU5fU1RPQ0siKQoKICogRmlsdGVyIExpbWl0czoKICAgKiBGaWx0ZXIg
c2hvdWxkIG5vdCBjb250YWluIG1vcmUgdGhhbiA2IGNvbmRpdGlvbnMuCiAgICogTWF4IG5l
c3RpbmcgZGVwdGggc2hvdWxkIG5vdCBleGNlZWQgMiBsZXZlbHMuCgogRXhhbXBsZXMgcXVl
cmllczoKICogRGVsZXRlIGJhY2sgb3JkZXIgcHJvZHVjdHMgY3JlYXRlZCBiZWZvcmUgYSB0
aW1lc3RhbXAuCiAgIGNyZWF0ZV90aW1lIDw9ICIyMDE1LTAyLTEzVDE3OjA1OjQ2WiIgT1Ig
YXZhaWxhYmlsaXR5ID0gIkJBQ0tPUkRFUiIKCgwKBQQCAgEFEgNmAggKDAoFBAICAQESA2YJ
DwoMCgUEAgIBAxIDZhITCgwKBQQCAgEIEgNmFDwKDwoIBAICAQicCAASA2YVOwqYAQoEBAIC
AhIDawIRGooBIEFjdHVhbGx5IHBlcmZvcm0gdGhlIHB1cmdlLgogSWYgYGZvcmNlYCBpcyBz
ZXQgdG8gZmFsc2UsIHRoZSBtZXRob2Qgd2lsbCByZXR1cm4gdGhlIGV4cGVjdGVkIHB1cmdl
IGNvdW50CiB3aXRob3V0IGRlbGV0aW5nIGFueSBwcm9kdWN0cy4KCgwKBQQCAgIFEgNrAgYK
DAoFBAICAgESA2sHDAoMCgUEAgICAxIDaw8QCr0BCgIEAxIEcQB7ARqwASBSZXNwb25zZSBv
ZiB0aGUgUHVyZ2VQcm9kdWN0c1JlcXVlc3QuIElmIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0
aW9uIGlzCiBzdWNjZXNzZnVsbHkgZG9uZSwgdGhlbiB0aGlzIG1lc3NhZ2UgaXMgcmV0dXJu
ZWQgYnkgdGhlCiBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVs
ZC4KCgoKAwQDARIDcQgdCk8KBAQDAgASA3MCGBpCIFRoZSB0b3RhbCBjb3VudCBvZiBwcm9k
dWN0cyBwdXJnZWQgYXMgYSByZXN1bHQgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQDAgAFEgNz
AgcKDAoFBAMCAAESA3MIEwoMCgUEAwIAAxIDcxYXCrkBCgQEAwIBEgR4AnoEGqoBIEEgc2Ft
cGxlIG9mIHRoZSBwcm9kdWN0IG5hbWVzIHRoYXQgd2lsbCBiZSBkZWxldGVkLgogT25seSBw
b3B1bGF0ZWQgaWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2UuIEEgbWF4IG9mIDEwMCBuYW1l
cyB3aWxsIGJlCiByZXR1cm5lZCBhbmQgdGhlIG5hbWVzIGFyZSBjaG9zZW4gYXQgcmFuZG9t
LgoKDAoFBAMCAQQSA3gCCgoMCgUEAwIBBRIDeAsRCgwKBQQDAgEBEgN4Eh4KDAoFBAMCAQMS
A3ghIgoNCgUEAwIBCBIEeCN6AwoOCgcEAwIBCJ8IEgN5BE8KOgoCBAQSBX4ApQEBGi0gUmVx
dWVzdCBtZXNzYWdlIGZvciBQdXJnZVVzZXJFdmVudHMgbWV0aG9kLgoKCgoDBAQBEgN+CB4K
sAEKBAQEAgASBoIBAoUBBBqfASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IGNhdGFsb2cgdW5kZXIgd2hpY2ggdGhlIGV2ZW50cyBhcmUKIGNyZWF0ZWQuIFRoZSBmb3Jt
YXQgaXMKIGBwcm9qZWN0cy8ke3Byb2plY3RJZH0vbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9n
cy8ke2NhdGFsb2dJZH1gCgoNCgUEBAIABRIEggECCAoNCgUEBAIAARIEggEJDwoNCgUEBAIA
AxIEggESEwoPCgUEBAIACBIGggEUhQEDChAKCAQEAgAInAgAEgSDAQQqCg8KBwQEAgAInwgS
BIQBBE8KwQcKBAQEAgESBJ8BAj0asgcgUmVxdWlyZWQuIFRoZSBmaWx0ZXIgc3RyaW5nIHRv
IHNwZWNpZnkgdGhlIGV2ZW50cyB0byBiZSBkZWxldGVkIHdpdGggYQogbGVuZ3RoIGxpbWl0
IG9mIDUsMDAwIGNoYXJhY3RlcnMuIEVtcHR5IHN0cmluZyBmaWx0ZXIgaXMgbm90IGFsbG93
ZWQuIFRoZQogZWxpZ2libGUgZmllbGRzIGZvciBmaWx0ZXJpbmcgYXJlOgoKICogYGV2ZW50
VHlwZWA6IERvdWJsZSBxdW90ZWQKIFtVc2VyRXZlbnQuZXZlbnRfdHlwZV1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhLlVzZXJFdmVudC5ldmVudF90eXBlXQogc3RyaW5nLgogKiBg
ZXZlbnRUaW1lYDogaW4gSVNPIDg2MDEgInp1bHUiIGZvcm1hdC4KICogYHZpc2l0b3JJZGA6
IERvdWJsZSBxdW90ZWQgc3RyaW5nLiBTcGVjaWZ5aW5nIHRoaXMgd2lsbCBkZWxldGUgYWxs
CiAgIGV2ZW50cyBhc3NvY2lhdGVkIHdpdGggYSB2aXNpdG9yLgogKiBgdXNlcklkYDogRG91
YmxlIHF1b3RlZCBzdHJpbmcuIFNwZWNpZnlpbmcgdGhpcyB3aWxsIGRlbGV0ZSBhbGwgZXZl
bnRzCiAgIGFzc29jaWF0ZWQgd2l0aCBhIHVzZXIuCgogRXhhbXBsZXM6CgogKiBEZWxldGlu
ZyBhbGwgZXZlbnRzIGluIGEgdGltZSByYW5nZToKICAgYGV2ZW50VGltZSA+ICIyMDEyLTA0
LTIzVDE4OjI1OjQzLjUxMVoiCiAgIGV2ZW50VGltZSA8ICIyMDEyLTA0LTIzVDE4OjMwOjQz
LjUxMVoiYAogKiBEZWxldGluZyBzcGVjaWZpYyBldmVudFR5cGUgaW4gdGltZSByYW5nZToK
ICAgYGV2ZW50VGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiIGV2ZW50VHlwZSA9
ICJkZXRhaWwtcGFnZS12aWV3ImAKICogRGVsZXRpbmcgYWxsIGV2ZW50cyBmb3IgYSBzcGVj
aWZpYyB2aXNpdG9yOgogICBgdmlzaXRvcklkID0gInZpc2l0b3IxMDI0ImAKCiBUaGUgZmls
dGVyaW5nIGZpZWxkcyBhcmUgYXNzdW1lZCB0byBoYXZlIGFuIGltcGxpY2l0IEFORC4KCg0K
BQQEAgEFEgSfAQIICg0KBQQEAgEBEgSfAQkPCg0KBQQEAgEDEgSfARITCg0KBQQEAgEIEgSf
ARQ8ChAKCAQEAgEInAgAEgSfARU7CpwBCgQEBAICEgSkAQIRGo0BIEFjdHVhbGx5IHBlcmZv
cm0gdGhlIHB1cmdlLgogSWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2UsIHRoZSBtZXRob2Qg
d2lsbCByZXR1cm4gdGhlIGV4cGVjdGVkIHB1cmdlIGNvdW50CiB3aXRob3V0IGRlbGV0aW5n
IGFueSB1c2VyIGV2ZW50cy4KCg0KBQQEAgIFEgSkAQIGCg0KBQQEAgIBEgSkAQcMCg0KBQQE
AgIDEgSkAQ8QCsEBCgIEBRIGqgEArQEBGrIBIFJlc3BvbnNlIG9mIHRoZSBQdXJnZVVzZXJF
dmVudHNSZXF1ZXN0LiBJZiB0aGUgbG9uZyBydW5uaW5nIG9wZXJhdGlvbiBpcwogc3VjY2Vz
c2Z1bGx5IGRvbmUsIHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQuCgoLCgMEBQESBKoB
CB8KTgoEBAUCABIErAECIBpAIFRoZSB0b3RhbCBjb3VudCBvZiBldmVudHMgcHVyZ2VkIGFz
IGEgcmVzdWx0IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEBQIABRIErAECBwoNCgUEBQIAARIE
rAEIGwoNCgUEBQIAAxIErAEeH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata ===
    # Fields for PurgeMetadata

# === Message: Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsMetadata ===
    # Fields for PurgeProductsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsRequest ===
    # Fields for PurgeProductsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsResponse ===
    # Fields for PurgeProductsResponse
    # Field: purge_count Type: 3 ()
    # Field: purge_sample Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsRequest ===
    # Fields for PurgeUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsResponse ===
    # Fields for PurgeUserEventsResponse
    # Field: purged_events_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::PurgeConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/purge_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::PurgeConfig;

    my $msg = Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/purge_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeMetadata

Metadata related to the progress of the Purge operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsMetadata

Metadata related to the progress of the PurgeProducts operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=back

=head2 Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsRequest

Request message for PurgeProducts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the branch under which the products are
created. The format is
`projects/${projectId}/locations/global/catalogs/${catalogId}/branches/${branchId}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the products to be deleted with a
length limit of 5,000 characters.

Empty string filter is not allowed. "*" implies delete all items in a
branch.

The eligible fields for filtering are:

* `availability`: Double quoted
[Product.availability][google.cloud.retail.v2alpha.Product.availability]
string.
* `create_time` : in ISO 8601 "zulu" format.

Supported syntax:

* Comparators (">", "<", ">=", "<=", "=").
  Examples:
  * create_time <= "2015-02-13T17:05:46Z"
  * availability = "IN_STOCK"

* Conjunctions ("AND")
  Examples:
  * create_time <= "2015-02-13T17:05:46Z" AND availability = "PREORDER"

* Disjunctions ("OR")
  Examples:
  * create_time <= "2015-02-13T17:05:46Z" OR availability = "IN_STOCK"

* Can support nested queries.
  Examples:
  * (create_time <= "2015-02-13T17:05:46Z" AND availability = "PREORDER")
  OR (create_time >= "2015-02-14T13:03:32Z" AND availability = "IN_STOCK")

* Filter Limits:
  * Filter should not contain more than 6 conditions.
  * Max nesting depth should not exceed 2 levels.

Examples queries:
* Delete back order products created before a timestamp.
  create_time <= "2015-02-13T17:05:46Z" OR availability = "BACKORDER"

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually perform the purge.
If `force` is set to false, the method will return the expected purge count
without deleting any products.

=back

=head2 Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeProductsResponse

Response of the PurgeProductsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of products purged as a result of the operation.

=item * C<< $msg->purge_sample() >> / C<< $msg->purge_sample($value) >>

Type: C<String>

A sample of the product names that will be deleted.
Only populated if `force` is set to false. A max of 100 names will be
returned and the names are chosen at random.

=back

=head2 Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsRequest

Request message for PurgeUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the catalog under which the events are
created. The format is
`projects/${projectId}/locations/global/catalogs/${catalogId}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the events to be deleted with a
length limit of 5,000 characters. Empty string filter is not allowed. The
eligible fields for filtering are:

* `eventType`: Double quoted
[UserEvent.event_type][google.cloud.retail.v2alpha.UserEvent.event_type]
string.
* `eventTime`: in ISO 8601 "zulu" format.
* `visitorId`: Double quoted string. Specifying this will delete all
  events associated with a visitor.
* `userId`: Double quoted string. Specifying this will delete all events
  associated with a user.

Examples:

* Deleting all events in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z"`
* Deleting specific eventType in time range:
  `eventTime > "2012-04-23T18:25:43.511Z" eventType = "detail-page-view"`
* Deleting all events for a specific visitor:
  `visitorId = "visitor1024"`

The filtering fields are assumed to have an implicit AND.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually perform the purge.
If `force` is set to false, the method will return the expected purge count
without deleting any user events.

=back

=head2 Google::Cloud::Retail::V2alpha::PurgeConfig::PurgeUserEventsResponse

Response of the PurgeUserEventsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purged_events_count() >> / C<< $msg->purged_events_count($value) >>

Type: C<Int64>

The total count of events purged as a result of the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::PurgeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
