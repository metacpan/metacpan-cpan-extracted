package Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService;

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
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UvdjEvY21fZW5yb2xsbWVu
dF9zZXJ2aWNlLnByb3RvEidnb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2Uu
djEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnBy
b3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byK+AQoZVXBkYXRl
Q21FbnJvbGxtZW50UmVxdWVzdBJfCg1jbV9lbnJvbGxtZW50GAEgASgLMjUuZ29vZ2xlLmNs
b3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNlLnYxLkNtRW5yb2xsbWVudEID4EECUgxjbUVu
cm9sbG1lbnQSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRN
YXNrQgPgQQFSCnVwZGF0ZU1hc2sieAolQ2FsY3VsYXRlRWZmZWN0aXZlQ21FbnJvbGxtZW50
UmVxdWVzdBJPCgRuYW1lGAEgASgJQjvgQQL6QTUKM2Nsb3Vkc2VjdXJpdHljb21wbGlhbmNl
Lmdvb2dsZWFwaXMuY29tL0NtRW5yb2xsbWVudFIEbmFtZSL1AgoMQ21FbnJvbGxtZW50EhcK
BG5hbWUYASABKAlCA+BBCFIEbmFtZRIfCghlbnJvbGxlZBgCIAEoCEID4EEBUghlbnJvbGxl
ZBJcCgxhdWRpdF9jb25maWcYAyABKAsyNC5nb29nbGUuY2xvdWQuY2xvdWRzZWN1cml0eWNv
bXBsaWFuY2UudjEuQXVkaXRDb25maWdCA+BBAVILYXVkaXRDb25maWc6zAHqQcgBCjNjbG91
ZHNlY3VyaXR5Y29tcGxpYW5jZS5nb29nbGVhcGlzLmNvbS9DbUVucm9sbG1lbnQSPm9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY21FbnJvbGxt
ZW50EjRwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY21FbnJvbGxt
ZW50Kg1jbUVucm9sbG1lbnRzMgxjbUVucm9sbG1lbnQihAEKJkNhbGN1bGF0ZUVmZmVjdGl2
ZUNtRW5yb2xsbWVudFJlc3BvbnNlEloKDWNtX2Vucm9sbG1lbnQYASABKAsyNS5nb29nbGUu
Y2xvdWQuY2xvdWRzZWN1cml0eWNvbXBsaWFuY2UudjEuQ21FbnJvbGxtZW50UgxjbUVucm9s
bG1lbnQi2AEKC0F1ZGl0Q29uZmlnEnMKDGRlc3RpbmF0aW9ucxgBIAMoCzJKLmdvb2dsZS5j
bG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS52MS5BdWRpdENvbmZpZy5DbUVsaWdpYmxl
RGVzdGluYXRpb25CA+BBAlIMZGVzdGluYXRpb25zGlQKFUNtRWxpZ2libGVEZXN0aW5hdGlv
bhIfCgpnY3NfYnVja2V0GAEgASgJSABSCWdjc0J1Y2tldEIaChhjbV9lbGlnaWJsZV9kZXN0
aW5hdGlvbnMyowcKE0NtRW5yb2xsbWVudFNlcnZpY2USpAMKElVwZGF0ZUNtRW5yb2xsbWVu
dBJCLmdvb2dsZS5jbG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS52MS5VcGRhdGVDbUVu
cm9sbG1lbnRSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmNsb3Vkc2VjdXJpdHljb21wbGlhbmNl
LnYxLkNtRW5yb2xsbWVudCKSAoLT5JMC7wEyQS92MS97Y21fZW5yb2xsbWVudC5uYW1lPW9y
Z2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9jbUVucm9sbG1lbnR9Og1jbV9lbnJvbGxtZW50
WkwyOy92MS97Y21fZW5yb2xsbWVudC5uYW1lPWZvbGRlcnMvKi9sb2NhdGlvbnMvKi9jbUVu
cm9sbG1lbnR9Og1jbV9lbnJvbGxtZW50Wk0yPC92MS97Y21fZW5yb2xsbWVudC5uYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY21FbnJvbGxtZW50fToNY21fZW5yb2xsbWVudNpBGWNt
X2Vucm9sbG1lbnQsdXBkYXRlX21hc2sSiAMKHkNhbGN1bGF0ZUVmZmVjdGl2ZUNtRW5yb2xs
bWVudBJOLmdvb2dsZS5jbG91ZC5jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS52MS5DYWxjdWxh
dGVFZmZlY3RpdmVDbUVucm9sbG1lbnRSZXF1ZXN0Gk8uZ29vZ2xlLmNsb3VkLmNsb3Vkc2Vj
dXJpdHljb21wbGlhbmNlLnYxLkNhbGN1bGF0ZUVmZmVjdGl2ZUNtRW5yb2xsbWVudFJlc3Bv
bnNlIsQBgtPkkwK2ARI9L3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9j
bUVucm9sbG1lbnR9OmNhbGN1bGF0ZVo5EjcvdjEve25hbWU9Zm9sZGVycy8qL2xvY2F0aW9u
cy8qL2NtRW5yb2xsbWVudH06Y2FsY3VsYXRlWjoSOC92MS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2NtRW5yb2xsbWVudH06Y2FsY3VsYXRl2kEEbmFtZRpaykEmY2xvdWRzZWN1
cml0eWNvbXBsaWFuY2UuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQrECCitjb20uZ29vZ2xlLmNsb3VkLmNsb3Vkc2Vj
dXJpdHljb21wbGlhbmNlLnYxQhhDbUVucm9sbG1lbnRTZXJ2aWNlUHJvdG9QAVplY2xvdWQu
Z29vZ2xlLmNvbS9nby9jbG91ZHNlY3VyaXR5Y29tcGxpYW5jZS9hcGl2MS9jbG91ZHNlY3Vy
aXR5Y29tcGxpYW5jZXBiO2Nsb3Vkc2VjdXJpdHljb21wbGlhbmNlcGKqAidHb29nbGUuQ2xv
dWQuQ2xvdWRTZWN1cml0eUNvbXBsaWFuY2UuVjHKAidHb29nbGVcQ2xvdWRcQ2xvdWRTZWN1
cml0eUNvbXBsaWFuY2VcVjHqAipHb29nbGU6OkNsb3VkOjpDbG91ZFNlY3VyaXR5Q29tcGxp
YW5jZTo6VjFKqSIKBxIFDgCeAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQADAKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgAqCggKAQgSAxgARAoJCgIIJRIDGABECggKAQgSAxkAfAoJCgIICxIDGQB8
CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAOQoJCgIICBIDGwA5CggKAQgSAxwARAoJ
CgIIARIDHABECggKAQgSAx0ARAoJCgIIKRIDHQBECggKAQgSAx4AQwoJCgIILRIDHgBDClIK
AgYAEgQiAEwBGkYgU2VydmljZSBkZXNjcmliaW5nIENtRW5yb2xsbWVudCByZWxhdGVkIFJQ
Q3MgZm9yCiBjb21wbGlhbmNlTWFuYWdlci4KCgoKAwYAARIDIggbCgoKAwYAAxIDIwJOCgwK
BQYAA5kIEgMjAk4KCwoDBgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3CtcBCgQGAAIAEgQrAjkD
GsgBIFVwZGF0ZXMgdGhlIENvbXBsaWFuY2UgTWFuYWdlciBlbnJvbGxtZW50IGZvciBhIHJl
c291cmNlIHRvIGZhY2lsaXRhdGUKIGFuIGF1ZGl0LgogVXNlIHRoaXMgbWV0aG9kIHRvIGVu
cm9sbCBhIHJlc291cmNlIGluIENvbXBsaWFuY2UgTWFuYWdlciBvciB0bwogY3JlYXRlIG9y
IHVwZGF0ZSBmZWF0dXJlLXNwZWNpZmljIGNvbmZpZ3VyYXRpb25zLgoKDAoFBgACAAESAysG
GAoMCgUGAAIAAhIDKxkyCgwKBQYAAgADEgMrPUkKDQoFBgACAAQSBCwENwYKEQoJBgACAASw
yrwiEgQsBDcGCgwKBQYAAgAEEgM4BEcKDwoIBgACAASbCAASAzgERwqKAgoEBgACARIEPwJL
Axr7ASBDYWxjdWxhdGVzIHRoZSBlZmZlY3RpdmUgQ29tcGxpYW5jZSBNYW5hZ2VyIGVucm9s
bG1lbnQgZm9yIGEgcmVzb3VyY2UuCiBBbiBlZmZlY3RpdmUgZW5yb2xsbWVudCBpcyBlaXRo
ZXIgYSBkaXJlY3QgZW5yb2xsbWVudCBvZiBhCiByZXNvdXJjZSAoaWYgaXQgZXhpc3RzKSwg
b3IgYW4gZW5yb2xsbWVudCBvZiB0aGUgY2xvc2VzdCBwYXJlbnQgb2YgYQogcmVzb3VyY2Ug
dGhhdCdzIGVucm9sbGVkIGluIENvbXBsaWFuY2UgTWFuYWdlci4KCgwKBQYAAgEBEgM/BiQK
DAoFBgACAQISAz8lSgoMCgUGAAIBAxIDQA81Cg0KBQYAAgEEEgRBBEkGChEKCQYAAgEEsMq8
IhIEQQRJBgoMCgUGAAIBBBIDSgQyCg8KCAYAAgEEmwgAEgNKBDIKPQoCBAASBE8AVwEaMSBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvciBbVXBkYXRlQ21FbnJvbGxtZW50XVtdLgoKCgoDBAAB
EgNPCCEKkgEKBAQAAgASA1ICShqEASBSZXF1aXJlZC4gVGhlIENvbXBsaWFuY2UgTWFuYWdl
ciBlbnJvbGxtZW50IHRvIHVwZGF0ZS4KIFRoZSBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBp
ZGVudGlmeSB0aGUgc2V0dGluZ3MgdGhhdCB5b3Ugd2FudCB0byB1cGRhdGUuCgoMCgUEAAIA
BhIDUgIOCgwKBQQAAgABEgNSDxwKDAoFBAACAAMSA1IfIAoMCgUEAAIACBIDUiFJCg8KCAQA
AgAInAgAEgNSIkgKRQoEBAACARIEVQJWLxo3IE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVs
ZHMgdGhhdCB5b3Ugd2FudCB0byB1cGRhdGUuCgoMCgUEAAIBBhIDVQIbCgwKBQQAAgEBEgNV
HCcKDAoFBAACAQMSA1UqKwoMCgUEAAIBCBIDVgYuCg8KCAQAAgEInAgAEgNWBy0KSQoCBAES
BFoAaAEaPSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciBbQ2FsY3VsYXRlRWZmZWN0aXZlQ21F
bnJvbGxtZW50XVtdLgoKCgoDBAEBEgNaCC0KvQIKBAQBAgASBGICZwQargIgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBDb21wbGlhbmNlIE1hbmFnZXIgZW5yb2xsbWVudCB0byBjYWxj
dWxhdGUuCgogU3VwcG9ydGVkIGZvcm1hdHMgYXJlIHRoZSBmb2xsb3dpbmc6CgogKiBgb3Jn
YW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbUVu
cm9sbG1lbnRgCiAqIGBmb2xkZXJzL3tmb2xkZXJfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NtRW5yb2xsbWVudGAKICogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jbUVucm9sbG1lbnRgCgoMCgUEAQIABRIDYgIICgwKBQQBAgABEgNiCQ0KDAoF
BAECAAMSA2IQEQoNCgUEAQIACBIEYhJnAwoPCggEAQIACJwIABIDYwQqCg8KBwQBAgAInwgS
BGQEZgUKUQoCBAISBWsAhQEBGkQgVGhlIHNldHRpbmdzIGZvciBDb21wbGlhbmNlIE1hbmFn
ZXIgYXQgYSBzcGVjaWZpYyByZXNvdXJjZSBzY29wZS49CgoKCgMEAgESA2sIFAoLCgMEAgcS
BGwCcgQKDQoFBAIHnQgSBGwCcgQKsQIKBAQCAgASA3sCPRqjAiBJZGVudGlmaWVyLiBUaGUg
bmFtZSBvZiB0aGUgQ29tcGxpYW5jZSBNYW5hZ2VyIGVucm9sbG1lbnQuCgogU3VwcG9ydGVk
IGZvcm1hdHMgYXJlIHRoZSBmb2xsb3dpbmc6CgogKiBgb3JnYW5pemF0aW9ucy97b3JnYW5p
emF0aW9uX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbUVucm9sbG1lbnRgCiAqIGBmb2xk
ZXJzL3tmb2xkZXJfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2NtRW5yb2xsbWVudGAKICog
YHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbUVucm9sbG1l
bnRgCgoMCgUEAgIABRIDewIICgwKBQQCAgABEgN7CQ0KDAoFBAICAAMSA3sQEQoMCgUEAgIA
CBIDexI8Cg8KCAQCAgAInAgAEgN7EzsKfwoEBAICARIDfwI9GnIgT3B0aW9uYWwuIFdoZXRo
ZXIgdGhlIHJlc291cmNlIGlzIGVucm9sbGVkIGluIENvbXBsaWFuY2UgTWFuYWdlci4KIFRo
aXMgc2V0dGluZyBpcyBpbmhlcml0ZWQgYnkgYWxsIGRlc2NlbmRhbnRzLgoKDAoFBAICAQUS
A38CBgoMCgUEAgIBARIDfwcPCgwKBQQCAgEDEgN/EhMKDAoFBAICAQgSA38UPAoPCggEAgIB
CJwIABIDfxU7Cp8BCgQEAgICEgSEAQJIGpABIE9wdGlvbmFsLiBUaGUgYXVkaXQgY29uZmln
dXJhdGlvbiBmb3IgQ29tcGxpYW5jZSBNYW5hZ2VyLgogSWYgc2V0IGF0IGEgc2NvcGUsIHRo
aXMgY29uZmlndXJhdGlvbiBvdmVycmlkZXMgYW55IGluaGVyaXRlZCBhdWRpdAogY29uZmln
dXJhdGlvbi4KCg0KBQQCAgIGEgSEAQINCg0KBQQCAgIBEgSEAQ4aCg0KBQQCAgIDEgSEAR0e
Cg0KBQQCAgIIEgSEAR9HChAKCAQCAgIInAgAEgSEASBGCkwKAgQDEgaIAQCLAQEaPiBUaGUg
cmVzcG9uc2UgbWVzc2FnZSBmb3IgW0NhbGN1bGF0ZUVmZmVjdGl2ZUNtRW5yb2xsbWVudF1b
XS4KCgsKAwQDARIEiAEILgpNCgQEAwIAEgSKAQIhGj8gVGhlIGVmZmVjdGl2ZSBDb21wbGlh
bmNlIE1hbmFnZXIgZW5yb2xsbWVudCBmb3IgdGhlIHJlc291cmNlLgoKDQoFBAMCAAYSBIoB
Ag4KDQoFBAMCAAESBIoBDxwKDQoFBAMCAAMSBIoBHyAKPwoCBAQSBo4BAJ4BARoxIFRoZSBh
dWRpdCBjb25maWd1cmF0aW9uIGZvciBDb21wbGlhbmNlIE1hbmFnZXIuCgoLCgMEBAESBI4B
CBMKTAoEBAQDABIGkQECmAEDGjwgVGhlIGRlc3RpbmF0aW9uIGRldGFpbHMgd2hlcmUgYXVk
aXQgcmVwb3J0cyBhcmUKIHVwbG9hZGVkLgoKDQoFBAQDAAESBJEBCh8KRwoGBAQDAAgAEgaT
AQSXAQUaNSBTZXQgb2Ygb3B0aW9ucyBmb3IgdGhlIHJlcG9ydCBkZXN0aW5hdGlvbiBsb2Nh
dGlvbi4KCg8KBwQEAwAIAAESBJMBCiIKggEKBgQEAwACABIElgEGHBpyIFRoZSBDbG91ZCBT
dG9yYWdlIGJ1Y2tldCB3aGVyZSBhdWRpdCByZXBvcnRzIGFuZCBldmlkZW5jZXMgY2FuIGJl
CiB1cGxvYWRlZC4gVGhlIGZvcm1hdCBpcyBgZ3M6Ly97YnVja2V0X25hbWV9YC4KCg8KBwQE
AwACAAUSBJYBBgwKDwoHBAQDAAIAARIElgENFwoPCgcEBAMAAgADEgSWARobCmoKBAQEAgAS
BpwBAp0BLxpaIFJlcXVpcmVkLiBUaGUgbGlzdCBvZiBkZXN0aW5hdGlvbnMgdGhhdCBjYW4g
YmUgc2VsZWN0ZWQgZm9yIHVwbG9hZGluZyBhdWRpdAogcmVwb3J0cyB0by4KCg0KBQQEAgAE
EgScAQIKCg0KBQQEAgAGEgScAQsgCg0KBQQEAgABEgScASEtCg0KBQQEAgADEgScATAxCg0K
BQQEAgAIEgSdAQYuChAKCAQEAgAInAgAEgSdAQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest ===
    # Fields for UpdateCmEnrollmentRequest
    # Field: cm_enrollment Type: 11 (.google.cloud.cloudsecuritycompliance.v1.CmEnrollment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest ===
    # Fields for CalculateEffectiveCmEnrollmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment ===
    # Fields for CmEnrollment
    # Field: name Type: 9 ()
    # Field: enrolled Type: 8 ()
    # Field: audit_config Type: 11 (.google.cloud.cloudsecuritycompliance.v1.AuditConfig)

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse ===
    # Fields for CalculateEffectiveCmEnrollmentResponse
    # Field: cm_enrollment Type: 11 (.google.cloud.cloudsecuritycompliance.v1.CmEnrollment)

