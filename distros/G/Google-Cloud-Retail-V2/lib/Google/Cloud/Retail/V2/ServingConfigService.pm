package Google::Cloud::Retail::V2::ServingConfigService;

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
    eval { require Google::Cloud::Retail::V2::ServingConfig };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3NlcnZpbmdfY29uZmlnX3NlcnZpY2UucHJvdG8S
Fmdvb2dsZS5jbG91ZC5yZXRhaWwudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGitnb29nbGUvY2xvdWQvcmV0YWlsL3Yy
L3NlcnZpbmdfY29uZmlnLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdv
b2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIt8BChpDcmVhdGVTZXJ2aW5nQ29uZmln
UmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29t
L0NhdGFsb2dSBnBhcmVudBJRCg5zZXJ2aW5nX2NvbmZpZxgCIAEoCzIlLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZ0ID4EECUg1zZXJ2aW5nQ29uZmlnEi8KEXNlcnZp
bmdfY29uZmlnX2lkGAMgASgJQgPgQQJSD3NlcnZpbmdDb25maWdJZCKsAQoaVXBkYXRlU2Vy
dmluZ0NvbmZpZ1JlcXVlc3QSUQoOc2VydmluZ19jb25maWcYASABKAsyJS5nb29nbGUuY2xv
dWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWdCA+BBAlINc2VydmluZ0NvbmZpZxI7Cgt1cGRh
dGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2si
XQoaRGVsZXRlU2VydmluZ0NvbmZpZ1JlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNy
ZXRhaWwuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZ1IEbmFtZSJaChdHZXRTZXJ2aW5n
Q29uZmlnUmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUKI3JldGFpbC5nb29nbGVhcGlz
LmNvbS9TZXJ2aW5nQ29uZmlnUgRuYW1lIqABChlMaXN0U2VydmluZ0NvbmZpZ3NSZXF1ZXN0
Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxv
Z1IGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rv
a2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKUAQoaTGlzdFNlcnZpbmdDb25maWdzUmVzcG9u
c2USTgoPc2VydmluZ19jb25maWdzGAEgAygLMiUuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5T
ZXJ2aW5nQ29uZmlnUg5zZXJ2aW5nQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4iiwEKEUFkZENvbnRyb2xSZXF1ZXN0ElIKDnNlcnZpbmdfY29uZmln
GAEgASgJQivgQQL6QSUKI3JldGFpbC5nb29nbGVhcGlzLmNvbS9TZXJ2aW5nQ29uZmlnUg1z
ZXJ2aW5nQ29uZmlnEiIKCmNvbnRyb2xfaWQYAiABKAlCA+BBAlIJY29udHJvbElkIo4BChRS
ZW1vdmVDb250cm9sUmVxdWVzdBJSCg5zZXJ2aW5nX2NvbmZpZxgBIAEoCUIr4EEC+kElCiNy
ZXRhaWwuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZ1INc2VydmluZ0NvbmZpZxIiCgpj
b250cm9sX2lkGAIgASgJQgPgQQJSCWNvbnRyb2xJZDKyDAoUU2VydmluZ0NvbmZpZ1NlcnZp
Y2US8QEKE0NyZWF0ZVNlcnZpbmdDb25maWcSMi5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkNy
ZWF0ZVNlcnZpbmdDb25maWdSZXF1ZXN0GiUuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZXJ2
aW5nQ29uZmlnIn+C0+STAk8iPS92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
Y2F0YWxvZ3MvKn0vc2VydmluZ0NvbmZpZ3M6DnNlcnZpbmdfY29uZmln2kEncGFyZW50LHNl
cnZpbmdfY29uZmlnLHNlcnZpbmdfY29uZmlnX2lkEq8BChNEZWxldGVTZXJ2aW5nQ29uZmln
EjIuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5EZWxldGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJMgtPkkwI/Kj0vdjIve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jYXRhbG9ncy8qL3NlcnZpbmdDb25maWdzLyp92kEEbmFtZRL0AQoTVXBk
YXRlU2VydmluZ0NvbmZpZxIyLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXBkYXRlU2Vydmlu
Z0NvbmZpZ1JlcXVlc3QaJS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWci
gQGC0+STAl4yTC92Mi97c2VydmluZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn06DnNlcnZpbmdfY29uZmln2kEac2Vy
dmluZ19jb25maWcsdXBkYXRlX21hc2sSuAEKEEdldFNlcnZpbmdDb25maWcSLy5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyLkdldFNlcnZpbmdDb25maWdSZXF1ZXN0GiUuZ29vZ2xlLmNsb3Vk
LnJldGFpbC52Mi5TZXJ2aW5nQ29uZmlnIkyC0+STAj8SPS92Mi97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn3aQQRuYW1lEssBChJM
aXN0U2VydmluZ0NvbmZpZ3MSMS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkxpc3RTZXJ2aW5n
Q29uZmlnc1JlcXVlc3QaMi5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkxpc3RTZXJ2aW5nQ29u
Zmlnc1Jlc3BvbnNlIk6C0+STAj8SPS92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
LyovY2F0YWxvZ3MvKn0vc2VydmluZ0NvbmZpZ3PaQQZwYXJlbnQSzgEKCkFkZENvbnRyb2wS
KS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkFkZENvbnRyb2xSZXF1ZXN0GiUuZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5TZXJ2aW5nQ29uZmlnIm6C0+STAlciUi92Mi97c2VydmluZ19jb25m
aWc9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL3NlcnZpbmdDb25maWdzLyp9
OmFkZENvbnRyb2w6ASraQQ5zZXJ2aW5nX2NvbmZpZxLXAQoNUmVtb3ZlQ29udHJvbBIsLmdv
b2dsZS5jbG91ZC5yZXRhaWwudjIuUmVtb3ZlQ29udHJvbFJlcXVlc3QaJS5nb29nbGUuY2xv
dWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWcicYLT5JMCWiJVL3YyL3tzZXJ2aW5nX2NvbmZp
Zz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn06
cmVtb3ZlQ29udHJvbDoBKtpBDnNlcnZpbmdfY29uZmlnGknKQRVyZXRhaWwuZ29vZ2xlYXBp
cy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3Jt
QsQBChpjb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MkIZU2VydmluZ0NvbmZpZ1NlcnZpY2VQ
cm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2Mi9yZXRhaWxwYjtyZXRh
aWxwYqICBlJFVEFJTKoCFkdvb2dsZS5DbG91ZC5SZXRhaWwuVjLKAhZHb29nbGVcQ2xvdWRc
UmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMkrmNwoHEgUOAO8BAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADUKCQoCAwUSAxcAJQoJ
CgIDBhIDGAAqCggKAQgSAxoAMwoJCgIIJRIDGgAzCggKAQgSAxsASQoJCgIICxIDGwBJCggK
AQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AOgoJCgIICBIDHQA6CggKAQgSAx4AMwoJCgII
ARIDHgAzCggKAQgSAx8AJAoJCgIIJBIDHwAkCggKAQgSAyAAMwoJCgIIKRIDIAAzCggKAQgS
AyEAMgoJCgIILRIDIQAyCjIKAgYAEgQkAHgBGiYgU2VydmljZSBmb3IgbW9kaWZ5aW5nIFNl
cnZpbmdDb25maWcuCgoKCgMGAAESAyQIHAoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsK
AwYAAxIEJgInNwoNCgUGAAOaCBIEJgInNwrkAQoEBgACABIELgI1AxrVASBDcmVhdGVzIGEg
U2VydmluZ0NvbmZpZy4KCiBBIG1heGltdW0gb2YgMTAwIFtTZXJ2aW5nQ29uZmlnXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWddcyBhcmUKIGFsbG93ZWQgaW4gYSBb
Q2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRhbG9nXSwgb3RoZXJ3aXNlIGEK
IEZBSUxFRF9QUkVDT05ESVRJT04gZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAIAARIDLgYZ
CgwKBQYAAgACEgMuGjQKDAoFBgACAAMSAy4/TAoNCgUGAAIABBIELwQyBgoRCgkGAAIABLDK
vCISBC8EMgYKDQoFBgACAAQSBDMENDIKEAoIBgACAASbCAASBDMENDIKaAoEBgACARIEOgJA
AxpaIERlbGV0ZXMgYSBTZXJ2aW5nQ29uZmlnLgoKIFJldHVybnMgYSBOb3RGb3VuZCBlcnJv
ciBpZiB0aGUgU2VydmluZ0NvbmZpZyBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgEBEgM6BhkK
DAoFBgACAQISAzoaNAoMCgUGAAIBAxIDOw8kCg0KBQYAAgEEEgQ8BD4GChEKCQYAAgEEsMq8
IhIEPAQ+BgoMCgUGAAIBBBIDPwQyCg8KCAYAAgEEmwgAEgM/BDIKKAoEBgACAhIEQwJJAxoa
IFVwZGF0ZXMgYSBTZXJ2aW5nQ29uZmlnLgoKDAoFBgACAgESA0MGGQoMCgUGAAICAhIDQxo0
CgwKBQYAAgIDEgNDP0wKDQoFBgACAgQSBEQERwYKEQoJBgACAgSwyrwiEgREBEcGCgwKBQYA
AgIEEgNIBEgKDwoIBgACAgSbCAASA0gESAplCgQGAAIDEgROAlMDGlcgR2V0cyBhIFNlcnZp
bmdDb25maWcuCgogUmV0dXJucyBhIE5vdEZvdW5kIGVycm9yIGlmIHRoZSBTZXJ2aW5nQ29u
ZmlnIGRvZXMgbm90IGV4aXN0LgoKDAoFBgACAwESA04GFgoMCgUGAAIDAhIDThcuCgwKBQYA
AgMDEgNOOUYKDQoFBgACAwQSBE8EUQYKEQoJBgACAwSwyrwiEgRPBFEGCgwKBQYAAgMEEgNS
BDIKDwoIBgACAwSbCAASA1IEMgpACgQGAAIEEgRWAlwDGjIgTGlzdHMgYWxsIFNlcnZpbmdD
b25maWdzIGxpbmtlZCB0byB0aGlzIGNhdGFsb2cuCgoMCgUGAAIEARIDVgYYCgwKBQYAAgQC
EgNWGTIKDAoFBgACBAMSA1cPKQoNCgUGAAIEBBIEWARaBgoRCgkGAAIEBLDKvCISBFgEWgYK
DAoFBgACBAQSA1sENAoPCggGAAIEBJsIABIDWwQ0CscDCgQGAAIFEgRlAmsDGrgDIEVuYWJs
ZXMgYSBDb250cm9sIG9uIHRoZSBzcGVjaWZpZWQgU2VydmluZ0NvbmZpZy4KIFRoZSBjb250
cm9sIGlzIGFkZGVkIGluIHRoZSBsYXN0IHBvc2l0aW9uIG9mIHRoZSBsaXN0IG9mIGNvbnRy
b2xzCiBpdCBiZWxvbmdzIHRvIChlLmcuIGlmIGl0J3MgYSBmYWNldCBzcGVjIGNvbnRyb2wg
aXQgd2lsbCBiZSBhcHBsaWVkCiBpbiB0aGUgbGFzdCBwb3NpdGlvbiBvZiBzZXJ2aW5nQ29u
ZmlnLmZhY2V0U3BlY0lkcykKIFJldHVybnMgYSBBTFJFQURZX0VYSVNUUyBlcnJvciBpZiB0
aGUgY29udHJvbCBoYXMgYWxyZWFkeSBiZWVuIGFwcGxpZWQuCiBSZXR1cm5zIGEgRkFJTEVE
X1BSRUNPTkRJVElPTiBlcnJvciBpZiB0aGUgYWRkaXRpb24gY291bGQgZXhjZWVkIG1heGlt
dW0KIG51bWJlciBvZiBjb250cm9sIGFsbG93ZWQgZm9yIHRoYXQgdHlwZSBvZiBjb250cm9s
LgoKDAoFBgACBQESA2UGEAoMCgUGAAIFAhIDZREiCgwKBQYAAgUDEgNlLToKDQoFBgACBQQS
BGYEaQYKEQoJBgACBQSwyrwiEgRmBGkGCgwKBQYAAgUEEgNqBDwKDwoIBgACBQSbCAASA2oE
PArEAQoEBgACBhIEcQJ3Axq1ASBEaXNhYmxlcyBhIENvbnRyb2wgb24gdGhlIHNwZWNpZmll
ZCBTZXJ2aW5nQ29uZmlnLgogVGhlIGNvbnRyb2wgaXMgcmVtb3ZlZCBmcm9tIHRoZSBTZXJ2
aW5nQ29uZmlnLgogUmV0dXJucyBhIE5PVF9GT1VORCBlcnJvciBpZiB0aGUgQ29udHJvbCBp
cyBub3QgZW5hYmxlZCBmb3IgdGhlCiBTZXJ2aW5nQ29uZmlnLgoKDAoFBgACBgESA3EGEwoM
CgUGAAIGAhIDcRQoCgwKBQYAAgYDEgNxM0AKDQoFBgACBgQSBHIEdQYKEQoJBgACBgSwyrwi
EgRyBHUGCgwKBQYAAgYEEgN2BDwKDwoIBgACBgSbCAASA3YEPAo2CgIEABIFewCMAQEaKSBS
ZXF1ZXN0IGZvciBDcmVhdGVTZXJ2aW5nQ29uZmlnIG1ldGhvZC4KCgoKAwQAARIDewgiCosB
CgQEAAIAEgV+AoEBBBp8IFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgcGFyZW50
LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0
aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH1gCgoMCgUEAAIABRIDfgIICgwKBQQAAgAB
EgN+CQ8KDAoFBAACAAMSA34SEwoOCgUEAAIACBIFfhSBAQMKDwoIBAACAAicCAASA38EKgoP
CgcEAAIACJ8IEgSAAQRPCjYKBAQAAgESBIQBAkwaKCBSZXF1aXJlZC4gVGhlIFNlcnZpbmdD
b25maWcgdG8gY3JlYXRlLgoKDQoFBAACAQYSBIQBAg8KDQoFBAACAQESBIQBEB4KDQoFBAAC
AQMSBIQBISIKDQoFBAACAQgSBIQBI0sKEAoIBAACAQicCAASBIQBJEoK3gEKBAQAAgISBIsB
AkgazwEgUmVxdWlyZWQuIFRoZSBJRCB0byB1c2UgZm9yIHRoZSBTZXJ2aW5nQ29uZmlnLCB3
aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgU2VydmluZ0Nv
bmZpZydzIHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBzaG91bGQgYmUgNC02MyBjaGFy
YWN0ZXJzLCBhbmQgdmFsaWQgY2hhcmFjdGVycwogYXJlIC9bYS16XVswLTldLV8vLgoKDQoF
BAACAgUSBIsBAggKDQoFBAACAgESBIsBCRoKDQoFBAACAgMSBIsBHR4KDQoFBAACAggSBIsB
H0cKEAoIBAACAgicCAASBIsBIEYKNwoCBAESBo8BAJsBARopIFJlcXVlc3QgZm9yIFVwZGF0
ZVNlcnZpbmdDb25maWcgbWV0aG9kLgoKCwoDBAEBEgSPAQgiCjYKBAQBAgASBJEBAkwaKCBS
ZXF1aXJlZC4gVGhlIFNlcnZpbmdDb25maWcgdG8gdXBkYXRlLgoKDQoFBAECAAYSBJEBAg8K
DQoFBAECAAESBJEBEB4KDQoFBAECAAMSBJEBISIKDQoFBAECAAgSBJEBI0sKEAoIBAECAAic
CAASBJEBJEoKjwIKBAQBAgESBJoBAiwagAIgSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0
aGUgcHJvdmlkZWQKIFtTZXJ2aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNl
cnZpbmdDb25maWddIHRvIHVwZGF0ZS4gVGhlCiBmb2xsb3dpbmcgYXJlIE5PVCBzdXBwb3J0
ZWQ6CgogKiBbU2VydmluZ0NvbmZpZy5uYW1lXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNl
cnZpbmdDb25maWcubmFtZV0KCiBJZiBub3Qgc2V0LCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBh
cmUgdXBkYXRlZC4KCg0KBQQBAgEGEgSaAQIbCg0KBQQBAgEBEgSaARwnCg0KBQQBAgEDEgSa
ASorCjcKAgQCEgaeAQCnAQEaKSBSZXF1ZXN0IGZvciBEZWxldGVTZXJ2aW5nQ29uZmlnIG1l
dGhvZC4KCgsKAwQCARIEngEIIgrEAQoEBAICABIGoQECpgEEGrMBIFJlcXVpcmVkLiBUaGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgU2VydmluZ0NvbmZpZyB0byBkZWxldGUuIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2Nh
dGFsb2dzL3tjYXRhbG9nX2lkfS9zZXJ2aW5nQ29uZmlncy97c2VydmluZ19jb25maWdfaWR9
YAoKDQoFBAICAAUSBKEBAggKDQoFBAICAAESBKEBCQ0KDQoFBAICAAMSBKEBEBEKDwoFBAIC
AAgSBqEBEqYBAwoQCggEAgIACJwIABIEogEEKgoRCgcEAgIACJ8IEgajAQSlAQUKNAoCBAMS
BqoBALMBARomIFJlcXVlc3QgZm9yIEdldFNlcnZpbmdDb25maWcgbWV0aG9kLgoKCwoDBAMB
EgSqAQgfCsEBCgQEAwIAEgatAQKyAQQasAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSBTZXJ2aW5nQ29uZmlnIHRvIGdldC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2df
aWR9L3NlcnZpbmdDb25maWdzL3tzZXJ2aW5nX2NvbmZpZ19pZH1gCgoNCgUEAwIABRIErQEC
CAoNCgUEAwIAARIErQEJDQoNCgUEAwIAAxIErQEQEQoPCgUEAwIACBIGrQESsgEDChAKCAQD
AgAInAgAEgSuAQQqChEKBwQDAgAInwgSBq8BBLEBBQo2CgIEBBIGtgEAxgEBGiggUmVxdWVz
dCBmb3IgTGlzdFNlcnZpbmdDb25maWdzIG1ldGhvZC4KCgsKAwQEARIEtgEIIQqJAQoEBAQC
ABIGuQECvAEEGnkgUmVxdWlyZWQuIFRoZSBjYXRhbG9nIHJlc291cmNlIG5hbWUuIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9
L2NhdGFsb2dzL3tjYXRhbG9nX2lkfWAKCg0KBQQEAgAFEgS5AQIICg0KBQQEAgABEgS5AQkP
Cg0KBQQEAgADEgS5ARITCg8KBQQEAgAIEga5ARS8AQMKEAoIBAQCAAicCAASBLoBBCoKDwoH
BAQCAAifCBIEuwEETwqtAQoEBAQCARIEwQECPxqeASBPcHRpb25hbC4gTWF4aW11bSBudW1i
ZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8g
MTAwLiBJZiBhIHZhbHVlIGdyZWF0ZXIgdGhhbiAxMDAgaXMgcHJvdmlkZWQsIGF0IG1vc3Qg
MTAwIHJlc3VsdHMgYXJlCiByZXR1cm5lZC4KCg0KBQQEAgEFEgTBAQIHCg0KBQQEAgEBEgTB
AQgRCg0KBQQEAgEDEgTBARQVCg0KBQQEAgEIEgTBARY+ChAKCAQEAgEInAgAEgTBARc9CooB
CgQEBAICEgTFAQJBGnwgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBh
IHByZXZpb3VzIGBMaXN0U2VydmluZ0NvbmZpZ3NgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8g
cmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQEAgIFEgTFAQIICg0KBQQEAgIB
EgTFAQkTCg0KBQQEAgIDEgTFARYXCg0KBQQEAgIIEgTFARhAChAKCAQEAgIInAgAEgTFARk/
CjcKAgQFEgbJAQDPAQEaKSBSZXNwb25zZSBmb3IgTGlzdFNlcnZpbmdDb25maWdzIG1ldGhv
ZC4KCgsKAwQFARIEyQEIIgo7CgQEBQIAEgTLAQItGi0gQWxsIHRoZSBTZXJ2aW5nQ29uZmln
cyBmb3IgYSBnaXZlbiBjYXRhbG9nLgoKDQoFBAUCAAQSBMsBAgoKDQoFBAUCAAYSBMsBCxgK
DQoFBAUCAAESBMsBGSgKDQoFBAUCAAMSBMsBKywKSgoEBAUCARIEzgECHRo8IFBhZ2luYXRp
b24gdG9rZW4sIGlmIG5vdCByZXR1cm5lZCBpbmRpY2F0ZXMgdGhlIGxhc3QgcGFnZS4KCg0K
BQQFAgEFEgTOAQIICg0KBQQFAgEBEgTOAQkYCg0KBQQFAgEDEgTOARscCi4KAgQGEgbSAQDf
AQEaICBSZXF1ZXN0IGZvciBBZGRDb250cm9sIG1ldGhvZC4KCgsKAwQGARIE0gEIGQq7AQoE
BAYCABIG1QEC2gEEGqoBIFJlcXVpcmVkLiBUaGUgc291cmNlIFNlcnZpbmdDb25maWcgcmVz
b3VyY2UgbmFtZSAuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0
aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfS9zZXJ2aW5nQ29uZmln
cy97c2VydmluZ19jb25maWdfaWR9YAoKDQoFBAYCAAUSBNUBAggKDQoFBAYCAAESBNUBCRcK
DQoFBAYCAAMSBNUBGhsKDwoFBAYCAAgSBtUBHNoBAwoQCggEBgIACJwIABIE1gEEKgoRCgcE
BgIACJ8IEgbXAQTZAQUKpwEKBAQGAgESBN4BAkEamAEgUmVxdWlyZWQuIFRoZSBpZCBvZiB0
aGUgY29udHJvbCB0byBhcHBseS4gQXNzdW1lZCB0byBiZSBpbiB0aGUgc2FtZSBjYXRhbG9n
CiBhcyB0aGUgc2VydmluZyBjb25maWcgLSBpZiBpZCBpcyBub3QgZm91bmQgYSBOT1RfRk9V
TkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEBgIBBRIE3gECCAoNCgUEBgIBARIE3gEJEwoN
CgUEBgIBAxIE3gEWFwoNCgUEBgIBCBIE3gEYQAoQCggEBgIBCJwIABIE3gEZPwoxCgIEBxIG
4gEA7wEBGiMgUmVxdWVzdCBmb3IgUmVtb3ZlQ29udHJvbCBtZXRob2QuCgoLCgMEBwESBOIB
CBwKuwEKBAQHAgASBuUBAuoBBBqqASBSZXF1aXJlZC4gVGhlIHNvdXJjZSBTZXJ2aW5nQ29u
ZmlnIHJlc291cmNlIG5hbWUgLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVy
fS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vc2Vydmlu
Z0NvbmZpZ3Mve3NlcnZpbmdfY29uZmlnX2lkfWAKCg0KBQQHAgAFEgTlAQIICg0KBQQHAgAB
EgTlAQkXCg0KBQQHAgADEgTlARobCg8KBQQHAgAIEgblARzqAQMKEAoIBAcCAAicCAASBOYB
BCoKEQoHBAcCAAifCBIG5wEE6QEFCnMKBAQHAgESBO4BAkEaZSBSZXF1aXJlZC4gVGhlIGlk
IG9mIHRoZSBjb250cm9sIHRvIGFwcGx5LiBBc3N1bWVkIHRvIGJlIGluIHRoZSBzYW1lIGNh
dGFsb2cKIGFzIHRoZSBzZXJ2aW5nIGNvbmZpZy4KCg0KBQQHAgEFEgTuAQIICg0KBQQHAgEB
EgTuAQkTCg0KBQQHAgEDEgTuARYXCg0KBQQHAgEIEgTuARhAChAKCAQHAgEInAgAEgTuARk/
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest ===
    # Fields for CreateServingConfigRequest
    # Field: parent Type: 9 ()
    # Field: serving_config Type: 11 (.google.cloud.retail.v2.ServingConfig)
    # Field: serving_config_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ServingConfigService::UpdateServingConfigRequest ===
    # Fields for UpdateServingConfigRequest
    # Field: serving_config Type: 11 (.google.cloud.retail.v2.ServingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::ServingConfigService::DeleteServingConfigRequest ===
    # Fields for DeleteServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ServingConfigService::GetServingConfigRequest ===
    # Fields for GetServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ServingConfigService::ListServingConfigsRequest ===
    # Fields for ListServingConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ServingConfigService::ListServingConfigsResponse ===
    # Fields for ListServingConfigsResponse
    # Field: serving_configs Type: 11 (.google.cloud.retail.v2.ServingConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ServingConfigService::AddControlRequest ===
    # Fields for AddControlRequest
    # Field: serving_config Type: 9 ()
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ServingConfigService::RemoveControlRequest ===
    # Fields for RemoveControlRequest
    # Field: serving_config Type: 9 ()
    # Field: control_id Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2::ServingConfigService::ServingConfigServiceClient ===
