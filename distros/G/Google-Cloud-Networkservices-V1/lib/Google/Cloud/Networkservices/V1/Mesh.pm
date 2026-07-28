package Google::Cloud::Networkservices::V1::Mesh;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Networkservices::V1::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL21lc2gucHJvdG8SH2dvb2dsZS5j
bG91ZC5uZXR3b3Jrc2VydmljZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91ZC9uZXR3b3Jrc2Vy
dmljZXMvdjEvY29tbW9uLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKIBQoETWVzaBIXCgRuYW1lGAEg
ASgJQgPgQQhSBG5hbWUSIAoJc2VsZl9saW5rGAkgASgJQgPgQQNSCHNlbGZMaW5rEkAKC2Ny
ZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lEk4KBmxhYmVscxgEIAMoCzIxLmdvb2dsZS5jbG91ZC5uZXR3
b3Jrc2VydmljZXMudjEuTWVzaC5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSJQoLZGVzY3Jp
cHRpb24YBSABKAlCA+BBAVILZGVzY3JpcHRpb24SMAoRaW50ZXJjZXB0aW9uX3BvcnQYCCAB
KAVCA+BBAVIQaW50ZXJjZXB0aW9uUG9ydBJcCg1lbnZveV9oZWFkZXJzGBAgASgOMi0uZ29v
Z2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5FbnZveUhlYWRlcnNCA+BBAUgAUgxlbnZv
eUhlYWRlcnOIAQEaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ATpt6kFqCiNuZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20v
TWVzaBI1cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L21lc2hlcy97
bWVzaH0qBm1lc2hlczIEbWVzaEIQCg5fZW52b3lfaGVhZGVycyLPAQoRTGlzdE1lc2hlc1Jl
cXVlc3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI25ldHdvcmtzZXJ2aWNlcy5nb29nbGVh
cGlzLmNvbS9NZXNoUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpw
YWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SOQoWcmV0dXJuX3BhcnRpYWxfc3VjY2VzcxgE
IAEoCEID4EEBUhRyZXR1cm5QYXJ0aWFsU3VjY2VzcyKdAQoSTGlzdE1lc2hlc1Jlc3BvbnNl
Ej0KBm1lc2hlcxgBIAMoCzIlLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuTWVz
aFIGbWVzaGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1
bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiUQoOR2V0TWVzaFJlcXVlc3QSPwoEbmFt
ZRgBIAEoCUIr4EEC+kElCiNuZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vTWVzaFIE
bmFtZSK2AQoRQ3JlYXRlTWVzaFJlcXVlc3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI25l
dHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9NZXNoUgZwYXJlbnQSHAoHbWVzaF9pZBgC
IAEoCUID4EECUgZtZXNoSWQSPgoEbWVzaBgDIAEoCzIlLmdvb2dsZS5jbG91ZC5uZXR3b3Jr
c2VydmljZXMudjEuTWVzaEID4EECUgRtZXNoIpUBChFVcGRhdGVNZXNoUmVxdWVzdBJACgt1
cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBk
YXRlTWFzaxI+CgRtZXNoGAIgASgLMiUuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52
MS5NZXNoQgPgQQJSBG1lc2giVAoRRGVsZXRlTWVzaFJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr
4EEC+kElCiNuZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vTWVzaFIEbmFtZULkAgoj
Y29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjFCCU1lc2hQcm90b1ABWk1jbG91
ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZXJ2aWNlcy9hcGl2MS9uZXR3b3Jrc2VydmljZXNw
YjtuZXR3b3Jrc2VydmljZXNwYqoCH0dvb2dsZS5DbG91ZC5OZXR3b3JrU2VydmljZXMuVjHK
Ah9Hb29nbGVcQ2xvdWRcTmV0d29ya1NlcnZpY2VzXFYx6gIiR29vZ2xlOjpDbG91ZDo6TmV0
d29ya1NlcnZpY2VzOjpWMepBdwooY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlQXR0
YWNobWVudBJLcHJvamVjdHMve3Byb2plY3R9L3JlZ2lvbnMve3JlZ2lvbn0vc2VydmljZUF0
dGFjaG1lbnRzL3tzZXJ2aWNlX2F0dGFjaG1lbnR9SqAwCgcSBQ4AswEBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAA2CgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYADwKCQoCCCUSAxgA
PAoICgEIEgMZAGQKCQoCCAsSAxkAZAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbACoK
CQoCCAgSAxsAKgoICgEIEgMcADwKCQoCCAESAxwAPAoICgEIEgMdADwKCQoCCCkSAx0APAoI
CgEIEgMeADsKCQoCCC0SAx4AOwoJCgEIEgQfACICCgwKBAidCAASBB8AIgIK3AEKAgQAEgQn
AFIBGs8BIE1lc2ggcmVwcmVzZW50cyBhIGxvZ2ljYWwgY29uZmlndXJhdGlvbiBncm91cGlu
ZyBmb3Igd29ya2xvYWQgdG8gd29ya2xvYWQKIGNvbW11bmljYXRpb24gd2l0aGluIGEgc2Vy
dmljZSBtZXNoLiBSb3V0ZXMgdGhhdCBwb2ludCB0byBtZXNoIGRpY3RhdGUgaG93CiByZXF1
ZXN0cyBhcmUgcm91dGVkIHdpdGhpbiB0aGlzIGxvZ2ljYWwgbWVzaCBib3VuZGFyeS4KCgoK
AwQAARIDJwgMCgsKAwQABxIEKAItBAoNCgUEAAedCBIEKAItBAp2CgQEAAIAEgMxAj0aaSBJ
ZGVudGlmaWVyLiBOYW1lIG9mIHRoZSBNZXNoIHJlc291cmNlLiBJdCBtYXRjaGVzIHBhdHRl
cm4KIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL21lc2hlcy88bWVzaF9uYW1lPmAuCgoMCgUE
AAIABRIDMQIICgwKBQQAAgABEgMxCQ0KDAoFBAACAAMSAzEQEQoMCgUEAAIACBIDMRI8Cg8K
CAQAAgAInAgAEgMxEzsKPwoEBAACARIDNAJDGjIgT3V0cHV0IG9ubHkuIFNlcnZlci1kZWZp
bmVkIFVSTCBvZiB0aGlzIHJlc291cmNlCgoMCgUEAAIBBRIDNAIICgwKBQQAAgEBEgM0CRIK
DAoFBAACAQMSAzQVFgoMCgUEAAIBCBIDNBdCCg8KCAQAAgEInAgAEgM0GEEKSQoEBAACAhIE
NwI4Mho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdh
cyBjcmVhdGVkLgoKDAoFBAACAgYSAzcCGwoMCgUEAAICARIDNxwnCgwKBQQAAgIDEgM3KisK
DAoFBAACAggSAzgGMQoPCggEAAICCJwIABIDOAcwCkkKBAQAAgMSBDsCPDIaOyBPdXRwdXQg
b25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgdXBkYXRlZC4KCgwK
BQQAAgMGEgM7AhsKDAoFBAACAwESAzscJwoMCgUEAAIDAxIDOyorCgwKBQQAAgMIEgM8BjEK
DwoIBAACAwicCAASAzwHMApNCgQEAAIEEgM/AkoaQCBPcHRpb25hbC4gU2V0IG9mIGxhYmVs
IHRhZ3MgYXNzb2NpYXRlZCB3aXRoIHRoZSBNZXNoIHJlc291cmNlLgoKDAoFBAACBAYSAz8C
FQoMCgUEAAIEARIDPxYcCgwKBQQAAgQDEgM/HyAKDAoFBAACBAgSAz8hSQoPCggEAAIECJwI
ABIDPyJICl4KBAQAAgUSA0MCQhpRIE9wdGlvbmFsLiBBIGZyZWUtdGV4dCBkZXNjcmlwdGlv
biBvZiB0aGUgcmVzb3VyY2UuIE1heCBsZW5ndGggMTAyNAogY2hhcmFjdGVycy4KCgwKBQQA
AgUFEgNDAggKDAoFBAACBQESA0MJFAoMCgUEAAIFAxIDQxcYCgwKBQQAAgUIEgNDGUEKDwoI
BAACBQicCAASA0MaQAqKAwoEBAACBhIDSwJHGvwCIE9wdGlvbmFsLiBJZiBzZXQgdG8gYSB2
YWxpZCBUQ1AgcG9ydCAoMS02NTUzNSksIGluc3RydWN0cyB0aGUgU0lERUNBUiBwcm94eQog
dG8gbGlzdGVuIG9uIHRoZSBzcGVjaWZpZWQgcG9ydCBvZiBsb2NhbGhvc3QgKDEyNy4wLjAu
MSkgYWRkcmVzcy4gVGhlCiBTSURFQ0FSIHByb3h5IHdpbGwgZXhwZWN0IGFsbCB0cmFmZmlj
IHRvIGJlIHJlZGlyZWN0ZWQgdG8gdGhpcyBwb3J0CiByZWdhcmRsZXNzIG9mIGl0cyBhY3R1
YWwgaXA6cG9ydCBkZXN0aW5hdGlvbi4gSWYgdW5zZXQsIGEgcG9ydCAnMTUwMDEnIGlzCiB1
c2VkIGFzIHRoZSBpbnRlcmNlcHRpb24gcG9ydC4gVGhpcyBpcyBhcHBsaWNhYmxlIG9ubHkg
Zm9yIHNpZGVjYXIgcHJveHkKIGRlcGxveW1lbnRzLgoKDAoFBAACBgUSA0sCBwoMCgUEAAIG
ARIDSwgZCgwKBQQAAgYDEgNLHB0KDAoFBAACBggSA0seRgoPCggEAAIGCJwIABIDSx9FCssB
CgQEAAIHEgRQAlEvGrwBIE9wdGlvbmFsLiBEZXRlcm1pbmVzIGlmIGVudm95IHdpbGwgaW5z
ZXJ0IGludGVybmFsIGRlYnVnIGhlYWRlcnMgaW50bwogdXBzdHJlYW0gcmVxdWVzdHMuIE90
aGVyIEVudm95IGhlYWRlcnMgbWF5IHN0aWxsIGJlIGluamVjdGVkLiBCeSBkZWZhdWx0LAog
ZW52b3kgd2lsbCBub3QgaW5zZXJ0IGFueSBkZWJ1ZyBoZWFkZXJzLgoKDAoFBAACBwQSA1AC
CgoMCgUEAAIHBhIDUAsXCgwKBQQAAgcBEgNQGCUKDAoFBAACBwMSA1AoKgoMCgUEAAIHCBID
UQYuCg8KCAQAAgcInAgAEgNRBy0KNgoCBAESBFUAawEaKiBSZXF1ZXN0IHVzZWQgd2l0aCB0
aGUgTGlzdE1lc2hlcyBtZXRob2QuCgoKCgMEAQESA1UIGQqNAQoEBAECABIEWAJdBBp/IFJl
cXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3aGljaCB0aGUgTWVzaGVz
IHNob3VsZCBiZQogbGlzdGVkLCBzcGVjaWZpZWQgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMv
Ki9sb2NhdGlvbnMvKmAuCgoMCgUEAQIABRIDWAIICgwKBQQBAgABEgNYCQ8KDAoFBAECAAMS
A1gSEwoNCgUEAQIACBIEWBRdAwoPCggEAQIACJwIABIDWQQqCg8KBwQBAgAInwgSBFoEXAUK
OwoEBAECARIDYAIWGi4gTWF4aW11bSBudW1iZXIgb2YgTWVzaGVzIHRvIHJldHVybiBwZXIg
Y2FsbC4KCgwKBQQBAgEFEgNgAgcKDAoFBAECAQESA2AIEQoMCgUEAQIBAxIDYBQVCsIBCgQE
AQICEgNlAhgatAEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0IGBMaXN0TWVzaGVz
UmVzcG9uc2VgCiBJbmRpY2F0ZXMgdGhhdCB0aGlzIGlzIGEgY29udGludWF0aW9uIG9mIGEg
cHJpb3IgYExpc3RNZXNoZXNgIGNhbGwsCiBhbmQgdGhhdCB0aGUgc3lzdGVtIHNob3VsZCBy
ZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBkYXRhLgoKDAoFBAECAgUSA2UCCAoMCgUEAQICARID
ZQkTCgwKBQQBAgIDEgNlFhcKygEKBAQBAgMSA2oCSxq8ASBPcHRpb25hbC4gSWYgdHJ1ZSwg
YWxsb3cgcGFydGlhbCByZXNwb25zZXMgZm9yIG11bHRpLXJlZ2lvbmFsIEFnZ3JlZ2F0ZWQK
IExpc3QgcmVxdWVzdHMuIE90aGVyd2lzZSBpZiBvbmUgb2YgdGhlIGxvY2F0aW9ucyBpcyBk
b3duIG9yIHVucmVhY2hhYmxlLAogdGhlIEFnZ3JlZ2F0ZWQgTGlzdCByZXF1ZXN0IHdpbGwg
ZmFpbC4KCgwKBQQBAgMFEgNqAgYKDAoFBAECAwESA2oHHQoMCgUEAQIDAxIDaiAhCgwKBQQB
AgMIEgNqIkoKDwoIBAECAwicCAASA2ojSQo5CgIEAhIEbgB7ARotIFJlc3BvbnNlIHJldHVy
bmVkIGJ5IHRoZSBMaXN0TWVzaGVzIG1ldGhvZC4KCgoKAwQCARIDbggaCiYKBAQCAgASA3AC
GxoZIExpc3Qgb2YgTWVzaCByZXNvdXJjZXMuCgoMCgUEAgIABBIDcAIKCgwKBQQCAgAGEgNw
Cw8KDAoFBAICAAESA3AQFgoMCgUEAgIAAxIDcBkaCugBCgQEAgIBEgN1Ah0a2gEgSWYgdGhl
cmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBwZWFyaW5nIGluIHRoaXMg
cmVzcG9uc2UsIHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGluY2x1ZGVkLiBUbyBnZXQg
dGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0aG9kIGFnYWluIHVzaW5n
IHRoZSB2YWx1ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFnZV90b2tlbmAuCgoMCgUE
AgIBBRIDdQIICgwKBQQCAgEBEgN1CRgKDAoFBAICAQMSA3UbHArQAQoEBAICAhIDegIiGsIB
IFVucmVhY2hhYmxlIHJlc291cmNlcy4gUG9wdWxhdGVkIHdoZW4gdGhlIHJlcXVlc3Qgb3B0
cyBpbnRvCiBgcmV0dXJuX3BhcnRpYWxfc3VjY2Vzc2AgYW5kIHJlYWRpbmcgYWNyb3NzIGNv
bGxlY3Rpb25zIGUuZy4gd2hlbgogYXR0ZW1wdGluZyB0byBsaXN0IGFsbCByZXNvdXJjZXMg
YWNyb3NzIGFsbCBzdXBwb3J0ZWQgbG9jYXRpb25zLgoKDAoFBAICAgQSA3oCCgoMCgUEAgIC
BRIDegsRCgwKBQQCAgIBEgN6Eh0KDAoFBAICAgMSA3ogIQoyCgIEAxIFfgCHAQEaJSBSZXF1
ZXN0IHVzZWQgYnkgdGhlIEdldE1lc2ggbWV0aG9kLgoKCgoDBAMBEgN+CBYKcAoEBAMCABIG
gQEChgEEGmAgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgTWVzaCB0byBnZXQuIE11c3QgYmUg
aW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovbWVzaGVzLypgLgoKDQoF
BAMCAAUSBIEBAggKDQoFBAMCAAESBIEBCQ0KDQoFBAMCAAMSBIEBEBEKDwoFBAMCAAgSBoEB
EoYBAwoQCggEAwIACJwIABIEggEEKgoRCgcEAwIACJ8IEgaDAQSFAQUKNgoCBAQSBooBAJkB
ARooIFJlcXVlc3QgdXNlZCBieSB0aGUgQ3JlYXRlTWVzaCBtZXRob2QuCgoLCgMEBAESBIoB
CBkKbQoEBAQCABIGjQECkgEEGl0gUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2Yg
dGhlIE1lc2guIE11c3QgYmUgaW4gdGhlCiBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25z
LypgLgoKDQoFBAQCAAUSBI0BAggKDQoFBAQCAAESBI0BCQ8KDQoFBAQCAAMSBI0BEhMKDwoF
BAQCAAgSBo0BFJIBAwoQCggEBAIACJwIABIEjgEEKgoRCgcEBAIACJ8IEgaPAQSRAQUKSAoE
BAQCARIElQECPho6IFJlcXVpcmVkLiBTaG9ydCBuYW1lIG9mIHRoZSBNZXNoIHJlc291cmNl
IHRvIGJlIGNyZWF0ZWQuCgoNCgUEBAIBBRIElQECCAoNCgUEBAIBARIElQEJEAoNCgUEBAIB
AxIElQETFAoNCgUEBAIBCBIElQEVPQoQCggEBAIBCJwIABIElQEWPAo2CgQEBAICEgSYAQI5
GiggUmVxdWlyZWQuIE1lc2ggcmVzb3VyY2UgdG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgSY
AQIGCg0KBQQEAgIBEgSYAQcLCg0KBQQEAgIDEgSYAQ4PCg0KBQQEAgIIEgSYARA4ChAKCAQE
AgIInAgAEgSYARE3CjYKAgQFEgacAQCnAQEaKCBSZXF1ZXN0IHVzZWQgYnkgdGhlIFVwZGF0
ZU1lc2ggbWV0aG9kLgoKCwoDBAUBEgScAQgZCtYCCgQEBQIAEgaiAQKjAS8axQIgT3B0aW9u
YWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3Zl
cndyaXR0ZW4gaW4gdGhlCiBNZXNoIHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmll
bGRzIHNwZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSBy
ZXNvdXJjZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3Zlcndy
aXR0ZW4gaWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92
aWRlIGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCg0KBQQF
AgAGEgSiAQIbCg0KBQQFAgABEgSiARwnCg0KBQQFAgADEgSiASorCg0KBQQFAgAIEgSjAQYu
ChAKCAQFAgAInAgAEgSjAQctCjAKBAQFAgESBKYBAjkaIiBSZXF1aXJlZC4gVXBkYXRlZCBN
ZXNoIHJlc291cmNlLgoKDQoFBAUCAQYSBKYBAgYKDQoFBAUCAQESBKYBBwsKDQoFBAUCAQMS
BKYBDg8KDQoFBAUCAQgSBKYBEDgKEAoIBAUCAQicCAASBKYBETcKNgoCBAYSBqoBALMBARoo
IFJlcXVlc3QgdXNlZCBieSB0aGUgRGVsZXRlTWVzaCBtZXRob2QuCgoLCgMEBgESBKoBCBkK
cwoEBAYCABIGrQECsgEEGmMgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgTWVzaCB0byBkZWxl
dGUuIE11c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovbWVz
aGVzLypgLgoKDQoFBAYCAAUSBK0BAggKDQoFBAYCAAESBK0BCQ0KDQoFBAYCAAMSBK0BEBEK
DwoFBAYCAAgSBq0BErIBAwoQCggEBgIACJwIABIErgEEKgoRCgcEBgIACJ8IEgavAQSxAQVi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::Mesh::Mesh ===
    # Fields for Mesh
    # Field: name Type: 9 ()
    # Field: self_link Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.Mesh.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: interception_port Type: 5 ()
    # Field: envoy_headers Type: 14 (.google.cloud.networkservices.v1.EnvoyHeaders)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::Mesh - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::Mesh->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<self_link>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<labels>

