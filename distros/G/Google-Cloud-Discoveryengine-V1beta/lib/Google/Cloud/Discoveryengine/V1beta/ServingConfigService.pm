package Google::Cloud::Discoveryengine::V1beta::ServingConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::ServingConfig };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zZXJ2aW5nX2NvbmZpZ19z
ZXJ2aWNlLnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aOGdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL3NlcnZpbmdfY29uZmln
LnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9m
aWVsZF9tYXNrLnByb3RvIvsBChpDcmVhdGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBJMCgZwYXJl
bnQYASABKAlCNOBBAvpBLhIsZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NlcnZp
bmdDb25maWdSBnBhcmVudBJeCg5zZXJ2aW5nX2NvbmZpZxgCIAEoCzIyLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNlcnZpbmdDb25maWdCA+BBAlINc2VydmluZ0Nv
bmZpZxIvChFzZXJ2aW5nX2NvbmZpZ19pZBgDIAEoCUID4EECUg9zZXJ2aW5nQ29uZmlnSWQi
uQEKGlVwZGF0ZVNlcnZpbmdDb25maWdSZXF1ZXN0El4KDnNlcnZpbmdfY29uZmlnGAEgASgL
MjIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2VydmluZ0NvbmZpZ0ID
4EECUg1zZXJ2aW5nQ29uZmlnEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJmChpEZWxldGVTZXJ2aW5nQ29uZmlnUmVxdWVz
dBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9TZXJ2aW5nQ29uZmlnUgRuYW1lImMKF0dldFNlcnZpbmdDb25maWdSZXF1ZXN0EkgKBG5h
bWUYASABKAlCNOBBAvpBLgosZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NlcnZp
bmdDb25maWdSBG5hbWUirwEKGUxpc3RTZXJ2aW5nQ29uZmlnc1JlcXVlc3QSTAoGcGFyZW50
GAEgASgJQjTgQQL6QS4SLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TZXJ2aW5n
Q29uZmlnUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBh
Z2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIqEBChpMaXN0U2VydmluZ0NvbmZpZ3NS
ZXNwb25zZRJbCg9zZXJ2aW5nX2NvbmZpZ3MYASADKAsyMi5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5TZXJ2aW5nQ29uZmlnUg5zZXJ2aW5nQ29uZmlncxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4yyxIKFFNlcnZpbmdDb25maWdTZXJ2
aWNlEtoDChNDcmVhdGVTZXJ2aW5nQ29uZmlnEj8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuQ3JlYXRlU2VydmluZ0NvbmZpZ1JlcXVlc3QaMi5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZXJ2aW5nQ29uZmlnIs0CgtPkkwKcAiJDL3YxYmV0
YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qfS9zZXJ2aW5n
Q29uZmlnczoOc2VydmluZ19jb25maWdaYyJRL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3NlcnZpbmdDb25maWdz
Og5zZXJ2aW5nX2NvbmZpZ1pgIk4vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn0vc2VydmluZ0NvbmZpZ3M6DnNlcnZpbmdf
Y29uZmln2kEncGFyZW50LHNlcnZpbmdfY29uZmlnLHNlcnZpbmdfY29uZmlnX2lkEusCChNE
ZWxldGVTZXJ2aW5nQ29uZmlnEj8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuRGVsZXRlU2VydmluZ0NvbmZpZ1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHki
+gGC0+STAuwBKkMvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0
b3Jlcy8qL3NlcnZpbmdDb25maWdzLyp9WlMqUS92MWJldGEve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8q
fVpQKk4vdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMv
Ki9lbmdpbmVzLyovc2VydmluZ0NvbmZpZ3MvKn3aQQRuYW1lEvoDChNVcGRhdGVTZXJ2aW5n
Q29uZmlnEj8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVXBkYXRlU2Vy
dmluZ0NvbmZpZ1JlcXVlc3QaMi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TZXJ2aW5nQ29uZmlnIu0CgtPkkwLJAjJSL3YxYmV0YS97c2VydmluZ19jb25maWcubmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8q
fToOc2VydmluZ19jb25maWdacjJgL3YxYmV0YS97c2VydmluZ19jb25maWcubmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3NlcnZpbmdD
b25maWdzLyp9Og5zZXJ2aW5nX2NvbmZpZ1pvMl0vdjFiZXRhL3tzZXJ2aW5nX2NvbmZpZy5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovc2Vy
dmluZ0NvbmZpZ3MvKn06DnNlcnZpbmdfY29uZmln2kEac2VydmluZ19jb25maWcsdXBkYXRl
X21hc2sSgQMKEEdldFNlcnZpbmdDb25maWcSPC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5HZXRTZXJ2aW5nQ29uZmlnUmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLlNlcnZpbmdDb25maWci+gGC0+STAuwBEkMvdjFiZXRhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3NlcnZpbmdDb25maWdz
Lyp9WlMSUS92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9u
cy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8qfVpQEk4vdjFiZXRhL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovc2VydmluZ0Nv
bmZpZ3MvKn3aQQRuYW1lEpQDChJMaXN0U2VydmluZ0NvbmZpZ3MSPi5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0U2VydmluZ0NvbmZpZ3NSZXF1ZXN0Gj8uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdFNlcnZpbmdDb25maWdzUmVz
cG9uc2Ui/AGC0+STAuwBEkMvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9kYXRhU3RvcmVzLyp9L3NlcnZpbmdDb25maWdzWlMSUS92MWJldGEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfS9zZXJ2aW5n
Q29uZmlnc1pQEk4vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xs
ZWN0aW9ucy8qL2VuZ2luZXMvKn0vc2VydmluZ0NvbmZpZ3PaQQZwYXJlbnQazwHKQR5kaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCoAIKJ2NvbS5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIZU2VydmluZ0NvbmZpZ1NlcnZpY2VQcm90
b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlz
Y292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNH
b29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNj
b3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpW
MWJldGFKrisKBxIFDgDjAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACwKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJ
CgIDBBIDFgBCCgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMaAEAKCQoCCCUSAxoAQAoI
CgEIEgMbAGgKCQoCCAsSAxsAaAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADoKCQoC
CAgSAx0AOgoICgEIEgMeAEAKCQoCCAESAx4AQAoICgEIEgMfAC0KCQoCCCQSAx8ALQoICgEI
EgMgAEAKCQoCCCkSAyAAQAoICgEIEgMhAD8KCQoCCC0SAyEAPwp1CgIGABIFJQCIAQEaaCBT
ZXJ2aWNlIGZvciBvcGVyYXRpb25zIHJlbGF0ZWQgdG8KIFtTZXJ2aW5nQ29uZmlnXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZXJ2aW5nQ29uZmlnXS4KCgoKAwYA
ARIDJQgcCgoKAwYAAxIDJgJGCgwKBQYAA5kIEgMmAkYKCwoDBgADEgQnAipKCg0KBQYAA5oI
EgQnAipKCpIDCgQGAAIAEgQ1AkQDGoMDIENyZWF0ZXMgYSBTZXJ2aW5nQ29uZmlnLgoKIE5v
dGU6IFRoZSBHb29nbGUgQ2xvdWQgY29uc29sZSB3b3JrcyBvbmx5IHdpdGggdGhlIGRlZmF1
bHQgc2VydmluZyBjb25maWcuCiBBZGRpdGlvbmFsIFNlcnZpbmdDb25maWdzIGNhbiBiZSBj
cmVhdGVkIGFuZCBtYW5hZ2VkIG9ubHkgdmlhIHRoZSBBUEkuCgogQSBtYXhpbXVtIG9mIDEw
MAogW1NlcnZpbmdDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LlNlcnZpbmdDb25maWddcyBhcmUKIGFsbG93ZWQgaW4gYW4gW0VuZ2luZV1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRW5naW5lXSwKIG90aGVyd2lzZSBhIFJFU09V
UkNFX0VYSEFVU1RFRCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgABEgM1BhkKDAoFBgAC
AAISAzUaNAoMCgUGAAIAAxIDNT9MCg0KBQYAAgAEEgQ2BEEGChEKCQYAAgAEsMq8IhIENgRB
BgoNCgUGAAIABBIEQgRDMgoQCggGAAIABJsIABIEQgRDMgppCgQGAAIBEgRJAlUDGlsgRGVs
ZXRlcyBhIFNlcnZpbmdDb25maWcuCgogUmV0dXJucyBhIE5PVF9GT1VORCBlcnJvciBpZiB0
aGUgU2VydmluZ0NvbmZpZyBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgEBEgNJBhkKDAoFBgAC
AQISA0kaNAoMCgUGAAIBAxIDSg8kCg0KBQYAAgEEEgRLBFMGChEKCQYAAgEEsMq8IhIESwRT
BgoMCgUGAAIBBBIDVAQyCg8KCAYAAgEEmwgAEgNUBDIKaQoEBgACAhIEWgJoAxpbIFVwZGF0
ZXMgYSBTZXJ2aW5nQ29uZmlnLgoKIFJldHVybnMgYSBOT1RfRk9VTkQgZXJyb3IgaWYgdGhl
IFNlcnZpbmdDb25maWcgZG9lcyBub3QgZXhpc3QuCgoMCgUGAAICARIDWgYZCgwKBQYAAgIC
EgNaGjQKDAoFBgACAgMSA1o/TAoNCgUGAAICBBIEWwRmBgoRCgkGAAICBLDKvCISBFsEZgYK
DAoFBgACAgQSA2cESAoPCggGAAICBJsIABIDZwRICmUKBAYAAgMSBG0CeAMaVyBHZXRzIGEg
U2VydmluZ0NvbmZpZy4KCiBSZXR1cm5zIGEgTm90Rm91bmQgZXJyb3IgaWYgdGhlIFNlcnZp
bmdDb25maWcgZG9lcyBub3QgZXhpc3QuCgoMCgUGAAIDARIDbQYWCgwKBQYAAgMCEgNtFy4K
DAoFBgACAwMSA205RgoNCgUGAAIDBBIEbgR2BgoRCgkGAAIDBLDKvCISBG4EdgYKDAoFBgAC
AwQSA3cEMgoPCggGAAIDBJsIABIDdwQyCkMKBAYAAgQSBXsChwEDGjQgTGlzdHMgYWxsIFNl
cnZpbmdDb25maWdzIGxpbmtlZCB0byB0aGlzIGRhdGFTdG9yZS4KCgwKBQYAAgQBEgN7BhgK
DAoFBgACBAISA3sZMgoMCgUGAAIEAxIDfA8pCg4KBQYAAgQEEgV9BIUBBgoSCgkGAAIEBLDK
vCISBX0EhQEGCg0KBQYAAgQEEgSGAQQ0ChAKCAYAAgQEmwgAEgSGAQQ0CjcKAgQAEgaLAQCe
AQEaKSBSZXF1ZXN0IGZvciBDcmVhdGVTZXJ2aW5nQ29uZmlnIG1ldGhvZC4KCgsKAwQAARIE
iwEIIgqXAQoEBAACABIGjgECkwEEGoYBIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUg
b2YgcGFyZW50LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdpbmV9YAoKDQoF
BAACAAUSBI4BAggKDQoFBAACAAESBI4BCQ8KDQoFBAACAAMSBI4BEhMKDwoFBAACAAgSBo4B
FJMBAwoQCggEAAIACJwIABIEjwEEKgoRCgcEAAIACJ8IEgaQAQSSAQUKNgoEBAACARIElgEC
TBooIFJlcXVpcmVkLiBUaGUgU2VydmluZ0NvbmZpZyB0byBjcmVhdGUuCgoNCgUEAAIBBhIE
lgECDwoNCgUEAAIBARIElgEQHgoNCgUEAAIBAxIElgEhIgoNCgUEAAIBCBIElgEjSwoQCggE
AAIBCJwIABIElgEkSgrrAQoEBAACAhIEnQECSBrcASBSZXF1aXJlZC4gVGhlIElEIHRvIHVz
ZSBmb3IgdGhlIFNlcnZpbmdDb25maWcsIHdoaWNoIHdpbGwgYmVjb21lIHRoZSBmaW5hbAog
Y29tcG9uZW50IG9mIHRoZSBTZXJ2aW5nQ29uZmlnJ3MgcmVzb3VyY2UgbmFtZS4KCiBUaGlz
IHZhbHVlIHNob3VsZCBiZSA0LTYzIGNoYXJhY3RlcnMsIGFuZCB2YWxpZCBjaGFyYWN0ZXJz
CiBhcmUgL1thLXpBLVowLTldW2EtekEtWjAtOV8tXSsvLgoKDQoFBAACAgUSBJ0BAggKDQoF
BAACAgESBJ0BCRoKDQoFBAACAgMSBJ0BHR4KDQoFBAACAggSBJ0BH0cKEAoIBAACAgicCAAS
BJ0BIEYKNwoCBAESBqEBAK0BARopIFJlcXVlc3QgZm9yIFVwZGF0ZVNlcnZpbmdDb25maWcg
bWV0aG9kLgoKCwoDBAEBEgShAQgiCjYKBAQBAgASBKMBAkwaKCBSZXF1aXJlZC4gVGhlIFNl
cnZpbmdDb25maWcgdG8gdXBkYXRlLgoKDQoFBAECAAYSBKMBAg8KDQoFBAECAAESBKMBEB4K
DQoFBAECAAMSBKMBISIKDQoFBAECAAgSBKMBI0sKEAoIBAECAAicCAASBKMBJEoKqQIKBAQB
AgESBKwBAiwamgIgSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtT
ZXJ2aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZXJ2
aW5nQ29uZmlnXSB0bwogdXBkYXRlLiBUaGUgZm9sbG93aW5nIGFyZSBOT1Qgc3VwcG9ydGVk
OgoKICogW1NlcnZpbmdDb25maWcubmFtZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuU2VydmluZ0NvbmZpZy5uYW1lXQoKIElmIG5vdCBzZXQsIGFsbCBzdXBwb3J0
ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoFBAECAQYSBKwBAhsKDQoFBAECAQESBKwBHCcK
DQoFBAECAQMSBKwBKisKNwoCBAISBrABALkBARopIFJlcXVlc3QgZm9yIERlbGV0ZVNlcnZp
bmdDb25maWcgbWV0aG9kLgoKCwoDBAIBEgSwAQgiCs4BCgQEAgIAEgazAQK4AQQavQEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTZXJ2aW5nQ29uZmlnIHRvIGRlbGV0
ZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5naW5lfS9zZXJ2aW5nQ29uZmln
cy97c2VydmluZ19jb25maWdfaWR9YAoKDQoFBAICAAUSBLMBAggKDQoFBAICAAESBLMBCQ0K
DQoFBAICAAMSBLMBEBEKDwoFBAICAAgSBrMBErgBAwoQCggEAgIACJwIABIEtAEEKgoRCgcE
AgIACJ8IEga1AQS3AQUKNAoCBAMSBrwBAMUBARomIFJlcXVlc3QgZm9yIEdldFNlcnZpbmdD
b25maWcgbWV0aG9kLgoKCwoDBAMBEgS8AQgfCssBCgQEAwIAEga/AQLEAQQaugEgUmVxdWly
ZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTZXJ2aW5nQ29uZmlnIHRvIGdldC4gRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0
aW9ucy97Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5naW5lfS9zZXJ2aW5nQ29uZmlncy97c2Vy
dmluZ19jb25maWdfaWR9YAoKDQoFBAMCAAUSBL8BAggKDQoFBAMCAAESBL8BCQ0KDQoFBAMC
AAMSBL8BEBEKDwoFBAMCAAgSBr8BEsQBAwoQCggEAwIACJwIABIEwAEEKgoRCgcEAwIACJ8I
EgbBAQTDAQUKNgoCBAQSBsgBANoBARooIFJlcXVlc3QgZm9yIExpc3RTZXJ2aW5nQ29uZmln
cyBtZXRob2QuCgoLCgMEBAESBMgBCCEKpAEKBAQEAgASBssBAtABBBqTASBSZXF1aXJlZC4g
RnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXJlbnQgcmVzb3VyY2UuIEZvcm1hdDoKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2Nv
bGxlY3Rpb259L2VuZ2luZXMve2VuZ2luZX1gCgoNCgUEBAIABRIEywECCAoNCgUEBAIAARIE
ywEJDwoNCgUEBAIAAxIEywESEwoPCgUEBAIACBIGywEU0AEDChAKCAQEAgAInAgAEgTMAQQq
ChEKBwQEAgAInwgSBs0BBM8BBQqtAQoEBAQCARIE1QECPxqeASBPcHRpb25hbC4gTWF4aW11
bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0
cwogdG8gMTAwLiBJZiBhIHZhbHVlIGdyZWF0ZXIgdGhhbiAxMDAgaXMgcHJvdmlkZWQsIGF0
IG1vc3QgMTAwIHJlc3VsdHMgYXJlCiByZXR1cm5lZC4KCg0KBQQEAgEFEgTVAQIHCg0KBQQE
AgEBEgTVAQgRCg0KBQQEAgEDEgTVARQVCg0KBQQEAgEIEgTVARY+ChAKCAQEAgEInAgAEgTV
ARc9CooBCgQEBAICEgTZAQJBGnwgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQg
ZnJvbSBhIHByZXZpb3VzIGBMaXN0U2VydmluZ0NvbmZpZ3NgIGNhbGwuCiBQcm92aWRlIHRo
aXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQEAgIFEgTZAQIICg0K
BQQEAgIBEgTZAQkTCg0KBQQEAgIDEgTZARYXCg0KBQQEAgIIEgTZARhAChAKCAQEAgIInAgA
EgTZARk/CjcKAgQFEgbdAQDjAQEaKSBSZXNwb25zZSBmb3IgTGlzdFNlcnZpbmdDb25maWdz
IG1ldGhvZC4KCgsKAwQFARIE3QEIIgo9CgQEBQIAEgTfAQItGi8gQWxsIHRoZSBTZXJ2aW5n
Q29uZmlncyBmb3IgYSBnaXZlbiBkYXRhU3RvcmUuCgoNCgUEBQIABBIE3wECCgoNCgUEBQIA
BhIE3wELGAoNCgUEBQIAARIE3wEZKAoNCgUEBQIAAxIE3wErLApKCgQEBQIBEgTiAQIdGjwg
UGFnaW5hdGlvbiB0b2tlbiwgaWYgbm90IHJldHVybmVkIGluZGljYXRlcyB0aGUgbGFzdCBw
YWdlLgoKDQoFBAUCAQUSBOIBAggKDQoFBAUCAQESBOIBCRgKDQoFBAUCAQMSBOIBGxxiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest ===
    # Fields for CreateServingConfigRequest
    # Field: parent Type: 9 ()
    # Field: serving_config Type: 11 (.google.cloud.discoveryengine.v1beta.ServingConfig)
    # Field: serving_config_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::UpdateServingConfigRequest ===
    # Fields for UpdateServingConfigRequest
    # Field: serving_config Type: 11 (.google.cloud.discoveryengine.v1beta.ServingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::DeleteServingConfigRequest ===
    # Fields for DeleteServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::GetServingConfigRequest ===
    # Fields for GetServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ListServingConfigsRequest ===
    # Fields for ListServingConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ListServingConfigsResponse ===
    # Fields for ListServingConfigsResponse
    # Field: serving_configs Type: 11 (.google.cloud.discoveryengine.v1beta.ServingConfig)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ServingConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ServingConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ServingConfigServiceClient

