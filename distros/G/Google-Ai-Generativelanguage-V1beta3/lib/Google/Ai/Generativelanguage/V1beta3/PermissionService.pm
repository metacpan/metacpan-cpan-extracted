package Google::Ai::Generativelanguage::V1beta3::PermissionService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta3::Permission };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvcGVybWlzc2lvbl9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMaNWdvb2ds
ZS9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvdjFiZXRhMy9wZXJtaXNzaW9uLnByb3RvGhxnb29n
bGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90byK+AQoXQ3JlYXRlUGVybWlzc2lvblJlcXVlc3QSTAoGcGFyZW50GAEgASgJ
QjTgQQL6QS4SLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9u
UgZwYXJlbnQSVQoKcGVybWlzc2lvbhgCIAEoCzIwLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFu
Z3VhZ2UudjFiZXRhMy5QZXJtaXNzaW9uQgPgQQJSCnBlcm1pc3Npb24iYAoUR2V0UGVybWlz
c2lvblJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixnZW5lcmF0aXZlbGFuZ3VhZ2Uu
Z29vZ2xlYXBpcy5jb20vUGVybWlzc2lvblIEbmFtZSKBAQoWTGlzdFBlcm1pc3Npb25zUmVx
dWVzdBIhCgZwYXJlbnQYASABKAlCCeBBAvpBAwoBKlIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgC
IAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tl
biKVAQoXTGlzdFBlcm1pc3Npb25zUmVzcG9uc2USUgoLcGVybWlzc2lvbnMYASADKAsyMC5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuUGVybWlzc2lvblILcGVybWlz
c2lvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrIBChdVcGRh
dGVQZXJtaXNzaW9uUmVxdWVzdBJVCgpwZXJtaXNzaW9uGAEgASgLMjAuZ29vZ2xlLmFpLmdl
bmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLlBlcm1pc3Npb25CA+BBAlIKcGVybWlzc2lvbhJA
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIK
dXBkYXRlTWFzayJjChdEZWxldGVQZXJtaXNzaW9uUmVxdWVzdBJICgRuYW1lGAEgASgJQjTg
QQL6QS4KLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9QZXJtaXNzaW9uUgRu
YW1lIo4BChhUcmFuc2Zlck93bmVyc2hpcFJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEu
CixnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vVHVuZWRNb2RlbFIEbmFtZRIo
Cg1lbWFpbF9hZGRyZXNzGAIgASgJQgPgQQJSDGVtYWlsQWRkcmVzcyIbChlUcmFuc2Zlck93
bmVyc2hpcFJlc3BvbnNlMoUKChFQZXJtaXNzaW9uU2VydmljZRLYAQoQQ3JlYXRlUGVybWlz
c2lvbhI9Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5DcmVhdGVQZXJt
aXNzaW9uUmVxdWVzdBowLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5Q
ZXJtaXNzaW9uIlOC0+STAjkiKy92MWJldGEzL3twYXJlbnQ9dHVuZWRNb2RlbHMvKn0vcGVy
bWlzc2lvbnM6CnBlcm1pc3Npb27aQRFwYXJlbnQscGVybWlzc2lvbhK5AQoNR2V0UGVybWlz
c2lvbhI6Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5HZXRQZXJtaXNz
aW9uUmVxdWVzdBowLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5QZXJt
aXNzaW9uIjqC0+STAi0SKy92MWJldGEzL3tuYW1lPXR1bmVkTW9kZWxzLyovcGVybWlzc2lv
bnMvKn3aQQRuYW1lEswBCg9MaXN0UGVybWlzc2lvbnMSPC5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYmV0YTMuTGlzdFBlcm1pc3Npb25zUmVxdWVzdBo9Lmdvb2dsZS5haS5n
ZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5MaXN0UGVybWlzc2lvbnNSZXNwb25zZSI8gtPk
kwItEisvdjFiZXRhMy97cGFyZW50PXR1bmVkTW9kZWxzLyp9L3Blcm1pc3Npb25z2kEGcGFy
ZW50EugBChBVcGRhdGVQZXJtaXNzaW9uEj0uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MWJldGEzLlVwZGF0ZVBlcm1pc3Npb25SZXF1ZXN0GjAuZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWJldGEzLlBlcm1pc3Npb24iY4LT5JMCRDI2L3YxYmV0YTMve3Blcm1p
c3Npb24ubmFtZT10dW5lZE1vZGVscy8qL3Blcm1pc3Npb25zLyp9OgpwZXJtaXNzaW9u2kEW
cGVybWlzc2lvbix1cGRhdGVfbWFzaxKlAQoQRGVsZXRlUGVybWlzc2lvbhI9Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5EZWxldGVQZXJtaXNzaW9uUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI6gtPkkwItKisvdjFiZXRhMy97bmFtZT10dW5lZE1v
ZGVscy8qL3Blcm1pc3Npb25zLyp92kEEbmFtZRLQAQoRVHJhbnNmZXJPd25lcnNoaXASPi5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuVHJhbnNmZXJPd25lcnNoaXBS
ZXF1ZXN0Gj8uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLlRyYW5zZmVy
T3duZXJzaGlwUmVzcG9uc2UiOoLT5JMCNCIvL3YxYmV0YTMve25hbWU9dHVuZWRNb2RlbHMv
Kn06dHJhbnNmZXJPd25lcnNoaXA6ASoaJMpBIWdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVh
cGlzLmNvbUKkAQooY29tLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhM0IW
UGVybWlzc2lvblNlcnZpY2VQcm90b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVy
YXRpdmVsYW5ndWFnZS9hcGl2MWJldGEzL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRp
dmVsYW5ndWFnZXBiStgpCgcSBQ4AyQEkCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSAD8KCQoCAwESAxMAJgoJCgIDAhIDFAAhCgkKAgMD
EgMVACkKCQoCAwQSAxYAIwoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgB1CgkKAggL
EgMaAHUKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA3CgkKAggIEgMcADcKCAoBCBID
HQBBCgkKAggBEgMdAEEKTgoCBgASBCAAWQEaQiBQcm92aWRlcyBtZXRob2RzIGZvciBtYW5h
Z2luZyBwZXJtaXNzaW9ucyB0byBQYUxNIEFQSSByZXNvdXJjZXMuCgoKCgMGAAESAyAIGQoK
CgMGAAMSAyECSQoMCgUGAAOZCBIDIQJJCjsKBAYAAgASBCQCKgMaLSBDcmVhdGUgYSBwZXJt
aXNzaW9uIHRvIGEgc3BlY2lmaWMgcmVzb3VyY2UuCgoMCgUGAAIAARIDJAYWCgwKBQYAAgAC
EgMkFy4KDAoFBgACAAMSAyQ5QwoNCgUGAAIABBIEJQQoBgoRCgkGAAIABLDKvCISBCUEKAYK
DAoFBgACAAQSAykEPwoPCggGAAIABJsIABIDKQQ/Cj0KBAYAAgESBC0CMgMaLyBHZXRzIGlu
Zm9ybWF0aW9uIGFib3V0IGEgc3BlY2lmaWMgUGVybWlzc2lvbi4KCgwKBQYAAgEBEgMtBhMK
DAoFBgACAQISAy0UKAoMCgUGAAIBAxIDLTM9Cg0KBQYAAgEEEgQuBDAGChEKCQYAAgEEsMq8
IhIELgQwBgoMCgUGAAIBBBIDMQQyCg8KCAYAAgEEmwgAEgMxBDIKPAoEBgACAhIENQI7Axou
IExpc3RzIHBlcm1pc3Npb25zIGZvciB0aGUgc3BlY2lmaWMgcmVzb3VyY2UuCgoMCgUGAAIC
ARIDNQYVCgwKBQYAAgICEgM1FiwKDAoFBgACAgMSAzYPJgoNCgUGAAICBBIENwQ5BgoRCgkG
AAICBLDKvCISBDcEOQYKDAoFBgACAgQSAzoENAoPCggGAAICBJsIABIDOgQ0CicKBAYAAgMS
BD4CRAMaGSBVcGRhdGVzIHRoZSBwZXJtaXNzaW9uLgoKDAoFBgACAwESAz4GFgoMCgUGAAID
AhIDPhcuCgwKBQYAAgMDEgM+OUMKDQoFBgACAwQSBD8EQgYKEQoJBgACAwSwyrwiEgQ/BEIG
CgwKBQYAAgMEEgNDBEQKDwoIBgACAwSbCAASA0MERAonCgQGAAIEEgRHAk0DGhkgRGVsZXRl
cyB0aGUgcGVybWlzc2lvbi4KCgwKBQYAAgQBEgNHBhYKDAoFBgACBAISA0cXLgoMCgUGAAIE
AxIDSA8kCg0KBQYAAgQEEgRJBEsGChEKCQYAAgQEsMq8IhIESQRLBgoMCgUGAAIEBBIDTAQy
Cg8KCAYAAgQEmwgAEgNMBDIKrAEKBAYAAgUSBFICWAManQEgVHJhbnNmZXJzIG93bmVyc2hp
cCBvZiB0aGUgdHVuZWQgbW9kZWwuCiBUaGlzIGlzIHRoZSBvbmx5IHdheSB0byBjaGFuZ2Ug
b3duZXJzaGlwIG9mIHRoZSB0dW5lZCBtb2RlbC4KIFRoZSBjdXJyZW50IG93bmVyIHdpbGwg
YmUgZG93bmdyYWRlZCB0byB3cml0ZXIgcm9sZS4KCgwKBQYAAgUBEgNSBhcKDAoFBgACBQIS
A1IYMAoMCgUGAAIFAxIDUw8oCg0KBQYAAgUEEgRUBFcGChEKCQYAAgUEsMq8IhIEVARXBgov
CgIEABIEXABoARojIFJlcXVlc3QgdG8gY3JlYXRlIGEgYFBlcm1pc3Npb25gLgoKCgoDBAAB
EgNcCB8KZQoEBAACABIEXwJkBBpXIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9m
IHRoZSBgUGVybWlzc2lvbmAuCiBGb3JtYXQ6IHR1bmVkTW9kZWxzL3t0dW5lZF9tb2RlbH0K
CgwKBQQAAgAFEgNfAggKDAoFBAACAAESA18JDwoMCgUEAAIAAxIDXxITCg0KBQQAAgAIEgRf
FGQDCg8KCAQAAgAInAgAEgNgBCoKDwoHBAACAAifCBIEYQRjBQoyCgQEAAIBEgNnAkUaJSBS
ZXF1aXJlZC4gVGhlIHBlcm1pc3Npb24gdG8gY3JlYXRlLgoKDAoFBAACAQYSA2cCDAoMCgUE
AAIBARIDZw0XCgwKBQQAAgEDEgNnGhsKDAoFBAACAQgSA2ccRAoPCggEAAIBCJwIABIDZx1D
CkwKAgQBEgRrAHUBGkAgUmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZvcm1hdGlvbiBhYm91dCBh
IHNwZWNpZmljIGBQZXJtaXNzaW9uYC4KCgoKAwQBARIDawgcCnwKBAQBAgASBG8CdAQabiBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHBlcm1pc3Npb24uCgogRm9ybWF0
OiBgdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfXBlcm1pc3Npb25zL3twZXJtaXNzaW9ufWAK
CgwKBQQBAgAFEgNvAggKDAoFBAECAAESA28JDQoMCgUEAQIAAxIDbxARCg0KBQQBAgAIEgRv
EnQDCg8KCAQBAgAInAgAEgNwBCoKDwoHBAECAAifCBIEcQRzBQovCgIEAhIFeACQAQEaIiBS
ZXF1ZXN0IGZvciBsaXN0aW5nIHBlcm1pc3Npb25zLgoKCgoDBAIBEgN4CB4KZAoEBAICABIE
ewJ+BBpWIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBwZXJtaXNzaW9u
cy4KIEZvcm1hdDogdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfQoKDAoFBAICAAUSA3sCCAoM
CgUEAgIAARIDewkPCgwKBQQCAgADEgN7EhMKDQoFBAICAAgSBHsUfgMKDwoIBAICAAicCAAS
A3wEKgoOCgcEAgIACJ8IEgN9BDMKlgIKBAQCAgESBIYBAj8ahwIgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBgUGVybWlzc2lvbmBzIHRvIHJldHVybiAocGVyIHBhZ2UpLgog
VGhlIHNlcnZpY2UgbWF5IHJldHVybiBmZXdlciBwZXJtaXNzaW9ucy4KCiBJZiB1bnNwZWNp
ZmllZCwgYXQgbW9zdCAxMCBwZXJtaXNzaW9ucyB3aWxsIGJlIHJldHVybmVkLgogVGhpcyBt
ZXRob2QgcmV0dXJucyBhdCBtb3N0IDEwMDAgcGVybWlzc2lvbnMgcGVyIHBhZ2UsIGV2ZW4g
aWYgeW91IHBhc3MKIGxhcmdlciBwYWdlX3NpemUuCgoNCgUEAgIBBRIEhgECBwoNCgUEAgIB
ARIEhgEIEQoNCgUEAgIBAxIEhgEUFQoNCgUEAgIBCBIEhgEWPgoQCggEAgIBCJwIABIEhgEX
PQrEAgoEBAICAhIEjwECQRq1AiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBm
cm9tIGEgcHJldmlvdXMgYExpc3RQZXJtaXNzaW9uc2AgY2FsbC4KCiBQcm92aWRlIHRoZSBg
cGFnZV90b2tlbmAgcmV0dXJuZWQgYnkgb25lIHJlcXVlc3QgYXMgYW4gYXJndW1lbnQgdG8g
dGhlCiBuZXh0IHJlcXVlc3QgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KCiBXaGVuIHBh
Z2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBMaXN0UGVybWlz
c2lvbnNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9r
ZW4uCgoNCgUEAgICBRIEjwECCAoNCgUEAgICARIEjwEJEwoNCgUEAgICAxIEjwEWFwoNCgUE
AgICCBIEjwEYQAoQCggEAgICCJwIABIEjwEZPwpcCgIEAxIGlAEAnAEBGk4gUmVzcG9uc2Ug
ZnJvbSBgTGlzdFBlcm1pc3Npb25zYCBjb250YWluaW5nIGEgcGFnaW5hdGVkIGxpc3Qgb2YK
IHBlcm1pc3Npb25zLgoKCwoDBAMBEgSUAQgfCiUKBAQDAgASBJYBAiYaFyBSZXR1cm5lZCBw
ZXJtaXNzaW9ucy4KCg0KBQQDAgAEEgSWAQIKCg0KBQQDAgAGEgSWAQsVCg0KBQQDAgABEgSW
ARYhCg0KBQQDAgADEgSWASQlCooBCgQEAwIBEgSbAQIdGnwgQSB0b2tlbiwgd2hpY2ggY2Fu
IGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgog
SWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gbW9yZSBwYWdlcy4KCg0K
BQQDAgEFEgSbAQIICg0KBQQDAgEBEgSbAQkYCg0KBQQDAgEDEgSbARscCjMKAgQEEgafAQCp
AQEaJSBSZXF1ZXN0IHRvIHVwZGF0ZSB0aGUgYFBlcm1pc3Npb25gLgoKCwoDBAQBEgSfAQgf
CoEBCgQEBAIAEgSjAQJFGnMgUmVxdWlyZWQuIFRoZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZS4K
CiBUaGUgcGVybWlzc2lvbidzIGBuYW1lYCBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRo
ZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZS4KCg0KBQQEAgAGEgSjAQIMCg0KBQQEAgABEgSjAQ0X
Cg0KBQQEAgADEgSjARobCg0KBQQEAgAIEgSjARxEChAKCAQEAgAInAgAEgSjAR1DCmsKBAQE
AgESBqcBAqgBLxpbIFJlcXVpcmVkLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLiBB
Y2NlcHRlZCBvbmVzOgogIC0gcm9sZSAoYFBlcm1pc3Npb24ucm9sZWAgZmllbGQpCgoNCgUE
BAIBBhIEpwECGwoNCgUEBAIBARIEpwEcJwoNCgUEBAIBAxIEpwEqKwoNCgUEBAIBCBIEqAEG
LgoQCggEBAIBCJwIABIEqAEHLQozCgIEBRIGrAEAtQEBGiUgUmVxdWVzdCB0byBkZWxldGUg
dGhlIGBQZXJtaXNzaW9uYC4KCgsKAwQFARIErAEIHwp+CgQEBQIAEgavAQK0AQQabiBSZXF1
aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHBlcm1pc3Npb24uCiBGb3JtYXQ6IGB0
dW5lZE1vZGVscy97dHVuZWRfbW9kZWx9L3Blcm1pc3Npb25zL3twZXJtaXNzaW9ufWAKCg0K
BQQFAgAFEgSvAQIICg0KBQQFAgABEgSvAQkNCg0KBQQFAgADEgSvARARCg8KBQQFAgAIEgav
ARK0AQMKEAoIBAUCAAicCAASBLABBCoKEQoHBAUCAAifCBIGsQEEswEFCkUKAgQGEga4AQDG
AQEaNyBSZXF1ZXN0IHRvIHRyYW5zZmVyIHRoZSBvd25lcnNoaXAgb2YgdGhlIHR1bmVkIG1v
ZGVsLgoKCwoDBAYBEgS4AQggCnwKBAQGAgASBrwBAsEBBBpsIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgdHVuZWQgbW9kZWwgdG8gdHJhbnNmZXIgb3duZXJzaGlwIC4K
CiBGb3JtYXQ6IGB0dW5lZE1vZGVscy9teS1tb2RlbC1pZGAKCg0KBQQGAgAFEgS8AQIICg0K
BQQGAgABEgS8AQkNCg0KBQQGAgADEgS8ARARCg8KBQQGAgAIEga8ARLBAQMKEAoIBAYCAAic
CAASBL0BBCoKEQoHBAYCAAifCBIGvgEEwAEFCmkKBAQGAgESBMUBAkQaWyBSZXF1aXJlZC4g
VGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIHVzZXIgdG8gd2hvbSB0aGUgdHVuZWQgbW9kZWwg
aXMgYmVpbmcKIHRyYW5zZmVycmVkIHRvLgoKDQoFBAYCAQUSBMUBAggKDQoFBAYCAQESBMUB
CRYKDQoFBAYCAQMSBMUBGRoKDQoFBAYCAQgSBMUBG0MKEAoIBAYCAQicCAASBMUBHEIKMAoC
BAcSBMkBACQaJCBSZXNwb25zZSBmcm9tIGBUcmFuc2Zlck93bmVyc2hpcGAuCgoLCgMEBwES
BMkBCCFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest ===
    # Fields for CreatePermissionRequest
    # Field: parent Type: 9 ()
    # Field: permission Type: 11 (.google.ai.generativelanguage.v1beta3.Permission)

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::GetPermissionRequest ===
    # Fields for GetPermissionRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::ListPermissionsRequest ===
    # Fields for ListPermissionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::ListPermissionsResponse ===
    # Fields for ListPermissionsResponse
    # Field: permissions Type: 11 (.google.ai.generativelanguage.v1beta3.Permission)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::UpdatePermissionRequest ===
    # Fields for UpdatePermissionRequest
    # Field: permission Type: 11 (.google.ai.generativelanguage.v1beta3.Permission)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::DeletePermissionRequest ===
    # Fields for DeletePermissionRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipRequest ===
    # Fields for TransferOwnershipRequest
    # Field: name Type: 9 ()
    # Field: email_address Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse ===
    # Fields for TransferOwnershipResponse

