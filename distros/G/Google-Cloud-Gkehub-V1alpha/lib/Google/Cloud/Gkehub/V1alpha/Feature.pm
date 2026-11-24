package Google::Cloud::Gkehub::V1alpha::Feature;

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
    eval { require Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging };
    eval { require Google::Cloud::Gkehub::Configmanagement::V1alpha::Configmanagement };
    eval { require Google::Cloud::Gkehub::Metering::V1alpha::Metering };
    eval { require Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress };
    eval { require Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEvZmVhdHVyZS5wcm90bxIbZ29vZ2xlLmNs
b3VkLmdrZWh1Yi52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGkVnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEv
Y2xvdWRhdWRpdGxvZ2dpbmcvY2xvdWRhdWRpdGxvZ2dpbmcucHJvdG8aQ2dvb2dsZS9jbG91
ZC9na2VodWIvdjFhbHBoYS9jb25maWdtYW5hZ2VtZW50L2NvbmZpZ21hbmFnZW1lbnQucHJv
dG8aM2dvb2dsZS9jbG91ZC9na2VodWIvdjFhbHBoYS9tZXRlcmluZy9tZXRlcmluZy5wcm90
bxpJZ29vZ2xlL2Nsb3VkL2drZWh1Yi92MWFscGhhL211bHRpY2x1c3RlcmluZ3Jlc3MvbXVs
dGljbHVzdGVyaW5ncmVzcy5wcm90bxo5Z29vZ2xlL2Nsb3VkL2drZWh1Yi92MWFscGhhL3Nl
cnZpY2VtZXNoL3NlcnZpY2VtZXNoLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIowJCgdGZWF0dXJlEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJICgZsYWJlbHMY
AiADKAsyMC5nb29nbGUuY2xvdWQuZ2tlaHViLnYxYWxwaGEuRmVhdHVyZS5MYWJlbHNFbnRy
eVIGbGFiZWxzEl0KDnJlc291cmNlX3N0YXRlGAMgASgLMjEuZ29vZ2xlLmNsb3VkLmdrZWh1
Yi52MWFscGhhLkZlYXR1cmVSZXNvdXJjZVN0YXRlQgPgQQNSDXJlc291cmNlU3RhdGUSRwoE
c3BlYxgEIAEoCzIuLmdvb2dsZS5jbG91ZC5na2VodWIudjFhbHBoYS5Db21tb25GZWF0dXJl
U3BlY0ID4EEBUgRzcGVjEmkKEG1lbWJlcnNoaXBfc3BlY3MYBSADKAsyOS5nb29nbGUuY2xv
dWQuZ2tlaHViLnYxYWxwaGEuRmVhdHVyZS5NZW1iZXJzaGlwU3BlY3NFbnRyeUID4EEBUg9t
ZW1iZXJzaGlwU3BlY3MSSgoFc3RhdGUYBiABKAsyLy5nb29nbGUuY2xvdWQuZ2tlaHViLnYx
YWxwaGEuQ29tbW9uRmVhdHVyZVN0YXRlQgPgQQNSBXN0YXRlEmwKEW1lbWJlcnNoaXBfc3Rh
dGVzGAcgAygLMjouZ29vZ2xlLmNsb3VkLmdrZWh1Yi52MWFscGhhLkZlYXR1cmUuTWVtYmVy
c2hpcFN0YXRlc0VudHJ5QgPgQQNSEG1lbWJlcnNoaXBTdGF0ZXMSQAoLY3JlYXRlX3RpbWUY
CCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSQAoLZGVsZXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmRlbGV0ZVRpbWUaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARp2ChRNZW1iZXJzaGlwU3BlY3NFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRJICgV2YWx1ZRgCIAEoCzIyLmdvb2dsZS5jbG91ZC5na2VodWIudjFh
bHBoYS5NZW1iZXJzaGlwRmVhdHVyZVNwZWNSBXZhbHVlOgI4ARp4ChVNZW1iZXJzaGlwU3Rh
dGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSSQoFdmFsdWUYAiABKAsyMy5nb29nbGUuY2xv
dWQuZ2tlaHViLnYxYWxwaGEuTWVtYmVyc2hpcEZlYXR1cmVTdGF0ZVIFdmFsdWU6AjgBOl7q
QVsKHWdrZWh1Yi5nb29nbGVhcGlzLmNvbS9GZWF0dXJlEjpwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vZmVhdHVyZXMve2ZlYXR1cmV9ItIBChRGZWF0dXJlUmVz
b3VyY2VTdGF0ZRJNCgVzdGF0ZRgBIAEoDjI3Lmdvb2dsZS5jbG91ZC5na2VodWIudjFhbHBo
YS5GZWF0dXJlUmVzb3VyY2VTdGF0ZS5TdGF0ZVIFc3RhdGUiawoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIMCghFTkFCTElORxABEgoKBkFDVElWRRACEg0KCURJU0FCTElORxAD
EgwKCFVQREFUSU5HEAQSFAoQU0VSVklDRV9VUERBVElORxAFIu8BCgxGZWF0dXJlU3RhdGUS
QgoEY29kZRgBIAEoDjIuLmdvb2dsZS5jbG91ZC5na2VodWIudjFhbHBoYS5GZWF0dXJlU3Rh
dGUuQ29kZVIEY29kZRIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb24SOwoLdXBk
YXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1l
IjwKBENvZGUSFAoQQ09ERV9VTlNQRUNJRklFRBAAEgYKAk9LEAESCwoHV0FSTklORxACEgkK
BUVSUk9SEAMigQIKEUNvbW1vbkZlYXR1cmVTcGVjEnAKE211bHRpY2x1c3RlcmluZ3Jlc3MY
ZiABKAsyPC5nb29nbGUuY2xvdWQuZ2tlaHViLm11bHRpY2x1c3RlcmluZ3Jlc3MudjFhbHBo
YS5GZWF0dXJlU3BlY0gAUhNtdWx0aWNsdXN0ZXJpbmdyZXNzEmoKEWNsb3VkYXVkaXRsb2dn
aW5nGGwgASgLMjouZ29vZ2xlLmNsb3VkLmdrZWh1Yi5jbG91ZGF1ZGl0bG9nZ2luZy52MWFs
cGhhLkZlYXR1cmVTcGVjSABSEWNsb3VkYXVkaXRsb2dnaW5nQg4KDGZlYXR1cmVfc3BlYyLG
AQoSQ29tbW9uRmVhdHVyZVN0YXRlElkKC3NlcnZpY2VtZXNoGGQgASgLMjUuZ29vZ2xlLmNs
b3VkLmdrZWh1Yi5zZXJ2aWNlbWVzaC52MWFscGhhLkZlYXR1cmVTdGF0ZUgAUgtzZXJ2aWNl
bWVzaBJECgVzdGF0ZRgBIAEoCzIpLmdvb2dsZS5jbG91ZC5na2VodWIudjFhbHBoYS5GZWF0
dXJlU3RhdGVCA+BBA1IFc3RhdGVCDwoNZmVhdHVyZV9zdGF0ZSKTAQoVTWVtYmVyc2hpcEZl
YXR1cmVTcGVjEmoKEGNvbmZpZ21hbmFnZW1lbnQYaiABKAsyPC5nb29nbGUuY2xvdWQuZ2tl
aHViLmNvbmZpZ21hbmFnZW1lbnQudjFhbHBoYS5NZW1iZXJzaGlwU3BlY0gAUhBjb25maWdt
YW5hZ2VtZW50Qg4KDGZlYXR1cmVfc3BlYyKKAwoWTWVtYmVyc2hpcEZlYXR1cmVTdGF0ZRJc
CgtzZXJ2aWNlbWVzaBhkIAEoCzI4Lmdvb2dsZS5jbG91ZC5na2VodWIuc2VydmljZW1lc2gu
djFhbHBoYS5NZW1iZXJzaGlwU3RhdGVIAFILc2VydmljZW1lc2gSUwoIbWV0ZXJpbmcYaCAB
KAsyNS5nb29nbGUuY2xvdWQuZ2tlaHViLm1ldGVyaW5nLnYxYWxwaGEuTWVtYmVyc2hpcFN0
YXRlSABSCG1ldGVyaW5nEmsKEGNvbmZpZ21hbmFnZW1lbnQYaiABKAsyPS5nb29nbGUuY2xv
dWQuZ2tlaHViLmNvbmZpZ21hbmFnZW1lbnQudjFhbHBoYS5NZW1iZXJzaGlwU3RhdGVIAFIQ
Y29uZmlnbWFuYWdlbWVudBI/CgVzdGF0ZRgBIAEoCzIpLmdvb2dsZS5jbG91ZC5na2VodWIu
djFhbHBoYS5GZWF0dXJlU3RhdGVSBXN0YXRlQg8KDWZlYXR1cmVfc3RhdGVCxwEKH2NvbS5n
b29nbGUuY2xvdWQuZ2tlaHViLnYxYWxwaGFCDEZlYXR1cmVQcm90b1ABWjdjbG91ZC5nb29n
bGUuY29tL2dvL2drZWh1Yi9hcGl2MWFscGhhL2drZWh1YnBiO2drZWh1YnBiqgIbR29vZ2xl
LkNsb3VkLkdrZUh1Yi5WMUFscGhhygIbR29vZ2xlXENsb3VkXEdrZUh1YlxWMWFscGhh6gIe
R29vZ2xlOjpDbG91ZDo6R2tlSHViOjpWMWFscGhhSrg7CgcSBQ4A1gEBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFABPCgkKAgMDEgMVAE0KCQoCAwQSAxYAPQoJCgIDBRIDFwBTCgkKAgMGEgMY
AEMKCQoCAwcSAxkAKQoICgEIEgMbADgKCQoCCCUSAxsAOAoICgEIEgMcAE4KCQoCCAsSAxwA
TgoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeAC0KCQoCCAgSAx4ALQoICgEIEgMfADgK
CQoCCAESAx8AOAoICgEIEgMgADgKCQoCCCkSAyAAOAoICgEIEgMhADcKCQoCCC0SAyEANwpM
CgIEABIEJABiARpAIEZlYXR1cmUgcmVwcmVzZW50cyB0aGUgc2V0dGluZ3MgYW5kIHN0YXR1
cyBvZiBhbnkgSHViIEZlYXR1cmUuCgoKCgMEAAESAyQIDwoLCgMEAAcSBCUCKAQKDQoFBAAH
nQgSBCUCKAQKfgoEBAACABIDLAI+GnEgT3V0cHV0IG9ubHkuIFRoZSBmdWxsLCB1bmlxdWUg
bmFtZSBvZiB0aGlzIEZlYXR1cmUgcmVzb3VyY2UgaW4gdGhlIGZvcm1hdAogYHByb2plY3Rz
LyovbG9jYXRpb25zLyovZmVhdHVyZXMvKmAuCgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMs
CQ0KDAoFBAACAAMSAywQEQoMCgUEAAIACBIDLBI9Cg8KCAQAAgAInAgAEgMsEzwKKwoEBAAC
ARIDLwIhGh4gR0NQIGxhYmVscyBmb3IgdGhpcyBGZWF0dXJlLgoKDAoFBAACAQYSAy8CFQoM
CgUEAAIBARIDLxYcCgwKBQQAAgEDEgMvHyAKQQoEBAACAhIDMgJWGjQgT3V0cHV0IG9ubHku
IFN0YXRlIG9mIHRoZSBGZWF0dXJlIHJlc291cmNlIGl0c2VsZi4KCgwKBQQAAgIGEgMyAhYK
DAoFBAACAgESAzIXJQoMCgUEAAICAxIDMigpCgwKBQQAAgIIEgMyKlUKDwoIBAACAgicCAAS
AzIrVAqRAQoEBAACAxIDNgJGGoMBIE9wdGlvbmFsLiBIdWItd2lkZSBGZWF0dXJlIGNvbmZp
Z3VyYXRpb24uIElmIHRoaXMgRmVhdHVyZSBkb2VzIG5vdCBzdXBwb3J0IGFueQogSHViLXdp
ZGUgY29uZmlndXJhdGlvbiwgdGhpcyBmaWVsZCBtYXkgYmUgdW51c2VkLgoKDAoFBAACAwYS
AzYCEwoMCgUEAAIDARIDNhQYCgwKBQQAAgMDEgM2GxwKDAoFBAACAwgSAzYdRQoPCggEAAID
CJwIABIDNh5ECs0GCgQEAAIEEgNJAmMavwYgT3B0aW9uYWwuIE1lbWJlcnNoaXAtc3BlY2lm
aWMgY29uZmlndXJhdGlvbiBmb3IgdGhpcyBGZWF0dXJlLiBJZiB0aGlzIEZlYXR1cmUgZG9l
cwogbm90IHN1cHBvcnQgYW55IHBlci1NZW1iZXJzaGlwIGNvbmZpZ3VyYXRpb24sIHRoaXMg
ZmllbGQgbWF5IGJlIHVudXNlZC4KCiBUaGUga2V5cyBpbmRpY2F0ZSB3aGljaCBNZW1iZXJz
aGlwIHRoZSBjb25maWd1cmF0aW9uIGlzIGZvciwgaW4gdGhlIGZvcm06CgogICAgIHByb2pl
Y3RzL3twfS9sb2NhdGlvbnMve2x9L21lbWJlcnNoaXBzL3ttfQoKIFdoZXJlIHtwfSBpcyB0
aGUgcHJvamVjdCwge2x9IGlzIGEgdmFsaWQgbG9jYXRpb24gYW5kIHttfSBpcyBhIHZhbGlk
CiBNZW1iZXJzaGlwIGluIHRoaXMgcHJvamVjdCBhdCB0aGF0IGxvY2F0aW9uLiB7cH0gV0lM
TCBtYXRjaCB0aGUgRmVhdHVyZSdzCiBwcm9qZWN0LgoKIHtwfSB3aWxsIGFsd2F5cyBiZSBy
ZXR1cm5lZCBhcyB0aGUgcHJvamVjdCBudW1iZXIsIGJ1dCB0aGUgcHJvamVjdCBJRCBpcwog
YWxzbyBhY2NlcHRlZCBkdXJpbmcgaW5wdXQuIElmIHRoZSBzYW1lIE1lbWJlcnNoaXAgaXMg
c3BlY2lmaWVkIGluIHRoZSBtYXAKIHR3aWNlICh1c2luZyB0aGUgcHJvamVjdCBJRCBmb3Jt
LCBhbmQgdGhlIHByb2plY3QgbnVtYmVyIGZvcm0pLCBleGFjdGx5CiBPTkUgb2YgdGhlIGVu
dHJpZXMgd2lsbCBiZSBzYXZlZCwgd2l0aCBubyBndWFyYW50ZWVzIGFzIHRvIHdoaWNoLiBG
b3IgdGhpcwogcmVhc29uLCBpdCBpcyByZWNvbW1lbmRlZCB0aGUgc2FtZSBmb3JtYXQgYmUg
dXNlZCBmb3IgYWxsIGVudHJpZXMgd2hlbgogbXV0YXRpbmcgYSBGZWF0dXJlLgoKDAoFBAAC
BAYSA0kCJAoMCgUEAAIEARIDSSU1CgwKBQQAAgQDEgNJODkKDAoFBAACBAgSA0k6YgoPCggE
AAIECJwIABIDSTthCjcKBAQAAgUSA0wCSxoqIE91dHB1dCBvbmx5LiBUaGUgSHViLXdpZGUg
RmVhdHVyZSBzdGF0ZS4KCgwKBQQAAgUGEgNMAhQKDAoFBAACBQESA0wVGgoMCgUEAAIFAxID
TB0eCgwKBQQAAgUIEgNMH0oKDwoIBAACBQicCAASA0wgSQqxAwoEBAACBhIDWAJoGqMDIE91
dHB1dCBvbmx5LiBNZW1iZXJzaGlwLXNwZWNpZmljIEZlYXR1cmUgc3RhdHVzLiBJZiB0aGlz
IEZlYXR1cmUgZG9lcwogcmVwb3J0IGFueSBwZXItTWVtYmVyc2hpcCBzdGF0dXMsIHRoaXMg
ZmllbGQgbWF5IGJlIHVudXNlZC4KCiBUaGUga2V5cyBpbmRpY2F0ZSB3aGljaCBNZW1iZXJz
aGlwIHRoZSBzdGF0ZSBpcyBmb3IsIGluIHRoZSBmb3JtOgoKICAgICBwcm9qZWN0cy97cH0v
bG9jYXRpb25zL3tsfS9tZW1iZXJzaGlwcy97bX0KCiBXaGVyZSB7cH0gaXMgdGhlIHByb2pl
Y3QgbnVtYmVyLCB7bH0gaXMgYSB2YWxpZCBsb2NhdGlvbiBhbmQge219IGlzIGEgdmFsaWQK
IE1lbWJlcnNoaXAgaW4gdGhpcyBwcm9qZWN0IGF0IHRoYXQgbG9jYXRpb24uIHtwfSBNVVNU
IG1hdGNoIHRoZSBGZWF0dXJlJ3MKIHByb2plY3QgbnVtYmVyLgoKDAoFBAACBgYSA1gCJQoM
CgUEAAIGARIDWCY3CgwKBQQAAgYDEgNYOjsKDAoFBAACBggSA1g8ZwoPCggEAAIGCJwIABID
WD1mCkIKBAQAAgcSA1sCWBo1IE91dHB1dCBvbmx5LiBXaGVuIHRoZSBGZWF0dXJlIHJlc291
cmNlIHdhcyBjcmVhdGVkLgoKDAoFBAACBwYSA1sCGwoMCgUEAAIHARIDWxwnCgwKBQQAAgcD
EgNbKisKDAoFBAACBwgSA1ssVwoPCggEAAIHCJwIABIDWy1WCkcKBAQAAggSA14CWBo6IE91
dHB1dCBvbmx5LiBXaGVuIHRoZSBGZWF0dXJlIHJlc291cmNlIHdhcyBsYXN0IHVwZGF0ZWQu
CgoMCgUEAAIIBhIDXgIbCgwKBQQAAggBEgNeHCcKDAoFBAACCAMSA14qKwoMCgUEAAIICBID
XixXCg8KCAQAAggInAgAEgNeLVYKQgoEBAACCRIDYQJZGjUgT3V0cHV0IG9ubHkuIFdoZW4g
dGhlIEZlYXR1cmUgcmVzb3VyY2Ugd2FzIGRlbGV0ZWQuCgoMCgUEAAIJBhIDYQIbCgwKBQQA
AgkBEgNhHCcKDAoFBAACCQMSA2EqLAoMCgUEAAIJCBIDYS1YCg8KCAQAAgkInAgAEgNhLlcK
wgEKAgQBEgVnAIIBARq0ASBGZWF0dXJlUmVzb3VyY2VTdGF0ZSBkZXNjcmliZXMgdGhlIHN0
YXRlIG9mIGEgRmVhdHVyZSAqcmVzb3VyY2UqIGluIHRoZQogR2tlSHViIEFQSS4gU2VlIGBG
ZWF0dXJlU3RhdGVgIGZvciB0aGUgInJ1bm5pbmcgc3RhdGUiIG9mIHRoZSBGZWF0dXJlIGlu
IHRoZQogSHViIGFuZCBhY3Jvc3MgTWVtYmVyc2hpcHMuCgoKCgMEAQESA2cIHApCCgQEAQQA
EgRpAn4DGjQgU3RhdGUgZGVzY3JpYmVzIHRoZSBsaWZlY3ljbGUgc3RhdHVzIG9mIGEgRmVh
dHVyZS4KCgwKBQQBBAABEgNpBwwKLQoGBAEEAAIAEgNrBBoaHiBTdGF0ZSBpcyB1bmtub3du
IG9yIG5vdCBzZXQuCgoOCgcEAQQAAgABEgNrBBUKDgoHBAEEAAIAAhIDaxgZCqEBCgYEAQQA
AgESA28EERqRASBUaGUgRmVhdHVyZSBpcyBiZWluZyBlbmFibGVkLCBhbmQgdGhlIEZlYXR1
cmUgcmVzb3VyY2UgaXMgYmVpbmcgY3JlYXRlZC4KIE9uY2UgY29tcGxldGUsIHRoZSBjb3Jy
ZXNwb25kaW5nIEZlYXR1cmUgd2lsbCBiZSBlbmFibGVkIGluIHRoaXMgSHViLgoKDgoHBAEE
AAIBARIDbwQMCg4KBwQBBAACAQISA28PEApiCgYEAQQAAgISA3MEDxpTIFRoZSBGZWF0dXJl
IGlzIGVuYWJsZWQgaW4gdGhpcyBIdWIsIGFuZCB0aGUgRmVhdHVyZSByZXNvdXJjZSBpcyBm
dWxseQogYXZhaWxhYmxlLgoKDgoHBAEEAAICARIDcwQKCg4KBwQBBAACAgISA3MNDgpnCgYE
AQQAAgMSA3cEEhpYIFRoZSBGZWF0dXJlIGlzIGJlaW5nIGRpc2FibGVkIGluIHRoaXMgSHVi
LCBhbmQgdGhlIEZlYXR1cmUgcmVzb3VyY2UKIGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAQQA
AgMBEgN3BA0KDgoHBAEEAAIDAhIDdxARCjcKBgQBBAACBBIDegQRGiggVGhlIEZlYXR1cmUg
cmVzb3VyY2UgaXMgYmVpbmcgdXBkYXRlZC4KCg4KBwQBBAACBAESA3oEDAoOCgcEAQQAAgQC
EgN6DxAKSgoGBAEEAAIFEgN9BBkaOyBUaGUgRmVhdHVyZSByZXNvdXJjZSBpcyBiZWluZyB1
cGRhdGVkIGJ5IHRoZSBIdWIgU2VydmljZS4KCg4KBwQBBAACBQESA30EFAoOCgcEAQQAAgUC
EgN9FxgKSQoEBAECABIEgQECEho7IFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBGZWF0dXJl
IHJlc291cmNlIGluIHRoZSBIdWIgQVBJLgoKDQoFBAECAAYSBIEBAgcKDQoFBAECAAESBIEB
CA0KDQoFBAECAAMSBIEBEBEKvAEKAgQCEgaHAQClAQEarQEgRmVhdHVyZVN0YXRlIGRlc2Ny
aWJlcyB0aGUgaGlnaC1sZXZlbCBzdGF0ZSBvZiBhIEZlYXR1cmUuIEl0IG1heSBiZSB1c2Vk
IHRvCiBkZXNjcmliZSBhIEZlYXR1cmUncyBzdGF0ZSBhdCB0aGUgZW52aXJvbi1sZXZlbCwg
b3IgcGVyLW1lbWJlcnNob3AsIGRlcGVuZGluZwogb24gdGhlIGNvbnRleHQuCgoLCgMEAgES
BIcBCBQKVwoEBAIEABIGiQECmwEDGkcgQ29kZSByZXByZXNlbnRzIGEgbWFjaGluZS1yZWFk
YWJsZSwgaGlnaC1sZXZlbCBzdGF0dXMgb2YgdGhlIEZlYXR1cmUuCgoNCgUEAgQAARIEiQEH
CwolCgYEAgQAAgASBIsBBBkaFSBVbmtub3duIG9yIG5vdCBzZXQuCgoPCgcEAgQAAgABEgSL
AQQUCg8KBwQCBAACAAISBIsBFxgKNAoGBAIEAAIBEgSOAQQLGiQgVGhlIEZlYXR1cmUgaXMg
b3BlcmF0aW5nIG5vcm1hbGx5LgoKDwoHBAIEAAIBARIEjgEEBgoPCgcEAgQAAgECEgSOAQkK
CvgBCgYEAgQAAgISBJQBBBAa5wEgVGhlIEZlYXR1cmUgaGFzIGVuY291bnRlcmVkIGFuIGlz
c3VlLCBhbmQgaXMgb3BlcmF0aW5nIGluIGEgZGVncmFkZWQKIHN0YXRlLiBUaGUgRmVhdHVy
ZSBtYXkgbmVlZCBpbnRlcnZlbnRpb24gdG8gcmV0dXJuIHRvIG5vcm1hbCBvcGVyYXRpb24u
CiBTZWUgdGhlIGRlc2NyaXB0aW9uIGFuZCBhbnkgYXNzb2NpYXRlZCBGZWF0dXJlLXNwZWNp
ZmljIGRldGFpbHMgZm9yIG1vcmUKIGluZm9ybWF0aW9uLgoKDwoHBAIEAAICARIElAEECwoP
CgcEAgQAAgICEgSUAQ4PCu0BCgYEAgQAAgMSBJoBBA4a3AEgVGhlIEZlYXR1cmUgaXMgbm90
IG9wZXJhdGluZyBvciBpcyBpbiBhIHNldmVyZWx5IGRlZ3JhZGVkIHN0YXRlLgogVGhlIEZl
YXR1cmUgbWF5IG5lZWQgaW50ZXJ2ZW50aW9uIHRvIHJldHVybiB0byBub3JtYWwgb3BlcmF0
aW9uLgogU2VlIHRoZSBkZXNjcmlwdGlvbiBhbmQgYW55IGFzc29jaWF0ZWQgRmVhdHVyZS1z
cGVjaWZpYyBkZXRhaWxzIGZvciBtb3JlCiBpbmZvcm1hdGlvbi4KCg8KBwQCBAACAwESBJoB
BAkKDwoHBAIEAAIDAhIEmgEMDQpICgQEAgIAEgSeAQIQGjogVGhlIGhpZ2gtbGV2ZWwsIG1h
Y2hpbmUtcmVhZGFibGUgc3RhdHVzIG9mIHRoaXMgRmVhdHVyZS4KCg0KBQQCAgAGEgSeAQIG
Cg0KBQQCAgABEgSeAQcLCg0KBQQCAgADEgSeAQ4PCkMKBAQCAgESBKEBAhkaNSBBIGh1bWFu
LXJlYWRhYmxlIGRlc2NyaXB0aW9uIG9mIHRoZSBjdXJyZW50IHN0YXR1cy4KCg0KBQQCAgEF
EgShAQIICg0KBQQCAgEBEgShAQkUCg0KBQQCAgEDEgShARcYClsKBAQCAgISBKQBAiwaTSBU
aGUgdGltZSB0aGlzIHN0YXR1cyBhbmQgYW55IHJlbGF0ZWQgRmVhdHVyZS1zcGVjaWZpYyBk
ZXRhaWxzIHdlcmUgdXBkYXRlZC4KCg0KBQQCAgIGEgSkAQIbCg0KBQQCAgIBEgSkARwnCg0K
BQQCAgIDEgSkASorCk0KAgQDEgaoAQCwAQEaPyBDb21tb25GZWF0dXJlU3BlYyBjb250YWlu
cyBIdWItd2lkZSBjb25maWd1cmF0aW9uIGluZm9ybWF0aW9uCgoLCgMEAwESBKgBCBkKDgoE
BAMIABIGqQECrwEDCg0KBQQDCAABEgSpAQgUCjMKBAQDAgASBKsBBFoaJSBNdWx0aWNsdXN0
ZXIgSW5ncmVzcy1zcGVjaWZpYyBzcGVjLgoKDQoFBAMCAAYSBKsBBD8KDQoFBAMCAAESBKsB
QFMKDQoFBAMCAAMSBKsBVlkKMgoEBAMCARIErgEEVhokIENsb3VkIEF1ZGl0IExvZ2dpbmct
c3BlY2lmaWMgc3BlYy4KCg0KBQQDAgEGEgSuAQQ9Cg0KBQQDAgEBEgSuAT5PCg0KBQQDAgED
EgSuAVJVClAKAgQEEgazAQC7AQEaQiBDb21tb25GZWF0dXJlU3RhdGUgY29udGFpbnMgSHVi
LXdpZGUgRmVhdHVyZSBzdGF0dXMgaW5mb3JtYXRpb24uCgoLCgMEBAESBLMBCBoKDgoEBAQI
ABIGtAECtwEDCg0KBQQECAABEgS0AQgVCiwKBAQEAgASBLYBBEsaHiBTZXJ2aWNlIE1lc2gt
c3BlY2lmaWMgc3RhdGUuCgoNCgUEBAIABhIEtgEEOAoNCgUEBAIAARIEtgE5RAoNCgUEBAIA
AxIEtgFHSgpMCgQEBAIBEgS6AQJFGj4gT3V0cHV0IG9ubHkuIFRoZSAicnVubmluZyBzdGF0
ZSIgb2YgdGhlIEZlYXR1cmUgaW4gdGhpcyBIdWIuCgoNCgUEBAIBBhIEugECDgoNCgUEBAIB
ARIEugEPFAoNCgUEBAIBAxIEugEXGAoNCgUEBAIBCBIEugEZRAoQCggEBAIBCJwIABIEugEa
QwpiCgIEBRIGvwEAxAEBGlQgTWVtYmVyc2hpcEZlYXR1cmVTcGVjIGNvbnRhaW5zIGNvbmZp
Z3VyYXRpb24gaW5mb3JtYXRpb24gZm9yIGEgc2luZ2xlCiBNZW1iZXJzaGlwLgoKCwoDBAUB
EgS/AQgdCg4KBAQFCAASBsABAsMBAwoNCgUEBQgAARIEwAEIFAowCgQEBQIAEgTCAQRXGiIg
Q29uZmlnIE1hbmFnZW1lbnQtc3BlY2lmaWMgc3BlYy4KCg0KBQQFAgAGEgTCAQQ/Cg0KBQQF
AgABEgTCAUBQCg0KBQQFAgADEgTCAVNWCmQKAgQGEgbIAQDWAQEaViBNZW1iZXJzaGlwRmVh
dHVyZVN0YXRlIGNvbnRhaW5zIEZlYXR1cmUgc3RhdHVzIGluZm9ybWF0aW9uIGZvciBhIHNp
bmdsZQogTWVtYmVyc2hpcC4KCgsKAwQGARIEyAEIHgoOCgQEBggAEgbJAQLSAQMKDQoFBAYI
AAESBMkBCBUKLAoEBAYCABIEywEEThoeIFNlcnZpY2UgTWVzaC1zcGVjaWZpYyBzdGF0ZS4K
Cg0KBQQGAgAGEgTLAQQ7Cg0KBQQGAgABEgTLATxHCg0KBQQGAgADEgTLAUpNCicKBAQGAgES
BM4BBEgaGSBNZXRlcmluZy1zcGVjaWZpYyBzcGVjLgoKDQoFBAYCAQYSBM4BBDgKDQoFBAYC
AQESBM4BOUEKDQoFBAYCAQMSBM4BREcKMQoEBAYCAhIE0QEEWBojIENvbmZpZyBNYW5hZ2Vt
ZW50LXNwZWNpZmljIHN0YXRlLgoKDQoFBAYCAgYSBNEBBEAKDQoFBAYCAgESBNEBQVEKDQoF
BAYCAgMSBNEBVFcKTQoEBAYCAxIE1QECGRo/IFRoZSBoaWdoLWxldmVsIHN0YXRlIG9mIHRo
aXMgRmVhdHVyZSBmb3IgYSBzaW5nbGUgbWVtYmVyc2hpcC4KCg0KBQQGAgMGEgTVAQIOCg0K
BQQGAgMBEgTVAQ8UCg0KBQQGAgMDEgTVARcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::Feature ===
    # Fields for Feature
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkehub.v1alpha.Feature.LabelsEntry)
    # Field: resource_state Type: 11 (.google.cloud.gkehub.v1alpha.FeatureResourceState)
    # Field: spec Type: 11 (.google.cloud.gkehub.v1alpha.CommonFeatureSpec)
    # Field: membership_specs Type: 11 (.google.cloud.gkehub.v1alpha.Feature.MembershipSpecsEntry)
    # Field: state Type: 11 (.google.cloud.gkehub.v1alpha.CommonFeatureState)
    # Field: membership_states Type: 11 (.google.cloud.gkehub.v1alpha.Feature.MembershipStatesEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::FeatureResourceState ===
    # Fields for FeatureResourceState
    # Field: state Type: 14 (.google.cloud.gkehub.v1alpha.FeatureResourceState.State)

