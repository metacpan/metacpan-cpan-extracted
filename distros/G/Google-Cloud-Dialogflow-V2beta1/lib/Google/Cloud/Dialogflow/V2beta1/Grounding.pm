package Google::Cloud::Dialogflow::V2beta1::Grounding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2dyb3VuZGluZy5wcm90bxIfZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90byL0AgoRR3JvdW5kaW5nTWV0YWRhdGESMQoSd2ViX3NlYXJjaF9xdWVyaWVzGAEg
AygJQgPgQQFSEHdlYlNlYXJjaFF1ZXJpZXMSZAoSc2VhcmNoX2VudHJ5X3BvaW50GAIgASgL
MjEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TZWFyY2hFbnRyeVBvaW50QgPg
QQFSEHNlYXJjaEVudHJ5UG9pbnQSXwoQZ3JvdW5kaW5nX2NodW5rcxgDIAMoCzIvLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuR3JvdW5kaW5nQ2h1bmtCA+BBAVIPZ3JvdW5k
aW5nQ2h1bmtzEmUKEmdyb3VuZGluZ19zdXBwb3J0cxgEIAMoCzIxLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuR3JvdW5kaW5nU3VwcG9ydEID4EEBUhFncm91bmRpbmdTdXBw
b3J0cyJCChBTZWFyY2hFbnRyeVBvaW50Ei4KEHJlbmRlcmVkX2NvbnRlbnQYASABKAlCA+BB
AVIPcmVuZGVyZWRDb250ZW50IpcDCg5Hcm91bmRpbmdDaHVuaxJMCgN3ZWIYASABKAsyMy5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkdyb3VuZGluZ0NodW5rLldlYkID4EEB
SABSA3dlYhJ0ChFyZXRyaWV2ZWRfY29udGV4dBgCIAEoCzJALmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuR3JvdW5kaW5nQ2h1bmsuUmV0cmlldmVkQ29udGV4dEID4EEBSABS
EHJldHJpZXZlZENvbnRleHQaVAoDV2ViEhUKA3VyaRgBIAEoCUID4EEDUgN1cmkSGQoFdGl0
bGUYAiABKAlCA+BBA1IFdGl0bGUSGwoGZG9tYWluGAMgASgJQgPgQQNSBmRvbWFpbhpdChBS
ZXRyaWV2ZWRDb250ZXh0EhUKA3VyaRgBIAEoCUID4EEDUgN1cmkSGQoFdGl0bGUYAiABKAlC
A+BBA1IFdGl0bGUSFwoEdGV4dBgDIAEoCUID4EEDUgR0ZXh0QgwKCmNodW5rX3R5cGUiagoH
U2VnbWVudBIkCgtzdGFydF9pbmRleBgBIAEoBUID4EEDUgpzdGFydEluZGV4EiAKCWVuZF9p
bmRleBgCIAEoBUID4EEDUghlbmRJbmRleBIXCgR0ZXh0GAMgASgJQgPgQQNSBHRleHQimAEK
EEdyb3VuZGluZ1N1cHBvcnQSRwoHc2VnbWVudBgBIAEoCzIoLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuU2VnbWVudEID4EEBUgdzZWdtZW50EjsKF2dyb3VuZGluZ19jaHVu
a19pbmRpY2VzGAIgAygFQgPgQQFSFWdyb3VuZGluZ0NodW5rSW5kaWNlc0KjAQojY29tLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTFCDkdyb3VuZGluZ1Byb3RvUAFaQ2Nsb3Vk
Lmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2MmJldGExL2RpYWxvZ2Zsb3dwYjtkaWFs
b2dmbG93cGKiAgJERqoCH0dvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYyQmV0YTFKiSsKBxIF
DgCGAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoC
AwASAxIAKQoICgEIEgMUADwKCQoCCCUSAxQAPAoICgEIEgMVAFoKCQoCCAsSAxUAWgoICgEI
EgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC8KCQoCCAgSAxcALwoICgEIEgMYADwKCQoCCAES
AxgAPAoICgEIEgMZACAKCQoCCCQSAxkAIAqHAQoCBAASBB0AMAEaeyBHcm91bmRpbmcgbWV0
YWRhdGEgY29udGFpbnMgc291cmNlcywgY2l0YXRpb25zLCBhbmQgc2VhcmNoIGVudHJ5IHBv
aW50cyB1c2VkCiB0byBncm91bmQgYSBnZW5lcmF0ZWQgYW5zd2VyIG9yIHN1Z2dlc3Rpb24u
CgoKCgMEAAESAx0IGQpYCgQEAAIAEgQfAiAvGkogT3B0aW9uYWwuIFRoZSB3ZWIgc2VhcmNo
IHF1ZXJpZXMgdGhhdCB3ZXJlIHVzZWQgdG8gZ2VuZXJhdGUgdGhlIGNvbnRlbnQuCgoMCgUE
AAIABBIDHwIKCgwKBQQAAgAFEgMfCxEKDAoFBAACAAESAx8SJAoMCgUEAAIAAxIDHycoCgwK
BQQAAgAIEgMgBi4KDwoIBAACAAicCAASAyAHLQpfCgQEAAIBEgQkAiUvGlEgT3B0aW9uYWwu
IEEgd2ViIHNlYXJjaCBlbnRyeSBwb2ludCB0aGF0IGNhbiBiZSB1c2VkIHRvIGRpc3BsYXkg
c2VhcmNoCiByZXN1bHRzLgoKDAoFBAACAQYSAyQCEgoMCgUEAAIBARIDJBMlCgwKBQQAAgED
EgMkKCkKDAoFBAACAQgSAyUGLgoPCggEAAIBCJwIABIDJQctCl8KBAQAAgISBCkCKi8aUSBP
cHRpb25hbC4gQSBsaXN0IG9mIHN1cHBvcnRpbmcgcmVmZXJlbmNlcyByZXRyaWV2ZWQgZnJv
bSB0aGUgZ3JvdW5kaW5nCiBzb3VyY2UuCgoMCgUEAAICBBIDKQIKCgwKBQQAAgIGEgMpCxkK
DAoFBAACAgESAykaKgoMCgUEAAICAxIDKS0uCgwKBQQAAgIIEgMqBi4KDwoIBAACAgicCAAS
AyoHLQpzCgQEAAIDEgQuAi8vGmUgT3B0aW9uYWwuIEEgbGlzdCBvZiBncm91bmRpbmcgc3Vw
cG9ydHMgdGhhdCBjb25uZWN0IHRoZSBnZW5lcmF0ZWQKIGNvbnRlbnQgdG8gdGhlIGdyb3Vu
ZGluZyBjaHVua3MuCgoMCgUEAAIDBBIDLgIKCgwKBQQAAgMGEgMuCxsKDAoFBAACAwESAy4c
LgoMCgUEAAIDAxIDLjEyCgwKBQQAAgMIEgMvBi4KDwoIBAACAwicCAASAy8HLQooCgIEARIE
MwA4ARocIEdvb2dsZSBzZWFyY2ggZW50cnkgcG9pbnQuCgoKCgMEAQESAzMIGAraAQoEBAEC
ABIDNwJHGswBIE9wdGlvbmFsLiBBbiBIVE1MIHNuaXBwZXQgdGhhdCBjYW4gYmUgZW1iZWRk
ZWQgaW4gYSB3ZWIgcGFnZSBvciBhbgogYXBwbGljYXRpb24ncyB3ZWJ2aWV3LiBUaGlzIHNu
aXBwZXQgZGlzcGxheXMgYSBzZWFyY2ggcmVzdWx0LCBpbmNsdWRpbmcgdGhlCiB0aXRsZSwg
VVJMLCBhbmQgYSBicmllZiBkZXNjcmlwdGlvbiBvZiB0aGUgc2VhcmNoIHJlc3VsdC4KCgwK
BQQBAgAFEgM3AggKDAoFBAECAAESAzcJGQoMCgUEAQIAAxIDNxwdCgwKBQQBAgAIEgM3HkYK
DwoIBAECAAicCAASAzcfRQrHAQoCBAISBD4AaAEaugEgQSBwaWVjZSBvZiBldmlkZW5jZSB0
aGF0IHN1cHBvcnRzIGEgY2xhaW0gbWFkZSBieSB0aGUgbW9kZWwuCgogVGhpcyBpcyB1c2Vk
IHRvIHNob3cgYSBjaXRhdGlvbiBmb3IgYSBjbGFpbSBtYWRlIGJ5IHRoZSBtb2RlbC4KIEl0
IGNvbnRhaW5zIGEgcmVmZXJlbmNlIHRvIHRoZSBzb3VyY2Ugb2YgdGhlIGluZm9ybWF0aW9u
LgoKCgoDBAIBEgM+CBYK+wEKBAQCAwASBEMCTQMa7AEgQSBgV2ViYCBjaHVuayBpcyBhIHBp
ZWNlIG9mIGV2aWRlbmNlIHRoYXQgY29tZXMgZnJvbSBhIHdlYiBwYWdlLiBJdAogY29udGFp
bnMgdGhlIFVSSSBvZiB0aGUgd2ViIHBhZ2UsIHRoZSB0aXRsZSBvZiB0aGUgcGFnZSwgYW5k
IHRoZSBkb21haW4gb2YKIHRoZSBwYWdlLiBUaGlzIGlzIHVzZWQgdG8gcHJvdmlkZSB0aGUg
dXNlciB3aXRoIGEgbGluayB0byB0aGUgc291cmNlIG9mCiB0aGUgaW5mb3JtYXRpb24uCgoM
CgUEAgMAARIDQwoNClEKBgQCAwACABIDRQQ/GkIgT3V0cHV0IG9ubHkuIFRoZSBVUkkgb2Yg
dGhlIHdlYiBwYWdlIHRoYXQgY29udGFpbnMgdGhlIGV2aWRlbmNlLgoKDgoHBAIDAAIABRID
RQQKCg4KBwQCAwACAAESA0ULDgoOCgcEAgMAAgADEgNFERIKDgoHBAIDAAIACBIDRRM+ChEK
CgQCAwACAAicCAASA0UUPQpTCgYEAgMAAgESA0gEQRpEIE91dHB1dCBvbmx5LiBUaGUgdGl0
bGUgb2YgdGhlIHdlYiBwYWdlIHRoYXQgY29udGFpbnMgdGhlIGV2aWRlbmNlLgoKDgoHBAID
AAIBBRIDSAQKCg4KBwQCAwACAQESA0gLEAoOCgcEAgMAAgEDEgNIExQKDgoHBAIDAAIBCBID
SBVAChEKCgQCAwACAQicCAASA0gWPwqJAQoGBAIDAAICEgNMBEIaeiBPdXRwdXQgb25seS4g
VGhlIGRvbWFpbiBvZiB0aGUgd2ViIHBhZ2UgdGhhdCBjb250YWlucyB0aGUgZXZpZGVuY2Uu
IFRoaXMKIGNhbiBiZSB1c2VkIHRvIGZpbHRlciBvdXQgbG93LXF1YWxpdHkgc291cmNlcy4K
Cg4KBwQCAwACAgUSA0wECgoOCgcEAgMAAgIBEgNMCxEKDgoHBAIDAAICAxIDTBQVCg4KBwQC
AwACAggSA0wWQQoRCgoEAgMAAgIInAgAEgNMF0AKvwEKBAQCAwESBFICWwMasAEgQ29udGV4
dCByZXRyaWV2ZWQgZnJvbSBhIGRhdGEgc291cmNlIHRvIGdyb3VuZCB0aGUgbW9kZWwncyBy
ZXNwb25zZS4gVGhpcwogaXMgdXNlZCB3aGVuIGEgcmV0cmlldmFsIHRvb2wgZmV0Y2hlcyBp
bmZvcm1hdGlvbiBmcm9tIGEgdXNlci1wcm92aWRlZAogY29ycHVzIG9yIGEgcHVibGljIGRh
dGFzZXQuCgoMCgUEAgMBARIDUgoaCkMKBgQCAwECABIDVAQ/GjQgT3V0cHV0IG9ubHkuIFRo
ZSBVUkkgb2YgdGhlIHJldHJpZXZlZCBkYXRhIHNvdXJjZS4KCg4KBwQCAwECAAUSA1QECgoO
CgcEAgMBAgABEgNUCw4KDgoHBAIDAQIAAxIDVBESCg4KBwQCAwECAAgSA1QTPgoRCgoEAgMB
AgAInAgAEgNUFD0KRQoGBAIDAQIBEgNXBEEaNiBPdXRwdXQgb25seS4gVGhlIHRpdGxlIG9m
IHRoZSByZXRyaWV2ZWQgZGF0YSBzb3VyY2UuCgoOCgcEAgMBAgEFEgNXBAoKDgoHBAIDAQIB
ARIDVwsQCg4KBwQCAwECAQMSA1cTFAoOCgcEAgMBAgEIEgNXFUAKEQoKBAIDAQIBCJwIABID
VxY/CkcKBgQCAwECAhIDWgRAGjggT3V0cHV0IG9ubHkuIFRoZSBjb250ZW50IG9mIHRoZSBy
ZXRyaWV2ZWQgZGF0YSBzb3VyY2UuCgoOCgcEAgMBAgIFEgNaBAoKDgoHBAIDAQICARIDWgsP
Cg4KBwQCAwECAgMSA1oSEwoOCgcEAgMBAgIIEgNaFD8KEQoKBAIDAQICCJwIABIDWhU+ClgK
BAQCCAASBF4CZwMaSiBUaGUgc291cmNlIG9mIHRoZSBncm91bmRpbmcgY2h1bmsuIEN1cnJl
bnRseSB3ZSBvbmx5IHN1cHBvcnQgd2ViIHNlYXJjaC4KCgwKBQQCCAABEgNeCBIKegoEBAIC
ABIDYQQ5Gm0gT3B0aW9uYWwuIEEgZ3JvdW5kaW5nIGNodW5rIGZyb20gYSB3ZWIgcGFnZSwg
dHlwaWNhbGx5IGZyb20gd2ViCiBzZWFyY2guIFNlZSB0aGUgYFdlYmAgbWVzc2FnZSBmb3Ig
ZGV0YWlscy4KCgwKBQQCAgAGEgNhBAcKDAoFBAICAAESA2EICwoMCgUEAgIAAxIDYQ4PCgwK
BQQCAgAIEgNhEDgKDwoIBAICAAicCAASA2ERNwpfCgQEAgIBEgRlBGYxGlEgT3B0aW9uYWwu
IEEgZ3JvdW5kaW5nIGNodW5rIGZyb20gYSBkYXRhIHNvdXJjZSByZXRyaWV2ZWQgYnkgYQog
ZGF0YSBzdG9yZSB0b29sLgoKDAoFBAICAQYSA2UEFAoMCgUEAgIBARIDZRUmCgwKBQQCAgED
EgNlKSoKDAoFBAICAQgSA2YIMAoPCggEAgIBCJwIABIDZgkvCicKAgQDEgRrAHgBGhsgQSBz
ZWdtZW50IG9mIHRoZSBjb250ZW50LgoKCgoDBAMBEgNrCA8KzAEKBAQDAgASA28CRBq+ASBP
dXRwdXQgb25seS4gVGhlIHN0YXJ0IGluZGV4IG9mIHRoZSBzZWdtZW50LCBtZWFzdXJlZCBp
biBieXRlcy4gVGhpcyBtYXJrcwogdGhlIGJlZ2lubmluZyBvZiB0aGUgc2VnbWVudCBhbmQg
aXMgaW5jbHVzaXZlLCBtZWFuaW5nIHRoZSBieXRlIGF0IHRoaXMKIGluZGV4IGlzIHRoZSBm
aXJzdCBieXRlIG9mIHRoZSBzZWdtZW50LgoKDAoFBAMCAAUSA28CBwoMCgUEAwIAARIDbwgT
CgwKBQQDAgADEgNvFhcKDAoFBAMCAAgSA28YQwoPCggEAwIACJwIABIDbxlCCtoBCgQEAwIB
EgN0AkIazAEgT3V0cHV0IG9ubHkuIFRoZSBlbmQgaW5kZXggb2YgdGhlIHNlZ21lbnQsIG1l
YXN1cmVkIGluIGJ5dGVzLiBUaGlzIG1hcmtzCiB0aGUgZW5kIG9mIHRoZSBzZWdtZW50IGFu
ZCBpcyBleGNsdXNpdmUsIG1lYW5pbmcgdGhlIHNlZ21lbnQgaW5jbHVkZXMKIGNvbnRlbnQg
dXAgdG8sIGJ1dCBub3QgaW5jbHVkaW5nLCB0aGUgYnl0ZSBhdCB0aGlzIGluZGV4LgoKDAoF
BAMCAQUSA3QCBwoMCgUEAwIBARIDdAgRCgwKBQQDAgEDEgN0FBUKDAoFBAMCAQgSA3QWQQoP
CggEAwIBCJwIABIDdBdACjQKBAQDAgISA3cCPhonIE91dHB1dCBvbmx5LiBUaGUgdGV4dCBv
ZiB0aGUgc2VnbWVudC4KCgwKBQQDAgIFEgN3AggKDAoFBAMCAgESA3cJDQoMCgUEAwICAxID
dxARCgwKBQQDAgIIEgN3Ej0KDwoIBAMCAgicCAASA3cTPApkCgIEBBIFfACGAQEaVyBBIGNv
bGxlY3Rpb24gb2Ygc3VwcG9ydGluZyByZWZlcmVuY2VzIGZvciBhIHNlZ21lbnQgb3IgcGFy
dCBvZiB0aGUKIG1vZGVsJ3MgcmVzcG9uc2UuCgoKCgMEBAESA3wIGApICgQEBAIAEgN+Aj8a
OyBPcHRpb25hbC4gU2VnbWVudCBvZiB0aGUgY29udGVudCB0aGlzIHN1cHBvcnQgYmVsb25n
cyB0by4KCgwKBQQEAgAGEgN+AgkKDAoFBAQCAAESA34KEQoMCgUEBAIAAxIDfhQVCgwKBQQE
AgAIEgN+Fj4KDwoIBAQCAAicCAASA34XPQqCAgoEBAQCARIGhAEChQEvGvEBIE9wdGlvbmFs
LiBBIGxpc3Qgb2YgaW5kaWNlcyBpbnRvIGBncm91bmRpbmdfY2h1bmtzYCBmaWVsZCBzcGVj
aWZ5aW5nIHRoZQogY2l0YXRpb25zIGFzc29jaWF0ZWQgd2l0aCB0aGUgY2xhaW0uIEZvciBp
bnN0YW5jZSBbMSwgM10gbWVhbnMgdGhhdAogZ3JvdW5kaW5nX2NodW5rc1sxXSBhbmQgZ3Jv
dW5kaW5nX2NodW5rc1szXSBhcmUgdGhlIHJldHJpZXZlZCBjb250ZW50cwogYXR0cmlidXRl
ZCB0byB0aGUgY2xhaW0uCgoNCgUEBAIBBBIEhAECCgoNCgUEBAIBBRIEhAELEAoNCgUEBAIB
ARIEhAERKAoNCgUEBAIBAxIEhAErLAoNCgUEBAIBCBIEhQEGLgoQCggEBAIBCJwIABIEhQEH
LWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingMetadata ===
    # Fields for GroundingMetadata
    # Field: web_search_queries Type: 9 ()
    # Field: search_entry_point Type: 11 (.google.cloud.dialogflow.v2beta1.SearchEntryPoint)
    # Field: grounding_chunks Type: 11 (.google.cloud.dialogflow.v2beta1.GroundingChunk)
    # Field: grounding_supports Type: 11 (.google.cloud.dialogflow.v2beta1.GroundingSupport)

