package Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvYmlncXVlcnkvZGF0YXBvbGljaWVzL3YyL2RhdGFwb2xpY3kucHJv
dG8SJWdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjIaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29n
bGUvaWFtL3YxL2lhbV9wb2xpY3kucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnByb3Rv
Ghtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9t
YXNrLnByb3RvIusBChdDcmVhdGVEYXRhUG9saWN5UmVxdWVzdBJMCgZwYXJlbnQYASABKAlC
NOBBAvpBLhIsYmlncXVlcnlkYXRhcG9saWN5Lmdvb2dsZWFwaXMuY29tL0RhdGFQb2xpY3lS
BnBhcmVudBIpCg5kYXRhX3BvbGljeV9pZBgCIAEoCUID4EECUgxkYXRhUG9saWN5SWQSVwoL
ZGF0YV9wb2xpY3kYAyABKAsyMS5nb29nbGUuY2xvdWQuYmlncXVlcnkuZGF0YXBvbGljaWVz
LnYyLkRhdGFQb2xpY3lCA+BBAlIKZGF0YVBvbGljeSLeAQoXVXBkYXRlRGF0YVBvbGljeVJl
cXVlc3QSVwoLZGF0YV9wb2xpY3kYASABKAsyMS5nb29nbGUuY2xvdWQuYmlncXVlcnkuZGF0
YXBvbGljaWVzLnYyLkRhdGFQb2xpY3lCA+BBAlIKZGF0YVBvbGljeRJACgt1cGRhdGVfbWFz
axgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxIo
Cg1hbGxvd19taXNzaW5nGAMgASgIQgPgQQFSDGFsbG93TWlzc2luZyKMAQoSQWRkR3JhbnRl
ZXNSZXF1ZXN0ElUKC2RhdGFfcG9saWN5GAEgASgJQjTgQQL6QS4KLGJpZ3F1ZXJ5ZGF0YXBv
bGljeS5nb29nbGVhcGlzLmNvbS9EYXRhUG9saWN5UgpkYXRhUG9saWN5Eh8KCGdyYW50ZWVz
GAIgAygJQgPgQQJSCGdyYW50ZWVzIo8BChVSZW1vdmVHcmFudGVlc1JlcXVlc3QSVQoLZGF0
YV9wb2xpY3kYASABKAlCNOBBAvpBLgosYmlncXVlcnlkYXRhcG9saWN5Lmdvb2dsZWFwaXMu
Y29tL0RhdGFQb2xpY3lSCmRhdGFQb2xpY3kSHwoIZ3JhbnRlZXMYAiADKAlCA+BBAlIIZ3Jh
bnRlZXMiYwoXRGVsZXRlRGF0YVBvbGljeVJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEu
CixiaWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20vRGF0YVBvbGljeVIEbmFtZSJg
ChRHZXREYXRhUG9saWN5UmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGJpZ3F1ZXJ5
ZGF0YXBvbGljeS5nb29nbGVhcGlzLmNvbS9EYXRhUG9saWN5UgRuYW1lIsoBChdMaXN0RGF0
YVBvbGljaWVzUmVxdWVzdBJMCgZwYXJlbnQYASABKAlCNOBBAvpBLhIsYmlncXVlcnlkYXRh
cG9saWN5Lmdvb2dsZWFwaXMuY29tL0RhdGFQb2xpY3lSBnBhcmVudBIgCglwYWdlX3NpemUY
AiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9r
ZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlciKaAQoYTGlzdERhdGFQb2xpY2llc1Jl
c3BvbnNlElYKDWRhdGFfcG9saWNpZXMYASADKAsyMS5nb29nbGUuY2xvdWQuYmlncXVlcnku
ZGF0YXBvbGljaWVzLnYyLkRhdGFQb2xpY3lSDGRhdGFQb2xpY2llcxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i+QYKCkRhdGFQb2xpY3kSbwoTZGF0YV9tYXNr
aW5nX3BvbGljeRgHIAEoCzI4Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMu
djIuRGF0YU1hc2tpbmdQb2xpY3lCA+BBAUgAUhFkYXRhTWFza2luZ1BvbGljeRIXCgRuYW1l
GAEgASgJQgPgQQhSBG5hbWUSKQoOZGF0YV9wb2xpY3lfaWQYAiABKAlCA+BBA1IMZGF0YVBv
bGljeUlkEhcKBGV0YWcYCyABKAlIAVIEZXRhZ4gBARJvChBkYXRhX3BvbGljeV90eXBlGAMg
ASgOMkAuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52Mi5EYXRhUG9saWN5
LkRhdGFQb2xpY3lUeXBlQgPgQQJSDmRhdGFQb2xpY3lUeXBlEksKCnBvbGljeV90YWcYBCAB
KAlCLOBBA/pBJgokZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vUG9saWN5VGFnUglwb2xp
Y3lUYWcSHwoIZ3JhbnRlZXMYCCADKAlCA+BBAVIIZ3JhbnRlZXMSWAoHdmVyc2lvbhgJIAEo
DjI5Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjIuRGF0YVBvbGljeS5W
ZXJzaW9uQgPgQQNSB3ZlcnNpb24iiQEKDkRhdGFQb2xpY3lUeXBlEiAKHERBVEFfUE9MSUNZ
X1RZUEVfVU5TUEVDSUZJRUQQABIXChNEQVRBX01BU0tJTkdfUE9MSUNZEAESGgoWUkFXX0RB
VEFfQUNDRVNTX1BPTElDWRACEiAKHENPTFVNTl9MRVZFTF9TRUNVUklUWV9QT0xJQ1kQAyIy
CgdWZXJzaW9uEhcKE1ZFUlNJT05fVU5TUEVDSUZJRUQQABIGCgJWMRABEgYKAlYyEAI6kAHq
QYwBCixiaWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20vRGF0YVBvbGljeRJCcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFQb2xpY2llcy97ZGF0
YV9wb2xpY3l9KgxkYXRhUG9saWNpZXMyCmRhdGFQb2xpY3lCCAoGcG9saWN5QgcKBV9ldGFn
ItwDChFEYXRhTWFza2luZ1BvbGljeRKJAQoVcHJlZGVmaW5lZF9leHByZXNzaW9uGAEgASgO
Mk0uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52Mi5EYXRhTWFza2luZ1Bv
bGljeS5QcmVkZWZpbmVkRXhwcmVzc2lvbkID4EEBSABSFHByZWRlZmluZWRFeHByZXNzaW9u
EkMKB3JvdXRpbmUYAiABKAlCJ+BBAfpBIQofYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vUm91
dGluZUgAUgdyb3V0aW5lIt8BChRQcmVkZWZpbmVkRXhwcmVzc2lvbhIlCiFQUkVERUZJTkVE
X0VYUFJFU1NJT05fVU5TUEVDSUZJRUQQABIKCgZTSEEyNTYQARIPCgtBTFdBWVNfTlVMTBAC
EhkKFURFRkFVTFRfTUFTS0lOR19WQUxVRRADEhgKFExBU1RfRk9VUl9DSEFSQUNURVJTEAQS
GQoVRklSU1RfRk9VUl9DSEFSQUNURVJTEAUSDgoKRU1BSUxfTUFTSxAGEhIKDkRBVEVfWUVB
Ul9NQVNLEAcSDwoLUkFORE9NX0hBU0gQCEIUChJtYXNraW5nX2V4cHJlc3Npb24yghEKEURh
dGFQb2xpY3lTZXJ2aWNlEuYBChBDcmVhdGVEYXRhUG9saWN5Ej4uZ29vZ2xlLmNsb3VkLmJp
Z3F1ZXJ5LmRhdGFwb2xpY2llcy52Mi5DcmVhdGVEYXRhUG9saWN5UmVxdWVzdBoxLmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjIuRGF0YVBvbGljeSJfgtPkkwI1IjAv
djIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kYXRhUG9saWNpZXM6ASraQSFw
YXJlbnQsZGF0YV9wb2xpY3ksZGF0YV9wb2xpY3lfaWQS4gEKC0FkZEdyYW50ZWVzEjkuZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52Mi5BZGRHcmFudGVlc1JlcXVlc3Qa
MS5nb29nbGUuY2xvdWQuYmlncXVlcnkuZGF0YXBvbGljaWVzLnYyLkRhdGFQb2xpY3kiZYLT
5JMCSCJDL3YyL3tkYXRhX3BvbGljeT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xp
Y2llcy8qfTphZGRHcmFudGVlczoBKtpBFGRhdGFfcG9saWN5LGdyYW50ZWVzEusBCg5SZW1v
dmVHcmFudGVlcxI8Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjIuUmVt
b3ZlR3JhbnRlZXNSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2ll
cy52Mi5EYXRhUG9saWN5ImiC0+STAksiRi92Mi97ZGF0YV9wb2xpY3k9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9kYXRhUG9saWNpZXMvKn06cmVtb3ZlR3JhbnRlZXM6ASraQRRkYXRhX3Bv
bGljeSxncmFudGVlcxLyAQoQVXBkYXRlRGF0YVBvbGljeRI+Lmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5kYXRhcG9saWNpZXMudjIuVXBkYXRlRGF0YVBvbGljeVJlcXVlc3QaMS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkuZGF0YXBvbGljaWVzLnYyLkRhdGFQb2xpY3kia4LT5JMCSzI8L3Yy
L3tkYXRhX3BvbGljeS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVz
Lyp9OgtkYXRhX3BvbGljedpBF2RhdGFfcG9saWN5LHVwZGF0ZV9tYXNrEqsBChBEZWxldGVE
YXRhUG9saWN5Ej4uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52Mi5EZWxl
dGVEYXRhUG9saWN5UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI/gtPkkwIyKjAv
djIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhUG9saWNpZXMvKn3aQQRuYW1l
EsABCg1HZXREYXRhUG9saWN5EjsuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2ll
cy52Mi5HZXREYXRhUG9saWN5UmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRh
cG9saWNpZXMudjIuRGF0YVBvbGljeSI/gtPkkwIyEjAvdjIve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9kYXRhUG9saWNpZXMvKn3aQQRuYW1lEtYBChBMaXN0RGF0YVBvbGljaWVz
Ej4uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52Mi5MaXN0RGF0YVBvbGlj
aWVzUmVxdWVzdBo/Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjIuTGlz
dERhdGFQb2xpY2llc1Jlc3BvbnNlIkGC0+STAjISMC92Mi97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyp9L2RhdGFQb2xpY2llc9pBBnBhcmVudBKXAQoMR2V0SWFtUG9saWN5EiIu
Z29vZ2xlLmlhbS52MS5HZXRJYW1Qb2xpY3lSZXF1ZXN0GhUuZ29vZ2xlLmlhbS52MS5Qb2xp
Y3kiTILT5JMCRiJBL3YyL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQ
b2xpY2llcy8qfTpnZXRJYW1Qb2xpY3k6ASoSlwEKDFNldElhbVBvbGljeRIiLmdvb2dsZS5p
YW0udjEuU2V0SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IkyC0+ST
AkYiQS92Mi97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhUG9saWNpZXMv
Kn06c2V0SWFtUG9saWN5OgEqEr0BChJUZXN0SWFtUGVybWlzc2lvbnMSKC5nb29nbGUuaWFt
LnYxLlRlc3RJYW1QZXJtaXNzaW9uc1JlcXVlc3QaKS5nb29nbGUuaWFtLnYxLlRlc3RJYW1Q
ZXJtaXNzaW9uc1Jlc3BvbnNlIlKC0+STAkwiRy92Mi97cmVzb3VyY2U9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9kYXRhUG9saWNpZXMvKn06dGVzdElhbVBlcm1pc3Npb25zOgEqGn7KQSFi
aWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb23SQVdodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2JpZ3F1ZXJ5LGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm1C5wMKKWNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkuZGF0YXBvbGlj
aWVzLnYyQg9EYXRhUG9saWN5UHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVy
eS9kYXRhcG9saWNpZXMvYXBpdjIvZGF0YXBvbGljaWVzcGI7ZGF0YXBvbGljaWVzcGKqAiVH
b29nbGUuQ2xvdWQuQmlnUXVlcnkuRGF0YVBvbGljaWVzLlYyygIlR29vZ2xlXENsb3VkXEJp
Z1F1ZXJ5XERhdGFQb2xpY2llc1xWMuoCKUdvb2dsZTo6Q2xvdWQ6OkJpZ3F1ZXJ5OjpEYXRh
UG9saWNpZXM6OlYy6kF9CiRkYXRhY2F0YWxvZy5nb29nbGVhcGlzLmNvbS9Qb2xpY3lUYWcS
VXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90YXhvbm9taWVzL3t0
YXhvbm9teX0vcG9saWN5VGFncy97cG9saWN5X3RhZ33qQVsKH2JpZ3F1ZXJ5Lmdvb2dsZWFw
aXMuY29tL1JvdXRpbmUSOHByb2plY3RzL3twcm9qZWN0fS9kYXRhc2V0cy97ZGF0YXNldH0v
cm91dGluZXMve3JvdXRpbmV9Stl9CgcSBQ4A7wMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAuCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYAKAoJCgIDBRIDFwAkCgkKAgMGEgMYACUKCQoCAwcSAxkA
KgoICgEIEgMbAEIKCQoCCCUSAxsAQgoICgEIEgMcAGQKCQoCCAsSAxwAZAoICgEIEgMdACIK
CQoCCAoSAx0AIgoICgEIEgMeADAKCQoCCAgSAx4AMAoICgEIEgMfAEIKCQoCCAESAx8AQgoI
CgEIEgMgAEMKCQoCCCkSAyAAQwoICgEIEgMhAEIKCQoCCC0SAyEAQgoJCgEIEgQiACUCCgwK
BAidCAASBCIAJQIKCQoBCBIEJgApAgoMCgQInQgBEgQmACkCClcKAgYAEgUsAJMBARpKIERh
dGEgUG9saWN5IFNlcnZpY2UgcHJvdmlkZXMgQVBJcyBmb3IgbWFuYWdpbmcgdGhlIEJpZ1F1
ZXJ5IERhdGEgUG9saWN5LgoKCgoDBgABEgMsCBkKCgoDBgADEgMtAkkKDAoFBgADmQgSAy0C
SQoLCgMGAAMSBC4CMDcKDQoFBgADmggSBC4CMDcKjAEKBAYAAgASBDQCOgMafiBDcmVhdGVz
IGEgbmV3IGRhdGEgcG9saWN5IHVuZGVyIGEgcHJvamVjdCB3aXRoIHRoZSBnaXZlbiBgZGF0
YV9wb2xpY3lfaWRgCiAodXNlZCBhcyB0aGUgZGlzcGxheSBuYW1lKSwgYW5kIGRhdGEgcG9s
aWN5IHR5cGUuCgoMCgUGAAIAARIDNAYWCgwKBQYAAgACEgM0Fy4KDAoFBgACAAMSAzQ5QwoN
CgUGAAIABBIENQQ4BgoRCgkGAAIABLDKvCISBDUEOAYKDAoFBgACAAQSAzkETwoPCggGAAIA
BJsIABIDOQRPCo8CCgQGAAIBEgRBAkcDGoACIEFkZHMgbmV3IGdyYW50ZWVzIHRvIGEgZGF0
YSBwb2xpY3kuCiBUaGUgbmV3IGdyYW50ZWVzIHdpbGwgYmUgYWRkZWQgdG8gdGhlIGV4aXN0
aW5nIGdyYW50ZWVzLgogSWYgdGhlIHJlcXVlc3QgY29udGFpbnMgYSBkdXBsaWNhdGUgZ3Jh
bnRlZSwgdGhlIGdyYW50ZWUgd2lsbCBiZSBpZ25vcmVkLgogSWYgdGhlIHJlcXVlc3QgY29u
dGFpbnMgYSBncmFudGVlIHRoYXQgYWxyZWFkeSBleGlzdHMsIHRoZSBncmFudGVlIHdpbGwg
YmUKIGlnbm9yZWQuCgoMCgUGAAIBARIDQQYRCgwKBQYAAgECEgNBEiQKDAoFBgACAQMSA0Ev
OQoNCgUGAAIBBBIEQgRFBgoRCgkGAAIBBLDKvCISBEIERQYKDAoFBgACAQQSA0YEQgoPCggG
AAIBBJsIABIDRgRCCsUBCgQGAAICEgRNAlMDGrYBIFJlbW92ZXMgZ3JhbnRlZXMgZnJvbSBh
IGRhdGEgcG9saWN5LgogVGhlIGdyYW50ZWVzIHdpbGwgYmUgcmVtb3ZlZCBmcm9tIHRoZSBl
eGlzdGluZyBncmFudGVlcy4KIElmIHRoZSByZXF1ZXN0IGNvbnRhaW5zIGEgZ3JhbnRlZSB0
aGF0IGRvZXMgbm90IGV4aXN0LCB0aGUgZ3JhbnRlZSB3aWxsIGJlCiBpZ25vcmVkLgoKDAoF
BgACAgESA00GFAoMCgUGAAICAhIDTRUqCgwKBQYAAgIDEgNNNT8KDQoFBgACAgQSBE4EUQYK
EQoJBgACAgSwyrwiEgROBFEGCgwKBQYAAgIEEgNSBEIKDwoIBgACAgSbCAASA1IEQgqAAQoE
BgACAxIEVwJdAxpyIFVwZGF0ZXMgdGhlIG1ldGFkYXRhIGZvciBhbiBleGlzdGluZyBkYXRh
IHBvbGljeS4gVGhlIHRhcmdldCBkYXRhIHBvbGljeQogY2FuIGJlIHNwZWNpZmllZCBieSB0
aGUgcmVzb3VyY2UgbmFtZS4KCgwKBQYAAgMBEgNXBhYKDAoFBgACAwISA1cXLgoMCgUGAAID
AxIDVzlDCg0KBQYAAgMEEgRYBFsGChEKCQYAAgMEsMq8IhIEWARbBgoMCgUGAAIDBBIDXARF
Cg8KCAYAAgMEmwgAEgNcBEUKRwoEBgACBBIEYAJmAxo5IERlbGV0ZXMgdGhlIGRhdGEgcG9s
aWN5IHNwZWNpZmllZCBieSBpdHMgcmVzb3VyY2UgbmFtZS4KCgwKBQYAAgQBEgNgBhYKDAoF
BgACBAISA2AXLgoMCgUGAAIEAxIDYQ8kCg0KBQYAAgQEEgRiBGQGChEKCQYAAgQEsMq8IhIE
YgRkBgoMCgUGAAIEBBIDZQQyCg8KCAYAAgQEmwgAEgNlBDIKRAoEBgACBRIEaQJuAxo2IEdl
dHMgdGhlIGRhdGEgcG9saWN5IHNwZWNpZmllZCBieSBpdHMgcmVzb3VyY2UgbmFtZS4KCgwK
BQYAAgUBEgNpBhMKDAoFBgACBQISA2kUKAoMCgUGAAIFAxIDaTM9Cg0KBQYAAgUEEgRqBGwG
ChEKCQYAAgUEsMq8IhIEagRsBgoMCgUGAAIFBBIDbQQyCg8KCAYAAgUEmwgAEgNtBDIKTgoE
BgACBhIEcQJ3AxpAIExpc3QgYWxsIG9mIHRoZSBkYXRhIHBvbGljaWVzIGluIHRoZSBzcGVj
aWZpZWQgcGFyZW50IHByb2plY3QuCgoMCgUGAAIGARIDcQYWCgwKBQYAAgYCEgNxFy4KDAoF
BgACBgMSA3IPJwoNCgUGAAIGBBIEcwR1BgoRCgkGAAIGBLDKvCISBHMEdQYKDAoFBgACBgQS
A3YENAoPCggGAAIGBJsIABIDdgQ0CkMKBAYAAgcSBXoCgAEDGjQgR2V0cyB0aGUgSUFNIHBv
bGljeSBmb3IgdGhlIHNwZWNpZmllZCBkYXRhIHBvbGljeS4KCgwKBQYAAgcBEgN6BhIKDAoF
BgACBwISA3oTNAoMCgUGAAIHAxIDew8jCg0KBQYAAgcEEgR8BH8GChEKCQYAAgcEsMq8IhIE
fAR/BgpECgQGAAIIEgaDAQKJAQMaNCBTZXRzIHRoZSBJQU0gcG9saWN5IGZvciB0aGUgc3Bl
Y2lmaWVkIGRhdGEgcG9saWN5LgoKDQoFBgACCAESBIMBBhIKDQoFBgACCAISBIMBEzQKDQoF
BgACCAMSBIQBDyMKDwoFBgACCAQSBoUBBIgBBgoTCgkGAAIIBLDKvCISBoUBBIgBBgpYCgQG
AAIJEgaMAQKSAQMaSCBSZXR1cm5zIHRoZSBjYWxsZXIncyBwZXJtaXNzaW9uIG9uIHRoZSBz
cGVjaWZpZWQgZGF0YSBwb2xpY3kgcmVzb3VyY2UuCgoNCgUGAAIJARIEjAEGGAoNCgUGAAIJ
AhIEjAEZQAoNCgUGAAIJAxIEjQEPNwoPCgUGAAIJBBIGjgEEkQEGChMKCQYAAgkEsMq8IhIG
jgEEkQEGCkAKAgQAEgaWAQCoAQEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBDcmVhdGVE
YXRhUG9saWN5IG1ldGhvZC4KCgsKAwQAARIElgEIHwqiAQoEBAACABIGmQECngEEGpEBIFJl
cXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9qZWN0IHRoYXQgdGhlIGRhdGEgcG9s
aWN5IHdpbGwgYmVsb25nIHRvLgogVGhlIGZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3Rf
bnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfWAuCgoNCgUEAAIABRIEmQECCAoNCgUE
AAIAARIEmQEJDwoNCgUEAAIAAxIEmQESEwoPCgUEAAIACBIGmQEUngEDChAKCAQAAgAInAgA
EgSaAQQqChEKBwQAAgAInwgSBpsBBJ0BBQqyAQoEBAACARIEowECRRqjASBSZXF1aXJlZC4g
VXNlci1hc3NpZ25lZCAoaHVtYW4gcmVhZGFibGUpIElEIG9mIHRoZSBkYXRhIHBvbGljeSB0
aGF0IG5lZWRzCiB0byBiZSB1bmlxdWUgd2l0aGluIGEgcHJvamVjdC4gVXNlZCBhcyB7ZGF0
YV9wb2xpY3lfaWR9IGluIHBhcnQgb2YgdGhlCiByZXNvdXJjZSBuYW1lLgoKDQoFBAACAQUS
BKMBAggKDQoFBAACAQESBKMBCRcKDQoFBAACAQMSBKMBGhsKDQoFBAACAQgSBKMBHEQKEAoI
BAACAQicCAASBKMBHUMKgQEKBAQAAgISBKcBAkYacyBSZXF1aXJlZC4gVGhlIGRhdGEgcG9s
aWN5IHRvIGNyZWF0ZS4gVGhlIGBuYW1lYCBmaWVsZCBkb2VzIG5vdCBuZWVkIHRvIGJlCiBw
cm92aWRlZCBmb3IgdGhlIGRhdGEgcG9saWN5IGNyZWF0aW9uLgoKDQoFBAACAgYSBKcBAgwK
DQoFBAACAgESBKcBDRgKDQoFBAACAgMSBKcBGxwKDQoFBAACAggSBKcBHUUKEAoIBAACAgic
CAASBKcBHkQKQAoCBAESBqsBAL4BARoyIFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIFVwZGF0
ZURhdGFQb2xpY3kgbWV0aG9kLgoKCwoDBAEBEgSrAQgfCsUBCgQEAQIAEgSwAQJGGrYBIFJl
cXVpcmVkLiBVcGRhdGUgdGhlIGRhdGEgcG9saWN5J3MgbWV0YWRhdGEuCgogVGhlIHRhcmdl
dCBkYXRhIHBvbGljeSBpcyBkZXRlcm1pbmVkIGJ5IHRoZSBgbmFtZWAgZmllbGQuCiBPdGhl
ciBmaWVsZHMgYXJlIHVwZGF0ZWQgdG8gdGhlIHNwZWNpZmllZCB2YWx1ZXMgYmFzZWQgb24g
dGhlIGZpZWxkIG1hc2tzLgoKDQoFBAECAAYSBLABAgwKDQoFBAECAAESBLABDRgKDQoFBAEC
AAMSBLABGxwKDQoFBAECAAgSBLABHUUKEAoIBAECAAicCAASBLABHkQKzQIKBAQBAgESBrgB
ArkBLxq8AiBPcHRpb25hbC4gVGhlIHVwZGF0ZSBtYXNrIGFwcGxpZXMgdG8gdGhlIHJlc291
cmNlLiBGb3IgdGhlIGBGaWVsZE1hc2tgCiBkZWZpbml0aW9uLCBzZWUKIGh0dHBzOi8vZGV2
ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9yZWZlcmVuY2UvZ29v
Z2xlLnByb3RvYnVmI2ZpZWxkbWFzawogSWYgbm90IHNldCwgZGVmYXVsdHMgdG8gYWxsIG9m
IHRoZSBmaWVsZHMgdGhhdCBhcmUgYWxsb3dlZCB0byB1cGRhdGUuCgogVXBkYXRlcyB0byB0
aGUgYG5hbWVgIGFuZCBgZGF0YVBvbGljeUlkYCBmaWVsZHMgYXJlIG5vdCBhbGxvd2VkLgoK
DQoFBAECAQYSBLgBAhsKDQoFBAECAQESBLgBHCcKDQoFBAECAQMSBLgBKisKDQoFBAECAQgS
BLkBBi4KEAoIBAECAQicCAASBLkBBy0KmwEKBAQBAgISBL0BAkIajAEgT3B0aW9uYWwuIElm
IHNldCB0byB0cnVlLCBhbmQgdGhlIGRhdGEgcG9saWN5IGlzIG5vdCBmb3VuZCwgYSBuZXcg
ZGF0YQogcG9saWN5IHdpbGwgYmUgY3JlYXRlZC4gSW4gdGhpcyBzaXR1YXRpb24sIHVwZGF0
ZV9tYXNrIGlzIGlnbm9yZWQuCgoNCgUEAQICBRIEvQECBgoNCgUEAQICARIEvQEHFAoNCgUE
AQICAxIEvQEXGAoNCgUEAQICCBIEvQEZQQoQCggEAQICCJwIABIEvQEaQAo7CgIEAhIGwQEA
1wEBGi0gUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgQWRkR3JhbnRlZXMgbWV0aG9kLgoKCwoD
BAIBEgTBAQgaCqQBCgQEAgIAEgbEAQLJAQQakwEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUg
b2YgdGhpcyBkYXRhIHBvbGljeSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZGF0YVBvbGljaWVzL3tkYXRh
X3BvbGljeV9pZH1gLgoKDQoFBAICAAUSBMQBAggKDQoFBAICAAESBMQBCRQKDQoFBAICAAMS
BMQBFxgKDwoFBAICAAgSBsQBGckBAwoQCggEAgIACJwIABIExQEEKgoRCgcEAgIACJ8IEgbG
AQTIAQUK7wIKBAQCAgESBNYBAkga4AIgUmVxdWlyZWQuIElBTSBwcmluY2lwYWwgdGhhdCBz
aG91bGQgYmUgZ3JhbnRlZCBGaW5lIEdyYWluZWQgQWNjZXNzIHRvIHRoZQogdW5kZXJseWlu
ZyBkYXRhIGdvdmVyZW5lZCBieSB0aGUgZGF0YSBwb2xpY3kuIFRoZSB0YXJnZXQgZGF0YSBw
b2xpY3kgaXMKIGRldGVybWluZWQgYnkgdGhlIGBkYXRhX3BvbGljeWAgZmllbGQuCgogVXNl
cyB0aGUgW0lBTSBWMiBwcmluY2lwYWwKIHN5bnRheF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2lhbS9kb2NzL3ByaW5jaXBhbC1pZGVudGlmaWVycyN2MikuCiBTdXBwb3J0ZWQgcHJp
bmNpcGFsIHR5cGVzOgoKICogVXNlcgogKiBHcm91cAogKiBTZXJ2aWNlIGFjY291bnQKCg0K
BQQCAgEEEgTWAQIKCg0KBQQCAgEFEgTWAQsRCg0KBQQCAgEBEgTWARIaCg0KBQQCAgEDEgTW
AR0eCg0KBQQCAgEIEgTWAR9HChAKCAQCAgEInAgAEgTWASBGCj4KAgQDEgbaAQDwAQEaMCBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBSZW1vdmVHcmFudGVlcyBtZXRob2QuCgoLCgMEAwES
BNoBCB0KpAEKBAQDAgASBt0BAuIBBBqTASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0
aGlzIGRhdGEgcG9saWN5LCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3Rf
bnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9kYXRhUG9saWNpZXMve2RhdGFfcG9s
aWN5X2lkfWAuCgoNCgUEAwIABRIE3QECCAoNCgUEAwIAARIE3QEJFAoNCgUEAwIAAxIE3QEX
GAoPCgUEAwIACBIG3QEZ4gEDChAKCAQDAgAInAgAEgTeAQQqChEKBwQDAgAInwgSBt8BBOEB
BQr0AgoEBAMCARIE7wECSBrlAiBSZXF1aXJlZC4gSUFNIHByaW5jaXBhbCB0aGF0IHNob3Vs
ZCBiZSByZXZva2VkIGZyb20gRmluZSBHcmFpbmVkIEFjY2VzcyB0bwogdGhlIHVuZGVybHlp
bmcgZGF0YSBnb3ZlcmVuZWQgYnkgdGhlIGRhdGEgcG9saWN5LiBUaGUgdGFyZ2V0IGRhdGEg
cG9saWN5IGlzCiBkZXRlcm1pbmVkIGJ5IHRoZSBgZGF0YV9wb2xpY3lgIGZpZWxkLgoKIFVz
ZXMgdGhlIFtJQU0gVjIgcHJpbmNpcGFsCiBzeW50YXhdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9pYW0vZG9jcy9wcmluY2lwYWwtaWRlbnRpZmllcnMjdjIpLgogU3VwcG9ydGVkIHBy
aW5jaXBhbCB0eXBlczoKCiAqIFVzZXIKICogR3JvdXAKICogU2VydmljZSBhY2NvdW50CgoN
CgUEAwIBBBIE7wECCgoNCgUEAwIBBRIE7wELEQoNCgUEAwIBARIE7wESGgoNCgUEAwIBAxIE
7wEdHgoNCgUEAwIBCBIE7wEfRwoQCggEAwIBCJwIABIE7wEgRgpACgIEBBIG8wEA/AEBGjIg
UmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgRGVsZXRlRGF0YVBvbGljeSBtZXRob2QuCgoLCgME
BAESBPMBCB8KmgEKBAQEAgASBvYBAvsBBBqJASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBv
ZiB0aGUgZGF0YSBwb2xpY3kgdG8gZGVsZXRlLiBGb3JtYXQgaXMKIGBwcm9qZWN0cy97cHJv
amVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2RhdGFQb2xpY2llcy97aWR9
YC4KCg0KBQQEAgAFEgT2AQIICg0KBQQEAgABEgT2AQkNCg0KBQQEAgADEgT2ARARCg8KBQQE
AgAIEgb2ARL7AQMKEAoIBAQCAAicCAASBPcBBCoKEQoHBAQCAAifCBIG+AEE+gEFCj0KAgQF
Egb/AQCIAgEaLyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBHZXREYXRhUG9saWN5IG1ldGhv
ZC4KCgsKAwQFARIE/wEIHAqaAQoEBAUCABIGggIChwIEGokBIFJlcXVpcmVkLiBSZXNvdXJj
ZSBuYW1lIG9mIHRoZSByZXF1ZXN0ZWQgZGF0YSBwb2xpY3kuIEZvcm1hdCBpcwogYHByb2pl
Y3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZGF0YVBvbGlj
aWVzL3tpZH1gLgoKDQoFBAUCAAUSBIICAggKDQoFBAUCAAESBIICCQ0KDQoFBAUCAAMSBIIC
EBEKDwoFBAUCAAgSBoICEocCAwoQCggEBQIACJwIABIEgwIEKgoRCgcEBQIACJ8IEgaEAgSG
AgUKQAoCBAYSBosCAKYCARoyIFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIExpc3REYXRhUG9s
aWNpZXMgbWV0aG9kLgoKCwoDBAYBEgSLAggfCpoBCgQEBgIAEgaOAgKTAgQaiQEgUmVxdWly
ZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHByb2plY3QgZm9yIHdoaWNoIHRvIGxpc3QgZGF0
YSBwb2xpY2llcy4KIEZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2Nh
dGlvbnMve2xvY2F0aW9uX2lkfWAuCgoNCgUEBgIABRIEjgICCAoNCgUEBgIAARIEjgIJDwoN
CgUEBgIAAxIEjgISEwoPCgUEBgIACBIGjgIUkwIDChAKCAQGAgAInAgAEgSPAgQqChEKBwQG
AgAInwgSBpACBJICBQqJAQoEBAYCARIElwICPxp7IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBu
dW1iZXIgb2YgZGF0YSBwb2xpY2llcyB0byByZXR1cm4uIE11c3QgYmUgYSB2YWx1ZQogYmV0
d2VlbiAxIGFuZCAxMDAwLiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byA1MC4KCg0KBQQGAgEF
EgSXAgIHCg0KBQQGAgEBEgSXAggRCg0KBQQGAgEDEgSXAhQVCg0KBQQGAgEIEgSXAhY+ChAK
CAQGAgEInAgAEgSXAhc9CowBCgQEBgICEgSbAgJBGn4gT3B0aW9uYWwuIFRoZSBgbmV4dFBh
Z2VUb2tlbmAgdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdCwK
IGlmIGFueS4gSWYgbm90IHNldCwgZGVmYXVsdHMgdG8gYW4gZW1wdHkgc3RyaW5nLgoKDQoF
BAYCAgUSBJsCAggKDQoFBAYCAgESBJsCCRMKDQoFBAYCAgMSBJsCFhcKDQoFBAYCAggSBJsC
GEAKEAoIBAYCAgicCAASBJsCGT8KsAMKBAQGAgMSBKUCAj0aoQMgT3B0aW9uYWwuIEZpbHRl
cnMgdGhlIGRhdGEgcG9saWNpZXMgYnkgcG9saWN5IHRhZ3MgdGhhdCB0aGV5CiBhcmUgYXNz
b2NpYXRlZCB3aXRoLiBDdXJyZW50bHkgZmlsdGVyIG9ubHkgc3VwcG9ydHMKICJwb2xpY3lf
dGFnIiBiYXNlZCBmaWx0ZXJpbmcgYW5kIE9SIGJhc2VkIHByZWRpY2F0ZXMuIFNhbXBsZQog
ZmlsdGVyIGNhbiBiZSAicG9saWN5X3RhZzoKIHByb2plY3RzLzEvbG9jYXRpb25zL3VzL3Rh
eG9ub21pZXMvMi9wb2xpY3lUYWdzLzMiLgogWW91IG1heSBhbHNvIHVzZSB3aWxkY2FyZCBz
dWNoIGFzICJwb2xpY3lfdGFnOgogcHJvamVjdHMvMS9sb2NhdGlvbnMvdXMvdGF4b25vbWll
cy8yKiIuIFBsZWFzZSBub3RlIHRoYXQgT1IgcHJlZGljYXRlcwogY2Fubm90IGJlIHVzZWQg
d2l0aCB3aWxkY2FyZCBmaWx0ZXJzLgoKDQoFBAYCAwUSBKUCAggKDQoFBAYCAwESBKUCCQ8K
DQoFBAYCAwMSBKUCEhMKDQoFBAYCAwgSBKUCFDwKEAoIBAYCAwicCAASBKUCFTsKQQoCBAcS
BqkCALACARozIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIHRoZSBMaXN0RGF0YVBvbGljaWVzIG1l
dGhvZC4KCgsKAwQHARIEqQIIIApDCgQEBwIAEgSrAgIoGjUgRGF0YSBwb2xpY2llcyB0aGF0
IGJlbG9uZyB0byB0aGUgcmVxdWVzdGVkIHByb2plY3QuCgoNCgUEBwIABBIEqwICCgoNCgUE
BwIABhIEqwILFQoNCgUEBwIAARIEqwIWIwoNCgUEBwIAAxIEqwImJwpoCgQEBwIBEgSvAgId
GlogVG9rZW4gdXNlZCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9y
IGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSByZXN1bHRzLgoKDQoFBAcCAQUSBK8CAggK
DQoFBAcCAQESBK8CCRgKDQoFBAcCAQMSBK8CGxwKNAoCBAgSBrMCAIoDARomIFJlcHJlc2Vu
dHMgdGhlIGxhYmVsLXBvbGljeSBiaW5kaW5nLgoKCwoDBAgBEgSzAggSCg0KAwQIBxIGtAIC
uQIECg8KBQQIB50IEga0AgK5AgQKOAoEBAgEABIGvAICygIDGiggQSBsaXN0IG9mIHN1cHBv
cnRlZCBkYXRhIHBvbGljeSB0eXBlcy4KCg0KBQQIBAABEgS8AgcVClIKBgQIBAACABIEvgIE
JRpCIERlZmF1bHQgdmFsdWUgZm9yIHRoZSBkYXRhIHBvbGljeSB0eXBlLiBUaGlzIHNob3Vs
ZCBub3QgYmUgdXNlZC4KCg8KBwQIBAACAAESBL4CBCAKDwoHBAgEAAIAAhIEvgIjJApACgYE
CAQAAgESBMECBBwaMCBVc2VkIHRvIGNyZWF0ZSBhIGRhdGEgcG9saWN5IGZvciBkYXRhIG1h
c2tpbmcuCgoPCgcECAQAAgEBEgTBAgQXCg8KBwQIBAACAQISBMECGhsKQwoGBAgEAAICEgTE
AgQfGjMgVXNlZCB0byBjcmVhdGUgYSBkYXRhIHBvbGljeSBmb3IgcmF3IGRhdGEgYWNjZXNz
LgoKDwoHBAgEAAICARIExAIEGgoPCgcECAQAAgICEgTEAh0eCtMBCgYECAQAAgMSBMkCBCUa
wgEgVXNlZCB0byBjcmVhdGUgYSBkYXRhIHBvbGljeSBmb3IgY29sdW1uLWxldmVsIHNlY3Vy
aXR5LCB3aXRob3V0IGRhdGEKIG1hc2tpbmcuIFRoaXMgaXMgZGVwcmVjYXRlZCBpbiBWMiBh
cGkgYW5kIG9ubHkgcHJlc2VudCB0byBzdXBwb3J0IEdFVCBhbmQKIExJU1Qgb3BlcmF0aW9u
cyBmb3IgVjEgZGF0YSBwb2xpY2llcyBpbiBWMiBhcGkuCgoPCgcECAQAAgMBEgTJAgQgCg8K
BwQIBAACAwISBMkCIyQKRgoEBAgEARIGzQIC1wIDGjYgVGhlIHN1cHBvcnRlZCB2ZXJzaW9u
cyBmb3IgdGhlIERhdGEgUG9saWN5IHJlc291cmNlLgoKDQoFBAgEAQESBM0CBw4KVQoGBAgE
AQIAEgTPAgQcGkUgRGVmYXVsdCB2YWx1ZSBmb3IgdGhlIGRhdGEgcG9saWN5IHZlcnNpb24u
IFRoaXMgc2hvdWxkIG5vdCBiZSB1c2VkLgoKDwoHBAgEAQIAARIEzwIEFwoPCgcECAQBAgAC
EgTPAhobCpkBCgYECAQBAgESBNMCBAsaiAEgVjEgZGF0YSBwb2xpY3kgdmVyc2lvbi4gVjEg
RGF0YSBQb2xpY2llcyB3aWxsIGJlIHByZXNlbnQgaW4gVjIgTGlzdCBhcGkKIHJlc3BvbnNl
LCBidXQgY2FuIG5vdCBiZSBjcmVhdGVkL3VwZGF0ZWQvZGVsZXRlZCBmcm9tIFYyIGFwaS4K
Cg8KBwQIBAECAQESBNMCBAYKDwoHBAgEAQIBAhIE0wIJCgopCgYECAQBAgISBNYCBAsaGSBW
MiBkYXRhIHBvbGljeSB2ZXJzaW9uLgoKDwoHBAgEAQICARIE1gIEBgoPCgcECAQBAgICEgTW
AgkKCj8KBAQICAASBtoCAt8CAxovIFRoZSBwb2xpY3kgdGhhdCBpcyBib3VuZCB0byB0aGlz
IGRhdGEgcG9saWN5LgoKDQoFBAgIAAESBNoCCA4KoQEKBAQIAgASBt0CBN4CMRqQASBPcHRp
b25hbC4gVGhlIGRhdGEgbWFza2luZyBwb2xpY3kgdGhhdCBzcGVjaWZpZXMgdGhlIGRhdGEg
bWFza2luZyBydWxlIHRvCiB1c2UuIEl0IG11c3QgYmUgc2V0IGlmIHRoZSBkYXRhIHBvbGlj
eSB0eXBlIGlzIERBVEFfTUFTS0lOR19QT0xJQ1kuCgoNCgUECAIABhIE3QIEFQoNCgUECAIA
ARIE3QIWKQoNCgUECAIAAxIE3QIsLQoNCgUECAIACBIE3gIIMAoQCggECAIACJwIABIE3gIJ
LwqkAQoEBAgCARIE4wICPRqVASBJZGVudGlmaWVyLiBSZXNvdXJjZSBuYW1lIG9mIHRoaXMg
ZGF0YSBwb2xpY3ksIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdF9udW1i
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2RhdGFQb2xpY2llcy97ZGF0YV9wb2xpY3lf
aWR9YC4KCg0KBQQIAgEFEgTjAgIICg0KBQQIAgEBEgTjAgkNCg0KBQQIAgEDEgTjAhARCg0K
BQQIAgEIEgTjAhI8ChAKCAQIAgEInAgAEgTjAhM7CrUBCgQECAICEgToAgJIGqYBIE91dHB1
dCBvbmx5LiBVc2VyLWFzc2lnbmVkIChodW1hbiByZWFkYWJsZSkgSUQgb2YgdGhlIGRhdGEg
cG9saWN5IHRoYXQKIG5lZWRzIHRvIGJlIHVuaXF1ZSB3aXRoaW4gYSBwcm9qZWN0LiBVc2Vk
IGFzIHtkYXRhX3BvbGljeV9pZH0gaW4gcGFydCBvZgogdGhlIHJlc291cmNlIG5hbWUuCgoN
CgUECAICBRIE6AICCAoNCgUECAICARIE6AIJFwoNCgUECAICAxIE6AIaGwoNCgUECAICCBIE
6AIcRwoQCggECAICCJwIABIE6AIdRgqcAgoEBAgCAxIE7wICHBqNAiBUaGUgZXRhZyBmb3Ig
dGhpcyBEYXRhIFBvbGljeS4KIFRoaXMgZmllbGQgaXMgdXNlZCBmb3IgVXBkYXRlRGF0YVBv
bGljeSBjYWxscy4gSWYgRGF0YSBQb2xpY3kgZXhpc3RzLCB0aGlzCiBmaWVsZCBpcyByZXF1
aXJlZCBhbmQgbXVzdCBtYXRjaCB0aGUgc2VydmVyJ3MgZXRhZy4gSXQgd2lsbCBhbHNvIGJl
CiBwb3B1bGF0ZWQgaW4gdGhlIHJlc3BvbnNlIG9mIEdldERhdGFQb2xpY3ksIENyZWF0ZURh
dGFQb2xpY3ksIGFuZAogVXBkYXRlRGF0YVBvbGljeSBjYWxscy4KCg0KBQQIAgMEEgTvAgIK
Cg0KBQQIAgMFEgTvAgsRCg0KBQQIAgMBEgTvAhIWCg0KBQQIAgMDEgTvAhkbCi4KBAQIAgQS
BPICAk8aICBSZXF1aXJlZC4gVHlwZSBvZiBkYXRhIHBvbGljeS4KCg0KBQQIAgQGEgTyAgIQ
Cg0KBQQIAgQBEgTyAhEhCg0KBQQIAgQDEgTyAiQlCg0KBQQIAgQIEgTyAiZOChAKCAQIAgQI
nAgAEgTyAidNCucBCgQECAIFEgb3AgL8AgQa1gEgT3V0cHV0IG9ubHkuIFBvbGljeSB0YWcg
cmVzb3VyY2UgbmFtZSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0X251
bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vdGF4b25vbWllcy97dGF4b25vbXlfaWR9
L3BvbGljeVRhZ3Mve3BvbGljeVRhZ19pZH1gLgogcG9saWN5X3RhZyBpcyBzdXBwb3J0ZWQg
b25seSBmb3IgVjEgZGF0YSBwb2xpY2llcy4KCg0KBQQIAgUFEgT3AgIICg0KBQQIAgUBEgT3
AgkTCg0KBQQIAgUDEgT3AhYXCg8KBQQIAgUIEgb3Ahj8AgMKEAoIBAgCBQicCAASBPgCBC0K
EQoHBAgCBQifCBIG+QIE+wIFCs4DCgQECAIGEgSGAwJIGr8DIE9wdGlvbmFsLiBUaGUgbGlz
dCBvZiBJQU0gcHJpbmNpcGFscyB0aGF0IGhhdmUgRmluZSBHcmFpbmVkIEFjY2VzcyB0byB0
aGUKIHVuZGVybHlpbmcgZGF0YSBnb3ZlcmVuZWQgYnkgdGhpcyBkYXRhIHBvbGljeS4KCiBV
c2VzIHRoZSBbSUFNIFYyIHByaW5jaXBhbAogc3ludGF4XShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vaWFtL2RvY3MvcHJpbmNpcGFsLWlkZW50aWZpZXJzI3YyKSBPbmx5CiBzdXBwb3J0
cyBwcmluY2lwYWwgdHlwZXMgdXNlcnMsIGdyb3Vwcywgc2VydmljZWFjY291bnRzLCBjbG91
ZGlkZW50aXR5LgogVGhpcyBmaWVsZCBpcyBzdXBwb3J0ZWQgaW4gVjIgRGF0YSBQb2xpY3kg
b25seS4gSW4gY2FzZSBvZiBWMSBkYXRhIHBvbGljaWVzCiAoaS5lLiB2ZXJpb24gPSAxIGFu
ZCBwb2xpY3lfdGFnIGlzIHNldCksIHRoaXMgZmllbGQgaXMgbm90IHBvcHVsYXRlZC4KCg0K
BQQIAgYEEgSGAwIKCg0KBQQIAgYFEgSGAwsRCg0KBQQIAgYBEgSGAxIaCg0KBQQIAgYDEgSG
Ax0eCg0KBQQIAgYIEgSGAx9HChAKCAQIAgYInAgAEgSGAyBGCkUKBAQIAgcSBIkDAkIaNyBP
dXRwdXQgb25seS4gVGhlIHZlcnNpb24gb2YgdGhlIERhdGEgUG9saWN5IHJlc291cmNlLgoK
DQoFBAgCBwYSBIkDAgkKDQoFBAgCBwESBIkDChEKDQoFBAgCBwMSBIkDFBUKDQoFBAgCBwgS
BIkDFkEKEAoIBAgCBwicCAASBIkDF0AKPQoCBAkSBo0DAO8DARovIFRoZSBwb2xpY3kgdXNl
ZCB0byBzcGVjaWZ5IGRhdGEgbWFza2luZyBydWxlLgoKCwoDBAkBEgSNAwgZCpMBCgQECQQA
EgaQAwLdAwMaggEgVGhlIGF2YWlsYWJsZSBtYXNraW5nIHJ1bGVzLiBMZWFybiBtb3JlIGhl
cmU6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmlncXVlcnkvZG9jcy9jb2x1bW4tZGF0
YS1tYXNraW5nLWludHJvI21hc2tpbmdfb3B0aW9ucy4KCg0KBQQJBAABEgSQAwcbCnsKBgQJ
BAACABIEkwMEKhprIERlZmF1bHQsIHVuc3BlY2lmaWVkIHByZWRlZmluZWQgZXhwcmVzc2lv
bi4gTm8gbWFza2luZyB3aWxsIHRha2UgcGxhY2UKIHNpbmNlIG5vIGV4cHJlc3Npb24gaXMg
c3BlY2lmaWVkLgoKDwoHBAkEAAIAARIEkwMEJQoPCgcECQQAAgACEgSTAygpCkcKBgQJBAAC
ARIElgMEDxo3IE1hc2tpbmcgZXhwcmVzc2lvbiB0byByZXBsYWNlIGRhdGEgd2l0aCBTSEEt
MjU2IGhhc2guCgoPCgcECQQAAgEBEgSWAwQKCg8KBwQJBAACAQISBJYDDQ4KQAoGBAkEAAIC
EgSZAwQUGjAgTWFza2luZyBleHByZXNzaW9uIHRvIHJlcGxhY2UgZGF0YSB3aXRoIE5VTExz
LgoKDwoHBAkEAAICARIEmQMEDwoPCgcECQQAAgICEgSZAxITCrgDCgYECQQAAgMSBK0DBB4a
pwMgTWFza2luZyBleHByZXNzaW9uIHRvIHJlcGxhY2UgZGF0YSB3aXRoIHRoZWlyIGRlZmF1
bHQgbWFza2luZyB2YWx1ZXMuCiBUaGUgZGVmYXVsdCBtYXNraW5nIHZhbHVlcyBmb3IgZWFj
aCB0eXBlIGxpc3RlZCBhcyBiZWxvdzoKCiAqIFNUUklORzogIiIKICogQllURVM6IGInJwog
KiBJTlRFR0VSOiAwCiAqIEZMT0FUOiAwLjAKICogTlVNRVJJQzogMAogKiBCT09MRUFOOiBG
QUxTRQogKiBUSU1FU1RBTVA6IDE5NzAtMDEtMDEgMDA6MDA6MDAgVVRDCiAqIERBVEU6IDE5
NzAtMDEtMDEKICogVElNRTogMDA6MDA6MDAKICogREFURVRJTUU6IDE5NzAtMDEtMDFUMDA6
MDA6MDAKICogR0VPR1JBUEhZOiBQT0lOVCgwIDApCiAqIEJJR05VTUVSSUM6IDAKICogQVJS
QVk6IFtdCiAqIFNUUlVDVDogTk9UX0FQUExJQ0FCTEUKICogSlNPTjogTlVMTAoKDwoHBAkE
AAIDARIErQMEGQoPCgcECQQAAgMCEgStAxwdCpQCCgYECQQAAgQSBLUDBB0agwIgTWFza2lu
ZyBleHByZXNzaW9uIHNob3dzIHRoZSBsYXN0IGZvdXIgY2hhcmFjdGVycyBvZiB0ZXh0Lgog
VGhlIG1hc2tpbmcgYmVoYXZpb3IgaXMgYXMgZm9sbG93czoKCiAqIElmIHRleHQgbGVuZ3Ro
ID4gNCBjaGFyYWN0ZXJzOiBSZXBsYWNlIHRleHQgd2l0aCBYWFhYWCwgYXBwZW5kIGxhc3QK
IGZvdXIgY2hhcmFjdGVycyBvZiBvcmlnaW5hbCB0ZXh0LgogKiBJZiB0ZXh0IGxlbmd0aCA8
PSA0IGNoYXJhY3RlcnM6IEFwcGx5IFNIQS0yNTYgaGFzaC4KCg8KBwQJBAACBAESBLUDBBgK
DwoHBAkEAAIEAhIEtQMbHAqXAgoGBAkEAAIFEgS9AwQeGoYCIE1hc2tpbmcgZXhwcmVzc2lv
biBzaG93cyB0aGUgZmlyc3QgZm91ciBjaGFyYWN0ZXJzIG9mIHRleHQuCiBUaGUgbWFza2lu
ZyBiZWhhdmlvciBpcyBhcyBmb2xsb3dzOgoKICogSWYgdGV4dCBsZW5ndGggPiA0IGNoYXJh
Y3RlcnM6IFJlcGxhY2UgdGV4dCB3aXRoIFhYWFhYLCBwcmVwZW5kIGZpcnN0CiBmb3VyIGNo
YXJhY3RlcnMgb2Ygb3JpZ2luYWwgdGV4dC4KICogSWYgdGV4dCBsZW5ndGggPD0gNCBjaGFy
YWN0ZXJzOiBBcHBseSBTSEEtMjU2IGhhc2guCgoPCgcECQQAAgUBEgS9AwQZCg8KBwQJBAAC
BQISBL0DHB0KkgMKBgQJBAACBhIEyAMEExqBAyBNYXNraW5nIGV4cHJlc3Npb24gZm9yIGVt
YWlsIGFkZHJlc3Nlcy4KIFRoZSBtYXNraW5nIGJlaGF2aW9yIGlzIGFzIGZvbGxvd3M6Cgog
KiBTeW50YXgtdmFsaWQgZW1haWwgYWRkcmVzczogUmVwbGFjZSB1c2VybmFtZSB3aXRoIFhY
WFhYLiBGb3IgZXhhbXBsZSwKIGNsb3VkeXNhbmZyYW5jaXNjb0BnbWFpbC5jb20gYmVjb21l
cyBYWFhYWEBnbWFpbC5jb20uCiAqIFN5bnRheC1pbnZhbGlkIGVtYWlsIGFkZHJlc3M6IEFw
cGx5IFNIQS0yNTYgaGFzaC4KCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlIFtFbWFpbAog
bWFza10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpZ3F1ZXJ5L2RvY3MvY29sdW1uLWRh
dGEtbWFza2luZy1pbnRybyNtYXNraW5nX29wdGlvbnMpLgoKDwoHBAkEAAIGARIEyAMEDgoP
CgcECQQAAgYCEgTIAxESCoMECgYECQQAAgcSBNYDBBca8gMgTWFza2luZyBleHByZXNzaW9u
IHRvIG9ubHkgc2hvdyB0aGUgPGk+eWVhcjwvaT4gb2YgYERhdGVgLAogYERhdGVUaW1lYCBh
bmQgYFRpbWVTdGFtcGAuIEZvciBleGFtcGxlLCB3aXRoIHRoZQogeWVhciAyMDc2OgoKICog
REFURSAgICAgICAgIDogIDIwNzYtMDEtMDEKICogREFURVRJTUUgICAgIDogIDIwNzYtMDEt
MDFUMDA6MDA6MDAKICogVElNRVNUQU1QICAgIDogIDIwNzYtMDEtMDEgMDA6MDA6MDAgVVRD
CgogVHJ1bmNhdGlvbiBvY2N1cnMgYWNjb3JkaW5nIHRvIHRoZSBVVEMgdGltZSB6b25lLiBU
byBjaGFuZ2UgdGhpcywgYWRqdXN0CiB0aGUgZGVmYXVsdCB0aW1lIHpvbmUgdXNpbmcgdGhl
IGB0aW1lX3pvbmVgIHN5c3RlbSB2YXJpYWJsZS4KIEZvciBtb3JlIGluZm9ybWF0aW9uLCBz
ZWUgW1N5c3RlbSB2YXJpYWJsZXMKIHJlZmVyZW5jZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2JpZ3F1ZXJ5L2RvY3MvcmVmZXJlbmNlL3N5c3RlbS12YXJpYWJsZXMpLgoKDwoHBAkE
AAIHARIE1gMEEgoPCgcECQQAAgcCEgTWAxUWCqQCCgYECQQAAggSBNwDBBQakwIgTWFza2lu
ZyBleHByZXNzaW9uIHRoYXQgdXNlcyBoYXNoaW5nIHRvIG1hc2sgY29sdW1uIGRhdGEuCiBJ
dCBkaWZmZXJzIGZyb20gU0hBMjU2IGluIHRoYXQgYSB1bmlxdWUgcmFuZG9tIHZhbHVlIGlz
IGdlbmVyYXRlZCBmb3IKIGVhY2ggcXVlcnkgYW5kIGlzIGFkZGVkIHRvIHRoZSBoYXNoIGlu
cHV0LCByZXN1bHRpbmcgaW4gdGhlIGhhc2ggLyBtYXNrZWQKIHJlc3VsdCB0byBiZSBkaWZm
ZXJlbnQgZm9yIGVhY2ggcXVlcnkuIEhlbmNlIHRoZSBuYW1lICJyYW5kb20gaGFzaCIuCgoP
CgcECQQAAggBEgTcAwQPCg8KBwQJBAACCAISBNwDEhMKSAoEBAkIABIG4AMC7gMDGjggQSBt
YXNraW5nIGV4cHJlc3Npb24gdG8gYmluZCB0byB0aGUgZGF0YSBtYXNraW5nIHJ1bGUuCgoN
CgUECQgAARIE4AMIGgo8CgQECQIAEgbiAwTjAzEaLCBPcHRpb25hbC4gQSBwcmVkZWZpbmVk
IG1hc2tpbmcgZXhwcmVzc2lvbi4KCg0KBQQJAgAGEgTiAwQYCg0KBQQJAgABEgTiAxkuCg0K
BQQJAgADEgTiAzEyCg0KBQQJAgAIEgTjAwgwChAKCAQJAgAInAgAEgTjAwkvCsMBCgQECQIB
EgboAwTtAwYasgEgT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRoZSBCaWdRdWVyeSByb3V0aW5l
IHRoYXQgY29udGFpbnMgdGhlIGN1c3RvbQogbWFza2luZyByb3V0aW5lLCBpbiB0aGUgZm9y
bWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9kYXRhc2V0cy97ZGF0YXNldF9p
ZH0vcm91dGluZXMve3JvdXRpbmVfaWR9YC4KCg0KBQQJAgEFEgToAwQKCg0KBQQJAgEBEgTo
AwsSCg0KBQQJAgEDEgToAxUWCg8KBQQJAgEIEgboAxftAwUKEAoIBAkCAQicCAASBOkDBiwK
EQoHBAkCAQifCBIG6gMG7AMHYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest ===
    # Fields for CreateDataPolicyRequest
    # Field: parent Type: 9 ()
    # Field: data_policy_id Type: 9 ()
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v2.DataPolicy)

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::UpdateDataPolicyRequest ===
    # Fields for UpdateDataPolicyRequest
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v2.DataPolicy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::AddGranteesRequest ===
    # Fields for AddGranteesRequest
    # Field: data_policy Type: 9 ()
    # Field: grantees Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::RemoveGranteesRequest ===
    # Fields for RemoveGranteesRequest
    # Field: data_policy Type: 9 ()
    # Field: grantees Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DeleteDataPolicyRequest ===
    # Fields for DeleteDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::GetDataPolicyRequest ===
    # Fields for GetDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesRequest ===
    # Fields for ListDataPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesResponse ===
    # Fields for ListDataPoliciesResponse
    # Field: data_policies Type: 11 (.google.cloud.bigquery.datapolicies.v2.DataPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy ===
    # Fields for DataPolicy
    # Field: data_masking_policy Type: 11 (.google.cloud.bigquery.datapolicies.v2.DataMaskingPolicy)
    # Field: name Type: 9 ()
    # Field: data_policy_id Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: data_policy_type Type: 14 (.google.cloud.bigquery.datapolicies.v2.DataPolicy.DataPolicyType)
    # Field: policy_tag Type: 9 ()
    # Field: grantees Type: 9 ()
    # Field: version Type: 14 (.google.cloud.bigquery.datapolicies.v2.DataPolicy.Version)

