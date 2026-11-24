package Google::Cloud::Financialservices::V1::Service;

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
    eval { require Google::Cloud::Financialservices::V1::BacktestResult };
    eval { require Google::Cloud::Financialservices::V1::Dataset };
    eval { require Google::Cloud::Financialservices::V1::EngineConfig };
    eval { require Google::Cloud::Financialservices::V1::EngineVersion };
    eval { require Google::Cloud::Financialservices::V1::Instance };
    eval { require Google::Cloud::Financialservices::V1::Model };
    eval { require Google::Cloud::Financialservices::V1::PredictionResult };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvc2VydmljZS5wcm90bxIhZ29v
Z2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxo3Z29vZ2xlL2Nsb3VkL2ZpbmFuY2lhbHNlcnZpY2VzL3YxL2JhY2t0ZXN0
X3Jlc3VsdC5wcm90bxovZ29vZ2xlL2Nsb3VkL2ZpbmFuY2lhbHNlcnZpY2VzL3YxL2RhdGFz
ZXQucHJvdG8aNWdvb2dsZS9jbG91ZC9maW5hbmNpYWxzZXJ2aWNlcy92MS9lbmdpbmVfY29u
ZmlnLnByb3RvGjZnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvZW5naW5lX3Zl
cnNpb24ucHJvdG8aMGdvb2dsZS9jbG91ZC9maW5hbmNpYWxzZXJ2aWNlcy92MS9pbnN0YW5j
ZS5wcm90bxotZ29vZ2xlL2Nsb3VkL2ZpbmFuY2lhbHNlcnZpY2VzL3YxL21vZGVsLnByb3Rv
Gjlnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvcHJlZGljdGlvbl9yZXN1bHQu
cHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJv
dG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1QIK
EU9wZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEoCUID
4EEDUgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEioKDnN0YXR1c19tZXNzYWdl
GAUgASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgG
IAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YByABKAlC
A+BBA1IKYXBpVmVyc2lvbjKwSgoDQU1MEsIBCg1MaXN0SW5zdGFuY2VzEjcuZ29vZ2xlLmNs
b3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpc3RJbnN0YW5jZXNSZXF1ZXN0GjguZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpc3RJbnN0YW5jZXNSZXNwb25zZSI+gtPk
kwIvEi0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9pbnN0YW5jZXPaQQZw
YXJlbnQSrwEKC0dldEluc3RhbmNlEjUuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2Vz
LnYxLkdldEluc3RhbmNlUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNl
cy52MS5JbnN0YW5jZSI8gtPkkwIvEi0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9pbnN0YW5jZXMvKn3aQQRuYW1lEugBCg5DcmVhdGVJbnN0YW5jZRI4Lmdvb2dsZS5jbG91
ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5DcmVhdGVJbnN0YW5jZVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn2C0+STAjkiLS92MS97cGFyZW50PXByb2plY3RzLyov
bG9jYXRpb25zLyp9L2luc3RhbmNlczoIaW5zdGFuY2XaQRtwYXJlbnQsaW5zdGFuY2UsaW5z
dGFuY2VfaWTKQR0KCEluc3RhbmNlEhFPcGVyYXRpb25NZXRhZGF0YRLqAQoOVXBkYXRlSW5z
dGFuY2USOC5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuVXBkYXRlSW5zdGFu
Y2VSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ/gtPkkwJCMjYvdjEv
e2luc3RhbmNlLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn06CGlu
c3RhbmNl2kEUaW5zdGFuY2UsdXBkYXRlX21hc2vKQR0KCEluc3RhbmNlEhFPcGVyYXRpb25N
ZXRhZGF0YRLUAQoORGVsZXRlSW5zdGFuY2USOC5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2Vy
dmljZXMudjEuRGVsZXRlSW5zdGFuY2VSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiJpgtPkkwIvKi0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0
YW5jZXMvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1l
dGFkYXRhEq8CChdJbXBvcnRSZWdpc3RlcmVkUGFydGllcxJBLmdvb2dsZS5jbG91ZC5maW5h
bmNpYWxzZXJ2aWNlcy52MS5JbXBvcnRSZWdpc3RlcmVkUGFydGllc1JlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrEBgtPkkwJKIkUvdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn06aW1wb3J0UmVnaXN0ZXJlZFBhcnRpZXM6ASra
QSduYW1lLG1vZGUsbGluZV9vZl9idXNpbmVzcyxwYXJ0eV90YWJsZXPKQTQKH0ltcG9ydFJl
Z2lzdGVyZWRQYXJ0aWVzUmVzcG9uc2USEU9wZXJhdGlvbk1ldGFkYXRhEqUCChdFeHBvcnRS
ZWdpc3RlcmVkUGFydGllcxJBLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5F
eHBvcnRSZWdpc3RlcmVkUGFydGllc1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uIqcBgtPkkwJKIkUvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0
YW5jZXMvKn06ZXhwb3J0UmVnaXN0ZXJlZFBhcnRpZXM6ASraQR1uYW1lLGRhdGFzZXQsbGlu
ZV9vZl9idXNpbmVzc8pBNAofRXhwb3J0UmVnaXN0ZXJlZFBhcnRpZXNSZXNwb25zZRIRT3Bl
cmF0aW9uTWV0YWRhdGESygEKDExpc3REYXRhc2V0cxI2Lmdvb2dsZS5jbG91ZC5maW5hbmNp
YWxzZXJ2aWNlcy52MS5MaXN0RGF0YXNldHNSZXF1ZXN0GjcuZ29vZ2xlLmNsb3VkLmZpbmFu
Y2lhbHNlcnZpY2VzLnYxLkxpc3REYXRhc2V0c1Jlc3BvbnNlIkmC0+STAjoSOC92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyp9L2RhdGFzZXRz2kEGcGFy
ZW50ErcBCgpHZXREYXRhc2V0EjQuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYx
LkdldERhdGFzZXRSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYx
LkRhdGFzZXQiR4LT5JMCOhI4L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovaW5z
dGFuY2VzLyovZGF0YXNldHMvKn3aQQRuYW1lEu4BCg1DcmVhdGVEYXRhc2V0EjcuZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkNyZWF0ZURhdGFzZXRSZXF1ZXN0Gh0uZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKEAYLT5JMCQyI4L3YxL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0vZGF0YXNldHM6B2RhdGFzZXTaQRlwYXJl
bnQsZGF0YXNldCxkYXRhc2V0X2lkykEcCgdEYXRhc2V0EhFPcGVyYXRpb25NZXRhZGF0YRLw
AQoNVXBkYXRlRGF0YXNldBI3Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5V
cGRhdGVEYXRhc2V0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ihgGC
0+STAksyQC92MS97ZGF0YXNldC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFu
Y2VzLyovZGF0YXNldHMvKn06B2RhdGFzZXTaQRNkYXRhc2V0LHVwZGF0ZV9tYXNrykEcCgdE
YXRhc2V0EhFPcGVyYXRpb25NZXRhZGF0YRLdAQoNRGVsZXRlRGF0YXNldBI3Lmdvb2dsZS5j
bG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5EZWxldGVEYXRhc2V0UmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24idILT5JMCOio4L3YxL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovaW5zdGFuY2VzLyovZGF0YXNldHMvKn3aQQRuYW1lykEqChVnb29nbGUu
cHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEsIBCgpMaXN0TW9kZWxzEjQuZ29v
Z2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpc3RNb2RlbHNSZXF1ZXN0GjUuZ29v
Z2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpc3RNb2RlbHNSZXNwb25zZSJHgtPk
kwI4EjYvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfS9t
b2RlbHPaQQZwYXJlbnQSrwEKCEdldE1vZGVsEjIuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNl
cnZpY2VzLnYxLkdldE1vZGVsUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2
aWNlcy52MS5Nb2RlbCJFgtPkkwI4EjYvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9pbnN0YW5jZXMvKi9tb2RlbHMvKn3aQQRuYW1lEt8BCgtDcmVhdGVNb2RlbBI1Lmdvb2ds
ZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5DcmVhdGVNb2RlbFJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uInqC0+STAj8iNi92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyp9L21vZGVsczoFbW9kZWzaQRVwYXJlbnQsbW9k
ZWwsbW9kZWxfaWTKQRoKBU1vZGVsEhFPcGVyYXRpb25NZXRhZGF0YRLhAQoLVXBkYXRlTW9k
ZWwSNS5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuVXBkYXRlTW9kZWxSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ8gtPkkwJFMjwvdjEve21vZGVs
Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9tb2RlbHMvKn06BW1v
ZGVs2kERbW9kZWwsdXBkYXRlX21hc2vKQRoKBU1vZGVsEhFPcGVyYXRpb25NZXRhZGF0YRKi
AgoTRXhwb3J0TW9kZWxNZXRhZGF0YRI9Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNl
cy52MS5FeHBvcnRNb2RlbE1ldGFkYXRhUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb24irAGC0+STAksiRi92MS97bW9kZWw9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9p
bnN0YW5jZXMvKi9tb2RlbHMvKn06ZXhwb3J0TWV0YWRhdGE6ASraQSVtb2RlbCxzdHJ1Y3R1
cmVkX21ldGFkYXRhX2Rlc3RpbmF0aW9uykEwChtFeHBvcnRNb2RlbE1ldGFkYXRhUmVzcG9u
c2USEU9wZXJhdGlvbk1ldGFkYXRhEtcBCgtEZWxldGVNb2RlbBI1Lmdvb2dsZS5jbG91ZC5m
aW5hbmNpYWxzZXJ2aWNlcy52MS5EZWxldGVNb2RlbFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uInKC0+STAjgqNi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2luc3RhbmNlcy8qL21vZGVscy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5F
bXB0eRIRT3BlcmF0aW9uTWV0YWRhdGES3gEKEUxpc3RFbmdpbmVDb25maWdzEjsuZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpc3RFbmdpbmVDb25maWdzUmVxdWVzdBo8
Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5MaXN0RW5naW5lQ29uZmlnc1Jl
c3BvbnNlIk6C0+STAj8SPS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovaW5z
dGFuY2VzLyp9L2VuZ2luZUNvbmZpZ3PaQQZwYXJlbnQSywEKD0dldEVuZ2luZUNvbmZpZxI5
Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5HZXRFbmdpbmVDb25maWdSZXF1
ZXN0Gi8uZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkVuZ2luZUNvbmZpZyJM
gtPkkwI/Ej0vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9l
bmdpbmVDb25maWdzLyp92kEEbmFtZRKUAgoSQ3JlYXRlRW5naW5lQ29uZmlnEjwuZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkNyZWF0ZUVuZ2luZUNvbmZpZ1JlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqABgtPkkwJOIj0vdjEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfS9lbmdpbmVDb25maWdzOg1lbmdp
bmVfY29uZmln2kElcGFyZW50LGVuZ2luZV9jb25maWcsZW5naW5lX2NvbmZpZ19pZMpBIQoM
RW5naW5lQ29uZmlnEhFPcGVyYXRpb25NZXRhZGF0YRKWAgoSVXBkYXRlRW5naW5lQ29uZmln
EjwuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLlVwZGF0ZUVuZ2luZUNvbmZp
Z1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqIBgtPkkwJcMksvdjEv
e2VuZ2luZV9jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8q
L2VuZ2luZUNvbmZpZ3MvKn06DWVuZ2luZV9jb25maWfaQRllbmdpbmVfY29uZmlnLHVwZGF0
ZV9tYXNrykEhCgxFbmdpbmVDb25maWcSEU9wZXJhdGlvbk1ldGFkYXRhEs4CChpFeHBvcnRF
bmdpbmVDb25maWdNZXRhZGF0YRJELmdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52
MS5FeHBvcnRFbmdpbmVDb25maWdNZXRhZGF0YVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIsoBgtPkkwJaIlUvdjEve2VuZ2luZV9jb25maWc9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9lbmdpbmVDb25maWdzLyp9OmV4cG9ydE1ldGFkYXRh
OgEq2kEtZW5naW5lX2NvbmZpZyxzdHJ1Y3R1cmVkX21ldGFkYXRhX2Rlc3RpbmF0aW9uykE3
CiJFeHBvcnRFbmdpbmVDb25maWdNZXRhZGF0YVJlc3BvbnNlEhFPcGVyYXRpb25NZXRhZGF0
YRLsAQoSRGVsZXRlRW5naW5lQ29uZmlnEjwuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZp
Y2VzLnYxLkRlbGV0ZUVuZ2luZUNvbmZpZ1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uInmC0+STAj8qPS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lu
c3RhbmNlcy8qL2VuZ2luZUNvbmZpZ3MvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9idWYu
RW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEs8BChBHZXRFbmdpbmVWZXJzaW9uEjouZ29vZ2xl
LmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkdldEVuZ2luZVZlcnNpb25SZXF1ZXN0GjAu
Z29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkVuZ2luZVZlcnNpb24iTYLT5JMC
QBI+L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyovZW5naW5l
VmVyc2lvbnMvKn3aQQRuYW1lEuIBChJMaXN0RW5naW5lVmVyc2lvbnMSPC5nb29nbGUuY2xv
dWQuZmluYW5jaWFsc2VydmljZXMudjEuTGlzdEVuZ2luZVZlcnNpb25zUmVxdWVzdBo9Lmdv
b2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5MaXN0RW5naW5lVmVyc2lvbnNSZXNw
b25zZSJPgtPkkwJAEj4vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3Rh
bmNlcy8qfS9lbmdpbmVWZXJzaW9uc9pBBnBhcmVudBLuAQoVTGlzdFByZWRpY3Rpb25SZXN1
bHRzEj8uZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpc3RQcmVkaWN0aW9u
UmVzdWx0c1JlcXVlc3QaQC5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuTGlz
dFByZWRpY3Rpb25SZXN1bHRzUmVzcG9uc2UiUoLT5JMCQxJBL3YxL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0vcHJlZGljdGlvblJlc3VsdHPaQQZwYXJl
bnQS2wEKE0dldFByZWRpY3Rpb25SZXN1bHQSPS5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2Vy
dmljZXMudjEuR2V0UHJlZGljdGlvblJlc3VsdFJlcXVlc3QaMy5nb29nbGUuY2xvdWQuZmlu
YW5jaWFsc2VydmljZXMudjEuUHJlZGljdGlvblJlc3VsdCJQgtPkkwJDEkEvdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9wcmVkaWN0aW9uUmVzdWx0cy8q
fdpBBG5hbWUSsAIKFkNyZWF0ZVByZWRpY3Rpb25SZXN1bHQSQC5nb29nbGUuY2xvdWQuZmlu
YW5jaWFsc2VydmljZXMudjEuQ3JlYXRlUHJlZGljdGlvblJlc3VsdFJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrQBgtPkkwJWIkEvdjEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfS9wcmVkaWN0aW9uUmVzdWx0czoRcHJlZGlj
dGlvbl9yZXN1bHTaQS1wYXJlbnQscHJlZGljdGlvbl9yZXN1bHQscHJlZGljdGlvbl9yZXN1
bHRfaWTKQSUKEFByZWRpY3Rpb25SZXN1bHQSEU9wZXJhdGlvbk1ldGFkYXRhErICChZVcGRh
dGVQcmVkaWN0aW9uUmVzdWx0EkAuZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYx
LlVwZGF0ZVByZWRpY3Rpb25SZXN1bHRSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiK2AYLT5JMCaDJTL3YxL3twcmVkaWN0aW9uX3Jlc3VsdC5uYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyovcHJlZGljdGlvblJlc3VsdHMvKn06EXByZWRp
Y3Rpb25fcmVzdWx02kEdcHJlZGljdGlvbl9yZXN1bHQsdXBkYXRlX21hc2vKQSUKEFByZWRp
Y3Rpb25SZXN1bHQSEU9wZXJhdGlvbk1ldGFkYXRhEuYCCh5FeHBvcnRQcmVkaWN0aW9uUmVz
dWx0TWV0YWRhdGESSC5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuRXhwb3J0
UHJlZGljdGlvblJlc3VsdE1ldGFkYXRhUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb24i2gGC0+STAmIiXS92MS97cHJlZGljdGlvbl9yZXN1bHQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9wcmVkaWN0aW9uUmVzdWx0cy8qfTpleHBvcnRNZXRh
ZGF0YToBKtpBMXByZWRpY3Rpb25fcmVzdWx0LHN0cnVjdHVyZWRfbWV0YWRhdGFfZGVzdGlu
YXRpb27KQTsKJkV4cG9ydFByZWRpY3Rpb25SZXN1bHRNZXRhZGF0YVJlc3BvbnNlEhFPcGVy
YXRpb25NZXRhZGF0YRL4AQoWRGVsZXRlUHJlZGljdGlvblJlc3VsdBJALmdvb2dsZS5jbG91
ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5EZWxldGVQcmVkaWN0aW9uUmVzdWx0UmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ifYLT5JMCQypBL3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyovcHJlZGljdGlvblJlc3VsdHMvKn3aQQRu
YW1lykEqChVnb29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEuYBChNM
aXN0QmFja3Rlc3RSZXN1bHRzEj0uZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYx
Lkxpc3RCYWNrdGVzdFJlc3VsdHNSZXF1ZXN0Gj4uZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNl
cnZpY2VzLnYxLkxpc3RCYWNrdGVzdFJlc3VsdHNSZXNwb25zZSJQgtPkkwJBEj8vdjEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfS9iYWNrdGVzdFJlc3Vs
dHPaQQZwYXJlbnQS0wEKEUdldEJhY2t0ZXN0UmVzdWx0EjsuZ29vZ2xlLmNsb3VkLmZpbmFu
Y2lhbHNlcnZpY2VzLnYxLkdldEJhY2t0ZXN0UmVzdWx0UmVxdWVzdBoxLmdvb2dsZS5jbG91
ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5CYWNrdGVzdFJlc3VsdCJOgtPkkwJBEj8vdjEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9iYWNrdGVzdFJlc3VsdHMv
Kn3aQQRuYW1lEqICChRDcmVhdGVCYWNrdGVzdFJlc3VsdBI+Lmdvb2dsZS5jbG91ZC5maW5h
bmNpYWxzZXJ2aWNlcy52MS5DcmVhdGVCYWNrdGVzdFJlc3VsdFJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqoBgtPkkwJSIj8vdjEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfS9iYWNrdGVzdFJlc3VsdHM6D2JhY2t0ZXN0X3Jl
c3VsdNpBKXBhcmVudCxiYWNrdGVzdF9yZXN1bHQsYmFja3Rlc3RfcmVzdWx0X2lkykEjCg5C
YWNrdGVzdFJlc3VsdBIRT3BlcmF0aW9uTWV0YWRhdGESpAIKFFVwZGF0ZUJhY2t0ZXN0UmVz
dWx0Ej4uZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLlVwZGF0ZUJhY2t0ZXN0
UmVzdWx0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24irAGC0+STAmIy
Ty92MS97YmFja3Rlc3RfcmVzdWx0Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0
YW5jZXMvKi9iYWNrdGVzdFJlc3VsdHMvKn06D2JhY2t0ZXN0X3Jlc3VsdNpBG2JhY2t0ZXN0
X3Jlc3VsdCx1cGRhdGVfbWFza8pBIwoOQmFja3Rlc3RSZXN1bHQSEU9wZXJhdGlvbk1ldGFk
YXRhEtoCChxFeHBvcnRCYWNrdGVzdFJlc3VsdE1ldGFkYXRhEkYuZ29vZ2xlLmNsb3VkLmZp
bmFuY2lhbHNlcnZpY2VzLnYxLkV4cG9ydEJhY2t0ZXN0UmVzdWx0TWV0YWRhdGFSZXF1ZXN0
Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLSAYLT5JMCXiJZL3YxL3tiYWNrdGVz
dF9yZXN1bHQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9iYWNrdGVzdFJl
c3VsdHMvKn06ZXhwb3J0TWV0YWRhdGE6ASraQS9iYWNrdGVzdF9yZXN1bHQsc3RydWN0dXJl
ZF9tZXRhZGF0YV9kZXN0aW5hdGlvbspBOQokRXhwb3J0QmFja3Rlc3RSZXN1bHRNZXRhZGF0
YVJlc3BvbnNlEhFPcGVyYXRpb25NZXRhZGF0YRLyAQoURGVsZXRlQmFja3Rlc3RSZXN1bHQS
Pi5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuRGVsZXRlQmFja3Rlc3RSZXN1
bHRSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ7gtPkkwJBKj8vdjEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9iYWNrdGVzdFJlc3Vs
dHMvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFk
YXRhGlTKQSBmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C+wEKJWNvbS5nb29nbGUuY2xv
dWQuZmluYW5jaWFsc2VydmljZXMudjFCDFNlcnZpY2VQcm90b1ABWlNjbG91ZC5nb29nbGUu
Y29tL2dvL2ZpbmFuY2lhbHNlcnZpY2VzL2FwaXYxL2ZpbmFuY2lhbHNlcnZpY2VzcGI7Zmlu
YW5jaWFsc2VydmljZXNwYqoCIUdvb2dsZS5DbG91ZC5GaW5hbmNpYWxTZXJ2aWNlcy5WMcoC
IUdvb2dsZVxDbG91ZFxGaW5hbmNpYWxTZXJ2aWNlc1xWMeoCJEdvb2dsZTo6Q2xvdWQ6OkZp
bmFuY2lhbFNlcnZpY2VzOjpWMUrdVAoHEgUOAKUEAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQA
KQoJCgIDAxIDFQBBCgkKAgMEEgMWADkKCQoCAwUSAxcAPwoJCgIDBhIDGABACgkKAgMHEgMZ
ADoKCQoCAwgSAxoANwoJCgIDCRIDGwBDCgkKAgMKEgMcAC0KCQoCAwsSAx0AJQoJCgIDDBID
HgApCggKAQgSAyAAPgoJCgIIJRIDIAA+CggKAQgSAyEAagoJCgIICxIDIQBqCggKAQgSAyIA
IgoJCgIIChIDIgAiCggKAQgSAyMALQoJCgIICBIDIwAtCggKAQgSAyQAPgoJCgIIARIDJAA+
CggKAQgSAyUAPgoJCgIIKRIDJQA+CggKAQgSAyYAPQoJCgIILRIDJgA9CmcKAgYAEgUqAIQE
ARpaIFRoZSBBTUwgKEFudGkgTW9uZXkgTGF1bmRlcmluZykgc2VydmljZSBhbGxvd3MgdXNl
cnMgdG8gcGVyZm9ybSBSRVNUCiBvcGVyYXRpb25zIG9uIGFtbC4KCgoKAwYAARIDKggLCgoK
AwYAAxIDKwJICgwKBQYAA5kIEgMrAkgKCwoDBgADEgQsAi03Cg0KBQYAA5oIEgQsAi03CiAK
BAYAAgASBDACNQMaEiBMaXN0cyBpbnN0YW5jZXMuCgoMCgUGAAIAARIDMAYTCgwKBQYAAgAC
EgMwFCgKDAoFBgACAAMSAzAzSAoNCgUGAAIABBIEMQQzBgoRCgkGAAIABLDKvCISBDEEMwYK
DAoFBgACAAQSAzQENAoPCggGAAIABJsIABIDNAQ0CiEKBAYAAgESBDgCPQMaEyBHZXRzIGFu
IGluc3RhbmNlLgoKDAoFBgACAQESAzgGEQoMCgUGAAIBAhIDOBIkCgwKBQYAAgEDEgM4LzcK
DQoFBgACAQQSBDkEOwYKEQoJBgACAQSwyrwiEgQ5BDsGCgwKBQYAAgEEEgM8BDIKDwoIBgAC
AQSbCAASAzwEMgokCgQGAAICEgRAAksDGhYgQ3JlYXRlcyBhbiBpbnN0YW5jZS4KCgwKBQYA
AgIBEgNABhQKDAoFBgACAgISA0AVKgoMCgUGAAICAxIDQQ8rCg0KBQYAAgIEEgRCBEUGChEK
CQYAAgIEsMq8IhIEQgRFBgoMCgUGAAICBBIDRgRJCg8KCAYAAgIEmwgAEgNGBEkKDQoFBgAC
AgQSBEcESgYKDwoHBgACAgSZCBIERwRKBgo8CgQGAAIDEgROAlkDGi4gVXBkYXRlcyB0aGUg
cGFyYW1ldGVycyBvZiBhIHNpbmdsZSBJbnN0YW5jZS4KCgwKBQYAAgMBEgNOBhQKDAoFBgAC
AwISA04VKgoMCgUGAAIDAxIDTw8rCg0KBQYAAgMEEgRQBFMGChEKCQYAAgMEsMq8IhIEUART
BgoMCgUGAAIDBBIDVARCCg8KCAYAAgMEmwgAEgNUBEIKDQoFBgACAwQSBFUEWAYKDwoHBgAC
AwSZCBIEVQRYBgokCgQGAAIEEgRcAmYDGhYgRGVsZXRlcyBhbiBpbnN0YW5jZS4KCgwKBQYA
AgQBEgNcBhQKDAoFBgACBAISA1wVKgoMCgUGAAIEAxIDXQ8rCg0KBQYAAgQEEgReBGAGChEK
CQYAAgQEsMq8IhIEXgRgBgoMCgUGAAIEBBIDYQQyCg8KCAYAAgQEmwgAEgNhBDIKDQoFBgAC
BAQSBGIEZQYKDwoHBgACBASZCBIEYgRlBgqdAgoEBgACBRIEbAJ4AxqOAiBJbXBvcnRzIHRo
ZSBsaXN0IG9mIHJlZ2lzdGVyZWQgcGFydGllcy4gU2VlCiBbQ3JlYXRlIGFuZCBtYW5hZ2UK
IGluc3RhbmNlc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2ZpbmFuY2lhbC1zZXJ2aWNl
cy9hbnRpLW1vbmV5LWxhdW5kZXJpbmcvZG9jcy9jcmVhdGUtYW5kLW1hbmFnZS1pbnN0YW5j
ZXMjaW1wb3J0LXJlZ2lzdGVyZWQtcGFydGllcykKIGZvciBpbmZvcm1hdGlvbiBvbiB0aGUg
aW5wdXQgc2NoZW1hIGFuZCByZXNwb25zZSBmb3IgdGhpcyBtZXRob2QuCgoMCgUGAAIFARID
bAYdCgwKBQYAAgUCEgNsHjwKDAoFBgACBQMSA20PKwoNCgUGAAIFBBIEbgRxBgoRCgkGAAIF
BLDKvCISBG4EcQYKDQoFBgACBQQSBHIEczIKEAoIBgACBQSbCAASBHIEczIKDQoFBgACBQQS
BHQEdwYKDwoHBgACBQSZCBIEdAR3BgqSAgoEBgACBhIFfgKJAQMaggIgRXhwb3J0cyB0aGUg
bGlzdCBvZiByZWdpc3RlcmVkIHBhcnRpZXMuIFNlZQogW0NyZWF0ZSBhbmQgbWFuYWdlCiBp
bnN0YW5jZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9maW5hbmNpYWwtc2VydmljZXMv
YW50aS1tb25leS1sYXVuZGVyaW5nL2RvY3MvY3JlYXRlLWFuZC1tYW5hZ2UtaW5zdGFuY2Vz
I2V4cG9ydC1yZWdpc3RlcmVkLXBhcnRpZXMpCiBmb3IgaW5mb3JtYXRpb24gb24gdGhlIG91
dHB1dCBzY2hlbWEgZm9yIHRoaXMgbWV0aG9kLgoKDAoFBgACBgESA34GHQoMCgUGAAIGAhID
fh48CgwKBQYAAgYDEgN/DysKDwoFBgACBgQSBoABBIMBBgoTCgkGAAIGBLDKvCISBoABBIMB
BgoNCgUGAAIGBBIEhAEESwoQCggGAAIGBJsIABIEhAEESwoPCgUGAAIGBBIGhQEEiAEGChEK
BwYAAgYEmQgSBoUBBIgBBgohCgQGAAIHEgaMAQKRAQMaESBMaXN0cyBkYXRhc2V0cy4KCg0K
BQYAAgcBEgSMAQYSCg0KBQYAAgcCEgSMARMmCg0KBQYAAgcDEgSMATFFCg8KBQYAAgcEEgaN
AQSPAQYKEwoJBgACBwSwyrwiEgaNAQSPAQYKDQoFBgACBwQSBJABBDQKEAoIBgACBwSbCAAS
BJABBDQKIQoEBgACCBIGlAECmQEDGhEgR2V0cyBhIGRhdGFzZXQuCgoNCgUGAAIIARIElAEG
EAoNCgUGAAIIAhIElAERIgoNCgUGAAIIAxIElAEtNAoPCgUGAAIIBBIGlQEElwEGChMKCQYA
AggEsMq8IhIGlQEElwEGCg0KBQYAAggEEgSYAQQyChAKCAYAAggEmwgAEgSYAQQyCiQKBAYA
AgkSBpwBAqcBAxoUIENyZWF0ZXMgYSBkYXRhc2V0LgoKDQoFBgACCQESBJwBBhMKDQoFBgAC
CQISBJwBFCgKDQoFBgACCQMSBJ0BDysKDwoFBgACCQQSBp4BBKEBBgoTCgkGAAIJBLDKvCIS
Bp4BBKEBBgoNCgUGAAIJBBIEogEERwoQCggGAAIJBJsIABIEogEERwoPCgUGAAIJBBIGowEE
pgEGChEKBwYAAgkEmQgSBqMBBKYBBgo9CgQGAAIKEgaqAQK1AQMaLSBVcGRhdGVzIHRoZSBw
YXJhbWV0ZXJzIG9mIGEgc2luZ2xlIERhdGFzZXQuCgoNCgUGAAIKARIEqgEGEwoNCgUGAAIK
AhIEqgEUKAoNCgUGAAIKAxIEqwEPKwoPCgUGAAIKBBIGrAEErwEGChMKCQYAAgoEsMq8IhIG
rAEErwEGCg0KBQYAAgoEEgSwAQRBChAKCAYAAgoEmwgAEgSwAQRBCg8KBQYAAgoEEgaxAQS0
AQYKEQoHBgACCgSZCBIGsQEEtAEGCiQKBAYAAgsSBrgBAsIBAxoUIERlbGV0ZXMgYSBkYXRh
c2V0LgoKDQoFBgACCwESBLgBBhMKDQoFBgACCwISBLgBFCgKDQoFBgACCwMSBLkBDysKDwoF
BgACCwQSBroBBLwBBgoTCgkGAAILBLDKvCISBroBBLwBBgoNCgUGAAILBBIEvQEEMgoQCggG
AAILBJsIABIEvQEEMgoPCgUGAAILBBIGvgEEwQEGChEKBwYAAgsEmQgSBr4BBMEBBgofCgQG
AAIMEgbFAQLKAQMaDyBMaXN0cyBtb2RlbHMuCgoNCgUGAAIMARIExQEGEAoNCgUGAAIMAhIE
xQERIgoNCgUGAAIMAxIExQEtPwoPCgUGAAIMBBIGxgEEyAEGChMKCQYAAgwEsMq8IhIGxgEE
yAEGCg0KBQYAAgwEEgTJAQQ0ChAKCAYAAgwEmwgAEgTJAQQ0Ch8KBAYAAg0SBs0BAtIBAxoP
IEdldHMgYSBtb2RlbC4KCg0KBQYAAg0BEgTNAQYOCg0KBQYAAg0CEgTNAQ8eCg0KBQYAAg0D
EgTNASkuCg8KBQYAAg0EEgbOAQTQAQYKEwoJBgACDQSwyrwiEgbOAQTQAQYKDQoFBgACDQQS
BNEBBDIKEAoIBgACDQSbCAASBNEBBDIKIgoEBgACDhIG1QEC3wEDGhIgQ3JlYXRlcyBhIG1v
ZGVsLgoKDQoFBgACDgESBNUBBhEKDQoFBgACDgISBNUBEiQKDQoFBgACDgMSBNUBL0sKDwoF
BgACDgQSBtYBBNkBBgoTCgkGAAIOBLDKvCISBtYBBNkBBgoNCgUGAAIOBBIE2gEEQwoQCggG
AAIOBJsIABIE2gEEQwoPCgUGAAIOBBIG2wEE3gEGChEKBwYAAg4EmQgSBtsBBN4BBgo7CgQG
AAIPEgbiAQLsAQMaKyBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIE1vZGVs
LgoKDQoFBgACDwESBOIBBhEKDQoFBgACDwISBOIBEiQKDQoFBgACDwMSBOIBL0sKDwoFBgAC
DwQSBuMBBOYBBgoTCgkGAAIPBLDKvCISBuMBBOYBBgoNCgUGAAIPBBIE5wEEPwoQCggGAAIP
BJsIABIE5wEEPwoPCgUGAAIPBBIG6AEE6wEGChEKBwYAAg8EmQgSBugBBOsBBgqEAgoEBgAC
EBIG8gEC/gEDGvMBIEV4cG9ydCBnb3Zlcm5hbmNlIGluZm9ybWF0aW9uIGZvciBhIE1vZGVs
IHJlc291cmNlLiBGb3IKIGluZm9ybWF0aW9uIG9uIHRoZSBleHBvcnRlZCBmaWVsZHMsIHNl
ZQogW0FNTCBvdXRwdXQgZGF0YQogbW9kZWxdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9m
aW5hbmNpYWwtc2VydmljZXMvYW50aS1tb25leS1sYXVuZGVyaW5nL2RvY3MvcmVmZXJlbmNl
L3NjaGVtYXMvYW1sLW91dHB1dC1kYXRhLW1vZGVsI21vZGVsKS4KCg0KBQYAAhABEgTyAQYZ
Cg0KBQYAAhACEgTyARo0Cg0KBQYAAhADEgTzAQ8rCg8KBQYAAhAEEgb0AQT3AQYKEwoJBgAC
EASwyrwiEgb0AQT3AQYKDwoFBgACEAQSBvgBBPkBMAoSCggGAAIQBJsIABIG+AEE+QEwCg8K
BQYAAhAEEgb6AQT9AQYKEQoHBgACEASZCBIG+gEE/QEGCiIKBAYAAhESBoECAooCAxoSIERl
bGV0ZXMgYSBtb2RlbC4KCg0KBQYAAhEBEgSBAgYRCg0KBQYAAhECEgSBAhIkCg0KBQYAAhED
EgSBAi9LCg8KBQYAAhEEEgaCAgSEAgYKEwoJBgACEQSwyrwiEgaCAgSEAgYKDQoFBgACEQQS
BIUCBDIKEAoIBgACEQSbCAASBIUCBDIKDwoFBgACEQQSBoYCBIkCBgoRCgcGAAIRBJkIEgaG
AgSJAgYKJwoEBgACEhIGjQICkwIDGhcgTGlzdHMgZW5naW5lIGNvbmZpZ3MuCgoNCgUGAAIS
ARIEjQIGFwoNCgUGAAISAhIEjQIYMAoNCgUGAAISAxIEjgIPKAoPCgUGAAISBBIGjwIEkQIG
ChMKCQYAAhIEsMq8IhIGjwIEkQIGCg0KBQYAAhIEEgSSAgQ0ChAKCAYAAhIEmwgAEgSSAgQ0
CigKBAYAAhMSBpYCApsCAxoYIEdldHMgYW4gZW5naW5lIGNvbmZpZy4KCg0KBQYAAhMBEgSW
AgYVCg0KBQYAAhMCEgSWAhYsCg0KBQYAAhMDEgSWAjdDCg8KBQYAAhMEEgaXAgSZAgYKEwoJ
BgACEwSwyrwiEgaXAgSZAgYKDQoFBgACEwQSBJoCBDIKEAoIBgACEwSbCAASBJoCBDIKKwoE
BgACFBIGngICqgIDGhsgQ3JlYXRlcyBhbiBlbmdpbmUgY29uZmlnLgoKDQoFBgACFAESBJ4C
BhgKDQoFBgACFAISBJ4CGTIKDQoFBgACFAMSBJ8CDysKDwoFBgACFAQSBqACBKMCBgoTCgkG
AAIUBLDKvCISBqACBKMCBgoPCgUGAAIUBBIGpAIEpQIwChIKCAYAAhQEmwgAEgakAgSlAjAK
DwoFBgACFAQSBqYCBKkCBgoRCgcGAAIUBJkIEgamAgSpAgYKQgoEBgACFRIGrQICuAIDGjIg
VXBkYXRlcyB0aGUgcGFyYW1ldGVycyBvZiBhIHNpbmdsZSBFbmdpbmVDb25maWcuCgoNCgUG
AAIVARIErQIGGAoNCgUGAAIVAhIErQIZMgoNCgUGAAIVAxIErgIPKwoPCgUGAAIVBBIGrwIE
sgIGChMKCQYAAhUEsMq8IhIGrwIEsgIGCg0KBQYAAhUEEgSzAgRHChAKCAYAAhUEmwgAEgSz
AgRHCg8KBQYAAhUEEga0AgS3AgYKEQoHBgACFQSZCBIGtAIEtwIGCpQCCgQGAAIWEga+AgLK
AgMagwIgRXhwb3J0IGdvdmVybmFuY2UgaW5mb3JtYXRpb24gZm9yIGFuIEVuZ2luZUNvbmZp
ZyByZXNvdXJjZS4gRm9yCiBpbmZvcm1hdGlvbiBvbiB0aGUgZXhwb3J0ZWQgZmllbGRzLCBz
ZWUKIFtBTUwgb3V0cHV0IGRhdGEKIG1vZGVsXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
ZmluYW5jaWFsLXNlcnZpY2VzL2FudGktbW9uZXktbGF1bmRlcmluZy9kb2NzL3JlZmVyZW5j
ZS9zY2hlbWFzL2FtbC1vdXRwdXQtZGF0YS1tb2RlbCNlbmdpbmUtY29uZmlnKS4KCg0KBQYA
AhYBEgS+AgYgCg0KBQYAAhYCEgS+AiFCCg0KBQYAAhYDEgS/Ag8rCg8KBQYAAhYEEgbAAgTD
AgYKEwoJBgACFgSwyrwiEgbAAgTDAgYKDwoFBgACFgQSBsQCBMUCOAoSCggGAAIWBJsIABIG
xAIExQI4Cg8KBQYAAhYEEgbGAgTJAgYKEQoHBgACFgSZCBIGxgIEyQIGCisKBAYAAhcSBs0C
AtcCAxobIERlbGV0ZXMgYW4gZW5naW5lIGNvbmZpZy4KCg0KBQYAAhcBEgTNAgYYCg0KBQYA
AhcCEgTNAhkyCg0KBQYAAhcDEgTOAg8rCg8KBQYAAhcEEgbPAgTRAgYKEwoJBgACFwSwyrwi
EgbPAgTRAgYKDQoFBgACFwQSBNICBDIKEAoIBgACFwSbCAASBNICBDIKDwoFBgACFwQSBtMC
BNYCBgoRCgcGAAIXBJkIEgbTAgTWAgYKLgoEBgACGBIG2gIC3wIDGh4gR2V0cyBhIHNpbmds
ZSBFbmdpbmVWZXJzaW9uLgoKDQoFBgACGAESBNoCBhYKDQoFBgACGAISBNoCFy4KDQoFBgAC
GAMSBNoCOUYKDwoFBgACGAQSBtsCBN0CBgoTCgkGAAIYBLDKvCISBtsCBN0CBgoNCgUGAAIY
BBIE3gIEMgoQCggGAAIYBJsIABIE3gIEMgo6CgQGAAIZEgbiAgLoAgMaKiBMaXN0cyBFbmdp
bmVWZXJzaW9ucyBmb3IgZ2l2ZW4gbG9jYXRpb24uCgoNCgUGAAIZARIE4gIGGAoNCgUGAAIZ
AhIE4gIZMgoNCgUGAAIZAxIE4wIPKQoPCgUGAAIZBBIG5AIE5gIGChMKCQYAAhkEsMq8IhIG
5AIE5gIGCg0KBQYAAhkEEgTnAgQ0ChAKCAYAAhkEmwgAEgTnAgQ0CikKBAYAAhoSBusCAvEC
AxoZIExpc3QgUHJlZGljdGlvblJlc3VsdHMuCgoNCgUGAAIaARIE6wIGGwoNCgUGAAIaAhIE
6wIcOAoNCgUGAAIaAxIE7AIPLAoPCgUGAAIaBBIG7QIE7wIGChMKCQYAAhoEsMq8IhIG7QIE
7wIGCg0KBQYAAhoEEgTwAgQ0ChAKCAYAAhoEmwgAEgTwAgQ0CioKBAYAAhsSBvQCAvoCAxoa
IEdldHMgYSBQcmVkaWN0aW9uUmVzdWx0LgoKDQoFBgACGwESBPQCBhkKDQoFBgACGwISBPQC
GjQKDQoFBgACGwMSBPUCDx8KDwoFBgACGwQSBvYCBPgCBgoTCgkGAAIbBLDKvCISBvYCBPgC
BgoNCgUGAAIbBBIE+QIEMgoQCggGAAIbBJsIABIE+QIEMgosCgQGAAIcEgb9AgKJAwMaHCBD
cmVhdGUgYSBQcmVkaWN0aW9uUmVzdWx0LgoKDQoFBgACHAESBP0CBhwKDQoFBgACHAISBP0C
HToKDQoFBgACHAMSBP4CDysKDwoFBgACHAQSBv8CBIIDBgoTCgkGAAIcBLDKvCISBv8CBIID
BgoPCgUGAAIcBBIGgwMEhAM4ChIKCAYAAhwEmwgAEgaDAwSEAzgKDwoFBgACHAQSBoUDBIgD
BgoRCgcGAAIcBJkIEgaFAwSIAwYKRgoEBgACHRIGjAMClwMDGjYgVXBkYXRlcyB0aGUgcGFy
YW1ldGVycyBvZiBhIHNpbmdsZSBQcmVkaWN0aW9uUmVzdWx0LgoKDQoFBgACHQESBIwDBhwK
DQoFBgACHQISBIwDHToKDQoFBgACHQMSBI0DDysKDwoFBgACHQQSBo4DBJEDBgoTCgkGAAId
BLDKvCISBo4DBJEDBgoNCgUGAAIdBBIEkgMESwoQCggGAAIdBJsIABIEkgMESwoPCgUGAAId
BBIGkwMElgMGChEKBwYAAh0EmQgSBpMDBJYDBgqcAgoEBgACHhIGnQMCqQMDGosCIEV4cG9y
dCBnb3Zlcm5hbmNlIGluZm9ybWF0aW9uIGZvciBhIFByZWRpY3Rpb25SZXN1bHQgcmVzb3Vy
Y2UuIEZvcgogaW5mb3JtYXRpb24gb24gdGhlIGV4cG9ydGVkIGZpZWxkcywgc2VlCiBbQU1M
IG91dHB1dCBkYXRhCiBtb2RlbF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2ZpbmFuY2lh
bC1zZXJ2aWNlcy9hbnRpLW1vbmV5LWxhdW5kZXJpbmcvZG9jcy9yZWZlcmVuY2Uvc2NoZW1h
cy9hbWwtb3V0cHV0LWRhdGEtbW9kZWwjcHJlZGljdGlvbi1yZXN1bHRzKS4KCg0KBQYAAh4B
EgSdAwYkCg0KBQYAAh4CEgSdAyVKCg0KBQYAAh4DEgSeAw8rCg8KBQYAAh4EEgafAwSiAwYK
EwoJBgACHgSwyrwiEgafAwSiAwYKDwoFBgACHgQSBqMDBKQDPAoSCggGAAIeBJsIABIGowME
pAM8Cg8KBQYAAh4EEgalAwSoAwYKEQoHBgACHgSZCBIGpQMEqAMGCi0KBAYAAh8SBqwDArYD
AxodIERlbGV0ZXMgYSBQcmVkaWN0aW9uUmVzdWx0LgoKDQoFBgACHwESBKwDBhwKDQoFBgAC
HwISBKwDHToKDQoFBgACHwMSBK0DDysKDwoFBgACHwQSBq4DBLADBgoTCgkGAAIfBLDKvCIS
Bq4DBLADBgoNCgUGAAIfBBIEsQMEMgoQCggGAAIfBJsIABIEsQMEMgoPCgUGAAIfBBIGsgME
tQMGChEKBwYAAh8EmQgSBrIDBLUDBgonCgQGAAIgEga5AwK/AwMaFyBMaXN0IEJhY2t0ZXN0
UmVzdWx0cy4KCg0KBQYAAiABEgS5AwYZCg0KBQYAAiACEgS5Axo0Cg0KBQYAAiADEgS6Aw8q
Cg8KBQYAAiAEEga7AwS9AwYKEwoJBgACIASwyrwiEga7AwS9AwYKDQoFBgACIAQSBL4DBDQK
EAoIBgACIASbCAASBL4DBDQKKAoEBgACIRIGwgMCxwMDGhggR2V0cyBhIEJhY2t0ZXN0UmVz
dWx0LgoKDQoFBgACIQESBMIDBhcKDQoFBgACIQISBMIDGDAKDQoFBgACIQMSBMIDO0kKDwoF
BgACIQQSBsMDBMUDBgoTCgkGAAIhBLDKvCISBsMDBMUDBgoNCgUGAAIhBBIExgMEMgoQCggG
AAIhBJsIABIExgMEMgoqCgQGAAIiEgbKAwLWAwMaGiBDcmVhdGUgYSBCYWNrdGVzdFJlc3Vs
dC4KCg0KBQYAAiIBEgTKAwYaCg0KBQYAAiICEgTKAxs2Cg0KBQYAAiIDEgTLAw8rCg8KBQYA
AiIEEgbMAwTPAwYKEwoJBgACIgSwyrwiEgbMAwTPAwYKDwoFBgACIgQSBtADBNEDNAoSCggG
AAIiBJsIABIG0AME0QM0Cg8KBQYAAiIEEgbSAwTVAwYKEQoHBgACIgSZCBIG0gME1QMGCkQK
BAYAAiMSBtkDAuQDAxo0IFVwZGF0ZXMgdGhlIHBhcmFtZXRlcnMgb2YgYSBzaW5nbGUgQmFj
a3Rlc3RSZXN1bHQuCgoNCgUGAAIjARIE2QMGGgoNCgUGAAIjAhIE2QMbNgoNCgUGAAIjAxIE
2gMPKwoPCgUGAAIjBBIG2wME3gMGChMKCQYAAiMEsMq8IhIG2wME3gMGCg0KBQYAAiMEEgTf
AwRJChAKCAYAAiMEmwgAEgTfAwRJCg8KBQYAAiMEEgbgAwTjAwYKEQoHBgACIwSZCBIG4AME
4wMGCpgCCgQGAAIkEgbqAwL2AwMahwIgRXhwb3J0IGdvdmVybmFuY2UgaW5mb3JtYXRpb24g
Zm9yIGEgQmFja3Rlc3RSZXN1bHQgcmVzb3VyY2UuIEZvcgogaW5mb3JtYXRpb24gb24gdGhl
IGV4cG9ydGVkIGZpZWxkcywgc2VlCiBbQU1MIG91dHB1dCBkYXRhCiBtb2RlbF0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2ZpbmFuY2lhbC1zZXJ2aWNlcy9hbnRpLW1vbmV5LWxhdW5k
ZXJpbmcvZG9jcy9yZWZlcmVuY2Uvc2NoZW1hcy9hbWwtb3V0cHV0LWRhdGEtbW9kZWwjYmFj
a3Rlc3QtcmVzdWx0cykuCgoNCgUGAAIkARIE6gMGIgoNCgUGAAIkAhIE6gMjRgoNCgUGAAIk
AxIE6wMPKwoPCgUGAAIkBBIG7AME7wMGChMKCQYAAiQEsMq8IhIG7AME7wMGCg8KBQYAAiQE
EgbwAwTxAzoKEgoIBgACJASbCAASBvADBPEDOgoPCgUGAAIkBBIG8gME9QMGChEKBwYAAiQE
mQgSBvIDBPUDBgorCgQGAAIlEgb5AwKDBAMaGyBEZWxldGVzIGEgQmFja3Rlc3RSZXN1bHQu
CgoNCgUGAAIlARIE+QMGGgoNCgUGAAIlAhIE+QMbNgoNCgUGAAIlAxIE+gMPKwoPCgUGAAIl
BBIG+wME/QMGChMKCQYAAiUEsMq8IhIG+wME/QMGCg0KBQYAAiUEEgT+AwQyChAKCAYAAiUE
mwgAEgT+AwQyCg8KBQYAAiUEEgb/AwSCBAYKEQoHBgACJQSZCBIG/wMEggQGCkYKAgQAEgaH
BAClBAEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9w
ZXJhdGlvbi4KCgsKAwQAARIEhwQIGQpCCgQEAAIAEgaJBAKKBDIaMiBPdXRwdXQgb25seS4g
VGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3YXMgY3JlYXRlZC4KCg0KBQQAAgAGEgSJBAIbCg0K
BQQAAgABEgSJBBwnCg0KBQQAAgADEgSJBCorCg0KBQQAAgAIEgSKBAYxChAKCAQAAgAInAgA
EgSKBAcwCkcKBAQAAgESBo0EAo4EMho3IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgb3Bl
cmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoNCgUEAAIBBhIEjQQCGwoNCgUEAAIBARIEjQQc
JAoNCgUEAAIBAxIEjQQnKAoNCgUEAAIBCBIEjgQGMQoQCggEAAIBCJwIABIEjgQHMAqaAQoE
BAACAhIEkwQCQBqLASBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0
aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgogZm9ybWF0OiAiL3Byb2plY3Rz
L3twcm9qZWN0fS8uLi4iCiBWUEMtU0MgcmVzdHJpY3Rpb25zIGFwcGx5LgoKDQoFBAACAgUS
BJMEAggKDQoFBAACAgESBJMECQ8KDQoFBAACAgMSBJMEEhMKDQoFBAACAggSBJMEFD8KEAoI
BAACAgicCAASBJMEFT4KSAoEBAACAxIElgQCPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRo
ZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoNCgUEAAIDBRIElgQCCAoNCgUE
AAIDARIElgQJDQoNCgUEAAIDAxIElgQQEQoNCgUEAAIDCBIElgQSPQoQCggEAAIDCJwIABIE
lgQTPApMCgQEAAIEEgSZBAJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1
cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoNCgUEAAIEBRIEmQQCCAoNCgUEAAIEARIE
mQQJFwoNCgUEAAIEAxIEmQQaGwoNCgUEAAIECBIEmQQcRwoQCggEAAIECJwIABIEmQQdRgqP
AgoEBAACBRIEoQQCThqAAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1
c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uIG9mIHRoZQogb3BlcmF0aW9uLgoKIFN1
Y2Nlc3NmdWxseSBjYW5jZWxsZWQgb3BlcmF0aW9ucyBoYXZlIGEgW09wZXJhdGlvbi5lcnJv
cl1bXSB2YWx1ZQogd2l0aCBhIFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBj
LlN0YXR1cy5jb2RlXSBvZiAxLCBjb3JyZXNwb25kaW5nCiB0byBgQ29kZS5DQU5DRUxMRURg
LgoKDQoFBAACBQUSBKEEAgYKDQoFBAACBQESBKEEBx0KDQoFBAACBQMSBKEEICEKDQoFBAAC
BQgSBKEEIk0KEAoIBAACBQicCAASBKEEI0wKRQoEBAACBhIEpAQCRRo3IE91dHB1dCBvbmx5
LiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRpb24uCgoNCgUEAAIGBRIE
pAQCCAoNCgUEAAIGARIEpAQJFAoNCgUEAAIGAxIEpAQXGAoNCgUEAAIGCBIEpAQZRAoQCggE
AAIGCJwIABIEpAQaQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Financialservices::V1::Service::AMLClient ===
package Google::Cloud::Financialservices::V1::Service::AMLClient;

