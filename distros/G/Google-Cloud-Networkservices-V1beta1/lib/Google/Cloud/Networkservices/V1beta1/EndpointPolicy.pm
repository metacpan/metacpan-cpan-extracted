package Google::Cloud::Networkservices::V1beta1::EndpointPolicy;

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
    eval { require Google::Cloud::Networkservices::V1beta1::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxYmV0YTEvZW5kcG9pbnRfcG9saWN5
LnByb3RvEiRnb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMWdv
b2dsZS9jbG91ZC9uZXR3b3Jrc2VydmljZXMvdjFiZXRhMS9jb21tb24ucHJvdG8aIGdvb2ds
ZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIsQJCg5FbmRwb2ludFBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSQAoL
Y3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCnVwZGF0ZVRpbWUSXQoGbGFiZWxzGAQgAygLMkAuZ29vZ2xlLmNsb3VkLm5l
dHdvcmtzZXJ2aWNlcy52MWJldGExLkVuZHBvaW50UG9saWN5LkxhYmVsc0VudHJ5QgPgQQFS
BmxhYmVscxJgCgR0eXBlGAUgASgOMkcuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52
MWJldGExLkVuZHBvaW50UG9saWN5LkVuZHBvaW50UG9saWN5VHlwZUID4EECUgR0eXBlEm0K
FGF1dGhvcml6YXRpb25fcG9saWN5GAcgASgJQjrgQQH6QTQKMm5ldHdvcmtzZWN1cml0eS5n
b29nbGVhcGlzLmNvbS9BdXRob3JpemF0aW9uUG9saWN5UhNhdXRob3JpemF0aW9uUG9saWN5
EmUKEGVuZHBvaW50X21hdGNoZXIYCSABKAsyNS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxYmV0YTEuRW5kcG9pbnRNYXRjaGVyQgPgQQJSD2VuZHBvaW50TWF0Y2hlchJyChV0
cmFmZmljX3BvcnRfc2VsZWN0b3IYCiABKAsyOS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxYmV0YTEuVHJhZmZpY1BvcnRTZWxlY3RvckID4EEBUhN0cmFmZmljUG9ydFNlbGVj
dG9yEiUKC2Rlc2NyaXB0aW9uGAsgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEmIKEXNlcnZlcl90
bHNfcG9saWN5GAwgASgJQjbgQQH6QTAKLm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNv
bS9TZXJ2ZXJUbHNQb2xpY3lSD3NlcnZlclRsc1BvbGljeRJkChFjbGllbnRfdGxzX3BvbGlj
eRgNIAEoCUI4GAHgQQH6QTAKLm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9DbGll
bnRUbHNQb2xpY3lSD2NsaWVudFRsc1BvbGljeRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIl4KEkVuZHBvaW50UG9saWN5VHlw
ZRIkCiBFTkRQT0lOVF9QT0xJQ1lfVFlQRV9VTlNQRUNJRklFRBAAEhEKDVNJREVDQVJfUFJP
WFkQARIPCgtHUlBDX1NFUlZFUhACOn7qQXsKLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlz
LmNvbS9FbmRwb2ludFBvbGljeRJKcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2VuZHBvaW50UG9saWNpZXMve2VuZHBvaW50X3BvbGljeX0iqAEKG0xpc3RFbmRw
b2ludFBvbGljaWVzUmVxdWVzdBJNCgZwYXJlbnQYASABKAlCNeBBAvpBLxItbmV0d29ya3Nl
cnZpY2VzLmdvb2dsZWFwaXMuY29tL0VuZHBvaW50UG9saWN5UgZwYXJlbnQSGwoJcGFnZV9z
aXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4iqQEK
HExpc3RFbmRwb2ludFBvbGljaWVzUmVzcG9uc2USYQoRZW5kcG9pbnRfcG9saWNpZXMYASAD
KAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuRW5kcG9pbnRQb2xp
Y3lSEGVuZHBvaW50UG9saWNpZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuImUKGEdldEVuZHBvaW50UG9saWN5UmVxdWVzdBJJCgRuYW1lGAEgASgJQjXgQQL6
QS8KLW5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9FbmRwb2ludFBvbGljeVIEbmFt
ZSKDAgobQ3JlYXRlRW5kcG9pbnRQb2xpY3lSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC
+kEvEi1uZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnRQb2xpY3lSBnBh
cmVudBIxChJlbmRwb2ludF9wb2xpY3lfaWQYAiABKAlCA+BBAlIQZW5kcG9pbnRQb2xpY3lJ
ZBJiCg9lbmRwb2ludF9wb2xpY3kYAyABKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxYmV0YTEuRW5kcG9pbnRQb2xpY3lCA+BBAlIOZW5kcG9pbnRQb2xpY3kiwwEKG1Vw
ZGF0ZUVuZHBvaW50UG9saWN5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJiCg9lbmRwb2ludF9wb2xp
Y3kYAiABKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuRW5kcG9p
bnRQb2xpY3lCA+BBAlIOZW5kcG9pbnRQb2xpY3kiaAobRGVsZXRlRW5kcG9pbnRQb2xpY3lS
ZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBBAvpBLwotbmV0d29ya3NlcnZpY2VzLmdvb2dsZWFw
aXMuY29tL0VuZHBvaW50UG9saWN5UgRuYW1lQp8FCihjb20uZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZXJ2aWNlcy52MWJldGExQhNFbmRwb2ludFBvbGljeVByb3RvUAFaUmNsb3VkLmdvb2ds
ZS5jb20vZ28vbmV0d29ya3NlcnZpY2VzL2FwaXYxYmV0YTEvbmV0d29ya3NlcnZpY2VzcGI7
bmV0d29ya3NlcnZpY2VzcGKqAiRHb29nbGUuQ2xvdWQuTmV0d29ya1NlcnZpY2VzLlYxQmV0
YTHKAiRHb29nbGVcQ2xvdWRcTmV0d29ya1NlcnZpY2VzXFYxYmV0YTHqAidHb29nbGU6OkNs
b3VkOjpOZXR3b3JrU2VydmljZXM6OlYxYmV0YTHqQYoBCjJuZXR3b3Jrc2VjdXJpdHkuZ29v
Z2xlYXBpcy5jb20vQXV0aG9yaXphdGlvblBvbGljeRJUcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2F1dGhvcml6YXRpb25Qb2xpY2llcy97YXV0aG9yaXphdGlv
bl9wb2xpY3l96kF/Ci5uZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmVyVGxz
UG9saWN5Ek1wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmVy
VGxzUG9saWNpZXMve3NlcnZlcl90bHNfcG9saWN5fepBfwoubmV0d29ya3NlY3VyaXR5Lmdv
b2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGljeRJNcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NsaWVudFRsc1BvbGljaWVzL3tjbGllbnRfdGxzX3BvbGljeX1K
kDsKBxIFDgDiAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
AC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADsKCQoCAwMSAxUAKgoJCgIDBBID
FgApCggKAQgSAxgAQQoJCgIIJRIDGABBCggKAQgSAxkAaQoJCgIICxIDGQBpCggKAQgSAxoA
IgoJCgIIChIDGgAiCggKAQgSAxsANAoJCgIICBIDGwA0CggKAQgSAxwAQQoJCgIIARIDHABB
CggKAQgSAx0AQQoJCgIIKRIDHQBBCggKAQgSAx4AQAoJCgIILRIDHgBACgkKAQgSBB8AIgIK
DAoECJ0IABIEHwAiAgoJCgEIEgQjACYCCgwKBAidCAESBCMAJgIKCQoBCBIEJwAqAgoMCgQI
nQgCEgQnACoCCvcBCgIEABIFMACJAQEa6QEgRW5kcG9pbnRQb2xpY3kgaXMgYSByZXNvdXJj
ZSB0aGF0IGhlbHBzIGFwcGx5IGRlc2lyZWQgY29uZmlndXJhdGlvbgogb24gdGhlIGVuZHBv
aW50cyB0aGF0IG1hdGNoIHNwZWNpZmljIGNyaXRlcmlhLgogRm9yIGV4YW1wbGUsIHRoaXMg
cmVzb3VyY2UgY2FuIGJlIHVzZWQgdG8gYXBwbHkgImF1dGhlbnRpY2F0aW9uIGNvbmZpZyIK
IGFuIGFsbCBlbmRwb2ludHMgdGhhdCBzZXJ2ZSBvbiBwb3J0IDgwODAuCgoKCgMEAAESAzAI
FgoLCgMEAAcSBDECNAQKDQoFBAAHnQgSBDECNAQKLAoEBAAEABIENwJAAxoeIFRoZSB0eXBl
IG9mIGVuZHBvaW50IHBvbGljeS4KCgwKBQQABAABEgM3BxkKMQoGBAAEAAIAEgM5BCkaIiBE
ZWZhdWx0IHZhbHVlLiBNdXN0IG5vdCBiZSB1c2VkLgoKDgoHBAAEAAIAARIDOQQkCg4KBwQA
BAACAAISAzknKAo6CgYEAAQAAgESAzwEFhorIFJlcHJlc2VudHMgYSBwcm94eSBkZXBsb3ll
ZCBhcyBhIHNpZGVjYXIuCgoOCgcEAAQAAgEBEgM8BBEKDgoHBAAEAAIBAhIDPBQVCjUKBgQA
BAACAhIDPwQUGiYgUmVwcmVzZW50cyBhIHByb3h5bGVzcyBnUlBDIGJhY2tlbmQuCgoOCgcE
AAQAAgIBEgM/BA8KDgoHBAAEAAICAhIDPxITCpwBCgQEAAIAEgNEAjsajgEgUmVxdWlyZWQu
IE5hbWUgb2YgdGhlIEVuZHBvaW50UG9saWN5IHJlc291cmNlLiBJdCBtYXRjaGVzIHBhdHRl
cm4KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL2dsb2JhbC9lbmRwb2ludFBvbGlj
aWVzL3tlbmRwb2ludF9wb2xpY3l9YC4KCgwKBQQAAgAFEgNEAggKDAoFBAACAAESA0QJDQoM
CgUEAAIAAxIDRBARCgwKBQQAAgAIEgNEEjoKDwoIBAACAAicCAASA0QTOQpJCgQEAAIBEgRH
AkgyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgcmVzb3VyY2Ugd2Fz
IGNyZWF0ZWQuCgoMCgUEAAIBBhIDRwIbCgwKBQQAAgEBEgNHHCcKDAoFBAACAQMSA0cqKwoM
CgUEAAIBCBIDSAYxCg8KCAQAAgEInAgAEgNIBzAKSQoEBAACAhIESwJMMho7IE91dHB1dCBv
bmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdhcyB1cGRhdGVkLgoKDAoF
BAACAgYSA0sCGwoMCgUEAAICARIDSxwnCgwKBQQAAgIDEgNLKisKDAoFBAACAggSA0wGMQoP
CggEAAICCJwIABIDTAcwClcKBAQAAgMSA08CShpKIE9wdGlvbmFsLiBTZXQgb2YgbGFiZWwg
dGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIEVuZHBvaW50UG9saWN5IHJlc291cmNlLgoKDAoF
BAACAwYSA08CFQoMCgUEAAIDARIDTxYcCgwKBQQAAgMDEgNPHyAKDAoFBAACAwgSA08hSQoP
CggEAAIDCJwIABIDTyJICmwKBAQAAgQSA1MCRxpfIFJlcXVpcmVkLiBUaGUgdHlwZSBvZiBl
bmRwb2ludCBwb2xpY3kuIFRoaXMgaXMgcHJpbWFyaWx5IHVzZWQgdG8gdmFsaWRhdGUKIHRo
ZSBjb25maWd1cmF0aW9uLgoKDAoFBAACBAYSA1MCFAoMCgUEAAIEARIDUxUZCgwKBQQAAgQD
EgNTHB0KDAoFBAACBAgSA1MeRgoPCggEAAIECJwIABIDUx9FCqYCCgQEAAIFEgRaAl8EGpcC
IE9wdGlvbmFsLiBUaGlzIGZpZWxkIHNwZWNpZmllcyB0aGUgVVJMIG9mIEF1dGhvcml6YXRp
b25Qb2xpY3kgcmVzb3VyY2UgdGhhdAogYXBwbGllcyBhdXRob3JpemF0aW9uIHBvbGljaWVz
IHRvIHRoZSBpbmJvdW5kIHRyYWZmaWMgYXQgdGhlCiBtYXRjaGVkIGVuZHBvaW50cy4gUmVm
ZXIgdG8gQXV0aG9yaXphdGlvbi4gSWYgdGhpcyBmaWVsZCBpcyBub3QKIHNwZWNpZmllZCwg
YXV0aG9yaXphdGlvbiBpcyBkaXNhYmxlZChubyBhdXRoeiBjaGVja3MpIGZvciB0aGlzCiBl
bmRwb2ludC4KCgwKBQQAAgUFEgNaAggKDAoFBAACBQESA1oJHQoMCgUEAAIFAxIDWiAhCg0K
BQQAAgUIEgRaIl8DCg8KCAQAAgUInAgAEgNbBCoKDwoHBAACBQifCBIEXAReBQpjCgQEAAIG
EgNjAlAaViBSZXF1aXJlZC4gQSBtYXRjaGVyIHRoYXQgc2VsZWN0cyBlbmRwb2ludHMgdG8g
d2hpY2ggdGhlIHBvbGljaWVzIHNob3VsZCBiZQogYXBwbGllZC4KCgwKBQQAAgYGEgNjAhEK
DAoFBAACBgESA2MSIgoMCgUEAAIGAxIDYyUmCgwKBQQAAgYIEgNjJ08KDwoIBAACBgicCAAS
A2MoTgqTAQoEBAACBxIEZwJoLxqEASBPcHRpb25hbC4gUG9ydCBzZWxlY3RvciBmb3IgdGhl
IChtYXRjaGVkKSBlbmRwb2ludHMuIElmIG5vIHBvcnQgc2VsZWN0b3IgaXMKIHByb3ZpZGVk
LCB0aGUgbWF0Y2hlZCBjb25maWcgaXMgYXBwbGllZCB0byBhbGwgcG9ydHMuCgoMCgUEAAIH
BhIDZwIVCgwKBQQAAgcBEgNnFisKDAoFBAACBwMSA2cuMAoMCgUEAAIHCBIDaAYuCg8KCAQA
AgcInAgAEgNoBy0KXgoEBAACCBIDbAJDGlEgT3B0aW9uYWwuIEEgZnJlZS10ZXh0IGRlc2Ny
aXB0aW9uIG9mIHRoZSByZXNvdXJjZS4gTWF4IGxlbmd0aCAxMDI0CiBjaGFyYWN0ZXJzLgoK
DAoFBAACCAUSA2wCCAoMCgUEAAIIARIDbAkUCgwKBQQAAggDEgNsFxkKDAoFBAACCAgSA2wa
QgoPCggEAAIICJwIABIDbBtBCqICCgQEAAIJEgRyAncEGpMCIE9wdGlvbmFsLiBBIFVSTCBy
ZWZlcnJpbmcgdG8gU2VydmVyVGxzUG9saWN5IHJlc291cmNlLiBTZXJ2ZXJUbHNQb2xpY3kg
aXMKIHVzZWQgdG8gZGV0ZXJtaW5lIHRoZSBhdXRoZW50aWNhdGlvbiBwb2xpY3kgdG8gYmUg
YXBwbGllZCB0byB0ZXJtaW5hdGUgdGhlCiBpbmJvdW5kIHRyYWZmaWMgYXQgdGhlIGlkZW50
aWZpZWQgYmFja2VuZHMuIElmIHRoaXMgZmllbGQgaXMgbm90IHNldCwKIGF1dGhlbnRpY2F0
aW9uIGlzIGRpc2FibGVkKG9wZW4pIGZvciB0aGlzIGVuZHBvaW50LgoKDAoFBAACCQUSA3IC
CAoMCgUEAAIJARIDcgkaCgwKBQQAAgkDEgNyHR8KDQoFBAACCQgSBHIgdwMKDwoIBAACCQic
CAASA3MEKgoPCgcEAAIJCJ8IEgR0BHYFCvoECgQEAAIKEgaCAQKIAQQa6QQgT3B0aW9uYWwu
IERlcHJlY2F0ZWQ6IFRoaXMgZmllbGQgaXMgbm90IHVzZWQgYW5kIGlzIGEgbm8tb3AuCiBB
IFVSTCByZWZlcnJpbmcgdG8gYSBDbGllbnRUbHNQb2xpY3kgcmVzb3VyY2UuIENsaWVudFRs
c1BvbGljeSBjYW4gYmUgc2V0CiB0byBzcGVjaWZ5IHRoZSBhdXRoZW50aWNhdGlvbiBmb3Ig
dHJhZmZpYyBmcm9tIHRoZSBwcm94eSB0byB0aGUgYWN0dWFsCiBlbmRwb2ludHMuIE1vcmUg
c3BlY2lmaWNhbGx5LCBpdCBpcyBhcHBsaWVkIHRvIHRoZSBvdXRnb2luZyB0cmFmZmljIGZy
b20KIHRoZSBwcm94eSB0byB0aGUgZW5kcG9pbnQuIFRoaXMgaXMgdHlwaWNhbGx5IHVzZWQg
Zm9yIHNpZGVjYXIgbW9kZWwgd2hlcmUKIHRoZSBwcm94eSBpZGVudGlmaWVzIGl0c2VsZiBh
cyBlbmRwb2ludCB0byB0aGUgY29udHJvbCBwbGFuZSwgd2l0aCB0aGUKIGNvbm5lY3Rpb24g
YmV0d2VlbiBzaWRlY2FyIGFuZCBlbmRwb2ludCByZXF1aXJpbmcgYXV0aGVudGljYXRpb24u
IElmIHRoaXMKIGZpZWxkIGlzIG5vdCBzZXQsIGF1dGhlbnRpY2F0aW9uIGlzIGRpc2FibGVk
KG9wZW4pLiBBcHBsaWNhYmxlIG9ubHkgd2hlbgogRW5kcG9pbnRQb2xpY3lUeXBlIGlzIFNJ
REVDQVJfUFJPWFkuCgoNCgUEAAIKBRIEggECCAoNCgUEAAIKARIEggEJGgoNCgUEAAIKAxIE
ggEdHwoPCgUEAAIKCBIGggEgiAEDCg4KBgQAAgoIAxIEgwEEFQoQCggEAAIKCJwIABIEhAEE
KgoRCgcEAAIKCJ8IEgaFAQSHAQUKQgoCBAESBowBAJ4BARo0IFJlcXVlc3QgdXNlZCB3aXRo
IHRoZSBMaXN0RW5kcG9pbnRQb2xpY2llcyBtZXRob2QuCgoLCgMEAQESBIwBCCMKnwEKBAQB
AgASBo8BApQBBBqOASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZyb20g
d2hpY2ggdGhlIEVuZHBvaW50UG9saWNpZXMgc2hvdWxkCiBiZSBsaXN0ZWQsIHNwZWNpZmll
ZCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWxgLgoKDQoFBAEC
AAUSBI8BAggKDQoFBAECAAESBI8BCQ8KDQoFBAECAAMSBI8BEhMKDwoFBAECAAgSBo8BFJQB
AwoQCggEAQIACJwIABIEkAEEKgoRCgcEAQIACJ8IEgaRAQSTAQUKRgoEBAECARIElwECFho4
IE1heGltdW0gbnVtYmVyIG9mIEVuZHBvaW50UG9saWNpZXMgdG8gcmV0dXJuIHBlciBjYWxs
LgoKDQoFBAECAQUSBJcBAgcKDQoFBAECAQESBJcBCBEKDQoFBAECAQMSBJcBFBUK2AEKBAQB
AgISBJ0BAhgayQEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0IGBMaXN0RW5kcG9p
bnRQb2xpY2llc1Jlc3BvbnNlYAogSW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBhIGNvbnRpbnVh
dGlvbiBvZiBhIHByaW9yCiBgTGlzdEVuZHBvaW50UG9saWNpZXNgIGNhbGwsIGFuZCB0aGF0
IHRoZSBzeXN0ZW0gc2hvdWxkIHJldHVybiB0aGUKIG5leHQgcGFnZSBvZiBkYXRhLgoKDQoF
BAECAgUSBJ0BAggKDQoFBAECAgESBJ0BCRMKDQoFBAECAgMSBJ0BFhcKRQoCBAISBqEBAKkB
ARo3IFJlc3BvbnNlIHJldHVybmVkIGJ5IHRoZSBMaXN0RW5kcG9pbnRQb2xpY2llcyBtZXRo
b2QuCgoLCgMEAgESBKEBCCQKMQoEBAICABIEowECMBojIExpc3Qgb2YgRW5kcG9pbnRQb2xp
Y3kgcmVzb3VyY2VzLgoKDQoFBAICAAQSBKMBAgoKDQoFBAICAAYSBKMBCxkKDQoFBAICAAES
BKMBGisKDQoFBAICAAMSBKMBLi8K6QEKBAQCAgESBKgBAh0a2gEgSWYgdGhlcmUgbWlnaHQg
YmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2Us
IHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQg
c2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1
ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFnZV90b2tlbmAuCgoNCgUEAgIBBRIEqAEC
CAoNCgUEAgIBARIEqAEJGAoNCgUEAgIBAxIEqAEbHAo/CgIEAxIGrAEAtQEBGjEgUmVxdWVz
dCB1c2VkIHdpdGggdGhlIEdldEVuZHBvaW50UG9saWN5IG1ldGhvZC4KCgsKAwQDARIErAEI
IAqJAQoEBAMCABIGrwECtAEEGnkgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgRW5kcG9pbnRQ
b2xpY3kgdG8gZ2V0LiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0
aW9ucy9nbG9iYWwvZW5kcG9pbnRQb2xpY2llcy8qYC4KCg0KBQQDAgAFEgSvAQIICg0KBQQD
AgABEgSvAQkNCg0KBQQDAgADEgSvARARCg8KBQQDAgAIEgavARK0AQMKEAoIBAMCAAicCAAS
BLABBCoKEQoHBAMCAAifCBIGsQEEswEFCkIKAgQEEga4AQDIAQEaNCBSZXF1ZXN0IHVzZWQg
d2l0aCB0aGUgQ3JlYXRlRW5kcG9pbnRQb2xpY3kgbWV0aG9kLgoKCwoDBAQBEgS4AQgjCnwK
BAQEAgASBrsBAsABBBpsIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBF
bmRwb2ludFBvbGljeS4gTXVzdCBiZSBpbiB0aGUKIGZvcm1hdCBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvZ2xvYmFsYC4KCg0KBQQEAgAFEgS7AQIICg0KBQQEAgABEgS7AQkPCg0KBQQEAgAD
EgS7ARITCg8KBQQEAgAIEga7ARTAAQMKEAoIBAQCAAicCAASBLwBBCoKEQoHBAQCAAifCBIG
vQEEvwEFCmUKBAQEAgESBMQBAkkaVyBSZXF1aXJlZC4gU2hvcnQgbmFtZSBvZiB0aGUgRW5k
cG9pbnRQb2xpY3kgcmVzb3VyY2UgdG8gYmUgY3JlYXRlZC4KIEUuZy4gIkN1c3RvbUVDUyIu
CgoNCgUEBAIBBRIExAECCAoNCgUEBAIBARIExAEJGwoNCgUEBAIBAxIExAEeHwoNCgUEBAIB
CBIExAEgSAoQCggEBAIBCJwIABIExAEhRwpACgQEBAICEgTHAQJOGjIgUmVxdWlyZWQuIEVu
ZHBvaW50UG9saWN5IHJlc291cmNlIHRvIGJlIGNyZWF0ZWQuCgoNCgUEBAICBhIExwECEAoN
CgUEBAICARIExwERIAoNCgUEBAICAxIExwEjJAoNCgUEBAICCBIExwElTQoQCggEBAICCJwI
ABIExwEmTApCCgIEBRIGywEA1gEBGjQgUmVxdWVzdCB1c2VkIHdpdGggdGhlIFVwZGF0ZUVu
ZHBvaW50UG9saWN5IG1ldGhvZC4KCgsKAwQFARIEywEIIwrgAgoEBAUCABIG0QEC0gEvGs8C
IE9wdGlvbmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRv
IGJlIG92ZXJ3cml0dGVuIGluIHRoZQogRW5kcG9pbnRQb2xpY3kgcmVzb3VyY2UgYnkgdGhl
IHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUg
cmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmll
bGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgdGhlCiB1
c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZpZWxkcyB3aWxsIGJlIG92
ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBNEBAhsKDQoFBAUCAAESBNEBHCcKDQoFBAUCAAMSBNEB
KisKDQoFBAUCAAgSBNIBBi4KEAoIBAUCAAicCAASBNIBBy0KOgoEBAUCARIE1QECThosIFJl
cXVpcmVkLiBVcGRhdGVkIEVuZHBvaW50UG9saWN5IHJlc291cmNlLgoKDQoFBAUCAQYSBNUB
AhAKDQoFBAUCAQESBNUBESAKDQoFBAUCAQMSBNUBIyQKDQoFBAUCAQgSBNUBJU0KEAoIBAUC
AQicCAASBNUBJkwKQgoCBAYSBtkBAOIBARo0IFJlcXVlc3QgdXNlZCB3aXRoIHRoZSBEZWxl
dGVFbmRwb2ludFBvbGljeSBtZXRob2QuCgoLCgMEBgESBNkBCCMKjAEKBAQGAgASBtwBAuEB
BBp8IFJlcXVpcmVkLiBBIG5hbWUgb2YgdGhlIEVuZHBvaW50UG9saWN5IHRvIGRlbGV0ZS4g
TXVzdCBiZSBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2Vu
ZHBvaW50UG9saWNpZXMvKmAuCgoNCgUEBgIABRIE3AECCAoNCgUEBgIAARIE3AEJDQoNCgUE
BgIAAxIE3AEQEQoPCgUEBgIACBIG3AES4QEDChAKCAQGAgAInAgAEgTdAQQqChEKBwQGAgAI
nwgSBt4BBOABBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy ===
    # Fields for EndpointPolicy
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkservices.v1beta1.EndpointPolicy.LabelsEntry)
    # Field: type Type: 14 (.google.cloud.networkservices.v1beta1.EndpointPolicy.EndpointPolicyType)
    # Field: authorization_policy Type: 9 ()
    # Field: endpoint_matcher Type: 11 (.google.cloud.networkservices.v1beta1.EndpointMatcher)
    # Field: traffic_port_selector Type: 11 (.google.cloud.networkservices.v1beta1.TrafficPortSelector)
    # Field: description Type: 9 ()
    # Field: server_tls_policy Type: 9 ()
    # Field: client_tls_policy Type: 9 ()

