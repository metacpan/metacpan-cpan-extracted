package Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

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

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest ===
    # Fields for ListClientTlsPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse ===
    # Fields for ListClientTlsPoliciesResponse
    # Field: client_tls_policies Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest ===
    # Fields for GetClientTlsPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest ===
    # Fields for CreateClientTlsPolicyRequest
    # Field: parent Type: 9 ()
    # Field: client_tls_policy_id Type: 9 ()
    # Field: client_tls_policy Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy)

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest ===
    # Fields for UpdateClientTlsPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: client_tls_policy Type: 11 (.google.cloud.networksecurity.v1.ClientTlsPolicy)

# === Message: Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest ===
    # Fields for DeleteClientTlsPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1/client_tls_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1/client_tls_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy

ClientTlsPolicy is a resource that specifies how a client should authenticate
connections to backends of a service. This resource itself does not affect
configuration unless it is attached to a backend service resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the ClientTlsPolicy resource. It matches the pattern
`projects/{project}/locations/{location}/clientTlsPolicies/{client_tls_policy}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy::LabelsEntry>)

Optional. Set of label tags associated with the resource.

=item * C<< $msg->sni() >> / C<< $msg->sni($value) >>

Type: C<String>

Optional. Server Name Indication string to present to the server during TLS
handshake. E.g: "secure.example.com".

=item * C<< $msg->client_certificate() >> / C<< $msg->client_certificate($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::Tls::CertificateProvider>)

Optional. Defines a mechanism to provision client identity (public and
private keys) for peer to peer authentication. The presence of this
dictates mTLS.

=item * C<< $msg->server_validation_ca() >> / C<< $msg->server_validation_ca($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::Tls::ValidationCA>)

Optional. Defines the mechanism to obtain the Certificate Authority
certificate to validate the server certificate. If empty, client does not
validate the server certificate.

=back

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest

Request used by the ListClientTlsPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the ClientTlsPolicies should
be listed, specified in the format `projects/*/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of ClientTlsPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListClientTlsPoliciesResponse`
Indicates that this is a continuation of a prior
`ListClientTlsPolicies` call, and that the system
should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse

Response returned by the ListClientTlsPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_tls_policies() >> / C<< $msg->client_tls_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy>)

List of ClientTlsPolicy resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=back

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest

Request used by the GetClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ClientTlsPolicy to get. Must be in the format
`projects/*/locations/{location}/clientTlsPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest

Request used by the CreateClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the ClientTlsPolicy. Must be in
the format `projects/*/locations/{location}`.

=item * C<< $msg->client_tls_policy_id() >> / C<< $msg->client_tls_policy_id($value) >>

Type: C<String>

Required. Short name of the ClientTlsPolicy resource to be created. This
value should be 1-63 characters long, containing only letters, numbers,
hyphens, and underscores, and should not start with a number. E.g.
"client_mtls_policy".

=item * C<< $msg->client_tls_policy() >> / C<< $msg->client_tls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy>)

Required. ClientTlsPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest

Request used by UpdateClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
ClientTlsPolicy resource by the update.  The fields
specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the
mask. If the user does not provide a mask then all fields will be
overwritten.

=item * C<< $msg->client_tls_policy() >> / C<< $msg->client_tls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy>)

Required. Updated ClientTlsPolicy resource.

=back

=head2 Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest

Request used by the DeleteClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ClientTlsPolicy to delete. Must be in
the format `projects/*/locations/{location}/clientTlsPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1::ClientTlsPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
