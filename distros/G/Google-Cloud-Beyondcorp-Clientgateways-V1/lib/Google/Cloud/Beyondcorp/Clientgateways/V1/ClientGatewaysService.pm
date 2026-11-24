package Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ckdnb29nbGUvY2xvdWQvYmV5b25kY29ycC9jbGllbnRnYXRld2F5cy92MS9jbGllbnRfZ2F0
ZXdheXNfc2VydmljZS5wcm90bxIpZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuY2xpZW50Z2F0
ZXdheXMudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xp
ZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byK+BAoNQ2xpZW50R2F0ZXdheRIXCgRu
YW1lGAEgASgJQgPgQQJSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSWQoFc3RhdGUY
BCABKA4yPi5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5jbGllbnRnYXRld2F5cy52MS5DbGll
bnRHYXRld2F5LlN0YXRlQgPgQQNSBXN0YXRlEhMKAmlkGAUgASgJQgPgQQNSAmlkEj0KGGNs
aWVudF9jb25uZWN0b3Jfc2VydmljZRgGIAEoCUID4EEDUhZjbGllbnRDb25uZWN0b3JTZXJ2
aWNlImoKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIMCghV
UERBVElORxACEgwKCERFTEVUSU5HEAMSCwoHUlVOTklORxAEEggKBERPV04QBRIJCgVFUlJP
UhAGOnXqQXIKJ2JleW9uZGNvcnAuZ29vZ2xlYXBpcy5jb20vQ2xpZW50R2F0ZXdheRJHcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsaWVudEdhdGV3YXlzL3tj
bGllbnRfZ2F0ZXdheX0i5wEKGUxpc3RDbGllbnRHYXRld2F5c1JlcXVlc3QSRwoGcGFyZW50
GAEgASgJQi/gQQL6QSkSJ2JleW9uZGNvcnAuZ29vZ2xlYXBpcy5jb20vQ2xpZW50R2F0ZXdh
eVIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rv
a2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVy
Eh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkiyQEKGkxpc3RDbGllbnRHYXRld2F5
c1Jlc3BvbnNlEmEKD2NsaWVudF9nYXRld2F5cxgBIAMoCzI4Lmdvb2dsZS5jbG91ZC5iZXlv
bmRjb3JwLmNsaWVudGdhdGV3YXlzLnYxLkNsaWVudEdhdGV3YXlSDmNsaWVudEdhdGV3YXlz
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJs
ZRgDIAMoCVILdW5yZWFjaGFibGUiXgoXR2V0Q2xpZW50R2F0ZXdheVJlcXVlc3QSQwoEbmFt
ZRgBIAEoCUIv4EEC+kEpCidiZXlvbmRjb3JwLmdvb2dsZWFwaXMuY29tL0NsaWVudEdhdGV3
YXlSBG5hbWUiygIKGkNyZWF0ZUNsaWVudEdhdGV3YXlSZXF1ZXN0EkcKBnBhcmVudBgBIAEo
CUIv4EEC+kEpEidiZXlvbmRjb3JwLmdvb2dsZWFwaXMuY29tL0NsaWVudEdhdGV3YXlSBnBh
cmVudBIvChFjbGllbnRfZ2F0ZXdheV9pZBgCIAEoCUID4EEBUg9jbGllbnRHYXRld2F5SWQS
ZAoOY2xpZW50X2dhdGV3YXkYAyABKAsyOC5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5jbGll
bnRnYXRld2F5cy52MS5DbGllbnRHYXRld2F5QgPgQQJSDWNsaWVudEdhdGV3YXkSIgoKcmVx
dWVzdF9pZBgEIAEoCUID4EEBUglyZXF1ZXN0SWQSKAoNdmFsaWRhdGVfb25seRgFIAEoCEID
4EEBUgx2YWxpZGF0ZU9ubHkirwEKGkRlbGV0ZUNsaWVudEdhdGV3YXlSZXF1ZXN0EkMKBG5h
bWUYASABKAlCL+BBAvpBKQonYmV5b25kY29ycC5nb29nbGVhcGlzLmNvbS9DbGllbnRHYXRl
d2F5UgRuYW1lEiIKCnJlcXVlc3RfaWQYAiABKAlCA+BBAVIJcmVxdWVzdElkEigKDXZhbGlk
YXRlX29ubHkYAyABKAhCA+BBAVIMdmFsaWRhdGVPbmx5IuICCh5DbGllbnRHYXRld2F5T3Bl
cmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNS
BnRhcmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSAB
KAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgI
QgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EED
UgphcGlWZXJzaW9uMscIChVDbGllbnRHYXRld2F5c1NlcnZpY2US5gEKEkxpc3RDbGllbnRH
YXRld2F5cxJELmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmNsaWVudGdhdGV3YXlzLnYxLkxp
c3RDbGllbnRHYXRld2F5c1JlcXVlc3QaRS5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5jbGll
bnRnYXRld2F5cy52MS5MaXN0Q2xpZW50R2F0ZXdheXNSZXNwb25zZSJDgtPkkwI0EjIvdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jbGllbnRHYXRld2F5c9pBBnBhcmVu
dBLTAQoQR2V0Q2xpZW50R2F0ZXdheRJCLmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmNsaWVu
dGdhdGV3YXlzLnYxLkdldENsaWVudEdhdGV3YXlSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLmJl
eW9uZGNvcnAuY2xpZW50Z2F0ZXdheXMudjEuQ2xpZW50R2F0ZXdheSJBgtPkkwI0EjIvdjEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbGllbnRHYXRld2F5cy8qfdpBBG5hbWUS
pAIKE0NyZWF0ZUNsaWVudEdhdGV3YXkSRS5nb29nbGUuY2xvdWQuYmV5b25kY29ycC5jbGll
bnRnYXRld2F5cy52MS5DcmVhdGVDbGllbnRHYXRld2F5UmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24ipgGC0+STAkQiMi92MS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyp9L2NsaWVudEdhdGV3YXlzOg5jbGllbnRfZ2F0ZXdhedpBJ3BhcmVudCxjbGll
bnRfZ2F0ZXdheSxjbGllbnRfZ2F0ZXdheV9pZMpBLwoNQ2xpZW50R2F0ZXdheRIeQ2xpZW50
R2F0ZXdheU9wZXJhdGlvbk1ldGFkYXRhEvgBChNEZWxldGVDbGllbnRHYXRld2F5EkUuZ29v
Z2xlLmNsb3VkLmJleW9uZGNvcnAuY2xpZW50Z2F0ZXdheXMudjEuRGVsZXRlQ2xpZW50R2F0
ZXdheVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uInuC0+STAjQqMi92
MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NsaWVudEdhdGV3YXlzLyp92kEEbmFt
ZcpBNwoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5Eh5DbGllbnRHYXRld2F5T3BlcmF0aW9uTWV0
YWRhdGEaTcpBGWJleW9uZGNvcnAuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQqwCCi1jb20uZ29vZ2xlLmNsb3VkLmJl
eW9uZGNvcnAuY2xpZW50Z2F0ZXdheXMudjFCGkNsaWVudEdhdGV3YXlzU2VydmljZVByb3Rv
UAFaVWNsb3VkLmdvb2dsZS5jb20vZ28vYmV5b25kY29ycC9jbGllbnRnYXRld2F5cy9hcGl2
MS9jbGllbnRnYXRld2F5c3BiO2NsaWVudGdhdGV3YXlzcGKqAilHb29nbGUuQ2xvdWQuQmV5
b25kQ29ycC5DbGllbnRHYXRld2F5cy5WMcoCKUdvb2dsZVxDbG91ZFxCZXlvbmRDb3JwXENs
aWVudEdhdGV3YXlzXFYx6gItR29vZ2xlOjpDbG91ZDo6QmV5b25kQ29ycDo6Q2xpZW50R2F0
ZXdheXM6OlYxSrFMCgcSBQ4ApwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAyCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYALQoJCgIDBRIDFwApCggKAQgSAxkARgoJCgIIJRIDGQBGCggKAQgSAxoA
bAoJCgIICxIDGgBsCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAOwoJCgIICBIDHAA7
CggKAQgSAx0ARgoJCgIIARIDHQBGCggKAQgSAx4ARwoJCgIIKRIDHgBHCggKAQgSAx8ARgoJ
CgIILRIDHwBGCrwCCgIGABIELABdARqvAiBBUEkgT3ZlcnZpZXc6CgogVGhlIGBiZXlvbmRj
b3JwLmdvb2dsZWFwaXMuY29tYCBzZXJ2aWNlIGltcGxlbWVudHMgdGhlIEdvb2dsZSBDbG91
ZAogQmV5b25kQ29ycCBBUEkuCgogRGF0YSBNb2RlbDoKCiBUaGUgQ2xpZW50R2F0ZXdheXNT
ZXJ2aWNlIGV4cG9zZXMgdGhlIGZvbGxvd2luZyByZXNvdXJjZXM6CgogKiBDbGllbnQgR2F0
ZXdheXMsIG5hbWVkIGFzIGZvbGxvd3M6CiAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9j
YXRpb25zL3tsb2NhdGlvbl9pZH0vY2xpZW50R2F0ZXdheXMve2NsaWVudF9nYXRld2F5X2lk
fWAuCgoKCgMGAAESAywIHQoKCgMGAAMSAy0CQQoMCgUGAAOZCBIDLQJBCgsKAwYAAxIELgIv
NwoNCgUGAAOaCBIELgIvNwpFCgQGAAIAEgQyAjgDGjcgTGlzdHMgQ2xpZW50R2F0ZXdheXMg
aW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMyBhgKDAoFBgAC
AAISAzIZMgoMCgUGAAIAAxIDMw8pCg0KBQYAAgAEEgQ0BDYGChEKCQYAAgAEsMq8IhIENAQ2
BgoMCgUGAAIABBIDNwQ0Cg8KCAYAAgAEmwgAEgM3BDQKNwoEBgACARIEOwJAAxopIEdldHMg
ZGV0YWlscyBvZiBhIHNpbmdsZSBDbGllbnRHYXRld2F5LgoKDAoFBgACAQESAzsGFgoMCgUG
AAIBAhIDOxcuCgwKBQYAAgEDEgM7OUYKDQoFBgACAQQSBDwEPgYKEQoJBgACAQSwyrwiEgQ8
BD4GCgwKBQYAAgEEEgM/BDIKDwoIBgACAQSbCAASAz8EMgpMCgQGAAICEgRDAk8DGj4gQ3Jl
YXRlcyBhIG5ldyBDbGllbnRHYXRld2F5IGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRp
b24uCgoMCgUGAAICARIDQwYZCgwKBQYAAgICEgNDGjQKDAoFBgACAgMSA0QPKwoNCgUGAAIC
BBIERQRIBgoRCgkGAAICBLDKvCISBEUESAYKDQoFBgACAgQSBEkESjIKEAoIBgACAgSbCAAS
BEkESjIKDQoFBgACAgQSBEsETgYKDwoHBgACAgSZCBIESwROBgovCgQGAAIDEgRSAlwDGiEg
RGVsZXRlcyBhIHNpbmdsZSBDbGllbnRHYXRld2F5LgoKDAoFBgACAwESA1IGGQoMCgUGAAID
AhIDUho0CgwKBQYAAgMDEgNTDysKDQoFBgACAwQSBFQEVgYKEQoJBgACAwSwyrwiEgRUBFYG
CgwKBQYAAgMEEgNXBDIKDwoIBgACAwSbCAASA1cEMgoNCgUGAAIDBBIEWARbBgoPCgcGAAID
BJkIEgRYBFsGCjcKAgQAEgVgAJUBARoqIE1lc3NhZ2UgZGVzY3JpYmluZyBDbGllbnRHYXRl
d2F5IG9iamVjdC4KCgoKAwQAARIDYAgVCgsKAwQABxIEYQJkBAoNCgUEAAedCBIEYQJkBAo9
CgQEAAQAEgRnAn0DGi8gUmVwcmVzZW50cyB0aGUgZGlmZmVyZW50IHN0YXRlcyBvZiBhIGdh
dGV3YXkuCgoMCgUEAAQAARIDZwcMCjUKBgQABAACABIDaQQaGiYgRGVmYXVsdCB2YWx1ZS4g
VGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAAQAAgABEgNpBBUKDgoHBAAEAAIAAhIDaRgZ
CioKBgQABAACARIDbAQRGhsgR2F0ZXdheSBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIB
ARIDbAQMCg4KBwQABAACAQISA2wPEAoqCgYEAAQAAgISA28EERobIEdhdGV3YXkgaXMgYmVp
bmcgdXBkYXRlZC4KCg4KBwQABAACAgESA28EDAoOCgcEAAQAAgICEgNvDxAKKgoGBAAEAAID
EgNyBBEaGyBHYXRld2F5IGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgMBEgNyBAwKDgoH
BAAEAAIDAhIDcg8QCiQKBgQABAACBBIDdQQQGhUgR2F0ZXdheSBpcyBydW5uaW5nLgoKDgoH
BAAEAAIEARIDdQQLCg4KBwQABAACBAISA3UODwp1CgYEAAQAAgUSA3kEDRpmIEdhdGV3YXkg
aXMgZG93biBhbmQgbWF5IGJlIHJlc3RvcmVkIGluIHRoZSBmdXR1cmUuCiBUaGlzIGhhcHBl
bnMgd2hlbiBDQ0ZFIHNlbmRzIFByb2plY3RTdGF0ZSA9IE9GRi4KCg4KBwQABAACBQESA3kE
CAoOCgcEAAQAAgUCEgN5CwwKVAoGBAAEAAIGEgN8BA4aRSBDbGllbnRHYXRld2F5IGVuY291
bnRlcmVkIGFuIGVycm9yIGFuZCBpcyBpbiBpbmRldGVybWluaXN0aWMgc3RhdGUuCgoOCgcE
AAQAAgYBEgN8BAkKDgoHBAAEAAIGAhIDfAwNClAKBAQAAgASBIABAjsaQiBSZXF1aXJlZC4g
bmFtZSBvZiByZXNvdXJjZS4gVGhlIG5hbWUgaXMgaWdub3JlZCBkdXJpbmcgY3JlYXRpb24u
CgoNCgUEAAIABRIEgAECCAoNCgUEAAIAARIEgAEJDQoNCgUEAAIAAxIEgAEQEQoNCgUEAAIA
CBIEgAESOgoQCggEAAIACJwIABIEgAETOQo/CgQEAAIBEgaDAQKEATIaLyBPdXRwdXQgb25s
eS4gW091dHB1dCBvbmx5XSBDcmVhdGUgdGltZSBzdGFtcC4KCg0KBQQAAgEGEgSDAQIbCg0K
BQQAAgEBEgSDARwnCg0KBQQAAgEDEgSDASorCg0KBQQAAgEIEgSEAQYxChAKCAQAAgEInAgA
EgSEAQcwCj8KBAQAAgISBocBAogBMhovIE91dHB1dCBvbmx5LiBbT3V0cHV0IG9ubHldIFVw
ZGF0ZSB0aW1lIHN0YW1wLgoKDQoFBAACAgYSBIcBAhsKDQoFBAACAgESBIcBHCcKDQoFBAAC
AgMSBIcBKisKDQoFBAACAggSBIgBBjEKEAoIBAACAgicCAASBIgBBzAKQgoEBAACAxIEiwEC
Pho0IE91dHB1dCBvbmx5LiBUaGUgb3BlcmF0aW9uYWwgc3RhdGUgb2YgdGhlIGdhdGV3YXku
CgoNCgUEAAIDBhIEiwECBwoNCgUEAAIDARIEiwEIDQoNCgUEAAIDAxIEiwEQEQoNCgUEAAID
CBIEiwESPQoQCggEAAIDCJwIABIEiwETPApaCgQEAAIEEgSOAQI8GkwgT3V0cHV0IG9ubHku
IEEgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBpbnN0YW5jZSBnZW5lcmF0ZWQgYnkgdGhl
IHN5c3RlbS4KCg0KBQQAAgQFEgSOAQIICg0KBQQAAgQBEgSOAQkLCg0KBQQAAgQDEgSOAQ4P
Cg0KBQQAAgQIEgSOARA7ChAKCAQAAgQInAgAEgSOARE6CoUCCgQEAAIFEgaTAQKUATIa9AEg
T3V0cHV0IG9ubHkuIFRoZSBjbGllbnQgY29ubmVjdG9yIHNlcnZpY2UgbmFtZSB0aGF0IHRo
ZSBjbGllbnQgZ2F0ZXdheSBpcwogYXNzb2NpYXRlZCB0by4gQ2xpZW50IENvbm5lY3RvciBT
ZXJ2aWNlcywgbmFtZWQgYXMgZm9sbG93czoKICAgYHByb2plY3RzL3twcm9qZWN0X2lkfS9s
b2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jbGllbnRfY29ubmVjdG9yX3NlcnZpY2VzL3tjbGll
bnRfY29ubmVjdG9yX3NlcnZpY2VfaWR9YC4KCg0KBQQAAgUFEgSTAQIICg0KBQQAAgUBEgST
AQkhCg0KBQQAAgUDEgSTASQlCg0KBQQAAgUIEgSUAQYxChAKCAQAAgUInAgAEgSUAQcwCj4K
AgQBEgaYAQCtAQEaMCBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGxpc3Qgb2YgQ2xpZW50R2F0
ZXdheXMuCgoLCgMEAQESBJgBCCEKRwoEBAECABIGmgECnwEEGjcgUmVxdWlyZWQuIFBhcmVu
dCB2YWx1ZSBmb3IgTGlzdENsaWVudEdhdGV3YXlzUmVxdWVzdC4KCg0KBQQBAgAFEgSaAQII
Cg0KBQQBAgABEgSaAQkPCg0KBQQBAgADEgSaARITCg8KBQQBAgAIEgaaARSfAQMKEAoIBAEC
AAicCAASBJsBBCoKEQoHBAECAAifCBIGnAEEngEFCpcBCgQEAQIBEgSjAQI/GogBIE9wdGlv
bmFsLiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJldHVybiBmZXdlciBpdGVt
cyB0aGFuCiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCBwaWNrIGFu
IGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAQIBBRIEowECBwoNCgUEAQIBARIEowEIEQoN
CgUEAQIBAxIEowEUFQoNCgUEAQIBCBIEowEWPgoQCggEAQIBCJwIABIEowEXPQpZCgQEAQIC
EgSmAQJBGksgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3Vs
dHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDQoFBAECAgUSBKYBAggKDQoFBAECAgES
BKYBCRMKDQoFBAECAgMSBKYBFhcKDQoFBAECAggSBKYBGEAKEAoIBAECAgicCAASBKYBGT8K
LAoEBAECAxIEqQECPRoeIE9wdGlvbmFsLiBGaWx0ZXJpbmcgcmVzdWx0cy4KCg0KBQQBAgMF
EgSpAQIICg0KBQQBAgMBEgSpAQkPCg0KBQQBAgMDEgSpARITCg0KBQQBAgMIEgSpARQ8ChAK
CAQBAgMInAgAEgSpARU7CjwKBAQBAgQSBKwBAj8aLiBPcHRpb25hbC4gSGludCBmb3IgaG93
IHRvIG9yZGVyIHRoZSByZXN1bHRzLgoKDQoFBAECBAUSBKwBAggKDQoFBAECBAESBKwBCREK
DQoFBAECBAMSBKwBFBUKDQoFBAECBAgSBKwBFj4KEAoIBAECBAicCAASBKwBFz0KPwoCBAIS
BrABALkBARoxIE1lc3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGxpc3RpbmcgQ2xpZW50R2F0ZXdh
eXMuCgoLCgMEAgESBLABCCIKKgoEBAICABIEsgECLRocIFRoZSBsaXN0IG9mIENsaWVudEdh
dGV3YXkuCgoNCgUEAgIABBIEsgECCgoNCgUEAgIABhIEsgELGAoNCgUEAgIAARIEsgEZKAoN
CgUEAgIAAxIEsgErLApPCgQEAgIBEgS1AQIdGkEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBh
Z2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCgoNCgUEAgIBBRIEtQEC
CAoNCgUEAgIBARIEtQEJGAoNCgUEAgIBAxIEtQEbHAo0CgQEAgICEgS4AQIiGiYgTG9jYXRp
b25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAgICBBIEuAECCgoNCgUEAgIC
BRIEuAELEQoNCgUEAgICARIEuAESHQoNCgUEAgICAxIEuAEgIQo0CgIEAxIGvAEAxAEBGiYg
TWVzc2FnZSBmb3IgZ2V0dGluZyBhIENsaWVudEdhdGV3YXkuCgoLCgMEAwESBLwBCB8KMAoE
BAMCABIGvgECwwEEGiAgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHJlc291cmNlCgoNCgUEAwIA
BRIEvgECCAoNCgUEAwIAARIEvgEJDQoNCgUEAwIAAxIEvgEQEQoPCgUEAwIACBIGvgESwwED
ChAKCAQDAgAInAgAEgS/AQQqChEKBwQDAgAInwgSBsABBMIBBQo1CgIEBBIGxwEA6wEBGicg
TWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBDbGllbnRHYXRld2F5LgoKCwoDBAQBEgTHAQgiCi0K
BAQEAgASBskBAs4BBBodIFJlcXVpcmVkLiBWYWx1ZSBmb3IgcGFyZW50LgoKDQoFBAQCAAUS
BMkBAggKDQoFBAQCAAESBMkBCQ8KDQoFBAQCAAMSBMkBEhMKDwoFBAQCAAgSBskBFM4BAwoQ
CggEBAIACJwIABIEygEEKgoRCgcEBAIACJ8IEgbLAQTNAQUKyQEKBAQEAgESBNQBAkgaugEg
T3B0aW9uYWwuIFVzZXItc2V0dGFibGUgY2xpZW50IGdhdGV3YXkgcmVzb3VyY2UgSUQuCiAg
KiBNdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCiAgKiBNdXN0IGNvbnRhaW4gYmV0d2VlbiA0
LTYzIGNoYXJhY3RlcnMgZnJvbSBgL1thLXpdWzAtOV0tL2AuCiAgKiBNdXN0IGVuZCB3aXRo
IGEgbnVtYmVyIG9yIGEgbGV0dGVyLgoKDQoFBAQCAQUSBNQBAggKDQoFBAQCAQESBNQBCRoK
DQoFBAQCAQMSBNQBHR4KDQoFBAQCAQgSBNQBH0cKEAoIBAQCAQicCAASBNQBIEYKNQoEBAQC
AhIE1wECTBonIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgYmVpbmcgY3JlYXRlZC4KCg0KBQQE
AgIGEgTXAQIPCg0KBQQEAgIBEgTXARAeCg0KBQQEAgIDEgTXASEiCg0KBQQEAgIIEgTXASNL
ChAKCAQEAgIInAgAEgTXASRKCpAGCgQEBAIDEgTmAQJBGoEGIE9wdGlvbmFsLiBBbiBvcHRp
b25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVl
CiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0
aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBh
bHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0
IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZv
ciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0
aWFsIHJlcXVlc3QgYW5kIHQKIGhlIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0
aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVy
IGNhbiBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0
IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCBy
ZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0
aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEg
dmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBz
dXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUE
BAIDBRIE5gECCAoNCgUEBAIDARIE5gEJEwoNCgUEBAIDAxIE5gEWFwoNCgUEBAIDCBIE5gEY
QAoQCggEBAIDCJwIABIE5gEZPwp6CgQEBAIEEgTqAQJCGmwgT3B0aW9uYWwuIElmIHNldCwg
dmFsaWRhdGVzIHJlcXVlc3QgYnkgZXhlY3V0aW5nIGEgZHJ5LXJ1biB3aGljaCB3b3VsZCBu
b3QKIGFsdGVyIHRoZSByZXNvdXJjZSBpbiBhbnkgd2F5LgoKDQoFBAQCBAUSBOoBAgYKDQoF
BAQCBAESBOoBBxQKDQoFBAQCBAMSBOoBFxgKDQoFBAQCBAgSBOoBGUEKEAoIBAQCBAicCAAS
BOoBGkAKNAoCBAUSBu4BAIkCARomIE1lc3NhZ2UgZm9yIGRlbGV0aW5nIGEgQ2xpZW50R2F0
ZXdheQoKCwoDBAUBEgTuAQgiCjAKBAQFAgASBvABAvUBBBogIFJlcXVpcmVkLiBOYW1lIG9m
IHRoZSByZXNvdXJjZQoKDQoFBAUCAAUSBPABAggKDQoFBAUCAAESBPABCQ0KDQoFBAUCAAMS
BPABEBEKDwoFBAUCAAgSBvABEvUBAwoQCggEBQIACJwIABIE8QEEKgoRCgcEBQIACJ8IEgby
AQT0AQUKkAYKBAQFAgESBIQCAkEagQYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3Qg
SUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQg
c28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2ls
bCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBj
b21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0
IDYwIG1pbnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNv
bnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBh
bmQgdAogaGUgcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFn
YWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlm
IG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNl
aXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMg
cHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRl
IGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdp
dGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAw
MDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQFAgEFEgSEAgIICg0K
BQQFAgEBEgSEAgkTCg0KBQQFAgEDEgSEAhYXCg0KBQQFAgEIEgSEAhhAChAKCAQFAgEInAgA
EgSEAhk/CnoKBAQFAgISBIgCAkIabCBPcHRpb25hbC4gSWYgc2V0LCB2YWxpZGF0ZXMgcmVx
dWVzdCBieSBleGVjdXRpbmcgYSBkcnktcnVuIHdoaWNoIHdvdWxkIG5vdAogYWx0ZXIgdGhl
IHJlc291cmNlIGluIGFueSB3YXkuCgoNCgUEBQICBRIEiAICBgoNCgUEBQICARIEiAIHFAoN
CgUEBQICAxIEiAIXGAoNCgUEBQICCBIEiAIZQQoQCggEBQICCJwIABIEiAIaQApGCgIEBhIG
jAIApwIBGjggUmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBv
cGVyYXRpb24uCgoLCgMEBgESBIwCCCYKQgoEBAYCABIGjgICjwIyGjIgT3V0cHV0IG9ubHku
IFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoNCgUEBgIABhIEjgICGwoN
CgUEBgIAARIEjgIcJwoNCgUEBgIAAxIEjgIqKwoNCgUEBgIACBIEjwIGMQoQCggEBgIACJwI
ABIEjwIHMApHCgQEBgIBEgaSAgKTAjIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9w
ZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5nLgoKDQoFBAYCAQYSBJICAhsKDQoFBAYCAQESBJIC
HCQKDQoFBAYCAQMSBJICJygKDQoFBAYCAQgSBJMCBjEKEAoIBAYCAQicCAASBJMCBzAKWgoE
BAYCAhIElgICQBpMIE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRo
IGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEBgICBRIElgICCAoNCgUE
BgICARIElgIJDwoNCgUEBgICAxIElgISEwoNCgUEBgICCBIElgIUPwoQCggEBgICCJwIABIE
lgIVPgpICgQEBgIDEgSZAgI+GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhl
Y3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4KCg0KBQQGAgMFEgSZAgIICg0KBQQGAgMBEgSZAgkN
Cg0KBQQGAgMDEgSZAhARCg0KBQQGAgMIEgSZAhI9ChAKCAQGAgMInAgAEgSZAhM8CkwKBAQG
AgQSBJwCAkgaPiBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBv
cGVyYXRpb24sIGlmIGFueS4KCg0KBQQGAgQFEgScAgIICg0KBQQGAgQBEgScAgkXCg0KBQQG
AgQDEgScAhobCg0KBQQGAgQIEgScAhxHChAKCAQGAgQInAgAEgScAh1GCpsCCgQEBgIFEgSj
AgJOGowCIE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJl
cXVlc3RlZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhh
dCBoYXZlIGJlZW4gY2FuY2VsbGVkIHN1Y2Nlc3NmdWxseQogaGF2ZSBbT3BlcmF0aW9uLmVy
cm9yXVtdIHZhbHVlIHdpdGggYQogW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5y
cGMuU3RhdHVzLmNvZGVdIG9mIDEsIGNvcnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExF
RGAuCgoNCgUEBgIFBRIEowICBgoNCgUEBgIFARIEowIHHQoNCgUEBgIFAxIEowIgIQoNCgUE
BgIFCBIEowIiTQoQCggEBgIFCJwIABIEowIjTApFCgQEBgIGEgSmAgJFGjcgT3V0cHV0IG9u
bHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQGAgYF
EgSmAgIICg0KBQQGAgYBEgSmAgkUCg0KBQQGAgYDEgSmAhcYCg0KBQQGAgYIEgSmAhlEChAK
CAQGAgYInAgAEgSmAhpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway ===
    # Fields for ClientGateway
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.beyondcorp.clientgateways.v1.ClientGateway.State)
    # Field: id Type: 9 ()
    # Field: client_connector_service Type: 9 ()

