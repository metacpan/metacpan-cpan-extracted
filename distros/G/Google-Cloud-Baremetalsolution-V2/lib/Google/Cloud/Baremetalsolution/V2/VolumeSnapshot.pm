package Google::Cloud::Baremetalsolution::V2::VolumeSnapshot;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvdm9sdW1lX3NuYXBzaG90LnBy
b3RvEiFnb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8inwQKDlZvbHVtZVNuYXBzaG90EhIKBG5hbWUYASAB
KAlSBG5hbWUSEwoCaWQYBiABKAlCA+BBA1ICaWQSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rl
c2NyaXB0aW9uEkAKC2NyZWF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lElYKDnN0b3JhZ2Vfdm9sdW1lGAUgASgJQi/gQQP6QSkK
J2JhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL1ZvbHVtZVINc3RvcmFnZVZvbHVt
ZRJXCgR0eXBlGAcgASgOMj4uZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZv
bHVtZVNuYXBzaG90LlNuYXBzaG90VHlwZUID4EEDUgR0eXBlIkgKDFNuYXBzaG90VHlwZRId
ChlTTkFQU0hPVF9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGQURfSE9DEAESDQoJU0NIRURVTEVE
EAI6hAHqQYABCi9iYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9Wb2x1bWVTbmFw
c2hvdBJNcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3ZvbHVtZXMv
e3ZvbHVtZX0vc25hcHNob3RzL3tzbmFwc2hvdH0iZwoYR2V0Vm9sdW1lU25hcHNob3RSZXF1
ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBp
cy5jb20vVm9sdW1lU25hcHNob3RSBG5hbWUioQEKGkxpc3RWb2x1bWVTbmFwc2hvdHNSZXF1
ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC+kEpCidiYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVh
cGlzLmNvbS9Wb2x1bWVSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0K
CnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiLFAQobTGlzdFZvbHVtZVNuYXBzaG90c1Jl
c3BvbnNlElwKEHZvbHVtZV9zbmFwc2hvdHMYASADKAsyMS5nb29nbGUuY2xvdWQuYmFyZW1l
dGFsc29sdXRpb24udjIuVm9sdW1lU25hcHNob3RSD3ZvbHVtZVNuYXBzaG90cxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlS
C3VucmVhY2hhYmxlImoKG0RlbGV0ZVZvbHVtZVNuYXBzaG90UmVxdWVzdBJLCgRuYW1lGAEg
ASgJQjfgQQL6QTEKL2JhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL1ZvbHVtZVNu
YXBzaG90UgRuYW1lIscBChtDcmVhdGVWb2x1bWVTbmFwc2hvdFJlcXVlc3QSRwoGcGFyZW50
GAEgASgJQi/gQQL6QSkKJ2JhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL1ZvbHVt
ZVIGcGFyZW50El8KD3ZvbHVtZV9zbmFwc2hvdBgCIAEoCzIxLmdvb2dsZS5jbG91ZC5iYXJl
bWV0YWxzb2x1dGlvbi52Mi5Wb2x1bWVTbmFwc2hvdEID4EECUg52b2x1bWVTbmFwc2hvdCKA
AQocUmVzdG9yZVZvbHVtZVNuYXBzaG90UmVxdWVzdBJgCg92b2x1bWVfc25hcHNob3QYASAB
KAlCN+BBAvpBMQovYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vVm9sdW1lU25h
cHNob3RSDnZvbHVtZVNuYXBzaG90QoICCiVjb20uZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNv
bHV0aW9uLnYyQhNWb2x1bWVTbmFwc2hvdFByb3RvUAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28v
YmFyZW1ldGFsc29sdXRpb24vYXBpdjIvYmFyZW1ldGFsc29sdXRpb25wYjtiYXJlbWV0YWxz
b2x1dGlvbnBiqgIhR29vZ2xlLkNsb3VkLkJhcmVNZXRhbFNvbHV0aW9uLlYyygIhR29vZ2xl
XENsb3VkXEJhcmVNZXRhbFNvbHV0aW9uXFYy6gIkR29vZ2xlOjpDbG91ZDo6QmFyZU1ldGFs
U29sdXRpb246OlYySu4fCgcSBQ4AlwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgS
AxYAPgoJCgIIJRIDFgA+CggKAQgSAxcAagoJCgIICxIDFwBqCggKAQgSAxgAIgoJCgIIChID
GAAiCggKAQgSAxkANAoJCgIICBIDGQA0CggKAQgSAxoAPgoJCgIIARIDGgA+CggKAQgSAxsA
PgoJCgIIKRIDGwA+CggKAQgSAxwAPQoJCgIILRIDHAA9CksKAgQAEgQfAEkBGj8gQSBzbmFw
c2hvdCBvZiBhIHZvbHVtZS4gT25seSBib290IHZvbHVtZXMgY2FuIGhhdmUgc25hcHNob3Rz
LgoKCgoDBAABEgMfCBYKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECjIKBAQABAASBCYC
LwMaJCBSZXByZXNlbnRzIHRoZSB0eXBlIG9mIGEgc25hcHNob3QuCgoMCgUEAAQAARIDJgcT
CicKBgQABAACABIDKAQiGhggVHlwZSBpcyBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAAIAARID
KAQdCg4KBwQABAACAAISAyggIQo1CgYEAAQAAgESAysEDxomIFNuYXBzaG90IHdhcyB0YWtl
biBtYW51YWxseSBieSB1c2VyLgoKDgoHBAAEAAIBARIDKwQKCg4KBwQABAACAQISAysNDgpT
CgYEAAQAAgISAy4EEhpEIFNuYXBzaG90IHdhcyB0YWtlbiBhdXRvbWF0aWNhbGx5IGFzIGEg
cGFydCBvZiBhIHNuYXBzaG90IHNjaGVkdWxlLgoKDgoHBAAEAAICARIDLgQNCg4KBwQABAAC
AgISAy4QEQooCgQEAAIAEgMyAhIaGyBUaGUgbmFtZSBvZiB0aGUgc25hcHNob3QuCgoMCgUE
AAIABRIDMgIICgwKBQQAAgABEgMyCQ0KDAoFBAACAAMSAzIQEQpVCgQEAAIBEgM1AjwaSCBP
dXRwdXQgb25seS4gQW4gaWRlbnRpZmllciBmb3IgdGhlIHNuYXBzaG90LCBnZW5lcmF0ZWQg
YnkgdGhlIGJhY2tlbmQuCgoMCgUEAAIBBRIDNQIICgwKBQQAAgEBEgM1CQsKDAoFBAACAQMS
AzUODwoMCgUEAAIBCBIDNRA7Cg8KCAQAAgEInAgAEgM1EToKLwoEBAACAhIDOAIZGiIgVGhl
IGRlc2NyaXB0aW9uIG9mIHRoZSBzbmFwc2hvdC4KCgwKBQQAAgIFEgM4AggKDAoFBAACAgES
AzgJFAoMCgUEAAICAxIDOBcYCj8KBAQAAgMSBDsCPDIaMSBPdXRwdXQgb25seS4gVGhlIGNy
ZWF0aW9uIHRpbWUgb2YgdGhlIHNuYXBzaG90LgoKDAoFBAACAwYSAzsCGwoMCgUEAAIDARID
OxwnCgwKBQQAAgMDEgM7KisKDAoFBAACAwgSAzwGMQoPCggEAAIDCJwIABIDPAcwClMKBAQA
AgQSBD8CRAQaRSBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIHZvbHVtZSB3aGljaCB0
aGlzIHNuYXBzaG90IGJlbG9uZ3MgdG8uCgoMCgUEAAIEBRIDPwIICgwKBQQAAgQBEgM/CRcK
DAoFBAACBAMSAz8aGwoNCgUEAAIECBIEPxxEAwoPCggEAAIECJwIABIDQAQtCg8KBwQAAgQI
nwgSBEEEQwUKcAoEBAACBRIDSAJEGmMgT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSBz
bmFwc2hvdCB3aGljaCBpbmRpY2F0ZXMgd2hldGhlciBpdCB3YXMKIHNjaGVkdWxlZCBvciBt
YW51YWwvYWQtaG9jLgoKDAoFBAACBQYSA0gCDgoMCgUEAAIFARIDSA8TCgwKBQQAAgUDEgNI
FhcKDAoFBAACBQgSA0gYQwoPCggEAAIFCJwIABIDSBlCCkEKAgQBEgRMAFQBGjUgTWVzc2Fn
ZSBmb3IgcmVxdWVzdGluZyB2b2x1bWUgc25hcHNob3QgaW5mb3JtYXRpb24uCgoKCgMEAQES
A0wIIAozCgQEAQIAEgROAlMEGiUgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzbmFwc2hv
dC4KCgwKBQQBAgAFEgNOAggKDAoFBAECAAESA04JDQoMCgUEAQIAAxIDThARCg0KBQQBAgAI
EgROElMDCg8KCAQBAgAInAgAEgNPBCoKDwoHBAECAAifCBIEUARSBQpACgIEAhIEVwBmARo0
IE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgYSBsaXN0IG9mIHZvbHVtZSBzbmFwc2hvdHMuCgoK
CgMEAgESA1cIIgo+CgQEAgIAEgRZAl4EGjAgUmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3Ig
TGlzdFZvbHVtZXNSZXF1ZXN0LgoKDAoFBAICAAUSA1kCCAoMCgUEAgIAARIDWQkPCgwKBQQC
AgADEgNZEhMKDQoFBAICAAgSBFkUXgMKDwoIBAICAAicCAASA1oEKgoPCgcEAgIACJ8IEgRb
BF0FCpIBCgQEAgIBEgNiAhYahAEgUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gVGhlIHNlcnZlciBt
aWdodCByZXR1cm4gZmV3ZXIgaXRlbXMgdGhhbiByZXF1ZXN0ZWQuCiBJZiB1bnNwZWNpZmll
ZCwgc2VydmVyIHdpbGwgcGljayBhbiBhcHByb3ByaWF0ZSBkZWZhdWx0LgoKDAoFBAICAQUS
A2ICBwoMCgUEAgIBARIDYggRCgwKBQQCAgEDEgNiFBUKRQoEBAICAhIDZQIYGjggQSB0b2tl
biBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyBmcm9tIHRoZSBzZXJ2ZXIuCgoMCgUE
AgICBRIDZQIICgwKBQQCAgIBEgNlCRMKDAoFBAICAgMSA2UWFwpHCgIEAxIEaQByARo7IFJl
c3BvbnNlIG1lc3NhZ2UgY29udGFpbmluZyB0aGUgbGlzdCBvZiB2b2x1bWUgc25hcHNob3Rz
LgoKCgoDBAMBEgNpCCMKJQoEBAMCABIDawIvGhggVGhlIGxpc3Qgb2Ygc25hcHNob3RzLgoK
DAoFBAMCAAQSA2sCCgoMCgUEAwIABhIDawsZCgwKBQQDAgABEgNrGioKDAoFBAMCAAMSA2st
LgpFCgQEAwIBEgNuAh0aOCBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRz
IGZyb20gdGhlIHNlcnZlci4KCgwKBQQDAgEFEgNuAggKDAoFBAMCAQESA24JGAoMCgUEAwIB
AxIDbhscCjMKBAQDAgISA3ECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFj
aGVkLgoKDAoFBAMCAgQSA3ECCgoMCgUEAwICBRIDcQsRCgwKBQQDAgIBEgNxEh0KDAoFBAMC
AgMSA3EgIQo5CgIEBBIEdQB9ARotIE1lc3NhZ2UgZm9yIGRlbGV0aW5nIG5hbWVkIFZvbHVt
ZSBzbmFwc2hvdC4KCgoKAwQEARIDdQgjCj0KBAQEAgASBHcCfAQaLyBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIHNuYXBzaG90IHRvIGRlbGV0ZS4KCgwKBQQEAgAFEgN3AggKDAoFBAQC
AAESA3cJDQoMCgUEBAIAAxIDdxARCg0KBQQEAgAIEgR3EnwDCg8KCAQEAgAInAgAEgN4BCoK
DwoHBAQCAAifCBIEeQR7BQo3CgIEBRIGgAEAiwEBGikgTWVzc2FnZSBmb3IgY3JlYXRpbmcg
YSB2b2x1bWUgc25hcHNob3QuCgoLCgMEBQESBIABCCMKMwoEBAUCABIGggEChwEEGiMgUmVx
dWlyZWQuIFRoZSB2b2x1bWUgdG8gc25hcHNob3QuCgoNCgUEBQIABRIEggECCAoNCgUEBQIA
ARIEggEJDwoNCgUEBQIAAxIEggESEwoPCgUEBQIACBIGggEUhwEDChAKCAQFAgAInAgAEgSD
AQQqChEKBwQFAgAInwgSBoQBBIYBBQoxCgQEBQIBEgSKAQJOGiMgUmVxdWlyZWQuIFRoZSBz
bmFwc2hvdCB0byBjcmVhdGUuCgoNCgUEBQIBBhIEigECEAoNCgUEBQIBARIEigERIAoNCgUE
BQIBAxIEigEjJAoNCgUEBQIBCBIEigElTQoQCggEBQIBCJwIABIEigEmTAo4CgIEBhIGjgEA
lwEBGiogTWVzc2FnZSBmb3IgcmVzdG9yaW5nIGEgdm9sdW1lIHNuYXBzaG90LgoKCwoDBAYB
EgSOAQgkCmIKBAQGAgASBpEBApYBBBpSIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBzbmFwc2hv
dCB3aGljaCB3aWxsIGJlIHVzZWQgdG8gcmVzdG9yZSBpdHMgcGFyZW50CiB2b2x1bWUuCgoN
CgUEBgIABRIEkQECCAoNCgUEBgIAARIEkQEJGAoNCgUEBgIAAxIEkQEbHAoPCgUEBgIACBIG
kQEdlgEDChAKCAQGAgAInAgAEgSSAQQqChEKBwQGAgAInwgSBpMBBJUBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot ===
    # Fields for VolumeSnapshot
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: storage_volume Type: 9 ()
    # Field: type Type: 14 (.google.cloud.baremetalsolution.v2.VolumeSnapshot.SnapshotType)

