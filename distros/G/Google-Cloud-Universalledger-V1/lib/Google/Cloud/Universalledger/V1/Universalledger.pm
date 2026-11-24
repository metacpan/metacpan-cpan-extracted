package Google::Cloud::Universalledger::V1::Universalledger;

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
    eval { require Google::Cloud::Universalledger::V1::Query };
    eval { require Google::Cloud::Universalledger::V1::Types };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvdW5pdmVyc2FsbGVkZ2VyL3YxL3VuaXZlcnNhbGxlZGdlci5wcm90
bxIfZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aK2dvb2dsZS9jbG91
ZC91bml2ZXJzYWxsZWRnZXIvdjEvcXVlcnkucHJvdG8aK2dvb2dsZS9jbG91ZC91bml2ZXJz
YWxsZWRnZXIvdjEvdHlwZXMucHJvdG8ipAEKCEVuZHBvaW50EhcKBG5hbWUYASABKAlCA+BB
CFIEbmFtZTp/6kF8Cid1bml2ZXJzYWxsZWRnZXIuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnQS
PHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9lbmRwb2ludHMve2Vu
ZHBvaW50fSoJZW5kcG9pbnRzMghlbmRwb2ludCKlAQoUTGlzdEVuZHBvaW50c1JlcXVlc3QS
RwoGcGFyZW50GAEgASgJQi/gQQL6QSkSJ3VuaXZlcnNhbGxlZGdlci5nb29nbGVhcGlzLmNv
bS9FbmRwb2ludFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIi
CgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKIAQoVTGlzdEVuZHBvaW50c1Jl
c3BvbnNlEkcKCWVuZHBvaW50cxgBIAMoCzIpLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRn
ZXIudjEuRW5kcG9pbnRSCWVuZHBvaW50cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4iWQoSR2V0RW5kcG9pbnRSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpB
KQondW5pdmVyc2FsbGVkZ2VyLmdvb2dsZWFwaXMuY29tL0VuZHBvaW50UgRuYW1lInoKE1F1
ZXJ5QWNjb3VudFJlcXVlc3QSHwoIZW5kcG9pbnQYASABKAlCA+BBAlIIZW5kcG9pbnQSIgoK
YWNjb3VudF9pZBgCIAEoCUID4EECUglhY2NvdW50SWQSHgoIcm91bmRfaWQYAyABKANCA+BB
AVIHcm91bmRJZCJaChRRdWVyeUFjY291bnRSZXNwb25zZRJCCgdhY2NvdW50GAEgASgLMigu
Z29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5BY2NvdW50UgdhY2NvdW50IoQBChhT
dWJtaXRUcmFuc2FjdGlvblJlcXVlc3QSHwoIZW5kcG9pbnQYASABKAlCA+BBAlIIZW5kcG9p
bnQSRwodc2VyaWFsaXplZF9zaWduZWRfdHJhbnNhY3Rpb24YAiABKAxCA+BBAlIbc2VyaWFs
aXplZFNpZ25lZFRyYW5zYWN0aW9uIlEKGVN1Ym1pdFRyYW5zYWN0aW9uUmVzcG9uc2USNAoW
dHJhbnNhY3Rpb25fZGlnZXN0X2hleBgBIAEoCVIUdHJhbnNhY3Rpb25EaWdlc3RIZXgipgEK
I1N1Ym1pdE9wZXJhdGlvbmFsVHJhbnNhY3Rpb25SZXF1ZXN0Eh8KCGVuZHBvaW50GAEgASgJ
QgPgQQJSCGVuZHBvaW50El4KKXNlcmlhbGl6ZWRfc2lnbmVkX29wZXJhdGlvbmFsX3RyYW5z
YWN0aW9uGAIgASgMQgPgQQJSJnNlcmlhbGl6ZWRTaWduZWRPcGVyYXRpb25hbFRyYW5zYWN0
aW9uIlwKJFN1Ym1pdE9wZXJhdGlvbmFsVHJhbnNhY3Rpb25SZXNwb25zZRI0ChZ0cmFuc2Fj
dGlvbl9kaWdlc3RfaGV4GAEgASgJUhR0cmFuc2FjdGlvbkRpZ2VzdEhleCJ6ChxRdWVyeVRy
YW5zYWN0aW9uU3RhdGVSZXF1ZXN0Eh8KCGVuZHBvaW50GAEgASgJQgPgQQJSCGVuZHBvaW50
EjkKFnRyYW5zYWN0aW9uX2RpZ2VzdF9oZXgYAiABKAlCA+BBAlIUdHJhbnNhY3Rpb25EaWdl
c3RIZXgihwEKHVF1ZXJ5VHJhbnNhY3Rpb25TdGF0ZVJlc3BvbnNlEmYKFHRyYW5zYWN0aW9u
X2F0dGVtcHRzGAEgAygLMjMuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5UcmFu
c2FjdGlvbkF0dGVtcHRSE3RyYW5zYWN0aW9uQXR0ZW1wdHMifwoQUXVlcnlEYXRhUmVxdWVz
dBIfCghlbmRwb2ludBgBIAEoCUID4EECUghlbmRwb2ludBJKCh9zZXJpYWxpemVkX3NpZ25l
ZF9xdWVyeV9yZXF1ZXN0GAIgASgMQgPgQQJSHHNlcmlhbGl6ZWRTaWduZWRRdWVyeVJlcXVl
c3QinAIKEVF1ZXJ5RGF0YVJlc3BvbnNlEkQKB2FjY291bnQYASABKAsyKC5nb29nbGUuY2xv
dWQudW5pdmVyc2FsbGVkZ2VyLnYxLkFjY291bnRIAFIHYWNjb3VudBJgChF0cmFuc2FjdGlv
bl9zdGF0ZRgCIAEoCzIxLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuVHJhbnNh
Y3Rpb25TdGF0ZUgAUhB0cmFuc2FjdGlvblN0YXRlElcKD3JlZGFjdGVkX2ZpZWxkcxgDIAMo
CzIuLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuUmVkYWN0ZWRGaWVsZFIOcmVk
YWN0ZWRGaWVsZHNCBgoEa2luZDLvDQoPVW5pdmVyc2FsTGVkZ2VyEoMCChFTdWJtaXRUcmFu
c2FjdGlvbhI5Lmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuU3VibWl0VHJhbnNh
Y3Rpb25SZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5TdWJtaXRU
cmFuc2FjdGlvblJlc3BvbnNlIneC0+STAkgiQy92MS97ZW5kcG9pbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9lbmRwb2ludHMvKn06c3VibWl0VHJhbnNhY3Rpb246ASraQSZlbmRwb2lu
dCxzZXJpYWxpemVkX3NpZ25lZF90cmFuc2FjdGlvbhK+AQoNTGlzdEVuZHBvaW50cxI1Lmdv
b2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuTGlzdEVuZHBvaW50c1JlcXVlc3QaNi5n
b29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkxpc3RFbmRwb2ludHNSZXNwb25zZSI+
gtPkkwIvEi0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9lbmRwb2ludHPa
QQZwYXJlbnQSqwEKC0dldEVuZHBvaW50EjMuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdl
ci52MS5HZXRFbmRwb2ludFJlcXVlc3QaKS5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2Vy
LnYxLkVuZHBvaW50IjyC0+STAi8SLS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2VuZHBvaW50cy8qfdpBBG5hbWUSvAIKHFN1Ym1pdE9wZXJhdGlvbmFsVHJhbnNhY3Rpb24S
RC5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLlN1Ym1pdE9wZXJhdGlvbmFsVHJh
bnNhY3Rpb25SZXF1ZXN0GkUuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5TdWJt
aXRPcGVyYXRpb25hbFRyYW5zYWN0aW9uUmVzcG9uc2UijgGC0+STAlMiTi92MS97ZW5kcG9p
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9lbmRwb2ludHMvKn06c3VibWl0T3BlcmF0aW9u
YWxUcmFuc2FjdGlvbjoBKtpBMmVuZHBvaW50LHNlcmlhbGl6ZWRfc2lnbmVkX29wZXJhdGlv
bmFsX3RyYW5zYWN0aW9uEowCChVRdWVyeVRyYW5zYWN0aW9uU3RhdGUSPS5nb29nbGUuY2xv
dWQudW5pdmVyc2FsbGVkZ2VyLnYxLlF1ZXJ5VHJhbnNhY3Rpb25TdGF0ZVJlcXVlc3QaPi5n
b29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLlF1ZXJ5VHJhbnNhY3Rpb25TdGF0ZVJl
c3BvbnNlInSIAgGC0+STAkkSRy92MS97ZW5kcG9pbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9lbmRwb2ludHMvKn06cXVlcnlUcmFuc2FjdGlvblN0YXRl2kEfZW5kcG9pbnQsdHJhbnNh
Y3Rpb25fZGlnZXN0X2hleBLcAQoMUXVlcnlBY2NvdW50EjQuZ29vZ2xlLmNsb3VkLnVuaXZl
cnNhbGxlZGdlci52MS5RdWVyeUFjY291bnRSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLnVuaXZl
cnNhbGxlZGdlci52MS5RdWVyeUFjY291bnRSZXNwb25zZSJfiAIBgtPkkwJAEj4vdjEve2Vu
ZHBvaW50PXByb2plY3RzLyovbG9jYXRpb25zLyovZW5kcG9pbnRzLyp9OnF1ZXJ5QWNjb3Vu
dNpBE2VuZHBvaW50LGFjY291bnRfaWQS5QEKCVF1ZXJ5RGF0YRIxLmdvb2dsZS5jbG91ZC51
bml2ZXJzYWxsZWRnZXIudjEuUXVlcnlEYXRhUmVxdWVzdBoyLmdvb2dsZS5jbG91ZC51bml2
ZXJzYWxsZWRnZXIudjEuUXVlcnlEYXRhUmVzcG9uc2UicYLT5JMCQCI7L3YxL3tlbmRwb2lu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2VuZHBvaW50cy8qfTpxdWVyeURhdGE6ASraQShl
bmRwb2ludCxzZXJpYWxpemVkX3NpZ25lZF9xdWVyeV9yZXF1ZXN0GlLKQR51bml2ZXJzYWxs
ZWRnZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Nsb3VkLXBsYXRmb3JtQvUBCiNjb20uZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52
MUIUVW5pdmVyc2FsTGVkZ2VyUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby91bml2ZXJz
YWxsZWRnZXIvYXBpdjEvdW5pdmVyc2FsbGVkZ2VycGI7dW5pdmVyc2FsbGVkZ2VycGKqAh9H
b29nbGUuQ2xvdWQuVW5pdmVyc2FsTGVkZ2VyLlYxygIfR29vZ2xlXENsb3VkXFVuaXZlcnNh
bExlZGdlclxWMeoCIkdvb2dsZTo6Q2xvdWQ6OlVuaXZlcnNhbExlZGdlcjo6VjFKvVkKBxIF
DgDFAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA1CgkK
AgMFEgMXADUKCAoBCBIDGQA8CgkKAgglEgMZADwKCAoBCBIDGgBkCgkKAggLEgMaAGQKCAoB
CBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA1CgkKAggIEgMcADUKCAoBCBIDHQA8CgkKAggB
EgMdADwKCAoBCBIDHgA8CgkKAggpEgMeADwKCAoBCBIDHwA7CgkKAggtEgMfADsKrwMKAgYA
EgUpAIkBARqhAyBBIHNlcnZpY2UgZm9yIGludGVyYWN0aW5nIHdpdGggdGhlIEdvb2dsZSBD
bG91ZCBVbml2ZXJzYWwgTGVkZ2VyLgogRW5kcG9pbnRzIGFyZSBwcmUtY3JlYXRlZCBhbmQg
bWFuYWdlZCBieSBHb29nbGUgYW5kIGNhbm5vdAogYmUgbW9kaWZpZWQgYnkgdXNlcnMuCiBU
aGUgbmFtZXMgb2YgYXZhaWxhYmxlIGVuZHBvaW50cyB3aWxsIGJlIHByb3ZpZGVkIGluIHRo
ZSBwdWJsaWMKIGRvY3VtZW50YXRpb24uCiBBbiBlbmRwb2ludCBpcyBhIHJlZ2lvbmFsIHJl
c291cmNlIHdpdGhpbiBhIFVuaXZlcnNhbCBMZWRnZXIgbmV0d29yay4KIFJlcXVlc3RzIHNl
bnQgdG8gYW4gZW5kcG9pbnQgbWF5IGJlIHJvdXRlZCB0byBkaWZmZXJlbnQgdmFsaWRhdG9y
cyBpbiB0aGUKIGdpdmVuIG5ldHdvcmsgd2l0aGluIHRoZSBnaXZlbiByZWdpb24uCgoKCgMG
AAESAykIFwoKCgMGAAMSAyoCRgoMCgUGAAOZCBIDKgJGCgsKAwYAAxIEKwIsNwoNCgUGAAOa
CBIEKwIsNwrQAgoEBgACABIENAI8AxrBAiBTdWJtaXRzIGEgdHJhbnNhY3Rpb24gdG8gdGhl
IG5ldHdvcmsuCiBUaGUgcmVxdWVzdCBpcyBmaXJzdCB2YWxpZGF0ZWQgZm9yIGJhc2ljIGNv
cnJlY3RuZXNzLiBJZiB2YWxpZGF0aW9uIGZhaWxzLAogdGhlIHJlcXVlc3Qgd2lsbCBmYWls
IGltbWVkaWF0ZWx5LgogSWYgdmFsaWRhdGlvbiBzdWNjZWVkcywgdGhpcyBtZXRob2QgcmV0
dXJucyBvbmx5IGFmdGVyIHRoZSB0cmFuc2FjdGlvbiBoYXMKIGJlZW4gcmVwbGljYXRlZCBh
Y3Jvc3MgYSBtYWpvcml0eSBvZiB2YWxpZGF0b3JzIGluIHRoZSBuZXR3b3JrLCBvciB1bnRp
bAogdGhlIHJlcXVlc3QgZmFpbHMuCgoMCgUGAAIAARIDNAYXCgwKBQYAAgACEgM0GDAKDAoF
BgACAAMSAzUPKAoNCgUGAAIABBIENgQ5BgoRCgkGAAIABLDKvCISBDYEOQYKDQoFBgACAAQS
BDoEOzEKEAoIBgACAASbCAASBDoEOzEKRQoEBgACARIEPwJEAxo3IExpc3RzIGFsbCBlbmRw
b2ludHMgZm9yIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIBARIDPwYT
CgwKBQYAAgECEgM/FCgKDAoFBgACAQMSAz8zSAoNCgUGAAIBBBIEQARCBgoRCgkGAAIBBLDK
vCISBEAEQgYKDAoFBgACAQQSA0MENAoPCggGAAIBBJsIABIDQwQ0CjgKBAYAAgISBEcCTAMa
KiBHZXRzIHRoZSBkZXRhaWxzIG9mIGEgc3BlY2lmaWMgZW5kcG9pbnQuCgoMCgUGAAICARID
RwYRCgwKBQYAAgICEgNHEiQKDAoFBgACAgMSA0cvNwoNCgUGAAICBBIESARKBgoRCgkGAAIC
BLDKvCISBEgESgYKDAoFBgACAgQSA0sEMgoPCggGAAICBJsIABIDSwQyCtUBCgQGAAIDEgRR
AlkDGsYBIFN1Ym1pdHMgYW4gb3BlcmF0aW9uYWwgdHJhbnNhY3Rpb24gdG8gdGhlIG5ldHdv
cmsuCiBUaGlzIG1ldGhvZCByZXR1cm5zIG9ubHkgYWZ0ZXIgdGhlIHRyYW5zYWN0aW9uIGhh
cyBiZWVuIHJlcGxpY2F0ZWQgYWNyb3NzIGEKIG1ham9yaXR5IG9mIHZhbGlkYXRvcnMgaW4g
dGhlIG5ldHdvcmssIG9yIGlmIHRoZSB0cmFuc2FjdGlvbiBmYWlscy4KCgwKBQYAAgMBEgNR
BiIKDAoFBgACAwISA1EjRgoMCgUGAAIDAxIDUg8zCg0KBQYAAgMEEgRTBFYGChEKCQYAAgME
sMq8IhIEUwRWBgoNCgUGAAIDBBIEVwRYPQoQCggGAAIDBJsIABIEVwRYPQrKAwoEBgACBBIE
YgJpAxq7AyBEZXByZWNhdGVkOiBVc2UgdGhlCiBbUXVlcnlEYXRhXVtnb29nbGUuY2xvdWQu
dW5pdmVyc2FsbGVkZ2VyLnYxLlVuaXZlcnNhbExlZGdlci5RdWVyeURhdGFdCiBtZXRob2Qg
aW5zdGVhZC4gUXVlcmllcyB0aGUgc3RhdGUgb2YgYSB0cmFuc2FjdGlvbi4gVGhpcyBtZXRo
b2QgY2FuIGJlCiBjYWxsZWQgZm9yIGFueSB0cmFuc2FjdGlvbiBzdWJtaXR0ZWQgdG8gdGhl
IG5ldHdvcmsuIFRoZSByZXR1cm5lZAogdHJhbnNhY3Rpb24gZGV0YWlscyBtYXkgdmFyeSBi
ZXR3ZWVuIGNhbGxzLCBiZWNhdXNlIGFuIGVuZHBvaW50IG1heSByb3V0ZQogcmVxdWVzdHMg
dG8gZGlmZmVyZW50IHZhbGlkYXRvcnMgd2l0aGluIHRoZSBuZXR3b3JrIGFuZCByZWdpb24s
IGFuZCB0aGUKIHZhbGlkYXRvcnMgbWF5IG5vdCBiZSBhdCB0aGUgc2FtZSByb3VuZCBJRCBh
dCBhbnkgZ2l2ZW4gdGltZS4KCgwKBQYAAgQBEgNiBhsKDAoFBgACBAISA2IcOAoMCgUGAAIE
AxIDYw8sCgwKBQYAAgQEEgNkBB0KDQoGBgACBAQhEgNkBB0KDQoFBgACBAQSBGUEZwYKEQoJ
BgACBASwyrwiEgRlBGcGCgwKBQYAAgQEEgNoBE0KDwoIBgACBASbCAASA2gETQqeAwoEBgAC
BRIEcgJ4AxqPAyBEZXByZWNhdGVkOiBVc2UgdGhlCiBbUXVlcnlEYXRhXVtnb29nbGUuY2xv
dWQudW5pdmVyc2FsbGVkZ2VyLnYxLlVuaXZlcnNhbExlZGdlci5RdWVyeURhdGFdCiBtZXRo
b2QgaW5zdGVhZC4gUXVlcmllcyBhbGwgdGhlIGluZm9ybWF0aW9uIHN0b3JlZCBhYm91dCBh
biBhY2NvdW50IGluIHRoZQogbmV0d29yay4gVGhlIHJldHVybmVkIGFjY291bnQgZGV0YWls
cyBtYXkgdmFyeSBiZXR3ZWVuIGNhbGxzLCBiZWNhdXNlIGFuCiBlbmRwb2ludCBtYXkgcm91
dGUgcmVxdWVzdHMgdG8gZGlmZmVyZW50IHZhbGlkYXRvcnMgd2l0aGluIHRoZSBuZXR3b3Jr
IGFuZAogcmVnaW9uLCBhbmQgdGhlIHZhbGlkYXRvcnMgbWF5IG5vdCBiZSBhdCB0aGUgc2Ft
ZSByb3VuZCBJRCBhdCBhbnkgZ2l2ZW4KIHRpbWUuCgoMCgUGAAIFARIDcgYSCgwKBQYAAgUC
EgNyEyYKDAoFBgACBQMSA3IxRQoMCgUGAAIFBBIDcwQdCg0KBgYAAgUEIRIDcwQdCg0KBQYA
AgUEEgR0BHYGChEKCQYAAgUEsMq8IhIEdAR2BgoMCgUGAAIFBBIDdwRBCg8KCAYAAgUEmwgA
EgN3BEEKlQMKBAYAAgYSBoEBAogBAxqEAyBRdWVyaWVzIHRoZSBuZXR3b3JrIGZvciBpbmZv
cm1hdGlvbiBzdG9yZWQgb24gdGhlIGxlZGdlciwKIHN1Y2ggYXMgYWNjb3VudHMgYW5kIHRy
YW5zYWN0aW9ucy4KCiBBY2Nlc3MgdG8gY2VydGFpbiBzZW5zaXRpdmUgZmllbGRzLCBzdWNo
IGFzIGFjY291bnQgYmFsYW5jZXMsIG1heSBiZQogcmVzdHJpY3RlZCBiYXNlZCBvbiB0aGUg
aWRlbnRpdHkgb2YgdGhlIHNlbmRlciBkZXJpdmVkIGZyb20gdGhlIHNpZ25hdHVyZQogaW4g
dGhlIHJlcXVlc3QuIElmIHRoZSBzZW5kZXIgbGFja3MgcGVybWlzc2lvbiwgc2Vuc2l0aXZl
IGZpZWxkcyB3aWxsIGJlCiByZWRhY3RlZCBmcm9tIHRoZSByZXNwb25zZSBhbmQgcmVwb3J0
ZWQgaW4gdGhlIGByZWRhY3RlZF9maWVsZHNgIGZpZWxkLgoKDQoFBgACBgESBIEBBg8KDQoF
BgACBgISBIEBECAKDQoFBgACBgMSBIEBKzwKDwoFBgACBgQSBoIBBIUBBgoTCgkGAAIGBLDK
vCISBoIBBIUBBgoPCgUGAAIGBBIGhgEEhwEzChIKCAYAAgYEmwgAEgaGAQSHATMKNwoCBAAS
BowBAJcBARopIFJlcHJlc2VudHMgYSBVbml2ZXJzYWwgTGVkZ2VyIGVuZHBvaW50LgoKCwoD
BAABEgSMAQgQCg0KAwQABxIGjQECkgEECg8KBQQAB50IEgaNAQKSAQQKhgEKBAQAAgASBJYB
Aj0aeCBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZW5kcG9pbnQuCiBG
b3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZW5kcG9p
bnRzL3tlbmRwb2ludH1gCgoNCgUEAAIABRIElgECCAoNCgUEAAIAARIElgEJDQoNCgUEAAIA
AxIElgEQEQoNCgUEAAIACBIElgESPAoQCggEAAIACJwIABIElgETOwoyCgIEARIGmgEArQEB
GiQgUmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0RW5kcG9pbnRzLgoKCwoDBAEBEgSaAQgcCoMB
CgQEAQIAEgadAQKiAQQacyBSZXF1aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3ducyB0aGlz
IGNvbGxlY3Rpb24gb2YgZW5kcG9pbnRzLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAECAAUSBJ0BAggKDQoFBAECAAESBJ0BCQ8K
DQoFBAECAAMSBJ0BEhMKDwoFBAECAAgSBp0BFKIBAwoQCggEAQIACJwIABIEngEEKgoRCgcE
AQIACJ8IEgafAQShAQUK8wEKBAQBAgESBKgBAj8a5AEgT3B0aW9uYWwuIFRoZSBtYXhpbXVt
IG51bWJlciBvZiBlbmRwb2ludHMgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkgcmV0dXJu
CiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIGVu
ZHBvaW50cyB3aWxsIGJlCiByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsg
dmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvCiAxMDAwLgoKDQoFBAECAQUS
BKgBAgcKDQoFBAECAQESBKgBCBEKDQoFBAECAQMSBKgBFBUKDQoFBAECAQgSBKgBFj4KEAoI
BAECAQicCAASBKgBFz0KhQEKBAQBAgISBKwBAkEadyBPcHRpb25hbC4gQSBwYWdlIHRva2Vu
LCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RFbmRwb2ludHNgIGNhbGwuCiBQcm92
aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQBAgIFEgSs
AQIICg0KBQQBAgIBEgSsAQkTCg0KBQQBAgIDEgSsARYXCg0KBQQBAgIIEgSsARhAChAKCAQB
AgIInAgAEgSsARk/CjMKAgQCEgawAQC3AQEaJSBSZXNwb25zZSBtZXNzYWdlIGZvciBMaXN0
RW5kcG9pbnRzLgoKCwoDBAIBEgSwAQgdCkEKBAQCAgASBLIBAiIaMyBUaGUgZW5kcG9pbnRz
IGZvciB0aGUgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoNCgUEAgIABBIEsgECCgoN
CgUEAgIABhIEsgELEwoNCgUEAgIAARIEsgEUHQoNCgUEAgIAAxIEsgEgIQqQAQoEBAICARIE
tgECHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8g
cmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhl
cmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAgIBBRIEtgECCAoNCgUEAgIBARIE
tgEJGAoNCgUEAgIBAxIEtgEbHAowCgIEAxIGugEAwwEBGiIgUmVxdWVzdCBtZXNzYWdlIGZv
ciBHZXRFbmRwb2ludC4KCgsKAwQDARIEugEIGgqJAQoEBAMCABIGvQECwgEEGnkgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBlbmRwb2ludCB0byByZXRyaWV2ZS4KIEZvcm1hdDogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9lbmRwb2ludHMve2VuZHBv
aW50fWAKCg0KBQQDAgAFEgS9AQIICg0KBQQDAgABEgS9AQkNCg0KBQQDAgADEgS9ARARCg8K
BQQDAgAIEga9ARLCAQMKEAoIBAMCAAicCAASBL4BBCoKEQoHBAMCAAifCBIGvwEEwQEFCjEK
AgQEEgbGAQDWAQEaIyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFF1ZXJ5QWNjb3VudC4KCgsKAwQE
ARIExgEIGwqgAQoEBAQCABIEygECPxqRASBSZXF1aXJlZC4gVGhlIGVuZHBvaW50IHRvIHNl
cnZlIHRoZSByZXF1ZXN0LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2VuZHBvaW50cy97ZW5kcG9pbnR9YAogVGhlIGxvY2F0aW9uIGlzIGEg
cmVnaW9uLgoKDQoFBAQCAAUSBMoBAggKDQoFBAQCAAESBMoBCREKDQoFBAQCAAMSBMoBFBUK
DQoFBAQCAAgSBMoBFj4KEAoIBAQCAAicCAASBMoBFz0KagoEBAQCARIEzgECQRpcIFJlcXVp
cmVkLiBUaGUgYWNjb3VudCBJRCB0byBnZXQgaW5mb3JtYXRpb24gYWJvdXQuIFRoZSB2YWx1
ZSBpcyBsaW1pdGVkIHRvCiA2MCBjaGFyYWN0ZXJzLgoKDQoFBAQCAQUSBM4BAggKDQoFBAQC
AQESBM4BCRMKDQoFBAQCAQMSBM4BFhcKDQoFBAQCAQgSBM4BGEAKEAoIBAQCAQicCAASBM4B
GT8K5gIKBAQEAgISBNUBAj4a1wIgT3B0aW9uYWwuIFRoZSBJRCBvZiB0aGUgZXhlY3V0aW9u
IHJvdW5kIChzaW1pbGFyIHRvIGJsb2NrICJoZWlnaHQiKSBhdAogd2hpY2ggdG8gcmVxdWVz
dCBkYXRhLiBUaGUgcmV0dXJuZWQgYWNjb3VudCBpbmZvcm1hdGlvbiB3aWxsIGJlIGFjY3Vy
YXRlCiBmb3IgdGhlIHdvcmxkIHN0YXRlIGF0IHRoaXMgZXhlY3V0aW9uIHJvdW5kLiBJZiB1
bnNwZWNpZmllZCwgdXNlcyB0aGUKIGxhdGVzdCBmaW5hbGl6ZWQgcm91bmQgYXMga25vd24g
YnkgdGhlIHNlcnZpbmcgdmFsaWRhdG9yLiBUaGUgc3RhdGUgYXQgYQogZ2l2ZW4gcm91bmQg
SUQgaXMgYWx3YXlzIGNvbnNpc3RlbnQgYW5kIGNhbm9uaWNhbC4KCg0KBQQEAgIFEgTVAQIH
Cg0KBQQEAgIBEgTVAQgQCg0KBQQEAgIDEgTVARMUCg0KBQQEAgIIEgTVARU9ChAKCAQEAgII
nAgAEgTVARY8CjIKAgQFEgbZAQDcAQEaJCBSZXNwb25zZSBtZXNzYWdlIGZvciBRdWVyeUFj
Y291bnQuCgoLCgMEBQESBNkBCBwKWAoEBAUCABIE2wECFhpKIFRoZSBhY2NvdW50IGluZm9y
bWF0aW9uLCBhbG9uZyB3aXRoIHRoZSBoZWlnaHQgYXQgd2hpY2ggaXQgd2FzIG9idGFpbmVk
LgoKDQoFBAUCAAYSBNsBAgkKDQoFBAUCAAESBNsBChEKDQoFBAUCAAMSBNsBFBUKNgoCBAYS
Bt8BAOwBARooIFJlcXVlc3QgbWVzc2FnZSBmb3IgU3VibWl0VHJhbnNhY3Rpb24uCgoLCgME
BgESBN8BCCAKqAEKBAQGAgASBOMBAj8amQEgUmVxdWlyZWQuIFRoZSBlbmRwb2ludCB0byBz
dWJtaXQgdGhlIHRyYW5zYWN0aW9uIHRvLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2VuZHBvaW50cy97ZW5kcG9pbnR9YAogVGhlIGxvY2F0
aW9uIGlzIGEgcmVnaW9uLgoKDQoFBAYCAAUSBOMBAggKDQoFBAYCAAESBOMBCREKDQoFBAYC
AAMSBOMBFBUKDQoFBAYCAAgSBOMBFj4KEAoIBAYCAAicCAASBOMBFz0KmwIKBAQGAgESBuoB
AusBLxqKAiBSZXF1aXJlZC4gQSBwcm90b2J1ZiBzZXJpYWxpemVkCiBbU2lnbmVkVHJhbnNh
Y3Rpb25dW2dvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuU2lnbmVkVHJhbnNhY3Rp
b25dIHRvCiBzdWJtaXQgdG8gdGhlIGxlZGdlci4gVXNpbmcgYSBzZXJpYWxpemVkIGZvcm1h
dCBlbnN1cmVzIHRoYXQgYWxsIHZhbGlkYXRvcnMKIGNvbXB1dGUgdGhlIHNhbWUgdHJhbnNh
Y3Rpb24gSUQgYXMgdGhlIFNIQS0yNTYgZGlnZXN0IG9mIHRoZSBzZXJpYWxpemVkCiBieXRl
cy4KCg0KBQQGAgEFEgTqAQIHCg0KBQQGAgEBEgTqAQglCg0KBQQGAgEDEgTqASgpCg0KBQQG
AgEIEgTrAQYuChAKCAQGAgEInAgAEgTrAQctCjcKAgQHEgbvAQD4AQEaKSBSZXNwb25zZSBt
ZXNzYWdlIGZvciBTdWJtaXRUcmFuc2FjdGlvbi4KCgsKAwQHARIE7wEIIQqjAwoEBAcCABIE
9wECJBqUAyBJZGVudGlmaWVyIHRoYXQgdW5pcXVlbHkgcmVwcmVzZW50cyB0aGUgc3VibWl0
dGVkIHRyYW5zYWN0aW9uLgogSXQgaXMgdGhlIGhleGFkZWNpbWFsIHJlcHJlc2VudGF0aW9u
IG9mIHRoZSBTSEEtMjU2IGRpZ2VzdCBvZiB0aGUKIGBzZXJpYWxpemVkX3NpZ25lZF90cmFu
c2FjdGlvbmAuCiBUaGlzIHRyYW5zYWN0aW9uIElEIGlzIHByb3ZpZGVkIHNvIHRoYXQgYSBj
bGllbnQgY2FuIHRyYWNrIHRoZSB0cmFuc2FjdGlvbgogd2l0aG91dCBuZWVkaW5nIHRvIGlt
cGxlbWVudCB0aGUgaGFzaGluZyBsb2dpYyBpdHNlbGYuCiBUaGUgaWRlbnRpZmllciBjYW4g
YmUgZGlyZWN0bHkgdXNlZCBpbiBzdWJzZXF1ZW50IEFQSSBjYWxscywgZm9yIGV4YW1wbGUg
dG8KIHF1ZXJ5IHRoZSB0cmFuc2FjdGlvbiBzdGF0ZS4KCg0KBQQHAgAFEgT3AQIICg0KBQQH
AgABEgT3AQkfCg0KBQQHAgADEgT3ASIjCkEKAgQIEgb7AQCJAgEaMyBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIFN1Ym1pdE9wZXJhdGlvbmFsVHJhbnNhY3Rpb24uCgoLCgMECAESBPsBCCsKoAEK
BAQIAgASBP8BAj8akQEgUmVxdWlyZWQuIFRoZSBlbmRwb2ludCB0byBzZXJ2ZSB0aGUgcmVx
dWVzdC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9lbmRwb2ludHMve2VuZHBvaW50fWAKIFRoZSBsb2NhdGlvbiBpcyBhIHJlZ2lvbi4KCg0K
BQQIAgAFEgT/AQIICg0KBQQIAgABEgT/AQkRCg0KBQQIAgADEgT/ARQVCg0KBQQIAgAIEgT/
ARY+ChAKCAQIAgAInAgAEgT/ARc9Co4DCgQECAIBEgaHAgKIAi8a/QIgUmVxdWlyZWQuIEEg
cHJvdG9idWYgc2VyaWFsaXplZAogW1NpZ25lZFRyYW5zYWN0aW9uXVtnb29nbGUuY2xvdWQu
dW5pdmVyc2FsbGVkZ2VyLnYxLlNpZ25lZFRyYW5zYWN0aW9uXSB0bwogc3VibWl0IHRvIHRo
ZSBsZWRnZXIuIFRoZSBlbmNsb3NlZCBjbGllbnQgdHJhbnNhY3Rpb24gbXVzdCBiZSBhbgog
b3BlcmF0aW9uYWwgdHJhbnNhY3Rpb24sIGFuZCB0aGUgc2VuZGVyIG11c3QgYmUgdGhlIHBs
YXRmb3JtIG9wZXJhdG9yLgogVXNpbmcgYSBzZXJpYWxpemVkIGZvcm1hdCBlbnN1cmVzIHRo
YXQgYWxsIHZhbGlkYXRvcnMgY29tcHV0ZSB0aGUgc2FtZQogdHJhbnNhY3Rpb24gSUQgYXMg
dGhlIFNIQS0yNTYgZGlnZXN0IG9mIHRoZSBzZXJpYWxpemVkIGJ5dGVzLgoKDQoFBAgCAQUS
BIcCAgcKDQoFBAgCAQESBIcCCDEKDQoFBAgCAQMSBIcCNDUKDQoFBAgCAQgSBIgCBi4KEAoI
BAgCAQicCAASBIgCBy0KQgoCBAkSBowCAJUCARo0IFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFN1
Ym1pdE9wZXJhdGlvbmFsVHJhbnNhY3Rpb24uCgoLCgMECQESBIwCCCwKuwMKBAQJAgASBJQC
AiQarAMgSWRlbnRpZmllciB0aGF0IHVuaXF1ZWx5IHJlcHJlc2VudHMgdGhlIHN1Ym1pdHRl
ZCBvcGVyYXRpb25hbCB0cmFuc2FjdGlvbi4KIEl0IGlzIHRoZSBoZXhhZGVjaW1hbCByZXBy
ZXNlbnRhdGlvbiBvZiB0aGUgU0hBLTI1NiBkaWdlc3Qgb2YgdGhlCiBgc2VyaWFsaXplZF9z
aWduZWRfb3BlcmF0aW9uYWxfdHJhbnNhY3Rpb25gLgogVGhpcyB0cmFuc2FjdGlvbiBJRCBp
cyBwcm92aWRlZCBzbyB0aGF0IGEgY2xpZW50IGNhbiB0cmFjayB0aGUgdHJhbnNhY3Rpb24K
IHdpdGhvdXQgbmVlZGluZyB0byBpbXBsZW1lbnQgdGhlIGhhc2hpbmcgbG9naWMgaXRzZWxm
LgogVGhlIGlkZW50aWZpZXIgY2FuIGJlIGRpcmVjdGx5IHVzZWQgaW4gc3Vic2VxdWVudCBB
UEkgY2FsbHMsIGZvciBleGFtcGxlIHRvCiBxdWVyeSB0aGUgdHJhbnNhY3Rpb24gc3RhdGUu
CgoNCgUECQIABRIElAICCAoNCgUECQIAARIElAIJHwoNCgUECQIAAxIElAIiIwo6CgIEChIG
mAIAoAIBGiwgUmVxdWVzdCBtZXNzYWdlIGZvciBRdWVyeVRyYW5zYWN0aW9uU3RhdGUuCgoL
CgMECgESBJgCCCQKoAEKBAQKAgASBJwCAj8akQEgUmVxdWlyZWQuIFRoZSBlbmRwb2ludCB0
byBzZXJ2ZSB0aGUgcmVxdWVzdC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9lbmRwb2ludHMve2VuZHBvaW50fWAKIFRoZSBsb2NhdGlvbiBp
cyBhIHJlZ2lvbi4KCg0KBQQKAgAFEgScAgIICg0KBQQKAgABEgScAgkRCg0KBQQKAgADEgSc
AhQVCg0KBQQKAgAIEgScAhY+ChAKCAQKAgAInAgAEgScAhc9CkEKBAQKAgESBJ8CAk0aMyBS
ZXF1aXJlZC4gVGhlIHRyYW5zYWN0aW9uIElEIHRvIGdldCB0aGUgc3RhdGUgb2YuCgoNCgUE
CgIBBRIEnwICCAoNCgUECgIBARIEnwIJHwoNCgUECgIBAxIEnwIiIwoNCgUECgIBCBIEnwIk
TAoQCggECgIBCJwIABIEnwIlSwo7CgIECxIGowIApwIBGi0gUmVzcG9uc2UgbWVzc2FnZSBm
b3IgUXVlcnlUcmFuc2FjdGlvblN0YXRlLgoKCwoDBAsBEgSjAgglCm4KBAQLAgASBKYCAjca
YCBPbmUgZW50cnkgcGVyIGVhY2gga25vd24gc3VibWlzc2lvbiBvZiB0aGUgdHJhbnNhY3Rp
b24gdG8gdGhlIHZhbGlkYXRvcgogaGFuZGxpbmcgdGhlIHJlcXVlc3QuCgoNCgUECwIABBIE
pgICCgoNCgUECwIABhIEpgILHQoNCgUECwIAARIEpgIeMgoNCgUECwIAAxIEpgI1NgouCgIE
DBIGqgIAtQIBGiAgUmVxdWVzdCBtZXNzYWdlIGZvciBRdWVyeURhdGEuCgoLCgMEDAESBKoC
CBgKoAEKBAQMAgASBK4CAj8akQEgUmVxdWlyZWQuIFRoZSBlbmRwb2ludCB0byBzZXJ2ZSB0
aGUgcmVxdWVzdC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9lbmRwb2ludHMve2VuZHBvaW50fWAKIFRoZSBsb2NhdGlvbiBpcyBhIHJlZ2lv
bi4KCg0KBQQMAgAFEgSuAgIICg0KBQQMAgABEgSuAgkRCg0KBQQMAgADEgSuAhQVCg0KBQQM
AgAIEgSuAhY+ChAKCAQMAgAInAgAEgSuAhc9CqQBCgQEDAIBEgazAgK0Ai8akwEgUmVxdWly
ZWQuIEEgcHJvdG9idWYgc2VyaWFsaXplZAogW1NpZ25lZFF1ZXJ5UmVxdWVzdF1bZ29vZ2xl
LmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5TaWduZWRRdWVyeVJlcXVlc3RdIHRvCiBxdWVy
eSB0aGUgVW5pdmVyc2FsIExlZGdlciBuZXR3b3JrLgoKDQoFBAwCAQUSBLMCAgcKDQoFBAwC
AQESBLMCCCcKDQoFBAwCAQMSBLMCKisKDQoFBAwCAQgSBLQCBi4KEAoIBAwCAQicCAASBLQC
By0KLwoCBA0SBrgCAMUCARohIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIFF1ZXJ5RGF0YS4KCgsK
AwQNARIEuAIIGQosCgQEDQgAEga6AgLAAgMaHCBUaGUgcXVlcnktc3BlY2lmaWMgcmVzdWx0
LgoKDQoFBA0IAAESBLoCCAwKSQoEBA0CABIEvAIEGBo7IFRoZSBhY2NvdW50IGluZm9ybWF0
aW9uLCBpZiB0aGUgcXVlcnkgd2FzIGZvciBhbiBhY2NvdW50LgoKDQoFBA0CAAYSBLwCBAsK
DQoFBA0CAAESBLwCDBMKDQoFBA0CAAMSBLwCFhcKTwoEBA0CARIEvwIEKxpBIFRoZSBzdGF0
ZSBvZiBhIHRyYW5zYWN0aW9uLCBpZiB0aGUgcXVlcnkgd2FzIGZvciBhIHRyYW5zYWN0aW9u
LgoKDQoFBA0CAQYSBL8CBBQKDQoFBA0CAQESBL8CFSYKDQoFBA0CAQMSBL8CKSoKbAoEBA0C
AhIExAICLRpeIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaGF2ZSBiZWVuIHJlZGFjdGVkIGZy
b20gdGhlIHJlc3BvbnNlIGR1ZSB0bwogcGVybWlzc2lvbiByZXN0cmljdGlvbnMuCgoNCgUE
DQICBBIExAICCgoNCgUEDQICBhIExAILGAoNCgUEDQICARIExAIZKAoNCgUEDQICAxIExAIr
LGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Universalledger::V1::Universalledger::Endpoint ===
    # Fields for Endpoint
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsRequest ===
    # Fields for ListEndpointsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsResponse ===
    # Fields for ListEndpointsResponse
    # Field: endpoints Type: 11 (.google.cloud.universalledger.v1.Endpoint)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::GetEndpointRequest ===
    # Fields for GetEndpointRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::QueryAccountRequest ===
    # Fields for QueryAccountRequest
    # Field: endpoint Type: 9 ()
    # Field: account_id Type: 9 ()
    # Field: round_id Type: 3 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::QueryAccountResponse ===
    # Fields for QueryAccountResponse
    # Field: account Type: 11 (.google.cloud.universalledger.v1.Account)

