package Google::Cloud::Datacatalog::V1beta1::Schema;

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
Ci1nb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS9zY2hlbWEucHJvdG8SIGdvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvIlcKBlNjaGVtYRJNCgdjb2x1bW5zGAIgAygLMi4uZ29vZ2xlLmNsb3VkLmRhdGFj
YXRhbG9nLnYxYmV0YTEuQ29sdW1uU2NoZW1hQgPgQQJSB2NvbHVtbnMi2QEKDENvbHVtblNj
aGVtYRIbCgZjb2x1bW4YBiABKAlCA+BBAlIGY29sdW1uEhcKBHR5cGUYASABKAlCA+BBAlIE
dHlwZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhIXCgRtb2RlGAMg
ASgJQgPgQQFSBG1vZGUSUwoKc3ViY29sdW1ucxgHIAMoCzIuLmdvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MWJldGExLkNvbHVtblNjaGVtYUID4EEBUgpzdWJjb2x1bW5zQtwBCiRjb20u
Z29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTFQAVpGY2xvdWQuZ29vZ2xlLmNvbS9n
by9kYXRhY2F0YWxvZy9hcGl2MWJldGExL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoC
IEdvb2dsZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMUJldGExygIgR29vZ2xlXENsb3VkXERhdGFD
YXRhbG9nXFYxYmV0YTHqAiNHb29nbGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFiZXRhMUrE
DwoGEgQOADYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAp
CgkKAgMAEgMSACkKCAoBCBIDFAA9CgkKAgglEgMUAD0KCAoBCBIDFQBdCgkKAggLEgMVAF0K
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA9CgkKAggBEgMXAD0KCAoBCBIDGAA9CgkK
AggpEgMYAD0KCAoBCBIDGQA8CgkKAggtEgMZADwKSgoCBAASBBwAIAEaPiBSZXByZXNlbnRz
IGEgc2NoZW1hIChlLmcuIEJpZ1F1ZXJ5LCBHb29nbGVTUUwsIEF2cm8gc2NoZW1hKS4KCgoK
AwQAARIDHAgOCmoKBAQAAgASAx8CTRpdIFJlcXVpcmVkLiBTY2hlbWEgb2YgY29sdW1ucy4g
QSBtYXhpbXVtIG9mIDEwLDAwMCBjb2x1bW5zIGFuZCBzdWItY29sdW1ucwogY2FuIGJlIHNw
ZWNpZmllZC4KCgwKBQQAAgAEEgMfAgoKDAoFBAACAAYSAx8LFwoMCgUEAAIAARIDHxgfCgwK
BQQAAgADEgMfIiMKDAoFBAACAAgSAx8kTAoPCggEAAIACJwIABIDHyVLCmgKAgQBEgQkADYB
GlwgUmVwcmVzZW50YXRpb24gb2YgYSBjb2x1bW4gd2l0aGluIGEgc2NoZW1hLiBDb2x1bW5z
IGNvdWxkIGJlIG5lc3RlZCBpbnNpZGUKIG90aGVyIGNvbHVtbnMuCgoKCgMEAQESAyQIFAos
CgQEAQIAEgMmAj0aHyBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgY29sdW1uLgoKDAoFBAECAAUS
AyYCCAoMCgUEAQIAARIDJgkPCgwKBQQBAgADEgMmEhMKDAoFBAECAAgSAyYUPAoPCggEAQIA
CJwIABIDJhU7CiwKBAQBAgESAykCOxofIFJlcXVpcmVkLiBUeXBlIG9mIHRoZSBjb2x1bW4u
CgoMCgUEAQIBBRIDKQIICgwKBQQBAgEBEgMpCQ0KDAoFBAECAQMSAykQEQoMCgUEAQIBCBID
KRI6Cg8KCAQBAgEInAgAEgMpEzkKVQoEBAECAhIDLAJCGkggT3B0aW9uYWwuIERlc2NyaXB0
aW9uIG9mIHRoZSBjb2x1bW4uIERlZmF1bHQgdmFsdWUgaXMgYW4gZW1wdHkgc3RyaW5nLgoK
DAoFBAECAgUSAywCCAoMCgUEAQICARIDLAkUCgwKBQQBAgIDEgMsFxgKDAoFBAECAggSAywZ
QQoPCggEAQICCJwIABIDLBpACsoBCgQEAQIDEgMxAjsavAEgT3B0aW9uYWwuIEEgY29sdW1u
J3MgbW9kZSBpbmRpY2F0ZXMgd2hldGhlciB0aGUgdmFsdWVzIGluIHRoaXMgY29sdW1uIGFy
ZQogcmVxdWlyZWQsIG51bGxhYmxlLCBldGMuIE9ubHkgYE5VTExBQkxFYCwgYFJFUVVJUkVE
YCBhbmQgYFJFUEVBVEVEYCBhcmUKIHN1cHBvcnRlZC4gRGVmYXVsdCBtb2RlIGlzIGBOVUxM
QUJMRWAuCgoMCgUEAQIDBRIDMQIICgwKBQQBAgMBEgMxCQ0KDAoFBAECAwMSAzEQEQoMCgUE
AQIDCBIDMRI6Cg8KCAQBAgMInAgAEgMxEzkKXAoEBAECBBIDNQJQGk8gT3B0aW9uYWwuIFNj
aGVtYSBvZiBzdWItY29sdW1ucy4gQSBjb2x1bW4gY2FuIGhhdmUgemVybyBvciBtb3JlCiBz
dWItY29sdW1ucy4KCgwKBQQBAgQEEgM1AgoKDAoFBAECBAYSAzULFwoMCgUEAQIEARIDNRgi
CgwKBQQBAgQDEgM1JSYKDAoFBAECBAgSAzUnTwoPCggEAQIECJwIABIDNShOYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Schema::Schema ===
    # Fields for Schema
    # Field: columns Type: 11 (.google.cloud.datacatalog.v1beta1.ColumnSchema)

# === Message: Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema ===
    # Fields for ColumnSchema
    # Field: column Type: 9 ()
    # Field: type Type: 9 ()
    # Field: description Type: 9 ()
    # Field: mode Type: 9 ()
    # Field: subcolumns Type: 11 (.google.cloud.datacatalog.v1beta1.ColumnSchema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Schema - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Schema;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Schema::Schema->new({
        columns => $columns,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Schema::Schema

Represents a schema (e.g. BigQuery, GoogleSQL, Avro schema).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema>)

Required. Schema of columns. A maximum of 10,000 columns and sub-columns
can be specified.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema

Representation of a column within a schema. Columns could be nested inside
other columns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<String>

Required. Name of the column.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. Type of the column.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the column. Default value is an empty string.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<String>

Optional. A column's mode indicates whether the values in this column are
required, nullable, etc. Only `NULLABLE`, `REQUIRED` and `REPEATED` are
supported. Default mode is `NULLABLE`.

=item * C<< $msg->subcolumns() >> / C<< $msg->subcolumns($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema>)

Optional. Schema of sub-columns. A column can have zero or more
sub-columns.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
