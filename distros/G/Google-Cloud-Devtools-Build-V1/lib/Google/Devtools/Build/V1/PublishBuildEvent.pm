package Google::Devtools::Build::V1::PublishBuildEvent;

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
    eval { require Google::Devtools::Build::V1::BuildEvents };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvZGV2dG9vbHMvYnVpbGQvdjEvcHVibGlzaF9idWlsZF9ldmVudC5wcm90bxIY
Z29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxorZ29vZ2xlL2RldnRvb2xzL2J1aWxkL3YxL2J1aWxkX2V2ZW50cy5wcm90bxoeZ29v
Z2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJv
dG8igwQKHFB1Ymxpc2hMaWZlY3ljbGVFdmVudFJlcXVlc3QSaAoNc2VydmljZV9sZXZlbBgB
IAEoDjJDLmdvb2dsZS5kZXZ0b29scy5idWlsZC52MS5QdWJsaXNoTGlmZWN5Y2xlRXZlbnRS
ZXF1ZXN0LlNlcnZpY2VMZXZlbFIMc2VydmljZUxldmVsElEKC2J1aWxkX2V2ZW50GAIgASgL
MisuZ29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxLk9yZGVyZWRCdWlsZEV2ZW50QgPgQQJSCmJ1
aWxkRXZlbnQSQAoOc3RyZWFtX3RpbWVvdXQYAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVy
YXRpb25SDXN0cmVhbVRpbWVvdXQSMwoVbm90aWZpY2F0aW9uX2tleXdvcmRzGAQgAygJUhRu
b3RpZmljYXRpb25LZXl3b3JkcxIiCgpwcm9qZWN0X2lkGAYgASgJQgPgQQJSCXByb2plY3RJ
ZBJWCihjaGVja19wcmVjZWRpbmdfbGlmZWN5Y2xlX2V2ZW50c19wcmVzZW50GAcgASgIUiRj
aGVja1ByZWNlZGluZ0xpZmVjeWNsZUV2ZW50c1ByZXNlbnQiMwoMU2VydmljZUxldmVsEhIK
Dk5PTklOVEVSQUNUSVZFEAASDwoLSU5URVJBQ1RJVkUQASKPAQojUHVibGlzaEJ1aWxkVG9v
bEV2ZW50U3RyZWFtUmVzcG9uc2USPwoJc3RyZWFtX2lkGAEgASgLMiIuZ29vZ2xlLmRldnRv
b2xzLmJ1aWxkLnYxLlN0cmVhbUlkUghzdHJlYW1JZBInCg9zZXF1ZW5jZV9udW1iZXIYAiAB
KANSDnNlcXVlbmNlTnVtYmVyIrkBChFPcmRlcmVkQnVpbGRFdmVudBI/CglzdHJlYW1faWQY
ASABKAsyIi5nb29nbGUuZGV2dG9vbHMuYnVpbGQudjEuU3RyZWFtSWRSCHN0cmVhbUlkEicK
D3NlcXVlbmNlX251bWJlchgCIAEoA1IOc2VxdWVuY2VOdW1iZXISOgoFZXZlbnQYAyABKAsy
JC5nb29nbGUuZGV2dG9vbHMuYnVpbGQudjEuQnVpbGRFdmVudFIFZXZlbnQitwIKIlB1Ymxp
c2hCdWlsZFRvb2xFdmVudFN0cmVhbVJlcXVlc3QSYAoTb3JkZXJlZF9idWlsZF9ldmVudBgE
IAEoCzIrLmdvb2dsZS5kZXZ0b29scy5idWlsZC52MS5PcmRlcmVkQnVpbGRFdmVudEID4EEC
UhFvcmRlcmVkQnVpbGRFdmVudBIzChVub3RpZmljYXRpb25fa2V5d29yZHMYBSADKAlSFG5v
dGlmaWNhdGlvbktleXdvcmRzEiIKCnByb2plY3RfaWQYBiABKAlCA+BBAlIJcHJvamVjdElk
ElYKKGNoZWNrX3ByZWNlZGluZ19saWZlY3ljbGVfZXZlbnRzX3ByZXNlbnQYByABKAhSJGNo
ZWNrUHJlY2VkaW5nTGlmZWN5Y2xlRXZlbnRzUHJlc2VudDLeBAoRUHVibGlzaEJ1aWxkRXZl
bnQSyQEKFVB1Ymxpc2hMaWZlY3ljbGVFdmVudBI2Lmdvb2dsZS5kZXZ0b29scy5idWlsZC52
MS5QdWJsaXNoTGlmZWN5Y2xlRXZlbnRSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5
ImCC0+STAloiMy92MS9wcm9qZWN0cy97cHJvamVjdF9pZD0qfS9saWZlY3ljbGVFdmVudHM6
cHVibGlzaDoBKlogIhsvdjEvbGlmZWN5Y2xlRXZlbnRzOnB1Ymxpc2g6ASoSpgIKG1B1Ymxp
c2hCdWlsZFRvb2xFdmVudFN0cmVhbRI8Lmdvb2dsZS5kZXZ0b29scy5idWlsZC52MS5QdWJs
aXNoQnVpbGRUb29sRXZlbnRTdHJlYW1SZXF1ZXN0Gj0uZ29vZ2xlLmRldnRvb2xzLmJ1aWxk
LnYxLlB1Ymxpc2hCdWlsZFRvb2xFdmVudFN0cmVhbVJlc3BvbnNlIoUBgtPkkwJIIiovdjEv
cHJvamVjdHMve3Byb2plY3RfaWQ9Kn0vZXZlbnRzOnB1Ymxpc2g6ASpaFyISL3YxL2V2ZW50
czpwdWJsaXNoOgEq2kE0b3JkZXJlZF9idWlsZF9ldmVudCxub3RpZmljYXRpb25fa2V5d29y
ZHMscHJvamVjdF9pZCgBMAEaVMpBIGJ1aWxkZXZlbnRzZXJ2aWNlLmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKIAQoc
Y29tLmdvb2dsZS5kZXZ0b29scy5idWlsZC52MUIMQmFja2VuZFByb3RvUAFaPWdvb2dsZS5n
b2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZGV2dG9vbHMvYnVpbGQvdjE7YnVpbGT4
AQHKAhVHb29nbGVcQ2xvdWRcQnVpbGRcVjFKvDkKBxIFDgC6AQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUANQoJCgIDBBIDFgAoCgkKAgMFEgMXACUKCAoBCBIDGQAfCgkK
AggfEgMZAB8KCAoBCBIDGgBUCgkKAggLEgMaAFQKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoB
CBIDHAAtCgkKAggIEgMcAC0KCAoBCBIDHQA1CgkKAggBEgMdADUKCAoBCBIDHgAyCgkKAggp
EgMeADIKswcKAgYAEgQvAFMBGqYHIEEgc2VydmljZSBmb3IgcHVibGlzaGluZyBCdWlsZEV2
ZW50cy4gQnVpbGRFdmVudHMgYXJlIGdlbmVyYXRlZCBieSBCdWlsZAogU3lzdGVtcyB0byBy
ZWNvcmQgYWN0aW9ucyB0YWtlbiBkdXJpbmcgYSBCdWlsZC4gRXZlbnRzIG9jY3VyIGluIHN0
cmVhbXMsCiBhcmUgaWRlbnRpZmllZCBieSBhIFN0cmVhbUlkLCBhbmQgb3JkZXJlZCBieSBz
ZXF1ZW5jZSBudW1iZXIgaW4gYSBzdHJlYW0uCgogQSBCdWlsZCBtYXkgY29udGFpbiBzZXZl
cmFsIHN0cmVhbXMgb2YgQnVpbGRFdmVudHMsIGRlcGVuZGluZyBvbiB0aGUgc3lzdGVtcwog
dGhhdCBhcmUgaW52b2x2ZWQgaW4gdGhlIEJ1aWxkLiBTb21lIEJ1aWxkRXZlbnRzIGFyZSB1
c2VkIHRvIGRlY2xhcmUgdGhlCiBiZWdpbm5pbmcgYW5kIGVuZCBvZiBtYWpvciBwb3J0aW9u
cyBvZiBhIEJ1aWxkOyB0aGVzZSBhcmUgY2FsbGVkCiBMaWZlY3ljbGVFdmVudHMsIGFuZCBh
cmUgdXNlZCAoZm9yIGV4YW1wbGUpIHRvIGluZGljYXRlIHRoZSBiZWdpbm5pbmcgb3IgZW5k
CiBvZiBhIEJ1aWxkLCBhbmQgdGhlIGJlZ2lubmluZyBvciBlbmQgb2YgYW4gSW52b2NhdGlv
biBhdHRlbXB0ICh0aGVyZSBjYW4gYmUKIG1vcmUgdGhhbiAxIEludm9jYXRpb24gaW4gYSBC
dWlsZCBpZiwgZm9yIGV4YW1wbGUsIGEgZmFpbHVyZSBvY2N1cnMgc29tZXdoZXJlCiBhbmQg
aXQgbmVlZHMgdG8gYmUgcmV0cmllZCkuCgogT3RoZXIsIGJ1aWxkLXRvb2wgZXZlbnRzIHJl
cHJlc2VudCBhY3Rpb25zIHRha2VuIGJ5IHRoZSBCdWlsZCB0b29sLCBzdWNoIGFzCiB0YXJn
ZXQgb2JqZWN0cyBwcm9kdWNlZCB2aWEgY29tcGlsYXRpb24sIHRlc3RzIHJ1biwgZXQgY2V0
ZXJhLiBUaGVyZSBjb3VsZCBiZQogbW9yZSB0aGFuIG9uZSBidWlsZCB0b29sIHN0cmVhbSBm
b3IgYW4gaW52b2NhdGlvbiBhdHRlbXB0IG9mIGEgYnVpbGQuCgoKCgMGAAESAy8IGQoKCgMG
AAMSAzACSAoMCgUGAAOZCBIDMAJICgsKAwYAAxIEMQIyNwoNCgUGAAOaCBIEMQIyNwrYAwoE
BgACABIEPgJFAxrJAyBQdWJsaXNoIGEgYnVpbGQgZXZlbnQgc3RhdGluZyB0aGUgbmV3IHN0
YXRlIG9mIGEgYnVpbGQgKHR5cGljYWxseSBmcm9tIHRoZQogYnVpbGQgcXVldWUpLiBUaGUg
QnVpbGRFbnF1ZXVlZCBldmVudCBtdXN0IGJlIHB1Ymxpc2hlZCBiZWZvcmUgYWxsIG90aGVy
CiBldmVudHMgZm9yIHRoZSBzYW1lIGJ1aWxkIElELgoKIFRoZSBiYWNrZW5kIHdpbGwgcGVy
c2lzdCB0aGUgZXZlbnQgYW5kIGRlbGl2ZXIgaXQgdG8gcmVnaXN0ZXJlZCBmcm9udGVuZAog
am9icyBpbW1lZGlhdGVseSB3aXRob3V0IGJhdGNoaW5nLgoKIFRoZSBjb21taXQgc3RhdHVz
IG9mIHRoZSByZXF1ZXN0IGlzIHJlcG9ydGVkIGJ5IHRoZSBSUEMncyB1dGlsX3N0YXR1cygp
CiBmdW5jdGlvbi4gVGhlIGVycm9yIGNvZGUgaXMgdGhlIGNhbm9uaWNhbCBlcnJvciBjb2Rl
IGRlZmluZWQgaW4KIC8vdXRpbC90YXNrL2NvZGVzLnByb3RvLgoKDAoFBgACAAESAz4GGwoM
CgUGAAIAAhIDPhw4CgwKBQYAAgADEgM/DyQKDQoFBgACAAQSBEAERAYKEQoJBgACAASwyrwi
EgRABEQGCncKBAYAAgESBEkCUgMaaSBQdWJsaXNoIGJ1aWxkIHRvb2wgZXZlbnRzIGJlbG9u
Z2luZyB0byB0aGUgc2FtZSBzdHJlYW0gdG8gYSBiYWNrZW5kIGpvYgogdXNpbmcgYmlkaXJl
Y3Rpb25hbCBzdHJlYW1pbmcuCgoMCgUGAAIBARIDSQYhCgwKBQYAAgEFEgNJIigKDAoFBgAC
AQISA0kpSwoMCgUGAAIBBhIDSg8VCgwKBQYAAgEDEgNKFjkKDQoFBgACAQQSBEsETwYKEQoJ
BgACAQSwyrwiEgRLBE8GCg0KBQYAAgEEEgRQBFE/ChAKCAYAAgEEmwgAEgRQBFE/Cu8CCgIE
ABIFWwCIAQEa4QIgUHVibGlzaGVzICdsaWZlY3ljbGUgZXZlbnRzJyB0aGF0IHVwZGF0ZSB0
aGUgaGlnaC1sZXZlbCBzdGF0ZSBvZiBhIGJ1aWxkOgogLSBCdWlsZEVucXVldWVkOiBXaGVu
IGEgYnVpbGQgaXMgc2NoZWR1bGVkLgogLSBJbnZvY2F0aW9uQXR0ZW1wdFN0YXJ0ZWQ6IFdo
ZW4gd29yayBmb3IgYSBidWlsZCBzdGFydHM7IHRoZXJlIGNhbiBiZQogICAgIG11bHRpcGxl
IGludm9jYXRpb25zIGZvciBhIGJ1aWxkIChlLmcuIHJldHJpZXMpLgogLSBJbnZvY2F0aW9u
QXR0ZW1wdENvbXBsZXRlZDogV2hlbiB3b3JrIGZvciBhIGJ1aWxkIGZpbmlzaGVzLgogLSBC
dWlsZEZpbmlzaGVkOiBXaGVuIGEgYnVpbGQgaXMgZmluaXNoZWQuCgoKCgMEAAESA1sIJArA
AQoEBAAEABIEXwJmAxqxASBUaGUgc2VydmljZSBsZXZlbCBvZiB0aGUgYnVpbGQgcmVxdWVz
dC4gQmFja2VuZHMgb25seSB1c2VzIHRoaXMgdmFsdWUgd2hlbgogdGhlIEJ1aWxkRW5xdWV1
ZWQgZXZlbnQgaXMgcHVibGlzaGVkIHRvIGRldGVybWluZSB3aGF0IGxldmVsIG9mIHNlcnZp
Y2UKIHRoaXMgYnVpbGQgc2hvdWxkIHJlY2VpdmUuCgoMCgUEAAQAARIDXwcTCo0BCgYEAAQA
AgASA2IEFxp+IE5vbi1pbnRlcmFjdGl2ZSBidWlsZHMgY2FuIHRvbGVyYXRlIGxvbmdlciBl
dmVudCBsYXRlbmNpZXMuIFRoaXMgaXMgdGhlCiBkZWZhdWx0IFNlcnZpY2VMZXZlbCBpZiBj
YWxsZXJzIGRvIG5vdCBzcGVjaWZ5IG9uZS4KCg4KBwQABAACAAESA2IEEgoOCgcEAAQAAgAC
EgNiFRYKWQoGBAAEAAIBEgNlBBQaSiBUaGUgZXZlbnRzIG9mIGFuIGludGVyYWN0aXZlIGJ1
aWxkIHNob3VsZCBiZSBkZWxpdmVyZWQgd2l0aCBsb3cgbGF0ZW5jeS4KCg4KBwQABAACAQES
A2UEDwoOCgcEAAQAAgECEgNlEhMKLwoEBAACABIDaQIhGiIgVGhlIGludGVyYWN0aXZpdHkg
b2YgdGhpcyBidWlsZC4KCgwKBQQAAgAGEgNpAg4KDAoFBAACAAESA2kPHAoMCgUEAAIAAxID
aR8gCnsKBAQAAgESA20CTRpuIFJlcXVpcmVkLiBUaGUgbGlmZWN5Y2xlIGJ1aWxkIGV2ZW50
LiBJZiB0aGlzIGlzIGEgYnVpbGQgdG9vbCBldmVudCwgdGhlIFJQQwogd2lsbCBmYWlsIHdp
dGggSU5WQUxJRF9SRVFVRVNULgoKDAoFBAACAQYSA20CEwoMCgUEAAIBARIDbRQfCgwKBQQA
AgEDEgNtIiMKDAoFBAACAQgSA20kTAoPCggEAAIBCJwIABIDbSVLCpgCCgQEAAICEgNzAi4a
igIgSWYgdGhlIG5leHQgZXZlbnQgZm9yIHRoaXMgYnVpbGQgb3IgaW52b2NhdGlvbiAoZGVw
ZW5kaW5nIG9uIHRoZSBldmVudAogdHlwZSkgaGFzbid0IGJlZW4gcHVibGlzaGVkIGFmdGVy
IHRoaXMgZHVyYXRpb24gZnJvbSB3aGVuIHtidWlsZF9ldmVudH0KIGlzIHdyaXR0ZW4gdG8g
QkVTLCBjb25zaWRlciB0aGlzIHN0cmVhbSBleHBpcmVkLiBJZiB0aGlzIGZpZWxkIGlzIG5v
dCBzZXQsCiBCRVMgYmFja2VuZCB3aWxsIHVzZSBpdHMgb3duIGRlZmF1bHQgdmFsdWUuCgoM
CgUEAAICBhIDcwIaCgwKBQQAAgIBEgNzGykKDAoFBAACAgMSA3MsLQrIAgoEBAACAxIDegIs
GroCIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gYWJvdXQgYSBidWlsZCByZXF1ZXN0LiBUaGVz
ZSBhcmUgZGVmaW5lIGJ5IHRoZSBldmVudAogcHVibGlzaGVycywgYW5kIHRoZSBCdWlsZCBF
dmVudCBTZXJ2aWNlIGRvZXMgbm90IHZhbGlkYXRlIG9yIGludGVycHJldAogdGhlbS4gVGhl
eSBhcmUgdXNlZCB3aGlsZSBub3RpZnlpbmcgaW50ZXJuYWwgc3lzdGVtcyBvZiBuZXcgYnVp
bGRzIGFuZAogaW52b2NhdGlvbnMgaWYgdGhlIE9yZGVyZWRCdWlsZEV2ZW50LmV2ZW50IHR5
cGUgaXMKIEJ1aWxkRW5xdWV1ZWQvSW52b2NhdGlvbkF0dGVtcHRTdGFydGVkLgoKDAoFBAAC
AwQSA3oCCgoMCgUEAAIDBRIDegsRCgwKBQQAAgMBEgN6EicKDAoFBAACAwMSA3oqKwq9AQoE
BAACBBIDfwJBGq8BIFJlcXVpcmVkLiBUaGUgcHJvamVjdCB0aGlzIGJ1aWxkIGlzIGFzc29j
aWF0ZWQgd2l0aC4KIFRoaXMgc2hvdWxkIG1hdGNoIHRoZSBwcm9qZWN0IHVzZWQgZm9yIHRo
ZSBpbml0aWFsIGNhbGwgdG8KIFB1Ymxpc2hMaWZlY3ljbGVFdmVudCAoY29udGFpbmluZyBh
IEJ1aWxkRW5xdWV1ZWQgbWVzc2FnZSkuCgoMCgUEAAIEBRIDfwIICgwKBQQAAgQBEgN/CRMK
DAoFBAACBAMSA38WFwoMCgUEAAIECBIDfxhACg8KCAQAAgQInAgAEgN/GT8KzwIKBAQAAgUS
BIcBAjQawAIgV2hldGhlciB0byByZXF1aXJlIGEgcHJldmlvdXNseSByZWNlaXZlZCBtYXRj
aGluZyBwYXJlbnQgbGlmZWN5Y2xlIGV2ZW50CiBmb3IgdGhlIGN1cnJlbnQgcmVxdWVzdCdz
IGV2ZW50IGJlZm9yZSBjb250aW51aW5nIHByb2Nlc3NpbmcuCiAtIEludm9jYXRpb25BdHRl
bXB0U3RhcnRlZCBhbmQgQnVpbGRGaW5pc2hlZCBldmVudHMgcmVxdWlyZSBhIEJ1aWxkRW5x
dWV1ZWQKICAgcGFyZW50IGV2ZW50LgogLSBJbnZvY2F0aW9uQXR0ZW1wdEZpbmlzaGVkIGV2
ZW50cyByZXF1aXJlIGFuIEludm9jYXRpb25BdHRlbXB0U3RhcnRlZAogICBwYXJlbnQgZXZl
bnQuCgoNCgUEAAIFBRIEhwECBgoNCgUEAAIFARIEhwEHLwoNCgUEAAIFAxIEhwEyMwqGAQoC
BAESBowBAJIBARp4IFN0YXRlcyB3aGljaCBldmVudCBoYXMgYmVlbiBjb21taXR0ZWQuIEFu
eSBmYWlsdXJlIHRvIGNvbW1pdCB3aWxsIGNhdXNlCiBSUEMgZXJyb3JzLCBoZW5jZSBub3Qg
cmVjb3JkZWQgYnkgdGhpcyBwcm90by4KCgsKAwQBARIEjAEIKwo0CgQEAQIAEgSOAQIZGiYg
VGhlIHN0cmVhbSB0aGF0IGNvbnRhaW5zIHRoaXMgZXZlbnQuCgoNCgUEAQIABhIEjgECCgoN
CgUEAQIAARIEjgELFAoNCgUEAQIAAxIEjgEXGApKCgQEAQIBEgSRAQIcGjwgVGhlIHNlcXVl
bmNlIG51bWJlciBvZiB0aGlzIGV2ZW50IHRoYXQgaGFzIGJlZW4gY29tbWl0dGVkLgoKDQoF
BAECAQUSBJEBAgcKDQoFBAECAQESBJEBCBcKDQoFBAECAQMSBJEBGhsKeAoCBAISBpYBAKEB
ARpqIEJ1aWxkIGV2ZW50IHdpdGggY29udGV4dHVhbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUg
c3RyZWFtIGl0IGJlbG9uZ3MgdG8gYW5kCiBpdHMgcG9zaXRpb24gaW4gdGhhdCBzdHJlYW0u
CgoLCgMEAgESBJYBCBkKPwoEBAICABIEmAECGRoxIFdoaWNoIGJ1aWxkIGV2ZW50IHN0cmVh
bSB0aGlzIGV2ZW50IGJlbG9uZ3MgdG8uCgoNCgUEAgIABhIEmAECCgoNCgUEAgIAARIEmAEL
FAoNCgUEAgIAAxIEmAEXGArAAQoEBAICARIEnQECHBqxASBUaGUgcG9zaXRpb24gb2YgdGhp
cyBldmVudCBpbiB0aGUgc3RyZWFtLiBUaGUgc2VxdWVuY2UgbnVtYmVycyBmb3IgYSBidWls
ZAogZXZlbnQgc3RyZWFtIHNob3VsZCBiZSBhIHNlcXVlbmNlIG9mIGNvbnNlY3V0aXZlIG5h
dHVyYWwgbnVtYmVycyBzdGFydGluZwogZnJvbSBvbmUuICgxLCAyLCAzLCAuLi4pCgoNCgUE
AgIBBRIEnQECBwoNCgUEAgIBARIEnQEIFwoNCgUEAgIBAxIEnQEaGwohCgQEAgICEgSgAQIX
GhMgVGhlIGFjdHVhbCBldmVudC4KCg0KBQQCAgIGEgSgAQIMCg0KBQQCAgIBEgSgAQ0SCg0K
BQQCAgIDEgSgARUWCkoKAgQDEgakAQC6AQEaPCBTdHJlYW1pbmcgcmVxdWVzdCBtZXNzYWdl
IGZvciBQdWJsaXNoQnVpbGRUb29sRXZlbnRTdHJlYW0uCgoLCgMEAwESBKQBCCoKhgEKBAQD
AgASBqcBAqgBLxp2IFJlcXVpcmVkLiBUaGUgYnVpbGQgZXZlbnQgd2l0aCBwb3NpdGlvbiBp
bmZvLgogTmV3IHB1Ymxpc2hpbmcgY2xpZW50cyBzaG91bGQgdXNlIHRoaXMgZmllbGQgcmF0
aGVyIHRoYW4gdGhlIDMgYWJvdmUuCgoNCgUEAwIABhIEpwECEwoNCgUEAwIAARIEpwEUJwoN
CgUEAwIAAxIEpwEqKwoNCgUEAwIACBIEqAEGLgoQCggEAwIACJwIABIEqAEHLQq5AgoEBAMC
ARIErgECLBqqAiBUaGUga2V5d29yZHMgdG8gYmUgYXR0YWNoZWQgdG8gdGhlIG5vdGlmaWNh
dGlvbiB3aGljaCBub3RpZmllcyB0aGUgc3RhcnQKIG9mIGEgbmV3IGJ1aWxkIGV2ZW50IHN0
cmVhbS4gQkVTIG9ubHkgcmVhZHMgdGhpcyBmaWVsZCB3aGVuIHNlcXVlbmNlX251bWJlcgog
b3Igb3JkZXJlZF9idWlsZF9ldmVudC5zZXF1ZW5jZV9udW1iZXIgaXMgMSBpbiB0aGlzIG1l
c3NhZ2UuIElmIHRoaXMgZmllbGQKIGlzIGVtcHR5LCBCRVMgd2lsbCBub3QgcHVibGlzaCBu
b3RpZmljYXRpb24gbWVzc2FnZXMgZm9yIHRoaXMgc3RyZWFtLgoKDQoFBAMCAQQSBK4BAgoK
DQoFBAMCAQUSBK4BCxEKDQoFBAMCAQESBK4BEicKDQoFBAMCAQMSBK4BKisKvgEKBAQDAgIS
BLMBAkEarwEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0IHRoaXMgYnVpbGQgaXMgYXNzb2NpYXRl
ZCB3aXRoLgogVGhpcyBzaG91bGQgbWF0Y2ggdGhlIHByb2plY3QgdXNlZCBmb3IgdGhlIGlu
aXRpYWwgY2FsbCB0bwogUHVibGlzaExpZmVjeWNsZUV2ZW50IChjb250YWluaW5nIGEgQnVp
bGRFbnF1ZXVlZCBtZXNzYWdlKS4KCg0KBQQDAgIFEgSzAQIICg0KBQQDAgIBEgSzAQkTCg0K
BQQDAgIDEgSzARYXCg0KBQQDAgIIEgSzARhAChAKCAQDAgIInAgAEgSzARk/CpACCgQEAwID
EgS5AQI0GoECIFdoZXRoZXIgdG8gcmVxdWlyZSBhIHByZXZpb3VzbHkgcmVjZWl2ZWQgbWF0
Y2hpbmcgSW52b2NhdGlvbkF0dGVtcHRTdGFydGVkCiBldmVudCBiZWZvcmUgY29udGludWlu
ZyBldmVudCBwcm9jZXNzaW5nIGZvciB0aGUgZXZlbnQgaW4gdGhlIGN1cnJlbnQKIHJlcXVl
c3QuIEJFUyBvbmx5IHBlcmZvcm1zIHRoaXMgY2hlY2sgZm9yIGV2ZW50cyB3aXRoIHNlcXVl
bmNlX251bWJlciAxCiBpLmUuIHRoZSBmaXJzdCBldmVudCBpbiB0aGUgc3RyZWFtLgoKDQoF
BAMCAwUSBLkBAgYKDQoFBAMCAwESBLkBBy8KDQoFBAMCAwMSBLkBMjNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest ===
    # Fields for PublishLifecycleEventRequest
    # Field: service_level Type: 14 (.google.devtools.build.v1.PublishLifecycleEventRequest.ServiceLevel)
    # Field: build_event Type: 11 (.google.devtools.build.v1.OrderedBuildEvent)
    # Field: stream_timeout Type: 11 (.google.protobuf.Duration)
    # Field: notification_keywords Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: check_preceding_lifecycle_events_present Type: 8 ()

