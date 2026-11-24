package Google::Cloud::Gkehub::V1beta::Feature;

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
    eval { require Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller };
    eval { require Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh };
    eval { require Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement };
    eval { require Google::Cloud::Gkehub::Metering::V1beta::Metering };
    eval { require Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZ2tlaHViL3YxYmV0YS9mZWF0dXJlLnByb3RvEhpnb29nbGUuY2xv
dWQuZ2tlaHViLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxpCZ29vZ2xlL2Nsb3VkL2drZWh1Yi9wb2xpY3ljb250
cm9sbGVyL3YxYmV0YS9wb2xpY3ljb250cm9sbGVyLnByb3RvGjhnb29nbGUvY2xvdWQvZ2tl
aHViL3NlcnZpY2VtZXNoL3YxYmV0YS9zZXJ2aWNlbWVzaC5wcm90bxpCZ29vZ2xlL2Nsb3Vk
L2drZWh1Yi92MWJldGEvY29uZmlnbWFuYWdlbWVudC9jb25maWdtYW5hZ2VtZW50LnByb3Rv
GjJnb29nbGUvY2xvdWQvZ2tlaHViL3YxYmV0YS9tZXRlcmluZy9tZXRlcmluZy5wcm90bxpI
Z29vZ2xlL2Nsb3VkL2drZWh1Yi92MWJldGEvbXVsdGljbHVzdGVyaW5ncmVzcy9tdWx0aWNs
dXN0ZXJpbmdyZXNzLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoQJ
CgdGZWF0dXJlEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJHCgZsYWJlbHMYAiADKAsyLy5n
b29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0YS5GZWF0dXJlLkxhYmVsc0VudHJ5UgZsYWJlbHMS
XAoOcmVzb3VyY2Vfc3RhdGUYAyABKAsyMC5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0YS5G
ZWF0dXJlUmVzb3VyY2VTdGF0ZUID4EEDUg1yZXNvdXJjZVN0YXRlEkYKBHNwZWMYBCABKAsy
LS5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0YS5Db21tb25GZWF0dXJlU3BlY0ID4EEBUgRz
cGVjEmgKEG1lbWJlcnNoaXBfc3BlY3MYBSADKAsyOC5nb29nbGUuY2xvdWQuZ2tlaHViLnYx
YmV0YS5GZWF0dXJlLk1lbWJlcnNoaXBTcGVjc0VudHJ5QgPgQQFSD21lbWJlcnNoaXBTcGVj
cxJJCgVzdGF0ZRgGIAEoCzIuLmdvb2dsZS5jbG91ZC5na2VodWIudjFiZXRhLkNvbW1vbkZl
YXR1cmVTdGF0ZUID4EEDUgVzdGF0ZRJrChFtZW1iZXJzaGlwX3N0YXRlcxgHIAMoCzI5Lmdv
b2dsZS5jbG91ZC5na2VodWIudjFiZXRhLkZlYXR1cmUuTWVtYmVyc2hpcFN0YXRlc0VudHJ5
QgPgQQNSEG1lbWJlcnNoaXBTdGF0ZXMSQAoLY3JlYXRlX3RpbWUYCCABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCSAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLZGVs
ZXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmRlbGV0
ZVRpbWUaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ARp1ChRNZW1iZXJzaGlwU3BlY3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRJH
CgV2YWx1ZRgCIAEoCzIxLmdvb2dsZS5jbG91ZC5na2VodWIudjFiZXRhLk1lbWJlcnNoaXBG
ZWF0dXJlU3BlY1IFdmFsdWU6AjgBGncKFU1lbWJlcnNoaXBTdGF0ZXNFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRJICgV2YWx1ZRgCIAEoCzIyLmdvb2dsZS5jbG91ZC5na2VodWIudjFiZXRh
Lk1lbWJlcnNoaXBGZWF0dXJlU3RhdGVSBXZhbHVlOgI4ATpe6kFbCh1na2VodWIuZ29vZ2xl
YXBpcy5jb20vRmVhdHVyZRI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2ZlYXR1cmVzL3tmZWF0dXJlfSLRAQoURmVhdHVyZVJlc291cmNlU3RhdGUSTAoFc3Rh
dGUYASABKA4yNi5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYmV0YS5GZWF0dXJlUmVzb3VyY2VT
dGF0ZS5TdGF0ZVIFc3RhdGUiawoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghF
TkFCTElORxABEgoKBkFDVElWRRACEg0KCURJU0FCTElORxADEgwKCFVQREFUSU5HEAQSFAoQ
U0VSVklDRV9VUERBVElORxAFIu4BCgxGZWF0dXJlU3RhdGUSQQoEY29kZRgBIAEoDjItLmdv
b2dsZS5jbG91ZC5na2VodWIudjFiZXRhLkZlYXR1cmVTdGF0ZS5Db2RlUgRjb2RlEiAKC2Rl
c2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhI7Cgt1cGRhdGVfdGltZRgDIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUiPAoEQ29kZRIUChBDT0RFX1VO
U1BFQ0lGSUVEEAASBgoCT0sQARILCgdXQVJOSU5HEAISCQoFRVJST1IQAyKUAQoRQ29tbW9u
RmVhdHVyZVNwZWMSbwoTbXVsdGljbHVzdGVyaW5ncmVzcxhmIAEoCzI7Lmdvb2dsZS5jbG91
ZC5na2VodWIubXVsdGljbHVzdGVyaW5ncmVzcy52MWJldGEuRmVhdHVyZVNwZWNIAFITbXVs
dGljbHVzdGVyaW5ncmVzc0IOCgxmZWF0dXJlX3NwZWMiWQoSQ29tbW9uRmVhdHVyZVN0YXRl
EkMKBXN0YXRlGAEgASgLMiguZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWJldGEuRmVhdHVyZVN0
YXRlQgPgQQNSBXN0YXRlIssCChVNZW1iZXJzaGlwRmVhdHVyZVNwZWMSaQoQY29uZmlnbWFu
YWdlbWVudBhqIAEoCzI7Lmdvb2dsZS5jbG91ZC5na2VodWIuY29uZmlnbWFuYWdlbWVudC52
MWJldGEuTWVtYmVyc2hpcFNwZWNIAFIQY29uZmlnbWFuYWdlbWVudBJMCgRtZXNoGHQgASgL
MjYuZ29vZ2xlLmNsb3VkLmdrZWh1Yi5zZXJ2aWNlbWVzaC52MWJldGEuTWVtYmVyc2hpcFNw
ZWNIAFIEbWVzaBJpChBwb2xpY3ljb250cm9sbGVyGHYgASgLMjsuZ29vZ2xlLmNsb3VkLmdr
ZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5NZW1iZXJzaGlwU3BlY0gAUhBwb2xpY3lj
b250cm9sbGVyQg4KDGZlYXR1cmVfc3BlYyLyAwoWTWVtYmVyc2hpcEZlYXR1cmVTdGF0ZRJb
CgtzZXJ2aWNlbWVzaBhkIAEoCzI3Lmdvb2dsZS5jbG91ZC5na2VodWIuc2VydmljZW1lc2gu
djFiZXRhLk1lbWJlcnNoaXBTdGF0ZUgAUgtzZXJ2aWNlbWVzaBJSCghtZXRlcmluZxhoIAEo
CzI0Lmdvb2dsZS5jbG91ZC5na2VodWIubWV0ZXJpbmcudjFiZXRhLk1lbWJlcnNoaXBTdGF0
ZUgAUghtZXRlcmluZxJqChBjb25maWdtYW5hZ2VtZW50GGogASgLMjwuZ29vZ2xlLmNsb3Vk
LmdrZWh1Yi5jb25maWdtYW5hZ2VtZW50LnYxYmV0YS5NZW1iZXJzaGlwU3RhdGVIAFIQY29u
ZmlnbWFuYWdlbWVudBJqChBwb2xpY3ljb250cm9sbGVyGHQgASgLMjwuZ29vZ2xlLmNsb3Vk
LmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5NZW1iZXJzaGlwU3RhdGVIAFIQcG9s
aWN5Y29udHJvbGxlchI+CgVzdGF0ZRgBIAEoCzIoLmdvb2dsZS5jbG91ZC5na2VodWIudjFi
ZXRhLkZlYXR1cmVTdGF0ZVIFc3RhdGVCDwoNZmVhdHVyZV9zdGF0ZULCAQoeY29tLmdvb2ds
ZS5jbG91ZC5na2VodWIudjFiZXRhQgxGZWF0dXJlUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNv
bS9nby9na2VodWIvYXBpdjFiZXRhL2drZWh1YnBiO2drZWh1YnBiqgIaR29vZ2xlLkNsb3Vk
LkdrZUh1Yi5WMUJldGHKAhpHb29nbGVcQ2xvdWRcR2tlSHViXFYxYmV0YeoCHUdvb2dsZTo6
Q2xvdWQ6OkdrZUh1Yjo6VjFiZXRhSrg8CgcSBQ4A5AEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhID
FABMCgkKAgMDEgMVAEIKCQoCAwQSAxYATAoJCgIDBRIDFwA8CgkKAgMGEgMYAFIKCQoCAwcS
AxkAKQoICgEIEgMbADcKCQoCCCUSAxsANwoICgEIEgMcAE0KCQoCCAsSAxwATQoICgEIEgMd
ACIKCQoCCAoSAx0AIgoICgEIEgMeAC0KCQoCCAgSAx4ALQoICgEIEgMfADcKCQoCCAESAx8A
NwoICgEIEgMgADcKCQoCCCkSAyAANwoICgEIEgMhADYKCQoCCC0SAyEANgpMCgIEABIEJABp
ARpAIEZlYXR1cmUgcmVwcmVzZW50cyB0aGUgc2V0dGluZ3MgYW5kIHN0YXR1cyBvZiBhbnkg
SHViIEZlYXR1cmUuCgoKCgMEAAESAyQIDwoLCgMEAAcSBCUCKAQKDQoFBAAHnQgSBCUCKAQK
fgoEBAACABIDLAI+GnEgT3V0cHV0IG9ubHkuIFRoZSBmdWxsLCB1bmlxdWUgbmFtZSBvZiB0
aGlzIEZlYXR1cmUgcmVzb3VyY2UgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRp
b25zLyovZmVhdHVyZXMvKmAuCgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMsCQ0KDAoFBAAC
AAMSAywQEQoMCgUEAAIACBIDLBI9Cg8KCAQAAgAInAgAEgMsEzwKJwoEBAACARIDLwIhGhog
TGFiZWxzIGZvciB0aGlzIEZlYXR1cmUuCgoMCgUEAAIBBhIDLwIVCgwKBQQAAgEBEgMvFhwK
DAoFBAACAQMSAy8fIApCCgQEAAICEgQyAjMyGjQgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRo
ZSBGZWF0dXJlIHJlc291cmNlIGl0c2VsZi4KCgwKBQQAAgIGEgMyAhYKDAoFBAACAgESAzIX
JQoMCgUEAAICAxIDMigpCgwKBQQAAgIIEgMzBjEKDwoIBAACAgicCAASAzMHMAqRAQoEBAAC
AxIDNwJGGoMBIE9wdGlvbmFsLiBIdWItd2lkZSBGZWF0dXJlIGNvbmZpZ3VyYXRpb24uIElm
IHRoaXMgRmVhdHVyZSBkb2VzIG5vdCBzdXBwb3J0CiBhbnkgSHViLXdpZGUgY29uZmlndXJh
dGlvbiwgdGhpcyBmaWVsZCBtYXkgYmUgdW51c2VkLgoKDAoFBAACAwYSAzcCEwoMCgUEAAID
ARIDNxQYCgwKBQQAAgMDEgM3GxwKDAoFBAACAwgSAzcdRQoPCggEAAIDCJwIABIDNx5ECs0G
CgQEAAIEEgRLAkwvGr4GIE9wdGlvbmFsLiBNZW1iZXJzaGlwLXNwZWNpZmljIGNvbmZpZ3Vy
YXRpb24gZm9yIHRoaXMgRmVhdHVyZS4gSWYgdGhpcwogRmVhdHVyZSBkb2VzIG5vdCBzdXBw
b3J0IGFueSBwZXItTWVtYmVyc2hpcCBjb25maWd1cmF0aW9uLCB0aGlzIGZpZWxkIG1heQog
YmUgdW51c2VkLgoKIFRoZSBrZXlzIGluZGljYXRlIHdoaWNoIE1lbWJlcnNoaXAgdGhlIGNv
bmZpZ3VyYXRpb24gaXMgZm9yLCBpbiB0aGUgZm9ybToKCiBgcHJvamVjdHMve3B9L2xvY2F0
aW9ucy97bH0vbWVtYmVyc2hpcHMve219YAoKIFdoZXJlIHtwfSBpcyB0aGUgcHJvamVjdCwg
e2x9IGlzIGEgdmFsaWQgbG9jYXRpb24gYW5kIHttfSBpcyBhIHZhbGlkCiBNZW1iZXJzaGlw
IGluIHRoaXMgcHJvamVjdCBhdCB0aGF0IGxvY2F0aW9uLiB7cH0gV0lMTCBtYXRjaCB0aGUg
RmVhdHVyZSdzCiBwcm9qZWN0LgoKIHtwfSB3aWxsIGFsd2F5cyBiZSByZXR1cm5lZCBhcyB0
aGUgcHJvamVjdCBudW1iZXIsIGJ1dCB0aGUgcHJvamVjdCBJRCBpcwogYWxzbyBhY2NlcHRl
ZCBkdXJpbmcgaW5wdXQuIElmIHRoZSBzYW1lIE1lbWJlcnNoaXAgaXMgc3BlY2lmaWVkIGlu
IHRoZSBtYXAKIHR3aWNlICh1c2luZyB0aGUgcHJvamVjdCBJRCBmb3JtLCBhbmQgdGhlIHBy
b2plY3QgbnVtYmVyIGZvcm0pLCBleGFjdGx5CiBPTkUgb2YgdGhlIGVudHJpZXMgd2lsbCBi
ZSBzYXZlZCwgd2l0aCBubyBndWFyYW50ZWVzIGFzIHRvIHdoaWNoLiBGb3IgdGhpcwogcmVh
c29uLCBpdCBpcyByZWNvbW1lbmRlZCB0aGUgc2FtZSBmb3JtYXQgYmUgdXNlZCBmb3IgYWxs
IGVudHJpZXMgd2hlbgogbXV0YXRpbmcgYSBGZWF0dXJlLgoKDAoFBAACBAYSA0sCJAoMCgUE
AAIEARIDSyU1CgwKBQQAAgQDEgNLODkKDAoFBAACBAgSA0wGLgoPCggEAAIECJwIABIDTAct
CjcKBAQAAgUSA08CSxoqIE91dHB1dCBvbmx5LiBUaGUgSHViLXdpZGUgRmVhdHVyZSBzdGF0
ZS4KCgwKBQQAAgUGEgNPAhQKDAoFBAACBQESA08VGgoMCgUEAAIFAxIDTx0eCgwKBQQAAgUI
EgNPH0oKDwoIBAACBQicCAASA08gSQqwAwoEBAACBhIEWwJcMhqhAyBPdXRwdXQgb25seS4g
TWVtYmVyc2hpcC1zcGVjaWZpYyBGZWF0dXJlIHN0YXR1cy4gSWYgdGhpcyBGZWF0dXJlIGRv
ZXMKIHJlcG9ydCBhbnkgcGVyLU1lbWJlcnNoaXAgc3RhdHVzLCB0aGlzIGZpZWxkIG1heSBi
ZSB1bnVzZWQuCgogVGhlIGtleXMgaW5kaWNhdGUgd2hpY2ggTWVtYmVyc2hpcCB0aGUgc3Rh
dGUgaXMgZm9yLCBpbiB0aGUgZm9ybToKCiBgcHJvamVjdHMve3B9L2xvY2F0aW9ucy97bH0v
bWVtYmVyc2hpcHMve219YAoKIFdoZXJlIHtwfSBpcyB0aGUgcHJvamVjdCBudW1iZXIsIHts
fSBpcyBhIHZhbGlkIGxvY2F0aW9uIGFuZCB7bX0gaXMgYSB2YWxpZAogTWVtYmVyc2hpcCBp
biB0aGlzIHByb2plY3QgYXQgdGhhdCBsb2NhdGlvbi4ge3B9IE1VU1QgbWF0Y2ggdGhlIEZl
YXR1cmUncwogcHJvamVjdCBudW1iZXIuCgoMCgUEAAIGBhIDWwIlCgwKBQQAAgYBEgNbJjcK
DAoFBAACBgMSA1s6OwoMCgUEAAIGCBIDXAYxCg8KCAQAAgYInAgAEgNcBzAKQwoEBAACBxIE
XwJgMho1IE91dHB1dCBvbmx5LiBXaGVuIHRoZSBGZWF0dXJlIHJlc291cmNlIHdhcyBjcmVh
dGVkLgoKDAoFBAACBwYSA18CGwoMCgUEAAIHARIDXxwnCgwKBQQAAgcDEgNfKisKDAoFBAAC
BwgSA2AGMQoPCggEAAIHCJwIABIDYAcwCkgKBAQAAggSBGMCZDIaOiBPdXRwdXQgb25seS4g
V2hlbiB0aGUgRmVhdHVyZSByZXNvdXJjZSB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACCAYS
A2MCGwoMCgUEAAIIARIDYxwnCgwKBQQAAggDEgNjKisKDAoFBAACCAgSA2QGMQoPCggEAAII
CJwIABIDZAcwCkMKBAQAAgkSBGcCaDIaNSBPdXRwdXQgb25seS4gV2hlbiB0aGUgRmVhdHVy
ZSByZXNvdXJjZSB3YXMgZGVsZXRlZC4KCgwKBQQAAgkGEgNnAhsKDAoFBAACCQESA2ccJwoM
CgUEAAIJAxIDZyosCgwKBQQAAgkIEgNoBjEKDwoIBAACCQicCAASA2gHMArCAQoCBAESBW4A
iQEBGrQBIEZlYXR1cmVSZXNvdXJjZVN0YXRlIGRlc2NyaWJlcyB0aGUgc3RhdGUgb2YgYSBG
ZWF0dXJlICpyZXNvdXJjZSogaW4gdGhlCiBHa2VIdWIgQVBJLiBTZWUgYEZlYXR1cmVTdGF0
ZWAgZm9yIHRoZSAicnVubmluZyBzdGF0ZSIgb2YgdGhlIEZlYXR1cmUgaW4gdGhlCiBIdWIg
YW5kIGFjcm9zcyBNZW1iZXJzaGlwcy4KCgoKAwQBARIDbggcCkMKBAQBBAASBXAChQEDGjQg
U3RhdGUgZGVzY3JpYmVzIHRoZSBsaWZlY3ljbGUgc3RhdHVzIG9mIGEgRmVhdHVyZS4KCgwK
BQQBBAABEgNwBwwKLQoGBAEEAAIAEgNyBBoaHiBTdGF0ZSBpcyB1bmtub3duIG9yIG5vdCBz
ZXQuCgoOCgcEAQQAAgABEgNyBBUKDgoHBAEEAAIAAhIDchgZCqEBCgYEAQQAAgESA3YEERqR
ASBUaGUgRmVhdHVyZSBpcyBiZWluZyBlbmFibGVkLCBhbmQgdGhlIEZlYXR1cmUgcmVzb3Vy
Y2UgaXMgYmVpbmcgY3JlYXRlZC4KIE9uY2UgY29tcGxldGUsIHRoZSBjb3JyZXNwb25kaW5n
IEZlYXR1cmUgd2lsbCBiZSBlbmFibGVkIGluIHRoaXMgSHViLgoKDgoHBAEEAAIBARIDdgQM
Cg4KBwQBBAACAQISA3YPEApiCgYEAQQAAgISA3oEDxpTIFRoZSBGZWF0dXJlIGlzIGVuYWJs
ZWQgaW4gdGhpcyBIdWIsIGFuZCB0aGUgRmVhdHVyZSByZXNvdXJjZSBpcyBmdWxseQogYXZh
aWxhYmxlLgoKDgoHBAEEAAICARIDegQKCg4KBwQBBAACAgISA3oNDgpnCgYEAQQAAgMSA34E
EhpYIFRoZSBGZWF0dXJlIGlzIGJlaW5nIGRpc2FibGVkIGluIHRoaXMgSHViLCBhbmQgdGhl
IEZlYXR1cmUgcmVzb3VyY2UKIGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAQQAAgMBEgN+BA0K
DgoHBAEEAAIDAhIDfhARCjgKBgQBBAACBBIEgQEEERooIFRoZSBGZWF0dXJlIHJlc291cmNl
IGlzIGJlaW5nIHVwZGF0ZWQuCgoPCgcEAQQAAgQBEgSBAQQMCg8KBwQBBAACBAISBIEBDxAK
SwoGBAEEAAIFEgSEAQQZGjsgVGhlIEZlYXR1cmUgcmVzb3VyY2UgaXMgYmVpbmcgdXBkYXRl
ZCBieSB0aGUgSHViIFNlcnZpY2UuCgoPCgcEAQQAAgUBEgSEAQQUCg8KBwQBBAACBQISBIQB
FxgKSQoEBAECABIEiAECEho7IFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBGZWF0dXJlIHJl
c291cmNlIGluIHRoZSBIdWIgQVBJLgoKDQoFBAECAAYSBIgBAgcKDQoFBAECAAESBIgBCA0K
DQoFBAECAAMSBIgBEBEKvAEKAgQCEgaOAQCsAQEarQEgRmVhdHVyZVN0YXRlIGRlc2NyaWJl
cyB0aGUgaGlnaC1sZXZlbCBzdGF0ZSBvZiBhIEZlYXR1cmUuIEl0IG1heSBiZSB1c2VkIHRv
CiBkZXNjcmliZSBhIEZlYXR1cmUncyBzdGF0ZSBhdCB0aGUgZW52aXJvbi1sZXZlbCwgb3Ig
cGVyLW1lbWJlcnNob3AsIGRlcGVuZGluZwogb24gdGhlIGNvbnRleHQuCgoLCgMEAgESBI4B
CBQKVwoEBAIEABIGkAECogEDGkcgQ29kZSByZXByZXNlbnRzIGEgbWFjaGluZS1yZWFkYWJs
ZSwgaGlnaC1sZXZlbCBzdGF0dXMgb2YgdGhlIEZlYXR1cmUuCgoNCgUEAgQAARIEkAEHCwol
CgYEAgQAAgASBJIBBBkaFSBVbmtub3duIG9yIG5vdCBzZXQuCgoPCgcEAgQAAgABEgSSAQQU
Cg8KBwQCBAACAAISBJIBFxgKNAoGBAIEAAIBEgSVAQQLGiQgVGhlIEZlYXR1cmUgaXMgb3Bl
cmF0aW5nIG5vcm1hbGx5LgoKDwoHBAIEAAIBARIElQEEBgoPCgcEAgQAAgECEgSVAQkKCvgB
CgYEAgQAAgISBJsBBBAa5wEgVGhlIEZlYXR1cmUgaGFzIGVuY291bnRlcmVkIGFuIGlzc3Vl
LCBhbmQgaXMgb3BlcmF0aW5nIGluIGEgZGVncmFkZWQKIHN0YXRlLiBUaGUgRmVhdHVyZSBt
YXkgbmVlZCBpbnRlcnZlbnRpb24gdG8gcmV0dXJuIHRvIG5vcm1hbCBvcGVyYXRpb24uCiBT
ZWUgdGhlIGRlc2NyaXB0aW9uIGFuZCBhbnkgYXNzb2NpYXRlZCBGZWF0dXJlLXNwZWNpZmlj
IGRldGFpbHMgZm9yIG1vcmUKIGluZm9ybWF0aW9uLgoKDwoHBAIEAAICARIEmwEECwoPCgcE
AgQAAgICEgSbAQ4PCu0BCgYEAgQAAgMSBKEBBA4a3AEgVGhlIEZlYXR1cmUgaXMgbm90IG9w
ZXJhdGluZyBvciBpcyBpbiBhIHNldmVyZWx5IGRlZ3JhZGVkIHN0YXRlLgogVGhlIEZlYXR1
cmUgbWF5IG5lZWQgaW50ZXJ2ZW50aW9uIHRvIHJldHVybiB0byBub3JtYWwgb3BlcmF0aW9u
LgogU2VlIHRoZSBkZXNjcmlwdGlvbiBhbmQgYW55IGFzc29jaWF0ZWQgRmVhdHVyZS1zcGVj
aWZpYyBkZXRhaWxzIGZvciBtb3JlCiBpbmZvcm1hdGlvbi4KCg8KBwQCBAACAwESBKEBBAkK
DwoHBAIEAAIDAhIEoQEMDQpICgQEAgIAEgSlAQIQGjogVGhlIGhpZ2gtbGV2ZWwsIG1hY2hp
bmUtcmVhZGFibGUgc3RhdHVzIG9mIHRoaXMgRmVhdHVyZS4KCg0KBQQCAgAGEgSlAQIGCg0K
BQQCAgABEgSlAQcLCg0KBQQCAgADEgSlAQ4PCkMKBAQCAgESBKgBAhkaNSBBIGh1bWFuLXJl
YWRhYmxlIGRlc2NyaXB0aW9uIG9mIHRoZSBjdXJyZW50IHN0YXR1cy4KCg0KBQQCAgEFEgSo
AQIICg0KBQQCAgEBEgSoAQkUCg0KBQQCAgEDEgSoARcYClsKBAQCAgISBKsBAiwaTSBUaGUg
dGltZSB0aGlzIHN0YXR1cyBhbmQgYW55IHJlbGF0ZWQgRmVhdHVyZS1zcGVjaWZpYyBkZXRh
aWxzIHdlcmUgdXBkYXRlZC4KCg0KBQQCAgIGEgSrAQIbCg0KBQQCAgIBEgSrARwnCg0KBQQC
AgIDEgSrASorCk0KAgQDEgavAQC1AQEaPyBDb21tb25GZWF0dXJlU3BlYyBjb250YWlucyBI
dWItd2lkZSBjb25maWd1cmF0aW9uIGluZm9ybWF0aW9uCgoLCgMEAwESBK8BCBkKDgoEBAMI
ABIGsAECtAEDCg0KBQQDCAABEgSwAQgUCjUKBAQDAgASBrIBBLMBIholIE11bHRpY2x1c3Rl
ciBJbmdyZXNzLXNwZWNpZmljIHNwZWMuCgoNCgUEAwIABhIEsgEEPgoNCgUEAwIAARIEswEI
GwoNCgUEAwIAAxIEswEeIQpQCgIEBBIGuAEAuwEBGkIgQ29tbW9uRmVhdHVyZVN0YXRlIGNv
bnRhaW5zIEh1Yi13aWRlIEZlYXR1cmUgc3RhdHVzIGluZm9ybWF0aW9uLgoKCwoDBAQBEgS4
AQgaCkwKBAQEAgASBLoBAkUaPiBPdXRwdXQgb25seS4gVGhlICJydW5uaW5nIHN0YXRlIiBv
ZiB0aGUgRmVhdHVyZSBpbiB0aGlzIEh1Yi4KCg0KBQQEAgAGEgS6AQIOCg0KBQQEAgABEgS6
AQ8UCg0KBQQEAgADEgS6ARcYCg0KBQQEAgAIEgS6ARlEChAKCAQEAgAInAgAEgS6ARpDCpYB
CgIEBRIGwAEAzQEBGocBIE1lbWJlcnNoaXBGZWF0dXJlU3BlYyBjb250YWlucyBjb25maWd1
cmF0aW9uIGluZm9ybWF0aW9uIGZvciBhIHNpbmdsZQogTWVtYmVyc2hpcC4KIE5PVEU6IFBs
ZWFzZSB1c2Ugc25ha2UgY2FzZSBpbiB5b3VyIGZlYXR1cmUgbmFtZS4KCgsKAwQFARIEwAEI
HQoOCgQEBQgAEgbBAQLMAQMKDQoFBAUIAAESBMEBCBQKMgoEBAUCABIGwwEExAEfGiIgQ29u
ZmlnIE1hbmFnZW1lbnQtc3BlY2lmaWMgc3BlYy4KCg0KBQQFAgAGEgTDAQQ+Cg0KBQQFAgAB
EgTEAQgYCg0KBQQFAgADEgTEARseCjEKBAQFAgESBMcBBEUaIyBBbnRob3MgU2VydmljZSBN
ZXNoLXNwZWNpZmljIHNwZWMKCg0KBQQFAgEGEgTHAQQ5Cg0KBQQFAgEBEgTHATo+Cg0KBQQF
AgEDEgTHAUFECikKBAQFAgISBsoBBMsBHxoZIFBvbGljeSBDb250cm9sbGVyIHNwZWMuCgoN
CgUEBQICBhIEygEEPgoNCgUEBQICARIEywEIGAoNCgUEBQICAxIEywEbHgpkCgIEBhIG0QEA
5AEBGlYgTWVtYmVyc2hpcEZlYXR1cmVTdGF0ZSBjb250YWlucyBGZWF0dXJlIHN0YXR1cyBp
bmZvcm1hdGlvbiBmb3IgYSBzaW5nbGUKIE1lbWJlcnNoaXAuCgoLCgMEBgESBNEBCB4KDgoE
BAYIABIG0gEC4AEDCg0KBQQGCAABEgTSAQgVCiwKBAQGAgASBNQBBE0aHiBTZXJ2aWNlIE1l
c2gtc3BlY2lmaWMgc3RhdGUuCgoNCgUEBgIABhIE1AEEOgoNCgUEBgIAARIE1AE7RgoNCgUE
BgIAAxIE1AFJTAooCgQEBgIBEgTXAQRHGhogTWV0ZXJpbmctc3BlY2lmaWMgc3RhdGUuCgoN
CgUEBgIBBhIE1wEENwoNCgUEBgIBARIE1wE4QAoNCgUEBgIBAxIE1wFDRgozCgQEBgICEgba
AQTbAR8aIyBDb25maWcgTWFuYWdlbWVudC1zcGVjaWZpYyBzdGF0ZS4KCg0KBQQGAgIGEgTa
AQQ/Cg0KBQQGAgIBEgTbAQgYCg0KBQQGAgIDEgTbARseCjIKBAQGAgMSBt4BBN8BHxoiIFBv
bGljeWNvbnRyb2xsZXItc3BlY2lmaWMgc3RhdGUuCgoNCgUEBgIDBhIE3gEEPwoNCgUEBgID
ARIE3wEIGAoNCgUEBgIDAxIE3wEbHgpNCgQEBgIEEgTjAQIZGj8gVGhlIGhpZ2gtbGV2ZWwg
c3RhdGUgb2YgdGhpcyBGZWF0dXJlIGZvciBhIHNpbmdsZSBtZW1iZXJzaGlwLgoKDQoFBAYC
BAYSBOMBAg4KDQoFBAYCBAESBOMBDxQKDQoFBAYCBAMSBOMBFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::V1beta::Feature::Feature ===
    # Fields for Feature
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkehub.v1beta.Feature.LabelsEntry)
    # Field: resource_state Type: 11 (.google.cloud.gkehub.v1beta.FeatureResourceState)
    # Field: spec Type: 11 (.google.cloud.gkehub.v1beta.CommonFeatureSpec)
    # Field: membership_specs Type: 11 (.google.cloud.gkehub.v1beta.Feature.MembershipSpecsEntry)
    # Field: state Type: 11 (.google.cloud.gkehub.v1beta.CommonFeatureState)
    # Field: membership_states Type: 11 (.google.cloud.gkehub.v1beta.Feature.MembershipStatesEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Gkehub::V1beta::Feature::FeatureResourceState ===
    # Fields for FeatureResourceState
    # Field: state Type: 14 (.google.cloud.gkehub.v1beta.FeatureResourceState.State)

