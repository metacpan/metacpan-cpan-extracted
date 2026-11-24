package Google::Cloud::Connectors::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9jb21tb24ucHJvdG8SGmdvb2dsZS5jbG91
ZC5jb25uZWN0b3JzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItUCChFPcGVyYXRpb25NZXRhZGF0YRJACgtj
cmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3Jl
YXRlVGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IHZW5kVGltZRIbCgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZlcmIYBCAB
KAlCA+BBA1IEdmVyYhIqCg5zdGF0dXNfbWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0dXNNZXNz
YWdlEjoKFnJlcXVlc3RlZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVzdGVkQ2Fu
Y2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9uGAcgASgJQgPgQQNSCmFwaVZlcnNpb24isgYKFkNv
bmZpZ1ZhcmlhYmxlVGVtcGxhdGUSEAoDa2V5GAEgASgJUgNrZXkSWwoKdmFsdWVfdHlwZRgC
IAEoDjI8Lmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkNvbmZpZ1ZhcmlhYmxlVGVtcGxh
dGUuVmFsdWVUeXBlUgl2YWx1ZVR5cGUSIQoMZGlzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5
TmFtZRIgCgtkZXNjcmlwdGlvbhgEIAEoCVILZGVzY3JpcHRpb24SKQoQdmFsaWRhdGlvbl9y
ZWdleBgFIAEoCVIPdmFsaWRhdGlvblJlZ2V4EhoKCHJlcXVpcmVkGAYgASgIUghyZXF1aXJl
ZBJECgpyb2xlX2dyYW50GAcgASgLMiUuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUm9s
ZUdyYW50Uglyb2xlR3JhbnQSSQoMZW51bV9vcHRpb25zGAggAygLMiYuZ29vZ2xlLmNsb3Vk
LmNvbm5lY3RvcnMudjEuRW51bU9wdGlvblILZW51bU9wdGlvbnMSaQoXYXV0aG9yaXphdGlv
bl9jb2RlX2xpbmsYCSABKAsyMS5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5BdXRob3Jp
emF0aW9uQ29kZUxpbmtSFWF1dGhvcml6YXRpb25Db2RlTGluaxJOCgVzdGF0ZRgKIAEoDjI4
Lmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkNvbmZpZ1ZhcmlhYmxlVGVtcGxhdGUuU3Rh
dGVSBXN0YXRlEh8KC2lzX2FkdmFuY2VkGAsgASgIUgppc0FkdmFuY2VkInQKCVZhbHVlVHlw
ZRIaChZWQUxVRV9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGU1RSSU5HEAESBwoDSU5UEAISCAoE
Qk9PTBADEgoKBlNFQ1JFVBAEEggKBEVOVU0QBRIWChJBVVRIT1JJWkFUSU9OX0NPREUQBiI6
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEg4KCkRFUFJFQ0FU
RUQQAiIvCgZTZWNyZXQSJQoOc2VjcmV0X3ZlcnNpb24YASABKAlSDXNlY3JldFZlcnNpb24i
PwoKRW51bU9wdGlvbhIOCgJpZBgBIAEoCVICaWQSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtk
aXNwbGF5TmFtZSLZAQoOQ29uZmlnVmFyaWFibGUSEAoDa2V5GAEgASgJUgNrZXkSHQoJaW50
X3ZhbHVlGAIgASgDSABSCGludFZhbHVlEh8KCmJvb2xfdmFsdWUYAyABKAhIAFIJYm9vbFZh
bHVlEiMKDHN0cmluZ192YWx1ZRgEIAEoCUgAUgtzdHJpbmdWYWx1ZRJHCgxzZWNyZXRfdmFs
dWUYBSABKAsyIi5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5TZWNyZXRIAFILc2VjcmV0
VmFsdWVCBwoFdmFsdWUiqQQKCVJvbGVHcmFudBJNCglwcmluY2lwYWwYASABKA4yLy5nb29n
bGUuY2xvdWQuY29ubmVjdG9ycy52MS5Sb2xlR3JhbnQuUHJpbmNpcGFsUglwcmluY2lwYWwS
FAoFcm9sZXMYAiADKAlSBXJvbGVzEkoKCHJlc291cmNlGAMgASgLMi4uZ29vZ2xlLmNsb3Vk
LmNvbm5lY3RvcnMudjEuUm9sZUdyYW50LlJlc291cmNlUghyZXNvdXJjZRIwChRoZWxwZXJf
dGV4dF90ZW1wbGF0ZRgEIAEoCVISaGVscGVyVGV4dFRlbXBsYXRlGv4BCghSZXNvdXJjZRJH
CgR0eXBlGAEgASgOMjMuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUm9sZUdyYW50LlJl
c291cmNlLlR5cGVSBHR5cGUSIwoNcGF0aF90ZW1wbGF0ZRgDIAEoCVIMcGF0aFRlbXBsYXRl
IoMBCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIPCgtHQ1BfUFJPSkVDVBABEhAKDEdD
UF9SRVNPVVJDRRACEhwKGEdDUF9TRUNSRVRNQU5BR0VSX1NFQ1JFVBADEiQKIEdDUF9TRUNS
RVRNQU5BR0VSX1NFQ1JFVF9WRVJTSU9OEAQiOAoJUHJpbmNpcGFsEhkKFVBSSU5DSVBBTF9V
TlNQRUNJRklFRBAAEhAKDENPTk5FQ1RPUl9TQRABIn8KFUF1dGhvcml6YXRpb25Db2RlTGlu
axIQCgN1cmkYASABKAlSA3VyaRIWCgZzY29wZXMYAiADKAlSBnNjb3BlcxIbCgljbGllbnRf
aWQYAyABKAlSCGNsaWVudElkEh8KC2VuYWJsZV9wa2NlGAQgASgIUgplbmFibGVQa2NlKmUK
C0xhdW5jaFN0YWdlEhwKGExBVU5DSF9TVEFHRV9VTlNQRUNJRklFRBAAEgsKB1BSRVZJRVcQ
ARIGCgJHQRACEg4KCkRFUFJFQ0FURUQQAxITCg9QUklWQVRFX1BSRVZJRVcQBUJvCh5jb20u
Z29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjFCC0NvbW1vblByb3RvUAFaPmNsb3VkLmdvb2ds
ZS5jb20vZ28vY29ubmVjdG9ycy9hcGl2MS9jb25uZWN0b3JzcGI7Y29ubmVjdG9yc3BiSqNE
CgcSBQ4AigIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
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
CgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVAFUKCQoCCAsSAxUAVQoICgEIEgMWACIK
CQoCCAoSAxYAIgoICgEIEgMXACwKCQoCCAgSAxcALAoICgEIEgMYADcKCQoCCAESAxgANwpE
CgIEABIEGwA2ARo4IFJlcHJlc2VudHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5p
bmcgb3BlcmF0aW9uLgoKCgoDBAABEgMbCBkKQAoEBAACABIEHQIeMhoyIE91dHB1dCBvbmx5
LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAAYSAx0CGwoM
CgUEAAIAARIDHRwnCgwKBQQAAgADEgMdKisKDAoFBAACAAgSAx4GMQoPCggEAAIACJwIABID
HgcwCkUKBAQAAgESBCECIjIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlv
biBmaW5pc2hlZCBydW5uaW5nLgoKDAoFBAACAQYSAyECGwoMCgUEAAIBARIDIRwkCgwKBQQA
AgEDEgMhJygKDAoFBAACAQgSAyIGMQoPCggEAAIBCJwIABIDIgcwClkKBAQAAgISAyUCQBpM
IE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFy
Z2V0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAAICBRIDJQIICgwKBQQAAgIBEgMlCQ8KDAoF
BAACAgMSAyUSEwoMCgUEAAICCBIDJRQ/Cg8KCAQAAgIInAgAEgMlFT4KRwoEBAACAxIDKAI+
GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJh
dGlvbi4KCgwKBQQAAgMFEgMoAggKDAoFBAACAwESAygJDQoMCgUEAAIDAxIDKBARCgwKBQQA
AgMIEgMoEj0KDwoIBAACAwicCAASAygTPApLCgQEAAIEEgMrAkgaPiBPdXRwdXQgb25seS4g
SHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCgwKBQQA
AgQFEgMrAggKDAoFBAACBAESAysJFwoMCgUEAAIEAxIDKxobCgwKBQQAAgQIEgMrHEcKDwoI
BAACBAicCAASAysdRgqaAgoEBAACBRIDMgJOGowCIE91dHB1dCBvbmx5LiBJZGVudGlmaWVz
IHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBv
cGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVuIGNhbmNl
bGxlZAogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtdIHZhbHVlIHdpdGggYQogW2dvb2dsZS5y
cGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsIGNvcnJlc3Bv
bmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoMCgUEAAIFBRIDMgIGCgwKBQQAAgUBEgMy
Bx0KDAoFBAACBQMSAzIgIQoMCgUEAAIFCBIDMiJNCg8KCAQAAgUInAgAEgMyI0wKRAoEBAAC
BhIDNQJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9w
ZXJhdGlvbi4KCgwKBQQAAgYFEgM1AggKDAoFBAACBgESAzUJFAoMCgUEAAIGAxIDNRcYCgwK
BQQAAgYIEgM1GUQKDwoIBAACBgicCAASAzUaQwpvCgIEARIFOgCDAQEaYiBDb25maWdWYXJp
YWJsZVRlbXBsYXRlIHByb3ZpZGVzIG1ldGFkYXRhIGFib3V0IGEgYENvbmZpZ1ZhcmlhYmxl
YCB0aGF0IGlzCiB1c2VkIGluIGEgQ29ubmVjdGlvbi4KCgoKAwQBARIDOggeCj8KBAQBBAAS
BDwCUQMaMSBWYWx1ZVR5cGUgaW5kaWNhdGVzIHRoZSBkYXRhIHR5cGUgb2YgdGhlIHZhbHVl
LgoKDAoFBAEEAAESAzwHEAotCgYEAQQAAgASAz4EHxoeIFZhbHVlIHR5cGUgaXMgbm90IHNw
ZWNpZmllZC4KCg4KBwQBBAACAAESAz4EGgoOCgcEAQQAAgACEgM+HR4KJgoGBAEEAAIBEgNB
BA8aFyBWYWx1ZSB0eXBlIGlzIHN0cmluZy4KCg4KBwQBBAACAQESA0EECgoOCgcEAQQAAgEC
EgNBDQ4KJwoGBAEEAAICEgNEBAwaGCBWYWx1ZSB0eXBlIGlzIGludGVnZXIuCgoOCgcEAQQA
AgIBEgNEBAcKDgoHBAEEAAICAhIDRAoLCicKBgQBBAACAxIDRwQNGhggVmFsdWUgdHlwZSBp
cyBib29sZWFuLgoKDgoHBAEEAAIDARIDRwQICg4KBwQBBAACAwISA0cLDAomCgYEAQQAAgQS
A0oEDxoXIFZhbHVlIHR5cGUgaXMgc2VjcmV0LgoKDgoHBAEEAAIEARIDSgQKCg4KBwQBBAAC
BAISA0oNDgokCgYEAQQAAgUSA00EDRoVIFZhbHVlIHR5cGUgaXMgZW51bS4KCg4KBwQBBAAC
BQESA00ECAoOCgcEAQQAAgUCEgNNCwwKMgoGBAEEAAIGEgNQBBsaIyBWYWx1ZSB0eXBlIGlz
IGF1dGhvcml6YXRpb24gY29kZS4KCg4KBwQBBAACBgESA1AEFgoOCgcEAQQAAgYCEgNQGRoK
OwoEBAEEARIEVAJdAxotIEluZGljYXRlcyB0aGUgc3RhdGUgb2YgdGhlIGNvbmZpZyB2YXJp
YWJsZS4KCgwKBQQBBAEBEgNUBwwKJwoGBAEEAQIAEgNWBBoaGCBTdGF0dXMgaXMgdW5zcGVj
aWZpZWQuCgoOCgcEAQQBAgABEgNWBBUKDgoHBAEEAQIAAhIDVhgZCioKBgQBBAECARIDWQQP
GhsgQ29uZmlnIHZhcmlhYmxlIGlzIGFjdGl2ZQoKDgoHBAEEAQIBARIDWQQKCg4KBwQBBAEC
AQISA1kNDgovCgYEAQQBAgISA1wEExogIENvbmZpZyB2YXJpYWJsZSBpcyBkZXByZWNhdGVk
LgoKDgoHBAEEAQICARIDXAQOCg4KBwQBBAECAgISA1wREgoqCgQEAQIAEgNgAhEaHSBLZXkg
b2YgdGhlIGNvbmZpZyB2YXJpYWJsZS4KCgwKBQQBAgAFEgNgAggKDAoFBAECAAESA2AJDAoM
CgUEAQIAAxIDYA8QCnYKBAQBAgESA2QCGxppIFR5cGUgb2YgdGhlIHBhcmFtZXRlcjogc3Ry
aW5nLCBpbnQsIGJvb2wgZXRjLgogY29uc2lkZXIgY3VzdG9tIHR5cGUgZm9yIHRoZSBiZW5l
Zml0IGZvciB0aGUgdmFsaWRhdGlvbi4KCgwKBQQBAgEGEgNkAgsKDAoFBAECAQESA2QMFgoM
CgUEAQIBAxIDZBkaCi0KBAQBAgISA2cCGhogIERpc3BsYXkgbmFtZSBvZiB0aGUgcGFyYW1l
dGVyLgoKDAoFBAECAgUSA2cCCAoMCgUEAQICARIDZwkVCgwKBQQBAgIDEgNnGBkKGwoEBAEC
AxIDagIZGg4gRGVzY3JpcHRpb24uCgoMCgUEAQIDBRIDagIICgwKBQQBAgMBEgNqCRQKDAoF
BAECAwMSA2oXGApnCgQEAQIEEgNuAh4aWiBSZWd1bGFyIGV4cHJlc3Npb24gaW4gUkUyIHN5
bnRheCB1c2VkIGZvciB2YWxpZGF0aW5nIHRoZSBgdmFsdWVgIG9mIGEKIGBDb25maWdWYXJp
YWJsZWAuCgoMCgUEAQIEBRIDbgIICgwKBQQBAgQBEgNuCRkKDAoFBAECBAMSA24cHQpdCgQE
AQIFEgNyAhQaUCBGbGFnIHJlcHJlc2VudHMgdGhhdCB0aGlzIGBDb25maWdWYXJpYWJsZWAg
bXVzdCBiZSBwcm92aWRlZCBmb3IgYQogY29ubmVjdGlvbi4KCgwKBQQBAgUFEgNyAgYKDAoF
BAECBQESA3IHDwoMCgUEAQIFAxIDchITCkAKBAQBAgYSA3UCGxozIFJvbGUgZ3JhbnQgY29u
ZmlndXJhdGlvbiBmb3IgdGhlIGNvbmZpZyB2YXJpYWJsZS4KCgwKBQQBAgYGEgN1AgsKDAoF
BAECBgESA3UMFgoMCgUEAQIGAxIDdRkaCkUKBAQBAgcSA3gCJxo4IEVudW0gb3B0aW9ucy4g
VG8gYmUgcG9wdWxhdGVkIGlmIGBWYWx1ZVR5cGVgIGlzIGBFTlVNYAoKDAoFBAECBwQSA3gC
CgoMCgUEAQIHBhIDeAsVCgwKBQQBAgcBEgN4FiIKDAoFBAECBwMSA3glJgpnCgQEAQIIEgN8
AjQaWiBBdXRob3JpemF0aW9uIGNvZGUgbGluayBvcHRpb25zLiBUbyBiZSBwb3B1bGF0ZWQg
aWYgYFZhbHVlVHlwZWAgaXMKIGBBVVRIT1JJWkFUSU9OX0NPREVgCgoMCgUEAQIIBhIDfAIX
CgwKBQQBAggBEgN8GC8KDAoFBAECCAMSA3wyMwosCgQEAQIJEgN/AhMaHyBTdGF0ZSBvZiB0
aGUgY29uZmlnIHZhcmlhYmxlLgoKDAoFBAECCQYSA38CBwoMCgUEAQIJARIDfwgNCgwKBQQB
AgkDEgN/EBIKSgoEBAECChIEggECGBo8IEluZGljYXRlcyBpZiBjdXJyZW50IHRlbXBsYXRl
IGlzIHBhcnQgb2YgYWR2YW5jZWQgc2V0dGluZ3MKCg0KBQQBAgoFEgSCAQIGCg0KBQQBAgoB
EgSCAQcSCg0KBQQBAgoDEgSCARUXCkkKAgQCEgaGAQCKAQEaOyBTZWNyZXQgcHJvdmlkZXMg
YSByZWZlcmVuY2UgdG8gZW50cmllcyBpbiBTZWNyZXQgTWFuYWdlci4KCgsKAwQCARIEhgEI
Dgp1CgQEAgIAEgSJAQIcGmcgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHNlY3JldCB2ZXJz
aW9uIGluIHRoZSBmb3JtYXQsCiBmb3JtYXQgYXM6IGBwcm9qZWN0cy8qL3NlY3JldHMvKi92
ZXJzaW9ucy8qYC4KCg0KBQQCAgAFEgSJAQIICg0KBQQCAgABEgSJAQkXCg0KBQQCAgADEgSJ
ARobCiUKAgQDEgaNAQCTAQEaFyBFbnVtT3B0aW9uIGRlZmluaXRpb24KCgsKAwQDARIEjQEI
EgohCgQEAwIAEgSPAQIQGhMgSWQgb2YgdGhlIG9wdGlvbi4KCg0KBQQDAgAFEgSPAQIICg0K
BQQDAgABEgSPAQkLCg0KBQQDAgADEgSPAQ4PCisKBAQDAgESBJIBAhoaHSBEaXNwbGF5IG5h
bWUgb2YgdGhlIG9wdGlvbi4KCg0KBQQDAgEFEgSSAQIICg0KBQQDAgEBEgSSAQkVCg0KBQQD
AgEDEgSSARgZCmsKAgQEEgaXAQCpAQEaXSBDb25maWdWYXJpYWJsZSByZXByZXNlbnRzIGEg
Y29uZmlndXJhdGlvbiB2YXJpYWJsZSBwcmVzZW50IGluIGEgQ29ubmVjdGlvbi4KIG9yIEF1
dGhDb25maWcuCgoLCgMEBAESBJcBCBYKKwoEBAQCABIEmQECERodIEtleSBvZiB0aGUgY29u
ZmlnIHZhcmlhYmxlLgoKDQoFBAQCAAUSBJkBAggKDQoFBAQCAAESBJkBCQwKDQoFBAQCAAMS
BJkBDxAKNAoEBAQIABIGnAECqAEDGiQgVmFsdWUgdHlwZSBvZiB0aGUgY29uZmlnIHZhcmlh
YmxlLgoKDQoFBAQIAAESBJwBCA0KIwoEBAQCARIEngEEGBoVIFZhbHVlIGlzIGFuIGludGVn
ZXIKCg0KBQQEAgEFEgSeAQQJCg0KBQQEAgEBEgSeAQoTCg0KBQQEAgEDEgSeARYXCiAKBAQE
AgISBKEBBBgaEiBWYWx1ZSBpcyBhIGJvb2wuCgoNCgUEBAICBRIEoQEECAoNCgUEBAICARIE
oQEJEwoNCgUEBAICAxIEoQEWFwoiCgQEBAIDEgSkAQQcGhQgVmFsdWUgaXMgYSBzdHJpbmcu
CgoNCgUEBAIDBRIEpAEECgoNCgUEBAIDARIEpAELFwoNCgUEBAIDAxIEpAEaGwoiCgQEBAIE
EgSnAQQcGhQgVmFsdWUgaXMgYSBzZWNyZXQuCgoNCgUEBAIEBhIEpwEECgoNCgUEBAIEARIE
pwELFwoNCgUEBAIEAxIEpwEaGwr+AgoCBAUSBrABAOQBARrvAiBUaGlzIGNvbmZpZ3VyYXRp
b24gZGVmaW5lcyBhbGwgdGhlIENsb3VkIElBTSByb2xlcyB0aGF0IG5lZWRzIHRvIGJlIGdy
YW50ZWQKIHRvIGEgcGFydGljdWxhciBHQ1AgcmVzb3VyY2UgZm9yIHRoZSBzZWxlY3RlZCBw
cmluaWNwYWwgbGlrZSBzZXJ2aWNlCiBhY2NvdW50LiBUaGVzZSBjb25maWd1cmF0aW9ucyB3
aWxsIGxldCBVSSBkaXNwbGF5IHRvIGN1c3RvbWVycyB3aGF0CiBJQU0gcm9sZXMgbmVlZCB0
byBiZSBncmFudGVkIGJ5IHRoZW0uIE9yIHRoZXNlIGNvbmZpZ3VyYXRpb25zIGNhbiBiZSB1
c2VkCiBieSB0aGUgVUkgdG8gcmVuZGVyIGEgJ2dyYW50JyBidXR0b24gdG8gZG8gdGhlIHNh
bWUgb24gYmVoYWxmIG9mIHRoZSB1c2VyLgoKCwoDBAUBEgSwAQgRCi0KBAQFBAASBrIBAroB
AxodIFN1cHBvcnRlZCBQcmluY2lwYWwgdmFsdWVzLgoKDQoFBAUEAAESBLIBBxAKLgoGBAUE
AAIAEgS0AQQeGh4gVmFsdWUgdHlwZSBpcyBub3Qgc3BlY2lmaWVkLgoKDwoHBAUEAAIAARIE
tAEEGQoPCgcEBQQAAgACEgS0ARwdCrsBCgYEBQQAAgESBLkBBBUaqgEgU2VydmljZSBBY2Nv
dW50IHVzZWQgZm9yIENvbm5lY3RvciB3b3JrbG9hZCBpZGVudGl0eQogVGhpcyBpcyBlaXRo
ZXIgdGhlIGRlZmF1bHQgc2VydmljZSBhY2NvdW50IGlmIHVuc3BlY2lmaWVkIG9yIFNlcnZp
Y2UKIEFjY291bnQgcHJvdmlkZWQgYnkgQ3VzdG9tZXJzIHRocm91Z2ggQllPU0EuCgoPCgcE
BQQAAgEBEgS5AQQQCg8KBwQFBAACAQISBLkBExQKJQoEBAUDABIGvQEC1wEDGhUgUmVzb3Vy
Y2UgZGVmaW5pdGlvbgoKDQoFBAUDAAESBL0BChIKLQoGBAUDAAQAEga/AQTOAQUaGyBSZXNv
dXJjZSBUeXBlIGRlZmluaXRpb24uCgoPCgcEBQMABAABEgS/AQkNCjAKCAQFAwAEAAIAEgTB
AQYbGh4gVmFsdWUgdHlwZSBpcyBub3Qgc3BlY2lmaWVkLgoKEQoJBAUDAAQAAgABEgTBAQYW
ChEKCQQFAwAEAAIAAhIEwQEZGgopCggEBQMABAACARIExAEGFhoXIEdDUCBQcm9qZWN0IFJl
c291cmNlLgoKEQoJBAUDAAQAAgEBEgTEAQYRChEKCQQFAwAEAAIBAhIExAEUFQpJCggEBQMA
BAACAhIExwEGFxo3IEFueSBHQ1AgUmVzb3VyY2Ugd2hpY2ggaXMgaWRlbnRpZmllZCB1bmlx
dWVseSBieSBJQU0uCgoRCgkEBQMABAACAgESBMcBBhIKEQoJBAUDAAQAAgICEgTHARUWCigK
CAQFAwAEAAIDEgTKAQYjGhYgR0NQIFNlY3JldCBSZXNvdXJjZS4KChEKCQQFAwAEAAIDARIE
ygEGHgoRCgkEBQMABAACAwISBMoBISIKMAoIBAUDAAQAAgQSBM0BBisaHiBHQ1AgU2VjcmV0
IFZlcnNpb24gUmVzb3VyY2UuCgoRCgkEBQMABAACBAESBM0BBiYKEQoJBAUDAAQAAgQCEgTN
ASkqCjgKBgQFAwACABIE0QEEEhooIERpZmZlcmVudCB0eXBlcyBvZiByZXNvdXJjZSBzdXBw
b3J0ZWQuCgoPCgcEBQMAAgAGEgTRAQQICg8KBwQFAwACAAESBNEBCQ0KDwoHBAUDAAIAAxIE
0QEQEQrAAQoGBAUDAAIBEgTWAQQdGq8BIFRlbXBsYXRlIHRvIHVuaXF1ZWx5IHJlcHJlc2Vu
dCBhIEdDUCByZXNvdXJjZSBpbiBhIGZvcm1hdCBJQU0gZXhwZWN0cwogVGhpcyBpcyBhIHRl
bXBsYXRlIHRoYXQgY2FuIGhhdmUgcmVmZXJlbmNlcyB0byBvdGhlciB2YWx1ZXMgcHJvdmlk
ZWQgaW4KIHRoZSBjb25maWcgdmFyaWFibGUgdGVtcGxhdGUuCgoPCgcEBQMAAgEFEgTWAQQK
Cg8KBwQFAwACAQESBNYBCxgKDwoHBAUDAAIBAxIE1gEbHApHCgQEBQIAEgTaAQIaGjkgUHJp
bmljaXBhbC9JZGVudGl0eSBmb3Igd2hvbSB0aGUgcm9sZSBuZWVkIHRvIGFzc2lnbmVkLgoK
DQoFBAUCAAYSBNoBAgsKDQoFBAUCAAESBNoBDBUKDQoFBAUCAAMSBNoBGBkKNgoEBAUCARIE
3QECHBooIExpc3Qgb2Ygcm9sZXMgdGhhdCBuZWVkIHRvIGJlIGdyYW50ZWQuCgoNCgUEBQIB
BBIE3QECCgoNCgUEBQIBBRIE3QELEQoNCgUEBQIBARIE3QESFwoNCgUEBQIBAxIE3QEaGwpS
CgQEBQICEgTgAQIYGkQgUmVzb3VyY2Ugb24gd2hpY2ggdGhlIHJvbGVzIG5lZWRzIHRvIGJl
IGdyYW50ZWQgZm9yIHRoZSBwcmluY2lwYWwuCgoNCgUEBQICBhIE4AECCgoNCgUEBQICARIE
4AELEwoNCgUEBQICAxIE4AEWFwpNCgQEBQIDEgTjAQIiGj8gVGVtcGxhdGUgdGhhdCBVSSBj
YW4gdXNlIHRvIHByb3ZpZGUgaGVscGVyIHRleHQgdG8gY3VzdG9tZXJzLgoKDQoFBAUCAwUS
BOMBAggKDQoFBAUCAwESBOMBCR0KDQoFBAUCAwMSBOMBICEKiAEKAgQGEgboAQD3AQEaeiBU
aGlzIGNvbmZpZ3VyYXRpb24gY2FwdHVyZXMgdGhlIGRldGFpbHMgcmVxdWlyZWQgdG8gcmVu
ZGVyIGFuIGF1dGhvcml6YXRpb24KIGxpbmsgZm9yIHRoZSBPQXV0aCBBdXRob3JpemF0aW9u
IENvZGUgRmxvdy4KCgsKAwQGARIE6AEIHQpfCgQEBgIAEgTrAQIRGlEgVGhlIGJhc2UgVVJJ
IHRoZSB1c2VyIG11c3QgY2xpY2sgdG8gdHJpZ2dlciB0aGUgYXV0aG9yaXphdGlvbiBjb2Rl
IGxvZ2luCiBmbG93LgoKDQoFBAYCAAUSBOsBAggKDQoFBAYCAAESBOsBCQwKDQoFBAYCAAMS
BOsBDxAKagoEBAYCARIE7wECHRpcIFRoZSBzY29wZXMgZm9yIHdoaWNoIHRoZSB1c2VyIHdp
bGwgYXV0aG9yaXplIEdDUCBDb25uZWN0b3JzIG9uIHRoZQogY29ubmVjdG9yIGRhdGEgc291
cmNlLgoKDQoFBAYCAQQSBO8BAgoKDQoFBAYCAQUSBO8BCxEKDQoFBAYCAQESBO8BEhgKDQoF
BAYCAQMSBO8BGxwKZgoEBAYCAhIE8wECFxpYIFRoZSBjbGllbnQgSUQgYXNzaWduZWQgdG8g
dGhlIEdDUCBDb25uZWN0b3JzIE9BdXRoIGFwcCBmb3IgdGhlIGNvbm5lY3RvcgogZGF0YSBz
b3VyY2UuCgoNCgUEBgICBRIE8wECCAoNCgUEBgICARIE8wEJEgoNCgUEBgICAxIE8wEVFgo+
CgQEBgIDEgT2AQIXGjAgV2hldGhlciB0byBlbmFibGUgUEtDRSBmb3IgdGhlIGF1dGggY29k
ZSBmbG93LgoKDQoFBAYCAwUSBPYBAgYKDQoFBAYCAwESBPYBBxIKDQoFBAYCAwMSBPYBFRYK
agoCBQASBvsBAIoCARpcIExhdW5jaFN0YWdlIGlzIGEgZW51bSB0byBpbmRpY2F0ZSBsYXVu
Y2ggc3RhZ2U6CiBQUkVWSUVXLCBHQSwgREVQUkVDQVRFRCwgUFJJVkFURV9QUkVWSUVXLgoK
CwoDBQABEgT7AQUQCikKBAUAAgASBP0BAh8aGyBMQVVOQ0hfU1RBR0VfVU5TUEVDSUZJRUQu
CgoNCgUFAAIAARIE/QECGgoNCgUFAAIAAhIE/QEdHgoYCgQFAAIBEgSAAgIOGgogUFJFVklF
Vy4KCg0KBQUAAgEBEgSAAgIJCg0KBQUAAgECEgSAAgwNChMKBAUAAgISBIMCAgkaBSBHQS4K
Cg0KBQUAAgIBEgSDAgIECg0KBQUAAgICEgSDAgcIChsKBAUAAgMSBIYCAhEaDSBERVBSRUNB
VEVELgoKDQoFBQACAwESBIYCAgwKDQoFBQACAwISBIYCDxAKIAoEBQACBBIEiQICFhoSIFBS
SVZBVEVfUFJFVklFVy4KCg0KBQUAAgQBEgSJAgIRCg0KBQUAAgQCEgSJAhQVYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate ===
    # Fields for ConfigVariableTemplate
    # Field: key Type: 9 ()
    # Field: value_type Type: 14 (.google.cloud.connectors.v1.ConfigVariableTemplate.ValueType)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: validation_regex Type: 9 ()
    # Field: required Type: 8 ()
    # Field: role_grant Type: 11 (.google.cloud.connectors.v1.RoleGrant)
    # Field: enum_options Type: 11 (.google.cloud.connectors.v1.EnumOption)
    # Field: authorization_code_link Type: 11 (.google.cloud.connectors.v1.AuthorizationCodeLink)
    # Field: state Type: 14 (.google.cloud.connectors.v1.ConfigVariableTemplate.State)
    # Field: is_advanced Type: 8 ()

