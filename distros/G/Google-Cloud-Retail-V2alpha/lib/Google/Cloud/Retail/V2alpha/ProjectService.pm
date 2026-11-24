package Google::Cloud::Retail::V2alpha::ProjectService;

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
    eval { require Google::Cloud::Retail::V2alpha::Common };
    eval { require Google::Cloud::Retail::V2alpha::Project };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvcHJvamVjdF9zZXJ2aWNlLnByb3RvEhtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvcmV0YWls
L3YyYWxwaGEvY29tbW9uLnByb3RvGilnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvcHJv
amVjdC5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aIGdvb2ds
ZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIlQKEUdldFByb2plY3RSZXF1ZXN0Ej8KBG5h
bWUYASABKAlCK+BBAvpBJQojcmV0YWlsLmdvb2dsZWFwaXMuY29tL1JldGFpbFByb2plY3RS
BG5hbWUiWwoSQWNjZXB0VGVybXNSZXF1ZXN0EkUKB3Byb2plY3QYASABKAlCK+BBAvpBJQoj
cmV0YWlsLmdvb2dsZWFwaXMuY29tL1JldGFpbFByb2plY3RSB3Byb2plY3QisgEKFUVucm9s
bFNvbHV0aW9uUmVxdWVzdBJNCgdwcm9qZWN0GAEgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3Vy
Y2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2plY3RSB3Byb2plY3QSSgoIc29sdXRpb24Y
AiABKA4yKS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlQgPgQQJS
CHNvbHV0aW9uInAKFkVucm9sbFNvbHV0aW9uUmVzcG9uc2USVgoRZW5yb2xsZWRfc29sdXRp
b24YASABKA4yKS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlUhBl
bnJvbGxlZFNvbHV0aW9uIhgKFkVucm9sbFNvbHV0aW9uTWV0YWRhdGEiawocTGlzdEVucm9s
bGVkU29sdXRpb25zUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNv
dXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFIGcGFyZW50InkKHUxpc3RFbnJv
bGxlZFNvbHV0aW9uc1Jlc3BvbnNlElgKEmVucm9sbGVkX3NvbHV0aW9ucxgBIAMoDjIpLmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Tb2x1dGlvblR5cGVSEWVucm9sbGVkU29sdXRp
b25zIloKF0dldExvZ2dpbmdDb25maWdSZXF1ZXN0Ej8KBG5hbWUYASABKAlCK+BBAvpBJQoj
cmV0YWlsLmdvb2dsZWFwaXMuY29tL0xvZ2dpbmdDb25maWdSBG5hbWUisQEKGlVwZGF0ZUxv
Z2dpbmdDb25maWdSZXF1ZXN0ElYKDmxvZ2dpbmdfY29uZmlnGAEgASgLMiouZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhLkxvZ2dpbmdDb25maWdCA+BBAlINbG9nZ2luZ0NvbmZpZxI7
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0
ZU1hc2siVgoVR2V0QWxlcnRDb25maWdSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwoh
cmV0YWlsLmdvb2dsZWFwaXMuY29tL0FsZXJ0Q29uZmlnUgRuYW1lIqkBChhVcGRhdGVBbGVy
dENvbmZpZ1JlcXVlc3QSUAoMYWxlcnRfY29uZmlnGAEgASgLMiguZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLkFsZXJ0Q29uZmlnQgPgQQJSC2FsZXJ0Q29uZmlnEjsKC3VwZGF0ZV9t
YXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzazKrDQoO
UHJvamVjdFNlcnZpY2USmwEKCkdldFByb2plY3QSLi5nb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuR2V0UHJvamVjdFJlcXVlc3QaJC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEu
UHJvamVjdCI3gtPkkwIqEigvdjJhbHBoYS97bmFtZT1wcm9qZWN0cy8qL3JldGFpbFByb2pl
Y3R92kEEbmFtZRKyAQoLQWNjZXB0VGVybXMSLy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxw
aGEuQWNjZXB0VGVybXNSZXF1ZXN0GiQuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlBy
b2plY3QiTILT5JMCPCI3L3YyYWxwaGEve3Byb2plY3Q9cHJvamVjdHMvKi9yZXRhaWxQcm9q
ZWN0fTphY2NlcHRUZXJtczoBKtpBB3Byb2plY3QSiAIKDkVucm9sbFNvbHV0aW9uEjIuZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkVucm9sbFNvbHV0aW9uUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24iogGC0+STAjEiLC92MmFscGhhL3twcm9qZWN0PXBy
b2plY3RzLyp9OmVucm9sbFNvbHV0aW9uOgEqykFoCjJnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuRW5yb2xsU29sdXRpb25SZXNwb25zZRIyZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkVucm9sbFNvbHV0aW9uTWV0YWRhdGESzwEKFUxpc3RFbnJvbGxlZFNvbHV0aW9ucxI5
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5MaXN0RW5yb2xsZWRTb2x1dGlvbnNSZXF1
ZXN0GjouZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxpc3RFbnJvbGxlZFNvbHV0aW9u
c1Jlc3BvbnNlIj+C0+STAjASLi92MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKn06ZW5yb2xs
ZWRTb2x1dGlvbnPaQQZwYXJlbnQSrQEKEEdldExvZ2dpbmdDb25maWcSNC5nb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuR2V0TG9nZ2luZ0NvbmZpZ1JlcXVlc3QaKi5nb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZyI3gtPkkwIqEigvdjJhbHBoYS97bmFt
ZT1wcm9qZWN0cy8qL2xvZ2dpbmdDb25maWd92kEEbmFtZRLoAQoTVXBkYXRlTG9nZ2luZ0Nv
bmZpZxI3Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5VcGRhdGVMb2dnaW5nQ29uZmln
UmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Mb2dnaW5nQ29uZmlnImyC
0+STAkkyNy92MmFscGhhL3tsb2dnaW5nX2NvbmZpZy5uYW1lPXByb2plY3RzLyovbG9nZ2lu
Z0NvbmZpZ306DmxvZ2dpbmdfY29uZmln2kEabG9nZ2luZ19jb25maWcsdXBkYXRlX21hc2sS
pQEKDkdldEFsZXJ0Q29uZmlnEjIuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkdldEFs
ZXJ0Q29uZmlnUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5BbGVydENv
bmZpZyI1gtPkkwIoEiYvdjJhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2FsZXJ0Q29uZmlnfdpB
BG5hbWUS2gEKEVVwZGF0ZUFsZXJ0Q29uZmlnEjUuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLlVwZGF0ZUFsZXJ0Q29uZmlnUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5BbGVydENvbmZpZyJkgtPkkwJDMjMvdjJhbHBoYS97YWxlcnRfY29uZmlnLm5hbWU9
cHJvamVjdHMvKi9hbGVydENvbmZpZ306DGFsZXJ0X2NvbmZpZ9pBGGFsZXJ0X2NvbmZpZyx1
cGRhdGVfbWFzaxpJykEVcmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULXAQofY29tLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYUITUHJvamVjdFNlcnZpY2VQcm90b1ABWjdjbG91ZC5nb29nbGUuY29t
L2dvL3JldGFpbC9hcGl2MmFscGhhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIbR29v
Z2xlLkNsb3VkLlJldGFpbC5WMkFscGhhygIbR29vZ2xlXENsb3VkXFJldGFpbFxWMmFscGhh
6gIeR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMmFscGhhSpQ6CgcSBQ4AkAIBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACYKCQoCAwES
AxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAMgoJCgIDBRIDFwAzCgkKAgMG
EgMYAC0KCQoCAwcSAxkAKgoICgEIEgMbADgKCQoCCCUSAxsAOAoICgEIEgMcAE4KCQoCCAsS
AxwATgoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADQKCQoCCAgSAx4ANAoICgEIEgMf
ADgKCQoCCAESAx8AOAoICgEIEgMgACQKCQoCCCQSAyAAJAoICgEIEgMhADgKCQoCCCkSAyEA
OAoICgEIEgMiADcKCQoCCC0SAyIANwo1CgIGABIFJQCCAQEaKCBTZXJ2aWNlIGZvciBzZXR0
aW5ncyBhdCBQcm9qZWN0IGxldmVsLgoKCgoDBgABEgMlCBYKCgoDBgADEgMmAj0KDAoFBgAD
mQgSAyYCPQoLCgMGAAMSBCcCKDcKDQoFBgADmggSBCcCKDcKdQoEBgACABIELgIzAxpnIEdl
dHMgdGhlIHByb2plY3QuCgogVGhyb3dzIGBOT1RfRk9VTkRgIGlmIHRoZSBwcm9qZWN0IHdh
c24ndCBpbml0aWFsaXplZCBmb3IgdGhlIFJldGFpbCBBUEkKIHNlcnZpY2UuCgoMCgUGAAIA
ARIDLgYQCgwKBQYAAgACEgMuESIKDAoFBgACAAMSAy4tNAoNCgUGAAIABBIELwQxBgoRCgkG
AAIABLDKvCISBC8EMQYKDAoFBgACAAQSAzIEMgoPCggGAAIABJsIABIDMgQyCroBCgQGAAIB
EgQ5Aj8DGqsBIEFjY2VwdHMgc2VydmljZSB0ZXJtcyBmb3IgdGhpcyBwcm9qZWN0LgogQnkg
bWFraW5nIHJlcXVlc3RzIHRvIHRoaXMgQVBJLCB5b3UgYWdyZWUgdG8gdGhlIHRlcm1zIG9m
IHNlcnZpY2UgbGlua2VkCiBiZWxvdy4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXRh
aWwvZGF0YS11c2UtdGVybXMKCgwKBQYAAgEBEgM5BhEKDAoFBgACAQISAzkSJAoMCgUGAAIB
AxIDOS82Cg0KBQYAAgEEEgQ6BD0GChEKCQYAAgEEsMq8IhIEOgQ9BgoMCgUGAAIBBBIDPgQ1
Cg8KCAYAAgEEmwgAEgM+BDUKkAMKBAYAAgISBEkCUwMagQMgVGhlIG1ldGhvZCBlbnJvbGxz
IGEgc29sdXRpb24gb2YgdHlwZSBbUmV0YWlsCiBTZWFyY2hdW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJhbHBoYS5Tb2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdCiBpbnRvIGEg
cHJvamVjdC4KCiBUaGUgW1JlY29tbWVuZGF0aW9ucyBBSSBzb2x1dGlvbgogdHlwZV1bZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1JF
Q09NTUVOREFUSU9OXQogaXMgZW5yb2xsZWQgYnkgZGVmYXVsdCB3aGVuIHlvdXIgcHJvamVj
dCBlbmFibGVzIFJldGFpbCBBUEksIHNvIHlvdSBkb24ndAogbmVlZCB0byBjYWxsIHRoZSBl
bnJvbGxTb2x1dGlvbiBtZXRob2QgZm9yIHJlY29tbWVuZGF0aW9ucy4KCgwKBQYAAgIBEgNJ
BhQKDAoFBgACAgISA0kVKgoMCgUGAAICAxIDSg8rCg0KBQYAAgIEEgRLBE4GChEKCQYAAgIE
sMq8IhIESwROBgoNCgUGAAICBBIETwRSBgoPCgcGAAICBJkIEgRPBFIGCkwKBAYAAgMSBFYC
XAMaPiBMaXN0cyBhbGwgdGhlIHJldGFpbCBBUEkgc29sdXRpb25zIHRoZSBwcm9qZWN0IGhh
cyBlbnJvbGxlZC4KCgwKBQYAAgMBEgNWBhsKDAoFBgACAwISA1YcOAoMCgUGAAIDAxIDVw8s
Cg0KBQYAAgMEEgRYBFoGChEKCQYAAgMEsMq8IhIEWARaBgoMCgUGAAIDBBIDWwQ0Cg8KCAYA
AgMEmwgAEgNbBDQKbgoEBgACBBIEYAJlAxpgIEdldHMgdGhlIFtMb2dnaW5nQ29uZmlnXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZ10gb2YgdGhlCiByZXF1
ZXN0ZWQgcHJvamVjdC4KCgwKBQYAAgQBEgNgBhYKDAoFBgACBAISA2AXLgoMCgUGAAIEAxID
YDlGCg0KBQYAAgQEEgRhBGMGChEKCQYAAgQEsMq8IhIEYQRjBgoMCgUGAAIEBBIDZAQyCg8K
CAYAAgQEmwgAEgNkBDIKcQoEBgACBRIEaQJvAxpjIFVwZGF0ZXMgdGhlIFtMb2dnaW5nQ29u
ZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZ10gb2YKIHRo
ZSByZXF1ZXN0ZWQgcHJvamVjdC4KCgwKBQYAAgUBEgNpBhkKDAoFBgACBQISA2kaNAoMCgUG
AAIFAxIDaT9MCg0KBQYAAgUEEgRqBG0GChEKCQYAAgUEsMq8IhIEagRtBgoMCgUGAAIFBBID
bgRICg8KCAYAAgUEmwgAEgNuBEgKaQoEBgACBhIEcwJ4AxpbIEdldCB0aGUgW0FsZXJ0Q29u
ZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQWxlcnRDb25maWddIG9mIHRoZQog
cmVxdWVzdGVkIHByb2plY3QuCgoMCgUGAAIGARIDcwYUCgwKBQYAAgYCEgNzFSoKDAoFBgAC
BgMSA3M1QAoNCgUGAAIGBBIEdAR2BgoRCgkGAAIGBLDKvCISBHQEdgYKDAoFBgACBgQSA3cE
MgoPCggGAAIGBJsIABIDdwQyCkIKBAYAAgcSBXsCgQEDGjMgVXBkYXRlIHRoZSBhbGVydCBj
b25maWcgb2YgdGhlIHJlcXVlc3RlZCBwcm9qZWN0LgoKDAoFBgACBwESA3sGFwoMCgUGAAIH
AhIDexgwCgwKBQYAAgcDEgN7O0YKDQoFBgACBwQSBHwEfwYKEQoJBgACBwSwyrwiEgR8BH8G
Cg0KBQYAAgcEEgSAAQRGChAKCAYAAgcEmwgAEgSAAQRGCi4KAgQAEgaFAQCOAQEaICBSZXF1
ZXN0IGZvciBHZXRQcm9qZWN0IG1ldGhvZC4KCgsKAwQAARIEhQEIGQp3CgQEAAIAEgaIAQKN
AQQaZyBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9qZWN0LiBGb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyX29yX2lkfS9yZXRhaWxQcm9qZWN0YAoK
DQoFBAACAAUSBIgBAggKDQoFBAACAAESBIgBCQ0KDQoFBAACAAMSBIgBEBEKDwoFBAACAAgS
BogBEo0BAwoQCggEAAIACJwIABIEiQEEKgoRCgcEAAIACJ8IEgaKAQSMAQUKLwoCBAESBpEB
AJoBARohIFJlcXVlc3QgZm9yIEFjY2VwdFRlcm1zIG1ldGhvZC4KCgsKAwQBARIEkQEIGgp3
CgQEAQIAEgaUAQKZAQQaZyBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBw
cm9qZWN0LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyX29yX2lkfS9yZXRh
aWxQcm9qZWN0YAoKDQoFBAECAAUSBJQBAggKDQoFBAECAAESBJQBCRAKDQoFBAECAAMSBJQB
ExQKDwoFBAECAAgSBpQBFZkBAwoQCggEAQIACJwIABIElQEEKgoRCgcEAQIACJ8IEgaWAQSY
AQUKMgoCBAISBp0BAKkBARokIFJlcXVlc3QgZm9yIEVucm9sbFNvbHV0aW9uIG1ldGhvZC4K
CgsKAwQCARIEnQEIHQpkCgQEAgIAEgagAQKlAQQaVCBSZXF1aXJlZC4gRnVsbCByZXNvdXJj
ZSBuYW1lIG9mIHBhcmVudC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcl9v
cl9pZH1gCgoNCgUEAgIABRIEoAECCAoNCgUEAgIAARIEoAEJEAoNCgUEAgIAAxIEoAETFAoP
CgUEAgIACBIGoAEVpQEDChAKCAQCAgAInAgAEgShAQQqChEKBwQCAgAInwgSBqIBBKQBBQot
CgQEAgIBEgSoAQJFGh8gUmVxdWlyZWQuIFNvbHV0aW9uIHRvIGVucm9sbC4KCg0KBQQCAgEG
EgSoAQIOCg0KBQQCAgEBEgSoAQ8XCg0KBQQCAgEDEgSoARobCg0KBQQCAgEIEgSoARxEChAK
CAQCAgEInAgAEgSoAR1DCjMKAgQDEgasAQCvAQEaJSBSZXNwb25zZSBmb3IgRW5yb2xsU29s
dXRpb24gbWV0aG9kLgoKCwoDBAMBEgSsAQgeCkIKBAQDAgASBK4BAiUaNCBSZXRhaWwgQVBJ
IHNvbHV0aW9uIHRoYXQgdGhlIHByb2plY3QgaGFzIGVucm9sbGVkLgoKDQoFBAMCAAYSBK4B
Ag4KDQoFBAMCAAESBK4BDyAKDQoFBAMCAAMSBK4BIyQKhwEKAgQEEgSzAQAhGnsgTWV0YWRh
dGEgcmVsYXRlZCB0byB0aGUgRW5yb2xsU29sdXRpb24gbWV0aG9kLgogVGhpcyB3aWxsIGJl
IHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRh
IGZpZWxkLgoKCwoDBAQBEgSzAQgeCjkKAgQFEga2AQC/AQEaKyBSZXF1ZXN0IGZvciBMaXN0
RW5yb2xsZWRTb2x1dGlvbnMgbWV0aG9kLgoKCwoDBAUBEgS2AQgkCmQKBAQFAgASBrkBAr4B
BBpUIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgcGFyZW50LiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyX29yX2lkfWAKCg0KBQQFAgAFEgS5AQIICg0KBQQF
AgABEgS5AQkPCg0KBQQFAgADEgS5ARITCg8KBQQFAgAIEga5ARS+AQMKEAoIBAUCAAicCAAS
BLoBBCoKEQoHBAUCAAifCBIGuwEEvQEFCjoKAgQGEgbCAQDFAQEaLCBSZXNwb25zZSBmb3Ig
TGlzdEVucm9sbGVkU29sdXRpb25zIG1ldGhvZC4KCgsKAwQGARIEwgEIJQpDCgQEBgIAEgTE
AQIvGjUgUmV0YWlsIEFQSSBzb2x1dGlvbnMgdGhhdCB0aGUgcHJvamVjdCBoYXMgZW5yb2xs
ZWQuCgoNCgUEBgIABBIExAECCgoNCgUEBgIABhIExAELFwoNCgUEBgIAARIExAEYKgoNCgUE
BgIAAxIExAEtLgqEAQoCBAcSBsoBANMBARp2IFJlcXVlc3QgZm9yCiBbUHJvamVjdFNlcnZp
Y2UuR2V0TG9nZ2luZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlByb2pl
Y3RTZXJ2aWNlLkdldExvZ2dpbmdDb25maWddCiBtZXRob2QuCgoLCgMEBwESBMoBCB8KbgoE
BAcCABIGzQEC0gEEGl4gUmVxdWlyZWQuIEZ1bGwgTG9nZ2luZ0NvbmZpZyByZXNvdXJjZSBu
YW1lLiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvZ2dpbmdDb25maWcK
Cg0KBQQHAgAFEgTNAQIICg0KBQQHAgABEgTNAQkNCg0KBQQHAgADEgTNARARCg8KBQQHAgAI
EgbNARLSAQMKEAoIBAcCAAicCAASBM4BBCoKEQoHBAcCAAifCBIGzwEE0QEFCooBCgIECBIG
2AEA7QEBGnwgUmVxdWVzdCBmb3IKIFtQcm9qZWN0U2VydmljZS5VcGRhdGVMb2dnaW5nQ29u
ZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUHJvamVjdFNlcnZpY2UuVXBkYXRl
TG9nZ2luZ0NvbmZpZ10KIG1ldGhvZC4KCgsKAwQIARIE2AEIIgqEAwoEBAgCABIE4gECTBr1
AiBSZXF1aXJlZC4gVGhlIFtMb2dnaW5nQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuTG9nZ2luZ0NvbmZpZ10gdG8KIHVwZGF0ZS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMg
bm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBbTG9nZ2luZ0NvbmZpZ11bZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxvZ2dpbmdDb25maWddLCB0aGVuIGEKIFBFUk1J
U1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRoZSBbTG9nZ2luZ0NvbmZp
Z11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkxvZ2dpbmdDb25maWddIHRvIHVwZGF0
ZQogZG9lcyBub3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJldHVybmVkLgoKDQoF
BAgCAAYSBOIBAg8KDQoFBAgCAAESBOIBEB4KDQoFBAgCAAMSBOIBISIKDQoFBAgCAAgSBOIB
I0sKEAoIBAgCAAicCAASBOIBJEoKywMKBAQIAgESBOwBAiwavAMgSW5kaWNhdGVzIHdoaWNo
IGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtMb2dnaW5nQ29uZmlnXVtnb29nbGUuY2xvdWQu
cmV0YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZ10gdG8gdXBkYXRlLiBUaGUKIGZvbGxvd2lu
ZyBhcmUgdGhlIG9ubHkgc3VwcG9ydGVkIGZpZWxkczoKCiAqIFtMb2dnaW5nQ29uZmlnLmRl
ZmF1bHRfbG9nX2dlbmVyYXRpb25fcnVsZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhh
LkxvZ2dpbmdDb25maWcuZGVmYXVsdF9sb2dfZ2VuZXJhdGlvbl9ydWxlXQogKiBbTG9nZ2lu
Z0NvbmZpZy5zZXJ2aWNlX2xvZ19nZW5lcmF0aW9uX3J1bGVzXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuTG9nZ2luZ0NvbmZpZy5zZXJ2aWNlX2xvZ19nZW5lcmF0aW9uX3J1bGVz
XQoKIElmIG5vdCBzZXQsIGFsbCBzdXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoF
BAgCAQYSBOwBAhsKDQoFBAgCAQESBOwBHCcKDQoFBAgCAQMSBOwBKisKgAEKAgQJEgbyAQD7
AQEaciBSZXF1ZXN0IGZvcgogW1Byb2plY3RTZXJ2aWNlLkdldEFsZXJ0Q29uZmlnXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUHJvamVjdFNlcnZpY2UuR2V0QWxlcnRDb25maWdd
CiBtZXRob2QuCgoLCgMECQESBPIBCB0KagoEBAkCABIG9QEC+gEEGlogUmVxdWlyZWQuIEZ1
bGwgQWxlcnRDb25maWcgcmVzb3VyY2UgbmFtZS4gRm9ybWF0OgogcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9hbGVydENvbmZpZwoKDQoFBAkCAAUSBPUBAggKDQoFBAkCAAESBPUBCQ0K
DQoFBAkCAAMSBPUBEBEKDwoFBAkCAAgSBvUBEvoBAwoQCggECQIACJwIABIE9gEEKgoRCgcE
CQIACJ8IEgb3AQT5AQUKhgEKAgQKEgaAAgCQAgEaeCBSZXF1ZXN0IGZvcgogW1Byb2plY3RT
ZXJ2aWNlLlVwZGF0ZUFsZXJ0Q29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEu
UHJvamVjdFNlcnZpY2UuVXBkYXRlQWxlcnRDb25maWddCiBtZXRob2QuCgoLCgMECgESBIAC
CCAK+AIKBAQKAgASBIoCAkga6QIgUmVxdWlyZWQuIFRoZSBbQWxlcnRDb25maWddW2dvb2ds
ZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5BbGVydENvbmZpZ10gdG8KIHVwZGF0ZS4KCiBJZiB0
aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBbQWxl
cnRDb25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5BbGVydENvbmZpZ10sIHRo
ZW4gYQogUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIFtB
bGVydENvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkFsZXJ0Q29uZmlnXSB0
byB1cGRhdGUKIGRvZXMgbm90IGV4aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5l
ZC4KCg0KBQQKAgAGEgSKAgINCg0KBQQKAgABEgSKAg4aCg0KBQQKAgADEgSKAh0eCg0KBQQK
AgAIEgSKAh9HChAKCAQKAgAInAgAEgSKAiBGCqkBCgQECgIBEgSPAgIsGpoBIEluZGljYXRl
cyB3aGljaCBmaWVsZHMgaW4gdGhlIHByb3ZpZGVkCiBbQWxlcnRDb25maWddW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJhbHBoYS5BbGVydENvbmZpZ10gdG8gdXBkYXRlLiBJZiBub3QKIHNl
dCwgYWxsIHN1cHBvcnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoNCgUECgIBBhIEjwICGwoN
CgUECgIBARIEjwIcJwoNCgUECgIBAxIEjwIqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest ===
    # Fields for GetProjectRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::AcceptTermsRequest ===
    # Fields for AcceptTermsRequest
    # Field: project Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest ===
    # Fields for EnrollSolutionRequest
    # Field: project Type: 9 ()
    # Field: solution Type: 14 (.google.cloud.retail.v2alpha.SolutionType)

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionResponse ===
    # Fields for EnrollSolutionResponse
    # Field: enrolled_solution Type: 14 (.google.cloud.retail.v2alpha.SolutionType)

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionMetadata ===
    # Fields for EnrollSolutionMetadata

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsRequest ===
    # Fields for ListEnrolledSolutionsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsResponse ===
    # Fields for ListEnrolledSolutionsResponse
    # Field: enrolled_solutions Type: 14 (.google.cloud.retail.v2alpha.SolutionType)

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::GetLoggingConfigRequest ===
    # Fields for GetLoggingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest ===
    # Fields for UpdateLoggingConfigRequest
    # Field: logging_config Type: 11 (.google.cloud.retail.v2alpha.LoggingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::GetAlertConfigRequest ===
    # Fields for GetAlertConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest ===
    # Fields for UpdateAlertConfigRequest
    # Field: alert_config Type: 11 (.google.cloud.retail.v2alpha.AlertConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Retail::V2alpha::ProjectService::ProjectServiceClient ===
