package Google::Cloud::Essentialcontacts::V1::Service;

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
    eval { require Google::Cloud::Essentialcontacts::V1::Enums };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZXNzZW50aWFsY29udGFjdHMvdjEvc2VydmljZS5wcm90bxIhZ29v
Z2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3RzLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxotZ29vZ2xlL2Nsb3VkL2Vz
c2VudGlhbGNvbnRhY3RzL3YxL2VudW1zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIscECgdDb250YWN0EhcKBG5hbWUYASABKAlCA+BBA1IEbmFt
ZRIZCgVlbWFpbBgCIAEoCUID4EECUgVlbWFpbBKMAQojbm90aWZpY2F0aW9uX2NhdGVnb3J5
X3N1YnNjcmlwdGlvbnMYAyADKA4yNy5nb29nbGUuY2xvdWQuZXNzZW50aWFsY29udGFjdHMu
djEuTm90aWZpY2F0aW9uQ2F0ZWdvcnlCA+BBAlIhbm90aWZpY2F0aW9uQ2F0ZWdvcnlTdWJz
Y3JpcHRpb25zEiYKDGxhbmd1YWdlX3RhZxgEIAEoCUID4EECUgtsYW5ndWFnZVRhZxJiChB2
YWxpZGF0aW9uX3N0YXRlGAggASgOMjIuZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3Rz
LnYxLlZhbGlkYXRpb25TdGF0ZUID4EEDUg92YWxpZGF0aW9uU3RhdGUSPwoNdmFsaWRhdGVf
dGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDHZhbGlkYXRlVGltZTqr
AepBpwEKKGVzc2VudGlhbGNvbnRhY3RzLmdvb2dsZWFwaXMuY29tL0NvbnRhY3QSJXByb2pl
Y3RzL3twcm9qZWN0fS9jb250YWN0cy97Y29udGFjdH0SI2ZvbGRlcnMve2ZvbGRlcn0vY29u
dGFjdHMve2NvbnRhY3R9Ei9vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2NvbnRhY3Rz
L3tjb250YWN0fSKlAQoTTGlzdENvbnRhY3RzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBB
AvpBKhIoZXNzZW50aWFsY29udGFjdHMuZ29vZ2xlYXBpcy5jb20vQ29udGFjdFIGcGFyZW50
EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJ
QgPgQQFSCXBhZ2VUb2tlbiKGAQoUTGlzdENvbnRhY3RzUmVzcG9uc2USRgoIY29udGFjdHMY
ASADKAsyKi5nb29nbGUuY2xvdWQuZXNzZW50aWFsY29udGFjdHMudjEuQ29udGFjdFIIY29u
dGFjdHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlkKEUdldENv
bnRhY3RSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgooZXNzZW50aWFsY29udGFjdHMu
Z29vZ2xlYXBpcy5jb20vQ29udGFjdFIEbmFtZSJcChREZWxldGVDb250YWN0UmVxdWVzdBJE
CgRuYW1lGAEgASgJQjDgQQL6QSoKKGVzc2VudGlhbGNvbnRhY3RzLmdvb2dsZWFwaXMuY29t
L0NvbnRhY3RSBG5hbWUiqwEKFENyZWF0ZUNvbnRhY3RSZXF1ZXN0EkgKBnBhcmVudBgBIAEo
CUIw4EEC+kEqEihlc3NlbnRpYWxjb250YWN0cy5nb29nbGVhcGlzLmNvbS9Db250YWN0UgZw
YXJlbnQSSQoHY29udGFjdBgCIAEoCzIqLmdvb2dsZS5jbG91ZC5lc3NlbnRpYWxjb250YWN0
cy52MS5Db250YWN0QgPgQQJSB2NvbnRhY3QiowEKFFVwZGF0ZUNvbnRhY3RSZXF1ZXN0EkkK
B2NvbnRhY3QYAiABKAsyKi5nb29nbGUuY2xvdWQuZXNzZW50aWFsY29udGFjdHMudjEuQ29u
dGFjdEID4EECUgdjb250YWN0EkAKC3VwZGF0ZV9tYXNrGAMgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrIpoCChZDb21wdXRlQ29udGFjdHNSZXF1
ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqEihlc3NlbnRpYWxjb250YWN0cy5nb29nbGVh
cGlzLmNvbS9Db250YWN0UgZwYXJlbnQScAoXbm90aWZpY2F0aW9uX2NhdGVnb3JpZXMYBiAD
KA4yNy5nb29nbGUuY2xvdWQuZXNzZW50aWFsY29udGFjdHMudjEuTm90aWZpY2F0aW9uQ2F0
ZWdvcnlSFm5vdGlmaWNhdGlvbkNhdGVnb3JpZXMSIAoJcGFnZV9zaXplGAMgASgFQgPgQQFS
CHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YBCABKAlCA+BBAVIJcGFnZVRva2VuIokBChdDb21w
dXRlQ29udGFjdHNSZXNwb25zZRJGCghjb250YWN0cxgBIAMoCzIqLmdvb2dsZS5jbG91ZC5l
c3NlbnRpYWxjb250YWN0cy52MS5Db250YWN0Ughjb250YWN0cxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4ipwIKFlNlbmRUZXN0TWVzc2FnZVJlcXVlc3QSTAoI
Y29udGFjdHMYASADKAlCMOBBAvpBKgooZXNzZW50aWFsY29udGFjdHMuZ29vZ2xlYXBpcy5j
b20vQ29udGFjdFIIY29udGFjdHMSTAoIcmVzb3VyY2UYAiABKAlCMOBBAvpBKhIoZXNzZW50
aWFsY29udGFjdHMuZ29vZ2xlYXBpcy5jb20vQ29udGFjdFIIcmVzb3VyY2UScQoVbm90aWZp
Y2F0aW9uX2NhdGVnb3J5GAMgASgOMjcuZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3Rz
LnYxLk5vdGlmaWNhdGlvbkNhdGVnb3J5QgPgQQJSFG5vdGlmaWNhdGlvbkNhdGVnb3J5MssP
ChhFc3NlbnRpYWxDb250YWN0c1NlcnZpY2USmAIKDUNyZWF0ZUNvbnRhY3QSNy5nb29nbGUu
Y2xvdWQuZXNzZW50aWFsY29udGFjdHMudjEuQ3JlYXRlQ29udGFjdFJlcXVlc3QaKi5nb29n
bGUuY2xvdWQuZXNzZW50aWFsY29udGFjdHMudjEuQ29udGFjdCKhAYLT5JMCiQEiIC92MS97
cGFyZW50PXByb2plY3RzLyp9L2NvbnRhY3RzOgdjb250YWN0WioiHy92MS97cGFyZW50PWZv
bGRlcnMvKn0vY29udGFjdHM6B2NvbnRhY3RaMCIlL3YxL3twYXJlbnQ9b3JnYW5pemF0aW9u
cy8qfS9jb250YWN0czoHY29udGFjdNpBDnBhcmVudCxjb250YWN0ErUCCg1VcGRhdGVDb250
YWN0EjcuZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3RzLnYxLlVwZGF0ZUNvbnRhY3RS
ZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3RzLnYxLkNvbnRhY3QivgGC
0+STAqEBMigvdjEve2NvbnRhY3QubmFtZT1wcm9qZWN0cy8qL2NvbnRhY3RzLyp9Ogdjb250
YWN0WjIyJy92MS97Y29udGFjdC5uYW1lPWZvbGRlcnMvKi9jb250YWN0cy8qfToHY29udGFj
dFo4Mi0vdjEve2NvbnRhY3QubmFtZT1vcmdhbml6YXRpb25zLyovY29udGFjdHMvKn06B2Nv
bnRhY3TaQRNjb250YWN0LHVwZGF0ZV9tYXNrEv4BCgxMaXN0Q29udGFjdHMSNi5nb29nbGUu
Y2xvdWQuZXNzZW50aWFsY29udGFjdHMudjEuTGlzdENvbnRhY3RzUmVxdWVzdBo3Lmdvb2ds
ZS5jbG91ZC5lc3NlbnRpYWxjb250YWN0cy52MS5MaXN0Q29udGFjdHNSZXNwb25zZSJ9gtPk
kwJuEiAvdjEve3BhcmVudD1wcm9qZWN0cy8qfS9jb250YWN0c1ohEh8vdjEve3BhcmVudD1m
b2xkZXJzLyp9L2NvbnRhY3RzWicSJS92MS97cGFyZW50PW9yZ2FuaXphdGlvbnMvKn0vY29u
dGFjdHPaQQZwYXJlbnQS6wEKCkdldENvbnRhY3QSNC5nb29nbGUuY2xvdWQuZXNzZW50aWFs
Y29udGFjdHMudjEuR2V0Q29udGFjdFJlcXVlc3QaKi5nb29nbGUuY2xvdWQuZXNzZW50aWFs
Y29udGFjdHMudjEuQ29udGFjdCJ7gtPkkwJuEiAvdjEve25hbWU9cHJvamVjdHMvKi9jb250
YWN0cy8qfVohEh8vdjEve25hbWU9Zm9sZGVycy8qL2NvbnRhY3RzLyp9WicSJS92MS97bmFt
ZT1vcmdhbml6YXRpb25zLyovY29udGFjdHMvKn3aQQRuYW1lEt0BCg1EZWxldGVDb250YWN0
EjcuZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3RzLnYxLkRlbGV0ZUNvbnRhY3RSZXF1
ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5InuC0+STAm4qIC92MS97bmFtZT1wcm9qZWN0
cy8qL2NvbnRhY3RzLyp9WiEqHy92MS97bmFtZT1mb2xkZXJzLyovY29udGFjdHMvKn1aJyol
L3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9jb250YWN0cy8qfdpBBG5hbWUSmAIKD0NvbXB1
dGVDb250YWN0cxI5Lmdvb2dsZS5jbG91ZC5lc3NlbnRpYWxjb250YWN0cy52MS5Db21wdXRl
Q29udGFjdHNSZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3RzLnYxLkNv
bXB1dGVDb250YWN0c1Jlc3BvbnNlIo0BgtPkkwKGARIoL3YxL3twYXJlbnQ9cHJvamVjdHMv
Kn0vY29udGFjdHM6Y29tcHV0ZVopEicvdjEve3BhcmVudD1mb2xkZXJzLyp9L2NvbnRhY3Rz
OmNvbXB1dGVaLxItL3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qfS9jb250YWN0czpjb21w
dXRlEpsCCg9TZW5kVGVzdE1lc3NhZ2USOS5nb29nbGUuY2xvdWQuZXNzZW50aWFsY29udGFj
dHMudjEuU2VuZFRlc3RNZXNzYWdlUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSK0
AYLT5JMCrQEiMi92MS97cmVzb3VyY2U9cHJvamVjdHMvKn0vY29udGFjdHM6c2VuZFRlc3RN
ZXNzYWdlOgEqWjYiMS92MS97cmVzb3VyY2U9Zm9sZGVycy8qfS9jb250YWN0czpzZW5kVGVz
dE1lc3NhZ2U6ASpaPCI3L3YxL3tyZXNvdXJjZT1vcmdhbml6YXRpb25zLyp9L2NvbnRhY3Rz
OnNlbmRUZXN0TWVzc2FnZToBKhpUykEgZXNzZW50aWFsY29udGFjdHMuZ29vZ2xlYXBpcy5j
b23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQu0B
CiVjb20uZ29vZ2xlLmNsb3VkLmVzc2VudGlhbGNvbnRhY3RzLnYxUAFaU2Nsb3VkLmdvb2ds
ZS5jb20vZ28vZXNzZW50aWFsY29udGFjdHMvYXBpdjEvZXNzZW50aWFsY29udGFjdHNwYjtl
c3NlbnRpYWxjb250YWN0c3BiqgIhR29vZ2xlLkNsb3VkLkVzc2VudGlhbENvbnRhY3RzLlYx
ygIhR29vZ2xlXENsb3VkXEVzc2VudGlhbENvbnRhY3RzXFYx6gIkR29vZ2xlOjpDbG91ZDo6
RXNzZW50aWFsQ29udGFjdHM6OlYxSvxPCgcSBQ4A2AIBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAApCgkKAgMDEgMVACMKCQoCAwQSAxYANwoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCQoCAwcS
AxkAKQoICgEIEgMbAD4KCQoCCCUSAxsAPgoICgEIEgMcAGoKCQoCCAsSAxwAagoICgEIEgMd
ACIKCQoCCAoSAx0AIgoICgEIEgMeAD4KCQoCCAESAx4APgoICgEIEgMfAD4KCQoCCCkSAx8A
PgoICgEIEgMgAD0KCQoCCC0SAyAAPQpJCgIGABIFIwCHAQEaPCBNYW5hZ2VzIGNvbnRhY3Rz
IGZvciBpbXBvcnRhbnQgR29vZ2xlIENsb3VkIG5vdGlmaWNhdGlvbnMuCgoKCgMGAAESAyMI
IAoKCgMGAAMSAyQCSAoMCgUGAAOZCBIDJAJICgsKAwYAAxIEJQImNwoNCgUGAAOaCBIEJQIm
NwoyCgQGAAIAEgQpAjcDGiQgQWRkcyBhIG5ldyBjb250YWN0IGZvciBhIHJlc291cmNlLgoK
DAoFBgACAAESAykGEwoMCgUGAAIAAhIDKRQoCgwKBQYAAgADEgMpMzoKDQoFBgACAAQSBCoE
NQYKEQoJBgACAASwyrwiEgQqBDUGCgwKBQYAAgAEEgM2BDwKDwoIBgACAASbCAASAzYEPApW
CgQGAAIBEgQ7AkkDGkggVXBkYXRlcyBhIGNvbnRhY3QuCiBOb3RlOiBBIGNvbnRhY3QncyBl
bWFpbCBhZGRyZXNzIGNhbm5vdCBiZSBjaGFuZ2VkLgoKDAoFBgACAQESAzsGEwoMCgUGAAIB
AhIDOxQoCgwKBQYAAgEDEgM7MzoKDQoFBgACAQQSBDwERwYKEQoJBgACAQSwyrwiEgQ8BEcG
CgwKBQYAAgEEEgNIBEEKDwoIBgACAQSbCAASA0gEQQpECgQGAAICEgRMAlMDGjYgTGlzdHMg
dGhlIGNvbnRhY3RzIHRoYXQgaGF2ZSBiZWVuIHNldCBvbiBhIHJlc291cmNlLgoKDAoFBgAC
AgESA0wGEgoMCgUGAAICAhIDTBMmCgwKBQYAAgIDEgNMMUUKDQoFBgACAgQSBE0EUQYKEQoJ
BgACAgSwyrwiEgRNBFEGCgwKBQYAAgIEEgNSBDQKDwoIBgACAgSbCAASA1IENAomCgQGAAID
EgRWAl0DGhggR2V0cyBhIHNpbmdsZSBjb250YWN0LgoKDAoFBgACAwESA1YGEAoMCgUGAAID
AhIDVhEiCgwKBQYAAgMDEgNWLTQKDQoFBgACAwQSBFcEWwYKEQoJBgACAwSwyrwiEgRXBFsG
CgwKBQYAAgMEEgNcBDIKDwoIBgACAwSbCAASA1wEMgoiCgQGAAIEEgRgAmcDGhQgRGVsZXRl
cyBhIGNvbnRhY3QuCgoMCgUGAAIEARIDYAYTCgwKBQYAAgQCEgNgFCgKDAoFBgACBAMSA2Az
SAoNCgUGAAIEBBIEYQRlBgoRCgkGAAIEBLDKvCISBGEEZQYKDAoFBgACBAQSA2YEMgoPCggG
AAIEBJsIABIDZgQyCqwBCgQGAAIFEgRsAnUDGp0BIExpc3RzIGFsbCBjb250YWN0cyBmb3Ig
dGhlIHJlc291cmNlIHRoYXQgYXJlIHN1YnNjcmliZWQgdG8gdGhlCiBzcGVjaWZpZWQgbm90
aWZpY2F0aW9uIGNhdGVnb3JpZXMsIGluY2x1ZGluZyBjb250YWN0cyBpbmhlcml0ZWQgZnJv
bQogYW55IHBhcmVudCByZXNvdXJjZXMuCgoMCgUGAAIFARIDbAYVCgwKBQYAAgUCEgNsFiwK
DAoFBgACBQMSA20PJgoNCgUGAAIFBBIEbgR0BgoRCgkGAAIFBLDKvCISBG4EdAYKewoEBgAC
BhIFeQKGAQMabCBBbGxvd3MgYSBjb250YWN0IGFkbWluIHRvIHNlbmQgYSB0ZXN0IG1lc3Nh
Z2UgdG8gY29udGFjdCB0byB2ZXJpZnkgdGhhdCBpdAogaGFzIGJlZW4gY29uZmlndXJlZCBj
b3JyZWN0bHkuCgoMCgUGAAIGARIDeQYVCgwKBQYAAgYCEgN5FiwKDAoFBgACBgMSA3k3TAoO
CgUGAAIGBBIFegSFAQYKEgoJBgACBgSwyrwiEgV6BIUBBgpMCgIEABIGigEArgEBGj4gQSBj
b250YWN0IHRoYXQgd2lsbCByZWNlaXZlIG5vdGlmaWNhdGlvbnMgZnJvbSBHb29nbGUgQ2xv
dWQuCgoLCgMEAAESBIoBCA8KDQoDBAAHEgaLAQKQAQQKDwoFBAAHnQgSBosBApABBAp5CgQE
AAIAEgSUAQI+GmsgT3V0cHV0IG9ubHkuIFRoZSBpZGVudGlmaWVyIGZvciB0aGUgY29udGFj
dC4KIEZvcm1hdDoge3Jlc291cmNlX3R5cGV9L3tyZXNvdXJjZV9pZH0vY29udGFjdHMve2Nv
bnRhY3RfaWR9CgoNCgUEAAIABRIElAECCAoNCgUEAAIAARIElAEJDQoNCgUEAAIAAxIElAEQ
EQoNCgUEAAIACBIElAESPQoQCggEAAIACJwIABIElAETPAp+CgQEAAIBEgSYAQI8GnAgUmVx
dWlyZWQuIFRoZSBlbWFpbCBhZGRyZXNzIHRvIHNlbmQgbm90aWZpY2F0aW9ucyB0by4gVGhl
IGVtYWlsIGFkZHJlc3MKIGRvZXMgbm90IG5lZWQgdG8gYmUgYSBHb29nbGUgQWNjb3VudC4K
Cg0KBQQAAgEFEgSYAQIICg0KBQQAAgEBEgSYAQkOCg0KBQQAAgEDEgSYARESCg0KBQQAAgEI
EgSYARM7ChAKCAQAAgEInAgAEgSYARQ6Cm4KBAQAAgISBpwBAp0BLxpeIFJlcXVpcmVkLiBU
aGUgY2F0ZWdvcmllcyBvZiBub3RpZmljYXRpb25zIHRoYXQgdGhlIGNvbnRhY3Qgd2lsbCBy
ZWNlaXZlCiBjb21tdW5pY2F0aW9ucyBmb3IuCgoNCgUEAAICBBIEnAECCgoNCgUEAAICBhIE
nAELHwoNCgUEAAICARIEnAEgQwoNCgUEAAICAxIEnAFGRwoNCgUEAAICCBIEnQEGLgoQCggE
AAICCJwIABIEnQEHLQqFAgoEBAACAxIEowECQxr2ASBSZXF1aXJlZC4gVGhlIHByZWZlcnJl
ZCBsYW5ndWFnZSBmb3Igbm90aWZpY2F0aW9ucywgYXMgYSBJU08gNjM5LTEgbGFuZ3VhZ2UK
IGNvZGUuIFNlZSBbU3VwcG9ydGVkCiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvbWFuYWdpbmctbm90aWZpY2F0aW9uLWNvbnRh
Y3RzI3N1cHBvcnRlZC1sYW5ndWFnZXMpCiBmb3IgYSBsaXN0IG9mIHN1cHBvcnRlZCBsYW5n
dWFnZXMuCgoNCgUEAAIDBRIEowECCAoNCgUEAAIDARIEowEJFQoNCgUEAAIDAxIEowEYGQoN
CgUEAAIDCBIEowEaQgoQCggEAAIDCJwIABIEowEbQQqnAQoEBAACBBIGpwECqAEyGpYBIE91
dHB1dCBvbmx5LiBUaGUgdmFsaWRpdHkgb2YgdGhlIGNvbnRhY3QuIEEgY29udGFjdCBpcyBj
b25zaWRlcmVkIHZhbGlkIGlmCiBpdCBpcyB0aGUgY29ycmVjdCByZWNpcGllbnQgZm9yIG5v
dGlmaWNhdGlvbnMgZm9yIGEgcGFydGljdWxhciByZXNvdXJjZS4KCg0KBQQAAgQGEgSnAQIR
Cg0KBQQAAgQBEgSnARIiCg0KBQQAAgQDEgSnASUmCg0KBQQAAgQIEgSoAQYxChAKCAQAAgQI
nAgAEgSoAQcwCrwBCgQEAAIFEgStAQIuGq0BIFRoZSBsYXN0IHRpbWUgdGhlIHZhbGlkYXRp
b25fc3RhdGUgd2FzIHVwZGF0ZWQsIGVpdGhlciBtYW51YWxseSBvcgogYXV0b21hdGljYWxs
eS4gQSBjb250YWN0IGlzIGNvbnNpZGVyZWQgc3RhbGUgaWYgaXRzIHZhbGlkYXRpb24gc3Rh
dGUgd2FzCiB1cGRhdGVkIG1vcmUgdGhhbiAxIHllYXIgYWdvLgoKDQoFBAACBQYSBK0BAhsK
DQoFBAACBQESBK0BHCkKDQoFBAACBQMSBK0BLC0KPAoCBAESBrEBAMcBARouIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgdGhlIExpc3RDb250YWN0cyBtZXRob2QuCgoLCgMEAQESBLEBCBsKjQEK
BAQBAgASBrUBAroBBBp9IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUuCiBG
b3JtYXQ6IG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0sIGZvbGRlcnMve2ZvbGRl
cl9pZH0gb3IKIHByb2plY3RzL3twcm9qZWN0X2lkfQoKDQoFBAECAAUSBLUBAggKDQoFBAEC
AAESBLUBCQ8KDQoFBAECAAMSBLUBEhMKDwoFBAECAAgSBrUBFLoBAwoQCggEAQIACJwIABIE
tgEEKgoRCgcEAQIACJ8IEga3AQS5AQUKiwIKBAQBAgESBMABAj8a/AEgT3B0aW9uYWwuIFRo
ZSBtYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybiBmcm9tIHRoaXMgcmVxdWVz
dC4KIE5vbi1wb3NpdGl2ZSB2YWx1ZXMgYXJlIGlnbm9yZWQuIFRoZSBwcmVzZW5jZSBvZiBg
bmV4dF9wYWdlX3Rva2VuYCBpbiB0aGUKIHJlc3BvbnNlIGluZGljYXRlcyB0aGF0IG1vcmUg
cmVzdWx0cyBtaWdodCBiZSBhdmFpbGFibGUuCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgZGVm
YXVsdCBwYWdlX3NpemUgaXMgMTAwLgoKDQoFBAECAQUSBMABAgcKDQoFBAECAQESBMABCBEK
DQoFBAECAQMSBMABFBUKDQoFBAECAQgSBMABFj4KEAoIBAECAQicCAASBMABFz0KngIKBAQB
AgISBMYBAkEajwIgT3B0aW9uYWwuIElmIHByZXNlbnQsIHJldHJpZXZlcyB0aGUgbmV4dCBi
YXRjaCBvZiByZXN1bHRzIGZyb20gdGhlCiBwcmVjZWRpbmcgY2FsbCB0byB0aGlzIG1ldGhv
ZC4gYHBhZ2VfdG9rZW5gIG11c3QgYmUgdGhlIHZhbHVlIG9mCiBgbmV4dF9wYWdlX3Rva2Vu
YCBmcm9tIHRoZSBwcmV2aW91cyByZXNwb25zZS4gVGhlIHZhbHVlcyBvZiBvdGhlciBtZXRo
b2QKIHBhcmFtZXRlcnMgc2hvdWxkIGJlIGlkZW50aWNhbCB0byB0aG9zZSBpbiB0aGUgcHJl
dmlvdXMgY2FsbC4KCg0KBQQBAgIFEgTGAQIICg0KBQQBAgIBEgTGAQkTCg0KBQQBAgIDEgTG
ARYXCg0KBQQBAgIIEgTGARhAChAKCAQBAgIInAgAEgTGARk/Cj0KAgQCEgbKAQDTAQEaLyBS
ZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgTGlzdENvbnRhY3RzIG1ldGhvZC4KCgsKAwQCARIE
ygEIHAo4CgQEAgIAEgTMAQIgGiogVGhlIGNvbnRhY3RzIGZvciB0aGUgc3BlY2lmaWVkIHJl
c291cmNlLgoKDQoFBAICAAQSBMwBAgoKDQoFBAICAAYSBMwBCxIKDQoFBAICAAESBMwBExsK
DQoFBAICAAMSBMwBHh8KpQIKBAQCAgESBNIBAh0algIgSWYgdGhlcmUgYXJlIG1vcmUgcmVz
dWx0cyB0aGFuIHRob3NlIGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBgbmV4
dF9wYWdlX3Rva2VuYCBpcyBpbmNsdWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiByZXN1
bHRzLCBjYWxsIHRoaXMKIG1ldGhvZCBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgYG5leHRf
cGFnZV90b2tlbmAgYXMgYHBhZ2VfdG9rZW5gIGFuZCB0aGUKIHJlc3Qgb2YgdGhlIHBhcmFt
ZXRlcnMgdGhlIHNhbWUgYXMgdGhlIG9yaWdpbmFsIHJlcXVlc3QuCgoNCgUEAgIBBRIE0gEC
CAoNCgUEAgIBARIE0gEJGAoNCgUEAgIBAxIE0gEbHAo6CgIEAxIG1gEA4QEBGiwgUmVxdWVz
dCBtZXNzYWdlIGZvciB0aGUgR2V0Q29udGFjdCBtZXRob2QuCgoLCgMEAwESBNYBCBkK3AEK
BAQDAgASBtsBAuABBBrLASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGNvbnRhY3QgdG8g
cmV0cmlldmUuCiBGb3JtYXQ6IG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vY29u
dGFjdHMve2NvbnRhY3RfaWR9LAogZm9sZGVycy97Zm9sZGVyX2lkfS9jb250YWN0cy97Y29u
dGFjdF9pZH0gb3IKIHByb2plY3RzL3twcm9qZWN0X2lkfS9jb250YWN0cy97Y29udGFjdF9p
ZH0KCg0KBQQDAgAFEgTbAQIICg0KBQQDAgABEgTbAQkNCg0KBQQDAgADEgTbARARCg8KBQQD
AgAIEgbbARLgAQMKEAoIBAMCAAicCAASBNwBBCoKEQoHBAMCAAifCBIG3QEE3wEFCj0KAgQE
EgbkAQDvAQEaLyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBEZWxldGVDb250YWN0IG1ldGhv
ZC4KCgsKAwQEARIE5AEIHAraAQoEBAQCABIG6QEC7gEEGskBIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUgY29udGFjdCB0byBkZWxldGUuCiBGb3JtYXQ6IG9yZ2FuaXphdGlvbnMve29y
Z2FuaXphdGlvbl9pZH0vY29udGFjdHMve2NvbnRhY3RfaWR9LAogZm9sZGVycy97Zm9sZGVy
X2lkfS9jb250YWN0cy97Y29udGFjdF9pZH0gb3IKIHByb2plY3RzL3twcm9qZWN0X2lkfS9j
b250YWN0cy97Y29udGFjdF9pZH0KCg0KBQQEAgAFEgTpAQIICg0KBQQEAgABEgTpAQkNCg0K
BQQEAgADEgTpARARCg8KBQQEAgAIEgbpARLuAQMKEAoIBAQCAAicCAASBOoBBCoKEQoHBAQC
AAifCBIG6wEE7QEFCj0KAgQFEgbyAQCAAgEaLyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBD
cmVhdGVDb250YWN0IG1ldGhvZC4KCgsKAwQFARIE8gEIHAqbAQoEBAUCABIG9gEC+wEEGooB
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgdG8gc2F2ZSB0aGlzIGNvbnRhY3QgZm9yLgogRm9y
bWF0OiBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9LCBmb2xkZXJzL3tmb2xkZXJf
aWR9IG9yCiBwcm9qZWN0cy97cHJvamVjdF9pZH0KCg0KBQQFAgAFEgT2AQIICg0KBQQFAgAB
EgT2AQkPCg0KBQQFAgADEgT2ARITCg8KBQQFAgAIEgb2ART7AQMKEAoIBAUCAAicCAASBPcB
BCoKEQoHBAUCAAifCBIG+AEE+gEFCmEKBAQFAgESBP8BAj8aUyBSZXF1aXJlZC4gVGhlIGNv
bnRhY3QgdG8gY3JlYXRlLiBNdXN0IHNwZWNpZnkgYW4gZW1haWwgYWRkcmVzcyBhbmQgbGFu
Z3VhZ2UKIHRhZy4KCg0KBQQFAgEGEgT/AQIJCg0KBQQFAgEBEgT/AQoRCg0KBQQFAgEDEgT/
ARQVCg0KBQQFAgEIEgT/ARY+ChAKCAQFAgEInAgAEgT/ARc9Cj0KAgQGEgaDAgCNAgEaLyBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBVcGRhdGVDb250YWN0IG1ldGhvZC4KCgsKAwQGARIE
gwIIHAqSAQoEBAYCABIEhgICPxqDASBSZXF1aXJlZC4gVGhlIGNvbnRhY3QgcmVzb3VyY2Ug
dG8gcmVwbGFjZSB0aGUgZXhpc3Rpbmcgc2F2ZWQgY29udGFjdC4gTm90ZToKIHRoZSBlbWFp
bCBhZGRyZXNzIG9mIHRoZSBjb250YWN0IGNhbm5vdCBiZSBtb2RpZmllZC4KCg0KBQQGAgAG
EgSGAgIJCg0KBQQGAgABEgSGAgoRCg0KBQQGAgADEgSGAhQVCg0KBQQGAgAIEgSGAhY+ChAK
CAQGAgAInAgAEgSGAhc9CsMBCgQEBgIBEgaLAgKMAi8asgEgT3B0aW9uYWwuIFRoZSB1cGRh
dGUgbWFzayBhcHBsaWVkIHRvIHRoZSByZXNvdXJjZS4gRm9yIHRoZSBgRmllbGRNYXNrYAog
ZGVmaW5pdGlvbiwgc2VlCiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9wcm90b2Nv
bC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNmaWVsZG1hc2sKCg0K
BQQGAgEGEgSLAgIbCg0KBQQGAgEBEgSLAhwnCg0KBQQGAgEDEgSLAiorCg0KBQQGAgEIEgSM
AgYuChAKCAQGAgEInAgAEgSMAgctCj8KAgQHEgaQAgCrAgEaMSBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIHRoZSBDb21wdXRlQ29udGFjdHMgbWV0aG9kLgoKCwoDBAcBEgSQAggeCqYBCgQEBwIA
EgaUAgKZAgQalQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXNvdXJjZSB0byBjb21w
dXRlIGNvbnRhY3RzIGZvci4KIEZvcm1hdDogb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9u
X2lkfSwKIGZvbGRlcnMve2ZvbGRlcl9pZH0gb3IgcHJvamVjdHMve3Byb2plY3RfaWR9CgoN
CgUEBwIABRIElAICCAoNCgUEBwIAARIElAIJDwoNCgUEBwIAAxIElAISEwoPCgUEBwIACBIG
lAIUmQIDChAKCAQHAgAInAgAEgSVAgQqChEKBwQHAgAInwgSBpYCBJgCBQqvAQoEBAcCARIE
ngICPBqgASBUaGUgY2F0ZWdvcmllcyBvZiBub3RpZmljYXRpb25zIHRvIGNvbXB1dGUgY29u
dGFjdHMgZm9yLiBJZiBBTEwgaXMgaW5jbHVkZWQKIGluIHRoaXMgbGlzdCwgY29udGFjdHMg
c3Vic2NyaWJlZCB0byBhbnkgbm90aWZpY2F0aW9uIGNhdGVnb3J5IHdpbGwgYmUKIHJldHVy
bmVkLgoKDQoFBAcCAQQSBJ4CAgoKDQoFBAcCAQYSBJ4CCx8KDQoFBAcCAQESBJ4CIDcKDQoF
BAcCAQMSBJ4COjsKiwIKBAQHAgISBKQCAj8a/AEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51
bWJlciBvZiByZXN1bHRzIHRvIHJldHVybiBmcm9tIHRoaXMgcmVxdWVzdC4KIE5vbi1wb3Np
dGl2ZSB2YWx1ZXMgYXJlIGlnbm9yZWQuIFRoZSBwcmVzZW5jZSBvZiBgbmV4dF9wYWdlX3Rv
a2VuYCBpbiB0aGUKIHJlc3BvbnNlIGluZGljYXRlcyB0aGF0IG1vcmUgcmVzdWx0cyBtaWdo
dCBiZSBhdmFpbGFibGUuCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgZGVmYXVsdCBwYWdlX3Np
emUgaXMgMTAwLgoKDQoFBAcCAgUSBKQCAgcKDQoFBAcCAgESBKQCCBEKDQoFBAcCAgMSBKQC
FBUKDQoFBAcCAggSBKQCFj4KEAoIBAcCAgicCAASBKQCFz0KngIKBAQHAgMSBKoCAkEajwIg
T3B0aW9uYWwuIElmIHByZXNlbnQsIHJldHJpZXZlcyB0aGUgbmV4dCBiYXRjaCBvZiByZXN1
bHRzIGZyb20gdGhlCiBwcmVjZWRpbmcgY2FsbCB0byB0aGlzIG1ldGhvZC4gYHBhZ2VfdG9r
ZW5gIG11c3QgYmUgdGhlIHZhbHVlIG9mCiBgbmV4dF9wYWdlX3Rva2VuYCBmcm9tIHRoZSBw
cmV2aW91cyByZXNwb25zZS4gVGhlIHZhbHVlcyBvZiBvdGhlciBtZXRob2QKIHBhcmFtZXRl
cnMgc2hvdWxkIGJlIGlkZW50aWNhbCB0byB0aG9zZSBpbiB0aGUgcHJldmlvdXMgY2FsbC4K
Cg0KBQQHAgMFEgSqAgIICg0KBQQHAgMBEgSqAgkTCg0KBQQHAgMDEgSqAhYXCg0KBQQHAgMI
EgSqAhhAChAKCAQHAgMInAgAEgSqAhk/CkAKAgQIEgauAgC5AgEaMiBSZXNwb25zZSBtZXNz
YWdlIGZvciB0aGUgQ29tcHV0ZUNvbnRhY3RzIG1ldGhvZC4KCgsKAwQIARIErgIIHwqmAQoE
BAgCABIEsgICIBqXASBBbGwgY29udGFjdHMgZm9yIHRoZSByZXNvdXJjZSB0aGF0IGFyZSBz
dWJzY3JpYmVkIHRvIHRoZSBzcGVjaWZpZWQKIG5vdGlmaWNhdGlvbiBjYXRlZ29yaWVzLCBp
bmNsdWRpbmcgY29udGFjdHMgaW5oZXJpdGVkIGZyb20gYW55IHBhcmVudAogcmVzb3VyY2Vz
LgoKDQoFBAgCAAQSBLICAgoKDQoFBAgCAAYSBLICCxIKDQoFBAgCAAESBLICExsKDQoFBAgC
AAMSBLICHh8KpQIKBAQIAgESBLgCAh0algIgSWYgdGhlcmUgYXJlIG1vcmUgcmVzdWx0cyB0
aGFuIHRob3NlIGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBgbmV4dF9wYWdl
X3Rva2VuYCBpcyBpbmNsdWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiByZXN1bHRzLCBj
YWxsIHRoaXMKIG1ldGhvZCBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgYG5leHRfcGFnZV90
b2tlbmAgYXMgYHBhZ2VfdG9rZW5gIGFuZCB0aGUKIHJlc3Qgb2YgdGhlIHBhcmFtZXRlcnMg
dGhlIHNhbWUgYXMgdGhlIG9yaWdpbmFsIHJlcXVlc3QuCgoNCgUECAIBBRIEuAICCAoNCgUE
CAIBARIEuAIJGAoNCgUECAIBAxIEuAIbHAo/CgIECRIGvAIA2AIBGjEgUmVxdWVzdCBtZXNz
YWdlIGZvciB0aGUgU2VuZFRlc3RNZXNzYWdlIG1ldGhvZC4KCgsKAwQJARIEvAIIHgr0AQoE
BAkCABIGwQICxgIEGuMBIFJlcXVpcmVkLiBUaGUgbGlzdCBvZiBuYW1lcyBvZiB0aGUgY29u
dGFjdHMgdG8gc2VuZCBhIHRlc3QgbWVzc2FnZSB0by4KIEZvcm1hdDogb3JnYW5pemF0aW9u
cy97b3JnYW5pemF0aW9uX2lkfS9jb250YWN0cy97Y29udGFjdF9pZH0sCiBmb2xkZXJzL3tm
b2xkZXJfaWR9L2NvbnRhY3RzL3tjb250YWN0X2lkfSBvcgogcHJvamVjdHMve3Byb2plY3Rf
aWR9L2NvbnRhY3RzL3tjb250YWN0X2lkfQoKDQoFBAkCAAQSBMECAgoKDQoFBAkCAAUSBMEC
CxEKDQoFBAkCAAESBMECEhoKDQoFBAkCAAMSBMECHR4KDwoFBAkCAAgSBsECH8YCAwoQCggE
CQIACJwIABIEwgIEKgoRCgcECQIACJ8IEgbDAgTFAgUKqwIKBAQJAgESBs0CAtICBBqaAiBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHJlc291cmNlIHRvIHNlbmQgdGhlIHRlc3QgbWVz
c2FnZSBmb3IuIEFsbAogY29udGFjdHMgbXVzdCBlaXRoZXIgYmUgc2V0IGRpcmVjdGx5IG9u
IHRoaXMgcmVzb3VyY2Ugb3IgaW5oZXJpdGVkIGZyb20KIGFub3RoZXIgcmVzb3VyY2UgdGhh
dCBpcyBhbiBhbmNlc3RvciBvZiB0aGlzIG9uZS4gRm9ybWF0Ogogb3JnYW5pemF0aW9ucy97
b3JnYW5pemF0aW9uX2lkfSwgZm9sZGVycy97Zm9sZGVyX2lkfSBvcgogcHJvamVjdHMve3By
b2plY3RfaWR9CgoNCgUECQIBBRIEzQICCAoNCgUECQIBARIEzQIJEQoNCgUECQIBAxIEzQIU
FQoPCgUECQIBCBIGzQIW0gIDChAKCAQJAgEInAgAEgTOAgQqChEKBwQJAgEInwgSBs8CBNEC
BQqGAQoEBAkCAhIG1gIC1wIvGnYgUmVxdWlyZWQuIFRoZSBub3RpZmljYXRpb24gY2F0ZWdv
cnkgdG8gc2VuZCB0aGUgdGVzdCBtZXNzYWdlIGZvci4gQWxsCiBjb250YWN0cyBtdXN0IGJl
IHN1YnNjcmliZWQgdG8gdGhpcyBjYXRlZ29yeS4KCg0KBQQJAgIGEgTWAgIWCg0KBQQJAgIB
EgTWAhcsCg0KBQQJAgIDEgTWAi8wCg0KBQQJAgIIEgTXAgYuChAKCAQJAgIInAgAEgTXAgct
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Essentialcontacts::V1::Service::Contact ===
    # Fields for Contact
    # Field: name Type: 9 ()
    # Field: email Type: 9 ()
    # Field: notification_category_subscriptions Type: 14 (.google.cloud.essentialcontacts.v1.NotificationCategory)
    # Field: language_tag Type: 9 ()
    # Field: validation_state Type: 14 (.google.cloud.essentialcontacts.v1.ValidationState)
    # Field: validate_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Essentialcontacts::V1::Service::ListContactsRequest ===
    # Fields for ListContactsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Essentialcontacts::V1::Service::ListContactsResponse ===
    # Fields for ListContactsResponse
    # Field: contacts Type: 11 (.google.cloud.essentialcontacts.v1.Contact)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Essentialcontacts::V1::Service::GetContactRequest ===
    # Fields for GetContactRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Essentialcontacts::V1::Service::DeleteContactRequest ===
    # Fields for DeleteContactRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest ===
    # Fields for CreateContactRequest
    # Field: parent Type: 9 ()
    # Field: contact Type: 11 (.google.cloud.essentialcontacts.v1.Contact)