# === Message: Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest ===
    # Fields for SubmitTransactionRequest
    # Field: endpoint Type: 9 ()
    # Field: serialized_signed_transaction Type: 12 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse ===
    # Fields for SubmitTransactionResponse
    # Field: transaction_digest_hex Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionRequest ===
    # Fields for SubmitOperationalTransactionRequest
    # Field: endpoint Type: 9 ()
    # Field: serialized_signed_operational_transaction Type: 12 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionResponse ===
    # Fields for SubmitOperationalTransactionResponse
    # Field: transaction_digest_hex Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateRequest ===
    # Fields for QueryTransactionStateRequest
    # Field: endpoint Type: 9 ()
    # Field: transaction_digest_hex Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateResponse ===
    # Fields for QueryTransactionStateResponse
    # Field: transaction_attempts Type: 11 (.google.cloud.universalledger.v1.TransactionAttempt)

# === Message: Google::Cloud::Universalledger::V1::Universalledger::QueryDataRequest ===
    # Fields for QueryDataRequest
    # Field: endpoint Type: 9 ()
    # Field: serialized_signed_query_request Type: 12 ()

# === Message: Google::Cloud::Universalledger::V1::Universalledger::QueryDataResponse ===
    # Fields for QueryDataResponse
    # Field: account Type: 11 (.google.cloud.universalledger.v1.Account)
    # Field: transaction_state Type: 11 (.google.cloud.universalledger.v1.TransactionState)
    # Field: redacted_fields Type: 11 (.google.cloud.universalledger.v1.RedactedField)

