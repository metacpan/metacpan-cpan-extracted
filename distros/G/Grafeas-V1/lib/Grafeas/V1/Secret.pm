package Grafeas::V1::Secret;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    eval { require Grafeas::V1::Common };
    my $descriptor_b64 = <<'EOF';
ChdncmFmZWFzL3YxL3NlY3JldC5wcm90bxIKZ3JhZmVhcy52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL3Byb3RvYnVmL2FueS5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ3JhZmVhcy92MS9jb21tb24ucHJvdG8iDAoKU2Vj
cmV0Tm90ZSKTAgoQU2VjcmV0T2NjdXJyZW5jZRIvCgRraW5kGAEgASgOMhYuZ3JhZmVhcy52
MS5TZWNyZXRLaW5kQgPgQQJSBGtpbmQSPQoJbG9jYXRpb25zGAIgAygLMhouZ3JhZmVhcy52
MS5TZWNyZXRMb2NhdGlvbkID4EEBUglsb2NhdGlvbnMSOQoIc3RhdHVzZXMYAyADKAsyGC5n
cmFmZWFzLnYxLlNlY3JldFN0YXR1c0ID4EEBUghzdGF0dXNlcxIoCgRkYXRhGAQgASgLMhQu
Z29vZ2xlLnByb3RvYnVmLkFueVIEZGF0YRIqCgZkaWdlc3QYBSABKAsyEi5ncmFmZWFzLnYx
LkRpZ2VzdFIGZGlnZXN0Il0KDlNlY3JldExvY2F0aW9uEj8KDWZpbGVfbG9jYXRpb24YASAB
KAsyGC5ncmFmZWFzLnYxLkZpbGVMb2NhdGlvbkgAUgxmaWxlTG9jYXRpb25CCgoIbG9jYXRp
b24i9AEKDFNlY3JldFN0YXR1cxI8CgZzdGF0dXMYASABKA4yHy5ncmFmZWFzLnYxLlNlY3Jl
dFN0YXR1cy5TdGF0dXNCA+BBAVIGc3RhdHVzEkAKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUgp1cGRhdGVUaW1lEh0KB21lc3NhZ2UYAyAB
KAlCA+BBAVIHbWVzc2FnZSJFCgZTdGF0dXMSFgoSU1RBVFVTX1VOU1BFQ0lGSUVEEAASCwoH
VU5LTk9XThABEgkKBVZBTElEEAISCwoHSU5WQUxJRBADKqUHCgpTZWNyZXRLaW5kEhsKF1NF
Q1JFVF9LSU5EX1VOU1BFQ0lGSUVEEAASFwoTU0VDUkVUX0tJTkRfVU5LTk9XThABEicKI1NF
Q1JFVF9LSU5EX0dDUF9TRVJWSUNFX0FDQ09VTlRfS0VZEAISGwoXU0VDUkVUX0tJTkRfR0NQ
X0FQSV9LRVkQAxItCilTRUNSRVRfS0lORF9HQ1BfT0FVVEgyX0NMSUVOVF9DUkVERU5USUFM
UxAEEicKI1NFQ1JFVF9LSU5EX0dDUF9PQVVUSDJfQUNDRVNTX1RPS0VOEAUSJwojU0VDUkVU
X0tJTkRfQU5USFJPUElDX0FETUlOX0FQSV9LRVkQBhIhCh1TRUNSRVRfS0lORF9BTlRIUk9Q
SUNfQVBJX0tFWRAHEiIKHlNFQ1JFVF9LSU5EX0FaVVJFX0FDQ0VTU19UT0tFThAIEiQKIFNF
Q1JFVF9LSU5EX0FaVVJFX0lERU5USVRZX1RPS0VOEAkSMAosU0VDUkVUX0tJTkRfRE9DS0VS
X0hVQl9QRVJTT05BTF9BQ0NFU1NfVE9LRU4QChIoCiRTRUNSRVRfS0lORF9HSVRIVUJfQVBQ
X1JFRlJFU0hfVE9LRU4QCxIxCi1TRUNSRVRfS0lORF9HSVRIVUJfQVBQX1NFUlZFUl9UT19T
RVJWRVJfVE9LRU4QDBIvCitTRUNSRVRfS0lORF9HSVRIVUJfQVBQX1VTRVJfVE9fU0VSVkVS
X1RPS0VOEA0SNAowU0VDUkVUX0tJTkRfR0lUSFVCX0NMQVNTSUNfUEVSU09OQUxfQUNDRVNT
X1RPS0VOEA4SOQo1U0VDUkVUX0tJTkRfR0lUSFVCX0ZJTkVfR1JBSU5FRF9QRVJTT05BTF9B
Q0NFU1NfVE9LRU4QDxIiCh5TRUNSRVRfS0lORF9HSVRIVUJfT0FVVEhfVE9LRU4QEBIjCh9T
RUNSRVRfS0lORF9IVUdHSU5HRkFDRV9BUElfS0VZEBESHgoaU0VDUkVUX0tJTkRfT1BFTkFJ
X0FQSV9LRVkQEhIiCh5TRUNSRVRfS0lORF9QRVJQTEVYSVRZX0FQSV9LRVkQExIhCh1TRUNS
RVRfS0lORF9TVFJJUEVfU0VDUkVUX0tFWRAUEiUKIVNFQ1JFVF9LSU5EX1NUUklQRV9SRVNU
UklDVEVEX0tFWRAVEiUKIVNFQ1JFVF9LSU5EX1NUUklQRV9XRUJIT09LX1NFQ1JFVBAWQlEK
DWlvLmdyYWZlYXMudjFQAVo4Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBp
cy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFKtCMKBxIFDgCMAQEK2gQKAQwSAw4AEjLPBCBD
b3B5cmlnaHQgMjAyNSBUaGUgR3JhZmVhcyBBdXRob3JzLiBBbGwgcmlnaHRzIHJlc2VydmVk
LgoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQABMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCQoCAwMSAxUAIQoICgEI
EgMXAE8KCQoCCAsSAxcATwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZACYKCQoCCAES
AxkAJgoICgEIEgMaACEKCQoCCCQSAxoAIQosCgIEABIDHQAVGiEgVGhlIG5vdGUgcmVwcmVz
ZW50aW5nIGEgc2VjcmV0LgoKCgoDBAABEgMdCBIKOgoCBAESBCAAMQEaLiBUaGUgb2NjdXJy
ZW5jZSBwcm92aWRlcyBkZXRhaWxzIG9mIGEgc2VjcmV0LgoKCgoDBAEBEgMgCBgKHgoEBAEC
ABIDIgI/GhEgVHlwZSBvZiBzZWNyZXQuCgoMCgUEAQIABhIDIgIMCgwKBQQBAgABEgMiDREK
DAoFBAECAAMSAyIUFQoMCgUEAQIACBIDIhY+Cg8KCAQBAgAInAgAEgMiFz0KNwoEBAECARIE
JQImLxopIExvY2F0aW9ucyB3aGVyZSB0aGUgc2VjcmV0IGlzIGRldGVjdGVkLgoKDAoFBAEC
AQQSAyUCCgoMCgUEAQIBBhIDJQsZCgwKBQQBAgEBEgMlGiMKDAoFBAECAQMSAyUmJwoMCgUE
AQIBCBIDJgYuCg8KCAQBAgEInAgAEgMmBy0KJAoEBAECAhIDKQJOGhcgU3RhdHVzIG9mIHRo
ZSBzZWNyZXQuCgoMCgUEAQICBBIDKQIKCgwKBQQBAgIGEgMpCxcKDAoFBAECAgESAykYIAoM
CgUEAQICAxIDKSMkCgwKBQQBAgIIEgMpJU0KDwoIBAECAgicCAASAykmTAopCgQEAQIDEgMs
Ah8aHCBTY2FuIHJlc3VsdCBvZiB0aGUgc2VjcmV0LgoKDAoFBAECAwYSAywCFQoMCgUEAQID
ARIDLBYaCgwKBQQBAgMDEgMsHR4KewoEBAECBBIDMAIUGm4gSGFzaCB2YWx1ZSwgdHlwaWNh
bGx5IGEgZGlnZXN0IGZvciB0aGUgc2VjcmV0IGRhdGEsIHRoYXQgYWxsb3dzIHVuaXF1ZQog
aWRlbnRpZmljYXRpb24gb2YgYSBzcGVjaWZpYyBzZWNyZXQuCgoMCgUEAQIEBhIDMAIICgwK
BQQBAgQBEgMwCQ8KDAoFBAECBAMSAzASEwopCgIEAhIENAA6ARodIFRoZSBsb2NhdGlvbiBv
ZiB0aGUgc2VjcmV0LgoKCgoDBAIBEgM0CBYKNAoEBAIIABIENgI5AxomIFRoZSBkZXRhaWxl
ZCBsb2NhdGlvbiBvZiB0aGUgc2VjcmV0LgoKDAoFBAIIAAESAzYIEAovCgQEAgIAEgM4BCMa
IiBUaGUgc2VjcmV0IGlzIGZvdW5kIGZyb20gYSBmaWxlLgoKDAoFBAICAAYSAzgEEAoMCgUE
AgIAARIDOBEeCgwKBQQCAgADEgM4ISIKOAoCBAMSBD0AVgEaLCBUaGUgc3RhdHVzIG9mIHRo
ZSBzZWNyZXQgd2l0aCBhIHRpbWVzdGFtcC4KCgoKAwQDARIDPQgUCikKBAQDBAASBD8CSwMa
GyBUaGUgc3RhdHVzIG9mIHRoZSBzZWNyZXQuCgoMCgUEAwQAARIDPwcNChwKBgQDBAACABID
QQQbGg0gVW5zcGVjaWZpZWQKCg4KBwQDBAACAAESA0EEFgoOCgcEAwQAAgACEgNBGRoKNQoG
BAMEAAIBEgNEBBAaJiBUaGUgc3RhdHVzIG9mIHRoZSBzZWNyZXQgaXMgdW5rbm93bi4KCg4K
BwQDBAACAQESA0QECwoOCgcEAwQAAgECEgNEDg8KJQoGBAMEAAICEgNHBA4aFiBUaGUgc2Vj
cmV0IGlzIHZhbGlkLgoKDgoHBAMEAAICARIDRwQJCg4KBwQDBAACAgISA0cMDQonCgYEAwQA
AgMSA0oEEBoYIFRoZSBzZWNyZXQgaXMgaW52YWxpZC4KCg4KBwQDBAACAwESA0oECwoOCgcE
AwQAAgMCEgNKDg8KKAoEBAMCABIDTgI9GhsgVGhlIHN0YXR1cyBvZiB0aGUgc2VjcmV0LgoK
DAoFBAMCAAYSA04CCAoMCgUEAwIAARIDTgkPCgwKBQQDAgADEgNOEhMKDAoFBAMCAAgSA04U
PAoPCggEAwIACJwIABIDThU7CjwKBAQDAgESBFECUi8aLiBUaGUgdGltZSB0aGUgc2VjcmV0
IHN0YXR1cyB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAMCAQYSA1ECGwoMCgUEAwIBARIDURwn
CgwKBQQDAgEDEgNRKisKDAoFBAMCAQgSA1IGLgoPCggEAwIBCJwIABIDUgctCjYKBAQDAgIS
A1UCPhopIE9wdGlvbmFsIG1lc3NhZ2UgYWJvdXQgdGhlIHN0YXR1cyBjb2RlLgoKDAoFBAMC
AgUSA1UCCAoMCgUEAwICARIDVQkQCgwKBQQDAgIDEgNVExQKDAoFBAMCAggSA1UVPQoPCggE
AwICCJwIABIDVRY8Ch4KAgUAEgVZAIwBARoRIEtpbmQgb2Ygc2VjcmV0LgoKCgoDBQABEgNZ
BQ8KGgoEBQACABIDWwIeGg0gVW5zcGVjaWZpZWQKCgwKBQUAAgABEgNbAhkKDAoFBQACAAIS
A1scHQoqCgQFAAIBEgNdAhoaHSBUaGUgc2VjcmV0IGtpbmQgaXMgdW5rbm93bi4KCgwKBQUA
AgEBEgNdAhUKDAoFBQACAQISA10YGQqAAQoEBQACAhIDYAIqGnMgQSBHb29nbGUgQ2xvdWQg
c2VydmljZSBhY2NvdW50IGtleSBwZXI6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFt
L2RvY3MvY3JlYXRpbmctbWFuYWdpbmctc2VydmljZS1hY2NvdW50LWtleXMKCgwKBQUAAgIB
EgNgAiUKDAoFBQACAgISA2AoKQphCgQFAAIDEgNjAh4aVCBBIEdvb2dsZSBDbG91ZCBBUEkg
a2V5IHBlcjoKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kb2NzL2F1dGhlbnRpY2F0aW9u
L2FwaS1rZXlzCgoMCgUFAAIDARIDYwIZCgwKBQUAAgMCEgNjHB0KdQoEBQACBBIDZgIwGmgg
QSBHb29nbGUgQ2xvdWQgT0F1dGgyIGNsaWVudCBjcmVkZW50aWFscyBwZXI6CiBodHRwczov
L2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9pZGVudGl0eS9wcm90b2NvbHMvb2F1dGgyCgoMCgUF
AAIEARIDZgIrCgwKBQUAAgQCEgNmLi8KdwoEBQACBRIDaQIqGmogQSBHb29nbGUgQ2xvdWQg
T0F1dGgyIGFjY2VzcyB0b2tlbiBwZXI6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZG9j
cy9hdXRoZW50aWNhdGlvbi90b2tlbi10eXBlcyNhY2Nlc3MKCgwKBQUAAgUBEgNpAiUKDAoF
BQACBQISA2koKQoqCgQFAAIGEgNrAioaHSBBbiBBbnRocm9waWMgQWRtaW4gQVBJIGtleS4K
CgwKBQUAAgYBEgNrAiUKDAoFBQACBgISA2soKQokCgQFAAIHEgNtAiQaFyBBbiBBbnRocm9w
aWMgQVBJIGtleS4KCgwKBQUAAgcBEgNtAh8KDAoFBQACBwISA20iIwolCgQFAAIIEgNvAiUa
GCBBbiBBenVyZSBhY2Nlc3MgdG9rZW4uCgoMCgUFAAIIARIDbwIgCgwKBQUAAggCEgNvIyQK
MwoEBQACCRIDcQInGiYgQW4gQXp1cmUgSWRlbnRpdHkgUGxhdGZvcm0gSUQgdG9rZW4uCgoM
CgUFAAIJARIDcQIiCgwKBQUAAgkCEgNxJSYKMgoEBQACChIDcwI0GiUgQSBEb2NrZXIgSHVi
IHBlcnNvbmFsIGFjY2VzcyB0b2tlbi4KCgwKBQUAAgoBEgNzAi4KDAoFBQACCgISA3MxMwoq
CgQFAAILEgN1AiwaHSBBIEdpdEh1YiBBcHAgcmVmcmVzaCB0b2tlbi4KCgwKBQUAAgsBEgN1
AiYKDAoFBQACCwISA3UpKwozCgQFAAIMEgN3AjUaJiBBIEdpdEh1YiBBcHAgc2VydmVyLXRv
LXNlcnZlciB0b2tlbi4KCgwKBQUAAgwBEgN3Ai8KDAoFBQACDAISA3cyNAoxCgQFAAINEgN5
AjMaJCBBIEdpdEh1YiBBcHAgdXNlci10by1zZXJ2ZXIgdG9rZW4uCgoMCgUFAAINARIDeQIt
CgwKBQUAAg0CEgN5MDIKOAoEBQACDhIDewI4GisgQSBHaXRIdWIgcGVyc29uYWwgYWNjZXNz
IHRva2VuIChjbGFzc2ljKS4KCgwKBQUAAg4BEgN7AjIKDAoFBQACDgISA3s1Nwo7CgQFAAIP
EgN9Aj0aLiBBIEdpdEh1YiBmaW5lLWdyYWluZWQgcGVyc29uYWwgYWNjZXNzIHRva2VuLgoK
DAoFBQACDwESA30CNwoMCgUFAAIPAhIDfTo8CiQKBAUAAhASA38CJhoXIEEgR2l0SHViIE9B
dXRoIHRva2VuLgoKDAoFBQACEAESA38CIAoMCgUFAAIQAhIDfyMlCicKBAUAAhESBIEBAica
GSBBIEh1Z2dpbmcgRmFjZSBBUEkga2V5LgoKDQoFBQACEQESBIEBAiEKDQoFBQACEQISBIEB
JCYKIgoEBQACEhIEgwECIhoUIEFuIE9wZW5BSSBBUEkga2V5LgoKDQoFBQACEgESBIMBAhwK
DQoFBQACEgISBIMBHyEKJQoEBQACExIEhQECJhoXIEEgUGVycGxleGl0eSBBUEkga2V5LgoK
DQoFBQACEwESBIUBAiAKDQoFBQACEwISBIUBIyUKJAoEBQACFBIEhwECJRoWIEEgU3RyaXBl
IHNlY3JldCBrZXkuCgoNCgUFAAIUARIEhwECHwoNCgUFAAIUAhIEhwEiJAooCgQFAAIVEgSJ
AQIpGhogQSBTdHJpcGUgcmVzdHJpY3RlZCBrZXkuCgoNCgUFAAIVARIEiQECIwoNCgUFAAIV
AhIEiQEmKAooCgQFAAIWEgSLAQIpGhogQSBTdHJpcGUgd2ViaG9vayBzZWNyZXQuCgoNCgUF
AAIWARIEiwECIwoNCgUFAAIWAhIEiwEmKGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Secret::SecretNote ===
    # Fields for SecretNote

