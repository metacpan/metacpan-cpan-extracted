package Google::Cloud::Securitycenter::V2::AiModel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvYWlfbW9kZWwucHJvdG8SHmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MiKLAwoHQWlNb2RlbBISCgRuYW1lGAEgASgJUgRu
YW1lEhYKBmRvbWFpbhgCIAEoCVIGZG9tYWluEhgKB2xpYnJhcnkYAyABKAlSB2xpYnJhcnkS
GgoIbG9jYXRpb24YBCABKAlSCGxvY2F0aW9uEhwKCXB1Ymxpc2hlchgFIAEoCVIJcHVibGlz
aGVyEmsKE2RlcGxveW1lbnRfcGxhdGZvcm0YBiABKA4yOi5nb29nbGUuY2xvdWQuc2VjdXJp
dHljZW50ZXIudjIuQWlNb2RlbC5EZXBsb3ltZW50UGxhdGZvcm1SEmRlcGxveW1lbnRQbGF0
Zm9ybRIhCgxkaXNwbGF5X25hbWUYByABKAlSC2Rpc3BsYXlOYW1lInAKEkRlcGxveW1lbnRQ
bGF0Zm9ybRIjCh9ERVBMT1lNRU5UX1BMQVRGT1JNX1VOU1BFQ0lGSUVEEAASDQoJVkVSVEVY
X0FJEAESBwoDR0tFEAISBwoDR0NFEAMSFAoQRklORV9UVU5FRF9NT0RFTBAEQuYBCiJjb20u
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyQgxBaU1vZGVsUHJvdG9QAVpKY2xvdWQu
Z29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0eWNlbnRlcnBiO3Nl
Y3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjLKAh5Hb29n
bGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjLqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNl
bnRlcjo6VjJKzRAKBhIEDgBCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
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
CggKAQISAxAAJwoICgEIEgMSADsKCQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsSAxMAYQoI
CgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVAC0KCQoCCAgSAxUALQoICgEIEgMWADsKCQoC
CAESAxYAOwoICgEIEgMXADsKCQoCCCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgAOgpSCgIE
ABIEGwBCARpGIENvbnRhaW5zIGluZm9ybWF0aW9uIGFib3V0IHRoZSBBSSBtb2RlbCBhc3Nv
Y2lhdGVkIHdpdGggdGhlIGZpbmRpbmcuCgoKCgMEAAESAxsIDwo8CgQEAAQAEgQdAiwDGi4g
VGhlIHBsYXRmb3JtIG9uIHdoaWNoIHRoZSBtb2RlbCBpcyBkZXBsb3llZC4KCgwKBQQABAAB
EgMdBxkKMQoGBAAEAAIAEgMfBCgaIiBVbnNwZWNpZmllZCBkZXBsb3ltZW50IHBsYXRmb3Jt
LgoKDgoHBAAEAAIAARIDHwQjCg4KBwQABAACAAISAx8mJwobCgYEAAQAAgESAyIEEhoMIFZl
cnRleCBBSS4KCg4KBwQABAACAQESAyIEDQoOCgcEAAQAAgECEgMiEBEKKgoGBAAEAAICEgMl
BAwaGyBHb29nbGUgS3ViZXJuZXRlcyBFbmdpbmUuCgoOCgcEAAQAAgIBEgMlBAcKDgoHBAAE
AAICAhIDJQoLCicKBgQABAACAxIDKAQMGhggR29vZ2xlIENvbXB1dGUgRW5naW5lLgoKDgoH
BAAEAAIDARIDKAQHCg4KBwQABAACAwISAygKCwoiCgYEAAQAAgQSAysEGRoTIEZpbmUgdHVu
ZWQgbW9kZWwuCgoOCgcEAAQAAgQBEgMrBBQKDgoHBAAEAAIEAhIDKxcYCkUKBAQAAgASAy8C
Eho4IFRoZSBuYW1lIG9mIHRoZSBBSSBtb2RlbCwgZm9yIGV4YW1wbGUsICJnZW1pbmk6MS4w
LjAiLgoKDAoFBAACAAUSAy8CCAoMCgUEAAIAARIDLwkNCgwKBQQAAgADEgMvEBEKUAoEBAAC
ARIDMgIUGkMgVGhlIGRvbWFpbiBvZiB0aGUgbW9kZWwsIGZvciBleGFtcGxlLCDigJxpbWFn
ZS1jbGFzc2lmaWNhdGlvbuKAnS4KCgwKBQQAAgEFEgMyAggKDAoFBAACAQESAzIJDwoMCgUE
AAIBAxIDMhITCk4KBAQAAgISAzUCFRpBIFRoZSBuYW1lIG9mIHRoZSBtb2RlbCBsaWJyYXJ5
LCBmb3IgZXhhbXBsZSwg4oCcdHJhbnNmb3JtZXJz4oCdLgoKDAoFBAACAgUSAzUCCAoMCgUE
AAICARIDNQkQCgwKBQQAAgIDEgM1ExQKVQoEBAACAxIDOAIWGkggVGhlIHJlZ2lvbiBpbiB3
aGljaCB0aGUgbW9kZWwgaXMgdXNlZCwgZm9yIGV4YW1wbGUsIOKAnHVzLWNlbnRyYWwx4oCd
LgoKDAoFBAACAwUSAzgCCAoMCgUEAAIDARIDOAkRCgwKBQQAAgMDEgM4FBUKVQoEBAACBBID
OwIXGkggVGhlIHB1Ymxpc2hlciBvZiB0aGUgbW9kZWwsIGZvciBleGFtcGxlLCDigJxnb29n
bGXigJ0gb3Ig4oCcbnZpZGlh4oCdLgoKDAoFBAACBAUSAzsCCAoMCgUEAAIEARIDOwkSCgwK
BQQAAgQDEgM7FRYKOwoEBAACBRIDPgItGi4gVGhlIHBsYXRmb3JtIG9uIHdoaWNoIHRoZSBt
b2RlbCBpcyBkZXBsb3llZC4KCgwKBQQAAgUGEgM+AhQKDAoFBAACBQESAz4VKAoMCgUEAAIF
AxIDPissClgKBAQAAgYSA0ECGhpLIFRoZSB1c2VyIGRlZmluZWQgZGlzcGxheSBuYW1lIG9m
IG1vZGVsLiBFeC4gYmFzZWxpbmUtY2xhc3NpZmljYXRpb24tbW9kZWwKCgwKBQQAAgYFEgNB
AggKDAoFBAACBgESA0EJFQoMCgUEAAIGAxIDQRgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::AiModel::AiModel ===
    # Fields for AiModel
    # Field: name Type: 9 ()
    # Field: domain Type: 9 ()
    # Field: library Type: 9 ()
    # Field: location Type: 9 ()
    # Field: publisher Type: 9 ()
    # Field: deployment_platform Type: 14 (.google.cloud.securitycenter.v2.AiModel.DeploymentPlatform)
    # Field: display_name Type: 9 ()

