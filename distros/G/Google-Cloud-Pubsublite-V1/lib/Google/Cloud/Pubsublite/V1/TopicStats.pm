package Google::Cloud::Pubsublite::V1::TopicStats;

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
    eval { require Google::Cloud::Pubsublite::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvcHVic3VibGl0ZS92MS90b3BpY19zdGF0cy5wcm90bxIaZ29vZ2xl
LmNsb3VkLnB1YnN1YmxpdGUudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvY2xvdWQvcHVic3VibGl0ZS92
MS9jb21tb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iiAIKGkNv
bXB1dGVNZXNzYWdlU3RhdHNSZXF1ZXN0Ej0KBXRvcGljGAEgASgJQifgQQL6QSEKH3B1YnN1
YmxpdGUuZ29vZ2xlYXBpcy5jb20vVG9waWNSBXRvcGljEiEKCXBhcnRpdGlvbhgCIAEoA0ID
4EECUglwYXJ0aXRpb24SRQoMc3RhcnRfY3Vyc29yGAMgASgLMiIuZ29vZ2xlLmNsb3VkLnB1
YnN1YmxpdGUudjEuQ3Vyc29yUgtzdGFydEN1cnNvchJBCgplbmRfY3Vyc29yGAQgASgLMiIu
Z29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuQ3Vyc29yUgllbmRDdXJzb3Ii/wEKG0NvbXB1
dGVNZXNzYWdlU3RhdHNSZXNwb25zZRIjCg1tZXNzYWdlX2NvdW50GAEgASgDUgxtZXNzYWdl
Q291bnQSIwoNbWVzc2FnZV9ieXRlcxgCIAEoA1IMbWVzc2FnZUJ5dGVzEkwKFG1pbmltdW1f
cHVibGlzaF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFISbWluaW11
bVB1Ymxpc2hUaW1lEkgKEm1pbmltdW1fZXZlbnRfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBSEG1pbmltdW1FdmVudFRpbWUifAoYQ29tcHV0ZUhlYWRDdXJzb3JS
ZXF1ZXN0Ej0KBXRvcGljGAEgASgJQifgQQL6QSEKH3B1YnN1YmxpdGUuZ29vZ2xlYXBpcy5j
b20vVG9waWNSBXRvcGljEiEKCXBhcnRpdGlvbhgCIAEoA0ID4EECUglwYXJ0aXRpb24iYAoZ
Q29tcHV0ZUhlYWRDdXJzb3JSZXNwb25zZRJDCgtoZWFkX2N1cnNvchgBIAEoCzIiLmdvb2ds
ZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkN1cnNvclIKaGVhZEN1cnNvciLBAQoYQ29tcHV0ZVRp
bWVDdXJzb3JSZXF1ZXN0Ej0KBXRvcGljGAEgASgJQifgQQL6QSEKH3B1YnN1YmxpdGUuZ29v
Z2xlYXBpcy5jb20vVG9waWNSBXRvcGljEiEKCXBhcnRpdGlvbhgCIAEoA0ID4EECUglwYXJ0
aXRpb24SQwoGdGFyZ2V0GAMgASgLMiYuZ29vZ2xlLmNsb3VkLnB1YnN1YmxpdGUudjEuVGlt
ZVRhcmdldEID4EECUgZ0YXJnZXQiVwoZQ29tcHV0ZVRpbWVDdXJzb3JSZXNwb25zZRI6CgZj
dXJzb3IYASABKAsyIi5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5DdXJzb3JSBmN1cnNv
cjLyBQoRVG9waWNTdGF0c1NlcnZpY2US3QEKE0NvbXB1dGVNZXNzYWdlU3RhdHMSNi5nb29n
bGUuY2xvdWQucHVic3VibGl0ZS52MS5Db21wdXRlTWVzc2FnZVN0YXRzUmVxdWVzdBo3Lmdv
b2dsZS5jbG91ZC5wdWJzdWJsaXRlLnYxLkNvbXB1dGVNZXNzYWdlU3RhdHNSZXNwb25zZSJV
gtPkkwJPIkovdjEvdG9waWNTdGF0cy97dG9waWM9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi90
b3BpY3MvKn06Y29tcHV0ZU1lc3NhZ2VTdGF0czoBKhLVAQoRQ29tcHV0ZUhlYWRDdXJzb3IS
NC5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5Db21wdXRlSGVhZEN1cnNvclJlcXVlc3Qa
NS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5Db21wdXRlSGVhZEN1cnNvclJlc3BvbnNl
IlOC0+STAk0iSC92MS90b3BpY1N0YXRzL3t0b3BpYz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3RvcGljcy8qfTpjb21wdXRlSGVhZEN1cnNvcjoBKhLVAQoRQ29tcHV0ZVRpbWVDdXJzb3IS
NC5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5Db21wdXRlVGltZUN1cnNvclJlcXVlc3Qa
NS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS52MS5Db21wdXRlVGltZUN1cnNvclJlc3BvbnNl
IlOC0+STAk0iSC92MS90b3BpY1N0YXRzL3t0b3BpYz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3RvcGljcy8qfTpjb21wdXRlVGltZUN1cnNvcjoBKhpNykEZcHVic3VibGl0ZS5nb29nbGVh
cGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZv
cm1C0AEKIWNvbS5nb29nbGUuY2xvdWQucHVic3VibGl0ZS5wcm90b0IPVG9waWNTdGF0c1By
b3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vcHVic3VibGl0ZS9hcGl2MS9wdWJzdWJsaXRl
cGI7cHVic3VibGl0ZXBiqgIaR29vZ2xlLkNsb3VkLlB1YlN1YkxpdGUuVjHKAhpHb29nbGVc
Q2xvdWRcUHViU3ViTGl0ZVxWMeoCHUdvb2dsZTo6Q2xvdWQ6OlB1YlN1YkxpdGU6OlYxSvMm
CgcSBQ4AoQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAj
CgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYA
MQoJCgIDBRIDFwApCggKAQgSAxkANwoJCgIIJRIDGQA3CggKAQgSAxoAVQoJCgIICxIDGgBV
CggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAMAoJCgIICBIDHAAwCggKAQgSAx0AOgoJ
CgIIARIDHQA6CggKAQgSAx4ANwoJCgIIKRIDHgA3CggKAQgSAx8ANgoJCgIILRIDHwA2ClMK
AgYAEgQiAEgBGkcgVGhpcyBzZXJ2aWNlIGFsbG93cyB1c2VycyB0byBnZXQgc3RhdHMgYWJv
dXQgbWVzc2FnZXMgaW4gdGhlaXIgdG9waWMuCgoKCgMGAAESAyIIGQoKCgMGAAMSAyMCQQoM
CgUGAAOZCBIDIwJBCgsKAwYAAxIEJAIlNwoNCgUGAAOaCBIEJAIlNwpdCgQGAAIAEgQpAi8D
Gk8gQ29tcHV0ZSBzdGF0aXN0aWNzIGFib3V0IGEgcmFuZ2Ugb2YgbWVzc2FnZXMgaW4gYSBn
aXZlbiB0b3BpYyBhbmQKIHBhcnRpdGlvbi4KCgwKBQYAAgABEgMpBhkKDAoFBgACAAISAyka
NAoMCgUGAAIAAxIDKg8qCg0KBQYAAgAEEgQrBC4GChEKCQYAAgAEsMq8IhIEKwQuBgraAgoE
BgACARIENwI9AxrLAiBDb21wdXRlIHRoZSBoZWFkIGN1cnNvciBmb3IgdGhlIHBhcnRpdGlv
bi4KIFRoZSBoZWFkIGN1cnNvcidzIG9mZnNldCBpcyBndWFyYW50ZWVkIHRvIGJlIGxlc3Mg
dGhhbiBvciBlcXVhbCB0byBhbGwKIG1lc3NhZ2VzIHdoaWNoIGhhdmUgbm90IHlldCBiZWVu
IGFja25vd2xlZGdlZCBhcyBwdWJsaXNoZWQsIGFuZAogZ3JlYXRlciB0aGFuIHRoZSBvZmZz
ZXQgb2YgYW55IG1lc3NhZ2Ugd2hvc2UgcHVibGlzaCBoYXMgYWxyZWFkeQogYmVlbiBhY2tu
b3dsZWRnZWQuIEl0IGlzIHplcm8gaWYgdGhlcmUgaGF2ZSBuZXZlciBiZWVuIG1lc3NhZ2Vz
IGluIHRoZQogcGFydGl0aW9uLgoKDAoFBgACAQESAzcGFwoMCgUGAAIBAhIDNxgwCgwKBQYA
AgEDEgM4DygKDQoFBgACAQQSBDkEPAYKEQoJBgACAQSwyrwiEgQ5BDwGCmMKBAYAAgISBEEC
RwMaVSBDb21wdXRlIHRoZSBjb3JyZXNwb25kaW5nIGN1cnNvciBmb3IgYSBwdWJsaXNoIG9y
IGV2ZW50IHRpbWUgaW4gYSB0b3BpYwogcGFydGl0aW9uLgoKDAoFBgACAgESA0EGFwoMCgUG
AAICAhIDQRgwCgwKBQYAAgIDEgNCDygKDQoFBgACAgQSBEMERgYKEQoJBgACAgSwyrwiEgRD
BEYGCloKAgQAEgRLAF4BGk4gQ29tcHV0ZSBzdGF0aXN0aWNzIGFib3V0IGEgcmFuZ2Ugb2Yg
bWVzc2FnZXMgaW4gYSBnaXZlbiB0b3BpYyBhbmQgcGFydGl0aW9uLgoKCgoDBAABEgNLCCIK
TgoEBAACABIETQJSBBpAIFJlcXVpcmVkLiBUaGUgdG9waWMgZm9yIHdoaWNoIHdlIHNob3Vs
ZCBjb21wdXRlIG1lc3NhZ2Ugc3RhdHMuCgoMCgUEAAIABRIDTQIICgwKBQQAAgABEgNNCQ4K
DAoFBAACAAMSA00REgoNCgUEAAIACBIETRNSAwoPCggEAAIACJwIABIDTgQqCg8KBwQAAgAI
nwgSBE8EUQUKUQoEBAACARIDVQI/GkQgUmVxdWlyZWQuIFRoZSBwYXJ0aXRpb24gZm9yIHdo
aWNoIHdlIHNob3VsZCBjb21wdXRlIG1lc3NhZ2Ugc3RhdHMuCgoMCgUEAAIBBRIDVQIHCgwK
BQQAAgEBEgNVCBEKDAoFBAACAQMSA1UUFQoMCgUEAAIBCBIDVRY+Cg8KCAQAAgEInAgAEgNV
Fz0KMAoEBAACAhIDWAIaGiMgVGhlIGluY2x1c2l2ZSBzdGFydCBvZiB0aGUgcmFuZ2UuCgoM
CgUEAAICBhIDWAIICgwKBQQAAgIBEgNYCRUKDAoFBAACAgMSA1gYGQrbAQoEBAACAxIDXQIY
Gs0BIFRoZSBleGNsdXNpdmUgZW5kIG9mIHRoZSByYW5nZS4gVGhlIHJhbmdlIGlzIGVtcHR5
IGlmIGVuZF9jdXJzb3IgPD0KIHN0YXJ0X2N1cnNvci4gU3BlY2lmeWluZyBhIHN0YXJ0X2N1
cnNvciBiZWZvcmUgdGhlIGZpcnN0IG1lc3NhZ2UgYW5kIGFuCiBlbmRfY3Vyc29yIGFmdGVy
IHRoZSBsYXN0IG1lc3NhZ2Ugd2lsbCByZXRyaWV2ZSBhbGwgbWVzc2FnZXMuCgoMCgUEAAID
BhIDXQIICgwKBQQAAgMBEgNdCRMKDAoFBAACAwMSA10WFwpaCgIEARIEYQBxARpOIFJlc3Bv
bnNlIGNvbnRhaW5pbmcgc3RhdHMgZm9yIG1lc3NhZ2VzIGluIHRoZSByZXF1ZXN0ZWQgdG9w
aWMgYW5kIHBhcnRpdGlvbi4KCgoKAwQBARIDYQgjCiUKBAQBAgASA2MCGhoYIFRoZSBjb3Vu
dCBvZiBtZXNzYWdlcy4KCgwKBQQBAgAFEgNjAgcKDAoFBAECAAESA2MIFQoMCgUEAQIAAxID
YxgZCkUKBAQBAgESA2YCGho4IFRoZSBudW1iZXIgb2YgcXVvdGEgYnl0ZXMgYWNjb3VudGVk
IHRvIHRoZXNlIG1lc3NhZ2VzLgoKDAoFBAECAQUSA2YCBwoMCgUEAQIBARIDZggVCgwKBQQB
AgEDEgNmGBkK1QEKBAQBAgISA2sCNRrHASBUaGUgbWluaW11bSBwdWJsaXNoIHRpbWVzdGFt
cCBhY3Jvc3MgdGhlc2UgbWVzc2FnZXMuIE5vdGUgdGhhdCBwdWJsaXNoCiB0aW1lc3RhbXBz
IHdpdGhpbiBhIHBhcnRpdGlvbiBhcmUgbm90IGd1YXJhbnRlZWQgdG8gYmUgbm9uLWRlY3Jl
YXNpbmcuIFRoZQogdGltZXN0YW1wIHdpbGwgYmUgdW5zZXQgaWYgdGhlcmUgYXJlIG5vIG1l
c3NhZ2VzLgoKDAoFBAECAgYSA2sCGwoMCgUEAQICARIDaxwwCgwKBQQBAgIDEgNrMzQK4wEK
BAQBAgMSA3ACMxrVASBUaGUgbWluaW11bSBldmVudCB0aW1lc3RhbXAgYWNyb3NzIHRoZXNl
IG1lc3NhZ2VzLiBGb3IgdGhlIHB1cnBvc2VzIG9mIHRoaXMKIGNvbXB1dGF0aW9uLCBpZiBh
IG1lc3NhZ2UgZG9lcyBub3QgaGF2ZSBhbiBldmVudCB0aW1lLCB3ZSB1c2UgdGhlIHB1Ymxp
c2gKIHRpbWUuIFRoZSB0aW1lc3RhbXAgd2lsbCBiZSB1bnNldCBpZiB0aGVyZSBhcmUgbm8g
bWVzc2FnZXMuCgoMCgUEAQIDBhIDcAIbCgwKBQQBAgMBEgNwHC4KDAoFBAECAwMSA3AxMgo+
CgIEAhIEdAB/ARoyIENvbXB1dGUgdGhlIGN1cnJlbnQgaGVhZCBjdXJzb3IgZm9yIGEgcGFy
dGl0aW9uLgoKCgoDBAIBEgN0CCAKUAoEBAICABIEdgJ7BBpCIFJlcXVpcmVkLiBUaGUgdG9w
aWMgZm9yIHdoaWNoIHdlIHNob3VsZCBjb21wdXRlIHRoZSBoZWFkIGN1cnNvci4KCgwKBQQC
AgAFEgN2AggKDAoFBAICAAESA3YJDgoMCgUEAgIAAxIDdhESCg0KBQQCAgAIEgR2E3sDCg8K
CAQCAgAInAgAEgN3BCoKDwoHBAICAAifCBIEeAR6BQpTCgQEAgIBEgN+Aj8aRiBSZXF1aXJl
ZC4gVGhlIHBhcnRpdGlvbiBmb3Igd2hpY2ggd2Ugc2hvdWxkIGNvbXB1dGUgdGhlIGhlYWQg
Y3Vyc29yLgoKDAoFBAICAQUSA34CBwoMCgUEAgIBARIDfggRCgwKBQQCAgEDEgN+FBUKDAoF
BAICAQgSA34WPgoPCggEAgIBCJwIABIDfhc9CloKAgQDEgaCAQCFAQEaTCBSZXNwb25zZSBj
b250YWluaW5nIHRoZSBoZWFkIGN1cnNvciBmb3IgdGhlIHJlcXVlc3RlZCB0b3BpYyBhbmQg
cGFydGl0aW9uLgoKCwoDBAMBEgSCAQghCiAKBAQDAgASBIQBAhkaEiBUaGUgaGVhZCBjdXJz
b3IuCgoNCgUEAwIABhIEhAECCAoNCgUEAwIAARIEhAEJFAoNCgUEAwIAAxIEhAEXGApjCgIE
BBIGiQEAmAEBGlUgQ29tcHV0ZSB0aGUgY29ycmVzcG9uZGluZyBjdXJzb3IgZm9yIGEgcHVi
bGlzaCBvciBldmVudCB0aW1lIGluIGEgdG9waWMKIHBhcnRpdGlvbi4KCgsKAwQEARIEiQEI
IApNCgQEBAIAEgaLAQKQAQQaPSBSZXF1aXJlZC4gVGhlIHRvcGljIGZvciB3aGljaCB3ZSBz
aG91bGQgY29tcHV0ZSB0aGUgY3Vyc29yLgoKDQoFBAQCAAUSBIsBAggKDQoFBAQCAAESBIsB
CQ4KDQoFBAQCAAMSBIsBERIKDwoFBAQCAAgSBosBE5ABAwoQCggEBAIACJwIABIEjAEEKgoR
CgcEBAIACJ8IEgaNAQSPAQUKTwoEBAQCARIEkwECPxpBIFJlcXVpcmVkLiBUaGUgcGFydGl0
aW9uIGZvciB3aGljaCB3ZSBzaG91bGQgY29tcHV0ZSB0aGUgY3Vyc29yLgoKDQoFBAQCAQUS
BJMBAgcKDQoFBAQCAQESBJMBCBEKDQoFBAQCAQMSBJMBFBUKDQoFBAQCAQgSBJMBFj4KEAoI
BAQCAQicCAASBJMBFz0KcgoEBAQCAhIElwECQRpkIFJlcXVpcmVkLiBUaGUgdGFyZ2V0IHB1
Ymxpc2ggb3IgZXZlbnQgdGltZS4gU3BlY2lmeWluZyBhIGZ1dHVyZSB0aW1lIHdpbGwKIHJl
dHVybiBhbiB1bnNldCBjdXJzb3IuCgoNCgUEBAICBhIElwECDAoNCgUEBAICARIElwENEwoN
CgUEBAICAxIElwEWFwoNCgUEBAICCBIElwEYQAoQCggEBAICCJwIABIElwEZPwpuCgIEBRIG
nAEAoQEBGmAgUmVzcG9uc2UgY29udGFpbmluZyB0aGUgY3Vyc29yIGNvcnJlc3BvbmRpbmcg
dG8gYSBwdWJsaXNoIG9yIGV2ZW50IHRpbWUgaW4gYQogdG9waWMgcGFydGl0aW9uLgoKCwoD
BAUBEgScAQghCuABCgQEBQIAEgSgAQIUGtEBIElmIHByZXNlbnQsIHRoZSBjdXJzb3IgcmVm
ZXJlbmNlcyB0aGUgZmlyc3QgbWVzc2FnZSB3aXRoIHRpbWUgZ3JlYXRlciB0aGFuCiBvciBl
cXVhbCB0byB0aGUgc3BlY2lmaWVkIHRhcmdldCB0aW1lLiBJZiBzdWNoIGEgbWVzc2FnZSBj
YW5ub3QgYmUgZm91bmQsCiB0aGUgY3Vyc29yIHdpbGwgYmUgdW5zZXQgKGkuZS4gYGN1cnNv
cmAgaXMgbm90IHByZXNlbnQpLgoKDQoFBAUCAAYSBKABAggKDQoFBAUCAAESBKABCQ8KDQoF
BAUCAAMSBKABEhNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest ===
    # Fields for ComputeMessageStatsRequest
    # Field: topic Type: 9 ()
    # Field: partition Type: 3 ()
    # Field: start_cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)
    # Field: end_cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse ===
    # Fields for ComputeMessageStatsResponse
    # Field: message_count Type: 3 ()
    # Field: message_bytes Type: 3 ()
    # Field: minimum_publish_time Type: 11 (.google.protobuf.Timestamp)
    # Field: minimum_event_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorRequest ===
    # Fields for ComputeHeadCursorRequest
    # Field: topic Type: 9 ()
    # Field: partition Type: 3 ()

# === Message: Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorResponse ===
    # Fields for ComputeHeadCursorResponse
    # Field: head_cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Message: Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorRequest ===
    # Fields for ComputeTimeCursorRequest
    # Field: topic Type: 9 ()
    # Field: partition Type: 3 ()
    # Field: target Type: 11 (.google.cloud.pubsublite.v1.TimeTarget)

# === Message: Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorResponse ===
    # Fields for ComputeTimeCursorResponse
    # Field: cursor Type: 11 (.google.cloud.pubsublite.v1.Cursor)

# === Service Client: Google::Cloud::Pubsublite::V1::TopicStats::TopicStatsServiceClient ===
package Google::Cloud::Pubsublite::V1::TopicStats::TopicStatsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Pubsublite::V1::TopicStats::TopicStatsServiceClient

Client stub representing the remote C<TopicStatsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsublite.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsublite.googleapis.com:443' );

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

sub compute_message_stats {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.TopicStatsService',
        method         => 'ComputeMessageStats',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse',
    });
}