# === Message: Google::Cloud::Essentialcontacts::V1::Service::UpdateContactRequest ===
    # Fields for UpdateContactRequest
    # Field: contact Type: 11 (.google.cloud.essentialcontacts.v1.Contact)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest ===
    # Fields for ComputeContactsRequest
    # Field: parent Type: 9 ()
    # Field: notification_categories Type: 14 (.google.cloud.essentialcontacts.v1.NotificationCategory)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse ===
    # Fields for ComputeContactsResponse
    # Field: contacts Type: 11 (.google.cloud.essentialcontacts.v1.Contact)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest ===
    # Fields for SendTestMessageRequest
    # Field: contacts Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: notification_category Type: 14 (.google.cloud.essentialcontacts.v1.NotificationCategory)

# === Service Client: Google::Cloud::Essentialcontacts::V1::Service::EssentialContactsServiceClient ===
package Google::Cloud::Essentialcontacts::V1::Service::EssentialContactsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Essentialcontacts::V1::Service::EssentialContactsServiceClient

Client stub representing the remote C<EssentialContactsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<essentialcontacts.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'essentialcontacts.googleapis.com:443' );

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

sub create_contact {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'CreateContact',
        request        => $req,
        response_class => 'Google::Cloud::Essentialcontacts::V1::Service::Contact',
    });
}

