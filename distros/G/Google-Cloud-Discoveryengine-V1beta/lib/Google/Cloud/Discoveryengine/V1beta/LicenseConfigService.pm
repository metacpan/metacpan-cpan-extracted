package Google::Cloud::Discoveryengine::V1beta::LicenseConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::LicenseConfig };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9saWNlbnNlX2NvbmZpZ19z
ZXJ2aWNlLnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aOGdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL2xpY2Vuc2VfY29uZmln
LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byL2AQoaQ3JlYXRlTGlj
ZW5zZUNvbmZpZ1JlcXVlc3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50El4KDmxpY2Vuc2VfY29uZmln
GAIgASgLMjIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNv
bmZpZ0ID4EECUg1saWNlbnNlQ29uZmlnEi8KEWxpY2Vuc2VfY29uZmlnX2lkGAMgASgJQgPg
QQFSD2xpY2Vuc2VDb25maWdJZCK+AQoaVXBkYXRlTGljZW5zZUNvbmZpZ1JlcXVlc3QSXgoO
bGljZW5zZV9jb25maWcYASABKAsyMi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5MaWNlbnNlQ29uZmlnQgPgQQJSDWxpY2Vuc2VDb25maWcSQAoLdXBkYXRlX21hc2sY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siYwoX
R2V0TGljZW5zZUNvbmZpZ1JlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixkaXNjb3Zl
cnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vTGljZW5zZUNvbmZpZ1IEbmFtZSLHAQoZTGlzdExp
Y2Vuc2VDb25maWdzUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIg
ASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2Vu
EhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIioQEKGkxpc3RMaWNlbnNlQ29uZmlnc1Jl
c3BvbnNlElsKD2xpY2Vuc2VfY29uZmlncxgBIAMoCzIyLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWdSDmxpY2Vuc2VDb25maWdzEiYKD25leHRf
cGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLSAgoeRGlzdHJpYnV0ZUxpY2Vuc2VD
b25maWdSZXF1ZXN0EocBCh5iaWxsaW5nX2FjY291bnRfbGljZW5zZV9jb25maWcYASABKAlC
QuBBAvpBPAo6ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0JpbGxpbmdBY2NvdW50
TGljZW5zZUNvbmZpZ1IbYmlsbGluZ0FjY291bnRMaWNlbnNlQ29uZmlnEioKDnByb2plY3Rf
bnVtYmVyGAIgASgDQgPgQQJSDXByb2plY3ROdW1iZXISHwoIbG9jYXRpb24YAyABKAlCA+BB
AlIIbG9jYXRpb24SKAoNbGljZW5zZV9jb3VudBgEIAEoA0ID4EECUgxsaWNlbnNlQ291bnQS
LwoRbGljZW5zZV9jb25maWdfaWQYBSABKAlCA+BBAVIPbGljZW5zZUNvbmZpZ0lkInwKH0Rp
c3RyaWJ1dGVMaWNlbnNlQ29uZmlnUmVzcG9uc2USWQoObGljZW5zZV9jb25maWcYASABKAsy
Mi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnUg1s
aWNlbnNlQ29uZmlnItYCChtSZXRyYWN0TGljZW5zZUNvbmZpZ1JlcXVlc3QShwEKHmJpbGxp
bmdfYWNjb3VudF9saWNlbnNlX2NvbmZpZxgBIAEoCUJC4EEC+kE8CjpkaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb20vQmlsbGluZ0FjY291bnRMaWNlbnNlQ29uZmlnUhtiaWxsaW5n
QWNjb3VudExpY2Vuc2VDb25maWcSWwoObGljZW5zZV9jb25maWcYAiABKAlCNOBBAvpBLgos
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xpY2Vuc2VDb25maWdSDWxpY2Vuc2VD
b25maWcSJgoMZnVsbF9yZXRyYWN0GAMgASgIQgPgQQFSC2Z1bGxSZXRyYWN0EigKDWxpY2Vu
c2VfY291bnQYBCABKANCA+BBAVIMbGljZW5zZUNvdW50InkKHFJldHJhY3RMaWNlbnNlQ29u
ZmlnUmVzcG9uc2USWQoObGljZW5zZV9jb25maWcYASABKAsyMi5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnUg1saWNlbnNlQ29uZmlnMosPChRM
aWNlbnNlQ29uZmlnU2VydmljZRKEAgoTQ3JlYXRlTGljZW5zZUNvbmZpZxI/Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0ZUxpY2Vuc2VDb25maWdSZXF1ZXN0
GjIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNvbmZpZyJ4
gtPkkwJIIjYvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vbGljZW5z
ZUNvbmZpZ3M6DmxpY2Vuc2VfY29uZmln2kEncGFyZW50LGxpY2Vuc2VfY29uZmlnLGxpY2Vu
c2VfY29uZmlnX2lkEoYCChNVcGRhdGVMaWNlbnNlQ29uZmlnEj8uZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuVXBkYXRlTGljZW5zZUNvbmZpZ1JlcXVlc3QaMi5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnInqC0+STAlcy
RS92MWJldGEve2xpY2Vuc2VfY29uZmlnLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9s
aWNlbnNlQ29uZmlncy8qfToObGljZW5zZV9jb25maWfaQRpsaWNlbnNlX2NvbmZpZyx1cGRh
dGVfbWFzaxLLAQoQR2V0TGljZW5zZUNvbmZpZxI8Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkdldExpY2Vuc2VDb25maWdSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNvbmZpZyJFgtPkkwI4EjYvdjFiZXRhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovbGljZW5zZUNvbmZpZ3MvKn3aQQRuYW1lEt4B
ChJMaXN0TGljZW5zZUNvbmZpZ3MSPi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5MaXN0TGljZW5zZUNvbmZpZ3NSZXF1ZXN0Gj8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuTGlzdExpY2Vuc2VDb25maWdzUmVzcG9uc2UiR4LT5JMCOBI2L3Yx
YmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2xpY2Vuc2VDb25maWdz2kEG
cGFyZW50EvwCChdEaXN0cmlidXRlTGljZW5zZUNvbmZpZxJDLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkRpc3RyaWJ1dGVMaWNlbnNlQ29uZmlnUmVxdWVzdBpELmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRpc3RyaWJ1dGVMaWNlbnNlQ29u
ZmlnUmVzcG9uc2Ui1QGC0+STAnYicS92MWJldGEve2JpbGxpbmdfYWNjb3VudF9saWNlbnNl
X2NvbmZpZz1iaWxsaW5nQWNjb3VudHMvKi9iaWxsaW5nQWNjb3VudExpY2Vuc2VDb25maWdz
Lyp9OmRpc3RyaWJ1dGVMaWNlbnNlQ29uZmlnOgEq2kFWYmlsbGluZ19hY2NvdW50X2xpY2Vu
c2VfY29uZmlnLHByb2plY3RfbnVtYmVyLGxvY2F0aW9uLGxpY2Vuc2VfY291bnQsbGljZW5z
ZV9jb25maWdfaWQS4gIKFFJldHJhY3RMaWNlbnNlQ29uZmlnEkAuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuUmV0cmFjdExpY2Vuc2VDb25maWdSZXF1ZXN0GkEuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUmV0cmFjdExpY2Vuc2VDb25maWdS
ZXNwb25zZSLEAYLT5JMCcyJuL3YxYmV0YS97YmlsbGluZ19hY2NvdW50X2xpY2Vuc2VfY29u
ZmlnPWJpbGxpbmdBY2NvdW50cy8qL2JpbGxpbmdBY2NvdW50TGljZW5zZUNvbmZpZ3MvKn06
cmV0cmFjdExpY2Vuc2VDb25maWc6ASraQUhiaWxsaW5nX2FjY291bnRfbGljZW5zZV9jb25m
aWcsbGljZW5zZV9jb25maWcsZnVsbF9yZXRyYWN0LGxpY2Vuc2VfY291bnQazwHKQR5kaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCoAIKJ2NvbS5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIZTGljZW5zZUNvbmZpZ1NlcnZpY2VQcm90
b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlz
Y292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNH
b29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNj
b3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpW
MWJldGFKr0oKBxIFDgC3AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
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
CgIDBBIDFgBCCgkKAgMFEgMXACoKCAoBCBIDGQBACgkKAgglEgMZAEAKCAoBCBIDGgBoCgkK
AggLEgMaAGgKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA6CgkKAggIEgMcADoKCAoB
CBIDHQBACgkKAggBEgMdAEAKCAoBCBIDHgAtCgkKAggkEgMeAC0KCAoBCBIDHwBACgkKAggp
EgMfAEAKCAoBCBIDIAA/CgkKAggtEgMgAD8KRAoCBgASBCMAbQEaOCBTZXJ2aWNlIGZvciBt
YW5hZ2luZyBsaWNlbnNlIGNvbmZpZyByZWxhdGVkIHJlc291cmNlcy4KCgoKAwYAARIDIwgc
CgoKAwYAAxIDJAJGCgwKBQYAA5kIEgMkAkYKCwoDBgADEgQlAihKCg0KBQYAA5oIEgQlAihK
CssBCgQGAAIAEgQuAjUDGrwBIENyZWF0ZXMgYQogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWddIFRoaXMKIG1ldGhv
ZCBzaG91bGQgb25seSBiZSB1c2VkIGZvciBjcmVhdGluZyBOb3RlYm9va0xtIGxpY2Vuc2Vz
IG9yIEdlbWluaQogRW50ZXJwcmlzZSBmcmVlIHRyaWFsIGxpY2Vuc2VzLgoKDAoFBgACAAES
Ay4GGQoMCgUGAAIAAhIDLho0CgwKBQYAAgADEgMuP0wKDQoFBgACAAQSBC8EMgYKEQoJBgAC
AASwyrwiEgQvBDIGCg0KBQYAAgAEEgQzBDQyChAKCAYAAgAEmwgAEgQzBDQyCl8KBAYAAgES
BDkCPwMaUSBVcGRhdGVzIHRoZQogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWddCgoMCgUGAAIBARIDOQYZCgwKBQYA
AgECEgM5GjQKDAoFBgACAQMSAzk/TAoNCgUGAAIBBBIEOgQ9BgoRCgkGAAIBBLDKvCISBDoE
PQYKDAoFBgACAQQSAz4ESAoPCggGAAIBBJsIABIDPgRICloKBAYAAgISBEICRwMaTCBHZXRz
IGEgW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkxpY2Vuc2VDb25maWddLgoKDAoFBgACAgESA0IGFgoMCgUGAAICAhIDQhcuCgwKBQYAAgID
EgNCOUYKDQoFBgACAgQSBEMERQYKEQoJBgACAgSwyrwiEgRDBEUGCgwKBQYAAgIEEgNGBDIK
DwoIBgACAgSbCAASA0YEMgqAAQoEBgACAxIETAJSAxpyIExpc3RzIGFsbCB0aGUKIFtMaWNl
bnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNl
Q29uZmlnXXMKIGFzc29jaWF0ZWQgd2l0aCB0aGUgcHJvamVjdC4KCgwKBQYAAgMBEgNMBhgK
DAoFBgACAwISA0wZMgoMCgUGAAIDAxIDTQ8pCg0KBQYAAgMEEgROBFAGChEKCQYAAgMEsMq8
IhIETgRQBgoMCgUGAAIDBBIDUQQ0Cg8KCAYAAgMEmwgAEgNRBDQKkAEKBAYAAgQSBFcCXwMa
gQEgRGlzdHJpYnV0ZXMgYQogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWddIGZyb20KIGJpbGxpbmcgYWNjb3VudCBs
ZXZlbCB0byBwcm9qZWN0IGxldmVsLgoKDAoFBgACBAESA1cGHQoMCgUGAAIEAhIDVx48CgwK
BQYAAgQDEgNYDy4KDQoFBgACBAQSBFkEXAYKEQoJBgACBASwyrwiEgRZBFwGCg0KBQYAAgQE
EgRdBF5hChAKCAYAAgQEmwgAEgRdBF5hCswBCgQGAAIFEgRkAmwDGr0BIFRoaXMgbWV0aG9k
IGlzIGNhbGxlZCBmcm9tIHRoZSBiaWxsaW5nIGFjY291bnQgc2lkZSB0byByZXRyYWN0IHRo
ZQogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkxpY2Vuc2VDb25maWddIGZyb20gdGhlCiBnaXZlbiBwcm9qZWN0IGJhY2sgdG8gdGhlIGJp
bGxpbmcgYWNjb3VudC4KCgwKBQYAAgUBEgNkBhoKDAoFBgACBQISA2QbNgoMCgUGAAIFAxID
ZQ8rCg0KBQYAAgUEEgRmBGkGChEKCQYAAgUEsMq8IhIEZgRpBgoNCgUGAAIFBBIEagRrUwoQ
CggGAAIFBJsIABIEagRrUwqmAQoCBAASBXIAiAEBGpgBIFJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtMaWNlbnNlQ29uZmlnU2VydmljZS5DcmVhdGVMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnU2VydmljZS5DcmVhdGVM
aWNlbnNlQ29uZmlnXQogbWV0aG9kLgoKCgoDBAABEgNyCCIKZwoEBAACABIEdQJ6BBpZIFJl
cXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDAoFBAACAAUSA3UCCAoMCgUEAAIA
ARIDdQkPCgwKBQQAAgADEgN1EhMKDQoFBAACAAgSBHUUegMKDwoIBAACAAicCAASA3YEKgoP
CgcEAAIACJ8IEgR3BHkFCmwKBAQAAgESA38CTBpfIFJlcXVpcmVkLiBUaGUKIFtMaWNlbnNl
Q29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29u
ZmlnXSB0bwogY3JlYXRlLgoKDAoFBAACAQYSA38CDwoMCgUEAAIBARIDfxAeCgwKBQQAAgED
EgN/ISIKDAoFBAACAQgSA38jSwoPCggEAAIBCJwIABIDfyRKCuwCCgQEAAICEgSHAQJIGt0C
IE9wdGlvbmFsLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtMaWNlbnNlQ29uZmlnXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnXSwgd2hpY2gK
IHdpbGwgYmVjb21lIHRoZSBmaW5hbCBjb21wb25lbnQgb2YgdGhlCiBbTGljZW5zZUNvbmZp
Z11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNvbmZpZ10n
cwogcmVzb3VyY2UgbmFtZS4gV2UgYXJlIHVzaW5nIHRoZSB0aWVyIChwcm9kdWN0IGVkaXRp
b24pIG5hbWUgYXMgdGhlIGxpY2Vuc2UKIGNvbmZpZyBpZCBzdWNoIGFzIGBzZWFyY2hgIG9y
IGBzZWFyY2hfYW5kX2Fzc2lzdGFudGAuCgoNCgUEAAICBRIEhwECCAoNCgUEAAICARIEhwEJ
GgoNCgUEAAICAxIEhwEdHgoNCgUEAAICCBIEhwEfRwoQCggEAAICCJwIABIEhwEgRgqnAQoC
BAESBo0BAJsBARqYASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZp
Y2UuVXBkYXRlTGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuTGljZW5zZUNvbmZpZ1NlcnZpY2UuVXBkYXRlTGljZW5zZUNvbmZpZ10KIG1ldGhv
ZC4KCgsKAwQBARIEjQEIIgptCgQEAQIAEgSRAQJMGl8gUmVxdWlyZWQuIFRoZQogW0xpY2Vu
c2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpY2Vuc2VD
b25maWddIHRvCiB1cGRhdGUuCgoNCgUEAQIABhIEkQECDwoNCgUEAQIAARIEkQEQHgoNCgUE
AQIAAxIEkQEhIgoNCgUEAQIACBIEkQEjSwoQCggEAQIACJwIABIEkQEkSgrtAQoEBAECARIG
mQECmgEvGtwBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92
aWRlZAogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkxpY2Vuc2VDb25maWddIHRvCiB1cGRhdGUuCgogSWYgYW4gdW5zdXBwb3J0ZWQgb3Ig
dW5rbm93biBmaWVsZCBpcyBwcm92aWRlZCwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvcgog
aXMgcmV0dXJuZWQuCgoNCgUEAQIBBhIEmQECGwoNCgUEAQIBARIEmQEcJwoNCgUEAQIBAxIE
mQEqKwoNCgUEAQIBCBIEmgEGLgoQCggEAQIBCJwIABIEmgEHLQqhAQoCBAISBqABALMBARqS
ASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZpY2UuR2V0TGljZW5z
ZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNv
bmZpZ1NlcnZpY2UuR2V0TGljZW5zZUNvbmZpZ10KIG1ldGhvZC4KCgsKAwQCARIEoAEIHwqQ
BAoEBAICABIGrQECsgEEGv8DIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YKIFtM
aWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNl
bnNlQ29uZmlnXSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9saWNlbnNlQ29uZmlncy8qYC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhh
dmUgcGVybWlzc2lvbiB0byBhY2Nlc3MgdGhlCiBbTGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNvbmZpZ10sCiByZWdhcmRsZXNz
IG9mIHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RFTklFRCBlcnJv
ciBpcwogcmV0dXJuZWQuCgogSWYgdGhlIHJlcXVlc3RlZAogW0xpY2Vuc2VDb25maWddW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWddIGRvZXMg
bm90CiBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAgIABRIE
rQECCAoNCgUEAgIAARIErQEJDQoNCgUEAgIAAxIErQEQEQoPCgUEAgIACBIGrQESsgEDChAK
CAQCAgAInAgAEgSuAQQqChEKBwQCAgAInwgSBq8BBLEBBQqlAQoCBAMSBrgBANcBARqWASBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZpY2UuTGlzdExpY2Vuc2VD
b25maWdzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29u
ZmlnU2VydmljZS5MaXN0TGljZW5zZUNvbmZpZ3NdCiBtZXRob2QuCgoLCgMEAwESBLgBCCEK
cAoEBAMCABIGuwECwAEEGmAgUmVxdWlyZWQuIFRoZSBwYXJlbnQgYnJhbmNoIHJlc291cmNl
IG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn1gLgoKDQoFBAMCAAUSBLsBAggKDQoFBAMCAAESBLsBCQ8KDQoFBAMCAAMSBLsBEhMKDwoF
BAMCAAgSBrsBFMABAwoQCggEAwIACJwIABIEvAEEKgoRCgcEAwIACJ8IEga9AQS/AQUKKAoE
BAMCARIEwwECPxoaIE9wdGlvbmFsLiBOb3Qgc3VwcG9ydGVkLgoKDQoFBAMCAQUSBMMBAgcK
DQoFBAMCAQESBMMBCBEKDQoFBAMCAQMSBMMBFBUKDQoFBAMCAQgSBMMBFj4KEAoIBAMCAQic
CAASBMMBFz0KKAoEBAMCAhIExgECQRoaIE9wdGlvbmFsLiBOb3Qgc3VwcG9ydGVkLgoKDQoF
BAMCAgUSBMYBAggKDQoFBAMCAgESBMYBCRMKDQoFBAMCAgMSBMYBFhcKDQoFBAMCAggSBMYB
GEAKEAoIBAMCAgicCAASBMYBGT8KgwMKBAQDAgMSBNYBAj0a9AIgT3B0aW9uYWwuIFRoZSBm
aWx0ZXIgdG8gYXBwbHkgdG8gdGhlIGxpc3QgcmVzdWx0cy4KCiBUaGUgc3VwcG9ydGVkIGZp
ZWxkcyBhcmU6CgogICAqIGBzdWJzY3JpcHRpb25fdGllcmAKICAgKiBgc3RhdGVgCgogRXhh
bXBsZXM6CgogICAqIGBzdWJzY3JpcHRpb25fdGllcj1TVUJTQ1JJUFRJT05fVElFUl9TRUFS
Q0gsc3RhdGU9QUNUSVZFYCAtIExpc3RzIGFsbAogICBhY3RpdmUgc2VhcmNoIGxpY2Vuc2Ug
Y29uZmlncy4KICAgKiBgc3RhdGU9QUNUSVZFYCAtIExpc3RzIGFsbCBhY3RpdmUgbGljZW5z
ZSBjb25maWdzLgoKIFRoZSBmaWx0ZXIgc3RyaW5nIHNob3VsZCBiZSBhIGNvbW1hLXNlcGFy
YXRlZCBsaXN0IG9mIGZpZWxkPXZhbHVlIHBhaXJzLgoKDQoFBAMCAwUSBNYBAggKDQoFBAMC
AwESBNYBCQ8KDQoFBAMCAwMSBNYBEhMKDQoFBAMCAwgSBNYBFDwKEAoIBAMCAwicCAASBNYB
FTsKpgEKAgQEEgbcAQDjAQEalwEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtMaWNlbnNlQ29u
ZmlnU2VydmljZS5MaXN0TGljZW5zZUNvbmZpZ3NdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWdTZXJ2aWNlLkxpc3RMaWNlbnNlQ29uZmlnc10K
IG1ldGhvZC4KCgsKAwQEARIE3AEIIgpoCgQEBAIAEgTfAQItGlogQWxsIHRoZSBjdXN0b21l
cidzCiBbTGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuTGljZW5zZUNvbmZpZ11zLgoKDQoFBAQCAAQSBN8BAgoKDQoFBAQCAAYSBN8BCxgKDQoF
BAQCAAESBN8BGSgKDQoFBAQCAAMSBN8BKywKHgoEBAQCARIE4gECHRoQIE5vdCBzdXBwb3J0
ZWQuCgoNCgUEBAIBBRIE4gECCAoNCgUEBAIBARIE4gEJGAoNCgUEBAIBAxIE4gEbHAqvAQoC
BAUSBugBAIMCARqgASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZp
Y2UuRGlzdHJpYnV0ZUxpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkxpY2Vuc2VDb25maWdTZXJ2aWNlLkRpc3RyaWJ1dGVMaWNlbnNlQ29uZmln
XQogbWV0aG9kLgoKCwoDBAUBEgToAQgmCsQBCgQEBQIAEgbtAQLyAQQaswEgUmVxdWlyZWQu
IEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBbQmlsbGluZ0FjY291bnRMaWNlbnNlQ29uZmlnXVtd
LgoKIEZvcm1hdDoKIGBiaWxsaW5nQWNjb3VudHMve2JpbGxpbmdfYWNjb3VudH0vYmlsbGlu
Z0FjY291bnRMaWNlbnNlQ29uZmlncy97YmlsbGluZ19hY2NvdW50X2xpY2Vuc2VfY29uZmln
X2lkfWAuCgoNCgUEBQIABRIE7QECCAoNCgUEBQIAARIE7QEJJwoNCgUEBQIAAxIE7QEqKwoP
CgUEBQIACBIG7QEs8gEDChAKCAQFAgAInAgAEgTuAQQqChEKBwQFAgAInwgSBu8BBPEBBQpd
CgQEBQIBEgT2AQJEGk8gUmVxdWlyZWQuIFRoZSB0YXJnZXQgR0NQIHByb2plY3QgbnVtYmVy
IHRvIGRpc3RyaWJ1dGUgdGhlIGxpY2Vuc2UgY29uZmlnCiB0by4KCg0KBQQFAgEFEgT2AQIH
Cg0KBQQFAgEBEgT2AQgWCg0KBQQFAgEDEgT2ARkaCg0KBQQFAgEIEgT2ARtDChAKCAQFAgEI
nAgAEgT2ARxCCl0KBAQFAgISBPoBAj8aTyBSZXF1aXJlZC4gVGhlIHRhcmdldCBHQ1AgcHJv
amVjdCByZWdpb24gdG8gZGlzdHJpYnV0ZSB0aGUgbGljZW5zZSBjb25maWcKIHRvLgoKDQoF
BAUCAgUSBPoBAggKDQoFBAUCAgESBPoBCREKDQoFBAUCAgMSBPoBFBUKDQoFBAUCAggSBPoB
Fj4KEAoIBAUCAgicCAASBPoBFz0KPwoEBAUCAxIE/QECQxoxIFJlcXVpcmVkLiBUaGUgbnVt
YmVyIG9mIGxpY2Vuc2VzIHRvIGRpc3RyaWJ1dGUuCgoNCgUEBQIDBRIE/QECBwoNCgUEBQID
ARIE/QEIFQoNCgUEBQIDAxIE/QEYGQoNCgUEBQIDCBIE/QEaQgoQCggEBQIDCJwIABIE/QEb
QQrDAQoEBAUCBBIEggICSBq0ASBPcHRpb25hbC4gRGlzdHJpYnV0ZSBzZWF0cyB0byB0aGlz
IGxpY2Vuc2UgY29uZmlnIGluc3RlYWQgb2YgY3JlYXRpbmcgYSBuZXcKIG9uZS4gSWYgbm90
IHNwZWNpZmllZCwgYSBuZXcgbGljZW5zZSBjb25maWcgd2lsbCBiZSBjcmVhdGVkIGZyb20g
dGhlCiBiaWxsaW5nIGFjY291bnQgbGljZW5zZSBjb25maWcuCgoNCgUEBQIEBRIEggICCAoN
CgUEBQIEARIEggIJGgoNCgUEBQIEAxIEggIdHgoNCgUEBQIECBIEggIfRwoQCggEBQIECJwI
ABIEggIgRgqwAQoCBAYSBogCAIsCARqhASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0xpY2Vu
c2VDb25maWdTZXJ2aWNlLkRpc3RyaWJ1dGVMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmlnU2VydmljZS5EaXN0cmlidXRl
TGljZW5zZUNvbmZpZ10KIG1ldGhvZC4KCgsKAwQGARIEiAIIJwo1CgQEBgIAEgSKAgIjGicg
VGhlIHVwZGF0ZWQgb3IgY3JlYXRlZCBMaWNlbnNlQ29uZmlnLgoKDQoFBAYCAAYSBIoCAg8K
DQoFBAYCAAESBIoCEB4KDQoFBAYCAAMSBIoCISIKqQEKAgQHEgaQAgCvAgEamgEgUmVxdWVz
dCBtZXNzYWdlIGZvcgogW0xpY2Vuc2VDb25maWdTZXJ2aWNlLlJldHJhY3RMaWNlbnNlQ29u
ZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNlQ29uZmln
U2VydmljZS5SZXRyYWN0TGljZW5zZUNvbmZpZ10KIG1ldGhvZC4KCgsKAwQHARIEkAIIIwrE
AQoEBAcCABIGlQICmgIEGrMBIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgW0Jp
bGxpbmdBY2NvdW50TGljZW5zZUNvbmZpZ11bXS4KCiBGb3JtYXQ6CiBgYmlsbGluZ0FjY291
bnRzL3tiaWxsaW5nX2FjY291bnR9L2JpbGxpbmdBY2NvdW50TGljZW5zZUNvbmZpZ3Mve2Jp
bGxpbmdfYWNjb3VudF9saWNlbnNlX2NvbmZpZ19pZH1gLgoKDQoFBAcCAAUSBJUCAggKDQoF
BAcCAAESBJUCCScKDQoFBAcCAAMSBJUCKisKDwoFBAcCAAgSBpUCLJoCAwoQCggEBwIACJwI
ABIElgIEKgoRCgcEBwIACJ8IEgaXAgSZAgUK0AEKBAQHAgESBqECAqYCBBq/ASBSZXF1aXJl
ZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mCiBbTGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGljZW5zZUNvbmZpZ10uCgogRm9ybWF0OgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9saWNlbnNlQ29uZmlncy97
bGljZW5zZV9jb25maWdfaWR9YC4KCg0KBQQHAgEFEgShAgIICg0KBQQHAgEBEgShAgkXCg0K
BQQHAgEDEgShAhobCg8KBQQHAgEIEgahAhymAgMKEAoIBAcCAQicCAASBKICBCoKEQoHBAcC
AQifCBIGowIEpQIFCn0KBAQHAgISBKoCAkEabyBPcHRpb25hbC4gSWYgc2V0IHRvIHRydWUs
IHJldHJhY3QgdGhlIGVudGlyZSBsaWNlbnNlIGNvbmZpZy4gT3RoZXJ3aXNlLAogcmV0cmFj
dCB0aGUgc3BlY2lmaWVkIGxpY2Vuc2UgY291bnQuCgoNCgUEBwICBRIEqgICBgoNCgUEBwIC
ARIEqgIHEwoNCgUEBwICAxIEqgIWFwoNCgUEBwICCBIEqgIYQAoQCggEBwICCJwIABIEqgIZ
PwpjCgQEBwIDEgSuAgJDGlUgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgbGljZW5zZXMgdG8g
cmV0cmFjdC4gT25seSB1c2VkIHdoZW4gZnVsbF9yZXRyYWN0IGlzCiBmYWxzZS4KCg0KBQQH
AgMFEgSuAgIHCg0KBQQHAgMBEgSuAggVCg0KBQQHAgMDEgSuAhgZCg0KBQQHAgMIEgSuAhpC
ChAKCAQHAgMInAgAEgSuAhtBCqoBCgIECBIGtAIAtwIBGpsBIFJlc3BvbnNlIG1lc3NhZ2Ug
Zm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZpY2UuUmV0cmFjdExpY2Vuc2VDb25maWddW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpY2Vuc2VDb25maWdTZXJ2aWNlLlJl
dHJhY3RMaWNlbnNlQ29uZmlnXQogbWV0aG9kLgoKCwoDBAgBEgS0AggkCioKBAQIAgASBLYC
AiMaHCBUaGUgdXBkYXRlZCBMaWNlbnNlQ29uZmlnLgoKDQoFBAgCAAYSBLYCAg8KDQoFBAgC
AAESBLYCEB4KDQoFBAgCAAMSBLYCISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest ===
    # Fields for CreateLicenseConfigRequest
    # Field: parent Type: 9 ()
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1beta.LicenseConfig)
    # Field: license_config_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::UpdateLicenseConfigRequest ===
    # Fields for UpdateLicenseConfigRequest
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1beta.LicenseConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::GetLicenseConfigRequest ===
    # Fields for GetLicenseConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::ListLicenseConfigsRequest ===
    # Fields for ListLicenseConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::ListLicenseConfigsResponse ===
    # Fields for ListLicenseConfigsResponse
    # Field: license_configs Type: 11 (.google.cloud.discoveryengine.v1beta.LicenseConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::DistributeLicenseConfigRequest ===
    # Fields for DistributeLicenseConfigRequest
    # Field: billing_account_license_config Type: 9 ()
    # Field: project_number Type: 3 ()
    # Field: location Type: 9 ()
    # Field: license_count Type: 3 ()
    # Field: license_config_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::DistributeLicenseConfigResponse ===
    # Fields for DistributeLicenseConfigResponse
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1beta.LicenseConfig)

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::RetractLicenseConfigRequest ===
    # Fields for RetractLicenseConfigRequest
    # Field: billing_account_license_config Type: 9 ()
    # Field: license_config Type: 9 ()
    # Field: full_retract Type: 8 ()
    # Field: license_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::RetractLicenseConfigResponse ===
    # Fields for RetractLicenseConfigResponse
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1beta.LicenseConfig)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::LicenseConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::LicenseConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::LicenseConfigServiceClient

