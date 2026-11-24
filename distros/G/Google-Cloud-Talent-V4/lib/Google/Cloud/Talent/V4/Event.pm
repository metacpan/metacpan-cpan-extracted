package Google::Cloud::Talent::V4::Event;

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
CiJnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2V2ZW50LnByb3RvEhZnb29nbGUuY2xvdWQudGFs
ZW50LnY0Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIvkBCgtDbGllbnRFdmVudBIdCgpyZXF1ZXN0X2lkGAEgASgJ
UglyZXF1ZXN0SWQSHgoIZXZlbnRfaWQYAiABKAlCA+BBAlIHZXZlbnRJZBJACgtjcmVhdGVf
dGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIKY3JlYXRlVGlt
ZRI/Cglqb2JfZXZlbnQYBSABKAsyIC5nb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYkV2ZW50
SABSCGpvYkV2ZW50Eh8KC2V2ZW50X25vdGVzGAkgASgJUgpldmVudE5vdGVzQgcKBWV2ZW50
IuwDCghKb2JFdmVudBJGCgR0eXBlGAEgASgOMi0uZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5K
b2JFdmVudC5Kb2JFdmVudFR5cGVCA+BBAlIEdHlwZRIXCgRqb2JzGAIgAygJQgPgQQJSBGpv
YnMi/gIKDEpvYkV2ZW50VHlwZRIeChpKT0JfRVZFTlRfVFlQRV9VTlNQRUNJRklFRBAAEg4K
CklNUFJFU1NJT04QARIICgRWSUVXEAISEQoNVklFV19SRURJUkVDVBADEhUKEUFQUExJQ0FU
SU9OX1NUQVJUEAQSFgoSQVBQTElDQVRJT05fRklOSVNIEAUSIAocQVBQTElDQVRJT05fUVVJ
Q0tfU1VCTUlTU0lPThAGEhgKFEFQUExJQ0FUSU9OX1JFRElSRUNUEAcSIQodQVBQTElDQVRJ
T05fU1RBUlRfRlJPTV9TRUFSQ0gQCBIkCiBBUFBMSUNBVElPTl9SRURJUkVDVF9GUk9NX1NF
QVJDSBAJEh4KGkFQUExJQ0FUSU9OX0NPTVBBTllfU1VCTUlUEAoSDAoIQk9PS01BUksQCxIQ
CgxOT1RJRklDQVRJT04QDBIJCgVISVJFRBANEgsKB1NFTlRfQ1YQDhIVChFJTlRFUlZJRVdf
R1JBTlRFRBAPQmQKGmNvbS5nb29nbGUuY2xvdWQudGFsZW50LnY0QgpFdmVudFByb3RvUAFa
MmNsb3VkLmdvb2dsZS5jb20vZ28vdGFsZW50L2FwaXY0L3RhbGVudHBiO3RhbGVudHBiogID
Q1RTStA9CgcSBQ4AsgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEI
EgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACsKCQoCCAgSAxcAKwoICgEIEgMYADMKCQoCCAES
AxgAMwoICgEIEgMZACEKCQoCCCQSAxkAIQruAgoCBAASBCAAOgEa4QIgQW4gZXZlbnQgaXNz
dWVkIHdoZW4gYW4gZW5kIHVzZXIgaW50ZXJhY3RzIHdpdGggdGhlIGFwcGxpY2F0aW9uIHRo
YXQKIGltcGxlbWVudHMgQ2xvdWQgVGFsZW50IFNvbHV0aW9uLiBQcm92aWRpbmcgdGhpcyBp
bmZvcm1hdGlvbiBpbXByb3ZlcyB0aGUKIHF1YWxpdHkgb2YgcmVzdWx0cyBmb3IgdGhlIEFQ
SSBjbGllbnRzLCBlbmFibGluZyB0aGUKIHNlcnZpY2UgdG8gcGVyZm9ybSBvcHRpbWFsbHku
IFRoZSBudW1iZXIgb2YgZXZlbnRzIHNlbnQgbXVzdCBiZSBjb25zaXN0ZW50CiB3aXRoIG90
aGVyIGNhbGxzLCBzdWNoIGFzIGpvYiBzZWFyY2hlcywgaXNzdWVkIHRvIHRoZSBzZXJ2aWNl
IGJ5IHRoZSBjbGllbnQuCgoKCgMEAAESAyAIEwraAQoEBAACABIDJQIYGswBIFN0cm9uZ2x5
IHJlY29tbWVuZGVkIGZvciB0aGUgYmVzdCBzZXJ2aWNlIGV4cGVyaWVuY2UuCgogQSB1bmlx
dWUgSUQgZ2VuZXJhdGVkIGluIHRoZSBBUEkgcmVzcG9uc2VzLiBJdCBjYW4gYmUgZm91bmQg
aW4KIFtSZXNwb25zZU1ldGFkYXRhLnJlcXVlc3RfaWRdW2dvb2dsZS5jbG91ZC50YWxlbnQu
djQuUmVzcG9uc2VNZXRhZGF0YS5yZXF1ZXN0X2lkXS4KCgwKBQQAAgAFEgMlAggKDAoFBAAC
AAESAyUJEwoMCgUEAAIAAxIDJRYXClIKBAQAAgESAygCPxpFIFJlcXVpcmVkLiBBIHVuaXF1
ZSBpZGVudGlmaWVyLCBnZW5lcmF0ZWQgYnkgdGhlIGNsaWVudCBhcHBsaWNhdGlvbi4KCgwK
BQQAAgEFEgMoAggKDAoFBAACAQESAygJEQoMCgUEAAIBAxIDKBQVCgwKBQQAAgEIEgMoFj4K
DwoIBAACAQicCAASAygXPQo1CgQEAAICEgQrAiwvGicgUmVxdWlyZWQuIFRoZSB0aW1lc3Rh
bXAgb2YgdGhlIGV2ZW50LgoKDAoFBAACAgYSAysCGwoMCgUEAAICARIDKxwnCgwKBQQAAgID
EgMrKisKDAoFBAACAggSAywGLgoPCggEAAICCJwIABIDLActCkwKBAQACAASBDECNQMaPiBS
ZXF1aXJlZC4KCiBUaGUgZGV0YWlsIGluZm9ybWF0aW9uIG9mIGEgc3BlY2lmaWMgZXZlbnQg
dHlwZS4KCgwKBQQACAABEgMxCA0KdwoEBAACAxIDNAQbGmogQW4gZXZlbnQgaXNzdWVkIHdo
ZW4gYSBqb2Igc2Vla2VyIGludGVyYWN0cyB3aXRoIHRoZSBhcHBsaWNhdGlvbiB0aGF0CiBp
bXBsZW1lbnRzIENsb3VkIFRhbGVudCBTb2x1dGlvbi4KCgwKBQQAAgMGEgM0BAwKDAoFBAAC
AwESAzQNFgoMCgUEAAIDAxIDNBkaCn8KBAQAAgQSAzkCGRpyIE5vdGVzIGFib3V0IHRoZSBl
dmVudCBwcm92aWRlZCBieSByZWNydWl0ZXJzIG9yIG90aGVyIHVzZXJzLCBmb3IgZXhhbXBs
ZSwKIGZlZWRiYWNrIG9uIHdoeSBhIGpvYiB3YXMgYm9va21hcmtlZC4KCgwKBQQAAgQFEgM5
AggKDAoFBAACBAESAzkJFAoMCgUEAAIEAxIDORcYCncKAgQBEgU+ALIBARpqIEFuIGV2ZW50
IGlzc3VlZCB3aGVuIGEgam9iIHNlZWtlciBpbnRlcmFjdHMgd2l0aCB0aGUgYXBwbGljYXRp
b24gdGhhdAogaW1wbGVtZW50cyBDbG91ZCBUYWxlbnQgU29sdXRpb24uCgoKCgMEAQESAz4I
EApuCgQEAQQAEgVBAqABAxpfIEFuIGVudW1lcmF0aW9uIG9mIGFuIGV2ZW50IGF0dHJpYnV0
ZWQgdG8gdGhlIGJlaGF2aW9yIG9mIHRoZSBlbmQgdXNlciwKIHN1Y2ggYXMgYSBqb2Igc2Vl
a2VyLgoKDAoFBAEEAAESA0EHEwpDCgYEAQQAAgASA0MEIxo0IFRoZSBldmVudCBpcyB1bnNw
ZWNpZmllZCBieSBvdGhlciBwcm92aWRlZCB2YWx1ZXMuCgoOCgcEAQQAAgABEgNDBB4KDgoH
BAEEAAIAAhIDQyEiCqICCgYEAQQAAgESA0kEExqSAiBUaGUgam9iIHNlZWtlciBvciBvdGhl
ciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUgc2VydmljZSBoYXMKIGhhZCBhIGpvYiBy
ZW5kZXJlZCBpbiB0aGVpciB2aWV3LCBzdWNoIGFzIGluIGEgbGlzdCBvZiBzZWFyY2ggcmVz
dWx0cyBpbgogYSBjb21wcmVzc2VkIG9yIGNsaXBwZWQgZm9ybWF0LiBUaGlzIGV2ZW50IGlz
IHR5cGljYWxseSBhc3NvY2lhdGVkIHdpdGgKIHRoZSB2aWV3aW5nIG9mIGEgam9icyBsaXN0
IG9uIGEgc2luZ2xlIHBhZ2UgYnkgYSBqb2Igc2Vla2VyLgoKDgoHBAEEAAIBARIDSQQOCg4K
BwQBBAACAQISA0kREgruAgoGBAEEAAICEgNQBA0a3gIgVGhlIGpvYiBzZWVrZXIsIG9yIG90
aGVyIGVudGl0eSBpbnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlLCBoYXMKIHZpZXdlZCB0
aGUgZGV0YWlscyBvZiBhIGpvYiwgaW5jbHVkaW5nIHRoZSBmdWxsIGRlc2NyaXB0aW9uLiBU
aGlzCiBldmVudCBkb2Vzbid0IGFwcGx5IHRvIHRoZSB2aWV3aW5nIGEgc25pcHBldCBvZiBh
IGpvYiBhcHBlYXJpbmcgYXMgYQogcGFydCBvZiB0aGUgam9iIHNlYXJjaCByZXN1bHRzLiBW
aWV3aW5nIGEgc25pcHBldCBpcyBhc3NvY2lhdGVkIHdpdGggYW4KIFtpbXByZXNzaW9uXVtn
b29nbGUuY2xvdWQudGFsZW50LnY0LkpvYkV2ZW50LkpvYkV2ZW50VHlwZS5JTVBSRVNTSU9O
XSkuCgoOCgcEAQQAAgIBEgNQBAgKDgoHBAEEAAICAhIDUAsMCqQBCgYEAQQAAgMSA1UEFhqU
ASBUaGUgam9iIHNlZWtlciBvciBvdGhlciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUg
c2VydmljZQogcGVyZm9ybWVkIGFuIGFjdGlvbiB0byB2aWV3IGEgam9iIGFuZCB3YXMgcmVk
aXJlY3RlZCB0byBhIGRpZmZlcmVudAogd2Vic2l0ZSBmb3Igam9iLgoKDgoHBAEEAAIDARID
VQQRCg4KBwQBBAACAwISA1UUFQqVAQoGBAEEAAIEEgNZBBoahQEgVGhlIGpvYiBzZWVrZXIg
b3Igb3RoZXIgZW50aXR5IGludGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2UKIGJlZ2FuIHRo
ZSBwcm9jZXNzIG9yIGRlbW9uc3RyYXRlZCB0aGUgaW50ZW50aW9uIG9mIGFwcGx5aW5nIGZv
ciBhIGpvYi4KCg4KBwQBBAACBAESA1kEFQoOCgcEAQQAAgQCEgNZGBkKcQoGBAEEAAIFEgNd
BBsaYiBUaGUgam9iIHNlZWtlciBvciBvdGhlciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0
aGUgc2VydmljZQogc3VibWl0dGVkIGFuIGFwcGxpY2F0aW9uIGZvciBhIGpvYi4KCg4KBwQB
BAACBQESA10EFgoOCgcEAQQAAgUCEgNdGRoK1AMKBgQBBAACBhIDZwQlGsQDIFRoZSBqb2Ig
c2Vla2VyIG9yIG90aGVyIGVudGl0eSBpbnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlCiBz
dWJtaXR0ZWQgYW4gYXBwbGljYXRpb24gZm9yIGEgam9iIHdpdGggYSBzaW5nbGUgY2xpY2sg
d2l0aG91dAogZW50ZXJpbmcgaW5mb3JtYXRpb24uIElmIGEgam9iIHNlZWtlciBwZXJmb3Jt
cyB0aGlzIGFjdGlvbiwgc2VuZCBvbmx5CiB0aGlzIGV2ZW50IHRvIHRoZSBzZXJ2aWNlLiBE
byBub3QgYWxzbyBzZW5kCiBbSm9iRXZlbnRUeXBlLkFQUExJQ0FUSU9OX1NUQVJUXVtnb29n
bGUuY2xvdWQudGFsZW50LnY0LkpvYkV2ZW50LkpvYkV2ZW50VHlwZS5BUFBMSUNBVElPTl9T
VEFSVF0KIG9yCiBbSm9iRXZlbnRUeXBlLkFQUExJQ0FUSU9OX0ZJTklTSF1bZ29vZ2xlLmNs
b3VkLnRhbGVudC52NC5Kb2JFdmVudC5Kb2JFdmVudFR5cGUuQVBQTElDQVRJT05fRklOSVNI
XQogZXZlbnRzLgoKDgoHBAEEAAIGARIDZwQgCg4KBwQBBAACBgISA2cjJAq8AQoGBAEEAAIH
EgNsBB0arAEgVGhlIGpvYiBzZWVrZXIgb3Igb3RoZXIgZW50aXR5IGludGVyYWN0aW5nIHdp
dGggdGhlIHNlcnZpY2UKIHBlcmZvcm1lZCBhbiBhY3Rpb24gdG8gYXBwbHkgdG8gYSBqb2Ig
YW5kIHdhcyByZWRpcmVjdGVkIHRvIGEgZGlmZmVyZW50CiB3ZWJzaXRlIHRvIGNvbXBsZXRl
IHRoZSBhcHBsaWNhdGlvbi4KCg4KBwQBBAACBwESA2wEGAoOCgcEAQQAAgcCEgNsGxwKpQIK
BgQBBAACCBIDcgQmGpUCIFRoZSBqb2Igc2Vla2VyIG9yIG90aGVyIGVudGl0eSBpbnRlcmFj
dGluZyB3aXRoIHRoZSBzZXJ2aWNlIGJlZ2FuIHRoZQogcHJvY2VzcyBvciBkZW1vbnN0cmF0
ZWQgdGhlIGludGVudGlvbiBvZiBhcHBseWluZyBmb3IgYSBqb2IgZnJvbSB0aGUKIHNlYXJj
aCByZXN1bHRzIHBhZ2Ugd2l0aG91dCB2aWV3aW5nIHRoZSBkZXRhaWxzIG9mIHRoZSBqb2Ig
cG9zdGluZy4KIElmIHNlbmRpbmcgdGhpcyBldmVudCwgSm9iRXZlbnRUeXBlLlZJRVcgZXZl
bnQgc2hvdWxkbid0IGJlIHNlbnQuCgoOCgcEAQQAAggBEgNyBCEKDgoHBAEEAAIIAhIDciQl
CpgFCgYEAQQAAgkSA34EKRqIBSBUaGUgam9iIHNlZWtlciwgb3Igb3RoZXIgZW50aXR5IGlu
dGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2UsIHBlcmZvcm1zIGFuCiBhY3Rpb24gd2l0aCBh
IHNpbmdsZSBjbGljayBmcm9tIHRoZSBzZWFyY2ggcmVzdWx0cyBwYWdlIHRvIGFwcGx5IHRv
IGEgam9iCiAod2l0aG91dCB2aWV3aW5nIHRoZSBkZXRhaWxzIG9mIHRoZSBqb2IgcG9zdGlu
ZyksIGFuZCBpcyByZWRpcmVjdGVkCiB0byBhIGRpZmZlcmVudCB3ZWJzaXRlIHRvIGNvbXBs
ZXRlIHRoZSBhcHBsaWNhdGlvbi4gSWYgYSBjYW5kaWRhdGUKIHBlcmZvcm1zIHRoaXMgYWN0
aW9uLCBzZW5kIG9ubHkgdGhpcyBldmVudCB0byB0aGUgc2VydmljZS4gRG8gbm90IGFsc28K
IHNlbmQKIFtKb2JFdmVudFR5cGUuQVBQTElDQVRJT05fU1RBUlRdW2dvb2dsZS5jbG91ZC50
YWxlbnQudjQuSm9iRXZlbnQuSm9iRXZlbnRUeXBlLkFQUExJQ0FUSU9OX1NUQVJUXSwKIFtK
b2JFdmVudFR5cGUuQVBQTElDQVRJT05fRklOSVNIXVtnb29nbGUuY2xvdWQudGFsZW50LnY0
LkpvYkV2ZW50LkpvYkV2ZW50VHlwZS5BUFBMSUNBVElPTl9GSU5JU0hdCiBvciBbSm9iRXZl
bnRUeXBlLlZJRVddW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iRXZlbnQuSm9iRXZlbnRU
eXBlLlZJRVddCiBldmVudHMuCgoOCgcEAQQAAgkBEgN+BCQKDgoHBAEEAAIJAhIDficoCsMB
CgYEAQQAAgoSBIMBBCQasgEgVGhpcyBldmVudCBzaG91bGQgYmUgdXNlZCB3aGVuIGEgY29t
cGFueSBzdWJtaXRzIGFuIGFwcGxpY2F0aW9uCiBvbiBiZWhhbGYgb2YgYSBqb2Igc2Vla2Vy
LiBUaGlzIGV2ZW50IGlzIGludGVuZGVkIGZvciB1c2UgYnkgc3RhZmZpbmcKIGFnZW5jaWVz
IGF0dGVtcHRpbmcgdG8gcGxhY2UgY2FuZGlkYXRlcy4KCg8KBwQBBAACCgESBIMBBB4KDwoH
BAEEAAIKAhIEgwEhIwqNAQoGBAEEAAILEgSHAQQSGn0gVGhlIGpvYiBzZWVrZXIgb3Igb3Ro
ZXIgZW50aXR5IGludGVyYWN0aW5nIHdpdGggdGhlIHNlcnZpY2UgZGVtb25zdHJhdGVkCiBh
biBpbnRlcmVzdCBpbiBhIGpvYiBieSBib29rbWFya2luZyBvciBzYXZpbmcgaXQuCgoPCgcE
AQQAAgsBEgSHAQQMCg8KBwQBBAACCwISBIcBDxEK1wEKBgQBBAACDBIEjAEEFhrGASBUaGUg
am9iIHNlZWtlciBvciBvdGhlciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUgc2Vydmlj
ZSB3YXMKIHNlbnQgYSBub3RpZmljYXRpb24sIHN1Y2ggYXMgYW4gZW1haWwgYWxlcnQgb3Ig
ZGV2aWNlIG5vdGlmaWNhdGlvbiwKIGNvbnRhaW5pbmcgb25lIG9yIG1vcmUgam9icyBsaXN0
aW5ncyBnZW5lcmF0ZWQgYnkgdGhlIHNlcnZpY2UuCgoPCgcEAQQAAgwBEgSMAQQQCg8KBwQB
BAACDAISBIwBExUKnAIKBgQBBAACDRIEkwEEDxqLAiBUaGUgam9iIHNlZWtlciBvciBvdGhl
ciBlbnRpdHkgaW50ZXJhY3Rpbmcgd2l0aCB0aGUgc2VydmljZSB3YXMKIGVtcGxveWVkIGJ5
IHRoZSBoaXJpbmcgZW50aXR5IChlbXBsb3llcikuIFNlbmQgdGhpcyBldmVudAogb25seSBp
ZiB0aGUgam9iIHNlZWtlciB3YXMgaGlyZWQgdGhyb3VnaCBhbiBhcHBsaWNhdGlvbiB0aGF0
IHdhcwogaW5pdGlhdGVkIGJ5IGEgc2VhcmNoIGNvbmR1Y3RlZCB0aHJvdWdoIHRoZSBDbG91
ZCBUYWxlbnQgU29sdXRpb24KIHNlcnZpY2UuCgoPCgcEAQQAAg0BEgSTAQQJCg8KBwQBBAAC
DQISBJMBDA4KrgEKBgQBBAACDhIEmAEEERqdASBBIHJlY3J1aXRlciBvciBzdGFmZmluZyBh
Z2VuY3kgc3VibWl0dGVkIGFuIGFwcGxpY2F0aW9uIG9uIGJlaGFsZiBvZiB0aGUKIGNhbmRp
ZGF0ZSBhZnRlciBpbnRlcmFjdGluZyB3aXRoIHRoZSBzZXJ2aWNlIHRvIGlkZW50aWZ5IGEg
c3VpdGFibGUgam9iCiBwb3N0aW5nLgoKDwoHBAEEAAIOARIEmAEECwoPCgcEAQQAAg4CEgSY
AQ4QCvQCCgYEAQQAAg8SBJ8BBBsa4wIgVGhlIGVudGl0eSBpbnRlcmFjdGluZyB3aXRoIHRo
ZSBzZXJ2aWNlIChmb3IgZXhhbXBsZSwgdGhlIGpvYiBzZWVrZXIpLAogd2FzIGdyYW50ZWQg
YW4gaW5pdGlhbCBpbnRlcnZpZXcgYnkgdGhlIGhpcmluZyBlbnRpdHkgKGVtcGxveWVyKS4g
VGhpcwogZXZlbnQgc2hvdWxkIG9ubHkgYmUgc2VudCBpZiB0aGUgam9iIHNlZWtlciB3YXMg
Z3JhbnRlZCBhbiBpbnRlcnZpZXcgYXMKIHBhcnQgb2YgYW4gYXBwbGljYXRpb24gdGhhdCB3
YXMgaW5pdGlhdGVkIGJ5IGEgc2VhcmNoIGNvbmR1Y3RlZCB0aHJvdWdoIC8KIHJlY29tbWVu
ZGF0aW9uIHByb3ZpZGVkIGJ5IHRoZSBDbG91ZCBUYWxlbnQgU29sdXRpb24gc2VydmljZS4K
Cg8KBwQBBAACDwESBJ8BBBUKDwoHBAEEAAIPAhIEnwEYGgp0CgQEAQIAEgSkAQJBGmYgUmVx
dWlyZWQuIFRoZSB0eXBlIG9mIHRoZSBldmVudCAoc2VlCiBbSm9iRXZlbnRUeXBlXVtnb29n
bGUuY2xvdWQudGFsZW50LnY0LkpvYkV2ZW50LkpvYkV2ZW50VHlwZV0pLgoKDQoFBAECAAYS
BKQBAg4KDQoFBAECAAESBKQBDxMKDQoFBAECAAMSBKQBFhcKDQoFBAECAAgSBKQBGEAKEAoI
BAECAAicCAASBKQBGT8KpAQKBAQBAgESBLEBAkQalQQgUmVxdWlyZWQuIFRoZSBbam9iIG5h
bWUocyldW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iLm5hbWVdIGFzc29jaWF0ZWQKIHdp
dGggdGhpcyBldmVudC4gRm9yIGV4YW1wbGUsIGlmIHRoaXMgaXMgYW4KIFtpbXByZXNzaW9u
XVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYkV2ZW50LkpvYkV2ZW50VHlwZS5JTVBSRVNT
SU9OXQogZXZlbnQsIHRoaXMgZmllbGQgY29udGFpbnMgdGhlIGlkZW50aWZpZXJzIG9mIGFs
bCBqb2JzIHNob3duIHRvIHRoZSBqb2IKIHNlZWtlci4gSWYgdGhpcyB3YXMgYQogW3ZpZXdd
W2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iRXZlbnQuSm9iRXZlbnRUeXBlLlZJRVddIGV2
ZW50LCB0aGlzIGZpZWxkCiBjb250YWlucyB0aGUgaWRlbnRpZmllciBvZiB0aGUgdmlld2Vk
IGpvYi4KCiBUaGUgZm9ybWF0IGlzCiAicHJvamVjdHMve3Byb2plY3RfaWR9L3RlbmFudHMv
e3RlbmFudF9pZH0vam9icy97am9iX2lkfSIsIGZvcgogZXhhbXBsZSwgInByb2plY3RzL2Zv
by90ZW5hbnRzL2Jhci9qb2JzL2JheiIuCgoNCgUEAQIBBBIEsQECCgoNCgUEAQIBBRIEsQEL
EQoNCgUEAQIBARIEsQESFgoNCgUEAQIBAxIEsQEZGgoNCgUEAQIBCBIEsQEbQwoQCggEAQIB
CJwIABIEsQEcQmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::Event::ClientEvent ===
    # Fields for ClientEvent
    # Field: request_id Type: 9 ()
    # Field: event_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: job_event Type: 11 (.google.cloud.talent.v4.JobEvent)
    # Field: event_notes Type: 9 ()

