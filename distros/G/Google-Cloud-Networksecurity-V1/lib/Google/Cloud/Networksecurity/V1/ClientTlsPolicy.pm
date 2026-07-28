package Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Networksecurity::V1::Tls };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL2NsaWVudF90bHNfcG9saWN5LnBy
b3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGilnb29nbGUvY2xv
dWQvbmV0d29ya3NlY3VyaXR5L3YxL3Rscy5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxk
X21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1wUKD0NsaWVu
dFRsc1BvbGljeRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiAB
KAlCA+BBAVILZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSWQoGbGFiZWxz
GAUgAygLMjwuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MS5DbGllbnRUbHNQb2xp
Y3kuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEhUKA3NuaRgGIAEoCUID4EEBUgNzbmkSaAoS
Y2xpZW50X2NlcnRpZmljYXRlGAcgASgLMjQuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0
eS52MS5DZXJ0aWZpY2F0ZVByb3ZpZGVyQgPgQQFSEWNsaWVudENlcnRpZmljYXRlEmQKFHNl
cnZlcl92YWxpZGF0aW9uX2NhGAggAygLMi0uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0
eS52MS5WYWxpZGF0aW9uQ0FCA+BBAVISc2VydmVyVmFsaWRhdGlvbkNhGjkKC0xhYmVsc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6ggHqQX8K
Lm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbS9DbGllbnRUbHNQb2xpY3kSTXByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbGllbnRUbHNQb2xpY2llcy97
Y2xpZW50X3Rsc19wb2xpY3l9Ip0BChxMaXN0Q2xpZW50VGxzUG9saWNpZXNSZXF1ZXN0EkEK
BnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRp
b25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
AyABKAlSCXBhZ2VUb2tlbiKpAQodTGlzdENsaWVudFRsc1BvbGljaWVzUmVzcG9uc2USYAoT
Y2xpZW50X3Rsc19wb2xpY2llcxgBIAMoCzIwLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJp
dHkudjEuQ2xpZW50VGxzUG9saWN5UhFjbGllbnRUbHNQb2xpY2llcxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iZwoZR2V0Q2xpZW50VGxzUG9saWN5UmVxdWVz
dBJKCgRuYW1lGAEgASgJQjbgQQL6QTAKLm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNv
bS9DbGllbnRUbHNQb2xpY3lSBG5hbWUihwIKHENyZWF0ZUNsaWVudFRsc1BvbGljeVJlcXVl
c3QSTgoGcGFyZW50GAEgASgJQjbgQQL6QTASLm5ldHdvcmtzZWN1cml0eS5nb29nbGVhcGlz
LmNvbS9DbGllbnRUbHNQb2xpY3lSBnBhcmVudBI0ChRjbGllbnRfdGxzX3BvbGljeV9pZBgC
IAEoCUID4EECUhFjbGllbnRUbHNQb2xpY3lJZBJhChFjbGllbnRfdGxzX3BvbGljeRgDIAEo
CzIwLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuQ2xpZW50VGxzUG9saWN5QgPg
QQJSD2NsaWVudFRsc1BvbGljeSLDAQocVXBkYXRlQ2xpZW50VGxzUG9saWN5UmVxdWVzdBJA
Cgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIK
dXBkYXRlTWFzaxJhChFjbGllbnRfdGxzX3BvbGljeRgCIAEoCzIwLmdvb2dsZS5jbG91ZC5u
ZXR3b3Jrc2VjdXJpdHkudjEuQ2xpZW50VGxzUG9saWN5QgPgQQJSD2NsaWVudFRsc1BvbGlj
eSJqChxEZWxldGVDbGllbnRUbHNQb2xpY3lSZXF1ZXN0EkoKBG5hbWUYASABKAlCNuBBAvpB
MAoubmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGljeVIEbmFt
ZUL1AQojY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFCFENsaWVudFRsc1Bv
bGljeVByb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya3NlY3VyaXR5L2FwaXYx
L25ldHdvcmtzZWN1cml0eXBiO25ldHdvcmtzZWN1cml0eXBiqgIfR29vZ2xlLkNsb3VkLk5l
dHdvcmtTZWN1cml0eS5WMcoCH0dvb2dsZVxDbG91ZFxOZXR3b3JrU2VjdXJpdHlcVjHqAiJH
b29nbGU6OkNsb3VkOjpOZXR3b3JrU2VjdXJpdHk6OlYxSvwtCgcSBQ4AqAEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwES
AxMAIwoJCgIDAhIDFAAzCgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYADwKCQoCCCUS
AxgAPAoICgEIEgMZAGQKCQoCCAsSAxkAZAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMb
ADUKCQoCCAgSAxsANQoICgEIEgMcADwKCQoCCAESAxwAPAoICgEIEgMdADwKCQoCCCkSAx0A
PAoICgEIEgMeADsKCQoCCC0SAx4AOwrsAQoCBAASBCMASgEa3wEgQ2xpZW50VGxzUG9saWN5
IGlzIGEgcmVzb3VyY2UgdGhhdCBzcGVjaWZpZXMgaG93IGEgY2xpZW50IHNob3VsZCBhdXRo
ZW50aWNhdGUKIGNvbm5lY3Rpb25zIHRvIGJhY2tlbmRzIG9mIGEgc2VydmljZS4gVGhpcyBy
ZXNvdXJjZSBpdHNlbGYgZG9lcyBub3QgYWZmZWN0CiBjb25maWd1cmF0aW9uIHVubGVzcyBp
dCBpcyBhdHRhY2hlZCB0byBhIGJhY2tlbmQgc2VydmljZSByZXNvdXJjZS4KCgoKAwQAARID
IwgXCgsKAwQABxIEJAInBAoNCgUEAAedCBIEJAInBAqnAQoEBAACABIDKwI7GpkBIFJlcXVp
cmVkLiBOYW1lIG9mIHRoZSBDbGllbnRUbHNQb2xpY3kgcmVzb3VyY2UuIEl0IG1hdGNoZXMg
dGhlIHBhdHRlcm4KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Y2xpZW50VGxzUG9saWNpZXMve2NsaWVudF90bHNfcG9saWN5fWAKCgwKBQQAAgAFEgMrAggK
DAoFBAACAAESAysJDQoMCgUEAAIAAxIDKxARCgwKBQQAAgAIEgMrEjoKDwoIBAACAAicCAAS
AysTOQo/CgQEAAIBEgMuAkIaMiBPcHRpb25hbC4gRnJlZS10ZXh0IGRlc2NyaXB0aW9uIG9m
IHRoZSByZXNvdXJjZS4KCgwKBQQAAgEFEgMuAggKDAoFBAACAQESAy4JFAoMCgUEAAIBAxID
LhcYCgwKBQQAAgEIEgMuGUEKDwoIBAACAQicCAASAy4aQApJCgQEAAICEgQxAjIyGjsgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgcmVzb3VyY2Ugd2FzIGNyZWF0ZWQu
CgoMCgUEAAICBhIDMQIbCgwKBQQAAgIBEgMxHCcKDAoFBAACAgMSAzEqKwoMCgUEAAICCBID
MgYxCg8KCAQAAgIInAgAEgMyBzAKSQoEBAACAxIENQI2Mho7IE91dHB1dCBvbmx5LiBUaGUg
dGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdhcyB1cGRhdGVkLgoKDAoFBAACAwYSAzUC
GwoMCgUEAAIDARIDNRwnCgwKBQQAAgMDEgM1KisKDAoFBAACAwgSAzYGMQoPCggEAAIDCJwI
ABIDNgcwCkgKBAQAAgQSAzkCSho7IE9wdGlvbmFsLiBTZXQgb2YgbGFiZWwgdGFncyBhc3Nv
Y2lhdGVkIHdpdGggdGhlIHJlc291cmNlLgoKDAoFBAACBAYSAzkCFQoMCgUEAAIEARIDORYc
CgwKBQQAAgQDEgM5HyAKDAoFBAACBAgSAzkhSQoPCggEAAIECJwIABIDOSJICoEBCgQEAAIF
EgM9AjoadCBPcHRpb25hbC4gU2VydmVyIE5hbWUgSW5kaWNhdGlvbiBzdHJpbmcgdG8gcHJl
c2VudCB0byB0aGUgc2VydmVyIGR1cmluZyBUTFMKIGhhbmRzaGFrZS4gRS5nOiAic2VjdXJl
LmV4YW1wbGUuY29tIi4KCgwKBQQAAgUFEgM9AggKDAoFBAACBQESAz0JDAoMCgUEAAIFAxID
PQ8QCgwKBQQAAgUIEgM9ETkKDwoIBAACBQicCAASAz0SOAqsAQoEBAACBhIEQgJDLxqdASBP
cHRpb25hbC4gRGVmaW5lcyBhIG1lY2hhbmlzbSB0byBwcm92aXNpb24gY2xpZW50IGlkZW50
aXR5IChwdWJsaWMgYW5kCiBwcml2YXRlIGtleXMpIGZvciBwZWVyIHRvIHBlZXIgYXV0aGVu
dGljYXRpb24uIFRoZSBwcmVzZW5jZSBvZiB0aGlzCiBkaWN0YXRlcyBtVExTLgoKDAoFBAAC
BgYSA0ICFQoMCgUEAAIGARIDQhYoCgwKBQQAAgYDEgNCKywKDAoFBAACBggSA0MGLgoPCggE
AAIGCJwIABIDQwctCsEBCgQEAAIHEgRIAkkvGrIBIE9wdGlvbmFsLiBEZWZpbmVzIHRoZSBt
ZWNoYW5pc20gdG8gb2J0YWluIHRoZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkKIGNlcnRpZmlj
YXRlIHRvIHZhbGlkYXRlIHRoZSBzZXJ2ZXIgY2VydGlmaWNhdGUuIElmIGVtcHR5LCBjbGll
bnQgZG9lcyBub3QKIHZhbGlkYXRlIHRoZSBzZXJ2ZXIgY2VydGlmaWNhdGUuCgoMCgUEAAIH
BBIDSAIKCgwKBQQAAgcGEgNICxcKDAoFBAACBwESA0gYLAoMCgUEAAIHAxIDSC8wCgwKBQQA
AgcIEgNJBi4KDwoIBAACBwicCAASA0kHLQo/CgIEARIETQBfARozIFJlcXVlc3QgdXNlZCBi
eSB0aGUgTGlzdENsaWVudFRsc1BvbGljaWVzIG1ldGhvZC4KCgoKAwQBARIDTQgkCqIBCgQE
AQIAEgRQAlUEGpMBIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3
aGljaCB0aGUgQ2xpZW50VGxzUG9saWNpZXMgc2hvdWxkCiBiZSBsaXN0ZWQsIHNwZWNpZmll
ZCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy97bG9jYXRpb259YC4KCgwK
BQQBAgAFEgNQAggKDAoFBAECAAESA1AJDwoMCgUEAQIAAxIDUBITCg0KBQQBAgAIEgRQFFUD
Cg8KCAQBAgAInAgAEgNRBCoKDwoHBAECAAifCBIEUgRUBQpGCgQEAQIBEgNYAhYaOSBNYXhp
bXVtIG51bWJlciBvZiBDbGllbnRUbHNQb2xpY2llcyB0byByZXR1cm4gcGVyIGNhbGwuCgoM
CgUEAQIBBRIDWAIHCgwKBQQBAgEBEgNYCBEKDAoFBAECAQMSA1gUFQrZAQoEBAECAhIDXgIY
GssBIFRoZSB2YWx1ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBgTGlzdENsaWVudFRsc1BvbGlj
aWVzUmVzcG9uc2VgCiBJbmRpY2F0ZXMgdGhhdCB0aGlzIGlzIGEgY29udGludWF0aW9uIG9m
IGEgcHJpb3IKIGBMaXN0Q2xpZW50VGxzUG9saWNpZXNgIGNhbGwsIGFuZCB0aGF0IHRoZSBz
eXN0ZW0KIHNob3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBkYXRhLgoKDAoFBAECAgUS
A14CCAoMCgUEAQICARIDXgkTCgwKBQQBAgIDEgNeFhcKRAoCBAISBGIAagEaOCBSZXNwb25z
ZSByZXR1cm5lZCBieSB0aGUgTGlzdENsaWVudFRsc1BvbGljaWVzIG1ldGhvZC4KCgoKAwQC
ARIDYgglCjEKBAQCAgASA2QCMxokIExpc3Qgb2YgQ2xpZW50VGxzUG9saWN5IHJlc291cmNl
cy4KCgwKBQQCAgAEEgNkAgoKDAoFBAICAAYSA2QLGgoMCgUEAgIAARIDZBsuCgwKBQQCAgAD
EgNkMTIK6AEKBAQCAgESA2kCHRraASBJZiB0aGVyZSBtaWdodCBiZSBtb3JlIHJlc3VsdHMg
dGhhbiB0aG9zZSBhcHBlYXJpbmcgaW4gdGhpcyByZXNwb25zZSwgdGhlbgogYG5leHRfcGFn
ZV90b2tlbmAgaXMgaW5jbHVkZWQuIFRvIGdldCB0aGUgbmV4dCBzZXQgb2YgcmVzdWx0cywg
Y2FsbCB0aGlzCiBtZXRob2QgYWdhaW4gdXNpbmcgdGhlIHZhbHVlIG9mIGBuZXh0X3BhZ2Vf
dG9rZW5gIGFzIGBwYWdlX3Rva2VuYC4KCgwKBQQCAgEFEgNpAggKDAoFBAICAQESA2kJGAoM
CgUEAgIBAxIDaRscCjwKAgQDEgRtAHYBGjAgUmVxdWVzdCB1c2VkIGJ5IHRoZSBHZXRDbGll
bnRUbHNQb2xpY3kgbWV0aG9kLgoKCgoDBAMBEgNtCCEKjQEKBAQDAgASBHACdQQafyBSZXF1
aXJlZC4gQSBuYW1lIG9mIHRoZSBDbGllbnRUbHNQb2xpY3kgdG8gZ2V0LiBNdXN0IGJlIGlu
IHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy97bG9jYXRpb259L2NsaWVudFRs
c1BvbGljaWVzLypgLgoKDAoFBAMCAAUSA3ACCAoMCgUEAwIAARIDcAkNCgwKBQQDAgADEgNw
EBEKDQoFBAMCAAgSBHASdQMKDwoIBAMCAAicCAASA3EEKgoPCgcEAwIACJ8IEgRyBHQFCkAK
AgQEEgV5AIwBARozIFJlcXVlc3QgdXNlZCBieSB0aGUgQ3JlYXRlQ2xpZW50VGxzUG9saWN5
IG1ldGhvZC4KCgoKAwQEARIDeQgkCoABCgQEBAIAEgV8AoEBBBpxIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIG9mIHRoZSBDbGllbnRUbHNQb2xpY3kuIE11c3QgYmUgaW4KIHRo
ZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDAoFBAQCAAUS
A3wCCAoMCgUEBAIAARIDfAkPCgwKBQQEAgADEgN8EhMKDgoFBAQCAAgSBXwUgQEDCg8KCAQE
AgAInAgAEgN9BCoKEAoHBAQCAAifCBIFfgSAAQUK/QEKBAQEAgESBIcBAksa7gEgUmVxdWly
ZWQuIFNob3J0IG5hbWUgb2YgdGhlIENsaWVudFRsc1BvbGljeSByZXNvdXJjZSB0byBiZSBj
cmVhdGVkLiBUaGlzCiB2YWx1ZSBzaG91bGQgYmUgMS02MyBjaGFyYWN0ZXJzIGxvbmcsIGNv
bnRhaW5pbmcgb25seSBsZXR0ZXJzLCBudW1iZXJzLAogaHlwaGVucywgYW5kIHVuZGVyc2Nv
cmVzLCBhbmQgc2hvdWxkIG5vdCBzdGFydCB3aXRoIGEgbnVtYmVyLiBFLmcuCiAiY2xpZW50
X210bHNfcG9saWN5Ii4KCg0KBQQEAgEFEgSHAQIICg0KBQQEAgEBEgSHAQkdCg0KBQQEAgED
EgSHASAhCg0KBQQEAgEIEgSHASJKChAKCAQEAgEInAgAEgSHASNJCkMKBAQEAgISBooBAosB
LxozIFJlcXVpcmVkLiBDbGllbnRUbHNQb2xpY3kgcmVzb3VyY2UgdG8gYmUgY3JlYXRlZC4K
Cg0KBQQEAgIGEgSKAQIRCg0KBQQEAgIBEgSKARIjCg0KBQQEAgIDEgSKASYnCg0KBQQEAgII
EgSLAQYuChAKCAQEAgIInAgAEgSLAQctCj0KAgQFEgaPAQCcAQEaLyBSZXF1ZXN0IHVzZWQg
YnkgVXBkYXRlQ2xpZW50VGxzUG9saWN5IG1ldGhvZC4KCgsKAwQFARIEjwEIJArjAgoEBAUC
ABIGlgEClwEvGtICIE9wdGlvbmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0
aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogQ2xpZW50VGxzUG9saWN5IHJl
c291cmNlIGJ5IHRoZSB1cGRhdGUuICBUaGUgZmllbGRzCiBzcGVjaWZpZWQgaW4gdGhlIHVw
ZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwg
cmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRoZQog
bWFzay4gSWYgdGhlIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwgZmll
bGRzIHdpbGwgYmUKIG92ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBJYBAhsKDQoFBAUCAAESBJYB
HCcKDQoFBAUCAAMSBJYBKisKDQoFBAUCAAgSBJcBBi4KEAoIBAUCAAicCAASBJcBBy0KPQoE
BAUCARIGmgECmwEvGi0gUmVxdWlyZWQuIFVwZGF0ZWQgQ2xpZW50VGxzUG9saWN5IHJlc291
cmNlLgoKDQoFBAUCAQYSBJoBAhEKDQoFBAUCAQESBJoBEiMKDQoFBAUCAQMSBJoBJicKDQoF
BAUCAQgSBJsBBi4KEAoIBAUCAQicCAASBJsBBy0KQQoCBAYSBp8BAKgBARozIFJlcXVlc3Qg
dXNlZCBieSB0aGUgRGVsZXRlQ2xpZW50VGxzUG9saWN5IG1ldGhvZC4KCgsKAwQGARIEnwEI
JAqTAQoEBAYCABIGogECpwEEGoIBIFJlcXVpcmVkLiBBIG5hbWUgb2YgdGhlIENsaWVudFRs
c1BvbGljeSB0byBkZWxldGUuIE11c3QgYmUgaW4KIHRoZSBmb3JtYXQgYHByb2plY3RzLyov
bG9jYXRpb25zL3tsb2NhdGlvbn0vY2xpZW50VGxzUG9saWNpZXMvKmAuCgoNCgUEBgIABRIE
ogECCAoNCgUEBgIAARIEogEJDQoNCgUEBgIAAxIEogEQEQoPCgUEBgIACBIGogESpwEDChAK
CAQGAgAInAgAEgSjAQQqChEKBwQGAgAInwgSBqQBBKYBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy ===
    # Fields for ClientTlsPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy.LabelsEntry)
    # Field: sni Type: 9 ()
    # Field: client_certificate Type: 11 (.google.cloud.networksecurity.v1.CertificateProvider)
    # Field: server_validation_ca Type: 11 (.google.cloud.networksecurity.v1.ValidationCA)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<description>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<labels>