# Enum: EndpointPolicy::EndpointPolicyType
our $EndpointPolicy_ENDPOINT_POLICY_TYPE_UNSPECIFIED = 0;
our $EndpointPolicy_SIDECAR_PROXY = 1;
our $EndpointPolicy_GRPC_SERVER = 2;

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::ListEndpointPoliciesRequest ===
    # Fields for ListEndpointPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::ListEndpointPoliciesResponse ===
    # Fields for ListEndpointPoliciesResponse
    # Field: endpoint_policies Type: 11 (.google.cloud.networkservices.v1beta1.EndpointPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::GetEndpointPolicyRequest ===
    # Fields for GetEndpointPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::CreateEndpointPolicyRequest ===
    # Fields for CreateEndpointPolicyRequest
    # Field: parent Type: 9 ()
    # Field: endpoint_policy_id Type: 9 ()
    # Field: endpoint_policy Type: 11 (.google.cloud.networkservices.v1beta1.EndpointPolicy)

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::UpdateEndpointPolicyRequest ===
    # Fields for UpdateEndpointPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: endpoint_policy Type: 11 (.google.cloud.networkservices.v1beta1.EndpointPolicy)

# === Message: Google::Cloud::Networkservices::V1beta1::EndpointPolicy::DeleteEndpointPolicyRequest ===
    # Fields for DeleteEndpointPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1beta1::EndpointPolicy - Compiled Protocol Buffers messages for google/cloud/networkservices/v1beta1/endpoint_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1beta1::EndpointPolicy;

    my $msg = Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1beta1/endpoint_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy

EndpointPolicy is a resource that helps apply desired configuration
on the endpoints that match specific criteria.
For example, this resource can be used to apply "authentication config"
an all endpoints that serve on port 8080.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the EndpointPolicy resource. It matches pattern
`projects/{project}/locations/global/endpointPolicies/{endpoint_policy}`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy::LabelsEntry>)

Optional. Set of label tags associated with the EndpointPolicy resource.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicyType>)

Required. The type of endpoint policy. This is primarily used to validate
the configuration.

=item * C<< $msg->authorization_policy() >> / C<< $msg->authorization_policy($value) >>

Type: C<String>

Optional. This field specifies the URL of AuthorizationPolicy resource that
applies authorization policies to the inbound traffic at the
matched endpoints. Refer to Authorization. If this field is not
specified, authorization is disabled(no authz checks) for this
endpoint.

=item * C<< $msg->endpoint_matcher() >> / C<< $msg->endpoint_matcher($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::Common::EndpointMatcher>)

Required. A matcher that selects endpoints to which the policies should be
applied.

=item * C<< $msg->traffic_port_selector() >> / C<< $msg->traffic_port_selector($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::Common::TrafficPortSelector>)

Optional. Port selector for the (matched) endpoints. If no port selector is
provided, the matched config is applied to all ports.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A free-text description of the resource. Max length 1024
characters.