# Enum: FeatureResourceState::State
our $FeatureResourceState_STATE_UNSPECIFIED = 0;
our $FeatureResourceState_ENABLING = 1;
our $FeatureResourceState_ACTIVE = 2;
our $FeatureResourceState_DISABLING = 3;
our $FeatureResourceState_UPDATING = 4;
our $FeatureResourceState_SERVICE_UPDATING = 5;

# === Message: Google::Cloud::Gkehub::V1beta::Feature::FeatureState ===
    # Fields for FeatureState
    # Field: code Type: 14 (.google.cloud.gkehub.v1beta.FeatureState.Code)
    # Field: description Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: FeatureState::Code
our $FeatureState_CODE_UNSPECIFIED = 0;
our $FeatureState_OK = 1;
our $FeatureState_WARNING = 2;
our $FeatureState_ERROR = 3;

# === Message: Google::Cloud::Gkehub::V1beta::Feature::CommonFeatureSpec ===
    # Fields for CommonFeatureSpec
    # Field: multiclusteringress Type: 11 (.google.cloud.gkehub.multiclusteringress.v1beta.FeatureSpec)

# === Message: Google::Cloud::Gkehub::V1beta::Feature::CommonFeatureState ===
    # Fields for CommonFeatureState
    # Field: state Type: 11 (.google.cloud.gkehub.v1beta.FeatureState)

