package Google::Cloud::Discoveryengine::V1beta::DocumentService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Document };
    eval { require Google::Cloud::Discoveryengine::V1beta::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1beta::PurgeConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9kb2N1bWVudF9zZXJ2aWNl
LnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRocZ29vZ2xlL2Fw
aS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdv
b2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL2RvY3VtZW50LnByb3RvGjdnb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9pbXBvcnRfY29uZmlnLnByb3RvGjZn
b29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9wdXJnZV9jb25maWcucHJvdG8a
I2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYv
ZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIlkKEkdldERvY3VtZW50UmVxdWVzdBJDCgRuYW1l
GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVu
dFIEbmFtZSKZAQoUTGlzdERvY3VtZW50c1JlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6
QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9CcmFuY2hSBnBhcmVudBIbCglw
YWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tl
biKMAQoVTGlzdERvY3VtZW50c1Jlc3BvbnNlEksKCWRvY3VtZW50cxgBIAMoCzItLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50Uglkb2N1bWVudHMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuItQBChVDcmVhdGVEb2N1bWVu
dFJlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29n
bGVhcGlzLmNvbS9CcmFuY2hSBnBhcmVudBJOCghkb2N1bWVudBgCIAEoCzItLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50QgPgQQJSCGRvY3VtZW50EiQK
C2RvY3VtZW50X2lkGAMgASgJQgPgQQJSCmRvY3VtZW50SWQiyQEKFVVwZGF0ZURvY3VtZW50
UmVxdWVzdBJOCghkb2N1bWVudBgBIAEoCzItLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkRvY3VtZW50QgPgQQJSCGRvY3VtZW50EiMKDWFsbG93X21pc3NpbmcYAiAB
KAhSDGFsbG93TWlzc2luZxI7Cgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siXAoVRGVsZXRlRG9jdW1lbnRSZXF1ZXN0EkMKBG5h
bWUYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RvY3Vt
ZW50UgRuYW1lIucECiBCYXRjaEdldERvY3VtZW50c01ldGFkYXRhUmVxdWVzdBJFCgZwYXJl
bnQYASABKAlCLeBBAvpBJwolZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0JyYW5j
aFIGcGFyZW50EmwKB21hdGNoZXIYAiABKAsyTS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5CYXRjaEdldERvY3VtZW50c01ldGFkYXRhUmVxdWVzdC5NYXRjaGVyQgPg
QQJSB21hdGNoZXIaIQoLVXJpc01hdGNoZXISEgoEdXJpcxgBIAMoCVIEdXJpcxpkCgtGaGly
TWF0Y2hlchJVCg5maGlyX3Jlc291cmNlcxgBIAMoCUIu4EEC+kEoCiZoZWFsdGhjYXJlLmdv
b2dsZWFwaXMuY29tL0ZoaXJSZXNvdXJjZVINZmhpclJlc291cmNlcxqEAgoHTWF0Y2hlchJ2
Cgx1cmlzX21hdGNoZXIYASABKAsyUS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5CYXRjaEdldERvY3VtZW50c01ldGFkYXRhUmVxdWVzdC5VcmlzTWF0Y2hlckgAUgt1
cmlzTWF0Y2hlchJ2CgxmaGlyX21hdGNoZXIYAiABKAsyUS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5CYXRjaEdldERvY3VtZW50c01ldGFkYXRhUmVxdWVzdC5GaGly
TWF0Y2hlckgAUgtmaGlyTWF0Y2hlckIJCgdtYXRjaGVyIpIGCiFCYXRjaEdldERvY3VtZW50
c01ldGFkYXRhUmVzcG9uc2UShgEKEmRvY3VtZW50c19tZXRhZGF0YRgBIAMoCzJXLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkJhdGNoR2V0RG9jdW1lbnRzTWV0YWRh
dGFSZXNwb25zZS5Eb2N1bWVudE1ldGFkYXRhUhFkb2N1bWVudHNNZXRhZGF0YRqMBAoQRG9j
dW1lbnRNZXRhZGF0YRKJAQoNbWF0Y2hlcl92YWx1ZRgCIAEoCzJkLmdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkJhdGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFSZXNwb25z
ZS5Eb2N1bWVudE1ldGFkYXRhLk1hdGNoZXJWYWx1ZVIMbWF0Y2hlclZhbHVlEmIKBXN0YXRl
GAMgASgOMkwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQmF0Y2hHZXRE
b2N1bWVudHNNZXRhZGF0YVJlc3BvbnNlLlN0YXRlUgVzdGF0ZRJKChNsYXN0X3JlZnJlc2hl
ZF90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIRbGFzdFJlZnJlc2hl
ZFRpbWUSMgoVZGF0YV9pbmdlc3Rpb25fc291cmNlGAUgASgJUhNkYXRhSW5nZXN0aW9uU291
cmNlGocBCgxNYXRjaGVyVmFsdWUSEgoDdXJpGAEgASgJSABSA3VyaRJSCg1maGlyX3Jlc291
cmNlGAIgASgJQiv6QSgKJmhlYWx0aGNhcmUuZ29vZ2xlYXBpcy5jb20vRmhpclJlc291cmNl
SABSDGZoaXJSZXNvdXJjZUIPCg1tYXRjaGVyX3ZhbHVlIlUKBVN0YXRlEhUKEVNUQVRFX1VO
U1BFQ0lGSUVEEAASCwoHSU5ERVhFRBABEhYKEk5PVF9JTl9UQVJHRVRfU0lURRACEhAKDE5P
VF9JTl9JTkRFWBADMp8YCg9Eb2N1bWVudFNlcnZpY2USrAIKC0dldERvY3VtZW50EjcuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuR2V0RG9jdW1lbnRSZXF1ZXN0Gi0u
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnQitAGC0+STAqYB
EkkvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL2Jy
YW5jaGVzLyovZG9jdW1lbnRzLyp9WlkSVy92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50
cy8qfdpBBG5hbWUSvwIKDUxpc3REb2N1bWVudHMSOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5MaXN0RG9jdW1lbnRzUmVxdWVzdBo6Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkxpc3REb2N1bWVudHNSZXNwb25zZSK2AYLT5JMCpgESSS92
MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFu
Y2hlcy8qfS9kb2N1bWVudHNaWRJXL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMvKn0vZG9jdW1lbnRz
2kEGcGFyZW50Et0CCg5DcmVhdGVEb2N1bWVudBI6Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkNyZWF0ZURvY3VtZW50UmVxdWVzdBotLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50It8BgtPkkwK6ASJJL3YxYmV0YS97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyp9L2RvY3Vt
ZW50czoIZG9jdW1lbnRaYyJXL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
LyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMvKn0vZG9jdW1lbnRzOghk
b2N1bWVudNpBG3BhcmVudCxkb2N1bWVudCxkb2N1bWVudF9pZBLoAgoOVXBkYXRlRG9jdW1l
bnQSOi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5VcGRhdGVEb2N1bWVu
dFJlcXVlc3QaLS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVu
dCLqAYLT5JMCzAEyUi92MWJldGEve2RvY3VtZW50Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMvKi9kb2N1bWVudHMvKn06CGRvY3VtZW50Wmwy
YC92MWJldGEve2RvY3VtZW50Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qfToIZG9jdW1lbnTa
QRRkb2N1bWVudCx1cGRhdGVfbWFzaxKbAgoORGVsZXRlRG9jdW1lbnQSOi5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EZWxldGVEb2N1bWVudFJlcXVlc3QaFi5nb29n
bGUucHJvdG9idWYuRW1wdHkitAGC0+STAqYBKkkvdjFiZXRhL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyovZG9jdW1lbnRzLyp9WlkqVy92
MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFT
dG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qfdpBBG5hbWUSrgMKD0ltcG9ydERvY3Vt
ZW50cxI7Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkltcG9ydERvY3Vt
ZW50c1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIr4CgtPkkwK6ASJQ
L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL2Jy
YW5jaGVzLyp9L2RvY3VtZW50czppbXBvcnQ6ASpaYyJeL3YxYmV0YS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMv
Kn0vZG9jdW1lbnRzOmltcG9ydDoBKspBego7Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuSW1wb3J0RG9jdW1lbnRzUmVzcG9uc2USO2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkltcG9ydERvY3VtZW50c01ldGFkYXRhEqgDCg5QdXJnZURvY3Vt
ZW50cxI6Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlB1cmdlRG9jdW1l
bnRzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iugKC0+STArgBIk8v
djFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJh
bmNoZXMvKn0vZG9jdW1lbnRzOnB1cmdlOgEqWmIiXS92MWJldGEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyp9
L2RvY3VtZW50czpwdXJnZToBKspBeAo6Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuUHVyZ2VEb2N1bWVudHNSZXNwb25zZRI6Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuUHVyZ2VEb2N1bWVudHNNZXRhZGF0YRKDAwoZQmF0Y2hHZXREb2N1bWVu
dHNNZXRhZGF0YRJFLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkJhdGNo
R2V0RG9jdW1lbnRzTWV0YWRhdGFSZXF1ZXN0GkYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuQmF0Y2hHZXREb2N1bWVudHNNZXRhZGF0YVJlc3BvbnNlItYBgtPkkwLG
ARJZL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8q
L2JyYW5jaGVzLyp9L2JhdGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFaaRJnL3YxYmV0YS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyov
YnJhbmNoZXMvKn0vYmF0Y2hHZXREb2N1bWVudHNNZXRhZGF0YdpBBnBhcmVudBrPAcpBHmRp
c2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBqgFodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0ZUKbAgonY29tLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhREb2N1bWVudFNlcnZpY2VQcm90b1AB
WlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292
ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29n
bGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3Zl
cnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJl
dGFKq3MKBxIFDgDMAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACwKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgID
BBIDFgA8CgkKAgMFEgMXAEEKCQoCAwYSAxgAQAoJCgIDBxIDGQAtCgkKAgMIEgMaACUKCQoC
AwkSAxsAKgoJCgIDChIDHAApCggKAQgSAx4AQAoJCgIIJRIDHgBACggKAQgSAx8AaAoJCgII
CxIDHwBoCggKAQgSAyAAIgoJCgIIChIDIAAiCggKAQgSAyEANQoJCgIICBIDIQA1CggKAQgS
AyIAQAoJCgIIARIDIgBACggKAQgSAyMALQoJCgIIJBIDIwAtCggKAQgSAyQAQAoJCgIIKRID
JABACggKAQgSAyUAPwoJCgIILRIDJQA/CoYBCgIGABIFKgCxAQEaeSBTZXJ2aWNlIGZvciBp
bmdlc3RpbmcKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuRG9jdW1lbnRdIGluZm9ybWF0aW9uIG9mIHRoZQogY3VzdG9tZXIncyB3ZWJzaXRlLgoK
CgoDBgABEgMqCBcKCgoDBgADEgMrAkYKDAoFBgADmQgSAysCRgoLCgMGAAMSBCwCL0oKDQoF
BgADmggSBCwCL0oKUAoEBgACABIEMgI6AxpCIEdldHMgYSBbRG9jdW1lbnRdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XS4KCgwKBQYAAgABEgMyBhEK
DAoFBgACAAISAzISJAoMCgUGAAIAAxIDMi83Cg0KBQYAAgAEEgQzBDgGChEKCQYAAgAEsMq8
IhIEMwQ4BgoMCgUGAAIABBIDOQQyCg8KCAYAAgAEmwgAEgM5BDIKWQoEBgACARIEPQJFAxpL
IEdldHMgYSBsaXN0IG9mIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuRG9jdW1lbnRdcy4KCgwKBQYAAgEBEgM9BhMKDAoFBgACAQISAz0UKAoMCgUG
AAIBAxIDPTNICg0KBQYAAgEEEgQ+BEMGChEKCQYAAgEEsMq8IhIEPgRDBgoMCgUGAAIBBBID
RAQ0Cg8KCAYAAgEEmwgAEgNEBDQKUwoEBgACAhIESAJSAxpFIENyZWF0ZXMgYSBbRG9jdW1l
bnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XS4KCgwK
BQYAAgIBEgNIBhQKDAoFBgACAgISA0gVKgoMCgUGAAICAxIDSDU9Cg0KBQYAAgIEEgRJBFAG
ChEKCQYAAgIEsMq8IhIESQRQBgoMCgUGAAICBBIDUQRJCg8KCAYAAgIEmwgAEgNRBEkKUwoE
BgACAxIEVQJfAxpFIFVwZGF0ZXMgYSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkRvY3VtZW50XS4KCgwKBQYAAgMBEgNVBhQKDAoFBgACAwISA1UV
KgoMCgUGAAIDAxIDVTU9Cg0KBQYAAgMEEgRWBF0GChEKCQYAAgMEsMq8IhIEVgRdBgoMCgUG
AAIDBBIDXgRCCg8KCAYAAgMEmwgAEgNeBEIKUwoEBgACBBIEYgJqAxpFIERlbGV0ZXMgYSBb
RG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50
XS4KCgwKBQYAAgQBEgNiBhQKDAoFBgACBAISA2IVKgoMCgUGAAIEAxIDYjVKCg0KBQYAAgQE
EgRjBGgGChEKCQYAAgQEsMq8IhIEYwRoBgoMCgUGAAIEBBIDaQQyCg8KCAYAAgQEmwgAEgNp
BDIKsAIKBAYAAgUSBXMCgQEDGqACIEJ1bGsgaW1wb3J0IG9mIG11bHRpcGxlCiBbRG9jdW1l
bnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XXMuIFJl
cXVlc3QKIHByb2Nlc3NpbmcgbWF5IGJlIHN5bmNocm9ub3VzLiBOb24tZXhpc3RpbmcgaXRl
bXMgYXJlIGNyZWF0ZWQuCgogTm90ZTogSXQgaXMgcG9zc2libGUgZm9yIGEgc3Vic2V0IG9m
IHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5E
b2N1bWVudF1zIHRvIGJlCiBzdWNjZXNzZnVsbHkgdXBkYXRlZC4KCgwKBQYAAgUBEgNzBhUK
DAoFBgACBQISA3MWLAoMCgUGAAIFAxIDdA8rCg0KBQYAAgUEEgR1BHwGChEKCQYAAgUEsMq8
IhIEdQR8BgoOCgUGAAIFBBIFfQSAAQYKEAoHBgACBQSZCBIFfQSAAQYKyQYKBAYAAgYSBpQB
AqIBAxq4BiBQZXJtYW5lbnRseSBkZWxldGVzIGFsbCBzZWxlY3RlZAogW0RvY3VtZW50XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudF1zIGluIGEgYnJh
bmNoLgoKIFRoaXMgcHJvY2VzcyBpcyBhc3luY2hyb25vdXMuIERlcGVuZGluZyBvbiB0aGUg
bnVtYmVyIG9mCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkRvY3VtZW50XXMgdG8gYmUgZGVsZXRlZCwKIHRoaXMgb3BlcmF0aW9uIGNhbiB0YWtl
IGhvdXJzIHRvIGNvbXBsZXRlLiBCZWZvcmUgdGhlIGRlbGV0ZSBvcGVyYXRpb24KIGNvbXBs
ZXRlcywgc29tZSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkRvY3VtZW50XXMKIG1pZ2h0IHN0aWxsIGJlIHJldHVybmVkIGJ5CiBbRG9jdW1lbnRT
ZXJ2aWNlLkdldERvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5Eb2N1bWVudFNlcnZpY2UuR2V0RG9jdW1lbnRdCiBvcgogW0RvY3VtZW50U2VydmljZS5M
aXN0RG9jdW1lbnRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1
bWVudFNlcnZpY2UuTGlzdERvY3VtZW50c10uCgogVG8gZ2V0IGEgbGlzdCBvZiB0aGUKIFtE
b2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRd
cyB0byBiZSBkZWxldGVkLAogc2V0CiBbUHVyZ2VEb2N1bWVudHNSZXF1ZXN0LmZvcmNlXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5QdXJnZURvY3VtZW50c1JlcXVl
c3QuZm9yY2VdCiB0byBmYWxzZS4KCg0KBQYAAgYBEgSUAQYUCg0KBQYAAgYCEgSUARUqCg0K
BQYAAgYDEgSVAQ8rCg8KBQYAAgYEEgaWAQSdAQYKEwoJBgACBgSwyrwiEgaWAQSdAQYKDwoF
BgACBgQSBp4BBKEBBgoRCgcGAAIGBJkIEgaeAQShAQYKlAEKBAYAAgcSBqcBArABAxqDASBH
ZXRzIGluZGV4IGZyZXNobmVzcyBtZXRhZGF0YSBmb3IKIFtEb2N1bWVudF1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdcy4gU3VwcG9ydGVkIGZvcgog
d2Vic2l0ZSBzZWFyY2ggb25seS4KCg0KBQYAAgcBEgSnAQYfCg0KBQYAAgcCEgSnASBACg0K
BQYAAgcDEgSoAQ8wCg8KBQYAAgcEEgapAQSuAQYKEwoJBgACBwSwyrwiEgapAQSuAQYKDQoF
BgACBwQSBK8BBDQKEAoIBgACBwSbCAASBK8BBDQKjAEKAgQAEga2AQDHAQEafiBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbRG9jdW1lbnRTZXJ2aWNlLkdldERvY3VtZW50XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudFNlcnZpY2UuR2V0RG9jdW1lbnRd
CiBtZXRob2QuCgoLCgMEAAESBLYBCBoKuwQKBAQAAgASBsEBAsYBBBqqBCBSZXF1aXJlZC4g
RnVsbCByZXNvdXJjZSBuYW1lIG9mCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkRvY3VtZW50XSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0
b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNoZXMve2JyYW5jaH0vZG9jdW1lbnRzL3tkb2N1bWVu
dH1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGFjY2Vz
cyB0aGUKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
RG9jdW1lbnRdLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEg
YFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgcmVxdWVz
dGVkIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9j
dW1lbnRdCiBkb2VzIG5vdCBleGlzdCwgYSBgTk9UX0ZPVU5EYCBlcnJvciBpcyByZXR1cm5l
ZC4KCg0KBQQAAgAFEgTBAQIICg0KBQQAAgABEgTBAQkNCg0KBQQAAgADEgTBARARCg8KBQQA
AgAIEgbBARLGAQMKEAoIBAACAAicCAASBMIBBCoKEQoHBAACAAifCBIGwwEExQEFCpEBCgIE
ARIGzAEA7wEBGoIBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEb2N1bWVudFNlcnZpY2UuTGlz
dERvY3VtZW50c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1l
bnRTZXJ2aWNlLkxpc3REb2N1bWVudHNdCiBtZXRob2QuCgoLCgMEAQESBMwBCBwK5AMKBAQB
AgASBtYBAtsBBBrTAyBSZXF1aXJlZC4gVGhlIHBhcmVudCBicmFuY2ggcmVzb3VyY2UgbmFt
ZSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNo
ZXMve2JyYW5jaH1gLgogVXNlIGBkZWZhdWx0X2JyYW5jaGAgYXMgdGhlIGJyYW5jaCBJRCwg
dG8gbGlzdCBkb2N1bWVudHMgdW5kZXIgdGhlIGRlZmF1bHQKIGJyYW5jaC4KCiBJZiB0aGUg
Y2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBsaXN0CiBbRG9jdW1lbnRdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XXMgdW5kZXIgdGhp
cwogYnJhbmNoLCByZWdhcmRsZXNzIG9mIHdoZXRoZXIgb3Igbm90IHRoaXMgYnJhbmNoIGV4
aXN0cywgYQogYFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQB
AgAFEgTWAQIICg0KBQQBAgABEgTWAQkPCg0KBQQBAgADEgTWARITCg8KBQQBAgAIEgbWARTb
AQMKEAoIBAECAAicCAASBNcBBCoKEQoHBAECAAifCBIG2AEE2gEFCpYCCgQEAQIBEgTiAQIW
GocCIE1heGltdW0gbnVtYmVyIG9mIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuRG9jdW1lbnRdcwogdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwg
ZGVmYXVsdHMgdG8gMTAwLiBUaGUgbWF4aW11bSBhbGxvd2VkIHZhbHVlIGlzCiAxMDAwLiBW
YWx1ZXMgYWJvdmUgMTAwMCBhcmUgc2V0IHRvIDEwMDAuCgogSWYgdGhpcyBmaWVsZCBpcyBu
ZWdhdGl2ZSwgYW4gYElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoF
BAECAQUSBOIBAgcKDQoFBAECAQESBOIBCBEKDQoFBAECAQMSBOIBFBUKxQQKBAQBAgISBO4B
AhgatgQgQSBwYWdlIHRva2VuCiBbTGlzdERvY3VtZW50c1Jlc3BvbnNlLm5leHRfcGFnZV90
b2tlbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdERvY3VtZW50
c1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0sCiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMK
IFtEb2N1bWVudFNlcnZpY2UuTGlzdERvY3VtZW50c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuRG9jdW1lbnRTZXJ2aWNlLkxpc3REb2N1bWVudHNdCiBjYWxsLiBQ
cm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBh
Z2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBbRG9jdW1lbnRT
ZXJ2aWNlLkxpc3REb2N1bWVudHNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkRvY3VtZW50U2VydmljZS5MaXN0RG9jdW1lbnRzXQogbXVzdCBtYXRjaCB0aGUgY2Fs
bCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLiBPdGhlcndpc2UsIGFuCiBgSU5WQUxJ
RF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAQICBRIE7gECCAoNCgUEAQIC
ARIE7gEJEwoNCgUEAQICAxIE7gEWFwqSAQoCBAISBvQBAP0BARqDASBSZXNwb25zZSBtZXNz
YWdlIGZvcgogW0RvY3VtZW50U2VydmljZS5MaXN0RG9jdW1lbnRzXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudFNlcnZpY2UuTGlzdERvY3VtZW50c10K
IG1ldGhvZC4KCgsKAwQCARIE9AEIHQpOCgQEAgIAEgT2AQIiGkAgVGhlIFtEb2N1bWVudF1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdcy4KCg0KBQQC
AgAEEgT2AQIKCg0KBQQCAgAGEgT2AQsTCg0KBQQCAgABEgT2ARQdCg0KBQQCAgADEgT2ASAh
CuoBCgQEAgIBEgT8AQIdGtsBIEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcwogW0xpc3RE
b2N1bWVudHNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkxpc3REb2N1bWVudHNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRyaWV2
ZSB0aGUgbmV4dCBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBu
bwogc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQCAgEFEgT8AQIICg0KBQQCAgEBEgT8AQkYCg0K
BQQCAgEDEgT8ARscCpMBCgIEAxIGggIAogIBGoQBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtE
b2N1bWVudFNlcnZpY2UuQ3JlYXRlRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFiZXRhLkRvY3VtZW50U2VydmljZS5DcmVhdGVEb2N1bWVudF0KIG1ldGhvZC4K
CgsKAwQDARIEggIIHQqtAQoEBAMCABIGhQICigIEGpwBIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFf
c3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9YC4KCg0KBQQDAgAFEgSFAgIICg0KBQQDAgABEgSF
AgkPCg0KBQQDAgADEgSFAhITCg8KBQQDAgAIEgaFAhSKAgMKEAoIBAMCAAicCAASBIYCBCoK
EQoHBAMCAAifCBIGhwIEiQIFCmIKBAQDAgESBI4CAkEaVCBSZXF1aXJlZC4gVGhlIFtEb2N1
bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdIHRv
CiBjcmVhdGUuCgoNCgUEAwIBBhIEjgICCgoNCgUEAwIBARIEjgILEwoNCgUEAwIBAxIEjgIW
FwoNCgUEAwIBCBIEjgIYQAoQCggEAwIBCJwIABIEjgIZPwrABgoEBAMCAhIEoQICQhqxBiBS
ZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XSwgd2hpY2ggYmVjb21lcyB0aGUK
IGZpbmFsIGNvbXBvbmVudCBvZiB0aGUKIFtEb2N1bWVudC5uYW1lXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudC5uYW1lXS4KCiBJZiB0aGUgY2FsbGVy
IGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBjcmVhdGUgdGhlCiBbRG9jdW1lbnRdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XSwgcmVnYXJkbGVz
cyBvZgogd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAg
ZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBmaWVsZCBtdXN0IGJlIHVuaXF1ZSBhbW9uZyBh
bGwKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9j
dW1lbnRdcyB3aXRoIHRoZSBzYW1lCiBbcGFyZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5DcmVhdGVEb2N1bWVudFJlcXVlc3QucGFyZW50XS4KIE90aGVyd2lz
ZSwgYW4gYEFMUkVBRFlfRVhJU1RTYCBlcnJvciBpcyByZXR1cm5lZC4KCiBUaGlzIGZpZWxk
IG11c3QgY29uZm9ybSB0byBbUkZDLTEwMzRdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRt
bC9yZmMxMDM0KQogc3RhbmRhcmQgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMjggY2hhcmFj
dGVycy4gT3RoZXJ3aXNlLCBhbgogYElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVy
bmVkLgoKDQoFBAMCAgUSBKECAggKDQoFBAMCAgESBKECCRQKDQoFBAMCAgMSBKECFxgKDQoF
BAMCAggSBKECGUEKEAoIBAMCAgicCAASBKECGkAKkwEKAgQEEganAgC8AgEahAEgUmVxdWVz
dCBtZXNzYWdlIGZvcgogW0RvY3VtZW50U2VydmljZS5VcGRhdGVEb2N1bWVudF1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRTZXJ2aWNlLlVwZGF0ZURv
Y3VtZW50XQogbWV0aG9kLgoKCwoDBAQBEgSnAggdCuUDCgQEBAIAEgSyAgJBGtYDIFJlcXVp
cmVkLiBUaGUgZG9jdW1lbnQgdG8gdXBkYXRlL2NyZWF0ZS4KCiBJZiB0aGUgY2FsbGVyIGRv
ZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBbRG9jdW1lbnRdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XSwgcmVnYXJkbGVzcyBv
Zgogd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJy
b3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdIHRvIHVwZGF0ZQogZG9lcyBub3QgZXhpc3Qg
YW5kCiBbYWxsb3dfbWlzc2luZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuVXBkYXRlRG9jdW1lbnRSZXF1ZXN0LmFsbG93X21pc3NpbmddCiBpcyBub3Qgc2V0LCBh
IGBOT1RfRk9VTkRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAQCAAYSBLICAgoKDQoFBAQC
AAESBLICCxMKDQoFBAQCAAMSBLICFhcKDQoFBAQCAAgSBLICGEAKEAoIBAQCAAicCAASBLIC
GT8KwAEKBAQEAgESBLcCAhkasQEgSWYgc2V0IHRvIGB0cnVlYCBhbmQgdGhlCiBbRG9jdW1l
bnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XSBpcyBu
b3QgZm91bmQsIGEKIG5ldyBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkRvY3VtZW50XSBpcyBiZSBjcmVhdGVkLgoKDQoFBAQCAQUSBLcCAgYKDQoF
BAQCAQESBLcCBxQKDQoFBAQCAQMSBLcCFxgKgQEKBAQEAgISBLsCAiwacyBJbmRpY2F0ZXMg
d2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZCBpbXBvcnRlZCAnZG9jdW1lbnQnIHRvIHVw
ZGF0ZS4gSWYKIG5vdCBzZXQsIGJ5IGRlZmF1bHQgdXBkYXRlcyBhbGwgZmllbGRzLgoKDQoF
BAQCAgYSBLsCAhsKDQoFBAQCAgESBLsCHCcKDQoFBAQCAgMSBLsCKisKkwEKAgQFEgbBAgDS
AgEahAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RvY3VtZW50U2VydmljZS5EZWxldGVEb2N1
bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRTZXJ2
aWNlLkRlbGV0ZURvY3VtZW50XQogbWV0aG9kLgoKCwoDBAUBEgTBAggdCrsECgQEBQIAEgbM
AgLRAgQaqgQgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0RvY3VtZW50XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudF0sIHN1Y2ggYXMK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMv
e2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9
L2RvY3VtZW50cy97ZG9jdW1lbnR9YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUg
cGVybWlzc2lvbiB0byBkZWxldGUgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XSwgcmVnYXJkbGVzcyBvZgogd2hldGhlciBv
ciBub3QgaXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMgcmV0dXJu
ZWQuCgogSWYgdGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuRG9jdW1lbnRdIHRvIGRlbGV0ZQogZG9lcyBub3QgZXhpc3QsIGEgYE5PVF9GT1VO
RGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEBQIABRIEzAICCAoNCgUEBQIAARIEzAIJDQoN
CgUEBQIAAxIEzAIQEQoPCgUEBQIACBIGzAIS0QIDChAKCAQFAgAInAgAEgTNAgQqChEKBwQF
AgAInwgSBs4CBNACBQqpAQoCBAYSBtcCAIcDARqaASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
RG9jdW1lbnRTZXJ2aWNlLkJhdGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50U2VydmljZS5CYXRjaEdldERvY3Vt
ZW50c01ldGFkYXRhXQogbWV0aG9kLgoKCwoDBAYBEgTXAggoCmsKBAQGAwASBtoCAt0CAxpb
IE1hdGNoZXIgZm9yIHRoZSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkRvY3VtZW50XXMKIGJ5IGV4YWN0IHVyaXMuCgoNCgUEBgMAARIE2gIKFQot
CgYEBgMAAgASBNwCBB0aHSBUaGUgZXhhY3QgVVJJcyB0byBtYXRjaCBieS4KCg8KBwQGAwAC
AAQSBNwCBAwKDwoHBAYDAAIABRIE3AINEwoPCgcEBgMAAgABEgTcAhQYCg8KBwQGAwACAAMS
BNwCGxwKdAoEBAYDARIG4QIC6wIDGmQgTWF0Y2hlciBmb3IgdGhlIFtEb2N1bWVudF1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdcwogYnkgRkhJUiBy
ZXNvdXJjZSBuYW1lcy4KCg0KBQQGAwEBEgThAgoVCsMBCgYEBgMBAgASBuUCBOoCBhqwASBS
ZXF1aXJlZC4gVGhlIEZISVIgcmVzb3VyY2VzIHRvIG1hdGNoIGJ5LgogRm9ybWF0OgogcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0
fS9maGlyU3RvcmVzL3tmaGlyX3N0b3JlfS9maGlyL3tyZXNvdXJjZV90eXBlfS97Zmhpcl9y
ZXNvdXJjZV9pZH0KCg8KBwQGAwECAAQSBOUCBAwKDwoHBAYDAQIABRIE5QINEwoPCgcEBgMB
AgABEgTlAhQiCg8KBwQGAwECAAMSBOUCJSYKEQoHBAYDAQIACBIG5QIn6gIFChIKCgQGAwEC
AAicCAASBOYCBiwKEwoJBAYDAQIACJ8IEgbnAgbpAgcKiAEKBAQGAwISBu8CAvkCAxp4IE1h
dGNoZXIgZm9yIHRoZSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkRvY3VtZW50XXMuCiBDdXJyZW50bHkgc3VwcG9ydHMgbWF0Y2hpbmcgYnkgZXhh
Y3QgVVJJcy4KCg0KBQQGAwIBEgTvAgoRCl8KBgQGAwIIABIG8gIE+AIFGk0gTWF0Y2hlciBm
b3IgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkRvY3VtZW50XXMuCgoPCgcEBgMCCAABEgTyAgoRCigKBgQGAwICABIE9AIGIxoYIE1hdGNo
ZXIgYnkgZXhhY3QgVVJJcy4KCg8KBwQGAwICAAYSBPQCBhEKDwoHBAYDAgIAARIE9AISHgoP
CgcEBgMCAgADEgT0AiEiCjEKBgQGAwICARIE9wIGIxohIE1hdGNoZXIgYnkgRkhJUiByZXNv
dXJjZSBuYW1lcy4KCg8KBwQGAwICAQYSBPcCBhEKDwoHBAYDAgIBARIE9wISHgoPCgcEBgMC
AgEDEgT3AiEiCrQBCgQEBgIAEgb9AgKCAwQaowEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgYnJh
bmNoIHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2Rh
dGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9YC4KCg0KBQQGAgAFEgT9AgIICg0KBQQGAgAB
EgT9AgkPCg0KBQQGAgADEgT9AhITCg8KBQQGAgAIEgb9AhSCAwMKEAoIBAYCAAicCAASBP4C
BCoKEQoHBAYCAAifCBIG/wIEgQMFCmUKBAQGAgESBIYDAj8aVyBSZXF1aXJlZC4gTWF0Y2hl
ciBmb3IgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkRvY3VtZW50XXMuCgoNCgUEBgIBBhIEhgMCCQoNCgUEBgIBARIEhgMKEQoNCgUEBgIB
AxIEhgMUFQoNCgUEBgIBCBIEhgMWPgoQCggEBgIBCJwIABIEhgMXPQqqAQoCBAcSBowDAMwD
ARqbASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0RvY3VtZW50U2VydmljZS5CYXRjaEdldERv
Y3VtZW50c01ldGFkYXRhXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5E
b2N1bWVudFNlcnZpY2UuQmF0Y2hHZXREb2N1bWVudHNNZXRhZGF0YV0KIG1ldGhvZC4KCgsK
AwQHARIEjAMIKQpdCgQEBwMAEgaOAwK1AwMaTSBUaGUgbWV0YWRhdGEgb2YgYSBbRG9jdW1l
bnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XS4KCg0K
BQQHAwABEgSOAwoaCoIBCgYEBwMAAwASBpEDBJ8DBRpwIFRoZSB2YWx1ZSBvZiB0aGUgbWF0
Y2hlciB0aGF0IHdhcyB1c2VkIHRvIG1hdGNoIHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudF0uCgoPCgcEBwMAAwABEgSRAwwY
CoQBCggEBwMAAwAIABIGlAMGngMHGnAgVGhlIHZhbHVlIG9mIHRoZSBtYXRjaGVyIHRoYXQg
d2FzIHVzZWQgdG8gbWF0Y2ggdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkRvY3VtZW50XS4KChEKCQQHAwADAAgAARIElAMMGQpuCggEBwMA
AwACABIElwMIFxpcIElmIG1hdGNoIGJ5IFVSSSwgdGhlIFVSSSBvZiB0aGUKIFtEb2N1bWVu
dF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdLgoKEQoJ
BAcDAAMAAgAFEgSXAwgOChEKCQQHAwADAAIAARIElwMPEgoRCgkEBwMAAwACAAMSBJcDFRYK
mgEKCAQHAwADAAIBEgabAwidAwsahQEgRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0fS9maGlyU3RvcmVzL3tmaGly
X3N0b3JlfS9maGlyL3tyZXNvdXJjZV90eXBlfS97Zmhpcl9yZXNvdXJjZV9pZH0KChEKCQQH
AwADAAIBBRIEmwMIDgoRCgkEBwMAAwACAQESBJsDDxwKEQoJBAcDAAMAAgEDEgSbAx8gChMK
CQQHAwADAAIBCBIGmwMhnQMKChUKCwQHAwADAAIBCJ8IEgabAyKdAwkKgAEKBgQHAwACABIE
owMEIxpwIFRoZSB2YWx1ZSBvZiB0aGUgbWF0Y2hlciB0aGF0IHdhcyB1c2VkIHRvIG1hdGNo
IHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5E
b2N1bWVudF0uCgoPCgcEBwMAAgAGEgSjAwQQCg8KBwQHAwACAAESBKMDER4KDwoHBAcDAAIA
AxIEowMhIgosCgYEBwMAAgESBKYDBBQaHCBUaGUgc3RhdGUgb2YgdGhlIGRvY3VtZW50LgoK
DwoHBAcDAAIBBhIEpgMECQoPCgcEBwMAAgEBEgSmAwoPCg8KBwQHAwACAQMSBKYDEhMKgQEK
BgQHAwACAhIEqwMENhpxIFRoZSB0aW1lc3RhbXAgb2YgdGhlIGxhc3QgdGltZSB0aGUKIFtE
b2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRd
IHdhcyBsYXN0CiBpbmRleGVkLgoKDwoHBAcDAAICBhIEqwMEHQoPCgcEBwMAAgIBEgSrAx4x
Cg8KBwQHAwACAgMSBKsDNDUKiwIKBgQHAwACAxIEtAMEJRr6ASBUaGUgZGF0YSBpbmdlc3Rp
b24gc291cmNlIG9mIHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5Eb2N1bWVudF0uCgogQWxsb3dlZCB2YWx1ZXMgYXJlOgoKICogYGJhdGNo
YDogRGF0YSBpbmdlc3RlZCB2aWEgQmF0Y2ggQVBJLCBlLmcuLCBJbXBvcnREb2N1bWVudHMu
CiAqIGBzdHJlYW1pbmdgIERhdGEgaW5nZXN0ZWQgdmlhIFN0cmVhbWluZyBBUEksIGUuZy4s
IEZISVIgc3RyZWFtaW5nLgoKDwoHBAcDAAIDBRIEtAMECgoPCgcEBwMAAgMBEgS0AwsgCg8K
BwQHAwACAwMSBLQDIyQKXAoEBAcEABIGuAMCxwMDGkwgVGhlIHN0YXRlIG9mIHRoZSBbRG9j
dW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50XS4K
Cg0KBQQHBAABEgS4AwcMCiYKBgQHBAACABIEugMEGhoWIFNob3VsZCBuZXZlciBiZSBzZXQu
CgoPCgcEBwQAAgABEgS6AwQVCg8KBwQHBAACAAISBLoDGBkKWgoGBAcEAAIBEgS9AwQQGkog
VGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9j
dW1lbnRdIGlzIGluZGV4ZWQuCgoPCgcEBwQAAgEBEgS9AwQLCg8KBwQHBAACAQISBL0DDg8K
vAEKBgQHBAACAhIEwgMEGxqrASBUaGUgW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudF0gaXMgbm90CiBpbmRleGVkIGJlY2F1c2UgaXRz
IFVSSSBpcyBub3QgaW4gdGhlCiBbVGFyZ2V0U2l0ZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuVGFyZ2V0U2l0ZV0uCgoPCgcEBwQAAgIBEgTCAwQWCg8KBwQHBAAC
AgISBMIDGRoKXwoGBAcEAAIDEgTGAwQVGk8gVGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdIGlzIG5vdAogaW5kZXhlZC4KCg8K
BwQHBAACAwESBMYDBBAKDwoHBAcEAAIDAhIExgMTFApfCgQEBwIAEgTLAwIzGlEgVGhlIG1l
dGFkYXRhIG9mIHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5Eb2N1bWVudF1zLgoKDQoFBAcCAAQSBMsDAgoKDQoFBAcCAAYSBMsDCxsKDQoF
BAcCAAESBMsDHC4KDQoFBAcCAAMSBMsDMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest ===
    # Fields for GetDocumentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::ListDocumentsRequest ===
    # Fields for ListDocumentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::ListDocumentsResponse ===
    # Fields for ListDocumentsResponse
    # Field: documents Type: 11 (.google.cloud.discoveryengine.v1beta.Document)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::CreateDocumentRequest ===
    # Fields for CreateDocumentRequest
    # Field: parent Type: 9 ()
    # Field: document Type: 11 (.google.cloud.discoveryengine.v1beta.Document)
    # Field: document_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::UpdateDocumentRequest ===
    # Fields for UpdateDocumentRequest
    # Field: document Type: 11 (.google.cloud.discoveryengine.v1beta.Document)
    # Field: allow_missing Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::DeleteDocumentRequest ===
    # Fields for DeleteDocumentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataRequest ===
    # Fields for BatchGetDocumentsMetadataRequest
    # Field: parent Type: 9 ()
    # Field: matcher Type: 11 (.google.cloud.discoveryengine.v1beta.BatchGetDocumentsMetadataRequest.Matcher)

# === Message: Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataResponse ===
    # Fields for BatchGetDocumentsMetadataResponse
    # Field: documents_metadata Type: 11 (.google.cloud.discoveryengine.v1beta.BatchGetDocumentsMetadataResponse.DocumentMetadata)

# Enum: BatchGetDocumentsMetadataResponse::State
our $BatchGetDocumentsMetadataResponse_STATE_UNSPECIFIED = 0;
our $BatchGetDocumentsMetadataResponse_INDEXED = 1;
our $BatchGetDocumentsMetadataResponse_NOT_IN_TARGET_SITE = 2;
our $BatchGetDocumentsMetadataResponse_NOT_IN_INDEX = 3;

# === Service Client: Google::Cloud::Discoveryengine::V1beta::DocumentService::DocumentServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::DocumentService::DocumentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::DocumentService::DocumentServiceClient

Client stub representing the remote C<DocumentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'GetDocument',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Document::Document',
    });
}

