package Google::Cloud::Websecurityscanner::V1::ScanConfig;

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
CjRnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3NjYW5fY29uZmlnLnByb3Rv
EiJnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIroQCgpT
Y2FuQ29uZmlnEhIKBG5hbWUYASABKAlSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtk
aXNwbGF5TmFtZRIXCgdtYXhfcXBzGAMgASgFUgZtYXhRcHMSIwoNc3RhcnRpbmdfdXJscxgE
IAMoCVIMc3RhcnRpbmdVcmxzEmUKDmF1dGhlbnRpY2F0aW9uGAUgASgLMj0uZ29vZ2xlLmNs
b3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5TY2FuQ29uZmlnLkF1dGhlbnRpY2F0aW9uUg5h
dXRoZW50aWNhdGlvbhJXCgp1c2VyX2FnZW50GAYgASgOMjguZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MS5TY2FuQ29uZmlnLlVzZXJBZ2VudFIJdXNlckFnZW50Ei0KEmJs
YWNrbGlzdF9wYXR0ZXJucxgHIAMoCVIRYmxhY2tsaXN0UGF0dGVybnMSUwoIc2NoZWR1bGUY
CCABKAsyNy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLlNjYW5Db25maWcu
U2NoZWR1bGVSCHNjaGVkdWxlEpYBCiFleHBvcnRfdG9fc2VjdXJpdHlfY29tbWFuZF9jZW50
ZXIYCiABKA4yTC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLlNjYW5Db25m
aWcuRXhwb3J0VG9TZWN1cml0eUNvbW1hbmRDZW50ZXJSHWV4cG9ydFRvU2VjdXJpdHlDb21t
YW5kQ2VudGVyElcKCnJpc2tfbGV2ZWwYDCABKA4yOC5nb29nbGUuY2xvdWQud2Vic2VjdXJp
dHlzY2FubmVyLnYxLlNjYW5Db25maWcuUmlza0xldmVsUglyaXNrTGV2ZWwSIQoMbWFuYWdl
ZF9zY2FuGA0gASgIUgttYW5hZ2VkU2NhbhIkCg5zdGF0aWNfaXBfc2NhbhgOIAEoCFIMc3Rh
dGljSXBTY2FuEjkKGWlnbm9yZV9odHRwX3N0YXR1c19lcnJvcnMYDyABKAhSFmlnbm9yZUh0
dHBTdGF0dXNFcnJvcnMa6QYKDkF1dGhlbnRpY2F0aW9uEngKDmdvb2dsZV9hY2NvdW50GAEg
ASgLMksuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5TY2FuQ29uZmlnLkF1
dGhlbnRpY2F0aW9uLkdvb2dsZUFjY291bnRCAhgBSABSDWdvb2dsZUFjY291bnQSdAoOY3Vz
dG9tX2FjY291bnQYAiABKAsySy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYx
LlNjYW5Db25maWcuQXV0aGVudGljYXRpb24uQ3VzdG9tQWNjb3VudEgAUg1jdXN0b21BY2Nv
dW50EnQKDmlhcF9jcmVkZW50aWFsGAQgASgLMksuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5
c2Nhbm5lci52MS5TY2FuQ29uZmlnLkF1dGhlbnRpY2F0aW9uLklhcENyZWRlbnRpYWxIAFIN
aWFwQ3JlZGVudGlhbBpLCg1Hb29nbGVBY2NvdW50EhoKCHVzZXJuYW1lGAEgASgJUgh1c2Vy
bmFtZRIaCghwYXNzd29yZBgCIAEoCVIIcGFzc3dvcmQ6AhgBGmQKDUN1c3RvbUFjY291bnQS
GgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGAIgASgJUghwYXNzd29y
ZBIbCglsb2dpbl91cmwYAyABKAlSCGxvZ2luVXJsGqsCCg1JYXBDcmVkZW50aWFsEqkBCh1p
YXBfdGVzdF9zZXJ2aWNlX2FjY291bnRfaW5mbxgBIAEoCzJlLmdvb2dsZS5jbG91ZC53ZWJz
ZWN1cml0eXNjYW5uZXIudjEuU2NhbkNvbmZpZy5BdXRoZW50aWNhdGlvbi5JYXBDcmVkZW50
aWFsLklhcFRlc3RTZXJ2aWNlQWNjb3VudEluZm9IAFIZaWFwVGVzdFNlcnZpY2VBY2NvdW50
SW5mbxpbChlJYXBUZXN0U2VydmljZUFjY291bnRJbmZvEj4KGXRhcmdldF9hdWRpZW5jZV9j
bGllbnRfaWQYASABKAlCA+BBAlIWdGFyZ2V0QXVkaWVuY2VDbGllbnRJZEIRCg9pYXBfY3Jl
ZGVudGlhbHNCEAoOYXV0aGVudGljYXRpb24agQEKCFNjaGVkdWxlEj8KDXNjaGVkdWxlX3Rp
bWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxzY2hlZHVsZVRpbWUSNAoW
aW50ZXJ2YWxfZHVyYXRpb25fZGF5cxgCIAEoBVIUaW50ZXJ2YWxEdXJhdGlvbkRheXMiYAoJ
VXNlckFnZW50EhoKFlVTRVJfQUdFTlRfVU5TUEVDSUZJRUQQABIQCgxDSFJPTUVfTElOVVgQ
ARISCg5DSFJPTUVfQU5EUk9JRBACEhEKDVNBRkFSSV9JUEhPTkUQAyI8CglSaXNrTGV2ZWwS
GgoWUklTS19MRVZFTF9VTlNQRUNJRklFRBAAEgoKBk5PUk1BTBABEgcKA0xPVxACIm0KHUV4
cG9ydFRvU2VjdXJpdHlDb21tYW5kQ2VudGVyEjEKLUVYUE9SVF9UT19TRUNVUklUWV9DT01N
QU5EX0NFTlRFUl9VTlNQRUNJRklFRBAAEgsKB0VOQUJMRUQQARIMCghESVNBQkxFRBACQoUC
CiZjb20uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MUIPU2NhbkNvbmZpZ1By
b3RvUAFaVmNsb3VkLmdvb2dsZS5jb20vZ28vd2Vic2VjdXJpdHlzY2FubmVyL2FwaXYxL3dl
YnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiqgIiR29vZ2xlLkNsb3Vk
LldlYlNlY3VyaXR5U2Nhbm5lci5WMcoCIkdvb2dsZVxDbG91ZFxXZWJTZWN1cml0eVNjYW5u
ZXJcVjHqAiVHb29nbGU6OkNsb3VkOjpXZWJTZWN1cml0eVNjYW5uZXI6OlYxSvw3CgcSBQ4A
wAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMA
EgMSACkKCQoCAwESAxMAKQoICgEIEgMVAD8KCQoCCCUSAxUAPwoICgEIEgMWAG0KCQoCCAsS
AxYAbQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoCCAgSAxgAMAoICgEIEgMZ
AD8KCQoCCAESAxkAPwoICgEIEgMaAD8KCQoCCCkSAxoAPwoICgEIEgMbAD4KCQoCCC0SAxsA
PgpSCgIEABIFHgDAAQEaRSBBIFNjYW5Db25maWcgcmVzb3VyY2UgY29udGFpbnMgdGhlIGNv
bmZpZ3VyYXRpb25zIHRvIGxhdW5jaCBhIHNjYW4uCgoKCgMEAAESAx4IEgoyCgQEAAMAEgQg
AlgDGiQgU2NhbiBhdXRoZW50aWNhdGlvbiBjb25maWd1cmF0aW9uLgoKDAoFBAADAAESAyAK
GApUCgYEAAMAAwASBCIEKwUaRCBEZXNjcmliZXMgYXV0aGVudGljYXRpb24gY29uZmlndXJh
dGlvbiB0aGF0IHVzZXMgYSBHb29nbGUgYWNjb3VudC4KCg4KBwQAAwADAAESAyIMGQoOCgcE
AAMAAwAHEgMjBh8KDwoIBAADAAMABwMSAyMGHwpBCggEAAMAAwACABIDJgYaGjAgUmVxdWly
ZWQuIFRoZSB1c2VyIG5hbWUgb2YgdGhlIEdvb2dsZSBhY2NvdW50LgoKEAoJBAADAAMAAgAF
EgMmBgwKEAoJBAADAAMAAgABEgMmDRUKEAoJBAADAAMAAgADEgMmGBkKrgEKCAQAAwADAAIB
EgMqBhoanAEgUmVxdWlyZWQuIElucHV0IG9ubHkuIFRoZSBwYXNzd29yZCBvZiB0aGUgR29v
Z2xlIGFjY291bnQuIFRoZSBjcmVkZW50aWFsIGlzIHN0b3JlZCBlbmNyeXB0ZWQKIGFuZCBu
b3QgcmV0dXJuZWQgaW4gYW55IHJlc3BvbnNlIG5vciBpbmNsdWRlZCBpbiBhdWRpdCBsb2dz
LgoKEAoJBAADAAMAAgEFEgMqBgwKEAoJBAADAAMAAgEBEgMqDRUKEAoJBAADAAMAAgEDEgMq
GBkKVAoGBAADAAMBEgQuBDgFGkQgRGVzY3JpYmVzIGF1dGhlbnRpY2F0aW9uIGNvbmZpZ3Vy
YXRpb24gdGhhdCB1c2VzIGEgY3VzdG9tIGFjY291bnQuCgoOCgcEAAMAAwEBEgMuDBkKQQoI
BAADAAMBAgASAzAGGhowIFJlcXVpcmVkLiBUaGUgdXNlciBuYW1lIG9mIHRoZSBjdXN0b20g
YWNjb3VudC4KChAKCQQAAwADAQIABRIDMAYMChAKCQQAAwADAQIAARIDMA0VChAKCQQAAwAD
AQIAAxIDMBgZCq4BCggEAAMAAwECARIDNAYaGpwBIFJlcXVpcmVkLiBJbnB1dCBvbmx5LiBU
aGUgcGFzc3dvcmQgb2YgdGhlIGN1c3RvbSBhY2NvdW50LiBUaGUgY3JlZGVudGlhbCBpcyBz
dG9yZWQgZW5jcnlwdGVkCiBhbmQgbm90IHJldHVybmVkIGluIGFueSByZXNwb25zZSBub3Ig
aW5jbHVkZWQgaW4gYXVkaXQgbG9ncy4KChAKCQQAAwADAQIBBRIDNAYMChAKCQQAAwADAQIB
ARIDNA0VChAKCQQAAwADAQIBAxIDNBgZCj8KCAQAAwADAQICEgM3BhsaLiBSZXF1aXJlZC4g
VGhlIGxvZ2luIGZvcm0gVVJMIG9mIHRoZSB3ZWJzaXRlLgoKEAoJBAADAAMBAgIFEgM3BgwK
EAoJBAADAAMBAgIBEgM3DRYKEAoJBAADAAMBAgIDEgM3GRoKWAoGBAADAAMCEgQ7BEoFGkgg
RGVzY3JpYmVzIGF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRpb24gZm9yIElkZW50aXR5LUF3
YXJlLVByb3h5IChJQVApLgoKDgoHBAADAAMCARIDOwwZCp4BCggEAAMAAwIDABIEPgZCBxqL
ASBEZXNjcmliZXMgYXV0aGVudGljYXRpb24gY29uZmlndXJhdGlvbiB3aGVuIFdlYi1TZWN1
cml0eS1TY2FubmVyCiBzZXJ2aWNlIGFjY291bnQgaXMgYWRkZWQgaW4gSWRlbnRpdHktQXdh
cmUtUHJveHkgKElBUCkgYWNjZXNzIHBvbGljaWVzLgoKEAoJBAADAAMCAwABEgM+DicKcAoK
BAADAAMCAwACABIDQQhWGl0gUmVxdWlyZWQuIERlc2NyaWJlcyBPQXV0aDIgY2xpZW50IGlk
IG9mIHJlc291cmNlcyBwcm90ZWN0ZWQgYnkKIElkZW50aXR5LUF3YXJlLVByb3h5IChJQVAp
LgoKEgoLBAADAAMCAwACAAUSA0EIDgoSCgsEAAMAAwIDAAIAARIDQQ8oChIKCwQAAwADAgMA
AgADEgNBKywKEgoLBAADAAMCAwACAAgSA0EtVQoVCg4EAAMAAwIDAAIACJwIABIDQS5UCksK
CAQAAwADAggAEgRFBkkHGjkgSWRlbnRpdHktQXdhcmUtUHJveHkgKElBUCkgQXV0aGVudGlj
YXRpb24gQ29uZmlndXJhdGlvbgoKEAoJBAADAAMCCAABEgNFDBsKkwEKCAQAAwADAgIAEgNI
CEQagQEgQXV0aGVudGljYXRpb24gY29uZmlndXJhdGlvbiB3aGVuIFdlYi1TZWN1cml0eS1T
Y2FubmVyIHNlcnZpY2UKIGFjY291bnQgaXMgYWRkZWQgaW4gSWRlbnRpdHktQXdhcmUtUHJv
eHkgKElBUCkgYWNjZXNzIHBvbGljaWVzLgoKEAoJBAADAAMCAgAGEgNICCEKEAoJBAADAAMC
AgABEgNIIj8KEAoJBAADAAMCAgADEgNIQkMKOQoGBAADAAgAEgROBFcFGikgUmVxdWlyZWQu
CiBBdXRoZW50aWNhdGlvbiBjb25maWd1cmF0aW9uCgoOCgcEAAMACAABEgNOChgKNwoGBAAD
AAIAEgNQBjsaKCBBdXRoZW50aWNhdGlvbiB1c2luZyBhIEdvb2dsZSBhY2NvdW50LgoKDgoH
BAADAAIABhIDUAYTCg4KBwQAAwACAAESA1AUIgoOCgcEAAMAAgADEgNQJSYKDgoHBAADAAIA
CBIDUCc6Cg8KCAQAAwACAAgDEgNQKDkKNwoGBAADAAIBEgNTBicaKCBBdXRoZW50aWNhdGlv
biB1c2luZyBhIGN1c3RvbSBhY2NvdW50LgoKDgoHBAADAAIBBhIDUwYTCg4KBwQAAwACAQES
A1MUIgoOCgcEAAMAAgEDEgNTJSYKQQoGBAADAAICEgNWBicaMiBBdXRoZW50aWNhdGlvbiB1
c2luZyBJZGVudGl0eS1Bd2FyZS1Qcm94eSAoSUFQKS4KCg4KBwQAAwACAgYSA1YGEwoOCgcE
AAMAAgIBEgNWFCIKDgoHBAADAAICAxIDViUmCiwKBAQAAwESBFsCZAMaHiBTY2FuIHNjaGVk
dWxlIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAMBARIDWwoSCvkBCgYEAAMBAgASA2AEMBrpASBB
IHRpbWVzdGFtcCBpbmRpY2F0ZXMgd2hlbiB0aGUgbmV4dCBydW4gd2lsbCBiZSBzY2hlZHVs
ZWQuIFRoZSB2YWx1ZSBpcwogcmVmcmVzaGVkIGJ5IHRoZSBzZXJ2ZXIgYWZ0ZXIgZWFjaCBy
dW4uIElmIHVuc3BlY2lmaWVkLCBpdCB3aWxsIGRlZmF1bHQKIHRvIGN1cnJlbnQgc2VydmVy
IHRpbWUsIHdoaWNoIG1lYW5zIHRoZSBzY2FuIHdpbGwgYmUgc2NoZWR1bGVkIHRvIHN0YXJ0
CiBpbW1lZGlhdGVseS4KCg4KBwQAAwECAAYSA2AEHQoOCgcEAAMBAgABEgNgHisKDgoHBAAD
AQIAAxIDYC4vCksKBgQAAwECARIDYwQlGjwgUmVxdWlyZWQuIFRoZSBkdXJhdGlvbiBvZiB0
aW1lIGJldHdlZW4gZXhlY3V0aW9ucyBpbiBkYXlzLgoKDgoHBAADAQIBBRIDYwQJCg4KBwQA
AwECAQESA2MKIAoOCgcEAAMBAgEDEgNjIyQKNgoEBAAEABIEZwJzAxooIFR5cGUgb2YgdXNl
ciBhZ2VudHMgdXNlZCBmb3Igc2Nhbm5pbmcuCgoMCgUEAAQAARIDZwcQClEKBgQABAACABID
aQQfGkIgVGhlIHVzZXIgYWdlbnQgaXMgdW5rbm93bi4gU2VydmljZSB3aWxsIGRlZmF1bHQg
dG8gQ0hST01FX0xJTlVYLgoKDgoHBAAEAAIAARIDaQQaCg4KBwQABAACAAISA2kdHgpNCgYE
AAQAAgESA2wEFRo+IENocm9tZSBvbiBMaW51eC4gVGhpcyBpcyB0aGUgc2VydmljZSBkZWZh
dWx0IGlmIHVuc3BlY2lmaWVkLgoKDgoHBAAEAAIBARIDbAQQCg4KBwQABAACAQISA2wTFAoj
CgYEAAQAAgISA28EFxoUIENocm9tZSBvbiBBbmRyb2lkLgoKDgoHBAAEAAICARIDbwQSCg4K
BwQABAACAgISA28VFgoiCgYEAAQAAgMSA3IEFhoTIFNhZmFyaSBvbiBJUGhvbmUuCgoOCgcE
AAQAAgMBEgNyBBEKDgoHBAAEAAIDAhIDchQVCt0BCgQEAAQBEgV4AoEBAxrNASBTY2FuIHJp
c2sgbGV2ZWxzIHN1cHBvcnRlZCBieSBXZWIgU2VjdXJpdHkgU2Nhbm5lci4gTE9XIGltcGFj
dAogc2Nhbm5pbmcgd2lsbCBtaW5pbWl6ZSByZXF1ZXN0cyB3aXRoIHRoZSBwb3RlbnRpYWwg
dG8gbW9kaWZ5IGRhdGEuIFRvCiBhY2hpZXZlIHRoZSBtYXhpbXVtIHNjYW4gY292ZXJhZ2Us
IE5PUk1BTCByaXNrIGxldmVsIGlzIHJlY29tbWVuZGVkLgoKDAoFBAAEAQESA3gHEAouCgYE
AAQBAgASA3oEHxofIFVzZSBkZWZhdWx0LCB3aGljaCBpcyBOT1JNQUwuCgoOCgcEAAQBAgAB
EgN6BBoKDgoHBAAEAQIAAhIDeh0eCi4KBgQABAECARIDfQQPGh8gTm9ybWFsIHNjYW5uaW5n
IChSZWNvbW1lbmRlZCkKCg4KBwQABAECAQESA30ECgoOCgcEAAQBAgECEgN9DQ4KJwoGBAAE
AQICEgSAAQQMGhcgTG93ZXIgaW1wYWN0IHNjYW5uaW5nCgoPCgcEAAQBAgIBEgSAAQQHCg8K
BwQABAECAgISBIABCgsKYQoEBAAEAhIGhQECjgEDGlEgQ29udHJvbHMgZXhwb3J0IG9mIHNj
YW4gY29uZmlndXJhdGlvbnMgYW5kIHJlc3VsdHMgdG8gU2VjdXJpdHkKIENvbW1hbmQgQ2Vu
dGVyLgoKDQoFBAAEAgESBIUBByQKMAoGBAAEAgIAEgSHAQQ2GiAgVXNlIGRlZmF1bHQsIHdo
aWNoIGlzIEVOQUJMRUQuCgoPCgcEAAQCAgABEgSHAQQxCg8KBwQABAICAAISBIcBNDUKSQoG
BAAEAgIBEgSKAQQQGjkgRXhwb3J0IHJlc3VsdHMgb2YgdGhpcyBzY2FuIHRvIFNlY3VyaXR5
IENvbW1hbmQgQ2VudGVyLgoKDwoHBAAEAgIBARIEigEECwoPCgcEAAQCAgECEgSKAQ4PClAK
BgQABAICAhIEjQEEERpAIERvIG5vdCBleHBvcnQgcmVzdWx0cyBvZiB0aGlzIHNjYW4gdG8g
U2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIuCgoPCgcEAAQCAgIBEgSNAQQMCg8KBwQABAICAgIS
BI0BDxAKuQEKBAQAAgASBJMBAhIaqgEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNjYW5D
b25maWcuIFRoZSBuYW1lIGZvbGxvd3MgdGhlIGZvcm1hdCBvZgogJ3Byb2plY3RzL3twcm9q
ZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9Jy4gVGhlIFNjYW5Db25maWcgSURz
IGFyZQogZ2VuZXJhdGVkIGJ5IHRoZSBzeXN0ZW0uCgoNCgUEAAIABRIEkwECCAoNCgUEAAIA
ARIEkwEJDQoNCgUEAAIAAxIEkwEQEQpLCgQEAAIBEgSWAQIaGj0gUmVxdWlyZWQuIFRoZSB1
c2VyIHByb3ZpZGVkIGRpc3BsYXkgbmFtZSBvZiB0aGUgU2NhbkNvbmZpZy4KCg0KBQQAAgEF
EgSWAQIICg0KBQQAAgEBEgSWAQkVCg0KBQQAAgEDEgSWARgZCoUCCgQEAAICEgScAQIUGvYB
IFRoZSBtYXhpbXVtIFFQUyBkdXJpbmcgc2Nhbm5pbmcuIEEgdmFsaWQgdmFsdWUgcmFuZ2Vz
IGZyb20gNSB0byAyMAogaW5jbHVzaXZlbHkuIElmIHRoZSBmaWVsZCBpcyB1bnNwZWNpZmll
ZCBvciBpdHMgdmFsdWUgaXMgc2V0IDAsIHNlcnZlciB3aWxsCiBkZWZhdWx0IHRvIDE1LiBP
dGhlciB2YWx1ZXMgb3V0c2lkZSBvZiBbNSwgMjBdIHJhbmdlIHdpbGwgYmUgcmVqZWN0ZWQg
d2l0aAogSU5WQUxJRF9BUkdVTUVOVCBlcnJvci4KCg0KBQQAAgIFEgScAQIHCg0KBQQAAgIB
EgScAQgPCg0KBQQAAgIDEgScARITClQKBAQAAgMSBJ8BAiQaRiBSZXF1aXJlZC4gVGhlIHN0
YXJ0aW5nIFVSTHMgZnJvbSB3aGljaCB0aGUgc2Nhbm5lciBmaW5kcyBzaXRlIHBhZ2VzLgoK
DQoFBAACAwQSBJ8BAgoKDQoFBAACAwUSBJ8BCxEKDQoFBAACAwESBJ8BEh8KDQoFBAACAwMS
BJ8BIiMKgwEKBAQAAgQSBKMBAiQadSBUaGUgYXV0aGVudGljYXRpb24gY29uZmlndXJhdGlv
bi4gSWYgc3BlY2lmaWVkLCBzZXJ2aWNlIHdpbGwgdXNlIHRoZQogYXV0aGVudGljYXRpb24g
Y29uZmlndXJhdGlvbiBkdXJpbmcgc2Nhbm5pbmcuCgoNCgUEAAIEBhIEowECEAoNCgUEAAIE
ARIEowERHwoNCgUEAAIEAxIEowEiIwo0CgQEAAIFEgSmAQIbGiYgVGhlIHVzZXIgYWdlbnQg
dXNlZCBkdXJpbmcgc2Nhbm5pbmcuCgoNCgUEAAIFBhIEpgECCwoNCgUEAAIFARIEpgEMFgoN
CgUEAAIFAxIEpgEZGgqgAQoEBAACBhIEqgECKRqRASBUaGUgZXhjbHVkZWQgVVJMIHBhdHRl
cm5zIGFzIGRlc2NyaWJlZCBpbgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3NlY3VyaXR5
LWNvbW1hbmQtY2VudGVyL2RvY3MvaG93LXRvLXVzZS13ZWItc2VjdXJpdHktc2Nhbm5lciNl
eGNsdWRpbmdfdXJscwoKDQoFBAACBgQSBKoBAgoKDQoFBAACBgUSBKoBCxEKDQoFBAACBgES
BKoBEiQKDQoFBAACBgMSBKoBJygKLwoEBAACBxIErQECGBohIFRoZSBzY2hlZHVsZSBvZiB0
aGUgU2NhbkNvbmZpZy4KCg0KBQQAAgcGEgStAQIKCg0KBQQAAgcBEgStAQsTCg0KBQQAAgcD
EgStARYXCl8KBAQAAggSBLEBAkcaUSBDb250cm9scyBleHBvcnQgb2Ygc2NhbiBjb25maWd1
cmF0aW9ucyBhbmQgcmVzdWx0cyB0byBTZWN1cml0eQogQ29tbWFuZCBDZW50ZXIuCgoNCgUE
AAIIBhIEsQECHwoNCgUEAAIIARIEsQEgQQoNCgUEAAIIAxIEsQFERgo0CgQEAAIJEgS0AQIc
GiYgVGhlIHJpc2sgbGV2ZWwgc2VsZWN0ZWQgZm9yIHRoZSBzY2FuCgoNCgUEAAIJBhIEtAEC
CwoNCgUEAAIJARIEtAEMFgoNCgUEAAIJAxIEtAEZGwpZCgQEAAIKEgS4AQIZGksgV2hldGhl
ciB0aGUgc2NhbiBjb25maWcgaXMgbWFuYWdlZCBieSBXZWIgU2VjdXJpdHkgU2Nhbm5lciwg
b3V0cHV0CiBvbmx5LgoKDQoFBAACCgUSBLgBAgYKDQoFBAACCgESBLgBBxMKDQoFBAACCgMS
BLgBFhgKpwEKBAQAAgsSBLwBAhsamAEgV2hldGhlciB0aGUgc2NhbiBjb25maWd1cmF0aW9u
IGhhcyBlbmFibGVkIHN0YXRpYyBJUCBhZGRyZXNzIHNjYW4gZmVhdHVyZS4KIElmIGVuYWJs
ZWQsIHRoZSBzY2FubmVyIHdpbGwgYWNjZXNzIGFwcGxpY2F0aW9ucyBmcm9tIHN0YXRpYyBJ
UCBhZGRyZXNzZXMuCgoNCgUEAAILBRIEvAECBgoNCgUEAAILARIEvAEHFQoNCgUEAAILAxIE
vAEYGgpXCgQEAAIMEgS/AQImGkkgV2hldGhlciB0byBrZWVwIHNjYW5uaW5nIGV2ZW4gaWYg
bW9zdCByZXF1ZXN0cyByZXR1cm4gSFRUUCBlcnJvciBjb2Rlcy4KCg0KBQQAAgwFEgS/AQIG
Cg0KBQQAAgwBEgS/AQcgCg0KBQQAAgwDEgS/ASMlYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig ===
    # Fields for ScanConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: max_qps Type: 5 ()
    # Field: starting_urls Type: 9 ()
    # Field: authentication Type: 11 (.google.cloud.websecurityscanner.v1.ScanConfig.Authentication)
    # Field: user_agent Type: 14 (.google.cloud.websecurityscanner.v1.ScanConfig.UserAgent)
    # Field: blacklist_patterns Type: 9 ()
    # Field: schedule Type: 11 (.google.cloud.websecurityscanner.v1.ScanConfig.Schedule)
    # Field: export_to_security_command_center Type: 14 (.google.cloud.websecurityscanner.v1.ScanConfig.ExportToSecurityCommandCenter)
    # Field: risk_level Type: 14 (.google.cloud.websecurityscanner.v1.ScanConfig.RiskLevel)
    # Field: managed_scan Type: 8 ()
    # Field: static_ip_scan Type: 8 ()
    # Field: ignore_http_status_errors Type: 8 ()

