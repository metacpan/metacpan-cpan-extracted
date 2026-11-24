package Google::Cloud::Dialogflow::V2::Grounding;

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
Cipnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9ncm91bmRpbmcucHJvdG8SGmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIuUC
ChFHcm91bmRpbmdNZXRhZGF0YRIxChJ3ZWJfc2VhcmNoX3F1ZXJpZXMYASADKAlCA+BBAVIQ
d2ViU2VhcmNoUXVlcmllcxJfChJzZWFyY2hfZW50cnlfcG9pbnQYAiABKAsyLC5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5TZWFyY2hFbnRyeVBvaW50QgPgQQFSEHNlYXJjaEVudHJ5
UG9pbnQSWgoQZ3JvdW5kaW5nX2NodW5rcxgDIAMoCzIqLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyLkdyb3VuZGluZ0NodW5rQgPgQQFSD2dyb3VuZGluZ0NodW5rcxJgChJncm91bmRp
bmdfc3VwcG9ydHMYBCADKAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Hcm91bmRp
bmdTdXBwb3J0QgPgQQFSEWdyb3VuZGluZ1N1cHBvcnRzIkIKEFNlYXJjaEVudHJ5UG9pbnQS
LgoQcmVuZGVyZWRfY29udGVudBgBIAEoCUID4EEBUg9yZW5kZXJlZENvbnRlbnQijQMKDkdy
b3VuZGluZ0NodW5rEkcKA3dlYhgBIAEoCzIuLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
Lkdyb3VuZGluZ0NodW5rLldlYkID4EEBSABSA3dlYhJvChFyZXRyaWV2ZWRfY29udGV4dBgC
IAEoCzI7Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkdyb3VuZGluZ0NodW5rLlJldHJp
ZXZlZENvbnRleHRCA+BBAUgAUhByZXRyaWV2ZWRDb250ZXh0GlQKA1dlYhIVCgN1cmkYASAB
KAlCA+BBA1IDdXJpEhkKBXRpdGxlGAIgASgJQgPgQQNSBXRpdGxlEhsKBmRvbWFpbhgDIAEo
CUID4EEDUgZkb21haW4aXQoQUmV0cmlldmVkQ29udGV4dBIVCgN1cmkYASABKAlCA+BBA1ID
dXJpEhkKBXRpdGxlGAIgASgJQgPgQQNSBXRpdGxlEhcKBHRleHQYAyABKAlCA+BBA1IEdGV4
dEIMCgpjaHVua190eXBlImoKB1NlZ21lbnQSJAoLc3RhcnRfaW5kZXgYASABKAVCA+BBA1IK
c3RhcnRJbmRleBIgCgllbmRfaW5kZXgYAiABKAVCA+BBA1IIZW5kSW5kZXgSFwoEdGV4dBgD
IAEoCUID4EEDUgR0ZXh0IpMBChBHcm91bmRpbmdTdXBwb3J0EkIKB3NlZ21lbnQYASABKAsy
Iy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TZWdtZW50QgPgQQFSB3NlZ21lbnQSOwoX
Z3JvdW5kaW5nX2NodW5rX2luZGljZXMYAiADKAVCA+BBAVIVZ3JvdW5kaW5nQ2h1bmtJbmRp
Y2VzQpQBCh5jb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJCDkdyb3VuZGluZ1Byb3Rv
UAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7
ZGlhbG9nZmxvd3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkq0KwoHEgUO
AIcBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgID
ABIDEgApCggKAQgSAxQANwoJCgIIJRIDFAA3CggKAQgSAxUAVQoJCgIICxIDFQBVCggKAQgS
AxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgANwoJCgIIARID
GAA3CggKAQgSAxkAIAoJCgIIJBIDGQAgCocBCgIEABIEHQAwARp7IEdyb3VuZGluZyBtZXRh
ZGF0YSBjb250YWlucyBzb3VyY2VzLCBjaXRhdGlvbnMsIGFuZCBzZWFyY2ggZW50cnkgcG9p
bnRzIHVzZWQKIHRvIGdyb3VuZCBhIGdlbmVyYXRlZCBhbnN3ZXIgb3Igc3VnZ2VzdGlvbi4K
CgoKAwQAARIDHQgZClgKBAQAAgASBB8CIC8aSiBPcHRpb25hbC4gVGhlIHdlYiBzZWFyY2gg
cXVlcmllcyB0aGF0IHdlcmUgdXNlZCB0byBnZW5lcmF0ZSB0aGUgY29udGVudC4KCgwKBQQA
AgAEEgMfAgoKDAoFBAACAAUSAx8LEQoMCgUEAAIAARIDHxIkCgwKBQQAAgADEgMfJygKDAoF
BAACAAgSAyAGLgoPCggEAAIACJwIABIDIActCl8KBAQAAgESBCQCJS8aUSBPcHRpb25hbC4g
QSB3ZWIgc2VhcmNoIGVudHJ5IHBvaW50IHRoYXQgY2FuIGJlIHVzZWQgdG8gZGlzcGxheSBz
ZWFyY2gKIHJlc3VsdHMuCgoMCgUEAAIBBhIDJAISCgwKBQQAAgEBEgMkEyUKDAoFBAACAQMS
AyQoKQoMCgUEAAIBCBIDJQYuCg8KCAQAAgEInAgAEgMlBy0KXwoEBAACAhIEKQIqLxpRIE9w
dGlvbmFsLiBBIGxpc3Qgb2Ygc3VwcG9ydGluZyByZWZlcmVuY2VzIHJldHJpZXZlZCBmcm9t
IHRoZSBncm91bmRpbmcKIHNvdXJjZS4KCgwKBQQAAgIEEgMpAgoKDAoFBAACAgYSAykLGQoM
CgUEAAICARIDKRoqCgwKBQQAAgIDEgMpLS4KDAoFBAACAggSAyoGLgoPCggEAAICCJwIABID
KgctCnMKBAQAAgMSBC4CLy8aZSBPcHRpb25hbC4gQSBsaXN0IG9mIGdyb3VuZGluZyBzdXBw
b3J0cyB0aGF0IGNvbm5lY3QgdGhlIGdlbmVyYXRlZAogY29udGVudCB0byB0aGUgZ3JvdW5k
aW5nIGNodW5rcy4KCgwKBQQAAgMEEgMuAgoKDAoFBAACAwYSAy4LGwoMCgUEAAIDARIDLhwu
CgwKBQQAAgMDEgMuMTIKDAoFBAACAwgSAy8GLgoPCggEAAIDCJwIABIDLwctClMKAgQBEgQ0
ADkBGkcgQSB3ZWIgc2VhcmNoIGVudHJ5IHBvaW50IHRoYXQgY2FuIGJlIHVzZWQgdG8gZGlz
cGxheSBzZWFyY2gKIHJlc3VsdHMuCgoKCgMEAQESAzQIGAraAQoEBAECABIDOAJHGswBIE9w
dGlvbmFsLiBBbiBIVE1MIHNuaXBwZXQgdGhhdCBjYW4gYmUgZW1iZWRkZWQgaW4gYSB3ZWIg
cGFnZSBvciBhbgogYXBwbGljYXRpb24ncyB3ZWJ2aWV3LiBUaGlzIHNuaXBwZXQgZGlzcGxh
eXMgYSBzZWFyY2ggcmVzdWx0LCBpbmNsdWRpbmcgdGhlCiB0aXRsZSwgVVJMLCBhbmQgYSBi
cmllZiBkZXNjcmlwdGlvbiBvZiB0aGUgc2VhcmNoIHJlc3VsdC4KCgwKBQQBAgAFEgM4AggK
DAoFBAECAAESAzgJGQoMCgUEAQIAAxIDOBwdCgwKBQQBAgAIEgM4HkYKDwoIBAECAAicCAAS
AzgfRQrHAQoCBAISBD8AaQEaugEgQSBwaWVjZSBvZiBldmlkZW5jZSB0aGF0IHN1cHBvcnRz
IGEgY2xhaW0gbWFkZSBieSB0aGUgbW9kZWwuCgogVGhpcyBpcyB1c2VkIHRvIHNob3cgYSBj
aXRhdGlvbiBmb3IgYSBjbGFpbSBtYWRlIGJ5IHRoZSBtb2RlbC4KIEl0IGNvbnRhaW5zIGEg
cmVmZXJlbmNlIHRvIHRoZSBzb3VyY2Ugb2YgdGhlIGluZm9ybWF0aW9uLgoKCgoDBAIBEgM/
CBYK+wEKBAQCAwASBEQCTgMa7AEgQSBgV2ViYCBjaHVuayBpcyBhIHBpZWNlIG9mIGV2aWRl
bmNlIHRoYXQgY29tZXMgZnJvbSBhIHdlYiBwYWdlLiBJdAogY29udGFpbnMgdGhlIFVSSSBv
ZiB0aGUgd2ViIHBhZ2UsIHRoZSB0aXRsZSBvZiB0aGUgcGFnZSwgYW5kIHRoZSBkb21haW4g
b2YKIHRoZSBwYWdlLiBUaGlzIGlzIHVzZWQgdG8gcHJvdmlkZSB0aGUgdXNlciB3aXRoIGEg
bGluayB0byB0aGUgc291cmNlIG9mCiB0aGUgaW5mb3JtYXRpb24uCgoMCgUEAgMAARIDRAoN
ClEKBgQCAwACABIDRgQ/GkIgT3V0cHV0IG9ubHkuIFRoZSBVUkkgb2YgdGhlIHdlYiBwYWdl
IHRoYXQgY29udGFpbnMgdGhlIGV2aWRlbmNlLgoKDgoHBAIDAAIABRIDRgQKCg4KBwQCAwAC
AAESA0YLDgoOCgcEAgMAAgADEgNGERIKDgoHBAIDAAIACBIDRhM+ChEKCgQCAwACAAicCAAS
A0YUPQpTCgYEAgMAAgESA0kEQRpEIE91dHB1dCBvbmx5LiBUaGUgdGl0bGUgb2YgdGhlIHdl
YiBwYWdlIHRoYXQgY29udGFpbnMgdGhlIGV2aWRlbmNlLgoKDgoHBAIDAAIBBRIDSQQKCg4K
BwQCAwACAQESA0kLEAoOCgcEAgMAAgEDEgNJExQKDgoHBAIDAAIBCBIDSRVAChEKCgQCAwAC
AQicCAASA0kWPwqJAQoGBAIDAAICEgNNBEIaeiBPdXRwdXQgb25seS4gVGhlIGRvbWFpbiBv
ZiB0aGUgd2ViIHBhZ2UgdGhhdCBjb250YWlucyB0aGUgZXZpZGVuY2UuIFRoaXMKIGNhbiBi
ZSB1c2VkIHRvIGZpbHRlciBvdXQgbG93LXF1YWxpdHkgc291cmNlcy4KCg4KBwQCAwACAgUS
A00ECgoOCgcEAgMAAgIBEgNNCxEKDgoHBAIDAAICAxIDTRQVCg4KBwQCAwACAggSA00WQQoR
CgoEAgMAAgIInAgAEgNNF0AKvwEKBAQCAwESBFMCXAMasAEgQ29udGV4dCByZXRyaWV2ZWQg
ZnJvbSBhIGRhdGEgc291cmNlIHRvIGdyb3VuZCB0aGUgbW9kZWwncyByZXNwb25zZS4gVGhp
cwogaXMgdXNlZCB3aGVuIGEgcmV0cmlldmFsIHRvb2wgZmV0Y2hlcyBpbmZvcm1hdGlvbiBm
cm9tIGEgdXNlci1wcm92aWRlZAogY29ycHVzIG9yIGEgcHVibGljIGRhdGFzZXQuCgoMCgUE
AgMBARIDUwoaCkMKBgQCAwECABIDVQQ/GjQgT3V0cHV0IG9ubHkuIFRoZSBVUkkgb2YgdGhl
IHJldHJpZXZlZCBkYXRhIHNvdXJjZS4KCg4KBwQCAwECAAUSA1UECgoOCgcEAgMBAgABEgNV
Cw4KDgoHBAIDAQIAAxIDVRESCg4KBwQCAwECAAgSA1UTPgoRCgoEAgMBAgAInAgAEgNVFD0K
RQoGBAIDAQIBEgNYBEEaNiBPdXRwdXQgb25seS4gVGhlIHRpdGxlIG9mIHRoZSByZXRyaWV2
ZWQgZGF0YSBzb3VyY2UuCgoOCgcEAgMBAgEFEgNYBAoKDgoHBAIDAQIBARIDWAsQCg4KBwQC
AwECAQMSA1gTFAoOCgcEAgMBAgEIEgNYFUAKEQoKBAIDAQIBCJwIABIDWBY/CkcKBgQCAwEC
AhIDWwRAGjggT3V0cHV0IG9ubHkuIFRoZSBjb250ZW50IG9mIHRoZSByZXRyaWV2ZWQgZGF0
YSBzb3VyY2UuCgoOCgcEAgMBAgIFEgNbBAoKDgoHBAIDAQICARIDWwsPCg4KBwQCAwECAgMS
A1sSEwoOCgcEAgMBAgIIEgNbFD8KEQoKBAIDAQICCJwIABIDWxU+ClgKBAQCCAASBF8CaAMa
SiBUaGUgc291cmNlIG9mIHRoZSBncm91bmRpbmcgY2h1bmsuIEN1cnJlbnRseSB3ZSBvbmx5
IHN1cHBvcnQgd2ViIHNlYXJjaC4KCgwKBQQCCAABEgNfCBIKegoEBAICABIDYgQ5Gm0gT3B0
aW9uYWwuIEEgZ3JvdW5kaW5nIGNodW5rIGZyb20gYSB3ZWIgcGFnZSwgdHlwaWNhbGx5IGZy
b20gd2ViCiBzZWFyY2guIFNlZSB0aGUgYFdlYmAgbWVzc2FnZSBmb3IgZGV0YWlscy4KCgwK
BQQCAgAGEgNiBAcKDAoFBAICAAESA2IICwoMCgUEAgIAAxIDYg4PCgwKBQQCAgAIEgNiEDgK
DwoIBAICAAicCAASA2IRNwpfCgQEAgIBEgRmBGcxGlEgT3B0aW9uYWwuIEEgZ3JvdW5kaW5n
IGNodW5rIGZyb20gYSBkYXRhIHNvdXJjZSByZXRyaWV2ZWQgYnkgYQogZGF0YSBzdG9yZSB0
b29sLgoKDAoFBAICAQYSA2YEFAoMCgUEAgIBARIDZhUmCgwKBQQCAgEDEgNmKSoKDAoFBAIC
AQgSA2cIMAoPCggEAgIBCJwIABIDZwkvCicKAgQDEgRsAHkBGhsgQSBzZWdtZW50IG9mIHRo
ZSBjb250ZW50LgoKCgoDBAMBEgNsCA8KzAEKBAQDAgASA3ACRBq+ASBPdXRwdXQgb25seS4g
VGhlIHN0YXJ0IGluZGV4IG9mIHRoZSBzZWdtZW50LCBtZWFzdXJlZCBpbiBieXRlcy4gVGhp
cyBtYXJrcwogdGhlIGJlZ2lubmluZyBvZiB0aGUgc2VnbWVudCBhbmQgaXMgaW5jbHVzaXZl
LCBtZWFuaW5nIHRoZSBieXRlIGF0IHRoaXMKIGluZGV4IGlzIHRoZSBmaXJzdCBieXRlIG9m
IHRoZSBzZWdtZW50LgoKDAoFBAMCAAUSA3ACBwoMCgUEAwIAARIDcAgTCgwKBQQDAgADEgNw
FhcKDAoFBAMCAAgSA3AYQwoPCggEAwIACJwIABIDcBlCCtoBCgQEAwIBEgN1AkIazAEgT3V0
cHV0IG9ubHkuIFRoZSBlbmQgaW5kZXggb2YgdGhlIHNlZ21lbnQsIG1lYXN1cmVkIGluIGJ5
dGVzLiBUaGlzIG1hcmtzCiB0aGUgZW5kIG9mIHRoZSBzZWdtZW50IGFuZCBpcyBleGNsdXNp
dmUsIG1lYW5pbmcgdGhlIHNlZ21lbnQgaW5jbHVkZXMKIGNvbnRlbnQgdXAgdG8sIGJ1dCBu
b3QgaW5jbHVkaW5nLCB0aGUgYnl0ZSBhdCB0aGlzIGluZGV4LgoKDAoFBAMCAQUSA3UCBwoM
CgUEAwIBARIDdQgRCgwKBQQDAgEDEgN1FBUKDAoFBAMCAQgSA3UWQQoPCggEAwIBCJwIABID
dRdACjQKBAQDAgISA3gCPhonIE91dHB1dCBvbmx5LiBUaGUgdGV4dCBvZiB0aGUgc2VnbWVu
dC4KCgwKBQQDAgIFEgN4AggKDAoFBAMCAgESA3gJDQoMCgUEAwICAxIDeBARCgwKBQQDAgII
EgN4Ej0KDwoIBAMCAgicCAASA3gTPApkCgIEBBIFfQCHAQEaVyBBIGNvbGxlY3Rpb24gb2Yg
c3VwcG9ydGluZyByZWZlcmVuY2VzIGZvciBhIHNlZ21lbnQgb3IgcGFydCBvZiB0aGUKIG1v
ZGVsJ3MgcmVzcG9uc2UuCgoKCgMEBAESA30IGApICgQEBAIAEgN/Aj8aOyBPcHRpb25hbC4g
U2VnbWVudCBvZiB0aGUgY29udGVudCB0aGlzIHN1cHBvcnQgYmVsb25ncyB0by4KCgwKBQQE
AgAGEgN/AgkKDAoFBAQCAAESA38KEQoMCgUEBAIAAxIDfxQVCgwKBQQEAgAIEgN/Fj4KDwoI
BAQCAAicCAASA38XPQqCAgoEBAQCARIGhQEChgEvGvEBIE9wdGlvbmFsLiBBIGxpc3Qgb2Yg
aW5kaWNlcyBpbnRvIGBncm91bmRpbmdfY2h1bmtzYCBmaWVsZCBzcGVjaWZ5aW5nIHRoZQog
Y2l0YXRpb25zIGFzc29jaWF0ZWQgd2l0aCB0aGUgY2xhaW0uIEZvciBpbnN0YW5jZSBbMSwg
M10gbWVhbnMgdGhhdAogZ3JvdW5kaW5nX2NodW5rc1sxXSBhbmQgZ3JvdW5kaW5nX2NodW5r
c1szXSBhcmUgdGhlIHJldHJpZXZlZCBjb250ZW50cwogYXR0cmlidXRlZCB0byB0aGUgY2xh
aW0uCgoNCgUEBAIBBBIEhQECCgoNCgUEBAIBBRIEhQELEAoNCgUEBAIBARIEhQERKAoNCgUE
BAIBAxIEhQErLAoNCgUEBAIBCBIEhgEGLgoQCggEBAIBCJwIABIEhgEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata ===
    # Fields for GroundingMetadata
    # Field: web_search_queries Type: 9 ()
    # Field: search_entry_point Type: 11 (.google.cloud.dialogflow.v2.SearchEntryPoint)
    # Field: grounding_chunks Type: 11 (.google.cloud.dialogflow.v2.GroundingChunk)
    # Field: grounding_supports Type: 11 (.google.cloud.dialogflow.v2.GroundingSupport)

