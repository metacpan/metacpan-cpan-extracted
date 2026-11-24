package Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL2ZyZWVfdGV4
dF90eXBlLnByb3RvEitnb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50
eXBlGkBnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL2VudGl0
eV9kaXNwbGF5LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvImkKDEZy
ZWVUZXh0VHlwZRJZCgdkaXNwbGF5GAIgASgLMjouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwudHlwZS5FbnRpdHlEaXNwbGF5QgPgQQFSB2Rpc3BsYXlCkgEKL2Nv
bS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC50eXBlQhFGcmVlVGV4
dFR5cGVQcm90b1ABWkpnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2Fj
dGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlwZUqcCAoGEgQOACABCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA0CgkKAgMAEgMSAEoKCQoCAwES
AxMAKQoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ADIKCQoCCAgSAxcAMgoICgEIEgMYAEgKCQoCCAESAxgASApuCgIEABIEHAAgARpiIFR5cGUg
dGhhdCBtYXRjaGVzIGFueSB0ZXh0IGlmIHN1cnJvdW5kaW5nIHdvcmRzIGNvbnRleHQgaXMg
Y2xvc2UgdG8gcHJvdmlkZWQKIHRyYWluaW5nIGV4YW1wbGVzLgoKCgoDBAABEgMcCBQKmQEK
BAQAAgASAx8CRRqLASBPcHRpb25hbC4gRWxlbWVudHMgdGhhdCB3aWxsIGJlIGRpc3BsYXll
ZCBvbiB0aGUgY2FudmFzIG9uY2UgYW4gZW50aXR5IGlzIGV4dHJhY3RlZAogZnJvbSBhIHF1
ZXJ5LiBPbmx5IHJlbGV2YW50IGZvciBjYW52YXMgZW5hYmxlZCBhcHBzLgoKDAoFBAACAAYS
Ax8CDwoMCgUEAAIAARIDHxAXCgwKBQQAAgADEgMfGhsKDAoFBAACAAgSAx8cRAoPCggEAAIA
CJwIABIDHx1DYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType ===
    # Fields for FreeTextType
    # Field: display Type: 11 (.google.actions.sdk.v2.interactionmodel.type.EntityDisplay)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/type/free_text_type.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType->new({
        display => $display,
    });

    # Read or update a field
    my $val = $msg->display();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/type/free_text_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType

Type that matches any text if surrounding words context is close to provided
training examples.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display() >> / C<< $msg->display($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay>)

Optional. Elements that will be displayed on the canvas once an entity is extracted
from a query. Only relevant for canvas enabled apps.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