# Enum: DataPolicy::DataPolicyType
our $DataPolicy_DATA_POLICY_TYPE_UNSPECIFIED = 0;
our $DataPolicy_DATA_MASKING_POLICY = 1;
our $DataPolicy_RAW_DATA_ACCESS_POLICY = 2;
our $DataPolicy_COLUMN_LEVEL_SECURITY_POLICY = 3;

# Enum: DataPolicy::Version
our $DataPolicy_VERSION_UNSPECIFIED = 0;
our $DataPolicy_V1 = 1;
our $DataPolicy_V2 = 2;

# === Message: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataMaskingPolicy ===
    # Fields for DataMaskingPolicy
    # Field: predefined_expression Type: 14 (.google.cloud.bigquery.datapolicies.v2.DataMaskingPolicy.PredefinedExpression)
    # Field: routine Type: 9 ()

# Enum: DataMaskingPolicy::PredefinedExpression
our $DataMaskingPolicy_PREDEFINED_EXPRESSION_UNSPECIFIED = 0;
our $DataMaskingPolicy_SHA256 = 1;
our $DataMaskingPolicy_ALWAYS_NULL = 2;
our $DataMaskingPolicy_DEFAULT_MASKING_VALUE = 3;
our $DataMaskingPolicy_LAST_FOUR_CHARACTERS = 4;
our $DataMaskingPolicy_FIRST_FOUR_CHARACTERS = 5;
our $DataMaskingPolicy_EMAIL_MASK = 6;
our $DataMaskingPolicy_DATE_YEAR_MASK = 7;
our $DataMaskingPolicy_RANDOM_HASH = 8;

