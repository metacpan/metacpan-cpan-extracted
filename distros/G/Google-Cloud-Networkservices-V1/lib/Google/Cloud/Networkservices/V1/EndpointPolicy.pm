package Google::Cloud::Networkservices::V1::EndpointPolicy;

use strict;
use warnings;

our $VERSION = '0.12';

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
CjVnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL2VuZHBvaW50X3BvbGljeS5wcm90
bxIfZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3Vk
L25ldHdvcmtzZXJ2aWNlcy92MS9jb21tb24ucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVs
ZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrAJCg5FbmRw
b2ludFBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBk
YXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0
ZVRpbWUSWAoGbGFiZWxzGAQgAygLMjsuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52
MS5FbmRwb2ludFBvbGljeS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSWwoEdHlwZRgFIAEo
DjJCLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuRW5kcG9pbnRQb2xpY3kuRW5k
cG9pbnRQb2xpY3lUeXBlQgPgQQJSBHR5cGUSbQoUYXV0aG9yaXphdGlvbl9wb2xpY3kYByAB
KAlCOuBBAfpBNAoybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0F1dGhvcml6YXRp
b25Qb2xpY3lSE2F1dGhvcml6YXRpb25Qb2xpY3kSYAoQZW5kcG9pbnRfbWF0Y2hlchgJIAEo
CzIwLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuRW5kcG9pbnRNYXRjaGVyQgPg
QQJSD2VuZHBvaW50TWF0Y2hlchJtChV0cmFmZmljX3BvcnRfc2VsZWN0b3IYCiABKAsyNC5n
b29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLlRyYWZmaWNQb3J0U2VsZWN0b3JCA+BB
AVITdHJhZmZpY1BvcnRTZWxlY3RvchIlCgtkZXNjcmlwdGlvbhgLIAEoCUID4EEBUgtkZXNj
cmlwdGlvbhJiChFzZXJ2ZXJfdGxzX3BvbGljeRgMIAEoCUI24EEB+kEwCi5uZXR3b3Jrc2Vj
dXJpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmVyVGxzUG9saWN5Ug9zZXJ2ZXJUbHNQb2xpY3kS
ZAoRY2xpZW50X3Rsc19wb2xpY3kYDSABKAlCOBgB4EEB+kEwCi5uZXR3b3Jrc2VjdXJpdHku
Z29vZ2xlYXBpcy5jb20vQ2xpZW50VGxzUG9saWN5Ug9jbGllbnRUbHNQb2xpY3kaOQoLTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJe
ChJFbmRwb2ludFBvbGljeVR5cGUSJAogRU5EUE9JTlRfUE9MSUNZX1RZUEVfVU5TUEVDSUZJ
RUQQABIRCg1TSURFQ0FSX1BST1hZEAESDwoLR1JQQ19TRVJWRVIQAjp+6kF7Ci1uZXR3b3Jr
c2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnRQb2xpY3kSSnByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9lbmRwb2ludFBvbGljaWVzL3tlbmRwb2ludF9w
b2xpY3l9IuMBChtMaXN0RW5kcG9pbnRQb2xpY2llc1JlcXVlc3QSTQoGcGFyZW50GAEgASgJ
QjXgQQL6QS8SLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmRwb2ludFBvbGlj
eVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuEjkKFnJldHVybl9wYXJ0aWFsX3N1Y2Nlc3MYBCABKAhCA+BBAVIU
cmV0dXJuUGFydGlhbFN1Y2Nlc3MixgEKHExpc3RFbmRwb2ludFBvbGljaWVzUmVzcG9uc2US
XAoRZW5kcG9pbnRfcG9saWNpZXMYASADKAsyLy5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxLkVuZHBvaW50UG9saWN5UhBlbmRwb2ludFBvbGljaWVzEiYKD25leHRfcGFnZV90
b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFj
aGFibGUiZQoYR2V0RW5kcG9pbnRQb2xpY3lSZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBBAvpB
LwotbmV0d29ya3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0VuZHBvaW50UG9saWN5UgRuYW1l
Iv4BChtDcmVhdGVFbmRwb2ludFBvbGljeVJlcXVlc3QSTQoGcGFyZW50GAEgASgJQjXgQQL6
QS8SLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmRwb2ludFBvbGljeVIGcGFy
ZW50EjEKEmVuZHBvaW50X3BvbGljeV9pZBgCIAEoCUID4EECUhBlbmRwb2ludFBvbGljeUlk
El0KD2VuZHBvaW50X3BvbGljeRgDIAEoCzIvLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2Vydmlj
ZXMudjEuRW5kcG9pbnRQb2xpY3lCA+BBAlIOZW5kcG9pbnRQb2xpY3kivgEKG1VwZGF0ZUVu
ZHBvaW50UG9saWN5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJdCg9lbmRwb2ludF9wb2xpY3kYAiAB
KAsyLy5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLkVuZHBvaW50UG9saWN5QgPg
QQJSDmVuZHBvaW50UG9saWN5ImgKG0RlbGV0ZUVuZHBvaW50UG9saWN5UmVxdWVzdBJJCgRu
YW1lGAEgASgJQjXgQQL6QS8KLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmRw
b2ludFBvbGljeVIEbmFtZUKGBQojY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMu
djFCE0VuZHBvaW50UG9saWN5UHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jr
c2VydmljZXMvYXBpdjEvbmV0d29ya3NlcnZpY2VzcGI7bmV0d29ya3NlcnZpY2VzcGKqAh9H
b29nbGUuQ2xvdWQuTmV0d29ya1NlcnZpY2VzLlYxygIfR29vZ2xlXENsb3VkXE5ldHdvcmtT
ZXJ2aWNlc1xWMeoCIkdvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZXJ2aWNlczo6VjHqQYoBCjJu
ZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vQXV0aG9yaXphdGlvblBvbGljeRJUcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dGhvcml6YXRpb25Qb2xp
Y2llcy97YXV0aG9yaXphdGlvbl9wb2xpY3l96kF/Ci5uZXR3b3Jrc2VjdXJpdHkuZ29vZ2xl
YXBpcy5jb20vU2VydmVyVGxzUG9saWN5Ek1wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vc2VydmVyVGxzUG9saWNpZXMve3NlcnZlcl90bHNfcG9saWN5fepBfwou
bmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGljeRJNcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsaWVudFRsc1BvbGljaWVzL3tj
bGllbnRfdGxzX3BvbGljeX1K+j8KBxIFDgDtAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADYK
CQoCAwMSAxUAKgoJCgIDBBIDFgApCggKAQgSAxgAPAoJCgIIJRIDGAA8CggKAQgSAxkAZAoJ
CgIICxIDGQBkCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsANAoJCgIICBIDGwA0CggK
AQgSAxwAPAoJCgIIARIDHAA8CggKAQgSAx0APAoJCgIIKRIDHQA8CggKAQgSAx4AOwoJCgII
LRIDHgA7CgkKAQgSBB8AIgIKDAoECJ0IABIEHwAiAgoJCgEIEgQjACYCCgwKBAidCAESBCMA
JgIKCQoBCBIEJwAqAgoMCgQInQgCEgQnACoCCvcBCgIEABIFMACJAQEa6QEgRW5kcG9pbnRQ
b2xpY3kgaXMgYSByZXNvdXJjZSB0aGF0IGhlbHBzIGFwcGx5IGRlc2lyZWQgY29uZmlndXJh
dGlvbgogb24gdGhlIGVuZHBvaW50cyB0aGF0IG1hdGNoIHNwZWNpZmljIGNyaXRlcmlhLgog
Rm9yIGV4YW1wbGUsIHRoaXMgcmVzb3VyY2UgY2FuIGJlIHVzZWQgdG8gYXBwbHkgImF1dGhl
bnRpY2F0aW9uIGNvbmZpZyIKIGFuIGFsbCBlbmRwb2ludHMgdGhhdCBzZXJ2ZSBvbiBwb3J0
IDgwODAuCgoKCgMEAAESAzAIFgoLCgMEAAcSBDECNAQKDQoFBAAHnQgSBDECNAQKLAoEBAAE
ABIENwJAAxoeIFRoZSB0eXBlIG9mIGVuZHBvaW50IHBvbGljeS4KCgwKBQQABAABEgM3BxkK
MQoGBAAEAAIAEgM5BCkaIiBEZWZhdWx0IHZhbHVlLiBNdXN0IG5vdCBiZSB1c2VkLgoKDgoH
BAAEAAIAARIDOQQkCg4KBwQABAACAAISAzknKAo6CgYEAAQAAgESAzwEFhorIFJlcHJlc2Vu
dHMgYSBwcm94eSBkZXBsb3llZCBhcyBhIHNpZGVjYXIuCgoOCgcEAAQAAgEBEgM8BBEKDgoH
BAAEAAIBAhIDPBQVCjUKBgQABAACAhIDPwQUGiYgUmVwcmVzZW50cyBhIHByb3h5bGVzcyBn
UlBDIGJhY2tlbmQuCgoOCgcEAAQAAgIBEgM/BA8KDgoHBAAEAAICAhIDPxITCpkBCgQEAAIA
EgNEAj0aiwEgSWRlbnRpZmllci4gTmFtZSBvZiB0aGUgRW5kcG9pbnRQb2xpY3kgcmVzb3Vy
Y2UuIEl0IG1hdGNoZXMgcGF0dGVybgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
Ki9lbmRwb2ludFBvbGljaWVzL3tlbmRwb2ludF9wb2xpY3l9YC4KCgwKBQQAAgAFEgNEAggK
DAoFBAACAAESA0QJDQoMCgUEAAIAAxIDRBARCgwKBQQAAgAIEgNEEjwKDwoIBAACAAicCAAS
A0QTOwpJCgQEAAIBEgRHAkgyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0
aGUgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQuCgoMCgUEAAIBBhIDRwIbCgwKBQQAAgEBEgNHHCcK
DAoFBAACAQMSA0cqKwoMCgUEAAIBCBIDSAYxCg8KCAQAAgEInAgAEgNIBzAKSQoEBAACAhIE
SwJMMho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdh
cyB1cGRhdGVkLgoKDAoFBAACAgYSA0sCGwoMCgUEAAICARIDSxwnCgwKBQQAAgIDEgNLKisK
DAoFBAACAggSA0wGMQoPCggEAAICCJwIABIDTAcwClcKBAQAAgMSA08CShpKIE9wdGlvbmFs
LiBTZXQgb2YgbGFiZWwgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIEVuZHBvaW50UG9saWN5
IHJlc291cmNlLgoKDAoFBAACAwYSA08CFQoMCgUEAAIDARIDTxYcCgwKBQQAAgMDEgNPHyAK
DAoFBAACAwgSA08hSQoPCggEAAIDCJwIABIDTyJICmwKBAQAAgQSA1MCRxpfIFJlcXVpcmVk
LiBUaGUgdHlwZSBvZiBlbmRwb2ludCBwb2xpY3kuIFRoaXMgaXMgcHJpbWFyaWx5IHVzZWQg
dG8gdmFsaWRhdGUKIHRoZSBjb25maWd1cmF0aW9uLgoKDAoFBAACBAYSA1MCFAoMCgUEAAIE
ARIDUxUZCgwKBQQAAgQDEgNTHB0KDAoFBAACBAgSA1MeRgoPCggEAAIECJwIABIDUx9FCqYC
CgQEAAIFEgRaAl8EGpcCIE9wdGlvbmFsLiBUaGlzIGZpZWxkIHNwZWNpZmllcyB0aGUgVVJM
IG9mIEF1dGhvcml6YXRpb25Qb2xpY3kgcmVzb3VyY2UgdGhhdAogYXBwbGllcyBhdXRob3Jp
emF0aW9uIHBvbGljaWVzIHRvIHRoZSBpbmJvdW5kIHRyYWZmaWMgYXQgdGhlCiBtYXRjaGVk
IGVuZHBvaW50cy4gUmVmZXIgdG8gQXV0aG9yaXphdGlvbi4gSWYgdGhpcyBmaWVsZCBpcyBu
b3QKIHNwZWNpZmllZCwgYXV0aG9yaXphdGlvbiBpcyBkaXNhYmxlZChubyBhdXRoeiBjaGVj
a3MpIGZvciB0aGlzCiBlbmRwb2ludC4KCgwKBQQAAgUFEgNaAggKDAoFBAACBQESA1oJHQoM
CgUEAAIFAxIDWiAhCg0KBQQAAgUIEgRaIl8DCg8KCAQAAgUInAgAEgNbBCoKDwoHBAACBQif
CBIEXAReBQpjCgQEAAIGEgNjAlAaViBSZXF1aXJlZC4gQSBtYXRjaGVyIHRoYXQgc2VsZWN0
cyBlbmRwb2ludHMgdG8gd2hpY2ggdGhlIHBvbGljaWVzIHNob3VsZCBiZQogYXBwbGllZC4K
CgwKBQQAAgYGEgNjAhEKDAoFBAACBgESA2MSIgoMCgUEAAIGAxIDYyUmCgwKBQQAAgYIEgNj
J08KDwoIBAACBgicCAASA2MoTgqTAQoEBAACBxIEZwJoLxqEASBPcHRpb25hbC4gUG9ydCBz
ZWxlY3RvciBmb3IgdGhlIChtYXRjaGVkKSBlbmRwb2ludHMuIElmIG5vIHBvcnQgc2VsZWN0
b3IgaXMKIHByb3ZpZGVkLCB0aGUgbWF0Y2hlZCBjb25maWcgaXMgYXBwbGllZCB0byBhbGwg
cG9ydHMuCgoMCgUEAAIHBhIDZwIVCgwKBQQAAgcBEgNnFisKDAoFBAACBwMSA2cuMAoMCgUE
AAIHCBIDaAYuCg8KCAQAAgcInAgAEgNoBy0KXgoEBAACCBIDbAJDGlEgT3B0aW9uYWwuIEEg
ZnJlZS10ZXh0IGRlc2NyaXB0aW9uIG9mIHRoZSByZXNvdXJjZS4gTWF4IGxlbmd0aCAxMDI0
CiBjaGFyYWN0ZXJzLgoKDAoFBAACCAUSA2wCCAoMCgUEAAIIARIDbAkUCgwKBQQAAggDEgNs
FxkKDAoFBAACCAgSA2waQgoPCggEAAIICJwIABIDbBtBCqICCgQEAAIJEgRyAncEGpMCIE9w
dGlvbmFsLiBBIFVSTCByZWZlcnJpbmcgdG8gU2VydmVyVGxzUG9saWN5IHJlc291cmNlLiBT
ZXJ2ZXJUbHNQb2xpY3kgaXMKIHVzZWQgdG8gZGV0ZXJtaW5lIHRoZSBhdXRoZW50aWNhdGlv
biBwb2xpY3kgdG8gYmUgYXBwbGllZCB0byB0ZXJtaW5hdGUgdGhlCiBpbmJvdW5kIHRyYWZm
aWMgYXQgdGhlIGlkZW50aWZpZWQgYmFja2VuZHMuIElmIHRoaXMgZmllbGQgaXMgbm90IHNl
dCwKIGF1dGhlbnRpY2F0aW9uIGlzIGRpc2FibGVkKG9wZW4pIGZvciB0aGlzIGVuZHBvaW50
LgoKDAoFBAACCQUSA3ICCAoMCgUEAAIJARIDcgkaCgwKBQQAAgkDEgNyHR8KDQoFBAACCQgS
BHIgdwMKDwoIBAACCQicCAASA3MEKgoPCgcEAAIJCJ8IEgR0BHYFCvoECgQEAAIKEgaCAQKI
AQQa6QQgT3B0aW9uYWwuIERlcHJlY2F0ZWQ6IFRoaXMgZmllbGQgaXMgbm90IHVzZWQgYW5k
IGlzIGEgbm8tb3AuCiBBIFVSTCByZWZlcnJpbmcgdG8gYSBDbGllbnRUbHNQb2xpY3kgcmVz
b3VyY2UuIENsaWVudFRsc1BvbGljeSBjYW4gYmUgc2V0CiB0byBzcGVjaWZ5IHRoZSBhdXRo
ZW50aWNhdGlvbiBmb3IgdHJhZmZpYyBmcm9tIHRoZSBwcm94eSB0byB0aGUgYWN0dWFsCiBl
bmRwb2ludHMuIE1vcmUgc3BlY2lmaWNhbGx5LCBpdCBpcyBhcHBsaWVkIHRvIHRoZSBvdXRn
b2luZyB0cmFmZmljIGZyb20KIHRoZSBwcm94eSB0byB0aGUgZW5kcG9pbnQuIFRoaXMgaXMg
dHlwaWNhbGx5IHVzZWQgZm9yIHNpZGVjYXIgbW9kZWwgd2hlcmUKIHRoZSBwcm94eSBpZGVu
dGlmaWVzIGl0c2VsZiBhcyBlbmRwb2ludCB0byB0aGUgY29udHJvbCBwbGFuZSwgd2l0aCB0
aGUKIGNvbm5lY3Rpb24gYmV0d2VlbiBzaWRlY2FyIGFuZCBlbmRwb2ludCByZXF1aXJpbmcg
YXV0aGVudGljYXRpb24uIElmIHRoaXMKIGZpZWxkIGlzIG5vdCBzZXQsIGF1dGhlbnRpY2F0
aW9uIGlzIGRpc2FibGVkKG9wZW4pLiBBcHBsaWNhYmxlIG9ubHkgd2hlbgogRW5kcG9pbnRQ
b2xpY3lUeXBlIGlzIFNJREVDQVJfUFJPWFkuCgoNCgUEAAIKBRIEggECCAoNCgUEAAIKARIE
ggEJGgoNCgUEAAIKAxIEggEdHwoPCgUEAAIKCBIGggEgiAEDCg4KBgQAAgoIAxIEgwEEFQoQ
CggEAAIKCJwIABIEhAEEKgoRCgcEAAIKCJ8IEgaFAQSHAQUKQgoCBAESBowBAKMBARo0IFJl
cXVlc3QgdXNlZCB3aXRoIHRoZSBMaXN0RW5kcG9pbnRQb2xpY2llcyBtZXRob2QuCgoLCgME
AQESBIwBCCMKmgEKBAQBAgASBo8BApQBBBqJASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5k
IGxvY2F0aW9uIGZyb20gd2hpY2ggdGhlIEVuZHBvaW50UG9saWNpZXMgc2hvdWxkCiBiZSBs
aXN0ZWQsIHNwZWNpZmllZCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8q
YC4KCg0KBQQBAgAFEgSPAQIICg0KBQQBAgABEgSPAQkPCg0KBQQBAgADEgSPARITCg8KBQQB
AgAIEgaPARSUAQMKEAoIBAECAAicCAASBJABBCoKEQoHBAECAAifCBIGkQEEkwEFCkYKBAQB
AgESBJcBAhYaOCBNYXhpbXVtIG51bWJlciBvZiBFbmRwb2ludFBvbGljaWVzIHRvIHJldHVy
biBwZXIgY2FsbC4KCg0KBQQBAgEFEgSXAQIHCg0KBQQBAgEBEgSXAQgRCg0KBQQBAgEDEgSX
ARQVCtgBCgQEAQICEgSdAQIYGskBIFRoZSB2YWx1ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBg
TGlzdEVuZHBvaW50UG9saWNpZXNSZXNwb25zZWAKIEluZGljYXRlcyB0aGF0IHRoaXMgaXMg
YSBjb250aW51YXRpb24gb2YgYSBwcmlvcgogYExpc3RFbmRwb2ludFBvbGljaWVzYCBjYWxs
LCBhbmQgdGhhdCB0aGUgc3lzdGVtIHNob3VsZCByZXR1cm4gdGhlCiBuZXh0IHBhZ2Ugb2Yg
ZGF0YS4KCg0KBQQBAgIFEgSdAQIICg0KBQQBAgIBEgSdAQkTCg0KBQQBAgIDEgSdARYXCssB
CgQEAQIDEgSiAQJLGrwBIE9wdGlvbmFsLiBJZiB0cnVlLCBhbGxvdyBwYXJ0aWFsIHJlc3Bv
bnNlcyBmb3IgbXVsdGktcmVnaW9uYWwgQWdncmVnYXRlZAogTGlzdCByZXF1ZXN0cy4gT3Ro
ZXJ3aXNlIGlmIG9uZSBvZiB0aGUgbG9jYXRpb25zIGlzIGRvd24gb3IgdW5yZWFjaGFibGUs
CiB0aGUgQWdncmVnYXRlZCBMaXN0IHJlcXVlc3Qgd2lsbCBmYWlsLgoKDQoFBAECAwUSBKIB
AgYKDQoFBAECAwESBKIBBx0KDQoFBAECAwMSBKIBICEKDQoFBAECAwgSBKIBIkoKEAoIBAEC
AwicCAASBKIBI0kKRQoCBAISBqYBALQBARo3IFJlc3BvbnNlIHJldHVybmVkIGJ5IHRoZSBM
aXN0RW5kcG9pbnRQb2xpY2llcyBtZXRob2QuCgoLCgMEAgESBKYBCCQKMQoEBAICABIEqAEC
MBojIExpc3Qgb2YgRW5kcG9pbnRQb2xpY3kgcmVzb3VyY2VzLgoKDQoFBAICAAQSBKgBAgoK
DQoFBAICAAYSBKgBCxkKDQoFBAICAAESBKgBGisKDQoFBAICAAMSBKgBLi8K6QEKBAQCAgES
BK0BAh0a2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBw
ZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGlu
Y2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0
aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFn
ZV90b2tlbmAuCgoNCgUEAgIBBRIErQECCAoNCgUEAgIBARIErQEJGAoNCgUEAgIBAxIErQEb
HAqmAgoEBAICAhIEswECIhqXAiBVbnJlYWNoYWJsZSByZXNvdXJjZXMuIFBvcHVsYXRlZCB3
aGVuIHRoZSByZXF1ZXN0IG9wdHMgaW50bwogW3JldHVybl9wYXJ0aWFsX3N1Y2Nlc3NdW2dv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuTGlzdEVuZHBvaW50UG9saWNpZXNSZXF1
ZXN0LnJldHVybl9wYXJ0aWFsX3N1Y2Nlc3NdCiBhbmQgcmVhZGluZyBhY3Jvc3MgY29sbGVj
dGlvbnMgZS5nLiB3aGVuCiBhdHRlbXB0aW5nIHRvIGxpc3QgYWxsIHJlc291cmNlcyBhY3Jv
c3MgYWxsIHN1cHBvcnRlZCBsb2NhdGlvbnMuCgoNCgUEAgICBBIEswECCgoNCgUEAgICBRIE
swELEQoNCgUEAgICARIEswESHQoNCgUEAgICAxIEswEgIQo/CgIEAxIGtwEAwAEBGjEgUmVx
dWVzdCB1c2VkIHdpdGggdGhlIEdldEVuZHBvaW50UG9saWN5IG1ldGhvZC4KCgsKAwQDARIE
twEIIAqEAQoEBAMCABIGugECvwEEGnQgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgRW5kcG9p
bnRQb2xpY3kgdG8gZ2V0LiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2VuZHBvaW50UG9saWNpZXMvKmAuCgoNCgUEAwIABRIEugECCAoNCgUEAwIA
ARIEugEJDQoNCgUEAwIAAxIEugEQEQoPCgUEAwIACBIGugESvwEDChAKCAQDAgAInAgAEgS7
AQQqChEKBwQDAgAInwgSBrwBBL4BBQpCCgIEBBIGwwEA0wEBGjQgUmVxdWVzdCB1c2VkIHdp
dGggdGhlIENyZWF0ZUVuZHBvaW50UG9saWN5IG1ldGhvZC4KCgsKAwQEARIEwwEIIwp3CgQE
BAIAEgbGAQLLAQQaZyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBvZiB0aGUgRW5k
cG9pbnRQb2xpY3kuIE11c3QgYmUgaW4gdGhlCiBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRp
b25zLypgLgoKDQoFBAQCAAUSBMYBAggKDQoFBAQCAAESBMYBCQ8KDQoFBAQCAAMSBMYBEhMK
DwoFBAQCAAgSBsYBFMsBAwoQCggEBAIACJwIABIExwEEKgoRCgcEBAIACJ8IEgbIAQTKAQUK
ZQoEBAQCARIEzwECSRpXIFJlcXVpcmVkLiBTaG9ydCBuYW1lIG9mIHRoZSBFbmRwb2ludFBv
bGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLgogRS5nLiAiQ3VzdG9tRUNTIi4KCg0KBQQE
AgEFEgTPAQIICg0KBQQEAgEBEgTPAQkbCg0KBQQEAgEDEgTPAR4fCg0KBQQEAgEIEgTPASBI
ChAKCAQEAgEInAgAEgTPASFHCkAKBAQEAgISBNIBAk4aMiBSZXF1aXJlZC4gRW5kcG9pbnRQ
b2xpY3kgcmVzb3VyY2UgdG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgTSAQIQCg0KBQQEAgIB
EgTSAREgCg0KBQQEAgIDEgTSASMkCg0KBQQEAgIIEgTSASVNChAKCAQEAgIInAgAEgTSASZM
CkIKAgQFEgbWAQDhAQEaNCBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgVXBkYXRlRW5kcG9pbnRQ
b2xpY3kgbWV0aG9kLgoKCwoDBAUBEgTWAQgjCuACCgQEBQIAEgbcAQLdAS8azwIgT3B0aW9u
YWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3Zl
cndyaXR0ZW4gaW4gdGhlCiBFbmRwb2ludFBvbGljeSByZXNvdXJjZSBieSB0aGUgdXBkYXRl
LgogVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2
ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxs
IGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9l
cyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0
ZW4uCgoNCgUEBQIABhIE3AECGwoNCgUEBQIAARIE3AEcJwoNCgUEBQIAAxIE3AEqKwoNCgUE
BQIACBIE3QEGLgoQCggEBQIACJwIABIE3QEHLQo6CgQEBQIBEgTgAQJOGiwgUmVxdWlyZWQu
IFVwZGF0ZWQgRW5kcG9pbnRQb2xpY3kgcmVzb3VyY2UuCgoNCgUEBQIBBhIE4AECEAoNCgUE
BQIBARIE4AERIAoNCgUEBQIBAxIE4AEjJAoNCgUEBQIBCBIE4AElTQoQCggEBQIBCJwIABIE
4AEmTApCCgIEBhIG5AEA7QEBGjQgUmVxdWVzdCB1c2VkIHdpdGggdGhlIERlbGV0ZUVuZHBv
aW50UG9saWN5IG1ldGhvZC4KCgsKAwQGARIE5AEIIwqHAQoEBAYCABIG5wEC7AEEGncgUmVx
dWlyZWQuIEEgbmFtZSBvZiB0aGUgRW5kcG9pbnRQb2xpY3kgdG8gZGVsZXRlLiBNdXN0IGJl
IGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2VuZHBvaW50UG9saWNp
ZXMvKmAuCgoNCgUEBgIABRIE5wECCAoNCgUEBgIAARIE5wEJDQoNCgUEBgIAAxIE5wEQEQoP
CgUEBgIACBIG5wES7AEDChAKCAQGAgAInAgAEgToAQQqChEKBwQGAgAInwgSBukBBOsBBWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy ===
    # Fields for EndpointPolicy
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy.LabelsEntry)
    # Field: type Type: 14 (.google.cloud.networkservices.v1.EndpointPolicy.EndpointPolicyType)
    # Field: authorization_policy Type: 9 ()
    # Field: endpoint_matcher Type: 11 (.google.cloud.networkservices.v1.EndpointMatcher)
    # Field: traffic_port_selector Type: 11 (.google.cloud.networkservices.v1.TrafficPortSelector)
    # Field: description Type: 9 ()
    # Field: server_tls_policy Type: 9 ()
    # Field: client_tls_policy Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<labels>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy.LabelsEntry)

