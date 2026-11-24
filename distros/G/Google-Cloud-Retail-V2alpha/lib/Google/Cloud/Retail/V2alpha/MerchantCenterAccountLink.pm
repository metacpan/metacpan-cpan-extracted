package Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink;

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
Cj5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvbWVyY2hhbnRfY2VudGVyX2FjY291bnRf
bGluay5wcm90bxIbZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpMHChlNZXJjaGFudENlbnRlckFjY291bnRMaW5r
EhoKBG5hbWUYASABKAlCBuBBBeBBA1IEbmFtZRIWCgJpZBgIIAEoCUIG4EEF4EEDUgJpZBJA
ChptZXJjaGFudF9jZW50ZXJfYWNjb3VudF9pZBgCIAEoA0ID4EECUhdtZXJjaGFudENlbnRl
ckFjY291bnRJZBIgCglicmFuY2hfaWQYAyABKAlCA+BBAlIIYnJhbmNoSWQSHQoKZmVlZF9s
YWJlbBgEIAEoCVIJZmVlZExhYmVsEiMKDWxhbmd1YWdlX2NvZGUYBSABKAlSDGxhbmd1YWdl
Q29kZRJyCgxmZWVkX2ZpbHRlcnMYBiADKAsyTy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxw
aGEuTWVyY2hhbnRDZW50ZXJBY2NvdW50TGluay5NZXJjaGFudENlbnRlckZlZWRGaWx0ZXJS
C2ZlZWRGaWx0ZXJzElcKBXN0YXRlGAcgASgOMjwuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLk1lcmNoYW50Q2VudGVyQWNjb3VudExpbmsuU3RhdGVCA+BBA1IFc3RhdGUSIgoKcHJv
amVjdF9pZBgJIAEoCUID4EEDUglwcm9qZWN0SWQSGwoGc291cmNlGAogASgJQgPgQQFSBnNv
dXJjZRqYAQoYTWVyY2hhbnRDZW50ZXJGZWVkRmlsdGVyEioKD3ByaW1hcnlfZmVlZF9pZBgB
IAEoA0ICGAFSDXByaW1hcnlGZWVkSWQSJAoOZGF0YV9zb3VyY2VfaWQYAyABKANSDGRhdGFT
b3VyY2VJZBIqChFwcmltYXJ5X2ZlZWRfbmFtZRgCIAEoCVIPcHJpbWFyeUZlZWROYW1lIkMK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHUEVORElORxABEgoKBkFDVElWRRAC
EgoKBkZBSUxFRBADOqsB6kGnAQovcmV0YWlsLmdvb2dsZWFwaXMuY29tL01lcmNoYW50Q2Vu
dGVyQWNjb3VudExpbmsSdHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jYXRhbG9ncy97Y2F0YWxvZ30vbWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua3Mve21lcmNo
YW50X2NlbnRlcl9hY2NvdW50X2xpbmt9IqMBCidDcmVhdGVNZXJjaGFudENlbnRlckFjY291
bnRMaW5rTWV0YWRhdGESOwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZULiAQofY29tLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJhbHBoYUIeTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1Byb3RvUAFaN2Nsb3VkLmdv
b2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxwaGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRB
SUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQWxwaGHKAhtHb29nbGVcQ2xvdWRcUmV0YWls
XFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYWxwaGFKjygKBxIFDgCQAQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIA
KQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA4CgkKAgglEgMWADgKCAoBCBIDFwBO
CgkKAggLEgMXAE4KCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA/CgkKAggIEgMZAD8K
CAoBCBIDGgA4CgkKAggBEgMaADgKCAoBCBIDGwAkCgkKAggkEgMbACQKCAoBCBIDHAA4CgkK
AggpEgMcADgKCAoBCBIDHQA3CgkKAggtEgMdADcKxAEKAgQAEgUiAIYBARq2ASBSZXByZXNl
bnRzIGEgbGluayBiZXR3ZWVuIGEgTWVyY2hhbnQgQ2VudGVyIGFjY291bnQgYW5kIGEgYnJh
bmNoLgogQWZ0ZXIgYSBsaW5rIGlzIGVzdGFibGlzaGVkLCBwcm9kdWN0cyBmcm9tIHRoZSBs
aW5rZWQgTWVyY2hhbnQgQ2VudGVyIGFjY291bnQKIGFyZSBzdHJlYW1lZCB0byB0aGUgbGlu
a2VkIGJyYW5jaC4KCgoKAwQAARIDIgghCgsKAwQABxIEIwImBAoNCgUEAAedCBIEIwImBAo2
CgQEAAMAEgQpAjQDGiggTWVyY2hhbnQgQ2VudGVyIEZlZWQgZmlsdGVyIGNyaXRlcmlvbi4K
CgwKBQQAAwABEgMpCiIKWgoGBAADAAIAEgMsBDIaSyBNZXJjaGFudCBDZW50ZXIgcHJpbWFy
eSBmZWVkIElELgogRGVwcmVjYXRlZDogdXNlIGRhdGFfc291cmNlX2lkIGluc3RlYWQuCgoO
CgcEAAMAAgAFEgMsBAkKDgoHBAADAAIAARIDLAoZCg4KBwQAAwACAAMSAywcHQoOCgcEAAMA
AgAIEgMsHjEKDwoIBAADAAIACAMSAywfMAokCgYEAAMAAgESAy8EHRoVIEFGTSBkYXRhIHNv
dXJjZSBJRC4KCg4KBwQAAwACAQUSAy8ECQoOCgcEAAMAAgEBEgMvChgKDgoHBAADAAIBAxID
LxscCmQKBgQAAwACAhIDMwQhGlUgTWVyY2hhbnQgQ2VudGVyIHByaW1hcnkgZmVlZCBuYW1l
LiBUaGUgbmFtZSBpcyB1c2VkIGZvciB0aGUgZGlzcGxheQogcHVycG9zZXMgb25seS4KCg4K
BwQAAwACAgUSAzMECgoOCgcEAAMAAgIBEgMzCxwKDgoHBAADAAICAxIDMx8gCiYKBAQABAAS
BDcCQwMaGCBUaGUgc3RhdGUgb2YgdGhlIGxpbmsuCgoMCgUEAAQAARIDNwcMCh8KBgQABAAC
ABIDOQQaGhAgRGVmYXVsdCB2YWx1ZS4KCg4KBwQABAACAAESAzkEFQoOCgcEAAQAAgACEgM5
GBkKOQoGBAAEAAIBEgM8BBAaKiBMaW5rIGlzIGNyZWF0ZWQgYW5kIExSTyBpcyBub3QgY29t
cGxldGUuCgoOCgcEAAQAAgEBEgM8BAsKDgoHBAAEAAIBAhIDPA4PCiAKBgQABAACAhIDPwQP
GhEgTGluayBpcyBhY3RpdmUuCgoOCgcEAAQAAgIBEgM/BAoKDgoHBAAEAAICAhIDPw0OCiYK
BgQABAACAxIDQgQPGhcgTGluayBjcmVhdGlvbiBmYWlsZWQuCgoOCgcEAAQAAgMBEgNCBAoK
DgoHBAAEAAIDAhIDQg0OCtoBCgQEAAIAEgRIAksEGssBIE91dHB1dCBvbmx5LiBJbW11dGFi
bGUuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgTWVyY2hhbnQgQ2VudGVyIEFjY291bnQK
IExpbmssIHN1Y2ggYXMKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3Mv
ZGVmYXVsdF9jYXRhbG9nL21lcmNoYW50Q2VudGVyQWNjb3VudExpbmtzL21lcmNoYW50X2Nl
bnRlcl9hY2NvdW50X2xpbmtgLgoKDAoFBAACAAUSA0gCCAoMCgUEAAIAARIDSAkNCgwKBQQA
AgADEgNIEBEKDQoFBAACAAgSBEgSSwMKDwoIBAACAAicCAASA0kEKwoPCggEAAIACJwIARID
SgQtCqYDCgQEAAIBEgRUAlcEGpcDIE91dHB1dCBvbmx5LiBJbW11dGFibGUuCiBbTWVyY2hh
bnRDZW50ZXJBY2NvdW50TGlua11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLk1lcmNo
YW50Q2VudGVyQWNjb3VudExpbmtdCiBpZGVudGlmaWVyLCB3aGljaCBpcyB0aGUgZmluYWwg
Y29tcG9uZW50IG9mCiBbbmFtZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLk1lcmNo
YW50Q2VudGVyQWNjb3VudExpbmsubmFtZV0uIFRoaXMKIGZpZWxkIGlzIGF1dG8gZ2VuZXJh
dGVkIGFuZCBmb2xsb3dzIHRoZSBjb252ZW50aW9uOgogYEJyYW5jaElkX01lcmNoYW50Q2Vu
dGVyQWNjb3VudElkYC4KIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3Mv
ZGVmYXVsdF9jYXRhbG9nL21lcmNoYW50Q2VudGVyQWNjb3VudExpbmtzL2lkXzFgLgoKDAoF
BAACAQUSA1QCCAoMCgUEAAIBARIDVAkLCgwKBQQAAgEDEgNUDg8KDQoFBAACAQgSBFQQVwMK
DwoIBAACAQicCAASA1UEKwoPCggEAAIBCJwIARIDVgQtCs8BCgQEAAICEgNcAlAawQEgUmVx
dWlyZWQuIFRoZSBsaW5rZWQgW01lcmNoYW50IGNlbnRlciBhY2NvdW50CiBpZF0oaHR0cHM6
Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vc2hvcHBpbmctY29udGVudC9ndWlkZXMvYWNjb3Vu
dHN0YXR1c2VzKS4KIFRoZSBhY2NvdW50IG11c3QgYmUgYSBzdGFuZGFsb25lIGFjY291bnQg
b3IgYSBzdWItYWNjb3VudCBvZiBhIE1DQS4KCgwKBQQAAgIFEgNcAgcKDAoFBAACAgESA1wI
IgoMCgUEAAICAxIDXCUmCgwKBQQAAgIIEgNcJ08KDwoIBAACAgicCAASA1woTgqBAwoEBAAC
AxIDZAJAGvMCIFJlcXVpcmVkLiBUaGUgYnJhbmNoIElEIChlLmcuIDAvMS8yKSB3aXRoaW4g
dGhlIGNhdGFsb2cgdGhhdCBwcm9kdWN0cyBmcm9tCiBtZXJjaGFudF9jZW50ZXJfYWNjb3Vu
dF9pZCBhcmUgc3RyZWFtZWQgdG8uIFdoZW4gdXBkYXRpbmcgdGhpcyBmaWVsZCwgYW4KIGVt
cHR5IHZhbHVlIHdpbGwgdXNlIHRoZSBjdXJyZW50bHkgY29uZmlndXJlZCBkZWZhdWx0IGJy
YW5jaC4gSG93ZXZlciwKIGNoYW5naW5nIHRoZSBkZWZhdWx0IGJyYW5jaCBsYXRlciBvbiB3
b24ndCBjaGFuZ2UgdGhlIGxpbmtlZCBicmFuY2ggaGVyZS4KCiBBIHNpbmdsZSBicmFuY2gg
SUQgY2FuIG9ubHkgaGF2ZSBvbmUgbGlua2VkIE1lcmNoYW50IENlbnRlciBhY2NvdW50IElE
LgoKDAoFBAACAwUSA2QCCAoMCgUEAAIDARIDZAkSCgwKBQQAAgMDEgNkFRYKDAoFBAACAwgS
A2QXPwoPCggEAAIDCJwIABIDZBg+CvcBCgQEAAIEEgNsAhga6QEgVGhlIEZlZWRMYWJlbCB1
c2VkIHRvIHBlcmZvcm0gZmlsdGVyaW5nLgogTm90ZTogdGhpcyByZXBsYWNlcwogW3JlZ2lv
bl9pZF0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vc2hvcHBpbmctY29udGVudC9y
ZWZlcmVuY2UvcmVzdC92Mi4xL3Byb2R1Y3RzI1Byb2R1Y3QuRklFTERTLmZlZWRfbGFiZWwp
LgoKIEV4YW1wbGUgdmFsdWU6IGBVU2AuCiBFeGFtcGxlIHZhbHVlOiBgRmVlZExhYmVsMWAu
CgoMCgUEAAIEBRIDbAIICgwKBQQAAgQBEgNsCRMKDAoFBAACBAMSA2wWFwrNAgoEBAACBRID
dgIbGr8CIExhbmd1YWdlIG9mIHRoZSB0aXRsZS9kZXNjcmlwdGlvbiBhbmQgb3RoZXIgc3Ry
aW5nIGF0dHJpYnV0ZXMuIFVzZSBsYW5ndWFnZQogdGFncyBkZWZpbmVkIGJ5IFtCQ1AgNDdd
KGh0dHBzOi8vd3d3LnJmYy1lZGl0b3Iub3JnL3JmYy9iY3AvYmNwNDcudHh0KS4KIElTTyA2
MzktMS4KCiBUaGlzIHNwZWNpZmllcyB0aGUgbGFuZ3VhZ2Ugb2Ygb2ZmZXJzIGluIE1lcmNo
YW50IENlbnRlciB0aGF0IHdpbGwgYmUKIGFjY2VwdGVkLiBJZiBlbXB0eSwgbm8gbGFuZ3Vh
Z2UgZmlsdGVyaW5nIHdpbGwgYmUgcGVyZm9ybWVkLgoKIEV4YW1wbGUgdmFsdWU6IGBlbmAu
CgoMCgUEAAIFBRIDdgIICgwKBQQAAgUBEgN2CRYKDAoFBAACBQMSA3YZGgrCAQoEBAACBhID
ewI1GrQBIENyaXRlcmlhIGZvciB0aGUgTWVyY2hhbnQgQ2VudGVyIGZlZWRzIHRvIGJlIGlu
Z2VzdGVkIHZpYSB0aGUgbGluay4KIEFsbCBvZmZlcnMgd2lsbCBiZSBpbmdlc3RlZCBpZiB0
aGUgbGlzdCBpcyBlbXB0eS4KIE90aGVyd2lzZSB0aGUgb2ZmZXJzIHdpbGwgYmUgaW5nZXN0
ZWQgZnJvbSBzZWxlY3RlZCBmZWVkcy4KCgwKBQQAAgYEEgN7AgoKDAoFBAACBgYSA3sLIwoM
CgUEAAIGARIDeyQwCgwKBQQAAgYDEgN7MzQKPQoEBAACBxIDfgI+GjAgT3V0cHV0IG9ubHku
IFJlcHJlc2VudHMgdGhlIHN0YXRlIG9mIHRoZSBsaW5rLgoKDAoFBAACBwYSA34CBwoMCgUE
AAIHARIDfggNCgwKBQQAAgcDEgN+EBEKDAoFBAACBwgSA34SPQoPCggEAAIHCJwIABIDfhM8
CjUKBAQAAggSBIEBAkQaJyBPdXRwdXQgb25seS4gR29vZ2xlIENsb3VkIHByb2plY3QgSUQu
CgoNCgUEAAIIBRIEgQECCAoNCgUEAAIIARIEgQEJEwoNCgUEAAIIAxIEgQEWFwoNCgUEAAII
CBIEgQEYQwoQCggEAAIICJwIABIEgQEZQgptCgQEAAIJEgSFAQI+Gl8gT3B0aW9uYWwuIEFu
IG9wdGlvbmFsIGFyYml0cmFyeSBzdHJpbmcgdGhhdCBjb3VsZCBiZSB1c2VkIGFzIGEgdGFn
IGZvcgogdHJhY2tpbmcgbGluayBzb3VyY2UuCgoNCgUEAAIJBRIEhQECCAoNCgUEAAIJARIE
hQEJDwoNCgUEAAIJAxIEhQESFAoNCgUEAAIJCBIEhQEVPQoQCggEAAIJCJwIABIEhQEWPApK
CgIEARIGiQEAkAEBGjwgQ29tbW9uIG1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNz
IG9mIHRoZSBvcGVyYXRpb25zLgoKCwoDBAEBEgSJAQgvCiYKBAQBAgASBIsBAiwaGCBPcGVy
YXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEAQIABhIEiwECGwoNCgUEAQIAARIEiwEcJwoNCgUE
AQIAAxIEiwEqKwpkCgQEAQIBEgSPAQIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUu
IElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRp
bWUuCgoNCgUEAQIBBhIEjwECGwoNCgUEAQIBARIEjwEcJwoNCgUEAQIBAxIEjwEqK2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink ===
    # Fields for MerchantCenterAccountLink
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: merchant_center_account_id Type: 3 ()
    # Field: branch_id Type: 9 ()
    # Field: feed_label Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: feed_filters Type: 11 (.google.cloud.retail.v2alpha.MerchantCenterAccountLink.MerchantCenterFeedFilter)
    # Field: state Type: 14 (.google.cloud.retail.v2alpha.MerchantCenterAccountLink.State)
    # Field: project_id Type: 9 ()
    # Field: source Type: 9 ()