# Enum: ConfigVariableTemplate::ValueType
our $ConfigVariableTemplate_VALUE_TYPE_UNSPECIFIED = 0;
our $ConfigVariableTemplate_STRING = 1;
our $ConfigVariableTemplate_INT = 2;
our $ConfigVariableTemplate_BOOL = 3;
our $ConfigVariableTemplate_SECRET = 4;
our $ConfigVariableTemplate_ENUM = 5;
our $ConfigVariableTemplate_AUTHORIZATION_CODE = 6;

# Enum: ConfigVariableTemplate::State
our $ConfigVariableTemplate_STATE_UNSPECIFIED = 0;
our $ConfigVariableTemplate_ACTIVE = 1;
our $ConfigVariableTemplate_DEPRECATED = 2;

# === Message: Google::Cloud::Connectors::V1::Common::Secret ===
    # Fields for Secret
    # Field: secret_version Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Common::EnumOption ===
    # Fields for EnumOption
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Common::ConfigVariable ===
    # Fields for ConfigVariable
    # Field: key Type: 9 ()
    # Field: int_value Type: 3 ()
    # Field: bool_value Type: 8 ()
    # Field: string_value Type: 9 ()
    # Field: secret_value Type: 11 (.google.cloud.connectors.v1.Secret)

# === Message: Google::Cloud::Connectors::V1::Common::RoleGrant ===
    # Fields for RoleGrant
    # Field: principal Type: 14 (.google.cloud.connectors.v1.RoleGrant.Principal)
    # Field: roles Type: 9 ()
    # Field: resource Type: 11 (.google.cloud.connectors.v1.RoleGrant.Resource)
    # Field: helper_text_template Type: 9 ()