# Enum: FeatureResourceState::State
our $FeatureResourceState_STATE_UNSPECIFIED = 0;
our $FeatureResourceState_ENABLING = 1;
our $FeatureResourceState_ACTIVE = 2;
our $FeatureResourceState_DISABLING = 3;
our $FeatureResourceState_UPDATING = 4;
our $FeatureResourceState_SERVICE_UPDATING = 5;

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::FeatureState ===
    # Fields for FeatureState
    # Field: code Type: 14 (.google.cloud.gkehub.v1alpha.FeatureState.Code)
    # Field: description Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: FeatureState::Code
our $FeatureState_CODE_UNSPECIFIED = 0;
our $FeatureState_OK = 1;
our $FeatureState_WARNING = 2;
our $FeatureState_ERROR = 3;

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::CommonFeatureSpec ===
    # Fields for CommonFeatureSpec
    # Field: multiclusteringress Type: 11 (.google.cloud.gkehub.multiclusteringress.v1alpha.FeatureSpec)
    # Field: cloudauditlogging Type: 11 (.google.cloud.gkehub.cloudauditlogging.v1alpha.FeatureSpec)

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::CommonFeatureState ===
    # Fields for CommonFeatureState
    # Field: servicemesh Type: 11 (.google.cloud.gkehub.servicemesh.v1alpha.FeatureState)
    # Field: state Type: 11 (.google.cloud.gkehub.v1alpha.FeatureState)

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::MembershipFeatureSpec ===
    # Fields for MembershipFeatureSpec
    # Field: configmanagement Type: 11 (.google.cloud.gkehub.configmanagement.v1alpha.MembershipSpec)

