package Google::Cloud::Dialogflow::V2beta1::ValidationResult;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3ZhbGlkYXRpb25fcmVzdWx0LnBy
b3RvEh9nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExIv0BCg9WYWxpZGF0aW9uRXJy
b3ISVQoIc2V2ZXJpdHkYASABKA4yOS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LlZhbGlkYXRpb25FcnJvci5TZXZlcml0eVIIc2V2ZXJpdHkSGAoHZW50cmllcxgDIAMoCVIH
ZW50cmllcxIjCg1lcnJvcl9tZXNzYWdlGAQgASgJUgxlcnJvck1lc3NhZ2UiVAoIU2V2ZXJp
dHkSGAoUU0VWRVJJVFlfVU5TUEVDSUZJRUQQABIICgRJTkZPEAESCwoHV0FSTklORxACEgkK
BUVSUk9SEAMSDAoIQ1JJVElDQUwQBCJxChBWYWxpZGF0aW9uUmVzdWx0El0KEXZhbGlkYXRp
b25fZXJyb3JzGAEgAygLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5WYWxp
ZGF0aW9uRXJyb3JSEHZhbGlkYXRpb25FcnJvcnNCqgEKI2NvbS5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExQhVWYWxpZGF0aW9uUmVzdWx0UHJvdG9QAVpDY2xvdWQuZ29vZ2xl
LmNvbS9nby9kaWFsb2dmbG93L2FwaXYyYmV0YTEvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dw
YqICAkRGqgIfR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJCZXRhMUrXEgoGEgQOAEgBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCggKAQgSAxIAPAoJ
CgIIJRIDEgA8CggKAQgSAxMAWgoJCgIICxIDEwBaCggKAQgSAxQAIgoJCgIIChIDFAAiCggK
AQgSAxUANgoJCgIICBIDFQA2CggKAQgSAxYAPAoJCgIIARIDFgA8CggKAQgSAxcAIAoJCgII
JBIDFwAgCjMKAgQAEgQaAEIBGicgUmVwcmVzZW50cyBhIHNpbmdsZSB2YWxpZGF0aW9uIGVy
cm9yLgoKCgoDBAABEgMaCBcKLwoEBAAEABIEHAIrAxohIFJlcHJlc2VudHMgYSBsZXZlbCBv
ZiBzZXZlcml0eS4KCgwKBQQABAABEgMcBw8KQAoGBAAEAAIAEgMeBB0aMSBOb3Qgc3BlY2lm
aWVkLiBUaGlzIHZhbHVlIHNob3VsZCBuZXZlciBiZSB1c2VkLgoKDgoHBAAEAAIAARIDHgQY
Cg4KBwQABAACAAISAx4bHApECgYEAAQAAgESAyEEDRo1IFRoZSBhZ2VudCBkb2Vzbid0IGZv
bGxvdyBEaWFsb2dmbG93IGJlc3QgcHJhY3RpY2VzLgoKDgoHBAAEAAIBARIDIQQICg4KBwQA
BAACAQISAyELDAo2CgYEAAQAAgISAyQEEBonIFRoZSBhZ2VudCBtYXkgbm90IGJlaGF2ZSBh
cyBleHBlY3RlZC4KCg4KBwQABAACAgESAyQECwoOCgcEAAQAAgICEgMkDg8KOwoGBAAEAAID
EgMnBA4aLCBUaGUgYWdlbnQgbWF5IGV4cGVyaWVuY2UgcGFydGlhbCBmYWlsdXJlcy4KCg4K
BwQABAACAwESAycECQoOCgcEAAQAAgMCEgMnDA0KLwoGBAAEAAIEEgMqBBEaICBUaGUgYWdl
bnQgbWF5IGNvbXBsZXRlbHkgZmFpbC4KCg4KBwQABAACBAESAyoEDAoOCgcEAAQAAgQCEgMq
DxAKKQoEBAACABIDLgIYGhwgVGhlIHNldmVyaXR5IG9mIHRoZSBlcnJvci4KCgwKBQQAAgAG
EgMuAgoKDAoFBAACAAESAy4LEwoMCgUEAAIAAxIDLhYXCqYFCgQEAAIBEgM+Ah4amAUgVGhl
IG5hbWVzIG9mIHRoZSBlbnRyaWVzIHRoYXQgdGhlIGVycm9yIGlzIGFzc29jaWF0ZWQgd2l0
aC4KIEZvcm1hdDoKCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnRgLCBpZiB0aGUg
ZXJyb3IgaXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBlbnRpcmUKIGFnZW50LgogLSBgcHJvamVj
dHMvPFByb2plY3QgSUQ+L2FnZW50L2ludGVudHMvPEludGVudCBJRD5gLCBpZiB0aGUgZXJy
b3IgaXMKIGFzc29jaWF0ZWQgd2l0aCBjZXJ0YWluIGludGVudHMuCiAtIGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vYWdlbnQvaW50ZW50cy88SW50ZW50CiBJZD4vdHJhaW5pbmdQaHJhc2Vz
LzxUcmFpbmluZyBQaHJhc2UgSUQ+YCwgaWYgdGhlIGVycm9yIGlzIGFzc29jaWF0ZWQgd2l0
aAogY2VydGFpbiBpbnRlbnQgdHJhaW5pbmcgcGhyYXNlcy4KIC0gYHByb2plY3RzLzxQcm9q
ZWN0IElEPi9hZ2VudC9pbnRlbnRzLzxJbnRlbnQgSWQ+L3BhcmFtZXRlcnMvPFBhcmFtZXRl
cgogSUQ+YCwgaWYgdGhlIGVycm9yIGlzIGFzc29jaWF0ZWQgd2l0aCBjZXJ0YWluIGludGVu
dCBwYXJhbWV0ZXJzLgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2VudGl0aWVz
LzxFbnRpdHkgSUQ+YCwgaWYgdGhlIGVycm9yIGlzCiBhc3NvY2lhdGVkIHdpdGggY2VydGFp
biBlbnRpdGllcy4KCgwKBQQAAgEEEgM+AgoKDAoFBAACAQUSAz4LEQoMCgUEAAIBARIDPhIZ
CgwKBQQAAgEDEgM+HB0KKgoEBAACAhIDQQIbGh0gVGhlIGRldGFpbGVkIGVycm9yIG1lc3Nh
Z2UuCgoMCgUEAAICBRIDQQIICgwKBQQAAgIBEgNBCRYKDAoFBAACAgMSA0EZGgo4CgIEARIE
RQBIARosIFJlcHJlc2VudHMgdGhlIG91dHB1dCBvZiBhZ2VudCB2YWxpZGF0aW9uLgoKCgoD
BAEBEgNFCBgKLgoEBAECABIDRwIxGiEgQ29udGFpbnMgYWxsIHZhbGlkYXRpb24gZXJyb3Jz
LgoKDAoFBAECAAQSA0cCCgoMCgUEAQIABhIDRwsaCgwKBQQBAgABEgNHGywKDAoFBAECAAMS
A0cvMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationError ===
    # Fields for ValidationError
    # Field: severity Type: 14 (.google.cloud.dialogflow.v2beta1.ValidationError.Severity)
    # Field: entries Type: 9 ()
    # Field: error_message Type: 9 ()

