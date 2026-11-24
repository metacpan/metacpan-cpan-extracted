package Google::Cloud::Ces::V1::BigqueryExport;

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
Cilnb29nbGUvY2xvdWQvY2VzL3YxL2JpZ3F1ZXJ5X2V4cG9ydC5wcm90bxITZ29vZ2xlLmNs
b3VkLmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byJ1ChZCaWdRdWVy
eUV4cG9ydFNldHRpbmdzEh0KB2VuYWJsZWQYASABKAhCA+BBAVIHZW5hYmxlZBIdCgdwcm9q
ZWN0GAIgASgJQgPgQQFSB3Byb2plY3QSHQoHZGF0YXNldBgDIAEoCUID4EEBUgdkYXRhc2V0
QlsKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQhNCaWdRdWVyeUV4cG9ydFByb3RvUAFaKWNs
b3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSqwLCgYSBA4AJwEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoI
CgEIEgMUAEAKCQoCCAsSAxQAQAoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADQKCQoC
CAgSAxYANAoICgEIEgMXADAKCQoCCAESAxcAMApNCgIEABIEGgAnARpBIFNldHRpbmdzIHRv
IGRlc2NyaWJlIHRoZSBCaWdRdWVyeSBleHBvcnQgYmVoYXZpb3JzIGZvciB0aGUgYXBwLgoK
CgoDBAABEgMaCB4KSgoEBAACABIDHAI8Gj0gT3B0aW9uYWwuIEluZGljYXRlcyB3aGV0aGVy
IHRoZSBCaWdRdWVyeSBleHBvcnQgaXMgZW5hYmxlZC4KCgwKBQQAAgAFEgMcAgYKDAoFBAAC
AAESAxwHDgoMCgUEAAIAAxIDHBESCgwKBQQAAgAIEgMcEzsKDwoIBAACAAicCAASAxwUOgqq
AgoEBAACARIDIwI+GpwCIE9wdGlvbmFsLiBUaGUgKipwcm9qZWN0IElEKiogb2YgdGhlIEJp
Z1F1ZXJ5IGRhdGFzZXQgdG8gZXhwb3J0IHRoZSBkYXRhIHRvLgoKIE5vdGU6IElmIHRoZSBC
aWdRdWVyeSBkYXRhc2V0IGlzIGluIGEgZGlmZmVyZW50IHByb2plY3QgZnJvbSB0aGUgYXBw
LAogeW91IHNob3VsZCBncmFudCBgcm9sZXMvYmlncXVlcnkuYWRtaW5gIHJvbGUgdG8gdGhl
IENFUyBzZXJ2aWNlIGFnZW50CiBgc2VydmljZS08UFJPSkVDVC1OVU1CRVI+QGdjcC1zYS1j
ZXMuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gLgoKDAoFBAACAQUSAyMCCAoMCgUEAAIBARID
IwkQCgwKBQQAAgEDEgMjExQKDAoFBAACAQgSAyMVPQoPCggEAAIBCJwIABIDIxY8CksKBAQA
AgISAyYCPho+IE9wdGlvbmFsLiBUaGUgQmlnUXVlcnkgKipkYXRhc2V0IElEKiogdG8gZXhw
b3J0IHRoZSBkYXRhIHRvLgoKDAoFBAACAgUSAyYCCAoMCgUEAAICARIDJgkQCgwKBQQAAgID
EgMmExQKDAoFBAACAggSAyYVPQoPCggEAAICCJwIABIDJhY8YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::BigqueryExport::BigQueryExportSettings ===
    # Fields for BigQueryExportSettings
    # Field: enabled Type: 8 ()
    # Field: project Type: 9 ()
    # Field: dataset Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::BigqueryExport - Compiled Protocol Buffers messages for google/cloud/ces/v1/bigquery_export.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::BigqueryExport;

    my $msg = Google::Cloud::Ces::V1::BigqueryExport::BigQueryExportSettings->new({
        enabled => $enabled,
        project => $project,
        dataset => $dataset,
    });

    # Read or update a field
    my $val = $msg->enabled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::BigqueryExport::BigQueryExportSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/bigquery_export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::BigqueryExport::BigQueryExportSettings

Settings to describe the BigQuery export behaviors for the app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Optional. Indicates whether the BigQuery export is enabled.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Optional. The B<project ID> of the BigQuery dataset to export the data to.

Note: If the BigQuery dataset is in a different project from the app,
you should grant `roles/bigquery.admin` role to the CES service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Optional. The BigQuery B<dataset ID> to export the data to.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::BigqueryExport::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