sub list_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DocumentService::ListDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'ListDocuments',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::DocumentService::ListDocumentsResponse',
    });
}

sub create_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DocumentService::CreateDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'CreateDocument',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Document::Document',
    });
}

sub update_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DocumentService::UpdateDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'UpdateDocument',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Document::Document',
    });
}

sub delete_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DocumentService::DeleteDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'DeleteDocument',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub import_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'ImportDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub purge_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'PurgeDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub batch_get_documents_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'BatchGetDocumentsMetadata',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::DocumentService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/document_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::DocumentService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/document_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest

Request message for
[DocumentService.GetDocument][google.cloud.discoveryengine.v1beta.DocumentService.GetDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Document][google.cloud.discoveryengine.v1beta.Document], such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document}`.

If the caller does not have permission to access the
[Document][google.cloud.discoveryengine.v1beta.Document], regardless of
whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the requested [Document][google.cloud.discoveryengine.v1beta.Document]
does not exist, a `NOT_FOUND` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::ListDocumentsRequest

Request message for
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1beta.DocumentService.ListDocuments]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.
Use `default_branch` as the branch ID, to list documents under the default
branch.

If the caller does not have permission to list
[Document][google.cloud.discoveryengine.v1beta.Document]s under this
branch, regardless of whether or not this branch exists, a
`PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of [Document][google.cloud.discoveryengine.v1beta.Document]s
to return. If unspecified, defaults to 100. The maximum allowed value is
1000. Values above 1000 are set to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListDocumentsResponse.next_page_token][google.cloud.discoveryengine.v1beta.ListDocumentsResponse.next_page_token],
received from a previous
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1beta.DocumentService.ListDocuments]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1beta.DocumentService.ListDocuments]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::ListDocumentsResponse

