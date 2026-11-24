package Google::Cloud::Dialogflow::Cx::V3::Inline;

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
Cipnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9pbmxpbmUucHJvdG8SHWdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LmN4LnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
IjIKEUlubGluZURlc3RpbmF0aW9uEh0KB2NvbnRlbnQYASABKAxCA+BBA1IHY29udGVudCIo
CgxJbmxpbmVTb3VyY2USGAoHY29udGVudBgBIAEoDFIHY29udGVudEKuAQohY29tLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzQgtJbmxpbmVQcm90b1ABWjFjbG91ZC5nb29nbGUu
Y29tL2dvL2RpYWxvZ2Zsb3cvY3gvYXBpdjMvY3hwYjtjeHBiogICREaqAh1Hb29nbGUuQ2xv
dWQuRGlhbG9nZmxvdy5DeC5WM+oCIUdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6OkNYOjpW
M0rxCgoGEgQOACkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
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
EAAmCgkKAgMAEgMSACkKCAoBCBIDFAA6CgkKAgglEgMUADoKCAoBCBIDFQBICgkKAggLEgMV
AEgKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAsCgkKAggIEgMXACwKCAoBCBIDGAA6
CgkKAggBEgMYADoKCAoBCBIDGQAgCgkKAggkEgMZACAKCAoBCBIDGgA6CgkKAggtEgMaADoK
qgEKAgQAEgQeACIBGp0BIElubGluZSBkZXN0aW5hdGlvbiBmb3IgYSBEaWFsb2dmbG93IG9w
ZXJhdGlvbiB0aGF0IHdyaXRlcyBvciBleHBvcnRzIG9iamVjdHMKIChlLmcuIFtpbnRlbnRz
XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5JbnRlbnRdKSBvdXRzaWRlIG9mIERp
YWxvZ2Zsb3cuCgoKCgMEAAESAx4IGQpoCgQEAAIAEgMhAkAaWyBPdXRwdXQgb25seS4gVGhl
IHVuY29tcHJlc3NlZCBieXRlIGNvbnRlbnQgZm9yIHRoZSBvYmplY3RzLgogT25seSBwb3B1
bGF0ZWQgaW4gcmVzcG9uc2VzLgoKDAoFBAACAAUSAyECBwoMCgUEAAIAARIDIQgPCgwKBQQA
AgADEgMhEhMKDAoFBAACAAgSAyEUPwoPCggEAAIACJwIABIDIRU+Cp4BCgIEARIEJgApARqR
ASBJbmxpbmUgc291cmNlIGZvciBhIERpYWxvZ2Zsb3cgb3BlcmF0aW9uIHRoYXQgcmVhZHMg
b3IgaW1wb3J0cyBvYmplY3RzCiAoZS5nLiBbaW50ZW50c11bZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjMuSW50ZW50XSkgaW50byBEaWFsb2dmbG93LgoKCgoDBAEBEgMmCBQKPQoE
BAECABIDKAIUGjAgVGhlIHVuY29tcHJlc3NlZCBieXRlIGNvbnRlbnQgZm9yIHRoZSBvYmpl
Y3RzLgoKDAoFBAECAAUSAygCBwoMCgUEAQIAARIDKAgPCgwKBQQBAgADEgMoEhNiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Inline::InlineDestination ===
    # Fields for InlineDestination
    # Field: content Type: 12 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Inline::InlineSource ===
    # Fields for InlineSource
    # Field: content Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Inline - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/inline.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Inline;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Inline::InlineDestination->new({
        content => $content,
    });

    # Read or update a field
    my $val = $msg->content();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Inline::InlineDestination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/inline.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Inline::InlineDestination

Inline destination for a Dialogflow operation that writes or exports objects
(e.g. [intents][google.cloud.dialogflow.cx.v3.Intent]) outside of Dialogflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

Output only. The uncompressed byte content for the objects.
Only populated in responses.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Inline::InlineSource

Inline source for a Dialogflow operation that reads or imports objects
(e.g. [intents][google.cloud.dialogflow.cx.v3.Intent]) into Dialogflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

The uncompressed byte content for the objects.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Inline::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
