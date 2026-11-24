package Google::Cloud::Discoveryengine::V1alpha::RecommendationService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Document };
    eval { require Google::Cloud::Discoveryengine::V1alpha::UserEvent };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvcmVjb21tZW5kYXRpb25f
c2VydmljZS5wcm90bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxozZ29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL2RvY3VtZW50LnBy
b3RvGjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvdXNlcl9ldmVudC5w
cm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byL1BAoQUmVjb21tZW5kUmVxdWVz
dBJbCg5zZXJ2aW5nX2NvbmZpZxgBIAEoCUI04EEC+kEuCixkaXNjb3ZlcnllbmdpbmUuZ29v
Z2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZ1INc2VydmluZ0NvbmZpZxJTCgp1c2VyX2V2ZW50
GAIgASgLMi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlVzZXJFdmVu
dEID4EECUgl1c2VyRXZlbnQSGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRIWCgZmaWx0
ZXIYBCABKAlSBmZpbHRlchIjCg12YWxpZGF0ZV9vbmx5GAUgASgIUgx2YWxpZGF0ZU9ubHkS
WgoGcGFyYW1zGAYgAygLMkIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlJlY29tbWVuZFJlcXVlc3QuUGFyYW1zRW50cnlSBnBhcmFtcxJnCgt1c2VyX2xhYmVscxgI
IAMoCzJGLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SZWNvbW1lbmRS
ZXF1ZXN0LlVzZXJMYWJlbHNFbnRyeVIKdXNlckxhYmVscxpRCgtQYXJhbXNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIsCgV2YWx1ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIF
dmFsdWU6AjgBGj0KD1VzZXJMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1
ZRgCIAEoCVIFdmFsdWU6AjgBIrAEChFSZWNvbW1lbmRSZXNwb25zZRJmCgdyZXN1bHRzGAEg
AygLMkwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlJlY29tbWVuZFJl
c3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0UgdyZXN1bHRzEisKEWF0dHJpYnV0aW9uX3Rv
a2VuGAIgASgJUhBhdHRyaWJ1dGlvblRva2VuEh8KC21pc3NpbmdfaWRzGAMgAygJUgptaXNz
aW5nSWRzEiMKDXZhbGlkYXRlX29ubHkYBCABKAhSDHZhbGlkYXRlT25seRq/AgoUUmVjb21t
ZW5kYXRpb25SZXN1bHQSDgoCaWQYASABKAlSAmlkEkoKCGRvY3VtZW50GAIgASgLMi4uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50Ughkb2N1bWVudBJ2
CghtZXRhZGF0YRgDIAMoCzJaLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5SZWNvbW1lbmRSZXNwb25zZS5SZWNvbW1lbmRhdGlvblJlc3VsdC5NZXRhZGF0YUVudHJ5
UghtZXRhZGF0YRpTCg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EiwKBXZhbHVl
GAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZToCOAEyqAQKFVJlY29tbWVu
ZGF0aW9uU2VydmljZRK6AwoJUmVjb21tZW5kEjYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlJlY29tbWVuZFJlcXVlc3QaNy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuUmVjb21tZW5kUmVzcG9uc2UiuwKC0+STArQCIlgvdjFhbHBoYS97
c2VydmluZ19jb25maWc9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovc2Vy
dmluZ0NvbmZpZ3MvKn06cmVjb21tZW5kOgEqWmsiZi92MWFscGhhL3tzZXJ2aW5nX2NvbmZp
Zz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL3Nl
cnZpbmdDb25maWdzLyp9OnJlY29tbWVuZDoBKlpoImMvdjFhbHBoYS97c2VydmluZ19jb25m
aWc9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXJ2
aW5nQ29uZmlncy8qfTpyZWNvbW1lbmQ6ASoaUspBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZv
cm1CpgIKKGNvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCGlJlY29t
bWVuZGF0aW9uU2VydmljZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5
ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKi
Ag9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxw
aGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNs
b3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFKkkUKBxIFDgDlAQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA9CgkKAgMFEgMXAD8KCQoCAwYSAxgA
JgoICgEIEgMaAEEKCQoCCCUSAxoAQQoICgEIEgMbAGkKCQoCCAsSAxsAaQoICgEIEgMcACIK
CQoCCAoSAxwAIgoICgEIEgMdADsKCQoCCAgSAx0AOwoICgEIEgMeAEEKCQoCCAESAx4AQQoI
CgEIEgMfAC0KCQoCCCQSAx8ALQoICgEIEgMgAEEKCQoCCCkSAyAAQQoICgEIEgMhAEAKCQoC
CC0SAyEAQAoxCgIGABIEJAA4ARolIFNlcnZpY2UgZm9yIG1ha2luZyByZWNvbW1lbmRhdGlv
bnMuCgoKCgMGAAESAyQIHQoKCgMGAAMSAyUCRgoMCgUGAAOZCBIDJQJGCgsKAwYAAxIEJgIn
NwoNCgUGAAOaCBIEJgInNwpPCgQGAAIAEgQqAjcDGkEgTWFrZXMgYSByZWNvbW1lbmRhdGlv
biwgd2hpY2ggcmVxdWlyZXMgYSBjb250ZXh0dWFsIHVzZXIgZXZlbnQuCgoMCgUGAAIAARID
KgYPCgwKBQYAAgACEgMqECAKDAoFBgACAAMSAyorPAoNCgUGAAIABBIEKwQ2BgoRCgkGAAIA
BLDKvCISBCsENgYKNAoCBAASBTsAuwEBGicgUmVxdWVzdCBtZXNzYWdlIGZvciBSZWNvbW1l
bmQgbWV0aG9kLgoKCgoDBAABEgM7CBgK4gUKBAQAAgASBEkCTgQa0wUgUmVxdWlyZWQuIEZ1
bGwgcmVzb3VyY2UgbmFtZSBvZiBhCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlNlcnZpbmdDb25maWddOgogYHByb2plY3RzLyovbG9j
YXRpb25zL2dsb2JhbC9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXJ2aW5nQ29uZmlncy8q
YCwgb3IKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyovc2VydmluZ0NvbmZpZ3MvKmAKCiBPbmUgZGVmYXVsdCBzZXJ2aW5nIGNvbmZp
ZyBpcyBjcmVhdGVkIGFsb25nIHdpdGggeW91ciByZWNvbW1lbmRhdGlvbiBlbmdpbmUKIGNy
ZWF0aW9uLiBUaGUgZW5naW5lIElEIGlzIHVzZWQgYXMgdGhlIElEIG9mIHRoZSBkZWZhdWx0
IHNlcnZpbmcKIGNvbmZpZy4gRm9yIGV4YW1wbGUsIGZvciBFbmdpbmUKIGBwcm9qZWN0cy8q
L2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvKi9lbmdpbmVzL215LWVuZ2luZWAsIHlv
dSBjYW4gdXNlCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2NvbGxlY3Rpb25zLyov
ZW5naW5lcy9teS1lbmdpbmUvc2VydmluZ0NvbmZpZ3MvbXktZW5naW5lYAogZm9yIHlvdXIK
IFtSZWNvbW1lbmRhdGlvblNlcnZpY2UuUmVjb21tZW5kXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuUmVjb21tZW5kYXRpb25TZXJ2aWNlLlJlY29tbWVuZF0KIHJl
cXVlc3RzLgoKDAoFBAACAAUSA0kCCAoMCgUEAAIAARIDSQkXCgwKBQQAAgADEgNJGhsKDQoF
BAACAAgSBEkcTgMKDwoIBAACAAicCAASA0oEKgoPCgcEAAIACJ8IEgRLBE0FCuoGCgQEAAIB
EgNgAkQa3AYgUmVxdWlyZWQuIENvbnRleHQgYWJvdXQgdGhlIHVzZXIsIHdoYXQgdGhleSBh
cmUgbG9va2luZyBhdCBhbmQgd2hhdCBhY3Rpb24KIHRoZXkgdG9vayB0byB0cmlnZ2VyIHRo
ZSBSZWNvbW1lbmQgcmVxdWVzdC4gTm90ZSB0aGF0IHRoaXMgdXNlciBldmVudAogZGV0YWls
IHdvbid0IGJlIGluZ2VzdGVkIHRvIHVzZXJFdmVudCBsb2dzLiBUaHVzLCBhIHNlcGFyYXRl
IHVzZXJFdmVudAogd3JpdGUgcmVxdWVzdCBpcyByZXF1aXJlZCBmb3IgZXZlbnQgbG9nZ2lu
Zy4KCiBEb24ndCBzZXQKIFtVc2VyRXZlbnQudXNlcl9wc2V1ZG9faWRdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Vc2VyRXZlbnQudXNlcl9wc2V1ZG9faWRdCiBv
cgogW1VzZXJFdmVudC51c2VyX2luZm8udXNlcl9pZF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlVzZXJJbmZvLnVzZXJfaWRdCiB0byB0aGUgc2FtZSBmaXhlZCBJ
RCBmb3IgZGlmZmVyZW50IHVzZXJzLiBJZiB5b3UgYXJlIHRyeWluZyB0byByZWNlaXZlCiBu
b24tcGVyc29uYWxpemVkIHJlY29tbWVuZGF0aW9ucyAobm90IHJlY29tbWVuZGVkOyB0aGlz
IGNhbiBuZWdhdGl2ZWx5CiBpbXBhY3QgbW9kZWwgcGVyZm9ybWFuY2UpLCBpbnN0ZWFkIHNl
dAogW1VzZXJFdmVudC51c2VyX3BzZXVkb19pZF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlVzZXJFdmVudC51c2VyX3BzZXVkb19pZF0KIHRvIGEgcmFuZG9tIHVu
aXF1ZSBJRCBhbmQgbGVhdmUKIFtVc2VyRXZlbnQudXNlcl9pbmZvLnVzZXJfaWRdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Vc2VySW5mby51c2VyX2lkXQogdW5z
ZXQuCgoMCgUEAAIBBhIDYAILCgwKBQQAAgEBEgNgDBYKDAoFBAACAQMSA2AZGgoMCgUEAAIB
CBIDYBtDCg8KCAQAAgEInAgAEgNgHEIK7wEKBAQAAgISA2YCFhrhASBNYXhpbXVtIG51bWJl
ciBvZiByZXN1bHRzIHRvIHJldHVybi4gU2V0IHRoaXMgcHJvcGVydHkKIHRvIHRoZSBudW1i
ZXIgb2YgcmVjb21tZW5kYXRpb24gcmVzdWx0cyBuZWVkZWQuIElmIHplcm8sIHRoZSBzZXJ2
aWNlCiBjaG9vc2VzIGEgcmVhc29uYWJsZSBkZWZhdWx0LiBUaGUgbWF4aW11bSBhbGxvd2Vk
IHZhbHVlIGlzIDEwMC4gVmFsdWVzCiBhYm92ZSAxMDAgYXJlIHNldCB0byAxMDAuCgoMCgUE
AAICBRIDZgIHCgwKBQQAAgIBEgNmCBEKDAoFBAACAgMSA2YUFQqSCQoEBAACAxIEgwECFBqD
CSBGaWx0ZXIgZm9yIHJlc3RyaWN0aW5nIHJlY29tbWVuZGF0aW9uIHJlc3VsdHMgd2l0aCBh
IGxlbmd0aCBsaW1pdCBvZiA1LDAwMAogY2hhcmFjdGVycy4gQ3VycmVudGx5LCBvbmx5IGZp
bHRlciBleHByZXNzaW9ucyBvbiB0aGUgYGZpbHRlcl90YWdzYAogYXR0cmlidXRlIGlzIHN1
cHBvcnRlZC4KCgogRXhhbXBsZXM6CgogICogYChmaWx0ZXJfdGFnczogQU5ZKCJSZWQiLCAi
Qmx1ZSIpIE9SIGZpbHRlcl90YWdzOiBBTlkoIkhvdCIsICJDb2xkIikpYAogICogYChmaWx0
ZXJfdGFnczogQU5ZKCJSZWQiLCAiQmx1ZSIpKSBBTkQgTk9UIChmaWx0ZXJfdGFnczogQU5Z
KCJHcmVlbiIpKWAKCiBJZiBgYXR0cmlidXRlRmlsdGVyaW5nU3ludGF4YCBpcyBzZXQgdG8g
dHJ1ZSB1bmRlciB0aGUgYHBhcmFtc2AgZmllbGQsIHRoZW4KIGF0dHJpYnV0ZS1iYXNlZCBl
eHByZXNzaW9ucyBhcmUgZXhwZWN0ZWQgaW5zdGVhZCBvZiB0aGUgYWJvdmUgZGVzY3JpYmVk
CiB0YWctYmFzZWQgc3ludGF4LiBFeGFtcGxlczoKCiAgKiAobGF1bmd1YWdlOiBBTlkoImVu
IiwgImVzIikpIEFORCBOT1QgKGNhdGVnb3JpZXM6IEFOWSgiTW92aWUiKSkKICAqIChhdmFp
bGFibGU6IHRydWUpIEFORAogICAgKGxhdW5ndWFnZTogQU5ZKCJlbiIsICJlcyIpKSBPUiAo
Y2F0ZWdvcmllczogQU5ZKCJNb3ZpZSIpKQoKIElmIHlvdXIgZmlsdGVyIGJsb2NrcyBhbGwg
cmVzdWx0cywgdGhlIEFQSSByZXR1cm5zIGdlbmVyaWMKICh1bmZpbHRlcmVkKSBwb3B1bGFy
IERvY3VtZW50cy4gSWYgeW91IG9ubHkgd2FudCByZXN1bHRzIHN0cmljdGx5IG1hdGNoaW5n
CiB0aGUgZmlsdGVycywgc2V0IGBzdHJpY3RGaWx0ZXJpbmdgIHRvIGB0cnVlYCBpbgogW1Jl
Y29tbWVuZFJlcXVlc3QucGFyYW1zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuUmVjb21tZW5kUmVxdWVzdC5wYXJhbXNdCiB0byByZWNlaXZlIGVtcHR5IHJlc3Vs
dHMgaW5zdGVhZC4KCiBOb3RlIHRoYXQgdGhlIEFQSSBuZXZlciByZXR1cm5zCiBbRG9jdW1l
bnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Eb2N1bWVudF1zIHdp
dGgKIGBzdG9yYWdlU3RhdHVzYCBhcyBgRVhQSVJFRGAgb3IgYERFTEVURURgIHJlZ2FyZGxl
c3Mgb2YgZmlsdGVyIGNob2ljZXMuCgoNCgUEAAIDBRIEgwECCAoNCgUEAAIDARIEgwEJDwoN
CgUEAAIDAxIEgwESEwr9AQoEBAACBBIEiQECGRruASBVc2UgdmFsaWRhdGUgb25seSBtb2Rl
IGZvciB0aGlzIHJlY29tbWVuZGF0aW9uIHF1ZXJ5LiBJZiBzZXQgdG8gYHRydWVgLCBhCiBm
YWtlIG1vZGVsIGlzIHVzZWQgdGhhdCByZXR1cm5zIGFyYml0cmFyeSBEb2N1bWVudCBJRHMu
CiBOb3RlIHRoYXQgdGhlIHZhbGlkYXRlIG9ubHkgbW9kZSBzaG91bGQgb25seSBiZSB1c2Vk
IGZvciB0ZXN0aW5nIHRoZSBBUEksCiBvciBpZiB0aGUgbW9kZWwgaXMgbm90IHJlYWR5LgoK
DQoFBAACBAUSBIkBAgYKDQoFBAACBAESBIkBBxQKDQoFBAACBAMSBIkBFxgK/QoKBAQAAgUS
BKcBAjAa7gogQWRkaXRpb25hbCBkb21haW4gc3BlY2lmaWMgcGFyYW1ldGVycyBmb3IgdGhl
IHJlY29tbWVuZGF0aW9ucy4KCiBBbGxvd2VkIHZhbHVlczoKCiAqIGByZXR1cm5Eb2N1bWVu
dGA6IEJvb2xlYW4uIElmIHNldCB0byBgdHJ1ZWAsIHRoZSBhc3NvY2lhdGVkIERvY3VtZW50
CiAgICBvYmplY3QgaXMgcmV0dXJuZWQgaW4KICAgIFtSZWNvbW1lbmRSZXNwb25zZS5SZWNv
bW1lbmRhdGlvblJlc3VsdC5kb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLlJlY29tbWVuZFJlc3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0LmRvY3Vt
ZW50XS4KICogYHJldHVyblNjb3JlYDogQm9vbGVhbi4gSWYgc2V0IHRvIHRydWUsIHRoZSBy
ZWNvbW1lbmRhdGlvbiBzY29yZQogICAgY29ycmVzcG9uZGluZyB0byBlYWNoIHJldHVybmVk
IERvY3VtZW50IGlzIHNldCBpbgogICAgW1JlY29tbWVuZFJlc3BvbnNlLlJlY29tbWVuZGF0
aW9uUmVzdWx0Lm1ldGFkYXRhXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuUmVjb21tZW5kUmVzcG9uc2UuUmVjb21tZW5kYXRpb25SZXN1bHQubWV0YWRhdGFdLgog
ICAgVGhlIGdpdmVuIHNjb3JlIGluZGljYXRlcyB0aGUgcHJvYmFiaWxpdHkgb2YgYSBEb2N1
bWVudCBjb252ZXJzaW9uIGdpdmVuCiAgICB0aGUgdXNlcidzIGNvbnRleHQgYW5kIGhpc3Rv
cnkuCiAqIGBzdHJpY3RGaWx0ZXJpbmdgOiBCb29sZWFuLiBUcnVlIGJ5IGRlZmF1bHQuIElm
IHNldCB0byBgZmFsc2VgLCB0aGUKIHNlcnZpY2UKICAgIHJldHVybnMgZ2VuZXJpYyAodW5m
aWx0ZXJlZCkgcG9wdWxhciBEb2N1bWVudHMgaW5zdGVhZCBvZiBlbXB0eSBpZgogICAgeW91
ciBmaWx0ZXIgYmxvY2tzIGFsbCByZWNvbW1lbmRhdGlvbiByZXN1bHRzLgogKiBgZGl2ZXJz
aXR5TGV2ZWxgOiBTdHJpbmcuIERlZmF1bHQgZW1wdHkuIElmIHNldCB0byBiZSBub24tZW1w
dHksIHRoZW4KICAgIGl0IG5lZWRzIHRvIGJlIG9uZSBvZjoKICAgICAqICBgbm8tZGl2ZXJz
aXR5YAogICAgICogIGBsb3ctZGl2ZXJzaXR5YAogICAgICogIGBtZWRpdW0tZGl2ZXJzaXR5
YAogICAgICogIGBoaWdoLWRpdmVyc2l0eWAKICAgICAqICBgYXV0by1kaXZlcnNpdHlgCiAg
ICBUaGlzIGdpdmVzIHJlcXVlc3QtbGV2ZWwgY29udHJvbCBhbmQgYWRqdXN0cyByZWNvbW1l
bmRhdGlvbiByZXN1bHRzCiAgICBiYXNlZCBvbiBEb2N1bWVudCBjYXRlZ29yeS4KICogYGF0
dHJpYnV0ZUZpbHRlcmluZ1N5bnRheGA6IEJvb2xlYW4uIEZhbHNlIGJ5IGRlZmF1bHQuIElm
IHNldCB0byB0cnVlLAogICAgdGhlIGBmaWx0ZXJgIGZpZWxkIGlzIGludGVycHJldGVkIGFj
Y29yZGluZyB0byB0aGUgbmV3LAogICAgYXR0cmlidXRlLWJhc2VkIHN5bnRheC4KCg0KBQQA
AgUGEgSnAQIkCg0KBQQAAgUBEgSnASUrCg0KBQQAAgUDEgSnAS4vCu4GCgQEAAIGEgS6AQIm
Gt8GIFRoZSB1c2VyIGxhYmVscyBhcHBsaWVkIHRvIGEgcmVzb3VyY2UgbXVzdCBtZWV0IHRo
ZSBmb2xsb3dpbmcgcmVxdWlyZW1lbnRzOgoKICogRWFjaCByZXNvdXJjZSBjYW4gaGF2ZSBt
dWx0aXBsZSBsYWJlbHMsIHVwIHRvIGEgbWF4aW11bSBvZiA2NC4KICogRWFjaCBsYWJlbCBt
dXN0IGJlIGEga2V5LXZhbHVlIHBhaXIuCiAqIEtleXMgaGF2ZSBhIG1pbmltdW0gbGVuZ3Ro
IG9mIDEgY2hhcmFjdGVyIGFuZCBhIG1heGltdW0gbGVuZ3RoIG9mIDYzCiAgIGNoYXJhY3Rl
cnMgYW5kIGNhbm5vdCBiZSBlbXB0eS4gVmFsdWVzIGNhbiBiZSBlbXB0eSBhbmQgaGF2ZSBh
IG1heGltdW0KICAgbGVuZ3RoIG9mIDYzIGNoYXJhY3RlcnMuCiAqIEtleXMgYW5kIHZhbHVl
cyBjYW4gY29udGFpbiBvbmx5IGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1lcmljIGNoYXJhY3Rl
cnMsCiAgIHVuZGVyc2NvcmVzLCBhbmQgZGFzaGVzLiBBbGwgY2hhcmFjdGVycyBtdXN0IHVz
ZSBVVEYtOCBlbmNvZGluZywgYW5kCiAgIGludGVybmF0aW9uYWwgY2hhcmFjdGVycyBhcmUg
YWxsb3dlZC4KICogVGhlIGtleSBwb3J0aW9uIG9mIGEgbGFiZWwgbXVzdCBiZSB1bmlxdWUu
IEhvd2V2ZXIsIHlvdSBjYW4gdXNlIHRoZSBzYW1lCiAgIGtleSB3aXRoIG11bHRpcGxlIHJl
c291cmNlcy4KICogS2V5cyBtdXN0IHN0YXJ0IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIG9y
IGludGVybmF0aW9uYWwgY2hhcmFjdGVyLgoKIFNlZSBbUmVxdWlyZW1lbnRzIGZvcgogbGFi
ZWxzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmVzb3VyY2UtbWFuYWdlci9kb2NzL2Ny
ZWF0aW5nLW1hbmFnaW5nLWxhYmVscyNyZXF1aXJlbWVudHMpCiBmb3IgbW9yZSBkZXRhaWxz
LgoKDQoFBAACBgYSBLoBAhUKDQoFBAACBgESBLoBFiEKDQoFBAACBgMSBLoBJCUKNgoCBAES
Br4BAOUBARooIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFJlY29tbWVuZCBtZXRob2QuCgoLCgME
AQESBL4BCBkKbAoEBAEDABIGwQEC0QEDGlwgUmVjb21tZW5kYXRpb25SZXN1bHQgcmVwcmVz
ZW50cyBhIGdlbmVyaWMgcmVjb21tZW5kYXRpb24gcmVzdWx0IHdpdGgKIGFzc29jaWF0ZWQg
bWV0YWRhdGEuCgoNCgUEAQMAARIEwQEKHgo6CgYEAQMAAgASBMMBBBIaKiBSZXNvdXJjZSBJ
RCBvZiB0aGUgcmVjb21tZW5kZWQgRG9jdW1lbnQuCgoPCgcEAQMAAgAFEgTDAQQKCg8KBwQB
AwACAAESBMMBCw0KDwoHBAEDAAIAAxIEwwEQEQqWAQoGBAEDAAIBEgTHAQQaGoUBIFNldCBp
ZiBgcmV0dXJuRG9jdW1lbnRgIGlzIHNldCB0byB0cnVlIGluCiBbUmVjb21tZW5kUmVxdWVz
dC5wYXJhbXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SZWNvbW1l
bmRSZXF1ZXN0LnBhcmFtc10uCgoPCgcEAQMAAgEGEgTHAQQMCg8KBwQBAwACAQESBMcBDRUK
DwoHBAEDAAIBAxIExwEYGQqOAgoGBAEDAAICEgTQAQQ0Gv0BIEFkZGl0aW9uYWwgRG9jdW1l
bnQgbWV0YWRhdGEgb3IgYW5ub3RhdGlvbnMuCgogUG9zc2libGUgdmFsdWVzOgoKICogYHNj
b3JlYDogUmVjb21tZW5kYXRpb24gc2NvcmUgaW4gZG91YmxlIHZhbHVlLiBJcyBzZXQgaWYK
ICAgYHJldHVyblNjb3JlYCBpcyBzZXQgdG8gdHJ1ZSBpbgogICBbUmVjb21tZW5kUmVxdWVz
dC5wYXJhbXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SZWNvbW1l
bmRSZXF1ZXN0LnBhcmFtc10uCgoPCgcEAQMAAgIGEgTQAQQmCg8KBwQBAwACAgESBNABJy8K
DwoHBAEDAAICAxIE0AEyMwqCAQoEBAECABIE1QECLBp0IEEgbGlzdCBvZiByZWNvbW1lbmRl
ZCBEb2N1bWVudHMuIFRoZSBvcmRlciByZXByZXNlbnRzIHRoZSByYW5raW5nIChmcm9tIHRo
ZQogbW9zdCByZWxldmFudCBEb2N1bWVudCB0byB0aGUgbGVhc3QpLgoKDQoFBAECAAQSBNUB
AgoKDQoFBAECAAYSBNUBCx8KDQoFBAECAAESBNUBICcKDQoFBAECAAMSBNUBKisK+wEKBAQB
AgESBNsBAh8a7AEgQSB1bmlxdWUgYXR0cmlidXRpb24gdG9rZW4uIFRoaXMgc2hvdWxkIGJl
IGluY2x1ZGVkIGluIHRoZQogW1VzZXJFdmVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlVzZXJFdmVudF0gbG9ncyByZXN1bHRpbmcKIGZyb20gdGhpcyByZWNv
bW1lbmRhdGlvbiwgd2hpY2ggZW5hYmxlcyBhY2N1cmF0ZSBhdHRyaWJ1dGlvbiBvZgogcmVj
b21tZW5kYXRpb24gbW9kZWwgcGVyZm9ybWFuY2UuCgoNCgUEAQIBBRIE2wECCAoNCgUEAQIB
ARIE2wEJGgoNCgUEAQIBAxIE2wEdHgqHAQoEBAECAhIE3wECIhp5IElEcyBvZiBkb2N1bWVu
dHMgaW4gdGhlIHJlcXVlc3QgdGhhdCB3ZXJlIG1pc3NpbmcgZnJvbSB0aGUgZGVmYXVsdCBC
cmFuY2gKIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVxdWVzdGVkIFNlcnZpbmdDb25maWcuCgoN
CgUEAQICBBIE3wECCgoNCgUEAQICBRIE3wELEQoNCgUEAQICARIE3wESHQoNCgUEAQICAxIE
3wEgIQqIAQoEBAECAxIE5AECGRp6IFRydWUgaWYKIFtSZWNvbW1lbmRSZXF1ZXN0LnZhbGlk
YXRlX29ubHldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SZWNvbW1l
bmRSZXF1ZXN0LnZhbGlkYXRlX29ubHldCiB3YXMgc2V0LgoKDQoFBAECAwUSBOQBAgYKDQoF
BAECAwESBOQBBxQKDQoFBAECAwMSBOQBFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest ===
    # Fields for RecommendRequest
    # Field: serving_config Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.discoveryengine.v1alpha.UserEvent)
    # Field: page_size Type: 5 ()
    # Field: filter Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: params Type: 11 (.google.cloud.discoveryengine.v1alpha.RecommendRequest.ParamsEntry)
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1alpha.RecommendRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse ===
    # Fields for RecommendResponse
    # Field: results Type: 11 (.google.cloud.discoveryengine.v1alpha.RecommendResponse.RecommendationResult)
    # Field: attribution_token Type: 9 ()
    # Field: missing_ids Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendationServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendationServiceClient

