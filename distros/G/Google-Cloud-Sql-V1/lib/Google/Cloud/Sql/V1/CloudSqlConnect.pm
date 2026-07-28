package Google::Cloud::Sql::V1::CloudSqlConnect;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9jb25uZWN0LnByb3RvEhNnb29nbGUu
Y2xvdWQuc3FsLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxotZ29vZ2xl
L2Nsb3VkL3NxbC92MS9jbG91ZF9zcWxfcmVzb3VyY2VzLnByb3RvGh5nb29nbGUvcHJvdG9i
dWYvZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ijwEK
GUdldENvbm5lY3RTZXR0aW5nc1JlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNl
EhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSPAoJcmVhZF90aW1lGAcgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUghyZWFkVGltZSJgCh1SZXNvbHZlQ29ubmVjdFNl
dHRpbmdzUmVxdWVzdBIeCghkbnNfbmFtZRgBIAEoCUID4EECUgdkbnNOYW1lEh8KCGxvY2F0
aW9uGAIgASgJQgPgQQJSCGxvY2F0aW9uIoALCg9Db25uZWN0U2V0dGluZ3MSEgoEa2luZBgB
IAEoCVIEa2luZBJCCg5zZXJ2ZXJfY2FfY2VydBgCIAEoCzIcLmdvb2dsZS5jbG91ZC5zcWwu
djEuU3NsQ2VydFIMc2VydmVyQ2FDZXJ0EkEKDGlwX2FkZHJlc3NlcxgDIAMoCzIeLmdvb2ds
ZS5jbG91ZC5zcWwudjEuSXBNYXBwaW5nUgtpcEFkZHJlc3NlcxIWCgZyZWdpb24YBCABKAlS
BnJlZ2lvbhJSChBkYXRhYmFzZV92ZXJzaW9uGB8gASgOMicuZ29vZ2xlLmNsb3VkLnNxbC52
MS5TcWxEYXRhYmFzZVZlcnNpb25SD2RhdGFiYXNlVmVyc2lvbhJGCgxiYWNrZW5kX3R5cGUY
ICABKA4yIy5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbEJhY2tlbmRUeXBlUgtiYWNrZW5kVHlw
ZRIfCgtwc2NfZW5hYmxlZBghIAEoCFIKcHNjRW5hYmxlZBIZCghkbnNfbmFtZRgiIAEoCVIH
ZG5zTmFtZRJRCg5zZXJ2ZXJfY2FfbW9kZRgjIAEoDjIrLmdvb2dsZS5jbG91ZC5zcWwudjEu
Q29ubmVjdFNldHRpbmdzLkNhTW9kZVIMc2VydmVyQ2FNb2RlEkcKIGN1c3RvbV9zdWJqZWN0
X2FsdGVybmF0aXZlX25hbWVzGCUgAygJUh1jdXN0b21TdWJqZWN0QWx0ZXJuYXRpdmVOYW1l
cxJFCglkbnNfbmFtZXMYJiADKAsyIy5nb29nbGUuY2xvdWQuc3FsLnYxLkRuc05hbWVNYXBw
aW5nQgPgQQNSCGRuc05hbWVzEiIKCm5vZGVfY291bnQYPyABKAVIAFIJbm9kZUNvdW50iAEB
ElUKBW5vZGVzGEAgAygLMjouZ29vZ2xlLmNsb3VkLnNxbC52MS5Db25uZWN0U2V0dGluZ3Mu
Q29ubmVjdFBvb2xOb2RlQ29uZmlnQgPgQQNSBW5vZGVzEnEKFG1keF9wcm90b2NvbF9zdXBw
b3J0GCcgAygOMjcuZ29vZ2xlLmNsb3VkLnNxbC52MS5Db25uZWN0U2V0dGluZ3MuTWR4UHJv
dG9jb2xTdXBwb3J0QgbgQQPgQQFSEm1keFByb3RvY29sU3VwcG9ydBIvCg9jb25uZWN0aW9u
X25hbWUYKCABKAlCBuBBA+BBAVIOY29ubmVjdGlvbk5hbWUa/wEKFUNvbm5lY3RQb29sTm9k
ZUNvbmZpZxIcCgRuYW1lGAEgASgJQgPgQQNIAFIEbmFtZYgBARJGCgxpcF9hZGRyZXNzZXMY
AiADKAsyHi5nb29nbGUuY2xvdWQuc3FsLnYxLklwTWFwcGluZ0ID4EEDUgtpcEFkZHJlc3Nl
cxIjCghkbnNfbmFtZRgDIAEoCUID4EEDSAFSB2Ruc05hbWWIAQESRQoJZG5zX25hbWVzGAQg
AygLMiMuZ29vZ2xlLmNsb3VkLnNxbC52MS5EbnNOYW1lTWFwcGluZ0ID4EEDUghkbnNOYW1l
c0IHCgVfbmFtZUILCglfZG5zX25hbWUieQoGQ2FNb2RlEhcKE0NBX01PREVfVU5TUEVDSUZJ
RUQQABIeChpHT09HTEVfTUFOQUdFRF9JTlRFUk5BTF9DQRABEhkKFUdPT0dMRV9NQU5BR0VE
X0NBU19DQRACEhsKF0NVU1RPTUVSX01BTkFHRURfQ0FTX0NBEAMiVAoSTWR4UHJvdG9jb2xT
dXBwb3J0EiQKIE1EWF9QUk9UT0NPTF9TVVBQT1JUX1VOU1BFQ0lGSUVEEAASGAoUQ0xJRU5U
X1BST1RPQ09MX1RZUEUQAUINCgtfbm9kZV9jb3VudCKiAgocR2VuZXJhdGVFcGhlbWVyYWxD
ZXJ0UmVxdWVzdBIaCghpbnN0YW5jZRgBIAEoCVIIaW5zdGFuY2USGAoHcHJvamVjdBgCIAEo
CVIHcHJvamVjdBIeCgpwdWJsaWNfa2V5GAMgASgJUgpwdWJsaWNfa2V5EicKDGFjY2Vzc190
b2tlbhgEIAEoCUID4EEBUgxhY2Nlc3NfdG9rZW4SPAoJcmVhZF90aW1lGAcgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUghyZWFkVGltZRJFCg52YWxpZF9kdXJhdGlv
bhgMIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EEBUg12YWxpZER1cmF0aW9u
ImQKHUdlbmVyYXRlRXBoZW1lcmFsQ2VydFJlc3BvbnNlEkMKDmVwaGVtZXJhbF9jZXJ0GAEg
ASgLMhwuZ29vZ2xlLmNsb3VkLnNxbC52MS5Tc2xDZXJ0Ug1lcGhlbWVyYWxDZXJ0Ms8FChFT
cWxDb25uZWN0U2VydmljZRKvAQoSR2V0Q29ubmVjdFNldHRpbmdzEi4uZ29vZ2xlLmNsb3Vk
LnNxbC52MS5HZXRDb25uZWN0U2V0dGluZ3NSZXF1ZXN0GiQuZ29vZ2xlLmNsb3VkLnNxbC52
MS5Db25uZWN0U2V0dGluZ3MiQ4LT5JMCPRI7L3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0
YW5jZXMve2luc3RhbmNlfS9jb25uZWN0U2V0dGluZ3MSugEKFlJlc29sdmVDb25uZWN0U2V0
dGluZ3MSMi5nb29nbGUuY2xvdWQuc3FsLnYxLlJlc29sdmVDb25uZWN0U2V0dGluZ3NSZXF1
ZXN0GiQuZ29vZ2xlLmNsb3VkLnNxbC52MS5Db25uZWN0U2V0dGluZ3MiRoLT5JMCQBI+L3Yx
L2xvY2F0aW9ucy97bG9jYXRpb259L2Rucy97ZG5zX25hbWV9OnJlc29sdmVDb25uZWN0U2V0
dGluZ3MSzAEKFUdlbmVyYXRlRXBoZW1lcmFsQ2VydBIxLmdvb2dsZS5jbG91ZC5zcWwudjEu
R2VuZXJhdGVFcGhlbWVyYWxDZXJ0UmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5zcWwudjEuR2Vu
ZXJhdGVFcGhlbWVyYWxDZXJ0UmVzcG9uc2UiTILT5JMCRiJBL3YxL3Byb2plY3RzL3twcm9q
ZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfTpnZW5lcmF0ZUVwaGVtZXJhbENlcnQ6ASoafMpB
F3NxbGFkbWluLmdvb2dsZWFwaXMuY29t0kFfaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3Nx
bHNlcnZpY2UuYWRtaW5CXAoXY29tLmdvb2dsZS5jbG91ZC5zcWwudjFCFENsb3VkU3FsQ29u
bmVjdFByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vc3FsL2FwaXYxL3NxbHBiO3NxbHBi
SpJBCgcSBQ4A8AEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
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
AxYAKAoJCgIDBRIDFwApCggKAQgSAxkAQAoJCgIICxIDGQBACggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsANQoJCgIICBIDGwA1CggKAQgSAxwAMAoJCgIIARIDHAAwCigKAgYAEgQf
AEABGhwgQ2xvdWQgU1FMIGNvbm5lY3Qgc2VydmljZS4KCgoKAwYAARIDHwgZCgoKAwYAAxID
IAI/CgwKBQYAA5kIEgMgAj8KCwoDBgADEgQhAiM5Cg0KBQYAA5oIEgQhAiM5CkYKBAYAAgAS
BCYCKgMaOCBSZXRyaWV2ZXMgY29ubmVjdCBzZXR0aW5ncyBhYm91dCBhIENsb3VkIFNRTCBp
bnN0YW5jZS4KCgwKBQYAAgABEgMmBhgKDAoFBgACAAISAyYZMgoMCgUGAAIAAxIDJj1MCg0K
BQYAAgAEEgQnBCkGChEKCQYAAgAEsMq8IhIEJwQpBgpjCgQGAAIBEgQuAjMDGlUgUmV0cmll
dmVzIGNvbm5lY3Qgc2V0dGluZ3MgYWJvdXQgYSBDbG91ZCBTUUwgaW5zdGFuY2UgdXNpbmcg
dGhlIGluc3RhbmNlCiBETlMgbmFtZS4KCgwKBQYAAgEBEgMuBhwKDAoFBgACAQISAy4dOgoM
CgUGAAIBAxIDLw8eCg0KBQYAAgEEEgQwBDIGChEKCQYAAgEEsMq8IhIEMAQyBgr5AQoEBgAC
AhIEOQI/AxrqASBHZW5lcmF0ZXMgYSBzaG9ydC1saXZlZCBYNTA5IGNlcnRpZmljYXRlIGNv
bnRhaW5pbmcgdGhlIHByb3ZpZGVkIHB1YmxpYyBrZXkKIGFuZCBzaWduZWQgYnkgYSBwcml2
YXRlIGtleSBzcGVjaWZpYyB0byB0aGUgdGFyZ2V0IGluc3RhbmNlLiBVc2VycyBtYXkgdXNl
CiB0aGUgY2VydGlmaWNhdGUgdG8gYXV0aGVudGljYXRlIGFzIHRoZW1zZWx2ZXMgd2hlbiBj
b25uZWN0aW5nIHRvIHRoZQogZGF0YWJhc2UuCgoMCgUGAAICARIDOQYbCgwKBQYAAgICEgM5
HDgKDAoFBgACAgMSAzoPLAoNCgUGAAICBBIEOwQ+BgoRCgkGAAICBLDKvCISBDsEPgYKMQoC
BAASBEMATgEaJSBDb25uZWN0IHNldHRpbmdzIHJldHJpZXZhbCByZXF1ZXN0LgoKCgoDBAAB
EgNDCCEKSwoEBAACABIDRQIWGj4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMg
bm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAAIABRIDRQIICgwKBQQAAgABEgNF
CREKDAoFBAACAAMSA0UUFQpECgQEAAIBEgNIAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9q
ZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAACAQUSA0gCCAoMCgUEAAIB
ARIDSAkQCgwKBQQAAgEDEgNIExQKXwoEBAACAhIETAJNLxpRIE9wdGlvbmFsLiBPcHRpb25h
bCBzbmFwc2hvdCByZWFkIHRpbWVzdGFtcCB0byB0cmFkZSBmcmVzaG5lc3MgZm9yCiBwZXJm
b3JtYW5jZS4KCgwKBQQAAgIGEgNMAhsKDAoFBAACAgESA0wcJQoMCgUEAAICAxIDTCgpCgwK
BQQAAgIIEgNNBi4KDwoIBAACAgicCAASA00HLQoxCgIEARIEUQBXARolIENvbm5lY3Qgc2V0
dGluZ3MgcmV0cmlldmFsIHJlcXVlc3QuCgoKCgMEAQESA1EIJQpVCgQEAQIAEgNTAj8aSCBS
ZXF1aXJlZC4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUg
dGhlIHByb2plY3QgSUQuCgoMCgUEAQIABRIDUwIICgwKBQQBAgABEgNTCREKDAoFBAECAAMS
A1MUFQoMCgUEAQIACBIDUxY+Cg8KCAQBAgAInAgAEgNTFz0KNAoEBAECARIDVgI/GicgUmVx
dWlyZWQuIFRoZSByZWdpb24gb2YgdGhlIGluc3RhbmNlLgoKDAoFBAECAQUSA1YCCAoMCgUE
AQIBARIDVgkRCgwKBQQBAgEDEgNWFBUKDAoFBAECAQgSA1YWPgoPCggEAQIBCJwIABIDVhc9
CjMKAgQCEgVaANEBARomIENvbm5lY3Qgc2V0dGluZ3MgcmV0cmlldmFsIHJlc3BvbnNlLgoK
CgoDBAIBEgNaCBcKUQoEBAIEABIEXAJqAxpDIFZhcmlvdXMgQ2VydGlmaWNhdGUgQXV0aG9y
aXR5IChDQSkgbW9kZXMgZm9yIGNlcnRpZmljYXRlIHNpZ25pbmcuCgoMCgUEAgQAARIDXAcN
CiQKBgQCBAACABIDXgQcGhUgQ0EgbW9kZSBpcyB1bmtub3duLgoKDgoHBAIEAAIAARIDXgQX
Cg4KBwQCBAACAAISA14aGwo4CgYEAgQAAgESA2EEIxopIEdvb2dsZS1tYW5hZ2VkIHNlbGYt
c2lnbmVkIGludGVybmFsIENBLgoKDgoHBAIEAAIBARIDYQQeCg4KBwQCBAACAQISA2EhIgqE
AQoGBAIEAAICEgNlBB4adSBHb29nbGUtbWFuYWdlZCByZWdpb25hbCBDQSBwYXJ0IG9mIHJv
b3QgQ0EgaGllcmFyY2h5IGhvc3RlZCBvbiBHb29nbGUKIENsb3VkJ3MgQ2VydGlmaWNhdGUg
QXV0aG9yaXR5IFNlcnZpY2UgKENBUykuCgoOCgcEAgQAAgIBEgNlBBkKDgoHBAIEAAICAhID
ZRwdCmMKBgQCBAACAxIDaQQgGlQgQ3VzdG9tZXItbWFuYWdlZCBDQSBob3N0ZWQgb24gR29v
Z2xlIENsb3VkJ3MgQ2VydGlmaWNhdGUgQXV0aG9yaXR5CiBTZXJ2aWNlIChDQVMpLgoKDgoH
BAIEAAIDARIDaQQbCg4KBwQCBAACAwISA2keHwpCCgQEAgMAEgRtAn0DGjQgRGV0YWlscyBv
ZiBhIHNpbmdsZSByZWFkIHBvb2wgbm9kZSBvZiBhIHJlYWQgcG9vbC4KCgwKBQQCAwABEgNt
Ch8KXgoGBAIDAAIAEgNwBEkaTyBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIHJlYWQg
cG9vbCBub2RlLiBEb2Vzbid0IGluY2x1ZGUgdGhlIHByb2plY3QKIElELgoKDgoHBAIDAAIA
BBIDcAQMCg4KBwQCAwACAAUSA3ANEwoOCgcEAgMAAgABEgNwFBgKDgoHBAIDAAIAAxIDcBsc
Cg4KBwQCAwACAAgSA3AdSAoRCgoEAgMAAgAInAgAEgNwHkcKcwoGBAIDAAIBEgR0BHU0GmMg
T3V0cHV0IG9ubHkuIE1hcHBpbmdzIGNvbnRhaW5pbmcgSVAgYWRkcmVzc2VzIHRoYXQgY2Fu
IGJlIHVzZWQgdG8gY29ubmVjdAogdG8gdGhlIHJlYWQgcG9vbCBub2RlLgoKDgoHBAIDAAIB
BBIDdAQMCg4KBwQCAwACAQYSA3QNFgoOCgcEAgMAAgEBEgN0FyMKDgoHBAIDAAIBAxIDdCYn
Cg4KBwQCAwACAQgSA3UIMwoRCgoEAgMAAgEInAgAEgN1CTIKQQoGBAIDAAICEgN4BE0aMiBP
dXRwdXQgb25seS4gVGhlIEROUyBuYW1lIG9mIHRoZSByZWFkIHBvb2wgbm9kZS4KCg4KBwQC
AwACAgQSA3gEDAoOCgcEAgMAAgIFEgN4DRMKDgoHBAIDAAICARIDeBQcCg4KBwQCAwACAgMS
A3gfIAoOCgcEAgMAAgIIEgN4IUwKEQoKBAIDAAICCJwIABIDeCJLClEKBgQCAwACAxIEewR8
NBpBIE91dHB1dCBvbmx5LiBUaGUgbGlzdCBvZiBETlMgbmFtZXMgdXNlZCBieSB0aGlzIHJl
YWQgcG9vbCBub2RlLgoKDgoHBAIDAAIDBBIDewQMCg4KBwQCAwACAwYSA3sNGwoOCgcEAgMA
AgMBEgN7HCUKDgoHBAIDAAIDAxIDeygpCg4KBwQCAwACAwgSA3wIMwoRCgoEAgMAAgMInAgA
EgN8CTIKZQoEBAIEARIGgQEChwEDGlUgTWR4UHJvdG9jb2xTdXBwb3J0IGRlc2NyaWJlcyBw
YXJ0cyBvZiB0aGUgTURYIHByb3RvY29sIHN1cHBvcnRlZCBieSB0aGlzCiBpbnN0YW5jZS4K
Cg0KBQQCBAEBEgSBAQcZCiAKBgQCBAECABIEgwEEKRoQIE5vdCBzcGVjaWZpZWQuCgoPCgcE
AgQBAgABEgSDAQQkCg8KBwQCBAECAAISBIMBJygKUQoGBAIEAQIBEgSGAQQdGkEgQ2xpZW50
IHNob3VsZCBzZW5kIHRoZSBjbGllbnQgcHJvdG9jb2wgdHlwZSBpbiB0aGUgTURYIHJlcXVl
c3QuCgoPCgcEAgQBAgEBEgSGAQQYCg8KBwQCBAECAQISBIYBGxwKNQoEBAICABIEigECEhon
IFRoaXMgaXMgYWx3YXlzIGBzcWwjY29ubmVjdFNldHRpbmdzYC4KCg0KBQQCAgAFEgSKAQII
Cg0KBQQCAgABEgSKAQkNCg0KBQQCAgADEgSKARARCiIKBAQCAgESBI0BAh0aFCBTU0wgY29u
ZmlndXJhdGlvbi4KCg0KBQQCAgEGEgSNAQIJCg0KBQQCAgEBEgSNAQoYCg0KBQQCAgEDEgSN
ARscCjsKBAQCAgISBJABAiYaLSBUaGUgYXNzaWduZWQgSVAgYWRkcmVzc2VzIGZvciB0aGUg
aW5zdGFuY2UuCgoNCgUEAgICBBIEkAECCgoNCgUEAgICBhIEkAELFAoNCgUEAgICARIEkAEV
IQoNCgUEAgICAxIEkAEkJQqWAQoEBAICAxIElAECFBqHASBUaGUgY2xvdWQgcmVnaW9uIGZv
ciB0aGUgaW5zdGFuY2UuIEZvciBleGFtcGxlLCBgdXMtY2VudHJhbDFgLAogYGV1cm9wZS13
ZXN0MWAuIFRoZSByZWdpb24gY2Fubm90IGJlIGNoYW5nZWQgYWZ0ZXIgaW5zdGFuY2UgY3Jl
YXRpb24uCgoNCgUEAgIDBRIElAECCAoNCgUEAgIDARIElAEJDwoNCgUEAgIDAxIElAESEwrD
BAoEBAICBBIEoQECKxq0BCBUaGUgZGF0YWJhc2UgZW5naW5lIHR5cGUgYW5kIHZlcnNpb24u
IFRoZSBgZGF0YWJhc2VWZXJzaW9uYAogZmllbGQgY2Fubm90IGJlIGNoYW5nZWQgYWZ0ZXIg
aW5zdGFuY2UgY3JlYXRpb24uCiAgIE15U1FMIGluc3RhbmNlczogYE1ZU1FMXzhfMGAsIGBN
WVNRTF81XzdgIChkZWZhdWx0KSwKIG9yIGBNWVNRTF81XzZgLgogICBQb3N0Z3JlU1FMIGlu
c3RhbmNlczogYFBPU1RHUkVTXzlfNmAsIGBQT1NUR1JFU18xMGAsCiBgUE9TVEdSRVNfMTFg
LCBgUE9TVEdSRVNfMTJgIChkZWZhdWx0KSwgYFBPU1RHUkVTXzEzYCwgb3IgYFBPU1RHUkVT
XzE0YC4KICAgU1FMIFNlcnZlciBpbnN0YW5jZXM6IGBTUUxTRVJWRVJfMjAxN19TVEFOREFS
RGAgKGRlZmF1bHQpLAogYFNRTFNFUlZFUl8yMDE3X0VOVEVSUFJJU0VgLCBgU1FMU0VSVkVS
XzIwMTdfRVhQUkVTU2AsCiBgU1FMU0VSVkVSXzIwMTdfV0VCYCwgYFNRTFNFUlZFUl8yMDE5
X1NUQU5EQVJEYCwKIGBTUUxTRVJWRVJfMjAxOV9FTlRFUlBSSVNFYCwgYFNRTFNFUlZFUl8y
MDE5X0VYUFJFU1NgLCBvcgogYFNRTFNFUlZFUl8yMDE5X1dFQmAuCgoNCgUEAgIEBhIEoQEC
FAoNCgUEAgIEARIEoQEVJQoNCgUEAgIEAxIEoQEoKgroAQoEBAICBRIEpwECIxrZASBgU0VD
T05EX0dFTmA6IENsb3VkIFNRTCBkYXRhYmFzZSBpbnN0YW5jZS4KIGBFWFRFUk5BTGA6IEEg
ZGF0YWJhc2Ugc2VydmVyIHRoYXQgaXMgbm90IG1hbmFnZWQgYnkgR29vZ2xlLgogVGhpcyBw
cm9wZXJ0eSBpcyByZWFkLW9ubHk7IHVzZSB0aGUgYHRpZXJgIHByb3BlcnR5IGluIHRoZSBg
c2V0dGluZ3NgCiBvYmplY3QgdG8gZGV0ZXJtaW5lIHRoZSBkYXRhYmFzZSB0eXBlLgoKDQoF
BAICBQYSBKcBAhAKDQoFBAICBQESBKcBER0KDQoFBAICBQMSBKcBICIKRgoEBAICBhIEqgEC
GBo4IFdoZXRoZXIgUFNDIGNvbm5lY3Rpdml0eSBpcyBlbmFibGVkIGZvciB0aGlzIGluc3Rh
bmNlLgoKDQoFBAICBgUSBKoBAgYKDQoFBAICBgESBKoBBxIKDQoFBAICBgMSBKoBFRcKLQoE
BAICBxIErQECFxofIFRoZSBkbnMgbmFtZSBvZiB0aGUgaW5zdGFuY2UuCgoNCgUEAgIHBRIE
rQECCAoNCgUEAgIHARIErQEJEQoNCgUEAgIHAxIErQEUFgpLCgQEAgIIEgSwAQIdGj0gU3Bl
Y2lmeSB3aGF0IHR5cGUgb2YgQ0EgaXMgdXNlZCBmb3IgdGhlIHNlcnZlciBjZXJ0aWZpY2F0
ZS4KCg0KBQQCAggGEgSwAQIICg0KBQQCAggBEgSwAQkXCg0KBQQCAggDEgSwARocCkwKBAQC
AgkSBLMBAjgaPiBDdXN0b20gc3ViamVjdCBhbHRlcm5hdGl2ZSBuYW1lcyBmb3IgdGhlIHNl
cnZlciBjZXJ0aWZpY2F0ZS4KCg0KBQQCAgkEEgSzAQIKCg0KBQQCAgkFEgSzAQsRCg0KBQQC
AgkBEgSzARIyCg0KBQQCAgkDEgSzATU3CksKBAQCAgoSBrYBArcBMho7IE91dHB1dCBvbmx5
LiBUaGUgbGlzdCBvZiBETlMgbmFtZXMgdXNlZCBieSB0aGlzIGluc3RhbmNlLgoKDQoFBAIC
CgQSBLYBAgoKDQoFBAICCgYSBLYBCxkKDQoFBAICCgESBLYBGiMKDQoFBAICCgMSBLYBJigK
DQoFBAICCggSBLcBBjEKEAoIBAICCgicCAASBLcBBzAKPQoEBAICCxIEugECIRovIFRoZSBu
dW1iZXIgb2YgcmVhZCBwb29sIG5vZGVzIGluIGEgcmVhZCBwb29sLgoKDQoFBAICCwQSBLoB
AgoKDQoFBAICCwUSBLoBCxAKDQoFBAICCwESBLoBERsKDQoFBAICCwMSBLoBHiAKagoEBAIC
DBIGvgECvwEyGlogT3V0cHV0IG9ubHkuIEVudHJpZXMgY29udGFpbmluZyBpbmZvcm1hdGlv
biBhYm91dCBlYWNoIHJlYWQgcG9vbCBub2RlIG9mCiB0aGUgcmVhZCBwb29sLgoKDQoFBAIC
DAQSBL4BAgoKDQoFBAICDAYSBL4BCyAKDQoFBAICDAESBL4BISYKDQoFBAICDAMSBL4BKSsK
DQoFBAICDAgSBL8BBjEKEAoIBAICDAicCAASBL8BBzAK8gIKBAQCAg0SBsYBAskBBBrhAiBP
cHRpb25hbC4gT3V0cHV0IG9ubHkuIG1keF9wcm90b2NvbF9zdXBwb3J0IGNvbnRyb2xzIGhv
dyB0aGUgY2xpZW50IHVzZXMKIG1ldGFkYXRhIGV4Y2hhbmdlIHdoZW4gY29ubmVjdGluZyB0
byB0aGUgaW5zdGFuY2UuIFRoZSB2YWx1ZXMgaW4gdGhlIGxpc3QKIHJlcHJlc2VudGluZyBw
YXJ0cyBvZiB0aGUgTURYIHByb3RvY29sIHRoYXQgYXJlIHN1cHBvcnRlZCBieSB0aGlzIGlu
c3RhbmNlLgogV2hlbiB0aGUgbGlzdCBpcyBlbXB0eSwgdGhlIGluc3RhbmNlIGRvZXMgbm90
IHN1cHBvcnQgTURYLCBzbyB0aGUgY2xpZW50CiBtdXN0IG5vdCBzZW5kIGFuIE1EWCByZXF1
ZXN0LiBUaGUgZGVmYXVsdCBpcyBlbXB0eS4KCg0KBQQCAg0EEgTGAQIKCg0KBQQCAg0GEgTG
AQsdCg0KBQQCAg0BEgTGAR4yCg0KBQQCAg0DEgTGATU3Cg8KBQQCAg0IEgbGATjJAQMKEAoI
BAICDQicCAASBMcBBC0KEAoIBAICDQicCAESBMgBBCoKlwEKBAQCAg4SBs0BAtABBBqGASBP
cHRpb25hbC4gT3V0cHV0IG9ubHkuIENvbm5lY3Rpb24gbmFtZSBvZiB0aGUgQ2xvdWQgU1FM
IGluc3RhbmNlIHVzZWQgaW4KIGNvbm5lY3Rpb24gc3RyaW5ncywgaW4gdGhlIGZvcm1hdCBw
cm9qZWN0OnJlZ2lvbjppbnN0YW5jZS4KCg0KBQQCAg4FEgTNAQIICg0KBQQCAg4BEgTNAQkY
Cg0KBQQCAg4DEgTNARsdCg8KBQQCAg4IEgbNAR7QAQMKEAoIBAICDgicCAASBM4BBC0KEAoI
BAICDgicCAESBM8BBCoKNwoCBAMSBtQBAOoBARopIEVwaGVtZXJhbCBjZXJ0aWZpY2F0ZSBj
cmVhdGlvbiByZXF1ZXN0LgoKCwoDBAMBEgTUAQgkCkwKBAQDAgASBNYBAhYaPiBDbG91ZCBT
UUwgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4K
Cg0KBQQDAgAFEgTWAQIICg0KBQQDAgABEgTWAQkRCg0KBQQDAgADEgTWARQVCkUKBAQDAgES
BNkBAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGlu
c3RhbmNlLgoKDQoFBAMCAQUSBNkBAggKDQoFBAMCAQESBNkBCRAKDQoFBAMCAQMSBNkBExQK
TAoEBAMCAhIE3AECMxo+IFBFTSBlbmNvZGVkIHB1YmxpYyBrZXkgdG8gaW5jbHVkZSBpbiB0
aGUgc2lnbmVkIGNlcnRpZmljYXRlLgoKDQoFBAMCAgUSBNwBAggKDQoFBAMCAgESBNwBCRMK
DQoFBAMCAgMSBNwBFhcKDQoFBAMCAggSBNwBGDIKDQoFBAMCAgoSBNwBGTEKDQoFBAMCAgoS
BNwBJTEKTgoEBAMCAxIG3wEC4AFLGj4gT3B0aW9uYWwuIEFjY2VzcyB0b2tlbiB0byBpbmNs
dWRlIGluIHRoZSBzaWduZWQgY2VydGlmaWNhdGUuCgoNCgUEAwIDBRIE3wECCAoNCgUEAwID
ARIE3wEJFQoNCgUEAwIDAxIE3wEYGQoNCgUEAwIDCBIE4AEGSgoNCgUEAwIDChIE4AEHIQoN
CgUEAwIDChIE4AETIQoQCggEAwIDCJwIABIE4AEjSQphCgQEAwIEEgbkAQLlAS8aUSBPcHRp
b25hbC4gT3B0aW9uYWwgc25hcHNob3QgcmVhZCB0aW1lc3RhbXAgdG8gdHJhZGUgZnJlc2hu
ZXNzIGZvcgogcGVyZm9ybWFuY2UuCgoNCgUEAwIEBhIE5AECGwoNCgUEAwIEARIE5AEcJQoN
CgUEAwIEAxIE5AEoKQoNCgUEAwIECBIE5QEGLgoQCggEAwIECJwIABIE5QEHLQpMCgQEAwIF
EgboAQLpAS8aPCBPcHRpb25hbC4gSWYgc2V0LCBpdCB3aWxsIGNvbnRhaW4gdGhlIGNlcnQg
dmFsaWQgZHVyYXRpb24uCgoNCgUEAwIFBhIE6AECGgoNCgUEAwIFARIE6AEbKQoNCgUEAwIF
AxIE6AEsLgoNCgUEAwIFCBIE6QEGLgoQCggEAwIFCJwIABIE6QEHLQo3CgIEBBIG7QEA8AEB
GikgRXBoZW1lcmFsIGNlcnRpZmljYXRlIGNyZWF0aW9uIHJlcXVlc3QuCgoLCgMEBAESBO0B
CCUKHgoEBAQCABIE7wECHRoQIEdlbmVyYXRlZCBjZXJ0CgoNCgUEBAIABhIE7wECCQoNCgUE
BAIAARIE7wEKGAoNCgUEBAIAAxIE7wEbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest ===
    # Fields for GetConnectSettingsRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlConnect;

    my $msg = Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<read_time>

