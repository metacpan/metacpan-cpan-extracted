package Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2JpZ3F1ZXJ5X2V4cG9ydC5w
cm90bxIiZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMSJZChZCaWdRdWVyeUV4
cG9ydFNldHRpbmdzEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSJQoOYmlncXVlcnlfdGFi
bGUYAiABKAlSDWJpZ3F1ZXJ5VGFibGVCoQEKJmNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52M2JldGExQhNCaWdRdWVyeUV4cG9ydFByb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20v
Z28vZGlhbG9nZmxvdy9jeC9hcGl2M2JldGExL2N4cGI7Y3hwYqICAkRGqgIiR29vZ2xlLkNs
b3VkLkRpYWxvZ2Zsb3cuQ3guVjNCZXRhMUqiCAoGEgQOACEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCggKAQgSAxIAPwoJCgIIJRIDEgA/CggKAQgS
AxMATQoJCgIICxIDEwBNCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUANAoJCgIICBID
FQA0CggKAQgSAxYAPwoJCgIIARIDFgA/CggKAQgSAxcAIAoJCgIIJBIDFwAgCi4KAgQAEgQa
ACEBGiIgVGhlIHNldHRpbmdzIG9mIEJpZ1F1ZXJ5IGV4cG9ydC4KCgoKAwQAARIDGggeCkwK
BAQAAgASAxwCExo/IFRoZSBmaWVsZCB0byBpbmRpY2F0ZSB3aGV0aGVyIHRoZSBCaWdRdWVy
eSBleHBvcnQgaXMgZW5hYmxlZC4KCgwKBQQAAgAFEgMcAgYKDAoFBAACAAESAxwHDgoMCgUE
AAIAAxIDHBESCnMKBAQAAgESAyACHBpmIFRoZSBCaWdRdWVyeSB0YWJsZSB0byBleHBvcnQu
CiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdElEPi9kYXRhc2V0cy88RGF0YXNldElEPi90
YWJsZXMvPFRhYmxlSUQ+YC4KCgwKBQQAAgEFEgMgAggKDAoFBAACAQESAyAJFwoMCgUEAAIB
AxIDIBobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport::BigQueryExportSettings ===
    # Fields for BigQueryExportSettings
    # Field: enabled Type: 8 ()
    # Field: bigquery_table Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/bigquery_export.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport::BigQueryExportSettings->new({
        enabled => $enabled,
        bigquery_table => $bigquery_table,
    });

    # Read or update a field
    my $val = $msg->enabled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport::BigQueryExportSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/bigquery_export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport::BigQueryExportSettings

The settings of BigQuery export.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

The field to indicate whether the BigQuery export is enabled.

=item * C<< $msg->bigquery_table() >> / C<< $msg->bigquery_table($value) >>

Type: C<String>

The BigQuery table to export.
Format: `projects/<ProjectID>/datasets/<DatasetID>/tables/<TableID>`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
