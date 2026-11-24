package Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvaHlwZXJjb21wdXRlY2x1c3Rlci92MWJldGEvb3BlcmF0aW9uX21l
dGFkYXRhLnByb3RvEidnb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWJldGEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ihgMKEU9wZXJhdGlvbk1l
dGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEoCUID4EEDUgZ0YXJnZXQS
FwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEjoKFnJlcXVlc3RlZF9jYW5jZWxsYXRpb24YBSAB
KAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9uGAYgASgJQgPg
QQNSCmFwaVZlcnNpb24SWwoIcHJvZ3Jlc3MYByABKAsyOi5nb29nbGUuY2xvdWQuaHlwZXJj
b21wdXRlY2x1c3Rlci52MWJldGEuT3BlcmF0aW9uUHJvZ3Jlc3NCA+BBA1IIcHJvZ3Jlc3Mi
ZgoRT3BlcmF0aW9uUHJvZ3Jlc3MSUQoFc3RlcHMYASADKAsyNi5nb29nbGUuY2xvdWQuaHlw
ZXJjb21wdXRlY2x1c3Rlci52MWJldGEuT3BlcmF0aW9uU3RlcEID4EEDUgVzdGVwcyKsFgoN
T3BlcmF0aW9uU3RlcBJkCg5jcmVhdGVfbmV0d29yaxgCIAEoCzI2Lmdvb2dsZS5jbG91ZC5o
eXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5DcmVhdGVOZXR3b3JrQgPgQQNIAFINY3JlYXRl
TmV0d29yaxKNAQodY3JlYXRlX3ByaXZhdGVfc2VydmljZV9hY2Nlc3MYAyABKAsyQy5nb29n
bGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWJldGEuQ3JlYXRlUHJpdmF0ZVNlcnZp
Y2VBY2Nlc3NCA+BBA0gAUhpjcmVhdGVQcml2YXRlU2VydmljZUFjY2VzcxKDAQoZY3JlYXRl
X2ZpbGVzdG9yZV9pbnN0YW5jZRgEIAEoCzJALmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVj
bHVzdGVyLnYxYmV0YS5DcmVhdGVGaWxlc3RvcmVJbnN0YW5jZUID4EEDSABSF2NyZWF0ZUZp
bGVzdG9yZUluc3RhbmNlEncKFWNyZWF0ZV9zdG9yYWdlX2J1Y2tldBgFIAEoCzI8Lmdvb2ds
ZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5DcmVhdGVTdG9yYWdlQnVja2V0
QgPgQQNIAFITY3JlYXRlU3RvcmFnZUJ1Y2tldBJ6ChZjcmVhdGVfbHVzdHJlX2luc3RhbmNl
GAYgASgLMj0uZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFiZXRhLkNyZWF0
ZUx1c3RyZUluc3RhbmNlQgPgQQNIAFIUY3JlYXRlTHVzdHJlSW5zdGFuY2UScwoTY3JlYXRl
X29yY2hlc3RyYXRvchgIIAEoCzI7Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVy
LnYxYmV0YS5DcmVhdGVPcmNoZXN0cmF0b3JCA+BBA0gAUhJjcmVhdGVPcmNoZXN0cmF0b3IS
ZAoOY3JlYXRlX25vZGVzZXQYCSABKAsyNi5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1
c3Rlci52MWJldGEuQ3JlYXRlTm9kZXNldEID4EEDSABSDWNyZWF0ZU5vZGVzZXQSagoQY3Jl
YXRlX3BhcnRpdGlvbhgKIAEoCzI4Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVy
LnYxYmV0YS5DcmVhdGVQYXJ0aXRpb25CA+BBA0gAUg9jcmVhdGVQYXJ0aXRpb24SawoRY3Jl
YXRlX2xvZ2luX25vZGUYCyABKAsyOC5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rl
ci52MWJldGEuQ3JlYXRlTG9naW5Ob2RlQgPgQQNIAFIPY3JlYXRlTG9naW5Ob2RlEnQKFGNo
ZWNrX2NsdXN0ZXJfaGVhbHRoGAwgASgLMjsuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNs
dXN0ZXIudjFiZXRhLkNoZWNrQ2x1c3RlckhlYWx0aEID4EEDSABSEmNoZWNrQ2x1c3Rlckhl
YWx0aBJzChN1cGRhdGVfb3JjaGVzdHJhdG9yGA0gASgLMjsuZ29vZ2xlLmNsb3VkLmh5cGVy
Y29tcHV0ZWNsdXN0ZXIudjFiZXRhLlVwZGF0ZU9yY2hlc3RyYXRvckID4EEDSABSEnVwZGF0
ZU9yY2hlc3RyYXRvchJkCg51cGRhdGVfbm9kZXNldBgOIAEoCzI2Lmdvb2dsZS5jbG91ZC5o
eXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5VcGRhdGVOb2Rlc2V0QgPgQQNIAFINdXBkYXRl
Tm9kZXNldBJqChB1cGRhdGVfcGFydGl0aW9uGA8gASgLMjguZ29vZ2xlLmNsb3VkLmh5cGVy
Y29tcHV0ZWNsdXN0ZXIudjFiZXRhLlVwZGF0ZVBhcnRpdGlvbkID4EEDSABSD3VwZGF0ZVBh
cnRpdGlvbhJrChF1cGRhdGVfbG9naW5fbm9kZRgQIAEoCzI4Lmdvb2dsZS5jbG91ZC5oeXBl
cmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5VcGRhdGVMb2dpbk5vZGVCA+BBA0gAUg91cGRhdGVM
b2dpbk5vZGUScwoTZGVsZXRlX29yY2hlc3RyYXRvchgSIAEoCzI7Lmdvb2dsZS5jbG91ZC5o
eXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5EZWxldGVPcmNoZXN0cmF0b3JCA+BBA0gAUhJk
ZWxldGVPcmNoZXN0cmF0b3ISZAoOZGVsZXRlX25vZGVzZXQYEyABKAsyNi5nb29nbGUuY2xv
dWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWJldGEuRGVsZXRlTm9kZXNldEID4EEDSABSDWRl
bGV0ZU5vZGVzZXQSagoQZGVsZXRlX3BhcnRpdGlvbhgUIAEoCzI4Lmdvb2dsZS5jbG91ZC5o
eXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5EZWxldGVQYXJ0aXRpb25CA+BBA0gAUg9kZWxl
dGVQYXJ0aXRpb24SawoRZGVsZXRlX2xvZ2luX25vZGUYFSABKAsyOC5nb29nbGUuY2xvdWQu
aHlwZXJjb21wdXRlY2x1c3Rlci52MWJldGEuRGVsZXRlTG9naW5Ob2RlQgPgQQNIAFIPZGVs
ZXRlTG9naW5Ob2RlEoMBChlkZWxldGVfZmlsZXN0b3JlX2luc3RhbmNlGBYgASgLMkAuZ29v
Z2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFiZXRhLkRlbGV0ZUZpbGVzdG9yZUlu
c3RhbmNlQgPgQQNIAFIXZGVsZXRlRmlsZXN0b3JlSW5zdGFuY2USdwoVZGVsZXRlX3N0b3Jh
Z2VfYnVja2V0GBcgASgLMjwuZ29vZ2xlLmNsb3VkLmh5cGVyY29tcHV0ZWNsdXN0ZXIudjFi
ZXRhLkRlbGV0ZVN0b3JhZ2VCdWNrZXRCA+BBA0gAUhNkZWxldGVTdG9yYWdlQnVja2V0EnoK
FmRlbGV0ZV9sdXN0cmVfaW5zdGFuY2UYGCABKAsyPS5nb29nbGUuY2xvdWQuaHlwZXJjb21w
dXRlY2x1c3Rlci52MWJldGEuRGVsZXRlTHVzdHJlSW5zdGFuY2VCA+BBA0gAUhRkZWxldGVM
dXN0cmVJbnN0YW5jZRKNAQodZGVsZXRlX3ByaXZhdGVfc2VydmljZV9hY2Nlc3MYGSABKAsy
Qy5nb29nbGUuY2xvdWQuaHlwZXJjb21wdXRlY2x1c3Rlci52MWJldGEuRGVsZXRlUHJpdmF0
ZVNlcnZpY2VBY2Nlc3NCA+BBA0gAUhpkZWxldGVQcml2YXRlU2VydmljZUFjY2VzcxJkCg5k
ZWxldGVfbmV0d29yaxgaIAEoCzI2Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVy
LnYxYmV0YS5EZWxldGVOZXR3b3JrQgPgQQNIAFINZGVsZXRlTmV0d29yaxJXCgVzdGF0ZRgB
IAEoDjI8Lmdvb2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YS5PcGVyYXRp
b25TdGVwLlN0YXRlQgPgQQNSBXN0YXRlIkYKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVE
EAASCwoHV0FJVElORxABEg8KC0lOX1BST0dSRVNTEAISCAoERE9ORRADQgYKBHR5cGUiUQoN
Q3JlYXRlTmV0d29yaxJACgduZXR3b3JrGAEgASgJQibgQQP6QSAKHmNvbXB1dGUuZ29vZ2xl
YXBpcy5jb20vTmV0d29ya1IHbmV0d29yayIcChpDcmVhdGVQcml2YXRlU2VydmljZUFjY2Vz
cyJhChdDcmVhdGVGaWxlc3RvcmVJbnN0YW5jZRJGCglmaWxlc3RvcmUYASABKAlCKOBBA/pB
IgogZmlsZS5nb29nbGVhcGlzLmNvbS9GaWxlSW5zdGFuY2VSCWZpbGVzdG9yZSJUChNDcmVh
dGVTdG9yYWdlQnVja2V0Ej0KBmJ1Y2tldBgBIAEoCUIl4EED+kEfCh1zdG9yYWdlLmdvb2ds
ZWFwaXMuY29tL0J1Y2tldFIGYnVja2V0IlYKFENyZWF0ZUx1c3RyZUluc3RhbmNlEj4KBmx1
c3RyZRgBIAEoCUIm4EED+kEgCh5sdXN0cmUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBmx1
c3RyZSIUChJDcmVhdGVPcmNoZXN0cmF0b3IiMAoNQ3JlYXRlTm9kZXNldBIfCghub2Rlc2V0
cxgBIAMoCUID4EEDUghub2Rlc2V0cyI2Cg9DcmVhdGVQYXJ0aXRpb24SIwoKcGFydGl0aW9u
cxgBIAMoCUID4EEDUgpwYXJ0aXRpb25zIhEKD0NyZWF0ZUxvZ2luTm9kZSIUChJDaGVja0Ns
dXN0ZXJIZWFsdGgiFAoSVXBkYXRlT3JjaGVzdHJhdG9yIjAKDVVwZGF0ZU5vZGVzZXQSHwoI
bm9kZXNldHMYASADKAlCA+BBA1IIbm9kZXNldHMiNgoPVXBkYXRlUGFydGl0aW9uEiMKCnBh
cnRpdGlvbnMYASADKAlCA+BBA1IKcGFydGl0aW9ucyIRCg9VcGRhdGVMb2dpbk5vZGUiFAoS
RGVsZXRlT3JjaGVzdHJhdG9yIjAKDURlbGV0ZU5vZGVzZXQSHwoIbm9kZXNldHMYASADKAlC
A+BBA1IIbm9kZXNldHMiNgoPRGVsZXRlUGFydGl0aW9uEiMKCnBhcnRpdGlvbnMYASADKAlC
A+BBA1IKcGFydGl0aW9ucyIRCg9EZWxldGVMb2dpbk5vZGUiYQoXRGVsZXRlRmlsZXN0b3Jl
SW5zdGFuY2USRgoJZmlsZXN0b3JlGAEgASgJQijgQQP6QSIKIGZpbGUuZ29vZ2xlYXBpcy5j
b20vRmlsZUluc3RhbmNlUglmaWxlc3RvcmUiVAoTRGVsZXRlU3RvcmFnZUJ1Y2tldBI9CgZi
dWNrZXQYASABKAlCJeBBA/pBHwodc3RvcmFnZS5nb29nbGVhcGlzLmNvbS9CdWNrZXRSBmJ1
Y2tldCJWChREZWxldGVMdXN0cmVJbnN0YW5jZRI+CgZsdXN0cmUYASABKAlCJuBBA/pBIAoe
bHVzdHJlLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgZsdXN0cmUiHAoaRGVsZXRlUHJpdmF0
ZVNlcnZpY2VBY2Nlc3MiUQoNRGVsZXRlTmV0d29yaxJACgduZXR3b3JrGAEgASgJQibgQQP6
QSAKHmNvbXB1dGUuZ29vZ2xlYXBpcy5jb20vTmV0d29ya1IHbmV0d29ya0KIAworY29tLmdv
b2dsZS5jbG91ZC5oeXBlcmNvbXB1dGVjbHVzdGVyLnYxYmV0YUIWT3BlcmF0aW9uTWV0YWRh
dGFQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2h5cGVyY29tcHV0ZWNsdXN0ZXIvYXBp
djFiZXRhL2h5cGVyY29tcHV0ZWNsdXN0ZXJwYjtoeXBlcmNvbXB1dGVjbHVzdGVycGKqAidH
b29nbGUuQ2xvdWQuSHlwZXJjb21wdXRlQ2x1c3Rlci5WMUJldGHKAidHb29nbGVcQ2xvdWRc
SHlwZXJjb21wdXRlQ2x1c3RlclxWMWJldGHqAipHb29nbGU6OkNsb3VkOjpIeXBlcmNvbXB1
dGVDbHVzdGVyOjpWMWJldGHqQV4KHmx1c3RyZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZRI8
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5z
dGFuY2V9SvpgCgcSBQ4A7AIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
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
CAoBAhIDEAAwCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYARAoJ
CgIIJRIDFgBECggKAQgSAxcAdAoJCgIICxIDFwB0CggKAQgSAxgAIgoJCgIIChIDGAAiCggK
AQgSAxkANwoJCgIICBIDGQA3CggKAQgSAxoARAoJCgIIARIDGgBECggKAQgSAxsARAoJCgII
KRIDGwBECggKAQgSAxwAQwoJCgIILRIDHABDCgkKAQgSBB0AIAIKDAoECJ0IABIEHQAgAgpE
CgIEABIEIwA/ARo4IFJlcHJlc2VudHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5p
bmcgb3BlcmF0aW9uLgoKCgoDBAABEgMjCBkKQAoEBAACABIEJQImMhoyIE91dHB1dCBvbmx5
LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAAYSAyUCGwoM
CgUEAAIAARIDJRwnCgwKBQQAAgADEgMlKisKDAoFBAACAAgSAyYGMQoPCggEAAIACJwIABID
JgcwCkUKBAQAAgESBCkCKjIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlv
biBmaW5pc2hlZCBydW5uaW5nLgoKDAoFBAACAQYSAykCGwoMCgUEAAIBARIDKRwkCgwKBQQA
AgEDEgMpJygKDAoFBAACAQgSAyoGMQoPCggEAAIBCJwIABIDKgcwClkKBAQAAgISAy0CQBpM
IE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFy
Z2V0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAAICBRIDLQIICgwKBQQAAgIBEgMtCQ8KDAoF
BAACAgMSAy0SEwoMCgUEAAICCBIDLRQ/Cg8KCAQAAgIInAgAEgMtFT4KRwoEBAACAxIDMAI+
GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJh
dGlvbi4KCgwKBQQAAgMFEgMwAggKDAoFBAACAwESAzAJDQoMCgUEAAIDAxIDMBARCgwKBQQA
AgMIEgMwEj0KDwoIBAACAwicCAASAzATPArSAgoEBAACBBIDOAJOGsQCIE91dHB1dCBvbmx5
LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRp
b24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIGJlZW4gY2FuY2Vs
bGVkIHN1Y2Nlc3NmdWxseQogaGF2ZQogW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24u
ZXJyb3JdW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24uZXJyb3JdCiB2YWx1ZSB3aXRo
IGEgW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9m
IGAxYCwKIGNvcnJlc3BvbmRpbmcgdG8gYENvZGUuQ0FOQ0VMTEVEYC4KCgwKBQQAAgQFEgM4
AgYKDAoFBAACBAESAzgHHQoMCgUEAAIEAxIDOCAhCgwKBQQAAgQIEgM4Ik0KDwoIBAACBAic
CAASAzgjTApECgQEAAIFEgM7AkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNpb24gdXNlZCB0
byBzdGFydCB0aGUgb3BlcmF0aW9uLgoKDAoFBAACBQUSAzsCCAoMCgUEAAIFARIDOwkUCgwK
BQQAAgUDEgM7FxgKDAoFBAACBQgSAzsZRAoPCggEAAIFCJwIABIDOxpDCjYKBAQAAgYSAz4C
TRopIE91dHB1dCBvbmx5LiBQcm9ncmVzcyBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACBgYS
Az4CEwoMCgUEAAIGARIDPhQcCgwKBQQAAgYDEgM+HyAKDAoFBAACBggSAz4hTAoPCggEAAIG
CJwIABIDPiJLClsKAgQBEgRCAEUBGk8gTWVzc2FnZSBkZXNjcmliaW5nIHRoZSBwcm9ncmVz
cyBvZiBhIGNsdXN0ZXIgbXV0YXRpb24gbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQB
ARIDQggZCj4KBAQBAgASA0QCTxoxIE91dHB1dCBvbmx5LiBTdGVwcyBhbmQgc3RhdHVzIG9m
IHRoZSBvcGVyYXRpb24uCgoMCgUEAQIABBIDRAIKCgwKBQQBAgAGEgNECxgKDAoFBAECAAES
A0QZHgoMCgUEAQIAAxIDRCEiCgwKBQQBAgAIEgNEI04KDwoIBAECAAicCAASA0QkTQpsCgIE
AhIFSQDRAQEaXyBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIHN0YXR1cyBvZiBhIHNpbmdsZSBz
dGVwIGluIGEgY2x1c3RlciBtdXRhdGlvbgogbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoK
AwQCARIDSQgVCiwKBAQCBAASBEsCVwMaHiBTdGF0ZSBvZiB0aGUgb3BlcmF0aW9uIHN0ZXAu
CgoMCgUEAgQAARIDSwcMCiMKBgQCBAACABIDTQQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoO
CgcEAgQAAgABEgNNBBUKDgoHBAIEAAIAAhIDTRgZCjwKBgQCBAACARIDUAQQGi0gSW5pdGlh
bCBzdGF0ZSBiZWZvcmUgc3RlcCBleGVjdXRpb24gc3RhcnRzLgoKDgoHBAIEAAIBARIDUAQL
Cg4KBwQCBAACAQISA1AODwo3CgYEAgQAAgISA1MEFBooIFN0ZXAgZXhlY3V0aW9uIGlzIHJ1
bm5pbmcgaW4gcHJvZ3Jlc3MuCgoOCgcEAgQAAgIBEgNTBA8KDgoHBAIEAAICAhIDUxITCi0K
BgQCBAACAxIDVgQNGh4gU3RlcCBleGVjdXRpb24gaXMgY29tcGxldGVkLgoKDgoHBAIEAAID
ARIDVgQICg4KBwQCBAACAwISA1YLDAonCgQEAggAEgVaAs0BAxoYIFN0ZXAgb2YgdGhlIG9w
ZXJhdGlvbi4KCgwKBQQCCAABEgNaCAwKYwoEBAICABIEXQReNBpVIE91dHB1dCBvbmx5LiBJ
ZiBzZXQsIGluZGljYXRlcyB0aGF0IG5ldyBuZXR3b3JrIGNyZWF0aW9uIGlzIHBhcnQgb2Yg
dGhlCiBvcGVyYXRpb24uCgoMCgUEAgIABhIDXQQRCgwKBQQCAgABEgNdEiAKDAoFBAICAAMS
A10jJAoMCgUEAgIACBIDXggzCg8KCAQCAgAInAgAEgNeCTIKcgoEBAICARIEYgRjNBpkIE91
dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IG5ldyBwcml2YXRlIHNlcnZpY2Ug
YWNjZXNzIGNyZWF0aW9uCiBpcyBwYXJ0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAgIBBhID
YgQeCgwKBQQCAgEBEgNiHzwKDAoFBAICAQMSA2I/QAoMCgUEAgIBCBIDYwgzCg8KCAQCAgEI
nAgAEgNjCTIKbgoEBAICAhIEZwRoNBpgIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRl
cyB0aGF0IG5ldyBGaWxlc3RvcmUgaW5zdGFuY2UgY3JlYXRpb24gaXMKIHBhcnQgb2YgdGhl
IG9wZXJhdGlvbi4KCgwKBQQCAgIGEgNnBBsKDAoFBAICAgESA2ccNQoMCgUEAgICAxIDZzg5
CgwKBQQCAgIIEgNoCDMKDwoIBAICAgicCAASA2gJMgpwCgQEAgIDEgRsBG00GmIgT3V0cHV0
IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbmV3IENsb3VkIFN0b3JhZ2UgYnVja2V0
IGNyZWF0aW9uIGlzCiBwYXJ0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAgIDBhIDbAQXCgwK
BQQCAgMBEgNsGC0KDAoFBAICAwMSA2wwMQoMCgUEAgIDCBIDbQgzCg8KCAQCAgMInAgAEgNt
CTIKawoEBAICBBIEcQRyNBpdIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0
IG5ldyBMdXN0cmUgaW5zdGFuY2UgY3JlYXRpb24gaXMgcGFydAogb2YgdGhlIG9wZXJhdGlv
bi4KCgwKBQQCAgQGEgNxBBgKDAoFBAICBAESA3EZLwoMCgUEAgIEAxIDcTIzCgwKBQQCAgQI
EgNyCDMKDwoIBAICBAicCAASA3IJMgpkCgQEAgIFEgR2BHc0GlYgT3V0cHV0IG9ubHkuIElm
IHNldCwgaW5kaWNhdGVzIHRoYXQgb3JjaGVzdHJhdG9yIGNyZWF0aW9uIGlzIHBhcnQgb2Yg
dGhlCiBvcGVyYXRpb24uCgoMCgUEAgIFBhIDdgQWCgwKBQQCAgUBEgN2FyoKDAoFBAICBQMS
A3YtLgoMCgUEAgIFCBIDdwgzCg8KCAQCAgUInAgAEgN3CTIKYwoEBAICBhIEewR8NBpVIE91
dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IG5ldyBub2Rlc2V0IGNyZWF0aW9u
IGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoMCgUEAgIGBhIDewQRCgwKBQQCAgYBEgN7
EiAKDAoFBAICBgMSA3sjJAoMCgUEAgIGCBIDfAgzCg8KCAQCAgYInAgAEgN8CTIKZwoEBAIC
BxIGgAEEgQE0GlcgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbmV3IHBh
cnRpdGlvbiBjcmVhdGlvbiBpcyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICBwYS
BIABBBMKDQoFBAICBwESBIABFCQKDQoFBAICBwMSBIABJykKDQoFBAICBwgSBIEBCDMKEAoI
BAICBwicCAASBIEBCTIKaAoEBAICCBIGhQEEhgE0GlggT3V0cHV0IG9ubHkuIElmIHNldCwg
aW5kaWNhdGVzIHRoYXQgbmV3IGxvZ2luIG5vZGUgY3JlYXRpb24gaXMgcGFydCBvZgogdGhl
IG9wZXJhdGlvbi4KCg0KBQQCAggGEgSFAQQTCg0KBQQCAggBEgSFARQlCg0KBQQCAggDEgSF
ASgqCg0KBQQCAggIEgSGAQgzChAKCAQCAggInAgAEgSGAQkyCmUKBAQCAgkSBooBBIsBNBpV
IE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IGNsdXN0ZXIgaGVhbHRoIGNo
ZWNrIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoNCgUEAgIJBhIEigEEFgoNCgUEAgIJ
ARIEigEXKwoNCgUEAgIJAxIEigEuMAoNCgUEAgIJCBIEiwEIMwoQCggEAgIJCJwIABIEiwEJ
MgpnCgQEAgIKEgaPAQSQATQaVyBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhh
dCBhbiBvcmNoZXN0cmF0b3IgdXBkYXRlIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoN
CgUEAgIKBhIEjwEEFgoNCgUEAgIKARIEjwEXKgoNCgUEAgIKAxIEjwEtLwoNCgUEAgIKCBIE
kAEIMwoQCggEAgIKCJwIABIEkAEJMgpfCgQEAgILEgaUAQSVATQaTyBPdXRwdXQgb25seS4g
SWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBub2Rlc2V0IHVwZGF0ZSBpcyBwYXJ0IG9mIHRoZQog
b3BlcmF0aW9uLgoKDQoFBAICCwYSBJQBBBEKDQoFBAICCwESBJQBEiAKDQoFBAICCwMSBJQB
IyUKDQoFBAICCwgSBJUBCDMKEAoIBAICCwicCAASBJUBCTIKYQoEBAICDBIGmQEEmgE0GlEg
T3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgcGFydGl0aW9uIHVwZGF0ZSBp
cyBwYXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICDAYSBJkBBBMKDQoFBAICDAESBJkB
FCQKDQoFBAICDAMSBJkBJykKDQoFBAICDAgSBJoBCDMKEAoIBAICDAicCAASBJoBCTIKYgoE
BAICDRIGngEEnwE0GlIgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbG9n
aW4gbm9kZSB1cGRhdGUgaXMgcGFydCBvZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQCAg0GEgSe
AQQTCg0KBQQCAg0BEgSeARQlCg0KBQQCAg0DEgSeASgqCg0KBQQCAg0IEgSfAQgzChAKCAQC
Ag0InAgAEgSfAQkyCmYKBAQCAg4SBqMBBKQBNBpWIE91dHB1dCBvbmx5LiBJZiBzZXQsIGlu
ZGljYXRlcyB0aGF0IG9yY2hlc3RyYXRvciBkZWxldGlvbiBpcyBwYXJ0IG9mIHRoZQogb3Bl
cmF0aW9uLgoKDQoFBAICDgYSBKMBBBYKDQoFBAICDgESBKMBFyoKDQoFBAICDgMSBKMBLS8K
DQoFBAICDggSBKQBCDMKEAoIBAICDgicCAASBKQBCTIKYQoEBAICDxIGqAEEqQE0GlEgT3V0
cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgbm9kZXNldCBkZWxldGlvbiBpcyBw
YXJ0IG9mIHRoZQogb3BlcmF0aW9uLgoKDQoFBAICDwYSBKgBBBEKDQoFBAICDwESBKgBEiAK
DQoFBAICDwMSBKgBIyUKDQoFBAICDwgSBKkBCDMKEAoIBAICDwicCAASBKkBCTIKYwoEBAIC
EBIGrQEErgE0GlMgT3V0cHV0IG9ubHkuIElmIHNldCwgaW5kaWNhdGVzIHRoYXQgcGFydGl0
aW9uIGRlbGV0aW9uIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRpb24uCgoNCgUEAgIQBhIErQEE
EwoNCgUEAgIQARIErQEUJAoNCgUEAgIQAxIErQEnKQoNCgUEAgIQCBIErgEIMwoQCggEAgIQ
CJwIABIErgEJMgpkCgQEAgIREgayAQSzATQaVCBPdXRwdXQgb25seS4gSWYgc2V0LCBpbmRp
Y2F0ZXMgdGhhdCBsb2dpbiBub2RlIGRlbGV0aW9uIGlzIHBhcnQgb2YgdGhlCiBvcGVyYXRp
b24uCgoNCgUEAgIRBhIEsgEEEwoNCgUEAgIRARIEsgEUJQoNCgUEAgIRAxIEsgEoKgoNCgUE
AgIRCBIEswEIMwoQCggEAgIRCJwIABIEswEJMgpsCgQEAgISEga3AQS4ATQaXCBPdXRwdXQg
b25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBGaWxlc3RvcmUgaW5zdGFuY2UgZGVsZXRp
b24gaXMgcGFydAogb2YgdGhlIG9wZXJhdGlvbi4KCg0KBQQCAhIGEgS3AQQbCg0KBQQCAhIB
EgS3ARw1Cg0KBQQCAhIDEgS3ATg6Cg0KBQQCAhIIEgS4AQgzChAKCAQCAhIInAgAEgS4AQky
Cm4KBAQCAhMSBrwBBL0BNBpeIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0
IENsb3VkIFN0b3JhZ2UgYnVja2V0IGRlbGV0aW9uIGlzIHBhcnQKIG9mIHRoZSBvcGVyYXRp
b24uCgoNCgUEAgITBhIEvAEEFwoNCgUEAgITARIEvAEYLQoNCgUEAgITAxIEvAEwMgoNCgUE
AgITCBIEvQEIMwoQCggEAgITCJwIABIEvQEJMgppCgQEAgIUEgbBAQTCATQaWSBPdXRwdXQg
b25seS4gSWYgc2V0LCBpbmRpY2F0ZXMgdGhhdCBMdXN0cmUgaW5zdGFuY2UgZGVsZXRpb24g
aXMgcGFydCBvZgogdGhlIG9wZXJhdGlvbi4KCg0KBQQCAhQGEgTBAQQYCg0KBQQCAhQBEgTB
ARkvCg0KBQQCAhQDEgTBATI0Cg0KBQQCAhQIEgTCAQgzChAKCAQCAhQInAgAEgTCAQkyCnAK
BAQCAhUSBsYBBMcBNBpgIE91dHB1dCBvbmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IHBy
aXZhdGUgc2VydmljZSBhY2Nlc3MgZGVsZXRpb24gaXMKIHBhcnQgb2YgdGhlIG9wZXJhdGlv
bi4KCg0KBQQCAhUGEgTGAQQeCg0KBQQCAhUBEgTGAR88Cg0KBQQCAhUDEgTGAT9BCg0KBQQC
AhUIEgTHAQgzChAKCAQCAhUInAgAEgTHAQkyCmEKBAQCAhYSBssBBMwBNBpRIE91dHB1dCBv
bmx5LiBJZiBzZXQsIGluZGljYXRlcyB0aGF0IG5ldHdvcmsgZGVsZXRpb24gaXMgcGFydCBv
ZiB0aGUKIG9wZXJhdGlvbi4KCg0KBQQCAhYGEgTLAQQRCg0KBQQCAhYBEgTLARIgCg0KBQQC
AhYDEgTLASMlCg0KBQQCAhYIEgTMAQgzChAKCAQCAhYInAgAEgTMAQkyCjkKBAQCAhcSBNAB
Aj4aKyBPdXRwdXQgb25seS4gU3RhdGUgb2YgdGhlIG9wZXJhdGlvbiBzdGVwLgoKDQoFBAIC
FwYSBNABAgcKDQoFBAICFwESBNABCA0KDQoFBAICFwMSBNABEBEKDQoFBAICFwgSBNABEj0K
EAoIBAICFwicCAASBNABEzwKWgoCBAMSBtQBANsBARpMIFdoZW4gc2V0IGluIE9wZXJhdGlv
blN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbmV3IG5ldHdvcmsgc2hvdWxkIGJlIGNyZWF0ZWQu
CgoLCgMEAwESBNQBCBUKfAoEBAMCABIG1wEC2gEEGmwgT3V0cHV0IG9ubHkuIE5hbWUgb2Yg
dGhlIG5ldHdvcmsgdG8gY3JlYXRlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2pl
Y3R9L2dsb2JhbC9uZXR3b3Jrcy97bmV0d29ya31gLgoKDQoFBAMCAAUSBNcBAggKDQoFBAMC
AAESBNcBCRAKDQoFBAMCAAMSBNcBExQKDwoFBAMCAAgSBtcBFdoBAwoQCggEAwIACJwIABIE
2AEELQoPCgcEAwIACJ8IEgTZAQRQCmgKAgQEEgTfAQAlGlwgV2hlbiBzZXQgaW4gT3BlcmF0
aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBuZXcgcHJpdmF0ZSBzZXJ2aWNlIGFjY2VzcyBz
aG91bGQKIGJlIGNyZWF0ZWQuCgoLCgMEBAESBN8BCCIKZgoCBAUSBuMBAOwBARpYIFdoZW4g
c2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbmV3IGZpbGVzdG9yZSBp
bnN0YW5jZSBzaG91bGQgYmUKIGNyZWF0ZWQuCgoLCgMEBQESBOMBCB8KjAEKBAQFAgASBuYB
AusBBBp8IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBGaWxlc3RvcmUgaW5zdGFuY2UsIGlu
IHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
aW5zdGFuY2VzL3tpbnN0YW5jZX1gCgoNCgUEBQIABRIE5gECCAoNCgUEBQIAARIE5gEJEgoN
CgUEBQIAAxIE5gEVFgoPCgUEBQIACBIG5gEX6wEDChAKCAQFAgAInAgAEgTnAQQtChEKBwQF
AgAInwgSBugBBOoBBQpiCgIEBhIG8AEA9gEBGlQgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3Rl
cCwgaW5kaWNhdGVzIHRoYXQgYSBuZXcgc3RvcmFnZSBidWNrZXQgc2hvdWxkIGJlCiBjcmVh
dGVkLgoKCwoDBAYBEgTwAQgbCjIKBAQGAgASBvIBAvUBBBoiIE91dHB1dCBvbmx5LiBOYW1l
IG9mIHRoZSBidWNrZXQuCgoNCgUEBgIABRIE8gECCAoNCgUEBgIAARIE8gEJDwoNCgUEBgIA
AxIE8gESEwoPCgUEBgIACBIG8gEU9QEDChAKCAQGAgAInAgAEgTzAQQtCg8KBwQGAgAInwgS
BPQBBE8KYwoCBAcSBvoBAIECARpVIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGlj
YXRlcyB0aGF0IGEgbmV3IGx1c3RyZSBpbnN0YW5jZSBzaG91bGQgYmUKIGNyZWF0ZWQuCgoL
CgMEBwESBPoBCBwKkgEKBAQHAgASBv0BAoACBBqBASBPdXRwdXQgb25seS4gTmFtZSBvZiB0
aGUgTWFuYWdlZCBMdXN0cmUgaW5zdGFuY2UsIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX1gCgoN
CgUEBwIABRIE/QECCAoNCgUEBwIAARIE/QEJDwoNCgUEBwIAAxIE/QESEwoPCgUEBwIACBIG
/QEUgAIDChAKCAQHAgAInAgAEgT+AQQtCg8KBwQHAgAInwgSBP8BBFAKWgoCBAgSBIQCAB0a
TiBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhbiBvcmNoZXN0
cmF0b3Igc2hvdWxkIGJlIGNyZWF0ZWQuCgoLCgMECAESBIQCCBoKVgoCBAkSBocCAIoCARpI
IFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbm9kZXNldCBz
aG91bGQgYmUgY3JlYXRlZC4KCgsKAwQJARIEhwIIFQo6CgQECQIAEgSJAgJLGiwgT3V0cHV0
IG9ubHkuIE5hbWUgb2YgdGhlIG5vZGVzZXQgdG8gY3JlYXRlCgoNCgUECQIABBIEiQICCgoN
CgUECQIABRIEiQILEQoNCgUECQIAARIEiQISGgoNCgUECQIAAxIEiQIdHgoNCgUECQIACBIE
iQIfSgoQCggECQIACJwIABIEiQIgSQpYCgIEChIGjQIAkAIBGkogV2hlbiBzZXQgaW4gT3Bl
cmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBwYXJ0aXRpb24gc2hvdWxkIGJlIGNyZWF0
ZWQuCgoLCgMECgESBI0CCBcKPAoEBAoCABIEjwICTRouIE91dHB1dCBvbmx5LiBOYW1lIG9m
IHRoZSBwYXJ0aXRpb24gdG8gY3JlYXRlCgoNCgUECgIABBIEjwICCgoNCgUECgIABRIEjwIL
EQoNCgUECgIAARIEjwISHAoNCgUECgIAAxIEjwIfIAoNCgUECgIACBIEjwIhTAoQCggECgIA
CJwIABIEjwIiSwpXCgIECxIEkwIAGhpLIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGlu
ZGljYXRlcyB0aGF0IGEgbG9naW4gbm9kZSBzaG91bGQgYmUgY3JlYXRlZC4KCgsKAwQLARIE
kwIIFwpiCgIEDBIElwIAHRpWIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRl
cyB0aGF0IGNsdXN0ZXIgaGVhbHRoIGNoZWNrIHNob3VsZCBiZQogcGVyZm9ybWVkLgoKCwoD
BAwBEgSXAggaCloKAgQNEgSaAgAdGk4gV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5k
aWNhdGVzIHRoYXQgYW4gb3JjaGVzdHJhdG9yIHNob3VsZCBiZSB1cGRhdGVkLgoKCwoDBA0B
EgSaAggaClYKAgQOEgadAgCgAgEaSCBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRp
Y2F0ZXMgdGhhdCBhIG5vZGVzZXQgc2hvdWxkIGJlIHVwZGF0ZWQuCgoLCgMEDgESBJ0CCBUK
OgoEBA4CABIEnwICSxosIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBub2Rlc2V0IHRvIHVw
ZGF0ZQoKDQoFBA4CAAQSBJ8CAgoKDQoFBA4CAAUSBJ8CCxEKDQoFBA4CAAESBJ8CEhoKDQoF
BA4CAAMSBJ8CHR4KDQoFBA4CAAgSBJ8CH0oKEAoIBA4CAAicCAASBJ8CIEkKWAoCBA8SBqMC
AKYCARpKIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgcGFy
dGl0aW9uIHNob3VsZCBiZSB1cGRhdGVkLgoKCwoDBA8BEgSjAggXCjwKBAQPAgASBKUCAk0a
LiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgcGFydGl0aW9uIHRvIHVwZGF0ZQoKDQoFBA8C
AAQSBKUCAgoKDQoFBA8CAAUSBKUCCxEKDQoFBA8CAAESBKUCEhwKDQoFBA8CAAMSBKUCHyAK
DQoFBA8CAAgSBKUCIUwKEAoIBA8CAAicCAASBKUCIksKVwoCBBASBKkCABoaSyBXaGVuIHNl
dCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhIGxvZ2luIG5vZGUgc2hvdWxk
IGJlIHVwZGF0ZWQuCgoLCgMEEAESBKkCCBcKWgoCBBESBKwCAB0aTiBXaGVuIHNldCBpbiBP
cGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgdGhhdCBhbiBvcmNoZXN0cmF0b3Igc2hvdWxkIGJl
IGRlbGV0ZWQuCgoLCgMEEQESBKwCCBoKVgoCBBISBq8CALICARpIIFdoZW4gc2V0IGluIE9w
ZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEgbm9kZXNldCBzaG91bGQgYmUgZGVsZXRl
ZC4KCgsKAwQSARIErwIIFQo6CgQEEgIAEgSxAgJLGiwgT3V0cHV0IG9ubHkuIE5hbWUgb2Yg
dGhlIG5vZGVzZXQgdG8gZGVsZXRlCgoNCgUEEgIABBIEsQICCgoNCgUEEgIABRIEsQILEQoN
CgUEEgIAARIEsQISGgoNCgUEEgIAAxIEsQIdHgoNCgUEEgIACBIEsQIfSgoQCggEEgIACJwI
ABIEsQIgSQpYCgIEExIGtQIAuAIBGkogV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5k
aWNhdGVzIHRoYXQgYSBwYXJ0aXRpb24gc2hvdWxkIGJlIGRlbGV0ZWQuCgoLCgMEEwESBLUC
CBcKPAoEBBMCABIEtwICTRouIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBwYXJ0aXRpb24g
dG8gZGVsZXRlCgoNCgUEEwIABBIEtwICCgoNCgUEEwIABRIEtwILEQoNCgUEEwIAARIEtwIS
HAoNCgUEEwIAAxIEtwIfIAoNCgUEEwIACBIEtwIhTAoQCggEEwIACJwIABIEtwIiSwpXCgIE
FBIEuwIAGhpLIFdoZW4gc2V0IGluIE9wZXJhdGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IGEg
bG9naW4gbm9kZSBzaG91bGQgYmUgZGVsZXRlZC4KCgsKAwQUARIEuwIIFwpiCgIEFRIGvwIA
yAIBGlQgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIHRoYXQgYSBGaWxl
c3RvcmUgaW5zdGFuY2Ugc2hvdWxkIGJlCiBkZWxldGVkLgoKCwoDBBUBEgS/AggfCowBCgQE
FQIAEgbCAgLHAgQafCBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgRmlsZXN0b3JlIGluc3Rh
bmNlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBBUCAAUSBMICAggKDQoFBBUCAAES
BMICCRIKDQoFBBUCAAMSBMICFRYKDwoFBBUCAAgSBsICF8cCAwoQCggEFQIACJwIABIEwwIE
LQoRCgcEFQIACJ8IEgbEAgTGAgUKYgoCBBYSBswCANICARpUIFdoZW4gc2V0IGluIE9wZXJh
dGlvblN0ZXAsIGluZGljYXRlcyB0aGF0IENsb3VkIFN0b3JhZ2UgYnVja2V0IHNob3VsZCBi
ZQogZGVsZXRlZC4KCgsKAwQWARIEzAIIGwoyCgQEFgIAEgbOAgLRAgQaIiBPdXRwdXQgb25s
eS4gTmFtZSBvZiB0aGUgYnVja2V0LgoKDQoFBBYCAAUSBM4CAggKDQoFBBYCAAESBM4CCQ8K
DQoFBBYCAAMSBM4CEhMKDwoFBBYCAAgSBs4CFNECAwoQCggEFgIACJwIABIEzwIELQoPCgcE
FgIACJ8IEgTQAgRPCl8KAgQXEgbWAgDdAgEaUSBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVw
LCBpbmRpY2F0ZXMgdGhhdCBhIEx1c3RyZSBpbnN0YW5jZSBzaG91bGQgYmUKIGRlbGV0ZWQu
CgoLCgMEFwESBNYCCBwKkgEKBAQXAgASBtkCAtwCBBqBASBPdXRwdXQgb25seS4gTmFtZSBv
ZiB0aGUgTWFuYWdlZCBMdXN0cmUgaW5zdGFuY2UsIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX1g
CgoNCgUEFwIABRIE2QICCAoNCgUEFwIAARIE2QIJDwoNCgUEFwIAAxIE2QISEwoPCgUEFwIA
CBIG2QIU3AIDChAKCAQXAgAInAgAEgTaAgQtCg8KBwQXAgAInwgSBNsCBFAKWQoCBBgSBOEC
ACUaTSBXaGVuIHNldCBpbiBPcGVyYXRpb25TdGVwLCBpbmRpY2F0ZXMgcHJpdmF0ZSBzZXJ2
aWNlIGFjY2VzcyBkZWxldGlvbgogc3RlcC4KCgsKAwQYARIE4QIIIgpjCgIEGRIG5QIA7AIB
GlUgV2hlbiBzZXQgaW4gT3BlcmF0aW9uU3RlcCwgaW5kaWNhdGVzIG5ldHdvcmsgZGVsZXRp
b24gc3RlcCB3aXRoIHRoZQogcmVzb3VyY2UgbmFtZS4KCgsKAwQZARIE5QIIFQp8CgQEGQIA
EgboAgLrAgQabCBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgbmV0d29yayB0byBkZWxldGUs
IGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdH0vZ2xvYmFsL25ldHdvcmtzL3tu
ZXR3b3JrfWAuCgoNCgUEGQIABRIE6AICCAoNCgUEGQIAARIE6AIJEAoNCgUEGQIAAxIE6AIT
FAoPCgUEGQIACBIG6AIV6wIDChAKCAQZAgAInAgAEgTpAgQtCg8KBwQZAgAInwgSBOoCBFBi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: progress Type: 11 (.google.cloud.hypercomputecluster.v1beta.OperationProgress)

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationProgress ===
    # Fields for OperationProgress
    # Field: steps Type: 11 (.google.cloud.hypercomputecluster.v1beta.OperationStep)

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationStep ===
    # Fields for OperationStep
    # Field: create_network Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateNetwork)
    # Field: create_private_service_access Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreatePrivateServiceAccess)
    # Field: create_filestore_instance Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateFilestoreInstance)
    # Field: create_storage_bucket Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateStorageBucket)
    # Field: create_lustre_instance Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateLustreInstance)
    # Field: create_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateOrchestrator)
    # Field: create_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateNodeset)
    # Field: create_partition Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreatePartition)
    # Field: create_login_node Type: 11 (.google.cloud.hypercomputecluster.v1beta.CreateLoginNode)
    # Field: check_cluster_health Type: 11 (.google.cloud.hypercomputecluster.v1beta.CheckClusterHealth)
    # Field: update_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1beta.UpdateOrchestrator)
    # Field: update_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1beta.UpdateNodeset)
    # Field: update_partition Type: 11 (.google.cloud.hypercomputecluster.v1beta.UpdatePartition)
    # Field: update_login_node Type: 11 (.google.cloud.hypercomputecluster.v1beta.UpdateLoginNode)
    # Field: delete_orchestrator Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteOrchestrator)
    # Field: delete_nodeset Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteNodeset)
    # Field: delete_partition Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeletePartition)
    # Field: delete_login_node Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteLoginNode)
    # Field: delete_filestore_instance Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteFilestoreInstance)
    # Field: delete_storage_bucket Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteStorageBucket)
    # Field: delete_lustre_instance Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteLustreInstance)
    # Field: delete_private_service_access Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeletePrivateServiceAccess)
    # Field: delete_network Type: 11 (.google.cloud.hypercomputecluster.v1beta.DeleteNetwork)
    # Field: state Type: 14 (.google.cloud.hypercomputecluster.v1beta.OperationStep.State)