# Enum: ValidationError::Severity
our $ValidationError_SEVERITY_UNSPECIFIED = 0;
our $ValidationError_INFO = 1;
our $ValidationError_WARNING = 2;
our $ValidationError_ERROR = 3;
our $ValidationError_CRITICAL = 4;

# === Message: Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationResult ===
    # Fields for ValidationResult
    # Field: validation_errors Type: 11 (.google.cloud.dialogflow.v2beta1.ValidationError)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::ValidationResult - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/validation_result.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::ValidationResult;

    my $msg = Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationError->new({
        severity => $severity,
        entries => $entries,
        error_message => $error_message,
    });

    # Read or update a field
    my $val = $msg->severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationError->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/validation_result.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationError

Represents a single validation error.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::ValidationError::Severity>)

The severity of the error.

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<String>

The names of the entries that the error is associated with.
Format:

- `projects/<Project ID>/agent`, if the error is associated with the entire
agent.
- `projects/<Project ID>/agent/intents/<Intent ID>`, if the error is
associated with certain intents.
- `projects/<Project ID>/agent/intents/<Intent
Id>/trainingPhrases/<Training Phrase ID>`, if the error is associated with
certain intent training phrases.
- `projects/<Project ID>/agent/intents/<Intent Id>/parameters/<Parameter
ID>`, if the error is associated with certain intent parameters.
- `projects/<Project ID>/agent/entities/<Entity ID>`, if the error is
associated with certain entities.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The detailed error message.

=back

=head3 Enum: ValidationError::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<INFO> => C<1>

=item * C<WARNING> => C<2>

=item * C<ERROR> => C<3>

=item * C<CRITICAL> => C<4>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationResult

Represents the output of agent validation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->validation_errors() >> / C<< $msg->validation_errors($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::ValidationResult::ValidationError>)

Contains all validation errors.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::ValidationResult::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
