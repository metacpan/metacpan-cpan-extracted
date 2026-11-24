package Google::Cloud::Datalabeling::V1beta1::Evaluation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Datalabeling::V1beta1::Annotation };
    eval { require Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvZXZhbHVhdGlvbi5wcm90bxIh
Z29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGjJnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvYW5ub3RhdGlvbi5w
cm90bxo7Z29vZ2xlL2Nsb3VkL2RhdGFsYWJlbGluZy92MWJldGExL2Fubm90YXRpb25fc3Bl
Y19zZXQucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i3QQKCkV2YWx1
YXRpb24SEgoEbmFtZRgBIAEoCVIEbmFtZRJLCgZjb25maWcYAiABKAsyMy5nb29nbGUuY2xv
dWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbkNvbmZpZ1IGY29uZmlnElEKF2V2
YWx1YXRpb25fam9iX3J1bl90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIUZXZhbHVhdGlvbkpvYlJ1blRpbWUSOwoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEmMKEmV2YWx1YXRpb25fbWV0cmljcxgF
IAEoCzI0Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5FdmFsdWF0aW9uTWV0
cmljc1IRZXZhbHVhdGlvbk1ldHJpY3MSWgoPYW5ub3RhdGlvbl90eXBlGAYgASgOMjEuZ29v
Z2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkFubm90YXRpb25UeXBlUg5hbm5vdGF0
aW9uVHlwZRIwChRldmFsdWF0ZWRfaXRlbV9jb3VudBgHIAEoA1ISZXZhbHVhdGVkSXRlbUNv
dW50OmvqQWgKJmRhdGFsYWJlbGluZy5nb29nbGVhcGlzLmNvbS9FdmFsdWF0aW9uEj5wcm9q
ZWN0cy97cHJvamVjdH0vZGF0YXNldHMve2RhdGFzZXR9L2V2YWx1YXRpb25zL3tldmFsdWF0
aW9ufSKwAQoQRXZhbHVhdGlvbkNvbmZpZxKIAQofYm91bmRpbmdfYm94X2V2YWx1YXRpb25f
b3B0aW9ucxgBIAEoCzI/Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5Cb3Vu
ZGluZ0JveEV2YWx1YXRpb25PcHRpb25zSABSHGJvdW5kaW5nQm94RXZhbHVhdGlvbk9wdGlv
bnNCEQoPdmVydGljYWxfb3B0aW9uIkMKHEJvdW5kaW5nQm94RXZhbHVhdGlvbk9wdGlvbnMS
IwoNaW91X3RocmVzaG9sZBgBIAEoAlIMaW91VGhyZXNob2xkIogCChFFdmFsdWF0aW9uTWV0
cmljcxJxChZjbGFzc2lmaWNhdGlvbl9tZXRyaWNzGAEgASgLMjguZ29vZ2xlLmNsb3VkLmRh
dGFsYWJlbGluZy52MWJldGExLkNsYXNzaWZpY2F0aW9uTWV0cmljc0gAUhVjbGFzc2lmaWNh
dGlvbk1ldHJpY3MSdQoYb2JqZWN0X2RldGVjdGlvbl9tZXRyaWNzGAIgASgLMjkuZ29vZ2xl
LmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLk9iamVjdERldGVjdGlvbk1ldHJpY3NIAFIW
b2JqZWN0RGV0ZWN0aW9uTWV0cmljc0IJCgdtZXRyaWNzIr0BChVDbGFzc2lmaWNhdGlvbk1l
dHJpY3MSRQoIcHJfY3VydmUYASABKAsyKi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYx
YmV0YTEuUHJDdXJ2ZVIHcHJDdXJ2ZRJdChBjb25mdXNpb25fbWF0cml4GAIgASgLMjIuZ29v
Z2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkNvbmZ1c2lvbk1hdHJpeFIPY29uZnVz
aW9uTWF0cml4Il8KFk9iamVjdERldGVjdGlvbk1ldHJpY3MSRQoIcHJfY3VydmUYASABKAsy
Ki5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuUHJDdXJ2ZVIHcHJDdXJ2ZSKx
BQoHUHJDdXJ2ZRJaCg9hbm5vdGF0aW9uX3NwZWMYASABKAsyMS5nb29nbGUuY2xvdWQuZGF0
YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNwZWNSDmFubm90YXRpb25TcGVjEigKEGFy
ZWFfdW5kZXJfY3VydmUYAiABKAJSDmFyZWFVbmRlckN1cnZlEn8KGmNvbmZpZGVuY2VfbWV0
cmljc19lbnRyaWVzGAMgAygLMkEuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGEx
LlByQ3VydmUuQ29uZmlkZW5jZU1ldHJpY3NFbnRyeVIYY29uZmlkZW5jZU1ldHJpY3NFbnRy
aWVzEjQKFm1lYW5fYXZlcmFnZV9wcmVjaXNpb24YBCABKAJSFG1lYW5BdmVyYWdlUHJlY2lz
aW9uGugCChZDb25maWRlbmNlTWV0cmljc0VudHJ5EjEKFGNvbmZpZGVuY2VfdGhyZXNob2xk
GAEgASgCUhNjb25maWRlbmNlVGhyZXNob2xkEhYKBnJlY2FsbBgCIAEoAlIGcmVjYWxsEhwK
CXByZWNpc2lvbhgDIAEoAlIJcHJlY2lzaW9uEhkKCGYxX3Njb3JlGAQgASgCUgdmMVNjb3Jl
Eh0KCnJlY2FsbF9hdDEYBSABKAJSCXJlY2FsbEF0MRIjCg1wcmVjaXNpb25fYXQxGAYgASgC
UgxwcmVjaXNpb25BdDESIAoMZjFfc2NvcmVfYXQxGAcgASgCUgpmMVNjb3JlQXQxEh0KCnJl
Y2FsbF9hdDUYCCABKAJSCXJlY2FsbEF0NRIjCg1wcmVjaXNpb25fYXQ1GAkgASgCUgxwcmVj
aXNpb25BdDUSIAoMZjFfc2NvcmVfYXQ1GAogASgCUgpmMVNjb3JlQXQ1IrYDCg9Db25mdXNp
b25NYXRyaXgSSAoDcm93GAEgAygLMjYuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJl
dGExLkNvbmZ1c2lvbk1hdHJpeC5Sb3dSA3JvdxqRAQoUQ29uZnVzaW9uTWF0cml4RW50cnkS
WgoPYW5ub3RhdGlvbl9zcGVjGAEgASgLMjEuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52
MWJldGExLkFubm90YXRpb25TcGVjUg5hbm5vdGF0aW9uU3BlYxIdCgppdGVtX2NvdW50GAIg
ASgFUglpdGVtQ291bnQaxAEKA1JvdxJaCg9hbm5vdGF0aW9uX3NwZWMYASABKAsyMS5nb29n
bGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNwZWNSDmFubm90YXRp
b25TcGVjEmEKB2VudHJpZXMYAiADKAsyRy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYx
YmV0YTEuQ29uZnVzaW9uTWF0cml4LkNvbmZ1c2lvbk1hdHJpeEVudHJ5UgdlbnRyaWVzQuMB
CiVjb20uZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExUAFaSWNsb3VkLmdvb2ds
ZS5jb20vZ28vZGF0YWxhYmVsaW5nL2FwaXYxYmV0YTEvZGF0YWxhYmVsaW5ncGI7ZGF0YWxh
YmVsaW5ncGKqAiFHb29nbGUuQ2xvdWQuRGF0YUxhYmVsaW5nLlYxQmV0YTHKAiFHb29nbGVc
Q2xvdWRcRGF0YUxhYmVsaW5nXFYxYmV0YTHqAiRHb29nbGU6OkNsb3VkOjpEYXRhTGFiZWxp
bmc6OlYxYmV0YTFKpzwKBxIFDwDOAQEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoKCAoBAhIDEQAqCgkKAgMAEgMTACMKCQoCAwESAxQAPAoJCgIDAhIDFQBFCgkKAgMD
EgMWACkKCAoBCBIDGAA+CgkKAgglEgMYAD4KCAoBCBIDGQBgCgkKAggLEgMZAGAKCAoBCBID
GgAiCgkKAggKEgMaACIKCAoBCBIDGwA+CgkKAggBEgMbAD4KCAoBCBIDHAA+CgkKAggpEgMc
AD4KCAoBCBIDHQA9CgkKAggtEgMdAD0K0wEKAgQAEgQhAEYBGsYBIERlc2NyaWJlcyBhbiBl
dmFsdWF0aW9uIGJldHdlZW4gYSBtYWNoaW5lIGxlYXJuaW5nIG1vZGVsJ3MgcHJlZGljdGlv
bnMgYW5kCiBncm91bmQgdHJ1dGggbGFiZWxzLiBDcmVhdGVkIHdoZW4gYW4gW0V2YWx1YXRp
b25Kb2JdW2dvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5FdmFsdWF0aW9uSm9i
XSBydW5zIHN1Y2Nlc3NmdWxseS4KCgoKAwQAARIDIQgSCgsKAwQABxIEIgIlBAoNCgUEAAed
CBIEIgIlBArNAQoEBAACABIDKwISGr8BIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9m
IGFuIGV2YWx1YXRpb24uIFRoZSBuYW1lIGhhcyB0aGUgZm9sbG93aW5nCiBmb3JtYXQ6Cgog
InByb2plY3RzLzx2YXI+e3Byb2plY3RfaWR9PC92YXI+L2RhdGFzZXRzLzx2YXI+e2RhdGFz
ZXRfaWR9PC92YXI+L2V2YWx1YXRpb25zLzx2YXI+e2V2YWx1YXRpb25faWQ8L3Zhcj59JwoK
DAoFBAACAAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEKXQoEBAACARIDLwIe
GlAgT3V0cHV0IG9ubHkuIE9wdGlvbnMgdXNlZCBpbiB0aGUgZXZhbHVhdGlvbiBqb2IgdGhh
dCBjcmVhdGVkIHRoaXMKIGV2YWx1YXRpb24uCgoMCgUEAAIBBhIDLwISCgwKBQQAAgEBEgMv
ExkKDAoFBAACAQMSAy8cHQpkCgQEAAICEgMzAjgaVyBPdXRwdXQgb25seS4gVGltZXN0YW1w
IGZvciB3aGVuIHRoZSBldmFsdWF0aW9uIGpvYiB0aGF0IGNyZWF0ZWQgdGhpcwogZXZhbHVh
dGlvbiByYW4uCgoMCgUEAAICBhIDMwIbCgwKBQQAAgIBEgMzHDMKDAoFBAACAgMSAzM2NwpL
CgQEAAIDEgM2AiwaPiBPdXRwdXQgb25seS4gVGltZXN0YW1wIGZvciB3aGVuIHRoaXMgZXZh
bHVhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgMGEgM2AhsKDAoFBAACAwESAzYcJwoMCgUE
AAIDAxIDNiorClEKBAQAAgQSAzkCKxpEIE91dHB1dCBvbmx5LiBNZXRyaWNzIGNvbXBhcmlu
ZyBwcmVkaWN0aW9ucyB0byBncm91bmQgdHJ1dGggbGFiZWxzLgoKDAoFBAACBAYSAzkCEwoM
CgUEAAIEARIDORQmCgwKBQQAAgQDEgM5KSoKnwIKBAQAAgUSA0ACJRqRAiBPdXRwdXQgb25s
eS4gVHlwZSBvZiB0YXNrIHRoYXQgdGhlIG1vZGVsIHZlcnNpb24gYmVpbmcgZXZhbHVhdGVk
IHBlcmZvcm1zLAogYXMgZGVmaW5lZCBpbiB0aGUKCiBbZXZhbHVhdGlvbkpvYkNvbmZpZy5p
bnB1dENvbmZpZy5hbm5vdGF0aW9uVHlwZV1bZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52
MWJldGExLkV2YWx1YXRpb25Kb2JDb25maWcuaW5wdXRfY29uZmlnXQogZmllbGQgb2YgdGhl
IGV2YWx1YXRpb24gam9iIHRoYXQgY3JlYXRlZCB0aGlzIGV2YWx1YXRpb24uCgoMCgUEAAIF
BhIDQAIQCgwKBQQAAgUBEgNAESAKDAoFBAACBQMSA0AjJAq1AQoEBAACBhIDRQIhGqcBIE91
dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIGl0ZW1zIGluIHRoZSBncm91bmQgdHJ1dGggZGF0
YXNldCB0aGF0IHdlcmUgdXNlZAogZm9yIHRoaXMgZXZhbHVhdGlvbi4gT25seSBwb3B1bGF0
ZWQgd2hlbiB0aGUgZXZhdWxhdGlvbiBpcyBmb3IgY2VydGFpbgogQW5ub3RhdGlvblR5cGVz
LgoKDAoFBAACBgUSA0UCBwoMCgUEAAIGARIDRQgcCgwKBQQAAgYDEgNFHyAKmQEKAgQBEgRK
AFIBGowBIENvbmZpZ3VyYXRpb24gZGV0YWlscyB1c2VkIGZvciBjYWxjdWxhdGluZyBldmFs
dWF0aW9uIG1ldHJpY3MgYW5kIGNyZWF0aW5nIGFuCiBbRXZhbHVhdGlvbl1bZ29vZ2xlLmNs
b3VkLmRhdGFsYWJlbGluZy52MWJldGExLkV2YWx1YXRpb25dLgoKCgoDBAEBEgNKCBgKPgoE
BAEIABIETAJRAxowIFZlcnRpY2FsIHNwZWNpZmljIG9wdGlvbnMgZm9yIGdlbmVyYWwgbWV0
cmljcy4KCgwKBQQBCAABEgNMCBcKqwEKBAQBAgASA1AERRqdASBPbmx5IHNwZWNpZnkgdGhp
cyBmaWVsZCBpZiB0aGUgcmVsYXRlZCBtb2RlbCBwZXJmb3JtcyBpbWFnZSBvYmplY3QKIGRl
dGVjdGlvbiAoYElNQUdFX0JPVU5ESU5HX0JPWF9BTk5PVEFUSU9OYCkuIERlc2NyaWJlcyBo
b3cgdG8gZXZhbHVhdGUKIGJvdW5kaW5nIGJveGVzLgoKDAoFBAECAAYSA1AEIAoMCgUEAQIA
ARIDUCFACgwKBQQBAgADEgNQQ0QKQgoCBAISBFUAXQEaNiBPcHRpb25zIHJlZ2FyZGluZyBl
dmFsdWF0aW9uIGJldHdlZW4gYm91bmRpbmcgYm94ZXMuCgoKCgMEAgESA1UIJAriAQoEBAIC
ABIDXAIaGtQBIE1pbmltdW0KIFtpbnRlcnNlY3Rpb24tb3Zlci11bmlvbgoKIChJT1UpXSgv
dmlzaW9uL2F1dG9tbC9vYmplY3QtZGV0ZWN0aW9uL2RvY3MvZXZhbHVhdGUjaW50ZXJzZWN0
aW9uLW92ZXItdW5pb24pCiByZXF1aXJlZCBmb3IgMiBib3VuZGluZyBib3hlcyB0byBiZSBj
b25zaWRlcmVkIGEgbWF0Y2guIFRoaXMgbXVzdCBiZSBhCiBudW1iZXIgYmV0d2VlbiAwIGFu
ZCAxLgoKDAoFBAICAAUSA1wCBwoMCgUEAgIAARIDXAgVCgwKBQQCAgADEgNcGBkKCgoCBAMS
BF8AZgEKCgoDBAMBEgNfCBkKOwoEBAMIABIEYQJlAxotIENvbW1vbiBtZXRyaWNzIGNvdmVy
aW5nIG1vc3QgZ2VuZXJhbCBjYXNlcy4KCgwKBQQDCAABEgNhCA8KCwoEBAMCABIDYgQ1CgwK
BQQDAgAGEgNiBBkKDAoFBAMCAAESA2IaMAoMCgUEAwIAAxIDYjM0CgsKBAQDAgESA2QEOAoM
CgUEAwIBBhIDZAQaCgwKBQQDAgEBEgNkGzMKDAoFBAMCAQMSA2Q2Nwo8CgIEBBIEaQBwARow
IE1ldHJpY3MgY2FsY3VsYXRlZCBmb3IgYSBjbGFzc2lmaWNhdGlvbiBtb2RlbC4KCgoKAwQE
ARIDaQgdCnsKBAQEAgASA2wCFxpuIFByZWNpc2lvbi1yZWNhbGwgY3VydmUgYmFzZWQgb24g
Z3JvdW5kIHRydXRoIGxhYmVscywgcHJlZGljdGVkIGxhYmVscywgYW5kCiBzY29yZXMgZm9y
IHRoZSBwcmVkaWN0ZWQgbGFiZWxzLgoKDAoFBAQCAAYSA2wCCQoMCgUEBAIAARIDbAoSCgwK
BQQEAgADEgNsFRYKTAoEBAQCARIDbwInGj8gQ29uZnVzaW9uIG1hdHJpeCBvZiBwcmVkaWN0
ZWQgbGFiZWxzIHZzLiBncm91bmQgdHJ1dGggbGFiZWxzLgoKDAoFBAQCAQYSA28CEQoMCgUE
BAIBARIDbxIiCgwKBQQEAgEDEgNvJSYKVAoCBAUSBHMAdgEaSCBNZXRyaWNzIGNhbGN1bGF0
ZWQgZm9yIGFuIGltYWdlIG9iamVjdCBkZXRlY3Rpb24gKGJvdW5kaW5nIGJveCkgbW9kZWwu
CgoKCgMEBQESA3MIHgomCgQEBQIAEgN1AhcaGSBQcmVjaXNpb24tcmVjYWxsIGN1cnZlLgoK
DAoFBAUCAAYSA3UCCQoMCgUEBQIAARIDdQoSCgwKBQQFAgADEgN1FRYKCwoCBAYSBXgAswEB
CgoKAwQGARIDeAgPCg0KBAQGAwASBXkCogEDCgwKBQQGAwABEgN5CiAK+AMKBgQGAwACABIE
hgEEIxrnAyBUaHJlc2hvbGQgdXNlZCBmb3IgdGhpcyBlbnRyeS4KCiBGb3IgY2xhc3NpZmlj
YXRpb24gdGFza3MsIHRoaXMgaXMgYSBjbGFzc2lmaWNhdGlvbiB0aHJlc2hvbGQ6IGEKIHBy
ZWRpY3RlZCBsYWJlbCBpcyBjYXRlZ29yaXplZCBhcyBwb3NpdGl2ZSBvciBuZWdhdGl2ZSAo
aW4gdGhlIGNvbnRleHQgb2YKIHRoaXMgcG9pbnQgb24gdGhlIFBSIGN1cnZlKSBiYXNlZCBv
biB3aGV0aGVyIHRoZSBsYWJlbCdzIHNjb3JlIG1lZXRzIHRoaXMKIHRocmVzaG9sZC4KCiBG
b3IgaW1hZ2Ugb2JqZWN0IGRldGVjdGlvbiAoYm91bmRpbmcgYm94KSB0YXNrcywgdGhpcyBp
cyB0aGUKIFtpbnRlcnNlY3Rpb24tb3Zlci11bmlvbgoKIChJT1UpXSgvdmlzaW9uL2F1dG9t
bC9vYmplY3QtZGV0ZWN0aW9uL2RvY3MvZXZhbHVhdGUjaW50ZXJzZWN0aW9uLW92ZXItdW5p
b24pCiB0aHJlc2hvbGQgZm9yIHRoZSBjb250ZXh0IG9mIHRoaXMgcG9pbnQgb24gdGhlIFBS
IGN1cnZlLgoKDwoHBAYDAAIABRIEhgEECQoPCgcEBgMAAgABEgSGAQoeCg8KBwQGAwACAAMS
BIYBISIKHwoGBAYDAAIBEgSJAQQVGg8gUmVjYWxsIHZhbHVlLgoKDwoHBAYDAAIBBRIEiQEE
CQoPCgcEBgMAAgEBEgSJAQoQCg8KBwQGAwACAQMSBIkBExQKIgoGBAYDAAICEgSMAQQYGhIg
UHJlY2lzaW9uIHZhbHVlLgoKDwoHBAYDAAICBRIEjAEECQoPCgcEBgMAAgIBEgSMAQoTCg8K
BwQGAwACAgMSBIwBFhcKOAoGBAYDAAIDEgSPAQQXGiggSGFybW9uaWMgbWVhbiBvZiByZWNh
bGwgYW5kIHByZWNpc2lvbi4KCg8KBwQGAwACAwUSBI8BBAkKDwoHBAYDAAIDARIEjwEKEgoP
CgcEBgMAAgMDEgSPARUWCk0KBgQGAwACBBIEkgEEGRo9IFJlY2FsbCB2YWx1ZSBmb3IgZW50
cmllcyB3aXRoIGxhYmVsIHRoYXQgaGFzIGhpZ2hlc3Qgc2NvcmUuCgoPCgcEBgMAAgQFEgSS
AQQJCg8KBwQGAwACBAESBJIBChQKDwoHBAYDAAIEAxIEkgEXGApQCgYEBgMAAgUSBJUBBBwa
QCBQcmVjaXNpb24gdmFsdWUgZm9yIGVudHJpZXMgd2l0aCBsYWJlbCB0aGF0IGhhcyBoaWdo
ZXN0IHNjb3JlLgoKDwoHBAYDAAIFBRIElQEECQoPCgcEBgMAAgUBEgSVAQoXCg8KBwQGAwAC
BQMSBJUBGhsK5gEKBgQGAwACBhIEmAEEGxrVASBUaGUgaGFybW9uaWMgbWVhbiBvZiBbcmVj
YWxsX2F0MV1bZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLlByQ3VydmUuQ29u
ZmlkZW5jZU1ldHJpY3NFbnRyeS5yZWNhbGxfYXQxXSBhbmQgW3ByZWNpc2lvbl9hdDFdW2dv
b2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5QckN1cnZlLkNvbmZpZGVuY2VNZXRy
aWNzRW50cnkucHJlY2lzaW9uX2F0MV0uCgoPCgcEBgMAAgYFEgSYAQQJCg8KBwQGAwACBgES
BJgBChYKDwoHBAYDAAIGAxIEmAEZGgpQCgYEBgMAAgcSBJsBBBkaQCBSZWNhbGwgdmFsdWUg
Zm9yIGVudHJpZXMgd2l0aCBsYWJlbCB0aGF0IGhhcyBoaWdoZXN0IDUgc2NvcmVzLgoKDwoH
BAYDAAIHBRIEmwEECQoPCgcEBgMAAgcBEgSbAQoUCg8KBwQGAwACBwMSBJsBFxgKUwoGBAYD
AAIIEgSeAQQcGkMgUHJlY2lzaW9uIHZhbHVlIGZvciBlbnRyaWVzIHdpdGggbGFiZWwgdGhh
dCBoYXMgaGlnaGVzdCA1IHNjb3Jlcy4KCg8KBwQGAwACCAUSBJ4BBAkKDwoHBAYDAAIIARIE
ngEKFwoPCgcEBgMAAggDEgSeARobCuYBCgYEBgMAAgkSBKEBBBwa1QEgVGhlIGhhcm1vbmlj
IG1lYW4gb2YgW3JlY2FsbF9hdDVdW2dvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRh
MS5QckN1cnZlLkNvbmZpZGVuY2VNZXRyaWNzRW50cnkucmVjYWxsX2F0NV0gYW5kIFtwcmVj
aXNpb25fYXQ1XVtnb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuUHJDdXJ2ZS5D
b25maWRlbmNlTWV0cmljc0VudHJ5LnByZWNpc2lvbl9hdDVdLgoKDwoHBAYDAAIJBRIEoQEE
CQoPCgcEBgMAAgkBEgShAQoWCg8KBwQGAwACCQMSBKEBGRsKyAEKBAQGAgASBKcBAiUauQEg
VGhlIGFubm90YXRpb24gc3BlYyBvZiB0aGUgbGFiZWwgZm9yIHdoaWNoIHRoZSBwcmVjaXNp
b24tcmVjYWxsIGN1cnZlCiBjYWxjdWxhdGVkLiBJZiB0aGlzIGZpZWxkIGlzIGVtcHR5LCB0
aGF0IG1lYW5zIHRoZSBwcmVjaXNpb24tcmVjYWxsIGN1cnZlCiBpcyBhbiBhZ2dyZWdhdGUg
Y3VydmUgZm9yIGFsbCBsYWJlbHMuCgoNCgUEBgIABhIEpwECEAoNCgUEBgIAARIEpwERIAoN
CgUEBgIAAxIEpwEjJAqLAQoEBAYCARIEqwECHRp9IEFyZWEgdW5kZXIgdGhlIHByZWNpc2lv
bi1yZWNhbGwgY3VydmUuIE5vdCB0byBiZSBjb25mdXNlZCB3aXRoIGFyZWEgdW5kZXIKIGEg
cmVjZWl2ZXIgb3BlcmF0aW5nIGNoYXJhY3RlcmlzdGljIChST0MpIGN1cnZlLgoKDQoFBAYC
AQUSBKsBAgcKDQoFBAYCAQESBKsBCBgKDQoFBAYCAQMSBKsBGxwKlQEKBAQGAgISBK8BAkEa
hgEgRW50cmllcyB0aGF0IG1ha2UgdXAgdGhlIHByZWNpc2lvbi1yZWNhbGwgZ3JhcGguIEVh
Y2ggZW50cnkgaXMgYSAicG9pbnQiIG9uCiB0aGUgZ3JhcGggZHJhd24gZm9yIGEgZGlmZmVy
ZW50IGBjb25maWRlbmNlX3RocmVzaG9sZGAuCgoNCgUEBgICBBIErwECCgoNCgUEBgICBhIE
rwELIQoNCgUEBgICARIErwEiPAoNCgUEBgICAxIErwE/QAo0CgQEBgIDEgSyAQIjGiYgTWVh
biBhdmVyYWdlIHByY2lzaW9uIG9mIHRoaXMgY3VydmUuCgoNCgUEBgIDBRIEsgECBwoNCgUE
BgIDARIEsgEIHgoNCgUEBgIDAxIEsgEhIgrEAQoCBAcSBrgBAM4BARq1ASBDb25mdXNpb24g
bWF0cml4IG9mIHRoZSBtb2RlbCBydW5uaW5nIHRoZSBjbGFzc2lmaWNhdGlvbi4gT25seSBh
cHBsaWNhYmxlCiB3aGVuIHRoZSBtZXRyaWNzIGVudHJ5IGFnZ3JlZ2F0ZXMgbXVsdGlwbGUg
bGFiZWxzLiBOb3QgYXBwbGljYWJsZSB3aGVuIHRoZQogZW50cnkgaXMgZm9yIGEgc2luZ2xl
IGxhYmVsLgoKCwoDBAcBEgS4AQgXCg4KBAQHAwASBrkBAsABAwoNCgUEBwMAARIEuQEKHgo7
CgYEBwMAAgASBLsBBCcaKyBUaGUgYW5ub3RhdGlvbiBzcGVjIG9mIGEgcHJlZGljdGVkIGxh
YmVsLgoKDwoHBAcDAAIABhIEuwEEEgoPCgcEBwMAAgABEgS7ARMiCg8KBwQHAwACAAMSBLsB
JSYKngEKBgQHAwACARIEvwEEGRqNASBOdW1iZXIgb2YgaXRlbXMgcHJlZGljdGVkIHRvIGhh
dmUgdGhpcyBsYWJlbC4gKFRoZSBncm91bmQgdHJ1dGggbGFiZWwgZm9yCiB0aGVzZSBpdGVt
cyBpcyB0aGUgYFJvdy5hbm5vdGF0aW9uU3BlY2Agb2YgdGhpcyBlbnRyeSdzIHBhcmVudC4p
CgoPCgcEBwMAAgEFEgS/AQQJCg8KBwQHAwACAQESBL8BChQKDwoHBAcDAAIBAxIEvwEXGApp
CgQEBwMBEgbEAQLLAQMaWSBBIHJvdyBpbiB0aGUgY29uZnVzaW9uIG1hdHJpeC4gRWFjaCBl
bnRyeSBpbiB0aGlzIHJvdyBoYXMgdGhlIHNhbWUKIGdyb3VuZCB0cnV0aCBsYWJlbC4KCg0K
BQQHAwEBEgTEAQoNCk0KBgQHAwECABIExgEEJxo9IFRoZSBhbm5vdGF0aW9uIHNwZWMgb2Yg
dGhlIGdyb3VuZCB0cnV0aCBsYWJlbCBmb3IgdGhpcyByb3cuCgoPCgcEBwMBAgAGEgTGAQQS
Cg8KBwQHAwECAAESBMYBEyIKDwoHBAcDAQIAAxIExgElJgpnCgYEBwMBAgESBMoBBC4aVyBB
IGxpc3Qgb2YgdGhlIGNvbmZ1c2lvbiBtYXRyaXggZW50cmllcy4gT25lIGVudHJ5IGZvciBl
YWNoIHBvc3NpYmxlCiBwcmVkaWN0ZWQgbGFiZWwuCgoPCgcEBwMBAgEEEgTKAQQMCg8KBwQH
AwECAQYSBMoBDSEKDwoHBAcDAQIBARIEygEiKQoPCgcEBwMBAgEDEgTKASwtCgwKBAQHAgAS
BM0BAhcKDQoFBAcCAAQSBM0BAgoKDQoFBAcCAAYSBM0BCw4KDQoFBAcCAAESBM0BDxIKDQoF
BAcCAAMSBM0BFRZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation ===
    # Fields for Evaluation
    # Field: name Type: 9 ()
    # Field: config Type: 11 (.google.cloud.datalabeling.v1beta1.EvaluationConfig)
    # Field: evaluation_job_run_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: evaluation_metrics Type: 11 (.google.cloud.datalabeling.v1beta1.EvaluationMetrics)
    # Field: annotation_type Type: 14 (.google.cloud.datalabeling.v1beta1.AnnotationType)
    # Field: evaluated_item_count Type: 3 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig ===
    # Fields for EvaluationConfig
    # Field: bounding_box_evaluation_options Type: 11 (.google.cloud.datalabeling.v1beta1.BoundingBoxEvaluationOptions)

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::BoundingBoxEvaluationOptions ===
    # Fields for BoundingBoxEvaluationOptions
    # Field: iou_threshold Type: 2 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationMetrics ===
    # Fields for EvaluationMetrics
    # Field: classification_metrics Type: 11 (.google.cloud.datalabeling.v1beta1.ClassificationMetrics)
    # Field: object_detection_metrics Type: 11 (.google.cloud.datalabeling.v1beta1.ObjectDetectionMetrics)

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::ClassificationMetrics ===
    # Fields for ClassificationMetrics
    # Field: pr_curve Type: 11 (.google.cloud.datalabeling.v1beta1.PrCurve)
    # Field: confusion_matrix Type: 11 (.google.cloud.datalabeling.v1beta1.ConfusionMatrix)

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::ObjectDetectionMetrics ===
    # Fields for ObjectDetectionMetrics
    # Field: pr_curve Type: 11 (.google.cloud.datalabeling.v1beta1.PrCurve)

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve ===
    # Fields for PrCurve
    # Field: annotation_spec Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotationSpec)
    # Field: area_under_curve Type: 2 ()
    # Field: confidence_metrics_entries Type: 11 (.google.cloud.datalabeling.v1beta1.PrCurve.ConfidenceMetricsEntry)
    # Field: mean_average_precision Type: 2 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix ===
    # Fields for ConfusionMatrix
    # Field: row Type: 11 (.google.cloud.datalabeling.v1beta1.ConfusionMatrix.Row)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Evaluation - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/evaluation.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::Evaluation;

    my $msg = Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation->new({
        name => $name,
        config => $config,
        evaluation_job_run_time => $evaluation_job_run_time,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/evaluation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation

Describes an evaluation between a machine learning model's predictions and
ground truth labels. Created when an [EvaluationJob][google.cloud.datalabeling.v1beta1.EvaluationJob] runs successfully.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of an evaluation. The name has the following
format:

"projects/<var>{project_id}</var>/datasets/<var>{dataset_id}</var>/evaluations/<var>{evaluation_id</var>}'

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig>)

Output only. Options used in the evaluation job that created this
evaluation.

=item * C<< $msg->evaluation_job_run_time() >> / C<< $msg->evaluation_job_run_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp for when the evaluation job that created this
evaluation ran.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp for when this evaluation was created.

=item * C<< $msg->evaluation_metrics() >> / C<< $msg->evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationMetrics>)

Output only. Metrics comparing predictions to ground truth labels.

=item * C<< $msg->annotation_type() >> / C<< $msg->annotation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationType>)

