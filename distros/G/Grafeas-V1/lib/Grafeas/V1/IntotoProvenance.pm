package Grafeas::V1::IntotoProvenance;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiJncmFmZWFzL3YxL2ludG90b19wcm92ZW5hbmNlLnByb3RvEgpncmFmZWFzLnYxGhlnb29n
bGUvcHJvdG9idWYvYW55LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
ItkBCgZSZWNpcGUSEgoEdHlwZRgBIAEoCVIEdHlwZRIuChNkZWZpbmVkX2luX21hdGVyaWFs
GAIgASgDUhFkZWZpbmVkSW5NYXRlcmlhbBIfCgtlbnRyeV9wb2ludBgDIAEoCVIKZW50cnlQ
b2ludBIyCglhcmd1bWVudHMYBCADKAsyFC5nb29nbGUucHJvdG9idWYuQW55Uglhcmd1bWVu
dHMSNgoLZW52aXJvbm1lbnQYBSADKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgtlbnZpcm9u
bWVudCJsCgxDb21wbGV0ZW5lc3MSHAoJYXJndW1lbnRzGAEgASgIUglhcmd1bWVudHMSIAoL
ZW52aXJvbm1lbnQYAiABKAhSC2Vudmlyb25tZW50EhwKCW1hdGVyaWFscxgDIAEoCFIJbWF0
ZXJpYWxzIqoCCghNZXRhZGF0YRIuChNidWlsZF9pbnZvY2F0aW9uX2lkGAEgASgJUhFidWls
ZEludm9jYXRpb25JZBJEChBidWlsZF9zdGFydGVkX29uGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFIOYnVpbGRTdGFydGVkT24SRgoRYnVpbGRfZmluaXNoZWRfb24YAyAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg9idWlsZEZpbmlzaGVkT24SPAoMY29t
cGxldGVuZXNzGAQgASgLMhguZ3JhZmVhcy52MS5Db21wbGV0ZW5lc3NSDGNvbXBsZXRlbmVz
cxIiCgxyZXByb2R1Y2libGUYBSABKAhSDHJlcHJvZHVjaWJsZSIfCg1CdWlsZGVyQ29uZmln
Eg4KAmlkGAEgASgJUgJpZCLQAQoQSW5Ub3RvUHJvdmVuYW5jZRJACg5idWlsZGVyX2NvbmZp
ZxgBIAEoCzIZLmdyYWZlYXMudjEuQnVpbGRlckNvbmZpZ1INYnVpbGRlckNvbmZpZxIqCgZy
ZWNpcGUYAiABKAsyEi5ncmFmZWFzLnYxLlJlY2lwZVIGcmVjaXBlEjAKCG1ldGFkYXRhGAMg
ASgLMhQuZ3JhZmVhcy52MS5NZXRhZGF0YVIIbWV0YWRhdGESHAoJbWF0ZXJpYWxzGAQgAygJ
UgltYXRlcmlhbHNCaAoNaW8uZ3JhZmVhcy52MUIVSW5Ub3RvUHJvdmVuYW5jZVByb3RvUAFa
OGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZ3JhZmVhcy92MTtncmFm
ZWFzogIDR1JBSvgnCgYSBA4AcAEK2gQKAQwSAw4AEjLPBCBDb3B5cmlnaHQgMjAyMSBUaGUg
R3JhZmVhcyBBdXRob3JzLiBBbGwgcmlnaHRzIHJlc2VydmVkLgoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABMKCQoCAwASAxIAIwoJ
CgIDARIDEwApCggKAQgSAxUATwoJCgIICxIDFQBPCggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcAJgoJCgIIARIDFwAmCggKAQgSAxgAIQoJCgIIJBIDGAAhCggKAQgSAxkANgoJCgII
CBIDGQA2CuQBCgIEABIEIQA9ARp1IFN0ZXBzIHRha2VuIHRvIGJ1aWxkIHRoZSBhcnRpZmFj
dC4KIEZvciBhIFRhc2tSdW4sIHR5cGljYWxseSBlYWNoIGNvbnRhaW5lciBjb3JyZXNwb25k
cyB0byBvbmUgc3RlcCBpbiB0aGUKIHJlY2lwZS4KMmEgU3BlYyBkZWZpbmVkIGF0CiBodHRw
czovL2dpdGh1Yi5jb20vaW4tdG90by9hdHRlc3RhdGlvbi9ibG9iL21haW4vc3BlYy9wcmVk
aWNhdGVzL3Byb3ZlbmFuY2UubWQKCgoKAwQAARIDIQgOCqcBCgQEAAIAEgMkAhIamQEgVVJJ
IGluZGljYXRpbmcgd2hhdCB0eXBlIG9mIHJlY2lwZSB3YXMgcGVyZm9ybWVkLiBJdCBkZXRl
cm1pbmVzIHRoZSBtZWFuaW5nCiBvZiByZWNpcGUuZW50cnlQb2ludCwgcmVjaXBlLmFyZ3Vt
ZW50cywgcmVjaXBlLmVudmlyb25tZW50LCBhbmQgbWF0ZXJpYWxzLgoKDAoFBAACAAUSAyQC
CAoMCgUEAAIAARIDJAkNCgwKBQQAAgADEgMkEBEKzgIKBAQAAgESAyoCIBrAAiBJbmRleCBp
biBtYXRlcmlhbHMgY29udGFpbmluZyB0aGUgcmVjaXBlIHN0ZXBzIHRoYXQgYXJlIG5vdCBp
bXBsaWVkIGJ5CiByZWNpcGUudHlwZS4gRm9yIGV4YW1wbGUsIGlmIHRoZSByZWNpcGUgdHlw
ZSB3ZXJlICJtYWtlIiwgdGhlbiB0aGlzIHdvdWxkCiBwb2ludCB0byB0aGUgc291cmNlIGNv
bnRhaW5pbmcgdGhlIE1ha2VmaWxlLCBub3QgdGhlIG1ha2UgcHJvZ3JhbSBpdHNlbGYuCiBT
ZXQgdG8gLTEgaWYgdGhlIHJlY2lwZSBkb2Vzbid0IGNvbWUgZnJvbSBhIG1hdGVyaWFsLCBh
cyB6ZXJvIGlzIGRlZmF1bHQKIHVuc2V0IHZhbHVlIGZvciBpbnQ2NC4KCgwKBQQAAgEFEgMq
AgcKDAoFBAACAQESAyoIGwoMCgUEAAIBAxIDKh4fCtgCCgQEAAICEgMwAhkaygIgU3RyaW5n
IGlkZW50aWZ5aW5nIHRoZSBlbnRyeSBwb2ludCBpbnRvIHRoZSBidWlsZC4KIFRoaXMgaXMg
b2Z0ZW4gYSBwYXRoIHRvIGEgY29uZmlndXJhdGlvbiBmaWxlIGFuZC9vciBhIHRhcmdldCBs
YWJlbCB3aXRoaW4KIHRoYXQgZmlsZS4gVGhlIHN5bnRheCBhbmQgbWVhbmluZyBhcmUgZGVm
aW5lZCBieSByZWNpcGUudHlwZS4gRm9yIGV4YW1wbGUsCiBpZiB0aGUgcmVjaXBlIHR5cGUg
d2VyZSAibWFrZSIsIHRoZW4gdGhpcyB3b3VsZCByZWZlcmVuY2UgdGhlIGRpcmVjdG9yeSBp
bgogd2hpY2ggdG8gcnVuIG1ha2UgYXMgd2VsbCBhcyB3aGljaCB0YXJnZXQgdG8gdXNlLgoK
DAoFBAACAgUSAzACCAoMCgUEAAICARIDMAkUCgwKBQQAAgIDEgMwFxgKnAMKBAQAAgMSAzcC
LRqOAyBDb2xsZWN0aW9uIG9mIGFsbCBleHRlcm5hbCBpbnB1dHMgdGhhdCBpbmZsdWVuY2Vk
IHRoZSBidWlsZCBvbiB0b3Agb2YKIHJlY2lwZS5kZWZpbmVkSW5NYXRlcmlhbCBhbmQgcmVj
aXBlLmVudHJ5UG9pbnQuIEZvciBleGFtcGxlLCBpZiB0aGUgcmVjaXBlCiB0eXBlIHdlcmUg
Im1ha2UiLCB0aGVuIHRoaXMgbWlnaHQgYmUgdGhlIGZsYWdzIHBhc3NlZCB0byBtYWtlIGFz
aWRlIGZyb20KIHRoZSB0YXJnZXQsIHdoaWNoIGlzIGNhcHR1cmVkIGluIHJlY2lwZS5lbnRy
eVBvaW50LiBTaW5jZSB0aGUgYXJndW1lbnRzCiBmaWVsZCBjYW4gZ3JlYXRseSB2YXJ5IGlu
IHN0cnVjdHVyZSwgZGVwZW5kaW5nIG9uIHRoZSBidWlsZGVyIGFuZCByZWNpcGUKIHR5cGUs
IHRoaXMgaXMgb2YgZm9ybSAiQW55Ii4KCgwKBQQAAgMEEgM3AgoKDAoFBAACAwYSAzcLHgoM
CgUEAAIDARIDNx8oCgwKBQQAAgMDEgM3KywKtAIKBAQAAgQSAzwCLxqmAiBBbnkgb3RoZXIg
YnVpbGRlci1jb250cm9sbGVkIGlucHV0cyBuZWNlc3NhcnkgZm9yIGNvcnJlY3RseSBldmFs
dWF0aW5nIHRoZQogcmVjaXBlLiBVc3VhbGx5IG9ubHkgbmVlZGVkIGZvciByZXByb2R1Y2lu
ZyB0aGUgYnVpbGQgYnV0IG5vdCBldmFsdWF0ZWQgYXMKIHBhcnQgb2YgcG9saWN5LiBTaW5j
ZSB0aGUgZW52aXJvbm1lbnQgZmllbGQgY2FuIGdyZWF0bHkgdmFyeSBpbiBzdHJ1Y3R1cmUs
CiBkZXBlbmRpbmcgb24gdGhlIGJ1aWxkZXIgYW5kIHJlY2lwZSB0eXBlLCB0aGlzIGlzIG9m
IGZvcm0gIkFueSIuCgoMCgUEAAIEBBIDPAIKCgwKBQQAAgQGEgM8Cx4KDAoFBAACBAESAzwf
KgoMCgUEAAIEAxIDPC0uCl8KAgQBEgRBAEsBGlMgSW5kaWNhdGVzIHRoYXQgdGhlIGJ1aWxk
ZXIgY2xhaW1zIGNlcnRhaW4gZmllbGRzIGluIHRoaXMgbWVzc2FnZSB0byBiZQogY29tcGxl
dGUuCgoKCgMEAQESA0EIFAqVAQoEBAECABIDRAIVGocBIElmIHRydWUsIHRoZSBidWlsZGVy
IGNsYWltcyB0aGF0IHJlY2lwZS5hcmd1bWVudHMgaXMgY29tcGxldGUsIG1lYW5pbmcgdGhh
dAogYWxsIGV4dGVybmFsIGlucHV0cyBhcmUgcHJvcGVybHkgY2FwdHVyZWQgaW4gdGhlIHJl
Y2lwZS4KCgwKBQQBAgAFEgNEAgYKDAoFBAECAAESA0QHEAoMCgUEAQIAAxIDRBMUCl4KBAQB
AgESA0cCFxpRIElmIHRydWUsIHRoZSBidWlsZGVyIGNsYWltcyB0aGF0IHJlY2lwZS5lbnZp
cm9ubWVudCBpcyBjbGFpbWVkIHRvIGJlCiBjb21wbGV0ZS4KCgwKBQQBAgEFEgNHAgYKDAoF
BAECAQESA0cHEgoMCgUEAQIBAxIDRxUWCp8BCgQEAQICEgNKAhUakQEgSWYgdHJ1ZSwgdGhl
IGJ1aWxkZXIgY2xhaW1zIHRoYXQgbWF0ZXJpYWxzIGFyZSBjb21wbGV0ZSwgdXN1YWxseSB0
aHJvdWdoCiBzb21lIGNvbnRyb2xzIHRvIHByZXZlbnQgbmV0d29yayBhY2Nlc3MuIFNvbWV0
aW1lcyBjYWxsZWQgImhlcm1ldGljIi4KCgwKBQQBAgIFEgNKAgYKDAoFBAECAgESA0oHEAoM
CgUEAQICAxIDShMUCiwKAgQCEgROAF0BGiAgT3RoZXIgcHJvcGVydGllcyBvZiB0aGUgYnVp
bGQuCgoKCgMEAgESA04IEArJAQoEBAICABIDUgIhGrsBIElkZW50aWZpZXMgdGhlIHBhcnRp
Y3VsYXIgYnVpbGQgaW52b2NhdGlvbiwgd2hpY2ggY2FuIGJlIHVzZWZ1bCBmb3IgZmluZGlu
ZwogYXNzb2NpYXRlZCBsb2dzIG9yIG90aGVyIGFkLWhvYyBhbmFseXNpcy4gVGhlIHZhbHVl
IFNIT1VMRCBiZSBnbG9iYWxseQogdW5pcXVlLCBwZXIgaW4tdG90byBQcm92ZW5hbmNlIHNw
ZWMuCgoMCgUEAgIABRIDUgIICgwKBQQCAgABEgNSCRwKDAoFBAICAAMSA1IfIAo3CgQEAgIB
EgNUAjEaKiBUaGUgdGltZXN0YW1wIG9mIHdoZW4gdGhlIGJ1aWxkIHN0YXJ0ZWQuCgoMCgUE
AgIBBhIDVAIbCgwKBQQCAgEBEgNUHCwKDAoFBAICAQMSA1QvMAo5CgQEAgICEgNWAjIaLCBU
aGUgdGltZXN0YW1wIG9mIHdoZW4gdGhlIGJ1aWxkIGNvbXBsZXRlZC4KCgwKBQQCAgIGEgNW
AhsKDAoFBAICAgESA1YcLQoMCgUEAgICAxIDVjAxCmAKBAQCAgMSA1kCIBpTIEluZGljYXRl
cyB0aGF0IHRoZSBidWlsZGVyIGNsYWltcyBjZXJ0YWluIGZpZWxkcyBpbiB0aGlzIG1lc3Nh
Z2UgdG8gYmUKIGNvbXBsZXRlLgoKDAoFBAICAwYSA1kCDgoMCgUEAgIDARIDWQ8bCgwKBQQC
AgMDEgNZHh8KewoEBAICBBIDXAIYGm4gSWYgdHJ1ZSwgdGhlIGJ1aWxkZXIgY2xhaW1zIHRo
YXQgcnVubmluZyB0aGUgcmVjaXBlIG9uIG1hdGVyaWFscyB3aWxsCiBwcm9kdWNlIGJpdC1m
b3ItYml0IGlkZW50aWNhbCBvdXRwdXQuCgoMCgUEAgIEBRIDXAIGCgwKBQQCAgQBEgNcBxMK
DAoFBAICBAMSA1wWFwoKCgIEAxIEXwBhAQoKCgMEAwESA18IFQoLCgQEAwIAEgNgAhAKDAoF
BAMCAAUSA2ACCAoMCgUEAwIAARIDYAkLCgwKBQQDAgADEgNgDg8KCgoCBAQSBGMAcAEKCgoD
BAQBEgNjCBgKFwoEBAQCABIDZAIjIgogcmVxdWlyZWQKCgwKBQQEAgAGEgNkAg8KDAoFBAQC
AAESA2QQHgoMCgUEBAIAAxIDZCEiCvwBCgQEBAIBEgNpAhQa4gEgSWRlbnRpZmllcyB0aGUg
Y29uZmlndXJhdGlvbiB1c2VkIGZvciB0aGUgYnVpbGQuCiBXaGVuIGNvbWJpbmVkIHdpdGgg
bWF0ZXJpYWxzLCB0aGlzIFNIT1VMRCBmdWxseSBkZXNjcmliZSB0aGUgYnVpbGQsCiBzdWNo
IHRoYXQgcmUtcnVubmluZyB0aGlzIHJlY2lwZSByZXN1bHRzIGluIGJpdC1mb3ItYml0IGlk
ZW50aWNhbCBvdXRwdXQKIChpZiB0aGUgYnVpbGQgaXMgcmVwcm9kdWNpYmxlKS4KIgogcmVx
dWlyZWQKCgwKBQQEAgEGEgNpAggKDAoFBAQCAQESA2kJDwoMCgUEBAIBAxIDaRITCgsKBAQE
AgISA2oCGAoMCgUEBAICBhIDagIKCgwKBQQEAgIBEgNqCxMKDAoFBAQCAgMSA2oWFwqIAgoE
BAQCAxIDbwIgGvoBIFRoZSBjb2xsZWN0aW9uIG9mIGFydGlmYWN0cyB0aGF0IGluZmx1ZW5j
ZWQgdGhlIGJ1aWxkIGluY2x1ZGluZyBzb3VyY2VzLAogZGVwZW5kZW5jaWVzLCBidWlsZCB0
b29scywgYmFzZSBpbWFnZXMsIGFuZCBzbyBvbi4gVGhpcyBpcyBjb25zaWRlcmVkIHRvIGJl
CiBpbmNvbXBsZXRlIHVubGVzcyBtZXRhZGF0YS5jb21wbGV0ZW5lc3MubWF0ZXJpYWxzIGlz
IHRydWUuIFVuc2V0IG9yIG51bGwgaXMKIGVxdWl2YWxlbnQgdG8gZW1wdHkuCgoMCgUEBAID
BBIDbwIKCgwKBQQEAgMFEgNvCxEKDAoFBAQCAwESA28SGwoMCgUEBAIDAxIDbx4fYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::IntotoProvenance::Recipe ===
    # Fields for Recipe
    # Field: type Type: 9 ()
    # Field: defined_in_material Type: 3 ()
    # Field: entry_point Type: 9 ()
    # Field: arguments Type: 11 (.google.protobuf.Any)
    # Field: environment Type: 11 (.google.protobuf.Any)

