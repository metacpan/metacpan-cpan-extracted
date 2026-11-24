package Google::Cloud::Discoveryengine::V1::ServingConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1::ServingConfig };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NlcnZpbmdfY29uZmlnX3NlcnZp
Y2UucHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRnb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NlcnZpbmdfY29uZmlnLnByb3RvGhtnb29n
bGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvIvcBChpDcmVhdGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBJMCgZwYXJlbnQYASABKAlCNOBB
AvpBLhIsZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NlcnZpbmdDb25maWdSBnBh
cmVudBJaCg5zZXJ2aW5nX2NvbmZpZxgCIAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuU2VydmluZ0NvbmZpZ0ID4EECUg1zZXJ2aW5nQ29uZmlnEi8KEXNlcnZpbmdf
Y29uZmlnX2lkGAMgASgJQgPgQQJSD3NlcnZpbmdDb25maWdJZCK1AQoaVXBkYXRlU2Vydmlu
Z0NvbmZpZ1JlcXVlc3QSWgoOc2VydmluZ19jb25maWcYASABKAsyLi5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLlNlcnZpbmdDb25maWdCA+BBAlINc2VydmluZ0NvbmZpZxI7
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0
ZU1hc2siZgoaRGVsZXRlU2VydmluZ0NvbmZpZ1JlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC
+kEuCixkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZ1IEbmFt
ZSJjChdHZXRTZXJ2aW5nQ29uZmlnUmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGRp
c2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TZXJ2aW5nQ29uZmlnUgRuYW1lIq8BChlM
aXN0U2VydmluZ0NvbmZpZ3NSZXF1ZXN0EkwKBnBhcmVudBgBIAEoCUI04EEC+kEuEixkaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZ1IGcGFyZW50EiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbiKdAQoaTGlzdFNlcnZpbmdDb25maWdzUmVzcG9uc2USVwoPc2VydmluZ19j
b25maWdzGAEgAygLMi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TZXJ2aW5n
Q29uZmlnUg5zZXJ2aW5nQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4y6xEKFFNlcnZpbmdDb25maWdTZXJ2aWNlEsYDChNDcmVhdGVTZXJ2aW5nQ29u
ZmlnEjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DcmVhdGVTZXJ2aW5nQ29u
ZmlnUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2VydmluZ0Nv
bmZpZyLBAoLT5JMCkAIiPy92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0
YVN0b3Jlcy8qfS9zZXJ2aW5nQ29uZmlnczoOc2VydmluZ19jb25maWdaXyJNL3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0v
c2VydmluZ0NvbmZpZ3M6DnNlcnZpbmdfY29uZmlnWlwiSi92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyp9L3NlcnZpbmdDb25maWdz
Og5zZXJ2aW5nX2NvbmZpZ9pBJ3BhcmVudCxzZXJ2aW5nX2NvbmZpZyxzZXJ2aW5nX2NvbmZp
Z19pZBLbAgoTRGVsZXRlU2VydmluZ0NvbmZpZxI7Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuRGVsZXRlU2VydmluZ0NvbmZpZ1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHki7gGC0+STAuABKj8vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRh
U3RvcmVzLyovc2VydmluZ0NvbmZpZ3MvKn1aTypNL3YxL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2VydmluZ0NvbmZpZ3MvKn1a
TCpKL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdp
bmVzLyovc2VydmluZ0NvbmZpZ3MvKn3aQQRuYW1lEuYDChNVcGRhdGVTZXJ2aW5nQ29uZmln
EjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5VcGRhdGVTZXJ2aW5nQ29uZmln
UmVxdWVzdBouLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2VydmluZ0NvbmZp
ZyLhAoLT5JMCvQIyTi92MS97c2VydmluZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8qfToOc2VydmluZ19jb25maWda
bjJcL3YxL3tzZXJ2aW5nX2NvbmZpZy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29s
bGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2VydmluZ0NvbmZpZ3MvKn06DnNlcnZpbmdfY29u
ZmlnWmsyWS92MS97c2VydmluZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NvbGxlY3Rpb25zLyovZW5naW5lcy8qL3NlcnZpbmdDb25maWdzLyp9Og5zZXJ2aW5nX2Nv
bmZpZ9pBGnNlcnZpbmdfY29uZmlnLHVwZGF0ZV9tYXNrEu0CChBHZXRTZXJ2aW5nQ29uZmln
EjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5HZXRTZXJ2aW5nQ29uZmlnUmVx
dWVzdBouLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2VydmluZ0NvbmZpZyLu
AYLT5JMC4AESPy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMv
Ki9zZXJ2aW5nQ29uZmlncy8qfVpPEk0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8qfVpMEkovdjEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9z
ZXJ2aW5nQ29uZmlncy8qfdpBBG5hbWUSgAMKEkxpc3RTZXJ2aW5nQ29uZmlncxI6Lmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdFNlcnZpbmdDb25maWdzUmVxdWVzdBo7
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdFNlcnZpbmdDb25maWdzUmVz
cG9uc2Ui8AGC0+STAuABEj8vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rh
dGFTdG9yZXMvKn0vc2VydmluZ0NvbmZpZ3NaTxJNL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2VydmluZ0NvbmZpZ3Na
TBJKL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2Vu
Z2luZXMvKn0vc2VydmluZ0NvbmZpZ3PaQQZwYXJlbnQazwHKQR5kaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVu
Z2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zl
cnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCjAIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxQhlTZXJ2aW5nQ29uZmlnU2VydmljZVByb3RvUAFaTWNsb3VkLmdvb2ds
ZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2Nv
dmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIfR29vZ2xlLkNsb3VkLkRpc2NvdmVy
eUVuZ2luZS5WMcoCH0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjHqAiJHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxSporCgcSBQ4A4wEBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJ
CgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPgoJCgIDBRIDFwAlCgkKAgMGEgMYACoK
CAoBCBIDGgA8CgkKAgglEgMaADwKCAoBCBIDGwBkCgkKAggLEgMbAGQKCAoBCBIDHAAiCgkK
AggKEgMcACIKCAoBCBIDHQA6CgkKAggIEgMdADoKCAoBCBIDHgA8CgkKAggBEgMeADwKCAoB
CBIDHwAtCgkKAggkEgMfAC0KCAoBCBIDIAA8CgkKAggpEgMgADwKCAoBCBIDIQA7CgkKAggt
EgMhADsKcQoCBgASBSUAiAEBGmQgU2VydmljZSBmb3Igb3BlcmF0aW9ucyByZWxhdGVkIHRv
CiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5TZXJ2
aW5nQ29uZmlnXS4KCgoKAwYAARIDJQgcCgoKAwYAAxIDJgJGCgwKBQYAA5kIEgMmAkYKCwoD
BgADEgQnAipKCg0KBQYAA5oIEgQnAipKCooDCgQGAAIAEgQ1AkQDGvsCIENyZWF0ZXMgYSBT
ZXJ2aW5nQ29uZmlnLgoKIE5vdGU6IFRoZSBHb29nbGUgQ2xvdWQgY29uc29sZSB3b3JrcyBv
bmx5IHdpdGggdGhlIGRlZmF1bHQgc2VydmluZyBjb25maWcuCiBBZGRpdGlvbmFsIFNlcnZp
bmdDb25maWdzIGNhbiBiZSBjcmVhdGVkIGFuZCBtYW5hZ2VkIG9ubHkgdmlhIHRoZSBBUEku
CgogQSBtYXhpbXVtIG9mIDEwMAogW1NlcnZpbmdDb25maWddW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuU2VydmluZ0NvbmZpZ11zIGFyZSBhbGxvd2VkCiBpbiBhbiBbRW5n
aW5lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkVuZ2luZV0sIG90aGVyd2lz
ZSBhCiBSRVNPVVJDRV9FWEhBVVNURUQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAIAARID
NQYZCgwKBQYAAgACEgM1GjQKDAoFBgACAAMSAzU/TAoNCgUGAAIABBIENgRBBgoRCgkGAAIA
BLDKvCISBDYEQQYKDQoFBgACAAQSBEIEQzIKEAoIBgACAASbCAASBEIEQzIKaQoEBgACARIE
SQJVAxpbIERlbGV0ZXMgYSBTZXJ2aW5nQ29uZmlnLgoKIFJldHVybnMgYSBOT1RfRk9VTkQg
ZXJyb3IgaWYgdGhlIFNlcnZpbmdDb25maWcgZG9lcyBub3QgZXhpc3QuCgoMCgUGAAIBARID
SQYZCgwKBQYAAgECEgNJGjQKDAoFBgACAQMSA0oPJAoNCgUGAAIBBBIESwRTBgoRCgkGAAIB
BLDKvCISBEsEUwYKDAoFBgACAQQSA1QEMgoPCggGAAIBBJsIABIDVAQyCmkKBAYAAgISBFoC
aAMaWyBVcGRhdGVzIGEgU2VydmluZ0NvbmZpZy4KCiBSZXR1cm5zIGEgTk9UX0ZPVU5EIGVy
cm9yIGlmIHRoZSBTZXJ2aW5nQ29uZmlnIGRvZXMgbm90IGV4aXN0LgoKDAoFBgACAgESA1oG
GQoMCgUGAAICAhIDWho0CgwKBQYAAgIDEgNaP0wKDQoFBgACAgQSBFsEZgYKEQoJBgACAgSw
yrwiEgRbBGYGCgwKBQYAAgIEEgNnBEgKDwoIBgACAgSbCAASA2cESAplCgQGAAIDEgRtAngD
GlcgR2V0cyBhIFNlcnZpbmdDb25maWcuCgogUmV0dXJucyBhIE5vdEZvdW5kIGVycm9yIGlm
IHRoZSBTZXJ2aW5nQ29uZmlnIGRvZXMgbm90IGV4aXN0LgoKDAoFBgACAwESA20GFgoMCgUG
AAIDAhIDbRcuCgwKBQYAAgMDEgNtOUYKDQoFBgACAwQSBG4EdgYKEQoJBgACAwSwyrwiEgRu
BHYGCgwKBQYAAgMEEgN3BDIKDwoIBgACAwSbCAASA3cEMgpDCgQGAAIEEgV7AocBAxo0IExp
c3RzIGFsbCBTZXJ2aW5nQ29uZmlncyBsaW5rZWQgdG8gdGhpcyBkYXRhU3RvcmUuCgoMCgUG
AAIEARIDewYYCgwKBQYAAgQCEgN7GTIKDAoFBgACBAMSA3wPKQoOCgUGAAIEBBIFfQSFAQYK
EgoJBgACBASwyrwiEgV9BIUBBgoNCgUGAAIEBBIEhgEENAoQCggGAAIEBJsIABIEhgEENAo3
CgIEABIGiwEAngEBGikgUmVxdWVzdCBmb3IgQ3JlYXRlU2VydmluZ0NvbmZpZyBtZXRob2Qu
CgoLCgMEAAESBIsBCCIKlwEKBAQAAgASBo4BApMBBBqGASBSZXF1aXJlZC4gRnVsbCByZXNv
dXJjZSBuYW1lIG9mIHBhcmVudC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5n
aW5lfWAKCg0KBQQAAgAFEgSOAQIICg0KBQQAAgABEgSOAQkPCg0KBQQAAgADEgSOARITCg8K
BQQAAgAIEgaOARSTAQMKEAoIBAACAAicCAASBI8BBCoKEQoHBAACAAifCBIGkAEEkgEFCjYK
BAQAAgESBJYBAkwaKCBSZXF1aXJlZC4gVGhlIFNlcnZpbmdDb25maWcgdG8gY3JlYXRlLgoK
DQoFBAACAQYSBJYBAg8KDQoFBAACAQESBJYBEB4KDQoFBAACAQMSBJYBISIKDQoFBAACAQgS
BJYBI0sKEAoIBAACAQicCAASBJYBJEoK6wEKBAQAAgISBJ0BAkga3AEgUmVxdWlyZWQuIFRo
ZSBJRCB0byB1c2UgZm9yIHRoZSBTZXJ2aW5nQ29uZmlnLCB3aGljaCB3aWxsIGJlY29tZSB0
aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgU2VydmluZ0NvbmZpZydzIHJlc291cmNlIG5h
bWUuCgogVGhpcyB2YWx1ZSBzaG91bGQgYmUgNC02MyBjaGFyYWN0ZXJzLCBhbmQgdmFsaWQg
Y2hhcmFjdGVycwogYXJlIC9bYS16QS1aMC05XVthLXpBLVowLTlfLV0rLy4KCg0KBQQAAgIF
EgSdAQIICg0KBQQAAgIBEgSdAQkaCg0KBQQAAgIDEgSdAR0eCg0KBQQAAgIIEgSdAR9HChAK
CAQAAgIInAgAEgSdASBGCjcKAgQBEgahAQCtAQEaKSBSZXF1ZXN0IGZvciBVcGRhdGVTZXJ2
aW5nQ29uZmlnIG1ldGhvZC4KCgsKAwQBARIEoQEIIgo2CgQEAQIAEgSjAQJMGiggUmVxdWly
ZWQuIFRoZSBTZXJ2aW5nQ29uZmlnIHRvIHVwZGF0ZS4KCg0KBQQBAgAGEgSjAQIPCg0KBQQB
AgABEgSjARAeCg0KBQQBAgADEgSjASEiCg0KBQQBAgAIEgSjASNLChAKCAQBAgAInAgAEgSj
ASRKCqECCgQEAQIBEgSsAQIsGpICIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHBy
b3ZpZGVkCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5TZXJ2aW5nQ29uZmlnXSB0byB1cGRhdGUuCiBUaGUgZm9sbG93aW5nIGFyZSBOT1Qgc3Vw
cG9ydGVkOgoKICogW1NlcnZpbmdDb25maWcubmFtZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5TZXJ2aW5nQ29uZmlnLm5hbWVdCgogSWYgbm90IHNldCwgYWxsIHN1cHBv
cnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoNCgUEAQIBBhIErAECGwoNCgUEAQIBARIErAEc
JwoNCgUEAQIBAxIErAEqKwo3CgIEAhIGsAEAuQEBGikgUmVxdWVzdCBmb3IgRGVsZXRlU2Vy
dmluZ0NvbmZpZyBtZXRob2QuCgoLCgMEAgESBLABCCIKzgEKBAQCAgASBrMBArgBBBq9ASBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNlcnZpbmdDb25maWcgdG8gZGVs
ZXRlLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdpbmV9L3NlcnZpbmdDb25m
aWdzL3tzZXJ2aW5nX2NvbmZpZ19pZH1gCgoNCgUEAgIABRIEswECCAoNCgUEAgIAARIEswEJ
DQoNCgUEAgIAAxIEswEQEQoPCgUEAgIACBIGswESuAEDChAKCAQCAgAInAgAEgS0AQQqChEK
BwQCAgAInwgSBrUBBLcBBQo0CgIEAxIGvAEAxQEBGiYgUmVxdWVzdCBmb3IgR2V0U2Vydmlu
Z0NvbmZpZyBtZXRob2QuCgoLCgMEAwESBLwBCB8KywEKBAQDAgASBr8BAsQBBBq6ASBSZXF1
aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNlcnZpbmdDb25maWcgdG8gZ2V0LiBG
b3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxl
Y3Rpb25zL3tjb2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdpbmV9L3NlcnZpbmdDb25maWdzL3tz
ZXJ2aW5nX2NvbmZpZ19pZH1gCgoNCgUEAwIABRIEvwECCAoNCgUEAwIAARIEvwEJDQoNCgUE
AwIAAxIEvwEQEQoPCgUEAwIACBIGvwESxAEDChAKCAQDAgAInAgAEgTAAQQqChEKBwQDAgAI
nwgSBsEBBMMBBQo2CgIEBBIGyAEA2gEBGiggUmVxdWVzdCBmb3IgTGlzdFNlcnZpbmdDb25m
aWdzIG1ldGhvZC4KCgsKAwQEARIEyAEIIQqkAQoEBAQCABIGywEC0AEEGpMBIFJlcXVpcmVk
LiBGdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZS4gRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97
Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5naW5lfWAKCg0KBQQEAgAFEgTLAQIICg0KBQQEAgAB
EgTLAQkPCg0KBQQEAgADEgTLARITCg8KBQQEAgAIEgbLARTQAQMKEAoIBAQCAAicCAASBMwB
BCoKEQoHBAQCAAifCBIGzQEEzwEFCq0BCgQEBAIBEgTVAQI/Gp4BIE9wdGlvbmFsLiBNYXhp
bXVtIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1
bHRzCiB0byAxMDAuIElmIGEgdmFsdWUgZ3JlYXRlciB0aGFuIDEwMCBpcyBwcm92aWRlZCwg
YXQgbW9zdCAxMDAgcmVzdWx0cyBhcmUKIHJldHVybmVkLgoKDQoFBAQCAQUSBNUBAgcKDQoF
BAQCAQESBNUBCBEKDQoFBAQCAQMSBNUBFBUKDQoFBAQCAQgSBNUBFj4KEAoIBAQCAQicCAAS
BNUBFz0KigEKBAQEAgISBNkBAkEafCBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZl
ZCBmcm9tIGEgcHJldmlvdXMgYExpc3RTZXJ2aW5nQ29uZmlnc2AgY2FsbC4KIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBAQCAgUSBNkBAggK
DQoFBAQCAgESBNkBCRMKDQoFBAQCAgMSBNkBFhcKDQoFBAQCAggSBNkBGEAKEAoIBAQCAgic
CAASBNkBGT8KNwoCBAUSBt0BAOMBARopIFJlc3BvbnNlIGZvciBMaXN0U2VydmluZ0NvbmZp
Z3MgbWV0aG9kLgoKCwoDBAUBEgTdAQgiCj0KBAQFAgASBN8BAi0aLyBBbGwgdGhlIFNlcnZp
bmdDb25maWdzIGZvciBhIGdpdmVuIGRhdGFTdG9yZS4KCg0KBQQFAgAEEgTfAQIKCg0KBQQF
AgAGEgTfAQsYCg0KBQQFAgABEgTfARkoCg0KBQQFAgADEgTfASssCkoKBAQFAgESBOIBAh0a
PCBQYWdpbmF0aW9uIHRva2VuLCBpZiBub3QgcmV0dXJuZWQgaW5kaWNhdGVzIHRoZSBsYXN0
IHBhZ2UuCgoNCgUEBQIBBRIE4gECCAoNCgUEBQIBARIE4gEJGAoNCgUEBQIBAxIE4gEbHGIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest ===
    # Fields for CreateServingConfigRequest
    # Field: parent Type: 9 ()
    # Field: serving_config Type: 11 (.google.cloud.discoveryengine.v1.ServingConfig)
    # Field: serving_config_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ServingConfigService::UpdateServingConfigRequest ===
    # Fields for UpdateServingConfigRequest
    # Field: serving_config Type: 11 (.google.cloud.discoveryengine.v1.ServingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1::ServingConfigService::DeleteServingConfigRequest ===
    # Fields for DeleteServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ServingConfigService::GetServingConfigRequest ===
    # Fields for GetServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ServingConfigService::ListServingConfigsRequest ===
    # Fields for ListServingConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ServingConfigService::ListServingConfigsResponse ===
    # Fields for ListServingConfigsResponse
    # Field: serving_configs Type: 11 (.google.cloud.discoveryengine.v1.ServingConfig)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1::ServingConfigService::ServingConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1::ServingConfigService::ServingConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::ServingConfigService::ServingConfigServiceClient

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
        ? Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig',
    });
}

