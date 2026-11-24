package Google::Cloud::Support::V2::SupportEventSubscriptionService;

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
    eval { require Google::Cloud::Support::V2::SupportEventSubscription };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9zdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbl9z
ZXJ2aWNlLnByb3RvEhdnb29nbGUuY2xvdWQuc3VwcG9ydC52MhocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOGdvb2dsZS9j
bG91ZC9zdXBwb3J0L3YyL3N1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uLnByb3RvGhtnb29n
bGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvIvMBCiVDcmVhdGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0ElQKBnBhcmVu
dBgBIAEoCUI84EEC+kE2EjRjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vU3VwcG9ydEV2
ZW50U3Vic2NyaXB0aW9uUgZwYXJlbnQSdAoac3VwcG9ydF9ldmVudF9zdWJzY3JpcHRpb24Y
AiABKAsyMS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5TdXBwb3J0RXZlbnRTdWJzY3JpcHRp
b25CA+BBAlIYc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uInYKIkdldFN1cHBvcnRFdmVudFN1
YnNjcmlwdGlvblJlcXVlc3QSUAoEbmFtZRgBIAEoCUI84EEC+kE2CjRjbG91ZHN1cHBvcnQu
Z29vZ2xlYXBpcy5jb20vU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUgRuYW1lIocCCiRMaXN0
U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uc1JlcXVlc3QSVAoGcGFyZW50GAEgASgJQjzgQQL6
QTYSNGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9TdXBwb3J0RXZlbnRTdWJzY3JpcHRp
b25SBnBhcmVudBIbCgZmaWx0ZXIYAiABKAlCA+BBAVIGZmlsdGVyEiYKDHNob3dfZGVsZXRl
ZBgDIAEoCEID4EEBUgtzaG93RGVsZXRlZBIgCglwYWdlX3NpemUYBCABKAVCA+BBAVIIcGFn
ZVNpemUSIgoKcGFnZV90b2tlbhgFIAEoCUID4EEBUglwYWdlVG9rZW4iwgEKJUxpc3RTdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb25zUmVzcG9uc2UScQobc3VwcG9ydF9ldmVudF9zdWJzY3Jp
cHRpb25zGAEgAygLMjEuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuU3VwcG9ydEV2ZW50U3Vi
c2NyaXB0aW9uUhlzdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLfAQolVXBkYXRlU3VwcG9ydEV2ZW50U3Vic2NyaXB0
aW9uUmVxdWVzdBJ0ChpzdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbhgBIAEoCzIxLmdvb2ds
ZS5jbG91ZC5zdXBwb3J0LnYyLlN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbkID4EECUhhzdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb24SQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sieQolRGVsZXRlU3VwcG9ydEV2ZW50
U3Vic2NyaXB0aW9uUmVxdWVzdBJQCgRuYW1lGAEgASgJQjzgQQL6QTYKNGNsb3Vkc3VwcG9y
dC5nb29nbGVhcGlzLmNvbS9TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SBG5hbWUiewonVW5k
ZWxldGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0ElAKBG5hbWUYASABKAlCPOBB
AvpBNgo0Y2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tL1N1cHBvcnRFdmVudFN1YnNjcmlw
dGlvblIEbmFtZSJ6CiZFeHB1bmdlU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUmVxdWVzdBJQ
CgRuYW1lGAEgASgJQjzgQQL6QTYKNGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9TdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb25SBG5hbWUykg4KH1N1cHBvcnRFdmVudFN1YnNjcmlwdGlv
blNlcnZpY2USkwIKHkNyZWF0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbhI+Lmdvb2dsZS5j
bG91ZC5zdXBwb3J0LnYyLkNyZWF0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvblJlcXVlc3Qa
MS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24ifoLT
5JMCVCI2L3YyL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qfS9zdXBwb3J0RXZlbnRTdWJzY3Jp
cHRpb25zOhpzdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbtpBIXBhcmVudCxzdXBwb3J0X2V2
ZW50X3N1YnNjcmlwdGlvbhLUAQobR2V0U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uEjsuZ29v
Z2xlLmNsb3VkLnN1cHBvcnQudjIuR2V0U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUmVxdWVz
dBoxLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLlN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbiJF
gtPkkwI4EjYvdjIve25hbWU9b3JnYW5pemF0aW9ucy8qL3N1cHBvcnRFdmVudFN1YnNjcmlw
dGlvbnMvKn3aQQRuYW1lEucBCh1MaXN0U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9ucxI9Lmdv
b2dsZS5jbG91ZC5zdXBwb3J0LnYyLkxpc3RTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zUmVx
dWVzdBo+Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkxpc3RTdXBwb3J0RXZlbnRTdWJzY3Jp
cHRpb25zUmVzcG9uc2UiR4LT5JMCOBI2L3YyL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qfS9z
dXBwb3J0RXZlbnRTdWJzY3JpcHRpb25z2kEGcGFyZW50ErQCCh5VcGRhdGVTdXBwb3J0RXZl
bnRTdWJzY3JpcHRpb24SPi5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5VcGRhdGVTdXBwb3J0
RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuU3Vw
cG9ydEV2ZW50U3Vic2NyaXB0aW9uIp4BgtPkkwJvMlEvdjIve3N1cHBvcnRfZXZlbnRfc3Vi
c2NyaXB0aW9uLm5hbWU9b3JnYW5pemF0aW9ucy8qL3N1cHBvcnRFdmVudFN1YnNjcmlwdGlv
bnMvKn06GnN1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9u2kEmc3VwcG9ydF9ldmVudF9zdWJz
Y3JpcHRpb24sdXBkYXRlX21hc2sS2gEKHkRlbGV0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlv
bhI+Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkRlbGV0ZVN1cHBvcnRFdmVudFN1YnNjcmlw
dGlvblJlcXVlc3QaMS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5TdXBwb3J0RXZlbnRTdWJz
Y3JpcHRpb24iRYLT5JMCOCo2L3YyL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9zdXBwb3J0RXZl
bnRTdWJzY3JpcHRpb25zLyp92kEEbmFtZRLjAQogVW5kZWxldGVTdXBwb3J0RXZlbnRTdWJz
Y3JpcHRpb24SQC5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5VbmRlbGV0ZVN1cHBvcnRFdmVu
dFN1YnNjcmlwdGlvblJlcXVlc3QaMS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5TdXBwb3J0
RXZlbnRTdWJzY3JpcHRpb24iSoLT5JMCRCI/L3YyL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9z
dXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zLyp9OnVuZGVsZXRlOgEqEswBCh9FeHB1bmdlU3Vw
cG9ydEV2ZW50U3Vic2NyaXB0aW9uEj8uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuRXhwdW5n
ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvblJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1w
dHkiUILT5JMCQyI+L3YyL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9zdXBwb3J0RXZlbnRTdWJz
Y3JpcHRpb25zLyp9OmV4cHVuZ2U6ASraQQRuYW1lGk/KQRtjbG91ZHN1cHBvcnQuZ29vZ2xl
YXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtQs0BChtjb20uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJCJFN1cHBvcnRFdmVudFN1YnNj
cmlwdGlvblNlcnZpY2VQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL3N1cHBvcnQvYXBp
djIvc3VwcG9ydHBiO3N1cHBvcnRwYqoCF0dvb2dsZS5DbG91ZC5TdXBwb3J0LlYyygIXR29v
Z2xlXENsb3VkXFN1cHBvcnRcVjLqAhpHb29nbGU6OkNsb3VkOjpTdXBwb3J0OjpWMkqeNwoH
EgUOAIoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJ
CgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEIK
CQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgSAxoANAoJCgIIJRIDGgA0CggKAQgSAxsATAoJ
CgIICxIDGwBMCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ARQoJCgIICBIDHQBFCggK
AQgSAx4ANAoJCgIIARIDHgA0CggKAQgSAx8ANAoJCgIIKRIDHwA0CggKAQgSAyAAMwoJCgII
LRIDIAAzCkkKAgYAEgUjAIgBARo8IFNlcnZpY2UgZm9yIG1hbmFnaW5nIGN1c3RvbWVyIHN1
cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9ucy4KCgoKAwYAARIDIwgnCgoKAwYAAxIDJAJDCgwK
BQYAA5kIEgMkAkMKCwoDBgADEgQlAiY3Cg0KBQYAA5oIEgQlAiY3CkkKBAYAAgASBCkCMAMa
OyBDcmVhdGVzIGEgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24gZm9yIGFuIG9yZ2FuaXph
dGlvbi4KCgwKBQYAAgABEgMpBiQKDAoFBgACAAISAyklSgoMCgUGAAIAAxIDKg8nCg0KBQYA
AgAEEgQrBC4GChEKCQYAAgAEsMq8IhIEKwQuBgoMCgUGAAIABBIDLwRPCg8KCAYAAgAEmwgA
EgMvBE8KMgoEBgACARIEMwI5AxokIEdldHMgYSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlv
bi4KCgwKBQYAAgEBEgMzBiEKDAoFBgACAQISAzMiRAoMCgUGAAIBAxIDNA8nCg0KBQYAAgEE
EgQ1BDcGChEKCQYAAgEEsMq8IhIENQQ3BgoMCgUGAAIBBBIDOAQyCg8KCAYAAgEEmwgAEgM4
BDIKRgoEBgACAhIEPAJCAxo4IExpc3RzIHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9ucyBm
b3IgYW4gb3JnYW5pemF0aW9uLgoKDAoFBgACAgESAzwGIwoMCgUGAAICAhIDPCRICgwKBQYA
AgIDEgM9DzQKDQoFBgACAgQSBD4EQAYKEQoJBgACAgSwyrwiEgQ+BEAGCgwKBQYAAgIEEgNB
BDQKDwoIBgACAgSbCAASA0EENAo1CgQGAAIDEgRFAk0DGicgVXBkYXRlcyBhIHN1cHBvcnQg
ZXZlbnQgc3Vic2NyaXB0aW9uLgoKDAoFBgACAwESA0UGJAoMCgUGAAIDAhIDRSVKCgwKBQYA
AgMDEgNGDycKDQoFBgACAwQSBEcESgYKEQoJBgACAwSwyrwiEgRHBEoGCg0KBQYAAgMEEgRL
BEwxChAKCAYAAgMEmwgAEgRLBEwxCjoKBAYAAgQSBFACVgMaLCBTb2Z0IGRlbGV0ZXMgYSBz
dXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlvbi4KCgwKBQYAAgQBEgNQBiQKDAoFBgACBAISA1Al
SgoMCgUGAAIEAxIDUQ8nCg0KBQYAAgQEEgRSBFQGChEKCQYAAgQEsMq8IhIEUgRUBgoMCgUG
AAIEBBIDVQQyCg8KCAYAAgQEmwgAEgNVBDIKNwoEBgACBRIEWQJfAxopIFVuZGVsZXRlcyBh
IHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9uLgoKDAoFBgACBQESA1kGJgoMCgUGAAIFAhID
WSdOCgwKBQYAAgUDEgNaDycKDQoFBgACBQQSBFsEXgYKEQoJBgACBQSwyrwiEgRbBF4GCsYG
CgQGAAIGEgaAAQKHAQMatQYgRXhwdW5nZXMgYSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlv
bi4KCiBFWEFNUExFUzoKCiBjVVJMOgoKIGBgYHNoZWxsCiBzdXBwb3J0X2V2ZW50X3N1YnNj
cmlwdGlvbj0ib3JnYW5pemF0aW9ucy8xMjM0NTY3ODkvc3VwcG9ydEV2ZW50U3Vic2NyaXB0
aW9ucy9hYmNkZWYxMjM0NTYiCiBjdXJsIFwKICAgLS1yZXF1ZXN0IFBPU1QgXAogICAtLWhl
YWRlciAiQXV0aG9yaXphdGlvbjogQmVhcmVyICQoZ2Nsb3VkIGF1dGggcHJpbnQtYWNjZXNz
LXRva2VuKSIgXAogICAiaHR0cHM6Ly9jbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vdjIv
JHN1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uOmV4cHVuZ2UiCiBgYGAKCiBQeXRob246Cgog
YGBgcHl0aG9uCiBpbXBvcnQgZ29vZ2xlYXBpY2xpZW50LmRpc2NvdmVyeQoKIGFwaV92ZXJz
aW9uID0gInYyIgogc3VwcG9ydEFwaVNlcnZpY2UgPSBnb29nbGVhcGljbGllbnQuZGlzY292
ZXJ5LmJ1aWxkKAogICAgIHNlcnZpY2VOYW1lPSJjbG91ZHN1cHBvcnQiLAogICAgIHZlcnNp
b249YXBpX3ZlcnNpb24sCiAgICAgZGlzY292ZXJ5U2VydmljZVVybD1mImh0dHBzOi8vY2xv
dWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tLyRkaXNjb3ZlcnkvcmVzdD92ZXJzaW9uPXthcGlf
dmVyc2lvbn0iLAogKQoKIHJlcXVlc3QgPSBzdXBwb3J0QXBpU2VydmljZS5zdXBwb3J0RXZl
bnRTdWJzY3JpcHRpb25zKCkuZXhwdW5nZSgKICAgICBuYW1lPSJvcmdhbml6YXRpb25zLzEy
MzQ1Njc4OS9zdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zL2FiY2RlZjEyMzQ1NiIKICkKIHBy
aW50KHJlcXVlc3QuZXhlY3V0ZSgpKQogYGBgCgoNCgUGAAIGARIEgAEGJQoNCgUGAAIGAhIE
gAEmTAoNCgUGAAIGAxIEgQEPJAoPCgUGAAIGBBIGggEEhQEGChMKCQYAAgYEsMq8IhIGggEE
hQEGCg0KBQYAAgYEEgSGAQQyChAKCAYAAgYEmwgAEgSGAQQyCkMKAgQAEgaLAQCYAQEaNSBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIENyZWF0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbi4KCgsK
AwQAARIEiwEILQqUAQoEBAACABIGjgECkwEEGoMBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJl
c291cmNlIG5hbWUgd2hlcmUgdGhlIHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9uCiB3aWxs
IGJlIGNyZWF0ZWQuIEZvcm1hdDogb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfQoK
DQoFBAACAAUSBI4BAggKDQoFBAACAAESBI4BCQ8KDQoFBAACAAMSBI4BEhMKDwoFBAACAAgS
Bo4BFJMBAwoQCggEAAIACJwIABIEjwEEKgoRCgcEAAIACJ8IEgaQAQSSAQUKQAoEBAACARIG
lgEClwEvGjAgUmVxdWlyZWQuIFRoZSBQdWIvU3ViIGNvbmZpZ3VyYXRpb24gdG8gY3JlYXRl
LgoKDQoFBAACAQYSBJYBAhoKDQoFBAACAQESBJYBGzUKDQoFBAACAQMSBJYBODkKDQoFBAAC
AQgSBJcBBi4KEAoIBAACAQicCAASBJcBBy0KQAoCBAESBpsBAKUBARoyIFJlcXVlc3QgbWVz
c2FnZSBmb3IgR2V0U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uLgoKCwoDBAEBEgSbAQgqCqoB
CgQEAQIAEgafAQKkAQQamQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzdXBwb3J0IGV2
ZW50IHN1YnNjcmlwdGlvbiB0byByZXRyaWV2ZS4KIEZvcm1hdDoKIG9yZ2FuaXphdGlvbnMv
e29yZ2FuaXphdGlvbl9pZH0vc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9ucy97c3Vic2NyaXB0
aW9uX2lkfQoKDQoFBAECAAUSBJ8BAggKDQoFBAECAAESBJ8BCQ0KDQoFBAECAAMSBJ8BEBEK
DwoFBAECAAgSBp8BEqQBAwoQCggEAQIACJwIABIEoAEEKgoRCgcEAQIACJ8IEgahAQSjAQUK
QgoCBAISBqgBAMwBARo0IFJlcXVlc3QgbWVzc2FnZSBmb3IgTGlzdFN1cHBvcnRFdmVudFN1
YnNjcmlwdGlvbnMuCgoLCgMEAgESBKgBCCwKnwEKBAQCAgASBqsBArABBBqOASBSZXF1aXJl
ZC4gVGhlIGZ1bGx5IHF1YWxpZmllZCBuYW1lIG9mIHRoZSBDbG91ZCByZXNvdXJjZSB0byBs
aXN0IHN1cHBvcnQKIGV2ZW50IHN1YnNjcmlwdGlvbnMgdW5kZXIuIEZvcm1hdDogb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9uX2lkfQoKDQoFBAICAAUSBKsBAggKDQoFBAICAAESBKsB
CQ8KDQoFBAICAAMSBKsBEhMKDwoFBAICAAgSBqsBFLABAwoQCggEAgIACJwIABIErAEEKgoR
CgcEAgIACJ8IEgatAQSvAQUKowIKBAQCAgESBLwBAj0alAIgT3B0aW9uYWwuIEZpbHRlciBl
eHByZXNzaW9uIGJhc2VkIG9uIEFJUC0xNjAuCiBTdXBwb3J0ZWQgZmllbGRzOgogLSBwdWJf
c3ViX3RvcGljCiAtIHN0YXRlCgogRXhhbXBsZXM6CiAtIGBwdWJfc3ViX3RvcGljPSJwcm9q
ZWN0cy9leGFtcGxlLXByb2plY3QvdG9waWNzL2V4YW1wbGUtdG9waWMiYAogLSBgc3RhdGU9
V09SS0lOR2AKIC0gYHB1Yl9zdWJfdG9waWM9InByb2plY3RzL2V4YW1wbGUtcHJvamVjdC90
b3BpY3MvZXhhbXBsZS10b3BpYyIgQU5ECiBzdGF0ZT1XT1JLSU5HYAoKDQoFBAICAQUSBLwB
AggKDQoFBAICAQESBLwBCQ8KDQoFBAICAQMSBLwBEhMKDQoFBAICAQgSBLwBFDwKEAoIBAIC
AQicCAASBLwBFTsKdQoEBAICAhIEwAECQRpnIE9wdGlvbmFsLiBXaGV0aGVyIHRvIHNob3cg
ZGVsZXRlZCBzdWJzY3JpcHRpb25zLiBCeSBkZWZhdWx0LCBkZWxldGVkCiBzdWJzY3JpcHRp
b25zIGFyZSBub3QgcmV0dXJuZWQuCgoNCgUEAgICBRIEwAECBgoNCgUEAgICARIEwAEHEwoN
CgUEAgICAxIEwAEWFwoNCgUEAgICCBIEwAEYQAoQCggEAgICCJwIABIEwAEZPwpWCgQEAgID
EgTDAQI/GkggT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBzdXBwb3J0IGV2ZW50
IHN1YnNjcmlwdGlvbnMgdG8gcmV0dXJuLgoKDQoFBAICAwUSBMMBAgcKDQoFBAICAwESBMMB
CBEKDQoFBAICAwMSBMMBFBUKDQoFBAICAwgSBMMBFj4KEAoIBAICAwicCAASBMMBFz0KgwIK
BAQCAgQSBMsBAkEa9AEgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgdGhlIHBhZ2Ug
b2YgcmVzdWx0cyB0byByZXR1cm4uIElmCiB1bnNwZWNpZmllZCwgdGhlIGZpcnN0IHBhZ2Ug
aXMgcmV0cmlldmVkLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMg
cHJvdmlkZWQgdG8KIGBMaXN0U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uc2AgbXVzdCBtYXRj
aCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlCiB0b2tlbi4KCg0KBQQCAgQFEgTL
AQIICg0KBQQCAgQBEgTLAQkTCg0KBQQCAgQDEgTLARYXCg0KBQQCAgQIEgTLARhAChAKCAQC
AgQInAgAEgTLARk/CkMKAgQDEgbPAQDWAQEaNSBSZXNwb25zZSBtZXNzYWdlIGZvciBMaXN0
U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9ucy4KCgsKAwQDARIEzwEILQowCgQEAwIAEgTRAQJE
GiIgVGhlIHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9ucy4KCg0KBQQDAgAEEgTRAQIKCg0K
BQQDAgAGEgTRAQsjCg0KBQQDAgABEgTRASQ/Cg0KBQQDAgADEgTRAUJDCpABCgQEAwIBEgTV
AQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byBy
ZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVy
ZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQDAgEFEgTVAQIICg0KBQQDAgEBEgTV
AQkYCg0KBQQDAgEDEgTVARscCkMKAgQEEgbZAQDjAQEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IFVwZGF0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbi4KCgsKAwQEARIE2QEILQqIAQoEBAQC
ABIG3AEC3QEvGnggUmVxdWlyZWQuIFRoZSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlvbiB0
byB1cGRhdGUuCiBUaGUgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIGNv
bmZpZ3VyYXRpb24gdG8gdXBkYXRlLgoKDQoFBAQCAAYSBNwBAhoKDQoFBAQCAAESBNwBGzUK
DQoFBAQCAAMSBNwBODkKDQoFBAQCAAgSBN0BBi4KEAoIBAQCAAicCAASBN0BBy0KZQoEBAQC
ARIG4QEC4gEvGlUgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuIFRo
ZSBvbmx5IHN1cHBvcnRlZCB2YWx1ZSBpcwogcHViX3N1Yl90b3BpYy4KCg0KBQQEAgEGEgTh
AQIbCg0KBQQEAgEBEgThARwnCg0KBQQEAgEDEgThASorCg0KBQQEAgEIEgTiAQYuChAKCAQE
AgEInAgAEgTiAQctCkMKAgQFEgbmAQDwAQEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIERlbGV0
ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbi4KCgsKAwQFARIE5gEILQqoAQoEBAUCABIG6gEC
7wEEGpcBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc3VwcG9ydCBldmVudCBzdWJzY3Jp
cHRpb24gdG8gZGVsZXRlLgogRm9ybWF0Ogogb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9u
X2lkfS9zdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zL3tzdWJzY3JpcHRpb25faWR9CgoNCgUE
BQIABRIE6gECCAoNCgUEBQIAARIE6gEJDQoNCgUEBQIAAxIE6gEQEQoPCgUEBQIACBIG6gES
7wEDChAKCAQFAgAInAgAEgTrAQQqChEKBwQFAgAInwgSBuwBBO4BBQpFCgIEBhIG8wEA/QEB
GjcgUmVxdWVzdCBtZXNzYWdlIGZvciBVbmRlbGV0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlv
bi4KCgsKAwQGARIE8wEILwqqAQoEBAYCABIG9wEC/AEEGpkBIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24gdG8gdW5kZWxldGUuCiBGb3Jt
YXQ6CiBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L3N1cHBvcnRFdmVudFN1YnNj
cmlwdGlvbnMve3N1YnNjcmlwdGlvbl9pZH0KCg0KBQQGAgAFEgT3AQIICg0KBQQGAgABEgT3
AQkNCg0KBQQGAgADEgT3ARARCg8KBQQGAgAIEgb3ARL8AQMKEAoIBAYCAAicCAASBPgBBCoK
EQoHBAYCAAifCBIG+QEE+wEFCkQKAgQHEgaAAgCKAgEaNiBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IEV4cHVuZ2VTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24uCgoLCgMEBwESBIACCC4KqQEKBAQH
AgASBoQCAokCBBqYASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHN1cHBvcnQgZXZlbnQg
c3Vic2NyaXB0aW9uIHRvIGV4cHVuZ2UuCiBGb3JtYXQ6CiBvcmdhbml6YXRpb25zL3tvcmdh
bml6YXRpb25faWR9L3N1cHBvcnRFdmVudFN1YnNjcmlwdGlvbnMve3N1YnNjcmlwdGlvbl9p
ZH0KCg0KBQQHAgAFEgSEAgIICg0KBQQHAgABEgSEAgkNCg0KBQQHAgADEgSEAhARCg8KBQQH
AgAIEgaEAhKJAgMKEAoIBAcCAAicCAASBIUCBCoKEQoHBAcCAAifCBIGhgIEiAIFYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest ===
    # Fields for CreateSupportEventSubscriptionRequest
    # Field: parent Type: 9 ()
    # Field: support_event_subscription Type: 11 (.google.cloud.support.v2.SupportEventSubscription)

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest ===
    # Fields for GetSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest ===
    # Fields for ListSupportEventSubscriptionsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: show_deleted Type: 8 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse ===
    # Fields for ListSupportEventSubscriptionsResponse
    # Field: support_event_subscriptions Type: 11 (.google.cloud.support.v2.SupportEventSubscription)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest ===
    # Fields for UpdateSupportEventSubscriptionRequest
    # Field: support_event_subscription Type: 11 (.google.cloud.support.v2.SupportEventSubscription)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest ===
    # Fields for DeleteSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest ===
    # Fields for UndeleteSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest ===
    # Fields for ExpungeSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Support::V2::SupportEventSubscriptionService::SupportEventSubscriptionServiceClient ===
