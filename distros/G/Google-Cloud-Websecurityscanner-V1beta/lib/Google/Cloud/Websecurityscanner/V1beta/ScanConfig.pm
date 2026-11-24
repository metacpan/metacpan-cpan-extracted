package Google::Cloud::Websecurityscanner::V1beta::ScanConfig;

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
    eval { require Google::Cloud::Websecurityscanner::V1beta::ScanRun };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9zY2FuX2NvbmZpZy5w
cm90bxImZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aNWdv
b2dsZS9jbG91ZC93ZWJzZWN1cml0eXNjYW5uZXIvdjFiZXRhL3NjYW5fcnVuLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIsMPCgpTY2FuQ29uZmlnEhIKBG5hbWUY
ASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lEhcK
B21heF9xcHMYAyABKAVSBm1heFFwcxIoCg1zdGFydGluZ191cmxzGAQgAygJQgPgQQJSDHN0
YXJ0aW5nVXJscxJpCg5hdXRoZW50aWNhdGlvbhgFIAEoCzJBLmdvb2dsZS5jbG91ZC53ZWJz
ZWN1cml0eXNjYW5uZXIudjFiZXRhLlNjYW5Db25maWcuQXV0aGVudGljYXRpb25SDmF1dGhl
bnRpY2F0aW9uElsKCnVzZXJfYWdlbnQYBiABKA4yPC5nb29nbGUuY2xvdWQud2Vic2VjdXJp
dHlzY2FubmVyLnYxYmV0YS5TY2FuQ29uZmlnLlVzZXJBZ2VudFIJdXNlckFnZW50Ei0KEmJs
YWNrbGlzdF9wYXR0ZXJucxgHIAMoCVIRYmxhY2tsaXN0UGF0dGVybnMSVwoIc2NoZWR1bGUY
CCABKAsyOy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5TY2FuQ29u
ZmlnLlNjaGVkdWxlUghzY2hlZHVsZRJsChB0YXJnZXRfcGxhdGZvcm1zGAkgAygOMkEuZ29v
Z2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuU2NhbkNvbmZpZy5UYXJnZXRQ
bGF0Zm9ybVIPdGFyZ2V0UGxhdGZvcm1zEpoBCiFleHBvcnRfdG9fc2VjdXJpdHlfY29tbWFu
ZF9jZW50ZXIYCiABKA4yUC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0
YS5TY2FuQ29uZmlnLkV4cG9ydFRvU2VjdXJpdHlDb21tYW5kQ2VudGVyUh1leHBvcnRUb1Nl
Y3VyaXR5Q29tbWFuZENlbnRlchJOCgpsYXRlc3RfcnVuGAsgASgLMi8uZ29vZ2xlLmNsb3Vk
LndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuU2NhblJ1blIJbGF0ZXN0UnVuElsKCnJpc2tf
bGV2ZWwYDCABKA4yPC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5T
Y2FuQ29uZmlnLlJpc2tMZXZlbFIJcmlza0xldmVsGuQDCg5BdXRoZW50aWNhdGlvbhJ4Cg5n
b29nbGVfYWNjb3VudBgBIAEoCzJPLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIu
djFiZXRhLlNjYW5Db25maWcuQXV0aGVudGljYXRpb24uR29vZ2xlQWNjb3VudEgAUg1nb29n
bGVBY2NvdW50EngKDmN1c3RvbV9hY2NvdW50GAIgASgLMk8uZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWJldGEuU2NhbkNvbmZpZy5BdXRoZW50aWNhdGlvbi5DdXN0b21B
Y2NvdW50SABSDWN1c3RvbUFjY291bnQaVAoNR29vZ2xlQWNjb3VudBIfCgh1c2VybmFtZRgB
IAEoCUID4EECUgh1c2VybmFtZRIiCghwYXNzd29yZBgCIAEoCUIG4EEC4EEEUghwYXNzd29y
ZBp2Cg1DdXN0b21BY2NvdW50Eh8KCHVzZXJuYW1lGAEgASgJQgPgQQJSCHVzZXJuYW1lEiIK
CHBhc3N3b3JkGAIgASgJQgbgQQLgQQRSCHBhc3N3b3JkEiAKCWxvZ2luX3VybBgDIAEoCUID
4EECUghsb2dpblVybEIQCg5hdXRoZW50aWNhdGlvbhqGAQoIU2NoZWR1bGUSPwoNc2NoZWR1
bGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVkdWxlVGlt
ZRI5ChZpbnRlcnZhbF9kdXJhdGlvbl9kYXlzGAIgASgFQgPgQQJSFGludGVydmFsRHVyYXRp
b25EYXlzImAKCVVzZXJBZ2VudBIaChZVU0VSX0FHRU5UX1VOU1BFQ0lGSUVEEAASEAoMQ0hS
T01FX0xJTlVYEAESEgoOQ0hST01FX0FORFJPSUQQAhIRCg1TQUZBUklfSVBIT05FEAMiTgoO
VGFyZ2V0UGxhdGZvcm0SHwobVEFSR0VUX1BMQVRGT1JNX1VOU1BFQ0lGSUVEEAASDgoKQVBQ
X0VOR0lORRABEgsKB0NPTVBVVEUQAiI8CglSaXNrTGV2ZWwSGgoWUklTS19MRVZFTF9VTlNQ
RUNJRklFRBAAEgoKBk5PUk1BTBABEgcKA0xPVxACIm0KHUV4cG9ydFRvU2VjdXJpdHlDb21t
YW5kQ2VudGVyEjEKLUVYUE9SVF9UT19TRUNVUklUWV9DT01NQU5EX0NFTlRFUl9VTlNQRUNJ
RklFRBAAEgsKB0VOQUJMRUQQARIMCghESVNBQkxFRBACOl/qQVwKLHdlYnNlY3VyaXR5c2Nh
bm5lci5nb29nbGVhcGlzLmNvbS9TY2FuQ29uZmlnEixwcm9qZWN0cy97cHJvamVjdH0vc2Nh
bkNvbmZpZ3Mve3NjYW5fY29uZmlnfUKZAgoqY29tLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0
eXNjYW5uZXIudjFiZXRhQg9TY2FuQ29uZmlnUHJvdG9QAVpaY2xvdWQuZ29vZ2xlLmNvbS9n
by93ZWJzZWN1cml0eXNjYW5uZXIvYXBpdjFiZXRhL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dl
YnNlY3VyaXR5c2Nhbm5lcnBiqgImR29vZ2xlLkNsb3VkLldlYlNlY3VyaXR5U2Nhbm5lci5W
MUJldGHKAiZHb29nbGVcQ2xvdWRcV2ViU2VjdXJpdHlTY2FubmVyXFYxYmV0YeoCKUdvb2ds
ZTo6Q2xvdWQ6OldlYlNlY3VyaXR5U2Nhbm5lcjo6VjFiZXRhSt00CgcSBQ8AwAEBCr0ECgEM
EgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQISAxEALwoJCgIDABIDEwApCgkK
AgMBEgMUACMKCQoCAwISAxUAPwoJCgIDAxIDFgApCggKAQgSAxgAQwoJCgIIJRIDGABDCggK
AQgSAxkAcQoJCgIICxIDGQBxCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMAoJCgII
CBIDGwAwCggKAQgSAxwAQwoJCgIIARIDHABDCggKAQgSAx0AQwoJCgIIKRIDHQBDCggKAQgS
Ax4AQgoJCgIILRIDHgBCClIKAgQAEgUhAMABARpFIEEgU2NhbkNvbmZpZyByZXNvdXJjZSBj
b250YWlucyB0aGUgY29uZmlndXJhdGlvbnMgdG8gbGF1bmNoIGEgc2Nhbi4KCgoKAwQAARID
IQgSCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAoyCgQEAAMAEgQoAk8DGiQgU2NhbiBh
dXRoZW50aWNhdGlvbiBjb25maWd1cmF0aW9uLgoKDAoFBAADAAESAygKGApUCgYEAAMAAwAS
BCoENAUaRCBEZXNjcmliZXMgYXV0aGVudGljYXRpb24gY29uZmlndXJhdGlvbiB0aGF0IHVz
ZXMgYSBHb29nbGUgYWNjb3VudC4KCg4KBwQAAwADAAESAyoMGQpBCggEAAMAAwACABIDLAZD
GjAgUmVxdWlyZWQuIFRoZSB1c2VyIG5hbWUgb2YgdGhlIEdvb2dsZSBhY2NvdW50LgoKEAoJ
BAADAAMAAgAFEgMsBgwKEAoJBAADAAMAAgABEgMsDRUKEAoJBAADAAMAAgADEgMsGBkKEAoJ
BAADAAMAAgAIEgMsGkIKEwoMBAADAAMAAgAInAgAEgMsG0EKrwEKCAQAAwADAAIBEgQwBjMI
GpwBIFJlcXVpcmVkLiBJbnB1dCBvbmx5LiBUaGUgcGFzc3dvcmQgb2YgdGhlIEdvb2dsZSBh
Y2NvdW50LiBUaGUgY3JlZGVudGlhbCBpcyBzdG9yZWQgZW5jcnlwdGVkCiBhbmQgbm90IHJl
dHVybmVkIGluIGFueSByZXNwb25zZSBub3IgaW5jbHVkZWQgaW4gYXVkaXQgbG9ncy4KChAK
CQQAAwADAAIBBRIDMAYMChAKCQQAAwADAAIBARIDMA0VChAKCQQAAwADAAIBAxIDMBgZChEK
CQQAAwADAAIBCBIEMBozBwoTCgwEAAMAAwACAQicCAASAzEILgoTCgwEAAMAAwACAQicCAES
AzIIMApUCgYEAAMAAwESBDcERAUaRCBEZXNjcmliZXMgYXV0aGVudGljYXRpb24gY29uZmln
dXJhdGlvbiB0aGF0IHVzZXMgYSBjdXN0b20gYWNjb3VudC4KCg4KBwQAAwADAQESAzcMGQpB
CggEAAMAAwECABIDOQZDGjAgUmVxdWlyZWQuIFRoZSB1c2VyIG5hbWUgb2YgdGhlIGN1c3Rv
bSBhY2NvdW50LgoKEAoJBAADAAMBAgAFEgM5BgwKEAoJBAADAAMBAgABEgM5DRUKEAoJBAAD
AAMBAgADEgM5GBkKEAoJBAADAAMBAgAIEgM5GkIKEwoMBAADAAMBAgAInAgAEgM5G0EKrwEK
CAQAAwADAQIBEgQ9BkAIGpwBIFJlcXVpcmVkLiBJbnB1dCBvbmx5LiBUaGUgcGFzc3dvcmQg
b2YgdGhlIGN1c3RvbSBhY2NvdW50LiBUaGUgY3JlZGVudGlhbCBpcyBzdG9yZWQgZW5jcnlw
dGVkCiBhbmQgbm90IHJldHVybmVkIGluIGFueSByZXNwb25zZSBub3IgaW5jbHVkZWQgaW4g
YXVkaXQgbG9ncy4KChAKCQQAAwADAQIBBRIDPQYMChAKCQQAAwADAQIBARIDPQ0VChAKCQQA
AwADAQIBAxIDPRgZChEKCQQAAwADAQIBCBIEPRpABwoTCgwEAAMAAwECAQicCAASAz4ILgoT
CgwEAAMAAwECAQicCAESAz8IMAo/CggEAAMAAwECAhIDQwZEGi4gUmVxdWlyZWQuIFRoZSBs
b2dpbiBmb3JtIFVSTCBvZiB0aGUgd2Vic2l0ZS4KChAKCQQAAwADAQICBRIDQwYMChAKCQQA
AwADAQICARIDQw0WChAKCQQAAwADAQICAxIDQxkaChAKCQQAAwADAQICCBIDQxtDChMKDAQA
AwADAQICCJwIABIDQxxCCjkKBgQAAwAIABIESAROBRopIFJlcXVpcmVkLgogQXV0aGVudGlj
YXRpb24gY29uZmlndXJhdGlvbgoKDgoHBAADAAgAARIDSAoYCjcKBgQAAwACABIDSgYnGigg
QXV0aGVudGljYXRpb24gdXNpbmcgYSBHb29nbGUgYWNjb3VudC4KCg4KBwQAAwACAAYSA0oG
EwoOCgcEAAMAAgABEgNKFCIKDgoHBAADAAIAAxIDSiUmCjcKBgQAAwACARIDTQYnGiggQXV0
aGVudGljYXRpb24gdXNpbmcgYSBjdXN0b20gYWNjb3VudC4KCg4KBwQAAwACAQYSA00GEwoO
CgcEAAMAAgEBEgNNFCIKDgoHBAADAAIBAxIDTSUmCiwKBAQAAwESBFICWwMaHiBTY2FuIHNj
aGVkdWxlIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAMBARIDUgoSCvkBCgYEAAMBAgASA1cEMBrp
ASBBIHRpbWVzdGFtcCBpbmRpY2F0ZXMgd2hlbiB0aGUgbmV4dCBydW4gd2lsbCBiZSBzY2hl
ZHVsZWQuIFRoZSB2YWx1ZSBpcwogcmVmcmVzaGVkIGJ5IHRoZSBzZXJ2ZXIgYWZ0ZXIgZWFj
aCBydW4uIElmIHVuc3BlY2lmaWVkLCBpdCB3aWxsIGRlZmF1bHQKIHRvIGN1cnJlbnQgc2Vy
dmVyIHRpbWUsIHdoaWNoIG1lYW5zIHRoZSBzY2FuIHdpbGwgYmUgc2NoZWR1bGVkIHRvIHN0
YXJ0CiBpbW1lZGlhdGVseS4KCg4KBwQAAwECAAYSA1cEHQoOCgcEAAMBAgABEgNXHisKDgoH
BAADAQIAAxIDVy4vCksKBgQAAwECARIDWgROGjwgUmVxdWlyZWQuIFRoZSBkdXJhdGlvbiBv
ZiB0aW1lIGJldHdlZW4gZXhlY3V0aW9ucyBpbiBkYXlzLgoKDgoHBAADAQIBBRIDWgQJCg4K
BwQAAwECAQESA1oKIAoOCgcEAAMBAgEDEgNaIyQKDgoHBAADAQIBCBIDWiVNChEKCgQAAwEC
AQicCAASA1omTAo2CgQEAAQAEgReAmoDGiggVHlwZSBvZiB1c2VyIGFnZW50cyB1c2VkIGZv
ciBzY2FubmluZy4KCgwKBQQABAABEgNeBxAKUQoGBAAEAAIAEgNgBB8aQiBUaGUgdXNlciBh
Z2VudCBpcyB1bmtub3duLiBTZXJ2aWNlIHdpbGwgZGVmYXVsdCB0byBDSFJPTUVfTElOVVgu
CgoOCgcEAAQAAgABEgNgBBoKDgoHBAAEAAIAAhIDYB0eCk0KBgQABAACARIDYwQVGj4gQ2hy
b21lIG9uIExpbnV4LiBUaGlzIGlzIHRoZSBzZXJ2aWNlIGRlZmF1bHQgaWYgdW5zcGVjaWZp
ZWQuCgoOCgcEAAQAAgEBEgNjBBAKDgoHBAAEAAIBAhIDYxMUCiMKBgQABAACAhIDZgQXGhQg
Q2hyb21lIG9uIEFuZHJvaWQuCgoOCgcEAAQAAgIBEgNmBBIKDgoHBAAEAAICAhIDZhUWCiIK
BgQABAACAxIDaQQWGhMgU2FmYXJpIG9uIElQaG9uZS4KCg4KBwQABAACAwESA2kEEQoOCgcE
AAQAAgMCEgNpFBUKSAoEBAAEARIEbQJ3Axo6IENsb3VkIHBsYXRmb3JtcyBzdXBwb3J0ZWQg
YnkgQ2xvdWQgV2ViIFNlY3VyaXR5IFNjYW5uZXIuCgoMCgUEAAQBARIDbQcVCn0KBgQABAEC
ABIDcAQkGm4gVGhlIHRhcmdldCBwbGF0Zm9ybSBpcyB1bmtub3duLiBSZXF1ZXN0cyB3aXRo
IHRoaXMgZW51bSB2YWx1ZSB3aWxsIGJlCiByZWplY3RlZCB3aXRoIElOVkFMSURfQVJHVU1F
TlQgZXJyb3IuCgoOCgcEAAQBAgABEgNwBB8KDgoHBAAEAQIAAhIDcCIjCisKBgQABAECARID
cwQTGhwgR29vZ2xlIEFwcCBFbmdpbmUgc2VydmljZS4KCg4KBwQABAECAQESA3MEDgoOCgcE
AAQBAgECEgNzERIKLwoGBAAEAQICEgN2BBAaICBHb29nbGUgQ29tcHV0ZSBFbmdpbmUgc2Vy
dmljZS4KCg4KBwQABAECAgESA3YECwoOCgcEAAQBAgICEgN2Dg8K4wEKBAQABAISBXwChQED
GtMBIFNjYW4gcmlzayBsZXZlbHMgc3VwcG9ydGVkIGJ5IENsb3VkIFdlYiBTZWN1cml0eSBT
Y2FubmVyLiBMT1cgaW1wYWN0CiBzY2FubmluZyB3aWxsIG1pbmltaXplIHJlcXVlc3RzIHdp
dGggdGhlIHBvdGVudGlhbCB0byBtb2RpZnkgZGF0YS4gVG8KIGFjaGlldmUgdGhlIG1heGlt
dW0gc2NhbiBjb3ZlcmFnZSwgTk9STUFMIHJpc2sgbGV2ZWwgaXMgcmVjb21tZW5kZWQuCgoM
CgUEAAQCARIDfAcQCi4KBgQABAICABIDfgQfGh8gVXNlIGRlZmF1bHQsIHdoaWNoIGlzIE5P
Uk1BTC4KCg4KBwQABAICAAESA34EGgoOCgcEAAQCAgACEgN+HR4KLwoGBAAEAgIBEgSBAQQP
Gh8gTm9ybWFsIHNjYW5uaW5nIChSZWNvbW1lbmRlZCkKCg8KBwQABAICAQESBIEBBAoKDwoH
BAAEAgIBAhIEgQENDgonCgYEAAQCAgISBIQBBAwaFyBMb3dlciBpbXBhY3Qgc2Nhbm5pbmcK
Cg8KBwQABAICAgESBIQBBAcKDwoHBAAEAgICAhIEhAEKCwpnCgQEAAQDEgaJAQKSAQMaVyBD
b250cm9scyBleHBvcnQgb2Ygc2NhbiBjb25maWd1cmF0aW9ucyBhbmQgcmVzdWx0cyB0byBD
bG91ZCBTZWN1cml0eQogQ29tbWFuZCBDZW50ZXIuCgoNCgUEAAQDARIEiQEHJAowCgYEAAQD
AgASBIsBBDYaICBVc2UgZGVmYXVsdCwgd2hpY2ggaXMgRU5BQkxFRC4KCg8KBwQABAMCAAES
BIsBBDEKDwoHBAAEAwIAAhIEiwE0NQpPCgYEAAQDAgESBI4BBBAaPyBFeHBvcnQgcmVzdWx0
cyBvZiB0aGlzIHNjYW4gdG8gQ2xvdWQgU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIuCgoPCgcE
AAQDAgEBEgSOAQQLCg8KBwQABAMCAQISBI4BDg8KVgoGBAAEAwICEgSRAQQRGkYgRG8gbm90
IGV4cG9ydCByZXN1bHRzIG9mIHRoaXMgc2NhbiB0byBDbG91ZCBTZWN1cml0eSBDb21tYW5k
IENlbnRlci4KCg8KBwQABAMCAgESBJEBBAwKDwoHBAAEAwICAhIEkQEPEAq5AQoEBAACABIE
lwECEhqqASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgU2NhbkNvbmZpZy4gVGhlIG5hbWUg
Zm9sbG93cyB0aGUgZm9ybWF0IG9mCiAncHJvamVjdHMve3Byb2plY3RJZH0vc2NhbkNvbmZp
Z3Mve3NjYW5Db25maWdJZH0nLiBUaGUgU2NhbkNvbmZpZyBJRHMgYXJlCiBnZW5lcmF0ZWQg
YnkgdGhlIHN5c3RlbS4KCg0KBQQAAgAFEgSXAQIICg0KBQQAAgABEgSXAQkNCg0KBQQAAgAD
EgSXARARCksKBAQAAgESBJoBAkMaPSBSZXF1aXJlZC4gVGhlIHVzZXIgcHJvdmlkZWQgZGlz
cGxheSBuYW1lIG9mIHRoZSBTY2FuQ29uZmlnLgoKDQoFBAACAQUSBJoBAggKDQoFBAACAQES
BJoBCRUKDQoFBAACAQMSBJoBGBkKDQoFBAACAQgSBJoBGkIKEAoIBAACAQicCAASBJoBG0EK
hQIKBAQAAgISBKABAhQa9gEgVGhlIG1heGltdW0gUVBTIGR1cmluZyBzY2FubmluZy4gQSB2
YWxpZCB2YWx1ZSByYW5nZXMgZnJvbSA1IHRvIDIwCiBpbmNsdXNpdmVseS4gSWYgdGhlIGZp
ZWxkIGlzIHVuc3BlY2lmaWVkIG9yIGl0cyB2YWx1ZSBpcyBzZXQgMCwgc2VydmVyIHdpbGwK
IGRlZmF1bHQgdG8gMTUuIE90aGVyIHZhbHVlcyBvdXRzaWRlIG9mIFs1LCAyMF0gcmFuZ2Ug
d2lsbCBiZSByZWplY3RlZCB3aXRoCiBJTlZBTElEX0FSR1VNRU5UIGVycm9yLgoKDQoFBAAC
AgUSBKABAgcKDQoFBAACAgESBKABCA8KDQoFBAACAgMSBKABEhMKVAoEBAACAxIEowECTRpG
IFJlcXVpcmVkLiBUaGUgc3RhcnRpbmcgVVJMcyBmcm9tIHdoaWNoIHRoZSBzY2FubmVyIGZp
bmRzIHNpdGUgcGFnZXMuCgoNCgUEAAIDBBIEowECCgoNCgUEAAIDBRIEowELEQoNCgUEAAID
ARIEowESHwoNCgUEAAIDAxIEowEiIwoNCgUEAAIDCBIEowEkTAoQCggEAAIDCJwIABIEowEl
SwqDAQoEBAACBBIEpwECJBp1IFRoZSBhdXRoZW50aWNhdGlvbiBjb25maWd1cmF0aW9uLiBJ
ZiBzcGVjaWZpZWQsIHNlcnZpY2Ugd2lsbCB1c2UgdGhlCiBhdXRoZW50aWNhdGlvbiBjb25m
aWd1cmF0aW9uIGR1cmluZyBzY2FubmluZy4KCg0KBQQAAgQGEgSnAQIQCg0KBQQAAgQBEgSn
AREfCg0KBQQAAgQDEgSnASIjCjQKBAQAAgUSBKoBAhsaJiBUaGUgdXNlciBhZ2VudCB1c2Vk
IGR1cmluZyBzY2FubmluZy4KCg0KBQQAAgUGEgSqAQILCg0KBQQAAgUBEgSqAQwWCg0KBQQA
AgUDEgSqARkaCngKBAQAAgYSBK4BAikaaiBUaGUgYmxhY2tsaXN0IFVSTCBwYXR0ZXJucyBh
cyBkZXNjcmliZWQgaW4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zZWN1cml0eS1zY2Fu
bmVyL2RvY3MvZXhjbHVkZWQtdXJscwoKDQoFBAACBgQSBK4BAgoKDQoFBAACBgUSBK4BCxEK
DQoFBAACBgESBK4BEiQKDQoFBAACBgMSBK4BJygKLwoEBAACBxIEsQECGBohIFRoZSBzY2hl
ZHVsZSBvZiB0aGUgU2NhbkNvbmZpZy4KCg0KBQQAAgcGEgSxAQIKCg0KBQQAAgcBEgSxAQsT
Cg0KBQQAAgcDEgSxARYXCm0KBAQAAggSBLUBAi8aXyBTZXQgb2YgQ2xvdWQgUGxhdGZvcm1z
IHRhcmdldGVkIGJ5IHRoZSBzY2FuLiBJZiBlbXB0eSwgQVBQX0VOR0lORSB3aWxsIGJlCiB1
c2VkIGFzIGEgZGVmYXVsdC4KCg0KBQQAAggEEgS1AQIKCg0KBQQAAggGEgS1AQsZCg0KBQQA
AggBEgS1ARoqCg0KBQQAAggDEgS1AS0uCmUKBAQAAgkSBLkBAkcaVyBDb250cm9scyBleHBv
cnQgb2Ygc2NhbiBjb25maWd1cmF0aW9ucyBhbmQgcmVzdWx0cyB0byBDbG91ZCBTZWN1cml0
eQogQ29tbWFuZCBDZW50ZXIuCgoNCgUEAAIJBhIEuQECHwoNCgUEAAIJARIEuQEgQQoNCgUE
AAIJAxIEuQFERgosCgQEAAIKEgS8AQIaGh4gTGF0ZXN0IFNjYW5SdW4gaWYgYXZhaWxhYmxl
LgoKDQoFBAACCgYSBLwBAgkKDQoFBAACCgESBLwBChQKDQoFBAACCgMSBLwBFxkKNAoEBAAC
CxIEvwECHBomIFRoZSByaXNrIGxldmVsIHNlbGVjdGVkIGZvciB0aGUgc2NhbgoKDQoFBAAC
CwYSBL8BAgsKDQoFBAACCwESBL8BDBYKDQoFBAACCwMSBL8BGRtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig ===
    # Fields for ScanConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: max_qps Type: 5 ()
    # Field: starting_urls Type: 9 ()
    # Field: authentication Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanConfig.Authentication)
    # Field: user_agent Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanConfig.UserAgent)
    # Field: blacklist_patterns Type: 9 ()
    # Field: schedule Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanConfig.Schedule)
    # Field: target_platforms Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanConfig.TargetPlatform)
    # Field: export_to_security_command_center Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanConfig.ExportToSecurityCommandCenter)
    # Field: latest_run Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanRun)
    # Field: risk_level Type: 14 (.google.cloud.websecurityscanner.v1beta.ScanConfig.RiskLevel)