Type: Message (.google.cloud.networkservices.v1.Mesh.LabelsEntry)

=item * B<description>

Type: String

=item * B<interception_port>

Type: Int32

=item * B<envoy_headers>

Type: Enum (.google.cloud.networkservices.v1.EnvoyHeaders)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::Mesh::ListMeshesRequest ===
    # Fields for ListMeshesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: return_partial_success Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::ListMeshesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::ListMeshesRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<return_partial_success>

Type: Bool

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::Mesh::ListMeshesResponse ===
    # Fields for ListMeshesResponse
    # Field: meshes Type: 11 (.google.cloud.networkservices.v1.Mesh)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::ListMeshesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::ListMeshesResponse->new(
        meshes => $value,
    );

=head1 FIELDS

=over 4

=item * B<meshes>

Type: Message (.google.cloud.networkservices.v1.Mesh)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::Mesh::GetMeshRequest ===
    # Fields for GetMeshRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::GetMeshRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::GetMeshRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::Mesh::CreateMeshRequest ===
    # Fields for CreateMeshRequest
    # Field: parent Type: 9 ()
    # Field: mesh_id Type: 9 ()
    # Field: mesh Type: 11 (.google.cloud.networkservices.v1.Mesh)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::CreateMeshRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::CreateMeshRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<mesh_id>

Type: String

=item * B<mesh>

Type: Message (.google.cloud.networkservices.v1.Mesh)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::Mesh::UpdateMeshRequest ===
    # Fields for UpdateMeshRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: mesh Type: 11 (.google.cloud.networkservices.v1.Mesh)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::UpdateMeshRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::UpdateMeshRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<mesh>

Type: Message (.google.cloud.networkservices.v1.Mesh)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::Mesh::DeleteMeshRequest ===
    # Fields for DeleteMeshRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh::DeleteMeshRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::Mesh;

    my $msg = Google::Cloud::Networkservices::V1::Mesh::DeleteMeshRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::Mesh - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
