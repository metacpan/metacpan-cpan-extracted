package Google::Cloud::Securitycenter::V1::BigqueryExport;

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
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYmlncXVlcnlfZXhwb3J0LnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8iggUKDkJpZ1F1ZXJ5RXhwb3J0EhIKBG5hbWUYASABKAlSBG5h
bWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEhYKBmZpbHRlchgDIAEoCVIG
ZmlsdGVyEhgKB2RhdGFzZXQYBCABKAlSB2RhdGFzZXQSQAoLY3JlYXRlX3RpbWUYBSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRl
X3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRp
bWUSMQoSbW9zdF9yZWNlbnRfZWRpdG9yGAcgASgJQgPgQQNSEG1vc3RSZWNlbnRFZGl0b3IS
IQoJcHJpbmNpcGFsGAggASgJQgPgQQNSCXByaW5jaXBhbBJJCh5kZWxldGlvbl9ub3RpZmlj
YXRpb25zX2VuYWJsZWQYCSABKAhCA+BBAVIcZGVsZXRpb25Ob3RpZmljYXRpb25zRW5hYmxl
ZDriAepB3gEKLHNlY3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL0JpZ1F1ZXJ5RXhwb3J0
EjVvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2JpZ1F1ZXJ5RXhwb3J0cy97ZXhwb3J0
fRIpZm9sZGVycy97Zm9sZGVyfS9iaWdRdWVyeUV4cG9ydHMve2V4cG9ydH0SK3Byb2plY3Rz
L3twcm9qZWN0fS9iaWdRdWVyeUV4cG9ydHMve2V4cG9ydH0qD2JpZ1F1ZXJ5RXhwb3J0czIO
YmlnUXVlcnlFeHBvcnRC7QEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFC
E0JpZ1F1ZXJ5RXhwb3J0UHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNl
bnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUu
Q2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJc
VjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFK5R0KBhIEDgBsAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADsKCQoCCCUSAxYAOwoICgEIEgMXAGEKCQoC
CAsSAxcAYQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADQKCQoCCAgSAxkANAoICgEI
EgMaADsKCQoCCAESAxoAOwoICgEIEgMbADsKCQoCCCkSAxsAOwoICgEIEgMcADoKCQoCCC0S
AxwAOgpGCgIEABIEHwBsARo6IENvbmZpZ3VyZXMgaG93IHRvIGRlbGl2ZXIgRmluZGluZ3Mg
dG8gQmlnUXVlcnkgSW5zdGFuY2UuCgoKCgMEAAESAx8IFgoLCgMEAAcSBCACJwQKDQoFBAAH
nQgSBCACJwQKvAMKBAQAAgASAzECEhquAyBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGlzIGV4cG9ydC4gU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwaXMvZGVz
aWduL3Jlc291cmNlX25hbWVzI3JlbGF0aXZlX3Jlc291cmNlX25hbWUuCiBFeGFtcGxlIGZv
cm1hdDoKICJvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2JpZ1F1ZXJ5RXhwb3J0
cy97ZXhwb3J0X2lkfSIgRXhhbXBsZQogZm9ybWF0OiAiZm9sZGVycy97Zm9sZGVyX2lkfS9i
aWdRdWVyeUV4cG9ydHMve2V4cG9ydF9pZH0iIEV4YW1wbGUgZm9ybWF0OgogInByb2plY3Rz
L3twcm9qZWN0X2lkfS9iaWdRdWVyeUV4cG9ydHMve2V4cG9ydF9pZH0iCiBUaGlzIGZpZWxk
IGlzIHByb3ZpZGVkIGluIHJlc3BvbnNlcywgYW5kIGlzIGlnbm9yZWQgd2hlbiBwcm92aWRl
ZCBpbiBjcmVhdGUKIHJlcXVlc3RzLgoKDAoFBAACAAUSAzECCAoMCgUEAAIAARIDMQkNCgwK
BQQAAgADEgMxEBEKRgoEBAACARIDNAIZGjkgVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBleHBv
cnQgKG1heCBvZiAxMDI0IGNoYXJhY3RlcnMpLgoKDAoFBAACAQUSAzQCCAoMCgUEAAIBARID
NAkUCgwKBQQAAgEDEgM0FxgKhQYKBAQAAgISA0oCFBr3BSBFeHByZXNzaW9uIHRoYXQgZGVm
aW5lcyB0aGUgZmlsdGVyIHRvIGFwcGx5IGFjcm9zcyBjcmVhdGUvdXBkYXRlIGV2ZW50cwog
b2YgZmluZGluZ3MuIFRoZSBleHByZXNzaW9uIGlzIGEgbGlzdCBvZiB6ZXJvIG9yIG1vcmUg
cmVzdHJpY3Rpb25zIGNvbWJpbmVkCiB2aWEgbG9naWNhbCBvcGVyYXRvcnMgYEFORGAgYW5k
IGBPUmAuIFBhcmVudGhlc2VzIGFyZSBzdXBwb3J0ZWQsIGFuZCBgT1JgCiBoYXMgaGlnaGVy
IHByZWNlZGVuY2UgdGhhbiBgQU5EYC4KCiBSZXN0cmljdGlvbnMgaGF2ZSB0aGUgZm9ybSBg
PGZpZWxkPiA8b3BlcmF0b3I+IDx2YWx1ZT5gIGFuZCBtYXkgaGF2ZSBhCiBgLWAgY2hhcmFj
dGVyIGluIGZyb250IG9mIHRoZW0gdG8gaW5kaWNhdGUgbmVnYXRpb24uIFRoZSBmaWVsZHMg
bWFwIHRvCiB0aG9zZSBkZWZpbmVkIGluIHRoZSBjb3JyZXNwb25kaW5nIHJlc291cmNlLgoK
IFRoZSBzdXBwb3J0ZWQgb3BlcmF0b3JzIGFyZToKCiAqIGA9YCBmb3IgYWxsIHZhbHVlIHR5
cGVzLgogKiBgPmAsIGA8YCwgYD49YCwgYDw9YCBmb3IgaW50ZWdlciB2YWx1ZXMuCiAqIGA6
YCwgbWVhbmluZyBzdWJzdHJpbmcgbWF0Y2hpbmcsIGZvciBzdHJpbmdzLgoKIFRoZSBzdXBw
b3J0ZWQgdmFsdWUgdHlwZXMgYXJlOgoKICogc3RyaW5nIGxpdGVyYWxzIGluIHF1b3Rlcy4K
ICogaW50ZWdlciBsaXRlcmFscyB3aXRob3V0IHF1b3Rlcy4KICogYm9vbGVhbiBsaXRlcmFs
cyBgdHJ1ZWAgYW5kIGBmYWxzZWAgd2l0aG91dCBxdW90ZXMuCgoMCgUEAAICBRIDSgIICgwK
BQQAAgIBEgNKCQ8KDAoFBAACAgMSA0oSEwroAQoEBAACAxIDUAIVGtoBIFRoZSBkYXRhc2V0
IHRvIHdyaXRlIGZpbmRpbmdzJyB1cGRhdGVzIHRvLiBJdHMgZm9ybWF0IGlzCiAicHJvamVj
dHMvW3Byb2plY3RfaWRdL2RhdGFzZXRzL1tiaWdxdWVyeV9kYXRhc2V0X2lkXSIuCiBCaWdR
dWVyeSBEYXRhc2V0IHVuaXF1ZSBJRCAgbXVzdCBjb250YWluIG9ubHkgbGV0dGVycyAoYS16
LCBBLVopLCBudW1iZXJzCiAoMC05KSwgb3IgdW5kZXJzY29yZXMgKF8pLgoKDAoFBAACAwUS
A1ACCAoMCgUEAAIDARIDUAkQCgwKBQQAAgMDEgNQExQKqQEKBAQAAgQSBFUCVjIamgEgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBCaWdRdWVyeSBleHBvcnQgd2FzIGNy
ZWF0ZWQuCiBUaGlzIGZpZWxkIGlzIHNldCBieSB0aGUgc2VydmVyIGFuZCB3aWxsIGJlIGln
bm9yZWQgaWYgcHJvdmlkZWQgb24gZXhwb3J0CiBvbiBjcmVhdGlvbi4KCgwKBQQAAgQGEgNV
AhsKDAoFBAACBAESA1UcJwoMCgUEAAIEAxIDVSorCgwKBQQAAgQIEgNWBjEKDwoIBAACBAic
CAASA1YHMAq8AQoEBAACBRIEWwJcMhqtASBPdXRwdXQgb25seS4gVGhlIG1vc3QgcmVjZW50
IHRpbWUgYXQgd2hpY2ggdGhlIEJpZ1F1ZXJ5IGV4cG9ydCB3YXMgdXBkYXRlZC4KIFRoaXMg
ZmllbGQgaXMgc2V0IGJ5IHRoZSBzZXJ2ZXIgYW5kIHdpbGwgYmUgaWdub3JlZCBpZiBwcm92
aWRlZCBvbiBleHBvcnQKIGNyZWF0aW9uIG9yIHVwZGF0ZS4KCgwKBQQAAgUGEgNbAhsKDAoF
BAACBQESA1scJwoMCgUEAAIFAxIDWyorCgwKBQQAAgUIEgNcBjEKDwoIBAACBQicCAASA1wH
MAq7AQoEBAACBhIDYQJMGq0BIE91dHB1dCBvbmx5LiBFbWFpbCBhZGRyZXNzIG9mIHRoZSB1
c2VyIHdobyBsYXN0IGVkaXRlZCB0aGUgQmlnUXVlcnkgZXhwb3J0LgogVGhpcyBmaWVsZCBp
cyBzZXQgYnkgdGhlIHNlcnZlciBhbmQgd2lsbCBiZSBpZ25vcmVkIGlmIHByb3ZpZGVkIG9u
IGV4cG9ydAogY3JlYXRpb24gb3IgdXBkYXRlLgoKDAoFBAACBgUSA2ECCAoMCgUEAAIGARID
YQkbCgwKBQQAAgYDEgNhHh8KDAoFBAACBggSA2EgSwoPCggEAAIGCJwIABIDYSFKCn8KBAQA
AgcSA2UCQxpyIE91dHB1dCBvbmx5LiBUaGUgc2VydmljZSBhY2NvdW50IHRoYXQgbmVlZHMg
cGVybWlzc2lvbiB0byBjcmVhdGUgdGFibGUgYW5kCiB1cGxvYWQgZGF0YSB0byB0aGUgQmln
UXVlcnkgZGF0YXNldC4KCgwKBQQAAgcFEgNlAggKDAoFBAACBwESA2UJEgoMCgUEAAIHAxID
ZRUWCgwKBQQAAgcIEgNlF0IKDwoIBAACBwicCAASA2UYQQq0AQoEBAACCBIEagJrLxqlASBP
cHRpb25hbC4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIG5vdGlmaWNhdGlvbnMgd2lsbCBiZSBz
ZW50IGZvciBkZWxldGVkCiBmaW5kaW5ncy4gV2hlbiBlbmFibGVkLCB0aGUgZmlsdGVyIGlz
IHN0aWxsIHJlc3BlY3RlZCB3aGVuIHNlbmRpbmcgZGVsZXRpb24KIG5vdGlmaWNhdGlvbnMu
CgoMCgUEAAIIBRIDagIGCgwKBQQAAggBEgNqByUKDAoFBAACCAMSA2ooKQoMCgUEAAIICBID
awYuCg8KCAQAAggInAgAEgNrBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport ===
    # Fields for BigQueryExport
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: dataset Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: most_recent_editor Type: 9 ()
    # Field: principal Type: 9 ()
    # Field: deletion_notifications_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::BigqueryExport - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/bigquery_export.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::BigqueryExport;

    my $msg = Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport->new({
        name => $name,
        description => $description,
        filter => $filter,
        dataset => $dataset,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/bigquery_export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport

Configures how to deliver Findings to BigQuery Instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this export. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name.
Example format:
"organizations/{organization_id}/bigQueryExports/{export_id}" Example
format: "folders/{folder_id}/bigQueryExports/{export_id}" Example format:
"projects/{project_id}/bigQueryExports/{export_id}"
This field is provided in responses, and is ignored when provided in create
requests.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the export (max of 1024 characters).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Expression that defines the filter to apply across create/update events
of findings. The expression is a list of zero or more restrictions combined
via logical operators `AND` and `OR`. Parentheses are supported, and `OR`
has higher precedence than `AND`.

Restrictions have the form `<field> <operator> <value>` and may have a
`-` character in front of them to indicate negation. The fields map to
those defined in the corresponding resource.

The supported operators are:

* `=` for all value types.
* `>`, `<`, `>=`, `<=` for integer values.
* `:`, meaning substring matching, for strings.

The supported value types are:

* string literals in quotes.
* integer literals without quotes.
* boolean literals `true` and `false` without quotes.

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

The dataset to write findings' updates to. Its format is
"projects/[project_id]/datasets/[bigquery_dataset_id]".
BigQuery Dataset unique ID  must contain only letters (a-z, A-Z), numbers
(0-9), or underscores (_).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the BigQuery export was created.
This field is set by the server and will be ignored if provided on export
on creation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The most recent time at which the BigQuery export was updated.
This field is set by the server and will be ignored if provided on export
creation or update.

=item * C<< $msg->most_recent_editor() >> / C<< $msg->most_recent_editor($value) >>

Type: C<String>

Output only. Email address of the user who last edited the BigQuery export.
This field is set by the server and will be ignored if provided on export
creation or update.

=item * C<< $msg->principal() >> / C<< $msg->principal($value) >>

Type: C<String>

Output only. The service account that needs permission to create table and
upload data to the BigQuery dataset.

=item * C<< $msg->deletion_notifications_enabled() >> / C<< $msg->deletion_notifications_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether the notifications will be sent for deleted
findings. When enabled, the filter is still respected when sending deletion
notifications.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::BigqueryExport::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