# Enum: RoleGrant::Principal
our $RoleGrant_PRINCIPAL_UNSPECIFIED = 0;
our $RoleGrant_CONNECTOR_SA = 1;

# === Message: Google::Cloud::Connectors::V1::Common::AuthorizationCodeLink ===
    # Fields for AuthorizationCodeLink
    # Field: uri Type: 9 ()
    # Field: scopes Type: 9 ()
    # Field: client_id Type: 9 ()
    # Field: enable_pkce Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::Common - Compiled Protocol Buffers messages for google/cloud/connectors/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::Common;

    my $msg = Google::Cloud::Connectors::V1::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::Common::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate

ConfigVariableTemplate provides metadata about a `ConfigVariable` that is
used in a Connection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key of the config variable.

=item * C<< $msg->value_type() >> / C<< $msg->value_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::ConfigVariableTemplate::ValueType>)

Type of the parameter: string, int, bool etc.
consider custom type for the benefit for the validation.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name of the parameter.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description.

=item * C<< $msg->validation_regex() >> / C<< $msg->validation_regex($value) >>

Type: C<String>

Regular expression in RE2 syntax used for validating the `value` of a
`ConfigVariable`.

=item * C<< $msg->required() >> / C<< $msg->required($value) >>

Type: C<Bool>

