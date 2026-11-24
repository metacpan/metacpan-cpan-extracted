package Google::Cloud::Discoveryengine::V1::Collection;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NvbGxlY3Rpb24ucHJvdG8SH2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8igQIKCkNvbGxlY3Rpb24SFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1l
EiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRJACgtjcmVhdGVfdGlt
ZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZTpw
6kFtCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvbhJAcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0
aW9ufUKCAgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCD0NvbGxlY3Rp
b25Qcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9k
aXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoC
H0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292
ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUqmDQoG
EgQOADkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAPAoJCgIIJRIDFgA8CggK
AQgSAxcAZAoJCgIICxIDFwBkCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMAoJCgII
CBIDGQAwCggKAQgSAxoAPAoJCgIIARIDGgA8CggKAQgSAxsALQoJCgIIJBIDGwAtCggKAQgS
AxwAPAoJCgIIKRIDHAA8CggKAQgSAx0AOwoJCgIILRIDHQA7CmUKAgQAEgQhADkBGlkgQ29s
bGVjdGlvbiBpcyBhIGNvbnRhaW5lciBmb3IgY29uZmlndXJpbmcgcmVzb3VyY2VzIGFuZCBh
Y2Nlc3MgdG8gYSBzZXQgb2YKIERhdGFTdG9yZXMuCgoKCgMEAAESAyEIEgoLCgMEAAcSBCIC
JQQKDQoFBAAHnQgSBCICJQQK6gEKBAQAAgASAy0CPBrcASBJbW11dGFibGUuIFRoZSBmdWxs
IHJlc291cmNlIG5hbWUgb2YgdGhlIENvbGxlY3Rpb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9u
X2lkfWAuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0
aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAy0CCAoM
CgUEAAIAARIDLQkNCgwKBQQAAgADEgMtEBEKDAoFBAACAAgSAy0SOwoPCggEAAIACJwIABID
LRM6CrwBCgQEAAIBEgMzAkMargEgUmVxdWlyZWQuIFRoZSBDb2xsZWN0aW9uIGRpc3BsYXkg
bmFtZS4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRo
IGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbiBJTlZB
TElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDAoFBAACAQUSAzMCCAoMCgUEAAIB
ARIDMwkVCgwKBQQAAgEDEgMzGBkKDAoFBAACAQgSAzMaQgoPCggEAAIBCJwIABIDMxtBCnQK
BAQAAgISBDcCODIaZiBPdXRwdXQgb25seS4gVGltZXN0YW1wIHRoZQogW0NvbGxlY3Rpb25d
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29sbGVjdGlvbl0gd2FzIGNyZWF0
ZWQgYXQuCgoMCgUEAAICBhIDNwIbCgwKBQQAAgIBEgM3HCcKDAoFBAACAgMSAzcqKwoMCgUE
AAICCBIDOAYxCg8KCAQAAgIInAgAEgM4BzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Collection::Collection ===
    # Fields for Collection
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Collection - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/collection.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Collection;

    my $msg = Google::Cloud::Discoveryengine::V1::Collection::Collection->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Collection::Collection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/collection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Collection::Collection

Collection is a container for configuring resources and access to a set of
DataStores.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the Collection.
Format:
`projects/{project}/locations/{location}/collections/{collection_id}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The Collection display name.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[Collection][google.cloud.discoveryengine.v1.Collection] was created at.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Collection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
