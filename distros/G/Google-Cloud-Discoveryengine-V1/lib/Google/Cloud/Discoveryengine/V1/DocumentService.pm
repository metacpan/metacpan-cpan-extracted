package Google::Cloud::Discoveryengine::V1::DocumentService;

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
    eval { require Google::Cloud::Discoveryengine::V1::Document };
    eval { require Google::Cloud::Discoveryengine::V1::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1::PurgeConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2RvY3VtZW50X3NlcnZpY2UucHJv
dG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2xv
dWQvZGlzY292ZXJ5ZW5naW5lL3YxL2RvY3VtZW50LnByb3RvGjNnb29nbGUvY2xvdWQvZGlz
Y292ZXJ5ZW5naW5lL3YxL2ltcG9ydF9jb25maWcucHJvdG8aMmdvb2dsZS9jbG91ZC9kaXNj
b3ZlcnllbmdpbmUvdjEvcHVyZ2VfY29uZmlnLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcv
b3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUv
cHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byJZChJHZXREb2N1bWVudFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidkaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnRSBG5hbWUimQEKFExpc3REb2N1
bWVudHNSZXF1ZXN0EkUKBnBhcmVudBgBIAEoCUIt4EEC+kEnCiVkaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb20vQnJhbmNoUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdl
U2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4iiAEKFUxpc3REb2N1bWVudHNS
ZXNwb25zZRJHCglkb2N1bWVudHMYASADKAsyKS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkRvY3VtZW50Uglkb2N1bWVudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuItABChVDcmVhdGVEb2N1bWVudFJlcXVlc3QSRQoGcGFyZW50GAEgASgJ
Qi3gQQL6QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9CcmFuY2hSBnBhcmVu
dBJKCghkb2N1bWVudBgCIAEoCzIpLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RG9jdW1lbnRCA+BBAlIIZG9jdW1lbnQSJAoLZG9jdW1lbnRfaWQYAyABKAlCA+BBAlIKZG9j
dW1lbnRJZCLFAQoVVXBkYXRlRG9jdW1lbnRSZXF1ZXN0EkoKCGRvY3VtZW50GAEgASgLMiku
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudEID4EECUghkb2N1bWVu
dBIjCg1hbGxvd19taXNzaW5nGAIgASgIUgxhbGxvd01pc3NpbmcSOwoLdXBkYXRlX21hc2sY
AyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrIlwKFURlbGV0
ZURvY3VtZW50UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVudFIEbmFtZSLbBAogQmF0Y2hHZXREb2N1bWVudHNN
ZXRhZGF0YVJlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScKJWRpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9CcmFuY2hSBnBhcmVudBJoCgdtYXRjaGVyGAIgASgLMkkuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5CYXRjaEdldERvY3VtZW50c01ldGFkYXRh
UmVxdWVzdC5NYXRjaGVyQgPgQQJSB21hdGNoZXIaIQoLVXJpc01hdGNoZXISEgoEdXJpcxgB
IAMoCVIEdXJpcxpkCgtGaGlyTWF0Y2hlchJVCg5maGlyX3Jlc291cmNlcxgBIAMoCUIu4EEC
+kEoCiZoZWFsdGhjYXJlLmdvb2dsZWFwaXMuY29tL0ZoaXJSZXNvdXJjZVINZmhpclJlc291
cmNlcxr8AQoHTWF0Y2hlchJyCgx1cmlzX21hdGNoZXIYASABKAsyTS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkJhdGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFSZXF1ZXN0LlVy
aXNNYXRjaGVySABSC3VyaXNNYXRjaGVyEnIKDGZoaXJfbWF0Y2hlchgCIAEoCzJNLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQmF0Y2hHZXREb2N1bWVudHNNZXRhZGF0YVJl
cXVlc3QuRmhpck1hdGNoZXJIAFILZmhpck1hdGNoZXJCCQoHbWF0Y2hlciKGBgohQmF0Y2hH
ZXREb2N1bWVudHNNZXRhZGF0YVJlc3BvbnNlEoIBChJkb2N1bWVudHNfbWV0YWRhdGEYASAD
KAsyUy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkJhdGNoR2V0RG9jdW1lbnRz
TWV0YWRhdGFSZXNwb25zZS5Eb2N1bWVudE1ldGFkYXRhUhFkb2N1bWVudHNNZXRhZGF0YRqE
BAoQRG9jdW1lbnRNZXRhZGF0YRKFAQoNbWF0Y2hlcl92YWx1ZRgCIAEoCzJgLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQmF0Y2hHZXREb2N1bWVudHNNZXRhZGF0YVJlc3Bv
bnNlLkRvY3VtZW50TWV0YWRhdGEuTWF0Y2hlclZhbHVlUgxtYXRjaGVyVmFsdWUSXgoFc3Rh
dGUYAyABKA4ySC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkJhdGNoR2V0RG9j
dW1lbnRzTWV0YWRhdGFSZXNwb25zZS5TdGF0ZVIFc3RhdGUSSgoTbGFzdF9yZWZyZXNoZWRf
dGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSEWxhc3RSZWZyZXNoZWRU
aW1lEjIKFWRhdGFfaW5nZXN0aW9uX3NvdXJjZRgFIAEoCVITZGF0YUluZ2VzdGlvblNvdXJj
ZRqHAQoMTWF0Y2hlclZhbHVlEhIKA3VyaRgBIAEoCUgAUgN1cmkSUgoNZmhpcl9yZXNvdXJj
ZRgCIAEoCUIr+kEoCiZoZWFsdGhjYXJlLmdvb2dsZWFwaXMuY29tL0ZoaXJSZXNvdXJjZUgA
UgxmaGlyUmVzb3VyY2VCDwoNbWF0Y2hlcl92YWx1ZSJVCgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEgsKB0lOREVYRUQQARIWChJOT1RfSU5fVEFSR0VUX1NJVEUQAhIQCgxOT1Rf
SU5fSU5ERVgQAzKbFwoPRG9jdW1lbnRTZXJ2aWNlEpwCCgtHZXREb2N1bWVudBIzLmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuR2V0RG9jdW1lbnRSZXF1ZXN0GikuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudCKsAYLT5JMCngESRS92MS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3Vt
ZW50cy8qfVpVElMvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9u
cy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qfdpBBG5hbWUSrwIKDUxp
c3REb2N1bWVudHMSNS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3REb2N1
bWVudHNSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0RG9j
dW1lbnRzUmVzcG9uc2UirgGC0+STAp4BEkUvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qfS9kb2N1bWVudHNaVRJTL3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9i
cmFuY2hlcy8qfS9kb2N1bWVudHPaQQZwYXJlbnQSzQIKDkNyZWF0ZURvY3VtZW50EjYuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DcmVhdGVEb2N1bWVudFJlcXVlc3QaKS5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50ItcBgtPkkwKyASJFL3Yx
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMv
Kn0vZG9jdW1lbnRzOghkb2N1bWVudFpfIlMvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyp9L2RvY3VtZW50
czoIZG9jdW1lbnTaQRtwYXJlbnQsZG9jdW1lbnQsZG9jdW1lbnRfaWQS2AIKDlVwZGF0ZURv
Y3VtZW50EjYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5VcGRhdGVEb2N1bWVu
dFJlcXVlc3QaKS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50IuIB
gtPkkwLEATJOL3YxL3tkb2N1bWVudC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0
YVN0b3Jlcy8qL2JyYW5jaGVzLyovZG9jdW1lbnRzLyp9Oghkb2N1bWVudFpoMlwvdjEve2Rv
Y3VtZW50Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFT
dG9yZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qfToIZG9jdW1lbnTaQRRkb2N1bWVudCx1
cGRhdGVfbWFzaxKPAgoORGVsZXRlRG9jdW1lbnQSNi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkRlbGV0ZURvY3VtZW50UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0
eSKsAYLT5JMCngEqRS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9y
ZXMvKi9icmFuY2hlcy8qL2RvY3VtZW50cy8qfVpVKlMvdjEve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qL2RvY3Vt
ZW50cy8qfdpBBG5hbWUSmgMKD0ltcG9ydERvY3VtZW50cxI3Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuSW1wb3J0RG9jdW1lbnRzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb24irgKC0+STArIBIkwvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qfS9kb2N1bWVudHM6aW1wb3J0OgEqWl8i
Wi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyovYnJhbmNoZXMvKn0vZG9jdW1lbnRzOmltcG9ydDoBKspBcgo3Z29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JbXBvcnREb2N1bWVudHNSZXNwb25zZRI3Z29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5JbXBvcnREb2N1bWVudHNNZXRhZGF0YRKUAwoO
UHVyZ2VEb2N1bWVudHMSNi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlB1cmdl
RG9jdW1lbnRzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iqgKC0+ST
ArABIksvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9i
cmFuY2hlcy8qfS9kb2N1bWVudHM6cHVyZ2U6ASpaXiJZL3YxL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9icmFuY2hlcy8qfS9k
b2N1bWVudHM6cHVyZ2U6ASrKQXAKNmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
UHVyZ2VEb2N1bWVudHNSZXNwb25zZRI2Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5QdXJnZURvY3VtZW50c01ldGFkYXRhEvMCChlCYXRjaEdldERvY3VtZW50c01ldGFkYXRh
EkEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5CYXRjaEdldERvY3VtZW50c01l
dGFkYXRhUmVxdWVzdBpCLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQmF0Y2hH
ZXREb2N1bWVudHNNZXRhZGF0YVJlc3BvbnNlIs4BgtPkkwK+ARJVL3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMvKn0vYmF0Y2hHZXRE
b2N1bWVudHNNZXRhZGF0YVplEmMvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyp9L2JhdGNoR2V0RG9jdW1l
bnRzTWV0YWRhdGHaQQZwYXJlbnQazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5j
b23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxo
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3Jp
dGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2Vy
dmluZy5yZWFkd3JpdGVChwIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
QhREb2N1bWVudFNlcnZpY2VQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVy
eWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJ
U0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29n
bGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5
RW5naW5lOjpWMUqVcQoHEgUOAMYDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWADgKCQoCAwUSAxcAPQoJCgIDBhIDGAA8CgkKAgMHEgMZAC0KCQoCAwgS
AxoAJQoJCgIDCRIDGwAqCgkKAgMKEgMcACkKCAoBCBIDHgA8CgkKAgglEgMeADwKCAoBCBID
HwBkCgkKAggLEgMfAGQKCAoBCBIDIAAiCgkKAggKEgMgACIKCAoBCBIDIQA1CgkKAggIEgMh
ADUKCAoBCBIDIgA8CgkKAggBEgMiADwKCAoBCBIDIwAtCgkKAggkEgMjAC0KCAoBCBIDJAA8
CgkKAggpEgMkADwKCAoBCBIDJQA7CgkKAggtEgMlADsKgQEKAgYAEgUpAK8BARp0IFNlcnZp
Y2UgZm9yIGluZ2VzdGluZyBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuRG9jdW1lbnRdCiBpbmZvcm1hdGlvbiBvZiB0aGUgY3VzdG9tZXIncyB3ZWJzaXRl
LgoKCgoDBgABEgMpCBcKCgoDBgADEgMqAkYKDAoFBgADmQgSAyoCRgoLCgMGAAMSBCsCLkoK
DQoFBgADmggSBCsCLkoKTAoEBgACABIEMQI5Axo+IEdldHMgYSBbRG9jdW1lbnRdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdLgoKDAoFBgACAAESAzEGEQoM
CgUGAAIAAhIDMRIkCgwKBQYAAgADEgMxLzcKDQoFBgACAAQSBDIENwYKEQoJBgACAASwyrwi
EgQyBDcGCgwKBQYAAgAEEgM4BDIKDwoIBgACAASbCAASAzgEMgpVCgQGAAIBEgQ8AkQDGkcg
R2V0cyBhIGxpc3Qgb2YgW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLkRvY3VtZW50XXMuCgoMCgUGAAIBARIDPAYTCgwKBQYAAgECEgM8FCgKDAoFBgACAQMS
AzwzSAoNCgUGAAIBBBIEPQRCBgoRCgkGAAIBBLDKvCISBD0EQgYKDAoFBgACAQQSA0MENAoP
CggGAAIBBJsIABIDQwQ0Ck8KBAYAAgISBEcCUQMaQSBDcmVhdGVzIGEgW0RvY3VtZW50XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XS4KCgwKBQYAAgIBEgNH
BhQKDAoFBgACAgISA0cVKgoMCgUGAAICAxIDRzU9Cg0KBQYAAgIEEgRIBE8GChEKCQYAAgIE
sMq8IhIESARPBgoMCgUGAAICBBIDUARJCg8KCAYAAgIEmwgAEgNQBEkKTwoEBgACAxIEVAJe
AxpBIFVwZGF0ZXMgYSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRG9jdW1lbnRdLgoKDAoFBgACAwESA1QGFAoMCgUGAAIDAhIDVBUqCgwKBQYAAgMDEgNU
NT0KDQoFBgACAwQSBFUEXAYKEQoJBgACAwSwyrwiEgRVBFwGCgwKBQYAAgMEEgNdBEIKDwoI
BgACAwSbCAASA10EQgpPCgQGAAIEEgRhAmkDGkEgRGVsZXRlcyBhIFtEb2N1bWVudF1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF0uCgoMCgUGAAIEARIDYQYU
CgwKBQYAAgQCEgNhFSoKDAoFBgACBAMSA2E1SgoNCgUGAAIEBBIEYgRnBgoRCgkGAAIEBLDK
vCISBGIEZwYKDAoFBgACBAQSA2gEMgoPCggGAAIEBJsIABIDaAQyCqgCCgQGAAIFEgVyAoAB
AxqYAiBCdWxrIGltcG9ydCBvZiBtdWx0aXBsZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XXMuIFJlcXVlc3QgcHJvY2Vzc2luZwogbWF5
IGJlIHN5bmNocm9ub3VzLiBOb24tZXhpc3RpbmcgaXRlbXMgYXJlIGNyZWF0ZWQuCgogTm90
ZTogSXQgaXMgcG9zc2libGUgZm9yIGEgc3Vic2V0IG9mIHRoZQogW0RvY3VtZW50XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XXMgdG8gYmUgc3VjY2Vzc2Z1
bGx5CiB1cGRhdGVkLgoKDAoFBgACBQESA3IGFQoMCgUGAAIFAhIDchYsCgwKBQYAAgUDEgNz
DysKDQoFBgACBQQSBHQEewYKEQoJBgACBQSwyrwiEgR0BHsGCg0KBQYAAgUEEgR8BH8GCg8K
BwYAAgUEmQgSBHwEfwYKrAYKBAYAAgYSBpIBAqABAxqbBiBQZXJtYW5lbnRseSBkZWxldGVz
IGFsbCBzZWxlY3RlZAogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLkRvY3VtZW50XXMgaW4gYSBicmFuY2guCgogVGhpcyBwcm9jZXNzIGlzIGFzeW5jaHJv
bm91cy4gRGVwZW5kaW5nIG9uIHRoZSBudW1iZXIgb2YKIFtEb2N1bWVudF1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF1zIHRvIGJlIGRlbGV0ZWQsIHRoaXMK
IG9wZXJhdGlvbiBjYW4gdGFrZSBob3VycyB0byBjb21wbGV0ZS4gQmVmb3JlIHRoZSBkZWxl
dGUgb3BlcmF0aW9uCiBjb21wbGV0ZXMsIHNvbWUgW0RvY3VtZW50XVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XXMgbWlnaHQKIHN0aWxsIGJlIHJldHVybmVk
IGJ5CiBbRG9jdW1lbnRTZXJ2aWNlLkdldERvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLkRvY3VtZW50U2VydmljZS5HZXREb2N1bWVudF0KIG9yCiBbRG9jdW1l
bnRTZXJ2aWNlLkxpc3REb2N1bWVudHNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRG9jdW1lbnRTZXJ2aWNlLkxpc3REb2N1bWVudHNdLgoKIFRvIGdldCBhIGxpc3Qgb2Yg
dGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVu
dF1zCiB0byBiZSBkZWxldGVkLCBzZXQKIFtQdXJnZURvY3VtZW50c1JlcXVlc3QuZm9yY2Vd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUHVyZ2VEb2N1bWVudHNSZXF1ZXN0
LmZvcmNlXQogdG8gZmFsc2UuCgoNCgUGAAIGARIEkgEGFAoNCgUGAAIGAhIEkgEVKgoNCgUG
AAIGAxIEkwEPKwoPCgUGAAIGBBIGlAEEmwEGChMKCQYAAgYEsMq8IhIGlAEEmwEGCg8KBQYA
AgYEEgacAQSfAQYKEQoHBgACBgSZCBIGnAEEnwEGCo8BCgQGAAIHEgalAQKuAQMafyBHZXRz
IGluZGV4IGZyZXNobmVzcyBtZXRhZGF0YSBmb3IKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF1zLiBTdXBwb3J0ZWQgZm9yCiB3ZWJzaXRl
IHNlYXJjaCBvbmx5LgoKDQoFBgACBwESBKUBBh8KDQoFBgACBwISBKUBIEAKDQoFBgACBwMS
BKYBDzAKDwoFBgACBwQSBqcBBKwBBgoTCgkGAAIHBLDKvCISBqcBBKwBBgoNCgUGAAIHBBIE
rQEENAoQCggGAAIHBJsIABIErQEENAqIAQoCBAASBrQBAMUBARp6IFJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtEb2N1bWVudFNlcnZpY2UuR2V0RG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuRG9jdW1lbnRTZXJ2aWNlLkdldERvY3VtZW50XQogbWV0aG9kLgoK
CwoDBAABEgS0AQgaCq8ECgQEAAIAEga/AQLEAQQangQgUmVxdWlyZWQuIEZ1bGwgcmVzb3Vy
Y2UgbmFtZSBvZgogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LkRvY3VtZW50XSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9y
ZX0vYnJhbmNoZXMve2JyYW5jaH0vZG9jdW1lbnRzL3tkb2N1bWVudH1gLgoKIElmIHRoZSBj
YWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGFjY2VzcyB0aGUKIFtEb2N1bWVu
dF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF0sIHJlZ2FyZGxl
c3Mgb2Ygd2hldGhlcgogb3Igbm90IGl0IGV4aXN0cywgYSBgUEVSTUlTU0lPTl9ERU5JRURg
IGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRoZSByZXF1ZXN0ZWQgW0RvY3VtZW50XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XSBkb2VzCiBub3QgZXhpc3Qs
IGEgYE5PVF9GT1VORGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAIABRIEvwECCAoNCgUE
AAIAARIEvwEJDQoNCgUEAAIAAxIEvwEQEQoPCgUEAAIACBIGvwESxAEDChAKCAQAAgAInAgA
EgTAAQQqChEKBwQAAgAInwgSBsEBBMMBBQqMAQoCBAESBsoBAO0BARp+IFJlcXVlc3QgbWVz
c2FnZSBmb3IKIFtEb2N1bWVudFNlcnZpY2UuTGlzdERvY3VtZW50c11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudFNlcnZpY2UuTGlzdERvY3VtZW50c10KIG1l
dGhvZC4KCgsKAwQBARIEygEIHArgAwoEBAECABIG1AEC2QEEGs8DIFJlcXVpcmVkLiBUaGUg
cGFyZW50IGJyYW5jaCByZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRh
U3RvcmVzL3tkYXRhX3N0b3JlfS9icmFuY2hlcy97YnJhbmNofWAuCiBVc2UgYGRlZmF1bHRf
YnJhbmNoYCBhcyB0aGUgYnJhbmNoIElELCB0byBsaXN0IGRvY3VtZW50cyB1bmRlciB0aGUg
ZGVmYXVsdAogYnJhbmNoLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNz
aW9uIHRvIGxpc3QKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5Eb2N1bWVudF1zIHVuZGVyIHRoaXMgYnJhbmNoLAogcmVnYXJkbGVzcyBvZiB3aGV0aGVy
IG9yIG5vdCB0aGlzIGJyYW5jaCBleGlzdHMsIGEgYFBFUk1JU1NJT05fREVOSUVEYAogZXJy
b3IgaXMgcmV0dXJuZWQuCgoNCgUEAQIABRIE1AECCAoNCgUEAQIAARIE1AEJDwoNCgUEAQIA
AxIE1AESEwoPCgUEAQIACBIG1AEU2QEDChAKCAQBAgAInAgAEgTVAQQqChEKBwQBAgAInwgS
BtYBBNgBBQqSAgoEBAECARIE4AECFhqDAiBNYXhpbXVtIG51bWJlciBvZiBbRG9jdW1lbnRd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdcyB0bwogcmV0dXJu
LiBJZiB1bnNwZWNpZmllZCwgZGVmYXVsdHMgdG8gMTAwLiBUaGUgbWF4aW11bSBhbGxvd2Vk
IHZhbHVlIGlzIDEwMDAuCiBWYWx1ZXMgYWJvdmUgMTAwMCBhcmUgc2V0IHRvIDEwMDAuCgog
SWYgdGhpcyBmaWVsZCBpcyBuZWdhdGl2ZSwgYW4gYElOVkFMSURfQVJHVU1FTlRgIGVycm9y
IGlzIHJldHVybmVkLgoKDQoFBAECAQUSBOABAgcKDQoFBAECAQESBOABCBEKDQoFBAECAQMS
BOABFBUKuQQKBAQBAgISBOwBAhgaqgQgQSBwYWdlIHRva2VuCiBbTGlzdERvY3VtZW50c1Jl
c3BvbnNlLm5leHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5MaXN0RG9jdW1lbnRzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXSwKIHJlY2VpdmVkIGZy
b20gYSBwcmV2aW91cwogW0RvY3VtZW50U2VydmljZS5MaXN0RG9jdW1lbnRzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50U2VydmljZS5MaXN0RG9jdW1lbnRz
XQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2Uu
CgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwog
W0RvY3VtZW50U2VydmljZS5MaXN0RG9jdW1lbnRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkRvY3VtZW50U2VydmljZS5MaXN0RG9jdW1lbnRzXQogbXVzdCBtYXRjaCB0
aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLiBPdGhlcndpc2UsIGFuCiBg
SU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAQICBRIE7AECCAoN
CgUEAQICARIE7AEJEwoNCgUEAQICAxIE7AEWFwqNAQoCBAISBvIBAPsBARp/IFJlc3BvbnNl
IG1lc3NhZ2UgZm9yCiBbRG9jdW1lbnRTZXJ2aWNlLkxpc3REb2N1bWVudHNdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRTZXJ2aWNlLkxpc3REb2N1bWVudHNd
CiBtZXRob2QuCgoLCgMEAgESBPIBCB0KSgoEBAICABIE9AECIho8IFRoZSBbRG9jdW1lbnRd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdcy4KCg0KBQQCAgAE
EgT0AQIKCg0KBQQCAgAGEgT0AQsTCg0KBQQCAgABEgT0ARQdCg0KBQQCAgADEgT0ASAhCuYB
CgQEAgIBEgT6AQIdGtcBIEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcwogW0xpc3REb2N1
bWVudHNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuTGlzdERvY3VtZW50c1JlcXVlc3QucGFnZV90b2tlbl0KIHRvIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vCiBzdWJz
ZXF1ZW50IHBhZ2VzLgoKDQoFBAICAQUSBPoBAggKDQoFBAICAQESBPoBCRgKDQoFBAICAQMS
BPoBGxwKjwEKAgQDEgaAAgCgAgEagAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RvY3VtZW50
U2VydmljZS5DcmVhdGVEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5Eb2N1bWVudFNlcnZpY2UuQ3JlYXRlRG9jdW1lbnRdCiBtZXRob2QuCgoLCgMEAwESBIAC
CB0KrQEKBAQDAgASBoMCAogCBBqcASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBu
YW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9icmFu
Y2hlcy97YnJhbmNofWAuCgoNCgUEAwIABRIEgwICCAoNCgUEAwIAARIEgwIJDwoNCgUEAwIA
AxIEgwISEwoPCgUEAwIACBIGgwIUiAIDChAKCAQDAgAInAgAEgSEAgQqChEKBwQDAgAInwgS
BoUCBIcCBQpeCgQEAwIBEgSMAgJBGlAgUmVxdWlyZWQuIFRoZSBbRG9jdW1lbnRdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdIHRvCiBjcmVhdGUuCgoNCgUE
AwIBBhIEjAICCgoNCgUEAwIBARIEjAILEwoNCgUEAwIBAxIEjAIWFwoNCgUEAwIBCBIEjAIY
QAoQCggEAwIBCJwIABIEjAIZPwqsBgoEBAMCAhIEnwICQhqdBiBSZXF1aXJlZC4gVGhlIElE
IHRvIHVzZSBmb3IgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuRG9jdW1lbnRdLCB3aGljaCBiZWNvbWVzIHRoZQogZmluYWwgY29tcG9uZW50IG9m
IHRoZQogW0RvY3VtZW50Lm5hbWVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RG9jdW1lbnQubmFtZV0uCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Np
b24gdG8gY3JlYXRlIHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkRvY3VtZW50XSwgcmVnYXJkbGVzcyBvZiB3aGV0aGVyCiBvciBub3QgaXQgZXhp
c3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMgcmV0dXJuZWQuCgogVGhpcyBm
aWVsZCBtdXN0IGJlIHVuaXF1ZSBhbW9uZyBhbGwKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF1zIHdpdGggdGhlIHNhbWUKIFtwYXJlbnRd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ3JlYXRlRG9jdW1lbnRSZXF1ZXN0
LnBhcmVudF0uCiBPdGhlcndpc2UsIGFuIGBBTFJFQURZX0VYSVNUU2AgZXJyb3IgaXMgcmV0
dXJuZWQuCgogVGhpcyBmaWVsZCBtdXN0IGNvbmZvcm0gdG8gW1JGQy0xMDM0XShodHRwczov
L3Rvb2xzLmlldGYub3JnL2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdpdGggYSBsZW5ndGgg
bGltaXQgb2YgMTI4IGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4KIGBJTlZBTElEX0FSR1VN
RU5UYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQDAgIFEgSfAgIICg0KBQQDAgIBEgSfAgkU
Cg0KBQQDAgIDEgSfAhcYCg0KBQQDAgIIEgSfAhlBChAKCAQDAgIInAgAEgSfAhpACo8BCgIE
BBIGpQIAugIBGoABIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEb2N1bWVudFNlcnZpY2UuVXBk
YXRlRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRT
ZXJ2aWNlLlVwZGF0ZURvY3VtZW50XQogbWV0aG9kLgoKCwoDBAQBEgSlAggdCtkDCgQEBAIA
EgSwAgJBGsoDIFJlcXVpcmVkLiBUaGUgZG9jdW1lbnQgdG8gdXBkYXRlL2NyZWF0ZS4KCiBJ
ZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBb
RG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdLCBy
ZWdhcmRsZXNzIG9mIHdoZXRoZXIKIG9yIG5vdCBpdCBleGlzdHMsIGEgYFBFUk1JU1NJT05f
REVOSUVEYCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0RvY3VtZW50XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XSB0byB1cGRhdGUgZG9lcwogbm90
IGV4aXN0IGFuZAogW2FsbG93X21pc3NpbmddW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuVXBkYXRlRG9jdW1lbnRSZXF1ZXN0LmFsbG93X21pc3NpbmddCiBpcyBub3Qgc2V0
LCBhIGBOT1RfRk9VTkRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAQCAAYSBLACAgoKDQoF
BAQCAAESBLACCxMKDQoFBAQCAAMSBLACFhcKDQoFBAQCAAgSBLACGEAKEAoIBAQCAAicCAAS
BLACGT8KuAEKBAQEAgESBLUCAhkaqQEgSWYgc2V0IHRvIGB0cnVlYCBhbmQgdGhlCiBbRG9j
dW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdIGlzIG5v
dCBmb3VuZCwgYSBuZXcKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5Eb2N1bWVudF0gaXMgYmUgY3JlYXRlZC4KCg0KBQQEAgEFEgS1AgIGCg0KBQQEAgEB
EgS1AgcUCg0KBQQEAgEDEgS1AhcYCoEBCgQEBAICEgS5AgIsGnMgSW5kaWNhdGVzIHdoaWNo
IGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQgaW1wb3J0ZWQgJ2RvY3VtZW50JyB0byB1cGRhdGUu
IElmCiBub3Qgc2V0LCBieSBkZWZhdWx0IHVwZGF0ZXMgYWxsIGZpZWxkcy4KCg0KBQQEAgIG
EgS5AgIbCg0KBQQEAgIBEgS5AhwnCg0KBQQEAgIDEgS5AiorCo8BCgIEBRIGvwIA0AIBGoAB
IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEb2N1bWVudFNlcnZpY2UuRGVsZXRlRG9jdW1lbnRd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRTZXJ2aWNlLkRlbGV0
ZURvY3VtZW50XQogbWV0aG9kLgoKCwoDBAUBEgS/AggdCq8ECgQEBQIAEgbKAgLPAgQangQg
UmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0RvY3VtZW50XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XSwgc3VjaCBhcwogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0v
ZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNoZXMve2JyYW5jaH0vZG9jdW1lbnRzL3tk
b2N1bWVudH1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRv
IGRlbGV0ZSB0aGUKIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5Eb2N1bWVudF0sIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlcgogb3Igbm90IGl0IGV4aXN0cywg
YSBgUEVSTUlTU0lPTl9ERU5JRURgIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRoZSBbRG9j
dW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdIHRvIGRl
bGV0ZSBkb2VzCiBub3QgZXhpc3QsIGEgYE5PVF9GT1VORGAgZXJyb3IgaXMgcmV0dXJuZWQu
CgoNCgUEBQIABRIEygICCAoNCgUEBQIAARIEygIJDQoNCgUEBQIAAxIEygIQEQoPCgUEBQIA
CBIGygISzwIDChAKCAQFAgAInAgAEgTLAgQqChEKBwQFAgAInwgSBswCBM4CBQqlAQoCBAYS
BtUCAIQDARqWASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRG9jdW1lbnRTZXJ2aWNlLkJhdGNo
R2V0RG9jdW1lbnRzTWV0YWRhdGFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RG9jdW1lbnRTZXJ2aWNlLkJhdGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFdCiBtZXRob2QuCgoL
CgMEBgESBNUCCCgKZwoEBAYDABIG2AIC2wIDGlcgTWF0Y2hlciBmb3IgdGhlIFtEb2N1bWVu
dF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF1zIGJ5CiBleGFj
dCB1cmlzLgoKDQoFBAYDAAESBNgCChUKLQoGBAYDAAIAEgTaAgQdGh0gVGhlIGV4YWN0IFVS
SXMgdG8gbWF0Y2ggYnkuCgoPCgcEBgMAAgAEEgTaAgQMCg8KBwQGAwACAAUSBNoCDRMKDwoH
BAYDAAIAARIE2gIUGAoPCgcEBgMAAgADEgTaAhscCnAKBAQGAwESBt8CAukCAxpgIE1hdGNo
ZXIgZm9yIHRoZSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RG9jdW1lbnRdcyBieQogRkhJUiByZXNvdXJjZSBuYW1lcy4KCg0KBQQGAwEBEgTfAgoVCsMB
CgYEBgMBAgASBuMCBOgCBhqwASBSZXF1aXJlZC4gVGhlIEZISVIgcmVzb3VyY2VzIHRvIG1h
dGNoIGJ5LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2RhdGFzZXRzL3tkYXRhc2V0fS9maGlyU3RvcmVzL3tmaGlyX3N0b3JlfS9maGlyL3ty
ZXNvdXJjZV90eXBlfS97Zmhpcl9yZXNvdXJjZV9pZH0KCg8KBwQGAwECAAQSBOMCBAwKDwoH
BAYDAQIABRIE4wINEwoPCgcEBgMBAgABEgTjAhQiCg8KBwQGAwECAAMSBOMCJSYKEQoHBAYD
AQIACBIG4wIn6AIFChIKCgQGAwECAAicCAASBOQCBiwKEwoJBAYDAQIACJ8IEgblAgbnAgcK
hAEKBAQGAwISBu0CAvYCAxp0IE1hdGNoZXIgZm9yIHRoZSBbRG9jdW1lbnRdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdcy4KIEN1cnJlbnRseSBzdXBwb3J0
cyBtYXRjaGluZyBieSBleGFjdCBVUklzLgoKDQoFBAYDAgESBO0CChEKWgoGBAYDAggAEgbv
AgT1AgUaSCBNYXRjaGVyIGZvciB0aGUgW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XXMuCgoPCgcEBgMCCAABEgTvAgoRCigKBgQGAwICABIE
8QIGIxoYIE1hdGNoZXIgYnkgZXhhY3QgVVJJcy4KCg8KBwQGAwICAAYSBPECBhEKDwoHBAYD
AgIAARIE8QISHgoPCgcEBgMCAgADEgTxAiEiCjEKBgQGAwICARIE9AIGIxohIE1hdGNoZXIg
YnkgRkhJUiByZXNvdXJjZSBuYW1lcy4KCg8KBwQGAwICAQYSBPQCBhEKDwoHBAYDAgIBARIE
9AISHgoPCgcEBgMCAgEDEgT0AiEiCrQBCgQEBgIAEgb6AgL/AgQaowEgUmVxdWlyZWQuIFRo
ZSBwYXJlbnQgYnJhbmNoIHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2Rh
dGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9YC4KCg0KBQQGAgAFEgT6
AgIICg0KBQQGAgABEgT6AgkPCg0KBQQGAgADEgT6AhITCg8KBQQGAgAIEgb6AhT/AgMKEAoI
BAYCAAicCAASBPsCBCoKEQoHBAYCAAifCBIG/AIE/gIFCmEKBAQGAgESBIMDAj8aUyBSZXF1
aXJlZC4gTWF0Y2hlciBmb3IgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuRG9jdW1lbnRdcy4KCg0KBQQGAgEGEgSDAwIJCg0KBQQGAgEBEgSDAwoR
Cg0KBQQGAgEDEgSDAxQVCg0KBQQGAgEIEgSDAxY+ChAKCAQGAgEInAgAEgSDAxc9CqYBCgIE
BxIGiQMAxgMBGpcBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbRG9jdW1lbnRTZXJ2aWNlLkJh
dGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRG9jdW1lbnRTZXJ2aWNlLkJhdGNoR2V0RG9jdW1lbnRzTWV0YWRhdGFdCiBtZXRob2Qu
CgoLCgMEBwESBIkDCCkKWQoEBAcDABIGiwMCsQMDGkkgVGhlIG1ldGFkYXRhIG9mIGEgW0Rv
Y3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XS4KCg0K
BQQHAwABEgSLAwoaCn4KBgQHAwADABIGjgMEnAMFGmwgVGhlIHZhbHVlIG9mIHRoZSBtYXRj
aGVyIHRoYXQgd2FzIHVzZWQgdG8gbWF0Y2ggdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdLgoKDwoHBAcDAAMAARIEjgMMGAqAAQoI
BAcDAAMACAASBpEDBpsDBxpsIFRoZSB2YWx1ZSBvZiB0aGUgbWF0Y2hlciB0aGF0IHdhcyB1
c2VkIHRvIG1hdGNoIHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkRvY3VtZW50XS4KChEKCQQHAwADAAgAARIEkQMMGQpqCggEBwMAAwACABIElAMI
FxpYIElmIG1hdGNoIGJ5IFVSSSwgdGhlIFVSSSBvZiB0aGUKIFtEb2N1bWVudF1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF0uCgoRCgkEBwMAAwACAAUSBJQD
CA4KEQoJBAcDAAMAAgABEgSUAw8SChEKCQQHAwADAAIAAxIElAMVFgqaAQoIBAcDAAMAAgES
BpgDCJoDCxqFASBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vZGF0YXNldHMve2RhdGFzZXR9L2ZoaXJTdG9yZXMve2ZoaXJfc3RvcmV9L2ZoaXIv
e3Jlc291cmNlX3R5cGV9L3tmaGlyX3Jlc291cmNlX2lkfQoKEQoJBAcDAAMAAgEFEgSYAwgO
ChEKCQQHAwADAAIBARIEmAMPHAoRCgkEBwMAAwACAQMSBJgDHyAKEwoJBAcDAAMAAgEIEgaY
AyGaAwoKFQoLBAcDAAMAAgEInwgSBpgDIpoDCQp8CgYEBwMAAgASBKADBCMabCBUaGUgdmFs
dWUgb2YgdGhlIG1hdGNoZXIgdGhhdCB3YXMgdXNlZCB0byBtYXRjaCB0aGUKIFtEb2N1bWVu
dF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Eb2N1bWVudF0uCgoPCgcEBwMA
AgAGEgSgAwQQCg8KBwQHAwACAAESBKADER4KDwoHBAcDAAIAAxIEoAMhIgosCgYEBwMAAgES
BKMDBBQaHCBUaGUgc3RhdGUgb2YgdGhlIGRvY3VtZW50LgoKDwoHBAcDAAIBBhIEowMECQoP
CgcEBwMAAgEBEgSjAwoPCg8KBwQHAwACAQMSBKMDEhMKfAoGBAcDAAICEgSnAwQ2GmwgVGhl
IHRpbWVzdGFtcCBvZiB0aGUgbGFzdCB0aW1lIHRoZQogW0RvY3VtZW50XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XSB3YXMgbGFzdCBpbmRleGVkLgoKDwoH
BAcDAAICBhIEpwMEHQoPCgcEBwMAAgIBEgSnAx4xCg8KBwQHAwACAgMSBKcDNDUKhwIKBgQH
AwACAxIEsAMEJRr2ASBUaGUgZGF0YSBpbmdlc3Rpb24gc291cmNlIG9mIHRoZQogW0RvY3Vt
ZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XS4KCiBBbGxv
d2VkIHZhbHVlcyBhcmU6CgogKiBgYmF0Y2hgOiBEYXRhIGluZ2VzdGVkIHZpYSBCYXRjaCBB
UEksIGUuZy4sIEltcG9ydERvY3VtZW50cy4KICogYHN0cmVhbWluZ2AgRGF0YSBpbmdlc3Rl
ZCB2aWEgU3RyZWFtaW5nIEFQSSwgZS5nLiwgRkhJUiBzdHJlYW1pbmcuCgoPCgcEBwMAAgMF
EgSwAwQKCg8KBwQHAwACAwESBLADCyAKDwoHBAcDAAIDAxIEsAMjJApYCgQEBwQAEga0AwLC
AwMaSCBUaGUgc3RhdGUgb2YgdGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5Eb2N1bWVudF0uCgoNCgUEBwQAARIEtAMHDAomCgYEBwQAAgASBLYDBBoa
FiBTaG91bGQgbmV2ZXIgYmUgc2V0LgoKDwoHBAcEAAIAARIEtgMEFQoPCgcEBwQAAgACEgS2
AxgZClYKBgQHBAACARIEuQMEEBpGIFRoZSBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdIGlzIGluZGV4ZWQuCgoPCgcEBwQAAgEBEgS5AwQL
Cg8KBwQHBAACAQISBLkDDg8KtAEKBgQHBAACAhIEvgMEGxqjASBUaGUgW0RvY3VtZW50XVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XSBpcyBub3QgaW5kZXhl
ZAogYmVjYXVzZSBpdHMgVVJJIGlzIG5vdCBpbiB0aGUKIFtUYXJnZXRTaXRlXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlRhcmdldFNpdGVdLgoKDwoHBAcEAAICARIEvgME
FgoPCgcEBwQAAgICEgS+AxkaCloKBgQHBAACAxIEwQMEFRpKIFRoZSBbRG9jdW1lbnRdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRG9jdW1lbnRdIGlzIG5vdCBpbmRleGVk
LgoKDwoHBAcEAAIDARIEwQMEEAoPCgcEBwQAAgMCEgTBAxMUCloKBAQHAgASBMUDAjMaTCBU
aGUgbWV0YWRhdGEgb2YgdGhlIFtEb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5Eb2N1bWVudF1zLgoKDQoFBAcCAAQSBMUDAgoKDQoFBAcCAAYSBMUDCxsKDQoF
BAcCAAESBMUDHC4KDQoFBAcCAAMSBMUDMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest ===
    # Fields for GetDocumentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::ListDocumentsRequest ===
    # Fields for ListDocumentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::ListDocumentsResponse ===
    # Fields for ListDocumentsResponse
    # Field: documents Type: 11 (.google.cloud.discoveryengine.v1.Document)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::CreateDocumentRequest ===
    # Fields for CreateDocumentRequest
    # Field: parent Type: 9 ()
    # Field: document Type: 11 (.google.cloud.discoveryengine.v1.Document)
    # Field: document_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::UpdateDocumentRequest ===
    # Fields for UpdateDocumentRequest
    # Field: document Type: 11 (.google.cloud.discoveryengine.v1.Document)
    # Field: allow_missing Type: 8 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::DeleteDocumentRequest ===
    # Fields for DeleteDocumentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataRequest ===
    # Fields for BatchGetDocumentsMetadataRequest
    # Field: parent Type: 9 ()
    # Field: matcher Type: 11 (.google.cloud.discoveryengine.v1.BatchGetDocumentsMetadataRequest.Matcher)

# === Message: Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataResponse ===
    # Fields for BatchGetDocumentsMetadataResponse
    # Field: documents_metadata Type: 11 (.google.cloud.discoveryengine.v1.BatchGetDocumentsMetadataResponse.DocumentMetadata)

# Enum: BatchGetDocumentsMetadataResponse::State
our $BatchGetDocumentsMetadataResponse_STATE_UNSPECIFIED = 0;
our $BatchGetDocumentsMetadataResponse_INDEXED = 1;
our $BatchGetDocumentsMetadataResponse_NOT_IN_TARGET_SITE = 2;
our $BatchGetDocumentsMetadataResponse_NOT_IN_INDEX = 3;

# === Service Client: Google::Cloud::Discoveryengine::V1::DocumentService::DocumentServiceClient ===
package Google::Cloud::Discoveryengine::V1::DocumentService::DocumentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::DocumentService::DocumentServiceClient

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
        ? Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'GetDocument',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Document::Document',
    });
}

