package Google::Cloud::Discoveryengine::V1alpha::CompletionService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1alpha::PurgeConfig };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tcGxldGlvbl9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvaW1wb3J0X2NvbmZpZy5w
cm90bxo3Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL3B1cmdlX2NvbmZp
Zy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8igwIKFENvbXBs
ZXRlUXVlcnlSZXF1ZXN0Ek8KCmRhdGFfc3RvcmUYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIJZGF0YVN0b3JlEhkKBXF1ZXJ5GAIg
ASgJQgPgQQJSBXF1ZXJ5Eh8KC3F1ZXJ5X21vZGVsGAMgASgJUgpxdWVyeU1vZGVsEiQKDnVz
ZXJfcHNldWRvX2lkGAQgASgJUgx1c2VyUHNldWRvSWQSOAoYaW5jbHVkZV90YWlsX3N1Z2dl
c3Rpb25zGAUgASgIUhZpbmNsdWRlVGFpbFN1Z2dlc3Rpb25zIq4CChVDb21wbGV0ZVF1ZXJ5
UmVzcG9uc2USeAoRcXVlcnlfc3VnZ2VzdGlvbnMYASADKAsySy5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29tcGxldGVRdWVyeVJlc3BvbnNlLlF1ZXJ5U3VnZ2Vz
dGlvblIQcXVlcnlTdWdnZXN0aW9ucxIwChR0YWlsX21hdGNoX3RyaWdnZXJlZBgCIAEoCFIS
dGFpbE1hdGNoVHJpZ2dlcmVkGmkKD1F1ZXJ5U3VnZ2VzdGlvbhIeCgpzdWdnZXN0aW9uGAEg
ASgJUgpzdWdnZXN0aW9uEjYKF2NvbXBsZXRhYmxlX2ZpZWxkX3BhdGhzGAIgAygJUhVjb21w
bGV0YWJsZUZpZWxkUGF0aHMy5xIKEUNvbXBsZXRpb25TZXJ2aWNlErQCCg1Db21wbGV0ZVF1
ZXJ5EjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNvbXBsZXRlUXVl
cnlSZXF1ZXN0GjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNvbXBs
ZXRlUXVlcnlSZXNwb25zZSKpAYLT5JMCogESRy92MWFscGhhL3tkYXRhX3N0b3JlPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qfTpjb21wbGV0ZVF1ZXJ5WlcSVS92MWFs
cGhhL3tkYXRhX3N0b3JlPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9k
YXRhU3RvcmVzLyp9OmNvbXBsZXRlUXVlcnkS/gMKH0ltcG9ydFN1Z2dlc3Rpb25EZW55TGlz
dEVudHJpZXMSTC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuSW1wb3J0
U3VnZ2VzdGlvbkRlbnlMaXN0RW50cmllc1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uIu0CgtPkkwLGASJkL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfS9zdWdnZXN0aW9uRGVueUxpc3RF
bnRyaWVzOmltcG9ydDoBKlpbIlYvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovZGF0YVN0b3Jlcy8qfS9zdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzOmltcG9ydDoB
KspBnAEKTGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5JbXBvcnRTdWdn
ZXN0aW9uRGVueUxpc3RFbnRyaWVzUmVzcG9uc2USTGdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5JbXBvcnRTdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzTWV0YWRhdGES
+QMKHlB1cmdlU3VnZ2VzdGlvbkRlbnlMaXN0RW50cmllcxJLLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLqAoLT5JMCxQEiYy92MWFscGhh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9y
ZXMvKn0vc3VnZ2VzdGlvbkRlbnlMaXN0RW50cmllczpwdXJnZToBKlpbIlYvdjFhbHBoYS97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qKn0vc3VnZ2VzdGlv
bkRlbnlMaXN0RW50cmllczpwdXJnZToBKspBmgEKS2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNSZXNwb25zZRJL
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlB1cmdlU3VnZ2VzdGlvbkRl
bnlMaXN0RW50cmllc01ldGFkYXRhEuYDChtJbXBvcnRDb21wbGV0aW9uU3VnZ2VzdGlvbnMS
SC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuSW1wb3J0Q29tcGxldGlv
blN1Z2dlc3Rpb25zUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i3QKC
0+STAr4BImAvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVj
dGlvbnMvKi9kYXRhU3RvcmVzLyp9L2NvbXBsZXRpb25TdWdnZXN0aW9uczppbXBvcnQ6ASpa
VyJSL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMv
Kn0vY29tcGxldGlvblN1Z2dlc3Rpb25zOmltcG9ydDoBKspBlAEKSGdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5JbXBvcnRDb21wbGV0aW9uU3VnZ2VzdGlvbnNSZXNw
b25zZRJIZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkltcG9ydENvbXBs
ZXRpb25TdWdnZXN0aW9uc01ldGFkYXRhEuADChpQdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9u
cxJHLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5QdXJnZUNvbXBsZXRp
b25TdWdnZXN0aW9uc1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uItkC
gtPkkwK8ASJfL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxl
Y3Rpb25zLyovZGF0YVN0b3Jlcy8qfS9jb21wbGV0aW9uU3VnZ2VzdGlvbnM6cHVyZ2U6ASpa
ViJRL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMv
Kn0vY29tcGxldGlvblN1Z2dlc3Rpb25zOnB1cmdlOgEqykGSAQpHZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlB1cmdlQ29tcGxldGlvblN1Z2dlc3Rpb25zUmVzcG9u
c2USR2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5QdXJnZUNvbXBsZXRp
b25TdWdnZXN0aW9uc01ldGFkYXRhGlLKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5j
b23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQqIC
Cihjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhQhZDb21wbGV0aW9u
U2VydmljZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2Fw
aXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZF
UllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29n
bGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNj
b3ZlcnlFbmdpbmU6OlYxYWxwaGFKky0KBxIFDgDVAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMU
ACkKCQoCAwMSAxUAIwoJCgIDBBIDFgBCCgkKAgMFEgMXAEEKCQoCAwYSAxgALQoICgEIEgMa
AEEKCQoCCCUSAxoAQQoICgEIEgMbAGkKCQoCCAsSAxsAaQoICgEIEgMcACIKCQoCCAoSAxwA
IgoICgEIEgMdADcKCQoCCAgSAx0ANwoICgEIEgMeAEEKCQoCCAESAx4AQQoICgEIEgMfAC0K
CQoCCCQSAx8ALQoICgEIEgMgAEEKCQoCCCkSAyAAQQoICgEIEgMhAEAKCQoCCC0SAyEAQAoq
CgIGABIEJAB+ARoeIFNlcnZpY2UgZm9yIEF1dG8tQ29tcGxldGlvbi4KCgoKAwYAARIDJAgZ
CgoKAwYAAxIDJQJGCgwKBQYAA5kIEgMlAkYKCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3
CkwKBAYAAgASBCoCMQMaPiBDb21wbGV0ZXMgdGhlIHNwZWNpZmllZCB1c2VyIGlucHV0IHdp
dGgga2V5d29yZCBzdWdnZXN0aW9ucy4KCgwKBQYAAgABEgMqBhMKDAoFBgACAAISAyoUKAoM
CgUGAAIAAxIDKjNICg0KBQYAAgAEEgQrBDAGChEKCQYAAgAEsMq8IhIEKwQwBgqGAQoEBgAC
ARIENgJEAxp4IEltcG9ydHMgYWxsCiBbU3VnZ2VzdGlvbkRlbnlMaXN0RW50cnldW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TdWdnZXN0aW9uRGVueUxpc3RFbnRy
eV0KIGZvciBhIERhdGFTdG9yZS4KCgwKBQYAAgEBEgM2BiUKDAoFBgACAQISAzYmTAoMCgUG
AAIBAxIDNw8rCg0KBQYAAgEEEgQ4BD8GChEKCQYAAgEEsMq8IhIEOAQ/BgoNCgUGAAIBBBIE
QARDBgoPCgcGAAIBBJkIEgRABEMGCpMBCgQGAAICEgRJAlcDGoQBIFBlcm1hbmVudGx5IGRl
bGV0ZXMgYWxsCiBbU3VnZ2VzdGlvbkRlbnlMaXN0RW50cnldW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5TdWdnZXN0aW9uRGVueUxpc3RFbnRyeV0KIGZvciBhIERh
dGFTdG9yZS4KCgwKBQYAAgIBEgNJBiQKDAoFBgACAgISA0klSgoMCgUGAAICAxIDSg8rCg0K
BQYAAgIEEgRLBFIGChEKCQYAAgIEsMq8IhIESwRSBgoNCgUGAAICBBIEUwRWBgoPCgcGAAIC
BJkIEgRTBFYGCn0KBAYAAgMSBFwCagMabyBJbXBvcnRzCiBbQ29tcGxldGlvblN1Z2dlc3Rp
b25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db21wbGV0aW9uU3Vn
Z2VzdGlvbl1zCiBmb3IgYSBEYXRhU3RvcmUuCgoMCgUGAAIDARIDXAYhCgwKBQYAAgMCEgNc
IkQKDAoFBgACAwMSA10PKwoNCgUGAAIDBBIEXgRlBgoRCgkGAAIDBLDKvCISBF4EZQYKDQoF
BgACAwQSBGYEaQYKDwoHBgACAwSZCBIEZgRpBgqNAQoEBgACBBIEbwJ9Axp/IFBlcm1hbmVu
dGx5IGRlbGV0ZXMgYWxsCiBbQ29tcGxldGlvblN1Z2dlc3Rpb25dW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db21wbGV0aW9uU3VnZ2VzdGlvbl1zCiBmb3IgYSBE
YXRhU3RvcmUuCgoMCgUGAAIEARIDbwYgCgwKBQYAAgQCEgNvIUIKDAoFBgACBAMSA3APKwoN
CgUGAAIEBBIEcQR4BgoRCgkGAAIEBLDKvCISBHEEeAYKDQoFBgACBAQSBHkEfAYKDwoHBgAC
BASZCBIEeQR8BgqWAQoCBAASBoMBALoBARqHASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ29t
cGxldGlvblNlcnZpY2UuQ29tcGxldGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLkNvbXBsZXRpb25TZXJ2aWNlLkNvbXBsZXRlUXVlcnldCiBtZXRob2Qu
CgoLCgMEAAESBIMBCBwKzQEKBAQAAgASBocBAowBBBq8ASBSZXF1aXJlZC4gVGhlIHBhcmVu
dCBkYXRhIHN0b3JlIHJlc291cmNlIG5hbWUgZm9yIHdoaWNoIHRoZSBjb21wbGV0aW9uIGlz
CiBwZXJmb3JtZWQsIHN1Y2ggYXMKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY29s
bGVjdGlvbnMvZGVmYXVsdF9jb2xsZWN0aW9uL2RhdGFTdG9yZXMvZGVmYXVsdF9kYXRhX3N0
b3JlYC4KCg0KBQQAAgAFEgSHAQIICg0KBQQAAgABEgSHAQkTCg0KBQQAAgADEgSHARYXCg8K
BQQAAgAIEgaHARiMAQMKEAoIBAACAAicCAASBIgBBCoKEQoHBAACAAifCBIGiQEEiwEFCmsK
BAQAAgESBJABAjwaXSBSZXF1aXJlZC4gVGhlIHR5cGVhaGVhZCBpbnB1dCB1c2VkIHRvIGZl
dGNoIHN1Z2dlc3Rpb25zLiBNYXhpbXVtIGxlbmd0aCBpcwogMTI4IGNoYXJhY3RlcnMuCgoN
CgUEAAIBBRIEkAECCAoNCgUEAAIBARIEkAEJDgoNCgUEAAIBAxIEkAEREgoNCgUEAAIBCBIE
kAETOwoQCggEAAIBCJwIABIEkAEUOgrCBgoEBAACAhIEowECGRqzBiBTcGVjaWZpZXMgdGhl
IGF1dG9jb21wbGV0ZSBkYXRhIG1vZGVsLiBUaGlzIG92ZXJyaWRlcyBhbnkgbW9kZWwgc3Bl
Y2lmaWVkCiBpbiB0aGUgQ29uZmlndXJhdGlvbiA+IEF1dG9jb21wbGV0ZSBzZWN0aW9uIG9m
IHRoZSBDbG91ZCBjb25zb2xlLiBDdXJyZW50bHkKIHN1cHBvcnRlZCB2YWx1ZXM6CgogKiBg
ZG9jdW1lbnRgIC0gVXNpbmcgc3VnZ2VzdGlvbnMgZ2VuZXJhdGVkIGZyb20gdXNlci1pbXBv
cnRlZCBkb2N1bWVudHMuCiAqIGBzZWFyY2gtaGlzdG9yeWAgLSBVc2luZyBzdWdnZXN0aW9u
cyBnZW5lcmF0ZWQgZnJvbSB0aGUgcGFzdCBoaXN0b3J5IG9mCiBbU2VhcmNoU2VydmljZS5T
ZWFyY2hdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZWFyY2hTZXJ2
aWNlLlNlYXJjaF0KIEFQSSBjYWxscy4gRG8gbm90IHVzZSBpdCB3aGVuIHRoZXJlIGlzIG5v
IHRyYWZmaWMgZm9yIFNlYXJjaCBBUEkuCiAqIGB1c2VyLWV2ZW50YCAtIFVzaW5nIHN1Z2dl
c3Rpb25zIGdlbmVyYXRlZCBmcm9tIHVzZXItaW1wb3J0ZWQgc2VhcmNoCiBldmVudHMuCiAq
IGBkb2N1bWVudC1jb21wbGV0YWJsZWAgLSBVc2luZyBzdWdnZXN0aW9ucyB0YWtlbiBkaXJl
Y3RseSBmcm9tCiB1c2VyLWltcG9ydGVkIGRvY3VtZW50IGZpZWxkcyBtYXJrZWQgYXMgY29t
cGxldGFibGUuCgogRGVmYXVsdCB2YWx1ZXM6CgogKiBgZG9jdW1lbnRgIGlzIHRoZSBkZWZh
dWx0IG1vZGVsIGZvciByZWd1bGFyIGRhdGFTdG9yZXMuCiAqIGBzZWFyY2gtaGlzdG9yeWAg
aXMgdGhlIGRlZmF1bHQgbW9kZWwgZm9yIHNpdGUgc2VhcmNoIGRhdGFTdG9yZXMuCgoNCgUE
AAICBRIEowECCAoNCgUEAAICARIEowEJFAoNCgUEAAICAxIEowEXGArSBQoEBAACAxIEswEC
HBrDBSBBIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0cmFja2luZyB2aXNpdG9ycy4gRm9yIGV4
YW1wbGUsIHRoaXMgY291bGQgYmUKIGltcGxlbWVudGVkIHdpdGggYW4gSFRUUCBjb29raWUs
IHdoaWNoIHNob3VsZCBiZSBhYmxlIHRvIHVuaXF1ZWx5IGlkZW50aWZ5CiBhIHZpc2l0b3Ig
b24gYSBzaW5nbGUgZGV2aWNlLiBUaGlzIHVuaXF1ZSBpZGVudGlmaWVyIHNob3VsZCBub3Qg
Y2hhbmdlIGlmCiB0aGUgdmlzaXRvciBsb2dzIGluIG9yIG91dCBvZiB0aGUgd2Vic2l0ZS4K
CiBUaGlzIGZpZWxkIHNob3VsZCBOT1QgaGF2ZSBhIGZpeGVkIHZhbHVlIHN1Y2ggYXMgYHVu
a25vd25fdmlzaXRvcmAuCgogVGhpcyBzaG91bGQgYmUgdGhlIHNhbWUgaWRlbnRpZmllciBh
cwogW1VzZXJFdmVudC51c2VyX3BzZXVkb19pZF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlVzZXJFdmVudC51c2VyX3BzZXVkb19pZF0KIGFuZAogW1NlYXJjaFJl
cXVlc3QudXNlcl9wc2V1ZG9faWRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TZWFyY2hSZXF1ZXN0LnVzZXJfcHNldWRvX2lkXS4KCiBUaGUgZmllbGQgbXVzdCBi
ZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTI4CiBj
aGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFuIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyBy
ZXR1cm5lZC4KCg0KBQQAAgMFEgSzAQIICg0KBQQAAgMBEgSzAQkXCg0KBQQAAgMDEgSzARob
Cv0BCgQEAAIEEgS5AQIkGu4BIEluZGljYXRlcyBpZiB0YWlsIHN1Z2dlc3Rpb25zIHNob3Vs
ZCBiZSByZXR1cm5lZCBpZiB0aGVyZSBhcmUgbm8KIHN1Z2dlc3Rpb25zIHRoYXQgbWF0Y2gg
dGhlIGZ1bGwgcXVlcnkuIEV2ZW4gaWYgc2V0IHRvIHRydWUsIGlmIHRoZXJlIGFyZQogc3Vn
Z2VzdGlvbnMgdGhhdCBtYXRjaCB0aGUgZnVsbCBxdWVyeSwgdGhvc2UgYXJlIHJldHVybmVk
IGFuZCBubwogdGFpbCBzdWdnZXN0aW9ucyBhcmUgcmV0dXJuZWQuCgoNCgUEAAIEBRIEuQEC
BgoNCgUEAAIEARIEuQEHHwoNCgUEAAIEAxIEuQEiIwqXAQoCBAESBr8BANUBARqIASBSZXNw
b25zZSBtZXNzYWdlIGZvcgogW0NvbXBsZXRpb25TZXJ2aWNlLkNvbXBsZXRlUXVlcnldW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db21wbGV0aW9uU2VydmljZS5D
b21wbGV0ZVF1ZXJ5XQogbWV0aG9kLgoKCwoDBAEBEgS/AQgdCjAKBAQBAwASBsEBAsoBAxog
IFN1Z2dlc3Rpb25zIGFzIHNlYXJjaCBxdWVyaWVzLgoKDQoFBAEDAAESBMEBChkKLwoGBAED
AAIAEgTDAQQaGh8gVGhlIHN1Z2dlc3Rpb24gZm9yIHRoZSBxdWVyeS4KCg8KBwQBAwACAAUS
BMMBBAoKDwoHBAEDAAIAARIEwwELFQoPCgcEAQMAAgADEgTDARgZCs8BCgYEAQMAAgESBMkB
BDAavgEgVGhlIHVuaXF1ZSBkb2N1bWVudCBmaWVsZCBwYXRocyB0aGF0IHNlcnZlIGFzIHRo
ZSBzb3VyY2Ugb2YgdGhpcwogc3VnZ2VzdGlvbiBpZiBpdCB3YXMgZ2VuZXJhdGVkIGZyb20g
Y29tcGxldGFibGUgZmllbGRzLgoKIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQgZm9y
IHRoZSBkb2N1bWVudC1jb21wbGV0YWJsZSBtb2RlbC4KCg8KBwQBAwACAQQSBMkBBAwKDwoH
BAEDAAIBBRIEyQENEwoPCgcEAQMAAgEBEgTJARQrCg8KBwQBAwACAQMSBMkBLi8KfwoEBAEC
ABIEzgECMRpxIFJlc3VsdHMgb2YgdGhlIG1hdGNoZWQgcXVlcnkgc3VnZ2VzdGlvbnMuIFRo
ZSByZXN1bHQgbGlzdCBpcyBvcmRlcmVkIGFuZAogdGhlIGZpcnN0IHJlc3VsdCBpcyBhIHRv
cCBzdWdnZXN0aW9uLgoKDQoFBAECAAQSBM4BAgoKDQoFBAECAAYSBM4BCxoKDQoFBAECAAES
BM4BGywKDQoFBAECAAMSBM4BLzAK4gEKBAQBAgESBNQBAiAa0wEgVHJ1ZSBpZiB0aGUgcmV0
dXJuZWQgc3VnZ2VzdGlvbnMgYXJlIGFsbCB0YWlsIHN1Z2dlc3Rpb25zLgoKIEZvciB0YWls
IG1hdGNoaW5nIHRvIGJlIHRyaWdnZXJlZCwgaW5jbHVkZV90YWlsX3N1Z2dlc3Rpb25zIGlu
IHRoZSByZXF1ZXN0CiBtdXN0IGJlIHRydWUgYW5kIHRoZXJlIG11c3QgYmUgbm8gc3VnZ2Vz
dGlvbnMgdGhhdCBtYXRjaCB0aGUgZnVsbCBxdWVyeS4KCg0KBQQBAgEFEgTUAQIGCg0KBQQB
AgEBEgTUAQcbCg0KBQQBAgEDEgTUAR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest ===
    # Fields for CompleteQueryRequest
    # Field: data_store Type: 9 ()
    # Field: query Type: 9 ()
    # Field: query_model Type: 9 ()
    # Field: user_pseudo_id Type: 9 ()
    # Field: include_tail_suggestions Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse ===
    # Fields for CompleteQueryResponse
    # Field: query_suggestions Type: 11 (.google.cloud.discoveryengine.v1alpha.CompleteQueryResponse.QuerySuggestion)
    # Field: tail_match_triggered Type: 8 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompletionServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompletionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompletionServiceClient

Client stub representing the remote C<CompletionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub complete_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.CompletionService',
        method         => 'CompleteQuery',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse',
    });
}

sub import_suggestion_deny_list_entries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportSuggestionDenyListEntriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.CompletionService',
        method         => 'ImportSuggestionDenyListEntries',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub purge_suggestion_deny_list_entries {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.CompletionService',
        method         => 'PurgeSuggestionDenyListEntries',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_completion_suggestions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportCompletionSuggestionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.CompletionService',
        method         => 'ImportCompletionSuggestions',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub purge_completion_suggestions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.CompletionService',
        method         => 'PurgeCompletionSuggestions',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::CompletionService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/completion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::CompletionService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest->new({
        data_store => $data_store,
        query => $query,
        query_model => $query_model,
        user_pseudo_id => $user_pseudo_id,
    });

    # Read or update a field
    my $val = $msg->data_store();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/completion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest

Request message for
[CompletionService.CompleteQuery][google.cloud.discoveryengine.v1alpha.CompletionService.CompleteQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The parent data store resource name for which the completion is
performed, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. The typeahead input used to fetch suggestions. Maximum length is
128 characters.

=item * C<< $msg->query_model() >> / C<< $msg->query_model($value) >>

Type: C<String>

Specifies the autocomplete data model. This overrides any model specified
in the Configuration > Autocomplete section of the Cloud console. Currently
supported values:

* `document` - Using suggestions generated from user-imported documents.
* `search-history` - Using suggestions generated from the past history of
[SearchService.Search][google.cloud.discoveryengine.v1alpha.SearchService.Search]
API calls. Do not use it when there is no traffic for Search API.
* `user-event` - Using suggestions generated from user-imported search
events.
* `document-completable` - Using suggestions taken directly from
user-imported document fields marked as completable.

Default values:

* `document` is the default model for regular dataStores.
* `search-history` is the default model for site search dataStores.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking visitors. For example, this could be
implemented with an HTTP cookie, which should be able to uniquely identify
a visitor on a single device. This unique identifier should not change if
the visitor logs in or out of the website.

This field should NOT have a fixed value such as `unknown_visitor`.

This should be the same identifier as
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1alpha.UserEvent.user_pseudo_id]
and
[SearchRequest.user_pseudo_id][google.cloud.discoveryengine.v1alpha.SearchRequest.user_pseudo_id].

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->include_tail_suggestions() >> / C<< $msg->include_tail_suggestions($value) >>

Type: C<Bool>

Indicates if tail suggestions should be returned if there are no
suggestions that match the full query. Even if set to true, if there are
suggestions that match the full query, those are returned and no
tail suggestions are returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse

Response message for
[CompletionService.CompleteQuery][google.cloud.discoveryengine.v1alpha.CompletionService.CompleteQuery]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query_suggestions() >> / C<< $msg->query_suggestions($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse::QuerySuggestion>)

Results of the matched query suggestions. The result list is ordered and
the first result is a top suggestion.

=item * C<< $msg->tail_match_triggered() >> / C<< $msg->tail_match_triggered($value) >>

Type: C<Bool>

True if the returned suggestions are all tail suggestions.

For tail matching to be triggered, include_tail_suggestions in the request
must be true and there must be no suggestions that match the full query.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::CompletionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