Client stub representing the remote C<RecommendationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub recommend {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.RecommendationService',
        method         => 'Recommend',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::RecommendationService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/recommendation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::RecommendationService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest->new({
        serving_config => $serving_config,
        user_event => $user_event,
        page_size => $page_size,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->serving_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/recommendation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest

Request message for Recommend method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. Full resource name of a
[ServingConfig][google.cloud.discoveryengine.v1alpha.ServingConfig]:
`projects/*/locations/global/collections/*/engines/*/servingConfigs/*`, or
`projects/*/locations/global/collections/*/dataStores/*/servingConfigs/*`

One default serving config is created along with your recommendation engine
creation. The engine ID is used as the ID of the default serving
config. For example, for Engine
`projects/*/locations/global/collections/*/engines/my-engine`, you can use
`projects/*/locations/global/collections/*/engines/my-engine/servingConfigs/my-engine`
for your
[RecommendationService.Recommend][google.cloud.discoveryengine.v1alpha.RecommendationService.Recommend]
requests.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent>)

Required. Context about the user, what they are looking at and what action
they took to trigger the Recommend request. Note that this user event
detail won't be ingested to userEvent logs. Thus, a separate userEvent
write request is required for event logging.

Don't set
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1alpha.UserEvent.user_pseudo_id]
or
[UserEvent.user_info.user_id][google.cloud.discoveryengine.v1alpha.UserInfo.user_id]
to the same fixed ID for different users. If you are trying to receive
non-personalized recommendations (not recommended; this can negatively
impact model performance), instead set
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1alpha.UserEvent.user_pseudo_id]
to a random unique ID and leave
[UserEvent.user_info.user_id][google.cloud.discoveryengine.v1alpha.UserInfo.user_id]
unset.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of results to return. Set this property
to the number of recommendation results needed. If zero, the service
chooses a reasonable default. The maximum allowed value is 100. Values
above 100 are set to 100.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter for restricting recommendation results with a length limit of 5,000
characters. Currently, only filter expressions on the `filter_tags`
attribute is supported.