# Enum: ClientGateway::State
our $ClientGateway_STATE_UNSPECIFIED = 0;
our $ClientGateway_CREATING = 1;
our $ClientGateway_UPDATING = 2;
our $ClientGateway_DELETING = 3;
our $ClientGateway_RUNNING = 4;
our $ClientGateway_DOWN = 5;
our $ClientGateway_ERROR = 6;

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysRequest ===
    # Fields for ListClientGatewaysRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysResponse ===
    # Fields for ListClientGatewaysResponse
    # Field: client_gateways Type: 11 (.google.cloud.beyondcorp.clientgateways.v1.ClientGateway)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::GetClientGatewayRequest ===
    # Fields for GetClientGatewayRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::CreateClientGatewayRequest ===
    # Fields for CreateClientGatewayRequest
    # Field: parent Type: 9 ()
    # Field: client_gateway_id Type: 9 ()
    # Field: client_gateway Type: 11 (.google.cloud.beyondcorp.clientgateways.v1.ClientGateway)
    # Field: request_id Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::DeleteClientGatewayRequest ===
    # Fields for DeleteClientGatewayRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewayOperationMetadata ===
    # Fields for ClientGatewayOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewaysServiceClient ===
package Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewaysServiceClient;

=pod

=head2 Service Client: Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewaysServiceClient

Client stub representing the remote C<ClientGatewaysService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<beyondcorp.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'beyondcorp.googleapis.com:443' );

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

sub list_client_gateways {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.clientgateways.v1.ClientGatewaysService',
        method         => 'ListClientGateways',
        request        => $req,
        response_class => 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysResponse',
    });
}

sub get_client_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::GetClientGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.clientgateways.v1.ClientGatewaysService',
        method         => 'GetClientGateway',
        request        => $req,
        response_class => 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway',
    });
}

sub create_client_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::CreateClientGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.clientgateways.v1.ClientGatewaysService',
        method         => 'CreateClientGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_client_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::DeleteClientGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.beyondcorp.clientgateways.v1.ClientGatewaysService',
        method         => 'DeleteClientGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService - Compiled Protocol Buffers messages for google/cloud/beyondcorp/clientgateways/v1/client_gateways_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService;

    my $msg = Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/beyondcorp/clientgateways/v1/client_gateways_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway

Message describing ClientGateway object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. name of resource. The name is ignored during creation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Create time stamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Update time stamp.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGateway::State>)

Output only. The operational state of the gateway.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. A unique identifier for the instance generated by the system.

=item * C<< $msg->client_connector_service() >> / C<< $msg->client_connector_service($value) >>

Type: C<String>

