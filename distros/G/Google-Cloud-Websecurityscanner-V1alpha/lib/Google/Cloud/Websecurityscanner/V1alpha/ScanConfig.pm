package Google::Cloud::Websecurityscanner::V1alpha::ScanConfig;

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
    eval { require Google::Cloud::Websecurityscanner::V1alpha::ScanRun };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvc2Nhbl9jb25maWcu
cHJvdG8SJ2dvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo2
Z29vZ2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MWFscGhhL3NjYW5fcnVuLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqMMCgpTY2FuQ29uZmlnEhIKBG5h
bWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1l
EhcKB21heF9xcHMYAyABKAVSBm1heFFwcxIoCg1zdGFydGluZ191cmxzGAQgAygJQgPgQQJS
DHN0YXJ0aW5nVXJscxJqCg5hdXRoZW50aWNhdGlvbhgFIAEoCzJCLmdvb2dsZS5jbG91ZC53
ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5TY2FuQ29uZmlnLkF1dGhlbnRpY2F0aW9uUg5h
dXRoZW50aWNhdGlvbhJcCgp1c2VyX2FnZW50GAYgASgOMj0uZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWFscGhhLlNjYW5Db25maWcuVXNlckFnZW50Ugl1c2VyQWdlbnQS
LQoSYmxhY2tsaXN0X3BhdHRlcm5zGAcgAygJUhFibGFja2xpc3RQYXR0ZXJucxJYCghzY2hl
ZHVsZRgIIAEoCzI8Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5T
Y2FuQ29uZmlnLlNjaGVkdWxlUghzY2hlZHVsZRJtChB0YXJnZXRfcGxhdGZvcm1zGAkgAygO
MkIuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLlNjYW5Db25maWcu
VGFyZ2V0UGxhdGZvcm1SD3RhcmdldFBsYXRmb3JtcxJPCgpsYXRlc3RfcnVuGAsgASgLMjAu
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLlNjYW5SdW5SCWxhdGVz
dFJ1bhrmAwoOQXV0aGVudGljYXRpb24SeQoOZ29vZ2xlX2FjY291bnQYASABKAsyUC5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2NhbkNvbmZpZy5BdXRoZW50
aWNhdGlvbi5Hb29nbGVBY2NvdW50SABSDWdvb2dsZUFjY291bnQSeQoOY3VzdG9tX2FjY291
bnQYAiABKAsyUC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2Nh
bkNvbmZpZy5BdXRoZW50aWNhdGlvbi5DdXN0b21BY2NvdW50SABSDWN1c3RvbUFjY291bnQa
VAoNR29vZ2xlQWNjb3VudBIfCgh1c2VybmFtZRgBIAEoCUID4EECUgh1c2VybmFtZRIiCghw
YXNzd29yZBgCIAEoCUIG4EEC4EEEUghwYXNzd29yZBp2Cg1DdXN0b21BY2NvdW50Eh8KCHVz
ZXJuYW1lGAEgASgJQgPgQQJSCHVzZXJuYW1lEiIKCHBhc3N3b3JkGAIgASgJQgbgQQLgQQRS
CHBhc3N3b3JkEiAKCWxvZ2luX3VybBgDIAEoCUID4EECUghsb2dpblVybEIQCg5hdXRoZW50
aWNhdGlvbhqGAQoIU2NoZWR1bGUSPwoNc2NoZWR1bGVfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSDHNjaGVkdWxlVGltZRI5ChZpbnRlcnZhbF9kdXJhdGlvbl9k
YXlzGAIgASgFQgPgQQJSFGludGVydmFsRHVyYXRpb25EYXlzImAKCVVzZXJBZ2VudBIaChZV
U0VSX0FHRU5UX1VOU1BFQ0lGSUVEEAASEAoMQ0hST01FX0xJTlVYEAESEgoOQ0hST01FX0FO
RFJPSUQQAhIRCg1TQUZBUklfSVBIT05FEAMiTgoOVGFyZ2V0UGxhdGZvcm0SHwobVEFSR0VU
X1BMQVRGT1JNX1VOU1BFQ0lGSUVEEAASDgoKQVBQX0VOR0lORRABEgsKB0NPTVBVVEUQAjpf
6kFcCix3ZWJzZWN1cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2NhbkNvbmZpZxIscHJv
amVjdHMve3Byb2plY3R9L3NjYW5Db25maWdzL3tzY2FuX2NvbmZpZ31CnQEKK2NvbS5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGFCD1NjYW5Db25maWdQcm90b1AB
WltjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9hcGl2MWFscGhhL3dl
YnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiSo8rCgcSBQ8AnAEBCr0E
CgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQISAxEAMAoJCgIDABIDEwAp
CgkKAgMBEgMUACMKCQoCAwISAxUAQAoJCgIDAxIDFgApCggKAQgSAxgAcgoJCgIICxIDGABy
CggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMAoJCgIICBIDGgAwCggKAQgSAxsARAoJ
CgIIARIDGwBECl8KAgQAEgUfAJwBARpSIEEgU2NhbkNvbmZpZyByZXNvdXJjZSBjb250YWlu
cyB0aGUgY29uZmlndXJhdGlvbnMgdG8gbGF1bmNoIGEgc2Nhbi4KIG5leHQgaWQ6IDEyCgoK
CgMEAAESAx8IEgoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKMgoEBAADABIEJgJNAxok
IFNjYW4gYXV0aGVudGljYXRpb24gY29uZmlndXJhdGlvbi4KCgwKBQQAAwABEgMmChgKVAoG
BAADAAMAEgQoBDIFGkQgRGVzY3JpYmVzIGF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRpb24g
dGhhdCB1c2VzIGEgR29vZ2xlIGFjY291bnQuCgoOCgcEAAMAAwABEgMoDBkKQQoIBAADAAMA
AgASAyoGQxowIFJlcXVpcmVkLiBUaGUgdXNlciBuYW1lIG9mIHRoZSBHb29nbGUgYWNjb3Vu
dC4KChAKCQQAAwADAAIABRIDKgYMChAKCQQAAwADAAIAARIDKg0VChAKCQQAAwADAAIAAxID
KhgZChAKCQQAAwADAAIACBIDKhpCChMKDAQAAwADAAIACJwIABIDKhtBCq8BCggEAAMAAwAC
ARIELgYxCBqcASBSZXF1aXJlZC4gSW5wdXQgb25seS4gVGhlIHBhc3N3b3JkIG9mIHRoZSBH
b29nbGUgYWNjb3VudC4gVGhlIGNyZWRlbnRpYWwgaXMgc3RvcmVkIGVuY3J5cHRlZAogYW5k
IG5vdCByZXR1cm5lZCBpbiBhbnkgcmVzcG9uc2Ugbm9yIGluY2x1ZGVkIGluIGF1ZGl0IGxv
Z3MuCgoQCgkEAAMAAwACAQUSAy4GDAoQCgkEAAMAAwACAQESAy4NFQoQCgkEAAMAAwACAQMS
Ay4YGQoRCgkEAAMAAwACAQgSBC4aMQcKEwoMBAADAAMAAgEInAgAEgMvCC4KEwoMBAADAAMA
AgEInAgBEgMwCDAKVAoGBAADAAMBEgQ1BEIFGkQgRGVzY3JpYmVzIGF1dGhlbnRpY2F0aW9u
IGNvbmZpZ3VyYXRpb24gdGhhdCB1c2VzIGEgY3VzdG9tIGFjY291bnQuCgoOCgcEAAMAAwEB
EgM1DBkKQQoIBAADAAMBAgASAzcGQxowIFJlcXVpcmVkLiBUaGUgdXNlciBuYW1lIG9mIHRo
ZSBjdXN0b20gYWNjb3VudC4KChAKCQQAAwADAQIABRIDNwYMChAKCQQAAwADAQIAARIDNw0V
ChAKCQQAAwADAQIAAxIDNxgZChAKCQQAAwADAQIACBIDNxpCChMKDAQAAwADAQIACJwIABID
NxtBCq8BCggEAAMAAwECARIEOwY+CBqcASBSZXF1aXJlZC4gSW5wdXQgb25seS4gVGhlIHBh
c3N3b3JkIG9mIHRoZSBjdXN0b20gYWNjb3VudC4gVGhlIGNyZWRlbnRpYWwgaXMgc3RvcmVk
IGVuY3J5cHRlZAogYW5kIG5vdCByZXR1cm5lZCBpbiBhbnkgcmVzcG9uc2Ugbm9yIGluY2x1
ZGVkIGluIGF1ZGl0IGxvZ3MuCgoQCgkEAAMAAwECAQUSAzsGDAoQCgkEAAMAAwECAQESAzsN
FQoQCgkEAAMAAwECAQMSAzsYGQoRCgkEAAMAAwECAQgSBDsaPgcKEwoMBAADAAMBAgEInAgA
EgM8CC4KEwoMBAADAAMBAgEInAgBEgM9CDAKPwoIBAADAAMBAgISA0EGRBouIFJlcXVpcmVk
LiBUaGUgbG9naW4gZm9ybSBVUkwgb2YgdGhlIHdlYnNpdGUuCgoQCgkEAAMAAwECAgUSA0EG
DAoQCgkEAAMAAwECAgESA0ENFgoQCgkEAAMAAwECAgMSA0EZGgoQCgkEAAMAAwECAggSA0Eb
QwoTCgwEAAMAAwECAgicCAASA0EcQgo5CgYEAAMACAASBEYETAUaKSBSZXF1aXJlZC4KIEF1
dGhlbnRpY2F0aW9uIGNvbmZpZ3VyYXRpb24KCg4KBwQAAwAIAAESA0YKGAo3CgYEAAMAAgAS
A0gGJxooIEF1dGhlbnRpY2F0aW9uIHVzaW5nIGEgR29vZ2xlIGFjY291bnQuCgoOCgcEAAMA
AgAGEgNIBhMKDgoHBAADAAIAARIDSBQiCg4KBwQAAwACAAMSA0glJgo3CgYEAAMAAgESA0sG
JxooIEF1dGhlbnRpY2F0aW9uIHVzaW5nIGEgY3VzdG9tIGFjY291bnQuCgoOCgcEAAMAAgEG
EgNLBhMKDgoHBAADAAIBARIDSxQiCg4KBwQAAwACAQMSA0slJgosCgQEAAMBEgRQAlkDGh4g
U2NhbiBzY2hlZHVsZSBjb25maWd1cmF0aW9uLgoKDAoFBAADAQESA1AKEgr5AQoGBAADAQIA
EgNVBDAa6QEgQSB0aW1lc3RhbXAgaW5kaWNhdGVzIHdoZW4gdGhlIG5leHQgcnVuIHdpbGwg
YmUgc2NoZWR1bGVkLiBUaGUgdmFsdWUgaXMKIHJlZnJlc2hlZCBieSB0aGUgc2VydmVyIGFm
dGVyIGVhY2ggcnVuLiBJZiB1bnNwZWNpZmllZCwgaXQgd2lsbCBkZWZhdWx0CiB0byBjdXJy
ZW50IHNlcnZlciB0aW1lLCB3aGljaCBtZWFucyB0aGUgc2NhbiB3aWxsIGJlIHNjaGVkdWxl
ZCB0byBzdGFydAogaW1tZWRpYXRlbHkuCgoOCgcEAAMBAgAGEgNVBB0KDgoHBAADAQIAARID
VR4rCg4KBwQAAwECAAMSA1UuLwpLCgYEAAMBAgESA1gETho8IFJlcXVpcmVkLiBUaGUgZHVy
YXRpb24gb2YgdGltZSBiZXR3ZWVuIGV4ZWN1dGlvbnMgaW4gZGF5cy4KCg4KBwQAAwECAQUS
A1gECQoOCgcEAAMBAgEBEgNYCiAKDgoHBAADAQIBAxIDWCMkCg4KBwQAAwECAQgSA1glTQoR
CgoEAAMBAgEInAgAEgNYJkwKNgoEBAAEABIEXAJoAxooIFR5cGUgb2YgdXNlciBhZ2VudHMg
dXNlZCBmb3Igc2Nhbm5pbmcuCgoMCgUEAAQAARIDXAcQClEKBgQABAACABIDXgQfGkIgVGhl
IHVzZXIgYWdlbnQgaXMgdW5rbm93bi4gU2VydmljZSB3aWxsIGRlZmF1bHQgdG8gQ0hST01F
X0xJTlVYLgoKDgoHBAAEAAIAARIDXgQaCg4KBwQABAACAAISA14dHgpNCgYEAAQAAgESA2EE
FRo+IENocm9tZSBvbiBMaW51eC4gVGhpcyBpcyB0aGUgc2VydmljZSBkZWZhdWx0IGlmIHVu
c3BlY2lmaWVkLgoKDgoHBAAEAAIBARIDYQQQCg4KBwQABAACAQISA2ETFAojCgYEAAQAAgIS
A2QEFxoUIENocm9tZSBvbiBBbmRyb2lkLgoKDgoHBAAEAAICARIDZAQSCg4KBwQABAACAgIS
A2QVFgoiCgYEAAQAAgMSA2cEFhoTIFNhZmFyaSBvbiBJUGhvbmUuCgoOCgcEAAQAAgMBEgNn
BBEKDgoHBAAEAAIDAhIDZxQVCkgKBAQABAESBGsCdQMaOiBDbG91ZCBwbGF0Zm9ybXMgc3Vw
cG9ydGVkIGJ5IENsb3VkIFdlYiBTZWN1cml0eSBTY2FubmVyLgoKDAoFBAAEAQESA2sHFQp9
CgYEAAQBAgASA24EJBpuIFRoZSB0YXJnZXQgcGxhdGZvcm0gaXMgdW5rbm93bi4gUmVxdWVz
dHMgd2l0aCB0aGlzIGVudW0gdmFsdWUgd2lsbCBiZQogcmVqZWN0ZWQgd2l0aCBJTlZBTElE
X0FSR1VNRU5UIGVycm9yLgoKDgoHBAAEAQIAARIDbgQfCg4KBwQABAECAAISA24iIworCgYE
AAQBAgESA3EEExocIEdvb2dsZSBBcHAgRW5naW5lIHNlcnZpY2UuCgoOCgcEAAQBAgEBEgNx
BA4KDgoHBAAEAQIBAhIDcRESCi8KBgQABAECAhIDdAQQGiAgR29vZ2xlIENvbXB1dGUgRW5n
aW5lIHNlcnZpY2UuCgoOCgcEAAQBAgIBEgN0BAsKDgoHBAAEAQICAhIDdA4PCrgBCgQEAAIA
EgN6AhIaqgEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNjYW5Db25maWcuIFRoZSBuYW1l
IGZvbGxvd3MgdGhlIGZvcm1hdCBvZgogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25m
aWdzL3tzY2FuQ29uZmlnSWR9Jy4gVGhlIFNjYW5Db25maWcgSURzIGFyZQogZ2VuZXJhdGVk
IGJ5IHRoZSBzeXN0ZW0uCgoMCgUEAAIABRIDegIICgwKBQQAAgABEgN6CQ0KDAoFBAACAAMS
A3oQEQpKCgQEAAIBEgN9AkMaPSBSZXF1aXJlZC4gVGhlIHVzZXIgcHJvdmlkZWQgZGlzcGxh
eSBuYW1lIG9mIHRoZSBTY2FuQ29uZmlnLgoKDAoFBAACAQUSA30CCAoMCgUEAAIBARIDfQkV
CgwKBQQAAgEDEgN9GBkKDAoFBAACAQgSA30aQgoPCggEAAIBCJwIABIDfRtBCoUCCgQEAAIC
EgSDAQIUGvYBIFRoZSBtYXhpbXVtIFFQUyBkdXJpbmcgc2Nhbm5pbmcuIEEgdmFsaWQgdmFs
dWUgcmFuZ2VzIGZyb20gNSB0byAyMAogaW5jbHVzaXZlbHkuIElmIHRoZSBmaWVsZCBpcyB1
bnNwZWNpZmllZCBvciBpdHMgdmFsdWUgaXMgc2V0IDAsIHNlcnZlciB3aWxsCiBkZWZhdWx0
IHRvIDE1LiBPdGhlciB2YWx1ZXMgb3V0c2lkZSBvZiBbNSwgMjBdIHJhbmdlIHdpbGwgYmUg
cmVqZWN0ZWQgd2l0aAogSU5WQUxJRF9BUkdVTUVOVCBlcnJvci4KCg0KBQQAAgIFEgSDAQIH
Cg0KBQQAAgIBEgSDAQgPCg0KBQQAAgIDEgSDARITClQKBAQAAgMSBIYBAk0aRiBSZXF1aXJl
ZC4gVGhlIHN0YXJ0aW5nIFVSTHMgZnJvbSB3aGljaCB0aGUgc2Nhbm5lciBmaW5kcyBzaXRl
IHBhZ2VzLgoKDQoFBAACAwQSBIYBAgoKDQoFBAACAwUSBIYBCxEKDQoFBAACAwESBIYBEh8K
DQoFBAACAwMSBIYBIiMKDQoFBAACAwgSBIYBJEwKEAoIBAACAwicCAASBIYBJUsKgwEKBAQA
AgQSBIoBAiQadSBUaGUgYXV0aGVudGljYXRpb24gY29uZmlndXJhdGlvbi4gSWYgc3BlY2lm
aWVkLCBzZXJ2aWNlIHdpbGwgdXNlIHRoZQogYXV0aGVudGljYXRpb24gY29uZmlndXJhdGlv
biBkdXJpbmcgc2Nhbm5pbmcuCgoNCgUEAAIEBhIEigECEAoNCgUEAAIEARIEigERHwoNCgUE
AAIEAxIEigEiIwo0CgQEAAIFEgSNAQIbGiYgVGhlIHVzZXIgYWdlbnQgdXNlZCBkdXJpbmcg
c2Nhbm5pbmcuCgoNCgUEAAIFBhIEjQECCwoNCgUEAAIFARIEjQEMFgoNCgUEAAIFAxIEjQEZ
Ggp4CgQEAAIGEgSRAQIpGmogVGhlIGJsYWNrbGlzdCBVUkwgcGF0dGVybnMgYXMgZGVzY3Jp
YmVkIGluCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc2VjdXJpdHktc2Nhbm5lci9kb2Nz
L2V4Y2x1ZGVkLXVybHMKCg0KBQQAAgYEEgSRAQIKCg0KBQQAAgYFEgSRAQsRCg0KBQQAAgYB
EgSRARIkCg0KBQQAAgYDEgSRAScoCi8KBAQAAgcSBJQBAhgaISBUaGUgc2NoZWR1bGUgb2Yg
dGhlIFNjYW5Db25maWcuCgoNCgUEAAIHBhIElAECCgoNCgUEAAIHARIElAELEwoNCgUEAAIH
AxIElAEWFwptCgQEAAIIEgSYAQIvGl8gU2V0IG9mIENsb3VkIFBsYXRmb3JtcyB0YXJnZXRl
ZCBieSB0aGUgc2Nhbi4gSWYgZW1wdHksIEFQUF9FTkdJTkUgd2lsbCBiZQogdXNlZCBhcyBh
IGRlZmF1bHQuCgoNCgUEAAIIBBIEmAECCgoNCgUEAAIIBhIEmAELGQoNCgUEAAIIARIEmAEa
KgoNCgUEAAIIAxIEmAEtLgosCgQEAAIJEgSbAQIaGh4gTGF0ZXN0IFNjYW5SdW4gaWYgYXZh
aWxhYmxlLgoKDQoFBAACCQYSBJsBAgkKDQoFBAACCQESBJsBChQKDQoFBAACCQMSBJsBFxli
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig ===
    # Fields for ScanConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: max_qps Type: 5 ()
    # Field: starting_urls Type: 9 ()
    # Field: authentication Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanConfig.Authentication)
    # Field: user_agent Type: 14 (.google.cloud.websecurityscanner.v1alpha.ScanConfig.UserAgent)
    # Field: blacklist_patterns Type: 9 ()
    # Field: schedule Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanConfig.Schedule)
    # Field: target_platforms Type: 14 (.google.cloud.websecurityscanner.v1alpha.ScanConfig.TargetPlatform)
    # Field: latest_run Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanRun)