# Enum: OperationStep::State
our $OperationStep_STATE_UNSPECIFIED = 0;
our $OperationStep_WAITING = 1;
our $OperationStep_IN_PROGRESS = 2;
our $OperationStep_DONE = 3;

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateNetwork ===
    # Fields for CreateNetwork
    # Field: network Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreatePrivateServiceAccess ===
    # Fields for CreatePrivateServiceAccess

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateFilestoreInstance ===
    # Fields for CreateFilestoreInstance
    # Field: filestore Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateStorageBucket ===
    # Fields for CreateStorageBucket
    # Field: bucket Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateLustreInstance ===
    # Fields for CreateLustreInstance
    # Field: lustre Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateOrchestrator ===
    # Fields for CreateOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateNodeset ===
    # Fields for CreateNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreatePartition ===
    # Fields for CreatePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateLoginNode ===
    # Fields for CreateLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CheckClusterHealth ===
    # Fields for CheckClusterHealth

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateOrchestrator ===
    # Fields for UpdateOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateNodeset ===
    # Fields for UpdateNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdatePartition ===
    # Fields for UpdatePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateLoginNode ===
    # Fields for UpdateLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteOrchestrator ===
    # Fields for DeleteOrchestrator

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteNodeset ===
    # Fields for DeleteNodeset
    # Field: nodesets Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeletePartition ===
    # Fields for DeletePartition
    # Field: partitions Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteLoginNode ===
    # Fields for DeleteLoginNode

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteFilestoreInstance ===
    # Fields for DeleteFilestoreInstance
    # Field: filestore Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteStorageBucket ===
    # Fields for DeleteStorageBucket
    # Field: bucket Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteLustreInstance ===
    # Fields for DeleteLustreInstance
    # Field: lustre Type: 9 ()

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeletePrivateServiceAccess ===
    # Fields for DeletePrivateServiceAccess