# === Service Client: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicyServiceClient ===
package Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicyServiceClient

Client stub representing the remote C<DataPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'CreateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy',
    });
}

sub add_grantees {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::AddGranteesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'AddGrantees',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy',
    });
}

sub remove_grantees {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::RemoveGranteesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'RemoveGrantees',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy',
    });
}

sub update_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::UpdateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'UpdateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy',
    });
}

sub delete_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DeleteDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'DeleteDataPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::GetDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'GetDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy',
    });
}

sub list_data_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'ListDataPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesResponse',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'SetIamPolicy',
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
        service        => 'google.cloud.bigquery.datapolicies.v2.DataPolicyService',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy - Compiled Protocol Buffers messages for google/cloud/bigquery/datapolicies/v2/datapolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy;

    my $msg = Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest->new({
        parent => $parent,
        data_policy_id => $data_policy_id,
        data_policy => $data_policy,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/datapolicies/v2/datapolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest

Request message for the CreateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the data policy will belong to.
The format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->data_policy_id() >> / C<< $msg->data_policy_id($value) >>

Type: C<String>

Required. User-assigned (human readable) ID of the data policy that needs
to be unique within a project. Used as {data_policy_id} in part of the
resource name.

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy>)

Required. The data policy to create. The `name` field does not need to be
provided for the data policy creation.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::UpdateDataPolicyRequest

Request message for the UpdateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy>)

