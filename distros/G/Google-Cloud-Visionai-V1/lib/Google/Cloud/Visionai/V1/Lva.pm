package Google::Cloud::Visionai::V1::Lva;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvbHZhLnByb3RvEhhnb29nbGUuY2xvdWQudmlz
aW9uYWkudjEi0QUKEk9wZXJhdG9yRGVmaW5pdGlvbhIaCghvcGVyYXRvchgBIAEoCVIIb3Bl
cmF0b3ISXgoKaW5wdXRfYXJncxgCIAMoCzI/Lmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5P
cGVyYXRvckRlZmluaXRpb24uQXJndW1lbnREZWZpbml0aW9uUglpbnB1dEFyZ3MSYAoLb3V0
cHV0X2FyZ3MYAyADKAsyPy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuT3BlcmF0b3JEZWZp
bml0aW9uLkFyZ3VtZW50RGVmaW5pdGlvblIKb3V0cHV0QXJncxJgCgphdHRyaWJ1dGVzGAQg
AygLMkAuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLk9wZXJhdG9yRGVmaW5pdGlvbi5BdHRy
aWJ1dGVEZWZpbml0aW9uUgphdHRyaWJ1dGVzEk0KCXJlc291cmNlcxgFIAEoCzIvLmdvb2ds
ZS5jbG91ZC52aXNpb25haS52MS5SZXNvdXJjZVNwZWNpZmljYXRpb25SCXJlc291cmNlcxIr
ChFzaG9ydF9kZXNjcmlwdGlvbhgGIAEoCVIQc2hvcnREZXNjcmlwdGlvbhIgCgtkZXNjcmlw
dGlvbhgHIAEoCVILZGVzY3JpcHRpb24aRAoSQXJndW1lbnREZWZpbml0aW9uEhoKCGFyZ3Vt
ZW50GAEgASgJUghhcmd1bWVudBISCgR0eXBlGAIgASgJUgR0eXBlGpYBChNBdHRyaWJ1dGVE
ZWZpbml0aW9uEhwKCWF0dHJpYnV0ZRgBIAEoCVIJYXR0cmlidXRlEhIKBHR5cGUYAiABKAlS
BHR5cGUSTQoNZGVmYXVsdF92YWx1ZRgDIAEoCzIoLmdvb2dsZS5jbG91ZC52aXNpb25haS52
MS5BdHRyaWJ1dGVWYWx1ZVIMZGVmYXVsdFZhbHVlIsUBChVSZXNvdXJjZVNwZWNpZmljYXRp
b24SEAoDY3B1GAEgASgJUgNjcHUSHQoKY3B1X2xpbWl0cxgFIAEoCVIJY3B1TGltaXRzEhYK
Bm1lbW9yeRgCIAEoCVIGbWVtb3J5EiMKDW1lbW9yeV9saW1pdHMYBiABKAlSDG1lbW9yeUxp
bWl0cxISCgRncHVzGAMgASgFUgRncHVzEioKEWxhdGVuY3lfYnVkZ2V0X21zGAQgASgFUg9s
YXRlbmN5QnVkZ2V0TXMiWQoOQXR0cmlidXRlVmFsdWUSDgoBaRgBIAEoA0gAUgFpEg4KAWYY
AiABKAJIAFIBZhIOCgFiGAMgASgISABSAWISDgoBcxgEIAEoDEgAUgFzQgcKBXZhbHVlIuEG
ChJBbmFseXplckRlZmluaXRpb24SGgoIYW5hbHl6ZXIYASABKAlSCGFuYWx5emVyEhoKCG9w
ZXJhdG9yGAIgASgJUghvcGVyYXRvchJQCgZpbnB1dHMYAyADKAsyOC5nb29nbGUuY2xvdWQu
dmlzaW9uYWkudjEuQW5hbHl6ZXJEZWZpbml0aW9uLlN0cmVhbUlucHV0UgZpbnB1dHMSTQoF
YXR0cnMYBCADKAsyNy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuQW5hbHl6ZXJEZWZpbml0
aW9uLkF0dHJzRW50cnlSBWF0dHJzEl4KDWRlYnVnX29wdGlvbnMYBSABKAsyOS5nb29nbGUu
Y2xvdWQudmlzaW9uYWkudjEuQW5hbHl6ZXJEZWZpbml0aW9uLkRlYnVnT3B0aW9uc1IMZGVi
dWdPcHRpb25zEmQKD29wZXJhdG9yX29wdGlvbhgGIAEoCzI7Lmdvb2dsZS5jbG91ZC52aXNp
b25haS52MS5BbmFseXplckRlZmluaXRpb24uT3BlcmF0b3JPcHRpb25SDm9wZXJhdG9yT3B0
aW9uGiMKC1N0cmVhbUlucHV0EhQKBWlucHV0GAEgASgJUgVpbnB1dBriAQoMRGVidWdPcHRp
b25zEogBChVlbnZpcm9ubWVudF92YXJpYWJsZXMYASADKAsyUy5nb29nbGUuY2xvdWQudmlz
aW9uYWkudjEuQW5hbHl6ZXJEZWZpbml0aW9uLkRlYnVnT3B0aW9ucy5FbnZpcm9ubWVudFZh
cmlhYmxlc0VudHJ5UhRlbnZpcm9ubWVudFZhcmlhYmxlcxpHChlFbnZpcm9ubWVudFZhcmlh
Ymxlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEa
PgoOT3BlcmF0b3JPcHRpb24SEAoDdGFnGAEgASgJUgN0YWcSGgoIcmVnaXN0cnkYAiABKAlS
CHJlZ2lzdHJ5GmIKCkF0dHJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSPgoFdmFsdWUYAiAB
KAsyKC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuQXR0cmlidXRlVmFsdWVSBXZhbHVlOgI4
ASJgChJBbmFseXNpc0RlZmluaXRpb24SSgoJYW5hbHl6ZXJzGAEgAygLMiwuZ29vZ2xlLmNs
b3VkLnZpc2lvbmFpLnYxLkFuYWx5emVyRGVmaW5pdGlvblIJYW5hbHl6ZXJzIssBCglSdW5T
dGF0dXMSPwoFc3RhdGUYASABKA4yKS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuUnVuU3Rh
dHVzLlN0YXRlUgVzdGF0ZRIWCgZyZWFzb24YAiABKAlSBnJlYXNvbiJlCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEhAKDElOSVRJQUxJWklORxABEgsKB1JVTk5JTkcQAhINCglD
T01QTEVURUQQAxIKCgZGQUlMRUQQBBILCgdQRU5ESU5HEAUqPQoHUnVuTW9kZRIYChRSVU5f
TU9ERV9VTlNQRUNJRklFRBAAEggKBExJVkUQARIOCgpTVUJNSVNTSU9OEAJCuAEKHGNvbS5n
b29nbGUuY2xvdWQudmlzaW9uYWkudjFCCEx2YVByb3RvUAFaOGNsb3VkLmdvb2dsZS5jb20v
Z28vdmlzaW9uYWkvYXBpdjEvdmlzaW9uYWlwYjt2aXNpb25haXBiqgIYR29vZ2xlLkNsb3Vk
LlZpc2lvbkFJLlYxygIYR29vZ2xlXENsb3VkXFZpc2lvbkFJXFYx6gIbR29vZ2xlOjpDbG91
ZDo6VmlzaW9uQUk6OlYxSu1ICgcSBQ4ApwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
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
aWNlbnNlLgoKCAoBAhIDEAAhCggKAQgSAxIANQoJCgIIJRIDEgA1CggKAQgSAxMATwoJCgII
CxIDEwBPCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAKQoJCgIICBIDFQApCggKAQgS
AxYANQoJCgIIARIDFgA1CggKAQgSAxcANQoJCgIIKRIDFwA1CggKAQgSAxgANAoJCgIILRID
GAA0CkMKAgUAEgQbACYBGjcgUnVuTW9kZSByZXByZXNlbnRzIHRoZSBtb2RlIHRvIGxhdW5j
aCB0aGUgUHJvY2VzcyBvbi4KCgoKAwUAARIDGwUMCiMKBAUAAgASAx0CGxoWIE1vZGUgaXMg
dW5zcGVjaWZpZWQuCgoMCgUFAAIAARIDHQIWCgwKBQUAAgACEgMdGRoKfwoEBQACARIDIQIL
GnIgTGl2ZSBtb2RlLiBNZWFuaW5nIHRoZSBQcm9jZXNzIGlzIGxhdW5jaGVkIHRvIGhhbmRs
ZSBsaXZlIHZpZGVvCiBzb3VyY2UsIGFuZCBwb3NzaWJsZSBwYWNrZXQgZHJvcHMgYXJlIGV4
cGVjdGVkLgoKDAoFBQACAQESAyECBgoMCgUFAAIBAhIDIQkKCpMBCgQFAAICEgMlAhEahQEg
U3VibWlzc2lvbiBtb2RlLiBNZWFuaW5nIHRoZSBQcm9jZXNzIGlzIGxhdW5jaGVkIHRvIGhh
bmRsZSBib3VuZGVkIHZpZGVvCiBmaWxlcywgd2l0aCBubyBwYWNrZXQgZHJvcC4gQ29tcGxl
dGlvbiBzdGF0dXMgaXMgdHJhY2tlZC4KCgwKBQUAAgIBEgMlAgwKDAoFBQACAgISAyUPEArE
AQoCBAASBCwAZQEatwEgRGVmaW5lcyB0aGUgaW50ZXJmYWNlIG9mIGFuIE9wZXJhdG9yLgoK
IEFyZ3VtZW50cyB0byBhbiBvcGVyYXRvciBhcmUgaW5wdXQvb3V0cHV0IHN0cmVhbXMgdGhh
dCBhcmUgZ2V0dGluZwogcHJvY2Vzc2VzZWQvcmV0dXJuZWQgd2hpbGUgYXR0cmlidXRlcyBh
cmUgZml4ZWQgY29uZmlndXJhdGlvbiBwYXJhbWV0ZXJzLgoKCgoDBAABEgMsCBoKVwoEBAAD
ABIEMAI7AxpJIERlZmluZXMgYW4gYXJndW1lbnQgdG8gYW4gb3BlcmF0b3IuCgogVXNlZCBm
b3IgYm90aCBpbnB1dHMgYW5kIG91dHB1dHMuCgoMCgUEAAMAARIDMAocCnkKBgQAAwACABID
NQQYGmogVGhlIG5hbWUgb2YgdGhlIGFyZ3VtZW50LgoKIFRlbnRhdGl2ZWx5IFthLXpdKFtf
YS16MC05XSpbYS16MC05XSk/LCBlLmcuLCB2aWRlbywgYXVkaW8sCiBoaWdoX2Zwc19mcmFt
ZS4KCg4KBwQAAwACAAUSAzUECgoOCgcEAAMAAgABEgM1CxMKDgoHBAADAAIAAxIDNRYXCncK
BgQAAwACARIDOgQUGmggVGhlIGRhdGEgdHlwZSBvZiB0aGUgYXJndW1lbnQuCgogVGhpcyBz
aG91bGQgbWF0Y2ggdGhlIHRleHR1YWwgcmVwcmVzZW50YXRpb24gb2YgYSBzdHJlYW0vUGFj
a2V0IHR5cGUuCgoOCgcEAAMAAgEFEgM6BAoKDgoHBAADAAIBARIDOgsPCg4KBwQAAwACAQMS
AzoSEwo0CgQEAAMBEgQ+AkwDGiYgRGVmaW5lcyBhbiBhdHRyaWJ1dGUgb2YgYW4gb3BlcmF0
b3IuCgoMCgUEAAMBARIDPgodCoEBCgYEAAMBAgASA0MEGRpyIFRoZSBuYW1lIG9mIHRoZSBh
dHRyaWJ1dGUuCgogVGVudGF0aXZlbHkgW2Etel0oW19hLXowLTldKlthLXowLTldKT8sIGUu
Zy4sIG1heF9mcmFtZXNfcGVyX3ZpZGVvLAogcmVzaXplX2hlaWdodC4KCg4KBwQAAwECAAUS
A0MECgoOCgcEAAMBAgABEgNDCxQKDgoHBAADAQIAAxIDQxcYClsKBgQAAwECARIDSAQUGkwg
VGhlIHR5cGUgb2YgdGhpcyBhdHRyaWJ1dGUuCgogU2VlIGF0dHJpYnV0ZV92YWx1ZS5wcm90
byBmb3IgcG9zc2liaWxpdGllcy4KCg4KBwQAAwECAQUSA0gECgoOCgcEAAMBAgEBEgNICw8K
DgoHBAADAQIBAxIDSBITCjUKBgQAAwECAhIDSwQlGiYgVGhlIGRlZmF1bHQgdmFsdWUgZm9y
IHRoZSBhdHRyaWJ1dGUuCgoOCgcEAAMBAgIGEgNLBBIKDgoHBAADAQICARIDSxMgCg4KBwQA
AwECAgMSA0sjJAp5CgQEAAIAEgNSAhYabCBUaGUgbmFtZSBvZiB0aGlzIG9wZXJhdG9yLgoK
IFRlbnRhdGl2ZWx5IFtBLVpdW2EtekEtWjAtOV0qLCBlLmcuLCBCYm94Q291bnRlciwgUGV0
RGV0ZWN0b3IsCiBQZXREZXRlY3RvcjEuCgoMCgUEAAIABRIDUgIICgwKBQQAAgABEgNSCREK
DAoFBAACAAMSA1IUFQooCgQEAAIBEgNVAi0aGyBEZWNsYXJlcyBpbnB1dCBhcmd1bWVudHMu
CgoMCgUEAAIBBBIDVQIKCgwKBQQAAgEGEgNVCx0KDAoFBAACAQESA1UeKAoMCgUEAAIBAxID
VSssCikKBAQAAgISA1gCLhocIERlY2xhcmVzIG91dHB1dCBhcmd1bWVudHMuCgoMCgUEAAIC
BBIDWAIKCgwKBQQAAgIGEgNYCx0KDAoFBAACAgESA1geKQoMCgUEAAICAxIDWCwtCicKBAQA
AgMSA1sCLhoaIERlY2xhcmVzIHRoZSBhdHRyaWJ1dGVzLgoKDAoFBAACAwQSA1sCCgoMCgUE
AAIDBhIDWwseCgwKBQQAAgMBEgNbHykKDAoFBAACAwMSA1ssLQo2CgQEAAIEEgNeAiYaKSBU
aGUgcmVzb3VyY2VzIGZvciBydW5uaW5nIHRoZSBvcGVyYXRvci4KCgwKBQQAAgQGEgNeAhcK
DAoFBAACBAESA14YIQoMCgUEAAIEAxIDXiQlCjEKBAQAAgUSA2ECHxokIFNob3J0IGRlc2Ny
aXB0aW9uIG9mIHRoZSBvcGVyYXRvci4KCgwKBQQAAgUFEgNhAggKDAoFBAACBQESA2EJGgoM
CgUEAAIFAxIDYR0eCjAKBAQAAgYSA2QCGRojIEZ1bGwgZGVzY3JpcHRpb24gb2YgdGhlIG9w
ZXJhdG9yLgoKDAoFBAACBgUSA2QCCAoMCgUEAAIGARIDZAkUCgwKBQQAAgYDEgNkFxgK/QEK
AgQBEgVtAKEBARrvASBSZXNvdXJjZVNwZWMgY29sbGVjdHMgYSBzZXQgb2YgcmVzb3VyY2Vz
IHRoYXQgY2FuCiBiZSB1c2VkIHRvIHNwZWNpZnkgcmVxdWVzdHMgYW5kIHJlcXVpcmVtZW50
cy4KCiBOb3RlOiBIaWdobHkgZXhwZXJpbWVudGFsIGFzIHRoaXMgY2FuIGJlIHJ1bnRpbWUg
ZGVwZW5kZW50LgogQ2FuIHVzZSB0aGUgImV4dHJhcyIgZmllbGQgdG8gZXhwZXJpbWVudCBm
aXJzdCBiZWZvcmUgdHJ5aW5nCiB0byBhYnN0cmFjdCBpdC4KCgoKAwQBARIDbQgdCsoCCgQE
AQIAEgN5AhEavAIgQ1BVIHNwZWNpZmljYXRpb24uCgogRXhhbXBsZXM6CiAiMTAwbSIsICIw
LjUiLCAiMSIsICIyIiwgLi4uIGNvcnJlc3BvbmQgdG8KIDAuMSwgaGFsZiwgMSwgb3IgMiBj
cHVzLgoKIExlYXZlIGVtcHR5IHRvIGxldCB0aGUgc3lzdGVtIGRlY2lkZS4KCiBOb3RlIHRo
YXQgdGhpcyBkb2VzICpub3QqIGRldGVybWluZSB0aGUgY3B1IHZlbmRlci9tYWtlLAogb3Ig
aXRzIHVuZGVybHlpbmcgY2xvY2sgc3BlZWQgYW5kIHNwZWNpZmljIFNJTUQgZmVhdHVyZXMu
CiBJdCBpcyBvbmx5IHRoZSBhbW91bnQgdGltZSBpdCByZXF1aXJlcyBpbiB0aW1lc2xpY2lu
Zy4KCgwKBQQBAgAFEgN5AggKDAoFBAECAAESA3kJDAoMCgUEAQIAAxIDeQ8QCpEBCgQEAQIB
EgSCAQIYGoIBIENQVSBsaW1pdC4KCiBFeGFtcGxlczoKICIxMDBtIiwgIjAuNSIsICIxIiwg
IjIiLCAuLi4gY29ycmVzcG9uZCB0bwogMC4xLCBoYWxmLCAxLCBvciAyIGNwdXMuCgogTGVh
dmUgZW1wdHkgdG8gaW5kaWNhdGUgbm8gbGltaXQuCgoNCgUEAQIBBRIEggECCAoNCgUEAQIB
ARIEggEJEwoNCgUEAQIBAxIEggEWFwrgAQoEBAECAhIEiwECFBrRASBNZW1vcnkgc3BlY2lm
aWNhdGlvbiAoaW4gYnl0ZXMpLgoKIEV4YW1wbGVzOgogIjEyODk3NDg0OCIsICIxMjllNiIs
ICIxMjlNIiwgIjEyM01pIiwgLi4uIGNvcnJlc3BvbmQgdG8KIDEyODk3NDg0OCBieXRlcywg
MTI5MDAwMDAwIGJ5dGVzLCAxMjkgbWViaWJ5dGVzLCAxMjMgbWVnYWJ5dGVzLgoKIExlYXZl
IGVtcHR5IHRvIGxldCB0aGUgc3lzdGVtIGRlY2lkZS4KCg0KBQQBAgIFEgSLAQIICg0KBQQB
AgIBEgSLAQkPCg0KBQQBAgIDEgSLARITCtABCgQEAQIDEgSUAQIbGsEBIE1lbW9yeSB1c2Fn
ZSBsaW1pdHMuCgogRXhhbXBsZXM6CiAiMTI4OTc0ODQ4IiwgIjEyOWU2IiwgIjEyOU0iLCAi
MTIzTWkiLCAuLi4gY29ycmVzcG9uZCB0bwogMTI4OTc0ODQ4IGJ5dGVzLCAxMjkwMDAwMDAg
Ynl0ZXMsIDEyOSBtZWJpYnl0ZXMsIDEyMyBtZWdhYnl0ZXMuCgogTGVhdmUgZW1wdHkgdG8g
aW5kaWNhdGUgbm8gbGltaXQuCgoNCgUEAQIDBRIElAECCAoNCgUEAQIDARIElAEJFgoNCgUE
AQIDAxIElAEZGgofCgQEAQIEEgSXAQIRGhEgTnVtYmVyIG9mIGdwdXMuCgoNCgUEAQIEBRIE
lwECBwoNCgUEAQIEARIElwEIDAoNCgUEAQIEAxIElwEPEAqHAwoEBAECBRIEoAECHhr4AiBU
aGUgbWF4aW11bSBsYXRlbmN5IHRoYXQgdGhpcyBvcGVyYXRvciBtYXkgdXNlIHRvIHByb2Nl
c3MgYW4gZWxlbWVudC4KCiBJZiBub24gcG9zaXRpdmUsIHRoZW4gYSBzeXN0ZW0gZGVmYXVs
dCB3aWxsIGJlIHVzZWQuCiBPcGVyYXRvciBkZXZlbG9wZXJzIHNob3VsZCBhcnJhbmdlIGZv
ciB0aGUgc3lzdGVtIGNvbXB1dGUgcmVzb3VyY2VzIHRvIGJlCiBhbGlnbmVkIHdpdGggdGhp
cyBsYXRlbmN5IGJ1ZGdldDsgZS5nLiBpZiB5b3Ugd2FudCBhIE1MIG1vZGVsIHRvIHByb2R1
Y2UKIHJlc3VsdHMgd2l0aGluIDUwMG1zLCB0aGVuIHlvdSBzaG91bGQgbWFrZSBzdXJlIHlv
dSByZXF1ZXN0IGVub3VnaAogY3B1L2dwdS9tZW1vcnkgdG8gYWNoaWV2ZSB0aGF0LgoKDQoF
BAECBQUSBKABAgcKDQoFBAECBQESBKABCBkKDQoFBAECBQMSBKABHB0KRAoCBAISBqQBALMB
ARo2IFJlcHJlc2VudHMgYW4gYWN0dWFsIHZhbHVlIG9mIGFuIG9wZXJhdG9yIGF0dHJpYnV0
ZS4KCgsKAwQCARIEpAEIFgoiCgQEAggAEgamAQKyAQMaEiBBdHRyaWJ1dGUgdmFsdWUuCgoN
CgUEAggAARIEpgEIDQoUCgQEAgIAEgSoAQQQGgYgaW50LgoKDQoFBAICAAUSBKgBBAkKDQoF
BAICAAESBKgBCgsKDQoFBAICAAMSBKgBDg8KFgoEBAICARIEqwEEEBoIIGZsb2F0LgoKDQoF
BAICAQUSBKsBBAkKDQoFBAICAQESBKsBCgsKDQoFBAICAQMSBKsBDg8KFQoEBAICAhIErgEE
DxoHIGJvb2wuCgoNCgUEAgICBRIErgEECAoNCgUEAgICARIErgEJCgoNCgUEAgICAxIErgEN
DgoXCgQEAgIDEgSxAQQQGgkgc3RyaW5nLgoKDQoFBAICAwUSBLEBBAkKDQoFBAICAwESBLEB
CgsKDQoFBAICAwMSBLEBDg8K5AEKAgQDEga6AQD6AQEa1QEgRGVmaW5lcyBhbiBBbmFseXpl
ci4KCiBBbiBhbmFseXplciBwcm9jZXNzZXMgZGF0YSBmcm9tIGl0cyBpbnB1dCBzdHJlYW1z
IHVzaW5nIHRoZSBsb2dpYyBkZWZpbmVkIGluCiB0aGUgT3BlcmF0b3IgdGhhdCBpdCByZXBy
ZXNlbnRzLiBPZiBjb3Vyc2UsIGl0IHByb2R1Y2VzIGRhdGEgZm9yIHRoZSBvdXRwdXQKIHN0
cmVhbXMgZGVjbGFyZWQgaW4gdGhlIE9wZXJhdG9yLgoKCwoDBAMBEgS6AQgaCu8FCgQEAwMA
EgbNAQLQAQMa3gUgVGhlIGlucHV0cyB0byB0aGlzIGFuYWx5emVyLgoKIFdlIGFjY2VwdCBp
bnB1dCBuYW1lIHJlZmVyZW5jZXMgb2YgdGhlIGZvbGxvd2luZyBmb3JtOgogPGFuYWx5emVy
LW5hbWU+OjxvdXRwdXQtYXJndW1lbnQtbmFtZT4KCiBFeGFtcGxlOgoKIFN1cHBvc2UgeW91
IGhhZCBhbiBvcGVyYXRvciBuYW1lZCAiU29tZU9wIiB0aGF0IGhhcyAyIG91dHB1dAogYXJn
dW1lbnRzLCB0aGUgZmlyc3Qgb2Ygd2hpY2ggaXMgbmFtZWQgImZvbyIgYW5kIHRoZSBzZWNv
bmQgb2Ygd2hpY2ggaXMKIG5hbWVkICJiYXIiLCBhbmQgYW4gb3BlcmF0b3IgbmFtZWQgIk15
T3AiIHRoYXQgYWNjZXB0cyAyIGlucHV0cy4KCiBBbHNvIHN1cHBvc2UgdGhhdCB0aGVyZSBp
cyBhbiBhbmFseXplciBuYW1lZCAic29tZS1hbmFseXplciIgdGhhdCBpcwogcnVubmluZyAi
U29tZU9wIiBhbmQgYW5vdGhlciBhbmFseXplciBuYW1lZCAibXktYW5hbHl6ZXIiIHJ1bm5p
bmcgIk15T3AiLgoKIFRvIGluZGljYXRlIHRoYXQgIm15LWFuYWx5emVyIiBpcyB0byBjb25z
dW1lICJzb21lLWFuYWx5emVyIidzICJmb28iCiBvdXRwdXQgYXMgaXRzIGZpcnN0IGlucHV0
IGFuZCAic29tZS1hbmFseXplciIncyAiYmFyIiBvdXRwdXQgYXMgaXRzCiBzZWNvbmQgaW5w
dXQsIHlvdSBjYW4gc2V0IHRoaXMgZmllbGQgdG8gdGhlIGZvbGxvd2luZzoKIGlucHV0ID0g
WyJzb21lLWFuYWx5emVyOmZvbyIsICJzb21lLWFuYWx5emVyOmJhciJdCgoNCgUEAwMAARIE
zQEKFQpECgYEAwMAAgASBM8BBBUaNCBUaGUgbmFtZSBvZiB0aGUgc3RyZWFtIGlucHV0IChh
cyBkaXNjdXNzZWQgYWJvdmUpLgoKDwoHBAMDAAIABRIEzwEECgoPCgcEAwMAAgABEgTPAQsQ
Cg8KBwQDAwACAAMSBM8BExQKQAoEBAMDARIG0wEC1gEDGjAgT3B0aW9ucyBhdmFpbGFibGUg
Zm9yIGRlYnVnZ2luZyBwdXJwb3NlcyBvbmx5LgoKDQoFBAMDAQESBNMBChYKKAoGBAMDAQIA
EgTVAQQyGhggRW52aXJvbm1lbnQgdmFyaWFibGVzLgoKDwoHBAMDAQIABhIE1QEEFwoPCgcE
AwMBAgABEgTVARgtCg8KBwQDAwECAAMSBNUBMDEKMQoEBAMDAhIG2QEC3wEDGiEgT3B0aW9u
IHJlbGF0ZWQgdG8gdGhlIG9wZXJhdG9yLgoKDQoFBAMDAgESBNkBChgKJgoGBAMDAgIAEgTb
AQQTGhYgVGFnIG9mIHRoZSBvcGVyYXRvci4KCg8KBwQDAwICAAUSBNsBBAoKDwoHBAMDAgIA
ARIE2wELDgoPCgcEAwMCAgADEgTbARESCj0KBgQDAwICARIE3gEEGBotIFJlZ2lzdHJ5IG9m
IHRoZSBvcGVyYXRvci4gZS5nLiBwdWJsaWMsIGRldi4KCg8KBwQDAwICAQUSBN4BBAoKDwoH
BAMDAgIBARIE3gELEwoPCgcEAwMCAgEDEgTeARYXClUKBAQDAgASBOQBAhYaRyBUaGUgbmFt
ZSBvZiB0aGlzIGFuYWx5emVyLgoKIFRlbnRhdGl2ZWx5IFthLXpdW2EtejAtOV0qKF9bYS16
MC05XSspKi4KCg0KBQQDAgAFEgTkAQIICg0KBQQDAgABEgTkAQkRCg0KBQQDAgADEgTkARQV
CnAKBAQDAgESBOkBAhYaYiBUaGUgbmFtZSBvZiB0aGUgb3BlcmF0b3IgdGhhdCB0aGlzIGFu
YWx5emVyIHJ1bnMuCgogTXVzdCBtYXRjaCB0aGUgbmFtZSBvZiBhIHN1cHBvcnRlZCBvcGVy
YXRvci4KCg0KBQQDAgEFEgTpAQIICg0KBQQDAgEBEgTpAQkRCg0KBQQDAgEDEgTpARQVCh4K
BAQDAgISBOwBAiIaECBJbnB1dCBzdHJlYW1zLgoKDQoFBAMCAgQSBOwBAgoKDQoFBAMCAgYS
BOwBCxYKDQoFBAMCAgESBOwBFx0KDQoFBAMCAgMSBOwBICEK/AEKBAQDAgMSBPMBAiga7QEg
VGhlIGF0dHJpYnV0ZSB2YWx1ZXMgdGhhdCB0aGlzIGFuYWx5emVyIGFwcGxpZXMgdG8gdGhl
IG9wZXJhdG9yLgoKIFN1cHBseSBhIG1hcHBpbmcgYmV0d2VlbiB0aGUgYXR0cmlidXRlIG5h
bWVzIGFuZCB0aGUgYWN0dWFsIHZhbHVlIHlvdSB3aXNoCiB0byBhcHBseS4gSWYgYW4gYXR0
cmlidXRlIG5hbWUgaXMgb21pdHRlZCwgdGhlbiBpdCB3aWxsIHRha2UgYQogcHJlY29uZmln
dXJlZCBkZWZhdWx0IHZhbHVlLgoKDQoFBAMCAwYSBPMBAh0KDQoFBAMCAwESBPMBHiMKDQoF
BAMCAwMSBPMBJicKHgoEBAMCBBIE9gECIRoQIERlYnVnIG9wdGlvbnMuCgoNCgUEAwIEBhIE
9gECDgoNCgUEAwIEARIE9gEPHAoNCgUEAwIEAxIE9gEfIAogCgQEAwIFEgT5AQIlGhIgT3Bl
cmF0b3Igb3B0aW9uLgoKDQoFBAMCBQYSBPkBAhAKDQoFBAMCBQESBPkBESAKDQoFBAMCBQMS
BPkBIyQK1gIKAgQEEgaEAgCHAgEaxwIgRGVmaW5lcyBhIGZ1bGwgYW5hbHlzaXMuCgogVGhp
cyBpcyBhIGRlc2NyaXB0aW9uIG9mIHRoZSBvdmVyYWxsIGxpdmUgYW5hbHl0aWNzIHBpcGVs
aW5lLgogWW91IG1heSB0aGluayBvZiB0aGlzIGFzIGFuIGVkZ2UgbGlzdCByZXByZXNlbnRh
dGlvbiBvZiBhIG11bHRpZ3JhcGguCgogVGhpcyBtYXkgYmUgZGlyZWN0bHkgYXV0aG9yZWQg
YnkgYSBodW1hbiBpbiBwcm90b2J1ZiB0ZXh0Zm9ybWF0LCBvciBpdCBtYXkgYmUKIGdlbmVy
YXRlZCBieSBhIHByb2dyYW1taW5nIEFQSSAocGVyaGFwcyBQeXRob24gb3IgSmF2YVNjcmlw
dCBkZXBlbmRpbmcgb24KIGNvbnRleHQpLgoKCwoDBAQBEgSEAggaCiUKBAQEAgASBIYCAiwa
FyBBbmFseXplciBkZWZpbml0aW9ucy4KCg0KBQQEAgAEEgSGAgIKCg0KBQQEAgAGEgSGAgsd
Cg0KBQQEAgABEgSGAh4nCg0KBQQEAgADEgSGAiorCj0KAgQFEgaKAgCnAgEaLyBNZXNzYWdl
IGRlc2NyaWJpbmcgdGhlIHN0YXR1cyBvZiB0aGUgUHJvY2Vzcy4KCgsKAwQFARIEigIIEQpF
CgQEBQQAEgaMAgKgAgMaNSBTdGF0ZSByZXByZXNlbnRzIHRoZSBydW5uaW5nIHN0YXR1cyBv
ZiB0aGUgUHJvY2Vzcy4KCg0KBQQFBAABEgSMAgcMCicKBgQFBAACABIEjgIEGhoXIFN0YXRl
IGlzIHVuc3BlY2lmaWVkLgoKDwoHBAUEAAIAARIEjgIEFQoPCgcEBQQAAgACEgSOAhgZCmQK
BgQFBAACARIEkgIEFRpUIElOSVRJQUxJWklORyBtZWFucyB0aGUgUHJvY2VzcyBpcyBzY2hl
ZHVsZWQgYnV0IHlldCByZWFkeSB0byBoYW5kbGUKIHJlYWwgdHJhZmZpYy4KCg8KBwQFBAAC
AQESBJICBBAKDwoHBAUEAAIBAhIEkgITFApPCgYEBQQAAgISBJUCBBAaPyBSVU5OSU5HIG1l
YW5zIHRoZSBQcm9jZXNzIGlzIHVwIHJ1bm5pbmcgYW5kIGhhbmRsaW5nIHRyYWZmaWMuCgoP
CgcEBQQAAgIBEgSVAgQLCg8KBwQFBAACAgISBJUCDg8KcwoGBAUEAAIDEgSZAgQSGmMgQ09N
UExFVEVEIG1lYW5zIHRoZSBQcm9jZXNzIGhhcyBjb21wbGV0ZWQgdGhlIHByb2Nlc3Npbmcs
IGVzcGVjaWFsbHkKIGZvciBub24tc3RyZWFtaW5nIHVzZSBjYXNlLgoKDwoHBAUEAAIDARIE
mQIEDQoPCgcEBQQAAgMCEgSZAhARCk0KBgQFBAACBBIEnAIEDxo9IEZBSUxFRCBtZWFucyB0
aGUgUHJvY2VzcyBmYWlsZWQgdG8gY29tcGxldGUgdGhlIHByb2Nlc3NpbmcuCgoPCgcEBQQA
AgQBEgScAgQKCg8KBwQFBAACBAISBJwCDQ4KTwoGBAUEAAIFEgSfAgQQGj8gUEVORElORyBt
ZWFucyB0aGUgUHJvY2VzcyBpcyBjcmVhdGVkIGJ1dCB5ZXQgdG8gYmUgc2NoZWR1bGVkLgoK
DwoHBAUEAAIFARIEnwIECwoPCgcEBQQAAgUCEgSfAg4PCikKBAQFAgASBKMCAhIaGyBUaGUg
c3RhdGUgb2YgdGhlIFByb2Nlc3MuCgoNCgUEBQIABhIEowICBwoNCgUEBQIAARIEowIIDQoN
CgUEBQIAAxIEowIQEQoxCgQEBQIBEgSmAgIUGiMgVGhlIHJlYXNvbiBvZiBiZWNvbWluZyB0
aGUgc3RhdGUuCgoNCgUEBQIBBRIEpgICCAoNCgUEBQIBARIEpgIJDwoNCgUEBQIBAxIEpgIS
E2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::Lva::OperatorDefinition ===
    # Fields for OperatorDefinition
    # Field: operator Type: 9 ()
    # Field: input_args Type: 11 (.google.cloud.visionai.v1.OperatorDefinition.ArgumentDefinition)
    # Field: output_args Type: 11 (.google.cloud.visionai.v1.OperatorDefinition.ArgumentDefinition)
    # Field: attributes Type: 11 (.google.cloud.visionai.v1.OperatorDefinition.AttributeDefinition)
    # Field: resources Type: 11 (.google.cloud.visionai.v1.ResourceSpecification)
    # Field: short_description Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::Lva::ResourceSpecification ===
    # Fields for ResourceSpecification
    # Field: cpu Type: 9 ()
    # Field: cpu_limits Type: 9 ()
    # Field: memory Type: 9 ()
    # Field: memory_limits Type: 9 ()
    # Field: gpus Type: 5 ()
    # Field: latency_budget_ms Type: 5 ()