# === Message: Grafeas::V1::IntotoProvenance::Completeness ===
    # Fields for Completeness
    # Field: arguments Type: 8 ()
    # Field: environment Type: 8 ()
    # Field: materials Type: 8 ()

# === Message: Grafeas::V1::IntotoProvenance::Metadata ===
    # Fields for Metadata
    # Field: build_invocation_id Type: 9 ()
    # Field: build_started_on Type: 11 (.google.protobuf.Timestamp)
    # Field: build_finished_on Type: 11 (.google.protobuf.Timestamp)
    # Field: completeness Type: 11 (.grafeas.v1.Completeness)
    # Field: reproducible Type: 8 ()

# === Message: Grafeas::V1::IntotoProvenance::BuilderConfig ===
    # Fields for BuilderConfig
    # Field: id Type: 9 ()

# === Message: Grafeas::V1::IntotoProvenance::InTotoProvenance ===
    # Fields for InTotoProvenance
    # Field: builder_config Type: 11 (.grafeas.v1.BuilderConfig)
    # Field: recipe Type: 11 (.grafeas.v1.Recipe)
    # Field: metadata Type: 11 (.grafeas.v1.Metadata)
    # Field: materials Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::IntotoProvenance - Compiled Protocol Buffers messages for grafeas/v1/intoto_provenance.proto