Required. Update the data policy's metadata.

The target data policy is determined by the `name` field.
Other fields are updated to the specified values based on the field masks.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The update mask applies to the resource. For the `FieldMask`
definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
If not set, defaults to all of the fields that are allowed to update.

Updates to the `name` and `dataPolicyId` fields are not allowed.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

Optional. If set to true, and the data policy is not found, a new data
policy will be created. In this situation, update_mask is ignored.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::AddGranteesRequest

Request message for the AddGrantees method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<String>

Required. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Required. IAM principal that should be granted Fine Grained Access to the
underlying data goverened by the data policy. The target data policy is
determined by the `data_policy` field.

Uses the [IAM V2 principal
syntax](https://cloud.google.com/iam/docs/principal-identifiers#v2).
Supported principal types:

* User
* Group
* Service account

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::RemoveGranteesRequest

Request message for the RemoveGrantees method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<String>

Required. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Required. IAM principal that should be revoked from Fine Grained Access to
the underlying data goverened by the data policy. The target data policy is
determined by the `data_policy` field.

Uses the [IAM V2 principal
syntax](https://cloud.google.com/iam/docs/principal-identifiers#v2).
Supported principal types:

* User
* Group
* Service account

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DeleteDataPolicyRequest

Request message for the DeleteDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the data policy to delete. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::GetDataPolicyRequest

Request message for the GetDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the requested data policy. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesRequest

Request message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project for which to list data policies.
Format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of data policies to return. Must be a value
between 1 and 1000. If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The `nextPageToken` value returned from a previous list request,
if any. If not set, defaults to an empty string.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filters the data policies by policy tags that they
are associated with. Currently filter only supports
"policy_tag" based filtering and OR based predicates. Sample
filter can be "policy_tag:
projects/1/locations/us/taxonomies/2/policyTags/3".
You may also use wildcard such as "policy_tag:
projects/1/locations/us/taxonomies/2*". Please note that OR predicates
cannot be used with wildcard filters.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesResponse

Response message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policies() >> / C<< $msg->data_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy>)

Data policies that belong to the requested project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token used to retrieve the next page of results, or empty if there are no
more results.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy

Represents the label-policy binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_masking_policy() >> / C<< $msg->data_masking_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataMaskingPolicy>)

