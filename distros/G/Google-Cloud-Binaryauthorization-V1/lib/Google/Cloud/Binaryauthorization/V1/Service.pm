package Google::Cloud::Binaryauthorization::V1::Service;

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
    eval { require Google::Cloud::Binaryauthorization::V1::Resources };
    eval { require Google::Protobuf::Empty };
    eval { require Grafeas::V1::Attestation };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYmluYXJ5YXV0aG9yaXphdGlvbi92MS9zZXJ2aWNlLnByb3RvEiNn
b29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aM2dvb2dsZS9jbG91
ZC9iaW5hcnlhdXRob3JpemF0aW9uL3YxL3Jlc291cmNlcy5wcm90bxobZ29vZ2xlL3Byb3Rv
YnVmL2VtcHR5LnByb3RvGhxncmFmZWFzL3YxL2F0dGVzdGF0aW9uLnByb3RvIlkKEEdldFBv
bGljeVJlcXVlc3QSRQoEbmFtZRgBIAEoCUIx4EEC+kErCiliaW5hcnlhdXRob3JpemF0aW9u
Lmdvb2dsZWFwaXMuY29tL1BvbGljeVIEbmFtZSJfChNVcGRhdGVQb2xpY3lSZXF1ZXN0EkgK
BnBvbGljeRgBIAEoCzIrLmdvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLlBv
bGljeUID4EECUgZwb2xpY3ki2gEKFUNyZWF0ZUF0dGVzdG9yUmVxdWVzdBJLCgZwYXJlbnQY
ASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJv
amVjdFIGcGFyZW50EiQKC2F0dGVzdG9yX2lkGAIgASgJQgPgQQJSCmF0dGVzdG9ySWQSTgoI
YXR0ZXN0b3IYAyABKAsyLS5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5B
dHRlc3RvckID4EECUghhdHRlc3RvciJdChJHZXRBdHRlc3RvclJlcXVlc3QSRwoEbmFtZRgB
IAEoCUIz4EEC+kEtCitiaW5hcnlhdXRob3JpemF0aW9uLmdvb2dsZWFwaXMuY29tL0F0dGVz
dG9yUgRuYW1lImcKFVVwZGF0ZUF0dGVzdG9yUmVxdWVzdBJOCghhdHRlc3RvchgBIAEoCzIt
Lmdvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0dGVzdG9yQgPgQQJSCGF0
dGVzdG9yIp8BChRMaXN0QXR0ZXN0b3JzUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpB
LQorY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFIGcGFyZW50
EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFn
ZVRva2VuIowBChVMaXN0QXR0ZXN0b3JzUmVzcG9uc2USSwoJYXR0ZXN0b3JzGAEgAygLMi0u
Z29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0ZXN0b3JSCWF0dGVzdG9y
cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iYAoVRGVsZXRlQXR0
ZXN0b3JSZXF1ZXN0EkcKBG5hbWUYASABKAlCM+BBAvpBLQorYmluYXJ5YXV0aG9yaXphdGlv
bi5nb29nbGVhcGlzLmNvbS9BdHRlc3RvclIEbmFtZSJfChZHZXRTeXN0ZW1Qb2xpY3lSZXF1
ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopYmluYXJ5YXV0aG9yaXphdGlvbi5nb29nbGVh
cGlzLmNvbS9Qb2xpY3lSBG5hbWUi/AEKJFZhbGlkYXRlQXR0ZXN0YXRpb25PY2N1cnJlbmNl
UmVxdWVzdBIfCghhdHRlc3RvchgBIAEoCUID4EECUghhdHRlc3RvchJICgthdHRlc3RhdGlv
bhgCIAEoCzIhLmdyYWZlYXMudjEuQXR0ZXN0YXRpb25PY2N1cnJlbmNlQgPgQQJSC2F0dGVz
dGF0aW9uEiwKD29jY3VycmVuY2Vfbm90ZRgDIAEoCUID4EECUg5vY2N1cnJlbmNlTm90ZRI7
ChdvY2N1cnJlbmNlX3Jlc291cmNlX3VyaRgEIAEoCUID4EECUhVvY2N1cnJlbmNlUmVzb3Vy
Y2VVcmkihwIKJVZhbGlkYXRlQXR0ZXN0YXRpb25PY2N1cnJlbmNlUmVzcG9uc2USaQoGcmVz
dWx0GAEgASgOMlEuZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuVmFsaWRh
dGVBdHRlc3RhdGlvbk9jY3VycmVuY2VSZXNwb25zZS5SZXN1bHRSBnJlc3VsdBIjCg1kZW5p
YWxfcmVhc29uGAIgASgJUgxkZW5pYWxSZWFzb24iTgoGUmVzdWx0EhYKElJFU1VMVF9VTlNQ
RUNJRklFRBAAEgwKCFZFUklGSUVEEAESHgoaQVRURVNUQVRJT05fTk9UX1ZFUklGSUFCTEUQ
AjLiCgobQmluYXV0aHpNYW5hZ2VtZW50U2VydmljZVYxEpwBCglHZXRQb2xpY3kSNS5nb29n
bGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5HZXRQb2xpY3lSZXF1ZXN0GisuZ29v
Z2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuUG9saWN5IiuC0+STAh4SHC92MS97
bmFtZT1wcm9qZWN0cy8qL3BvbGljeX3aQQRuYW1lErMBCgxVcGRhdGVQb2xpY3kSOC5nb29n
bGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5VcGRhdGVQb2xpY3lSZXF1ZXN0Gisu
Z29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuUG9saWN5IjyC0+STAi0aIy92
MS97cG9saWN5Lm5hbWU9cHJvamVjdHMvKi9wb2xpY3l9OgZwb2xpY3naQQZwb2xpY3kSzgEK
DkNyZWF0ZUF0dGVzdG9yEjouZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEu
Q3JlYXRlQXR0ZXN0b3JSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRp
b24udjEuQXR0ZXN0b3IiUYLT5JMCLSIhL3YxL3twYXJlbnQ9cHJvamVjdHMvKn0vYXR0ZXN0
b3JzOghhdHRlc3RvctpBG3BhcmVudCxhdHRlc3Rvcl9pZCxhdHRlc3RvchKnAQoLR2V0QXR0
ZXN0b3ISNy5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5HZXRBdHRlc3Rv
clJlcXVlc3QaLS5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5BdHRlc3Rv
ciIwgtPkkwIjEiEvdjEve25hbWU9cHJvamVjdHMvKi9hdHRlc3RvcnMvKn3aQQRuYW1lEsQB
Cg5VcGRhdGVBdHRlc3RvchI6Lmdvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYx
LlVwZGF0ZUF0dGVzdG9yUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0
aW9uLnYxLkF0dGVzdG9yIkeC0+STAjYaKi92MS97YXR0ZXN0b3IubmFtZT1wcm9qZWN0cy8q
L2F0dGVzdG9ycy8qfToIYXR0ZXN0b3LaQQhhdHRlc3RvchK6AQoNTGlzdEF0dGVzdG9ycxI5
Lmdvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkxpc3RBdHRlc3RvcnNSZXF1
ZXN0GjouZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuTGlzdEF0dGVzdG9y
c1Jlc3BvbnNlIjKC0+STAiMSIS92MS97cGFyZW50PXByb2plY3RzLyp9L2F0dGVzdG9yc9pB
BnBhcmVudBKWAQoORGVsZXRlQXR0ZXN0b3ISOi5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9y
aXphdGlvbi52MS5EZWxldGVBdHRlc3RvclJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1w
dHkiMILT5JMCIyohL3YxL3tuYW1lPXByb2plY3RzLyovYXR0ZXN0b3JzLyp92kEEbmFtZRpW
ykEiYmluYXJ5YXV0aG9yaXphdGlvbi5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0ylAIKDlN5c3RlbVBvbGljeVYxEqkB
Cg9HZXRTeXN0ZW1Qb2xpY3kSOy5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52
MS5HZXRTeXN0ZW1Qb2xpY3lSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6
YXRpb24udjEuUG9saWN5IiyC0+STAh8SHS92MS97bmFtZT1sb2NhdGlvbnMvKi9wb2xpY3l9
2kEEbmFtZRpWykEiYmluYXJ5YXV0aG9yaXphdGlvbi5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0y9QIKElZhbGlkYXRp
b25IZWxwZXJWMRKGAgodVmFsaWRhdGVBdHRlc3RhdGlvbk9jY3VycmVuY2USSS5nb29nbGUu
Y2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5WYWxpZGF0ZUF0dGVzdGF0aW9uT2NjdXJy
ZW5jZVJlcXVlc3QaSi5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5WYWxp
ZGF0ZUF0dGVzdGF0aW9uT2NjdXJyZW5jZVJlc3BvbnNlIk6C0+STAkgiQy92MS97YXR0ZXN0
b3I9cHJvamVjdHMvKi9hdHRlc3RvcnMvKn06dmFsaWRhdGVBdHRlc3RhdGlvbk9jY3VycmVu
Y2U6ASoaVspBImJpbmFyeWF1dGhvcml6YXRpb24uZ29vZ2xlYXBpcy5jb23SQS5odHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQokCCjVjb20uZ29vZ2xl
LnByb3Rvcy5nb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MVAAWlljbG91ZC5n
b29nbGUuY29tL2dvL2JpbmFyeWF1dGhvcml6YXRpb24vYXBpdjEvYmluYXJ5YXV0aG9yaXph
dGlvbnBiO2JpbmFyeWF1dGhvcml6YXRpb25wYqoCI0dvb2dsZS5DbG91ZC5CaW5hcnlBdXRo
b3JpemF0aW9uLlYxygIjR29vZ2xlXENsb3VkXEJpbmFyeUF1dGhvcml6YXRpb25cVjHqAiZH
b29nbGU6OkNsb3VkOjpCaW5hcnlBdXRob3JpemF0aW9uOjpWMUrfXQoHEgUOANoCAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAD0KCQoCAwUSAxcAJQoJ
CgIDBhIDGAAmCggKAQgSAxoAQAoJCgIIJRIDGgBACggKAQgSAxsAcAoJCgIICxIDGwBwCggK
AQgSAxwAIwoJCgIIChIDHAAjCggKAQgSAx0ATgoJCgIIARIDHQBOCggKAQgSAx4AQAoJCgII
KRIDHgBACggKAQgSAx8APwoJCgIILRIDHwA/CuQCCgIGABIFKgCDAQEanwIgR29vZ2xlIENs
b3VkIE1hbmFnZW1lbnQgU2VydmljZSBmb3IgQmluYXJ5IEF1dGhvcml6YXRpb24gYWRtaXNz
aW9uIHBvbGljaWVzCiBhbmQgYXR0ZXN0YXRpb24gYXV0aG9yaXRpZXMuCgogVGhpcyBBUEkg
aW1wbGVtZW50cyBhIFJFU1QgbW9kZWwgd2l0aCB0aGUgZm9sbG93aW5nIG9iamVjdHM6Cgog
KiBbUG9saWN5XVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5Qb2xpY3ld
CiAqIFtBdHRlc3Rvcl1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0
ZXN0b3JdCjI1IEN1c3RvbWVyLWZhY2luZyBBUEkgZm9yIENsb3VkIEJpbmFyeSBBdXRob3Jp
emF0aW9uLgoKCgoDBgABEgMqCCMKCgoDBgADEgMrAkoKDAoFBgADmQgSAysCSgoLCgMGAAMS
BCwCLTcKDQoFBgADmggSBCwCLTcKnAQKBAYAAgASBDkCPgMajQQgQSBbcG9saWN5XVtnb29n
bGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5Qb2xpY3ldIHNwZWNpZmllcyB0aGUK
IFthdHRlc3RvcnNdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0dGVz
dG9yXSB0aGF0IG11c3QgYXR0ZXN0CiB0byBhIGNvbnRhaW5lciBpbWFnZSwgYmVmb3JlIHRo
ZSBwcm9qZWN0IGlzIGFsbG93ZWQgdG8gZGVwbG95IHRoYXQgaW1hZ2UuCiBUaGVyZSBpcyBh
dCBtb3N0IG9uZSBwb2xpY3kgcGVyIHByb2plY3QuIEFsbCBpbWFnZSBhZG1pc3Npb24gcmVx
dWVzdHMgYXJlCiBwZXJtaXR0ZWQgaWYgYSBwcm9qZWN0IGhhcyBubyBwb2xpY3kuCgogR2V0
cyB0aGUgW3BvbGljeV1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuUG9s
aWN5XSBmb3IgdGhpcwogcHJvamVjdC4gUmV0dXJucyBhIGRlZmF1bHQKIFtwb2xpY3ldW2dv
b2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLlBvbGljeV0gaWYgdGhlIHByb2pl
Y3QgZG9lcwogbm90IGhhdmUgb25lLgoKDAoFBgACAAESAzkGDwoMCgUGAAIAAhIDORAgCgwK
BQYAAgADEgM5KzEKDQoFBgACAAQSBDoEPAYKEQoJBgACAASwyrwiEgQ6BDwGCgwKBQYAAgAE
EgM9BDIKDwoIBgACAASbCAASAz0EMgqfAwoEBgACARIERgJMAxqQAyBDcmVhdGVzIG9yIHVw
ZGF0ZXMgYSBwcm9qZWN0J3MKIFtwb2xpY3ldW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3Jp
emF0aW9uLnYxLlBvbGljeV0sIGFuZCByZXR1cm5zIGEgY29weSBvZgogdGhlIG5ldyBbcG9s
aWN5XVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5Qb2xpY3ldLiBBIHBv
bGljeSBpcwogYWx3YXlzIHVwZGF0ZWQgYXMgYSB3aG9sZSwgdG8gYXZvaWQgcmFjZSBjb25k
aXRpb25zIHdpdGggY29uY3VycmVudCBwb2xpY3kKIGVuZm9yY2VtZW50IChvciBtYW5hZ2Vt
ZW50ISkgcmVxdWVzdHMuIFJldHVybnMgYE5PVF9GT1VORGAgaWYgdGhlIHByb2plY3QKIGRv
ZXMgbm90IGV4aXN0LCBgSU5WQUxJRF9BUkdVTUVOVGAgaWYgdGhlIHJlcXVlc3QgaXMgbWFs
Zm9ybWVkLgoKDAoFBgACAQESA0YGEgoMCgUGAAIBAhIDRhMmCgwKBQYAAgEDEgNGMTcKDQoF
BgACAQQSBEcESgYKEQoJBgACAQSwyrwiEgRHBEoGCgwKBQYAAgEEEgNLBDQKDwoIBgACAQSb
CAASA0sENAr2AgoEBgACAhIEVAJaAxrnAiBDcmVhdGVzIGFuIFthdHRlc3Rvcl1bZ29vZ2xl
LmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0ZXN0b3JdLCBhbmQKIHJldHVybnMg
YSBjb3B5IG9mIHRoZSBuZXcKIFthdHRlc3Rvcl1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhv
cml6YXRpb24udjEuQXR0ZXN0b3JdLiBSZXR1cm5zCiBgTk9UX0ZPVU5EYCBpZiB0aGUgcHJv
amVjdCBkb2VzIG5vdCBleGlzdCwgYElOVkFMSURfQVJHVU1FTlRgIGlmIHRoZQogcmVxdWVz
dCBpcyBtYWxmb3JtZWQsIGBBTFJFQURZX0VYSVNUU2AgaWYgdGhlCiBbYXR0ZXN0b3JdW2dv
b2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0dGVzdG9yXSBhbHJlYWR5IGV4
aXN0cy4KCgwKBQYAAgIBEgNUBhQKDAoFBgACAgISA1QVKgoMCgUGAAICAxIDVDU9Cg0KBQYA
AgIEEgRVBFgGChEKCQYAAgIEsMq8IhIEVQRYBgoMCgUGAAICBBIDWQRJCg8KCAYAAgIEmwgA
EgNZBEkKuAEKBAYAAgMSBF8CZAMaqQEgR2V0cyBhbiBbYXR0ZXN0b3JdW2dvb2dsZS5jbG91
ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0dGVzdG9yXS4KIFJldHVybnMgYE5PVF9GT1VO
RGAgaWYgdGhlCiBbYXR0ZXN0b3JdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9u
LnYxLkF0dGVzdG9yXSBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgMBEgNfBhEKDAoFBgACAwIS
A18SJAoMCgUGAAIDAxIDXy83Cg0KBQYAAgMEEgRgBGIGChEKCQYAAgMEsMq8IhIEYARiBgoM
CgUGAAIDBBIDYwQyCg8KCAYAAgMEmwgAEgNjBDIKuwEKBAYAAgQSBGkCbwMarAEgVXBkYXRl
cyBhbiBbYXR0ZXN0b3JdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0
dGVzdG9yXS4KIFJldHVybnMgYE5PVF9GT1VORGAgaWYgdGhlCiBbYXR0ZXN0b3JdW2dvb2ds
ZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0dGVzdG9yXSBkb2VzIG5vdCBleGlz
dC4KCgwKBQYAAgQBEgNpBhQKDAoFBgACBAISA2kVKgoMCgUGAAIEAxIDaTU9Cg0KBQYAAgQE
EgRqBG0GChEKCQYAAgQEsMq8IhIEagRtBgoMCgUGAAIEBBIDbgQ2Cg8KCAYAAgQEmwgAEgNu
BDYKiwEKBAYAAgUSBHMCeAMafSBMaXN0cyBbYXR0ZXN0b3JzXVtnb29nbGUuY2xvdWQuYmlu
YXJ5YXV0aG9yaXphdGlvbi52MS5BdHRlc3Rvcl0uCiBSZXR1cm5zIGBJTlZBTElEX0FSR1VN
RU5UYCBpZiB0aGUgcHJvamVjdCBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgUBEgNzBhMKDAoF
BgACBQISA3MUKAoMCgUGAAIFAxIDczNICg0KBQYAAgUEEgR0BHYGChEKCQYAAgUEsMq8IhIE
dAR2BgoMCgUGAAIFBBIDdwQ0Cg8KCAYAAgUEmwgAEgN3BDQKvAEKBAYAAgYSBX0CggEDGqwB
IERlbGV0ZXMgYW4gW2F0dGVzdG9yXVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlv
bi52MS5BdHRlc3Rvcl0uCiBSZXR1cm5zIGBOT1RfRk9VTkRgIGlmIHRoZQogW2F0dGVzdG9y
XVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5BdHRlc3Rvcl0gZG9lcyBu
b3QgZXhpc3QuCgoMCgUGAAIGARIDfQYUCgwKBQYAAgYCEgN9FSoKDAoFBgACBgMSA301SgoO
CgUGAAIGBBIFfgSAAQYKEgoJBgACBgSwyrwiEgV+BIABBgoNCgUGAAIGBBIEgQEEMgoQCggG
AAIGBJsIABIEgQEEMgo3CgIGARIGhgEAkgEBGikgQVBJIGZvciB3b3JraW5nIHdpdGggdGhl
IHN5c3RlbSBwb2xpY3kuCgoLCgMGAQESBIYBCBYKCwoDBgEDEgSHAQJKCg0KBQYBA5kIEgSH
AQJKCg0KAwYBAxIGiAECiQE3Cg8KBQYBA5oIEgaIAQKJATcKSwoEBgECABIGjAECkQEDGjsg
R2V0cyB0aGUgY3VycmVudCBzeXN0ZW0gcG9saWN5IGluIHRoZSBzcGVjaWZpZWQgbG9jYXRp
b24uCgoNCgUGAQIAARIEjAEGFQoNCgUGAQIAAhIEjAEWLAoNCgUGAQIAAxIEjAE3PQoPCgUG
AQIABBIGjQEEjwEGChMKCQYBAgAEsMq8IhIGjQEEjwEGCg0KBQYBAgAEEgSQAQQyChAKCAYB
AgAEmwgAEgSQAQQyCi4KAgYCEgaVAQCjAQEaICBCaW5BdXRoeiBBdHRlc3RvciB2ZXJpZmlj
YXRpb24KCgsKAwYCARIElQEIGgoLCgMGAgMSBJYBAkoKDQoFBgIDmQgSBJYBAkoKDQoDBgID
EgaXAQKYATcKDwoFBgIDmggSBpcBApgBNwp1CgQGAgIAEgacAQKiAQMaZSBSZXR1cm5zIHdo
ZXRoZXIgdGhlIGdpdmVuIGBBdHRlc3RhdGlvbmAgZm9yIHRoZSBnaXZlbiBpbWFnZSBVUkkK
IHdhcyBzaWduZWQgYnkgdGhlIGdpdmVuIGBBdHRlc3RvcmAKCg0KBQYCAgABEgScAQYjCg0K
BQYCAgACEgScASRICg0KBQYCAgADEgSdAQ80Cg8KBQYCAgAEEgaeAQShAQYKEwoJBgICAASw
yrwiEgaeAQShAQYKmQEKAgQAEganAQCxAQEaigEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0Jp
bmF1dGh6TWFuYWdlbWVudFNlcnZpY2VWMS5HZXRQb2xpY3ldW2dvb2dsZS5jbG91ZC5iaW5h
cnlhdXRob3JpemF0aW9uLnYxLkJpbmF1dGh6TWFuYWdlbWVudFNlcnZpY2VWMS5HZXRQb2xp
Y3ldLgoKCwoDBAABEgSnAQgYCpwBCgQEAAIAEgarAQKwAQQaiwEgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZQogW3BvbGljeV1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhv
cml6YXRpb24udjEuUG9saWN5XSB0byByZXRyaWV2ZSwgaW4gdGhlCiBmb3JtYXQgYHByb2pl
Y3RzLyovcG9saWN5YC4KCg0KBQQAAgAFEgSrAQIICg0KBQQAAgABEgSrAQkNCg0KBQQAAgAD
EgSrARARCg8KBQQAAgAIEgarARKwAQMKEAoIBAACAAicCAASBKwBBCoKEQoHBAACAAifCBIG
rQEErwEFCp8BCgIEARIGtQEAvAEBGpABIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtCaW5hdXRo
ek1hbmFnZW1lbnRTZXJ2aWNlVjEuVXBkYXRlUG9saWN5XVtnb29nbGUuY2xvdWQuYmluYXJ5
YXV0aG9yaXphdGlvbi52MS5CaW5hdXRoek1hbmFnZW1lbnRTZXJ2aWNlVjEuVXBkYXRlUG9s
aWN5XS4KCgsKAwQBARIEtQEIGwqdAgoEBAECABIEuwECPRqOAiBSZXF1aXJlZC4gQSBuZXcg
b3IgdXBkYXRlZAogW3BvbGljeV1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24u
djEuUG9saWN5XSB2YWx1ZS4gVGhlIHNlcnZpY2UKIHdpbGwgb3ZlcndyaXRlIHRoZSBbcG9s
aWN5CiBuYW1lXVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52MS5Qb2xpY3ku
bmFtZV0gZmllbGQgd2l0aCB0aGUKIHJlc291cmNlIG5hbWUgaW4gdGhlIHJlcXVlc3QgVVJM
LCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL3BvbGljeWAuCgoNCgUEAQIABhIEuwECCAoN
CgUEAQIAARIEuwEJDwoNCgUEAQIAAxIEuwESEwoNCgUEAQIACBIEuwEUPAoQCggEAQIACJwI
ABIEuwEVOwqjAQoCBAISBsABANMBARqUASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQmluYXV0
aHpNYW5hZ2VtZW50U2VydmljZVYxLkNyZWF0ZUF0dGVzdG9yXVtnb29nbGUuY2xvdWQuYmlu
YXJ5YXV0aG9yaXphdGlvbi52MS5CaW5hdXRoek1hbmFnZW1lbnRTZXJ2aWNlVjEuQ3JlYXRl
QXR0ZXN0b3JdLgoKCwoDBAIBEgTAAQgdCmkKBAQCAgASBsMBAsgBBBpZIFJlcXVpcmVkLiBU
aGUgcGFyZW50IG9mIHRoaXMKIFthdHRlc3Rvcl1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhv
cml6YXRpb24udjEuQXR0ZXN0b3JdLgoKDQoFBAICAAUSBMMBAggKDQoFBAICAAESBMMBCQ8K
DQoFBAICAAMSBMMBEhMKDwoFBAICAAgSBsMBFMgBAwoQCggEAgIACJwIABIExAEEKgoRCgcE
AgIACJ8IEgbFAQTHAQUKWwoEBAICARIEywECQhpNIFJlcXVpcmVkLiBUaGUgW2F0dGVzdG9y
c11bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0ZXN0b3JdIElELgoK
DQoFBAICAQUSBMsBAggKDQoFBAICAQESBMsBCRQKDQoFBAICAQMSBMsBFxgKDQoFBAICAQgS
BMsBGUEKEAoIBAICAQicCAASBMsBGkAKkgIKBAQCAgISBNIBAkEagwIgUmVxdWlyZWQuIFRo
ZSBpbml0aWFsCiBbYXR0ZXN0b3JdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9u
LnYxLkF0dGVzdG9yXSB2YWx1ZS4gVGhlIHNlcnZpY2UKIHdpbGwgb3ZlcndyaXRlIHRoZSBb
YXR0ZXN0b3IKIG5hbWVdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0
dGVzdG9yLm5hbWVdIGZpZWxkIHdpdGggdGhlCiByZXNvdXJjZSBuYW1lLCBpbiB0aGUgZm9y
bWF0IGBwcm9qZWN0cy8qL2F0dGVzdG9ycy8qYC4KCg0KBQQCAgIGEgTSAQIKCg0KBQQCAgIB
EgTSAQsTCg0KBQQCAgIDEgTSARYXCg0KBQQCAgIIEgTSARhAChAKCAQCAgIInAgAEgTSARk/
Cp0BCgIEAxIG1wEA4QEBGo4BIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtCaW5hdXRoek1hbmFn
ZW1lbnRTZXJ2aWNlVjEuR2V0QXR0ZXN0b3JdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3Jp
emF0aW9uLnYxLkJpbmF1dGh6TWFuYWdlbWVudFNlcnZpY2VWMS5HZXRBdHRlc3Rvcl0uCgoL
CgMEAwESBNcBCBoKnAEKBAQDAgASBtsBAuABBBqLASBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlCiBbYXR0ZXN0b3JdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0
dGVzdG9yXSB0byByZXRyaWV2ZSwgaW4KIHRoZSBmb3JtYXQgYHByb2plY3RzLyovYXR0ZXN0
b3JzLypgLgoKDQoFBAMCAAUSBNsBAggKDQoFBAMCAAESBNsBCQ0KDQoFBAMCAAMSBNsBEBEK
DwoFBAMCAAgSBtsBEuABAwoQCggEAwIACJwIABIE3AEEKgoRCgcEAwIACJ8IEgbdAQTfAQUK
owEKAgQEEgblAQDsAQEalAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0JpbmF1dGh6TWFuYWdl
bWVudFNlcnZpY2VWMS5VcGRhdGVBdHRlc3Rvcl1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhv
cml6YXRpb24udjEuQmluYXV0aHpNYW5hZ2VtZW50U2VydmljZVYxLlVwZGF0ZUF0dGVzdG9y
XS4KCgsKAwQEARIE5QEIHQqlAgoEBAQCABIE6wECQRqWAiBSZXF1aXJlZC4gVGhlIHVwZGF0
ZWQKIFthdHRlc3Rvcl1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0
ZXN0b3JdIHZhbHVlLiBUaGUgc2VydmljZQogd2lsbCBvdmVyd3JpdGUgdGhlIFthdHRlc3Rv
cgogbmFtZV1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0ZXN0b3Iu
bmFtZV0gZmllbGQgd2l0aCB0aGUKIHJlc291cmNlIG5hbWUgaW4gdGhlIHJlcXVlc3QgVVJM
LCBpbiB0aGUgZm9ybWF0IGBwcm9qZWN0cy8qL2F0dGVzdG9ycy8qYC4KCg0KBQQEAgAGEgTr
AQIKCg0KBQQEAgABEgTrAQsTCg0KBQQEAgADEgTrARYXCg0KBQQEAgAIEgTrARhAChAKCAQE
AgAInAgAEgTrARk/CqEBCgIEBRIG8AEAhAIBGpIBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtC
aW5hdXRoek1hbmFnZW1lbnRTZXJ2aWNlVjEuTGlzdEF0dGVzdG9yc11bZ29vZ2xlLmNsb3Vk
LmJpbmFyeWF1dGhvcml6YXRpb24udjEuQmluYXV0aHpNYW5hZ2VtZW50U2VydmljZVYxLkxp
c3RBdHRlc3RvcnNdLgoKCwoDBAUBEgTwAQgcCqoBCgQEBQIAEgb0AQL5AQQamQEgUmVxdWly
ZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9qZWN0IGFzc29jaWF0ZWQgd2l0aCB0
aGUKIFthdHRlc3RvcnNdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkF0
dGVzdG9yXSwgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLypgLgoKDQoFBAUCAAUSBPQBAggK
DQoFBAUCAAESBPQBCQ8KDQoFBAUCAAMSBPQBEhMKDwoFBAUCAAgSBvQBFPkBAwoQCggEBQIA
CJwIABIE9QEEKgoRCgcEBQIACJ8IEgb2AQT4AQUKlwEKBAQFAgESBP0BAhYaiAEgUmVxdWVz
dGVkIHBhZ2Ugc2l6ZS4gVGhlIHNlcnZlciBtYXkgcmV0dXJuIGZld2VyIHJlc3VsdHMgdGhh
biByZXF1ZXN0ZWQuIElmCiB1bnNwZWNpZmllZCwgdGhlIHNlcnZlciB3aWxsIHBpY2sgYW4g
YXBwcm9wcmlhdGUgZGVmYXVsdC4KCg0KBQQFAgEFEgT9AQIHCg0KBQQFAgEBEgT9AQgRCg0K
BQQFAgEDEgT9ARQVCqUCCgQEBQICEgSDAgIYGpYCIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBw
YWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLiBUeXBpY2FsbHksCiB0
aGlzIGlzIHRoZSB2YWx1ZSBvZgogW0xpc3RBdHRlc3RvcnNSZXNwb25zZS5uZXh0X3BhZ2Vf
dG9rZW5dW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkxpc3RBdHRlc3Rv
cnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dCiByZXR1cm5lZCBmcm9tIHRoZSBwcmV2aW91
cyBjYWxsIHRvIHRoZSBgTGlzdEF0dGVzdG9yc2AgbWV0aG9kLgoKDQoFBAUCAgUSBIMCAggK
DQoFBAUCAgESBIMCCRMKDQoFBAUCAgMSBIMCFhcKogEKAgQGEgaIAgCRAgEakwEgUmVzcG9u
c2UgbWVzc2FnZSBmb3IKIFtCaW5hdXRoek1hbmFnZW1lbnRTZXJ2aWNlVjEuTGlzdEF0dGVz
dG9yc11bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQmluYXV0aHpNYW5h
Z2VtZW50U2VydmljZVYxLkxpc3RBdHRlc3RvcnNdLgoKCwoDBAYBEgSIAggdClYKBAQGAgAS
BIoCAiIaSCBUaGUgbGlzdCBvZiBbYXR0ZXN0b3JzXVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0
aG9yaXphdGlvbi52MS5BdHRlc3Rvcl0uCgoNCgUEBgIABBIEigICCgoNCgUEBgIABhIEigIL
EwoNCgUEBgIAARIEigIUHQoNCgUEBgIAAxIEigIgIQqgAgoEBAYCARIEkAICHRqRAiBBIHRv
a2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4gUGFzcyB0aGlzIHZh
bHVlIGluIHRoZQogW0xpc3RBdHRlc3RvcnNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5j
bG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLkxpc3RBdHRlc3RvcnNSZXF1ZXN0LnBhZ2Vf
dG9rZW5dCiBmaWVsZCBpbiB0aGUgc3Vic2VxdWVudCBjYWxsIHRvIHRoZSBgTGlzdEF0dGVz
dG9yc2AgbWV0aG9kIHRvIHJldHJpZXZlIHRoZQogbmV4dCBwYWdlIG9mIHJlc3VsdHMuCgoN
CgUEBgIBBRIEkAICCAoNCgUEBgIBARIEkAIJGAoNCgUEBgIBAxIEkAIbHAqjAQoCBAcSBpUC
AJ8CARqUASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQmluYXV0aHpNYW5hZ2VtZW50U2Vydmlj
ZVYxLkRlbGV0ZUF0dGVzdG9yXVtnb29nbGUuY2xvdWQuYmluYXJ5YXV0aG9yaXphdGlvbi52
MS5CaW5hdXRoek1hbmFnZW1lbnRTZXJ2aWNlVjEuRGVsZXRlQXR0ZXN0b3JdLgoKCwoDBAcB
EgSVAggdCpsBCgQEBwIAEgaZAgKeAgQaigEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZQog
W2F0dGVzdG9yc11bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6YXRpb24udjEuQXR0ZXN0
b3JdIHRvIGRlbGV0ZSwgaW4gdGhlCiBmb3JtYXQgYHByb2plY3RzLyovYXR0ZXN0b3JzLypg
LgoKDQoFBAcCAAUSBJkCAggKDQoFBAcCAAESBJkCCQ0KDQoFBAcCAAMSBJkCEBEKDwoFBAcC
AAgSBpkCEp4CAwoQCggEBwIACJwIABIEmgIEKgoRCgcEBwIACJ8IEgabAgSdAgUKOgoCBAgS
BqICAKsCARosIFJlcXVlc3QgdG8gcmVhZCB0aGUgY3VycmVudCBzeXN0ZW0gcG9saWN5LgoK
CwoDBAgBEgSiAggeCpIBCgQECAIAEgalAgKqAgQagQEgUmVxdWlyZWQuIFRoZSByZXNvdXJj
ZSBuYW1lLCBpbiB0aGUgZm9ybWF0IGBsb2NhdGlvbnMvKi9wb2xpY3lgLgogTm90ZSB0aGF0
IHRoZSBzeXN0ZW0gcG9saWN5IGlzIG5vdCBhc3NvY2lhdGVkIHdpdGggYSBwcm9qZWN0LgoK
DQoFBAgCAAUSBKUCAggKDQoFBAgCAAESBKUCCQ0KDQoFBAgCAAMSBKUCEBEKDwoFBAgCAAgS
BqUCEqoCAwoQCggECAIACJwIABIEpgIEKgoRCgcECAIACJ8IEganAgSpAgUKrwEKAgQJEgav
AgDEAgEaoAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1ZhbGlkYXRpb25IZWxwZXJWMS5WYWxp
ZGF0ZUF0dGVzdGF0aW9uT2NjdXJyZW5jZV1bZ29vZ2xlLmNsb3VkLmJpbmFyeWF1dGhvcml6
YXRpb24udjEuVmFsaWRhdGlvbkhlbHBlclYxLlZhbGlkYXRlQXR0ZXN0YXRpb25PY2N1cnJl
bmNlXS4KCgsKAwQJARIErwIILArDAQoEBAkCABIEtAICPxq0ASBSZXF1aXJlZC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlCiBbQXR0ZXN0b3JdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRo
b3JpemF0aW9uLnYxLkF0dGVzdG9yXSBvZiB0aGUKIFtvY2N1cnJlbmNlXVtncmFmZWFzLnYx
Lk9jY3VycmVuY2VdLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9hdHRlc3RvcnMvKmAu
CgoNCgUECQIABRIEtAICCAoNCgUECQIAARIEtAIJEQoNCgUECQIAAxIEtAIUFQoNCgUECQIA
CBIEtAIWPgoQCggECQIACJwIABIEtAIXPQqMAgoEBAkCARIGugICuwIvGvsBIFJlcXVpcmVk
LiBBbiBbQXR0ZXN0YXRpb25PY2N1cnJlbmNlXVtncmFmZWFzLnYxLkF0dGVzdGF0aW9uT2Nj
dXJyZW5jZV0gdG8KIGJlIGNoZWNrZWQgdGhhdCBpdCBjYW4gYmUgdmVyaWZpZWQgYnkgdGhl
IGBBdHRlc3RvcmAuIEl0IGRvZXMgbm90IGhhdmUgdG8KIGJlIGFuIGV4aXN0aW5nIGVudGl0
eSBpbiBDb250YWluZXIgQW5hbHlzaXMuIEl0IG11c3Qgb3RoZXJ3aXNlIGJlIGEgdmFsaWQK
IGBBdHRlc3RhdGlvbk9jY3VycmVuY2VgLgoKDQoFBAkCAQYSBLoCAiIKDQoFBAkCAQESBLoC
Iy4KDQoFBAkCAQMSBLoCMTIKDQoFBAkCAQgSBLsCBi4KEAoIBAkCAQicCAASBLsCBy0KlwEK
BAQJAgISBL8CAkYaiAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBbTm90
ZV1bZ3JhZmVhcy52MS5Ob3RlXSB0byB3aGljaCB0aGUKIGNvbnRhaW5pbmcgW09jY3VycmVu
Y2VdW2dyYWZlYXMudjEuT2NjdXJyZW5jZV0gaXMgYXNzb2NpYXRlZC4KCg0KBQQJAgIFEgS/
AgIICg0KBQQJAgIBEgS/AgkYCg0KBQQJAgIDEgS/AhscCg0KBQQJAgIIEgS/Ah1FChAKCAQJ
AgIInAgAEgS/Ah5ECpUBCgQECQIDEgTDAgJOGoYBIFJlcXVpcmVkLiBUaGUgVVJJIG9mIHRo
ZSBhcnRpZmFjdCAoZS5nLiBjb250YWluZXIgaW1hZ2UpIHRoYXQgaXMgdGhlCiBzdWJqZWN0
IG9mIHRoZSBjb250YWluaW5nIFtPY2N1cnJlbmNlXVtncmFmZWFzLnYxLk9jY3VycmVuY2Vd
LgoKDQoFBAkCAwUSBMMCAggKDQoFBAkCAwESBMMCCSAKDQoFBAkCAwMSBMMCIyQKDQoFBAkC
AwgSBMMCJU0KEAoIBAkCAwicCAASBMMCJkwKsAEKAgQKEgbIAgDaAgEaoQEgUmVzcG9uc2Ug
bWVzc2FnZSBmb3IKIFtWYWxpZGF0aW9uSGVscGVyVjEuVmFsaWRhdGVBdHRlc3RhdGlvbk9j
Y3VycmVuY2VdW2dvb2dsZS5jbG91ZC5iaW5hcnlhdXRob3JpemF0aW9uLnYxLlZhbGlkYXRp
b25IZWxwZXJWMS5WYWxpZGF0ZUF0dGVzdGF0aW9uT2NjdXJyZW5jZV0uCgoLCgMECgESBMgC
CC0KOgoEBAoEABIGygIC0wIDGiogVGhlIGVudW0gcmV0dXJuZWQgaW4gdGhlIGByZXN1bHRg
IGZpZWxkLgoKDQoFBAoEAAESBMoCBw0KHgoGBAoEAAIAEgTMAgQbGg4gVW5zcGVjaWZpZWQu
CgoPCgcECgQAAgABEgTMAgQWCg8KBwQKBAACAAISBMwCGRoKRwoGBAoEAAIBEgTPAgQRGjcg
VGhlIEF0dGVzdGF0aW9uIHdhcyBhYmxlIHRvIHZlcmlmaWVkIGJ5IHRoZSBBdHRlc3Rvci4K
Cg8KBwQKBAACAQESBM8CBAwKDwoHBAoEAAIBAhIEzwIPEApLCgYECgQAAgISBNICBCMaOyBU
aGUgQXR0ZXN0YXRpb24gd2FzIG5vdCBhYmxlIHRvIHZlcmlmaWVkIGJ5IHRoZSBBdHRlc3Rv
ci4KCg8KBwQKBAACAgESBNICBB4KDwoHBAoEAAICAhIE0gIhIgo5CgQECgIAEgTWAgIUGisg
VGhlIHJlc3VsdCBvZiB0aGUgQXR0ZXN0YXRpb24gdmFsaWRhdGlvbi4KCg0KBQQKAgAGEgTW
AgIICg0KBQQKAgABEgTWAgkPCg0KBQQKAgADEgTWAhITCk8KBAQKAgESBNkCAhsaQSBUaGUg
cmVhc29uIGZvciBkZW5pYWwgaWYgdGhlIEF0dGVzdGF0aW9uIGNvdWxkbid0IGJlIHZhbGlk
YXRlZC4KCg0KBQQKAgEFEgTZAgIICg0KBQQKAgEBEgTZAgkWCg0KBQQKAgEDEgTZAhkaYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest ===
    # Fields for GetPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::UpdatePolicyRequest ===
    # Fields for UpdatePolicyRequest
    # Field: policy Type: 11 (.google.cloud.binaryauthorization.v1.Policy)

