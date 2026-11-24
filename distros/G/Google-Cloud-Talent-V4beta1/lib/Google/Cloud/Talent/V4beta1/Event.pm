package Google::Cloud::Talent::V4beta1::Event;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvZXZlbnQucHJvdG8SG2dvb2dsZS5jbG91
ZC50YWxlbnQudjRiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byL+AQoLQ2xpZW50RXZlbnQSHQoKcmVxdWVz
dF9pZBgBIAEoCVIJcmVxdWVzdElkEh4KCGV2ZW50X2lkGAIgASgJQgPgQQJSB2V2ZW50SWQS
QAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQJS
CmNyZWF0ZVRpbWUSRAoJam9iX2V2ZW50GAUgASgLMiUuZ29vZ2xlLmNsb3VkLnRhbGVudC52
NGJldGExLkpvYkV2ZW50SABSCGpvYkV2ZW50Eh8KC2V2ZW50X25vdGVzGAkgASgJUgpldmVu
dE5vdGVzQgcKBWV2ZW50IosECghKb2JFdmVudBJLCgR0eXBlGAEgASgOMjIuZ29vZ2xlLmNs
b3VkLnRhbGVudC52NGJldGExLkpvYkV2ZW50LkpvYkV2ZW50VHlwZUID4EECUgR0eXBlEhcK
BGpvYnMYAiADKAlCA+BBAlIEam9icxIYCgdwcm9maWxlGAMgASgJUgdwcm9maWxlIv4CCgxK
b2JFdmVudFR5cGUSHgoaSk9CX0VWRU5UX1RZUEVfVU5TUEVDSUZJRUQQABIOCgpJTVBSRVNT
SU9OEAESCAoEVklFVxACEhEKDVZJRVdfUkVESVJFQ1QQAxIVChFBUFBMSUNBVElPTl9TVEFS
VBAEEhYKEkFQUExJQ0FUSU9OX0ZJTklTSBAFEiAKHEFQUExJQ0FUSU9OX1FVSUNLX1NVQk1J
U1NJT04QBhIYChRBUFBMSUNBVElPTl9SRURJUkVDVBAHEiEKHUFQUExJQ0FUSU9OX1NUQVJU
X0ZST01fU0VBUkNIEAgSJAogQVBQTElDQVRJT05fUkVESVJFQ1RfRlJPTV9TRUFSQ0gQCRIe
ChpBUFBMSUNBVElPTl9DT01QQU5ZX1NVQk1JVBAKEgwKCEJPT0tNQVJLEAsSEAoMTk9USUZJ
Q0FUSU9OEAwSCQoFSElSRUQQDRILCgdTRU5UX0NWEA4SFQoRSU5URVJWSUVXX0dSQU5URUQQ
D0JuCh9jb20uZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExQgpFdmVudFByb3RvUAFaN2Ns
b3VkLmdvb2dsZS5jb20vZ28vdGFsZW50L2FwaXY0YmV0YTEvdGFsZW50cGI7dGFsZW50cGKi
AgNDVFNKuUAKBxIFDgC7AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwApCggKAQgSAxUATgoJCgIICxIDFQBOCggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAKwoJCgIICBIDFwArCggKAQgSAxgAOAoJCgII
ARIDGAA4CggKAQgSAxkAIQoJCgIIJBIDGQAhCu4CCgIEABIEIAA6ARrhAiBBbiBldmVudCBp
c3N1ZWQgd2hlbiBhbiBlbmQgdXNlciBpbnRlcmFjdHMgd2l0aCB0aGUgYXBwbGljYXRpb24g
dGhhdAogaW1wbGVtZW50cyBDbG91ZCBUYWxlbnQgU29sdXRpb24uIFByb3ZpZGluZyB0aGlz
IGluZm9ybWF0aW9uIGltcHJvdmVzIHRoZQogcXVhbGl0eSBvZiByZXN1bHRzIGZvciB0aGUg
QVBJIGNsaWVudHMsIGVuYWJsaW5nIHRoZQogc2VydmljZSB0byBwZXJmb3JtIG9wdGltYWxs
eS4gVGhlIG51bWJlciBvZiBldmVudHMgc2VudCBtdXN0IGJlIGNvbnNpc3RlbnQKIHdpdGgg
b3RoZXIgY2FsbHMsIHN1Y2ggYXMgam9iIHNlYXJjaGVzLCBpc3N1ZWQgdG8gdGhlIHNlcnZp
Y2UgYnkgdGhlIGNsaWVudC4KCgoKAwQAARIDIAgTCt8BCgQEAAIAEgMlAhga0QEgU3Ryb25n
bHkgcmVjb21tZW5kZWQgZm9yIHRoZSBiZXN0IHNlcnZpY2UgZXhwZXJpZW5jZS4KCiBBIHVu
aXF1ZSBJRCBnZW5lcmF0ZWQgaW4gdGhlIEFQSSByZXNwb25zZXMuIEl0IGNhbiBiZSBmb3Vu
ZCBpbgogW1Jlc3BvbnNlTWV0YWRhdGEucmVxdWVzdF9pZF1bZ29vZ2xlLmNsb3VkLnRhbGVu
dC52NGJldGExLlJlc3BvbnNlTWV0YWRhdGEucmVxdWVzdF9pZF0uCgoMCgUEAAIABRIDJQII
CgwKBQQAAgABEgMlCRMKDAoFBAACAAMSAyUWFwpSCgQEAAIBEgMoAj8aRSBSZXF1aXJlZC4g
QSB1bmlxdWUgaWRlbnRpZmllciwgZ2VuZXJhdGVkIGJ5IHRoZSBjbGllbnQgYXBwbGljYXRp
b24uCgoMCgUEAAIBBRIDKAIICgwKBQQAAgEBEgMoCREKDAoFBAACAQMSAygUFQoMCgUEAAIB
CBIDKBY+Cg8KCAQAAgEInAgAEgMoFz0KNQoEBAACAhIEKwIsLxonIFJlcXVpcmVkLiBUaGUg
dGltZXN0YW1wIG9mIHRoZSBldmVudC4KCgwKBQQAAgIGEgMrAhsKDAoFBAACAgESAyscJwoM
CgUEAAICAxIDKyorCgwKBQQAAgIIEgMsBi4KDwoIBAACAgicCAASAywHLQpMCgQEAAgAEgQx
AjUDGj4gUmVxdWlyZWQuCgogVGhlIGRldGFpbCBpbmZvcm1hdGlvbiBvZiBhIHNwZWNpZmlj
IGV2ZW50IHR5cGUuCgoMCgUEAAgAARIDMQgNCncKBAQAAgMSAzQEGxpqIEFuIGV2ZW50IGlz
c3VlZCB3aGVuIGEgam9iIHNlZWtlciBpbnRlcmFjdHMgd2l0aCB0aGUgYXBwbGljYXRpb24g
dGhhdAogaW1wbGVtZW50cyBDbG91ZCBUYWxlbnQgU29sdXRpb24uCgoMCgUEAAIDBhIDNAQM
CgwKBQQAAgMBEgM0DRYKDAoFBAACAwMSAzQZGgqDAQoEBAACBBIDOQIZGnYgTm90ZXMgYWJv
dXQgdGhlIGV2ZW50IHByb3ZpZGVkIGJ5IHJlY3J1aXRlcnMgb3Igb3RoZXIgdXNlcnMsIGZv
ciBleGFtcGxlLAogZmVlZGJhY2sgb24gd2h5IGEgcHJvZmlsZSB3YXMgYm9va21hcmtlZC4K
CgwKBQQAAgQFEgM5AggKDAoFBAACBAESAzkJFAoMCgUEAAIEAxIDORcYCncKAgQBEgU+ALsB
ARpqIEFuIGV2ZW50IGlzc3VlZCB3aGVuIGEgam9iIHNlZWtlciBpbnRlcmFjdHMgd2l0aCB0
aGUgYXBwbGljYXRpb24gdGhhdAogaW1wbGVtZW50cyBDbG91ZCBUYWxlbnQgU29sdXRpb24u
CgoKCgMEAQESAz4IEApuCgQEAQQAEgVBAqEBAxpfIEFuIGVudW1lcmF0aW9uIG9mIGFuIGV2
ZW50IGF0dHJpYnV0ZWQgdG8gdGhlIGJlaGF2aW9yIG9mIHRoZSBlbmQgdXNlciwKIHN1Y2gg
YXMgYSBqb2Igc2Vla2VyLgoKDAoFBAEEAAESA0EHEwpDCgYEAQQAAgASA0MEIxo0IFRoZSBl
dmVudCBpcyB1bnNwZWNpZmllZCBieSBvdGhlciBwcm92aWRlZCB2YWx1ZXMuCgoOCgcEAQQA
AgABEgNDBB4KDgoHBAEEAAIAAhIDQyEiCqICCgYEAQQAAgESA0kEExqSAiBUaGUgam9iIHNl
ZWtlciBvciBvdGhlciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUgc2VydmljZSBoYXMK
IGhhZCBhIGpvYiByZW5kZXJlZCBpbiB0aGVpciB2aWV3LCBzdWNoIGFzIGluIGEgbGlzdCBv
ZiBzZWFyY2ggcmVzdWx0cyBpbgogYSBjb21wcmVzc2VkIG9yIGNsaXBwZWQgZm9ybWF0LiBU
aGlzIGV2ZW50IGlzIHR5cGljYWxseSBhc3NvY2lhdGVkIHdpdGgKIHRoZSB2aWV3aW5nIG9m
IGEgam9icyBsaXN0IG9uIGEgc2luZ2xlIHBhZ2UgYnkgYSBqb2Igc2Vla2VyLgoKDgoHBAEE
AAIBARIDSQQOCg4KBwQBBAACAQISA0kREgrzAgoGBAEEAAICEgNQBA0a4wIgVGhlIGpvYiBz
ZWVrZXIsIG9yIG90aGVyIGVudGl0eSBpbnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlLCBo
YXMKIHZpZXdlZCB0aGUgZGV0YWlscyBvZiBhIGpvYiwgaW5jbHVkaW5nIHRoZSBmdWxsIGRl
c2NyaXB0aW9uLiBUaGlzCiBldmVudCBkb2Vzbid0IGFwcGx5IHRvIHRoZSB2aWV3aW5nIGEg
c25pcHBldCBvZiBhIGpvYiBhcHBlYXJpbmcgYXMgYQogcGFydCBvZiB0aGUgam9iIHNlYXJj
aCByZXN1bHRzLiBWaWV3aW5nIGEgc25pcHBldCBpcyBhc3NvY2lhdGVkIHdpdGggYW4KIFtp
bXByZXNzaW9uXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iRXZlbnQuSm9iRXZl
bnRUeXBlLklNUFJFU1NJT05dKS4KCg4KBwQBBAACAgESA1AECAoOCgcEAQQAAgICEgNQCwwK
pAEKBgQBBAACAxIDVQQWGpQBIFRoZSBqb2Igc2Vla2VyIG9yIG90aGVyIGVudGl0eSBpbnRl
cmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlCiBwZXJmb3JtZWQgYW4gYWN0aW9uIHRvIHZpZXcg
YSBqb2IgYW5kIHdhcyByZWRpcmVjdGVkIHRvIGEgZGlmZmVyZW50CiB3ZWJzaXRlIGZvciBq
b2IuCgoOCgcEAQQAAgMBEgNVBBEKDgoHBAEEAAIDAhIDVRQVCpUBCgYEAQQAAgQSA1kEGhqF
ASBUaGUgam9iIHNlZWtlciBvciBvdGhlciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUg
c2VydmljZQogYmVnYW4gdGhlIHByb2Nlc3Mgb3IgZGVtb25zdHJhdGVkIHRoZSBpbnRlbnRp
b24gb2YgYXBwbHlpbmcgZm9yIGEgam9iLgoKDgoHBAEEAAIEARIDWQQVCg4KBwQBBAACBAIS
A1kYGQpxCgYEAQQAAgUSA10EGxpiIFRoZSBqb2Igc2Vla2VyIG9yIG90aGVyIGVudGl0eSBp
bnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlCiBzdWJtaXR0ZWQgYW4gYXBwbGljYXRpb24g
Zm9yIGEgam9iLgoKDgoHBAEEAAIFARIDXQQWCg4KBwQBBAACBQISA10ZGgreAwoGBAEEAAIG
EgNnBCUazgMgVGhlIGpvYiBzZWVrZXIgb3Igb3RoZXIgZW50aXR5IGludGVyYWN0aW5nIHdp
dGggdGhlIHNlcnZpY2UKIHN1Ym1pdHRlZCBhbiBhcHBsaWNhdGlvbiBmb3IgYSBqb2Igd2l0
aCBhIHNpbmdsZSBjbGljayB3aXRob3V0CiBlbnRlcmluZyBpbmZvcm1hdGlvbi4gSWYgYSBq
b2Igc2Vla2VyIHBlcmZvcm1zIHRoaXMgYWN0aW9uLCBzZW5kIG9ubHkKIHRoaXMgZXZlbnQg
dG8gdGhlIHNlcnZpY2UuIERvIG5vdCBhbHNvIHNlbmQKIFtKb2JFdmVudFR5cGUuQVBQTElD
QVRJT05fU1RBUlRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2JFdmVudC5Kb2JF
dmVudFR5cGUuQVBQTElDQVRJT05fU1RBUlRdCiBvcgogW0pvYkV2ZW50VHlwZS5BUFBMSUNB
VElPTl9GSU5JU0hdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2JFdmVudC5Kb2JF
dmVudFR5cGUuQVBQTElDQVRJT05fRklOSVNIXQogZXZlbnRzLgoKDgoHBAEEAAIGARIDZwQg
Cg4KBwQBBAACBgISA2cjJAq8AQoGBAEEAAIHEgNsBB0arAEgVGhlIGpvYiBzZWVrZXIgb3Ig
b3RoZXIgZW50aXR5IGludGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2UKIHBlcmZvcm1lZCBh
biBhY3Rpb24gdG8gYXBwbHkgdG8gYSBqb2IgYW5kIHdhcyByZWRpcmVjdGVkIHRvIGEgZGlm
ZmVyZW50CiB3ZWJzaXRlIHRvIGNvbXBsZXRlIHRoZSBhcHBsaWNhdGlvbi4KCg4KBwQBBAAC
BwESA2wEGAoOCgcEAQQAAgcCEgNsGxwKpQIKBgQBBAACCBIDcgQmGpUCIFRoZSBqb2Igc2Vl
a2VyIG9yIG90aGVyIGVudGl0eSBpbnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlIGJlZ2Fu
IHRoZQogcHJvY2VzcyBvciBkZW1vbnN0cmF0ZWQgdGhlIGludGVudGlvbiBvZiBhcHBseWlu
ZyBmb3IgYSBqb2IgZnJvbSB0aGUKIHNlYXJjaCByZXN1bHRzIHBhZ2Ugd2l0aG91dCB2aWV3
aW5nIHRoZSBkZXRhaWxzIG9mIHRoZSBqb2IgcG9zdGluZy4KIElmIHNlbmRpbmcgdGhpcyBl
dmVudCwgSm9iRXZlbnRUeXBlLlZJRVcgZXZlbnQgc2hvdWxkbid0IGJlIHNlbnQuCgoOCgcE
AQQAAggBEgNyBCEKDgoHBAEEAAIIAhIDciQlCqgFCgYEAQQAAgkSA38EKRqYBSBUaGUgam9i
IHNlZWtlciwgb3Igb3RoZXIgZW50aXR5IGludGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2Us
IHBlcmZvcm1zIGFuCiBhY3Rpb24gd2l0aCBhIHNpbmdsZSBjbGljayBmcm9tIHRoZSBzZWFy
Y2ggcmVzdWx0cyBwYWdlIHRvIGFwcGx5IHRvIGEgam9iCiAod2l0aG91dCB2aWV3aW5nIHRo
ZSBkZXRhaWxzIG9mIHRoZSBqb2IgcG9zdGluZyksIGFuZCBpcyByZWRpcmVjdGVkCiB0byBh
IGRpZmZlcmVudCB3ZWJzaXRlIHRvIGNvbXBsZXRlIHRoZSBhcHBsaWNhdGlvbi4gSWYgYSBj
YW5kaWRhdGUKIHBlcmZvcm1zIHRoaXMgYWN0aW9uLCBzZW5kIG9ubHkgdGhpcyBldmVudCB0
byB0aGUgc2VydmljZS4gRG8gbm90IGFsc28KIHNlbmQKIFtKb2JFdmVudFR5cGUuQVBQTElD
QVRJT05fU1RBUlRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2JFdmVudC5Kb2JF
dmVudFR5cGUuQVBQTElDQVRJT05fU1RBUlRdLAogW0pvYkV2ZW50VHlwZS5BUFBMSUNBVElP
Tl9GSU5JU0hdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2JFdmVudC5Kb2JFdmVu
dFR5cGUuQVBQTElDQVRJT05fRklOSVNIXQogb3IKIFtKb2JFdmVudFR5cGUuVklFV11bZ29v
Z2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYkV2ZW50LkpvYkV2ZW50VHlwZS5WSUVXXQog
ZXZlbnRzLgoKDgoHBAEEAAIJARIDfwQkCg4KBwQBBAACCQISA38nKArDAQoGBAEEAAIKEgSE
AQQkGrIBIFRoaXMgZXZlbnQgc2hvdWxkIGJlIHVzZWQgd2hlbiBhIGNvbXBhbnkgc3VibWl0
cyBhbiBhcHBsaWNhdGlvbgogb24gYmVoYWxmIG9mIGEgam9iIHNlZWtlci4gVGhpcyBldmVu
dCBpcyBpbnRlbmRlZCBmb3IgdXNlIGJ5IHN0YWZmaW5nCiBhZ2VuY2llcyBhdHRlbXB0aW5n
IHRvIHBsYWNlIGNhbmRpZGF0ZXMuCgoPCgcEAQQAAgoBEgSEAQQeCg8KBwQBBAACCgISBIQB
ISMKjQEKBgQBBAACCxIEiAEEEhp9IFRoZSBqb2Igc2Vla2VyIG9yIG90aGVyIGVudGl0eSBp
bnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlIGRlbW9uc3RyYXRlZAogYW4gaW50ZXJlc3Qg
aW4gYSBqb2IgYnkgYm9va21hcmtpbmcgb3Igc2F2aW5nIGl0LgoKDwoHBAEEAAILARIEiAEE
DAoPCgcEAQQAAgsCEgSIAQ8RCtcBCgYEAQQAAgwSBI0BBBYaxgEgVGhlIGpvYiBzZWVrZXIg
b3Igb3RoZXIgZW50aXR5IGludGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2Ugd2FzCiBzZW50
IGEgbm90aWZpY2F0aW9uLCBzdWNoIGFzIGFuIGVtYWlsIGFsZXJ0IG9yIGRldmljZSBub3Rp
ZmljYXRpb24sCiBjb250YWluaW5nIG9uZSBvciBtb3JlIGpvYnMgbGlzdGluZ3MgZ2VuZXJh
dGVkIGJ5IHRoZSBzZXJ2aWNlLgoKDwoHBAEEAAIMARIEjQEEEAoPCgcEAQQAAgwCEgSNARMV
CpwCCgYEAQQAAg0SBJQBBA8aiwIgVGhlIGpvYiBzZWVrZXIgb3Igb3RoZXIgZW50aXR5IGlu
dGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2Ugd2FzCiBlbXBsb3llZCBieSB0aGUgaGlyaW5n
IGVudGl0eSAoZW1wbG95ZXIpLiBTZW5kIHRoaXMgZXZlbnQKIG9ubHkgaWYgdGhlIGpvYiBz
ZWVrZXIgd2FzIGhpcmVkIHRocm91Z2ggYW4gYXBwbGljYXRpb24gdGhhdCB3YXMKIGluaXRp
YXRlZCBieSBhIHNlYXJjaCBjb25kdWN0ZWQgdGhyb3VnaCB0aGUgQ2xvdWQgVGFsZW50IFNv
bHV0aW9uCiBzZXJ2aWNlLgoKDwoHBAEEAAINARIElAEECQoPCgcEAQQAAg0CEgSUAQwOCq4B
CgYEAQQAAg4SBJkBBBEanQEgQSByZWNydWl0ZXIgb3Igc3RhZmZpbmcgYWdlbmN5IHN1Ym1p
dHRlZCBhbiBhcHBsaWNhdGlvbiBvbiBiZWhhbGYgb2YgdGhlCiBjYW5kaWRhdGUgYWZ0ZXIg
aW50ZXJhY3Rpbmcgd2l0aCB0aGUgc2VydmljZSB0byBpZGVudGlmeSBhIHN1aXRhYmxlIGpv
YgogcG9zdGluZy4KCg8KBwQBBAACDgESBJkBBAsKDwoHBAEEAAIOAhIEmQEOEAr0AgoGBAEE
AAIPEgSgAQQbGuMCIFRoZSBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUgc2VydmljZSAo
Zm9yIGV4YW1wbGUsIHRoZSBqb2Igc2Vla2VyKSwKIHdhcyBncmFudGVkIGFuIGluaXRpYWwg
aW50ZXJ2aWV3IGJ5IHRoZSBoaXJpbmcgZW50aXR5IChlbXBsb3llcikuIFRoaXMKIGV2ZW50
IHNob3VsZCBvbmx5IGJlIHNlbnQgaWYgdGhlIGpvYiBzZWVrZXIgd2FzIGdyYW50ZWQgYW4g
aW50ZXJ2aWV3IGFzCiBwYXJ0IG9mIGFuIGFwcGxpY2F0aW9uIHRoYXQgd2FzIGluaXRpYXRl
ZCBieSBhIHNlYXJjaCBjb25kdWN0ZWQgdGhyb3VnaCAvCiByZWNvbW1lbmRhdGlvbiBwcm92
aWRlZCBieSB0aGUgQ2xvdWQgVGFsZW50IFNvbHV0aW9uIHNlcnZpY2UuCgoPCgcEAQQAAg8B
EgSgAQQVCg8KBwQBBAACDwISBKABGBoKeQoEBAECABIEpQECQRprIFJlcXVpcmVkLiBUaGUg
dHlwZSBvZiB0aGUgZXZlbnQgKHNlZQogW0pvYkV2ZW50VHlwZV1bZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkpvYkV2ZW50LkpvYkV2ZW50VHlwZV0pLgoKDQoFBAECAAYSBKUBAg4K
DQoFBAECAAESBKUBDxMKDQoFBAECAAMSBKUBFhcKDQoFBAECAAgSBKUBGEAKEAoIBAECAAic
CAASBKUBGT8KswQKBAQBAgESBLIBAkQapAQgUmVxdWlyZWQuIFRoZSBbam9iIG5hbWUocyld
W2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2IubmFtZV0KIGFzc29jaWF0ZWQgd2l0
aCB0aGlzIGV2ZW50LiBGb3IgZXhhbXBsZSwgaWYgdGhpcyBpcyBhbgogW2ltcHJlc3Npb25d
W2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2JFdmVudC5Kb2JFdmVudFR5cGUuSU1Q
UkVTU0lPTl0KIGV2ZW50LCB0aGlzIGZpZWxkIGNvbnRhaW5zIHRoZSBpZGVudGlmaWVycyBv
ZiBhbGwgam9icyBzaG93biB0byB0aGUgam9iCiBzZWVrZXIuIElmIHRoaXMgd2FzIGEKIFt2
aWV3XVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iRXZlbnQuSm9iRXZlbnRUeXBl
LlZJRVddIGV2ZW50LCB0aGlzCiBmaWVsZCBjb250YWlucyB0aGUgaWRlbnRpZmllciBvZiB0
aGUgdmlld2VkIGpvYi4KCiBUaGUgZm9ybWF0IGlzCiAicHJvamVjdHMve3Byb2plY3RfaWR9
L3RlbmFudHMve3RlbmFudF9pZH0vam9icy97am9iX2lkfSIsIGZvcgogZXhhbXBsZSwgInBy
b2plY3RzL2Zvby90ZW5hbnRzL2Jhci9qb2JzL2JheiIuCgoNCgUEAQIBBBIEsgECCgoNCgUE
AQIBBRIEsgELEQoNCgUEAQIBARIEsgESFgoNCgUEAQIBAxIEsgEZGgoNCgUEAQIBCBIEsgEb
QwoQCggEAQIBCJwIABIEsgEcQgr8AQoEBAECAhIEugECFRrtASBUaGUgW3Byb2ZpbGUgbmFt
ZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLlByb2ZpbGUubmFtZV0gYXNzb2NpYXRl
ZAogd2l0aCB0aGlzIGNsaWVudCBldmVudC4KCiBUaGUgZm9ybWF0IGlzCiAicHJvamVjdHMv
e3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFudF9pZH0vcHJvZmlsZXMve3Byb2ZpbGVfaWR9
IiwKIGZvciBleGFtcGxlLCAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFyL3Byb2ZpbGVzL2Jh
eiIuCgoNCgUEAQICBRIEugECCAoNCgUEAQICARIEugEJEAoNCgUEAQICAxIEugETFGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::Event::ClientEvent ===
    # Fields for ClientEvent
    # Field: request_id Type: 9 ()
    # Field: event_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: job_event Type: 11 (.google.cloud.talent.v4beta1.JobEvent)
    # Field: event_notes Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::Event::JobEvent ===
    # Fields for JobEvent
    # Field: type Type: 14 (.google.cloud.talent.v4beta1.JobEvent.JobEventType)
    # Field: jobs Type: 9 ()
    # Field: profile Type: 9 ()