Optional. The data masking policy that specifies the data masking rule to
use. It must be set if the data policy type is DATA_MASKING_POLICY.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->data_policy_id() >> / C<< $msg->data_policy_id($value) >>

Type: C<String>

Output only. User-assigned (human readable) ID of the data policy that
needs to be unique within a project. Used as {data_policy_id} in part of
the resource name.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

The etag for this Data Policy.
This field is used for UpdateDataPolicy calls. If Data Policy exists, this
field is required and must match the server's etag. It will also be
populated in the response of GetDataPolicy, CreateDataPolicy, and
UpdateDataPolicy calls.

=item * C<< $msg->data_policy_type() >> / C<< $msg->data_policy_type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V2::DataPolicy::DataPolicyType>)

Required. Type of data policy.

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<String>

Output only. Policy tag resource name, in the format of
`projects/{project_number}/locations/{location_id}/taxonomies/{taxonomy_id}/policyTags/{policyTag_id}`.
policy_tag is supported only for V1 data policies.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

Optional. The list of IAM principals that have Fine Grained Access to the
underlying data goverened by this data policy.

Uses the [IAM V2 principal
syntax](https://cloud.google.com/iam/docs/principal-identifiers#v2) Only
supports principal types users, groups, serviceaccounts, cloudidentity.
This field is supported in V2 Data Policy only. In case of V1 data policies
(i.e. verion = 1 and policy_tag is set), this field is not populated.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V2::DataPolicy::Version>)

