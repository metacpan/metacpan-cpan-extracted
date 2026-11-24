package Google::Cloud::Dialogflow::V2beta1::Gcs;

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
Cilnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2djcy5wcm90bxIfZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
byIlCgpHY3NTb3VyY2VzEhcKBHVyaXMYAiADKAlCA+BBAlIEdXJpcyIdCglHY3NTb3VyY2US
EAoDdXJpGAEgASgJUgN1cmkiIgoOR2NzRGVzdGluYXRpb24SEAoDdXJpGAEgASgJUgN1cmlC
nQEKI2NvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExQghHY3NQcm90b1ABWkNj
bG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRhMS9kaWFsb2dmbG93cGI7
ZGlhbG9nZmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkJldGExSuMN
CgYSBA4ANQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgK
CQoCAwASAxIAKQoICgEIEgMUADwKCQoCCCUSAxQAPAoICgEIEgMVAFoKCQoCCAsSAxUAWgoI
CgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACkKCQoCCAgSAxcAKQoICgEIEgMYADwKCQoC
CAESAxgAPAoICgEIEgMZACAKCQoCCCQSAxkAIAo8CgIEABIEHAAiARowIEdvb2dsZSBDbG91
ZCBTdG9yYWdlIGxvY2F0aW9ucyBmb3IgdGhlIGlucHV0cy4KCgoKAwQAARIDHAgSCroBCgQE
AAIAEgMhAkQarAEgUmVxdWlyZWQuIEdvb2dsZSBDbG91ZCBTdG9yYWdlIFVSSXMgZm9yIHRo
ZSBpbnB1dHMuIEEgVVJJIGlzIG9mIHRoZQogZm9ybToKIGBnczovL2J1Y2tldC9vYmplY3Qt
cHJlZml4LW9yLW5hbWVgCiBXaGV0aGVyIGEgcHJlZml4IG9yIG5hbWUgaXMgdXNlZCBkZXBl
bmRzIG9uIHRoZSB1c2UgY2FzZS4KCgwKBQQAAgAEEgMhAgoKDAoFBAACAAUSAyELEQoMCgUE
AAIAARIDIRIWCgwKBQQAAgADEgMhGRoKDAoFBAACAAgSAyEbQwoPCggEAAIACJwIABIDIRxC
Cj0KAgQBEgQlACsBGjEgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gZm9yIHNpbmds
ZSBpbnB1dC4KCgoKAwQBARIDJQgRCr4BCgQEAQIAEgMqAhEasAEgUmVxdWlyZWQuIFRoZSBH
b29nbGUgQ2xvdWQgU3RvcmFnZSBVUklzIGZvciB0aGUgaW5wdXRzLiBBIFVSSSBpcyBvZiB0
aGUKIGZvcm06CiBgZ3M6Ly9idWNrZXQvb2JqZWN0LXByZWZpeC1vci1uYW1lYAogV2hldGhl
ciBhIHByZWZpeCBvciBuYW1lIGlzIHVzZWQgZGVwZW5kcyBvbiB0aGUgdXNlIGNhc2UuCgoM
CgUEAQIABRIDKgIICgwKBQQBAgABEgMqCQwKDAoFBAECAAMSAyoPEAo7CgIEAhIELgA1ARov
IEdvb2dsZSBDbG91ZCBTdG9yYWdlIGxvY2F0aW9uIGZvciB0aGUgb3V0cHV0LgoKCgoDBAIB
EgMuCBYK/wEKBAQCAgASAzQCERrxASBSZXF1aXJlZC4gVGhlIEdvb2dsZSBDbG91ZCBTdG9y
YWdlIFVSSXMgZm9yIHRoZSBvdXRwdXQuIEEgVVJJIGlzIG9mIHRoZQogZm9ybToKIGBnczov
L2J1Y2tldC9vYmplY3QtcHJlZml4LW9yLW5hbWVgCiBXaGV0aGVyIGEgcHJlZml4IG9yIG5h
bWUgaXMgdXNlZCBkZXBlbmRzIG9uIHRoZSB1c2UgY2FzZS4gVGhlIHJlcXVlc3RpbmcKIHVz
ZXIgbXVzdCBoYXZlICJ3cml0ZS1wZXJtaXNzaW9uIiB0byB0aGUgYnVja2V0LgoKDAoFBAIC
AAUSAzQCCAoMCgUEAgIAARIDNAkMCgwKBQQCAgADEgM0DxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources ===
    # Fields for GcsSources
    # Field: uris Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSource ===
    # Fields for GcsSource
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Gcs::GcsDestination ===
    # Fields for GcsDestination
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Gcs - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/gcs.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Gcs;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources->new({
        uris => $uris,
    });

    # Read or update a field
    my $val = $msg->uris();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/gcs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources

Google Cloud Storage locations for the inputs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uris() >> / C<< $msg->uris($value) >>

Type: C<String>

Required. Google Cloud Storage URIs for the inputs. A URI is of the
form:
`gs://bucket/object-prefix-or-name`
Whether a prefix or name is used depends on the use case.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSource

Google Cloud Storage location for single input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The Google Cloud Storage URIs for the inputs. A URI is of the
form:
`gs://bucket/object-prefix-or-name`
Whether a prefix or name is used depends on the use case.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Gcs::GcsDestination

Google Cloud Storage location for the output.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The Google Cloud Storage URIs for the output. A URI is of the
form:
`gs://bucket/object-prefix-or-name`
Whether a prefix or name is used depends on the use case. The requesting
user must have "write-permission" to the bucket.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Gcs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