# Enum: JobEvent::JobEventType
our $JobEvent_JOB_EVENT_TYPE_UNSPECIFIED = 0;
our $JobEvent_IMPRESSION = 1;
our $JobEvent_VIEW = 2;
our $JobEvent_VIEW_REDIRECT = 3;
our $JobEvent_APPLICATION_START = 4;
our $JobEvent_APPLICATION_FINISH = 5;
our $JobEvent_APPLICATION_QUICK_SUBMISSION = 6;
our $JobEvent_APPLICATION_REDIRECT = 7;
our $JobEvent_APPLICATION_START_FROM_SEARCH = 8;
our $JobEvent_APPLICATION_REDIRECT_FROM_SEARCH = 9;
our $JobEvent_APPLICATION_COMPANY_SUBMIT = 10;
our $JobEvent_BOOKMARK = 11;
our $JobEvent_NOTIFICATION = 12;
our $JobEvent_HIRED = 13;
our $JobEvent_SENT_CV = 14;
our $JobEvent_INTERVIEW_GRANTED = 15;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::Event - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/event.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::Event;

    my $msg = Google::Cloud::Talent::V4beta1::Event::ClientEvent->new({
        request_id => $request_id,
        event_id => $event_id,
        create_time => $create_time,
        job_event => $job_event,
    });

    # Read or update a field
    my $val = $msg->request_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::Event::ClientEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::Event::ClientEvent

