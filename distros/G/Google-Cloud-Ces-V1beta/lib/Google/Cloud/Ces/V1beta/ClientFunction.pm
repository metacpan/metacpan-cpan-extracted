package Google::Cloud::Ces::V1beta::ClientFunction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1beta::Schema };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jbGllbnRfZnVuY3Rpb24ucHJvdG8SF2dvb2ds
ZS5jbG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGiRn
b29nbGUvY2xvdWQvY2VzL3YxYmV0YS9zY2hlbWEucHJvdG8i2AEKDkNsaWVudEZ1bmN0aW9u
EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtk
ZXNjcmlwdGlvbhJECgpwYXJhbWV0ZXJzGAMgASgLMh8uZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuU2NoZW1hQgPgQQFSCnBhcmFtZXRlcnMSQAoIcmVzcG9uc2UYBCABKAsyHy5nb29nbGUu
Y2xvdWQuY2VzLnYxYmV0YS5TY2hlbWFCA+BBAVIIcmVzcG9uc2VCYwobY29tLmdvb2dsZS5j
bG91ZC5jZXMudjFiZXRhQhNDbGllbnRGdW5jdGlvblByb3RvUAFaLWNsb3VkLmdvb2dsZS5j
b20vZ28vY2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNwYkqdDAoGEgQOACsBCrwECgEMEgMOABIy
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
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMA
LgoICgEIEgMVAEQKCQoCCAsSAxUARAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADQK
CQoCCAgSAxcANAoICgEIEgMYADQKCQoCCAESAxgANArOAgoCBAASBB8AKwEawQIgUmVwcmVz
ZW50cyBhIGNsaWVudC1zaWRlIGZ1bmN0aW9uIHRoYXQgdGhlIGFnZW50IGNhbiBpbnZva2Uu
IFdoZW4gdGhlCiB0b29sIGlzIGNob3NlbiBieSB0aGUgYWdlbnQsIGNvbnRyb2wgaXMgaGFu
ZGVkIG9mZiB0byB0aGUgY2xpZW50LgogVGhlIGNsaWVudCBpcyByZXNwb25zaWJsZSBmb3Ig
ZXhlY3V0aW5nIHRoZSBmdW5jdGlvbiBhbmQgcmV0dXJuaW5nIHRoZSByZXN1bHQKIGFzIGEg
W1Rvb2xSZXNwb25zZV1bZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuVG9vbFJlc3BvbnNlXSB0
byBjb250aW51ZSB0aGUKIGludGVyYWN0aW9uIHdpdGggdGhlIGFnZW50LgoKCgoDBAABEgMf
CBYKKwoEBAACABIDIQI7Gh4gUmVxdWlyZWQuIFRoZSBmdW5jdGlvbiBuYW1lLgoKDAoFBAAC
AAUSAyECCAoMCgUEAAIAARIDIQkNCgwKBQQAAgADEgMhEBEKDAoFBAACAAgSAyESOgoPCggE
AAIACJwIABIDIRM5CjIKBAQAAgESAyQCQholIE9wdGlvbmFsLiBUaGUgZnVuY3Rpb24gZGVz
Y3JpcHRpb24uCgoMCgUEAAIBBRIDJAIICgwKBQQAAgEBEgMkCRQKDAoFBAACAQMSAyQXGAoM
CgUEAAIBCBIDJBlBCg8KCAQAAgEInAgAEgMkGkAKPwoEBAACAhIDJwJBGjIgT3B0aW9uYWwu
IFRoZSBzY2hlbWEgb2YgdGhlIGZ1bmN0aW9uIHBhcmFtZXRlcnMuCgoMCgUEAAICBhIDJwII
CgwKBQQAAgIBEgMnCRMKDAoFBAACAgMSAycWFwoMCgUEAAICCBIDJxhACg8KCAQAAgIInAgA
EgMnGT8KPQoEBAACAxIDKgI/GjAgT3B0aW9uYWwuIFRoZSBzY2hlbWEgb2YgdGhlIGZ1bmN0
aW9uIHJlc3BvbnNlLgoKDAoFBAACAwYSAyoCCAoMCgUEAAIDARIDKgkRCgwKBQQAAgMDEgMq
FBUKDAoFBAACAwgSAyoWPgoPCggEAAIDCJwIABIDKhc9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::ClientFunction::ClientFunction ===
    # Fields for ClientFunction
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: response Type: 11 (.google.cloud.ces.v1beta.Schema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::ClientFunction - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/client_function.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::ClientFunction;

    my $msg = Google::Cloud::Ces::V1beta::ClientFunction::ClientFunction->new({
        name => $name,
        description => $description,
        parameters => $parameters,
        response => $response,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::ClientFunction::ClientFunction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/client_function.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::ClientFunction::ClientFunction

Represents a client-side function that the agent can invoke. When the
tool is chosen by the agent, control is handed off to the client.
The client is responsible for executing the function and returning the result
as a [ToolResponse][google.cloud.ces.v1beta.ToolResponse] to continue the
interaction with the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The function name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The function description.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. The schema of the function parameters.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. The schema of the function response.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::ClientFunction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
