package Google::Cloud::Retail::V2alpha::UserEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Retail::V2alpha::Common };
    eval { require Google::Cloud::Retail::V2alpha::Product };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvdXNlcl9ldmVudC5wcm90bxIbZ29vZ2xl
LmNsb3VkLnJldGFpbC52MmFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Gihnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvY29tbW9uLnByb3RvGilnb29nbGUvY2xv
dWQvcmV0YWlsL3YyYWxwaGEvcHJvZHVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnByb3RvIr8ICglVc2VyRXZl
bnQSIgoKZXZlbnRfdHlwZRgBIAEoCUID4EECUglldmVudFR5cGUSIgoKdmlzaXRvcl9pZBgC
IAEoCUID4EECUgl2aXNpdG9ySWQSHQoKc2Vzc2lvbl9pZBgVIAEoCVIJc2Vzc2lvbklkEjkK
CmV2ZW50X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglldmVudFRp
bWUSJQoOZXhwZXJpbWVudF9pZHMYBCADKAlSDWV4cGVyaW1lbnRJZHMSKwoRYXR0cmlidXRp
b25fdG9rZW4YBSABKAlSEGF0dHJpYnV0aW9uVG9rZW4SUwoPcHJvZHVjdF9kZXRhaWxzGAYg
AygLMiouZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlByb2R1Y3REZXRhaWxSDnByb2R1
Y3REZXRhaWxzEloKEWNvbXBsZXRpb25fZGV0YWlsGBYgASgLMi0uZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLkNvbXBsZXRpb25EZXRhaWxSEGNvbXBsZXRpb25EZXRhaWwSVgoKYXR0
cmlidXRlcxgHIAMoCzI2Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Vc2VyRXZlbnQu
QXR0cmlidXRlc0VudHJ5UgphdHRyaWJ1dGVzEhcKB2NhcnRfaWQYCCABKAlSBmNhcnRJZBJj
ChRwdXJjaGFzZV90cmFuc2FjdGlvbhgJIAEoCzIwLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5QdXJjaGFzZVRyYW5zYWN0aW9uUhNwdXJjaGFzZVRyYW5zYWN0aW9uEiEKDHNlYXJj
aF9xdWVyeRgKIAEoCVILc2VhcmNoUXVlcnkSFgoGZmlsdGVyGBAgASgJUgZmaWx0ZXISGQoI
b3JkZXJfYnkYESABKAlSB29yZGVyQnkSFgoGb2Zmc2V0GBIgASgFUgZvZmZzZXQSJwoPcGFn
ZV9jYXRlZ29yaWVzGAsgAygJUg5wYWdlQ2F0ZWdvcmllcxJCCgl1c2VyX2luZm8YDCABKAsy
JS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVXNlckluZm9SCHVzZXJJbmZvEhAKA3Vy
aRgNIAEoCVIDdXJpEiEKDHJlZmVycmVyX3VyaRgOIAEoCVILcmVmZXJyZXJVcmkSIAoMcGFn
ZV92aWV3X2lkGA8gASgJUgpwYWdlVmlld0lkEhYKBmVudGl0eRgXIAEoCVIGZW50aXR5GmsK
D0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJCCgV2YWx1ZRgCIAEoCzIsLmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5DdXN0b21BdHRyaWJ1dGVSBXZhbHVlOgI4ASKN
AQoNUHJvZHVjdERldGFpbBJDCgdwcm9kdWN0GAEgASgLMiQuZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmFscGhhLlByb2R1Y3RCA+BBAlIHcHJvZHVjdBI3CghxdWFudGl0eRgCIAEoCzIbLmdv
b2dsZS5wcm90b2J1Zi5JbnQzMlZhbHVlUghxdWFudGl0eSKyAQoQQ29tcGxldGlvbkRldGFp
bBJAChxjb21wbGV0aW9uX2F0dHJpYnV0aW9uX3Rva2VuGAEgASgJUhpjb21wbGV0aW9uQXR0
cmlidXRpb25Ub2tlbhIvChNzZWxlY3RlZF9zdWdnZXN0aW9uGAIgASgJUhJzZWxlY3RlZFN1
Z2dlc3Rpb24SKwoRc2VsZWN0ZWRfcG9zaXRpb24YAyABKAVSEHNlbGVjdGVkUG9zaXRpb24i
lAEKE1B1cmNoYXNlVHJhbnNhY3Rpb24SDgoCaWQYASABKAlSAmlkEh0KB3JldmVudWUYAiAB
KAJCA+BBAlIHcmV2ZW51ZRIQCgN0YXgYAyABKAJSA3RheBISCgRjb3N0GAQgASgCUgRjb3N0
EigKDWN1cnJlbmN5X2NvZGUYBSABKAlCA+BBAlIMY3VycmVuY3lDb2RlQtIBCh9jb20uZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhQg5Vc2VyRXZlbnRQcm90b1ABWjdjbG91ZC5nb29n
bGUuY29tL2dvL3JldGFpbC9hcGl2MmFscGhhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlM
qgIbR29vZ2xlLkNsb3VkLlJldGFpbC5WMkFscGhhygIbR29vZ2xlXENsb3VkXFJldGFpbFxW
MmFscGhh6gIeR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMmFscGhhSqV0CgcSBQ4A4AIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkK
CQoCAwESAxMAMgoJCgIDAhIDFAAzCgkKAgMDEgMVACkKCQoCAwQSAxYAKAoICgEIEgMYADgK
CQoCCCUSAxgAOAoICgEIEgMZAE4KCQoCCAsSAxkATgoICgEIEgMaACIKCQoCCAoSAxoAIgoI
CgEIEgMbAC8KCQoCCAgSAxsALwoICgEIEgMcADgKCQoCCAESAxwAOAoICgEIEgMdACQKCQoC
CCQSAx0AJAoICgEIEgMeADgKCQoCCCkSAx4AOAoICgEIEgMfADcKCQoCCC0SAx8ANwqKAQoC
BAASBSMAlgIBGn0gVXNlckV2ZW50IGNhcHR1cmVzIGFsbCBtZXRhZGF0YSBpbmZvcm1hdGlv
biBSZXRhaWwgQVBJIG5lZWRzIHRvIGtub3cgYWJvdXQKIGhvdyBlbmQgdXNlcnMgaW50ZXJh
Y3Qgd2l0aCBjdXN0b21lcnMnIHdlYnNpdGUuCgoKCgMEAAESAyMIEQrgAwoEBAACABIDLwJB
GtIDIFJlcXVpcmVkLiBVc2VyIGV2ZW50IHR5cGUuIEFsbG93ZWQgdmFsdWVzIGFyZToKCiAq
IGBhZGQtdG8tY2FydGA6IFByb2R1Y3RzIGJlaW5nIGFkZGVkIHRvIGNhcnQuCiAqIGByZW1v
dmUtZnJvbS1jYXJ0YDogUHJvZHVjdHMgYmVpbmcgcmVtb3ZlZCBmcm9tIGNhcnQuCiAqIGBj
YXRlZ29yeS1wYWdlLXZpZXdgOiBTcGVjaWFsIHBhZ2VzIHN1Y2ggYXMgc2FsZSBvciBwcm9t
b3Rpb24gcGFnZXMKICAgdmlld2VkLgogKiBgZGV0YWlsLXBhZ2Utdmlld2A6IFByb2R1Y3Rz
IGRldGFpbCBwYWdlIHZpZXdlZC4KICogYGhvbWUtcGFnZS12aWV3YDogSG9tZXBhZ2Ugdmll
d2VkLgogKiBgcHVyY2hhc2UtY29tcGxldGVgOiBVc2VyIGZpbmlzaGluZyBhIHB1cmNoYXNl
LgogKiBgc2VhcmNoYDogUHJvZHVjdCBzZWFyY2guCiAqIGBzaG9wcGluZy1jYXJ0LXBhZ2Ut
dmlld2A6IFVzZXIgdmlld2luZyBhIHNob3BwaW5nIGNhcnQuCgoMCgUEAAIABRIDLwIICgwK
BQQAAgABEgMvCRMKDAoFBAACAAMSAy8WFwoMCgUEAAIACBIDLxhACg8KCAQAAgAInAgAEgMv
GT8KnQYKBAQAAgESA0ICQRqPBiBSZXF1aXJlZC4gQSB1bmlxdWUgaWRlbnRpZmllciBmb3Ig
dHJhY2tpbmcgdmlzaXRvcnMuCgogRm9yIGV4YW1wbGUsIHRoaXMgY291bGQgYmUgaW1wbGVt
ZW50ZWQgd2l0aCBhbiBIVFRQIGNvb2tpZSwgd2hpY2ggc2hvdWxkIGJlCiBhYmxlIHRvIHVu
aXF1ZWx5IGlkZW50aWZ5IGEgdmlzaXRvciBvbiBhIHNpbmdsZSBkZXZpY2UuIFRoaXMgdW5p
cXVlCiBpZGVudGlmaWVyIHNob3VsZCBub3QgY2hhbmdlIGlmIHRoZSB2aXNpdG9yIGxvZyBp
bi9vdXQgb2YgdGhlIHdlYnNpdGUuCgogRG9uJ3Qgc2V0IHRoZSBmaWVsZCB0byB0aGUgc2Ft
ZSBmaXhlZCBJRCBmb3IgZGlmZmVyZW50IHVzZXJzLiBUaGlzIG1peGVzCiB0aGUgZXZlbnQg
aGlzdG9yeSBvZiB0aG9zZSB1c2VycyB0b2dldGhlciwgd2hpY2ggcmVzdWx0cyBpbiBkZWdy
YWRlZCBtb2RlbAogcXVhbGl0eS4KCiBUaGUgZmllbGQgbXVzdCBiZSBhIFVURi04IGVuY29k
ZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTI4CiBjaGFyYWN0ZXJzLiBPdGhl
cndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhlIGZp
ZWxkIHNob3VsZCBub3QgY29udGFpbiBQSUkgb3IgdXNlci1kYXRhLiBXZSByZWNvbW1lbmQg
dG8gdXNlIEdvb2dsZQogQW5hbHl0aWNzIFtDbGllbnQKIElEXShodHRwczovL2RldmVsb3Bl
cnMuZ29vZ2xlLmNvbS9hbmFseXRpY3MvZGV2Z3VpZGVzL2NvbGxlY3Rpb24vYW5hbHl0aWNz
anMvZmllbGQtcmVmZXJlbmNlI2NsaWVudElkKQogZm9yIHRoaXMgZmllbGQuCgoMCgUEAAIB
BRIDQgIICgwKBQQAAgEBEgNCCRMKDAoFBAACAQMSA0IWFwoMCgUEAAIBCBIDQhhACg8KCAQA
AgEInAgAEgNCGT8KiQMKBAQAAgISA0wCGRr7AiBBIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0
cmFja2luZyBhIHZpc2l0b3Igc2Vzc2lvbiB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mCiAxMjgg
Ynl0ZXMuIEEgc2Vzc2lvbiBpcyBhbiBhZ2dyZWdhdGlvbiBvZiBhbiBlbmQgdXNlciBiZWhh
dmlvciBpbiBhIHRpbWUKIHNwYW4uCgogQSBnZW5lcmFsIGd1aWRlbGluZSB0byBwb3B1bGF0
ZSB0aGUgc2VzaW9uX2lkOgogMS4gSWYgdXNlciBoYXMgbm8gYWN0aXZpdHkgZm9yIDMwIG1p
biwgYSBuZXcgc2Vzc2lvbl9pZCBzaG91bGQgYmUgYXNzaWduZWQuCiAyLiBUaGUgc2Vzc2lv
bl9pZCBzaG91bGQgYmUgdW5pcXVlIGFjcm9zcyB1c2Vycywgc3VnZ2VzdCB1c2UgdXVpZCBv
ciBhZGQKIHZpc2l0b3JfaWQgYXMgcHJlZml4LgoKDAoFBAACAgUSA0wCCAoMCgUEAAICARID
TAkTCgwKBQQAAgIDEgNMFhgKuQEKBAQAAgMSA1ECKxqrASBPbmx5IHJlcXVpcmVkIGZvcgog
W1VzZXJFdmVudFNlcnZpY2UuSW1wb3J0VXNlckV2ZW50c11bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmFscGhhLlVzZXJFdmVudFNlcnZpY2UuSW1wb3J0VXNlckV2ZW50c10KIG1ldGhvZC4g
VGltZXN0YW1wIG9mIHdoZW4gdGhlIHVzZXIgZXZlbnQgaGFwcGVuZWQuCgoMCgUEAAIDBhID
UQIbCgwKBQQAAgMBEgNRHCYKDAoFBAACAwMSA1EpKgqGAgoEBAACBBIDVwIlGvgBIEEgbGlz
dCBvZiBpZGVudGlmaWVycyBmb3IgdGhlIGluZGVwZW5kZW50IGV4cGVyaW1lbnQgZ3JvdXBz
IHRoaXMgdXNlciBldmVudAogYmVsb25ncyB0by4gVGhpcyBpcyB1c2VkIHRvIGRpc3Rpbmd1
aXNoIGJldHdlZW4gdXNlciBldmVudHMgYXNzb2NpYXRlZCB3aXRoCiBkaWZmZXJlbnQgZXhw
ZXJpbWVudCBzZXR1cHMgKGUuZy4gdXNpbmcgUmV0YWlsIEFQSSwgdXNpbmcgZGlmZmVyZW50
CiByZWNvbW1lbmRhdGlvbiBtb2RlbHMpLgoKDAoFBAACBAQSA1cCCgoMCgUEAAIEBRIDVwsR
CgwKBQQAAgQBEgNXEiAKDAoFBAACBAMSA1cjJAr5CQoEBAACBRIDcAIfGusJIEhpZ2hseSBy
ZWNvbW1lbmRlZCBmb3IgdXNlciBldmVudHMgdGhhdCBhcmUgdGhlIHJlc3VsdCBvZgogW1By
ZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Q
cmVkaWN0aW9uU2VydmljZS5QcmVkaWN0XS4KIFRoaXMgZmllbGQgZW5hYmxlcyBhY2N1cmF0
ZSBhdHRyaWJ1dGlvbiBvZiByZWNvbW1lbmRhdGlvbiBtb2RlbAogcGVyZm9ybWFuY2UuCgog
VGhlIHZhbHVlIG11c3QgYmUgYSB2YWxpZAogW1ByZWRpY3RSZXNwb25zZS5hdHRyaWJ1dGlv
bl90b2tlbl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlByZWRpY3RSZXNwb25zZS5h
dHRyaWJ1dGlvbl90b2tlbl0KIGZvciB1c2VyIGV2ZW50cyB0aGF0IGFyZSB0aGUgcmVzdWx0
IG9mCiBbUHJlZGljdGlvblNlcnZpY2UuUHJlZGljdF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmFscGhhLlByZWRpY3Rpb25TZXJ2aWNlLlByZWRpY3RdLgogVGhlIHZhbHVlIG11c3QgYmUg
YSB2YWxpZAogW1NlYXJjaFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2VuXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuU2VhcmNoUmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dCiBm
b3IgdXNlciBldmVudHMgdGhhdCBhcmUgdGhlIHJlc3VsdCBvZgogW1NlYXJjaFNlcnZpY2Uu
U2VhcmNoXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU2VhcmNoU2VydmljZS5TZWFy
Y2hdLgoKIFRoaXMgdG9rZW4gZW5hYmxlcyB1cyB0byBhY2N1cmF0ZWx5IGF0dHJpYnV0ZSBw
YWdlIHZpZXcgb3IgcHVyY2hhc2UgYmFjayB0bwogdGhlIGV2ZW50IGFuZCB0aGUgcGFydGlj
dWxhciBwcmVkaWN0IHJlc3BvbnNlIGNvbnRhaW5pbmcgdGhpcwogY2xpY2tlZC9wdXJjaGFz
ZWQgcHJvZHVjdC4gSWYgdXNlciBjbGlja3Mgb24gcHJvZHVjdCBLIGluIHRoZQogcmVjb21t
ZW5kYXRpb24gcmVzdWx0cywgcGFzcwogW1ByZWRpY3RSZXNwb25zZS5hdHRyaWJ1dGlvbl90
b2tlbl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlByZWRpY3RSZXNwb25zZS5hdHRy
aWJ1dGlvbl90b2tlbl0KIGFzIGEgVVJMIHBhcmFtZXRlciB0byBwcm9kdWN0IEsncyBwYWdl
LiBXaGVuIHJlY29yZGluZyBldmVudHMgb24gcHJvZHVjdAogSydzIHBhZ2UsIGxvZyB0aGUK
IFtQcmVkaWN0UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJhbHBoYS5QcmVkaWN0UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dCiB0byB0aGlz
IGZpZWxkLgoKDAoFBAACBQUSA3ACCAoMCgUEAAIFARIDcAkaCgwKBQQAAgUDEgNwHR4KjwUK
BAQAAgYSBIEBAi0agAUgVGhlIG1haW4gcHJvZHVjdCBkZXRhaWxzIHJlbGF0ZWQgdG8gdGhl
IGV2ZW50LgoKIFRoaXMgZmllbGQgaXMgb3B0aW9uYWwgZXhjZXB0IGZvciB0aGUgZm9sbG93
aW5nIGV2ZW50IHR5cGVzOgoKICogYGFkZC10by1jYXJ0YAogKiBgZGV0YWlsLXBhZ2Utdmll
d2AKICogYHB1cmNoYXNlLWNvbXBsZXRlYAoKIEluIGEgYHNlYXJjaGAgZXZlbnQsIHRoaXMg
ZmllbGQgcmVwcmVzZW50cyB0aGUgcHJvZHVjdHMgcmV0dXJuZWQgdG8gdGhlIGVuZAogdXNl
ciBvbiB0aGUgY3VycmVudCBwYWdlICh0aGUgZW5kIHVzZXIgbWF5IGhhdmUgbm90IGZpbmlz
aGVkIGJyb3dzaW5nIHRoZQogd2hvbGUgcGFnZSB5ZXQpLiBXaGVuIGEgbmV3IHBhZ2UgaXMg
cmV0dXJuZWQgdG8gdGhlIGVuZCB1c2VyLCBhZnRlcgogcGFnaW5hdGlvbi9maWx0ZXJpbmcv
b3JkZXJpbmcgZXZlbiBmb3IgdGhlIHNhbWUgcXVlcnksIGEgbmV3IGBzZWFyY2hgIGV2ZW50
CiB3aXRoIGRpZmZlcmVudAogW3Byb2R1Y3RfZGV0YWlsc11bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmFscGhhLlVzZXJFdmVudC5wcm9kdWN0X2RldGFpbHNdIGlzCiBkZXNpcmVkLiBUaGUg
ZW5kIHVzZXIgbWF5IGhhdmUgbm90IGZpbmlzaGVkIGJyb3dzaW5nIHRoZSB3aG9sZSBwYWdl
IHlldC4KCg0KBQQAAgYEEgSBAQIKCg0KBQQAAgYGEgSBAQsYCg0KBQQAAgYBEgSBARkoCg0K
BQQAAgYDEgSBASssCskBCgQEAAIHEgSHAQIqGroBIFRoZSBtYWluIGF1dG8tY29tcGxldGlv
biBkZXRhaWxzIHJlbGF0ZWQgdG8gdGhlIGV2ZW50LgoKIFRoaXMgZmllbGQgc2hvdWxkIGJl
IHNldCBmb3IgYHNlYXJjaGAgZXZlbnQgd2hlbiBhdXRvY29tcGxldGUgZnVuY3Rpb24gaXMK
IGVuYWJsZWQgYW5kIHRoZSB1c2VyIGNsaWNrcyBhIHN1Z2dlc3Rpb24gZm9yIHNlYXJjaC4K
Cg0KBQQAAgcGEgSHAQISCg0KBQQAAgcBEgSHARMkCg0KBQQAAgcDEgSHAScpCvoICgQEAAII
EgSgAQIuGusIIEV4dHJhIHVzZXIgZXZlbnQgZmVhdHVyZXMgdG8gaW5jbHVkZSBpbiB0aGUg
cmVjb21tZW5kYXRpb24gbW9kZWwuCgogSWYgeW91IHByb3ZpZGUgY3VzdG9tIGF0dHJpYnV0
ZXMgZm9yIGluZ2VzdGVkIHVzZXIgZXZlbnRzLCBhbHNvIGluY2x1ZGUKIHRoZW0gaW4gdGhl
IHVzZXIgZXZlbnRzIHRoYXQgeW91IGFzc29jaWF0ZSB3aXRoIHByZWRpY3Rpb24gcmVxdWVz
dHMuIEN1c3RvbQogYXR0cmlidXRlIGZvcm1hdHRpbmcgbXVzdCBiZSBjb25zaXN0ZW50IGJl
dHdlZW4gaW1wb3J0ZWQgZXZlbnRzIGFuZCBldmVudHMKIHByb3ZpZGVkIHdpdGggcHJlZGlj
dGlvbiByZXF1ZXN0cy4gVGhpcyBsZXRzIHRoZSBSZXRhaWwgQVBJIHVzZQogdGhvc2UgY3Vz
dG9tIGF0dHJpYnV0ZXMgd2hlbiB0cmFpbmluZyBtb2RlbHMgYW5kIHNlcnZpbmcgcHJlZGlj
dGlvbnMsIHdoaWNoCiBoZWxwcyBpbXByb3ZlIHJlY29tbWVuZGF0aW9uIHF1YWxpdHkuCgog
VGhpcyBmaWVsZCBuZWVkcyB0byBwYXNzIGFsbCBiZWxvdyBjcml0ZXJpYSwgb3RoZXJ3aXNl
IGFuIElOVkFMSURfQVJHVU1FTlQKIGVycm9yIGlzIHJldHVybmVkOgoKICogVGhlIGtleSBt
dXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiA1
LDAwMAogICBjaGFyYWN0ZXJzLgogKiBGb3IgdGV4dCBhdHRyaWJ1dGVzLCBhdCBtb3N0IDQw
MCB2YWx1ZXMgYXJlIGFsbG93ZWQuIEVtcHR5IHZhbHVlcyBhcmUgbm90CiAgIGFsbG93ZWQu
IEVhY2ggdmFsdWUgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5n
dGggbGltaXQgb2YKICAgMjU2IGNoYXJhY3RlcnMuCiAqIEZvciBudW1iZXIgYXR0cmlidXRl
cywgYXQgbW9zdCA0MDAgdmFsdWVzIGFyZSBhbGxvd2VkLgoKIEZvciBwcm9kdWN0IHJlY29t
bWVuZGF0aW9ucywgYW4gZXhhbXBsZSBvZiBleHRyYSB1c2VyIGluZm9ybWF0aW9uIGlzCiB0
cmFmZmljX2NoYW5uZWwsIHdoaWNoIGlzIGhvdyBhIHVzZXIgYXJyaXZlcyBhdCB0aGUgc2l0
ZS4gVXNlcnMgY2FuIGFycml2ZQogYXQgdGhlIHNpdGUgYnkgY29taW5nIHRvIHRoZSBzaXRl
IGRpcmVjdGx5LCBjb21pbmcgdGhyb3VnaCBHb29nbGUKIHNlYXJjaCwgb3IgaW4gb3RoZXIg
d2F5cy4KCg0KBQQAAggGEgSgAQIeCg0KBQQAAggBEgSgAR8pCg0KBQQAAggDEgSgASwtCoAC
CgQEAAIJEgSnAQIVGvEBIFRoZSBJRCBvciBuYW1lIG9mIHRoZSBhc3NvY2lhdGVkIHNob3Bw
aW5nIGNhcnQuIFRoaXMgSUQgaXMgdXNlZAogdG8gYXNzb2NpYXRlIG11bHRpcGxlIGl0ZW1z
IGFkZGVkIG9yIHByZXNlbnQgaW4gdGhlIGNhcnQgYmVmb3JlIHB1cmNoYXNlLgoKIFRoaXMg
Y2FuIG9ubHkgYmUgc2V0IGZvciBgYWRkLXRvLWNhcnRgLCBgcHVyY2hhc2UtY29tcGxldGVg
LCBvcgogYHNob3BwaW5nLWNhcnQtcGFnZS12aWV3YCBldmVudHMuCgoNCgUEAAIJBRIEpwEC
CAoNCgUEAAIJARIEpwEJEAoNCgUEAAIJAxIEpwETFArVAQoEBAACChIErQECLxrGASBBIHRy
YW5zYWN0aW9uIHJlcHJlc2VudHMgdGhlIGVudGlyZSBwdXJjaGFzZSB0cmFuc2FjdGlvbi4K
CiBSZXF1aXJlZCBmb3IgYHB1cmNoYXNlLWNvbXBsZXRlYCBldmVudHMuIE90aGVyIGV2ZW50
IHR5cGVzIHNob3VsZCBub3Qgc2V0CiB0aGlzIGZpZWxkLiBPdGhlcndpc2UsIGFuIElOVkFM
SURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAIKBhIErQECFQoNCgUEAAIK
ARIErQEWKgoNCgUEAAIKAxIErQEtLgqzBAoEBAACCxIEvAECGxqkBCBUaGUgdXNlcidzIHNl
YXJjaCBxdWVyeS4KCiBTZWUgW1NlYXJjaFJlcXVlc3QucXVlcnldW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYS5TZWFyY2hSZXF1ZXN0LnF1ZXJ5XQogZm9yIGRlZmluaXRpb24uCgog
VGhlIHZhbHVlIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3Ro
IGxpbWl0IG9mIDUsMDAwCiBjaGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJH
VU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgogQXQgbGVhc3Qgb25lIG9mCiBbc2VhcmNoX3F1
ZXJ5XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVXNlckV2ZW50LnNlYXJjaF9xdWVy
eV0gb3IKIFtwYWdlX2NhdGVnb3JpZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5V
c2VyRXZlbnQucGFnZV9jYXRlZ29yaWVzXSBpcwogcmVxdWlyZWQgZm9yIGBzZWFyY2hgIGV2
ZW50cy4gT3RoZXIgZXZlbnQgdHlwZXMgc2hvdWxkIG5vdCBzZXQgdGhpcyBmaWVsZC4KIE90
aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQA
AgsFEgS8AQIICg0KBQQAAgsBEgS8AQkVCg0KBQQAAgsDEgS8ARgaCo4DCgQEAAIMEgTHAQIV
Gv8CIFRoZSBmaWx0ZXIgc3ludGF4IGNvbnNpc3RzIG9mIGFuIGV4cHJlc3Npb24gbGFuZ3Vh
Z2UgZm9yIGNvbnN0cnVjdGluZyBhCiBwcmVkaWNhdGUgZnJvbSBvbmUgb3IgbW9yZSBmaWVs
ZHMgb2YgdGhlIHByb2R1Y3RzIGJlaW5nIGZpbHRlcmVkLgoKIFNlZQogW1NlYXJjaFJlcXVl
c3QuZmlsdGVyXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU2VhcmNoUmVxdWVzdC5m
aWx0ZXJdCiBmb3IgZGVmaW5pdGlvbiBhbmQgc3ludGF4LgoKIFRoZSB2YWx1ZSBtdXN0IGJl
IGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxLDAwMAog
Y2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJl
dHVybmVkLgoKDQoFBAACDAUSBMcBAggKDQoFBAACDAESBMcBCQ8KDQoFBAACDAMSBMcBEhQK
vQMKBAQAAg0SBNQBAhcargMgVGhlIG9yZGVyIGluIHdoaWNoIHByb2R1Y3RzIGFyZSByZXR1
cm5lZC4KCiBTZWUKIFtTZWFyY2hSZXF1ZXN0Lm9yZGVyX2J5XVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuU2VhcmNoUmVxdWVzdC5vcmRlcl9ieV0KIGZvciBkZWZpbml0aW9uIGFu
ZCBzeW50YXguCgogVGhlIHZhbHVlIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3
aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEsMDAwCiBjaGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFu
IElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBjYW4gb25seSBi
ZSBzZXQgZm9yIGBzZWFyY2hgIGV2ZW50cy4gT3RoZXIgZXZlbnQgdHlwZXMgc2hvdWxkIG5v
dCBzZXQKIHRoaXMgZmllbGQuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJv
ciBpcyByZXR1cm5lZC4KCg0KBQQAAg0FEgTUAQIICg0KBQQAAg0BEgTUAQkRCg0KBQQAAg0D
EgTUARQWCs8DCgQEAAIOEgThAQIUGsADIEFuIGludGVnZXIgdGhhdCBzcGVjaWZpZXMgdGhl
IGN1cnJlbnQgb2Zmc2V0IGZvciBwYWdpbmF0aW9uICh0aGUgMC1pbmRleGVkCiBzdGFydGlu
ZyBsb2NhdGlvbiwgYW1vbmdzdCB0aGUgcHJvZHVjdHMgZGVlbWVkIGJ5IHRoZSBBUEkgYXMg
cmVsZXZhbnQpLgoKIFNlZQogW1NlYXJjaFJlcXVlc3Qub2Zmc2V0XVtnb29nbGUuY2xvdWQu
cmV0YWlsLnYyYWxwaGEuU2VhcmNoUmVxdWVzdC5vZmZzZXRdCiBmb3IgZGVmaW5pdGlvbi4K
CiBJZiB0aGlzIGZpZWxkIGlzIG5lZ2F0aXZlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGlzIHJl
dHVybmVkLgoKIFRoaXMgY2FuIG9ubHkgYmUgc2V0IGZvciBgc2VhcmNoYCBldmVudHMuIE90
aGVyIGV2ZW50IHR5cGVzIHNob3VsZCBub3Qgc2V0CiB0aGlzIGZpZWxkLiBPdGhlcndpc2Us
IGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAIOBRIE4QEC
BwoNCgUEAAIOARIE4QEIDgoNCgUEAAIOAxIE4QEREwrxBQoEBAACDxIE8gECJxriBSBUaGUg
Y2F0ZWdvcmllcyBhc3NvY2lhdGVkIHdpdGggYSBjYXRlZ29yeSBwYWdlLgoKIFRvIHJlcHJl
c2VudCBmdWxsIHBhdGggb2YgY2F0ZWdvcnksIHVzZSAnPicgc2lnbiB0byBzZXBhcmF0ZSBk
aWZmZXJlbnQKIGhpZXJhcmNoaWVzLiBJZiAnPicgaXMgcGFydCBvZiB0aGUgY2F0ZWdvcnkg
bmFtZSwgcmVwbGFjZSBpdCB3aXRoCiBvdGhlciBjaGFyYWN0ZXIocykuCgogQ2F0ZWdvcnkg
cGFnZXMgaW5jbHVkZSBzcGVjaWFsIHBhZ2VzIHN1Y2ggYXMgc2FsZXMgb3IgcHJvbW90aW9u
cy4gRm9yCiBpbnN0YW5jZSwgYSBzcGVjaWFsIHNhbGUgcGFnZSBtYXkgaGF2ZSB0aGUgY2F0
ZWdvcnkgaGllcmFyY2h5OgogInBhZ2VDYXRlZ29yaWVzIiA6IFsiU2FsZXMgPiAyMDE3IEJs
YWNrIEZyaWRheSBEZWFscyJdLgoKIFJlcXVpcmVkIGZvciBgY2F0ZWdvcnktcGFnZS12aWV3
YCBldmVudHMuIEF0IGxlYXN0IG9uZSBvZgogW3NlYXJjaF9xdWVyeV1bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmFscGhhLlVzZXJFdmVudC5zZWFyY2hfcXVlcnldIG9yCiBbcGFnZV9jYXRl
Z29yaWVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVXNlckV2ZW50LnBhZ2VfY2F0
ZWdvcmllc10gaXMKIHJlcXVpcmVkIGZvciBgc2VhcmNoYCBldmVudHMuIE90aGVyIGV2ZW50
IHR5cGVzIHNob3VsZCBub3Qgc2V0IHRoaXMgZmllbGQuCiBPdGhlcndpc2UsIGFuIElOVkFM
SURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAIPBBIE8gECCgoNCgUEAAIP
BRIE8gELEQoNCgUEAAIPARIE8gESIQoNCgUEAAIPAxIE8gEkJgohCgQEAAIQEgT1AQIaGhMg
VXNlciBpbmZvcm1hdGlvbi4KCg0KBQQAAhAGEgT1AQIKCg0KBQQAAhABEgT1AQsUCg0KBQQA
AhADEgT1ARcZCvUBCgQEAAIREgT8AQISGuYBIENvbXBsZXRlIFVSTCAod2luZG93LmxvY2F0
aW9uLmhyZWYpIG9mIHRoZSB1c2VyJ3MgY3VycmVudCBwYWdlLgoKIFdoZW4gdXNpbmcgdGhl
IGNsaWVudCBzaWRlIGV2ZW50IHJlcG9ydGluZyB3aXRoIEphdmFTY3JpcHQgcGl4ZWwgYW5k
IEdvb2dsZQogVGFnIE1hbmFnZXIsIHRoaXMgdmFsdWUgaXMgZmlsbGVkIGluIGF1dG9tYXRp
Y2FsbHkuIE1heGltdW0gbGVuZ3RoIDUsMDAwCiBjaGFyYWN0ZXJzLgoKDQoFBAACEQUSBPwB
AggKDQoFBAACEQESBPwBCQwKDQoFBAACEQMSBPwBDxEKuQEKBAQAAhISBIICAhsaqgEgVGhl
IHJlZmVycmVyIFVSTCBvZiB0aGUgY3VycmVudCBwYWdlLgoKIFdoZW4gdXNpbmcgdGhlIGNs
aWVudCBzaWRlIGV2ZW50IHJlcG9ydGluZyB3aXRoIEphdmFTY3JpcHQgcGl4ZWwgYW5kIEdv
b2dsZQogVGFnIE1hbmFnZXIsIHRoaXMgdmFsdWUgaXMgZmlsbGVkIGluIGF1dG9tYXRpY2Fs
bHkuCgoNCgUEAAISBRIEggICCAoNCgUEAAISARIEggIJFQoNCgUEAAISAxIEggIYGgroAwoE
BAACExIEjgICGxrZAyBBIHVuaXF1ZSBJRCBvZiBhIHdlYiBwYWdlIHZpZXcuCgogVGhpcyBz
aG91bGQgYmUga2VwdCB0aGUgc2FtZSBmb3IgYWxsIHVzZXIgZXZlbnRzIHRyaWdnZXJlZCBm
cm9tIHRoZSBzYW1lCiBwYWdldmlldy4gRm9yIGV4YW1wbGUsIGFuIGl0ZW0gZGV0YWlsIHBh
Z2UgdmlldyBjb3VsZCB0cmlnZ2VyIG11bHRpcGxlCiBldmVudHMgYXMgdGhlIHVzZXIgaXMg
YnJvd3NpbmcgdGhlIHBhZ2UuIFRoZSBgcGFnZVZpZXdJZGAgcHJvcGVydHkgc2hvdWxkCiBi
ZSBrZXB0IHRoZSBzYW1lIGZvciBhbGwgdGhlc2UgZXZlbnRzIHNvIHRoYXQgdGhleSBjYW4g
YmUgZ3JvdXBlZCB0b2dldGhlcgogcHJvcGVybHkuCgogV2hlbiB1c2luZyB0aGUgY2xpZW50
IHNpZGUgZXZlbnQgcmVwb3J0aW5nIHdpdGggSmF2YVNjcmlwdCBwaXhlbCBhbmQgR29vZ2xl
CiBUYWcgTWFuYWdlciwgdGhpcyB2YWx1ZSBpcyBmaWxsZWQgaW4gYXV0b21hdGljYWxseS4K
Cg0KBQQAAhMFEgSOAgIICg0KBQQAAhMBEgSOAgkVCg0KBQQAAhMDEgSOAhgaCq8CCgQEAAIU
EgSVAgIVGqACIFRoZSBlbnRpdHkgZm9yIGN1c3RvbWVycyB0aGF0IG1heSBydW4gbXVsdGlw
bGUgZGlmZmVyZW50IGVudGl0aWVzLCBkb21haW5zLAogc2l0ZXMgb3IgcmVnaW9ucywgZm9y
IGV4YW1wbGUsIGBHb29nbGUgVVNgLCBgR29vZ2xlIEFkc2AsIGBXYXltb2AsCiBgZ29vZ2xl
LmNvbWAsIGB5b3V0dWJlLmNvbWAsIGV0Yy4KIFdlIHJlY29tbWVuZCB0aGF0IHlvdSBzZXQg
dGhpcyBmaWVsZCB0byBnZXQgYmV0dGVyIHBlci1lbnRpdHkgc2VhcmNoLAogY29tcGxldGlv
biwgYW5kIHByZWRpY3Rpb24gcmVzdWx0cy4KCg0KBQQAAhQFEgSVAgIICg0KBQQAAhQBEgSV
AgkPCg0KBQQAAhQDEgSVAhIUCkoKAgQBEgaZAgCzAgEaPCBEZXRhaWxlZCBwcm9kdWN0IGlu
Zm9ybWF0aW9uIGFzc29jaWF0ZWQgd2l0aCBhIHVzZXIgZXZlbnQuCgoLCgMEAQESBJkCCBUK
2QQKBAQBAgASBKsCAj8aygQgUmVxdWlyZWQuIFtQcm9kdWN0XVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuUHJvZHVjdF0gaW5mb3JtYXRpb24uCgogUmVxdWlyZWQgZmllbGQocyk6
CgogKiBbUHJvZHVjdC5pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlByb2R1Y3Qu
aWRdCgogT3B0aW9uYWwgb3ZlcnJpZGUgZmllbGQocyk6CgogKiBbUHJvZHVjdC5wcmljZV9p
bmZvXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUHJvZHVjdC5wcmljZV9pbmZvXQoK
IElmIGFueSBzdXBwb3J0ZWQgb3B0aW9uYWwgZmllbGRzIGFyZSBwcm92aWRlZCwgd2Ugd2ls
bCB0cmVhdCB0aGVtIGFzIGEgZnVsbAogb3ZlcnJpZGUgd2hlbiBsb29raW5nIHVwIHByb2R1
Y3QgaW5mb3JtYXRpb24gZnJvbSB0aGUgY2F0YWxvZy4gVGh1cywgaXQgaXMKIGltcG9ydGFu
dCB0byBlbnN1cmUgdGhhdCB0aGUgb3ZlcnJpZGluZyBmaWVsZHMgYXJlIGFjY3VyYXRlIGFu
ZAogY29tcGxldGUuCgogQWxsIG90aGVyIHByb2R1Y3QgZmllbGRzIGFyZSBpZ25vcmVkIGFu
ZCBpbnN0ZWFkIHBvcHVsYXRlZCB2aWEgY2F0YWxvZwogbG9va3VwIGFmdGVyIGV2ZW50IGlu
Z2VzdGlvbi4KCg0KBQQBAgAGEgSrAgIJCg0KBQQBAgABEgSrAgoRCg0KBQQBAgADEgSrAhQV
Cg0KBQQBAgAIEgSrAhY+ChAKCAQBAgAInAgAEgSrAhc9CvwBCgQEAQIBEgSyAgIqGu0BIFF1
YW50aXR5IG9mIHRoZSBwcm9kdWN0IGFzc29jaWF0ZWQgd2l0aCB0aGUgdXNlciBldmVudC4K
CiBGb3IgZXhhbXBsZSwgdGhpcyBmaWVsZCB3aWxsIGJlIDIgaWYgdHdvIHByb2R1Y3RzIGFy
ZSBhZGRlZCB0byB0aGUgc2hvcHBpbmcKIGNhcnQgZm9yIGBwdXJjaGFzZS1jb21wbGV0ZWAg
ZXZlbnQuIFJlcXVpcmVkIGZvciBgYWRkLXRvLWNhcnRgIGFuZAogYHB1cmNoYXNlLWNvbXBs
ZXRlYCBldmVudCB0eXBlcy4KCg0KBQQBAgEGEgSyAgIcCg0KBQQBAgEBEgSyAh0lCg0KBQQB
AgEDEgSyAigpCnQKAgQCEga3AgDEAgEaZiBEZXRhaWxlZCBjb21wbGV0aW9uIGluZm9ybWF0
aW9uIGluY2x1ZGluZyBjb21wbGV0aW9uIGF0dHJpYnV0aW9uIHRva2VuIGFuZAogY2xpY2tl
ZCBjb21wbGV0aW9uIGluZm8uCgoLCgMEAgESBLcCCBgKoQEKBAQCAgASBLoCAioakgEgQ29t
cGxldGlvbiBhdHRyaWJ1dGlvbiB0b2tlbiBpbgogW0NvbXBsZXRlUXVlcnlSZXNwb25zZS5h
dHRyaWJ1dGlvbl90b2tlbl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNvbXBsZXRl
UXVlcnlSZXNwb25zZS5hdHRyaWJ1dGlvbl90b2tlbl0uCgoNCgUEAgIABRIEugICCAoNCgUE
AgIAARIEugIJJQoNCgUEAgIAAxIEugIoKQqnAQoEBAICARIEvgICIRqYASBFbmQgdXNlciBz
ZWxlY3RlZAogW0NvbXBsZXRlUXVlcnlSZXNwb25zZS5Db21wbGV0aW9uUmVzdWx0LnN1Z2dl
c3Rpb25dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Db21wbGV0ZVF1ZXJ5UmVzcG9u
c2UuQ29tcGxldGlvblJlc3VsdC5zdWdnZXN0aW9uXS4KCg0KBQQCAgEFEgS+AgIICg0KBQQC
AgEBEgS+AgkcCg0KBQQCAgEDEgS+Ah8gCsIBCgQEAgICEgTDAgIeGrMBIEVuZCB1c2VyIHNl
bGVjdGVkCiBbQ29tcGxldGVRdWVyeVJlc3BvbnNlLkNvbXBsZXRpb25SZXN1bHQuc3VnZ2Vz
dGlvbl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNvbXBsZXRlUXVlcnlSZXNwb25z
ZS5Db21wbGV0aW9uUmVzdWx0LnN1Z2dlc3Rpb25dCiBwb3NpdGlvbiwgc3RhcnRpbmcgZnJv
bSAwLgoKDQoFBAICAgUSBMMCAgcKDQoFBAICAgESBMMCCBkKDQoFBAICAgMSBMMCHB0KSQoC
BAMSBscCAOACARo7IEEgdHJhbnNhY3Rpb24gcmVwcmVzZW50cyB0aGUgZW50aXJlIHB1cmNo
YXNlIHRyYW5zYWN0aW9uLgoKCwoDBAMBEgTHAggbCkkKBAQDAgASBMkCAhAaOyBUaGUgdHJh
bnNhY3Rpb24gSUQgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMjggY2hhcmFjdGVycy4KCg0K
BQQDAgAFEgTJAgIICg0KBQQDAgABEgTJAgkLCg0KBQQDAgADEgTJAg4PCusBCgQEAwIBEgTP
AgI9GtwBIFJlcXVpcmVkLiBUb3RhbCBub24temVybyByZXZlbnVlIG9yIGdyYW5kIHRvdGFs
IGFzc29jaWF0ZWQgd2l0aCB0aGUKIHRyYW5zYWN0aW9uLiBUaGlzIHZhbHVlIGluY2x1ZGUg
c2hpcHBpbmcsIHRheCwgb3Igb3RoZXIgYWRqdXN0bWVudHMgdG8KIHRvdGFsIHJldmVudWUg
dGhhdCB5b3Ugd2FudCB0byBpbmNsdWRlIGFzIHBhcnQgb2YgeW91ciByZXZlbnVlCiBjYWxj
dWxhdGlvbnMuCgoNCgUEAwIBBRIEzwICBwoNCgUEAwIBARIEzwIIDwoNCgUEAwIBAxIEzwIS
EwoNCgUEAwIBCBIEzwIUPAoQCggEAwIBCJwIABIEzwIVOwo+CgQEAwICEgTSAgIQGjAgQWxs
IHRoZSB0YXhlcyBhc3NvY2lhdGVkIHdpdGggdGhlIHRyYW5zYWN0aW9uLgoKDQoFBAMCAgUS
BNICAgcKDQoFBAMCAgESBNICCAsKDQoFBAMCAgMSBNICDg8K+wIKBAQDAgMSBNwCAhEa7AIg
QWxsIHRoZSBjb3N0cyBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2R1Y3RzLiBUaGVzZSBjYW4g
YmUgbWFudWZhY3R1cmluZwogY29zdHMsIHNoaXBwaW5nIGV4cGVuc2VzIG5vdCBib3JuZSBi
eSB0aGUgZW5kIHVzZXIsIG9yIGFueSBvdGhlciBjb3N0cywKIHN1Y2ggdGhhdDoKCiAqIFBy
b2ZpdCA9CiBbcmV2ZW51ZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlB1cmNoYXNl
VHJhbnNhY3Rpb24ucmV2ZW51ZV0gLQogW3RheF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLlB1cmNoYXNlVHJhbnNhY3Rpb24udGF4XSAtCiBbY29zdF1bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLlB1cmNoYXNlVHJhbnNhY3Rpb24uY29zdF0KCg0KBQQDAgMFEgTcAgIH
Cg0KBQQDAgMBEgTcAggMCg0KBQQDAgMDEgTcAg8QCksKBAQDAgQSBN8CAkQaPSBSZXF1aXJl
ZC4gQ3VycmVuY3kgY29kZS4gVXNlIHRocmVlLWNoYXJhY3RlciBJU08tNDIxNyBjb2RlLgoK
DQoFBAMCBAUSBN8CAggKDQoFBAMCBAESBN8CCRYKDQoFBAMCBAMSBN8CGRoKDQoFBAMCBAgS
BN8CG0MKEAoIBAMCBAicCAASBN8CHEJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::UserEvent::UserEvent ===
    # Fields for UserEvent
    # Field: event_type Type: 9 ()
    # Field: visitor_id Type: 9 ()
    # Field: session_id Type: 9 ()
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: experiment_ids Type: 9 ()
    # Field: attribution_token Type: 9 ()
    # Field: product_details Type: 11 (.google.cloud.retail.v2alpha.ProductDetail)
    # Field: completion_detail Type: 11 (.google.cloud.retail.v2alpha.CompletionDetail)
    # Field: attributes Type: 11 (.google.cloud.retail.v2alpha.UserEvent.AttributesEntry)
    # Field: cart_id Type: 9 ()
    # Field: purchase_transaction Type: 11 (.google.cloud.retail.v2alpha.PurchaseTransaction)
    # Field: search_query Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: offset Type: 5 ()
    # Field: page_categories Type: 9 ()
    # Field: user_info Type: 11 (.google.cloud.retail.v2alpha.UserInfo)
    # Field: uri Type: 9 ()
    # Field: referrer_uri Type: 9 ()
    # Field: page_view_id Type: 9 ()
    # Field: entity Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::UserEvent::ProductDetail ===
    # Fields for ProductDetail
    # Field: product Type: 11 (.google.cloud.retail.v2alpha.Product)
    # Field: quantity Type: 11 (.google.protobuf.Int32Value)