# === Message: Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteNetwork ===
    # Fields for DeleteNetwork
    # Field: network Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata - Compiled Protocol Buffers messages for google/cloud/hypercomputecluster/v1beta/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata;

    my $msg = Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/hypercomputecluster/v1beta/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of `1`,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=item * C<< $msg->progress() >> / C<< $msg->progress($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationProgress>)

Output only. Progress of the operation.

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationProgress

Message describing the progress of a cluster mutation long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->steps() >> / C<< $msg->steps($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationStep>)

Output only. Steps and status of the operation.

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::OperationStep

Message describing the status of a single step in a cluster mutation
long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_network() >> / C<< $msg->create_network($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateNetwork>)

Output only. If set, indicates that new network creation is part of the
operation.

=item * C<< $msg->create_private_service_access() >> / C<< $msg->create_private_service_access($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreatePrivateServiceAccess>)

Output only. If set, indicates that new private service access creation
is part of the operation.

=item * C<< $msg->create_filestore_instance() >> / C<< $msg->create_filestore_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateFilestoreInstance>)

Output only. If set, indicates that new Filestore instance creation is
part of the operation.

=item * C<< $msg->create_storage_bucket() >> / C<< $msg->create_storage_bucket($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateStorageBucket>)

Output only. If set, indicates that new Cloud Storage bucket creation is
part of the operation.