Output only. Type of task that the model version being evaluated performs,
as defined in the

[evaluationJobConfig.inputConfig.annotationType][google.cloud.datalabeling.v1beta1.EvaluationJobConfig.input_config]
field of the evaluation job that created this evaluation.

=item * C<< $msg->evaluated_item_count() >> / C<< $msg->evaluated_item_count($value) >>

Type: C<Int64>

Output only. The number of items in the ground truth dataset that were used
for this evaluation. Only populated when the evaulation is for certain
AnnotationTypes.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig

Configuration details used for calculating evaluation metrics and creating an
[Evaluation][google.cloud.datalabeling.v1beta1.Evaluation].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_box_evaluation_options() >> / C<< $msg->bounding_box_evaluation_options($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::BoundingBoxEvaluationOptions>)

Only specify this field if the related model performs image object
detection (`IMAGE_BOUNDING_BOX_ANNOTATION`). Describes how to evaluate
bounding boxes.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::BoundingBoxEvaluationOptions

Options regarding evaluation between bounding boxes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->iou_threshold() >> / C<< $msg->iou_threshold($value) >>

Type: C<Float>

Minimum
[intersection-over-union

(IOU)](/vision/automl/object-detection/docs/evaluate#intersection-over-union)
required for 2 bounding boxes to be considered a match. This must be a
number between 0 and 1.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationMetrics

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_metrics() >> / C<< $msg->classification_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::ClassificationMetrics>)

