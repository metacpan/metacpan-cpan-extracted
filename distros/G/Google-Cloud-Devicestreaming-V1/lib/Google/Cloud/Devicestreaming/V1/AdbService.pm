package Google::Cloud::Devicestreaming::V1::AdbService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGV2aWNlc3RyZWFtaW5nL3YxL2FkYl9zZXJ2aWNlLnByb3RvEh9n
b29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvIpcCCg1EZXZpY2VNZXNzYWdlElQKDXN0YXR1c191cGRhdGUYASABKAsyLS5n
b29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLlN0YXR1c1VwZGF0ZUgAUgxzdGF0dXNV
cGRhdGUSVAoNc3RyZWFtX3N0YXR1cxgCIAEoCzItLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJl
YW1pbmcudjEuU3RyZWFtU3RhdHVzSABSDHN0cmVhbVN0YXR1cxJOCgtzdHJlYW1fZGF0YRgD
IAEoCzIrLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuU3RyZWFtRGF0YUgAUgpz
dHJlYW1EYXRhQgoKCGNvbnRlbnRzIqUBCgpBZGJNZXNzYWdlEjsKBG9wZW4YASABKAsyJS5n
b29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLk9wZW5IAFIEb3BlbhJOCgtzdHJlYW1f
ZGF0YRgCIAEoCzIrLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuU3RyZWFtRGF0
YUgAUgpzdHJlYW1EYXRhQgoKCGNvbnRlbnRzIsgDCgxTdGF0dXNVcGRhdGUSTwoFc3RhdGUY
ASABKA4yOS5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLlN0YXR1c1VwZGF0ZS5E
ZXZpY2VTdGF0ZVIFc3RhdGUSXQoKcHJvcGVydGllcxgCIAMoCzI9Lmdvb2dsZS5jbG91ZC5k
ZXZpY2VzdHJlYW1pbmcudjEuU3RhdHVzVXBkYXRlLlByb3BlcnRpZXNFbnRyeVIKcHJvcGVy
dGllcxIaCghmZWF0dXJlcxgDIAEoCVIIZmVhdHVyZXMaPQoPUHJvcGVydGllc0VudHJ5EhAK
A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEirAEKC0RldmljZVN0
YXRlEhwKGERFVklDRV9TVEFURV9VTlNQRUNJRklFRBAAEgoKBkRFVklDRRABEgwKCFJFQ09W
RVJZEAISCgoGUkVTQ1VFEAMSDAoIU0lERUxPQUQQBBILCgdNSVNTSU5HEAoSCwoHT0ZGTElO
RRALEhAKDFVOQVVUSE9SSVpFRBAMEg8KC0FVVEhPUklaSU5HEA0SDgoKQ09OTkVDVElORxAO
Iq8BCgxTdHJlYW1TdGF0dXMSGwoJc3RyZWFtX2lkGAEgASgFUghzdHJlYW1JZBI7CgRva2F5
GAIgASgLMiUuZ29vZ2xlLmNsb3VkLmRldmljZXN0cmVhbWluZy52MS5Pa2F5SABSBG9rYXkS
OwoEZmFpbBgDIAEoCzIlLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuRmFpbEgA
UgRmYWlsQggKBnN0YXR1cyJHCgRPcGVuEiAKCXN0cmVhbV9pZBgBIAEoBUID4EECUghzdHJl
YW1JZBIdCgdzZXJ2aWNlGAIgASgJQgPgQQFSB3NlcnZpY2UikAEKClN0cmVhbURhdGESIAoJ
c3RyZWFtX2lkGAEgASgFQgPgQQJSCHN0cmVhbUlkEhQKBGRhdGEYAiABKAxIAFIEZGF0YRI+
CgVjbG9zZRgDIAEoCzImLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuQ2xvc2VI
AFIFY2xvc2VCCgoIY29udGVudHMiBgoET2theSIeCgRGYWlsEhYKBnJlYXNvbhgBIAEoCVIG
cmVhc29uIgcKBUNsb3NlQvABCiNjb20uZ29vZ2xlLmNsb3VkLmRldmljZXN0cmVhbWluZy52
MUIPQWRiU2VydmljZVByb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vZGV2aWNlc3RyZWFt
aW5nL2FwaXYxL2RldmljZXN0cmVhbWluZ3BiO2RldmljZXN0cmVhbWluZ3BiqgIfR29vZ2xl
LkNsb3VkLkRldmljZVN0cmVhbWluZy5WMcoCH0dvb2dsZVxDbG91ZFxEZXZpY2VTdHJlYW1p
bmdcVjHqAiJHb29nbGU6OkNsb3VkOjpEZXZpY2VTdHJlYW1pbmc6OlYxSp0lCgcSBQ4AmgEQ
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMS
ACkKCAoBCBIDFAA8CgkKAgglEgMUADwKCAoBCBIDFQBkCgkKAggLEgMVAGQKCAoBCBIDFgAi
CgkKAggKEgMWACIKCAoBCBIDFwAwCgkKAggIEgMXADAKCAoBCBIDGAA8CgkKAggBEgMYADwK
CAoBCBIDGQA8CgkKAggpEgMZADwKCAoBCBIDGgA7CgkKAggtEgMaADsKzAIKAgQAEgQiAC0B
GiMgQSBtZXNzYWdlIHJldHVybmVkIGZyb20gYSBkZXZpY2UuCjKaAiBBUEktZmFjaW5nIHBy
b3RvIGVxdWl2YWxlbnQgdG8gdGhlIGludGVybmFsIEFEQiBTZXJ2aWNlIHByb3RvLiBJbiBn
ZW5lcmFsLAogdGhpcyBwcm90byBzaG91bGQgYmUgZXF1aXZhbGVudCBvZiB0aGUgbWVzc2Fn
ZXMgZGVmaW5lZCBpbiB0aGUgaW50ZXJuYWwKIEFEQiBEZXZpY2UgRm9yd2FyZGVyLCB3aXRo
IHRoZSBjYXZlYXQgdGhhdCB0aGVzZSBzdXBwb3J0IGEgc2VsZi1zdWZmaWNpZW50CiBBUEks
IHdoaWNoIGlzIHRoZSBiZXN0IHByYWN0aWNlIGF0IHRoZSB0aW1lIG9mIHdyaXRpbmcuCgoK
CgMEAAESAyIIFQoMCgQEAAgAEgQjAiwDCgwKBQQACAABEgMjCBAKNAoEBAACABIDJQQjGicg
SW5mb3JtYXRpb24gYWJvdXQgdGhlIGRldmljZSdzIHN0YXRlLgoKDAoFBAACAAYSAyUEEAoM
CgUEAAIAARIDJREeCgwKBQQAAgADEgMlISIKNgoEBAACARIDKAQjGikgVGhlIHJlc3VsdCBv
ZiBhIGRldmljZSBzdHJlYW0gZnJvbSBBREIuCgoMCgUEAAIBBhIDKAQQCgwKBQQAAgEBEgMo
ER4KDAoFBAACAQMSAyghIgooCgQEAAICEgMrBB8aGyBEYXRhIGZyb20gYW4gb3BlbiBzdHJl
YW0uCgoMCgUEAAICBhIDKwQOCgwKBQQAAgIBEgMrDxoKDAoFBAACAgMSAysdHgopCgIEARIE
MAA4ARodIEEgbWVzc2FnZSB0byBhbiBBREIgc2VydmVyLgoKCgoDBAEBEgMwCBIKDAoEBAEI
ABIEMQI3AwoMCgUEAQgAARIDMQgQCiEKBAQBAgASAzMEEhoUIE9wZW4gYSBuZXcgc3RyZWFt
LgoKDAoFBAECAAYSAzMECAoMCgUEAQIAARIDMwkNCgwKBQQBAgADEgMzEBEKJQoEBAECARID
NgQfGhggU2VuZCBkYXRhIHRvIGEgc3RyZWFtLgoKDAoFBAECAQYSAzYEDgoMCgUEAQIBARID
Ng8aCgwKBQQBAgEDEgM2HR4KVgoCBAISBDsAZQEaSiBBIFN0YXR1c1VwZGF0ZSBtZXNzYWdl
IGdpdmVuIG92ZXIgdGhlIEFEQiBwcm90b2NvbCBmb3IgdGhlIGRldmljZSBzdGF0ZS4KCgoK
AwQCARIDOwgUClIKBAQCBAASBD0CWwMaRCBUaGUgc3RhdGUgZGlzcGxheWVkIHdpdGggdGhl
IEFEQiBEZXZpY2Ugd2hlbiBydW5uaW5nICJhZGIgZGV2aWNlcyIKCgwKBQQCBAABEgM9BxIK
LQoGBAIEAAIAEgM/BCEaHiBUaGUgZGV2aWNlIHN0YXRlIGlzIHVua25vd24uCgoOCgcEAgQA
AgABEgM/BBwKDgoHBAIEAAIAAhIDPx8gCjoKBgQCBAACARIDQgQPGisgVGhlIEFEQiBkZXZp
Y2UgaXMgaW4gdGhlICJkZXZpY2UiIHN0YXR1cy4KCg4KBwQCBAACAQESA0IECgoOCgcEAgQA
AgECEgNCDQ4KPAoGBAIEAAICEgNFBBEaLSBUaGUgQURCIGRldmljZSBpcyBpbiB0aGUgInJl
Y292ZXJ5IiBzdGF0dXMuCgoOCgcEAgQAAgIBEgNFBAwKDgoHBAIEAAICAhIDRQ8QCjoKBgQC
BAACAxIDSAQPGisgVGhlIEFEQiBkZXZpY2UgaXMgaW4gdGhlICJyZXNjdWUiIHN0YXR1cy4K
Cg4KBwQCBAACAwESA0gECgoOCgcEAgQAAgMCEgNIDQ4KPAoGBAIEAAIEEgNLBBEaLSBUaGUg
QURCIGRldmljZSBpcyBpbiB0aGUgInNpZGVsb2FkIiBzdGF0dXMuCgoOCgcEAgQAAgQBEgNL
BAwKDgoHBAIEAAIEAhIDSw8QCjsKBgQCBAACBRIDTgQRGiwgVGhlIEFEQiBkZXZpY2UgaXMg
aW4gdGhlICJtaXNzaW5nIiBzdGF0dXMuCgoOCgcEAgQAAgUBEgNOBAsKDgoHBAIEAAIFAhID
Tg4QCjsKBgQCBAACBhIDUQQRGiwgVGhlIEFEQiBkZXZpY2UgaXMgaW4gdGhlICJvZmZsaW5l
IiBzdGF0dXMuCgoOCgcEAgQAAgYBEgNRBAsKDgoHBAIEAAIGAhIDUQ4QCkAKBgQCBAACBxID
VAQWGjEgVGhlIEFEQiBkZXZpY2UgaXMgaW4gdGhlICJ1bmF1dGhvcml6ZWQiIHN0YXR1cy4K
Cg4KBwQCBAACBwESA1QEEAoOCgcEAgQAAgcCEgNUExUKPwoGBAIEAAIIEgNXBBUaMCBUaGUg
QURCIGRldmljZSBpcyBpbiB0aGUgImF1dGhvcml6aW5nIiBzdGF0dXMuCgoOCgcEAgQAAggB
EgNXBA8KDgoHBAIEAAIIAhIDVxIUCj4KBgQCBAACCRIDWgQUGi8gVGhlIEFEQiBkZXZpY2Ug
aXMgaW4gdGhlICJjb25uZWN0aW5nIiBzdGF0dXMuCgoOCgcEAgQAAgkBEgNaBA4KDgoHBAIE
AAIJAhIDWhETCiEKBAQCAgASA14CGBoUIFRoZSBkZXZpY2UncyBzdGF0ZQoKDAoFBAICAAYS
A14CDQoMCgUEAgIAARIDXg4TCgwKBQQCAgADEgNeFhcKRgoEBAICARIDYQIlGjkgQSBtYXAg
b2YgcHJvcGVydGllcyB3aXRoIGluZm9ybWF0aW9uIGFib3V0IHRoaXMgZGV2aWNlLgoKDAoF
BAICAQYSA2ECFQoMCgUEAgIBARIDYRYgCgwKBQQCAgEDEgNhIyQKTgoEBAICAhIDZAIWGkEg
QSBjb21tYS1zZXBhcmF0ZWQgbGlzdCBvZiAiZmVhdHVyZXMiIHRoYXQgdGhpcyBkZXZpY2Ug
c3VwcG9ydHMuCgoMCgUEAgICBRIDZAIICgwKBQQCAgIBEgNkCREKDAoFBAICAgMSA2QUFQol
CgIEAxIEaAB0ARoZIFRoZSByZXN1bHQgb2YgYSBzdHJlYW0uCgoKCgMEAwESA2gIFApECgQE
AwIAEgNqAhYaNyBUaGUgdW5pcXVlIElEIG9mIHRoaXMgc3RyZWFtLCBhc3NpZ25lZCBieSB0
aGUgY2xpZW50LgoKDAoFBAMCAAUSA2oCBwoMCgUEAwIAARIDaggRCgwKBQQDAgADEgNqFBUK
WgoEBAMIABIEbQJzAxpMIFRoZSByZXN1bHQgb2YgdGhlIHN0cmVhbS4gRWl0aGVyICJPa2F5
IiBmb3Igc3VjY2VzcyBvciAiRmFpbCIgZm9yIGZhaWx1cmUuCgoMCgUEAwgAARIDbQgOCiAK
BAQDAgESA28EEhoTIE9rYXkgZm9yIHN1Y2Nlc3MuCgoMCgUEAwIBBhIDbwQICgwKBQQDAgEB
EgNvCQ0KDAoFBAMCAQMSA28QEQogCgQEAwICEgNyBBIaEyBGYWlsIGZvciBmYWlsdXJlLgoK
DAoFBAMCAgYSA3IECAoMCgUEAwICARIDcgkNCgwKBQQDAgIDEgNyEBEKLwoCBAQSBHcAfgEa
IyBNZXNzYWdlIGZvciBvcGVuaW5nIGEgbmV3IHN0cmVhbS4KCgoKAwQEARIDdwgMCqMBCgQE
BAIAEgN6Aj8alQEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgSUQgdGhhdCB3aWxsIGJlIHVzZWQg
dG8gdGFsayB0byB0aGlzIHN0cmVhbS4gVGhpcwogc2hvdWxkIHByb2JhYmx5IGp1c3QgYmUg
YSBudW1iZXIgdGhhdCBpbmNyZW1lbnRzIGZvciBlYWNoIG5ldyBPcGVuIHJlcXVlc3QuCgoM
CgUEBAIABRIDegIHCgwKBQQEAgABEgN6CBEKDAoFBAQCAAMSA3oUFQoMCgUEBAIACBIDehY+
Cg8KCAQEAgAInAgAEgN6Fz0KQQoEBAQCARIDfQI+GjQgT3B0aW9uYWwuIEFuIEFEQiBzZXJ2
aWNlIHRvIHVzZSBpbiB0aGUgbmV3IHN0cmVhbS4KCgwKBQQEAgEFEgN9AggKDAoFBAQCAQES
A30JEAoMCgUEBAIBAxIDfRMUCgwKBQQEAgEIEgN9FT0KDwoIBAQCAQicCAASA30WPAoiCgIE
BRIGgQEAjgEBGhQgRGF0YSBmb3IgYSBzdHJlYW0uCgoLCgMEBQESBIEBCBIKTwoEBAUCABIE
gwECPxpBIFJlcXVpcmVkLiBUaGUgdW5pcXVlIElEIG9mIHRoaXMgc3RyZWFtLCBhc3NpZ25l
ZCBieSB0aGUgY2xpZW50LgoKDQoFBAUCAAUSBIMBAgcKDQoFBAUCAAESBIMBCBEKDQoFBAUC
AAMSBIMBFBUKDQoFBAUCAAgSBIMBFj4KEAoIBAUCAAicCAASBIMBFz0KZwoEBAUIABIGhwEC
jQEDGlcgVGhlIGRhdGEgb2YgdGhlIHN0cmVhbSwgZWl0aGVyIGJ5dGVzIG9yICJDbG9zZSIs
IGluZGljYXRpbmcgdGhhdCB0aGUgc3RyZWFtCiBpcyBkb25lLgoKDQoFBAUIAAESBIcBCBAK
IwoEBAUCARIEiQEEExoVIERhdGEgaW4gdGhlIHN0cmVhbS4KCg0KBQQFAgEFEgSJAQQJCg0K
BQQFAgEBEgSJAQoOCg0KBQQFAgEDEgSJARESCisKBAQFAgISBIwBBBQaHSBUaGUgc3RyZWFt
IGlzIGNsb3NpbmcuIEVPRi4KCg0KBQQFAgIGEgSMAQQJCg0KBQQFAgIBEgSMAQoPCg0KBQQF
AgIDEgSMARITCjgKAgQGEgSRAQAPGiwgTWVzc2FnZSBzaWduaWZ5aW5nIHRoYXQgdGhlIHN0
cmVhbSBpcyBvcGVuCgoLCgMEBgESBJEBCAwKQQoCBAcSBpQBAJcBARozIE1lc3NhZ2Ugc2ln
bmlmeWluZyB0aGF0IHRoZSBzdHJlYW0gZmFpbGVkIHRvIG9wZW4KCgsKAwQHARIElAEIDAoy
CgQEBwIAEgSWAQIUGiQgQSB1c2VyLWRpc3BsYXlhYmxlIGZhaWx1cmUgcmVhc29uLgoKDQoF
BAcCAAUSBJYBAggKDQoFBAcCAAESBJYBCQ8KDQoFBAcCAAMSBJYBEhMKOAoCBAgSBJoBABAa
LCBNZXNzYWdlIHNpZ25pZnlpbmcgdGhhdCB0aGUgc3RyZWFtIGNsb3NlZC4KCgsKAwQIARIE
mgEIDWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage ===
    # Fields for DeviceMessage
    # Field: status_update Type: 11 (.google.cloud.devicestreaming.v1.StatusUpdate)
    # Field: stream_status Type: 11 (.google.cloud.devicestreaming.v1.StreamStatus)
    # Field: stream_data Type: 11 (.google.cloud.devicestreaming.v1.StreamData)

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::AdbMessage ===
    # Fields for AdbMessage
    # Field: open Type: 11 (.google.cloud.devicestreaming.v1.Open)
    # Field: stream_data Type: 11 (.google.cloud.devicestreaming.v1.StreamData)

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::StatusUpdate ===
    # Fields for StatusUpdate
    # Field: state Type: 14 (.google.cloud.devicestreaming.v1.StatusUpdate.DeviceState)
    # Field: properties Type: 11 (.google.cloud.devicestreaming.v1.StatusUpdate.PropertiesEntry)
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

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::StreamStatus ===
    # Fields for StreamStatus
    # Field: stream_id Type: 5 ()
    # Field: okay Type: 11 (.google.cloud.devicestreaming.v1.Okay)
    # Field: fail Type: 11 (.google.cloud.devicestreaming.v1.Fail)

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::Open ===
    # Fields for Open
    # Field: stream_id Type: 5 ()
    # Field: service Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::StreamData ===
    # Fields for StreamData
    # Field: stream_id Type: 5 ()
    # Field: data Type: 12 ()
    # Field: close Type: 11 (.google.cloud.devicestreaming.v1.Close)

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::Okay ===
    # Fields for Okay

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::Fail ===
    # Fields for Fail
    # Field: reason Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::AdbService::Close ===
    # Fields for Close

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Devicestreaming::V1::AdbService - Compiled Protocol Buffers messages for google/cloud/devicestreaming/v1/adb_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Devicestreaming::V1::AdbService;

    my $msg = Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage->new({
        status_update => $status_update,
        stream_status => $stream_status,
        stream_data => $stream_data,
    });

    # Read or update a field
    my $val = $msg->status_update();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/devicestreaming/v1/adb_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage

A message returned from a device.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status_update() >> / C<< $msg->status_update($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::StatusUpdate>)

Information about the device's state.

=item * C<< $msg->stream_status() >> / C<< $msg->stream_status($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::StreamStatus>)

The result of a device stream from ADB.

=item * C<< $msg->stream_data() >> / C<< $msg->stream_data($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::StreamData>)

Data from an open stream.

=back

=head2 Google::Cloud::Devicestreaming::V1::AdbService::AdbMessage

A message to an ADB server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->open() >> / C<< $msg->open($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::Open>)

Open a new stream.

=item * C<< $msg->stream_data() >> / C<< $msg->stream_data($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::StreamData>)

Send data to a stream.

=back

=head2 Google::Cloud::Devicestreaming::V1::AdbService::StatusUpdate

A StatusUpdate message given over the ADB protocol for the device state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Devicestreaming::V1::StatusUpdate::DeviceState>)

The device's state

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::StatusUpdate::PropertiesEntry>)

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

=head2 Google::Cloud::Devicestreaming::V1::AdbService::StreamStatus

The result of a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Int32>

The unique ID of this stream, assigned by the client.

=item * C<< $msg->okay() >> / C<< $msg->okay($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::Okay>)

Okay for success.

=item * C<< $msg->fail() >> / C<< $msg->fail($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::Fail>)

Fail for failure.

=back

=head2 Google::Cloud::Devicestreaming::V1::AdbService::Open

Message for opening a new stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Int32>

Required. The unique ID that will be used to talk to this stream. This
should probably just be a number that increments for each new Open request.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Optional. An ADB service to use in the new stream.

=back

=head2 Google::Cloud::Devicestreaming::V1::AdbService::StreamData

Data for a stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream_id() >> / C<< $msg->stream_id($value) >>

Type: C<Int32>

Required. The unique ID of this stream, assigned by the client.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

Data in the stream.

=item * C<< $msg->close() >> / C<< $msg->close($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::AdbService::Close>)

The stream is closing. EOF.

=back

=head2 Google::Cloud::Devicestreaming::V1::AdbService::Okay

Message signifying that the stream is open

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Devicestreaming::V1::AdbService::Fail

Message signifying that the stream failed to open

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

A user-displayable failure reason.

=back

=head2 Google::Cloud::Devicestreaming::V1::AdbService::Close

Message signifying that the stream closed.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Devicestreaming::V1::AdbService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
