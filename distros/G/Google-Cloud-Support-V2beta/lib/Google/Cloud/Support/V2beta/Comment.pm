package Google::Cloud::Support::V2beta::Comment;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvY29tbWVudC5wcm90bxIbZ29vZ2xlLmNs
b3VkLnN1cHBvcnQudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEv
YWN0b3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iiwMKB0NvbW1l
bnQSGgoEbmFtZRgBIAEoCUIG4EEI4EEDUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkEKB2NyZWF0b3IY
AyABKAsyIi5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQWN0b3JCA+BBA1IHY3JlYXRv
chISCgRib2R5GAQgASgJUgRib2R5Ei0KD3BsYWluX3RleHRfYm9keRgFIAEoCUIFGAHgQQNS
DXBsYWluVGV4dEJvZHk6mwHqQZcBCiNjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vQ29t
bWVudBI8b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9jYXNlcy97Y2FzZX0vY29tbWVu
dHMve2NvbW1lbnR9EjJwcm9qZWN0cy97cHJvamVjdH0vY2FzZXMve2Nhc2V9L2NvbW1lbnRz
L3tjb21tZW50fULJAQofY29tLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YUIMQ29tbWVu
dFByb3RvUAFaOWNsb3VkLmdvb2dsZS5jb20vZ28vc3VwcG9ydC9hcGl2MmJldGEvc3VwcG9y
dHBiO3N1cHBvcnRwYqoCG0dvb2dsZS5DbG91ZC5TdXBwb3J0LlYyQmV0YcoCG0dvb2dsZVxD
bG91ZFxTdXBwb3J0XFYyYmV0YeoCHkdvb2dsZTo6Q2xvdWQ6OlN1cHBvcnQ6OlYyYmV0YUrc
DgoGEgQOAEQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
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
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAxCgkKAgMDEgMVACkKCAoBCBIDFwA4
CgkKAgglEgMXADgKCAoBCBIDGABQCgkKAggLEgMYAFAKCAoBCBIDGQAiCgkKAggKEgMZACIK
CAoBCBIDGgAtCgkKAggIEgMaAC0KCAoBCBIDGwA4CgkKAggBEgMbADgKCAoBCBIDHAA4CgkK
AggpEgMcADgKCAoBCBIDHQA3CgkKAggtEgMdADcK+QEKAgQAEgQkAEQBGuwBIEEgY29tbWVu
dCBhc3NvY2lhdGVkIHdpdGggYSBzdXBwb3J0IGNhc2UuCgogQ2FzZSBjb21tZW50cyBhcmUg
dGhlIHByaW1hcnkgd2F5IGZvciBHb29nbGUgU3VwcG9ydCB0byBjb21tdW5pY2F0ZSB3aXRo
IGEKIHVzZXIgd2hvIGhhcyBvcGVuZWQgYSBjYXNlLiBXaGVuIGEgdXNlciByZXNwb25kcyB0
byBHb29nbGUgU3VwcG9ydCwgdGhlCiB1c2VyJ3MgcmVzcG9uc2VzIGFsc28gYXBwZWFyIGFz
IGNvbW1lbnRzLgoKCgoDBAABEgMkCA8KCwoDBAAHEgQlAikECg0KBQQAB50IEgQlAikECkoK
BAQAAgASBCwCLwQaPCBPdXRwdXQgb25seS4gSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIGNvbW1lbnQuCgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMsCQ0KDAoFBAAC
AAMSAywQEQoNCgUEAAIACBIELBIvAwoPCggEAAIACJwIABIDLQQsCg8KCAQAAgAInAgBEgMu
BC0KQwoEBAACARIEMgIzMho1IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBjb21t
ZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAzICGwoMCgUEAAIBARIDMhwnCgwKBQQAAgED
EgMyKisKDAoFBAACAQgSAzMGMQoPCggEAAIBCJwIABIDMwcwClUKBAQAAgISAzYCQBpIIE91
dHB1dCBvbmx5LiBUaGUgdXNlciBvciBHb29nbGUgU3VwcG9ydCBhZ2VudCB3aG8gY3JlYXRl
ZCB0aGUgY29tbWVudC4KCgwKBQQAAgIGEgM2AgcKDAoFBAACAgESAzYIDwoMCgUEAAICAxID
NhITCgwKBQQAAgIIEgM2FD8KDwoIBAACAgicCAASAzYVPgpECgQEAAIDEgM7AhIaNyBUaGUg
ZnVsbCBjb21tZW50IGJvZHkuCgogTWF4aW11bSBvZiAxMjgwMCBjaGFyYWN0ZXJzLgoKDAoF
BAACAwUSAzsCCAoMCgUEAAIDARIDOwkNCgwKBQQAAgMDEgM7EBEKiAEKBAQAAgQSBEICQ0Ua
eiBPdXRwdXQgb25seS4gREVQUkVDQVRFRC4gRE8gTk9UIFVTRS4KCiBBIGR1cGxpY2F0ZSBv
ZiB0aGUgYGJvZHlgIGZpZWxkLgoKIFRoaXMgZmllbGQgaXMgb25seSBwcmVzZW50IGZvciBs
ZWdhY3kgcmVhc29ucy4KCgwKBQQAAgQFEgNCAggKDAoFBAACBAESA0IJGAoMCgUEAAIEAxID
QhscCgwKBQQAAgQIEgNDBkQKDQoGBAACBAgDEgNDBxgKDwoIBAACBAicCAASA0MaQ2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::Comment::Comment ===
    # Fields for Comment
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 11 (.google.cloud.support.v2beta.Actor)
    # Field: body Type: 9 ()
    # Field: plain_text_body Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::Comment - Compiled Protocol Buffers messages for google/cloud/support/v2beta/comment.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::Comment;

    my $msg = Google::Cloud::Support::V2beta::Comment::Comment->new({
        name => $name,
        create_time => $create_time,
        creator => $creator,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::Comment::Comment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/comment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::Comment::Comment

A comment associated with a support case.

Case comments are the primary way for Google Support to communicate with a
user who has opened a case. When a user responds to Google Support, the
user's responses also appear as comments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the comment.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the comment was created.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Actor::Actor>)

Output only. The user or Google Support agent who created the comment.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

The full comment body.

Maximum of 12800 characters.

=item * C<< $msg->plain_text_body() >> / C<< $msg->plain_text_body($value) >>

Type: C<String>

Output only. DEPRECATED. DO NOT USE.

A duplicate of the `body` field.

This field is only present for legacy reasons.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::Comment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
