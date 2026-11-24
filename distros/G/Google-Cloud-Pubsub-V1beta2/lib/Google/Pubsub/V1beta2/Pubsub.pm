package Google::Pubsub::V1beta2::Pubsub;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvcHVic3ViL3YxYmV0YTIvcHVic3ViLnByb3RvEhVnb29nbGUucHVic3ViLnYx
YmV0YTIaG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90byIbCgVUb3BpYxISCgRuYW1lGAEg
ASgJUgRuYW1lItcBCg1QdWJzdWJNZXNzYWdlEhIKBGRhdGEYASABKAxSBGRhdGESVAoKYXR0
cmlidXRlcxgCIAMoCzI0Lmdvb2dsZS5wdWJzdWIudjFiZXRhMi5QdWJzdWJNZXNzYWdlLkF0
dHJpYnV0ZXNFbnRyeVIKYXR0cmlidXRlcxIdCgptZXNzYWdlX2lkGAMgASgJUgltZXNzYWdl
SWQaPQoPQXR0cmlidXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEiJwoPR2V0VG9waWNSZXF1ZXN0EhQKBXRvcGljGAEgASgJUgV0b3BpYyJo
Cg5QdWJsaXNoUmVxdWVzdBIUCgV0b3BpYxgBIAEoCVIFdG9waWMSQAoIbWVzc2FnZXMYAiAD
KAsyJC5nb29nbGUucHVic3ViLnYxYmV0YTIuUHVic3ViTWVzc2FnZVIIbWVzc2FnZXMiMgoP
UHVibGlzaFJlc3BvbnNlEh8KC21lc3NhZ2VfaWRzGAEgAygJUgptZXNzYWdlSWRzImkKEUxp
c3RUb3BpY3NSZXF1ZXN0EhgKB3Byb2plY3QYASABKAlSB3Byb2plY3QSGwoJcGFnZV9zaXpl
GAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4icgoSTGlz
dFRvcGljc1Jlc3BvbnNlEjQKBnRvcGljcxgBIAMoCzIcLmdvb2dsZS5wdWJzdWIudjFiZXRh
Mi5Ub3BpY1IGdG9waWNzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
biJxCh1MaXN0VG9waWNTdWJzY3JpcHRpb25zUmVxdWVzdBIUCgV0b3BpYxgBIAEoCVIFdG9w
aWMSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglw
YWdlVG9rZW4ibgoeTGlzdFRvcGljU3Vic2NyaXB0aW9uc1Jlc3BvbnNlEiQKDXN1YnNjcmlw
dGlvbnMYASADKAlSDXN1YnNjcmlwdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuIioKEkRlbGV0ZVRvcGljUmVxdWVzdBIUCgV0b3BpYxgBIAEoCVIFdG9w
aWMirgEKDFN1YnNjcmlwdGlvbhISCgRuYW1lGAEgASgJUgRuYW1lEhQKBXRvcGljGAIgASgJ
UgV0b3BpYxJCCgtwdXNoX2NvbmZpZxgEIAEoCzIhLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5Q
dXNoQ29uZmlnUgpwdXNoQ29uZmlnEjAKFGFja19kZWFkbGluZV9zZWNvbmRzGAUgASgFUhJh
Y2tEZWFkbGluZVNlY29uZHMiwwEKClB1c2hDb25maWcSIwoNcHVzaF9lbmRwb2ludBgBIAEo
CVIMcHVzaEVuZHBvaW50ElEKCmF0dHJpYnV0ZXMYAiADKAsyMS5nb29nbGUucHVic3ViLnYx
YmV0YTIuUHVzaENvbmZpZy5BdHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0ZXMaPQoPQXR0cmli
dXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEi
aAoPUmVjZWl2ZWRNZXNzYWdlEhUKBmFja19pZBgBIAEoCVIFYWNrSWQSPgoHbWVzc2FnZRgC
IAEoCzIkLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5QdWJzdWJNZXNzYWdlUgdtZXNzYWdlIjwK
FkdldFN1YnNjcmlwdGlvblJlcXVlc3QSIgoMc3Vic2NyaXB0aW9uGAEgASgJUgxzdWJzY3Jp
cHRpb24icAoYTGlzdFN1YnNjcmlwdGlvbnNSZXF1ZXN0EhgKB3Byb2plY3QYASABKAlSB3By
b2plY3QSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJ
UglwYWdlVG9rZW4ijgEKGUxpc3RTdWJzY3JpcHRpb25zUmVzcG9uc2USSQoNc3Vic2NyaXB0
aW9ucxgBIAMoCzIjLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5TdWJzY3JpcHRpb25SDXN1YnNj
cmlwdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIj8KGURl
bGV0ZVN1YnNjcmlwdGlvblJlcXVlc3QSIgoMc3Vic2NyaXB0aW9uGAEgASgJUgxzdWJzY3Jp
cHRpb24igQEKF01vZGlmeVB1c2hDb25maWdSZXF1ZXN0EiIKDHN1YnNjcmlwdGlvbhgBIAEo
CVIMc3Vic2NyaXB0aW9uEkIKC3B1c2hfY29uZmlnGAIgASgLMiEuZ29vZ2xlLnB1YnN1Yi52
MWJldGEyLlB1c2hDb25maWdSCnB1c2hDb25maWcigwEKC1B1bGxSZXF1ZXN0EiIKDHN1YnNj
cmlwdGlvbhgBIAEoCVIMc3Vic2NyaXB0aW9uEi0KEnJldHVybl9pbW1lZGlhdGVseRgCIAEo
CFIRcmV0dXJuSW1tZWRpYXRlbHkSIQoMbWF4X21lc3NhZ2VzGAMgASgFUgttYXhNZXNzYWdl
cyJjCgxQdWxsUmVzcG9uc2USUwoRcmVjZWl2ZWRfbWVzc2FnZXMYASADKAsyJi5nb29nbGUu
cHVic3ViLnYxYmV0YTIuUmVjZWl2ZWRNZXNzYWdlUhByZWNlaXZlZE1lc3NhZ2VzIocBChhN
b2RpZnlBY2tEZWFkbGluZVJlcXVlc3QSIgoMc3Vic2NyaXB0aW9uGAEgASgJUgxzdWJzY3Jp
cHRpb24SFQoGYWNrX2lkGAIgASgJUgVhY2tJZBIwChRhY2tfZGVhZGxpbmVfc2Vjb25kcxgD
IAEoBVISYWNrRGVhZGxpbmVTZWNvbmRzIlEKEkFja25vd2xlZGdlUmVxdWVzdBIiCgxzdWJz
Y3JpcHRpb24YASABKAlSDHN1YnNjcmlwdGlvbhIXCgdhY2tfaWRzGAIgAygJUgZhY2tJZHMy
iAYKClN1YnNjcmliZXISXgoSQ3JlYXRlU3Vic2NyaXB0aW9uEiMuZ29vZ2xlLnB1YnN1Yi52
MWJldGEyLlN1YnNjcmlwdGlvbhojLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5TdWJzY3JpcHRp
b24SZQoPR2V0U3Vic2NyaXB0aW9uEi0uZ29vZ2xlLnB1YnN1Yi52MWJldGEyLkdldFN1YnNj
cmlwdGlvblJlcXVlc3QaIy5nb29nbGUucHVic3ViLnYxYmV0YTIuU3Vic2NyaXB0aW9uEnYK
EUxpc3RTdWJzY3JpcHRpb25zEi8uZ29vZ2xlLnB1YnN1Yi52MWJldGEyLkxpc3RTdWJzY3Jp
cHRpb25zUmVxdWVzdBowLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5MaXN0U3Vic2NyaXB0aW9u
c1Jlc3BvbnNlEl4KEkRlbGV0ZVN1YnNjcmlwdGlvbhIwLmdvb2dsZS5wdWJzdWIudjFiZXRh
Mi5EZWxldGVTdWJzY3JpcHRpb25SZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5ElwK
EU1vZGlmeUFja0RlYWRsaW5lEi8uZ29vZ2xlLnB1YnN1Yi52MWJldGEyLk1vZGlmeUFja0Rl
YWRsaW5lUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eRJQCgtBY2tub3dsZWRnZRIp
Lmdvb2dsZS5wdWJzdWIudjFiZXRhMi5BY2tub3dsZWRnZVJlcXVlc3QaFi5nb29nbGUucHJv
dG9idWYuRW1wdHkSTwoEUHVsbBIiLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5QdWxsUmVxdWVz
dBojLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5QdWxsUmVzcG9uc2USWgoQTW9kaWZ5UHVzaENv
bmZpZxIuLmdvb2dsZS5wdWJzdWIudjFiZXRhMi5Nb2RpZnlQdXNoQ29uZmlnUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eTK/BAoJUHVibGlzaGVyEkkKC0NyZWF0ZVRvcGljEhwu
Z29vZ2xlLnB1YnN1Yi52MWJldGEyLlRvcGljGhwuZ29vZ2xlLnB1YnN1Yi52MWJldGEyLlRv
cGljElgKB1B1Ymxpc2gSJS5nb29nbGUucHVic3ViLnYxYmV0YTIuUHVibGlzaFJlcXVlc3Qa
Ji5nb29nbGUucHVic3ViLnYxYmV0YTIuUHVibGlzaFJlc3BvbnNlElAKCEdldFRvcGljEiYu
Z29vZ2xlLnB1YnN1Yi52MWJldGEyLkdldFRvcGljUmVxdWVzdBocLmdvb2dsZS5wdWJzdWIu
djFiZXRhMi5Ub3BpYxJhCgpMaXN0VG9waWNzEiguZ29vZ2xlLnB1YnN1Yi52MWJldGEyLkxp
c3RUb3BpY3NSZXF1ZXN0GikuZ29vZ2xlLnB1YnN1Yi52MWJldGEyLkxpc3RUb3BpY3NSZXNw
b25zZRKFAQoWTGlzdFRvcGljU3Vic2NyaXB0aW9ucxI0Lmdvb2dsZS5wdWJzdWIudjFiZXRh
Mi5MaXN0VG9waWNTdWJzY3JpcHRpb25zUmVxdWVzdBo1Lmdvb2dsZS5wdWJzdWIudjFiZXRh
Mi5MaXN0VG9waWNTdWJzY3JpcHRpb25zUmVzcG9uc2USUAoLRGVsZXRlVG9waWMSKS5nb29n
bGUucHVic3ViLnYxYmV0YTIuRGVsZXRlVG9waWNSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVm
LkVtcHR5QmcKGWNvbS5nb29nbGUucHVic3ViLnYxYmV0YTJCC1B1YnN1YlByb3RvUAFaO2dv
b2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvcHVic3ViL3YxYmV0YTI7cHVi
c3ViSu1zCgcSBQ4AggMBCsIECgEMEgMOABIytwQgQ29weXJpZ2h0IChjKSAyMDE1LCBHb29n
bGUgSW5jLgoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAeCgkKAgMAEgMSACUKCAoBCBIDFABSCgkKAggLEgMUAFIKCAoBCBIDFQAi
CgkKAggKEgMVACIKCAoBCBIDFgAsCgkKAggIEgMWACwKCAoBCBIDFwAyCgkKAggBEgMXADIK
kQEKAgYAEgQbAFEBGoQBIFRoZSBzZXJ2aWNlIHRoYXQgYW4gYXBwbGljYXRpb24gdXNlcyB0
byBtYW5pcHVsYXRlIHN1YnNjcmlwdGlvbnMgYW5kIHRvCiBjb25zdW1lIG1lc3NhZ2VzIGZy
b20gYSBzdWJzY3JpcHRpb24gdmlhIHRoZSBQdWxsIG1ldGhvZC4KCgoKAwYAARIDGwgSCtYC
CgQGAAIAEgMiAj4ayAIgQ3JlYXRlcyBhIHN1YnNjcmlwdGlvbiB0byBhIGdpdmVuIHRvcGlj
IGZvciBhIGdpdmVuIHN1YnNjcmliZXIuCiBJZiB0aGUgc3Vic2NyaXB0aW9uIGFscmVhZHkg
ZXhpc3RzLCByZXR1cm5zIEFMUkVBRFlfRVhJU1RTLgogSWYgdGhlIGNvcnJlc3BvbmRpbmcg
dG9waWMgZG9lc24ndCBleGlzdCwgcmV0dXJucyBOT1RfRk9VTkQuCgogSWYgdGhlIG5hbWUg
aXMgbm90IHByb3ZpZGVkIGluIHRoZSByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwgYXNzaWdu
IGEgcmFuZG9tCiBuYW1lIGZvciB0aGlzIHN1YnNjcmlwdGlvbiBvbiB0aGUgc2FtZSBwcm9q
ZWN0IGFzIHRoZSB0b3BpYy4KCgwKBQYAAgABEgMiBhgKDAoFBgACAAISAyIZJQoMCgUGAAIA
AxIDIjA8CkAKBAYAAgESAyUCRRozIEdldHMgdGhlIGNvbmZpZ3VyYXRpb24gZGV0YWlscyBv
ZiBhIHN1YnNjcmlwdGlvbi4KCgwKBQYAAgEBEgMlBhUKDAoFBgACAQISAyUWLAoMCgUGAAIB
AxIDJTdDCi0KBAYAAgISBCgCKSoaHyBMaXN0cyBtYXRjaGluZyBzdWJzY3JpcHRpb25zLgoK
DAoFBgACAgESAygGFwoMCgUGAAICAhIDKBgwCgwKBQYAAgIDEgMpDygK6QIKBAYAAgMSBDAC
MSYa2gIgRGVsZXRlcyBhbiBleGlzdGluZyBzdWJzY3JpcHRpb24uIEFsbCBwZW5kaW5nIG1l
c3NhZ2VzIGluIHRoZSBzdWJzY3JpcHRpb24KIGFyZSBpbW1lZGlhdGVseSBkcm9wcGVkLiBD
YWxscyB0byBQdWxsIGFmdGVyIGRlbGV0aW9uIHdpbGwgcmV0dXJuCiBOT1RfRk9VTkQuIEFm
dGVyIGEgc3Vic2NyaXB0aW9uIGlzIGRlbGV0ZWQsIGEgbmV3IG9uZSBtYXkgYmUgY3JlYXRl
ZCB3aXRoCiB0aGUgc2FtZSBuYW1lLCBidXQgdGhlIG5ldyBvbmUgaGFzIG5vIGFzc29jaWF0
aW9uIHdpdGggdGhlIG9sZAogc3Vic2NyaXB0aW9uLCBvciBpdHMgdG9waWMgdW5sZXNzIHRo
ZSBzYW1lIHRvcGljIGlzIHNwZWNpZmllZC4KCgwKBQYAAgMBEgMwBhgKDAoFBgACAwISAzAZ
MgoMCgUGAAIDAxIDMQ8kCvsBCgQGAAIEEgQ3AjgmGuwBIE1vZGlmaWVzIHRoZSBhY2sgZGVh
ZGxpbmUgZm9yIGEgc3BlY2lmaWMgbWVzc2FnZS4gVGhpcyBtZXRob2QgaXMgdXNlZnVsIHRv
CiBpbmRpY2F0ZSB0aGF0IG1vcmUgdGltZSBpcyBuZWVkZWQgdG8gcHJvY2VzcyBhIG1lc3Nh
Z2UgYnkgdGhlIHN1YnNjcmliZXIsCiBvciB0byBtYWtlIHRoZSBtZXNzYWdlIGF2YWlsYWJs
ZSBmb3IgcmVkZWxpdmVyeSBpZiB0aGUgcHJvY2Vzc2luZyB3YXMKIGludGVycnVwdGVkLgoK
DAoFBgACBAESAzcGFwoMCgUGAAIEAhIDNxgwCgwKBQYAAgQDEgM4DyQK6QIKBAYAAgUSA0EC
RhrbAiBBY2tub3dsZWRnZXMgdGhlIG1lc3NhZ2VzIGFzc29jaWF0ZWQgd2l0aCB0aGUgYWNr
IHRva2VucyBpbiB0aGUKIEFja25vd2xlZGdlUmVxdWVzdC4gVGhlIFB1Yi9TdWIgc3lzdGVt
IGNhbiByZW1vdmUgdGhlIHJlbGV2YW50IG1lc3NhZ2VzCiBmcm9tIHRoZSBzdWJzY3JpcHRp
b24uCgogQWNrbm93bGVkZ2luZyBhIG1lc3NhZ2Ugd2hvc2UgYWNrIGRlYWRsaW5lIGhhcyBl
eHBpcmVkIG1heSBzdWNjZWVkLAogYnV0IHN1Y2ggYSBtZXNzYWdlIG1heSBiZSByZWRlbGl2
ZXJlZCBsYXRlci4gQWNrbm93bGVkZ2luZyBhIG1lc3NhZ2UgbW9yZQogdGhhbiBvbmNlIHdp
bGwgbm90IHJlc3VsdCBpbiBhbiBlcnJvci4KCgwKBQYAAgUBEgNBBhEKDAoFBgACBQISA0ES
JAoMCgUGAAIFAxIDQS9ECvABCgQGAAIGEgNHAi8a4gEgUHVsbHMgbWVzc2FnZXMgZnJvbSB0
aGUgc2VydmVyLiBSZXR1cm5zIGFuIGVtcHR5IGxpc3QgaWYgdGhlcmUgYXJlIG5vCiBtZXNz
YWdlcyBhdmFpbGFibGUgaW4gdGhlIGJhY2tsb2cuIFRoZSBzZXJ2ZXIgbWF5IHJldHVybiBV
TkFWQUlMQUJMRSBpZgogdGhlcmUgYXJlIHRvbyBtYW55IGNvbmN1cnJlbnQgcHVsbCByZXF1
ZXN0cyBwZW5kaW5nIGZvciB0aGUgZ2l2ZW4KIHN1YnNjcmlwdGlvbi4KCgwKBQYAAgYBEgNH
BgoKDAoFBgACBgISA0cLFgoMCgUGAAIGAxIDRyEtCu8CCgQGAAIHEgNQAlAa4QIgTW9kaWZp
ZXMgdGhlIFB1c2hDb25maWcgZm9yIGEgc3BlY2lmaWVkIHN1YnNjcmlwdGlvbi4KCiBUaGlz
IG1heSBiZSB1c2VkIHRvIGNoYW5nZSBhIHB1c2ggc3Vic2NyaXB0aW9uIHRvIGEgcHVsbCBv
bmUgKHNpZ25pZmllZAogYnkgYW4gZW1wdHkgUHVzaENvbmZpZykgb3IgdmljZSB2ZXJzYSwg
b3IgY2hhbmdlIHRoZSBlbmRwb2ludCBVUkwgYW5kIG90aGVyCiBhdHRyaWJ1dGVzIG9mIGEg
cHVzaCBzdWJzY3JpcHRpb24uIE1lc3NhZ2VzIHdpbGwgYWNjdW11bGF0ZSBmb3IKIGRlbGl2
ZXJ5IGNvbnRpbnVvdXNseSB0aHJvdWdoIHRoZSBjYWxsIHJlZ2FyZGxlc3Mgb2YgY2hhbmdl
cyB0byB0aGUKIFB1c2hDb25maWcuCgoMCgUGAAIHARIDUAYWCgwKBQYAAgcCEgNQFy4KDAoF
BgACBwMSA1A5TgpqCgIGARIEVQBtARpeIFRoZSBzZXJ2aWNlIHRoYXQgYW4gYXBwbGljYXRp
b24gdXNlcyB0byBtYW5pcHVsYXRlIHRvcGljcywgYW5kIHRvIHNlbmQKIG1lc3NhZ2VzIHRv
IGEgdG9waWMuCgoKCgMGAQESA1UIEQo7CgQGAQIAEgNXAikaLiBDcmVhdGVzIHRoZSBnaXZl
biB0b3BpYyB3aXRoIHRoZSBnaXZlbiBuYW1lLgoKDAoFBgECAAESA1cGEQoMCgUGAQIAAhID
VxIXCgwKBQYBAgADEgNXIicKZgoEBgECARIDWwI4GlkgQWRkcyBvbmUgb3IgbW9yZSBtZXNz
YWdlcyB0byB0aGUgdG9waWMuIFJldHVybnMgTk9UX0ZPVU5EIGlmIHRoZSB0b3BpYyBkb2Vz
CiBub3QgZXhpc3QuCgoMCgUGAQIBARIDWwYNCgwKBQYBAgECEgNbDhwKDAoFBgECAQMSA1sn
NgoxCgQGAQICEgNeAjAaJCBHZXRzIHRoZSBjb25maWd1cmF0aW9uIG9mIGEgdG9waWMuCgoM
CgUGAQICARIDXgYOCgwKBQYBAgICEgNeDx4KDAoFBgECAgMSA14pLgolCgQGAQIDEgNhAkEa
GCBMaXN0cyBtYXRjaGluZyB0b3BpY3MuCgoMCgUGAQIDARIDYQYQCgwKBQYBAgMCEgNhESIK
DAoFBgECAwMSA2EtPwpDCgQGAQIEEgRkAmUvGjUgTGlzdHMgdGhlIG5hbWUgb2YgdGhlIHN1
YnNjcmlwdGlvbnMgZm9yIHRoaXMgdG9waWMuCgoMCgUGAQIEARIDZAYcCgwKBQYBAgQCEgNk
HToKDAoFBgECBAMSA2UPLQq7AgoEBgECBRIDbAJGGq0CIERlbGV0ZXMgdGhlIHRvcGljIHdp
dGggdGhlIGdpdmVuIG5hbWUuIFJldHVybnMgTk9UX0ZPVU5EIGlmIHRoZSB0b3BpYyBkb2Vz
CiBub3QgZXhpc3QuIEFmdGVyIGEgdG9waWMgaXMgZGVsZXRlZCwgYSBuZXcgdG9waWMgbWF5
IGJlIGNyZWF0ZWQgd2l0aCB0aGUKIHNhbWUgbmFtZTsgdGhpcyBpcyBhbiBlbnRpcmVseSBu
ZXcgdG9waWMgd2l0aCBub25lIG9mIHRoZSBvbGQKIGNvbmZpZ3VyYXRpb24gb3Igc3Vic2Ny
aXB0aW9ucy4gRXhpc3Rpbmcgc3Vic2NyaXB0aW9ucyB0byB0aGlzIHRvcGljIGFyZQogbm90
IGRlbGV0ZWQuCgoMCgUGAQIFARIDbAYRCgwKBQYBAgUCEgNsEiQKDAoFBgECBQMSA2wvRAof
CgIEABIEcABzARoTIEEgdG9waWMgcmVzb3VyY2UuCgoKCgMEAAESA3AIDQohCgQEAAIAEgNy
AhIaFCBOYW1lIG9mIHRoZSB0b3BpYy4KCgwKBQQAAgAFEgNyAggKDAoFBAACAAESA3IJDQoM
CgUEAAIAAxIDchARCjEKAgQBEgV2AIMBARokIEEgbWVzc2FnZSBkYXRhIGFuZCBpdHMgYXR0
cmlidXRlcy4KCgoKAwQBARIDdggVCmcKBAQBAgASA3kCERpaIFRoZSBtZXNzYWdlIHBheWxv
YWQuIEZvciBKU09OIHJlcXVlc3RzLCB0aGUgdmFsdWUgb2YgdGhpcyBmaWVsZCBtdXN0IGJl
CiBiYXNlNjQtZW5jb2RlZC4KCgwKBQQBAgAFEgN5AgcKDAoFBAECAAESA3kIDAoMCgUEAQIA
AxIDeQ8QCjQKBAQBAgESA3wCJRonIE9wdGlvbmFsIGF0dHJpYnV0ZXMgZm9yIHRoaXMgbWVz
c2FnZS4KCgwKBQQBAgEGEgN8AhUKDAoFBAECAQESA3wWIAoMCgUEAQIBAxIDfCMkCqACCgQE
AQICEgSCAQIYGpECIElEIG9mIHRoaXMgbWVzc2FnZSBhc3NpZ25lZCBieSB0aGUgc2VydmVy
IGF0IHB1YmxpY2F0aW9uIHRpbWUuIEd1YXJhbnRlZWQKIHRvIGJlIHVuaXF1ZSB3aXRoaW4g
dGhlIHRvcGljLiBUaGlzIHZhbHVlIG1heSBiZSByZWFkIGJ5IGEgc3Vic2NyaWJlcgogdGhh
dCByZWNlaXZlcyBhIFB1YnN1Yk1lc3NhZ2UgdmlhIGEgUHVsbCBjYWxsIG9yIGEgcHVzaCBk
ZWxpdmVyeS4gSXQgbXVzdAogbm90IGJlIHBvcHVsYXRlZCBieSBhIHB1Ymxpc2hlciBpbiBh
IFB1Ymxpc2ggY2FsbC4KCg0KBQQBAgIFEgSCAQIICg0KBQQBAgIBEgSCAQkTCg0KBQQBAgID
EgSCARYXCjAKAgQCEgaGAQCJAQEaIiBSZXF1ZXN0IGZvciB0aGUgR2V0VG9waWMgbWV0aG9k
LgoKCwoDBAIBEgSGAQgXCi0KBAQCAgASBIgBAhMaHyBUaGUgbmFtZSBvZiB0aGUgdG9waWMg
dG8gZ2V0LgoKDQoFBAICAAUSBIgBAggKDQoFBAICAAESBIgBCQ4KDQoFBAICAAMSBIgBERIK
LwoCBAMSBowBAJIBARohIFJlcXVlc3QgZm9yIHRoZSBQdWJsaXNoIG1ldGhvZC4KCgsKAwQD
ARIEjAEIFgpMCgQEAwIAEgSOAQITGj4gVGhlIG1lc3NhZ2VzIGluIHRoZSByZXF1ZXN0IHdp
bGwgYmUgcHVibGlzaGVkIG9uIHRoaXMgdG9waWMuCgoNCgUEAwIABRIEjgECCAoNCgUEAwIA
ARIEjgEJDgoNCgUEAwIAAxIEjgEREgooCgQEAwIBEgSRAQImGhogVGhlIG1lc3NhZ2VzIHRv
IHB1Ymxpc2guCgoNCgUEAwIBBBIEkQECCgoNCgUEAwIBBhIEkQELGAoNCgUEAwIBARIEkQEZ
IQoNCgUEAwIBAxIEkQEkJQowCgIEBBIGlQEAmgEBGiIgUmVzcG9uc2UgZm9yIHRoZSBQdWJs
aXNoIG1ldGhvZC4KCgsKAwQEARIElQEIFwqoAQoEBAQCABIEmQECIhqZASBUaGUgc2VydmVy
LWFzc2lnbmVkIElEIG9mIGVhY2ggcHVibGlzaGVkIG1lc3NhZ2UsIGluIHRoZSBzYW1lIG9y
ZGVyIGFzCiB0aGUgbWVzc2FnZXMgaW4gdGhlIHJlcXVlc3QuIElEcyBhcmUgZ3VhcmFudGVl
ZCB0byBiZSB1bmlxdWUgd2l0aGluCiB0aGUgdG9waWMuCgoNCgUEBAIABBIEmQECCgoNCgUE
BAIABRIEmQELEQoNCgUEBAIAARIEmQESHQoNCgUEBAIAAxIEmQEgIQoyCgIEBRIGnQEAqAEB
GiQgUmVxdWVzdCBmb3IgdGhlIExpc3RUb3BpY3MgbWV0aG9kLgoKCwoDBAUBEgSdAQgZCkQK
BAQFAgASBJ8BAhUaNiBUaGUgbmFtZSBvZiB0aGUgY2xvdWQgcHJvamVjdCB0aGF0IHRvcGlj
cyBiZWxvbmcgdG8uCgoNCgUEBQIABRIEnwECCAoNCgUEBQIAARIEnwEJEAoNCgUEBQIAAxIE
nwETFAozCgQEBQIBEgSiAQIWGiUgTWF4aW11bSBudW1iZXIgb2YgdG9waWNzIHRvIHJldHVy
bi4KCg0KBQQFAgEFEgSiAQIHCg0KBQQFAgEBEgSiAQgRCg0KBQQFAgEDEgSiARQVCsABCgQE
BQICEgSnAQIYGrEBIFRoZSB2YWx1ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBMaXN0VG9waWNz
UmVzcG9uc2U7IGluZGljYXRlcyB0aGF0IHRoaXMgaXMKIGEgY29udGludWF0aW9uIG9mIGEg
cHJpb3IgTGlzdFRvcGljcyBjYWxsLCBhbmQgdGhhdCB0aGUgc3lzdGVtIHNob3VsZAogcmV0
dXJuIHRoZSBuZXh0IHBhZ2Ugb2YgZGF0YS4KCg0KBQQFAgIFEgSnAQIICg0KBQQFAgIBEgSn
AQkTCg0KBQQFAgIDEgSnARYXCjMKAgQGEgarAQCyAQEaJSBSZXNwb25zZSBmb3IgdGhlIExp
c3RUb3BpY3MgbWV0aG9kLgoKCwoDBAYBEgSrAQgaCiUKBAQGAgASBK0BAhwaFyBUaGUgcmVz
dWx0aW5nIHRvcGljcy4KCg0KBQQGAgAEEgStAQIKCg0KBQQGAgAGEgStAQsQCg0KBQQGAgAB
EgStAREXCg0KBQQGAgADEgStARobCpcBCgQEBgIBEgSxAQIdGogBIElmIG5vdCBlbXB0eSwg
aW5kaWNhdGVzIHRoYXQgdGhlcmUgbWF5IGJlIG1vcmUgdG9waWNzIHRoYXQgbWF0Y2ggdGhl
CiByZXF1ZXN0OyB0aGlzIHZhbHVlIHNob3VsZCBiZSBwYXNzZWQgaW4gYSBuZXcgTGlzdFRv
cGljc1JlcXVlc3QuCgoNCgUEBgIBBRIEsQECCAoNCgUEBgIBARIEsQEJGAoNCgUEBgIBAxIE
sQEbHAo+CgIEBxIGtQEAwAEBGjAgUmVxdWVzdCBmb3IgdGhlIExpc3RUb3BpY1N1YnNjcmlw
dGlvbnMgbWV0aG9kLgoKCwoDBAcBEgS1AQglCkkKBAQHAgASBLcBAhMaOyBUaGUgbmFtZSBv
ZiB0aGUgdG9waWMgdGhhdCBzdWJzY3JpcHRpb25zIGFyZSBhdHRhY2hlZCB0by4KCg0KBQQH
AgAFEgS3AQIICg0KBQQHAgABEgS3AQkOCg0KBQQHAgADEgS3ARESCj8KBAQHAgESBLoBAhYa
MSBNYXhpbXVtIG51bWJlciBvZiBzdWJzY3JpcHRpb24gbmFtZXMgdG8gcmV0dXJuLgoKDQoF
BAcCAQUSBLoBAgcKDQoFBAcCAQESBLoBCBEKDQoFBAcCAQMSBLoBFBUK2AEKBAQHAgISBL8B
AhgayQEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0IExpc3RUb3BpY1N1YnNjcmlw
dGlvbnNSZXNwb25zZTsgaW5kaWNhdGVzCiB0aGF0IHRoaXMgaXMgYSBjb250aW51YXRpb24g
b2YgYSBwcmlvciBMaXN0VG9waWNTdWJzY3JpcHRpb25zIGNhbGwsIGFuZAogdGhhdCB0aGUg
c3lzdGVtIHNob3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBkYXRhLgoKDQoFBAcCAgUS
BL8BAggKDQoFBAcCAgESBL8BCRMKDQoFBAcCAgMSBL8BFhcKPwoCBAgSBsMBAMsBARoxIFJl
c3BvbnNlIGZvciB0aGUgTGlzdFRvcGljU3Vic2NyaXB0aW9ucyBtZXRob2QuCgoLCgMECAES
BMMBCCYKRgoEBAgCABIExQECJBo4IFRoZSBuYW1lcyBvZiB0aGUgc3Vic2NyaXB0aW9ucyB0
aGF0IG1hdGNoIHRoZSByZXF1ZXN0LgoKDQoFBAgCAAQSBMUBAgoKDQoFBAgCAAUSBMUBCxEK
DQoFBAgCAAESBMUBEh8KDQoFBAgCAAMSBMUBIiMKxQEKBAQIAgESBMoBAh0atgEgSWYgbm90
IGVtcHR5LCBpbmRpY2F0ZXMgdGhhdCB0aGVyZSBtYXkgYmUgbW9yZSBzdWJzY3JpcHRpb25z
IHRoYXQgbWF0Y2gKIHRoZSByZXF1ZXN0OyB0aGlzIHZhbHVlIHNob3VsZCBiZSBwYXNzZWQg
aW4gYSBuZXcKIExpc3RUb3BpY1N1YnNjcmlwdGlvbnNSZXF1ZXN0IHRvIGdldCBtb3JlIHN1
YnNjcmlwdGlvbnMuCgoNCgUECAIBBRIEygECCAoNCgUECAIBARIEygEJGAoNCgUECAIBAxIE
ygEbHAozCgIECRIGzgEA0QEBGiUgUmVxdWVzdCBmb3IgdGhlIERlbGV0ZVRvcGljIG1ldGhv
ZC4KCgsKAwQJARIEzgEIGgosCgQECQIAEgTQAQITGh4gTmFtZSBvZiB0aGUgdG9waWMgdG8g
ZGVsZXRlLgoKDQoFBAkCAAUSBNABAggKDQoFBAkCAAESBNABCQ4KDQoFBAkCAAMSBNABERIK
KAoCBAoSBtQBAPIBARoaIEEgc3Vic2NyaXB0aW9uIHJlc291cmNlLgoKCwoDBAoBEgTUAQgU
CikKBAQKAgASBNYBAhIaGyBOYW1lIG9mIHRoZSBzdWJzY3JpcHRpb24uCgoNCgUECgIABRIE
1gECCAoNCgUECgIAARIE1gEJDQoNCgUECgIAAxIE1gEQEQq3AQoEBAoCARIE2wECExqoASBU
aGUgbmFtZSBvZiB0aGUgdG9waWMgZnJvbSB3aGljaCB0aGlzIHN1YnNjcmlwdGlvbiBpcyBy
ZWNlaXZpbmcgbWVzc2FnZXMuCiBUaGlzIHdpbGwgYmUgcHJlc2VudCBpZiBhbmQgb25seSBp
ZiB0aGUgc3Vic2NyaXB0aW9uIGhhcyBub3QgYmVlbiBkZXRhY2hlZAogZnJvbSBpdHMgdG9w
aWMuCgoNCgUECgIBBRIE2wECCAoNCgUECgIBARIE2wEJDgoNCgUECgIBAxIE2wEREgrHAQoE
BAoCAhIE4AECHRq4ASBJZiBwdXNoIGRlbGl2ZXJ5IGlzIHVzZWQgd2l0aCB0aGlzIHN1YnNj
cmlwdGlvbiwgdGhpcyBmaWVsZCBpcwogdXNlZCB0byBjb25maWd1cmUgaXQuIEFuIGVtcHR5
IHB1c2hDb25maWcgc2lnbmlmaWVzIHRoYXQgdGhlIHN1YnNjcmliZXIKIHdpbGwgcHVsbCBh
bmQgYWNrIG1lc3NhZ2VzIHVzaW5nIEFQSSBtZXRob2RzLgoKDQoFBAoCAgYSBOABAgwKDQoF
BAoCAgESBOABDRgKDQoFBAoCAgMSBOABGxwK0wUKBAQKAgMSBPEBAiEaxAUgVGhpcyB2YWx1
ZSBpcyB0aGUgbWF4aW11bSB0aW1lIGFmdGVyIGEgc3Vic2NyaWJlciByZWNlaXZlcyBhIG1l
c3NhZ2UKIGJlZm9yZSB0aGUgc3Vic2NyaWJlciBzaG91bGQgYWNrbm93bGVkZ2UgdGhlIG1l
c3NhZ2UuIEFmdGVyIG1lc3NhZ2UKIGRlbGl2ZXJ5IGJ1dCBiZWZvcmUgdGhlIGFjayBkZWFk
bGluZSBleHBpcmVzIGFuZCBiZWZvcmUgdGhlIG1lc3NhZ2UgaXMKIGFja25vd2xlZGdlZCwg
aXQgaXMgYW4gb3V0c3RhbmRpbmcgbWVzc2FnZSBhbmQgd2lsbCBub3QgYmUgZGVsaXZlcmVk
CiBhZ2FpbiBkdXJpbmcgdGhhdCB0aW1lIChvbiBhIGJlc3QtZWZmb3J0IGJhc2lzKS4KCiBG
b3IgcHVsbCBkZWxpdmVyeSB0aGlzIHZhbHVlCiBpcyB1c2VkIGFzIHRoZSBpbml0aWFsIHZh
bHVlIGZvciB0aGUgYWNrIGRlYWRsaW5lLiBJdCBtYXkgYmUgb3ZlcnJpZGRlbgogZm9yIGEg
c3BlY2lmaWMgbWVzc2FnZSBieSBjYWxsaW5nIE1vZGlmeUFja0RlYWRsaW5lLgoKIEZvciBw
dXNoIGRlbGl2ZXJ5LCB0aGlzIHZhbHVlIGlzIGFsc28gdXNlZCB0byBzZXQgdGhlIHJlcXVl
c3QgdGltZW91dCBmb3IKIHRoZSBjYWxsIHRvIHRoZSBwdXNoIGVuZHBvaW50LgoKIElmIHRo
ZSBzdWJzY3JpYmVyIG5ldmVyIGFja25vd2xlZGdlcyB0aGUgbWVzc2FnZSwgdGhlIFB1Yi9T
dWIKIHN5c3RlbSB3aWxsIGV2ZW50dWFsbHkgcmVkZWxpdmVyIHRoZSBtZXNzYWdlLgoKDQoF
BAoCAwUSBPEBAgcKDQoFBAoCAwESBPEBCBwKDQoFBAoCAwMSBPEBHyAKOwoCBAsSBvUBAJIC
ARotIENvbmZpZ3VyYXRpb24gZm9yIGEgcHVzaCBkZWxpdmVyeSBlbmRwb2ludC4KCgsKAwQL
ARIE9QEIEgqXAQoEBAsCABIE+AECGxqIASBBIFVSTCBsb2NhdGluZyB0aGUgZW5kcG9pbnQg
dG8gd2hpY2ggbWVzc2FnZXMgc2hvdWxkIGJlIHB1c2hlZC4KIEZvciBleGFtcGxlLCBhIFdl
Ymhvb2sgZW5kcG9pbnQgbWlnaHQgdXNlICJodHRwczovL2V4YW1wbGUuY29tL3B1c2giLgoK
DQoFBAsCAAUSBPgBAggKDQoFBAsCAAESBPgBCRYKDQoFBAsCAAMSBPgBGRoK/gcKBAQLAgES
BJECAiUa7wcgRW5kcG9pbnQgY29uZmlndXJhdGlvbiBhdHRyaWJ1dGVzLgoKIEV2ZXJ5IGVu
ZHBvaW50IGhhcyBhIHNldCBvZiBBUEkgc3VwcG9ydGVkIGF0dHJpYnV0ZXMgdGhhdCBjYW4g
YmUgdXNlZCB0bwogY29udHJvbCBkaWZmZXJlbnQgYXNwZWN0cyBvZiB0aGUgbWVzc2FnZSBk
ZWxpdmVyeS4KCiBUaGUgY3VycmVudGx5IHN1cHBvcnRlZCBhdHRyaWJ1dGUgaXMgYHgtZ29v
Zy12ZXJzaW9uYCwgd2hpY2ggeW91IGNhbgogdXNlIHRvIGNoYW5nZSB0aGUgZm9ybWF0IG9m
IHRoZSBwdXNoIG1lc3NhZ2UuIFRoaXMgYXR0cmlidXRlCiBpbmRpY2F0ZXMgdGhlIHZlcnNp
b24gb2YgdGhlIGRhdGEgZXhwZWN0ZWQgYnkgdGhlIGVuZHBvaW50LiBUaGlzCiBjb250cm9s
cyB0aGUgc2hhcGUgb2YgdGhlIGVudmVsb3BlIChpLmUuIGl0cyBmaWVsZHMgYW5kIG1ldGFk
YXRhKS4KIFRoZSBlbmRwb2ludCB2ZXJzaW9uIGlzIGJhc2VkIG9uIHRoZSB2ZXJzaW9uIG9m
IHRoZSBQdWIvU3ViCiBBUEkuCgogSWYgbm90IHByZXNlbnQgZHVyaW5nIHRoZSBDcmVhdGVT
dWJzY3JpcHRpb24gY2FsbCwgaXQgd2lsbCBkZWZhdWx0IHRvCiB0aGUgdmVyc2lvbiBvZiB0
aGUgQVBJIHVzZWQgdG8gbWFrZSBzdWNoIGNhbGwuIElmIG5vdCBwcmVzZW50IGR1cmluZyBh
CiBNb2RpZnlQdXNoQ29uZmlnIGNhbGwsIGl0cyB2YWx1ZSB3aWxsIG5vdCBiZSBjaGFuZ2Vk
LiBHZXRTdWJzY3JpcHRpb24KIGNhbGxzIHdpbGwgYWx3YXlzIHJldHVybiBhIHZhbGlkIHZl
cnNpb24sIGV2ZW4gaWYgdGhlIHN1YnNjcmlwdGlvbiB3YXMKIGNyZWF0ZWQgd2l0aG91dCB0
aGlzIGF0dHJpYnV0ZS4KCiBUaGUgcG9zc2libGUgdmFsdWVzIGZvciB0aGlzIGF0dHJpYnV0
ZSBhcmU6CgogKiBgdjFiZXRhMWA6IHVzZXMgdGhlIHB1c2ggZm9ybWF0IGRlZmluZWQgaW4g
dGhlIHYxYmV0YTEgUHViL1N1YiBBUEkuCiAqIGB2MWJldGEyYDogdXNlcyB0aGUgcHVzaCBm
b3JtYXQgZGVmaW5lZCBpbiB0aGUgdjFiZXRhMiBQdWIvU3ViIEFQSS4KCgoNCgUECwIBBhIE
kQICFQoNCgUECwIBARIEkQIWIAoNCgUECwIBAxIEkQIjJApCCgIEDBIGlQIAmwIBGjQgQSBt
ZXNzYWdlIGFuZCBpdHMgY29ycmVzcG9uZGluZyBhY2tub3dsZWRnbWVudCBJRC4KCgsKAwQM
ARIElQIIFwpICgQEDAIAEgSXAgIUGjogVGhpcyBJRCBjYW4gYmUgdXNlZCB0byBhY2tub3ds
ZWRnZSB0aGUgcmVjZWl2ZWQgbWVzc2FnZS4KCg0KBQQMAgAFEgSXAgIICg0KBQQMAgABEgSX
AgkPCg0KBQQMAgADEgSXAhITChwKBAQMAgESBJoCAhwaDiBUaGUgbWVzc2FnZS4KCg0KBQQM
AgEGEgSaAgIPCg0KBQQMAgEBEgSaAhAXCg0KBQQMAgEDEgSaAhobCjcKAgQNEgaeAgChAgEa
KSBSZXF1ZXN0IGZvciB0aGUgR2V0U3Vic2NyaXB0aW9uIG1ldGhvZC4KCgsKAwQNARIEngII
Hgo0CgQEDQIAEgSgAgIaGiYgVGhlIG5hbWUgb2YgdGhlIHN1YnNjcmlwdGlvbiB0byBnZXQu
CgoNCgUEDQIABRIEoAICCAoNCgUEDQIAARIEoAIJFQoNCgUEDQIAAxIEoAIYGQo5CgIEDhIG
pAIArwIBGisgUmVxdWVzdCBmb3IgdGhlIExpc3RTdWJzY3JpcHRpb25zIG1ldGhvZC4KCgsK
AwQOARIEpAIIIApLCgQEDgIAEgSmAgIVGj0gVGhlIG5hbWUgb2YgdGhlIGNsb3VkIHByb2pl
Y3QgdGhhdCBzdWJzY3JpcHRpb25zIGJlbG9uZyB0by4KCg0KBQQOAgAFEgSmAgIICg0KBQQO
AgABEgSmAgkQCg0KBQQOAgADEgSmAhMUCjoKBAQOAgESBKkCAhYaLCBNYXhpbXVtIG51bWJl
ciBvZiBzdWJzY3JpcHRpb25zIHRvIHJldHVybi4KCg0KBQQOAgEFEgSpAgIHCg0KBQQOAgEB
EgSpAggRCg0KBQQOAgEDEgSpAhQVCs4BCgQEDgICEgSuAgIYGr8BIFRoZSB2YWx1ZSByZXR1
cm5lZCBieSB0aGUgbGFzdCBMaXN0U3Vic2NyaXB0aW9uc1Jlc3BvbnNlOyBpbmRpY2F0ZXMg
dGhhdAogdGhpcyBpcyBhIGNvbnRpbnVhdGlvbiBvZiBhIHByaW9yIExpc3RTdWJzY3JpcHRp
b25zIGNhbGwsIGFuZCB0aGF0IHRoZQogc3lzdGVtIHNob3VsZCByZXR1cm4gdGhlIG5leHQg
cGFnZSBvZiBkYXRhLgoKDQoFBA4CAgUSBK4CAggKDQoFBA4CAgESBK4CCRMKDQoFBA4CAgMS
BK4CFhcKOgoCBA8SBrICALoCARosIFJlc3BvbnNlIGZvciB0aGUgTGlzdFN1YnNjcmlwdGlv
bnMgbWV0aG9kLgoKCwoDBA8BEgSyAgghCjkKBAQPAgASBLQCAioaKyBUaGUgc3Vic2NyaXB0
aW9ucyB0aGF0IG1hdGNoIHRoZSByZXF1ZXN0LgoKDQoFBA8CAAQSBLQCAgoKDQoFBA8CAAYS
BLQCCxcKDQoFBA8CAAESBLQCGCUKDQoFBA8CAAMSBLQCKCkKwAEKBAQPAgESBLkCAh0asQEg
SWYgbm90IGVtcHR5LCBpbmRpY2F0ZXMgdGhhdCB0aGVyZSBtYXkgYmUgbW9yZSBzdWJzY3Jp
cHRpb25zIHRoYXQgbWF0Y2gKIHRoZSByZXF1ZXN0OyB0aGlzIHZhbHVlIHNob3VsZCBiZSBw
YXNzZWQgaW4gYSBuZXcgTGlzdFN1YnNjcmlwdGlvbnNSZXF1ZXN0CiB0byBnZXQgbW9yZSBz
dWJzY3JpcHRpb25zLgoKDQoFBA8CAQUSBLkCAggKDQoFBA8CAQESBLkCCRgKDQoFBA8CAQMS
BLkCGxwKOgoCBBASBr0CAMACARosIFJlcXVlc3QgZm9yIHRoZSBEZWxldGVTdWJzY3JpcHRp
b24gbWV0aG9kLgoKCwoDBBABEgS9AgghCisKBAQQAgASBL8CAhoaHSBUaGUgc3Vic2NyaXB0
aW9uIHRvIGRlbGV0ZS4KCg0KBQQQAgAFEgS/AgIICg0KBQQQAgABEgS/AgkVCg0KBQQQAgAD
EgS/AhgZCjgKAgQREgbDAgDOAgEaKiBSZXF1ZXN0IGZvciB0aGUgTW9kaWZ5UHVzaENvbmZp
ZyBtZXRob2QuCgoLCgMEEQESBMMCCB8KLQoEBBECABIExQICGhofIFRoZSBuYW1lIG9mIHRo
ZSBzdWJzY3JpcHRpb24uCgoNCgUEEQIABRIExQICCAoNCgUEEQIAARIExQIJFQoNCgUEEQIA
AxIExQIYGQqhAgoEBBECARIEzQICHRqSAiBUaGUgcHVzaCBjb25maWd1cmF0aW9uIGZvciBm
dXR1cmUgZGVsaXZlcmllcy4KCiBBbiBlbXB0eSBwdXNoQ29uZmlnIGluZGljYXRlcyB0aGF0
IHRoZSBQdWIvU3ViIHN5c3RlbSBzaG91bGQKIHN0b3AgcHVzaGluZyBtZXNzYWdlcyBmcm9t
IHRoZSBnaXZlbiBzdWJzY3JpcHRpb24gYW5kIGFsbG93CiBtZXNzYWdlcyB0byBiZSBwdWxs
ZWQgYW5kIGFja25vd2xlZGdlZCAtIGVmZmVjdGl2ZWx5IHBhdXNpbmcKIHRoZSBzdWJzY3Jp
cHRpb24gaWYgUHVsbCBpcyBub3QgY2FsbGVkLgoKDQoFBBECAQYSBM0CAgwKDQoFBBECAQES
BM0CDRgKDQoFBBECAQMSBM0CGxwKLAoCBBISBtECAN8CARoeIFJlcXVlc3QgZm9yIHRoZSBQ
dWxsIG1ldGhvZC4KCgsKAwQSARIE0QIIEwpGCgQEEgIAEgTTAgIaGjggVGhlIHN1YnNjcmlw
dGlvbiBmcm9tIHdoaWNoIG1lc3NhZ2VzIHNob3VsZCBiZSBwdWxsZWQuCgoNCgUEEgIABRIE
0wICCAoNCgUEEgIAARIE0wIJFQoNCgUEEgIAAxIE0wIYGQrkAgoEBBICARIE2gICHhrVAiBJ
ZiB0aGlzIGlzIHNwZWNpZmllZCBhcyB0cnVlIHRoZSBzeXN0ZW0gd2lsbCByZXNwb25kIGlt
bWVkaWF0ZWx5IGV2ZW4gaWYKIGl0IGlzIG5vdCBhYmxlIHRvIHJldHVybiBhIG1lc3NhZ2Ug
aW4gdGhlIFB1bGwgcmVzcG9uc2UuIE90aGVyd2lzZSB0aGUKIHN5c3RlbSBpcyBhbGxvd2Vk
IHRvIHdhaXQgdW50aWwgYXQgbGVhc3Qgb25lIG1lc3NhZ2UgaXMgYXZhaWxhYmxlIHJhdGhl
cgogdGhhbiByZXR1cm5pbmcgbm8gbWVzc2FnZXMuIFRoZSBjbGllbnQgbWF5IGNhbmNlbCB0
aGUgcmVxdWVzdCBpZiBpdCBkb2VzCiBub3Qgd2lzaCB0byB3YWl0IGFueSBsb25nZXIgZm9y
IHRoZSByZXNwb25zZS4KCg0KBQQSAgEFEgTaAgIGCg0KBQQSAgEBEgTaAgcZCg0KBQQSAgED
EgTaAhwdCokBCgQEEgICEgTeAgIZGnsgVGhlIG1heGltdW0gbnVtYmVyIG9mIG1lc3NhZ2Vz
IHJldHVybmVkIGZvciB0aGlzIHJlcXVlc3QuIFRoZSBQdWIvU3ViCiBzeXN0ZW0gbWF5IHJl
dHVybiBmZXdlciB0aGFuIHRoZSBudW1iZXIgc3BlY2lmaWVkLgoKDQoFBBICAgUSBN4CAgcK
DQoFBBICAgESBN4CCBQKDQoFBBICAgMSBN4CFxgKLQoCBBMSBuICAOgCARofIFJlc3BvbnNl
IGZvciB0aGUgUHVsbCBtZXRob2QuCgoLCgMEEwESBOICCBQKhwIKBAQTAgASBOcCAjEa+AEg
UmVjZWl2ZWQgUHViL1N1YiBtZXNzYWdlcy4gVGhlIFB1Yi9TdWIgc3lzdGVtIHdpbGwgcmV0
dXJuIHplcm8gbWVzc2FnZXMgaWYKIHRoZXJlIGFyZSBubyBtb3JlIGF2YWlsYWJsZSBpbiB0
aGUgYmFja2xvZy4gVGhlIFB1Yi9TdWIgc3lzdGVtIG1heSByZXR1cm4KIGZld2VyIHRoYW4g
dGhlIG1heE1lc3NhZ2VzIHJlcXVlc3RlZCBldmVuIGlmIHRoZXJlIGFyZSBtb3JlIG1lc3Nh
Z2VzCiBhdmFpbGFibGUgaW4gdGhlIGJhY2tsb2cuCgoNCgUEEwIABBIE5wICCgoNCgUEEwIA
BhIE5wILGgoNCgUEEwIAARIE5wIbLAoNCgUEEwIAAxIE5wIvMAo5CgIEFBIG6wIA+AIBGisg
UmVxdWVzdCBmb3IgdGhlIE1vZGlmeUFja0RlYWRsaW5lIG1ldGhvZC4KCgsKAwQUARIE6wII
IAotCgQEFAIAEgTtAgIaGh8gVGhlIG5hbWUgb2YgdGhlIHN1YnNjcmlwdGlvbi4KCg0KBQQU
AgAFEgTtAgIICg0KBQQUAgABEgTtAgkVCg0KBQQUAgADEgTtAhgZCiYKBAQUAgESBPACAhQa
GCBUaGUgYWNrbm93bGVkZ21lbnQgSUQuCgoNCgUEFAIBBRIE8AICCAoNCgUEFAIBARIE8AIJ
DwoNCgUEFAIBAxIE8AISEwrKAgoEBBQCAhIE9wICIRq7AiBUaGUgbmV3IGFjayBkZWFkbGlu
ZSB3aXRoIHJlc3BlY3QgdG8gdGhlIHRpbWUgdGhpcyByZXF1ZXN0IHdhcyBzZW50IHRvIHRo
ZQogUHViL1N1YiBzeXN0ZW0uIE11c3QgYmUgPj0gMC4gRm9yIGV4YW1wbGUsIGlmIHRoZSB2
YWx1ZSBpcyAxMCwgdGhlIG5ldyBhY2sKIGRlYWRsaW5lIHdpbGwgZXhwaXJlIDEwIHNlY29u
ZHMgYWZ0ZXIgdGhlIE1vZGlmeUFja0RlYWRsaW5lIGNhbGwgd2FzIG1hZGUuCiBTcGVjaWZ5
aW5nIHplcm8gbWF5IGltbWVkaWF0ZWx5IG1ha2UgdGhlIG1lc3NhZ2UgYXZhaWxhYmxlIGZv
ciBhbm90aGVyIHB1bGwKIHJlcXVlc3QuCgoNCgUEFAICBRIE9wICBwoNCgUEFAICARIE9wII
HAoNCgUEFAICAxIE9wIfIAozCgIEFRIG+wIAggMBGiUgUmVxdWVzdCBmb3IgdGhlIEFja25v
d2xlZGdlIG1ldGhvZC4KCgsKAwQVARIE+wIIGgpFCgQEFQIAEgT9AgIaGjcgVGhlIHN1YnNj
cmlwdGlvbiB3aG9zZSBtZXNzYWdlIGlzIGJlaW5nIGFja25vd2xlZGdlZC4KCg0KBQQVAgAF
EgT9AgIICg0KBQQVAgABEgT9AgkVCg0KBQQVAgADEgT9AhgZCpwBCgQEFQIBEgSBAwIeGo0B
IFRoZSBhY2tub3dsZWRnbWVudCBJRCBmb3IgdGhlIG1lc3NhZ2VzIGJlaW5nIGFja25vd2xl
ZGdlZCB0aGF0IHdhcyByZXR1cm5lZAogYnkgdGhlIFB1Yi9TdWIgc3lzdGVtIGluIHRoZSBQ
dWxsIHJlc3BvbnNlLiBNdXN0IG5vdCBiZSBlbXB0eS4KCg0KBQQVAgEEEgSBAwIKCg0KBQQV
AgEFEgSBAwsRCg0KBQQVAgEBEgSBAxIZCg0KBQQVAgEDEgSBAxwdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Pubsub::V1beta2::Pubsub::Topic ===
    # Fields for Topic
    # Field: name Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::PubsubMessage ===
    # Fields for PubsubMessage
    # Field: data Type: 12 ()
    # Field: attributes Type: 11 (.google.pubsub.v1beta2.PubsubMessage.AttributesEntry)
    # Field: message_id Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::GetTopicRequest ===
    # Fields for GetTopicRequest
    # Field: topic Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::PublishRequest ===
    # Fields for PublishRequest
    # Field: topic Type: 9 ()
    # Field: messages Type: 11 (.google.pubsub.v1beta2.PubsubMessage)

