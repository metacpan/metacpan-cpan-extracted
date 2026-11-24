package Google::Cloud::Support::V2beta::EmailMessage;

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
    eval { require Google::Cloud::Support::V2beta::Actor };
    eval { require Google::Cloud::Support::V2beta::Content };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvZW1haWxfbWVzc2FnZS5wcm90bxIbZ29v
Z2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvY2xvdWQvc3VwcG9ydC92
MmJldGEvYWN0b3IucHJvdG8aKWdvb2dsZS9jbG91ZC9zdXBwb3J0L3YyYmV0YS9jb250ZW50
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIuMECgxFbWFpbE1lc3Nh
Z2USFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEj0KBWFjdG9yGAMgASgL
MiIuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLkFjdG9yQgPgQQNSBWFjdG9yEh0KB3N1
YmplY3QYBCABKAlCA+BBA1IHc3ViamVjdBI/ChlyZWNpcGllbnRfZW1haWxfYWRkcmVzc2Vz
GAUgAygJQgPgQQNSF3JlY2lwaWVudEVtYWlsQWRkcmVzc2VzEjEKEmNjX2VtYWlsX2FkZHJl
c3NlcxgGIAMoCUID4EEDUhBjY0VtYWlsQWRkcmVzc2VzElAKDGJvZHlfY29udGVudBgIIAEo
CzIoLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5UZXh0Q29udGVudEID4EEDUgtib2R5
Q29udGVudDrTAepBzwEKKGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9FbWFpbE1lc3Nh
Z2USPXByb2plY3RzL3twcm9qZWN0fS9jYXNlcy97Y2FzZX0vZW1haWxNZXNzYWdlcy97ZW1h
aWxfbWVzc2FnZX0SR29yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vY2FzZXMve2Nhc2V9
L2VtYWlsTWVzc2FnZXMve2VtYWlsX21lc3NhZ2V9Kg1lbWFpbE1lc3NhZ2VzMgxlbWFpbE1l
c3NhZ2VCzgEKH2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGFCEUVtYWlsTWVzc2Fn
ZVByb3RvUAFaOWNsb3VkLmdvb2dsZS5jb20vZ28vc3VwcG9ydC9hcGl2MmJldGEvc3VwcG9y
dHBiO3N1cHBvcnRwYqoCG0dvb2dsZS5DbG91ZC5TdXBwb3J0LlYyQmV0YcoCG0dvb2dsZVxD
bG91ZFxTdXBwb3J0XFYyYmV0YeoCHkdvb2dsZTo6Q2xvdWQ6OlN1cHBvcnQ6OlYyYmV0YUr2
DwoGEgQOAEMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAk
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAxCgkKAgMDEgMVADMKCQoCAwQSAxYA
KQoICgEIEgMYADgKCQoCCCUSAxgAOAoICgEIEgMZAFAKCQoCCAsSAxkAUAoICgEIEgMaACIK
CQoCCAoSAxoAIgoICgEIEgMbADIKCQoCCAgSAxsAMgoICgEIEgMcADgKCQoCCAESAxwAOAoI
CgEIEgMdADgKCQoCCCkSAx0AOAoICgEIEgMeADcKCQoCCC0SAx4ANwo2CgIEABIEIQBDARoq
IEFuIGVtYWlsIGFzc29jaWF0ZWQgd2l0aCBhIHN1cHBvcnQgY2FzZS4KCgoKAwQAARIDIQgU
CgsKAwQABxIEIgIoBAoNCgUEAAedCBIEIgIoBAo/CgQEAAIAEgMrAj0aMiBJZGVudGlmaWVy
LiBSZXNvdXJjZSBuYW1lIGZvciB0aGUgZW1haWwgbWVzc2FnZS4KCgwKBQQAAgAFEgMrAggK
DAoFBAACAAESAysJDQoMCgUEAAIAAxIDKxARCgwKBQQAAgAIEgMrEjwKDwoIBAACAAicCAAS
AysTOwpNCgQEAAIBEgQuAi8yGj8gT3V0cHV0IG9ubHkuIFRpbWUgd2hlbiB0aGlzIGVtYWls
IG1lc3NhZ2Ugb2JqZWN0IHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAy4CGwoMCgUEAAIBARID
LhwnCgwKBQQAAgEDEgMuKisKDAoFBAACAQgSAy8GMQoPCggEAAIBCJwIABIDLwcwCpcBCgQE
AAICEgMzAj4aiQEgT3V0cHV0IG9ubHkuIFRoZSB1c2VyIG9yIEdvb2dsZSBTdXBwb3J0IGFn
ZW50IHRoYXQgY3JlYXRlZCB0aGlzIGVtYWlsCiBtZXNzYWdlLiBUaGlzIGlzIGluZmVycmVk
IGZyb20gdGhlIGhlYWRlcnMgb24gdGhlIGVtYWlsIG1lc3NhZ2UuCgoMCgUEAAICBhIDMwIH
CgwKBQQAAgIBEgMzCA0KDAoFBAACAgMSAzMQEQoMCgUEAAICCBIDMxI9Cg8KCAQAAgIInAgA
EgMzEzwKMQoEBAACAxIDNgJBGiQgT3V0cHV0IG9ubHkuIFN1YmplY3Qgb2YgdGhlIGVtYWls
LgoKDAoFBAACAwUSAzYCCAoMCgUEAAIDARIDNgkQCgwKBQQAAgMDEgM2ExQKDAoFBAACAwgS
AzYVQAoPCggEAAIDCJwIABIDNhY/CkMKBAQAAgQSBDkCOjIaNSBPdXRwdXQgb25seS4gRW1h
aWwgYWRkcmVzc2VzIHRoZSBlbWFpbCB3YXMgc2VudCB0by4KCgwKBQQAAgQEEgM5AgoKDAoF
BAACBAUSAzkLEQoMCgUEAAIEARIDORIrCgwKBQQAAgQDEgM5Li8KDAoFBAACBAgSAzoGMQoP
CggEAAIECJwIABIDOgcwCj8KBAQAAgUSBD0CPjIaMSBPdXRwdXQgb25seS4gRW1haWwgYWRk
cmVzc2VzIENDZWQgb24gdGhlIGVtYWlsLgoKDAoFBAACBQQSAz0CCgoMCgUEAAIFBRIDPQsR
CgwKBQQAAgUBEgM9EiQKDAoFBAACBQMSAz0nKAoMCgUEAAIFCBIDPgYxCg8KCAQAAgUInAgA
EgM+BzAKewoEBAACBhIDQgJLGm4gT3V0cHV0IG9ubHkuIFRoZSBmdWxsIGVtYWlsIG1lc3Nh
Z2UgYm9keS4gQSBiZXN0LWVmZm9ydCBhdHRlbXB0IGlzIG1hZGUgdG8KIHJlbW92ZSBleHRy
YW5lb3VzIHJlcGx5IHRocmVhZHMuCgoMCgUEAAIGBhIDQgINCgwKBQQAAgYBEgNCDhoKDAoF
BAACBgMSA0IdHgoMCgUEAAIGCBIDQh9KCg8KCAQAAgYInAgAEgNCIEliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::EmailMessage::EmailMessage ===
    # Fields for EmailMessage
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: actor Type: 11 (.google.cloud.support.v2beta.Actor)
    # Field: subject Type: 9 ()
    # Field: recipient_email_addresses Type: 9 ()
    # Field: cc_email_addresses Type: 9 ()
    # Field: body_content Type: 11 (.google.cloud.support.v2beta.TextContent)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::EmailMessage - Compiled Protocol Buffers messages for google/cloud/support/v2beta/email_message.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::EmailMessage;

    my $msg = Google::Cloud::Support::V2beta::EmailMessage::EmailMessage->new({
        name => $name,
        create_time => $create_time,
        actor => $actor,
        subject => $subject,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::EmailMessage::EmailMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/email_message.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::EmailMessage::EmailMessage

An email associated with a support case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name for the email message.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when this email message object was created.

=item * C<< $msg->actor() >> / C<< $msg->actor($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Actor::Actor>)

Output only. The user or Google Support agent that created this email
message. This is inferred from the headers on the email message.

=item * C<< $msg->subject() >> / C<< $msg->subject($value) >>

Type: C<String>

Output only. Subject of the email.

=item * C<< $msg->recipient_email_addresses() >> / C<< $msg->recipient_email_addresses($value) >>

Type: C<String>

Output only. Email addresses the email was sent to.

=item * C<< $msg->cc_email_addresses() >> / C<< $msg->cc_email_addresses($value) >>

Type: C<String>

Output only. Email addresses CCed on the email.

=item * C<< $msg->body_content() >> / C<< $msg->body_content($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Content::TextContent>)

Output only. The full email message body. A best-effort attempt is made to
remove extraneous reply threads.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::EmailMessage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
