package Google::Cloud::Dialogflow::V2beta1::CesApp;

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
    eval { require Google::Cloud::Dialogflow::V2beta1::Tool };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2Nlc19hcHAucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKmdvb2dsZS9jbG91ZC9kaWFsb2dm
bG93L3YyYmV0YTEvdG9vbC5wcm90byLfAgoKQ2VzQXBwU3BlYxI3CgdjZXNfYXBwGAEgASgJ
Qh7gQQH6QRgKFmNlcy5nb29nbGVhcGlzLmNvbS9BcHBSBmNlc0FwcBJ9Chhjb25maXJtYXRp
b25fcmVxdWlyZW1lbnQYAiABKA4yPS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LlRvb2wuQ29uZmlybWF0aW9uUmVxdWlyZW1lbnRCA+BBAVIXY29uZmlybWF0aW9uUmVxdWly
ZW1lbnQSNQoRcHJvYWN0aXZlX2VuYWJsZWQYAyABKAhCA+BBAUgAUhBwcm9hY3RpdmVFbmFi
bGVkiAEBEjMKEHJlYWN0aXZlX2VuYWJsZWQYBCABKAhCA+BBAUgBUg9yZWFjdGl2ZUVuYWJs
ZWSIAQE6AhgBQhQKEl9wcm9hY3RpdmVfZW5hYmxlZEITChFfcmVhY3RpdmVfZW5hYmxlZELv
AQojY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTFCC0Nlc0FwcFByb3RvUAFa
Q2Nsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2MmJldGExL2RpYWxvZ2Zsb3dw
YjtkaWFsb2dmbG93cGKiAgJERqoCH0dvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYyQmV0YTHq
QUwKFmNlcy5nb29nbGVhcGlzLmNvbS9BcHASMnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9hcHBzL3thcHB9SoAPCgYSBA4APAEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMC
EgMUADQKCAoBCBIDFgA8CgkKAgglEgMWADwKCAoBCBIDFwBaCgkKAggLEgMXAFoKCAoBCBID
GAAiCgkKAggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgA8CgkKAggBEgMa
ADwKCAoBCBIDGwAgCgkKAggkEgMbACAKCQoBCBIEHAAfAgoMCgQInQgAEgQcAB8CCmkKAgQA
EgQjADwBGl0gRGVwcmVjYXRlZDogVXNlIGBDZXNUb29sU3BlY2AgaW5zdGVhZC4KIFNwZWMg
b2YgQ0VTIGFwcCB0aGF0IHRoZSBnZW5lcmF0b3IgY2FuIGNob29zZSBmcm9tLgoKCgoDBAAB
EgMjCBIKCgoDBAAHEgMkAhsKCwoEBAAHAxIDJAIbCmEKBAQAAgASBCgCKwQaUyBPcHRpb25h
bC4gRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24g
SUQ+L2FwcHMvPGFwcAogSUQ+YC4KCgwKBQQAAgAFEgMoAggKDAoFBAACAAESAygJEAoMCgUE
AAIAAxIDKBMUCg0KBQQAAgAIEgQoFSsDCg8KCAQAAgAInAgAEgMpBCoKDgoHBAACAAifCBID
KgRIClAKBAQAAgESBC4CLy8aQiBPcHRpb25hbC4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGFw
cCByZXF1aXJlcyBodW1hbiBjb25maXJtYXRpb24uCgoMCgUEAAIBBhIDLgIeCgwKBQQAAgEB
EgMuHzcKDAoFBAACAQMSAy46OwoMCgUEAAIBCBIDLwYuCg8KCAQAAgEInAgAEgMvBy0K7gEK
BAQAAgISAzUCTxrgASBPcHRpb25hbC4gT25seSBhcHBsaWNhYmxlIGZvciBDb21wYW5pb25B
Z2VudC4KIEluZGljYXRlcyB3aGV0aGVyIHRoZSBjZXMgYXBwIGlzIGVuYWJsZWQgaW4gcHJv
YWN0aXZlIG1vZGUuCiBBdCBsZWFzdCBvbmUgb2YgYHByb2FjdGl2ZV9lbmFibGVkYCBvciBg
cmVhY3RpdmVfZW5hYmxlZGAgc2hvdWxkIGJlCiB0cnVlOyBvdGhlcndpc2UsIHRoZSBjZXMg
YXBwIHdpbGwgYmUgaWdub3JlZC4KCgwKBQQAAgIEEgM1AgoKDAoFBAACAgUSAzULDwoMCgUE
AAICARIDNRAhCgwKBQQAAgIDEgM1JCUKDAoFBAACAggSAzUmTgoPCggEAAICCJwIABIDNSdN
Cu0BCgQEAAIDEgM7Ak4a3wEgT3B0aW9uYWwuIE9ubHkgYXBwbGljYWJsZSBmb3IgQ29tcGFu
aW9uQWdlbnQuCiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgY2VzIGFwcCBpcyBlbmFibGVkIGlu
IHJlYWN0aXZlIG1vZGUuCiBBdCBsZWFzdCBvbmUgb2YgYHByb2FjdGl2ZV9lbmFibGVkYCBv
ciBgcmVhY3RpdmVfZW5hYmxlZGAgc2hvdWxkIGJlCiB0cnVlOyBvdGhlcndpc2UsIHRoZSBj
ZXMgYXBwIHdpbGwgYmUgaWdub3JlZC4KCgwKBQQAAgMEEgM7AgoKDAoFBAACAwUSAzsLDwoM
CgUEAAIDARIDOxAgCgwKBQQAAgMDEgM7IyQKDAoFBAACAwgSAzslTQoPCggEAAIDCJwIABID
OyZMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::CesApp::CesAppSpec ===
    # Fields for CesAppSpec
    # Field: ces_app Type: 9 ()
    # Field: confirmation_requirement Type: 14 (.google.cloud.dialogflow.v2beta1.Tool.ConfirmationRequirement)
    # Field: proactive_enabled Type: 8 ()
    # Field: reactive_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::CesApp - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/ces_app.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::CesApp;

    my $msg = Google::Cloud::Dialogflow::V2beta1::CesApp::CesAppSpec->new({
        ces_app => $ces_app,
        confirmation_requirement => $confirmation_requirement,
        proactive_enabled => $proactive_enabled,
        reactive_enabled => $reactive_enabled,
    });

    # Read or update a field
    my $val = $msg->ces_app();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::CesApp::CesAppSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/ces_app.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::CesApp::CesAppSpec

Deprecated: Use `CesToolSpec` instead.
Spec of CES app that the generator can choose from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ces_app() >> / C<< $msg->ces_app($value) >>

Type: C<String>

Optional. Format: `projects/<Project ID>/locations/<Location ID>/apps/<app
ID>`.

=item * C<< $msg->confirmation_requirement() >> / C<< $msg->confirmation_requirement($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::Tool::ConfirmationRequirement>)

Optional. Indicates whether the app requires human confirmation.

=item * C<< $msg->proactive_enabled() >> / C<< $msg->proactive_enabled($value) >>

Type: C<Bool>

Optional. Only applicable for CompanionAgent.
Indicates whether the ces app is enabled in proactive mode.
At least one of `proactive_enabled` or `reactive_enabled` should be
true; otherwise, the ces app will be ignored.

=item * C<< $msg->reactive_enabled() >> / C<< $msg->reactive_enabled($value) >>

Type: C<Bool>

Optional. Only applicable for CompanionAgent.
Indicates whether the ces app is enabled in reactive mode.
At least one of `proactive_enabled` or `reactive_enabled` should be
true; otherwise, the ces app will be ignored.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::CesApp::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