# === Message: Google::Pubsub::V1beta2::Pubsub::PublishResponse ===
    # Fields for PublishResponse
    # Field: message_ids Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest ===
    # Fields for ListTopicsRequest
    # Field: project Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse ===
    # Fields for ListTopicsResponse
    # Field: topics Type: 11 (.google.pubsub.v1beta2.Topic)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest ===
    # Fields for ListTopicSubscriptionsRequest
    # Field: topic Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse ===
    # Fields for ListTopicSubscriptionsResponse
    # Field: subscriptions Type: 9 ()
    # Field: next_page_token Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest ===
    # Fields for DeleteTopicRequest
    # Field: topic Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::Subscription ===
    # Fields for Subscription
    # Field: name Type: 9 ()
    # Field: topic Type: 9 ()
    # Field: push_config Type: 11 (.google.pubsub.v1beta2.PushConfig)
    # Field: ack_deadline_seconds Type: 5 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::PushConfig ===
    # Fields for PushConfig
    # Field: push_endpoint Type: 9 ()
    # Field: attributes Type: 11 (.google.pubsub.v1beta2.PushConfig.AttributesEntry)

# === Message: Google::Pubsub::V1beta2::Pubsub::ReceivedMessage ===
    # Fields for ReceivedMessage
    # Field: ack_id Type: 9 ()
    # Field: message Type: 11 (.google.pubsub.v1beta2.PubsubMessage)