# === Message: Google::Cloud::Gkehub::V1beta::Feature::MembershipFeatureSpec ===
    # Fields for MembershipFeatureSpec
    # Field: configmanagement Type: 11 (.google.cloud.gkehub.configmanagement.v1beta.MembershipSpec)
    # Field: mesh Type: 11 (.google.cloud.gkehub.servicemesh.v1beta.MembershipSpec)
    # Field: policycontroller Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.MembershipSpec)

# === Message: Google::Cloud::Gkehub::V1beta::Feature::MembershipFeatureState ===
    # Fields for MembershipFeatureState
    # Field: servicemesh Type: 11 (.google.cloud.gkehub.servicemesh.v1beta.MembershipState)
    # Field: metering Type: 11 (.google.cloud.gkehub.metering.v1beta.MembershipState)
    # Field: configmanagement Type: 11 (.google.cloud.gkehub.configmanagement.v1beta.MembershipState)
    # Field: policycontroller Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.MembershipState)
    # Field: state Type: 11 (.google.cloud.gkehub.v1beta.FeatureState)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::V1beta::Feature - Compiled Protocol Buffers messages for google/cloud/gkehub/v1beta/feature.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::V1beta::Feature;

    my $msg = Google::Cloud::Gkehub::V1beta::Feature::Feature->new({
        name => $name,
        labels => $labels,
        resource_state => $resource_state,
        spec => $spec,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::V1beta::Feature::Feature->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1beta/feature.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::V1beta::Feature::Feature

Feature represents the settings and status of any Hub Feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full, unique name of this Feature resource in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::Feature::LabelsEntry>)

Labels for this Feature.

=item * C<< $msg->resource_state() >> / C<< $msg->resource_state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::FeatureResourceState>)