Response message for
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1beta.DocumentService.ListDocuments]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Document::Document>)

The [Document][google.cloud.discoveryengine.v1beta.Document]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListDocumentsRequest.page_token][google.cloud.discoveryengine.v1beta.ListDocumentsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::CreateDocumentRequest

Request message for
[DocumentService.CreateDocument][google.cloud.discoveryengine.v1beta.DocumentService.CreateDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Document::Document>)

Required. The [Document][google.cloud.discoveryengine.v1beta.Document] to
create.

=item * C<< $msg->document_id() >> / C<< $msg->document_id($value) >>

Type: C<String>

Required. The ID to use for the
[Document][google.cloud.discoveryengine.v1beta.Document], which becomes the
final component of the
[Document.name][google.cloud.discoveryengine.v1beta.Document.name].

If the caller does not have permission to create the
[Document][google.cloud.discoveryengine.v1beta.Document], regardless of
whether or not it exists, a `PERMISSION_DENIED` error is returned.

This field must be unique among all
[Document][google.cloud.discoveryengine.v1beta.Document]s with the same
[parent][google.cloud.discoveryengine.v1beta.CreateDocumentRequest.parent].
Otherwise, an `ALREADY_EXISTS` error is returned.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 128 characters. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::UpdateDocumentRequest

Request message for
[DocumentService.UpdateDocument][google.cloud.discoveryengine.v1beta.DocumentService.UpdateDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Document::Document>)

Required. The document to update/create.

If the caller does not have permission to update the
[Document][google.cloud.discoveryengine.v1beta.Document], regardless of
whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [Document][google.cloud.discoveryengine.v1beta.Document] to update
does not exist and
[allow_missing][google.cloud.discoveryengine.v1beta.UpdateDocumentRequest.allow_missing]
is not set, a `NOT_FOUND` error is returned.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to `true` and the
[Document][google.cloud.discoveryengine.v1beta.Document] is not found, a
new [Document][google.cloud.discoveryengine.v1beta.Document] is be created.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported 'document' to update. If
not set, by default updates all fields.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::DeleteDocumentRequest

Request message for
[DocumentService.DeleteDocument][google.cloud.discoveryengine.v1beta.DocumentService.DeleteDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Document][google.cloud.discoveryengine.v1beta.Document], such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document}`.

If the caller does not have permission to delete the
[Document][google.cloud.discoveryengine.v1beta.Document], regardless of
whether or not it exists, a `PERMISSION_DENIED` error is returned.

If the [Document][google.cloud.discoveryengine.v1beta.Document] to delete
does not exist, a `NOT_FOUND` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataRequest

Request message for
[DocumentService.BatchGetDocumentsMetadata][google.cloud.discoveryengine.v1beta.DocumentService.BatchGetDocumentsMetadata]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->matcher() >> / C<< $msg->matcher($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataRequest::Matcher>)

Required. Matcher for the
[Document][google.cloud.discoveryengine.v1beta.Document]s.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataResponse

Response message for
[DocumentService.BatchGetDocumentsMetadata][google.cloud.discoveryengine.v1beta.DocumentService.BatchGetDocumentsMetadata]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents_metadata() >> / C<< $msg->documents_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata>)

The metadata of the
[Document][google.cloud.discoveryengine.v1beta.Document]s.

=back

=head3 Enum: BatchGetDocumentsMetadataResponse::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<INDEXED> => C<1>

=item * C<NOT_IN_TARGET_SITE> => C<2>

=item * C<NOT_IN_INDEX> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::DocumentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
