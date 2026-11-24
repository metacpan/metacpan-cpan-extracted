package Google::Cloud::Bigquery::V2::PrivacyPolicy;

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
Ci1nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcHJpdmFjeV9wb2xpY3kucHJvdG8SGGdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKJ
AQoaQWdncmVnYXRpb25UaHJlc2hvbGRQb2xpY3kSJgoJdGhyZXNob2xkGAEgASgDQgPgQQFI
AFIJdGhyZXNob2xkiAEBEjUKFHByaXZhY3lfdW5pdF9jb2x1bW5zGAIgAygJQgPgQQFSEnBy
aXZhY3lVbml0Q29sdW1uc0IMCgpfdGhyZXNob2xkIqMFChlEaWZmZXJlbnRpYWxQcml2YWN5
UG9saWN5EjsKFW1heF9lcHNpbG9uX3Blcl9xdWVyeRgBIAEoAUID4EEBSABSEm1heEVwc2ls
b25QZXJRdWVyeYgBARIwCg9kZWx0YV9wZXJfcXVlcnkYAiABKAFCA+BBAUgBUg1kZWx0YVBl
clF1ZXJ5iAEBEj4KFm1heF9ncm91cHNfY29udHJpYnV0ZWQYAyABKANCA+BBAUgCUhRtYXhH
cm91cHNDb250cmlidXRlZIgBARI4ChNwcml2YWN5X3VuaXRfY29sdW1uGAQgASgJQgPgQQFI
A1IRcHJpdmFjeVVuaXRDb2x1bW6IAQESLwoOZXBzaWxvbl9idWRnZXQYBSABKAFCA+BBAUgE
Ug1lcHNpbG9uQnVkZ2V0iAEBEisKDGRlbHRhX2J1ZGdldBgGIAEoAUID4EEBSAVSC2RlbHRh
QnVkZ2V0iAEBEkIKGGVwc2lsb25fYnVkZ2V0X3JlbWFpbmluZxgHIAEoAUID4EEDSAZSFmVw
c2lsb25CdWRnZXRSZW1haW5pbmeIAQESPgoWZGVsdGFfYnVkZ2V0X3JlbWFpbmluZxgIIAEo
AUID4EEDSAdSFGRlbHRhQnVkZ2V0UmVtYWluaW5niAEBQhgKFl9tYXhfZXBzaWxvbl9wZXJf
cXVlcnlCEgoQX2RlbHRhX3Blcl9xdWVyeUIZChdfbWF4X2dyb3Vwc19jb250cmlidXRlZEIW
ChRfcHJpdmFjeV91bml0X2NvbHVtbkIRCg9fZXBzaWxvbl9idWRnZXRCDwoNX2RlbHRhX2J1
ZGdldEIbChlfZXBzaWxvbl9idWRnZXRfcmVtYWluaW5nQhkKF19kZWx0YV9idWRnZXRfcmVt
YWluaW5nIscCChVKb2luUmVzdHJpY3Rpb25Qb2xpY3kSbgoOam9pbl9jb25kaXRpb24YASAB
KA4yPS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuSm9pblJlc3RyaWN0aW9uUG9saWN5Lkpv
aW5Db25kaXRpb25CA+BBAUgAUg1qb2luQ29uZGl0aW9uiAEBEjUKFGpvaW5fYWxsb3dlZF9j
b2x1bW5zGAIgAygJQgPgQQFSEmpvaW5BbGxvd2VkQ29sdW1ucyJ0Cg1Kb2luQ29uZGl0aW9u
Eh4KGkpPSU5fQ09ORElUSU9OX1VOU1BFQ0lGSUVEEAASDAoISk9JTl9BTlkQARIMCghKT0lO
X0FMTBACEhUKEUpPSU5fTk9UX1JFUVVJUkVEEAMSEAoMSk9JTl9CTE9DS0VEEARCEQoPX2pv
aW5fY29uZGl0aW9uIqsDCg1Qcml2YWN5UG9saWN5En0KHGFnZ3JlZ2F0aW9uX3RocmVzaG9s
ZF9wb2xpY3kYAiABKAsyNC5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuQWdncmVnYXRpb25U
aHJlc2hvbGRQb2xpY3lCA+BBAUgAUhphZ2dyZWdhdGlvblRocmVzaG9sZFBvbGljeRJ6Chtk
aWZmZXJlbnRpYWxfcHJpdmFjeV9wb2xpY3kYAyABKAsyMy5nb29nbGUuY2xvdWQuYmlncXVl
cnkudjIuRGlmZmVyZW50aWFsUHJpdmFjeVBvbGljeUID4EEBSABSGWRpZmZlcmVudGlhbFBy
aXZhY3lQb2xpY3kScQoXam9pbl9yZXN0cmljdGlvbl9wb2xpY3kYASABKAsyLy5nb29nbGUu
Y2xvdWQuYmlncXVlcnkudjIuSm9pblJlc3RyaWN0aW9uUG9saWN5QgPgQQFIAVIVam9pblJl
c3RyaWN0aW9uUG9saWN5iAEBQhAKDnByaXZhY3lfcG9saWN5QhoKGF9qb2luX3Jlc3RyaWN0
aW9uX3BvbGljeUJvChxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhJQcml2YWN5UG9s
aWN5UHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVl
cnlwYjtiaWdxdWVyeXBiSrg+CgcSBQ4AqAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCAoBCBIDFABSCgkKAggLEgMUAFIKCAoB
CBIDFQAzCgkKAggIEgMVADMKCAoBCBIDFgA1CgkKAggBEgMWADUKVwoCBAASBBkAJgEaSyBS
ZXByZXNlbnRzIHByaXZhY3kgcG9saWN5IGFzc29jaWF0ZWQgd2l0aCAiYWdncmVnYXRpb24g
dGhyZXNob2xkIiBtZXRob2QuCgoKCgMEAAESAxkIIgpOCgQEAAIAEgMbAkgaQSBPcHRpb25h
bC4gVGhlIHRocmVzaG9sZCBmb3IgdGhlICJhZ2dyZWdhdGlvbiB0aHJlc2hvbGQiIHBvbGlj
eS4KCgwKBQQAAgAEEgMbAgoKDAoFBAACAAUSAxsLEAoMCgUEAAIAARIDGxEaCgwKBQQAAgAD
EgMbHR4KDAoFBAACAAgSAxsfRwoPCggEAAIACJwIABIDGyBGCoQDCgQEAAIBEgQkAiUvGvUC
IE9wdGlvbmFsLiBUaGUgcHJpdmFjeSB1bml0IGNvbHVtbihzKSBhc3NvY2lhdGVkIHdpdGgg
dGhpcyBwb2xpY3kuCiBGb3Igbm93LCBvbmx5IG9uZSBjb2x1bW4gcGVyIGRhdGEgc291cmNl
IG9iamVjdCAodGFibGUsIHZpZXcpIGlzIGFsbG93ZWQgYXMKIGEgcHJpdmFjeSB1bml0IGNv
bHVtbi4KIFJlcHJlc2VudGluZyBhcyBhIHJlcGVhdGVkIGZpZWxkIGluIG1ldGFkYXRhIGZv
ciBleHRlbnNpYmlsaXR5IHRvCiBtdWx0aXBsZSBjb2x1bW5zIGluIGZ1dHVyZS4KIER1cGxp
Y2F0ZXMgYW5kIFJlcGVhdGVkIHN0cnVjdCBmaWVsZHMgYXJlIG5vdCBhbGxvd2VkLgogRm9y
IG5lc3RlZCBmaWVsZHMsIHVzZSBkb3Qgbm90YXRpb24gKCJvdXRlci5pbm5lciIpCgoMCgUE
AAIBBBIDJAIKCgwKBQQAAgEFEgMkCxEKDAoFBAACAQESAyQSJgoMCgUEAAIBAxIDJCkqCgwK
BQQAAgEIEgMlBi4KDwoIBAACAQicCAASAyUHLQpWCgIEARIEKQBuARpKIFJlcHJlc2VudHMg
cHJpdmFjeSBwb2xpY3kgYXNzb2NpYXRlZCB3aXRoICJkaWZmZXJlbnRpYWwgcHJpdmFjeSIg
bWV0aG9kLgoKCgoDBAEBEgMpCCEKugIKBAQBAgASBC4CLy8aqwIgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIGVwc2lsb24gdmFsdWUgdGhhdCBhIHF1ZXJ5IGNhbiBjb25zdW1lLiBJZiB0aGUK
IHN1YnNjcmliZXIgc3BlY2lmaWVzIGVwc2lsb24gYXMgYSBwYXJhbWV0ZXIgaW4gYSBTRUxF
Q1QgcXVlcnksIGl0IG11c3QgYmUKIGxlc3MgdGhhbiBvciBlcXVhbCB0byB0aGlzIHZhbHVl
LiBUaGUgZXBzaWxvbiBwYXJhbWV0ZXIgY29udHJvbHMgdGhlIGFtb3VudAogb2Ygbm9pc2Ug
dGhhdCBpcyBhZGRlZCB0byB0aGUgZ3JvdXBzIOKAlCBhIGhpZ2hlciBlcHNpbG9uIG1lYW5z
IGxlc3Mgbm9pc2UuCgoMCgUEAQIABBIDLgIKCgwKBQQBAgAFEgMuCxEKDAoFBAECAAESAy4S
JwoMCgUEAQIAAxIDLiorCgwKBQQBAgAIEgMvBi4KDwoIBAECAAicCAASAy8HLQr3AQoEBAEC
ARIDNQJPGukBIE9wdGlvbmFsLiBUaGUgZGVsdGEgdmFsdWUgdGhhdCBpcyB1c2VkIHBlciBx
dWVyeS4gRGVsdGEgcmVwcmVzZW50cyB0aGUKIHByb2JhYmlsaXR5IHRoYXQgYW55IHJvdyB3
aWxsIGZhaWwgdG8gYmUgZXBzaWxvbiBkaWZmZXJlbnRpYWxseSBwcml2YXRlLgogSW5kaWNh
dGVzIHRoZSByaXNrIGFzc29jaWF0ZWQgd2l0aCBleHBvc2luZyBhZ2dyZWdhdGUgcm93cyBp
biB0aGUgcmVzdWx0IG9mCiBhIHF1ZXJ5LgoKDAoFBAECAQQSAzUCCgoMCgUEAQIBBRIDNQsR
CgwKBQQBAgEBEgM1EiEKDAoFBAECAQMSAzUkJQoMCgUEAQIBCBIDNSZOCg8KCAQBAgEInAgA
EgM1J00KsAIKBAQBAgISBDsCPC8aoQIgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIGdyb3VwcyBj
b250cmlidXRlZCB2YWx1ZSB0aGF0IGlzIHVzZWQgcGVyIHF1ZXJ5LgogUmVwcmVzZW50cyB0
aGUgbWF4aW11bSBudW1iZXIgb2YgZ3JvdXBzIHRvIHdoaWNoIGVhY2ggcHJvdGVjdGVkIGVu
dGl0eSBjYW4KIGNvbnRyaWJ1dGUuIENoYW5naW5nIHRoaXMgdmFsdWUgZG9lcyBub3QgaW1w
cm92ZSBvciB3b3JzZW4gcHJpdmFjeS4gVGhlCiBiZXN0IHZhbHVlIGZvciBhY2N1cmFjeSBh
bmQgdXRpbGl0eSBkZXBlbmRzIG9uIHRoZSBxdWVyeSBhbmQgZGF0YS4KCgwKBQQBAgIEEgM7
AgoKDAoFBAECAgUSAzsLEAoMCgUEAQICARIDOxEnCgwKBQQBAgIDEgM7KisKDAoFBAECAggS
AzwGLgoPCggEAQICCJwIABIDPActCrsBCgQEAQIDEgRBAkIvGqwBIE9wdGlvbmFsLiBUaGUg
cHJpdmFjeSB1bml0IGNvbHVtbiBhc3NvY2lhdGVkIHdpdGggdGhpcyBwb2xpY3kuIERpZmZl
cmVudGlhbAogcHJpdmFjeSBwb2xpY2llcyBjYW4gb25seSBoYXZlIG9uZSBwcml2YWN5IHVu
aXQgY29sdW1uIHBlciBkYXRhIHNvdXJjZQogb2JqZWN0ICh0YWJsZSwgdmlldykuCgoMCgUE
AQIDBBIDQQIKCgwKBQQBAgMFEgNBCxEKDAoFBAECAwESA0ESJQoMCgUEAQIDAxIDQSgpCgwK
BQQBAgMIEgNCBi4KDwoIBAECAwicCAASA0IHLQqeBgoEBAECBBIDTwJOGpAGIE9wdGlvbmFs
LiBUaGUgdG90YWwgZXBzaWxvbiBidWRnZXQgZm9yIGFsbCBxdWVyaWVzIGFnYWluc3QgdGhl
CiBwcml2YWN5LXByb3RlY3RlZCB2aWV3LiBFYWNoIHN1YnNjcmliZXIgcXVlcnkgYWdhaW5z
dCB0aGlzIHZpZXcgY2hhcmdlcyB0aGUKIGFtb3VudCBvZiBlcHNpbG9uIHRoZXkgcmVxdWVz
dCBpbiB0aGVpciBxdWVyeS4gSWYgdGhlcmUgaXMgc3VmZmljaWVudAogYnVkZ2V0LCB0aGVu
IHRoZSBzdWJzY3JpYmVyIHF1ZXJ5IGF0dGVtcHRzIHRvIGNvbXBsZXRlLiBJdCBtaWdodCBz
dGlsbCBmYWlsCiBkdWUgdG8gb3RoZXIgcmVhc29ucywgaW4gd2hpY2ggY2FzZSB0aGUgY2hh
cmdlIGlzIHJlZnVuZGVkLiBJZiB0aGVyZSBpcwogaW5zdWZmaWNpZW50IGJ1ZGdldCB0aGUg
cXVlcnkgaXMgcmVqZWN0ZWQuIFRoZXJlIG1pZ2h0IGJlIG11bHRpcGxlIGNoYXJnZQogYXR0
ZW1wdHMgaWYgYSBzaW5nbGUgcXVlcnkgcmVmZXJlbmNlcyBtdWx0aXBsZSB2aWV3cy4gSW4g
dGhpcyBjYXNlIHRoZXJlCiBtdXN0IGJlIHN1ZmZpY2llbnQgYnVkZ2V0IGZvciBhbGwgY2hh
cmdlcyBvciB0aGUgcXVlcnkgaXMgcmVqZWN0ZWQgYW5kCiBjaGFyZ2VzIGFyZSByZWZ1bmRl
ZCBpbiBiZXN0IGVmZm9ydC4gVGhlIGJ1ZGdldCBkb2VzIG5vdCBoYXZlIGEgcmVmcmVzaAog
cG9saWN5IGFuZCBjYW4gb25seSBiZSB1cGRhdGVkIHZpYSBBTFRFUiBWSUVXIG9yIGNpcmN1
bXZlbnRlZCBieSBjcmVhdGluZyBhCiBuZXcgdmlldyB0aGF0IGNhbiBiZSBxdWVyaWVkIHdp
dGggYSBmcmVzaCBidWRnZXQuCgoMCgUEAQIEBBIDTwIKCgwKBQQBAgQFEgNPCxEKDAoFBAEC
BAESA08SIAoMCgUEAQIEAxIDTyMkCgwKBQQBAgQIEgNPJU0KDwoIBAECBAicCAASA08mTArX
BgoEBAECBRIDXQJMGskGIE9wdGlvbmFsLiBUaGUgdG90YWwgZGVsdGEgYnVkZ2V0IGZvciBh
bGwgcXVlcmllcyBhZ2FpbnN0IHRoZQogcHJpdmFjeS1wcm90ZWN0ZWQgdmlldy4gRWFjaCBz
dWJzY3JpYmVyIHF1ZXJ5IGFnYWluc3QgdGhpcyB2aWV3IGNoYXJnZXMgdGhlCiBhbW91bnQg
b2YgZGVsdGEgdGhhdCBpcyBwcmUtZGVmaW5lZCBieSB0aGUgY29udHJpYnV0b3IgdGhyb3Vn
aCB0aGUgcHJpdmFjeQogcG9saWN5IGRlbHRhX3Blcl9xdWVyeSBmaWVsZC4gSWYgdGhlcmUg
aXMgc3VmZmljaWVudCBidWRnZXQsIHRoZW4gdGhlCiBzdWJzY3JpYmVyIHF1ZXJ5IGF0dGVt
cHRzIHRvIGNvbXBsZXRlLiBJdCBtaWdodCBzdGlsbCBmYWlsIGR1ZSB0byBvdGhlcgogcmVh
c29ucywgaW4gd2hpY2ggY2FzZSB0aGUgY2hhcmdlIGlzIHJlZnVuZGVkLiBJZiB0aGVyZSBp
cyBpbnN1ZmZpY2llbnQKIGJ1ZGdldCB0aGUgcXVlcnkgaXMgcmVqZWN0ZWQuIFRoZXJlIG1p
Z2h0IGJlIG11bHRpcGxlIGNoYXJnZSBhdHRlbXB0cyBpZiBhCiBzaW5nbGUgcXVlcnkgcmVm
ZXJlbmNlcyBtdWx0aXBsZSB2aWV3cy4gSW4gdGhpcyBjYXNlIHRoZXJlIG11c3QgYmUKIHN1
ZmZpY2llbnQgYnVkZ2V0IGZvciBhbGwgY2hhcmdlcyBvciB0aGUgcXVlcnkgaXMgcmVqZWN0
ZWQgYW5kIGNoYXJnZXMgYXJlCiByZWZ1bmRlZCBpbiBiZXN0IGVmZm9ydC4gVGhlIGJ1ZGdl
dCBkb2VzIG5vdCBoYXZlIGEgcmVmcmVzaCBwb2xpY3kgYW5kIGNhbgogb25seSBiZSB1cGRh
dGVkIHZpYSBBTFRFUiBWSUVXIG9yIGNpcmN1bXZlbnRlZCBieSBjcmVhdGluZyBhIG5ldyB2
aWV3IHRoYXQKIGNhbiBiZSBxdWVyaWVkIHdpdGggYSBmcmVzaCBidWRnZXQuCgoMCgUEAQIF
BBIDXQIKCgwKBQQBAgUFEgNdCxEKDAoFBAECBQESA10SHgoMCgUEAQIFAxIDXSEiCgwKBQQB
AgUIEgNdI0sKDwoIBAECBQicCAASA10kSgrLAgoEBAECBhIEZAJlMhq8AiBPdXRwdXQgb25s
eS4gVGhlIGVwc2lsb24gYnVkZ2V0IHJlbWFpbmluZy4gSWYgYnVkZ2V0IGlzIGV4aGF1c3Rl
ZCwgbm8gbW9yZQogcXVlcmllcyBhcmUgYWxsb3dlZC4gTm90ZSB0aGF0IHRoZSBidWRnZXQg
Zm9yIHF1ZXJpZXMgdGhhdCBhcmUgaW4gcHJvZ3Jlc3MKIGlzIGRlZHVjdGVkIGJlZm9yZSB0
aGUgcXVlcnkgZXhlY3V0ZXMuIElmIHRoZSBxdWVyeSBmYWlscyBvciBpcyBjYW5jZWxsZWQK
IHRoZW4gdGhlIGJ1ZGdldCBpcyByZWZ1bmRlZC4gSW4gdGhpcyBjYXNlIHRoZSBhbW91bnQg
b2YgYnVkZ2V0IHJlbWFpbmluZwogY2FuIGluY3JlYXNlLgoKDAoFBAECBgQSA2QCCgoMCgUE
AQIGBRIDZAsRCgwKBQQBAgYBEgNkEioKDAoFBAECBgMSA2QtLgoMCgUEAQIGCBIDZQYxCg8K
CAQBAgYInAgAEgNlBzAKyQIKBAQBAgcSBGwCbTIaugIgT3V0cHV0IG9ubHkuIFRoZSBkZWx0
YSBidWRnZXQgcmVtYWluaW5nLiBJZiBidWRnZXQgaXMgZXhoYXVzdGVkLCBubyBtb3JlCiBx
dWVyaWVzIGFyZSBhbGxvd2VkLiBOb3RlIHRoYXQgdGhlIGJ1ZGdldCBmb3IgcXVlcmllcyB0
aGF0IGFyZSBpbiBwcm9ncmVzcwogaXMgZGVkdWN0ZWQgYmVmb3JlIHRoZSBxdWVyeSBleGVj
dXRlcy4gSWYgdGhlIHF1ZXJ5IGZhaWxzIG9yIGlzIGNhbmNlbGxlZAogdGhlbiB0aGUgYnVk
Z2V0IGlzIHJlZnVuZGVkLiBJbiB0aGlzIGNhc2UgdGhlIGFtb3VudCBvZiBidWRnZXQgcmVt
YWluaW5nCiBjYW4gaW5jcmVhc2UuCgoMCgUEAQIHBBIDbAIKCgwKBQQBAgcFEgNsCxEKDAoF
BAECBwESA2wSKAoMCgUEAQIHAxIDbCssCgwKBQQBAgcIEgNtBjEKDwoIBAECBwicCAASA20H
MArlAQoCBAISBXMAkQEBGtcBIFJlcHJlc2VudHMgcHJpdmFjeSBwb2xpY3kgYXNzb2NpYXRl
ZCB3aXRoICJqb2luIHJlc3RyaWN0aW9ucyIuIEpvaW4KIHJlc3RyaWN0aW9uIGdpdmVzIGRh
dGEgcHJvdmlkZXJzIHRoZSBhYmlsaXR5IHRvIGVuZm9yY2Ugam9pbnMgb24gdGhlCiAnam9p
bl9hbGxvd2VkX2NvbHVtbnMnIHdoZW4gZGF0YSBpcyBxdWVyaWVkIGZyb20gYSBwcml2YWN5
IHByb3RlY3RlZCB2aWV3LgoKCgoDBAIBEgNzCB0KMwoEBAIEABIFdQKFAQMaJCBFbnVtIGZv
ciBKb2luIFJlc3RyaWN0aW9ucyBwb2xpY3kuCgoMCgUEAgQAARIDdQcUClgKBgQCBAACABID
dwQjGkkgQSBqb2luIGlzIG5laXRoZXIgcmVxdWlyZWQgbm9yIHJlc3RyaWN0ZWQgb24gYW55
IGNvbHVtbi4gRGVmYXVsdCB2YWx1ZS4KCg4KBwQCBAACAAESA3cEHgoOCgcEAgQAAgACEgN3
ISIKTQoGBAIEAAIBEgN6BBEaPiBBIGpvaW4gaXMgcmVxdWlyZWQgb24gYXQgbGVhc3Qgb25l
IG9mIHRoZSBzcGVjaWZpZWQgY29sdW1ucy4KCg4KBwQCBAACAQESA3oEDAoOCgcEAgQAAgEC
EgN6DxAKPQoGBAIEAAICEgN9BBEaLiBBIGpvaW4gaXMgcmVxdWlyZWQgb24gYWxsIHNwZWNp
ZmllZCBjb2x1bW5zLgoKDgoHBAIEAAICARIDfQQMCg4KBwQCBAACAgISA30PEApoCgYEAgQA
AgMSBIEBBBoaWCBBIGpvaW4gaXMgbm90IHJlcXVpcmVkLCBidXQgaWYgcHJlc2VudCBpdCBp
cyBvbmx5IHBlcm1pdHRlZCBvbgogJ2pvaW5fYWxsb3dlZF9jb2x1bW5zJwoKDwoHBAIEAAID
ARIEgQEEFQoPCgcEAgQAAgMCEgSBARgZCjQKBgQCBAACBBIEhAEEFRokIEpvaW5zIGFyZSBi
bG9ja2VkIGZvciBhbGwgcXVlcmllcy4KCg8KBwQCBAACBAESBIQBBBAKDwoHBAIEAAIEAhIE
hAETFAqDAQoEBAICABIGiQECigEvGnMgT3B0aW9uYWwuIFNwZWNpZmllcyBpZiBhIGpvaW4g
aXMgcmVxdWlyZWQgb3Igbm90IG9uIHF1ZXJpZXMgZm9yIHRoZSB2aWV3LgogRGVmYXVsdCBp
cyBKT0lOX0NPTkRJVElPTl9VTlNQRUNJRklFRC4KCg0KBQQCAgAEEgSJAQIKCg0KBQQCAgAG
EgSJAQsYCg0KBQQCAgABEgSJARknCg0KBQQCAgADEgSJASorCg0KBQQCAgAIEgSKAQYuChAK
CAQCAgAInAgAEgSKAQctCrsBCgQEAgIBEgaPAQKQAS8aqgEgT3B0aW9uYWwuIFRoZSBvbmx5
IGNvbHVtbnMgdGhhdCBqb2lucyBhcmUgYWxsb3dlZCBvbi4KIFRoaXMgZmllbGQgaXMgbXVz
dCBiZSBzcGVjaWZpZWQgZm9yIGpvaW5fY29uZGl0aW9ucyBKT0lOX0FOWSBhbmQgSk9JTl9B
TEwKIGFuZCBpdCBjYW5ub3QgYmUgc2V0IGZvciBKT0lOX0JMT0NLRUQuCgoNCgUEAgIBBBIE
jwECCgoNCgUEAgIBBRIEjwELEQoNCgUEAgIBARIEjwESJgoNCgUEAgIBAxIEjwEpKgoNCgUE
AgIBCBIEkAEGLgoQCggEAgIBCJwIABIEkAEHLQqbAQoCBAMSBpUBAKgBARqMASBSZXByZXNl
bnRzIHByaXZhY3kgcG9saWN5IHRoYXQgY29udGFpbnMgdGhlIHByaXZhY3kgcmVxdWlyZW1l
bnRzIHNwZWNpZmllZCBieQogdGhlIGRhdGEgb3duZXIuIEN1cnJlbnRseSwgdGhpcyBpcyBv
bmx5IHN1cHBvcnRlZCBvbiB2aWV3cy4KCgsKAwQDARIElQEIFQqVAQoEBAMIABIGmAECoAED
GoQBIFByaXZhY3kgcG9saWN5IGFzc29jaWF0ZWQgd2l0aCB0aGlzIHJlcXVpcmVtZW50IHNw
ZWNpZmljYXRpb24uIE9ubHkgb25lIG9mCiB0aGUgcHJpdmFjeSBtZXRob2RzIGlzIGFsbG93
ZWQgcGVyIGRhdGEgc291cmNlIG9iamVjdC4KCg0KBQQDCAABEgSYAQgWCkMKBAQDAgASBpoB
BJsBMRozIE9wdGlvbmFsLiBQb2xpY3kgdXNlZCBmb3IgYWdncmVnYXRpb24gdGhyZXNob2xk
cy4KCg0KBQQDAgAGEgSaAQQeCg0KBQQDAgABEgSaAR87Cg0KBQQDAgADEgSaAT4/Cg0KBQQD
AgAIEgSbAQgwChAKCAQDAgAInAgAEgSbAQkvCkEKBAQDAgESBp4BBJ8BMRoxIE9wdGlvbmFs
LiBQb2xpY3kgdXNlZCBmb3IgZGlmZmVyZW50aWFsIHByaXZhY3kuCgoNCgUEAwIBBhIEngEE
HQoNCgUEAwIBARIEngEeOQoNCgUEAwIBAxIEngE8PQoNCgUEAwIBCBIEnwEIMAoQCggEAwIB
CJwIABIEnwEJLwqiAgoEBAMCAhIGpgECpwEvGpECIE9wdGlvbmFsLiBKb2luIHJlc3RyaWN0
aW9uIHBvbGljeSBpcyBvdXRzaWRlIG9mIHRoZSBvbmUgb2YgcG9saWNpZXMsIHNpbmNlCiB0
aGlzIHBvbGljeSBjYW4gYmUgc2V0IGFsb25nIHdpdGggb3RoZXIgcG9saWNpZXMuIFRoaXMg
cG9saWN5IGdpdmVzIGRhdGEKIHByb3ZpZGVycyB0aGUgYWJpbGl0eSB0byBlbmZvcmNlIGpv
aW5zIG9uIHRoZSAnam9pbl9hbGxvd2VkX2NvbHVtbnMnIHdoZW4KIGRhdGEgaXMgcXVlcmll
ZCBmcm9tIGEgcHJpdmFjeSBwcm90ZWN0ZWQgdmlldy4KCg0KBQQDAgIEEgSmAQIKCg0KBQQD
AgIGEgSmAQsgCg0KBQQDAgIBEgSmASE4Cg0KBQQDAgIDEgSmATs8Cg0KBQQDAgIIEgSnAQYu
ChAKCAQDAgIInAgAEgSnAQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy ===
    # Fields for AggregationThresholdPolicy
    # Field: threshold Type: 3 ()
    # Field: privacy_unit_columns Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::PrivacyPolicy::DifferentialPrivacyPolicy ===
    # Fields for DifferentialPrivacyPolicy
    # Field: max_epsilon_per_query Type: 1 ()
    # Field: delta_per_query Type: 1 ()
    # Field: max_groups_contributed Type: 3 ()
    # Field: privacy_unit_column Type: 9 ()
    # Field: epsilon_budget Type: 1 ()
    # Field: delta_budget Type: 1 ()
    # Field: epsilon_budget_remaining Type: 1 ()
    # Field: delta_budget_remaining Type: 1 ()