Output only. State of the Feature resource itself.

=item * C<< $msg->spec() >> / C<< $msg->spec($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::CommonFeatureSpec>)

Optional. Hub-wide Feature configuration. If this Feature does not support
any Hub-wide configuration, this field may be unused.

=item * C<< $msg->membership_specs() >> / C<< $msg->membership_specs($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::Feature::MembershipSpecsEntry>)

Optional. Membership-specific configuration for this Feature. If this
Feature does not support any per-Membership configuration, this field may
be unused.

The keys indicate which Membership the configuration is for, in the form:

`projects/{p}/locations/{l}/memberships/{m}`

Where {p} is the project, {l} is a valid location and {m} is a valid
Membership in this project at that location. {p} WILL match the Feature's
project.

{p} will always be returned as the project number, but the project ID is
also accepted during input. If the same Membership is specified in the map
twice (using the project ID form, and the project number form), exactly
ONE of the entries will be saved, with no guarantees as to which. For this
reason, it is recommended the same format be used for all entries when
mutating a Feature.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::CommonFeatureState>)

Output only. The Hub-wide Feature state.

=item * C<< $msg->membership_states() >> / C<< $msg->membership_states($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::Feature::MembershipStatesEntry>)

Output only. Membership-specific Feature status. If this Feature does
report any per-Membership status, this field may be unused.

