package Google::Cloud::Discoveryengine::V1alpha::SessionService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService };
    eval { require Google::Cloud::Discoveryengine::V1alpha::Session };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2Vzc2lvbl9zZXJ2aWNl
LnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGkhn
b29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29udmVyc2F0aW9uYWxfc2Vh
cmNoX3NlcnZpY2UucHJvdG8aMmdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBo
YS9zZXNzaW9uLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8ivQEKEExpc3RG
aWxlc1JlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgKJmRpc2NvdmVyeWVuZ2luZS5n
b29nbGVhcGlzLmNvbS9TZXNzaW9uUgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQFSBmZp
bHRlchIgCglwYWdlX3NpemUYAyABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgE
IAEoCUID4EEBUglwYWdlVG9rZW4ihQEKEUxpc3RGaWxlc1Jlc3BvbnNlEkgKBWZpbGVzGAEg
AygLMjIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkZpbGVNZXRhZGF0
YVIFZmlsZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAMgASgJUg1uZXh0UGFnZVRva2VuMrURCg5T
ZXNzaW9uU2VydmljZRKNAwoNQ3JlYXRlU2Vzc2lvbhI6Lmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5DcmVhdGVTZXNzaW9uUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZXNzaW9uIpACgtPkkwL4ASI+L3YxYWxwaGEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2Vzc2lvbnM6B3Nl
c3Npb25aVyJML3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxl
Y3Rpb25zLyovZGF0YVN0b3Jlcy8qfS9zZXNzaW9uczoHc2Vzc2lvblpUIkkvdjFhbHBoYS97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyp9
L3Nlc3Npb25zOgdzZXNzaW9u2kEOcGFyZW50LHNlc3Npb24S0QIKDURlbGV0ZVNlc3Npb24S
Oi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGVsZXRlU2Vzc2lvblJl
cXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHki6wGC0+STAt0BKj4vdjFhbHBoYS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXNzaW9ucy8qfVpOKkwv
djFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0
YVN0b3Jlcy8qL3Nlc3Npb25zLyp9WksqSS92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovc2Vzc2lvbnMvKn3aQQRuYW1lEqoD
Cg1VcGRhdGVTZXNzaW9uEjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlVwZGF0ZVNlc3Npb25SZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLlNlc3Npb24irQKC0+STApACMkYvdjFhbHBoYS97c2Vzc2lvbi5uYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3Nlc3Npb25zLyp9OgdzZXNzaW9uWl8y
VC92MWFscGhhL3tzZXNzaW9uLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXNzaW9ucy8qfToHc2Vzc2lvblpcMlEvdjFhbHBoYS97
c2Vzc2lvbi5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdp
bmVzLyovc2Vzc2lvbnMvKn06B3Nlc3Npb27aQRNzZXNzaW9uLHVwZGF0ZV9tYXNrEuICCgpH
ZXRTZXNzaW9uEjcuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdldFNl
c3Npb25SZXF1ZXN0Gi0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNl
c3Npb24i6wGC0+STAt0BEj4vdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2RhdGFTdG9yZXMvKi9zZXNzaW9ucy8qfVpOEkwvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3Nlc3Npb25zLyp9WksS
SS92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9l
bmdpbmVzLyovc2Vzc2lvbnMvKn3aQQRuYW1lEvUCCgxMaXN0U2Vzc2lvbnMSOS5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdFNlc3Npb25zUmVxdWVzdBo6Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0U2Vzc2lvbnNSZXNwb25z
ZSLtAYLT5JMC3QESPi92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9k
YXRhU3RvcmVzLyp9L3Nlc3Npb25zWk4STC92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn0vc2Vzc2lvbnNaSxJJL3Yx
YWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5n
aW5lcy8qfS9zZXNzaW9uc9pBBnBhcmVudBLgAQoJTGlzdEZpbGVzEjYuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RGaWxlc1JlcXVlc3QaNy5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdEZpbGVzUmVzcG9uc2UiYoLT5JMCUxJR
L3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyov
ZW5naW5lcy8qL3Nlc3Npb25zLyp9L2ZpbGVz2kEGcGFyZW50GlLKQR5kaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtQp8CCihjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhQhNTZXNzaW9uU2VydmljZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292
ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5l
cGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYx
QWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFK6iYKBxIFDgDIAQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgBSCgkKAgMFEgMXADwKCQoCAwYS
AxgAJQoICgEIEgMaAEEKCQoCCCUSAxoAQQoICgEIEgMbAGkKCQoCCAsSAxsAaQoICgEIEgMc
ACIKCQoCCAoSAxwAIgoICgEIEgMdADQKCQoCCAgSAx0ANAoICgEIEgMeAEEKCQoCCAESAx4A
QQoICgEIEgMfAC0KCQoCCCQSAx8ALQoICgEIEgMgAEEKCQoCCCkSAyAAQQoICgEIEgMhAEAK
CQoCCC0SAyEAQApLCgIGABIFJACHAQEaPiBTZXJ2aWNlIGZvciBtYW5hZ2luZyBTZXNzaW9u
cyBhbmQgU2Vzc2lvbi1yZWxhdGVkIHJlc291cmNlcy4KCgoKAwYAARIDJAgWCgoKAwYAAxID
JQJGCgwKBQYAA5kIEgMlAkYKCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CqQBCgQGAAIA
EgQtAjsDGpUBIENyZWF0ZXMgYSBTZXNzaW9uLgoKIElmIHRoZSBbU2Vzc2lvbl1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlc3Npb25dIHRvIGNyZWF0ZQogYWxy
ZWFkeSBleGlzdHMsIGFuIEFMUkVBRFlfRVhJU1RTIGVycm9yIGlzIHJldHVybmVkLgoKDAoF
BgACAAESAy0GEwoMCgUGAAIAAhIDLRQoCgwKBQYAAgADEgMtMzoKDQoFBgACAAQSBC4EOQYK
EQoJBgACAASwyrwiEgQuBDkGCgwKBQYAAgAEEgM6BDwKDwoIBgACAASbCAASAzoEPAqeAQoE
BgACARIEQQJMAxqPASBEZWxldGVzIGEgU2Vzc2lvbi4KCiBJZiB0aGUgW1Nlc3Npb25dW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZXNzaW9uXSB0byBkZWxldGUK
IGRvZXMgbm90IGV4aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYA
AgEBEgNBBhMKDAoFBgACAQISA0EUKAoMCgUGAAIBAxIDQTNICg0KBQYAAgEEEgRCBEoGChEK
CQYAAgEEsMq8IhIEQgRKBgoMCgUGAAIBBBIDSwQyCg8KCAYAAgEEmwgAEgNLBDIK9gEKBAYA
AgISBFMCYQMa5wEgVXBkYXRlcyBhIFNlc3Npb24uCgogW1Nlc3Npb25dW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZXNzaW9uXSBhY3Rpb24gdHlwZSBjYW5ub3QK
IGJlIGNoYW5nZWQuIElmIHRoZSBbU2Vzc2lvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlNlc3Npb25dCiB0byB1cGRhdGUgZG9lcyBub3QgZXhpc3QsIGEgTk9U
X0ZPVU5EIGVycm9yIGlzIHJldHVybmVkLgoKDAoFBgACAgESA1MGEwoMCgUGAAICAhIDUxQo
CgwKBQYAAgIDEgNTMzoKDQoFBgACAgQSBFQEXwYKEQoJBgACAgSwyrwiEgRUBF8GCgwKBQYA
AgIEEgNgBEEKDwoIBgACAgSbCAASA2AEQQofCgQGAAIDEgRkAm8DGhEgR2V0cyBhIFNlc3Np
b24uCgoMCgUGAAIDARIDZAYQCgwKBQYAAgMCEgNkESIKDAoFBgACAwMSA2QtNAoNCgUGAAID
BBIEZQRtBgoRCgkGAAIDBLDKvCISBGUEbQYKDAoFBgACAwQSA24EMgoPCggGAAIDBJsIABID
bgQyCnAKBAYAAgQSBHMCfgMaYiBMaXN0cyBhbGwgU2Vzc2lvbnMgYnkgdGhlaXIgcGFyZW50
CiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0
YVN0b3JlXS4KCgwKBQYAAgQBEgNzBhIKDAoFBgACBAISA3MTJgoMCgUGAAIEAxIDczFFCg0K
BQYAAgQEEgR0BHwGChEKCQYAAgQEsMq8IhIEdAR8BgoMCgUGAAIEBBIDfQQ0Cg8KCAYAAgQE
mwgAEgN9BDQKRgoEBgACBRIGgQEChgEDGjYgTGlzdHMgbWV0YWRhdGEgZm9yIGFsbCBmaWxl
cyBpbiB0aGUgY3VycmVudCBzZXNzaW9uLgoKDQoFBgACBQESBIEBBg8KDQoFBgACBQISBIEB
ECAKDQoFBgACBQMSBIEBKzwKDwoFBgACBQQSBoIBBIQBBgoTCgkGAAIFBLDKvCISBoIBBIQB
BgoNCgUGAAIFBBIEhQEENAoQCggGAAIFBJsIABIEhQEENAqHAQoCBAASBowBALkBARp5IFJl
cXVlc3QgbWVzc2FnZSBmb3IKIFtTZXNzaW9uU2VydmljZS5MaXN0RmlsZXNdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZXNzaW9uU2VydmljZS5MaXN0RmlsZXNd
CiBtZXRob2QuCgoLCgMEAAESBIwBCBgK5wEKBAQAAgASBpEBApYBBBrWASBSZXF1aXJlZC4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNlc3Npb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9u
fS9lbmdpbmVzL3tlbmdpbmV9L3Nlc3Npb25zL3tzZXNzaW9ufWAKIE5hbWUgb2YgdGhlIHNl
c3Npb24gcmVzb3VyY2UgdG8gd2hpY2ggdGhlIGZpbGUgYmVsb25nLgoKDQoFBAACAAUSBJEB
AggKDQoFBAACAAESBJEBCQ8KDQoFBAACAAMSBJEBEhMKDwoFBAACAAgSBpEBFJYBAwoQCggE
AAIACJwIABIEkgEEKgoRCgcEAAIACJ8IEgaTAQSVAQUKsgQKBAQAAgESBKkBAj0aowQgT3B0
aW9uYWwuIFRoZSBmaWx0ZXIgc3ludGF4IGNvbnNpc3RzIG9mIGFuIGV4cHJlc3Npb24gbGFu
Z3VhZ2UgZm9yCiBjb25zdHJ1Y3RpbmcgYSBwcmVkaWNhdGUgZnJvbSBvbmUgb3IgbW9yZSBm
aWVsZHMgb2YgdGhlIGZpbGVzIGJlaW5nCiBmaWx0ZXJlZC4gRmlsdGVyIGV4cHJlc3Npb24g
aXMgY2FzZS1zZW5zaXRpdmUuIEN1cnJlbnRseSBzdXBwb3J0ZWQgZmllbGQKIG5hbWVzIGFy
ZToKICogdXBsb2FkX3RpbWUKICogbGFzdF9hZGRfdGltZQogKiBsYXN0X3VzZV90aW1lCiAq
IGZpbGVfbmFtZQogKiBtaW1lX3R5cGUKCiBTb21lIGV4YW1wbGVzIG9mIGZpbHRlcnMgd291
bGQgYmU6CiAqICJmaWxlX25hbWUgPSAnZmlsZV8xJyIKICogImZpbGVfbmFtZSA9ICdmaWxl
XzEnIEFORCBtaW1lX3R5cGUgPSAndGV4dC9wbGFpbiciCiAqICJsYXN0X3VzZV90aW1lID4g
JzIwMjUtMDYtMTRUMTI6MDA6MDBaJyIKCiBGb3IgYSBmdWxsIGRlc2NyaXB0aW9uIG9mIHRo
ZSBmaWx0ZXIgZm9ybWF0LCBwbGVhc2UKIHNlZSBodHRwczovL2dvb2dsZS5haXAuZGV2LzE2
MC4KCg0KBQQAAgEFEgSpAQIICg0KBQQAAgEBEgSpAQkPCg0KBQQAAgEDEgSpARITCg0KBQQA
AgEIEgSpARQ8ChAKCAQAAgEInAgAEgSpARU7Ct4CCgQEAAICEgSwAQI/Gs8CIE9wdGlvbmFs
LiBUaGUgbWF4aW11bSBudW1iZXIgb2YgZmlsZXMgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBt
YXkgcmV0dXJuCiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVkLCBhdCBt
b3N0IDEwMCBmaWxlcyB3aWxsIGJlIHJldHVybmVkLgogVGhlIG1heGltdW0gdmFsdWUgaXMg
MTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCiBJZiB1
c2VyIHNwZWNpZmllcyBhIHZhbHVlIGxlc3MgdGhhbiBvciBlcXVhbCB0byAwIC0gdGhlIHJl
cXVlc3Qgd2lsbCBiZQogcmVqZWN0ZWQgd2l0aCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9y
LgoKDQoFBAACAgUSBLABAgcKDQoFBAACAgESBLABCBEKDQoFBAACAgMSBLABFBUKDQoFBAAC
AggSBLABFj4KEAoIBAACAgicCAASBLABFz0KnAIKBAQAAgMSBLgBAkEajQIgT3B0aW9uYWwu
IEEgcGFnZSB0b2tlbiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RGaWxlc2AgY2Fs
bC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdo
ZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RG
aWxlc2AKIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tl
biAoZXhjZXB0IGBwYWdlX3NpemVgLCB3aGljaAogbWF5IGRpZmZlcikuCgoNCgUEAAIDBRIE
uAECCAoNCgUEAAIDARIEuAEJEwoNCgUEAAIDAxIEuAEWFwoNCgUEAAIDCBIEuAEYQAoQCggE
AAIDCJwIABIEuAEZPwqIAQoCBAESBr4BAMgBARp6IFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBb
U2Vzc2lvblNlcnZpY2UuTGlzdEZpbGVzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuU2Vzc2lvblNlcnZpY2UuTGlzdEZpbGVzXQogbWV0aG9kLgoKCwoDBAEBEgS+
AQgZClcKBAQBAgASBMABAiIaSSBUaGUgW0ZpbGVNZXRhZGF0YV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLkZpbGVNZXRhZGF0YV1zLgoKDQoFBAECAAQSBMABAgoK
DQoFBAECAAYSBMABCxcKDQoFBAECAAESBMABGB0KDQoFBAECAAMSBMABICEKjQIKBAQBAgES
BMcBAh0a/gEgQSB0b2tlbiB0byByZXRyaWV2ZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4KIFBh
c3MgdGhpcyB2YWx1ZSBpbiB0aGUKIFtMaXN0RmlsZXNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFtYWluLkxpc3RGaWxlc1JlcXVlc3QucGFn
ZV90b2tlbl0KIGZpZWxkIGluIHRoZSBzdWJzZXF1ZW50IGNhbGwgdG8gYExpc3RGaWxlc2Ag
bWV0aG9kIHRvCiByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuCgoNCgUEAQIB
BRIExwECCAoNCgUEAQIBARIExwEJGAoNCgUEAQIBAxIExwEbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest ===
    # Fields for ListFilesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesResponse ===
    # Fields for ListFilesResponse
    # Field: files Type: 11 (.google.cloud.discoveryengine.v1alpha.FileMetadata)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::SessionService::SessionServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::SessionService::SessionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::SessionService::SessionServiceClient

