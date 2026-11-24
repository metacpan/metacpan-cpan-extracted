package Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy;

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
    eval { require Google::Cloud::Networksecurity::V1beta1::Tls };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvc2VydmVyX3Rsc19wb2xp
Y3kucHJvdG8SJGdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxou
Z29vZ2xlL2Nsb3VkL25ldHdvcmtzZWN1cml0eS92MWJldGExL3Rscy5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8iywYKD1NlcnZlclRsc1BvbGljeRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSIAoL
ZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEkAKC2NyZWF0ZV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90
aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1l
ElkKBmxhYmVscxgFIAMoCzJBLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRh
MS5TZXJ2ZXJUbHNQb2xpY3kuTGFiZWxzRW50cnlSBmxhYmVscxIdCgphbGxvd19vcGVuGAYg
ASgIUglhbGxvd09wZW4SaAoSc2VydmVyX2NlcnRpZmljYXRlGAcgASgLMjkuZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkNlcnRpZmljYXRlUHJvdmlkZXJSEXNlcnZl
ckNlcnRpZmljYXRlEmEKC210bHNfcG9saWN5GAggASgLMkAuZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZWN1cml0eS52MWJldGExLlNlcnZlclRsc1BvbGljeS5NVExTUG9saWN5UgptdGxzUG9s
aWN5GnIKCk1UTFNQb2xpY3kSZAoUY2xpZW50X3ZhbGlkYXRpb25fY2EYASADKAsyMi5nb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuVmFsaWRhdGlvbkNBUhJjbGllbnRW
YWxpZGF0aW9uQ2EaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ATqCAepBfwoubmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29t
L1NlcnZlclRsc1BvbGljeRJNcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L3NlcnZlclRsc1BvbGljaWVzL3tzZXJ2ZXJfdGxzX3BvbGljeX0inQEKHExpc3RTZXJ2
ZXJUbHNQb2xpY2llc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9u
cy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVII
cGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIq4BCh1MaXN0U2VydmVy
VGxzUG9saWNpZXNSZXNwb25zZRJlChNzZXJ2ZXJfdGxzX3BvbGljaWVzGAEgAygLMjUuZ29v
Z2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLlNlcnZlclRsc1BvbGljeVIRc2Vy
dmVyVGxzUG9saWNpZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
ImcKGUdldFNlcnZlclRsc1BvbGljeVJlcXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5u
ZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmVyVGxzUG9saWN5UgRuYW1lIowC
ChxDcmVhdGVTZXJ2ZXJUbHNQb2xpY3lSZXF1ZXN0Ek4KBnBhcmVudBgBIAEoCUI24EEC+kEw
Ei5uZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vU2VydmVyVGxzUG9saWN5UgZwYXJl
bnQSNAoUc2VydmVyX3Rsc19wb2xpY3lfaWQYAiABKAlCA+BBAlIRc2VydmVyVGxzUG9saWN5
SWQSZgoRc2VydmVyX3Rsc19wb2xpY3kYAyABKAsyNS5nb29nbGUuY2xvdWQubmV0d29ya3Nl
Y3VyaXR5LnYxYmV0YTEuU2VydmVyVGxzUG9saWN5QgPgQQJSD3NlcnZlclRsc1BvbGljeSLI
AQocVXBkYXRlU2VydmVyVGxzUG9saWN5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJmChFzZXJ2ZXJf
dGxzX3BvbGljeRgCIAEoCzI1Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRh
MS5TZXJ2ZXJUbHNQb2xpY3lCA+BBAlIPc2VydmVyVGxzUG9saWN5ImoKHERlbGV0ZVNlcnZl
clRsc1BvbGljeVJlcXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5uZXR3b3Jrc2VjdXJp
dHkuZ29vZ2xlYXBpcy5jb20vU2VydmVyVGxzUG9saWN5UgRuYW1lQo4CCihjb20uZ29vZ2xl
LmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExQhRTZXJ2ZXJUbHNQb2xpY3lQcm90b1AB
WlJjbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZWN1cml0eS9hcGl2MWJldGExL25ldHdv
cmtzZWN1cml0eXBiO25ldHdvcmtzZWN1cml0eXBiqgIkR29vZ2xlLkNsb3VkLk5ldHdvcmtT
ZWN1cml0eS5WMUJldGExygIkR29vZ2xlXENsb3VkXE5ldHdvcmtTZWN1cml0eVxWMWJldGEx
6gInR29vZ2xlOjpDbG91ZDo6TmV0d29ya1NlY3VyaXR5OjpWMWJldGExSpkzCgcSBQ4AugEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMS
ACkKCQoCAwESAxMAIwoJCgIDAhIDFAA4CgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMY
AEEKCQoCCCUSAxgAQQoICgEIEgMZAGkKCQoCCAsSAxkAaQoICgEIEgMaACIKCQoCCAoSAxoA
IgoICgEIEgMbADUKCQoCCAgSAxsANQoICgEIEgMcAEEKCQoCCAESAxwAQQoICgEIEgMdAEEK
CQoCCCkSAx0AQQoICgEIEgMeAEAKCQoCCC0SAx4AQAr4AQoCBAASBCMAXAEa6wEgU2VydmVy
VGxzUG9saWN5IGlzIGEgcmVzb3VyY2UgdGhhdCBzcGVjaWZpZXMgaG93IGEgc2VydmVyIHNo
b3VsZCBhdXRoZW50aWNhdGUKIGluY29taW5nIHJlcXVlc3RzLiBUaGlzIHJlc291cmNlIGl0
c2VsZiBkb2VzIG5vdCBhZmZlY3QgY29uZmlndXJhdGlvbiB1bmxlc3MKIGl0IGlzIGF0dGFj
aGVkIHRvIGEgdGFyZ2V0IGh0dHBzIHByb3h5IG9yIGVuZHBvaW50IGNvbmZpZyBzZWxlY3Rv
ciByZXNvdXJjZS4KCgoKAwQAARIDIwgXCgsKAwQABxIEJAInBAoNCgUEAAedCBIEJAInBAow
CgQEAAMAEgQqAi8DGiIgU3BlY2lmaWNhdGlvbiBvZiB0aGUgTVRMU1BvbGljeS4KCgwKBQQA
AwABEgMqChQKfAoGBAADAAIAEgMuBDMabQogRGVmaW5lcyB0aGUgbWVjaGFuaXNtIHRvIG9i
dGFpbiB0aGUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IGNlcnRpZmljYXRlIHRvCiB2YWxpZGF0
ZSB0aGUgY2xpZW50IGNlcnRpZmljYXRlLgoKDgoHBAADAAIABBIDLgQMCg4KBwQAAwACAAYS
Ay4NGQoOCgcEAAMAAgABEgMuGi4KDgoHBAADAAIAAxIDLjEyCp8BCgQEAAIAEgMzAjsakQEg
UmVxdWlyZWQuIE5hbWUgb2YgdGhlIFNlcnZlclRsc1BvbGljeSByZXNvdXJjZS4gSXQgbWF0
Y2hlcyB0aGUgcGF0dGVybgogYHByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlvbn0vc2Vy
dmVyVGxzUG9saWNpZXMve3NlcnZlcl90bHNfcG9saWN5fWAKCgwKBQQAAgAFEgMzAggKDAoF
BAACAAESAzMJDQoMCgUEAAIAAxIDMxARCgwKBQQAAgAIEgMzEjoKDwoIBAACAAicCAASAzMT
OQo1CgQEAAIBEgM2AhkaKCBGcmVlLXRleHQgZGVzY3JpcHRpb24gb2YgdGhlIHJlc291cmNl
LgoKDAoFBAACAQUSAzYCCAoMCgUEAAIBARIDNgkUCgwKBQQAAgEDEgM2FxgKSQoEBAACAhIE
OQI6Mho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdh
cyBjcmVhdGVkLgoKDAoFBAACAgYSAzkCGwoMCgUEAAICARIDORwnCgwKBQQAAgIDEgM5KisK
DAoFBAACAggSAzoGMQoPCggEAAICCJwIABIDOgcwCkkKBAQAAgMSBD0CPjIaOyBPdXRwdXQg
b25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgdXBkYXRlZC4KCgwK
BQQAAgMGEgM9AhsKDAoFBAACAwESAz0cJwoMCgUEAAIDAxIDPSorCgwKBQQAAgMIEgM+BjEK
DwoIBAACAwicCAASAz4HMAo+CgQEAAIEEgNBAiEaMSBTZXQgb2YgbGFiZWwgdGFncyBhc3Nv
Y2lhdGVkIHdpdGggdGhlIHJlc291cmNlLgoKDAoFBAACBAYSA0ECFQoMCgUEAAIEARIDQRYc
CgwKBQQAAgQDEgNBHyAKkwQKBAQAAgUSA00CFhqFBAogRGV0ZXJtaW5lcyBpZiBzZXJ2ZXIg
YWxsb3dzIHBsYWludGV4dCBjb25uZWN0aW9ucy4gSWYgc2V0IHRvIHRydWUsIHNlcnZlcgog
YWxsb3dzIHBsYWluIHRleHQgY29ubmVjdGlvbnMuIEJ5IGRlZmF1bHQsIGl0IGlzIHNldCB0
byBmYWxzZS4gVGhpcyBzZXR0aW5nCiBpcyBub3QgZXhjbHVzaXZlIG9mIG90aGVyIGVuY3J5
cHRpb24gbW9kZXMuIEZvciBleGFtcGxlLCBpZiBgYWxsb3dfb3BlbmAKIGFuZCBgbXRsc19w
b2xpY3lgIGFyZSBzZXQsIHNlcnZlciBhbGxvd3MgYm90aCBwbGFpbiB0ZXh0IGFuZCBtVExT
CiBjb25uZWN0aW9ucy4gU2VlIGRvY3VtZW50YXRpb24gb2Ygb3RoZXIgZW5jcnlwdGlvbiBt
b2RlcyB0byBjb25maXJtCiBjb21wYXRpYmlsaXR5LgoKIENvbnNpZGVyIHVzaW5nIGl0IGlm
IHlvdSB3aXNoIHRvIHVwZ3JhZGUgaW4gcGxhY2UgeW91ciBkZXBsb3ltZW50IHRvIFRMUwog
d2hpbGUgaGF2aW5nIG1peGVkIFRMUyBhbmQgbm9uLVRMUyB0cmFmZmljIHJlYWNoaW5nIHBv
cnQgOjgwLgoKDAoFBAACBQUSA00CBgoMCgUEAAIFARIDTQcRCgwKBQQAAgUDEgNNFBUKzgEK
BAQAAgYSA1MCLRrAAQogRGVmaW5lcyBhIG1lY2hhbmlzbSB0byBwcm92aXNpb24gc2VydmVy
IGlkZW50aXR5IChwdWJsaWMgYW5kIHByaXZhdGUga2V5cykuCiBDYW5ub3QgYmUgY29tYmlu
ZWQgd2l0aCBgYWxsb3dfb3BlbmAgYXMgYSBwZXJtaXNzaXZlIG1vZGUgdGhhdCBhbGxvd3Mg
Ym90aAogcGxhaW4gdGV4dCBhbmQgVExTIGlzIG5vdCBzdXBwb3J0ZWQuCgoMCgUEAAIGBhID
UwIVCgwKBQQAAgYBEgNTFigKDAoFBAACBgMSA1MrLArRAgoEBAACBxIDWwIdGsMCCiBEZWZp
bmVzIGEgbWVjaGFuaXNtIHRvIHByb3Zpc2lvbiBwZWVyIHZhbGlkYXRpb24gY2VydGlmaWNh
dGVzIGZvciBwZWVyIHRvCiBwZWVyIGF1dGhlbnRpY2F0aW9uIChNdXR1YWwgVExTIC0gbVRM
UykuIElmIG5vdCBzcGVjaWZpZWQsIGNsaWVudAogY2VydGlmaWNhdGUgd2lsbCBub3QgYmUg
cmVxdWVzdGVkLiBUaGUgY29ubmVjdGlvbiBpcyB0cmVhdGVkIGFzIFRMUyBhbmQgbm90CiBt
VExTLiBJZiBgYWxsb3dfb3BlbmAgYW5kIGBtdGxzX3BvbGljeWAgYXJlIHNldCwgc2VydmVy
IGFsbG93cyBib3RoIHBsYWluCiB0ZXh0IGFuZCBtVExTIGNvbm5lY3Rpb25zLgoKDAoFBAAC
BwYSA1sCDAoMCgUEAAIHARIDWw0YCgwKBQQAAgcDEgNbGxwKPwoCBAESBF8AcQEaMyBSZXF1
ZXN0IHVzZWQgYnkgdGhlIExpc3RTZXJ2ZXJUbHNQb2xpY2llcyBtZXRob2QuCgoKCgMEAQES
A18IJAqiAQoEBAECABIEYgJnBBqTASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0
aW9uIGZyb20gd2hpY2ggdGhlIFNlcnZlclRsc1BvbGljaWVzIHNob3VsZAogYmUgbGlzdGVk
LCBzcGVjaWZpZWQgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMve2xvY2F0
aW9ufWAuCgoMCgUEAQIABRIDYgIICgwKBQQBAgABEgNiCQ8KDAoFBAECAAMSA2ISEwoNCgUE
AQIACBIEYhRnAwoPCggEAQIACJwIABIDYwQqCg8KBwQBAgAInwgSBGQEZgUKRgoEBAECARID
agIWGjkgTWF4aW11bSBudW1iZXIgb2YgU2VydmVyVGxzUG9saWNpZXMgdG8gcmV0dXJuIHBl
ciBjYWxsLgoKDAoFBAECAQUSA2oCBwoMCgUEAQIBARIDaggRCgwKBQQBAgEDEgNqFBUK2QEK
BAQBAgISA3ACGBrLASBUaGUgdmFsdWUgcmV0dXJuZWQgYnkgdGhlIGxhc3QgYExpc3RTZXJ2
ZXJUbHNQb2xpY2llc1Jlc3BvbnNlYAogSW5kaWNhdGVzIHRoYXQgdGhpcyBpcyBhIGNvbnRp
bnVhdGlvbiBvZiBhIHByaW9yCiBgTGlzdFNlcnZlclRsc1BvbGljaWVzYCBjYWxsLCBhbmQg
dGhhdCB0aGUgc3lzdGVtCiBzaG91bGQgcmV0dXJuIHRoZSBuZXh0IHBhZ2Ugb2YgZGF0YS4K
CgwKBQQBAgIFEgNwAggKDAoFBAECAgESA3AJEwoMCgUEAQICAxIDcBYXCkQKAgQCEgR0AHwB
GjggUmVzcG9uc2UgcmV0dXJuZWQgYnkgdGhlIExpc3RTZXJ2ZXJUbHNQb2xpY2llcyBtZXRo
b2QuCgoKCgMEAgESA3QIJQoxCgQEAgIAEgN2AjMaJCBMaXN0IG9mIFNlcnZlclRsc1BvbGlj
eSByZXNvdXJjZXMuCgoMCgUEAgIABBIDdgIKCgwKBQQCAgAGEgN2CxoKDAoFBAICAAESA3Yb
LgoMCgUEAgIAAxIDdjEyCugBCgQEAgIBEgN7Ah0a2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9y
ZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4K
IGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9m
IHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBg
bmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFnZV90b2tlbmAuCgoMCgUEAgIBBRIDewIICgwKBQQC
AgEBEgN7CRgKDAoFBAICAQMSA3sbHAo9CgIEAxIFfwCIAQEaMCBSZXF1ZXN0IHVzZWQgYnkg
dGhlIEdldFNlcnZlclRsc1BvbGljeSBtZXRob2QuCgoKCgMEAwESA38IIQqPAQoEBAMCABIG
ggEChwEEGn8gUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgU2VydmVyVGxzUG9saWN5IHRvIGdl
dC4gTXVzdCBiZSBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMve2xvY2F0
aW9ufS9zZXJ2ZXJUbHNQb2xpY2llcy8qYC4KCg0KBQQDAgAFEgSCAQIICg0KBQQDAgABEgSC
AQkNCg0KBQQDAgADEgSCARARCg8KBQQDAgAIEgaCARKHAQMKEAoIBAMCAAicCAASBIMBBCoK
EQoHBAMCAAifCBIGhAEEhgEFCkEKAgQEEgaLAQCeAQEaMyBSZXF1ZXN0IHVzZWQgYnkgdGhl
IENyZWF0ZVNlcnZlclRsc1BvbGljeSBtZXRob2QuCgoLCgMEBAESBIsBCCQKgQEKBAQEAgAS
Bo4BApMBBBpxIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBTZXJ2ZXJU
bHNQb2xpY3kuIE11c3QgYmUgaW4KIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25z
L3tsb2NhdGlvbn1gLgoKDQoFBAQCAAUSBI4BAggKDQoFBAQCAAESBI4BCQ8KDQoFBAQCAAMS
BI4BEhMKDwoFBAQCAAgSBo4BFJMBAwoQCggEBAIACJwIABIEjwEEKgoRCgcEBAIACJ8IEgaQ
AQSSAQUK/QEKBAQEAgESBJkBAksa7gEgUmVxdWlyZWQuIFNob3J0IG5hbWUgb2YgdGhlIFNl
cnZlclRsc1BvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLiBUaGlzCiB2YWx1ZSBzaG91
bGQgYmUgMS02MyBjaGFyYWN0ZXJzIGxvbmcsIGNvbnRhaW5pbmcgb25seSBsZXR0ZXJzLCBu
dW1iZXJzLAogaHlwaGVucywgYW5kIHVuZGVyc2NvcmVzLCBhbmQgc2hvdWxkIG5vdCBzdGFy
dCB3aXRoIGEgbnVtYmVyLiBFLmcuCiAic2VydmVyX210bHNfcG9saWN5Ii4KCg0KBQQEAgEF
EgSZAQIICg0KBQQEAgEBEgSZAQkdCg0KBQQEAgEDEgSZASAhCg0KBQQEAgEIEgSZASJKChAK
CAQEAgEInAgAEgSZASNJCkMKBAQEAgISBpwBAp0BLxozIFJlcXVpcmVkLiBTZXJ2ZXJUbHNQ
b2xpY3kgcmVzb3VyY2UgdG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgScAQIRCg0KBQQEAgIB
EgScARIjCg0KBQQEAgIDEgScASYnCg0KBQQEAgIIEgSdAQYuChAKCAQEAgIInAgAEgSdAQct
Cj0KAgQFEgahAQCuAQEaLyBSZXF1ZXN0IHVzZWQgYnkgVXBkYXRlU2VydmVyVGxzUG9saWN5
IG1ldGhvZC4KCgsKAwQFARIEoQEIJArjAgoEBAUCABIGqAECqQEvGtICIE9wdGlvbmFsLiBG
aWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0
dGVuIGluIHRoZQogU2VydmVyVGxzUG9saWN5IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuICBU
aGUgZmllbGRzCiBzcGVjaWZpZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0
byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJl
IG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZQogbWFzay4gSWYgdGhlIHVzZXIgZG9lcyBu
b3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHdpbGwgYmUKIG92ZXJ3cml0dGVu
LgoKDQoFBAUCAAYSBKgBAhsKDQoFBAUCAAESBKgBHCcKDQoFBAUCAAMSBKgBKisKDQoFBAUC
AAgSBKkBBi4KEAoIBAUCAAicCAASBKkBBy0KPQoEBAUCARIGrAECrQEvGi0gUmVxdWlyZWQu
IFVwZGF0ZWQgU2VydmVyVGxzUG9saWN5IHJlc291cmNlLgoKDQoFBAUCAQYSBKwBAhEKDQoF
BAUCAQESBKwBEiMKDQoFBAUCAQMSBKwBJicKDQoFBAUCAQgSBK0BBi4KEAoIBAUCAQicCAAS
BK0BBy0KQQoCBAYSBrEBALoBARozIFJlcXVlc3QgdXNlZCBieSB0aGUgRGVsZXRlU2VydmVy
VGxzUG9saWN5IG1ldGhvZC4KCgsKAwQGARIEsQEIJAqTAQoEBAYCABIGtAECuQEEGoIBIFJl
cXVpcmVkLiBBIG5hbWUgb2YgdGhlIFNlcnZlclRsc1BvbGljeSB0byBkZWxldGUuIE11c3Qg
YmUgaW4KIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlvbn0vc2Vy
dmVyVGxzUG9saWNpZXMvKmAuCgoNCgUEBgIABRIEtAECCAoNCgUEBgIAARIEtAEJDQoNCgUE
BgIAAxIEtAEQEQoPCgUEBgIACBIGtAESuQEDChAKCAQGAgAInAgAEgS1AQQqChEKBwQGAgAI
nwgSBrYBBLgBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy ===
    # Fields for ServerTlsPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1beta1.ServerTlsPolicy.LabelsEntry)
    # Field: allow_open Type: 8 ()
    # Field: server_certificate Type: 11 (.google.cloud.networksecurity.v1beta1.CertificateProvider)
    # Field: mtls_policy Type: 11 (.google.cloud.networksecurity.v1beta1.ServerTlsPolicy.MTLSPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ListServerTlsPoliciesRequest ===
    # Fields for ListServerTlsPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ListServerTlsPoliciesResponse ===
    # Fields for ListServerTlsPoliciesResponse
    # Field: server_tls_policies Type: 11 (.google.cloud.networksecurity.v1beta1.ServerTlsPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::GetServerTlsPolicyRequest ===
    # Fields for GetServerTlsPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::CreateServerTlsPolicyRequest ===
    # Fields for CreateServerTlsPolicyRequest
    # Field: parent Type: 9 ()
    # Field: server_tls_policy_id Type: 9 ()
    # Field: server_tls_policy Type: 11 (.google.cloud.networksecurity.v1beta1.ServerTlsPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::UpdateServerTlsPolicyRequest ===
    # Fields for UpdateServerTlsPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: server_tls_policy Type: 11 (.google.cloud.networksecurity.v1beta1.ServerTlsPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::DeleteServerTlsPolicyRequest ===
    # Fields for DeleteServerTlsPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/server_tls_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/server_tls_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy

ServerTlsPolicy is a resource that specifies how a server should authenticate
incoming requests. This resource itself does not affect configuration unless
it is attached to a target https proxy or endpoint config selector resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the ServerTlsPolicy resource. It matches the pattern
`projects/*/locations/{location}/serverTlsPolicies/{server_tls_policy}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Free-text description of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy::LabelsEntry>)

Set of label tags associated with the resource.

=item * C<< $msg->allow_open() >> / C<< $msg->allow_open($value) >>

Type: C<Bool>


Determines if server allows plaintext connections. If set to true, server
allows plain text connections. By default, it is set to false. This setting
is not exclusive of other encryption modes. For example, if `allow_open`
and `mtls_policy` are set, server allows both plain text and mTLS
connections. See documentation of other encryption modes to confirm
compatibility.

Consider using it if you wish to upgrade in place your deployment to TLS
while having mixed TLS and non-TLS traffic reaching port :80.

=item * C<< $msg->server_certificate() >> / C<< $msg->server_certificate($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProvider>)


Defines a mechanism to provision server identity (public and private keys).
Cannot be combined with `allow_open` as a permissive mode that allows both
plain text and TLS is not supported.

=item * C<< $msg->mtls_policy() >> / C<< $msg->mtls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy::MTLSPolicy>)


Defines a mechanism to provision peer validation certificates for peer to
peer authentication (Mutual TLS - mTLS). If not specified, client
certificate will not be requested. The connection is treated as TLS and not
mTLS. If `allow_open` and `mtls_policy` are set, server allows both plain
text and mTLS connections.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ListServerTlsPoliciesRequest

Request used by the ListServerTlsPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the ServerTlsPolicies should
be listed, specified in the format `projects/*/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of ServerTlsPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListServerTlsPoliciesResponse`
Indicates that this is a continuation of a prior
`ListServerTlsPolicies` call, and that the system
should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ListServerTlsPoliciesResponse

Response returned by the ListServerTlsPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->server_tls_policies() >> / C<< $msg->server_tls_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy>)

List of ServerTlsPolicy resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::GetServerTlsPolicyRequest

Request used by the GetServerTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ServerTlsPolicy to get. Must be in the format
`projects/*/locations/{location}/serverTlsPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::CreateServerTlsPolicyRequest

Request used by the CreateServerTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the ServerTlsPolicy. Must be in
the format `projects/*/locations/{location}`.

=item * C<< $msg->server_tls_policy_id() >> / C<< $msg->server_tls_policy_id($value) >>

Type: C<String>

Required. Short name of the ServerTlsPolicy resource to be created. This
value should be 1-63 characters long, containing only letters, numbers,
hyphens, and underscores, and should not start with a number. E.g.
"server_mtls_policy".

=item * C<< $msg->server_tls_policy() >> / C<< $msg->server_tls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy>)

Required. ServerTlsPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::UpdateServerTlsPolicyRequest

Request used by UpdateServerTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
ServerTlsPolicy resource by the update.  The fields
specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the
mask. If the user does not provide a mask then all fields will be
overwritten.

=item * C<< $msg->server_tls_policy() >> / C<< $msg->server_tls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy>)

Required. Updated ServerTlsPolicy resource.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::DeleteServerTlsPolicyRequest

Request used by the DeleteServerTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ServerTlsPolicy to delete. Must be in
the format `projects/*/locations/{location}/serverTlsPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