# === Message: Google::Cloud::Visionai::V1::Lva::AttributeValue ===
    # Fields for AttributeValue
    # Field: i Type: 3 ()
    # Field: f Type: 2 ()
    # Field: b Type: 8 ()
    # Field: s Type: 12 ()

# === Message: Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition ===
    # Fields for AnalyzerDefinition
    # Field: analyzer Type: 9 ()
    # Field: operator Type: 9 ()
    # Field: inputs Type: 11 (.google.cloud.visionai.v1.AnalyzerDefinition.StreamInput)
    # Field: attrs Type: 11 (.google.cloud.visionai.v1.AnalyzerDefinition.AttrsEntry)
    # Field: debug_options Type: 11 (.google.cloud.visionai.v1.AnalyzerDefinition.DebugOptions)
    # Field: operator_option Type: 11 (.google.cloud.visionai.v1.AnalyzerDefinition.OperatorOption)

# === Message: Google::Cloud::Visionai::V1::Lva::AnalysisDefinition ===
    # Fields for AnalysisDefinition
    # Field: analyzers Type: 11 (.google.cloud.visionai.v1.AnalyzerDefinition)

# === Message: Google::Cloud::Visionai::V1::Lva::RunStatus ===
    # Fields for RunStatus
    # Field: state Type: 14 (.google.cloud.visionai.v1.RunStatus.State)
    # Field: reason Type: 9 ()

