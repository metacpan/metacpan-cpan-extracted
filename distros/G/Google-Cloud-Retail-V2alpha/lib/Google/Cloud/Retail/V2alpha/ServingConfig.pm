package Google::Cloud::Retail::V2alpha::ServingConfig;

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
    eval { require Google::Cloud::Retail::V2alpha::Common };
    eval { require Google::Cloud::Retail::V2alpha::SearchService };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvc2VydmluZ19jb25maWcucHJvdG8SG2dv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL3JldGFpbC92
MmFscGhhL2NvbW1vbi5wcm90bxowZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmFscGhhL3NlYXJj
aF9zZXJ2aWNlLnByb3RvIp4LCg1TZXJ2aW5nQ29uZmlnEhcKBG5hbWUYASABKAlCA+BBBVIE
bmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSGQoIbW9kZWxf
aWQYAyABKAlSB21vZGVsSWQSMgoVcHJpY2VfcmVyYW5raW5nX2xldmVsGAQgASgJUhNwcmlj
ZVJlcmFua2luZ0xldmVsEioKEWZhY2V0X2NvbnRyb2xfaWRzGAUgAygJUg9mYWNldENvbnRy
b2xJZHMSaQoSZHluYW1pY19mYWNldF9zcGVjGAYgASgLMjsuZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmFscGhhLlNlYXJjaFJlcXVlc3QuRHluYW1pY0ZhY2V0U3BlY1IQZHluYW1pY0ZhY2V0
U3BlYxIqChFib29zdF9jb250cm9sX2lkcxgHIAMoCVIPYm9vc3RDb250cm9sSWRzEiwKEmZp
bHRlcl9jb250cm9sX2lkcxgJIAMoCVIQZmlsdGVyQ29udHJvbElkcxIwChRyZWRpcmVjdF9j
b250cm9sX2lkcxgKIAMoCVIScmVkaXJlY3RDb250cm9sSWRzEj0KG3R3b3dheV9zeW5vbnlt
c19jb250cm9sX2lkcxgSIAMoCVIYdHdvd2F5U3lub255bXNDb250cm9sSWRzEj0KG29uZXdh
eV9zeW5vbnltc19jb250cm9sX2lkcxgMIAMoCVIYb25ld2F5U3lub255bXNDb250cm9sSWRz
Ej4KHGRvX25vdF9hc3NvY2lhdGVfY29udHJvbF9pZHMYDSADKAlSGGRvTm90QXNzb2NpYXRl
Q29udHJvbElkcxI2ChdyZXBsYWNlbWVudF9jb250cm9sX2lkcxgOIAMoCVIVcmVwbGFjZW1l
bnRDb250cm9sSWRzEiwKEmlnbm9yZV9jb250cm9sX2lkcxgPIAMoCVIQaWdub3JlQ29udHJv
bElkcxInCg9kaXZlcnNpdHlfbGV2ZWwYCCABKAlSDmRpdmVyc2l0eUxldmVsEl8KDmRpdmVy
c2l0eV90eXBlGBQgASgOMjguZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdD
b25maWcuRGl2ZXJzaXR5VHlwZVINZGl2ZXJzaXR5VHlwZRI/ChxlbmFibGVfY2F0ZWdvcnlf
ZmlsdGVyX2xldmVsGBAgASgJUhllbmFibGVDYXRlZ29yeUZpbHRlckxldmVsEjAKFGlnbm9y
ZV9yZWNzX2RlbnlsaXN0GBggASgIUhJpZ25vcmVSZWNzRGVueWxpc3QScQoUcGVyc29uYWxp
emF0aW9uX3NwZWMYFSABKAsyPi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU2VhcmNo
UmVxdWVzdC5QZXJzb25hbGl6YXRpb25TcGVjUhNwZXJzb25hbGl6YXRpb25TcGVjElgKDnNv
bHV0aW9uX3R5cGVzGBMgAygOMikuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNvbHV0
aW9uVHlwZUIG4EEC4EEFUg1zb2x1dGlvblR5cGVzImQKDURpdmVyc2l0eVR5cGUSHgoaRElW
RVJTSVRZX1RZUEVfVU5TUEVDSUZJRUQQABIYChRSVUxFX0JBU0VEX0RJVkVSU0lUWRACEhkK
FURBVEFfRFJJVkVOX0RJVkVSU0lUWRADOoUB6kGBAQojcmV0YWlsLmdvb2dsZWFwaXMuY29t
L1NlcnZpbmdDb25maWcSWnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jYXRhbG9ncy97Y2F0YWxvZ30vc2VydmluZ0NvbmZpZ3Mve3NlcnZpbmdfY29uZmlnfULW
AQofY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYUISU2VydmluZ0NvbmZpZ1Byb3Rv
UAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxwaGEvcmV0YWlscGI7cmV0
YWlscGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQWxwaGHKAhtHb29nbGVc
Q2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYWxwaGFK
zVgKBxIFDgCcAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACQKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADIKCQoCAwMSAxUAOgoICgEIEgMX
ADgKCQoCCCUSAxcAOAoICgEIEgMYAE4KCQoCCAsSAxgATgoICgEIEgMZACIKCQoCCAoSAxkA
IgoICgEIEgMaADMKCQoCCAgSAxoAMwoICgEIEgMbADgKCQoCCAESAxsAOAoICgEIEgMcACQK
CQoCCCQSAxwAJAoICgEIEgMdADgKCQoCCCkSAx0AOAoICgEIEgMeADcKCQoCCC0SAx4ANwqG
AQoCBAASBSIAnAIBGnkgQ29uZmlndXJlcyBtZXRhZGF0YSB0aGF0IGlzIHVzZWQgdG8gZ2Vu
ZXJhdGUgc2VydmluZyB0aW1lIHJlc3VsdHMgKGUuZy4KIHNlYXJjaCByZXN1bHRzIG9yIHJl
Y29tbWVuZGF0aW9uIHByZWRpY3Rpb25zKS4KCgoKAwQAARIDIggVCgsKAwQABxIEIwImBAoN
CgUEAAedCBIEIwImBAo8CgQEAAQAEgQpAjIDGi4gV2hhdCB0eXBlIG9mIGRpdmVyc2l0eSAt
IGRhdGEgb3IgcnVsZSBiYXNlZC4KCgwKBQQABAABEgMpBxQKHwoGBAAEAAIAEgMrBCMaECBE
ZWZhdWx0IHZhbHVlLgoKDgoHBAAEAAIAARIDKwQeCg4KBwQABAACAAISAyshIgomCgYEAAQA
AgESAy4EHRoXIFJ1bGUgYmFzZWQgZGl2ZXJzaXR5LgoKDgoHBAAEAAIBARIDLgQYCg4KBwQA
BAACAQISAy4bHAonCgYEAAQAAgISAzEEHhoYIERhdGEgZHJpdmVuIGRpdmVyc2l0eS4KCg4K
BwQABAACAgESAzEEGQoOCgcEAAQAAgICEgMxHB0KaAoEBAACABIDNgI8GlsgSW1tdXRhYmxl
LiBGdWxseSBxdWFsaWZpZWQgbmFtZQogYHByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9j
YXRhbG9ncy8qL3NlcnZpbmdDb25maWcvKmAKCgwKBQQAAgAFEgM2AggKDAoFBAACAAESAzYJ
DQoMCgUEAAIAAxIDNhARCgwKBQQAAgAIEgM2EjsKDwoIBAACAAicCAASAzYTOgrjAQoEBAAC
ARIDPQJDGtUBIFJlcXVpcmVkLiBUaGUgaHVtYW4gcmVhZGFibGUgc2VydmluZyBjb25maWcg
ZGlzcGxheSBuYW1lLiBVc2VkIGluIFJldGFpbAogVUkuCgogVGhpcyBmaWVsZCBtdXN0IGJl
IGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMjgKIGNo
YXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1
cm5lZC4KCgwKBQQAAgEFEgM9AggKDAoFBAACAQESAz0JFQoMCgUEAAIBAxIDPRgZCgwKBQQA
AgEIEgM9GkIKDwoIBAACAQicCAASAz0bQQqlBAoEBAACAhIDSgIWGpcEIFRoZSBpZCBvZiB0
aGUgbW9kZWwgaW4gdGhlIHNhbWUKIFtDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuQ2F0YWxvZ10gdG8gdXNlIGF0IHNlcnZpbmcgdGltZS4KIEN1cnJlbnRseSBvbmx5
IFJlY29tbWVuZGF0aW9uTW9kZWxzIGFyZSBzdXBwb3J0ZWQ6CiBodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vcmV0YWlsL3JlY29tbWVuZGF0aW9ucy1haS9kb2NzL2NyZWF0ZS1tb2RlbHMK
IENhbiBiZSBjaGFuZ2VkIGJ1dCBvbmx5IHRvIGEgY29tcGF0aWJsZSBtb2RlbCAoZS5nLgog
b3RoZXJzLXlvdS1tYXktbGlrZSBDVFIgdG8gb3RoZXJzLXlvdS1tYXktbGlrZSBDVlIpLgoK
IFJlcXVpcmVkIHdoZW4KIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmFscGhhLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZ
UEVfUkVDT01NRU5EQVRJT05dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Tb2x1dGlv
blR5cGUuU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPTl0uCgoMCgUEAAICBRIDSgIICgwK
BQQAAgIBEgNKCREKDAoFBAACAgMSA0oUFQrNBQoEBAACAxIDXwIjGr8FIEhvdyBtdWNoIHBy
aWNlIHJhbmtpbmcgd2Ugd2FudCBpbiBzZXJ2aW5nIHJlc3VsdHMuCiBQcmljZSByZXJhbmtp
bmcgY2F1c2VzIHByb2R1Y3QgaXRlbXMgd2l0aCBhIHNpbWlsYXIKIHJlY29tbWVuZGF0aW9u
IHByb2JhYmlsaXR5IHRvIGJlIG9yZGVyZWQgYnkgcHJpY2UsIHdpdGggdGhlCiBoaWdoZXN0
LXByaWNlZCBpdGVtcyBmaXJzdC4gVGhpcyBzZXR0aW5nIGNvdWxkIHJlc3VsdCBpbiBhIGRl
Y3JlYXNlIGluCiBjbGljay10aHJvdWdoIGFuZCBjb252ZXJzaW9uIHJhdGVzLgogIEFsbG93
ZWQgdmFsdWVzIGFyZToKCiAqIGBuby1wcmljZS1yZXJhbmtpbmdgCiAqIGBsb3ctcHJpY2Ut
cmVyYW5raW5nYAogKiBgbWVkaXVtLXByaWNlLXJlcmFua2luZ2AKICogYGhpZ2gtcHJpY2Ut
cmVyYW5raW5nYAoKIElmIG5vdCBzcGVjaWZpZWQsIHdlIGNob29zZSBkZWZhdWx0IGJhc2Vk
IG9uIG1vZGVsIHR5cGUuIERlZmF1bHQgdmFsdWU6CiBgbm8tcHJpY2UtcmVyYW5raW5nYC4K
CiBDYW4gb25seSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmFscGhhLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVU
SU9OX1RZUEVfUkVDT01NRU5EQVRJT05dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5T
b2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPTl0uCgoMCgUEAAIDBRID
XwIICgwKBQQAAgMBEgNfCR4KDAoFBAACAwMSA18hIgqJBQoEBAACBBIDbQIoGvsEIEZhY2V0
IHNwZWNpZmljYXRpb25zIGZvciBmYWNldGVkIHNlYXJjaC4gSWYgZW1wdHksIG5vIGZhY2V0
cyBhcmUgcmV0dXJuZWQuCiBUaGUgaWRzIHJlZmVyIHRvIHRoZSBpZHMgb2YgW0NvbnRyb2xd
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Db250cm9sXQogcmVzb3VyY2VzIHdpdGgg
b25seSB0aGUgRmFjZXQgY29udHJvbCBzZXQuIFRoZXNlIGNvbnRyb2xzIGFyZSBhc3N1bWVk
IHRvIGJlCiBpbiB0aGUgc2FtZSBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkNhdGFsb2ddIGFzIHRoZQogW1NlcnZpbmdDb25maWddW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnXS4KIEEgbWF4aW11bSBvZiAxMDAgdmFsdWVzIGFy
ZSBhbGxvd2VkLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IKIGlzIHJl
dHVybmVkLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlz
CiBbU09MVVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5T
b2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKDAoFBAACBAQSA20CCgoMCgUE
AAIEBRIDbQsRCgwKBQQAAgQBEgNtEiMKDAoFBAACBAMSA20mJwq/AgoEBAACBRIDdgI4GrEC
IFRoZSBzcGVjaWZpY2F0aW9uIGZvciBkeW5hbWljYWxseSBnZW5lcmF0ZWQgZmFjZXRzLiBO
b3RpY2UgdGhhdCBvbmx5CiB0ZXh0dWFsIGZhY2V0cyBjYW4gYmUgZHluYW1pY2FsbHkgZ2Vu
ZXJhdGVkLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlz
CiBbU09MVVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5T
b2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKDAoFBAACBQYSA3YCIAoMCgUE
AAIFARIDdiEzCgwKBQQAAgUDEgN2NjcK2AYKBAQAAgYSBIkBAigayQYgQ29uZGl0aW9uIGJv
b3N0IHNwZWNpZmljYXRpb25zLiBJZiBhIHByb2R1Y3QgbWF0Y2hlcyBtdWx0aXBsZSBjb25k
aXRpb25zCiBpbiB0aGUgc3BlY2lmaWNhdGlvbnMsIGJvb3N0IHNjb3JlcyBmcm9tIHRoZXNl
IHNwZWNpZmljYXRpb25zIGFyZSBhbGwKIGFwcGxpZWQgYW5kIGNvbWJpbmVkIGluIGEgbm9u
LWxpbmVhciB3YXkuIE1heGltdW0gbnVtYmVyIG9mCiBzcGVjaWZpY2F0aW9ucyBpcyAxMDAu
CgogTm90aWNlIHRoYXQgaWYgYm90aAogW1NlcnZpbmdDb25maWcuYm9vc3RfY29udHJvbF9p
ZHNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnLmJvb3N0X2Nv
bnRyb2xfaWRzXQogYW5kCiBbU2VhcmNoUmVxdWVzdC5ib29zdF9zcGVjXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuU2VhcmNoUmVxdWVzdC5ib29zdF9zcGVjXQogYXJlIHNldCwg
dGhlIGJvb3N0IGNvbmRpdGlvbnMgZnJvbSBib3RoIHBsYWNlcyBhcmUgZXZhbHVhdGVkLiBJ
ZiBhIHNlYXJjaAogcmVxdWVzdCBtYXRjaGVzIG11bHRpcGxlIGJvb3N0IGNvbmRpdGlvbnMs
IHRoZSBmaW5hbCBib29zdCBzY29yZSBpcyBlcXVhbAogdG8gdGhlIHN1bSBvZiB0aGUgYm9v
c3Qgc2NvcmVzIGZyb20gYWxsIG1hdGNoZWQgYm9vc3QgY29uZGl0aW9ucy4KCiBDYW4gb25s
eSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVf
U0VBUkNIXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlLlNPTFVU
SU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAgYEEgSJAQIKCg0KBQQAAgYFEgSJAQsRCg0KBQQA
AgYBEgSJARIjCg0KBQQAAgYDEgSJASYnCq8DCgQEAAIHEgSUAQIpGqADIENvbmRpdGlvbiBm
aWx0ZXIgc3BlY2lmaWNhdGlvbnMuIElmIGEgcHJvZHVjdCBtYXRjaGVzIG11bHRpcGxlIGNv
bmRpdGlvbnMKIGluIHRoZSBzcGVjaWZpY2F0aW9ucywgZmlsdGVycyBmcm9tIHRoZXNlIHNw
ZWNpZmljYXRpb25zIGFyZSBhbGwKIGFwcGxpZWQgYW5kIGNvbWJpbmVkIHZpYSB0aGUgQU5E
IG9wZXJhdG9yLiBNYXhpbXVtIG51bWJlciBvZgogc3BlY2lmaWNhdGlvbnMgaXMgMTAwLgoK
IENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlzCiBbU09MVVRJ
T05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Tb2x1dGlvblR5
cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKDQoFBAACBwQSBJQBAgoKDQoFBAACBwUSBJQB
CxEKDQoFBAACBwESBJQBEiQKDQoFBAACBwMSBJQBJygK6QIKBAQAAggSBJ4BAiwa2gIgQ29u
ZGl0aW9uIHJlZGlyZWN0IHNwZWNpZmljYXRpb25zLiBPbmx5IHRoZSBmaXJzdCB0cmlnZ2Vy
ZWQgcmVkaXJlY3QgYWN0aW9uCiBpcyBhcHBsaWVkLCBldmVuIGlmIG11bHRpcGxlIGFwcGx5
LiBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBpcwogMTAwMC4KCiBDYW4gb25s
eSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVf
U0VBUkNIXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlLlNPTFVU
SU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAggEEgSeAQIKCg0KBQQAAggFEgSeAQsRCg0KBQQA
AggBEgSeARImCg0KBQQAAggDEgSeASkrCqkDCgQEAAIJEgSpAQIzGpoDIENvbmRpdGlvbiBz
eW5vbnltcyBzcGVjaWZpY2F0aW9ucy4gSWYgbXVsdGlwbGUgc3lvbnltcyBjb25kaXRpb25z
IG1hdGNoLAogYWxsIG1hdGNoaW5nIHN5bm9ueW1zIGNvbnRyb2wgaW4gdGhlIGxpc3Qgd2ls
bCBleGVjdXRlLiBPcmRlciBvZiBjb250cm9scwogaW4gdGhlIGxpc3Qgd2lsbCBub3QgbWF0
dGVyLiBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBpcwogMTAwLgoKIENhbiBv
bmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlzCiBbU09MVVRJT05fVFlQ
RV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Tb2x1dGlvblR5cGUuU09M
VVRJT05fVFlQRV9TRUFSQ0hdLgoKDQoFBAACCQQSBKkBAgoKDQoFBAACCQUSBKkBCxEKDQoF
BAACCQESBKkBEi0KDQoFBAACCQMSBKkBMDIKwAMKBAQAAgoSBLQBAjMasQMgQ29uZGl0aW9u
IG9uZXdheSBzeW5vbnltcyBzcGVjaWZpY2F0aW9ucy4gSWYgbXVsdGlwbGUgb25ld2F5IHN5
bm9ueW1zCiBjb25kaXRpb25zIG1hdGNoLCBhbGwgbWF0Y2hpbmcgb25ld2F5IHN5bm9ueW1z
IGNvbnRyb2xzIGluIHRoZSBsaXN0IHdpbGwKIGV4ZWN1dGUuIE9yZGVyIG9mIGNvbnRyb2xz
IGluIHRoZSBsaXN0IHdpbGwgbm90IG1hdHRlci4gTWF4aW11bSBudW1iZXIgb2YKIHNwZWNp
ZmljYXRpb25zIGlzIDEwMC4KCiBDYW4gb25seSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBl
c11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdDb25maWcuc29sdXRpb25f
dHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAgoE
EgS0AQIKCg0KBQQAAgoFEgS0AQsRCg0KBQQAAgoBEgS0ARItCg0KBQQAAgoDEgS0ATAyCrAD
CgQEAAILEgTAAQI0GqEDIENvbmRpdGlvbiBkbyBub3QgYXNzb2NpYXRlIHNwZWNpZmljYXRp
b25zLiBJZiBtdWx0aXBsZSBkbyBub3QgYXNzb2NpYXRlCiBjb25kaXRpb25zIG1hdGNoLCBh
bGwgbWF0Y2hpbmcgZG8gbm90IGFzc29jaWF0ZSBjb250cm9scyBpbiB0aGUgbGlzdCB3aWxs
CiBleGVjdXRlLgogLSBPcmRlciBkb2VzIG5vdCBtYXR0ZXIuCiAtIE1heGltdW0gbnVtYmVy
IG9mIHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCiBDYW4gb25seSBiZSBzZXQgaWYKIFtzb2x1
dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdDb25maWcu
c29sdXRpb25fdHlwZXNdCiBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4K
Cg0KBQQAAgsEEgTAAQIKCg0KBQQAAgsFEgTAAQsRCg0KBQQAAgsBEgTAARIuCg0KBQQAAgsD
EgTAATEzCoQDCgQEAAIMEgTLAQIvGvUCIENvbmRpdGlvbiByZXBsYWNlbWVudCBzcGVjaWZp
Y2F0aW9ucy4KIC0gQXBwbGllZCBhY2NvcmRpbmcgdG8gdGhlIG9yZGVyIGluIHRoZSBsaXN0
LgogLSBBIHByZXZpb3VzbHkgcmVwbGFjZWQgdGVybSBjYW4gbm90IGJlIHJlLXJlcGxhY2Vk
LgogLSBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBpcyAxMDAuCgogQ2FuIG9u
bHkgYmUgc2V0IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBF
X1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNvbHV0aW9uVHlwZS5TT0xV
VElPTl9UWVBFX1NFQVJDSF0uCgoNCgUEAAIMBBIEywECCgoNCgUEAAIMBRIEywELEQoNCgUE
AAIMARIEywESKQoNCgUEAAIMAxIEywEsLgqSAwoEBAACDRIE1wECKhqDAyBDb25kaXRpb24g
aWdub3JlIHNwZWNpZmljYXRpb25zLiBJZiBtdWx0aXBsZSBpZ25vcmUKIGNvbmRpdGlvbnMg
bWF0Y2gsIGFsbCBtYXRjaGluZyBpZ25vcmUgY29udHJvbHMgaW4gdGhlIGxpc3Qgd2lsbAog
ZXhlY3V0ZS4KIC0gT3JkZXIgZG9lcyBub3QgbWF0dGVyLgogLSBNYXhpbXVtIG51bWJlciBv
ZiBzcGVjaWZpY2F0aW9ucyBpcyAxMDAuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbc29sdXRp
b25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnLnNv
bHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmFscGhhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoN
CgUEAAINBBIE1wECCgoNCgUEAAINBRIE1wELEQoNCgUEAAINARIE1wESJAoNCgUEAAINAxIE
1wEnKQqvBAoEBAACDhIE6QECHRqgBCBIb3cgbXVjaCBkaXZlcnNpdHkgdG8gdXNlIGluIHJl
Y29tbWVuZGF0aW9uIG1vZGVsIHJlc3VsdHMgZS5nLgogYG1lZGl1bS1kaXZlcnNpdHlgIG9y
IGBoaWdoLWRpdmVyc2l0eWAuIEN1cnJlbnRseSBzdXBwb3J0ZWQgdmFsdWVzOgoKICogYG5v
LWRpdmVyc2l0eWAKICogYGxvdy1kaXZlcnNpdHlgCiAqIGBtZWRpdW0tZGl2ZXJzaXR5YAog
KiBgaGlnaC1kaXZlcnNpdHlgCiAqIGBhdXRvLWRpdmVyc2l0eWAKCiBJZiBub3Qgc3BlY2lm
aWVkLCB3ZSBjaG9vc2UgZGVmYXVsdCBiYXNlZCBvbiByZWNvbW1lbmRhdGlvbiBtb2RlbAog
dHlwZS4gRGVmYXVsdCB2YWx1ZTogYG5vLWRpdmVyc2l0eWAuCgogQ2FuIG9ubHkgYmUgc2V0
IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2
aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXQogaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVO
REFUSU9OXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlLlNPTFVU
SU9OX1RZUEVfUkVDT01NRU5EQVRJT05dLgoKDQoFBAACDgUSBOkBAggKDQoFBAACDgESBOkB
CRgKDQoFBAACDgMSBOkBGxwK3QEKBAQAAg8SBO4BAiQazgEgV2hhdCBraW5kIG9mIGRpdmVy
c2l0eSB0byB1c2UgLSBkYXRhIGRyaXZlbiBvciBydWxlIGJhc2VkLiBJZiB1bnNldCwgdGhl
CiBzZXJ2ZXIgYmVoYXZpb3IgZGVmYXVsdHMgdG8KIFtSVUxFX0JBU0VEX0RJVkVSU0lUWV1b
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdDb25maWcuRGl2ZXJzaXR5VHlw
ZS5SVUxFX0JBU0VEX0RJVkVSU0lUWV0uCgoNCgUEAAIPBhIE7gECDwoNCgUEAAIPARIE7gEQ
HgoNCgUEAAIPAxIE7gEhIwr5BQoEBAACEBIE/wECKxrqBSBXaGV0aGVyIHRvIGFkZCBhZGRp
dGlvbmFsIGNhdGVnb3J5IGZpbHRlcnMgb24gdGhlIGBzaW1pbGFyLWl0ZW1zYCBtb2RlbC4K
IElmIG5vdCBzcGVjaWZpZWQsIHdlIGVuYWJsZSBpdCBieSBkZWZhdWx0LgogIEFsbG93ZWQg
dmFsdWVzIGFyZToKCiAqIGBuby1jYXRlZ29yeS1tYXRjaGA6IE5vIGFkZGl0aW9uYWwgZmls
dGVyaW5nIG9mIG9yaWdpbmFsIHJlc3VsdHMgZnJvbQogICB0aGUgbW9kZWwgYW5kIHRoZSBj
dXN0b21lcidzIGZpbHRlcnMuCiAqIGByZWxheGVkLWNhdGVnb3J5LW1hdGNoYDogT25seSBr
ZWVwIHJlc3VsdHMgd2l0aCBjYXRlZ29yaWVzIHRoYXQgbWF0Y2gKICAgYXQgbGVhc3Qgb25l
IGl0ZW0gY2F0ZWdvcmllcyBpbiB0aGUgUHJlZGljdFJlcXVlc3RzJ3MgY29udGV4dCBpdGVt
LgogICAqIElmIGN1c3RvbWVyIGFsc28gc2VuZHMgZmlsdGVycyBpbiB0aGUgUHJlZGljdFJl
cXVlc3QsIHRoZW4gdGhlIHJlc3VsdHMKICAgd2lsbCBzYXRpc2Z5IGJvdGggY29uZGl0aW9u
cyAodXNlciBnaXZlbiBhbmQgY2F0ZWdvcnkgbWF0Y2gpLgoKIENhbiBvbmx5IGJlIHNldCBp
ZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU2Vydmlu
Z0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlzCiBbU09MVVRJT05fVFlQRV9SRUNPTU1FTkRB
VElPTl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNvbHV0aW9uVHlwZS5TT0xVVElP
Tl9UWVBFX1JFQ09NTUVOREFUSU9OXS4KCg0KBQQAAhAFEgT/AQIICg0KBQQAAhABEgT/AQkl
Cg0KBQQAAhADEgT/ASgqCokBCgQEAAIREgSDAgIhGnsgV2hlbiB0aGUgZmxhZyBpcyBlbmFi
bGVkLCB0aGUgcHJvZHVjdHMgaW4gdGhlIGRlbnlsaXN0IHdpbGwgbm90IGJlIGZpbHRlcmVk
CiBvdXQgaW4gdGhlIHJlY29tbWVuZGF0aW9uIGZpbHRlcmluZyByZXN1bHRzLgoKDQoFBAAC
EQUSBIMCAgYKDQoFBAACEQESBIMCBxsKDQoFBAACEQMSBIMCHiAKxgUKBAQAAhISBJQCAj4a
twUgVGhlIHNwZWNpZmljYXRpb24gZm9yIHBlcnNvbmFsaXphdGlvbiBzcGVjLgoKIENhbiBv
bmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10KIGlzCiBbU09MVVRJT05fVFlQ
RV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Tb2x1dGlvblR5cGUuU09M
VVRJT05fVFlQRV9TRUFSQ0hdLgoKIE5vdGljZSB0aGF0IGlmIGJvdGgKIFtTZXJ2aW5nQ29u
ZmlnLnBlcnNvbmFsaXphdGlvbl9zcGVjXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEu
U2VydmluZ0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY10KIGFuZAogW1NlYXJjaFJlcXVl
c3QucGVyc29uYWxpemF0aW9uX3NwZWNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5T
ZWFyY2hSZXF1ZXN0LnBlcnNvbmFsaXphdGlvbl9zcGVjXQogYXJlIHNldC4KIFtTZWFyY2hS
ZXF1ZXN0LnBlcnNvbmFsaXphdGlvbl9zcGVjXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxw
aGEuU2VhcmNoUmVxdWVzdC5wZXJzb25hbGl6YXRpb25fc3BlY10KIHdpbGwgb3ZlcnJpZGUK
IFtTZXJ2aW5nQ29uZmlnLnBlcnNvbmFsaXphdGlvbl9zcGVjXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuU2VydmluZ0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY10uCgoNCgUE
AAISBhIElAICIwoNCgUEAAISARIElAIkOAoNCgUEAAISAxIElAI7PQqrAQoEBAACExIGmAIC
mwIEGpoBIFJlcXVpcmVkLiBJbW11dGFibGUuIFNwZWNpZmllcyB0aGUgc29sdXRpb24gdHlw
ZXMgdGhhdCBhIHNlcnZpbmcgY29uZmlnIGNhbgogYmUgYXNzb2NpYXRlZCB3aXRoLiBDdXJy
ZW50bHkgd2Ugc3VwcG9ydCBzZXR0aW5nIG9ubHkgb25lIHR5cGUgb2Ygc29sdXRpb24uCgoN
CgUEAAITBBIEmAICCgoNCgUEAAITBhIEmAILFwoNCgUEAAITARIEmAIYJgoNCgUEAAITAxIE
mAIpKwoPCgUEAAITCBIGmAIsmwIDChAKCAQAAhMInAgAEgSZAgQqChAKCAQAAhMInAgBEgSa
AgQrYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig ===
    # Fields for ServingConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model_id Type: 9 ()
    # Field: price_reranking_level Type: 9 ()
    # Field: facet_control_ids Type: 9 ()
    # Field: dynamic_facet_spec Type: 11 (.google.cloud.retail.v2alpha.SearchRequest.DynamicFacetSpec)
    # Field: boost_control_ids Type: 9 ()
    # Field: filter_control_ids Type: 9 ()
    # Field: redirect_control_ids Type: 9 ()
    # Field: twoway_synonyms_control_ids Type: 9 ()
    # Field: oneway_synonyms_control_ids Type: 9 ()
    # Field: do_not_associate_control_ids Type: 9 ()
    # Field: replacement_control_ids Type: 9 ()
    # Field: ignore_control_ids Type: 9 ()
    # Field: diversity_level Type: 9 ()
    # Field: diversity_type Type: 14 (.google.cloud.retail.v2alpha.ServingConfig.DiversityType)
    # Field: enable_category_filter_level Type: 9 ()
    # Field: ignore_recs_denylist Type: 8 ()
    # Field: personalization_spec Type: 11 (.google.cloud.retail.v2alpha.SearchRequest.PersonalizationSpec)
    # Field: solution_types Type: 14 (.google.cloud.retail.v2alpha.SolutionType)

