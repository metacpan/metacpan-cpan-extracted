package Google::Devtools::Testing::V1::AdbService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvZGV2dG9vbHMvdGVzdGluZy92MS9hZGJfc2VydmljZS5wcm90bxIaZ29vZ2xl
LmRldnRvb2xzLnRlc3RpbmcudjEiiAIKDURldmljZU1lc3NhZ2USTwoNc3RhdHVzX3VwZGF0
ZRgBIAEoCzIoLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLlN0YXR1c1VwZGF0ZUgAUgxz
dGF0dXNVcGRhdGUSTwoNc3RyZWFtX3N0YXR1cxgCIAEoCzIoLmdvb2dsZS5kZXZ0b29scy50
ZXN0aW5nLnYxLlN0cmVhbVN0YXR1c0gAUgxzdHJlYW1TdGF0dXMSSQoLc3RyZWFtX2RhdGEY
AyABKAsyJi5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5TdHJlYW1EYXRhSABSCnN0cmVh
bURhdGFCCgoIY29udGVudHMimwEKCkFkYk1lc3NhZ2USNgoEb3BlbhgBIAEoCzIgLmdvb2ds
ZS5kZXZ0b29scy50ZXN0aW5nLnYxLk9wZW5IAFIEb3BlbhJJCgtzdHJlYW1fZGF0YRgCIAEo
CzImLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLlN0cmVhbURhdGFIAFIKc3RyZWFtRGF0
YUIKCghjb250ZW50cyK+AwoMU3RhdHVzVXBkYXRlEkoKBXN0YXRlGAEgASgOMjQuZ29vZ2xl
LmRldnRvb2xzLnRlc3RpbmcudjEuU3RhdHVzVXBkYXRlLkRldmljZVN0YXRlUgVzdGF0ZRJY
Cgpwcm9wZXJ0aWVzGAIgAygLMjguZ29vZ2xlLmRldnRvb2xzLnRlc3RpbmcudjEuU3RhdHVz
VXBkYXRlLlByb3BlcnRpZXNFbnRyeVIKcHJvcGVydGllcxIaCghmZWF0dXJlcxgDIAEoCVII
ZmVhdHVyZXMaPQoPUHJvcGVydGllc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgJUgV2YWx1ZToCOAEirAEKC0RldmljZVN0YXRlEhwKGERFVklDRV9TVEFURV9VTlNQ
RUNJRklFRBAAEgoKBkRFVklDRRABEgwKCFJFQ09WRVJZEAISCgoGUkVTQ1VFEAMSDAoIU0lE
RUxPQUQQBBILCgdNSVNTSU5HEAoSCwoHT0ZGTElORRALEhAKDFVOQVVUSE9SSVpFRBAMEg8K
C0FVVEhPUklaSU5HEA0SDgoKQ09OTkVDVElORxAOIqUBCgxTdHJlYW1TdGF0dXMSGwoJc3Ry
ZWFtX2lkGAEgASgFUghzdHJlYW1JZBI2CgRva2F5GAIgASgLMiAuZ29vZ2xlLmRldnRvb2xz
LnRlc3RpbmcudjEuT2theUgAUgRva2F5EjYKBGZhaWwYAyABKAsyIC5nb29nbGUuZGV2dG9v
bHMudGVzdGluZy52MS5GYWlsSABSBGZhaWxCCAoGc3RhdHVzIj0KBE9wZW4SGwoJc3RyZWFt
X2lkGAEgASgFUghzdHJlYW1JZBIYCgdzZXJ2aWNlGAIgASgJUgdzZXJ2aWNlIoYBCgpTdHJl
YW1EYXRhEhsKCXN0cmVhbV9pZBgBIAEoBVIIc3RyZWFtSWQSFAoEZGF0YRgCIAEoDEgAUgRk
YXRhEjkKBWNsb3NlGAMgASgLMiEuZ29vZ2xlLmRldnRvb2xzLnRlc3RpbmcudjEuQ2xvc2VI
AFIFY2xvc2VCCgoIY29udGVudHMiBgoET2theSIeCgRGYWlsEhYKBnJlYXNvbhgBIAEoCVIG
cmVhc29uIgcKBUNsb3NlQnYKHmNvbS5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MUIPQWRi
U2VydmljZVByb3RvUAFaQWdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMv
ZGV2dG9vbHMvdGVzdGluZy92MTt0ZXN0aW5nStAjCgcSBQ4AlQEQCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCggKAQgSAxIAWAoJCgIICxIDEgBYCggK
AQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQAMAoJCgIICBIDFAAwCggKAQgSAxUANwoJCgII
ARIDFQA3CswCCgIEABIEHQAoARojIEEgbWVzc2FnZSByZXR1cm5lZCBmcm9tIGEgZGV2aWNl
LgoymgIgQVBJLWZhY2luZyBwcm90byBlcXVpdmFsZW50IHRvIHRoZSBpbnRlcm5hbCBBREIg
U2VydmljZSBwcm90by4gSW4gZ2VuZXJhbCwKIHRoaXMgcHJvdG8gc2hvdWxkIGJlIGVxdWl2
YWxlbnQgb2YgdGhlIG1lc3NhZ2VzIGRlZmluZWQgaW4gdGhlIGludGVybmFsCiBBREIgRGV2
aWNlIEZvcndhcmRlciwgd2l0aCB0aGUgY2F2ZWF0IHRoYXQgdGhlc2Ugc3VwcG9ydCBhIHNl
bGYtc3VmZmljaWVudAogQVBJLCB3aGljaCBpcyB0aGUgYmVzdCBwcmFjdGljZSBhdCB0aGUg
dGltZSBvZiB3cml0aW5nLgoKCgoDBAABEgMdCBUKDAoEBAAIABIEHgInAwoMCgUEAAgAARID
HggQCjQKBAQAAgASAyAEIxonIEluZm9ybWF0aW9uIGFib3V0IHRoZSBkZXZpY2UncyBzdGF0
ZS4KCgwKBQQAAgAGEgMgBBAKDAoFBAACAAESAyARHgoMCgUEAAIAAxIDICEiCjYKBAQAAgES
AyMEIxopIFRoZSByZXN1bHQgb2YgYSBkZXZpY2Ugc3RyZWFtIGZyb20gQURCLgoKDAoFBAAC
AQYSAyMEEAoMCgUEAAIBARIDIxEeCgwKBQQAAgEDEgMjISIKKAoEBAACAhIDJgQfGhsgRGF0
YSBmcm9tIGFuIG9wZW4gc3RyZWFtLgoKDAoFBAACAgYSAyYEDgoMCgUEAAICARIDJg8aCgwK
BQQAAgIDEgMmHR4KKQoCBAESBCsAMwEaHSBBIG1lc3NhZ2UgdG8gYW4gQURCIHNlcnZlci4K
CgoKAwQBARIDKwgSCgwKBAQBCAASBCwCMgMKDAoFBAEIAAESAywIEAohCgQEAQIAEgMuBBIa
FCBPcGVuIGEgbmV3IHN0cmVhbS4KCgwKBQQBAgAGEgMuBAgKDAoFBAECAAESAy4JDQoMCgUE
AQIAAxIDLhARCiUKBAQBAgESAzEEHxoYIFNlbmQgZGF0YSB0byBhIHN0cmVhbS4KCgwKBQQB
AgEGEgMxBA4KDAoFBAECAQESAzEPGgoMCgUEAQIBAxIDMR0eClYKAgQCEgQ2AGABGkogQSBT
dGF0dXNVcGRhdGUgbWVzc2FnZSBnaXZlbiBvdmVyIHRoZSBBREIgcHJvdG9jb2wgZm9yIHRo
ZSBkZXZpY2Ugc3RhdGUuCgoKCgMEAgESAzYIFApSCgQEAgQAEgQ4AlYDGkQgVGhlIHN0YXRl
IGRpc3BsYXllZCB3aXRoIHRoZSBBREIgRGV2aWNlIHdoZW4gcnVubmluZyAiYWRiIGRldmlj
ZXMiCgoMCgUEAgQAARIDOAcSCi0KBgQCBAACABIDOgQhGh4gVGhlIGRldmljZSBzdGF0ZSBp
cyB1bmtub3duLgoKDgoHBAIEAAIAARIDOgQcCg4KBwQCBAACAAISAzofIAo6CgYEAgQAAgES
Az0EDxorIFRoZSBBREIgZGV2aWNlIGlzIGluIHRoZSAiZGV2aWNlIiBzdGF0dXMuCgoOCgcE
AgQAAgEBEgM9BAoKDgoHBAIEAAIBAhIDPQ0OCjwKBgQCBAACAhIDQAQRGi0gVGhlIEFEQiBk
ZXZpY2UgaXMgaW4gdGhlICJyZWNvdmVyeSIgc3RhdHVzLgoKDgoHBAIEAAICARIDQAQMCg4K
BwQCBAACAgISA0APEAo6CgYEAgQAAgMSA0MEDxorIFRoZSBBREIgZGV2aWNlIGlzIGluIHRo
ZSAicmVzY3VlIiBzdGF0dXMuCgoOCgcEAgQAAgMBEgNDBAoKDgoHBAIEAAIDAhIDQw0OCjwK
BgQCBAACBBIDRgQRGi0gVGhlIEFEQiBkZXZpY2UgaXMgaW4gdGhlICJzaWRlbG9hZCIgc3Rh
dHVzLgoKDgoHBAIEAAIEARIDRgQMCg4KBwQCBAACBAISA0YPEAo7CgYEAgQAAgUSA0kEERos
IFRoZSBBREIgZGV2aWNlIGlzIGluIHRoZSAibWlzc2luZyIgc3RhdHVzLgoKDgoHBAIEAAIF
ARIDSQQLCg4KBwQCBAACBQISA0kOEAo7CgYEAgQAAgYSA0wEERosIFRoZSBBREIgZGV2aWNl
IGlzIGluIHRoZSAib2ZmbGluZSIgc3RhdHVzLgoKDgoHBAIEAAIGARIDTAQLCg4KBwQCBAAC
BgISA0wOEApACgYEAgQAAgcSA08EFhoxIFRoZSBBREIgZGV2aWNlIGlzIGluIHRoZSAidW5h
dXRob3JpemVkIiBzdGF0dXMuCgoOCgcEAgQAAgcBEgNPBBAKDgoHBAIEAAIHAhIDTxMVCj8K
BgQCBAACCBIDUgQVGjAgVGhlIEFEQiBkZXZpY2UgaXMgaW4gdGhlICJhdXRob3JpemluZyIg
c3RhdHVzLgoKDgoHBAIEAAIIARIDUgQPCg4KBwQCBAACCAISA1ISFAo+CgYEAgQAAgkSA1UE
FBovIFRoZSBBREIgZGV2aWNlIGlzIGluIHRoZSAiY29ubmVjdGluZyIgc3RhdHVzLgoKDgoH
BAIEAAIJARIDVQQOCg4KBwQCBAACCQISA1UREwohCgQEAgIAEgNZAhgaFCBUaGUgZGV2aWNl
J3Mgc3RhdGUKCgwKBQQCAgAGEgNZAg0KDAoFBAICAAESA1kOEwoMCgUEAgIAAxIDWRYXCkYK
BAQCAgESA1wCJRo5IEEgbWFwIG9mIHByb3BlcnRpZXMgd2l0aCBpbmZvcm1hdGlvbiBhYm91
dCB0aGlzIGRldmljZS4KCgwKBQQCAgEGEgNcAhUKDAoFBAICAQESA1wWIAoMCgUEAgIBAxID
XCMkCk4KBAQCAgISA18CFhpBIEEgY29tbWEtc2VwYXJhdGVkIGxpc3Qgb2YgImZlYXR1cmVz
IiB0aGF0IHRoaXMgZGV2aWNlIHN1cHBvcnRzLgoKDAoFBAICAgUSA18CCAoMCgUEAgICARID
XwkRCgwKBQQCAgIDEgNfFBUKJQoCBAMSBGMAbwEaGSBUaGUgcmVzdWx0IG9mIGEgc3RyZWFt
LgoKCgoDBAMBEgNjCBQKRAoEBAMCABIDZQIWGjcgVGhlIHVuaXF1ZSBJRCBvZiB0aGlzIHN0
cmVhbSwgYXNzaWduZWQgYnkgdGhlIGNsaWVudC4KCgwKBQQDAgAFEgNlAgcKDAoFBAMCAAES
A2UIEQoMCgUEAwIAAxIDZRQVCloKBAQDCAASBGgCbgMaTCBUaGUgcmVzdWx0IG9mIHRoZSBz
dHJlYW0uIEVpdGhlciAiT2theSIgZm9yIHN1Y2Nlc3Mgb3IgIkZhaWwiIGZvciBmYWlsdXJl
LgoKDAoFBAMIAAESA2gIDgogCgQEAwIBEgNqBBIaEyBPa2F5IGZvciBzdWNjZXNzLgoKDAoF
BAMCAQYSA2oECAoMCgUEAwIBARIDagkNCgwKBQQDAgEDEgNqEBEKIAoEBAMCAhIDbQQSGhMg
RmFpbCBmb3IgZmFpbHVyZS4KCgwKBQQDAgIGEgNtBAgKDAoFBAMCAgESA20JDQoMCgUEAwIC
AxIDbRARCi8KAgQEEgRyAHkBGiMgTWVzc2FnZSBmb3Igb3BlbmluZyBhIG5ldyBzdHJlYW0u
CgoKCgMEBAESA3IIDAqZAQoEBAQCABIDdQIWGosBIFRoZSB1bmlxdWUgSUQgdGhhdCB3aWxs
IGJlIHVzZWQgdG8gdGFsayB0byB0aGlzIHN0cmVhbS4gVGhpcyBzaG91bGQKIHByb2JhYmx5
IGp1c3QgYmUgYSBudW1iZXIgdGhhdCBpbmNyZW1lbnRzIGZvciBlYWNoIG5ldyBPcGVuIHJl
cXVlc3QuCgoMCgUEBAIABRIDdQIHCgwKBQQEAgABEgN1CBEKDAoFBAQCAAMSA3UUFQo3CgQE
BAIBEgN4AhUaKiBBbiBBREIgc2VydmljZSB0byB1c2UgaW4gdGhlIG5ldyBzdHJlYW0uCgoM
CgUEBAIBBRIDeAIICgwKBQQEAgEBEgN4CRAKDAoFBAQCAQMSA3gTFAohCgIEBRIFfACJAQEa
FCBEYXRhIGZvciBhIHN0cmVhbS4KCgoKAwQFARIDfAgSCkQKBAQFAgASA34CFho3IFRoZSB1
bmlxdWUgSUQgb2YgdGhpcyBzdHJlYW0sIGFzc2lnbmVkIGJ5IHRoZSBjbGllbnQuCgoMCgUE
BQIABRIDfgIHCgwKBQQFAgABEgN+CBEKDAoFBAUCAAMSA34UFQpnCgQEBQgAEgaCAQKIAQMa
VyBUaGUgZGF0YSBvZiB0aGUgc3RyZWFtLCBlaXRoZXIgYnl0ZXMgb3IgIkNsb3NlIiwgaW5k
aWNhdGluZyB0aGF0IHRoZSBzdHJlYW0KIGlzIGRvbmUuCgoNCgUEBQgAARIEggEIEAojCgQE
BQIBEgSEAQQTGhUgRGF0YSBpbiB0aGUgc3RyZWFtLgoKDQoFBAUCAQUSBIQBBAkKDQoFBAUC
AQESBIQBCg4KDQoFBAUCAQMSBIQBERIKKwoEBAUCAhIEhwEEFBodIFRoZSBzdHJlYW0gaXMg
Y2xvc2luZy4gRU9GLgoKDQoFBAUCAgYSBIcBBAkKDQoFBAUCAgESBIcBCg8KDQoFBAUCAgMS
BIcBEhMKOAoCBAYSBIwBAA8aLCBNZXNzYWdlIHNpZ25pZnlpbmcgdGhhdCB0aGUgc3RyZWFt
IGlzIG9wZW4KCgsKAwQGARIEjAEIDApBCgIEBxIGjwEAkgEBGjMgTWVzc2FnZSBzaWduaWZ5
aW5nIHRoYXQgdGhlIHN0cmVhbSBmYWlsZWQgdG8gb3BlbgoKCwoDBAcBEgSPAQgMCjIKBAQH
AgASBJEBAhQaJCBBIHVzZXItZGlzcGxheWFibGUgZmFpbHVyZSByZWFzb24uCgoNCgUEBwIA
BRIEkQECCAoNCgUEBwIAARIEkQEJDwoNCgUEBwIAAxIEkQESEwo4CgIECBIElQEAEBosIE1l
c3NhZ2Ugc2lnbmlmeWluZyB0aGF0IHRoZSBzdHJlYW0gY2xvc2VkLgoKCwoDBAgBEgSVAQgN
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Testing::V1::AdbService::DeviceMessage ===
    # Fields for DeviceMessage
    # Field: status_update Type: 11 (.google.devtools.testing.v1.StatusUpdate)
    # Field: stream_status Type: 11 (.google.devtools.testing.v1.StreamStatus)
    # Field: stream_data Type: 11 (.google.devtools.testing.v1.StreamData)

