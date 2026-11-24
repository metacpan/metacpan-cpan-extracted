package Google::Cloud::Retail::V2beta::ExportConfig;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9leHBvcnRfY29uZmlnLnByb3RvEhpnb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8ixAMKDE91dHB1dENvbmZpZxJiCg9n
Y3NfZGVzdGluYXRpb24YASABKAsyNy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5PdXRw
dXRDb25maWcuR2NzRGVzdGluYXRpb25IAFIOZ2NzRGVzdGluYXRpb24ScQoUYmlncXVlcnlf
ZGVzdGluYXRpb24YAiABKAsyPC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5PdXRwdXRD
b25maWcuQmlnUXVlcnlEZXN0aW5hdGlvbkgAUhNiaWdxdWVyeURlc3RpbmF0aW9uGkEKDkdj
c0Rlc3RpbmF0aW9uEi8KEW91dHB1dF91cmlfcHJlZml4GAEgASgJQgPgQQJSD291dHB1dFVy
aVByZWZpeBqKAQoTQmlnUXVlcnlEZXN0aW5hdGlvbhIiCgpkYXRhc2V0X2lkGAEgASgJQgPg
QQJSCWRhdGFzZXRJZBIrCg90YWJsZV9pZF9wcmVmaXgYAiABKAlCA+BBAlINdGFibGVJZFBy
ZWZpeBIiCgp0YWJsZV90eXBlGAMgASgJQgPgQQJSCXRhYmxlVHlwZUINCgtkZXN0aW5hdGlv
biJEChJFeHBvcnRFcnJvcnNDb25maWcSHwoKZ2NzX3ByZWZpeBgBIAEoCUgAUglnY3NQcmVm
aXhCDQoLZGVzdGluYXRpb24iwQEKFUV4cG9ydFByb2R1Y3RzUmVxdWVzdBI8CgZwYXJlbnQY
ASABKAlCJOBBAvpBHgoccmV0YWlsLmdvb2dsZWFwaXMuY29tL0JyYW5jaFIGcGFyZW50ElIK
DW91dHB1dF9jb25maWcYAiABKAsyKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5PdXRw
dXRDb25maWdCA+BBAlIMb3V0cHV0Q29uZmlnEhYKBmZpbHRlchgDIAEoCVIGZmlsdGVyIsQB
ChdFeHBvcnRVc2VyRXZlbnRzUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0
YWlsLmdvb2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJSCg1vdXRwdXRfY29uZmlnGAIg
ASgLMiguZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuT3V0cHV0Q29uZmlnQgPgQQJSDG91
dHB1dENvbmZpZxIWCgZmaWx0ZXIYAyABKAlSBmZpbHRlciKqAQodRXhwb3J0QW5hbHl0aWNz
TWV0cmljc1JlcXVlc3QSHQoHY2F0YWxvZxgBIAEoCUID4EECUgdjYXRhbG9nElIKDW91dHB1
dF9jb25maWcYAiABKAsyKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5PdXRwdXRDb25m
aWdCA+BBAlIMb3V0cHV0Q29uZmlnEhYKBmZpbHRlchgDIAEoCVIGZmlsdGVyIooBCg5FeHBv
cnRNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lIvUBChZFeHBvcnRQcm9kdWN0c1Jlc3BvbnNlEjcK
DWVycm9yX3NhbXBsZXMYASADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVz
ElMKDWVycm9yc19jb25maWcYAiABKAsyLi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5F
eHBvcnRFcnJvcnNDb25maWdSDGVycm9yc0NvbmZpZxJNCg1vdXRwdXRfcmVzdWx0GAMgASgL
MiguZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuT3V0cHV0UmVzdWx0UgxvdXRwdXRSZXN1
bHQi9wEKGEV4cG9ydFVzZXJFdmVudHNSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygL
MhIuZ29vZ2xlLnJwYy5TdGF0dXNSDGVycm9yU2FtcGxlcxJTCg1lcnJvcnNfY29uZmlnGAIg
ASgLMi4uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuRXhwb3J0RXJyb3JzQ29uZmlnUgxl
cnJvcnNDb25maWcSTQoNb3V0cHV0X3Jlc3VsdBgDIAEoCzIoLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLk91dHB1dFJlc3VsdFIMb3V0cHV0UmVzdWx0Iv0BCh5FeHBvcnRBbmFseXRp
Y3NNZXRyaWNzUmVzcG9uc2USNwoNZXJyb3Jfc2FtcGxlcxgBIAMoCzISLmdvb2dsZS5ycGMu
U3RhdHVzUgxlcnJvclNhbXBsZXMSUwoNZXJyb3JzX2NvbmZpZxgCIAEoCzIuLmdvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLkV4cG9ydEVycm9yc0NvbmZpZ1IMZXJyb3JzQ29uZmlnEk0K
DW91dHB1dF9yZXN1bHQYAyABKAsyKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5PdXRw
dXRSZXN1bHRSDG91dHB1dFJlc3VsdCK1AQoMT3V0cHV0UmVzdWx0ElkKD2JpZ3F1ZXJ5X3Jl
c3VsdBgBIAMoCzIwLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkJpZ1F1ZXJ5T3V0cHV0
UmVzdWx0Ug5iaWdxdWVyeVJlc3VsdBJKCgpnY3NfcmVzdWx0GAIgAygLMisuZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmJldGEuR2NzT3V0cHV0UmVzdWx0UglnY3NSZXN1bHQiUAoUQmlnUXVl
cnlPdXRwdXRSZXN1bHQSHQoKZGF0YXNldF9pZBgBIAEoCVIJZGF0YXNldElkEhkKCHRhYmxl
X2lkGAIgASgJUgd0YWJsZUlkIjAKD0djc091dHB1dFJlc3VsdBIdCgpvdXRwdXRfdXJpGAEg
ASgJUglvdXRwdXRVcmlC0AEKHmNvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YUIRRXhw
b3J0Q29uZmlnUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJiZXRh
L3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xlLkNsb3VkLlJldGFpbC5WMkJl
dGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdvb2dsZTo6Q2xvdWQ6OlJldGFp
bDo6VjJiZXRhSvRdCgcSBQ4AqwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAjCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCgkKAgMDEgMV
ACEKCAoBCBIDFwA3CgkKAgglEgMXADcKCAoBCBIDGABNCgkKAggLEgMYAE0KCAoBCBIDGQAi
CgkKAggKEgMZACIKCAoBCBIDGgAyCgkKAggIEgMaADIKCAoBCBIDGwA3CgkKAggBEgMbADcK
CAoBCBIDHAAkCgkKAggkEgMcACQKCAoBCBIDHQA3CgkKAggpEgMdADcKCAoBCBIDHgA2CgkK
AggtEgMeADYKLwoCBAASBCEARQEaIyBUaGUgb3V0cHV0IGNvbmZpZ3VyYXRpb24gc2V0dGlu
Zy4KCgoKAwQAARIDIQgUCkoKBAQAAwASBCMCLAMaPCBUaGUgR29vZ2xlIENsb3VkIFN0b3Jh
Z2Ugb3V0cHV0IGRlc3RpbmF0aW9uIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAMAARIDIwoYCrQD
CgYEAAMAAgASAysEShqkAyBSZXF1aXJlZC4gVGhlIG91dHB1dCB1cmkgcHJlZml4IGZvciBz
YXZpbmcgb3V0cHV0IGRhdGEgdG8ganNvbiBmaWxlcy4KIFNvbWUgbWFwcGluZyBleGFtcGxl
cyBhcmUgYXMgZm9sbG93czoKIG91dHB1dF91cmlfcHJlZml4ICAgICAgICAgc2FtcGxlIG91
dHB1dChhc3N1bWluZyB0aGUgb2JqZWN0IGlzIGZvby5qc29uKQogPT09PT09PT09PT09PT09
PT09PT09PT09ICA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT0KIGdzOi8vYnVja2V0LyAgICAgICAgICAgICAgZ3M6Ly9idWNrZXQvZm9vLmpzb24KIGdz
Oi8vYnVja2V0L2ZvbGRlci8gICAgICAgZ3M6Ly9idWNrZXQvZm9sZGVyL2Zvby5qc29uCiBn
czovL2J1Y2tldC9mb2xkZXIvaXRlbV8gIGdzOi8vYnVja2V0L2ZvbGRlci9pdGVtX2Zvby5q
c29uCgoOCgcEAAMAAgAFEgMrBAoKDgoHBAADAAIAARIDKwscCg4KBwQAAwACAAMSAysfIAoO
CgcEAAMAAgAIEgMrIUkKEQoKBAADAAIACJwIABIDKyJICj4KBAQAAwESBC8COwMaMCBUaGUg
QmlnUXVlcnkgb3V0cHV0IGRlc3RpbmF0aW9uIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAMBARID
LwodCjgKBgQAAwECABIDMQRDGikgUmVxdWlyZWQuIFRoZSBJRCBvZiBhIEJpZ1F1ZXJ5IERh
dGFzZXQuCgoOCgcEAAMBAgAFEgMxBAoKDgoHBAADAQIAARIDMQsVCg4KBwQAAwECAAMSAzEY
GQoOCgcEAAMBAgAIEgMxGkIKEQoKBAADAQIACJwIABIDMRtBCkIKBgQAAwECARIDNARIGjMg
UmVxdWlyZWQuIFRoZSBwcmVmaXggb2YgZXhwb3J0ZWQgQmlnUXVlcnkgdGFibGVzLgoKDgoH
BAADAQIBBRIDNAQKCg4KBwQAAwECAQESAzQLGgoOCgcEAAMBAgEDEgM0HR4KDgoHBAADAQIB
CBIDNB9HChEKCgQAAwECAQicCAASAzQgRgqyAQoGBAADAQICEgM6BEMaogEgUmVxdWlyZWQu
IERlc2NyaWJlcyB0aGUgdGFibGUgdHlwZS4gVGhlIGZvbGxvd2luZyB2YWx1ZXMgYXJlIHN1
cHBvcnRlZDoKCiAqIGB0YWJsZWA6IEEgQmlnUXVlcnkgbmF0aXZlIHRhYmxlLgogKiBgdmll
d2A6IEEgdmlydHVhbCB0YWJsZSBkZWZpbmVkIGJ5IGEgU1FMIHF1ZXJ5LgoKDgoHBAADAQIC
BRIDOgQKCg4KBwQAAwECAgESAzoLFQoOCgcEAAMBAgIDEgM6GBkKDgoHBAADAQICCBIDOhpC
ChEKCgQAAwECAgicCAASAzobQQpJCgQEAAgAEgQ+AkQDGjsgVGhlIGNvbmZpZ3VyYXRpb24g
b2YgZGVzdGluYXRpb24gZm9yIGhvbGRpbmcgb3V0cHV0IGRhdGEuCgoMCgUEAAgAARIDPggT
ClYKBAQAAgASA0AEJxpJIFRoZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiB3aGVy
ZSB0aGUgb3V0cHV0IGlzIHRvIGJlIHdyaXR0ZW4gdG8uCgoMCgUEAAIABhIDQAQSCgwKBQQA
AgABEgNAEyIKDAoFBAACAAMSA0AlJgpKCgQEAAIBEgNDBDEaPSBUaGUgQmlnUXVlcnkgbG9j
YXRpb24gd2hlcmUgdGhlIG91dHB1dCBpcyB0byBiZSB3cml0dGVuIHRvLgoKDAoFBAACAQYS
A0MEFwoMCgUEAAIBARIDQxgsCgwKBQQAAgEDEgNDLzAKRQoCBAESBEgAUQEaOSBDb25maWd1
cmF0aW9uIG9mIGRlc3RpbmF0aW9uIGZvciBFeHBvcnQgcmVsYXRlZCBlcnJvcnMuCgoKCgME
AQESA0gIGgotCgQEAQgAEgRKAlADGh8gUmVxdWlyZWQuIEVycm9ycyBkZXN0aW5hdGlvbi4K
CgwKBQQBCAABEgNKCBMK6gEKBAQBAgASA08EGhrcASBHb29nbGUgQ2xvdWQgU3RvcmFnZSBw
YXRoIGZvciBpbXBvcnQgZXJyb3JzLiBUaGlzIG11c3QgYmUgYW4gZW1wdHksCiBleGlzdGlu
ZyBDbG91ZCBTdG9yYWdlIGJ1Y2tldC4gRXhwb3J0IGVycm9ycyB3aWxsIGJlIHdyaXR0ZW4g
dG8gYSBmaWxlIGluCiB0aGlzIGJ1Y2tldCwgb25lIHBlciBsaW5lLCBhcyBhIEpTT04tZW5j
b2RlZAogYGdvb2dsZS5ycGMuU3RhdHVzYCBtZXNzYWdlLgoKDAoFBAECAAUSA08ECgoMCgUE
AQIAARIDTwsVCgwKBQQBAgADEgNPGBkKOQoCBAISBVQAjQEBGiwgUmVxdWVzdCBtZXNzYWdl
IGZvciBFeHBvcnRQcm9kdWN0cyBtZXRob2QuCgoKCgMEAgESA1QIHQr2AQoEBAICABIEWAJb
BBrnASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiBhIFtCcmFuY2hdW2dvb2dsZS5jbG91
ZC5yZXRhaWwudjJiZXRhLkJyYW5jaF0sCiBhbmQgYGRlZmF1bHRfYnJhbmNoYCBmb3IgYnJh
bmNoX2lkIGNvbXBvbmVudCBpcyBzdXBwb3J0ZWQuIEZvciBleGFtcGxlCiAgYHByb2plY3Rz
LzEyMzQvbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFsb2cvYnJhbmNo
ZXMvZGVmYXVsdF9icmFuY2hgCgoMCgUEAgIABRIDWAIICgwKBQQCAgABEgNYCQ8KDAoFBAIC
AAMSA1gSEwoNCgUEAgIACBIEWBRbAwoPCggEAgIACJwIABIDWQQqCg4KBwQCAgAInwgSA1oE
Tgo5CgQEAgIBEgNeAkoaLCBSZXF1aXJlZC4gVGhlIG91dHB1dCBsb2NhdGlvbiBvZiB0aGUg
ZGF0YS4KCgwKBQQCAgEGEgNeAg4KDAoFBAICAQESA14PHAoMCgUEAgIBAxIDXh8gCgwKBQQC
AgEIEgNeIUkKDwoIBAICAQicCAASA14iSArdEQoEBAICAhIEjAECFBrOESBBIGZpbHRlcmlu
ZyBleHByZXNzaW9uIHRvIHNwZWNpZnkgcmVzdHJpY3Rpb25zIG9uIHJldHVybmVkIGV2ZW50
cy4KIFRoZSBleHByZXNzaW9uIGlzIGEgc2VxdWVuY2Ugb2YgdGVybXMuIEVhY2ggdGVybSBh
cHBsaWVzIGEgcmVzdHJpY3Rpb24gdG8KIHRoZSByZXR1cm5lZCBwcm9kdWN0cy4gVXNlIHRo
aXMgZXhwcmVzc2lvbiB0byByZXN0cmljdCByZXN1bHRzIHRvIGEKIHNwZWNpZmljIHRpbWUg
cmFuZ2UsIHRhZywgb3Igc3RvY2sgc3RhdGUgb3IgdG8gZmlsdGVyIHByb2R1Y3RzIGJ5IHBy
b2R1Y3QKIHR5cGUuCiBGb3IgZXhhbXBsZSwgYGxhc3RNb2RpZmllZFRpbWUgPiAiMjAxMi0w
NC0yM1QxODoyNTo0My41MTFaIgogbGFzdE1vZGlmaWVkVGltZTwiMjAxMi0wNC0yM1QxODoy
NTo0My41MTFaIiBwcm9kdWN0VHlwZT1wcmltYXJ5YAoKICAgV2UgZXhwZWN0IG9ubHkgZm91
ciB0eXBlcyBvZiBmaWVsZHM6CgogICAgKiBgbGFzdE1vZGlmaWVkVGltZWA6IFRoaXMgY2Fu
IGJlIHNwZWNpZmllZCB0d2ljZSwgb25jZSB3aXRoIGEKICAgICAgbGVzcyB0aGFuIG9wZXJh
dG9yIGFuZCBvbmNlIHdpdGggYSBncmVhdGVyIHRoYW4gb3BlcmF0b3IuIFRoZQogICAgICBg
bGFzdE1vZGlmaWVkVGltZWAgcmVzdHJpY3Rpb24gc2hvdWxkIHJlc3VsdCBpbiBvbmUsIGNv
bnRpZ3VvdXMsCiAgICAgIHZhbGlkLCBsYXN0LW1vZGlmaWVkLCB0aW1lIHJhbmdlLgoKICAg
ICogYHByb2R1Y3RUeXBlYDogU3VwcG9ydGVkIHZhbHVlcyBhcmUgYHByaW1hcnlgIGFuZCBg
dmFyaWFudGAuIFRoZQogICAgQm9vbGVhbiBvcGVyYXRvcnMgYE9SYCBhbmQgYE5PVGAgYXJl
IHN1cHBvcnRlZCBpZiB0aGUgZXhwcmVzc2lvbiBpcwogICAgZW5jbG9zZWQgaW4gcGFyZW50
aGVzZXMgYW5kIG11c3QgYmUgc2VwYXJhdGVkIGZyb20gdGhlCiAgICAgIGBwcm9kdWN0VHlw
ZWAgdmFsdWVzIGJ5IGEgc3BhY2UuCgogICAgKiBgYXZhaWxhYmlsaXR5YDogU3VwcG9ydGVk
IHZhbHVlcyBhcmUgYElOX1NUT0NLYCwgYE9VVF9PRl9TVE9DS2AsCiAgICBgUFJFT1JERVJg
LCBhbmQgYEJBQ0tPUkRFUmAuIEJvb2xlYW4gb3BlcmF0b3JzIGBPUmAgYW5kIGBOT1RgIGFy
ZQogICAgc3VwcG9ydGVkIGlmIHRoZSBleHByZXNzaW9uIGlzIGVuY2xvc2VkIGluIHBhcmVu
dGhlc2VzIGFuZCBtdXN0IGJlCiAgICBzZXBhcmF0ZWQgZnJvbSB0aGUgYGF2YWlsYWJpbGl0
eWAgdmFsdWVzIGJ5IGEgc3BhY2UuCgogICAgKiBgVGFnIGV4cHJlc3Npb25zYDogUmVzdHJp
Y3RzIG91dHB1dCB0byBwcm9kdWN0cyB0aGF0IG1hdGNoIGFsbCBvZiB0aGUKICAgICAgc3Bl
Y2lmaWVkIHRhZ3MuIEJvb2xlYW4gb3BlcmF0b3JzIGBPUmAgYW5kIGBOT1RgIGFyZSBzdXBw
b3J0ZWQgaWYgdGhlCiAgICAgIGV4cHJlc3Npb24gaXMgZW5jbG9zZWQgaW4gcGFyZW50aGVz
ZXMgYW5kIHRoZSBvcGVyYXRvcnMgYXJlIHNlcGFyYXRlZAogICAgICBmcm9tIHRoZSB0YWcg
dmFsdWVzIGJ5IGEgc3BhY2UuIEFsc28gc3VwcG9ydGVkIGlzICdgLSJ0YWdBImAnLCB3aGlj
aAogICAgICBpcyBlcXVpdmFsZW50IHRvICdgTk9UICJ0YWdBImAnLiBUYWcgdmFsdWVzIG11
c3QgYmUgZG91YmxlLXF1b3RlZCwKICAgICAgVVRGLTggZW5jb2RlZCBzdHJpbmdzIGFuZCBo
YXZlIGEgc2l6ZSBsaW1pdCBvZiAxLDAwMCBjaGFyYWN0ZXJzLgoKICAgU29tZSBleGFtcGxl
cyBvZiB2YWxpZCBmaWx0ZXJzIGV4cHJlc3Npb25zOgoKICAgKiBFeGFtcGxlIDE6IGBsYXN0
TW9kaWZpZWRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTExWiIKICAgICAgICAgICAg
IGxhc3RNb2RpZmllZFRpbWUgPCAiMjAxMi0wNC0yM1QxODozMDo0My41MTFaImAKICAgKiBF
eGFtcGxlIDI6IGBsYXN0TW9kaWZpZWRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTEx
WiIKICAgICAgICAgICAgIHByb2R1Y3RUeXBlID0gInZhcmlhbnQiYAogICAqIEV4YW1wbGUg
MzogYHRhZz0oIlJlZCIgT1IgIkJsdWUiKSB0YWc9Ik5ldy1BcnJpdmFsIgogICAgICAgICAg
ICAgdGFnPShOT1QgInByb21vdGlvbmFsIikKICAgICAgICAgICAgIHByb2R1Y3RUeXBlID0g
InByaW1hcnkiIGxhc3RNb2RpZmllZFRpbWUgPAogICAgICAgICAgICAgIjIwMTgtMDQtMjNU
MTg6MzA6NDMuNTExWiJgCiAgICogRXhhbXBsZSA0OiBgbGFzdE1vZGlmaWVkVGltZSA+ICIy
MDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiYAogICAqIEV4YW1wbGUgNTogYGF2YWlsYWJpbGl0
eSA9IChJTl9TVE9DSyBPUiBCQUNLT1JERVIpYAoKDQoFBAICAgUSBIwBAggKDQoFBAICAgES
BIwBCQ8KDQoFBAICAgMSBIwBEhMKQgoCBAMSBpABAMABARo0IFJlcXVlc3QgbWVzc2FnZSBm
b3IgdGhlIGBFeHBvcnRVc2VyRXZlbnRzYCBtZXRob2QuCgoLCgMEAwESBJABCB8KpQEKBAQD
AgASBpMBApYBBBqUASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiBhIFtDYXRhbG9nXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5DYXRhbG9nXS4KIEZvciBleGFtcGxlIGBwcm9q
ZWN0cy8xMjM0L2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9nYAoK
DQoFBAMCAAUSBJMBAggKDQoFBAMCAAESBJMBCQ8KDQoFBAMCAAMSBJMBEhMKDwoFBAMCAAgS
BpMBFJYBAwoQCggEAwIACJwIABIElAEEKgoPCgcEAwIACJ8IEgSVAQRPCjoKBAQDAgESBJkB
AkoaLCBSZXF1aXJlZC4gVGhlIG91dHB1dCBsb2NhdGlvbiBvZiB0aGUgZGF0YS4KCg0KBQQD
AgEGEgSZAQIOCg0KBQQDAgEBEgSZAQ8cCg0KBQQDAgEDEgSZAR8gCg0KBQQDAgEIEgSZASFJ
ChAKCAQDAgEInAgAEgSZASJICvoMCgQEAwICEgS/AQIUGusMIEEgZmlsdGVyaW5nIGV4cHJl
c3Npb24gdG8gc3BlY2lmeSByZXN0cmljdGlvbnMgb24gcmV0dXJuZWQgZXZlbnRzLgogVGhl
IGV4cHJlc3Npb24gaXMgYSBzZXF1ZW5jZSBvZiB0ZXJtcy4gRWFjaCB0ZXJtIGFwcGxpZXMg
YSByZXN0cmljdGlvbiB0bwogdGhlIHJldHVybmVkIHVzZXIgZXZlbnRzLiBVc2UgdGhpcyBl
eHByZXNzaW9uIHRvIHJlc3RyaWN0IHJlc3VsdHMgdG8gYQogc3BlY2lmaWMgdGltZSByYW5n
ZSBvciB0byBmaWx0ZXIgZXZlbnRzIGJ5IGV2ZW50VHlwZS4KIEZvciBleGFtcGxlLCBgZXZl
bnRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTExWiIKIGV2ZW50c01pc3NpbmdDYXRh
bG9nSXRlbXMgZXZlbnRUaW1lPCIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiCiBldmVudFR5
cGU9c2VhcmNoYAoKICAgV2UgZXhwZWN0IG9ubHkgdGhyZWUgdHlwZXMgb2YgZmllbGRzOgoK
ICAgICogYGV2ZW50VGltZWA6IFRoaXMgY2FuIGJlIHNwZWNpZmllZCB0d2ljZSwgb25jZSB3
aXRoIGEKICAgICAgbGVzcyB0aGFuIG9wZXJhdG9yIGFuZCBvbmNlIHdpdGggYSBncmVhdGVy
IHRoYW4gb3BlcmF0b3IuIFRoZQogICAgICBgZXZlbnRUaW1lYCByZXN0cmljdGlvbiBzaG91
bGQgcmVzdWx0IGluIG9uZSwgY29udGlndW91cywgdmFsaWQsCiAgICAgIGBldmVudFRpbWVg
IHJhbmdlLgoKICAgICogYGV2ZW50VHlwZWA6IEJvb2xlYW4gb3BlcmF0b3JzIGBPUmAgYW5k
IGBOT1RgIGFyZSBzdXBwb3J0ZWQgaWYgdGhlCiAgICAgIGV4cHJlc3Npb24gaXMgZW5jbG9z
ZWQgaW4gcGFyZW50aGVzZXMgYW5kIHRoZSBvcGVyYXRvcnMgYXJlIHNlcGFyYXRlZAogICAg
ICBmcm9tIHRoZSB0YWcgdmFsdWVzIGJ5IGEgc3BhY2UuCgogICAgKiBgZXZlbnRzTWlzc2lu
Z0NhdGFsb2dJdGVtc2A6IFRoaXMgcmVzdHJpY3RzIHJlc3VsdHMKICAgICAgdG8gZXZlbnRz
IGZvciB3aGljaCBjYXRhbG9nIGl0ZW1zIHdlcmUgbm90IGZvdW5kIGluIHRoZSBjYXRhbG9n
LiBUaGUKICAgICAgZGVmYXVsdCBiZWhhdmlvciBpcyB0byByZXR1cm4gb25seSB0aG9zZSBl
dmVudHMgZm9yIHdoaWNoIGNhdGFsb2cKICAgICAgaXRlbXMgd2VyZSBmb3VuZC4KCiAgIFNv
bWUgZXhhbXBsZXMgb2YgdmFsaWQgZmlsdGVycyBleHByZXNzaW9uczoKCiAgICogRXhhbXBs
ZSAxOiBgZXZlbnRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTExWiIKICAgICAgICAg
ICAgIGV2ZW50VGltZSA8ICIyMDEyLTA0LTIzVDE4OjMwOjQzLjUxMVoiYAogICAqIEV4YW1w
bGUgMjogYGV2ZW50VGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiCiAgICAgICAg
ICAgICBldmVudFR5cGUgPSBkZXRhaWwtcGFnZS12aWV3YAogICAqIEV4YW1wbGUgMzogYGV2
ZW50c01pc3NpbmdDYXRhbG9nSXRlbXMKICAgICAgICAgICAgIGV2ZW50VHlwZSA9IChOT1Qg
c2VhcmNoKSBldmVudFRpbWUgPAogICAgICAgICAgICAgIjIwMTgtMDQtMjNUMTg6MzA6NDMu
NTExWiJgCiAgICogRXhhbXBsZSA0OiBgZXZlbnRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6
NDMuNTExWiJgCiAgICogRXhhbXBsZSA1OiBgZXZlbnRUeXBlID0gKGRldGFpbC1wYWdlLXZp
ZXcgT1Igc2VhcmNoKWAKICAgKiBFeGFtcGxlIDY6IGBldmVudHNNaXNzaW5nQ2F0YWxvZ0l0
ZW1zYAoKDQoFBAMCAgUSBL8BAggKDQoFBAMCAgESBL8BCQ8KDQoFBAMCAgMSBL8BEhMKSAoC
BAQSBsMBAN0BARo6IFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBFeHBvcnRBbmFseXRpY3NN
ZXRyaWNzYCBtZXRob2QuCgoLCgMEBAESBMMBCCUKeQoEBAQCABIExgECPhprIFJlcXVpcmVk
LiBGdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBjYXRhbG9nLgogRXhwZWN0ZWQg
Zm9ybWF0OiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qYAoKDQoFBAQCAAUS
BMYBAggKDQoFBAQCAAESBMYBCRAKDQoFBAQCAAMSBMYBExQKDQoFBAQCAAgSBMYBFT0KEAoI
BAQCAAicCAASBMYBFjwKOgoEBAQCARIEyQECShosIFJlcXVpcmVkLiBUaGUgb3V0cHV0IGxv
Y2F0aW9uIG9mIHRoZSBkYXRhLgoKDQoFBAQCAQYSBMkBAg4KDQoFBAQCAQESBMkBDxwKDQoF
BAQCAQMSBMkBHyAKDQoFBAQCAQgSBMkBIUkKEAoIBAQCAQicCAASBMkBIkgK4wUKBAQEAgIS
BNwBAhQa1AUgQSBmaWx0ZXJpbmcgZXhwcmVzc2lvbiB0byBzcGVjaWZ5IHJlc3RyaWN0aW9u
cyBvbiByZXR1cm5lZCBtZXRyaWNzLgogVGhlIGV4cHJlc3Npb24gaXMgYSBzZXF1ZW5jZSBv
ZiB0ZXJtcy4gRWFjaCB0ZXJtIGFwcGxpZXMgYSByZXN0cmljdGlvbiB0bwogdGhlIHJldHVy
bmVkIG1ldHJpY3MuIFVzZSB0aGlzIGV4cHJlc3Npb24gdG8gcmVzdHJpY3QgcmVzdWx0cyB0
byBhCiBzcGVjaWZpYyB0aW1lIHJhbmdlLgoKICAgQ3VycmVudGx5IHdlIGV4cGVjdCBvbmx5
IG9uZSB0eXBlcyBvZiBmaWVsZHM6CgogICAgKiBgdGltZXN0YW1wYDogVGhpcyBjYW4gYmUg
c3BlY2lmaWVkIHR3aWNlLCBvbmNlIHdpdGggYQogICAgICBsZXNzIHRoYW4gb3BlcmF0b3Ig
YW5kIG9uY2Ugd2l0aCBhIGdyZWF0ZXIgdGhhbiBvcGVyYXRvci4gVGhlCiAgICAgIGB0aW1l
c3RhbXBgIHJlc3RyaWN0aW9uIHNob3VsZCByZXN1bHQgaW4gb25lLCBjb250aWd1b3VzLCB2
YWxpZCwKICAgICAgYHRpbWVzdGFtcGAgcmFuZ2UuCgogICBTb21lIGV4YW1wbGVzIG9mIHZh
bGlkIGZpbHRlcnMgZXhwcmVzc2lvbnM6CgogICAqIEV4YW1wbGUgMTogYHRpbWVzdGFtcCA+
ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiCiAgICAgICAgICAgICB0aW1lc3RhbXAgPCAi
MjAxMi0wNC0yM1QxODozMDo0My41MTFaImAKICAgKiBFeGFtcGxlIDI6IGB0aW1lc3RhbXAg
PiAiMjAxMi0wNC0yM1QxODoyNTo0My41MTFaImAKCg0KBQQEAgIFEgTcAQIICg0KBQQEAgIB
EgTcAQkPCg0KBQQEAgIDEgTcARITCpABCgIEBRIG4QEA6AEBGoEBIE1ldGFkYXRhIHJlbGF0
ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZSBFeHBvcnQgb3BlcmF0aW9uLiBUaGlzIGlzCiBy
ZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YSBm
aWVsZC4KCgsKAwQFARIE4QEIFgomCgQEBQIAEgTjAQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0
aW1lLgoKDQoFBAUCAAYSBOMBAhsKDQoFBAUCAAESBOMBHCcKDQoFBAUCAAMSBOMBKisKZAoE
BAUCARIE5wECLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0
aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAUCAQYS
BOcBAhsKDQoFBAUCAQESBOcBHCcKDQoFBAUCAQMSBOcBKisK0wEKAgQGEgbtAQD2AQEaxAEg
UmVzcG9uc2Ugb2YgdGhlIEV4cG9ydFByb2R1Y3RzUmVxdWVzdC4gSWYgdGhlIGxvbmcgcnVu
bmluZwogb3BlcmF0aW9uIGlzIGRvbmUsIHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVk
IGJ5IHRoZQogZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQg
aWYgdGhlIG9wZXJhdGlvbiB3YXMgc3VjY2Vzc2Z1bC4KCgsKAwQGARIE7QEIHgpMCgQEBgIA
EgTvAQIvGj4gQSBzYW1wbGUgb2YgZXJyb3JzIGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3Np
bmcgdGhlIHJlcXVlc3QuCgoNCgUEBgIABBIE7wECCgoNCgUEBgIABhIE7wELHAoNCgUEBgIA
ARIE7wEdKgoNCgUEBgIAAxIE7wEtLgooCgQEBgIBEgTyAQInGhogVGhpcyBmaWVsZCBpcyBu
ZXZlciBzZXQuCgoNCgUEBgIBBhIE8gECFAoNCgUEBgIBARIE8gEVIgoNCgUEBgIBAxIE8gEl
JgpJCgQEBgICEgT1AQIhGjsgT3V0cHV0IHJlc3VsdCBpbmRpY2F0aW5nIHdoZXJlIHRoZSBk
YXRhIHdlcmUgZXhwb3J0ZWQgdG8uCgoNCgUEBgICBhIE9QECDgoNCgUEBgICARIE9QEPHAoN
CgUEBgICAxIE9QEfIArcAQoCBAcSBvsBAIQCARrNASBSZXNwb25zZSBvZiB0aGUgRXhwb3J0
VXNlckV2ZW50c1JlcXVlc3QuIElmIHRoZSBsb25nIHJ1bm5pbmcKIG9wZXJhdGlvbiB3YXMg
c3VjY2Vzc2Z1bCwgdGhlbiB0aGlzIG1lc3NhZ2UgaXMgcmV0dXJuZWQgYnkgdGhlCiBnb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVsZCBpZiB0aGUgb3BlcmF0
aW9uIHdhcyBzdWNjZXNzZnVsLgoKCwoDBAcBEgT7AQggCkwKBAQHAgASBP0BAi8aPiBBIHNh
bXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVz
dC4KCg0KBQQHAgAEEgT9AQIKCg0KBQQHAgAGEgT9AQscCg0KBQQHAgABEgT9AR0qCg0KBQQH
AgADEgT9AS0uCigKBAQHAgESBIACAicaGiBUaGlzIGZpZWxkIGlzIG5ldmVyIHNldC4KCg0K
BQQHAgEGEgSAAgIUCg0KBQQHAgEBEgSAAhUiCg0KBQQHAgEDEgSAAiUmCkkKBAQHAgISBIMC
AiEaOyBPdXRwdXQgcmVzdWx0IGluZGljYXRpbmcgd2hlcmUgdGhlIGRhdGEgd2VyZSBleHBv
cnRlZCB0by4KCg0KBQQHAgIGEgSDAgIOCg0KBQQHAgIBEgSDAg8cCg0KBQQHAgIDEgSDAh8g
CuIBCgIECBIGiQIAkgIBGtMBIFJlc3BvbnNlIG9mIHRoZSBFeHBvcnRBbmFseXRpY3NNZXRy
aWNzUmVxdWVzdC4gSWYgdGhlIGxvbmcgcnVubmluZwogb3BlcmF0aW9uIHdhcyBzdWNjZXNz
ZnVsLCB0aGVuIHRoaXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0aGUKIGdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkIGlmIHRoZSBvcGVyYXRpb24gd2Fz
IHN1Y2Nlc3NmdWwuCgoLCgMECAESBIkCCCYKTAoEBAgCABIEiwICLxo+IEEgc2FtcGxlIG9m
IGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSBwcm9jZXNzaW5nIHRoZSByZXF1ZXN0LgoKDQoF
BAgCAAQSBIsCAgoKDQoFBAgCAAYSBIsCCxwKDQoFBAgCAAESBIsCHSoKDQoFBAgCAAMSBIsC
LS4KKAoEBAgCARIEjgICJxoaIFRoaXMgZmllbGQgaXMgbmV2ZXIgc2V0LgoKDQoFBAgCAQYS
BI4CAhQKDQoFBAgCAQESBI4CFSIKDQoFBAgCAQMSBI4CJSYKSQoEBAgCAhIEkQICIRo7IE91
dHB1dCByZXN1bHQgaW5kaWNhdGluZyB3aGVyZSB0aGUgZGF0YSB3ZXJlIGV4cG9ydGVkIHRv
LgoKDQoFBAgCAgYSBJECAg4KDQoFBAgCAgESBJECDxwKDQoFBAgCAgMSBJECHyAKYwoCBAkS
BpYCAJwCARpVIE91dHB1dCByZXN1bHQgdGhhdCBzdG9yZXMgdGhlIGluZm9ybWF0aW9uIGFi
b3V0IHdoZXJlIHRoZSBleHBvcnRlZCBkYXRhIGlzCiBzdG9yZWQuCgoLCgMECQESBJYCCBQK
QQoEBAkCABIEmAICNBozIFRoZSBCaWdRdWVyeSBsb2NhdGlvbiB3aGVyZSB0aGUgcmVzdWx0
IGlzIHN0b3JlZC4KCg0KBQQJAgAEEgSYAgIKCg0KBQQJAgAGEgSYAgsfCg0KBQQJAgABEgSY
AiAvCg0KBQQJAgADEgSYAjIzCk0KBAQJAgESBJsCAioaPyBUaGUgR29vZ2xlIENsb3VkIFN0
b3JhZ2UgbG9jYXRpb24gd2hlcmUgdGhlIHJlc3VsdCBpcyBzdG9yZWQuCgoNCgUECQIBBBIE
mwICCgoNCgUECQIBBhIEmwILGgoNCgUECQIBARIEmwIbJQoNCgUECQIBAxIEmwIoKQopCgIE
ChIGnwIApQIBGhsgQSBCaWdRdWVyeSBvdXRwdXQgcmVzdWx0LgoKCwoDBAoBEgSfAggcCi0K
BAQKAgASBKECAhgaHyBUaGUgSUQgb2YgYSBCaWdRdWVyeSBEYXRhc2V0LgoKDQoFBAoCAAUS
BKECAggKDQoFBAoCAAESBKECCRMKDQoFBAoCAAMSBKECFhcKKwoEBAoCARIEpAICFhodIFRo
ZSBJRCBvZiBhIEJpZ1F1ZXJ5IFRhYmxlLgoKDQoFBAoCAQUSBKQCAggKDQoFBAoCAQESBKQC
CREKDQoFBAoCAQMSBKQCFBUKJAoCBAsSBqgCAKsCARoWIEEgR2NzIG91dHB1dCByZXN1bHQu
CgoLCgMECwESBKgCCBcKJQoEBAsCABIEqgICGBoXIFRoZSB1cmkgb2YgR2NzIG91dHB1dAoK
DQoFBAsCAAUSBKoCAggKDQoFBAsCAAESBKoCCRMKDQoFBAsCAAMSBKoCFhdiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig ===
    # Fields for OutputConfig
    # Field: gcs_destination Type: 11 (.google.cloud.retail.v2beta.OutputConfig.GcsDestination)
    # Field: bigquery_destination Type: 11 (.google.cloud.retail.v2beta.OutputConfig.BigQueryDestination)

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig ===
    # Fields for ExportErrorsConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsRequest ===
    # Fields for ExportProductsRequest
    # Field: parent Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2beta.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsRequest ===
    # Fields for ExportUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2beta.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest ===
    # Fields for ExportAnalyticsMetricsRequest
    # Field: catalog Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2beta.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportMetadata ===
    # Fields for ExportMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsResponse ===
    # Fields for ExportProductsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2beta.OutputResult)

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsResponse ===
    # Fields for ExportUserEventsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2beta.OutputResult)

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsResponse ===
    # Fields for ExportAnalyticsMetricsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2beta.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2beta.OutputResult)

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::OutputResult ===
    # Fields for OutputResult
    # Field: bigquery_result Type: 11 (.google.cloud.retail.v2beta.BigQueryOutputResult)
    # Field: gcs_result Type: 11 (.google.cloud.retail.v2beta.GcsOutputResult)

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::BigQueryOutputResult ===
    # Fields for BigQueryOutputResult
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ExportConfig::GcsOutputResult ===
    # Fields for GcsOutputResult
    # Field: output_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ExportConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/export_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ExportConfig;

    my $msg = Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig->new({
        gcs_destination => $gcs_destination,
        bigquery_destination => $bigquery_destination,
    });

    # Read or update a field
    my $val = $msg->gcs_destination();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/export_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig

