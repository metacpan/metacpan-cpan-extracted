package Google::Monitoring::V3::UptimeService;

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
    eval { require Google::Monitoring::V3::Uptime };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvbW9uaXRvcmluZy92My91cHRpbWVfc2VydmljZS5wcm90bxIUZ29vZ2xlLm1v
bml0b3JpbmcudjMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkv
Y2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGiFnb29nbGUvbW9uaXRvcmluZy92My91cHRpbWUucHJvdG8a
G2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21h
c2sucHJvdG8iwAEKHUxpc3RVcHRpbWVDaGVja0NvbmZpZ3NSZXF1ZXN0EksKBnBhcmVudBgB
IAEoCUIz4EEC+kEtEittb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL1VwdGltZUNoZWNrQ29u
ZmlnUgZwYXJlbnQSFgoGZmlsdGVyGAIgASgJUgZmaWx0ZXISGwoJcGFnZV9zaXplGAMgASgF
UghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAQgASgJUglwYWdlVG9rZW4iwgEKHkxpc3RVcHRp
bWVDaGVja0NvbmZpZ3NSZXNwb25zZRJZChR1cHRpbWVfY2hlY2tfY29uZmlncxgBIAMoCzIn
Lmdvb2dsZS5tb25pdG9yaW5nLnYzLlVwdGltZUNoZWNrQ29uZmlnUhJ1cHRpbWVDaGVja0Nv
bmZpZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEh0KCnRvdGFs
X3NpemUYAyABKAVSCXRvdGFsU2l6ZSJmChtHZXRVcHRpbWVDaGVja0NvbmZpZ1JlcXVlc3QS
RwoEbmFtZRgBIAEoCUIz4EEC+kEtCittb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL1VwdGlt
ZUNoZWNrQ29uZmlnUgRuYW1lIssBCh5DcmVhdGVVcHRpbWVDaGVja0NvbmZpZ1JlcXVlc3QS
SwoGcGFyZW50GAEgASgJQjPgQQL6QS0SK21vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vVXB0
aW1lQ2hlY2tDb25maWdSBnBhcmVudBJcChN1cHRpbWVfY2hlY2tfY29uZmlnGAIgASgLMicu
Z29vZ2xlLm1vbml0b3JpbmcudjMuVXB0aW1lQ2hlY2tDb25maWdCA+BBAlIRdXB0aW1lQ2hl
Y2tDb25maWciuwEKHlVwZGF0ZVVwdGltZUNoZWNrQ29uZmlnUmVxdWVzdBI7Cgt1cGRhdGVf
bWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sSXAoT
dXB0aW1lX2NoZWNrX2NvbmZpZxgDIAEoCzInLmdvb2dsZS5tb25pdG9yaW5nLnYzLlVwdGlt
ZUNoZWNrQ29uZmlnQgPgQQJSEXVwdGltZUNoZWNrQ29uZmlnImkKHkRlbGV0ZVVwdGltZUNo
ZWNrQ29uZmlnUmVxdWVzdBJHCgRuYW1lGAEgASgJQjPgQQL6QS0KK21vbml0b3JpbmcuZ29v
Z2xlYXBpcy5jb20vVXB0aW1lQ2hlY2tDb25maWdSBG5hbWUiVwoZTGlzdFVwdGltZUNoZWNr
SXBzUmVxdWVzdBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
AyABKAlSCXBhZ2VUb2tlbiKTAQoaTGlzdFVwdGltZUNoZWNrSXBzUmVzcG9uc2USTQoQdXB0
aW1lX2NoZWNrX2lwcxgBIAMoCzIjLmdvb2dsZS5tb25pdG9yaW5nLnYzLlVwdGltZUNoZWNr
SXBSDnVwdGltZUNoZWNrSXBzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbjK9CgoSVXB0aW1lQ2hlY2tTZXJ2aWNlEsABChZMaXN0VXB0aW1lQ2hlY2tDb25maWdz
EjMuZ29vZ2xlLm1vbml0b3JpbmcudjMuTGlzdFVwdGltZUNoZWNrQ29uZmlnc1JlcXVlc3Qa
NC5nb29nbGUubW9uaXRvcmluZy52My5MaXN0VXB0aW1lQ2hlY2tDb25maWdzUmVzcG9uc2Ui
O4LT5JMCLBIqL3YzL3twYXJlbnQ9cHJvamVjdHMvKn0vdXB0aW1lQ2hlY2tDb25maWdz2kEG
cGFyZW50Eq0BChRHZXRVcHRpbWVDaGVja0NvbmZpZxIxLmdvb2dsZS5tb25pdG9yaW5nLnYz
LkdldFVwdGltZUNoZWNrQ29uZmlnUmVxdWVzdBonLmdvb2dsZS5tb25pdG9yaW5nLnYzLlVw
dGltZUNoZWNrQ29uZmlnIjmC0+STAiwSKi92My97bmFtZT1wcm9qZWN0cy8qL3VwdGltZUNo
ZWNrQ29uZmlncy8qfdpBBG5hbWUS3gEKF0NyZWF0ZVVwdGltZUNoZWNrQ29uZmlnEjQuZ29v
Z2xlLm1vbml0b3JpbmcudjMuQ3JlYXRlVXB0aW1lQ2hlY2tDb25maWdSZXF1ZXN0GicuZ29v
Z2xlLm1vbml0b3JpbmcudjMuVXB0aW1lQ2hlY2tDb25maWciZILT5JMCQSIqL3YzL3twYXJl
bnQ9cHJvamVjdHMvKn0vdXB0aW1lQ2hlY2tDb25maWdzOhN1cHRpbWVfY2hlY2tfY29uZmln
2kEacGFyZW50LHVwdGltZV9jaGVja19jb25maWcS6wEKF1VwZGF0ZVVwdGltZUNoZWNrQ29u
ZmlnEjQuZ29vZ2xlLm1vbml0b3JpbmcudjMuVXBkYXRlVXB0aW1lQ2hlY2tDb25maWdSZXF1
ZXN0GicuZ29vZ2xlLm1vbml0b3JpbmcudjMuVXB0aW1lQ2hlY2tDb25maWcicYLT5JMCVTI+
L3YzL3t1cHRpbWVfY2hlY2tfY29uZmlnLm5hbWU9cHJvamVjdHMvKi91cHRpbWVDaGVja0Nv
bmZpZ3MvKn06E3VwdGltZV9jaGVja19jb25maWfaQRN1cHRpbWVfY2hlY2tfY29uZmlnEqIB
ChdEZWxldGVVcHRpbWVDaGVja0NvbmZpZxI0Lmdvb2dsZS5tb25pdG9yaW5nLnYzLkRlbGV0
ZVVwdGltZUNoZWNrQ29uZmlnUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI5gtPk
kwIsKiovdjMve25hbWU9cHJvamVjdHMvKi91cHRpbWVDaGVja0NvbmZpZ3MvKn3aQQRuYW1l
EpMBChJMaXN0VXB0aW1lQ2hlY2tJcHMSLy5nb29nbGUubW9uaXRvcmluZy52My5MaXN0VXB0
aW1lQ2hlY2tJcHNSZXF1ZXN0GjAuZ29vZ2xlLm1vbml0b3JpbmcudjMuTGlzdFVwdGltZUNo
ZWNrSXBzUmVzcG9uc2UiGoLT5JMCFBISL3YzL3VwdGltZUNoZWNrSXBzGqkBykEZbW9uaXRv
cmluZy5nb29nbGVhcGlzLmNvbdJBiQFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvbW9uaXRv
cmluZyxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vbml0b3JpbmcucmVhZELN
AQoYY29tLmdvb2dsZS5tb25pdG9yaW5nLnYzQhJVcHRpbWVTZXJ2aWNlUHJvdG9QAVpBY2xv
dWQuZ29vZ2xlLmNvbS9nby9tb25pdG9yaW5nL2FwaXYzL3YyL21vbml0b3JpbmdwYjttb25p
dG9yaW5ncGKqAhpHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5WM8oCGkdvb2dsZVxDbG91ZFxN
b25pdG9yaW5nXFYz6gIdR29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6VjNKmUMKBxIFDgCC
AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB0KCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgArCgkKAgMF
EgMXACUKCQoCAwYSAxgAKgoICgEIEgMaADcKCQoCCCUSAxoANwoICgEIEgMbAFgKCQoCCAsS
AxsAWAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADMKCQoCCAgSAx0AMwoICgEIEgMe
ADEKCQoCCAESAx4AMQoICgEIEgMfADcKCQoCCCkSAx8ANwoICgEIEgMgADYKCQoCCC0SAyAA
NgqnBAoCBgASBCoAbQEamgQgVGhlIFVwdGltZUNoZWNrU2VydmljZSBBUEkgaXMgdXNlZCB0
byBtYW5hZ2UgKGxpc3QsIGNyZWF0ZSwgZGVsZXRlLCBlZGl0KQogVXB0aW1lIGNoZWNrIGNv
bmZpZ3VyYXRpb25zIGluIHRoZSBDbG91ZCBNb25pdG9yaW5nIHByb2R1Y3QuIEFuIFVwdGlt
ZQogY2hlY2sgaXMgYSBwaWVjZSBvZiBjb25maWd1cmF0aW9uIHRoYXQgZGV0ZXJtaW5lcyB3
aGljaCByZXNvdXJjZXMgYW5kCiBzZXJ2aWNlcyB0byBtb25pdG9yIGZvciBhdmFpbGFiaWxp
dHkuIFRoZXNlIGNvbmZpZ3VyYXRpb25zIGNhbiBhbHNvIGJlCiBjb25maWd1cmVkIGludGVy
YWN0aXZlbHkgYnkgbmF2aWdhdGluZyB0byB0aGUgW0Nsb3VkIGNvbnNvbGVdCiAoaHR0cHM6
Ly9jb25zb2xlLmNsb3VkLmdvb2dsZS5jb20pLCBzZWxlY3RpbmcgdGhlIGFwcHJvcHJpYXRl
IHByb2plY3QsCiBjbGlja2luZyBvbiAiTW9uaXRvcmluZyIgb24gdGhlIGxlZnQtaGFuZCBz
aWRlIHRvIG5hdmlnYXRlIHRvIENsb3VkCiBNb25pdG9yaW5nLCBhbmQgdGhlbiBjbGlja2lu
ZyBvbiAiVXB0aW1lIi4KCgoKAwYAARIDKggaCgoKAwYAAxIDKwJBCgwKBQYAA5kIEgMrAkEK
CwoDBgADEgQsAi84Cg0KBQYAA5oIEgQsAi84Cn8KBAYAAgASBDMCOQMacSBMaXN0cyB0aGUg
ZXhpc3RpbmcgdmFsaWQgVXB0aW1lIGNoZWNrIGNvbmZpZ3VyYXRpb25zIGZvciB0aGUgcHJv
amVjdAogKGxlYXZpbmcgb3V0IGFueSBpbnZhbGlkIGNvbmZpZ3VyYXRpb25zKS4KCgwKBQYA
AgABEgMzBhwKDAoFBgACAAISAzMdOgoMCgUGAAIAAxIDNA8tCg0KBQYAAgAEEgQ1BDcGChEK
CQYAAgAEsMq8IhIENQQ3BgoMCgUGAAIABBIDOAQ0Cg8KCAYAAgAEmwgAEgM4BDQKOQoEBgAC
ARIEPAJCAxorIEdldHMgYSBzaW5nbGUgVXB0aW1lIGNoZWNrIGNvbmZpZ3VyYXRpb24uCgoM
CgUGAAIBARIDPAYaCgwKBQYAAgECEgM8GzYKDAoFBgACAQMSAz0PIAoNCgUGAAIBBBIEPgRA
BgoRCgkGAAIBBLDKvCISBD4EQAYKDAoFBgACAQQSA0EEMgoPCggGAAIBBJsIABIDQQQyCjkK
BAYAAgISBEUCTAMaKyBDcmVhdGVzIGEgbmV3IFVwdGltZSBjaGVjayBjb25maWd1cmF0aW9u
LgoKDAoFBgACAgESA0UGHQoMCgUGAAICAhIDRR48CgwKBQYAAgIDEgNGDyAKDQoFBgACAgQS
BEcESgYKEQoJBgACAgSwyrwiEgRHBEoGCgwKBQYAAgIEEgNLBEgKDwoIBgACAgSbCAASA0sE
SAqRAgoEBgACAxIEUgJZAxqCAiBVcGRhdGVzIGFuIFVwdGltZSBjaGVjayBjb25maWd1cmF0
aW9uLiBZb3UgY2FuIGVpdGhlciByZXBsYWNlIHRoZSBlbnRpcmUKIGNvbmZpZ3VyYXRpb24g
d2l0aCBhIG5ldyBvbmUgb3IgcmVwbGFjZSBvbmx5IGNlcnRhaW4gZmllbGRzIGluIHRoZSBj
dXJyZW50CiBjb25maWd1cmF0aW9uIGJ5IHNwZWNpZnlpbmcgdGhlIGZpZWxkcyB0byBiZSB1
cGRhdGVkIHZpYSBgdXBkYXRlTWFza2AuCiBSZXR1cm5zIHRoZSB1cGRhdGVkIGNvbmZpZ3Vy
YXRpb24uCgoMCgUGAAIDARIDUgYdCgwKBQYAAgMCEgNSHjwKDAoFBgACAwMSA1MPIAoNCgUG
AAIDBBIEVARXBgoRCgkGAAIDBLDKvCISBFQEVwYKDAoFBgACAwQSA1gEQQoPCggGAAIDBJsI
ABIDWARBCucBCgQGAAIEEgReAmQDGtgBIERlbGV0ZXMgYW4gVXB0aW1lIGNoZWNrIGNvbmZp
Z3VyYXRpb24uIE5vdGUgdGhhdCB0aGlzIG1ldGhvZCB3aWxsIGZhaWwKIGlmIHRoZSBVcHRp
bWUgY2hlY2sgY29uZmlndXJhdGlvbiBpcyByZWZlcmVuY2VkIGJ5IGFuIGFsZXJ0IHBvbGlj
eSBvcgogb3RoZXIgZGVwZW5kZW50IGNvbmZpZ3MgdGhhdCB3b3VsZCBiZSByZW5kZXJlZCBp
bnZhbGlkIGJ5IHRoZSBkZWxldGlvbi4KCgwKBQYAAgQBEgNeBh0KDAoFBgACBAISA14ePAoM
CgUGAAIEAxIDXw8kCg0KBQYAAgQEEgRgBGIGChEKCQYAAgQEsMq8IhIEYARiBgoMCgUGAAIE
BBIDYwQyCg8KCAYAAgQEmwgAEgNjBDIKSAoEBgACBRIEZwJsAxo6IFJldHVybnMgdGhlIGxp
c3Qgb2YgSVAgYWRkcmVzc2VzIHRoYXQgY2hlY2tlcnMgcnVuIGZyb20uCgoMCgUGAAIFARID
ZwYYCgwKBQYAAgUCEgNnGTIKDAoFBgACBQMSA2gPKQoNCgUGAAIFBBIEaQRrBgoRCgkGAAIF
BLDKvCISBGkEawYKRQoCBAASBXAAjgEBGjggVGhlIHByb3RvY29sIGZvciB0aGUgYExpc3RV
cHRpbWVDaGVja0NvbmZpZ3NgIHJlcXVlc3QuCgoKCgMEAAESA3AIJQrGAQoEBAACABIEdgJ7
BBq3ASBSZXF1aXJlZC4gVGhlCiBbcHJvamVjdF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L21vbml0b3JpbmcvYXBpL3YzI3Byb2plY3RfbmFtZSkgd2hvc2UKIFVwdGltZSBjaGVjayBj
b25maWd1cmF0aW9ucyBhcmUgbGlzdGVkLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0
cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdCgoMCgUEAAIABRIDdgIICgwKBQQAAgABEgN2CQ8K
DAoFBAACAAMSA3YSEwoNCgUEAAIACBIEdhR7AwoPCggEAAIACJwIABIDdwQqCg8KBwQAAgAI
nwgSBHgEegUK/wEKBAQAAgESBIIBAhQa8AEgSWYgcHJvdmlkZWQsIHRoaXMgZmllbGQgc3Bl
Y2lmaWVzIHRoZSBjcml0ZXJpYSB0aGF0IG11c3QgYmUgbWV0IGJ5CiB1cHRpbWUgY2hlY2tz
IHRvIGJlIGluY2x1ZGVkIGluIHRoZSByZXNwb25zZS4KCiBGb3IgbW9yZSBkZXRhaWxzLCBz
ZWUgW0ZpbHRlcmluZwogc3ludGF4XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbW9uaXRv
cmluZy9hcGkvdjMvc29ydGluZy1hbmQtZmlsdGVyaW5nI2ZpbHRlcl9zeW50YXgpLgoKDQoF
BAACAQUSBIIBAggKDQoFBAACAQESBIIBCQ8KDQoFBAACAQMSBIIBEhMKgQIKBAQAAgISBIgB
AhYa8gEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuIGluIGEgc2lu
Z2xlIHJlc3BvbnNlLiBUaGUgc2VydmVyCiBtYXkgZnVydGhlciBjb25zdHJhaW4gdGhlIG1h
eGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgcmV0dXJuZWQgaW4gYSBzaW5nbGUKIHBhZ2UuIElm
IHRoZSBwYWdlX3NpemUgaXMgPD0wLCB0aGUgc2VydmVyIHdpbGwgZGVjaWRlIHRoZSBudW1i
ZXIgb2YgcmVzdWx0cwogdG8gYmUgcmV0dXJuZWQuCgoNCgUEAAICBRIEiAECBwoNCgUEAAIC
ARIEiAEIEQoNCgUEAAICAxIEiAEUFQriAQoEBAACAxIEjQECGBrTASBJZiB0aGlzIGZpZWxk
IGlzIG5vdCBlbXB0eSB0aGVuIGl0IG11c3QgY29udGFpbiB0aGUgYG5leHRQYWdlVG9rZW5g
IHZhbHVlCiByZXR1cm5lZCBieSBhIHByZXZpb3VzIGNhbGwgdG8gdGhpcyBtZXRob2QuICBV
c2luZyB0aGlzIGZpZWxkIGNhdXNlcyB0aGUKIG1ldGhvZCB0byByZXR1cm4gbW9yZSByZXN1
bHRzIGZyb20gdGhlIHByZXZpb3VzIG1ldGhvZCBjYWxsLgoKDQoFBAACAwUSBI0BAggKDQoF
BAACAwESBI0BCRMKDQoFBAACAwMSBI0BFhcKRwoCBAESBpEBAJ8BARo5IFRoZSBwcm90b2Nv
bCBmb3IgdGhlIGBMaXN0VXB0aW1lQ2hlY2tDb25maWdzYCByZXNwb25zZS4KCgsKAwQBARIE
kQEIJgo5CgQEAQIAEgSTAQI2GisgVGhlIHJldHVybmVkIFVwdGltZSBjaGVjayBjb25maWd1
cmF0aW9ucy4KCg0KBQQBAgAEEgSTAQIKCg0KBQQBAgAGEgSTAQscCg0KBQQBAgABEgSTAR0x
Cg0KBQQBAgADEgSTATQ1CsoCCgQEAQIBEgSaAQIdGrsCIFRoaXMgZmllbGQgcmVwcmVzZW50
cyB0aGUgcGFnaW5hdGlvbiB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mCiBy
ZXN1bHRzLiBJZiB0aGUgdmFsdWUgaXMgZW1wdHksIGl0IG1lYW5zIG5vIGZ1cnRoZXIgcmVz
dWx0cyBmb3IgdGhlCiByZXF1ZXN0LiBUbyByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJl
c3VsdHMsIHRoZSB2YWx1ZSBvZiB0aGUKIG5leHRfcGFnZV90b2tlbiBpcyBwYXNzZWQgdG8g
dGhlIHN1YnNlcXVlbnQgTGlzdCBtZXRob2QgY2FsbCAoaW4gdGhlCiByZXF1ZXN0IG1lc3Nh
Z2UncyBwYWdlX3Rva2VuIGZpZWxkKS4KCg0KBQQBAgEFEgSaAQIICg0KBQQBAgEBEgSaAQkY
Cg0KBQQBAgEDEgSaARscCnEKBAQBAgISBJ4BAhcaYyBUaGUgdG90YWwgbnVtYmVyIG9mIFVw
dGltZSBjaGVjayBjb25maWd1cmF0aW9ucyBmb3IgdGhlIHByb2plY3QsCiBpcnJlc3BlY3Rp
dmUgb2YgYW55IHBhZ2luYXRpb24uCgoNCgUEAQICBRIEngECBwoNCgUEAQICARIEngEIEgoN
CgUEAQICAxIEngEVFgpECgIEAhIGogEArAEBGjYgVGhlIHByb3RvY29sIGZvciB0aGUgYEdl
dFVwdGltZUNoZWNrQ29uZmlnYCByZXF1ZXN0LgoKCwoDBAIBEgSiAQgjCqIBCgQEAgIAEgam
AQKrAQQakQEgUmVxdWlyZWQuIFRoZSBVcHRpbWUgY2hlY2sgY29uZmlndXJhdGlvbiB0byBy
ZXRyaWV2ZS4gVGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1Jf
TlVNQkVSXS91cHRpbWVDaGVja0NvbmZpZ3MvW1VQVElNRV9DSEVDS19JRF0KCg0KBQQCAgAF
EgSmAQIICg0KBQQCAgABEgSmAQkNCg0KBQQCAgADEgSmARARCg8KBQQCAgAIEgamARKrAQMK
EAoIBAICAAicCAASBKcBBCoKEQoHBAICAAifCBIGqAEEqgEFCkcKAgQDEgavAQC/AQEaOSBU
aGUgcHJvdG9jb2wgZm9yIHRoZSBgQ3JlYXRlVXB0aW1lQ2hlY2tDb25maWdgIHJlcXVlc3Qu
CgoLCgMEAwESBK8BCCYKvwEKBAQDAgASBrUBAroBBBquASBSZXF1aXJlZC4gVGhlCiBbcHJv
amVjdF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3YzI3Byb2pl
Y3RfbmFtZSkgaW4gd2hpY2gKIHRvIGNyZWF0ZSB0aGUgVXB0aW1lIGNoZWNrLiBUaGUgZm9y
bWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdCgoNCgUEAwIA
BRIEtQECCAoNCgUEAwIAARIEtQEJDwoNCgUEAwIAAxIEtQESEwoPCgUEAwIACBIGtQEUugED
ChAKCAQDAgAInAgAEgS2AQQqChEKBwQDAgAInwgSBrcBBLkBBQo/CgQEAwIBEga9AQK+AS8a
LyBSZXF1aXJlZC4gVGhlIG5ldyBVcHRpbWUgY2hlY2sgY29uZmlndXJhdGlvbi4KCg0KBQQD
AgEGEgS9AQITCg0KBQQDAgEBEgS9ARQnCg0KBQQDAgEDEgS9ASorCg0KBQQDAgEIEgS+AQYu
ChAKCAQDAgEInAgAEgS+AQctCkcKAgQEEgbCAQDWAQEaOSBUaGUgcHJvdG9jb2wgZm9yIHRo
ZSBgVXBkYXRlVXB0aW1lQ2hlY2tDb25maWdgIHJlcXVlc3QuCgoLCgMEBAESBMIBCCYKiAIK
BAQEAgASBMcBAiwa+QEgT3B0aW9uYWwuIElmIHByZXNlbnQsIG9ubHkgdGhlIGxpc3RlZCBm
aWVsZHMgaW4gdGhlIGN1cnJlbnQgVXB0aW1lIGNoZWNrCiBjb25maWd1cmF0aW9uIGFyZSB1
cGRhdGVkIHdpdGggdmFsdWVzIGZyb20gdGhlIG5ldyBjb25maWd1cmF0aW9uLiBJZiB0aGlz
CiBmaWVsZCBpcyBlbXB0eSwgdGhlbiB0aGUgY3VycmVudCBjb25maWd1cmF0aW9uIGlzIGNv
bXBsZXRlbHkgcmVwbGFjZWQgd2l0aAogdGhlIG5ldyBjb25maWd1cmF0aW9uLgoKDQoFBAQC
AAYSBMcBAhsKDQoFBAQCAAESBMcBHCcKDQoFBAQCAAMSBMcBKisK4gQKBAQEAgESBtQBAtUB
LxrRBCBSZXF1aXJlZC4gSWYgYW4gYHVwZGF0ZU1hc2tgIGhhcyBiZWVuIHNwZWNpZmllZCwg
dGhpcyBmaWVsZCBnaXZlcwogdGhlIHZhbHVlcyBmb3IgdGhlIHNldCBvZiBmaWVsZHMgbWVu
dGlvbmVkIGluIHRoZSBgdXBkYXRlTWFza2AuIElmIGFuCiBgdXBkYXRlTWFza2AgaGFzIG5v
dCBiZWVuIGdpdmVuLCB0aGlzIFVwdGltZSBjaGVjayBjb25maWd1cmF0aW9uIHJlcGxhY2Vz
CiB0aGUgY3VycmVudCBjb25maWd1cmF0aW9uLiBJZiBhIGZpZWxkIGlzIG1lbnRpb25lZCBp
biBgdXBkYXRlTWFza2AgYnV0CiB0aGUgY29ycmVzcG9uZGluZyBmaWVsZCBpcyBvbWl0dGVk
IGluIHRoaXMgcGFydGlhbCBVcHRpbWUgY2hlY2sKIGNvbmZpZ3VyYXRpb24sIGl0IGhhcyB0
aGUgZWZmZWN0IG9mIGRlbGV0aW5nL2NsZWFyaW5nIHRoZSBmaWVsZCBmcm9tIHRoZQogY29u
ZmlndXJhdGlvbiBvbiB0aGUgc2VydmVyLgoKIFRoZSBmb2xsb3dpbmcgZmllbGRzIGNhbiBi
ZSB1cGRhdGVkOiBgZGlzcGxheV9uYW1lYCwKIGBodHRwX2NoZWNrYCwgYHRjcF9jaGVja2As
IGB0aW1lb3V0YCwgYGNvbnRlbnRfbWF0Y2hlcnNgLCBhbmQKIGBzZWxlY3RlZF9yZWdpb25z
YC4KCg0KBQQEAgEGEgTUAQITCg0KBQQEAgEBEgTUARQnCg0KBQQEAgEDEgTUASorCg0KBQQE
AgEIEgTVAQYuChAKCAQEAgEInAgAEgTVAQctCkcKAgQFEgbZAQDjAQEaOSBUaGUgcHJvdG9j
b2wgZm9yIHRoZSBgRGVsZXRlVXB0aW1lQ2hlY2tDb25maWdgIHJlcXVlc3QuCgoLCgMEBQES
BNkBCCYKoAEKBAQFAgASBt0BAuIBBBqPASBSZXF1aXJlZC4gVGhlIFVwdGltZSBjaGVjayBj
b25maWd1cmF0aW9uIHRvIGRlbGV0ZS4gVGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMv
W1BST0pFQ1RfSURfT1JfTlVNQkVSXS91cHRpbWVDaGVja0NvbmZpZ3MvW1VQVElNRV9DSEVD
S19JRF0KCg0KBQQFAgAFEgTdAQIICg0KBQQFAgABEgTdAQkNCg0KBQQFAgADEgTdARARCg8K
BQQFAgAIEgbdARLiAQMKEAoIBAUCAAicCAASBN4BBCoKEQoHBAUCAAifCBIG3wEE4QEFCkIK
AgQGEgbmAQDzAQEaNCBUaGUgcHJvdG9jb2wgZm9yIHRoZSBgTGlzdFVwdGltZUNoZWNrSXBz
YCByZXF1ZXN0LgoKCwoDBAYBEgTmAQghCqoCCgQEBgIAEgTsAQIWGpsCIFRoZSBtYXhpbXVt
IG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybiBpbiBhIHNpbmdsZSByZXNwb25zZS4gVGhl
IHNlcnZlcgogbWF5IGZ1cnRoZXIgY29uc3RyYWluIHRoZSBtYXhpbXVtIG51bWJlciBvZiBy
ZXN1bHRzIHJldHVybmVkIGluIGEgc2luZ2xlCiBwYWdlLiBJZiB0aGUgcGFnZV9zaXplIGlz
IDw9MCwgdGhlIHNlcnZlciB3aWxsIGRlY2lkZSB0aGUgbnVtYmVyIG9mIHJlc3VsdHMKIHRv
IGJlIHJldHVybmVkLgogTk9URTogdGhpcyBmaWVsZCBpcyBub3QgeWV0IGltcGxlbWVudGVk
CgoNCgUEBgIABRIE7AECBwoNCgUEBgIAARIE7AEIEQoNCgUEBgIAAxIE7AEUFQqLAgoEBAYC
ARIE8gECGBr8ASBJZiB0aGlzIGZpZWxkIGlzIG5vdCBlbXB0eSB0aGVuIGl0IG11c3QgY29u
dGFpbiB0aGUgYG5leHRQYWdlVG9rZW5gIHZhbHVlCiByZXR1cm5lZCBieSBhIHByZXZpb3Vz
IGNhbGwgdG8gdGhpcyBtZXRob2QuICBVc2luZyB0aGlzIGZpZWxkIGNhdXNlcyB0aGUKIG1l
dGhvZCB0byByZXR1cm4gbW9yZSByZXN1bHRzIGZyb20gdGhlIHByZXZpb3VzIG1ldGhvZCBj
YWxsLgogTk9URTogdGhpcyBmaWVsZCBpcyBub3QgeWV0IGltcGxlbWVudGVkCgoNCgUEBgIB
BRIE8gECCAoNCgUEBgIBARIE8gEJEwoNCgUEBgIBAxIE8gEWFwpDCgIEBxIG9gEAggIBGjUg
VGhlIHByb3RvY29sIGZvciB0aGUgYExpc3RVcHRpbWVDaGVja0lwc2AgcmVzcG9uc2UuCgoL
CgMEBwESBPYBCCIKbgoEBAcCABIE+QECLhpgIFRoZSByZXR1cm5lZCBsaXN0IG9mIElQIGFk
ZHJlc3NlcyAoaW5jbHVkaW5nIHJlZ2lvbiBhbmQgbG9jYXRpb24pIHRoYXQgdGhlCiBjaGVj
a2VycyBydW4gZnJvbS4KCg0KBQQHAgAEEgT5AQIKCg0KBQQHAgAGEgT5AQsYCg0KBQQHAgAB
EgT5ARkpCg0KBQQHAgADEgT5ASwtCvMCCgQEBwIBEgSBAgIdGuQCIFRoaXMgZmllbGQgcmVw
cmVzZW50cyB0aGUgcGFnaW5hdGlvbiB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdl
IG9mCiByZXN1bHRzLiBJZiB0aGUgdmFsdWUgaXMgZW1wdHksIGl0IG1lYW5zIG5vIGZ1cnRo
ZXIgcmVzdWx0cyBmb3IgdGhlCiByZXF1ZXN0LiBUbyByZXRyaWV2ZSB0aGUgbmV4dCBwYWdl
IG9mIHJlc3VsdHMsIHRoZSB2YWx1ZSBvZiB0aGUKIG5leHRfcGFnZV90b2tlbiBpcyBwYXNz
ZWQgdG8gdGhlIHN1YnNlcXVlbnQgTGlzdCBtZXRob2QgY2FsbCAoaW4gdGhlCiByZXF1ZXN0
IG1lc3NhZ2UncyBwYWdlX3Rva2VuIGZpZWxkKS4KIE5PVEU6IHRoaXMgZmllbGQgaXMgbm90
IHlldCBpbXBsZW1lbnRlZAoKDQoFBAcCAQUSBIECAggKDQoFBAcCAQESBIECCRgKDQoFBAcC
AQMSBIECGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest ===
    # Fields for ListUptimeCheckConfigsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse ===
    # Fields for ListUptimeCheckConfigsResponse
    # Field: uptime_check_configs Type: 11 (.google.monitoring.v3.UptimeCheckConfig)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Monitoring::V3::UptimeService::GetUptimeCheckConfigRequest ===
    # Fields for GetUptimeCheckConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::UptimeService::CreateUptimeCheckConfigRequest ===
    # Fields for CreateUptimeCheckConfigRequest
    # Field: parent Type: 9 ()
    # Field: uptime_check_config Type: 11 (.google.monitoring.v3.UptimeCheckConfig)