# === Service Client: Google::Cloud::Universalledger::V1::Universalledger::UniversalLedgerClient ===
package Google::Cloud::Universalledger::V1::Universalledger::UniversalLedgerClient;

=pod

=head2 Service Client: Google::Cloud::Universalledger::V1::Universalledger::UniversalLedgerClient

Client stub representing the remote C<UniversalLedger> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<universalledger.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'universalledger.googleapis.com:443' );

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

sub submit_transaction {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'SubmitTransaction',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse',
    });
}

sub list_endpoints {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'ListEndpoints',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsResponse',
    });
}

sub get_endpoint {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::GetEndpointRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'GetEndpoint',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::Endpoint',
    });
}

sub submit_operational_transaction {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'SubmitOperationalTransaction',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionResponse',
    });
}

sub query_transaction_state {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'QueryTransactionState',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateResponse',
    });
}

sub query_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::QueryAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'QueryAccount',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::QueryAccountResponse',
    });
}

sub query_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Universalledger::V1::Universalledger::QueryDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'QueryData',
        request        => $req,
        response_class => 'Google::Cloud::Universalledger::V1::Universalledger::QueryDataResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Universalledger::V1::Universalledger - Compiled Protocol Buffers messages for google/cloud/universalledger/v1/universalledger.proto