# Enum: ServingConfig::DiversityType
our $ServingConfig_DIVERSITY_TYPE_UNSPECIFIED = 0;
our $ServingConfig_RULE_BASED_DIVERSITY = 2;
our $ServingConfig_DATA_DRIVEN_DIVERSITY = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::ServingConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/serving_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::ServingConfig;

    my $msg = Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig->new({
        name => $name,
        display_name => $display_name,
        model_id => $model_id,
        price_reranking_level => $price_reranking_level,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/serving_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig

Configures metadata that is used to generate serving time results (e.g.
search results or recommendation predictions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/*/locations/global/catalogs/*/servingConfig/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human readable serving config display name. Used in Retail
UI.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

The id of the model in the same
[Catalog][google.cloud.retail.v2alpha.Catalog] to use at serving time.
Currently only RecommendationModels are supported:
https://cloud.google.com/retail/recommendations-ai/docs/create-models
Can be changed but only to a compatible model (e.g.
others-you-may-like CTR to others-you-may-like CVR).

Required when
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->price_reranking_level() >> / C<< $msg->price_reranking_level($value) >>

Type: C<String>

How much price ranking we want in serving results.
Price reranking causes product items with a similar
recommendation probability to be ordered by price, with the
highest-priced items first. This setting could result in a decrease in
click-through and conversion rates.
 Allowed values are:

* `no-price-reranking`
* `low-price-reranking`
* `medium-price-reranking`
* `high-price-reranking`

If not specified, we choose default based on model type. Default value:
`no-price-reranking`.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->facet_control_ids() >> / C<< $msg->facet_control_ids($value) >>

Type: C<String>

Facet specifications for faceted search. If empty, no facets are returned.
The ids refer to the ids of [Control][google.cloud.retail.v2alpha.Control]
resources with only the Facet control set. These controls are assumed to be
in the same [Catalog][google.cloud.retail.v2alpha.Catalog] as the
[ServingConfig][google.cloud.retail.v2alpha.ServingConfig].
A maximum of 100 values are allowed. Otherwise, an INVALID_ARGUMENT error
is returned.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->dynamic_facet_spec() >> / C<< $msg->dynamic_facet_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::DynamicFacetSpec>)

The specification for dynamically generated facets. Notice that only
textual facets can be dynamically generated.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->boost_control_ids() >> / C<< $msg->boost_control_ids($value) >>

Type: C<String>

Condition boost specifications. If a product matches multiple conditions
in the specifications, boost scores from these specifications are all
applied and combined in a non-linear way. Maximum number of
specifications is 100.

Notice that if both
[ServingConfig.boost_control_ids][google.cloud.retail.v2alpha.ServingConfig.boost_control_ids]
and
[SearchRequest.boost_spec][google.cloud.retail.v2alpha.SearchRequest.boost_spec]
are set, the boost conditions from both places are evaluated. If a search
request matches multiple boost conditions, the final boost score is equal
to the sum of the boost scores from all matched boost conditions.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->filter_control_ids() >> / C<< $msg->filter_control_ids($value) >>

Type: C<String>

Condition filter specifications. If a product matches multiple conditions
in the specifications, filters from these specifications are all
applied and combined via the AND operator. Maximum number of
specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->redirect_control_ids() >> / C<< $msg->redirect_control_ids($value) >>

Type: C<String>

Condition redirect specifications. Only the first triggered redirect action
is applied, even if multiple apply. Maximum number of specifications is
1000.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->twoway_synonyms_control_ids() >> / C<< $msg->twoway_synonyms_control_ids($value) >>

Type: C<String>

Condition synonyms specifications. If multiple syonyms conditions match,
all matching synonyms control in the list will execute. Order of controls
in the list will not matter. Maximum number of specifications is
100.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->oneway_synonyms_control_ids() >> / C<< $msg->oneway_synonyms_control_ids($value) >>

Type: C<String>

Condition oneway synonyms specifications. If multiple oneway synonyms
conditions match, all matching oneway synonyms controls in the list will
execute. Order of controls in the list will not matter. Maximum number of
specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->do_not_associate_control_ids() >> / C<< $msg->do_not_associate_control_ids($value) >>

Type: C<String>

Condition do not associate specifications. If multiple do not associate
conditions match, all matching do not associate controls in the list will
execute.
- Order does not matter.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->replacement_control_ids() >> / C<< $msg->replacement_control_ids($value) >>

Type: C<String>

Condition replacement specifications.
- Applied according to the order in the list.
- A previously replaced term can not be re-replaced.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->ignore_control_ids() >> / C<< $msg->ignore_control_ids($value) >>

Type: C<String>

Condition ignore specifications. If multiple ignore
conditions match, all matching ignore controls in the list will
execute.
- Order does not matter.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->diversity_level() >> / C<< $msg->diversity_level($value) >>

Type: C<String>

How much diversity to use in recommendation model results e.g.
`medium-diversity` or `high-diversity`. Currently supported values:

* `no-diversity`
* `low-diversity`
* `medium-diversity`
* `high-diversity`
* `auto-diversity`

If not specified, we choose default based on recommendation model
type. Default value: `no-diversity`.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->diversity_type() >> / C<< $msg->diversity_type($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::ServingConfig::DiversityType>)

What kind of diversity to use - data driven or rule based. If unset, the
server behavior defaults to
[RULE_BASED_DIVERSITY][google.cloud.retail.v2alpha.ServingConfig.DiversityType.RULE_BASED_DIVERSITY].

=item * C<< $msg->enable_category_filter_level() >> / C<< $msg->enable_category_filter_level($value) >>

Type: C<String>

Whether to add additional category filters on the `similar-items` model.
If not specified, we enable it by default.
 Allowed values are:

* `no-category-match`: No additional filtering of original results from
  the model and the customer's filters.
* `relaxed-category-match`: Only keep results with categories that match
  at least one item categories in the PredictRequests's context item.
  * If customer also sends filters in the PredictRequest, then the results
  will satisfy both conditions (user given and category match).

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->ignore_recs_denylist() >> / C<< $msg->ignore_recs_denylist($value) >>

Type: C<Bool>

When the flag is enabled, the products in the denylist will not be filtered
out in the recommendation filtering results.

=item * C<< $msg->personalization_spec() >> / C<< $msg->personalization_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::PersonalizationSpec>)

The specification for personalization spec.

Can only be set if
[solution_types][google.cloud.retail.v2alpha.ServingConfig.solution_types]
is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

Notice that if both
[ServingConfig.personalization_spec][google.cloud.retail.v2alpha.ServingConfig.personalization_spec]
and
[SearchRequest.personalization_spec][google.cloud.retail.v2alpha.SearchRequest.personalization_spec]
are set.
[SearchRequest.personalization_spec][google.cloud.retail.v2alpha.SearchRequest.personalization_spec]
will override
[ServingConfig.personalization_spec][google.cloud.retail.v2alpha.ServingConfig.personalization_spec].

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SolutionType>)

Required. Immutable. Specifies the solution types that a serving config can
be associated with. Currently we support setting only one type of solution.

=back

=head3 Enum: ServingConfig::DiversityType

=over 4

=item * C<DIVERSITY_TYPE_UNSPECIFIED> => C<0>

=item * C<RULE_BASED_DIVERSITY> => C<2>

=item * C<DATA_DRIVEN_DIVERSITY> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::ServingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
