package Google::Cloud::Securitycenter::V2::BigqueryExport;

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
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvYmlncXVlcnlfZXhwb3J0LnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8ixgUKDkJpZ1F1ZXJ5RXhwb3J0EhcKBG5hbWUYASABKAlCA+BB
CFIEbmFtZRIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb24SFgoGZmlsdGVyGAMg
ASgJUgZmaWx0ZXISGAoHZGF0YXNldBgEIAEoCVIHZGF0YXNldBJACgtjcmVhdGVfdGltZRgF
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1
cGRhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBk
YXRlVGltZRIxChJtb3N0X3JlY2VudF9lZGl0b3IYByABKAlCA+BBA1IQbW9zdFJlY2VudEVk
aXRvchIhCglwcmluY2lwYWwYCCABKAlCA+BBA1IJcHJpbmNpcGFsEkkKHmRlbGV0aW9uX25v
dGlmaWNhdGlvbnNfZW5hYmxlZBgKIAEoCEID4EEBUhxkZWxldGlvbk5vdGlmaWNhdGlvbnNF
bmFibGVkOqEC6kGdAgosc2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vQmlnUXVlcnlF
eHBvcnQSSm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYmlnUXVlcnlFeHBvcnRzL3tleHBvcnR9Ej5mb2xkZXJzL3tmb2xkZXJ9L2xvY2F0aW9u
cy97bG9jYXRpb259L2JpZ1F1ZXJ5RXhwb3J0cy97ZXhwb3J0fRJAcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2JpZ1F1ZXJ5RXhwb3J0cy97ZXhwb3J0fSoPYmln
UXVlcnlFeHBvcnRzMg5iaWdRdWVyeUV4cG9ydELtAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1
cml0eWNlbnRlci52MkITQmlnUXVlcnlFeHBvcnRQcm90b1ABWkpjbG91ZC5nb29nbGUuY29t
L2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50
ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxT
ZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMkra
HgoGEgQOAHABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAn
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAOwoJCgIIJRIDFgA7
CggKAQgSAxcAYQoJCgIICxIDFwBhCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkANAoJ
CgIICBIDGQA0CggKAQgSAxoAOwoJCgIIARIDGgA7CggKAQgSAxsAOwoJCgIIKRIDGwA7CggK
AQgSAxwAOgoJCgIILRIDHAA6CkYKAgQAEgQfAHABGjogQ29uZmlndXJlcyBob3cgdG8gZGVs
aXZlciBGaW5kaW5ncyB0byBCaWdRdWVyeSBJbnN0YW5jZS4KCgoKAwQAARIDHwgWCgsKAwQA
BxIEIAInBAoNCgUEAAedCBIEIAInBAqSBAoEBAACABIDNQI9GoQEIElkZW50aWZpZXIuIFRo
ZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoaXMgZXhwb3J0LiBTZWU6CiBodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjcmVsYXRpdmVf
cmVzb3VyY2VfbmFtZS4KIFRoZSBmb2xsb3dpbmcgbGlzdCBzaG93cyBzb21lIGV4YW1wbGVz
OgoKICsKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L2xvY2F0aW9ucy97bG9j
YXRpb25faWR9L2JpZ1F1ZXJ5RXhwb3J0cy97ZXhwb3J0X2lkfWAKICsgYGZvbGRlcnMve2Zv
bGRlcl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vYmlnUXVlcnlFeHBvcnRzL3tleHBv
cnRfaWR9YAogKwogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9u
X2lkfS9iaWdRdWVyeUV4cG9ydHMve2V4cG9ydF9pZH1gCgogVGhpcyBmaWVsZCBpcyBwcm92
aWRlZCBpbiByZXNwb25zZXMsIGFuZCBpcyBpZ25vcmVkIHdoZW4gcHJvdmlkZWQgaW4gY3Jl
YXRlCiByZXF1ZXN0cy4KCgwKBQQAAgAFEgM1AggKDAoFBAACAAESAzUJDQoMCgUEAAIAAxID
NRARCgwKBQQAAgAIEgM1EjwKDwoIBAACAAicCAASAzUTOwpGCgQEAAIBEgM4AhkaOSBUaGUg
ZGVzY3JpcHRpb24gb2YgdGhlIGV4cG9ydCAobWF4IG9mIDEwMjQgY2hhcmFjdGVycykuCgoM
CgUEAAIBBRIDOAIICgwKBQQAAgEBEgM4CRQKDAoFBAACAQMSAzgXGAqFBgoEBAACAhIDTgIU
GvcFIEV4cHJlc3Npb24gdGhhdCBkZWZpbmVzIHRoZSBmaWx0ZXIgdG8gYXBwbHkgYWNyb3Nz
IGNyZWF0ZS91cGRhdGUgZXZlbnRzCiBvZiBmaW5kaW5ncy4gVGhlIGV4cHJlc3Npb24gaXMg
YSBsaXN0IG9mIHplcm8gb3IgbW9yZSByZXN0cmljdGlvbnMgY29tYmluZWQKIHZpYSBsb2dp
Y2FsIG9wZXJhdG9ycyBgQU5EYCBhbmQgYE9SYC4gUGFyZW50aGVzZXMgYXJlIHN1cHBvcnRl
ZCwgYW5kIGBPUmAKIGhhcyBoaWdoZXIgcHJlY2VkZW5jZSB0aGFuIGBBTkRgLgoKIFJlc3Ry
aWN0aW9ucyBoYXZlIHRoZSBmb3JtIGA8ZmllbGQ+IDxvcGVyYXRvcj4gPHZhbHVlPmAgYW5k
IG1heSBoYXZlIGEKIGAtYCBjaGFyYWN0ZXIgaW4gZnJvbnQgb2YgdGhlbSB0byBpbmRpY2F0
ZSBuZWdhdGlvbi4gVGhlIGZpZWxkcyBtYXAgdG8KIHRob3NlIGRlZmluZWQgaW4gdGhlIGNv
cnJlc3BvbmRpbmcgcmVzb3VyY2UuCgogVGhlIHN1cHBvcnRlZCBvcGVyYXRvcnMgYXJlOgoK
ICogYD1gIGZvciBhbGwgdmFsdWUgdHlwZXMuCiAqIGA+YCwgYDxgLCBgPj1gLCBgPD1gIGZv
ciBpbnRlZ2VyIHZhbHVlcy4KICogYDpgLCBtZWFuaW5nIHN1YnN0cmluZyBtYXRjaGluZywg
Zm9yIHN0cmluZ3MuCgogVGhlIHN1cHBvcnRlZCB2YWx1ZSB0eXBlcyBhcmU6CgogKiBzdHJp
bmcgbGl0ZXJhbHMgaW4gcXVvdGVzLgogKiBpbnRlZ2VyIGxpdGVyYWxzIHdpdGhvdXQgcXVv
dGVzLgogKiBib29sZWFuIGxpdGVyYWxzIGB0cnVlYCBhbmQgYGZhbHNlYCB3aXRob3V0IHF1
b3Rlcy4KCgwKBQQAAgIFEgNOAggKDAoFBAACAgESA04JDwoMCgUEAAICAxIDThITCugBCgQE
AAIDEgNUAhUa2gEgVGhlIGRhdGFzZXQgdG8gd3JpdGUgZmluZGluZ3MnIHVwZGF0ZXMgdG8u
IEl0cyBmb3JtYXQgaXMKICJwcm9qZWN0cy9bcHJvamVjdF9pZF0vZGF0YXNldHMvW2JpZ3F1
ZXJ5X2RhdGFzZXRfaWRdIi4KIEJpZ1F1ZXJ5IGRhdGFzZXQgdW5pcXVlIElEICBtdXN0IGNv
bnRhaW4gb25seSBsZXR0ZXJzIChhLXosIEEtWiksIG51bWJlcnMKICgwLTkpLCBvciB1bmRl
cnNjb3JlcyAoXykuCgoMCgUEAAIDBRIDVAIICgwKBQQAAgMBEgNUCRAKDAoFBAACAwMSA1QT
FAqpAQoEBAACBBIEWQJaMhqaASBPdXRwdXQgb25seS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhl
IEJpZ1F1ZXJ5IGV4cG9ydCB3YXMgY3JlYXRlZC4KIFRoaXMgZmllbGQgaXMgc2V0IGJ5IHRo
ZSBzZXJ2ZXIgYW5kIHdpbGwgYmUgaWdub3JlZCBpZiBwcm92aWRlZCBvbiBleHBvcnQKIG9u
IGNyZWF0aW9uLgoKDAoFBAACBAYSA1kCGwoMCgUEAAIEARIDWRwnCgwKBQQAAgQDEgNZKisK
DAoFBAACBAgSA1oGMQoPCggEAAIECJwIABIDWgcwCrwBCgQEAAIFEgRfAmAyGq0BIE91dHB1
dCBvbmx5LiBUaGUgbW9zdCByZWNlbnQgdGltZSBhdCB3aGljaCB0aGUgQmlnUXVlcnkgZXhw
b3J0IHdhcyB1cGRhdGVkLgogVGhpcyBmaWVsZCBpcyBzZXQgYnkgdGhlIHNlcnZlciBhbmQg
d2lsbCBiZSBpZ25vcmVkIGlmIHByb3ZpZGVkIG9uIGV4cG9ydAogY3JlYXRpb24gb3IgdXBk
YXRlLgoKDAoFBAACBQYSA18CGwoMCgUEAAIFARIDXxwnCgwKBQQAAgUDEgNfKisKDAoFBAAC
BQgSA2AGMQoPCggEAAIFCJwIABIDYAcwCrsBCgQEAAIGEgNlAkwarQEgT3V0cHV0IG9ubHku
IEVtYWlsIGFkZHJlc3Mgb2YgdGhlIHVzZXIgd2hvIGxhc3QgZWRpdGVkIHRoZSBCaWdRdWVy
eSBleHBvcnQuCiBUaGlzIGZpZWxkIGlzIHNldCBieSB0aGUgc2VydmVyIGFuZCB3aWxsIGJl
IGlnbm9yZWQgaWYgcHJvdmlkZWQgb24gZXhwb3J0CiBjcmVhdGlvbiBvciB1cGRhdGUuCgoM
CgUEAAIGBRIDZQIICgwKBQQAAgYBEgNlCRsKDAoFBAACBgMSA2UeHwoMCgUEAAIGCBIDZSBL
Cg8KCAQAAgYInAgAEgNlIUoKfwoEBAACBxIDaQJDGnIgT3V0cHV0IG9ubHkuIFRoZSBzZXJ2
aWNlIGFjY291bnQgdGhhdCBuZWVkcyBwZXJtaXNzaW9uIHRvIGNyZWF0ZSB0YWJsZSBhbmQK
IHVwbG9hZCBkYXRhIHRvIHRoZSBCaWdRdWVyeSBkYXRhc2V0LgoKDAoFBAACBwUSA2kCCAoM
CgUEAAIHARIDaQkSCgwKBQQAAgcDEgNpFRYKDAoFBAACBwgSA2kXQgoPCggEAAIHCJwIABID
aRhBCrQBCgQEAAIIEgRuAm8vGqUBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0aGUg
bm90aWZpY2F0aW9ucyB3aWxsIGJlIHNlbnQgZm9yIGRlbGV0ZWQKIGZpbmRpbmdzLiBXaGVu
IGVuYWJsZWQsIHRoZSBmaWx0ZXIgaXMgc3RpbGwgcmVzcGVjdGVkIHdoZW4gc2VuZGluZyBk
ZWxldGlvbgogbm90aWZpY2F0aW9ucy4KCgwKBQQAAggFEgNuAgYKDAoFBAACCAESA24HJQoM
CgUEAAIIAxIDbigqCgwKBQQAAggIEgNvBi4KDwoIBAACCAicCAASA28HLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport ===
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

Google::Cloud::Securitycenter::V2::BigqueryExport - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/bigquery_export.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::BigqueryExport;

    my $msg = Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport->new({
        name => $name,
        description => $description,
        filter => $filter,
        dataset => $dataset,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/bigquery_export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::BigqueryExport::BigQueryExport

Configures how to deliver Findings to BigQuery Instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The relative resource name of this export. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name.
The following list shows some examples:

+
`organizations/{organization_id}/locations/{location_id}/bigQueryExports/{export_id}`
+ `folders/{folder_id}/locations/{location_id}/bigQueryExports/{export_id}`
+
`projects/{project_id}/locations/{location_id}/bigQueryExports/{export_id}`

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
BigQuery dataset unique ID  must contain only letters (a-z, A-Z), numbers
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::BigqueryExport::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