# === Message: Google::Cloud::Bigquery::V2::PrivacyPolicy::JoinRestrictionPolicy ===
    # Fields for JoinRestrictionPolicy
    # Field: join_condition Type: 14 (.google.cloud.bigquery.v2.JoinRestrictionPolicy.JoinCondition)
    # Field: join_allowed_columns Type: 9 ()

# Enum: JoinRestrictionPolicy::JoinCondition
our $JoinRestrictionPolicy_JOIN_CONDITION_UNSPECIFIED = 0;
our $JoinRestrictionPolicy_JOIN_ANY = 1;
our $JoinRestrictionPolicy_JOIN_ALL = 2;
our $JoinRestrictionPolicy_JOIN_NOT_REQUIRED = 3;
our $JoinRestrictionPolicy_JOIN_BLOCKED = 4;

# === Message: Google::Cloud::Bigquery::V2::PrivacyPolicy::PrivacyPolicy ===
    # Fields for PrivacyPolicy
    # Field: aggregation_threshold_policy Type: 11 (.google.cloud.bigquery.v2.AggregationThresholdPolicy)
    # Field: differential_privacy_policy Type: 11 (.google.cloud.bigquery.v2.DifferentialPrivacyPolicy)
    # Field: join_restriction_policy Type: 11 (.google.cloud.bigquery.v2.JoinRestrictionPolicy)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::PrivacyPolicy - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/privacy_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::PrivacyPolicy;

    my $msg = Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy->new({
        threshold => $threshold,
        privacy_unit_columns => $privacy_unit_columns,
    });

    # Read or update a field
    my $val = $msg->threshold();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/privacy_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy

Represents privacy policy associated with "aggregation threshold" method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Int64>

Optional. The threshold for the "aggregation threshold" policy.

=item * C<< $msg->privacy_unit_columns() >> / C<< $msg->privacy_unit_columns($value) >>

Type: C<String>

Optional. The privacy unit column(s) associated with this policy.
For now, only one column per data source object (table, view) is allowed as
a privacy unit column.
Representing as a repeated field in metadata for extensibility to
multiple columns in future.
Duplicates and Repeated struct fields are not allowed.
For nested fields, use dot notation ("outer.inner")

=back

=head2 Google::Cloud::Bigquery::V2::PrivacyPolicy::DifferentialPrivacyPolicy

Represents privacy policy associated with "differential privacy" method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->max_epsilon_per_query() >> / C<< $msg->max_epsilon_per_query($value) >>

Type: C<Double>

Optional. The maximum epsilon value that a query can consume. If the
subscriber specifies epsilon as a parameter in a SELECT query, it must be
less than or equal to this value. The epsilon parameter controls the amount
of noise that is added to the groups — a higher epsilon means less noise.

=item * C<< $msg->delta_per_query() >> / C<< $msg->delta_per_query($value) >>

Type: C<Double>

Optional. The delta value that is used per query. Delta represents the
probability that any row will fail to be epsilon differentially private.
Indicates the risk associated with exposing aggregate rows in the result of
a query.