=item * C<< $msg->create_lustre_instance() >> / C<< $msg->create_lustre_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateLustreInstance>)

Output only. If set, indicates that new Lustre instance creation is part
of the operation.

=item * C<< $msg->create_orchestrator() >> / C<< $msg->create_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateOrchestrator>)

Output only. If set, indicates that orchestrator creation is part of the
operation.

=item * C<< $msg->create_nodeset() >> / C<< $msg->create_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateNodeset>)

Output only. If set, indicates that new nodeset creation is part of the
operation.

=item * C<< $msg->create_partition() >> / C<< $msg->create_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreatePartition>)

Output only. If set, indicates that new partition creation is part of the
operation.

=item * C<< $msg->create_login_node() >> / C<< $msg->create_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateLoginNode>)

Output only. If set, indicates that new login node creation is part of
the operation.

=item * C<< $msg->check_cluster_health() >> / C<< $msg->check_cluster_health($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CheckClusterHealth>)

Output only. If set, indicates that cluster health check is part of the
operation.

=item * C<< $msg->update_orchestrator() >> / C<< $msg->update_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateOrchestrator>)

Output only. If set, indicates that an orchestrator update is part of the
operation.

=item * C<< $msg->update_nodeset() >> / C<< $msg->update_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateNodeset>)

