package Google::Cloud::Apigateway::V1::ApigatewayService;

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
    eval { require Google::Cloud::Apigateway::V1::Apigateway };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYXBpZ2F0ZXdheS92MS9hcGlnYXRld2F5X3NlcnZpY2UucHJvdG8S
Gmdvb2dsZS5jbG91ZC5hcGlnYXRld2F5LnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxorZ29vZ2xlL2Nsb3VkL2FwaWdhdGV3YXkv
djEvYXBpZ2F0ZXdheS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJv
dG8y4BcKEUFwaUdhdGV3YXlTZXJ2aWNlErABCgxMaXN0R2F0ZXdheXMSLy5nb29nbGUuY2xv
dWQuYXBpZ2F0ZXdheS52MS5MaXN0R2F0ZXdheXNSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLmFw
aWdhdGV3YXkudjEuTGlzdEdhdGV3YXlzUmVzcG9uc2UiPYLT5JMCLhIsL3YxL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZ2F0ZXdheXPaQQZwYXJlbnQSnQEKCkdldEdhdGV3
YXkSLS5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5HZXRHYXRld2F5UmVxdWVzdBojLmdv
b2dsZS5jbG91ZC5hcGlnYXRld2F5LnYxLkdhdGV3YXkiO4LT5JMCLhIsL3YxL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovZ2F0ZXdheXMvKn3aQQRuYW1lEtoBCg1DcmVhdGVHYXRl
d2F5EjAuZ29vZ2xlLmNsb3VkLmFwaWdhdGV3YXkudjEuQ3JlYXRlR2F0ZXdheVJlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIniC0+STAjciLC92MS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyp9L2dhdGV3YXlzOgdnYXRld2F52kEZcGFyZW50LGdhdGV3
YXksZ2F0ZXdheV9pZMpBHAoHR2F0ZXdheRIRT3BlcmF0aW9uTWV0YWRhdGES3AEKDVVwZGF0
ZUdhdGV3YXkSMC5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5VcGRhdGVHYXRld2F5UmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ieoLT5JMCPzI0L3YxL3tnYXRl
d2F5Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9nYXRld2F5cy8qfToHZ2F0ZXdhedpB
E2dhdGV3YXksdXBkYXRlX21hc2vKQRwKB0dhdGV3YXkSEU9wZXJhdGlvbk1ldGFkYXRhEsoB
Cg1EZWxldGVHYXRld2F5EjAuZ29vZ2xlLmNsb3VkLmFwaWdhdGV3YXkudjEuRGVsZXRlR2F0
ZXdheVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uImiC0+STAi4qLC92
MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2dhdGV3YXlzLyp92kEEbmFtZcpBKgoV
Z29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRKgAQoITGlzdEFwaXMS
Ky5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5MaXN0QXBpc1JlcXVlc3QaLC5nb29nbGUu
Y2xvdWQuYXBpZ2F0ZXdheS52MS5MaXN0QXBpc1Jlc3BvbnNlIjmC0+STAioSKC92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2FwaXPaQQZwYXJlbnQSjQEKBkdldEFwaRIp
Lmdvb2dsZS5jbG91ZC5hcGlnYXRld2F5LnYxLkdldEFwaVJlcXVlc3QaHy5nb29nbGUuY2xv
dWQuYXBpZ2F0ZXdheS52MS5BcGkiN4LT5JMCKhIoL3YxL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovYXBpcy8qfdpBBG5hbWUSvgEKCUNyZWF0ZUFwaRIsLmdvb2dsZS5jbG91ZC5h
cGlnYXRld2F5LnYxLkNyZWF0ZUFwaVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uImSC0+STAi8iKC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2Fw
aXM6A2FwadpBEXBhcmVudCxhcGksYXBpX2lkykEYCgNBcGkSEU9wZXJhdGlvbk1ldGFkYXRh
EsABCglVcGRhdGVBcGkSLC5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5VcGRhdGVBcGlS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJmgtPkkwIzMiwvdjEve2Fw
aS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYXBpcy8qfToDYXBp2kEPYXBpLHVwZGF0
ZV9tYXNrykEYCgNBcGkSEU9wZXJhdGlvbk1ldGFkYXRhEr4BCglEZWxldGVBcGkSLC5nb29n
bGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5EZWxldGVBcGlSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbiJkgtPkkwIqKigvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hcGlzLyp92kEEbmFtZcpBKgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRp
b25NZXRhZGF0YRK8AQoOTGlzdEFwaUNvbmZpZ3MSMS5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdh
eS52MS5MaXN0QXBpQ29uZmlnc1JlcXVlc3QaMi5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52
MS5MaXN0QXBpQ29uZmlnc1Jlc3BvbnNlIkOC0+STAjQSMi92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyovYXBpcy8qfS9jb25maWdz2kEGcGFyZW50EqkBCgxHZXRBcGlDb25m
aWcSLy5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5HZXRBcGlDb25maWdSZXF1ZXN0GiUu
Z29vZ2xlLmNsb3VkLmFwaWdhdGV3YXkudjEuQXBpQ29uZmlnIkGC0+STAjQSMi92MS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FwaXMvKi9jb25maWdzLyp92kEEbmFtZRLwAQoP
Q3JlYXRlQXBpQ29uZmlnEjIuZ29vZ2xlLmNsb3VkLmFwaWdhdGV3YXkudjEuQ3JlYXRlQXBp
Q29uZmlnUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iiQGC0+STAkAi
Mi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYXBpcy8qfS9jb25maWdzOgph
cGlfY29uZmln2kEfcGFyZW50LGFwaV9jb25maWcsYXBpX2NvbmZpZ19pZMpBHgoJQXBpQ29u
ZmlnEhFPcGVyYXRpb25NZXRhZGF0YRLyAQoPVXBkYXRlQXBpQ29uZmlnEjIuZ29vZ2xlLmNs
b3VkLmFwaWdhdGV3YXkudjEuVXBkYXRlQXBpQ29uZmlnUmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24iiwGC0+STAksyPS92MS97YXBpX2NvbmZpZy5uYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovYXBpcy8qL2NvbmZpZ3MvKn06CmFwaV9jb25maWfaQRZhcGlf
Y29uZmlnLHVwZGF0ZV9tYXNrykEeCglBcGlDb25maWcSEU9wZXJhdGlvbk1ldGFkYXRhEtQB
Cg9EZWxldGVBcGlDb25maWcSMi5nb29nbGUuY2xvdWQuYXBpZ2F0ZXdheS52MS5EZWxldGVB
cGlDb25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJugtPkkwI0
KjIvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hcGlzLyovY29uZmlncy8qfdpB
BG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIRT3BlcmF0aW9uTWV0YWRhdGEaTcpB
GWFwaWdhdGV3YXkuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtQrwBCh5jb20uZ29vZ2xlLmNsb3VkLmFwaWdhdGV3YXku
djFQAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlnYXRld2F5L2FwaXYxL2FwaWdhdGV3YXlw
YjthcGlnYXRld2F5cGKqAhpHb29nbGUuQ2xvdWQuQXBpR2F0ZXdheS5WMcoCGkdvb2dsZVxD
bG91ZFxBcGlHYXRld2F5XFYx6gIdR29vZ2xlOjpDbG91ZDo6QXBpR2F0ZXdheTo6VjFKrB0K
BxIFDgDEAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMK
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUADUKCQoCAwMSAxUALQoICgEIEgMXADcK
CQoCCCUSAxcANwoICgEIEgMYAFUKCQoCCAsSAxgAVQoICgEIEgMZACIKCQoCCAoSAxkAIgoI
CgEIEgMaADcKCQoCCAESAxoANwoICgEIEgMbADcKCQoCCCkSAxsANwoICgEIEgMcADYKCQoC
CC0SAxwANgpSCgIGABIFHwDEAQEaRSBUaGUgQVBJIEdhdGV3YXkgU2VydmljZSBpcyB0aGUg
aW50ZXJmYWNlIGZvciBtYW5hZ2luZyBBUEkgR2F0ZXdheXMuCgoKCgMGAAESAx8IGQoKCgMG
AAMSAyACQQoMCgUGAAOZCBIDIAJBCgoKAwYAAxIDIQJWCgwKBQYAA5oIEgMhAlYKPwoEBgAC
ABIEJAIpAxoxIExpc3RzIEdhdGV3YXlzIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRp
b24uCgoMCgUGAAIAARIDJAYSCgwKBQYAAgACEgMkEyYKDAoFBgACAAMSAyQxRQoNCgUGAAIA
BBIEJQQnBgoRCgkGAAIABLDKvCISBCUEJwYKDAoFBgACAAQSAygENAoPCggGAAIABJsIABID
KAQ0CjEKBAYAAgESBCwCMQMaIyBHZXRzIGRldGFpbHMgb2YgYSBzaW5nbGUgR2F0ZXdheS4K
CgwKBQYAAgEBEgMsBhAKDAoFBgACAQISAywRIgoMCgUGAAIBAxIDLC00Cg0KBQYAAgEEEgQt
BC8GChEKCQYAAgEEsMq8IhIELQQvBgoMCgUGAAIBBBIDMAQyCg8KCAYAAgEEmwgAEgMwBDIK
RgoEBgACAhIENAI+Axo4IENyZWF0ZXMgYSBuZXcgR2F0ZXdheSBpbiBhIGdpdmVuIHByb2pl
Y3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAgESAzQGEwoMCgUGAAICAhIDNBQoCgwKBQYAAgID
EgM0M08KDQoFBgACAgQSBDUEOAYKEQoJBgACAgSwyrwiEgQ1BDgGCgwKBQYAAgIEEgM5BEcK
DwoIBgACAgSbCAASAzkERwoNCgUGAAICBBIEOgQ9BgoPCgcGAAICBJkIEgQ6BD0GCjsKBAYA
AgMSBEECSwMaLSBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIEdhdGV3YXku
CgoMCgUGAAIDARIDQQYTCgwKBQYAAgMCEgNBFCgKDAoFBgACAwMSA0EzTwoNCgUGAAIDBBIE
QgRFBgoRCgkGAAIDBLDKvCISBEIERQYKDAoFBgACAwQSA0YEQQoPCggGAAIDBJsIABIDRgRB
Cg0KBQYAAgMEEgRHBEoGCg8KBwYAAgMEmQgSBEcESgYKKQoEBgACBBIETgJXAxobIERlbGV0
ZXMgYSBzaW5nbGUgR2F0ZXdheS4KCgwKBQYAAgQBEgNOBhMKDAoFBgACBAISA04UKAoMCgUG
AAIEAxIDTjNPCg0KBQYAAgQEEgRPBFEGChEKCQYAAgQEsMq8IhIETwRRBgoMCgUGAAIEBBID
UgQyCg8KCAYAAgQEmwgAEgNSBDIKDQoFBgACBAQSBFMEVgYKDwoHBgACBASZCBIEUwRWBgo7
CgQGAAIFEgRaAl8DGi0gTGlzdHMgQXBpcyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0
aW9uLgoKDAoFBgACBQESA1oGDgoMCgUGAAIFAhIDWg8eCgwKBQYAAgUDEgNaKTkKDQoFBgAC
BQQSBFsEXQYKEQoJBgACBQSwyrwiEgRbBF0GCgwKBQYAAgUEEgNeBDQKDwoIBgACBQSbCAAS
A14ENAotCgQGAAIGEgRiAmcDGh8gR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIEFwaS4KCgwK
BQYAAgYBEgNiBgwKDAoFBgACBgISA2INGgoMCgUGAAIGAxIDYiUoCg0KBQYAAgYEEgRjBGUG
ChEKCQYAAgYEsMq8IhIEYwRlBgoMCgUGAAIGBBIDZgQyCg8KCAYAAgYEmwgAEgNmBDIKQgoE
BgACBxIEagJ0Axo0IENyZWF0ZXMgYSBuZXcgQXBpIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQg
bG9jYXRpb24uCgoMCgUGAAIHARIDagYPCgwKBQYAAgcCEgNqECAKDAoFBgACBwMSA2orRwoN
CgUGAAIHBBIEawRuBgoRCgkGAAIHBLDKvCISBGsEbgYKDAoFBgACBwQSA28EPwoPCggGAAIH
BJsIABIDbwQ/Cg0KBQYAAgcEEgRwBHMGCg8KBwYAAgcEmQgSBHAEcwYKOAoEBgACCBIFdwKB
AQMaKSBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIEFwaS4KCgwKBQYAAggB
EgN3Bg8KDAoFBgACCAISA3cQIAoMCgUGAAIIAxIDdytHCg0KBQYAAggEEgR4BHsGChEKCQYA
AggEsMq8IhIEeAR7BgoMCgUGAAIIBBIDfAQ9Cg8KCAYAAggEmwgAEgN8BD0KDgoFBgACCAQS
BX0EgAEGChAKBwYAAggEmQgSBX0EgAEGCicKBAYAAgkSBoQBAo0BAxoXIERlbGV0ZXMgYSBz
aW5nbGUgQXBpLgoKDQoFBgACCQESBIQBBg8KDQoFBgACCQISBIQBECAKDQoFBgACCQMSBIQB
K0cKDwoFBgACCQQSBoUBBIcBBgoTCgkGAAIJBLDKvCISBoUBBIcBBgoNCgUGAAIJBBIEiAEE
MgoQCggGAAIJBJsIABIEiAEEMgoPCgUGAAIJBBIGiQEEjAEGChEKBwYAAgkEmQgSBokBBIwB
BgpDCgQGAAIKEgaQAQKVAQMaMyBMaXN0cyBBcGlDb25maWdzIGluIGEgZ2l2ZW4gcHJvamVj
dCBhbmQgbG9jYXRpb24uCgoNCgUGAAIKARIEkAEGFAoNCgUGAAIKAhIEkAEVKgoNCgUGAAIK
AxIEkAE1SwoPCgUGAAIKBBIGkQEEkwEGChMKCQYAAgoEsMq8IhIGkQEEkwEGCg0KBQYAAgoE
EgSUAQQ0ChAKCAYAAgoEmwgAEgSUAQQ0CjUKBAYAAgsSBpgBAp0BAxolIEdldHMgZGV0YWls
cyBvZiBhIHNpbmdsZSBBcGlDb25maWcuCgoNCgUGAAILARIEmAEGEgoNCgUGAAILAhIEmAET
JgoNCgUGAAILAxIEmAExOgoPCgUGAAILBBIGmQEEmwEGChMKCQYAAgsEsMq8IhIGmQEEmwEG
Cg0KBQYAAgsEEgScAQQyChAKCAYAAgsEmwgAEgScAQQyCkoKBAYAAgwSBqABAqoBAxo6IENy
ZWF0ZXMgYSBuZXcgQXBpQ29uZmlnIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24u
CgoNCgUGAAIMARIEoAEGFQoNCgUGAAIMAhIEoAEWLAoNCgUGAAIMAxIEoAE3UwoPCgUGAAIM
BBIGoQEEpAEGChMKCQYAAgwEsMq8IhIGoQEEpAEGCg0KBQYAAgwEEgSlAQRNChAKCAYAAgwE
mwgAEgSlAQRNCg8KBQYAAgwEEgamAQSpAQYKEQoHBgACDASZCBIGpgEEqQEGCj8KBAYAAg0S
Bq0BArcBAxovIFVwZGF0ZXMgdGhlIHBhcmFtZXRlcnMgb2YgYSBzaW5nbGUgQXBpQ29uZmln
LgoKDQoFBgACDQESBK0BBhUKDQoFBgACDQISBK0BFiwKDQoFBgACDQMSBK0BN1MKDwoFBgAC
DQQSBq4BBLEBBgoTCgkGAAINBLDKvCISBq4BBLEBBgoNCgUGAAINBBIEsgEERAoQCggGAAIN
BJsIABIEsgEERAoPCgUGAAINBBIGswEEtgEGChEKBwYAAg0EmQgSBrMBBLYBBgotCgQGAAIO
Ega6AQLDAQMaHSBEZWxldGVzIGEgc2luZ2xlIEFwaUNvbmZpZy4KCg0KBQYAAg4BEgS6AQYV
Cg0KBQYAAg4CEgS6ARYsCg0KBQYAAg4DEgS6ATdTCg8KBQYAAg4EEga7AQS9AQYKEwoJBgAC
DgSwyrwiEga7AQS9AQYKDQoFBgACDgQSBL4BBDIKEAoIBgACDgSbCAASBL4BBDIKDwoFBgAC
DgQSBr8BBMIBBgoRCgcGAAIOBJkIEga/AQTCAQZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Apigateway::V1::ApigatewayService::ApiGatewayServiceClient ===
package Google::Cloud::Apigateway::V1::ApigatewayService::ApiGatewayServiceClient;

