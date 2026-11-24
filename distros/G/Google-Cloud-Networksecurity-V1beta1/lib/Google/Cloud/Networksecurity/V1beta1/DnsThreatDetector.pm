package Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector;

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
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvZG5zX3RocmVhdF9kZXRl
Y3Rvci5wcm90bxIkZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExGhxnb29n
bGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLuBQoRRG5zVGhy
ZWF0RGV0ZWN0b3ISGgoEbmFtZRgBIAEoCUIG4EEI4EEFUgRuYW1lEkAKC2NyZWF0ZV90aW1l
GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAK
C3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1
cGRhdGVUaW1lEmAKBmxhYmVscxgEIAMoCzJDLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJp
dHkudjFiZXRhMS5EbnNUaHJlYXREZXRlY3Rvci5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMS
UwoRZXhjbHVkZWRfbmV0d29ya3MYBSADKAlCJuBBAfpBIAoeY29tcHV0ZS5nb29nbGVhcGlz
LmNvbS9OZXR3b3JrUhBleGNsdWRlZE5ldHdvcmtzEmEKCHByb3ZpZGVyGAYgASgOMkAuZ29v
Z2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkRuc1RocmVhdERldGVjdG9yLlBy
b3ZpZGVyQgPgQQJSCHByb3ZpZGVyGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiMgoIUHJvdmlkZXISGAoUUFJPVklERVJfVU5T
UEVDSUZJRUQQABIMCghJTkZPQkxPWBABOq8B6kGrAQowbmV0d29ya3NlY3VyaXR5Lmdvb2ds
ZWFwaXMuY29tL0Ruc1RocmVhdERldGVjdG9yElBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vZG5zVGhyZWF0RGV0ZWN0b3JzL3tkbnNfdGhyZWF0X2RldGVjdG9y
fSoSZG5zVGhyZWF0RGV0ZWN0b3JzMhFkbnNUaHJlYXREZXRlY3RvciK3AQodTGlzdERuc1Ro
cmVhdERldGVjdG9yc1JlcXVlc3QSUAoGcGFyZW50GAEgASgJQjjgQQL6QTISMG5ldHdvcmtz
ZWN1cml0eS5nb29nbGVhcGlzLmNvbS9EbnNUaHJlYXREZXRlY3RvclIGcGFyZW50EiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbiLaAQoeTGlzdERuc1RocmVhdERldGVjdG9yc1Jlc3BvbnNlEmkKFGRuc190
aHJlYXRfZGV0ZWN0b3JzGAEgAygLMjcuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52
MWJldGExLkRuc1RocmVhdERldGVjdG9yUhJkbnNUaHJlYXREZXRlY3RvcnMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiUKC3VucmVhY2hhYmxlGAMgAygJQgPg
QQZSC3VucmVhY2hhYmxlImsKG0dldERuc1RocmVhdERldGVjdG9yUmVxdWVzdBJMCgRuYW1l
GAEgASgJQjjgQQL6QTIKMG5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9EbnNUaHJl
YXREZXRlY3RvclIEbmFtZSKaAgoeQ3JlYXRlRG5zVGhyZWF0RGV0ZWN0b3JSZXF1ZXN0ElAK
BnBhcmVudBgBIAEoCUI44EEC+kEyEjBuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20v
RG5zVGhyZWF0RGV0ZWN0b3JSBnBhcmVudBI4ChZkbnNfdGhyZWF0X2RldGVjdG9yX2lkGAIg
ASgJQgPgQQFSE2Ruc1RocmVhdERldGVjdG9ySWQSbAoTZG5zX3RocmVhdF9kZXRlY3RvchgD
IAEoCzI3Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5EbnNUaHJlYXRE
ZXRlY3RvckID4EECUhFkbnNUaHJlYXREZXRlY3RvciLQAQoeVXBkYXRlRG5zVGhyZWF0RGV0
ZWN0b3JSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrEmwKE2Ruc190aHJlYXRfZGV0ZWN0b3IYAiABKAsy
Ny5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuRG5zVGhyZWF0RGV0ZWN0
b3JCA+BBAlIRZG5zVGhyZWF0RGV0ZWN0b3IibgoeRGVsZXRlRG5zVGhyZWF0RGV0ZWN0b3JS
ZXF1ZXN0EkwKBG5hbWUYASABKAlCOOBBAvpBMgowbmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFw
aXMuY29tL0Ruc1RocmVhdERldGVjdG9yUgRuYW1lMt8KChhEbnNUaHJlYXREZXRlY3RvclNl
cnZpY2US8QEKFkxpc3REbnNUaHJlYXREZXRlY3RvcnMSQy5nb29nbGUuY2xvdWQubmV0d29y
a3NlY3VyaXR5LnYxYmV0YTEuTGlzdERuc1RocmVhdERldGVjdG9yc1JlcXVlc3QaRC5nb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuTGlzdERuc1RocmVhdERldGVjdG9y
c1Jlc3BvbnNlIkyC0+STAj0SOy92MWJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKn0vZG5zVGhyZWF0RGV0ZWN0b3Jz2kEGcGFyZW50Et4BChRHZXREbnNUaHJlYXREZXRl
Y3RvchJBLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5HZXREbnNUaHJl
YXREZXRlY3RvclJlcXVlc3QaNy5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0
YTEuRG5zVGhyZWF0RGV0ZWN0b3IiSoLT5JMCPRI7L3YxYmV0YTEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9kbnNUaHJlYXREZXRlY3RvcnMvKn3aQQRuYW1lEqcCChdDcmVhdGVE
bnNUaHJlYXREZXRlY3RvchJELmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRh
MS5DcmVhdGVEbnNUaHJlYXREZXRlY3RvclJlcXVlc3QaNy5nb29nbGUuY2xvdWQubmV0d29y
a3NlY3VyaXR5LnYxYmV0YTEuRG5zVGhyZWF0RGV0ZWN0b3IijAGC0+STAlIiOy92MWJldGEx
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZG5zVGhyZWF0RGV0ZWN0b3JzOhNk
bnNfdGhyZWF0X2RldGVjdG9y2kExcGFyZW50LGRuc190aHJlYXRfZGV0ZWN0b3IsZG5zX3Ro
cmVhdF9kZXRlY3Rvcl9pZBKpAgoXVXBkYXRlRG5zVGhyZWF0RGV0ZWN0b3ISRC5nb29nbGUu
Y2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuVXBkYXRlRG5zVGhyZWF0RGV0ZWN0b3JS
ZXF1ZXN0GjcuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkRuc1RocmVh
dERldGVjdG9yIo4BgtPkkwJmMk8vdjFiZXRhMS97ZG5zX3RocmVhdF9kZXRlY3Rvci5uYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovZG5zVGhyZWF0RGV0ZWN0b3JzLyp9OhNkbnNfdGhy
ZWF0X2RldGVjdG9y2kEfZG5zX3RocmVhdF9kZXRlY3Rvcix1cGRhdGVfbWFzaxLDAQoXRGVs
ZXRlRG5zVGhyZWF0RGV0ZWN0b3ISRC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYx
YmV0YTEuRGVsZXRlRG5zVGhyZWF0RGV0ZWN0b3JSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVm
LkVtcHR5IkqC0+STAj0qOy92MWJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZG5zVGhyZWF0RGV0ZWN0b3JzLyp92kEEbmFtZRpSykEebmV0d29ya3NlY3VyaXR5Lmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybULhAgooY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMUIWRG5z
VGhyZWF0RGV0ZWN0b3JQcm90b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZWN1
cml0eS9hcGl2MWJldGExL25ldHdvcmtzZWN1cml0eXBiO25ldHdvcmtzZWN1cml0eXBiqgIk
R29vZ2xlLkNsb3VkLk5ldHdvcmtTZWN1cml0eS5WMUJldGExygIkR29vZ2xlXENsb3VkXE5l
dHdvcmtTZWN1cml0eVxWMWJldGEx6gInR29vZ2xlOjpDbG91ZDo6TmV0d29ya1NlY3VyaXR5
OjpWMWJldGEx6kFOCh5jb21wdXRlLmdvb2dsZWFwaXMuY29tL05ldHdvcmsSLHByb2plY3Rz
L3twcm9qZWN0fS9nbG9iYWwvbmV0d29ya3Mve25ldHdvcmt9SoMzCgcSBQ4A6QEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACYKCQoC
AwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAJQoJCgIDBRIDFwAqCgkK
AgMGEgMYACkKCAoBCBIDGgBBCgkKAgglEgMaAEEKCAoBCBIDGwBpCgkKAggLEgMbAGkKCAoB
CBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA3CgkKAggIEgMdADcKCAoBCBIDHgBBCgkKAggB
EgMeAEEKCAoBCBIDHwBBCgkKAggpEgMfAEEKCAoBCBIDIABACgkKAggtEgMgAEAKCQoBCBIE
IQAkAgoMCgQInQgAEgQhACQCCkAKAgYAEgQnAFsBGjQgVGhlIE5ldHdvcmsgU2VjdXJpdHkg
QVBJIGZvciBETlMgVGhyZWF0IERldGVjdG9ycy4KCgoKAwYAARIDJwggCgoKAwYAAxIDKAJG
CgwKBQYAA5kIEgMoAkYKCwoDBgADEgQpAio3Cg0KBQYAA5oIEgQpAio3CkkKBAYAAgASBC0C
MwMaOyBMaXN0cyBEbnNUaHJlYXREZXRlY3RvcnMgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBs
b2NhdGlvbi4KCgwKBQYAAgABEgMtBhwKDAoFBgACAAISAy0dOgoMCgUGAAIAAxIDLg8tCg0K
BQYAAgAEEgQvBDEGChEKCQYAAgAEsMq8IhIELwQxBgoMCgUGAAIABBIDMgQ0Cg8KCAYAAgAE
mwgAEgMyBDQKPwoEBgACARIENgI8AxoxIEdldHMgdGhlIGRldGFpbHMgb2YgYSBzaW5nbGUg
RG5zVGhyZWF0RGV0ZWN0b3IuCgoMCgUGAAIBARIDNgYaCgwKBQYAAgECEgM2GzYKDAoFBgAC
AQMSAzcPIAoNCgUGAAIBBBIEOAQ6BgoRCgkGAAIBBLDKvCISBDgEOgYKDAoFBgACAQQSAzsE
MgoPCggGAAIBBJsIABIDOwQyClAKBAYAAgISBD8CRwMaQiBDcmVhdGVzIGEgbmV3IERuc1Ro
cmVhdERldGVjdG9yIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIC
ARIDPwYdCgwKBQYAAgICEgM/HjwKDAoFBgACAgMSA0APIAoNCgUGAAICBBIEQQREBgoRCgkG
AAICBLDKvCISBEEERAYKDQoFBgACAgQSBEUERjwKEAoIBgACAgSbCAASBEUERjwKMwoEBgAC
AxIESgJRAxolIFVwZGF0ZXMgYSBzaW5nbGUgRG5zVGhyZWF0RGV0ZWN0b3IuCgoMCgUGAAID
ARIDSgYdCgwKBQYAAgMCEgNKHjwKDAoFBgACAwMSA0sPIAoNCgUGAAIDBBIETARPBgoRCgkG
AAIDBLDKvCISBEwETwYKDAoFBgACAwQSA1AETQoPCggGAAIDBJsIABIDUARNCjMKBAYAAgQS
BFQCWgMaJSBEZWxldGVzIGEgc2luZ2xlIERuc1RocmVhdERldGVjdG9yLgoKDAoFBgACBAES
A1QGHQoMCgUGAAIEAhIDVB48CgwKBQYAAgQDEgNVDyQKDQoFBgACBAQSBFYEWAYKEQoJBgAC
BASwyrwiEgRWBFgGCgwKBQYAAgQEEgNZBDIKDwoIBgACBASbCAASA1kEMgqXAgoCBAASBWEA
kAEBGokCIEEgRE5TIHRocmVhdCBkZXRlY3RvciBzZW5kcyBETlMgcXVlcnkgbG9ncyB0byBh
IF9wcm92aWRlcl8gdGhhdCB0aGVuCiBhbmFseXplcyB0aGUgbG9ncyB0byBpZGVudGlmeSB0
aHJlYXQgZXZlbnRzIGluIHRoZSBETlMgcXVlcmllcy4KIEJ5IGRlZmF1bHQsIGFsbCBWUEMg
bmV0d29ya3MgaW4geW91ciBwcm9qZWN0cyBhcmUgaW5jbHVkZWQuIFlvdSBjYW4gZXhjbHVk
ZQogc3BlY2lmaWMgbmV0d29ya3MgYnkgc3VwcGx5aW5nIGBleGNsdWRlZF9uZXR3b3Jrc2Au
CgoKCgMEAAESA2EIGQoLCgMEAAcSBGICZwQKDQoFBAAHnQgSBGICZwQKQgoEBAAEABIEagJw
Axo0IE5hbWUgb2YgdGhlIHByb3ZpZGVyIHVzZWQgZm9yIEROUyB0aHJlYXQgYW5hbHlzaXMu
CgoMCgUEAAQAARIDagcPCikKBgQABAACABIDbAQdGhogQW4gdW5zcGVjaWZpZWQgcHJvdmlk
ZXIuCgoOCgcEAAQAAgABEgNsBBgKDgoHBAAEAAIAAhIDbBscCjsKBgQABAACARIDbwQRGiwg
VGhlIEluZm9ibG94IEROUyB0aHJlYXQgZGV0ZWN0b3IgcHJvdmlkZXIuCgoOCgcEAAQAAgEB
EgNvBAwKDgoHBAAEAAIBAhIDbw8QCk4KBAQAAgASBHMCdgQaQCBJbW11dGFibGUuIElkZW50
aWZpZXIuIE5hbWUgb2YgdGhlIERuc1RocmVhdERldGVjdG9yIHJlc291cmNlLgoKDAoFBAAC
AAUSA3MCCAoMCgUEAAIAARIDcwkNCgwKBQQAAgADEgNzEBEKDQoFBAACAAgSBHMSdgMKDwoI
BAACAAicCAASA3QELAoPCggEAAIACJwIARIDdQQrCi8KBAQAAgESBHkCejIaISBPdXRwdXQg
b25seS4gQ3JlYXRlIHRpbWUgc3RhbXAuCgoMCgUEAAIBBhIDeQIbCgwKBQQAAgEBEgN5HCcK
DAoFBAACAQMSA3kqKwoMCgUEAAIBCBIDegYxCg8KCAQAAgEInAgAEgN6BzAKLwoEBAACAhIE
fQJ+MhohIE91dHB1dCBvbmx5LiBVcGRhdGUgdGltZSBzdGFtcC4KCgwKBQQAAgIGEgN9AhsK
DAoFBAACAgESA30cJwoMCgUEAAICAxIDfSorCgwKBQQAAgIIEgN+BjEKDwoIBAACAgicCAAS
A34HMApnCgQEAAIDEgSCAQJKGlkgT3B0aW9uYWwuIEFueSBsYWJlbHMgYXNzb2NpYXRlZCB3
aXRoIHRoZSBEbnNUaHJlYXREZXRlY3RvciwgbGlzdGVkIGFzIGtleQogdmFsdWUgcGFpcnMu
CgoNCgUEAAIDBhIEggECFQoNCgUEAAIDARIEggEWHAoNCgUEAAIDAxIEggEfIAoNCgUEAAID
CBIEggEhSQoQCggEAAIDCJwIABIEggEiSAqwAQoEBAACBBIGiQECjAEEGp8BIE9wdGlvbmFs
LiBBIGxpc3Qgb2YgbmV0d29yayByZXNvdXJjZSBuYW1lcyB3aGljaCBhcmVuJ3QgbW9uaXRv
cmVkIGJ5IHRoaXMKIERuc1RocmVhdERldGVjdG9yLgoKIEV4YW1wbGU6CiBgcHJvamVjdHMv
UFJPSkVDVF9JRC9nbG9iYWwvbmV0d29ya3MvTkVUV09SS19OQU1FYC4KCg0KBQQAAgQEEgSJ
AQIKCg0KBQQAAgQFEgSJAQsRCg0KBQQAAgQBEgSJARIjCg0KBQQAAgQDEgSJASYnCg8KBQQA
AgQIEgaJASiMAQMKEAoIBAACBAicCAASBIoBBCoKDwoHBAACBAifCBIEiwEEUApECgQEAAIF
EgSPAQJBGjYgUmVxdWlyZWQuIFRoZSBwcm92aWRlciB1c2VkIGZvciBETlMgdGhyZWF0IGFu
YWx5c2lzLgoKDQoFBAACBQYSBI8BAgoKDQoFBAACBQESBI8BCxMKDQoFBAACBQMSBI8BFhcK
DQoFBAACBQgSBI8BGEAKEAoIBAACBQicCAASBI8BGT8KVwoCBAESBpMBAKQBARpJIFRoZSBt
ZXNzYWdlIGZvciByZXF1ZXN0aW5nIGEgbGlzdCBvZiBEbnNUaHJlYXREZXRlY3RvcnMgaW4g
dGhlIHByb2plY3QuCgoLCgMEAQESBJMBCCUKUQoEBAECABIGlQECmgEEGkEgUmVxdWlyZWQu
IFRoZSBwYXJlbnQgdmFsdWUgZm9yIGBMaXN0RG5zVGhyZWF0RGV0ZWN0b3JzUmVxdWVzdGAu
CgoNCgUEAQIABRIElQECCAoNCgUEAQIAARIElQEJDwoNCgUEAQIAAxIElQESEwoPCgUEAQIA
CBIGlQEUmgEDChAKCAQBAgAInAgAEgSWAQQqChEKBwQBAgAInwgSBpcBBJkBBQqfAQoEBAEC
ARIEngECPxqQASBPcHRpb25hbC4gVGhlIHJlcXVlc3RlZCBwYWdlIHNpemUuIFRoZSBzZXJ2
ZXIgbWF5IHJldHVybiBmZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lm
aWVkLCB0aGUgc2VydmVyIHBpY2tzIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAQIB
BRIEngECBwoNCgUEAQIBARIEngEIEQoNCgUEAQIBAxIEngEUFQoNCgUEAQIBCBIEngEWPgoQ
CggEAQIBCJwIABIEngEXPQqWAQoEBAECAhIEowECQRqHASBPcHRpb25hbC4gQSBwYWdlIHRv
a2VuIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogYExpc3REbnNUaHJlYXREZXRlY3RvcnNS
ZXF1ZXN0YCBjYWxsLiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlCiBzdWJzZXF1ZW50
IHBhZ2UuCgoNCgUEAQICBRIEowECCAoNCgUEAQICARIEowEJEwoNCgUEAQICAxIEowEWFwoN
CgUEAQICCBIEowEYQAoQCggEAQICCJwIABIEowEZPwpQCgIEAhIGpwEAsQEBGkIgVGhlIHJl
c3BvbnNlIG1lc3NhZ2UgdG8gcmVxdWVzdGluZyBhIGxpc3Qgb2YgRG5zVGhyZWF0RGV0ZWN0
b3JzLgoKCwoDBAIBEgSnAQgmCjgKBAQCAgASBKkBAjYaKiBUaGUgbGlzdCBvZiBEbnNUaHJl
YXREZXRlY3RvciByZXNvdXJjZXMuCgoNCgUEAgIABBIEqQECCgoNCgUEAgIABhIEqQELHAoN
CgUEAgIAARIEqQEdMQoNCgUEAgIAAxIEqQE0NQpWCgQEAgIBEgSsAQIdGkggQSB0b2tlbiwg
d2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gLCB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlLgoKDQoFBAICAQUSBKwBAggKDQoFBAICAQESBKwBCRgKDQoFBAICAQMSBKwBGxwK
TAoEBAICAhIGrwECsAE1GjwgVW5vcmRlcmVkIGxpc3QuIFVucmVhY2hhYmxlIGBEbnNUaHJl
YXREZXRlY3RvcmAgcmVzb3VyY2VzLgoKDQoFBAICAgQSBK8BAgoKDQoFBAICAgUSBK8BCxEK
DQoFBAICAgESBK8BEh0KDQoFBAICAgMSBK8BICEKDQoFBAICAggSBLABBjQKEAoIBAICAgic
CAASBLABBzMKPAoCBAMSBrQBALwBARouIFRoZSBtZXNzYWdlIHNlbnQgdG8gZ2V0IGEgRG5z
VGhyZWF0RGV0ZWN0b3IuCgoLCgMEAwESBLQBCCMKQwoEBAMCABIGtgECuwEEGjMgUmVxdWly
ZWQuIE5hbWUgb2YgdGhlIERuc1RocmVhdERldGVjdG9yIHJlc291cmNlLgoKDQoFBAMCAAUS
BLYBAggKDQoFBAMCAAESBLYBCQ0KDQoFBAMCAAMSBLYBEBEKDwoFBAMCAAgSBrYBErsBAwoQ
CggEAwIACJwIABIEtwEEKgoRCgcEAwIACJ8IEga4AQS6AQUKOgoCBAQSBr8BAM8BARosIFRo
ZSBtZXNzYWdlIHRvIGNyZWF0ZSBhIERuc1RocmVhdERldGVjdG9yLgoKCwoDBAQBEgS/AQgm
ClcKBAQEAgASBsEBAsYBBBpHIFJlcXVpcmVkLiBUaGUgdmFsdWUgZm9yIHRoZSBwYXJlbnQg
b2YgdGhlIERuc1RocmVhdERldGVjdG9yIHJlc291cmNlLgoKDQoFBAQCAAUSBMEBAggKDQoF
BAQCAAESBMEBCQ8KDQoFBAQCAAMSBMEBEhMKDwoFBAQCAAgSBsEBFMYBAwoQCggEBAIACJwI
ABIEwgEEKgoRCgcEBAIACJ8IEgbDAQTFAQUKkgEKBAQEAgESBMoBAk0agwEgT3B0aW9uYWwu
IFRoZSBJRCBvZiB0aGUgcmVxdWVzdGluZyBEbnNUaHJlYXREZXRlY3RvciBvYmplY3QuCiBJ
ZiB0aGlzIGZpZWxkIGlzIG5vdCBzdXBwbGllZCwgdGhlIHNlcnZpY2UgZ2VuZXJhdGVzIGFu
IGlkZW50aWZpZXIuCgoNCgUEBAIBBRIEygECCAoNCgUEBAIBARIEygEJHwoNCgUEBAIBAxIE
ygEiIwoNCgUEBAIBCBIEygEkTAoQCggEBAIBCJwIABIEygElSwpHCgQEBAICEgbNAQLOAS8a
NyBSZXF1aXJlZC4gVGhlIGBEbnNUaHJlYXREZXRlY3RvcmAgcmVzb3VyY2UgdG8gY3JlYXRl
LgoKDQoFBAQCAgYSBM0BAhMKDQoFBAQCAgESBM0BFCcKDQoFBAQCAgMSBM0BKisKDQoFBAQC
AggSBM4BBi4KEAoIBAQCAgicCAASBM4BBy0KPQoCBAUSBtIBAN4BARovIFRoZSBtZXNzYWdl
IGZvciB1cGRhdGluZyBhIERuc1RocmVhdERldGVjdG9yLgoKCwoDBAUBEgTSAQgmCvYCCgQE
BQIAEgbYAQLZAS8a5QIgT3B0aW9uYWwuIFRoZSBmaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3Bl
Y2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluCiB0aGUgRG5zVGhyZWF0RGV0
ZWN0b3IgcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4gVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4g
dGhlCiB1cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QgdGhl
IGZ1bGwgcmVxdWVzdC4gQSBmaWVsZAogd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBp
biB0aGUgbWFzay4gSWYgdGhlIG1hc2sgaXMgbm90IHByb3ZpZGVkIHRoZW4KIGFsbCBmaWVs
ZHMgcHJlc2VudCBpbiB0aGUgcmVxdWVzdCB3aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoFBAUC
AAYSBNgBAhsKDQoFBAUCAAESBNgBHCcKDQoFBAUCAAMSBNgBKisKDQoFBAUCAAgSBNkBBi4K
EAoIBAUCAAicCAASBNkBBy0KSQoEBAUCARIG3AEC3QEvGjkgUmVxdWlyZWQuIFRoZSBEbnNU
aHJlYXREZXRlY3RvciByZXNvdXJjZSBiZWluZyB1cGRhdGVkLgoKDQoFBAUCAQYSBNwBAhMK
DQoFBAUCAQESBNwBFCcKDQoFBAUCAQMSBNwBKisKDQoFBAUCAQgSBN0BBi4KEAoIBAUCAQic
CAASBN0BBy0KPQoCBAYSBuEBAOkBARovIFRoZSBtZXNzYWdlIGZvciBkZWxldGluZyBhIERu
c1RocmVhdERldGVjdG9yLgoKCwoDBAYBEgThAQgmCkMKBAQGAgASBuMBAugBBBozIFJlcXVp
cmVkLiBOYW1lIG9mIHRoZSBEbnNUaHJlYXREZXRlY3RvciByZXNvdXJjZS4KCg0KBQQGAgAF
EgTjAQIICg0KBQQGAgABEgTjAQkNCg0KBQQGAgADEgTjARARCg8KBQQGAgAIEgbjARLoAQMK
EAoIBAYCAAicCAASBOQBBCoKEQoHBAYCAAifCBIG5QEE5wEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector ===
    # Fields for DnsThreatDetector
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1beta1.DnsThreatDetector.LabelsEntry)
    # Field: excluded_networks Type: 9 ()
    # Field: provider Type: 14 (.google.cloud.networksecurity.v1beta1.DnsThreatDetector.Provider)

