package Google::Cloud::Dialogflow::V2beta1::CesTool;

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
Ci5nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2Nlc190b29sLnByb3RvEh9nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGipnb29nbGUvY2xvdWQvZGlhbG9n
Zmxvdy92MmJldGExL3Rvb2wucHJvdG8iyAEKC0Nlc1Rvb2xTcGVjEjoKCGNlc190b29sGAEg
ASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVhcGlzLmNvbS9Ub29sUgdjZXNUb29sEn0KGGNvbmZp
cm1hdGlvbl9yZXF1aXJlbWVudBgCIAEoDjI9Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
YmV0YTEuVG9vbC5Db25maXJtYXRpb25SZXF1aXJlbWVudEID4EEBUhdjb25maXJtYXRpb25S
ZXF1aXJlbWVudEKhAQojY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTFCDENl
c1Rvb2xQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRh
MS9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9n
Zmxvdy5WMkJldGExSqkJCgYSBA4AKQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADQKCAoBCBID
FgA8CgkKAgglEgMWADwKCAoBCBIDFwBaCgkKAggLEgMXAFoKCAoBCBIDGAAiCgkKAggKEgMY
ACIKCAoBCBIDGQAtCgkKAggIEgMZAC0KCAoBCBIDGgA8CgkKAggBEgMaADwKCAoBCBIDGwAg
CgkKAggkEgMbACAKQgoCBAASBB4AKQEaNiBTcGVjIG9mIENFUyB0b29sIHRoYXQgdGhlIGdl
bmVyYXRvciBjYW4gY2hvb3NlIGZyb20uCgoKCgMEAAESAx4IEwpxCgQEAAIAEgQhAiQEGmMg
T3B0aW9uYWwuIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExv
Y2F0aW9uIElEPi9hcHBzLzxhcHAKIElEPi90b29scy88dG9vbCBJRD5gLgoKDAoFBAACAAUS
AyECCAoMCgUEAAIAARIDIQkRCgwKBQQAAgADEgMhFBUKDQoFBAACAAgSBCEWJAMKDwoIBAAC
AAicCAASAyIEKgoOCgcEAAIACJ8IEgMjBEkKUQoEBAACARIEJwIoLxpDIE9wdGlvbmFsLiBJ
bmRpY2F0ZXMgd2hldGhlciB0aGUgdG9vbCByZXF1aXJlcyBodW1hbiBjb25maXJtYXRpb24u
CgoMCgUEAAIBBhIDJwIeCgwKBQQAAgEBEgMnHzcKDAoFBAACAQMSAyc6OwoMCgUEAAIBCBID
KAYuCg8KCAQAAgEInAgAEgMoBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::CesTool::CesToolSpec ===
    # Fields for CesToolSpec
    # Field: ces_tool Type: 9 ()
    # Field: confirmation_requirement Type: 14 (.google.cloud.dialogflow.v2beta1.Tool.ConfirmationRequirement)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::CesTool - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/ces_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::CesTool;

    my $msg = Google::Cloud::Dialogflow::V2beta1::CesTool::CesToolSpec->new({
        ces_tool => $ces_tool,
        confirmation_requirement => $confirmation_requirement,
    });

    # Read or update a field
    my $val = $msg->ces_tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::CesTool::CesToolSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/ces_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::CesTool::CesToolSpec

Spec of CES tool that the generator can choose from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ces_tool() >> / C<< $msg->ces_tool($value) >>

Type: C<String>

Optional. Format: `projects/<Project ID>/locations/<Location ID>/apps/<app
ID>/tools/<tool ID>`.

=item * C<< $msg->confirmation_requirement() >> / C<< $msg->confirmation_requirement($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::Tool::ConfirmationRequirement>)

Optional. Indicates whether the tool requires human confirmation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::CesTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