# === Message: Google::Cloud::Dialogflow::V2beta1::Grounding::SearchEntryPoint ===
    # Fields for SearchEntryPoint
    # Field: rendered_content Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingChunk ===
    # Fields for GroundingChunk
    # Field: web Type: 11 (.google.cloud.dialogflow.v2beta1.GroundingChunk.Web)
    # Field: retrieved_context Type: 11 (.google.cloud.dialogflow.v2beta1.GroundingChunk.RetrievedContext)

# === Message: Google::Cloud::Dialogflow::V2beta1::Grounding::Segment ===
    # Fields for Segment
    # Field: start_index Type: 5 ()
    # Field: end_index Type: 5 ()
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingSupport ===
    # Fields for GroundingSupport
    # Field: segment Type: 11 (.google.cloud.dialogflow.v2beta1.Segment)
    # Field: grounding_chunk_indices Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Grounding - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/grounding.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Grounding;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingMetadata->new({
        web_search_queries => $web_search_queries,
        search_entry_point => $search_entry_point,
        grounding_chunks => $grounding_chunks,
        grounding_supports => $grounding_supports,
    });

    # Read or update a field
    my $val = $msg->web_search_queries();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/grounding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingMetadata

Grounding metadata contains sources, citations, and search entry points used
to ground a generated answer or suggestion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->web_search_queries() >> / C<< $msg->web_search_queries($value) >>

