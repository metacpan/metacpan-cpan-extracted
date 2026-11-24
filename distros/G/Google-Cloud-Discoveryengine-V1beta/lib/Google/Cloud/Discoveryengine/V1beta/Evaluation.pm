package Google::Cloud::Discoveryengine::V1beta::Evaluation;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::SearchService };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9ldmFsdWF0aW9uLnByb3Rv
EiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo4Z29vZ2xlL2Ns
b3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvc2VhcmNoX3NlcnZpY2UucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIucI
CgpFdmFsdWF0aW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJsCg9ldmFsdWF0aW9uX3Nw
ZWMYAiABKAsyPi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0
aW9uLkV2YWx1YXRpb25TcGVjQgPgQQJSDmV2YWx1YXRpb25TcGVjEmEKD3F1YWxpdHlfbWV0
cmljcxgDIAEoCzIzLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlF1YWxp
dHlNZXRyaWNzQgPgQQNSDnF1YWxpdHlNZXRyaWNzElAKBXN0YXRlGAQgASgOMjUuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRXZhbHVhdGlvbi5TdGF0ZUID4EEDUgVz
dGF0ZRItCgVlcnJvchgFIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzQgPgQQNSBWVycm9yEkAK
C2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpj
cmVhdGVUaW1lEjoKCGVuZF90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgdlbmRUaW1lEjwKDWVycm9yX3NhbXBsZXMYCCADKAsyEi5nb29nbGUucnBjLlN0
YXR1c0ID4EEDUgxlcnJvclNhbXBsZXMa6gIKDkV2YWx1YXRpb25TcGVjEmAKDnNlYXJjaF9y
ZXF1ZXN0GAIgASgLMjIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2Vh
cmNoUmVxdWVzdEID4EECSABSDXNlYXJjaFJlcXVlc3QSdgoOcXVlcnlfc2V0X3NwZWMYASAB
KAsySy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0aW9uLkV2
YWx1YXRpb25TcGVjLlF1ZXJ5U2V0U3BlY0ID4EEBUgxxdWVyeVNldFNwZWMabwoMUXVlcnlT
ZXRTcGVjEl8KEHNhbXBsZV9xdWVyeV9zZXQYASABKAlCNeBBAfpBLwotZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29tL1NhbXBsZVF1ZXJ5U2V0Ug5zYW1wbGVRdWVyeVNldEINCgtz
ZWFyY2hfc3BlYyJTCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB1BFTkRJTkcQ
ARILCgdSVU5OSU5HEAISDQoJU1VDQ0VFREVEEAMSCgoGRkFJTEVEEAQ6cOpBbQopZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0V2YWx1YXRpb24SQHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ldmFsdWF0aW9ucy97ZXZhbHVhdGlvbn0i1wQKDlF1
YWxpdHlNZXRyaWNzEl4KCmRvY19yZWNhbGwYASABKAsyPy5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5RdWFsaXR5TWV0cmljcy5Ub3BrTWV0cmljc1IJZG9jUmVjYWxs
EmQKDWRvY19wcmVjaXNpb24YAiABKAsyPy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5RdWFsaXR5TWV0cmljcy5Ub3BrTWV0cmljc1IMZG9jUHJlY2lzaW9uEloKCGRv
Y19uZGNnGAMgASgLMj8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUXVh
bGl0eU1ldHJpY3MuVG9wa01ldHJpY3NSB2RvY05kY2cSYAoLcGFnZV9yZWNhbGwYBCABKAsy
Py5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5RdWFsaXR5TWV0cmljcy5U
b3BrTWV0cmljc1IKcGFnZVJlY2FsbBJcCglwYWdlX25kY2cYBSABKAsyPy5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5RdWFsaXR5TWV0cmljcy5Ub3BrTWV0cmljc1II
cGFnZU5kY2caYwoLVG9wa01ldHJpY3MSEwoFdG9wXzEYASABKAFSBHRvcDESEwoFdG9wXzMY
AiABKAFSBHRvcDMSEwoFdG9wXzUYAyABKAFSBHRvcDUSFQoGdG9wXzEwGAQgASgBUgV0b3Ax
MEKWAgonY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQg9FdmFsdWF0
aW9uUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFi
ZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5H
SU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xv
dWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVu
Z2luZTo6VjFiZXRhStJACgcSBQ4A5gEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
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
bnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABCCgkKAgMD
EgMVACkKCQoCAwQSAxYAIQoICgEIEgMYAEAKCQoCCCUSAxgAQAoICgEIEgMZAGgKCQoCCAsS
AxkAaAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADAKCQoCCAgSAxsAMAoICgEIEgMc
AEAKCQoCCAESAxwAQAoICgEIEgMdAC0KCQoCCCQSAx0ALQoICgEIEgMeAEAKCQoCCCkSAx4A
QAoICgEIEgMfAD8KCQoCCC0SAx8APwqbAQoCBAASBSMAiQEBGo0BIEFuIGV2YWx1YXRpb24g
aXMgYSBzaW5nbGUgZXhlY3V0aW9uIChvciBydW4pIG9mIGFuIGV2YWx1YXRpb24gcHJvY2Vz
cy4gSXQKIGVuY2Fwc3VsYXRlcyB0aGUgc3RhdGUgb2YgdGhlIGV2YWx1YXRpb24gYW5kIHRo
ZSByZXN1bHRpbmcgZGF0YS4KCgoKAwQAARIDIwgSCgsKAwQABxIEJAInBAoNCgUEAAedCBIE
JAInBAo+CgQEAAMAEgQqAkwDGjAgRGVzY3JpYmVzIHRoZSBzcGVjaWZpY2F0aW9uIG9mIHRo
ZSBldmFsdWF0aW9uLgoKDAoFBAADAAESAyoKGAo/CgYEAAMAAwASBCwENwUaLyBEZXNjcmli
ZXMgdGhlIHNwZWNpZmljYXRpb24gb2YgdGhlIHF1ZXJ5IHNldC4KCg4KBwQAAwADAAESAywM
GAr6AQoIBAADAAMAAgASBDEGNgga5wEgT3B0aW9uYWwuIFRoZSBmdWxsIHJlc291cmNlIG5h
bWUgb2YgdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XQogdXNlZCBmb3IgdGhlIGV2YWx1YXRpb24sIGlu
IHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vc2FtcGxlUXVlcnlTZXRzL3tzYW1wbGVRdWVyeVNldH1gLgoKEAoJBAADAAMAAgAFEgMx
BgwKEAoJBAADAAMAAgABEgMxDR0KEAoJBAADAAMAAgADEgMxICEKEQoJBAADAAMAAgAIEgQx
IjYHChMKDAQAAwADAAIACJwIABIDMgguChMKCwQAAwADAAIACJ8IEgQzCDUJCisKBgQAAwAI
ABIEOgRIBRobIFRoZSBzZWFyY2ggc3BlY2lmaWNhdGlvbi4KCg4KBwQAAwAIAAESAzoKFQq1
BwoGBAADAAIAEgNHBlAapQcgUmVxdWlyZWQuIFRoZSBzZWFyY2ggcmVxdWVzdCB0aGF0IGlz
IHVzZWQgdG8gcGVyZm9ybSB0aGUgZXZhbHVhdGlvbi4KCiBPbmx5IHRoZSBmb2xsb3dpbmcg
ZmllbGRzIHdpdGhpbiBTZWFyY2hSZXF1ZXN0IGFyZSBzdXBwb3J0ZWQ7IGlmIGFueQogb3Ro
ZXIgZmllbGRzIGFyZSBwcm92aWRlZCwgYW4gVU5TVVBQT1JURUQgZXJyb3Igd2lsbCBiZSBy
ZXR1cm5lZDoKCiAqIFtTZWFyY2hSZXF1ZXN0LnNlcnZpbmdfY29uZmlnXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hSZXF1ZXN0LnNlcnZpbmdfY29uZmln
XQogKiBbU2VhcmNoUmVxdWVzdC5icmFuY2hdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNlYXJjaFJlcXVlc3QuYnJhbmNoXQogKiBbU2VhcmNoUmVxdWVzdC5jYW5v
bmljYWxfZmlsdGVyXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFy
Y2hSZXF1ZXN0LmNhbm9uaWNhbF9maWx0ZXJdCiAqIFtTZWFyY2hSZXF1ZXN0LnF1ZXJ5X2V4
cGFuc2lvbl9zcGVjXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFy
Y2hSZXF1ZXN0LnF1ZXJ5X2V4cGFuc2lvbl9zcGVjXQogKiBbU2VhcmNoUmVxdWVzdC5zcGVs
bF9jb3JyZWN0aW9uX3NwZWNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlNlYXJjaFJlcXVlc3Quc3BlbGxfY29ycmVjdGlvbl9zcGVjXQogKiBbU2VhcmNoUmVxdWVz
dC5jb250ZW50X3NlYXJjaF9zcGVjXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5TZWFyY2hSZXF1ZXN0LmNvbnRlbnRfc2VhcmNoX3NwZWNdCiAqIFtTZWFyY2hSZXF1
ZXN0LnVzZXJfcHNldWRvX2lkXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TZWFyY2hSZXF1ZXN0LnVzZXJfcHNldWRvX2lkXQoKDgoHBAADAAIABhIDRwYTCg4KBwQA
AwACAAESA0cUIgoOCgcEAAMAAgADEgNHJSYKDgoHBAADAAIACBIDRydPChEKCgQAAwACAAic
CAASA0coTgo+CgYEAAMAAgESA0sETRovIE9wdGlvbmFsLiBUaGUgc3BlY2lmaWNhdGlvbiBv
ZiB0aGUgcXVlcnkgc2V0LgoKDgoHBAADAAIBBhIDSwQQCg4KBwQAAwACAQESA0sRHwoOCgcE
AAMAAgEDEgNLIiMKDgoHBAADAAIBCBIDSyRMChEKCgQAAwACAQicCAASA0slSwo1CgQEAAQA
EgRPAl4DGicgRGVzY3JpYmVzIHRoZSBzdGF0ZSBvZiBhbiBldmFsdWF0aW9uLgoKDAoFBAAE
AAESA08HDAovCgYEAAQAAgASA1EEGhogIFRoZSBldmFsdWF0aW9uIGlzIHVuc3BlY2lmaWVk
LgoKDgoHBAAEAAIAARIDUQQVCg4KBwQABAACAAISA1EYGQpACgYEAAQAAgESA1QEEBoxIFRo
ZSBzZXJ2aWNlIGlzIHByZXBhcmluZyB0byBydW4gdGhlIGV2YWx1YXRpb24uCgoOCgcEAAQA
AgEBEgNUBAsKDgoHBAAEAAIBAhIDVA4PCi8KBgQABAACAhIDVwQQGiAgVGhlIGV2YWx1YXRp
b24gaXMgaW4gcHJvZ3Jlc3MuCgoOCgcEAAQAAgIBEgNXBAsKDgoHBAAEAAICAhIDVw4PCjcK
BgQABAACAxIDWgQSGiggVGhlIGV2YWx1YXRpb24gY29tcGxldGVkIHN1Y2Nlc3NmdWxseS4K
Cg4KBwQABAACAwESA1oEDQoOCgcEAAQAAgMCEgNaEBEKJwoGBAAEAAIEEgNdBA8aGCBUaGUg
ZXZhbHVhdGlvbiBmYWlsZWQuCgoOCgcEAAQAAgQBEgNdBAoKDgoHBAAEAAIEAhIDXQ0OCqMC
CgQEAAIAEgNmAj0alQIgSWRlbnRpZmllci4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0
aGUKIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5F
dmFsdWF0aW9uXSwgaW4gdGhlIGZvcm1hdAogb2YgYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9ldmFsdWF0aW9ucy97ZXZhbHVhdGlvbn1gLgoKIFRoaXMgZmll
bGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQg
b2YgMTAyNAogY2hhcmFjdGVycy4KCgwKBQQAAgAFEgNmAggKDAoFBAACAAESA2YJDQoMCgUE
AAIAAxIDZhARCgwKBQQAAgAIEgNmEjwKDwoIBAACAAicCAASA2YTOwo9CgQEAAIBEgNpAk4a
MCBSZXF1aXJlZC4gVGhlIHNwZWNpZmljYXRpb24gb2YgdGhlIGV2YWx1YXRpb24uCgoMCgUE
AAIBBhIDaQIQCgwKBQQAAgEBEgNpESAKDAoFBAACAQMSA2kjJAoMCgUEAAIBCBIDaSVNCg8K
CAQAAgEInAgAEgNpJkwKowIKBAQAAgISBHACcTIalAIgT3V0cHV0IG9ubHkuIFRoZSBtZXRy
aWNzIHByb2R1Y2VkIGJ5IHRoZSBldmFsdWF0aW9uLCBhdmVyYWdlZCBhY3Jvc3MgYWxsCiBb
U2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBs
ZVF1ZXJ5XXMgaW4gdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLlNhbXBsZVF1ZXJ5U2V0XS4KCiBPbmx5IHBvcHVsYXRlZCB3aGVu
IHRoZSBldmFsdWF0aW9uJ3Mgc3RhdGUgaXMgU1VDQ0VFREVELgoKDAoFBAACAgYSA3ACEAoM
CgUEAAICARIDcBEgCgwKBQQAAgIDEgNwIyQKDAoFBAACAggSA3EGMQoPCggEAAICCJwIABID
cQcwCjgKBAQAAgMSA3QCPhorIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIGV2YWx1
YXRpb24uCgoMCgUEAAIDBhIDdAIHCgwKBQQAAgMBEgN0CA0KDAoFBAACAwMSA3QQEQoMCgUE
AAIDCBIDdBI9Cg8KCAQAAgMInAgAEgN0EzwKfQoEBAACBBIDeAJKGnAgT3V0cHV0IG9ubHku
IFRoZSBlcnJvciB0aGF0IG9jY3VycmVkIGR1cmluZyBldmFsdWF0aW9uLiBPbmx5IHBvcHVs
YXRlZCB3aGVuCiB0aGUgZXZhbHVhdGlvbidzIHN0YXRlIGlzIEZBSUxFRC4KCgwKBQQAAgQG
EgN4AhMKDAoFBAACBAESA3gUGQoMCgUEAAIEAxIDeBwdCgwKBQQAAgQIEgN4HkkKDwoIBAAC
BAicCAASA3gfSAp5CgQEAAIFEgR9An4yGmsgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB0aGUK
IFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFs
dWF0aW9uXSB3YXMgY3JlYXRlZAogYXQuCgoMCgUEAAIFBhIDfQIbCgwKBQQAAgUBEgN9HCcK
DAoFBAACBQMSA30qKwoMCgUEAAIFCBIDfgYxCg8KCAQAAgUInAgAEgN+BzAKfQoEBAACBhIG
gwEChAEyGm0gT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB0aGUKIFtFdmFsdWF0aW9uXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5FdmFsdWF0aW9uXSB3YXMgY29tcGxl
dGVkCiBhdC4KCg0KBQQAAgYGEgSDAQIbCg0KBQQAAgYBEgSDARwkCg0KBQQAAgYDEgSDASco
Cg0KBQQAAgYIEgSEAQYxChAKCAQAAgYInAgAEgSEAQcwClsKBAQAAgcSBocBAogBMhpLIE91
dHB1dCBvbmx5LiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vz
c2luZyB0aGUgcmVxdWVzdC4KCg0KBQQAAgcEEgSHAQIKCg0KBQQAAgcGEgSHAQscCg0KBQQA
AgcBEgSHAR0qCg0KBQQAAgcDEgSHAS0uCg0KBQQAAgcIEgSIAQYxChAKCAQAAgcInAgAEgSI
AQcwCkEKAgQBEgaMAQDmAQEaMyBEZXNjcmliZXMgdGhlIG1ldHJpY3MgcHJvZHVjZWQgYnkg
dGhlIGV2YWx1YXRpb24uCgoLCgMEAQESBIwBCBYKRAoEBAEDABIGjgECmgEDGjQgU3RvcmVz
IHRoZSBtZXRyaWMgdmFsdWVzIGF0IHNwZWNpZmljIHRvcC1rIGxldmVscy4KCg0KBQQBAwAB
EgSOAQoVCiIKBgQBAwACABIEkAEEFRoSIFRoZSB0b3AtMSB2YWx1ZS4KCg8KBwQBAwACAAUS
BJABBAoKDwoHBAEDAAIAARIEkAELEAoPCgcEAQMAAgADEgSQARMUCiIKBgQBAwACARIEkwEE
FRoSIFRoZSB0b3AtMyB2YWx1ZS4KCg8KBwQBAwACAQUSBJMBBAoKDwoHBAEDAAIBARIEkwEL
EAoPCgcEAQMAAgEDEgSTARMUCiIKBgQBAwACAhIElgEEFRoSIFRoZSB0b3AtNSB2YWx1ZS4K
Cg8KBwQBAwACAgUSBJYBBAoKDwoHBAEDAAICARIElgELEAoPCgcEAQMAAgIDEgSWARMUCiMK
BgQBAwACAxIEmQEEFhoTIFRoZSB0b3AtMTAgdmFsdWUuCgoPCgcEAQMAAgMFEgSZAQQKCg8K
BwQBAwACAwESBJkBCxEKDwoHBAEDAAIDAxIEmQEUFQrYAgoEBAECABIEpQECHRrJAiBSZWNh
bGwgcGVyIGRvY3VtZW50LCBhdCB2YXJpb3VzIHRvcC1rIGN1dG9mZiBsZXZlbHMuCgogUmVj
YWxsIGlzIHRoZSBmcmFjdGlvbiBvZiByZWxldmFudCBkb2N1bWVudHMgcmV0cmlldmVkIG91
dCBvZiBhbGwKIHJlbGV2YW50IGRvY3VtZW50cy4KCiBFeGFtcGxlICh0b3AtNSk6CiAgKiBG
b3IgYSBzaW5nbGUKICBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNhbXBsZVF1ZXJ5XSwgSWYgMyBvdXQKICBvZiA1IHJlbGV2YW50IGRvY3Vt
ZW50cyBhcmUgcmV0cmlldmVkIGluIHRoZSB0b3AtNSwgcmVjYWxsQDUgPSAzLzUgPSAwLjYK
Cg0KBQQBAgAGEgSlAQINCg0KBQQBAgABEgSlAQ4YCg0KBQQBAgADEgSlARscCs0CCgQEAQIB
EgSwAQIgGr4CIFByZWNpc2lvbiBwZXIgZG9jdW1lbnQsIGF0IHZhcmlvdXMgdG9wLWsgY3V0
b2ZmIGxldmVscy4KCiBQcmVjaXNpb24gaXMgdGhlIGZyYWN0aW9uIG9mIHJldHJpZXZlZCBk
b2N1bWVudHMgdGhhdCBhcmUgcmVsZXZhbnQuCgogRXhhbXBsZSAodG9wLTUpOgogICogRm9y
IGEgc2luZ2xlCiAgW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5TYW1wbGVRdWVyeV0sIElmIDQgb3V0CiAgb2YgNSByZXRyaWV2ZWQgZG9jdW1l
bnRzIGluIHRoZSB0b3AtNSBhcmUgcmVsZXZhbnQsIHByZWNpc2lvbkA1ID0gNC81ID0KICAw
LjgKCg0KBQQBAgEGEgSwAQINCg0KBQQBAgEBEgSwAQ4bCg0KBQQBAgEDEgSwAR4fCtwFCgQE
AQICEgTFAQIbGs0FIE5vcm1hbGl6ZWQgZGlzY291bnRlZCBjdW11bGF0aXZlIGdhaW4gKE5E
Q0cpIHBlciBkb2N1bWVudCwgYXQgdmFyaW91cyB0b3AtawogY3V0b2ZmIGxldmVscy4KCiBO
RENHIG1lYXN1cmVzIHRoZSByYW5raW5nIHF1YWxpdHksIGdpdmluZyBoaWdoZXIgcmVsZXZh
bmNlIHRvIHRvcAogcmVzdWx0cy4KCiBFeGFtcGxlICh0b3AtMyk6CiAgU3VwcG9zZSBbU2Ft
cGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNhbXBsZVF1
ZXJ5XQogIHdpdGggdGhyZWUgcmV0cmlldmVkIGRvY3VtZW50cyAoRDEsIEQyLCBEMykgYW5k
IGJpbmFyeSByZWxldmFuY2UKICBqdWRnZW1lbnRzICgxIGZvciByZWxldmFudCwgMCBmb3Ig
bm90IHJlbGV2YW50KToKCiAgIFJldHJpZXZlZDogIFtEMyAoMCksIEQxICgxKSwgRDIgKDEp
XQogICBJZGVhbDogICAgICBbRDEgKDEpLCBEMiAoMSksIEQzICgwKV0KCiAgIENhbGN1bGF0
ZSBORENHQDMgZm9yIGVhY2gKICAgW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV06CiAgICAqIERDR0AzOiAwL2xvZzIoMSsx
KSArIDEvbG9nMigyKzEpICsgMS9sb2cyKDMrMSkgPSAxLjEzCiAgICAqIElkZWFsIERDR0Az
OiAxL2xvZzIoMSsxKSArIDEvbG9nMigyKzEpICsgMC9sb2cyKDMrMSkgPSAxLjYzCiAgICAq
IE5EQ0dAMzogMS4xMy8xLjYzID0gMC42OTMKCg0KBQQBAgIGEgTFAQINCg0KBQQBAgIBEgTF
AQ4WCg0KBQQBAgIDEgTFARkaCsgCCgQEAQIDEgTQAQIeGrkCIFJlY2FsbCBwZXIgcGFnZSwg
YXQgdmFyaW91cyB0b3AtayBjdXRvZmYgbGV2ZWxzLgoKIFJlY2FsbCBpcyB0aGUgZnJhY3Rp
b24gb2YgcmVsZXZhbnQgcGFnZXMgcmV0cmlldmVkIG91dCBvZiBhbGwgcmVsZXZhbnQKIHBh
Z2VzLgoKIEV4YW1wbGUgKHRvcC01KToKICAqIEZvciBhIHNpbmdsZQogIFtTYW1wbGVRdWVy
eV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2FtcGxlUXVlcnldLCBp
ZiAzIG91dAogIG9mIDUgcmVsZXZhbnQgcGFnZXMgYXJlIHJldHJpZXZlZCBpbiB0aGUgdG9w
LTUsIHJlY2FsbEA1ID0gMy81ID0gMC42CgoNCgUEAQIDBhIE0AECDQoNCgUEAQIDARIE0AEO
GQoNCgUEAQIDAxIE0AEcHQrPBQoEBAECBBIE5QECHBrABSBOb3JtYWxpemVkIGRpc2NvdW50
ZWQgY3VtdWxhdGl2ZSBnYWluIChORENHKSBwZXIgcGFnZSwgYXQgdmFyaW91cyB0b3Atawog
Y3V0b2ZmIGxldmVscy4KCiBORENHIG1lYXN1cmVzIHRoZSByYW5raW5nIHF1YWxpdHksIGdp
dmluZyBoaWdoZXIgcmVsZXZhbmNlIHRvIHRvcAogcmVzdWx0cy4KCiBFeGFtcGxlICh0b3At
Myk6CiAgU3VwcG9zZSBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlNhbXBsZVF1ZXJ5XQogIHdpdGggdGhyZWUgcmV0cmlldmVkIHBhZ2VzIChQ
MSwgUDIsIFAzKSBhbmQgYmluYXJ5IHJlbGV2YW5jZSBqdWRnZW1lbnRzICgxCiAgZm9yIHJl
bGV2YW50LCAwIGZvciBub3QgcmVsZXZhbnQpOgoKICAgUmV0cmlldmVkOiAgW1AzICgwKSwg
UDEgKDEpLCBQMiAoMSldCiAgIElkZWFsOiAgICAgIFtQMSAoMSksIFAyICgxKSwgUDMgKDAp
XQoKICAgQ2FsY3VsYXRlIE5EQ0dAMyBmb3IKICAgW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TYW1wbGVRdWVyeV06CiAgICAqIERDR0AzOiAw
L2xvZzIoMSsxKSArIDEvbG9nMigyKzEpICsgMS9sb2cyKDMrMSkgPSAxLjEzCiAgICAqIElk
ZWFsIERDR0AzOiAxL2xvZzIoMSsxKSArIDEvbG9nMigyKzEpICsgMC9sb2cyKDMrMSkgPSAx
LjYzCiAgICAqIE5EQ0dAMzogMS4xMy8xLjYzID0gMC42OTMKCg0KBQQBAgQGEgTlAQINCg0K
BQQBAgQBEgTlAQ4XCg0KBQQBAgQDEgTlARobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation ===
    # Fields for Evaluation
    # Field: name Type: 9 ()
    # Field: evaluation_spec Type: 11 (.google.cloud.discoveryengine.v1beta.Evaluation.EvaluationSpec)
    # Field: quality_metrics Type: 11 (.google.cloud.discoveryengine.v1beta.QualityMetrics)
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1beta.Evaluation.State)
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: error_samples Type: 11 (.google.rpc.Status)

