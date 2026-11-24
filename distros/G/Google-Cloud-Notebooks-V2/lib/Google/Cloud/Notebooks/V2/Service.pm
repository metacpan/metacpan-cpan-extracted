package Google::Cloud::Notebooks::V2::Service;

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
    eval { require Google::Cloud::Notebooks::V2::DiagnosticConfig };
    eval { require Google::Cloud::Notebooks::V2::Instance };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL3NlcnZpY2UucHJvdG8SGWdvb2dsZS5jbG91
ZC5ub3RlYm9va3MudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2RpYWdu
b3N0aWNfY29uZmlnLnByb3RvGihnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2luc3RhbmNl
LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3By
b3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLOAgoRT3BlcmF0aW9uTWV0YWRhdGES
OwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVh
dGVUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIH
ZW5kVGltZRIWCgZ0YXJnZXQYAyABKAlSBnRhcmdldBISCgR2ZXJiGAQgASgJUgR2ZXJiEiUK
DnN0YXR1c19tZXNzYWdlGAUgASgJUg1zdGF0dXNNZXNzYWdlEjUKFnJlcXVlc3RlZF9jYW5j
ZWxsYXRpb24YBiABKAhSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIfCgthcGlfdmVyc2lvbhgH
IAEoCVIKYXBpVmVyc2lvbhIaCghlbmRwb2ludBgIIAEoCVIIZW5kcG9pbnQi3AEKFExpc3RJ
bnN0YW5jZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFub3RlYm9va3MuZ29v
Z2xlYXBpcy5jb20vSW5zdGFuY2VSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVII
cGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SHgoIb3JkZXJf
YnkYBCABKAlCA+BBAVIHb3JkZXJCeRIbCgZmaWx0ZXIYBSABKAlCA+BBAVIGZmlsdGVyIqQB
ChVMaXN0SW5zdGFuY2VzUmVzcG9uc2USQQoJaW5zdGFuY2VzGAEgAygLMiMuZ29vZ2xlLmNs
b3VkLm5vdGVib29rcy52Mi5JbnN0YW5jZVIJaW5zdGFuY2VzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFi
bGUiUwoSR2V0SW5zdGFuY2VSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohbm90ZWJv
b2tzLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgRuYW1lIuoBChVDcmVhdGVJbnN0YW5jZVJl
cXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIW5vdGVib29rcy5nb29nbGVhcGlzLmNv
bS9JbnN0YW5jZVIGcGFyZW50EiQKC2luc3RhbmNlX2lkGAIgASgJQgPgQQJSCmluc3RhbmNl
SWQSRAoIaW5zdGFuY2UYAyABKAsyIy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkluc3Rh
bmNlQgPgQQJSCGluc3RhbmNlEiIKCnJlcXVlc3RfaWQYBCABKAlCA+BBAVIJcmVxdWVzdElk
IsMBChVVcGRhdGVJbnN0YW5jZVJlcXVlc3QSRAoIaW5zdGFuY2UYASABKAsyIy5nb29nbGUu
Y2xvdWQubm90ZWJvb2tzLnYyLkluc3RhbmNlQgPgQQJSCGluc3RhbmNlEkAKC3VwZGF0ZV9t
YXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNr
EiIKCnJlcXVlc3RfaWQYAyABKAlCA+BBAVIJcmVxdWVzdElkInoKFURlbGV0ZUluc3RhbmNl
UmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIW5vdGVib29rcy5nb29nbGVhcGlzLmNv
bS9JbnN0YW5jZVIEbmFtZRIiCgpyZXF1ZXN0X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZCIv
ChRTdGFydEluc3RhbmNlUmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUiLgoTU3Rv
cEluc3RhbmNlUmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUiLwoUUmVzZXRJbnN0
YW5jZVJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lIlUKIUNoZWNrSW5zdGFuY2VV
cGdyYWRhYmlsaXR5UmVxdWVzdBIwChFub3RlYm9va19pbnN0YW5jZRgBIAEoCUID4EECUhBu
b3RlYm9va0luc3RhbmNlIrcBCiJDaGVja0luc3RhbmNlVXBncmFkYWJpbGl0eVJlc3BvbnNl
EiAKC3VwZ3JhZGVhYmxlGAEgASgIUgt1cGdyYWRlYWJsZRInCg91cGdyYWRlX3ZlcnNpb24Y
AiABKAlSDnVwZ3JhZGVWZXJzaW9uEiEKDHVwZ3JhZGVfaW5mbxgDIAEoCVILdXBncmFkZUlu
Zm8SIwoNdXBncmFkZV9pbWFnZRgEIAEoCVIMdXBncmFkZUltYWdlIjEKFlVwZ3JhZGVJbnN0
YW5jZVJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lIq8BChdSb2xsYmFja0luc3Rh
bmNlUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIW5vdGVib29rcy5nb29nbGVhcGlz
LmNvbS9JbnN0YW5jZVIEbmFtZRIsCg90YXJnZXRfc25hcHNob3QYAiABKAlCA+BBAlIOdGFy
Z2V0U25hcHNob3QSJwoLcmV2aXNpb25faWQYAyABKAlCBuBBA+BBAlIKcmV2aXNpb25JZCLl
AQoXRGlhZ25vc2VJbnN0YW5jZVJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFub3Rl
Ym9va3MuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBG5hbWUSXQoRZGlhZ25vc3RpY19jb25m
aWcYAiABKAsyKy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkRpYWdub3N0aWNDb25maWdC
A+BBAlIQZGlhZ25vc3RpY0NvbmZpZxIsCg90aW1lb3V0X21pbnV0ZXMYAyABKAVCA+BBAVIO
dGltZW91dE1pbnV0ZXMy+hMKD05vdGVib29rU2VydmljZRKyAQoNTGlzdEluc3RhbmNlcxIv
Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjIuTGlzdEluc3RhbmNlc1JlcXVlc3QaMC5nb29n
bGUuY2xvdWQubm90ZWJvb2tzLnYyLkxpc3RJbnN0YW5jZXNSZXNwb25zZSI+gtPkkwIvEi0v
djIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9pbnN0YW5jZXPaQQZwYXJlbnQS
nwEKC0dldEluc3RhbmNlEi0uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5HZXRJbnN0YW5j
ZVJlcXVlc3QaIy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkluc3RhbmNlIjyC0+STAi8S
LS92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfdpBBG5hbWUS
4AEKDkNyZWF0ZUluc3RhbmNlEjAuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5DcmVhdGVJ
bnN0YW5jZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn2C0+STAjki
LS92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2luc3RhbmNlczoIaW5zdGFu
Y2XaQRtwYXJlbnQsaW5zdGFuY2UsaW5zdGFuY2VfaWTKQR0KCEluc3RhbmNlEhFPcGVyYXRp
b25NZXRhZGF0YRLiAQoOVXBkYXRlSW5zdGFuY2USMC5nb29nbGUuY2xvdWQubm90ZWJvb2tz
LnYyLlVwZGF0ZUluc3RhbmNlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24if4LT5JMCQjI2L3YyL3tpbnN0YW5jZS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
aW5zdGFuY2VzLyp9OghpbnN0YW5jZdpBFGluc3RhbmNlLHVwZGF0ZV9tYXNrykEdCghJbnN0
YW5jZRIRT3BlcmF0aW9uTWV0YWRhdGESzAEKDkRlbGV0ZUluc3RhbmNlEjAuZ29vZ2xlLmNs
b3VkLm5vdGVib29rcy52Mi5EZWxldGVJbnN0YW5jZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uImmC0+STAi8qLS92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2luc3RhbmNlcy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIRT3Bl
cmF0aW9uTWV0YWRhdGESvwEKDVN0YXJ0SW5zdGFuY2USLy5nb29nbGUuY2xvdWQubm90ZWJv
b2tzLnYyLlN0YXJ0SW5zdGFuY2VSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbiJegtPkkwI4IjMvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5j
ZXMvKn06c3RhcnQ6ASrKQR0KCEluc3RhbmNlEhFPcGVyYXRpb25NZXRhZGF0YRK8AQoMU3Rv
cEluc3RhbmNlEi4uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5TdG9wSW5zdGFuY2VSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJdgtPkkwI3IjIvdjIve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn06c3RvcDoBKspBHQoISW5zdGFu
Y2USEU9wZXJhdGlvbk1ldGFkYXRhEr8BCg1SZXNldEluc3RhbmNlEi8uZ29vZ2xlLmNsb3Vk
Lm5vdGVib29rcy52Mi5SZXNldEluc3RhbmNlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb24iXoLT5JMCOCIzL3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
aW5zdGFuY2VzLyp9OnJlc2V0OgEqykEdCghJbnN0YW5jZRIRT3BlcmF0aW9uTWV0YWRhdGES
8AEKGkNoZWNrSW5zdGFuY2VVcGdyYWRhYmlsaXR5EjwuZ29vZ2xlLmNsb3VkLm5vdGVib29r
cy52Mi5DaGVja0luc3RhbmNlVXBncmFkYWJpbGl0eVJlcXVlc3QaPS5nb29nbGUuY2xvdWQu
bm90ZWJvb2tzLnYyLkNoZWNrSW5zdGFuY2VVcGdyYWRhYmlsaXR5UmVzcG9uc2UiVYLT5JMC
TxJNL3YyL3tub3RlYm9va19pbnN0YW5jZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3Rh
bmNlcy8qfTpjaGVja1VwZ3JhZGFiaWxpdHkSxQEKD1VwZ3JhZGVJbnN0YW5jZRIxLmdvb2ds
ZS5jbG91ZC5ub3RlYm9va3MudjIuVXBncmFkZUluc3RhbmNlUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24iYILT5JMCOiI1L3YyL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovaW5zdGFuY2VzLyp9OnVwZ3JhZGU6ASrKQR0KCEluc3RhbmNlEhFPcGVyYXRp
b25NZXRhZGF0YRLIAQoQUm9sbGJhY2tJbnN0YW5jZRIyLmdvb2dsZS5jbG91ZC5ub3RlYm9v
a3MudjIuUm9sbGJhY2tJbnN0YW5jZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uImGC0+STAjsiNi92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3Rh
bmNlcy8qfTpyb2xsYmFjazoBKspBHQoISW5zdGFuY2USEU9wZXJhdGlvbk1ldGFkYXRhEuEB
ChBEaWFnbm9zZUluc3RhbmNlEjIuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5EaWFnbm9z
ZUluc3RhbmNlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ieoLT5JMC
OyI2L3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyp9OmRpYWdu
b3NlOgEq2kEWbmFtZSxkaWFnbm9zdGljX2NvbmZpZ8pBHQoISW5zdGFuY2USEU9wZXJhdGlv
bk1ldGFkYXRhGkzKQRhub3RlYm9va3MuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQsMBCh1jb20uZ29vZ2xlLmNsb3Vk
Lm5vdGVib29rcy52MkIMU2VydmljZVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vbm90
ZWJvb2tzL2FwaXYyL25vdGVib29rc3BiO25vdGVib29rc3BiqgIZR29vZ2xlLkNsb3VkLk5v
dGVib29rcy5WMsoCGUdvb2dsZVxDbG91ZFxOb3RlYm9va3NcVjLqAhxHb29nbGU6OkNsb3Vk
OjpOb3RlYm9va3M6OlYySuVUCgcSBQ4AnAMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkK
AgMDEgMVACMKCQoCAwQSAxYAOwoJCgIDBRIDFwAyCgkKAgMGEgMYAC0KCQoCAwcSAxkAJQoJ
CgIDCBIDGgAqCgkKAgMJEgMbACkKCAoBCBIDHQA2CgkKAgglEgMdADYKCAoBCBIDHgBSCgkK
AggLEgMeAFIKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAAtCgkKAggIEgMgAC0KCAoB
CBIDIQA2CgkKAggBEgMhADYKCAoBCBIDIgA2CgkKAggpEgMiADYKCAoBCBIDIwA1CgkKAggt
EgMjADUKQAoCBgASBSYAuQEBGjMgQVBJIHYyIHNlcnZpY2UgZm9yIFdvcmtiZW5jaCBOb3Rl
Ym9va3MgSW5zdGFuY2VzLgoKCgoDBgABEgMmCBcKCgoDBgADEgMnAkAKDAoFBgADmQgSAycC
QAoLCgMGAAMSBCgCKTcKDQoFBgADmggSBCgCKTcKQAoEBgACABIELAIxAxoyIExpc3RzIGlu
c3RhbmNlcyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAywG
EwoMCgUGAAIAAhIDLBQoCgwKBQYAAgADEgMsM0gKDQoFBgACAAQSBC0ELwYKEQoJBgACAASw
yrwiEgQtBC8GCgwKBQYAAgAEEgMwBDQKDwoIBgACAASbCAASAzAENAoyCgQGAAIBEgQ0AjkD
GiQgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIEluc3RhbmNlLgoKDAoFBgACAQESAzQGEQoM
CgUGAAIBAhIDNBIkCgwKBQYAAgEDEgM0LzcKDQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwi
EgQ1BDcGCgwKBQYAAgEEEgM4BDIKDwoIBgACAQSbCAASAzgEMgpHCgQGAAICEgQ8AkcDGjkg
Q3JlYXRlcyBhIG5ldyBJbnN0YW5jZSBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9u
LgoKDAoFBgACAgESAzwGFAoMCgUGAAICAhIDPBUqCgwKBQYAAgIDEgM9DysKDQoFBgACAgQS
BD4EQQYKEQoJBgACAgSwyrwiEgQ+BEEGCgwKBQYAAgIEEgNCBEkKDwoIBgACAgSbCAASA0IE
SQoNCgUGAAICBBIEQwRGBgoPCgcGAAICBJkIEgRDBEYGCjMKBAYAAgMSBEoCVQMaJSBVcGRh
dGVJbnN0YW5jZSB1cGRhdGVzIGFuIEluc3RhbmNlLgoKDAoFBgACAwESA0oGFAoMCgUGAAID
AhIDShUqCgwKBQYAAgMDEgNLDysKDQoFBgACAwQSBEwETwYKEQoJBgACAwSwyrwiEgRMBE8G
CgwKBQYAAgMEEgNQBEIKDwoIBgACAwSbCAASA1AEQgoNCgUGAAIDBBIEUQRUBgoPCgcGAAID
BJkIEgRRBFQGCioKBAYAAgQSBFgCYgMaHCBEZWxldGVzIGEgc2luZ2xlIEluc3RhbmNlLgoK
DAoFBgACBAESA1gGFAoMCgUGAAIEAhIDWBUqCgwKBQYAAgQDEgNZDysKDQoFBgACBAQSBFoE
XAYKEQoJBgACBASwyrwiEgRaBFwGCgwKBQYAAgQEEgNdBDIKDwoIBgACBASbCAASA10EMgoN
CgUGAAIEBBIEXgRhBgoPCgcGAAIEBJkIEgReBGEGCisKBAYAAgUSBGUCbwMaHSBTdGFydHMg
YSBub3RlYm9vayBpbnN0YW5jZS4KCgwKBQYAAgUBEgNlBhMKDAoFBgACBQISA2UUKAoMCgUG
AAIFAxIDZg8rCg0KBQYAAgUEEgRnBGoGChEKCQYAAgUEsMq8IhIEZwRqBgoNCgUGAAIFBBIE
awRuBgoPCgcGAAIFBJkIEgRrBG4GCioKBAYAAgYSBHICewMaHCBTdG9wcyBhIG5vdGVib29r
IGluc3RhbmNlLgoKDAoFBgACBgESA3IGEgoMCgUGAAIGAhIDchMmCgwKBQYAAgYDEgNyMU0K
DQoFBgACBgQSBHMEdgYKEQoJBgACBgSwyrwiEgRzBHYGCg0KBQYAAgYEEgR3BHoGCg8KBwYA
AgYEmQgSBHcEegYKLAoEBgACBxIFfgKIAQMaHSBSZXNldHMgYSBub3RlYm9vayBpbnN0YW5j
ZS4KCgwKBQYAAgcBEgN+BhMKDAoFBgACBwISA34UKAoMCgUGAAIHAxIDfw8rCg8KBQYAAgcE
EgaAAQSDAQYKEwoJBgACBwSwyrwiEgaAAQSDAQYKDwoFBgACBwQSBoQBBIcBBgoRCgcGAAIH
BJkIEgaEAQSHAQYKQwoEBgACCBIGiwECkAEDGjMgQ2hlY2tzIHdoZXRoZXIgYSBub3RlYm9v
ayBpbnN0YW5jZSBpcyB1cGdyYWRhYmxlLgoKDQoFBgACCAESBIsBBiAKDQoFBgACCAISBIsB
IUIKDQoFBgACCAMSBIwBDzEKDwoFBgACCAQSBo0BBI8BBgoTCgkGAAIIBLDKvCISBo0BBI8B
BgpFCgQGAAIJEgaTAQKdAQMaNSBVcGdyYWRlcyBhIG5vdGVib29rIGluc3RhbmNlIHRvIHRo
ZSBsYXRlc3QgdmVyc2lvbi4KCg0KBQYAAgkBEgSTAQYVCg0KBQYAAgkCEgSTARYsCg0KBQYA
AgkDEgSUAQ8rCg8KBQYAAgkEEgaVAQSYAQYKEwoJBgACCQSwyrwiEgaVAQSYAQYKDwoFBgAC
CQQSBpkBBJwBBgoRCgcGAAIJBJkIEgaZAQScAQYKSAoEBgACChIGoAECqgEDGjggUm9sbGJh
Y2tzIGEgbm90ZWJvb2sgaW5zdGFuY2UgdG8gdGhlIHByZXZpb3VzIHZlcnNpb24uCgoNCgUG
AAIKARIEoAEGFgoNCgUGAAIKAhIEoAEXLgoNCgUGAAIKAxIEoQEPKwoPCgUGAAIKBBIGogEE
pQEGChMKCQYAAgoEsMq8IhIGogEEpQEGCg8KBQYAAgoEEgamAQSpAQYKEQoHBgACCgSZCBIG
pgEEqQEGClcKBAYAAgsSBq0BArgBAxpHIENyZWF0ZXMgYSBEaWFnbm9zdGljIEZpbGUgYW5k
IHJ1bnMgRGlhZ25vc3RpYyBUb29sIGdpdmVuIGFuIEluc3RhbmNlLgoKDQoFBgACCwESBK0B
BhYKDQoFBgACCwISBK0BFy4KDQoFBgACCwMSBK4BDysKDwoFBgACCwQSBq8BBLIBBgoTCgkG
AAILBLDKvCISBq8BBLIBBgoNCgUGAAILBBIEswEERAoQCggGAAILBJsIABIEswEERAoPCgUG
AAILBBIGtAEEtwEGChEKBwYAAgsEmQgSBrQBBLcBBgpGCgIEABIGvAEA2AEBGjggUmVwcmVz
ZW50cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoLCgME
AAESBLwBCBkKMwoEBAACABIEvgECLBolIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNy
ZWF0ZWQuCgoNCgUEAAIABhIEvgECGwoNCgUEAAIAARIEvgEcJwoNCgUEAAIAAxIEvgEqKwo4
CgQEAAIBEgTBAQIpGiogVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5n
LgoKDQoFBAACAQYSBMEBAhsKDQoFBAACAQESBMEBHCQKDQoFBAACAQMSBMEBJygKTQoEBAAC
AhIExAECFBo/IFNlcnZlci1kZWZpbmVkIHJlc291cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQg
b2YgdGhlIG9wZXJhdGlvbi4KCg0KBQQAAgIFEgTEAQIICg0KBQQAAgIBEgTEAQkPCg0KBQQA
AgIDEgTEARITCjsKBAQAAgMSBMcBAhIaLSBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5
IHRoZSBvcGVyYXRpb24uCgoNCgUEAAIDBRIExwECCAoNCgUEAAIDARIExwEJDQoNCgUEAAID
AxIExwEQEQo/CgQEAAIEEgTKAQIcGjEgSHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBv
cGVyYXRpb24sIGlmIGFueS4KCg0KBQQAAgQFEgTKAQIICg0KBQQAAgQBEgTKAQkXCg0KBQQA
AgQDEgTKARobCo4CCgQEAAIFEgTRAQIiGv8BIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNl
ciBoYXMgcmVxdWVzdGVkIGNhbmNlbGxhdGlvbgogb2YgdGhlIG9wZXJhdGlvbi4gT3BlcmF0
aW9ucyB0aGF0IGhhdmUgc3VjY2Vzc2Z1bGx5IGJlZW4gY2FuY2VsbGVkCiBoYXZlIFtPcGVy
YXRpb24uZXJyb3JdW10gdmFsdWUgd2l0aCBhCiBbZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV1b
Z29vZ2xlLnJwYy5TdGF0dXMuY29kZV0gb2YgMSwgY29ycmVzcG9uZGluZyB0bwogYENvZGUu
Q0FOQ0VMTEVEYC4KCg0KBQQAAgUFEgTRAQIGCg0KBQQAAgUBEgTRAQcdCg0KBQQAAgUDEgTR
ASAhCjgKBAQAAgYSBNQBAhkaKiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVy
YXRpb24uCgoNCgUEAAIGBRIE1AECCAoNCgUEAAIGARIE1AEJFAoNCgUEAAIGAxIE1AEXGAo0
CgQEAAIHEgTXAQIWGiYgQVBJIGVuZHBvaW50IG5hbWUgb2YgdGhpcyBvcGVyYXRpb24uCgoN
CgUEAAIHBRIE1wECCAoNCgUEAAIHARIE1wEJEQoNCgUEAAIHAxIE1wEUFQo3CgIEARIG2wEA
8gEBGikgUmVxdWVzdCBmb3IgbGlzdGluZyBub3RlYm9vayBpbnN0YW5jZXMuCgoLCgMEAQES
BNsBCBwKWAoEBAECABIG3gEC4wEEGkggUmVxdWlyZWQuIEZvcm1hdDoKIGBwYXJlbnQ9cHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAECAAUSBN4B
AggKDQoFBAECAAESBN4BCQ8KDQoFBAECAAMSBN4BEhMKDwoFBAECAAgSBt4BFOMBAwoQCggE
AQIACJwIABIE3wEEKgoRCgcEAQIACJ8IEgbgAQTiAQUKPwoEBAECARIE5gECPxoxIE9wdGlv
bmFsLiBNYXhpbXVtIHJldHVybiBzaXplIG9mIHRoZSBsaXN0IGNhbGwuCgoNCgUEAQIBBRIE
5gECBwoNCgUEAQIBARIE5gEIEQoNCgUEAQIBAxIE5gEUFQoNCgUEAQIBCBIE5gEWPgoQCggE
AQIBCJwIABIE5gEXPQp0CgQEAQICEgTqAQJBGmYgT3B0aW9uYWwuIEEgcHJldmlvdXMgcmV0
dXJuZWQgcGFnZSB0b2tlbiB0aGF0IGNhbiBiZSB1c2VkIHRvIGNvbnRpbnVlCiBsaXN0aW5n
IGZyb20gdGhlIGxhc3QgcmVzdWx0LgoKDQoFBAECAgUSBOoBAggKDQoFBAECAgESBOoBCRMK
DQoFBAECAgMSBOoBFhcKDQoFBAECAggSBOoBGEAKEAoIBAECAgicCAASBOoBGT8KYwoEBAEC
AxIE7gECPxpVIE9wdGlvbmFsLiBTb3J0IHJlc3VsdHMuIFN1cHBvcnRlZCB2YWx1ZXMgYXJl
ICJuYW1lIiwgIm5hbWUgZGVzYyIgb3IgIiIKICh1bnNvcnRlZCkuCgoNCgUEAQIDBRIE7gEC
CAoNCgUEAQIDARIE7gEJEQoNCgUEAQIDAxIE7gEUFQoNCgUEAQIDCBIE7gEWPgoQCggEAQID
CJwIABIE7gEXPQomCgQEAQIEEgTxAQI9GhggT3B0aW9uYWwuIExpc3QgZmlsdGVyLgoKDQoF
BAECBAUSBPEBAggKDQoFBAECBAESBPEBCQ8KDQoFBAECBAMSBPEBEhMKDQoFBAECBAgSBPEB
FDwKEAoIBAECBAicCAASBPEBFTsKOAoCBAISBvUBAIECARoqIFJlc3BvbnNlIGZvciBsaXN0
aW5nIG5vdGVib29rIGluc3RhbmNlcy4KCgsKAwQCARIE9QEIHQotCgQEAgIAEgT3AQIiGh8g
QSBsaXN0IG9mIHJldHVybmVkIGluc3RhbmNlcy4KCg0KBQQCAgAEEgT3AQIKCg0KBQQCAgAG
EgT3AQsTCg0KBQQCAgABEgT3ARQdCg0KBQQCAgADEgT3ASAhCmwKBAQCAgESBPsBAh0aXiBQ
YWdlIHRva2VuIHRoYXQgY2FuIGJlIHVzZWQgdG8gY29udGludWUgbGlzdGluZyBmcm9tIHRo
ZSBsYXN0IHJlc3VsdCBpbiB0aGUKIG5leHQgbGlzdCBjYWxsLgoKDQoFBAICAQUSBPsBAggK
DQoFBAICAQESBPsBCRgKDQoFBAICAQMSBPsBGxwKsQEKBAQCAgISBIACAiIaogEgTG9jYXRp
b25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuIEZvciBleGFtcGxlLAogWyd1cy13ZXN0
MS1hJywgJ3VzLWNlbnRyYWwxLWInXS4KIEEgTGlzdEluc3RhbmNlc1Jlc3BvbnNlIHdpbGwg
b25seSBjb250YWluIGVpdGhlciBpbnN0YW5jZXMgb3IgdW5yZWFjaGFibGVzLAoKDQoFBAIC
AgQSBIACAgoKDQoFBAICAgUSBIACCxEKDQoFBAICAgESBIACEh0KDQoFBAICAgMSBIACICEK
OAoCBAMSBoQCAI0CARoqIFJlcXVlc3QgZm9yIGdldHRpbmcgYSBub3RlYm9vayBpbnN0YW5j
ZS4KCgsKAwQDARIEhAIIGgppCgQEAwIAEgaHAgKMAgQaWSBSZXF1aXJlZC4gRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMv
e2luc3RhbmNlX2lkfWAKCg0KBQQDAgAFEgSHAgIICg0KBQQDAgABEgSHAgkNCg0KBQQDAgAD
EgSHAhARCg8KBQQDAgAIEgaHAhKMAgMKEAoIBAMCAAicCAASBIgCBCoKEQoHBAMCAAifCBIG
iQIEiwIFCjkKAgQEEgaQAgCiAgEaKyBSZXF1ZXN0IGZvciBjcmVhdGluZyBhIG5vdGVib29r
IGluc3RhbmNlLgoKCwoDBAQBEgSQAggdClgKBAQEAgASBpMCApgCBBpIIFJlcXVpcmVkLiBG
b3JtYXQ6CiBgcGFyZW50PXByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0
aW9ufWAKCg0KBQQEAgAFEgSTAgIICg0KBQQEAgABEgSTAgkPCg0KBQQEAgADEgSTAhITCg8K
BQQEAgAIEgaTAhSYAgMKEAoIBAQCAAicCAASBJQCBCoKEQoHBAQCAAifCBIGlQIElwIFCkIK
BAQEAgESBJsCAkIaNCBSZXF1aXJlZC4gVXNlci1kZWZpbmVkIHVuaXF1ZSBJRCBvZiB0aGlz
IGluc3RhbmNlLgoKDQoFBAQCAQUSBJsCAggKDQoFBAQCAQESBJsCCRQKDQoFBAQCAQMSBJsC
FxgKDQoFBAQCAQgSBJsCGUEKEAoIBAQCAQicCAASBJsCGkAKNQoEBAQCAhIEngICQRonIFJl
cXVpcmVkLiBUaGUgaW5zdGFuY2UgdG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgSeAgIKCg0K
BQQEAgIBEgSeAgsTCg0KBQQEAgIDEgSeAhYXCg0KBQQEAgIIEgSeAhhAChAKCAQEAgIInAgA
EgSeAhk/CjIKBAQEAgMSBKECAkEaJCBPcHRpb25hbC4gSWRlbXBvdGVudCByZXF1ZXN0IFVV
SUQuCgoNCgUEBAIDBRIEoQICCAoNCgUEBAIDARIEoQIJEwoNCgUEBAIDAxIEoQIWFwoNCgUE
BAIDCBIEoQIYQAoQCggEBAIDCJwIABIEoQIZPwo5CgIEBRIGpQIArwIBGisgUmVxdWVzdCBm
b3IgdXBkYXRpbmcgYSBub3RlYm9vayBpbnN0YW5jZS4KCgsKAwQFARIEpQIIHQo6CgQEBQIA
EgSnAgJBGiwgUmVxdWlyZWQuIEEgcmVwcmVzZW50YXRpb24gb2YgYW4gaW5zdGFuY2UuCgoN
CgUEBQIABhIEpwICCgoNCgUEBQIAARIEpwILEwoNCgUEBQIAAxIEpwIWFwoNCgUEBQIACBIE
pwIYQAoQCggEBQIACJwIABIEpwIZPwo7CgQEBQIBEgaqAgKrAi8aKyBSZXF1aXJlZC4gTWFz
ayB1c2VkIHRvIHVwZGF0ZSBhbiBpbnN0YW5jZQoKDQoFBAUCAQYSBKoCAhsKDQoFBAUCAQES
BKoCHCcKDQoFBAUCAQMSBKoCKisKDQoFBAUCAQgSBKsCBi4KEAoIBAUCAQicCAASBKsCBy0K
MgoEBAUCAhIErgICQRokIE9wdGlvbmFsLiBJZGVtcG90ZW50IHJlcXVlc3QgVVVJRC4KCg0K
BQQFAgIFEgSuAgIICg0KBQQFAgIBEgSuAgkTCg0KBQQFAgIDEgSuAhYXCg0KBQQFAgIIEgSu
AhhAChAKCAQFAgIInAgAEgSuAhk/CjkKAgQGEgayAgC+AgEaKyBSZXF1ZXN0IGZvciBkZWxl
dGluZyBhIG5vdGVib29rIGluc3RhbmNlLgoKCwoDBAYBEgSyAggdCmkKBAQGAgASBrUCAroC
BBpZIFJlcXVpcmVkLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9u
cy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2VfaWR9YAoKDQoFBAYCAAUSBLUCAggK
DQoFBAYCAAESBLUCCQ0KDQoFBAYCAAMSBLUCEBEKDwoFBAYCAAgSBrUCEroCAwoQCggEBgIA
CJwIABIEtgIEKgoRCgcEBgIACJ8IEga3AgS5AgUKMgoEBAYCARIEvQICQRokIE9wdGlvbmFs
LiBJZGVtcG90ZW50IHJlcXVlc3QgVVVJRC4KCg0KBQQGAgEFEgS9AgIICg0KBQQGAgEBEgS9
AgkTCg0KBQQGAgEDEgS9AhYXCg0KBQQGAgEIEgS9AhhAChAKCAQGAgEInAgAEgS9Ahk/CjgK
AgQHEgbBAgDFAgEaKiBSZXF1ZXN0IGZvciBzdGFydGluZyBhIG5vdGVib29rIGluc3RhbmNl
CgoLCgMEBwESBMECCBwKZwoEBAcCABIExAICOxpZIFJlcXVpcmVkLiBGb3JtYXQ6CiBgcHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5z
dGFuY2VfaWR9YAoKDQoFBAcCAAUSBMQCAggKDQoFBAcCAAESBMQCCQ0KDQoFBAcCAAMSBMQC
EBEKDQoFBAcCAAgSBMQCEjoKEAoIBAcCAAicCAASBMQCEzkKOAoCBAgSBsgCAMwCARoqIFJl
cXVlc3QgZm9yIHN0b3BwaW5nIGEgbm90ZWJvb2sgaW5zdGFuY2UKCgsKAwQIARIEyAIIGwpn
CgQECAIAEgTLAgI7GlkgUmVxdWlyZWQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9p
ZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZV9pZH1gCgoNCgUE
CAIABRIEywICCAoNCgUECAIAARIEywIJDQoNCgUECAIAAxIEywIQEQoNCgUECAIACBIEywIS
OgoQCggECAIACJwIABIEywITOQo5CgIECRIGzwIA0wIBGisgUmVxdWVzdCBmb3IgcmVzZXR0
aW5nIGEgbm90ZWJvb2sgaW5zdGFuY2UKCgsKAwQJARIEzwIIHApnCgQECQIAEgTSAgI7Glkg
UmVxdWlyZWQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZV9pZH1gCgoNCgUECQIABRIE0gICCAoNCgUE
CQIAARIE0gIJDQoNCgUECQIAAxIE0gIQEQoNCgUECQIACBIE0gISOgoQCggECQIACJwIABIE
0gITOQpLCgIEChIG1gIA2gIBGj0gUmVxdWVzdCBmb3IgY2hlY2tpbmcgaWYgYSBub3RlYm9v
ayBpbnN0YW5jZSBpcyB1cGdyYWRlYWJsZS4KCgsKAwQKARIE1gIIKQpnCgQECgIAEgTZAgJI
GlkgUmVxdWlyZWQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZV9pZH1gCgoNCgUECgIABRIE2QICCAoN
CgUECgIAARIE2QIJGgoNCgUECgIAAxIE2QIdHgoNCgUECgIACBIE2QIfRwoQCggECgIACJwI
ABIE2QIgRgpMCgIECxIG3QIA7AIBGj4gUmVzcG9uc2UgZm9yIGNoZWNraW5nIGlmIGEgbm90
ZWJvb2sgaW5zdGFuY2UgaXMgdXBncmFkZWFibGUuCgoLCgMECwESBN0CCCoKLgoEBAsCABIE
3wICFxogIElmIGFuIGluc3RhbmNlIGlzIHVwZ3JhZGVhYmxlLgoKDQoFBAsCAAUSBN8CAgYK
DQoFBAsCAAESBN8CBxIKDQoFBAsCAAMSBN8CFRYKoAEKBAQLAgESBOMCAh0akQEgVGhlIHZl
cnNpb24gdGhpcyBpbnN0YW5jZSB3aWxsIGJlIHVwZ3JhZGVkIHRvIGlmIGNhbGxpbmcgdGhl
IHVwZ3JhZGUKIGVuZHBvaW50LiBUaGlzIGZpZWxkIHdpbGwgb25seSBiZSBwb3B1bGF0ZWQg
aWYgZmllbGQgdXBncmFkZWFibGUgaXMgdHJ1ZS4KCg0KBQQLAgEFEgTjAgIICg0KBQQLAgEB
EgTjAgkYCg0KBQQLAgEDEgTjAhscCjUKBAQLAgISBOYCAhoaJyBBZGRpdGlvbmFsIGluZm9y
bWF0aW9uIGFib3V0IHVwZ3JhZGUuCgoNCgUECwICBRIE5gICCAoNCgUECwICARIE5gIJFQoN
CgUECwICAxIE5gIYGQqtAQoEBAsCAxIE6wICGxqeASBUaGUgbmV3IGltYWdlIHNlbGYgbGlu
ayB0aGlzIGluc3RhbmNlIHdpbGwgYmUgdXBncmFkZWQgdG8gaWYgY2FsbGluZyB0aGUKIHVw
Z3JhZGUgZW5kcG9pbnQuIFRoaXMgZmllbGQgd2lsbCBvbmx5IGJlIHBvcHVsYXRlZCBpZiBm
aWVsZCB1cGdyYWRlYWJsZQogaXMgdHJ1ZS4KCg0KBQQLAgMFEgTrAgIICg0KBQQLAgMBEgTr
AgkWCg0KBQQLAgMDEgTrAhkaCjkKAgQMEgbvAgDzAgEaKyBSZXF1ZXN0IGZvciB1cGdyYWRp
bmcgYSBub3RlYm9vayBpbnN0YW5jZQoKCwoDBAwBEgTvAggeCmcKBAQMAgASBPICAjsaWSBS
ZXF1aXJlZC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlX2lkfWAKCg0KBQQMAgAFEgTyAgIICg0KBQQM
AgABEgTyAgkNCg0KBQQMAgADEgTyAhARCg0KBQQMAgAIEgTyAhI6ChAKCAQMAgAInAgAEgTy
AhM5CjsKAgQNEgb2AgCJAwEaLSBSZXF1ZXN0IGZvciByb2xsYmFja2luZyBhIG5vdGVib29r
IGluc3RhbmNlCgoLCgMEDQESBPYCCB8KaQoEBA0CABIG+QIC/gIEGlkgUmVxdWlyZWQuIEZv
cm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5z
dGFuY2VzL3tpbnN0YW5jZV9pZH1gCgoNCgUEDQIABRIE+QICCAoNCgUEDQIAARIE+QIJDQoN
CgUEDQIAAxIE+QIQEQoPCgUEDQIACBIG+QIS/gIDChAKCAQNAgAInAgAEgT6AgQqChEKBwQN
AgAInwgSBvsCBP0CBQp1CgQEDQIBEgSCAwJGGmcgUmVxdWlyZWQuIFRoZSBzbmFwc2hvdCBm
b3Igcm9sbGJhY2suCiBFeGFtcGxlOiAicHJvamVjdHMvdGVzdC1wcm9qZWN0L2dsb2JhbC9z
bmFwc2hvdHMva3J3bHppcHlucmlsIi4KCg0KBQQNAgEFEgSCAwIICg0KBQQNAgEBEgSCAwkY
Cg0KBQQNAgEDEgSCAxscCg0KBQQNAgEIEgSCAx1FChAKCAQNAgEInAgAEgSCAx5ECjQKBAQN
AgISBoUDAogDBBokIFJlcXVpcmVkLiBPdXRwdXQgb25seS4gUmV2aXNpb24gSWQKCg0KBQQN
AgIFEgSFAwIICg0KBQQNAgIBEgSFAwkUCg0KBQQNAgIDEgSFAxcYCg8KBQQNAgIIEgaFAxmI
AwMKEAoIBA0CAgicCAASBIYDBC0KEAoIBA0CAgicCAESBIcDBCoKSQoCBA4SBowDAJwDARo7
IFJlcXVlc3QgZm9yIGNyZWF0aW5nIGEgbm90ZWJvb2sgaW5zdGFuY2UgZGlhZ25vc3RpYyBm
aWxlLgoKCwoDBA4BEgSMAwgfCmkKBAQOAgASBo8DApQDBBpZIFJlcXVpcmVkLiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNl
cy97aW5zdGFuY2VfaWR9YAoKDQoFBA4CAAUSBI8DAggKDQoFBA4CAAESBI8DCQ0KDQoFBA4C
AAMSBI8DEBEKDwoFBA4CAAgSBo8DEpQDAwoQCggEDgIACJwIABIEkAMEKgoRCgcEDgIACJ8I
EgaRAwSTAwUKUgoEBA4CARIGlwMCmAMvGkIgUmVxdWlyZWQuIERlZmluZXMgZmxhZ3MgdGhh
dCBhcmUgdXNlZCB0byBydW4gdGhlIGRpYWdub3N0aWMgdG9vbAoKDQoFBA4CAQYSBJcDAhIK
DQoFBA4CAQESBJcDEyQKDQoFBA4CAQMSBJcDJygKDQoFBA4CAQgSBJgDBi4KEAoIBA4CAQic
CAASBJgDBy0KWwoEBA4CAhIEmwMCRRpNIE9wdGlvbmFsLiBNYXhtaXVtIGFtb3VudCBvZiB0
aW1lIGluIG1pbnV0ZXMgYmVmb3JlIHRoZSBvcGVyYXRpb24gdGltZXMgb3V0LgoKDQoFBA4C
AgUSBJsDAgcKDQoFBA4CAgESBJsDCBcKDQoFBA4CAgMSBJsDGhsKDQoFBA4CAggSBJsDHEQK
EAoIBA4CAgicCAASBJsDHUNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V2::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: endpoint Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::ListInstancesRequest ===
    # Fields for ListInstancesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::ListInstancesResponse ===
    # Fields for ListInstancesResponse
    # Field: instances Type: 11 (.google.cloud.notebooks.v2.Instance)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::GetInstanceRequest ===
    # Fields for GetInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::CreateInstanceRequest ===
    # Fields for CreateInstanceRequest
    # Field: parent Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: instance Type: 11 (.google.cloud.notebooks.v2.Instance)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::UpdateInstanceRequest ===
    # Fields for UpdateInstanceRequest
    # Field: instance Type: 11 (.google.cloud.notebooks.v2.Instance)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::DeleteInstanceRequest ===
    # Fields for DeleteInstanceRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::StartInstanceRequest ===
    # Fields for StartInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::StopInstanceRequest ===
    # Fields for StopInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::ResetInstanceRequest ===
    # Fields for ResetInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityRequest ===
    # Fields for CheckInstanceUpgradabilityRequest
    # Field: notebook_instance Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityResponse ===
    # Fields for CheckInstanceUpgradabilityResponse
    # Field: upgradeable Type: 8 ()
    # Field: upgrade_version Type: 9 ()
    # Field: upgrade_info Type: 9 ()
    # Field: upgrade_image Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::UpgradeInstanceRequest ===
    # Fields for UpgradeInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::RollbackInstanceRequest ===
    # Fields for RollbackInstanceRequest
    # Field: name Type: 9 ()
    # Field: target_snapshot Type: 9 ()
    # Field: revision_id Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::Service::DiagnoseInstanceRequest ===
    # Fields for DiagnoseInstanceRequest
    # Field: name Type: 9 ()
    # Field: diagnostic_config Type: 11 (.google.cloud.notebooks.v2.DiagnosticConfig)
    # Field: timeout_minutes Type: 5 ()