# === Message: Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest ===
    # Fields for GetSubscriptionRequest
    # Field: subscription Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest ===
    # Fields for ListSubscriptionsRequest
    # Field: project Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse ===
    # Fields for ListSubscriptionsResponse
    # Field: subscriptions Type: 11 (.google.pubsub.v1beta2.Subscription)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest ===
    # Fields for DeleteSubscriptionRequest
    # Field: subscription Type: 9 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest ===
    # Fields for ModifyPushConfigRequest
    # Field: subscription Type: 9 ()
    # Field: push_config Type: 11 (.google.pubsub.v1beta2.PushConfig)

# === Message: Google::Pubsub::V1beta2::Pubsub::PullRequest ===
    # Fields for PullRequest
    # Field: subscription Type: 9 ()
    # Field: return_immediately Type: 8 ()
    # Field: max_messages Type: 5 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::PullResponse ===
    # Fields for PullResponse
    # Field: received_messages Type: 11 (.google.pubsub.v1beta2.ReceivedMessage)

# === Message: Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest ===
    # Fields for ModifyAckDeadlineRequest
    # Field: subscription Type: 9 ()
    # Field: ack_id Type: 9 ()
    # Field: ack_deadline_seconds Type: 5 ()

# === Message: Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest ===
    # Fields for AcknowledgeRequest
    # Field: subscription Type: 9 ()
    # Field: ack_ids Type: 9 ()