Client stub representing the remote C<LicenseConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'CreateLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig',
    });
}

sub update_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::UpdateLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'UpdateLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig',
    });
}

sub get_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::GetLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'GetLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig',
    });
}

sub list_license_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::ListLicenseConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'ListLicenseConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::ListLicenseConfigsResponse',
    });
}

sub distribute_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::DistributeLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'DistributeLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::DistributeLicenseConfigResponse',
    });
}

sub retract_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::RetractLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'RetractLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::RetractLicenseConfigResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::LicenseConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/license_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::LicenseConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest->new({
        parent => $parent,
        license_config => $license_config,
        license_config_id => $license_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/license_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest

Request message for
[LicenseConfigService.CreateLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.CreateLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>)

Required. The
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig] to
create.

=item * C<< $msg->license_config_id() >> / C<< $msg->license_config_id($value) >>

Type: C<String>

Optional. The ID to use for the
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig], which
will become the final component of the
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig]'s
resource name. We are using the tier (product edition) name as the license
config id such as `search` or `search_and_assistant`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::UpdateLicenseConfigRequest

Request message for
[LicenseConfigService.UpdateLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.UpdateLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>)

Required. The
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig] to
update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig] to
update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::GetLicenseConfigRequest

Request message for
[LicenseConfigService.GetLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.GetLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig], such as
`projects/{project}/locations/{location}/licenseConfigs/*`.