# === Message: Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest ===
    # Fields for CreateAttestorRequest
    # Field: parent Type: 9 ()
    # Field: attestor_id Type: 9 ()
    # Field: attestor Type: 11 (.google.cloud.binaryauthorization.v1.Attestor)

# === Message: Google::Cloud::Binaryauthorization::V1::Service::GetAttestorRequest ===
    # Fields for GetAttestorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::UpdateAttestorRequest ===
    # Fields for UpdateAttestorRequest
    # Field: attestor Type: 11 (.google.cloud.binaryauthorization.v1.Attestor)

# === Message: Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsRequest ===
    # Fields for ListAttestorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsResponse ===
    # Fields for ListAttestorsResponse
    # Field: attestors Type: 11 (.google.cloud.binaryauthorization.v1.Attestor)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::DeleteAttestorRequest ===
    # Fields for DeleteAttestorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::GetSystemPolicyRequest ===
    # Fields for GetSystemPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest ===
    # Fields for ValidateAttestationOccurrenceRequest
    # Field: attestor Type: 9 ()
    # Field: attestation Type: 11 (.grafeas.v1.AttestationOccurrence)
    # Field: occurrence_note Type: 9 ()
    # Field: occurrence_resource_uri Type: 9 ()

# === Message: Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse ===
    # Fields for ValidateAttestationOccurrenceResponse
    # Field: result Type: 14 (.google.cloud.binaryauthorization.v1.ValidateAttestationOccurrenceResponse.Result)
    # Field: denial_reason Type: 9 ()

