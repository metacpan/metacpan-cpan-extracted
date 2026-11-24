package Google::Cloud::Automl::V1beta1::ColumnSpec;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Automl::V1beta1::DataStats };
    eval { require Google::Cloud::Automl::V1beta1::DataTypes };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvY29sdW1uX3NwZWMucHJvdG8SG2dvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29v
Z2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2RhdGFfc3RhdHMucHJvdG8aLGdvb2dsZS9jbG91
ZC9hdXRvbWwvdjFiZXRhMS9kYXRhX3R5cGVzLnByb3RvIoAFCgpDb2x1bW5TcGVjEhIKBG5h
bWUYASABKAlSBG5hbWUSQgoJZGF0YV90eXBlGAIgASgLMiUuZ29vZ2xlLmNsb3VkLmF1dG9t
bC52MWJldGExLkRhdGFUeXBlUghkYXRhVHlwZRIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rp
c3BsYXlOYW1lEkUKCmRhdGFfc3RhdHMYBCABKAsyJi5nb29nbGUuY2xvdWQuYXV0b21sLnYx
YmV0YTEuRGF0YVN0YXRzUglkYXRhU3RhdHMSbgoWdG9wX2NvcnJlbGF0ZWRfY29sdW1ucxgF
IAMoCzI4Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Db2x1bW5TcGVjLkNvcnJlbGF0
ZWRDb2x1bW5SFHRvcENvcnJlbGF0ZWRDb2x1bW5zEhIKBGV0YWcYBiABKAlSBGV0YWcalAEK
EENvcnJlbGF0ZWRDb2x1bW4SJAoOY29sdW1uX3NwZWNfaWQYASABKAlSDGNvbHVtblNwZWNJ
ZBJaChFjb3JyZWxhdGlvbl9zdGF0cxgCIAEoCzItLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFi
ZXRhMS5Db3JyZWxhdGlvblN0YXRzUhBjb3JyZWxhdGlvblN0YXRzOpQB6kGQAQogYXV0b21s
Lmdvb2dsZWFwaXMuY29tL0NvbHVtblNwZWMSbHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNldH0vdGFibGVTcGVjcy97dGFibGVfc3Bl
Y30vY29sdW1uU3BlY3Mve2NvbHVtbl9zcGVjfUKbAQofY29tLmdvb2dsZS5jbG91ZC5hdXRv
bWwudjFiZXRhMVABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJldGExL2F1
dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIeR29vZ2xl
OjpDbG91ZDo6QXV0b01MOjpWMWJldGExSpMUCgYSBA4ATAEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAIwoJCgIDARIDEwA2CgkKAgMC
EgMUADYKCAoBCBIDFgBOCgkKAggLEgMWAE4KCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBID
GAA4CgkKAggBEgMYADgKCAoBCBIDGQA4CgkKAggpEgMZADgKCAoBCBIDGgA3CgkKAggtEgMa
ADcKvwEKAgQAEgQgAEwBGrIBIEEgcmVwcmVzZW50YXRpb24gb2YgYSBjb2x1bW4gaW4gYSBy
ZWxhdGlvbmFsIHRhYmxlLiBXaGVuIGxpc3RpbmcgdGhlbSwgY29sdW1uIHNwZWNzIGFyZSBy
ZXR1cm5lZCBpbiB0aGUgc2FtZSBvcmRlciBpbiB3aGljaCB0aGV5IHdlcmUKIGdpdmVuIG9u
IGltcG9ydCAuCiBVc2VkIGJ5OgogICAqICAgVGFibGVzCgoKCgMEAAESAyAIEgoLCgMEAAcS
BCECJAQKDQoFBAAHnQgSBCECJAQKbgoEBAADABIEKAIvAxpgIElkZW50aWZpZXMgdGhlIHRh
YmxlJ3MgY29sdW1uLCBhbmQgaXRzIGNvcnJlbGF0aW9uIHdpdGggdGhlIGNvbHVtbiB0aGlz
CiBDb2x1bW5TcGVjIGRlc2NyaWJlcy4KCgwKBQQAAwABEgMoChoKeAoGBAADAAIAEgMrBB4a
aSBUaGUgY29sdW1uX3NwZWNfaWQgb2YgdGhlIGNvcnJlbGF0ZWQgY29sdW1uLCB3aGljaCBi
ZWxvbmdzIHRvIHRoZSBzYW1lCiB0YWJsZSBhcyB0aGUgaW4tY29udGV4dCBjb2x1bW4uCgoO
CgcEAAMAAgAFEgMrBAoKDgoHBAADAAIAARIDKwsZCg4KBwQAAwACAAMSAyscHQpECgYEAAMA
AgESAy4EKxo1IENvcnJlbGF0aW9uIGJldHdlZW4gdGhpcyBhbmQgdGhlIGluLWNvbnRleHQg
Y29sdW1uLgoKDgoHBAADAAIBBhIDLgQUCg4KBwQAAwACAQESAy4VJgoOCgcEAAMAAgEDEgMu
KSoKygEKBAQAAgASAzUCEhq8ASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIGNvbHVtbiBzcGVjcy4KIEZvcm06CgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9uX2lkfS9kYXRhc2V0cy97ZGF0YXNldF9pZH0vdGFibGVTcGVjcy97
dGFibGVfc3BlY19pZH0vY29sdW1uU3BlY3Mve2NvbHVtbl9zcGVjX2lkfWAKCgwKBQQAAgAF
EgM1AggKDAoFBAACAAESAzUJDQoMCgUEAAIAAxIDNRARCj4KBAQAAgESAzgCGRoxIFRoZSBk
YXRhIHR5cGUgb2YgZWxlbWVudHMgc3RvcmVkIGluIHRoZSBjb2x1bW4uCgoMCgUEAAIBBhID
OAIKCgwKBQQAAgEBEgM4CxQKDAoFBAACAQMSAzgXGAqWAgoEBAACAhIDPgIaGogCIE91dHB1
dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUgY29sdW1uIHRvIHNob3cgaW4gdGhlIGludGVyZmFj
ZS4gVGhlIG5hbWUgY2FuCiBiZSB1cCB0byAxMDAgY2hhcmFjdGVycyBsb25nIGFuZCBjYW4g
Y29uc2lzdCBvbmx5IG9mIEFTQ0lJIExhdGluIGxldHRlcnMKIEEtWiBhbmQgYS16LCBBU0NJ
SSBkaWdpdHMgMC05LCB1bmRlcnNjb3JlcyhfKSwgYW5kIGZvcndhcmQgc2xhc2hlcygvKSwg
YW5kCiBtdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIgb3IgYSBkaWdpdC4KCgwKBQQAAgIFEgM+
AggKDAoFBAACAgESAz4JFQoMCgUEAAICAxIDPhgZCuoBCgQEAAIDEgNEAhsa3AEgT3V0cHV0
IG9ubHkuIFN0YXRzIG9mIHRoZSBzZXJpZXMgb2YgdmFsdWVzIGluIHRoZSBjb2x1bW4uCiBU
aGlzIGZpZWxkIG1heSBiZSBzdGFsZSwgc2VlIHRoZSBhbmNlc3RvcidzCiBEYXRhc2V0LnRh
Ymxlc19kYXRhc2V0X21ldGFkYXRhLnN0YXRzX3VwZGF0ZV90aW1lIGZpZWxkCiBmb3IgdGhl
IHRpbWVzdGFtcCBhdCB3aGljaCB0aGVzZSBzdGF0cyB3ZXJlIGxhc3QgdXBkYXRlZC4KCgwK
BQQAAgMGEgNEAgsKDAoFBAACAwESA0QMFgoMCgUEAAIDAxIDRBkaChoKBAQAAgQSA0cCNxoN
IERlcHJlY2F0ZWQuCgoMCgUEAAIEBBIDRwIKCgwKBQQAAgQGEgNHCxsKDAoFBAACBAESA0cc
MgoMCgUEAAIEAxIDRzU2CnUKBAQAAgUSA0sCEhpoIFVzZWQgdG8gcGVyZm9ybSBjb25zaXN0
ZW50IHJlYWQtbW9kaWZ5LXdyaXRlIHVwZGF0ZXMuIElmIG5vdCBzZXQsIGEgYmxpbmQKICJv
dmVyd3JpdGUiIHVwZGF0ZSBoYXBwZW5zLgoKDAoFBAACBQUSA0sCCAoMCgUEAAIFARIDSwkN
CgwKBQQAAgUDEgNLEBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec ===
    # Fields for ColumnSpec
    # Field: name Type: 9 ()
    # Field: data_type Type: 11 (.google.cloud.automl.v1beta1.DataType)
    # Field: display_name Type: 9 ()
    # Field: data_stats Type: 11 (.google.cloud.automl.v1beta1.DataStats)
    # Field: top_correlated_columns Type: 11 (.google.cloud.automl.v1beta1.ColumnSpec.CorrelatedColumn)
    # Field: etag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::ColumnSpec - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/column_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::ColumnSpec;

    my $msg = Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec->new({
        name => $name,
        data_type => $data_type,
        display_name => $display_name,
        data_stats => $data_stats,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/column_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec

A representation of a column in a relational table. When listing them, column specs are returned in the same order in which they were
given on import .
Used by:
  *   Tables

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the column specs.
Form:

`projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/tableSpecs/{table_spec_id}/columnSpecs/{column_spec_id}`

=item * C<< $msg->data_type() >> / C<< $msg->data_type($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataTypes::DataType>)

The data type of elements stored in the column.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The name of the column to show in the interface. The name can
be up to 100 characters long and can consist only of ASCII Latin letters
A-Z and a-z, ASCII digits 0-9, underscores(_), and forward slashes(/), and
must start with a letter or a digit.

=item * C<< $msg->data_stats() >> / C<< $msg->data_stats($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataStats::DataStats>)

Output only. Stats of the series of values in the column.
This field may be stale, see the ancestor's
Dataset.tables_dataset_metadata.stats_update_time field
for the timestamp at which these stats were last updated.

=item * C<< $msg->top_correlated_columns() >> / C<< $msg->top_correlated_columns($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::ColumnSpec::ColumnSpec::CorrelatedColumn>)

Deprecated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Used to perform consistent read-modify-write updates. If not set, a blind
"overwrite" update happens.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::ColumnSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