# === Message: Google::Monitoring::V3::UptimeService::UpdateUptimeCheckConfigRequest ===
    # Fields for UpdateUptimeCheckConfigRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: uptime_check_config Type: 11 (.google.monitoring.v3.UptimeCheckConfig)

# === Message: Google::Monitoring::V3::UptimeService::DeleteUptimeCheckConfigRequest ===
    # Fields for DeleteUptimeCheckConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest ===
    # Fields for ListUptimeCheckIpsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse ===
    # Fields for ListUptimeCheckIpsResponse
    # Field: uptime_check_ips Type: 11 (.google.monitoring.v3.UptimeCheckIp)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Monitoring::V3::UptimeService::UptimeCheckServiceClient ===
package Google::Monitoring::V3::UptimeService::UptimeCheckServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::UptimeService::UptimeCheckServiceClient

Client stub representing the remote C<UptimeCheckService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub list_uptime_check_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'ListUptimeCheckConfigs',
        request        => $req,
        response_class => 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse',
    });
}

sub get_uptime_check_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::UptimeService::GetUptimeCheckConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'GetUptimeCheckConfig',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Uptime::UptimeCheckConfig',
    });
}

sub create_uptime_check_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::UptimeService::CreateUptimeCheckConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'CreateUptimeCheckConfig',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Uptime::UptimeCheckConfig',
    });
}

