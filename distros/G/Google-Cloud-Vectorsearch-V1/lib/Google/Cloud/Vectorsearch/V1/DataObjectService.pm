package Google::Cloud::Vectorsearch::V1::DataObjectService;

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
    eval { require Google::Cloud::Vectorsearch::V1::DataObject };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxL2RhdGFfb2JqZWN0X3NlcnZpY2UucHJv
dG8SHGdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2xvdWQv
dmVjdG9yc2VhcmNoL3YxL2RhdGFfb2JqZWN0LnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvItwBChdDcmVhdGVE
YXRhT2JqZWN0UmVxdWVzdBJGCgZwYXJlbnQYASABKAlCLuBBAvpBKAomdmVjdG9yc2VhcmNo
Lmdvb2dsZWFwaXMuY29tL0NvbGxlY3Rpb25SBnBhcmVudBIpCg5kYXRhX29iamVjdF9pZBgC
IAEoCUID4EECUgxkYXRhT2JqZWN0SWQSTgoLZGF0YV9vYmplY3QYAyABKAsyKC5nb29nbGUu
Y2xvdWQudmVjdG9yc2VhcmNoLnYxLkRhdGFPYmplY3RCA+BBAlIKZGF0YU9iamVjdCK/AQod
QmF0Y2hDcmVhdGVEYXRhT2JqZWN0c1JlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgK
JnZlY3RvcnNlYXJjaC5nb29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSVgoIcmVx
dWVzdHMYAiADKAsyNS5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkNyZWF0ZURhdGFP
YmplY3RSZXF1ZXN0QgPgQQJSCHJlcXVlc3RzInIKHkJhdGNoQ3JlYXRlRGF0YU9iamVjdHNS
ZXNwb25zZRJQCgxkYXRhX29iamVjdHMYASADKAsyKC5nb29nbGUuY2xvdWQudmVjdG9yc2Vh
cmNoLnYxLkRhdGFPYmplY3RCA+BBA1ILZGF0YU9iamVjdHMiWgoUR2V0RGF0YU9iamVjdFJl
cXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZ2ZWN0b3JzZWFyY2guZ29vZ2xlYXBpcy5j
b20vRGF0YU9iamVjdFIEbmFtZSKrAQoXVXBkYXRlRGF0YU9iamVjdFJlcXVlc3QSTgoLZGF0
YV9vYmplY3QYASABKAsyKC5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkRhdGFPYmpl
Y3RCA+BBAlIKZGF0YU9iamVjdBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayK/AQodQmF0Y2hVcGRhdGVEYXRhT2Jq
ZWN0c1JlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgKJnZlY3RvcnNlYXJjaC5nb29n
bGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSVgoIcmVxdWVzdHMYAiADKAsyNS5nb29n
bGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLlVwZGF0ZURhdGFPYmplY3RSZXF1ZXN0QgPgQQJS
CHJlcXVlc3RzIiAKHkJhdGNoVXBkYXRlRGF0YU9iamVjdHNSZXNwb25zZSJ2ChdEZWxldGVE
YXRhT2JqZWN0UmVxdWVzdBJCCgRuYW1lGAEgASgJQi7gQQL6QSgKJnZlY3RvcnNlYXJjaC5n
b29nbGVhcGlzLmNvbS9EYXRhT2JqZWN0UgRuYW1lEhcKBGV0YWcYAiABKAlCA+BBAVIEZXRh
ZyK/AQodQmF0Y2hEZWxldGVEYXRhT2JqZWN0c1JlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7g
QQL6QSgKJnZlY3RvcnNlYXJjaC5nb29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQS
VgoIcmVxdWVzdHMYAyADKAsyNS5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkRlbGV0
ZURhdGFPYmplY3RSZXF1ZXN0QgPgQQJSCHJlcXVlc3RzMtkNChFEYXRhT2JqZWN0U2Vydmlj
ZRLrAQoQQ3JlYXRlRGF0YU9iamVjdBI1Lmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEu
Q3JlYXRlRGF0YU9iamVjdFJlcXVlc3QaKC5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYx
LkRhdGFPYmplY3QidoLT5JMCTCI9L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jb2xsZWN0aW9ucy8qfS9kYXRhT2JqZWN0czoLZGF0YV9vYmplY3TaQSFwYXJlbnQsZGF0
YV9vYmplY3QsZGF0YV9vYmplY3RfaWQS6QEKFkJhdGNoQ3JlYXRlRGF0YU9iamVjdHMSOy5n
b29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkJhdGNoQ3JlYXRlRGF0YU9iamVjdHNSZXF1
ZXN0GjwuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MS5CYXRjaENyZWF0ZURhdGFPYmpl
Y3RzUmVzcG9uc2UiVILT5JMCTiJJL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jb2xsZWN0aW9ucy8qfS9kYXRhT2JqZWN0czpiYXRjaENyZWF0ZToBKhK7AQoNR2V0RGF0
YU9iamVjdBIyLmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEuR2V0RGF0YU9iamVjdFJl
cXVlc3QaKC5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkRhdGFPYmplY3QiTILT5JMC
PxI9L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
T2JqZWN0cy8qfdpBBG5hbWUS7QEKEFVwZGF0ZURhdGFPYmplY3QSNS5nb29nbGUuY2xvdWQu
dmVjdG9yc2VhcmNoLnYxLlVwZGF0ZURhdGFPYmplY3RSZXF1ZXN0GiguZ29vZ2xlLmNsb3Vk
LnZlY3RvcnNlYXJjaC52MS5EYXRhT2JqZWN0IniC0+STAlgySS92MS97ZGF0YV9vYmplY3Qu
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YU9iamVjdHMv
Kn06C2RhdGFfb2JqZWN02kEXZGF0YV9vYmplY3QsdXBkYXRlX21hc2sS+wEKFkJhdGNoVXBk
YXRlRGF0YU9iamVjdHMSOy5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkJhdGNoVXBk
YXRlRGF0YU9iamVjdHNSZXF1ZXN0GjwuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MS5C
YXRjaFVwZGF0ZURhdGFPYmplY3RzUmVzcG9uc2UiZoLT5JMCTiJJL3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qfS9kYXRhT2JqZWN0czpiYXRjaFVw
ZGF0ZToBKtpBD3BhcmVudCxyZXF1ZXN0cxKvAQoQRGVsZXRlRGF0YU9iamVjdBI1Lmdvb2ds
ZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEuRGVsZXRlRGF0YU9iamVjdFJlcXVlc3QaFi5nb29n
bGUucHJvdG9idWYuRW1wdHkiTILT5JMCPyo9L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovY29sbGVjdGlvbnMvKi9kYXRhT2JqZWN0cy8qfdpBBG5hbWUS1QEKFkJhdGNoRGVs
ZXRlRGF0YU9iamVjdHMSOy5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkJhdGNoRGVs
ZXRlRGF0YU9iamVjdHNSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5ImaC0+STAk4i
SS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKn0vZGF0
YU9iamVjdHM6YmF0Y2hEZWxldGU6ASraQQ9wYXJlbnQscmVxdWVzdHMaswHKQRt2ZWN0b3Jz
ZWFyY2guZ29vZ2xlYXBpcy5jb23SQZEBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3ZlY3Rv
cnNlYXJjaCxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3ZlY3RvcnNlYXJjaC5y
ZWFkb25seULiAQogY29tLmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFCFkRhdGFPYmpl
Y3RTZXJ2aWNlUHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby92ZWN0b3JzZWFyY2gvYXBp
djEvdmVjdG9yc2VhcmNocGI7dmVjdG9yc2VhcmNocGKqAhxHb29nbGUuQ2xvdWQuVmVjdG9y
U2VhcmNoLlYxygIcR29vZ2xlXENsb3VkXFZlY3RvclNlYXJjaFxWMeoCH0dvb2dsZTo6Q2xv
dWQ6OlZlY3RvclNlYXJjaDo6VjFKrzgKBxIFDgDzAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMU
ACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA4CgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMa
ADkKCQoCCCUSAxoAOQoICgEIEgMbAFsKCQoCCAsSAxsAWwoICgEIEgMcACIKCQoCCAoSAxwA
IgoICgEIEgMdADcKCQoCCAgSAx0ANwoICgEIEgMeADkKCQoCCAESAx4AOQoICgEIEgMfADkK
CQoCCCkSAx8AOQoICgEIEgMgADgKCQoCCC0SAyAAOAo9CgIGABIEIwBpARoxIFNlcnZpY2Ug
Zm9yIGNyZWF0aW5nIGFuZCBtYW5hZ2luZyBkYXRhIG9iamVjdHMuCgoKCgMGAAESAyMIGQoK
CgMGAAMSAyQCQwoMCgUGAAOZCBIDJAJDCgsKAwYAAxIEJQIoPgoNCgUGAAOaCBIEJQIoPgol
CgQGAAIAEgQrAjEDGhcgQ3JlYXRlcyBhIGRhdGFPYmplY3QuCgoMCgUGAAIAARIDKwYWCgwK
BQYAAgACEgMrFy4KDAoFBgACAAMSAys5QwoNCgUGAAIABBIELAQvBgoRCgkGAAIABLDKvCIS
BCwELwYKDAoFBgACAAQSAzAETwoPCggGAAIABJsIABIDMARPCi8KBAYAAgESBDQCOgMaISBD
cmVhdGVzIGEgYmF0Y2ggb2YgZGF0YU9iamVjdHMuCgoMCgUGAAIBARIDNAYcCgwKBQYAAgEC
EgM0HToKDAoFBgACAQMSAzUPLQoNCgUGAAIBBBIENgQ5BgoRCgkGAAIBBLDKvCISBDYEOQYK
IwoEBgACAhIEPQJCAxoVIEdldHMgYSBkYXRhIG9iamVjdC4KCgwKBQYAAgIBEgM9BhMKDAoF
BgACAgISAz0UKAoMCgUGAAICAxIDPTM9Cg0KBQYAAgIEEgQ+BEAGChEKCQYAAgIEsMq8IhIE
PgRABgoMCgUGAAICBBIDQQQyCg8KCAYAAgIEmwgAEgNBBDIKJQoEBgACAxIERQJLAxoXIFVw
ZGF0ZXMgYSBkYXRhT2JqZWN0LgoKDAoFBgACAwESA0UGFgoMCgUGAAIDAhIDRRcuCgwKBQYA
AgMDEgNFOUMKDQoFBgACAwQSBEYESQYKEQoJBgACAwSwyrwiEgRGBEkGCgwKBQYAAgMEEgNK
BEUKDwoIBgACAwSbCAASA0oERQovCgQGAAIEEgROAlUDGiEgVXBkYXRlcyBkYXRhT2JqZWN0
cyBpbiBhIGJhdGNoLgoKDAoFBgACBAESA04GHAoMCgUGAAIEAhIDTh06CgwKBQYAAgQDEgNP
Dy0KDQoFBgACBAQSBFAEUwYKEQoJBgACBASwyrwiEgRQBFMGCgwKBQYAAgQEEgNUBD0KDwoI
BgACBASbCAASA1QEPQolCgQGAAIFEgRYAl4DGhcgRGVsZXRlcyBhIGRhdGFPYmplY3QuCgoM
CgUGAAIFARIDWAYWCgwKBQYAAgUCEgNYFy4KDAoFBgACBQMSA1kPJAoNCgUGAAIFBBIEWgRc
BgoRCgkGAAIFBLDKvCISBFoEXAYKDAoFBgACBQQSA10EMgoPCggGAAIFBJsIABIDXQQyCi8K
BAYAAgYSBGECaAMaISBEZWxldGVzIGRhdGFPYmplY3RzIGluIGEgYmF0Y2guCgoMCgUGAAIG
ARIDYQYcCgwKBQYAAgYCEgNhHToKDAoFBgACBgMSA2IPJAoNCgUGAAIGBBIEYwRmBgoRCgkG
AAIGBLDKvCISBGMEZgYKDAoFBgACBgQSA2cEPQoPCggGAAIGBJsIABIDZwQ9CooBCgIEABIF
bQCAAQEafSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YU9iamVjdFNlcnZpY2UuQ3JlYXRl
RGF0YU9iamVjdF1bZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MS5EYXRhT2JqZWN0U2Vy
dmljZS5DcmVhdGVEYXRhT2JqZWN0XS4KCgoKAwQAARIDbQgfCqcBCgQEAAIAEgRwAnUEGpgB
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQ29sbGVjdGlvbiB0byBjcmVh
dGUgdGhlIERhdGFPYmplY3QgaW4uCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259YAoKDAoFBAACAAUS
A3ACCAoMCgUEAAIAARIDcAkPCgwKBQQAAgADEgNwEhMKDQoFBAACAAgSBHAUdQMKDwoIBAAC
AAicCAASA3EEKgoPCgcEAAIACJ8IEgRyBHQFCpsCCgQEAAIBEgN8AkUajQIgUmVxdWlyZWQu
IFRoZSBpZCBvZiB0aGUgZGF0YU9iamVjdCB0byBjcmVhdGUuCiBUaGUgaWQgbXVzdCBiZSAx
LTYzIGNoYXJhY3RlcnMgbG9uZywgYW5kIGNvbXBseSB3aXRoCiBbUkZDMTAzNV0oaHR0cHM6
Ly93d3cuaWV0Zi5vcmcvcmZjL3JmYzEwMzUudHh0KS4KIFNwZWNpZmljYWxseSwgaXQgbXVz
dCBiZSAxLTYzIGNoYXJhY3RlcnMgbG9uZyBhbmQgbWF0Y2ggdGhlIHJlZ3VsYXIKIGV4cHJl
c3Npb24gYFthLXpdKD86Wy1hLXowLTldezAsNjF9W2EtejAtOV0pP2AuCgoMCgUEAAIBBRID
fAIICgwKBQQAAgEBEgN8CRcKDAoFBAACAQMSA3waGwoMCgUEAAIBCBIDfBxECg8KCAQAAgEI
nAgAEgN8HUMKMgoEBAACAhIDfwJGGiUgUmVxdWlyZWQuIFRoZSBEYXRhT2JqZWN0IHRvIGNy
ZWF0ZS4KCgwKBQQAAgIGEgN/AgwKDAoFBAACAgESA38NGAoMCgUEAAICAxIDfxscCgwKBQQA
AgIIEgN/HUUKDwoIBAACAgicCAASA38eRAqYAQoCBAESBoQBAJQBARqJASBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbRGF0YU9iamVjdFNlcnZpY2UuQmF0Y2hDcmVhdGVEYXRhT2JqZWN0c11b
Z29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MS5EYXRhT2JqZWN0U2VydmljZS5CYXRjaENy
ZWF0ZURhdGFPYmplY3RzXS4KCgsKAwQBARIEhAEIJQr9AQoEBAECABIGiQECjgEEGuwBIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQ29sbGVjdGlvbiB0byBjcmVhdGUg
dGhlIERhdGFPYmplY3RzIGluLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufWAuCiBUaGUgcGFyZW50
IGZpZWxkIGluIHRoZSBDcmVhdGVEYXRhT2JqZWN0UmVxdWVzdCBtZXNzYWdlcyBtdXN0IG1h
dGNoIHRoaXMKIGZpZWxkLgoKDQoFBAECAAUSBIkBAggKDQoFBAECAAESBIkBCQ8KDQoFBAEC
AAMSBIkBEhMKDwoFBAECAAgSBokBFI4BAwoQCggEAQIACJwIABIEigEEKgoRCgcEAQIACJ8I
EgaLAQSNAQUKjQEKBAQBAgESBpIBApMBLxp9IFJlcXVpcmVkLiBUaGUgcmVxdWVzdCBtZXNz
YWdlIHNwZWNpZnlpbmcgdGhlIHJlc291cmNlcyB0byBjcmVhdGUuCiBBIG1heGltdW0gb2Yg
MTAwMCBEYXRhT2JqZWN0cyBjYW4gYmUgY3JlYXRlZCBpbiBhIGJhdGNoLgoKDQoFBAECAQQS
BJIBAgoKDQoFBAECAQYSBJIBCyIKDQoFBAECAQESBJIBIysKDQoFBAECAQMSBJIBLi8KDQoF
BAECAQgSBJMBBi4KEAoIBAECAQicCAASBJMBBy0KmQEKAgQCEgaYAQCcAQEaigEgUmVzcG9u
c2UgbWVzc2FnZSBmb3IKIFtEYXRhT2JqZWN0U2VydmljZS5CYXRjaENyZWF0ZURhdGFPYmpl
Y3RzXVtnb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkRhdGFPYmplY3RTZXJ2aWNlLkJh
dGNoQ3JlYXRlRGF0YU9iamVjdHNdLgoKCwoDBAIBEgSYAQgmCjMKBAQCAgASBpoBApsBMhoj
IE91dHB1dCBvbmx5LiBEYXRhT2JqZWN0cyBjcmVhdGVkLgoKDQoFBAICAAQSBJoBAgoKDQoF
BAICAAYSBJoBCxUKDQoFBAICAAESBJoBFiIKDQoFBAICAAMSBJoBJSYKDQoFBAICAAgSBJsB
BjEKEAoIBAICAAicCAASBJsBBzAKhQEKAgQDEgagAQCqAQEadyBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbRGF0YU9iamVjdFNlcnZpY2UuR2V0RGF0YU9iamVjdF1bZ29vZ2xlLmNsb3VkLnZl
Y3RvcnNlYXJjaC52MS5EYXRhT2JqZWN0U2VydmljZS5HZXREYXRhT2JqZWN0XS4KCgsKAwQD
ARIEoAEIHAqnAQoEBAMCABIGpAECqQEEGpYBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
RGF0YU9iamVjdCByZXNvdXJjZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFPYmplY3Rz
L3tkYXRhT2JqZWN0fWAKCg0KBQQDAgAFEgSkAQIICg0KBQQDAgABEgSkAQkNCg0KBQQDAgAD
EgSkARARCg8KBQQDAgAIEgakARKpAQMKEAoIBAMCAAicCAASBKUBBCoKEQoHBAMCAAifCBIG
pgEEqAEFCosBCgIEBBIGrgEAtgEBGn0gUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFPYmpl
Y3RTZXJ2aWNlLlVwZGF0ZURhdGFPYmplY3RdW2dvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gu
djEuRGF0YU9iamVjdFNlcnZpY2UuVXBkYXRlRGF0YU9iamVjdF0uCgoLCgMEBAESBK4BCB8K
UwoEBAQCABIEsAECRhpFIFJlcXVpcmVkLiBUaGUgRGF0YU9iamVjdCB3aGljaCByZXBsYWNl
cyB0aGUgcmVzb3VyY2Ugb24gdGhlIHNlcnZlci4KCg0KBQQEAgAGEgSwAQIMCg0KBQQEAgAB
EgSwAQ0YCg0KBQQEAgADEgSwARscCg0KBQQEAgAIEgSwAR1FChAKCAQEAgAInAgAEgSwAR5E
CoEBCgQEBAIBEga0AQK1AS8acSBPcHRpb25hbC4gVGhlIHVwZGF0ZSBtYXNrIGFwcGxpZXMg
dG8gdGhlIHJlc291cmNlLiBTZWUKIFtnb29nbGUucHJvdG9idWYuRmllbGRNYXNrXVtnb29n
bGUucHJvdG9idWYuRmllbGRNYXNrXS4KCg0KBQQEAgEGEgS0AQIbCg0KBQQEAgEBEgS0ARwn
Cg0KBQQEAgEDEgS0ASorCg0KBQQEAgEIEgS1AQYuChAKCAQEAgEInAgAEgS1AQctCpgBCgIE
BRIGugEAygEBGokBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEYXRhT2JqZWN0U2VydmljZS5C
YXRjaFVwZGF0ZURhdGFPYmplY3RzXVtnb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLkRh
dGFPYmplY3RTZXJ2aWNlLkJhdGNoVXBkYXRlRGF0YU9iamVjdHNdLgoKCwoDBAUBEgS6AQgl
Cv0BCgQEBQIAEga/AQLEAQQa7AEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZSBDb2xsZWN0aW9uIHRvIHVwZGF0ZSB0aGUgRGF0YU9iamVjdHMgaW4uCiBGb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2Nv
bGxlY3Rpb259YC4KIFRoZSBwYXJlbnQgZmllbGQgaW4gdGhlIFVwZGF0ZURhdGFPYmplY3RS
ZXF1ZXN0IG1lc3NhZ2VzIG11c3QgbWF0Y2ggdGhpcwogZmllbGQuCgoNCgUEBQIABRIEvwEC
CAoNCgUEBQIAARIEvwEJDwoNCgUEBQIAAxIEvwESEwoPCgUEBQIACBIGvwEUxAEDChAKCAQF
AgAInAgAEgTAAQQqChEKBwQFAgAInwgSBsEBBMMBBQqNAQoEBAUCARIGyAECyQEvGn0gUmVx
dWlyZWQuIFRoZSByZXF1ZXN0IG1lc3NhZ2Ugc3BlY2lmeWluZyB0aGUgcmVzb3VyY2VzIHRv
IHVwZGF0ZS4KIEEgbWF4aW11bSBvZiAxMDAwIERhdGFPYmplY3RzIGNhbiBiZSB1cGRhdGVk
IGluIGEgYmF0Y2guCgoNCgUEBQIBBBIEyAECCgoNCgUEBQIBBhIEyAELIgoNCgUEBQIBARIE
yAEjKwoNCgUEBQIBAxIEyAEuLwoNCgUEBQIBCBIEyQEGLgoQCggEBQIBCJwIABIEyQEHLQqX
AQoCBAYSBM4BACkaigEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtEYXRhT2JqZWN0U2Vydmlj
ZS5CYXRjaFVwZGF0ZURhdGFPYmplY3RzXVtnb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYx
LkRhdGFPYmplY3RTZXJ2aWNlLkJhdGNoVXBkYXRlRGF0YU9iamVjdHNdLgoKCwoDBAYBEgTO
AQgmCosBCgIEBxIG0gEA4QEBGn0gUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFPYmplY3RT
ZXJ2aWNlLkRlbGV0ZURhdGFPYmplY3RdW2dvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEu
RGF0YU9iamVjdFNlcnZpY2UuRGVsZXRlRGF0YU9iamVjdF0uCgoLCgMEBwESBNIBCB8KtQEK
BAQHAgASBtYBAtsBBBqkASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIERhdGFPYmplY3Qg
cmVzb3VyY2UgdG8gYmUgZGVsZXRlZC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFPYmpl
Y3RzL3tkYXRhT2JqZWN0fWAKCg0KBQQHAgAFEgTWAQIICg0KBQQHAgABEgTWAQkNCg0KBQQH
AgADEgTWARARCg8KBQQHAgAIEgbWARLbAQMKEAoIBAcCAAicCAASBNcBBCoKEQoHBAcCAAif
CBIG2AEE2gEFCs4BCgQEBwIBEgTgAQI7Gr8BIE9wdGlvbmFsLiBUaGUgY3VycmVudCBldGFn
IG9mIHRoZSBEYXRhT2JqZWN0LgogSWYgYW4gZXRhZyBpcyBwcm92aWRlZCBhbmQgZG9lcyBu
b3QgbWF0Y2ggdGhlIGN1cnJlbnQgZXRhZyBvZiB0aGUKIERhdGFPYmplY3QsIGRlbGV0aW9u
IHdpbGwgYmUgYmxvY2tlZCBhbmQgYW4gQUJPUlRFRCBlcnJvciB3aWxsIGJlIHJldHVybmVk
LgoKDQoFBAcCAQUSBOABAggKDQoFBAcCAQESBOABCQ0KDQoFBAcCAQMSBOABEBEKDQoFBAcC
AQgSBOABEjoKEAoIBAcCAQicCAASBOABEzkKmAEKAgQIEgblAQDzAQEaiQEgUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW0RhdGFPYmplY3RTZXJ2aWNlLkJhdGNoRGVsZXRlRGF0YU9iamVjdHNd
W2dvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEuRGF0YU9iamVjdFNlcnZpY2UuQmF0Y2hE
ZWxldGVEYXRhT2JqZWN0c10uCgoLCgMECAESBOUBCCUKqwEKBAQIAgASBugBAu0BBBqaASBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIENvbGxlY3Rpb24gdG8gZGVsZXRl
IHRoZSBEYXRhT2JqZWN0cyBpbi4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn1gLgoKDQoFBAgCAAUS
BOgBAggKDQoFBAgCAAESBOgBCQ8KDQoFBAgCAAMSBOgBEhMKDwoFBAgCAAgSBugBFO0BAwoQ
CggECAIACJwIABIE6QEEKgoRCgcECAIACJ8IEgbqAQTsAQUKjQEKBAQIAgESBvEBAvIBLxp9
IFJlcXVpcmVkLiBUaGUgcmVxdWVzdCBtZXNzYWdlIHNwZWNpZnlpbmcgdGhlIHJlc291cmNl
cyB0byBkZWxldGUuCiBBIG1heGltdW0gb2YgMTAwMCBEYXRhT2JqZWN0cyBjYW4gYmUgZGVs
ZXRlZCBpbiBhIGJhdGNoLgoKDQoFBAgCAQQSBPEBAgoKDQoFBAgCAQYSBPEBCyIKDQoFBAgC
AQESBPEBIysKDQoFBAgCAQMSBPEBLi8KDQoFBAgCAQgSBPIBBi4KEAoIBAgCAQicCAASBPIB
By1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::CreateDataObjectRequest ===
    # Fields for CreateDataObjectRequest
    # Field: parent Type: 9 ()
    # Field: data_object_id Type: 9 ()
    # Field: data_object Type: 11 (.google.cloud.vectorsearch.v1.DataObject)

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::BatchCreateDataObjectsRequest ===
    # Fields for BatchCreateDataObjectsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.vectorsearch.v1.CreateDataObjectRequest)

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::BatchCreateDataObjectsResponse ===
    # Fields for BatchCreateDataObjectsResponse
    # Field: data_objects Type: 11 (.google.cloud.vectorsearch.v1.DataObject)

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::GetDataObjectRequest ===
    # Fields for GetDataObjectRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::UpdateDataObjectRequest ===
    # Fields for UpdateDataObjectRequest
    # Field: data_object Type: 11 (.google.cloud.vectorsearch.v1.DataObject)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::BatchUpdateDataObjectsRequest ===
    # Fields for BatchUpdateDataObjectsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.vectorsearch.v1.UpdateDataObjectRequest)

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::BatchUpdateDataObjectsResponse ===
    # Fields for BatchUpdateDataObjectsResponse

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::DeleteDataObjectRequest ===
    # Fields for DeleteDataObjectRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Vectorsearch::V1::DataObjectService::BatchDeleteDataObjectsRequest ===
    # Fields for BatchDeleteDataObjectsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.vectorsearch.v1.DeleteDataObjectRequest)