If the caller does not have permission to access the
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig],
regardless of whether or not it exists, a PERMISSION_DENIED error is
returned.

If the requested
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig] does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::ListLicenseConfigsRequest

Request message for
[LicenseConfigService.ListLicenseConfigs][google.cloud.discoveryengine.v1beta.LicenseConfigService.ListLicenseConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Not supported.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Not supported.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply to the list results.

The supported fields are:

  * `subscription_tier`
  * `state`

Examples:

  * `subscription_tier=SUBSCRIPTION_TIER_SEARCH,state=ACTIVE` - Lists all
  active search license configs.
  * `state=ACTIVE` - Lists all active license configs.

The filter string should be a comma-separated list of field=value pairs.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::ListLicenseConfigsResponse

Response message for
[LicenseConfigService.ListLicenseConfigs][google.cloud.discoveryengine.v1beta.LicenseConfigService.ListLicenseConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_configs() >> / C<< $msg->license_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>)

All the customer's
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Not supported.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::DistributeLicenseConfigRequest

Request message for
[LicenseConfigService.DistributeLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.DistributeLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->billing_account_license_config() >> / C<< $msg->billing_account_license_config($value) >>

Type: C<String>

Required. Full resource name of [BillingAccountLicenseConfig][].

Format:
`billingAccounts/{billing_account}/billingAccountLicenseConfigs/{billing_account_license_config_id}`.

=item * C<< $msg->project_number() >> / C<< $msg->project_number($value) >>

Type: C<Int64>

Required. The target GCP project number to distribute the license config
to.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. The target GCP project region to distribute the license config
to.

=item * C<< $msg->license_count() >> / C<< $msg->license_count($value) >>

Type: C<Int64>

Required. The number of licenses to distribute.

=item * C<< $msg->license_config_id() >> / C<< $msg->license_config_id($value) >>

Type: C<String>

Optional. Distribute seats to this license config instead of creating a new
one. If not specified, a new license config will be created from the
billing account license config.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::DistributeLicenseConfigResponse

Response message for
[LicenseConfigService.DistributeLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.DistributeLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>)

The updated or created LicenseConfig.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::RetractLicenseConfigRequest

Request message for
[LicenseConfigService.RetractLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.RetractLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->billing_account_license_config() >> / C<< $msg->billing_account_license_config($value) >>

Type: C<String>

Required. Full resource name of [BillingAccountLicenseConfig][].

Format:
`billingAccounts/{billing_account}/billingAccountLicenseConfigs/{billing_account_license_config_id}`.

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<String>

Required. Full resource name of
[LicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfig].

Format:
`projects/{project}/locations/{location}/licenseConfigs/{license_config_id}`.

=item * C<< $msg->full_retract() >> / C<< $msg->full_retract($value) >>

Type: C<Bool>

Optional. If set to true, retract the entire license config. Otherwise,
retract the specified license count.

=item * C<< $msg->license_count() >> / C<< $msg->license_count($value) >>

Type: C<Int64>

Optional. The number of licenses to retract. Only used when full_retract is
false.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::RetractLicenseConfigResponse

Response message for
[LicenseConfigService.RetractLicenseConfig][google.cloud.discoveryengine.v1beta.LicenseConfigService.RetractLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>)

The updated LicenseConfig.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