Output only. If set, indicates that nodeset update is part of the
operation.

=item * C<< $msg->update_partition() >> / C<< $msg->update_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdatePartition>)

Output only. If set, indicates that partition update is part of the
operation.

=item * C<< $msg->update_login_node() >> / C<< $msg->update_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateLoginNode>)

Output only. If set, indicates that login node update is part of the
operation.

=item * C<< $msg->delete_orchestrator() >> / C<< $msg->delete_orchestrator($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteOrchestrator>)

Output only. If set, indicates that orchestrator deletion is part of the
operation.

=item * C<< $msg->delete_nodeset() >> / C<< $msg->delete_nodeset($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteNodeset>)

Output only. If set, indicates that nodeset deletion is part of the
operation.

=item * C<< $msg->delete_partition() >> / C<< $msg->delete_partition($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeletePartition>)

Output only. If set, indicates that partition deletion is part of the
operation.

=item * C<< $msg->delete_login_node() >> / C<< $msg->delete_login_node($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteLoginNode>)

Output only. If set, indicates that login node deletion is part of the
operation.

=item * C<< $msg->delete_filestore_instance() >> / C<< $msg->delete_filestore_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteFilestoreInstance>)

Output only. If set, indicates that Filestore instance deletion is part
of the operation.

=item * C<< $msg->delete_storage_bucket() >> / C<< $msg->delete_storage_bucket($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteStorageBucket>)