sub compute_head_cursor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.TopicStatsService',
        method         => 'ComputeHeadCursor',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorResponse',
    });
}

sub compute_time_cursor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.pubsublite.v1.TopicStatsService',
        method         => 'ComputeTimeCursor',
        request        => $req,
        response_class => 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Pubsublite::V1::TopicStats - Compiled Protocol Buffers messages for google/cloud/pubsublite/v1/topic_stats.proto

=head1 SYNOPSIS

    use Google::Cloud::Pubsublite::V1::TopicStats;

    my $msg = Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest->new({
        topic => $topic,
        partition => $partition,
        start_cursor => $start_cursor,
        end_cursor => $end_cursor,
    });

    # Read or update a field
    my $val = $msg->topic();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/pubsublite/v1/topic_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest

Compute statistics about a range of messages in a given topic and partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

Required. The topic for which we should compute message stats.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

Required. The partition for which we should compute message stats.

=item * C<< $msg->start_cursor() >> / C<< $msg->start_cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The inclusive start of the range.

=item * C<< $msg->end_cursor() >> / C<< $msg->end_cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The exclusive end of the range. The range is empty if end_cursor <=
start_cursor. Specifying a start_cursor before the first message and an
end_cursor after the last message will retrieve all messages.

=back

=head2 Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse

Response containing stats for messages in the requested topic and partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_count() >> / C<< $msg->message_count($value) >>

Type: C<Int64>

The count of messages.

=item * C<< $msg->message_bytes() >> / C<< $msg->message_bytes($value) >>

Type: C<Int64>

The number of quota bytes accounted to these messages.

=item * C<< $msg->minimum_publish_time() >> / C<< $msg->minimum_publish_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The minimum publish timestamp across these messages. Note that publish
timestamps within a partition are not guaranteed to be non-decreasing. The
timestamp will be unset if there are no messages.

=item * C<< $msg->minimum_event_time() >> / C<< $msg->minimum_event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The minimum event timestamp across these messages. For the purposes of this
computation, if a message does not have an event time, we use the publish
time. The timestamp will be unset if there are no messages.

=back

=head2 Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorRequest

Compute the current head cursor for a partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

Required. The topic for which we should compute the head cursor.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

Required. The partition for which we should compute the head cursor.

=back

=head2 Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorResponse

Response containing the head cursor for the requested topic and partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->head_cursor() >> / C<< $msg->head_cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

The head cursor.

=back

=head2 Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorRequest

Compute the corresponding cursor for a publish or event time in a topic
partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

Required. The topic for which we should compute the cursor.

=item * C<< $msg->partition() >> / C<< $msg->partition($value) >>

Type: C<Int64>

Required. The partition for which we should compute the cursor.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::TimeTarget>)

Required. The target publish or event time. Specifying a future time will
return an unset cursor.

=back

=head2 Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorResponse

Response containing the cursor corresponding to a publish or event time in a
topic partition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cursor() >> / C<< $msg->cursor($value) >>

Type: C<Message> (L<Google::Cloud::Pubsublite::V1::Common::Cursor>)

If present, the cursor references the first message with time greater than
or equal to the specified target time. If such a message cannot be found,
the cursor will be unset (i.e. `cursor` is not present).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Pubsublite::V1::TopicStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
