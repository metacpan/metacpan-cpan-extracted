package Google::Cloud::Bigquery::Storage::V1beta::Partition;

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
CjRnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEvcGFydGl0aW9uLnByb3Rv
EiRnb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8iPwoLRmllbGRTY2hlbWESFwoEbmFtZRgBIAEoCUID
4EECUgRuYW1lEhcKBHR5cGUYAiABKAlCA+BBAlIEdHlwZSLiAQoRU3RvcmFnZURlc2NyaXB0
b3ISJgoMbG9jYXRpb25fdXJpGAEgASgJQgPgQQFSC2xvY2F0aW9uVXJpEiYKDGlucHV0X2Zv
cm1hdBgCIAEoCUID4EEBUgtpbnB1dEZvcm1hdBIoCg1vdXRwdXRfZm9ybWF0GAMgASgJQgPg
QQFSDG91dHB1dEZvcm1hdBJTCgpzZXJkZV9pbmZvGAQgASgLMi8uZ29vZ2xlLmNsb3VkLmJp
Z3F1ZXJ5LnN0b3JhZ2UudjFiZXRhLlNlckRlSW5mb0ID4EEBUglzZXJkZUluZm8igwIKCVNl
ckRlSW5mbxIXCgRuYW1lGAEgASgJQgPgQQFSBG5hbWUSOAoVc2VyaWFsaXphdGlvbl9saWJy
YXJ5GAIgASgJQgPgQQJSFHNlcmlhbGl6YXRpb25MaWJyYXJ5EmQKCnBhcmFtZXRlcnMYAyAD
KAsyPy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEuU2VyRGVJbmZvLlBh
cmFtZXRlcnNFbnRyeUID4EEBUgpwYXJhbWV0ZXJzGj0KD1BhcmFtZXRlcnNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIt4DChJNZXRhc3RvcmVQ
YXJ0aXRpb24SGwoGdmFsdWVzGAEgAygJQgPgQQJSBnZhbHVlcxJACgtjcmVhdGVfdGltZRgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJrChJz
dG9yYWdlX2Rlc2NyaXB0b3IYAyABKAsyNy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFn
ZS52MWJldGEuU3RvcmFnZURlc2NyaXB0b3JCA+BBAVIRc3RvcmFnZURlc2NyaXB0b3ISbQoK
cGFyYW1ldGVycxgEIAMoCzJILmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0
YS5NZXRhc3RvcmVQYXJ0aXRpb24uUGFyYW1ldGVyc0VudHJ5QgPgQQFSCnBhcmFtZXRlcnMS
TgoGZmllbGRzGAUgAygLMjEuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRh
LkZpZWxkU2NoZW1hQgPgQQFSBmZpZWxkcxo9Cg9QYXJhbWV0ZXJzRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJ3ChZNZXRhc3RvcmVQYXJ0aXRp
b25MaXN0El0KCnBhcnRpdGlvbnMYASADKAsyOC5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3Rv
cmFnZS52MWJldGEuTWV0YXN0b3JlUGFydGl0aW9uQgPgQQJSCnBhcnRpdGlvbnMiwAEKClJl
YWRTdHJlYW0SGgoEbmFtZRgBIAEoCUIG4EED4EEIUgRuYW1lOpUB6kGRAQopYmlncXVlcnlz
dG9yYWdlLmdvb2dsZWFwaXMuY29tL1JlYWRTdHJlYW0SS3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9zZXNzaW9ucy97c2Vzc2lvbn0vc3RyZWFtcy97c3RyZWFt
fSoLcmVhZFN0cmVhbXMyCnJlYWRTdHJlYW0iXQoKU3RyZWFtTGlzdBJPCgdzdHJlYW1zGAEg
AygLMjAuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhLlJlYWRTdHJlYW1C
A+BBA1IHc3RyZWFtcyI3ChhNZXRhc3RvcmVQYXJ0aXRpb25WYWx1ZXMSGwoGdmFsdWVzGAEg
AygJQgPgQQJSBnZhbHVlc0LXAQooY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdl
LnYxYmV0YUIXTWV0YXN0b3JlUGFydGl0aW9uUHJvdG9QAVpCY2xvdWQuZ29vZ2xlLmNvbS9n
by9iaWdxdWVyeS9zdG9yYWdlL2FwaXYxYmV0YS9zdG9yYWdlcGI7c3RvcmFnZXBiqgIkR29v
Z2xlLkNsb3VkLkJpZ1F1ZXJ5LlN0b3JhZ2UuVjFCZXRhygIkR29vZ2xlXENsb3VkXEJpZ1F1
ZXJ5XFN0b3JhZ2VcVjFiZXRhSvcnCgcSBQ4AiwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAp
CggKAQgSAxYAQQoJCgIIJRIDFgBBCggKAQgSAxcAWQoJCgIICxIDFwBZCggKAQgSAxgAIgoJ
CgIIChIDGAAiCggKAQgSAxkAOAoJCgIICBIDGQA4CggKAQgSAxoAQQoJCgIIARIDGgBBCggK
AQgSAxsAQgoJCgIIKRIDGwBCCkEKAgQAEgQeACYBGjUgU2NoZW1hIGRlc2NyaXB0aW9uIG9m
IGEgbWV0YXN0b3JlIHBhcnRpdGlvbiBjb2x1bW4uCgoKCgMEAAESAx4IEwpjCgQEAAIAEgMh
AjsaViBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGNvbHVtbi4KIFRoZSBtYXhpbXVtIGxl
bmd0aCBvZiB0aGUgbmFtZSBpcyAxMDI0IGNoYXJhY3RlcnMKCgwKBQQAAgAFEgMhAggKDAoF
BAACAAESAyEJDQoMCgUEAAIAAxIDIRARCgwKBQQAAgAIEgMhEjoKDwoIBAACAAicCAASAyET
OQpwCgQEAAIBEgMlAjsaYyBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgdGhlIG1ldGFzdG9yZSBw
YXJ0aXRpb24gY29sdW1uLiBNYXhpbXVtIGFsbG93ZWQKIGxlbmd0aCBpcyAxMDI0IGNoYXJh
Y3RlcnMuCgoMCgUEAAIBBRIDJQIICgwKBQQAAgEBEgMlCQ0KDAoFBAACAQMSAyUQEQoMCgUE
AAIBCBIDJRI6Cg8KCAQAAgEInAgAEgMlEzkKZgoCBAESBCoAPAEaWiBDb250YWlucyBpbmZv
cm1hdGlvbiBhYm91dCB0aGUgcGh5c2ljYWwgc3RvcmFnZSBvZiB0aGUgZGF0YSBpbiB0aGUg
bWV0YXN0b3JlCiBwYXJ0aXRpb24uCgoKCgMEAQESAyoIGQq3AQoEBAECABIDLgJDGqkBIE9w
dGlvbmFsLiBUaGUgcGh5c2ljYWwgbG9jYXRpb24gb2YgdGhlIG1ldGFzdG9yZSBwYXJ0aXRp
b24KIChlLmcuIGBnczovL3NwYXJrLWRhdGFwcm9jLWRhdGEvcGFuZ2VhLWRhdGEvY2FzZV9z
ZW5zaXRpdmUvYCBvcgogYGdzOi8vc3BhcmstZGF0YXByb2MtZGF0YS9wYW5nZWEtZGF0YS8q
YCkuCgoMCgUEAQIABRIDLgIICgwKBQQBAgABEgMuCRUKDAoFBAECAAMSAy4YGQoMCgUEAQIA
CBIDLhpCCg8KCAQBAgAInAgAEgMuG0EKtwEKBAQBAgESAzMCQxqpASBPcHRpb25hbC4gU3Bl
Y2lmaWVzIHRoZSBmdWxseSBxdWFsaWZpZWQgY2xhc3MgbmFtZSBvZiB0aGUgSW5wdXRGb3Jt
YXQKIChlLmcuICJvcmcuYXBhY2hlLmhhZG9vcC5oaXZlLnFsLmlvLm9yYy5PcmNJbnB1dEZv
cm1hdCIpLgogVGhlIG1heGltdW0gbGVuZ3RoIGlzIDEyOCBjaGFyYWN0ZXJzLgoKDAoFBAEC
AQUSAzMCCAoMCgUEAQIBARIDMwkVCgwKBQQBAgEDEgMzGBkKDAoFBAECAQgSAzMaQgoPCggE
AQIBCJwIABIDMxtBCrkBCgQEAQICEgM4AkQaqwEgT3B0aW9uYWwuIFNwZWNpZmllcyB0aGUg
ZnVsbHkgcXVhbGlmaWVkIGNsYXNzIG5hbWUgb2YgdGhlIE91dHB1dEZvcm1hdAogKGUuZy4g
Im9yZy5hcGFjaGUuaGFkb29wLmhpdmUucWwuaW8ub3JjLk9yY091dHB1dEZvcm1hdCIpLgog
VGhlIG1heGltdW0gbGVuZ3RoIGlzIDEyOCBjaGFyYWN0ZXJzLgoKDAoFBAECAgUSAzgCCAoM
CgUEAQICARIDOAkWCgwKBQQBAgIDEgM4GRoKDAoFBAECAggSAzgbQwoPCggEAQICCJwIABID
OBxCCkEKBAQBAgMSAzsCRBo0IE9wdGlvbmFsLiBTZXJpYWxpemVyIGFuZCBkZXNlcmlhbGl6
ZXIgaW5mb3JtYXRpb24uCgoMCgUEAQIDBhIDOwILCgwKBQQBAgMBEgM7DBYKDAoFBAECAwMS
AzsZGgoMCgUEAQIDCBIDOxtDCg8KCAQBAgMInAgAEgM7HEIKNgoCBAISBD8ATgEaKiBTZXJp
YWxpemVyIGFuZCBkZXNlcmlhbGl6ZXIgaW5mb3JtYXRpb24uCgoKCgMEAgESAz8IEQpSCgQE
AgIAEgNCAjsaRSBPcHRpb25hbC4gTmFtZSBvZiB0aGUgU2VyRGUuCiBUaGUgbWF4aW11bSBs
ZW5ndGggaXMgMjU2IGNoYXJhY3RlcnMuCgoMCgUEAgIABRIDQgIICgwKBQQCAgABEgNCCQ0K
DAoFBAICAAMSA0IQEQoMCgUEAgIACBIDQhI6Cg8KCAQCAgAInAgAEgNCEzkKlAIKBAQCAgES
A0gCTBqGAiBSZXF1aXJlZC4gU3BlY2lmaWVzIGEgZnVsbHktcXVhbGlmaWVkIGNsYXNzIG5h
bWUgb2YgdGhlIHNlcmlhbGl6YXRpb24KIGxpYnJhcnkgdGhhdCBpcyByZXNwb25zaWJsZSBm
b3IgdGhlIHRyYW5zbGF0aW9uIG9mIGRhdGEgYmV0d2VlbiB0YWJsZQogcmVwcmVzZW50YXRp
b24gYW5kIHRoZSB1bmRlcmx5aW5nIGxvdy1sZXZlbCBpbnB1dCBhbmQgb3V0cHV0IGZvcm1h
dAogc3RydWN0dXJlcy4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDI1NiBjaGFyYWN0ZXJzLgoK
DAoFBAICAQUSA0gCCAoMCgUEAgIBARIDSAkeCgwKBQQCAgEDEgNIISIKDAoFBAICAQgSA0gj
SwoPCggEAgIBCJwIABIDSCRKCogBCgQEAgICEgNNAk4aeyBPcHRpb25hbC4gS2V5LXZhbHVl
IHBhaXJzIHRoYXQgZGVmaW5lIHRoZSBpbml0aWFsaXphdGlvbiBwYXJhbWV0ZXJzIGZvciB0
aGUKIHNlcmlhbGl6YXRpb24gbGlicmFyeS4KIE1heGltdW0gc2l6ZSAxMCBLaWIuCgoMCgUE
AgICBhIDTQIVCgwKBQQCAgIBEgNNFiAKDAoFBAICAgMSA00jJAoMCgUEAgICCBIDTSVNCg8K
CAQCAgIInAgAEgNNJkwKMQoCBAMSBFEAZgEaJSBJbmZvcm1hdGlvbiBhYm91dCBhIEhpdmUg
cGFydGl0aW9uLgoKCgoDBAMBEgNRCBoK1wEKBAQDAgASA1UCRhrJASBSZXF1aXJlZC4gUmVw
cmVzZW50cyB0aGUgdmFsdWVzIG9mIHRoZSBwYXJ0aXRpb24ga2V5cywgd2hlcmUgZWFjaCB2
YWx1ZQogY29ycmVzcG9uZHMgdG8gYSBzcGVjaWZpYyBwYXJ0aXRpb24ga2V5IGluIHRoZSBv
cmRlciBpbiB3aGljaCB0aGUga2V5cyBhcmUKIGRlZmluZWQuIEVhY2ggdmFsdWUgaXMgbGlt
aXRlZCB0byAxMDI0IGNoYXJhY3RlcnMuCgoMCgUEAwIABBIDVQIKCgwKBQQDAgAFEgNVCxEK
DAoFBAMCAAESA1USGAoMCgUEAwIAAxIDVRscCgwKBQQDAgAIEgNVHUUKDwoIBAMCAAicCAAS
A1UeRApACgQEAwIBEgRYAlkyGjIgT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGlvbiB0aW1lIG9m
IHRoZSBwYXJ0aXRpb24uCgoMCgUEAwIBBhIDWAIbCgwKBQQDAgEBEgNYHCcKDAoFBAMCAQMS
A1gqKwoMCgUEAwIBCBIDWQYxCg8KCAQDAgEInAgAEgNZBzAKaAoEBAMCAhIEXQJeLxpaIE9w
dGlvbmFsLiBDb250YWlucyBpbmZvcm1hdGlvbiBhYm91dCB0aGUgcGh5c2ljYWwgc3RvcmFn
ZSBvZiB0aGUgZGF0YSBpbgogdGhlIHBhcnRpdGlvbi4KCgwKBQQDAgIGEgNdAhMKDAoFBAMC
AgESA10UJgoMCgUEAwICAxIDXSkqCgwKBQQDAgIIEgNeBi4KDwoIBAMCAgicCAASA14HLQpv
CgQEAwIDEgNiAk4aYiBPcHRpb25hbC4gQWRkaXRpb25hbCBwYXJhbWV0ZXJzIG9yIG1ldGFk
YXRhIGFzc29jaWF0ZWQgd2l0aCB0aGUgcGFydGl0aW9uLgogTWF4aW11bSBzaXplIDEwIEtp
Qi4KCgwKBQQDAgMGEgNiAhUKDAoFBAMCAwESA2IWIAoMCgUEAwIDAxIDYiMkCgwKBQQDAgMI
EgNiJU0KDwoIBAMCAwicCAASA2ImTAopCgQEAwIEEgNlAksaHCBPcHRpb25hbC4gTGlzdCBv
ZiBjb2x1bW5zLgoKDAoFBAMCBAQSA2UCCgoMCgUEAwIEBhIDZQsWCgwKBQQDAgQBEgNlFx0K
DAoFBAMCBAMSA2UgIQoMCgUEAwIECBIDZSJKCg8KCAQDAgQInAgAEgNlI0kKKwoCBAQSBGkA
bQEaHyBMaXN0IG9mIG1ldGFzdG9yZSBwYXJ0aXRpb25zLgoKCgoDBAQBEgNpCB4KLQoEBAQC
ABIEawJsLxofIFJlcXVpcmVkLiBMaXN0IG9mIHBhcnRpdGlvbnMuCgoMCgUEBAIABBIDawIK
CgwKBQQEAgAGEgNrCx0KDAoFBAQCAAESA2seKAoMCgUEBAIAAxIDayssCgwKBQQEAgAIEgNs
Bi4KDwoIBAQCAAicCAASA2wHLQpQCgIEBRIEcAB+ARpEIEluZm9ybWF0aW9uIGFib3V0IGEg
c2luZ2xlIHN0cmVhbSB0aGF0IGlzIHVzZWQgdG8gcmVhZCBwYXJ0aXRpb25zLgoKCgoDBAUB
EgNwCBIKCwoDBAUHEgRxAnYECg0KBQQFB50IEgRxAnYECqIBCgQEBQIAEgR6An0EGpMBIE91
dHB1dCBvbmx5LiBJZGVudGlmaWVyLiBOYW1lIG9mIHRoZSBzdHJlYW0sIGluIHRoZSBmb3Jt
CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nlc3Npb25z
L3tzZXNzaW9uX2lkfS9zdHJlYW1zL3tzdHJlYW1faWR9YC4KCgwKBQQFAgAFEgN6AggKDAoF
BAUCAAESA3oJDQoMCgUEBQIAAxIDehARCg0KBQQFAgAIEgR6En0DCg8KCAQFAgAInAgAEgN7
BC0KDwoIBAUCAAicCAESA3wELAogCgIEBhIGgQEAhAEBGhIgTGlzdCBvZiBzdHJlYW1zLgoK
CwoDBAYBEgSBAQgSCi0KBAQGAgASBIMBAk4aHyBPdXRwdXQgb25seS4gTGlzdCBvZiBzdHJl
YW1zLgoKDQoFBAYCAAQSBIMBAgoKDQoFBAYCAAYSBIMBCxUKDQoFBAYCAAESBIMBFh0KDQoF
BAYCAAMSBIMBICEKDQoFBAYCAAgSBIMBIk0KEAoIBAYCAAicCAASBIMBI0wKPwoCBAcSBocB
AIsBARoxIFJlcHJlc2VudHMgdGhlIHZhbHVlcyBvZiBhIG1ldGFzdG9yZSBwYXJ0aXRpb24u
CgoLCgMEBwESBIcBCCAKogEKBAQHAgASBIoBAkYakwEgUmVxdWlyZWQuIFRoZSB2YWx1ZXMg
b2YgdGhlIHBhcnRpdGlvbiBrZXlzLCB3aGVyZSBlYWNoIHZhbHVlIGNvcnJlc3BvbmRzIHRv
CiBhIHNwZWNpZmljIHBhcnRpdGlvbiBrZXkgaW4gdGhlIG9yZGVyIGluIHdoaWNoIHRoZSBr
ZXlzIGFyZSBkZWZpbmVkLgoKDQoFBAcCAAQSBIoBAgoKDQoFBAcCAAUSBIoBCxEKDQoFBAcC
AAESBIoBEhgKDQoFBAcCAAMSBIoBGxwKDQoFBAcCAAgSBIoBHUUKEAoIBAcCAAicCAASBIoB
HkRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema ===
    # Fields for FieldSchema
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::StorageDescriptor ===
    # Fields for StorageDescriptor
    # Field: location_uri Type: 9 ()
    # Field: input_format Type: 9 ()
    # Field: output_format Type: 9 ()
    # Field: serde_info Type: 11 (.google.cloud.bigquery.storage.v1beta.SerDeInfo)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo ===
    # Fields for SerDeInfo
    # Field: name Type: 9 ()
    # Field: serialization_library Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.bigquery.storage.v1beta.SerDeInfo.ParametersEntry)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition ===
    # Fields for MetastorePartition
    # Field: values Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: storage_descriptor Type: 11 (.google.cloud.bigquery.storage.v1beta.StorageDescriptor)
    # Field: parameters Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition.ParametersEntry)
    # Field: fields Type: 11 (.google.cloud.bigquery.storage.v1beta.FieldSchema)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionList ===
    # Fields for MetastorePartitionList
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::ReadStream ===
    # Fields for ReadStream
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::StreamList ===
    # Fields for StreamList
    # Field: streams Type: 11 (.google.cloud.bigquery.storage.v1beta.ReadStream)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionValues ===
    # Fields for MetastorePartitionValues
    # Field: values Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta::Partition - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta/partition.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta::Partition;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema->new({
        name => $name,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta/partition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema

