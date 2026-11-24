package Google::Cloud::Secrets::V1beta1::Service;

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
    eval { require Google::Cloud::Secrets::V1beta1::Resources };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvc2VjcmV0cy92MWJldGExL3NlcnZpY2UucHJvdG8SHGdvb2dsZS5j
bG91ZC5zZWNyZXRzLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGixnb29nbGUvY2xvdWQvc2VjcmV0cy92MWJl
dGExL3Jlc291cmNlcy5wcm90bxoeZ29vZ2xlL2lhbS92MS9pYW1fcG9saWN5LnByb3RvGhpn
b29nbGUvaWFtL3YxL3BvbGljeS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKnAQoSTGlzdFNlY3JldHNSZXF1
ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFuYWdlci5nb29n
bGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBh
Z2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpwBChNMaXN0U2Vj
cmV0c1Jlc3BvbnNlEj4KB3NlY3JldHMYASADKAsyJC5nb29nbGUuY2xvdWQuc2VjcmV0cy52
MWJldGExLlNlY3JldFIHc2VjcmV0cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4SHQoKdG90YWxfc2l6ZRgDIAEoBVIJdG90YWxTaXplIscBChNDcmVhdGVTZWNy
ZXRSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSIAoJc2VjcmV0X2lkGAIgASgJQgPg
QQJSCHNlY3JldElkEkEKBnNlY3JldBgDIAEoCzIkLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYx
YmV0YTEuU2VjcmV0QgPgQQJSBnNlY3JldCKqAQoXQWRkU2VjcmV0VmVyc2lvblJlcXVlc3QS
QwoGcGFyZW50GAEgASgJQivgQQL6QSUKI3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20v
U2VjcmV0UgZwYXJlbnQSSgoHcGF5bG9hZBgCIAEoCzIrLmdvb2dsZS5jbG91ZC5zZWNyZXRz
LnYxYmV0YTEuU2VjcmV0UGF5bG9hZEID4EECUgdwYXlsb2FkIlMKEEdldFNlY3JldFJlcXVl
c3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNzZWNyZXRtYW5hZ2VyLmdvb2dsZWFwaXMuY29t
L1NlY3JldFIEbmFtZSKmAQoZTGlzdFNlY3JldFZlcnNpb25zUmVxdWVzdBJDCgZwYXJlbnQY
ASABKAlCK+BBAvpBJQojc2VjcmV0bWFuYWdlci5nb29nbGVhcGlzLmNvbS9TZWNyZXRSBnBh
cmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4irAEKGkxpc3RTZWNyZXRWZXJzaW9uc1Jlc3BvbnNlEkcK
CHZlcnNpb25zGAEgAygLMisuZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRW
ZXJzaW9uUgh2ZXJzaW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4SHQoKdG90YWxfc2l6ZRgDIAEoBVIJdG90YWxTaXplImEKF0dldFNlY3JldFZlcnNpb25S
ZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqc2VjcmV0bWFuYWdlci5nb29nbGVhcGlz
LmNvbS9TZWNyZXRWZXJzaW9uUgRuYW1lIpoBChNVcGRhdGVTZWNyZXRSZXF1ZXN0EkEKBnNl
Y3JldBgBIAEoCzIkLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0QgPgQQJS
BnNlY3JldBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1h
c2tCA+BBAlIKdXBkYXRlTWFzayJkChpBY2Nlc3NTZWNyZXRWZXJzaW9uUmVxdWVzdBJGCgRu
YW1lGAEgASgJQjLgQQL6QSwKKnNlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0
VmVyc2lvblIEbmFtZSKpAQobQWNjZXNzU2VjcmV0VmVyc2lvblJlc3BvbnNlEkMKBG5hbWUY
ASABKAlCL/pBLAoqc2VjcmV0bWFuYWdlci5nb29nbGVhcGlzLmNvbS9TZWNyZXRWZXJzaW9u
UgRuYW1lEkUKB3BheWxvYWQYAiABKAsyKy5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGEx
LlNlY3JldFBheWxvYWRSB3BheWxvYWQiVgoTRGVsZXRlU2VjcmV0UmVxdWVzdBI/CgRuYW1l
GAEgASgJQivgQQL6QSUKI3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0UgRu
YW1lImUKG0Rpc2FibGVTZWNyZXRWZXJzaW9uUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6
QSwKKnNlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lvblIEbmFtZSJk
ChpFbmFibGVTZWNyZXRWZXJzaW9uUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKnNl
Y3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lvblIEbmFtZSJlChtEZXN0
cm95U2VjcmV0VmVyc2lvblJlcXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCipzZWNyZXRt
YW5hZ2VyLmdvb2dsZWFwaXMuY29tL1NlY3JldFZlcnNpb25SBG5hbWUygxYKFFNlY3JldE1h
bmFnZXJTZXJ2aWNlEqkBCgtMaXN0U2VjcmV0cxIwLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYx
YmV0YTEuTGlzdFNlY3JldHNSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRh
MS5MaXN0U2VjcmV0c1Jlc3BvbnNlIjWC0+STAiYSJC92MWJldGExL3twYXJlbnQ9cHJvamVj
dHMvKn0vc2VjcmV0c9pBBnBhcmVudBK3AQoMQ3JlYXRlU2VjcmV0EjEuZ29vZ2xlLmNsb3Vk
LnNlY3JldHMudjFiZXRhMS5DcmVhdGVTZWNyZXRSZXF1ZXN0GiQuZ29vZ2xlLmNsb3VkLnNl
Y3JldHMudjFiZXRhMS5TZWNyZXQiToLT5JMCLiIkL3YxYmV0YTEve3BhcmVudD1wcm9qZWN0
cy8qfS9zZWNyZXRzOgZzZWNyZXTaQRdwYXJlbnQsc2VjcmV0X2lkLHNlY3JldBLFAQoQQWRk
U2VjcmV0VmVyc2lvbhI1Lmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuQWRkU2VjcmV0
VmVyc2lvblJlcXVlc3QaKy5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZl
cnNpb24iTYLT5JMCNiIxL3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL3NlY3JldHMvKn06
YWRkVmVyc2lvbjoBKtpBDnBhcmVudCxwYXlsb2FkEpYBCglHZXRTZWNyZXQSLi5nb29nbGUu
Y2xvdWQuc2VjcmV0cy52MWJldGExLkdldFNlY3JldFJlcXVlc3QaJC5nb29nbGUuY2xvdWQu
c2VjcmV0cy52MWJldGExLlNlY3JldCIzgtPkkwImEiQvdjFiZXRhMS97bmFtZT1wcm9qZWN0
cy8qL3NlY3JldHMvKn3aQQRuYW1lErkBCgxVcGRhdGVTZWNyZXQSMS5nb29nbGUuY2xvdWQu
c2VjcmV0cy52MWJldGExLlVwZGF0ZVNlY3JldFJlcXVlc3QaJC5nb29nbGUuY2xvdWQuc2Vj
cmV0cy52MWJldGExLlNlY3JldCJQgtPkkwI1MisvdjFiZXRhMS97c2VjcmV0Lm5hbWU9cHJv
amVjdHMvKi9zZWNyZXRzLyp9OgZzZWNyZXTaQRJzZWNyZXQsdXBkYXRlX21hc2sSjgEKDERl
bGV0ZVNlY3JldBIxLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuRGVsZXRlU2VjcmV0
UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSIzgtPkkwImKiQvdjFiZXRhMS97bmFt
ZT1wcm9qZWN0cy8qL3NlY3JldHMvKn3aQQRuYW1lEskBChJMaXN0U2VjcmV0VmVyc2lvbnMS
Ny5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLkxpc3RTZWNyZXRWZXJzaW9uc1JlcXVl
c3QaOC5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLkxpc3RTZWNyZXRWZXJzaW9uc1Jl
c3BvbnNlIkCC0+STAjESLy92MWJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9zZWNyZXRzLyp9
L3ZlcnNpb25z2kEGcGFyZW50ErYBChBHZXRTZWNyZXRWZXJzaW9uEjUuZ29vZ2xlLmNsb3Vk
LnNlY3JldHMudjFiZXRhMS5HZXRTZWNyZXRWZXJzaW9uUmVxdWVzdBorLmdvb2dsZS5jbG91
ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbiI+gtPkkwIxEi8vdjFiZXRhMS97bmFt
ZT1wcm9qZWN0cy8qL3NlY3JldHMvKi92ZXJzaW9ucy8qfdpBBG5hbWUS0QEKE0FjY2Vzc1Nl
Y3JldFZlcnNpb24SOC5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLkFjY2Vzc1NlY3Jl
dFZlcnNpb25SZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5BY2Nlc3NT
ZWNyZXRWZXJzaW9uUmVzcG9uc2UiRYLT5JMCOBI2L3YxYmV0YTEve25hbWU9cHJvamVjdHMv
Ki9zZWNyZXRzLyovdmVyc2lvbnMvKn06YWNjZXNz2kEEbmFtZRLJAQoURGlzYWJsZVNlY3Jl
dFZlcnNpb24SOS5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLkRpc2FibGVTZWNyZXRW
ZXJzaW9uUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVy
c2lvbiJJgtPkkwI8IjcvdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL3NlY3JldHMvKi92ZXJz
aW9ucy8qfTpkaXNhYmxlOgEq2kEEbmFtZRLGAQoTRW5hYmxlU2VjcmV0VmVyc2lvbhI4Lmdv
b2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuRW5hYmxlU2VjcmV0VmVyc2lvblJlcXVlc3Qa
Ky5nb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb24iSILT5JMCOyI2
L3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9zZWNyZXRzLyovdmVyc2lvbnMvKn06ZW5hYmxl
OgEq2kEEbmFtZRLJAQoURGVzdHJveVNlY3JldFZlcnNpb24SOS5nb29nbGUuY2xvdWQuc2Vj
cmV0cy52MWJldGExLkRlc3Ryb3lTZWNyZXRWZXJzaW9uUmVxdWVzdBorLmdvb2dsZS5jbG91
ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbiJJgtPkkwI8IjcvdjFiZXRhMS97bmFt
ZT1wcm9qZWN0cy8qL3NlY3JldHMvKi92ZXJzaW9ucy8qfTpkZXN0cm95OgEq2kEEbmFtZRKL
AQoMU2V0SWFtUG9saWN5EiIuZ29vZ2xlLmlhbS52MS5TZXRJYW1Qb2xpY3lSZXF1ZXN0GhUu
Z29vZ2xlLmlhbS52MS5Qb2xpY3kiQILT5JMCOiI1L3YxYmV0YTEve3Jlc291cmNlPXByb2pl
Y3RzLyovc2VjcmV0cy8qfTpzZXRJYW1Qb2xpY3k6ASoSiAEKDEdldElhbVBvbGljeRIiLmdv
b2dsZS5pYW0udjEuR2V0SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5
Ij2C0+STAjcSNS92MWJldGExL3tyZXNvdXJjZT1wcm9qZWN0cy8qL3NlY3JldHMvKn06Z2V0
SWFtUG9saWN5ErEBChJUZXN0SWFtUGVybWlzc2lvbnMSKC5nb29nbGUuaWFtLnYxLlRlc3RJ
YW1QZXJtaXNzaW9uc1JlcXVlc3QaKS5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9u
c1Jlc3BvbnNlIkaC0+STAkAiOy92MWJldGExL3tyZXNvdXJjZT1wcm9qZWN0cy8qL3NlY3Jl
dHMvKn06dGVzdElhbVBlcm1pc3Npb25zOgEqGlDKQRxzZWNyZXRtYW5hZ2VyLmdvb2dsZWFw
aXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bULsAQomY29tLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxYmV0YTFCDFNlcnZpY2VQ
cm90b1ABWjpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3JldHMvYXBpdjFiZXRhMS9zZWNyZXRz
cGI7c2VjcmV0c3BiogIDR1NNqgIiR29vZ2xlLkNsb3VkLlNlY3JldE1hbmFnZXIuVjFCZXRh
McoCIkdvb2dsZVxDbG91ZFxTZWNyZXRNYW5hZ2VyXFYxYmV0YTHqAiVHb29nbGU6OkNsb3Vk
OjpTZWNyZXRNYW5hZ2VyOjpWMWJldGExSuJ0CgcSBQ4A0gMBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgID
AhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANgoJCgIDBRIDFwAoCgkKAgMGEgMYACQKCQoC
AwcSAxkAJQoJCgIDCBIDGgAqCggKAQgSAxwAPwoJCgIIJRIDHAA/CggKAQgSAx0AUQoJCgII
CxIDHQBRCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8ALQoJCgIICBIDHwAtCggKAQgS
AyAAPwoJCgIIARIDIAA/CggKAQgSAyEAIQoJCgIIJBIDIQAhCggKAQgSAyIAPwoJCgIIKRID
IgA/CggKAQgSAyMAPgoJCgIILRIDIwA+CoICCgIGABIFLADaAQEa9AEgU2VjcmV0IE1hbmFn
ZXIgU2VydmljZQoKIE1hbmFnZXMgc2VjcmV0cyBhbmQgb3BlcmF0aW9ucyB1c2luZyB0aG9z
ZSBzZWNyZXRzLiBJbXBsZW1lbnRzIGEgUkVTVAogbW9kZWwgd2l0aCB0aGUgZm9sbG93aW5n
IG9iamVjdHM6CgogKiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNl
Y3JldF0KICogW1NlY3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEu
U2VjcmV0VmVyc2lvbl0KCgoKAwYAARIDLAgcCgoKAwYAAxIDLQJECgwKBQYAA5kIEgMtAkQK
CwoDBgADEgQuAi83Cg0KBQYAA5oIEgQuAi83CkUKBAYAAgASBDICNwMaNyBMaXN0cyBbU2Vj
cmV0c11bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRdLgoKDAoFBgACAAES
AzIGEQoMCgUGAAIAAhIDMhIkCgwKBQYAAgADEgMyL0IKDQoFBgACAAQSBDMENQYKEQoJBgAC
AASwyrwiEgQzBDUGCgwKBQYAAgAEEgM2BDQKDwoIBgACAASbCAASAzYENAqZAQoEBgACARIE
OwJBAxqKASBDcmVhdGVzIGEgbmV3IFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYx
YmV0YTEuU2VjcmV0XSBjb250YWluaW5nIG5vCiBbU2VjcmV0VmVyc2lvbnNdW2dvb2dsZS5j
bG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0uCgoMCgUGAAIBARIDOwYSCgwK
BQYAAgECEgM7EyYKDAoFBgACAQMSAzsxNwoNCgUGAAIBBBIEPAQ/BgoRCgkGAAIBBLDKvCIS
BDwEPwYKDAoFBgACAQQSA0AERQoPCggGAAIBBJsIABIDQARFCsEBCgQGAAICEgRGAkwDGrIB
IENyZWF0ZXMgYSBuZXcgW1NlY3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYx
YmV0YTEuU2VjcmV0VmVyc2lvbl0KIGNvbnRhaW5pbmcgc2VjcmV0IGRhdGEgYW5kIGF0dGFj
aGVzIGl0IHRvIGFuIGV4aXN0aW5nCiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52
MWJldGExLlNlY3JldF0uCgoMCgUGAAICARIDRgYWCgwKBQYAAgICEgNGFy4KDAoFBgACAgMS
A0Y5RgoNCgUGAAICBBIERwRKBgoRCgkGAAICBLDKvCISBEcESgYKDAoFBgACAgQSA0sEPAoP
CggGAAICBJsIABIDSwQ8ClgKBAYAAgMSBE8CVAMaSiBHZXRzIG1ldGFkYXRhIGZvciBhIGdp
dmVuIFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XS4KCgwK
BQYAAgMBEgNPBg8KDAoFBgACAwISA08QIAoMCgUGAAIDAxIDTysxCg0KBQYAAgMEEgRQBFIG
ChEKCQYAAgMEsMq8IhIEUARSBgoMCgUGAAIDBBIDUwQyCg8KCAYAAgMEmwgAEgNTBDIKXwoE
BgACBBIEWAJeAxpRIFVwZGF0ZXMgbWV0YWRhdGEgb2YgYW4gZXhpc3RpbmcKIFtTZWNyZXRd
W2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XS4KCgwKBQYAAgQBEgNYBhIK
DAoFBgACBAISA1gTJgoMCgUGAAIEAxIDWDE3Cg0KBQYAAgQEEgRZBFwGChEKCQYAAgQEsMq8
IhIEWQRcBgoMCgUGAAIEBBIDXQRACg8KCAYAAgQEmwgAEgNdBEAKSAoEBgACBRIEYQJmAxo6
IERlbGV0ZXMgYSBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3Jl
dF0uCgoMCgUGAAIFARIDYQYSCgwKBQYAAgUCEgNhEyYKDAoFBgACBQMSA2ExRgoNCgUGAAIF
BBIEYgRkBgoRCgkGAAIFBLDKvCISBGIEZAYKDAoFBgACBQQSA2UEMgoPCggGAAIFBJsIABID
ZQQyCnsKBAYAAgYSBGoCcAMabSBMaXN0cyBbU2VjcmV0VmVyc2lvbnNdW2dvb2dsZS5jbG91
ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0uIFRoaXMKIGNhbGwgZG9lcyBub3Qg
cmV0dXJuIHNlY3JldCBkYXRhLgoKDAoFBgACBgESA2oGGAoMCgUGAAIGAhIDahkyCgwKBQYA
AgYDEgNrDykKDQoFBgACBgQSBGwEbgYKEQoJBgACBgSwyrwiEgRsBG4GCgwKBQYAAgYEEgNv
BDQKDwoIBgACBgSbCAASA28ENArlAQoEBgACBxIEdwJ8AxrWASBHZXRzIG1ldGFkYXRhIGZv
ciBhCiBbU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNy
ZXRWZXJzaW9uXS4KCiBgcHJvamVjdHMvKi9zZWNyZXRzLyovdmVyc2lvbnMvbGF0ZXN0YCBp
cyBhbiBhbGlhcyB0byB0aGUgYGxhdGVzdGAKIFtTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xv
dWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb25dLgoKDAoFBgACBwESA3cGFgoMCgUG
AAIHAhIDdxcuCgwKBQYAAgcDEgN3OUYKDQoFBgACBwQSBHgEegYKEQoJBgACBwSwyrwiEgR4
BHoGCgwKBQYAAgcEEgN7BDIKDwoIBgACBwSbCAASA3sEMgqBAgoEBgACCBIGgwECiQEDGvAB
IEFjY2Vzc2VzIGEgW1NlY3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0
YTEuU2VjcmV0VmVyc2lvbl0uCiBUaGlzIGNhbGwgcmV0dXJucyB0aGUgc2VjcmV0IGRhdGEu
CgogYHByb2plY3RzLyovc2VjcmV0cy8qL3ZlcnNpb25zL2xhdGVzdGAgaXMgYW4gYWxpYXMg
dG8gdGhlIGBsYXRlc3RgCiBbU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMu
djFiZXRhMS5TZWNyZXRWZXJzaW9uXS4KCg0KBQYAAggBEgSDAQYZCg0KBQYAAggCEgSDARo0
Cg0KBQYAAggDEgSEAQ8qCg8KBQYAAggEEgaFAQSHAQYKEwoJBgACCASwyrwiEgaFAQSHAQYK
DQoFBgACCAQSBIgBBDIKEAoIBgACCASbCAASBIgBBDIKrgIKBAYAAgkSBpABApcBAxqdAiBE
aXNhYmxlcyBhIFtTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGEx
LlNlY3JldFZlcnNpb25dLgoKIFNldHMgdGhlIFtzdGF0ZV1bZ29vZ2xlLmNsb3VkLnNlY3Jl
dHMudjFiZXRhMS5TZWNyZXRWZXJzaW9uLnN0YXRlXSBvZiB0aGUKIFtTZWNyZXRWZXJzaW9u
XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb25dIHRvCiBbRElT
QUJMRURdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbi5TdGF0
ZS5ESVNBQkxFRF0uCgoNCgUGAAIJARIEkAEGGgoNCgUGAAIJAhIEkAEbNgoNCgUGAAIJAxIE
kQEPHAoPCgUGAAIJBBIGkgEElQEGChMKCQYAAgkEsMq8IhIGkgEElQEGCg0KBQYAAgkEEgSW
AQQyChAKCAYAAgkEmwgAEgSWAQQyCqsCCgQGAAIKEgaeAQKkAQMamgIgRW5hYmxlcyBhIFtT
ZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNp
b25dLgoKIFNldHMgdGhlIFtzdGF0ZV1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5T
ZWNyZXRWZXJzaW9uLnN0YXRlXSBvZiB0aGUKIFtTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xv
dWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb25dIHRvCiBbRU5BQkxFRF1bZ29vZ2xl
LmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRWZXJzaW9uLlN0YXRlLkVOQUJMRURdLgoK
DQoFBgACCgESBJ4BBhkKDQoFBgACCgISBJ4BGjQKDQoFBgACCgMSBJ4BP0wKDwoFBgACCgQS
Bp8BBKIBBgoTCgkGAAIKBLDKvCISBp8BBKIBBgoNCgUGAAIKBBIEowEEMgoQCggGAAIKBJsI
ABIEowEEMgraAgoEBgACCxIGrAECswEDGskCIERlc3Ryb3lzIGEgW1NlY3JldFZlcnNpb25d
W2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0uCgogU2V0cyB0
aGUgW3N0YXRlXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb24u
c3RhdGVdIG9mIHRoZQogW1NlY3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYx
YmV0YTEuU2VjcmV0VmVyc2lvbl0gdG8KIFtERVNUUk9ZRURdW2dvb2dsZS5jbG91ZC5zZWNy
ZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbi5TdGF0ZS5ERVNUUk9ZRURdIGFuZAogaXJyZXZv
Y2FibHkgZGVzdHJveXMgdGhlIHNlY3JldCBkYXRhLgoKDQoFBgACCwESBKwBBhoKDQoFBgAC
CwISBKwBGzYKDQoFBgACCwMSBK0BDxwKDwoFBgACCwQSBq4BBLEBBgoTCgkGAAILBLDKvCIS
Bq4BBLEBBgoNCgUGAAILBBIEsgEEMgoQCggGAAILBJsIABIEsgEEMgqjAgoEBgACDBIGuwEC
wQEDGpICIFNldHMgdGhlIGFjY2VzcyBjb250cm9sIHBvbGljeSBvbiB0aGUgc3BlY2lmaWVk
IHNlY3JldC4gUmVwbGFjZXMgYW55CiBleGlzdGluZyBwb2xpY3kuCgogUGVybWlzc2lvbnMg
b24gW1NlY3JldFZlcnNpb25zXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3Jl
dFZlcnNpb25dCiBhcmUgZW5mb3JjZWQgYWNjb3JkaW5nIHRvIHRoZSBwb2xpY3kgc2V0IG9u
IHRoZSBhc3NvY2lhdGVkCiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGEx
LlNlY3JldF0uCgoNCgUGAAIMARIEuwEGEgoNCgUGAAIMAhIEuwETNAoNCgUGAAIMAxIEvAEP
IwoPCgUGAAIMBBIGvQEEwAEGChMKCQYAAgwEsMq8IhIGvQEEwAEGCokBCgQGAAINEgbFAQLK
AQMaeSBHZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgZm9yIGEgc2VjcmV0LgogUmV0
dXJucyBlbXB0eSBwb2xpY3kgaWYgdGhlIHNlY3JldCBleGlzdHMgYW5kIGRvZXMgbm90IGhh
dmUgYSBwb2xpY3kgc2V0LgoKDQoFBgACDQESBMUBBhIKDQoFBgACDQISBMUBEzQKDQoFBgAC
DQMSBMYBDyMKDwoFBgACDQQSBscBBMkBBgoTCgkGAAINBLDKvCISBscBBMkBBgryAgoEBgAC
DhIG0wEC2QEDGuECIFJldHVybnMgcGVybWlzc2lvbnMgdGhhdCBhIGNhbGxlciBoYXMgZm9y
IHRoZSBzcGVjaWZpZWQgc2VjcmV0LgogSWYgdGhlIHNlY3JldCBkb2VzIG5vdCBleGlzdCwg
dGhpcyBjYWxsIHJldHVybnMgYW4gZW1wdHkgc2V0IG9mCiBwZXJtaXNzaW9ucywgbm90IGEg
Tk9UX0ZPVU5EIGVycm9yLgoKIE5vdGU6IFRoaXMgb3BlcmF0aW9uIGlzIGRlc2lnbmVkIHRv
IGJlIHVzZWQgZm9yIGJ1aWxkaW5nIHBlcm1pc3Npb24tYXdhcmUKIFVJcyBhbmQgY29tbWFu
ZC1saW5lIHRvb2xzLCBub3QgZm9yIGF1dGhvcml6YXRpb24gY2hlY2tpbmcuIFRoaXMgb3Bl
cmF0aW9uCiBtYXkgImZhaWwgb3BlbiIgd2l0aG91dCB3YXJuaW5nLgoKDQoFBgACDgESBNMB
BhgKDQoFBgACDgISBNMBGUAKDQoFBgACDgMSBNQBDzcKDwoFBgACDgQSBtUBBNgBBgoTCgkG
AAIOBLDKvCISBtUBBNgBBgqHAQoCBAASBt4BAPABARp5IFJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtTZWNyZXRNYW5hZ2VyU2VydmljZS5MaXN0U2VjcmV0c11bZ29vZ2xlLmNsb3VkLnNlY3Jl
dHMudjFiZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5MaXN0U2VjcmV0c10uCgoLCgMEAAES
BN4BCBoKngEKBAQAAgASBuEBAuYBBBqNASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIHByb2plY3QgYXNzb2NpYXRlZCB3aXRoIHRoZQogW1NlY3JldHNdW2dvb2dsZS5j
bG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XSwgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMv
KmAuCgoNCgUEAAIABRIE4QECCAoNCgUEAAIAARIE4QEJDwoNCgUEAAIAAxIE4QESEwoPCgUE
AAIACBIG4QEU5gEDChAKCAQAAgAInAgAEgTiAQQqChEKBwQAAgAInwgSBuMBBOUBBQrYAQoE
BAACARIE6wECPxrJASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMg
dG8gYmUgcmV0dXJuZWQgaW4gYSBzaW5nbGUgcGFnZS4gSWYKIHNldCB0byAwLCB0aGUgc2Vy
dmVyIGRlY2lkZXMgdGhlIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYgdGhlCiBu
dW1iZXIgaXMgZ3JlYXRlciB0aGFuIDI1MDAwLCBpdCBpcyBjYXBwZWQgYXQgMjUwMDAuCgoN
CgUEAAIBBRIE6wECBwoNCgUEAAIBARIE6wEIEQoNCgUEAAIBAxIE6wEUFQoNCgUEAAIBCBIE
6wEWPgoQCggEAAIBCJwIABIE6wEXPQqrAQoEBAACAhIE7wECQRqcASBPcHRpb25hbC4gUGFn
aW5hdGlvbiB0b2tlbiwgcmV0dXJuZWQgZWFybGllciB2aWEKIFtMaXN0U2VjcmV0c1Jlc3Bv
bnNlLm5leHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5MaXN0
U2VjcmV0c1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0uCgoNCgUEAAICBRIE7wECCAoNCgUE
AAICARIE7wEJEwoNCgUEAAICAxIE7wEWFwoNCgUEAAICCBIE7wEYQAoQCggEAAICCJwIABIE
7wEZPwqIAQoCBAESBvQBAIACARp6IFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbU2VjcmV0TWFu
YWdlclNlcnZpY2UuTGlzdFNlY3JldHNdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEu
U2VjcmV0TWFuYWdlclNlcnZpY2UuTGlzdFNlY3JldHNdLgoKCwoDBAEBEgT0AQgbCnwKBAQB
AgASBPcBAh4abiBUaGUgbGlzdCBvZiBbU2VjcmV0c11bZ29vZ2xlLmNsb3VkLnNlY3JldHMu
djFiZXRhMS5TZWNyZXRdIHNvcnRlZCBpbgogcmV2ZXJzZSBieSBjcmVhdGVfdGltZSAobmV3
ZXN0IGZpcnN0KS4KCg0KBQQBAgAEEgT3AQIKCg0KBQQBAgAGEgT3AQsRCg0KBQQBAgABEgT3
ARIZCg0KBQQBAgADEgT3ARwdCsoBCgQEAQIBEgT8AQIdGrsBIEEgdG9rZW4gdG8gcmV0cmll
dmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLiBQYXNzIHRoaXMgdmFsdWUgaW4KIFtMaXN0
U2VjcmV0c1JlcXVlc3QucGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRh
MS5MaXN0U2VjcmV0c1JlcXVlc3QucGFnZV90b2tlbl0KIHRvIHJldHJpZXZlIHRoZSBuZXh0
IHBhZ2UuCgoNCgUEAQIBBRIE/AECCAoNCgUEAQIBARIE/AEJGAoNCgUEAQIBAxIE/AEbHApT
CgQEAQICEgT/AQIXGkUgVGhlIHRvdGFsIG51bWJlciBvZiBbU2VjcmV0c11bZ29vZ2xlLmNs
b3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRdLgoKDQoFBAECAgUSBP8BAgcKDQoFBAECAgES
BP8BCBIKDQoFBAECAgMSBP8BFRYKiQEKAgQCEgaEAgCYAgEaeyBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbU2VjcmV0TWFuYWdlclNlcnZpY2UuQ3JlYXRlU2VjcmV0XVtnb29nbGUuY2xvdWQu
c2VjcmV0cy52MWJldGExLlNlY3JldE1hbmFnZXJTZXJ2aWNlLkNyZWF0ZVNlY3JldF0uCgoL
CgMEAgESBIQCCBsKnwEKBAQCAgASBocCAowCBBqOASBSZXF1aXJlZC4gVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIHByb2plY3QgdG8gYXNzb2NpYXRlIHdpdGggdGhlCiBbU2VjcmV0XVtn
b29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldF0sIGluIHRoZSBmb3JtYXQgYHBy
b2plY3RzLypgLgoKDQoFBAICAAUSBIcCAggKDQoFBAICAAESBIcCCQ8KDQoFBAICAAMSBIcC
EhMKDwoFBAICAAgSBocCFIwCAwoQCggEAgIACJwIABIEiAIEKgoRCgcEAgIACJ8IEgaJAgSL
AgUK9wEKBAQCAgESBJMCAkAa6AEgUmVxdWlyZWQuIFRoaXMgbXVzdCBiZSB1bmlxdWUgd2l0
aGluIHRoZSBwcm9qZWN0LgoKIEEgc2VjcmV0IElEIGlzIGEgc3RyaW5nIHdpdGggYSBtYXhp
bXVtIGxlbmd0aCBvZiAyNTUgY2hhcmFjdGVycyBhbmQgY2FuCiBjb250YWluIHVwcGVyY2Fz
ZSBhbmQgbG93ZXJjYXNlIGxldHRlcnMsIG51bWVyYWxzLCBhbmQgdGhlIGh5cGhlbiAoYC1g
KSBhbmQKIHVuZGVyc2NvcmUgKGBfYCkgY2hhcmFjdGVycy4KCg0KBQQCAgEFEgSTAgIICg0K
BQQCAgEBEgSTAgkSCg0KBQQCAgEDEgSTAhUWCg0KBQQCAgEIEgSTAhc/ChAKCAQCAgEInAgA
EgSTAhg+CmUKBAQCAgISBJcCAj0aVyBSZXF1aXJlZC4gQSBbU2VjcmV0XVtnb29nbGUuY2xv
dWQuc2VjcmV0cy52MWJldGExLlNlY3JldF0gd2l0aCBpbml0aWFsCiBmaWVsZCB2YWx1ZXMu
CgoNCgUEAgICBhIElwICCAoNCgUEAgICARIElwIJDwoNCgUEAgICAxIElwISEwoNCgUEAgIC
CBIElwIUPAoQCggEAgICCJwIABIElwIVOwqSAQoCBAMSBpwCAKsCARqDASBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbU2VjcmV0TWFuYWdlclNlcnZpY2UuQWRkU2VjcmV0VmVyc2lvbl1bZ29v
Z2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5BZGRTZWNy
ZXRWZXJzaW9uXS4KCgsKAwQDARIEnAIIHwreAQoEBAMCABIGoQICpgIEGs0BIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUKIFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNy
ZXRzLnYxYmV0YTEuU2VjcmV0XSB0byBhc3NvY2lhdGUgd2l0aCB0aGUKIFtTZWNyZXRWZXJz
aW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb25dIGluIHRo
ZSBmb3JtYXQKIGBwcm9qZWN0cy8qL3NlY3JldHMvKmAuCgoNCgUEAwIABRIEoQICCAoNCgUE
AwIAARIEoQIJDwoNCgUEAwIAAxIEoQISEwoPCgUEAwIACBIGoQIUpgIDChAKCAQDAgAInAgA
EgSiAgQqChEKBwQDAgAInwgSBqMCBKUCBQpxCgQEAwIBEgSqAgJFGmMgUmVxdWlyZWQuIFRo
ZSBzZWNyZXQgcGF5bG9hZCBvZiB0aGUKIFtTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQu
c2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb25dLgoKDQoFBAMCAQYSBKoCAg8KDQoFBAMC
AQESBKoCEBcKDQoFBAMCAQMSBKoCGhsKDQoFBAMCAQgSBKoCHEQKEAoIBAMCAQicCAASBKoC
HUMKgwEKAgQEEgavAgC5AgEadSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2VjcmV0TWFuYWdl
clNlcnZpY2UuR2V0U2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3Jl
dE1hbmFnZXJTZXJ2aWNlLkdldFNlY3JldF0uCgoLCgMEBAESBK8CCBgKiwEKBAQEAgASBrMC
ArgCBBp7IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUKIFtTZWNyZXRdW2dv
b2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XSwgaW4gdGhlIGZvcm1hdAogYHBy
b2plY3RzLyovc2VjcmV0cy8qYC4KCg0KBQQEAgAFEgSzAgIICg0KBQQEAgABEgSzAgkNCg0K
BQQEAgADEgSzAhARCg8KBQQEAgAIEgazAhK4AgMKEAoIBAQCAAicCAASBLQCBCoKEQoHBAQC
AAifCBIGtQIEtwIFCpYBCgIEBRIGvQIA0QIBGocBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtT
ZWNyZXRNYW5hZ2VyU2VydmljZS5MaXN0U2VjcmV0VmVyc2lvbnNdW2dvb2dsZS5jbG91ZC5z
ZWNyZXRzLnYxYmV0YTEuU2VjcmV0TWFuYWdlclNlcnZpY2UuTGlzdFNlY3JldFZlcnNpb25z
XS4KCgsKAwQFARIEvQIIIQrmAQoEBAUCABIGwgICxwIEGtUBIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUKIFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0
YTEuU2VjcmV0XSBhc3NvY2lhdGVkIHdpdGggdGhlCiBbU2VjcmV0VmVyc2lvbnNdW2dvb2ds
ZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0gdG8gbGlzdCwgaW4KIHRo
ZSBmb3JtYXQgYHByb2plY3RzLyovc2VjcmV0cy8qYC4KCg0KBQQFAgAFEgTCAgIICg0KBQQF
AgABEgTCAgkPCg0KBQQFAgADEgTCAhITCg8KBQQFAgAIEgbCAhTHAgMKEAoIBAUCAAicCAAS
BMMCBCoKEQoHBAUCAAifCBIGxAIExgIFCtgBCgQEBQIBEgTMAgI/GskBIE9wdGlvbmFsLiBU
aGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byBiZSByZXR1cm5lZCBpbiBhIHNpbmds
ZSBwYWdlLiBJZgogc2V0IHRvIDAsIHRoZSBzZXJ2ZXIgZGVjaWRlcyB0aGUgbnVtYmVyIG9m
IHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB0aGUKIG51bWJlciBpcyBncmVhdGVyIHRoYW4gMjUw
MDAsIGl0IGlzIGNhcHBlZCBhdCAyNTAwMC4KCg0KBQQFAgEFEgTMAgIHCg0KBQQFAgEBEgTM
AggRCg0KBQQFAgEDEgTMAhQVCg0KBQQFAgEIEgTMAhY+ChAKCAQFAgEInAgAEgTMAhc9CnAK
BAQFAgISBNACAkEaYiBPcHRpb25hbC4gUGFnaW5hdGlvbiB0b2tlbiwgcmV0dXJuZWQgZWFy
bGllciB2aWEKIExpc3RTZWNyZXRWZXJzaW9uc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl1b
XS4KCg0KBQQFAgIFEgTQAgIICg0KBQQFAgIBEgTQAgkTCg0KBQQFAgIDEgTQAhYXCg0KBQQF
AgIIEgTQAhhAChAKCAQFAgIInAgAEgTQAhk/CpcBCgIEBhIG1QIA4gIBGogBIFJlc3BvbnNl
IG1lc3NhZ2UgZm9yCiBbU2VjcmV0TWFuYWdlclNlcnZpY2UuTGlzdFNlY3JldFZlcnNpb25z
XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldE1hbmFnZXJTZXJ2aWNlLkxp
c3RTZWNyZXRWZXJzaW9uc10uCgoLCgMEBgESBNUCCCIKigEKBAQGAgASBNgCAiYafCBUaGUg
bGlzdCBvZiBbU2VjcmV0VmVyc2lvbnNdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEu
U2VjcmV0VmVyc2lvbl0KIHNvcnRlZCBpbiByZXZlcnNlIGJ5IGNyZWF0ZV90aW1lIChuZXdl
c3QgZmlyc3QpLgoKDQoFBAYCAAQSBNgCAgoKDQoFBAYCAAYSBNgCCxgKDQoFBAYCAAESBNgC
GSEKDQoFBAYCAAMSBNgCJCUK2AEKBAQGAgESBN0CAh0ayQEgQSB0b2tlbiB0byByZXRyaWV2
ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuIFBhc3MgdGhpcyB2YWx1ZSBpbgogW0xpc3RT
ZWNyZXRWZXJzaW9uc1JlcXVlc3QucGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMu
djFiZXRhMS5MaXN0U2VjcmV0VmVyc2lvbnNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRy
aWV2ZSB0aGUgbmV4dCBwYWdlLgoKDQoFBAYCAQUSBN0CAggKDQoFBAYCAQESBN0CCRgKDQoF
BAYCAQMSBN0CGxwKYgoEBAYCAhIE4QICFxpUIFRoZSB0b3RhbCBudW1iZXIgb2YKIFtTZWNy
ZXRWZXJzaW9uc11bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRWZXJzaW9u
XS4KCg0KBQQGAgIFEgThAgIHCg0KBQQGAgIBEgThAggSCg0KBQQGAgIDEgThAhUWCpIBCgIE
BxIG5gIA8gIBGoMBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNyZXRNYW5hZ2VyU2Vydmlj
ZS5HZXRTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3Jl
dE1hbmFnZXJTZXJ2aWNlLkdldFNlY3JldFZlcnNpb25dLgoKCwoDBAcBEgTmAggfCqYCCgQE
BwIAEgbsAgLxAgQalQIgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZQogW1Nl
Y3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lv
bl0gaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovc2VjcmV0cy8qL3ZlcnNpb25zLypgLgog
YHByb2plY3RzLyovc2VjcmV0cy8qL3ZlcnNpb25zL2xhdGVzdGAgaXMgYW4gYWxpYXMgdG8g
dGhlIGBsYXRlc3RgCiBbU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFi
ZXRhMS5TZWNyZXRWZXJzaW9uXS4KCg0KBQQHAgAFEgTsAgIICg0KBQQHAgABEgTsAgkNCg0K
BQQHAgADEgTsAhARCg8KBQQHAgAIEgbsAhLxAgMKEAoIBAcCAAicCAASBO0CBCoKEQoHBAcC
AAifCBIG7gIE8AIFCokBCgIECBIG9gIA/gIBGnsgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1Nl
Y3JldE1hbmFnZXJTZXJ2aWNlLlVwZGF0ZVNlY3JldF1bZ29vZ2xlLmNsb3VkLnNlY3JldHMu
djFiZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5VcGRhdGVTZWNyZXRdLgoKCwoDBAgBEgT2
AggbCmMKBAQIAgASBPkCAj0aVSBSZXF1aXJlZC4gW1NlY3JldF1bZ29vZ2xlLmNsb3VkLnNl
Y3JldHMudjFiZXRhMS5TZWNyZXRdIHdpdGggdXBkYXRlZCBmaWVsZAogdmFsdWVzLgoKDQoF
BAgCAAYSBPkCAggKDQoFBAgCAAESBPkCCQ8KDQoFBAgCAAMSBPkCEhMKDQoFBAgCAAgSBPkC
FDwKEAoIBAgCAAicCAASBPkCFTsKPwoEBAgCARIG/AIC/QIvGi8gUmVxdWlyZWQuIFNwZWNp
ZmllcyB0aGUgZmllbGRzIHRvIGJlIHVwZGF0ZWQuCgoNCgUECAIBBhIE/AICGwoNCgUECAIB
ARIE/AIcJwoNCgUECAIBAxIE/AIqKwoNCgUECAIBCBIE/QIGLgoQCggECAIBCJwIABIE/QIH
LQqYAQoCBAkSBoIDAIwDARqJASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2VjcmV0TWFuYWdl
clNlcnZpY2UuQWNjZXNzU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFi
ZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5BY2Nlc3NTZWNyZXRWZXJzaW9uXS4KCgsKAwQJ
ARIEggMIIgqkAQoEBAkCABIGhgMCiwMEGpMBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUKIFtTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGEx
LlNlY3JldFZlcnNpb25dIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL3NlY3JldHMvKi92
ZXJzaW9ucy8qYC4KCg0KBQQJAgAFEgSGAwIICg0KBQQJAgABEgSGAwkNCg0KBQQJAgADEgSG
AxARCg8KBQQJAgAIEgaGAxKLAwMKEAoIBAkCAAicCAASBIcDBCoKEQoHBAkCAAifCBIGiAME
igMFCpkBCgIEChIGkAMAmgMBGooBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbU2VjcmV0TWFu
YWdlclNlcnZpY2UuQWNjZXNzU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMu
djFiZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5BY2Nlc3NTZWNyZXRWZXJzaW9uXS4KCgsK
AwQKARIEkAMIIwqaAQoEBAoCABIGlAMClgMFGokBIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZQogW1NlY3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0
VmVyc2lvbl0gaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovc2VjcmV0cy8qL3ZlcnNpb25z
LypgLgoKDQoFBAoCAAUSBJQDAggKDQoFBAoCAAESBJQDCQ0KDQoFBAoCAAMSBJQDEBEKDwoF
BAoCAAgSBpQDEpYDBAoRCgcECgIACJ8IEgaUAxOWAwMKHgoEBAoCARIEmQMCHBoQIFNlY3Jl
dCBwYXlsb2FkCgoNCgUECgIBBhIEmQMCDwoNCgUECgIBARIEmQMQFwoNCgUECgIBAxIEmQMa
GwqJAQoCBAsSBp4DAKgDARp7IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNyZXRNYW5hZ2Vy
U2VydmljZS5EZWxldGVTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2Vj
cmV0TWFuYWdlclNlcnZpY2UuRGVsZXRlU2VjcmV0XS4KCgsKAwQLARIEngMIGwqVAQoEBAsC
ABIGogMCpwMEGoQBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUKIFtTZWNy
ZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XSB0byBkZWxldGUgaW4g
dGhlIGZvcm1hdAogYHByb2plY3RzLyovc2VjcmV0cy8qYC4KCg0KBQQLAgAFEgSiAwIICg0K
BQQLAgABEgSiAwkNCg0KBQQLAgADEgSiAxARCg8KBQQLAgAIEgaiAxKnAwMKEAoIBAsCAAic
CAASBKMDBCoKEQoHBAsCAAifCBIGpAMEpgMFCpoBCgIEDBIGrAMAtgMBGosBIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtTZWNyZXRNYW5hZ2VyU2VydmljZS5EaXNhYmxlU2VjcmV0VmVyc2lv
bl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5E
aXNhYmxlU2VjcmV0VmVyc2lvbl0uCgoLCgMEDAESBKwDCCMKrwEKBAQMAgASBrADArUDBBqe
ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlCiBbU2VjcmV0VmVyc2lvbl1b
Z29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRWZXJzaW9uXSB0byBkaXNhYmxl
IGluCiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL3NlY3JldHMvKi92ZXJzaW9ucy8qYC4KCg0K
BQQMAgAFEgSwAwIICg0KBQQMAgABEgSwAwkNCg0KBQQMAgADEgSwAxARCg8KBQQMAgAIEgaw
AxK1AwMKEAoIBAwCAAicCAASBLEDBCoKEQoHBAwCAAifCBIGsgMEtAMFCpgBCgIEDRIGugMA
xAMBGokBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNyZXRNYW5hZ2VyU2VydmljZS5FbmFi
bGVTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldE1h
bmFnZXJTZXJ2aWNlLkVuYWJsZVNlY3JldFZlcnNpb25dLgoKCwoDBA0BEgS6AwgiCq4BCgQE
DQIAEga+AwLDAwQanQEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZQogW1Nl
Y3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lv
bl0gdG8gZW5hYmxlIGluCiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL3NlY3JldHMvKi92ZXJz
aW9ucy8qYC4KCg0KBQQNAgAFEgS+AwIICg0KBQQNAgABEgS+AwkNCg0KBQQNAgADEgS+AxAR
Cg8KBQQNAgAIEga+AxLDAwMKEAoIBA0CAAicCAASBL8DBCoKEQoHBA0CAAifCBIGwAMEwgMF
CpoBCgIEDhIGyAMA0gMBGosBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNyZXRNYW5hZ2Vy
U2VydmljZS5EZXN0cm95U2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFi
ZXRhMS5TZWNyZXRNYW5hZ2VyU2VydmljZS5EZXN0cm95U2VjcmV0VmVyc2lvbl0uCgoLCgME
DgESBMgDCCMKrwEKBAQOAgASBswDAtEDBBqeASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlCiBbU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRh
MS5TZWNyZXRWZXJzaW9uXSB0byBkZXN0cm95IGluCiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8q
L3NlY3JldHMvKi92ZXJzaW9ucy8qYC4KCg0KBQQOAgAFEgTMAwIICg0KBQQOAgABEgTMAwkN
Cg0KBQQOAgADEgTMAxARCg8KBQQOAgAIEgbMAxLRAwMKEAoIBA4CAAicCAASBM0DBCoKEQoH
BA4CAAifCBIGzgME0AMFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Secrets::V1beta1::Service::ListSecretsRequest ===
    # Fields for ListSecretsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::ListSecretsResponse ===
    # Fields for ListSecretsResponse
    # Field: secrets Type: 11 (.google.cloud.secrets.v1beta1.Secret)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::CreateSecretRequest ===
    # Fields for CreateSecretRequest
    # Field: parent Type: 9 ()
    # Field: secret_id Type: 9 ()
    # Field: secret Type: 11 (.google.cloud.secrets.v1beta1.Secret)