=item * C<< $msg->server_tls_policy() >> / C<< $msg->server_tls_policy($value) >>

Type: C<String>

Optional. A URL referring to ServerTlsPolicy resource. ServerTlsPolicy is
used to determine the authentication policy to be applied to terminate the
inbound traffic at the identified backends. If this field is not set,
authentication is disabled(open) for this endpoint.

=item * C<< $msg->client_tls_policy() >> / C<< $msg->client_tls_policy($value) >>

Type: C<String>

Optional. Deprecated: This field is not used and is a no-op.
A URL referring to a ClientTlsPolicy resource. ClientTlsPolicy can be set
to specify the authentication for traffic from the proxy to the actual
endpoints. More specifically, it is applied to the outgoing traffic from
the proxy to the endpoint. This is typically used for sidecar model where
the proxy identifies itself as endpoint to the control plane, with the
connection between sidecar and endpoint requiring authentication. If this
field is not set, authentication is disabled(open). Applicable only when
EndpointPolicyType is SIDECAR_PROXY.

=back

=head3 Enum: EndpointPolicy::EndpointPolicyType

=over 4

=item * C<ENDPOINT_POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<SIDECAR_PROXY> => C<1>

=item * C<GRPC_SERVER> => C<2>

=back

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::ListEndpointPoliciesRequest

