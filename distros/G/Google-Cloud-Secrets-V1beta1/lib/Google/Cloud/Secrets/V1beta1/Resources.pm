package Google::Cloud::Secrets::V1beta1::Resources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvc2VjcmV0cy92MWJldGExL3Jlc291cmNlcy5wcm90bxIcZ29vZ2xl
LmNsb3VkLnNlY3JldHMudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90byKMAwoGU2VjcmV0EhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJTCgtyZXBsaWNh
dGlvbhgCIAEoCzIpLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuUmVwbGljYXRpb25C
BuBBBeBBAlILcmVwbGljYXRpb24SQAoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSSAoGbGFiZWxzGAQgAygLMjAuZ29v
Z2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXQuTGFiZWxzRW50cnlSBmxhYmVscxo5
CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBOk3qQUoKI3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0EiNwcm9qZWN0
cy97cHJvamVjdH0vc2VjcmV0cy97c2VjcmV0fSK2AwoNU2VjcmV0VmVyc2lvbhIXCgRuYW1l
GAEgASgJQgPgQQNSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQgoMZGVzdHJveV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgtkZXN0cm95VGltZRJMCgVzdGF0ZRgE
IAEoDjIxLmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbi5TdGF0
ZUID4EEDUgVzdGF0ZSJICgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB0VOQUJM
RUQQARIMCghESVNBQkxFRBACEg0KCURFU1RST1lFRBADOm7qQWsKKnNlY3JldG1hbmFnZXIu
Z29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lvbhI9cHJvamVjdHMve3Byb2plY3R9L3NlY3Jl
dHMve3NlY3JldH0vdmVyc2lvbnMve3NlY3JldF92ZXJzaW9ufSLxAgoLUmVwbGljYXRpb24S
UwoJYXV0b21hdGljGAEgASgLMjMuZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5SZXBs
aWNhdGlvbi5BdXRvbWF0aWNIAFIJYXV0b21hdGljEloKDHVzZXJfbWFuYWdlZBgCIAEoCzI1
Lmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuUmVwbGljYXRpb24uVXNlck1hbmFnZWRI
AFILdXNlck1hbmFnZWQaCwoJQXV0b21hdGljGpQBCgtVc2VyTWFuYWdlZBJeCghyZXBsaWNh
cxgBIAMoCzI9Lmdvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuUmVwbGljYXRpb24uVXNl
ck1hbmFnZWQuUmVwbGljYUID4EECUghyZXBsaWNhcxolCgdSZXBsaWNhEhoKCGxvY2F0aW9u
GAEgASgJUghsb2NhdGlvbkINCgtyZXBsaWNhdGlvbiIjCg1TZWNyZXRQYXlsb2FkEhIKBGRh
dGEYASABKAxSBGRhdGFC7gEKJmNvbS5nb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52MWJl
dGExQg5SZXNvdXJjZXNQcm90b1ABWjpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3JldHMvYXBp
djFiZXRhMS9zZWNyZXRzcGI7c2VjcmV0c3BiogIDR1NNqgIiR29vZ2xlLkNsb3VkLlNlY3Jl
dE1hbmFnZXIuVjFCZXRhMcoCIkdvb2dsZVxDbG91ZFxTZWNyZXRNYW5hZ2VyXFYxYmV0YTHq
AiVHb29nbGU6OkNsb3VkOjpTZWNyZXRNYW5hZ2VyOjpWMWJldGExSrAxCgcSBQ4AsQEBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAPwoJCgIIJRIDFgA/CggKAQgSAxcAUQoJ
CgIICxIDFwBRCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALwoJCgIICBIDGQAvCggK
AQgSAxoAPwoJCgIIARIDGgA/CggKAQgSAxsAIQoJCgIIJBIDGwAhCggKAQgSAxwAPwoJCgII
KRIDHAA/CggKAQgSAx0APgoJCgIILRIDHQA+CqkCCgIEABIEJQBKARqcAiBBIFtTZWNyZXRd
W2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XSBpcyBhIGxvZ2ljYWwgc2Vj
cmV0IHdob3NlCiB2YWx1ZSBhbmQgdmVyc2lvbnMgY2FuIGJlIGFjY2Vzc2VkLgoKIEEgW1Nl
Y3JldF1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRdIGlzIG1hZGUgdXAg
b2YgemVybyBvciBtb3JlCiBbU2VjcmV0VmVyc2lvbnNdW2dvb2dsZS5jbG91ZC5zZWNyZXRz
LnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0gdGhhdCByZXByZXNlbnQKIHRoZSBzZWNyZXQgZGF0
YS4KCgoKAwQAARIDJQgOCgsKAwQABxIEJgIpBAoNCgUEAAedCBIEJgIpBAqKAQoEBAACABID
LgI+Gn0gT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZQogW1NlY3JldF1b
Z29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRdIGluIHRoZSBmb3JtYXQKIGBw
cm9qZWN0cy8qL3NlY3JldHMvKmAuCgoMCgUEAAIABRIDLgIICgwKBQQAAgABEgMuCQ0KDAoF
BAACAAMSAy4QEQoMCgUEAAIACBIDLhI9Cg8KCAQAAgAInAgAEgMuEzwK3QEKBAQAAgESBDQC
NwQazgEgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHJlcGxpY2F0aW9uIHBvbGljeSBvZiB0
aGUgc2VjcmV0IGRhdGEgYXR0YWNoZWQgdG8KIHRoZSBbU2VjcmV0XVtnb29nbGUuY2xvdWQu
c2VjcmV0cy52MWJldGExLlNlY3JldF0uCgogVGhlIHJlcGxpY2F0aW9uIHBvbGljeSBjYW5u
b3QgYmUgY2hhbmdlZCBhZnRlciB0aGUgU2VjcmV0IGhhcyBiZWVuIGNyZWF0ZWQuCgoMCgUE
AAIBBhIDNAINCgwKBQQAAgEBEgM0DhkKDAoFBAACAQMSAzQcHQoNCgUEAAIBCBIENB43AwoP
CggEAAIBCJwIABIDNQQrCg8KCAQAAgEInAgBEgM2BCoKbgoEBAACAhIEOwI8MhpgIE91dHB1
dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGUKIFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5z
ZWNyZXRzLnYxYmV0YTEuU2VjcmV0XSB3YXMgY3JlYXRlZC4KCgwKBQQAAgIGEgM7AhsKDAoF
BAACAgESAzscJwoMCgUEAAICAxIDOyorCgwKBQQAAgIIEgM8BjEKDwoIBAACAgicCAASAzwH
MAr9AwoEBAACAxIDSQIhGu8DIFRoZSBsYWJlbHMgYXNzaWduZWQgdG8gdGhpcyBTZWNyZXQu
CgogTGFiZWwga2V5cyBtdXN0IGJlIGJldHdlZW4gMSBhbmQgNjMgY2hhcmFjdGVycyBsb25n
LCBoYXZlIGEgVVRGLTggZW5jb2RpbmcKIG9mIG1heGltdW0gMTI4IGJ5dGVzLCBhbmQgbXVz
dCBjb25mb3JtIHRvIHRoZSBmb2xsb3dpbmcgUENSRSByZWd1bGFyCiBleHByZXNzaW9uOiBg
W1xwe0xsfVxwe0xvfV1bXHB7TGx9XHB7TG99XHB7Tn1fLV17MCw2Mn1gCgogTGFiZWwgdmFs
dWVzIG11c3QgYmUgYmV0d2VlbiAwIGFuZCA2MyBjaGFyYWN0ZXJzIGxvbmcsIGhhdmUgYSBV
VEYtOAogZW5jb2Rpbmcgb2YgbWF4aW11bSAxMjggYnl0ZXMsIGFuZCBtdXN0IGNvbmZvcm0g
dG8gdGhlIGZvbGxvd2luZyBQQ1JFCiByZWd1bGFyIGV4cHJlc3Npb246IGBbXHB7TGx9XHB7
TG99XHB7Tn1fLV17MCw2M31gCgogTm8gbW9yZSB0aGFuIDY0IGxhYmVscyBjYW4gYmUgYXNz
aWduZWQgdG8gYSBnaXZlbiByZXNvdXJjZS4KCgwKBQQAAgMGEgNJAhUKDAoFBAACAwESA0kW
HAoMCgUEAAIDAxIDSR8gCkMKAgQBEgVNAIIBARo2IEEgc2VjcmV0IHZlcnNpb24gcmVzb3Vy
Y2UgaW4gdGhlIFNlY3JldCBNYW5hZ2VyIEFQSS4KCgoKAwQBARIDTQgVCgsKAwQBBxIETgJR
BAoNCgUEAQedCBIETgJRBAp+CgQEAQQAEgRVAmgDGnAgVGhlIHN0YXRlIG9mIGEgW1NlY3Jl
dFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0s
CiBpbmRpY2F0aW5nIGlmIGl0IGNhbiBiZSBhY2Nlc3NlZC4KCgwKBQQBBAABEgNVBwwKQQoG
BAEEAAIAEgNXBBoaMiBOb3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIGlzIHVudXNlZCBhbmQg
aW52YWxpZC4KCg4KBwQBBAACAAESA1cEFQoOCgcEAQQAAgACEgNXGBkKYgoGBAEEAAIBEgNb
BBAaUyBUaGUgW1NlY3JldFZlcnNpb25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEu
U2VjcmV0VmVyc2lvbl0gbWF5IGJlCiBhY2Nlc3NlZC4KCg4KBwQBBAACAQESA1sECwoOCgcE
AQQAAgECEgNbDg8K/AEKBgQBBAACAhIDYgQRGuwBIFRoZSBbU2VjcmV0VmVyc2lvbl1bZ29v
Z2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRWZXJzaW9uXSBtYXkgbm90CiBiZSBh
Y2Nlc3NlZCwgYnV0IHRoZSBzZWNyZXQgZGF0YSBpcyBzdGlsbCBhdmFpbGFibGUgYW5kIGNh
biBiZSBwbGFjZWQKIGJhY2sgaW50byB0aGUKIFtFTkFCTEVEXVtnb29nbGUuY2xvdWQuc2Vj
cmV0cy52MWJldGExLlNlY3JldFZlcnNpb24uU3RhdGUuRU5BQkxFRF0KIHN0YXRlLgoKDgoH
BAEEAAICARIDYgQMCg4KBwQBBAACAgISA2IPEAq6AQoGBAEEAAIDEgNnBBIaqgEgVGhlIFtT
ZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNp
b25dIGlzCiBkZXN0cm95ZWQgYW5kIHRoZSBzZWNyZXQgZGF0YSBpcyBubyBsb25nZXIgc3Rv
cmVkLiBBIHZlcnNpb24gbWF5IG5vdAogbGVhdmUgdGhpcyBzdGF0ZSBvbmNlIGVudGVyZWQu
CgoOCgcEAQQAAgMBEgNnBA0KDgoHBAEEAAIDAhIDZxARCuUCCgQEAQIAEgNxAj4a1wIgT3V0
cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZQogW1NlY3JldFZlcnNpb25dW2dv
b2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0gaW4gdGhlIGZvcm1h
dAogYHByb2plY3RzLyovc2VjcmV0cy8qL3ZlcnNpb25zLypgLgoKIFtTZWNyZXRWZXJzaW9u
XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb25dIElEcyBpbiBh
CiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldF0gc3RhcnQg
YXQgMSBhbmQgYXJlCiBpbmNyZW1lbnRlZCBmb3IgZWFjaCBzdWJzZXF1ZW50IHZlcnNpb24g
b2YgdGhlIHNlY3JldC4KCgwKBQQBAgAFEgNxAggKDAoFBAECAAESA3EJDQoMCgUEAQIAAxID
cRARCgwKBQQBAgAIEgNxEj0KDwoIBAECAAicCAASA3ETPAp8CgQEAQIBEgR1AnYyGm4gT3V0
cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZQogW1NlY3JldFZlcnNpb25dW2dvb2ds
ZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0gd2FzIGNyZWF0ZWQuCgoM
CgUEAQIBBhIDdQIbCgwKBQQBAgEBEgN1HCcKDAoFBAECAQMSA3UqKwoMCgUEAQIBCBIDdgYx
Cg8KCAQBAgEInAgAEgN2BzAKjwIKBAQBAgISBHwCfTIagAIgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHRoaXMKIFtTZWNyZXRWZXJzaW9uXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGEx
LlNlY3JldFZlcnNpb25dIHdhcyBkZXN0cm95ZWQuCiBPbmx5IHByZXNlbnQgaWYgW3N0YXRl
XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNpb24uc3RhdGVdCiBp
cyBbREVTVFJPWUVEXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldFZlcnNp
b24uU3RhdGUuREVTVFJPWUVEXS4KCgwKBQQBAgIGEgN8AhsKDAoFBAECAgESA3wcKAoMCgUE
AQICAxIDfCssCgwKBQQBAgIIEgN9BjEKDwoIBAECAgicCAASA30HMApzCgQEAQIDEgSBAQI+
GmUgT3V0cHV0IG9ubHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZQogW1NlY3JldFZlcnNp
b25dW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0VmVyc2lvbl0uCgoNCgUE
AQIDBhIEgQECBwoNCgUEAQIDARIEgQEIDQoNCgUEAQIDAxIEgQEQEQoNCgUEAQIDCBIEgQES
PQoQCggEAQIDCJwIABIEgQETPApMCgIEAhIGhQEAqQEBGj4gQSBwb2xpY3kgdGhhdCBkZWZp
bmVzIHRoZSByZXBsaWNhdGlvbiBjb25maWd1cmF0aW9uIG9mIGRhdGEuCgoLCgMEAgESBIUB
CBMKigEKBAQCAwASBIkBAhYafCBBIHJlcGxpY2F0aW9uIHBvbGljeSB0aGF0IHJlcGxpY2F0
ZXMgdGhlCiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldF0g
cGF5bG9hZCB3aXRob3V0IGFueQogcmVzdHJpY3Rpb25zLgoKDQoFBAIDAAESBIkBChMK9gEK
BAQCAwESBo8BAp0BAxrlASBBIHJlcGxpY2F0aW9uIHBvbGljeSB0aGF0IHJlcGxpY2F0ZXMg
dGhlCiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlNlY3JldF0gcGF5
bG9hZCBpbnRvIHRoZSBsb2NhdGlvbnMKIHNwZWNpZmllZCBpbgogW1JlcGxpY2F0aW9uLlVz
ZXJNYW5hZ2VkLnJlcGxpY2FzXVtnb29nbGUuY2xvdWQuc2VjcmV0cy52MWJldGExLlJlcGxp
Y2F0aW9uLlVzZXJNYW5hZ2VkLnJlcGxpY2FzXQoKDQoFBAIDAQESBI8BChUKYQoGBAIDAQMA
EgaSAQSWAQUaTyBSZXByZXNlbnRzIGEgUmVwbGljYSBmb3IgdGhpcwogW1NlY3JldF1bZ29v
Z2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRdLgoKDwoHBAIDAQMAARIEkgEMEwpk
CggEAgMBAwACABIElQEGGhpSIFRoZSBjYW5vbmljYWwgSURzIG9mIHRoZSBsb2NhdGlvbiB0
byByZXBsaWNhdGUgZGF0YS4KIEZvciBleGFtcGxlOiBgInVzLWVhc3QxImAuCgoRCgkEAgMB
AwACAAUSBJUBBgwKEQoJBAIDAQMAAgABEgSVAQ0VChEKCQQCAwEDAAIAAxIElQEYGQp8CgYE
AgMBAgASBJwBBEsabCBSZXF1aXJlZC4gVGhlIGxpc3Qgb2YgUmVwbGljYXMgZm9yIHRoaXMK
IFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XS4KCiBDYW5u
b3QgYmUgZW1wdHkuCgoPCgcEAgMBAgAEEgScAQQMCg8KBwQCAwECAAYSBJwBDRQKDwoHBAID
AQIAARIEnAEVHQoPCgcEAgMBAgADEgScASAhCg8KBwQCAwECAAgSBJwBIkoKEgoKBAIDAQIA
CJwIABIEnAEjSQo5CgQEAggAEgagAQKoAQMaKSBUaGUgcmVwbGljYXRpb24gcG9saWN5IGZv
ciB0aGlzIHNlY3JldC4KCg0KBQQCCAABEgSgAQgTCn0KBAQCAgASBKMBBBwabyBUaGUgW1Nl
Y3JldF1bZ29vZ2xlLmNsb3VkLnNlY3JldHMudjFiZXRhMS5TZWNyZXRdIHdpbGwgYXV0b21h
dGljYWxseSBiZQogcmVwbGljYXRlZCB3aXRob3V0IGFueSByZXN0cmljdGlvbnMuCgoNCgUE
AgIABhIEowEEDQoNCgUEAgIAARIEowEOFwoNCgUEAgIAAxIEowEaGwp4CgQEAgIBEgSnAQQh
GmogVGhlIFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRzLnYxYmV0YTEuU2VjcmV0XSB3
aWxsIG9ubHkgYmUgcmVwbGljYXRlZAogaW50byB0aGUgbG9jYXRpb25zIHNwZWNpZmllZC4K
Cg0KBQQCAgEGEgSnAQQPCg0KBQQCAgEBEgSnARAcCg0KBQQCAgEDEgSnAR8gCsYBCgIEAxIG
rgEAsQEBGrcBIEEgc2VjcmV0IHBheWxvYWQgcmVzb3VyY2UgaW4gdGhlIFNlY3JldCBNYW5h
Z2VyIEFQSS4gVGhpcyBjb250YWlucyB0aGUKIHNlbnNpdGl2ZSBzZWNyZXQgZGF0YSB0aGF0
IGlzIGFzc29jaWF0ZWQgd2l0aCBhCiBbU2VjcmV0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLnNl
Y3JldHMudjFiZXRhMS5TZWNyZXRWZXJzaW9uXS4KCgsKAwQDARIErgEIFQo+CgQEAwIAEgSw
AQIRGjAgVGhlIHNlY3JldCBkYXRhLiBNdXN0IGJlIG5vIGxhcmdlciB0aGFuIDY0S2lCLgoK
DQoFBAMCAAUSBLABAgcKDQoFBAMCAAESBLABCAwKDQoFBAMCAAMSBLABDxBiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Secrets::V1beta1::Resources::Secret ===
    # Fields for Secret
    # Field: name Type: 9 ()
    # Field: replication Type: 11 (.google.cloud.secrets.v1beta1.Replication)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.secrets.v1beta1.Secret.LabelsEntry)