The output configuration setting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_destination() >> / C<< $msg->gcs_destination($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::GcsDestination>)

The Google Cloud Storage location where the output is to be written to.

=item * C<< $msg->bigquery_destination() >> / C<< $msg->bigquery_destination($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig::BigQueryDestination>)

The BigQuery location where the output is to be written to.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig

Configuration of destination for Export related errors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<String>

Google Cloud Storage path for import errors. This must be an empty,
existing Cloud Storage bucket. Export errors will be written to a file in
this bucket, one per line, as a JSON-encoded
`google.rpc.Status` message.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsRequest

Request message for ExportProducts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of a [Branch][google.cloud.retail.v2beta.Branch],
and `default_branch` for branch_id component is supported. For example
 `projects/1234/locations/global/catalogs/default_catalog/branches/default_branch`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig>)

Required. The output location of the data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filtering expression to specify restrictions on returned events.
The expression is a sequence of terms. Each term applies a restriction to
the returned products. Use this expression to restrict results to a
specific time range, tag, or stock state or to filter products by product
type.
For example, `lastModifiedTime > "2012-04-23T18:25:43.511Z"
lastModifiedTime<"2012-04-23T18:25:43.511Z" productType=primary`

  We expect only four types of fields:

   * `lastModifiedTime`: This can be specified twice, once with a
     less than operator and once with a greater than operator. The
     `lastModifiedTime` restriction should result in one, contiguous,
     valid, last-modified, time range.

   * `productType`: Supported values are `primary` and `variant`. The
   Boolean operators `OR` and `NOT` are supported if the expression is
   enclosed in parentheses and must be separated from the
     `productType` values by a space.

   * `availability`: Supported values are `IN_STOCK`, `OUT_OF_STOCK`,
   `PREORDER`, and `BACKORDER`. Boolean operators `OR` and `NOT` are
   supported if the expression is enclosed in parentheses and must be
   separated from the `availability` values by a space.

   * `Tag expressions`: Restricts output to products that match all of the
     specified tags. Boolean operators `OR` and `NOT` are supported if the
     expression is enclosed in parentheses and the operators are separated
     from the tag values by a space. Also supported is '`-"tagA"`', which
     is equivalent to '`NOT "tagA"`'. Tag values must be double-quoted,
     UTF-8 encoded strings and have a size limit of 1,000 characters.

  Some examples of valid filters expressions:

  * Example 1: `lastModifiedTime > "2012-04-23T18:25:43.511Z"
            lastModifiedTime < "2012-04-23T18:30:43.511Z"`
  * Example 2: `lastModifiedTime > "2012-04-23T18:25:43.511Z"
            productType = "variant"`
  * Example 3: `tag=("Red" OR "Blue") tag="New-Arrival"
            tag=(NOT "promotional")
            productType = "primary" lastModifiedTime <
            "2018-04-23T18:30:43.511Z"`
  * Example 4: `lastModifiedTime > "2012-04-23T18:25:43.511Z"`
  * Example 5: `availability = (IN_STOCK OR BACKORDER)`

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsRequest

Request message for the `ExportUserEvents` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of a [Catalog][google.cloud.retail.v2beta.Catalog].
For example `projects/1234/locations/global/catalogs/default_catalog`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig>)

Required. The output location of the data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filtering expression to specify restrictions on returned events.
The expression is a sequence of terms. Each term applies a restriction to
the returned user events. Use this expression to restrict results to a
specific time range or to filter events by eventType.
For example, `eventTime > "2012-04-23T18:25:43.511Z"
eventsMissingCatalogItems eventTime<"2012-04-23T18:25:43.511Z"
eventType=search`

  We expect only three types of fields:

   * `eventTime`: This can be specified twice, once with a
     less than operator and once with a greater than operator. The
     `eventTime` restriction should result in one, contiguous, valid,
     `eventTime` range.

   * `eventType`: Boolean operators `OR` and `NOT` are supported if the
     expression is enclosed in parentheses and the operators are separated
     from the tag values by a space.

   * `eventsMissingCatalogItems`: This restricts results
     to events for which catalog items were not found in the catalog. The
     default behavior is to return only those events for which catalog
     items were found.

  Some examples of valid filters expressions:

  * Example 1: `eventTime > "2012-04-23T18:25:43.511Z"
            eventTime < "2012-04-23T18:30:43.511Z"`
  * Example 2: `eventTime > "2012-04-23T18:25:43.511Z"
            eventType = detail-page-view`
  * Example 3: `eventsMissingCatalogItems
            eventType = (NOT search) eventTime <
            "2018-04-23T18:30:43.511Z"`
  * Example 4: `eventTime > "2012-04-23T18:25:43.511Z"`
  * Example 5: `eventType = (detail-page-view OR search)`
  * Example 6: `eventsMissingCatalogItems`

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest

Request message for the `ExportAnalyticsMetrics` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Full resource name of the parent catalog.
Expected format: `projects/*/locations/*/catalogs/*`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig>)

Required. The output location of the data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filtering expression to specify restrictions on returned metrics.
The expression is a sequence of terms. Each term applies a restriction to
the returned metrics. Use this expression to restrict results to a
specific time range.

  Currently we expect only one types of fields:

   * `timestamp`: This can be specified twice, once with a
     less than operator and once with a greater than operator. The
     `timestamp` restriction should result in one, contiguous, valid,
     `timestamp` range.

  Some examples of valid filters expressions:

  * Example 1: `timestamp > "2012-04-23T18:25:43.511Z"
            timestamp < "2012-04-23T18:30:43.511Z"`
  * Example 2: `timestamp > "2012-04-23T18:25:43.511Z"`

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportMetadata

Metadata related to the progress of the Export operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportProductsResponse

Response of the ExportProductsRequest. If the long running
operation is done, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportUserEventsResponse

Response of the ExportUserEventsRequest. If the long running
operation was successful, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsResponse

Response of the ExportAnalyticsMetricsRequest. If the long running
operation was successful, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::OutputResult

Output result that stores the information about where the exported data is
stored.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bigquery_result() >> / C<< $msg->bigquery_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::BigQueryOutputResult>)

The BigQuery location where the result is stored.

=item * C<< $msg->gcs_result() >> / C<< $msg->gcs_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ExportConfig::GcsOutputResult>)

The Google Cloud Storage location where the result is stored.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::BigQueryOutputResult

A BigQuery output result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

The ID of a BigQuery Dataset.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

The ID of a BigQuery Table.

=back

=head2 Google::Cloud::Retail::V2beta::ExportConfig::GcsOutputResult

A Gcs output result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri() >> / C<< $msg->output_uri($value) >>

Type: C<String>

The uri of Gcs output

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ExportConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
