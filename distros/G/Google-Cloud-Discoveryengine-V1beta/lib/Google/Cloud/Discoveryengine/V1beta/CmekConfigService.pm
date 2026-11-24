package Google::Cloud::Discoveryengine::V1beta::CmekConfigService;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jbWVrX2NvbmZpZ19zZXJ2
aWNlLnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRocZ29vZ2xl
L2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
I2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYv
ZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iiAEKF1VwZGF0
ZUNtZWtDb25maWdSZXF1ZXN0EkwKBmNvbmZpZxgBIAEoCzIvLmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLkNtZWtDb25maWdCA+BBAlIGY29uZmlnEh8KC3NldF9kZWZh
dWx0GAIgASgIUgpzZXREZWZhdWx0Il0KFEdldENtZWtDb25maWdSZXF1ZXN0EkUKBG5hbWUY
ASABKAlCMeBBAvpBKwopZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NtZWtDb25m
aWdSBG5hbWUiVgoPU2luZ2xlUmVnaW9uS2V5EkMKB2ttc19rZXkYASABKAlCKuBBAvpBJAoi
Y2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5c1IGa21zS2V5Is8ICgpDbWVrQ29u
ZmlnEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRJDCgdrbXNfa2V5GAIgASgJQirgQQL6QSQK
ImNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleXNSBmttc0tleRJZCg9rbXNfa2V5
X3ZlcnNpb24YBiABKAlCMeBBA/pBKwopY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRv
S2V5VmVyc2lvbnNSDWttc0tleVZlcnNpb24SUAoFc3RhdGUYAyABKA4yNS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DbWVrQ29uZmlnLlN0YXRlQgPgQQNSBXN0YXRl
EiIKCmlzX2RlZmF1bHQYBCABKAhCA+BBA1IJaXNEZWZhdWx0EkgKHmxhc3Rfcm90YXRpb25f
dGltZXN0YW1wX21pY3JvcxgFIAEoA0ID4EEDUhtsYXN0Um90YXRpb25UaW1lc3RhbXBNaWNy
b3MSZwoSc2luZ2xlX3JlZ2lvbl9rZXlzGAcgAygLMjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuU2luZ2xlUmVnaW9uS2V5QgPgQQFSEHNpbmdsZVJlZ2lvbktleXMS
bwoQbm90ZWJvb2tsbV9zdGF0ZRgIIAEoDjI/Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLkNtZWtDb25maWcuTm90ZWJvb2tMTVN0YXRlQgPgQQNSD25vdGVib29rbG1T
dGF0ZSKlAQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoK
BkFDVElWRRACEg0KCUtFWV9JU1NVRRADEgwKCERFTEVUSU5HEAQSEQoNREVMRVRFX0ZBSUxF
RBAHEgwKCFVOVVNBQkxFEAUSEwoPQUNUSVZFX1JPVEFUSU5HEAYSCwoHREVMRVRFRBAIEgsK
B0VYUElSRUQQCSKDAQoPTm90ZWJvb2tMTVN0YXRlEiEKHU5PVEVCT09LX0xNX1NUQVRFX1VO
U1BFQ0lGSUVEEAASGQoVTk9URUJPT0tfTE1fTk9UX1JFQURZEAESFQoRTk9URUJPT0tfTE1f
UkVBRFkQAhIbChdOT1RFQk9PS19MTV9OT1RfRU5BQkxFRBADOr8B6kG7AQopZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NtZWtDb25maWcSMnByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9jbWVrQ29uZmlnEkFwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY21la0NvbmZpZ3Mve2NtZWtfY29uZmlnfSoLY21la0NvbmZp
Z3MyCmNtZWtDb25maWcilAEKGFVwZGF0ZUNtZWtDb25maWdNZXRhZGF0YRI7CgtjcmVhdGVf
dGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoL
dXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVU
aW1lImEKFkxpc3RDbWVrQ29uZmlnc1JlcXVlc3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkK
J2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50Im0KF0xp
c3RDbWVrQ29uZmlnc1Jlc3BvbnNlElIKDGNtZWtfY29uZmlncxgBIAMoCzIvLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNtZWtDb25maWdSC2NtZWtDb25maWdzImAK
F0RlbGV0ZUNtZWtDb25maWdSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NtZWtDb25maWdSBG5hbWUilAEKGERlbGV0ZUNt
ZWtDb25maWdNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lMrwKChFDbWVrQ29uZmlnU2VydmljZRL6
AgoQVXBkYXRlQ21la0NvbmZpZxI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLlVwZGF0ZUNtZWtDb25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbiKIAoLT5JMChwEyNy92MWJldGEve2NvbmZpZy5uYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovY21la0NvbmZpZ306BmNvbmZpZ1pEMjovdjFiZXRhL3tjb25maWcubmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NtZWtDb25maWdzLyp9OgZjb25maWfaQQZjb25maWfKQW4K
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNtZWtDb25maWcSPGdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVwZGF0ZUNtZWtDb25maWdNZXRhZGF0
YRLzAQoNR2V0Q21la0NvbmZpZxI5Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkdldENtZWtDb25maWdSZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuQ21la0NvbmZpZyJ2gtPkkwJpEjAvdjFiZXRhL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovY21la0NvbmZpZ31aNRIzL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2NtZWtDb25maWdzLyp92kEEbmFtZRLSAQoPTGlzdENtZWtDb25maWdzEjsu
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdENtZWtDb25maWdzUmVx
dWVzdBo8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RDbWVrQ29u
Zmlnc1Jlc3BvbnNlIkSC0+STAjUSMy92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qfS9jbWVrQ29uZmlnc9pBBnBhcmVudBKMAgoQRGVsZXRlQ21la0NvbmZpZxI8Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRlbGV0ZUNtZWtDb25maWdSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKaAYLT5JMCNSozL3YxYmV0YS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NtZWtDb25maWdzLyp92kEEbmFtZcpBVQoV
Z29vZ2xlLnByb3RvYnVmLkVtcHR5Ejxnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5EZWxldGVDbWVrQ29uZmlnTWV0YWRhdGEazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29v
Z2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1w
bGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2lu
ZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zlcnll
bmdpbmUuc2VydmluZy5yZWFkd3JpdGVCnQIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YUIWQ21la0NvbmZpZ1NlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUu
Y29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlz
Y292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292
ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh
6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFK2kUKBxIFDgC5AgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIA
JgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAtCgkKAgMFEgMX
ACUKCQoCAwYSAxgAKQoICgEIEgMaAEAKCQoCCCUSAxoAQAoICgEIEgMbAGgKCQoCCAsSAxsA
aAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADcKCQoCCAgSAx0ANwoICgEIEgMeAEAK
CQoCCAESAx4AQAoICgEIEgMfAC0KCQoCCCQSAx8ALQoICgEIEgMgAEAKCQoCCCkSAyAAQAoI
CgEIEgMhAD8KCQoCCC0SAyEAPwo1CgIGABIEJABhARopIFNlcnZpY2UgZm9yIG1hbmFnaW5n
IENNRUsgcmVsYXRlZCB0YXNrcwoKCgoDBgABEgMkCBkKCgoDBgADEgMlAkYKDAoFBgADmQgS
AyUCRgoLCgMGAAMSBCYCKUoKDQoFBgADmggSBCYCKUoK7QEKBAYAAgASBC8CPgMa3gEgUHJv
dmlzaW9ucyBhIENNRUsga2V5IGZvciB1c2UgaW4gYSBsb2NhdGlvbiBvZiBhIGN1c3RvbWVy
J3MgcHJvamVjdC4KIFRoaXMgbWV0aG9kIHdpbGwgYWxzbyBjb25kdWN0IGxvY2F0aW9uIHZh
bGlkYXRpb24gb24gdGhlIHByb3ZpZGVkCiBjbWVrQ29uZmlnIHRvIG1ha2Ugc3VyZSB0aGUg
a2V5IGlzIHZhbGlkIGFuZCBjYW4gYmUgdXNlZCBpbiB0aGUKIHNlbGVjdGVkIGxvY2F0aW9u
LgoKDAoFBgACAAESAy8GFgoMCgUGAAIAAhIDLxcuCgwKBQYAAgADEgMwDysKDQoFBgACAAQS
BDEEOAYKEQoJBgACAASwyrwiEgQxBDgGCgwKBQYAAgAEEgM5BDQKDwoIBgACAASbCAASAzkE
NAoNCgUGAAIABBIEOgQ9BgoPCgcGAAIABJkIEgQ6BD0GClYKBAYAAgESBEECSQMaSCBHZXRz
IHRoZSBbQ21la0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
Q21la0NvbmZpZ10uCgoMCgUGAAIBARIDQQYTCgwKBQYAAgECEgNBFCgKDAoFBgACAQMSA0Ez
PQoNCgUGAAIBBBIEQgRHBgoRCgkGAAIBBLDKvCISBEIERwYKDAoFBgACAQQSA0gEMgoPCggG
AAIBBJsIABIDSAQyCm4KBAYAAgISBE0CUwMaYCBMaXN0cyBhbGwgdGhlIFtDbWVrQ29uZmln
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DbWVrQ29uZmlnXXMKIHdp
dGggdGhlIHByb2plY3QuCgoMCgUGAAICARIDTQYVCgwKBQYAAgICEgNNFiwKDAoFBgACAgMS
A04PJgoNCgUGAAICBBIETwRRBgoRCgkGAAICBLDKvCISBE8EUQYKDAoFBgACAgQSA1IENAoP
CggGAAICBJsIABIDUgQ0CisKBAYAAgMSBFYCYAMaHSBEZS1wcm92aXNpb25zIGEgQ21la0Nv
bmZpZy4KCgwKBQYAAgMBEgNWBhYKDAoFBgACAwISA1YXLgoMCgUGAAIDAxIDVw8rCg0KBQYA
AgMEEgRYBFoGChEKCQYAAgMEsMq8IhIEWARaBgoMCgUGAAIDBBIDWwQyCg8KCAYAAgMEmwgA
EgNbBDIKDQoFBgACAwQSBFwEXwYKDwoHBgACAwSZCBIEXARfBgpACgIEABIEZQBsARo0IFJl
cXVlc3QgbWVzc2FnZSBmb3IgVXBkYXRlQ21la0NvbmZpZyBtZXRob2QuCiBycGMuCgoKCgME
AAESA2UIHwoxCgQEAAIAEgNnAkEaJCBSZXF1aXJlZC4gVGhlIENtZWtDb25maWcgcmVzb3Vy
Y2UuCgoMCgUEAAIABhIDZwIMCgwKBQQAAgABEgNnDRMKDAoFBAACAAMSA2cWFwoMCgUEAAIA
CBIDZxhACg8KCAQAAgAInAgAEgNnGT8KcwoEBAACARIDawIXGmYgU2V0IHRoZSBmb2xsb3dp
bmcgQ21la0NvbmZpZyBhcyB0aGUgZGVmYXVsdCB0byBiZSB1c2VkIGZvciBjaGlsZAogcmVz
b3VyY2VzIGlmIG9uZSBpcyBub3Qgc3BlY2lmaWVkLgoKDAoFBAACAQUSA2sCBgoMCgUEAAIB
ARIDawcSCgwKBQQAAgEDEgNrFRYKPgoCBAESBG8AfgEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IEdldENtZWtDb25maWdSZXF1ZXN0IG1ldGhvZC4KCgoKAwQBARIDbwgcCokDCgQEAQIAEgR4
An0EGvoCIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mCiBbQ21la0NvbmZpZ11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ21la0NvbmZpZ10sIHN1Y2ggYXMKIGBw
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NtZWtDb25maWdgIG9yCiBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jbWVrQ29uZmlncy8qYC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUg
cGVybWlzc2lvbiB0byBhY2Nlc3MgdGhlCiBbQ21la0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuQ21la0NvbmZpZ10sIHJlZ2FyZGxlc3Mgb2YKIHdoZXRo
ZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1
cm5lZC4KCgwKBQQBAgAFEgN4AggKDAoFBAECAAESA3gJDQoMCgUEAQIAAxIDeBARCg0KBQQB
AgAIEgR4En0DCg8KCAQBAgAInAgAEgN5BCoKDwoHBAECAAifCBIEegR8BQozCgIEAhIGgQEA
iwEBGiUgTWV0YWRhdGEgZm9yIHNpbmdsZS1yZWdpb25hbCBDTUVLcy4KCgsKAwQCARIEgQEI
Fwq9AQoEBAICABIGhQECigEEGqwBIFJlcXVpcmVkLiBTaW5nbGUtcmVnaW9uYWwga21zIGtl
eSByZXNvdXJjZSBuYW1lIHdoaWNoIHdpbGwgYmUgdXNlZCB0bwogZW5jcnlwdCByZXNvdXJj
ZXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mv
e2tleVJpbmd9L2NyeXB0b0tleXMve2tleUlkfWAuCgoNCgUEAgIABRIEhQECCAoNCgUEAgIA
ARIEhQEJEAoNCgUEAgIAAxIEhQETFAoPCgUEAgIACBIGhQEVigEDChAKCAQCAgAInAgAEgSG
AQQqChEKBwQCAgAInwgSBocBBIkBBQpXCgIEAxIGjgEA8wEBGkkgQ29uZmlndXJhdGlvbnMg
dXNlZCB0byBlbmFibGUgQ01FSyBkYXRhIGVuY3J5cHRpb24gd2l0aCBDbG91ZCBLTVMga2V5
cy4KCgsKAwQDARIEjgEIEgoNCgMEAwcSBo8BApUBBAoPCgUEAwedCBIGjwEClQEECisKBAQD
BAASBpgBArkBAxobIFN0YXRlcyBvZiB0aGUgQ21la0NvbmZpZy4KCg0KBQQDBAABEgSYAQcM
CjIKBgQDBAACABIEmgEEGhoiIFRoZSBDbWVrQ29uZmlnIHN0YXRlIGlzIHVua25vd24uCgoP
CgcEAwQAAgABEgSaAQQVCg8KBwQDBAACAAISBJoBGBkKLQoGBAMEAAIBEgSdAQQRGh0gVGhl
IENtZWtDb25maWcgaXMgY3JlYXRpbmcuCgoPCgcEAwQAAgEBEgSdAQQMCg8KBwQDBAACAQIS
BJ0BDxAKPQoGBAMEAAICEgSgAQQPGi0gVGhlIENtZWtDb25maWcgY2FuIGJlIHVzZWQgd2l0
aCBEYXRhU3RvcmVzLgoKDwoHBAMEAAICARIEoAEECgoPCgcEAwQAAgICEgSgAQ0OCl8KBgQD
BAACAxIEpAEEEhpPIFRoZSBDbWVrQ29uZmlnIGlzIHVuYXZhaWxhYmxlLCBtb3N0IGxpa2Vs
eSBkdWUgdG8gdGhlIEtNUyBLZXkgYmVpbmcKIHJldm9rZWQuCgoPCgcEAwQAAgMBEgSkAQQN
Cg8KBwQDBAACAwISBKQBEBEKLQoGBAMEAAIEEgSnAQQRGh0gVGhlIENtZWtDb25maWcgaXMg
ZGVsZXRpbmcuCgoPCgcEAwQAAgQBEgSnAQQMCg8KBwQDBAACBAISBKcBDxAKOQoGBAMEAAIF
EgSqAQQWGikgVGhlIENtZWtDb25maWcgZGVsZXRpb24gcHJvY2VzcyBmYWlsZWQuCgoPCgcE
AwQAAgUBEgSqAQQRCg8KBwQDBAACBQISBKoBFBUKVwoGBAMEAAIGEgStAQQRGkcgVGhlIENt
ZWtDb25maWcgaXMgbm90IHVzYWJsZSwgbW9zdCBsaWtlbHkgZHVlIHRvIHNvbWUgaW50ZXJu
YWwgaXNzdWUuCgoPCgcEAwQAAgYBEgStAQQMCg8KBwQDBAACBgISBK0BDxAKNwoGBAMEAAIH
EgSwAQQYGicgVGhlIEtNUyBrZXkgdmVyc2lvbiBpcyBiZWluZyByb3RhdGVkLgoKDwoHBAME
AAIHARIEsAEEEwoPCgcEAwQAAgcCEgSwARYXCl8KBgQDBAACCBIEtAEEEBpPIFRoZSBLTVMg
a2V5IGlzIHNvZnQgZGVsZXRlZC4gU29tZSBjbGVhbnVwIHBvbGljeSB3aWxsIGV2ZW50dWFs
bHkgYmUKIGFwcGxpZWQuCgoPCgcEAwQAAggBEgS0AQQLCg8KBwQDBAACCAISBLQBDg8KogEK
BgQDBAACCRIEuAEEEBqRASBUaGUgS01TIGtleSBpcyBleHBpcmVkLCBtZWFuaW5nIHRoZSBr
ZXkgaGFzIGJlZW4gZGlzYWJsZWQgZm9yIDMwKyBkYXlzLgogVGhlIGN1c3RvbWVyIGNhbiBj
YWxsIERlbGV0ZUNtZWtDb25maWcgdG8gY2hhbmdlIHRoZSBzdGF0ZSB0byBERUxFVEVELgoK
DwoHBAMEAAIJARIEuAEECwoPCgcEAwQAAgkCEgS4AQ4PCicKBAQDBAESBrwBAsgBAxoXIFN0
YXRlcyBvZiBOb3RlYm9va0xNLgoKDQoFBAMEAQESBLwBBxYKMgoGBAMEAQIAEgS+AQQmGiIg
VGhlIE5vdGVib29rTE0gc3RhdGUgaXMgdW5rbm93bi4KCg8KBwQDBAECAAESBL4BBCEKDwoH
BAMEAQIAAhIEvgEkJQouCgYEAwQBAgESBMEBBB4aHiBUaGUgTm90ZWJvb2tMTSBpcyBub3Qg
cmVhZHkuCgoPCgcEAwQBAgEBEgTBAQQZCg8KBwQDBAECAQISBMEBHB0KNQoGBAMEAQICEgTE
AQQaGiUgVGhlIE5vdGVib29rTE0gaXMgcmVhZHkgdG8gYmUgdXNlZC4KCg8KBwQDBAECAgES
BMQBBBUKDwoHBAMEAQICAhIExAEYGQowCgYEAwQBAgMSBMcBBCAaICBUaGUgTm90ZWJvb2tM
TSBpcyBub3QgZW5hYmxlZC4KCg8KBwQDBAECAwESBMcBBBsKDwoHBAMEAQIDAhIExwEeHwrA
AQoEBAMCABIEzQECOxqxASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIENtZWtDb25maWcg
b2YgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Y21la0NvbmZpZ2Agb3IKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY21la0NvbmZpZ3Mve2NtZWtfY29uZmlnfWAuCgoNCgUEAwIABRIEzQECCAoNCgUEAwIA
ARIEzQEJDQoNCgUEAwIAAxIEzQEQEQoNCgUEAwIACBIEzQESOgoQCggEAwIACJwIABIEzQET
OQqsAQoEBAMCARIG0QEC1gEEGpsBIFJlcXVpcmVkLiBLTVMga2V5IHJlc291cmNlIG5hbWUg
d2hpY2ggd2lsbCBiZSB1c2VkIHRvIGVuY3J5cHQgcmVzb3VyY2VzCiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleVJpbmdzL3trZXlSaW5nfS9jcnlwdG9L
ZXlzL3trZXlJZH1gLgoKDQoFBAMCAQUSBNEBAggKDQoFBAMCAQESBNEBCRAKDQoFBAMCAQMS
BNEBExQKDwoFBAMCAQgSBtEBFdYBAwoQCggEAwIBCJwIABIE0gEEKgoRCgcEAwIBCJ8IEgbT
AQTVAQUKkwEKBAQDAgISBtsBAuABBBqCASBPdXRwdXQgb25seS4gS01TIGtleSB2ZXJzaW9u
IHJlc291cmNlIG5hbWUgd2hpY2ggd2lsbCBiZSB1c2VkIHRvIGVuY3J5cHQKIHJlc291cmNl
cwogYDxrbXNfa2V5Pi9jcnlwdG9LZXlWZXJzaW9ucy97a2V5VmVyc2lvbn1gLgoKDQoFBAMC
AgUSBNsBAggKDQoFBAMCAgESBNsBCRgKDQoFBAMCAgMSBNsBGxwKDwoFBAMCAggSBtsBHeAB
AwoQCggEAwICCJwIABIE3AEELQoRCgcEAwICCJ8IEgbdAQTfAQUKOgoEBAMCAxIE4wECPhos
IE91dHB1dCBvbmx5LiBUaGUgc3RhdGVzIG9mIHRoZSBDbWVrQ29uZmlnLgoKDQoFBAMCAwYS
BOMBAgcKDQoFBAMCAwESBOMBCA0KDQoFBAMCAwMSBOMBEBEKDQoFBAMCAwgSBOMBEj0KEAoI
BAMCAwicCAASBOMBEzwKRQoEBAMCBBIE5gECQho3IE91dHB1dCBvbmx5LiBUaGUgZGVmYXVs
dCBDbWVrQ29uZmlnIGZvciB0aGUgQ3VzdG9tZXIuCgoNCgUEAwIEBRIE5gECBgoNCgUEAwIE
ARIE5gEHEQoNCgUEAwIEAxIE5gEUFQoNCgUEAwIECBIE5gEWQQoQCggEAwIECJwIABIE5gEX
QApGCgQEAwIFEgbpAQLqATIaNiBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCBvZiB0aGUg
bGFzdCBrZXkgcm90YXRpb24uCgoNCgUEAwIFBRIE6QECBwoNCgUEAwIFARIE6QEIJgoNCgUE
AwIFAxIE6QEpKgoNCgUEAwIFCBIE6gEGMQoQCggEAwIFCJwIABIE6gEHMApbCgQEAwIGEgbt
AQLuAS8aSyBPcHRpb25hbC4gU2luZ2xlLXJlZ2lvbmFsIENNRUtzIHRoYXQgYXJlIHJlcXVp
cmVkIGZvciBzb21lIFZBSVMgZmVhdHVyZXMuCgoNCgUEAwIGBBIE7QECCgoNCgUEAwIGBhIE
7QELGgoNCgUEAwIGARIE7QEbLQoNCgUEAwIGAxIE7QEwMQoNCgUEAwIGCBIE7gEGLgoQCggE
AwIGCJwIABIE7gEHLQpRCgQEAwIHEgbxAQLyATIaQSBPdXRwdXQgb25seS4gV2hldGhlciB0
aGUgTm90ZWJvb2tMTSBDb3JwdXMgaXMgcmVhZHkgdG8gYmUgdXNlZC4KCg0KBQQDAgcGEgTx
AQIRCg0KBQQDAgcBEgTxARIiCg0KBQQDAgcDEgTxASUmCg0KBQQDAgcIEgTyAQYxChAKCAQD
AgcInAgAEgTyAQcwCv0BCgIEBBIG+QEAgAIBGu4BIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhl
IHByb2dyZXNzIG9mIHRoZQogW0NtZWtDb25maWdTZXJ2aWNlLlVwZGF0ZUNtZWtDb25maWdd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNtZWtDb25maWdTZXJ2aWNl
LlVwZGF0ZUNtZWtDb25maWddCiBvcGVyYXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBi
eSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoL
CgMEBAESBPkBCCAKJgoEBAQCABIE+wECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0K
BQQEAgAGEgT7AQIbCg0KBQQEAgABEgT7ARwnCg0KBQQEAgADEgT7ASorCmQKBAQEAgESBP8B
AiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBk
b25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQEAgEGEgT/AQIbCg0K
BQQEAgEBEgT/ARwnCg0KBQQEAgEDEgT/ASorCpkBCgIEBRIGhQIAkwIBGooBIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtDbWVrQ29uZmlnU2VydmljZS5MaXN0Q21la0NvbmZpZ3NdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNtZWtDb25maWdTZXJ2aWNlLkxpc3RD
bWVrQ29uZmlnc10KIG1ldGhvZC4KCgsKAwQFARIEhQIIHgrTAgoEBAUCABIGjQICkgIEGsIC
IFJlcXVpcmVkLiBUaGUgcGFyZW50IGxvY2F0aW9uIHJlc291cmNlIG5hbWUsIHN1Y2ggYXMK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKIElmIHRoZSBj
YWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGxpc3QKIFtDbWVrQ29uZmlnXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DbWVrQ29uZmlnXXMgdW5kZXIg
dGhpcwogbG9jYXRpb24sIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciBvciBub3QgYSBDbWVrQ29u
ZmlnIGV4aXN0cywgYQogUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgoN
CgUEBQIABRIEjQICCAoNCgUEBQIAARIEjQIJDwoNCgUEBQIAAxIEjQISEwoPCgUEBQIACBIG
jQIUkgIDChAKCAQFAgAInAgAEgSOAgQqChEKBwQFAgAInwgSBo8CBJECBQqaAQoCBAYSBpgC
AJwCARqLASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0NtZWtDb25maWdTZXJ2aWNlLkxpc3RD
bWVrQ29uZmlnc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ21la0Nv
bmZpZ1NlcnZpY2UuTGlzdENtZWtDb25maWdzXQogbWV0aG9kLgoKCwoDBAYBEgSYAggfCmIK
BAQGAgASBJsCAicaVCBBbGwgdGhlIGN1c3RvbWVyJ3MKIFtDbWVrQ29uZmlnXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DbWVrQ29uZmlnXXMuCgoNCgUEBgIABBIE
mwICCgoNCgUEBgIABhIEmwILFQoNCgUEBgIAARIEmwIWIgoNCgUEBgIAAxIEmwIlJgqbAQoC
BAcSBqECAKwCARqMASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ21la0NvbmZpZ1NlcnZpY2Uu
RGVsZXRlQ21la0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
Q21la0NvbmZpZ1NlcnZpY2UuRGVsZXRlQ21la0NvbmZpZ10KIG1ldGhvZC4KCgsKAwQHARIE
oQIIHwrNAQoEBAcCABIGpgICqwIEGrwBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUKIFtDbWVrQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5DbWVrQ29uZmlnXSB0byBkZWxldGUsCiBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NtZWtDb25maWdzL3tjbWVrX2NvbmZpZ31gLgoKDQoF
BAcCAAUSBKYCAggKDQoFBAcCAAESBKYCCQ0KDQoFBAcCAAMSBKYCEBEKDwoFBAcCAAgSBqYC
EqsCAwoQCggEBwIACJwIABIEpwIEKgoRCgcEBwIACJ8IEgaoAgSqAgUK/QEKAgQIEgayAgC5
AgEa7gEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBbQ21la0Nv
bmZpZ1NlcnZpY2UuRGVsZXRlQ21la0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuQ21la0NvbmZpZ1NlcnZpY2UuRGVsZXRlQ21la0NvbmZpZ10KIG9wZXJh
dGlvbi4gVGhpcyB3aWxsIGJlIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVsZC4KCgsKAwQIARIEsgIIIAomCgQECAIAEgS0AgIs
GhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAgCAAYSBLQCAhsKDQoFBAgCAAESBLQC
HCcKDQoFBAgCAAMSBLQCKisKZAoEBAgCARIEuAICLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0
ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZp
bmlzaCB0aW1lLgoKDQoFBAgCAQYSBLgCAhsKDQoFBAgCAQESBLgCHCcKDQoFBAgCAQMSBLgC
KitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest ===
    # Fields for UpdateCmekConfigRequest
    # Field: config Type: 11 (.google.cloud.discoveryengine.v1beta.CmekConfig)
    # Field: set_default Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::GetCmekConfigRequest ===
    # Fields for GetCmekConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::SingleRegionKey ===
    # Fields for SingleRegionKey
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig ===
    # Fields for CmekConfig
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()
    # Field: kms_key_version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1beta.CmekConfig.State)
    # Field: is_default Type: 8 ()
    # Field: last_rotation_timestamp_micros Type: 3 ()
    # Field: single_region_keys Type: 11 (.google.cloud.discoveryengine.v1beta.SingleRegionKey)
    # Field: notebooklm_state Type: 14 (.google.cloud.discoveryengine.v1beta.CmekConfig.NotebookLMState)