Output only. If set, indicates that Cloud Storage bucket deletion is part
of the operation.

=item * C<< $msg->delete_lustre_instance() >> / C<< $msg->delete_lustre_instance($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteLustreInstance>)

Output only. If set, indicates that Lustre instance deletion is part of
the operation.

=item * C<< $msg->delete_private_service_access() >> / C<< $msg->delete_private_service_access($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeletePrivateServiceAccess>)

Output only. If set, indicates that private service access deletion is
part of the operation.

=item * C<< $msg->delete_network() >> / C<< $msg->delete_network($value) >>

Type: C<Message> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteNetwork>)

Output only. If set, indicates that network deletion is part of the
operation.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Hypercomputecluster::V1beta::OperationStep::State>)

Output only. State of the operation step.

=back

=head3 Enum: OperationStep::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<WAITING> => C<1>

=item * C<IN_PROGRESS> => C<2>

=item * C<DONE> => C<3>

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateNetwork

When set in OperationStep, indicates that a new network should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Output only. Name of the network to create, in the format
`projects/{project}/global/networks/{network}`.

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreatePrivateServiceAccess

When set in OperationStep, indicates that a new private service access should
be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateFilestoreInstance

When set in OperationStep, indicates that a new filestore instance should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filestore() >> / C<< $msg->filestore($value) >>