Type: Message (.google.cloud.networksecurity.v1.ClientTlsPolicy.LabelsEntry)

=item * B<sni>

Type: String

=item * B<client_certificate>

Type: Message (.google.cloud.networksecurity.v1.CertificateProvider)

=item * B<server_validation_ca>

Type: Message (.google.cloud.networksecurity.v1.ValidationCA)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest ===
    # Fields for ListClientTlsPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse ===
    # Fields for ListClientTlsPoliciesResponse
    # Field: client_tls_policies Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse->new(
        client_tls_policies => $value,
    );

=head1 FIELDS

=over 4

=item * B<client_tls_policies>

Type: Message (.google.cloud.networksecurity.v1.ClientTlsPolicy)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest ===
    # Fields for GetClientTlsPolicyRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest ===
    # Fields for CreateClientTlsPolicyRequest
    # Field: parent Type: 9 ()
    # Field: client_tls_policy_id Type: 9 ()
    # Field: client_tls_policy Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<client_tls_policy_id>

Type: String

=item * B<client_tls_policy>

Type: Message (.google.cloud.networksecurity.v1.ClientTlsPolicy)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest ===
    # Fields for UpdateClientTlsPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: client_tls_policy Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<client_tls_policy>

Type: Message (.google.cloud.networksecurity.v1.ClientTlsPolicy)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest ===
    # Fields for DeleteClientTlsPolicyRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