# Enum: CmekConfig::State
our $CmekConfig_STATE_UNSPECIFIED = 0;
our $CmekConfig_CREATING = 1;
our $CmekConfig_ACTIVE = 2;
our $CmekConfig_KEY_ISSUE = 3;
our $CmekConfig_DELETING = 4;
our $CmekConfig_DELETE_FAILED = 7;
our $CmekConfig_UNUSABLE = 5;
our $CmekConfig_ACTIVE_ROTATING = 6;
our $CmekConfig_DELETED = 8;
our $CmekConfig_EXPIRED = 9;

# Enum: CmekConfig::NotebookLMState
our $CmekConfig_NOTEBOOK_LM_STATE_UNSPECIFIED = 0;
our $CmekConfig_NOTEBOOK_LM_NOT_READY = 1;
our $CmekConfig_NOTEBOOK_LM_READY = 2;
our $CmekConfig_NOTEBOOK_LM_NOT_ENABLED = 3;

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigMetadata ===
    # Fields for UpdateCmekConfigMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::ListCmekConfigsRequest ===
    # Fields for ListCmekConfigsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::ListCmekConfigsResponse ===
    # Fields for ListCmekConfigsResponse
    # Field: cmek_configs Type: 11 (.google.cloud.discoveryengine.v1beta.CmekConfig)

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::DeleteCmekConfigRequest ===
    # Fields for DeleteCmekConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::DeleteCmekConfigMetadata ===
    # Fields for DeleteCmekConfigMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfigServiceClient

Client stub representing the remote C<CmekConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub update_cmek_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.CmekConfigService',
        method         => 'UpdateCmekConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_cmek_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::CmekConfigService::GetCmekConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.CmekConfigService',
        method         => 'GetCmekConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig',
    });
}

sub list_cmek_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::CmekConfigService::ListCmekConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.CmekConfigService',
        method         => 'ListCmekConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::CmekConfigService::ListCmekConfigsResponse',
    });
}

sub delete_cmek_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::CmekConfigService::DeleteCmekConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.CmekConfigService',
        method         => 'DeleteCmekConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::CmekConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/cmek_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::CmekConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest->new({
        config => $config,
        set_default => $set_default,
    });

    # Read or update a field
    my $val = $msg->config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/cmek_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest

Request message for UpdateCmekConfig method.
rpc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig>)

Required. The CmekConfig resource.

=item * C<< $msg->set_default() >> / C<< $msg->set_default($value) >>

Type: C<Bool>

Set the following CmekConfig as the default to be used for child
resources if one is not specified.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::GetCmekConfigRequest

Request message for GetCmekConfigRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of
[CmekConfig][google.cloud.discoveryengine.v1beta.CmekConfig], such as
`projects/*/locations/*/cmekConfig` or
`projects/*/locations/*/cmekConfigs/*`.

