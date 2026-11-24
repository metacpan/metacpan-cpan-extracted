package Google::Cloud::Apihub::V1::DiscoveryService;

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
    eval { require Google::Cloud::Apihub::V1::CommonFields };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYXBpaHViL3YxL2Rpc2NvdmVyeV9zZXJ2aWNlLnByb3RvEhZnb29n
bGUuY2xvdWQuYXBpaHViLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoqZ29vZ2xlL2Nsb3VkL2FwaWh1Yi92MS9jb21t
b25fZmllbGRzLnByb3RvIrwBCiRMaXN0RGlzY292ZXJlZEFwaU9ic2VydmF0aW9uc1JlcXVl
c3QSTgoGcGFyZW50GAEgASgJQjbgQQL6QTASLmFwaWh1Yi5nb29nbGVhcGlzLmNvbS9EaXNj
b3ZlcmVkQXBpT2JzZXJ2YXRpb25SBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVII
cGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4iwQEKJUxpc3RE
aXNjb3ZlcmVkQXBpT2JzZXJ2YXRpb25zUmVzcG9uc2UScAobZGlzY292ZXJlZF9hcGlfb2Jz
ZXJ2YXRpb25zGAEgAygLMjAuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5EaXNjb3ZlcmVkQXBp
T2JzZXJ2YXRpb25SGWRpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMSJgoPbmV4dF9wYWdlX3Rv
a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrgBCiJMaXN0RGlzY292ZXJlZEFwaU9wZXJhdGlv
bnNSZXF1ZXN0EkwKBnBhcmVudBgBIAEoCUI04EEC+kEuEixhcGlodWIuZ29vZ2xlYXBpcy5j
b20vRGlzY292ZXJlZEFwaU9wZXJhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID
4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiK5AQoj
TGlzdERpc2NvdmVyZWRBcGlPcGVyYXRpb25zUmVzcG9uc2USagoZZGlzY292ZXJlZF9hcGlf
b3BlcmF0aW9ucxgBIAMoCzIuLmdvb2dsZS5jbG91ZC5hcGlodWIudjEuRGlzY292ZXJlZEFw
aU9wZXJhdGlvblIXZGlzY292ZXJlZEFwaU9wZXJhdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuInAKIkdldERpc2NvdmVyZWRBcGlPYnNlcnZhdGlvblJl
cXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5hcGlodWIuZ29vZ2xlYXBpcy5jb20vRGlz
Y292ZXJlZEFwaU9ic2VydmF0aW9uUgRuYW1lImwKIEdldERpc2NvdmVyZWRBcGlPcGVyYXRp
b25SZXF1ZXN0EkgKBG5hbWUYASABKAlCNOBBAvpBLgosYXBpaHViLmdvb2dsZWFwaXMuY29t
L0Rpc2NvdmVyZWRBcGlPcGVyYXRpb25SBG5hbWUymggKD0FwaUh1YkRpc2NvdmVyeRLsAQod
TGlzdERpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMSPC5nb29nbGUuY2xvdWQuYXBpaHViLnYx
Lkxpc3REaXNjb3ZlcmVkQXBpT2JzZXJ2YXRpb25zUmVxdWVzdBo9Lmdvb2dsZS5jbG91ZC5h
cGlodWIudjEuTGlzdERpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnNSZXNwb25zZSJOgtPkkwI/
Ej0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kaXNjb3ZlcmVkQXBpT2Jz
ZXJ2YXRpb25z2kEGcGFyZW50EtkBChtHZXREaXNjb3ZlcmVkQXBpT2JzZXJ2YXRpb24SOi5n
b29nbGUuY2xvdWQuYXBpaHViLnYxLkdldERpc2NvdmVyZWRBcGlPYnNlcnZhdGlvblJlcXVl
c3QaMC5nb29nbGUuY2xvdWQuYXBpaHViLnYxLkRpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbiJM
gtPkkwI/Ej0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kaXNjb3ZlcmVkQXBp
T2JzZXJ2YXRpb25zLyp92kEEbmFtZRKAAgobTGlzdERpc2NvdmVyZWRBcGlPcGVyYXRpb25z
EjouZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5MaXN0RGlzY292ZXJlZEFwaU9wZXJhdGlvbnNS
ZXF1ZXN0GjsuZ29vZ2xlLmNsb3VkLmFwaWh1Yi52MS5MaXN0RGlzY292ZXJlZEFwaU9wZXJh
dGlvbnNSZXNwb25zZSJogtPkkwJZElcvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2Rpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMvKn0vZGlzY292ZXJlZEFwaU9wZXJhdGlv
bnPaQQZwYXJlbnQS7QEKGUdldERpc2NvdmVyZWRBcGlPcGVyYXRpb24SOC5nb29nbGUuY2xv
dWQuYXBpaHViLnYxLkdldERpc2NvdmVyZWRBcGlPcGVyYXRpb25SZXF1ZXN0Gi4uZ29vZ2xl
LmNsb3VkLmFwaWh1Yi52MS5EaXNjb3ZlcmVkQXBpT3BlcmF0aW9uImaC0+STAlkSVy92MS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMv
Ki9kaXNjb3ZlcmVkQXBpT3BlcmF0aW9ucy8qfdpBBG5hbWUaScpBFWFwaWh1Yi5nb29nbGVh
cGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZv
cm1CtwEKGmNvbS5nb29nbGUuY2xvdWQuYXBpaHViLnYxQhVEaXNjb3ZlcnlTZXJ2aWNlUHJv
dG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlodWIvYXBpdjEvYXBpaHVicGI7YXBpaHVi
cGKqAhZHb29nbGUuQ2xvdWQuQXBpSHViLlYxygIWR29vZ2xlXENsb3VkXEFwaUh1YlxWMeoC
GUdvb2dsZTo6Q2xvdWQ6OkFwaUh1Yjo6VjFKoCoKBxIFDgCxAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA0CggKAQgSAxgAMwoJCgIIJRIDGAAzCggK
AQgSAxkASQoJCgIICxIDGQBJCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsANgoJCgII
CBIDGwA2CggKAQgSAxwAMwoJCgIIARIDHAAzCggKAQgSAx0AMwoJCgIIKRIDHQAzCggKAQgS
Ax4AMgoJCgIILRIDHgAyCnEKAgYAEgQiAE0BGmUgVGhpcyBzZXJ2aWNlIGV4cG9zZXMgbWV0
aG9kcyB1c2VkIHRvIG1hbmFnZSBEaXNjb3ZlcmVkQXBpT2JzZXJ2YXRpb25zCiBhbmQgRGlz
Y292ZXJlZEFwaU9wZXJhdGlvbnMuCgoKCgMGAAESAyIIFwoKCgMGAAMSAyMCPQoMCgUGAAOZ
CBIDIwI9CgsKAwYAAxIEJAIlNwoNCgUGAAOaCBIEJAIlNwpYCgQGAAIAEgQoAi4DGkogTGlz
dHMgYWxsIHRoZSBEaXNjb3ZlcmVkQVBJT2JzZXJ2YXRpb25zIGluIGEgZ2l2ZW4gcHJvamVj
dCBhbmQgbG9jYXRpb24uCgoMCgUGAAIAARIDKAYjCgwKBQYAAgACEgMoJEgKDAoFBgACAAMS
AykPNAoNCgUGAAIABBIEKgQsBgoRCgkGAAIABLDKvCISBCoELAYKDAoFBgACAAQSAy0ENAoP
CggGAAIABJsIABIDLQQ0CmEKBAYAAgESBDICOAMaUyBHZXRzIGEgRGlzY292ZXJlZEFQSU9i
c2VydmF0aW9uIGluIGEgZ2l2ZW4gcHJvamVjdCwgbG9jYXRpb24gYW5kCiBBcGlPYnNlcnZh
dGlvbi4KCgwKBQYAAgEBEgMyBiEKDAoFBgACAQISAzIiRAoMCgUGAAIBAxIDMw8nCg0KBQYA
AgEEEgQ0BDYGChEKCQYAAgEEsMq8IhIENAQ2BgoMCgUGAAIBBBIDNwQyCg8KCAYAAgEEmwgA
EgM3BDIKZwoEBgACAhIEPAJCAxpZIExpc3RzIGFsbCB0aGUgRGlzY292ZXJlZEFQSU9wZXJh
dGlvbnMgaW4gYSBnaXZlbiBwcm9qZWN0LCBsb2NhdGlvbiBhbmQKIEFwaU9ic2VydmF0aW9u
LgoKDAoFBgACAgESAzwGIQoMCgUGAAICAhIDPCJECgwKBQYAAgIDEgM9DzIKDQoFBgACAgQS
BD4EQAYKEQoJBgACAgSwyrwiEgQ+BEAGCgwKBQYAAgIEEgNBBDQKDwoIBgACAgSbCAASA0EE
NAptCgQGAAIDEgRGAkwDGl8gR2V0cyBhIERpc2NvdmVyZWRBUElPcGVyYXRpb24gaW4gYSBn
aXZlbiBwcm9qZWN0LCBsb2NhdGlvbiwKIEFwaU9ic2VydmF0aW9uIGFuZCBBcGlPcGVyYXRp
b24uCgoMCgUGAAIDARIDRgYfCgwKBQYAAgMCEgNGIEAKDAoFBgACAwMSA0cPJQoNCgUGAAID
BBIESARKBgoRCgkGAAIDBLDKvCISBEgESgYKDAoFBgACAwQSA0sEMgoPCggGAAIDBJsIABID
SwQyCkYKAgQAEgRQAGgBGjogTWVzc2FnZSBmb3IgcmVxdWVzdGluZyBsaXN0IG9mIERpc2Nv
dmVyZWRBcGlPYnNlcnZhdGlvbnMKCgoKAwQAARIDUAgsCoYBCgQEAAIAEgRUAlkEGnggUmVx
dWlyZWQuIFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mIEFwaU9i
c2VydmF0aW9ucy4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufQoKDAoFBAACAAUSA1QCCAoMCgUEAAIAARIDVAkPCgwKBQQAAgADEgNUEhMKDQoF
BAACAAgSBFQUWQMKDwoIBAACAAicCAASA1UEKgoPCgcEAAIACJ8IEgRWBFgFCv4BCgQEAAIB
EgNfAj8a8AEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBBcGlPYnNlcnZhdGlv
bnMgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMg
dmFsdWUuIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDEwCiBBcGlPYnNlcnZhdGlvbnMgd2ls
bCBiZSByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzCiBhYm92
ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDAoFBAACAQUSA18CBwoMCgUEAAIB
ARIDXwgRCgwKBQQAAgEDEgNfFBUKDAoFBAACAQgSA18WPgoPCggEAAIBCJwIABIDXxc9CokC
CgQEAAICEgNnAkEa+wEgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBh
IHByZXZpb3VzIGBMaXN0QXBpT2JzZXJ2YXRpb25zYAogY2FsbC4gUHJvdmlkZSB0aGlzIHRv
IHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwg
b3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogYExpc3RBcGlPYnNlcnZhdGlvbnNgIG11
c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZQogdG9rZW4uCgoMCgUE
AAICBRIDZwIICgwKBQQAAgIBEgNnCRMKDAoFBAACAgMSA2cWFwoMCgUEAAICCBIDZxhACg8K
CAQAAgIInAgAEgNnGT8KRwoCBAESBGsAcgEaOyBNZXNzYWdlIGZvciByZXNwb25zZSB0byBs
aXN0aW5nIERpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMKCgoKAwQBARIDawgtClQKBAQBAgAS
A20CRBpHIFRoZSBEaXNjb3ZlcmVkQXBpT2JzZXJ2YXRpb24gZnJvbSB0aGUgc3BlY2lmaWVk
IHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBAECAAQSA20CCgoMCgUEAQIABhIDbQsjCgwK
BQQBAgABEgNtJD8KDAoFBAECAAMSA21CQwqPAQoEBAECARIDcQIdGoEBIEEgdG9rZW4sIHdo
aWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBw
YWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVu
dCBwYWdlcy4KCgwKBQQBAgEFEgNxAggKDAoFBAECAQESA3EJGAoMCgUEAQIBAxIDcRscCkUK
AgQCEgV1AIwBARo4IE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgbGlzdCBvZiBEaXNjb3ZlcmVk
QXBpT3BlcmF0aW9ucwoKCgoDBAIBEgN1CCoKxgEKBAQCAgASBHkCfgQatwEgUmVxdWlyZWQu
IFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mCiBEaXNjb3ZlcmVk
QXBpT3BlcmF0aW9ucy4gRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2Rpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMve2Rpc2NvdmVyZWRfYXBpX29i
c2VydmF0aW9ufQoKDAoFBAICAAUSA3kCCAoMCgUEAgIAARIDeQkPCgwKBQQCAgADEgN5EhMK
DQoFBAICAAgSBHkUfgMKDwoIBAICAAicCAASA3oEKgoPCgcEAgIACJ8IEgR7BH0FCooBCgQE
AgIBEgSCAQI/GnwgT3B0aW9uYWwuIERpc2NvdmVyZWRBcGlPcGVyYXRpb25zIHdpbGwgYmUg
cmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlzCiAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAw
MCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCg0KBQQCAgEFEgSCAQIHCg0KBQQCAgEBEgSC
AQgRCg0KBQQCAgEDEgSCARQVCg0KBQQCAgEIEgSCARY+ChAKCAQCAgEInAgAEgSCARc9CqEC
CgQEAgICEgSLAQJBGpICIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20g
YSBwcmV2aW91cwogYExpc3REaXNjb3ZlcmVkQXBpQXBpT3BlcmF0aW9uc2AgY2FsbC4gUHJv
dmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZQogc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFn
aW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8KIGBMaXN0RGlzY292
ZXJlZEFwaUFwaU9wZXJhdGlvbnNgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRl
ZCB0aGUgcGFnZQogdG9rZW4uCgoNCgUEAgICBRIEiwECCAoNCgUEAgICARIEiwEJEwoNCgUE
AgICAxIEiwEWFwoNCgUEAgICCBIEiwEYQAoQCggEAgICCJwIABIEiwEZPwpHCgIEAxIGjwEA
lwEBGjkgTWVzc2FnZSBmb3IgcmVzcG9uc2UgdG8gbGlzdGluZyBEaXNjb3ZlcmVkQXBpT3Bl
cmF0aW9ucwoKCwoDBAMBEgSPAQgrCm8KBAQDAgASBJIBAkAaYSBUaGUgRGlzY292ZXJlZEFw
aU9wZXJhdGlvbnMgZnJvbSB0aGUgc3BlY2lmaWVkIHByb2plY3QsIGxvY2F0aW9uCiBhbmQg
RGlzY292ZXJlZEFwaU9ic2VydmF0aW9uLgoKDQoFBAMCAAQSBJIBAgoKDQoFBAMCAAYSBJIB
CyEKDQoFBAMCAAESBJIBIjsKDQoFBAMCAAMSBJIBPj8KkAEKBAQDAgESBJYBAh0agQEgQSB0
b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRo
ZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBz
dWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAMCAQUSBJYBAggKDQoFBAMCAQESBJYBCRgKDQoFBAMC
AQMSBJYBGxwKQQoCBAQSBpoBAKQBARozIE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgYSBEaXNj
b3ZlcmVkQXBpT2JzZXJ2YXRpb24KCgsKAwQEARIEmgEIKgq7AQoEBAQCABIGngECowEEGqoB
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgRGlzY292ZXJlZEFwaU9ic2VydmF0aW9uIHRv
IHJldHJpZXZlLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2Rpc2NvdmVyZWRBcGlPYnNlcnZhdGlvbnMve2Rpc2NvdmVyZWRfYXBpX29ic2Vy
dmF0aW9ufQoKDQoFBAQCAAUSBJ4BAggKDQoFBAQCAAESBJ4BCQ0KDQoFBAQCAAMSBJ4BEBEK
DwoFBAQCAAgSBp4BEqMBAwoQCggEBAIACJwIABIEnwEEKgoRCgcEBAIACJ8IEgagAQSiAQUK
PwoCBAUSBqcBALEBARoxIE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgYSBEaXNjb3ZlcmVkQXBp
T3BlcmF0aW9uCgoLCgMEBQESBKcBCCgK7AEKBAQFAgASBqsBArABBBrbASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIERpc2NvdmVyZWRBcGlPcGVyYXRpb24gdG8gcmV0cmlldmUuCiBG
b3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGlzY292
ZXJlZEFwaU9ic2VydmF0aW9ucy97ZGlzY292ZXJlZF9hcGlfb2JzZXJ2YXRpb259L2Rpc2Nv
dmVyZWRBcGlPcGVyYXRpb25zL3tkaXNjb3ZlcmVkX2FwaV9vcGVyYXRpb259CgoNCgUEBQIA
BRIEqwECCAoNCgUEBQIAARIEqwEJDQoNCgUEBQIAAxIEqwEQEQoPCgUEBQIACBIGqwESsAED
ChAKCAQFAgAInAgAEgSsAQQqChEKBwQFAgAInwgSBq0BBK8BBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest ===
    # Fields for ListDiscoveredApiObservationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse ===
    # Fields for ListDiscoveredApiObservationsResponse
    # Field: discovered_api_observations Type: 11 (.google.cloud.apihub.v1.DiscoveredApiObservation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsRequest ===
    # Fields for ListDiscoveredApiOperationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsResponse ===
    # Fields for ListDiscoveredApiOperationsResponse
    # Field: discovered_api_operations Type: 11 (.google.cloud.apihub.v1.DiscoveredApiOperation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiObservationRequest ===
    # Fields for GetDiscoveredApiObservationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiOperationRequest ===
    # Fields for GetDiscoveredApiOperationRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Apihub::V1::DiscoveryService::ApiHubDiscoveryClient ===