# Enum: VolumeSnapshot::SnapshotType
our $VolumeSnapshot_SNAPSHOT_TYPE_UNSPECIFIED = 0;
our $VolumeSnapshot_AD_HOC = 1;
our $VolumeSnapshot_SCHEDULED = 2;

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::GetVolumeSnapshotRequest ===
    # Fields for GetVolumeSnapshotRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsRequest ===
    # Fields for ListVolumeSnapshotsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsResponse ===
    # Fields for ListVolumeSnapshotsResponse
    # Field: volume_snapshots Type: 11 (.google.cloud.baremetalsolution.v2.VolumeSnapshot)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::DeleteVolumeSnapshotRequest ===
    # Fields for DeleteVolumeSnapshotRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::CreateVolumeSnapshotRequest ===
    # Fields for CreateVolumeSnapshotRequest
    # Field: parent Type: 9 ()
    # Field: volume_snapshot Type: 11 (.google.cloud.baremetalsolution.v2.VolumeSnapshot)

# === Message: Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::RestoreVolumeSnapshotRequest ===
    # Fields for RestoreVolumeSnapshotRequest
    # Field: volume_snapshot Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::VolumeSnapshot - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/volume_snapshot.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::VolumeSnapshot;

    my $msg = Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot->new({
        name => $name,
        id => $id,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/volume_snapshot.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot

A snapshot of a volume. Only boot volumes can have snapshots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the snapshot.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. An identifier for the snapshot, generated by the backend.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the snapshot.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time of the snapshot.

=item * C<< $msg->storage_volume() >> / C<< $msg->storage_volume($value) >>

Type: C<String>

Output only. The name of the volume which this snapshot belongs to.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::SnapshotType>)

Output only. The type of the snapshot which indicates whether it was
scheduled or manual/ad-hoc.

=back

=head3 Enum: VolumeSnapshot::SnapshotType

=over 4

=item * C<SNAPSHOT_TYPE_UNSPECIFIED> => C<0>

=item * C<AD_HOC> => C<1>

=item * C<SCHEDULED> => C<2>

=back

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::GetVolumeSnapshotRequest

Message for requesting volume snapshot information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the snapshot.

=back

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsRequest

Message for requesting a list of volume snapshots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListVolumesRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server might return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=back

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::ListVolumeSnapshotsResponse

Response message containing the list of volume snapshots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volume_snapshots() >> / C<< $msg->volume_snapshots($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot>)

The list of snapshots.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::DeleteVolumeSnapshotRequest

Message for deleting named Volume snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the snapshot to delete.

=back

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::CreateVolumeSnapshotRequest

Message for creating a volume snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The volume to snapshot.

=item * C<< $msg->volume_snapshot() >> / C<< $msg->volume_snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::VolumeSnapshot>)

Required. The snapshot to create.

=back

=head2 Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::RestoreVolumeSnapshotRequest

Message for restoring a volume snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volume_snapshot() >> / C<< $msg->volume_snapshot($value) >>

Type: C<String>

Required. Name of the snapshot which will be used to restore its parent
volume.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::VolumeSnapshot::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