# === Message: Google::Cloud::Retail::V2alpha::UserEvent::CompletionDetail ===
    # Fields for CompletionDetail
    # Field: completion_attribution_token Type: 9 ()
    # Field: selected_suggestion Type: 9 ()
    # Field: selected_position Type: 5 ()

# === Message: Google::Cloud::Retail::V2alpha::UserEvent::PurchaseTransaction ===
    # Fields for PurchaseTransaction
    # Field: id Type: 9 ()
    # Field: revenue Type: 2 ()
    # Field: tax Type: 2 ()
    # Field: cost Type: 2 ()
    # Field: currency_code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::UserEvent - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/user_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::UserEvent;

    my $msg = Google::Cloud::Retail::V2alpha::UserEvent::UserEvent->new({
        event_type => $event_type,
        visitor_id => $visitor_id,
        session_id => $session_id,
        event_time => $event_time,
    });

    # Read or update a field
    my $val = $msg->event_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::UserEvent::UserEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/user_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::UserEvent::UserEvent

UserEvent captures all metadata information Retail API needs to know about
how end users interact with customers' website.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<String>

Required. User event type. Allowed values are:

* `add-to-cart`: Products being added to cart.
* `remove-from-cart`: Products being removed from cart.
* `category-page-view`: Special pages such as sale or promotion pages
  viewed.