# === Message: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig ===
    # Fields for AuditConfig
    # Field: destinations Type: 11 (.google.cloud.cloudsecuritycompliance.v1.AuditConfig.CmEligibleDestination)

# === Service Client: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollmentServiceClient ===
package Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollmentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollmentServiceClient

Client stub representing the remote C<CmEnrollmentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<cloudsecuritycompliance.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'cloudsecuritycompliance.googleapis.com:443' );

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

sub update_cm_enrollment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService',
        method         => 'UpdateCmEnrollment',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment',
    });
}

sub calculate_effective_cm_enrollment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService',
        method         => 'CalculateEffectiveCmEnrollment',
        request        => $req,
        response_class => 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService - Compiled Protocol Buffers messages for google/cloud/cloudsecuritycompliance/v1/cm_enrollment_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService;

    my $msg = Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest->new({
        cm_enrollment => $cm_enrollment,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->cm_enrollment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudsecuritycompliance/v1/cm_enrollment_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest

The request message for [UpdateCmEnrollment][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cm_enrollment() >> / C<< $msg->cm_enrollment($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment>)

Required. The Compliance Manager enrollment to update.
The `name` field is used to identify the settings that you want to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields that you want to update.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest

The request message for [CalculateEffectiveCmEnrollment][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Compliance Manager enrollment to calculate.

Supported formats are the following:

* `organizations/{organization_id}/locations/{location}/cmEnrollment`
* `folders/{folder_id}/locations/{location}/cmEnrollment`
* `projects/{project_id}/locations/{location}/cmEnrollment`

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment

The settings for Compliance Manager at a specific resource scope.=

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Compliance Manager enrollment.

Supported formats are the following:

* `organizations/{organization_id}/locations/{location}/cmEnrollment`
* `folders/{folder_id}/locations/{location}/cmEnrollment`
* `projects/{project_id}/locations/{location}/cmEnrollment`

=item * C<< $msg->enrolled() >> / C<< $msg->enrolled($value) >>

Type: C<Bool>

Optional. Whether the resource is enrolled in Compliance Manager.
This setting is inherited by all descendants.

=item * C<< $msg->audit_config() >> / C<< $msg->audit_config($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig>)

Optional. The audit configuration for Compliance Manager.
If set at a scope, this configuration overrides any inherited audit
configuration.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse

The response message for [CalculateEffectiveCmEnrollment][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cm_enrollment() >> / C<< $msg->cm_enrollment($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment>)

The effective Compliance Manager enrollment for the resource.

=back

=head2 Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig

The audit configuration for Compliance Manager.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->destinations() >> / C<< $msg->destinations($value) >>

Type: C<Message> (L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig::CmEligibleDestination>)

Required. The list of destinations that can be selected for uploading audit
reports to.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