# Enum: Evaluation::State
our $Evaluation_STATE_UNSPECIFIED = 0;
our $Evaluation_PENDING = 1;
our $Evaluation_RUNNING = 2;
our $Evaluation_SUCCEEDED = 3;
our $Evaluation_FAILED = 4;

# === Message: Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics ===
    # Fields for QualityMetrics
    # Field: doc_recall Type: 11 (.google.cloud.discoveryengine.v1beta.QualityMetrics.TopkMetrics)
    # Field: doc_precision Type: 11 (.google.cloud.discoveryengine.v1beta.QualityMetrics.TopkMetrics)
    # Field: doc_ndcg Type: 11 (.google.cloud.discoveryengine.v1beta.QualityMetrics.TopkMetrics)
    # Field: page_recall Type: 11 (.google.cloud.discoveryengine.v1beta.QualityMetrics.TopkMetrics)
    # Field: page_ndcg Type: 11 (.google.cloud.discoveryengine.v1beta.QualityMetrics.TopkMetrics)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Evaluation - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/evaluation.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Evaluation;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation->new({
        name => $name,
        evaluation_spec => $evaluation_spec,
        quality_metrics => $quality_metrics,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/evaluation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation

An evaluation is a single execution (or run) of an evaluation process. It
encapsulates the state of the evaluation and the resulting data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The full resource name of the
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation], in the format
of `projects/{project}/locations/{location}/evaluations/{evaluation}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->evaluation_spec() >> / C<< $msg->evaluation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation::EvaluationSpec>)

Required. The specification of the evaluation.

=item * C<< $msg->quality_metrics() >> / C<< $msg->quality_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics>)

Output only. The metrics produced by the evaluation, averaged across all
[SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]s in the
[SampleQuerySet][google.cloud.discoveryengine.v1beta.SampleQuerySet].

Only populated when the evaluation's state is SUCCEEDED.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::State>)

Output only. The state of the evaluation.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The error that occurred during evaluation. Only populated when
the evaluation's state is FAILED.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation] was created
at.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[Evaluation][google.cloud.discoveryengine.v1beta.Evaluation] was completed
at.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. A sample of errors encountered while processing the request.

=back

=head3 Enum: Evaluation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics

Describes the metrics produced by the evaluation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->doc_recall() >> / C<< $msg->doc_recall($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics::TopkMetrics>)

Recall per document, at various top-k cutoff levels.

Recall is the fraction of relevant documents retrieved out of all
relevant documents.

Example (top-5):
 * For a single
 [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], If 3 out
 of 5 relevant documents are retrieved in the top-5, recall@5 = 3/5 = 0.6

=item * C<< $msg->doc_precision() >> / C<< $msg->doc_precision($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics::TopkMetrics>)

Precision per document, at various top-k cutoff levels.

Precision is the fraction of retrieved documents that are relevant.

Example (top-5):
 * For a single
 [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], If 4 out
 of 5 retrieved documents in the top-5 are relevant, precision@5 = 4/5 =
 0.8

=item * C<< $msg->doc_ndcg() >> / C<< $msg->doc_ndcg($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics::TopkMetrics>)

Normalized discounted cumulative gain (NDCG) per document, at various top-k
cutoff levels.

NDCG measures the ranking quality, giving higher relevance to top
results.

Example (top-3):
 Suppose [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]
 with three retrieved documents (D1, D2, D3) and binary relevance
 judgements (1 for relevant, 0 for not relevant):

  Retrieved:  [D3 (0), D1 (1), D2 (1)]
  Ideal:      [D1 (1), D2 (1), D3 (0)]

  Calculate NDCG@3 for each
  [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]:
   * DCG@3: 0/log2(1+1) + 1/log2(2+1) + 1/log2(3+1) = 1.13
   * Ideal DCG@3: 1/log2(1+1) + 1/log2(2+1) + 0/log2(3+1) = 1.63
   * NDCG@3: 1.13/1.63 = 0.693

=item * C<< $msg->page_recall() >> / C<< $msg->page_recall($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics::TopkMetrics>)

Recall per page, at various top-k cutoff levels.

Recall is the fraction of relevant pages retrieved out of all relevant
pages.

Example (top-5):
 * For a single
 [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery], if 3 out
 of 5 relevant pages are retrieved in the top-5, recall@5 = 3/5 = 0.6

=item * C<< $msg->page_ndcg() >> / C<< $msg->page_ndcg($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Evaluation::QualityMetrics::TopkMetrics>)

Normalized discounted cumulative gain (NDCG) per page, at various top-k
cutoff levels.

NDCG measures the ranking quality, giving higher relevance to top
results.

Example (top-3):
 Suppose [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]
 with three retrieved pages (P1, P2, P3) and binary relevance judgements (1
 for relevant, 0 for not relevant):

  Retrieved:  [P3 (0), P1 (1), P2 (1)]
  Ideal:      [P1 (1), P2 (1), P3 (0)]

  Calculate NDCG@3 for
  [SampleQuery][google.cloud.discoveryengine.v1beta.SampleQuery]:
   * DCG@3: 0/log2(1+1) + 1/log2(2+1) + 1/log2(3+1) = 1.13
   * Ideal DCG@3: 1/log2(1+1) + 1/log2(2+1) + 0/log2(3+1) = 1.63
   * NDCG@3: 1.13/1.63 = 0.693

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Evaluation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