=item * C<< $msg->object_detection_metrics() >> / C<< $msg->object_detection_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::ObjectDetectionMetrics>)

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::ClassificationMetrics

Metrics calculated for a classification model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pr_curve() >> / C<< $msg->pr_curve($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve>)

Precision-recall curve based on ground truth labels, predicted labels, and
scores for the predicted labels.

=item * C<< $msg->confusion_matrix() >> / C<< $msg->confusion_matrix($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix>)

Confusion matrix of predicted labels vs. ground truth labels.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::ObjectDetectionMetrics

Metrics calculated for an image object detection (bounding box) model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pr_curve() >> / C<< $msg->pr_curve($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve>)

Precision-recall curve.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->annotation_spec() >> / C<< $msg->annotation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec>)

The annotation spec of the label for which the precision-recall curve
calculated. If this field is empty, that means the precision-recall curve
is an aggregate curve for all labels.

=item * C<< $msg->area_under_curve() >> / C<< $msg->area_under_curve($value) >>

Type: C<Float>

Area under the precision-recall curve. Not to be confused with area under
a receiver operating characteristic (ROC) curve.

=item * C<< $msg->confidence_metrics_entries() >> / C<< $msg->confidence_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve::ConfidenceMetricsEntry>)

Entries that make up the precision-recall graph. Each entry is a "point" on
the graph drawn for a different `confidence_threshold`.

=item * C<< $msg->mean_average_precision() >> / C<< $msg->mean_average_precision($value) >>

Type: C<Float>

Mean average prcision of this curve.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix

Confusion matrix of the model running the classification. Only applicable
when the metrics entry aggregates multiple labels. Not applicable when the
entry is for a single label.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->row() >> / C<< $msg->row($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::Row>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::Evaluation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