# === Service Client: Google::Pubsub::V1beta2::Pubsub::SubscriberClient ===
package Google::Pubsub::V1beta2::Pubsub::SubscriberClient;

=pod

=head2 Service Client: Google::Pubsub::V1beta2::Pubsub::SubscriberClient

Client stub representing the remote C<Subscriber> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsub.googleapis.com:443' );

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

sub create_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::Subscription->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'CreateSubscription',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::Subscription',
    });
}

sub get_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'GetSubscription',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::Subscription',
    });
}

sub list_subscriptions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'ListSubscriptions',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse',
    });
}

sub delete_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'DeleteSubscription',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub modify_ack_deadline {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'ModifyAckDeadline',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub acknowledge {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'Acknowledge',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub pull {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::PullRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'Pull',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::PullResponse',
    });
}

sub modify_push_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'ModifyPushConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

# === Service Client: Google::Pubsub::V1beta2::Pubsub::PublisherClient ===
package Google::Pubsub::V1beta2::Pubsub::PublisherClient;

=pod

=head2 Service Client: Google::Pubsub::V1beta2::Pubsub::PublisherClient

Client stub representing the remote C<Publisher> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<pubsub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'pubsub.googleapis.com:443' );

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

sub create_topic {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::Topic->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'CreateTopic',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::Topic',
    });
}