=head1 SYNOPSIS

    use Google::Cloud::Universalledger::V1::Universalledger;

    my $msg = Google::Cloud::Universalledger::V1::Universalledger::Endpoint->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Universalledger::V1::Universalledger::Endpoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/universalledger/v1/universalledger.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Universalledger::V1::Universalledger::Endpoint

Represents a Universal Ledger endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the endpoint.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsRequest

Request message for ListEndpoints.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of endpoints.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of endpoints to return. The service may return
fewer than this value. If unspecified, at most 50 endpoints will be
returned. The maximum value is 1000; values above 1000 will be coerced to
1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListEndpoints` call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsResponse

Response message for ListEndpoints.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoints() >> / C<< $msg->endpoints($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Universalledger::Endpoint>)

The endpoints for the given project and location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::GetEndpointRequest

Request message for GetEndpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the endpoint to retrieve.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::QueryAccountRequest

Request message for QueryAccount.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

Required. The endpoint to serve the request.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`
The location is a region.

=item * C<< $msg->account_id() >> / C<< $msg->account_id($value) >>

Type: C<String>

Required. The account ID to get information about. The value is limited to
60 characters.

=item * C<< $msg->round_id() >> / C<< $msg->round_id($value) >>

Type: C<Int64>

Optional. The ID of the execution round (similar to block "height") at
which to request data. The returned account information will be accurate
for the world state at this execution round. If unspecified, uses the
latest finalized round as known by the serving validator. The state at a
given round ID is always consistent and canonical.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::QueryAccountResponse