# === Service Client: Google::Cloud::Notebooks::V2::Service::NotebookServiceClient ===
package Google::Cloud::Notebooks::V2::Service::NotebookServiceClient;

=pod

=head2 Service Client: Google::Cloud::Notebooks::V2::Service::NotebookServiceClient

Client stub representing the remote C<NotebookService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<notebooks.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'notebooks.googleapis.com:443' );

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

sub list_instances {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::ListInstancesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'ListInstances',
        request        => $req,
        response_class => 'Google::Cloud::Notebooks::V2::Service::ListInstancesResponse',
    });
}

sub get_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::GetInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'GetInstance',
        request        => $req,
        response_class => 'Google::Cloud::Notebooks::V2::Instance::Instance',
    });
}

sub create_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::CreateInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'CreateInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::UpdateInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'UpdateInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::DeleteInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'DeleteInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub start_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::StartInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'StartInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub stop_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::StopInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'StopInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reset_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::ResetInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'ResetInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub check_instance_upgradability {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'CheckInstanceUpgradability',
        request        => $req,
        response_class => 'Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityResponse',
    });
}

sub upgrade_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::UpgradeInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'UpgradeInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub rollback_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::RollbackInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'RollbackInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub diagnose_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Notebooks::V2::Service::DiagnoseInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.notebooks.v2.NotebookService',
        method         => 'DiagnoseInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V2::Service - Compiled Protocol Buffers messages for google/cloud/notebooks/v2/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V2::Service;

    my $msg = Google::Cloud::Notebooks::V2::Service::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V2::Service::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v2/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V2::Service::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