Examples:

 * `(filter_tags: ANY("Red", "Blue") OR filter_tags: ANY("Hot", "Cold"))`
 * `(filter_tags: ANY("Red", "Blue")) AND NOT (filter_tags: ANY("Green"))`

If `attributeFilteringSyntax` is set to true under the `params` field, then
attribute-based expressions are expected instead of the above described
tag-based syntax. Examples:

 * (launguage: ANY("en", "es")) AND NOT (categories: ANY("Movie"))
 * (available: true) AND
   (launguage: ANY("en", "es")) OR (categories: ANY("Movie"))

If your filter blocks all results, the API returns generic
(unfiltered) popular Documents. If you only want results strictly matching
the filters, set `strictFiltering` to `true` in
[RecommendRequest.params][google.cloud.discoveryengine.v1alpha.RecommendRequest.params]
to receive empty results instead.

Note that the API never returns
[Document][google.cloud.discoveryengine.v1alpha.Document]s with
`storageStatus` as `EXPIRED` or `DELETED` regardless of filter choices.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Use validate only mode for this recommendation query. If set to `true`, a
fake model is used that returns arbitrary Document IDs.
Note that the validate only mode should only be used for testing the API,
or if the model is not ready.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest::ParamsEntry>)

Additional domain specific parameters for the recommendations.