Flag represents that this `ConfigVariable` must be provided for a
connection.

=item * C<< $msg->role_grant() >> / C<< $msg->role_grant($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::RoleGrant>)

Role grant configuration for the config variable.

=item * C<< $msg->enum_options() >> / C<< $msg->enum_options($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::EnumOption>)

Enum options. To be populated if `ValueType` is `ENUM`

=item * C<< $msg->authorization_code_link() >> / C<< $msg->authorization_code_link($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::AuthorizationCodeLink>)

Authorization code link options. To be populated if `ValueType` is
`AUTHORIZATION_CODE`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::ConfigVariableTemplate::State>)

State of the config variable.

=item * C<< $msg->is_advanced() >> / C<< $msg->is_advanced($value) >>

Type: C<Bool>

Indicates if current template is part of advanced settings

=back

=head3 Enum: ConfigVariableTemplate::ValueType

=over 4

=item * C<VALUE_TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INT> => C<2>

=item * C<BOOL> => C<3>

=item * C<SECRET> => C<4>

=item * C<ENUM> => C<5>

=item * C<AUTHORIZATION_CODE> => C<6>

=back

=head3 Enum: ConfigVariableTemplate::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<DEPRECATED> => C<2>

=back

=head2 Google::Cloud::Connectors::V1::Common::Secret