# === Message: Grafeas::V1::Secret::SecretOccurrence ===
    # Fields for SecretOccurrence
    # Field: kind Type: 14 (.grafeas.v1.SecretKind)
    # Field: locations Type: 11 (.grafeas.v1.SecretLocation)
    # Field: statuses Type: 11 (.grafeas.v1.SecretStatus)
    # Field: data Type: 11 (.google.protobuf.Any)
    # Field: digest Type: 11 (.grafeas.v1.Digest)

# === Message: Grafeas::V1::Secret::SecretLocation ===
    # Fields for SecretLocation
    # Field: file_location Type: 11 (.grafeas.v1.FileLocation)

# === Message: Grafeas::V1::Secret::SecretStatus ===
    # Fields for SecretStatus
    # Field: status Type: 14 (.grafeas.v1.SecretStatus.Status)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: message Type: 9 ()

# Enum: SecretStatus::Status
our $SecretStatus_STATUS_UNSPECIFIED = 0;
our $SecretStatus_UNKNOWN = 1;
our $SecretStatus_VALID = 2;
our $SecretStatus_INVALID = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Secret - Compiled Protocol Buffers messages for grafeas/v1/secret.proto

=head1 SYNOPSIS

    use Grafeas::V1::Secret;

    my $msg = Grafeas::V1::Secret::SecretNote->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Secret::SecretNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/secret.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Secret::SecretNote

