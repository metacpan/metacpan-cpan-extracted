package Google::Cloud::Osconfig::V1beta::PatchDeployments;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Osconfig::V1beta::PatchJobs };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Datetime };
    eval { require Google::Type::Dayofweek };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvb3Njb25maWcvdjFiZXRhL3BhdGNoX2RlcGxveW1lbnRzLnByb3Rv
Ehxnb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvb3Nj
b25maWcvdjFiZXRhL3BhdGNoX2pvYnMucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlv
bi5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8aGmdvb2dsZS90eXBlL2RhdGV0aW1lLnByb3RvGhtnb29n
bGUvdHlwZS9kYXlvZndlZWsucHJvdG8aG2dvb2dsZS90eXBlL3RpbWVvZmRheS5wcm90byKb
CAoPUGF0Y2hEZXBsb3ltZW50EhIKBG5hbWUYASABKAlSBG5hbWUSJQoLZGVzY3JpcHRpb24Y
AiABKAlCA+BBAVILZGVzY3JpcHRpb24SXwoPaW5zdGFuY2VfZmlsdGVyGAMgASgLMjEuZ29v
Z2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5QYXRjaEluc3RhbmNlRmlsdGVyQgPgQQJSDmlu
c3RhbmNlRmlsdGVyElEKDHBhdGNoX2NvbmZpZxgEIAEoCzIpLmdvb2dsZS5jbG91ZC5vc2Nv
bmZpZy52MWJldGEuUGF0Y2hDb25maWdCA+BBAVILcGF0Y2hDb25maWcSOgoIZHVyYXRpb24Y
BSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBAVIIZHVyYXRpb24SYAoRb25l
X3RpbWVfc2NoZWR1bGUYBiABKAsyLS5nb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhLk9u
ZVRpbWVTY2hlZHVsZUID4EECSABSD29uZVRpbWVTY2hlZHVsZRJlChJyZWN1cnJpbmdfc2No
ZWR1bGUYByABKAsyLy5nb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhLlJlY3VycmluZ1Nj
aGVkdWxlQgPgQQJIAFIRcmVjdXJyaW5nU2NoZWR1bGUSQAoLY3JlYXRlX3RpbWUYCCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRl
X3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRp
bWUSSwoRbGFzdF9leGVjdXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSD2xhc3RFeGVjdXRlVGltZRJJCgdyb2xsb3V0GAsgASgLMiouZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxYmV0YS5QYXRjaFJvbGxvdXRCA+BBAVIHcm9sbG91dBJOCgVzdGF0
ZRgMIAEoDjIzLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuUGF0Y2hEZXBsb3ltZW50
LlN0YXRlQgPgQQNSBXN0YXRlIjYKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCgoG
QUNUSVZFEAESCgoGUEFVU0VEEAI6ZOpBYQonb3Njb25maWcuZ29vZ2xlYXBpcy5jb20vUGF0
Y2hEZXBsb3ltZW50EjZwcm9qZWN0cy97cHJvamVjdH0vcGF0Y2hEZXBsb3ltZW50cy97cGF0
Y2hfZGVwbG95bWVudH1CCgoIc2NoZWR1bGUiVQoPT25lVGltZVNjaGVkdWxlEkIKDGV4ZWN1
dGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlILZXhlY3V0
ZVRpbWUi+QUKEVJlY3VycmluZ1NjaGVkdWxlEjcKCXRpbWVfem9uZRgBIAEoCzIVLmdvb2ds
ZS50eXBlLlRpbWVab25lQgPgQQJSCHRpbWVab25lEj4KCnN0YXJ0X3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQFSCXN0YXJ0VGltZRI6CghlbmRfdGltZRgD
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAVIHZW5kVGltZRI7Cgt0aW1l
X29mX2RheRgEIAEoCzIWLmdvb2dsZS50eXBlLlRpbWVPZkRheUID4EECUgl0aW1lT2ZEYXkS
XAoJZnJlcXVlbmN5GAUgASgOMjkuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5SZWN1
cnJpbmdTY2hlZHVsZS5GcmVxdWVuY3lCA+BBAlIJZnJlcXVlbmN5EksKBndlZWtseRgGIAEo
CzIsLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuV2Vla2x5U2NoZWR1bGVCA+BBAkgA
UgZ3ZWVrbHkSTgoHbW9udGhseRgHIAEoCzItLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJl
dGEuTW9udGhseVNjaGVkdWxlQgPgQQJIAFIHbW9udGhseRJLChFsYXN0X2V4ZWN1dGVfdGlt
ZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IPbGFzdEV4ZWN1dGVU
aW1lEksKEW5leHRfZXhlY3V0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUg9uZXh0RXhlY3V0ZVRpbWUiSgoJRnJlcXVlbmN5EhkKFUZSRVFVRU5DWV9V
TlNQRUNJRklFRBAAEgoKBldFRUtMWRABEgsKB01PTlRITFkQAhIJCgVEQUlMWRADQhEKD3Nj
aGVkdWxlX2NvbmZpZyJNCg5XZWVrbHlTY2hlZHVsZRI7CgtkYXlfb2Zfd2VlaxgBIAEoDjIW
Lmdvb2dsZS50eXBlLkRheU9mV2Vla0ID4EECUglkYXlPZldlZWsipQEKD01vbnRobHlTY2hl
ZHVsZRJeChF3ZWVrX2RheV9vZl9tb250aBgBIAEoCzIsLmdvb2dsZS5jbG91ZC5vc2NvbmZp
Zy52MWJldGEuV2Vla0RheU9mTW9udGhCA+BBAkgAUg53ZWVrRGF5T2ZNb250aBIiCgltb250
aF9kYXkYAiABKAVCA+BBAkgAUghtb250aERheUIOCgxkYXlfb2ZfbW9udGgimQEKDldlZWtE
YXlPZk1vbnRoEiYKDHdlZWtfb3JkaW5hbBgBIAEoBUID4EECUgt3ZWVrT3JkaW5hbBI7Cgtk
YXlfb2Zfd2VlaxgCIAEoDjIWLmdvb2dsZS50eXBlLkRheU9mV2Vla0ID4EECUglkYXlPZldl
ZWsSIgoKZGF5X29mZnNldBgDIAEoBUID4EEBUglkYXlPZmZzZXQizwEKHENyZWF0ZVBhdGNo
RGVwbG95bWVudFJlcXVlc3QSGwoGcGFyZW50GAEgASgJQgPgQQJSBnBhcmVudBIzChNwYXRj
aF9kZXBsb3ltZW50X2lkGAIgASgJQgPgQQJSEXBhdGNoRGVwbG95bWVudElkEl0KEHBhdGNo
X2RlcGxveW1lbnQYAyABKAsyLS5nb29nbGUuY2xvdWQub3Njb25maWcudjFiZXRhLlBhdGNo
RGVwbG95bWVudEID4EECUg9wYXRjaERlcGxveW1lbnQiNAoZR2V0UGF0Y2hEZXBsb3ltZW50
UmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUigAEKG0xpc3RQYXRjaERlcGxveW1l
bnRzUmVxdWVzdBIbCgZwYXJlbnQYASABKAlCA+BBAlIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgC
IAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tl
biKiAQocTGlzdFBhdGNoRGVwbG95bWVudHNSZXNwb25zZRJaChFwYXRjaF9kZXBsb3ltZW50
cxgBIAMoCzItLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWJldGEuUGF0Y2hEZXBsb3ltZW50
UhBwYXRjaERlcGxveW1lbnRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiI3ChxEZWxldGVQYXRjaERlcGxveW1lbnRSZXF1ZXN0EhcKBG5hbWUYASABKAlCA+BB
AlIEbmFtZSK/AQocVXBkYXRlUGF0Y2hEZXBsb3ltZW50UmVxdWVzdBJdChBwYXRjaF9kZXBs
b3ltZW50GAEgASgLMi0uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YS5QYXRjaERlcGxv
eW1lbnRCA+BBAlIPcGF0Y2hEZXBsb3ltZW50EkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrImIKG1BhdXNlUGF0Y2hE
ZXBsb3ltZW50UmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ29zY29uZmlnLmdvb2ds
ZWFwaXMuY29tL1BhdGNoRGVwbG95bWVudFIEbmFtZSJjChxSZXN1bWVQYXRjaERlcGxveW1l
bnRSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonb3Njb25maWcuZ29vZ2xlYXBpcy5j
b20vUGF0Y2hEZXBsb3ltZW50UgRuYW1lQnIKIGNvbS5nb29nbGUuY2xvdWQub3Njb25maWcu
djFiZXRhQhBQYXRjaERlcGxveW1lbnRzWjxjbG91ZC5nb29nbGUuY29tL2dvL29zY29uZmln
L2FwaXYxYmV0YS9vc2NvbmZpZ3BiO29zY29uZmlncGJKyVsKBxIFDgCmAgEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAKQoJCgIDARID
EwAjCgkKAgMCEgMUADcKCQoCAwMSAxUAKAoJCgIDBBIDFgAqCgkKAgMFEgMXACkKCQoCAwYS
AxgAJAoJCgIDBxIDGQAlCgkKAgMIEgMaACUKCAoBCBIDHABTCgkKAggLEgMcAFMKCAoBCBID
HQAxCgkKAggIEgMdADEKCAoBCBIDHgA5CgkKAggBEgMeADkK9gIKAgQAEgQlAGYBGukCIFBh
dGNoIGRlcGxveW1lbnRzIGFyZSBjb25maWd1cmF0aW9ucyB0aGF0IGluZGl2aWR1YWwgcGF0
Y2ggam9icyB1c2UgdG8KIGNvbXBsZXRlIGEgcGF0Y2guIFRoZXNlIGNvbmZpZ3VyYXRpb25z
IGluY2x1ZGUgaW5zdGFuY2UgZmlsdGVyLCBwYWNrYWdlCiByZXBvc2l0b3J5IHNldHRpbmdz
LCBhbmQgYSBzY2hlZHVsZS4gRm9yIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQgY3JlYXRpbmcg
YW5kCiBtYW5hZ2luZyBwYXRjaCBkZXBsb3ltZW50cywgc2VlIFtTY2hlZHVsaW5nIHBhdGNo
CiBqb2JzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL29zLXBhdGNo
LW1hbmFnZW1lbnQvc2NoZWR1bGUtcGF0Y2gtam9icykuCgoKCgMEAAESAyUIFwoLCgMEAAcS
BCYCKQQKDQoFBAAHnQgSBCYCKQQKNQoEBAAEABIELAI2AxonIFJlcHJlc2VudHMgc3RhdGUg
b2YgcGF0Y2ggcGVwbG95bWVudC4KCgwKBQQABAABEgMsBwwKTwoGBAAEAAIAEgMuBBoaQCBU
aGUgZGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1c2VkIGlmIHRoZSBzdGF0ZSBpcyBv
bWl0dGVkLgoKDgoHBAAEAAIAARIDLgQVCg4KBwQABAACAAISAy4YGQpPCgYEAAQAAgESAzEE
DxpAIEFjdGl2ZSB2YWx1ZSBtZWFucyB0aGF0IHBhdGNoIGRlcGxveW1lbnQgZ2VuZXJhdGVz
IFBhdGNoIEpvYnMuCgoOCgcEAAQAAgEBEgMxBAoKDgoHBAAEAAIBAhIDMQ0OCpIBCgYEAAQA
AgISAzUEDxqCASBQYXVzZWQgdmFsdWUgbWVhbnMgdGhhdCBwYXRjaCBkZXBsb3ltZW50IGRv
ZXMgbm90IGdlbmVyYXRlCiBQYXRjaCBqb2JzLiBSZXF1aXJlcyB1c2VyIGFjdGlvbiB0byBt
b3ZlIGluIGFuZCBvdXQgZnJvbSB0aGlzIHN0YXRlLgoKDgoHBAAEAAICARIDNQQKCg4KBwQA
BAACAgISAzUNDgr2AQoEBAACABIDPAISGugBIFVuaXF1ZSBuYW1lIGZvciB0aGUgcGF0Y2gg
ZGVwbG95bWVudCByZXNvdXJjZSBpbiBhIHByb2plY3QuIFRoZSBwYXRjaAogZGVwbG95bWVu
dCBuYW1lIGlzIGluIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9wYXRjaERl
cGxveW1lbnRzL3twYXRjaF9kZXBsb3ltZW50X2lkfWAuCiBUaGlzIGZpZWxkIGlzIGlnbm9y
ZWQgd2hlbiB5b3UgY3JlYXRlIGEgbmV3IHBhdGNoIGRlcGxveW1lbnQuCgoMCgUEAAIABRID
PAIICgwKBQQAAgABEgM8CQ0KDAoFBAACAAMSAzwQEQp3CgQEAAIBEgNAAkIaaiBPcHRpb25h
bC4gRGVzY3JpcHRpb24gb2YgdGhlIHBhdGNoIGRlcGxveW1lbnQuIExlbmd0aCBvZiB0aGUg
ZGVzY3JpcHRpb24gaXMgbGltaXRlZAogdG8gMTAyNCBjaGFyYWN0ZXJzLgoKDAoFBAACAQUS
A0ACCAoMCgUEAAIBARIDQAkUCgwKBQQAAgEDEgNAFxgKDAoFBAACAQgSA0AZQQoPCggEAAIB
CJwIABIDQBpACi8KBAQAAgISA0MCUxoiIFJlcXVpcmVkLiBWTSBpbnN0YW5jZXMgdG8gcGF0
Y2guCgoMCgUEAAICBhIDQwIVCgwKBQQAAgIBEgNDFiUKDAoFBAACAgMSA0MoKQoMCgUEAAIC
CBIDQypSCg8KCAQAAgIInAgAEgNDK1EKPQoEBAACAxIDRgJIGjAgT3B0aW9uYWwuIFBhdGNo
IGNvbmZpZ3VyYXRpb24gdGhhdCBpcyBhcHBsaWVkLgoKDAoFBAACAwYSA0YCDQoMCgUEAAID
ARIDRg4aCgwKBQQAAgMDEgNGHR4KDAoFBAACAwgSA0YfRwoPCggEAAIDCJwIABIDRiBGCl0K
BAQAAgQSA0kCURpQIE9wdGlvbmFsLiBEdXJhdGlvbiBvZiB0aGUgcGF0Y2guIEFmdGVyIHRo
ZSBkdXJhdGlvbiBlbmRzLCB0aGUgcGF0Y2ggdGltZXMgb3V0LgoKDAoFBAACBAYSA0kCGgoM
CgUEAAIEARIDSRsjCgwKBQQAAgQDEgNJJicKDAoFBAACBAgSA0koUAoPCggEAAIECJwIABID
SSlPCicKBAQACAASBEwCUgMaGSBTY2hlZHVsZSBmb3IgdGhlIHBhdGNoLgoKDAoFBAAIAAES
A0wIEAo3CgQEAAIFEgNOBFMaKiBSZXF1aXJlZC4gU2NoZWR1bGUgYSBvbmUtdGltZSBleGVj
dXRpb24uCgoMCgUEAAIFBhIDTgQTCgwKBQQAAgUBEgNOFCUKDAoFBAACBQMSA04oKQoMCgUE
AAIFCBIDTipSCg8KCAQAAgUInAgAEgNOK1EKNwoEBAACBhIDUQRWGiogUmVxdWlyZWQuIFNj
aGVkdWxlIHJlY3VycmluZyBleGVjdXRpb25zLgoKDAoFBAACBgYSA1EEFQoMCgUEAAIGARID
URYoCgwKBQQAAgYDEgNRKywKDAoFBAACBggSA1EtVQoPCggEAAIGCJwIABIDUS5UCpEBCgQE
AAIHEgNWAlgagwEgT3V0cHV0IG9ubHkuIFRpbWUgdGhlIHBhdGNoIGRlcGxveW1lbnQgd2Fz
IGNyZWF0ZWQuIFRpbWVzdGFtcCBpcyBpbgogW1JGQzMzMzldKGh0dHBzOi8vd3d3LmlldGYu
b3JnL3JmYy9yZmMzMzM5LnR4dCkgdGV4dCBmb3JtYXQuCgoMCgUEAAIHBhIDVgIbCgwKBQQA
AgcBEgNWHCcKDAoFBAACBwMSA1YqKwoMCgUEAAIHCBIDVixXCg8KCAQAAgcInAgAEgNWLVYK
lgEKBAQAAggSA1oCWBqIASBPdXRwdXQgb25seS4gVGltZSB0aGUgcGF0Y2ggZGVwbG95bWVu
dCB3YXMgbGFzdCB1cGRhdGVkLiBUaW1lc3RhbXAgaXMgaW4KIFtSRkMzMzM5XShodHRwczov
L3d3dy5pZXRmLm9yZy9yZmMvcmZjMzMzOS50eHQpIHRleHQgZm9ybWF0LgoKDAoFBAACCAYS
A1oCGwoMCgUEAAIIARIDWhwnCgwKBQQAAggDEgNaKisKDAoFBAACCAgSA1osVwoPCggEAAII
CJwIABIDWi1WCqUBCgQEAAIJEgNfAl8alwEgT3V0cHV0IG9ubHkuIFRoZSBsYXN0IHRpbWUg
YSBwYXRjaCBqb2Igd2FzIHN0YXJ0ZWQgYnkgdGhpcyBkZXBsb3ltZW50LgogVGltZXN0YW1w
IGlzIGluIFtSRkMzMzM5XShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMvcmZjMzMzOS50eHQp
IHRleHQKIGZvcm1hdC4KCgwKBQQAAgkGEgNfAhsKDAoFBAACCQESA18cLQoMCgUEAAIJAxID
XzAyCgwKBQQAAgkIEgNfM14KDwoIBAACCQicCAASA180XQo7CgQEAAIKEgNiAkUaLiBPcHRp
b25hbC4gUm9sbG91dCBzdHJhdGVneSBvZiB0aGUgcGF0Y2ggam9iLgoKDAoFBAACCgYSA2IC
DgoMCgUEAAIKARIDYg8WCgwKBQQAAgoDEgNiGRsKDAoFBAACCggSA2IcRAoPCggEAAIKCJwI
ABIDYh1DCkIKBAQAAgsSA2UCPxo1IE91dHB1dCBvbmx5LiBDdXJyZW50IHN0YXRlIG9mIHRo
ZSBwYXRjaCBkZXBsb3ltZW50LgoKDAoFBAACCwYSA2UCBwoMCgUEAAILARIDZQgNCgwKBQQA
AgsDEgNlEBIKDAoFBAACCwgSA2UTPgoPCggEAAILCJwIABIDZRQ9CooBCgIEARIEagBtARp+
IFNldHMgdGhlIHRpbWUgZm9yIGEgb25lIHRpbWUgcGF0Y2ggZGVwbG95bWVudC4gVGltZXN0
YW1wIGlzIGluCiBbUkZDMzMzOV0oaHR0cHM6Ly93d3cuaWV0Zi5vcmcvcmZjL3JmYzMzMzku
dHh0KSB0ZXh0IGZvcm1hdC4KCgoKAwQBARIDaggXCj4KBAQBAgASA2wCVhoxIFJlcXVpcmVk
LiBUaGUgZGVzaXJlZCBwYXRjaCBqb2IgZXhlY3V0aW9uIHRpbWUuCgoMCgUEAQIABhIDbAIb
CgwKBQQBAgABEgNsHCgKDAoFBAECAAMSA2wrLAoMCgUEAQIACBIDbC1VCg8KCAQBAgAInAgA
EgNsLlQKPQoCBAISBXAApAEBGjAgU2V0cyB0aGUgdGltZSBmb3IgcmVjdXJyaW5nIHBhdGNo
IGRlcGxveW1lbnRzLgoKCgoDBAIBEgNwCBkKTAoEBAIEABIFcgKBAQMaPSBTcGVjaWZpZXMg
dGhlIGZyZXF1ZW5jeSBvZiB0aGUgcmVjdXJyaW5nIHBhdGNoIGRlcGxveW1lbnRzLgoKDAoF
BAIEAAESA3IHEAo4CgYEAgQAAgASA3QEHhopIEludmFsaWQuIEEgZnJlcXVlbmN5IG11c3Qg
YmUgc3BlY2lmaWVkLgoKDgoHBAIEAAIAARIDdAQZCg4KBwQCBAACAAISA3QcHQpjCgYEAgQA
AgESA3gEDxpUIEluZGljYXRlcyB0aGF0IHRoZSBmcmVxdWVuY3kgb2YgcmVjdXJyZW5jZSBz
aG91bGQgYmUgZXhwcmVzc2VkIGluIHRlcm1zCiBvZiB3ZWVrcy4KCg4KBwQCBAACAQESA3gE
CgoOCgcEAgQAAgECEgN4DQ4KZAoGBAIEAAICEgN8BBAaVSBJbmRpY2F0ZXMgdGhhdCB0aGUg
ZnJlcXVlbmN5IG9mIHJlY3VycmVuY2Ugc2hvdWxkIGJlIGV4cHJlc3NlZCBpbiB0ZXJtcwog
b2YgbW9udGhzLgoKDgoHBAIEAAICARIDfAQLCg4KBwQCBAACAgISA3wODwpjCgYEAgQAAgMS
BIABBA4aUyBJbmRpY2F0ZXMgdGhhdCB0aGUgZnJlcXVlbmN5IG9mIHJlY3VycmVuY2Ugc2hv
dWxkIGJlIGV4cHJlc3NlZCBpbiB0ZXJtcwogb2YgZGF5cy4KCg8KBwQCBAACAwESBIABBAkK
DwoHBAIEAAIDAhIEgAEMDQqfAQoEBAICABIEhQECThqQASBSZXF1aXJlZC4gRGVmaW5lcyB0
aGUgdGltZSB6b25lIHRoYXQgYHRpbWVfb2ZfZGF5YCBpcyByZWxhdGl2ZSB0by4KIFRoZSBy
dWxlcyBmb3IgZGF5bGlnaHQgc2F2aW5nIHRpbWUgYXJlIGRldGVybWluZWQgYnkgdGhlIGNo
b3NlbiB0aW1lIHpvbmUuCgoNCgUEAgIABhIEhQECFgoNCgUEAgIAARIEhQEXIAoNCgUEAgIA
AxIEhQEjJAoNCgUEAgIACBIEhQElTQoQCggEAgIACJwIABIEhQEmTAqFAQoEBAICARIEiQEC
VBp3IE9wdGlvbmFsLiBUaGUgdGltZSB0aGF0IHRoZSByZWN1cnJpbmcgc2NoZWR1bGUgYmVj
b21lcyBlZmZlY3RpdmUuCiBEZWZhdWx0cyB0byBgY3JlYXRlX3RpbWVgIG9mIHRoZSBwYXRj
aCBkZXBsb3ltZW50LgoKDQoFBAICAQYSBIkBAhsKDQoFBAICAQESBIkBHCYKDQoFBAICAQMS
BIkBKSoKDQoFBAICAQgSBIkBK1MKEAoIBAICAQicCAASBIkBLFIKawoEBAICAhIEjQECUhpd
IE9wdGlvbmFsLiBUaGUgZW5kIHRpbWUgYXQgd2hpY2ggYSByZWN1cnJpbmcgcGF0Y2ggZGVw
bG95bWVudCBzY2hlZHVsZSBpcyBubyBsb25nZXIKIGFjdGl2ZS4KCg0KBQQCAgIGEgSNAQIb
Cg0KBQQCAgIBEgSNARwkCg0KBQQCAgIDEgSNAScoCg0KBQQCAgIIEgSNASlRChAKCAQCAgII
nAgAEgSNASpQCkgKBAQCAgMSBJABAlEaOiBSZXF1aXJlZC4gVGltZSBvZiB0aGUgZGF5IHRv
IHJ1biBhIHJlY3VycmluZyBkZXBsb3ltZW50LgoKDQoFBAICAwYSBJABAhcKDQoFBAICAwES
BJABGCMKDQoFBAICAwMSBJABJicKDQoFBAICAwgSBJABKFAKEAoIBAICAwicCAASBJABKU8K
SAoEBAICBBIEkwECQxo6IFJlcXVpcmVkLiBUaGUgZnJlcXVlbmN5IHVuaXQgb2YgdGhpcyBy
ZWN1cnJpbmcgc2NoZWR1bGUuCgoNCgUEAgIEBhIEkwECCwoNCgUEAgIEARIEkwEMFQoNCgUE
AgIEAxIEkwEYGQoNCgUEAgIECBIEkwEaQgoQCggEAgIECJwIABIEkwEbQQpjCgQEAggAEgaX
AQKdAQMaUyBDb25maWd1cmF0aW9ucyBmb3IgdGhpcyByZWN1cnJpbmcgc2NoZWR1bGUuCiBD
b25maWd1cmF0aW9ucyBtdXN0IG1hdGNoIGZyZXF1ZW5jeS4KCg0KBQQCCAABEgSXAQgXCjoK
BAQCAgUSBJkBBEcaLCBSZXF1aXJlZC4gU2NoZWR1bGUgd2l0aCB3ZWVrbHkgZXhlY3V0aW9u
cy4KCg0KBQQCAgUGEgSZAQQSCg0KBQQCAgUBEgSZARMZCg0KBQQCAgUDEgSZARwdCg0KBQQC
AgUIEgSZAR5GChAKCAQCAgUInAgAEgSZAR9FCjsKBAQCAgYSBJwBBEkaLSBSZXF1aXJlZC4g
U2NoZWR1bGUgd2l0aCBtb250aGx5IGV4ZWN1dGlvbnMuCgoNCgUEAgIGBhIEnAEEEwoNCgUE
AgIGARIEnAEUGwoNCgUEAgIGAxIEnAEeHwoNCgUEAgIGCBIEnAEgSAoQCggEAgIGCJwIABIE
nAEhRwpKCgQEAgIHEgSgAQJeGjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBsYXN0IHBh
dGNoIGpvYiByYW4gc3VjY2Vzc2Z1bGx5LgoKDQoFBAICBwYSBKABAhsKDQoFBAICBwESBKAB
HC0KDQoFBAICBwMSBKABMDEKDQoFBAICBwgSBKABMl0KEAoIBAICBwicCAASBKABM1wKTQoE
BAICCBIEowECXxo/IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgbmV4dCBwYXRjaCBqb2Ig
aXMgc2NoZWR1bGVkIHRvIHJ1bi4KCg0KBQQCAggGEgSjAQIbCg0KBQQCAggBEgSjARwtCg0K
BQQCAggDEgSjATAyCg0KBQQCAggIEgSjATNeChAKCAQCAggInAgAEgSjATRdCi0KAgQDEgan
AQCqAQEaHyBSZXByZXNlbnRzIGEgd2Vla2x5IHNjaGVkdWxlLgoKCwoDBAMBEgSnAQgWCioK
BAQDAgASBKkBAlEaHCBSZXF1aXJlZC4gRGF5IG9mIHRoZSB3ZWVrLgoKDQoFBAMCAAYSBKkB
AhcKDQoFBAMCAAESBKkBGCMKDQoFBAMCAAMSBKkBJicKDQoFBAMCAAgSBKkBKFAKEAoIBAMC
AAicCAASBKkBKU8KnQEKAgQEEgauAQC6AQEajgEgUmVwcmVzZW50cyBhIG1vbnRobHkgc2No
ZWR1bGUuIEFuIGV4YW1wbGUgb2YgYSB2YWxpZCBtb250aGx5IHNjaGVkdWxlIGlzCiAib24g
dGhlIHRoaXJkIFR1ZXNkYXkgb2YgdGhlIG1vbnRoIiBvciAib24gdGhlIDE1dGggb2YgdGhl
IG1vbnRoIi4KCgsKAwQEARIErgEIFwolCgQEBAgAEgawAQK5AQMaFSBPbmUgZGF5IGluIGEg
bW9udGguCgoNCgUEBAgAARIEsAEIFAouCgQEBAIAEgSyAQRSGiAgUmVxdWlyZWQuIFdlZWsg
ZGF5IGluIGEgbW9udGguCgoNCgUEBAIABhIEsgEEEgoNCgUEBAIAARIEsgETJAoNCgUEBAIA
AxIEsgEnKAoNCgUEBAIACBIEsgEpUQoQCggEBAIACJwIABIEsgEqUAqXAgoEBAQCARIEuAEE
QRqIAiBSZXF1aXJlZC4gT25lIGRheSBvZiB0aGUgbW9udGguIDEtMzEgaW5kaWNhdGVzIHRo
ZSAxc3QgdG8gdGhlIDMxc3QgZGF5LiAtMQogaW5kaWNhdGVzIHRoZSBsYXN0IGRheSBvZiB0
aGUgbW9udGguCiBNb250aHMgd2l0aG91dCB0aGUgdGFyZ2V0IGRheSB3aWxsIGJlIHNraXBw
ZWQuIEZvciBleGFtcGxlLCBhIHNjaGVkdWxlIHRvCiBydW4gImV2ZXJ5IG1vbnRoIG9uIHRo
ZSAzMXN0IiB3aWxsIG5vdCBydW4gaW4gRmVicnVhcnksIEFwcmlsLCBKdW5lLCBldGMuCgoN
CgUEBAIBBRIEuAEECQoNCgUEBAIBARIEuAEKEwoNCgUEBAIBAxIEuAEWFwoNCgUEBAIBCBIE
uAEYQAoQCggEBAIBCJwIABIEuAEZPwpTCgIEBRIGvQEAzQEBGkUgUmVwcmVzZW50cyBvbmUg
d2VlayBkYXkgaW4gYSBtb250aC4gQW4gZXhhbXBsZSBpcyAidGhlIDR0aCBTdW5kYXkiLgoK
CwoDBAUBEgS9AQgWCosBCgQEBQIAEgTAAQJCGn0gUmVxdWlyZWQuIFdlZWsgbnVtYmVyIGlu
IGEgbW9udGguIDEtNCBpbmRpY2F0ZXMgdGhlIDFzdCB0byA0dGggd2VlayBvZiB0aGUgbW9u
dGguIC0xCiBpbmRpY2F0ZXMgdGhlIGxhc3Qgd2VlayBvZiB0aGUgbW9udGguCgoNCgUEBQIA
BRIEwAECBwoNCgUEBQIAARIEwAEIFAoNCgUEBQIAAxIEwAEXGAoNCgUEBQIACBIEwAEZQQoQ
CggEBQIACJwIABIEwAEaQAosCgQEBQIBEgTDAQJRGh4gUmVxdWlyZWQuIEEgZGF5IG9mIHRo
ZSB3ZWVrLgoKDQoFBAUCAQYSBMMBAhcKDQoFBAUCAQESBMMBGCMKDQoFBAUCAQMSBMMBJicK
DQoFBAUCAQgSBMMBKFAKEAoIBAUCAQicCAASBMMBKU8KlwQKBAQFAgISBMwBAkAaiAQgT3B0
aW9uYWwuIFJlcHJlc2VudHMgdGhlIG51bWJlciBvZiBkYXlzIGJlZm9yZSBvciBhZnRlciB0
aGUgZ2l2ZW4gd2VlayBkYXkgb2YgbW9udGgKIHRoYXQgdGhlIHBhdGNoIGRlcGxveW1lbnQg
aXMgc2NoZWR1bGVkIGZvci4gRm9yIGV4YW1wbGUgaWYgYHdlZWtfb3JkaW5hbGAKIGFuZCBg
ZGF5X29mX3dlZWtgIHZhbHVlcyBwb2ludCB0byB0aGUgc2Vjb25kIGRheSBvZiB0aGUgbW9u
dGggYW5kIHRoaXMKIGBkYXlfb2Zmc2V0YCB2YWx1ZSBpcyBzZXQgdG8gYDNgLCB0aGUgcGF0
Y2ggZGVwbG95bWVudCB0YWtlcyBwbGFjZSB0aHJlZQogZGF5cyBhZnRlciB0aGUgc2Vjb25k
IFR1ZXNkYXkgb2YgdGhlIG1vbnRoLiBJZiB0aGlzIHZhbHVlIGlzIG5lZ2F0aXZlLCBmb3IK
IGV4YW1wbGUgLTUsIHRoZSBwYXRjaGVzICBhcmUgZGVwbG95ZWQgZml2ZSBkYXlzIGJlZm9y
ZSBiZWZvcmUgdGhlIHNlY29uZAogVHVlc2RheSBvZiB0aGUgbW9udGguIEFsbG93ZWQgdmFs
dWVzIGFyZSBpbiByYW5nZSBgWy0zMCwgMzBdYC4KCg0KBQQFAgIFEgTMAQIHCg0KBQQFAgIB
EgTMAQgSCg0KBQQFAgIDEgTMARUWCg0KBQQFAgIIEgTMARc/ChAKCAQFAgIInAgAEgTMARg+
CkIKAgQGEgbQAQDfAQEaNCBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBwYXRj
aCBkZXBsb3ltZW50LgoKCwoDBAYBEgTQAQgkCmEKBAQGAgASBNIBAj0aUyBSZXF1aXJlZC4g
VGhlIHByb2plY3QgdG8gYXBwbHkgdGhpcyBwYXRjaCBkZXBsb3ltZW50IHRvIGluIHRoZSBm
b3JtIGBwcm9qZWN0cy8qYC4KCg0KBQQGAgAFEgTSAQIICg0KBQQGAgABEgTSAQkPCg0KBQQG
AgADEgTSARITCg0KBQQGAgAIEgTSARQ8ChAKCAQGAgAInAgAEgTSARU7CscCCgQEBgIBEgTb
AQJKGrgCIFJlcXVpcmVkLiBBIG5hbWUgZm9yIHRoZSBwYXRjaCBkZXBsb3ltZW50IGluIHRo
ZSBwcm9qZWN0LiBXaGVuIGNyZWF0aW5nIGEgbmFtZQogdGhlIGZvbGxvd2luZyBydWxlcyBh
cHBseToKICogTXVzdCBjb250YWluIG9ubHkgbG93ZXJjYXNlIGxldHRlcnMsIG51bWJlcnMs
IGFuZCBoeXBoZW5zLgogKiBNdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCiAqIE11c3QgYmUg
YmV0d2VlbiAxLTYzIGNoYXJhY3RlcnMuCiAqIE11c3QgZW5kIHdpdGggYSBudW1iZXIgb3Ig
YSBsZXR0ZXIuCiAqIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgcHJvamVjdC4KCg0KBQQG
AgEFEgTbAQIICg0KBQQGAgEBEgTbAQkcCg0KBQQGAgEDEgTbAR8gCg0KBQQGAgEIEgTbASFJ
ChAKCAQGAgEInAgAEgTbASJICjkKBAQGAgISBN4BAlAaKyBSZXF1aXJlZC4gVGhlIHBhdGNo
IGRlcGxveW1lbnQgdG8gY3JlYXRlLgoKDQoFBAYCAgYSBN4BAhEKDQoFBAYCAgESBN4BEiIK
DQoFBAYCAgMSBN4BJSYKDQoFBAYCAggSBN4BJ08KEAoIBAYCAgicCAASBN4BKE4KRAoCBAcS
BuIBAOYBARo2IEEgcmVxdWVzdCBtZXNzYWdlIGZvciByZXRyaWV2aW5nIGEgcGF0Y2ggZGVw
bG95bWVudC4KCgsKAwQHARIE4gEIIQpxCgQEBwIAEgTlAQI7GmMgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXRjaCBkZXBsb3ltZW50IGluIHRoZSBmb3JtCiBgcHJv
amVjdHMvKi9wYXRjaERlcGxveW1lbnRzLypgLgoKDQoFBAcCAAUSBOUBAggKDQoFBAcCAAES
BOUBCQ0KDQoFBAcCAAMSBOUBEBEKDQoFBAcCAAgSBOUBEjoKEAoIBAcCAAicCAASBOUBEzkK
QAoCBAgSBukBAPMBARoyIEEgcmVxdWVzdCBtZXNzYWdlIGZvciBsaXN0aW5nIHBhdGNoIGRl
cGxveW1lbnRzLgoKCwoDBAgBEgTpAQgjClMKBAQIAgASBOsBAj0aRSBSZXF1aXJlZC4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBpbiB0aGUgZm9ybSBgcHJvamVjdHMvKmAu
CgoNCgUECAIABRIE6wECCAoNCgUECAIAARIE6wEJDwoNCgUECAIAAxIE6wESEwoNCgUECAIA
CBIE6wEUPAoQCggECAIACJwIABIE6wEVOwpcCgQECAIBEgTuAQI/Gk4gT3B0aW9uYWwuIFRo
ZSBtYXhpbXVtIG51bWJlciBvZiBwYXRjaCBkZXBsb3ltZW50cyB0byByZXR1cm4uIERlZmF1
bHQgaXMgMTAwLgoKDQoFBAgCAQUSBO4BAgcKDQoFBAgCAQESBO4BCBEKDQoFBAgCAQMSBO4B
FBUKDQoFBAgCAQgSBO4BFj4KEAoIBAgCAQicCAASBO4BFz0KnAEKBAQIAgISBPIBAkEajQEg
T3B0aW9uYWwuIEEgcGFnaW5hdGlvbiB0b2tlbiByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMg
Y2FsbCB0byBMaXN0UGF0Y2hEZXBsb3ltZW50cwogdGhhdCBpbmRpY2F0ZXMgd2hlcmUgdGhp
cyBsaXN0aW5nIHNob3VsZCBjb250aW51ZSBmcm9tLgoKDQoFBAgCAgUSBPIBAggKDQoFBAgC
AgESBPIBCRMKDQoFBAgCAgMSBPIBFhcKDQoFBAgCAggSBPIBGEAKEAoIBAgCAgicCAASBPIB
GT8KQQoCBAkSBvYBAP0BARozIEEgcmVzcG9uc2UgbWVzc2FnZSBmb3IgbGlzdGluZyBwYXRj
aCBkZXBsb3ltZW50cy4KCgsKAwQJARIE9gEIJAouCgQECQIAEgT4AQIxGiAgVGhlIGxpc3Qg
b2YgcGF0Y2ggZGVwbG95bWVudHMuCgoNCgUECQIABBIE+AECCgoNCgUECQIABhIE+AELGgoN
CgUECQIAARIE+AEbLAoNCgUECQIAAxIE+AEvMApfCgQECQIBEgT8AQIdGlEgQSBwYWdpbmF0
aW9uIHRva2VuIHRoYXQgY2FuIGJlIHVzZWQgdG8gZ2V0IHRoZSBuZXh0IHBhZ2Ugb2YgcGF0
Y2gKIGRlcGxveW1lbnRzLgoKDQoFBAkCAQUSBPwBAggKDQoFBAkCAQESBPwBCRgKDQoFBAkC
AQMSBPwBGxwKQgoCBAoSBoACAIQCARo0IEEgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGlu
ZyBhIHBhdGNoIGRlcGxveW1lbnQuCgoLCgMECgESBIACCCQKcQoEBAoCABIEgwICOxpjIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcGF0Y2ggZGVwbG95bWVudCBpbiB0
aGUgZm9ybQogYHByb2plY3RzLyovcGF0Y2hEZXBsb3ltZW50cy8qYC4KCg0KBQQKAgAFEgSD
AgIICg0KBQQKAgABEgSDAgkNCg0KBQQKAgADEgSDAhARCg0KBQQKAgAIEgSDAhI6ChAKCAQK
AgAInAgAEgSDAhM5CkIKAgQLEgaHAgCOAgEaNCBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgdXBk
YXRpbmcgYSBwYXRjaCBkZXBsb3ltZW50LgoKCwoDBAsBEgSHAggkCjkKBAQLAgASBIkCAlAa
KyBSZXF1aXJlZC4gVGhlIHBhdGNoIGRlcGxveW1lbnQgdG8gVXBkYXRlLgoKDQoFBAsCAAYS
BIkCAhEKDQoFBAsCAAESBIkCEiIKDQoFBAsCAAMSBIkCJSYKDQoFBAsCAAgSBIkCJ08KEAoI
BAsCAAicCAASBIkCKE4KawoEBAsCARIEjQICVRpdIE9wdGlvbmFsLiBGaWVsZCBtYXNrIHRo
YXQgY29udHJvbHMgd2hpY2ggZmllbGRzIG9mIHRoZSBwYXRjaCBkZXBsb3ltZW50IHNob3Vs
ZCBiZQogdXBkYXRlZC4KCg0KBQQLAgEGEgSNAgIbCg0KBQQLAgEBEgSNAhwnCg0KBQQLAgED
EgSNAiorCg0KBQQLAgEIEgSNAixUChAKCAQLAgEInAgAEgSNAi1TCkEKAgQMEgaRAgCaAgEa
MyBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgcGF1c2luZyBhIHBhdGNoIGRlcGxveW1lbnQuCgoL
CgMEDAESBJECCCMKcwoEBAwCABIGlAICmQIEGmMgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBwYXRjaCBkZXBsb3ltZW50IGluIHRoZSBmb3JtCiBgcHJvamVjdHMvKi9w
YXRjaERlcGxveW1lbnRzLypgLgoKDQoFBAwCAAUSBJQCAggKDQoFBAwCAAESBJQCCQ0KDQoF
BAwCAAMSBJQCEBEKDwoFBAwCAAgSBpQCEpkCAwoQCggEDAIACJwIABIElQIEKgoRCgcEDAIA
CJ8IEgaWAgSYAgUKQgoCBA0SBp0CAKYCARo0IEEgcmVxdWVzdCBtZXNzYWdlIGZvciByZXN1
bWluZyBhIHBhdGNoIGRlcGxveW1lbnQuCgoLCgMEDQESBJ0CCCQKcwoEBA0CABIGoAICpQIE
GmMgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXRjaCBkZXBsb3ltZW50
IGluIHRoZSBmb3JtCiBgcHJvamVjdHMvKi9wYXRjaERlcGxveW1lbnRzLypgLgoKDQoFBA0C
AAUSBKACAggKDQoFBA0CAAESBKACCQ0KDQoFBA0CAAMSBKACEBEKDwoFBA0CAAgSBqACEqUC
AwoQCggEDQIACJwIABIEoQIEKgoRCgcEDQIACJ8IEgaiAgSkAgViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment ===
    # Fields for PatchDeployment
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: instance_filter Type: 11 (.google.cloud.osconfig.v1beta.PatchInstanceFilter)
    # Field: patch_config Type: 11 (.google.cloud.osconfig.v1beta.PatchConfig)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: one_time_schedule Type: 11 (.google.cloud.osconfig.v1beta.OneTimeSchedule)
    # Field: recurring_schedule Type: 11 (.google.cloud.osconfig.v1beta.RecurringSchedule)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_execute_time Type: 11 (.google.protobuf.Timestamp)
    # Field: rollout Type: 11 (.google.cloud.osconfig.v1beta.PatchRollout)
    # Field: state Type: 14 (.google.cloud.osconfig.v1beta.PatchDeployment.State)

