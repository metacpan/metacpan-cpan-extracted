package Google::Cloud::Servicehealth::Logging::V1::EventLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc2VydmljZWhlYWx0aC9sb2dnaW5nL3YxL2V2ZW50X2xvZy5wcm90
bxIlZ29vZ2xlLmNsb3VkLnNlcnZpY2VoZWFsdGgubG9nZ2luZy52MRofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byL1CAoIRXZlbnRMb2cSFAoFdGl0bGUYASABKAlSBXRpdGxl
EiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhJZCghjYXRlZ29yeRgDIAEoDjI9
Lmdvb2dsZS5jbG91ZC5zZXJ2aWNlaGVhbHRoLmxvZ2dpbmcudjEuRXZlbnRMb2cuRXZlbnRD
YXRlZ29yeVIIY2F0ZWdvcnkSSwoFc3RhdGUYBCABKA4yNS5nb29nbGUuY2xvdWQuc2Vydmlj
ZWhlYWx0aC5sb2dnaW5nLnYxLkV2ZW50TG9nLlN0YXRlUgVzdGF0ZRJkCg5kZXRhaWxlZF9z
dGF0ZRgOIAEoDjI9Lmdvb2dsZS5jbG91ZC5zZXJ2aWNlaGVhbHRoLmxvZ2dpbmcudjEuRXZl
bnRMb2cuRGV0YWlsZWRTdGF0ZVINZGV0YWlsZWRTdGF0ZRIrChFpbXBhY3RlZF9wcm9kdWN0
cxgPIAEoCVIQaW1wYWN0ZWRQcm9kdWN0cxItChJpbXBhY3RlZF9sb2NhdGlvbnMYBiABKAlS
EWltcGFjdGVkTG9jYXRpb25zElcKCXJlbGV2YW5jZRgHIAEoDjI5Lmdvb2dsZS5jbG91ZC5z
ZXJ2aWNlaGVhbHRoLmxvZ2dpbmcudjEuRXZlbnRMb2cuUmVsZXZhbmNlUglyZWxldmFuY2US
IQoMcGFyZW50X2V2ZW50GAggASgJUgtwYXJlbnRFdmVudBI7Cgt1cGRhdGVfdGltZRgKIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSOQoKc3RhcnRfdGlt
ZRgLIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRf
dGltZRgMIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSRAoQbmV4
dF91cGRhdGVfdGltZRgNIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDm5leHRV
cGRhdGVUaW1lIj0KDUV2ZW50Q2F0ZWdvcnkSHgoaRVZFTlRfQ0FURUdPUllfVU5TUEVDSUZJ
RUQQABIMCghJTkNJREVOVBACIjYKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCgoG
QUNUSVZFEAESCgoGQ0xPU0VEEAIiZgoNRGV0YWlsZWRTdGF0ZRIeChpERVRBSUxFRF9TVEFU
RV9VTlNQRUNJRklFRBAAEgwKCEVNRVJHSU5HEAESDQoJQ09ORklSTUVEEAISDAoIUkVTT0xW
RUQQAxIKCgZNRVJHRUQQBCJ3CglSZWxldmFuY2USGQoVUkVMRVZBTkNFX1VOU1BFQ0lGSUVE
EAASCwoHVU5LTk9XThACEhAKDE5PVF9JTVBBQ1RFRBAGEhUKEVBBUlRJQUxMWV9SRUxBVEVE
EAcSCwoHUkVMQVRFRBAIEgwKCElNUEFDVEVEEAlCgQEKKWNvbS5nb29nbGUuY2xvdWQuc2Vy
dmljZWhlYWx0aC5sb2dnaW5nLnYxQg1FdmVudExvZ1Byb3RvUAFaQ2Nsb3VkLmdvb2dsZS5j
b20vZ28vc2VydmljZWhlYWx0aC9sb2dnaW5nL2FwaXYxL2xvZ2dpbmdwYjtsb2dnaW5ncGJK
3ScKBxIFDgCTAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
AC4KCQoCAwASAxIAKQoICgEIEgMUAFoKCQoCCAsSAxQAWgoICgEIEgMVACIKCQoCCAoSAxUA
IgoICgEIEgMWAC4KCQoCCAgSAxYALgoICgEIEgMXAEIKCQoCCAESAxcAQgpFCgIEABIFGgCT
AQEaOCBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIHBheWxvYWQgb2Ygc2VydmljZSBoZWFsdGgg
bG9ncy4KCgoKAwQAARIDGggQCl0KBAQABAASBB0CIwMaTyBUaGUgY2F0ZWdvcnkgb2YgdGhl
IGV2ZW50LiBUaGlzIGVudW0gbGlzdHMgYWxsIHBvc3NpYmxlIGNhdGVnb3JpZXMgb2YKIGV2
ZW50LgoKDAoFBAAEAAESAx0HFAomCgYEAAQAAgASAx8EIxoXIFVuc3BlY2lmaWVkIGNhdGVn
b3J5LgoKDgoHBAAEAAIAARIDHwQeCg4KBwQABAACAAISAx8hIgpCCgYEAAQAAgESAyIEERoz
IEV2ZW50IGNhdGVnb3J5IGZvciBzZXJ2aWNlIG91dGFnZSBvciBkZWdyYWRhdGlvbi4KCg4K
BwQABAACAQESAyIEDAoOCgcEAAQAAgECEgMiDxAKVQoEBAAEARIEJgIxAxpHIFRoZSBzdGF0
ZSBvZiB0aGUgZXZlbnQuIFRoaXMgZW51bSBsaXN0cyBhbGwgcG9zc2libGUgc3RhdGVzIG9m
IGV2ZW50LgoKDAoFBAAEAQESAyYHDAoiCgYEAAQBAgASAygEGhoTIFVuc3BlY2lmaWVkIHN0
YXRlCgoOCgcEAAQBAgABEgMoBBUKDgoHBAAEAQIAAhIDKBgZCmoKBgQABAECARIDLAQPGlsg
RXZlbnQgaXMgYWN0aXZlbHkgYWZmZWN0aW5nIGEgR29vZ2xlIENsb3VkIHNlcnZpY2UgYW5k
IHdpbGwgY29udGludWUgdG8KIHJlY2VpdmUgdXBkYXRlcy4KCg4KBwQABAECAQESAywECgoO
CgcEAAQBAgECEgMsDQ4KbgoGBAAEAQICEgMwBA8aXyBFdmVudCBpcyBubyBsb25nZXIgYWZm
ZWN0aW5nIHRoZSBHb29nbGUgQ2xvdWQgc2VydmljZSBvciBoYXMgYmVlbiBtZXJnZWQKIHdp
dGggYW5vdGhlciBldmVudC4KCg4KBwQABAECAgESAzAECgoOCgcEAAQBAgICEgMwDQ4KZgoE
BAAEAhIENQJJAxpYIFRoZSBkZXRhaWxlZCBzdGF0ZSBvZiB0aGUgZXZlbnQuIFRoaXMgZW51
bSBsaXN0cyBhbGwgcG9zc2libGUgZGV0YWlsIHN0YXRlcwogb2YgZXZlbnQuCgoMCgUEAAQC
ARIDNQcUCioKBgQABAICABIDNwQjGhsgVW5zcGVjaWZpZWQgZGV0YWlsIHN0YXRlLgoKDgoH
BAAEAgIAARIDNwQeCg4KBwQABAICAAISAzchIgpgCgYEAAQCAgESAzsEERpRIEdvb2dsZSBl
bmdpbmVlcnMgYXJlIGFjdGl2ZWx5IGludmVzdGlnYXRpbmcgdGhlIGV2ZW50IHRvIGRldGVy
bWluZSB0aGUKIGltcGFjdC4KCg4KBwQABAICAQESAzsEDAoOCgcEAAQCAgECEgM7DxAKmAEK
BgQABAICAhIDPwQSGogBIFRoZSBldmVudCBpcyBjb25maXJtZWQgYW5kIGltcGFjdGluZyBh
dCBsZWFzdCBvbmUgR29vZ2xlIENsb3VkIHNlcnZpY2UuCiBPbmdvaW5nIHN0YXR1cyB1cGRh
dGVzIHdpbGwgYmUgcHJvdmlkZWQgdW50aWwgaXQgaXMgcmVzb2x2ZWQuCgoOCgcEAAQCAgIB
EgM/BA0KDgoHBAAEAgICAhIDPxARCnIKBgQABAICAxIDQwQRGmMgVGhlIGV2ZW50IGlzIG5v
IGxvbmdlciBhZmZlY3RpbmcgYW55IEdvb2dsZSBDbG91ZCBzZXJ2aWNlLCBhbmQgdGhlcmUg
d2lsbAogYmUgbm8gZnVydGhlciB1cGRhdGVzLgoKDgoHBAAEAgIDARIDQwQMCg4KBwQABAIC
AwISA0MPEAqtAQoGBAAEAgIEEgNIBA8anQEgRXZlbnQgd2FzIG1lcmdlZCBpbnRvIGEgcGFy
ZW50IGV2ZW50LiBBbGwgZnVydGhlciB1cGRhdGVzIHdpbGwgYmUKIHB1Ymxpc2hlZCB0byB0
aGUgcGFyZW50IG9ubHkuIFRoZSBgcGFyZW50X2V2ZW50YCBmaWVsZCBjb250YWlucyB0aGUg
bmFtZQogb2YgdGhlIHBhcmVudC4KCg4KBwQABAICBAESA0gECgoOCgcEAAQCAgQCEgNIDQ4K
oQEKBAQABAMSBE0CYQMakgEgQ29tbXVuaWNhdGVzIHdoeSBhIGdpdmVuIGV2ZW50IGlzIGRl
ZW1lZCByZWxldmFudCBpbiB0aGUgY29udGV4dCBvZiBhIGdpdmVuCiBwcm9qZWN0LiBUaGlz
IGVudW0gbGlzdHMgYWxsIHBvc3NpYmxlIGRldGFpbGVkIHN0YXRlcyBvZiByZWxldmFuY2Uu
CgoMCgUEAAQDARIDTQcQCicKBgQABAMCABIDTwQeGhggVW5zcGVjaWZpZWQgcmVsZXZhbmNl
LgoKDgoHBAAEAwIAARIDTwQZCg4KBwQABAMCAAISA08cHQpGCgYEAAQDAgESA1IEEBo3IFRo
ZSByZWxldmFuY2Ugb2YgdGhlIGV2ZW50IHRvIHRoZSBwcm9qZWN0IGlzIHVua25vd24uCgoO
CgcEAAQDAgEBEgNSBAsKDgoHBAAEAwIBAhIDUg4PCjcKBgQABAMCAhIDVQQVGiggVGhlIGV2
ZW50IGRvZXMgbm90IGltcGFjdCB0aGUgcHJvamVjdC4KCg4KBwQABAMCAgESA1UEEAoOCgcE
AAQDAgICEgNVExQKvgEKBgQABAMCAxIDWgQaGq4BIFdlIGRldGVybWluZWQgdGhhdCB0aGUg
ZXZlbnQgaXMgbGlua2VkIHRvIGEgcHJvZHVjdCB0aGF0IGlzIHVzZWQgYnkKIHRoZSBwcm9q
ZWN0LCBidXQgd2UgaGF2ZSBubyBpbmZvcm1hdGlvbiAoZWl0aGVyIHBvc2l0aXZlCiBvciBu
ZWdhdGl2ZSkgd2hldGhlciB0aGUgcHJvamVjdCBpcyBhZmZlY3RlZC4KCg4KBwQABAMCAwES
A1oEFQoOCgcEAAQDAgMCEgNaGBkKUgoGBAAEAwIEEgNdBBAaQyBUaGUgZXZlbnQgaGFzIGEg
Y29ubmVjdGlvbiB0byB5b3VyIHByb2plY3QgYW5kIGl0IG1heSBiZSBpbXBhY3RlZAoKDgoH
BAAEAwIEARIDXQQLCg4KBwQABAMCBAISA10ODwo0CgYEAAQDAgUSA2AEERolIFRoZSBldmVu
dCBpcyBpbXBhY3RpbmcgeW91ciBwcm9qZWN0CgoOCgcEAAQDAgUBEgNgBAwKDgoHBAAEAwIF
AhIDYA8QCi8KBAQAAgASA2QCExoiIEJyaWVmIGRlc2NyaXB0aW9uIGZvciB0aGUgZXZlbnQu
CgoMCgUEAAIABRIDZAIICgwKBQQAAgABEgNkCQ4KDAoFBAACAAMSA2QREgo1CgQEAAIBEgNn
AhkaKCBGcmVlLWZvcm0sIGh1bWFuLXJlYWRhYmxlIGRlc2NyaXB0aW9uLgoKDAoFBAACAQUS
A2cCCAoMCgUEAAIBARIDZwkUCgwKBQQAAgEDEgNnFxgKNAoEBAACAhIDagIdGicgSWRlbnRp
ZmllcyB0aGUgY2F0ZWdvcnkgb2YgdGhlIGV2ZW50LgoKDAoFBAACAgYSA2oCDwoMCgUEAAIC
ARIDahAYCgwKBQQAAgIDEgNqGxwKLgoEBAACAxIDbQISGiEgVGhlIGN1cnJlbnQgc3RhdGUg
b2YgdGhlIGV2ZW50LgoKDAoFBAACAwYSA20CBwoMCgUEAAIDARIDbQgNCgwKBQQAAgMDEgNt
EBEKNwoEBAACBBIDcAIkGiogVGhlIGN1cnJlbnQgZGV0YWlsZWQgc3RhdGUgb2YgdGhlIGV2
ZW50LgoKDAoFBAACBAYSA3ACDwoMCgUEAAIEARIDcBAeCgwKBQQAAgQDEgNwISMK9QEKBAQA
AgUSA3cCIBrnASBHb29nbGUgQ2xvdWQgcHJvZHVjdHMga25vd24gdG8gYmUgYWZmZWN0ZWQg
YnkgdGhlIGV2ZW50LCBpbiBKU09OIHNlcmlhbGl6ZWQKIGZvcm1hdC4gTGlzdCBvZiBhbGwg
c3VwcG9ydGVkIFtHb29nbGUgQ2xvdWQKIHByb2R1Y3RzXSguLi9yZXNvdXJjZXMvcHJvZHVj
dHMtbG9jYXRpb25zLm1kKS4KCiBFeGFtcGxlOiAiYFsnR29vZ2xlIENsb3VkIFNRTCcsICdD
bG91ZCBDb21wdXRlIEVuZ2luZSddYCIuCgoMCgUEAAIFBRIDdwIICgwKBQQAAgUBEgN3CRoK
DAoFBAACBQMSA3cdHwrmAQoEBAACBhIDfgIgGtgBIExvY2F0aW9ucyBrbm93biB0byBiZSBp
bXBhY3RlZCBieSB0aGUgZXZlbnQsIGluIEpTT04gc2VyaWFsaXplZCBmb3JtYXQuIFNlZQog
cG9zc2libGUgW3ZhbHVlc10ocHJvZHVjdHMtbG9jYXRpb25zLm1kKSwgd2hpY2ggYXJlIHN1
YmplY3QgdG8gd2hlcmUgdGhlCiBzZXJ2aWNlIGlzIHJ1bm5pbmcuCgogRXhhbXBsZTogImBb
J3VzLWNlbnRyYWwxJywgJ3VzLXdlc3QxJ11gIi4KCgwKBQQAAgYFEgN+AggKDAoFBAACBgES
A34JGwoMCgUEAAIGAxIDfh4fCmUKBAQAAgcSBIIBAhoaVyBDb21tdW5pY2F0ZXMgd2h5IGEg
Z2l2ZW4gZXZlbnQgaXMgZGVlbWVkIHJlbGV2YW50IGluIHRoZSBjb250ZXh0IG9mIGEgZ2l2
ZW4KIHByb2plY3QuCgoNCgUEAAIHBhIEggECCwoNCgUEAAIHARIEggEMFQoNCgUEAAIHAxIE
ggEYGQqiAQoEBAACCBIEhgECGhqTASBXaGVuIGBkZXRhaWxlZF9zdGF0ZWA9YE1FUkdFRGAs
IGBwYXJlbnRfZXZlbnRgIGNvbnRhaW5zIHRoZSBuYW1lIG9mIHRoZQogcGFyZW50IGV2ZW50
LiBBbGwgZnVydGhlciB1cGRhdGVzIHdpbGwgYmUgcHVibGlzaGVkIHRvIHRoZSBwYXJlbnQg
ZXZlbnQuCgoNCgUEAAIIBRIEhgECCAoNCgUEAAIIARIEhgEJFQoNCgUEAAIIAxIEhgEYGQo6
CgQEAAIJEgSJAQItGiwgVGhlIHRpbWUgd2hlbiB0aGUgZXZlbnQgd2FzIGxhc3QgbW9kaWZp
ZWQuCgoNCgUEAAIJBhIEiQECGwoNCgUEAAIJARIEiQEcJwoNCgUEAAIJAxIEiQEqLAo7CgQE
AAIKEgSMAQIsGi0gVGhlIHN0YXJ0IHRpbWUgb2YgdGhlIGV2ZW50LCBpZiBhcHBsaWNhYmxl
LgoKDQoFBAACCgYSBIwBAhsKDQoFBAACCgESBIwBHCYKDQoFBAACCgMSBIwBKSsKOQoEBAAC
CxIEjwECKhorIFRoZSBlbmQgdGltZSBvZiB0aGUgZXZlbnQsIGlmIGFwcGxpY2FibGUuCgoN
CgUEAAILBhIEjwECGwoNCgUEAAILARIEjwEcJAoNCgUEAAILAxIEjwEnKQpTCgQEAAIMEgSS
AQIyGkUgSW5jaWRlbnQtb25seSBmaWVsZC4gVGhlIHRpbWUgd2hlbiB0aGUgbmV4dCB1cGRh
dGUgY2FuIGJlIGV4cGVjdGVkLgoKDQoFBAACDAYSBJIBAhsKDQoFBAACDAESBJIBHCwKDQoF
BAACDAMSBJIBLzFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog ===
    # Fields for EventLog
    # Field: title Type: 9 ()
    # Field: description Type: 9 ()
    # Field: category Type: 14 (.google.cloud.servicehealth.logging.v1.EventLog.EventCategory)
    # Field: state Type: 14 (.google.cloud.servicehealth.logging.v1.EventLog.State)
    # Field: detailed_state Type: 14 (.google.cloud.servicehealth.logging.v1.EventLog.DetailedState)
    # Field: impacted_products Type: 9 ()
    # Field: impacted_locations Type: 9 ()
    # Field: relevance Type: 14 (.google.cloud.servicehealth.logging.v1.EventLog.Relevance)
    # Field: parent_event Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: next_update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: EventLog::EventCategory