# Enum: ScanConfig::UserAgent
our $ScanConfig_USER_AGENT_UNSPECIFIED = 0;
our $ScanConfig_CHROME_LINUX = 1;
our $ScanConfig_CHROME_ANDROID = 2;
our $ScanConfig_SAFARI_IPHONE = 3;

# Enum: ScanConfig::TargetPlatform
our $ScanConfig_TARGET_PLATFORM_UNSPECIFIED = 0;
our $ScanConfig_APP_ENGINE = 1;
our $ScanConfig_COMPUTE = 2;

# Enum: ScanConfig::RiskLevel
our $ScanConfig_RISK_LEVEL_UNSPECIFIED = 0;
our $ScanConfig_NORMAL = 1;
our $ScanConfig_LOW = 2;

# Enum: ScanConfig::ExportToSecurityCommandCenter
our $ScanConfig_EXPORT_TO_SECURITY_COMMAND_CENTER_UNSPECIFIED = 0;
our $ScanConfig_ENABLED = 1;
our $ScanConfig_DISABLED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::ScanConfig - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/scan_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::ScanConfig;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig->new({
        name => $name,
        display_name => $display_name,
        max_qps => $max_qps,
        starting_urls => $starting_urls,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/scan_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig

A ScanConfig resource contains the configurations to launch a scan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the ScanConfig. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}'. The ScanConfig IDs are
generated by the system.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The user provided display name of the ScanConfig.

=item * C<< $msg->max_qps() >> / C<< $msg->max_qps($value) >>

Type: C<Int32>

The maximum QPS during scanning. A valid value ranges from 5 to 20
inclusively. If the field is unspecified or its value is set 0, server will
default to 15. Other values outside of [5, 20] range will be rejected with
INVALID_ARGUMENT error.

=item * C<< $msg->starting_urls() >> / C<< $msg->starting_urls($value) >>

Type: C<String>

Required. The starting URLs from which the scanner finds site pages.

=item * C<< $msg->authentication() >> / C<< $msg->authentication($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig::Authentication>)

The authentication configuration. If specified, service will use the
authentication configuration during scanning.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::UserAgent>)