* `detail-page-view`: Products detail page viewed.
* `home-page-view`: Homepage viewed.
* `purchase-complete`: User finishing a purchase.
* `search`: Product search.
* `shopping-cart-page-view`: User viewing a shopping cart.

=item * C<< $msg->visitor_id() >> / C<< $msg->visitor_id($value) >>

Type: C<String>

Required. A unique identifier for tracking visitors.

For example, this could be implemented with an HTTP cookie, which should be
able to uniquely identify a visitor on a single device. This unique
identifier should not change if the visitor log in/out of the website.

Don't set the field to the same fixed ID for different users. This mixes
the event history of those users together, which results in degraded model
quality.

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

The field should not contain PII or user-data. We recommend to use Google
Analytics [Client
ID](https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#clientId)
for this field.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

A unique identifier for tracking a visitor session with a length limit of
128 bytes. A session is an aggregation of an end user behavior in a time
span.

A general guideline to populate the sesion_id:
1. If user has no activity for 30 min, a new session_id should be assigned.
2. The session_id should be unique across users, suggest use uuid or add
visitor_id as prefix.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Only required for
[UserEventService.ImportUserEvents][google.cloud.retail.v2alpha.UserEventService.ImportUserEvents]
method. Timestamp of when the user event happened.

=item * C<< $msg->experiment_ids() >> / C<< $msg->experiment_ids($value) >>

Type: C<String>

A list of identifiers for the independent experiment groups this user event
belongs to. This is used to distinguish between user events associated with
different experiment setups (e.g. using Retail API, using different
recommendation models).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

Highly recommended for user events that are the result of
[PredictionService.Predict][google.cloud.retail.v2alpha.PredictionService.Predict].
This field enables accurate attribution of recommendation model
performance.

The value must be a valid
[PredictResponse.attribution_token][google.cloud.retail.v2alpha.PredictResponse.attribution_token]
for user events that are the result of
[PredictionService.Predict][google.cloud.retail.v2alpha.PredictionService.Predict].
The value must be a valid
[SearchResponse.attribution_token][google.cloud.retail.v2alpha.SearchResponse.attribution_token]
for user events that are the result of
[SearchService.Search][google.cloud.retail.v2alpha.SearchService.Search].

This token enables us to accurately attribute page view or purchase back to
the event and the particular predict response containing this
clicked/purchased product. If user clicks on product K in the
recommendation results, pass
[PredictResponse.attribution_token][google.cloud.retail.v2alpha.PredictResponse.attribution_token]
as a URL parameter to product K's page. When recording events on product
K's page, log the
[PredictResponse.attribution_token][google.cloud.retail.v2alpha.PredictResponse.attribution_token]
to this field.

=item * C<< $msg->product_details() >> / C<< $msg->product_details($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::UserEvent::ProductDetail>)

The main product details related to the event.

This field is optional except for the following event types:

* `add-to-cart`
* `detail-page-view`
* `purchase-complete`

In a `search` event, this field represents the products returned to the end
user on the current page (the end user may have not finished browsing the
whole page yet). When a new page is returned to the end user, after
pagination/filtering/ordering even for the same query, a new `search` event
with different
[product_details][google.cloud.retail.v2alpha.UserEvent.product_details] is
desired. The end user may have not finished browsing the whole page yet.

=item * C<< $msg->completion_detail() >> / C<< $msg->completion_detail($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::UserEvent::CompletionDetail>)

The main auto-completion details related to the event.

This field should be set for `search` event when autocomplete function is
enabled and the user clicks a suggestion for search.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::UserEvent::UserEvent::AttributesEntry>)