# Enum: ScanConfig::UserAgent
our $ScanConfig_USER_AGENT_UNSPECIFIED = 0;
our $ScanConfig_CHROME_LINUX = 1;
our $ScanConfig_CHROME_ANDROID = 2;
our $ScanConfig_SAFARI_IPHONE = 3;

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

Google::Cloud::Websecurityscanner::V1::ScanConfig - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/scan_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::ScanConfig;

    my $msg = Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig->new({
        name => $name,
        display_name => $display_name,
        max_qps => $max_qps,
        starting_urls => $starting_urls,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/scan_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig

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

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig::Authentication>)

The authentication configuration. If specified, service will use the
authentication configuration during scanning.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::UserAgent>)

The user agent used during scanning.

=item * C<< $msg->blacklist_patterns() >> / C<< $msg->blacklist_patterns($value) >>

Type: C<String>

The excluded URL patterns as described in
https://cloud.google.com/security-command-center/docs/how-to-use-web-security-scanner#excluding_urls

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig::Schedule>)

The schedule of the ScanConfig.

=item * C<< $msg->export_to_security_command_center() >> / C<< $msg->export_to_security_command_center($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ExportToSecurityCommandCenter>)

Controls export of scan configurations and results to Security
Command Center.

=item * C<< $msg->risk_level() >> / C<< $msg->risk_level($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::RiskLevel>)

The risk level selected for the scan

=item * C<< $msg->managed_scan() >> / C<< $msg->managed_scan($value) >>

Type: C<Bool>

Whether the scan config is managed by Web Security Scanner, output
only.

=item * C<< $msg->static_ip_scan() >> / C<< $msg->static_ip_scan($value) >>

Type: C<Bool>

Whether the scan configuration has enabled static IP address scan feature.
If enabled, the scanner will access applications from static IP addresses.

=item * C<< $msg->ignore_http_status_errors() >> / C<< $msg->ignore_http_status_errors($value) >>

Type: C<Bool>

Whether to keep scanning even if most requests return HTTP error codes.

=back

=head3 Enum: ScanConfig::UserAgent

=over 4

=item * C<USER_AGENT_UNSPECIFIED> => C<0>

=item * C<CHROME_LINUX> => C<1>

=item * C<CHROME_ANDROID> => C<2>

=item * C<SAFARI_IPHONE> => C<3>

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::ScanConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
