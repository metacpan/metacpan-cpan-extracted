package Google::Cloud::Retail::V2beta::PurgeConfig;

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
Ci1nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9wdXJnZV9jb25maWcucHJvdG8SGmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIg8KDVB1cmdlTWV0YWRhdGEi2wEKFVB1cmdlUHJvZHVjdHNNZXRhZGF0YRI7Cgtj
cmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRp
bWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1
cGRhdGVUaW1lEiMKDXN1Y2Nlc3NfY291bnQYAyABKANSDHN1Y2Nlc3NDb3VudBIjCg1mYWls
dXJlX2NvdW50GAQgASgDUgxmYWlsdXJlQ291bnQihwEKFFB1cmdlUHJvZHVjdHNSZXF1ZXN0
EjwKBnBhcmVudBgBIAEoCUIk4EEC+kEeChxyZXRhaWwuZ29vZ2xlYXBpcy5jb20vQnJhbmNo
UgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQJSBmZpbHRlchIUCgVmb3JjZRgDIAEoCFIF
Zm9yY2UifwoVUHVyZ2VQcm9kdWN0c1Jlc3BvbnNlEh8KC3B1cmdlX2NvdW50GAEgASgDUgpw
dXJnZUNvdW50EkUKDHB1cmdlX3NhbXBsZRgCIAMoCUIi+kEfCh1yZXRhaWwuZ29vZ2xlYXBp
cy5jb20vUHJvZHVjdFILcHVyZ2VTYW1wbGUiigEKFlB1cmdlVXNlckV2ZW50c1JlcXVlc3QS
PQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9n
UgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQJSBmZpbHRlchIUCgVmb3JjZRgDIAEoCFIF
Zm9yY2UiSQoXUHVyZ2VVc2VyRXZlbnRzUmVzcG9uc2USLgoTcHVyZ2VkX2V2ZW50c19jb3Vu
dBgBIAEoA1IRcHVyZ2VkRXZlbnRzQ291bnRCzwEKHmNvbS5nb29nbGUuY2xvdWQucmV0YWls
LnYyYmV0YUIQUHVyZ2VDb25maWdQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL3JldGFp
bC9hcGl2MmJldGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhpHb29nbGUuQ2xvdWQu
UmV0YWlsLlYyQmV0YcoCGkdvb2dsZVxDbG91ZFxSZXRhaWxcVjJiZXRh6gIdR29vZ2xlOjpD
bG91ZDo6UmV0YWlsOjpWMmJldGFK3S4KBxIFDgCtAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
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
dGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMU
ACkKCAoBCBIDFgA3CgkKAgglEgMWADcKCAoBCBIDFwBNCgkKAggLEgMXAE0KCAoBCBIDGAAi
CgkKAggKEgMYACIKCAoBCBIDGQAxCgkKAggIEgMZADEKCAoBCBIDGgA3CgkKAggBEgMaADcK
CAoBCBIDGwAkCgkKAggkEgMbACQKCAoBCBIDHAA3CgkKAggpEgMcADcKCAoBCBIDHQA2CgkK
AggtEgMdADYKkQEKAgQAEgMhABgahQEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jl
c3Mgb2YgdGhlIFB1cmdlIG9wZXJhdGlvbi4KIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0
aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YSBmaWVsZC4KCgoKAwQA
ARIDIQgVCpoBCgIEARIEJQAyARqNASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVz
cyBvZiB0aGUgUHVyZ2VQcm9kdWN0cyBvcGVyYXRpb24uCiBUaGlzIHdpbGwgYmUgcmV0dXJu
ZWQgYnkgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEgZmllbGQu
CgoKCgMEAQESAyUIHQolCgQEAQIAEgMnAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoM
CgUEAQIABhIDJwIbCgwKBQQBAgABEgMnHCcKDAoFBAECAAMSAycqKwpjCgQEAQIBEgMrAiwa
ViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25l
LCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCgwKBQQBAgEGEgMrAhsKDAoFBAEC
AQESAyscJwoMCgUEAQIBAxIDKyorCj8KBAQBAgISAy4CGhoyIENvdW50IG9mIGVudHJpZXMg
dGhhdCB3ZXJlIGRlbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDAoFBAECAgUSAy4CBwoMCgUEAQIC
ARIDLggVCgwKBQQBAgIDEgMuGBkKSQoEBAECAxIDMQIaGjwgQ291bnQgb2YgZW50cmllcyB0
aGF0IGVuY291bnRlcmVkIGVycm9ycyB3aGlsZSBwcm9jZXNzaW5nLgoKDAoFBAECAwUSAzEC
BwoMCgUEAQIDARIDMQgVCgwKBQQBAgMDEgMxGBkKNwoCBAISBDUAbAEaKyBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIFB1cmdlUHJvZHVjdHMgbWV0aG9kLgoKCgoDBAIBEgM1CBwKxAEKBAQCAgAS
BDkCPAQatQEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBicmFuY2ggdW5k
ZXIgd2hpY2ggdGhlIHByb2R1Y3RzIGFyZQogY3JlYXRlZC4gVGhlIGZvcm1hdCBpcwogYHBy
b2plY3RzLyR7cHJvamVjdElkfS9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzLyR7Y2F0YWxv
Z0lkfS9icmFuY2hlcy8ke2JyYW5jaElkfWAKCgwKBQQCAgAFEgM5AggKDAoFBAICAAESAzkJ
DwoMCgUEAgIAAxIDORITCg0KBQQCAgAIEgQ5FDwDCg8KCAQCAgAInAgAEgM6BCoKDgoHBAIC
AAifCBIDOwROCuEJCgQEAgIBEgNmAj0a0wkgUmVxdWlyZWQuIFRoZSBmaWx0ZXIgc3RyaW5n
IHRvIHNwZWNpZnkgdGhlIHByb2R1Y3RzIHRvIGJlIGRlbGV0ZWQgd2l0aCBhCiBsZW5ndGgg
bGltaXQgb2YgNSwwMDAgY2hhcmFjdGVycy4KCiBFbXB0eSBzdHJpbmcgZmlsdGVyIGlzIG5v
dCBhbGxvd2VkLiAiKiIgaW1wbGllcyBkZWxldGUgYWxsIGl0ZW1zIGluIGEKIGJyYW5jaC4K
CiBUaGUgZWxpZ2libGUgZmllbGRzIGZvciBmaWx0ZXJpbmcgYXJlOgoKICogYGF2YWlsYWJp
bGl0eWA6IERvdWJsZSBxdW90ZWQKIFtQcm9kdWN0LmF2YWlsYWJpbGl0eV1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmJldGEuUHJvZHVjdC5hdmFpbGFiaWxpdHldCiBzdHJpbmcuCiAqIGBj
cmVhdGVfdGltZWAgOiBpbiBJU08gODYwMSAienVsdSIgZm9ybWF0LgoKIFN1cHBvcnRlZCBz
eW50YXg6CgogKiBDb21wYXJhdG9ycyAoIj4iLCAiPCIsICI+PSIsICI8PSIsICI9IikuCiAg
IEV4YW1wbGVzOgogICAqIGNyZWF0ZV90aW1lIDw9ICIyMDE1LTAyLTEzVDE3OjA1OjQ2WiIK
ICAgKiBhdmFpbGFiaWxpdHkgPSAiSU5fU1RPQ0siCgogKiBDb25qdW5jdGlvbnMgKCJBTkQi
KQogICBFeGFtcGxlczoKICAgKiBjcmVhdGVfdGltZSA8PSAiMjAxNS0wMi0xM1QxNzowNTo0
NloiIEFORCBhdmFpbGFiaWxpdHkgPSAiUFJFT1JERVIiCgogKiBEaXNqdW5jdGlvbnMgKCJP
UiIpCiAgIEV4YW1wbGVzOgogICAqIGNyZWF0ZV90aW1lIDw9ICIyMDE1LTAyLTEzVDE3OjA1
OjQ2WiIgT1IgYXZhaWxhYmlsaXR5ID0gIklOX1NUT0NLIgoKICogQ2FuIHN1cHBvcnQgbmVz
dGVkIHF1ZXJpZXMuCiAgIEV4YW1wbGVzOgogICAqIChjcmVhdGVfdGltZSA8PSAiMjAxNS0w
Mi0xM1QxNzowNTo0NloiIEFORCBhdmFpbGFiaWxpdHkgPSAiUFJFT1JERVIiKQogICBPUiAo
Y3JlYXRlX3RpbWUgPj0gIjIwMTUtMDItMTRUMTM6MDM6MzJaIiBBTkQgYXZhaWxhYmlsaXR5
ID0gIklOX1NUT0NLIikKCiAqIEZpbHRlciBMaW1pdHM6CiAgICogRmlsdGVyIHNob3VsZCBu
b3QgY29udGFpbiBtb3JlIHRoYW4gNiBjb25kaXRpb25zLgogICAqIE1heCBuZXN0aW5nIGRl
cHRoIHNob3VsZCBub3QgZXhjZWVkIDIgbGV2ZWxzLgoKIEV4YW1wbGVzIHF1ZXJpZXM6CiAq
IERlbGV0ZSBiYWNrIG9yZGVyIHByb2R1Y3RzIGNyZWF0ZWQgYmVmb3JlIGEgdGltZXN0YW1w
LgogICBjcmVhdGVfdGltZSA8PSAiMjAxNS0wMi0xM1QxNzowNTo0NloiIE9SIGF2YWlsYWJp
bGl0eSA9ICJCQUNLT1JERVIiCgoMCgUEAgIBBRIDZgIICgwKBQQCAgEBEgNmCQ8KDAoFBAIC
AQMSA2YSEwoMCgUEAgIBCBIDZhQ8Cg8KCAQCAgEInAgAEgNmFTsKmAEKBAQCAgISA2sCERqK
ASBBY3R1YWxseSBwZXJmb3JtIHRoZSBwdXJnZS4KIElmIGBmb3JjZWAgaXMgc2V0IHRvIGZh
bHNlLCB0aGUgbWV0aG9kIHdpbGwgcmV0dXJuIHRoZSBleHBlY3RlZCBwdXJnZSBjb3VudAog
d2l0aG91dCBkZWxldGluZyBhbnkgcHJvZHVjdHMuCgoMCgUEAgICBRIDawIGCgwKBQQCAgIB
EgNrBwwKDAoFBAICAgMSA2sPEAq9AQoCBAMSBHEAewEasAEgUmVzcG9uc2Ugb2YgdGhlIFB1
cmdlUHJvZHVjdHNSZXF1ZXN0LiBJZiB0aGUgbG9uZyBydW5uaW5nIG9wZXJhdGlvbiBpcwog
c3VjY2Vzc2Z1bGx5IGRvbmUsIHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRo
ZQogZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQuCgoKCgME
AwESA3EIHQpPCgQEAwIAEgNzAhgaQiBUaGUgdG90YWwgY291bnQgb2YgcHJvZHVjdHMgcHVy
Z2VkIGFzIGEgcmVzdWx0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAwIABRIDcwIHCgwKBQQD
AgABEgNzCBMKDAoFBAMCAAMSA3MWFwq5AQoEBAMCARIEeAJ6BBqqASBBIHNhbXBsZSBvZiB0
aGUgcHJvZHVjdCBuYW1lcyB0aGF0IHdpbGwgYmUgZGVsZXRlZC4KIE9ubHkgcG9wdWxhdGVk
IGlmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLiBBIG1heCBvZiAxMDAgbmFtZXMgd2lsbCBi
ZQogcmV0dXJuZWQgYW5kIHRoZSBuYW1lcyBhcmUgY2hvc2VuIGF0IHJhbmRvbS4KCgwKBQQD
AgEEEgN4AgoKDAoFBAMCAQUSA3gLEQoMCgUEAwIBARIDeBIeCgwKBQQDAgEDEgN4ISIKDQoF
BAMCAQgSBHgjegMKDgoHBAMCAQifCBIDeQRPCjoKAgQEEgV+AKUBARotIFJlcXVlc3QgbWVz
c2FnZSBmb3IgUHVyZ2VVc2VyRXZlbnRzIG1ldGhvZC4KCgoKAwQEARIDfggeCrABCgQEBAIA
EgaCAQKFAQQanwEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjYXRhbG9n
IHVuZGVyIHdoaWNoIHRoZSBldmVudHMgYXJlCiBjcmVhdGVkLiBUaGUgZm9ybWF0IGlzCiBg
cHJvamVjdHMvJHtwcm9qZWN0SWR9L2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvJHtjYXRh
bG9nSWR9YAoKDQoFBAQCAAUSBIIBAggKDQoFBAQCAAESBIIBCQ8KDQoFBAQCAAMSBIIBEhMK
DwoFBAQCAAgSBoIBFIUBAwoQCggEBAIACJwIABIEgwEEKgoPCgcEBAIACJ8IEgSEAQRPCsAH
CgQEBAIBEgSfAQI9GrEHIFJlcXVpcmVkLiBUaGUgZmlsdGVyIHN0cmluZyB0byBzcGVjaWZ5
IHRoZSBldmVudHMgdG8gYmUgZGVsZXRlZCB3aXRoIGEKIGxlbmd0aCBsaW1pdCBvZiA1LDAw
MCBjaGFyYWN0ZXJzLiBFbXB0eSBzdHJpbmcgZmlsdGVyIGlzIG5vdCBhbGxvd2VkLiBUaGUK
IGVsaWdpYmxlIGZpZWxkcyBmb3IgZmlsdGVyaW5nIGFyZToKCiAqIGBldmVudFR5cGVgOiBE
b3VibGUgcXVvdGVkCiBbVXNlckV2ZW50LmV2ZW50X3R5cGVdW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLlVzZXJFdmVudC5ldmVudF90eXBlXQogc3RyaW5nLgogKiBgZXZlbnRUaW1l
YDogaW4gSVNPIDg2MDEgInp1bHUiIGZvcm1hdC4KICogYHZpc2l0b3JJZGA6IERvdWJsZSBx
dW90ZWQgc3RyaW5nLiBTcGVjaWZ5aW5nIHRoaXMgd2lsbCBkZWxldGUgYWxsCiAgIGV2ZW50
cyBhc3NvY2lhdGVkIHdpdGggYSB2aXNpdG9yLgogKiBgdXNlcklkYDogRG91YmxlIHF1b3Rl
ZCBzdHJpbmcuIFNwZWNpZnlpbmcgdGhpcyB3aWxsIGRlbGV0ZSBhbGwgZXZlbnRzCiAgIGFz
c29jaWF0ZWQgd2l0aCBhIHVzZXIuCgogRXhhbXBsZXM6CgogKiBEZWxldGluZyBhbGwgZXZl
bnRzIGluIGEgdGltZSByYW5nZToKICAgYGV2ZW50VGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1
OjQzLjUxMVoiCiAgIGV2ZW50VGltZSA8ICIyMDEyLTA0LTIzVDE4OjMwOjQzLjUxMVoiYAog
KiBEZWxldGluZyBzcGVjaWZpYyBldmVudFR5cGUgaW4gdGltZSByYW5nZToKICAgYGV2ZW50
VGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiIGV2ZW50VHlwZSA9ICJkZXRhaWwt
cGFnZS12aWV3ImAKICogRGVsZXRpbmcgYWxsIGV2ZW50cyBmb3IgYSBzcGVjaWZpYyB2aXNp
dG9yOgogICBgdmlzaXRvcklkID0gInZpc2l0b3IxMDI0ImAKCiBUaGUgZmlsdGVyaW5nIGZp
ZWxkcyBhcmUgYXNzdW1lZCB0byBoYXZlIGFuIGltcGxpY2l0IEFORC4KCg0KBQQEAgEFEgSf
AQIICg0KBQQEAgEBEgSfAQkPCg0KBQQEAgEDEgSfARITCg0KBQQEAgEIEgSfARQ8ChAKCAQE
AgEInAgAEgSfARU7CpwBCgQEBAICEgSkAQIRGo0BIEFjdHVhbGx5IHBlcmZvcm0gdGhlIHB1
cmdlLgogSWYgYGZvcmNlYCBpcyBzZXQgdG8gZmFsc2UsIHRoZSBtZXRob2Qgd2lsbCByZXR1
cm4gdGhlIGV4cGVjdGVkIHB1cmdlIGNvdW50CiB3aXRob3V0IGRlbGV0aW5nIGFueSB1c2Vy
IGV2ZW50cy4KCg0KBQQEAgIFEgSkAQIGCg0KBQQEAgIBEgSkAQcMCg0KBQQEAgIDEgSkAQ8Q
CsEBCgIEBRIGqgEArQEBGrIBIFJlc3BvbnNlIG9mIHRoZSBQdXJnZVVzZXJFdmVudHNSZXF1
ZXN0LiBJZiB0aGUgbG9uZyBydW5uaW5nIG9wZXJhdGlvbiBpcwogc3VjY2Vzc2Z1bGx5IGRv
bmUsIHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQuCgoLCgMEBQESBKoBCB8KTgoEBAUC
ABIErAECIBpAIFRoZSB0b3RhbCBjb3VudCBvZiBldmVudHMgcHVyZ2VkIGFzIGEgcmVzdWx0
IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEBQIABRIErAECBwoNCgUEBQIAARIErAEIGwoNCgUE
BQIAAxIErAEeH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::PurgeConfig::PurgeMetadata ===
    # Fields for PurgeMetadata