sub list_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DocumentService::ListDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'ListDocuments',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DocumentService::ListDocumentsResponse',
    });
}

sub create_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DocumentService::CreateDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'CreateDocument',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Document::Document',
    });
}

sub update_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DocumentService::UpdateDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'UpdateDocument',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Document::Document',
    });
}

sub delete_document {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DocumentService::DeleteDocumentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'DeleteDocument',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub import_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'ImportDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub purge_documents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::PurgeConfig::PurgeDocumentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'PurgeDocuments',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub batch_get_documents_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'BatchGetDocumentsMetadata',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::DocumentService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/document_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::DocumentService;

    my $msg = Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/document_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest

Request message for
[DocumentService.GetDocument][google.cloud.discoveryengine.v1.DocumentService.GetDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Document][google.cloud.discoveryengine.v1.Document], such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document}`.

If the caller does not have permission to access the
[Document][google.cloud.discoveryengine.v1.Document], regardless of whether
or not it exists, a `PERMISSION_DENIED` error is returned.

If the requested [Document][google.cloud.discoveryengine.v1.Document] does
not exist, a `NOT_FOUND` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::ListDocumentsRequest

Request message for
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1.DocumentService.ListDocuments]
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
[Document][google.cloud.discoveryengine.v1.Document]s under this branch,
regardless of whether or not this branch exists, a `PERMISSION_DENIED`
error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of [Document][google.cloud.discoveryengine.v1.Document]s to
return. If unspecified, defaults to 100. The maximum allowed value is 1000.
Values above 1000 are set to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListDocumentsResponse.next_page_token][google.cloud.discoveryengine.v1.ListDocumentsResponse.next_page_token],
received from a previous
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1.DocumentService.ListDocuments]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1.DocumentService.ListDocuments]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::ListDocumentsResponse

Response message for
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1.DocumentService.ListDocuments]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Document::Document>)

The [Document][google.cloud.discoveryengine.v1.Document]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListDocumentsRequest.page_token][google.cloud.discoveryengine.v1.ListDocumentsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::CreateDocumentRequest

Request message for
[DocumentService.CreateDocument][google.cloud.discoveryengine.v1.DocumentService.CreateDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Document::Document>)

Required. The [Document][google.cloud.discoveryengine.v1.Document] to
create.

=item * C<< $msg->document_id() >> / C<< $msg->document_id($value) >>

Type: C<String>

Required. The ID to use for the
[Document][google.cloud.discoveryengine.v1.Document], which becomes the
final component of the
[Document.name][google.cloud.discoveryengine.v1.Document.name].

If the caller does not have permission to create the
[Document][google.cloud.discoveryengine.v1.Document], regardless of whether
or not it exists, a `PERMISSION_DENIED` error is returned.

This field must be unique among all
[Document][google.cloud.discoveryengine.v1.Document]s with the same
[parent][google.cloud.discoveryengine.v1.CreateDocumentRequest.parent].
Otherwise, an `ALREADY_EXISTS` error is returned.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 128 characters. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::UpdateDocumentRequest

Request message for
[DocumentService.UpdateDocument][google.cloud.discoveryengine.v1.DocumentService.UpdateDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Document::Document>)

Required. The document to update/create.

If the caller does not have permission to update the
[Document][google.cloud.discoveryengine.v1.Document], regardless of whether
or not it exists, a `PERMISSION_DENIED` error is returned.

If the [Document][google.cloud.discoveryengine.v1.Document] to update does
not exist and
[allow_missing][google.cloud.discoveryengine.v1.UpdateDocumentRequest.allow_missing]
is not set, a `NOT_FOUND` error is returned.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

If set to `true` and the
[Document][google.cloud.discoveryengine.v1.Document] is not found, a new
[Document][google.cloud.discoveryengine.v1.Document] is be created.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided imported 'document' to update. If
not set, by default updates all fields.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::DeleteDocumentRequest

Request message for
[DocumentService.DeleteDocument][google.cloud.discoveryengine.v1.DocumentService.DeleteDocument]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Document][google.cloud.discoveryengine.v1.Document], such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document}`.

If the caller does not have permission to delete the
[Document][google.cloud.discoveryengine.v1.Document], regardless of whether
or not it exists, a `PERMISSION_DENIED` error is returned.

If the [Document][google.cloud.discoveryengine.v1.Document] to delete does
not exist, a `NOT_FOUND` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataRequest

Request message for
[DocumentService.BatchGetDocumentsMetadata][google.cloud.discoveryengine.v1.DocumentService.BatchGetDocumentsMetadata]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->matcher() >> / C<< $msg->matcher($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataRequest::Matcher>)

Required. Matcher for the
[Document][google.cloud.discoveryengine.v1.Document]s.

=back

=head2 Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataResponse

Response message for
[DocumentService.BatchGetDocumentsMetadata][google.cloud.discoveryengine.v1.DocumentService.BatchGetDocumentsMetadata]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents_metadata() >> / C<< $msg->documents_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata>)

The metadata of the [Document][google.cloud.discoveryengine.v1.Document]s.

=back

=head3 Enum: BatchGetDocumentsMetadataResponse::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<INDEXED> => C<1>

=item * C<NOT_IN_TARGET_SITE> => C<2>

=item * C<NOT_IN_INDEX> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::DocumentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