sub publish {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::PublishRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'Publish',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::PublishResponse',
    });
}

sub get_topic {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::GetTopicRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'GetTopic',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::Topic',
    });
}

sub list_topics {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'ListTopics',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse',
    });
}

sub list_topic_subscriptions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'ListTopicSubscriptions',
        request        => $req,
        response_class => 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse',
    });
}

sub delete_topic {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'DeleteTopic',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Pubsub::V1beta2::Pubsub - Compiled Protocol Buffers messages for google/pubsub/v1beta2/pubsub.proto

=head1 SYNOPSIS

    use Google::Pubsub::V1beta2::Pubsub;

    my $msg = Google::Pubsub::V1beta2::Pubsub::Topic->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Pubsub::V1beta2::Pubsub::Topic->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/pubsub/v1beta2/pubsub.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Pubsub::V1beta2::Pubsub::Topic

A topic resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the topic.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::PubsubMessage

A message data and its attributes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The message payload. For JSON requests, the value of this field must be
base64-encoded.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::PubsubMessage::AttributesEntry>)

Optional attributes for this message.

=item * C<< $msg->message_id() >> / C<< $msg->message_id($value) >>

Type: C<String>

ID of this message assigned by the server at publication time. Guaranteed
to be unique within the topic. This value may be read by a subscriber
that receives a PubsubMessage via a Pull call or a push delivery. It must
not be populated by a publisher in a Publish call.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::GetTopicRequest

