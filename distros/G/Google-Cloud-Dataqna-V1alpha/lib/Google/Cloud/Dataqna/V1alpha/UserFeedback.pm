package Google::Cloud::Dataqna::V1alpha::UserFeedback;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFscGhhL3VzZXJfZmVlZGJhY2sucHJvdG8SHGdv
b2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i+QIKDFVzZXJGZWVkYmFjaxIXCgRu
YW1lGAEgASgJQgPgQQJSBG5hbWUSLAoSZnJlZV9mb3JtX2ZlZWRiYWNrGAIgASgJUhBmcmVl
Rm9ybUZlZWRiYWNrElUKBnJhdGluZxgDIAEoDjI9Lmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYx
YWxwaGEuVXNlckZlZWRiYWNrLlVzZXJGZWVkYmFja1JhdGluZ1IGcmF0aW5nIlYKElVzZXJG
ZWVkYmFja1JhdGluZxIkCiBVU0VSX0ZFRURCQUNLX1JBVElOR19VTlNQRUNJRklFRBAAEgwK
CFBPU0lUSVZFEAESDAoITkVHQVRJVkUQAjpz6kFwCiNkYXRhcW5hLmdvb2dsZWFwaXMuY29t
L1VzZXJGZWVkYmFjaxJJcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3F1ZXN0aW9ucy97cXVlc3Rpb259L3VzZXJGZWVkYmFja0LTAQogY29tLmdvb2dsZS5jbG91
ZC5kYXRhcW5hLnYxYWxwaGFCEVVzZXJGZWVkYmFja1Byb3RvUAFaOmNsb3VkLmdvb2dsZS5j
b20vZ28vZGF0YXFuYS9hcGl2MWFscGhhL2RhdGFxbmFwYjtkYXRhcW5hcGKqAhxHb29nbGUu
Q2xvdWQuRGF0YVFuQS5WMUFscGhhygIcR29vZ2xlXENsb3VkXERhdGFRbkFcVjFhbHBoYeoC
H0dvb2dsZTo6Q2xvdWQ6OkRhdGFRbkE6OlYxYWxwaGFKzAwKBhIEDgA6AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCAoBCBIDFQA5CgkKAgglEgMVADkKCAoBCBIDFgBRCgkKAggLEgMWAFEKCAoBCBIDFwAi
CgkKAggKEgMXACIKCAoBCBIDGAAyCgkKAggIEgMYADIKCAoBCBIDGQA5CgkKAggBEgMZADkK
CAoBCBIDGgA5CgkKAggpEgMaADkKCAoBCBIDGwA4CgkKAggtEgMbADgKKgoCBAASBB4AOgEa
HiBGZWVkYmFjayBwcm92aWRlZCBieSBhIHVzZXIuCgoKCgMEAAESAx4IFAoLCgMEAAcSBB8C
IgQKDQoFBAAHnQgSBB8CIgQKMAoEBAAEABIEJQIuAxoiIEVudW1lcmF0aW9uIG9mIGZlZWRi
YWNrIHJhdGluZ3MuCgoMCgUEAAQAARIDJQcZCikKBgQABAACABIDJwQpGhogTm8gcmF0aW5n
IHdhcyBzcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMnBCQKDgoHBAAEAAIAAhIDJycoCjUKBgQA
BAACARIDKgQRGiYgVGhlIHVzZXIgcHJvdmlkZWQgcG9zaXRpdmUgZmVlZGJhY2suCgoOCgcE
AAQAAgEBEgMqBAwKDgoHBAAEAAIBAhIDKg8QCjUKBgQABAACAhIDLQQRGiYgVGhlIHVzZXIg
cHJvdmlkZWQgbmVnYXRpdmUgZmVlZGJhY2suCgoOCgcEAAQAAgIBEgMtBAwKDgoHBAAEAAIC
AhIDLQ8QCr8BCgQEAAIAEgMzAjsasQEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmll
ciBmb3IgdGhlIHVzZXIgZmVlZGJhY2suCiBVc2VyIGZlZWRiYWNrIGlzIGEgc2luZ2xldG9u
IHJlc291cmNlIG9uIGEgUXVlc3Rpb24uCiBFeGFtcGxlOiBgcHJvamVjdHMvZm9vL2xvY2F0
aW9ucy9iYXIvcXVlc3Rpb25zLzEyMzQvdXNlckZlZWRiYWNrYAoKDAoFBAACAAUSAzMCCAoM
CgUEAAIAARIDMwkNCgwKBQQAAgADEgMzEBEKDAoFBAACAAgSAzMSOgoPCggEAAIACJwIABID
MxM5CjsKBAQAAgESAzYCIBouIEZyZWUgZm9ybSB1c2VyIGZlZWRiYWNrLCBzdWNoIGFzIGEg
dGV4dCBib3guCgoMCgUEAAIBBRIDNgIICgwKBQQAAgEBEgM2CRsKDAoFBAACAQMSAzYeHwon
CgQEAAICEgM5AiAaGiBUaGUgdXNlciBmZWVkYmFjayByYXRpbmcKCgwKBQQAAgIGEgM5AhQK
DAoFBAACAgESAzkVGwoMCgUEAAICAxIDOR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback ===
    # Fields for UserFeedback
    # Field: name Type: 9 ()
    # Field: free_form_feedback Type: 9 ()
    # Field: rating Type: 14 (.google.cloud.dataqna.v1alpha.UserFeedback.UserFeedbackRating)

# Enum: UserFeedback::UserFeedbackRating
our $UserFeedback_USER_FEEDBACK_RATING_UNSPECIFIED = 0;
our $UserFeedback_POSITIVE = 1;
our $UserFeedback_NEGATIVE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataqna::V1alpha::UserFeedback - Compiled Protocol Buffers messages for google/cloud/dataqna/v1alpha/user_feedback.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataqna::V1alpha::UserFeedback;

    my $msg = Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback->new({
        name => $name,
        free_form_feedback => $free_form_feedback,
        rating => $rating,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataqna/v1alpha/user_feedback.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback

Feedback provided by a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the user feedback.
User feedback is a singleton resource on a Question.
Example: `projects/foo/locations/bar/questions/1234/userFeedback`

=item * C<< $msg->free_form_feedback() >> / C<< $msg->free_form_feedback($value) >>

Type: C<String>

Free form user feedback, such as a text box.

=item * C<< $msg->rating() >> / C<< $msg->rating($value) >>

Type: C<Enum> (L<Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedbackRating>)

The user feedback rating

=back

=head3 Enum: UserFeedback::UserFeedbackRating

=over 4

=item * C<USER_FEEDBACK_RATING_UNSPECIFIED> => C<0>

=item * C<POSITIVE> => C<1>

=item * C<NEGATIVE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataqna::V1alpha::UserFeedback::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