# === Message: Google::Cloud::Secrets::V1beta1::Service::AddSecretVersionRequest ===
    # Fields for AddSecretVersionRequest
    # Field: parent Type: 9 ()
    # Field: payload Type: 11 (.google.cloud.secrets.v1beta1.SecretPayload)

# === Message: Google::Cloud::Secrets::V1beta1::Service::GetSecretRequest ===
    # Fields for GetSecretRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::ListSecretVersionsRequest ===
    # Fields for ListSecretVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::ListSecretVersionsResponse ===
    # Fields for ListSecretVersionsResponse
    # Field: versions Type: 11 (.google.cloud.secrets.v1beta1.SecretVersion)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::GetSecretVersionRequest ===
    # Fields for GetSecretVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::UpdateSecretRequest ===
    # Fields for UpdateSecretRequest
    # Field: secret Type: 11 (.google.cloud.secrets.v1beta1.Secret)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Secrets::V1beta1::Service::AccessSecretVersionRequest ===
    # Fields for AccessSecretVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::AccessSecretVersionResponse ===
    # Fields for AccessSecretVersionResponse
    # Field: name Type: 9 ()
    # Field: payload Type: 11 (.google.cloud.secrets.v1beta1.SecretPayload)

# === Message: Google::Cloud::Secrets::V1beta1::Service::DeleteSecretRequest ===
    # Fields for DeleteSecretRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::DisableSecretVersionRequest ===
    # Fields for DisableSecretVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::EnableSecretVersionRequest ===
    # Fields for EnableSecretVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secrets::V1beta1::Service::DestroySecretVersionRequest ===
    # Fields for DestroySecretVersionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Secrets::V1beta1::Service::SecretManagerServiceClient ===
