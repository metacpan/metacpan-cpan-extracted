package Google::Cloud::Cloudcontrolspartner::V1::Core;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests };
    eval { require Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads };
    eval { require Google::Cloud::Cloudcontrolspartner::V1::Customers };
    eval { require Google::Cloud::Cloudcontrolspartner::V1::EkmConnections };
    eval { require Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions };
    eval { require Google::Cloud::Cloudcontrolspartner::V1::Partners };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvY29yZS5wcm90bxIkZ29v
Z2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxpDZ29vZ2xlL2Nsb3Vk
L2Nsb3VkY29udHJvbHNwYXJ0bmVyL3YxL2FjY2Vzc19hcHByb3ZhbF9yZXF1ZXN0cy5wcm90
bxo9Z29vZ2xlL2Nsb3VkL2Nsb3VkY29udHJvbHNwYXJ0bmVyL3YxL2N1c3RvbWVyX3dvcmts
b2Fkcy5wcm90bxo0Z29vZ2xlL2Nsb3VkL2Nsb3VkY29udHJvbHNwYXJ0bmVyL3YxL2N1c3Rv
bWVycy5wcm90bxo6Z29vZ2xlL2Nsb3VkL2Nsb3VkY29udHJvbHNwYXJ0bmVyL3YxL2VrbV9j
b25uZWN0aW9ucy5wcm90bxo+Z29vZ2xlL2Nsb3VkL2Nsb3VkY29udHJvbHNwYXJ0bmVyL3Yx
L3BhcnRuZXJfcGVybWlzc2lvbnMucHJvdG8aM2dvb2dsZS9jbG91ZC9jbG91ZGNvbnRyb2xz
cGFydG5lci92MS9wYXJ0bmVycy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItUCChFPcGVyYXRpb25NZXRhZGF0
YRJACgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKY3JlYXRlVGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IHZW5kVGltZRIbCgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZl
cmIYBCABKAlCA+BBA1IEdmVyYhIqCg5zdGF0dXNfbWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0
dXNNZXNzYWdlEjoKFnJlcXVlc3RlZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVz
dGVkQ2FuY2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9uGAcgASgJQgPgQQNSCmFwaVZlcnNpb24y
0xMKGENsb3VkQ29udHJvbHNQYXJ0bmVyQ29yZRLGAQoLR2V0V29ya2xvYWQSOC5nb29nbGUu
Y2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuR2V0V29ya2xvYWRSZXF1ZXN0Gi4uZ29v
Z2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLldvcmtsb2FkIk2C0+STAkASPi92
MS97bmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyovY3VzdG9tZXJzLyovd29ya2xv
YWRzLyp92kEEbmFtZRLZAQoNTGlzdFdvcmtsb2FkcxI6Lmdvb2dsZS5jbG91ZC5jbG91ZGNv
bnRyb2xzcGFydG5lci52MS5MaXN0V29ya2xvYWRzUmVxdWVzdBo7Lmdvb2dsZS5jbG91ZC5j
bG91ZGNvbnRyb2xzcGFydG5lci52MS5MaXN0V29ya2xvYWRzUmVzcG9uc2UiT4LT5JMCQBI+
L3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2N1c3RvbWVycy8qfS93
b3JrbG9hZHPaQQZwYXJlbnQSugEKC0dldEN1c3RvbWVyEjguZ29vZ2xlLmNsb3VkLmNsb3Vk
Y29udHJvbHNwYXJ0bmVyLnYxLkdldEN1c3RvbWVyUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5j
bG91ZGNvbnRyb2xzcGFydG5lci52MS5DdXN0b21lciJBgtPkkwI0EjIvdjEve25hbWU9b3Jn
YW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2N1c3RvbWVycy8qfdpBBG5hbWUSzQEKDUxpc3RD
dXN0b21lcnMSOi5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuTGlzdEN1
c3RvbWVyc1JlcXVlc3QaOy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEu
TGlzdEN1c3RvbWVyc1Jlc3BvbnNlIkOC0+STAjQSMi92MS97cGFyZW50PW9yZ2FuaXphdGlv
bnMvKi9sb2NhdGlvbnMvKn0vY3VzdG9tZXJz2kEGcGFyZW50EucBChFHZXRFa21Db25uZWN0
aW9ucxI+Lmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5HZXRFa21Db25u
ZWN0aW9uc1JlcXVlc3QaNC5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEu
RWttQ29ubmVjdGlvbnMiXILT5JMCTxJNL3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2Nh
dGlvbnMvKi9jdXN0b21lcnMvKi93b3JrbG9hZHMvKi9la21Db25uZWN0aW9uc33aQQRuYW1l
EvcBChVHZXRQYXJ0bmVyUGVybWlzc2lvbnMSQi5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9s
c3BhcnRuZXIudjEuR2V0UGFydG5lclBlcm1pc3Npb25zUmVxdWVzdBo4Lmdvb2dsZS5jbG91
ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5QYXJ0bmVyUGVybWlzc2lvbnMiYILT5JMCUxJR
L3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9jdXN0b21lcnMvKi93b3Jr
bG9hZHMvKi9wYXJ0bmVyUGVybWlzc2lvbnN92kEEbmFtZRKcAgoaTGlzdEFjY2Vzc0FwcHJv
dmFsUmVxdWVzdHMSRy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuTGlz
dEFjY2Vzc0FwcHJvdmFsUmVxdWVzdHNSZXF1ZXN0GkguZ29vZ2xlLmNsb3VkLmNsb3VkY29u
dHJvbHNwYXJ0bmVyLnYxLkxpc3RBY2Nlc3NBcHByb3ZhbFJlcXVlc3RzUmVzcG9uc2Uia4gC
AYLT5JMCWRJXL3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2N1c3Rv
bWVycy8qL3dvcmtsb2Fkcy8qfS9hY2Nlc3NBcHByb3ZhbFJlcXVlc3Rz2kEGcGFyZW50ErMB
CgpHZXRQYXJ0bmVyEjcuZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLkdl
dFBhcnRuZXJSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYx
LlBhcnRuZXIiPYLT5JMCMBIuL3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMv
Ki9wYXJ0bmVyfdpBBG5hbWUS4QEKDkNyZWF0ZUN1c3RvbWVyEjsuZ29vZ2xlLmNsb3VkLmNs
b3VkY29udHJvbHNwYXJ0bmVyLnYxLkNyZWF0ZUN1c3RvbWVyUmVxdWVzdBouLmdvb2dsZS5j
bG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5DdXN0b21lciJigtPkkwI+IjIvdjEve3Bh
cmVudD1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyp9L2N1c3RvbWVyczoIY3VzdG9tZXLa
QRtwYXJlbnQsY3VzdG9tZXIsY3VzdG9tZXJfaWQS4wEKDlVwZGF0ZUN1c3RvbWVyEjsuZ29v
Z2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLlVwZGF0ZUN1c3RvbWVyUmVxdWVz
dBouLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5DdXN0b21lciJkgtPk
kwJHMjsvdjEve2N1c3RvbWVyLm5hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2N1
c3RvbWVycy8qfToIY3VzdG9tZXLaQRRjdXN0b21lcix1cGRhdGVfbWFzaxKoAQoORGVsZXRl
Q3VzdG9tZXISOy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuRGVsZXRl
Q3VzdG9tZXJSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkGC0+STAjQqMi92MS97
bmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyovY3VzdG9tZXJzLyp92kEEbmFtZRpX
ykEjY2xvdWRjb250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQv0CCihjb20uZ29vZ2xlLmNsb3Vk
LmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxQglDb3JlUHJvdG9QAVpcY2xvdWQuZ29vZ2xlLmNv
bS9nby9jbG91ZGNvbnRyb2xzcGFydG5lci9hcGl2MS9jbG91ZGNvbnRyb2xzcGFydG5lcnBi
O2Nsb3VkY29udHJvbHNwYXJ0bmVycGKqAiRHb29nbGUuQ2xvdWQuQ2xvdWRDb250cm9sc1Bh
cnRuZXIuVjHKAiRHb29nbGVcQ2xvdWRcQ2xvdWRDb250cm9sc1BhcnRuZXJcVjHqAidHb29n
bGU6OkNsb3VkOjpDbG91ZENvbnRyb2xzUGFydG5lcjo6VjHqQW0KOGNsb3VkY29udHJvbHNw
YXJ0bmVyLmdvb2dsZWFwaXMuY29tL09yZ2FuaXphdGlvbkxvY2F0aW9uEjFvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259So8iCgcSBQ4ArAEBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACYK
CQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYATQoJCgIDBRIDFwBH
CgkKAgMGEgMYAD4KCQoCAwcSAxkARAoJCgIDCBIDGgBICgkKAgMJEgMbAD0KCQoCAwoSAxwA
JQoJCgIDCxIDHQApCggKAQgSAx8AQQoJCgIIJRIDHwBBCggKAQgSAyAAcwoJCgIICxIDIABz
CggKAQgSAyEAIgoJCgIIChIDIQAiCggKAQgSAyIAKgoJCgIICBIDIgAqCggKAQgSAyMAQQoJ
CgIIARIDIwBBCggKAQgSAyQAQQoJCgIIKRIDJABBCggKAQgSAyUAQAoJCgIILRIDJQBACgkK
AQgSBCYAKQIKDAoECJ0IABIEJgApAgo4CgIGABIFLACOAQEaKyBTZXJ2aWNlIGRlc2NyaWJp
bmcgaGFuZGxlcnMgZm9yIHJlc291cmNlcwoKCgoDBgABEgMsCCAKCgoDBgADEgMtAksKDAoF
BgADmQgSAy0CSwoLCgMGAAMSBC4CLzcKDQoFBgADmggSBC4CLzcKMQoEBgACABIEMgI3Axoj
IEdldHMgZGV0YWlscyBvZiBhIHNpbmdsZSB3b3JrbG9hZAoKDAoFBgACAAESAzIGEQoMCgUG
AAIAAhIDMhIkCgwKBQYAAgADEgMyLzcKDQoFBgACAAQSBDMENQYKEQoJBgACAASwyrwiEgQz
BDUGCgwKBQYAAgAEEgM2BDIKDwoIBgACAASbCAASAzYEMgpECgQGAAIBEgQ6Aj8DGjYgTGlz
dHMgY3VzdG9tZXIgd29ya2xvYWRzIGZvciBhIGdpdmVuIGN1c3RvbWVyIG9yZyBpZAoKDAoF
BgACAQESAzoGEwoMCgUGAAIBAhIDOhQoCgwKBQYAAgEDEgM6M0gKDQoFBgACAQQSBDsEPQYK
EQoJBgACAQSwyrwiEgQ7BD0GCgwKBQYAAgEEEgM+BDQKDwoIBgACAQSbCAASAz4ENAoxCgQG
AAICEgRCAkcDGiMgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIGN1c3RvbWVyCgoMCgUGAAIC
ARIDQgYRCgwKBQYAAgICEgNCEiQKDAoFBgACAgMSA0IvNwoNCgUGAAICBBIEQwRFBgoRCgkG
AAICBLDKvCISBEMERQYKDAoFBgACAgQSA0YEMgoPCggGAAICBJsIABIDRgQyClsKBAYAAgMS
BEoCTwMaTSBMaXN0cyBjdXN0b21lcnMgb2YgYSBwYXJ0bmVyIGlkZW50aWZpZWQgYnkgaXRz
IEdvb2dsZSBDbG91ZCBvcmdhbml6YXRpb24gSUQKCgwKBQYAAgMBEgNKBhMKDAoFBgACAwIS
A0oUKAoMCgUGAAIDAxIDSjNICg0KBQYAAgMEEgRLBE0GChEKCQYAAgMEsMq8IhIESwRNBgoM
CgUGAAIDBBIDTgQ0Cg8KCAYAAgMEmwgAEgNOBDQKQwoEBgACBBIEUgJXAxo1IEdldHMgdGhl
IEVLTSBjb25uZWN0aW9ucyBhc3NvY2lhdGVkIHdpdGggYSB3b3JrbG9hZAoKDAoFBgACBAES
A1IGFwoMCgUGAAIEAhIDUhgwCgwKBQYAAgQDEgNSO0kKDQoFBgACBAQSBFMEVQYKEQoJBgAC
BASwyrwiEgRTBFUGCgwKBQYAAgQEEgNWBDIKDwoIBgACBASbCAASA1YEMgpDCgQGAAIFEgRa
AmADGjUgR2V0cyB0aGUgcGFydG5lciBwZXJtaXNzaW9ucyBncmFudGVkIGZvciBhIHdvcmts
b2FkCgoMCgUGAAIFARIDWgYbCgwKBQYAAgUCEgNaHDgKDAoFBgACBQMSA1sPIQoNCgUGAAIF
BBIEXAReBgoRCgkGAAIFBLDKvCISBFwEXgYKDAoFBgACBQQSA18EMgoPCggGAAIFBJsIABID
XwQyCncKBAYAAgYSBGQCawMaaSBEZXByZWNhdGVkOiBPbmx5IHJldHVybnMgYWNjZXNzIGFw
cHJvdmFsIHJlcXVlc3RzIGRpcmVjdGx5IGFzc29jaWF0ZWQgd2l0aAogYW4gYXNzdXJlZCB3
b3JrbG9hZCBmb2xkZXIuCgoMCgUGAAIGARIDZAYgCgwKBQYAAgYCEgNkIUIKDAoFBgACBgMS
A2UPMQoMCgUGAAIGBBIDZgQdCg0KBgYAAgYEIRIDZgQdCg0KBQYAAgYEEgRnBGkGChEKCQYA
AgYEsMq8IhIEZwRpBgoMCgUGAAIGBBIDagQ0Cg8KCAYAAgYEmwgAEgNqBDQKKQoEBgACBxIE
bgJzAxobIEdldCBkZXRhaWxzIG9mIGEgUGFydG5lci4KCgwKBQYAAgcBEgNuBhAKDAoFBgAC
BwISA24RIgoMCgUGAAIHAxIDbi00Cg0KBQYAAgcEEgRvBHEGChEKCQYAAgcEsMq8IhIEbwRx
BgoMCgUGAAIHBBIDcgQyCg8KCAYAAgcEmwgAEgNyBDIKJwoEBgACCBIEdgJ8AxoZIENyZWF0
ZXMgYSBuZXcgY3VzdG9tZXIuCgoMCgUGAAIIARIDdgYUCgwKBQYAAggCEgN2FSoKDAoFBgAC
CAMSA3Y1PQoNCgUGAAIIBBIEdwR6BgoRCgkGAAIIBLDKvCISBHcEegYKDAoFBgACCAQSA3sE
SQoPCggGAAIIBJsIABIDewRJCjQKBAYAAgkSBX8ChQEDGiUgVXBkYXRlIGRldGFpbHMgb2Yg
YSBzaW5nbGUgY3VzdG9tZXIKCgwKBQYAAgkBEgN/BhQKDAoFBgACCQISA38VKgoMCgUGAAIJ
AxIDfzU9Cg8KBQYAAgkEEgaAAQSDAQYKEwoJBgACCQSwyrwiEgaAAQSDAQYKDQoFBgACCQQS
BIQBBEIKEAoIBgACCQSbCAASBIQBBEIKNQoEBgACChIGiAECjQEDGiUgRGVsZXRlIGRldGFp
bHMgb2YgYSBzaW5nbGUgY3VzdG9tZXIKCg0KBQYAAgoBEgSIAQYUCg0KBQYAAgoCEgSIARUq
Cg0KBQYAAgoDEgSIATVKCg8KBQYAAgoEEgaJAQSLAQYKEwoJBgACCgSwyrwiEgaJAQSLAQYK
DQoFBgACCgQSBIwBBDIKEAoIBgACCgSbCAASBIwBBDIKRgoCBAASBpEBAKwBARo4IFJlcHJl
c2VudHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgoKCwoD
BAABEgSRAQgZCkIKBAQAAgASBpMBApQBMhoyIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUg
b3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDQoFBAACAAYSBJMBAhsKDQoFBAACAAESBJMBHCcK
DQoFBAACAAMSBJMBKisKDQoFBAACAAgSBJQBBjEKEAoIBAACAAicCAASBJQBBzAKRwoEBAAC
ARIGlwECmAEyGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNo
ZWQgcnVubmluZy4KCg0KBQQAAgEGEgSXAQIbCg0KBQQAAgEBEgSXARwkCg0KBQQAAgEDEgSX
AScoCg0KBQQAAgEIEgSYAQYxChAKCAQAAgEInAgAEgSYAQcwCloKBAQAAgISBJsBAkAaTCBP
dXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdl
dCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAACAgUSBJsBAggKDQoFBAACAgESBJsBCQ8KDQoF
BAACAgMSBJsBEhMKDQoFBAACAggSBJsBFD8KEAoIBAACAgicCAASBJsBFT4KSAoEBAACAxIE
ngECPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBv
cGVyYXRpb24uCgoNCgUEAAIDBRIEngECCAoNCgUEAAIDARIEngEJDQoNCgUEAAIDAxIEngEQ
EQoNCgUEAAIDCBIEngESPQoQCggEAAIDCJwIABIEngETPApMCgQEAAIEEgShAQJIGj4gT3V0
cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBh
bnkuCgoNCgUEAAIEBRIEoQECCAoNCgUEAAIEARIEoQEJFwoNCgUEAAIEAxIEoQEaGwoNCgUE
AAIECBIEoQEcRwoQCggEAAIECJwIABIEoQEdRgq9AgoEBAACBRIEqAECThquAiBPdXRwdXQg
b25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2Vs
bGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBiZWVuIGNh
bmNlbGxlZCBzdWNjZXNzZnVsbHkKIGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bZ29vZ2xlLmxv
bmdydW5uaW5nLk9wZXJhdGlvbi5lcnJvcl0gdmFsdWUgd2l0aCBhCiBbZ29vZ2xlLnJwYy5T
dGF0dXMuY29kZV1bZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV0gb2YgMSwgY29ycmVzcG9uZGlu
ZyB0bwogYENvZGUuQ0FOQ0VMTEVEYC4KCg0KBQQAAgUFEgSoAQIGCg0KBQQAAgUBEgSoAQcd
Cg0KBQQAAgUDEgSoASAhCg0KBQQAAgUIEgSoASJNChAKCAQAAgUInAgAEgSoASNMCkUKBAQA
AgYSBKsBAkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNpb24gdXNlZCB0byBzdGFydCB0aGUg
b3BlcmF0aW9uLgoKDQoFBAACBgUSBKsBAggKDQoFBAACBgESBKsBCRQKDQoFBAACBgMSBKsB
FxgKDQoFBAACBggSBKsBGUQKEAoIBAACBgicCAASBKsBGkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Core::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Cloudcontrolspartner::V1::Core::CloudControlsPartnerCoreClient ===
package Google::Cloud::Cloudcontrolspartner::V1::Core::CloudControlsPartnerCoreClient;

