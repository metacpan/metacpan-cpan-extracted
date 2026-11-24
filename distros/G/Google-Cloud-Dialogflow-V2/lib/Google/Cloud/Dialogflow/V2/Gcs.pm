package Google::Cloud::Dialogflow::V2::Gcs;

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
CiRnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9nY3MucHJvdG8SGmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIiUKCkdjc1Nv
dXJjZXMSFwoEdXJpcxgCIAMoCUID4EECUgR1cmlzIiIKDkdjc0Rlc3RpbmF0aW9uEhAKA3Vy
aRgBIAEoCVIDdXJpQo4BCh5jb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJCCEdjc1By
b3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFsb2dmbG93
cGI7ZGlhbG9nZmxvd3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkqhCwoG
EgQOACsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkK
AgMAEgMSACkKCAoBCBIDFAA3CgkKAgglEgMUADcKCAoBCBIDFQBVCgkKAggLEgMVAFUKCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwApCgkKAggIEgMXACkKCAoBCBIDGAA3CgkKAggB
EgMYADcKCAoBCBIDGQAgCgkKAggkEgMZACAKOwoCBAASBBwAIQEaLyBHb29nbGUgQ2xvdWQg
U3RvcmFnZSBsb2NhdGlvbiBmb3IgdGhlIGlucHV0cy4KCgoKAwQAARIDHAgSCrkBCgQEAAIA
EgMgAkQaqwEgUmVxdWlyZWQuIEdvb2dsZSBDbG91ZCBTdG9yYWdlIFVSSXMgZm9yIHRoZSBp
bnB1dHMuIEEgVVJJIGlzIG9mIHRoZSBmb3JtOgogYGdzOi8vYnVja2V0L29iamVjdC1wcmVm
aXgtb3ItbmFtZWAKIFdoZXRoZXIgYSBwcmVmaXggb3IgbmFtZSBpcyB1c2VkIGRlcGVuZHMg
b24gdGhlIHVzZSBjYXNlLgoKDAoFBAACAAQSAyACCgoMCgUEAAIABRIDIAsRCgwKBQQAAgAB
EgMgEhYKDAoFBAACAAMSAyAZGgoMCgUEAAIACBIDIBtDCg8KCAQAAgAInAgAEgMgHEIKOwoC
BAESBCQAKwEaLyBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiBmb3IgdGhlIG91dHB1
dC4KCgoKAwQBARIDJAgWCvUBCgQEAQIAEgMqAhEa5wEgVGhlIEdvb2dsZSBDbG91ZCBTdG9y
YWdlIFVSSXMgZm9yIHRoZSBvdXRwdXQuIEEgVVJJIGlzIG9mIHRoZQogZm9ybToKIGBnczov
L2J1Y2tldC9vYmplY3QtcHJlZml4LW9yLW5hbWVgCiBXaGV0aGVyIGEgcHJlZml4IG9yIG5h
bWUgaXMgdXNlZCBkZXBlbmRzIG9uIHRoZSB1c2UgY2FzZS4gVGhlIHJlcXVlc3RpbmcKIHVz
ZXIgbXVzdCBoYXZlICJ3cml0ZS1wZXJtaXNzaW9uIiB0byB0aGUgYnVja2V0LgoKDAoFBAEC
AAUSAyoCCAoMCgUEAQIAARIDKgkMCgwKBQQBAgADEgMqDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Gcs::GcsSources ===
    # Fields for GcsSources
    # Field: uris Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Gcs::GcsDestination ===
    # Fields for GcsDestination
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Gcs - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/gcs.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Gcs;

    my $msg = Google::Cloud::Dialogflow::V2::Gcs::GcsSources->new({
        uris => $uris,
    });

    # Read or update a field
    my $val = $msg->uris();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Gcs::GcsSources->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/gcs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Gcs::GcsSources

Google Cloud Storage location for the inputs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uris() >> / C<< $msg->uris($value) >>

Type: C<String>

Required. Google Cloud Storage URIs for the inputs. A URI is of the form:
`gs://bucket/object-prefix-or-name`
Whether a prefix or name is used depends on the use case.

=back

=head2 Google::Cloud::Dialogflow::V2::Gcs::GcsDestination

Google Cloud Storage location for the output.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The Google Cloud Storage URIs for the output. A URI is of the
form:
`gs://bucket/object-prefix-or-name`
Whether a prefix or name is used depends on the use case. The requesting
user must have "write-permission" to the bucket.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Gcs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