# === Message: Google::Cloud::Gkehub::V1alpha::Feature::MembershipFeatureState ===
    # Fields for MembershipFeatureState
    # Field: servicemesh Type: 11 (.google.cloud.gkehub.servicemesh.v1alpha.MembershipState)
    # Field: metering Type: 11 (.google.cloud.gkehub.metering.v1alpha.MembershipState)
    # Field: configmanagement Type: 11 (.google.cloud.gkehub.configmanagement.v1alpha.MembershipState)
    # Field: state Type: 11 (.google.cloud.gkehub.v1alpha.FeatureState)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::V1alpha::Feature - Compiled Protocol Buffers messages for google/cloud/gkehub/v1alpha/feature.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::V1alpha::Feature;

    my $msg = Google::Cloud::Gkehub::V1alpha::Feature::Feature->new({
        name => $name,
        labels => $labels,
        resource_state => $resource_state,
        spec => $spec,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::V1alpha::Feature::Feature->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1alpha/feature.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::V1alpha::Feature::Feature

Feature represents the settings and status of any Hub Feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full, unique name of this Feature resource in the format
`projects/*/locations/*/features/*`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::Feature::LabelsEntry>)

GCP labels for this Feature.

=item * C<< $msg->resource_state() >> / C<< $msg->resource_state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::FeatureResourceState>)