=pod

=head2 Service Client: Google::Cloud::Apigateway::V1::ApigatewayService::ApiGatewayServiceClient

Client stub representing the remote C<ApiGatewayService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apigateway.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apigateway.googleapis.com:443' );

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

sub list_gateways {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'ListGateways',
        request        => $req,
        response_class => 'Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysResponse',
    });
}

sub get_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::GetGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'GetGateway',
        request        => $req,
        response_class => 'Google::Cloud::Apigateway::V1::Apigateway::Gateway',
    });
}

sub create_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::CreateGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'CreateGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::UpdateGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'UpdateGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_gateway {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::DeleteGatewayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'DeleteGateway',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_apis {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::ListApisRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'ListApis',
        request        => $req,
        response_class => 'Google::Cloud::Apigateway::V1::Apigateway::ListApisResponse',
    });
}

sub get_api {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::GetApiRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'GetApi',
        request        => $req,
        response_class => 'Google::Cloud::Apigateway::V1::Apigateway::Api',
    });
}

sub create_api {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::CreateApiRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'CreateApi',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_api {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::UpdateApiRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'UpdateApi',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_api {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::DeleteApiRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'DeleteApi',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_api_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'ListApiConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsResponse',
    });
}

sub get_api_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::GetApiConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'GetApiConfig',
        request        => $req,
        response_class => 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig',
    });
}

sub create_api_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::CreateApiConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'CreateApiConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_api_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::UpdateApiConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'UpdateApiConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_api_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigateway::V1::Apigateway::DeleteApiConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigateway.v1.ApiGatewayService',
        method         => 'DeleteApiConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apigateway::V1::ApigatewayService - Compiled Protocol Buffers messages for google/cloud/apigateway/v1/apigateway_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apigateway/v1/apigateway_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apigateway::V1::ApigatewayService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