=pod

=head2 Service Client: Google::Cloud::Financialservices::V1::Service::AMLClient

Client stub representing the remote C<AML> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<financialservices.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'financialservices.googleapis.com:443' );

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

sub list_instances {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::ListInstancesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListInstances',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::Instance::ListInstancesResponse',
    });
}

sub get_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::GetInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetInstance',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::Instance::Instance',
    });
}

sub create_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::CreateInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'CreateInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::UpdateInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'UpdateInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::DeleteInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'DeleteInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_registered_parties {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ImportRegisteredParties',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_registered_parties {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ExportRegisteredParties',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_datasets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Dataset::ListDatasetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListDatasets',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::Dataset::ListDatasetsResponse',
    });
}

sub get_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Dataset::GetDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetDataset',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::Dataset::Dataset',
    });
}

sub create_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Dataset::CreateDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'CreateDataset',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Dataset::UpdateDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'UpdateDataset',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Dataset::DeleteDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'DeleteDataset',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Model::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::Model::ListModelsResponse',
    });
}

sub get_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Model::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::Model::Model',
    });
}

sub create_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Model::CreateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'CreateModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Model::UpdateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'UpdateModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_model_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Model::ExportModelMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ExportModelMetadata',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::Model::DeleteModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'DeleteModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_engine_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListEngineConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsResponse',
    });
}