Request used with the ListEndpointPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the EndpointPolicies should
be listed, specified in the format `projects/*/locations/global`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of EndpointPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListEndpointPoliciesResponse`
Indicates that this is a continuation of a prior
`ListEndpointPolicies` call, and that the system should return the
next page of data.

=back

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::ListEndpointPoliciesResponse

Response returned by the ListEndpointPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint_policies() >> / C<< $msg->endpoint_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy>)

List of EndpointPolicy resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=back

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::GetEndpointPolicyRequest

Request used with the GetEndpointPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the EndpointPolicy to get. Must be in the format
`projects/*/locations/global/endpointPolicies/*`.

=back

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::CreateEndpointPolicyRequest

Request used with the CreateEndpointPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the EndpointPolicy. Must be in the
format `projects/*/locations/global`.

=item * C<< $msg->endpoint_policy_id() >> / C<< $msg->endpoint_policy_id($value) >>

Type: C<String>

Required. Short name of the EndpointPolicy resource to be created.
E.g. "CustomECS".

=item * C<< $msg->endpoint_policy() >> / C<< $msg->endpoint_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy>)

Required. EndpointPolicy resource to be created.

=back

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::UpdateEndpointPolicyRequest

Request used with the UpdateEndpointPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
EndpointPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->endpoint_policy() >> / C<< $msg->endpoint_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy>)

Required. Updated EndpointPolicy resource.

=back

=head2 Google::Cloud::Networkservices::V1beta1::EndpointPolicy::DeleteEndpointPolicyRequest

Request used with the DeleteEndpointPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the EndpointPolicy to delete. Must be in the format
`projects/*/locations/global/endpointPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1beta1::EndpointPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