# === Service Client: Google::Cloud::Vectorsearch::V1::DataObjectService::DataObjectServiceClient ===
package Google::Cloud::Vectorsearch::V1::DataObjectService::DataObjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Vectorsearch::V1::DataObjectService::DataObjectServiceClient

Client stub representing the remote C<DataObjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<vectorsearch.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'vectorsearch.googleapis.com:443' );

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

sub create_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::CreateDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'CreateDataObject',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1::DataObject::DataObject',
    });
}

sub batch_create_data_objects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::BatchCreateDataObjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'BatchCreateDataObjects',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1::DataObjectService::BatchCreateDataObjectsResponse',
    });
}

sub get_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::GetDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'GetDataObject',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1::DataObject::DataObject',
    });
}

sub update_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::UpdateDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'UpdateDataObject',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1::DataObject::DataObject',
    });
}

sub batch_update_data_objects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::BatchUpdateDataObjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'BatchUpdateDataObjects',
        request        => $req,
        response_class => 'Google::Cloud::Vectorsearch::V1::DataObjectService::BatchUpdateDataObjectsResponse',
    });
}

sub delete_data_object {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::DeleteDataObjectRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'DeleteDataObject',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub batch_delete_data_objects {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vectorsearch::V1::DataObjectService::BatchDeleteDataObjectsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vectorsearch.v1.DataObjectService',
        method         => 'BatchDeleteDataObjects',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1::DataObjectService - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1/data_object_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1::DataObjectService;

    my $msg = Google::Cloud::Vectorsearch::V1::DataObjectService::CreateDataObjectRequest->new({
        parent => $parent,
        data_object_id => $data_object_id,
        data_object => $data_object,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1::DataObjectService::CreateDataObjectRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1/data_object_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::CreateDataObjectRequest

Request message for
[DataObjectService.CreateDataObject][google.cloud.vectorsearch.v1.DataObjectService.CreateDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to create the DataObject in.
Format: `projects/{project}/locations/{location}/collections/{collection}`

=item * C<< $msg->data_object_id() >> / C<< $msg->data_object_id($value) >>

Type: C<String>

Required. The id of the dataObject to create.
The id must be 1-63 characters long, and comply with
[RFC1035](https://www.ietf.org/rfc/rfc1035.txt).
Specifically, it must be 1-63 characters long and match the regular
expression `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?`.

=item * C<< $msg->data_object() >> / C<< $msg->data_object($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObject::DataObject>)

Required. The DataObject to create.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::BatchCreateDataObjectsRequest

Request message for
[DataObjectService.BatchCreateDataObjects][google.cloud.vectorsearch.v1.DataObjectService.BatchCreateDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to create the DataObjects in.
Format: `projects/{project}/locations/{location}/collections/{collection}`.
The parent field in the CreateDataObjectRequest messages must match this
field.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObjectService::CreateDataObjectRequest>)

Required. The request message specifying the resources to create.
A maximum of 1000 DataObjects can be created in a batch.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::BatchCreateDataObjectsResponse

Response message for
[DataObjectService.BatchCreateDataObjects][google.cloud.vectorsearch.v1.DataObjectService.BatchCreateDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_objects() >> / C<< $msg->data_objects($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObject::DataObject>)

Output only. DataObjects created.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::GetDataObjectRequest

Request message for
[DataObjectService.GetDataObject][google.cloud.vectorsearch.v1.DataObjectService.GetDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DataObject resource.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataObjects/{dataObject}`

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::UpdateDataObjectRequest

Request message for
[DataObjectService.UpdateDataObject][google.cloud.vectorsearch.v1.DataObjectService.UpdateDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_object() >> / C<< $msg->data_object($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObject::DataObject>)

Required. The DataObject which replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The update mask applies to the resource. See
[google.protobuf.FieldMask][google.protobuf.FieldMask].

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::BatchUpdateDataObjectsRequest

Request message for
[DataObjectService.BatchUpdateDataObjects][google.cloud.vectorsearch.v1.DataObjectService.BatchUpdateDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to update the DataObjects in.
Format: `projects/{project}/locations/{location}/collections/{collection}`.
The parent field in the UpdateDataObjectRequest messages must match this
field.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObjectService::UpdateDataObjectRequest>)

Required. The request message specifying the resources to update.
A maximum of 1000 DataObjects can be updated in a batch.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::BatchUpdateDataObjectsResponse

Response message for
[DataObjectService.BatchUpdateDataObjects][google.cloud.vectorsearch.v1.DataObjectService.BatchUpdateDataObjects].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::DeleteDataObjectRequest

Request message for
[DataObjectService.DeleteDataObject][google.cloud.vectorsearch.v1.DataObjectService.DeleteDataObject].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DataObject resource to be deleted.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataObjects/{dataObject}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the DataObject.
If an etag is provided and does not match the current etag of the
DataObject, deletion will be blocked and an ABORTED error will be returned.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObjectService::BatchDeleteDataObjectsRequest

Request message for
[DataObjectService.BatchDeleteDataObjects][google.cloud.vectorsearch.v1.DataObjectService.BatchDeleteDataObjects].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Collection to delete the DataObjects in.
Format: `projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObjectService::DeleteDataObjectRequest>)

Required. The request message specifying the resources to delete.
A maximum of 1000 DataObjects can be deleted in a batch.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1::DataObjectService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