# Enum: AiModel::DeploymentPlatform
our $AiModel_DEPLOYMENT_PLATFORM_UNSPECIFIED = 0;
our $AiModel_VERTEX_AI = 1;
our $AiModel_GKE = 2;
our $AiModel_GCE = 3;
our $AiModel_FINE_TUNED_MODEL = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::AiModel - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/ai_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::AiModel;

    my $msg = Google::Cloud::Securitycenter::V2::AiModel::AiModel->new({
        name => $name,
        domain => $domain,
        library => $library,
        location => $location,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::AiModel::AiModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/ai_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::AiModel::AiModel

Contains information about the AI model associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the AI model, for example, "gemini:1.0.0".

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

The domain of the model, for example, “image-classification”.

=item * C<< $msg->library() >> / C<< $msg->library($value) >>

Type: C<String>

The name of the model library, for example, “transformers”.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The region in which the model is used, for example, “us-central1”.

=item * C<< $msg->publisher() >> / C<< $msg->publisher($value) >>

Type: C<String>

The publisher of the model, for example, “google” or “nvidia”.

=item * C<< $msg->deployment_platform() >> / C<< $msg->deployment_platform($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::AiModel::DeploymentPlatform>)

The platform on which the model is deployed.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The user defined display name of model. Ex. baseline-classification-model

=back

=head3 Enum: AiModel::DeploymentPlatform

=over 4

=item * C<DEPLOYMENT_PLATFORM_UNSPECIFIED> => C<0>

=item * C<VERTEX_AI> => C<1>

=item * C<GKE> => C<2>

=item * C<GCE> => C<3>

=item * C<FINE_TUNED_MODEL> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::AiModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