package Google::Cloud::Secrets::V1beta1::Service::SecretManagerServiceClient;

=pod

=head2 Service Client: Google::Cloud::Secrets::V1beta1::Service::SecretManagerServiceClient

Client stub representing the remote C<SecretManagerService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<secrets.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'secrets.googleapis.com:443' );

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

sub list_secrets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::ListSecretsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'ListSecrets',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Service::ListSecretsResponse',
    });
}

sub create_secret {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::CreateSecretRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'CreateSecret',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::Secret',
    });
}

sub add_secret_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::AddSecretVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'AddSecretVersion',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion',
    });
}

sub get_secret {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::GetSecretRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'GetSecret',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::Secret',
    });
}

sub update_secret {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::UpdateSecretRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'UpdateSecret',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::Secret',
    });
}

sub delete_secret {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::DeleteSecretRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'DeleteSecret',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_secret_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::ListSecretVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'ListSecretVersions',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Service::ListSecretVersionsResponse',
    });
}

sub get_secret_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::GetSecretVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'GetSecretVersion',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion',
    });
}

sub access_secret_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::AccessSecretVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'AccessSecretVersion',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Service::AccessSecretVersionResponse',
    });
}

sub disable_secret_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::DisableSecretVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'DisableSecretVersion',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion',
    });
}

