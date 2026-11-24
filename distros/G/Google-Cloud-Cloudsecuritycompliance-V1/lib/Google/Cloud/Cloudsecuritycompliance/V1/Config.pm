package Google::Cloud::Cloudsecuritycompliance::V1::Config;

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
    eval { require Google::Cloud::Cloudsecuritycompliance::V1::Common };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UvdjEvY29uZmlnLnByb3Rv
Eidnb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRnb29n
bGUvY2xvdWQvY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UvdjEvY29tbW9uLnByb3RvGhtnb29n
bGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvIq8BChVMaXN0RnJhbWV3b3Jrc1JlcXVlc3QSUAoGcGFyZW50GAEgASgJQjjgQQL6QTIS
MGNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLmdvb2dsZWFwaXMuY29tL0ZyYW1ld29ya1IGcGFy
ZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMg
ASgJQgPgQQFSCXBhZ2VUb2tlbiKUAQoWTGlzdEZyYW1ld29ya3NSZXNwb25zZRJSCgpmcmFt
ZXdvcmtzGAEgAygLMjIuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYx
LkZyYW1ld29ya1IKZnJhbWV3b3JrcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4ilAEKE0dldEZyYW1ld29ya1JlcXVlc3QSTAoEbmFtZRgBIAEoCUI44EEC+kEy
CjBjbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS5nb29nbGVhcGlzLmNvbS9GcmFtZXdvcmtSBG5h
bWUSLwoRbWFqb3JfcmV2aXNpb25faWQYAiABKANCA+BBAVIPbWFqb3JSZXZpc2lvbklkIukB
ChZDcmVhdGVGcmFtZXdvcmtSZXF1ZXN0ElAKBnBhcmVudBgBIAEoCUI44EEC+kEyEjBjbG91
ZHNlY3VyaXR5Y29tcGxpYW5jZS5nb29nbGVhcGlzLmNvbS9GcmFtZXdvcmtSBnBhcmVudBIm
CgxmcmFtZXdvcmtfaWQYAiABKAlCA+BBAlILZnJhbWV3b3JrSWQSVQoJZnJhbWV3b3JrGAMg
ASgLMjIuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLkZyYW1ld29y
a0ID4EECUglmcmFtZXdvcmsi4gEKFlVwZGF0ZUZyYW1ld29ya1JlcXVlc3QSQAoLdXBkYXRl
X21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1h
c2sSVQoJZnJhbWV3b3JrGAIgASgLMjIuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21w
bGlhbmNlLnYxLkZyYW1ld29ya0ID4EECUglmcmFtZXdvcmsSLwoRbWFqb3JfcmV2aXNpb25f
aWQYAyABKANCA+BBAVIPbWFqb3JSZXZpc2lvbklkImYKFkRlbGV0ZUZyYW1ld29ya1JlcXVl
c3QSTAoEbmFtZRgBIAEoCUI44EEC+kEyCjBjbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS5nb29n
bGVhcGlzLmNvbS9GcmFtZXdvcmtSBG5hbWUitQEKGExpc3RDbG91ZENvbnRyb2xzUmVxdWVz
dBJTCgZwYXJlbnQYASABKAlCO+BBAvpBNRIzY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UuZ29v
Z2xlYXBpcy5jb20vQ2xvdWRDb250cm9sUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIqEBChlM
aXN0Q2xvdWRDb250cm9sc1Jlc3BvbnNlElwKDmNsb3VkX2NvbnRyb2xzGAEgAygLMjUuZ29v
Z2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLkNsb3VkQ29udHJvbFINY2xv
dWRDb250cm9scxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4imgEK
FkdldENsb3VkQ29udHJvbFJlcXVlc3QSTwoEbmFtZRgBIAEoCUI74EEC+kE1CjNjbG91ZHNl
Y3VyaXR5Y29tcGxpYW5jZS5nb29nbGVhcGlzLmNvbS9DbG91ZENvbnRyb2xSBG5hbWUSLwoR
bWFqb3JfcmV2aXNpb25faWQYAiABKANCA+BBAVIPbWFqb3JSZXZpc2lvbklkIoACChlDcmVh
dGVDbG91ZENvbnRyb2xSZXF1ZXN0ElMKBnBhcmVudBgBIAEoCUI74EEC+kE1EjNjbG91ZHNl
Y3VyaXR5Y29tcGxpYW5jZS5nb29nbGVhcGlzLmNvbS9DbG91ZENvbnRyb2xSBnBhcmVudBIt
ChBjbG91ZF9jb250cm9sX2lkGAIgASgJQgPgQQJSDmNsb3VkQ29udHJvbElkEl8KDWNsb3Vk
X2NvbnRyb2wYAyABKAsyNS5nb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2Uu
djEuQ2xvdWRDb250cm9sQgPgQQJSDGNsb3VkQ29udHJvbCK+AQoZVXBkYXRlQ2xvdWRDb250
cm9sUmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVs
ZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJfCg1jbG91ZF9jb250cm9sGAIgASgLMjUuZ29vZ2xl
LmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLkNsb3VkQ29udHJvbEID4EECUgxj
bG91ZENvbnRyb2wibAoZRGVsZXRlQ2xvdWRDb250cm9sUmVxdWVzdBJPCgRuYW1lGAEgASgJ
QjvgQQL6QTUKM2Nsb3Vkc2VjdXJpdHljb21wbGlhbmNlLmdvb2dsZWFwaXMuY29tL0Nsb3Vk
Q29udHJvbFIEbmFtZTL3FgoGQ29uZmlnEokCCg5MaXN0RnJhbWV3b3JrcxI+Lmdvb2dsZS5j
bG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS52MS5MaXN0RnJhbWV3b3Jrc1JlcXVlc3Qa
Py5nb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEuTGlzdEZyYW1ld29y
a3NSZXNwb25zZSJ2gtPkkwJnEjMvdjEve3BhcmVudD1vcmdhbml6YXRpb25zLyovbG9jYXRp
b25zLyp9L2ZyYW1ld29ya3NaMBIuL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Kn0vZnJhbWV3b3Jrc9pBBnBhcmVudBL2AQoMR2V0RnJhbWV3b3JrEjwuZ29vZ2xlLmNsb3Vk
LmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLkdldEZyYW1ld29ya1JlcXVlc3QaMi5nb29n
bGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEuRnJhbWV3b3JrInSC0+STAmcS
My92MS97bmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyovZnJhbWV3b3Jrcy8qfVow
Ei4vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9mcmFtZXdvcmtzLyp92kEEbmFt
ZRKsAgoPQ3JlYXRlRnJhbWV3b3JrEj8uZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21w
bGlhbmNlLnYxLkNyZWF0ZUZyYW1ld29ya1JlcXVlc3QaMi5nb29nbGUuY2xvdWQuY2xvdWRz
ZWN1cml0eWNvbXBsaWFuY2UudjEuRnJhbWV3b3JrIqMBgtPkkwJ9IjMvdjEve3BhcmVudD1v
cmdhbml6YXRpb25zLyovbG9jYXRpb25zLyp9L2ZyYW1ld29ya3M6CWZyYW1ld29ya1o7Ii4v
djEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9mcmFtZXdvcmtzOglmcmFtZXdv
cmvaQR1wYXJlbnQsZnJhbWV3b3JrLGZyYW1ld29ya19pZBK5AgoPVXBkYXRlRnJhbWV3b3Jr
Ej8uZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLlVwZGF0ZUZyYW1l
d29ya1JlcXVlc3QaMi5nb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEu
RnJhbWV3b3JrIrABgtPkkwKRATI9L3YxL3tmcmFtZXdvcmsubmFtZT1vcmdhbml6YXRpb25z
LyovbG9jYXRpb25zLyovZnJhbWV3b3Jrcy8qfToJZnJhbWV3b3JrWkUyOC92MS97ZnJhbWV3
b3JrLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9mcmFtZXdvcmtzLyp9OglmcmFtZXdv
cmvaQRVmcmFtZXdvcmssdXBkYXRlX21hc2sS4AEKD0RlbGV0ZUZyYW1ld29yaxI/Lmdvb2ds
ZS5jbG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS52MS5EZWxldGVGcmFtZXdvcmtSZXF1
ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5InSC0+STAmcqMy92MS97bmFtZT1vcmdhbml6
YXRpb25zLyovbG9jYXRpb25zLyovZnJhbWV3b3Jrcy8qfVowKi4vdjEve25hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9mcmFtZXdvcmtzLyp92kEEbmFtZRKYAgoRTGlzdENsb3VkQ29u
dHJvbHMSQS5nb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEuTGlzdENs
b3VkQ29udHJvbHNSZXF1ZXN0GkIuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlh
bmNlLnYxLkxpc3RDbG91ZENvbnRyb2xzUmVzcG9uc2UifILT5JMCbRI2L3YxL3twYXJlbnQ9
b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS9jbG91ZENvbnRyb2xzWjMSMS92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2Nsb3VkQ29udHJvbHPaQQZwYXJlbnQShQIK
D0dldENsb3VkQ29udHJvbBI/Lmdvb2dsZS5jbG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5j
ZS52MS5HZXRDbG91ZENvbnRyb2xSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJp
dHljb21wbGlhbmNlLnYxLkNsb3VkQ29udHJvbCJ6gtPkkwJtEjYvdjEve25hbWU9b3JnYW5p
emF0aW9ucy8qL2xvY2F0aW9ucy8qL2Nsb3VkQ29udHJvbHMvKn1aMxIxL3YxL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY2xvdWRDb250cm9scy8qfdpBBG5hbWUSzAIKEkNyZWF0
ZUNsb3VkQ29udHJvbBJCLmdvb2dsZS5jbG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS52
MS5DcmVhdGVDbG91ZENvbnRyb2xSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJp
dHljb21wbGlhbmNlLnYxLkNsb3VkQ29udHJvbCK6AYLT5JMCiwEiNi92MS97cGFyZW50PW9y
Z2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKn0vY2xvdWRDb250cm9sczoNY2xvdWRfY29udHJv
bFpCIjEvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jbG91ZENvbnRyb2xz
Og1jbG91ZF9jb250cm9s2kElcGFyZW50LGNsb3VkX2NvbnRyb2wsY2xvdWRfY29udHJvbF9p
ZBLcAgoSVXBkYXRlQ2xvdWRDb250cm9sEkIuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHlj
b21wbGlhbmNlLnYxLlVwZGF0ZUNsb3VkQ29udHJvbFJlcXVlc3QaNS5nb29nbGUuY2xvdWQu
Y2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEuQ2xvdWRDb250cm9sIsoBgtPkkwKnATJEL3Yx
L3tjbG91ZF9jb250cm9sLm5hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2Nsb3Vk
Q29udHJvbHMvKn06DWNsb3VkX2NvbnRyb2xaUDI/L3YxL3tjbG91ZF9jb250cm9sLm5hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbG91ZENvbnRyb2xzLyp9Og1jbG91ZF9jb250cm9s
2kEZY2xvdWRfY29udHJvbCx1cGRhdGVfbWFzaxLsAQoSRGVsZXRlQ2xvdWRDb250cm9sEkIu
Z29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLkRlbGV0ZUNsb3VkQ29u
dHJvbFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkieoLT5JMCbSo2L3YxL3tuYW1l
PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9jbG91ZENvbnRyb2xzLyp9WjMqMS92MS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nsb3VkQ29udHJvbHMvKn3aQQRuYW1lGlrK
QSZjbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CpAIKK2NvbS5nb29nbGUuY2xv
dWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjFCC0NvbmZpZ1Byb3RvUAFaZWNsb3VkLmdv
b2dsZS5jb20vZ28vY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UvYXBpdjEvY2xvdWRzZWN1cml0
eWNvbXBsaWFuY2VwYjtjbG91ZHNlY3VyaXR5Y29tcGxpYW5jZXBiqgInR29vZ2xlLkNsb3Vk
LkNsb3VkU2VjdXJpdHlDb21wbGlhbmNlLlYxygInR29vZ2xlXENsb3VkXENsb3VkU2VjdXJp
dHlDb21wbGlhbmNlXFYx6gIqR29vZ2xlOjpDbG91ZDo6Q2xvdWRTZWN1cml0eUNvbXBsaWFu
Y2U6OlYxStZpCgcSBQ4AxwMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAwCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMK
CQoCAwQSAxYAPgoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgBECgkKAgglEgMaAEQK
CAoBCBIDGwB8CgkKAggLEgMbAHwKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQAsCgkK
AggIEgMdACwKCAoBCBIDHgBECgkKAggBEgMeAEQKCAoBCBIDHwBECgkKAggpEgMfAEQKCAoB
CBIDIABDCgkKAggtEgMgAEMKZwoCBgASBSQA2QEBGlogQ29uZmlnIFNlcnZpY2UgbWFuYWdl
cyBjb21wbGlhbmNlIGZyYW1ld29ya3MsIGNsb3VkIGNvbnRyb2xzLCBhbmQgdGhlaXIKIGNv
bmZpZ3VyYXRpb25zLgoKCgoDBgABEgMkCA4KCgoDBgADEgMlAk4KDAoFBgADmQgSAyUCTgoL
CgMGAAMSBCYCJzcKDQoFBgADmggSBCYCJzcKywEKBAYAAgASBC0CNQMavAEgTGlzdHMgdGhl
IGZyYW1ld29ya3MgKGJvdGggYnVpbHQtaW4gYW5kIGN1c3RvbSkgdGhhdCBhcmUgYXZhaWxh
YmxlIHdpdGhpbgogdGhlIHBhcmVudCByZXNvdXJjZS4gVGhlIGxhdGVzdCBtYWpvciB2ZXJz
aW9uIG9mIGVhY2ggZnJhbWV3b3JrIGlzCiByZXR1cm5lZC4KIFRoaXMgbWV0aG9kIHN1cHBv
cnRzIHBhZ2luYXRpb24uCgoMCgUGAAIAARIDLQYUCgwKBQYAAgACEgMtFSoKDAoFBgACAAMS
Ay01SwoNCgUGAAIABBIELgQzBgoRCgkGAAIABLDKvCISBC4EMwYKDAoFBgACAAQSAzQENAoP
CggGAAIABJsIABIDNAQ0CscBCgQGAAIBEgQ8AkQDGrgBIEdldHMgZGV0YWlscyBhYm91dCBh
IGZyYW1ld29yay4KIFRoaXMgbWV0aG9kIHJldHJpZXZlcyB0aGUgbGF0ZXN0IG1ham9yIHZl
cnNpb24gb2YgdGhlIGZyYW1ld29yay4KCiBUbyByZXRyaWV2ZSBhIHNwZWNpZmljIG1ham9y
IHZlcnNpb24sIGluY2x1ZGUgYG1ham9yX3JldmlzaW9uX2lkYCBpbgogdGhlIHJlcXVlc3Qu
CgoMCgUGAAIBARIDPAYSCgwKBQYAAgECEgM8EyYKDAoFBgACAQMSAzwxOgoNCgUGAAIBBBIE
PQRCBgoRCgkGAAIBBLDKvCISBD0EQgYKDAoFBgACAQQSA0MEMgoPCggGAAIBBJsIABIDQwQy
CpMBCgQGAAICEgRJAlMDGoQBIENyZWF0ZXMgYSBjdXN0b20gZnJhbWV3b3JrIGluIGEgZ2l2
ZW4gcGFyZW50IHJlc291cmNlLgogWW91IGNhbid0IGNyZWF0ZSBidWlsdC1pbiBmcmFtZXdv
cmtzIGJlY2F1c2UgdGhvc2UgYXJlIG1hbmFnZWQgYnkKIEdvb2dsZS4KCgwKBQYAAgIBEgNJ
BhUKDAoFBgACAgISA0kWLAoMCgUGAAICAxIDSTdACg0KBQYAAgIEEgRKBFEGChEKCQYAAgIE
sMq8IhIESgRRBgoMCgUGAAICBBIDUgRLCg8KCAYAAgIEmwgAEgNSBEsKqQQKBAYAAgMSBGEC
awMamgQgVXBkYXRlcyBhIGN1c3RvbSBmcmFtZXdvcmsuCiBUaGlzIG1ldGhvZCBhbGxvd3Mg
Zm9yIHBhcnRpYWwgdXBkYXRlcyBvZiBhIGZyYW1ld29yay4gVXNlIHRoZQogYHVwZGF0ZV9t
YXNrYCB0byBzcGVjaWZ5IHdoaWNoIGZpZWxkcyB0byB1cGRhdGUuIENvbnNpZGVyIHRoZSBm
b2xsb3dpbmc6CgogLSBJZiB5b3UgcHJvdmlkZSBhbiBgdXBkYXRlX21hc2tgLCBvbmx5IHRo
ZSBmaWVsZHMgdGhhdCBhcmUgc3BlY2lmaWVkCiBpbiB0aGUgbWFzayBhcmUgdXBkYXRlZC4K
IC0gSWYgeW91IGRvbid0IHByb3ZpZGUgYW4gYHVwZGF0ZV9tYXNrYCwgYWxsIHRoZSBmaWVs
ZHMgdGhhdCBhcmUgcHJlc2VudAogaW4gdGhlIHJlcXVlc3QncyBgZnJhbWV3b3JrYCBib2R5
IGFyZSB1c2VkIHRvIG92ZXJ3cml0ZSB0aGUgZXhpc3RpbmcKIHJlc291cmNlLgoKIFlvdSBj
YW4gb25seSB1cGRhdGUgZnJhbWV3b3JrcyB3aXRoIHRoZSBgQ1VTVE9NYCB0eXBlLgogQSBz
dWNjZXNzZnVsIHVwZGF0ZSBjcmVhdGVzIGEgbmV3IHZlcnNpb24gb2YgdGhlIGZyYW1ld29y
ay4KCgwKBQYAAgMBEgNhBhUKDAoFBgACAwISA2EWLAoMCgUGAAIDAxIDYTdACg0KBQYAAgME
EgRiBGkGChEKCQYAAgMEsMq8IhIEYgRpBgoMCgUGAAIDBBIDagRDCg8KCAYAAgMEmwgAEgNq
BEMK1gIKBAYAAgQSBHQCfAMaxwIgRGVsZXRlcyBhIGN1c3RvbSBmcmFtZXdvcmssIGluY2x1
ZGluZyBhbGwgaXRzIG1ham9yIGFuZAogbWlub3IgcmV2aXNpb25zLiBDb25zaWRlciB0aGUg
Zm9sbG93aW5nOgoKIC0gWW91IGNhbid0IGRlbGV0ZSBidWlsdC1pbiBmcmFtZXdvcmtzLiBZ
b3UgY2FuIG9ubHkgZGVsZXRlIGZyYW1ld29ya3MKICAgd2l0aCB0eXBlIGBDVVNUT01gLgog
LSBZb3UgY2FuJ3QgZGVsZXRlIGZyYW1ld29ya3MgdGhhdCBhcmUgZGVwbG95ZWQgdG8gYSBy
ZXNvdXJjZS4KIC0gWW91IGNhbid0IHJlc3RvcmUgYSBkZWxldGVkIGZyYW1ld29yay4gVGhp
cyBhY3Rpb24gaXMgcGVybWFuZW50LgoKDAoFBgACBAESA3QGFQoMCgUGAAIEAhIDdBYsCgwK
BQYAAgQDEgN0N0wKDQoFBgACBAQSBHUEegYKEQoJBgACBASwyrwiEgR1BHoGCgwKBQYAAgQE
EgN7BDIKDwoIBgACBASbCAASA3sEMgrVAQoEBgACBRIGggECiwEDGsQBIExpc3RzIHRoZSBj
bG91ZCBjb250cm9scyAoYm90aCBidWlsdC1pbiBhbmQgY3VzdG9tKSB0aGF0IGFyZSBhdmFp
bGFibGUKIGluIGEgZ2l2ZW4gcGFyZW50IHJlc291cmNlLiBUaGUgbGF0ZXN0IG1ham9yIHZl
cnNpb24gb2YgZWFjaCBjbG91ZCBjb250cm9sCiBpcyByZXR1cm5lZC4KIFRoaXMgbWV0aG9k
IHN1cHBvcnRzIHBhZ2luYXRpb24uCgoNCgUGAAIFARIEggEGFwoNCgUGAAIFAhIEggEYMAoN
CgUGAAIFAxIEgwEPKAoPCgUGAAIFBBIGhAEEiQEGChMKCQYAAgUEsMq8IhIGhAEEiQEGCg0K
BQYAAgUEEgSKAQQ0ChAKCAYAAgUEmwgAEgSKAQQ0CrICCgQGAAIGEgaUAQKcAQMaoQIgR2V0
cyBkZXRhaWxzIGFib3V0IGEgY2xvdWQgY29udHJvbC4KIFRoaXMgbWV0aG9kIHJldHJpZXZl
cyB0aGUgbGF0ZXN0IG1ham9yIHZlcnNpb24gb2YgYSBjbG91ZCBjb250cm9sIHRoYXQKIHlv
dSBpZGVudGlmeSBieSBuYW1lLgoKIEJ5IGRlZmF1bHQsIHRoZSBsYXRlc3QgbWFqb3IgdmVy
c2lvbiBvZiB0aGUgY2xvdWQgY29udHJvbCBpcyByZXR1cm5lZC4KIFRvIHJldHJpZXZlIGEg
c3BlY2lmaWMgbWFqb3IgdmVyc2lvbiwgaW5jbHVkZSBgbWFqb3JfcmV2aXNpb25faWRgIGlu
CiB0aGUgcmVxdWVzdC4KCg0KBQYAAgYBEgSUAQYVCg0KBQYAAgYCEgSUARYsCg0KBQYAAgYD
EgSUATdDCg8KBQYAAgYEEgaVAQSaAQYKEwoJBgACBgSwyrwiEgaVAQSaAQYKDQoFBgACBgQS
BJsBBDIKEAoIBgACBgSbCAASBJsBBDIKngEKBAYAAgcSBqIBAq0BAxqNASBDcmVhdGVzIGEg
Y3VzdG9tIGNsb3VkIGNvbnRyb2wgaW4gYSBnaXZlbiBwYXJlbnQKIHJlc291cmNlLgogWW91
IGNhbid0IGNyZWF0ZSBidWlsdC1pbiBjbG91ZCBjb250cm9scyBiZWNhdXNlIHRob3NlIGFy
ZSBtYW5hZ2VkIGJ5CiBHb29nbGUuCgoNCgUGAAIHARIEogEGGAoNCgUGAAIHAhIEogEZMgoN
CgUGAAIHAxIEogE9SQoPCgUGAAIHBBIGowEEqgEGChMKCQYAAgcEsMq8IhIGowEEqgEGCg8K
BQYAAgcEEgarAQSsATAKEgoIBgACBwSbCAASBqsBBKwBMAq/BAoEBgACCBIGuwECxQEDGq4E
IFVwZGF0ZXMgYSBjdXN0b20gY2xvdWQgY29udHJvbC4KIFRoaXMgbWV0aG9kIGFsbG93cyBm
b3IgcGFydGlhbCB1cGRhdGVzIG9mIGEgY2xvdWQgY29udHJvbC4gVXNlIHRoZQogYHVwZGF0
ZV9tYXNrYCB0byBzcGVjaWZ5IHdoaWNoIGZpZWxkcyB0byB1cGRhdGUuIENvbnNpZGVyIHRo
ZSBmb2xsb3dpbmc6CgogLSBJZiB5b3UgcHJvdmlkZSBhbiBgdXBkYXRlX21hc2tgLCBvbmx5
IHRoZSBmaWVsZHMgdGhhdCBhcmUgc3BlY2lmaWVkCiBpbiB0aGUgbWFzayBhcmUgdXBkYXRl
ZC4KIC0gSWYgeW91IGRvbid0IHByb3ZpZGUgYW4gYHVwZGF0ZV9tYXNrYCwgYWxsIHRoZSBm
aWVsZHMgdGhhdCBhcmUgcHJlc2VudAogaW4gdGhlIHJlcXVlc3QncyBgY2xvdWRfY29udHJv
bGAgYm9keSBhcmUgdXNlZCB0byBvdmVyd3JpdGUgdGhlIGV4aXN0aW5nCiByZXNvdXJjZS4K
CiBZb3UgY2FuIG9ubHkgdXBkYXRlIGNsb3VkIGNvbnRyb2xzIHdpdGggdGhlIGBDVVNUT01g
IHR5cGUuCiBBIHN1Y2Nlc3NmdWwgdXBkYXRlIGNyZWF0ZXMgYSBuZXcgdmVyc2lvbiBvZiB0
aGUgY2xvdWQgY29udHJvbC4KCg0KBQYAAggBEgS7AQYYCg0KBQYAAggCEgS7ARkyCg0KBQYA
AggDEgS7AT1JCg8KBQYAAggEEga8AQTDAQYKEwoJBgACCASwyrwiEga8AQTDAQYKDQoFBgAC
CAQSBMQBBEcKEAoIBgACCASbCAASBMQBBEcKhAMKBAYAAgkSBs8BAtgBAxrzAiBEZWxldGVz
IGEgY3VzdG9tIGNsb3VkIGNvbnRyb2wsIGluY2x1ZGluZyBhbGwgaXRzCiBtYWpvciBhbmQg
bWlub3IgcmV2aXNpb25zLiBDb25zaWRlciB0aGUgZm9sbG93aW5nOgoKIC0gWW91IGNhbid0
IGRlbGV0ZSBidWlsdC1pbiBjbG91ZCBjb250cm9scy4gWW91IGNhbiBvbmx5IGRlbGV0ZSBj
bG91ZAogICBjb250cm9scyB3aXRoIHR5cGUgYENVU1RPTWAuCiAtIFlvdSBjYW4ndCBkZWxl
dGUgY2xvdWQgY29udHJvbHMgaWYgYW55IG9mIHRoZSB2ZXJzaW9ucyBhcmUgcmVmZXJlbmNl
ZAogICBieSBhIGZyYW1ld29yay4KIC0gWW91IGNhbid0IHJlc3RvcmUgYSBkZWxldGVkIGNs
b3VkIGNvbnRyb2wuIFRoaXMgYWN0aW9uIGlzIHBlcm1hbmVudC4KCg0KBQYAAgkBEgTPAQYY
Cg0KBQYAAgkCEgTPARkyCg0KBQYAAgkDEgTQAQ8kCg8KBQYAAgkEEgbRAQTWAQYKEwoJBgAC
CQSwyrwiEgbRAQTWAQYKDQoFBgACCQQSBNcBBDIKEAoIBgACCQSbCAASBNcBBDIKNwoCBAAS
BtwBAPMBARopIFJlcXVlc3QgbWVzc2FnZSBmb3IgW0xpc3RGcmFtZXdvcmtzXVtdLgoKCwoD
BAABEgTcAQgdCucBCgQEAAIAEgbiAQLnAQQa1gEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVz
b3VyY2UgbmFtZSwgaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0czoKIC0gYG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCiAtIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKIFRoZSBvbmx5IHN1cHBv
cnRlZCBsb2NhdGlvbiBpcyBgZ2xvYmFsYC4KCg0KBQQAAgAFEgTiAQIICg0KBQQAAgABEgTi
AQkPCg0KBQQAAgADEgTiARITCg8KBQQAAgAIEgbiARTnAQMKEAoIBAACAAicCAASBOMBBCoK
EQoHBAACAAifCBIG5AEE5gEFCroBCgQEAAIBEgTuAQI/GqsBIE9wdGlvbmFsLiBUaGUgbWF4
aW11bSBudW1iZXIgb2YgZnJhbWV3b3JrcyB0byByZXR1cm4uIFRoZSBkZWZhdWx0IHZhbHVl
IGlzCiBgNTAwYC4KCiBJZiB5b3UgZXhjZWVkIHRoZSBtYXhpbXVtIHZhbHVlIG9mIGAxMDAw
YCwgdGhlbiB0aGUgc2VydmljZSB1c2VzIHRoZQogbWF4aW11bSB2YWx1ZS4KCg0KBQQAAgEF
EgTuAQIHCg0KBQQAAgEBEgTuAQgRCg0KBQQAAgEDEgTuARQVCg0KBQQAAgEIEgTuARY+ChAK
CAQAAgEInAgAEgTuARc9CpwBCgQEAAICEgTyAQJBGo0BIE9wdGlvbmFsLiBBIHBhZ2luYXRp
b24gdG9rZW4gcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIHJlcXVlc3QgdG8gbGlzdAogZnJh
bWV3b3Jrcy4gUHJvdmlkZSB0aGlzIHRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ug
b2YgcmVzdWx0cy4KCg0KBQQAAgIFEgTyAQIICg0KBQQAAgIBEgTyAQkTCg0KBQQAAgIDEgTy
ARYXCg0KBQQAAgIIEgTyARhAChAKCAQAAgIInAgAEgTyARk/Cm4KAgQBEgb3AQD+AQEaYCBU
aGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IgW0xpc3RGcmFtZXdvcmtzXVtdLgogUmV0dXJucyBh
IHBhZ2luYXRlZCBsaXN0IG9mIEZyYW1ld29yayByZXNvdXJjZXMuCgoLCgMEAQESBPcBCB4K
MAoEBAECABIE+QECJBoiIFRoZSBsaXN0IG9mIGZyYW1ld29yayByZXNvdXJjZXMuCgoNCgUE
AQIABBIE+QECCgoNCgUEAQIABhIE+QELFAoNCgUEAQIAARIE+QEVHwoNCgUEAQIAAxIE+QEi
IwpxCgQEAQIBEgT9AQIdGmMgQSBwYWdpbmF0aW9uIHRva2VuLiBUbyByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlIG9mIHJlc3VsdHMsIGNhbGwgdGhlIG1ldGhvZAogYWdhaW4gd2l0aCB0aGlz
IHRva2VuLgoKDQoFBAECAQUSBP0BAggKDQoFBAECAQESBP0BCRgKDQoFBAECAQMSBP0BGxwK
OQoCBAISBoECAJMCARorIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIFtHZXRGcmFtZXdvcmtd
W10uCgoLCgMEAgESBIECCBsKowIKBAQCAgASBokCAo4CBBqSAiBSZXF1aXJlZC4gVGhlIG5h
bWUgb2YgdGhlIGZyYW1ld29yayB0byByZXRyaWV2ZSwgaW4gb25lIG9mIHRoZSBmb2xsb3dp
bmcKIGZvcm1hdHM6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9mcmFtZXdvcmtzL3tmcmFtZXdvcmt9YAogb3IKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZnJhbWV3b3Jrcy97ZnJhbWV3b3JrfWAuCgog
VGhlIG9ubHkgc3VwcG9ydGVkIGxvY2F0aW9uIGlzIGBnbG9iYWxgLgoKDQoFBAICAAUSBIkC
AggKDQoFBAICAAESBIkCCQ0KDQoFBAICAAMSBIkCEBEKDwoFBAICAAgSBokCEo4CAwoQCggE
AgIACJwIABIEigIEKgoRCgcEAgIACJ8IEgaLAgSNAgUKiwEKBAQCAgESBJICAkcafSBPcHRp
b25hbC4gVGhlIGZyYW1ld29yayBtYWpvciB2ZXJzaW9uIHRvIHJldHJpZXZlLiBJZiBub3Qg
c3BlY2lmaWVkLCB0aGUKIG1vc3QgcmVjZW50bHkgdXBkYXRlZCBgcmV2aXNpb25faWRgIGlz
IHJldHJpZXZlZC4KCg0KBQQCAgEFEgSSAgIHCg0KBQQCAgEBEgSSAggZCg0KBQQCAgEDEgSS
AhwdCg0KBQQCAgEIEgSSAh5GChAKCAQCAgEInAgAEgSSAh9FCjwKAgQDEgaWAgCpAgEaLiBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvciBbQ3JlYXRlRnJhbWV3b3JrXVtdLgoKCwoDBAMBEgSW
AggeCucBCgQEAwIAEgacAgKhAgQa1gEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ug
bmFtZSwgaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0czoKIC0gYG9yZ2FuaXphdGlv
bnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCiAtIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKIFRoZSBvbmx5IHN1cHBvcnRlZCBs
b2NhdGlvbiBpcyBgZ2xvYmFsYC4KCg0KBQQDAgAFEgScAgIICg0KBQQDAgABEgScAgkPCg0K
BQQDAgADEgScAhITCg8KBQQDAgAIEgacAhShAgMKEAoIBAMCAAicCAASBJ0CBCoKEQoHBAMC
AAifCBIGngIEoAIFCqUBCgQEAwIBEgSlAgJDGpYBIFJlcXVpcmVkLiBUaGUgaWRlbnRpZmll
ciAoSUQpIG9mIHRoZSBmcmFtZXdvcmsuIFRoZSBJRCBpcyBub3QgdGhlIGZ1bGwgbmFtZQog
b2YgdGhlIGZyYW1ld29yazsgaXQncyB0aGUgbGFzdCBwYXJ0IG9mIHRoZSBmdWxsIG5hbWUg
b2YgdGhlIGZyYW1ld29yay4KCg0KBQQDAgEFEgSlAgIICg0KBQQDAgEBEgSlAgkVCg0KBQQD
AgEDEgSlAhgZCg0KBQQDAgEIEgSlAhpCChAKCAQDAgEInAgAEgSlAhtBCjUKBAQDAgISBKgC
AkMaJyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGJlaW5nIGNyZWF0ZWQuCgoNCgUEAwICBhIE
qAICCwoNCgUEAwICARIEqAIMFQoNCgUEAwICAxIEqAIYGQoNCgUEAwICCBIEqAIaQgoQCggE
AwICCJwIABIEqAIbQQo8CgIEBBIGrAIAugIBGi4gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3Ig
W1VwZGF0ZUZyYW1ld29ya11bXS4KCgsKAwQEARIErAIIHgrpAgoEBAQCABIGsgICswIvGtgC
IE9wdGlvbmFsLiBBIGZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMg
dG8gYmUgb3ZlcndyaXR0ZW4gaW4KIHRoZSBmcmFtZXdvcmsgcmVzb3VyY2UgYnkgdGhlIHVw
ZGF0ZS4gVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlCiBgdXBkYXRlX21hc2tgIGFyZSBy
ZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdCB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxk
CiBpcyBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgeW91IGRvbid0IHBy
b3ZpZGUgYSBtYXNrIHRoZW4gYWxsCiBmaWVsZHMgcHJlc2VudCBpbiB0aGUgcmVxdWVzdCB3
aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoFBAQCAAYSBLICAhsKDQoFBAQCAAESBLICHCcKDQoF
BAQCAAMSBLICKisKDQoFBAQCAAgSBLMCBi4KEAoIBAQCAAicCAASBLMCBy0KPQoEBAQCARIE
tgICQxovIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgdGhhdCBpcyBiZWluZyB1cGRhdGVkLgoK
DQoFBAQCAQYSBLYCAgsKDQoFBAQCAQESBLYCDBUKDQoFBAQCAQMSBLYCGBkKDQoFBAQCAQgS
BLYCGkIKEAoIBAQCAQicCAASBLYCG0EKSgoEBAQCAhIEuQICRxo8IE9wdGlvbmFsLiBUaGUg
bWFqb3IgdmVyc2lvbiBJRCBvZiB0aGUgZnJhbWV3b3JrIHRvIHVwZGF0ZS4KCg0KBQQEAgIF
EgS5AgIHCg0KBQQEAgIBEgS5AggZCg0KBQQEAgIDEgS5AhwdCg0KBQQEAgIIEgS5Ah5GChAK
CAQEAgIInAgAEgS5Ah9FCjgKAgQFEga9AgDKAgEaKiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFtE
ZWxldGVGcmFtZXdvcmtdW10uCgoLCgMEBQESBL0CCB4KlQIKBAQFAgASBsQCAskCBBqEAiBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHJlc291cmNlLCBpbiBvbmUgb2YgdGhlIGZvbGxv
d2luZyBmb3JtYXRzOgogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZnJhbWV3b3Jrcy97ZnJhbWV3b3JrfWAKIG9yCiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2ZyYW1ld29ya3Mve2ZyYW1ld29ya31gLgoK
IFRoZSBvbmx5IHN1cHBvcnRlZCBsb2NhdGlvbiBpcyBgZ2xvYmFsYC4KCg0KBQQFAgAFEgTE
AgIICg0KBQQFAgABEgTEAgkNCg0KBQQFAgADEgTEAhARCg8KBQQFAgAIEgbEAhLJAgMKEAoI
BAUCAAicCAASBMUCBCoKEQoHBAUCAAifCBIGxgIEyAIFCjoKAgQGEgbNAgDpAgEaLCBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIFtMaXN0Q2xvdWRDb250cm9sc11bXS4KCgsKAwQGARIEzQIIIArn
AQoEBAYCABIG0wIC2AIEGtYBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUs
IGluIG9uZSBvZiB0aGUgZm9sbG93aW5nIGZvcm1hdHM6CiAtIGBvcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259YAogLSBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCiBUaGUgb25seSBzdXBwb3J0ZWQgbG9jYXRp
b24gaXMgYGdsb2JhbGAuCgoNCgUEBgIABRIE0wICCAoNCgUEBgIAARIE0wIJDwoNCgUEBgIA
AxIE0wISEwoPCgUEBgIACBIG0wIU2AIDChAKCAQGAgAInAgAEgTUAgQqChEKBwQGAgAInwgS
BtUCBNcCBQq+AQoEBAYCARIE3wICPxqvASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVy
IG9mIGNsb3VkIGNvbnRyb2xzIHRvIHJldHVybi4gVGhlIGRlZmF1bHQgdmFsdWUKIGlzIGA1
MDBgLgoKIElmIHlvdSBleGNlZWQgdGhlIG1heGltdW0gdmFsdWUgb2YgYDEwMDBgLCB0aGVu
IHRoZSBzZXJ2aWNlIHVzZXMgdGhlCiBtYXhpbXVtIHZhbHVlLgoKDQoFBAYCAQUSBN8CAgcK
DQoFBAYCAQESBN8CCBEKDQoFBAYCAQMSBN8CFBUKDQoFBAYCAQgSBN8CFj4KEAoIBAYCAQic
CAASBN8CFz0K8AIKBAQGAgISBOgCAkEa4QIgT3B0aW9uYWwuIEEgcGFnaW5hdGlvbiB0b2tl
biB0aGF0J3MgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIHJlcXVlc3QgdG8KIGxpc3QgY2xv
dWQgY29udHJvbHMuIFByb3ZpZGUgdGhpcyB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBw
YWdlIG9mCiByZXN1bHRzLgoKIFdoZW4gcGFnaW5hdGluZywgdGhlIHBhcmVudCB0aGF0IHlv
dSBwcm92aWRlIHRvIHRoZQogW0xpc3RDbG91ZENvbnRyb2xzXVtnb29nbGUuY2xvdWQuY2xv
dWRzZWN1cml0eWNvbXBsaWFuY2UudjEuQ29uZmlnLkxpc3RDbG91ZENvbnRyb2xzXQogcmVx
dWVzdCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4u
CgoNCgUEBgICBRIE6AICCAoNCgUEBgICARIE6AIJEwoNCgUEBgICAxIE6AIWFwoNCgUEBgIC
CBIE6AIYQAoQCggEBgICCJwIABIE6AIZPwo/CgIEBxIG7AIA8wIBGjEgVGhlIHJlc3BvbnNl
IG1lc3NhZ2UgZm9yIFtMaXN0Q2xvdWRDb250cm9sc11bXS4KCgsKAwQHARIE7AIIIQozCgQE
BwIAEgTuAgIrGiUgVGhlIGxpc3Qgb2YgQ2xvdWRDb250cm9sIHJlc291cmNlcy4KCg0KBQQH
AgAEEgTuAgIKCg0KBQQHAgAGEgTuAgsXCg0KBQQHAgABEgTuAhgmCg0KBQQHAgADEgTuAikq
CnEKBAQHAgESBPICAh0aYyBBIHBhZ2luYXRpb24gdG9rZW4uIFRvIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2Ugb2YgcmVzdWx0cywgY2FsbCB0aGUgbWV0aG9kCiBhZ2FpbiB3aXRoIHRoaXMg
dG9rZW4uCgoNCgUEBwIBBRIE8gICCAoNCgUEBwIBARIE8gIJGAoNCgUEBwIBAxIE8gIbHAo8
CgIECBIG9gIAiAMBGi4gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgW0dldENsb3VkQ29udHJv
bF1bXS4KCgsKAwQIARIE9gIIHgq1AgoEBAgCABIG/gICgwMEGqQCIFJlcXVpcmVkLiBUaGUg
bmFtZSBvZiB0aGUgY2xvdWQgY29udHJvbCB0byByZXRyaWV2ZSwgaW4gb25lIG9mIHRoZQog
Zm9sbG93aW5nIGZvcm1hdHM6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jbG91ZENvbnRyb2xzL3tjbG91ZF9jb250cm9sfWAKIG9yCiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nsb3VkQ29udHJvbHMv
e2Nsb3VkX2NvbnRyb2x9YC4KCiBUaGUgb25seSBzdXBwb3J0ZWQgbG9jYXRpb24gaXMgYGds
b2JhbGAuCgoNCgUECAIABRIE/gICCAoNCgUECAIAARIE/gIJDQoNCgUECAIAAxIE/gIQEQoP
CgUECAIACBIG/gISgwMDChAKCAQIAgAInAgAEgT/AgQqChEKBwQIAgAInwgSBoADBIIDBQqX
AQoEBAgCARIEhwMCRxqIASBPcHRpb25hbC4gVGhlIG1ham9yIHZlcnNpb24gb2YgdGhlIGNs
b3VkIGNvbnRyb2wgdG8gcmV0cmlldmUuIElmIG5vdAogc3BlY2lmaWVkLCB0aGUgbW9zdCBy
ZWNlbnRseSB1cGRhdGVkIGByZXZpc2lvbl9pZGAgaXMgcmV0cmlldmVkLgoKDQoFBAgCAQUS
BIcDAgcKDQoFBAgCAQESBIcDCBkKDQoFBAgCAQMSBIcDHB0KDQoFBAgCAQgSBIcDHkYKEAoI
BAgCAQicCAASBIcDH0UKPwoCBAkSBosDAJ8DARoxIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9y
IFtDcmVhdGVDbG91ZENvbnRyb2xdW10uCgoLCgMECQESBIsDCCEK6AEKBAQJAgASBpEDApYD
BBrXASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLCBpbiBvbmUgb2YgdGhl
IGZvbGxvd2luZyBmb3JtYXRzOgogLSBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9s
b2NhdGlvbnMve2xvY2F0aW9ufWAuCiAtIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn1gLgoKIFRoZSBvbmx5IHN1cHBvcnRlZCBsb2NhdGlvbiBpcyBgZ2xvYmFs
YC4KCg0KBQQJAgAFEgSRAwIICg0KBQQJAgABEgSRAwkPCg0KBQQJAgADEgSRAxITCg8KBQQJ
AgAIEgaRAxSWAwMKEAoIBAkCAAicCAASBJIDBCoKEQoHBAkCAAifCBIGkwMElQMFCrABCgQE
CQIBEgSbAwJHGqEBIFJlcXVpcmVkLiBUaGUgaWRlbnRpZmllciBmb3IgdGhlIGNsb3VkIGNv
bnRyb2wsIHdoaWNoIGlzIHRoZSBsYXN0IHNlZ21lbnQKIG9mIHRoZSBjbG91ZCBjb250cm9s
IG5hbWUuIFRoZSBmb3JtYXQgaXMKIGBeW2EtekEtWl1bYS16QS1aMC05LV17MCw2MX1bYS16
QS1aMC05XSRgLgoKDQoFBAkCAQUSBJsDAggKDQoFBAkCAQESBJsDCRkKDQoFBAkCAQMSBJsD
HB0KDQoFBAkCAQgSBJsDHkYKEAoIBAkCAQicCAASBJsDH0UKQQoEBAkCAhIEngMCShozIFJl
cXVpcmVkLiBUaGUgY2xvdWQgY29udHJvbCB0aGF0J3MgYmVpbmcgY3JlYXRlZC4KCg0KBQQJ
AgIGEgSeAwIOCg0KBQQJAgIBEgSeAw8cCg0KBQQJAgIDEgSeAx8gCg0KBQQJAgIIEgSeAyFJ
ChAKCAQJAgIInAgAEgSeAyJICj8KAgQKEgaiAwC2AwEaMSBUaGUgcmVxdWVzdCBtZXNzYWdl
IGZvciBbVXBkYXRlQ2xvdWRDb250cm9sXVtdLgoKCwoDBAoBEgSiAwghCtYDCgQECgIAEgax
AwKyAy8axQMgT3B0aW9uYWwuIFVzZSBhIGZpZWxkIG1hc2sgdG8gc3BlY2lmeSB0aGUgZmll
bGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogY2xvdWQgY29udHJvbCBkdXJpbmcgdGhl
IHVwZGF0ZS4KIFRoZSBmaWVsZHMgdGhhdCB5b3Ugc3BlY2lmeSBpbiB0aGUgYHVwZGF0ZV9t
YXNrYCBhcmUgcmVsYXRpdmUgdG8gdGhlCiBjbG91ZCBjb250cm9sLCBub3QgdGhlIGZ1bGwg
cmVxdWVzdC4gQSBmaWVsZCBpcyBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbgogdGhlIG1hc2su
IElmIHlvdSBkb24ndCBwcm92aWRlIGEgbWFzaywgYWxsIGZpZWxkcyBpbiB0aGUgcmVxdWVz
dAogYXJlIHVwZGF0ZWQuCgogWW91IGNhbiB1cGRhdGUgdGhlIGZvbGxvd2luZyBmaWVsZHM6
CgogLSBEaXNwbGF5IG5hbWUKIC0gRGVzY3JpcHRpb24KIC0gUGFyYW1ldGVycwogLSBSdWxl
cwogLSBQYXJhbWV0ZXIgc3BlY2lmaWNhdGlvbgoKDQoFBAoCAAYSBLEDAhsKDQoFBAoCAAES
BLEDHCcKDQoFBAoCAAMSBLEDKisKDQoFBAoCAAgSBLIDBi4KEAoIBAoCAAicCAASBLIDBy0K
QQoEBAoCARIEtQMCShozIFJlcXVpcmVkLiBUaGUgY2xvdWQgY29udHJvbCB0aGF0IHlvdSdy
ZSB1cGRhdGluZy4KCg0KBQQKAgEGEgS1AwIOCg0KBQQKAgEBEgS1Aw8cCg0KBQQKAgEDEgS1
Ax8gCg0KBQQKAgEIEgS1AyFJChAKCAQKAgEInAgAEgS1AyJICj8KAgQLEga5AwDHAwEaMSBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvciBbRGVsZXRlQ2xvdWRDb250cm9sXVtdLgoKCwoDBAsB
EgS5AwghCrECCgQECwIAEgbBAwLGAwQaoAIgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBj
bG91ZCBjb250cm9sIHRvIGRlbGV0ZSwgaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcKIGZvcm1h
dHM6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9DbG91ZENvbnRyb2xzL3tDbG91ZENvbnRyb2x9YAogb3IKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vQ2xvdWRDb250cm9scy97Q2xvdWRDb250cm9sfWAu
CgogVGhlIG9ubHkgc3VwcG9ydGVkIGxvY2F0aW9uIGlzIGBnbG9iYWxgLgoKDQoFBAsCAAUS
BMEDAggKDQoFBAsCAAESBMEDCQ0KDQoFBAsCAAMSBMEDEBEKDwoFBAsCAAgSBsEDEsYDAwoQ
CggECwIACJwIABIEwgMEKgoRCgcECwIACJ8IEgbDAwTFAwViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest ===
    # Fields for ListFrameworksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse ===
    # Fields for ListFrameworksResponse
    # Field: frameworks Type: 11 (.google.cloud.cloudsecuritycompliance.v1.Framework)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::GetFrameworkRequest ===
    # Fields for GetFrameworkRequest
    # Field: name Type: 9 ()
    # Field: major_revision_id Type: 3 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateFrameworkRequest ===
    # Fields for CreateFrameworkRequest
    # Field: parent Type: 9 ()
    # Field: framework_id Type: 9 ()
    # Field: framework Type: 11 (.google.cloud.cloudsecuritycompliance.v1.Framework)

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateFrameworkRequest ===
    # Fields for UpdateFrameworkRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: framework Type: 11 (.google.cloud.cloudsecuritycompliance.v1.Framework)
    # Field: major_revision_id Type: 3 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteFrameworkRequest ===
    # Fields for DeleteFrameworkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsRequest ===
    # Fields for ListCloudControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsResponse ===
    # Fields for ListCloudControlsResponse
    # Field: cloud_controls Type: 11 (.google.cloud.cloudsecuritycompliance.v1.CloudControl)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::GetCloudControlRequest ===
    # Fields for GetCloudControlRequest
    # Field: name Type: 9 ()
    # Field: major_revision_id Type: 3 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateCloudControlRequest ===
    # Fields for CreateCloudControlRequest
    # Field: parent Type: 9 ()
    # Field: cloud_control_id Type: 9 ()
    # Field: cloud_control Type: 11 (.google.cloud.cloudsecuritycompliance.v1.CloudControl)

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateCloudControlRequest ===
    # Fields for UpdateCloudControlRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: cloud_control Type: 11 (.google.cloud.cloudsecuritycompliance.v1.CloudControl)

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteCloudControlRequest ===
    # Fields for DeleteCloudControlRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Cloudsecuritycompliance::V1::Config::ConfigClient ===