# === Message: Google::Devtools::Testing::V1::AdbService::AdbMessage ===
    # Fields for AdbMessage
    # Field: open Type: 11 (.google.devtools.testing.v1.Open)
    # Field: stream_data Type: 11 (.google.devtools.testing.v1.StreamData)

# === Message: Google::Devtools::Testing::V1::AdbService::StatusUpdate ===
    # Fields for StatusUpdate
    # Field: state Type: 14 (.google.devtools.testing.v1.StatusUpdate.DeviceState)
    # Field: properties Type: 11 (.google.devtools.testing.v1.StatusUpdate.PropertiesEntry)
    # Field: features Type: 9 ()

# Enum: StatusUpdate::DeviceState
our $StatusUpdate_DEVICE_STATE_UNSPECIFIED = 0;
our $StatusUpdate_DEVICE = 1;
our $StatusUpdate_RECOVERY = 2;
our $StatusUpdate_RESCUE = 3;
our $StatusUpdate_SIDELOAD = 4;
our $StatusUpdate_MISSING = 10;
our $StatusUpdate_OFFLINE = 11;
our $StatusUpdate_UNAUTHORIZED = 12;
our $StatusUpdate_AUTHORIZING = 13;
our $StatusUpdate_CONNECTING = 14;

# === Message: Google::Devtools::Testing::V1::AdbService::StreamStatus ===
    # Fields for StreamStatus
    # Field: stream_id Type: 5 ()
    # Field: okay Type: 11 (.google.devtools.testing.v1.Okay)
    # Field: fail Type: 11 (.google.devtools.testing.v1.Fail)