# === Message: Google::Cloud::Secrets::V1beta1::Resources::SecretVersion ===
    # Fields for SecretVersion
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: destroy_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.secrets.v1beta1.SecretVersion.State)

# Enum: SecretVersion::State
our $SecretVersion_STATE_UNSPECIFIED = 0;
our $SecretVersion_ENABLED = 1;
our $SecretVersion_DISABLED = 2;
our $SecretVersion_DESTROYED = 3;

# === Message: Google::Cloud::Secrets::V1beta1::Resources::Replication ===
    # Fields for Replication
    # Field: automatic Type: 11 (.google.cloud.secrets.v1beta1.Replication.Automatic)
    # Field: user_managed Type: 11 (.google.cloud.secrets.v1beta1.Replication.UserManaged)

# === Message: Google::Cloud::Secrets::V1beta1::Resources::SecretPayload ===
    # Fields for SecretPayload
    # Field: data Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Secrets::V1beta1::Resources - Compiled Protocol Buffers messages for google/cloud/secrets/v1beta1/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Secrets::V1beta1::Resources;

    my $msg = Google::Cloud::Secrets::V1beta1::Resources::Secret->new({
        name => $name,
        replication => $replication,
        create_time => $create_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Secrets::V1beta1::Resources::Secret->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/secrets/v1beta1/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Secrets::V1beta1::Resources::Secret

A [Secret][google.cloud.secrets.v1beta1.Secret] is a logical secret whose
value and versions can be accessed.

A [Secret][google.cloud.secrets.v1beta1.Secret] is made up of zero or more
[SecretVersions][google.cloud.secrets.v1beta1.SecretVersion] that represent
the secret data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the
[Secret][google.cloud.secrets.v1beta1.Secret] in the format
`projects/*/secrets/*`.

=item * C<< $msg->replication() >> / C<< $msg->replication($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Replication>)

Required. Immutable. The replication policy of the secret data attached to
the [Secret][google.cloud.secrets.v1beta1.Secret].

The replication policy cannot be changed after the Secret has been created.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the
[Secret][google.cloud.secrets.v1beta1.Secret] was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Secret::LabelsEntry>)

The labels assigned to this Secret.

Label keys must be between 1 and 63 characters long, have a UTF-8 encoding
of maximum 128 bytes, and must conform to the following PCRE regular
expression: `[\p{Ll}\p{Lo}][\p{Ll}\p{Lo}\p{N}_-]{0,62}`

Label values must be between 0 and 63 characters long, have a UTF-8
encoding of maximum 128 bytes, and must conform to the following PCRE
regular expression: `[\p{Ll}\p{Lo}\p{N}_-]{0,63}`

No more than 64 labels can be assigned to a given resource.

=back

=head2 Google::Cloud::Secrets::V1beta1::Resources::SecretVersion

A secret version resource in the Secret Manager API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] in the format
`projects/*/secrets/*/versions/*`.