Extra user event features to include in the recommendation model.

If you provide custom attributes for ingested user events, also include
them in the user events that you associate with prediction requests. Custom
attribute formatting must be consistent between imported events and events
provided with prediction requests. This lets the Retail API use
those custom attributes when training models and serving predictions, which
helps improve recommendation quality.

This field needs to pass all below criteria, otherwise an INVALID_ARGUMENT
error is returned:

* The key must be a UTF-8 encoded string with a length limit of 5,000
  characters.
* For text attributes, at most 400 values are allowed. Empty values are not
  allowed. Each value must be a UTF-8 encoded string with a length limit of
  256 characters.
* For number attributes, at most 400 values are allowed.

For product recommendations, an example of extra user information is
traffic_channel, which is how a user arrives at the site. Users can arrive
at the site by coming to the site directly, coming through Google
search, or in other ways.

=item * C<< $msg->cart_id() >> / C<< $msg->cart_id($value) >>

Type: C<String>

The ID or name of the associated shopping cart. This ID is used
to associate multiple items added or present in the cart before purchase.

This can only be set for `add-to-cart`, `purchase-complete`, or
`shopping-cart-page-view` events.

=item * C<< $msg->purchase_transaction() >> / C<< $msg->purchase_transaction($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::UserEvent::PurchaseTransaction>)