# === Message: Google::Cloud::Retail::V2beta::PurgeConfig::PurgeProductsMetadata ===
    # Fields for PurgeProductsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Retail::V2beta::PurgeConfig::PurgeProductsRequest ===
    # Fields for PurgeProductsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2beta::PurgeConfig::PurgeProductsResponse ===
    # Fields for PurgeProductsResponse
    # Field: purge_count Type: 3 ()
    # Field: purge_sample Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::PurgeConfig::PurgeUserEventsRequest ===
    # Fields for PurgeUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2beta::PurgeConfig::PurgeUserEventsResponse ===
    # Fields for PurgeUserEventsResponse
    # Field: purged_events_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::PurgeConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/purge_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::PurgeConfig;

    my $msg = Google::Cloud::Retail::V2beta::PurgeConfig::PurgeMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::PurgeConfig::PurgeMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/purge_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::PurgeConfig::PurgeMetadata

Metadata related to the progress of the Purge operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Retail::V2beta::PurgeConfig::PurgeProductsMetadata

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

=head2 Google::Cloud::Retail::V2beta::PurgeConfig::PurgeProductsRequest

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
[Product.availability][google.cloud.retail.v2beta.Product.availability]
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

=head2 Google::Cloud::Retail::V2beta::PurgeConfig::PurgeProductsResponse

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

=head2 Google::Cloud::Retail::V2beta::PurgeConfig::PurgeUserEventsRequest

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
[UserEvent.event_type][google.cloud.retail.v2beta.UserEvent.event_type]
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

=head2 Google::Cloud::Retail::V2beta::PurgeConfig::PurgeUserEventsResponse

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::PurgeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
