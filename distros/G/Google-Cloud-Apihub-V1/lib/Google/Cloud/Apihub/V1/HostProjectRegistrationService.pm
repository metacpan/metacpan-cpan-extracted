package Google::Cloud::Apihub::V1::HostProjectRegistrationService;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvYXBpaHViL3YxL2hvc3RfcHJvamVjdF9yZWdpc3RyYXRpb25fc2Vy
dmljZS5wcm90bxIWZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8irQIKJENyZWF0ZUhvc3RQcm9qZWN0UmVnaXN0cmF0aW9u
UmVxdWVzdBJNCgZwYXJlbnQYASABKAlCNeBBAvpBLxItYXBpaHViLmdvb2dsZWFwaXMuY29t
L0hvc3RQcm9qZWN0UmVnaXN0cmF0aW9uUgZwYXJlbnQSRAocaG9zdF9wcm9qZWN0X3JlZ2lz
dHJhdGlvbl9pZBgCIAEoCUID4EECUhlob3N0UHJvamVjdFJlZ2lzdHJhdGlvbklkEnAKGWhv
c3RfcHJvamVjdF9yZWdpc3RyYXRpb24YAyABKAsyLy5nb29nbGUuY2xvdWQuYXBpaHViLnYx
Lkhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uQgPgQQJSF2hvc3RQcm9qZWN0UmVnaXN0cmF0aW9u
Im4KIUdldEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uUmVxdWVzdBJJCgRuYW1lGAEgASgJQjXg
QQL6QS8KLWFwaWh1Yi5nb29nbGVhcGlzLmNvbS9Ib3N0UHJvamVjdFJlZ2lzdHJhdGlvblIE
bmFtZSL3AQojTGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uc1JlcXVlc3QSTQoGcGFyZW50
GAEgASgJQjXgQQL6QS8SLWFwaWh1Yi5nb29nbGVhcGlzLmNvbS9Ib3N0UHJvamVjdFJlZ2lz
dHJhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIG
ZmlsdGVyEh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnkivQEKJExpc3RIb3N0UHJv
amVjdFJlZ2lzdHJhdGlvbnNSZXNwb25zZRJtChpob3N0X3Byb2plY3RfcmVnaXN0cmF0aW9u
cxgBIAMoCzIvLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuSG9zdFByb2plY3RSZWdpc3RyYXRp
b25SGGhvc3RQcm9qZWN0UmVnaXN0cmF0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4ilAMKF0hvc3RQcm9qZWN0UmVnaXN0cmF0aW9uEhcKBG5hbWUYASAB
KAlCA+BBCFIEbmFtZRJXCgtnY3BfcHJvamVjdBgCIAEoCUI24EEC4EEF+kEtCitjbG91ZHJl
c291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgpnY3BQcm9qZWN0EkAKC2Ny
ZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lOsQB6kHAAQotYXBpaHViLmdvb2dsZWFwaXMuY29tL0hvc3RQcm9qZWN0UmVnaXN0
cmF0aW9uElxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaG9zdFBy
b2plY3RSZWdpc3RyYXRpb25zL3tob3N0X3Byb2plY3RfcmVnaXN0cmF0aW9ufSoYaG9zdFBy
b2plY3RSZWdpc3RyYXRpb25zMhdob3N0UHJvamVjdFJlZ2lzdHJhdGlvbjLhBgoeSG9zdFBy
b2plY3RSZWdpc3RyYXRpb25TZXJ2aWNlErACCh1DcmVhdGVIb3N0UHJvamVjdFJlZ2lzdHJh
dGlvbhI8Lmdvb2dsZS5jbG91ZC5hcGlodWIudjEuQ3JlYXRlSG9zdFByb2plY3RSZWdpc3Ry
YXRpb25SZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5Ib3N0UHJvamVjdFJlZ2lz
dHJhdGlvbiKfAYLT5JMCWSI8L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0v
aG9zdFByb2plY3RSZWdpc3RyYXRpb25zOhlob3N0X3Byb2plY3RfcmVnaXN0cmF0aW9u2kE9
cGFyZW50LGhvc3RfcHJvamVjdF9yZWdpc3RyYXRpb24saG9zdF9wcm9qZWN0X3JlZ2lzdHJh
dGlvbl9pZBLVAQoaR2V0SG9zdFByb2plY3RSZWdpc3RyYXRpb24SOS5nb29nbGUuY2xvdWQu
YXBpaHViLnYxLkdldEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uUmVxdWVzdBovLmdvb2dsZS5j
bG91ZC5hcGlodWIudjEuSG9zdFByb2plY3RSZWdpc3RyYXRpb24iS4LT5JMCPhI8L3YxL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovaG9zdFByb2plY3RSZWdpc3RyYXRpb25zLyp9
2kEEbmFtZRLoAQocTGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9ucxI7Lmdvb2dsZS5jbG91
ZC5hcGlodWIudjEuTGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uc1JlcXVlc3QaPC5nb29n
bGUuY2xvdWQuYXBpaHViLnYxLkxpc3RIb3N0UHJvamVjdFJlZ2lzdHJhdGlvbnNSZXNwb25z
ZSJNgtPkkwI+EjwvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9ob3N0UHJv
amVjdFJlZ2lzdHJhdGlvbnPaQQZwYXJlbnQaScpBFWFwaWh1Yi5nb29nbGVhcGlzLmNvbdJB
Lmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CxQEKGmNv
bS5nb29nbGUuY2xvdWQuYXBpaHViLnYxQiNIb3N0UHJvamVjdFJlZ2lzdHJhdGlvblNlcnZp
Y2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2FwaWh1Yi9hcGl2MS9hcGlodWJwYjth
cGlodWJwYqoCFkdvb2dsZS5DbG91ZC5BcGlIdWIuVjHKAhZHb29nbGVcQ2xvdWRcQXBpSHVi
XFYx6gIZR29vZ2xlOjpDbG91ZDo6QXBpSHViOjpWMUqpNAoHEgUOAM4BAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACkKCAoBCBIDGAAzCgkKAgglEgMY
ADMKCAoBCBIDGQBJCgkKAggLEgMZAEkKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwBE
CgkKAggIEgMbAEQKCAoBCBIDHAAzCgkKAggBEgMcADMKCAoBCBIDHQAzCgkKAggpEgMdADMK
CAoBCBIDHgAyCgkKAggtEgMeADIKTwoCBgASBCEARgEaQyBUaGlzIHNlcnZpY2UgaXMgdXNl
ZCBmb3IgbWFuYWdpbmcgdGhlIGhvc3QgcHJvamVjdCByZWdpc3RyYXRpb25zLgoKCgoDBgAB
EgMhCCYKCgoDBgADEgMiAj0KDAoFBgADmQgSAyICPQoLCgMGAAMSBCMCJDcKDQoFBgADmggS
BCMCJDcKqgIKBAYAAgASBCsCMwMamwIgQ3JlYXRlIGEgaG9zdCBwcm9qZWN0IHJlZ2lzdHJh
dGlvbi4KIEEgR29vZ2xlIGNsb3VkIHByb2plY3QgY2FuIGJlIHJlZ2lzdGVyZWQgYXMgYSBo
b3N0IHByb2plY3QgaWYgaXQgaXMgbm90CiBhdHRhY2hlZCBhcyBhIHJ1bnRpbWUgcHJvamVj
dCB0byBhbm90aGVyIGhvc3QgcHJvamVjdC4KIEEgcHJvamVjdCBjYW4gYmUgcmVnaXN0ZXJl
ZCBhcyBhIGhvc3QgcHJvamVjdCBvbmx5IG9uY2UuIFN1YnNlcXVlbnQKIHJlZ2lzdGVyIGNh
bGxzIGZvciB0aGUgc2FtZSBwcm9qZWN0IHdpbGwgZmFpbC4KCgwKBQYAAgABEgMrBiMKDAoF
BgACAAISAyskSAoMCgUGAAIAAxIDLA8mCg0KBQYAAgAEEgQtBDAGChEKCQYAAgAEsMq8IhIE
LQQwBgoNCgUGAAIABBIEMQQySAoQCggGAAIABJsIABIEMQQySAowCgQGAAIBEgQ2AjwDGiIg
R2V0IGEgaG9zdCBwcm9qZWN0IHJlZ2lzdHJhdGlvbi4KCgwKBQYAAgEBEgM2BiAKDAoFBgAC
AQISAzYhQgoMCgUGAAIBAxIDNw8mCg0KBQYAAgEEEgQ4BDoGChEKCQYAAgEEsMq8IhIEOAQ6
BgoMCgUGAAIBBBIDOwQyCg8KCAYAAgEEmwgAEgM7BDIKMQoEBgACAhIEPwJFAxojIExpc3Rz
IGhvc3QgcHJvamVjdCByZWdpc3RyYXRpb25zLgoKDAoFBgACAgESAz8GIgoMCgUGAAICAhID
PyNGCgwKBQYAAgIDEgNADzMKDQoFBgACAgQSBEEEQwYKEQoJBgACAgSwyrwiEgRBBEMGCgwK
BQYAAgIEEgNEBDQKDwoIBgACAgSbCAASA0QENAqbAQoCBAASBEsAXwEajgEgVGhlCiBbQ3Jl
YXRlSG9zdFByb2plY3RSZWdpc3RyYXRpb25dW2dvb2dsZS5jbG91ZC5hcGlodWIudjEuSG9z
dFByb2plY3RSZWdpc3RyYXRpb25TZXJ2aWNlLkNyZWF0ZUhvc3RQcm9qZWN0UmVnaXN0cmF0
aW9uXQogbWV0aG9kJ3MgcmVxdWVzdC4KCgoKAwQAARIDSwgsCnYKBAQAAgASBE4CUwQaaCBS
ZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBmb3IgdGhlIGhvc3QgcHJvamVjdC4KIEZv
cm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCgwKBQQA
AgAFEgNOAggKDAoFBAACAAESA04JDwoMCgUEAAIAAxIDThITCg0KBQQAAgAIEgROFFMDCg8K
CAQAAgAInAgAEgNPBCoKDwoHBAACAAifCBIEUARSBQqYAgoEBAACARIEWQJaLxqJAiBSZXF1
aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIEhvc3QgUHJvamVjdCBSZWdpc3RyYXRpb24s
IHdoaWNoIHdpbGwKIGJlY29tZSB0aGUgZmluYWwgY29tcG9uZW50IG9mIHRoZSBob3N0IHBy
b2plY3QgcmVnaXN0cmF0aW9uJ3MgcmVzb3VyY2UKIG5hbWUuIFRoZSBJRCBtdXN0IGJlIHRo
ZSBzYW1lIGFzIHRoZSBHb29nbGUgY2xvdWQgcHJvamVjdCBzcGVjaWZpZWQgaW4gdGhlCiBo
b3N0X3Byb2plY3RfcmVnaXN0cmF0aW9uLmdjcF9wcm9qZWN0IGZpZWxkLgoKDAoFBAACAQUS
A1kCCAoMCgUEAAIBARIDWQklCgwKBQQAAgEDEgNZKCkKDAoFBAACAQgSA1oGLgoPCggEAAIB
CJwIABIDWgctCkQKBAQAAgISBF0CXi8aNiBSZXF1aXJlZC4gVGhlIGhvc3QgcHJvamVjdCBy
ZWdpc3RyYXRpb24gdG8gcmVnaXN0ZXIuCgoMCgUEAAICBhIDXQIZCgwKBQQAAgIBEgNdGjMK
DAoFBAACAgMSA102NwoMCgUEAAICCBIDXgYuCg8KCAQAAgIInAgAEgNeBy0KlQEKAgQBEgRk
AG0BGogBIFRoZQogW0dldEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uXVtnb29nbGUuY2xvdWQu
YXBpaHViLnYxLkhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uU2VydmljZS5HZXRIb3N0UHJvamVj
dFJlZ2lzdHJhdGlvbl0KIG1ldGhvZCdzIHJlcXVlc3QuCgoKCgMEAQESA2QIKQqkAQoEBAEC
ABIEZwJsBBqVASBSZXF1aXJlZC4gSG9zdCBwcm9qZWN0IHJlZ2lzdHJhdGlvbiByZXNvdXJj
ZSBuYW1lLgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2hvc3RQ
cm9qZWN0UmVnaXN0cmF0aW9ucy97aG9zdF9wcm9qZWN0X3JlZ2lzdHJhdGlvbl9pZH0KCgwK
BQQBAgAFEgNnAggKDAoFBAECAAESA2cJDQoMCgUEAQIAAxIDZxARCg0KBQQBAgAIEgRnEmwD
Cg8KCAQBAgAInAgAEgNoBCoKDwoHBAECAAifCBIEaQRrBQqaAQoCBAISBXIAnwEBGowBIFRo
ZQogW0xpc3RIb3N0UHJvamVjdFJlZ2lzdHJhdGlvbnNdW2dvb2dsZS5jbG91ZC5hcGlodWIu
djEuSG9zdFByb2plY3RSZWdpc3RyYXRpb25TZXJ2aWNlLkxpc3RIb3N0UHJvamVjdFJlZ2lz
dHJhdGlvbnNdCiBtZXRob2QncyByZXF1ZXN0LgoKCgoDBAIBEgNyCCsKdAoEBAICABIEdQJ6
BBpmIFJlcXVpcmVkLiBUaGUgcGFyZW50LCB3aGljaCBvd25zIHRoaXMgY29sbGVjdGlvbiBv
ZiBob3N0IHByb2plY3RzLgogRm9ybWF0OiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKmAKCgwK
BQQCAgAFEgN1AggKDAoFBAICAAESA3UJDwoMCgUEAgIAAxIDdRITCg0KBQQCAgAIEgR1FHoD
Cg8KCAQCAgAInAgAEgN2BCoKDwoHBAICAAifCBIEdwR5BQqVAgoEBAICARIEgAECPxqGAiBP
cHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGhvc3QgcHJvamVjdCByZWdpc3RyYXRp
b25zIHRvIHJldHVybi4gVGhlCiBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIgdGhhbiB0aGlz
IHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBob3N0CiBwcm9qZWN0IHJlZ2lz
dHJhdGlvbnMgd2lsbCBiZSByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsg
dmFsdWVzCiBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBAICAQUS
BIABAgcKDQoFBAICAQESBIABCBEKDQoFBAICAQMSBIABFBUKDQoFBAICAQgSBIABFj4KEAoI
BAICAQicCAASBIABFz0KsAIKBAQCAgISBIkBAkEaoQIgT3B0aW9uYWwuIEEgcGFnZSB0b2tl
biwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0
aW9uc2AgY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZQogc3Vic2VxdWVudCBw
YWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgKGV4Y2VwdCBw
YWdlX3NpemUpIHByb3ZpZGVkIHRvCiBgTGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uc2Ag
bXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlCiB0b2tlbi4KCg0K
BQQCAgIFEgSJAQIICg0KBQQCAgIBEgSJAQkTCg0KBQQCAgIDEgSJARYXCg0KBQQCAgIIEgSJ
ARhAChAKCAQCAgIInAgAEgSJARk/CsEFCgQEAgIDEgSbAQI9GrIFIE9wdGlvbmFsLiBBbiBl
eHByZXNzaW9uIHRoYXQgZmlsdGVycyB0aGUgbGlzdCBvZiBIb3N0UHJvamVjdFJlZ2lzdHJh
dGlvbnMuCgogQSBmaWx0ZXIgZXhwcmVzc2lvbiBjb25zaXN0cyBvZiBhIGZpZWxkIG5hbWUs
IGEgY29tcGFyaXNvbgogb3BlcmF0b3IsIGFuZCBhIHZhbHVlIGZvciBmaWx0ZXJpbmcuIFRo
ZSB2YWx1ZSBtdXN0IGJlIGEgc3RyaW5nLiBBbGwKIHN0YW5kYXJkIG9wZXJhdG9ycyBhcyBk
b2N1bWVudGVkIGF0IGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTYwIGFyZQogc3VwcG9ydGVk
LgoKIFRoZSBmb2xsb3dpbmcgZmllbGRzIGluIHRoZSBgSG9zdFByb2plY3RSZWdpc3RyYXRp
b25gIGFyZSBlbGlnaWJsZSBmb3IKIGZpbHRlcmluZzoKCiAgICogYG5hbWVgIC0gVGhlIG5h
bWUgb2YgdGhlIEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uLgogICAqIGBjcmVhdGVfdGltZWAg
LSBUaGUgdGltZSBhdCB3aGljaCB0aGUgSG9zdFByb2plY3RSZWdpc3RyYXRpb24gd2FzCiAg
IGNyZWF0ZWQuIFRoZSB2YWx1ZSBzaG91bGQgYmUgaW4gdGhlCiAgIChSRkMzMzM5KVtodHRw
czovL3Rvb2xzLmlldGYub3JnL2h0bWwvcmZjMzMzOV0gZm9ybWF0LgogICAqIGBnY3BfcHJv
amVjdGAgLSBUaGUgR29vZ2xlIGNsb3VkIHByb2plY3QgYXNzb2NpYXRlZCB3aXRoIHRoZQog
ICBIb3N0UHJvamVjdFJlZ2lzdHJhdGlvbi4KCg0KBQQCAgMFEgSbAQIICg0KBQQCAgMBEgSb
AQkPCg0KBQQCAgMDEgSbARITCg0KBQQCAgMIEgSbARQ8ChAKCAQCAgMInAgAEgSbARU7CjwK
BAQCAgQSBJ4BAj8aLiBPcHRpb25hbC4gSGludCBmb3IgaG93IHRvIG9yZGVyIHRoZSByZXN1
bHRzLgoKDQoFBAICBAUSBJ4BAggKDQoFBAICBAESBJ4BCREKDQoFBAICBAMSBJ4BFBUKDQoF
BAICBAgSBJ4BFj4KEAoIBAICBAicCAASBJ4BFz0KnAEKAgQDEgakAQCrAQEajQEgVGhlCiBb
TGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0aW9uc11bZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5I
b3N0UHJvamVjdFJlZ2lzdHJhdGlvblNlcnZpY2UuTGlzdEhvc3RQcm9qZWN0UmVnaXN0cmF0
aW9uc10KIG1ldGhvZCdzIHJlc3BvbnNlLgoKCwoDBAMBEgSkAQgsCjcKBAQDAgASBKYBAkIa
KSBUaGUgbGlzdCBvZiBob3N0IHByb2plY3QgcmVnaXN0cmF0aW9ucy4KCg0KBQQDAgAEEgSm
AQIKCg0KBQQDAgAGEgSmAQsiCg0KBQQDAgABEgSmASM9Cg0KBQQDAgADEgSmAUBBCpABCgQE
AwIBEgSqAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2Vu
YCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVk
LCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQDAgEFEgSqAQIICg0KBQQD
AgEBEgSqAQkYCg0KBQQDAgEDEgSqARscCuwCCgIEBBIGsgEAzgEBGt0CIEhvc3QgcHJvamVj
dCByZWdpc3RyYXRpb24gcmVmZXJzIHRvIHRoZSByZWdpc3RyYXRpb24gb2YgYSBHb29nbGUg
Y2xvdWQKIHByb2plY3Qgd2l0aCBBcGkgSHViIGFzIGEgaG9zdCBwcm9qZWN0LiBUaGlzIGlz
IHRoZSBwcm9qZWN0IHdoZXJlIEFwaSBIdWIgaXMKIHByb3Zpc2lvbmVkLiBJdCBhY3RzIGFz
IHRoZSBjb25zdW1lciBwcm9qZWN0IGZvciB0aGUgQXBpIEh1YiBpbnN0YW5jZQogcHJvdmlz
aW9uZWQuIE11bHRpcGxlIHJ1bnRpbWUgcHJvamVjdHMgY2FuIGJlIGF0dGFjaGVkIHRvIHRo
ZSBob3N0IHByb2plY3QKIGFuZCB0aGVzZSBhdHRhY2htZW50cyBkZWZpbmUgdGhlIHNjb3Bl
IG9mIEFwaSBIdWIuCgoLCgMEBAESBLIBCB8KDQoDBAQHEgazAQK4AQQKDwoFBAQHnQgSBrMB
ArgBBAqxAQoEBAQCABIEvQECPRqiASBJZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0aGUgaG9z
dCBwcm9qZWN0IHJlZ2lzdHJhdGlvbi4KIEZvcm1hdDoKICJwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vaG9zdFByb2plY3RSZWdpc3RyYXRpb25zL3tob3N0X3By
b2plY3RfcmVnaXN0cmF0aW9ufSIuCgoNCgUEBAIABRIEvQECCAoNCgUEBAIAARIEvQEJDQoN
CgUEBAIAAxIEvQEQEQoNCgUEBAIACBIEvQESPAoQCggEBAIACJwIABIEvQETOwruAQoEBAQC
ARIGwwECyQEEGt0BIFJlcXVpcmVkLiBJbW11dGFibGUuIEdvb2dsZSBjbG91ZCBwcm9qZWN0
IG5hbWUgaW4gdGhlIGZvcm1hdDoKICJwcm9qZWN0cy9hYmMiIG9yICJwcm9qZWN0cy8xMjMi
LiBBcyBpbnB1dCwgcHJvamVjdCBuYW1lIHdpdGggZWl0aGVyCiBwcm9qZWN0IGlkIG9yIG51
bWJlciBhcmUgYWNjZXB0ZWQuIEFzIG91dHB1dCwgdGhpcyBmaWVsZCB3aWxsIGNvbnRhaW4K
IHByb2plY3QgbnVtYmVyLgoKDQoFBAQCAQUSBMMBAggKDQoFBAQCAQESBMMBCRQKDQoFBAQC
AQMSBMMBFxgKDwoFBAQCAQgSBsMBGckBAwoQCggEBAIBCJwIABIExAEEKgoQCggEBAIBCJwI
ARIExQEEKwoRCgcEBAIBCJ8IEgbGAQTIAQUKWwoEBAQCAhIGzAECzQEyGksgT3V0cHV0IG9u
bHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBob3N0IHByb2plY3QgcmVnaXN0cmF0aW9uIHdh
cyBjcmVhdGVkLgoKDQoFBAQCAgYSBMwBAhsKDQoFBAQCAgESBMwBHCcKDQoFBAQCAgMSBMwB
KisKDQoFBAQCAggSBM0BBjEKEAoIBAQCAgicCAASBM0BBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest ===
    # Fields for CreateHostProjectRegistrationRequest
    # Field: parent Type: 9 ()
    # Field: host_project_registration_id Type: 9 ()
    # Field: host_project_registration Type: 11 (.google.cloud.apihub.v1.HostProjectRegistration)