# Enum: RunStatus::State
our $RunStatus_STATE_UNSPECIFIED = 0;
our $RunStatus_INITIALIZING = 1;
our $RunStatus_RUNNING = 2;
our $RunStatus_COMPLETED = 3;
our $RunStatus_FAILED = 4;
our $RunStatus_PENDING = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::Lva - Compiled Protocol Buffers messages for google/cloud/visionai/v1/lva.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::Lva;

    my $msg = Google::Cloud::Visionai::V1::Lva::OperatorDefinition->new({
        operator => $operator,
        input_args => $input_args,
        output_args => $output_args,
        attributes => $attributes,
    });

    # Read or update a field
    my $val = $msg->operator();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::Lva::OperatorDefinition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/lva.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::Lva::OperatorDefinition

Defines the interface of an Operator.

Arguments to an operator are input/output streams that are getting
processesed/returned while attributes are fixed configuration parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operator() >> / C<< $msg->operator($value) >>

Type: C<String>

The name of this operator.

Tentatively [A-Z][a-zA-Z0-9]*, e.g., BboxCounter, PetDetector,
PetDetector1.

=item * C<< $msg->input_args() >> / C<< $msg->input_args($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::OperatorDefinition::ArgumentDefinition>)

Declares input arguments.

=item * C<< $msg->output_args() >> / C<< $msg->output_args($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::OperatorDefinition::ArgumentDefinition>)