Output only. State of the Feature resource itself.

=item * C<< $msg->spec() >> / C<< $msg->spec($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::CommonFeatureSpec>)

Optional. Hub-wide Feature configuration. If this Feature does not support any
Hub-wide configuration, this field may be unused.

=item * C<< $msg->membership_specs() >> / C<< $msg->membership_specs($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::Feature::MembershipSpecsEntry>)

Optional. Membership-specific configuration for this Feature. If this Feature does
not support any per-Membership configuration, this field may be unused.

The keys indicate which Membership the configuration is for, in the form:

    projects/{p}/locations/{l}/memberships/{m}

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

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::CommonFeatureState>)

Output only. The Hub-wide Feature state.

=item * C<< $msg->membership_states() >> / C<< $msg->membership_states($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::Feature::MembershipStatesEntry>)

Output only. Membership-specific Feature status. If this Feature does
report any per-Membership status, this field may be unused.

The keys indicate which Membership the state is for, in the form:

    projects/{p}/locations/{l}/memberships/{m}

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

=head2 Google::Cloud::Gkehub::V1alpha::Feature::FeatureResourceState

FeatureResourceState describes the state of a Feature *resource* in the
GkeHub API. See `FeatureState` for the "running state" of the Feature in the
Hub and across Memberships.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1alpha::FeatureResourceState::State>)

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