sub get_engine_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineConfig::GetEngineConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetEngineConfig',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig',
    });
}

sub create_engine_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineConfig::CreateEngineConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'CreateEngineConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_engine_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineConfig::UpdateEngineConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'UpdateEngineConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_engine_config_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ExportEngineConfigMetadata',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_engine_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineConfig::DeleteEngineConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'DeleteEngineConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_engine_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineVersion::GetEngineVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetEngineVersion',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::EngineVersion::EngineVersion',
    });
}

sub list_engine_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListEngineVersions',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::EngineVersion::ListEngineVersionsResponse',
    });
}

sub list_prediction_results {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListPredictionResults',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsResponse',
    });
}

sub get_prediction_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::PredictionResult::GetPredictionResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetPredictionResult',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult',
    });
}

sub create_prediction_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::PredictionResult::CreatePredictionResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'CreatePredictionResult',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_prediction_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::PredictionResult::UpdatePredictionResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'UpdatePredictionResult',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_prediction_result_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ExportPredictionResultMetadata',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_prediction_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::PredictionResult::DeletePredictionResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'DeletePredictionResult',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_backtest_results {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ListBacktestResults',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsResponse',
    });
}

sub get_backtest_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::BacktestResult::GetBacktestResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'GetBacktestResult',
        request        => $req,
        response_class => 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult',
    });
}

sub create_backtest_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::BacktestResult::CreateBacktestResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'CreateBacktestResult',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_backtest_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::BacktestResult::UpdateBacktestResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'UpdateBacktestResult',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_backtest_result_metadata {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'ExportBacktestResultMetadata',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_backtest_result {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Financialservices::V1::BacktestResult::DeleteBacktestResultRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.financialservices.v1.AML',
        method         => 'DeleteBacktestResult',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::Service - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::Service;

    my $msg = Google::Cloud::Financialservices::V1::Service::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::Service::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::Service::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.
format: "/projects/{project}/..."
VPC-SC restrictions apply.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation of the
operation.

Successfully cancelled operations have a [Operation.error][] value
with a [google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding
to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