# Enum: PatchDeployment::State
our $PatchDeployment_STATE_UNSPECIFIED = 0;
our $PatchDeployment_ACTIVE = 1;
our $PatchDeployment_PAUSED = 2;

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::OneTimeSchedule ===
    # Fields for OneTimeSchedule
    # Field: execute_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::RecurringSchedule ===
    # Fields for RecurringSchedule
    # Field: time_zone Type: 11 (.google.type.TimeZone)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: time_of_day Type: 11 (.google.type.TimeOfDay)
    # Field: frequency Type: 14 (.google.cloud.osconfig.v1beta.RecurringSchedule.Frequency)
    # Field: weekly Type: 11 (.google.cloud.osconfig.v1beta.WeeklySchedule)
    # Field: monthly Type: 11 (.google.cloud.osconfig.v1beta.MonthlySchedule)
    # Field: last_execute_time Type: 11 (.google.protobuf.Timestamp)
    # Field: next_execute_time Type: 11 (.google.protobuf.Timestamp)

# Enum: RecurringSchedule::Frequency
our $RecurringSchedule_FREQUENCY_UNSPECIFIED = 0;
our $RecurringSchedule_WEEKLY = 1;
our $RecurringSchedule_MONTHLY = 2;
our $RecurringSchedule_DAILY = 3;

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::WeeklySchedule ===
    # Fields for WeeklySchedule
    # Field: day_of_week Type: 14 (.google.type.DayOfWeek)

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::MonthlySchedule ===
    # Fields for MonthlySchedule
    # Field: week_day_of_month Type: 11 (.google.cloud.osconfig.v1beta.WeekDayOfMonth)
    # Field: month_day Type: 5 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::WeekDayOfMonth ===
    # Fields for WeekDayOfMonth
    # Field: week_ordinal Type: 5 ()
    # Field: day_of_week Type: 14 (.google.type.DayOfWeek)
    # Field: day_offset Type: 5 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::CreatePatchDeploymentRequest ===
    # Fields for CreatePatchDeploymentRequest
    # Field: parent Type: 9 ()
    # Field: patch_deployment_id Type: 9 ()
    # Field: patch_deployment Type: 11 (.google.cloud.osconfig.v1beta.PatchDeployment)

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::GetPatchDeploymentRequest ===
    # Fields for GetPatchDeploymentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::ListPatchDeploymentsRequest ===
    # Fields for ListPatchDeploymentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::ListPatchDeploymentsResponse ===
    # Fields for ListPatchDeploymentsResponse
    # Field: patch_deployments Type: 11 (.google.cloud.osconfig.v1beta.PatchDeployment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::DeletePatchDeploymentRequest ===
    # Fields for DeletePatchDeploymentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::UpdatePatchDeploymentRequest ===
    # Fields for UpdatePatchDeploymentRequest
    # Field: patch_deployment Type: 11 (.google.cloud.osconfig.v1beta.PatchDeployment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::PausePatchDeploymentRequest ===
    # Fields for PausePatchDeploymentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Osconfig::V1beta::PatchDeployments::ResumePatchDeploymentRequest ===
    # Fields for ResumePatchDeploymentRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1beta::PatchDeployments - Compiled Protocol Buffers messages for google/cloud/osconfig/v1beta/patch_deployments.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1beta::PatchDeployments;

    my $msg = Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment->new({
        name => $name,
        description => $description,
        instance_filter => $instance_filter,
        patch_config => $patch_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1beta/patch_deployments.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment

Patch deployments are configurations that individual patch jobs use to
complete a patch. These configurations include instance filter, package
repository settings, and a schedule. For more information about creating and
managing patch deployments, see [Scheduling patch
jobs](https://cloud.google.com/compute/docs/os-patch-management/schedule-patch-jobs).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Unique name for the patch deployment resource in a project. The patch
deployment name is in the form:
`projects/{project_id}/patchDeployments/{patch_deployment_id}`.
This field is ignored when you create a new patch deployment.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the patch deployment. Length of the description is limited
to 1024 characters.

=item * C<< $msg->instance_filter() >> / C<< $msg->instance_filter($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter>)

Required. VM instances to patch.

=item * C<< $msg->patch_config() >> / C<< $msg->patch_config($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchJobs::PatchConfig>)

Optional. Patch configuration that is applied.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Duration of the patch. After the duration ends, the patch times out.

=item * C<< $msg->one_time_schedule() >> / C<< $msg->one_time_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::OneTimeSchedule>)

Required. Schedule a one-time execution.

=item * C<< $msg->recurring_schedule() >> / C<< $msg->recurring_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::RecurringSchedule>)

Required. Schedule recurring executions.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the patch deployment was created. Timestamp is in
[RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the patch deployment was last updated. Timestamp is in
[RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.

=item * C<< $msg->last_execute_time() >> / C<< $msg->last_execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time a patch job was started by this deployment.
Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text
format.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchJobs::PatchRollout>)

Optional. Rollout strategy of the patch job.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1beta::PatchDeployment::State>)

Output only. Current state of the patch deployment.

=back

=head3 Enum: PatchDeployment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<PAUSED> => C<2>

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::OneTimeSchedule

Sets the time for a one time patch deployment. Timestamp is in
[RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->execute_time() >> / C<< $msg->execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The desired patch job execution time.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::RecurringSchedule

Sets the time for recurring patch deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<Message> (L<Google::Type::Datetime::TimeZone>)

Required. Defines the time zone that `time_of_day` is relative to.
The rules for daylight saving time are determined by the chosen time zone.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The time that the recurring schedule becomes effective.
Defaults to `create_time` of the patch deployment.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The end time at which a recurring patch deployment schedule is no longer
active.

=item * C<< $msg->time_of_day() >> / C<< $msg->time_of_day($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

Required. Time of the day to run a recurring deployment.

=item * C<< $msg->frequency() >> / C<< $msg->frequency($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1beta::RecurringSchedule::Frequency>)

Required. The frequency unit of this recurring schedule.

=item * C<< $msg->weekly() >> / C<< $msg->weekly($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::WeeklySchedule>)

Required. Schedule with weekly executions.

=item * C<< $msg->monthly() >> / C<< $msg->monthly($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::MonthlySchedule>)

Required. Schedule with monthly executions.

=item * C<< $msg->last_execute_time() >> / C<< $msg->last_execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the last patch job ran successfully.

=item * C<< $msg->next_execute_time() >> / C<< $msg->next_execute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the next patch job is scheduled to run.

=back

=head3 Enum: RecurringSchedule::Frequency

=over 4

=item * C<FREQUENCY_UNSPECIFIED> => C<0>

=item * C<WEEKLY> => C<1>

=item * C<MONTHLY> => C<2>

=item * C<DAILY> => C<3>

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::WeeklySchedule

Represents a weekly schedule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->day_of_week() >> / C<< $msg->day_of_week($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Required. Day of the week.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::MonthlySchedule

Represents a monthly schedule. An example of a valid monthly schedule is
"on the third Tuesday of the month" or "on the 15th of the month".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->week_day_of_month() >> / C<< $msg->week_day_of_month($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::WeekDayOfMonth>)

Required. Week day in a month.

=item * C<< $msg->month_day() >> / C<< $msg->month_day($value) >>

Type: C<Int32>

Required. One day of the month. 1-31 indicates the 1st to the 31st day. -1
indicates the last day of the month.
Months without the target day will be skipped. For example, a schedule to
run "every month on the 31st" will not run in February, April, June, etc.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::WeekDayOfMonth

Represents one week day in a month. An example is "the 4th Sunday".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->week_ordinal() >> / C<< $msg->week_ordinal($value) >>

Type: C<Int32>

Required. Week number in a month. 1-4 indicates the 1st to 4th week of the month. -1
indicates the last week of the month.

=item * C<< $msg->day_of_week() >> / C<< $msg->day_of_week($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Required. A day of the week.

=item * C<< $msg->day_offset() >> / C<< $msg->day_offset($value) >>

Type: C<Int32>

Optional. Represents the number of days before or after the given week day of month
that the patch deployment is scheduled for. For example if `week_ordinal`
and `day_of_week` values point to the second day of the month and this
`day_offset` value is set to `3`, the patch deployment takes place three
days after the second Tuesday of the month. If this value is negative, for
example -5, the patches  are deployed five days before before the second
Tuesday of the month. Allowed values are in range `[-30, 30]`.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::CreatePatchDeploymentRequest

A request message for creating a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to apply this patch deployment to in the form `projects/*`.

=item * C<< $msg->patch_deployment_id() >> / C<< $msg->patch_deployment_id($value) >>

Type: C<String>

Required. A name for the patch deployment in the project. When creating a name
the following rules apply:
* Must contain only lowercase letters, numbers, and hyphens.
* Must start with a letter.
* Must be between 1-63 characters.
* Must end with a number or a letter.
* Must be unique within the project.

=item * C<< $msg->patch_deployment() >> / C<< $msg->patch_deployment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment>)

Required. The patch deployment to create.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::GetPatchDeploymentRequest

A request message for retrieving a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::ListPatchDeploymentsRequest

A request message for listing patch deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the parent in the form `projects/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of patch deployments to return. Default is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to ListPatchDeployments
that indicates where this listing should continue from.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::ListPatchDeploymentsResponse

A response message for listing patch deployments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->patch_deployments() >> / C<< $msg->patch_deployments($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment>)

The list of patch deployments.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token that can be used to get the next page of patch
deployments.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::DeletePatchDeploymentRequest

A request message for deleting a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::UpdatePatchDeploymentRequest

A request message for updating a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->patch_deployment() >> / C<< $msg->patch_deployment($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1beta::PatchDeployments::PatchDeployment>)

Required. The patch deployment to Update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask that controls which fields of the patch deployment should be
updated.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::PausePatchDeploymentRequest

A request message for pausing a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head2 Google::Cloud::Osconfig::V1beta::PatchDeployments::ResumePatchDeploymentRequest

A request message for resuming a patch deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the patch deployment in the form
`projects/*/patchDeployments/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1beta::PatchDeployments::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