Allowed values:

* `returnDocument`: Boolean. If set to `true`, the associated Document
   object is returned in
   [RecommendResponse.RecommendationResult.document][google.cloud.discoveryengine.v1alpha.RecommendResponse.RecommendationResult.document].
* `returnScore`: Boolean. If set to true, the recommendation score
   corresponding to each returned Document is set in
   [RecommendResponse.RecommendationResult.metadata][google.cloud.discoveryengine.v1alpha.RecommendResponse.RecommendationResult.metadata].
   The given score indicates the probability of a Document conversion given
   the user's context and history.
* `strictFiltering`: Boolean. True by default. If set to `false`, the
service
   returns generic (unfiltered) popular Documents instead of empty if
   your filter blocks all recommendation results.
* `diversityLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of:
    *  `no-diversity`
    *  `low-diversity`
    *  `medium-diversity`
    *  `high-diversity`
    *  `auto-diversity`
   This gives request-level control and adjusts recommendation results
   based on Document category.
* `attributeFilteringSyntax`: Boolean. False by default. If set to true,
   the `filter` field is interpreted according to the new,
   attribute-based syntax.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest::UserLabelsEntry>)

The user labels applied to a resource must meet the following requirements:

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

See [Requirements for
labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
for more details.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse

Response message for Recommend method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse::RecommendationResult>)

A list of recommended Documents. The order represents the ranking (from the
most relevant Document to the least).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique attribution token. This should be included in the
[UserEvent][google.cloud.discoveryengine.v1alpha.UserEvent] logs resulting
from this recommendation, which enables accurate attribution of
recommendation model performance.

=item * C<< $msg->missing_ids() >> / C<< $msg->missing_ids($value) >>

Type: C<String>

IDs of documents in the request that were missing from the default Branch
associated with the requested ServingConfig.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

True if
[RecommendRequest.validate_only][google.cloud.discoveryengine.v1alpha.RecommendRequest.validate_only]
was set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::RecommendationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