# Enum: DnsThreatDetector::Provider
our $DnsThreatDetector_PROVIDER_UNSPECIFIED = 0;
our $DnsThreatDetector_INFOBLOX = 1;

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::ListDnsThreatDetectorsRequest ===
    # Fields for ListDnsThreatDetectorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::ListDnsThreatDetectorsResponse ===
    # Fields for ListDnsThreatDetectorsResponse
    # Field: dns_threat_detectors Type: 11 (.google.cloud.networksecurity.v1beta1.DnsThreatDetector)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::GetDnsThreatDetectorRequest ===
    # Fields for GetDnsThreatDetectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::CreateDnsThreatDetectorRequest ===
    # Fields for CreateDnsThreatDetectorRequest
    # Field: parent Type: 9 ()
    # Field: dns_threat_detector_id Type: 9 ()
    # Field: dns_threat_detector Type: 11 (.google.cloud.networksecurity.v1beta1.DnsThreatDetector)

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::UpdateDnsThreatDetectorRequest ===
    # Fields for UpdateDnsThreatDetectorRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: dns_threat_detector Type: 11 (.google.cloud.networksecurity.v1beta1.DnsThreatDetector)

# === Message: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DeleteDnsThreatDetectorRequest ===
    # Fields for DeleteDnsThreatDetectorRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetectorServiceClient ===
package Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetectorServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetectorServiceClient

Client stub representing the remote C<DnsThreatDetectorService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networksecurity.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networksecurity.googleapis.com:443' );

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

sub list_dns_threat_detectors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::ListDnsThreatDetectorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.DnsThreatDetectorService',
        method         => 'ListDnsThreatDetectors',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::ListDnsThreatDetectorsResponse',
    });
}

sub get_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::GetDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.DnsThreatDetectorService',
        method         => 'GetDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector',
    });
}

sub create_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::CreateDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.DnsThreatDetectorService',
        method         => 'CreateDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector',
    });
}

sub update_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::UpdateDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.DnsThreatDetectorService',
        method         => 'UpdateDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector',
    });
}

sub delete_dns_threat_detector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DeleteDnsThreatDetectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.DnsThreatDetectorService',
        method         => 'DeleteDnsThreatDetector',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/dns_threat_detector.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector;

    my $msg = Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/dns_threat_detector.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector

A DNS threat detector sends DNS query logs to a _provider_ that then
analyzes the logs to identify threat events in the DNS queries.
By default, all VPC networks in your projects are included. You can exclude
specific networks by supplying `excluded_networks`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. Name of the DnsThreatDetector resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time stamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time stamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector::LabelsEntry>)

Optional. Any labels associated with the DnsThreatDetector, listed as key
value pairs.