# === Message: Google::Cloud::Dialogflow::V2::Grounding::SearchEntryPoint ===
    # Fields for SearchEntryPoint
    # Field: rendered_content Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk ===
    # Fields for GroundingChunk
    # Field: web Type: 11 (.google.cloud.dialogflow.v2.GroundingChunk.Web)
    # Field: retrieved_context Type: 11 (.google.cloud.dialogflow.v2.GroundingChunk.RetrievedContext)

# === Message: Google::Cloud::Dialogflow::V2::Grounding::Segment ===
    # Fields for Segment
    # Field: start_index Type: 5 ()
    # Field: end_index Type: 5 ()
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Grounding::GroundingSupport ===
    # Fields for GroundingSupport
    # Field: segment Type: 11 (.google.cloud.dialogflow.v2.Segment)
    # Field: grounding_chunk_indices Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Grounding - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/grounding.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Grounding;

    my $msg = Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata->new({
        web_search_queries => $web_search_queries,
        search_entry_point => $search_entry_point,
        grounding_chunks => $grounding_chunks,
        grounding_supports => $grounding_supports,
    });

    # Read or update a field
    my $val = $msg->web_search_queries();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/grounding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata

Grounding metadata contains sources, citations, and search entry points used
to ground a generated answer or suggestion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->web_search_queries() >> / C<< $msg->web_search_queries($value) >>