# === Message: Google::Cloud::Talent::V4::Event::JobEvent ===
    # Fields for JobEvent
    # Field: type Type: 14 (.google.cloud.talent.v4.JobEvent.JobEventType)
    # Field: jobs Type: 9 ()

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

Google::Cloud::Talent::V4::Event - Compiled Protocol Buffers messages for google/cloud/talent/v4/event.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::Event;

    my $msg = Google::Cloud::Talent::V4::Event::ClientEvent->new({
        request_id => $request_id,
        event_id => $event_id,
        create_time => $create_time,
        job_event => $job_event,
    });

    # Read or update a field
    my $val = $msg->request_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::Event::ClientEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::Event::ClientEvent

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
[ResponseMetadata.request_id][google.cloud.talent.v4.ResponseMetadata.request_id].

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

Required. A unique identifier, generated by the client application.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The timestamp of the event.

=item * C<< $msg->job_event() >> / C<< $msg->job_event($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Event::JobEvent>)

An event issued when a job seeker interacts with the application that
implements Cloud Talent Solution.

=item * C<< $msg->event_notes() >> / C<< $msg->event_notes($value) >>

Type: C<String>

Notes about the event provided by recruiters or other users, for example,
feedback on why a job was bookmarked.

=back

=head2 Google::Cloud::Talent::V4::Event::JobEvent

An event issued when a job seeker interacts with the application that
implements Cloud Talent Solution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::JobEvent::JobEventType>)

Required. The type of the event (see
[JobEventType][google.cloud.talent.v4.JobEvent.JobEventType]).

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<String>

Required. The [job name(s)][google.cloud.talent.v4.Job.name] associated
with this event. For example, if this is an
[impression][google.cloud.talent.v4.JobEvent.JobEventType.IMPRESSION]
event, this field contains the identifiers of all jobs shown to the job
seeker. If this was a
[view][google.cloud.talent.v4.JobEvent.JobEventType.VIEW] event, this field
contains the identifier of the viewed job.

The format is
"projects/{project_id}/tenants/{tenant_id}/jobs/{job_id}", for
example, "projects/foo/tenants/bar/jobs/baz".

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::Event::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