# Enum: PublishLifecycleEventRequest::ServiceLevel
our $PublishLifecycleEventRequest_NONINTERACTIVE = 0;
our $PublishLifecycleEventRequest_INTERACTIVE = 1;

# === Message: Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamResponse ===
    # Fields for PublishBuildToolEventStreamResponse
    # Field: stream_id Type: 11 (.google.devtools.build.v1.StreamId)
    # Field: sequence_number Type: 3 ()

# === Message: Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent ===
    # Fields for OrderedBuildEvent
    # Field: stream_id Type: 11 (.google.devtools.build.v1.StreamId)
    # Field: sequence_number Type: 3 ()
    # Field: event Type: 11 (.google.devtools.build.v1.BuildEvent)

# === Message: Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamRequest ===
    # Fields for PublishBuildToolEventStreamRequest
    # Field: ordered_build_event Type: 11 (.google.devtools.build.v1.OrderedBuildEvent)
    # Field: notification_keywords Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: check_preceding_lifecycle_events_present Type: 8 ()

# === Service Client: Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildEventClient ===
package Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildEventClient;

=pod

=head2 Service Client: Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildEventClient

Client stub representing the remote C<PublishBuildEvent> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub publish_lifecycle_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.build.v1.PublishBuildEvent',
        method         => 'PublishLifecycleEvent',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub publish_build_tool_event_stream {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.build.v1.PublishBuildEvent',
        method         => 'PublishBuildToolEventStream',
        request        => $req,
        response_class => 'Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Build::V1::PublishBuildEvent - Compiled Protocol Buffers messages for google/devtools/build/v1/publish_build_event.proto

=head1 SYNOPSIS

    use Google::Devtools::Build::V1::PublishBuildEvent;

    my $msg = Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest->new({
        service_level => $service_level,
        build_event => $build_event,
        stream_timeout => $stream_timeout,
        notification_keywords => $notification_keywords,
    });

    # Read or update a field
    my $val = $msg->service_level();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/build/v1/publish_build_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest

Publishes 'lifecycle events' that update the high-level state of a build:
- BuildEnqueued: When a build is scheduled.
- InvocationAttemptStarted: When work for a build starts; there can be
    multiple invocations for a build (e.g. retries).
- InvocationAttemptCompleted: When work for a build finishes.
- BuildFinished: When a build is finished.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_level() >> / C<< $msg->service_level($value) >>

Type: C<Enum> (L<Google::Devtools::Build::V1::PublishLifecycleEventRequest::ServiceLevel>)

The interactivity of this build.

=item * C<< $msg->build_event() >> / C<< $msg->build_event($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent>)

Required. The lifecycle build event. If this is a build tool event, the RPC
will fail with INVALID_REQUEST.

=item * C<< $msg->stream_timeout() >> / C<< $msg->stream_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

If the next event for this build or invocation (depending on the event
type) hasn't been published after this duration from when {build_event}
is written to BES, consider this stream expired. If this field is not set,
BES backend will use its own default value.

=item * C<< $msg->notification_keywords() >> / C<< $msg->notification_keywords($value) >>

Type: C<String>

Additional information about a build request. These are define by the event
publishers, and the Build Event Service does not validate or interpret
them. They are used while notifying internal systems of new builds and
invocations if the OrderedBuildEvent.event type is
BuildEnqueued/InvocationAttemptStarted.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The project this build is associated with.
This should match the project used for the initial call to
PublishLifecycleEvent (containing a BuildEnqueued message).

=item * C<< $msg->check_preceding_lifecycle_events_present() >> / C<< $msg->check_preceding_lifecycle_events_present($value) >>

Type: C<Bool>

Whether to require a previously received matching parent lifecycle event
for the current request's event before continuing processing.
- InvocationAttemptStarted and BuildFinished events require a BuildEnqueued
  parent event.
- InvocationAttemptFinished events require an InvocationAttemptStarted
  parent event.

=back

=head3 Enum: PublishLifecycleEventRequest::ServiceLevel

=over 4

=item * C<NONINTERACTIVE> => C<0>

=item * C<INTERACTIVE> => C<1>

=back

=head2 Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamResponse

States which event has been committed. Any failure to commit will cause
RPC errors, hence not recorded by this proto.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::StreamId>)