Type: C<String>

Output only. Name of the Filestore instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateStorageBucket

When set in OperationStep, indicates that a new storage bucket should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Name of the bucket.

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateLustreInstance

When set in OperationStep, indicates that a new lustre instance should be
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lustre() >> / C<< $msg->lustre($value) >>

Type: C<String>

Output only. Name of the Managed Lustre instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateOrchestrator

When set in OperationStep, indicates that an orchestrator should be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateNodeset

When set in OperationStep, indicates that a nodeset should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to create

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreatePartition

When set in OperationStep, indicates that a partition should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to create

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CreateLoginNode

When set in OperationStep, indicates that a login node should be created.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::CheckClusterHealth

When set in OperationStep, indicates that cluster health check should be
performed.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateOrchestrator

When set in OperationStep, indicates that an orchestrator should be updated.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateNodeset

When set in OperationStep, indicates that a nodeset should be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to update

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdatePartition

When set in OperationStep, indicates that a partition should be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to update

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::UpdateLoginNode

When set in OperationStep, indicates that a login node should be updated.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteOrchestrator

When set in OperationStep, indicates that an orchestrator should be deleted.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteNodeset

When set in OperationStep, indicates that a nodeset should be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodesets() >> / C<< $msg->nodesets($value) >>

Type: C<String>

Output only. Name of the nodeset to delete

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeletePartition

When set in OperationStep, indicates that a partition should be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<String>

Output only. Name of the partition to delete

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteLoginNode

When set in OperationStep, indicates that a login node should be deleted.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteFilestoreInstance

When set in OperationStep, indicates that a Filestore instance should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->filestore() >> / C<< $msg->filestore($value) >>

Type: C<String>

Output only. Name of the Filestore instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteStorageBucket

When set in OperationStep, indicates that Cloud Storage bucket should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Name of the bucket.

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteLustreInstance

When set in OperationStep, indicates that a Lustre instance should be
deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lustre() >> / C<< $msg->lustre($value) >>

Type: C<String>

Output only. Name of the Managed Lustre instance, in the format
`projects/{project}/locations/{location}/instances/{instance}`

=back

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeletePrivateServiceAccess

When set in OperationStep, indicates private service access deletion
step.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::DeleteNetwork

When set in OperationStep, indicates network deletion step with the
resource name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Output only. Name of the network to delete, in the format
`projects/{project}/global/networks/{network}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Hypercomputecluster::V1beta::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