Declares output arguments.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::OperatorDefinition::AttributeDefinition>)

Declares the attributes.

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::ResourceSpecification>)

The resources for running the operator.

=item * C<< $msg->short_description() >> / C<< $msg->short_description($value) >>

Type: C<String>

Short description of the operator.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Full description of the operator.

=back

=head2 Google::Cloud::Visionai::V1::Lva::ResourceSpecification

ResourceSpec collects a set of resources that can
be used to specify requests and requirements.

Note: Highly experimental as this can be runtime dependent.
Can use the "extras" field to experiment first before trying
to abstract it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpu() >> / C<< $msg->cpu($value) >>

Type: C<String>

CPU specification.

Examples:
"100m", "0.5", "1", "2", ... correspond to
0.1, half, 1, or 2 cpus.

Leave empty to let the system decide.

Note that this does *not* determine the cpu vender/make,
or its underlying clock speed and specific SIMD features.
It is only the amount time it requires in timeslicing.

=item * C<< $msg->cpu_limits() >> / C<< $msg->cpu_limits($value) >>

Type: C<String>

CPU limit.

Examples:
"100m", "0.5", "1", "2", ... correspond to
0.1, half, 1, or 2 cpus.

Leave empty to indicate no limit.

=item * C<< $msg->memory() >> / C<< $msg->memory($value) >>

