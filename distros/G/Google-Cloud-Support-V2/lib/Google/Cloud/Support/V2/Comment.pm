package Google::Cloud::Support::V2::Comment;

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
    eval { require Google::Cloud::Support::V2::Actor };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9jb21tZW50LnByb3RvEhdnb29nbGUuY2xvdWQu
c3VwcG9ydC52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIvYWN0b3IucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ihwMKB0NvbW1lbnQSGgoEbmFtZRgB
IAEoCUIG4EEI4EEDUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEj0KB2NyZWF0b3IYAyABKAsyHi5nb29n
bGUuY2xvdWQuc3VwcG9ydC52Mi5BY3RvckID4EEDUgdjcmVhdG9yEhIKBGJvZHkYBCABKAlS
BGJvZHkSLQoPcGxhaW5fdGV4dF9ib2R5GAUgASgJQgUYAeBBA1INcGxhaW5UZXh0Qm9keTqb
AepBlwEKI2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9Db21tZW50Ejxvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb259L2Nhc2VzL3tjYXNlfS9jb21tZW50cy97Y29tbWVudH0SMnBy
b2plY3RzL3twcm9qZWN0fS9jYXNlcy97Y2FzZX0vY29tbWVudHMve2NvbW1lbnR9QrUBChtj
b20uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJCDENvbW1lbnRQcm90b1ABWjVjbG91ZC5nb29n
bGUuY29tL2dvL3N1cHBvcnQvYXBpdjIvc3VwcG9ydHBiO3N1cHBvcnRwYqoCF0dvb2dsZS5D
bG91ZC5TdXBwb3J0LlYyygIXR29vZ2xlXENsb3VkXFN1cHBvcnRcVjLqAhpHb29nbGU6OkNs
b3VkOjpTdXBwb3J0OjpWMkrcDgoGEgQOAEQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAtCgkK
AgMDEgMVACkKCAoBCBIDFwA0CgkKAgglEgMXADQKCAoBCBIDGABMCgkKAggLEgMYAEwKCAoB
CBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAtCgkKAggIEgMaAC0KCAoBCBIDGwA0CgkKAggB
EgMbADQKCAoBCBIDHAA0CgkKAggpEgMcADQKCAoBCBIDHQAzCgkKAggtEgMdADMK+QEKAgQA
EgQkAEQBGuwBIEEgY29tbWVudCBhc3NvY2lhdGVkIHdpdGggYSBzdXBwb3J0IGNhc2UuCgog
Q2FzZSBjb21tZW50cyBhcmUgdGhlIHByaW1hcnkgd2F5IGZvciBHb29nbGUgU3VwcG9ydCB0
byBjb21tdW5pY2F0ZSB3aXRoIGEKIHVzZXIgd2hvIGhhcyBvcGVuZWQgYSBjYXNlLiBXaGVu
IGEgdXNlciByZXNwb25kcyB0byBHb29nbGUgU3VwcG9ydCwgdGhlCiB1c2VyJ3MgcmVzcG9u
c2VzIGFsc28gYXBwZWFyIGFzIGNvbW1lbnRzLgoKCgoDBAABEgMkCA8KCwoDBAAHEgQlAikE
Cg0KBQQAB50IEgQlAikECkoKBAQAAgASBCwCLwQaPCBPdXRwdXQgb25seS4gSWRlbnRpZmll
ci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGNvbW1lbnQuCgoMCgUEAAIABRIDLAIICgwK
BQQAAgABEgMsCQ0KDAoFBAACAAMSAywQEQoNCgUEAAIACBIELBIvAwoPCggEAAIACJwIABID
LQQsCg8KCAQAAgAInAgBEgMuBC0KQwoEBAACARIEMgIzMho1IE91dHB1dCBvbmx5LiBUaGUg
dGltZSB3aGVuIHRoZSBjb21tZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAzICGwoMCgUE
AAIBARIDMhwnCgwKBQQAAgEDEgMyKisKDAoFBAACAQgSAzMGMQoPCggEAAIBCJwIABIDMwcw
ClUKBAQAAgISAzYCQBpIIE91dHB1dCBvbmx5LiBUaGUgdXNlciBvciBHb29nbGUgU3VwcG9y
dCBhZ2VudCB3aG8gY3JlYXRlZCB0aGUgY29tbWVudC4KCgwKBQQAAgIGEgM2AgcKDAoFBAAC
AgESAzYIDwoMCgUEAAICAxIDNhITCgwKBQQAAgIIEgM2FD8KDwoIBAACAgicCAASAzYVPgpE
CgQEAAIDEgM7AhIaNyBUaGUgZnVsbCBjb21tZW50IGJvZHkuCgogTWF4aW11bSBvZiAxMjgw
MCBjaGFyYWN0ZXJzLgoKDAoFBAACAwUSAzsCCAoMCgUEAAIDARIDOwkNCgwKBQQAAgMDEgM7
EBEKiAEKBAQAAgQSBEICQ0UaeiBPdXRwdXQgb25seS4gREVQUkVDQVRFRC4gRE8gTk9UIFVT
RS4KCiBBIGR1cGxpY2F0ZSBvZiB0aGUgYGJvZHlgIGZpZWxkLgoKIFRoaXMgZmllbGQgaXMg
b25seSBwcmVzZW50IGZvciBsZWdhY3kgcmVhc29ucy4KCgwKBQQAAgQFEgNCAggKDAoFBAAC
BAESA0IJGAoMCgUEAAIEAxIDQhscCgwKBQQAAgQIEgNDBkQKDQoGBAACBAgDEgNDBxgKDwoI
BAACBAicCAASA0MaQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::Comment::Comment ===
    # Fields for Comment
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 11 (.google.cloud.support.v2.Actor)
    # Field: body Type: 9 ()
    # Field: plain_text_body Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::Comment - Compiled Protocol Buffers messages for google/cloud/support/v2/comment.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::Comment;

    my $msg = Google::Cloud::Support::V2::Comment::Comment->new({
        name => $name,
        create_time => $create_time,
        creator => $creator,
        body => $body,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::Comment::Comment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/comment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::Comment::Comment

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

Type: C<Message> (L<Google::Cloud::Support::V2::Actor::Actor>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::Comment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