Type: Message (.google.protobuf.Timestamp)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest ===
    # Fields for ResolveConnectSettingsRequest
    # Field: dns_name Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlConnect;

    my $msg = Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest->new(
        dns_name => $value,
    );

=head1 FIELDS

=over 4

=item * B<dns_name>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings ===
    # Fields for ConnectSettings
    # Field: kind Type: 9 ()
    # Field: server_ca_cert Type: 11 (.google.cloud.sql.v1.SslCert)
    # Field: ip_addresses Type: 11 (.google.cloud.sql.v1.IpMapping)
    # Field: region Type: 9 ()
    # Field: database_version Type: 14 (.google.cloud.sql.v1.SqlDatabaseVersion)
    # Field: backend_type Type: 14 (.google.cloud.sql.v1.SqlBackendType)
    # Field: psc_enabled Type: 8 ()
    # Field: dns_name Type: 9 ()
    # Field: server_ca_mode Type: 14 (.google.cloud.sql.v1.ConnectSettings.CaMode)
    # Field: custom_subject_alternative_names Type: 9 ()
    # Field: dns_names Type: 11 (.google.cloud.sql.v1.DnsNameMapping)
    # Field: node_count Type: 5 ()
    # Field: nodes Type: 11 (.google.cloud.sql.v1.ConnectSettings.ConnectPoolNodeConfig)
    # Field: mdx_protocol_support Type: 14 (.google.cloud.sql.v1.ConnectSettings.MdxProtocolSupport)
    # Field: connection_name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlConnect;

    my $msg = Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<server_ca_cert>