=head2 Google::Cloud::Gkehub::V1alpha::Feature::FeatureState

FeatureState describes the high-level state of a Feature. It may be used to
describe a Feature's state at the environ-level, or per-membershop, depending
on the context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::V1alpha::FeatureState::Code>)

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

=head2 Google::Cloud::Gkehub::V1alpha::Feature::CommonFeatureSpec

CommonFeatureSpec contains Hub-wide configuration information

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->multiclusteringress() >> / C<< $msg->multiclusteringress($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Multiclusteringress::V1alpha::Multiclusteringress::FeatureSpec>)

Multicluster Ingress-specific spec.

=item * C<< $msg->cloudauditlogging() >> / C<< $msg->cloudauditlogging($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging::FeatureSpec>)

Cloud Audit Logging-specific spec.

=back

=head2 Google::Cloud::Gkehub::V1alpha::Feature::CommonFeatureState

CommonFeatureState contains Hub-wide Feature status information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->servicemesh() >> / C<< $msg->servicemesh($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState>)

Service Mesh-specific state.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::FeatureState>)

Output only. The "running state" of the Feature in this Hub.

=back

=head2 Google::Cloud::Gkehub::V1alpha::Feature::MembershipFeatureSpec

MembershipFeatureSpec contains configuration information for a single
Membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->configmanagement() >> / C<< $msg->configmanagement($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Configmanagement::V1alpha::Configmanagement::MembershipSpec>)

Config Management-specific spec.

=back

=head2 Google::Cloud::Gkehub::V1alpha::Feature::MembershipFeatureState

MembershipFeatureState contains Feature status information for a single
Membership.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->servicemesh() >> / C<< $msg->servicemesh($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::MembershipState>)

Service Mesh-specific state.

=item * C<< $msg->metering() >> / C<< $msg->metering($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Metering::V1alpha::Metering::MembershipState>)

Metering-specific spec.

=item * C<< $msg->configmanagement() >> / C<< $msg->configmanagement($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Configmanagement::V1alpha::Configmanagement::MembershipState>)

Config Management-specific state.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::V1alpha::Feature::FeatureState>)

The high-level state of this Feature for a single membership.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::V1alpha::Feature::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