Schema description of a metastore partition column.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the column.
The maximum length of the name is 1024 characters

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The type of the metastore partition column. Maximum allowed
length is 1024 characters.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::StorageDescriptor

Contains information about the physical storage of the data in the metastore
partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location_uri() >> / C<< $msg->location_uri($value) >>

Type: C<String>

Optional. The physical location of the metastore partition
(e.g. `gs://spark-dataproc-data/pangea-data/case_sensitive/` or
`gs://spark-dataproc-data/pangea-data/*`).

=item * C<< $msg->input_format() >> / C<< $msg->input_format($value) >>

Type: C<String>

Optional. Specifies the fully qualified class name of the InputFormat
(e.g. "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat").
The maximum length is 128 characters.

=item * C<< $msg->output_format() >> / C<< $msg->output_format($value) >>

Type: C<String>

Optional. Specifies the fully qualified class name of the OutputFormat
(e.g. "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat").
The maximum length is 128 characters.

=item * C<< $msg->serde_info() >> / C<< $msg->serde_info($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo>)

Optional. Serializer and deserializer information.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo

Serializer and deserializer information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Name of the SerDe.
The maximum length is 256 characters.

=item * C<< $msg->serialization_library() >> / C<< $msg->serialization_library($value) >>

Type: C<String>