A transaction represents the entire purchase transaction.

Required for `purchase-complete` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->search_query() >> / C<< $msg->search_query($value) >>

Type: C<String>

The user's search query.

See [SearchRequest.query][google.cloud.retail.v2alpha.SearchRequest.query]
for definition.

The value must be a UTF-8 encoded string with a length limit of 5,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

At least one of
[search_query][google.cloud.retail.v2alpha.UserEvent.search_query] or
[page_categories][google.cloud.retail.v2alpha.UserEvent.page_categories] is
required for `search` events. Other event types should not set this field.
Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter syntax consists of an expression language for constructing a
predicate from one or more fields of the products being filtered.

See
[SearchRequest.filter][google.cloud.retail.v2alpha.SearchRequest.filter]
for definition and syntax.

The value must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

The order in which products are returned.

See
[SearchRequest.order_by][google.cloud.retail.v2alpha.SearchRequest.order_by]
for definition and syntax.

The value must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

This can only be set for `search` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int32>

An integer that specifies the current offset for pagination (the 0-indexed
starting location, amongst the products deemed by the API as relevant).

See
[SearchRequest.offset][google.cloud.retail.v2alpha.SearchRequest.offset]
for definition.

If this field is negative, an INVALID_ARGUMENT is returned.

This can only be set for `search` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->page_categories() >> / C<< $msg->page_categories($value) >>