The stream that contains this event.

=item * C<< $msg->sequence_number() >> / C<< $msg->sequence_number($value) >>

Type: C<Int64>

The sequence number of this event that has been committed.

=back

=head2 Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent

Build event with contextual information about the stream it belongs to and
its position in that stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::StreamId>)

Which build event stream this event belongs to.

=item * C<< $msg->sequence_number() >> / C<< $msg->sequence_number($value) >>

Type: C<Int64>

The position of this event in the stream. The sequence numbers for a build
event stream should be a sequence of consecutive natural numbers starting
from one. (1, 2, 3, ...)

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent>)

The actual event.

=back

=head2 Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamRequest

Streaming request message for PublishBuildToolEventStream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ordered_build_event() >> / C<< $msg->ordered_build_event($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent>)

Required. The build event with position info.
New publishing clients should use this field rather than the 3 above.

=item * C<< $msg->notification_keywords() >> / C<< $msg->notification_keywords($value) >>

Type: C<String>

The keywords to be attached to the notification which notifies the start
of a new build event stream. BES only reads this field when sequence_number
or ordered_build_event.sequence_number is 1 in this message. If this field
is empty, BES will not publish notification messages for this stream.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The project this build is associated with.
This should match the project used for the initial call to
PublishLifecycleEvent (containing a BuildEnqueued message).

=item * C<< $msg->check_preceding_lifecycle_events_present() >> / C<< $msg->check_preceding_lifecycle_events_present($value) >>

Type: C<Bool>

Whether to require a previously received matching InvocationAttemptStarted
event before continuing event processing for the event in the current
request. BES only performs this check for events with sequence_number 1
i.e. the first event in the stream.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Build::V1::PublishBuildEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