An event issued when an end user interacts with the application that
implements Cloud Talent Solution. Providing this information improves the
quality of results for the API clients, enabling the
service to perform optimally. The number of events sent must be consistent
with other calls, such as job searches, issued to the service by the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Strongly recommended for the best service experience.

A unique ID generated in the API responses. It can be found in
[ResponseMetadata.request_id][google.cloud.talent.v4beta1.ResponseMetadata.request_id].

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

Required. A unique identifier, generated by the client application.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The timestamp of the event.

=item * C<< $msg->job_event() >> / C<< $msg->job_event($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Event::JobEvent>)

An event issued when a job seeker interacts with the application that
implements Cloud Talent Solution.

=item * C<< $msg->event_notes() >> / C<< $msg->event_notes($value) >>

Type: C<String>

Notes about the event provided by recruiters or other users, for example,
feedback on why a profile was bookmarked.

=back

=head2 Google::Cloud::Talent::V4beta1::Event::JobEvent

An event issued when a job seeker interacts with the application that
implements Cloud Talent Solution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::JobEvent::JobEventType>)

Required. The type of the event (see
[JobEventType][google.cloud.talent.v4beta1.JobEvent.JobEventType]).

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<String>

Required. The [job name(s)][google.cloud.talent.v4beta1.Job.name]
associated with this event. For example, if this is an
[impression][google.cloud.talent.v4beta1.JobEvent.JobEventType.IMPRESSION]
event, this field contains the identifiers of all jobs shown to the job
seeker. If this was a
[view][google.cloud.talent.v4beta1.JobEvent.JobEventType.VIEW] event, this
field contains the identifier of the viewed job.