# Enum: MerchantCenterAccountLink::State
our $MerchantCenterAccountLink_STATE_UNSPECIFIED = 0;
our $MerchantCenterAccountLink_PENDING = 1;
our $MerchantCenterAccountLink_ACTIVE = 2;
our $MerchantCenterAccountLink_FAILED = 3;

# === Message: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::CreateMerchantCenterAccountLinkMetadata ===
    # Fields for CreateMerchantCenterAccountLinkMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/merchant_center_account_link.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink;

    my $msg = Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink->new({
        name => $name,
        id => $id,
        merchant_center_account_id => $merchant_center_account_id,
        branch_id => $branch_id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/merchant_center_account_link.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink

Represents a link between a Merchant Center account and a branch.
After a link is established, products from the linked Merchant Center account
are streamed to the linked branch.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Immutable. Full resource name of the Merchant Center Account
Link, such as
`projects/*/locations/global/catalogs/default_catalog/merchantCenterAccountLinks/merchant_center_account_link`.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. Immutable.
[MerchantCenterAccountLink][google.cloud.retail.v2alpha.MerchantCenterAccountLink]
identifier, which is the final component of
[name][google.cloud.retail.v2alpha.MerchantCenterAccountLink.name]. This
field is auto generated and follows the convention:
`BranchId_MerchantCenterAccountId`.
`projects/*/locations/global/catalogs/default_catalog/merchantCenterAccountLinks/id_1`.

=item * C<< $msg->merchant_center_account_id() >> / C<< $msg->merchant_center_account_id($value) >>

Type: C<Int64>

Required. The linked [Merchant center account
id](https://developers.google.com/shopping-content/guides/accountstatuses).
The account must be a standalone account or a sub-account of a MCA.

=item * C<< $msg->branch_id() >> / C<< $msg->branch_id($value) >>

Type: C<String>

Required. The branch ID (e.g. 0/1/2) within the catalog that products from
merchant_center_account_id are streamed to. When updating this field, an
empty value will use the currently configured default branch. However,
changing the default branch later on won't change the linked branch here.

A single branch ID can only have one linked Merchant Center account ID.

=item * C<< $msg->feed_label() >> / C<< $msg->feed_label($value) >>

Type: C<String>

The FeedLabel used to perform filtering.
Note: this replaces
[region_id](https://developers.google.com/shopping-content/reference/rest/v2.1/products#Product.FIELDS.feed_label).

Example value: `US`.
Example value: `FeedLabel1`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Language of the title/description and other string attributes. Use language
tags defined by [BCP 47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt).
ISO 639-1.

This specifies the language of offers in Merchant Center that will be
accepted. If empty, no language filtering will be performed.

Example value: `en`.

=item * C<< $msg->feed_filters() >> / C<< $msg->feed_filters($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink::MerchantCenterFeedFilter>)

Criteria for the Merchant Center feeds to be ingested via the link.
All offers will be ingested if the list is empty.
Otherwise the offers will be ingested from selected feeds.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::State>)

Output only. Represents the state of the link.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Output only. Google Cloud project ID.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Optional. An optional arbitrary string that could be used as a tag for
tracking link source.

=back

=head3 Enum: MerchantCenterAccountLink::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::CreateMerchantCenterAccountLinkMetadata

Common metadata related to the progress of the operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