=item * B<type>

Type: Enum (.google.cloud.networkservices.v1.EndpointPolicy.EndpointPolicyType)

=item * B<authorization_policy>

Type: String

=item * B<endpoint_matcher>

Type: Message (.google.cloud.networkservices.v1.EndpointMatcher)

=item * B<traffic_port_selector>

Type: Message (.google.cloud.networkservices.v1.TrafficPortSelector)

=item * B<description>

Type: String

=item * B<server_tls_policy>

Type: String

=item * B<client_tls_policy>

Type: String

=back

=cut

# Enum: EndpointPolicy::EndpointPolicyType
our $EndpointPolicy_ENDPOINT_POLICY_TYPE_UNSPECIFIED = 0;
our $EndpointPolicy_SIDECAR_PROXY = 1;
our $EndpointPolicy_GRPC_SERVER = 2;

=pod

=head2 Enum: EndpointPolicy::EndpointPolicyType

Values:

=over 4

=item * C<ENDPOINT_POLICY_TYPE_UNSPECIFIED> => 0

=item * C<SIDECAR_PROXY> => 1

=item * C<GRPC_SERVER> => 2

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest ===
    # Fields for ListEndpointPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: return_partial_success Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest->new(
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

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse ===
    # Fields for ListEndpointPoliciesResponse
    # Field: endpoint_policies Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse->new(
        endpoint_policies => $value,
    );

=head1 FIELDS

=over 4

=item * B<endpoint_policies>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest ===
    # Fields for GetEndpointPolicyRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest ===
    # Fields for CreateEndpointPolicyRequest
    # Field: parent Type: 9 ()
    # Field: endpoint_policy_id Type: 9 ()
    # Field: endpoint_policy Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<endpoint_policy_id>

Type: String

=item * B<endpoint_policy>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest ===
    # Fields for UpdateEndpointPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: endpoint_policy Type: 11 (.google.cloud.networkservices.v1.EndpointPolicy)

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<endpoint_policy>

Type: Message (.google.cloud.networkservices.v1.EndpointPolicy)

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest ===
    # Fields for DeleteEndpointPolicyRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest->new(
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

Google::Cloud::Networkservices::V1::EndpointPolicy - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