=item * C<< $msg->max_groups_contributed() >> / C<< $msg->max_groups_contributed($value) >>

Type: C<Int64>

Optional. The maximum groups contributed value that is used per query.
Represents the maximum number of groups to which each protected entity can
contribute. Changing this value does not improve or worsen privacy. The
best value for accuracy and utility depends on the query and data.

=item * C<< $msg->privacy_unit_column() >> / C<< $msg->privacy_unit_column($value) >>

Type: C<String>

Optional. The privacy unit column associated with this policy. Differential
privacy policies can only have one privacy unit column per data source
object (table, view).

=item * C<< $msg->epsilon_budget() >> / C<< $msg->epsilon_budget($value) >>

Type: C<Double>

Optional. The total epsilon budget for all queries against the
privacy-protected view. Each subscriber query against this view charges the
amount of epsilon they request in their query. If there is sufficient
budget, then the subscriber query attempts to complete. It might still fail
due to other reasons, in which case the charge is refunded. If there is
insufficient budget the query is rejected. There might be multiple charge
attempts if a single query references multiple views. In this case there
must be sufficient budget for all charges or the query is rejected and
charges are refunded in best effort. The budget does not have a refresh
policy and can only be updated via ALTER VIEW or circumvented by creating a
new view that can be queried with a fresh budget.

