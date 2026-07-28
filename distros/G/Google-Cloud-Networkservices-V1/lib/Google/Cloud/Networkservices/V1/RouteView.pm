package Google::Cloud::Networkservices::V1::RouteView;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL3JvdXRlX3ZpZXcucHJvdG8SH2dv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ihgMKEEdhdGV3YXlSb3V0ZVZp
ZXcSGgoEbmFtZRgBIAEoCUIG4EED4EEIUgRuYW1lEjUKFHJvdXRlX3Byb2plY3RfbnVtYmVy
GAIgASgDQgPgQQNSEnJvdXRlUHJvamVjdE51bWJlchIqCg5yb3V0ZV9sb2NhdGlvbhgDIAEo
CUID4EEDUg1yb3V0ZUxvY2F0aW9uEiIKCnJvdXRlX3R5cGUYBCABKAlCA+BBA1IJcm91dGVU
eXBlEh4KCHJvdXRlX2lkGAUgASgJQgPgQQNSB3JvdXRlSWQ6rgHqQaoBCi9uZXR3b3Jrc2Vy
dmljZXMuZ29vZ2xlYXBpcy5jb20vR2F0ZXdheVJvdXRlVmlldxJScHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2dhdGV3YXlzL3tnYXRld2F5fS9yb3V0ZVZpZXdz
L3tyb3V0ZV92aWV3fSoRZ2F0ZXdheVJvdXRlVmlld3MyEGdhdGV3YXlSb3V0ZVZpZXci9QIK
DU1lc2hSb3V0ZVZpZXcSGgoEbmFtZRgBIAEoCUIG4EED4EEIUgRuYW1lEjUKFHJvdXRlX3By
b2plY3RfbnVtYmVyGAIgASgDQgPgQQNSEnJvdXRlUHJvamVjdE51bWJlchIqCg5yb3V0ZV9s
b2NhdGlvbhgDIAEoCUID4EEDUg1yb3V0ZUxvY2F0aW9uEiIKCnJvdXRlX3R5cGUYBCABKAlC
A+BBA1IJcm91dGVUeXBlEh4KCHJvdXRlX2lkGAUgASgJQgPgQQNSB3JvdXRlSWQ6oAHqQZwB
CixuZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vTWVzaFJvdXRlVmlldxJNcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L21lc2hlcy97bWVzaH0vcm91dGVW
aWV3cy97cm91dGVfdmlld30qDm1lc2hSb3V0ZVZpZXdzMg1tZXNoUm91dGVWaWV3ImkKGkdl
dEdhdGV3YXlSb3V0ZVZpZXdSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovbmV0d29y
a3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0dhdGV3YXlSb3V0ZVZpZXdSBG5hbWUiYwoXR2V0
TWVzaFJvdXRlVmlld1JlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixuZXR3b3Jrc2Vy
dmljZXMuZ29vZ2xlYXBpcy5jb20vTWVzaFJvdXRlVmlld1IEbmFtZSKrAQocTGlzdEdhdGV3
YXlSb3V0ZVZpZXdzUmVxdWVzdBJPCgZwYXJlbnQYASABKAlCN+BBAvpBMRIvbmV0d29ya3Nl
cnZpY2VzLmdvb2dsZWFwaXMuY29tL0dhdGV3YXlSb3V0ZVZpZXdSBnBhcmVudBIbCglwYWdl
X3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKl
AQoZTGlzdE1lc2hSb3V0ZVZpZXdzUmVxdWVzdBJMCgZwYXJlbnQYASABKAlCNOBBAvpBLhIs
bmV0d29ya3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL01lc2hSb3V0ZVZpZXdSBnBhcmVudBIb
CglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VU
b2tlbiLMAQodTGlzdEdhdGV3YXlSb3V0ZVZpZXdzUmVzcG9uc2USYQoTZ2F0ZXdheV9yb3V0
ZV92aWV3cxgBIAMoCzIxLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuR2F0ZXdh
eVJvdXRlVmlld1IRZ2F0ZXdheVJvdXRlVmlld3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
Ug1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSLAAQoa
TGlzdE1lc2hSb3V0ZVZpZXdzUmVzcG9uc2USWAoQbWVzaF9yb3V0ZV92aWV3cxgBIAMoCzIu
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuTWVzaFJvdXRlVmlld1IObWVzaFJv
dXRlVmlld3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3Vu
cmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZULvAQojY29tLmdvb2dsZS5jbG91ZC5uZXR3
b3Jrc2VydmljZXMudjFCDlJvdXRlVmlld1Byb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28v
bmV0d29ya3NlcnZpY2VzL2FwaXYxL25ldHdvcmtzZXJ2aWNlc3BiO25ldHdvcmtzZXJ2aWNl
c3BiqgIfR29vZ2xlLkNsb3VkLk5ldHdvcmtTZXJ2aWNlcy5WMcoCH0dvb2dsZVxDbG91ZFxO
ZXR3b3JrU2VydmljZXNcVjHqAiJHb29nbGU6OkNsb3VkOjpOZXR3b3JrU2VydmljZXM6OlYx
SvUuCgcSBQ4AuQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADwKCQoCCCUSAxUAPAoICgEIEgMW
AGQKCQoCCAsSAxYAZAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC8KCQoCCAgSAxgA
LwoICgEIEgMZADwKCQoCCAESAxkAPAoICgEIEgMaADwKCQoCCCkSAxoAPAoICgEIEgMbADsK
CQoCCC0SAxsAOwpRCgIEABIEHgA5ARpFIEdhdGV3YXlSb3V0ZVZpZXcgZGVmaW5lcyB2aWV3
LW9ubHkgcmVzb3VyY2UgZm9yIFJvdXRlcyB0byBhIEdhdGV3YXkKCgoKAwQAARIDHggYCgsK
AwQABxIEHwIkBAoNCgUEAAedCBIEHwIkBArAAQoEBAACABIEKQIsBBqxASBPdXRwdXQgb25s
eS4gSWRlbnRpZmllci4gRnVsbCBwYXRoIG5hbWUgb2YgdGhlIEdhdGV3YXlSb3V0ZVZpZXcg
cmVzb3VyY2UuCiBGb3JtYXQ6CiAgIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vZ2F0ZXdheXMve2dhdGV3YXl9L3JvdXRlVmlld3Mve3JvdXRlX3Zp
ZXd9CgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoNCgUEAAIA
CBIEKRIsAwoPCggEAAIACJwIABIDKgQtCg8KCAQAAgAInAgBEgMrBCwKQgoEBAACARIDLwJN
GjUgT3V0cHV0IG9ubHkuIFByb2plY3QgbnVtYmVyIHdoZXJlIHRoZSByb3V0ZSBleGlzdHMu
CgoMCgUEAAIBBRIDLwIHCgwKBQQAAgEBEgMvCBwKDAoFBAACAQMSAy8fIAoMCgUEAAIBCBID
LyFMCg8KCAQAAgEInAgAEgMvIksKPAoEBAACAhIDMgJIGi8gT3V0cHV0IG9ubHkuIExvY2F0
aW9uIHdoZXJlIHRoZSByb3V0ZSBleGlzdHMuCgoMCgUEAAICBRIDMgIICgwKBQQAAgIBEgMy
CRcKDAoFBAACAgMSAzIaGwoMCgUEAAICCBIDMhxHCg8KCAQAAgIInAgAEgMyHUYKWAoEBAAC
AxIDNQJEGksgT3V0cHV0IG9ubHkuIFR5cGUgb2YgdGhlIHJvdXRlOiBIdHRwUm91dGUsR3Jw
Y1JvdXRlLFRjcFJvdXRlLCBvciBUbHNSb3V0ZQoKDAoFBAACAwUSAzUCCAoMCgUEAAIDARID
NQkTCgwKBQQAAgMDEgM1FhcKDAoFBAACAwgSAzUYQwoPCggEAAIDCJwIABIDNRlCCjoKBAQA
AgQSAzgCQhotIE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgaWQgZm9yIHRoZSByb3V0ZS4K
CgwKBQQAAgQFEgM4AggKDAoFBAACBAESAzgJEQoMCgUEAAIEAxIDOBQVCgwKBQQAAgQIEgM4
FkEKDwoIBAACBAicCAASAzgXQApLCgIEARIEPABXARo/IE1lc2hSb3V0ZVZpZXcgZGVmaW5l
cyB2aWV3LW9ubHkgcmVzb3VyY2UgZm9yIFJvdXRlcyB0byBhIE1lc2gKCgoKAwQBARIDPAgV
CgsKAwQBBxIEPQJCBAoNCgUEAQedCBIEPQJCBAqxAQoEBAECABIERwJKBBqiASBPdXRwdXQg
b25seS4gSWRlbnRpZmllci4gRnVsbCBwYXRoIG5hbWUgb2YgdGhlIE1lc2hSb3V0ZVZpZXcg
cmVzb3VyY2UuCiBGb3JtYXQ6CiAgIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9tZXNoZXMve21lc2h9L3JvdXRlVmlld3Mve3JvdXRlX3ZpZXd9CgoMCgUEAQIA
BRIDRwIICgwKBQQBAgABEgNHCQ0KDAoFBAECAAMSA0cQEQoNCgUEAQIACBIERxJKAwoPCggE
AQIACJwIABIDSAQtCg8KCAQBAgAInAgBEgNJBCwKQgoEBAECARIDTQJNGjUgT3V0cHV0IG9u
bHkuIFByb2plY3QgbnVtYmVyIHdoZXJlIHRoZSByb3V0ZSBleGlzdHMuCgoMCgUEAQIBBRID
TQIHCgwKBQQBAgEBEgNNCBwKDAoFBAECAQMSA00fIAoMCgUEAQIBCBIDTSFMCg8KCAQBAgEI
nAgAEgNNIksKPAoEBAECAhIDUAJIGi8gT3V0cHV0IG9ubHkuIExvY2F0aW9uIHdoZXJlIHRo
ZSByb3V0ZSBleGlzdHMuCgoMCgUEAQICBRIDUAIICgwKBQQBAgIBEgNQCRcKDAoFBAECAgMS
A1AaGwoMCgUEAQICCBIDUBxHCg8KCAQBAgIInAgAEgNQHUYKWAoEBAECAxIDUwJEGksgT3V0
cHV0IG9ubHkuIFR5cGUgb2YgdGhlIHJvdXRlOiBIdHRwUm91dGUsR3JwY1JvdXRlLFRjcFJv
dXRlLCBvciBUbHNSb3V0ZQoKDAoFBAECAwUSA1MCCAoMCgUEAQIDARIDUwkTCgwKBQQBAgMD
EgNTFhcKDAoFBAECAwgSA1MYQwoPCggEAQIDCJwIABIDUxlCCjoKBAQBAgQSA1YCQhotIE91
dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgaWQgZm9yIHRoZSByb3V0ZS4KCgwKBQQBAgQFEgNW
AggKDAoFBAECBAESA1YJEQoMCgUEAQIEAxIDVhQVCgwKBQQBAgQIEgNWFkEKDwoIBAECBAic
CAASA1YXQAo/CgIEAhIEWgBkARozIFJlcXVlc3QgdXNlZCB3aXRoIHRoZSBHZXRHYXRld2F5
Um91dGVWaWV3IG1ldGhvZC4KCgoKAwQCARIDWggiCqEBCgQEAgIAEgReAmMEGpIBIFJlcXVp
cmVkLiBOYW1lIG9mIHRoZSBHYXRld2F5Um91dGVWaWV3IHJlc291cmNlLgogRm9ybWF0czoK
ICAgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2dhdGV3YXlzL3tn
YXRld2F5fS9yb3V0ZVZpZXdzL3tyb3V0ZV92aWV3fQoKDAoFBAICAAUSA14CCAoMCgUEAgIA
ARIDXgkNCgwKBQQCAgADEgNeEBEKDQoFBAICAAgSBF4SYwMKDwoIBAICAAicCAASA18EKgoP
CgcEAgIACJ8IEgRgBGIFCjwKAgQDEgRnAHEBGjAgUmVxdWVzdCB1c2VkIHdpdGggdGhlIEdl
dE1lc2hSb3V0ZVZpZXcgbWV0aG9kLgoKCgoDBAMBEgNnCB8KmAEKBAQDAgASBGsCcAQaiQEg
UmVxdWlyZWQuIE5hbWUgb2YgdGhlIE1lc2hSb3V0ZVZpZXcgcmVzb3VyY2UuCiBGb3JtYXQ6
CiAgIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tZXNoZXMve21l
c2h9L3JvdXRlVmlld3Mve3JvdXRlX3ZpZXd9CgoMCgUEAwIABRIDawIICgwKBQQDAgABEgNr
CQ0KDAoFBAMCAAMSA2sQEQoNCgUEAwIACBIEaxJwAwoPCggEAwIACJwIABIDbAQqCg8KBwQD
AgAInwgSBG0EbwUKQgoCBAQSBXQAhgEBGjUgUmVxdWVzdCB1c2VkIHdpdGggdGhlIExpc3RH
YXRld2F5Um91dGVWaWV3cyBtZXRob2QuCgoKCgMEBAESA3QIJAqNAQoEBAQCABIEeAJ9BBp/
IFJlcXVpcmVkLiBUaGUgR2F0ZXdheSB0byB3aGljaCBhIFJvdXRlIGlzIGFzc29jaWF0ZWQu
CiBGb3JtYXRzOgogICBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Z2F0ZXdheXMve2dhdGV3YXl9CgoMCgUEBAIABRIDeAIICgwKBQQEAgABEgN4CQ8KDAoFBAQC
AAMSA3gSEwoNCgUEBAIACBIEeBR9AwoPCggEBAIACJwIABIDeQQqCg8KBwQEAgAInwgSBHoE
fAUKRwoEBAQCARIEgAECFho5IE1heGltdW0gbnVtYmVyIG9mIEdhdGV3YXlSb3V0ZVZpZXdz
IHRvIHJldHVybiBwZXIgY2FsbC4KCg0KBQQEAgEFEgSAAQIHCg0KBQQEAgEBEgSAAQgRCg0K
BQQEAgEDEgSAARQVCtkBCgQEBAICEgSFAQIYGsoBIFRoZSB2YWx1ZSByZXR1cm5lZCBieSB0
aGUgbGFzdCBgTGlzdEdhdGV3YXlSb3V0ZVZpZXdzUmVzcG9uc2VgCiBJbmRpY2F0ZXMgdGhh
dCB0aGlzIGlzIGEgY29udGludWF0aW9uIG9mIGEgcHJpb3IgYExpc3RHYXRld2F5Um91dGVW
aWV3c2AKIGNhbGwsIGFuZCB0aGF0IHRoZSBzeXN0ZW0gc2hvdWxkIHJldHVybiB0aGUgbmV4
dCBwYWdlIG9mIGRhdGEuCgoNCgUEBAICBRIEhQECCAoNCgUEBAICARIEhQEJEwoNCgUEBAIC
AxIEhQEWFwpACgIEBRIGiQEAmwEBGjIgUmVxdWVzdCB1c2VkIHdpdGggdGhlIExpc3RNZXNo
Um91dGVWaWV3cyBtZXRob2QuCgoLCgMEBQESBIkBCCEKhgEKBAQFAgASBo0BApIBBBp2IFJl
cXVpcmVkLiBUaGUgTWVzaCB0byB3aGljaCBhIFJvdXRlIGlzIGFzc29jaWF0ZWQuCiBGb3Jt
YXQ6CiAgIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tZXNoZXMv
e21lc2h9CgoNCgUEBQIABRIEjQECCAoNCgUEBQIAARIEjQEJDwoNCgUEBQIAAxIEjQESEwoP
CgUEBQIACBIGjQEUkgEDChAKCAQFAgAInAgAEgSOAQQqChEKBwQFAgAInwgSBo8BBJEBBQpE
CgQEBQIBEgSVAQIWGjYgTWF4aW11bSBudW1iZXIgb2YgTWVzaFJvdXRlVmlld3MgdG8gcmV0
dXJuIHBlciBjYWxsLgoKDQoFBAUCAQUSBJUBAgcKDQoFBAUCAQESBJUBCBEKDQoFBAUCAQMS
BJUBFBUK0wEKBAQFAgISBJoBAhgaxAEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0
IGBMaXN0TWVzaFJvdXRlVmlld3NSZXNwb25zZWAKIEluZGljYXRlcyB0aGF0IHRoaXMgaXMg
YSBjb250aW51YXRpb24gb2YgYSBwcmlvciBgTGlzdE1lc2hSb3V0ZVZpZXdzYCBjYWxsLAog
YW5kIHRoYXQgdGhlIHN5c3RlbSBzaG91bGQgcmV0dXJuIHRoZSBuZXh0IHBhZ2Ugb2YgZGF0
YS4KCg0KBQQFAgIFEgSaAQIICg0KBQQFAgIBEgSaAQkTCg0KBQQFAgIDEgSaARYXCkYKAgQG
EgaeAQCqAQEaOCBSZXNwb25zZSByZXR1cm5lZCBieSB0aGUgTGlzdEdhdGV3YXlSb3V0ZVZp
ZXdzIG1ldGhvZC4KCgsKAwQGARIEngEIJQozCgQEBgIAEgSgAQI0GiUgTGlzdCBvZiBHYXRl
d2F5Um91dGVWaWV3IHJlc291cmNlcy4KCg0KBQQGAgAEEgSgAQIKCg0KBQQGAgAGEgSgAQsb
Cg0KBQQGAgABEgSgARwvCg0KBQQGAgADEgSgATIzCpABCgQEBgIBEgSkAQIdGoEBIEEgdG9r
ZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vi
c2VxdWVudCBwYWdlcy4KCg0KBQQGAgEFEgSkAQIICg0KBQQGAgEBEgSkAQkYCg0KBQQGAgED
EgSkARscCrUBCgQEBgICEgSpAQIiGqYBIFVucmVhY2hhYmxlIHJlc291cmNlcy4gUG9wdWxh
dGVkIHdoZW4gdGhlIHJlcXVlc3QgYXR0ZW1wdHMgdG8gbGlzdCBhbGwKIHJlc291cmNlcyBh
Y3Jvc3MgYWxsIHN1cHBvcnRlZCBsb2NhdGlvbnMsIHdoaWxlIHNvbWUgbG9jYXRpb25zIGFy
ZQogdGVtcG9yYXJpbHkgdW5hdmFpbGFibGUuCgoNCgUEBgICBBIEqQECCgoNCgUEBgICBRIE
qQELEQoNCgUEBgICARIEqQESHQoNCgUEBgICAxIEqQEgIQpDCgIEBxIGrQEAuQEBGjUgUmVz
cG9uc2UgcmV0dXJuZWQgYnkgdGhlIExpc3RNZXNoUm91dGVWaWV3cyBtZXRob2QuCgoLCgME
BwESBK0BCCIKMAoEBAcCABIErwECLhoiIExpc3Qgb2YgTWVzaFJvdXRlVmlldyByZXNvdXJj
ZXMuCgoNCgUEBwIABBIErwECCgoNCgUEBwIABhIErwELGAoNCgUEBwIAARIErwEZKQoNCgUE
BwIAAxIErwEsLQqQAQoEBAcCARIEswECHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2Vu
dCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMg
ZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUE
BwIBBRIEswECCAoNCgUEBwIBARIEswEJGAoNCgUEBwIBAxIEswEbHAq1AQoEBAcCAhIEuAEC
IhqmASBVbnJlYWNoYWJsZSByZXNvdXJjZXMuIFBvcHVsYXRlZCB3aGVuIHRoZSByZXF1ZXN0
IGF0dGVtcHRzIHRvIGxpc3QgYWxsCiByZXNvdXJjZXMgYWNyb3NzIGFsbCBzdXBwb3J0ZWQg
bG9jYXRpb25zLCB3aGlsZSBzb21lIGxvY2F0aW9ucyBhcmUKIHRlbXBvcmFyaWx5IHVuYXZh
aWxhYmxlLgoKDQoFBAcCAgQSBLgBAgoKDQoFBAcCAgUSBLgBCxEKDQoFBAcCAgESBLgBEh0K
DQoFBAcCAgMSBLgBICFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::RouteView::GatewayRouteView ===
    # Fields for GatewayRouteView
    # Field: name Type: 9 ()
    # Field: route_project_number Type: 3 ()
    # Field: route_location Type: 9 ()
    # Field: route_type Type: 9 ()
    # Field: route_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::GatewayRouteView - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::GatewayRouteView->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<route_project_number>