Type: C<String>

The categories associated with a category page.

To represent full path of category, use '>' sign to separate different
hierarchies. If '>' is part of the category name, replace it with
other character(s).

Category pages include special pages such as sales or promotions. For
instance, a special sale page may have the category hierarchy:
"pageCategories" : ["Sales > 2017 Black Friday Deals"].

Required for `category-page-view` events. At least one of
[search_query][google.cloud.retail.v2alpha.UserEvent.search_query] or
[page_categories][google.cloud.retail.v2alpha.UserEvent.page_categories] is
required for `search` events. Other event types should not set this field.
Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->user_info() >> / C<< $msg->user_info($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Common::UserInfo>)

User information.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Complete URL (window.location.href) of the user's current page.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically. Maximum length 5,000
characters.

=item * C<< $msg->referrer_uri() >> / C<< $msg->referrer_uri($value) >>

Type: C<String>

The referrer URL of the current page.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically.

=item * C<< $msg->page_view_id() >> / C<< $msg->page_view_id($value) >>

Type: C<String>

A unique ID of a web page view.

This should be kept the same for all user events triggered from the same
pageview. For example, an item detail page view could trigger multiple
events as the user is browsing the page. The `pageViewId` property should
be kept the same for all these events so that they can be grouped together
properly.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<String>