=item * C<< $msg->delta_budget() >> / C<< $msg->delta_budget($value) >>

Type: C<Double>

Optional. The total delta budget for all queries against the
privacy-protected view. Each subscriber query against this view charges the
amount of delta that is pre-defined by the contributor through the privacy
policy delta_per_query field. If there is sufficient budget, then the
subscriber query attempts to complete. It might still fail due to other
reasons, in which case the charge is refunded. If there is insufficient
budget the query is rejected. There might be multiple charge attempts if a
single query references multiple views. In this case there must be
sufficient budget for all charges or the query is rejected and charges are
refunded in best effort. The budget does not have a refresh policy and can
only be updated via ALTER VIEW or circumvented by creating a new view that
can be queried with a fresh budget.

=item * C<< $msg->epsilon_budget_remaining() >> / C<< $msg->epsilon_budget_remaining($value) >>

Type: C<Double>

Output only. The epsilon budget remaining. If budget is exhausted, no more
queries are allowed. Note that the budget for queries that are in progress
is deducted before the query executes. If the query fails or is cancelled
then the budget is refunded. In this case the amount of budget remaining
can increase.

=item * C<< $msg->delta_budget_remaining() >> / C<< $msg->delta_budget_remaining($value) >>

Type: C<Double>

Output only. The delta budget remaining. If budget is exhausted, no more
queries are allowed. Note that the budget for queries that are in progress
is deducted before the query executes. If the query fails or is cancelled
then the budget is refunded. In this case the amount of budget remaining
can increase.