package Google::Cloud::Apihub::V1::DiscoveryService::ApiHubDiscoveryClient;

=pod

=head2 Service Client: Google::Cloud::Apihub::V1::DiscoveryService::ApiHubDiscoveryClient

Client stub representing the remote C<ApiHubDiscovery> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_discovered_api_observations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubDiscovery',
        method         => 'ListDiscoveredApiObservations',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse',
    });
}

sub get_discovered_api_observation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiObservationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubDiscovery',
        method         => 'GetDiscoveredApiObservation',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiObservation',
    });
}

sub list_discovered_api_operations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubDiscovery',
        method         => 'ListDiscoveredApiOperations',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsResponse',
    });
}

sub get_discovered_api_operation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiOperationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apihub.v1.ApiHubDiscovery',
        method         => 'GetDiscoveredApiOperation',
        request        => $req,
        response_class => 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apihub::V1::DiscoveryService - Compiled Protocol Buffers messages for google/cloud/apihub/v1/discovery_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::DiscoveryService;

    my $msg = Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apihub/v1/discovery_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest

Message for requesting list of DiscoveredApiObservations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of ApiObservations.
Format:
projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of ApiObservations to return. The service may
return fewer than this value. If unspecified, at most 10
ApiObservations will be returned. The maximum value is 1000; values
above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListApiObservations`
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`ListApiObservations` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse

Message for response to listing DiscoveredApiObservations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->discovered_api_observations() >> / C<< $msg->discovered_api_observations($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiObservation>)

The DiscoveredApiObservation from the specified project and location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsRequest

Message for requesting list of DiscoveredApiOperations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of
DiscoveredApiOperations. Format:
projects/{project}/locations/{location}/discoveredApiObservations/{discovered_api_observation}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. DiscoveredApiOperations will be returned. The maximum value is
1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListDiscoveredApiApiOperations` call. Provide this to retrieve the
subsequent page.

When paginating, all other parameters provided to
`ListDiscoveredApiApiOperations` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsResponse

Message for response to listing DiscoveredApiOperations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->discovered_api_operations() >> / C<< $msg->discovered_api_operations($value) >>

Type: C<Message> (L<Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation>)

The DiscoveredApiOperations from the specified project, location
and DiscoveredApiObservation.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiObservationRequest

Message for requesting a DiscoveredApiObservation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DiscoveredApiObservation to retrieve.
Format:
projects/{project}/locations/{location}/discoveredApiObservations/{discovered_api_observation}

=back

=head2 Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiOperationRequest

Message for requesting a DiscoveredApiOperation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DiscoveredApiOperation to retrieve.
Format:
projects/{project}/locations/{location}/discoveredApiObservations/{discovered_api_observation}/discoveredApiOperations/{discovered_api_operation}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apihub::V1::DiscoveryService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
