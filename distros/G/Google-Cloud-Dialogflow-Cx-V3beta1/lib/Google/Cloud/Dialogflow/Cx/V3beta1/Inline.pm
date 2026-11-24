package Google::Cloud::Dialogflow::Cx::V3beta1::Inline;

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
Ci9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2lubGluZS5wcm90bxIiZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90byIyChFJbmxpbmVEZXN0aW5hdGlvbhIdCgdjb250ZW50GAEgASgMQgPgQQNS
B2NvbnRlbnQiKAoMSW5saW5lU291cmNlEhgKB2NvbnRlbnQYASABKAxSB2NvbnRlbnRCwgEK
JmNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExQgtJbmxpbmVQcm90b1AB
WjZjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvY3gvYXBpdjNiZXRhMS9jeHBiO2N4
cGKiAgJERqoCIkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LkN4LlYzQmV0YTHqAiZHb29nbGU6
OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNiZXRhMUr8CgoGEgQOACoBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACkKCAoBCBIDFAA/
CgkKAgglEgMUAD8KCAoBCBIDFQBNCgkKAggLEgMVAE0KCAoBCBIDFgAiCgkKAggKEgMWACIK
CAoBCBIDFwAsCgkKAggIEgMXACwKCAoBCBIDGAA/CgkKAggBEgMYAD8KCAoBCBIDGQAgCgkK
AggkEgMZACAKCAoBCBIDGgA/CgkKAggtEgMaAD8KsAEKAgQAEgQfACMBGqMBIElubGluZSBk
ZXN0aW5hdGlvbiBmb3IgYSBEaWFsb2dmbG93IG9wZXJhdGlvbiB0aGF0IHdyaXRlcyBvciBl
eHBvcnRzIG9iamVjdHMKIChlLmcuIFtpbnRlbnRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52M2JldGExLkludGVudF0pIG91dHNpZGUgb2YKIERpYWxvZ2Zsb3cuCgoKCgMEAAES
Ax8IGQpoCgQEAAIAEgMiAkAaWyBPdXRwdXQgb25seS4gVGhlIHVuY29tcHJlc3NlZCBieXRl
IGNvbnRlbnQgZm9yIHRoZSBvYmplY3RzLgogT25seSBwb3B1bGF0ZWQgaW4gcmVzcG9uc2Vz
LgoKDAoFBAACAAUSAyICBwoMCgUEAAIAARIDIggPCgwKBQQAAgADEgMiEhMKDAoFBAACAAgS
AyIUPwoPCggEAAIACJwIABIDIhU+CqMBCgIEARIEJwAqARqWASBJbmxpbmUgc291cmNlIGZv
ciBhIERpYWxvZ2Zsb3cgb3BlcmF0aW9uIHRoYXQgcmVhZHMgb3IgaW1wb3J0cyBvYmplY3Rz
CiAoZS5nLiBbaW50ZW50c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5J
bnRlbnRdKSBpbnRvIERpYWxvZ2Zsb3cuCgoKCgMEAQESAycIFAo9CgQEAQIAEgMpAhQaMCBU
aGUgdW5jb21wcmVzc2VkIGJ5dGUgY29udGVudCBmb3IgdGhlIG9iamVjdHMuCgoMCgUEAQIA
BRIDKQIHCgwKBQQBAgABEgMpCA8KDAoFBAECAAMSAykSE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination ===
    # Fields for InlineDestination
    # Field: content Type: 12 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineSource ===
    # Fields for InlineSource
    # Field: content Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Inline - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/inline.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Inline;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination->new({
        content => $content,
    });

    # Read or update a field
    my $val = $msg->content();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/inline.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineDestination

Inline destination for a Dialogflow operation that writes or exports objects
(e.g. [intents][google.cloud.dialogflow.cx.v3beta1.Intent]) outside of
Dialogflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

Output only. The uncompressed byte content for the objects.
Only populated in responses.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Inline::InlineSource

Inline source for a Dialogflow operation that reads or imports objects
(e.g. [intents][google.cloud.dialogflow.cx.v3beta1.Intent]) into Dialogflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

The uncompressed byte content for the objects.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Inline::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