Type: C<String>

Memory specification (in bytes).

Examples:
"128974848", "129e6", "129M", "123Mi", ... correspond to
128974848 bytes, 129000000 bytes, 129 mebibytes, 123 megabytes.

Leave empty to let the system decide.

=item * C<< $msg->memory_limits() >> / C<< $msg->memory_limits($value) >>

Type: C<String>

Memory usage limits.

Examples:
"128974848", "129e6", "129M", "123Mi", ... correspond to
128974848 bytes, 129000000 bytes, 129 mebibytes, 123 megabytes.

Leave empty to indicate no limit.

=item * C<< $msg->gpus() >> / C<< $msg->gpus($value) >>

Type: C<Int32>

Number of gpus.

=item * C<< $msg->latency_budget_ms() >> / C<< $msg->latency_budget_ms($value) >>

Type: C<Int32>

The maximum latency that this operator may use to process an element.

If non positive, then a system default will be used.
Operator developers should arrange for the system compute resources to be
aligned with this latency budget; e.g. if you want a ML model to produce
results within 500ms, then you should make sure you request enough
cpu/gpu/memory to achieve that.

=back

=head2 Google::Cloud::Visionai::V1::Lva::AttributeValue

Represents an actual value of an operator attribute.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->i() >> / C<< $msg->i($value) >>