Required. Specifies a fully-qualified class name of the serialization
library that is responsible for the translation of data between table
representation and the underlying low-level input and output format
structures. The maximum length is 256 characters.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo::ParametersEntry>)

Optional. Key-value pairs that define the initialization parameters for the
serialization library.
Maximum size 10 Kib.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition

Information about a Hive partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. Represents the values of the partition keys, where each value
corresponds to a specific partition key in the order in which the keys are
defined. Each value is limited to 1024 characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time of the partition.

=item * C<< $msg->storage_descriptor() >> / C<< $msg->storage_descriptor($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::StorageDescriptor>)

Optional. Contains information about the physical storage of the data in
the partition.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition::ParametersEntry>)

Optional. Additional parameters or metadata associated with the partition.
Maximum size 10 KiB.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema>)

Optional. List of columns.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionList

List of metastore partitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>)

Required. List of partitions.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::ReadStream

Information about a single stream that is used to read partitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. Name of the stream, in the form
`projects/{project_id}/locations/{location}/sessions/{session_id}/streams/{stream_id}`.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::StreamList

List of streams.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->streams() >> / C<< $msg->streams($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::ReadStream>)

Output only. List of streams.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionValues

Represents the values of a metastore partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. The values of the partition keys, where each value corresponds to
a specific partition key in the order in which the keys are defined.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta::Partition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