package Google::Cloud::Cloudsecuritycompliance::V1::Config::ConfigClient;

=pod

=head2 Service Client: Google::Cloud::Cloudsecuritycompliance::V1::Config::ConfigClient

Client stub representing the remote C<Config> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<cloudsecuritycompliance.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'cloudsecuritycompliance.googleapis.com:443' );

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

sub list_frameworks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'ListFrameworks',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse',
    });
}

sub get_framework {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::GetFrameworkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'GetFramework',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework',
    });
}

sub create_framework {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateFrameworkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'CreateFramework',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework',
    });
}

sub update_framework {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateFrameworkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'UpdateFramework',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework',
    });
}

sub delete_framework {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteFrameworkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'DeleteFramework',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_cloud_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'ListCloudControls',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsResponse',
    });
}

sub get_cloud_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::GetCloudControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'GetCloudControl',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl',
    });
}

sub create_cloud_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateCloudControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'CreateCloudControl',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl',
    });
}

sub update_cloud_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateCloudControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'UpdateCloudControl',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl',
    });
}

sub delete_cloud_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteCloudControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.Config',
        method         => 'DeleteCloudControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::Config - Compiled Protocol Buffers messages for google/cloud/cloudsecuritycompliance/v1/config.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudsecuritycompliance::V1::Config;

    my $msg = Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudsecuritycompliance/v1/config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest

