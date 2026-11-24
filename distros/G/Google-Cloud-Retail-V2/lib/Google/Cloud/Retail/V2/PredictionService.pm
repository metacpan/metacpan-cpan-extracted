package Google::Cloud::Retail::V2::PredictionService;

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
    eval { require Google::Cloud::Retail::V2::UserEvent };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcmV0YWlsL3YyL3ByZWRpY3Rpb25fc2VydmljZS5wcm90bxIWZ29v
Z2xlLmNsb3VkLnJldGFpbC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9jbG91ZC9yZXRhaWwvdjIvdXNl
cl9ldmVudC5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byKdBAoOUHJlZGlj
dFJlcXVlc3QSIQoJcGxhY2VtZW50GAEgASgJQgPgQQJSCXBsYWNlbWVudBJFCgp1c2VyX2V2
ZW50GAIgASgLMiEuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Vc2VyRXZlbnRCA+BBAlIJdXNl
ckV2ZW50EhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSIQoKcGFnZV90b2tlbhgEIAEo
CUICGAFSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBSABKAlSBmZpbHRlchIjCg12YWxpZGF0ZV9v
bmx5GAYgASgIUgx2YWxpZGF0ZU9ubHkSSgoGcGFyYW1zGAcgAygLMjIuZ29vZ2xlLmNsb3Vk
LnJldGFpbC52Mi5QcmVkaWN0UmVxdWVzdC5QYXJhbXNFbnRyeVIGcGFyYW1zEkoKBmxhYmVs
cxgIIAMoCzIyLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuUHJlZGljdFJlcXVlc3QuTGFiZWxz
RW50cnlSBmxhYmVscxpRCgtQYXJhbXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIsCgV2YWx1
ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIFdmFsdWU6AjgBGjkKC0xhYmVsc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEitgMKD1By
ZWRpY3RSZXNwb25zZRJSCgdyZXN1bHRzGAEgAygLMjguZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5QcmVkaWN0UmVzcG9uc2UuUHJlZGljdGlvblJlc3VsdFIHcmVzdWx0cxIrChFhdHRyaWJ1
dGlvbl90b2tlbhgCIAEoCVIQYXR0cmlidXRpb25Ub2tlbhIfCgttaXNzaW5nX2lkcxgDIAMo
CVIKbWlzc2luZ0lkcxIjCg12YWxpZGF0ZV9vbmx5GAQgASgIUgx2YWxpZGF0ZU9ubHka2wEK
EFByZWRpY3Rpb25SZXN1bHQSDgoCaWQYASABKAlSAmlkEmIKCG1ldGFkYXRhGAIgAygLMkYu
Z29vZ2xlLmNsb3VkLnJldGFpbC52Mi5QcmVkaWN0UmVzcG9uc2UuUHJlZGljdGlvblJlc3Vs
dC5NZXRhZGF0YUVudHJ5UghtZXRhZGF0YRpTCg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZToC
OAEy4QIKEVByZWRpY3Rpb25TZXJ2aWNlEoACCgdQcmVkaWN0EiYuZ29vZ2xlLmNsb3VkLnJl
dGFpbC52Mi5QcmVkaWN0UmVxdWVzdBonLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuUHJlZGlj
dFJlc3BvbnNlIqMBgtPkkwKcASJGL3YyL3twbGFjZW1lbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jYXRhbG9ncy8qL3BsYWNlbWVudHMvKn06cHJlZGljdDoBKlpPIkovdjIve3BsYWNl
bWVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3Mv
Kn06cHJlZGljdDoBKhpJykEVcmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULBAQoaY29tLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJCFlByZWRpY3Rpb25TZXJ2aWNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNv
bS9nby9yZXRhaWwvYXBpdjIvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhZHb29nbGUu
Q2xvdWQuUmV0YWlsLlYyygIWR29vZ2xlXENsb3VkXFJldGFpbFxWMuoCGUdvb2dsZTo6Q2xv
dWQ6OlJldGFpbDo6VjJKzEcKBxIFDgDhAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgAxCgkKAgMFEgMXACYKCAoBCBIDGQAzCgkKAgglEgMZADMKCAoB
CBIDGgBJCgkKAggLEgMaAEkKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA3CgkKAggI
EgMcADcKCAoBCBIDHQAzCgkKAggBEgMdADMKCAoBCBIDHgAkCgkKAggkEgMeACQKCAoBCBID
HwAzCgkKAggpEgMfADMKCAoBCBIDIAAyCgkKAggtEgMgADIKOwoCBgASBCMAMwEaLyBTZXJ2
aWNlIGZvciBtYWtpbmcgcmVjb21tZW5kYXRpb24gcHJlZGljdGlvbi4KCgoKAwYAARIDIwgZ
CgoKAwYAAxIDJAI9CgwKBQYAA5kIEgMkAj0KCwoDBgADEgQlAiY3Cg0KBQYAA5oIEgQlAiY3
CjIKBAYAAgASBCkCMgMaJCBNYWtlcyBhIHJlY29tbWVuZGF0aW9uIHByZWRpY3Rpb24uCgoM
CgUGAAIAARIDKQYNCgwKBQYAAgACEgMpDhwKDAoFBgACAAMSAyknNgoNCgUGAAIABBIEKgQx
BgoRCgkGAAIABLDKvCISBCoEMQYKMgoCBAASBTYAvgEBGiUgUmVxdWVzdCBtZXNzYWdlIGZv
ciBQcmVkaWN0IG1ldGhvZC4KCgoKAwQAARIDNggWCugFCgQEAAIAEgNFAkAa2gUgUmVxdWly
ZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZm9ybWF0OgogYHtwbGFjZW1lbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxvZy9zZXJ2
aW5nQ29uZmlncy8qfWAKIG9yCiBge3BsYWNlbWVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy9n
bG9iYWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9nL3BsYWNlbWVudHMvKn1gLgogV2UgcmVj
b21tZW5kIHVzaW5nIHRoZSBgc2VydmluZ0NvbmZpZ3NgIHJlc291cmNlLiBgcGxhY2VtZW50
c2AgaXMgYSBsZWdhY3kKIHJlc291cmNlLgogVGhlIElEIG9mIHRoZSBSZWNvbW1lbmRhdGlv
bnMgQUkgc2VydmluZyBjb25maWcgb3IgcGxhY2VtZW50LgogQmVmb3JlIHlvdSBjYW4gcmVx
dWVzdCBwcmVkaWN0aW9ucyBmcm9tIHlvdXIgbW9kZWwsIHlvdSBtdXN0IGNyZWF0ZSBhdAog
bGVhc3Qgb25lIHNlcnZpbmcgY29uZmlnIG9yIHBsYWNlbWVudCBmb3IgaXQuIEZvciBtb3Jl
IGluZm9ybWF0aW9uLCBzZWUKIFtNYW5hZ2Ugc2VydmluZyBjb25maWdzXQogKGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS9yZXRhaWwvZG9jcy9tYW5hZ2UtY29uZmlncykuCgogVGhlIGZ1
bGwgbGlzdCBvZiBhdmFpbGFibGUgc2VydmluZyBjb25maWdzIGNhbiBiZSBzZWVuIGF0CiBo
dHRwczovL2NvbnNvbGUuY2xvdWQuZ29vZ2xlLmNvbS9haS9yZXRhaWwvY2F0YWxvZ3MvZGVm
YXVsdF9jYXRhbG9nL2NvbmZpZ3MKCgwKBQQAAgAFEgNFAggKDAoFBAACAAESA0UJEgoMCgUE
AAIAAxIDRRUWCgwKBQQAAgAIEgNFFz8KDwoIBAACAAicCAASA0UYPgqIBgoEBAACARIDVQJE
GvoFIFJlcXVpcmVkLiBDb250ZXh0IGFib3V0IHRoZSB1c2VyLCB3aGF0IHRoZXkgYXJlIGxv
b2tpbmcgYXQgYW5kIHdoYXQgYWN0aW9uCiB0aGV5IHRvb2sgdG8gdHJpZ2dlciB0aGUgcHJl
ZGljdCByZXF1ZXN0LiBOb3RlIHRoYXQgdGhpcyB1c2VyIGV2ZW50IGRldGFpbAogd29uJ3Qg
YmUgaW5nZXN0ZWQgdG8gdXNlckV2ZW50IGxvZ3MuIFRodXMsIGEgc2VwYXJhdGUgdXNlckV2
ZW50IHdyaXRlCiByZXF1ZXN0IGlzIHJlcXVpcmVkIGZvciBldmVudCBsb2dnaW5nLgoKIERv
bid0IHNldAogW1VzZXJFdmVudC52aXNpdG9yX2lkXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
LlVzZXJFdmVudC52aXNpdG9yX2lkXSBvcgogW1VzZXJJbmZvLnVzZXJfaWRdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjIuVXNlckluZm8udXNlcl9pZF0gdG8gdGhlIHNhbWUKIGZpeGVkIElE
IGZvciBkaWZmZXJlbnQgdXNlcnMuIElmIHlvdSBhcmUgdHJ5aW5nIHRvIHJlY2VpdmUgbm9u
LXBlcnNvbmFsaXplZAogcmVjb21tZW5kYXRpb25zIChub3QgcmVjb21tZW5kZWQ7IHRoaXMg
Y2FuIG5lZ2F0aXZlbHkgaW1wYWN0IG1vZGVsCiBwZXJmb3JtYW5jZSksIGluc3RlYWQgc2V0
CiBbVXNlckV2ZW50LnZpc2l0b3JfaWRdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckV2
ZW50LnZpc2l0b3JfaWRdIHRvIGEKIHJhbmRvbSB1bmlxdWUgSUQgYW5kIGxlYXZlCiBbVXNl
ckluZm8udXNlcl9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Vc2VySW5mby51c2VyX2lk
XSB1bnNldC4KCgwKBQQAAgEGEgNVAgsKDAoFBAACAQESA1UMFgoMCgUEAAIBAxIDVRkaCgwK
BQQAAgEIEgNVG0MKDwoIBAACAQicCAASA1UcQgr3AQoEBAACAhIDWwIWGukBIE1heGltdW0g
bnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBTZXQgdGhpcyBwcm9wZXJ0eSB0byB0aGUg
bnVtYmVyIG9mCiBwcmVkaWN0aW9uIHJlc3VsdHMgbmVlZGVkLiBJZiB6ZXJvLCB0aGUgc2Vy
dmljZSB3aWxsIGNob29zZSBhIHJlYXNvbmFibGUKIGRlZmF1bHQuIFRoZSBtYXhpbXVtIGFs
bG93ZWQgdmFsdWUgaXMgMTAwLiBWYWx1ZXMgYWJvdmUgMTAwIHdpbGwgYmUgY29lcmNlZAog
dG8gMTAwLgoKDAoFBAACAgUSA1sCBwoMCgUEAAICARIDWwgRCgwKBQQAAgIDEgNbFBUKNgoE
BAACAxIDXgIsGikgVGhpcyBmaWVsZCBpcyBub3QgdXNlZDsgbGVhdmUgaXQgdW5zZXQuCgoM
CgUEAAIDBRIDXgIICgwKBQQAAgMBEgNeCRMKDAoFBAACAwMSA14WFwoMCgUEAAIDCBIDXhgr
Cg0KBgQAAgMIAxIDXhkqCr8NCgQEAAIEEgSHAQIUGrANIEZpbHRlciBmb3IgcmVzdHJpY3Rp
bmcgcHJlZGljdGlvbiByZXN1bHRzIHdpdGggYSBsZW5ndGggbGltaXQgb2YgNSwwMDAKIGNo
YXJhY3RlcnMuIEFjY2VwdHMgdmFsdWVzIGZvciB0YWdzIGFuZCB0aGUgYGZpbHRlck91dE9m
U3RvY2tJdGVtc2AgZmxhZy4KCiAgKiBUYWcgZXhwcmVzc2lvbnMuIFJlc3RyaWN0cyBwcmVk
aWN0aW9ucyB0byBwcm9kdWN0cyB0aGF0IG1hdGNoIGFsbCBvZiB0aGUKICAgIHNwZWNpZmll
ZCB0YWdzLiBCb29sZWFuIG9wZXJhdG9ycyBgT1JgIGFuZCBgTk9UYCBhcmUgc3VwcG9ydGVk
IGlmIHRoZQogICAgZXhwcmVzc2lvbiBpcyBlbmNsb3NlZCBpbiBwYXJlbnRoZXNlcywgYW5k
IG11c3QgYmUgc2VwYXJhdGVkIGZyb20gdGhlCiAgICB0YWcgdmFsdWVzIGJ5IGEgc3BhY2Uu
IGAtInRhZ0EiYCBpcyBhbHNvIHN1cHBvcnRlZCBhbmQgaXMgZXF1aXZhbGVudCB0bwogICAg
YE5PVCAidGFnQSJgLiBUYWcgdmFsdWVzIG11c3QgYmUgZG91YmxlIHF1b3RlZCBVVEYtOCBl
bmNvZGVkIHN0cmluZ3MKICAgIHdpdGggYSBzaXplIGxpbWl0IG9mIDEsMDAwIGNoYXJhY3Rl
cnMuCgogICAgTm90ZTogIlJlY2VudGx5IHZpZXdlZCIgbW9kZWxzIGRvbid0IHN1cHBvcnQg
dGFnIGZpbHRlcmluZyBhdCB0aGUKICAgIG1vbWVudC4KCiAgKiBmaWx0ZXJPdXRPZlN0b2Nr
SXRlbXMuIFJlc3RyaWN0cyBwcmVkaWN0aW9ucyB0byBwcm9kdWN0cyB0aGF0IGRvIG5vdAog
IGhhdmUgYQogICAgc3RvY2tTdGF0ZSB2YWx1ZSBvZiBPVVRfT0ZfU1RPQ0suCgogRXhhbXBs
ZXM6CgogICogdGFnPSgiUmVkIiBPUiAiQmx1ZSIpIHRhZz0iTmV3LUFycml2YWwiIHRhZz0o
Tk9UICJwcm9tb3Rpb25hbCIpCiAgKiBmaWx0ZXJPdXRPZlN0b2NrSXRlbXMgIHRhZz0oLSJw
cm9tb3Rpb25hbCIpCiAgKiBmaWx0ZXJPdXRPZlN0b2NrSXRlbXMKCiBJZiB5b3VyIGZpbHRl
ciBibG9ja3MgYWxsIHByZWRpY3Rpb24gcmVzdWx0cywgdGhlIEFQSSB3aWxsIHJldHVybiAq
bm8qCiByZXN1bHRzLiBJZiBpbnN0ZWFkIHlvdSB3YW50IGVtcHR5IHJlc3VsdCBzZXRzIHRv
IHJldHVybiBnZW5lcmljCiAodW5maWx0ZXJlZCkgcG9wdWxhciBwcm9kdWN0cywgc2V0IGBz
dHJpY3RGaWx0ZXJpbmdgIHRvIEZhbHNlIGluCiBgUHJlZGljdFJlcXVlc3QucGFyYW1zYC4g
Tm90ZSB0aGF0IHRoZSBBUEkgd2lsbCBuZXZlciByZXR1cm4gaXRlbXMgd2l0aAogc3RvcmFn
ZVN0YXR1cyBvZiAiRVhQSVJFRCIgb3IgIkRFTEVURUQiIHJlZ2FyZGxlc3Mgb2YgZmlsdGVy
IGNob2ljZXMuCgogSWYgYGZpbHRlclN5bnRheFYyYCBpcyBzZXQgdG8gdHJ1ZSB1bmRlciB0
aGUgYHBhcmFtc2AgZmllbGQsIHRoZW4KIGF0dHJpYnV0ZS1iYXNlZCBleHByZXNzaW9ucyBh
cmUgZXhwZWN0ZWQgaW5zdGVhZCBvZiB0aGUgYWJvdmUgZGVzY3JpYmVkCiB0YWctYmFzZWQg
c3ludGF4LiBFeGFtcGxlczoKCiAgKiAoY29sb3JzOiBBTlkoIlJlZCIsICJCbHVlIikpIEFO
RCBOT1QgKGNhdGVnb3JpZXM6IEFOWSgiUGhvbmVzIikpCiAgKiAoYXZhaWxhYmlsaXR5OiBB
TlkoIklOX1NUT0NLIikpIEFORAogICAgKGNvbG9yczogQU5ZKCJSZWQiKSBPUiBjYXRlZ29y
aWVzOiBBTlkoIlBob25lcyIpKQoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtGaWx0
ZXIgcmVjb21tZW5kYXRpb25zXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2Rv
Y3MvZmlsdGVyLXJlY3MpLgoKDQoFBAACBAUSBIcBAggKDQoFBAACBAESBIcBCQ8KDQoFBAAC
BAMSBIcBEhMK+QEKBAQAAgUSBI0BAhka6gEgVXNlIHZhbGlkYXRlIG9ubHkgbW9kZSBmb3Ig
dGhpcyBwcmVkaWN0aW9uIHF1ZXJ5LiBJZiBzZXQgdG8gdHJ1ZSwgYQogZHVtbXkgbW9kZWwg
d2lsbCBiZSB1c2VkIHRoYXQgcmV0dXJucyBhcmJpdHJhcnkgcHJvZHVjdHMuCiBOb3RlIHRo
YXQgdGhlIHZhbGlkYXRlIG9ubHkgbW9kZSBzaG91bGQgb25seSBiZSB1c2VkIGZvciB0ZXN0
aW5nIHRoZSBBUEksCiBvciBpZiB0aGUgbW9kZWwgaXMgbm90IHJlYWR5LgoKDQoFBAACBQUS
BI0BAgYKDQoFBAACBQESBI0BBxQKDQoFBAACBQMSBI0BFxgK4AsKBAQAAgYSBKoBAjAa0Qsg
QWRkaXRpb25hbCBkb21haW4gc3BlY2lmaWMgcGFyYW1ldGVycyBmb3IgdGhlIHByZWRpY3Rp
b25zLgoKIEFsbG93ZWQgdmFsdWVzOgoKICogYHJldHVyblByb2R1Y3RgOiBCb29sZWFuLiBJ
ZiBzZXQgdG8gdHJ1ZSwgdGhlIGFzc29jaWF0ZWQgcHJvZHVjdAogICAgb2JqZWN0IHdpbGwg
YmUgcmV0dXJuZWQgaW4gdGhlIGByZXN1bHRzLm1ldGFkYXRhYCBmaWVsZCBpbiB0aGUKICAg
IHByZWRpY3Rpb24gcmVzcG9uc2UuCiAqIGByZXR1cm5TY29yZWA6IEJvb2xlYW4uIElmIHNl
dCB0byB0cnVlLCB0aGUgcHJlZGljdGlvbiAnc2NvcmUnCiAgICBjb3JyZXNwb25kaW5nIHRv
IGVhY2ggcmV0dXJuZWQgcHJvZHVjdCB3aWxsIGJlIHNldCBpbiB0aGUKICAgIGByZXN1bHRz
Lm1ldGFkYXRhYCBmaWVsZCBpbiB0aGUgcHJlZGljdGlvbiByZXNwb25zZS4gVGhlIGdpdmVu
CiAgICAnc2NvcmUnIGluZGljYXRlcyB0aGUgcHJvYmFiaWxpdHkgb2YgYSBwcm9kdWN0IGJl
aW5nIGNsaWNrZWQvcHVyY2hhc2VkCiAgICBnaXZlbiB0aGUgdXNlcidzIGNvbnRleHQgYW5k
IGhpc3RvcnkuCiAqIGBzdHJpY3RGaWx0ZXJpbmdgOiBCb29sZWFuLiBUcnVlIGJ5IGRlZmF1
bHQuIElmIHNldCB0byBmYWxzZSwgdGhlIHNlcnZpY2UKICAgIHdpbGwgcmV0dXJuIGdlbmVy
aWMgKHVuZmlsdGVyZWQpIHBvcHVsYXIgcHJvZHVjdHMgaW5zdGVhZCBvZiBlbXB0eSBpZgog
ICAgeW91ciBmaWx0ZXIgYmxvY2tzIGFsbCBwcmVkaWN0aW9uIHJlc3VsdHMuCiAqIGBwcmlj
ZVJlcmFua0xldmVsYDogU3RyaW5nLiBEZWZhdWx0IGVtcHR5LiBJZiBzZXQgdG8gYmUgbm9u
LWVtcHR5LCB0aGVuCiAgICBpdCBuZWVkcyB0byBiZSBvbmUgb2Ygeyduby1wcmljZS1yZXJh
bmtpbmcnLCAnbG93LXByaWNlLXJlcmFua2luZycsCiAgICAnbWVkaXVtLXByaWNlLXJlcmFu
a2luZycsICdoaWdoLXByaWNlLXJlcmFua2luZyd9LiBUaGlzIGdpdmVzCiAgICByZXF1ZXN0
LWxldmVsIGNvbnRyb2wgYW5kIGFkanVzdHMgcHJlZGljdGlvbiByZXN1bHRzIGJhc2VkIG9u
IHByb2R1Y3QKICAgIHByaWNlLgogKiBgZGl2ZXJzaXR5TGV2ZWxgOiBTdHJpbmcuIERlZmF1
bHQgZW1wdHkuIElmIHNldCB0byBiZSBub24tZW1wdHksIHRoZW4KICAgIGl0IG5lZWRzIHRv
IGJlIG9uZSBvZiB7J25vLWRpdmVyc2l0eScsICdsb3ctZGl2ZXJzaXR5JywKICAgICdtZWRp
dW0tZGl2ZXJzaXR5JywgJ2hpZ2gtZGl2ZXJzaXR5JywgJ2F1dG8tZGl2ZXJzaXR5J30uIFRo
aXMgZ2l2ZXMKICAgIHJlcXVlc3QtbGV2ZWwgY29udHJvbCBhbmQgYWRqdXN0cyBwcmVkaWN0
aW9uIHJlc3VsdHMgYmFzZWQgb24gcHJvZHVjdAogICAgY2F0ZWdvcnkuCiAqIGBmaWx0ZXJT
eW50YXhWMmA6IEJvb2xlYW4uIEZhbHNlIGJ5IGRlZmF1bHQuIElmIHNldCB0byB0cnVlLCB0
aGUgYGZpbHRlcmAKICAgZmllbGQgaXMgaW50ZXJwcmV0ZXRlZCBhY2NvcmRpbmcgdG8gdGhl
IG5ldywgYXR0cmlidXRlLWJhc2VkIHN5bnRheC4KCg0KBQQAAgYGEgSqAQIkCg0KBQQAAgYB
EgSqASUrCg0KBQQAAgYDEgSqAS4vCucGCgQEAAIHEgS9AQIhGtgGIFRoZSBsYWJlbHMgYXBw
bGllZCB0byBhIHJlc291cmNlIG11c3QgbWVldCB0aGUgZm9sbG93aW5nIHJlcXVpcmVtZW50
czoKCiAqIEVhY2ggcmVzb3VyY2UgY2FuIGhhdmUgbXVsdGlwbGUgbGFiZWxzLCB1cCB0byBh
IG1heGltdW0gb2YgNjQuCiAqIEVhY2ggbGFiZWwgbXVzdCBiZSBhIGtleS12YWx1ZSBwYWly
LgogKiBLZXlzIGhhdmUgYSBtaW5pbXVtIGxlbmd0aCBvZiAxIGNoYXJhY3RlciBhbmQgYSBt
YXhpbXVtIGxlbmd0aCBvZiA2MwogICBjaGFyYWN0ZXJzIGFuZCBjYW5ub3QgYmUgZW1wdHku
IFZhbHVlcyBjYW4gYmUgZW1wdHkgYW5kIGhhdmUgYSBtYXhpbXVtCiAgIGxlbmd0aCBvZiA2
MyBjaGFyYWN0ZXJzLgogKiBLZXlzIGFuZCB2YWx1ZXMgY2FuIGNvbnRhaW4gb25seSBsb3dl
cmNhc2UgbGV0dGVycywgbnVtZXJpYyBjaGFyYWN0ZXJzLAogICB1bmRlcnNjb3JlcywgYW5k
IGRhc2hlcy4gQWxsIGNoYXJhY3RlcnMgbXVzdCB1c2UgVVRGLTggZW5jb2RpbmcsIGFuZAog
ICBpbnRlcm5hdGlvbmFsIGNoYXJhY3RlcnMgYXJlIGFsbG93ZWQuCiAqIFRoZSBrZXkgcG9y
dGlvbiBvZiBhIGxhYmVsIG11c3QgYmUgdW5pcXVlLiBIb3dldmVyLCB5b3UgY2FuIHVzZSB0
aGUgc2FtZQogICBrZXkgd2l0aCBtdWx0aXBsZSByZXNvdXJjZXMuCiAqIEtleXMgbXVzdCBz
dGFydCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciBvciBpbnRlcm5hdGlvbmFsIGNoYXJhY3Rl
ci4KCiBTZWUgW0dvb2dsZSBDbG91ZAogRG9jdW1lbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctbGFiZWxzI3Jl
cXVpcmVtZW50cykKIGZvciBtb3JlIGRldGFpbHMuCgoNCgUEAAIHBhIEvQECFQoNCgUEAAIH
ARIEvQEWHAoNCgUEAAIHAxIEvQEfIAo0CgIEARIGwQEA4QEBGiYgUmVzcG9uc2UgbWVzc2Fn
ZSBmb3IgcHJlZGljdCBtZXRob2QuCgoLCgMEAQESBMEBCBcKVAoEBAEDABIGwwEC0AEDGkQg
UHJlZGljdGlvblJlc3VsdCByZXByZXNlbnRzIHRoZSByZWNvbW1lbmRhdGlvbiBwcmVkaWN0
aW9uIHJlc3VsdHMuCgoNCgUEAQMAARIEwwEKGgovCgYEAQMAAgASBMUBBBIaHyBJRCBvZiB0
aGUgcmVjb21tZW5kZWQgcHJvZHVjdAoKDwoHBAEDAAIABRIExQEECgoPCgcEAQMAAgABEgTF
AQsNCg8KBwQBAwACAAMSBMUBEBEKvwIKBgQBAwACARIEzwEENBquAiBBZGRpdGlvbmFsIHBy
b2R1Y3QgbWV0YWRhdGEgLyBhbm5vdGF0aW9ucy4KCiBQb3NzaWJsZSB2YWx1ZXM6CgogKiBg
cHJvZHVjdGA6IEpTT04gcmVwcmVzZW50YXRpb24gb2YgdGhlIHByb2R1Y3QuIElzIHNldCBp
ZgogICBgcmV0dXJuUHJvZHVjdGAgaXMgc2V0IHRvIHRydWUgaW4gYFByZWRpY3RSZXF1ZXN0
LnBhcmFtc2AuCiAqIGBzY29yZWA6IFByZWRpY3Rpb24gc2NvcmUgaW4gZG91YmxlIHZhbHVl
LiBJcyBzZXQgaWYKICAgYHJldHVyblNjb3JlYCBpcyBzZXQgdG8gdHJ1ZSBpbiBgUHJlZGlj
dFJlcXVlc3QucGFyYW1zYC4KCg8KBwQBAwACAQYSBM8BBCYKDwoHBAEDAAIBARIEzwEnLwoP
CgcEAQMAAgEDEgTPATIzCoABCgQEAQIAEgTUAQIoGnIgQSBsaXN0IG9mIHJlY29tbWVuZGVk
IHByb2R1Y3RzLiBUaGUgb3JkZXIgcmVwcmVzZW50cyB0aGUgcmFua2luZyAoZnJvbSB0aGUK
IG1vc3QgcmVsZXZhbnQgcHJvZHVjdCB0byB0aGUgbGVhc3QpLgoKDQoFBAECAAQSBNQBAgoK
DQoFBAECAAYSBNQBCxsKDQoFBAECAAESBNQBHCMKDQoFBAECAAMSBNQBJicK7QEKBAQBAgES
BNoBAh8a3gEgQSB1bmlxdWUgYXR0cmlidXRpb24gdG9rZW4uIFRoaXMgc2hvdWxkIGJlIGlu
Y2x1ZGVkIGluIHRoZQogW1VzZXJFdmVudF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Vc2Vy
RXZlbnRdIGxvZ3MgcmVzdWx0aW5nIGZyb20gdGhpcwogcmVjb21tZW5kYXRpb24sIHdoaWNo
IGVuYWJsZXMgYWNjdXJhdGUgYXR0cmlidXRpb24gb2YgcmVjb21tZW5kYXRpb24gbW9kZWwK
IHBlcmZvcm1hbmNlLgoKDQoFBAECAQUSBNoBAggKDQoFBAECAQESBNoBCRoKDQoFBAECAQMS
BNoBHR4KVAoEBAECAhIE3QECIhpGIElEcyBvZiBwcm9kdWN0cyBpbiB0aGUgcmVxdWVzdCB0
aGF0IHdlcmUgbWlzc2luZyBmcm9tIHRoZSBpbnZlbnRvcnkuCgoNCgUEAQICBBIE3QECCgoN
CgUEAQICBRIE3QELEQoNCgUEAQICARIE3QESHQoNCgUEAQICAxIE3QEgIQpJCgQEAQIDEgTg
AQIZGjsgVHJ1ZSBpZiB0aGUgdmFsaWRhdGVPbmx5IHByb3BlcnR5IHdhcyBzZXQgaW4gdGhl
IHJlcXVlc3QuCgoNCgUEAQIDBRIE4AECBgoNCgUEAQIDARIE4AEHFAoNCgUEAQIDAxIE4AEX
GGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: placement Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.retail.v2.UserEvent)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: params Type: 11 (.google.cloud.retail.v2.PredictRequest.ParamsEntry)
    # Field: labels Type: 11 (.google.cloud.retail.v2.PredictRequest.LabelsEntry)