The note representing a secret.

Inherits from L<Protobuf::Message>.

=head2 Grafeas::V1::Secret::SecretOccurrence

The occurrence provides details of a secret.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Grafeas::V1::SecretKind>)

Type of secret.

=item * C<< $msg->locations() >> / C<< $msg->locations($value) >>

Type: C<Message> (L<Grafeas::V1::Secret::SecretLocation>)

Locations where the secret is detected.

=item * C<< $msg->statuses() >> / C<< $msg->statuses($value) >>

Type: C<Message> (L<Grafeas::V1::Secret::SecretStatus>)

Status of the secret.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Scan result of the secret.

=item * C<< $msg->digest() >> / C<< $msg->digest($value) >>

Type: C<Message> (L<Grafeas::V1::Common::Digest>)

Hash value, typically a digest for the secret data, that allows unique
identification of a specific secret.

=back

=head2 Grafeas::V1::Secret::SecretLocation

The location of the secret.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_location() >> / C<< $msg->file_location($value) >>

Type: C<Message> (L<Grafeas::V1::Common::FileLocation>)

The secret is found from a file.

=back

=head2 Grafeas::V1::Secret::SecretStatus

The status of the secret with a timestamp.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Grafeas::V1::SecretStatus::Status>)

The status of the secret.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the secret status was last updated.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Optional message about the status code.

=back

=head3 Enum: SecretStatus::Status

=over 4

=item * C<STATUS_UNSPECIFIED> => C<0>

=item * C<UNKNOWN> => C<1>

=item * C<VALID> => C<2>

=item * C<INVALID> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Secret::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
