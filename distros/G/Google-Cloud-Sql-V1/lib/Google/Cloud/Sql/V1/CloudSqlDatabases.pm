package Google::Cloud::Sql::V1::CloudSqlDatabases;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9kYXRhYmFzZXMucHJvdG8SE2dvb2ds
ZS5jbG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGi1nb29n
bGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9yZXNvdXJjZXMucHJvdG8ijgEKGVNxbERhdGFi
YXNlc0RlbGV0ZVJlcXVlc3QSGgoIZGF0YWJhc2UYASABKAlSCGRhdGFiYXNlEhoKCGluc3Rh
bmNlGAIgASgJUghpbnN0YW5jZRIYCgdwcm9qZWN0GAMgASgJUgdwcm9qZWN0Eh8KCGxvY2F0
aW9uGAQgASgJQgPgQQFSCGxvY2F0aW9uIosBChZTcWxEYXRhYmFzZXNHZXRSZXF1ZXN0EhoK
CGRhdGFiYXNlGAEgASgJUghkYXRhYmFzZRIaCghpbnN0YW5jZRgCIAEoCVIIaW5zdGFuY2US
GAoHcHJvamVjdBgDIAEoCVIHcHJvamVjdBIfCghsb2NhdGlvbhgEIAEoCUID4EEBUghsb2Nh
dGlvbiKlAQoZU3FsRGF0YWJhc2VzSW5zZXJ0UmVxdWVzdBIaCghpbnN0YW5jZRgBIAEoCVII
aW5zdGFuY2USGAoHcHJvamVjdBgCIAEoCVIHcHJvamVjdBIxCgRib2R5GGQgASgLMh0uZ29v
Z2xlLmNsb3VkLnNxbC52MS5EYXRhYmFzZVIEYm9keRIfCghsb2NhdGlvbhgDIAEoCUID4EEB
Ughsb2NhdGlvbiJwChdTcWxEYXRhYmFzZXNMaXN0UmVxdWVzdBIaCghpbnN0YW5jZRgBIAEo
CVIIaW5zdGFuY2USGAoHcHJvamVjdBgCIAEoCVIHcHJvamVjdBIfCghsb2NhdGlvbhgDIAEo
CUID4EEBUghsb2NhdGlvbiLBAQoZU3FsRGF0YWJhc2VzVXBkYXRlUmVxdWVzdBIaCghkYXRh
YmFzZRgBIAEoCVIIZGF0YWJhc2USGgoIaW5zdGFuY2UYAiABKAlSCGluc3RhbmNlEhgKB3By
b2plY3QYAyABKAlSB3Byb2plY3QSMQoEYm9keRhkIAEoCzIdLmdvb2dsZS5jbG91ZC5zcWwu
djEuRGF0YWJhc2VSBGJvZHkSHwoIbG9jYXRpb24YBCABKAlCA+BBAVIIbG9jYXRpb24iYAoV
RGF0YWJhc2VzTGlzdFJlc3BvbnNlEhIKBGtpbmQYASABKAlSBGtpbmQSMwoFaXRlbXMYAiAD
KAsyHS5nb29nbGUuY2xvdWQuc3FsLnYxLkRhdGFiYXNlUgVpdGVtczLtCAoTU3FsRGF0YWJh
c2VzU2VydmljZRKiAQoGRGVsZXRlEi4uZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxEYXRhYmFz
ZXNEZWxldGVSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNxbC52MS5PcGVyYXRpb24iSILT5JMC
QipAL3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS9kYXRhYmFz
ZXMve2RhdGFiYXNlfRKbAQoDR2V0EisuZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxEYXRhYmFz
ZXNHZXRSZXF1ZXN0Gh0uZ29vZ2xlLmNsb3VkLnNxbC52MS5EYXRhYmFzZSJIgtPkkwJCEkAv
djEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2RhdGFiYXNlcy97
ZGF0YWJhc2V9Ep0BCgZJbnNlcnQSLi5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbERhdGFiYXNl
c0luc2VydFJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiJDgtPkkwI9
IjUvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2RhdGFiYXNl
czoEYm9keRKfAQoETGlzdBIsLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsRGF0YWJhc2VzTGlz
dFJlcXVlc3QaKi5nb29nbGUuY2xvdWQuc3FsLnYxLkRhdGFiYXNlc0xpc3RSZXNwb25zZSI9
gtPkkwI3EjUvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2Rh
dGFiYXNlcxKnAQoFUGF0Y2gSLi5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbERhdGFiYXNlc1Vw
ZGF0ZVJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiJOgtPkkwJIMkAv
djEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2RhdGFiYXNlcy97
ZGF0YWJhc2V9OgRib2R5EqgBCgZVcGRhdGUSLi5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbERh
dGFiYXNlc1VwZGF0ZVJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiJO
gtPkkwJIGkAvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2Rh
dGFiYXNlcy97ZGF0YWJhc2V9OgRib2R5GnzKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbdJB
X2h0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9zcWxzZXJ2aWNlLmFkbWluQl4KF2NvbS5nb29n
bGUuY2xvdWQuc3FsLnYxQhZDbG91ZFNxbERhdGFiYXNlc1Byb3RvUAFaKWNsb3VkLmdvb2ds
ZS5jb20vZ28vc3FsL2FwaXYxL3NxbHBiO3NxbHBiSrQlCgcSBQ4ApwEBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVADcKCAoBCBIDFwBACgkKAggLEgMXAEAKCAoBCBIDGAAi
CgkKAggKEgMYACIKCAoBCBIDGQA3CgkKAggIEgMZADcKCAoBCBIDGgAwCgkKAggBEgMaADAK
KgoCBgASBB0AVQEaHiBTZXJ2aWNlIHRvIG1hbmFnZSBkYXRhYmFzZXMuCgoKCgMGAAESAx0I
GwoKCgMGAAMSAx4CPwoMCgUGAAOZCBIDHgI/CgsKAwYAAxIEHwIhOQoNCgUGAAOaCBIEHwIh
OQo9CgQGAAIAEgQkAigDGi8gRGVsZXRlcyBhIGRhdGFiYXNlIGZyb20gYSBDbG91ZCBTUUwg
aW5zdGFuY2UuCgoMCgUGAAIAARIDJAYMCgwKBQYAAgACEgMkDSYKDAoFBgACAAMSAyQxOgoN
CgUGAAIABBIEJQQnBgoRCgkGAAIABLDKvCISBCUEJwYKagoEBgACARIELAIwAxpcIFJldHJp
ZXZlcyBhIHJlc291cmNlIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQgYSBkYXRhYmFz
ZSBpbnNpZGUgYSBDbG91ZAogU1FMIGluc3RhbmNlLgoKDAoFBgACAQESAywGCQoMCgUGAAIB
AhIDLAogCgwKBQYAAgEDEgMsKzMKDQoFBgACAQQSBC0ELwYKEQoJBgACAQSwyrwiEgQtBC8G
Cq8BCgQGAAICEgQ2AjsDGqABIEluc2VydHMgYSByZXNvdXJjZSBjb250YWluaW5nIGluZm9y
bWF0aW9uIGFib3V0IGEgZGF0YWJhc2UgaW5zaWRlIGEgQ2xvdWQKIFNRTCBpbnN0YW5jZS4K
CiAqKk5vdGU6KiogWW91IGNhbid0IG1vZGlmeSB0aGUgZGVmYXVsdCBjaGFyYWN0ZXIgc2V0
IGFuZCBjb2xsYXRpb24uCgoMCgUGAAICARIDNgYMCgwKBQYAAgICEgM2DSYKDAoFBgACAgMS
AzYxOgoNCgUGAAICBBIENwQ6BgoRCgkGAAICBLDKvCISBDcEOgYKRAoEBgACAxIEPgJCAxo2
IExpc3RzIGRhdGFiYXNlcyBpbiB0aGUgc3BlY2lmaWVkIENsb3VkIFNRTCBpbnN0YW5jZS4K
CgwKBQYAAgMBEgM+BgoKDAoFBgACAwISAz4LIgoMCgUGAAIDAxIDPi1CCg0KBQYAAgMEEgQ/
BEEGChEKCQYAAgMEsMq8IhIEPwRBBgqZAQoEBgACBBIERgJLAxqKASBQYXJ0aWFsbHkgdXBk
YXRlcyBhIHJlc291cmNlIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQgYSBkYXRhYmFz
ZSBpbnNpZGUKIGEgQ2xvdWQgU1FMIGluc3RhbmNlLiBUaGlzIG1ldGhvZCBzdXBwb3J0cyBw
YXRjaCBzZW1hbnRpY3MuCgoMCgUGAAIEARIDRgYLCgwKBQYAAgQCEgNGDCUKDAoFBgACBAMS
A0YwOQoNCgUGAAIEBBIERwRKBgoRCgkGAAIEBLDKvCISBEcESgYKaAoEBgACBRIETwJUAxpa
IFVwZGF0ZXMgYSByZXNvdXJjZSBjb250YWluaW5nIGluZm9ybWF0aW9uIGFib3V0IGEgZGF0
YWJhc2UgaW5zaWRlIGEgQ2xvdWQKIFNRTCBpbnN0YW5jZS4KCgwKBQYAAgUBEgNPBgwKDAoF
BgACBQISA08NJgoMCgUGAAIFAxIDTzE6Cg0KBQYAAgUEEgRQBFMGChEKCQYAAgUEsMq8IhIE
UARTBgomCgIEABIEWABkARoaIERhdGFiYXNlIGRlbGV0ZSByZXF1ZXN0LgoKCgoDBAABEgNY
CCEKQgoEBAACABIDWgIWGjUgTmFtZSBvZiB0aGUgZGF0YWJhc2UgdG8gYmUgZGVsZXRlZCBp
biB0aGUgaW5zdGFuY2UuCgoMCgUEAAIABRIDWgIICgwKBQQAAgABEgNaCREKDAoFBAACAAMS
A1oUFQpKCgQEAAIBEgNdAhYaPSBEYXRhYmFzZSBpbnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5v
dCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAACAQUSA10CCAoMCgUEAAIBARIDXQkR
CgwKBQQAAgEDEgNdFBUKRAoEBAACAhIDYAIVGjcgUHJvamVjdCBJRCBvZiB0aGUgcHJvamVj
dCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQAAgIFEgNgAggKDAoFBAACAgES
A2AJEAoMCgUEAAICAxIDYBMUCjoKBAQAAgMSA2MCPxotIE9wdGlvbmFsLiBSZWdpb24gb2Yg
dGhlIENsb3VkIFNRTCBpbnN0YW5jZS4KCgwKBQQAAgMFEgNjAggKDAoFBAACAwESA2MJEQoM
CgUEAAIDAxIDYxQVCgwKBQQAAgMIEgNjFj4KDwoIBAACAwicCAASA2MXPQojCgIEARIEZwBz
ARoXIERhdGFiYXNlIGdldCByZXF1ZXN0LgoKCgoDBAEBEgNnCB4KNAoEBAECABIDaQIWGicg
TmFtZSBvZiB0aGUgZGF0YWJhc2UgaW4gdGhlIGluc3RhbmNlLgoKDAoFBAECAAUSA2kCCAoM
CgUEAQIAARIDaQkRCgwKBQQBAgADEgNpFBUKSgoEBAECARIDbAIWGj0gRGF0YWJhc2UgaW5z
dGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCgwKBQQB
AgEFEgNsAggKDAoFBAECAQESA2wJEQoMCgUEAQIBAxIDbBQVCkQKBAQBAgISA28CFRo3IFBy
b2plY3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoM
CgUEAQICBRIDbwIICgwKBQQBAgIBEgNvCRAKDAoFBAECAgMSA28TFAo6CgQEAQIDEgNyAj8a
LSBPcHRpb25hbC4gUmVnaW9uIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoMCgUEAQID
BRIDcgIICgwKBQQBAgMBEgNyCREKDAoFBAECAwMSA3IUFQoMCgUEAQIDCBIDchY+Cg8KCAQB
AgMInAgAEgNyFz0KJwoCBAISBXYAgQEBGhogRGF0YWJhc2UgaW5zZXJ0IHJlcXVlc3QuCgoK
CgMEAgESA3YIIQpKCgQEAgIAEgN4AhYaPSBEYXRhYmFzZSBpbnN0YW5jZSBJRC4gVGhpcyBk
b2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAICAAUSA3gCCAoMCgUEAgIA
ARIDeAkRCgwKBQQCAgADEgN4FBUKRAoEBAICARIDewIVGjcgUHJvamVjdCBJRCBvZiB0aGUg
cHJvamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQCAgEFEgN7AggKDAoF
BAICAQESA3sJEAoMCgUEAgIBAxIDexMUCgsKBAQCAgISA30CFgoMCgUEAgICBhIDfQIKCgwK
BQQCAgIBEgN9Cw8KDAoFBAICAgMSA30SFQo7CgQEAgIDEgSAAQI/Gi0gT3B0aW9uYWwuIFJl
Z2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDQoFBAICAwUSBIABAggKDQoFBAIC
AwESBIABCREKDQoFBAICAwMSBIABFBUKDQoFBAICAwgSBIABFj4KEAoIBAICAwicCAASBIAB
Fz0KJgoCBAMSBoQBAI0BARoYIERhdGFiYXNlIGxpc3QgcmVxdWVzdC4KCgsKAwQDARIEhAEI
HwpMCgQEAwIAEgSGAQIWGj4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90
IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoNCgUEAwIABRIEhgECCAoNCgUEAwIAARIEhgEJ
EQoNCgUEAwIAAxIEhgEUFQpFCgQEAwIBEgSJAQIVGjcgUHJvamVjdCBJRCBvZiB0aGUgcHJv
amVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCg0KBQQDAgEFEgSJAQIICg0KBQQD
AgEBEgSJAQkQCg0KBQQDAgEDEgSJARMUCjsKBAQDAgISBIwBAj8aLSBPcHRpb25hbC4gUmVn
aW9uIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoNCgUEAwICBRIEjAECCAoNCgUEAwIC
ARIEjAEJEQoNCgUEAwICAxIEjAEUFQoNCgUEAwICCBIEjAEWPgoQCggEAwICCJwIABIEjAEX
PQooCgIEBBIGkAEAngEBGhogRGF0YWJhc2UgdXBkYXRlIHJlcXVlc3QuCgoLCgMEBAESBJAB
CCEKQwoEBAQCABIEkgECFho1IE5hbWUgb2YgdGhlIGRhdGFiYXNlIHRvIGJlIHVwZGF0ZWQg
aW4gdGhlIGluc3RhbmNlLgoKDQoFBAQCAAUSBJIBAggKDQoFBAQCAAESBJIBCREKDQoFBAQC
AAMSBJIBFBUKSwoEBAQCARIElQECFho9IERhdGFiYXNlIGluc3RhbmNlIElELiBUaGlzIGRv
ZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoNCgUEBAIBBRIElQECCAoNCgUEBAIB
ARIElQEJEQoNCgUEBAIBAxIElQEUFQpFCgQEBAICEgSYAQIVGjcgUHJvamVjdCBJRCBvZiB0
aGUgcHJvamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCg0KBQQEAgIFEgSYAQII
Cg0KBQQEAgIBEgSYAQkQCg0KBQQEAgIDEgSYARMUCgwKBAQEAgMSBJoBAhYKDQoFBAQCAwYS
BJoBAgoKDQoFBAQCAwESBJoBCw8KDQoFBAQCAwMSBJoBEhUKOwoEBAQCBBIEnQECPxotIE9w
dGlvbmFsLiBSZWdpb24gb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5jZS4KCg0KBQQEAgQFEgSd
AQIICg0KBQQEAgQBEgSdAQkRCg0KBQQEAgQDEgSdARQVCg0KBQQEAgQIEgSdARY+ChAKCAQE
AgQInAgAEgSdARc9CicKAgQFEgahAQCnAQEaGSBEYXRhYmFzZSBsaXN0IHJlc3BvbnNlLgoK
CwoDBAUBEgShAQgdCjMKBAQFAgASBKMBAhIaJSBUaGlzIGlzIGFsd2F5cyBgc3FsI2RhdGFi
YXNlc0xpc3RgLgoKDQoFBAUCAAUSBKMBAggKDQoFBAUCAAESBKMBCQ0KDQoFBAUCAAMSBKMB
EBEKOwoEBAUCARIEpgECHhotIExpc3Qgb2YgZGF0YWJhc2UgcmVzb3VyY2VzIGluIHRoZSBp
bnN0YW5jZS4KCg0KBQQFAgEEEgSmAQIKCg0KBQQFAgEGEgSmAQsTCg0KBQQFAgEBEgSmARQZ
Cg0KBQQFAgEDEgSmARwdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest ===
    # Fields for SqlDatabasesDeleteRequest
    # Field: database Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest->new(
        database => $value,
    );

=head1 FIELDS

=over 4

=item * B<database>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest ===
    # Fields for SqlDatabasesGetRequest
    # Field: database Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest->new(
        database => $value,
    );

=head1 FIELDS

=over 4

=item * B<database>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest ===
    # Fields for SqlDatabasesInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.Database)
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.Database)

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest ===
    # Fields for SqlDatabasesListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest ===
    # Fields for SqlDatabasesUpdateRequest
    # Field: database Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.Database)
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest->new(
        database => $value,
    );

=head1 FIELDS

=over 4

=item * B<database>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.Database)

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse ===
    # Fields for DatabasesListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.Database)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.Database)

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesServiceClient - Client stub representing the remote SqlDatabasesService service

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

sub delete {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Database',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse',
    });
}

sub patch {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Patch',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub update {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Update',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