Request for the GetTopic method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

The name of the topic to get.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::PublishRequest

Request for the Publish method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

The messages in the request will be published on this topic.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::PubsubMessage>)

The messages to publish.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::PublishResponse

Response for the Publish method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_ids() >> / C<< $msg->message_ids($value) >>

Type: C<String>

The server-assigned ID of each published message, in the same order as
the messages in the request. IDs are guaranteed to be unique within
the topic.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest

Request for the ListTopics method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

The name of the cloud project that topics belong to.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of topics to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last ListTopicsResponse; indicates that this is
a continuation of a prior ListTopics call, and that the system should
return the next page of data.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse

Response for the ListTopics method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topics() >> / C<< $msg->topics($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::Topic>)

The resulting topics.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more topics that match the
request; this value should be passed in a new ListTopicsRequest.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest

Request for the ListTopicSubscriptions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

The name of the topic that subscriptions are attached to.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of subscription names to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last ListTopicSubscriptionsResponse; indicates
that this is a continuation of a prior ListTopicSubscriptions call, and
that the system should return the next page of data.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse

Response for the ListTopicSubscriptions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscriptions() >> / C<< $msg->subscriptions($value) >>

Type: C<String>

The names of the subscriptions that match the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more subscriptions that match
the request; this value should be passed in a new
ListTopicSubscriptionsRequest to get more subscriptions.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest

Request for the DeleteTopic method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

Name of the topic to delete.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::Subscription

A subscription resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the subscription.

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

The name of the topic from which this subscription is receiving messages.
This will be present if and only if the subscription has not been detached
from its topic.

=item * C<< $msg->push_config() >> / C<< $msg->push_config($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::PushConfig>)

If push delivery is used with this subscription, this field is
used to configure it. An empty pushConfig signifies that the subscriber
will pull and ack messages using API methods.

=item * C<< $msg->ack_deadline_seconds() >> / C<< $msg->ack_deadline_seconds($value) >>

Type: C<Int32>

This value is the maximum time after a subscriber receives a message
before the subscriber should acknowledge the message. After message
delivery but before the ack deadline expires and before the message is
acknowledged, it is an outstanding message and will not be delivered
again during that time (on a best-effort basis).

For pull delivery this value
is used as the initial value for the ack deadline. It may be overridden
for a specific message by calling ModifyAckDeadline.

For push delivery, this value is also used to set the request timeout for
the call to the push endpoint.

If the subscriber never acknowledges the message, the Pub/Sub
system will eventually redeliver the message.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::PushConfig

Configuration for a push delivery endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->push_endpoint() >> / C<< $msg->push_endpoint($value) >>

Type: C<String>

A URL locating the endpoint to which messages should be pushed.
For example, a Webhook endpoint might use "https://example.com/push".

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::PushConfig::AttributesEntry>)