sub update_contact {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::UpdateContactRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'UpdateContact',
        request        => $req,
        response_class => 'Google::Cloud::Essentialcontacts::V1::Service::Contact',
    });
}

sub list_contacts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::ListContactsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'ListContacts',
        request        => $req,
        response_class => 'Google::Cloud::Essentialcontacts::V1::Service::ListContactsResponse',
    });
}

sub get_contact {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::GetContactRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'GetContact',
        request        => $req,
        response_class => 'Google::Cloud::Essentialcontacts::V1::Service::Contact',
    });
}

sub delete_contact {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::DeleteContactRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'DeleteContact',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub compute_contacts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'ComputeContacts',
        request        => $req,
        response_class => 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse',
    });
}

sub send_test_message {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.essentialcontacts.v1.EssentialContactsService',
        method         => 'SendTestMessage',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Essentialcontacts::V1::Service - Compiled Protocol Buffers messages for google/cloud/essentialcontacts/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Essentialcontacts::V1::Service;

    my $msg = Google::Cloud::Essentialcontacts::V1::Service::Contact->new({
        name => $name,
        email => $email,
        notification_category_subscriptions => $notification_category_subscriptions,
        language_tag => $language_tag,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Essentialcontacts::V1::Service::Contact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/essentialcontacts/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Essentialcontacts::V1::Service::Contact

A contact that will receive notifications from Google Cloud.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The identifier for the contact.
Format: {resource_type}/{resource_id}/contacts/{contact_id}

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

Required. The email address to send notifications to. The email address
does not need to be a Google Account.

=item * C<< $msg->notification_category_subscriptions() >> / C<< $msg->notification_category_subscriptions($value) >>

Type: C<Enum> (L<Google::Cloud::Essentialcontacts::V1::NotificationCategory>)

Required. The categories of notifications that the contact will receive
communications for.

=item * C<< $msg->language_tag() >> / C<< $msg->language_tag($value) >>

Type: C<String>

Required. The preferred language for notifications, as a ISO 639-1 language
code. See [Supported
languages](https://cloud.google.com/resource-manager/docs/managing-notification-contacts#supported-languages)
for a list of supported languages.

=item * C<< $msg->validation_state() >> / C<< $msg->validation_state($value) >>

Type: C<Enum> (L<Google::Cloud::Essentialcontacts::V1::ValidationState>)

Output only. The validity of the contact. A contact is considered valid if
it is the correct recipient for notifications for a particular resource.

=item * C<< $msg->validate_time() >> / C<< $msg->validate_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last time the validation_state was updated, either manually or
automatically. A contact is considered stale if its validation state was
updated more than 1 year ago.

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::ListContactsRequest

Request message for the ListContacts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
Format: organizations/{organization_id}, folders/{folder_id} or
projects/{project_id}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive values are ignored. The presence of `next_page_token` in the
response indicates that more results might be available.
If not specified, the default page_size is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, retrieves the next batch of results from the
preceding call to this method. `page_token` must be the value of
`next_page_token` from the previous response. The values of other method
parameters should be identical to those in the previous call.

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::ListContactsResponse

Response message for the ListContacts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contacts() >> / C<< $msg->contacts($value) >>

Type: C<Message> (L<Google::Cloud::Essentialcontacts::V1::Service::Contact>)

The contacts for the specified resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token` and the
rest of the parameters the same as the original request.

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::GetContactRequest

Request message for the GetContact method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the contact to retrieve.
Format: organizations/{organization_id}/contacts/{contact_id},
folders/{folder_id}/contacts/{contact_id} or
projects/{project_id}/contacts/{contact_id}

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::DeleteContactRequest

Request message for the DeleteContact method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the contact to delete.
Format: organizations/{organization_id}/contacts/{contact_id},
folders/{folder_id}/contacts/{contact_id} or
projects/{project_id}/contacts/{contact_id}

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest

Request message for the CreateContact method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource to save this contact for.
Format: organizations/{organization_id}, folders/{folder_id} or
projects/{project_id}

=item * C<< $msg->contact() >> / C<< $msg->contact($value) >>

Type: C<Message> (L<Google::Cloud::Essentialcontacts::V1::Service::Contact>)

Required. The contact to create. Must specify an email address and language
tag.

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::UpdateContactRequest

Request message for the UpdateContact method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contact() >> / C<< $msg->contact($value) >>

Type: C<Message> (L<Google::Cloud::Essentialcontacts::V1::Service::Contact>)

Required. The contact resource to replace the existing saved contact. Note:
the email address of the contact cannot be modified.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The update mask applied to the resource. For the `FieldMask`
definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest

Request message for the ComputeContacts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the resource to compute contacts for.
Format: organizations/{organization_id},
folders/{folder_id} or projects/{project_id}

=item * C<< $msg->notification_categories() >> / C<< $msg->notification_categories($value) >>

Type: C<Enum> (L<Google::Cloud::Essentialcontacts::V1::NotificationCategory>)

The categories of notifications to compute contacts for. If ALL is included
in this list, contacts subscribed to any notification category will be
returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return from this request.
Non-positive values are ignored. The presence of `next_page_token` in the
response indicates that more results might be available.
If not specified, the default page_size is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If present, retrieves the next batch of results from the
preceding call to this method. `page_token` must be the value of
`next_page_token` from the previous response. The values of other method
parameters should be identical to those in the previous call.

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse

Response message for the ComputeContacts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contacts() >> / C<< $msg->contacts($value) >>

Type: C<Message> (L<Google::Cloud::Essentialcontacts::V1::Service::Contact>)

All contacts for the resource that are subscribed to the specified
notification categories, including contacts inherited from any parent
resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token` and the
rest of the parameters the same as the original request.

=back

=head2 Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest

Request message for the SendTestMessage method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contacts() >> / C<< $msg->contacts($value) >>

Type: C<String>

Required. The list of names of the contacts to send a test message to.
Format: organizations/{organization_id}/contacts/{contact_id},
folders/{folder_id}/contacts/{contact_id} or
projects/{project_id}/contacts/{contact_id}

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Required. The name of the resource to send the test message for. All
contacts must either be set directly on this resource or inherited from
another resource that is an ancestor of this one. Format:
organizations/{organization_id}, folders/{folder_id} or
projects/{project_id}

=item * C<< $msg->notification_category() >> / C<< $msg->notification_category($value) >>

Type: C<Enum> (L<Google::Cloud::Essentialcontacts::V1::NotificationCategory>)

Required. The notification category to send the test message for. All
contacts must be subscribed to this category.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Essentialcontacts::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