Response message for QueryAccount.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account() >> / C<< $msg->account($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::Account>)

The account information, along with the height at which it was obtained.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest

Request message for SubmitTransaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

Required. The endpoint to submit the transaction to.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`
The location is a region.

=item * C<< $msg->serialized_signed_transaction() >> / C<< $msg->serialized_signed_transaction($value) >>

Type: C<Bytes>

Required. A protobuf serialized
[SignedTransaction][google.cloud.universalledger.v1.SignedTransaction] to
submit to the ledger. Using a serialized format ensures that all validators
compute the same transaction ID as the SHA-256 digest of the serialized
bytes.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse

Response message for SubmitTransaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transaction_digest_hex() >> / C<< $msg->transaction_digest_hex($value) >>

Type: C<String>

Identifier that uniquely represents the submitted transaction.
It is the hexadecimal representation of the SHA-256 digest of the
`serialized_signed_transaction`.
This transaction ID is provided so that a client can track the transaction
without needing to implement the hashing logic itself.
The identifier can be directly used in subsequent API calls, for example to
query the transaction state.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionRequest

Request message for SubmitOperationalTransaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

Required. The endpoint to serve the request.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`
The location is a region.

=item * C<< $msg->serialized_signed_operational_transaction() >> / C<< $msg->serialized_signed_operational_transaction($value) >>

