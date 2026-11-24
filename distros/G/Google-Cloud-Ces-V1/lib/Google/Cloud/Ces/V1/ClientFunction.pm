package Google::Cloud::Ces::V1::ClientFunction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1::Schema };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvY2VzL3YxL2NsaWVudF9mdW5jdGlvbi5wcm90bxITZ29vZ2xlLmNs
b3VkLmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxogZ29vZ2xlL2Ns
b3VkL2Nlcy92MS9zY2hlbWEucHJvdG8i0AEKDkNsaWVudEZ1bmN0aW9uEhcKBG5hbWUYASAB
KAlCA+BBAlIEbmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJA
CgpwYXJhbWV0ZXJzGAMgASgLMhsuZ29vZ2xlLmNsb3VkLmNlcy52MS5TY2hlbWFCA+BBAVIK
cGFyYW1ldGVycxI8CghyZXNwb25zZRgEIAEoCzIbLmdvb2dsZS5jbG91ZC5jZXMudjEuU2No
ZW1hQgPgQQFSCHJlc3BvbnNlQlsKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQhNDbGllbnRG
dW5jdGlvblByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nl
c3BiSpkMCgYSBA4AKwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAqCggKAQgSAxUAQAoJCgIICxIDFQBACggKAQgS
AxYAIgoJCgIIChIDFgAiCggKAQgSAxcANAoJCgIICBIDFwA0CggKAQgSAxgAMAoJCgIIARID
GAAwCsoCCgIEABIEHwArARq9AiBSZXByZXNlbnRzIGEgY2xpZW50LXNpZGUgZnVuY3Rpb24g
dGhhdCB0aGUgYWdlbnQgY2FuIGludm9rZS4gV2hlbiB0aGUKIHRvb2wgaXMgY2hvc2VuIGJ5
IHRoZSBhZ2VudCwgY29udHJvbCBpcyBoYW5kZWQgb2ZmIHRvIHRoZSBjbGllbnQuCiBUaGUg
Y2xpZW50IGlzIHJlc3BvbnNpYmxlIGZvciBleGVjdXRpbmcgdGhlIGZ1bmN0aW9uIGFuZCBy
ZXR1cm5pbmcgdGhlIHJlc3VsdAogYXMgYSBbVG9vbFJlc3BvbnNlXVtnb29nbGUuY2xvdWQu
Y2VzLnYxLlRvb2xSZXNwb25zZV0gdG8gY29udGludWUgdGhlCiBpbnRlcmFjdGlvbiB3aXRo
IHRoZSBhZ2VudC4KCgoKAwQAARIDHwgWCisKBAQAAgASAyECOxoeIFJlcXVpcmVkLiBUaGUg
ZnVuY3Rpb24gbmFtZS4KCgwKBQQAAgAFEgMhAggKDAoFBAACAAESAyEJDQoMCgUEAAIAAxID
IRARCgwKBQQAAgAIEgMhEjoKDwoIBAACAAicCAASAyETOQoyCgQEAAIBEgMkAkIaJSBPcHRp
b25hbC4gVGhlIGZ1bmN0aW9uIGRlc2NyaXB0aW9uLgoKDAoFBAACAQUSAyQCCAoMCgUEAAIB
ARIDJAkUCgwKBQQAAgEDEgMkFxgKDAoFBAACAQgSAyQZQQoPCggEAAIBCJwIABIDJBpACj8K
BAQAAgISAycCQRoyIE9wdGlvbmFsLiBUaGUgc2NoZW1hIG9mIHRoZSBmdW5jdGlvbiBwYXJh
bWV0ZXJzLgoKDAoFBAACAgYSAycCCAoMCgUEAAICARIDJwkTCgwKBQQAAgIDEgMnFhcKDAoF
BAACAggSAycYQAoPCggEAAICCJwIABIDJxk/Cj0KBAQAAgMSAyoCPxowIE9wdGlvbmFsLiBU
aGUgc2NoZW1hIG9mIHRoZSBmdW5jdGlvbiByZXNwb25zZS4KCgwKBQQAAgMGEgMqAggKDAoF
BAACAwESAyoJEQoMCgUEAAIDAxIDKhQVCgwKBQQAAgMIEgMqFj4KDwoIBAACAwicCAASAyoX
PWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::ClientFunction::ClientFunction ===
    # Fields for ClientFunction
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: response Type: 11 (.google.cloud.ces.v1.Schema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::ClientFunction - Compiled Protocol Buffers messages for google/cloud/ces/v1/client_function.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::ClientFunction;

    my $msg = Google::Cloud::Ces::V1::ClientFunction::ClientFunction->new({
        name => $name,
        description => $description,
        parameters => $parameters,
        response => $response,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::ClientFunction::ClientFunction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/client_function.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::ClientFunction::ClientFunction

Represents a client-side function that the agent can invoke. When the
tool is chosen by the agent, control is handed off to the client.
The client is responsible for executing the function and returning the result
as a [ToolResponse][google.cloud.ces.v1.ToolResponse] to continue the
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

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. The schema of the function parameters.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. The schema of the function response.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::ClientFunction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