Type: Message (.google.cloud.sql.v1.SslCert)

=item * B<ip_addresses>

Type: Message (.google.cloud.sql.v1.IpMapping)

=item * B<region>

Type: String

=item * B<database_version>

Type: Enum (.google.cloud.sql.v1.SqlDatabaseVersion)

=item * B<backend_type>

Type: Enum (.google.cloud.sql.v1.SqlBackendType)

=item * B<psc_enabled>

Type: Bool

=item * B<dns_name>

Type: String

=item * B<server_ca_mode>

Type: Enum (.google.cloud.sql.v1.ConnectSettings.CaMode)

=item * B<custom_subject_alternative_names>

Type: String

=item * B<dns_names>

Type: Message (.google.cloud.sql.v1.DnsNameMapping)

=item * B<node_count>

Type: Int32

=item * B<nodes>

Type: Message (.google.cloud.sql.v1.ConnectSettings.ConnectPoolNodeConfig)

=item * B<mdx_protocol_support>

Type: Enum (.google.cloud.sql.v1.ConnectSettings.MdxProtocolSupport)

=item * B<connection_name>

Type: String

=back

=cut

# Enum: ConnectSettings::CaMode
our $ConnectSettings_CA_MODE_UNSPECIFIED = 0;
our $ConnectSettings_GOOGLE_MANAGED_INTERNAL_CA = 1;
our $ConnectSettings_GOOGLE_MANAGED_CAS_CA = 2;
our $ConnectSettings_CUSTOMER_MANAGED_CAS_CA = 3;