The entity for customers that may run multiple different entities, domains,
sites or regions, for example, `Google US`, `Google Ads`, `Waymo`,
`google.com`, `youtube.com`, etc.
We recommend that you set this field to get better per-entity search,
completion, and prediction results.

=back

=head2 Google::Cloud::Retail::V2alpha::UserEvent::ProductDetail

Detailed product information associated with a user event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Product::Product>)

Required. [Product][google.cloud.retail.v2alpha.Product] information.

Required field(s):

* [Product.id][google.cloud.retail.v2alpha.Product.id]

Optional override field(s):

* [Product.price_info][google.cloud.retail.v2alpha.Product.price_info]

If any supported optional fields are provided, we will treat them as a full
override when looking up product information from the catalog. Thus, it is
important to ensure that the overriding fields are accurate and
complete.

All other product fields are ignored and instead populated via catalog
lookup after event ingestion.

=item * C<< $msg->quantity() >> / C<< $msg->quantity($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int32Value>)

Quantity of the product associated with the user event.

For example, this field will be 2 if two products are added to the shopping
cart for `purchase-complete` event. Required for `add-to-cart` and
`purchase-complete` event types.

=back

=head2 Google::Cloud::Retail::V2alpha::UserEvent::CompletionDetail

Detailed completion information including completion attribution token and
clicked completion info.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_attribution_token() >> / C<< $msg->completion_attribution_token($value) >>