# Enum: ValidateAttestationOccurrenceResponse::Result
our $ValidateAttestationOccurrenceResponse_RESULT_UNSPECIFIED = 0;
our $ValidateAttestationOccurrenceResponse_VERIFIED = 1;
our $ValidateAttestationOccurrenceResponse_ATTESTATION_NOT_VERIFIABLE = 2;

# === Service Client: Google::Cloud::Binaryauthorization::V1::Service::BinauthzManagementServiceV1Client ===
package Google::Cloud::Binaryauthorization::V1::Service::BinauthzManagementServiceV1Client;

=pod

=head2 Service Client: Google::Cloud::Binaryauthorization::V1::Service::BinauthzManagementServiceV1Client

Client stub representing the remote C<BinauthzManagementServiceV1> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<binaryauthorization.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'binaryauthorization.googleapis.com:443' );

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

sub get_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'GetPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Resources::Policy',
    });
}

sub update_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::UpdatePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'UpdatePolicy',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Resources::Policy',
    });
}

sub create_attestor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'CreateAttestor',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Resources::Attestor',
    });
}

sub get_attestor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::GetAttestorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'GetAttestor',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Resources::Attestor',
    });
}

sub update_attestor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::UpdateAttestorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'UpdateAttestor',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Resources::Attestor',
    });
}