The user agent used during scanning.

=item * C<< $msg->blacklist_patterns() >> / C<< $msg->blacklist_patterns($value) >>

Type: C<String>

The blacklist URL patterns as described in
https://cloud.google.com/security-scanner/docs/excluded-urls

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig::Schedule>)

The schedule of the ScanConfig.

=item * C<< $msg->target_platforms() >> / C<< $msg->target_platforms($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::TargetPlatform>)

Set of Cloud Platforms targeted by the scan. If empty, APP_ENGINE will be
used as a default.

=item * C<< $msg->export_to_security_command_center() >> / C<< $msg->export_to_security_command_center($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ExportToSecurityCommandCenter>)

Controls export of scan configurations and results to Cloud Security
Command Center.

=item * C<< $msg->latest_run() >> / C<< $msg->latest_run($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun>)

Latest ScanRun if available.

=item * C<< $msg->risk_level() >> / C<< $msg->risk_level($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::RiskLevel>)

The risk level selected for the scan

=back

=head3 Enum: ScanConfig::UserAgent

=over 4

=item * C<USER_AGENT_UNSPECIFIED> => C<0>

=item * C<CHROME_LINUX> => C<1>

=item * C<CHROME_ANDROID> => C<2>

=item * C<SAFARI_IPHONE> => C<3>

=back

=head3 Enum: ScanConfig::TargetPlatform

=over 4

=item * C<TARGET_PLATFORM_UNSPECIFIED> => C<0>

=item * C<APP_ENGINE> => C<1>

=item * C<COMPUTE> => C<2>

=back

=head3 Enum: ScanConfig::RiskLevel

=over 4

=item * C<RISK_LEVEL_UNSPECIFIED> => C<0>

=item * C<NORMAL> => C<1>

=item * C<LOW> => C<2>

=back

=head3 Enum: ScanConfig::ExportToSecurityCommandCenter

=over 4

=item * C<EXPORT_TO_SECURITY_COMMAND_CENTER_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
