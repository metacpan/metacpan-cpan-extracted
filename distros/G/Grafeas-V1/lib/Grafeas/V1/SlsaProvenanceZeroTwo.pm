package Grafeas::V1::SlsaProvenanceZeroTwo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CilncmFmZWFzL3YxL3Nsc2FfcHJvdmVuYW5jZV96ZXJvX3R3by5wcm90bxIKZ3JhZmVhcy52
MRocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byLyCwoVU2xzYVByb3ZlbmFuY2VaZXJvVHdvEkcKB2J1aWxkZXIYASABKAsy
LS5ncmFmZWFzLnYxLlNsc2FQcm92ZW5hbmNlWmVyb1R3by5TbHNhQnVpbGRlclIHYnVpbGRl
chIdCgpidWlsZF90eXBlGAIgASgJUglidWlsZFR5cGUSUAoKaW52b2NhdGlvbhgDIAEoCzIw
LmdyYWZlYXMudjEuU2xzYVByb3ZlbmFuY2VaZXJvVHdvLlNsc2FJbnZvY2F0aW9uUgppbnZv
Y2F0aW9uEjoKDGJ1aWxkX2NvbmZpZxgEIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RS
C2J1aWxkQ29uZmlnEkoKCG1ldGFkYXRhGAUgASgLMi4uZ3JhZmVhcy52MS5TbHNhUHJvdmVu
YW5jZVplcm9Ud28uU2xzYU1ldGFkYXRhUghtZXRhZGF0YRJMCgltYXRlcmlhbHMYBiADKAsy
Li5ncmFmZWFzLnYxLlNsc2FQcm92ZW5hbmNlWmVyb1R3by5TbHNhTWF0ZXJpYWxSCW1hdGVy
aWFscxodCgtTbHNhQnVpbGRlchIOCgJpZBgBIAEoCVICaWQarwEKDFNsc2FNYXRlcmlhbBIQ
CgN1cmkYASABKAlSA3VyaRJSCgZkaWdlc3QYAiADKAsyOi5ncmFmZWFzLnYxLlNsc2FQcm92
ZW5hbmNlWmVyb1R3by5TbHNhTWF0ZXJpYWwuRGlnZXN0RW50cnlSBmRpZ2VzdBo5CgtEaWdl
c3RFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGt0B
Cg5TbHNhSW52b2NhdGlvbhJXCg1jb25maWdfc291cmNlGAEgASgLMjIuZ3JhZmVhcy52MS5T
bHNhUHJvdmVuYW5jZVplcm9Ud28uU2xzYUNvbmZpZ1NvdXJjZVIMY29uZmlnU291cmNlEjcK
CnBhcmFtZXRlcnMYAiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgpwYXJhbWV0ZXJz
EjkKC2Vudmlyb25tZW50GAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFILZW52aXJv
bm1lbnQa2AEKEFNsc2FDb25maWdTb3VyY2USEAoDdXJpGAEgASgJUgN1cmkSVgoGZGlnZXN0
GAIgAygLMj4uZ3JhZmVhcy52MS5TbHNhUHJvdmVuYW5jZVplcm9Ud28uU2xzYUNvbmZpZ1Nv
dXJjZS5EaWdlc3RFbnRyeVIGZGlnZXN0Eh8KC2VudHJ5X3BvaW50GAMgASgJUgplbnRyeVBv
aW50GjkKC0RpZ2VzdEVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2
YWx1ZToCOAEayAIKDFNsc2FNZXRhZGF0YRIuChNidWlsZF9pbnZvY2F0aW9uX2lkGAEgASgJ
UhFidWlsZEludm9jYXRpb25JZBJEChBidWlsZF9zdGFydGVkX29uGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIOYnVpbGRTdGFydGVkT24SRgoRYnVpbGRfZmluaXNoZWRf
b24YAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg9idWlsZEZpbmlzaGVkT24S
VgoMY29tcGxldGVuZXNzGAQgASgLMjIuZ3JhZmVhcy52MS5TbHNhUHJvdmVuYW5jZVplcm9U
d28uU2xzYUNvbXBsZXRlbmVzc1IMY29tcGxldGVuZXNzEiIKDHJlcHJvZHVjaWJsZRgFIAEo
CFIMcmVwcm9kdWNpYmxlGnIKEFNsc2FDb21wbGV0ZW5lc3MSHgoKcGFyYW1ldGVycxgBIAEo
CFIKcGFyYW1ldGVycxIgCgtlbnZpcm9ubWVudBgCIAEoCFILZW52aXJvbm1lbnQSHAoJbWF0
ZXJpYWxzGAMgASgIUgltYXRlcmlhbHNCbQoNaW8uZ3JhZmVhcy52MUIaU2xzYVByb3ZlbmFu
Y2VaZXJvVHdvUHJvdG9QAVo4Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBp
cy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFKwxcKBhIEDgBRAQraBAoBDBIDDgASMs8EIENv
cHlyaWdodCAyMDIxIFRoZSBHcmFmZWFzIEF1dGhvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQu
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAEwoJCgIDABIDEgAmCgkKAgMBEgMTACkKCAoBCBIDFQBPCgkKAggLEgMVAE8KCAoBCBID
FgAiCgkKAggKEgMWACIKCAoBCBIDFwAmCgkKAggBEgMXACYKCAoBCBIDGAAhCgkKAggkEgMY
ACEKCAoBCBIDGQA7CgkKAggIEgMZADsKSQoCBAASBBsAUQEiPSBTZWUgZnVsbCBleHBsYW5h
dGlvbiBvZiBmaWVsZHMgYXQgc2xzYS5kZXYvcHJvdmVuYW5jZS92MC4yLgoKCgoDBAABEgMb
CB0KmwEKBAQAAwASBCACIgMajAEgSWRlbnRpZmllcyB0aGUgZW50aXR5IHRoYXQgZXhlY3V0
ZWQgdGhlIHJlY2lwZSwgd2hpY2ggaXMgdHJ1c3RlZCB0byBoYXZlCiBjb3JyZWN0bHkgcGVy
Zm9ybWVkIHRoZSBvcGVyYXRpb24gYW5kIHBvcHVsYXRlZCB0aGlzIHByb3ZlbmFuY2UuCgoM
CgUEAAMAARIDIAoVCg0KBgQAAwACABIDIQQSCg4KBwQAAwACAAUSAyEECgoOCgcEAAMAAgAB
EgMhCw0KDgoHBAADAAIAAxIDIRARCowBCgQEAAMBEgQmAikDGn4gVGhlIGNvbGxlY3Rpb24g
b2YgYXJ0aWZhY3RzIHRoYXQgaW5mbHVlbmNlZCB0aGUgYnVpbGQgaW5jbHVkaW5nIHNvdXJj
ZXMsCiBkZXBlbmRlbmNpZXMsIGJ1aWxkIHRvb2xzLCBiYXNlIGltYWdlcywgYW5kIHNvIG9u
LgoKDAoFBAADAQESAyYKFgoNCgYEAAMBAgASAycEEwoOCgcEAAMBAgAFEgMnBAoKDgoHBAAD
AQIAARIDJwsOCg4KBwQAAwECAAMSAycREgoNCgYEAAMBAgESAygEIwoOCgcEAAMBAgEGEgMo
BBcKDgoHBAADAQIBARIDKBgeCg4KBwQAAwECAQMSAyghIgo/CgQEAAMCEgQsAjADGjEgSWRl
bnRpZmllcyB0aGUgZXZlbnQgdGhhdCBraWNrZWQgb2ZmIHRoZSBidWlsZC4KCgwKBQQAAwIB
EgMsChgKDQoGBAADAgIAEgMtBCcKDgoHBAADAgIABhIDLQQUCg4KBwQAAwICAAESAy0VIgoO
CgcEAAMCAgADEgMtJSYKDQoGBAADAgIBEgMuBCoKDgoHBAADAgIBBhIDLgQaCg4KBwQAAwIC
AQESAy4bJQoOCgcEAAMCAgEDEgMuKCkKDQoGBAADAgICEgMvBCsKDgoHBAADAgICBhIDLwQa
Cg4KBwQAAwICAgESAy8bJgoOCgcEAAMCAgIDEgMvKSoKnwEKBAQAAwMSBDQCOAMakAEgRGVz
Y3JpYmVzIHdoZXJlIHRoZSBjb25maWcgZmlsZSB0aGF0IGtpY2tlZCBvZmYgdGhlIGJ1aWxk
IGNhbWUgZnJvbS4KIFRoaXMgaXMgZWZmZWN0aXZlbHkgYSBwb2ludGVyIHRvIHRoZSBzb3Vy
Y2Ugd2hlcmUgYnVpbGRDb25maWcgY2FtZSBmcm9tLgoKDAoFBAADAwESAzQKGgoNCgYEAAMD
AgASAzUEEwoOCgcEAAMDAgAFEgM1BAoKDgoHBAADAwIAARIDNQsOCg4KBwQAAwMCAAMSAzUR
EgoNCgYEAAMDAgESAzYEIwoOCgcEAAMDAgEGEgM2BBcKDgoHBAADAwIBARIDNhgeCg4KBwQA
AwMCAQMSAzYhIgoNCgYEAAMDAgISAzcEGwoOCgcEAAMDAgIFEgM3BAoKDgoHBAADAwICARID
NwsWCg4KBwQAAwMCAgMSAzcZGgouCgQEAAMEEgQ7AkEDGiAgT3RoZXIgcHJvcGVydGllcyBv
ZiB0aGUgYnVpbGQuCgoMCgUEAAMEARIDOwoWCg0KBgQAAwQCABIDPAQjCg4KBwQAAwQCAAUS
AzwECgoOCgcEAAMEAgABEgM8Cx4KDgoHBAADBAIAAxIDPCEiCg0KBgQAAwQCARIDPQQzCg4K
BwQAAwQCAQYSAz0EHQoOCgcEAAMEAgEBEgM9Hi4KDgoHBAADBAIBAxIDPTEyCg0KBgQAAwQC
AhIDPgQ0Cg4KBwQAAwQCAgYSAz4EHQoOCgcEAAMEAgIBEgM+Hi8KDgoHBAADBAICAxIDPjIz
Cg0KBgQAAwQCAxIDPwQmCg4KBwQAAwQCAwYSAz8EFAoOCgcEAAMEAgMBEgM/FSEKDgoHBAAD
BAIDAxIDPyQlCg0KBgQAAwQCBBIDQAQaCg4KBwQAAwQCBAUSA0AECAoOCgcEAAMEAgQBEgNA
CRUKDgoHBAADBAIEAxIDQBgZCmEKBAQAAwUSBEUCSQMaUyBJbmRpY2F0ZXMgdGhhdCB0aGUg
YnVpbGRlciBjbGFpbXMgY2VydGFpbiBmaWVsZHMgaW4gdGhpcyBtZXNzYWdlIHRvIGJlCiBj
b21wbGV0ZS4KCgwKBQQAAwUBEgNFChoKDQoGBAADBQIAEgNGBBgKDgoHBAADBQIABRIDRgQI
Cg4KBwQAAwUCAAESA0YJEwoOCgcEAAMFAgADEgNGFhcKDQoGBAADBQIBEgNHBBkKDgoHBAAD
BQIBBRIDRwQICg4KBwQAAwUCAQESA0cJFAoOCgcEAAMFAgEDEgNHFxgKDQoGBAADBQICEgNI
BBcKDgoHBAADBQICBRIDSAQICg4KBwQAAwUCAgESA0gJEgoOCgcEAAMFAgIDEgNIFRYKCwoE
BAACABIDSwIaCgwKBQQAAgAGEgNLAg0KDAoFBAACAAESA0sOFQoMCgUEAAIAAxIDSxgZCgsK
BAQAAgESA0wCGAoMCgUEAAIBBRIDTAIICgwKBQQAAgEBEgNMCRMKDAoFBAACAQMSA0wWFwoL
CgQEAAICEgNNAiAKDAoFBAACAgYSA00CEAoMCgUEAAICARIDTREbCgwKBQQAAgIDEgNNHh8K
CwoEBAACAxIDTgIqCgwKBQQAAgMGEgNOAhgKDAoFBAACAwESA04ZJQoMCgUEAAIDAxIDTigp
CgsKBAQAAgQSA08CHAoMCgUEAAIEBhIDTwIOCgwKBQQAAgQBEgNPDxcKDAoFBAACBAMSA08a
GwoLCgQEAAIFEgNQAiYKDAoFBAACBQQSA1ACCgoMCgUEAAIFBhIDUAsXCgwKBQQAAgUBEgNQ
GCEKDAoFBAACBQMSA1AkJWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo ===
    # Fields for SlsaProvenanceZeroTwo
    # Field: builder Type: 11 (.grafeas.v1.SlsaProvenanceZeroTwo.SlsaBuilder)
    # Field: build_type Type: 9 ()
    # Field: invocation Type: 11 (.grafeas.v1.SlsaProvenanceZeroTwo.SlsaInvocation)
    # Field: build_config Type: 11 (.google.protobuf.Struct)
    # Field: metadata Type: 11 (.grafeas.v1.SlsaProvenanceZeroTwo.SlsaMetadata)
    # Field: materials Type: 11 (.grafeas.v1.SlsaProvenanceZeroTwo.SlsaMaterial)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::SlsaProvenanceZeroTwo - Compiled Protocol Buffers messages for grafeas/v1/slsa_provenance_zero_two.proto

=head1 SYNOPSIS

    use Grafeas::V1::SlsaProvenanceZeroTwo;

    my $msg = Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo->new({
        builder => $builder,
        build_type => $build_type,
        invocation => $invocation,
        build_config => $build_config,
    });

    # Read or update a field
    my $val = $msg->builder();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/slsa_provenance_zero_two.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo

See full explanation of fields at slsa.dev/provenance/v0.2.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->builder() >> / C<< $msg->builder($value) >>

Type: C<Message> (L<Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaBuilder>)

=item * C<< $msg->build_type() >> / C<< $msg->build_type($value) >>

Type: C<String>

=item * C<< $msg->invocation() >> / C<< $msg->invocation($value) >>

Type: C<Message> (L<Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaInvocation>)

=item * C<< $msg->build_config() >> / C<< $msg->build_config($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMetadata>)

=item * C<< $msg->materials() >> / C<< $msg->materials($value) >>

Type: C<Message> (L<Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::SlsaProvenanceZeroTwo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