Client stub representing the remote C<ServingConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub create_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig',
    });
}

sub delete_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ServingConfigService::DeleteServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ServingConfigService',
        method         => 'DeleteServingConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ServingConfigService::UpdateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig',
    });
}

sub get_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ServingConfigService::GetServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ServingConfigService',
        method         => 'GetServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig',
    });
}

sub list_serving_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ListServingConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ServingConfigService',
        method         => 'ListServingConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ListServingConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::ServingConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/serving_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::ServingConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest->new({
        parent => $parent,
        serving_config => $serving_config,
        serving_config_id => $serving_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/serving_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest

Request for CreateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}`

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig>)

Required. The ServingConfig to create.

=item * C<< $msg->serving_config_id() >> / C<< $msg->serving_config_id($value) >>

Type: C<String>

Required. The ID to use for the ServingConfig, which will become the final
component of the ServingConfig's resource name.

This value should be 4-63 characters, and valid characters
are /[a-zA-Z0-9][a-zA-Z0-9_-]+/.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ServingConfigService::UpdateServingConfigRequest

Request for UpdateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig>)

Required. The ServingConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[ServingConfig][google.cloud.discoveryengine.v1beta.ServingConfig] to
update. The following are NOT supported:

* [ServingConfig.name][google.cloud.discoveryengine.v1beta.ServingConfig.name]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ServingConfigService::DeleteServingConfigRequest

Request for DeleteServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to delete. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ServingConfigService::GetServingConfigRequest

Request for GetServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to get. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ListServingConfigsRequest

Request for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of the parent resource. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 100. If a value greater than 100 is provided, at most 100 results are
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListServingConfigs` call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ServingConfigService::ListServingConfigsResponse

Response for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_configs() >> / C<< $msg->serving_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig>)

All the ServingConfigs for a given dataStore.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::ServingConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