Request message for [ListFrameworks][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, in one of the following formats:
- `organizations/{organization}/locations/{location}`
- `projects/{project}/locations/{location}`.

The only supported location is `global`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of frameworks to return. The default value is
`500`.

If you exceed the maximum value of `1000`, then the service uses the
maximum value.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous request to list
frameworks. Provide this token to retrieve the next page of results.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse

The response message for [ListFrameworks][].
Returns a paginated list of Framework resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->frameworks() >> / C<< $msg->frameworks($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework>)

The list of framework resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token. To retrieve the next page of results, call the method
again with this token.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::GetFrameworkRequest

The request message for [GetFramework][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the framework to retrieve, in one of the following
formats:
`organizations/{organization}/locations/{location}/frameworks/{framework}`
or
`projects/{project}/locations/{location}/frameworks/{framework}`.

The only supported location is `global`.

=item * C<< $msg->major_revision_id() >> / C<< $msg->major_revision_id($value) >>

Type: C<Int64>

Optional. The framework major version to retrieve. If not specified, the
most recently updated `revision_id` is retrieved.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateFrameworkRequest

The request message for [CreateFramework][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, in one of the following formats:
- `organizations/{organization}/locations/{location}`
- `projects/{project}/locations/{location}`.

The only supported location is `global`.

=item * C<< $msg->framework_id() >> / C<< $msg->framework_id($value) >>

Type: C<String>

Required. The identifier (ID) of the framework. The ID is not the full name
of the framework; it's the last part of the full name of the framework.

=item * C<< $msg->framework() >> / C<< $msg->framework($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework>)

Required. The resource being created.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateFrameworkRequest

The request message for [UpdateFramework][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A field mask is used to specify the fields to be overwritten in
the framework resource by the update. The fields specified in the
`update_mask` are relative to the resource, not the full request. A field
is overwritten if it is in the mask. If you don't provide a mask then all
fields present in the request will be overwritten.

=item * C<< $msg->framework() >> / C<< $msg->framework($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework>)

Required. The resource that is being updated.

=item * C<< $msg->major_revision_id() >> / C<< $msg->major_revision_id($value) >>

Type: C<Int64>

Optional. The major version ID of the framework to update.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteFrameworkRequest

Request message for [DeleteFramework][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource, in one of the following formats:
`organizations/{organization}/locations/{location}/frameworks/{framework}`
or
`projects/{project}/locations/{location}/frameworks/{framework}`.

The only supported location is `global`.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsRequest

Request message for [ListCloudControls][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, in one of the following formats:
- `organizations/{organization}/locations/{location}`
- `projects/{project}/locations/{location}`.

The only supported location is `global`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of cloud controls to return. The default value
is `500`.

If you exceed the maximum value of `1000`, then the service uses the
maximum value.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token that's returned from a previous request to
list cloud controls. Provide this token to retrieve the next page of
results.

When paginating, the parent that you provide to the
[ListCloudControls][google.cloud.cloudsecuritycompliance.v1.Config.ListCloudControls]
request must match the call that provided the page token.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsResponse

The response message for [ListCloudControls][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_controls() >> / C<< $msg->cloud_controls($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl>)

The list of CloudControl resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token. To retrieve the next page of results, call the method
again with this token.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::GetCloudControlRequest

The request message for [GetCloudControl][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the cloud control to retrieve, in one of the
following formats:
`organizations/{organization}/locations/{location}/cloudControls/{cloud_control}`
or
`projects/{project}/locations/{location}/cloudControls/{cloud_control}`.

The only supported location is `global`.

=item * C<< $msg->major_revision_id() >> / C<< $msg->major_revision_id($value) >>

Type: C<Int64>

Optional. The major version of the cloud control to retrieve. If not
specified, the most recently updated `revision_id` is retrieved.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateCloudControlRequest

The request message for [CreateCloudControl][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, in one of the following formats:
- `organizations/{organization}/locations/{location}`.
- `projects/{project}/locations/{location}`.

The only supported location is `global`.

=item * C<< $msg->cloud_control_id() >> / C<< $msg->cloud_control_id($value) >>

Type: C<String>

Required. The identifier for the cloud control, which is the last segment
of the cloud control name. The format is
`^[a-zA-Z][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]$`.

=item * C<< $msg->cloud_control() >> / C<< $msg->cloud_control($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl>)

Required. The cloud control that's being created.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateCloudControlRequest

The request message for [UpdateCloudControl][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Use a field mask to specify the fields to be overwritten in the
cloud control during the update.
The fields that you specify in the `update_mask` are relative to the
cloud control, not the full request. A field is overwritten if it is in
the mask. If you don't provide a mask, all fields in the request
are updated.

You can update the following fields:

- Display name
- Description
- Parameters
- Rules
- Parameter specification

=item * C<< $msg->cloud_control() >> / C<< $msg->cloud_control($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl>)

Required. The cloud control that you're updating.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteCloudControlRequest

The request message for [DeleteCloudControl][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the cloud control to delete, in one of the following
formats:
`organizations/{organization}/locations/{location}/CloudControls/{CloudControl}`
or
`projects/{project}/locations/{location}/CloudControls/{CloudControl}`.

The only supported location is `global`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudsecuritycompliance::V1::Config::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