# === Message: Google::Cloud::Apihub::V1::HostProjectRegistrationService::GetHostProjectRegistrationRequest ===
    # Fields for GetHostProjectRegistrationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsRequest ===
    # Fields for ListHostProjectRegistrationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsResponse ===
    # Fields for ListHostProjectRegistrationsResponse
    # Field: host_project_registrations Type: 11 (.google.cloud.apihub.v1.HostProjectRegistration)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration ===
    # Fields for HostProjectRegistration
    # Field: name Type: 9 ()
    # Field: gcp_project Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistrationServiceClient ===
package Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistrationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistrationServiceClient

Client stub representing the remote C<HostProjectRegistrationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apihub.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apihub.googleapis.com:443' );

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

sub create_host_project_registration {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.HostProjectRegistrationService',
        method         => 'CreateHostProjectRegistration',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration',
    });
}

sub get_host_project_registration {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::HostProjectRegistrationService::GetHostProjectRegistrationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.HostProjectRegistrationService',
        method         => 'GetHostProjectRegistration',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration',
    });
}

sub list_host_project_registrations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.HostProjectRegistrationService',
        method         => 'ListHostProjectRegistrations',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::HostProjectRegistrationService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/host_project_registration_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::HostProjectRegistrationService;

    my $msg = Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest->new({
        parent => $parent,
        host_project_registration_id => $host_project_registration_id,
        host_project_registration => $host_project_registration,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/host_project_registration_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest

The
[CreateHostProjectRegistration][google.cloud.apihub.v1.HostProjectRegistrationService.CreateHostProjectRegistration]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource for the host project.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->host_project_registration_id() >> / C<< $msg->host_project_registration_id($value) >>

Type: C<String>

Required. The ID to use for the Host Project Registration, which will
become the final component of the host project registration's resource
name. The ID must be the same as the Google cloud project specified in the
host_project_registration.gcp_project field.

=item * C<< $msg->host_project_registration() >> / C<< $msg->host_project_registration($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration>)

Required. The host project registration to register.

=back

=head2 Google::Cloud::Apihub::V1::HostProjectRegistrationService::GetHostProjectRegistrationRequest

The
[GetHostProjectRegistration][google.cloud.apihub.v1.HostProjectRegistrationService.GetHostProjectRegistration]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Host project registration resource name.
projects/{project}/locations/{location}/hostProjectRegistrations/{host_project_registration_id}

=back

=head2 Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsRequest

The
[ListHostProjectRegistrations][google.cloud.apihub.v1.HostProjectRegistrationService.ListHostProjectRegistrations]
method's request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of host projects.
Format: `projects/*/locations/*`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of host project registrations to return. The
service may return fewer than this value. If unspecified, at most 50 host
project registrations will be returned. The maximum value is 1000; values
above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListHostProjectRegistrations` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters (except page_size) provided to
`ListHostProjectRegistrations` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression that filters the list of HostProjectRegistrations.

A filter expression consists of a field name, a comparison
operator, and a value for filtering. The value must be a string. All
standard operators as documented at https://google.aip.dev/160 are
supported.

The following fields in the `HostProjectRegistration` are eligible for
filtering:

  * `name` - The name of the HostProjectRegistration.
  * `create_time` - The time at which the HostProjectRegistration was
  created. The value should be in the
  (RFC3339)[https://tools.ietf.org/html/rfc3339] format.
  * `gcp_project` - The Google cloud project associated with the
  HostProjectRegistration.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Apihub::V1::HostProjectRegistrationService::ListHostProjectRegistrationsResponse

The
[ListHostProjectRegistrations][google.cloud.apihub.v1.HostProjectRegistrationService.ListHostProjectRegistrations]
method's response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host_project_registrations() >> / C<< $msg->host_project_registrations($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration>)

The list of host project registrations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration

Host project registration refers to the registration of a Google cloud
project with Api Hub as a host project. This is the project where Api Hub is
provisioned. It acts as the consumer project for the Api Hub instance
provisioned. Multiple runtime projects can be attached to the host project
and these attachments define the scope of Api Hub.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the host project registration.
Format:
"projects/{project}/locations/{location}/hostProjectRegistrations/{host_project_registration}".

=item * C<< $msg->gcp_project() >> / C<< $msg->gcp_project($value) >>

Type: C<String>

Required. Immutable. Google cloud project name in the format:
"projects/abc" or "projects/123". As input, project name with either
project id or number are accepted. As output, this field will contain
project number.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the host project registration was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::HostProjectRegistrationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