sub list_attestors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'ListAttestors',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsResponse',
    });
}

sub delete_attestor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::DeleteAttestorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'DeleteAttestor',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

# === Service Client: Google::Cloud::Binaryauthorization::V1::Service::SystemPolicyV1Client ===
package Google::Cloud::Binaryauthorization::V1::Service::SystemPolicyV1Client;

=pod

=head2 Service Client: Google::Cloud::Binaryauthorization::V1::Service::SystemPolicyV1Client

Client stub representing the remote C<SystemPolicyV1> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<binaryauthorization.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'binaryauthorization.googleapis.com:443' );

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

sub get_system_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::GetSystemPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.SystemPolicyV1',
        method         => 'GetSystemPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Resources::Policy',
    });
}

# === Service Client: Google::Cloud::Binaryauthorization::V1::Service::ValidationHelperV1Client ===
package Google::Cloud::Binaryauthorization::V1::Service::ValidationHelperV1Client;

=pod

=head2 Service Client: Google::Cloud::Binaryauthorization::V1::Service::ValidationHelperV1Client

Client stub representing the remote C<ValidationHelperV1> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<binaryauthorization.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'binaryauthorization.googleapis.com:443' );

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

sub validate_attestation_occurrence {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.binaryauthorization.v1.ValidationHelperV1',
        method         => 'ValidateAttestationOccurrence',
        request        => $req,
        response_class => 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Binaryauthorization::V1::Service - Compiled Protocol Buffers messages for google/cloud/binaryauthorization/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Binaryauthorization::V1::Service;

    my $msg = Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/binaryauthorization/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest

Request message for
[BinauthzManagementServiceV1.GetPolicy][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.GetPolicy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[policy][google.cloud.binaryauthorization.v1.Policy] to retrieve, in the
format `projects/*/policy`.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::UpdatePolicyRequest

Request message for
[BinauthzManagementServiceV1.UpdatePolicy][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.UpdatePolicy].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Cloud::Binaryauthorization::V1::Resources::Policy>)

Required. A new or updated
[policy][google.cloud.binaryauthorization.v1.Policy] value. The service
will overwrite the [policy
name][google.cloud.binaryauthorization.v1.Policy.name] field with the
resource name in the request URL, in the format `projects/*/policy`.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest

Request message for
[BinauthzManagementServiceV1.CreateAttestor][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.CreateAttestor].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of this
[attestor][google.cloud.binaryauthorization.v1.Attestor].

=item * C<< $msg->attestor_id() >> / C<< $msg->attestor_id($value) >>

Type: C<String>

Required. The [attestors][google.cloud.binaryauthorization.v1.Attestor] ID.

=item * C<< $msg->attestor() >> / C<< $msg->attestor($value) >>

Type: C<Message> (L<Google::Cloud::Binaryauthorization::V1::Resources::Attestor>)

Required. The initial
[attestor][google.cloud.binaryauthorization.v1.Attestor] value. The service
will overwrite the [attestor
name][google.cloud.binaryauthorization.v1.Attestor.name] field with the
resource name, in the format `projects/*/attestors/*`.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::GetAttestorRequest

Request message for
[BinauthzManagementServiceV1.GetAttestor][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.GetAttestor].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[attestor][google.cloud.binaryauthorization.v1.Attestor] to retrieve, in
the format `projects/*/attestors/*`.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::UpdateAttestorRequest

Request message for
[BinauthzManagementServiceV1.UpdateAttestor][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.UpdateAttestor].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attestor() >> / C<< $msg->attestor($value) >>

Type: C<Message> (L<Google::Cloud::Binaryauthorization::V1::Resources::Attestor>)

Required. The updated
[attestor][google.cloud.binaryauthorization.v1.Attestor] value. The service
will overwrite the [attestor
name][google.cloud.binaryauthorization.v1.Attestor.name] field with the
resource name in the request URL, in the format `projects/*/attestors/*`.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsRequest

Request message for
[BinauthzManagementServiceV1.ListAttestors][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.ListAttestors].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the project associated with the
[attestors][google.cloud.binaryauthorization.v1.Attestor], in the format
`projects/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server may return fewer results than requested. If
unspecified, the server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return. Typically,
this is the value of
[ListAttestorsResponse.next_page_token][google.cloud.binaryauthorization.v1.ListAttestorsResponse.next_page_token]
returned from the previous call to the `ListAttestors` method.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsResponse

Response message for
[BinauthzManagementServiceV1.ListAttestors][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.ListAttestors].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attestors() >> / C<< $msg->attestors($value) >>

Type: C<Message> (L<Google::Cloud::Binaryauthorization::V1::Resources::Attestor>)

The list of [attestors][google.cloud.binaryauthorization.v1.Attestor].

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Pass this value in the
[ListAttestorsRequest.page_token][google.cloud.binaryauthorization.v1.ListAttestorsRequest.page_token]
field in the subsequent call to the `ListAttestors` method to retrieve the
next page of results.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::DeleteAttestorRequest

Request message for
[BinauthzManagementServiceV1.DeleteAttestor][google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1.DeleteAttestor].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[attestors][google.cloud.binaryauthorization.v1.Attestor] to delete, in the
format `projects/*/attestors/*`.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::GetSystemPolicyRequest

Request to read the current system policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name, in the format `locations/*/policy`.
Note that the system policy is not associated with a project.

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest

Request message for
[ValidationHelperV1.ValidateAttestationOccurrence][google.cloud.binaryauthorization.v1.ValidationHelperV1.ValidateAttestationOccurrence].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attestor() >> / C<< $msg->attestor($value) >>

Type: C<String>

Required. The resource name of the
[Attestor][google.cloud.binaryauthorization.v1.Attestor] of the
[occurrence][grafeas.v1.Occurrence], in the format
`projects/*/attestors/*`.

=item * C<< $msg->attestation() >> / C<< $msg->attestation($value) >>

Type: C<Message> (L<Grafeas::V1::Attestation::AttestationOccurrence>)

Required. An [AttestationOccurrence][grafeas.v1.AttestationOccurrence] to
be checked that it can be verified by the `Attestor`. It does not have to
be an existing entity in Container Analysis. It must otherwise be a valid
`AttestationOccurrence`.

=item * C<< $msg->occurrence_note() >> / C<< $msg->occurrence_note($value) >>

Type: C<String>

Required. The resource name of the [Note][grafeas.v1.Note] to which the
containing [Occurrence][grafeas.v1.Occurrence] is associated.

=item * C<< $msg->occurrence_resource_uri() >> / C<< $msg->occurrence_resource_uri($value) >>

Type: C<String>

Required. The URI of the artifact (e.g. container image) that is the
subject of the containing [Occurrence][grafeas.v1.Occurrence].

=back

=head2 Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse

Response message for
[ValidationHelperV1.ValidateAttestationOccurrence][google.cloud.binaryauthorization.v1.ValidationHelperV1.ValidateAttestationOccurrence].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Enum> (L<Google::Cloud::Binaryauthorization::V1::ValidateAttestationOccurrenceResponse::Result>)

The result of the Attestation validation.

=item * C<< $msg->denial_reason() >> / C<< $msg->denial_reason($value) >>

Type: C<String>

The reason for denial if the Attestation couldn't be validated.

=back

=head3 Enum: ValidateAttestationOccurrenceResponse::Result

=over 4

=item * C<RESULT_UNSPECIFIED> => C<0>

=item * C<VERIFIED> => C<1>

=item * C<ATTESTATION_NOT_VERIFIABLE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Binaryauthorization::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