Type: Int64

=item * B<route_location>

Type: String

=item * B<route_type>

Type: String

=item * B<route_id>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::RouteView::MeshRouteView ===
    # Fields for MeshRouteView
    # Field: name Type: 9 ()
    # Field: route_project_number Type: 3 ()
    # Field: route_location Type: 9 ()
    # Field: route_type Type: 9 ()
    # Field: route_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::MeshRouteView - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::MeshRouteView->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<route_project_number>

Type: Int64

=item * B<route_location>

Type: String

=item * B<route_type>

Type: String

=item * B<route_id>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::RouteView::GetGatewayRouteViewRequest ===
    # Fields for GetGatewayRouteViewRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::GetGatewayRouteViewRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::GetGatewayRouteViewRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::RouteView::GetMeshRouteViewRequest ===
    # Fields for GetMeshRouteViewRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::GetMeshRouteViewRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::GetMeshRouteViewRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsRequest ===
    # Fields for ListGatewayRouteViewsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsRequest->new(
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

# === Message: Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsRequest ===
    # Fields for ListMeshRouteViewsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsRequest->new(
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

# === Message: Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsResponse ===
    # Fields for ListGatewayRouteViewsResponse
    # Field: gateway_route_views Type: 11 (.google.cloud.networkservices.v1.GatewayRouteView)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsResponse->new(
        gateway_route_views => $value,
    );

=head1 FIELDS

=over 4

=item * B<gateway_route_views>

Type: Message (.google.cloud.networkservices.v1.GatewayRouteView)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsResponse ===
    # Fields for ListMeshRouteViewsResponse
    # Field: mesh_route_views Type: 11 (.google.cloud.networkservices.v1.MeshRouteView)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::RouteView;

    my $msg = Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsResponse->new(
        mesh_route_views => $value,
    );

=head1 FIELDS

=over 4

=item * B<mesh_route_views>

Type: Message (.google.cloud.networkservices.v1.MeshRouteView)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