=pod

=head2 Enum: ConnectSettings::CaMode

Values:

=over 4

=item * C<CA_MODE_UNSPECIFIED> => 0

=item * C<GOOGLE_MANAGED_INTERNAL_CA> => 1

=item * C<GOOGLE_MANAGED_CAS_CA> => 2

=item * C<CUSTOMER_MANAGED_CAS_CA> => 3

=back

=cut

# Enum: ConnectSettings::MdxProtocolSupport
our $ConnectSettings_MDX_PROTOCOL_SUPPORT_UNSPECIFIED = 0;
our $ConnectSettings_CLIENT_PROTOCOL_TYPE = 1;

=pod

=head2 Enum: ConnectSettings::MdxProtocolSupport

Values:

=over 4

=item * C<MDX_PROTOCOL_SUPPORT_UNSPECIFIED> => 0

=item * C<CLIENT_PROTOCOL_TYPE> => 1

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest ===
    # Fields for GenerateEphemeralCertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: public_key Type: 9 ()
    # Field: access_token Type: 9 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)
    # Field: valid_duration Type: 11 (.google.protobuf.Duration)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlConnect;

    my $msg = Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<public_key>

Type: String

=item * B<access_token>

Type: String

=item * B<read_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<valid_duration>

Type: Message (.google.protobuf.Duration)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse ===
    # Fields for GenerateEphemeralCertResponse
    # Field: ephemeral_cert Type: 11 (.google.cloud.sql.v1.SslCert)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlConnect;

    my $msg = Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse->new(
        ephemeral_cert => $value,
    );

=head1 FIELDS

=over 4

=item * B<ephemeral_cert>

Type: Message (.google.cloud.sql.v1.SslCert)

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlConnect::SqlConnectServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlConnect::SqlConnectServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::SqlConnectServiceClient - Client stub representing the remote SqlConnectService service

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

sub get_connect_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlConnectService',
        method         => 'GetConnectSettings',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings',
    });
}

sub resolve_connect_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlConnectService',
        method         => 'ResolveConnectSettings',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings',
    });
}

sub generate_ephemeral_cert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlConnectService',
        method         => 'GenerateEphemeralCert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