API version used to start the operation.

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

API endpoint name of this operation.

=back

=head2 Google::Cloud::Notebooks::V2::Service::ListInstancesRequest

Request for listing notebook instances.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format:
`parent=projects/{project_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum return size of the list call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A previous returned page token that can be used to continue
listing from the last result.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Sort results. Supported values are "name", "name desc" or ""
(unsorted).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. List filter.

=back

=head2 Google::Cloud::Notebooks::V2::Service::ListInstancesResponse

Response for listing notebook instances.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instances() >> / C<< $msg->instances($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Instance::Instance>)

A list of returned instances.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token that can be used to continue listing from the last result in the
next list call.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached. For example,
['us-west1-a', 'us-central1-b'].
A ListInstancesResponse will only contain either instances or unreachables,

=back

=head2 Google::Cloud::Notebooks::V2::Service::GetInstanceRequest

Request for getting a notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=back

=head2 Google::Cloud::Notebooks::V2::Service::CreateInstanceRequest

Request for creating a notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Format:
`parent=projects/{project_id}/locations/{location}`

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Required. User-defined unique ID of this instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Instance::Instance>)

Required. The instance to be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V2::Service::UpdateInstanceRequest

Request for updating a notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Instance::Instance>)

Required. A representation of an instance.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask used to update an instance

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V2::Service::DeleteInstanceRequest

Request for deleting a notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. Idempotent request UUID.

=back

=head2 Google::Cloud::Notebooks::V2::Service::StartInstanceRequest

Request for starting a notebook instance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=back

=head2 Google::Cloud::Notebooks::V2::Service::StopInstanceRequest

Request for stopping a notebook instance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=back

=head2 Google::Cloud::Notebooks::V2::Service::ResetInstanceRequest

Request for resetting a notebook instance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=back

=head2 Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityRequest

Request for checking if a notebook instance is upgradeable.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->notebook_instance() >> / C<< $msg->notebook_instance($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=back

=head2 Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityResponse

Response for checking if a notebook instance is upgradeable.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->upgradeable() >> / C<< $msg->upgradeable($value) >>

Type: C<Bool>

If an instance is upgradeable.

=item * C<< $msg->upgrade_version() >> / C<< $msg->upgrade_version($value) >>

Type: C<String>

The version this instance will be upgraded to if calling the upgrade
endpoint. This field will only be populated if field upgradeable is true.

=item * C<< $msg->upgrade_info() >> / C<< $msg->upgrade_info($value) >>

Type: C<String>

Additional information about upgrade.

=item * C<< $msg->upgrade_image() >> / C<< $msg->upgrade_image($value) >>

Type: C<String>

The new image self link this instance will be upgraded to if calling the
upgrade endpoint. This field will only be populated if field upgradeable
is true.

=back

=head2 Google::Cloud::Notebooks::V2::Service::UpgradeInstanceRequest

Request for upgrading a notebook instance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=back

=head2 Google::Cloud::Notebooks::V2::Service::RollbackInstanceRequest

Request for rollbacking a notebook instance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=item * C<< $msg->target_snapshot() >> / C<< $msg->target_snapshot($value) >>

Type: C<String>

Required. The snapshot for rollback.
Example: "projects/test-project/global/snapshots/krwlzipynril".

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Required. Output only. Revision Id

=back

=head2 Google::Cloud::Notebooks::V2::Service::DiagnoseInstanceRequest

Request for creating a notebook instance diagnostic file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`projects/{project_id}/locations/{location}/instances/{instance_id}`

=item * C<< $msg->diagnostic_config() >> / C<< $msg->diagnostic_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::DiagnosticConfig::DiagnosticConfig>)

Required. Defines flags that are used to run the diagnostic tool

=item * C<< $msg->timeout_minutes() >> / C<< $msg->timeout_minutes($value) >>

Type: C<Int32>

Optional. Maxmium amount of time in minutes before the operation times out.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V2::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
