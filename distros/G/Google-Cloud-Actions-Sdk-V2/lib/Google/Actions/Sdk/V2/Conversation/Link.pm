package Google::Actions::Sdk::V2::Conversation::Link;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2xp
bmsucHJvdG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24iWwoETGluaxIS
CgRuYW1lGAEgASgJUgRuYW1lEj8KBG9wZW4YAiABKAsyKy5nb29nbGUuYWN0aW9ucy5zZGsu
djIuY29udmVyc2F0aW9uLk9wZW5VcmxSBG9wZW4iXAoHT3BlblVybBIQCgN1cmwYASABKAlS
A3VybBI/CgRoaW50GAIgASgOMisuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlv
bi5VcmxIaW50UgRoaW50KigKB1VybEhpbnQSFAoQTElOS19VTlNQRUNJRklFRBAAEgcKA0FN
UBABQoUBCiZjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbkIJTGlua1By
b3RvUAFaTmdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9z
ZGsvdjIvY29udmVyc2F0aW9uO2NvbnZlcnNhdGlvbkrLCwoGEgQOADIBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCggKAQgSAxIAZQoJCgIICxIDEgBl
CggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQAKgoJCgIICBIDFAAqCggKAQgSAxUAPwoJ
CgIIARIDFQA/ChsKAgQAEgQYAB4BGg8gTGluayBjb250ZW50LgoKCgoDBAABEgMYCAwKHwoE
BAACABIDGgISGhIgTmFtZSBvZiB0aGUgbGluawoKDAoFBAACAAUSAxoCCAoMCgUEAAIAARID
GgkNCgwKBQQAAgADEgMaEBEKNgoEBAACARIDHQITGikgV2hhdCBoYXBwZW5zIHdoZW4gYSB1
c2VyIG9wZW5zIHRoZSBsaW5rCgoMCgUEAAIBBhIDHQIJCgwKBQQAAgEBEgMdCg4KDAoFBAAC
AQMSAx0REgo0CgIEARIEIQAoARooIEFjdGlvbiB0YWtlbiB3aGVuIGEgdXNlciBvcGVucyBh
IGxpbmsuCgoKCgMEAQESAyEIDwpxCgQEAQIAEgMkAhEaZCBUaGUgdXJsIGZpZWxkIHdoaWNo
IGNvdWxkIGJlIGFueSBvZjoKIC0gaHR0cC9odHRwcyB1cmxzIGZvciBvcGVuaW5nIGFuIEFw
cC1saW5rZWQgQXBwIG9yIGEgd2VicGFnZQoKDAoFBAECAAUSAyQCCAoMCgUEAQIAARIDJAkM
CgwKBQQBAgADEgMkDxAKMQoEBAECARIDJwITGiQgSW5kaWNhdGVzIGEgaGludCBmb3IgdGhl
IHVybCB0eXBlLgoKDAoFBAECAQYSAycCCQoMCgUEAQIBARIDJwoOCgwKBQQBAgEDEgMnERIK
KwoCBQASBCsAMgEaHyBEaWZmZXJlbnQgdHlwZXMgb2YgdXJsIGhpbnRzLgoKCgoDBQABEgMr
BQwKGgoEBQACABIDLQIXGg0gVW5zcGVjaWZpZWQKCgwKBQUAAgABEgMtAhIKDAoFBQACAAIS
Ay0VFgqEAQoEBQACARIDMQIKGncgVVJMIHRoYXQgcG9pbnRzIGRpcmVjdGx5IHRvIEFNUCBj
b250ZW50LCBvciB0byBhIGNhbm9uaWNhbCBVUkwKIHdoaWNoIHJlZmVycyB0byBBTVAgY29u
dGVudCB2aWEgPGxpbmsgcmVsPSJhbXBodG1sIj4uCgoMCgUFAAIBARIDMQIFCgwKBQUAAgEC
EgMxCAliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Link::Link ===
    # Fields for Link
    # Field: name Type: 9 ()
    # Field: open Type: 11 (.google.actions.sdk.v2.conversation.OpenUrl)

# === Message: Google::Actions::Sdk::V2::Conversation::Link::OpenUrl ===
    # Fields for OpenUrl
    # Field: url Type: 9 ()
    # Field: hint Type: 14 (.google.actions.sdk.v2.conversation.UrlHint)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Link - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/link.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Link;

    my $msg = Google::Actions::Sdk::V2::Conversation::Link::Link->new({
        name => $name,
        open => $open,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Link::Link->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/link.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Link::Link

Link content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the link

=item * C<< $msg->open() >> / C<< $msg->open($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Link::OpenUrl>)

What happens when a user opens the link

=back

=head2 Google::Actions::Sdk::V2::Conversation::Link::OpenUrl

Action taken when a user opens a link.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The url field which could be any of:
- http/https urls for opening an App-linked App or a webpage

=item * C<< $msg->hint() >> / C<< $msg->hint($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::UrlHint>)

Indicates a hint for the url type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Link::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