[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] IDs in a
[Secret][google.cloud.secrets.v1beta1.Secret] start at 1 and are
incremented for each subsequent version of the secret.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] was created.

=item * C<< $msg->destroy_time() >> / C<< $msg->destroy_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion] was destroyed.
Only present if [state][google.cloud.secrets.v1beta1.SecretVersion.state]
is [DESTROYED][google.cloud.secrets.v1beta1.SecretVersion.State.DESTROYED].

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Secrets::V1beta1::SecretVersion::State>)

Output only. The current state of the
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion].

=back

=head3 Enum: SecretVersion::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=item * C<DESTROYED> => C<3>

=back

=head2 Google::Cloud::Secrets::V1beta1::Resources::Replication

A policy that defines the replication configuration of data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->automatic() >> / C<< $msg->automatic($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Replication::Automatic>)

The [Secret][google.cloud.secrets.v1beta1.Secret] will automatically be
replicated without any restrictions.

=item * C<< $msg->user_managed() >> / C<< $msg->user_managed($value) >>

Type: C<Message> (L<Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged>)

The [Secret][google.cloud.secrets.v1beta1.Secret] will only be replicated
into the locations specified.

=back

=head2 Google::Cloud::Secrets::V1beta1::Resources::SecretPayload

A secret payload resource in the Secret Manager API. This contains the
sensitive secret data that is associated with a
[SecretVersion][google.cloud.secrets.v1beta1.SecretVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

The secret data. Must be no larger than 64KiB.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Secrets::V1beta1::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