# === Service Client: Google::Ai::Generativelanguage::V1beta3::PermissionService::PermissionServiceClient ===
package Google::Ai::Generativelanguage::V1beta3::PermissionService::PermissionServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1beta3::PermissionService::PermissionServiceClient

Client stub representing the remote C<PermissionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub create_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'CreatePermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::Permission::Permission',
    });
}

sub get_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::PermissionService::GetPermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'GetPermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::Permission::Permission',
    });
}

sub list_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::PermissionService::ListPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'ListPermissions',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::PermissionService::ListPermissionsResponse',
    });
}

sub update_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::PermissionService::UpdatePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'UpdatePermission',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::Permission::Permission',
    });
}

sub delete_permission {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::PermissionService::DeletePermissionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'DeletePermission',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub transfer_ownership {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.PermissionService',
        method         => 'TransferOwnership',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::PermissionService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/permission_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::PermissionService;

    my $msg = Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest->new({
        parent => $parent,
        permission => $permission,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/permission_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest

Request to create a `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the `Permission`.
Format: tunedModels/{tuned_model}

=item * C<< $msg->permission() >> / C<< $msg->permission($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Permission::Permission>)

Required. The permission to create.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::GetPermissionRequest

Request for getting information about a specific `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the permission.

Format: `tunedModels/{tuned_model}permissions/{permission}`

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::ListPermissionsRequest

Request for listing permissions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the permissions.
Format: tunedModels/{tuned_model}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `Permission`s to return (per page).
The service may return fewer permissions.

If unspecified, at most 10 permissions will be returned.
This method returns at most 1000 permissions per page, even if you pass
larger page_size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListPermissions` call.

Provide the `page_token` returned by one request as an argument to the
next request to retrieve the next page.

When paginating, all other parameters provided to `ListPermissions`
must match the call that provided the page token.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::ListPermissionsResponse

Response from `ListPermissions` containing a paginated list of
permissions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permissions() >> / C<< $msg->permissions($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Permission::Permission>)

Returned permissions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::UpdatePermissionRequest

Request to update the `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->permission() >> / C<< $msg->permission($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Permission::Permission>)

Required. The permission to update.

The permission's `name` field is used to identify the permission to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The list of fields to update. Accepted ones:
 - role (`Permission.role` field)

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::DeletePermissionRequest

Request to delete the `Permission`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the permission.
Format: `tunedModels/{tuned_model}/permissions/{permission}`

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipRequest

Request to transfer the ownership of the tuned model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the tuned model to transfer ownership .

Format: `tunedModels/my-model-id`

=item * C<< $msg->email_address() >> / C<< $msg->email_address($value) >>

Type: C<String>

Required. The email address of the user to whom the tuned model is being
transferred to.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse

Response from `TransferOwnership`.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::PermissionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