=pod

=head2 Service Client: Google::Cloud::Cloudcontrolspartner::V1::Core::CloudControlsPartnerCoreClient

Client stub representing the remote C<CloudControlsPartnerCore> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<cloudcontrolspartner.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'cloudcontrolspartner.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub get_workload {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'GetWorkload',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload',
    });
}

sub list_workloads {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'ListWorkloads',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsResponse',
    });
}

sub get_customer {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Customers::GetCustomerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'GetCustomer',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer',
    });
}

sub list_customers {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'ListCustomers',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersResponse',
    });
}

sub get_ekm_connections {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::GetEkmConnectionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'GetEkmConnections',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections',
    });
}

sub get_partner_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::GetPartnerPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'GetPartnerPermissions',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions',
    });
}

sub list_access_approval_requests {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'ListAccessApprovalRequests',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsResponse',
    });
}

sub get_partner {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Partners::GetPartnerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'GetPartner',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner',
    });
}

sub create_customer {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Customers::CreateCustomerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'CreateCustomer',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer',
    });
}

sub update_customer {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Customers::UpdateCustomerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'UpdateCustomer',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer',
    });
}

sub delete_customer {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Customers::DeleteCustomerRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'DeleteCustomer',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Core - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/core.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::Core;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::Core::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::Core::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/core.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::Core::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have [Operation.error][google.longrunning.Operation.error] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::Core::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