Type: C<String>

Optional. The web search queries that were used to generate the content.

=item * C<< $msg->search_entry_point() >> / C<< $msg->search_entry_point($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Grounding::SearchEntryPoint>)

Optional. A web search entry point that can be used to display search
results.

=item * C<< $msg->grounding_chunks() >> / C<< $msg->grounding_chunks($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk>)

Optional. A list of supporting references retrieved from the grounding
source.

=item * C<< $msg->grounding_supports() >> / C<< $msg->grounding_supports($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Grounding::GroundingSupport>)

Optional. A list of grounding supports that connect the generated
content to the grounding chunks.

=back

=head2 Google::Cloud::Dialogflow::V2::Grounding::SearchEntryPoint

A web search entry point that can be used to display search
results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rendered_content() >> / C<< $msg->rendered_content($value) >>

Type: C<String>

Optional. An HTML snippet that can be embedded in a web page or an
application's webview. This snippet displays a search result, including the
title, URL, and a brief description of the search result.

=back

=head2 Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk

A piece of evidence that supports a claim made by the model.

This is used to show a citation for a claim made by the model.
It contains a reference to the source of the information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->web() >> / C<< $msg->web($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::Web>)

Optional. A grounding chunk from a web page, typically from web
search. See the `Web` message for details.

=item * C<< $msg->retrieved_context() >> / C<< $msg->retrieved_context($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::RetrievedContext>)

Optional. A grounding chunk from a data source retrieved by a
data store tool.

=back

=head2 Google::Cloud::Dialogflow::V2::Grounding::Segment

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

=head2 Google::Cloud::Dialogflow::V2::Grounding::GroundingSupport

A collection of supporting references for a segment or part of the
model's response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->segment() >> / C<< $msg->segment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Grounding::Segment>)

Optional. Segment of the content this support belongs to.

=item * C<< $msg->grounding_chunk_indices() >> / C<< $msg->grounding_chunk_indices($value) >>

Type: C<Int32>

Optional. A list of indices into `grounding_chunks` field specifying the
citations associated with the claim. For instance [1, 3] means that
grounding_chunks[1] and grounding_chunks[3] are the retrieved contents
attributed to the claim.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Grounding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