package Google::Cloud::Support::V2::SupportEventSubscriptionService::SupportEventSubscriptionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2::SupportEventSubscriptionService::SupportEventSubscriptionServiceClient

Client stub representing the remote C<SupportEventSubscriptionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<support.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'support.googleapis.com:443' );

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

sub create_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'CreateSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription',
    });
}

sub get_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'GetSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription',
    });
}

sub list_support_event_subscriptions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'ListSupportEventSubscriptions',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse',
    });
}

sub update_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'UpdateSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription',
    });
}

sub delete_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'DeleteSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription',
    });
}

sub undelete_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'UndeleteSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription',
    });
}

sub expunge_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'ExpungeSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::SupportEventSubscriptionService - Compiled Protocol Buffers messages for google/cloud/support/v2/support_event_subscription_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::SupportEventSubscriptionService;

    my $msg = Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest->new({
        parent => $parent,
        support_event_subscription => $support_event_subscription,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/support_event_subscription_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest

Request message for CreateSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name where the support event subscription
will be created. Format: organizations/{organization_id}

=item * C<< $msg->support_event_subscription() >> / C<< $msg->support_event_subscription($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription>)

Required. The Pub/Sub configuration to create.

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest

Request message for GetSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to retrieve.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest

Request message for ListSupportEventSubscriptions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The fully qualified name of the Cloud resource to list support
event subscriptions under. Format: organizations/{organization_id}

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression based on AIP-160.
Supported fields:
- pub_sub_topic
- state

Examples:
- `pub_sub_topic="projects/example-project/topics/example-topic"`
- `state=WORKING`
- `pub_sub_topic="projects/example-project/topics/example-topic" AND
state=WORKING`

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

Optional. Whether to show deleted subscriptions. By default, deleted
subscriptions are not returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of support event subscriptions to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the page of results to return. If
unspecified, the first page is retrieved.

When paginating, all other parameters provided to
`ListSupportEventSubscriptions` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse

Response message for ListSupportEventSubscriptions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->support_event_subscriptions() >> / C<< $msg->support_event_subscriptions($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription>)

The support event subscriptions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest

Request message for UpdateSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->support_event_subscription() >> / C<< $msg->support_event_subscription($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription>)

Required. The support event subscription to update.
The `name` field is used to identify the configuration to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update. The only supported value is
pub_sub_topic.

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest

Request message for DeleteSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to delete.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest

Request message for UndeleteSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to undelete.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head2 Google::Cloud::Support::V2::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest

Request message for ExpungeSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to expunge.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::SupportEventSubscriptionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