package Google::Cloud::Retail::V2alpha::ProjectService::ProjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::ProjectService::ProjectServiceClient

Client stub representing the remote C<ProjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub get_project {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'GetProject',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Project::Project',
    });
}

sub accept_terms {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::AcceptTermsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'AcceptTerms',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Project::Project',
    });
}

sub enroll_solution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'EnrollSolution',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_enrolled_solutions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'ListEnrolledSolutions',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsResponse',
    });
}

sub get_logging_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::GetLoggingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'GetLoggingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig',
    });
}

sub update_logging_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'UpdateLoggingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig',
    });
}

sub get_alert_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::GetAlertConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'GetAlertConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Project::AlertConfig',
    });
}

sub update_alert_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ProjectService',
        method         => 'UpdateAlertConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Project::AlertConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::ProjectService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/project_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::ProjectService;

    my $msg = Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/project_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest

Request for GetProject method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of the project. Format:
`projects/{project_number_or_id}/retailProject`

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::AcceptTermsRequest

Request for AcceptTerms method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Full resource name of the project. Format:
`projects/{project_number_or_id}/retailProject`

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest

Request for EnrollSolution method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project_number_or_id}`

=item * C<< $msg->solution() >> / C<< $msg->solution($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SolutionType>)

Required. Solution to enroll.

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionResponse

Response for EnrollSolution method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enrolled_solution() >> / C<< $msg->enrolled_solution($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SolutionType>)

Retail API solution that the project has enrolled.

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionMetadata

Metadata related to the EnrollSolution method.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsRequest

Request for ListEnrolledSolutions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project_number_or_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsResponse

Response for ListEnrolledSolutions method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enrolled_solutions() >> / C<< $msg->enrolled_solutions($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SolutionType>)

Retail API solutions that the project has enrolled.

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::GetLoggingConfigRequest

Request for
[ProjectService.GetLoggingConfig][google.cloud.retail.v2alpha.ProjectService.GetLoggingConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full LoggingConfig resource name. Format:
projects/{project_number}/loggingConfig

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest

Request for
[ProjectService.UpdateLoggingConfig][google.cloud.retail.v2alpha.ProjectService.UpdateLoggingConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->logging_config() >> / C<< $msg->logging_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Project::LoggingConfig>)

Required. The [LoggingConfig][google.cloud.retail.v2alpha.LoggingConfig] to
update.

If the caller does not have permission to update the
[LoggingConfig][google.cloud.retail.v2alpha.LoggingConfig], then a
PERMISSION_DENIED error is returned.

If the [LoggingConfig][google.cloud.retail.v2alpha.LoggingConfig] to update
does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[LoggingConfig][google.cloud.retail.v2alpha.LoggingConfig] to update. The
following are the only supported fields:

* [LoggingConfig.default_log_generation_rule][google.cloud.retail.v2alpha.LoggingConfig.default_log_generation_rule]
* [LoggingConfig.service_log_generation_rules][google.cloud.retail.v2alpha.LoggingConfig.service_log_generation_rules]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::GetAlertConfigRequest

Request for
[ProjectService.GetAlertConfig][google.cloud.retail.v2alpha.ProjectService.GetAlertConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full AlertConfig resource name. Format:
projects/{project_number}/alertConfig

=back

=head2 Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest

Request for
[ProjectService.UpdateAlertConfig][google.cloud.retail.v2alpha.ProjectService.UpdateAlertConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alert_config() >> / C<< $msg->alert_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Project::AlertConfig>)

Required. The [AlertConfig][google.cloud.retail.v2alpha.AlertConfig] to
update.

If the caller does not have permission to update the
[AlertConfig][google.cloud.retail.v2alpha.AlertConfig], then a
PERMISSION_DENIED error is returned.

If the [AlertConfig][google.cloud.retail.v2alpha.AlertConfig] to update
does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[AlertConfig][google.cloud.retail.v2alpha.AlertConfig] to update. If not
set, all supported fields are updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::ProjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