=head1 SYNOPSIS

    use Grafeas::V1::IntotoProvenance;

    my $msg = Grafeas::V1::IntotoProvenance::Recipe->new({
        type => $type,
        defined_in_material => $defined_in_material,
        entry_point => $entry_point,
        arguments => $arguments,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::IntotoProvenance::Recipe->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/intoto_provenance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::IntotoProvenance::Recipe

Steps taken to build the artifact.
For a TaskRun, typically each container corresponds to one step in the
recipe.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

URI indicating what type of recipe was performed. It determines the meaning
of recipe.entryPoint, recipe.arguments, recipe.environment, and materials.

=item * C<< $msg->defined_in_material() >> / C<< $msg->defined_in_material($value) >>

Type: C<Int64>

Index in materials containing the recipe steps that are not implied by
recipe.type. For example, if the recipe type were "make", then this would
point to the source containing the Makefile, not the make program itself.
Set to -1 if the recipe doesn't come from a material, as zero is default
unset value for int64.

=item * C<< $msg->entry_point() >> / C<< $msg->entry_point($value) >>

Type: C<String>

String identifying the entry point into the build.
This is often a path to a configuration file and/or a target label within
that file. The syntax and meaning are defined by recipe.type. For example,
if the recipe type were "make", then this would reference the directory in
which to run make as well as which target to use.

=item * C<< $msg->arguments() >> / C<< $msg->arguments($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Collection of all external inputs that influenced the build on top of
recipe.definedInMaterial and recipe.entryPoint. For example, if the recipe
type were "make", then this might be the flags passed to make aside from
the target, which is captured in recipe.entryPoint. Since the arguments
field can greatly vary in structure, depending on the builder and recipe
type, this is of form "Any".

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Any other builder-controlled inputs necessary for correctly evaluating the
recipe. Usually only needed for reproducing the build but not evaluated as
part of policy. Since the environment field can greatly vary in structure,
depending on the builder and recipe type, this is of form "Any".

=back

=head2 Grafeas::V1::IntotoProvenance::Completeness

Indicates that the builder claims certain fields in this message to be
complete.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->arguments() >> / C<< $msg->arguments($value) >>

Type: C<Bool>

If true, the builder claims that recipe.arguments is complete, meaning that
all external inputs are properly captured in the recipe.

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Bool>

If true, the builder claims that recipe.environment is claimed to be
complete.

=item * C<< $msg->materials() >> / C<< $msg->materials($value) >>

Type: C<Bool>

If true, the builder claims that materials are complete, usually through
some controls to prevent network access. Sometimes called "hermetic".

=back

=head2 Grafeas::V1::IntotoProvenance::Metadata

Other properties of the build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->build_invocation_id() >> / C<< $msg->build_invocation_id($value) >>

Type: C<String>

Identifies the particular build invocation, which can be useful for finding
associated logs or other ad-hoc analysis. The value SHOULD be globally
unique, per in-toto Provenance spec.

=item * C<< $msg->build_started_on() >> / C<< $msg->build_started_on($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp of when the build started.

=item * C<< $msg->build_finished_on() >> / C<< $msg->build_finished_on($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp of when the build completed.

=item * C<< $msg->completeness() >> / C<< $msg->completeness($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoProvenance::Completeness>)

Indicates that the builder claims certain fields in this message to be
complete.

=item * C<< $msg->reproducible() >> / C<< $msg->reproducible($value) >>

Type: C<Bool>

If true, the builder claims that running the recipe on materials will
produce bit-for-bit identical output.

=back

=head2 Grafeas::V1::IntotoProvenance::BuilderConfig

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

=back

=head2 Grafeas::V1::IntotoProvenance::InTotoProvenance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->builder_config() >> / C<< $msg->builder_config($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoProvenance::BuilderConfig>)

required

=item * C<< $msg->recipe() >> / C<< $msg->recipe($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoProvenance::Recipe>)

Identifies the configuration used for the build.
When combined with materials, this SHOULD fully describe the build,
such that re-running this recipe results in bit-for-bit identical output
(if the build is reproducible).

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoProvenance::Metadata>)

=item * C<< $msg->materials() >> / C<< $msg->materials($value) >>

Type: C<String>

The collection of artifacts that influenced the build including sources,
dependencies, build tools, base images, and so on. This is considered to be
incomplete unless metadata.completeness.materials is true. Unset or null is
equivalent to empty.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::IntotoProvenance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
