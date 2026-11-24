package Google::Cloud::Connectors::V1::DestinationConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9kZXN0aW5hdGlvbl9jb25maWcucHJvdG8S
Gmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxInIKEURlc3RpbmF0aW9uQ29uZmlnEhAKA2tl
eRgBIAEoCVIDa2V5EksKDGRlc3RpbmF0aW9ucxgCIAMoCzInLmdvb2dsZS5jbG91ZC5jb25u
ZWN0b3JzLnYxLkRlc3RpbmF0aW9uUgxkZXN0aW5hdGlvbnMidwoLRGVzdGluYXRpb24SLwoS
c2VydmljZV9hdHRhY2htZW50GAEgASgJSABSEXNlcnZpY2VBdHRhY2htZW50EhQKBGhvc3QY
AiABKAlIAFIEaG9zdBISCgRwb3J0GAMgASgFUgRwb3J0Qg0KC2Rlc3RpbmF0aW9uQkJQAVo+
Y2xvdWQuZ29vZ2xlLmNvbS9nby9jb25uZWN0b3JzL2FwaXYxL2Nvbm5lY3RvcnNwYjtjb25u
ZWN0b3JzcGJKuQoKBhIEDgAqAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAIwoICgEIEgMSAFUKCQoCCAsSAxIAVQoICgEIEgMTACIKCQoCCAoSAxMAIgo0
CgIEABIEFgAcARooIERlZmluZSB0aGUgQ29ubmVjdG9ycyB0YXJnZXQgZW5kcG9pbnQuCgoK
CgMEAAESAxYIGQpYCgQEAAIAEgMYAhEaSyBUaGUga2V5IGlzIHRoZSBkZXN0aW5hdGlvbiBp
ZGVudGlmaWVyIHRoYXQgaXMgc3VwcG9ydGVkIGJ5IHRoZSBDb25uZWN0b3IuCgoMCgUEAAIA
BRIDGAIICgwKBQQAAgABEgMYCQwKDAoFBAACAAMSAxgPEAosCgQEAAIBEgMbAigaHyBUaGUg
ZGVzdGluYXRpb25zIGZvciB0aGUga2V5LgoKDAoFBAACAQQSAxsCCgoMCgUEAAIBBhIDGwsW
CgwKBQQAAgEBEgMbFyMKDAoFBAACAQMSAxsmJwoKCgIEARIEHgAqAQoKCgMEAQESAx4IEwoM
CgQEAQgAEgQfAiYDCgwKBQQBCAABEgMfCBMKWgoEBAECABIDIgQiGk0gUFNDIHNlcnZpY2Ug
YXR0YWNobWVudHMuCiBGb3JtYXQ6IHByb2plY3RzLyovcmVnaW9ucy8qL3NlcnZpY2VBdHRh
Y2htZW50cy8qCgoMCgUEAQIABRIDIgQKCgwKBQQBAgABEgMiCx0KDAoFBAECAAMSAyIgIQoq
CgQEAQIBEgMlBBQaHSBGb3IgcHVibGljbHkgcm91dGFibGUgaG9zdC4KCgwKBQQBAgEFEgMl
BAoKDAoFBAECAQESAyULDwoMCgUEAQIBAxIDJRITClYKBAQBAgISAykCERpJIFRoZSBwb3J0
IGlzIHRoZSB0YXJnZXQgcG9ydCBudW1iZXIgdGhhdCBpcyBhY2NlcHRlZCBieSB0aGUgZGVz
dGluYXRpb24uCgoMCgUEAQICBRIDKQIHCgwKBQQBAgIBEgMpCAwKDAoFBAECAgMSAykPEGIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig ===
    # Fields for DestinationConfig
    # Field: key Type: 9 ()
    # Field: destinations Type: 11 (.google.cloud.connectors.v1.Destination)

# === Message: Google::Cloud::Connectors::V1::DestinationConfig::Destination ===
    # Fields for Destination
    # Field: service_attachment Type: 9 ()
    # Field: host Type: 9 ()
    # Field: port Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::DestinationConfig - Compiled Protocol Buffers messages for google/cloud/connectors/v1/destination_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::DestinationConfig;

    my $msg = Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig->new({
        key => $key,
        destinations => $destinations,
    });

    # Read or update a field
    my $val = $msg->key();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/destination_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig

Define the Connectors target endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

The key is the destination identifier that is supported by the Connector.

=item * C<< $msg->destinations() >> / C<< $msg->destinations($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::DestinationConfig::Destination>)

The destinations for the key.

=back

=head2 Google::Cloud::Connectors::V1::DestinationConfig::Destination

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_attachment() >> / C<< $msg->service_attachment($value) >>

Type: C<String>

PSC service attachments.
Format: projects/*/regions/*/serviceAttachments/*

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

For publicly routable host.

=item * C<< $msg->port() >> / C<< $msg->port($value) >>

Type: C<Int32>

The port is the target port number that is accepted by the destination.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::DestinationConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