The keys indicate which Membership the state is for, in the form:

`projects/{p}/locations/{l}/memberships/{m}`

Where {p} is the project number, {l} is a valid location and {m} is a valid
Membership in this project at that location. {p} MUST match the Feature's
project number.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Feature resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Feature resource was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the Feature resource was deleted.

=back

=head2 Google::Cloud::Gkehub::V1beta::Feature::FeatureResourceState

FeatureResourceState describes the state of a Feature *resource* in the
GkeHub API. See `FeatureState` for the "running state" of the Feature in the
Hub and across Memberships.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1beta::FeatureResourceState::State>)

The current state of the Feature resource in the Hub API.

=back

=head3 Enum: FeatureResourceState::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DISABLING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<SERVICE_UPDATING> => C<5>

=back

=head2 Google::Cloud::Gkehub::V1beta::Feature::FeatureState

FeatureState describes the high-level state of a Feature. It may be used to
describe a Feature's state at the environ-level, or per-membershop, depending
on the context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1beta::FeatureState::Code>)

The high-level, machine-readable status of this Feature.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the current status.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this status and any related Feature-specific details were updated.

=back

=head3 Enum: FeatureState::Code

=over 4

=item * C<CODE_UNSPECIFIED> => C<0>

=item * C<OK> => C<1>