Output only. The version of the Data Policy resource.

=back

=head3 Enum: DataPolicy::DataPolicyType

=over 4

=item * C<DATA_POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<DATA_MASKING_POLICY> => C<1>

=item * C<RAW_DATA_ACCESS_POLICY> => C<2>

=item * C<COLUMN_LEVEL_SECURITY_POLICY> => C<3>

=back

=head3 Enum: DataPolicy::Version

=over 4

=item * C<VERSION_UNSPECIFIED> => C<0>

=item * C<V1> => C<1>

=item * C<V2> => C<2>

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataMaskingPolicy

The policy used to specify data masking rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predefined_expression() >> / C<< $msg->predefined_expression($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V2::DataMaskingPolicy::PredefinedExpression>)

Optional. A predefined masking expression.

=item * C<< $msg->routine() >> / C<< $msg->routine($value) >>

Type: C<String>

Optional. The name of the BigQuery routine that contains the custom
masking routine, in the format of
`projects/{project_number}/datasets/{dataset_id}/routines/{routine_id}`.

=back

=head3 Enum: DataMaskingPolicy::PredefinedExpression

=over 4

=item * C<PREDEFINED_EXPRESSION_UNSPECIFIED> => C<0>

=item * C<SHA256> => C<1>

=item * C<ALWAYS_NULL> => C<2>

=item * C<DEFAULT_MASKING_VALUE> => C<3>

=item * C<LAST_FOUR_CHARACTERS> => C<4>

=item * C<FIRST_FOUR_CHARACTERS> => C<5>

=item * C<EMAIL_MASK> => C<6>

=item * C<DATE_YEAR_MASK> => C<7>

=item * C<RANDOM_HASH> => C<8>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