# === Message: Google::Cloud::Retail::V2::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: results Type: 11 (.google.cloud.retail.v2.PredictResponse.PredictionResult)
    # Field: attribution_token Type: 9 ()
    # Field: missing_ids Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Cloud::Retail::V2::PredictionService::PredictionServiceClient ===
package Google::Cloud::Retail::V2::PredictionService::PredictionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::PredictionService::PredictionServiceClient

Client stub representing the remote C<PredictionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::PredictionService::PredictResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::PredictionService - Compiled Protocol Buffers messages for google/cloud/retail/v2/prediction_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::PredictionService;

    my $msg = Google::Cloud::Retail::V2::PredictionService::PredictRequest->new({
        placement => $placement,
        user_event => $user_event,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->placement();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::PredictionService::PredictRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/prediction_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::PredictionService::PredictRequest

Request message for Predict method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->placement() >> / C<< $msg->placement($value) >>

Type: C<String>

Required. Full resource name of the format:
`{placement=projects/*/locations/global/catalogs/default_catalog/servingConfigs/*}`
or
`{placement=projects/*/locations/global/catalogs/default_catalog/placements/*}`.
We recommend using the `servingConfigs` resource. `placements` is a legacy
resource.
The ID of the Recommendations AI serving config or placement.
Before you can request predictions from your model, you must create at
least one serving config or placement for it. For more information, see
[Manage serving configs]
(https://cloud.google.com/retail/docs/manage-configs).

The full list of available serving configs can be seen at
https://console.cloud.google.com/ai/retail/catalogs/default_catalog/configs

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::UserEvent::UserEvent>)

Required. Context about the user, what they are looking at and what action
they took to trigger the predict request. Note that this user event detail
won't be ingested to userEvent logs. Thus, a separate userEvent write
request is required for event logging.

Don't set
[UserEvent.visitor_id][google.cloud.retail.v2.UserEvent.visitor_id] or
[UserInfo.user_id][google.cloud.retail.v2.UserInfo.user_id] to the same
fixed ID for different users. If you are trying to receive non-personalized
recommendations (not recommended; this can negatively impact model
performance), instead set
[UserEvent.visitor_id][google.cloud.retail.v2.UserEvent.visitor_id] to a
random unique ID and leave
[UserInfo.user_id][google.cloud.retail.v2.UserInfo.user_id] unset.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of results to return. Set this property to the number of
prediction results needed. If zero, the service will choose a reasonable
default. The maximum allowed value is 100. Values above 100 will be coerced
to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

This field is not used; leave it unset.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter for restricting prediction results with a length limit of 5,000
characters. Accepts values for tags and the `filterOutOfStockItems` flag.

 * Tag expressions. Restricts predictions to products that match all of the
   specified tags. Boolean operators `OR` and `NOT` are supported if the
   expression is enclosed in parentheses, and must be separated from the
   tag values by a space. `-"tagA"` is also supported and is equivalent to
   `NOT "tagA"`. Tag values must be double quoted UTF-8 encoded strings
   with a size limit of 1,000 characters.

   Note: "Recently viewed" models don't support tag filtering at the
   moment.

 * filterOutOfStockItems. Restricts predictions to products that do not
 have a
   stockState value of OUT_OF_STOCK.

Examples:

 * tag=("Red" OR "Blue") tag="New-Arrival" tag=(NOT "promotional")
 * filterOutOfStockItems  tag=(-"promotional")
 * filterOutOfStockItems

If your filter blocks all prediction results, the API will return *no*
results. If instead you want empty result sets to return generic
(unfiltered) popular products, set `strictFiltering` to False in
`PredictRequest.params`. Note that the API will never return items with
storageStatus of "EXPIRED" or "DELETED" regardless of filter choices.

If `filterSyntaxV2` is set to true under the `params` field, then
attribute-based expressions are expected instead of the above described
tag-based syntax. Examples:

 * (colors: ANY("Red", "Blue")) AND NOT (categories: ANY("Phones"))
 * (availability: ANY("IN_STOCK")) AND
   (colors: ANY("Red") OR categories: ANY("Phones"))

For more information, see
[Filter recommendations](https://cloud.google.com/retail/docs/filter-recs).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Use validate only mode for this prediction query. If set to true, a
dummy model will be used that returns arbitrary products.
Note that the validate only mode should only be used for testing the API,
or if the model is not ready.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::PredictionService::PredictRequest::ParamsEntry>)

Additional domain specific parameters for the predictions.

Allowed values:

* `returnProduct`: Boolean. If set to true, the associated product
   object will be returned in the `results.metadata` field in the
   prediction response.
* `returnScore`: Boolean. If set to true, the prediction 'score'
   corresponding to each returned product will be set in the
   `results.metadata` field in the prediction response. The given
   'score' indicates the probability of a product being clicked/purchased
   given the user's context and history.
* `strictFiltering`: Boolean. True by default. If set to false, the service
   will return generic (unfiltered) popular products instead of empty if
   your filter blocks all prediction results.
* `priceRerankLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of {'no-price-reranking', 'low-price-reranking',
   'medium-price-reranking', 'high-price-reranking'}. This gives
   request-level control and adjusts prediction results based on product
   price.
* `diversityLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of {'no-diversity', 'low-diversity',
   'medium-diversity', 'high-diversity', 'auto-diversity'}. This gives
   request-level control and adjusts prediction results based on product
   category.
* `filterSyntaxV2`: Boolean. False by default. If set to true, the `filter`
  field is interpreteted according to the new, attribute-based syntax.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::PredictionService::PredictRequest::LabelsEntry>)

The labels applied to a resource must meet the following requirements:

* Each resource can have multiple labels, up to a maximum of 64.
* Each label must be a key-value pair.
* Keys have a minimum length of 1 character and a maximum length of 63
  characters and cannot be empty. Values can be empty and have a maximum
  length of 63 characters.
* Keys and values can contain only lowercase letters, numeric characters,
  underscores, and dashes. All characters must use UTF-8 encoding, and
  international characters are allowed.
* The key portion of a label must be unique. However, you can use the same
  key with multiple resources.
* Keys must start with a lowercase letter or international character.

See [Google Cloud
Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
for more details.

=back

=head2 Google::Cloud::Retail::V2::PredictionService::PredictResponse

Response message for predict method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::PredictionService::PredictResponse::PredictionResult>)

A list of recommended products. The order represents the ranking (from the
most relevant product to the least).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique attribution token. This should be included in the
[UserEvent][google.cloud.retail.v2.UserEvent] logs resulting from this
recommendation, which enables accurate attribution of recommendation model
performance.

=item * C<< $msg->missing_ids() >> / C<< $msg->missing_ids($value) >>

Type: C<String>

IDs of products in the request that were missing from the inventory.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

True if the validateOnly property was set in the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::PredictionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