Type: C<Bytes>

Required. A protobuf serialized
[SignedTransaction][google.cloud.universalledger.v1.SignedTransaction] to
submit to the ledger. The enclosed client transaction must be an
operational transaction, and the sender must be the platform operator.
Using a serialized format ensures that all validators compute the same
transaction ID as the SHA-256 digest of the serialized bytes.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionResponse

Response message for SubmitOperationalTransaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transaction_digest_hex() >> / C<< $msg->transaction_digest_hex($value) >>

Type: C<String>

Identifier that uniquely represents the submitted operational transaction.
It is the hexadecimal representation of the SHA-256 digest of the
`serialized_signed_operational_transaction`.
This transaction ID is provided so that a client can track the transaction
without needing to implement the hashing logic itself.
The identifier can be directly used in subsequent API calls, for example to
query the transaction state.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateRequest

Request message for QueryTransactionState.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

Required. The endpoint to serve the request.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`
The location is a region.

=item * C<< $msg->transaction_digest_hex() >> / C<< $msg->transaction_digest_hex($value) >>

Type: C<String>

Required. The transaction ID to get the state of.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateResponse

Response message for QueryTransactionState.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transaction_attempts() >> / C<< $msg->transaction_attempts($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Types::TransactionAttempt>)

One entry per each known submission of the transaction to the validator
handling the request.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::QueryDataRequest

Request message for QueryData.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

Required. The endpoint to serve the request.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`
The location is a region.

=item * C<< $msg->serialized_signed_query_request() >> / C<< $msg->serialized_signed_query_request($value) >>

Type: C<Bytes>

Required. A protobuf serialized
[SignedQueryRequest][google.cloud.universalledger.v1.SignedQueryRequest] to
query the Universal Ledger network.

=back

=head2 Google::Cloud::Universalledger::V1::Universalledger::QueryDataResponse

Response message for QueryData.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account() >> / C<< $msg->account($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::Account>)

The account information, if the query was for an account.

=item * C<< $msg->transaction_state() >> / C<< $msg->transaction_state($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Types::TransactionState>)

The state of a transaction, if the query was for a transaction.

=item * C<< $msg->redacted_fields() >> / C<< $msg->redacted_fields($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Query::RedactedField>)

Indicates which fields have been redacted from the response due to
permission restrictions.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Universalledger::V1::Universalledger::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