sub update_uptime_check_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::UptimeService::UpdateUptimeCheckConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'UpdateUptimeCheckConfig',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Uptime::UptimeCheckConfig',
    });
}

sub delete_uptime_check_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::UptimeService::DeleteUptimeCheckConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'DeleteUptimeCheckConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_uptime_check_ips {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'ListUptimeCheckIps',
        request        => $req,
        response_class => 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::UptimeService - Compiled Protocol Buffers messages for google/monitoring/v3/uptime_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::UptimeService;

    my $msg = Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest->new({
        parent => $parent,
        filter => $filter,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/uptime_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest

The protocol for the `ListUptimeCheckConfigs` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) whose
Uptime check configurations are listed. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

If provided, this field specifies the criteria that must be met by
uptime checks to be included in the response.

For more details, see [Filtering
syntax](https://cloud.google.com/monitoring/api/v3/sorting-and-filtering#filter_syntax).

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results to return in a single response. The server
may further constrain the maximum number of results returned in a single
page. If the page_size is <=0, the server will decide the number of results
to be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If this field is not empty then it must contain the `nextPageToken` value
returned by a previous call to this method.  Using this field causes the
method to return more results from the previous method call.

=back

=head2 Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse

The protocol for the `ListUptimeCheckConfigs` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uptime_check_configs() >> / C<< $msg->uptime_check_configs($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Uptime::UptimeCheckConfig>)

The returned Uptime check configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This field represents the pagination token to retrieve the next page of
results. If the value is empty, it means no further results for the
request. To retrieve the next page of results, the value of the
next_page_token is passed to the subsequent List method call (in the
request message's page_token field).

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of Uptime check configurations for the project,
irrespective of any pagination.

=back

=head2 Google::Monitoring::V3::UptimeService::GetUptimeCheckConfigRequest

The protocol for the `GetUptimeCheckConfig` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The Uptime check configuration to retrieve. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/uptimeCheckConfigs/[UPTIME_CHECK_ID]

=back

=head2 Google::Monitoring::V3::UptimeService::CreateUptimeCheckConfigRequest

The protocol for the `CreateUptimeCheckConfig` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) in which
to create the Uptime check. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->uptime_check_config() >> / C<< $msg->uptime_check_config($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Uptime::UptimeCheckConfig>)

Required. The new Uptime check configuration.

=back

=head2 Google::Monitoring::V3::UptimeService::UpdateUptimeCheckConfigRequest

The protocol for the `UpdateUptimeCheckConfig` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. If present, only the listed fields in the current Uptime check
configuration are updated with values from the new configuration. If this
field is empty, then the current configuration is completely replaced with
the new configuration.

=item * C<< $msg->uptime_check_config() >> / C<< $msg->uptime_check_config($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Uptime::UptimeCheckConfig>)

Required. If an `updateMask` has been specified, this field gives
the values for the set of fields mentioned in the `updateMask`. If an
`updateMask` has not been given, this Uptime check configuration replaces
the current configuration. If a field is mentioned in `updateMask` but
the corresponding field is omitted in this partial Uptime check
configuration, it has the effect of deleting/clearing the field from the
configuration on the server.

The following fields can be updated: `display_name`,
`http_check`, `tcp_check`, `timeout`, `content_matchers`, and
`selected_regions`.

=back

=head2 Google::Monitoring::V3::UptimeService::DeleteUptimeCheckConfigRequest

The protocol for the `DeleteUptimeCheckConfig` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The Uptime check configuration to delete. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/uptimeCheckConfigs/[UPTIME_CHECK_ID]

=back

=head2 Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest

The protocol for the `ListUptimeCheckIps` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results to return in a single response. The server
may further constrain the maximum number of results returned in a single
page. If the page_size is <=0, the server will decide the number of results
to be returned.
NOTE: this field is not yet implemented

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If this field is not empty then it must contain the `nextPageToken` value
returned by a previous call to this method.  Using this field causes the
method to return more results from the previous method call.
NOTE: this field is not yet implemented

=back

=head2 Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse

The protocol for the `ListUptimeCheckIps` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uptime_check_ips() >> / C<< $msg->uptime_check_ips($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Uptime::UptimeCheckIp>)

The returned list of IP addresses (including region and location) that the
checkers run from.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This field represents the pagination token to retrieve the next page of
results. If the value is empty, it means no further results for the
request. To retrieve the next page of results, the value of the
next_page_token is passed to the subsequent List method call (in the
request message's page_token field).
NOTE: this field is not yet implemented

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::UptimeService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
