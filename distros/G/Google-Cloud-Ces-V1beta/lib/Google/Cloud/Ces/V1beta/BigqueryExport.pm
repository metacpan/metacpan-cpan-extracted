package Google::Cloud::Ces::V1beta::BigqueryExport;

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
Ci1nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9iaWdxdWVyeV9leHBvcnQucHJvdG8SF2dvb2ds
ZS5jbG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvInUK
FkJpZ1F1ZXJ5RXhwb3J0U2V0dGluZ3MSHQoHZW5hYmxlZBgBIAEoCEID4EEBUgdlbmFibGVk
Eh0KB3Byb2plY3QYAiABKAlCA+BBAVIHcHJvamVjdBIdCgdkYXRhc2V0GAMgASgJQgPgQQFS
B2RhdGFzZXRCYwobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhQhNCaWdRdWVyeUV4cG9y
dFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNw
YkqsCwoGEgQOACcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAgCgkKAgMAEgMSACkKCAoBCBIDFABECgkKAggLEgMUAEQKCAoBCBIDFQAiCgkKAggKEgMV
ACIKCAoBCBIDFgA0CgkKAggIEgMWADQKCAoBCBIDFwA0CgkKAggBEgMXADQKTQoCBAASBBoA
JwEaQSBTZXR0aW5ncyB0byBkZXNjcmliZSB0aGUgQmlnUXVlcnkgZXhwb3J0IGJlaGF2aW9y
cyBmb3IgdGhlIGFwcC4KCgoKAwQAARIDGggeCkoKBAQAAgASAxwCPBo9IE9wdGlvbmFsLiBJ
bmRpY2F0ZXMgd2hldGhlciB0aGUgQmlnUXVlcnkgZXhwb3J0IGlzIGVuYWJsZWQuCgoMCgUE
AAIABRIDHAIGCgwKBQQAAgABEgMcBw4KDAoFBAACAAMSAxwREgoMCgUEAAIACBIDHBM7Cg8K
CAQAAgAInAgAEgMcFDoKqgIKBAQAAgESAyMCPhqcAiBPcHRpb25hbC4gVGhlICoqcHJvamVj
dCBJRCoqIG9mIHRoZSBCaWdRdWVyeSBkYXRhc2V0IHRvIGV4cG9ydCB0aGUgZGF0YSB0by4K
CiBOb3RlOiBJZiB0aGUgQmlnUXVlcnkgZGF0YXNldCBpcyBpbiBhIGRpZmZlcmVudCBwcm9q
ZWN0IGZyb20gdGhlIGFwcCwKIHlvdSBzaG91bGQgZ3JhbnQgYHJvbGVzL2JpZ3F1ZXJ5LmFk
bWluYCByb2xlIHRvIHRoZSBDRVMgc2VydmljZSBhZ2VudAogYHNlcnZpY2UtPFBST0pFQ1Qt
TlVNQkVSPkBnY3Atc2EtY2VzLmlhbS5nc2VydmljZWFjY291bnQuY29tYC4KCgwKBQQAAgEF
EgMjAggKDAoFBAACAQESAyMJEAoMCgUEAAIBAxIDIxMUCgwKBQQAAgEIEgMjFT0KDwoIBAAC
AQicCAASAyMWPApLCgQEAAICEgMmAj4aPiBPcHRpb25hbC4gVGhlIEJpZ1F1ZXJ5ICoqZGF0
YXNldCBJRCoqIHRvIGV4cG9ydCB0aGUgZGF0YSB0by4KCgwKBQQAAgIFEgMmAggKDAoFBAAC
AgESAyYJEAoMCgUEAAICAxIDJhMUCgwKBQQAAgIIEgMmFT0KDwoIBAACAgicCAASAyYWPGIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings ===
    # Fields for BigQueryExportSettings
    # Field: enabled Type: 8 ()
    # Field: project Type: 9 ()
    # Field: dataset Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::BigqueryExport - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/bigquery_export.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::BigqueryExport;

    my $msg = Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings->new({
        enabled => $enabled,
        project => $project,
        dataset => $dataset,
    });

    # Read or update a field
    my $val = $msg->enabled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/bigquery_export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::BigqueryExport::BigQueryExportSettings

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::BigqueryExport::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