our $EventLog_EVENT_CATEGORY_UNSPECIFIED = 0;
our $EventLog_INCIDENT = 2;

# Enum: EventLog::State
our $EventLog_STATE_UNSPECIFIED = 0;
our $EventLog_ACTIVE = 1;
our $EventLog_CLOSED = 2;

# Enum: EventLog::DetailedState
our $EventLog_DETAILED_STATE_UNSPECIFIED = 0;
our $EventLog_EMERGING = 1;
our $EventLog_CONFIRMED = 2;
our $EventLog_RESOLVED = 3;
our $EventLog_MERGED = 4;

# Enum: EventLog::Relevance
our $EventLog_RELEVANCE_UNSPECIFIED = 0;
our $EventLog_UNKNOWN = 2;
our $EventLog_NOT_IMPACTED = 6;
our $EventLog_PARTIALLY_RELATED = 7;
our $EventLog_RELATED = 8;
our $EventLog_IMPACTED = 9;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicehealth::Logging::V1::EventLog - Compiled Protocol Buffers messages for google/cloud/servicehealth/logging/v1/event_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicehealth::Logging::V1::EventLog;

    my $msg = Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog->new({
        title => $title,
        description => $description,
        category => $category,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicehealth/logging/v1/event_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog

Message describing the payload of service health logs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Brief description for the event.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Free-form, human-readable description.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Servicehealth::Logging::V1::EventLog::EventCategory>)

Identifies the category of the event.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Servicehealth::Logging::V1::EventLog::State>)