The format is
"projects/{project_id}/tenants/{tenant_id}/jobs/{job_id}", for
example, "projects/foo/tenants/bar/jobs/baz".

=item * C<< $msg->profile() >> / C<< $msg->profile($value) >>

Type: C<String>

The [profile name][google.cloud.talent.v4beta1.Profile.name] associated
with this client event.

The format is
"projects/{project_id}/tenants/{tenant_id}/profiles/{profile_id}",
for example, "projects/foo/tenants/bar/profiles/baz".

=back

=head3 Enum: JobEvent::JobEventType

=over 4

=item * C<JOB_EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<IMPRESSION> => C<1>

=item * C<VIEW> => C<2>

=item * C<VIEW_REDIRECT> => C<3>

=item * C<APPLICATION_START> => C<4>

=item * C<APPLICATION_FINISH> => C<5>

=item * C<APPLICATION_QUICK_SUBMISSION> => C<6>

=item * C<APPLICATION_REDIRECT> => C<7>

=item * C<APPLICATION_START_FROM_SEARCH> => C<8>

=item * C<APPLICATION_REDIRECT_FROM_SEARCH> => C<9>

=item * C<APPLICATION_COMPANY_SUBMIT> => C<10>

=item * C<BOOKMARK> => C<11>

=item * C<NOTIFICATION> => C<12>

=item * C<HIRED> => C<13>

=item * C<SENT_CV> => C<14>

=item * C<INTERVIEW_GRANTED> => C<15>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::Event::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