Output only. The client connector service name that the client gateway is
associated to. Client Connector Services, named as follows:
  `projects/{project_id}/locations/{location_id}/client_connector_services/{client_connector_service_id}`.

=back

=head3 Enum: ClientGateway::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<UPDATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<RUNNING> => C<4>

=item * C<DOWN> => C<5>

=item * C<ERROR> => C<6>

=back

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysRequest

Message for requesting list of ClientGateways.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListClientGatewaysRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysResponse

Message for response to listing ClientGateways.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_gateways() >> / C<< $msg->client_gateways($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway>)

The list of ClientGateway.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::GetClientGatewayRequest

Message for getting a ClientGateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource

=back

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::CreateClientGatewayRequest

Message for creating a ClientGateway.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Value for parent.

=item * C<< $msg->client_gateway_id() >> / C<< $msg->client_gateway_id($value) >>

Type: C<String>

Optional. User-settable client gateway resource ID.
 * Must start with a letter.
 * Must contain between 4-63 characters from `/[a-z][0-9]-/`.
 * Must end with a number or a letter.

=item * C<< $msg->client_gateway() >> / C<< $msg->client_gateway($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway>)

Required. The resource being created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and t
he request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validates request by executing a dry-run which would not
alter the resource in any way.

=back

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::DeleteClientGatewayRequest

Message for deleting a ClientGateway

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and t
he request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. If set, validates request by executing a dry-run which would not
alter the resource in any way.

=back

=head2 Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewayOperationMetadata

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
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