Secret provides a reference to entries in Secret Manager.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->secret_version() >> / C<< $msg->secret_version($value) >>

Type: C<String>

The resource name of the secret version in the format,
format as: `projects/*/secrets/*/versions/*`.

=back

=head2 Google::Cloud::Connectors::V1::Common::EnumOption

EnumOption definition

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Id of the option.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name of the option.

=back

=head2 Google::Cloud::Connectors::V1::Common::ConfigVariable

ConfigVariable represents a configuration variable present in a Connection.
or AuthConfig.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key of the config variable.

=item * C<< $msg->int_value() >> / C<< $msg->int_value($value) >>

Type: C<Int64>

Value is an integer

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

Value is a bool.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

Value is a string.

=item * C<< $msg->secret_value() >> / C<< $msg->secret_value($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::Secret>)

Value is a secret.

=back

=head2 Google::Cloud::Connectors::V1::Common::RoleGrant

This configuration defines all the Cloud IAM roles that needs to be granted
to a particular GCP resource for the selected prinicpal like service
account. These configurations will let UI display to customers what
IAM roles need to be granted by them. Or these configurations can be used
by the UI to render a 'grant' button to do the same on behalf of the user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal() >> / C<< $msg->principal($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::RoleGrant::Principal>)

Prinicipal/Identity for whom the role need to assigned.

=item * C<< $msg->roles() >> / C<< $msg->roles($value) >>

Type: C<String>

List of roles that need to be granted.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::RoleGrant::Resource>)

Resource on which the roles needs to be granted for the principal.

=item * C<< $msg->helper_text_template() >> / C<< $msg->helper_text_template($value) >>

Type: C<String>

Template that UI can use to provide helper text to customers.

=back

=head3 Enum: RoleGrant::Principal

=over 4

=item * C<PRINCIPAL_UNSPECIFIED> => C<0>

=item * C<CONNECTOR_SA> => C<1>

=back

=head2 Google::Cloud::Connectors::V1::Common::AuthorizationCodeLink

This configuration captures the details required to render an authorization
link for the OAuth Authorization Code Flow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The base URI the user must click to trigger the authorization code login
flow.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

The scopes for which the user will authorize GCP Connectors on the
connector data source.

=item * C<< $msg->client_id() >> / C<< $msg->client_id($value) >>

Type: C<String>

The client ID assigned to the GCP Connectors OAuth app for the connector
data source.

=item * C<< $msg->enable_pkce() >> / C<< $msg->enable_pkce($value) >>

Type: C<Bool>

Whether to enable PKCE for the auth code flow.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