Type: C<String>

Optional. The web search queries that were used to generate the content.

=item * C<< $msg->search_entry_point() >> / C<< $msg->search_entry_point($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Grounding::SearchEntryPoint>)

Optional. A web search entry point that can be used to display search
results.

=item * C<< $msg->grounding_chunks() >> / C<< $msg->grounding_chunks($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingChunk>)

Optional. A list of supporting references retrieved from the grounding
source.

=item * C<< $msg->grounding_supports() >> / C<< $msg->grounding_supports($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingSupport>)

Optional. A list of grounding supports that connect the generated
content to the grounding chunks.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Grounding::SearchEntryPoint

Google search entry point.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rendered_content() >> / C<< $msg->rendered_content($value) >>

Type: C<String>

Optional. An HTML snippet that can be embedded in a web page or an
application's webview. This snippet displays a search result, including the
title, URL, and a brief description of the search result.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingChunk

A piece of evidence that supports a claim made by the model.

This is used to show a citation for a claim made by the model.
It contains a reference to the source of the information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->web() >> / C<< $msg->web($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingChunk::Web>)

Optional. A grounding chunk from a web page, typically from web
search. See the `Web` message for details.

=item * C<< $msg->retrieved_context() >> / C<< $msg->retrieved_context($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingChunk::RetrievedContext>)

Optional. A grounding chunk from a data source retrieved by a
data store tool.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Grounding::Segment

A segment of the content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_index() >> / C<< $msg->start_index($value) >>

Type: C<Int32>

Output only. The start index of the segment, measured in bytes. This marks
the beginning of the segment and is inclusive, meaning the byte at this
index is the first byte of the segment.

=item * C<< $msg->end_index() >> / C<< $msg->end_index($value) >>

Type: C<Int32>

Output only. The end index of the segment, measured in bytes. This marks
the end of the segment and is exclusive, meaning the segment includes
content up to, but not including, the byte at this index.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Output only. The text of the segment.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Grounding::GroundingSupport

A collection of supporting references for a segment or part of the
model's response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->segment() >> / C<< $msg->segment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Grounding::Segment>)

Optional. Segment of the content this support belongs to.

=item * C<< $msg->grounding_chunk_indices() >> / C<< $msg->grounding_chunk_indices($value) >>

Type: C<Int32>

Optional. A list of indices into `grounding_chunks` field specifying the
citations associated with the claim. For instance [1, 3] means that
grounding_chunks[1] and grounding_chunks[3] are the retrieved contents
attributed to the claim.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Grounding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
