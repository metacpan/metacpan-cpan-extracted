package Google::Cloud::Dialogflow::V2::CesApp;

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
    eval { require Google::Cloud::Dialogflow::V2::Tool };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9jZXNfYXBwLnByb3RvEhpnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxolZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvdjIvdG9v
bC5wcm90byLaAgoKQ2VzQXBwU3BlYxI3CgdjZXNfYXBwGAEgASgJQh7gQQH6QRgKFmNlcy5n
b29nbGVhcGlzLmNvbS9BcHBSBmNlc0FwcBJ4Chhjb25maXJtYXRpb25fcmVxdWlyZW1lbnQY
AiABKA4yOC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Ub29sLkNvbmZpcm1hdGlvblJl
cXVpcmVtZW50QgPgQQFSF2NvbmZpcm1hdGlvblJlcXVpcmVtZW50EjUKEXByb2FjdGl2ZV9l
bmFibGVkGAMgASgIQgPgQQFIAFIQcHJvYWN0aXZlRW5hYmxlZIgBARIzChByZWFjdGl2ZV9l
bmFibGVkGAQgASgIQgPgQQFIAVIPcmVhY3RpdmVFbmFibGVkiAEBOgIYAUIUChJfcHJvYWN0
aXZlX2VuYWJsZWRCEwoRX3JlYWN0aXZlX2VuYWJsZWRC4AEKHmNvbS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52MkILQ2VzQXBwUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFs
b2dmbG93L2FwaXYyL2RpYWxvZ2Zsb3dwYjtkaWFsb2dmbG93cGKiAgJERqoCGkdvb2dsZS5D
bG91ZC5EaWFsb2dmbG93LlYy6kFMChZjZXMuZ29vZ2xlYXBpcy5jb20vQXBwEjJwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfUqADwoGEgQOADwB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMS
ACkKCQoCAwESAxMAIwoJCgIDAhIDFAAvCggKAQgSAxYANwoJCgIIJRIDFgA3CggKAQgSAxcA
VQoJCgIICxIDFwBVCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALAoJCgIICBIDGQAs
CggKAQgSAxoANwoJCgIIARIDGgA3CggKAQgSAxsAIAoJCgIIJBIDGwAgCgkKAQgSBBwAHwIK
DAoECJ0IABIEHAAfAgppCgIEABIEIwA8ARpdIERlcHJlY2F0ZWQ6IFVzZSBgQ2VzVG9vbFNw
ZWNgIGluc3RlYWQuCiBTcGVjIG9mIENFUyBhcHAgdGhhdCB0aGUgZ2VuZXJhdG9yIGNhbiBj
aG9vc2UgZnJvbS4KCgoKAwQAARIDIwgSCgoKAwQABxIDJAIbCgsKBAQABwMSAyQCGwphCgQE
AAIAEgQoAisEGlMgT3B0aW9uYWwuIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9s
b2NhdGlvbnMvPExvY2F0aW9uIElEPi9hcHBzLzxhcHAKIElEPmAuCgoMCgUEAAIABRIDKAII
CgwKBQQAAgABEgMoCRAKDAoFBAACAAMSAygTFAoNCgUEAAIACBIEKBUrAwoPCggEAAIACJwI
ABIDKQQqCg4KBwQAAgAInwgSAyoESApQCgQEAAIBEgQuAi8vGkIgT3B0aW9uYWwuIEluZGlj
YXRlcyB3aGV0aGVyIHRoZSBhcHAgcmVxdWlyZXMgaHVtYW4gY29uZmlybWF0aW9uLgoKDAoF
BAACAQYSAy4CHgoMCgUEAAIBARIDLh83CgwKBQQAAgEDEgMuOjsKDAoFBAACAQgSAy8GLgoP
CggEAAIBCJwIABIDLwctCu4BCgQEAAICEgM1Ak8a4AEgT3B0aW9uYWwuIE9ubHkgYXBwbGlj
YWJsZSBmb3IgQ29tcGFuaW9uQWdlbnQuCiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgY2VzIGFw
cCBpcyBlbmFibGVkIGluIHByb2FjdGl2ZSBtb2RlLgogQXQgbGVhc3Qgb25lIG9mIGBwcm9h
Y3RpdmVfZW5hYmxlZGAgb3IgYHJlYWN0aXZlX2VuYWJsZWRgIHNob3VsZCBiZQogdHJ1ZTsg
b3RoZXJ3aXNlLCB0aGUgY2VzIGFwcCB3aWxsIGJlIGlnbm9yZWQuCgoMCgUEAAICBBIDNQIK
CgwKBQQAAgIFEgM1Cw8KDAoFBAACAgESAzUQIQoMCgUEAAICAxIDNSQlCgwKBQQAAgIIEgM1
Jk4KDwoIBAACAgicCAASAzUnTQrtAQoEBAACAxIDOwJOGt8BIE9wdGlvbmFsLiBPbmx5IGFw
cGxpY2FibGUgZm9yIENvbXBhbmlvbkFnZW50LgogSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGNl
cyBhcHAgaXMgZW5hYmxlZCBpbiByZWFjdGl2ZSBtb2RlLgogQXQgbGVhc3Qgb25lIG9mIGBw
cm9hY3RpdmVfZW5hYmxlZGAgb3IgYHJlYWN0aXZlX2VuYWJsZWRgIHNob3VsZCBiZQogdHJ1
ZTsgb3RoZXJ3aXNlLCB0aGUgY2VzIGFwcCB3aWxsIGJlIGlnbm9yZWQuCgoMCgUEAAIDBBID
OwIKCgwKBQQAAgMFEgM7Cw8KDAoFBAACAwESAzsQIAoMCgUEAAIDAxIDOyMkCgwKBQQAAgMI
EgM7JU0KDwoIBAACAwicCAASAzsmTGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec ===
    # Fields for CesAppSpec
    # Field: ces_app Type: 9 ()
    # Field: confirmation_requirement Type: 14 (.google.cloud.dialogflow.v2.Tool.ConfirmationRequirement)
    # Field: proactive_enabled Type: 8 ()
    # Field: reactive_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::CesApp - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/ces_app.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::CesApp;

    my $msg = Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec->new({
        ces_app => $ces_app,
        confirmation_requirement => $confirmation_requirement,
        proactive_enabled => $proactive_enabled,
        reactive_enabled => $reactive_enabled,
    });

    # Read or update a field
    my $val = $msg->ces_app();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/ces_app.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::CesApp::CesAppSpec

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

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::Tool::ConfirmationRequirement>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::CesApp::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
