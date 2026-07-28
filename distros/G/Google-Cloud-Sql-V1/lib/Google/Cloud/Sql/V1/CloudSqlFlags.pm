package Google::Cloud::Sql::V1::CloudSqlFlags;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9mbGFncy5wcm90bxITZ29vZ2xlLmNs
b3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aLWdvb2dsZS9j
bG91ZC9zcWwvdjEvY2xvdWRfc3FsX3Jlc291cmNlcy5wcm90bxoeZ29vZ2xlL3Byb3RvYnVm
L3dyYXBwZXJzLnByb3RvIpsBChNTcWxGbGFnc0xpc3RSZXF1ZXN0EikKEGRhdGFiYXNlX3Zl
cnNpb24YASABKAlSD2RhdGFiYXNlVmVyc2lvbhJKCgpmbGFnX3Njb3BlGAMgASgOMiEuZ29v
Z2xlLmNsb3VkLnNxbC52MS5TcWxGbGFnU2NvcGVCA+BBAUgAUglmbGFnU2NvcGWIAQFCDQoL
X2ZsYWdfc2NvcGUiWAoRRmxhZ3NMaXN0UmVzcG9uc2USEgoEa2luZBgBIAEoCVIEa2luZBIv
CgVpdGVtcxgCIAMoCzIZLmdvb2dsZS5jbG91ZC5zcWwudjEuRmxhZ1IFaXRlbXMi5AUKBEZs
YWcSEgoEbmFtZRgBIAEoCVIEbmFtZRI0CgR0eXBlGAIgASgOMiAuZ29vZ2xlLmNsb3VkLnNx
bC52MS5TcWxGbGFnVHlwZVIEdHlwZRJGCgphcHBsaWVzX3RvGAMgAygOMicuZ29vZ2xlLmNs
b3VkLnNxbC52MS5TcWxEYXRhYmFzZVZlcnNpb25SCWFwcGxpZXNUbxIyChVhbGxvd2VkX3N0
cmluZ192YWx1ZXMYBCADKAlSE2FsbG93ZWRTdHJpbmdWYWx1ZXMSOAoJbWluX3ZhbHVlGAUg
ASgLMhsuZ29vZ2xlLnByb3RvYnVmLkludDY0VmFsdWVSCG1pblZhbHVlEjgKCW1heF92YWx1
ZRgGIAEoCzIbLmdvb2dsZS5wcm90b2J1Zi5JbnQ2NFZhbHVlUghtYXhWYWx1ZRJFChByZXF1
aXJlc19yZXN0YXJ0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLkJvb2xWYWx1ZVIPcmVxdWly
ZXNSZXN0YXJ0EhIKBGtpbmQYCCABKAlSBGtpbmQSMwoHaW5fYmV0YRgJIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5Cb29sVmFsdWVSBmluQmV0YRIsChJhbGxvd2VkX2ludF92YWx1ZXMYCiAD
KANSEGFsbG93ZWRJbnRWYWx1ZXMSQAoKZmxhZ19zY29wZRgPIAEoDjIhLmdvb2dsZS5jbG91
ZC5zcWwudjEuU3FsRmxhZ1Njb3BlUglmbGFnU2NvcGUSOgoYcmVjb21tZW5kZWRfc3RyaW5n
X3ZhbHVlGBAgASgJSABSFnJlY29tbWVuZGVkU3RyaW5nVmFsdWUSUQoVcmVjb21tZW5kZWRf
aW50X3ZhbHVlGBEgASgLMhsuZ29vZ2xlLnByb3RvYnVmLkludDY0VmFsdWVIAFITcmVjb21t
ZW5kZWRJbnRWYWx1ZUITChFyZWNvbW1lbmRlZF92YWx1ZSqXAQoLU3FsRmxhZ1R5cGUSHQoZ
U1FMX0ZMQUdfVFlQRV9VTlNQRUNJRklFRBAAEgsKB0JPT0xFQU4QARIKCgZTVFJJTkcQAhIL
CgdJTlRFR0VSEAMSCAoETk9ORRAEEhkKFU1ZU1FMX1RJTUVaT05FX09GRlNFVBAFEgkKBUZM
T0FUEAYSEwoPUkVQRUFURURfU1RSSU5HEAcqbwoMU3FsRmxhZ1Njb3BlEh4KGlNRTF9GTEFH
X1NDT1BFX1VOU1BFQ0lGSUVEEAASGwoXU1FMX0ZMQUdfU0NPUEVfREFUQUJBU0UQARIiCh5T
UUxfRkxBR19TQ09QRV9DT05ORUNUSU9OX1BPT0wQAjL8AQoPU3FsRmxhZ3NTZXJ2aWNlEmsK
BExpc3QSKC5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbEZsYWdzTGlzdFJlcXVlc3QaJi5nb29n
bGUuY2xvdWQuc3FsLnYxLkZsYWdzTGlzdFJlc3BvbnNlIhGC0+STAgsSCS92MS9mbGFncxp8
ykEXc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb23SQV9odHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
c3Fsc2VydmljZS5hZG1pbkJaChdjb20uZ29vZ2xlLmNsb3VkLnNxbC52MUISQ2xvdWRTcWxG
bGFnc1Byb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vc3FsL2FwaXYxL3NxbHBiO3NxbHBi
SusnCgcSBQ4AoAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAcCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVADcKCQoCAwQS
AxYAKAoICgEIEgMYAEAKCQoCCAsSAxgAQAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMa
ADMKCQoCCAgSAxoAMwoICgEIEgMbADAKCQoCCAESAxsAMApHCgIGABIEHgAqARo7IFNlcnZp
Y2UgdG8gbWFuYWdlIGRhdGFiYXNlIGZsYWdzIGZvciBDbG91ZCBTUUwgaW5zdGFuY2VzLgoK
CgoDBgABEgMeCBcKCgoDBgADEgMfAj8KDAoFBgADmQgSAx8CPwoLCgMGAAMSBCACIjkKDQoF
BgADmggSBCACIjkKSwoEBgACABIEJQIpAxo9IExpc3RzIGFsbCBhdmFpbGFibGUgZGF0YWJh
c2UgZmxhZ3MgZm9yIENsb3VkIFNRTCBpbnN0YW5jZXMuCgoMCgUGAAIAARIDJQYKCgwKBQYA
AgACEgMlCx4KDAoFBgACAAMSAyUpOgoNCgUGAAIABBIEJgQoBgoRCgkGAAIABLDKvCISBCYE
KAYKIQoCBAASBC0ANQEaFSBGbGFncyBsaXN0IHJlcXVlc3QuCgoKCgMEAAESAy0IGwqVAQoE
BAACABIDMAIeGocBIERhdGFiYXNlIHR5cGUgYW5kIHZlcnNpb24geW91IHdhbnQgdG8gcmV0
cmlldmUgZmxhZ3MgZm9yLiBCeSBkZWZhdWx0LCB0aGlzCiBtZXRob2QgcmV0dXJucyBmbGFn
cyBmb3IgYWxsIGRhdGFiYXNlIHR5cGVzIGFuZCB2ZXJzaW9ucy4KCgwKBQQAAgAFEgMwAggK
DAoFBAACAAESAzAJGQoMCgUEAAIAAxIDMBwdCokBCgQEAAIBEgM0AlAafCBPcHRpb25hbC4g
U3BlY2lmeSB0aGUgc2NvcGUgb2YgZmxhZ3MgdG8gYmUgcmV0dXJuZWQgYnkgU3FsRmxhZ3NM
aXN0U2VydmljZS4KIFJldHVybiBsaXN0IG9mIGRhdGFiYXNlIGZsYWdzIGlmIHVuc3BlY2lm
aWVkLgoKDAoFBAACAQQSAzQCCgoMCgUEAAIBBhIDNAsXCgwKBQQAAgEBEgM0GCIKDAoFBAAC
AQMSAzQlJgoMCgUEAAIBCBIDNCdPCg8KCAQAAgEInAgAEgM0KE4KIgoCBAESBDgAPgEaFiBG
bGFncyBsaXN0IHJlc3BvbnNlLgoKCgoDBAEBEgM4CBkKLgoEBAECABIDOgISGiEgVGhpcyBp
cyBhbHdheXMgYHNxbCNmbGFnc0xpc3RgLgoKDAoFBAECAAUSAzoCCAoMCgUEAQIAARIDOgkN
CgwKBQQBAgADEgM6EBEKHQoEBAECARIDPQIaGhAgTGlzdCBvZiBmbGFncy4KCgwKBQQBAgEE
EgM9AgoKDAoFBAECAQYSAz0LDwoMCgUEAQIBARIDPRAVCgwKBQQBAgEDEgM9GBkKHgoCBAIS
BEEAeQEaEiBBIGZsYWcgcmVzb3VyY2UuCgoKCgMEAgESA0EIDAp/CgQEAgIAEgNEAhIaciBU
aGlzIGlzIHRoZSBuYW1lIG9mIHRoZSBmbGFnLiBGbGFnIG5hbWVzIGFsd2F5cyB1c2UgdW5k
ZXJzY29yZXMsIG5vdAogaHlwaGVucywgZm9yIGV4YW1wbGU6IGBtYXhfYWxsb3dlZF9wYWNr
ZXRgCgoMCgUEAgIABRIDRAIICgwKBQQCAgABEgNECQ0KDAoFBAICAAMSA0QQEQq6AQoEBAIC
ARIDSQIXGqwBIFRoZSB0eXBlIG9mIHRoZSBmbGFnLiBGbGFncyBhcmUgdHlwZWQgdG8gYmVp
bmcgYEJPT0xFQU5gLCBgU1RSSU5HYCwKIGBJTlRFR0VSYCBvciBgTk9ORWAuIGBOT05FYCBp
cyB1c2VkIGZvciBmbGFncyB0aGF0IGRvIG5vdCB0YWtlIGEKIHZhbHVlLCBzdWNoIGFzIGBz
a2lwX2dyYW50X3RhYmxlc2AuCgoMCgUEAgIBBhIDSQINCgwKBQQCAgEBEgNJDhIKDAoFBAIC
AQMSA0kVFgqyBAoEBAICAhIDVQItGqQEIFRoZSBkYXRhYmFzZSB2ZXJzaW9uIHRoaXMgZmxh
ZyBhcHBsaWVzIHRvLiBDYW4gYmUKIE15U1FMIGluc3RhbmNlczogYE1ZU1FMXzhfMGAsIGBN
WVNRTF84XzBfMThgLCBgTVlTUUxfOF8wXzI2YCwgYE1ZU1FMXzVfN2AsCiBvciBgTVlTUUxf
NV82YC4gUG9zdGdyZVNRTCBpbnN0YW5jZXM6IGBQT1NUR1JFU185XzZgLCBgUE9TVEdSRVNf
MTBgLAogYFBPU1RHUkVTXzExYCBvciBgUE9TVEdSRVNfMTJgLiBTUUwgU2VydmVyIGluc3Rh
bmNlczoKIGBTUUxTRVJWRVJfMjAxN19TVEFOREFSRGAsIGBTUUxTRVJWRVJfMjAxN19FTlRF
UlBSSVNFYCwKIGBTUUxTRVJWRVJfMjAxN19FWFBSRVNTYCwgYFNRTFNFUlZFUl8yMDE3X1dF
QmAsIGBTUUxTRVJWRVJfMjAxOV9TVEFOREFSRGAsCiBgU1FMU0VSVkVSXzIwMTlfRU5URVJQ
UklTRWAsIGBTUUxTRVJWRVJfMjAxOV9FWFBSRVNTYCwgb3IKIGBTUUxTRVJWRVJfMjAxOV9X
RUJgLgogU2VlIFt0aGUgY29tcGxldGUKIGxpc3RdKC9zcWwvZG9jcy9teXNxbC9hZG1pbi1h
cGkvcmVzdC92MS9TcWxEYXRhYmFzZVZlcnNpb24pLgoKDAoFBAICAgQSA1UCCgoMCgUEAgIC
BhIDVQsdCgwKBQQCAgIBEgNVHigKDAoFBAICAgMSA1UrLApSCgQEAgIDEgNYAiwaRSBGb3Ig
YFNUUklOR2AgZmxhZ3MsIGEgbGlzdCBvZiBzdHJpbmdzIHRoYXQgdGhlIHZhbHVlIGNhbiBi
ZSBzZXQgdG8uCgoMCgUEAgIDBBIDWAIKCgwKBQQCAgMFEgNYCxEKDAoFBAICAwESA1gSJwoM
CgUEAgIDAxIDWCorCj4KBAQCAgQSA1sCKxoxIEZvciBgSU5URUdFUmAgZmxhZ3MsIHRoZSBt
aW5pbXVtIGFsbG93ZWQgdmFsdWUuCgoMCgUEAgIEBhIDWwIcCgwKBQQCAgQBEgNbHSYKDAoF
BAICBAMSA1spKgo+CgQEAgIFEgNeAisaMSBGb3IgYElOVEVHRVJgIGZsYWdzLCB0aGUgbWF4
aW11bSBhbGxvd2VkIHZhbHVlLgoKDAoFBAICBQYSA14CHAoMCgUEAgIFARIDXh0mCgwKBQQC
AgUDEgNeKSoKhQEKBAQCAgYSA2ICMRp4IEluZGljYXRlcyB3aGV0aGVyIGNoYW5naW5nIHRo
aXMgZmxhZyB3aWxsIHRyaWdnZXIgYSBkYXRhYmFzZSByZXN0YXJ0LiBPbmx5CiBhcHBsaWNh
YmxlIHRvIFNlY29uZCBHZW5lcmF0aW9uIGluc3RhbmNlcy4KCgwKBQQCAgYGEgNiAhsKDAoF
BAICBgESA2IcLAoMCgUEAgIGAxIDYi8wCikKBAQCAgcSA2UCEhocIFRoaXMgaXMgYWx3YXlz
IGBzcWwjZmxhZ2AuCgoMCgUEAgIHBRIDZQIICgwKBQQCAgcBEgNlCQ0KDAoFBAICBwMSA2UQ
EQo9CgQEAgIIEgNoAigaMCBXaGV0aGVyIG9yIG5vdCB0aGUgZmxhZyBpcyBjb25zaWRlcmVk
IGluIGJldGEuCgoMCgUEAgIIBhIDaAIbCgwKBQQCAggBEgNoHCMKDAoFBAICCAMSA2gmJwqM
AQoEBAICCRIDbAIpGn8gVXNlIHRoaXMgZmllbGQgaWYgb25seSBjZXJ0YWluIGludGVnZXJz
IGFyZSBhY2NlcHRlZC4gQ2FuIGJlIGNvbWJpbmVkCiB3aXRoIG1pbl92YWx1ZSBhbmQgbWF4
X3ZhbHVlIHRvIGFkZCBhZGRpdGlvbmFsIHZhbHVlcy4KCgwKBQQCAgkEEgNsAgoKDAoFBAIC
CQUSA2wLEAoMCgUEAgIJARIDbBEjCgwKBQQCAgkDEgNsJigKHQoEBAICChIDbwIfGhAgU2Nv
cGUgb2YgZmxhZy4KCgwKBQQCAgoGEgNvAg4KDAoFBAICCgESA28PGQoMCgUEAgIKAxIDbxwe
CjYKBAQCCAASBHICeAMaKCBSZWNvbW1lbmRlZCBmbGFnIHZhbHVlIGZvciBVSSBkaXNwbGF5
LgoKDAoFBAIIAAESA3IIGQpICgQEAgILEgN0BCkaOyBSZWNvbW1lbmRlZCBzdHJpbmcgdmFs
dWUgaW4gc3RyaW5nIGZvcm1hdCBmb3IgVUkgZGlzcGxheS4KCgwKBQQCAgsFEgN0BAoKDAoF
BAICCwESA3QLIwoMCgUEAgILAxIDdCYoCkYKBAQCAgwSA3cEOho5IFJlY29tbWVuZGVkIGlu
dCB2YWx1ZSBpbiBpbnRlZ2VyIGZvcm1hdCBmb3IgVUkgZGlzcGxheS4KCgwKBQQCAgwGEgN3
BB4KDAoFBAICDAESA3cfNAoMCgUEAgIMAxIDdzc5CgsKAgUAEgV7AJQBAQoKCgMFAAESA3sF
EAosCgQFAAIAEgN9AiAaHyBUaGlzIGlzIGFuIHVua25vd24gZmxhZyB0eXBlLgoKDAoFBQAC
AAESA30CGwoMCgUFAAIAAhIDfR4fCiIKBAUAAgESBIABAg4aFCBCb29sZWFuIHR5cGUgZmxh
Zy4KCg0KBQUAAgEBEgSAAQIJCg0KBQUAAgECEgSAAQwNCiEKBAUAAgISBIMBAg0aEyBTdHJp
bmcgdHlwZSBmbGFnLgoKDQoFBQACAgESBIMBAggKDQoFBQACAgISBIMBCwwKIgoEBQACAxIE
hgECDhoUIEludGVnZXIgdHlwZSBmbGFnLgoKDQoFBQACAwESBIYBAgkKDQoFBQACAwISBIYB
DA0KOwoEBQACBBIEiQECCxotIEZsYWcgdHlwZSB1c2VkIGZvciBhIHNlcnZlciBzdGFydHVw
IG9wdGlvbi4KCg0KBQUAAgQBEgSJAQIGCg0KBQUAAgQCEgSJAQkKCnwKBAUAAgUSBI0BAhwa
biBUeXBlIGludHJvZHVjZWQgc3BlY2lhbGx5IGZvciBNeVNRTCBUaW1lWm9uZSBvZmZzZXQu
IEFjY2VwdCBhIHN0cmluZyB2YWx1ZQogd2l0aCB0aGUgZm9ybWF0IFstMTI6NTksIDEzOjAw
XS4KCg0KBQUAAgUBEgSNAQIXCg0KBQUAAgUCEgSNARobCiAKBAUAAgYSBJABAgwaEiBGbG9h
dCB0eXBlIGZsYWcuCgoNCgUFAAIGARIEkAECBwoNCgUFAAIGAhIEkAEKCwpKCgQFAAIHEgST
AQIWGjwgQ29tbWEtc2VwYXJhdGVkIGxpc3Qgb2YgdGhlIHN0cmluZ3MgaW4gYSBTcWxGbGFn
VHlwZSBlbnVtLgoKDQoFBQACBwESBJMBAhEKDQoFBQACBwISBJMBFBUKQQoCBQESBpcBAKAB
ARozIFNjb3BlcyBvZiBhIGZsYWcgZGVzY3JpYmUgd2hlcmUgdGhlIGZsYWcgaXMgdXNlZC4K
CgsKAwUBARIElwEFEQo0CgQFAQIAEgSZAQIhGiYgQXNzdW1lIGRhdGFiYXNlIGZsYWdzIGlm
IHVuc3BlY2lmaWVkCgoNCgUFAQIAARIEmQECHAoNCgUFAQIAAhIEmQEfIAoeCgQFAQIBEgSc
AQIeGhAgZGF0YWJhc2UgZmxhZ3MKCg0KBQUBAgEBEgScAQIZCg0KBQUBAgECEgScARwdCjMK
BAUBAgISBJ8BAiUaJSBjb25uZWN0aW9uIHBvb2wgY29uZmlndXJhdGlvbiBmbGFncwoKDQoF
BQECAgESBJ8BAiAKDQoFBQECAgISBJ8BIyRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest ===
    # Fields for SqlFlagsListRequest
    # Field: database_version Type: 9 ()
    # Field: flag_scope Type: 14 (.google.cloud.sql.v1.SqlFlagScope)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlFlags;

    my $msg = Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest->new(
        database_version => $value,
    );