=item * C<< $msg->excluded_networks() >> / C<< $msg->excluded_networks($value) >>

Type: C<String>

Optional. A list of network resource names which aren't monitored by this
DnsThreatDetector.

Example:
`projects/PROJECT_ID/global/networks/NETWORK_NAME`.

=item * C<< $msg->provider() >> / C<< $msg->provider($value) >>

Type: C<Enum> (L<Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::Provider>)

Required. The provider used for DNS threat analysis.

=back

=head3 Enum: DnsThreatDetector::Provider

=over 4

=item * C<PROVIDER_UNSPECIFIED> => C<0>

=item * C<INFOBLOX> => C<1>

=back

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::ListDnsThreatDetectorsRequest

The message for requesting a list of DnsThreatDetectors in the project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for `ListDnsThreatDetectorsRequest`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The requested page size. The server may return fewer items than
requested. If unspecified, the server picks an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token received from a previous
`ListDnsThreatDetectorsRequest` call. Provide this to retrieve the
subsequent page.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::ListDnsThreatDetectorsResponse

The response message to requesting a list of DnsThreatDetectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dns_threat_detectors() >> / C<< $msg->dns_threat_detectors($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector>)

The list of DnsThreatDetector resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token`, to retrieve the next page.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Unreachable `DnsThreatDetector` resources.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::GetDnsThreatDetectorRequest

The message sent to get a DnsThreatDetector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the DnsThreatDetector resource.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::CreateDnsThreatDetectorRequest

The message to create a DnsThreatDetector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The value for the parent of the DnsThreatDetector resource.

=item * C<< $msg->dns_threat_detector_id() >> / C<< $msg->dns_threat_detector_id($value) >>

Type: C<String>

Optional. The ID of the requesting DnsThreatDetector object.
If this field is not supplied, the service generates an identifier.

=item * C<< $msg->dns_threat_detector() >> / C<< $msg->dns_threat_detector($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector>)

Required. The `DnsThreatDetector` resource to create.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::UpdateDnsThreatDetectorRequest

The message for updating a DnsThreatDetector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The field mask is used to specify the fields to be overwritten in
the DnsThreatDetector resource by the update. The fields specified in the
update_mask are relative to the resource, not the full request. A field
will be overwritten if it is in the mask. If the mask is not provided then
all fields present in the request will be overwritten.

=item * C<< $msg->dns_threat_detector() >> / C<< $msg->dns_threat_detector($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DnsThreatDetector>)

Required. The DnsThreatDetector resource being updated.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::DeleteDnsThreatDetectorRequest

The message for deleting a DnsThreatDetector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the DnsThreatDetector resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::DnsThreatDetector::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