# === Message: Google::Devtools::Testing::V1::AdbService::Open ===
    # Fields for Open
    # Field: stream_id Type: 5 ()
    # Field: service Type: 9 ()

# === Message: Google::Devtools::Testing::V1::AdbService::StreamData ===
    # Fields for StreamData
    # Field: stream_id Type: 5 ()
    # Field: data Type: 12 ()
    # Field: close Type: 11 (.google.devtools.testing.v1.Close)

# === Message: Google::Devtools::Testing::V1::AdbService::Okay ===
    # Fields for Okay

# === Message: Google::Devtools::Testing::V1::AdbService::Fail ===
    # Fields for Fail
    # Field: reason Type: 9 ()

# === Message: Google::Devtools::Testing::V1::AdbService::Close ===
    # Fields for Close

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Testing::V1::AdbService - Compiled Protocol Buffers messages for google/devtools/testing/v1/adb_service.proto

=head1 SYNOPSIS

    use Google::Devtools::Testing::V1::AdbService;

    my $msg = Google::Devtools::Testing::V1::AdbService::DeviceMessage->new({
        status_update => $status_update,
        stream_status => $stream_status,
        stream_data => $stream_data,
    });

    # Read or update a field
    my $val = $msg->status_update();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Testing::V1::AdbService::DeviceMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/testing/v1/adb_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Testing::V1::AdbService::DeviceMessage