=head1 FIELDS

=over 4

=item * B<database_version>

Type: String

=item * B<flag_scope>

Type: Enum (.google.cloud.sql.v1.SqlFlagScope)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse ===
    # Fields for FlagsListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.Flag)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlFlags;

    my $msg = Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.Flag)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlFlags::Flag ===
    # Fields for Flag
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.sql.v1.SqlFlagType)
    # Field: applies_to Type: 14 (.google.cloud.sql.v1.SqlDatabaseVersion)
    # Field: allowed_string_values Type: 9 ()
    # Field: min_value Type: 11 (.google.protobuf.Int64Value)
    # Field: max_value Type: 11 (.google.protobuf.Int64Value)
    # Field: requires_restart Type: 11 (.google.protobuf.BoolValue)
    # Field: kind Type: 9 ()
    # Field: in_beta Type: 11 (.google.protobuf.BoolValue)
    # Field: allowed_int_values Type: 3 ()
    # Field: flag_scope Type: 14 (.google.cloud.sql.v1.SqlFlagScope)
    # Field: recommended_string_value Type: 9 ()
    # Field: recommended_int_value Type: 11 (.google.protobuf.Int64Value)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlFlags::Flag - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlFlags;

    my $msg = Google::Cloud::Sql::V1::CloudSqlFlags::Flag->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<type>

Type: Enum (.google.cloud.sql.v1.SqlFlagType)

=item * B<applies_to>

Type: Enum (.google.cloud.sql.v1.SqlDatabaseVersion)

=item * B<allowed_string_values>

Type: String

=item * B<min_value>

Type: Message (.google.protobuf.Int64Value)

=item * B<max_value>

Type: Message (.google.protobuf.Int64Value)

=item * B<requires_restart>

Type: Message (.google.protobuf.BoolValue)

=item * B<kind>

Type: String

=item * B<in_beta>

Type: Message (.google.protobuf.BoolValue)

=item * B<allowed_int_values>

Type: Int64

=item * B<flag_scope>

Type: Enum (.google.cloud.sql.v1.SqlFlagScope)

=item * B<recommended_string_value>

Type: String

=item * B<recommended_int_value>

Type: Message (.google.protobuf.Int64Value)

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsServiceClient - Client stub representing the remote SqlFlagsService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlFlags::SqlFlagsListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlFlagsService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlFlags::FlagsListResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlFlags - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