sub enable_secret_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::EnableSecretVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'EnableSecretVersion',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion',
    });
}

sub destroy_secret_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secrets::V1beta1::Service::DestroySecretVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'DestroySecretVersion',
        request        => $req,
        response_class => 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secrets.v1beta1.SecretManagerService',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Secrets::V1beta1::Service - Compiled Protocol Buffers messages for google/cloud/secrets/v1beta1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Secrets::V1beta1::Service;

    my $msg = Google::Cloud::Secrets::V1beta1::Service::ListSecretsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Secrets::V1beta1::Service::ListSecretsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/secrets/v1beta1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Secrets::V1beta1::Service::ListSecretsRequest

Request message for
[SecretManagerService.ListSecrets][google.cloud.secrets.v1beta1.SecretManagerService.ListSecrets].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the project associated with the
[Secrets][google.cloud.secrets.v1beta1.Secret], in the format `projects/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to be returned in a single page. If
set to 0, the server decides the number of results to return. If the
number is greater than 25000, it is capped at 25000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Pagination token, returned earlier via
[ListSecretsResponse.next_page_token][google.cloud.secrets.v1beta1.ListSecretsResponse.next_page_token].

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::ListSecretsResponse

Response message for
[SecretManagerService.ListSecrets][google.cloud.secrets.v1beta1.SecretManagerService.ListSecrets].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->secrets() >> / C<< $msg->secrets($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Secret>)

The list of [Secrets][google.cloud.secrets.v1beta1.Secret] sorted in
reverse by create_time (newest first).

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Pass this value in
[ListSecretsRequest.page_token][google.cloud.secrets.v1beta1.ListSecretsRequest.page_token]
to retrieve the next page.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of [Secrets][google.cloud.secrets.v1beta1.Secret].

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::CreateSecretRequest

Request message for
[SecretManagerService.CreateSecret][google.cloud.secrets.v1beta1.SecretManagerService.CreateSecret].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the project to associate with the
[Secret][google.cloud.secrets.v1beta1.Secret], in the format `projects/*`.

=item * C<< $msg->secret_id() >> / C<< $msg->secret_id($value) >>

Type: C<String>

Required. This must be unique within the project.

A secret ID is a string with a maximum length of 255 characters and can
contain uppercase and lowercase letters, numerals, and the hyphen (`-`) and
underscore (`_`) characters.

=item * C<< $msg->secret() >> / C<< $msg->secret($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Secret>)

Required. A [Secret][google.cloud.secrets.v1beta1.Secret] with initial
field values.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::AddSecretVersionRequest

Request message for
[SecretManagerService.AddSecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.AddSecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the
[Secret][google.cloud.secrets.v1beta1.Secret] to associate with the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] in the format
`projects/*/secrets/*`.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::SecretPayload>)

Required. The secret payload of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion].

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::GetSecretRequest

Request message for
[SecretManagerService.GetSecret][google.cloud.secrets.v1beta1.SecretManagerService.GetSecret].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Secret][google.cloud.secrets.v1beta1.Secret], in the format
`projects/*/secrets/*`.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::ListSecretVersionsRequest

Request message for
[SecretManagerService.ListSecretVersions][google.cloud.secrets.v1beta1.SecretManagerService.ListSecretVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the
[Secret][google.cloud.secrets.v1beta1.Secret] associated with the
[SecretVersions][google.cloud.secrets.v1beta1.SecretVersion] to list, in
the format `projects/*/secrets/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to be returned in a single page. If
set to 0, the server decides the number of results to return. If the
number is greater than 25000, it is capped at 25000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Pagination token, returned earlier via
ListSecretVersionsResponse.next_page_token][].

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::ListSecretVersionsResponse