A message returned from a device.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status_update() >> / C<< $msg->status_update($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::StatusUpdate>)

Information about the device's state.

=item * C<< $msg->stream_status() >> / C<< $msg->stream_status($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::StreamStatus>)

The result of a device stream from ADB.

=item * C<< $msg->stream_data() >> / C<< $msg->stream_data($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::StreamData>)

Data from an open stream.

=back

=head2 Google::Devtools::Testing::V1::AdbService::AdbMessage

A message to an ADB server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->open() >> / C<< $msg->open($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::Open>)

Open a new stream.

=item * C<< $msg->stream_data() >> / C<< $msg->stream_data($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::StreamData>)

Send data to a stream.

=back

=head2 Google::Devtools::Testing::V1::AdbService::StatusUpdate

A StatusUpdate message given over the ADB protocol for the device state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Devtools::Testing::V1::StatusUpdate::DeviceState>)

The device's state

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::StatusUpdate::PropertiesEntry>)

A map of properties with information about this device.

=item * C<< $msg->features() >> / C<< $msg->features($value) >>

Type: C<String>

A comma-separated list of "features" that this device supports.

=back

=head3 Enum: StatusUpdate::DeviceState

=over 4

=item * C<DEVICE_STATE_UNSPECIFIED> => C<0>

=item * C<DEVICE> => C<1>