Type: C<Int64>

int.

=item * C<< $msg->f() >> / C<< $msg->f($value) >>

Type: C<Float>

float.

=item * C<< $msg->b() >> / C<< $msg->b($value) >>

Type: C<Bool>

bool.

=item * C<< $msg->s() >> / C<< $msg->s($value) >>

Type: C<Bytes>

string.

=back

=head2 Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition

Defines an Analyzer.

An analyzer processes data from its input streams using the logic defined in
the Operator that it represents. Of course, it produces data for the output
streams declared in the Operator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analyzer() >> / C<< $msg->analyzer($value) >>

Type: C<String>

The name of this analyzer.

Tentatively [a-z][a-z0-9]*(_[a-z0-9]+)*.

=item * C<< $msg->operator() >> / C<< $msg->operator($value) >>

Type: C<String>

The name of the operator that this analyzer runs.

Must match the name of a supported operator.

=item * C<< $msg->inputs() >> / C<< $msg->inputs($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::StreamInput>)

Input streams.

=item * C<< $msg->attrs() >> / C<< $msg->attrs($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::AttrsEntry>)

The attribute values that this analyzer applies to the operator.

Supply a mapping between the attribute names and the actual value you wish
to apply. If an attribute name is omitted, then it will take a
preconfigured default value.

=item * C<< $msg->debug_options() >> / C<< $msg->debug_options($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions>)

Debug options.

=item * C<< $msg->operator_option() >> / C<< $msg->operator_option($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::OperatorOption>)

Operator option.

=back

=head2 Google::Cloud::Visionai::V1::Lva::AnalysisDefinition

Defines a full analysis.

This is a description of the overall live analytics pipeline.
You may think of this as an edge list representation of a multigraph.

This may be directly authored by a human in protobuf textformat, or it may be
generated by a programming API (perhaps Python or JavaScript depending on
context).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analyzers() >> / C<< $msg->analyzers($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition>)

Analyzer definitions.

=back

=head2 Google::Cloud::Visionai::V1::Lva::RunStatus

Message describing the status of the Process.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1::RunStatus::State>)

The state of the Process.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

The reason of becoming the state.

=back

=head3 Enum: RunStatus::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<INITIALIZING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<COMPLETED> => C<3>

=item * C<FAILED> => C<4>

=item * C<PENDING> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::Lva::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