Response message for
[SecretManagerService.ListSecretVersions][google.cloud.secrets.v1beta1.SecretManagerService.ListSecretVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::SecretVersion>)

The list of [SecretVersions][google.cloud.secrets.v1beta1.SecretVersion]
sorted in reverse by create_time (newest first).

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Pass this value in
[ListSecretVersionsRequest.page_token][google.cloud.secrets.v1beta1.ListSecretVersionsRequest.page_token]
to retrieve the next page.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of
[SecretVersions][google.cloud.secrets.v1beta1.SecretVersion].

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::GetSecretVersionRequest

Request message for
[SecretManagerService.GetSecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.GetSecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] in the format
`projects/*/secrets/*/versions/*`.
`projects/*/secrets/*/versions/latest` is an alias to the `latest`
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion].

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::UpdateSecretRequest

Request message for
[SecretManagerService.UpdateSecret][google.cloud.secrets.v1beta1.SecretManagerService.UpdateSecret].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->secret() >> / C<< $msg->secret($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Secret>)

Required. [Secret][google.cloud.secrets.v1beta1.Secret] with updated field
values.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Specifies the fields to be updated.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::AccessSecretVersionRequest

Request message for
[SecretManagerService.AccessSecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.AccessSecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] in the format
`projects/*/secrets/*/versions/*`.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::AccessSecretVersionResponse

Response message for
[SecretManagerService.AccessSecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.AccessSecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] in the format
`projects/*/secrets/*/versions/*`.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::SecretPayload>)

Secret payload

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::DeleteSecretRequest

Request message for
[SecretManagerService.DeleteSecret][google.cloud.secrets.v1beta1.SecretManagerService.DeleteSecret].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Secret][google.cloud.secrets.v1beta1.Secret] to delete in the format
`projects/*/secrets/*`.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::DisableSecretVersionRequest

Request message for
[SecretManagerService.DisableSecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.DisableSecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] to disable in
the format `projects/*/secrets/*/versions/*`.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::EnableSecretVersionRequest

Request message for
[SecretManagerService.EnableSecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.EnableSecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] to enable in
the format `projects/*/secrets/*/versions/*`.

=back

=head2 Google::Cloud::Secrets::V1beta1::Service::DestroySecretVersionRequest

Request message for
[SecretManagerService.DestroySecretVersion][google.cloud.secrets.v1beta1.SecretManagerService.DestroySecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] to destroy in
the format `projects/*/secrets/*/versions/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Secrets::V1beta1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