=item * C<RECOVERY> => C<2>

=item * C<RESCUE> => C<3>

=item * C<SIDELOAD> => C<4>

=item * C<MISSING> => C<10>

=item * C<OFFLINE> => C<11>

=item * C<UNAUTHORIZED> => C<12>

=item * C<AUTHORIZING> => C<13>

=item * C<CONNECTING> => C<14>

=back

=head2 Google::Devtools::Testing::V1::AdbService::StreamStatus

The result of a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Int32>

The unique ID of this stream, assigned by the client.

=item * C<< $msg->okay() >> / C<< $msg->okay($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::Okay>)

Okay for success.

=item * C<< $msg->fail() >> / C<< $msg->fail($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::Fail>)

Fail for failure.

=back

=head2 Google::Devtools::Testing::V1::AdbService::Open

Message for opening a new stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Int32>

The unique ID that will be used to talk to this stream. This should
probably just be a number that increments for each new Open request.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

An ADB service to use in the new stream.

=back

=head2 Google::Devtools::Testing::V1::AdbService::StreamData

Data for a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Int32>

The unique ID of this stream, assigned by the client.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

Data in the stream.

=item * C<< $msg->close() >> / C<< $msg->close($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::AdbService::Close>)

The stream is closing. EOF.

=back

=head2 Google::Devtools::Testing::V1::AdbService::Okay

Message signifying that the stream is open

Inherits from L<Protobuf::Message>.

=head2 Google::Devtools::Testing::V1::AdbService::Fail

Message signifying that the stream failed to open

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

A user-displayable failure reason.

=back

=head2 Google::Devtools::Testing::V1::AdbService::Close

Message signifying that the stream closed.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Testing::V1::AdbService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
