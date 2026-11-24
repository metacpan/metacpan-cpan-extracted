package Google::Cloud::Apphub::V1::ExtendedMetadataSchema;

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
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvYXBwaHViL3YxL2V4dGVuZGVkX21ldGFkYXRhX3NjaGVtYS5wcm90
bxIWZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byLFAgoWRXh0ZW5kZWRNZXRhZGF0YVNj
aGVtYRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJAoLanNvbl9zY2hlbWEYAiABKAlCA+BB
A1IKanNvblNjaGVtYRIqCg5zY2hlbWFfdmVyc2lvbhgDIAEoA0ID4EEDUg1zY2hlbWFWZXJz
aW9uOr8B6kG7AQosYXBwaHViLmdvb2dsZWFwaXMuY29tL0V4dGVuZGVkTWV0YWRhdGFTY2hl
bWESWnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9leHRlbmRlZE1l
dGFkYXRhU2NoZW1hcy97ZXh0ZW5kZWRfbWV0YWRhdGFfc2NoZW1hfSoXZXh0ZW5kZWRNZXRh
ZGF0YVNjaGVtYXMyFmV4dGVuZGVkTWV0YWRhdGFTY2hlbWFCvQEKGmNvbS5nb29nbGUuY2xv
dWQuYXBwaHViLnYxQhtFeHRlbmRlZE1ldGFkYXRhU2NoZW1hUHJvdG9QAVoyY2xvdWQuZ29v
Z2xlLmNvbS9nby9hcHBodWIvYXBpdjEvYXBwaHVicGI7YXBwaHVicGKqAhZHb29nbGUuQ2xv
dWQuQXBwSHViLlYxygIWR29vZ2xlXENsb3VkXEFwcEh1YlxWMeoCGUdvb2dsZTo6Q2xvdWQ6
OkFwcEh1Yjo6VjFKogsKBhIEDgAyAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQAzCgkKAgglEgMV
ADMKCAoBCBIDFgBJCgkKAggLEgMWAEkKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA8
CgkKAggIEgMYADwKCAoBCBIDGQAzCgkKAggBEgMZADMKCAoBCBIDGgAzCgkKAggpEgMaADMK
CAoBCBIDGwAyCgkKAggtEgMbADIKaQoCBAASBB8AMgEaXSBFeHRlbmRlZE1ldGFkYXRhU2No
ZW1hIHJlcHJlc2VudHMgYSBzY2hlbWEgZm9yIGV4dGVuZGVkIG1ldGFkYXRhIG9mIGEgc2Vy
dmljZQogb3Igd29ya2xvYWQuCgoKCgMEAAESAx8IHgoLCgMEAAcSBCACJQQKDQoFBAAHnQgS
BCACJQQKjgEKBAQAAgASAyoCPRqAASBJZGVudGlmaWVyLiBSZXNvdXJjZSBuYW1lIG9mIHRo
ZSBzY2hlbWEuCiBGb3JtYXQ6CiBwcm9qZWN0cy88cHJvamVjdD4vbG9jYXRpb25zLzxsb2Nh
dGlvbj4vZXh0ZW5kZWRNZXRhZGF0YVNjaGVtYXMvPHNjaGVtYS1pZD4KCgwKBQQAAgAFEgMq
AggKDAoFBAACAAESAyoJDQoMCgUEAAIAAxIDKhARCgwKBQQAAgAIEgMqEjwKDwoIBAACAAic
CAASAyoTOwo4CgQEAAIBEgMtAkUaKyBPdXRwdXQgb25seS4gVGhlIEpTT04gc2NoZW1hIGFz
IGEgc3RyaW5nLgoKDAoFBAACAQUSAy0CCAoMCgUEAAIBARIDLQkUCgwKBQQAAgEDEgMtFxgK
DAoFBAACAQgSAy0ZRAoPCggEAAIBCJwIABIDLRpDCm0KBAQAAgISAzECRxpgIE91dHB1dCBv
bmx5LiBUaGUgdmVyc2lvbiBvZiB0aGUgc2NoZW1hLiBOZXcgdmVyc2lvbnMgYXJlIHJlcXVp
cmVkIHRvIGJlCiBiYWNrd2FyZHMgY29tcGF0aWJsZS4KCgwKBQQAAgIFEgMxAgcKDAoFBAAC
AgESAzEIFgoMCgUEAAICAxIDMRkaCgwKBQQAAgIIEgMxG0YKDwoIBAACAgicCAASAzEcRWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema ===
    # Fields for ExtendedMetadataSchema
    # Field: name Type: 9 ()
    # Field: json_schema Type: 9 ()
    # Field: schema_version Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::ExtendedMetadataSchema - Compiled Protocol Buffers messages for google/cloud/apphub/v1/extended_metadata_schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::ExtendedMetadataSchema;

    my $msg = Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema->new({
        name => $name,
        json_schema => $json_schema,
        schema_version => $schema_version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/extended_metadata_schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema

ExtendedMetadataSchema represents a schema for extended metadata of a service
or workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the schema.
Format:
projects/<project>/locations/<location>/extendedMetadataSchemas/<schema-id>

=item * C<< $msg->json_schema() >> / C<< $msg->json_schema($value) >>

Type: C<String>

Output only. The JSON schema as a string.

=item * C<< $msg->schema_version() >> / C<< $msg->schema_version($value) >>

Type: C<Int64>

Output only. The version of the schema. New versions are required to be
backwards compatible.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::ExtendedMetadataSchema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