package Google::Cloud::Retail::V2::ServingConfigService::ServingConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::ServingConfigService::ServingConfigServiceClient

Client stub representing the remote C<ServingConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig',
    });
}

sub delete_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::DeleteServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'DeleteServingConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::UpdateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig',
    });
}

sub get_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::GetServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'GetServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig',
    });
}

sub list_serving_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::ListServingConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'ListServingConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ServingConfigService::ListServingConfigsResponse',
    });
}

sub add_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::AddControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'AddControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig',
    });
}

sub remove_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ServingConfigService::RemoveControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'RemoveControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::ServingConfigService - Compiled Protocol Buffers messages for google/cloud/retail/v2/serving_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ServingConfigService;

    my $msg = Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest->new({
        parent => $parent,
        serving_config => $serving_config,
        serving_config_id => $serving_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/serving_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest

Request for CreateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ServingConfig::ServingConfig>)

Required. The ServingConfig to create.

=item * C<< $msg->serving_config_id() >> / C<< $msg->serving_config_id($value) >>

Type: C<String>

Required. The ID to use for the ServingConfig, which will become the final
component of the ServingConfig's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Retail::V2::ServingConfigService::UpdateServingConfigRequest

Request for UpdateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ServingConfig::ServingConfig>)

Required. The ServingConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[ServingConfig][google.cloud.retail.v2.ServingConfig] to update. The
following are NOT supported:

* [ServingConfig.name][google.cloud.retail.v2.ServingConfig.name]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2::ServingConfigService::DeleteServingConfigRequest

Request for DeleteServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Retail::V2::ServingConfigService::GetServingConfigRequest

Request for GetServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Retail::V2::ServingConfigService::ListServingConfigsRequest

Request for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The catalog resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

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

=head2 Google::Cloud::Retail::V2::ServingConfigService::ListServingConfigsResponse

Response for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_configs() >> / C<< $msg->serving_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ServingConfig::ServingConfig>)

All the ServingConfigs for a given catalog.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head2 Google::Cloud::Retail::V2::ServingConfigService::AddControlRequest

Request for AddControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. The source ServingConfig resource name . Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The id of the control to apply. Assumed to be in the same catalog
as the serving config - if id is not found a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Retail::V2::ServingConfigService::RemoveControlRequest

Request for RemoveControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. The source ServingConfig resource name . Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The id of the control to apply. Assumed to be in the same catalog
as the serving config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::ServingConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