Endpoint configuration attributes.

Every endpoint has a set of API supported attributes that can be used to
control different aspects of the message delivery.

The currently supported attribute is `x-goog-version`, which you can
use to change the format of the push message. This attribute
indicates the version of the data expected by the endpoint. This
controls the shape of the envelope (i.e. its fields and metadata).
The endpoint version is based on the version of the Pub/Sub
API.

If not present during the CreateSubscription call, it will default to
the version of the API used to make such call. If not present during a
ModifyPushConfig call, its value will not be changed. GetSubscription
calls will always return a valid version, even if the subscription was
created without this attribute.

The possible values for this attribute are:

* `v1beta1`: uses the push format defined in the v1beta1 Pub/Sub API.
* `v1beta2`: uses the push format defined in the v1beta2 Pub/Sub API.


=back

=head2 Google::Pubsub::V1beta2::Pubsub::ReceivedMessage

A message and its corresponding acknowledgment ID.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ack_id() >> / C<< $msg->ack_id($value) >>

Type: C<String>

This ID can be used to acknowledge the received message.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::PubsubMessage>)

The message.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest

Request for the GetSubscription method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The name of the subscription to get.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest

Request for the ListSubscriptions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

The name of the cloud project that subscriptions belong to.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of subscriptions to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last ListSubscriptionsResponse; indicates that
this is a continuation of a prior ListSubscriptions call, and that the
system should return the next page of data.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse

Response for the ListSubscriptions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscriptions() >> / C<< $msg->subscriptions($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::Subscription>)

The subscriptions that match the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more subscriptions that match
the request; this value should be passed in a new ListSubscriptionsRequest
to get more subscriptions.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest

Request for the DeleteSubscription method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription to delete.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest

Request for the ModifyPushConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The name of the subscription.

=item * C<< $msg->push_config() >> / C<< $msg->push_config($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::PushConfig>)

The push configuration for future deliveries.

An empty pushConfig indicates that the Pub/Sub system should
stop pushing messages from the given subscription and allow
messages to be pulled and acknowledged - effectively pausing
the subscription if Pull is not called.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::PullRequest

Request for the Pull method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription from which messages should be pulled.

=item * C<< $msg->return_immediately() >> / C<< $msg->return_immediately($value) >>

Type: C<Bool>

If this is specified as true the system will respond immediately even if
it is not able to return a message in the Pull response. Otherwise the
system is allowed to wait until at least one message is available rather
than returning no messages. The client may cancel the request if it does
not wish to wait any longer for the response.

=item * C<< $msg->max_messages() >> / C<< $msg->max_messages($value) >>

Type: C<Int32>

The maximum number of messages returned for this request. The Pub/Sub
system may return fewer than the number specified.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::PullResponse

Response for the Pull method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->received_messages() >> / C<< $msg->received_messages($value) >>

Type: C<Message> (L<Google::Pubsub::V1beta2::Pubsub::ReceivedMessage>)

Received Pub/Sub messages. The Pub/Sub system will return zero messages if
there are no more available in the backlog. The Pub/Sub system may return
fewer than the maxMessages requested even if there are more messages
available in the backlog.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest

Request for the ModifyAckDeadline method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The name of the subscription.

=item * C<< $msg->ack_id() >> / C<< $msg->ack_id($value) >>

Type: C<String>

The acknowledgment ID.

=item * C<< $msg->ack_deadline_seconds() >> / C<< $msg->ack_deadline_seconds($value) >>

Type: C<Int32>

The new ack deadline with respect to the time this request was sent to the
Pub/Sub system. Must be >= 0. For example, if the value is 10, the new ack
deadline will expire 10 seconds after the ModifyAckDeadline call was made.
Specifying zero may immediately make the message available for another pull
request.

=back

=head2 Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest

Request for the Acknowledge method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

The subscription whose message is being acknowledged.

=item * C<< $msg->ack_ids() >> / C<< $msg->ack_ids($value) >>

Type: C<String>

The acknowledgment ID for the messages being acknowledged that was returned
by the Pub/Sub system in the Pull response. Must not be empty.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Pubsub::V1beta2::Pubsub::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
