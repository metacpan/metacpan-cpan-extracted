package Google::Cloud::Automl::V1beta1::TableSpec;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Automl::V1beta1::Io };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGFibGVfc3BlYy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiRnb29n
bGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvaW8ucHJvdG8ikwMKCVRhYmxlU3BlYxISCgRuYW1l
GAEgASgJUgRuYW1lEi0KE3RpbWVfY29sdW1uX3NwZWNfaWQYAiABKAlSEHRpbWVDb2x1bW5T
cGVjSWQSGwoJcm93X2NvdW50GAMgASgDUghyb3dDb3VudBImCg92YWxpZF9yb3dfY291bnQY
BCABKANSDXZhbGlkUm93Q291bnQSIQoMY29sdW1uX2NvdW50GAcgASgDUgtjb2x1bW5Db3Vu
dBJNCg1pbnB1dF9jb25maWdzGAUgAygLMiguZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGEx
LklucHV0Q29uZmlnUgxpbnB1dENvbmZpZ3MSEgoEZXRhZxgGIAEoCVIEZXRhZzp46kF1Ch9h
dXRvbWwuZ29vZ2xlYXBpcy5jb20vVGFibGVTcGVjElJwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vZGF0YXNldHMve2RhdGFzZXR9L3RhYmxlU3BlY3Mve3RhYmxl
X3NwZWN9QpsBCh9jb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExUAFaN2Nsb3VkLmdv
b2dsZS5jb20vZ28vYXV0b21sL2FwaXYxYmV0YTEvYXV0b21scGI7YXV0b21scGLKAhtHb29n
bGVcQ2xvdWRcQXV0b01sXFYxYmV0YTHqAh5Hb29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxYmV0
YTFK2BUKBhIEDgBMAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJAoJCgIDABIDEgAjCgkKAgMBEgMTAC4KCAoBCBIDFQBOCgkKAggLEgMVAE4KCAoBCBID
FgAiCgkKAggKEgMWACIKCAoBCBIDFwA4CgkKAggBEgMXADgKCAoBCBIDGAA4CgkKAggpEgMY
ADgKCAoBCBIDGQA3CgkKAggtEgMZADcK5wMKAgQAEgQkAEwBGtoDIEEgc3BlY2lmaWNhdGlv
biBvZiBhIHJlbGF0aW9uYWwgdGFibGUuCiBUaGUgdGFibGUncyBzY2hlbWEgaXMgcmVwcmVz
ZW50ZWQgdmlhIGl0cyBjaGlsZCBjb2x1bW4gc3BlY3MuIEl0IGlzCiBwcmUtcG9wdWxhdGVk
IGFzIHBhcnQgb2YgSW1wb3J0RGF0YSBieSBzY2hlbWEgaW5mZXJlbmNlIGFsZ29yaXRobSwg
dGhlCiB2ZXJzaW9uIG9mIHdoaWNoIGlzIGEgcmVxdWlyZWQgcGFyYW1ldGVyIG9mIEltcG9y
dERhdGEgSW5wdXRDb25maWcuCiBOb3RlOiBXaGlsZSB3b3JraW5nIHdpdGggYSB0YWJsZSwg
YXQgdGltZXMgdGhlIHNjaGVtYSBtYXkgYmUKIGluY29uc2lzdGVudCB3aXRoIHRoZSBkYXRh
IGluIHRoZSB0YWJsZSAoZS5nLiBzdHJpbmcgaW4gYSBGTE9BVDY0IGNvbHVtbikuCiBUaGUg
Y29uc2lzdGVuY3kgdmFsaWRhdGlvbiBpcyBkb25lIHVwb24gY3JlYXRpb24gb2YgYSBtb2Rl
bC4KIFVzZWQgYnk6CiAgICogICBUYWJsZXMKCgoKAwQAARIDJAgRCgsKAwQABxIEJQIoBAoN
CgUEAAedCBIEJQIoBAqrAQoEBAACABIDLgISGp0BIE91dHB1dCBvbmx5LiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgdGFibGUgc3BlYy4KIEZvcm06CgogYHByb2plY3RzL3twcm9qZWN0
X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9kYXRhc2V0cy97ZGF0YXNldF9pZH0vdGFi
bGVTcGVjcy97dGFibGVfc3BlY19pZH1gCgoMCgUEAAIABRIDLgIICgwKBQQAAgABEgMuCQ0K
DAoFBAACAAMSAy4QEQr2AwoEBAACARIDOAIhGugDIGNvbHVtbl9zcGVjX2lkIG9mIHRoZSB0
aW1lIGNvbHVtbi4gT25seSB1c2VkIGlmIHRoZSBwYXJlbnQgZGF0YXNldCdzCiBtbF91c2Vf
Y29sdW1uX3NwZWNfaWQgaXMgbm90IHNldC4gVXNlZCB0byBzcGxpdCByb3dzIGludG8gVFJB
SU4sIFZBTElEQVRFCiBhbmQgVEVTVCBzZXRzIHN1Y2ggdGhhdCBvbGRlc3Qgcm93cyBnbyB0
byBUUkFJTiBzZXQsIG5ld2VzdCB0byBURVNULCBhbmQKIHRob3NlIGluIGJldHdlZW4gdG8g
VkFMSURBVEUuCiBSZXF1aXJlZCB0eXBlOiBUSU1FU1RBTVAuCiBJZiBib3RoIHRoaXMgY29s
dW1uIGFuZCBtbF91c2VfY29sdW1uIGFyZSBub3Qgc2V0LCB0aGVuIE1MIHVzZSBvZiBhbGwg
cm93cwogd2lsbCBiZSBhc3NpZ25lZCBieSBBdXRvTUwuIE5PVEU6IFVwZGF0ZXMgb2YgdGhp
cyBmaWVsZCB3aWxsIGluc3RhbnRseQogYWZmZWN0IGFueSBvdGhlciB1c2VycyBjb25jdXJy
ZW50bHkgd29ya2luZyB3aXRoIHRoZSBkYXRhc2V0LgoKDAoFBAACAQUSAzgCCAoMCgUEAAIB
ARIDOAkcCgwKBQQAAgEDEgM4HyAKTAoEBAACAhIDOwIWGj8gT3V0cHV0IG9ubHkuIFRoZSBu
dW1iZXIgb2Ygcm93cyAoaS5lLiBleGFtcGxlcykgaW4gdGhlIHRhYmxlLgoKDAoFBAACAgUS
AzsCBwoMCgUEAAICARIDOwgRCgwKBQQAAgIDEgM7FBUKeQoEBAACAxIDPwIcGmwgT3V0cHV0
IG9ubHkuIFRoZSBudW1iZXIgb2YgdmFsaWQgcm93cyAoaS5lLiB3aXRob3V0IHZhbHVlcyB0
aGF0IGRvbid0IG1hdGNoCiBEYXRhVHlwZS1zIG9mIHRoZWlyIGNvbHVtbnMpLgoKDAoFBAAC
AwUSAz8CBwoMCgUEAAIDARIDPwgXCgwKBQQAAgMDEgM/GhsKawoEBAACBBIDQwIZGl4gT3V0
cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgY29sdW1ucyBvZiB0aGUgdGFibGUuIFRoYXQgaXMs
IHRoZSBudW1iZXIgb2YKIGNoaWxkIENvbHVtblNwZWMtcy4KCgwKBQQAAgQFEgNDAgcKDAoF
BAACBAESA0MIFAoMCgUEAAIEAxIDQxcYCmwKBAQAAgUSA0cCKRpfIE91dHB1dCBvbmx5LiBJ
bnB1dCBjb25maWdzIHZpYSB3aGljaCBkYXRhIGN1cnJlbnRseSByZXNpZGluZyBpbiB0aGUg
dGFibGUKIGhhZCBiZWVuIGltcG9ydGVkLgoKDAoFBAACBQQSA0cCCgoMCgUEAAIFBhIDRwsW
CgwKBQQAAgUBEgNHFyQKDAoFBAACBQMSA0cnKAp1CgQEAAIGEgNLAhIaaCBVc2VkIHRvIHBl
cmZvcm0gY29uc2lzdGVudCByZWFkLW1vZGlmeS13cml0ZSB1cGRhdGVzLiBJZiBub3Qgc2V0
LCBhIGJsaW5kCiAib3ZlcndyaXRlIiB1cGRhdGUgaGFwcGVucy4KCgwKBQQAAgYFEgNLAggK
DAoFBAACBgESA0sJDQoMCgUEAAIGAxIDSxARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::TableSpec::TableSpec ===
    # Fields for TableSpec
    # Field: name Type: 9 ()
    # Field: time_column_spec_id Type: 9 ()
    # Field: row_count Type: 3 ()
    # Field: valid_row_count Type: 3 ()
    # Field: column_count Type: 3 ()
    # Field: input_configs Type: 11 (.google.cloud.automl.v1beta1.InputConfig)
    # Field: etag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::TableSpec - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/table_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::TableSpec;

    my $msg = Google::Cloud::Automl::V1beta1::TableSpec::TableSpec->new({
        name => $name,
        time_column_spec_id => $time_column_spec_id,
        row_count => $row_count,
        valid_row_count => $valid_row_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::TableSpec::TableSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/table_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::TableSpec::TableSpec

A specification of a relational table.
The table's schema is represented via its child column specs. It is
pre-populated as part of ImportData by schema inference algorithm, the
version of which is a required parameter of ImportData InputConfig.
Note: While working with a table, at times the schema may be
inconsistent with the data in the table (e.g. string in a FLOAT64 column).
The consistency validation is done upon creation of a model.
Used by:
  *   Tables

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the table spec.
Form:

`projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/tableSpecs/{table_spec_id}`

=item * C<< $msg->time_column_spec_id() >> / C<< $msg->time_column_spec_id($value) >>

Type: C<String>

column_spec_id of the time column. Only used if the parent dataset's
ml_use_column_spec_id is not set. Used to split rows into TRAIN, VALIDATE
and TEST sets such that oldest rows go to TRAIN set, newest to TEST, and
those in between to VALIDATE.
Required type: TIMESTAMP.
If both this column and ml_use_column are not set, then ML use of all rows
will be assigned by AutoML. NOTE: Updates of this field will instantly
affect any other users concurrently working with the dataset.

=item * C<< $msg->row_count() >> / C<< $msg->row_count($value) >>

Type: C<Int64>

Output only. The number of rows (i.e. examples) in the table.

=item * C<< $msg->valid_row_count() >> / C<< $msg->valid_row_count($value) >>

Type: C<Int64>

Output only. The number of valid rows (i.e. without values that don't match
DataType-s of their columns).

=item * C<< $msg->column_count() >> / C<< $msg->column_count($value) >>

Type: C<Int64>

Output only. The number of columns of the table. That is, the number of
child ColumnSpec-s.

=item * C<< $msg->input_configs() >> / C<< $msg->input_configs($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Io::InputConfig>)

Output only. Input configs via which data currently residing in the table
had been imported.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Used to perform consistent read-modify-write updates. If not set, a blind
"overwrite" update happens.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::TableSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