If the caller does not have permission to access the
[CmekConfig][google.cloud.discoveryengine.v1beta.CmekConfig], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::SingleRegionKey

Metadata for single-regional CMEKs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Required. Single-regional kms key resource name which will be used to
encrypt resources
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{keyId}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig

Configurations used to enable CMEK data encryption with Cloud KMS keys.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the CmekConfig of the form
`projects/{project}/locations/{location}/cmekConfig` or
`projects/{project}/locations/{location}/cmekConfigs/{cmek_config}`.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Required. KMS key resource name which will be used to encrypt resources
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{keyId}`.

=item * C<< $msg->kms_key_version() >> / C<< $msg->kms_key_version($value) >>

Type: C<String>

Output only. KMS key version resource name which will be used to encrypt
resources
`<kms_key>/cryptoKeyVersions/{keyVersion}`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::CmekConfig::State>)

Output only. The states of the CmekConfig.

=item * C<< $msg->is_default() >> / C<< $msg->is_default($value) >>

Type: C<Bool>

Output only. The default CmekConfig for the Customer.

=item * C<< $msg->last_rotation_timestamp_micros() >> / C<< $msg->last_rotation_timestamp_micros($value) >>

Type: C<Int64>

Output only. The timestamp of the last key rotation.

=item * C<< $msg->single_region_keys() >> / C<< $msg->single_region_keys($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::SingleRegionKey>)

Optional. Single-regional CMEKs that are required for some VAIS features.

=item * C<< $msg->notebooklm_state() >> / C<< $msg->notebooklm_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::CmekConfig::NotebookLMState>)

Output only. Whether the NotebookLM Corpus is ready to be used.

=back

=head3 Enum: CmekConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<KEY_ISSUE> => C<3>

=item * C<DELETING> => C<4>

=item * C<DELETE_FAILED> => C<7>

=item * C<UNUSABLE> => C<5>

=item * C<ACTIVE_ROTATING> => C<6>

=item * C<DELETED> => C<8>

=item * C<EXPIRED> => C<9>

=back

=head3 Enum: CmekConfig::NotebookLMState

=over 4

=item * C<NOTEBOOK_LM_STATE_UNSPECIFIED> => C<0>

=item * C<NOTEBOOK_LM_NOT_READY> => C<1>

=item * C<NOTEBOOK_LM_READY> => C<2>

=item * C<NOTEBOOK_LM_NOT_ENABLED> => C<3>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigMetadata

Metadata related to the progress of the
[CmekConfigService.UpdateCmekConfig][google.cloud.discoveryengine.v1beta.CmekConfigService.UpdateCmekConfig]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::ListCmekConfigsRequest

Request message for
[CmekConfigService.ListCmekConfigs][google.cloud.discoveryengine.v1beta.CmekConfigService.ListCmekConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location resource name, such as
`projects/{project}/locations/{location}`.

If the caller does not have permission to list
[CmekConfig][google.cloud.discoveryengine.v1beta.CmekConfig]s under this
location, regardless of whether or not a CmekConfig exists, a
PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::ListCmekConfigsResponse

Response message for
[CmekConfigService.ListCmekConfigs][google.cloud.discoveryengine.v1beta.CmekConfigService.ListCmekConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cmek_configs() >> / C<< $msg->cmek_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig>)

All the customer's
[CmekConfig][google.cloud.discoveryengine.v1beta.CmekConfig]s.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::DeleteCmekConfigRequest

Request message for
[CmekConfigService.DeleteCmekConfig][google.cloud.discoveryengine.v1beta.CmekConfigService.DeleteCmekConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[CmekConfig][google.cloud.discoveryengine.v1beta.CmekConfig] to delete,
such as
`projects/{project}/locations/{location}/cmekConfigs/{cmek_config}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::CmekConfigService::DeleteCmekConfigMetadata

Metadata related to the progress of the
[CmekConfigService.DeleteCmekConfig][google.cloud.discoveryengine.v1beta.CmekConfigService.DeleteCmekConfig]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