sub delete_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ServingConfigService::DeleteServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ServingConfigService',
        method         => 'DeleteServingConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ServingConfigService::UpdateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig',
    });
}

sub get_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ServingConfigService::GetServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ServingConfigService',
        method         => 'GetServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig',
    });
}

sub list_serving_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ServingConfigService::ListServingConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ServingConfigService',
        method         => 'ListServingConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::ServingConfigService::ListServingConfigsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::ServingConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/serving_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::ServingConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest->new({
        parent => $parent,
        serving_config => $serving_config,
        serving_config_id => $serving_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/serving_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest

Request for CreateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}`

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig>)

Required. The ServingConfig to create.

=item * C<< $msg->serving_config_id() >> / C<< $msg->serving_config_id($value) >>

Type: C<String>

Required. The ID to use for the ServingConfig, which will become the final
component of the ServingConfig's resource name.

This value should be 4-63 characters, and valid characters
are /[a-zA-Z0-9][a-zA-Z0-9_-]+/.

=back

=head2 Google::Cloud::Discoveryengine::V1::ServingConfigService::UpdateServingConfigRequest

Request for UpdateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig>)

Required. The ServingConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[ServingConfig][google.cloud.discoveryengine.v1.ServingConfig] to update.
The following are NOT supported:

* [ServingConfig.name][google.cloud.discoveryengine.v1.ServingConfig.name]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Discoveryengine::V1::ServingConfigService::DeleteServingConfigRequest

Request for DeleteServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to delete. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1::ServingConfigService::GetServingConfigRequest

Request for GetServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to get. Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1::ServingConfigService::ListServingConfigsRequest

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

=head2 Google::Cloud::Discoveryengine::V1::ServingConfigService::ListServingConfigsResponse

Response for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_configs() >> / C<< $msg->serving_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig>)

All the ServingConfigs for a given dataStore.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::ServingConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