=item * C<WARNING> => C<2>

=item * C<ERROR> => C<3>

=back

=head2 Google::Cloud::Gkehub::V1beta::Feature::CommonFeatureSpec

CommonFeatureSpec contains Hub-wide configuration information

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->multiclusteringress() >> / C<< $msg->multiclusteringress($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Multiclusteringress::V1beta::Multiclusteringress::FeatureSpec>)

Multicluster Ingress-specific spec.

=back

=head2 Google::Cloud::Gkehub::V1beta::Feature::CommonFeatureState

CommonFeatureState contains Hub-wide Feature status information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::FeatureState>)

Output only. The "running state" of the Feature in this Hub.

=back

=head2 Google::Cloud::Gkehub::V1beta::Feature::MembershipFeatureSpec

MembershipFeatureSpec contains configuration information for a single
Membership.
NOTE: Please use snake case in your feature name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->configmanagement() >> / C<< $msg->configmanagement($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipSpec>)

Config Management-specific spec.

=item * C<< $msg->mesh() >> / C<< $msg->mesh($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipSpec>)

Anthos Service Mesh-specific spec

=item * C<< $msg->policycontroller() >> / C<< $msg->policycontroller($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipSpec>)

Policy Controller spec.

=back

=head2 Google::Cloud::Gkehub::V1beta::Feature::MembershipFeatureState

MembershipFeatureState contains Feature status information for a single
Membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->servicemesh() >> / C<< $msg->servicemesh($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState>)

Service Mesh-specific state.

=item * C<< $msg->metering() >> / C<< $msg->metering($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState>)

Metering-specific state.

=item * C<< $msg->configmanagement() >> / C<< $msg->configmanagement($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipState>)

Config Management-specific state.

=item * C<< $msg->policycontroller() >> / C<< $msg->policycontroller($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState>)

Policycontroller-specific state.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1beta::Feature::FeatureState>)

The high-level state of this Feature for a single membership.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::V1beta::Feature::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
