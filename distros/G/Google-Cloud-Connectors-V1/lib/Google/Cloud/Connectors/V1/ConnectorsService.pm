package Google::Cloud::Connectors::V1::ConnectorsService;

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
    eval { require Google::Cloud::Connectors::V1::Common };
    eval { require Google::Cloud::Connectors::V1::Connection };
    eval { require Google::Cloud::Connectors::V1::Connector };
    eval { require Google::Cloud::Connectors::V1::ConnectorVersion };
    eval { require Google::Cloud::Connectors::V1::Provider };
    eval { require Google::Cloud::Connectors::V1::Runtime };
    eval { require Google::Cloud::Connectors::V1::Settings };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9jb25uZWN0b3JzX3NlcnZpY2UucHJvdG8S
Gmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxonZ29vZ2xlL2Nsb3VkL2Nvbm5lY3RvcnMv
djEvY29tbW9uLnByb3RvGitnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9jb25uZWN0aW9u
LnByb3RvGipnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9jb25uZWN0b3IucHJvdG8aMmdv
b2dsZS9jbG91ZC9jb25uZWN0b3JzL3YxL2Nvbm5lY3Rvcl92ZXJzaW9uLnByb3RvGilnb29n
bGUvY2xvdWQvY29ubmVjdG9ycy92MS9wcm92aWRlci5wcm90bxooZ29vZ2xlL2Nsb3VkL2Nv
bm5lY3RvcnMvdjEvcnVudGltZS5wcm90bxopZ29vZ2xlL2Nsb3VkL2Nvbm5lY3RvcnMvdjEv
c2V0dGluZ3MucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtn
b29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8y6RwKCkNvbm5lY3RvcnMSvAEKD0xpc3RDb25u
ZWN0aW9ucxIyLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkxpc3RDb25uZWN0aW9uc1Jl
cXVlc3QaMy5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5MaXN0Q29ubmVjdGlvbnNSZXNw
b25zZSJAgtPkkwIxEi8vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jb25u
ZWN0aW9uc9pBBnBhcmVudBKpAQoNR2V0Q29ubmVjdGlvbhIwLmdvb2dsZS5jbG91ZC5jb25u
ZWN0b3JzLnYxLkdldENvbm5lY3Rpb25SZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLmNvbm5lY3Rv
cnMudjEuQ29ubmVjdGlvbiI+gtPkkwIxEi8vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb25uZWN0aW9ucy8qfdpBBG5hbWUS8AEKEENyZWF0ZUNvbm5lY3Rpb24SMy5nb29n
bGUuY2xvdWQuY29ubmVjdG9ycy52MS5DcmVhdGVDb25uZWN0aW9uUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24ihwGC0+STAj0iLy92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L2Nvbm5lY3Rpb25zOgpjb25uZWN0aW9u2kEfcGFyZW50LGNvbm5l
Y3Rpb24sY29ubmVjdGlvbl9pZMpBHwoKQ29ubmVjdGlvbhIRT3BlcmF0aW9uTWV0YWRhdGES
8gEKEFVwZGF0ZUNvbm5lY3Rpb24SMy5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5VcGRh
dGVDb25uZWN0aW9uUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iiQGC
0+STAkgyOi92MS97Y29ubmVjdGlvbi5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29u
bmVjdGlvbnMvKn06CmNvbm5lY3Rpb27aQRZjb25uZWN0aW9uLHVwZGF0ZV9tYXNrykEfCgpD
b25uZWN0aW9uEhFPcGVyYXRpb25NZXRhZGF0YRLTAQoQRGVsZXRlQ29ubmVjdGlvbhIzLmdv
b2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkRlbGV0ZUNvbm5lY3Rpb25SZXF1ZXN0Gh0uZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJrgtPkkwIxKi8vdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb25uZWN0aW9ucy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1
Zi5FbXB0eRIRT3BlcmF0aW9uTWV0YWRhdGEStAEKDUxpc3RQcm92aWRlcnMSMC5nb29nbGUu
Y2xvdWQuY29ubmVjdG9ycy52MS5MaXN0UHJvdmlkZXJzUmVxdWVzdBoxLmdvb2dsZS5jbG91
ZC5jb25uZWN0b3JzLnYxLkxpc3RQcm92aWRlcnNSZXNwb25zZSI+gtPkkwIvEi0vdjEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9wcm92aWRlcnPaQQZwYXJlbnQSoQEKC0dl
dFByb3ZpZGVyEi4uZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuR2V0UHJvdmlkZXJSZXF1
ZXN0GiQuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUHJvdmlkZXIiPILT5JMCLxItL3Yx
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcHJvdmlkZXJzLyp92kEEbmFtZRLEAQoO
TGlzdENvbm5lY3RvcnMSMS5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5MaXN0Q29ubmVj
dG9yc1JlcXVlc3QaMi5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5MaXN0Q29ubmVjdG9y
c1Jlc3BvbnNlIkuC0+STAjwSOi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
cHJvdmlkZXJzLyp9L2Nvbm5lY3RvcnPaQQZwYXJlbnQSsQEKDEdldENvbm5lY3RvchIvLmdv
b2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkdldENvbm5lY3RvclJlcXVlc3QaJS5nb29nbGUu
Y2xvdWQuY29ubmVjdG9ycy52MS5Db25uZWN0b3IiSYLT5JMCPBI6L3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovcHJvdmlkZXJzLyovY29ubmVjdG9ycy8qfdpBBG5hbWUS5AEK
FUxpc3RDb25uZWN0b3JWZXJzaW9ucxI4Lmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkxp
c3RDb25uZWN0b3JWZXJzaW9uc1JlcXVlc3QaOS5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52
MS5MaXN0Q29ubmVjdG9yVmVyc2lvbnNSZXNwb25zZSJWgtPkkwJHEkUvdjEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Byb3ZpZGVycy8qL2Nvbm5lY3RvcnMvKn0vdmVyc2lv
bnPaQQZwYXJlbnQS0QEKE0dldENvbm5lY3RvclZlcnNpb24SNi5nb29nbGUuY2xvdWQuY29u
bmVjdG9ycy52MS5HZXRDb25uZWN0b3JWZXJzaW9uUmVxdWVzdBosLmdvb2dsZS5jbG91ZC5j
b25uZWN0b3JzLnYxLkNvbm5lY3RvclZlcnNpb24iVILT5JMCRxJFL3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovcHJvdmlkZXJzLyovY29ubmVjdG9ycy8qL3ZlcnNpb25zLyp9
2kEEbmFtZRLsAQobR2V0Q29ubmVjdGlvblNjaGVtYU1ldGFkYXRhEj4uZ29vZ2xlLmNsb3Vk
LmNvbm5lY3RvcnMudjEuR2V0Q29ubmVjdGlvblNjaGVtYU1ldGFkYXRhUmVxdWVzdBo0Lmdv
b2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkNvbm5lY3Rpb25TY2hlbWFNZXRhZGF0YSJXgtPk
kwJKEkgvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0aW9ucy8qL2Nv
bm5lY3Rpb25TY2hlbWFNZXRhZGF0YX3aQQRuYW1lEpkCCh9SZWZyZXNoQ29ubmVjdGlvblNj
aGVtYU1ldGFkYXRhEkIuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUmVmcmVzaENvbm5l
Y3Rpb25TY2hlbWFNZXRhZGF0YVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uIpIBgtPkkwJVIlAvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0
aW9ucy8qL2Nvbm5lY3Rpb25TY2hlbWFNZXRhZGF0YX06cmVmcmVzaDoBKtpBBG5hbWXKQS0K
GENvbm5lY3Rpb25TY2hlbWFNZXRhZGF0YRIRT3BlcmF0aW9uTWV0YWRhdGES7gEKGExpc3RS
dW50aW1lRW50aXR5U2NoZW1hcxI7Lmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkxpc3RS
dW50aW1lRW50aXR5U2NoZW1hc1JlcXVlc3QaPC5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52
MS5MaXN0UnVudGltZUVudGl0eVNjaGVtYXNSZXNwb25zZSJXgtPkkwJIEkYvdjEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3Rpb25zLyp9L3J1bnRpbWVFbnRpdHlT
Y2hlbWFz2kEGcGFyZW50Eu4BChhMaXN0UnVudGltZUFjdGlvblNjaGVtYXMSOy5nb29nbGUu
Y2xvdWQuY29ubmVjdG9ycy52MS5MaXN0UnVudGltZUFjdGlvblNjaGVtYXNSZXF1ZXN0Gjwu
Z29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuTGlzdFJ1bnRpbWVBY3Rpb25TY2hlbWFzUmVz
cG9uc2UiV4LT5JMCSBJGL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25u
ZWN0aW9ucy8qfS9ydW50aW1lQWN0aW9uU2NoZW1hc9pBBnBhcmVudBKyAQoQR2V0UnVudGlt
ZUNvbmZpZxIzLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkdldFJ1bnRpbWVDb25maWdS
ZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUnVudGltZUNvbmZpZyI+gtPk
kwIxEi8vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9ydW50aW1lQ29uZmlnfdpB
BG5hbWUSrwEKEUdldEdsb2JhbFNldHRpbmdzEjQuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMu
djEuR2V0R2xvYmFsU2V0dGluZ3NSZXF1ZXN0GiQuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMu
djEuU2V0dGluZ3MiPoLT5JMCMRIvL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2ds
b2JhbC9zZXR0aW5nc33aQQRuYW1lGk3KQRljb25uZWN0b3JzLmdvb2dsZWFwaXMuY29t0kEu
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJ6Ch5jb20u
Z29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjFCFkNvbm5lY3RvcnNTZXJ2aWNlUHJvdG9QAVo+
Y2xvdWQuZ29vZ2xlLmNvbS9nby9jb25uZWN0b3JzL2FwaXYxL2Nvbm5lY3RvcnNwYjtjb25u
ZWN0b3JzcGJK3yAKBxIFDgDQAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQACMKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUADEKCQoCAwMSAxUA
NQoJCgIDBBIDFgA0CgkKAgMFEgMXADwKCQoCAwYSAxgAMwoJCgIDBxIDGQAyCgkKAgMIEgMa
ADMKCQoCAwkSAxsALQoJCgIDChIDHAAlCggKAQgSAx4AVQoJCgIICxIDHgBVCggKAQgSAx8A
IgoJCgIIChIDHwAiCggKAQgSAyAANwoJCgIICBIDIAA3CggKAQgSAyEANwoJCgIIARIDIQA3
CkMKAgYAEgUkANABARo2IENvbm5lY3RvcnMgaXMgdGhlIGludGVyZmFjZSBmb3IgbWFuYWdp
bmcgQ29ubmVjdG9ycy4KCgoKAwYAARIDJAgSCgoKAwYAAxIDJQJBCgwKBQYAA5kIEgMlAkEK
CwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CkIKBAYAAgASBCoCMAMaNCBMaXN0cyBDb25u
ZWN0aW9ucyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAyoG
FQoMCgUGAAIAAhIDKhYsCgwKBQYAAgADEgMrDyYKDQoFBgACAAQSBCwELgYKEQoJBgACAASw
yrwiEgQsBC4GCgwKBQYAAgAEEgMvBDQKDwoIBgACAASbCAASAy8ENAo0CgQGAAIBEgQzAjgD
GiYgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIENvbm5lY3Rpb24uCgoMCgUGAAIBARIDMwYT
CgwKBQYAAgECEgMzFCgKDAoFBgACAQMSAzMzPQoNCgUGAAIBBBIENAQ2BgoRCgkGAAIBBLDK
vCISBDQENgYKDAoFBgACAQQSAzcEMgoPCggGAAIBBJsIABIDNwQyCkkKBAYAAgISBDsCRgMa
OyBDcmVhdGVzIGEgbmV3IENvbm5lY3Rpb24gaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2Nh
dGlvbi4KCgwKBQYAAgIBEgM7BhYKDAoFBgACAgISAzsXLgoMCgUGAAICAxIDPA8rCg0KBQYA
AgIEEgQ9BEAGChEKCQYAAgIEsMq8IhIEPQRABgoMCgUGAAICBBIDQQRNCg8KCAYAAgIEmwgA
EgNBBE0KDQoFBgACAgQSBEIERQYKDwoHBgACAgSZCBIEQgRFBgo+CgQGAAIDEgRJAlQDGjAg
VXBkYXRlcyB0aGUgcGFyYW1ldGVycyBvZiBhIHNpbmdsZSBDb25uZWN0aW9uLgoKDAoFBgAC
AwESA0kGFgoMCgUGAAIDAhIDSRcuCgwKBQYAAgMDEgNKDysKDQoFBgACAwQSBEsETgYKEQoJ
BgACAwSwyrwiEgRLBE4GCgwKBQYAAgMEEgNPBEQKDwoIBgACAwSbCAASA08ERAoNCgUGAAID
BBIEUARTBgoPCgcGAAIDBJkIEgRQBFMGCiwKBAYAAgQSBFcCYQMaHiBEZWxldGVzIGEgc2lu
Z2xlIENvbm5lY3Rpb24uCgoMCgUGAAIEARIDVwYWCgwKBQYAAgQCEgNXFy4KDAoFBgACBAMS
A1gPKwoNCgUGAAIEBBIEWQRbBgoRCgkGAAIEBLDKvCISBFkEWwYKDAoFBgACBAQSA1wEMgoP
CggGAAIEBJsIABIDXAQyCg0KBQYAAgQEEgRdBGAGCg8KBwYAAgQEmQgSBF0EYAYKQAoEBgAC
BRIEZAJpAxoyIExpc3RzIFByb3ZpZGVycyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0
aW9uLgoKDAoFBgACBQESA2QGEwoMCgUGAAIFAhIDZBQoCgwKBQYAAgUDEgNkM0gKDQoFBgAC
BQQSBGUEZwYKEQoJBgACBQSwyrwiEgRlBGcGCgwKBQYAAgUEEgNoBDQKDwoIBgACBQSbCAAS
A2gENAorCgQGAAIGEgRsAnEDGh0gR2V0cyBkZXRhaWxzIG9mIGEgcHJvdmlkZXIuCgoMCgUG
AAIGARIDbAYRCgwKBQYAAgYCEgNsEiQKDAoFBgACBgMSA2wvNwoNCgUGAAIGBBIEbQRvBgoR
CgkGAAIGBLDKvCISBG0EbwYKDAoFBgACBgQSA3AEMgoPCggGAAIGBJsIABIDcAQyCkEKBAYA
AgcSBHQCeQMaMyBMaXN0cyBDb25uZWN0b3JzIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9j
YXRpb24uCgoMCgUGAAIHARIDdAYUCgwKBQYAAgcCEgN0FSoKDAoFBgACBwMSA3Q1SwoNCgUG
AAIHBBIEdQR3BgoRCgkGAAIHBLDKvCISBHUEdwYKDAoFBgACBwQSA3gENAoPCggGAAIHBJsI
ABIDeAQ0CjQKBAYAAggSBXwCgQEDGiUgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIENvbm5l
Y3Rvci4KCgwKBQYAAggBEgN8BhIKDAoFBgACCAISA3wTJgoMCgUGAAIIAxIDfDE6Cg0KBQYA
AggEEgR9BH8GChEKCQYAAggEsMq8IhIEfQR/BgoNCgUGAAIIBBIEgAEEMgoQCggGAAIIBJsI
ABIEgAEEMgpLCgQGAAIJEgaEAQKKAQMaOyBMaXN0cyBDb25uZWN0b3IgVmVyc2lvbnMgaW4g
YSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCg0KBQYAAgkBEgSEAQYbCg0KBQYAAgkC
EgSEARw4Cg0KBQYAAgkDEgSFAQ8sCg8KBQYAAgkEEgaGAQSIAQYKEwoJBgACCQSwyrwiEgaG
AQSIAQYKDQoFBgACCQQSBIkBBDQKEAoIBgACCQSbCAASBIkBBDQKPQoEBgACChIGjQECkwED
Gi0gR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIGNvbm5lY3RvciB2ZXJzaW9uLgoKDQoFBgAC
CgESBI0BBhkKDQoFBgACCgISBI0BGjQKDQoFBgACCgMSBI4BDx8KDwoFBgACCgQSBo8BBJEB
BgoTCgkGAAIKBLDKvCISBo8BBJEBBgoNCgUGAAIKBBIEkgEEMgoQCggGAAIKBJsIABIEkgEE
Mgp0CgQGAAILEgaXAQKdAQMaZCBHZXRzIHNjaGVtYSBtZXRhZGF0YSBvZiBhIGNvbm5lY3Rp
b24uCiBTY2hlbWFNZXRhZGF0YSBpcyBhIHNpbmdsZXRvbiByZXNvdXJjZSBmb3IgZWFjaCBj
b25uZWN0aW9uLgoKDQoFBgACCwESBJcBBiEKDQoFBgACCwISBJcBIkQKDQoFBgACCwMSBJgB
DycKDwoFBgACCwQSBpkBBJsBBgoTCgkGAAILBLDKvCISBpkBBJsBBgoNCgUGAAILBBIEnAEE
MgoQCggGAAILBJsIABIEnAEEMgo5CgQGAAIMEgagAQKrAQMaKSBSZWZyZXNoIHJ1bnRpbWUg
c2NoZW1hIG9mIGEgY29ubmVjdGlvbi4KCg0KBQYAAgwBEgSgAQYlCg0KBQYAAgwCEgSgASZM
Cg0KBQYAAgwDEgShAQ8rCg8KBQYAAgwEEgaiAQSlAQYKEwoJBgACDASwyrwiEgaiAQSlAQYK
DQoFBgACDAQSBKYBBDIKEAoIBgACDASbCAASBKYBBDIKDwoFBgACDAQSBqcBBKoBBgoRCgcG
AAIMBJkIEganAQSqAQYKTAoEBgACDRIGrgECtAEDGjwgTGlzdCBzY2hlbWEgb2YgYSBydW50
aW1lIGVudGl0aWVzIGZpbHRlcmVkIGJ5IGVudGl0eSBuYW1lLgoKDQoFBgACDQESBK4BBh4K
DQoFBgACDQISBK4BHz4KDQoFBgACDQMSBK8BDy8KDwoFBgACDQQSBrABBLIBBgoTCgkGAAIN
BLDKvCISBrABBLIBBgoNCgUGAAINBBIEswEENAoQCggGAAINBJsIABIEswEENApLCgQGAAIO
Ega3AQK9AQMaOyBMaXN0IHNjaGVtYSBvZiBhIHJ1bnRpbWUgYWN0aW9ucyBmaWx0ZXJlZCBi
eSBhY3Rpb24gbmFtZS4KCg0KBQYAAg4BEgS3AQYeCg0KBQYAAg4CEgS3AR8+Cg0KBQYAAg4D
EgS4AQ8vCg8KBQYAAg4EEga5AQS7AQYKEwoJBgACDgSwyrwiEga5AQS7AQYKDQoFBgACDgQS
BLwBBDQKEAoIBgACDgSbCAASBLwBBDQKcQoEBgACDxIGwQECxgEDGmEgR2V0cyB0aGUgcnVu
dGltZUNvbmZpZyBvZiBhIGxvY2F0aW9uLgogUnVudGltZUNvbmZpZyBpcyBhIHNpbmdsZXRv
biByZXNvdXJjZSBmb3IgZWFjaCBsb2NhdGlvbi4KCg0KBQYAAg8BEgTBAQYWCg0KBQYAAg8C
EgTBARcuCg0KBQYAAg8DEgTBATlGCg8KBQYAAg8EEgbCAQTEAQYKEwoJBgACDwSwyrwiEgbC
AQTEAQYKDQoFBgACDwQSBMUBBDIKEAoIBgACDwSbCAASBMUBBDIKaAoEBgACEBIGygECzwED
GlggR2V0R2xvYmFsU2V0dGluZ3MgZ2V0cyBzZXR0aW5ncyBvZiBhIHByb2plY3QuCiBHbG9i
YWxTZXR0aW5ncyBpcyBhIHNpbmdsZXRvbiByZXNvdXJjZS4KCg0KBQYAAhABEgTKAQYXCg0K
BQYAAhACEgTKARgwCg0KBQYAAhADEgTKATtDCg8KBQYAAhAEEgbLAQTNAQYKEwoJBgACEASw
yrwiEgbLAQTNAQYKDQoFBgACEAQSBM4BBDIKEAoIBgACEASbCAASBM4BBDJiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Connectors::V1::ConnectorsService::ConnectorsClient ===
package Google::Cloud::Connectors::V1::ConnectorsService::ConnectorsClient;