The current state of the event.

=item * C<< $msg->detailed_state() >> / C<< $msg->detailed_state($value) >>

Type: C<Enum> (L<Google::Cloud::Servicehealth::Logging::V1::EventLog::DetailedState>)

The current detailed state of the event.

=item * C<< $msg->impacted_products() >> / C<< $msg->impacted_products($value) >>

Type: C<String>

Google Cloud products known to be affected by the event, in JSON serialized
format. List of all supported [Google Cloud
products](../resources/products-locations.md).

Example: "`['Google Cloud SQL', 'Cloud Compute Engine']`".

=item * C<< $msg->impacted_locations() >> / C<< $msg->impacted_locations($value) >>

Type: C<String>

Locations known to be impacted by the event, in JSON serialized format. See
possible [values](products-locations.md), which are subject to where the
service is running.

Example: "`['us-central1', 'us-west1']`".

=item * C<< $msg->relevance() >> / C<< $msg->relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Servicehealth::Logging::V1::EventLog::Relevance>)

Communicates why a given event is deemed relevant in the context of a given
project.

=item * C<< $msg->parent_event() >> / C<< $msg->parent_event($value) >>

Type: C<String>

When `detailed_state`=`MERGED`, `parent_event` contains the name of the
parent event. All further updates will be published to the parent event.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the event was last modified.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The start time of the event, if applicable.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The end time of the event, if applicable.

=item * C<< $msg->next_update_time() >> / C<< $msg->next_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Incident-only field. The time when the next update can be expected.

=back

=head3 Enum: EventLog::EventCategory

=over 4

=item * C<EVENT_CATEGORY_UNSPECIFIED> => C<0>

=item * C<INCIDENT> => C<2>

=back

=head3 Enum: EventLog::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<CLOSED> => C<2>

=back

=head3 Enum: EventLog::DetailedState

=over 4

=item * C<DETAILED_STATE_UNSPECIFIED> => C<0>

=item * C<EMERGING> => C<1>

=item * C<CONFIRMED> => C<2>

=item * C<RESOLVED> => C<3>

=item * C<MERGED> => C<4>

=back

=head3 Enum: EventLog::Relevance

=over 4

=item * C<RELEVANCE_UNSPECIFIED> => C<0>

=item * C<UNKNOWN> => C<2>

=item * C<NOT_IMPACTED> => C<6>

=item * C<PARTIALLY_RELATED> => C<7>

=item * C<RELATED> => C<8>

=item * C<IMPACTED> => C<9>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicehealth::Logging::V1::EventLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