Type: C<String>

Completion attribution token in
[CompleteQueryResponse.attribution_token][google.cloud.retail.v2alpha.CompleteQueryResponse.attribution_token].

=item * C<< $msg->selected_suggestion() >> / C<< $msg->selected_suggestion($value) >>

Type: C<String>

End user selected
[CompleteQueryResponse.CompletionResult.suggestion][google.cloud.retail.v2alpha.CompleteQueryResponse.CompletionResult.suggestion].

=item * C<< $msg->selected_position() >> / C<< $msg->selected_position($value) >>

Type: C<Int32>

End user selected
[CompleteQueryResponse.CompletionResult.suggestion][google.cloud.retail.v2alpha.CompleteQueryResponse.CompletionResult.suggestion]
position, starting from 0.

=back

=head2 Google::Cloud::Retail::V2alpha::UserEvent::PurchaseTransaction

A transaction represents the entire purchase transaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The transaction ID with a length limit of 128 characters.

=item * C<< $msg->revenue() >> / C<< $msg->revenue($value) >>

Type: C<Float>

Required. Total non-zero revenue or grand total associated with the
transaction. This value include shipping, tax, or other adjustments to
total revenue that you want to include as part of your revenue
calculations.

=item * C<< $msg->tax() >> / C<< $msg->tax($value) >>

Type: C<Float>

All the taxes associated with the transaction.

=item * C<< $msg->cost() >> / C<< $msg->cost($value) >>

Type: C<Float>

All the costs associated with the products. These can be manufacturing
costs, shipping expenses not borne by the end user, or any other costs,
such that:

* Profit =
[revenue][google.cloud.retail.v2alpha.PurchaseTransaction.revenue] -
[tax][google.cloud.retail.v2alpha.PurchaseTransaction.tax] -
[cost][google.cloud.retail.v2alpha.PurchaseTransaction.cost]

=item * C<< $msg->currency_code() >> / C<< $msg->currency_code($value) >>

Type: C<String>

Required. Currency code. Use three-character ISO-4217 code.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::UserEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