# Enum: ScanConfig::UserAgent
our $ScanConfig_USER_AGENT_UNSPECIFIED = 0;
our $ScanConfig_CHROME_LINUX = 1;
our $ScanConfig_CHROME_ANDROID = 2;
our $ScanConfig_SAFARI_IPHONE = 3;

# Enum: ScanConfig::TargetPlatform
our $ScanConfig_TARGET_PLATFORM_UNSPECIFIED = 0;
our $ScanConfig_APP_ENGINE = 1;
our $ScanConfig_COMPUTE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::ScanConfig - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/scan_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::ScanConfig;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig->new({
        name => $name,
        display_name => $display_name,
        max_qps => $max_qps,
        starting_urls => $starting_urls,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/scan_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig

A ScanConfig resource contains the configurations to launch a scan.
next id: 12

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

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication>)

The authentication configuration. If specified, service will use the
authentication configuration during scanning.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::UserAgent>)

The user agent used during scanning.

=item * C<< $msg->blacklist_patterns() >> / C<< $msg->blacklist_patterns($value) >>

Type: C<String>

The blacklist URL patterns as described in
https://cloud.google.com/security-scanner/docs/excluded-urls

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Schedule>)

The schedule of the ScanConfig.

=item * C<< $msg->target_platforms() >> / C<< $msg->target_platforms($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::TargetPlatform>)

Set of Cloud Platforms targeted by the scan. If empty, APP_ENGINE will be
used as a default.

=item * C<< $msg->latest_run() >> / C<< $msg->latest_run($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun>)

Latest ScanRun if available.

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

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