Client stub representing the remote C<SessionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::CreateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'CreateSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Session::Session',
    });
}

sub delete_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::DeleteSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'DeleteSession',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::UpdateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'UpdateSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Session::Session',
    });
}

sub get_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::GetSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'GetSession',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Session::Session',
    });
}

sub list_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ListSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'ListSessions',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ListSessionsResponse',
    });
}

sub list_files {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'ListFiles',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SessionService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/session_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SessionService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest->new({
        parent => $parent,
        filter => $filter,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/session_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest

Request message for
[SessionService.ListFiles][google.cloud.discoveryengine.v1alpha.SessionService.ListFiles]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Session.
Format:
`projects/{project}/locations/{location}/collections/{collection}/engines/{engine}/sessions/{session}`
Name of the session resource to which the file belong.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter syntax consists of an expression language for
constructing a predicate from one or more fields of the files being
filtered. Filter expression is case-sensitive. Currently supported field
names are:
* upload_time
* last_add_time
* last_use_time
* file_name
* mime_type

Some examples of filters would be:
* "file_name = 'file_1'"
* "file_name = 'file_1' AND mime_type = 'text/plain'"
* "last_use_time > '2025-06-14T12:00:00Z'"

For a full description of the filter format, please
see https://google.aip.dev/160.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of files to return. The service may return
fewer than this value. If unspecified, at most 100 files will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.
If user specifies a value less than or equal to 0 - the request will be
rejected with an INVALID_ARGUMENT error.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token received from a previous `ListFiles` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListFiles`
must match the call that provided the page token (except `page_size`, which
may differ).

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesResponse

Response message for
[SessionService.ListFiles][google.cloud.discoveryengine.v1alpha.SessionService.ListFiles]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata>)

The [FileMetadata][google.cloud.discoveryengine.v1alpha.FileMetadata]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve next page of results.
Pass this value in the
[ListFilesRequest.page_token][google.cloud.discoveryengine.v1main.ListFilesRequest.page_token]
field in the subsequent call to `ListFiles` method to
retrieve the next page of results.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SessionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