=back

=head2 Google::Cloud::Bigquery::V2::PrivacyPolicy::JoinRestrictionPolicy

Represents privacy policy associated with "join restrictions". Join
restriction gives data providers the ability to enforce joins on the
'join_allowed_columns' when data is queried from a privacy protected view.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->join_condition() >> / C<< $msg->join_condition($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::JoinRestrictionPolicy::JoinCondition>)

Optional. Specifies if a join is required or not on queries for the view.
Default is JOIN_CONDITION_UNSPECIFIED.

=item * C<< $msg->join_allowed_columns() >> / C<< $msg->join_allowed_columns($value) >>

Type: C<String>

Optional. The only columns that joins are allowed on.
This field is must be specified for join_conditions JOIN_ANY and JOIN_ALL
and it cannot be set for JOIN_BLOCKED.

=back

=head3 Enum: JoinRestrictionPolicy::JoinCondition

=over 4

=item * C<JOIN_CONDITION_UNSPECIFIED> => C<0>

=item * C<JOIN_ANY> => C<1>

=item * C<JOIN_ALL> => C<2>

=item * C<JOIN_NOT_REQUIRED> => C<3>

=item * C<JOIN_BLOCKED> => C<4>

=back

=head2 Google::Cloud::Bigquery::V2::PrivacyPolicy::PrivacyPolicy

Represents privacy policy that contains the privacy requirements specified by
the data owner. Currently, this is only supported on views.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->aggregation_threshold_policy() >> / C<< $msg->aggregation_threshold_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy>)

Optional. Policy used for aggregation thresholds.

=item * C<< $msg->differential_privacy_policy() >> / C<< $msg->differential_privacy_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::PrivacyPolicy::DifferentialPrivacyPolicy>)

Optional. Policy used for differential privacy.

=item * C<< $msg->join_restriction_policy() >> / C<< $msg->join_restriction_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::PrivacyPolicy::JoinRestrictionPolicy>)

Optional. Join restriction policy is outside of the one of policies, since
this policy can be set along with other policies. This policy gives data
providers the ability to enforce joins on the 'join_allowed_columns' when
data is queried from a privacy protected view.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::PrivacyPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