=pod

=head2 Service Client: Google::Cloud::Connectors::V1::ConnectorsService::ConnectorsClient

Client stub representing the remote C<Connectors> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<connectors.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'connectors.googleapis.com:443' );

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

sub list_connections {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::ListConnectionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'ListConnections',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connection::ListConnectionsResponse',
    });
}

sub get_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::GetConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetConnection',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connection::Connection',
    });
}

sub create_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::CreateConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'CreateConnection',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::UpdateConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'UpdateConnection',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_connection {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::DeleteConnectionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'DeleteConnection',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_providers {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Provider::ListProvidersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'ListProviders',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Provider::ListProvidersResponse',
    });
}

sub get_provider {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Provider::GetProviderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetProvider',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Provider::Provider',
    });
}

sub list_connectors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connector::ListConnectorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'ListConnectors',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connector::ListConnectorsResponse',
    });
}

sub get_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connector::GetConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetConnector',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connector::Connector',
    });
}

sub list_connector_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'ListConnectorVersions',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsResponse',
    });
}

sub get_connector_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::ConnectorVersion::GetConnectorVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetConnectorVersion',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion',
    });
}

sub get_connection_schema_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::GetConnectionSchemaMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetConnectionSchemaMetadata',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connection::ConnectionSchemaMetadata',
    });
}

sub refresh_connection_schema_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::RefreshConnectionSchemaMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'RefreshConnectionSchemaMetadata',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_runtime_entity_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'ListRuntimeEntitySchemas',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasResponse',
    });
}

sub list_runtime_action_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'ListRuntimeActionSchemas',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasResponse',
    });
}

sub get_runtime_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetRuntimeConfig',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Runtime::RuntimeConfig',
    });
}

sub get_global_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.connectors.v1.Connectors',
        method         => 'GetGlobalSettings',
        request        => $req,
        response_class => 'Google::Cloud::Connectors::V1::Settings::Settings',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::ConnectorsService - Compiled Protocol Buffers messages for google/cloud/connectors/v1/connectors_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/connectors_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::ConnectorsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
